class_name Variants
extends RefCounted
## Стартовые позиции. Строки задаются сверху вниз (первая — сторона чёрных).
## Буквы: p пешка, n конь, b слон, r ладья, q ферзь, k король,
## u единорог, d дракон, s принцесса. Заглавные — белые.

const LIST := [
	{
		"id": "standard", "name": "Классика", "w": 8, "h": 8,
		"desc": "Обычная расстановка 8×8.",
		"rows": ["rnbqkbnr", "pppppppp", "........", "........", "........", "........", "PPPPPPPP", "RNBQKBNR"],
	},
	{
		"id": "turn_zero", "name": "Ход ноль", "w": 8, "h": 8,
		"desc": "Классика, но у чёрных есть доска «нулевого хода» — в неё можно вернуться.",
		"rows": ["rnbqkbnr", "pppppppp", "........", "........", "........", "........", "PPPPPPPP", "RNBQKBNR"],
		"turn_zero": true,
	},
	{
		"id": "princess", "name": "Принцессы", "w": 8, "h": 8,
		"desc": "Ферзи заменены принцессами (ладья + слон без диагоналей во времени).",
		"rows": ["rnbskbnr", "pppppppp", "........", "........", "........", "........", "PPPPPPPP", "RNBSKBNR"],
	},
	{
		"id": "exotic", "name": "Единороги и драконы", "w": 8, "h": 8,
		"desc": "Слоны и кони заменены фигурами, которые двигаются по 3 и 4 осям сразу.",
		"rows": ["rduqkudr", "pppppppp", "........", "........", "........", "........", "PPPPPPPP", "RDUQKUDR"],
	},
	{
		"id": "mini6", "name": "Малая 6×6", "w": 6, "h": 6,
		"desc": "Компактная доска без слонов — быстрые партии.",
		"rows": ["rnqknr", "pppppp", "......", "......", "PPPPPP", "RNQKNR"],
	},
	{
		"id": "mini5", "name": "Мини 5×5", "w": 5, "h": 5,
		"desc": "Самая маленькая доска. Отлично подходит для изучения механики.",
		"rows": ["kqbnr", "ppppp", ".....", "PPPPP", "KQBNR"],
	},
	{
		"id": "kings", "name": "Короли и пешки", "w": 8, "h": 8,
		"desc": "Тренировка: только короли, ладьи и пешки.",
		"rows": ["r...k..r", "pppppppp", "........", "........", "........", "........", "PPPPPPPP", "R...K..R"],
	},
]


static func by_id(id: String) -> Dictionary:
	for v in LIST:
		if v["id"] == id:
			return v
	return LIST[0]


static func create(id: String) -> GameState:
	var v: Dictionary = by_id(id)
	var g := GameState.new()
	g.setup(int(v["w"]), int(v["h"]), v["rows"], bool(v.get("turn_zero", false)))
	return g
