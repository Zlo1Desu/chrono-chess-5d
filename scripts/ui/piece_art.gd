class_name PieceArt
extends RefCounted
## Стилизованная векторная графика шахматных фигур в эстетике Cel-Shaded Staunton.
## Чистые резные силуэты, двухтоновый cel-шейдинг, латунный/акцентный обод и плотный контур.

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
	var c_main: String = pal.get("main", "#FAF6EE")
	var c_shade: String = pal.get("shade", "#DED4C1")
	var c_deep: String = pal.get("deep", "#BFB29B")
	var c_collar: String = pal.get("collar", "#C89D54")
	var c_collar_sh: String = pal.get("collar_shade", "#9C7432")
	var st: String = pal.get("stroke", "#1C2026")
	var hi: String = pal.get("highlight", "#FFFFFF")
	var eye: String = pal.get("eye", st)

	# Чёткая контактная тень под основанием (без размытых неоновых ореолов)
	var ground_shadow := '<ellipse cx="64" cy="115" rx="41" ry="5.5" fill="#000000" fill-opacity="0.32"/>'

	# Классическая точёная подставка Стаунтон (двухступенчатая с акцентным кольцом)
	var base_pedestal := (
		# Нижний широкий диск базы
		'<path d="M 23 113 C 23 105, 31 103, 64 103 C 97 103, 105 105, 105 113 Z" fill="' + c_main + '" stroke="' + st + '" stroke-width="4.2" stroke-linejoin="round"/>'
		+ '<path d="M 64 103 C 97 103, 105 105, 105 113 L 60 113 C 62 108, 63 105, 64 103 Z" fill="' + c_shade + '"/>'
		+ '<path d="M 23 113 C 23 105, 31 103, 64 103 C 97 103, 105 105, 105 113 Z" fill="none" stroke="' + st + '" stroke-width="4.2" stroke-linejoin="round"/>'
		# Вторая ступень базы
		+ '<path d="M 29 103 C 29 96, 37 94, 64 94 C 91 94, 99 96, 99 103 Z" fill="' + c_main + '"/>'
		+ '<path d="M 62 94 C 90 94, 99 96, 99 103 L 58 103 Z" fill="' + c_shade + '"/>'
		+ '<path d="M 29 103 C 29 96, 37 94, 64 94 C 91 94, 99 96, 99 103 Z" fill="none" stroke="' + st + '" stroke-width="3.8" stroke-linejoin="round"/>'
		# Точёное кольцо-обод (Collar)
		+ '<rect x="33" y="89" width="62" height="6" rx="3" fill="' + c_collar + '" stroke="' + st + '" stroke-width="3.4"/>'
		+ '<rect x="64" y="90.5" width="29" height="3" rx="1.5" fill="' + c_collar_sh + '"/>'
	)

	var art := ""
	match pt:
		GameState.PAWN:
			# Пешка Стаунтон: точёная вогнутая ножка, верхний воротничок и гладкий шар
			art = (
				# Вогнутый корпус
				'<path d="M 37 89 C 40 73, 47 62, 50 50 L 78 50 C 81 62, 88 73, 91 89 Z" fill="' + c_main + '"/>'
				# Тень справа (cel-shade)
				+ '<path d="M 61 50 L 78 50 C 81 62, 88 73, 91 89 L 58 89 C 61 74, 62 61, 61 50 Z" fill="' + c_shade + '"/>'
				+ '<path d="M 37 89 C 40 73, 47 62, 50 50 L 78 50 C 81 62, 88 73, 91 89 Z" fill="none" stroke="' + st + '" stroke-width="4.2" stroke-linejoin="round"/>'
				# Световой блик слева
				+ '<path d="M 43 84 C 45 72, 50 62, 53 54" fill="none" stroke="' + hi + '" stroke-width="3.0" stroke-linecap="round" stroke-opacity="0.75"/>'
				# Верхний воротничок под головой
				+ '<rect x="44" y="45" width="40" height="6.5" rx="3.2" fill="' + c_collar + '" stroke="' + st + '" stroke-width="3.6"/>'
				# Круглая голова пешки
				+ '<circle cx="64" cy="29" r="16.5" fill="' + c_main + '"/>'
				+ '<path d="M 64 12.5 A 16.5 16.5 0 0 1 64 45.5 A 12 16.5 0 0 0 64 12.5 Z" fill="' + c_shade + '"/>'
				+ '<circle cx="64" cy="29" r="16.5" fill="none" stroke="' + st + '" stroke-width="4.2"/>'
				+ '<path d="M 53 21 A 11 11 0 0 1 63 16.5" fill="none" stroke="' + hi + '" stroke-width="3.2" stroke-linecap="round" stroke-opacity="0.85"/>'
			)

		GameState.ROOK:
			# Ладья Стаунтон: монолитная крепостная башня с каннелюрами и 3 зубцами
			art = (
				# Колонна башни
				'<path d="M 36 89 L 41 44 L 87 44 L 92 89 Z" fill="' + c_main + '"/>'
				+ '<path d="M 62 44 L 87 44 L 92 89 L 60 89 Z" fill="' + c_shade + '"/>'
				+ '<path d="M 36 89 L 41 44 L 87 44 L 92 89 Z" fill="none" stroke="' + st + '" stroke-width="4.2" stroke-linejoin="round"/>'
				# Архитектурные вертикальные желоба (каннелюры)
				+ '<line x1="52" y1="52" x2="50" y2="82" stroke="' + st + '" stroke-width="3.2" stroke-linecap="round" stroke-opacity="0.55"/>'
				+ '<line x1="64" y1="52" x2="64" y2="82" stroke="' + st + '" stroke-width="3.2" stroke-linecap="round" stroke-opacity="0.55"/>'
				+ '<line x1="76" y1="52" x2="78" y2="82" stroke="' + st + '" stroke-width="3.2" stroke-linecap="round" stroke-opacity="0.55"/>'
				# Каменный карниз под зубцами
				+ '<rect x="33" y="38" width="62" height="7" rx="2.5" fill="' + c_collar + '" stroke="' + st + '" stroke-width="3.6"/>'
				# Корона башни с 3 классическими зубцами
				+ '<path d="M 30 38 L 30 18 L 46 18 L 46 27 L 56 27 L 56 18 L 72 18 L 72 27 L 82 27 L 82 18 L 98 18 L 98 38 Z" fill="' + c_main + '"/>'
				+ '<path d="M 64 18 L 72 18 L 72 27 L 82 27 L 82 18 L 98 18 L 98 38 L 64 38 Z" fill="' + c_shade + '"/>'
				+ '<path d="M 30 38 L 30 18 L 46 18 L 46 27 L 56 27 L 56 18 L 72 18 L 72 27 L 82 27 L 82 18 L 98 18 L 98 38 Z" fill="none" stroke="' + st + '" stroke-width="4.2" stroke-linejoin="round"/>'
				+ '<line x1="35" y1="22" x2="35" y2="34" stroke="' + hi + '" stroke-width="2.8" stroke-linecap="round" stroke-opacity="0.75"/>'
			)

		GameState.BISHOP:
			# Слон Стаунтон: обтекаемая митра с фирменным диагональным вырезом справа и шариком-навершием
			art = (
				# Ножка под митрой
				'<path d="M 36 89 C 38 78, 43 72, 47 68 L 81 68 C 85 72, 90 78, 92 89 Z" fill="' + c_main + '"/>'
				+ '<path d="M 62 68 L 81 68 C 85 72, 90 78, 92 89 L 60 89 Z" fill="' + c_shade + '"/>'
				+ '<path d="M 36 89 C 38 78, 43 72, 47 68 L 81 68 C 85 72, 90 78, 92 89 Z" fill="none" stroke="' + st + '" stroke-width="4.0" stroke-linejoin="round"/>'
				# Кольцо под митрой
				+ '<rect x="42" y="63" width="44" height="6" rx="3" fill="' + c_collar + '" stroke="' + st + '" stroke-width="3.4"/>'
				# Купол митры с характерным вырезом (прорезью) слона справа-сверху
				+ '<path d="M 43 63 C 36 47, 43 26, 64 17 C 72 21, 78 27, 81 34 L 68 43 L 84 41 C 88 49, 88 57, 85 63 Z" fill="' + c_main + '"/>'
				+ '<path d="M 64 17 C 72 21, 78 27, 81 34 L 68 43 L 84 41 C 88 49, 88 57, 85 63 L 61 63 C 63 47, 64 31, 64 17 Z" fill="' + c_shade + '"/>'
				+ '<path d="M 43 63 C 36 47, 43 26, 64 17 C 72 21, 78 27, 81 34 L 68 43 L 84 41 C 88 49, 88 57, 85 63 Z" fill="none" stroke="' + st + '" stroke-width="4.2" stroke-linejoin="round"/>'
				# Блик на левом своде митры
				+ '<path d="M 46 55 C 43 43, 48 29, 60 22" fill="none" stroke="' + hi + '" stroke-width="3.0" stroke-linecap="round" stroke-opacity="0.75"/>'
				# Шарик-навершие на вершине митры
				+ '<circle cx="64" cy="12" r="5.5" fill="' + c_collar + '" stroke="' + st + '" stroke-width="3.4"/>'
			)

		GameState.KNIGHT:
			# Конь Стаунтон: благородный резной профиль боевого коня с 3 прядями гривы
			art = (
				# Пряди резной гривы по гребню шеи
				'<path d="M 68 18 C 88 23, 98 40, 95 62 C 94 72, 92 81, 93 89 L 74 89 Z" fill="' + c_collar + '" stroke="' + st + '" stroke-width="3.8" stroke-linejoin="round"/>'
				+ '<path d="M 80 36 L 94 40 M 81 53 L 95 57 M 80 70 L 92 73" stroke="' + st + '" stroke-width="3.2" stroke-linecap="round"/>'
				# Основной профиль головы и шеи коня
				+ '<path d="M 34 89 C 34 69, 44 58, 52 49 C 43 51, 33 55, 27 49 C 22 44, 24 36, 33 30 C 40 25, 45 21, 47 12 L 58 20 C 63 16, 67 12, 72 10 L 74 22 C 85 32, 88 54, 85 89 Z" fill="' + c_main + '"/>'
				# Теневая часть шеи и скулы
				+ '<path d="M 72 22 C 85 32, 88 54, 85 89 L 58 89 C 62 69, 64 52, 60 36 L 44 45 C 48 39, 55 34, 62 28 Z" fill="' + c_shade + '"/>'
				+ '<path d="M 34 89 C 34 69, 44 58, 52 49 C 43 51, 33 55, 27 49 C 22 44, 24 36, 33 30 C 40 25, 45 21, 47 12 L 58 20 C 63 16, 67 12, 72 10 L 74 22 C 85 32, 88 54, 85 89 Z" fill="none" stroke="' + st + '" stroke-width="4.2" stroke-linejoin="round"/>'
				# Световой блик вдоль переносицы и груди
				+ '<path d="M 30 41 C 36 34, 43 28, 48 18" fill="none" stroke="' + hi + '" stroke-width="2.8" stroke-linecap="round" stroke-opacity="0.8"/>'
				+ '<path d="M 40 83 C 41 70, 48 60, 56 52" fill="none" stroke="' + hi + '" stroke-width="3.0" stroke-linecap="round" stroke-opacity="0.75"/>'
				# Глаз и ноздря (резные детали)
				+ '<circle cx="48" cy="30" r="3.2" fill="' + eye + '"/>'
				+ '<circle cx="31" cy="42" r="2.0" fill="' + st + '"/>'
			)

		GameState.QUEEN:
			# Ферзь Стаунтон: изящная корона с 5 плавными зубцами и жемчужинами на вершинах
			art = (
				# Внутренний бархатный купол короны
				'<path d="M 36 46 C 36 26, 92 26, 92 46 L 86 89 L 42 89 Z" fill="' + c_collar + '" stroke="' + st + '" stroke-width="3.6"/>'
				# Главная 5-зубчатая корона с плавными выемками
				+ '<path d="M 34 89 L 22 36 C 31 48, 39 48, 43 24 C 50 44, 57 44, 64 19 C 71 44, 78 44, 85 24 C 89 48, 97 48, 106 36 L 94 89 Z" fill="' + c_main + '"/>'
				# Теневая правая половина короны
				+ '<path d="M 64 19 C 71 44, 78 44, 85 24 C 89 48, 97 48, 106 36 L 94 89 L 61 89 Z" fill="' + c_shade + '"/>'
				+ '<path d="M 34 89 L 22 36 C 31 48, 39 48, 43 24 C 50 44, 57 44, 64 19 C 71 44, 78 44, 85 24 C 89 48, 97 48, 106 36 L 94 89 Z" fill="none" stroke="' + st + '" stroke-width="4.2" stroke-linejoin="round"/>'
				# Рельефные складки корпуса
				+ '<line x1="48" y1="54" x2="50" y2="83" stroke="' + st + '" stroke-width="2.8" stroke-linecap="round" stroke-opacity="0.45"/>'
				+ '<line x1="64" y1="50" x2="64" y2="83" stroke="' + st + '" stroke-width="2.8" stroke-linecap="round" stroke-opacity="0.45"/>'
				+ '<line x1="80" y1="54" x2="78" y2="83" stroke="' + st + '" stroke-width="2.8" stroke-linecap="round" stroke-opacity="0.45"/>'
				# 5 точёных жемчужин на остриях короны
				+ '<circle cx="21" cy="31" r="4.8" fill="' + c_collar + '" stroke="' + st + '" stroke-width="3.0"/>'
				+ '<circle cx="43" cy="19" r="5.2" fill="' + c_collar + '" stroke="' + st + '" stroke-width="3.0"/>'
				+ '<circle cx="64" cy="14" r="5.8" fill="' + c_collar + '" stroke="' + st + '" stroke-width="3.2"/>'
				+ '<circle cx="85" cy="19" r="5.2" fill="' + c_collar + '" stroke="' + st + '" stroke-width="3.0"/>'
				+ '<circle cx="107" cy="31" r="4.8" fill="' + c_collar + '" stroke="' + st + '" stroke-width="3.0"/>'
			)

		GameState.KING:
			# Король Стаунтон: величественная корона с арочным сводом и геральдическим крестом (Cross Patee)
			art = (
				# Геральдический крест Стаунтон на вершине
				'<path d="M 58 6 L 70 6 L 68 14 L 76 12 L 76 23 L 68 21 L 69 30 L 59 30 L 60 21 L 52 23 L 52 12 L 60 14 Z" fill="' + c_collar + '" stroke="' + st + '" stroke-width="3.6" stroke-linejoin="round"/>'
				# Внутренний свод короны
				+ '<path d="M 33 48 C 33 25, 95 25, 95 48 L 88 89 L 40 89 Z" fill="' + c_collar + '" stroke="' + st + '" stroke-width="3.8"/>'
				# Основной корпус короны Монарха
				+ '<path d="M 33 89 L 25 44 C 38 38, 51 40, 64 49 C 77 40, 90 38, 103 44 L 95 89 Z" fill="' + c_main + '"/>'
				+ '<path d="M 64 49 C 77 40, 90 38, 103 44 L 95 89 L 62 89 Z" fill="' + c_shade + '"/>'
				+ '<path d="M 33 89 L 25 44 C 38 38, 51 40, 64 49 C 77 40, 90 38, 103 44 L 95 89 Z" fill="none" stroke="' + st + '" stroke-width="4.2" stroke-linejoin="round"/>'
				# Пояс короны с 3 заклёпками
				+ '<rect x="33" y="73" width="62" height="7" rx="3" fill="' + c_collar + '" stroke="' + st + '" stroke-width="3.2"/>'
				+ '<circle cx="48" cy="76.5" r="2.2" fill="' + st + '"/>'
				+ '<circle cx="64" cy="76.5" r="2.2" fill="' + st + '"/>'
				+ '<circle cx="80" cy="76.5" r="2.2" fill="' + st + '"/>'
				# Световой блик на левом крыле короны
				+ '<path d="M 32 50 L 38 82" stroke="' + hi + '" stroke-width="3.0" stroke-linecap="round" stroke-opacity="0.75"/>'
			)

		GameState.UNICORN:
			# Единорог: изящный геральдический скакун с длинным витым рогом
			art = (
				# Развевающаяся грива
				'<path d="M 72 24 C 92 30, 100 48, 95 89 L 76 89 Z" fill="' + c_collar + '" stroke="' + st + '" stroke-width="3.6" stroke-linejoin="round"/>'
				# Длинный прямой витой рог
				+ '<polygon points="48,27 14,5 59,19" fill="' + c_collar + '" stroke="' + st + '" stroke-width="3.6" stroke-linejoin="round"/>'
				+ '<line x1="27" y1="13" x2="36" y2="18" stroke="' + st + '" stroke-width="2.6" stroke-linecap="round"/>'
				+ '<line x1="38" y1="19" x2="47" y2="24" stroke="' + st + '" stroke-width="2.6" stroke-linecap="round"/>'
				# Профиль головы и шеи единорога
				+ '<path d="M 35 89 C 35 68, 45 57, 54 49 C 43 51, 32 54, 27 47 C 23 42, 28 34, 43 27 L 58 19 L 72 11 L 74 24 C 87 34, 90 56, 86 89 Z" fill="' + c_main + '"/>'
				+ '<path d="M 72 24 C 87 34, 90 56, 86 89 L 59 89 C 63 67, 65 50, 61 35 L 46 43 C 50 37, 58 31, 65 25 Z" fill="' + c_shade + '"/>'
				+ '<path d="M 35 89 C 35 68, 45 57, 54 49 C 43 51, 32 54, 27 47 C 23 42, 28 34, 43 27 L 58 19 L 72 11 L 74 24 C 87 34, 90 56, 86 89 Z" fill="none" stroke="' + st + '" stroke-width="4.2" stroke-linejoin="round"/>'
				+ '<circle cx="49" cy="31" r="3.0" fill="' + eye + '"/>'
				+ '<path d="M 41 83 C 42 70, 49 60, 57 52" fill="none" stroke="' + hi + '" stroke-width="3.0" stroke-linecap="round" stroke-opacity="0.75"/>'
			)

		GameState.DRAGON:
			# Дракон: геральдический крылатый змей в профиль с гребнем, рогами и сложенным крылом
			art = (
				# Сложенное перепончатое крыло за спиной
				'<path d="M 62 46 L 108 20 C 102 36, 104 46, 112 54 C 100 58, 98 68, 104 78 C 92 78, 84 82, 82 89 L 60 89 Z" fill="' + c_collar + '" stroke="' + st + '" stroke-width="3.8" stroke-linejoin="round"/>'
				+ '<path d="M 74 52 L 104 49 M 72 66 L 98 68" stroke="' + st + '" stroke-width="2.8" stroke-linecap="round"/>'
				# Загнутый назад рог дракона
				+ '<path d="M 55 18 L 86 7 L 70 25 Z" fill="' + c_collar + '" stroke="' + st + '" stroke-width="3.6" stroke-linejoin="round"/>'
				# Змеиная шея и хищная пасть дракона
				+ '<path d="M 32 89 C 30 66, 38 52, 47 44 L 24 44 C 21 38, 26 31, 38 27 L 54 17 L 68 23 C 62 33, 58 43, 62 55 C 66 67, 74 75, 76 89 Z" fill="' + c_main + '"/>'
				+ '<path d="M 54 17 L 68 23 C 62 33, 58 43, 62 55 C 66 67, 74 75, 76 89 L 52 89 C 49 71, 48 56, 54 39 L 36 39 Z" fill="' + c_shade + '"/>'
				+ '<path d="M 32 89 C 30 66, 38 52, 47 44 L 24 44 C 21 38, 26 31, 38 27 L 54 17 L 68 23 C 62 33, 58 43, 62 55 C 66 67, 74 75, 76 89 Z" fill="none" stroke="' + st + '" stroke-width="4.2" stroke-linejoin="round"/>'
				# Глаз дракона и пластины на груди
				+ '<circle cx="46" cy="29" r="3.0" fill="' + eye + '"/>'
				+ '<path d="M 37 82 C 36 67, 41 55, 49 47" fill="none" stroke="' + hi + '" stroke-width="3.0" stroke-linecap="round" stroke-opacity="0.75"/>'
			)

		GameState.PRINCESS:
			# Принцесса (Архиепископ): стройная фигура с боковыми крыльями-лепестками и 3-лучевой тиарой
			art = (
				# Боковые резные крылья-вольюты
				'<path d="M 43 76 C 24 66, 18 46, 26 28 C 34 38, 41 47, 46 56 Z" fill="' + c_collar + '" stroke="' + st + '" stroke-width="3.6" stroke-linejoin="round"/>'
				+ '<path d="M 85 76 C 104 66, 110 46, 102 28 C 94 38, 87 47, 82 56 Z" fill="' + c_collar_sh + '" stroke="' + st + '" stroke-width="3.6" stroke-linejoin="round"/>'
				# Стройный силуэт с 3 высокими лучами тиары
				+ '<path d="M 36 89 C 39 69, 44 54, 43 30 L 56 45 L 64 16 L 72 45 L 85 30 C 84 54, 89 69, 92 89 Z" fill="' + c_main + '"/>'
				+ '<path d="M 64 16 L 72 45 L 85 30 C 84 54, 89 69, 92 89 L 62 89 Z" fill="' + c_shade + '"/>'
				+ '<path d="M 36 89 C 39 69, 44 54, 43 30 L 56 45 L 64 16 L 72 45 L 85 30 C 84 54, 89 69, 92 89 Z" fill="none" stroke="' + st + '" stroke-width="4.2" stroke-linejoin="round"/>'
				# Поясок-перехват на талии
				+ '<rect x="44" y="65" width="40" height="6" rx="3" fill="' + c_collar + '" stroke="' + st + '" stroke-width="3.2"/>'
				# Жемчужины на вершине тиары
				+ '<circle cx="64" cy="12" r="5.0" fill="' + c_collar + '" stroke="' + st + '" stroke-width="3.0"/>'
				+ '<circle cx="43" cy="26" r="4.0" fill="' + c_collar + '" stroke="' + st + '" stroke-width="2.8"/>'
				+ '<circle cx="85" cy="26" r="4.0" fill="' + c_collar + '" stroke="' + st + '" stroke-width="2.8"/>'
			)

	return (
		'<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">'
		+ ground_shadow
		+ base_pedestal
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
		var draw_rect := rect.grow(-rect.size.x * 0.04)
		ci.draw_texture_rect(tex, draw_rect, false, Color(1.0, 1.0, 1.0, alpha))


static func draw_multi_piece(ci: CanvasItem, piece_type: int, player_id: int, rect: Rect2, alpha: float = 1.0, override_skin: String = "") -> void:
	if piece_type == MultiChessState.EMPTY:
		return
	var skin_id: String = override_skin if override_skin != "" else Profile.active_skin
	var army_id: int = clampi(player_id, 0, 3)

	var tex := _get_piece_texture(piece_type, army_id, skin_id)
	if tex != null:
		var draw_rect := rect.grow(-rect.size.x * 0.04)
		ci.draw_texture_rect(tex, draw_rect, false, Color(1.0, 1.0, 1.0, alpha))
