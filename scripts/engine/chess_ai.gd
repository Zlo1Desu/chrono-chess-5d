class_name ChessAI
extends RefCounted
## Высокопроизводительный тактический ИИ для 5D-шахмат:
## - Быстрая оценка без лишнего клонирования (in-place проверка шахов и угроз)
## - Двухступенчатая фильтрация кандидатов (_evaluate_fast -> _evaluate)
## - Жёсткий контроль времени поиска (Time budget), исключающий фризы даже при 10+ таймлайнах
## - Лучевой поиск (Beam Search) + 2-ply просчёт на Сложном уровне + система подсказок (get_hint)

const EASY := 0
const NORMAL := 1
const HARD := 2

const MAX_SEARCH_MS := 75

var level: int = NORMAL
var rng := RandomNumberGenerator.new()


func _init(lvl: int = NORMAL) -> void:
	level = lvl
	rng.randomize()


## Возвращает массив ходов (Dictionary) для текущего игрока в `state`.
func choose_turn(state: GameState) -> Array:
	var start_ms: int = Time.get_ticks_msec()
	var me: int = state.turn

	# 1. Лучевой поиск лучших комбинаций ходов по обязательным доскам
	var beam_width: int = 2 if level == EASY else (4 if level == NORMAL else 6)
	var candidates: Array = _beam_search_turns(state, me, beam_width, start_ms)

	var legal_turns: Array = []
	for cand in candidates:
		var g_cand: GameState = cand["state"]
		if g_cand.submit_error() == "":
			legal_turns.append(cand)

	# 2. Если жадные комбинации оставляют короля под шахом — ищем легальные ходы с контролем времени
	if legal_turns.is_empty():
		var fb_start: int = Time.get_ticks_msec()
		legal_turns = _find_scored_legal_turns(state, me, 4 if level == HARD else 2, fb_start)

	if legal_turns.is_empty():
		return []

	# 3. Уточняем тактическую оценку (проверка подстав фигур) только для топ-кандидатов
	var top_eval_cnt: int = mini(legal_turns.size(), 4 if level == HARD else 3)
	for i in range(top_eval_cnt):
		if Time.get_ticks_msec() - start_ms > MAX_SEARCH_MS:
			break
		var item: Dictionary = legal_turns[i]
		item["score"] = _evaluate(item["state"], me) + _noise()
	legal_turns.sort_custom(func(a, b): return float(a["score"]) > float(b["score"]))

	# 4. На уровне HARD проверяем на мат в 1 ход и делаем быстрый 2-ply просчёт ответа соперника
	if level == HARD and legal_turns.size() > 1 and (Time.get_ticks_msec() - start_ms) < MAX_SEARCH_MS:
		var best_turn: Array = legal_turns[0]["moves"]
		var best_val: float = -INF
		var top_k: int = mini(legal_turns.size(), 3)
		for i in range(top_k):
			if Time.get_ticks_msec() - start_ms > MAX_SEARCH_MS:
				break
			var item: Dictionary = legal_turns[i]
			var g_after: GameState = item["state"].pass_clone()
			var val: float = float(item["score"])
			# Проверяем, не поставили ли мы мат!
			if g_after.in_check() and g_after.find_legal_turn(180) == null:
				return item["moves"]
			# Оцениваем лучший ответ соперника на первой обязательной доске
			var opp_mand: Array = g_after.mandatory_timelines()
			if not opp_mand.is_empty():
				var opp_moves: Array = g_after.board_moves(opp_mand[0])
				var worst_reply: float = INF
				var checked_replies: int = 0
				opp_moves.sort_custom(func(a, b): return _quick_move_priority(g_after, a) > _quick_move_priority(g_after, b))
				for om in opp_moves:
					if checked_replies >= 5 or (Time.get_ticks_msec() - start_ms) > MAX_SEARCH_MS:
						break
					g_after.apply_move(om)
					if not g_after.in_check():
						var reply_eval: float = _evaluate_fast(g_after, me)
						if reply_eval < worst_reply:
							worst_reply = reply_eval
						checked_replies += 1
					g_after.undo_move()
				if worst_reply < INF:
					val = val * 0.45 + worst_reply * 0.55
			if val > best_val:
				best_val = val
				best_turn = item["moves"]
		return best_turn

	return legal_turns[0]["moves"]


## Возвращает лучшую одиночную подсказку для текущего состояния игрока: {"move": Dictionary, "reason": String}
static func get_hint(state: GameState) -> Dictionary:
	var ai := ChessAI.new(HARD)
	var me: int = state.turn
	var opp: int = 1 - me
	var g: GameState = state.clone()

	var play_lines: Array = g.mandatory_timelines()
	if play_lines.is_empty():
		play_lines = g.playable_timelines()

	var all_moves: Array = []
	for l in play_lines:
		all_moves.append_array(g.board_moves(l))

	if all_moves.is_empty():
		for l in g.playable_timelines():
			all_moves.append_array(g.board_moves(l))

	if all_moves.is_empty():
		return {}

	all_moves.sort_custom(func(a, b): return ai._quick_move_priority(g, a) > ai._quick_move_priority(g, b))
	var max_candidates: int = mini(all_moves.size(), 24)

	var best_m: Dictionary = {}
	var best_score: float = -INF
	var best_reason: String = "Развитие и укрепление позиции"
	var start_ms: int = Time.get_ticks_msec()

	for idx in range(max_candidates):
		if idx > 4 and Time.get_ticks_msec() - start_ms > 65:
			break
		var m: Dictionary = all_moves[idx]
		g.apply_move(m)
		var king_exposed: bool = g.in_check()
		var s: float = ai._evaluate_fast(g, me)
		var reason: String = "Активный позиционный манёвр"

		if king_exposed:
			s -= 25000.0
			reason = "Защита короля"
		else:
			var gives_check: bool = g.is_king_capturable(me)
			if gives_check:
				var after_opp: GameState = g.pass_clone()
				if after_opp.find_legal_turn(180) == null:
					s += 100000.0
					reason = "⚡ Шах и мат в 1 ход!"
				else:
					s += 4.5
					reason = "⚔️ Объявление шаха королю соперника"

		var f: Vector4i = m["f"]
		var t: Vector4i = m["t"]
		var target_p: int = state.get_board(t.w, t.z)[t.y * state.w + t.x]
		if reason == "Активный позиционный манёвр":
			if target_p != GameState.EMPTY and GameState.piece_color(target_p) == opp:
				var cap_name: String = str(GameState.NAMES_RU.get(target_p & GameState.TYPE_MASK, "фигуры"))
				reason = "🎯 Выгодное взятие (%s)" % cap_name
			elif f.w != t.w or f.z != t.z:
				reason = "🌀 Темпоральный прыжок в другую линию/прошлое"
			elif int(m.get("promo", 0)) != 0:
				reason = "👑 Превращение пешки в ферзя"
			elif state.in_check():
				reason = "🛡️ Выход из-под шаха"

		g.undo_move()

		if s > best_score:
			best_score = s
			best_m = m
			best_reason = reason

	if best_m.is_empty():
		return {}
	return {"move": best_m, "reason": best_reason}


func _beam_search_turns(state: GameState, me: int, beam_width: int, start_ms: int) -> Array:
	var initial := state.clone()
	initial.turn_moves = []
	var max_allowed_tl: int = state.timelines.size() + 1
	var beam: Array = [{"state": initial, "moves": [], "score": _evaluate_fast(initial, me)}]

	var step: int = 0
	var max_steps: int = maxi(2, state.mandatory_timelines().size() + 1)
	while step < max_steps:
		if Time.get_ticks_msec() - start_ms > MAX_SEARCH_MS:
			break
		step += 1
		var next_beam: Array = []
		var expanded_any: bool = false

		for node in beam:
			var g: GameState = node["state"]
			if posmod(g.present(), 2) != me:
				next_beam.append(node)
				continue
			var mand: Array = g.mandatory_timelines()
			if mand.is_empty():
				next_beam.append(node)
				continue

			expanded_any = true
			var l: int = mand[0]
			var moves: Array = g.board_moves(l)
			if moves.is_empty():
				next_beam.append(node)
				continue

			moves.sort_custom(func(a, b): return _quick_move_priority(g, a) > _quick_move_priority(g, b))
			var limit: int = mini(moves.size(), 6 if level == EASY else (10 if level == NORMAL else 14))

			for i in range(limit):
				var m: Dictionary = moves[i]
				# Не позволяем в один ход создавать цепочку из 2+ новых таймлайнов в прошлом
				var f: Vector4i = m["f"]
				var t: Vector4i = m["t"]
				if (f.w != t.w or f.z != t.z) and g.timelines.size() >= max_allowed_tl:
					continue
				var g2: GameState = g.clone()
				g2.apply_move(m)
				var s: float = _evaluate_fast(g2, me) + _noise()
				var m_list: Array = (node["moves"] as Array).duplicate()
				m_list.append(m)
				next_beam.append({"state": g2, "moves": m_list, "score": s})

		if not expanded_any or next_beam.is_empty():
			break

		next_beam.sort_custom(func(a, b): return float(a["score"]) > float(b["score"]))
		if next_beam.size() > beam_width:
			next_beam.resize(beam_width)
		beam = next_beam

	# Если на лучшем ходе король всё ещё под ударом (например, шах из другой линии),
	# пробуем добавить ход на необязательной доске
	var final_candidates: Array = []
	for node in beam:
		var g: GameState = node["state"]
		if g.submit_error() == "":
			final_candidates.append(node)
		elif Time.get_ticks_msec() - start_ms <= MAX_SEARCH_MS:
			var extra_moves: Array = []
			for l in g.playable_timelines():
				extra_moves.append_array(g.board_moves(l))
			extra_moves.sort_custom(func(a, b): return _quick_move_priority(g, a) > _quick_move_priority(g, b))
			var limit_extra: int = mini(extra_moves.size(), 10)
			for i in range(limit_extra):
				var em: Dictionary = extra_moves[i]
				var g2: GameState = g.clone()
				g2.apply_move(em)
				if g2.submit_error() == "":
					var m_list: Array = (node["moves"] as Array).duplicate()
					m_list.append(em)
					final_candidates.append({"state": g2, "moves": m_list, "score": _evaluate_fast(g2, me) + _noise()})

	final_candidates.sort_custom(func(a, b): return float(a["score"]) > float(b["score"]))
	return final_candidates


func _find_scored_legal_turns(state: GameState, me: int, max_turns: int, start_ms: int) -> Array:
	var results: Array = []
	var g: GameState = state.clone()
	g.turn_moves = []
	var budget := [220]
	var max_moves: int = maxi(2, state.mandatory_timelines().size() + 1)
	var max_tl: int = state.timelines.size() + 1
	_dfs_collect_legal(g, me, budget, max_turns, max_moves, max_tl, start_ms, results)
	results.sort_custom(func(a, b): return float(a["score"]) > float(b["score"]))
	return results


func _dfs_collect_legal(g: GameState, me: int, budget: Array, max_turns: int, max_moves: int, max_tl: int, start_ms: int, results: Array) -> void:
	if results.size() >= max_turns or int(budget[0]) <= 0 or (Time.get_ticks_msec() - start_ms) > MAX_SEARCH_MS:
		return
	budget[0] = int(budget[0]) - 1

	if g.submit_error() == "":
		results.append({
			"state": g.clone(),
			"moves": g.turn_moves.duplicate(),
			"score": _evaluate_fast(g, me) + _noise()
		})
		return

	if g.turn_moves.size() >= max_moves or g.timelines.size() > max_tl:
		return

	var mand: Array = g.mandatory_timelines()
	var lines: Array = [mand[0]] if not mand.is_empty() else g.playable_timelines()
	for l in lines:
		var moves: Array = g.board_moves(l)
		moves.sort_custom(func(a, b): return _quick_move_priority(g, a) > _quick_move_priority(g, b))
		for m in moves:
			g.apply_move(m)
			_dfs_collect_legal(g, me, budget, max_turns, max_moves, max_tl, start_ms, results)
			g.undo_move()
			if results.size() >= max_turns or int(budget[0]) <= 0 or (Time.get_ticks_msec() - start_ms) > MAX_SEARCH_MS:
				return


## Быстрая эвристика сортировки ходов (MVV-LVA, превращения, прыжки, центр).
func _quick_move_priority(g: GameState, m: Dictionary) -> float:
	var f: Vector4i = m["f"]
	var t: Vector4i = m["t"]
	var src_b: PackedByteArray = g.get_board(f.w, f.z)
	var dst_b: PackedByteArray = g.get_board(t.w, t.z)
	var attacker: int = src_b[f.y * g.w + f.x] & GameState.TYPE_MASK
	var victim: int = dst_b[t.y * g.w + t.x]
	var prio: float = 0.0

	if victim != GameState.EMPTY:
		var vt: int = victim & GameState.TYPE_MASK
		var v_val: float = GameState.VALUES[vt] if vt >= 0 and vt < GameState.VALUES.size() else 1.0
		var a_val: float = GameState.VALUES[attacker] if attacker >= 0 and attacker < GameState.VALUES.size() else 1.0
		prio += v_val * 10.0 - a_val
	if int(m.get("promo", 0)) != 0:
		prio += 80.0
	if f.w != t.w or f.z != t.z:
		# Прыжок со взятием полезен, а пустой прыжок в прошлое менее приоритетен, чем развитие на доске
		prio += 2.5 if victim != GameState.EMPTY else -1.5
	# Централизация
	var cx: float = absf(t.x - (g.w - 1) / 2.0)
	var cy: float = absf(t.y - (g.h - 1) / 2.0)
	prio += (3.5 - minf(3.5, (cx + cy) * 0.5))
	return prio


func _noise() -> float:
	match level:
		EASY:
			return rng.randf_range(0.0, 3.2)
		NORMAL:
			return rng.randf_range(0.0, 0.45)
		_:
			return rng.randf_range(0.0, 0.04)


## Сверхбыстрая оценка позиции без клонирования GameState и без полного 4D-трассирования всех фигур.
func _evaluate_fast(g: GameState, me: int) -> float:
	var score: float = 0.0

	for l in g.timelines:
		var is_act: bool = g.is_active(l)
		var weight: float = 1.0 if is_act else 0.55
		var b: PackedByteArray = g.end_board(l)
		for i in b.size():
			var p: int = b[i]
			if p == GameState.EMPTY:
				continue
			var col: int = GameState.piece_color(p)
			var t: int = p & GameState.TYPE_MASK
			var v: float = GameState.VALUES[t] if t >= 0 and t < GameState.VALUES.size() else 0.0
			var x: int = i % g.w
			var y: int = i / g.w

			if t == GameState.PAWN:
				var adv: int = y if col == GameState.WHITE else (g.h - 1 - y)
				v += 0.08 * adv
				if adv >= g.h - 2:
					v += 0.65
				elif adv >= g.h - 3:
					v += 0.25
				if x >= 2 and x <= g.w - 3:
					v += 0.06
			elif t == GameState.KING:
				var back_rank: int = 0 if col == GameState.WHITE else (g.h - 1)
				var dist_back: int = absi(y - back_rank)
				v -= float(dist_back) * 0.12
				var shield_dir: int = 1 if col == GameState.WHITE else -1
				var sy: int = y + shield_dir
				if sy >= 0 and sy < g.h:
					for sx in range(maxi(0, x - 1), mini(g.w, x + 2)):
						var sp: int = b[sy * g.w + sx]
						if sp != GameState.EMPTY and GameState.piece_color(sp) == col and (sp & GameState.TYPE_MASK) == GameState.PAWN:
							v += 0.12
			else:
				var cx: float = absf(x - (g.w - 1) / 2.0)
				var cy: float = absf(y - (g.h - 1) / 2.0)
				v += 0.08 * (3.2 - minf(3.2, (cx + cy) / 2.0))
				var home_y: int = 0 if col == GameState.WHITE else (g.h - 1)
				if y == home_y and (t == GameState.KNIGHT or t == GameState.BISHOP or t == GameState.UNICORN or t == GameState.PRINCESS):
					v -= 0.14

			if col == me:
				score += v * weight
			else:
				score -= v * weight

	# Быстрая проверка подставы собственного короля (in-place без клонирования)
	if g.in_check():
		return score - 20000.0

	# Проверяем, поставили ли мы шах сопернику
	if g.is_king_capturable(me):
		score += 0.85 if level >= NORMAL else 0.35

	# Умный контроль мультивселенной: не плодить неактивные линии в пользу соперника
	var my_lines: int = g.max_l if me == GameState.WHITE else -g.min_l
	var opp_lines: int = -g.min_l if me == GameState.WHITE else g.max_l
	if my_lines > opp_lines + 1:
		score -= float(my_lines - opp_lines - 1) * 0.45
	else:
		score -= float(my_lines) * 0.10

	return score


## Полная тактическая оценка для финалистов лучевого поиска (учитывает подставы фигур).
func _evaluate(g: GameState, me: int) -> float:
	var opp: int = 1 - me
	var score: float = _evaluate_fast(g, me)
	if score < -10000.0:
		return score

	# Временно прокидываем обязательные доски вперёд (in-place), чтобы оценить лучший ответ соперника
	var mand: Array = g.mandatory_timelines()
	for l in mand:
		g._append(l, g.end_board(l))
	var opp_best_cap: float = g.best_capture_value(opp)
	for l in mand:
		var bs: Array = g.timelines[l]["b"]
		bs.pop_back()

	match level:
		EASY:
			score -= minf(opp_best_cap, 9.0) * 0.25
		NORMAL:
			score -= minf(opp_best_cap, 10.0) * 0.72
		HARD:
			score -= minf(opp_best_cap, 10.0) * 0.92
			score += minf(g.best_capture_value(me), 10.0) * 0.18

	return score
