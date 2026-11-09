class_name MultiChessView
extends Control
## Отрисовка и интерактивное управление доской мульти-шахмат 14×14 в форме креста.
## Поддерживает анимации ходов, адаптивный масштаб без перекрытия панелей,
## подсветку угроз королям (шах), а также визуализацию направлений армий.

signal move_requested(from_pos: Vector2i, to_pos: Vector2i)

var state: MultiChessState
var human_player: int = MultiChessState.WHITE
var is_pass_and_play: bool = false
var is_d20_mode: bool = false
var locked: bool = false

var selected_pos := Vector2i(-1, -1)
var hovered_pos := Vector2i(-1, -1)
var legal_destinations: Array = []  # Array[Vector2i]
var hint_move: Dictionary = {}
var animating_move: Dictionary = {}  # {"from": Vector2, "to": Vector2, "piece": int, "t": float}
var mate_cell := Vector2i(-1, -1)
var player_skins: Dictionary = {}

var _pulse_time: float = 0.0

# Визуальные эффекты (Game Juice FX)
var _shake_amount: float = 0.0
var _shake: Vector2 = Vector2.ZERO
var _ripples: Array = []
var _sparks: Array = []
var _floating_texts: Array = []

# Цвета доски
const LIGHT_SQUARE := Color(0.86, 0.89, 0.95)
const DARK_SQUARE  := Color(0.30, 0.38, 0.54)
const BORDER_COLOR := Color(0.14, 0.18, 0.30, 0.75)


func _ready() -> void:
	custom_minimum_size = Vector2(320, 320)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_exited.connect(func():
		hovered_pos = Vector2i(-1, -1)
		queue_redraw())


func _process(delta: float) -> void:
	_pulse_time += delta

	# 1. Тряска экрана (Screen Shake)
	if _shake_amount > 0.0:
		_shake = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_amount
		_shake_amount = move_toward(_shake_amount, 0.0, delta * 32.0)
	else:
		_shake = Vector2.ZERO

	# 2. Обновление взрывных волн (Shockwaves / Ripples)
	if not _ripples.is_empty():
		var rem_r := []
		for r in _ripples:
			r["timer"] += delta
			var k: float = r["timer"] / r["life"]
			if k < 1.0:
				r["radius"] = lerpf(float(r.get("start_r", 4.0)), float(r["max_radius"]), ease(k, 0.35))
				r["alpha"] = (1.0 - k)
				rem_r.append(r)
		_ripples = rem_r

	# 3. Обновление процедурных искр и осколков (Sparks & Debris)
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

	# 4. Обновление всплывающих тактических надписей (Floating Combat Text)
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

	# Плавная перерисовка
	if visible and is_inside_tree():
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if locked or state == null or state.is_game_over():
		return

	# Мышь / тач: перемещение курсора для подсветки
	if event is InputEventMouseMotion:
		var grid_pos := _screen_to_grid(event.position)
		if MultiChessState.is_valid_cell(grid_pos.x, grid_pos.y):
			if hovered_pos != grid_pos:
				hovered_pos = grid_pos
				queue_redraw()
		else:
			if hovered_pos.x != -1:
				hovered_pos = Vector2i(-1, -1)
				queue_redraw()

	# Клик мышью или тап по экрану
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var grid_pos := _screen_to_grid(event.position)
		if not MultiChessState.is_valid_cell(grid_pos.x, grid_pos.y):
			_clear_selection()
			return
		_handle_click(grid_pos)
		accept_event()
	elif event is InputEventScreenTouch and event.pressed:
		var grid_pos := _screen_to_grid(event.position)
		if not MultiChessState.is_valid_cell(grid_pos.x, grid_pos.y):
			_clear_selection()
			return
		_handle_click(grid_pos)
		accept_event()


func _handle_click(pos: Vector2i) -> void:
	# Если уже выбрана фигура и кликнули по доступной клетке для хода
	if selected_pos.x != -1 and legal_destinations.has(pos):
		var from_p := selected_pos
		hint_move.clear()
		_clear_selection()
		move_requested.emit(from_p, pos)
		return

	var p := state.get_cell(pos.x, pos.y)
	if p != MultiChessState.EMPTY:
		var owner := MultiChessState.get_piece_player(p)
		if owner == state.turn and (is_pass_and_play or owner == human_player):
			selected_pos = pos
			_update_legal_destinations()
			queue_redraw()
			return

	_clear_selection()


func _clear_selection() -> void:
	selected_pos = Vector2i(-1, -1)
	legal_destinations.clear()
	queue_redraw()


func _update_legal_destinations() -> void:
	legal_destinations.clear()
	if selected_pos.x == -1:
		return
	var all_moves := state.get_legal_moves(state.turn)
	for m in all_moves:
		if m["fx"] == selected_pos.x and m["fy"] == selected_pos.y:
			legal_destinations.append(Vector2i(m["tx"], m["ty"]))


func _screen_to_grid(pos: Vector2) -> Vector2i:
	var origin_and_size := _get_board_rect()
	var origin: Vector2 = origin_and_size[0]
	var cell_size: float = origin_and_size[1]

	var local := pos - origin
	if local.x < 0 or local.y < 0:
		return Vector2i(-1, -1)

	var gx := int(local.x / cell_size)
	var gy := MultiChessState.BOARD_SIZE - 1 - int(local.y / cell_size) # инвертируем Y для шахматной ориентации
	if gx < 0 or gx >= MultiChessState.BOARD_SIZE or gy < 0 or gy >= MultiChessState.BOARD_SIZE:
		return Vector2i(-1, -1)
	return Vector2i(gx, gy)


func _grid_to_rect(gx: int, gy: int, origin: Vector2, cell_size: float) -> Rect2:
	var screen_y := (MultiChessState.BOARD_SIZE - 1 - gy) * cell_size
	var screen_x := gx * cell_size
	return Rect2(origin + Vector2(screen_x, screen_y), Vector2(cell_size, cell_size))


func _get_board_rect() -> Array:
	var w: float = size.x
	var h: float = size.y

	# Выделяем гарантированные отступы сверху и снизу, чтобы интерфейс не перекрывал доску
	var top_pad: float = 70.0
	var bot_pad: float = 78.0
	var side_pad: float = 16.0

	var avail_w: float = maxf(80.0, w - side_pad * 2.0)
	var avail_h: float = maxf(80.0, h - top_pad - bot_pad)
	var board_size_px: float = minf(avail_w, avail_h)
	var cell_size: float = board_size_px / float(MultiChessState.BOARD_SIZE)
	var board_total: float = cell_size * MultiChessState.BOARD_SIZE

	var origin_x: float = (w - board_total) * 0.5 + _shake.x
	var origin_y: float = top_pad + (avail_h - board_total) * 0.5 + _shake.y
	return [Vector2(origin_x, origin_y), cell_size]


func get_cell_screen_rect(gx: int, gy: int) -> Rect2:
	var rect_data := _get_board_rect()
	return _grid_to_rect(gx, gy, rect_data[0], rect_data[1])


func shake(amount: float) -> void:
	_shake_amount = maxf(_shake_amount, amount)


func add_shockwave(center: Vector2, color: Color, max_r: float, duration: float = 0.42, count: int = 1) -> void:
	for i in count:
		_ripples.append({
			"center": center,
			"start_r": 4.0,
			"radius": 4.0,
			"max_radius": max_r * (1.0 + i * 0.3),
			"color": color,
			"life": duration + i * 0.08,
			"timer": 0.0,
			"alpha": 1.0,
			"width": maxf(1.5, 3.8 - i * 0.8)
		})


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


func _draw() -> void:
	if state == null:
		return

	var rect_data := _get_board_rect()
	var origin: Vector2 = rect_data[0]
	var cell_size: float = rect_data[1]

	# 1. Тень и подложка всей крестообразной формы доски (12-угольник)
	var cross_points := _get_cross_polygon_screen(origin, cell_size)
	var shadow_points := PackedVector2Array()
	for pt in cross_points:
		shadow_points.append(pt + Vector2(4, 7))
	draw_colored_polygon(shadow_points, Color(0.02, 0.03, 0.07, 0.65))

	# Матовая тёмная основа под клетки
	draw_colored_polygon(cross_points, Color(0.08, 0.11, 0.18, 0.95))

	# 2. Отрисовка клеток доски
	var pulse_sin: float = sin(_pulse_time * 5.0) * 0.5 + 0.5

	for y in MultiChessState.BOARD_SIZE:
		for x in MultiChessState.BOARD_SIZE:
			if not MultiChessState.is_valid_cell(x, y):
				continue

			var r := _grid_to_rect(x, y, origin, cell_size)
			var is_light := ((x + y) % 2) != 0
			var base_col := LIGHT_SQUARE if is_light else DARK_SQUARE

			# Подсветка последнего хода
			if not state.last_move.is_empty():
				if (state.last_move["fx"] == x and state.last_move["fy"] == y) or (state.last_move["tx"] == x and state.last_move["ty"] == y):
					base_col = base_col.lerp(Color(1.0, 0.85, 0.2), 0.45)

			# Подсветка наведения курсора
			if hovered_pos.x == x and hovered_pos.y == y and selected_pos != hovered_pos:
				base_col = base_col.lerp(Color(0.4, 0.75, 1.0), 0.28)

			# Подсветка выбранной клетки
			if selected_pos.x == x and selected_pos.y == y:
				base_col = base_col.lerp(Color(0.2, 0.9, 1.0), 0.55 + pulse_sin * 0.15)

			draw_rect(r, base_col)
			draw_rect(r, BORDER_COLOR, false, 1.0)

	# 3. Индикация шаха (подсветка клетки короля под угрозой)
	for p_idx in state.active_players:
		if not state.eliminated_players.has(p_idx) and state.is_king_threatened(p_idx):
			var king_pos := state.find_king(p_idx)
			if king_pos.x != -1:
				var kr := _grid_to_rect(king_pos.x, king_pos.y, origin, cell_size)
				var threat_col := Color(1.0, 0.2, 0.2, 0.35 + pulse_sin * 0.3)
				draw_rect(kr, threat_col)
				draw_rect(kr, Color(1.0, 0.3, 0.3, 0.9), false, 2.5)

	# 3.1 Подсветка поля мата / решающего взятия
	if mate_cell.x != -1 and mate_cell.y != -1:
		var mr := _grid_to_rect(mate_cell.x, mate_cell.y, origin, cell_size)
		var m_pulse := sin(_pulse_time * 8.0) * 0.35 + 0.65
		draw_rect(mr, Color(1.0, 0.15, 0.25, 0.6 * m_pulse))
		draw_rect(mr.grow(2), Color(1.0, 0.85, 0.25, 0.95 * m_pulse), false, 3.5)

	# 4. Рамка и световые полосы армий по краям доски
	var rim_col := Color(0.25, 0.34, 0.55, 0.85)
	for i in cross_points.size():
		var p1: Vector2 = cross_points[i]
		var p2: Vector2 = cross_points[(i + 1) % cross_points.size()]
		draw_line(p1, p2, rim_col, 2.0, true)

	_draw_army_banners(origin, cell_size)

	# 5. Метки доступных ходов
	var sel_piece := state.get_cell(selected_pos.x, selected_pos.y) if selected_pos.x != -1 else MultiChessState.EMPTY
	var sel_type := MultiChessState.get_piece_type(sel_piece) if sel_piece != MultiChessState.EMPTY else 0

	for dest in legal_destinations:
		var dr := _grid_to_rect(dest.x, dest.y, origin, cell_size)
		var center := dr.position + dr.size * 0.5
		var target := state.get_cell(dest.x, dest.y)
		if target == MultiChessState.EMPTY:
			# Свободное поле — аккуратная неоновая точка
			draw_circle(center, cell_size * 0.16, Color(0.25, 0.95, 0.45, 0.85))
		else:
			# Взятие — красное пульсирующее кольцо захвата
			var ring_r := cell_size * (0.38 + pulse_sin * 0.05)
			draw_circle(center, ring_r * 0.9, Color(1.0, 0.2, 0.2, 0.22))
			draw_arc(center, ring_r, 0, TAU, 32, Color(1.0, 0.25, 0.25, 0.95), 2.5)

	# 5.1 Подсветка тактического совета (💡 Совет)
	if not hint_move.is_empty() and hint_move.has("fx") and hint_move.has("tx"):
		var h_from := _grid_to_rect(int(hint_move["fx"]), int(hint_move["fy"]), origin, cell_size)
		var h_to := _grid_to_rect(int(hint_move["tx"]), int(hint_move["ty"]), origin, cell_size)
		var hp: float = 0.65 + pulse_sin * 0.35
		draw_rect(h_from, Color(0.2, 0.95, 0.68, 0.32 * hp))
		draw_rect(h_from.grow(-1.5), Color(0.25, 1.0, 0.72, 0.95 * hp), false, 2.2)
		draw_rect(h_to, Color(0.2, 0.95, 0.68, 0.32 * hp))
		draw_rect(h_to.grow(-1.5), Color(0.25, 1.0, 0.72, 0.95 * hp), false, 2.2)
		draw_line(h_from.get_center(), h_to.get_center(), Color(0.25, 1.0, 0.75, 0.88 * hp), 3.0, true)

	# 6. Отрисовка фигур на доске
	var piece_inset: float = cell_size * 0.075

	for y in MultiChessState.BOARD_SIZE:
		for x in MultiChessState.BOARD_SIZE:
			if not MultiChessState.is_valid_cell(x, y):
				continue
			var p := state.get_cell(x, y)
			if p == MultiChessState.EMPTY:
				continue

			# Если фигура сейчас анимируется, пропускаем её статическую отрисовку
			if not animating_move.is_empty() and animating_move["tx"] == x and animating_move["ty"] == y:
				continue

			var pr := _grid_to_rect(x, y, origin, cell_size).grow(-piece_inset)
			var p_type := MultiChessState.get_piece_type(p)
			var p_owner := MultiChessState.get_piece_player(p)
			var p_skin: String = player_skins.get(p_owner, "")
			PieceArt.draw_multi_piece(self, p_type, p_owner, pr, 1.0, p_skin)

	# 6.1 В режиме D20 рисуем бейджи порога пробития (DC X+) поверх целей для атаки
	var font := ThemeDB.fallback_font
	if is_d20_mode and sel_type > 0 and cell_size >= 18.0:
		var badge_fs: int = clampi(int(cell_size * 0.32), 9, 14)
		for dest in legal_destinations:
			var target := state.get_cell(dest.x, dest.y)
			if target != MultiChessState.EMPTY:
				var def_type := MultiChessState.get_piece_type(target)
				var dc: int = MultiChessAI._calc_d20_dc(sel_type, def_type)
				var dr := _grid_to_rect(dest.x, dest.y, origin, cell_size)
				var b_txt := "%d+" % dc
				var b_sz := font.get_string_size(b_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, badge_fs)
				var pill_w := maxf(b_sz.x + 6.0, cell_size * 0.48)
				var pill_h := float(badge_fs) + 4.0
				var pill_r := Rect2(dr.position.x + dr.size.x - pill_w - 1.0, dr.position.y + 1.0, pill_w, pill_h)
				var dc_col := Color(0.18, 0.85, 0.42, 0.92) if dc <= 8 else (Color(0.95, 0.68, 0.15, 0.94) if dc <= 12 else Color(0.92, 0.22, 0.25, 0.95))
				draw_rect(pill_r, Color(0.05, 0.07, 0.12, 0.88))
				draw_rect(pill_r, dc_col, false, 1.2)
				draw_string(font, Vector2(pill_r.position.x + (pill_w - b_sz.x) * 0.5, pill_r.position.y + pill_h - 3.0), b_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, badge_fs, dc_col.lightened(0.35))

	# 7. Отрисовка анимируемой фигуры
	if not animating_move.is_empty():
		var anim_r: Rect2 = animating_move["rect"].grow(-piece_inset)
		var anim_type: int = animating_move["type"]
		var anim_owner: int = animating_move["owner"]
		var a_skin: String = player_skins.get(anim_owner, "")
		PieceArt.draw_multi_piece(self, anim_type, anim_owner, anim_r, 1.0, a_skin)

	# 8. Отрисовка shockwave-волн
	for r in _ripples:
		var r_rad: float = float(r["radius"])
		var r_col: Color = r["color"]
		r_col.a *= float(r["alpha"])
		var r_width: float = float(r.get("width", 2.5))
		draw_arc(r["center"], r_rad, 0.0, TAU, 32, r_col, r_width)

	# 9. Отрисовка процедурных искр и осколков
	for sp in _sparks:
		var sp_col: Color = sp["color"]
		sp_col.a *= float(sp["alpha"])
		var sp_sz: float = float(sp["size"])
		var sp_pos: Vector2 = sp["pos"]
		draw_circle(sp_pos, sp_sz, sp_col)
		if bool(sp.get("is_star", false)):
			draw_line(sp_pos - Vector2(sp_sz * 1.8, 0), sp_pos + Vector2(sp_sz * 1.8, 0), sp_col, 1.2)
			draw_line(sp_pos - Vector2(0, sp_sz * 1.8), sp_pos + Vector2(0, sp_sz * 1.8), sp_col, 1.2)

	# 10. Отрисовка всплывающего тактического текста
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
		var str_w: float = font.get_string_size(str_val, HORIZONTAL_ALIGNMENT_CENTER, -1, f_size).x
		var draw_p: Vector2 = (ft["pos"] as Vector2) + Vector2(-str_w * 0.5, 0.0)
		# Двойная тень для четкости
		draw_string(font, draw_p + Vector2(2, 2), str_val, HORIZONTAL_ALIGNMENT_CENTER, -1, f_size, Color(0, 0, 0, alpha * 0.9))
		draw_string(font, draw_p, str_val, HORIZONTAL_ALIGNMENT_CENTER, -1, f_size, c)


func _draw_army_banners(origin: Vector2, cell_size: float) -> void:
	# Световые полосы у мест базирования армий
	# Юг (Белые): x=3..11, y=0
	var p_s1 := _pt_screen(3, 0, origin, cell_size)
	var p_s2 := _pt_screen(11, 0, origin, cell_size)
	draw_line(p_s1, p_s2, MultiChessState.PLAYER_COLORS[MultiChessState.WHITE], 4.0, true)

	# Запад (Красные): x=0, y=3..11
	var p_w1 := _pt_screen(0, 3, origin, cell_size)
	var p_w2 := _pt_screen(0, 11, origin, cell_size)
	draw_line(p_w1, p_w2, MultiChessState.PLAYER_COLORS[MultiChessState.RED], 4.0, true)

	# Север (Чёрные): x=3..11, y=14
	var p_n1 := _pt_screen(3, 14, origin, cell_size)
	var p_n2 := _pt_screen(11, 14, origin, cell_size)
	draw_line(p_n1, p_n2, MultiChessState.PLAYER_COLORS[MultiChessState.BLACK].lightened(0.2), 4.0, true)

	# Восток (Синие): x=14, y=3..11 (если 4 игрока)
	if state.mode != MultiChessState.MODE_1V1V1:
		var p_e1 := _pt_screen(14, 3, origin, cell_size)
		var p_e2 := _pt_screen(14, 11, origin, cell_size)
		draw_line(p_e1, p_e2, MultiChessState.PLAYER_COLORS[MultiChessState.BLUE], 4.0, true)


func _pt_screen(gx: float, gy: float, origin: Vector2, cell_size: float) -> Vector2:
	var sx := origin.x + gx * cell_size
	var sy := origin.y + (float(MultiChessState.BOARD_SIZE) - gy) * cell_size
	return Vector2(sx, sy)


func _get_cross_polygon_screen(origin: Vector2, cell_size: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	# 12 вершин греческого креста
	pts.append(_pt_screen(3, 0, origin, cell_size))
	pts.append(_pt_screen(11, 0, origin, cell_size))
	pts.append(_pt_screen(11, 3, origin, cell_size))
	pts.append(_pt_screen(14, 3, origin, cell_size))
	pts.append(_pt_screen(14, 11, origin, cell_size))
	pts.append(_pt_screen(11, 11, origin, cell_size))
	pts.append(_pt_screen(11, 14, origin, cell_size))
	pts.append(_pt_screen(3, 14, origin, cell_size))
	pts.append(_pt_screen(3, 11, origin, cell_size))
	pts.append(_pt_screen(0, 11, origin, cell_size))
	pts.append(_pt_screen(0, 3, origin, cell_size))
	pts.append(_pt_screen(3, 3, origin, cell_size))
	return pts


func animate_move(m: Dictionary, on_finished: Callable) -> void:
	var rect_data := _get_board_rect()
	var origin: Vector2 = rect_data[0]
	var cell_size: float = rect_data[1]

	var start_r := _grid_to_rect(m["fx"], m["fy"], origin, cell_size)
	var end_r   := _grid_to_rect(m["tx"], m["ty"], origin, cell_size)

	var p := state.get_cell(m["fx"], m["fy"])
	var p_type := MultiChessState.get_piece_type(p)
	var p_owner := MultiChessState.get_piece_player(p)
	var p_col: Color = MultiChessState.PLAYER_COLORS[p_owner] if p_owner >= 0 and p_owner < MultiChessState.PLAYER_COLORS.size() else Color.WHITE

	animating_move = {
		"fx": m["fx"], "fy": m["fy"],
		"tx": m["tx"], "ty": m["ty"],
		"type": p_type,
		"owner": p_owner,
		"rect": start_r
	}

	var is_d20_fail: bool = m.has("d20_success") and not bool(m["d20_success"])
	var is_d20_crit: bool = (int(m.get("d20_roll", 0)) == 20)
	var is_d20_fumble: bool = (int(m.get("d20_roll", 0)) == 1)
	var is_capture := (state.get_cell(m["tx"], m["ty"]) != MultiChessState.EMPTY) and not is_d20_fail

	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_QUAD)

	if is_d20_fail:
		# Наскок на защитника и отскок назад на исходную клетку
		var mid_pos := start_r.position.lerp(end_r.position, 0.55)
		tw.tween_method(func(val: float):
			if not animating_move.is_empty():
				var cur_pos := start_r.position.lerp(mid_pos, val)
				animating_move["rect"] = Rect2(cur_pos, start_r.size)
				queue_redraw()
		, 0.0, 1.0, 0.12)
		tw.tween_callback(func():
			var impact_pt := mid_pos + start_r.size * 0.5
			if is_d20_fumble:
				shake(8.0)
				emit_sparks(impact_pt, Color(1.0, 0.25, 0.25), 28, 220.0)
				add_shockwave(impact_pt, Color(1.0, 0.28, 0.28), cell_size * 1.4, 0.45)
				add_floating_text("💥 1! ПРОВАЛ!", impact_pt, Color(1.0, 0.35, 0.35), 22)
			else:
				shake(5.0)
				emit_sparks(impact_pt, Color(0.35, 0.85, 1.0), 20, 170.0)
				add_shockwave(impact_pt, Color(0.35, 0.85, 1.0), cell_size * 1.0, 0.35)
				add_floating_text("🛡 ОТБИТО!", impact_pt, Color(1.0, 0.65, 0.25), 20)
		)
		tw.tween_method(func(val: float):
			if not animating_move.is_empty():
				var cur_pos := mid_pos.lerp(start_r.position, val)
				animating_move["rect"] = Rect2(cur_pos, start_r.size)
				queue_redraw()
		, 0.0, 1.0, 0.14)
	else:
		tw.tween_method(func(val: float):
			if not animating_move.is_empty():
				var cur_pos := start_r.position.lerp(end_r.position, val)
				animating_move["rect"] = Rect2(cur_pos, start_r.size)
				# Легкий искрящийся шлейф
				if randf() > 0.45:
					emit_sparks(cur_pos + start_r.size * 0.5, p_col.lightened(0.2), 1, 20.0)
				queue_redraw()
		, 0.0, 1.0, 0.18)

		tw.tween_callback(func():
			var center_pt := end_r.position + end_r.size * 0.5

			if is_d20_crit:
				shake(14.0)
				emit_sparks(center_pt, Color(1.0, 0.88, 0.25), 45, 270.0, true)
				add_shockwave(center_pt, Color(1.0, 0.85, 0.2), cell_size * 2.4, 0.6, 2)
				add_floating_text("🔥 20! КРИТ!", center_pt, Color(1.0, 0.92, 0.3), 26)
			elif is_capture:
				shake(6.5)
				var cap_p := state.get_cell(m["tx"], m["ty"])
				var cap_owner := MultiChessState.get_piece_player(cap_p)
				var cap_col: Color = MultiChessState.PLAYER_COLORS[cap_owner] if cap_owner >= 0 and cap_owner < MultiChessState.PLAYER_COLORS.size() else Color(1.0, 0.4, 0.4)
				emit_sparks(center_pt, cap_col, 28, 190.0)
				add_shockwave(center_pt, Color(1.0, 0.35, 0.35), cell_size * 1.3, 0.42)
				if m.has("d20_success"):
					add_floating_text("⚔ УСПЕХ!", center_pt, Color(0.3, 0.98, 0.45), 20)
				else:
					add_floating_text("⚔ ВЗЯТИЕ!", center_pt, Color(1.0, 0.4, 0.4), 18)
			else:
				shake(2.0)
				add_shockwave(center_pt, p_col.lightened(0.3), cell_size * 0.7, 0.28)
		)

	tw.tween_callback(func():
		animating_move.clear()
		queue_redraw()
		if on_finished.is_valid():
			on_finished.call())
