class_name GameState
extends RefCounted
## Движок правил шахмат с путешествиями во времени и по мультивселенной.
##
## Координаты клетки — Vector4i(x, y, t, l):
##   x, y — клетка на доске (y = 0 — первая горизонталь белых);
##   t    — номер полухода (чётный — на этой доске ходят белые, нечётный — чёрные);
##   l    — номер временной линии (0 — основная, > 0 создают белые, < 0 — чёрные).
##
## Направления движения — Vector4i(dx, dy, dt, dl), где dt измеряется в полных ходах
## (один шаг по оси T = 2 полухода, чтобы цвет хода на доске-цели совпадал).

const EMPTY := 0
const PAWN := 1
const KNIGHT := 2
const BISHOP := 3
const ROOK := 4
const QUEEN := 5
const KING := 6
const UNICORN := 7
const DRAGON := 8
const PRINCESS := 9

const TYPE_MASK := 0x0F
const BLACK_BIT := 0x10
const UNMOVED := 0x20

const WHITE := 0
const BLACK := 1

const PIECE_LETTERS := ".pnbrqkuds"
const VALUES := [0.0, 1.0, 3.0, 3.2, 5.0, 9.0, 0.0, 4.0, 5.0, 7.5]
const KING_VALUE := 1000.0
const NAMES_RU := {
	PAWN: "пешка",
	KNIGHT: "конь",
	BISHOP: "слон",
	ROOK: "ладья",
	QUEEN: "ферзь",
	KING: "король",
	UNICORN: "единорог",
	DRAGON: "дракон",
	PRINCESS: "принцесса"
}

static var DIRS: Array = []        # DIRS[n] — направления ровно с n ненулевыми осями
static var ALL_DIRS: Array = []
static var KNIGHT_DIRS: Array = []


static func _static_init() -> void:
	DIRS = [[], [], [], [], []]
	ALL_DIRS = []
	KNIGHT_DIRS = []
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			for dt in range(-1, 2):
				for dl in range(-1, 2):
					var n: int = absi(dx) + absi(dy) + absi(dt) + absi(dl)
					if n == 0:
						continue
					var d := Vector4i(dx, dy, dt, dl)
					DIRS[n].append(d)
					ALL_DIRS.append(d)
	for a in 4:
		for b in 4:
			if a == b:
				continue
			for sa in [-2, 2]:
				for sb in [-1, 1]:
					var coords := [0, 0, 0, 0]
					coords[a] = sa
					coords[b] = sb
					KNIGHT_DIRS.append(Vector4i(coords[0], coords[1], coords[2], coords[3]))


var w: int = 8
var h: int = 8
## l -> {"s": стартовый полуход, "b": Array[PackedByteArray], "p": родительская линия}
var timelines: Dictionary = {}
var min_l: int = 0
var max_l: int = 0
var turn: int = WHITE
var turn_moves: Array = []
var history: Array = []
var _undo: Array = []


# ---------------------------------------------------------------- настройка

func setup(width: int, height: int, rows: Array, turn_zero: bool = false) -> void:
	w = width
	h = height
	var b := PackedByteArray()
	b.resize(w * h)
	b.fill(EMPTY)
	for r in rows.size():
		var row: String = rows[r].replace(" ", "")
		var y: int = h - 1 - r
		for x in mini(row.length(), w):
			b[y * w + x] = char_to_piece(row[x])
	timelines = {}
	if turn_zero:
		timelines[0] = {"s": -2, "b": [b, b.duplicate(), b.duplicate()], "p": 0}
	else:
		timelines[0] = {"s": 0, "b": [b], "p": 0}
	min_l = 0
	max_l = 0
	turn = WHITE
	turn_moves = []
	history = []
	_undo = []


func clone() -> GameState:
	var g := GameState.new()
	g.w = w
	g.h = h
	g.timelines = _dup_timelines()
	g.min_l = min_l
	g.max_l = max_l
	g.turn = turn
	g.turn_moves = turn_moves.duplicate()
	g.history = history.duplicate()
	return g


func _dup_timelines() -> Dictionary:
	var d: Dictionary = {}
	for l in timelines:
		var tl: Dictionary = timelines[l]
		var bs: Array = tl["b"]
		d[l] = {"s": tl["s"], "b": bs.duplicate(), "p": tl.get("p", 0)}
	return d


static func char_to_piece(ch: String) -> int:
	var lower: String = ch.to_lower()
	var t: int = PIECE_LETTERS.find(lower)
	if t <= 0:
		return EMPTY
	var p: int = t
	if ch == lower:
		p |= BLACK_BIT
	if t == PAWN or t == KING or t == ROOK:
		p |= UNMOVED
	return p


static func piece_type(p: int) -> int:
	return p & TYPE_MASK


static func piece_color(p: int) -> int:
	return (p >> 4) & 1


# ---------------------------------------------------------------- доски и линии

func timeline_ids() -> Array:
	var k: Array = timelines.keys()
	k.sort()
	return k


func start_t(l: int) -> int:
	return int(timelines[l]["s"])


func end_t(l: int) -> int:
	var tl: Dictionary = timelines[l]
	var bs: Array = tl["b"]
	return int(tl["s"]) + bs.size() - 1


func get_board(l: int, t: int) -> PackedByteArray:
	if not timelines.has(l):
		return PackedByteArray()
	var tl: Dictionary = timelines[l]
	var bs: Array = tl["b"]
	var i: int = t - int(tl["s"])
	if i < 0 or i >= bs.size():
		return PackedByteArray()
	return bs[i]


func has_board(l: int, t: int) -> bool:
	return not get_board(l, t).is_empty()


func end_board(l: int) -> PackedByteArray:
	return get_board(l, end_t(l))


func piece_at(v: Vector4i) -> int:
	return maxi(_sq(v), 0)


## Линия активна, если создатель опережает соперника по числу линий не больше чем на одну.
func is_active(l: int) -> bool:
	if l == 0:
		return true
	if l > 0:
		return l <= (-min_l) + 1
	return -l <= max_l + 1


## «Настоящее» — самый ранний конец среди активных линий.
func present() -> int:
	var p: int = 1 << 30
	for l in timelines:
		if is_active(l):
			p = mini(p, end_t(l))
	return p


func turn_number() -> int:
	return floori(present() / 2.0) + 1


## Доски, на которых текущий игрок обязан сходить.
func mandatory_timelines() -> Array:
	var res: Array = []
	var p: int = present()
	if posmod(p, 2) != turn:
		return res
	for l in timeline_ids():
		if is_active(l) and end_t(l) == p:
			res.append(l)
	return res


## Все доски, на которых текущий игрок может сходить (только активные линии).
func playable_timelines() -> Array:
	var res: Array = []
	for l in timeline_ids():
		if is_active(l) and posmod(end_t(l), 2) == turn:
			res.append(l)
	return res


func is_playable_board(l: int, t: int) -> bool:
	return timelines.has(l) and is_active(l) and t == end_t(l) and posmod(t, 2) == turn


func is_mandatory_board(l: int, t: int) -> bool:
	return is_playable_board(l, t) and t == present()


func can_select(v: Vector4i) -> bool:
	if not is_playable_board(v.w, v.z):
		return false
	var p: int = _sq(v)
	return p > 0 and piece_color(p) == turn


# ---------------------------------------------------------------- генерация ходов

func moves_from(v: Vector4i) -> Array:
	var res: Array = []
	if not can_select(v):
		return res
	for q in _gen(v, false, false):
		res.append({"f": v, "t": q})
	return res


func board_moves(l: int) -> Array:
	var res: Array = []
	var t: int = end_t(l)
	if posmod(t, 2) != turn:
		return res
	var b: PackedByteArray = get_board(l, t)
	var high_priority: Array = []
	var normal: Array = []
	for i in b.size():
		var p: int = b[i]
		if p != EMPTY and piece_color(p) == turn:
			var from := Vector4i(i % w, i / w, t, l)
			var is_king: bool = (piece_type(p) == KING)
			for q in _gen(from, false, false):
				var m := {"f": from, "t": q}
				if is_king or _sq(q) != EMPTY:
					high_priority.append(m)
				else:
					normal.append(m)
	high_priority.append_array(normal)
	return high_priority


func _sq(v: Vector4i) -> int:
	if v.x < 0 or v.y < 0 or v.x >= w or v.y >= h or v.w < min_l or v.w > max_l:
		return -1
	if not timelines.has(v.w) or not is_active(v.w):
		return -1
	var tl: Dictionary = timelines[v.w]
	var bs: Array = tl["b"]
	var i: int = v.z - int(tl["s"])
	if i < 0 or i >= bs.size():
		return -1
	var b: PackedByteArray = bs[i]
	return b[v.y * w + v.x]


func get_piece(l: int, t: int, x: int, y: int) -> int:
	return _sq(Vector4i(x, y, t, l))


static func _offset(pos: Vector4i, d: Vector4i, k: int) -> Vector4i:
	return Vector4i(pos.x + d.x * k, pos.y + d.y * k, pos.z + d.z * 2 * k, pos.w + d.w * k)


## attack = только взятия (без рокировки и тихих ходов пешки);
## planar = только в пределах одной доски.
func _gen(pos: Vector4i, attack: bool, planar: bool) -> Array:
	var out: Array = []
	var p: int = _sq(pos)
	if p <= 0:
		return out
	var c: int = piece_color(p)
	match p & TYPE_MASK:
		PAWN:
			_gen_pawn(pos, p, c, attack, planar, out)
		KNIGHT:
			_leap(pos, KNIGHT_DIRS, c, planar, out)
		BISHOP:
			_slide(pos, DIRS[2], c, planar, out)
		ROOK:
			_slide(pos, DIRS[1], c, planar, out)
		QUEEN:
			_slide(pos, DIRS[1], c, planar, out)
			_slide(pos, DIRS[2], c, planar, out)
		KING:
			_leap(pos, DIRS[1], c, planar, out)
			_leap(pos, DIRS[2], c, planar, out)
			if not attack:
				_gen_castle(pos, p, c, out)
		UNICORN:
			_slide(pos, DIRS[3], c, planar, out)
		DRAGON:
			_slide(pos, DIRS[4], c, planar, out)
		PRINCESS:
			_slide(pos, DIRS[1], c, planar, out)
			_slide(pos, DIRS[2], c, planar, out)
	return out


func _slide(pos: Vector4i, dirs: Array, c: int, planar: bool, out: Array) -> void:
	for d in dirs:
		if planar and (d.z != 0 or d.w != 0):
			continue
		var k: int = 1
		while true:
			var q: Vector4i = _offset(pos, d, k)
			var s: int = _sq(q)
			if s < 0:
				break
			if s == EMPTY:
				out.append(q)
			else:
				if piece_color(s) != c:
					out.append(q)
				break
			k += 1


func _leap(pos: Vector4i, dirs: Array, c: int, planar: bool, out: Array) -> void:
	for d in dirs:
		if planar and (d.z != 0 or d.w != 0):
			continue
		var q: Vector4i = _offset(pos, d, 1)
		var s: int = _sq(q)
		if s == EMPTY or (s > 0 and piece_color(s) != c):
			out.append(q)


func _gen_pawn(pos: Vector4i, p: int, c: int, attack: bool, planar: bool, out: Array) -> void:
	var fy: int = 1 if c == WHITE else -1
	var fl: int = -1 if c == WHITE else 1
	if not attack:
		var one := Vector4i(pos.x, pos.y + fy, pos.z, pos.w)
		if _sq(one) == EMPTY:
			out.append(one)
			if p & UNMOVED:
				var two := Vector4i(pos.x, pos.y + 2 * fy, pos.z, pos.w)
				if _sq(two) == EMPTY:
					out.append(two)
		if not planar:
			var lone := Vector4i(pos.x, pos.y, pos.z, pos.w + fl)
			if _sq(lone) == EMPTY:
				out.append(lone)
	for dx in [-1, 1]:
		var q := Vector4i(pos.x + dx, pos.y + fy, pos.z, pos.w)
		var s: int = _sq(q)
		if s > 0 and piece_color(s) != c:
			out.append(q)
		elif s == EMPTY and not attack and _en_passant_ok(pos, dx, fy, c):
			out.append(q)
	if not planar:
		for dt in [1]:
			var q := Vector4i(pos.x, pos.y, pos.z + 2 * dt, pos.w + fl)
			var s: int = _sq(q)
			if s > 0 and piece_color(s) != c:
				out.append(q)


func _en_passant_ok(pos: Vector4i, dx: int, fy: int, c: int) -> bool:
	var side: int = _sq(Vector4i(pos.x + dx, pos.y, pos.z, pos.w))
	if side <= 0 or piece_type(side) != PAWN or piece_color(side) == c:
		return false
	var prev_origin: int = _sq(Vector4i(pos.x + dx, pos.y + 2 * fy, pos.z - 1, pos.w))
	var prev_side: int = _sq(Vector4i(pos.x + dx, pos.y, pos.z - 1, pos.w))
	var now_origin: int = _sq(Vector4i(pos.x + dx, pos.y + 2 * fy, pos.z, pos.w))
	return prev_origin > 0 and piece_type(prev_origin) == PAWN and piece_color(prev_origin) != c \
		and prev_side == EMPTY and now_origin == EMPTY


func _gen_castle(pos: Vector4i, p: int, c: int, out: Array) -> void:
	if not (p & UNMOVED):
		return
	for dir in [-1, 1]:
		var x: int = pos.x + dir
		var ok := false
		while x >= 0 and x < w:
			var s: int = _sq(Vector4i(x, pos.y, pos.z, pos.w))
			if s != EMPTY:
				ok = piece_type(s) == ROOK and (s & UNMOVED) != 0 and piece_color(s) == c
				break
			x += dir
		if not ok or absi(x - pos.x) <= 2:
			continue
		var kx: int = pos.x + 2 * dir
		var safe := true
		for step in 3:
			if _planar_attacked(pos.w, pos.z, pos.x + dir * step, pos.y, 1 - c):
				safe = false
				break
		if safe:
			out.append(Vector4i(kx, pos.y, pos.z, pos.w))


func _planar_attacked(l: int, t: int, x: int, y: int, by: int) -> bool:
	var b: PackedByteArray = get_board(l, t)
	for i in b.size():
		var p: int = b[i]
		if p == EMPTY or piece_color(p) != by:
			continue
		for q in _gen(Vector4i(i % w, i / w, t, l), true, true):
			if q.x == x and q.y == y:
				return true
	return false


# ---------------------------------------------------------------- выполнение ходов

func apply_move(m: Dictionary) -> void:
	var f: Vector4i = m["f"]
	var to: Vector4i = m["t"]
	var src: PackedByteArray = get_board(f.w, f.z).duplicate()
	var fi: int = f.y * w + f.x
	var piece: int = src[fi]
	var c: int = piece_color(piece)
	var pt: int = piece_type(piece)
	var moved: int = piece & ~UNMOVED
	if pt == PAWN and ((c == WHITE and to.y == h - 1) or (c == BLACK and to.y == 0)):
		moved = (moved & ~TYPE_MASK) | int(m.get("promo", QUEEN))
	src[fi] = EMPTY
	var rec: Dictionary = m.duplicate()
	var undo_entry: Dictionary = {
		"fw": f.w,
		"has_dst": false,
		"dst_w": 0,
		"is_new_tl": false,
		"nl": 0,
		"prev_min": min_l,
		"prev_max": max_l,
	}
	if f.w == to.w and f.z == to.z:
		var ti: int = to.y * w + to.x
		if pt == KING and absi(to.x - f.x) == 2 and to.y == f.y:
			var dir: int = signi(to.x - f.x)
			var x: int = f.x + dir
			while x >= 0 and x < w:
				var s: int = src[f.y * w + x]
				if s != EMPTY:
					src[f.y * w + x] = EMPTY
					src[f.y * w + f.x + dir] = s & ~UNMOVED
					break
				x += dir
		elif pt == PAWN and to.x != f.x and src[ti] == EMPTY:
			src[f.y * w + to.x] = EMPTY
		src[ti] = moved
		_append(f.w, src)
	else:
		_append(f.w, src)
		var dst: PackedByteArray = get_board(to.w, to.z).duplicate()
		dst[to.y * w + to.x] = moved
		if to.z == end_t(to.w):
			_append(to.w, dst)
			undo_entry["has_dst"] = true
			undo_entry["dst_w"] = to.w
		else:
			var nl: int = max_l + 1 if c == WHITE else min_l - 1
			timelines[nl] = {"s": to.z + 1, "b": [dst], "p": to.w}
			max_l = maxi(max_l, nl)
			min_l = mini(min_l, nl)
			rec["nl"] = nl
			undo_entry["is_new_tl"] = true
			undo_entry["nl"] = nl
	_undo.append(undo_entry)
	turn_moves.append(rec)


func _append(l: int, board: PackedByteArray) -> void:
	var bs: Array = timelines[l]["b"]
	bs.append(board)


func can_undo() -> bool:
	return not _undo.is_empty()


func undo_move() -> bool:
	if _undo.is_empty():
		return false
	var u: Dictionary = _undo.pop_back()
	if u["is_new_tl"]:
		timelines.erase(u["nl"])
		min_l = int(u["prev_min"])
		max_l = int(u["prev_max"])
	elif u["has_dst"]:
		timelines[int(u["dst_w"])]["b"].pop_back()
	timelines[int(u["fw"])]["b"].pop_back()
	turn_moves.pop_back()
	return true


func reset_turn() -> void:
	while undo_move():
		pass


## Пустая строка — ход можно завершить, иначе текст причины.
func submit_error() -> String:
	if turn_moves.is_empty() or posmod(present(), 2) == turn:
		return "Сделайте ход на всех досках настоящего (жёлтая рамка)"
	if is_king_capturable(1 - turn):
		return "Нельзя: ваш король окажется под ударом"
	return ""


func submit() -> bool:
	if submit_error() != "":
		return false
	history.append(turn_moves.duplicate())
	turn_moves = []
	_undo = []
	turn = 1 - turn
	return true


# ---------------------------------------------------------------- шах и мат

## Может ли игрок `by` своим следующим ходом взять какого-нибудь короля соперника.
func is_king_capturable(by: int) -> bool:
	return not _scan_king_attacks(by, true).is_empty()


## Все угрозы королям: массив пар [откуда, куда] (только между активными линиями).
func king_attacks(by: int) -> Array:
	return _scan_king_attacks(by, false)


## Перебирает фигуры игрока `by` на его играбельных досках и ищет атаки на королей
## соперника. first_only — вернуть результат сразу после первой найденной угрозы.
func _scan_king_attacks(by: int, first_only: bool) -> Array:
	var res: Array = []
	var kings: Array = _find_kings(1 - by)
	if kings.is_empty():
		return res
	for l in timelines:
		if not is_active(l):
			continue
		var t: int = end_t(l)
		if posmod(t, 2) != by:
			continue
		var b: PackedByteArray = get_board(l, t)
		for i in b.size():
			var p: int = b[i]
			if p == EMPTY or piece_color(p) != by:
				continue
			var from := Vector4i(i % w, i / w, t, l)
			for k in kings:
				if _can_attack(from, k, p):
					res.append([from, k])
					if first_only:
						return res
	return res


func _find_kings(c: int) -> Array:
	var res: Array = []
	var target_piece: int = KING | (BLACK_BIT if c == BLACK else 0)
	for l in timelines:
		if not is_active(l):
			continue
		var tl: Dictionary = timelines[l]
		var bs: Array = tl["b"]
		var s: int = int(tl["s"])
		for bi in bs.size():
			var b: PackedByteArray = bs[bi]
			for idx in b.size():
				if (b[idx] & (TYPE_MASK | BLACK_BIT)) == target_piece:
					res.append(Vector4i(idx % w, idx / w, s + bi, l))
	return res


## Быстрая геометрическая проверка: может ли фигура `piece` с клетки `from` взять `target`.
func _can_attack(from: Vector4i, target: Vector4i, piece: int) -> bool:
	var dz: int = target.z - from.z
	if dz % 2 != 0:
		return false
	var dx: int = target.x - from.x
	var dy: int = target.y - from.y
	var dt: int = dz / 2
	var dl: int = target.w - from.w
	var adx: int = absi(dx)
	var ady: int = absi(dy)
	var adt: int = absi(dt)
	var adl: int = absi(dl)
	var k: int = maxi(maxi(adx, ady), maxi(adt, adl))
	if k == 0:
		return false
	# axes — число задействованных осей; straight — все ненулевые смещения равны k
	# (то есть цель лежит на прямом луче, по которому скользят дальнобойные фигуры).
	var axes: int = 0
	var straight := true
	for a in [adx, ady, adt, adl]:
		if a != 0:
			axes += 1
			if a != k:
				straight = false
	var c: int = piece_color(piece)

	match piece & TYPE_MASK:
		PAWN:
			if dt == 0 and dl == 0:
				return adx == 1 and dy == (1 if c == WHITE else -1)
			return dx == 0 and dy == 0 and dt == 1 and dl == (-1 if c == WHITE else 1)
		KNIGHT:
			return axes == 2 and k == 2 and adx + ady + adt + adl == 3
		KING:
			return axes <= 2 and k == 1
		ROOK:
			return axes == 1 and _is_path_clear(from, dx, dy, dt, dl, k)
		BISHOP:
			return axes == 2 and straight and _is_path_clear(from, dx, dy, dt, dl, k)
		UNICORN:
			return axes == 3 and straight and _is_path_clear(from, dx, dy, dt, dl, k)
		DRAGON:
			return axes == 4 and straight and _is_path_clear(from, dx, dy, dt, dl, k)
		QUEEN:
			return axes <= 2 and straight and _is_path_clear(from, dx, dy, dt, dl, k)
		PRINCESS:
			return axes <= 2 and straight and _is_path_clear(from, dx, dy, dt, dl, k)
	return false


func _is_path_clear(from: Vector4i, dx: int, dy: int, dt: int, dl: int, k: int) -> bool:
	if k <= 1:
		return true
	var step_x: int = dx / k
	var step_y: int = dy / k
	var step_t: int = dt / k
	var step_l: int = dl / k
	for i in range(1, k):
		var q := Vector4i(from.x + step_x * i, from.y + step_y * i, from.z + step_t * 2 * i, from.w + step_l * i)
		if _sq(q) != EMPTY:
			return false
	return true


## Ценность самой дорогой фигуры, которую `by` может взять следующим ходом.
func best_capture_value(by: int) -> float:
	if is_king_capturable(by):
		return KING_VALUE
	var best := 0.0
	for l in timelines:
		if not is_active(l):
			continue
		var t: int = end_t(l)
		if posmod(t, 2) != by:
			continue
		var b: PackedByteArray = get_board(l, t)
		for i in b.size():
			var p: int = b[i]
			if p == EMPTY or piece_color(p) != by:
				continue
			for q in _gen(Vector4i(i % w, i / w, t, l), true, false):
				var s: int = _sq(q)
				if s <= 0:
					continue
				var st: int = s & TYPE_MASK
				var v: float = VALUES[st]
				if v > best:
					best = v
	return best


## Копия позиции, где текущий игрок «пропускает» оставшиеся обязательные доски.
func pass_clone() -> GameState:
	var g: GameState = clone()
	for l in g.mandatory_timelines():
		g._append(l, g.end_board(l).duplicate())
	return g


## Угрозы королям текущего игрока, если бы он сейчас закончил ход.
func current_threats() -> Array:
	var g: GameState = pass_clone()
	var res: Array = []
	for pair in g.king_attacks(1 - turn):
		var a: Vector4i = pair[0]
		var b: Vector4i = pair[1]
		if not has_board(a.w, a.z):
			a.z -= 1
		if not has_board(b.w, b.z):
			b.z -= 1
		res.append([a, b])
	return res


func in_check() -> bool:
	return pass_clone().is_king_capturable(1 - turn)


## Поиск любого допустимого хода (набора перемещений) для текущего игрока.
## Возвращает Array (ход), null (ходов нет) или "unknown" (исчерпан лимит поиска).
func find_legal_turn(budget: int = 2000) -> Variant:
	var g: GameState = clone()
	g.turn_moves = []
	g._undo = []
	var ctx: Dictionary = {"n": 0, "budget": budget, "over": false}
	var res: Variant = g._dfs(ctx, 0)
	if res != null:
		return res
	if ctx["over"]:
		return "unknown"
	return null


func _dfs(ctx: Dictionary, extra: int) -> Variant:
	ctx["n"] = int(ctx["n"]) + 1
	if int(ctx["n"]) > int(ctx["budget"]):
		ctx["over"] = true
		return null
	var ls: Array
	if posmod(present(), 2) != turn:
		if not is_king_capturable(1 - turn):
			return turn_moves.duplicate()
		if extra >= 1:
			return null
		ls = playable_timelines()
		extra += 1
	else:
		var mand: Array = mandatory_timelines()
		if mand.is_empty():
			return null
		ls = [mand[0]]
	for l in ls:
		for m in board_moves(l):
			apply_move(m)
			var r: Variant = _dfs(ctx, extra)
			undo_move()
			if r != null:
				return r
			if ctx["over"]:
				return null
	return null


## "ongoing", "checkmate" или "stalemate" для игрока, который сейчас ходит.
func game_status(budget: int = 1500) -> String:
	var r: Variant = find_legal_turn(budget)
	if r is Array:
		return "ongoing"
	if r == null:
		return "checkmate" if in_check() else "stalemate"
	# Если бюджет поиска исчерпан (r == "unknown"):
	# Если игрок под шахом и за весь лимит ни одного разрешённого хода не найдено — объявляем мат,
	# чтобы игра не зависала в тупике.
	if in_check():
		return "checkmate"
	return "ongoing"


## Возвращает детальную информацию о матовой ситуации: доска, координаты короля и атакующей фигуры.
func get_checkmate_details() -> Dictionary:
	var threats := current_threats()
	var mated_player := turn
	var winning_player := 1 - turn

	var king_pos := Vector4i(-1, -1, -1, -1)
	var attacker_pos := Vector4i(-1, -1, -1, -1)

	if not threats.is_empty():
		attacker_pos = threats[0][0]
		king_pos = threats[0][1]
	else:
		var kings := _find_kings(mated_player)
		if not kings.is_empty():
			king_pos = kings[0]

	var col_names := ["a", "b", "c", "d", "e", "f", "g", "h"]
	var k_sq_name := ""
	if king_pos.x >= 0 and king_pos.x < col_names.size():
		k_sq_name = "%s%d" % [col_names[king_pos.x], king_pos.y + 1]
	elif king_pos.x != -1:
		k_sq_name = "(%d, %d)" % [king_pos.x, king_pos.y]

	var a_sq_name := ""
	if attacker_pos.x >= 0 and attacker_pos.x < col_names.size():
		a_sq_name = "%s%d" % [col_names[attacker_pos.x], attacker_pos.y + 1]
	elif attacker_pos.x != -1:
		a_sq_name = "(%d, %d)" % [attacker_pos.x, attacker_pos.y]

	var board_l: int = king_pos.w if king_pos.w != -1 else 0
	var board_t: int = king_pos.z if king_pos.z != -1 else 0

	return {
		"has_mate": (king_pos.x != -1),
		"king": king_pos,
		"attacker": attacker_pos,
		"board_l": board_l,
		"board_t": board_t,
		"king_sq": k_sq_name,
		"attacker_sq": a_sq_name,
		"threats": threats,
		"winner": winning_player,
		"loser": mated_player
	}


# ---------------------------------------------------------------- сериализация

static func move_to_array(m: Dictionary) -> Array:
	var f: Vector4i = m["f"]
	var t: Vector4i = m["t"]
	return [f.x, f.y, f.z, f.w, t.x, t.y, t.z, t.w, int(m.get("promo", QUEEN))]


static func move_from_array(a: Array) -> Dictionary:
	return {
		"f": Vector4i(int(a[0]), int(a[1]), int(a[2]), int(a[3])),
		"t": Vector4i(int(a[4]), int(a[5]), int(a[6]), int(a[7])),
		"promo": int(a[8]) if a.size() > 8 else QUEEN,
	}
