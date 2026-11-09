class_name PieceButton
extends Button
## Кнопка с векторной отрисовкой шахматной фигуры (для окна превращения пешки, аватаров и магазина).

var override_skin: String = "":
	set(v):
		override_skin = v
		queue_redraw()

var piece: int = GameState.QUEEN:
	set(v):
		piece = v
		queue_redraw()

var is_selected_slot: bool = false:
	set(v):
		is_selected_slot = v
		_apply_style()
		queue_redraw()


func _init() -> void:
	focus_mode = Control.FOCUS_NONE
	action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_style()


func _apply_style() -> void:
	var sb := StyleBoxFlat.new()
	if is_selected_slot:
		sb.bg_color = Color(0.14, 0.24, 0.44, 0.95)
		sb.border_color = Color(0.38, 0.68, 0.98, 0.95)
		sb.set_border_width_all(2)
	else:
		sb.bg_color = Color(0.08, 0.11, 0.18, 0.85)
		sb.border_color = Color(0.18, 0.24, 0.36, 0.80)
		sb.set_border_width_all(1)
	sb.set_corner_radius_all(10)
	add_theme_stylebox_override("normal", sb)

	var hover := sb.duplicate()
	hover.bg_color = Color(0.13, 0.19, 0.32, 0.95)
	hover.border_color = Color(0.35, 0.60, 0.92, 0.90)
	add_theme_stylebox_override("hover", hover)

	var pressed_sb := sb.duplicate()
	pressed_sb.bg_color = Color(0.18, 0.30, 0.52, 0.98)
	add_theme_stylebox_override("pressed", pressed_sb)


func _draw() -> void:
	var s: float = minf(size.x, size.y) * 0.80
	var r := Rect2((size - Vector2(s, s)) * 0.5, Vector2(s, s))
	PieceArt.draw_piece(self, piece, r, 1.0, override_skin)
