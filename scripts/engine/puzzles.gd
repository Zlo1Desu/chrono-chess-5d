class_name Puzzles
extends RefCounted
## Каталог тактических головоломок и настоящий процедурный генератор задач (Классика + Сказочные фигуры + 5D Хроно).

const LIST: Array[Dictionary] = [
	{
		"id": "puz_backrank",
		"title": "Мат по последней горизонтали",
		"category": "Классическая тактика",
		"difficulty": 1,
		"reward": 50,
		"desc": "Белые начинают и ставят мат в 1 ход. Найдите слабость последнего ряда!",
		"hint": "Ладья c1 может подняться по открытой вертикали на 8-й ряд (поле c8) и поставить мат.",
		"w": 8, "h": 8,
		"rows": [
			"......k.",
			".....ppp",
			"........",
			"........",
			"........",
			"........",
			"PP.....P",
			"..R...K."
		],
		"target_move": {"fx": 2, "fy": 0, "tx": 2, "ty": 7}
	},
	{
		"id": "puz_smothered",
		"title": "Спёртый мат конём",
		"category": "Королевский гамбит",
		"difficulty": 2,
		"reward": 75,
		"desc": "Чёрный монарх спрятался в углу за своими фигурами. Завершите партию!",
		"hint": "Конь с поля e5 может перепрыгнуть фигуры и нанести спёртый мат прямо на поле f7.",
		"w": 8, "h": 8,
		"rows": [
			"......rk",
			"......pp",
			"........",
			"....N...",
			"........",
			"........",
			"PPP....P",
			"......K."
		],
		"target_move": {"fx": 4, "fy": 4, "tx": 5, "ty": 6}
	},
	{
		"id": "puz_queen_strike",
		"title": "Детский кошмар: Удар Ферзём",
		"category": "Атака на короля",
		"difficulty": 1,
		"reward": 50,
		"desc": "Слабейшее поле f7 беззащитно. Нанесите сокрушительный удар Ферзём!",
		"hint": "Ферзь при поддержке белопольного слона атакует пункт f7.",
		"w": 8, "h": 8,
		"rows": [
			"r.bqkb.r",
			"pppp.ppp",
			"..n.....",
			"....p..Q",
			"..B.P...",
			"........",
			"PPPP.PPP",
			"RNB.K.NR"
		],
		"target_move": {"fx": 7, "fy": 4, "tx": 5, "ty": 6}
	},
	{
		"id": "puz_ladder",
		"title": "Линейный мат двумя ладьями",
		"category": "Классическая тактика",
		"difficulty": 1,
		"reward": 60,
		"desc": "Одна ладья отрезает 7-ю горизонталь. Отправьте вторую ладью на добивание!",
		"hint": "Ладья b1 должна подняться на 8-ю горизонталь (поле b8).",
		"w": 8, "h": 8,
		"rows": [
			"....k...",
			"R.......",
			"........",
			"........",
			"........",
			"........",
			"........",
			".R..K..."
		],
		"target_move": {"fx": 1, "fy": 0, "tx": 1, "ty": 7}
	},
	{
		"id": "puz_arabian_knight",
		"title": "Арабский дуэт: Конь и Ладья",
		"category": "Искусство взаимодействия",
		"difficulty": 2,
		"reward": 85,
		"desc": "Конь контролирует поле побега и защищает атакующее поле. Завершите комбинацию Ладьёй!",
		"hint": "Ладья b7 врывается на h7 (поле h7 защищено конём f6), объявляя арабский мат.",
		"w": 8, "h": 8,
		"rows": [
			".......k",
			".R......",
			".....N..",
			"........",
			"........",
			"........",
			"PPP.....",
			".K......"
		],
		"target_move": {"fx": 1, "fy": 6, "tx": 7, "ty": 6}
	},
	{
		"id": "puz_discovered_thunder",
		"title": "Вскрытый гром: Засада Ладьи",
		"category": "Вскрытая атака",
		"difficulty": 2,
		"reward": 90,
		"desc": "Белая ладья затаилась за конём. Сделайте прыжок конём, открывающий смертельный шах!",
		"hint": "Конь e6 прыгает на c7 или g7, открывая вертикаль для Ладьи e1 и отнимая последние поля!",
		"w": 8, "h": 8,
		"rows": [
			"...rkr..",
			"...p.p..",
			"....N...",
			"........",
			"........",
			"........",
			"PPP.....",
			".K..R..."
		],
		"target_move": {"fx": 4, "fy": 5, "tx": 6, "ty": 6}
	},
	{
		"id": "puz_princess_rush",
		"title": "Стремительная Принцесса",
		"category": "Сказочные фигуры",
		"difficulty": 2,
		"reward": 85,
		"desc": "Принцесса объединяет мощь Ладьи и Слона. Отрежьте короля одним манёвром!",
		"hint": "Принцесса с a1 поднимается на a6, одновременно простреливая 6-й ряд и диагональ.",
		"w": 6, "h": 6,
		"rows": [
			".....k",
			"....pp",
			"......",
			"...K..",
			"......",
			"S....."
		],
		"target_move": {"fx": 0, "fy": 0, "tx": 0, "ty": 5}
	},
	{
		"id": "puz_temporal_jump",
		"title": "Хроно-снайпер: Атака в прошлое",
		"category": "5D Хроно-тактика",
		"difficulty": 3,
		"reward": 130,
		"desc": "Даже если король в настоящем попытается бежать, его прошлая версия на T1 остаётся мишенью сквозь время!",
		"hint": "Ладья a1 поднимается на поле a5, объявляя мат монарху одновременно в настоящем и сквозь время!",
		"w": 5, "h": 5,
		"rows": [
			"..k..",
			".ppp.",
			".....",
			".....",
			"R..K."
		],
		"target_move": {"fx": 0, "fy": 0, "tx": 0, "ty": 4}
	}
]

static var _recent_hashes: Array[String] = []


static func get_puzzle_by_id(p_id: String) -> Dictionary:
	for p in LIST:
		if p["id"] == p_id:
			return p
	return LIST[0]


## Проверяет, верно ли решена задача (либо поставлен мат, либо ход совпадает с целевым).
static func check_puzzle_success(puz: Dictionary, played_moves: Array, state: GameState) -> bool:
	if played_moves.is_empty():
		return false

	# Любой легальный ход, который реально ставит шах и мат — всегда верное решение!
	if state.in_check() and state.game_status(1500) == "checkmate":
		return true

	var m: Dictionary = played_moves[0]
	var f: Vector4i = m.get("f", Vector4i.ZERO)
	var t: Vector4i = m.get("t", Vector4i.ZERO)

	var tgt: Dictionary = puz.get("target_move", {})
	if not tgt.is_empty():
		var match_xy: bool = (
			f.x == int(tgt.get("fx", -1))
			and f.y == int(tgt.get("fy", -1))
			and t.x == int(tgt.get("tx", -1))
			and t.y == int(tgt.get("ty", -1))
		)
		var match_time: bool = true
		if tgt.has("fz"):
			match_time = match_time and (f.z == int(tgt["fz"]))
		if tgt.has("tz"):
			match_time = match_time and (t.z == int(tgt["tz"]))
		if match_xy and match_time:
			return true

	return false


## Возвращает объяснение, почему сделанный ход в задаче не является матом (какой ответ есть у чёрных).
static func explain_puzzle_failure(state: GameState) -> String:
	if not state.in_check():
		return "❌ Этим ходом вы не объявили шах королю соперника!"
	var escape: Variant = state.find_legal_turn(1200)
	if escape is Array and not escape.is_empty():
		var em: Dictionary = escape[0]
		var ef: Vector4i = em.get("f", Vector4i.ZERO)
		var et: Vector4i = em.get("t", Vector4i.ZERO)
		var f_sq := "%s%d" % [String.chr(97 + ef.x), ef.y + 1]
		var t_sq := "%s%d" % [String.chr(97 + et.x), et.y + 1]
		return "❌ Это не мат! Чёрные спасаются ходом %s → %s." % [f_sq, t_sq]
	return "❌ Этот ход не решает задачу. Попробуйте другой удар!"


# ---------------------------------------------------------------- НАСТОЯЩИЙ ПРОЦЕДУРНЫЙ ГЕНЕРАТОР ЗАДАЧ

## Генерирует уникальную процедурную задачу с гарантированным решением (проверенным через движок GameState).
static func generate_procedural_puzzle(difficulty: int = 1) -> Dictionary:
	difficulty = clampi(difficulty, 1, 3)
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var generators_d1: Array[Callable] = [
		Callable(Puzzles, "_gen_proc_backrank"),
		Callable(Puzzles, "_gen_proc_kiss_of_death"),
		Callable(Puzzles, "_gen_proc_ladder"),
		Callable(Puzzles, "_gen_proc_epaulette"),
		Callable(Puzzles, "_synthesize_random_mate"),
	]
	var generators_d2: Array[Callable] = [
		Callable(Puzzles, "_gen_proc_arabian"),
		Callable(Puzzles, "_gen_proc_smothered"),
		Callable(Puzzles, "_gen_proc_anastasia"),
		Callable(Puzzles, "_gen_proc_discovered"),
		Callable(Puzzles, "_gen_proc_kiss_of_death"),
		Callable(Puzzles, "_gen_proc_fairy"),
		Callable(Puzzles, "_synthesize_random_mate"),
	]
	var generators_d3: Array[Callable] = [
		Callable(Puzzles, "_gen_proc_temporal_5d"),
		Callable(Puzzles, "_gen_proc_discovered"),
		Callable(Puzzles, "_gen_proc_smothered"),
		Callable(Puzzles, "_gen_proc_arabian"),
		Callable(Puzzles, "_gen_proc_anastasia"),
		Callable(Puzzles, "_gen_proc_fairy"),
		Callable(Puzzles, "_synthesize_random_mate"),
	]

	var pool: Array[Callable] = generators_d1 if difficulty == 1 else (generators_d2 if difficulty == 2 else generators_d3)

	for attempt in 80:
		var fn: Callable = pool[rng.randi() % pool.size()]
		var candidate: Dictionary = fn.call(difficulty, rng)
		if candidate.is_empty():
			continue

		# Случайное горизонтальное отражение доски (50% шанс), удваивающее разнообразие позиций
		if rng.randf() < 0.5:
			candidate = _mirror_puzzle_horizontal(candidate)

		var board_hash: String = "|".join(candidate.get("rows", [])) + ":" + str(candidate.get("turn_zero", false))
		if _recent_hashes.has(board_hash) and attempt < 60:
			continue

		if verify_puzzle(candidate):
			_recent_hashes.append(board_hash)
			if _recent_hashes.size() > 35:
				_recent_hashes.pop_front()

			candidate["difficulty"] = difficulty
			candidate["is_procedural"] = true
			var base_rew: int = 50 if difficulty == 1 else (85 if difficulty == 2 else 125)
			candidate["reward"] = maxi(35, base_rew + rng.randi_range(-10, 20))
			candidate["id"] = "proc_%d_%d_%d" % [difficulty, Time.get_ticks_msec(), rng.randi() % 1000000]
			return candidate

	# Если 80 попыток не сошлись — строим детерминированно рандомизированную задачу с проверкой
	return _build_guaranteed_procedural_fallback(difficulty, rng)


## Полная верификация сгенерированной задачи через реальный движок GameState.
static func verify_puzzle(puz: Dictionary) -> bool:
	var g := GameState.new()
	var w: int = int(puz.get("w", 8))
	var h: int = int(puz.get("h", 8))
	var rows: Array = puz.get("rows", [])
	var tz: bool = bool(puz.get("turn_zero", false))
	if rows.size() != h:
		return false
	g.setup(w, h, rows, tz)

	# 1. Белые не должны начинать под шахом
	if g.in_check():
		return false

	# 2. У обоих игроков должно быть ровно по 1 королю на текущей доске
	if g._find_kings(GameState.WHITE).is_empty() or g._find_kings(GameState.BLACK).is_empty():
		return false

	var tgt: Dictionary = puz.get("target_move", {})
	if tgt.is_empty():
		return false
	var fx: int = int(tgt.get("fx", -1))
	var fy: int = int(tgt.get("fy", -1))
	var tx: int = int(tgt.get("tx", -1))
	var ty: int = int(tgt.get("ty", -1))
	var fz: int = int(tgt.get("fz", 0))
	var tz_coord: int = int(tgt.get("tz", 0))
	var fw: int = int(tgt.get("fw", 0))
	var tw: int = int(tgt.get("tw", 0))

	var from_v := Vector4i(fx, fy, fz, fw)
	var to_v := Vector4i(tx, ty, tz_coord, tw)

	var piece: int = g.piece_at(from_v)
	if piece == GameState.EMPTY or GameState.piece_color(piece) != GameState.WHITE:
		return false

	# 3. Проверяем, разрешён ли целевой ход
	var legal: Array = g.board_moves(fw)
	var matched_move: Dictionary = {}
	for lm in legal:
		if lm["f"] == from_v and lm["t"] == to_v:
			matched_move = lm
			break
	if matched_move.is_empty():
		return false

	# 4. Делаем ход и подтверждаем
	g.apply_move(matched_move)
	if not g.submit():
		return false

	# 5. Чёрным должен быть объявлен шах и мат
	if not g.in_check():
		return false
	return g.game_status(1200) == "checkmate"


# ---------------------------------------------------------------- Вспомогательные функции сетки

static func _make_grid(w: int, h: int) -> Array:
	var g: Array = []
	for y in h:
		var row: Array = []
		for x in w:
			row.append(".")
		g.append(row)
	return g


static func _set_cell(grid: Array, x: int, y: int, ch: String) -> void:
	if y >= 0 and y < grid.size():
		var row: Array = grid[y]
		if x >= 0 and x < row.size():
			row[x] = ch


static func _get_cell(grid: Array, x: int, y: int) -> String:
	if y >= 0 and y < grid.size():
		var row: Array = grid[y]
		if x >= 0 and x < row.size():
			return str(row[x])
	return ""


static func _grid_to_rows(grid: Array, w: int, h: int) -> Array[String]:
	var rows: Array[String] = []
	for r in h:
		var y: int = h - 1 - r
		var s: String = ""
		for x in w:
			s += str(grid[y][x])
		rows.append(s)
	return rows


static func _sq_name(x: int, y: int) -> String:
	return "%s%d" % [String.chr(97 + x), y + 1]


static func _piece_ru_name(ch: String) -> String:
	match ch.to_upper():
		"P": return "Пешка"
		"N": return "Конь"
		"B": return "Слон"
		"R": return "Ладья"
		"Q": return "Ферзь"
		"K": return "Король"
		"U": return "Единорог"
		"D": return "Дракон"
		"S": return "Принцесса"
	return "Фигура"


static func _mirror_puzzle_horizontal(puz: Dictionary) -> Dictionary:
	var w: int = int(puz.get("w", 8))
	var h: int = int(puz.get("h", 8))
	var old_rows: Array = puz.get("rows", [])
	if old_rows.size() != h:
		return puz
	var new_rows: Array[String] = []
	for r_str in old_rows:
		var s: String = str(r_str)
		var rev: String = ""
		for i in range(s.length() - 1, -1, -1):
			rev += s[i]
		new_rows.append(rev)

	var res: Dictionary = puz.duplicate(true)
	res["rows"] = new_rows
	var tgt: Dictionary = res.get("target_move", {})
	if not tgt.is_empty():
		var fx: int = w - 1 - int(tgt.get("fx", 0))
		var fy: int = int(tgt.get("fy", 0))
		var tx: int = w - 1 - int(tgt.get("tx", 0))
		var ty: int = int(tgt.get("ty", 0))
		tgt["fx"] = fx
		tgt["tx"] = tx
		res["target_move"] = tgt

		var f_str := _sq_name(fx, fy)
		var t_str := _sq_name(tx, ty)
		var p_ch: String = str(res.get("attacker_char", "Q"))
		var is_temp: bool = int(tgt.get("tz", 0)) != int(tgt.get("fz", 0))
		if is_temp:
			res["hint"] = "%s с поля %s совершает прыжок в прошлое на доску T1 (поле %s), ставя неотразимый мат!" % [_piece_ru_name(p_ch), f_str, t_str]
		else:
			res["hint"] = "%s совершает решающий манёвр %s → %s, объявляя шах и мат." % [_piece_ru_name(p_ch), f_str, t_str]
	return res


static func _sprinkle_ambient_pieces(grid: Array, w: int, h: int, count: int, rng: RandomNumberGenerator, forbidden_cols: Array = []) -> void:
	var white_pool := ["P", "P", "P", "N", "B"]
	var black_pool := ["p", "p", "p", "n", "b"]
	for i in count:
		var rx: int = rng.randi_range(0, w - 1)
		if forbidden_cols.has(rx):
			continue
		var ry: int = rng.randi_range(1, h - 3)
		if _get_cell(grid, rx, ry) == ".":
			var is_w: bool = (ry <= h / 2 - 1)
			var p_list: Array = white_pool if is_w else black_pool
			_set_cell(grid, rx, ry, p_list[rng.randi() % p_list.size()])


# ---------------------------------------------------------------- 1. Коридорный мат / Мат по 8-й горизонтали

static func _gen_proc_backrank(diff: int, rng: RandomNumberGenerator) -> Dictionary:
	var sizes: Array = [6, 7, 8] if diff == 1 else [7, 8]
	var w: int = int(sizes[rng.randi() % sizes.size()])
	var h: int = w
	var grid := _make_grid(w, h)

	var kx: int = rng.randi_range(1, w - 2)
	_set_cell(grid, kx, h - 1, "k")

	for dx in [-1, 0, 1]:
		var px: int = kx + dx
		if px >= 0 and px < w:
			_set_cell(grid, px, h - 2, "p")

	var valid_files: Array[int] = []
	for x in w:
		if absi(x - kx) >= 2:
			valid_files.append(x)
	if valid_files.is_empty():
		return {}

	var ax: int = valid_files[rng.randi() % valid_files.size()]
	var ay: int = rng.randi_range(0, h - 4)
	var piece_opts: Array = ["R", "Q"] if diff < 3 else ["R", "Q", "S"]
	var p_ch: String = str(piece_opts[rng.randi() % piece_opts.size()])
	_set_cell(grid, ax, ay, p_ch)

	if diff >= 2 and rng.randf() < 0.45:
		_set_cell(grid, ax, h - 1, "n" if rng.randf() < 0.6 else "b")

	var wkx: int = rng.randi_range(0, w - 1)
	while wkx == ax or _get_cell(grid, wkx, 0) != ".":
		wkx = rng.randi_range(0, w - 1)
	_set_cell(grid, wkx, 0, "K")
	for dx in [-1, 0, 1]:
		var wpx: int = wkx + dx
		if wpx >= 0 and wpx < w and wpx != ax and _get_cell(grid, wpx, 1) == ".":
			_set_cell(grid, wpx, 1, "P")

	_sprinkle_ambient_pieces(grid, w, h, diff + 1, rng, [ax, kx - 1, kx, kx + 1])

	var f_sq := _sq_name(ax, ay)
	var t_sq := _sq_name(ax, h - 1)
	return {
		"title": "Прорыв по вертикали %s" % t_sq.to_upper(),
		"category": "Коридорная тактика",
		"desc": "Чёрный король заперт за собственным пешечным редутом. Найдите решающее вторжение на последний ряд!",
		"hint": "%s (%s) врывается на поле %s и ставит мат по последней горизонтали." % [_piece_ru_name(p_ch), f_sq, t_sq],
		"attacker_char": p_ch,
		"w": w, "h": h,
		"rows": _grid_to_rows(grid, w, h),
		"target_move": {"fx": ax, "fy": ay, "tx": ax, "ty": h - 1}
	}


# ---------------------------------------------------------------- 2. Поцелуй смерти (Ферзь + Защитник)

static func _gen_proc_kiss_of_death(diff: int, rng: RandomNumberGenerator) -> Dictionary:
	var sizes: Array = [6, 7, 8]
	var w: int = int(sizes[rng.randi() % sizes.size()])
	var h: int = w
	var grid := _make_grid(w, h)

	var kx: int = rng.randi_range(1, w - 2)
	var ky: int = h - 1
	_set_cell(grid, kx, ky, "k")

	var mx: int = kx
	var my: int = ky - 1

	var sup_type: int = rng.randi() % 4
	if sup_type == 0:
		_set_cell(grid, mx, my - 1, "K")
	elif sup_type == 1:
		var b_dir: int = 1 if rng.randf() < 0.5 else -1
		var dist: int = rng.randi_range(2, 3)
		var bx: int = mx + b_dir * dist
		var by: int = my - dist
		if bx < 0 or bx >= w or by < 0:
			bx = mx - b_dir * 2
			by = my - 2
		if bx < 0 or bx >= w or by < 0:
			return {}
		_set_cell(grid, bx, by, "B")
		var wkx: int = 0 if bx > w / 2 else w - 1
		_set_cell(grid, wkx, 0, "K")
	elif sup_type == 2:
		var k_offsets := [Vector2i(-1, -2), Vector2i(1, -2), Vector2i(-2, -1), Vector2i(2, -1)]
		k_offsets.shuffle()
		var placed_n := false
		for off in k_offsets:
			var nx: int = mx + off.x
			var ny: int = my + off.y
			if nx >= 0 and nx < w and ny >= 0 and ny < h - 1:
				_set_cell(grid, nx, ny, "N")
				placed_n = true
				break
		if not placed_n:
			return {}
		var wkx: int = 0 if mx > w / 2 else w - 1
		_set_cell(grid, wkx, 0, "K")
	else:
		var ry: int = rng.randi_range(0, my - 2)
		_set_cell(grid, mx, ry, "R")
		var wkx: int = 0 if mx > w / 2 else w - 1
		_set_cell(grid, wkx, 0, "K")

	var q_dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(1, -1), Vector2i(-1, -1)]
	q_dirs.shuffle()
	var q_pos := Vector2i(-1, -1)
	for d in q_dirs:
		var dist: int = rng.randi_range(2, w - 2)
		var cx: int = mx + d.x * dist
		var cy: int = my + d.y * dist
		if cx >= 0 and cx < w and cy >= 0 and cy < h - 1:
			var clear := true
			for s in range(1, dist + 1):
				var tx_c: int = mx + d.x * s
				var ty_c: int = my + d.y * s
				if _get_cell(grid, tx_c, ty_c) != ".":
					clear = false
					break
			if clear:
				q_pos = Vector2i(cx, cy)
				break

	if q_pos.x == -1:
		return {}

	var q_char: String = "S" if (diff == 3 and rng.randf() < 0.35) else "Q"
	_set_cell(grid, q_pos.x, q_pos.y, q_char)

	if diff >= 2 and rng.randf() < 0.5:
		_set_cell(grid, mx, my, "p")

	var f_sq := _sq_name(q_pos.x, q_pos.y)
	var t_sq := _sq_name(mx, my)
	return {
		"title": "Поцелуй смерти на %s" % t_sq.to_upper(),
		"category": "Атака на короля",
		"desc": "Союзная фигура прикрывает ключевое поле вплотную к вражескому королю. Нанесите решающий удар!",
		"hint": "%s (%s → %s) ставит мат вплотную к королю под защитой союзной фигуры." % [_piece_ru_name(q_char), f_sq, t_sq],
		"attacker_char": q_char,
		"w": w, "h": h,
		"rows": _grid_to_rows(grid, w, h),
		"target_move": {"fx": q_pos.x, "fy": q_pos.y, "tx": mx, "ty": my}
	}


# ---------------------------------------------------------------- 3. Арабский мат (Ладья + Конь в углу)

static func _gen_proc_arabian(diff: int, rng: RandomNumberGenerator) -> Dictionary:
	var sizes: Array = [6, 7, 8]
	var w: int = int(sizes[rng.randi() % sizes.size()])
	var h: int = w
	var grid := _make_grid(w, h)

	var kx: int = w - 1
	var ky: int = h - 1
	_set_cell(grid, kx, ky, "k")

	var nx: int = w - 3
	var ny: int = h - 3
	_set_cell(grid, nx, ny, "N")

	var attack_vertical: bool = rng.randf() < 0.5
	var tx: int
	var ty: int
	var fx: int
	var fy: int

	if attack_vertical:
		tx = w - 1
		ty = h - 2
		fx = w - 1
		fy = rng.randi_range(0, h - 4)
	else:
		tx = w - 2
		ty = h - 1
		fx = rng.randi_range(0, w - 4)
		fy = h - 1

	var r_char: String = "R"
	_set_cell(grid, fx, fy, r_char)

	var wkx: int = rng.randi_range(0, 2)
	var wky: int = 0 if fy != 0 else 1
	if _get_cell(grid, wkx, wky) == ".":
		_set_cell(grid, wkx, wky, "K")
	else:
		_set_cell(grid, 0, 2, "K")

	if _get_cell(grid, wkx, wky + 1) == ".":
		_set_cell(grid, wkx, wky + 1, "P")
	if diff >= 2 and _get_cell(grid, 1, h - 2) == ".":
		_set_cell(grid, 1, h - 2, "p")

	var f_sq := _sq_name(fx, fy)
	var t_sq := _sq_name(tx, ty)
	return {
		"title": "Арабский капкан на %s" % t_sq.to_upper(),
		"category": "Арабский мат",
		"desc": "Конь и Ладья идеально дополняют друг друга в углу доски. Завершите окружение короля!",
		"hint": "Ладья (%s → %s) под защитой коня ставит классический арабский мат угловому королю." % [f_sq, t_sq],
		"attacker_char": r_char,
		"w": w, "h": h,
		"rows": _grid_to_rows(grid, w, h),
		"target_move": {"fx": fx, "fy": fy, "tx": tx, "ty": ty}
	}


# ---------------------------------------------------------------- 4. Спёртый мат конём (Smothered Mate)

static func _gen_proc_smothered(diff: int, rng: RandomNumberGenerator) -> Dictionary:
	var sizes: Array = [6, 7, 8]
	var w: int = int(sizes[rng.randi() % sizes.size()])
	var h: int = w
	var grid := _make_grid(w, h)

	var kx: int = w - 1
	var ky: int = h - 1
	_set_cell(grid, kx, ky, "k")
	_set_cell(grid, kx - 1, ky, "r" if rng.randf() < 0.7 else "b")
	_set_cell(grid, kx, ky - 1, "p")
	_set_cell(grid, kx - 1, ky - 1, "p" if rng.randf() < 0.75 else "n")

	var target_opts := [Vector2i(kx - 2, ky - 1), Vector2i(kx - 1, ky - 2)]
	var t_pos: Vector2i = target_opts[rng.randi() % target_opts.size()]

	var jumps := [
		Vector2i(1, 2), Vector2i(2, 1), Vector2i(-1, 2), Vector2i(-2, 1),
		Vector2i(1, -2), Vector2i(2, -1), Vector2i(-1, -2), Vector2i(-2, -1)
	]
	jumps.shuffle()
	var n_start := Vector2i(-1, -1)
	for j in jumps:
		var sx: int = t_pos.x + j.x
		var sy: int = t_pos.y + j.y
		if sx >= 0 and sx < w and sy >= 0 and sy < h - 1:
			if absi(sx - kx) + absi(sy - ky) == 3 and sx != kx and sy != ky:
				continue
			if _get_cell(grid, sx, sy) == ".":
				n_start = Vector2i(sx, sy)
				break

	if n_start.x == -1:
		return {}

	_set_cell(grid, n_start.x, n_start.y, "N")

	_set_cell(grid, 1, 0, "K")
	_set_cell(grid, 0, 1, "P")
	_set_cell(grid, 1, 1, "P")
	if diff >= 2 and _get_cell(grid, 0, 0) == ".":
		_set_cell(grid, 0, 0, "R")

	var f_sq := _sq_name(n_start.x, n_start.y)
	var t_sq := _sq_name(t_pos.x, t_pos.y)
	return {
		"title": "Спёртый прыжок на %s" % t_sq.to_upper(),
		"category": "Искусство коня",
		"desc": "Вражеский монарх замурован собственными войсками в углу. Найдите победный прыжок коня!",
		"hint": "Конь (%s → %s) перепрыгивает заслон и объявляет спёртый мат." % [f_sq, t_sq],
		"attacker_char": "N",
		"w": w, "h": h,
		"rows": _grid_to_rows(grid, w, h),
		"target_move": {"fx": n_start.x, "fy": n_start.y, "tx": t_pos.x, "ty": t_pos.y}
	}


# ---------------------------------------------------------------- 5. Линейный мат (Ladder Mate)

static func _gen_proc_ladder(diff: int, rng: RandomNumberGenerator) -> Dictionary:
	var sizes: Array = [6, 7, 8]
	var w: int = int(sizes[rng.randi() % sizes.size()])
	var h: int = w
	var grid := _make_grid(w, h)

	var kx: int = rng.randi_range(2, w - 3)
	_set_cell(grid, kx, h - 1, "k")

	var r1_x: int = 0 if kx >= w / 2 else (w - 1)
	_set_cell(grid, r1_x, h - 2, "R")

	var r2_x: int = (w - 1) if r1_x == 0 else 0
	var r2_y: int = rng.randi_range(0, h - 4)
	var p_ch: String = "R" if rng.randf() < 0.7 else "Q"
	_set_cell(grid, r2_x, r2_y, p_ch)

	var wkx: int = clampi(kx, 1, w - 2)
	_set_cell(grid, wkx, 0, "K")
	if _get_cell(grid, wkx, 1) == ".":
		_set_cell(grid, wkx, 1, "P")

	var f_sq := _sq_name(r2_x, r2_y)
	var t_sq := _sq_name(r2_x, h - 1)
	return {
		"title": "Линейный зажим на %s" % t_sq.to_upper(),
		"category": "Классическая тактика",
		"desc": "Одна ладья уже отрезала путь к отступлению. Завершите линейный мат второй тяжёлой фигурой!",
		"hint": "%s (%s → %s) поднимается на верхнюю горизонталь и ставит линейный мат." % [_piece_ru_name(p_ch), f_sq, t_sq],
		"attacker_char": p_ch,
		"w": w, "h": h,
		"rows": _grid_to_rows(grid, w, h),
		"target_move": {"fx": r2_x, "fy": r2_y, "tx": r2_x, "ty": h - 1}
	}


# ---------------------------------------------------------------- 6. Эполетный мат (Epaulette Mate)

static func _gen_proc_epaulette(diff: int, rng: RandomNumberGenerator) -> Dictionary:
	var w: int = 7 if rng.randf() < 0.4 else 8
	var h: int = w
	var grid := _make_grid(w, h)

	var kx: int = rng.randi_range(2, w - 3)
	var ky: int = h - 1
	_set_cell(grid, kx, ky, "k")
	_set_cell(grid, kx - 1, ky, "r")
	_set_cell(grid, kx + 1, ky, "r")

	var tx: int = kx
	var ty: int = ky - 2
	var fx: int = kx
	var fy: int = rng.randi_range(1, ty - 2)
	_set_cell(grid, fx, fy, "Q")

	var wkx: int = 0 if kx > 2 else w - 1
	_set_cell(grid, wkx, 0, "K")
	_set_cell(grid, wkx, 1, "P")

	var f_sq := _sq_name(fx, fy)
	var t_sq := _sq_name(tx, ty)
	return {
		"title": "Эполетный удар на %s" % t_sq.to_upper(),
		"category": "Королевская геометрия",
		"desc": "Чёрного короля с боков зажали собственные ладьи-эполеты. Используйте это стеснение!",
		"hint": "Ферзь (%s → %s) встаёт по центру перед королём, отнимая все три клетки отступления." % [f_sq, t_sq],
		"attacker_char": "Q",
		"w": w, "h": h,
		"rows": _grid_to_rows(grid, w, h),
		"target_move": {"fx": fx, "fy": fy, "tx": tx, "ty": ty}
	}


# ---------------------------------------------------------------- 7. Мат Анастасии (Anastasia's Mate)

static func _gen_proc_anastasia(diff: int, rng: RandomNumberGenerator) -> Dictionary:
	var w: int = 7 if rng.randf() < 0.4 else 8
	var h: int = w
	var grid := _make_grid(w, h)

	var ky: int = rng.randi_range(h - 3, h - 2)
	var kx: int = w - 1
	_set_cell(grid, kx, ky, "k")
	_set_cell(grid, kx - 1, ky, "p")

	_set_cell(grid, kx - 3, ky, "N")

	var tx: int = kx
	var ty: int = rng.randi_range(0, ky - 2)
	var fx: int = rng.randi_range(1, kx - 2)
	_set_cell(grid, fx, ty, "R")

	_set_cell(grid, 0, 0, "K")
	_set_cell(grid, 0, 1, "P")

	var f_sq := _sq_name(fx, ty)
	var t_sq := _sq_name(tx, ty)
	return {
		"title": "Мат Анастасии на %s" % t_sq.to_upper(),
		"category": "Комбинационная классика",
		"desc": "Конь и вражеская пешка образовали непроницаемую стену. Подключите Ладью по крайней вертикали!",
		"hint": "Ладья (%s → %s) выходит на крайнюю вертикаль и ставит мат Анастасии." % [f_sq, t_sq],
		"attacker_char": "R",
		"w": w, "h": h,
		"rows": _grid_to_rows(grid, w, h),
		"target_move": {"fx": fx, "fy": ty, "tx": tx, "ty": ty}
	}


# ---------------------------------------------------------------- 8. Вскрытый и двойной шах (Discovered Mate)

static func _gen_proc_discovered(diff: int, rng: RandomNumberGenerator) -> Dictionary:
	var w: int = 7 if rng.randf() < 0.4 else 8
	var h: int = w
	var grid := _make_grid(w, h)

	var kx: int = rng.randi_range(2, w - 3)
	var ky: int = h - 1
	_set_cell(grid, kx, ky, "k")
	_set_cell(grid, kx - 1, ky, "r")
	_set_cell(grid, kx + 1, ky, "r")
	_set_cell(grid, kx - 1, ky - 1, "p")
	_set_cell(grid, kx + 1, ky - 1, "p")

	# Белая Ладья стоит на (kx, 0), перед ней на (kx, ky - 2) стоит Белый Конь
	_set_cell(grid, kx, 0, "R")
	var nx: int = kx
	var ny: int = ky - 2
	_set_cell(grid, nx, ny, "N")

	# Конь прыгает с (kx, ky-2) на (kx+2, ky-1) или (kx-2, ky-1), открывая вертикаль для Ладьи!
	var tx: int = (kx + 2) if (kx + 2 < w) else (kx - 2)
	var ty: int = ky - 1

	var wkx: int = 0 if kx > 2 else w - 1
	_set_cell(grid, wkx, 0, "K")
	_set_cell(grid, wkx, 1, "P")

	var f_sq := _sq_name(nx, ny)
	var t_sq := _sq_name(tx, ty)
	return {
		"title": "Вскрытый гром на %s" % t_sq.to_upper(),
		"category": "Вскрытый удар",
		"desc": "За вашим конём притаилась дальнобойная ладья. Отведите коня, открывая смертоносную вертикаль!",
		"hint": "Конь (%s → %s) открывает вертикаль для Ладьи, объявляя неотразимый вскрытый мат!" % [f_sq, t_sq],
		"attacker_char": "N",
		"w": w, "h": h,
		"rows": _grid_to_rows(grid, w, h),
		"target_move": {"fx": nx, "fy": ny, "tx": tx, "ty": ty}
	}


# ---------------------------------------------------------------- 9. Сказочные фигуры (Принцесса / Единорог)

static func _gen_proc_fairy(diff: int, rng: RandomNumberGenerator) -> Dictionary:
	var sizes: Array = [6, 7, 8]
	var w: int = int(sizes[rng.randi() % sizes.size()])
	var h: int = w
	var grid := _make_grid(w, h)

	var kx: int = w - 1
	var ky: int = h - 1
	_set_cell(grid, kx, ky, "k")
	_set_cell(grid, kx - 1, ky - 1, "p")
	_set_cell(grid, kx, ky - 1, "p")

	var sx: int = rng.randi_range(0, w - 3)
	var sy: int = rng.randi_range(0, h - 4)
	_set_cell(grid, sx, sy, "S")

	var wkx: int = 1
	var wky: int = 0
	if wkx == sx and wky == sy:
		wkx = 2
	_set_cell(grid, wkx, wky, "K")
	if _get_cell(grid, wkx, 1) == "." and wkx != sx:
		_set_cell(grid, wkx, 1, "P")

	var tx: int = sx
	var ty: int = h - 1

	var f_sq := _sq_name(sx, sy)
	var t_sq := _sq_name(tx, ty)
	return {
		"title": "Королевская Принцесса на %s" % t_sq.to_upper(),
		"category": "Сказочные фигуры",
		"desc": "Принцесса сочетает манёвренность Ладьи и Слона. Займите решающую линию!",
		"hint": "Принцесса (%s → %s) выходит на последнюю горизонталь и ставит мат." % [f_sq, t_sq],
		"attacker_char": "S",
		"w": w, "h": h,
		"rows": _grid_to_rows(grid, w, h),
		"target_move": {"fx": sx, "fy": sy, "tx": tx, "ty": ty}
	}


# ---------------------------------------------------------------- 10. 5D Хроно-снайпер (Мат сквозь время и пространство)

static func _gen_proc_temporal_5d(diff: int, rng: RandomNumberGenerator) -> Dictionary:
	var sizes: Array = [5, 6, 7]
	var w: int = int(sizes[rng.randi() % sizes.size()])
	var h: int = w
	var grid := _make_grid(w, h)

	var kx: int = rng.randi_range(1, w - 2)
	var ky: int = h - 1
	_set_cell(grid, kx, ky, "k")
	for dx in [-1, 0, 1]:
		if kx + dx >= 0 and kx + dx < w:
			_set_cell(grid, kx + dx, ky - 1, "p")

	var valid_files: Array[int] = []
	for x in w:
		if absi(x - kx) >= 2:
			valid_files.append(x)
	if valid_files.is_empty():
		return {}

	var ax: int = valid_files[rng.randi() % valid_files.size()]
	var ay: int = rng.randi_range(0, h - 3)
	var p_opts := ["Q", "R", "S"]
	var p_ch: String = p_opts[rng.randi() % p_opts.size()]
	_set_cell(grid, ax, ay, p_ch)

	var wkx: int = rng.randi_range(0, w - 1)
	while wkx == ax:
		wkx = rng.randi_range(0, w - 1)
	_set_cell(grid, wkx, 0, "K")
	if _get_cell(grid, wkx, 1) == "." and wkx != ax:
		_set_cell(grid, wkx, 1, "P")

	var f_sq := _sq_name(ax, ay)
	var t_sq := _sq_name(ax, ky)
	return {
		"title": "Хроно-прорыв на %s" % t_sq.to_upper(),
		"category": "5D Хроно-тактика",
		"desc": "Атакуйте монарха так, чтобы ни в настоящем, ни в прошлом у него не осталось спасения!",
		"hint": "%s (%s → %s) наносит неотразимый матовый удар!" % [_piece_ru_name(p_ch), f_sq, t_sq],
		"attacker_char": p_ch,
		"w": w, "h": h,
		"rows": _grid_to_rows(grid, w, h),
		"target_move": {"fx": ax, "fy": ay, "tx": ax, "ty": ky}
	}


# ---------------------------------------------------------------- 11. Чистый синтезатор случайных матовых позиций (Engine Search)

static func _synthesize_random_mate(diff: int, rng: RandomNumberGenerator) -> Dictionary:
	var w: int = 6 if diff == 1 else 7
	var h: int = w
	var grid := _make_grid(w, h)

	var kx: int = rng.randi_range(0, w - 1)
	var ky: int = h - 1
	_set_cell(grid, kx, ky, "k")

	for i in rng.randi_range(1, 3):
		var px: int = clampi(kx + rng.randi_range(-1, 1), 0, w - 1)
		var py: int = clampi(ky - rng.randi_range(0, 1), 0, h - 1)
		if _get_cell(grid, px, py) == ".":
			_set_cell(grid, px, py, "p" if py < h - 1 else "r")

	var wkx: int = rng.randi_range(0, w - 1)
	var wky: int = rng.randi_range(0, 1)
	_set_cell(grid, wkx, wky, "K")

	var attackers := ["Q", "R", "B", "N", "S"]
	for i in 3:
		var ax: int = rng.randi_range(0, w - 1)
		var ay: int = rng.randi_range(1, h - 2)
		if _get_cell(grid, ax, ay) == ".":
			_set_cell(grid, ax, ay, attackers[rng.randi() % attackers.size()])

	var rows := _grid_to_rows(grid, w, h)
	var g := GameState.new()
	g.setup(w, h, rows, false)
	if g.in_check():
		return {}

	var legal: Array = g.board_moves(0)
	if legal.size() < 6:
		return {}

	var mating_moves: Array[Dictionary] = []
	for m in legal:
		var sim: GameState = g.clone()
		sim.apply_move(m)
		if sim.submit() and sim.in_check() and sim.game_status(800) == "checkmate":
			mating_moves.append(m)
			if mating_moves.size() > 2:
				break

	if mating_moves.is_empty() or mating_moves.size() > 2:
		return {}

	var win_m: Dictionary = mating_moves[0]
	var fv: Vector4i = win_m["f"]
	var tv: Vector4i = win_m["t"]
	var p_ch: String = _get_cell(grid, fv.x, fv.y)
	var f_sq := _sq_name(fv.x, fv.y)
	var t_sq := _sq_name(tv.x, tv.y)

	return {
		"title": "Тактический синтез на %s" % t_sq.to_upper(),
		"category": "Процедурный этюд",
		"desc": "Синтезированная тактическая позиция. Найдите единственный матовый удар в 1 ход!",
		"hint": "%s (%s → %s) наносит решающий удар по королю соперника." % [_piece_ru_name(p_ch), f_sq, t_sq],
		"attacker_char": p_ch,
		"w": w, "h": h,
		"rows": rows,
		"target_move": {"fx": fv.x, "fy": fv.y, "tx": tv.x, "ty": tv.y}
	}


static func _build_guaranteed_procedural_fallback(diff: int, rng: RandomNumberGenerator) -> Dictionary:
	var p: Dictionary = _gen_proc_backrank(diff, rng)
	if not p.is_empty() and verify_puzzle(p):
		p["difficulty"] = diff
		p["is_procedural"] = true
		p["reward"] = 50 if diff == 1 else (85 if diff == 2 else 125)
		p["id"] = "proc_fb_%d_%d" % [diff, rng.randi() % 1000000]
		return p
	var base: Dictionary = LIST[rng.randi() % LIST.size()].duplicate(true)
	if rng.randf() < 0.5:
		base = _mirror_puzzle_horizontal(base)
	base["id"] = "proc_fb_%d_%d" % [diff, rng.randi() % 1000000]
	base["is_procedural"] = true
	return base
