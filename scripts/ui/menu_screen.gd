class_name MenuScreen
extends Control
## Главное меню: лаконичный тактический интерфейс, настройка партий, сетевое лобби и коллекция скинов.

signal start_game(variant_id: String, mode: String, color: int, ai_level: int, initial_turns: Array)
signal start_multi_game(sub_mode: String, is_pass_and_play: bool, color: int, ai_level: int, net_instance: Net, slots: Array, is_d20: bool)
signal start_puzzle_game(puzzle_data: Dictionary)

var net: Net
var sfx: Sfx

var _current_tab: int = 0
var _anim_time: float = 0.0

# Настройки партии 5D
var _selected_mode: String = GameScreen.MODE_AI
var _variant_idx: int = 0
var _color_choice: int = 0 # 0 — белые, 1 — чёрные, 2 — случайно
var _ai_level: int = ChessAI.NORMAL

# Настройки мульти-шахмат без путешествий во времени (1х1х1, 2х2, 1х1х1х1)
var _multi_chess_sub_mode: String = MultiChessState.MODE_1V1V1
var _multi_chess_pass_and_play: bool = false
var _multi_chess_color: int = MultiChessState.WHITE
var _multi_chess_ai_level: int = MultiChessAI.LEVEL_NORMAL
var _multi_sub_mode_btns: Array = []
var _multi_color_btns: Array = []
var _multi_diff_btns: Array = []
var _multi_blue_btn_ref: Button = null
var _multi_sub_mode_box: BoxContainer
var _multi_ctrl_box: BoxContainer
var _multi_col_row: BoxContainer
var _multi_col_lbl: Label
var _multi_diff_row: BoxContainer
var _multi_diff_lbl: Label

# Настройки режима D20 Битва (Мини-геймс)
var _d20_sub_mode: String = MultiChessState.MODE_1V1V1
var _d20_play_mode: int = 0 # 0 — против ботов, 1 — Pass & Play, 2 — онлайн лобби
var _d20_color: int = MultiChessState.WHITE
var _d20_ai_level: int = MultiChessAI.LEVEL_NORMAL
var _d20_sub_mode_btns: Array = []
var _d20_color_btns: Array = []
var _d20_diff_btns: Array = []
var _d20_blue_btn_ref: Button = null
var _d20_bot_options_box: VBoxContainer = null
var _d20_launch_btn_ref: Button = null
var _d20_preset_box: BoxContainer = null
var _d20_mode_box: BoxContainer = null
var _d20_col_row: BoxContainer = null

# Настройки сетевого создания комнат
var _net_game_type: String = "5d" # "5d", "multi" или "d20_multi"
var _net_multi_sub_mode: String = MultiChessState.MODE_1V1V1
var _net_multi_color: int = MultiChessState.WHITE
var _net_type_btns: Array = []
var _net_multi_options_box: Control
var _net_multi_sub_btns: Array = []
var _net_multi_color_btns: Array = []
var _net_multi_blue_btn: Button
var _lobby_info_label: Label
var _lobby_players_box: VBoxContainer
var _lobby_start_btn: Button

# Ссылки на элементы UI
var _scroll_container: ScrollContainer
var _margin_container: MarginContainer
var _root_container: VBoxContainer
var _title_label: Label
var _tab_buttons: Array = []
var _tab_containers: Array = []
var _mode_box: BoxContainer
var _diff_row: BoxContainer
var _diff_lbl: Label
var _col_row: BoxContainer
var _col_lbl: Label
var _var_header: BoxContainer
var _var_title: Label
var _variant_desc_label: Label
var _variant_select_btn: OptionButton
var _ai_buttons: Array = []
var _color_buttons: Array = []
var _mode_buttons: Array = []
var _start_btn: Button
var _ai_settings_box: VBoxContainer

# Сетевой UI
var _multi_online_mode: bool = true
var _multi_mode_btns: Array = []
var _code_row: BoxContainer
var _room_code_input: LineEdit
var _name_row: BoxContainer
var _room_name_input: LineEdit
var _host_code_label: Label
var _host_panel: PanelContainer
var _net_status_label: Label
var _server_list_container: VBoxContainer
var _no_servers_label: Label
var _sfx_btn_ref: Button
var _scale_btn_ref: Button
var _top_bar: PanelContainer
var _bottom_dock: PanelContainer
var _profile_chip_ref: Button
var _multi_launch_btn_ref: Button
var _hero_badge_lbl: Label
var _hero_title_lbl: Label
var _hero_subtitle_lbl: Label

# Профиль UI
var _crystal_badge_btn: Button
var _quests_container: VBoxContainer
var _puzzles_container: VBoxContainer
var _proc_diff: int = 1
var _proc_diff_btns: Array = []
var _skins_container: VBoxContainer
var _profile_avatar_preview: PieceButton
var _profile_name_edit: LineEdit
var _profile_title_lbl: Label
var _profile_rating_lbl: Label
var _profile_stats_lbl: Label
var _profile_winrate_lbl: Label
var _profile_streaks_lbl: Label
var _profile_5d_lbl: Label
var _avatar_piece_btns: Array = []
var _profile_header_box: BoxContainer

# Спокойные фоновые звёзды
var _stars: Array = []


func setup(p_net: Net, p_sfx: Sfx) -> void:
	net = p_net
	sfx = p_sfx
	if net != null:
		net.game_started.connect(_on_net_game_started)
		net.multi_game_started.connect(_on_net_multi_game_started)
		net.room_lobby_updated.connect(_on_net_room_lobby_updated)
		net.reconnected_to_match.connect(_on_net_reconnected)
		net.disconnected.connect(_on_net_disconnected)
		net.server_list_updated.connect(_on_server_list_updated)
		net.room_created.connect(_on_net_room_created)
		net.status_message.connect(_on_net_status_message)


func _exit_tree() -> void:
	if get_viewport() != null and get_viewport().size_changed.is_connected(_on_viewport_resized):
		get_viewport().size_changed.disconnect(_on_viewport_resized)
	if net != null:
		if net.game_started.is_connected(_on_net_game_started):
			net.game_started.disconnect(_on_net_game_started)
			net.multi_game_started.disconnect(_on_net_multi_game_started)
			net.room_lobby_updated.disconnect(_on_net_room_lobby_updated)
			net.reconnected_to_match.disconnect(_on_net_reconnected)
			net.disconnected.disconnect(_on_net_disconnected)
			net.server_list_updated.disconnect(_on_server_list_updated)
			net.room_created.disconnect(_on_net_room_created)
			net.status_message.disconnect(_on_net_status_message)
		net.stop_lan_discovery()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip_contents = true

	var rng := RandomNumberGenerator.new()
	rng.seed = 404
	var star_colors := [
		Color(0.88, 0.92, 0.98),
		Color(0.68, 0.82, 0.96),
		Color(0.96, 0.88, 0.72),
	]
	for i in 65:
		_stars.append({
			"pos": Vector2(rng.randf(), rng.randf()),
			"size": rng.randf_range(0.8, 1.8),
			"alpha": rng.randf_range(0.10, 0.35),
			"speed": rng.randf_range(0.5, 1.4),
			"phase": rng.randf_range(0.0, TAU),
			"color": star_colors[rng.randi() % star_colors.size()],
		})

	_build_ui()
	_switch_tab(0)

	get_viewport().size_changed.connect(_on_viewport_resized)
	_on_viewport_resized()


func _process(delta: float) -> void:
	_anim_time += delta
	queue_redraw()


# ---------------------------------------------------------------- Отрисовка фона

func _draw() -> void:
	# Глубокий графитово-сланцевый фон (#0B0F19)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.043, 0.059, 0.098))

	# Мягкое атмосферное свечение сверху и снизу без отвлекающих сеток и радаров
	var pulse: float = sin(_anim_time * 0.4) * 0.01 + 0.045
	draw_circle(Vector2(size.x * 0.5, size.y * 0.08), size.x * 0.65, Color(0.14, 0.24, 0.44, pulse))
	draw_circle(Vector2(size.x * 0.8, size.y * 0.88), size.x * 0.50, Color(0.10, 0.16, 0.30, pulse * 0.7))

	for s in _stars:
		var sp := Vector2(s["pos"].x * size.x, s["pos"].y * size.y)
		var twinkle: float = sin(_anim_time * float(s["speed"]) + float(s["phase"])) * 0.25 + 0.75
		var base_col: Color = s["color"]
		var col := Color(base_col.r, base_col.g, base_col.b, float(s["alpha"]) * twinkle)
		draw_circle(sp, float(s["size"]), col)


# ---------------------------------------------------------------- Построение интерфейса

func _build_ui() -> void:
	# 1. Основной скроллируемый вьюпорт
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.scroll_deadzone = 20
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(scroll)
	_scroll_container = scroll

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	scroll.add_child(margin)
	_margin_container = margin

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 14)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.add_child(root)
	_root_container = root

	# Лаконичный заголовок текущего раздела (вместо громоздкого дублирующего баннера)
	var header_box := VBoxContainer.new()
	header_box.add_theme_constant_override("separation", 3)
	root.add_child(header_box)

	var hero_title := Label.new()
	hero_title.text = "5D Хроно-шахматы"
	hero_title.add_theme_font_size_override("font_size", 21)
	hero_title.add_theme_color_override("font_color", Color(0.95, 0.96, 0.98))
	header_box.add_child(hero_title)
	_hero_title_lbl = hero_title

	var hero_sub := Label.new()
	hero_sub.text = "Классические и мультивселенные партии с прыжками сквозь время"
	hero_sub.add_theme_font_size_override("font_size", 13)
	hero_sub.add_theme_color_override("font_color", Color(0.56, 0.64, 0.76))
	hero_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header_box.add_child(hero_sub)
	_hero_subtitle_lbl = hero_sub

	var tab_stack := VBoxContainer.new()
	tab_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(tab_stack)

	var tab0: Control = _build_singleplayer_tab()
	var tab_multi: Control = _build_multi_tab()
	var tab_puzzle: Control = _build_puzzles_tab()
	var tab1: Control = _build_multiplayer_tab()
	var tab2: Control = _build_profile_tab()
	var tab3: Control = _build_rules_tab()

	tab_stack.add_child(tab0)
	tab_stack.add_child(tab_multi)
	tab_stack.add_child(tab_puzzle)
	tab_stack.add_child(tab1)
	tab_stack.add_child(tab2)
	tab_stack.add_child(tab3)

	_tab_containers = [tab0, tab_multi, tab_puzzle, tab1, tab2, tab3]

	# 2. Верхняя фиксированная панель (Top App Bar)
	var top_bar := PanelContainer.new()
	top_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(top_bar)
	_top_bar = top_bar

	var top_hb := HBoxContainer.new()
	top_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	top_hb.add_theme_constant_override("separation", 8)
	top_bar.add_child(top_hb)

	var title := Label.new()
	title.text = "CHRONO CHESS 5D"
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color(0.92, 0.90, 0.84))
	top_hb.add_child(title)
	_title_label = title

	var top_spacer := Control.new()
	top_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hb.add_child(top_spacer)

	# Плашка рейтинга игрока
	var profile_chip := _pill_action_btn("%d ELO" % Profile.rating, func(): _switch_tab(4))
	_profile_chip_ref = profile_chip
	top_hb.add_child(profile_chip)

	# Баланс кристаллов
	var crystal_btn := _pill_action_btn("◆ %d" % Profile.crystals, func(): _switch_tab(4))
	_crystal_badge_btn = crystal_btn
	top_hb.add_child(crystal_btn)

	# Переключатель звука
	var sfx_btn := _icon_action_btn("Звук" if (sfx == null or sfx.enabled) else "Без зв.", func():
		if sfx != null:
			var on: bool = sfx.toggle()
			_sfx_btn_ref.text = "Звук" if on else "Без зв."
			if on:
				sfx.play("move"))
	_sfx_btn_ref = sfx_btn
	top_hb.add_child(sfx_btn)

	# Масштаб интерфейса
	var scale_btn := _icon_action_btn("Масштаб", func():
		Settings.cycle_ui_scale(get_window())
		if sfx != null:
			sfx.play("click"))
	_scale_btn_ref = scale_btn
	top_hb.add_child(scale_btn)

	# 3. Нижняя навигационная панель (Bottom Navigation Bar)
	var bottom_dock := PanelContainer.new()
	bottom_dock.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_dock.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bottom_dock.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bottom_dock)
	_bottom_dock = bottom_dock

	var dock_hb := HBoxContainer.new()
	dock_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	dock_hb.add_theme_constant_override("separation", 6)
	bottom_dock.add_child(dock_hb)

	_tab_buttons.append(_create_tab_btn("5D", 0, dock_hb))
	_tab_buttons.append(_create_tab_btn("Мульти", 1, dock_hb))
	_tab_buttons.append(_create_tab_btn("D20 и задачи", 2, dock_hb))
	_tab_buttons.append(_create_tab_btn("Сеть", 3, dock_hb))
	_tab_buttons.append(_create_tab_btn("Профиль", 4, dock_hb))
	_tab_buttons.append(_create_tab_btn("Правила", 5, dock_hb))

	_switch_tab(0)


func _on_viewport_resized() -> void:
	_adapt_ui(get_viewport_rect().size)
	if _current_tab == 2:
		_refresh_puzzles_and_quests_ui()
	elif _current_tab == 4:
		_refresh_profile_ui()


func _adapt_ui(vp_size: Vector2) -> void:
	if _margin_container == null or _root_container == null:
		return
	var insets := Settings.safe_insets(vp_size)
	var w: float = vp_size.x
	var h: float = vp_size.y
	var is_compact: bool = w < 840.0 or h < 560.0
	var is_phone_portrait: bool = (w < 640.0 and h >= w) or (w < 520.0)

	var top_pad: float = maxf(6.0, insets.top)
	var bottom_pad: float = maxf(6.0, insets.bottom)
	var left_pad: float = maxf(10.0, insets.left + 6.0)
	var right_pad: float = maxf(10.0, insets.right + 6.0)

	# 1. Верхняя панель
	if _top_bar != null:
		var top_sb := StyleBoxFlat.new()
		top_sb.bg_color = Color(0.055, 0.075, 0.125, 0.96)
		top_sb.border_color = Color(0.14, 0.19, 0.28, 0.90)
		top_sb.border_width_bottom = 1
		top_sb.content_margin_top = int(top_pad + 4.0)
		top_sb.content_margin_bottom = 8
		top_sb.content_margin_left = int(left_pad + 6.0)
		top_sb.content_margin_right = int(right_pad + 6.0)
		_top_bar.add_theme_stylebox_override("panel", top_sb)

	# 2. Нижняя навигационная панель
	if _bottom_dock != null:
		var dock_sb := StyleBoxFlat.new()
		dock_sb.bg_color = Color(0.055, 0.075, 0.125, 0.98)
		dock_sb.border_color = Color(0.14, 0.19, 0.28, 0.90)
		dock_sb.border_width_top = 1
		dock_sb.content_margin_top = 6
		dock_sb.content_margin_bottom = int(bottom_pad + 6.0)
		dock_sb.content_margin_left = int(left_pad + 4.0)
		dock_sb.content_margin_right = int(right_pad + 4.0)
		_bottom_dock.add_theme_stylebox_override("panel", dock_sb)

	var top_bar_h: float = 48.0 + top_pad
	var bottom_dock_h: float = 56.0 + bottom_pad

	var avail_w: float = w - (left_pad + right_pad)
	if avail_w > 720.0:
		var side_margin: int = int((w - 720.0) / 2.0)
		_margin_container.add_theme_constant_override("margin_left", side_margin)
		_margin_container.add_theme_constant_override("margin_right", side_margin)
	else:
		_margin_container.add_theme_constant_override("margin_left", int(left_pad))
		_margin_container.add_theme_constant_override("margin_right", int(right_pad))

	_margin_container.add_theme_constant_override("margin_top", int(top_bar_h + 12.0))
	_margin_container.add_theme_constant_override("margin_bottom", int(bottom_dock_h + 16.0))
	_root_container.custom_minimum_size.x = 0

	if _title_label != null:
		_title_label.text = "CHRONO CHESS" if is_phone_portrait else "CHRONO CHESS 5D"
		_title_label.add_theme_font_size_override("font_size", 14 if is_phone_portrait else 15)

	if _hero_title_lbl != null:
		_hero_title_lbl.add_theme_font_size_override("font_size", 19 if is_phone_portrait else 22)

	if _profile_chip_ref != null:
		_profile_chip_ref.visible = (w >= 360.0)
	if _scale_btn_ref != null:
		_scale_btn_ref.visible = (w >= 420.0)

	# Навигационные вкладки
	if _tab_buttons.size() >= 6:
		if is_phone_portrait:
			_tab_buttons[0].text = "5D"
			_tab_buttons[1].text = "Мульти"
			_tab_buttons[2].text = "D20"
			_tab_buttons[3].text = "Сеть"
			_tab_buttons[4].text = "Профиль"
			_tab_buttons[5].text = "Правила"
			for b in _tab_buttons:
				b.add_theme_font_size_override("font_size", 11)
				b.custom_minimum_size.y = 42
		elif is_compact:
			_tab_buttons[0].text = "5D"
			_tab_buttons[1].text = "Мульти"
			_tab_buttons[2].text = "D20 и задачи"
			_tab_buttons[3].text = "Сеть"
			_tab_buttons[4].text = "Профиль"
			_tab_buttons[5].text = "Правила"
			for b in _tab_buttons:
				b.add_theme_font_size_override("font_size", 12)
				b.custom_minimum_size.y = 42
		else:
			_tab_buttons[0].text = "5D Шахматы"
			_tab_buttons[1].text = "Мульти 14×14"
			_tab_buttons[2].text = "D20 и задачи"
			_tab_buttons[3].text = "Сетевая игра"
			_tab_buttons[4].text = "Профиль и скины"
			_tab_buttons[5].text = "Правила"
			for b in _tab_buttons:
				b.add_theme_font_size_override("font_size", 13)
				b.custom_minimum_size.y = 44

	# Адаптация строк формы
	if _profile_header_box != null:
		_profile_header_box.vertical = is_compact
	if _diff_row != null:
		_diff_row.vertical = is_phone_portrait
		_diff_lbl.custom_minimum_size.x = 0 if is_phone_portrait else 150
	if _col_row != null:
		_col_row.vertical = is_phone_portrait
		_col_lbl.custom_minimum_size.x = 0 if is_phone_portrait else 150
	if _var_header != null:
		_var_header.vertical = is_phone_portrait
		_var_title.custom_minimum_size.x = 0 if is_phone_portrait else 150
	if _code_row != null:
		_code_row.vertical = is_phone_portrait
	if _name_row != null:
		_name_row.vertical = is_phone_portrait
	if _multi_sub_mode_box != null:
		_multi_sub_mode_box.vertical = is_phone_portrait
	if _multi_ctrl_box != null:
		_multi_ctrl_box.vertical = is_phone_portrait
	if _multi_col_row != null:
		_multi_col_row.vertical = is_phone_portrait
		if _multi_col_lbl != null:
			_multi_col_lbl.custom_minimum_size.x = 0 if is_phone_portrait else 150
	if _multi_diff_row != null:
		_multi_diff_row.vertical = is_phone_portrait
		if _multi_diff_lbl != null:
			_multi_diff_lbl.custom_minimum_size.x = 0 if is_phone_portrait else 150
	if _d20_preset_box != null:
		_d20_preset_box.vertical = is_phone_portrait
	if _d20_mode_box != null:
		_d20_mode_box.vertical = is_phone_portrait
	if _d20_col_row != null:
		_d20_col_row.vertical = is_phone_portrait


func _create_tab_btn(label: String, tab_idx: int, parent: Control) -> Button:
	var b := Button.new()
	b.text = label
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 42)
	b.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.add_theme_font_size_override("font_size", 12)
	b.pressed.connect(func():
		_switch_tab(tab_idx))
	parent.add_child(b)
	return b


func _switch_tab(idx: int) -> void:
	_current_tab = idx
	const TAB_TITLES := [
		"5D Хроно-шахматы",
		"Мульти-шахматы 14×14",
		"D20 Битва и тактические задачи",
		"Сетевая игра",
		"Профиль и коллекция фигур",
		"Справочник правил"
	]
	const TAB_SUBTITLES := [
		"Классические и мультивселенные партии с прыжками во времени и альтернативными линиями",
		"Сражение для 3 или 4 армий на крестообразном поле 14×14 по классическим правилам",
		"Боевые шахматы с броском 20-гранного кубика, генератор матовых задач и ежедневные цели",
		"Подключение по коду комнаты, создание лобби на 2 игроков и список открытых залов",
		"Личная статистика, выбор гербового аватара и наборы стилизованных фигур",
		"Краткое руководство по временным осям, фигурам 5D и режимам на 4 игроков"
	]
	if _hero_title_lbl != null and idx >= 0 and idx < TAB_TITLES.size():
		_hero_title_lbl.text = TAB_TITLES[idx]
	if _hero_subtitle_lbl != null and idx >= 0 and idx < TAB_SUBTITLES.size():
		_hero_subtitle_lbl.text = TAB_SUBTITLES[idx]

	for i in _tab_containers.size():
		var c: Control = _tab_containers[i]
		c.visible = (i == idx)
		if i < _tab_buttons.size():
			var b: Button = _tab_buttons[i]
			var is_active := (i == idx)

			var sb := StyleBoxFlat.new()
			if is_active:
				sb.bg_color = Color(0.14, 0.25, 0.48, 0.98)
				sb.border_color = Color(0.35, 0.62, 0.98, 0.95)
				sb.set_border_width_all(1)
				b.add_theme_color_override("font_color", Color.WHITE)
			else:
				sb.bg_color = Color(0.08, 0.11, 0.18, 0.0)
				sb.border_color = Color(0.16, 0.22, 0.34, 0.0)
				sb.set_border_width_all(0)
				b.add_theme_color_override("font_color", Color(0.58, 0.66, 0.78))
			sb.set_corner_radius_all(8)
			sb.content_margin_left = 6
			sb.content_margin_right = 6
			sb.content_margin_top = 6
			sb.content_margin_bottom = 6
			b.add_theme_stylebox_override("normal", sb)

			var hover := sb.duplicate()
			if not is_active:
				hover.bg_color = Color(0.10, 0.14, 0.24, 0.85)
			b.add_theme_stylebox_override("hover", hover)

			var pressed_sb := sb.duplicate()
			pressed_sb.bg_color = Color(0.16, 0.28, 0.54, 0.98)
			b.add_theme_stylebox_override("pressed", pressed_sb)

	if _scroll_container != null:
		_scroll_container.scroll_vertical = 0

	_update_crystals_display()

	if idx == 2:
		_refresh_puzzles_and_quests_ui()
	elif idx == 3:
		if net != null:
			if _multi_online_mode:
				net.connect_online()
			else:
				net.start_lan_discovery()
	elif idx == 4:
		_refresh_profile_ui()
	else:
		if net != null and not net.is_host:
			net.stop_lan_discovery()


# ---------------------------------------------------------------- Вкладка 0: 5D Хроно-шахматы

func _build_singleplayer_tab() -> Control:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)

	# Единая собранная карточка параметров партии (без дробления на 4 разных блока)
	var setup_card := PanelContainer.new()
	setup_card.add_theme_stylebox_override("panel", _glass_panel_style(12))
	vb.add_child(setup_card)

	var form_vb := VBoxContainer.new()
	form_vb.add_theme_constant_override("separation", 16)
	setup_card.add_child(form_vb)

	# 1. Формат игры
	var mode_section := VBoxContainer.new()
	mode_section.add_theme_constant_override("separation", 8)
	form_vb.add_child(mode_section)

	mode_section.add_child(_field_label("Режим игры"))

	_mode_box = BoxContainer.new()
	_mode_box.vertical = false
	_mode_box.add_theme_constant_override("separation", 8)
	mode_section.add_child(_mode_box)

	var btn_ai := _create_selectable_btn("Против ИИ", true)
	var btn_local := _create_selectable_btn("Вдвоём на экране", false)
	_mode_box.add_child(btn_ai)
	_mode_box.add_child(btn_local)
	_mode_buttons = [btn_ai, btn_local]

	btn_ai.pressed.connect(func():
		_selected_mode = GameScreen.MODE_AI
		_update_mode_buttons()
		_ai_settings_box.visible = true)
	btn_local.pressed.connect(func():
		_selected_mode = GameScreen.MODE_LOCAL
		_update_mode_buttons()
		_ai_settings_box.visible = false)

	# 2. Настройки соперника и стороны
	_ai_settings_box = VBoxContainer.new()
	_ai_settings_box.add_theme_constant_override("separation", 12)
	form_vb.add_child(_ai_settings_box)

	_diff_row = BoxContainer.new()
	_diff_row.vertical = false
	_diff_row.add_theme_constant_override("separation", 10)
	_ai_settings_box.add_child(_diff_row)

	_diff_lbl = _field_label("Сложность ИИ")
	_diff_lbl.custom_minimum_size.x = 150
	_diff_row.add_child(_diff_lbl)

	var diff_btns_box := HBoxContainer.new()
	diff_btns_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	diff_btns_box.add_theme_constant_override("separation", 8)
	_diff_row.add_child(diff_btns_box)

	var b_easy := _create_selectable_btn("Новичок", _ai_level == ChessAI.EASY)
	var b_norm := _create_selectable_btn("Мастер", _ai_level == ChessAI.NORMAL)
	var b_hard := _create_selectable_btn("Грандмастер", _ai_level == ChessAI.HARD)
	diff_btns_box.add_child(b_easy)
	diff_btns_box.add_child(b_norm)
	diff_btns_box.add_child(b_hard)
	_ai_buttons = [b_easy, b_norm, b_hard]

	var ai_desc_lbl := Label.new()
	ai_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ai_desc_lbl.add_theme_font_size_override("font_size", 12)
	ai_desc_lbl.add_theme_color_override("font_color", Color(0.56, 0.68, 0.84))
	_ai_settings_box.add_child(ai_desc_lbl)

	var update_ai_desc := func():
		match _ai_level:
			ChessAI.EASY:
				ai_desc_lbl.text = "🤖 Новичок: играет позиционно, но иногда допускает тактические зевки."
			ChessAI.NORMAL:
				ai_desc_lbl.text = "🤖 Мастер: защищает короля на всех досках, видит подставы фигур и темпоральные удары."
			ChessAI.HARD:
				ai_desc_lbl.text = "🤖 Грандмастер: лучевой поиск с просчётом ответов соперника (2-ply) и поиском мата в 1 ход."
	update_ai_desc.call()

	b_easy.pressed.connect(func(): _set_ai_level(ChessAI.EASY); update_ai_desc.call())
	b_norm.pressed.connect(func(): _set_ai_level(ChessAI.NORMAL); update_ai_desc.call())
	b_hard.pressed.connect(func(): _set_ai_level(ChessAI.HARD); update_ai_desc.call())

	_col_row = BoxContainer.new()
	_col_row.vertical = false
	_col_row.add_theme_constant_override("separation", 10)
	_ai_settings_box.add_child(_col_row)

	_col_lbl = _field_label("Ваша сторона")
	_col_lbl.custom_minimum_size.x = 150
	_col_row.add_child(_col_lbl)

	var col_btns_box := HBoxContainer.new()
	col_btns_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_btns_box.add_theme_constant_override("separation", 8)
	_col_row.add_child(col_btns_box)

	var b_white := _create_selectable_btn("Белые", _color_choice == 0)
	var b_black := _create_selectable_btn("Чёрные", _color_choice == 1)
	var b_rnd := _create_selectable_btn("Случайно", _color_choice == 2)
	col_btns_box.add_child(b_white)
	col_btns_box.add_child(b_black)
	col_btns_box.add_child(b_rnd)
	_color_buttons = [b_white, b_black, b_rnd]

	b_white.pressed.connect(func(): _set_color_choice(0))
	b_black.pressed.connect(func(): _set_color_choice(1))
	b_rnd.pressed.connect(func(): _set_color_choice(2))

	form_vb.add_child(_divider())

	# 3. Выбор расстановки и доски
	var var_vb := VBoxContainer.new()
	var_vb.add_theme_constant_override("separation", 8)
	form_vb.add_child(var_vb)

	_var_header = BoxContainer.new()
	_var_header.vertical = false
	_var_header.add_theme_constant_override("separation", 10)
	var_vb.add_child(_var_header)

	_var_title = _field_label("Расстановка")
	_var_title.custom_minimum_size.x = 150
	_var_header.add_child(_var_title)

	_variant_select_btn = OptionButton.new()
	_variant_select_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_variant_select_btn.custom_minimum_size.y = 42
	_variant_select_btn.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	_variant_select_btn.focus_mode = Control.FOCUS_NONE
	_style_option_button(_variant_select_btn)
	for v in Variants.LIST:
		_variant_select_btn.add_item("%s (%d×%d)" % [v["name"], v["w"], v["h"]])
	_variant_select_btn.item_selected.connect(func(i: int):
		_variant_idx = i
		_update_variant_desc())
	_var_header.add_child(_variant_select_btn)

	_variant_desc_label = Label.new()
	_variant_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_variant_desc_label.add_theme_color_override("font_color", Color(0.58, 0.66, 0.78))
	_variant_desc_label.add_theme_font_size_override("font_size", 13)
	var_vb.add_child(_variant_desc_label)
	_update_variant_desc()

	# 4. Главная кнопка запуска
	var start_btn := _create_launch_btn("Начать партию", func():
		_launch(_selected_mode))
	form_vb.add_child(start_btn)
	_start_btn = start_btn

	return vb


func _update_mode_buttons() -> void:
	var is_ai: bool = _selected_mode == GameScreen.MODE_AI
	_set_btn_active(_mode_buttons[0], is_ai)
	_set_btn_active(_mode_buttons[1], not is_ai)


func _set_ai_level(lvl: int) -> void:
	_ai_level = lvl
	for i in _ai_buttons.size():
		_set_btn_active(_ai_buttons[i], i == lvl)


func _set_color_choice(c: int) -> void:
	_color_choice = c
	for i in _color_buttons.size():
		_set_btn_active(_color_buttons[i], i == c)


func _update_variant_desc() -> void:
	if _variant_desc_label != null:
		var v: Dictionary = Variants.LIST[_variant_idx]
		_variant_desc_label.text = v["desc"]


# ---------------------------------------------------------------- Вкладка 1: Мульти-шахматы 14×14

func _build_multi_tab() -> Control:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)

	var setup_card := PanelContainer.new()
	setup_card.add_theme_stylebox_override("panel", _glass_panel_style(12))
	vb.add_child(setup_card)

	var f_vb := VBoxContainer.new()
	f_vb.add_theme_constant_override("separation", 16)
	setup_card.add_child(f_vb)

	# 1. Формат поля
	var fmt_section := VBoxContainer.new()
	fmt_section.add_theme_constant_override("separation", 8)
	f_vb.add_child(fmt_section)

	fmt_section.add_child(_field_label("Формат сражения"))

	var sub_hb := BoxContainer.new()
	sub_hb.vertical = false
	sub_hb.add_theme_constant_override("separation", 8)
	fmt_section.add_child(sub_hb)
	_multi_sub_mode_box = sub_hb

	var btn_3p := _create_selectable_btn("1×1×1 (3 игрока)", _multi_chess_sub_mode == MultiChessState.MODE_1V1V1)
	var btn_2v2 := _create_selectable_btn("2×2 (Команды)", _multi_chess_sub_mode == MultiChessState.MODE_2V2)
	var btn_4ffa := _create_selectable_btn("1×1×1×1 (Каждый за себя)", _multi_chess_sub_mode == MultiChessState.MODE_1V1V1V1)

	for b in [btn_3p, btn_2v2, btn_4ffa]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sub_hb.add_child(b)
	_multi_sub_mode_btns = [btn_3p, btn_2v2, btn_4ffa]

	var sub_desc := Label.new()
	sub_desc.add_theme_font_size_override("font_size", 13)
	sub_desc.add_theme_color_override("font_color", Color(0.58, 0.66, 0.78))
	sub_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fmt_section.add_child(sub_desc)

	var update_sub_desc := func():
		match _multi_chess_sub_mode:
			MultiChessState.MODE_1V1V1:
				sub_desc.text = "Три армии (Белые, Красные, Чёрные) на Юге, Западе и Севере. Каждый сам за себя."
				if _multi_blue_btn_ref != null:
					_multi_blue_btn_ref.visible = false
					if _multi_chess_color == MultiChessState.BLUE:
						_multi_chess_color = MultiChessState.WHITE
						_update_multi_color_btns()
			MultiChessState.MODE_2V2:
				sub_desc.text = "Команда Белые + Чёрные против команды Красные + Синие. Фигуры союзника атаковать нельзя."
				if _multi_blue_btn_ref != null:
					_multi_blue_btn_ref.visible = true
			MultiChessState.MODE_1V1V1V1:
				sub_desc.text = "Четыре армии на крестообразной доске 14×14. Побеждает последний оставшийся король."
				if _multi_blue_btn_ref != null:
					_multi_blue_btn_ref.visible = true

	f_vb.add_child(_divider())

	# 2. Режим управления
	var ctrl_section := VBoxContainer.new()
	ctrl_section.add_theme_constant_override("separation", 8)
	f_vb.add_child(ctrl_section)

	ctrl_section.add_child(_field_label("Управление"))

	var ctrl_hb := BoxContainer.new()
	ctrl_hb.vertical = false
	ctrl_hb.add_theme_constant_override("separation", 8)
	ctrl_section.add_child(ctrl_hb)
	_multi_ctrl_box = ctrl_hb

	var btn_bots := _create_selectable_btn("Против ботов", not _multi_chess_pass_and_play)
	var btn_pass := _create_selectable_btn("На одном экране", _multi_chess_pass_and_play)
	for b in [btn_bots, btn_pass]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ctrl_hb.add_child(b)

	var bot_options_box := VBoxContainer.new()
	bot_options_box.add_theme_constant_override("separation", 12)
	f_vb.add_child(bot_options_box)

	btn_bots.pressed.connect(func():
		_multi_chess_pass_and_play = false
		_set_btn_active(btn_bots, true)
		_set_btn_active(btn_pass, false)
		bot_options_box.visible = true)
	btn_pass.pressed.connect(func():
		_multi_chess_pass_and_play = true
		_set_btn_active(btn_bots, false)
		_set_btn_active(btn_pass, true)
		bot_options_box.visible = false)

	var col_row := BoxContainer.new()
	col_row.vertical = false
	col_row.add_theme_constant_override("separation", 10)
	bot_options_box.add_child(col_row)
	_multi_col_row = col_row

	var col_lbl := _field_label("Ваша армия")
	col_lbl.custom_minimum_size.x = 150
	col_row.add_child(col_lbl)
	_multi_col_lbl = col_lbl

	var col_btns_box := HBoxContainer.new()
	col_btns_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_btns_box.add_theme_constant_override("separation", 8)
	col_row.add_child(col_btns_box)

	var b_w := _create_selectable_btn("Белые", _multi_chess_color == MultiChessState.WHITE)
	var b_r := _create_selectable_btn("Красные", _multi_chess_color == MultiChessState.RED)
	var b_b := _create_selectable_btn("Чёрные", _multi_chess_color == MultiChessState.BLACK)
	var b_u := _create_selectable_btn("Синие", _multi_chess_color == MultiChessState.BLUE)
	_multi_blue_btn_ref = b_u
	for b in [b_w, b_r, b_b, b_u]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col_btns_box.add_child(b)
	_multi_color_btns = [b_w, b_r, b_b, b_u]
	_update_multi_color_btns()
	update_sub_desc.call()

	btn_3p.pressed.connect(func():
		_multi_chess_sub_mode = MultiChessState.MODE_1V1V1
		_update_multi_sub_btns()
		update_sub_desc.call())
	btn_2v2.pressed.connect(func():
		_multi_chess_sub_mode = MultiChessState.MODE_2V2
		_update_multi_sub_btns()
		update_sub_desc.call())
	btn_4ffa.pressed.connect(func():
		_multi_chess_sub_mode = MultiChessState.MODE_1V1V1V1
		_update_multi_sub_btns()
		update_sub_desc.call())

	b_w.pressed.connect(func(): _multi_chess_color = MultiChessState.WHITE; _update_multi_color_btns())
	b_r.pressed.connect(func(): _multi_chess_color = MultiChessState.RED; _update_multi_color_btns())
	b_b.pressed.connect(func(): _multi_chess_color = MultiChessState.BLACK; _update_multi_color_btns())
	b_u.pressed.connect(func(): _multi_chess_color = MultiChessState.BLUE; _update_multi_color_btns())

	var diff_row := BoxContainer.new()
	diff_row.vertical = false
	diff_row.add_theme_constant_override("separation", 10)
	bot_options_box.add_child(diff_row)
	_multi_diff_row = diff_row

	var diff_lbl := _field_label("Сложность ботов")
	diff_lbl.custom_minimum_size.x = 150
	diff_row.add_child(diff_lbl)
	_multi_diff_lbl = diff_lbl

	var diff_box := HBoxContainer.new()
	diff_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	diff_box.add_theme_constant_override("separation", 8)
	diff_row.add_child(diff_box)

	var bd_easy := _create_selectable_btn("Лёгкий", _multi_chess_ai_level == MultiChessAI.LEVEL_EASY)
	var bd_norm := _create_selectable_btn("Средний", _multi_chess_ai_level == MultiChessAI.LEVEL_NORMAL)
	var bd_hard := _create_selectable_btn("Сложный", _multi_chess_ai_level == MultiChessAI.LEVEL_HARD)
	for b in [bd_easy, bd_norm, bd_hard]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		diff_box.add_child(b)
	_multi_diff_btns = [bd_easy, bd_norm, bd_hard]

	bd_easy.pressed.connect(func(): _multi_chess_ai_level = MultiChessAI.LEVEL_EASY; _update_multi_diff_btns())
	bd_norm.pressed.connect(func(): _multi_chess_ai_level = MultiChessAI.LEVEL_NORMAL; _update_multi_diff_btns())
	bd_hard.pressed.connect(func(): _multi_chess_ai_level = MultiChessAI.LEVEL_HARD; _update_multi_diff_btns())

	var launch_btn := _create_launch_btn("Начать партию", func():
		if sfx != null:
			sfx.play("submit")
		start_multi_game.emit(_multi_chess_sub_mode, _multi_chess_pass_and_play, _multi_chess_color, _multi_chess_ai_level, null, [], false))
	_multi_launch_btn_ref = launch_btn
	f_vb.add_child(launch_btn)

	return vb


func _create_launch_btn(text: String, cb: Callable, is_amber: bool = false) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 50)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_filter = Control.MOUSE_FILTER_STOP

	var sb := StyleBoxFlat.new()
	if is_amber:
		sb.bg_color = Color(0.78, 0.44, 0.10, 0.98)
		sb.border_color = Color(0.96, 0.68, 0.25, 0.95)
	else:
		sb.bg_color = Color(0.15, 0.39, 0.92, 0.98)
		sb.border_color = Color(0.38, 0.65, 0.98, 0.95)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(10)
	btn.add_theme_stylebox_override("normal", sb)

	var sb_hover: StyleBoxFlat = sb.duplicate()
	sb_hover.bg_color = Color(0.88, 0.52, 0.14, 1.0) if is_amber else Color(0.22, 0.48, 0.98, 1.0)
	btn.add_theme_stylebox_override("hover", sb_hover)

	var sb_pressed: StyleBoxFlat = sb.duplicate()
	sb_pressed.bg_color = Color(0.64, 0.35, 0.08, 1.0) if is_amber else Color(0.11, 0.30, 0.74, 1.0)
	btn.add_theme_stylebox_override("pressed", sb_pressed)

	btn.pressed.connect(cb)
	return btn


func _apply_sub_mode_btns(btns: Array, mode: String) -> void:
	if btns.size() >= 3:
		_set_btn_active(btns[0], mode == MultiChessState.MODE_1V1V1)
		_set_btn_active(btns[1], mode == MultiChessState.MODE_2V2)
		_set_btn_active(btns[2], mode == MultiChessState.MODE_1V1V1V1)


func _apply_army_color_btns(btns: Array, selected_col: int) -> void:
	if btns.size() >= 4:
		_set_army_btn_style(btns[0], selected_col == MultiChessState.WHITE, Color(0.92, 0.94, 0.98), Color(0.18, 0.24, 0.34, 0.95))
		_set_army_btn_style(btns[1], selected_col == MultiChessState.RED, Color(0.94, 0.36, 0.36), Color(0.38, 0.14, 0.16, 0.95))
		_set_army_btn_style(btns[2], selected_col == MultiChessState.BLACK, Color(0.68, 0.72, 0.84), Color(0.16, 0.18, 0.26, 0.95))
		_set_army_btn_style(btns[3], selected_col == MultiChessState.BLUE, Color(0.36, 0.68, 0.98), Color(0.12, 0.26, 0.48, 0.95))


func _apply_diff_btns(btns: Array, lvl: int) -> void:
	if btns.size() >= 3:
		_set_btn_active(btns[0], lvl == MultiChessAI.LEVEL_EASY)
		_set_btn_active(btns[1], lvl == MultiChessAI.LEVEL_NORMAL)
		_set_btn_active(btns[2], lvl == MultiChessAI.LEVEL_HARD)


func _update_multi_sub_btns() -> void:
	_apply_sub_mode_btns(_multi_sub_mode_btns, _multi_chess_sub_mode)


func _update_multi_color_btns() -> void:
	_apply_army_color_btns(_multi_color_btns, _multi_chess_color)


func _update_net_multi_sub_btns() -> void:
	_apply_sub_mode_btns(_net_multi_sub_btns, _net_multi_sub_mode)


func _update_net_multi_color_btns() -> void:
	_apply_army_color_btns(_net_multi_color_btns, _net_multi_color)


func _update_multi_diff_btns() -> void:
	_apply_diff_btns(_multi_diff_btns, _multi_chess_ai_level)


func _update_d20_sub_mode_btns() -> void:
	_apply_sub_mode_btns(_d20_sub_mode_btns, _d20_sub_mode)
	if _d20_blue_btn_ref != null:
		var has_blue: bool = (_d20_sub_mode != MultiChessState.MODE_1V1V1)
		_d20_blue_btn_ref.visible = has_blue
		if not has_blue and _d20_color == MultiChessState.BLUE:
			_d20_color = MultiChessState.WHITE
			_update_d20_color_btns()


func _update_d20_color_btns() -> void:
	_apply_army_color_btns(_d20_color_btns, _d20_color)


func _update_d20_diff_btns() -> void:
	_apply_diff_btns(_d20_diff_btns, _d20_ai_level)


func _on_d20_launch_pressed() -> void:
	if sfx != null:
		sfx.play("submit")
	if _d20_play_mode == 0:
		start_multi_game.emit(_d20_sub_mode, false, _d20_color, _d20_ai_level, null, [], true)
	elif _d20_play_mode == 1:
		start_multi_game.emit(_d20_sub_mode, true, _d20_color, _d20_ai_level, null, [], true)
	else:
		if net == null:
			return
		_net_status_label.text = "Создание комнаты D20 на сервере..."
		net.online_create_multi_room(_d20_sub_mode, _d20_color, "D20 Битва " + _d20_sub_mode, true)
		_switch_tab(3)


# ---------------------------------------------------------------- Вкладка 2: D20 Битва и задачи

func _build_puzzles_tab() -> Control:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)

	# 1. D20 Битва
	var d20_card := PanelContainer.new()
	d20_card.add_theme_stylebox_override("panel", _glass_panel_style(12, Color(0.075, 0.095, 0.155, 0.96), Color(0.55, 0.42, 0.18, 0.80)))
	vb.add_child(d20_card)

	var d20_vb := VBoxContainer.new()
	d20_vb.add_theme_constant_override("separation", 12)
	d20_card.add_child(d20_vb)

	var d20_head := HBoxContainer.new()
	d20_vb.add_child(d20_head)

	var d20_title := Label.new()
	d20_title.text = "D20 Битва: Кубик судьбы"
	d20_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	d20_title.add_theme_font_size_override("font_size", 18)
	d20_title.add_theme_color_override("font_color", Color(0.96, 0.82, 0.42))
	d20_head.add_child(d20_title)

	var d20_desc := Label.new()
	d20_desc.text = "Каждое взятие решается броском 20-гранного кубика. Порог зависит от разницы в силе фигур: при неудаче защитник отбивает удар."
	d20_desc.add_theme_font_size_override("font_size", 13)
	d20_desc.add_theme_color_override("font_color", Color(0.64, 0.72, 0.84))
	d20_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d20_vb.add_child(d20_desc)

	d20_vb.add_child(_field_label("Карта"))

	var preset_row := BoxContainer.new()
	preset_row.vertical = false
	preset_row.add_theme_constant_override("separation", 8)
	d20_vb.add_child(preset_row)
	_d20_preset_box = preset_row

	var btn_p1 := _create_selectable_btn("1×1×1 (3 игрока)", _d20_sub_mode == MultiChessState.MODE_1V1V1)
	var btn_p2 := _create_selectable_btn("2×2 (Команды)", _d20_sub_mode == MultiChessState.MODE_2V2)
	var btn_p3 := _create_selectable_btn("1×1×1×1 (4 игрока)", _d20_sub_mode == MultiChessState.MODE_1V1V1V1)
	for b in [btn_p1, btn_p2, btn_p3]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		preset_row.add_child(b)
	_d20_sub_mode_btns = [btn_p1, btn_p2, btn_p3]

	btn_p1.pressed.connect(func(): _d20_sub_mode = MultiChessState.MODE_1V1V1; _update_d20_sub_mode_btns())
	btn_p2.pressed.connect(func(): _d20_sub_mode = MultiChessState.MODE_2V2; _update_d20_sub_mode_btns())
	btn_p3.pressed.connect(func(): _d20_sub_mode = MultiChessState.MODE_1V1V1V1; _update_d20_sub_mode_btns())

	d20_vb.add_child(_field_label("Режим"))

	var mode_row := BoxContainer.new()
	mode_row.vertical = false
	mode_row.add_theme_constant_override("separation", 8)
	d20_vb.add_child(mode_row)
	_d20_mode_box = mode_row

	var btn_m_bots := _create_selectable_btn("Против ботов", _d20_play_mode == 0)
	var btn_m_pass := _create_selectable_btn("На одном экране", _d20_play_mode == 1)
	var btn_m_net := _create_selectable_btn("Онлайн-комната", _d20_play_mode == 2)
	for b in [btn_m_bots, btn_m_pass, btn_m_net]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mode_row.add_child(b)

	_d20_bot_options_box = VBoxContainer.new()
	_d20_bot_options_box.add_theme_constant_override("separation", 10)
	d20_vb.add_child(_d20_bot_options_box)

	var col_row := BoxContainer.new()
	col_row.vertical = false
	col_row.add_theme_constant_override("separation", 10)
	_d20_bot_options_box.add_child(col_row)
	_d20_col_row = col_row

	var c_lbl := _field_label("Ваша армия")
	c_lbl.custom_minimum_size.x = 140
	col_row.add_child(c_lbl)

	var c_btns_box := HBoxContainer.new()
	c_btns_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c_btns_box.add_theme_constant_override("separation", 8)
	col_row.add_child(c_btns_box)

	var db_w := _create_selectable_btn("Белые", _d20_color == MultiChessState.WHITE)
	var db_r := _create_selectable_btn("Красные", _d20_color == MultiChessState.RED)
	var db_b := _create_selectable_btn("Чёрные", _d20_color == MultiChessState.BLACK)
	var db_u := _create_selectable_btn("Синие", _d20_color == MultiChessState.BLUE)
	_d20_blue_btn_ref = db_u
	for b in [db_w, db_r, db_b, db_u]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		c_btns_box.add_child(b)
	_d20_color_btns = [db_w, db_r, db_b, db_u]
	_update_d20_color_btns()

	db_w.pressed.connect(func(): _d20_color = MultiChessState.WHITE; _update_d20_color_btns())
	db_r.pressed.connect(func(): _d20_color = MultiChessState.RED; _update_d20_color_btns())
	db_b.pressed.connect(func(): _d20_color = MultiChessState.BLACK; _update_d20_color_btns())
	db_u.pressed.connect(func(): _d20_color = MultiChessState.BLUE; _update_d20_color_btns())

	var d20_diff_row := HBoxContainer.new()
	d20_diff_row.add_theme_constant_override("separation", 10)
	_d20_bot_options_box.add_child(d20_diff_row)

	var df_lbl := _field_label("Сложность ботов")
	df_lbl.custom_minimum_size.x = 140
	d20_diff_row.add_child(df_lbl)

	var df_box := HBoxContainer.new()
	df_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	df_box.add_theme_constant_override("separation", 8)
	d20_diff_row.add_child(df_box)

	var bdf_easy := _create_selectable_btn("Лёгкий", _d20_ai_level == MultiChessAI.LEVEL_EASY)
	var bdf_norm := _create_selectable_btn("Средний", _d20_ai_level == MultiChessAI.LEVEL_NORMAL)
	var bdf_hard := _create_selectable_btn("Сложный", _d20_ai_level == MultiChessAI.LEVEL_HARD)
	for b in [bdf_easy, bdf_norm, bdf_hard]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		df_box.add_child(b)
	_d20_diff_btns = [bdf_easy, bdf_norm, bdf_hard]

	bdf_easy.pressed.connect(func(): _d20_ai_level = MultiChessAI.LEVEL_EASY; _update_d20_diff_btns())
	bdf_norm.pressed.connect(func(): _d20_ai_level = MultiChessAI.LEVEL_NORMAL; _update_d20_diff_btns())
	bdf_hard.pressed.connect(func(): _d20_ai_level = MultiChessAI.LEVEL_HARD; _update_d20_diff_btns())

	btn_m_bots.pressed.connect(func():
		_d20_play_mode = 0
		_set_btn_active(btn_m_bots, true)
		_set_btn_active(btn_m_pass, false)
		_set_btn_active(btn_m_net, false)
		_d20_bot_options_box.visible = true
		d20_diff_row.visible = true
		_d20_launch_btn_ref.text = "Начать D20 битву"
	)
	btn_m_pass.pressed.connect(func():
		_d20_play_mode = 1
		_set_btn_active(btn_m_bots, false)
		_set_btn_active(btn_m_pass, true)
		_set_btn_active(btn_m_net, false)
		_d20_bot_options_box.visible = false
		_d20_launch_btn_ref.text = "Начать на одном экране"
	)
	btn_m_net.pressed.connect(func():
		_d20_play_mode = 2
		_set_btn_active(btn_m_bots, false)
		_set_btn_active(btn_m_pass, false)
		_set_btn_active(btn_m_net, true)
		_d20_bot_options_box.visible = true
		d20_diff_row.visible = false
		_d20_launch_btn_ref.text = "Создать онлайн-комнату D20"
	)

	var ch_text := Label.new()
	ch_text.text = "Формула порога (DC): 10 + (Сила цели − Сила атаки) × 2. Натуральная 20 — гарантированное взятие, 1 — промах."
	ch_text.add_theme_font_size_override("font_size", 12)
	ch_text.add_theme_color_override("font_color", Color(0.55, 0.63, 0.75))
	ch_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d20_vb.add_child(ch_text)

	var d20_launch_btn := _create_launch_btn("Начать D20 битву", _on_d20_launch_pressed, true)
	_d20_launch_btn_ref = d20_launch_btn
	d20_vb.add_child(d20_launch_btn)

	_update_d20_sub_mode_btns()

	# 2. Генератор тактических задач
	var proc_card := PanelContainer.new()
	proc_card.add_theme_stylebox_override("panel", _glass_panel_style(12))
	vb.add_child(proc_card)

	var proc_vb := VBoxContainer.new()
	proc_vb.add_theme_constant_override("separation", 10)
	proc_card.add_child(proc_vb)

	var proc_title := Label.new()
	proc_title.text = "🎲 Процедурный генератор задач (100% решаемые)"
	proc_title.add_theme_font_size_override("font_size", 17)
	proc_title.add_theme_color_override("font_color", Color(0.95, 0.96, 0.98))
	proc_vb.add_child(proc_title)

	var proc_sub := Label.new()
	proc_sub.text = "Каждая позиция генерируется случайно (11 тактических паттернов + синтезатор позиций) и проверяется движком на мат в 1 ход."
	proc_sub.add_theme_font_size_override("font_size", 13)
	proc_sub.add_theme_color_override("font_color", Color(0.58, 0.66, 0.78))
	proc_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	proc_vb.add_child(proc_sub)

	var diff_row := HBoxContainer.new()
	diff_row.add_theme_constant_override("separation", 8)
	proc_vb.add_child(diff_row)

	var proc_diff_desc := Label.new()
	proc_diff_desc.add_theme_font_size_override("font_size", 12)
	proc_diff_desc.add_theme_color_override("font_color", Color(0.54, 0.78, 0.94))
	proc_diff_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var update_proc_desc := func():
		match _proc_diff:
			1: proc_diff_desc.text = "⚡ Лёгкий: мат по 8-й горизонтали, линейный мат, эполетный мат и поцелуй смерти."
			2: proc_diff_desc.text = "⚔️ Средний: спёртый мат, арабский мат, мат Анастасии, вскрытый шах и 5D-фигуры (Принцесса, Единорог)."
			3: proc_diff_desc.text = "🌀 Сложный: темпоральные прыжки в прошлое (T1), двойные шахи и многофигурные матовые сети."
	update_proc_desc.call()

	_proc_diff_btns.clear()
	var diff_defs: Array = [
		{"d": 1, "text": "Лёгкий (+50 💎)"},
		{"d": 2, "text": "Средний (+85 💎)"},
		{"d": 3, "text": "Сложный (+125 💎)"}
	]
	for df in diff_defs:
		var d_val: int = int(df["d"])
		var btn := _create_selectable_btn(str(df["text"]), _proc_diff == d_val)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 40)
		btn.pressed.connect(func():
			_proc_diff = d_val
			_update_proc_diff_ui()
			update_proc_desc.call()
			if sfx != null:
				sfx.play("click"))
		diff_row.add_child(btn)
		_proc_diff_btns.append(btn)

	proc_vb.add_child(proc_diff_desc)

	var start_proc_btn := _create_launch_btn("🎲 Сгенерировать уникальную задачу", func():
		if sfx != null:
			sfx.play("click")
		var new_puz: Dictionary = Puzzles.generate_procedural_puzzle(_proc_diff)
		start_puzzle_game.emit(new_puz))
	start_proc_btn.custom_minimum_size = Vector2(0, 46)
	proc_vb.add_child(start_proc_btn)

	# 3. Ежедневные задания
	var quests_card := PanelContainer.new()
	quests_card.add_theme_stylebox_override("panel", _glass_panel_style(12))
	vb.add_child(quests_card)

	var q_main_vb := VBoxContainer.new()
	q_main_vb.add_theme_constant_override("separation", 10)
	quests_card.add_child(q_main_vb)

	var q_title := Label.new()
	q_title.text = "Ежедневные задания"
	q_title.add_theme_font_size_override("font_size", 17)
	q_title.add_theme_color_override("font_color", Color(0.95, 0.96, 0.98))
	q_main_vb.add_child(q_title)

	_quests_container = VBoxContainer.new()
	_quests_container.add_theme_constant_override("separation", 8)
	q_main_vb.add_child(_quests_container)

	# 4. Коллекция 5D-головоломок
	var puz_card := PanelContainer.new()
	puz_card.add_theme_stylebox_override("panel", _glass_panel_style(12))
	vb.add_child(puz_card)

	var p_main_vb := VBoxContainer.new()
	p_main_vb.add_theme_constant_override("separation", 10)
	puz_card.add_child(p_main_vb)

	var p_title := Label.new()
	p_title.text = "Тактические и 5D-головоломки"
	p_title.add_theme_font_size_override("font_size", 17)
	p_title.add_theme_color_override("font_color", Color(0.95, 0.96, 0.98))
	p_main_vb.add_child(p_title)

	_puzzles_container = VBoxContainer.new()
	_puzzles_container.add_theme_constant_override("separation", 8)
	p_main_vb.add_child(_puzzles_container)

	_refresh_puzzles_and_quests_ui()
	return vb


func _update_proc_diff_ui() -> void:
	for i in _proc_diff_btns.size():
		var btn: Button = _proc_diff_btns[i]
		_set_btn_active(btn, (i + 1) == _proc_diff)


func _refresh_puzzles_and_quests_ui() -> void:
	Profile.check_daily_quests()
	_refresh_quests_ui()
	_refresh_puzzles_ui()
	_update_crystals_display()


func _refresh_quests_ui() -> void:
	if _quests_container == null:
		return
	for c in _quests_container.get_children():
		c.queue_free()

	var is_phone: bool = get_viewport_rect().size.x < 620.0

	for q in Profile.daily_quests:
		var q_id: String = str(q.get("id", ""))
		var q_title: String = str(q.get("title", ""))
		var q_desc: String = str(q.get("desc", ""))
		var cur: int = int(q.get("current", 0))
		var tgt: int = int(q.get("target", 1))
		var rew: int = int(q.get("reward", 50))
		var is_claimed: bool = bool(q.get("claimed", false))
		var is_completed: bool = (cur >= tgt)

		var card := PanelContainer.new()
		var card_sb := StyleBoxFlat.new()
		card_sb.bg_color = Color(0.055, 0.075, 0.125, 0.90)
		card_sb.border_color = Color(0.85, 0.68, 0.25, 0.75) if (is_completed and not is_claimed) else Color(0.14, 0.19, 0.28, 0.80)
		card_sb.set_border_width_all(1)
		card_sb.set_corner_radius_all(8)
		card_sb.content_margin_left = 12
		card_sb.content_margin_right = 12
		card_sb.content_margin_top = 10
		card_sb.content_margin_bottom = 10
		card.add_theme_stylebox_override("panel", card_sb)
		_quests_container.add_child(card)

		var row := BoxContainer.new()
		row.vertical = is_phone
		row.add_theme_constant_override("separation", 8 if is_phone else 12)
		card.add_child(row)

		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_constant_override("separation", 2)
		row.add_child(info)

		var t_lbl := Label.new()
		t_lbl.text = "%s  (+%d ◆)" % [q_title, rew]
		t_lbl.add_theme_font_size_override("font_size", 14)
		t_lbl.add_theme_color_override("font_color", Color(0.94, 0.95, 0.98))
		t_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(t_lbl)

		var d_lbl := Label.new()
		d_lbl.text = "%s · %d / %d" % [q_desc, cur, tgt]
		d_lbl.add_theme_font_size_override("font_size", 12)
		d_lbl.add_theme_color_override("font_color", Color(0.58, 0.66, 0.78))
		d_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(d_lbl)

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 36) if is_phone else Vector2(130, 36)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL if is_phone else Control.SIZE_SHRINK_END
		btn.focus_mode = Control.FOCUS_NONE

		if is_claimed:
			btn.text = "Получено"
			btn.disabled = true
			var dis_sb := StyleBoxFlat.new()
			dis_sb.bg_color = Color(0.09, 0.12, 0.18, 0.5)
			dis_sb.set_corner_radius_all(6)
			btn.add_theme_stylebox_override("disabled", dis_sb)
		elif is_completed:
			btn.text = "Забрать +%d" % rew
			var act_sb := StyleBoxFlat.new()
			act_sb.bg_color = Color(0.16, 0.46, 0.28, 0.95)
			act_sb.border_color = Color(0.32, 0.78, 0.48)
			act_sb.set_border_width_all(1)
			act_sb.set_corner_radius_all(6)
			btn.add_theme_stylebox_override("normal", act_sb)
			btn.pressed.connect(func():
				var got := Profile.claim_quest_reward(q_id)
				if got > 0 and sfx != null:
					sfx.play("win")
				_refresh_puzzles_and_quests_ui())
		else:
			btn.text = "%d / %d" % [cur, tgt]
			btn.disabled = true
			var dis_sb := StyleBoxFlat.new()
			dis_sb.bg_color = Color(0.08, 0.11, 0.18, 0.6)
			dis_sb.set_corner_radius_all(6)
			btn.add_theme_stylebox_override("disabled", dis_sb)

		row.add_child(btn)


func _refresh_puzzles_ui() -> void:
	if _puzzles_container == null:
		return
	for c in _puzzles_container.get_children():
		c.queue_free()

	var is_phone: bool = get_viewport_rect().size.x < 620.0

	for p in Puzzles.LIST:
		var p_id: String = str(p.get("id", ""))
		var title: String = str(p.get("title", ""))
		var cat: String = str(p.get("category", "Тактика"))
		var rew: int = int(p.get("reward", 50))
		var desc: String = str(p.get("desc", ""))
		var is_solved: bool = Profile.is_puzzle_solved(p_id)

		var card := PanelContainer.new()
		var card_sb := StyleBoxFlat.new()
		card_sb.bg_color = Color(0.055, 0.075, 0.125, 0.90)
		card_sb.border_color = Color(0.22, 0.58, 0.42, 0.70) if is_solved else Color(0.14, 0.19, 0.28, 0.80)
		card_sb.set_border_width_all(1)
		card_sb.set_corner_radius_all(8)
		card_sb.content_margin_left = 12
		card_sb.content_margin_right = 12
		card_sb.content_margin_top = 10
		card_sb.content_margin_bottom = 10
		card.add_theme_stylebox_override("panel", card_sb)
		_puzzles_container.add_child(card)

		var row := BoxContainer.new()
		row.vertical = is_phone
		row.add_theme_constant_override("separation", 8 if is_phone else 12)
		card.add_child(row)

		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_constant_override("separation", 2)
		row.add_child(info)

		var t_lbl := Label.new()
		var status_str := " · Решено" if is_solved else (" · +%d ◆" % rew)
		t_lbl.text = "%s (%s)%s" % [title, cat, status_str]
		t_lbl.add_theme_font_size_override("font_size", 14)
		t_lbl.add_theme_color_override("font_color", Color(0.94, 0.95, 0.98) if not is_solved else Color(0.55, 0.88, 0.68))
		t_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(t_lbl)

		var d_lbl := Label.new()
		d_lbl.text = desc
		d_lbl.add_theme_font_size_override("font_size", 12)
		d_lbl.add_theme_color_override("font_color", Color(0.58, 0.66, 0.78))
		d_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(d_lbl)

		var play_btn := _action_btn("Повторить" if is_solved else "Решать", func():
			if sfx != null:
				sfx.play("click")
			start_puzzle_game.emit(p.duplicate(true)))
		play_btn.custom_minimum_size = Vector2(0, 36) if is_phone else Vector2(120, 36)
		play_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL if is_phone else Control.SIZE_SHRINK_END
		row.add_child(play_btn)


# ---------------------------------------------------------------- Вкладка 3: Сетевая игра

func _build_multiplayer_tab() -> Control:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)

	# Переключатель: Онлайн vs Локальная сеть
	var mode_toggle_hb := HBoxContainer.new()
	mode_toggle_hb.add_theme_constant_override("separation", 8)
	vb.add_child(mode_toggle_hb)

	var btn_online := _create_selectable_btn("Онлайн-сервер", _multi_online_mode)
	var btn_lan := _create_selectable_btn("Локальная сеть (Wi-Fi)", not _multi_online_mode)
	btn_online.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_lan.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mode_toggle_hb.add_child(btn_online)
	mode_toggle_hb.add_child(btn_lan)
	_multi_mode_btns = [btn_online, btn_lan]

	var server_cfg_btn := _action_btn("Сервер", _show_server_settings_dialog)
	server_cfg_btn.custom_minimum_size = Vector2(100, 42)
	mode_toggle_hb.add_child(server_cfg_btn)

	btn_online.pressed.connect(func():
		_multi_online_mode = true
		_update_multi_mode_ui()
		if net != null:
			net.connect_online())

	btn_lan.pressed.connect(func():
		_multi_online_mode = false
		_update_multi_mode_ui()
		if net != null:
			net.start_lan_discovery())

	# Незавершенный матч
	if Profile.has_active_match():
		var recon_card := PanelContainer.new()
		recon_card.add_theme_stylebox_override("panel", _glass_panel_style(12, Color(0.16, 0.12, 0.06, 0.95), Color(0.85, 0.62, 0.20, 0.85)))
		vb.add_child(recon_card)

		var r_vb := VBoxContainer.new()
		r_vb.add_theme_constant_override("separation", 8)
		recon_card.add_child(r_vb)

		var r_title := Label.new()
		r_title.text = "Незавершённый матч (код: %s)" % Profile.active_match_code
		r_title.add_theme_font_size_override("font_size", 15)
		r_title.add_theme_color_override("font_color", Color(0.96, 0.82, 0.38))
		r_vb.add_child(r_title)

		var r_sub := Label.new()
		var opp_name: String = Profile.active_match_opponent if Profile.active_match_opponent != "" else "Соперник"
		r_sub.text = "%s · %s" % [opp_name, Profile.active_match_variant]
		r_sub.add_theme_font_size_override("font_size", 13)
		r_sub.add_theme_color_override("font_color", Color(0.75, 0.80, 0.88))
		r_vb.add_child(r_sub)

		var r_btn_row := HBoxContainer.new()
		r_btn_row.add_theme_constant_override("separation", 8)
		r_vb.add_child(r_btn_row)

		var recon_btn := _action_btn("Вернуться в партию", func():
			if net != null:
				_net_status_label.text = "Переподключение к %s..." % Profile.active_match_code
				net.reconnect_to_match(Profile.active_match_code, Profile.active_match_token))
		recon_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r_btn_row.add_child(recon_btn)

		var dismiss_btn := _action_btn("Закрыть", func():
			Profile.clear_active_match()
			recon_card.queue_free())
		dismiss_btn.custom_minimum_size = Vector2(110, 40)
		r_btn_row.add_child(dismiss_btn)

	# 1. Вход по коду комнаты
	var code_card := PanelContainer.new()
	code_card.add_theme_stylebox_override("panel", _glass_panel_style(12))
	vb.add_child(code_card)

	var code_vb := VBoxContainer.new()
	code_vb.add_theme_constant_override("separation", 8)
	code_card.add_child(code_vb)

	code_vb.add_child(_field_label("Подключение по коду комнаты"))

	_code_row = BoxContainer.new()
	_code_row.vertical = false
	_code_row.add_theme_constant_override("separation", 8)
	code_vb.add_child(_code_row)

	_room_code_input = LineEdit.new()
	_room_code_input.placeholder_text = "Код комнаты (например, 7K9F)"
	_room_code_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_room_code_input.custom_minimum_size.y = 42
	_style_line_edit(_room_code_input)
	_code_row.add_child(_room_code_input)

	var join_code_btn := _action_btn("Войти", _on_join_code_pressed)
	join_code_btn.custom_minimum_size = Vector2(140, 42)
	_code_row.add_child(join_code_btn)

	# 2. Создание комнаты и лобби
	var host_card := PanelContainer.new()
	host_card.add_theme_stylebox_override("panel", _glass_panel_style(12))
	vb.add_child(host_card)

	var host_vb := VBoxContainer.new()
	host_vb.add_theme_constant_override("separation", 12)
	host_card.add_child(host_vb)

	host_vb.add_child(_field_label("Создать комнату (до 2 игроков)"))

	var type_row := HBoxContainer.new()
	type_row.add_theme_constant_override("separation", 8)
	host_vb.add_child(type_row)

	var btn_type_5d := _create_selectable_btn("5D Хроно", _net_game_type == "5d")
	var btn_type_multi := _create_selectable_btn("Мульти 14×14", _net_game_type == "multi")
	var btn_type_d20 := _create_selectable_btn("D20 Битва", _net_game_type == "d20_multi")
	btn_type_5d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_type_multi.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_type_d20.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	type_row.add_child(btn_type_5d)
	type_row.add_child(btn_type_multi)
	type_row.add_child(btn_type_d20)
	_net_type_btns = [btn_type_5d, btn_type_multi, btn_type_d20]

	_net_multi_options_box = VBoxContainer.new()
	_net_multi_options_box.add_theme_constant_override("separation", 10)
	_net_multi_options_box.visible = (_net_game_type in ["multi", "d20_multi"])
	host_vb.add_child(_net_multi_options_box)

	_net_multi_options_box.add_child(_field_label("Формат поля"))

	var m_fmt_row := HBoxContainer.new()
	m_fmt_row.add_theme_constant_override("separation", 8)
	_net_multi_options_box.add_child(m_fmt_row)

	var m_btn_3p := _create_selectable_btn("1×1×1", _net_multi_sub_mode == MultiChessState.MODE_1V1V1)
	var m_btn_2v2 := _create_selectable_btn("2×2", _net_multi_sub_mode == MultiChessState.MODE_2V2)
	var m_btn_4ffa := _create_selectable_btn("1×1×1×1", _net_multi_sub_mode == MultiChessState.MODE_1V1V1V1)
	for b in [m_btn_3p, m_btn_2v2, m_btn_4ffa]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		m_fmt_row.add_child(b)
	_net_multi_sub_btns = [m_btn_3p, m_btn_2v2, m_btn_4ffa]

	_net_multi_options_box.add_child(_field_label("Ваш цвет"))

	var m_col_row := HBoxContainer.new()
	m_col_row.add_theme_constant_override("separation", 8)
	_net_multi_options_box.add_child(m_col_row)

	var m_col_w := _create_selectable_btn("Белые", _net_multi_color == MultiChessState.WHITE)
	var m_col_r := _create_selectable_btn("Красные", _net_multi_color == MultiChessState.RED)
	var m_col_b := _create_selectable_btn("Чёрные", _net_multi_color == MultiChessState.BLACK)
	var m_col_u := _create_selectable_btn("Синие", _net_multi_color == MultiChessState.BLUE)
	_net_multi_blue_btn = m_col_u
	for b in [m_col_w, m_col_r, m_col_b, m_col_u]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		m_col_row.add_child(b)
	_net_multi_color_btns = [m_col_w, m_col_r, m_col_b, m_col_u]
	_update_net_multi_color_btns()

	var update_m_blue_vis := func():
		if _net_multi_blue_btn != null:
			_net_multi_blue_btn.visible = (_net_multi_sub_mode != MultiChessState.MODE_1V1V1)
			if _net_multi_sub_mode == MultiChessState.MODE_1V1V1 and _net_multi_color == MultiChessState.BLUE:
				_net_multi_color = MultiChessState.WHITE
				_update_net_multi_color_btns()

	update_m_blue_vis.call()

	m_btn_3p.pressed.connect(func():
		_net_multi_sub_mode = MultiChessState.MODE_1V1V1
		_update_net_multi_sub_btns()
		update_m_blue_vis.call())
	m_btn_2v2.pressed.connect(func():
		_net_multi_sub_mode = MultiChessState.MODE_2V2
		_update_net_multi_sub_btns()
		update_m_blue_vis.call())
	m_btn_4ffa.pressed.connect(func():
		_net_multi_sub_mode = MultiChessState.MODE_1V1V1V1
		_update_net_multi_sub_btns()
		update_m_blue_vis.call())

	m_col_w.pressed.connect(func(): _net_multi_color = MultiChessState.WHITE; _update_net_multi_color_btns())
	m_col_r.pressed.connect(func(): _net_multi_color = MultiChessState.RED; _update_net_multi_color_btns())
	m_col_b.pressed.connect(func(): _net_multi_color = MultiChessState.BLACK; _update_net_multi_color_btns())
	m_col_u.pressed.connect(func(): _net_multi_color = MultiChessState.BLUE; _update_net_multi_color_btns())

	btn_type_5d.pressed.connect(func():
		_net_game_type = "5d"
		_set_btn_active(btn_type_5d, true)
		_set_btn_active(btn_type_multi, false)
		_set_btn_active(btn_type_d20, false)
		_net_multi_options_box.visible = false)
	btn_type_multi.pressed.connect(func():
		_net_game_type = "multi"
		_set_btn_active(btn_type_5d, false)
		_set_btn_active(btn_type_multi, true)
		_set_btn_active(btn_type_d20, false)
		_net_multi_options_box.visible = true)
	btn_type_d20.pressed.connect(func():
		_net_game_type = "d20_multi"
		_set_btn_active(btn_type_5d, false)
		_set_btn_active(btn_type_multi, false)
		_set_btn_active(btn_type_d20, true)
		_net_multi_options_box.visible = true)

	_name_row = BoxContainer.new()
	_name_row.vertical = false
	_name_row.add_theme_constant_override("separation", 8)
	host_vb.add_child(_name_row)

	_room_name_input = LineEdit.new()
	_room_name_input.text = "Комната " + Profile.player_name
	_room_name_input.placeholder_text = "Название комнаты"
	_room_name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_room_name_input.custom_minimum_size.y = 42
	_style_line_edit(_room_name_input)
	_name_row.add_child(_room_name_input)

	var create_btn := _action_btn("Создать комнату", _on_create_host_pressed)
	create_btn.custom_minimum_size = Vector2(160, 42)
	_name_row.add_child(create_btn)

	# Панель активного лобби комнаты
	_host_panel = PanelContainer.new()
	_host_panel.add_theme_stylebox_override("panel", _glass_panel_style(10, Color(0.08, 0.12, 0.22, 0.96), Color(0.28, 0.52, 0.88, 0.80)))
	_host_panel.visible = false
	host_vb.add_child(_host_panel)

	var hp_vb := VBoxContainer.new()
	hp_vb.add_theme_constant_override("separation", 10)
	_host_panel.add_child(hp_vb)

	_host_code_label = Label.new()
	_host_code_label.add_theme_font_size_override("font_size", 20)
	_host_code_label.add_theme_color_override("font_color", Color(0.96, 0.84, 0.38))
	hp_vb.add_child(_host_code_label)

	_lobby_info_label = Label.new()
	_lobby_info_label.add_theme_font_size_override("font_size", 13)
	_lobby_info_label.add_theme_color_override("font_color", Color(0.68, 0.76, 0.88))
	hp_vb.add_child(_lobby_info_label)

	_lobby_players_box = VBoxContainer.new()
	_lobby_players_box.add_theme_constant_override("separation", 6)
	hp_vb.add_child(_lobby_players_box)

	var hp_btn_row := HBoxContainer.new()
	hp_btn_row.add_theme_constant_override("separation", 8)
	hp_vb.add_child(hp_btn_row)

	var copy_code_btn := _action_btn("Скопировать код", func():
		if net != null and net.room_code != "":
			DisplayServer.clipboard_set(net.room_code)
			_net_status_label.text = "Код %s скопирован" % net.room_code)
	hp_btn_row.add_child(copy_code_btn)

	_lobby_start_btn = _action_btn("Начать партию", func():
		if net != null:
			net.online_start_room_game())
	_lobby_start_btn.visible = false
	var st_sb := StyleBoxFlat.new()
	st_sb.bg_color = Color(0.16, 0.48, 0.28, 0.96)
	st_sb.border_color = Color(0.35, 0.82, 0.50, 0.90)
	st_sb.set_border_width_all(1)
	st_sb.set_corner_radius_all(8)
	_lobby_start_btn.add_theme_stylebox_override("normal", st_sb)
	hp_btn_row.add_child(_lobby_start_btn)

	var cancel_host_btn := _action_btn("Покинуть", func():
		if net != null:
			if _multi_online_mode:
				net.online_leave_room()
			else:
				net.close()
		_host_panel.visible = false
		_net_status_label.text = "Вы покинули комнату")
	hp_btn_row.add_child(cancel_host_btn)

	_net_status_label = Label.new()
	_net_status_label.add_theme_font_size_override("font_size", 13)
	_net_status_label.add_theme_color_override("font_color", Color(0.48, 0.78, 0.98))
	vb.add_child(_net_status_label)

	# 3. Список открытых комнат
	var browser_card := PanelContainer.new()
	browser_card.add_theme_stylebox_override("panel", _glass_panel_style(12))
	vb.add_child(browser_card)

	var browser_vb := VBoxContainer.new()
	browser_vb.add_theme_constant_override("separation", 10)
	browser_card.add_child(browser_vb)

	var br_header := HBoxContainer.new()
	browser_vb.add_child(br_header)

	var br_title := _field_label("Открытые комнаты")
	br_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	br_header.add_child(br_title)

	var refresh_btn := _action_btn("Обновить", func():
		if net != null:
			if _multi_online_mode:
				net.online_request_rooms()
			else:
				net.start_lan_discovery()
			_net_status_label.text = "Обновление списка...")
	refresh_btn.custom_minimum_size = Vector2(110, 36)
	br_header.add_child(refresh_btn)

	_server_list_container = VBoxContainer.new()
	_server_list_container.add_theme_constant_override("separation", 8)
	browser_vb.add_child(_server_list_container)

	_no_servers_label = Label.new()
	_no_servers_label.text = "Нет открытых комнат. Создайте свою или подключитесь по коду."
	_no_servers_label.add_theme_font_size_override("font_size", 13)
	_no_servers_label.add_theme_color_override("font_color", Color(0.50, 0.58, 0.70))
	browser_vb.add_child(_no_servers_label)

	return vb


func _update_multi_mode_ui() -> void:
	if _multi_mode_btns.size() >= 2:
		_set_btn_active(_multi_mode_btns[0], _multi_online_mode)
		_set_btn_active(_multi_mode_btns[1], not _multi_online_mode)
	if _room_code_input != null:
		_room_code_input.placeholder_text = "Код комнаты (например, 7K9F)" if _multi_online_mode else "Код комнаты (например, 7K9-F2M)"
	_host_panel.visible = false


func _show_server_settings_dialog() -> void:
	var dlg := ConfirmationDialog.new()
	dlg.title = "Адрес сервера"
	dlg.ok_button_text = "Сохранить"
	dlg.cancel_button_text = "Отмена"

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	dlg.add_child(vb)

	var lbl := Label.new()
	lbl.text = "WebSocket URL мастер-сервера:"
	vb.add_child(lbl)

	var input := LineEdit.new()
	input.text = net.server_url if net != null else Net.DEFAULT_SERVER_URL
	input.custom_minimum_size = Vector2(360, 40)
	vb.add_child(input)

	dlg.confirmed.connect(func():
		var u: String = input.text.strip_edges()
		if u != "" and net != null:
			net.connect_online(u)
			_net_status_label.text = "Адрес сервера обновлён")
	add_child(dlg)
	dlg.popup_centered()


func _on_create_host_pressed() -> void:
	if net == null:
		return
	var r_name: String = _room_name_input.text.strip_edges()
	if _net_game_type in ["multi", "d20_multi"]:
		var is_d20: bool = (_net_game_type == "d20_multi")
		if _multi_online_mode:
			_net_status_label.text = "Создание комнаты на сервере..."
			net.online_create_multi_room(_net_multi_sub_mode, _net_multi_color, r_name, is_d20)
		else:
			net.game_type = _net_game_type
			var err: String = net.host(_net_multi_sub_mode, _net_multi_color, r_name)
			if err != "":
				_net_status_label.text = err
				return
			_host_panel.visible = true
			_host_code_label.text = "Код комнаты: %s" % net.room_code
			_net_status_label.text = "LAN-комната создана"
	else:
		if _multi_online_mode:
			_net_status_label.text = "Создание комнаты на сервере..."
			net.online_create_room(_selected_variant_id(), _picked_color(), r_name)
		else:
			net.game_type = "5d"
			var err: String = net.host(_selected_variant_id(), _picked_color(), r_name)
			if err != "":
				_net_status_label.text = err
				return
			_host_panel.visible = true
			_host_code_label.text = "Код комнаты: %s" % net.room_code
			_net_status_label.text = "LAN-сервер запущен. Ожидание соперника..."


func _on_join_code_pressed() -> void:
	if net == null:
		return
	var input: String = _room_code_input.text.strip_edges()
	if input == "":
		_net_status_label.text = "Введите код комнаты"
		return

	if _multi_online_mode:
		_net_status_label.text = "Подключение к %s..." % input
		net.online_join_room(input)
	else:
		var err: String = net.join_by_code(input)
		if err != "":
			_net_status_label.text = err
			return
		_net_status_label.text = "Подключение к %s..." % input


func _on_net_room_created(code: String) -> void:
	_host_panel.visible = true
	_host_code_label.text = "Код комнаты: %s" % code
	_net_status_label.text = "Комната создана. Код для приглашения: %s" % code
	if _lobby_start_btn != null:
		_lobby_start_btn.visible = net.is_host


func _on_net_status_message(msg: String) -> void:
	if _net_status_label != null:
		_net_status_label.text = msg


func _on_server_list_updated(servers: Array) -> void:
	for child in _server_list_container.get_children():
		child.queue_free()

	_no_servers_label.visible = servers.is_empty()
	var is_compact: bool = get_viewport_rect().size.x < 560.0

	for s in servers:
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", _glass_panel_style(8, Color(0.055, 0.075, 0.125, 0.90), Color(0.16, 0.22, 0.34, 0.80)))
		_server_list_container.add_child(card)

		var row := BoxContainer.new()
		row.vertical = is_compact
		row.add_theme_constant_override("separation", 10)
		card.add_child(row)

		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)

		var s_name := Label.new()
		s_name.text = str(s.get("name", "Игровая комната"))
		s_name.add_theme_font_size_override("font_size", 15)
		s_name.add_theme_color_override("font_color", Color(0.94, 0.95, 0.98))
		info.add_child(s_name)

		var s_sub := Label.new()
		var code: String = str(s.get("code", ""))
		var g_type: String = str(s.get("game_type", "5d"))
		var variant: String = str(s.get("variant", "standard"))
		var cur_p: int = int(s.get("current_players", 1))
		var max_p: int = int(s.get("max_players", 2))

		var mode_badge := ""
		if g_type == "d20_multi":
			mode_badge = "D20 " + variant
		elif g_type == "multi":
			mode_badge = "Мульти " + variant
		else:
			mode_badge = "5D (%s)" % variant

		s_sub.text = "%s · Игроков: %d/%d · Код: %s" % [mode_badge, cur_p, max_p, code]
		s_sub.add_theme_font_size_override("font_size", 12)
		s_sub.add_theme_color_override("font_color", Color(0.58, 0.66, 0.78))
		info.add_child(s_sub)

		var join_btn := _action_btn("Войти", func():
			if _multi_online_mode:
				_net_status_label.text = "Подключение к %s..." % code
				net.online_join_room(code)
			else:
				var err: String = net.join(str(s.get("ip", "")))
				if err != "":
					_net_status_label.text = err
				else:
					_net_status_label.text = "Подключение...")
		join_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL if is_compact else Control.SIZE_SHRINK_END
		if not is_compact:
			join_btn.custom_minimum_size = Vector2(130, 38)
		row.add_child(join_btn)


# ---------------------------------------------------------------- Вкладка 4: Профиль и коллекция скинов

func _build_profile_tab() -> Control:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)

	# 1. Карточка игрока и сводная статистика
	var id_card := PanelContainer.new()
	id_card.add_theme_stylebox_override("panel", _glass_panel_style(12))
	vb.add_child(id_card)

	var id_main_vb := VBoxContainer.new()
	id_main_vb.add_theme_constant_override("separation", 14)
	id_card.add_child(id_main_vb)

	_profile_header_box = BoxContainer.new()
	_profile_header_box.vertical = false
	_profile_header_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_profile_header_box.add_theme_constant_override("separation", 14)
	id_main_vb.add_child(_profile_header_box)

	_profile_avatar_preview = PieceButton.new()
	_profile_avatar_preview.custom_minimum_size = Vector2(76, 76)
	_profile_avatar_preview.piece = Profile.get_avatar_code()
	_profile_avatar_preview.is_selected_slot = true
	_profile_header_box.add_child(_profile_avatar_preview)

	var info_vb := VBoxContainer.new()
	info_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vb.add_theme_constant_override("separation", 6)
	_profile_header_box.add_child(info_vb)

	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	info_vb.add_child(name_row)

	_profile_name_edit = LineEdit.new()
	_profile_name_edit.text = Profile.player_name
	_profile_name_edit.placeholder_text = "Имя игрока"
	_profile_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_profile_name_edit.custom_minimum_size.y = 38
	_profile_name_edit.add_theme_font_size_override("font_size", 15)
	_style_line_edit(_profile_name_edit)
	_profile_name_edit.text_changed.connect(func(new_text: String):
		Profile.set_nickname(new_text)
		if _room_name_input != null:
			_room_name_input.text = "Комната " + Profile.player_name)
	name_row.add_child(_profile_name_edit)

	var meta_row := HBoxContainer.new()
	meta_row.add_theme_constant_override("separation", 12)
	info_vb.add_child(meta_row)

	_profile_rating_lbl = Label.new()
	_profile_rating_lbl.text = "%d ELO" % Profile.rating
	_profile_rating_lbl.add_theme_font_size_override("font_size", 16)
	_profile_rating_lbl.add_theme_color_override("font_color", Color(0.45, 0.78, 0.98))
	meta_row.add_child(_profile_rating_lbl)

	_profile_title_lbl = Label.new()
	_profile_title_lbl.text = Profile.get_title()
	_profile_title_lbl.add_theme_font_size_override("font_size", 14)
	_profile_title_lbl.add_theme_color_override("font_color", Color(0.92, 0.78, 0.38))
	meta_row.add_child(_profile_title_lbl)

	id_main_vb.add_child(_divider())

	# Блок статистики внутри карточки профиля
	_profile_stats_lbl = Label.new()
	_profile_stats_lbl.add_theme_font_size_override("font_size", 13)
	_profile_stats_lbl.add_theme_color_override("font_color", Color(0.84, 0.88, 0.94))
	id_main_vb.add_child(_profile_stats_lbl)

	_profile_winrate_lbl = Label.new()
	_profile_winrate_lbl.add_theme_font_size_override("font_size", 13)
	_profile_winrate_lbl.add_theme_color_override("font_color", Color(0.58, 0.86, 0.70))
	id_main_vb.add_child(_profile_winrate_lbl)

	_profile_streaks_lbl = Label.new()
	_profile_streaks_lbl.add_theme_font_size_override("font_size", 13)
	_profile_streaks_lbl.add_theme_color_override("font_color", Color(0.58, 0.66, 0.78))
	id_main_vb.add_child(_profile_streaks_lbl)

	_profile_5d_lbl = Label.new()
	_profile_5d_lbl.add_theme_font_size_override("font_size", 13)
	_profile_5d_lbl.add_theme_color_override("font_color", Color(0.58, 0.66, 0.78))
	_profile_5d_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	id_main_vb.add_child(_profile_5d_lbl)

	# 2. Выбор гербовой фигуры (аватара)
	var avatar_card := PanelContainer.new()
	avatar_card.add_theme_stylebox_override("panel", _glass_panel_style(12))
	vb.add_child(avatar_card)

	var av_vb := VBoxContainer.new()
	av_vb.add_theme_constant_override("separation", 10)
	avatar_card.add_child(av_vb)

	var av_header := HBoxContainer.new()
	av_header.add_theme_constant_override("separation", 8)
	av_vb.add_child(av_header)

	var av_title := _field_label("Фигура профиля")
	av_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	av_header.add_child(av_title)

	var col_btn_w := _create_selectable_btn("Светлая", not Profile.avatar_is_black)
	var col_btn_b := _create_selectable_btn("Тёмная", Profile.avatar_is_black)
	col_btn_w.custom_minimum_size = Vector2(96, 36)
	col_btn_b.custom_minimum_size = Vector2(96, 36)
	av_header.add_child(col_btn_w)
	av_header.add_child(col_btn_b)

	col_btn_w.pressed.connect(func():
		Profile.set_avatar(Profile.avatar_piece, false)
		_set_btn_active(col_btn_w, true)
		_set_btn_active(col_btn_b, false)
		_refresh_avatar_selection()
		if sfx != null:
			sfx.play("click"))
	col_btn_b.pressed.connect(func():
		Profile.set_avatar(Profile.avatar_piece, true)
		_set_btn_active(col_btn_w, false)
		_set_btn_active(col_btn_b, true)
		_refresh_avatar_selection()
		if sfx != null:
			sfx.play("click"))

	var pieces_box := HBoxContainer.new()
	pieces_box.alignment = BoxContainer.ALIGNMENT_CENTER
	pieces_box.add_theme_constant_override("separation", 8)
	av_vb.add_child(pieces_box)

	var piece_types := [
		GameState.KING, GameState.QUEEN, GameState.DRAGON, GameState.UNICORN,
		GameState.PRINCESS, GameState.KNIGHT, GameState.ROOK, GameState.BISHOP
	]
	_avatar_piece_btns.clear()

	for pt in piece_types:
		var pb := PieceButton.new()
		pb.custom_minimum_size = Vector2(50, 50)
		pb.piece = pt | (GameState.BLACK_BIT if Profile.avatar_is_black else 0)
		pb.is_selected_slot = (Profile.avatar_piece == pt)
		pb.pressed.connect(func():
			Profile.set_avatar(pt, Profile.avatar_is_black)
			_refresh_avatar_selection()
			if sfx != null:
				sfx.play("click"))
		pieces_box.add_child(pb)
		_avatar_piece_btns.append({"btn": pb, "type": pt})

	# 3. Коллекция стилизованных наборов фигур
	var shop_card := PanelContainer.new()
	shop_card.add_theme_stylebox_override("panel", _glass_panel_style(12))
	vb.add_child(shop_card)

	var sh_vb := VBoxContainer.new()
	sh_vb.add_theme_constant_override("separation", 10)
	shop_card.add_child(sh_vb)

	sh_vb.add_child(_field_label("Коллекция фигур и материалов"))

	_skins_container = VBoxContainer.new()
	_skins_container.add_theme_constant_override("separation", 8)
	sh_vb.add_child(_skins_container)

	# Сброс статистики
	var reset_btn := _action_btn("Сбросить статистику", _on_reset_stats_pressed)
	reset_btn.custom_minimum_size = Vector2(200, 38)
	reset_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(reset_btn)

	_refresh_profile_ui()
	return vb


func _refresh_avatar_selection() -> void:
	if _profile_avatar_preview != null:
		_profile_avatar_preview.piece = Profile.get_avatar_code()
		_profile_avatar_preview.queue_redraw()
	for item in _avatar_piece_btns:
		var pb: PieceButton = item["btn"]
		var pt: int = item["type"]
		pb.piece = pt | (GameState.BLACK_BIT if Profile.avatar_is_black else 0)
		pb.is_selected_slot = (Profile.avatar_piece == pt)
		pb.queue_redraw()


func _refresh_profile_ui() -> void:
	if _profile_name_edit != null and not _profile_name_edit.has_focus():
		_profile_name_edit.text = Profile.player_name
	if _profile_title_lbl != null:
		_profile_title_lbl.text = Profile.get_title()
	if _profile_rating_lbl != null:
		_profile_rating_lbl.text = "%d ELO" % Profile.rating
	if _profile_avatar_preview != null:
		_profile_avatar_preview.piece = Profile.get_avatar_code()
		_profile_avatar_preview.queue_redraw()
	if _profile_stats_lbl != null:
		_profile_stats_lbl.text = "Партий: %d  ·  Побед: %d  ·  Поражений: %d  ·  Ничьих: %d" % [
			Profile.games_played, Profile.wins, Profile.losses, Profile.draws
		]
	if _profile_winrate_lbl != null:
		_profile_winrate_lbl.text = "Винрейт: %.1f%%  ·  Побед в сети: %d  ·  Побед над ИИ: %d" % [
			Profile.get_winrate(), Profile.online_wins, Profile.ai_wins
		]
	if _profile_streaks_lbl != null:
		_profile_streaks_lbl.text = "Серия побед: %d (лучшая: %d)" % [
			Profile.win_streak, Profile.best_streak
		]
	if _profile_5d_lbl != null:
		_profile_5d_lbl.text = "Создано временных линий: %d  ·  Прыжков во времени: %d" % [
			Profile.timelines_created, Profile.temporal_jumps
		]
	_refresh_skins_ui()
	_update_crystals_display()


func _refresh_skins_ui() -> void:
	if _skins_container == null:
		return
	for c in _skins_container.get_children():
		c.queue_free()

	var is_phone: bool = get_viewport_rect().size.x < 620.0

	for s in Skins.LIST:
		var s_id: String = str(s.get("id", ""))
		var s_name: String = str(s.get("name", ""))
		var s_desc: String = str(s.get("desc", ""))
		var price: int = int(s.get("price", 0))
		var is_owned: bool = Profile.owned_skins.has(s_id)
		var is_active: bool = (Profile.active_skin == s_id)

		var card := PanelContainer.new()
		var card_sb := StyleBoxFlat.new()
		card_sb.bg_color = Color(0.055, 0.075, 0.125, 0.92)
		if is_active:
			card_sb.border_color = Color(0.88, 0.72, 0.28, 0.90)
			card_sb.set_border_width_all(1)
		else:
			card_sb.border_color = Color(0.14, 0.19, 0.28, 0.80)
			card_sb.set_border_width_all(1)
		card_sb.set_corner_radius_all(8)
		card_sb.content_margin_left = 12
		card_sb.content_margin_right = 12
		card_sb.content_margin_top = 10
		card_sb.content_margin_bottom = 10
		card.add_theme_stylebox_override("panel", card_sb)
		_skins_container.add_child(card)

		var row := BoxContainer.new()
		row.vertical = is_phone
		row.add_theme_constant_override("separation", 8 if is_phone else 14)
		card.add_child(row)

		var top_part := HBoxContainer.new()
		top_part.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top_part.add_theme_constant_override("separation", 10)
		row.add_child(top_part)

		var prev_box := HBoxContainer.new()
		prev_box.add_theme_constant_override("separation", 4)
		top_part.add_child(prev_box)

		var sample_pieces: Array = [
			GameState.KING,
			GameState.KING | GameState.BLACK_BIT,
			GameState.KNIGHT,
			GameState.DRAGON | GameState.BLACK_BIT
		]
		for p_code in sample_pieces:
			var pb := PieceButton.new()
			pb.custom_minimum_size = Vector2(44, 44)
			pb.piece = p_code
			pb.override_skin = s_id
			pb.mouse_filter = Control.MOUSE_FILTER_IGNORE
			prev_box.add_child(pb)

		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_constant_override("separation", 2)
		top_part.add_child(info)

		var t_lbl := Label.new()
		var price_str := "" if is_owned else (" · %d ◆" % price)
		t_lbl.text = s_name + price_str
		t_lbl.add_theme_font_size_override("font_size", 14)
		t_lbl.add_theme_color_override("font_color", Color(0.96, 0.84, 0.38) if is_active else Color(0.94, 0.95, 0.98))
		t_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(t_lbl)

		var d_lbl := Label.new()
		d_lbl.text = s_desc
		d_lbl.add_theme_font_size_override("font_size", 12)
		d_lbl.add_theme_color_override("font_color", Color(0.58, 0.66, 0.78))
		d_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(d_lbl)

		var act_btn := Button.new()
		act_btn.custom_minimum_size = Vector2(0, 36) if is_phone else Vector2(130, 36)
		act_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL if is_phone else Control.SIZE_SHRINK_END
		act_btn.focus_mode = Control.FOCUS_NONE

		if is_active:
			act_btn.text = "Выбрано"
			act_btn.disabled = true
			var st := StyleBoxFlat.new()
			st.bg_color = Color(0.12, 0.16, 0.24, 0.6)
			st.border_color = Color(0.88, 0.72, 0.28, 0.6)
			st.set_border_width_all(1)
			st.set_corner_radius_all(6)
			act_btn.add_theme_stylebox_override("disabled", st)
		elif is_owned:
			act_btn.text = "Выбрать"
			var st := StyleBoxFlat.new()
			st.bg_color = Color(0.14, 0.24, 0.44, 0.95)
			st.border_color = Color(0.32, 0.56, 0.92, 0.85)
			st.set_border_width_all(1)
			st.set_corner_radius_all(6)
			act_btn.add_theme_stylebox_override("normal", st)
			act_btn.pressed.connect(func():
				Profile.equip_skin(s_id)
				if sfx != null:
					sfx.play("click")
				_refresh_skins_ui()
				_refresh_avatar_selection()
				_update_crystals_display())
		else:
			var can_afford: bool = (Profile.crystals >= price)
			act_btn.text = "Купить (%d ◆)" % price
			if can_afford:
				var st := StyleBoxFlat.new()
				st.bg_color = Color(0.16, 0.44, 0.28, 0.95)
				st.border_color = Color(0.32, 0.78, 0.48)
				st.set_border_width_all(1)
				st.set_corner_radius_all(6)
				act_btn.add_theme_stylebox_override("normal", st)
				act_btn.pressed.connect(func():
					if Profile.buy_skin(s_id):
						if sfx != null:
							sfx.play("win")
						_refresh_skins_ui()
						_refresh_avatar_selection()
						_update_crystals_display())
			else:
				act_btn.disabled = true
				var st := StyleBoxFlat.new()
				st.bg_color = Color(0.09, 0.12, 0.18, 0.5)
				st.set_corner_radius_all(6)
				act_btn.add_theme_stylebox_override("disabled", st)

		row.add_child(act_btn)


func _update_crystals_display() -> void:
	if _crystal_badge_btn != null:
		_crystal_badge_btn.text = "◆ %d" % Profile.crystals
	if _profile_chip_ref != null:
		_profile_chip_ref.text = "%d ELO" % Profile.rating


func _on_reset_stats_pressed() -> void:
	var dlg := ConfirmationDialog.new()
	dlg.title = "Сброс статистики"
	dlg.dialog_text = "Обнулить статистику партий и вернуть стартовый рейтинг?"
	dlg.ok_button_text = "Сбросить"
	dlg.cancel_button_text = "Отмена"
	dlg.confirmed.connect(func():
		Profile.reset_stats()
		_refresh_profile_ui()
		if sfx != null:
			sfx.play("click"))
	add_child(dlg)
	dlg.popup_centered()


# ---------------------------------------------------------------- Вкладка 5: Правила

func _build_rules_tab() -> Control:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)

	var card_5d := PanelContainer.new()
	card_5d.add_theme_stylebox_override("panel", _glass_panel_style(12))
	vb.add_child(card_5d)

	var vb_5d := VBoxContainer.new()
	vb_5d.add_theme_constant_override("separation", 8)
	card_5d.add_child(vb_5d)

	vb_5d.add_child(_field_label("Основы 5D-шахмат"))

	var text_block := Label.new()
	text_block.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_block.text = (
		"1. Координаты (X, Y, T, L):\n"
		+ "По горизонтали (T) идут ходы во времени, по вертикали (L) — параллельные временные линии.\n\n"
		+ "2. Линия настоящего (Present):\n"
		+ "Вертикальная полоса отмечает самую раннюю активную доску. Чтобы завершить ход, необходимо сделать ход на каждой доске с золотой рамкой.\n\n"
		+ "3. Прыжки в прошлое:\n"
		+ "Фигуры могут перемещаться на предыдущие ходы (T) и соседние линии (L). Ход на доску в прошлом создаёт новую ветвь реальности.\n\n"
		+ "4. Новые фигуры мультивселенной:\n"
		+ "• Единорог — ходит по триагоналям (одновременно меняет 3 координаты).\n"
		+ "• Дракон — ходит по квадриагоналям (одновременно меняет все 4 координаты).\n"
		+ "• Принцесса — объединяет ходы ладьи и слона в пространстве и времени."
	)
	text_block.add_theme_font_size_override("font_size", 13)
	text_block.add_theme_color_override("font_color", Color(0.76, 0.82, 0.90))
	vb_5d.add_child(text_block)

	var card_multi := PanelContainer.new()
	card_multi.add_theme_stylebox_override("panel", _glass_panel_style(12))
	vb.add_child(card_multi)

	var vb_multi := VBoxContainer.new()
	vb_multi.add_theme_constant_override("separation", 8)
	card_multi.add_child(vb_multi)

	vb_multi.add_child(_field_label("Мульти-шахматы 14×14 и D20 Битва"))

	var multi_block := Label.new()
	multi_block.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	multi_block.text = (
		"1. Крестообразная доска 14×14:\n"
		+ "Центральное поле 8×8 и четыре фланга 3×8 для Белых, Красных, Чёрных и Синих армий.\n\n"
		+ "2. Режимы:\n"
		+ "• 1×1×1 — три армии, каждый сам за себя.\n"
		+ "• 2×2 — команда Белые + Чёрные против Красных + Синих.\n"
		+ "• 1×1×1×1 — четыре армии, побеждает последний выживший король.\n\n"
		+ "3. Режим D20 Битва:\n"
		+ "При попытке взятия бросается кубик d20 против порога 10 + (Сила цели − Сила атаки) × 2. При успехе фигура берётся, при промахе атакующий отступает."
	)
	multi_block.add_theme_font_size_override("font_size", 13)
	multi_block.add_theme_color_override("font_color", Color(0.76, 0.82, 0.90))
	vb_multi.add_child(multi_block)

	return vb


# ---------------------------------------------------------------- Дизайн-система и элементы управления

func _field_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.84, 0.88, 0.94))
	return lbl


func _divider() -> ColorRect:
	var div := ColorRect.new()
	div.custom_minimum_size.y = 1
	div.color = Color(0.14, 0.19, 0.28, 0.80)
	return div


func _style_line_edit(le: LineEdit) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.07, 0.12, 0.95)
	sb.border_color = Color(0.16, 0.22, 0.34, 0.90)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	le.add_theme_stylebox_override("normal", sb)

	var focus_sb := sb.duplicate()
	focus_sb.border_color = Color(0.35, 0.62, 0.98, 0.95)
	le.add_theme_stylebox_override("focus", focus_sb)


func _style_option_button(ob: OptionButton) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.11, 0.18, 0.95)
	sb.border_color = Color(0.18, 0.25, 0.38, 0.90)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	ob.add_theme_stylebox_override("normal", sb)
	ob.add_theme_stylebox_override("hover", sb)
	ob.add_theme_stylebox_override("pressed", sb)


func _glass_panel_style(radius: int, bg: Color = Color(0.07, 0.095, 0.15, 0.94), border: Color = Color(0.14, 0.19, 0.28, 0.85), border_width: int = 1) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_width)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	return sb


func _create_selectable_btn(text: String, is_selected: bool) -> Button:
	var b := Button.new()
	b.text = text
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(110, 42)
	b.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.add_theme_font_size_override("font_size", 13)
	_set_btn_active(b, is_selected)
	return b


func _set_btn_active(b: Button, active: bool) -> void:
	var sb := StyleBoxFlat.new()
	if active:
		sb.bg_color = Color(0.13, 0.24, 0.46, 0.98)
		sb.border_color = Color(0.35, 0.62, 0.98, 0.95)
		sb.set_border_width_all(1)
		b.add_theme_color_override("font_color", Color.WHITE)
	else:
		sb.bg_color = Color(0.08, 0.11, 0.18, 0.85)
		sb.border_color = Color(0.15, 0.20, 0.30, 0.80)
		sb.set_border_width_all(1)
		b.add_theme_color_override("font_color", Color(0.64, 0.72, 0.84))
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	b.add_theme_stylebox_override("normal", sb)

	var hover := sb.duplicate()
	if not active:
		hover.bg_color = Color(0.11, 0.15, 0.24, 0.95)
		hover.border_color = Color(0.24, 0.36, 0.56, 0.85)
	b.add_theme_stylebox_override("hover", hover)

	var pressed_sb := sb.duplicate()
	pressed_sb.bg_color = Color(0.16, 0.28, 0.54, 0.98)
	b.add_theme_stylebox_override("pressed", pressed_sb)


func _set_army_btn_style(b: Button, active: bool, theme_col: Color, active_bg: Color) -> void:
	var sb := StyleBoxFlat.new()
	if active:
		sb.bg_color = active_bg
		sb.border_color = theme_col
		sb.set_border_width_all(1)
		b.add_theme_color_override("font_color", Color.WHITE)
	else:
		sb.bg_color = Color(0.08, 0.11, 0.18, 0.85)
		sb.border_color = Color(0.15, 0.20, 0.30, 0.80)
		sb.set_border_width_all(1)
		b.add_theme_color_override("font_color", Color(0.64, 0.72, 0.84))
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	b.add_theme_stylebox_override("normal", sb)

	var hover := sb.duplicate()
	if not active:
		hover.bg_color = Color(0.11, 0.15, 0.24, 0.95)
		hover.border_color = theme_col * Color(1.0, 1.0, 1.0, 0.55)
	b.add_theme_stylebox_override("hover", hover)

	var pressed_sb := sb.duplicate()
	pressed_sb.bg_color = active_bg.lightened(0.15)
	b.add_theme_stylebox_override("pressed", pressed_sb)


func _action_btn(text: String, cb: Callable = Callable()) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(130, 42)
	b.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.add_theme_font_size_override("font_size", 13)
	b.add_theme_color_override("font_color", Color(0.92, 0.95, 0.98))

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.11, 0.17, 0.28, 0.95)
	sb.border_color = Color(0.22, 0.34, 0.54, 0.85)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	b.add_theme_stylebox_override("normal", sb)

	var hover: StyleBoxFlat = sb.duplicate()
	hover.bg_color = Color(0.15, 0.23, 0.38, 0.98)
	hover.border_color = Color(0.35, 0.56, 0.88, 0.95)
	b.add_theme_stylebox_override("hover", hover)

	var pressed_sb: StyleBoxFlat = sb.duplicate()
	pressed_sb.bg_color = Color(0.09, 0.14, 0.24, 1.0)
	b.add_theme_stylebox_override("pressed", pressed_sb)

	if cb.is_valid():
		b.pressed.connect(func():
			if sfx != null:
				sfx.play("move")
			cb.call())
	return b


func _pill_action_btn(text: String, cb: Callable = Callable(), min_w: float = 0.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_w, 32)
	b.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.add_theme_font_size_override("font_size", 12)
	b.add_theme_color_override("font_color", Color(0.88, 0.92, 0.98))

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.13, 0.22, 0.90)
	sb.border_color = Color(0.18, 0.26, 0.40, 0.85)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(16)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	b.add_theme_stylebox_override("normal", sb)

	var hover: StyleBoxFlat = sb.duplicate()
	hover.bg_color = Color(0.13, 0.19, 0.32, 0.95)
	b.add_theme_stylebox_override("hover", hover)

	var pressed_sb: StyleBoxFlat = sb.duplicate()
	pressed_sb.bg_color = Color(0.07, 0.11, 0.18, 1.0)
	b.add_theme_stylebox_override("pressed", pressed_sb)

	if cb.is_valid():
		b.pressed.connect(func():
			if sfx != null:
				sfx.play("move")
			cb.call())
	return b


func _icon_action_btn(icon_text: String, cb: Callable = Callable()) -> Button:
	var b := Button.new()
	b.text = icon_text
	b.custom_minimum_size = Vector2(0, 32)
	b.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.add_theme_font_size_override("font_size", 12)
	b.add_theme_color_override("font_color", Color(0.78, 0.84, 0.92))

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.13, 0.22, 0.90)
	sb.border_color = Color(0.18, 0.26, 0.40, 0.85)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	b.add_theme_stylebox_override("normal", sb)

	var hover := sb.duplicate()
	hover.bg_color = Color(0.13, 0.19, 0.32, 0.95)
	b.add_theme_stylebox_override("hover", hover)

	var pressed_sb := sb.duplicate()
	pressed_sb.bg_color = Color(0.07, 0.11, 0.18, 1.0)
	b.add_theme_stylebox_override("pressed", pressed_sb)

	if cb.is_valid():
		b.pressed.connect(func():
			if sfx != null:
				sfx.play("click")
			cb.call())
	return b


func _picked_color() -> int:
	if _color_choice == 0:
		return GameState.WHITE
	if _color_choice == 1:
		return GameState.BLACK
	return randi() % 2


func _selected_variant_id() -> String:
	return Variants.LIST[_variant_idx]["id"]


func _launch(mode: String) -> void:
	if net != null:
		net.close()
	if sfx != null:
		sfx.play("submit")
	start_game.emit(_selected_variant_id(), mode, _picked_color(), _ai_level, [])


func _on_net_game_started(variant_id: String, my_color: int) -> void:
	if sfx != null:
		sfx.play("submit")
	start_game.emit(variant_id, GameScreen.MODE_ONLINE, my_color, _ai_level, [])


func _on_net_reconnected(_missed_turns: Array, turn_history: Array) -> void:
	if sfx != null:
		sfx.play("submit")
	start_game.emit(net.session_variant, GameScreen.MODE_ONLINE, net.session_my_color, _ai_level, turn_history)


func _on_net_disconnected(reason: String) -> void:
	_net_status_label.text = reason
	_host_panel.visible = false


func _on_net_multi_game_started(sub_mode: String, my_color: int, player_slots: Array, is_d20: bool = false) -> void:
	if sfx != null:
		sfx.play("submit")
	start_multi_game.emit(sub_mode, false, my_color, MultiChessAI.LEVEL_NORMAL, net, player_slots, is_d20)


func _on_net_room_lobby_updated(data: Dictionary) -> void:
	_host_panel.visible = true
	var code: String = str(data.get("code", net.room_code))
	var g_type: String = str(data.get("game_type", "5d"))
	var variant: String = str(data.get("variant", ""))
	var max_p: int = int(data.get("max_players", 2))
	var players: Array = data.get("players", [])

	_host_code_label.text = "Код комнаты: %s" % code

	var type_title := ""
	if g_type == "d20_multi":
		type_title = "D20 Мульти-шахматы " + variant
	elif g_type == "multi":
		type_title = "Мульти-шахматы " + variant
	else:
		type_title = "5D Хроно-шахматы (" + variant + ")"
	if _lobby_info_label != null:
		_lobby_info_label.text = "%s · Игроков: %d из %d" % [type_title, players.size(), max_p]

	if _lobby_players_box != null:
		for child in _lobby_players_box.get_children():
			child.queue_free()

		for i in max_p:
			var slot_card := PanelContainer.new()
			var p_data: Dictionary = {}
			for p in players:
				if int(p.get("color", -1)) == i:
					p_data = p
					break

			var is_multi_lobby: bool = g_type in ["multi", "d20_multi"]
			var col: Color = MultiChessState.PLAYER_COLORS[i] if (is_multi_lobby and i < MultiChessState.PLAYER_COLORS.size()) else (Color(0.92, 0.94, 0.98) if i == 0 else Color(0.68, 0.72, 0.82))
			var col_name: String = MultiChessState.PLAYER_NAMES[i] if (is_multi_lobby and i < MultiChessState.PLAYER_NAMES.size()) else ("Белые" if i == 0 else "Чёрные")

			var card_sb := StyleBoxFlat.new()
			card_sb.set_corner_radius_all(6)
			card_sb.set_border_width_all(1)

			var lbl := Label.new()
			lbl.add_theme_font_size_override("font_size", 13)

			if not p_data.is_empty():
				var p_name: String = str(p_data.get("name", "Игрок"))
				var is_h: bool = bool(p_data.get("is_host", false))
				var p_skin: String = str(p_data.get("skin", "classic"))
				var s_info := Skins.get_skin(p_skin)
				var s_name: String = str(s_info.get("name", "Классический Стаунтон"))
				var host_tag := " (Хост)" if is_h else ""
				lbl.text = "%s%s — %s · %s" % [p_name, host_tag, col_name, s_name]
				card_sb.bg_color = col.darkened(0.75)
				card_sb.border_color = col.darkened(0.15)
				lbl.add_theme_color_override("font_color", Color.WHITE)
			else:
				lbl.text = "Слот %d: Ожидание игрока (%s)" % [i + 1, col_name]
				card_sb.bg_color = Color(0.06, 0.08, 0.14, 0.7)
				card_sb.border_color = Color(0.16, 0.22, 0.34, 0.6)
				lbl.add_theme_color_override("font_color", Color(0.55, 0.62, 0.74))

			card_sb.content_margin_left = 10
			card_sb.content_margin_right = 10
			card_sb.content_margin_top = 6
			card_sb.content_margin_bottom = 6
			slot_card.add_theme_stylebox_override("panel", card_sb)
			slot_card.add_child(lbl)
			_lobby_players_box.add_child(slot_card)

	if _lobby_start_btn != null:
		_lobby_start_btn.visible = net.is_host
