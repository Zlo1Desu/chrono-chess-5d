class_name TimelineMinimap
extends Control
## Интерактивная миникарта мультивселенной 5D-шахмат.
## Отображает компактную сетку всех активных и прошлых досок,
## текущий фокус камеры, световой барьер Настоящего и обязательные доски.
## Позволяет кликом/тапом мгновенно переключать камеру на любую доску.

signal board_selected(l: int, t: int)

const BG_COLOR := Color(0.05, 0.07, 0.12, 0.88)
const BORDER_COLOR := Color(0.22, 0.35, 0.55, 0.75)
const PRESENT_COLOR := Color(0.35, 0.85, 1.0, 0.85)

var view: MultiverseView
var is_dragging: bool = false


func _ready() -> void:
	custom_minimum_size = Vector2(130, 80)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _gui_input(event: InputEvent) -> void:
	if view == null or view.state == null:
		return
	if event is InputEventMouseButton:
		var e: InputEventMouseButton = event
		if e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				is_dragging = true
				_navigate_to_click(e.position)
			else:
				is_dragging = false
			accept_event()
	elif event is InputEventMouseMotion and is_dragging:
		var e: InputEventMouseMotion = event
		_navigate_to_click(e.position)
		accept_event()
	elif event is InputEventScreenTouch:
		var e: InputEventScreenTouch = event
		if e.pressed:
			is_dragging = true
			_navigate_to_click(e.position)
		else:
			is_dragging = false
		accept_event()
	elif event is InputEventScreenDrag and is_dragging:
		var e: InputEventScreenDrag = event
		_navigate_to_click(e.position)
		accept_event()


func _navigate_to_click(pos: Vector2) -> void:
	var target_board := _find_board_at_minimap(pos)
	if target_board.x != -999:
		board_selected.emit(int(target_board.x), int(target_board.y))


func _find_board_at_minimap(pos: Vector2) -> Vector2i:
	if view == null or view.state == null:
		return Vector2i(-999, -999)
	var state: GameState = view.state
	if state.timelines.is_empty():
		return Vector2i(-999, -999)

	var min_t_val: int = view.min_t()
	var max_t_val: int = min_t_val
	var min_l_val: int = 0
	var max_l_val: int = 0

	for l in state.timelines:
		min_l_val = mini(min_l_val, l)
		max_l_val = maxi(max_l_val, l)
		max_t_val = maxi(max_t_val, state.end_t(l))

	var t_span: int = maxi(1, max_t_val - min_t_val + 1)
	var l_span: int = maxi(1, max_l_val - min_l_val + 1)

	var pad := 6.0
	var draw_w := size.x - pad * 2.0
	var draw_h := size.y - pad * 2.0

	var cell_w := draw_w / float(t_span)
	var cell_h := draw_h / float(l_span)

	var best_board := Vector2i(-999, -999)
	var best_dist := INF

	for l in state.timelines:
		var s: int = state.start_t(l)
		var e: int = state.end_t(l)
		var row: int = max_l_val - l if not view.flip else l - min_l_val
		for t in range(s, e + 1):
			var col: int = t - min_t_val
			var bx := pad + col * cell_w + cell_w * 0.5
			var by := pad + row * cell_h + cell_h * 0.5
			var dist := pos.distance_to(Vector2(bx, by))
			if dist < best_dist:
				best_dist = dist
				best_board = Vector2i(l, t)

	return best_board


func _draw() -> void:
	# Фоновая плашка
	var panel_r := Rect2(Vector2.ZERO, size)
	draw_rect(panel_r, BG_COLOR)
	draw_rect(panel_r, BORDER_COLOR, false, 1.5)

	if view == null or view.state == null:
		return
	var state: GameState = view.state
	if state.timelines.is_empty():
		return

	var min_t_val: int = view.min_t()
	var max_t_val: int = min_t_val
	var min_l_val: int = 0
	var max_l_val: int = 0

	for l in state.timelines:
		min_l_val = mini(min_l_val, l)
		max_l_val = maxi(max_l_val, l)
		max_t_val = maxi(max_t_val, state.end_t(l))

	var t_span: int = maxi(1, max_t_val - min_t_val + 1)
	var l_span: int = maxi(1, max_l_val - min_l_val + 1)

	var pad := 6.0
	var draw_w := size.x - pad * 2.0
	var draw_h := size.y - pad * 2.0

	var cell_w := draw_w / float(t_span)
	var cell_h := draw_h / float(l_span)

	var board_dot_w := clampf(cell_w * 0.72, 3.0, 16.0)
	var board_dot_h := clampf(cell_h * 0.72, 3.0, 16.0)

	var mand_lines: Array = state.mandatory_timelines()

	# Отрисовка линий времени
	for l in state.timelines:
		var s: int = state.start_t(l)
		var e: int = state.end_t(l)
		var row: int = max_l_val - l if not view.flip else l - min_l_val
		var y_coord: float = pad + row * cell_h + cell_h * 0.5

		var x_start: float = pad + (s - min_t_val) * cell_w + cell_w * 0.5
		var x_end: float = pad + (e - min_t_val) * cell_w + cell_w * 0.5
		var is_active: bool = state.is_active(l)
		var line_col := Color(0.3, 0.6, 0.9, 0.45) if is_active else Color(0.3, 0.3, 0.4, 0.25)
		draw_line(Vector2(x_start, y_coord), Vector2(x_end, y_coord), line_col, 1.5)

		# Доски
		for t in range(s, e + 1):
			var col: int = t - min_t_val
			var x_coord: float = pad + col * cell_w + cell_w * 0.5
			var dot_r := Rect2(Vector2(x_coord - board_dot_w * 0.5, y_coord - board_dot_h * 0.5), Vector2(board_dot_w, board_dot_h))

			var is_mand: bool = (t == e) and mand_lines.has(l)
			var b_color: Color
			if is_mand:
				b_color = Color(1.0, 0.8, 0.2, 0.95)
			elif is_active:
				b_color = Color(0.7, 0.85, 1.0, 0.85) if posmod(t, 2) == 0 else Color(0.25, 0.32, 0.48, 0.9)
			else:
				b_color = Color(0.2, 0.22, 0.28, 0.5)

			draw_rect(dot_r, b_color)

	# Линия Настоящего (Present)
	var pt: int = state.present()
	var present_col: int = pt - min_t_val
	var px: float = pad + present_col * cell_w + cell_w * 0.5
	draw_line(Vector2(px, pad), Vector2(px, size.y - pad), PRESENT_COLOR, 1.5)

	# Вьюпорт текущей камеры (видимая область)
	var cam_min_world := view.screen_to_world(Vector2.ZERO)
	var cam_max_world := view.screen_to_world(view.size)

	var bs: Vector2 = view.board_size()
	var gap: float = view.gap()
	var cw: float = bs.x + gap
	var ch: float = bs.y + gap

	var v_t_min: float = cam_min_world.x / cw + float(min_t_val)
	var v_t_max: float = cam_max_world.x / cw + float(min_t_val)
	var v_l_min: float = (cam_min_world.y / ch) if not view.flip else -(cam_max_world.y / ch)
	var v_l_max: float = (cam_max_world.y / ch) if not view.flip else -(cam_min_world.y / ch)

	var vx1: float = clampf(pad + (v_t_min - min_t_val) * cell_w, pad, size.x - pad)
	var vx2: float = clampf(pad + (v_t_max - min_t_val) * cell_w, pad, size.x - pad)
	var vy1: float = clampf(pad + (max_l_val - v_l_max) * cell_h, pad, size.y - pad)
	var vy2: float = clampf(pad + (max_l_val - v_l_min) * cell_h, pad, size.y - pad)

	var cam_rect := Rect2(Vector2(vx1, vy1), Vector2(maxf(6.0, vx2 - vx1), maxf(6.0, vy2 - vy1)))
	draw_rect(cam_rect, Color(0.3, 0.85, 1.0, 0.18))
	draw_rect(cam_rect, Color(0.4, 0.9, 1.0, 0.75), false, 1.0)
