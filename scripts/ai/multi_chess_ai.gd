class_name MultiChessAI
extends RefCounted
## Искусственный интеллект для мульти-шахмат (1х1х1, 2х2, 1х1х1х1).
## Оценивает материал, угрозы королям, захват центра и командное взаимодействие.

const LEVEL_EASY := 1
const LEVEL_NORMAL := 2
const LEVEL_HARD := 3

const PIECE_VALUES := [0, 100, 320, 330, 500, 950, 20000]

var level: int = LEVEL_NORMAL
var rng := RandomNumberGenerator.new()


func _init(p_level: int = LEVEL_NORMAL) -> void:
	level = p_level
	rng.randomize()


func choose_move(state: MultiChessState) -> Dictionary:
	var legal := state.get_legal_moves()
	if legal.is_empty():
		return {}

	var player := state.turn

	# Для легкого уровня иногда делаем случайный ход
	if level == LEVEL_EASY and rng.randf() < 0.35:
		return legal[rng.randi() % legal.size()]

	var best_moves: Array = []
	var best_score: float = -999999.0

	# Перемешиваем ходы для разнообразия партий
	legal.shuffle()

	for m in legal:
		var sim := state.clone()
		var target := sim.get_cell(m["tx"], m["ty"])
		var target_type := MultiChessState.get_piece_type(target)

		# Мгновенная победа/взятие короля
		if target_type == MultiChessState.KING:
			return m

		sim.apply_move(m)

		var score: float = 0.0

		if level == LEVEL_EASY:
			score = _evaluate_state(sim, player) + rng.randf_range(-40.0, 40.0)
		elif level == LEVEL_NORMAL:
			score = _evaluate_state(sim, player)
			# Дополнительный бонус за взятия фигур
			if target != MultiChessState.EMPTY:
				score += PIECE_VALUES[target_type] * 1.2
			score += rng.randf_range(-15.0, 15.0)
		else:
			# LEVEL_HARD: глубина 2 (анализируем ответные угрозы)
			var base_eval: float = _evaluate_state(sim, player)
			var worst_reply: float = 0.0
			var next_moves := sim.get_legal_moves()
			for nm in next_moves:
				var n_target := sim.get_cell(nm["tx"], nm["ty"])
				if n_target != MultiChessState.EMPTY and sim.are_teammates(player, MultiChessState.get_piece_player(n_target)):
					var n_type := MultiChessState.get_piece_type(n_target)
					if n_type == MultiChessState.KING:
						worst_reply = maxf(worst_reply, 30000.0)
					else:
						worst_reply = maxf(worst_reply, PIECE_VALUES[n_type])
			score = base_eval - worst_reply * 1.1 + rng.randf_range(-5.0, 5.0)

		if score > best_score:
			best_score = score
			best_moves = [m]
		elif is_equal_approx(score, best_score):
			best_moves.append(m)

	if best_moves.is_empty():
		return legal[0]
	return best_moves[rng.randi() % best_moves.size()]


func _evaluate_state(state: MultiChessState, player: int) -> float:
	var my_score: float = 0.0
	var enemy_score: float = 0.0

	for y in MultiChessState.BOARD_SIZE:
		for x in MultiChessState.BOARD_SIZE:
			if not MultiChessState.is_valid_cell(x, y):
				continue
			var p := state.get_cell(x, y)
			if p == MultiChessState.EMPTY:
				continue
			var p_type := MultiChessState.get_piece_type(p)
			var p_owner := MultiChessState.get_piece_player(p)
			var val: float = PIECE_VALUES[p_type]

			# Бонус за близость к центру (6..7)
			var dist_center: float = absf(x - 6.5) + absf(y - 6.5)
			val += maxf(0.0, (14.0 - dist_center) * 3.0)

			if state.are_teammates(player, p_owner):
				my_score += val
			else:
				enemy_score += val

	var total := my_score - (enemy_score / float(max(1, state.active_players.size() - 1)))
	return total
