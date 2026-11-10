class_name ChronoWheel
extends Control
## Радиальное быстрое меню «Колесо времени» (Chrono-Wheel).
## Всплывает при выборе фигуры с возможностью темпорального прыжка или перемещения.
## Позволяет выбрать целевую линию (L0, L+1, L-1...) или прыжок в прошлое (T),
## мгновенно фокусирует камеру на целевой доске и подсвечивает точные клетки приземления.

signal target_selected(target_square: Vector4i)
signal board_preview_requested(l: int, t: int)
signal closed

const WHEEL_RADIUS := 95.0
const INNER_RADIUS := 36.0
const SECTOR_PAD := 0.05

var view: MultiverseView
var center_screen_pos: Vector2 = Vector2.ZERO
var origin_square: Vector4i = Vector4i(-1, -1, 0, 0)
var available_destinations: Array = [] # Array[Vector4i]
var grouped_boards: Array = [] # [{"l": int, "t": int, "targets": Array[Vector4i], "label": String, "color": Color}]

var _hovered_idx: int = -1
var _open_anim: float = 0.0
var _anim_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func setup_for_piece(p_view: MultiverseView, p_origin: Vector4i, p_targets: Array) -> void:
	view = p_view
	origin_square = p_origin
	available_destinations = p_targets
	_hovered_idx = -1

	# Переводим позицию клетки на экране в глобальные координаты
	var origin_world_center: Vector2 = view.square_rect(origin_square).get_center()
	center_screen_pos = origin_world_center * view.zoom + view.offset

	# Группируем ходы по целевым доскам (l, t)
	var board_map: Dictionary = {}
	for tv in available_destinations:
		var key := "%d,%d" % [tv.w, tv.z]
		if not board_map.has(key):
			board_map[key] = {
				"l": tv.w,
				"t": tv.z,
				"targets": [],
				"is_temporal": (tv.w != origin_square.w or tv.z != origin_square.z)
			}
		board_map[key]["targets"].append(tv)

	grouped_boards.clear()
	for key in board_map:
		var item: Dictionary = board_map[key]
		var l: int = int(item["l"])
		var t: int = int(item["t"])
		var is_temp: bool = bool(item["is_temporal"])

		var l_name: String = ("L%+d" % l) if l != 0 else "L0"
		var t_step: int = floori(t / 2.0) + 1
		var t_name: String = "T%d%s" % [t_step, "" if posmod(t, 2) == 0 else "b"]
		var label: String = "Тут" if not is_temp else ("%s·%s" % [l_name, t_name])

		var col := Color(0.25, 0.75, 1.0)
		if is_temp:
			if l != origin_square.w:
				col = Color(0.92, 0.45, 1.0) # Ветвление параллельной линии
			else:
				col = Color(1.0, 0.8, 0.28) # Прыжок в прошлое текущей линии

		item["label"] = label
		item["color"] = col
		grouped_boards.append(item)

	# Сортируем: сначала текущая доска, затем по удалению во времени
	grouped_boards.sort_custom(func(a, b):
		if not bool(a["is_temporal"]):
			return true
		if not bool(b["is_temporal"]):
			return false
		return int(a["t"]) > int(b["t"])
	)

	_open_anim = 0.0
	if _anim_tween:
		_anim_tween.kill()
	_anim_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_anim_tween.tween_property(self, "_open_anim", 1.0, 0.24).from(0.0)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var e: InputEventMouseButton = event
		if e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_handle_selection_at(e.position)
			accept_event()
		elif e.pressed and e.button_index == MOUSE_BUTTON_RIGHT:
			close()
			accept_event()
	elif event is InputEventMouseMotion:
		var e: InputEventMouseMotion = event
		_update_hover(e.position)
		accept_event()
	elif event is InputEventScreenTouch:
		var e: InputEventScreenTouch = event
		if e.pressed:
			_handle_selection_at(e.position)
		accept_event()
	elif event is InputEventScreenDrag:
		var e: InputEventScreenDrag = event
		_update_hover(e.position)
		accept_event()


func _update_hover(pos: Vector2) -> void:
	var old_hover := _hovered_idx
	var idx := _get_sector_at(pos)
	if idx != _hovered_idx:
		_hovered_idx = idx
		queue_redraw()
		if _hovered_idx >= 0 and _hovered_idx < grouped_boards.size():
			var item: Dictionary = grouped_boards[_hovered_idx]
			board_preview_requested.emit(int(item["l"]), int(item["t"]))


func _handle_selection_at(pos: Vector2) -> void:
	var idx := _get_sector_at(pos)
	if idx >= 0 and idx < grouped_boards.size():
		var item: Dictionary = grouped_boards[idx]
		var tgts: Array = item["targets"]
		if tgts.size() == 1:
			target_selected.emit(tgts[0])
			close()
		else:
			# На доске несколько ходов: центрируем камеру и закрываем радиальное меню,
			# оставляя подсвеченными только клетки этой доски
			board_preview_requested.emit(int(item["l"]), int(item["t"]))
			close()
	else:
		# Клик вне колеса — закрыть
		close()


func _get_sector_at(pos: Vector2) -> int:
	var delta := pos - center_screen_pos
	var dist := delta.length()
	if dist < INNER_RADIUS * _open_anim or dist > (WHEEL_RADIUS + 28.0) * _open_anim:
		return -1

	var count := grouped_boards.size()
	if count == 0:
		return -1

	var angle := posmod(delta.angle(), TAU) # 0..TAU
	var arc_step := TAU / float(count)
	var idx := int(floor(angle / arc_step)) % count
	return idx


func close() -> void:
	closed.emit()
	queue_free()


func _draw() -> void:
	if grouped_boards.is_empty():
		return

	var count := grouped_boards.size()
	var arc_step := TAU / float(count)
	var r_outer := WHEEL_RADIUS * _open_anim
	var r_inner := INNER_RADIUS * _open_anim

	# Центральное ядро
	draw_circle(center_screen_pos, r_inner, Color(0.06, 0.08, 0.15, 0.94 * _open_anim))
	draw_arc(center_screen_pos, r_inner, 0.0, TAU, 32, Color(0.35, 0.65, 0.95, 0.8 * _open_anim), 2.0)

	# Иконка центрального хроно-ядра
	var font := ThemeDB.fallback_font
	var icon_txt := "⏳"
	draw_string(font, center_screen_pos + Vector2(-9.0, 6.0), icon_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color(1, 1, 1, 0.9 * _open_anim))

	# Сектора колеса
	for i in range(count):
		var item: Dictionary = grouped_boards[i]
		var is_hovered := (i == _hovered_idx)
		var base_col: Color = item["color"]
		var fill_col := Color(base_col.r, base_col.g, base_col.b, 0.38 if not is_hovered else 0.72)
		var border_col := Color(base_col.r, base_col.g, base_col.b, 0.85 if not is_hovered else 1.0)

		var cur_outer := (r_outer + 8.0) if is_hovered else r_outer
		var a_start := i * arc_step + SECTOR_PAD
		var a_end := (i + 1) * arc_step - SECTOR_PAD

		# Отрисовка секторного полигона
		var pts := PackedVector2Array()
		var segs := 10
		for s in range(segs + 1):
			var a := lerpf(a_start, a_end, float(s) / float(segs))
			pts.append(center_screen_pos + Vector2(cos(a), sin(a)) * cur_outer)
		for s in range(segs, -1, -1):
			var a := lerpf(a_start, a_end, float(s) / float(segs))
			pts.append(center_screen_pos + Vector2(cos(a), sin(a)) * r_inner)

		draw_colored_polygon(pts, fill_col)
		draw_polyline(pts, border_col, 2.0, true)

		# Текстовая метка сектора
		var mid_a := (a_start + a_end) * 0.5
		var label_r := (r_inner + cur_outer) * 0.5
		var label_pos := center_screen_pos + Vector2(cos(mid_a), sin(mid_a)) * label_r
		var label_txt: String = str(item["label"])

		var font_sz := 12 if is_hovered else 11
		var txt_w := font.get_string_size(label_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, font_sz).x
		draw_string(font, label_pos + Vector2(-txt_w * 0.5, 4.0), label_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, font_sz, Color(1, 1, 1, 0.95))
