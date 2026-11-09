class_name MultiGameScreen
extends Control

## Экран партии мульти-шахмат без путешествий во времени (1х1х1, 2х2, 1х1х1х1).
## Поддерживает локальную игру (против ИИ или Pass & Play) и сетевую онлайн-игру.

signal exit_requested

var state: MultiChessState
var view: MultiChessView
var sfx: Sfx

var game_mode: String = MultiChessState.MODE_1V1V1V1
var is_pass_and_play: bool = false
var human_player: int = MultiChessState.WHITE
var ai_level: int = MultiChessAI.LEVEL_NORMAL
var ai: MultiChessAI
var is_d20_mode: bool = false

var net: Net = null
var slots: Array = []

var _busy: bool = false
var _game_over: bool = false

# UI
var _top_panel: PanelContainer
var _bot_panel: PanelContainer
var _mode_title: Label
var _turn_count_lbl: Label
var _turn_badge: Button
var _status_row: HBoxContainer
var _player_cards: Array = []
var _net_badge_btn: Button = null
var player_skins: Dictionary = {}


func setup(p_mode: String, p_is_pass_and_play: bool, p_human_color: int, p_ai_level: int, p_sfx: Sfx, p_net: Net = null, p_slots: Array = [], p_is_d20: bool = false) -> void:
	game_mode = p_mode
	is_pass_and_play = p_is_pass_and_play
	human_player = p_human_color
	ai_level = p_ai_level
	sfx = p_sfx
	net = p_net
	slots = p_slots.duplicate()
	is_d20_mode = p_is_d20

	player_skins.clear()
	for slot in slots:
		if slot is Dictionary:
			var col: int = int(slot.get("color", 0))
			var sk: String = str(slot.get("skin", "classic"))
			player_skins[col] = sk
	player_skins[human_player] = Profile.active_skin

	state = MultiChessState.new()
	state.setup(game_mode)

	ai = MultiChessAI.new(ai_level)

	if net != null:
		net.multi_turn_received.connect(_on_remote_multi_turn)
		net.disconnected.connect(_on_net_disconnected)
		net.player_resigned.connect(_on_player_resigned)
		net.player_skin_updated.connect(_on_net_player_skin_updated)


func _exit_tree() -> void:
	if get_viewport() != null and get_viewport().size_changed.is_connected(_on_viewport_resized):
		get_viewport().size_changed.disconnect(_on_viewport_resized)
	if net != null:
		if net.multi_turn_received.is_connected(_on_remote_multi_turn):
			net.multi_turn_received.disconnect(_on_remote_multi_turn)
		if net.disconnected.is_connected(_on_net_disconnected):
			net.disconnected.disconnect(_on_net_disconnected)
		if net.player_resigned.is_connected(_on_player_resigned):
			net.player_resigned.disconnect(_on_player_resigned)
		if net.player_skin_updated.is_connected(_on_net_player_skin_updated):
			net.player_skin_updated.disconnect(_on_net_player_skin_updated)


func _on_net_player_skin_updated(col: int, skin_id: String) -> void:
	player_skins[col] = skin_id
	if view != null:
		view.player_skins[col] = skin_id
		view.queue_redraw()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Живой процедурный космический фон с мерцающими звёздами и туманностями
	var bg := CosmicBackground.new()
	add_child(bg)

	# Основная доска (расположена по центру, вычисляя отступы под панели)
	view = MultiChessView.new()
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view.state = state
	view.human_player = human_player
	view.is_pass_and_play = is_pass_and_play
	view.player_skins = player_skins
	view.move_requested.connect(_on_move_requested)
	add_child(view)

	_build_ui()
	_update_hud()

	get_viewport().size_changed.connect(_on_viewport_resized)
	_on_viewport_resized()

	# Если первый ход делает ИИ
	_check_ai_turn()


func _on_viewport_resized() -> void:
	var vp_size := get_viewport_rect().size
	var insets := Settings.safe_insets(vp_size)
	var is_compact: bool = vp_size.x < 680.0

	if _top_panel != null:
		var top_sb := _panel_style(10)
		top_sb.content_margin_top = int(maxf(6.0, insets.top + 4.0))
		top_sb.content_margin_bottom = 6
		top_sb.content_margin_left = int(maxf(10.0, insets.left + 6.0))
		top_sb.content_margin_right = int(maxf(10.0, insets.right + 6.0))
		_top_panel.add_theme_stylebox_override("panel", top_sb)

	if _bot_panel != null:
		var bot_sb := _panel_style(8)
		bot_sb.content_margin_bottom = int(maxf(8.0, insets.bottom + 6.0))
		bot_sb.content_margin_top = 6
		bot_sb.content_margin_left = int(maxf(10.0, insets.left + 6.0))
		bot_sb.content_margin_right = int(maxf(10.0, insets.right + 6.0))
		_bot_panel.add_theme_stylebox_override("panel", bot_sb)

	if _mode_title != null:
		var prefix := "🎲 D20 · " if is_d20_mode else ""
		match game_mode:
			MultiChessState.MODE_1V1V1:
				_mode_title.text = (prefix + "1х1х1") if is_compact else (prefix + "⚔ 1х1х1 (FFA)")
			MultiChessState.MODE_2V2:
				_mode_title.text = (prefix + "2х2") if is_compact else (prefix + "🛡 2х2 (Команда)")
			MultiChessState.MODE_1V1V1V1:
				_mode_title.text = (prefix + "1х1х1х1") if is_compact else (prefix + "⚔ 1х1х1х1 (FFA)")

	if _turn_badge != null:
		_turn_badge.custom_minimum_size.x = 140 if is_compact else 210

	if view != null:
		view.queue_redraw()


func _build_ui() -> void:
	# Верхняя панель
	_top_panel = PanelContainer.new()
	_top_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_top_panel.add_theme_stylebox_override("panel", _panel_style(10))
	add_child(_top_panel)

	var top_hb := HBoxContainer.new()
	top_hb.add_theme_constant_override("separation", 10)
	_top_panel.add_child(top_hb)

	var menu_btn := Button.new()
	menu_btn.text = "⚙ Меню"
	menu_btn.custom_minimum_size = Vector2(84, 40)
	menu_btn.pressed.connect(_on_menu_pressed)
	top_hb.add_child(menu_btn)

	_mode_title = Label.new()
	_mode_title.add_theme_font_size_override("font_size", 16)
	_mode_title.add_theme_color_override("font_color", Color(0.95, 0.96, 1.0))
	top_hb.add_child(_mode_title)

	_turn_count_lbl = Label.new()
	_turn_count_lbl.add_theme_font_size_override("font_size", 13)
	_turn_count_lbl.add_theme_color_override("font_color", Color(0.65, 0.8, 1.0))
	top_hb.add_child(_turn_count_lbl)

	if net != null and net.room_code != "":
		_net_badge_btn = Button.new()
		_net_badge_btn.text = "🔑 " + net.room_code
		_net_badge_btn.tooltip_text = "Нажмите, чтобы скопировать код комнаты"
		_net_badge_btn.custom_minimum_size = Vector2(85, 38)
		_net_badge_btn.pressed.connect(func():
			DisplayServer.clipboard_set(net.room_code)
			_net_badge_btn.text = "✔ Скопирован!")
		top_hb.add_child(_net_badge_btn)

	top_hb.add_child(Control.new())
	top_hb.get_child(top_hb.get_child_count() - 1).size_flags_horizontal = Control.SIZE_EXPAND_FILL

	_turn_badge = Button.new()
	_turn_badge.custom_minimum_size = Vector2(210, 40)
	_turn_badge.focus_mode = Control.FOCUS_NONE
	_turn_badge.add_theme_font_size_override("font_size", 14)
	top_hb.add_child(_turn_badge)

	# Нижняя панель со статусом игроков
	var bot_panel := PanelContainer.new()
	bot_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bot_panel.add_theme_stylebox_override("panel", _panel_style(8))
	add_child(bot_panel)
	_bot_panel = bot_panel

	_status_row = HBoxContainer.new()
	_status_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_status_row.add_theme_constant_override("separation", 8)
	bot_panel.add_child(_status_row)

	_create_player_cards()


func _create_player_cards() -> void:
	_player_cards.clear()
	for child in _status_row.get_children():
		child.queue_free()

	for p in state.active_players:
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.custom_minimum_size = Vector2(100, 48)
		_status_row.add_child(card)

		var card_vb := VBoxContainer.new()
		card_vb.alignment = BoxContainer.ALIGNMENT_CENTER
		card_vb.add_theme_constant_override("separation", 2)
		card.add_child(card_vb)

		var top_row := HBoxContainer.new()
		top_row.alignment = BoxContainer.ALIGNMENT_CENTER
		top_row.add_theme_constant_override("separation", 6)
		card_vb.add_child(top_row)

		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(8, 8)
		dot.color = MultiChessState.PLAYER_COLORS[p]
		top_row.add_child(dot)

		var name_lbl := Label.new()
		name_lbl.add_theme_font_size_override("font_size", 13)
		name_lbl.clip_text = true
		top_row.add_child(name_lbl)

		var team_lbl := Label.new()
		team_lbl.add_theme_font_size_override("font_size", 11)
		team_lbl.visible = (game_mode == MultiChessState.MODE_2V2)
		top_row.add_child(team_lbl)

		var sub_lbl := Label.new()
		sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub_lbl.add_theme_font_size_override("font_size", 11)
		card_vb.add_child(sub_lbl)

		_player_cards.append({
			"card": card,
			"name_lbl": name_lbl,
			"team_lbl": team_lbl,
			"sub_lbl": sub_lbl,
			"dot": dot,
			"player": p
		})


func _is_bot_slot(p: int) -> bool:
	if net == null:
		return not is_pass_and_play and p != human_player
	for s in slots:
		if int(s.get("color", -1)) == p:
			return bool(s.get("is_bot", false))
	return false


func get_player_display_name(p: int) -> String:
	if not slots.is_empty():
		for s in slots:
			if int(s.get("color", -1)) == p:
				var n: String = str(s.get("name", ""))
				if n != "":
					return n
	return MultiChessState.PLAYER_NAMES[p]


func _update_hud() -> void:
	var cur := state.turn
	var p_name: String = get_player_display_name(cur)
	var type_str := ""
	if net != null:
		if cur == human_player:
			type_str = " (Вы)"
		elif _is_bot_slot(cur):
			type_str = " (Бот)"
		else:
			type_str = " (Игрок)"
	else:
		var is_ai := (not is_pass_and_play and cur != human_player)
		type_str = " (ИИ)" if is_ai else " (Игрок)"

	_turn_badge.text = "Ход: %s%s" % [p_name, type_str]
	if _turn_count_lbl != null:
		_turn_count_lbl.text = "· Ход #%d" % state.move_number

	var cur_col: Color = MultiChessState.PLAYER_COLORS[cur]
	var badge_sb := StyleBoxFlat.new()
	badge_sb.bg_color = cur_col.darkened(0.65)
	badge_sb.border_color = cur_col
	badge_sb.set_border_width_all(2)
	badge_sb.set_corner_radius_all(8)
	_turn_badge.add_theme_stylebox_override("normal", badge_sb)

	# Обновление карточек игроков
	for item in _player_cards:
		var p: int = item["player"]
		var card: PanelContainer = item["card"]
		var name_lbl: Label = item["name_lbl"]
		var team_lbl: Label = item["team_lbl"]
		var sub_lbl: Label = item["sub_lbl"]

		var is_eliminated := state.eliminated_players.has(p)
		var p_col: Color = MultiChessState.PLAYER_COLORS[p]
		var pieces := state.count_pieces(p)
		var is_in_check := (not is_eliminated and state.is_king_threatened(p))

		var display_name: String = get_player_display_name(p)
		if net != null and p == human_player:
			display_name += " (Вы)"
		name_lbl.text = display_name

		if game_mode == MultiChessState.MODE_2V2:
			var team_num := 1 if (p == MultiChessState.WHITE or p == MultiChessState.BLACK) else 2
			team_lbl.text = "[К%d]" % team_num
			team_lbl.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0) if team_num == 1 else Color(1.0, 0.75, 0.5))

		if is_eliminated:
			sub_lbl.text = "☠ ВЫБЫЛ"
			sub_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.6))
		elif is_in_check:
			sub_lbl.text = "⚠️ ШАХ! (%d фиг.)" % pieces
			sub_lbl.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
		else:
			sub_lbl.text = "%d фиг." % pieces
			sub_lbl.add_theme_color_override("font_color", Color(0.85, 0.9, 0.98))

		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(6)
		sb.content_margin_left = 6
		sb.content_margin_right = 6
		sb.content_margin_top = 4
		sb.content_margin_bottom = 4

		if is_eliminated:
			sb.bg_color = Color(0.08, 0.09, 0.12, 0.5)
			sb.border_color = Color(0.25, 0.25, 0.3, 0.3)
			sb.set_border_width_all(1)
			name_lbl.add_theme_color_override("font_color", Color(0.45, 0.45, 0.5))
		elif p == cur:
			sb.bg_color = p_col.darkened(0.7)
			sb.border_color = p_col
			sb.set_border_width_all(2)
			name_lbl.add_theme_color_override("font_color", Color.WHITE)
		else:
			sb.bg_color = Color(0.07, 0.09, 0.16, 0.75)
			sb.border_color = p_col.darkened(0.4)
			sb.set_border_width_all(1)
			name_lbl.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))

		card.add_theme_stylebox_override("panel", sb)


func _populate_d20_roll(m: Dictionary) -> void:
	if not is_d20_mode:
		return
	var target := state.get_cell(int(m["tx"]), int(m["ty"]))
	if target == MultiChessState.EMPTY:
		return
	var attacker := state.get_cell(int(m["fx"]), int(m["fy"]))
	var threshold := MultiChessState.get_d20_threshold(attacker, target)
	var roll := randi_range(1, 20)
	var success := (roll == 20) or (roll != 1 and roll >= threshold)
	m["d20_roll"] = roll
	m["d20_threshold"] = threshold
	m["d20_success"] = success
	m["d20_attacker"] = attacker
	m["d20_target"] = target


func _on_move_requested(from_pos: Vector2i, to_pos: Vector2i) -> void:
	if _busy or _game_over:
		return
	var cur := state.turn
	if not is_pass_and_play and cur != human_player:
		return
	var m := {"fx": from_pos.x, "fy": from_pos.y, "tx": to_pos.x, "ty": to_pos.y}
	_populate_d20_roll(m)
	_apply_move_animated(m, true)


func _on_remote_multi_turn(m: Dictionary) -> void:
	if _game_over:
		return
	if m.has("action") and m["action"] == "eliminate":
		var p_elim: int = int(m.get("player", -1))
		if p_elim != -1 and not state.eliminated_players.has(p_elim):
			state.eliminate_player(p_elim)
			state.advance_turn()
			_update_hud()
			if state.is_game_over():
				_finish_game()
			else:
				_check_ai_turn()
		return

	_apply_move_animated(m, false)


func _apply_move_animated(m: Dictionary, broadcast: bool = false) -> void:
	_busy = true
	view.locked = true

	if broadcast and net != null:
		net.send_multi_turn(m)

	if is_d20_mode and m.has("d20_roll"):
		_show_d20_duel(m, func():
			_execute_move_animation(m)
		)
	else:
		_execute_move_animation(m)


func _execute_move_animation(m: Dictionary) -> void:
	var target := state.get_cell(m["tx"], m["ty"])
	var is_capture := (target != MultiChessState.EMPTY)
	var is_d20_fail := is_d20_mode and m.has("d20_success") and not bool(m["d20_success"])
	var is_d20_crit := is_d20_mode and (int(m.get("d20_roll", 0)) == 20)

	view.animate_move(m, func():
		state.apply_move(m, is_d20_mode)
		view.queue_redraw()

		if sfx != null:
			if is_d20_crit:
				sfx.play("crit")
			elif is_d20_fail:
				sfx.play("block")
			elif is_capture:
				sfx.play("capture")
			else:
				sfx.play("move")

		# Проверка на шах: если чей-то король под угрозой, даём сочную тряску и предупреждение
		for p_idx in state.active_players:
			if not state.eliminated_players.has(p_idx) and state.is_king_threatened(p_idx):
				var k_pos := state.find_king(p_idx)
				if k_pos.x != -1:
					var kr := view.get_cell_screen_rect(k_pos.x, k_pos.y)
					var kc := kr.get_center()
					view.shake(6.5)
					view.add_shockwave(kc, Color(1.0, 0.25, 0.25), kr.size.x * 1.5, 0.45, 2)
					view.add_floating_text("⚡ ШАХ!", kc, Color(1.0, 0.3, 0.3), 24)
					if sfx != null:
						sfx.play("check")

		_update_hud()
		_busy = false
		view.locked = false

		if state.is_game_over():
			_finish_game()
		else:
			_check_ai_turn()
	)


func _show_d20_duel(m: Dictionary, on_finished: Callable) -> void:
	var a_piece: int = int(m.get("d20_attacker", 0))
	var d_piece: int = int(m.get("d20_target", 0))
	var roll: int = int(m.get("d20_roll", 10))
	var threshold: int = int(m.get("d20_threshold", 10))
	var success: bool = bool(m.get("d20_success", false))

	var a_type := MultiChessState.get_piece_type(a_piece)
	var a_owner := MultiChessState.get_piece_player(a_piece)
	var d_type := MultiChessState.get_piece_type(d_piece)
	var d_owner := MultiChessState.get_piece_player(d_piece)

	var a_name: String = MultiChessState.PIECE_NAMES.get(a_type, "Фигура")
	var d_name: String = MultiChessState.PIECE_NAMES.get(d_type, "Фигура")
	var a_pl_name: String = MultiChessState.PLAYER_NAMES[a_owner] if a_owner >= 0 and a_owner < MultiChessState.PLAYER_NAMES.size() else "Игрок"
	var d_pl_name: String = MultiChessState.PLAYER_NAMES[d_owner] if d_owner >= 0 and d_owner < MultiChessState.PLAYER_NAMES.size() else "Игрок"

	var a_col: Color = MultiChessState.PLAYER_COLORS[a_owner] if a_owner >= 0 and a_owner < MultiChessState.PLAYER_COLORS.size() else Color.WHITE
	var d_col: Color = MultiChessState.PLAYER_COLORS[d_owner] if d_owner >= 0 and d_owner < MultiChessState.PLAYER_COLORS.size() else Color.WHITE

	# Оверлей затемнения
	var overlay := ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.02, 0.03, 0.07, 0.72)
	add_child(overlay)

	# Центрированная карточка битвы
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var card := PanelContainer.new()
	var card_sb := StyleBoxFlat.new()
	card_sb.bg_color = Color(0.07, 0.09, 0.16, 0.96)
	card_sb.border_color = Color(0.3, 0.55, 0.95, 0.85)
	card_sb.set_border_width_all(2)
	card_sb.set_corner_radius_all(14)
	card_sb.content_margin_left = 24
	card_sb.content_margin_right = 24
	card_sb.content_margin_top = 20
	card_sb.content_margin_bottom = 20
	card.add_theme_stylebox_override("panel", card_sb)

	var vp_w := get_viewport_rect().size.x
	card.custom_minimum_size = Vector2(minf(vp_w - 36, 420), 0)
	center.add_child(card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	card.add_child(vb)

	# Заголовок
	var title_lbl := Label.new()
	title_lbl.text = "🎲 ДУЭЛЬ D20: КУБИК СУДЬБЫ"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	vb.add_child(title_lbl)

	# Ряд противостояния: Атака vs Защита
	var clash_box := HBoxContainer.new()
	clash_box.alignment = BoxContainer.ALIGNMENT_CENTER
	clash_box.add_theme_constant_override("separation", 12)
	vb.add_child(clash_box)

	var a_lbl := Label.new()
	a_lbl.text = "⚔ %s\n%s (сила %d)" % [a_name, a_pl_name, MultiChessState.get_piece_value(a_type)]
	a_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	a_lbl.add_theme_font_size_override("font_size", 13)
	a_lbl.add_theme_color_override("font_color", a_col)
	clash_box.add_child(a_lbl)

	var vs_lbl := Label.new()
	vs_lbl.text = "VS"
	vs_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vs_lbl.add_theme_font_size_override("font_size", 18)
	vs_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	clash_box.add_child(vs_lbl)

	var d_lbl := Label.new()
	d_lbl.text = "🛡 %s\n%s (сила %d)" % [d_name, d_pl_name, MultiChessState.get_piece_value(d_type)]
	d_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	d_lbl.add_theme_font_size_override("font_size", 13)
	d_lbl.add_theme_color_override("font_color", d_col)
	clash_box.add_child(d_lbl)

	# Порог кубика
	var dc_lbl := Label.new()
	dc_lbl.text = "🎯 Необходимый бросок (DC): %d+" % threshold
	dc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dc_lbl.add_theme_font_size_override("font_size", 14)
	dc_lbl.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	vb.add_child(dc_lbl)

	# Блок с кубиком
	var dice_panel := PanelContainer.new()
	var d_sb := StyleBoxFlat.new()
	d_sb.bg_color = Color(0.12, 0.16, 0.28, 0.9)
	d_sb.border_color = Color(0.4, 0.65, 1.0, 0.7)
	d_sb.set_border_width_all(2)
	d_sb.set_corner_radius_all(12)
	d_sb.content_margin_top = 8
	d_sb.content_margin_bottom = 8
	dice_panel.add_theme_stylebox_override("panel", d_sb)
	dice_panel.custom_minimum_size = Vector2(90, 80)
	dice_panel.pivot_offset = Vector2(45, 40)
	dice_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(dice_panel)

	var dice_lbl := Label.new()
	dice_lbl.text = "?"
	dice_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dice_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dice_lbl.add_theme_font_size_override("font_size", 42)
	dice_lbl.add_theme_color_override("font_color", Color.WHITE)
	dice_panel.add_child(dice_lbl)

	# Статус результата
	var res_lbl := Label.new()
	res_lbl.text = "Бросок кубика d20..."
	res_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	res_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	res_lbl.add_theme_font_size_override("font_size", 14)
	res_lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	vb.add_child(res_lbl)

	if sfx != null:
		sfx.play("dice")

	# Анимация кручения кубика
	var tw := create_tween()
	var roll_steps := 8
	for i in range(roll_steps):
		tw.tween_callback(func():
			dice_lbl.text = str(randi_range(1, 20))
			dice_panel.scale = Vector2(randf_range(0.92, 1.08), randf_range(0.92, 1.08))
			if sfx != null:
				sfx.play("click")
		)
		tw.tween_interval(0.06 + i * 0.015)

	# Финальный результат броска
	tw.tween_callback(func():
		dice_lbl.text = str(roll)
		# Сочный bounce scale punch
		var ptw := create_tween()
		dice_panel.scale = Vector2(1.3, 1.3)
		ptw.tween_property(dice_panel, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

		if roll == 20:
			view.shake(14.0)
			d_sb.border_color = Color(1.0, 0.85, 0.2)
			dice_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
			res_lbl.text = "🔥 КРИТИЧЕСКИЙ ТРИУМФ! (20)\nАтака безупречна! Взятие гарантировано!"
			res_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
			if sfx != null:
				sfx.play("crit")
		elif roll == 1:
			view.shake(9.0)
			d_sb.border_color = Color(1.0, 0.25, 0.25)
			dice_lbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
			res_lbl.text = "💥 КРИТИЧЕСКИЙ ПРОВАЛ! (1)\nОсечка! Защитник парирует удар!"
			res_lbl.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
			if sfx != null:
				sfx.play("block")
		elif success:
			view.shake(5.5)
			d_sb.border_color = Color(0.2, 0.9, 0.4)
			dice_lbl.add_theme_color_override("font_color", Color(0.35, 1.0, 0.5))
			res_lbl.text = "⚔ ПОБЕДА АТАКИ! (%d ≥ %d)\nЗащита пробита, фигура повержена!" % [roll, threshold]
			res_lbl.add_theme_color_override("font_color", Color(0.3, 0.95, 0.45))
			if sfx != null:
				sfx.play("capture")
		else:
			view.shake(5.0)
			d_sb.border_color = Color(0.95, 0.55, 0.2)
			dice_lbl.add_theme_color_override("font_color", Color(0.95, 0.65, 0.3))
			res_lbl.text = "🛡 УДАР ОТБИТ! (%d < %d)\nЗащитник устоял! Атакующий отброшен!" % [roll, threshold]
			res_lbl.add_theme_color_override("font_color", Color(0.95, 0.6, 0.25))
			if sfx != null:
				sfx.play("block")
	)

	# Задержка на чтение и плавное затухание
	tw.tween_interval(0.75)
	tw.tween_property(overlay, "modulate:a", 0.0, 0.2)
	tw.tween_callback(func():
		overlay.queue_free()
		if on_finished.is_valid():
			on_finished.call()
	)


func _check_ai_turn() -> void:
	if _busy or _game_over:
		return
	var cur := state.turn
	var is_ai := false
	if net != null:
		# В сетевой игре за ботов ходит только хост комнаты
		if not net.is_host:
			return
		is_ai = _is_bot_slot(cur)
	else:
		is_ai = (not is_pass_and_play and cur != human_player)

	if not is_ai:
		return

	_busy = true
	view.locked = true

	# Естественная задержка раздумий ИИ (0.35 сек)
	await get_tree().create_timer(0.35).timeout
	if not is_inside_tree() or _game_over:
		_busy = false
		view.locked = false
		return

	var m := ai.choose_move(state)
	if m.is_empty():
		# Нет ходов — игрок выбывает
		state.eliminate_player(cur)
		state.advance_turn()
		if net != null:
			net.send_multi_turn({"action": "eliminate", "player": cur})
		_update_hud()
		_busy = false
		view.locked = false
		if state.is_game_over():
			_finish_game()
		else:
			_check_ai_turn()
		return

	_populate_d20_roll(m)
	_apply_move_animated(m, net != null)


func _on_player_resigned(r_color: int, _p_name: String) -> void:
	if state.eliminated_players.has(r_color):
		return
	state.eliminate_player(r_color)
	_update_hud()
	if sfx != null:
		sfx.play("check")
	if state.turn == r_color:
		state.advance_turn()
		_update_hud()
	if state.is_game_over():
		_finish_game()
	else:
		_check_ai_turn()


func _on_net_disconnected(reason: String) -> void:
	if _game_over:
		return
	_game_over = true
	view.locked = true
	var dlg := AcceptDialog.new()
	dlg.title = "Связь потеряна"
	dlg.dialog_text = "Связь с сервером прервана:\n%s" % reason
	dlg.ok_button_text = "В главное меню"
	dlg.confirmed.connect(func(): exit_requested.emit())
	add_child(dlg)
	dlg.popup_centered()


func _finish_game() -> void:
	_game_over = true
	view.locked = true
	if sfx != null:
		sfx.play("win")

	if net != null:
		net.clear_active_session()

	view.shake(16.0)
	var center := view.size * 0.5
	view.emit_sparks(center, Color(1.0, 0.88, 0.25), 65, 290.0, true)
	view.add_shockwave(center, Color(1.0, 0.85, 0.2), view.size.x * 0.45, 0.75, 3)
	view.add_floating_text("👑 ПОБЕДА!", center, Color(1.0, 0.92, 0.25), 32)

	var info := state.get_winner_info()
	var text: String = str(info.get("title", "Игра окончена!"))

	var last_m: Dictionary = state.last_move
	if not last_m.is_empty():
		var tx: int = int(last_m.get("tx", -1))
		var ty: int = int(last_m.get("ty", -1))
		if tx != -1 and ty != -1:
			view.mate_cell = Vector2i(tx, ty)
			view.queue_redraw()
			var cols := ["a","b","c","d","e","f","g","h","i","j","k","l","m","n"]
			var sq_str := "%s%d" % [cols[tx] if tx < cols.size() else str(tx), ty + 1]
			text += "\n\n📍 Решающий ход на поле: %s" % sq_str

	var dlg := AcceptDialog.new()
	dlg.title = "Партия завершена"
	dlg.dialog_text = text
	dlg.ok_button_text = "В главное меню"
	dlg.confirmed.connect(func(): exit_requested.emit())
	add_child(dlg)
	dlg.popup_centered()


func _on_menu_pressed() -> void:
	var dlg := ConfirmationDialog.new()
	dlg.title = "Меню партии"
	dlg.dialog_text = "Вы хотите сдаться и выйти в главное меню?"
	dlg.ok_button_text = "Выйти в меню"
	dlg.cancel_button_text = "Продолжить"
	dlg.confirmed.connect(func():
		if net != null:
			if net.is_online_mode:
				net.online_resign()
				net.online_leave_room()
			else:
				net.close()
		exit_requested.emit())
	add_child(dlg)
	dlg.popup_centered()


func _panel_style(margin: int = 12) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.08, 0.15, 0.94)
	sb.border_color = Color(0.22, 0.30, 0.50, 0.65)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = margin
	sb.content_margin_right = margin
	sb.content_margin_top = margin * 0.7
	sb.content_margin_bottom = margin * 0.7
	return sb
