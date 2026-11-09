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


func _init() -> void:
	focus_mode = Control.FOCUS_NONE
	action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	mouse_filter = Control.MOUSE_FILTER_STOP


func _draw() -> void:
	var s: float = minf(size.x, size.y) * 0.78
	var r := Rect2((size - Vector2(s, s)) * 0.5, Vector2(s, s))
	PieceArt.draw_piece(self, piece, r, 1.0, override_skin)
