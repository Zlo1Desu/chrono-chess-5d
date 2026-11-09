class_name ChessAI
extends RefCounted
## Простой ИИ: жадно выбирает ход на каждой обязательной доске, оценивая
## материал на концах всех линий и угрозы соперника. Если итоговый ход
## оказывается нелегальным, использует перебор GameState.find_legal_turn().

const EASY := 0
const NORMAL := 1
const HARD := 2

var level: int = NORMAL
var rng := RandomNumberGenerator.new()


func _init(lvl: int = NORMAL) -> void:
	level = lvl
	rng.randomize()


## Возвращает массив ходов (Dictionary) для текущего игрока в `state`.
func choose_turn(state: GameState) -> Array:
	var g: GameState = state.clone()
	g.turn_moves = []
	var me: int = g.turn
	var guard: int = 0
	while posmod(g.present(), 2) == me and guard < 32:
		guard += 1
		var mand: Array = g.mandatory_timelines()
		if mand.is_empty():
			break
		var best: Variant = _best_move(g, g.board_moves(mand[0]), me)
		if best == null:
			break
		g.apply_move(best)
	if level == HARD and g.is_king_capturable(1 - me):
		# Попробовать закрыться ходом на необязательной доске.
		var extra: Array = []
		for l in g.playable_timelines():
			extra.append_array(g.board_moves(l))
		var fix: Variant = _best_move(g, extra, me)
		if fix != null:
			g.apply_move(fix)
	if g.submit_error() == "":
		return g.turn_moves.duplicate()
	var legal: Variant = state.find_legal_turn(6000)
	if legal is Array:
		return legal
	return []


func _best_move(g: GameState, moves: Array, me: int) -> Variant:
	if moves.is_empty():
		return null
	var best: Variant = null
	var best_score: float = -INF
	for m in moves:
		g.apply_move(m)
		var s: float = _evaluate(g, me)
		g.undo_move()
		match level:
			EASY:
				s += rng.randf_range(0.0, 4.0)
			NORMAL:
				s += rng.randf_range(0.0, 0.6)
			_:
				s += rng.randf_range(0.0, 0.1)
		if s > best_score:
			best_score = s
			best = m
	return best


func _evaluate(g: GameState, me: int) -> float:
	var opp: int = 1 - me
	var score: float = 0.0
	for l in g.timelines:
		var weight: float = 1.0 if g.is_active(l) else 0.5
		var b: PackedByteArray = g.end_board(l)
		for i in b.size():
			var p: int = b[i]
			if p == GameState.EMPTY:
				continue
			var t: int = p & GameState.TYPE_MASK
			var v: float = GameState.VALUES[t]
			var x: int = i % g.w
			var y: int = i / g.w
			if t == GameState.PAWN:
				# Бонус за продвижение пешки
				var adv: int = y if (p & GameState.BLACK_BIT) == 0 else g.h - 1 - y
				v += 0.05 * adv
			elif t != GameState.KING:
				# Бонус за централизацию фигуры
				var cx: float = absf(x - (g.w - 1) / 2.0)
				var cy: float = absf(y - (g.h - 1) / 2.0)
				v += 0.06 * (3.0 - minf(3.0, (cx + cy) / 2.0))
			if GameState.piece_color(p) == me:
				score += v * weight
			else:
				score -= v * weight
	if g.is_king_capturable(opp):
		return score - 10000.0
	match level:
		NORMAL:
			score -= minf(g.best_capture_value(opp), 9.0) * 0.4
		HARD:
			score -= minf(g.best_capture_value(opp), 9.0) * 0.7
			score += minf(g.best_capture_value(me), 9.0) * 0.15
	# Не плодить линии без нужды: каждая своя линия — небольшой штраф.
	var own_lines: int = g.max_l if me == GameState.WHITE else -g.min_l
	score -= own_lines * 0.15
	return score
