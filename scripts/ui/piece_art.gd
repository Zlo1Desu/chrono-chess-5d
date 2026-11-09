class_name PieceArt
extends RefCounted
## Векторная (SVG) 3D-графика шахматных фигур с индивидуальными палитрами скинов,
## гранёным объёмом, броневыми элементами и светящимися квантовыми ядрами.

static var _textures: Dictionary = {}


static func _get_piece_texture(pt: int, army_id: int, skin_id: String) -> Texture2D:
	var clean_skin := skin_id if skin_id != "" else Skins.CLASSIC
	var key := "%s_%d_%d" % [clean_skin, army_id, pt]
	if _textures.has(key):
		return _textures[key]

	var pal: Dictionary = Skins.get_army_palette(clean_skin, army_id)
	var svg_str := _make_piece_svg(pt, pal)
	var img := Image.new()
	var err: int = img.load_svg_from_string(svg_str, 1.0)
	if err == OK:
		var tex := ImageTexture.create_from_image(img)
		_textures[key] = tex
		return tex
	return null


static func _make_piece_svg(pt: int, pal: Dictionary) -> String:
	var aura: String = pal.get("aura", "#38bdf8")
	var body_top: String = pal.get("body_top", "#ffffff")
	var body_mid: String = pal.get("body_mid", "#dbeafe")
	var body_bot: String = pal.get("body_bot", "#93c5fd")
	var facet_l: String = pal.get("facet_light", "#ffffff")
	var facet_d: String = pal.get("facet_dark", "#60a5fa")
	var trim_top: String = pal.get("trim_top", "#fef08a")
	var trim_bot: String = pal.get("trim_bot", "#d97706")
	var ped_top: String = pal.get("pedestal_top", "#e2e8f0")
	var ped_bot: String = pal.get("pedestal_bot", "#64748b")
	var st: String = pal.get("stroke", "#0f172a")
	var rim: String = pal.get("rim", "#ffffff")
	var core_b: String = pal.get("core_bright", "#e0f2fe")
	var core_o: String = pal.get("core_outer", "#0284c7")

	var defs := (
		'<defs>'
		+ '<radialGradient id="aura" cx="50%" cy="52%" r="48%">'
		+ '<stop offset="0%" stop-color="' + aura + '" stop-opacity="0.34"/>'
		+ '<stop offset="65%" stop-color="' + aura + '" stop-opacity="0.10"/>'
		+ '<stop offset="100%" stop-color="' + aura + '" stop-opacity="0.0"/>'
		+ '</radialGradient>'
		+ '<linearGradient id="body" x1="18%" y1="8%" x2="84%" y2="94%">'
		+ '<stop offset="0%" stop-color="' + body_top + '"/>'
		+ '<stop offset="48%" stop-color="' + body_mid + '"/>'
		+ '<stop offset="100%" stop-color="' + body_bot + '"/>'
		+ '</linearGradient>'
		+ '<linearGradient id="trim" x1="15%" y1="0%" x2="85%" y2="100%">'
		+ '<stop offset="0%" stop-color="' + trim_top + '"/>'
		+ '<stop offset="100%" stop-color="' + trim_bot + '"/>'
		+ '</linearGradient>'
		+ '<linearGradient id="ped" x1="10%" y1="0%" x2="90%" y2="100%">'
		+ '<stop offset="0%" stop-color="' + ped_top + '"/>'
		+ '<stop offset="100%" stop-color="' + ped_bot + '"/>'
		+ '</linearGradient>'
		+ '<radialGradient id="core" cx="38%" cy="35%" r="65%">'
		+ '<stop offset="0%" stop-color="#ffffff"/>'
		+ '<stop offset="38%" stop-color="' + core_b + '"/>'
		+ '<stop offset="100%" stop-color="' + core_o + '"/>'
		+ '</radialGradient>'
		+ '</defs>'
	)

	var bg_and_base := (
		'<circle cx="64" cy="62" r="56" fill="url(#aura)"/>'
		+ '<ellipse cx="64" cy="116" rx="44" ry="7.5" fill="#000000" fill-opacity="0.45"/>'
	)

	var pedestal := (
		'<path d="M 21 114 C 21 104, 32 101, 64 101 C 96 101, 107 104, 107 114 Z" fill="url(#ped)" stroke="' + st + '" stroke-width="3.6" stroke-linejoin="round"/>'
		+ '<path d="M 25 114 L 56 102 L 26 106 Z" fill="' + facet_l + '" fill-opacity="0.28"/>'
		+ '<path d="M 28 102 C 28 95, 38 93, 64 93 C 90 93, 100 95, 100 102 Z" fill="url(#body)" stroke="' + st + '" stroke-width="3.2" stroke-linejoin="round"/>'
		+ '<rect x="31" y="89" width="66" height="6.5" rx="3.2" fill="url(#trim)" stroke="' + st + '" stroke-width="2.6"/>'
		+ '<path d="M 29 110 L 99 110" stroke="' + rim + '" stroke-width="2.0" stroke-linecap="round" stroke-opacity="0.65"/>'
	)

	var art := ""
	match pt:
		GameState.PAWN:
			# Пешка — Квантовый Страж с гранёным корпусом, золотым воротником и энергетической сферой
			art = (
				# Основной корпус
				'<path d="M 35 89 C 37 72, 45 61, 50 51 L 78 51 C 83 61, 91 72, 93 89 Z" fill="url(#body)" stroke="' + st + '" stroke-width="3.6" stroke-linejoin="round"/>'
				# 3D-грани корпуса
				+ '<path d="M 38 87 C 40 73, 47 62, 52 53 L 64 53 L 64 87 Z" fill="' + facet_l + '" fill-opacity="0.30"/>'
				+ '<path d="M 64 53 L 76 53 C 81 62, 88 73, 90 87 L 64 87 Z" fill="' + facet_d + '" fill-opacity="0.32"/>'
				# Нагрудный щиток-шеврон
				+ '<path d="M 49 60 L 64 55 L 79 60 L 74 79 L 64 85 L 54 79 Z" fill="url(#ped)" stroke="' + st + '" stroke-width="2.4" stroke-linejoin="round"/>'
				# Воротник-кольцо
				+ '<path d="M 43 51 C 43 46, 85 46, 85 51 C 85 55, 43 55, 43 51 Z" fill="url(#trim)" stroke="' + st + '" stroke-width="2.8"/>'
				# Ореол вокруг головы
				+ '<circle cx="64" cy="33" r="21" fill="none" stroke="url(#trim)" stroke-width="2.4" stroke-opacity="0.75"/>'
				# Голова-сфера
				+ '<circle cx="64" cy="33" r="16.5" fill="url(#body)" stroke="' + st + '" stroke-width="3.6"/>'
				+ '<path d="M 52 24 A 13 13 0 0 1 68 19" fill="none" stroke="' + facet_l + '" stroke-width="3.2" stroke-linecap="round" stroke-opacity="0.65"/>'
				# Квантовое ядро в груди и во лбу
				+ '<polygon points="64,61 71,70 64,79 57,70" fill="url(#core)" stroke="' + st + '" stroke-width="2.0"/>'
				+ '<circle cx="64" cy="33" r="5.5" fill="url(#core)" stroke="' + st + '" stroke-width="1.8"/>'
				+ '<circle cx="62" cy="31" r="1.8" fill="#ffffff"/>'
			)

		GameState.ROOK:
			# Ладья — Цитадель Времени с бастионными зубцами, контрфорсами и силовым реактором
			art = (
				# Башня
				'<path d="M 33 89 L 39 44 L 89 44 L 95 89 Z" fill="url(#body)" stroke="' + st + '" stroke-width="3.6" stroke-linejoin="round"/>'
				# 3D-грани башни
				+ '<path d="M 35 87 L 41 46 L 64 46 L 64 87 Z" fill="' + facet_l + '" fill-opacity="0.28"/>'
				+ '<path d="M 64 46 L 87 46 L 93 87 L 64 87 Z" fill="' + facet_d + '" fill-opacity="0.34"/>'
				# Боковые броневые контрфорсы
				+ '<path d="M 33 89 L 41 52 L 49 52 L 45 89 Z" fill="url(#ped)" stroke="' + st + '" stroke-width="2.4"/>'
				+ '<path d="M 95 89 L 87 52 L 79 52 L 83 89 Z" fill="url(#ped)" stroke="' + st + '" stroke-width="2.4"/>'
				# Карниз под зубцами
				+ '<rect x="33" y="39" width="62" height="7" rx="2.5" fill="url(#trim)" stroke="' + st + '" stroke-width="2.8"/>'
				# Корона цитадели с зубцами
				+ '<path d="M 27 39 L 27 19 L 43 19 L 43 29 L 55 29 L 55 17 L 73 17 L 73 29 L 85 29 L 85 19 L 101 19 L 101 39 Z" fill="url(#body)" stroke="' + st + '" stroke-width="3.6" stroke-linejoin="round"/>'
				+ '<path d="M 29 37 L 29 21 L 41 21 L 41 31 L 64 31 L 64 37 Z" fill="' + facet_l + '" fill-opacity="0.32"/>'
				# Золотая окантовка центрального зубца
				+ '<rect x="57" y="19" width="14" height="7" rx="1.5" fill="url(#trim)" stroke="' + st + '" stroke-width="1.8"/>'
				# Силовая бойница / энергетический реактор в центре башни
				+ '<polygon points="64,51 74,62 70,81 58,81 54,62" fill="url(#trim)" stroke="' + st + '" stroke-width="2.4"/>'
				+ '<polygon points="64,55 70,63 67,77 61,77 58,63" fill="url(#core)" stroke="' + st + '" stroke-width="1.8"/>'
				+ '<circle cx="64" cy="64" r="2.5" fill="#ffffff"/>'
			)

		GameState.BISHOP:
			# Слон — Хроно-Прелат с высокой митрой, золотыми лентами и пространственным разрезом
			art = (
				# Плечи/мантия
				'<path d="M 32 89 C 34 73, 42 66, 48 62 L 80 62 C 86 66, 94 73, 96 89 Z" fill="url(#ped)" stroke="' + st + '" stroke-width="3.4" stroke-linejoin="round"/>'
				# Купол митры
				+ '<path d="M 40 85 C 33 60, 42 32, 64 19 C 86 32, 95 60, 88 85 Z" fill="url(#body)" stroke="' + st + '" stroke-width="3.6" stroke-linejoin="round"/>'
				# 3D-грани митры
				+ '<path d="M 42 83 C 36 60, 44 34, 64 21 L 64 83 Z" fill="' + facet_l + '" fill-opacity="0.30"/>'
				+ '<path d="M 64 21 C 84 34, 92 60, 86 83 L 64 83 Z" fill="' + facet_d + '" fill-opacity="0.33"/>'
				# Золотые диагональные ленты митры
				+ '<path d="M 43 74 Q 64 64 85 74" fill="none" stroke="url(#trim)" stroke-width="5.0" stroke-linecap="round"/>'
				+ '<path d="M 43 74 Q 64 64 85 74" fill="none" stroke="' + st + '" stroke-width="1.6" stroke-linecap="round"/>'
				+ '<path d="M 64 22 L 64 84" stroke="url(#trim)" stroke-width="4.0"/>'
				# Навершие-держава со звездой
				+ '<circle cx="64" cy="13" r="6.5" fill="url(#trim)" stroke="' + st + '" stroke-width="2.6"/>'
				+ '<circle cx="64" cy="13" r="3.0" fill="url(#core)"/>'
				# Квантовый символ-крест/ромб в центре митры
				+ '<polygon points="64,36 76,50 64,64 52,50" fill="url(#trim)" stroke="' + st + '" stroke-width="2.6"/>'
				+ '<polygon points="64,41 71,50 64,59 57,50" fill="url(#core)" stroke="' + st + '" stroke-width="1.8"/>'
				+ '<circle cx="62.5" cy="48" r="2.0" fill="#ffffff"/>'
			)

		GameState.KNIGHT:
			# Конь — Боевой Меха-Дестриэ с пластинчатой гривой, броневым налобником и горящим оком
			art = (
				# Задняя пластинчатая грива (золотой/акцентный гребень)
				'<path d="M 72 18 C 94 24, 104 44, 98 67 C 96 76, 94 83, 95 89 L 76 89 Z" fill="url(#trim)" stroke="' + st + '" stroke-width="3.2" stroke-linejoin="round"/>'
				# Зубцы гривы
				+ '<path d="M 80 26 L 97 32 L 84 41 L 100 49 L 85 59 L 97 69 L 82 77" fill="none" stroke="' + st + '" stroke-width="2.4" stroke-linejoin="round"/>'
				# Основной скульптурный профиль коня
				+ '<path d="M 33 89 C 33 69, 44 59, 52 51 C 42 52, 31 56, 25 49 C 20 43, 25 34, 36 28 C 42 25, 45 21, 45 14 L 57 21 C 62 18, 66 13, 72 11 L 75 23 C 89 31, 93 52, 88 89 Z" fill="url(#body)" stroke="' + st + '" stroke-width="3.6" stroke-linejoin="round"/>'
				# 3D-грань света (шея и морда)
				+ '<path d="M 36 87 C 37 69, 48 58, 56 49 L 30 47 C 26 43, 30 35, 40 30 L 47 18 L 58 24 L 68 55 L 58 87 Z" fill="' + facet_l + '" fill-opacity="0.30"/>'
				# 3D-грань тени (затылок и круп)
				+ '<path d="M 73 24 C 86 32, 90 52, 86 87 L 60 87 L 68 52 Z" fill="' + facet_d + '" fill-opacity="0.34"/>'
				# Броневой налобник (шафрон) и нагрудная пластина
				+ '<path d="M 46 16 L 56 22 L 42 40 L 27 46 C 26 40, 34 32, 46 16 Z" fill="url(#trim)" stroke="' + st + '" stroke-width="2.2" stroke-linejoin="round"/>'
				+ '<path d="M 35 89 C 37 74, 45 65, 56 61 L 66 72 L 58 89 Z" fill="url(#trim)" stroke="' + st + '" stroke-width="2.4" stroke-linejoin="round"/>'
				# Светящийся кибер-глаз и нагрудное ядро
				+ '<polygon points="45,30 55,27 51,35 43,35" fill="url(#core)" stroke="' + st + '" stroke-width="1.8"/>'
				+ '<circle cx="49" cy="31" r="1.6" fill="#ffffff"/>'
				+ '<circle cx="51" cy="77" r="5.5" fill="url(#core)" stroke="' + st + '" stroke-width="1.8"/>'
			)

		GameState.QUEEN:
			# Ферзь — Императрица Мультивселенной с 5-лучевой короной, парящими сферами и кристаллом
			art = (
				# Внутренняя золотая корона-ореол
				'<path d="M 28 42 L 43 22 L 64 36 L 85 22 L 100 42 L 88 85 L 40 85 Z" fill="url(#trim)" fill-opacity="0.45" stroke="' + st + '" stroke-width="2.4" stroke-linejoin="round"/>'
				# Главное платье/диадема с 5 острыми шпилями
				+ '<path d="M 32 89 L 19 34 L 41 55 L 44 22 L 58 51 L 64 16 L 70 51 L 84 22 L 87 55 L 109 34 L 96 89 Z" fill="url(#body)" stroke="' + st + '" stroke-width="3.6" stroke-linejoin="round"/>'
				# 3D-грань света (левая половина)
				+ '<path d="M 34 87 L 22 38 L 41 56 L 45 26 L 58 52 L 64 20 L 64 87 Z" fill="' + facet_l + '" fill-opacity="0.32"/>'
				# 3D-грань тени (правая половина)
				+ '<path d="M 64 20 L 70 52 L 83 26 L 87 56 L 106 38 L 94 87 L 64 87 Z" fill="' + facet_d + '" fill-opacity="0.34"/>'
				# Королевский пояс-корсет
				+ '<path d="M 34 76 Q 64 68 94 76 L 96 89 L 32 89 Z" fill="url(#trim)" stroke="' + st + '" stroke-width="2.8" stroke-linejoin="round"/>'
				# Жемчужины-сферы на вершинах 5 лучей
				+ '<circle cx="19" cy="30" r="5.0" fill="url(#trim)" stroke="' + st + '" stroke-width="2.2"/>'
				+ '<circle cx="44" cy="18" r="5.5" fill="url(#trim)" stroke="' + st + '" stroke-width="2.2"/>'
				+ '<circle cx="64" cy="12" r="6.5" fill="url(#core)" stroke="' + st + '" stroke-width="2.4"/>'
				+ '<circle cx="84" cy="18" r="5.5" fill="url(#trim)" stroke="' + st + '" stroke-width="2.2"/>'
				+ '<circle cx="109" cy="30" r="5.0" fill="url(#trim)" stroke="' + st + '" stroke-width="2.2"/>'
				# Центральный бриллиант Императрицы
				+ '<polygon points="64,52 75,66 64,81 53,66" fill="url(#trim)" stroke="' + st + '" stroke-width="2.4"/>'
				+ '<polygon points="64,56 71,66 64,76 57,66" fill="url(#core)" stroke="' + st + '" stroke-width="1.8"/>'
				+ '<circle cx="62" cy="63" r="2.2" fill="#ffffff"/>'
			)

		GameState.KING:
			# Король — Монарх Хроноса с имперским крестом, мантией и квантовыми песочными часами
			art = (
				# Навершие — Имперский крест с кристаллом
				'<path d="M 59 6 L 69 6 L 69 13 L 77 13 L 77 22 L 69 22 L 69 30 L 59 30 L 59 22 L 51 22 L 51 13 L 59 13 Z" fill="url(#trim)" stroke="' + st + '" stroke-width="3.0" stroke-linejoin="round"/>'
				+ '<circle cx="64" cy="17.5" r="4.2" fill="url(#core)" stroke="' + st + '" stroke-width="1.6"/>'
				# Внутренний золотой купол короны
				+ '<path d="M 34 44 C 34 26, 94 26, 94 44 L 88 85 L 40 85 Z" fill="url(#ped)" stroke="' + st + '" stroke-width="2.8"/>'
				# Главная зубчатая корона и броня Монарха
				+ '<path d="M 30 89 L 23 44 L 42 54 L 49 32 L 64 46 L 79 32 L 86 54 L 105 44 L 98 89 Z" fill="url(#body)" stroke="' + st + '" stroke-width="3.6" stroke-linejoin="round"/>'
				# 3D-грань света и тени
				+ '<path d="M 32 87 L 25 46 L 42 55 L 49 35 L 64 48 L 64 87 Z" fill="' + facet_l + '" fill-opacity="0.32"/>'
				+ '<path d="M 64 48 L 79 35 L 86 55 L 103 46 L 96 87 L 64 87 Z" fill="' + facet_d + '" fill-opacity="0.34"/>'
				# Золотой обруч короны и наплечники
				+ '<path d="M 29 77 L 99 77 L 98 89 L 30 89 Z" fill="url(#trim)" stroke="' + st + '" stroke-width="2.6" stroke-linejoin="round"/>'
				# Квантовое ядро песочных часов в центре груди Короля
				+ '<polygon points="52,53 76,53 67,65 76,77 52,77 61,65" fill="url(#trim)" stroke="' + st + '" stroke-width="2.4" stroke-linejoin="round"/>'
				+ '<polygon points="56,56 72,56 65,65 72,74 56,74 63,65" fill="url(#core)"/>'
				+ '<circle cx="64" cy="65" r="2.6" fill="#ffffff"/>'
			)

		GameState.UNICORN:
			# Единорог — Астральный Скакун с длинным витым золотым рогом и звёздной гривой
			art = (
				# Звёздная грива
				'<path d="M 74 26 C 95 33, 103 52, 96 89 L 76 89 Z" fill="url(#trim)" stroke="' + st + '" stroke-width="3.0" stroke-linejoin="round"/>'
				# Витой спиральный рог Единорога, пронзающий пространство
				+ '<polygon points="48,29 14,6 59,20" fill="url(#trim)" stroke="' + st + '" stroke-width="3.0" stroke-linejoin="round"/>'
				+ '<polygon points="46,26 18,9 54,21" fill="url(#core)" fill-opacity="0.75"/>'
				+ '<path d="M 26 14 L 35 19 M 35 19 L 44 25" stroke="' + st + '" stroke-width="2.0" stroke-linecap="round"/>'
				# Скульптурный корпус и голова Единорога
				+ '<path d="M 34 89 C 34 68, 45 58, 53 50 C 42 52, 31 55, 26 48 C 22 43, 28 34, 44 28 L 58 20 L 72 13 L 75 26 C 89 35, 92 56, 88 89 Z" fill="url(#body)" stroke="' + st + '" stroke-width="3.6" stroke-linejoin="round"/>'
				# 3D-грань света и тени
				+ '<path d="M 36 87 C 37 68, 48 57, 56 49 L 29 47 C 26 43, 32 35, 45 29 L 60 22 L 66 54 L 58 87 Z" fill="' + facet_l + '" fill-opacity="0.32"/>'
				+ '<path d="M 73 27 C 86 35, 89 56, 86 87 L 58 87 L 66 54 Z" fill="' + facet_d + '" fill-opacity="0.34"/>'
				# Астральный глаз и звезда на груди
				+ '<polygon points="46,33 56,30 52,38 44,38" fill="url(#core)" stroke="' + st + '" stroke-width="1.8"/>'
				+ '<polygon points="62,56 66,66 76,70 66,74 62,84 58,74 48,70 58,66" fill="url(#core)" stroke="' + st + '" stroke-width="2.0" stroke-linejoin="round"/>'
				+ '<circle cx="62" cy="70" r="2.2" fill="#ffffff"/>'
			)

		GameState.DRAGON:
			# Дракон — Крылатый Змей Вечности с расправленными крыльями, рогами и огненным сердцем
			art = (
				# Расправленные перепончатые крылья дракона (задний план)
				'<path d="M 52 54 L 12 22 L 18 46 L 10 58 L 26 65 L 20 77 L 42 78 Z" fill="url(#trim)" stroke="' + st + '" stroke-width="3.0" stroke-linejoin="round"/>'
				+ '<path d="M 76 54 L 116 22 L 110 46 L 118 58 L 102 65 L 108 77 L 86 78 Z" fill="url(#trim)" stroke="' + st + '" stroke-width="3.0" stroke-linejoin="round"/>'
				# Внутренние перепонки крыльев
				+ '<path d="M 48 56 L 18 30 L 23 48 L 16 57 L 36 66 Z" fill="url(#ped)" fill-opacity="0.65"/>'
				+ '<path d="M 80 56 L 110 30 L 105 48 L 112 57 L 92 66 Z" fill="url(#ped)" fill-opacity="0.65"/>'
				# Рога дракона
				+ '<path d="M 52 24 L 35 8 L 46 30 Z" fill="url(#trim)" stroke="' + st + '" stroke-width="2.6" stroke-linejoin="round"/>'
				+ '<path d="M 76 24 L 93 8 L 82 30 Z" fill="url(#trim)" stroke="' + st + '" stroke-width="2.6" stroke-linejoin="round"/>'
				# Бронированная шея, грудь и рогатая голова дракона
				+ '<path d="M 36 89 C 38 69, 44 55, 49 43 L 40 35 L 50 23 L 64 14 L 78 23 L 88 35 L 79 43 C 84 55, 90 69, 92 89 Z" fill="url(#body)" stroke="' + st + '" stroke-width="3.6" stroke-linejoin="round"/>'
				# 3D-грани тела дракона
				+ '<path d="M 38 87 C 40 69, 46 55, 51 43 L 43 35 L 52 24 L 64 16 L 64 87 Z" fill="' + facet_l + '" fill-opacity="0.30"/>'
				+ '<path d="M 64 16 L 76 24 L 85 35 L 77 43 C 82 55, 88 69, 90 87 L 64 87 Z" fill="' + facet_d + '" fill-opacity="0.34"/>'
				# Грудная чешуя и пылающее сердце дракона + горящие глаза
				+ '<polygon points="52,29 60,33 54,37" fill="url(#core)" stroke="' + st + '" stroke-width="1.5"/>'
				+ '<polygon points="76,29 68,33 74,37" fill="url(#core)" stroke="' + st + '" stroke-width="1.5"/>'
				+ '<polygon points="64,48 77,64 64,84 51,64" fill="url(#trim)" stroke="' + st + '" stroke-width="2.4"/>'
				+ '<polygon points="64,53 72,64 64,78 56,64" fill="url(#core)" stroke="' + st + '" stroke-width="1.8"/>'
				+ '<circle cx="64" cy="64" r="2.6" fill="#ffffff"/>'
			)

		GameState.PRINCESS:
			# Принцесса — Архитектор Зари с крылатой диадемой, изящным силуэтом и сапфировой звездой
			art = (
				# Боковые парящие крылья-лепестки
				'<path d="M 42 74 C 22 64, 16 42, 24 24 C 32 36, 40 46, 46 54 Z" fill="url(#trim)" stroke="' + st + '" stroke-width="3.0" stroke-linejoin="round"/>'
				+ '<path d="M 86 74 C 106 64, 112 42, 104 24 C 96 36, 88 46, 82 54 Z" fill="url(#trim)" stroke="' + st + '" stroke-width="3.0" stroke-linejoin="round"/>'
				# Стройный королевский силуэт с 3 высокими шпилями тиары
				+ '<path d="M 35 89 C 38 69, 44 55, 42 30 L 56 46 L 64 14 L 72 46 L 86 30 C 84 55, 90 69, 93 89 Z" fill="url(#body)" stroke="' + st + '" stroke-width="3.6" stroke-linejoin="round"/>'
				# 3D-грани тиары
				+ '<path d="M 37 87 C 40 69, 45 55, 44 34 L 56 48 L 64 18 L 64 87 Z" fill="' + facet_l + '" fill-opacity="0.32"/>'
				+ '<path d="M 64 18 L 72 48 L 84 34 C 83 55, 88 69, 91 87 L 64 87 Z" fill="' + facet_d + '" fill-opacity="0.34"/>'
				# Навершия тиары
				+ '<circle cx="64" cy="11" r="5.5" fill="url(#core)" stroke="' + st + '" stroke-width="2.2"/>'
				+ '<circle cx="42" cy="27" r="4.2" fill="url(#trim)" stroke="' + st + '" stroke-width="2.0"/>'
				+ '<circle cx="86" cy="27" r="4.2" fill="url(#trim)" stroke="' + st + '" stroke-width="2.0"/>'
				# Звёздный медальон Принцессы
				+ '<polygon points="64,48 70,60 82,64 70,68 64,80 58,68 46,64 58,60" fill="url(#trim)" stroke="' + st + '" stroke-width="2.2" stroke-linejoin="round"/>'
				+ '<circle cx="64" cy="64" r="6.5" fill="url(#core)" stroke="' + st + '" stroke-width="1.8"/>'
				+ '<circle cx="62" cy="62" r="2.0" fill="#ffffff"/>'
			)

	return (
		'<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">'
		+ defs
		+ bg_and_base
		+ pedestal
		+ art
		+ '</svg>'
	)


static func draw_piece(ci: CanvasItem, piece: int, rect: Rect2, alpha: float = 1.0, override_skin: String = "") -> void:
	var pt := piece & 15
	if pt == GameState.EMPTY:
		return
	var is_black := (piece & GameState.BLACK_BIT) != 0
	var skin_id: String = override_skin if override_skin != "" else Profile.active_skin
	var army_id: int = 2 if is_black else 0

	var tex := _get_piece_texture(pt, army_id, skin_id)
	if tex != null:
		var draw_rect := rect.grow(-rect.size.x * 0.03)
		ci.draw_texture_rect(tex, draw_rect, false, Color(1.0, 1.0, 1.0, alpha))


static func draw_multi_piece(ci: CanvasItem, piece_type: int, player_id: int, rect: Rect2, alpha: float = 1.0, override_skin: String = "") -> void:
	if piece_type == MultiChessState.EMPTY:
		return
	var skin_id: String = override_skin if override_skin != "" else Profile.active_skin
	var army_id: int = clampi(player_id, 0, 3)

	var tex := _get_piece_texture(piece_type, army_id, skin_id)
	if tex != null:
		var draw_rect := rect.grow(-rect.size.x * 0.03)
		ci.draw_texture_rect(tex, draw_rect, false, Color(1.0, 1.0, 1.0, alpha))
