class_name Skins
extends RefCounted
## Каталог стилизованных палитр для шахматных фигур (Cel-Shaded Staunton).

const CLASSIC := "classic"
const CYBERPUNK := "cyberpunk"
const GOLD := "gold"
const EMERALD := "emerald"
const OBSIDIAN := "obsidian"
const SUPERNOVA := "supernova"

const LIST: Array[Dictionary] = [
	{
		"id": CLASSIC,
		"name": "Классический Стаунтон",
		"desc": "Тёплая слоновая кость и матовый антрацит с латунным кольцом.",
		"price": 0,
		"white_col": Color(0.98, 0.96, 0.93),
		"black_col": Color(0.45, 0.50, 0.60),
		"accent": Color(0.78, 0.62, 0.33),
		"white_palette": {
			"main": "#FAF6EE",
			"shade": "#DED4C1",
			"deep": "#BFB29B",
			"collar": "#C89D54",
			"collar_shade": "#9C7432",
			"stroke": "#1C2026",
			"highlight": "#FFFFFF",
			"eye": "#1C2026",
		},
		"black_palette": {
			"main": "#434C5E",
			"shade": "#2B303C",
			"deep": "#1D212A",
			"collar": "#D4AF37",
			"collar_shade": "#9A7B1C",
			"stroke": "#0B0D12",
			"highlight": "#94A3B8",
			"eye": "#E2E8F0",
		},
	},
	{
		"id": CYBERPUNK,
		"name": "Неоновый Синт",
		"desc": "Ледяной циан и полуночный индиго с контрастным неоновым кантом.",
		"price": 150,
		"white_col": Color(0.35, 0.92, 1.0),
		"black_col": Color(0.95, 0.30, 0.75),
		"accent": Color(0.10, 0.88, 1.0),
		"white_palette": {
			"main": "#E4FAFF",
			"shade": "#84E4F7",
			"deep": "#38BDF8",
			"collar": "#FF2E93",
			"collar_shade": "#BE185D",
			"stroke": "#0F172A",
			"highlight": "#FFFFFF",
			"eye": "#0F172A",
		},
		"black_palette": {
			"main": "#352757",
			"shade": "#211738",
			"deep": "#120B21",
			"collar": "#22D3EE",
			"collar_shade": "#0891B2",
			"stroke": "#090514",
			"highlight": "#A5B4FC",
			"eye": "#22D3EE",
		},
	},
	{
		"id": GOLD,
		"name": "Имперский Янтарь",
		"desc": "Матовое шампанское золото и тёмный оникс в золотой оправе.",
		"price": 250,
		"white_col": Color(1.0, 0.88, 0.42),
		"black_col": Color(0.88, 0.65, 0.30),
		"accent": Color(0.95, 0.72, 0.20),
		"white_palette": {
			"main": "#FFF7D6",
			"shade": "#F3C64F",
			"deep": "#CA8A04",
			"collar": "#9A5812",
			"collar_shade": "#713F12",
			"stroke": "#271705",
			"highlight": "#FFFFFF",
			"eye": "#271705",
		},
		"black_palette": {
			"main": "#382E24",
			"shade": "#241D16",
			"deep": "#14100C",
			"collar": "#FACC15",
			"collar_shade": "#CA8A04",
			"stroke": "#0A0806",
			"highlight": "#A88B6E",
			"eye": "#FACC15",
		},
	},
	{
		"id": EMERALD,
		"name": "Нефрит и Малахит",
		"desc": "Светлый селадоновый нефрит и глубокий уральский малахит.",
		"price": 200,
		"white_col": Color(0.45, 0.95, 0.72),
		"black_col": Color(0.22, 0.78, 0.52),
		"accent": Color(0.20, 0.85, 0.58),
		"white_palette": {
			"main": "#E8FBF2",
			"shade": "#8CE6BE",
			"deep": "#34D399",
			"collar": "#0D9462",
			"collar_shade": "#065F46",
			"stroke": "#062419",
			"highlight": "#FFFFFF",
			"eye": "#062419",
		},
		"black_palette": {
			"main": "#1E4D3B",
			"shade": "#113024",
			"deep": "#081A13",
			"collar": "#4ADE96",
			"collar_shade": "#10B981",
			"stroke": "#04100B",
			"highlight": "#6EE7B7",
			"eye": "#4ADE96",
		},
	},
	{
		"id": OBSIDIAN,
		"name": "Аметистовый Кварц",
		"desc": "Пастельный лавандовый кварц и тёмный обсидиан с фиолетовым поясом.",
		"price": 300,
		"white_col": Color(0.84, 0.72, 1.0),
		"black_col": Color(0.62, 0.42, 0.92),
		"accent": Color(0.72, 0.48, 0.98),
		"white_palette": {
			"main": "#F5EEFF",
			"shade": "#C8B1F7",
			"deep": "#9366E8",
			"collar": "#6D28D9",
			"collar_shade": "#4C1D95",
			"stroke": "#1E1035",
			"highlight": "#FFFFFF",
			"eye": "#1E1035",
		},
		"black_palette": {
			"main": "#342252",
			"shade": "#1F1333",
			"deep": "#110A1E",
			"collar": "#C084FC",
			"collar_shade": "#7E22CE",
			"stroke": "#080411",
			"highlight": "#A78BFA",
			"eye": "#E9D5FF",
		},
	},
	{
		"id": SUPERNOVA,
		"name": "Терракота и Гранат",
		"desc": "Тёплая керамическая охра и благородный тёмно-гранатовый камень.",
		"price": 350,
		"white_col": Color(1.0, 0.68, 0.42),
		"black_col": Color(0.92, 0.35, 0.38),
		"accent": Color(0.95, 0.48, 0.25),
		"white_palette": {
			"main": "#FFF1E6",
			"shade": "#F9AD81",
			"deep": "#EA580C",
			"collar": "#B9381B",
			"collar_shade": "#7F1D1D",
			"stroke": "#2A0F07",
			"highlight": "#FFFFFF",
			"eye": "#2A0F07",
		},
		"black_palette": {
			"main": "#522228",
			"shade": "#331216",
			"deep": "#1C080B",
			"collar": "#FB923C",
			"collar_shade": "#C2410C",
			"stroke": "#0F0406",
			"highlight": "#FDA4AF",
			"eye": "#FDE047",
		},
	},
]


static func get_skin(id: String) -> Dictionary:
	for s in LIST:
		if s["id"] == id:
			return s
	return LIST[0]


static func get_piece_modulate(skin_id: String, is_black: bool) -> Color:
	var skin := get_skin(skin_id)
	return skin.get("black_col" if is_black else "white_col", Color.WHITE)


static func get_army_palette(skin_id: String, army_id: int) -> Dictionary:
	var skin := get_skin(skin_id)
	var w_pal: Dictionary = skin.get("white_palette", LIST[0]["white_palette"])
	var b_pal: Dictionary = skin.get("black_palette", LIST[0]["black_palette"])
	match army_id:
		0: # Белые
			return w_pal
		2: # Чёрные
			return b_pal
		1: # Красные (Мульти-шахматы) — кораллово-рубиновая керамика
			return {
				"main": "#FFD6DC",
				"shade": "#F4647A",
				"deep": "#BE123C",
				"collar": w_pal.get("collar", "#C89D54"),
				"collar_shade": w_pal.get("collar_shade", "#9C7432"),
				"stroke": "#29060E",
				"highlight": "#FFF0F3",
			}
		3: # Синие (Мульти-шахматы) — кобальтовый фарфор
			return {
				"main": "#D8EBFF",
				"shade": "#64A6F7",
				"deep": "#1D4ED8",
				"collar": w_pal.get("collar", "#C89D54"),
				"collar_shade": w_pal.get("collar_shade", "#9C7432"),
				"stroke": "#081638",
				"highlight": "#F0F7FF",
			}
	return w_pal
