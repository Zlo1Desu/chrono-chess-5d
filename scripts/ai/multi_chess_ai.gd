class_name MultiChessAI
extends RefCounted
## Улучшенный ИИ для 14×14 кросс-доски (3–4 игрока: FFA, 2v2 и режим с кубиком D20).
## Учитывает:
## - Защиту своего короля от ВСЕХ активных противников на доске
## - Командное взаимодействие в 2v2 (спасение короля союзника и совместные атаки)
## - Продвижение и превращение пешек в ферзя (линии 8 и 5)
## - Контроль разменов (защищённость поля прихода от всех вражеских армий)
## - Вероятность пробития защиты (DC) в режиме с кубиком D20

const LEVEL_EASY := 0
const LEVEL_NORMAL := 1
const LEVEL_HARD := 2

const EASY := 0
const NORMAL := 1
const HARD := 2

var level: int = LEVEL_NORMAL
var _rng := RandomNumberGenerator.new()


func _init(p_level: int = LEVEL_NORMAL) -> void:
	level = p_level
	_rng.randomize()


func choose_move(state: MultiChessState, is_d20: bool = false) -> Dictionary:
	return MultiChessAI.choose_move_static(state, level, is_d20)


static func choose_move_static(state: MultiChessState, p_level: int = LEVEL_NORMAL, is_d20: bool = false) -> Dictionary:
	var player := state.turn
	var moves := state.get_legal_moves(player)
	if moves.is_empty():
		return {}

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var best_move: Dictionary = moves[0]
	var best_score: float = -INF

	for m in moves:
		var s := _score_move(state, m, player, p_level, is_d20, rng)
		if s > best_score:
			best_score = s
			best_move = m

	return best_move


## Возвращает тактическую подсказку для игрока: {"move": Dictionary, "reason": String}
static func get_hint(state: MultiChessState, is_d20: bool = false) -> Dictionary:
	var player := state.turn
	var moves := state.get_legal_moves(player)
	if moves.is_empty():
		return {}

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var best_move: Dictionary = moves[0]
	var best_score: float = -INF

	for m in moves:
		var s := _score_move(state, m, player, HARD, is_d20, rng, false)
		if s > best_score:
			best_score = s
			best_move = m

	var fx: int = best_move["fx"]
	var fy: int = best_move["fy"]
	var tx: int = best_move["tx"]
	var ty: int = best_move["ty"]
	var piece := state.get_cell(fx, fy)
	var target := state.get_cell(tx, ty)
	var p_type := state.get_piece_type(piece)

	var reason := "Укрепление центра и развитие фигур"
	if state.is_king_threatened(player):
		reason = "🛡️ Спасение короля из-под удара!"
	elif target != MultiChessState.EMPTY:
		var t_type := state.get_piece_type(target)
		if t_type == MultiChessState.KING:
			reason = "👑 Сокрушительный удар по королю врага!"
		else:
			var p_names := {1: "пешки", 2: "коня", 3: "слона", 4: "ладьи", 5: "ферзя"}
			reason = "🎯 Взятие вражеской %s" % str(p_names.get(t_type, "фигуры"))
			if is_d20:
				var dc := _calc_d20_dc(p_type, t_type)
				var pct := int(round(clampf(float(21 - dc) / 20.0, 0.05, 0.95) * 100.0))
				reason += " (DC %d+, шанс %d%%)" % [dc, pct]
	elif p_type == MultiChessState.PAWN and _is_promotion_square(player, tx, ty):
		reason = "👑 Превращение пешки в ферзя!"

	return {"move": best_move, "reason": reason}


static func _score_move(
	state: MultiChessState,
	m: Dictionary,
	player: int,
	level: int,
	is_d20: bool,
	rng: RandomNumberGenerator,
	add_noise: bool = true
) -> float:
	var fx: int = m["fx"]
	var fy: int = m["fy"]
	var tx: int = m["tx"]
	var ty: int = m["ty"]

	var piece := state.get_cell(fx, fy)
	var p_type := state.get_piece_type(piece)
	var my_val: float = float(MultiChessState.PIECE_COMBAT_VALUES.get(p_type, 1))

	var target := state.get_cell(tx, ty)
	var score: float = 0.0

	# 1. Оценка взятия (с учётом вероятности пробития D20, если включён режим D20)
	if target != MultiChessState.EMPTY:
		var t_type := state.get_piece_type(target)
		var victim_val: float = float(MultiChessState.PIECE_COMBAT_VALUES.get(t_type, 1))
		if t_type == MultiChessState.KING:
			victim_val = 250.0 # Выбивание игрока из партии!
		if is_d20:
			var dc := _calc_d20_dc(p_type, t_type)
			var win_prob := clampf(float(21 - dc) / 20.0, 0.05, 0.95)
			score += victim_val * 12.0 * win_prob - (1.0 - win_prob) * 1.5
		else:
			score += victim_val * 12.0 - my_val * 0.25

	# 2. Продвижение и превращение пешек в ферзя
	if p_type == MultiChessState.PAWN:
		if _is_promotion_square(player, tx, ty):
			score += 75.0
		else:
			var progress := _pawn_progress(player, tx, ty)
			score += progress * 0.65

	# 3. Позиционный контроль центра 14×14 (квадрат 4..9 × 4..9)
	if p_type != MultiChessState.KING:
		var dist_center := absf(float(tx) - 6.5) + absf(float(ty) - 6.5)
		score += (12.0 - dist_center) * 0.28
		# Развитие коней и слонов со стартовой линии
		if (p_type == MultiChessState.KNIGHT or p_type == MultiChessState.BISHOP) and _is_back_rank(player, fx, fy):
			score += 1.15
	else:
		# Королю опасно выходить в центр перекрёстка в начале и середине игры
		var dist_center_k := absf(float(tx) - 6.5) + absf(float(ty) - 6.5)
		score -= (11.0 - dist_center_k) * 0.45

	# 4. Симуляция хода: проверка безопасности своего короля, короля союзника (в 2v2) и поля прихода
	var sim := state.clone()
	sim.apply_move(m, false)

	# Если наш король остаётся под боем любого из противников — огромный штраф на всех уровнях!
	if sim.is_king_threatened(player):
		score -= 15000.0 if level >= NORMAL else 6000.0

	# В режиме 2v2 проверяем безопасность короля напарника
	if state.mode == MultiChessState.MODE_2V2 and level >= NORMAL:
		for ally in sim.active_players:
			if ally != player and sim.are_teammates(player, ally) and not sim.eliminated_players.has(ally):
				if state.is_king_threatened(ally) and not sim.is_king_threatened(ally):
					score += 45.0 # Спасли короля союзника!
				elif sim.is_king_threatened(ally):
					score -= 12.0

	# 5. На среднем и сложном уровнях проверяем, не подставляется ли походившая фигура под бой вражеских армий
	if level >= NORMAL:
		var attacked_by_min_val: float = INF
		var gives_check_bonus: float = 0.0
		for opp in sim.active_players:
			if opp == player or sim.are_teammates(player, opp) or sim.eliminated_players.has(opp):
				continue
			# На сложном уровне также ценим объявление шаха вражескому королю
			if level == HARD and sim.is_king_threatened(opp):
				gives_check_bonus += 5.5
			var opp_moves := sim.get_legal_moves(opp)
			for om in opp_moves:
				if int(om["tx"]) == tx and int(om["ty"]) == ty:
					var attacker_p := sim.get_cell(int(om["fx"]), int(om["fy"]))
					var att_type := sim.get_piece_type(attacker_p)
					var att_val := float(MultiChessState.PIECE_COMBAT_VALUES.get(att_type, 1))
					if att_val < attacked_by_min_val:
						attacked_by_min_val = att_val

		score += gives_check_bonus
		if attacked_by_min_val < INF:
			var moved_piece_now := sim.get_cell(tx, ty)
			var now_type := sim.get_piece_type(moved_piece_now)
			var now_val := float(MultiChessState.PIECE_COMBAT_VALUES.get(now_type, int(my_val)))
			var risk_weight := 8.5 if level == NORMAL else 11.5
			if is_d20:
				risk_weight *= 0.65
			score -= now_val * risk_weight

	# 6. Добавляем контролируемый шум в зависимости от сложности
	if add_noise:
		match level:
			EASY:
				score += rng.randf_range(0.0, 9.0)
			NORMAL:
				score += rng.randf_range(0.0, 1.5)
			HARD:
				score += rng.randf_range(0.0, 0.15)

	return score


static func _calc_d20_dc(att_type: int, def_type: int) -> int:
	return MultiChessState.get_d20_threshold(att_type, def_type)


static func _is_promotion_square(player: int, x: int, y: int) -> bool:
	match player:
		MultiChessState.WHITE: return y >= 8
		MultiChessState.RED:   return x >= 8
		MultiChessState.BLACK: return y <= 5
		MultiChessState.BLUE:  return x <= 5
	return false


static func _pawn_progress(player: int, x: int, y: int) -> float:
	match player:
		MultiChessState.WHITE: return float(y - 1)
		MultiChessState.RED:   return float(x - 1)
		MultiChessState.BLACK: return float(12 - y)
		MultiChessState.BLUE:  return float(12 - x)
	return 0.0


static func _is_back_rank(player: int, x: int, y: int) -> bool:
	match player:
		MultiChessState.WHITE: return y == 0
		MultiChessState.RED:   return x == 0
		MultiChessState.BLACK: return y == 13
		MultiChessState.BLUE:  return x == 13
	return false
