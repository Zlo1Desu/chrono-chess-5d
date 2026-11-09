class_name MenuScreen
extends Control
## Главное меню: анимированный интерфейс, одиночная игра, браузер серверов и подключение по коду комнаты.

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

# Звёзды и метеоры фона
var _stars: Array = []
var _shooting_stars: Array = []


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
	rng.seed = 123
	var star_colors := [
		Color(1.0, 1.0, 1.0),          # Бриллиантовый белый
		Color(0.65, 0.88, 1.0),        # Квантовый циан
		Color(1.0, 0.90, 0.70),        # Золотистый свет
		Color(0.88, 0.72, 1.0),        # Фиолетовая дымка
	]
	for i in 140:
		_stars.append({
			"pos": Vector2(rng.randf(), rng.randf()),
			"size": rng.randf_range(1.0, 2.6),
			"alpha": rng.randf_range(0.25, 0.85),
			"speed": rng.randf_range(1.0, 3.2),
			"phase": rng.randf_range(0.0, TAU),
			"color": star_colors[rng.randi() % star_colors.size()],
			"glint": rng.randf() < 0.22,
		})

	for i in 3:
		_shooting_stars.append({
			"active": false,
			"pos": Vector2.ZERO,
			"dir": Vector2.ZERO,
			"speed": 0.0,
			"len": 0.0,
			"prog": 0.0,
			"timer": rng.randf_range(1.5, 6.0 + i * 4.0),
		})

	_build_ui()
	_switch_tab(0)

	get_viewport().size_changed.connect(_on_viewport_resized)
	_on_viewport_resized()


func _process(delta: float) -> void:
	_anim_time += delta
	var rng := RandomNumberGenerator.new()
	for s in _shooting_stars:
		if bool(s["active"]):
			s["prog"] = float(s["prog"]) + delta * (float(s["speed"]) / float(s["len"]))
			s["pos"] = Vector2(s["pos"]) + Vector2(s["dir"]) * (float(s["speed"]) * delta)
			if float(s["prog"]) >= 1.0:
				s["active"] = false
				s["timer"] = rng.randf_range(4.0, 10.0)
		else:
			s["timer"] = float(s["timer"]) - delta
			if float(s["timer"]) <= 0.0:
				s["active"] = true
				s["prog"] = 0.0
				var sx := rng.randf_range(0.0, size.x * 0.9)
				var sy := rng.randf_range(0.0, size.y * 0.45)
				s["pos"] = Vector2(sx, sy)
				var angle := deg_to_rad(rng.randf_range(28.0, 48.0))
				s["dir"] = Vector2(cos(angle), sin(angle))
				s["len"] = rng.randf_range(140.0, 280.0)
				s["speed"] = rng.randf_range(350.0, 650.0)
	queue_redraw()


# ---------------------------------------------------------------- Отрисовка фона

func _draw() -> void:
	# 1. Глубокий космический градиент (темнейшая бездна)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.015, 0.02, 0.045))

	# 2. Трехслойные процедурные космические туманности
	var pulse: float = sin(_anim_time * 0.7) * 0.03 + 0.08
	var pulse2: float = cos(_anim_time * 0.5) * 0.03 + 0.07

	var cx1: Vector2 = Vector2(size.x * 0.22 + sin(_anim_time * 0.25) * 30.0, size.y * 0.28)
	var cx2: Vector2 = Vector2(size.x * 0.82 + cos(_anim_time * 0.3) * 40.0, size.y * 0.72)
	var cx3: Vector2 = Vector2(size.x * 0.5 + sin(_anim_time * 0.2) * 50.0, size.y * 0.95)

	# Фиолетово-пурпурная туманность
	draw_circle(cx1, size.x * 0.38, Color(0.24, 0.08, 0.48, pulse * 0.95))
	# Неоново-бирюзовая космическая дымка
	draw_circle(cx2, size.x * 0.42, Color(0.04, 0.28, 0.52, pulse2 * 1.35))
	# Квантовая золотисто-янтарная туманность в основании
	draw_circle(cx3, size.x * 0.35, Color(0.35, 0.16, 0.04, pulse * 0.7))

	# 3. Квантовая координатная сетка перспективы (эффект 5D таймлайна)
	var horizon_y: float = size.y * 0.62
	var grid_steps := 9
	for i in grid_steps:
		var frac: float = float(i + 1) / float(grid_steps)
		var y_pos: float = lerpf(horizon_y, size.y, frac * frac)
		var grid_alpha: float = (frac * frac) * 0.12
		draw_line(Vector2(0.0, y_pos), Vector2(size.x, y_pos), Color(0.25, 0.65, 1.0, grid_alpha), 1.0)

	var ray_count := 12
	var vanish_pt := Vector2(size.x * 0.5, horizon_y)
	for i in ray_count + 1:
		var ray_frac: float = float(i) / float(ray_count)
		var bottom_x: float = lerpf(-size.x * 0.2, size.x * 1.2, ray_frac)
		var bottom_pt := Vector2(bottom_x, size.y)
		draw_line(vanish_pt, bottom_pt, Color(0.20, 0.55, 0.95, 0.07), 1.0)

	# 3.5. Вращающаяся голографическая Хроно-сфера (Квантовый хронометр 5D)
	var chrono_center := Vector2(size.x * 0.5, size.y * 0.28)
	var chrono_r: float = clampf(size.x * 0.26, 90.0, 200.0)
	var rot_speed: float = _anim_time * 0.35
	var c_col1 := Color(0.25, 0.78, 1.0, 0.18)
	var c_col2 := Color(0.85, 0.45, 1.0, 0.15)
	var c_gold := Color(1.0, 0.85, 0.35, 0.20)

	draw_arc(chrono_center, chrono_r, rot_speed, rot_speed + PI * 1.55, 42, c_col1, 1.6)
	draw_arc(chrono_center, chrono_r * 0.72, -rot_speed * 1.25, -rot_speed * 1.25 + PI * 1.45, 32, c_col2, 1.4)
	draw_arc(chrono_center, chrono_r * 0.44, rot_speed * 0.85, rot_speed * 0.85 + PI * 1.3, 24, c_gold, 1.2)
	draw_circle(chrono_center, chrono_r * 0.18, Color(0.15, 0.50, 0.95, 0.08))

	# Квантовые деления временного горизонта (12 измерений)
	for d_i in 12:
		var d_ang: float = rot_speed + float(d_i) * (TAU / 12.0)
		var p_in := chrono_center + Vector2(cos(d_ang), sin(d_ang)) * (chrono_r * 0.86)
		var p_out := chrono_center + Vector2(cos(d_ang), sin(d_ang)) * chrono_r
		draw_line(p_in, p_out, Color(0.35, 0.85, 1.0, 0.25), 1.2)

	# 4. Мерцающие разноцветные звёзды с крестообразными бликами
	for s in _stars:
		var sp := Vector2(s["pos"].x * size.x, s["pos"].y * size.y)
		var twinkle: float = sin(_anim_time * float(s["speed"]) + float(s["phase"])) * 0.35 + 0.65
		var base_col: Color = s["color"]
		var col := Color(base_col.r, base_col.g, base_col.b, float(s["alpha"]) * twinkle)
		var rad: float = float(s["size"])
		draw_circle(sp, rad, col)

		# 4-конечный световой блик на ярких звездах
		if bool(s.get("glint", false)) and twinkle > 0.8:
			var flare_len: float = rad * 3.2 * (twinkle - 0.75) * 4.0
			var flare_col := Color(base_col.r, base_col.g, base_col.b, col.a * 0.6)
			draw_line(sp - Vector2(flare_len, 0.0), sp + Vector2(flare_len, 0.0), flare_col, 1.0)
			draw_line(sp - Vector2(0.0, flare_len), sp + Vector2(0.0, flare_len), flare_col, 1.0)

	# 5. Падающие квантовые искры / метеоры
	for comet in _shooting_stars:
		if not bool(comet["active"]):
			continue
		var head_pos: Vector2 = comet["pos"]
		var d: Vector2 = comet["dir"]
		var prog: float = float(comet["prog"])
		var tail_len: float = float(comet["len"]) * 0.7
		var tail_pos: Vector2 = head_pos - d * tail_len
		var comet_alpha: float = sin(prog * PI) * 0.85
		var comet_col := Color(0.7, 0.92, 1.0, comet_alpha)
		draw_line(tail_pos, head_pos, comet_col, 1.5)
		draw_circle(head_pos, 2.0, Color(1.0, 1.0, 1.0, comet_alpha))


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
	root.add_theme_constant_override("separation", 18)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.add_child(root)
	_root_container = root

	# Эпический брендированный заголовок игры (Hero Banner)
	var hero_card := PanelContainer.new()
	hero_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero_card.add_theme_stylebox_override("panel", _hero_banner_style())
	root.add_child(hero_card)

	var hero_vb := VBoxContainer.new()
	hero_vb.alignment = BoxContainer.ALIGNMENT_CENTER
	hero_vb.add_theme_constant_override("separation", 6)
	hero_card.add_child(hero_vb)

	var hero_title := Label.new()
	hero_title.text = "✦ C H R O N O · C H E S S · 5 D ✦"
	hero_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_title.add_theme_font_size_override("font_size", 22)
	hero_title.add_theme_color_override("font_color", Color(0.96, 0.94, 0.84))
	hero_title.add_theme_color_override("font_shadow_color", Color(0.15, 0.60, 1.0, 0.85))
	hero_title.add_theme_constant_override("shadow_offset_y", 2)
	hero_title.add_theme_constant_override("shadow_outline_size", 4)
	hero_vb.add_child(hero_title)
	_hero_title_lbl = hero_title

	var hero_sub := Label.new()
	hero_sub.text = "МУЛЬТИВСЕЛЕННАЯ · ТАКТИЧЕСКИЙ ДВИЖОК · ПУТЕШЕСТВИЯ ВО ВРЕМЕНИ"
	hero_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_sub.add_theme_font_size_override("font_size", 11)
	hero_sub.add_theme_color_override("font_color", Color(0.65, 0.85, 1.0, 0.85))
	hero_vb.add_child(hero_sub)
	_hero_subtitle_lbl = hero_sub

	var badge_box := HBoxContainer.new()
	badge_box.alignment = BoxContainer.ALIGNMENT_CENTER
	hero_vb.add_child(badge_box)

	var hero_badge := Label.new()
	hero_badge.text = "⏳ 5D ХРОНО-ШАХМАТЫ"
	hero_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_badge.add_theme_font_size_override("font_size", 12)
	hero_badge.add_theme_color_override("font_color", Color(0.40, 0.95, 1.0))
	var badge_sb := StyleBoxFlat.new()
	badge_sb.bg_color = Color(0.10, 0.22, 0.46, 0.75)
	badge_sb.border_color = Color(0.35, 0.85, 1.0, 0.80)
	badge_sb.set_border_width_all(1)
	badge_sb.set_corner_radius_all(12)
	badge_sb.content_margin_left = 16
	badge_sb.content_margin_right = 16
	badge_sb.content_margin_top = 4
	badge_sb.content_margin_bottom = 4
	hero_badge.add_theme_stylebox_override("normal", badge_sb)
	badge_box.add_child(hero_badge)
	_hero_badge_lbl = hero_badge

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

	# 2. Верхняя фиксированная мобильная панель (Top App Bar)
	var top_bar := PanelContainer.new()
	top_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(top_bar)
	_top_bar = top_bar

	var top_hb := HBoxContainer.new()
	top_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	top_hb.add_theme_constant_override("separation", 8)
	top_bar.add_child(top_hb)

	# Логотип / Заголовок игры
	var title := Label.new()
	title.text = "✦ CHRONO CHESS 5D ✦"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.96, 0.93, 0.82))
	title.add_theme_color_override("font_shadow_color", Color(0.12, 0.45, 0.90, 0.65))
	title.add_theme_constant_override("shadow_offset_y", 2)
	top_hb.add_child(title)
	_title_label = title

	# Растягивающийся разделитель
	var top_spacer := Control.new()
	top_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hb.add_child(top_spacer)

	# Плашка профиля и рейтинга игрока
	var p_icon: String = "♚" if Profile.avatar_is_black else "♔"
	var profile_chip := _pill_action_btn("%s %d" % [p_icon, Profile.rating], func(): _switch_tab(4))
	_profile_chip_ref = profile_chip
	top_hb.add_child(profile_chip)

	# Кошелек кристаллов
	var crystal_btn := _pill_action_btn("💎 %d" % Profile.crystals, func(): _switch_tab(4))
	_crystal_badge_btn = crystal_btn
	top_hb.add_child(crystal_btn)

	# Быстрый переключатель звука
	var sfx_btn := _icon_action_btn("🔊" if (sfx == null or sfx.enabled) else "🔇", func():
		if sfx != null:
			var on: bool = sfx.toggle()
			_sfx_btn_ref.text = "🔊" if on else "🔇"
			if on:
				sfx.play("move"))
	_sfx_btn_ref = sfx_btn
	top_hb.add_child(sfx_btn)

	# Быстрый масштаб интерфейса
	var scale_btn := _icon_action_btn("⚙", func():
		Settings.cycle_ui_scale(get_window())
		if sfx != null:
			sfx.play("click"))
	_scale_btn_ref = scale_btn
	top_hb.add_child(scale_btn)

	# 3. Нижний навигационный док (Floating Bottom Navigation Dock)
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

	_tab_buttons.append(_create_tab_btn("⏳\n5D", 0, dock_hb))
	_tab_buttons.append(_create_tab_btn("⚔\nМульти", 1, dock_hb))
	_tab_buttons.append(_create_tab_btn("🎲\nМини", 2, dock_hb))
	_tab_buttons.append(_create_tab_btn("🌐\nСеть", 3, dock_hb))
	_tab_buttons.append(_create_tab_btn("👤\nПрофиль", 4, dock_hb))
	_tab_buttons.append(_create_tab_btn("📖\nИнфо", 5, dock_hb))

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
	var is_phone_portrait: bool = (w < 680.0 and h >= w) or (w < 540.0)

	var top_pad: float = maxf(6.0, insets.top)
	var bottom_pad: float = maxf(6.0, insets.bottom)
	var left_pad: float = maxf(8.0, insets.left + 4.0)
	var right_pad: float = maxf(8.0, insets.right + 4.0)

	# 1. Стилизация и отступы верхней фиксированной панели
	if _top_bar != null:
		var top_sb := _glass_panel_style(0, Color(0.04, 0.07, 0.14, 0.92), Color(0.25, 0.40, 0.70, 0.55), 1)
		top_sb.border_width_bottom = 2
		top_sb.content_margin_top = int(top_pad + 2.0)
		top_sb.content_margin_bottom = 6
		top_sb.content_margin_left = int(left_pad + 6.0)
		top_sb.content_margin_right = int(right_pad + 6.0)
		top_sb.shadow_color = Color(0.0, 0.0, 0.0, 0.50)
		top_sb.shadow_size = 10
		_top_bar.add_theme_stylebox_override("panel", top_sb)

	# 2. Стилизация и отступы нижнего плавающего дока
	if _bottom_dock != null:
		var dock_sb := _glass_panel_style(0, Color(0.04, 0.07, 0.14, 0.95), Color(0.30, 0.55, 0.95, 0.65), 1)
		dock_sb.border_width_top = 2
		dock_sb.content_margin_top = 6
		dock_sb.content_margin_bottom = int(bottom_pad + 4.0)
		dock_sb.content_margin_left = int(left_pad + 4.0)
		dock_sb.content_margin_right = int(right_pad + 4.0)
		dock_sb.shadow_color = Color(0.0, 0.0, 0.0, 0.60)
		dock_sb.shadow_size = 12
		_bottom_dock.add_theme_stylebox_override("panel", dock_sb)

	# 3. Отступы содержимого скролла (чтобы не перекрывалось шапкой и доком)
	var top_bar_h: float = 48.0 + top_pad
	var bottom_dock_h: float = 58.0 + bottom_pad

	# 4. Адаптивная ширина карточки (на широких экранах центрируем, на мобильных — 100% ширины)
	var avail_w: float = w - (left_pad + right_pad + 8.0)
	if avail_w > 780.0:
		var side_margin: int = int((w - 780.0) / 2.0)
		_margin_container.add_theme_constant_override("margin_left", side_margin)
		_margin_container.add_theme_constant_override("margin_right", side_margin)
	else:
		_margin_container.add_theme_constant_override("margin_left", int(left_pad + 4.0))
		_margin_container.add_theme_constant_override("margin_right", int(right_pad + 4.0))

	_margin_container.add_theme_constant_override("margin_top", int(top_bar_h + 10.0))
	_margin_container.add_theme_constant_override("margin_bottom", int(bottom_dock_h + 12.0))
	_root_container.custom_minimum_size.x = 0

	# 5. Адаптация логотипа / заголовка
	if _title_label != null:
		if is_phone_portrait:
			_title_label.text = "✦ 5D CHESS"
			_title_label.add_theme_font_size_override("font_size", 14)
		elif is_compact:
			_title_label.text = "✦ 5D CHRONO CHESS"
			_title_label.add_theme_font_size_override("font_size", 15)
		else:
			_title_label.text = "✦ CHRONO CHESS 5D ✦"
			_title_label.add_theme_font_size_override("font_size", 17)

	# Адаптация баннера Hero в теле страницы
	if _hero_title_lbl != null:
		if is_phone_portrait:
			_hero_title_lbl.text = "✦ CHRONO CHESS 5D ✦"
			_hero_title_lbl.add_theme_font_size_override("font_size", 18)
		elif is_compact:
			_hero_title_lbl.text = "✦ C H R O N O · C H E S S · 5 D ✦"
			_hero_title_lbl.add_theme_font_size_override("font_size", 20)
		else:
			_hero_title_lbl.text = "✦ C H R O N O · C H E S S · 5 D ✦"
			_hero_title_lbl.add_theme_font_size_override("font_size", 24)

	if _profile_chip_ref != null:
		_profile_chip_ref.visible = (w >= 360.0)
	if _scale_btn_ref != null:
		_scale_btn_ref.visible = (w >= 330.0)

	# 6. Адаптация кнопок навигационного дока
	if _tab_buttons.size() >= 6:
		if is_phone_portrait:
			_tab_buttons[0].text = "⏳\n5D"
			_tab_buttons[1].text = "⚔\nМульти"
			_tab_buttons[2].text = "🎲\nМини"
			_tab_buttons[3].text = "🌐\nСеть"
			_tab_buttons[4].text = "👤\nПрофиль"
			_tab_buttons[5].text = "📖\nИнфо"
			for b in _tab_buttons:
				b.add_theme_font_size_override("font_size", 10)
				b.custom_minimum_size.y = 48
		elif is_compact:
			_tab_buttons[0].text = "⏳ 5D"
			_tab_buttons[1].text = "⚔ Мульти"
			_tab_buttons[2].text = "🎲 Мини"
			_tab_buttons[3].text = "🌐 Сеть"
			_tab_buttons[4].text = "👤 Профиль"
			_tab_buttons[5].text = "📖 Инфо"
			for b in _tab_buttons:
				b.add_theme_font_size_override("font_size", 11)
				b.custom_minimum_size.y = 44
		else:
			_tab_buttons[0].text = "⏳ 5D Шахматы"
			_tab_buttons[1].text = "⚔ Мульти-шахматы"
			_tab_buttons[2].text = "🎲 Мини-геймс (D20 & Задачи)"
			_tab_buttons[3].text = "🌐 Сетевая игра"
			_tab_buttons[4].text = "👤 Профиль & Скины"
			_tab_buttons[5].text = "📖 Правила и фигуры"
			for b in _tab_buttons:
				b.add_theme_font_size_override("font_size", 13)
				b.custom_minimum_size.y = 46

	# 7. Адаптация кнопок в карточках
	if _profile_header_box != null:
		_profile_header_box.vertical = is_compact
	if _diff_row != null:
		_diff_row.vertical = is_phone_portrait
		_diff_lbl.custom_minimum_size.x = 0 if is_phone_portrait else 160
	if _col_row != null:
		_col_row.vertical = is_phone_portrait
		_col_lbl.custom_minimum_size.x = 0 if is_phone_portrait else 160
	if _var_header != null:
		_var_header.vertical = is_phone_portrait
		_var_title.custom_minimum_size.x = 0 if is_phone_portrait else 200
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
			_multi_col_lbl.custom_minimum_size.x = 0 if is_phone_portrait else 160
	if _d20_preset_box != null:
		_d20_preset_box.vertical = is_phone_portrait
	if _d20_mode_box != null:
		_d20_mode_box.vertical = is_phone_portrait
	if _d20_col_row != null:
		_d20_col_row.vertical = is_phone_portrait

	if _start_btn != null:
		_start_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL if is_compact else Control.SIZE_SHRINK_CENTER
		_start_btn.custom_minimum_size.x = 0 if is_compact else 320
	if _multi_launch_btn_ref != null:
		_multi_launch_btn_ref.size_flags_horizontal = Control.SIZE_EXPAND_FILL if is_compact else Control.SIZE_SHRINK_CENTER
		_multi_launch_btn_ref.custom_minimum_size.x = 0 if is_compact else 320
	if _d20_launch_btn_ref != null:
		_d20_launch_btn_ref.size_flags_horizontal = Control.SIZE_EXPAND_FILL if is_compact else Control.SIZE_SHRINK_CENTER
		_d20_launch_btn_ref.custom_minimum_size.x = 0 if is_compact else 320


func _create_tab_btn(label: String, tab_idx: int, parent: Control) -> Button:
	var b := Button.new()
	b.text = label
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 48)
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
	if _hero_badge_lbl != null:
		const TAB_NAMES := [
			"⏳ 5D ХРОНО-ШАХМАТЫ (МУЛЬТИВСЕЛЕННАЯ)",
			"⚔️ МУЛЬТИ-ШАХМАТЫ 14×14 (3 И 4 ИГРОКА)",
			"🎲 МИНИ-ГЕЙМС: D20 БИТВА & ЗАДАЧИ",
			"🌐 СЕТЕВАЯ КВАНТОВАЯ АРЕНА (ОНЛАЙН & LAN)",
			"👤 ЛИЧНЫЙ ПРОФИЛЬ, РЕЙТИНГ & КОЛЛЕКЦИЯ СКИНОВ",
			"📖 КОДЕКС ПРАВИЛ И МУЛЬТИВЕРС-ТАКТИКА"
		]
		if idx >= 0 and idx < TAB_NAMES.size():
			_hero_badge_lbl.text = TAB_NAMES[idx]
	for i in _tab_containers.size():
		var c: Control = _tab_containers[i]
		c.visible = (i == idx)
		if i < _tab_buttons.size():
			var b: Button = _tab_buttons[i]
			var is_active := (i == idx)

			var sb := StyleBoxFlat.new()
			if is_active:
				sb.bg_color = Color(0.18, 0.40, 0.82, 0.95)
				sb.border_color = Color(0.40, 0.95, 1.0, 0.95)
				sb.set_border_width_all(1)
				sb.border_width_top = 3
				sb.shadow_color = Color(0.15, 0.60, 1.0, 0.45)
				sb.shadow_size = 10
				b.add_theme_color_override("font_color", Color.WHITE)
			else:
				sb.bg_color = Color(0.06, 0.09, 0.16, 0.45)
				sb.border_color = Color(0.20, 0.30, 0.48, 0.30)
				sb.set_border_width_all(1)
				sb.shadow_size = 0
				b.add_theme_color_override("font_color", Color(0.75, 0.84, 0.96))
			sb.set_corner_radius_all(12)
			sb.content_margin_left = 6
			sb.content_margin_right = 6
			sb.content_margin_top = 6
			sb.content_margin_bottom = 6
			b.add_theme_stylebox_override("normal", sb)

			var hover := sb.duplicate()
			if not is_active:
				hover.bg_color = Color(0.12, 0.18, 0.32, 0.85)
				hover.border_color = Color(0.35, 0.62, 0.90, 0.65)
				hover.shadow_size = 4
			b.add_theme_stylebox_override("hover", hover)

			var pressed_sb := sb.duplicate()
			pressed_sb.bg_color = Color(0.24, 0.44, 0.80, 0.98)
			b.add_theme_stylebox_override("pressed", pressed_sb)

	if _scroll_container != null:
		_scroll_container.scroll_vertical = 0

	if sfx != null:
		sfx.play("move")

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


# ---------------------------------------------------------------- Вкладка 1: Одиночная игра

func _build_singleplayer_tab() -> Control:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)

	# 1. Карточка выбора формата битвы
	var format_card := PanelContainer.new()
	format_card.add_theme_stylebox_override("panel", _glass_panel_style(16))
	vb.add_child(format_card)

	var format_vb := VBoxContainer.new()
	format_vb.add_theme_constant_override("separation", 12)
	format_card.add_child(format_vb)

	format_vb.add_child(_section_header("ФОРМАТ СРАЖЕНИЯ", "⚡", Color(0.35, 0.85, 1.0)))

	_mode_box = BoxContainer.new()
	_mode_box.vertical = false
	_mode_box.add_theme_constant_override("separation", 12)
	format_vb.add_child(_mode_box)

	var btn_ai := _create_selectable_btn("🤖 Одиночная игра (Против ИИ)", true)
	var btn_local := _create_selectable_btn("👥 Pass & Play (Вдвоём на экране)", false)
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

	# 2. Карточка Хроно-параметров (ИИ и цвет)
	var params_card := PanelContainer.new()
	params_card.add_theme_stylebox_override("panel", _glass_panel_style(16))
	vb.add_child(params_card)

	_ai_settings_box = VBoxContainer.new()
	_ai_settings_box.add_theme_constant_override("separation", 14)
	params_card.add_child(_ai_settings_box)

	_ai_settings_box.add_child(_section_header("ХРОНО-ПАРАМЕТРЫ", "⚙", Color(1.0, 0.85, 0.35)))

	_diff_row = BoxContainer.new()
	_diff_row.vertical = false
	_diff_row.add_theme_constant_override("separation", 10)
	_ai_settings_box.add_child(_diff_row)

	_diff_lbl = Label.new()
	_diff_lbl.text = "Сложность ИИ:"
	_diff_lbl.custom_minimum_size.x = 160
	_diff_lbl.add_theme_color_override("font_color", Color(0.85, 0.90, 1.0))
	_diff_row.add_child(_diff_lbl)

	var diff_btns_box := HBoxContainer.new()
	diff_btns_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	diff_btns_box.add_theme_constant_override("separation", 8)
	_diff_row.add_child(diff_btns_box)

	var b_easy := _create_selectable_btn("🟢 Новичок", _ai_level == ChessAI.EASY)
	var b_norm := _create_selectable_btn("🟡 Мастер", _ai_level == ChessAI.NORMAL)
	var b_hard := _create_selectable_btn("🔴 Грандмастер", _ai_level == ChessAI.HARD)
	diff_btns_box.add_child(b_easy)
	diff_btns_box.add_child(b_norm)
	diff_btns_box.add_child(b_hard)
	_ai_buttons = [b_easy, b_norm, b_hard]

	b_easy.pressed.connect(func(): _set_ai_level(ChessAI.EASY))
	b_norm.pressed.connect(func(): _set_ai_level(ChessAI.NORMAL))
	b_hard.pressed.connect(func(): _set_ai_level(ChessAI.HARD))

	# Выбор цвета
	_col_row = BoxContainer.new()
	_col_row.vertical = false
	_col_row.add_theme_constant_override("separation", 10)
	_ai_settings_box.add_child(_col_row)

	_col_lbl = Label.new()
	_col_lbl.text = "Ваша сторона:"
	_col_lbl.custom_minimum_size.x = 160
	_col_lbl.add_theme_color_override("font_color", Color(0.85, 0.90, 1.0))
	_col_row.add_child(_col_lbl)

	var col_btns_box := HBoxContainer.new()
	col_btns_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_btns_box.add_theme_constant_override("separation", 8)
	_col_row.add_child(col_btns_box)

	var b_white := _create_selectable_btn("⚪ Белые", _color_choice == 0)
	var b_black := _create_selectable_btn("⚫ Чёрные", _color_choice == 1)
	var b_rnd := _create_selectable_btn("🎲 Суперпозиция", _color_choice == 2)
	col_btns_box.add_child(b_white)
	col_btns_box.add_child(b_black)
	col_btns_box.add_child(b_rnd)
	_color_buttons = [b_white, b_black, b_rnd]

	b_white.pressed.connect(func(): _set_color_choice(0))
	b_black.pressed.connect(func(): _set_color_choice(1))
	b_rnd.pressed.connect(func(): _set_color_choice(2))

	# 3. Карточка выбора временной расстановки
	var var_card := PanelContainer.new()
	var_card.add_theme_stylebox_override("panel", _glass_panel_style(16))
	vb.add_child(var_card)

	var var_vb := VBoxContainer.new()
	var_vb.add_theme_constant_override("separation", 10)
	var_card.add_child(var_vb)

	var_vb.add_child(_section_header("ПРОСТРАНСТВЕННО-ВРЕМЕННАЯ ДОСКА", "🌌", Color(0.85, 0.45, 1.0)))

	_var_header = BoxContainer.new()
	_var_header.vertical = false
	_var_header.add_theme_constant_override("separation", 10)
	var_vb.add_child(_var_header)

	_var_title = Label.new()
	_var_title.text = "Вариант расстановки:"
	_var_title.custom_minimum_size.x = 200
	_var_title.add_theme_color_override("font_color", Color(0.85, 0.90, 1.0))
	_var_header.add_child(_var_title)

	_variant_select_btn = OptionButton.new()
	_variant_select_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_variant_select_btn.custom_minimum_size.y = 48
	_variant_select_btn.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	_variant_select_btn.focus_mode = Control.FOCUS_NONE
	for v in Variants.LIST:
		_variant_select_btn.add_item("%s (%d×%d)" % [v["name"], v["w"], v["h"]])
	_variant_select_btn.item_selected.connect(func(i: int):
		_variant_idx = i
		_update_variant_desc())
	_var_header.add_child(_variant_select_btn)

	var desc_box := PanelContainer.new()
	var desc_sb := StyleBoxFlat.new()
	desc_sb.bg_color = Color(0.04, 0.07, 0.14, 0.65)
	desc_sb.border_color = Color(0.24, 0.45, 0.75, 0.45)
	desc_sb.set_border_width_all(1)
	desc_sb.set_corner_radius_all(10)
	desc_sb.content_margin_left = 14
	desc_sb.content_margin_right = 14
	desc_sb.content_margin_top = 10
	desc_sb.content_margin_bottom = 10
	desc_box.add_theme_stylebox_override("panel", desc_sb)
	var_vb.add_child(desc_box)

	_variant_desc_label = Label.new()
	_variant_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_variant_desc_label.add_theme_color_override("font_color", Color(0.80, 0.88, 1.0))
	_variant_desc_label.add_theme_font_size_override("font_size", 13)
	desc_box.add_child(_variant_desc_label)
	_update_variant_desc()

	# 4. Большая светящаяся кнопка старта
	var start_btn := _create_launch_btn("⚡ НАЧАТЬ ХРОНО-ПАРТИЮ", func():
		_launch(_selected_mode))
	vb.add_child(start_btn)
	_start_btn = start_btn

	return vb


var _ai_settings_box: VBoxContainer


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


# ---------------------------------------------------------------- Вкладка Мульти-шахматы (без времени)

func _build_multi_tab() -> Control:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)

	# 1. Шапка режима и описание
	var header_card := PanelContainer.new()
	header_card.add_theme_stylebox_override("panel", _glass_panel_style(16, Color(0.06, 0.10, 0.22, 0.88), Color(0.35, 0.65, 1.0, 0.70)))
	vb.add_child(header_card)

	var h_vb := VBoxContainer.new()
	h_vb.add_theme_constant_override("separation", 10)
	header_card.add_child(h_vb)

	h_vb.add_child(_section_header("МУЛЬТИ-ШАХМАТЫ 14×14", "⚔", Color(1.0, 0.85, 0.35)))

	var h_desc := Label.new()
	h_desc.text = "Эпическое сражение армий на крестообразном поле 14×14 БЕЗ путешествий во времени.\nКлассические правила взятий, тактическое позиционирование и бескомпромиссная борьба за центр."
	h_desc.add_theme_font_size_override("font_size", 13)
	h_desc.add_theme_color_override("font_color", Color(0.85, 0.90, 0.98))
	h_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	h_vb.add_child(h_desc)

	# 2. Выбор формата игры: 1х1х1, 2х2, 1х1х1х1
	var format_card := PanelContainer.new()
	format_card.add_theme_stylebox_override("panel", _glass_panel_style(16))
	vb.add_child(format_card)

	var f_vb := VBoxContainer.new()
	f_vb.add_theme_constant_override("separation", 12)
	format_card.add_child(f_vb)

	f_vb.add_child(_section_header("ФОРМАТ БИТВЫ", "👑", Color(0.40, 0.92, 1.0)))

	var sub_hb := BoxContainer.new()
	sub_hb.vertical = false
	sub_hb.add_theme_constant_override("separation", 10)
	f_vb.add_child(sub_hb)
	_multi_sub_mode_box = sub_hb

	var btn_3p := _create_selectable_btn("👑 1х1х1 (3 игрока)", _multi_chess_sub_mode == MultiChessState.MODE_1V1V1)
	var btn_2v2 := _create_selectable_btn("🛡 2х2 (Командный)", _multi_chess_sub_mode == MultiChessState.MODE_2V2)
	var btn_4ffa := _create_selectable_btn("⚔ 1х1х1х1 (4 игрока FFA)", _multi_chess_sub_mode == MultiChessState.MODE_1V1V1V1)

	for b in [btn_3p, btn_2v2, btn_4ffa]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 50)
		sub_hb.add_child(b)
	_multi_sub_mode_btns = [btn_3p, btn_2v2, btn_4ffa]

	var desc_box := PanelContainer.new()
	var desc_sb := StyleBoxFlat.new()
	desc_sb.bg_color = Color(0.04, 0.07, 0.14, 0.65)
	desc_sb.border_color = Color(0.24, 0.45, 0.75, 0.45)
	desc_sb.set_border_width_all(1)
	desc_sb.set_corner_radius_all(10)
	desc_sb.content_margin_left = 14
	desc_sb.content_margin_right = 14
	desc_sb.content_margin_top = 10
	desc_sb.content_margin_bottom = 10
	desc_box.add_theme_stylebox_override("panel", desc_sb)
	f_vb.add_child(desc_box)

	var sub_desc := Label.new()
	sub_desc.add_theme_font_size_override("font_size", 13)
	sub_desc.add_theme_color_override("font_color", Color(0.78, 0.88, 1.0))
	sub_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_box.add_child(sub_desc)

	var update_sub_desc := func():
		match _multi_chess_sub_mode:
			MultiChessState.MODE_1V1V1:
				sub_desc.text = "📌 1х1х1: 3 армии (Белые, Красные, Чёрные) на Юге, Западе и Севере. Каждый сам за себя!"
				if _multi_blue_btn_ref != null:
					_multi_blue_btn_ref.visible = false
					if _multi_chess_color == MultiChessState.BLUE:
						_multi_chess_color = MultiChessState.WHITE
						_update_multi_color_btns()
			MultiChessState.MODE_2V2:
				sub_desc.text = "📌 2х2: Команда Белые + Чёрные против команды Красные + Синие. Фигуры союзника рубить нельзя!"
				if _multi_blue_btn_ref != null:
					_multi_blue_btn_ref.visible = true
			MultiChessState.MODE_1V1V1V1:
				sub_desc.text = "📌 1х1х1х1: 4 армии, каждый сам за себя на полной доске 14×14. Побеждает последний оставшийся король!"
				if _multi_blue_btn_ref != null:
					_multi_blue_btn_ref.visible = true

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

	# 3. Карточка управления и ботов
	var ctrl_card := PanelContainer.new()
	ctrl_card.add_theme_stylebox_override("panel", _glass_panel_style(16))
	vb.add_child(ctrl_card)

	var c_vb := VBoxContainer.new()
	c_vb.add_theme_constant_override("separation", 12)
	ctrl_card.add_child(c_vb)

	c_vb.add_child(_section_header("УПРАВЛЕНИЕ АРМИЯМИ", "🛡", Color(0.35, 0.85, 1.0)))

	var ctrl_hb := BoxContainer.new()
	ctrl_hb.vertical = false
	ctrl_hb.add_theme_constant_override("separation", 10)
	c_vb.add_child(ctrl_hb)
	_multi_ctrl_box = ctrl_hb

	var btn_bots := _create_selectable_btn("🤖 Против ботов (ИИ)", not _multi_chess_pass_and_play)
	var btn_pass := _create_selectable_btn("👥 На одном экране (Pass & Play)", _multi_chess_pass_and_play)
	for b in [btn_bots, btn_pass]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ctrl_hb.add_child(b)

	# Секция настроек ботов
	var bot_options_box := VBoxContainer.new()
	bot_options_box.add_theme_constant_override("separation", 12)
	c_vb.add_child(bot_options_box)

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

	# Выбор своего цвета
	var col_row := BoxContainer.new()
	col_row.vertical = false
	col_row.add_theme_constant_override("separation", 10)
	bot_options_box.add_child(col_row)
	_multi_col_row = col_row

	var col_lbl := Label.new()
	col_lbl.text = "Ваш цвет:"
	col_lbl.custom_minimum_size.x = 160
	col_lbl.add_theme_color_override("font_color", Color(0.85, 0.90, 1.0))
	col_row.add_child(col_lbl)
	_multi_col_lbl = col_lbl

	var col_btns_box := HBoxContainer.new()
	col_btns_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_btns_box.add_theme_constant_override("separation", 8)
	col_row.add_child(col_btns_box)

	var b_w := _create_selectable_btn("⚪ Белые", _multi_chess_color == MultiChessState.WHITE)
	var b_r := _create_selectable_btn("🔴 Красные", _multi_chess_color == MultiChessState.RED)
	var b_b := _create_selectable_btn("⚫ Чёрные", _multi_chess_color == MultiChessState.BLACK)
	var b_u := _create_selectable_btn("🔵 Синие", _multi_chess_color == MultiChessState.BLUE)
	_multi_blue_btn_ref = b_u
	for b in [b_w, b_r, b_b, b_u]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col_btns_box.add_child(b)
	_multi_color_btns = [b_w, b_r, b_b, b_u]

	b_w.pressed.connect(func(): _multi_chess_color = MultiChessState.WHITE; _update_multi_color_btns())
	b_r.pressed.connect(func(): _multi_chess_color = MultiChessState.RED; _update_multi_color_btns())
	b_b.pressed.connect(func(): _multi_chess_color = MultiChessState.BLACK; _update_multi_color_btns())
	b_u.pressed.connect(func(): _multi_chess_color = MultiChessState.BLUE; _update_multi_color_btns())

	# Выбор сложности ботов
	var diff_row := HBoxContainer.new()
	diff_row.add_theme_constant_override("separation", 10)
	bot_options_box.add_child(diff_row)

	var diff_lbl := Label.new()
	diff_lbl.text = "Сложность ботов:"
	diff_lbl.custom_minimum_size.x = 160
	diff_lbl.add_theme_color_override("font_color", Color(0.85, 0.90, 1.0))
	diff_row.add_child(diff_lbl)

	var diff_box := HBoxContainer.new()
	diff_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	diff_box.add_theme_constant_override("separation", 8)
	diff_row.add_child(diff_box)

	var bd_easy := _create_selectable_btn("🌱 Лёгкий", _multi_chess_ai_level == MultiChessAI.LEVEL_EASY)
	var bd_norm := _create_selectable_btn("⚖ Средний", _multi_chess_ai_level == MultiChessAI.LEVEL_NORMAL)
	var bd_hard := _create_selectable_btn("⚡ Сложный", _multi_chess_ai_level == MultiChessAI.LEVEL_HARD)
	for b in [bd_easy, bd_norm, bd_hard]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		diff_box.add_child(b)
	_multi_diff_btns = [bd_easy, bd_norm, bd_hard]

	bd_easy.pressed.connect(func(): _multi_chess_ai_level = MultiChessAI.LEVEL_EASY; _update_multi_diff_btns())
	bd_norm.pressed.connect(func(): _multi_chess_ai_level = MultiChessAI.LEVEL_NORMAL; _update_multi_diff_btns())
	bd_hard.pressed.connect(func(): _multi_chess_ai_level = MultiChessAI.LEVEL_HARD; _update_multi_diff_btns())

	# Кнопка старта
	var launch_btn := _create_launch_btn("⚔ НАЧАТЬ МУЛЬТИ-ШАХМАТЫ", func():
		if sfx != null:
			sfx.play("submit")
		start_multi_game.emit(_multi_chess_sub_mode, _multi_chess_pass_and_play, _multi_chess_color, _multi_chess_ai_level, null, [], false))
	_multi_launch_btn_ref = launch_btn
	vb.add_child(launch_btn)

	return vb


func _create_launch_btn(text: String, cb: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(340, 58)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", 18)
	btn.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_filter = Control.MOUSE_FILTER_STOP

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.45, 0.88, 0.96)
	sb.border_color = Color(0.45, 0.92, 1.0, 0.95)
	sb.set_border_width_all(2)
	sb.border_width_top = 3
	sb.set_corner_radius_all(16)
	sb.shadow_color = Color(0.18, 0.60, 1.0, 0.50)
	sb.shadow_size = 18
	sb.shadow_offset = Vector2(0, 4)
	btn.add_theme_stylebox_override("normal", sb)

	var sb_hover: StyleBoxFlat = sb.duplicate()
	sb_hover.bg_color = Color(0.18, 0.56, 1.0, 1.0)
	sb_hover.border_color = Color(0.75, 1.0, 1.0)
	sb_hover.shadow_size = 24
	btn.add_theme_stylebox_override("hover", sb_hover)

	var sb_pressed: StyleBoxFlat = sb.duplicate()
	sb_pressed.bg_color = Color(0.08, 0.35, 0.72)
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
		_set_army_btn_style(btns[0], selected_col == MultiChessState.WHITE, Color(0.95, 0.95, 1.0), Color(0.20, 0.25, 0.36, 0.95))
		_set_army_btn_style(btns[1], selected_col == MultiChessState.RED, Color(1.0, 0.35, 0.38), Color(0.45, 0.12, 0.16, 0.95))
		_set_army_btn_style(btns[2], selected_col == MultiChessState.BLACK, Color(0.75, 0.65, 0.95), Color(0.26, 0.18, 0.38, 0.95))
		_set_army_btn_style(btns[3], selected_col == MultiChessState.BLUE, Color(0.35, 0.75, 1.0), Color(0.12, 0.28, 0.55, 0.95))


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
		net.online_create_multi_room(_d20_sub_mode, _d20_color, "🎲 D20 Битва " + _d20_sub_mode, true)
		_switch_tab(3)


# ---------------------------------------------------------------- Вкладка 2: Мини-игры, D20 Битва и Задачи

func _build_puzzles_tab() -> Control:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 18)

	# 0. Флагманский режим: D20 БИТВА ШАХМАТ (Кубик Судьбы)
	var d20_card := PanelContainer.new()
	d20_card.add_theme_stylebox_override("panel", _glass_panel_style(16, Color(0.10, 0.14, 0.28, 0.96), Color(0.95, 0.75, 0.25, 0.85), 2))
	vb.add_child(d20_card)

	var d20_vb := VBoxContainer.new()
	d20_vb.add_theme_constant_override("separation", 14)
	d20_card.add_child(d20_vb)

	# Заголовок
	var d20_head := HBoxContainer.new()
	d20_vb.add_child(d20_head)

	var d20_title := Label.new()
	d20_title.text = "🎲 D20 БИТВА: КУБИК СУДЬБЫ"
	d20_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	d20_title.add_theme_font_size_override("font_size", 20)
	d20_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	d20_head.add_child(d20_title)

	var d20_badge := Label.new()
	d20_badge.text = "RPG РЕЖИМ"
	d20_badge.add_theme_font_size_override("font_size", 11)
	d20_badge.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
	d20_head.add_child(d20_badge)

	var d20_desc := Label.new()
	d20_desc.text = "Шахматы с боевой механикой D20! Каждое взятие — это дуэль на 20-гранном кубике. Порог успеха (DC) зависит от ценности фигур. При успехе фигура повержена, при неудаче защитник отбивает атаку, а нападающий отскакивает назад!"
	d20_desc.add_theme_font_size_override("font_size", 13)
	d20_desc.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0, 0.9))
	d20_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d20_vb.add_child(d20_desc)

	# Выбор пресета карты (все карты из мультишахмат: 1v1v1, 2v2, 1v1v1v1)
	var p_lbl := Label.new()
	p_lbl.text = "Пресет карты (мультишахматы):"
	p_lbl.add_theme_font_size_override("font_size", 14)
	p_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0))
	d20_vb.add_child(p_lbl)

	var preset_row := BoxContainer.new()
	preset_row.vertical = false
	preset_row.add_theme_constant_override("separation", 8)
	d20_vb.add_child(preset_row)
	_d20_preset_box = preset_row

	var btn_p1 := _create_selectable_btn("⚔ 1х1х1 (3 игр.)", _d20_sub_mode == MultiChessState.MODE_1V1V1)
	var btn_p2 := _create_selectable_btn("🛡 2х2 (4 игр.)", _d20_sub_mode == MultiChessState.MODE_2V2)
	var btn_p3 := _create_selectable_btn("⚔ 1х1х1х1 (4 игр.)", _d20_sub_mode == MultiChessState.MODE_1V1V1V1)
	for b in [btn_p1, btn_p2, btn_p3]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		preset_row.add_child(b)
	_d20_sub_mode_btns = [btn_p1, btn_p2, btn_p3]

	btn_p1.pressed.connect(func(): _d20_sub_mode = MultiChessState.MODE_1V1V1; _update_d20_sub_mode_btns())
	btn_p2.pressed.connect(func(): _d20_sub_mode = MultiChessState.MODE_2V2; _update_d20_sub_mode_btns())
	btn_p3.pressed.connect(func(): _d20_sub_mode = MultiChessState.MODE_1V1V1V1; _update_d20_sub_mode_btns())

	# Выбор формата игры (Боты, Pass & Play, Онлайн)
	var mode_lbl := Label.new()
	mode_lbl.text = "Формат битвы:"
	mode_lbl.add_theme_font_size_override("font_size", 14)
	mode_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0))
	d20_vb.add_child(mode_lbl)

	var mode_row := BoxContainer.new()
	mode_row.vertical = false
	mode_row.add_theme_constant_override("separation", 8)
	d20_vb.add_child(mode_row)
	_d20_mode_box = mode_row

	var btn_m_bots := _create_selectable_btn("🤖 Против Ботов", _d20_play_mode == 0)
	var btn_m_pass := _create_selectable_btn("🤝 Pass & Play", _d20_play_mode == 1)
	var btn_m_net := _create_selectable_btn("🌐 Онлайн комната", _d20_play_mode == 2)
	for b in [btn_m_bots, btn_m_pass, btn_m_net]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mode_row.add_child(b)

	# Секция настроек ботов и цвета
	_d20_bot_options_box = VBoxContainer.new()
	_d20_bot_options_box.add_theme_constant_override("separation", 10)
	d20_vb.add_child(_d20_bot_options_box)

	# Цвет игрока
	var col_row := BoxContainer.new()
	col_row.vertical = false
	col_row.add_theme_constant_override("separation", 10)
	_d20_bot_options_box.add_child(col_row)
	_d20_col_row = col_row

	var c_lbl := Label.new()
	c_lbl.text = "Ваш цвет:"
	c_lbl.custom_minimum_size.x = 140
	c_lbl.add_theme_color_override("font_color", Color(0.85, 0.90, 1.0))
	col_row.add_child(c_lbl)

	var c_btns_box := HBoxContainer.new()
	c_btns_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c_btns_box.add_theme_constant_override("separation", 8)
	col_row.add_child(c_btns_box)

	var db_w := _create_selectable_btn("⚪ Белые", _d20_color == MultiChessState.WHITE)
	var db_r := _create_selectable_btn("🔴 Красные", _d20_color == MultiChessState.RED)
	var db_b := _create_selectable_btn("⚫ Чёрные", _d20_color == MultiChessState.BLACK)
	var db_u := _create_selectable_btn("🔵 Синие", _d20_color == MultiChessState.BLUE)
	_d20_blue_btn_ref = db_u
	for b in [db_w, db_r, db_b, db_u]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		c_btns_box.add_child(b)
	_d20_color_btns = [db_w, db_r, db_b, db_u]

	db_w.pressed.connect(func(): _d20_color = MultiChessState.WHITE; _update_d20_color_btns())
	db_r.pressed.connect(func(): _d20_color = MultiChessState.RED; _update_d20_color_btns())
	db_b.pressed.connect(func(): _d20_color = MultiChessState.BLACK; _update_d20_color_btns())
	db_u.pressed.connect(func(): _d20_color = MultiChessState.BLUE; _update_d20_color_btns())

	# Сложность ботов
	var d20_diff_row := HBoxContainer.new()
	d20_diff_row.add_theme_constant_override("separation", 10)
	_d20_bot_options_box.add_child(d20_diff_row)

	var df_lbl := Label.new()
	df_lbl.text = "Сложность ботов:"
	df_lbl.custom_minimum_size.x = 140
	df_lbl.add_theme_color_override("font_color", Color(0.85, 0.90, 1.0))
	d20_diff_row.add_child(df_lbl)

	var df_box := HBoxContainer.new()
	df_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	df_box.add_theme_constant_override("separation", 8)
	d20_diff_row.add_child(df_box)

	var bdf_easy := _create_selectable_btn("🌱 Лёгкий", _d20_ai_level == MultiChessAI.LEVEL_EASY)
	var bdf_norm := _create_selectable_btn("⚖ Средний", _d20_ai_level == MultiChessAI.LEVEL_NORMAL)
	var bdf_hard := _create_selectable_btn("⚡ Сложный", _d20_ai_level == MultiChessAI.LEVEL_HARD)
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
		_d20_launch_btn_ref.text = "🎲 НАЧАТЬ D20 БИТВУ"
	)
	btn_m_pass.pressed.connect(func():
		_d20_play_mode = 1
		_set_btn_active(btn_m_bots, false)
		_set_btn_active(btn_m_pass, true)
		_set_btn_active(btn_m_net, false)
		_d20_bot_options_box.visible = false
		_d20_launch_btn_ref.text = "🎲 НАЧАТЬ PASS & PLAY"
	)
	btn_m_net.pressed.connect(func():
		_d20_play_mode = 2
		_set_btn_active(btn_m_bots, false)
		_set_btn_active(btn_m_pass, false)
		_set_btn_active(btn_m_net, true)
		_d20_bot_options_box.visible = true
		d20_diff_row.visible = false
		_d20_launch_btn_ref.text = "🌐 СОЗДАТЬ D20 КОМНАТУ ОНЛАЙН"
	)

	# Памятка по боевым порогам (DC)
	var cheat_panel := PanelContainer.new()
	var ch_sb := StyleBoxFlat.new()
	ch_sb.bg_color = Color(0.06, 0.08, 0.16, 0.8)
	ch_sb.border_color = Color(0.25, 0.45, 0.75, 0.5)
	ch_sb.set_border_width_all(1)
	ch_sb.set_corner_radius_all(10)
	ch_sb.content_margin_left = 12
	ch_sb.content_margin_right = 12
	ch_sb.content_margin_top = 10
	ch_sb.content_margin_bottom = 10
	cheat_panel.add_theme_stylebox_override("panel", ch_sb)
	d20_vb.add_child(cheat_panel)

	var ch_vb := VBoxContainer.new()
	ch_vb.add_theme_constant_override("separation", 4)
	cheat_panel.add_child(ch_vb)

	var ch_title := Label.new()
	ch_title.text = "📜 Таблица боевых порогов d20:"
	ch_title.add_theme_font_size_override("font_size", 12)
	ch_title.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
	ch_vb.add_child(ch_title)

	var ch_text := Label.new()
	ch_text.text = "• Порог успеха = 10 + (Сила цели - Сила атаки) × 2 (от 3+ до 18+)\n• Пешка(1) vs Ферзь(9): порог 18+ | Ферзь vs Пешка: порог 3+\n• Равные фигуры (Конь vs Слон): порог 10+ (55% шанс успеха)\n• 🎲 Нат 20: Критический триумф (100% взятие) | 💥 Нат 1: Провал"
	ch_text.add_theme_font_size_override("font_size", 12)
	ch_text.add_theme_color_override("font_color", Color(0.75, 0.82, 0.95))
	ch_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ch_vb.add_child(ch_text)

	# Кнопка запуска D20
	var d20_launch_btn := Button.new()
	d20_launch_btn.text = "🎲 НАЧАТЬ D20 БИТВУ"
	d20_launch_btn.custom_minimum_size = Vector2(340, 56)
	d20_launch_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	d20_launch_btn.add_theme_font_size_override("font_size", 17)
	d20_launch_btn.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	d20_launch_btn.focus_mode = Control.FOCUS_NONE

	var d_sb := StyleBoxFlat.new()
	d_sb.bg_color = Color(0.85, 0.45, 0.12, 0.96)
	d_sb.border_color = Color(1.0, 0.85, 0.35, 0.95)
	d_sb.set_border_width_all(2)
	d_sb.set_corner_radius_all(16)
	d_sb.shadow_color = Color(0.9, 0.45, 0.1, 0.45)
	d_sb.shadow_size = 16
	d20_launch_btn.add_theme_stylebox_override("normal", d_sb)

	var d_hover: StyleBoxFlat = d_sb.duplicate()
	d_hover.bg_color = Color(0.95, 0.55, 0.18, 1.0)
	d_hover.shadow_size = 22
	d20_launch_btn.add_theme_stylebox_override("hover", d_hover)

	var d_pressed: StyleBoxFlat = d_sb.duplicate()
	d_pressed.bg_color = Color(0.7, 0.35, 0.08)
	d20_launch_btn.add_theme_stylebox_override("pressed", d_pressed)

	d20_launch_btn.pressed.connect(_on_d20_launch_pressed)
	_d20_launch_btn_ref = d20_launch_btn
	d20_vb.add_child(d20_launch_btn)

	_update_d20_sub_mode_btns()

	# 1. Ежедневные задания
	var quests_card := PanelContainer.new()
	quests_card.add_theme_stylebox_override("panel", _glass_panel_style(14, Color(0.10, 0.15, 0.28, 0.92)))
	vb.add_child(quests_card)

	var q_main_vb := VBoxContainer.new()
	q_main_vb.add_theme_constant_override("separation", 12)
	quests_card.add_child(q_main_vb)

	var q_head := HBoxContainer.new()
	q_main_vb.add_child(q_head)

	var q_title := Label.new()
	q_title.text = "📅 ЕЖЕДНЕВНЫЕ ЗАДАНИЯ"
	q_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	q_title.add_theme_font_size_override("font_size", 19)
	q_title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.4))
	q_head.add_child(q_title)

	var q_sub := Label.new()
	q_sub.text = "Обновляются каждый день. Выполняйте задачи в игре и получайте 💎 кристаллы для покупки скинов!"
	q_sub.add_theme_font_size_override("font_size", 13)
	q_sub.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0, 0.85))
	q_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	q_main_vb.add_child(q_sub)

	_quests_container = VBoxContainer.new()
	_quests_container.add_theme_constant_override("separation", 8)
	q_main_vb.add_child(_quests_container)

	# 2. Бесконечный процедурный генератор задач
	var proc_card := PanelContainer.new()
	proc_card.add_theme_stylebox_override("panel", _glass_panel_style(14, Color(0.10, 0.16, 0.32, 0.95), Color(0.3, 0.8, 1.0, 0.6), 2))
	vb.add_child(proc_card)

	var proc_vb := VBoxContainer.new()
	proc_vb.add_theme_constant_override("separation", 12)
	proc_card.add_child(proc_vb)

	var proc_head := HBoxContainer.new()
	proc_vb.add_child(proc_head)

	var proc_title := Label.new()
	proc_title.text = "🎲 БЕСКОНЕЧНЫЙ ГЕНЕРАТОР ЗАДАЧ"
	proc_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	proc_title.add_theme_font_size_override("font_size", 19)
	proc_title.add_theme_color_override("font_color", Color(0.35, 0.9, 1.0))
	proc_head.add_child(proc_title)

	var proc_sub := Label.new()
	proc_sub.text = "Генерируйте уникальные тактические головоломки на мат в 1 ход на лету! Каждая решённая процедурная задача приносит 💎 Хроно-кристаллы и засчитывается в ежедневные квесты."
	proc_sub.add_theme_font_size_override("font_size", 13)
	proc_sub.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0, 0.9))
	proc_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	proc_vb.add_child(proc_sub)

	# Выбор сложности
	var diff_box := VBoxContainer.new()
	diff_box.add_theme_constant_override("separation", 6)
	proc_vb.add_child(diff_box)

	var diff_lbl := Label.new()
	diff_lbl.text = "Сложность задачи:"
	diff_lbl.add_theme_font_size_override("font_size", 14)
	diff_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0))
	diff_box.add_child(diff_lbl)

	var diff_row := HBoxContainer.new()
	diff_row.add_theme_constant_override("separation", 8)
	diff_box.add_child(diff_row)

	_proc_diff_btns.clear()
	var diff_defs: Array = [
		{"d": 1, "text": "🟢 Лёгкий\n★☆☆ · 💎 50"},
		{"d": 2, "text": "🟡 Средний\n★★☆ · 💎 80"},
		{"d": 3, "text": "🔴 Сложный\n★★★ · 💎 120"}
	]
	for df in diff_defs:
		var d_val: int = int(df["d"])
		var btn := _create_selectable_btn(str(df["text"]), _proc_diff == d_val)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 11)
		btn.custom_minimum_size = Vector2(0, 44)
		btn.pressed.connect(func():
			_proc_diff = d_val
			_update_proc_diff_ui()
			if sfx != null:
				sfx.play("click"))
		diff_row.add_child(btn)
		_proc_diff_btns.append(btn)

	# Кнопка генерации
	var start_proc_btn := _action_btn("🎲 Сгенерировать задачу и начать", func():
		if sfx != null:
			sfx.play("click")
		var new_puz: Dictionary = Puzzles.generate_procedural_puzzle(_proc_diff)
		start_puzzle_game.emit(new_puz))
	start_proc_btn.custom_minimum_size = Vector2(0, 46)
	proc_vb.add_child(start_proc_btn)

	# 3. Сюжетные тактические головоломки
	var puz_card := PanelContainer.new()
	puz_card.add_theme_stylebox_override("panel", _glass_panel_style(14, Color(0.08, 0.12, 0.24, 0.90)))
	vb.add_child(puz_card)

	var p_main_vb := VBoxContainer.new()
	p_main_vb.add_theme_constant_override("separation", 12)
	puz_card.add_child(p_main_vb)

	var p_title := Label.new()
	p_title.text = "📚 СЮЖЕТНЫЕ И 5D ГОЛОВОЛОМКИ"
	p_title.add_theme_font_size_override("font_size", 19)
	p_title.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
	p_main_vb.add_child(p_title)

	var p_sub := Label.new()
	p_sub.text = "Решайте сюжетные шахматные задачи на мат в 1 ход и временные парадоксы. За первое прохождение начисляются кристаллы!"
	p_sub.add_theme_font_size_override("font_size", 13)
	p_sub.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0, 0.85))
	p_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p_main_vb.add_child(p_sub)

	_puzzles_container = VBoxContainer.new()
	_puzzles_container.add_theme_constant_override("separation", 10)
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
		card_sb.bg_color = Color(0.06, 0.09, 0.18, 0.85)
		card_sb.border_color = Color(1.0, 0.84, 0.3, 0.7) if is_completed and not is_claimed else Color(0.2, 0.3, 0.5, 0.4)
		card_sb.set_border_width_all(1)
		card_sb.set_corner_radius_all(10)
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
		info.add_theme_constant_override("separation", 3)
		row.add_child(info)

		var t_lbl := Label.new()
		t_lbl.text = "%s  (+%d 💎)" % [q_title, rew]
		t_lbl.add_theme_font_size_override("font_size", 14 if is_phone else 15)
		t_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.75))
		t_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(t_lbl)

		var d_lbl := Label.new()
		d_lbl.text = "%s  •  Прогресс: %d / %d" % [q_desc, cur, tgt]
		d_lbl.add_theme_font_size_override("font_size", 12 if is_phone else 13)
		d_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95))
		d_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(d_lbl)

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 38) if is_phone else Vector2(140, 38)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL if is_phone else Control.SIZE_SHRINK_END
		btn.focus_mode = Control.FOCUS_NONE

		if is_claimed:
			btn.text = "✅ Получено"
			btn.disabled = true
			var dis_sb := StyleBoxFlat.new()
			dis_sb.bg_color = Color(0.12, 0.16, 0.22, 0.5)
			dis_sb.set_corner_radius_all(8)
			btn.add_theme_stylebox_override("disabled", dis_sb)
		elif is_completed:
			btn.text = "💎 Забрать (+%d)" % rew
			var act_sb := StyleBoxFlat.new()
			act_sb.bg_color = Color(0.2, 0.5, 0.3, 0.95)
			act_sb.border_color = Color(0.4, 1.0, 0.6)
			act_sb.set_border_width_all(2)
			act_sb.set_corner_radius_all(8)
			btn.add_theme_stylebox_override("normal", act_sb)
			btn.pressed.connect(func():
				var got := Profile.claim_quest_reward(q_id)
				if got > 0 and sfx != null:
					sfx.play("win")
				_refresh_puzzles_and_quests_ui())
		else:
			btn.text = "В процессе (%d/%d)" % [cur, tgt]
			btn.disabled = true
			var dis_sb := StyleBoxFlat.new()
			dis_sb.bg_color = Color(0.10, 0.13, 0.22, 0.6)
			dis_sb.set_corner_radius_all(8)
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
		var diff: int = int(p.get("difficulty", 1))
		var rew: int = int(p.get("reward", 50))
		var desc: String = str(p.get("desc", ""))
		var is_solved: bool = Profile.is_puzzle_solved(p_id)

		var card := PanelContainer.new()
		var card_sb := StyleBoxFlat.new()
		card_sb.bg_color = Color(0.06, 0.08, 0.18, 0.85)
		card_sb.border_color = Color(0.3, 0.85, 0.6, 0.8) if is_solved else Color(0.25, 0.35, 0.55, 0.5)
		card_sb.set_border_width_all(1)
		card_sb.set_corner_radius_all(10)
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
		info.add_theme_constant_override("separation", 3)
		row.add_child(info)

		var stars_str := ""
		for s in diff:
			stars_str += "★"

		var t_lbl := Label.new()
		var status_str := "  •  ✅ Решено" if is_solved else ("  •  💎 +%d" % rew)
		t_lbl.text = "%s (%s) %s%s" % [title, cat, stars_str, status_str]
		t_lbl.add_theme_font_size_override("font_size", 14 if is_phone else 15)
		t_lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0) if not is_solved else Color(0.5, 0.95, 0.7))
		t_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(t_lbl)

		var d_lbl := Label.new()
		d_lbl.text = desc
		d_lbl.add_theme_font_size_override("font_size", 12 if is_phone else 13)
		d_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95))
		d_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(d_lbl)

		var play_btn := Button.new()
		play_btn.text = "Повторить задачу" if is_solved else "▶ Начать решение"
		play_btn.custom_minimum_size = Vector2(0, 38) if is_phone else Vector2(130, 40)
		play_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL if is_phone else Control.SIZE_SHRINK_END
		play_btn.focus_mode = Control.FOCUS_NONE

		var p_sb := StyleBoxFlat.new()
		p_sb.bg_color = Color(0.18, 0.28, 0.52, 0.95) if not is_solved else Color(0.12, 0.20, 0.35, 0.8)
		p_sb.border_color = Color(0.4, 0.75, 1.0)
		p_sb.set_border_width_all(1)
		p_sb.set_corner_radius_all(8)
		play_btn.add_theme_stylebox_override("normal", p_sb)

		var puzzle_copy := p.duplicate(true)
		play_btn.pressed.connect(func():
			if sfx != null:
				sfx.play("click")
			start_puzzle_game.emit(puzzle_copy))
		row.add_child(play_btn)


# ---------------------------------------------------------------- Вкладка 3: Сетевая игра и Браузер серверов

func _build_multiplayer_tab() -> Control:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)

	# Переключатель: Онлайн через сервер vs Локальная сеть (LAN)
	var mode_toggle_hb := HBoxContainer.new()
	mode_toggle_hb.add_theme_constant_override("separation", 12)
	vb.add_child(mode_toggle_hb)

	var btn_online := _create_selectable_btn("🌐 Онлайн-игра (Мастер-сервер)", _multi_online_mode)
	var btn_lan := _create_selectable_btn("📶 Локальная сеть (Wi-Fi)", not _multi_online_mode)
	btn_online.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_lan.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mode_toggle_hb.add_child(btn_online)
	mode_toggle_hb.add_child(btn_lan)
	_multi_mode_btns = [btn_online, btn_lan]

	var server_cfg_btn := _action_btn("⚙ Сервер", _show_server_settings_dialog)
	server_cfg_btn.custom_minimum_size = Vector2(120, 42)
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

	# Блок обнаружения активного матча для быстрого переподключения
	if Profile.has_active_match():
		var recon_card := PanelContainer.new()
		recon_card.add_theme_stylebox_override("panel", _glass_panel_style(12, Color(0.24, 0.14, 0.04, 0.95), Color(1.0, 0.75, 0.2, 0.95), 2))
		vb.add_child(recon_card)

		var r_vb := VBoxContainer.new()
		r_vb.add_theme_constant_override("separation", 8)
		recon_card.add_child(r_vb)

		var r_title := Label.new()
		r_title.text = "⚡ ОБНАРУЖЕН НЕЗАВЕРШЕННЫЙ МАТЧ [КОД: %s]" % Profile.active_match_code
		r_title.add_theme_font_size_override("font_size", 16)
		r_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		r_vb.add_child(r_title)

		var r_sub := Label.new()
		var opp_name: String = Profile.active_match_opponent if Profile.active_match_opponent != "" else "Соперник"
		r_sub.text = "Соперник: %s · Вариант: %s (Ожидание возвращения)" % [opp_name, Profile.active_match_variant]
		r_sub.add_theme_font_size_override("font_size", 13)
		r_sub.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
		r_vb.add_child(r_sub)

		var r_btn_row := HBoxContainer.new()
		r_btn_row.add_theme_constant_override("separation", 10)
		r_vb.add_child(r_btn_row)

		var recon_btn := _action_btn("🔄 Вернуться в матч", func():
			if net != null:
				_net_status_label.text = "Восстановление подключения к матчу %s..." % Profile.active_match_code
				net.reconnect_to_match(Profile.active_match_code, Profile.active_match_token))
		recon_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r_btn_row.add_child(recon_btn)

		var dismiss_btn := _action_btn("✖ Завершить", func():
			Profile.clear_active_match()
			recon_card.queue_free())
		dismiss_btn.custom_minimum_size = Vector2(130, 42)
		r_btn_row.add_child(dismiss_btn)

	# Секция 1: Подключение по коду комнаты или прямому IP
	var code_card := PanelContainer.new()
	code_card.add_theme_stylebox_override("panel", _glass_panel_style(12, Color(0.09, 0.12, 0.22, 0.85)))
	vb.add_child(code_card)

	var code_vb := VBoxContainer.new()
	code_vb.add_theme_constant_override("separation", 10)
	code_card.add_child(code_vb)

	var code_title := Label.new()
	code_title.text = "🔑 Подключение по коду комнаты:"
	code_title.add_theme_font_size_override("font_size", 18)
	code_vb.add_child(code_title)

	_code_row = BoxContainer.new()
	_code_row.vertical = false
	_code_row.add_theme_constant_override("separation", 10)
	code_vb.add_child(_code_row)

	_room_code_input = LineEdit.new()
	_room_code_input.placeholder_text = "Введите код комнаты (например 7K9F)"
	_room_code_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_room_code_input.custom_minimum_size.y = 48
	_code_row.add_child(_room_code_input)

	var join_code_btn := _action_btn("⚡ Подключиться", _on_join_code_pressed)
	join_code_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	join_code_btn.custom_minimum_size = Vector2(160, 48)
	_code_row.add_child(join_code_btn)

	# Секция 2: Создать сервер (Хост)
	var host_card := PanelContainer.new()
	host_card.add_theme_stylebox_override("panel", _glass_panel_style(12, Color(0.09, 0.12, 0.22, 0.85)))
	vb.add_child(host_card)

	var host_vb := VBoxContainer.new()
	host_vb.add_theme_constant_override("separation", 12)
	host_card.add_child(host_vb)

	var host_title := Label.new()
	host_title.text = "📡 Создать комнату:"
	host_title.add_theme_font_size_override("font_size", 18)
	host_vb.add_child(host_title)

	# Выбор типа игры: 5D vs Мульти vs D20 Битва
	var type_row := HBoxContainer.new()
	type_row.add_theme_constant_override("separation", 8)
	host_vb.add_child(type_row)

	var btn_type_5d := _create_selectable_btn("⏳ 5D Хроно", _net_game_type == "5d")
	var btn_type_multi := _create_selectable_btn("⚔ Мульти", _net_game_type == "multi")
	var btn_type_d20 := _create_selectable_btn("🎲 D20 Битва", _net_game_type == "d20_multi")
	btn_type_5d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_type_multi.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_type_d20.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	type_row.add_child(btn_type_5d)
	type_row.add_child(btn_type_multi)
	type_row.add_child(btn_type_d20)
	_net_type_btns = [btn_type_5d, btn_type_multi, btn_type_d20]

	# Блок настроек Мульти-шахмат / D20 при создании комнаты
	_net_multi_options_box = VBoxContainer.new()
	_net_multi_options_box.add_theme_constant_override("separation", 10)
	_net_multi_options_box.visible = (_net_game_type in ["multi", "d20_multi"])
	host_vb.add_child(_net_multi_options_box)

	var m_fmt_lbl := Label.new()
	m_fmt_lbl.text = "Формат сражения:"
	_net_multi_options_box.add_child(m_fmt_lbl)

	var m_fmt_row := HBoxContainer.new()
	m_fmt_row.add_theme_constant_override("separation", 8)
	_net_multi_options_box.add_child(m_fmt_row)

	var m_btn_3p := _create_selectable_btn("👑 1х1х1 (3 игр.)", _net_multi_sub_mode == MultiChessState.MODE_1V1V1)
	var m_btn_2v2 := _create_selectable_btn("🛡 2х2 (4 игр.)", _net_multi_sub_mode == MultiChessState.MODE_2V2)
	var m_btn_4ffa := _create_selectable_btn("⚔ 1х1х1х1 (4 игр.)", _net_multi_sub_mode == MultiChessState.MODE_1V1V1V1)
	for b in [m_btn_3p, m_btn_2v2, m_btn_4ffa]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		m_fmt_row.add_child(b)
	_net_multi_sub_btns = [m_btn_3p, m_btn_2v2, m_btn_4ffa]

	var m_col_lbl := Label.new()
	m_col_lbl.text = "Ваш стартовый цвет:"
	_net_multi_options_box.add_child(m_col_lbl)

	var m_col_row := HBoxContainer.new()
	m_col_row.add_theme_constant_override("separation", 8)
	_net_multi_options_box.add_child(m_col_row)

	var m_col_w := _create_selectable_btn("⚪ Белые", _net_multi_color == MultiChessState.WHITE)
	var m_col_r := _create_selectable_btn("🔴 Красные", _net_multi_color == MultiChessState.RED)
	var m_col_b := _create_selectable_btn("⚫ Чёрные", _net_multi_color == MultiChessState.BLACK)
	var m_col_u := _create_selectable_btn("🔵 Синие", _net_multi_color == MultiChessState.BLUE)
	_net_multi_blue_btn = m_col_u
	for b in [m_col_w, m_col_r, m_col_b, m_col_u]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		m_col_row.add_child(b)
	_net_multi_color_btns = [m_col_w, m_col_r, m_col_b, m_col_u]

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
	_name_row.add_theme_constant_override("separation", 10)
	host_vb.add_child(_name_row)

	var name_lbl := Label.new()
	name_lbl.text = "Имя комнаты:"
	_name_row.add_child(name_lbl)

	_room_name_input = LineEdit.new()
	_room_name_input.text = "Комната " + Profile.player_name
	_room_name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_room_name_input.custom_minimum_size.y = 44
	_name_row.add_child(_room_name_input)

	var create_btn := _action_btn("Создать игру", _on_create_host_pressed)
	create_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	create_btn.custom_minimum_size = Vector2(140, 44)
	_name_row.add_child(create_btn)

	# Информационная панель лобби (активна, когда сервер запущен или клиент вошел)
	_host_panel = PanelContainer.new()
	_host_panel.add_theme_stylebox_override("panel", _glass_panel_style(12, Color(0.12, 0.18, 0.32, 0.95), Color(0.35, 0.65, 1.0, 0.8), 2))
	_host_panel.visible = false
	host_vb.add_child(_host_panel)

	var hp_vb := VBoxContainer.new()
	hp_vb.add_theme_constant_override("separation", 10)
	_host_panel.add_child(hp_vb)

	_host_code_label = Label.new()
	_host_code_label.add_theme_font_size_override("font_size", 24)
	_host_code_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	hp_vb.add_child(_host_code_label)

	_lobby_info_label = Label.new()
	_lobby_info_label.add_theme_font_size_override("font_size", 14)
	_lobby_info_label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	hp_vb.add_child(_lobby_info_label)

	_lobby_players_box = VBoxContainer.new()
	_lobby_players_box.add_theme_constant_override("separation", 6)
	hp_vb.add_child(_lobby_players_box)

	var hp_btn_row := HBoxContainer.new()
	hp_btn_row.add_theme_constant_override("separation", 12)
	hp_vb.add_child(hp_btn_row)

	var copy_code_btn := _action_btn("📋 Скопировать код", func():
		if net != null and net.room_code != "":
			DisplayServer.clipboard_set(net.room_code)
			_net_status_label.text = "Код %s скопирован в буфер обмена!" % net.room_code)
	hp_btn_row.add_child(copy_code_btn)

	_lobby_start_btn = _action_btn("⚔ Начать игру (с ботами)", func():
		if net != null:
			net.online_start_room_game())
	_lobby_start_btn.visible = false
	var st_sb := StyleBoxFlat.new()
	st_sb.bg_color = Color(0.18, 0.55, 0.28)
	st_sb.border_color = Color(0.4, 0.9, 0.5)
	st_sb.set_border_width_all(2)
	st_sb.set_corner_radius_all(10)
	_lobby_start_btn.add_theme_stylebox_override("normal", st_sb)
	hp_btn_row.add_child(_lobby_start_btn)

	var cancel_host_btn := _action_btn("Покинуть комнату", func():
		if net != null:
			if _multi_online_mode:
				net.online_leave_room()
			else:
				net.close()
		_host_panel.visible = false
		_net_status_label.text = "Вы вышли из комнаты")
	hp_btn_row.add_child(cancel_host_btn)

	_net_status_label = Label.new()
	_net_status_label.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
	vb.add_child(_net_status_label)

	# Секция 3: Браузер серверов
	var browser_card := PanelContainer.new()
	browser_card.add_theme_stylebox_override("panel", _glass_panel_style(12, Color(0.07, 0.09, 0.18, 0.9)))
	vb.add_child(browser_card)

	var browser_vb := VBoxContainer.new()
	browser_vb.add_theme_constant_override("separation", 10)
	browser_card.add_child(browser_vb)

	var br_header := HBoxContainer.new()
	browser_vb.add_child(br_header)

	var br_title := Label.new()
	br_title.text = "🌍 Открытые онлайн-игры на сервере:"
	br_title.add_theme_font_size_override("font_size", 18)
	br_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	br_header.add_child(br_title)

	var refresh_btn := _action_btn("🔄 Обновить", func():
		if net != null:
			if _multi_online_mode:
				net.online_request_rooms()
			else:
				net.start_lan_discovery()
			_net_status_label.text = "Обновление списка комнат...")
	br_header.add_child(refresh_btn)

	_server_list_container = VBoxContainer.new()
	_server_list_container.add_theme_constant_override("separation", 8)
	browser_vb.add_child(_server_list_container)

	_no_servers_label = Label.new()
	_no_servers_label.text = "🔍 Нет открытых комнат. Создайте игру или введите код для подключения!"
	_no_servers_label.modulate = Color(0.7, 0.78, 0.95, 0.7)
	browser_vb.add_child(_no_servers_label)

	return vb


func _update_multi_mode_ui() -> void:
	if _multi_mode_btns.size() >= 2:
		_set_btn_active(_multi_mode_btns[0], _multi_online_mode)
		_set_btn_active(_multi_mode_btns[1], not _multi_online_mode)
	if _room_code_input != null:
		_room_code_input.placeholder_text = "Введите 4-значный код комнаты (например 7K9F)" if _multi_online_mode else "Введите код комнаты (например 7K9-F2M)"
	_host_panel.visible = false


func _show_server_settings_dialog() -> void:
	var dlg := ConfirmationDialog.new()
	dlg.title = "Настройка сервера ChronoChess"
	dlg.ok_button_text = "Сохранить"
	dlg.cancel_button_text = "Отмена"

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	dlg.add_child(vb)

	var lbl := Label.new()
	lbl.text = "Адрес мастер-сервера (WebSocket URL):"
	vb.add_child(lbl)

	var input := LineEdit.new()
	input.text = net.server_url if net != null else Net.DEFAULT_SERVER_URL
	input.custom_minimum_size = Vector2(360, 42)
	vb.add_child(input)

	dlg.confirmed.connect(func():
		var u: String = input.text.strip_edges()
		if u != "" and net != null:
			net.connect_online(u)
			_net_status_label.text = "Настройки сервера сохранены")
	add_child(dlg)
	dlg.popup_centered()


func _on_create_host_pressed() -> void:
	if net == null:
		return
	var r_name: String = _room_name_input.text.strip_edges()
	if _net_game_type in ["multi", "d20_multi"]:
		var is_d20: bool = (_net_game_type == "d20_multi")
		if _multi_online_mode:
			_net_status_label.text = "Создание комнаты D20 на сервере..." if is_d20 else "Создание мульти-шахматной комнаты на сервере..."
			net.online_create_multi_room(_net_multi_sub_mode, _net_multi_color, r_name, is_d20)
		else:
			net.game_type = _net_game_type
			var err: String = net.host(_net_multi_sub_mode, _net_multi_color, r_name)
			if err != "":
				_net_status_label.text = err
				return
			_host_panel.visible = true
			_host_code_label.text = "КОД КОМНАТЫ: %s" % net.room_code
			_net_status_label.text = ("LAN D20 комната создана!" if is_d20 else "LAN-комната мульти-шахмат создана!")
	else:
		if _multi_online_mode:
			_net_status_label.text = "Создание комнаты 5D на сервере..."
			net.online_create_room(_selected_variant_id(), _picked_color(), r_name)
		else:
			net.game_type = "5d"
			var err: String = net.host(_selected_variant_id(), _picked_color(), r_name)
			if err != "":
				_net_status_label.text = err
				return
			_host_panel.visible = true
			_host_code_label.text = "КОД КОМНАТЫ: %s" % net.room_code
			_net_status_label.text = "LAN-сервер запущен. Ожидание соперника..."


func _on_join_code_pressed() -> void:
	if net == null:
		return
	var input: String = _room_code_input.text.strip_edges()
	if input == "":
		_net_status_label.text = "Введите код комнаты"
		return

	if _multi_online_mode:
		_net_status_label.text = "Подключение к комнате %s..." % input
		net.online_join_room(input)
	else:
		var err: String = net.join_by_code(input)
		if err != "":
			_net_status_label.text = err
			return
		_net_status_label.text = "Подключение к %s..." % input


func _on_net_room_created(code: String) -> void:
	_host_panel.visible = true
	_host_code_label.text = "КОД ВАШЕЙ КОМНАТЫ: %s" % code
	_net_status_label.text = "Комната открыта на сервере! Назовите код сопернику: %s" % code
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
		card.add_theme_stylebox_override("panel", _glass_panel_style(8, Color(0.12, 0.16, 0.3, 0.9)))
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
		s_name.add_theme_font_size_override("font_size", 17)
		info.add_child(s_name)

		var s_sub := Label.new()
		var code: String = str(s.get("code", ""))
		var g_type: String = str(s.get("game_type", "5d"))
		var variant: String = str(s.get("variant", "standard"))
		var cur_p: int = int(s.get("current_players", 1))
		var max_p: int = int(s.get("max_players", 2))

		var mode_badge := ""
		if g_type == "d20_multi":
			match variant:
				"1v1v1": mode_badge = "🎲 D20 1х1х1"
				"2v2": mode_badge = "🎲 D20 2х2"
				"1v1v1v1": mode_badge = "🎲 D20 1х1х1х1"
				_: mode_badge = "🎲 D20 " + variant
		elif g_type == "multi":
			match variant:
				"1v1v1": mode_badge = "👑 Мульти 1х1х1"
				"2v2": mode_badge = "🛡 Мульти 2х2"
				"1v1v1v1": mode_badge = "⚔ Мульти 1х1х1х1"
				_: mode_badge = "⚔ Мульти " + variant
		else:
			mode_badge = "⏳ 5D (%s)" % variant

		s_sub.text = "%s · 👥 %d/%d · Код: %s" % [mode_badge, cur_p, max_p, code]
		s_sub.add_theme_font_size_override("font_size", 13)
		s_sub.modulate = Color(0.7, 0.85, 1.0)
		info.add_child(s_sub)

		var join_btn := _action_btn("Присоединиться", func():
			if _multi_online_mode:
				_net_status_label.text = "Подключение к комнате %s..." % code
				net.online_join_room(code)
			else:
				var err: String = net.join(str(s.get("ip", "")))
				if err != "":
					_net_status_label.text = err
				else:
					_net_status_label.text = "Подключение...")
		join_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if not is_compact:
			join_btn.custom_minimum_size = Vector2(170, 42)
		row.add_child(join_btn)


# ---------------------------------------------------------------- Вкладка 3: Профиль игрока

func _build_profile_tab() -> Control:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)

	# 1. Главная карточка игрока (Аватар + Имя + Титул + Рейтинг)
	var id_card := PanelContainer.new()
	id_card.add_theme_stylebox_override("panel", _glass_panel_style(14, Color(0.10, 0.14, 0.26, 0.92)))
	vb.add_child(id_card)

	_profile_header_box = BoxContainer.new()
	_profile_header_box.vertical = false
	_profile_header_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_profile_header_box.add_theme_constant_override("separation", 16)
	id_card.add_child(_profile_header_box)

	# Большой аватар
	var avatar_wrapper := PanelContainer.new()
	var av_sb := StyleBoxFlat.new()
	av_sb.bg_color = Color(0.06, 0.08, 0.16, 0.95)
	av_sb.border_color = Color(0.4, 0.85, 1.0, 0.9)
	av_sb.set_border_width_all(2)
	av_sb.set_corner_radius_all(14)
	av_sb.content_margin_left = 8
	av_sb.content_margin_right = 8
	av_sb.content_margin_top = 8
	av_sb.content_margin_bottom = 8
	avatar_wrapper.add_theme_stylebox_override("panel", av_sb)
	_profile_header_box.add_child(avatar_wrapper)

	_profile_avatar_preview = PieceButton.new()
	_profile_avatar_preview.custom_minimum_size = Vector2(80, 80)
	_profile_avatar_preview.piece = Profile.get_avatar_code()
	avatar_wrapper.add_child(_profile_avatar_preview)

	# Данные игрока
	var info_vb := VBoxContainer.new()
	info_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vb.add_theme_constant_override("separation", 6)
	_profile_header_box.add_child(info_vb)

	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	info_vb.add_child(name_row)

	var name_tag := Label.new()
	name_tag.text = "👤 Позывной:"
	name_tag.add_theme_font_size_override("font_size", 15)
	name_tag.add_theme_color_override("font_color", Color(0.7, 0.82, 1.0))
	name_row.add_child(name_tag)

	_profile_name_edit = LineEdit.new()
	_profile_name_edit.text = Profile.player_name
	_profile_name_edit.placeholder_text = "Введите ваш никнейм"
	_profile_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_profile_name_edit.custom_minimum_size.y = 42
	_profile_name_edit.add_theme_font_size_override("font_size", 17)
	_profile_name_edit.text_changed.connect(func(new_text: String):
		Profile.set_nickname(new_text)
		if _room_name_input != null:
			_room_name_input.text = "Комната " + Profile.player_name)
	name_row.add_child(_profile_name_edit)

	_profile_title_lbl = Label.new()
	_profile_title_lbl.text = Profile.get_title()
	_profile_title_lbl.add_theme_font_size_override("font_size", 15)
	_profile_title_lbl.add_theme_color_override("font_color", Color(1.0, 0.82, 0.35))
	info_vb.add_child(_profile_title_lbl)

	_profile_rating_lbl = Label.new()
	_profile_rating_lbl.text = "⚡ Рейтинг: %d ELO" % Profile.rating
	_profile_rating_lbl.add_theme_font_size_override("font_size", 18)
	_profile_rating_lbl.add_theme_color_override("font_color", Color(0.4, 0.95, 1.0))
	info_vb.add_child(_profile_rating_lbl)

	# 2. Выбор аватара (Фигура и цвет)
	var avatar_card := PanelContainer.new()
	avatar_card.add_theme_stylebox_override("panel", _glass_panel_style(12, Color(0.08, 0.11, 0.22, 0.85)))
	vb.add_child(avatar_card)

	var av_vb := VBoxContainer.new()
	av_vb.add_theme_constant_override("separation", 10)
	avatar_card.add_child(av_vb)

	var av_header := HBoxContainer.new()
	av_vb.add_child(av_header)

	var av_title := Label.new()
	av_title.text = "🎨 Выбор аватара:"
	av_title.add_theme_font_size_override("font_size", 17)
	av_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	av_header.add_child(av_title)

	# Переключатель цвета аватара
	var col_btn_w := _create_selectable_btn("⚪ Светлая", not Profile.avatar_is_black)
	var col_btn_b := _create_selectable_btn("⚫ Тёмная", Profile.avatar_is_black)
	col_btn_w.custom_minimum_size = Vector2(100, 38)
	col_btn_b.custom_minimum_size = Vector2(100, 38)
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

	# Сетка фигур для аватара
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
		pb.custom_minimum_size = Vector2(52, 52)
		pb.piece = pt | (GameState.BLACK_BIT if Profile.avatar_is_black else 0)
		pb.pressed.connect(func():
			Profile.set_avatar(pt, Profile.avatar_is_black)
			_refresh_avatar_selection()
			if sfx != null:
				sfx.play("click"))
		pieces_box.add_child(pb)
		_avatar_piece_btns.append({"btn": pb, "type": pt})

	# 3. Магазин скинов для фигур
	var shop_card := PanelContainer.new()
	shop_card.add_theme_stylebox_override("panel", _glass_panel_style(12, Color(0.08, 0.11, 0.22, 0.85)))
	vb.add_child(shop_card)

	var sh_vb := VBoxContainer.new()
	sh_vb.add_theme_constant_override("separation", 10)
	shop_card.add_child(sh_vb)

	var sh_title := Label.new()
	sh_title.text = "🛍 Магазин скинов для фигур (Кастомизация):"
	sh_title.add_theme_font_size_override("font_size", 17)
	sh_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	sh_vb.add_child(sh_title)

	var sh_sub := Label.new()
	sh_sub.text = "Скины изменяют цвет и свечение всех ваших фигур на доске во всех игровых режимах!"
	sh_sub.add_theme_font_size_override("font_size", 13)
	sh_sub.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95))
	sh_vb.add_child(sh_sub)

	_skins_container = VBoxContainer.new()
	_skins_container.add_theme_constant_override("separation", 8)
	sh_vb.add_child(_skins_container)

	# 4. Карточка боевой статистики
	var stats_card := PanelContainer.new()
	stats_card.add_theme_stylebox_override("panel", _glass_panel_style(12, Color(0.08, 0.11, 0.22, 0.85)))
	vb.add_child(stats_card)

	var st_vb := VBoxContainer.new()
	st_vb.add_theme_constant_override("separation", 10)
	stats_card.add_child(st_vb)

	var st_title := Label.new()
	st_title.text = "📊 Боевая статистика партий:"
	st_title.add_theme_font_size_override("font_size", 17)
	st_vb.add_child(st_title)

	_profile_stats_lbl = Label.new()
	_profile_stats_lbl.add_theme_font_size_override("font_size", 15)
	_profile_stats_lbl.add_theme_color_override("font_color", Color(0.9, 0.94, 1.0))
	st_vb.add_child(_profile_stats_lbl)

	_profile_winrate_lbl = Label.new()
	_profile_winrate_lbl.add_theme_font_size_override("font_size", 15)
	_profile_winrate_lbl.add_theme_color_override("font_color", Color(0.4, 0.95, 0.7))
	st_vb.add_child(_profile_winrate_lbl)

	_profile_streaks_lbl = Label.new()
	_profile_streaks_lbl.add_theme_font_size_override("font_size", 14)
	_profile_streaks_lbl.add_theme_color_override("font_color", Color(0.85, 0.88, 1.0, 0.8))
	st_vb.add_child(_profile_streaks_lbl)

	# 5. Карточка 5D-квантовых достижений
	var q_card := PanelContainer.new()
	q_card.add_theme_stylebox_override("panel", _glass_panel_style(12, Color(0.08, 0.11, 0.22, 0.85)))
	vb.add_child(q_card)

	var q_vb := VBoxContainer.new()
	q_vb.add_theme_constant_override("separation", 8)
	q_card.add_child(q_vb)

	var q_title := Label.new()
	q_title.text = "⏳ Пространственно-временные показатели (5D):"
	q_title.add_theme_font_size_override("font_size", 17)
	q_vb.add_child(q_title)

	_profile_5d_lbl = Label.new()
	_profile_5d_lbl.add_theme_font_size_override("font_size", 14)
	_profile_5d_lbl.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	_profile_5d_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	q_vb.add_child(_profile_5d_lbl)

	# 6. Кнопка сброса статистики
	var reset_btn := _action_btn("🗑 Сбросить статистику", _on_reset_stats_pressed)
	reset_btn.custom_minimum_size = Vector2(220, 44)
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
		pb.queue_redraw()


func _refresh_profile_ui() -> void:
	if _profile_name_edit != null and not _profile_name_edit.has_focus():
		_profile_name_edit.text = Profile.player_name
	if _profile_title_lbl != null:
		_profile_title_lbl.text = Profile.get_title()
	if _profile_rating_lbl != null:
		_profile_rating_lbl.text = "⚡ Рейтинг: %d ELO" % Profile.rating
	if _profile_avatar_preview != null:
		_profile_avatar_preview.piece = Profile.get_avatar_code()
		_profile_avatar_preview.queue_redraw()
	if _profile_stats_lbl != null:
		_profile_stats_lbl.text = "Всего сыграно: %d   ·   Побед: %d   ·   Поражений: %d   ·   Ничьих: %d" % [
			Profile.games_played, Profile.wins, Profile.losses, Profile.draws
		]
	if _profile_winrate_lbl != null:
		_profile_winrate_lbl.text = "Винрейт: %.1f%%   ·   Побед в онлайне: %d   ·   Побед над ИИ: %d" % [
			Profile.get_winrate(), Profile.online_wins, Profile.ai_wins
		]
	if _profile_streaks_lbl != null:
		_profile_streaks_lbl.text = "Текущая серия побед: %d   ·   Лучшая серия: %d" % [
			Profile.win_streak, Profile.best_streak
		]
	if _profile_5d_lbl != null:
		_profile_5d_lbl.text = (
			"• Создано альтернативных временных линий: %d\n" % Profile.timelines_created
			+ "• Совершено прыжков сквозь время и миры: %d\n" % Profile.temporal_jumps
			+ "• Квантовый статус: %s" % Profile.get_title()
		)
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
		card_sb.bg_color = Color(0.07, 0.10, 0.20, 0.88)
		if is_active:
			card_sb.border_color = Color(1.0, 0.85, 0.3, 0.9)
			card_sb.set_border_width_all(2)
		else:
			card_sb.border_color = Color(0.25, 0.35, 0.55, 0.5)
			card_sb.set_border_width_all(1)
		card_sb.set_corner_radius_all(10)
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

		# Превью фигур со скином (Белая и тёмная фигура)
		var prev_box := HBoxContainer.new()
		prev_box.add_theme_constant_override("separation", 6)
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

		# Описание
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_constant_override("separation", 3)
		top_part.add_child(info)

		var t_lbl := Label.new()
		var price_str := " (Бесплатно)" if price == 0 else (" (💎 %d)" % price)
		t_lbl.text = s_name + price_str
		t_lbl.add_theme_font_size_override("font_size", 14 if is_phone else 15)
		t_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.4) if is_active else Color(0.85, 0.92, 1.0))
		t_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(t_lbl)

		var d_lbl := Label.new()
		d_lbl.text = s_desc
		d_lbl.add_theme_font_size_override("font_size", 12 if is_phone else 13)
		d_lbl.add_theme_color_override("font_color", Color(0.7, 0.8, 0.92))
		d_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(d_lbl)

		# Кнопка действия
		var act_btn := Button.new()
		act_btn.custom_minimum_size = Vector2(0, 38) if is_phone else Vector2(140, 40)
		act_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL if is_phone else Control.SIZE_SHRINK_END
		act_btn.focus_mode = Control.FOCUS_NONE

		if is_active:
			act_btn.text = "⭐ Надето"
			act_btn.disabled = true
			var st := StyleBoxFlat.new()
			st.bg_color = Color(0.18, 0.22, 0.32, 0.7)
			st.border_color = Color(1.0, 0.84, 0.3)
			st.set_border_width_all(1)
			st.set_corner_radius_all(8)
			act_btn.add_theme_stylebox_override("disabled", st)
		elif is_owned:
			act_btn.text = "Выбрать"
			var st := StyleBoxFlat.new()
			st.bg_color = Color(0.16, 0.26, 0.48, 0.9)
			st.border_color = Color(0.4, 0.75, 1.0)
			st.set_border_width_all(1)
			st.set_corner_radius_all(8)
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
			act_btn.text = "Купить 💎 %d" % price
			if can_afford:
				var st := StyleBoxFlat.new()
				st.bg_color = Color(0.18, 0.42, 0.28, 0.95)
				st.border_color = Color(0.4, 0.9, 0.5)
				st.set_border_width_all(1)
				st.set_corner_radius_all(8)
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
				st.bg_color = Color(0.12, 0.14, 0.20, 0.6)
				st.set_corner_radius_all(8)
				act_btn.add_theme_stylebox_override("disabled", st)

		row.add_child(act_btn)


func _update_crystals_display() -> void:
	if _crystal_badge_btn != null:
		_crystal_badge_btn.text = "💎 %d" % Profile.crystals
	if _profile_chip_ref != null:
		var p_icon: String = "♚" if Profile.avatar_is_black else "♔"
		_profile_chip_ref.text = "%s %d" % [p_icon, Profile.rating]


func _on_reset_stats_pressed() -> void:
	var dlg := ConfirmationDialog.new()
	dlg.title = "Сброс статистики"
	dlg.dialog_text = "Вы уверены, что хотите обнулить всю боевую статистику и рейтинг?"
	dlg.ok_button_text = "Да, сбросить"
	dlg.cancel_button_text = "Отмена"
	dlg.confirmed.connect(func():
		Profile.reset_stats()
		_refresh_profile_ui()
		if sfx != null:
			sfx.play("click"))
	add_child(dlg)
	dlg.popup_centered()


# ---------------------------------------------------------------- Вкладка 5: Правила и фигуры

func _build_rules_tab() -> Control:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)

	var title := Label.new()
	title.text = "📖 Руководство по 5D-шахматам:"
	title.add_theme_font_size_override("font_size", 20)
	vb.add_child(title)

	var text_block := Label.new()
	text_block.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_block.text = (
		"• Четыре оси координат (X, Y, T, L):\n"
		+ "  Горизонтально во времени (T) идут ходы партии. По вертикали (L) разветвляются параллельные временные линии.\n\n"
		+ "• Барьер «Настоящего» (Present Beam):\n"
		+ "  Светящаяся вертикальная линия обозначает самую раннюю активную доску. Вы ОБЯЗАНЫ сходить на всех досках с золотой рамкой, чтобы закончить ход (доски с зелёной рамкой опциональны).\n\n"
		+ "• Прыжки сквозь время и новые линии:\n"
		+ "  Фигуры могут прыгать назад во времени (T) или между линиями (L). Если фигура совершает ход на доску в прошлом, создаётся НОВАЯ ветка реальности!\n\n"
		+ "• Уникальные фигуры:\n"
		+ "  – Единорог (U): триагональ — перемещается сразу по 3 осям.\n"
		+ "  – Дракон (D): квадриагональ — перемещается сразу по всем 4 осям.\n"
		+ "  – Принцесса (S): сочетает в себе ходы ладьи и слона (1 или 2 оси).\n\n"
		+ "• Шах и мат сквозь время:\n"
		+ "  Вы не можете сделать ход, если хотя бы один ваш король на любой доске (даже в прошлом) окажется под атакой врага. Красные лазерные стрелки предупредят об угрозах!"
	)
	text_block.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
	vb.add_child(text_block)

	# Раздел правил Мульти-шахмат
	var multi_title := Label.new()
	multi_title.text = "⚔ Правила мульти-шахмат (без времени):"
	multi_title.add_theme_font_size_override("font_size", 20)
	multi_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	vb.add_child(multi_title)

	var multi_block := Label.new()
	multi_block.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	multi_block.text = (
		"• Поле 14×14 в форме креста:\n"
		+ "  Центр 8×8 и четыре крыла 3×8 (Юг, Запад, Север, Восток). Угловые зоны 3×3 вырезаны.\n\n"
		+ "• Форматы сражения:\n"
		+ "  – 1х1х1 (3 игрока): Белые, Красные и Чёрные. Каждый сам за себя.\n"
		+ "  – 2х2 (Командный бой): Белые + Чёрные против Красных + Синих. Нельзя атаковать фигуры союзника.\n"
		+ "  – 1х1х1х1 (4 игрока FFA): Все против всех. Побеждает последний выживший король.\n\n"
		+ "• Движение пешек и превращение:\n"
		+ "  Каждая пешка шагает строго вперёд от своей базы (Белые вверх, Красные вправо, Чёрные вниз, Синие влево).\n"
		+ "  При достижении 8-й линии продвижения пешка превращается в Ферзя.\n\n"
		+ "• Устранение игроков:\n"
		+ "  При взятии короля игрок выбывает, а оставшиеся его фигуры снимаются с доски."
	)
	multi_block.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
	vb.add_child(multi_block)

	return vb


# ---------------------------------------------------------------- Вспомогательные стили и кнопки

func _hero_banner_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.08, 0.18, 0.88)
	sb.border_color = Color(0.35, 0.70, 1.0, 0.75)
	sb.set_border_width_all(1)
	sb.border_width_top = 3
	sb.border_width_bottom = 2
	sb.set_corner_radius_all(18)
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 18
	sb.content_margin_bottom = 18
	sb.shadow_color = Color(0.08, 0.35, 0.75, 0.35)
	sb.shadow_size = 20
	sb.shadow_offset = Vector2(0, 6)
	return sb


func _section_header(title: String, icon: String = "✦", color: Color = Color(0.40, 0.92, 1.0)) -> Control:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	var sym := Label.new()
	sym.text = icon
	sym.add_theme_font_size_override("font_size", 16)
	sym.add_theme_color_override("font_color", color)
	hb.add_child(sym)

	var lbl := Label.new()
	lbl.text = title
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(0.94, 0.96, 1.0))
	hb.add_child(lbl)
	return hb


func _glass_panel_style(radius: int, bg: Color = Color(0.06, 0.09, 0.18, 0.88), border: Color = Color(0.28, 0.45, 0.75, 0.55), border_width: int = 1) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_width)
	sb.border_width_top = border_width + 1
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	sb.shadow_color = Color(0.01, 0.02, 0.05, 0.60)
	sb.shadow_size = 14
	sb.shadow_offset = Vector2(0, 4)
	return sb


func _create_selectable_btn(text: String, is_selected: bool) -> Button:
	var b := Button.new()
	b.text = text
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(140, 48)
	b.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	_set_btn_active(b, is_selected)
	return b


func _set_btn_active(b: Button, active: bool) -> void:
	var sb := StyleBoxFlat.new()
	if active:
		sb.bg_color = Color(0.16, 0.34, 0.66, 0.95)
		sb.border_color = Color(0.45, 0.90, 1.0, 0.95)
		sb.set_border_width_all(1)
		sb.border_width_top = 2
		sb.shadow_color = Color(0.12, 0.45, 0.90, 0.40)
		sb.shadow_size = 8
		b.add_theme_color_override("font_color", Color.WHITE)
	else:
		sb.bg_color = Color(0.08, 0.11, 0.20, 0.75)
		sb.border_color = Color(0.22, 0.32, 0.50, 0.45)
		sb.set_border_width_all(1)
		sb.shadow_size = 0
		b.add_theme_color_override("font_color", Color(0.82, 0.88, 0.98))
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	b.add_theme_stylebox_override("normal", sb)

	var hover := sb.duplicate()
	if not active:
		hover.bg_color = Color(0.14, 0.22, 0.40, 0.90)
		hover.border_color = Color(0.35, 0.65, 0.95, 0.75)
	b.add_theme_stylebox_override("hover", hover)

	var pressed_sb := sb.duplicate()
	pressed_sb.bg_color = Color(0.24, 0.44, 0.80, 0.98)
	pressed_sb.border_color = Color(0.65, 0.95, 1.0)
	b.add_theme_stylebox_override("pressed", pressed_sb)


func _set_army_btn_style(b: Button, active: bool, theme_col: Color, active_bg: Color) -> void:
	var sb := StyleBoxFlat.new()
	if active:
		sb.bg_color = active_bg
		sb.border_color = theme_col
		sb.set_border_width_all(2)
		sb.border_width_top = 3
		sb.shadow_color = theme_col * Color(1.0, 1.0, 1.0, 0.40)
		sb.shadow_size = 10
		b.add_theme_color_override("font_color", Color.WHITE)
	else:
		sb.bg_color = Color(0.08, 0.11, 0.20, 0.75)
		sb.border_color = Color(0.22, 0.32, 0.50, 0.45)
		sb.set_border_width_all(1)
		sb.shadow_size = 0
		b.add_theme_color_override("font_color", Color(0.82, 0.88, 0.98))
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	b.add_theme_stylebox_override("normal", sb)

	var hover := sb.duplicate()
	if not active:
		hover.bg_color = Color(0.14, 0.22, 0.40, 0.90)
		hover.border_color = theme_col * Color(1.0, 1.0, 1.0, 0.60)
	b.add_theme_stylebox_override("hover", hover)

	var pressed_sb := sb.duplicate()
	pressed_sb.bg_color = active_bg.lightened(0.2)
	pressed_sb.border_color = theme_col.lightened(0.2)
	b.add_theme_stylebox_override("pressed", pressed_sb)


func _action_btn(text: String, cb: Callable = Callable()) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(160, 48)
	b.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_filter = Control.MOUSE_FILTER_STOP

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.22, 0.42, 0.90)
	sb.border_color = Color(0.35, 0.62, 0.95, 0.75)
	sb.set_border_width_all(1)
	sb.border_width_top = 2
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	sb.shadow_color = Color(0.01, 0.02, 0.06, 0.50)
	sb.shadow_size = 6
	b.add_theme_stylebox_override("normal", sb)

	var hover: StyleBoxFlat = sb.duplicate()
	hover.bg_color = Color(0.18, 0.32, 0.60, 0.95)
	hover.border_color = Color(0.55, 0.85, 1.0, 0.95)
	hover.shadow_size = 10
	b.add_theme_stylebox_override("hover", hover)

	var pressed_sb: StyleBoxFlat = sb.duplicate()
	pressed_sb.bg_color = Color(0.08, 0.16, 0.32, 0.98)
	pressed_sb.border_color = Color(0.65, 0.95, 1.0, 1.0)
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
	b.custom_minimum_size = Vector2(min_w, 38)
	b.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.add_theme_font_size_override("font_size", 13)

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.14, 0.28, 0.85)
	sb.border_color = Color(0.35, 0.65, 0.95, 0.60)
	sb.set_border_width_all(1)
	sb.border_width_top = 2
	sb.set_corner_radius_all(19)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	sb.shadow_color = Color(0.01, 0.02, 0.05, 0.40)
	sb.shadow_size = 6
	b.add_theme_stylebox_override("normal", sb)

	var hover: StyleBoxFlat = sb.duplicate()
	hover.bg_color = Color(0.14, 0.26, 0.50, 0.95)
	hover.border_color = Color(0.55, 0.90, 1.0, 0.95)
	hover.shadow_size = 10
	b.add_theme_stylebox_override("hover", hover)

	var pressed_sb: StyleBoxFlat = sb.duplicate()
	pressed_sb.bg_color = Color(0.06, 0.14, 0.30, 0.98)
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
	b.custom_minimum_size = Vector2(38, 38)
	b.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.add_theme_font_size_override("font_size", 16)

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.14, 0.28, 0.85)
	sb.border_color = Color(0.35, 0.65, 0.95, 0.60)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(10)
	b.add_theme_stylebox_override("normal", sb)

	var hover := sb.duplicate()
	hover.bg_color = Color(0.14, 0.26, 0.50, 0.95)
	hover.border_color = Color(0.55, 0.90, 1.0, 0.95)
	hover.shadow_size = 8
	b.add_theme_stylebox_override("hover", hover)

	var pressed_sb := sb.duplicate()
	pressed_sb.bg_color = Color(0.06, 0.14, 0.30, 0.98)
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

	_host_code_label.text = "КОД КОМНАТЫ: %s" % code

	var type_title := ""
	if g_type == "d20_multi":
		type_title = "🎲 D20 Мульти-шахматы " + variant
	elif g_type == "multi":
		type_title = "Мульти-шахматы " + variant
	else:
		type_title = "5D Хроно-шахматы (" + variant + ")"
	if _lobby_info_label != null:
		_lobby_info_label.text = "Формат: %s · Игроков: %d из %d" % [type_title, players.size(), max_p]

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
			var col: Color = MultiChessState.PLAYER_COLORS[i] if (is_multi_lobby and i < MultiChessState.PLAYER_COLORS.size()) else (Color(0.95, 0.95, 1.0) if i == 0 else Color(0.7, 0.7, 0.75))
			var col_name: String = MultiChessState.PLAYER_NAMES[i] if (is_multi_lobby and i < MultiChessState.PLAYER_NAMES.size()) else ("Белые" if i == 0 else "Чёрные")

			var card_sb := StyleBoxFlat.new()
			card_sb.set_corner_radius_all(8)
			card_sb.set_border_width_all(1)

			var lbl := Label.new()
			lbl.add_theme_font_size_override("font_size", 14)

			if not p_data.is_empty():
				var p_name: String = str(p_data.get("name", "Игрок"))
				var is_h: bool = bool(p_data.get("is_host", false))
				var p_skin: String = str(p_data.get("skin", "classic"))
				var s_info := Skins.get_skin(p_skin)
				var s_name: String = str(s_info.get("name", "Классический"))
				var host_tag := " [ХОСТ]" if is_h else ""
				lbl.text = "🟢 %s%s — %s · 🎨 %s" % [p_name, host_tag, col_name, s_name]
				card_sb.bg_color = col.darkened(0.7)
				card_sb.border_color = col
				lbl.add_theme_color_override("font_color", Color.WHITE)
			else:
				lbl.text = "⚪ Слот %d: Ожидание игрока... (%s)" % [i + 1, col_name]
				card_sb.bg_color = Color(0.1, 0.12, 0.18, 0.6)
				card_sb.border_color = Color(0.25, 0.3, 0.45, 0.5)
				lbl.add_theme_color_override("font_color", Color(0.65, 0.7, 0.8))

			card_sb.content_margin_left = 10
			card_sb.content_margin_right = 10
			card_sb.content_margin_top = 6
			card_sb.content_margin_bottom = 6
			slot_card.add_theme_stylebox_override("panel", card_sb)
			slot_card.add_child(lbl)
			_lobby_players_box.add_child(slot_card)

	if _lobby_start_btn != null:
		_lobby_start_btn.visible = net.is_host
