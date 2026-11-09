class_name Puzzles
extends RefCounted
## Каталог тактических головоломок и задач по 5D и классическим шахматам.

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
		"id": "puz_temporal_jump",
		"title": "Хроно-удар: Прорыв по вертикали",
		"category": "5D Хроно-тактика",
		"difficulty": 3,
		"reward": 120,
		"desc": "Вражеский монарх заблокирован собственными пешками. Нанесите сокрушительный удар по вертикали!",
		"hint": "Ладья a1 может ворваться на 5-ю горизонталь (поле a5), объявляя линейный мат монарху.",
		"w": 5, "h": 5,
		"rows": [
			"..k..",
			".ppp.",
			".....",
			".....",
			"R..K."
		],
		"target_move": {"fx": 0, "fy": 0, "tx": 0, "ty": 4}
	},
	{
		"id": "puz_princess_rush",
		"title": "Стремительная Принцесса",
		"category": "Сказочные фигуры",
		"difficulty": 2,
		"reward": 85,
		"desc": "Принцесса объединяет силу Ладьи и Слона. Отрежьте короля по линии!",
		"hint": "Принцесса с a1 может ворваться на 6-ю горизонталь (поле a6), отрезая короля по всей линии.",
		"w": 6, "h": 6,
		"rows": [
			".....k",
			"....pp",
			"...K..",
			"......",
			"......",
			"S....."
		],
		"target_move": {"fx": 0, "fy": 0, "tx": 0, "ty": 5}
	}
]


static func get_puzzle_by_id(p_id: String) -> Dictionary:
	for p in LIST:
		if p["id"] == p_id:
			return p
	return LIST[0]


## Проверяет, верно ли решена задача (либо поставлен мат, либо ход совпадает с целевым).
static func check_puzzle_success(puz: Dictionary, played_moves: Array, state: GameState) -> bool:
	if played_moves.is_empty():
		return false

	var m: Dictionary = played_moves[0]
	var f: Vector4i = m.get("f", Vector4i.ZERO)
	var t: Vector4i = m.get("t", Vector4i.ZERO)
	var fx: int = f.x
	var fy: int = f.y
	var tx: int = t.x
	var ty: int = t.y

	var tgt: Dictionary = puz.get("target_move", {})
	if not tgt.is_empty():
		var match_xy: bool = (fx == int(tgt.get("fx", -1)) and fy == int(tgt.get("fy", -1)) and tx == int(tgt.get("tx", -1)) and ty == int(tgt.get("ty", -1)))
		var match_time: bool = true
		if tgt.has("fz"):
			match_time = match_time and (f.z == int(tgt["fz"]))
		if tgt.has("tz"):
			match_time = match_time and (t.z == int(tgt["tz"]))
		if match_xy and match_time:
			return true

	# Если ход поставил сопернику шах и мат
	if state.in_check() and state.game_status(1000) == "checkmate":
		return true

	return false


# ---------------------------------------------------------------- ПРОЦЕДУРНЫЙ ГЕНЕРАТОР ЗАДАЧ

## Генерирует новую процедурную шахматную задачу с гарантированным решением (мат в 1 ход).
static func generate_procedural_puzzle(difficulty: int = 1) -> Dictionary:
	difficulty = clampi(difficulty, 1, 3)
	var attempts: int = 0
	var max_attempts: int = 30

	while attempts < max_attempts:
		attempts += 1
		var candidate: Dictionary = {}
		var r_type: int = randi() % 100

		if difficulty == 1:
			if r_type < 45:
				candidate = _gen_backrank(1)
			elif r_type < 75:
				candidate = _gen_ladder_box(1)
			else:
				candidate = _gen_battery(1)
		elif difficulty == 2:
			if r_type < 35:
				candidate = _gen_smothered(2)
			elif r_type < 60:
				candidate = _gen_backrank(2)
			elif r_type < 80:
				candidate = _gen_battery(2)
			else:
				candidate = _gen_fairy(2)
		else: # difficulty == 3
			if r_type < 35:
				candidate = _gen_fairy(3)
			elif r_type < 65:
				candidate = _gen_smothered(3)
			elif r_type < 85:
				candidate = _gen_backrank(3)
			else:
				candidate = _gen_ladder_box(3)

		candidate["difficulty"] = difficulty
		candidate["is_procedural"] = true
		var base_rew: int = 50 if difficulty == 1 else (80 if difficulty == 2 else 120)
		var jitter: int = randi_range(-10, 15)
		candidate["reward"] = maxi(30, base_rew + jitter)
		var uid: String = "proc_%d_%d_%d" % [difficulty, Time.get_ticks_msec(), randi() % 100000]
		candidate["id"] = uid

		if verify_puzzle(candidate):
			return candidate

	# Запасной проверенный шаблон, если за 30 попыток генератор не сошёлся
	return _make_fallback_puzzle(difficulty)


## Полная верификация сгенерированной задачи через игровой движок GameState.
static func verify_puzzle(puz: Dictionary) -> bool:
	var g := GameState.new()
	var w: int = int(puz.get("w", 8))
	var h: int = int(puz.get("h", 8))
	var rows: Array = puz.get("rows", [])
	if rows.size() != h:
		return false
	g.setup(w, h, rows)

	# 1. Белые не должны начинать под шахом
	if g.in_check():
		return false

	var tgt: Dictionary = puz.get("target_move", {})
	if tgt.is_empty():
		return false
	var fx: int = int(tgt.get("fx", -1))
	var fy: int = int(tgt.get("fy", -1))
	var tx: int = int(tgt.get("tx", -1))
	var ty: int = int(tgt.get("ty", -1))

	var piece: int = g.get_piece(0, 0, fx, fy)
	if piece == GameState.EMPTY or GameState.piece_color(piece) != GameState.WHITE:
		return false

	var m := {
		"f": Vector4i(fx, fy, 0, 0),
		"t": Vector4i(tx, ty, 0, 0),
		"p": piece
	}

	# 2. Проверяем, разрешён ли целевой ход
	var legal: Array = g.board_moves(0)
	var found_legal: bool = false
	for lm in legal:
		if lm["f"] == m["f"] and lm["t"] == m["t"]:
			found_legal = true
			m = lm
			break
	if not found_legal:
		return false

	# 3. Делаем ход и подтверждаем
	g.apply_move(m)
	if not g.submit():
		return false

	# 4. Чёрным должен быть объявлен шах
	if not g.in_check():
		return false

	# 5. Состояние партии должно быть мат (checkmate)
	var status: String = g.game_status(600)
	return status == "checkmate"


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


static func _gen_backrank(diff: int) -> Dictionary:
	var w: int = 8
	var h: int = 8
	var grid := _make_grid(w, h)
	var puz_num: int = randi() % 900 + 100

	var is_kingside: bool = (randi() % 2 == 0)
	var kx: int = 6 if is_kingside else 1
	_set_cell(grid, kx, h - 1, "k")

	if is_kingside:
		# Чёрный король на g8 (6, 7), пешки на f7 (5, 6), g7 (6, 6), h7 (7, 6)
		_set_cell(grid, 5, h - 2, "p")
		_set_cell(grid, 6, h - 2, "p")
		_set_cell(grid, 7, h - 2, "p")
		if diff >= 2:
			_set_cell(grid, 7, h - 1, "r")
		# Белый король на g1 (6, 0), пешки на f2 (5, 1), g2 (6, 1), h2 (7, 1)
		_set_cell(grid, 6, 0, "K")
		_set_cell(grid, 5, 1, "P")
		_set_cell(grid, 6, 1, "P")
		_set_cell(grid, 7, 1, "P")
	else:
		# Чёрный король на b8 (1, 7), пешки на a7 (0, 6), b7 (1, 6), c7 (2, 6)
		_set_cell(grid, 0, h - 2, "p")
		_set_cell(grid, 1, h - 2, "p")
		_set_cell(grid, 2, h - 2, "p")
		if diff >= 2:
			_set_cell(grid, 0, h - 1, "r")
		# Белый король на b1 (1, 0), пешки на a2 (0, 1), b2 (1, 1), c2 (2, 1)
		_set_cell(grid, 1, 0, "K")
		_set_cell(grid, 0, 1, "P")
		_set_cell(grid, 1, 1, "P")
		_set_cell(grid, 2, 1, "P")

	# Открытая вертикаль для атаки
	var ax: int = (randi() % 4) if is_kingside else (4 + (randi() % 4))
	var ay: int = randi() % 2
	var piece_char: String = "R"
	if diff == 2 and (randi() % 2 == 0):
		piece_char = "Q"
	elif diff == 3 and (randi() % 2 == 0):
		piece_char = "S"
	_set_cell(grid, ax, ay, piece_char)

	var rows: Array[String] = _grid_to_rows(grid, w, h)
	var ax_col_name: String = String.chr(97 + ax)
	var hint: String = "Фигура с поля %s%d может подняться на 8-ю горизонталь (%s%d), объявив мат зажатому монарху." % [
		ax_col_name, ay + 1, ax_col_name, h
	]

	return {
		"title": "Мат по последней горизонтали #%d" % puz_num,
		"category": "Классическая тактика",
		"desc": "Чёрный монарх заперт своими пешками на 8-м ряду. Пробейте открытую вертикаль!",
		"hint": hint,
		"w": w, "h": h,
		"rows": rows,
		"target_move": {"fx": ax, "fy": ay, "tx": ax, "ty": h - 1}
	}


static func _gen_smothered(diff: int) -> Dictionary:
	var w: int = 8
	var h: int = 8
	var grid := _make_grid(w, h)
	var puz_num: int = randi() % 900 + 100

	var is_kingside: bool = (randi() % 2 == 0)
	var kx: int = (w - 1) if is_kingside else 0
	var rx: int = (w - 2) if is_kingside else 1
	var tx: int = (w - 3) if is_kingside else 2
	var ty: int = h - 2 # rank 6

	_set_cell(grid, kx, h - 1, "k")
	_set_cell(grid, rx, h - 1, "r")
	_set_cell(grid, kx, h - 2, "p")
	_set_cell(grid, rx, h - 2, "p")

	var knight_starts: Array = []
	if is_kingside:
		# tx = 5, ty = 6 (f7)
		knight_starts = [
			Vector2i(4, 4), # e5
			Vector2i(6, 4), # g5
			Vector2i(3, 5), # d6
			Vector2i(3, 7)  # d8
		]
		_set_cell(grid, 1, 0, "K")
		_set_cell(grid, 0, 1, "P")
		_set_cell(grid, 1, 1, "P")
		_set_cell(grid, 2, 1, "P")
	else:
		# tx = 2, ty = 6 (c7)
		knight_starts = [
			Vector2i(3, 4), # d5
			Vector2i(1, 4), # b5
			Vector2i(4, 5), # e6
			Vector2i(4, 7)  # e8
		]
		_set_cell(grid, 6, 0, "K")
		_set_cell(grid, 5, 1, "P")
		_set_cell(grid, 6, 1, "P")
		_set_cell(grid, 7, 1, "P")

	var valid_starts: Array = []
	for pos in knight_starts:
		if pos.x >= 0 and pos.x < w and pos.y >= 0 and pos.y < h:
			if _get_cell(grid, pos.x, pos.y) == ".":
				valid_starts.append(pos)

	var start_pos: Vector2i = valid_starts.pick_random() if not valid_starts.is_empty() else (Vector2i(4, 4) if is_kingside else Vector2i(3, 4))
	_set_cell(grid, start_pos.x, start_pos.y, "N")

	var rows: Array[String] = _grid_to_rows(grid, w, h)
	var t_col: String = String.chr(97 + tx)
	var hint: String = "Конь может перепрыгнуть на поле %s%d и нанести спёртый мат — король окружен и не может пошевелиться!" % [
		t_col, ty + 1
	]

	return {
		"title": "Спёртый мат конём #%d" % puz_num,
		"category": "Королевский гамбит",
		"desc": "Чёрный король заблокирован в углу своими фигурами. Нанесите завершающий спёртый удар!",
		"hint": hint,
		"w": w, "h": h,
		"rows": rows,
		"target_move": {"fx": start_pos.x, "fy": start_pos.y, "tx": tx, "ty": ty}
	}


static func _gen_ladder_box(diff: int) -> Dictionary:
	var w: int = 8
	var h: int = 8
	var grid := _make_grid(w, h)
	var puz_num: int = randi() % 900 + 100

	# Черный король в центре последнего ряда (d8 или e8)
	var kx: int = 3 if (randi() % 2 == 0) else 4
	_set_cell(grid, kx, h - 1, "k")

	# Ладья 1 на a7 (0, 6) отрезает 7-ю горизонталь
	_set_cell(grid, 0, h - 2, "R")

	# Ладья 2 на h1 (7, 0) или h2 (7, 1) завершает мат на h8
	var rx2: int = 7
	var fy: int = randi() % 2
	_set_cell(grid, rx2, fy, "R")

	# Белый король надежно защищен на c1
	_set_cell(grid, 2, 0, "K")
	_set_cell(grid, 1, 1, "P")
	_set_cell(grid, 2, 1, "P")
	_set_cell(grid, 3, 1, "P")

	var rows: Array[String] = _grid_to_rows(grid, w, h)
	var t_col: String = String.chr(97 + rx2)
	var hint: String = "Ладья поднимается на поле %s%d по свободной вертикали и завершает линейный мат." % [
		t_col, h
	]

	return {
		"title": "Линейный мат двумя ладьями #%d" % puz_num,
		"category": "Классическая тактика",
		"desc": "Первая ладья отрезает 7-ю горизонталь. Отправьте вторую ладью на добивание!",
		"hint": hint,
		"w": w, "h": h,
		"rows": rows,
		"target_move": {"fx": rx2, "fy": fy, "tx": rx2, "ty": h - 1}
	}


static func _gen_battery(diff: int) -> Dictionary:
	var w: int = 8
	var h: int = 8
	var grid := _make_grid(w, h)
	var puz_num: int = randi() % 900 + 100

	_set_cell(grid, 4, 7, "k") # e8
	_set_cell(grid, 3, 7, "q") # d8
	_set_cell(grid, 5, 7, "b") # f8
	_set_cell(grid, 0, 6, "p") # a7
	_set_cell(grid, 1, 6, "p") # b7
	_set_cell(grid, 2, 6, "p") # c7
	_set_cell(grid, 3, 6, "p") # d7
	_set_cell(grid, 6, 6, "p") # g7
	_set_cell(grid, 7, 6, "p") # h7
	_set_cell(grid, 4, 4, "p") # e5 (e6 пусто для диагонали слона)
	_set_cell(grid, 1, 7, "n") # b8

	# Белопольный слон на c4 (2, 3) поддерживает f7 (5, 6)
	_set_cell(grid, 2, 3, "B")

	var qx: int = 7
	var qy: int = 4
	_set_cell(grid, qx, qy, "Q")

	_set_cell(grid, 4, 0, "K")
	_set_cell(grid, 0, 1, "P")
	_set_cell(grid, 1, 1, "P")
	_set_cell(grid, 2, 1, "P")
	_set_cell(grid, 3, 2, "P")
	_set_cell(grid, 6, 1, "P")
	_set_cell(grid, 7, 1, "P")

	var rows: Array[String] = _grid_to_rows(grid, w, h)
	var hint: String = "Ферзь при поддержке белопольного слона атакует пункт f7, король не может взять защищенного ферзя."

	return {
		"title": "Удар Ферзём: Батарея #%d" % puz_num,
		"category": "Атака на короля",
		"desc": "Слабейшее поле f7 беззащитно. Нанесите сокрушительный удар Ферзём при поддержке Слона!",
		"hint": hint,
		"w": w, "h": h,
		"rows": rows,
		"target_move": {"fx": qx, "fy": qy, "tx": 5, "ty": 6}
	}


static func _gen_fairy(diff: int) -> Dictionary:
	var w: int = 6
	var h: int = 6
	var grid := _make_grid(w, h)
	var puz_num: int = randi() % 900 + 100

	_set_cell(grid, 5, 5, "k") # f6
	_set_cell(grid, 4, 4, "p") # e5
	_set_cell(grid, 5, 4, "p") # f5

	# Принцесса объединяет Ладью и Слона
	_set_cell(grid, 0, 0, "S") # a1
	_set_cell(grid, 2, 2, "K") # c3

	var rows: Array[String] = _grid_to_rows(grid, w, h)
	var hint: String = "Принцесса объединяет свойства ладьи и слона. Ворвитесь на 6-ю горизонталь (поле a6)."

	return {
		"title": "Стремительная Принцесса #%d" % puz_num,
		"category": "Сказочные фигуры",
		"desc": "Принцесса объединяет силу Ладьи и Слона. Отрежьте короля по всей линии!",
		"hint": hint,
		"w": w, "h": h,
		"rows": rows,
		"target_move": {"fx": 0, "fy": 0, "tx": 0, "ty": 5}
	}


static func _make_fallback_puzzle(diff: int) -> Dictionary:
	var base_idx: int = clampi(diff - 1, 0, LIST.size() - 1)
	var p: Dictionary = LIST[base_idx].duplicate(true)
	p["id"] = "proc_fb_%d_%d" % [diff, randi() % 100000]
	p["is_procedural"] = true
	p["title"] = "Процедурный мат #%d" % (randi() % 900 + 100)
	var base_rew: int = 50 if diff == 1 else (80 if diff == 2 else 120)
	p["reward"] = base_rew + randi_range(-5, 10)
	return p

