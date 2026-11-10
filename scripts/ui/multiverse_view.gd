class_name MultiverseView
extends Control
## Высокопроизводительная и визуально улучшенная отрисовка мультивселенной 5D-шахмат.

signal square_tapped(pos: Vector4i)

const SQ := 48.0

# Цветовая палитра
const COL_LIGHT := Color(0.88, 0.91, 0.96)
const COL_DARK := Color(0.38, 0.45, 0.60)
const COL_FRAME_W := Color(0.92, 0.94, 0.98)
const COL_FRAME_B := Color(0.18, 0.21, 0.32)
const COL_MANDATORY := Color(1.0, 0.78, 0.22)
const COL_OPTIONAL := Color(0.32, 0.88, 0.58)
const COL_SELECT := Color(0.25, 0.82, 1.0, 0.65)
const COL_TARGET := Color(0.2, 0.8, 1.0, 0.8)
const COL_TARGET_CAPTURE := Color(1.0, 0.3, 0.35, 0.85)
const COL_TARGET_TIME := Color(0.85, 0.45, 1.0, 0.85)
const COL_LAST := Color(1.0, 0.85, 0.35, 0.32)
const COL_PRESENT_AURA := Color(0.35, 0.65, 1.0, 0.12)
const COL_PRESENT_BEAM := Color(0.45, 0.85, 1.0, 0.85)
const COL_THREAT := Color(1.0, 0.25, 0.25, 0.95)
const COL_SHADOW := Color(0.0, 0.0, 0.0, 0.45)

var state: GameState
var selected: Vector4i = Vector4i(-1, -1, 0, 0)
var targets: Array = []
var interactive: bool = true
var flip: bool = false
var threats: Array = []
var mate_info: Dictionary = {}
var hint_move: Dictionary = {}
var is_animating: bool = false
var player_skins: Dictionary = {}

func get_skin_for_piece(piece: int) -> String:
	var is_black: bool = (piece & GameState.BLACK_BIT) != 0
	var col: int = GameState.BLACK if is_black else GameState.WHITE
	return player_skins.get(col, Profile.active_skin)

var zoom: float = 1.0
var offset: Vector2 = Vector2.ZERO

var _touches: Dictionary = {}
var _drag_dist: float = 0.0
var _pinch_dist: float = 0.0
var _stars: Array = []
var _font: Font
var _cam_tween: Tween
var _anim_time: float = 0.0
var _shake_amount: float = 0.0
var _shake: Vector2 = Vector2.ZERO

var _moving_piece: Dictionary = {}
var _moving_progress: float = 0.0:
	set(v):
		_moving_progress = v
		if not _moving_piece.is_empty():
			_moving_piece["progress"] = v
		queue_redraw()

var _ripples: Array = []
var _sparks: Array = []
var _floating_texts: Array = []
var _prev_size: Vector2 = Vector2.ZERO
var _pan_velocity: Vector2 = Vector2.ZERO
# Кэш самого раннего полухода (зависит только от набора линий, а нужен для каждой клетки).
var _min_t_cache: int = 0
var _min_t_key: int = -1


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_font = ThemeDB.fallback_font
	resized.connect(_on_view_resized)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in 180:
		_stars.append({
			"pos": Vector2(rng.randf(), rng.randf()),
			"size": rng.randf_range(0.8, 2.2),
			"alpha": rng.randf_range(0.2, 0.75),
			"speed": rng.randf_range(1.5, 3.5),
			"phase": rng.randf_range(0.0, TAU),
		})


func _process(delta: float) -> void:
	_anim_time += delta

	# Тряска экрана при темпоральном приземлении или взятии
	if _shake_amount > 0.0:
		_shake = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_amount
		_shake_amount = move_toward(_shake_amount, 0.0, delta * 30.0)
	else:
		_shake = Vector2.ZERO

	# Обновление волн
	if not _ripples.is_empty():
		var remaining := []
		for r in _ripples:
			r["timer"] += delta
			var k: float = r["timer"] / r["life"]
			if k < 1.0:
				r["radius"] = lerpf(SQ * 0.15, r["max_radius"], k)
				r["color"].a = (1.0 - k) * 0.85
				remaining.append(r)
		_ripples = remaining

	# Обновление процедурных искр
	if not _sparks.is_empty():
		var rem_s := []
		for sp in _sparks:
			sp["timer"] += delta
			var k: float = sp["timer"] / sp["life"]
			if k < 1.0:
				sp["pos"] += sp["vel"] * delta
				sp["vel"] *= float(sp["drag"])
				sp["alpha"] = (1.0 - k)
				rem_s.append(sp)
		_sparks = rem_s

	# Обновление всплывающего текста
	if not _floating_texts.is_empty():
		var rem_t := []
		for ft in _floating_texts:
			ft["timer"] += delta
			var k: float = ft["timer"] / ft["life"]
			if k < 1.0:
				ft["pos"] += ft["vel"] * delta
				ft["vel"].y *= 0.95
				rem_t.append(ft)
		_floating_texts = rem_t

	# Инерционное скольжение камеры после свайпа
	if _touches.is_empty() and _pan_velocity.length_squared() > 10.0:
		offset += _pan_velocity * delta
		_pan_velocity = _pan_velocity.move_toward(Vector2.ZERO, delta * 3200.0)
		_pan_velocity *= pow(0.88, delta * 60.0)

	queue_redraw()


func _on_view_resized() -> void:
	if _prev_size != Vector2.ZERO and size != Vector2.ZERO and not is_animating:
		offset += (size - _prev_size) * 0.5
	_prev_size = size
	queue_redraw()


func animate_move(from: Vector4i, to: Vector4i, piece: int, is_temporal: bool = false, is_capture: bool = false) -> void:
	is_animating = true
	var dur: float = 0.52 if is_temporal else 0.30
	_moving_piece = {
		"from": from,
		"to": to,
		"piece": piece,
		"progress": 0.0,
		"is_temporal": is_temporal,
		"is_capture": is_capture,
	}
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "_moving_progress", 1.0, dur).from(0.0)
	await tw.finished
	var target_center: Vector2 = square_rect(to).get_center()
	shake(8.5 if is_temporal else (5.2 if is_capture else 2.5))
	_add_ripple(target_center, is_capture, is_temporal)
	if is_temporal:
		emit_sparks(target_center, Color(0.35, 0.95, 1.0), 30, 240.0, true)
		add_floating_text("⏳ СКАЧОК ВО ВРЕМЕНИ!", target_center, Color(0.4, 0.95, 1.0), 22)
	elif is_capture:
		emit_sparks(target_center, Color(1.0, 0.35, 0.4), 22, 180.0)
		add_floating_text("⚔ ВЗЯТИЕ!", target_center, Color(1.0, 0.4, 0.4), 19)
	else:
		emit_sparks(target_center, Color(0.4, 0.8, 1.0), 8, 90.0)

	_moving_piece = {}
	is_animating = false
	queue_redraw()


func shake(amount: float) -> void:
	_shake_amount = maxf(_shake_amount, amount)
	queue_redraw()


func emit_sparks(pos: Vector2, color: Color, count: int = 24, speed: float = 180.0, is_crit: bool = false) -> void:
	for i in count:
		var angle := randf() * TAU
		var spd := randf_range(speed * 0.35, speed * (1.5 if is_crit else 1.15))
		var vel := Vector2(cos(angle), sin(angle)) * spd
		var col := color
		if is_crit and randf() > 0.35:
			col = Color(1.0, randf_range(0.82, 1.0), randf_range(0.2, 0.45))
		_sparks.append({
			"pos": pos,
			"vel": vel,
			"color": col,
			"size": randf_range(3.5, 7.0) if is_crit else randf_range(2.0, 4.5),
			"life": randf_range(0.35, 0.65),
			"timer": 0.0,
			"alpha": 1.0,
			"drag": randf_range(0.89, 0.95),
			"is_star": is_crit and (i % 2 == 0)
		})


func add_floating_text(text: String, pos: Vector2, color: Color, font_size: int = 18) -> void:
	_floating_texts.append({
		"text": text,
		"pos": pos,
		"color": color,
		"timer": 0.0,
		"life": 0.95,
		"font_size": font_size,
		"vel": Vector2(randf_range(-14.0, 14.0), -68.0)
	})


func _add_ripple(center: Vector2, is_capture: bool, is_temporal: bool) -> void:
	if is_temporal:
		_ripples.append({
			"center": center,
			"radius": SQ * 0.1,
			"max_radius": SQ * 1.5,
			"color": Color(0.35, 0.95, 1.0, 1.0),
			"width": 4.5,
			"life": 0.45,
			"timer": 0.0,
			"is_temporal": true,
		})
		_ripples.append({
			"center": center,
			"radius": SQ * 0.1,
			"max_radius": SQ * 1.0,
			"color": Color(0.9, 0.45, 1.0, 0.9),
			"width": 3.0,
			"life": 0.38,
			"timer": 0.0,
			"is_temporal": true,
		})
	else:
		var col := Color(1.0, 0.3, 0.35, 0.9) if is_capture else Color(0.3, 0.85, 1.0, 0.8)
		_ripples.append({
			"center": center,
			"radius": SQ * 0.15,
			"max_radius": SQ * 0.9,
			"color": col,
			"width": 3.0,
			"life": 0.32,
			"timer": 0.0,
			"is_temporal": false,
		})


# ---------------------------------------------------------------- геометрия

func board_size() -> Vector2:
	return Vector2(state.w, state.h) * SQ


func gap() -> float:
	return SQ * 1.65


func min_t() -> int:
	var key: int = state.timelines.size()
	if key != _min_t_key:
		var m: int = 0
		for l in state.timelines:
			m = mini(m, state.start_t(l))
		_min_t_cache = m
		_min_t_key = key
	return _min_t_cache


func board_origin(l: int, t: int) -> Vector2:
	var bs: Vector2 = board_size()
	var row: int = -l if flip else l
	return Vector2((t - min_t()) * (bs.x + gap()), row * (bs.y + gap()))


func square_rect(v: Vector4i) -> Rect2:
	var o: Vector2 = board_origin(v.w, v.z)
	var cx: int = state.w - 1 - v.x if flip else v.x
	var cy: int = v.y if flip else state.h - 1 - v.y
	return Rect2(o + Vector2(cx, cy) * SQ, Vector2(SQ, SQ))


func world_to_square(p: Vector2) -> Vector4i:
	var bs: Vector2 = board_size()
	var cw: float = bs.x + gap()
	var ch: float = bs.y + gap()
	var col: int = floori(p.x / cw)
	var row: int = floori(p.y / ch)
	var lx: float = p.x - col * cw
	var ly: float = p.y - row * ch
	if lx < 0 or ly < 0 or lx >= bs.x or ly >= bs.y:
		return Vector4i(-1, -1, 0, 0)
	var t: int = col + min_t()
	var l: int = -row if flip else row
	if not state.has_board(l, t):
		return Vector4i(-1, -1, 0, 0)
	var cx: int = floori(lx / SQ)
	var cy: int = floori(ly / SQ)
	var x: int = state.w - 1 - cx if flip else cx
	var y: int = cy if flip else state.h - 1 - cy
	return Vector4i(x, y, t, l)


func screen_to_world(p: Vector2) -> Vector2:
	return (p - offset) / zoom


func center_on(world: Vector2, smooth: bool = false) -> void:
	var target_offset: Vector2 = size / 2.0 - world * zoom
	if smooth and is_inside_tree():
		if _cam_tween:
			_cam_tween.kill()
		_cam_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_cam_tween.tween_property(self, "offset", target_offset, 0.45)
	else:
		offset = target_offset
	queue_redraw()


## Показать доски настоящего с плавной анимацией камеры.
func focus_present(smooth: bool = true) -> void:
	if state == null:
		return
	var ls: Array = state.mandatory_timelines()
	if ls.is_empty():
		ls = state.playable_timelines()
	if ls.is_empty():
		ls = state.timeline_ids()
	var r := Rect2()
	var first := true
	for l in ls:
		var br := Rect2(board_origin(l, state.end_t(l)), board_size())
		r = br if first else r.merge(br)
		first = false
	_move_camera(r, 0.18, 1.5, smooth)


## Сфокусировать камеру на конкретной доске (l, t).
func focus_board(l: int, t: int, smooth: bool = true) -> void:
	if state == null or not state.has_board(l, t):
		return
	_move_camera(Rect2(board_origin(l, t), board_size()), 0.35, 1.3, smooth)


## Вписать прямоугольник мира `r` в экран (с полями) и переместить туда камеру.
func _move_camera(r: Rect2, min_zoom: float, max_zoom: float, smooth: bool) -> void:
	var fit: float = minf(size.x / (r.size.x + SQ * 4.5), size.y / (r.size.y + SQ * 4.5))
	var target_zoom: float = clampf(fit, min_zoom, max_zoom)
	var target_world: Vector2 = r.get_center()
	if smooth and is_inside_tree():
		if _cam_tween:
			_cam_tween.kill()
		_cam_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_cam_tween.tween_property(self, "zoom", target_zoom, 0.45)
		_cam_tween.tween_property(self, "offset", size / 2.0 - target_world * target_zoom, 0.45)
	else:
		zoom = target_zoom
		center_on(target_world, false)


func refresh() -> void:
	queue_redraw()


# ---------------------------------------------------------------- ввод

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var e: InputEventScreenTouch = event
		if e.pressed:
			if _cam_tween:
				_cam_tween.kill()
			_pan_velocity = Vector2.ZERO
			_touches[e.index] = e.position
			if _touches.size() == 1:
				_drag_dist = 0.0
			elif _touches.size() == 2:
				_pinch_dist = _pinch_span()
		else:
			if _touches.size() == 1 and _drag_dist < 18.0:
				_tap(e.position)
			_touches.erase(e.index)
			# Один палец остался после щипка — не считаем его последующее отпускание тапом.
			if _touches.size() == 1:
				_drag_dist = 999.0
				_pan_velocity = Vector2.ZERO
		accept_event()
	elif event is InputEventScreenDrag:
		var e: InputEventScreenDrag = event
		if _touches.size() >= 2:
			_touches[e.index] = e.position
			var d: float = _pinch_span()
			if _pinch_dist > 0.0 and d > 0.0:
				_zoom_at(_pinch_mid(), d / _pinch_dist)
			_pinch_dist = d
			_drag_dist = 999.0
			_pan_velocity = Vector2.ZERO
		else:
			_touches[e.index] = e.position
			_drag_dist += e.relative.length()
			if _drag_dist >= 12.0:
				offset += e.relative
				_pan_velocity = e.velocity
				queue_redraw()
		accept_event()
	elif event is InputEventMouseButton:
		var e: InputEventMouseButton = event
		if e.pressed and e.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_at(e.position, 1.14)
		elif e.pressed and e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_at(e.position, 1.0 / 1.14)
	elif event is InputEventMagnifyGesture:
		var e: InputEventMagnifyGesture = event
		_zoom_at(e.position, e.factor)
	elif event is InputEventPanGesture:
		var e: InputEventPanGesture = event
		offset -= e.delta * 22.0
		queue_redraw()


func _pinch_span() -> float:
	var pts: Array = _touches.values()
	return (pts[0] as Vector2).distance_to(pts[1]) if pts.size() >= 2 else 0.0


func _pinch_mid() -> Vector2:
	var pts: Array = _touches.values()
	return ((pts[0] as Vector2) + (pts[1] as Vector2)) / 2.0


func _zoom_at(p: Vector2, factor: float) -> void:
	if _cam_tween:
		_cam_tween.kill()
	var before: Vector2 = screen_to_world(p)
	zoom = clampf(zoom * factor, 0.08, 3.2)
	offset = p - before * zoom
	queue_redraw()


func _tap(p: Vector2) -> void:
	if state == null or not interactive:
		return
	var v: Vector4i = world_to_square(screen_to_world(p))
	square_tapped.emit(v)


# ---------------------------------------------------------------- рисование

func _draw() -> void:
	# Космический фон с градиентной глубиной
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.05, 0.09))

	# Мерцающее двухслойное звездное поле
	for s in _stars:
		var sp := Vector2(fposmod(s["pos"].x * size.x + offset.x * 0.04, size.x),
				fposmod(s["pos"].y * size.y + offset.y * 0.04, size.y))
		var twinkle: float = sin(_anim_time * float(s["speed"]) + float(s["phase"])) * 0.35 + 0.65
		var col := Color(0.8, 0.88, 1.0, float(s["alpha"]) * twinkle)
		draw_circle(sp, float(s["size"]), col)

	if state == null:
		return

	draw_set_transform(offset + _shake, 0.0, Vector2(zoom, zoom))
	var view := Rect2(screen_to_world(Vector2.ZERO), size / zoom).grow(SQ * 2.0)
	var bs: Vector2 = board_size()
	var pad: float = SQ * 0.22

	# Световой барьер «Настоящего» (Present Beam)
	var pt: int = state.present()
	var px: float = board_origin(0, pt).x - gap() * 0.32
	var beam_w: float = bs.x + gap() * 0.64
	draw_rect(Rect2(px, view.position.y, beam_w, view.size.y), COL_PRESENT_AURA)
	var laser_x: float = px + beam_w * 0.5
	var pulse: float = sin(_anim_time * 3.5) * 0.2 + 0.8
	draw_line(Vector2(laser_x, view.position.y), Vector2(laser_x, view.position.y + view.size.y),
			Color(COL_PRESENT_BEAM.r, COL_PRESENT_BEAM.g, COL_PRESENT_BEAM.b, COL_PRESENT_BEAM.a * pulse), SQ * 0.08)

	# Линии времени и ветвления
	for l in state.timelines:
		var s: int = state.start_t(l)
		var e: int = state.end_t(l)
		var a: Vector2 = board_origin(l, s) + bs / 2.0
		var b: Vector2 = board_origin(l, e) + bs / 2.0
		var tl_col: Color = _timeline_color(l, state.is_active(l))

		# Двухслойный светящийся кондуит
		draw_line(a, b, Color(tl_col.r, tl_col.g, tl_col.b, 0.18), SQ * 0.55)
		draw_line(a, b, tl_col, SQ * 0.18)

		if l != 0:
			var parent: int = int(state.timelines[l].get("p", 0))
			if state.has_board(parent, s - 1):
				var from: Vector2 = board_origin(parent, s - 1) + bs / 2.0
				_draw_curve(from, a, tl_col, SQ * 0.18)
				draw_circle(from, SQ * 0.16, tl_col)
				draw_circle(a, SQ * 0.16, tl_col)

	# Доски мультивселенной
	var recent: Array = _recent_moves()
	var last: Dictionary = _last_squares(recent)
	var threatened_squares: Dictionary = _threatened_squares()

	for l in state.timelines:
		var active: bool = state.is_active(l)
		var s: int = state.start_t(l)
		var e: int = state.end_t(l)
		for t in range(s, e + 1):
			var o: Vector2 = board_origin(l, t)
			var br := Rect2(o, bs)
			if not view.intersects(br.grow(pad * 2.0)):
				continue

			# Тень под доской для эффекта парения
			var shadow_rect: Rect2 = br.grow(pad)
			shadow_rect.position += Vector2(5.0, 7.0)
			draw_rect(shadow_rect, COL_SHADOW)

			# Рамка доски
			var frame_col: Color = COL_FRAME_W if posmod(t, 2) == GameState.WHITE else COL_FRAME_B
			if not active:
				frame_col = frame_col.darkened(0.4)
			draw_rect(br.grow(pad), frame_col)

			# Подсветка обязательных/опциональных досок
			if interactive and state.is_playable_board(l, t):
				var is_mand: bool = state.is_mandatory_board(l, t)
				var hl: Color = COL_MANDATORY if is_mand else COL_OPTIONAL
				var aura_pulse: float = sin(_anim_time * 4.0) * 0.25 + 0.75 if is_mand else 0.8
				hl.a *= aura_pulse
				draw_rect(br.grow(pad * 1.5), hl, false, pad * 0.85)

			# Аура материализации целевой доски во время хода
			if is_animating and _moving_piece.get("to", Vector4i(-1, -1, 0, 0)).w == l and _moving_piece.get("to", Vector4i(-1, -1, 0, 0)).z == t:
				var spawn_glow: float = sin(_moving_progress * PI)
				draw_rect(br.grow(pad * 1.8), Color(0.35, 0.92, 1.0, 0.65 * spawn_glow), false, pad * 0.9)

			# Особая аура и рамка доски, на которой был поставлен мат
			var is_mate_board: bool = not mate_info.is_empty() and int(mate_info.get("board_l", 99999)) == l and int(mate_info.get("board_t", -99999)) == t
			if is_mate_board:
				var m_pulse: float = sin(_anim_time * 6.0) * 0.3 + 0.7
				draw_rect(br.grow(pad * 2.4), Color(1.0, 0.2, 0.2, 0.95 * m_pulse), false, pad * 1.4)
				draw_rect(br.grow(pad * 3.8), Color(1.0, 0.85, 0.25, 0.65 * m_pulse), false, pad * 0.7)

			_draw_board(l, t, active, last, threatened_squares)

	# Подписи и бейджи (видны при умеренном и сильном приближении)
	if zoom > 0.22:
		var fs: int = int(SQ * 0.44)
		for l in state.timelines:
			var o: Vector2 = board_origin(l, state.start_t(l))
			var txt: String = ("L%+d" % l) if l != 0 else "L0"
			var col_txt: Color = _timeline_color(l, true)
			draw_string(_font, o + Vector2(-gap() * 0.85, bs.y / 2.0 + fs * 0.35), txt,
					HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col_txt)

		for l in state.timelines:
			for t in range(state.start_t(l), state.end_t(l) + 1):
				var o: Vector2 = board_origin(l, t)
				if not view.has_point(o):
					continue
				var is_mb: bool = not mate_info.is_empty() and int(mate_info.get("board_l", 99999)) == l and int(mate_info.get("board_t", -99999)) == t
				var label: String = "T%d%s" % [floori(t / 2.0) + 1, "" if posmod(t, 2) == 0 else "b"]
				var lbl_col: Color = Color(0.8, 0.86, 1.0, 0.78)
				if is_mb:
					label += "  [👑 МАТ!]"
					lbl_col = Color(1.0, 0.85, 0.3, 0.98)
				elif interactive and state.is_mandatory_board(l, t):
					label += "  ⚡ ОБЯЗ. ХОД"
					lbl_col = COL_MANDATORY
				elif interactive and state.is_playable_board(l, t):
					label += "  ✦ ДОСТУПНА"
					lbl_col = COL_OPTIONAL
				draw_string(_font, o + Vector2(2.0, -pad - 5.0), label,
						HORIZONTAL_ALIGNMENT_LEFT, -1, int(fs * 0.68), lbl_col)

	# Направляющие квантовые лучи к темпоральным целям выбранной фигуры
	if selected.x >= 0 and not targets.is_empty():
		var sel_c: Vector2 = square_rect(selected).get_center()
		var guide_pulse: float = sin(_anim_time * 5.0) * 0.2 + 0.65
		for tgt in targets:
			var tv: Vector4i = tgt
			if tv.z != selected.z or tv.w != selected.w:
				var dst_c: Vector2 = square_rect(tv).get_center()
				_draw_curve(sel_c, dst_c, Color(0.88, 0.45, 1.0, 0.55 * guide_pulse), SQ * 0.08)

	# Стрелка тактической подсказки (💡 Совет)
	if not hint_move.is_empty() and hint_move.has("f") and hint_move.has("t"):
		var hf: Vector4i = hint_move["f"]
		var ht: Vector4i = hint_move["t"]
		var h_pulse: float = sin(_anim_time * 6.0) * 0.2 + 0.8
		_draw_arrow(square_rect(hf).get_center(), square_rect(ht).get_center(), Color(0.25, 0.98, 0.72, 0.95 * h_pulse))

	# Стрелки ходов (последний ход соперника и текущий ход)
	for m in recent:
		var f: Vector4i = m["f"]
		var to: Vector4i = m["t"]
		if f.z == to.z and f.w == to.w:
			continue
		var dst := Vector4i(to.x, to.y, to.z + 1, int(m.get("nl", to.w)))
		if not state.has_board(dst.w, dst.z):
			dst = to
		_draw_arrow(square_rect(f).get_center(), square_rect(dst).get_center(), Color(0.75, 0.5, 1.0, 0.9))

	# Стрелки и лазеры угроз королям
	var cur_threats: Array = mate_info.get("threats", threats) if not mate_info.is_empty() else threats
	if interactive or not mate_info.is_empty():
		for pair in cur_threats:
			var a: Vector4i = pair[0]
			var b: Vector4i = pair[1]
			_draw_threat_beam(square_rect(a).get_center(), square_rect(b).get_center())

	# Анимированные волны приземления
	for rip in _ripples:
		draw_arc(rip["center"], rip["radius"], 0.0, TAU, 24, rip["color"], rip["width"])
		if bool(rip.get("is_temporal", false)):
			for ray_i in 4:
				var ray_ang: float = ray_i * (PI / 2.0) + PI / 4.0
				var ray_dir := Vector2(cos(ray_ang), sin(ray_ang))
				draw_line(rip["center"], rip["center"] + ray_dir * rip["radius"] * 1.15, rip["color"], rip["width"] * 0.6)

	# Процедурные искры и квантовые частицы
	for sp in _sparks:
		var sp_col: Color = sp["color"]
		sp_col.a *= float(sp["alpha"])
		var sp_sz: float = float(sp["size"])
		var sp_pos: Vector2 = sp["pos"]
		draw_circle(sp_pos, sp_sz, sp_col)
		if bool(sp.get("is_star", false)):
			draw_line(sp_pos - Vector2(sp_sz * 1.8, 0), sp_pos + Vector2(sp_sz * 1.8, 0), sp_col, 1.2)
			draw_line(sp_pos - Vector2(0, sp_sz * 1.8), sp_pos + Vector2(0, sp_sz * 1.8), sp_col, 1.2)

	# Всплывающий тактический текст
	for ft in _floating_texts:
		var k: float = ft["timer"] / ft["life"]
		var alpha: float = clampf((1.0 - k) * 1.6, 0.0, 1.0)
		var scale_punch: float = 1.0
		if k < 0.22:
			scale_punch = lerpf(1.45, 1.0, k / 0.22)
		var c: Color = ft["color"]
		c.a = alpha
		var f_size: int = int(float(ft["font_size"]) * scale_punch)
		var str_val: String = ft["text"]
		var str_w: float = _font.get_string_size(str_val, HORIZONTAL_ALIGNMENT_CENTER, -1, f_size).x
		var draw_p: Vector2 = (ft["pos"] as Vector2) + Vector2(-str_w * 0.5, 0.0)
		draw_string(_font, draw_p + Vector2(2, 2), str_val, HORIZONTAL_ALIGNMENT_CENTER, -1, f_size, Color(0, 0, 0, alpha * 0.9))
		draw_string(_font, draw_p, str_val, HORIZONTAL_ALIGNMENT_CENTER, -1, f_size, c)

	# Анимированная летящая фигура
	if not _moving_piece.is_empty():
		_draw_moving_piece()

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_board(l: int, t: int, active: bool, last: Dictionary, threatened_kings: Dictionary) -> void:
	var board: PackedByteArray = state.get_board(l, t)
	var dim: float = 1.0 if active else 0.55
	var moving_from: Vector4i = _moving_piece.get("from", Vector4i(-1, -1, 0, 0))
	var moving_dest: Vector4i = _moving_piece.get("to", Vector4i(-1, -1, 0, 0))

	for y in state.h:
		for x in state.w:
			var v := Vector4i(x, y, t, l)
			var r: Rect2 = square_rect(v)
			var is_light: bool = (x + y) % 2 == 1
			var c: Color = COL_LIGHT if is_light else COL_DARK
			if not active:
				c = c.darkened(0.42)
			draw_rect(r, c)

			# Подсветка последнего хода
			if last.has(v):
				draw_rect(r, COL_LAST)

			# Подсветка матованного короля и решающего удара
			var is_mated_king: bool = not mate_info.is_empty() and mate_info.get("king", Vector4i(-1, -1, -1, -1)) == v
			var is_mate_attacker: bool = not mate_info.is_empty() and mate_info.get("attacker", Vector4i(-1, -1, -1, -1)) == v

			if is_mated_king:
				var m_pulse: float = sin(_anim_time * 8.0) * 0.35 + 0.65
				draw_rect(r, Color(1.0, 0.1, 0.2, 0.65 * m_pulse))
				draw_rect(r.grow(-2), Color(1.0, 0.95, 0.3, 0.95 * m_pulse), false, 3.5)
				_draw_reticle(r, Color(1.0, 0.3, 0.3))
			elif is_mate_attacker:
				var a_pulse: float = sin(_anim_time * 6.0) * 0.3 + 0.7
				draw_rect(r, Color(1.0, 0.85, 0.2, 0.45 * a_pulse))
				draw_rect(r.grow(-2), Color(1.0, 0.85, 0.2, 0.95 * a_pulse), false, 2.5)
			elif active and threatened_kings.has(v):
				var pulse: float = sin(_anim_time * 6.0) * 0.35 + 0.65
				draw_rect(r, Color(1.0, 0.15, 0.15, 0.45 * pulse))
				draw_rect(r.grow(-2), Color(1.0, 0.25, 0.25, 0.9 * pulse), false, 2.5)

			# Выделенная фигура
			if v == selected:
				draw_rect(r, COL_SELECT)
				_draw_reticle(r, Color(0.2, 0.9, 1.0))
			elif not hint_move.is_empty():
				var hf: Vector4i = hint_move.get("f", Vector4i(-1, -1, -1, -1))
				var ht: Vector4i = hint_move.get("t", Vector4i(-1, -1, -1, -1))
				if v == hf or v == ht:
					var hp: float = sin(_anim_time * 6.5) * 0.25 + 0.75
					draw_rect(r, Color(0.2, 0.95, 0.68, 0.36 * hp))
					_draw_reticle(r, Color(0.25, 1.0, 0.72, 0.95 * hp), 2.5)

			# Отрисовка фигуры
			var p: int = board[y * state.w + x]
			if p != GameState.EMPTY:
				if is_animating and v == moving_dest:
					# Фигура в полёте: на клетке приземления рисуем маркер прицеливания
					var land_pulse: float = sin(_anim_time * 12.0) * 0.25 + 0.75
					_draw_reticle(r, Color(0.35, 0.95, 1.0, 0.65 * land_pulse), 2.0)
				elif is_animating and v == moving_from:
					# След старта фигуры на исходной доске
					var takeoff_fade: float = clampf(1.0 - _moving_progress * 1.5, 0.0, 1.0)
					PieceArt.draw_piece(self, p, r.grow(-SQ * 0.04), dim * takeoff_fade * 0.45, get_skin_for_piece(p))
					draw_circle(r.get_center(), SQ * 0.3 * takeoff_fade, Color(0.3, 0.85, 1.0, 0.25 * takeoff_fade))
				else:
					PieceArt.draw_piece(self, p, r.grow(-SQ * 0.04), dim, get_skin_for_piece(p))

			# Подсветка целей для хода
			if targets.has(v):
				var is_capture: bool = p != GameState.EMPTY
				var is_temporal: bool = (v.z != selected.z or v.w != selected.w)
				if is_temporal:
					_draw_temporal_target(r)
				elif is_capture:
					_draw_capture_target(r)
				else:
					_draw_move_dot(r)

	# Координаты по краям доски (a-h, 1-8) при сильном приближении
	if zoom > 0.45:
		_draw_board_coordinates(l, t)


func _draw_board_coordinates(l: int, t: int) -> void:
	var fs: int = int(SQ * 0.22)
	var col_coord := Color(0.7, 0.76, 0.9, 0.6)
	var o: Vector2 = board_origin(l, t)
	for x in state.w:
		var file_char: String = char(97 + (state.w - 1 - x if flip else x))
		draw_string(_font, o + Vector2(x * SQ + SQ * 0.38, -3.0), file_char,
				HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col_coord)
	for y in state.h:
		var rank_num: String = str((y + 1) if flip else (state.h - y))
		draw_string(_font, o + Vector2(-fs * 1.2, y * SQ + SQ * 0.62), rank_num,
				HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col_coord)


func _draw_reticle(r: Rect2, col: Color, w: float = 2.5) -> void:
	# Угловые скобки вокруг клетки
	var arm: float = r.size.x * 0.22
	var tr := Vector2(r.end.x, r.position.y)
	var bl := Vector2(r.position.x, r.end.y)
	draw_line(r.position, r.position + Vector2(arm, 0), col, w)
	draw_line(r.position, r.position + Vector2(0, arm), col, w)
	draw_line(tr, tr + Vector2(-arm, 0), col, w)
	draw_line(tr, tr + Vector2(0, arm), col, w)
	draw_line(bl, bl + Vector2(arm, 0), col, w)
	draw_line(bl, bl + Vector2(0, -arm), col, w)
	draw_line(r.end, r.end - Vector2(arm, 0), col, w)
	draw_line(r.end, r.end - Vector2(0, arm), col, w)


func _draw_move_dot(r: Rect2) -> void:
	var c: Vector2 = r.get_center()
	draw_circle(c, SQ * 0.17, COL_TARGET)
	draw_circle(c, SQ * 0.08, Color(1, 1, 1, 0.9))


func _draw_capture_target(r: Rect2) -> void:
	var pulse: float = sin(_anim_time * 6.0) * 0.2 + 0.8
	var col := Color(COL_TARGET_CAPTURE.r, COL_TARGET_CAPTURE.g, COL_TARGET_CAPTURE.b, COL_TARGET_CAPTURE.a * pulse)
	draw_rect(r.grow(-2), col, false, SQ * 0.08)
	var c: Vector2 = r.get_center()
	draw_circle(c, SQ * 0.14, col)


func _draw_temporal_target(r: Rect2) -> void:
	var c: Vector2 = r.get_center()
	var pulse: float = sin(_anim_time * 5.0) * 0.25 + 0.75
	var col := Color(COL_TARGET_TIME.r, COL_TARGET_TIME.g, COL_TARGET_TIME.b, COL_TARGET_TIME.a * pulse)
	draw_circle(c, SQ * 0.32, Color(col.r, col.g, col.b, 0.25))
	draw_arc(c, SQ * 0.26, 0.0, TAU, 24, col, 2.5)
	draw_circle(c, SQ * 0.1, col)


func _timeline_color(l: int, active: bool) -> Color:
	var col: Color
	if l == 0:
		col = Color(0.25, 0.75, 1.0) # Line 0: Cyan
	elif l > 0:
		col = Color(1.0, 0.78, 0.28) # White branches: Gold
	else:
		col = Color(0.85, 0.45, 1.0) # Black branches: Neon violet
	if not active:
		col = col.darkened(0.4)
		col.a = 0.35
	return col


func _threatened_squares() -> Dictionary:
	var d: Dictionary = {}
	for pair in threats:
		d[pair[1]] = true
	return d


## Ходы последнего завершённого хода соперника + ходы текущего (ещё не отправленного) хода.
func _recent_moves() -> Array:
	var ms: Array = []
	if not state.history.is_empty():
		ms.append_array(state.history[-1])
	ms.append_array(state.turn_moves)
	return ms


func _last_squares(moves: Array) -> Dictionary:
	var d: Dictionary = {}
	for m in moves:
		d[m["f"]] = true
		d[m["t"]] = true
	return d


func _draw_curve(a: Vector2, b: Vector2, col: Color, width: float) -> void:
	var pts := PackedVector2Array()
	var c1 := Vector2((a.x + b.x) / 2.0, a.y)
	var c2 := Vector2((a.x + b.x) / 2.0, b.y)
	for i in 21:
		var k: float = i / 20.0
		var p: Vector2 = a.bezier_interpolate(c1, c2, b, k)
		pts.append(p)
	draw_polyline(pts, Color(col.r, col.g, col.b, 0.25), width * 2.5, true)
	draw_polyline(pts, col, width, true)


func _draw_arrow(a: Vector2, b: Vector2, col: Color) -> void:
	var w: float = SQ * 0.14
	var dir: Vector2 = (b - a).normalized()
	if dir == Vector2.ZERO:
		return
	var tip: Vector2 = b - dir * SQ * 0.25
	draw_line(a, tip - dir * SQ * 0.3, col, w, true)
	var n := Vector2(-dir.y, dir.x)
	var head := PackedVector2Array([tip, tip - dir * SQ * 0.45 + n * SQ * 0.25, tip - dir * SQ * 0.45 - n * SQ * 0.25])
	draw_colored_polygon(head, col)


func _draw_threat_beam(a: Vector2, b: Vector2) -> void:
	var pulse: float = sin(_anim_time * 8.0) * 0.25 + 0.75
	var col := Color(COL_THREAT.r, COL_THREAT.g, COL_THREAT.b, COL_THREAT.a * pulse)
	var glow := Color(col.r, col.g, col.b, 0.25 * pulse)
	draw_line(a, b, glow, SQ * 0.4, true)
	_draw_arrow(a, b, col)


func _draw_moving_piece() -> void:
	var progress: float = float(_moving_piece.get("progress", 0.0))
	var from_v: Vector4i = _moving_piece["from"]
	var to_v: Vector4i = _moving_piece["to"]
	var p_code: int = int(_moving_piece["piece"])
	var from_r: Rect2 = square_rect(from_v)
	var to_r: Rect2 = square_rect(to_v)
	var is_temp: bool = bool(_moving_piece.get("is_temporal", false))

	if not is_temp:
		_draw_spatial_travel(from_r, to_r, progress, p_code)
	else:
		_draw_temporal_travel(from_r, to_r, progress, p_code)


func _draw_spatial_travel(from_r: Rect2, to_r: Rect2, progress: float, p_code: int) -> void:
	var p0: Vector2 = from_r.get_center()
	var p1: Vector2 = to_r.get_center()
	var dist: float = p0.distance_to(p1)
	var altitude: float = sin(progress * PI)
	var arc_h: float = clampf(SQ * 1.35 + dist * 0.16, SQ * 1.2, SQ * 4.2)
	var arc: float = -arc_h * altitude
	var cur_pos: Vector2 = p0.lerp(p1, progress) + Vector2(0.0, arc)

	# 1. Динамическая тень на плоскости доски
	var ground_pos: Vector2 = p0.lerp(p1, progress) + Vector2(SQ * 0.06, SQ * 0.14)
	var s_radius: float = SQ * (0.32 + altitude * 0.18)
	var s_alpha: float = clampf(0.42 - altitude * 0.22, 0.14, 0.45)
	draw_circle(ground_pos, s_radius, Color(0.0, 0.0, 0.0, s_alpha))

	# 2. Светящийся кометный шлейф и призрачные силуэты (Motion Trail)
	var is_black: bool = (p_code & GameState.BLACK_BIT) != 0
	var trail_base_col := Color(0.85, 0.45, 1.0) if is_black else Color(0.35, 0.85, 1.0)
	for dt in [0.035, 0.07, 0.105]:
		var tp: float = maxf(0.0, progress - dt)
		var t_alt: float = sin(tp * PI)
		var t_arc: float = -arc_h * t_alt
		var t_pos: Vector2 = p0.lerp(p1, tp) + Vector2(0.0, t_arc)
		var t_alpha: float = (1.0 - dt / 0.12) * 0.34 * altitude
		draw_circle(t_pos, SQ * 0.24, Color(trail_base_col.r, trail_base_col.g, trail_base_col.b, t_alpha * 0.5))
		PieceArt.draw_piece(self, p_code, Rect2(t_pos - Vector2(SQ, SQ) * 0.5, Vector2(SQ, SQ)).grow(-SQ * 0.04), t_alpha * 0.6, get_skin_for_piece(p_code))

	# 3. Энергетическая аура вокруг летящей фигуры
	draw_circle(cur_pos, SQ * 0.5, Color(trail_base_col.r, trail_base_col.g, trail_base_col.b, 0.22 * altitude))
	draw_circle(cur_pos, SQ * 0.36, Color(1.0, 1.0, 1.0, 0.25 * altitude))

	# 4. Кинетическое растяжение/сжатие (Squash & Stretch)
	var scale_x: float = 1.0
	var scale_y: float = 1.0
	if progress < 0.18:
		# Взлёт — растяжение по вертикали
		var k: float = progress / 0.18
		scale_y = lerpf(0.92, 1.14, k)
		scale_x = lerpf(1.08, 0.90, k)
	elif progress > 0.84:
		# Приземление — амортизация и сжатие
		var k: float = (progress - 0.84) / 0.16
		scale_y = lerpf(1.10, 0.88, k)
		scale_x = lerpf(0.92, 1.12, k)
	else:
		scale_x = 1.0
		scale_y = 1.0

	var draw_sz: Vector2 = Vector2(SQ * scale_x, SQ * scale_y)
	var draw_r := Rect2(cur_pos - draw_sz * 0.5, draw_sz).grow(-SQ * 0.04)

	# 5. Отрисовка самой фигуры
	PieceArt.draw_piece(self, p_code, draw_r, 1.0, get_skin_for_piece(p_code))


func _draw_temporal_travel(from_r: Rect2, to_r: Rect2, progress: float, p_code: int) -> void:
	var p0: Vector2 = from_r.get_center()
	var p3: Vector2 = to_r.get_center()
	var dist: float = p0.distance_to(p3)
	var arc_h: float = clampf(dist * 0.45, SQ * 2.2, SQ * 8.0)
	var c1 := Vector2(lerpf(p0.x, p3.x, 0.22), minf(p0.y, p3.y) - arc_h)
	var c2 := Vector2(lerpf(p0.x, p3.x, 0.78), minf(p0.y, p3.y) - arc_h)

	# 1. Тоннель червоточины сквозь пространство-время
	var pts := PackedVector2Array()
	var segs: int = 32
	for i in range(segs + 1):
		var u: float = float(i) / segs
		pts.append(p0.bezier_interpolate(c1, c2, p3, u))

	var alpha_flow: float = sin(progress * PI)
	# Внешнее свечение пространственного рукава
	draw_polyline(pts, Color(0.68, 0.32, 1.0, 0.35 * alpha_flow), SQ * 0.48, true)
	# Внутренний электрический сердечник червоточины
	draw_polyline(pts, Color(0.35, 0.92, 1.0, 0.75 * alpha_flow), SQ * 0.16, true)

	# Бегущие квантовые волны вдоль червоточины
	for k in 3:
		var pulse_prog: float = fposmod(progress * 2.2 + k * 0.33, 1.0)
		var pulse_pt: Vector2 = p0.bezier_interpolate(c1, c2, p3, pulse_prog)
		var p_alpha: float = sin(pulse_prog * PI) * alpha_flow
		draw_circle(pulse_pt, SQ * 0.18, Color(1, 1, 1, 0.85 * p_alpha))
		draw_circle(pulse_pt, SQ * 0.32, Color(0.3, 0.9, 1.0, 0.45 * p_alpha))

	# 2. Входной портал отправления (Source Portal)
	var dep_fade: float = clampf(1.0 - progress * 1.3, 0.0, 1.0)
	if dep_fade > 0.01:
		# Тёмная гравитационная сингулярность
		draw_circle(p0, SQ * 0.38 * dep_fade, Color(0.03, 0.02, 0.08, 0.92 * dep_fade))
		# Внешнее вращающееся кольцо горизонта событий
		draw_arc(p0, SQ * 0.52 * dep_fade, _anim_time * 6.5, _anim_time * 6.5 + PI * 1.5, 20, Color(0.35, 0.85, 1.0, 0.95 * dep_fade), 3.0)
		# Внутреннее контр-вращающееся фиолетовое кольцо
		draw_arc(p0, SQ * 0.34 * dep_fade, -_anim_time * 8.5, -_anim_time * 8.5 + PI * 1.4, 16, Color(0.9, 0.38, 1.0, 0.85 * dep_fade), 2.5)
		# Искры, втягивающиеся в сингулярность
		for sp in 4:
			var sp_phase: float = fposmod(_anim_time * 2.8 + sp * 0.25, 1.0)
			var sp_r: float = lerpf(SQ * 0.55, SQ * 0.1, sp_phase) * dep_fade
			var sp_ang: float = sp * (TAU / 4.0) + _anim_time * 4.0
			draw_circle(p0 + Vector2(cos(sp_ang), sin(sp_ang)) * sp_r, 2.5, Color(1, 1, 1, dep_fade * (1.0 - sp_phase)))

	# 3. Выходной портал прибытия на целевой доске (Destination Rift)
	var arr_fade: float = clampf((progress - 0.25) / 0.75, 0.0, 1.0)
	if arr_fade > 0.01:
		# Прицельные угловые маркеры вокруг целевой клетки
		var brk_col := Color(0.4, 0.95, 1.0, arr_fade * (0.6 + sin(_anim_time * 10.0) * 0.3))
		_draw_reticle(to_r, brk_col, 2.0)

		# Раскрывающийся фиолетовый разрыв пространства
		draw_arc(p3, SQ * 0.5 * arr_fade, -_anim_time * 7.5, -_anim_time * 7.5 + PI * 1.6, 20, Color(0.92, 0.45, 1.0, arr_fade * 0.9), 3.0)
		draw_circle(p3, SQ * 0.24 * arr_fade, Color(0.35, 0.95, 1.0, arr_fade * 0.45))

	# 4. Релятивистский шлейф призраков фигуры (Ghost Trail)
	for trail_i in [0.035, 0.07, 0.105]:
		var tp: float = maxf(0.0, progress - trail_i)
		var g_pos: Vector2 = p0.bezier_interpolate(c1, c2, p3, tp)
		var g_alpha: float = (1.0 - trail_i / 0.12) * 0.38 * alpha_flow
		PieceArt.draw_piece(self, p_code, Rect2(g_pos - Vector2(SQ, SQ) * 0.5, Vector2(SQ, SQ)).grow(-SQ * 0.04), g_alpha, get_skin_for_piece(p_code))

	# 5. Сама фигура во время темпорального скачка
	var cur_pos: Vector2 = p0.bezier_interpolate(c1, c2, p3, progress)

	# Квантовая защитная аура вокруг летящей фигуры
	var aura_col := Color(0.85, 0.45, 1.0, 0.45 * alpha_flow)
	draw_circle(cur_pos, SQ * 0.62, aura_col)
	draw_circle(cur_pos, SQ * 0.46, Color(0.35, 0.92, 1.0, 0.35 * alpha_flow))
	# 3 вращающиеся квантовые частицы вокруг фигуры
	for s in 3:
		var s_ang: float = _anim_time * 12.0 + s * (TAU / 3.0)
		var s_pt: Vector2 = cur_pos + Vector2(cos(s_ang), sin(s_ang)) * (SQ * 0.52)
		draw_circle(s_pt, 3.5, Color(1, 1, 1, 0.95))
		draw_circle(s_pt, 6.0, Color(0.35, 0.92, 1.0, 0.45))

	# Пространственная тень
	draw_circle(cur_pos + Vector2(4.0, 10.0), SQ * 0.36, Color(0, 0, 0, 0.4))
	# Отрисовка фигуры
	PieceArt.draw_piece(self, p_code, Rect2(cur_pos - Vector2(SQ, SQ) * 0.5, Vector2(SQ, SQ)).grow(-SQ * 0.04), 1.0, get_skin_for_piece(p_code))
