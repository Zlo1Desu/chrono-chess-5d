class_name MultiChessState
extends RefCounted
## Движок мульти-шахмат без путешествий во времени (1х1х1, 2х2, 1х1х1х1).
## Поле 14×14 в форме креста с вырезами 3×3 в углах (всего 160 активных клеток).

const BOARD_SIZE := 14

# Игроки / Цвета
const WHITE := 0  # Юг (движение пешек: +Y)
const RED   := 1  # Запад (движение пешек: +X)
const BLACK := 2  # Север (движение пешек: -Y)
const BLUE  := 3  # Восток (движение пешек: -X)

const PLAYER_NAMES: Array[String] = ["Белые", "Красные", "Чёрные", "Синие"]
const PLAYER_COLORS: Array[Color] = [
	Color(0.96, 0.95, 0.90),  # Белые
	Color(0.92, 0.28, 0.28),  # Красные
	Color(0.22, 0.24, 0.30),  # Чёрные
	Color(0.28, 0.60, 0.95),  # Синие
]

# Фигуры (1..6 соответствуют GameState)
const EMPTY := 0
const PAWN := 1
const KNIGHT := 2
const BISHOP := 3
const ROOK := 4
const QUEEN := 5
const KING := 6

const PIECE_NAMES: Dictionary = {
	EMPTY: "Пусто",
	PAWN: "Пешка",
	KNIGHT: "Конь",
	BISHOP: "Слон",
	ROOK: "Ладья",
	QUEEN: "Ферзь",
	KING: "Король"
}

const PIECE_COMBAT_VALUES: Dictionary = {
	PAWN: 1,
	KNIGHT: 3,
	BISHOP: 3,
	ROOK: 5,
	QUEEN: 9,
	KING: 6  # Базовая боевая сила/защита короля
}

static func get_piece_value(ptype: int) -> int:
	return PIECE_COMBAT_VALUES.get(ptype, 1)

## Расчёт необходимого порога d20 (DC) для взятия фигуры
## Базовый порог: 10 (для равных по силе фигур шанс ~55%).
## При атаке более слабой фигуры порог снижается (до 3+).
## При атаке более сильной фигуры порог растёт (до 18+).
static func get_d20_threshold(attacker_piece: int, defender_piece: int) -> int:
	var a_type := get_piece_type(attacker_piece)
	var d_type := get_piece_type(defender_piece)
	var a_val := get_piece_value(a_type)
	var d_val := get_piece_value(d_type)
	var diff := d_val - a_val
	var threshold := 10 + diff * 2
	return clampi(threshold, 3, 18)

# Режимы
const MODE_1V1V1 := "1v1v1"       # 3 игрока (White, Red, Black), FFA
const MODE_2V2 := "2v2"           # 4 игрока, команды (0 & 2 vs 1 & 3)
const MODE_1V1V1V1 := "1v1v1v1"   # 4 игрока, FFA

# Состояние доски: размер 14x14 = 196
# В ячейке: piece_type | (player_id << 4)
var grid: PackedByteArray = PackedByteArray()
var mode: String = MODE_1V1V1V1
var turn: int = WHITE
var active_players: Array = []       # [0, 1, 2] или [0, 1, 2, 3]
var eliminated_players: Array = []   # список выбывших игроков
var move_number: int = 1
var last_move: Dictionary = {}


static func is_valid_cell(x: int, y: int) -> bool:
	if x < 0 or x >= BOARD_SIZE or y < 0 or y >= BOARD_SIZE:
		return false
	# Угловые вырезы 3х3
	if (x < 3 or x > 10) and (y < 3 or y > 10):
		return false
	return true


static func make_piece(type: int, player: int) -> int:
	if type == EMPTY:
		return EMPTY
	return (type & 0x0F) | ((player & 0x07) << 4)


static func get_piece_type(p: int) -> int:
	return p & 0x0F


static func get_piece_player(p: int) -> int:
	return (p >> 4) & 0x07


func setup(p_mode: String) -> void:
	mode = p_mode
	grid.resize(BOARD_SIZE * BOARD_SIZE)
	grid.fill(EMPTY)
	eliminated_players.clear()
	move_number = 1
	last_move = {}

	if mode == MODE_1V1V1:
		active_players = [WHITE, RED, BLACK]
	else:
		active_players = [WHITE, RED, BLACK, BLUE]

	turn = active_players[0]

	# 1. Расстановка Белых (Юг, y=0..1, x=3..10)
	_setup_south_army(WHITE)

	# 2. Расстановка Красных (Запад, x=0..1, y=3..10)
	_setup_west_army(RED)

	# 3. Расстановка Чёрных (Север, y=12..13, x=3..10)
	_setup_north_army(BLACK)

	# 4. Расстановка Синих (Восток, x=12..13, y=3..10) — только для 4 игроков
	if mode != MODE_1V1V1:
		_setup_east_army(BLUE)


func _setup_south_army(p: int) -> void:
	var back := [ROOK, KNIGHT, BISHOP, QUEEN, KING, BISHOP, KNIGHT, ROOK]
	for i in 8:
		set_cell(3 + i, 0, make_piece(back[i], p))
		set_cell(3 + i, 1, make_piece(PAWN, p))


func _setup_north_army(p: int) -> void:
	var back := [ROOK, KNIGHT, BISHOP, QUEEN, KING, BISHOP, KNIGHT, ROOK]
	for i in 8:
		set_cell(3 + i, 13, make_piece(back[i], p))
		set_cell(3 + i, 12, make_piece(PAWN, p))


func _setup_west_army(p: int) -> void:
	var back := [ROOK, KNIGHT, BISHOP, KING, QUEEN, BISHOP, KNIGHT, ROOK]
	for i in 8:
		set_cell(0, 3 + i, make_piece(back[i], p))
		set_cell(1, 3 + i, make_piece(PAWN, p))


func _setup_east_army(p: int) -> void:
	var back := [ROOK, KNIGHT, BISHOP, QUEEN, KING, BISHOP, KNIGHT, ROOK]
	for i in 8:
		set_cell(13, 3 + i, make_piece(back[i], p))
		set_cell(12, 3 + i, make_piece(PAWN, p))


func get_cell(x: int, y: int) -> int:
	if not is_valid_cell(x, y):
		return EMPTY
	return grid[y * BOARD_SIZE + x]


func set_cell(x: int, y: int, piece: int) -> void:
	if is_valid_cell(x, y):
		grid[y * BOARD_SIZE + x] = piece


func are_teammates(p1: int, p2: int) -> bool:
	if p1 == p2:
		return true
	if mode == MODE_2V2:
		return (p1 == WHITE and p2 == BLACK) or (p1 == BLACK and p2 == WHITE) \
			or (p1 == RED and p2 == BLUE) or (p1 == BLUE and p2 == RED)
	return false


# ---------------------------------------------------------------- Генерация ходов

func get_legal_moves(player: int = -1) -> Array:
	if player == -1:
		player = turn
	var moves: Array = []
	for y in BOARD_SIZE:
		for x in BOARD_SIZE:
			if not is_valid_cell(x, y):
				continue
			var p := get_cell(x, y)
			if p != EMPTY and get_piece_player(p) == player:
				_generate_piece_moves(x, y, p, moves)
	return moves


func _generate_piece_moves(x: int, y: int, piece: int, out_moves: Array) -> void:
	var p_type := get_piece_type(piece)
	var player := get_piece_player(piece)

	match p_type:
		PAWN:
			_gen_pawn_moves(x, y, player, out_moves)
		KNIGHT:
			var jumps := [
				Vector2i(1, 2), Vector2i(2, 1), Vector2i(-1, 2), Vector2i(-2, 1),
				Vector2i(1, -2), Vector2i(2, -1), Vector2i(-1, -2), Vector2i(-2, -1)
			]
			for j in jumps:
				_try_add_move(x, y, x + j.x, y + j.y, player, out_moves)
		BISHOP:
			_gen_rays(x, y, [Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)], player, out_moves)
		ROOK:
			_gen_rays(x, y, [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)], player, out_moves)
		QUEEN:
			_gen_rays(x, y, [
				Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
				Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)
			], player, out_moves)
		KING:
			for dx in range(-1, 2):
				for dy in range(-1, 2):
					if dx != 0 or dy != 0:
						_try_add_move(x, y, x + dx, y + dy, player, out_moves)


func _gen_pawn_moves(x: int, y: int, player: int, out_moves: Array) -> void:
	var fwd := Vector2i(0, 0)
	var start_coord: int = 0
	var is_y_axis := false

	match player:
		WHITE:
			fwd = Vector2i(0, 1)
			start_coord = 1
			is_y_axis = true
		RED:
			fwd = Vector2i(1, 0)
			start_coord = 1
			is_y_axis = false
		BLACK:
			fwd = Vector2i(0, -1)
			start_coord = 12
			is_y_axis = true
		BLUE:
			fwd = Vector2i(-1, 0)
			start_coord = 12
			is_y_axis = false

	# 1. Шаг вперёд
	var nx := x + fwd.x
	var ny := y + fwd.y
	if is_valid_cell(nx, ny) and get_cell(nx, ny) == EMPTY:
		out_moves.append({"fx": x, "fy": y, "tx": nx, "ty": ny})
		# Двойной шаг со стартовой линии
		var at_start: bool = (y == start_coord) if is_y_axis else (x == start_coord)
		var nnx := x + fwd.x * 2
		var nny := y + fwd.y * 2
		if at_start and is_valid_cell(nnx, nny) and get_cell(nnx, nny) == EMPTY:
			out_moves.append({"fx": x, "fy": y, "tx": nnx, "ty": nny})

	# 2. Взятия по диагонали
	var cap_dirs: Array[Vector2i] = []
	if is_y_axis:
		cap_dirs = [Vector2i(-1, fwd.y), Vector2i(1, fwd.y)]
	else:
		cap_dirs = [Vector2i(fwd.x, -1), Vector2i(fwd.x, 1)]

	for cd in cap_dirs:
		var cx := x + cd.x
		var cy := y + cd.y
		if is_valid_cell(cx, cy):
			var target := get_cell(cx, cy)
			if target != EMPTY and not are_teammates(player, get_piece_player(target)):
				out_moves.append({"fx": x, "fy": y, "tx": cx, "ty": cy})


func _gen_rays(x: int, y: int, dirs: Array, player: int, out_moves: Array) -> void:
	for d in dirs:
		var cur_x: int = x + int(d.x)
		var cur_y: int = y + int(d.y)
		while is_valid_cell(cur_x, cur_y):
			var occ := get_cell(cur_x, cur_y)
			if occ == EMPTY:
				out_moves.append({"fx": x, "fy": y, "tx": cur_x, "ty": cur_y})
			else:
				if not are_teammates(player, get_piece_player(occ)):
					out_moves.append({"fx": x, "fy": y, "tx": cur_x, "ty": cur_y})
				break
			cur_x += int(d.x)
			cur_y += int(d.y)


func _try_add_move(fx: int, fy: int, tx: int, ty: int, player: int, out_moves: Array) -> void:
	if not is_valid_cell(tx, ty):
		return
	var occ := get_cell(tx, ty)
	if occ == EMPTY or not are_teammates(player, get_piece_player(occ)):
		out_moves.append({"fx": fx, "fy": fy, "tx": tx, "ty": ty})


# ---------------------------------------------------------------- Применение хода

func apply_move(m: Dictionary, is_d20: bool = false) -> void:
	var fx: int = m["fx"]
	var fy: int = m["fy"]
	var tx: int = m["tx"]
	var ty: int = m["ty"]

	var p := get_cell(fx, fy)
	var captured := get_cell(tx, ty)

	# В режиме D20: если это атака и бросок кубика провален — защитник отбил удар
	if is_d20 and captured != EMPTY and m.has("d20_success") and not bool(m["d20_success"]):
		last_move = m
		advance_turn()
		return

	set_cell(fx, fy, EMPTY)

	# Превращение пешки при достижении 8-й линии продвижения
	var p_type := get_piece_type(p)
	var player := get_piece_player(p)
	if p_type == PAWN:
		var promoted := false
		match player:
			WHITE: promoted = (ty >= 8)
			RED:   promoted = (tx >= 8)
			BLACK: promoted = (ty <= 5)
			BLUE:  promoted = (tx <= 5)
		if promoted:
			p = make_piece(QUEEN, player)

	set_cell(tx, ty, p)
	last_move = m

	# Если срублен король — игрок выбывает!
	if captured != EMPTY and get_piece_type(captured) == KING:
		var victim := get_piece_player(captured)
		eliminate_player(victim)

	# Переход хода к следующему активному игроку
	advance_turn()


func eliminate_player(victim: int) -> void:
	if not eliminated_players.has(victim):
		eliminated_players.append(victim)
		# Превращаем оставшиеся фигуры выбывшего в нейтральные (серые) или удаляем их
		for y in BOARD_SIZE:
			for x in BOARD_SIZE:
				if is_valid_cell(x, y):
					var p := get_cell(x, y)
					if p != EMPTY and get_piece_player(p) == victim:
						set_cell(x, y, EMPTY)


func advance_turn() -> void:
	if is_game_over():
		return

	var idx := active_players.find(turn)
	for step in range(1, active_players.size() + 1):
		var next_idx := (idx + step) % active_players.size()
		var candidate: int = active_players[next_idx]
		if not eliminated_players.has(candidate):
			turn = candidate
			move_number += 1
			return


func is_game_over() -> bool:
	if mode == MODE_2V2:
		var team0_alive: bool = not (eliminated_players.has(WHITE) and eliminated_players.has(BLACK))
		var team1_alive: bool = not (eliminated_players.has(RED) and eliminated_players.has(BLUE))
		return not (team0_alive and team1_alive)
	else:
		# FFA: Игра окончена, когда остался 1 активный игрок
		var alive_count: int = 0
		for p in active_players:
			if not eliminated_players.has(p):
				alive_count += 1
		return alive_count <= 1


func get_winner_info() -> Dictionary:
	if not is_game_over():
		return {"over": false}

	if mode == MODE_2V2:
		var team0_alive: bool = not (eliminated_players.has(WHITE) and eliminated_players.has(BLACK))
		if team0_alive:
			return {"over": true, "winner_team": 0, "title": "Победа команды Белые + Чёрные!"}
		else:
			return {"over": true, "winner_team": 1, "title": "Победа команды Красные + Синие!"}
	else:
		for p in active_players:
			if not eliminated_players.has(p):
				return {"over": true, "winner_player": p, "title": "Победитель: %s!" % PLAYER_NAMES[p]}
		return {"over": true, "winner_player": -1, "title": "Ничья!"}


func count_pieces(player: int) -> int:
	var count := 0
	for y in BOARD_SIZE:
		for x in BOARD_SIZE:
			if is_valid_cell(x, y):
				var p := get_cell(x, y)
				if p != EMPTY and get_piece_player(p) == player:
					count += 1
	return count


func find_king(player: int) -> Vector2i:
	for y in BOARD_SIZE:
		for x in BOARD_SIZE:
			if is_valid_cell(x, y):
				var p := get_cell(x, y)
				if p != EMPTY and get_piece_player(p) == player and get_piece_type(p) == KING:
					return Vector2i(x, y)
	return Vector2i(-1, -1)


func is_king_threatened(player: int) -> bool:
	var kp := find_king(player)
	if kp.x == -1:
		return false
	for opp in active_players:
		if opp == player or are_teammates(opp, player) or eliminated_players.has(opp):
			continue
		var moves := get_legal_moves(opp)
		for m in moves:
			if m["tx"] == kp.x and m["ty"] == kp.y:
				return true
	return false


func clone() -> MultiChessState:
	var c := MultiChessState.new()
	c.grid = grid.duplicate()
	c.mode = mode
	c.turn = turn
	c.active_players = active_players.duplicate()
	c.eliminated_players = eliminated_players.duplicate()
	c.move_number = move_number
	c.last_move = last_move.duplicate()
	return c
