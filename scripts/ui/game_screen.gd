class_name GameScreen
extends Control

## Экран партии: доски, панель управления, логика ходов игрока/ИИ/сети.

signal exit_requested

const MODE_LOCAL := "local"
const MODE_AI := "ai"
const MODE_ONLINE := "online"
const MODE_PUZZLE := "puzzle"

var state: GameState
var mode: String = MODE_LOCAL
var human_color: int = GameState.WHITE   # для ИИ и сети
var ai: ChessAI
var net: Net
var sfx: Sfx
var variant_id: String = "standard"
var auto_follow_present: bool = true
var puzzle_data: Dictionary = {}

var view: MultiverseView
var _top_panel: PanelContainer
var _bottom_panel: PanelContainer
var _menu_btn: Button
var _present_btn: Button
var _status: Label
var _info: Label
var _toast: Label
var _autofocus_btn: Button
var _btn_undo: Button
var _btn_reset: Button
var _btn_hint: Button
var _btn_submit: Button
var _puz_restart_btn: Button
var _puz_hint_btn: Button
var _puz_next_btn: Button
var _busy: bool = false
var _game_over: bool = false
var _promo_popup: PanelContainer
var _pending_promo: Dictionary = {}
var _toast_tween: Tween
var _ai_thread: Thread
var _minimap: TimelineMinimap
var _minimap_toggle_btn: Button
var _chrono_wheel: ChronoWheel
var _rift_rect: ColorRect
var _rift_material: ShaderMaterial

# Элементы переподключения (Reconnection System)
var _initial_turns: Array = []
var _opp_dc_banner: PanelContainer
var _opp_dc_label: Label
var _opp_dc_seconds_left: float = 0.0
var _self_reconnect_modal: Control
var _self_reconnect_label: Label


func setup(p_variant: String, p_mode: String, p_color: int, p_ai_level: int, p_net: Net, p_sfx: Sfx, p_initial_turns: Array = [], p_puzzle: Dictionary = {}) -> void:
	variant_id = p_variant
	mode = p_mode
	human_color = p_color
	net = p_net
	sfx = p_sfx
	_initial_turns = p_initial_turns
	puzzle_data = p_puzzle

	if mode == MODE_PUZZLE and not puzzle_data.is_empty():
		state = GameState.new()
		var pw: int = int(puzzle_data.get("w", 8))
		var ph: int = int(puzzle_data.get("h", 8))
		var p_rows: Array = puzzle_data.get("rows", [])
		var p_tz: bool = bool(puzzle_data.get("turn_zero", false))
		state.setup(pw, ph, p_rows, p_tz)
	else:
		state = Variants.create(variant_id)
	if mode == MODE_AI:
		ai = ChessAI.new(p_ai_level)
	if mode == MODE_ONLINE and net != null:
		net.turn_received.connect(_on_remote_turn)
		net.resign_received.connect(_on_remote_resign)
		net.disconnected.connect(_on_net_disconnected)
		net.opponent_disconnected_temporary.connect(_on_opponent_disconnected_temp)
		net.opponent_reconnected.connect(_on_opponent_reconnected)
		net.reconnecting.connect(_on_self_reconnecting)
		net.reconnected_to_match.connect(_on_reconnected_to_match)
		net.reconnect_failed.connect(_on_reconnect_failed)
		net.player_skin_updated.connect(_on_net_player_skin_updated)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view = MultiverseView.new()
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view.state = state
	view.flip = mode != MODE_LOCAL and human_color == GameState.BLACK
	view.square_tapped.connect(_on_square_tapped)

	# Настройка отображения скинов игроков
	var p_skins: Dictionary = {
		human_color: Profile.active_skin,
		(1 - human_color): "classic"
	}
	if net != null and mode == MODE_ONLINE:
		if net.opponent_skin != "":
			p_skins[1 - human_color] = net.opponent_skin
		for k in net.player_skins:
			p_skins[k] = net.player_skins[k]
	view.player_skins = p_skins
	add_child(view)

	# Экранный слой шейдера временного разлома (Chrono Rift)
	_setup_rift_shader()

	_build_hud()

	if not _initial_turns.is_empty():
		for turn_moves in _initial_turns:
			for m in turn_moves:
				state.apply_move(m)
			state.submit()

	await get_tree().process_frame
	view.focus_present()
	_after_state_change()
	if mode == MODE_PUZZLE and not puzzle_data.is_empty():
		_info.text = "🧩 %s · Награда: 💎 +%d" % [puzzle_data.get("title", ""), int(puzzle_data.get("reward", 50))]
		_status.text = str(puzzle_data.get("desc", "Найдите победный ход!"))
	_maybe_ai_turn()

	get_viewport().size_changed.connect(_on_viewport_resized)
	_on_viewport_resized()


func _exit_tree() -> void:
	if get_viewport() != null and get_viewport().size_changed.is_connected(_on_viewport_resized):
		get_viewport().size_changed.disconnect(_on_viewport_resized)
	if net != null:
		if net.turn_received.is_connected(_on_remote_turn):
			net.turn_received.disconnect(_on_remote_turn)
		if net.resign_received.is_connected(_on_remote_resign):
			net.resign_received.disconnect(_on_remote_resign)
		if net.disconnected.is_connected(_on_net_disconnected):
			net.disconnected.disconnect(_on_net_disconnected)
		if net.opponent_disconnected_temporary.is_connected(_on_opponent_disconnected_temp):
			net.opponent_disconnected_temporary.disconnect(_on_opponent_disconnected_temp)
		if net.opponent_reconnected.is_connected(_on_opponent_reconnected):
			net.opponent_reconnected.disconnect(_on_opponent_reconnected)
		if net.reconnecting.is_connected(_on_self_reconnecting):
			net.reconnecting.disconnect(_on_self_reconnecting)
		if net.reconnected_to_match.is_connected(_on_reconnected_to_match):
			net.reconnected_to_match.disconnect(_on_reconnected_to_match)
		if net.reconnect_failed.is_connected(_on_reconnect_failed):
			net.reconnect_failed.disconnect(_on_reconnect_failed)
		if net.player_skin_updated.is_connected(_on_net_player_skin_updated):
			net.player_skin_updated.disconnect(_on_net_player_skin_updated)


func _on_net_player_skin_updated(col: int, skin_id: String) -> void:
	if view != null:
		view.player_skins[col] = skin_id
		view.queue_redraw()


# ---------------------------------------------------------------- интерфейс

func _build_hud() -> void:
	_top_panel = PanelContainer.new()
	_top_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_top_panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(_top_panel)

	# Баннер ожидания соперника при временном разрыве связи
	_opp_dc_banner = PanelContainer.new()
	_opp_dc_banner.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_opp_dc_banner.offset_top = 76
	_opp_dc_banner.offset_bottom = 122
	_opp_dc_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_opp_dc_banner.add_theme_stylebox_override("panel", _banner_style(Color(0.25, 0.14, 0.04, 0.95), Color(1.0, 0.7, 0.2, 0.9)))
	_opp_dc_banner.visible = false
	add_child(_opp_dc_banner)

	_opp_dc_label = Label.new()
	_opp_dc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_opp_dc_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_opp_dc_label.add_theme_font_size_override("font_size", 14)
	_opp_dc_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
	_opp_dc_banner.add_child(_opp_dc_label)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 8)
	_top_panel.add_child(top_row)

	_menu_btn = _button("Меню", _on_menu)
	top_row.add_child(_menu_btn)

	if mode == MODE_PUZZLE:
		var restart_btn := _button("Заново", func(): _restart_puzzle(true))
		_puz_restart_btn = restart_btn
		top_row.add_child(restart_btn)

		var hint_btn := _button("💡 Подсказка", _on_puzzle_hint_pressed)
		_puz_hint_btn = hint_btn
		top_row.add_child(hint_btn)

		var next_btn := _button("🎲 Следующая", func():
			var cur_diff: int = int(puzzle_data.get("difficulty", 1))
			var new_puz: Dictionary = Puzzles.generate_procedural_puzzle(cur_diff)
			load_puzzle(new_puz))
		_puz_next_btn = next_btn
		top_row.add_child(next_btn)

	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(vb)

	_status = Label.new()
	_status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_status.add_theme_font_size_override("font_size", 20)
	_status.add_theme_color_override("font_color", Color(0.95, 0.96, 0.98))
	vb.add_child(_status)

	_info = Label.new()
	_info.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_info.add_theme_font_size_override("font_size", 13)
	_info.add_theme_color_override("font_color", Color(0.58, 0.66, 0.78))
	vb.add_child(_info)

	_autofocus_btn = _button("Слежка: ВКЛ", _toggle_autofocus)
	top_row.add_child(_autofocus_btn)

	_present_btn = _button("К настоящему", func():
		auto_follow_present = true
		_update_autofocus_btn()
		view.focus_present(true))
	top_row.add_child(_present_btn)

	_minimap_toggle_btn = _button("🗺️ Карта", _toggle_minimap)
	top_row.add_child(_minimap_toggle_btn)

	# Плавающая интерактивная миникарта мультивселенной
	_minimap = TimelineMinimap.new()
	_minimap.view = view
	_minimap.board_selected.connect(func(l: int, t: int):
		auto_follow_present = false
		_update_autofocus_btn()
		view.focus_board(l, t, true)
		_play("click")
	)
	add_child(_minimap)

	_bottom_panel = PanelContainer.new()
	_bottom_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_bottom_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_bottom_panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(_bottom_panel)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	_bottom_panel.add_child(row)

	_btn_undo = _button("Отменить", _on_undo)
	_btn_undo.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	_btn_reset = _button("Сбросить", _on_reset)
	_btn_reset.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	if mode == MODE_AI or mode == MODE_LOCAL:
		_btn_hint = _button("💡 Совет", _on_hint_pressed)
		_btn_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	_btn_submit = _button("Завершить ход", _on_submit)
	_btn_submit.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var sub_sb := StyleBoxFlat.new()
	sub_sb.bg_color = Color(0.15, 0.39, 0.92, 0.98)
	sub_sb.border_color = Color(0.38, 0.65, 0.98, 0.95)
	sub_sb.set_border_width_all(1)
	sub_sb.set_corner_radius_all(8)
	sub_sb.content_margin_left = 12
	sub_sb.content_margin_right = 12
	_btn_submit.add_theme_stylebox_override("normal", sub_sb)
	var sub_hover: StyleBoxFlat = sub_sb.duplicate()
	sub_hover.bg_color = Color(0.22, 0.48, 0.98, 1.0)
	_btn_submit.add_theme_stylebox_override("hover", sub_hover)
	var sub_dis: StyleBoxFlat = sub_sb.duplicate()
	sub_dis.bg_color = Color(0.09, 0.12, 0.18, 0.55)
	sub_dis.border_color = Color(0.16, 0.22, 0.32, 0.4)
	_btn_submit.add_theme_stylebox_override("disabled", sub_dis)

	row.add_child(_btn_undo)
	row.add_child(_btn_reset)
	if _btn_hint != null:
		row.add_child(_btn_hint)
	row.add_child(_btn_submit)

	_toast = Label.new()
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_toast.position.y -= 110
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_font_size_override("font_size", 20)
	_toast.add_theme_color_override("font_color", Color(1, 0.9, 0.6))
	_toast.add_theme_color_override("font_outline_color", Color.BLACK)
	_toast.add_theme_constant_override("outline_size", 6)
	_toast.modulate.a = 0.0
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_toast)


func _on_viewport_resized() -> void:
	if _top_panel == null or _bottom_panel == null:
		return
	var vp_size := get_viewport_rect().size
	var insets := Settings.safe_insets(vp_size)
	var w: float = vp_size.x
	var h: float = vp_size.y
	var is_compact: bool = w < 840.0 or h < 560.0
	var is_phone_portrait: bool = w < 540.0 and h >= w
	var is_medium: bool = not is_compact and w < 1080.0

	var top_sb := _panel_style()
	top_sb.content_margin_left = int(maxf(8.0, insets.left + 6.0))
	top_sb.content_margin_right = int(maxf(8.0, insets.right + 6.0))
	top_sb.content_margin_top = int(maxf(6.0, insets.top + 4.0))
	top_sb.content_margin_bottom = 6
	_top_panel.add_theme_stylebox_override("panel", top_sb)

	var bot_sb := _panel_style()
	bot_sb.content_margin_left = int(maxf(8.0, insets.left + 6.0))
	bot_sb.content_margin_right = int(maxf(8.0, insets.right + 6.0))
	bot_sb.content_margin_bottom = int(maxf(8.0, insets.bottom + 6.0))
	bot_sb.content_margin_top = 6
	bot_sb.set_corner_radius_all(16)
	_bottom_panel.add_theme_stylebox_override("panel", bot_sb)

	if is_phone_portrait:
		_menu_btn.text = "Меню"
		_menu_btn.custom_minimum_size = Vector2(62, 42)
		_present_btn.text = "Наст."
		_present_btn.custom_minimum_size = Vector2(58, 42)
		_status.add_theme_font_size_override("font_size", 14)
		_info.add_theme_font_size_override("font_size", 11)
		_btn_undo.text = "Отмена"
		_btn_reset.text = "Сброс"
		if _btn_hint != null:
			_btn_hint.text = "💡 Совет"
			_btn_hint.custom_minimum_size = Vector2(0, 44)
			_btn_hint.add_theme_font_size_override("font_size", 14)
		_btn_submit.text = "Завершить"
		for b in [_btn_undo, _btn_reset, _btn_submit]:
			b.custom_minimum_size = Vector2(0, 44)
			b.add_theme_font_size_override("font_size", 14)
		if _puz_restart_btn != null:
			_puz_restart_btn.text = "Заново"
			_puz_restart_btn.custom_minimum_size = Vector2(64, 42)
		if _puz_hint_btn != null:
			_puz_hint_btn.text = "💡 Подск."
			_puz_hint_btn.custom_minimum_size = Vector2(72, 42)
		if _puz_next_btn != null:
			_puz_next_btn.text = "🎲 След."
			_puz_next_btn.custom_minimum_size = Vector2(66, 42)
	elif is_compact:
		_menu_btn.text = "Меню"
		_menu_btn.custom_minimum_size = Vector2(72, 44)
		_present_btn.text = "Настоящее"
		_present_btn.custom_minimum_size = Vector2(96, 44)
		_status.add_theme_font_size_override("font_size", 16)
		_info.add_theme_font_size_override("font_size", 12)
		_btn_undo.text = "Отмена"
		_btn_reset.text = "Сброс"
		if _btn_hint != null:
			_btn_hint.text = "💡 Совет"
			_btn_hint.custom_minimum_size = Vector2(0, 46)
			_btn_hint.add_theme_font_size_override("font_size", 14)
		_btn_submit.text = "Завершить ход"
		for b in [_btn_undo, _btn_reset, _btn_submit]:
			b.custom_minimum_size = Vector2(0, 46)
			b.add_theme_font_size_override("font_size", 14)
		if _puz_restart_btn != null:
			_puz_restart_btn.text = "Заново"
			_puz_restart_btn.custom_minimum_size = Vector2(76, 44)
		if _puz_hint_btn != null:
			_puz_hint_btn.text = "💡 Подсказка"
			_puz_hint_btn.custom_minimum_size = Vector2(98, 44)
		if _puz_next_btn != null:
			_puz_next_btn.text = "🎲 Новая"
			_puz_next_btn.custom_minimum_size = Vector2(80, 44)
	elif is_medium:
		_menu_btn.text = "Меню"
		_menu_btn.custom_minimum_size = Vector2(100, 46)
		_present_btn.text = "Настоящее"
		_present_btn.custom_minimum_size = Vector2(116, 46)
		_status.add_theme_font_size_override("font_size", 18)
		_info.add_theme_font_size_override("font_size", 13)
		_btn_undo.text = "Отмена"
		_btn_reset.text = "Сброс"
		if _btn_hint != null:
			_btn_hint.text = "💡 Совет"
			_btn_hint.custom_minimum_size = Vector2(0, 48)
			_btn_hint.add_theme_font_size_override("font_size", 15)
		_btn_submit.text = "Завершить ход"
		for b in [_btn_undo, _btn_reset, _btn_submit]:
			b.custom_minimum_size = Vector2(0, 48)
			b.add_theme_font_size_override("font_size", 15)
		if _puz_restart_btn != null:
			_puz_restart_btn.text = "Заново"
			_puz_restart_btn.custom_minimum_size = Vector2(96, 46)
		if _puz_hint_btn != null:
			_puz_hint_btn.text = "💡 Подсказка"
			_puz_hint_btn.custom_minimum_size = Vector2(114, 46)
		if _puz_next_btn != null:
			_puz_next_btn.text = "🎲 Следующая"
			_puz_next_btn.custom_minimum_size = Vector2(108, 46)
	else:
		_menu_btn.text = "Меню"
		_menu_btn.custom_minimum_size = Vector2(120, 48)
		_present_btn.text = "К настоящему"
		_present_btn.custom_minimum_size = Vector2(140, 48)
		_status.add_theme_font_size_override("font_size", 20)
		_info.add_theme_font_size_override("font_size", 14)
		_btn_undo.text = "Отменить"
		_btn_reset.text = "Сбросить"
		if _btn_hint != null:
			_btn_hint.text = "💡 Совет"
			_btn_hint.custom_minimum_size = Vector2(0, 48)
			_btn_hint.add_theme_font_size_override("font_size", 15)
		_btn_submit.text = "Завершить ход"
		for b in [_btn_undo, _btn_reset, _btn_submit]:
			b.custom_minimum_size = Vector2(0, 48)
			b.add_theme_font_size_override("font_size", 15)
		if _puz_restart_btn != null:
			_puz_restart_btn.text = "Заново"
			_puz_restart_btn.custom_minimum_size = Vector2(104, 48)
		if _puz_hint_btn != null:
			_puz_hint_btn.text = "💡 Подсказка"
			_puz_hint_btn.custom_minimum_size = Vector2(124, 48)
		if _puz_next_btn != null:
			_puz_next_btn.text = "🎲 Следующая"
			_puz_next_btn.custom_minimum_size = Vector2(116, 48)

	_update_autofocus_btn()
	if _opp_dc_banner != null and _top_panel != null:
		_opp_dc_banner.offset_top = _top_panel.size.y + 8
		_opp_dc_banner.offset_bottom = _opp_dc_banner.offset_top + 46

	# Размещение миникарты в правом нижнем углу над нижней панелью управления
	if _minimap != null:
		var mm_w: float = clampf(w * 0.28, 140.0, 240.0) if not is_phone_portrait else clampf(w * 0.44, 130.0, 180.0)
		var mm_h: float = clampf(h * 0.16, 75.0, 120.0) if not is_phone_portrait else 75.0
		var bot_margin: float = _bottom_panel.size.y + 12.0
		_minimap.size = Vector2(mm_w, mm_h)
		_minimap.position = Vector2(w - mm_w - maxf(12.0, insets.right + 8.0), h - bot_margin - mm_h)
		_minimap.queue_redraw()


func _panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.055, 0.075, 0.125, 0.96)
	sb.border_color = Color(0.14, 0.19, 0.28, 0.85)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb


func _banner_style(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb


func _button(text: String, cb: Callable = Callable()) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(120, 46)
	b.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.add_theme_font_size_override("font_size", 15)
	b.add_theme_color_override("font_color", Color(0.92, 0.95, 0.98))

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.13, 0.22, 0.94)
	sb.border_color = Color(0.18, 0.25, 0.38, 0.85)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	b.add_theme_stylebox_override("normal", sb)

	var hover: StyleBoxFlat = sb.duplicate()
	hover.bg_color = Color(0.13, 0.19, 0.32, 0.98)
	hover.border_color = Color(0.32, 0.52, 0.84, 0.90)
	b.add_theme_stylebox_override("hover", hover)

	var pressed: StyleBoxFlat = sb.duplicate()
	pressed.bg_color = Color(0.07, 0.10, 0.18, 1.0)
	pressed.border_color = Color(0.38, 0.65, 0.98, 0.95)
	b.add_theme_stylebox_override("pressed", pressed)

	var disabled: StyleBoxFlat = sb.duplicate()
	disabled.bg_color = Color(0.07, 0.09, 0.14, 0.50)
	disabled.border_color = Color(0.14, 0.18, 0.26, 0.35)
	b.add_theme_stylebox_override("disabled", disabled)

	if cb.is_valid():
		b.pressed.connect(cb)
	return b


func toast(text: String, col: Color = Color(1, 0.9, 0.6)) -> void:
	_toast.text = text
	_toast.add_theme_color_override("font_color", col)
	if _toast_tween:
		_toast_tween.kill()
	_toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(2.2)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.6)


func _color_name(c: int) -> String:
	return "Белые" if c == GameState.WHITE else "Чёрные"


func _is_human_turn() -> bool:
	if _game_over:
		return false
	if mode == MODE_LOCAL:
		return true
	return state.turn == human_color


func _after_state_change() -> void:
	var human: bool = _is_human_turn() and not _busy
	view.interactive = human
	view.threats = state.current_threats() if human else []
	var mand_left: int = state.mandatory_timelines().size() if human else 0
	var sub_ready: bool = human and state.submit_error() == ""

	if not _game_over:
		if mode == MODE_PUZZLE and not puzzle_data.is_empty():
			var chk_puz: String = "  ·  ⚠️ ШАХ!" if human and not view.threats.is_empty() else ""
			_status.text = "%s%s" % [str(puzzle_data.get("desc", "Найдите победный ход!")), chk_puz]
			_info.text = "🧩 %s · Награда: 💎 +%d" % [puzzle_data.get("title", ""), int(puzzle_data.get("reward", 50))]
		else:
			var who: String = _color_name(state.turn)
			if mode == MODE_AI:
				who += " (вы)" if state.turn == human_color else " (🤖 ИИ думает…)"
			elif mode == MODE_ONLINE:
				who += " (вы)" if state.turn == human_color else " (ход соперника)"
			var chk: String = "  — ⚠️ ШАХ!" if human and not view.threats.is_empty() else ""
			_status.text = "Ходят %s%s" % [who, chk]

			var mand_txt: String = ""
			if human:
				if sub_ready:
					mand_txt = " · ✓ Можно завершить ход"
				elif mand_left > 0:
					mand_txt = " · ⚡ Обяз. досок: %d" % mand_left
				elif not view.threats.is_empty():
					mand_txt = " · 🛡️ Защитите короля!"
			_info.text = "Ход %d · Линий: %d (%d актив.)%s" % [state.turn_number(), state.timelines.size(), _active_count(), mand_txt]

	_btn_undo.disabled = not human or not state.can_undo()
	_btn_reset.disabled = not human or not state.can_undo()
	if _btn_hint != null:
		_btn_hint.disabled = not human
	_btn_submit.disabled = not sub_ready
	_update_submit_button_style(sub_ready)
	view.refresh()
	if _minimap != null:
		_minimap.queue_redraw()


func _update_submit_button_style(ready: bool) -> void:
	if _btn_submit == null:
		return
	var sb := StyleBoxFlat.new()
	if ready:
		sb.bg_color = Color(0.11, 0.56, 0.40, 0.98)
		sb.border_color = Color(0.32, 0.92, 0.68, 0.98)
	else:
		sb.bg_color = Color(0.15, 0.39, 0.92, 0.98)
		sb.border_color = Color(0.38, 0.65, 0.98, 0.95)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	_btn_submit.add_theme_stylebox_override("normal", sb)
	var hov: StyleBoxFlat = sb.duplicate()
	hov.bg_color = sb.bg_color.lightened(0.12)
	_btn_submit.add_theme_stylebox_override("hover", hov)


func _active_count() -> int:
	var n: int = 0
	for l in state.timelines:
		if state.is_active(l):
			n += 1
	return n


func _piece_rule_hint(pt: int) -> String:
	match pt:
		GameState.PAWN: return "шаг вперёд / взятие по диагонали и сквозь время"
		GameState.KNIGHT: return "прыжок Г (2+1) в пространстве или времени"
		GameState.BISHOP: return "скользит по диагоналям (2 оси)"
		GameState.ROOK: return "скользит по прямым и сквозь время (1 ось)"
		GameState.QUEEN: return "скользит по любым осям (от 1 до 4 измерений)"
		GameState.KING: return "шаг на 1 клетку в любом измерении"
		GameState.UNICORN: return "5D-фигура: бьёт только по триагоналям (3 оси сразу)"
		GameState.DRAGON: return "5D-фигура: бьёт по тетрагоналям (4 оси сразу)"
		GameState.PRINCESS: return "5D-фигура: сочетает ходы Слона и Ладьи"
	return ""


# ---------------------------------------------------------------- ходы игрока

func _on_square_tapped(v: Vector4i) -> void:
	if not _is_human_turn() or _busy:
		return
	if _promo_popup != null:
		return
	if _chrono_wheel != null:
		_chrono_wheel.close()
		_chrono_wheel = null

	if view.targets.has(v):
		var m: Dictionary = {"f": view.selected, "t": v}
		var p: int = state.piece_at(view.selected)
		if _is_promotion(p, v):
			_ask_promotion(m, GameState.piece_color(p))
			return
		_do_move(m)
		return
	if v.x >= 0 and state.can_select(v):
		view.selected = v
		view.targets = []
		var temporal_cnt: int = 0
		var all_moves: Array = state.moves_from(v)
		for m in all_moves:
			var tv: Vector4i = m["t"]
			view.targets.append(tv)
			if tv.z != v.z or tv.w != v.w:
				temporal_cnt += 1
		var p_sel: int = state.piece_at(v)
		var pt: int = GameState.piece_type(p_sel)
		var p_name: String = str(GameState.NAMES_RU.get(pt, "Фигура")).capitalize()
		var sq_name: String = "%s%d" % [String.chr(97 + v.x), v.y + 1]
		var time_tag: String = (" (из них %d в прошлое/иные линии)" % temporal_cnt) if temporal_cnt > 0 else ""
		_info.text = "🔹 %s [%s] — %s · Ходов: %d%s" % [p_name, sq_name, _piece_rule_hint(pt), view.targets.size(), time_tag]
		_play("click")
		view.refresh()

		# Если фигура может прыгать сквозь время/пространство — открываем радиальное Колесо Времени!
		if temporal_cnt > 0 and view.targets.size() >= 2:
			_open_chrono_wheel(v, view.targets)
	else:
		_clear_selection()
		_after_state_change()


func _open_chrono_wheel(origin: Vector4i, targets_list: Array) -> void:
	if _chrono_wheel != null:
		_chrono_wheel.close()
		_chrono_wheel = null

	var wheel := ChronoWheel.new()
	wheel.setup_for_piece(view, origin, targets_list)
	wheel.board_preview_requested.connect(func(l: int, t: int):
		auto_follow_present = false
		_update_autofocus_btn()
		view.focus_board(l, t, true)
		_play("click")
	)
	wheel.target_selected.connect(func(target_sq: Vector4i):
		_on_square_tapped(target_sq)
	)
	wheel.closed.connect(func():
		_chrono_wheel = null
	)
	_chrono_wheel = wheel
	add_child(_chrono_wheel)


func _clear_selection() -> void:
	if _chrono_wheel != null:
		_chrono_wheel.close()
		_chrono_wheel = null
	view.selected = Vector4i(-1, -1, 0, 0)
	view.targets = []
	view.refresh()


func _on_hint_pressed() -> void:
	if not _is_human_turn() or _busy:
		return
	var h: Dictionary = ChessAI.get_hint(state)
	if h.is_empty() or not h.has("move"):
		toast("💡 Нет доступных ходов на текущих досках", Color(1.0, 0.75, 0.4))
		return
	var m: Dictionary = h["move"]
	var reason: String = str(h.get("reason", "Рекомендуемый ход"))
	var f: Vector4i = m["f"]
	var t: Vector4i = m["t"]
	view.hint_move = {"f": f, "t": t}
	view.selected = f
	view.targets = []
	for mv in state.moves_from(f):
		view.targets.append(mv["t"])
	view.focus_board(f.w, f.z, true)
	view.refresh()
	_play("click")
	var f_sq := "%s%d" % [String.chr(97 + f.x), f.y + 1]
	var t_sq := "%s%d" % [String.chr(97 + t.x), t.y + 1]
	var t_tag := (" (в T%d)" % (floori(t.z / 2.0) + 1)) if (f.z != t.z or f.w != t.w) else ""
	toast("💡 Совет: %s → %s%s · %s" % [f_sq, t_sq, t_tag, reason], Color(0.35, 1.0, 0.78))


func _on_puzzle_hint_pressed() -> void:
	if puzzle_data.is_empty():
		return
	var hint_txt: String = str(puzzle_data.get("hint", "Ищите уязвимость короля соперника!"))
	var tgt: Dictionary = puzzle_data.get("target_move", {})
	if not tgt.is_empty():
		var fx: int = int(tgt.get("fx", 0))
		var fy: int = int(tgt.get("fy", 0))
		var tx: int = int(tgt.get("tx", 0))
		var ty: int = int(tgt.get("ty", 0))
		var fz: int = int(tgt.get("fz", state.end_t(0)))
		var tz: int = int(tgt.get("tz", fz))
		var fv := Vector4i(fx, fy, fz, 0)
		var tv := Vector4i(tx, ty, tz, 0)
		view.hint_move = {"f": fv, "t": tv}
		if state.can_select(fv):
			view.selected = fv
			view.targets = []
			for mv in state.moves_from(fv):
				view.targets.append(mv["t"])
		view.focus_board(0, fz, true)
		view.refresh()
	_play("click")
	toast("💡 Подсказка: " + hint_txt, Color(0.35, 0.98, 0.78))


## Пешка `p`, приходящая на клетку `to`, достигает последней горизонтали.
func _is_promotion(p: int, to: Vector4i) -> bool:
	if GameState.piece_type(p) != GameState.PAWN:
		return false
	var last_rank: int = state.h - 1 if GameState.piece_color(p) == GameState.WHITE else 0
	return to.y == last_rank


func _do_move(m: Dictionary) -> void:
	view.hint_move = {}
	_clear_selection()
	_busy = true
	await _animate_and_apply(m)
	_busy = false
	_after_state_change()
	# В режиме задач автоматически проверяем решение, когда ход на обязательной доске завершён!
	if mode == MODE_PUZZLE and state.submit_error() == "":
		await get_tree().create_timer(0.18).timeout
		if is_inside_tree() and not _game_over and state.submit_error() == "":
			_on_submit()


## Анимирует перемещение со старой доски на созданную новую доску и проигрывает подходящий звук.
## Общая часть для ходов игрока, ИИ и соперника по сети.
func _animate_and_apply(m: Dictionary) -> void:
	var f: Vector4i = m["f"]
	var to: Vector4i = m["t"]
	var piece: int = state.piece_at(f)
	var capture: bool = state.piece_at(to) != GameState.EMPTY
	var is_temporal: bool = (f.z != to.z or f.w != to.w)
	var prev_tl: int = state.timelines.size()

	if is_temporal:
		_play("travel")

	# 1. Применяем ход к состоянию игры, создавая новую доску в timeline
	state.apply_move(m)

	# 2. Вычисляем точную клетку назначения на созданной доске
	var last_rec: Dictionary = state.turn_moves.back() if not state.turn_moves.is_empty() else m
	var dest_l: int = int(last_rec.get("nl", to.w if is_temporal else f.w))
	var dest_t: int = (to.z + 1) if is_temporal else (f.z + 1)
	var dest_v := Vector4i(to.x, to.y, dest_t, dest_l)

	# 3. Анимируем полёт фигуры с доски отправления f на созданную доску dest_v
	await view.animate_move(f, dest_v, piece, is_temporal, capture)

	# 4. Звуковой отклик приземления и сочные эффекты
	if state.timelines.size() > prev_tl:
		_play("branch")
		var target_c: Vector2 = view.square_rect(dest_v).get_center()
		view.emit_sparks(target_c, Color(0.85, 0.45, 1.0), 38, 250.0, true)
		view.add_floating_text("🌀 НОВАЯ ВЕТВЬ ВРЕМЕНИ!", target_c, Color(0.9, 0.5, 1.0), 22)
		_trigger_rift_shockwave(dest_v)
	elif is_temporal:
		_trigger_rift_shockwave(dest_v)
	elif capture:
		_play("capture")
	else:
		_play("move")


func _setup_rift_shader() -> void:
	_rift_rect = ColorRect.new()
	_rift_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rift_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rift_material = ShaderMaterial.new()
	var shader_res := load("res://shaders/chrono_rift.gdshader")
	if shader_res != null:
		_rift_material.shader = shader_res
		_rift_material.set_shader_parameter("rift_progress", 1.0)
		_rift_material.set_shader_parameter("distortion_strength", 0.05)
		_rift_material.set_shader_parameter("chromatic_aberration", 0.025)
		_rift_rect.material = _rift_material
		_rift_rect.visible = false
	add_child(_rift_rect)


func _trigger_rift_shockwave(target_square: Vector4i) -> void:
	if _rift_material == null or _rift_rect == null:
		return
	var vp_size := get_viewport_rect().size
	if vp_size.x <= 0.0 or vp_size.y <= 0.0:
		return
	var world_center: Vector2 = view.square_rect(target_square).get_center()
	var screen_pos: Vector2 = world_center * view.zoom + view.offset
	var norm_center := Vector2(screen_pos.x / vp_size.x, screen_pos.y / vp_size.y)

	_rift_material.set_shader_parameter("rift_center", norm_center)
	_rift_material.set_shader_parameter("rift_progress", 0.0)
	_rift_rect.visible = true

	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(val: float):
		if _rift_material != null:
			_rift_material.set_shader_parameter("rift_progress", val)
	, 0.0, 1.0, 0.48)
	tw.finished.connect(func():
		if _rift_rect != null:
			_rift_rect.visible = false
	)


## Затемнённый модальный слой с панелью по центру экрана.
## Возвращает [overlay, vbox]: overlay удаляется для закрытия, во vbox добавляется содержимое.
func _make_modal(separation: int, dim_alpha: float) -> Array:
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.04, 0.08, dim_alpha)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(bg)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style())
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	overlay.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", separation)
	panel.add_child(vb)
	return [overlay, vb]


func _modal_title(vb: VBoxContainer, text: String, font_size: int) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", font_size)
	vb.add_child(lbl)


func _ask_promotion(m: Dictionary, color: int) -> void:
	_pending_promo = m
	var modal: Array = _make_modal(10, 0.72)
	_promo_popup = modal[0]
	var vb: VBoxContainer = modal[1]
	_modal_title(vb, "Превращение пешки", 18)

	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 6)
	vb.add_child(hb)

	var bit: int = 0 if color == GameState.WHITE else GameState.BLACK_BIT
	var vp_w: float = get_viewport_rect().size.x
	var btn_sz: float = clampf((vp_w - 64.0) / 7.0, 42.0, 68.0)
	for t in [GameState.QUEEN, GameState.PRINCESS, GameState.ROOK, GameState.BISHOP, GameState.KNIGHT, GameState.UNICORN, GameState.DRAGON]:
		var b := PieceButton.new()
		b.piece = t | bit
		b.custom_minimum_size = Vector2(btn_sz, btn_sz)
		b.pressed.connect(_on_promo_chosen.bind(t))
		hb.add_child(b)


func _on_promo_chosen(t: int) -> void:
	_pending_promo["promo"] = t
	_promo_popup.queue_free()
	_promo_popup = null
	_do_move(_pending_promo)


func _on_undo() -> void:
	if state.undo_move():
		_play("undo")
		_clear_selection()
		_after_state_change()


func _on_reset() -> void:
	if state.can_undo():
		_play("undo")
	state.reset_turn()
	_clear_selection()
	_after_state_change()


func _on_submit() -> void:
	if not _is_human_turn() or _busy:
		return
	var err: String = state.submit_error()
	if err != "":
		_play("error")
		toast(err)
		if state.in_check():
			if state.game_status(300) == "checkmate":
				_finish("checkmate")
				return
			_focus_on_threat()
		return
	var moves: Array = state.turn_moves.duplicate()
	state.submit()
	_play("submit")
	if mode == MODE_ONLINE and net != null:
		net.send_turn(moves)

	if mode == MODE_PUZZLE:
		var solved: bool = Puzzles.check_puzzle_success(puzzle_data, moves, state)
		if solved:
			_on_puzzle_solved()
		else:
			_on_puzzle_failed()
		return

	await _on_turn_passed()


func _on_puzzle_solved() -> void:
	_game_over = true
	_play("win")
	var mate_details: Dictionary = state.get_checkmate_details()
	view.mate_info = mate_details
	view.interactive = false
	if mate_details.get("has_mate", false):
		view.focus_board(int(mate_details.get("board_l", 0)), int(mate_details.get("board_t", 0)), true)
	var rew: int = int(puzzle_data.get("reward", 50))
	Profile.mark_puzzle_solved(str(puzzle_data.get("id", "")), rew)

	var msg: String = "Великолепный ход! Вы решили задачу «%s».\n\n💎 Награда: +%d Хроно-кристаллов!" % [str(puzzle_data.get("title", "")), rew]
	if mate_details.get("has_mate", false):
		var k_sq: String = str(mate_details.get("king_sq", ""))
		var a_sq: String = str(mate_details.get("attacker_sq", ""))
		msg += "\n📍 Король под матом на поле: %s" % k_sq
		if a_sq != "":
			msg += "\n⚔ Решающая атака с поля: %s" % a_sq

	var modal: Array = _make_modal(12, 0.72)
	var overlay: Control = modal[0]
	var vb: VBoxContainer = modal[1]
	_modal_title(vb, "🎉 Головоломка решена!", 22)

	var body := Label.new()
	body.text = msg
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(300, 0)
	body.add_theme_font_size_override("font_size", 15)
	body.add_theme_color_override("font_color", Color(0.88, 0.94, 1.0))
	vb.add_child(body)

	var next_btn := _button("🎲 Следующая задача", func():
		overlay.queue_free()
		var cur_diff: int = int(puzzle_data.get("difficulty", 1))
		var new_puz: Dictionary = Puzzles.generate_procedural_puzzle(cur_diff)
		load_puzzle(new_puz))
	var inspect_btn := _button("👁 Осмотреть доску", func():
		_play("click")
		overlay.queue_free())
	var menu_btn := _button("🏠 В меню", func():
		overlay.queue_free()
		exit_requested.emit())

	for b in [next_btn, inspect_btn, menu_btn]:
		b.custom_minimum_size = Vector2(260, 46)
		vb.add_child(b)


func load_puzzle(p_puzzle: Dictionary) -> void:
	puzzle_data = p_puzzle
	_restart_puzzle(false)
	toast("🎲 Загружена задача: «%s»" % str(puzzle_data.get("title", "")), Color(0.4, 0.9, 1.0))


func _restart_puzzle(show_toast: bool = true) -> void:
	if mode != MODE_PUZZLE or puzzle_data.is_empty():
		return
	_game_over = false
	_busy = false
	var pw: int = int(puzzle_data.get("w", 8))
	var ph: int = int(puzzle_data.get("h", 8))
	var p_rows: Array = puzzle_data.get("rows", [])
	var p_tz: bool = bool(puzzle_data.get("turn_zero", false))
	state.setup(pw, ph, p_rows, p_tz)
	view.state = state
	view.selected = Vector4i(-1, -1, 0, 0)
	view.targets = []
	view.hint_move = {}
	view.mate_info = {}
	view.threats = []
	view.interactive = true
	_after_state_change()
	view.focus_present(false)
	_info.text = "🧩 %s · Награда: 💎 +%d" % [puzzle_data.get("title", ""), int(puzzle_data.get("reward", 50))]
	_status.text = str(puzzle_data.get("desc", "Найдите победный ход!"))
	if show_toast:
		toast("🔄 Позиция сброшена", Color(0.4, 0.85, 1.0))
		if sfx != null:
			sfx.play("click")


func _on_puzzle_failed() -> void:
	var reason: String = Puzzles.explain_puzzle_failure(state)
	_play("error")
	_restart_puzzle(false)
	toast(reason + " (позиция возвращена)", Color(1.0, 0.42, 0.42))


func _focus_on_threat() -> void:
	var threats: Array = state.current_threats()
	if not threats.is_empty():
		var target: Vector4i = threats[0][1]
		view.focus_board(target.w, target.z)


func _toggle_autofocus() -> void:
	auto_follow_present = not auto_follow_present
	_update_autofocus_btn()
	if auto_follow_present:
		view.focus_present(true)


func _toggle_minimap() -> void:
	if _minimap != null:
		_minimap.visible = not _minimap.visible
		_minimap_toggle_btn.text = "🗺️ Карта" if _minimap.visible else "🗺️ Карта (скрыта)"
		_play("click")


func _update_autofocus_btn() -> void:
	if _autofocus_btn == null:
		return
	var w: float = get_viewport_rect().size.x
	if w < 720.0:
		_autofocus_btn.text = "Авто" if auto_follow_present else "Ручн."
		_autofocus_btn.custom_minimum_size = Vector2(54, 42)
	elif w < 960.0:
		_autofocus_btn.text = "Авто: ВКЛ" if auto_follow_present else "Авто: ВЫКЛ"
		_autofocus_btn.custom_minimum_size = Vector2(100, 46)
	else:
		_autofocus_btn.text = "Слежка: ВКЛ" if auto_follow_present else "Слежка: ВЫКЛ"
		_autofocus_btn.custom_minimum_size = Vector2(130, 48)


## Общая обработка после того, как любая сторона (игрок, ИИ или соперник по сети)
## завершила ход: проверка конца партии, звук шаха, обновление HUD и камеры,
## затем передача хода ИИ, если сейчас его очередь.
func _on_turn_passed() -> void:
	_clear_selection()
	_busy = true
	_after_state_change()
	# Даём интерфейсу отрисоваться перед поиском ходов.
	await get_tree().process_frame
	if not is_inside_tree():
		return
	var is_ai_next: bool = (mode == MODE_AI and state.turn != human_color)
	if not is_ai_next:
		var status: String = state.game_status(280)
		if status != "ongoing":
			_busy = false
			_finish(status)
			return
	_busy = false
	if state.in_check():
		_play("check")
	_after_state_change()
	if auto_follow_present:
		view.focus_present(true)
	_maybe_ai_turn()


func _process(delta: float) -> void:
	if _opp_dc_banner != null and _opp_dc_banner.visible and _opp_dc_seconds_left > 0.0:
		_opp_dc_seconds_left = max(0.0, _opp_dc_seconds_left - delta)
		if _opp_dc_label != null:
			if _opp_dc_seconds_left > 0.0:
				_opp_dc_label.text = "⏳ Соперник временно отключился. Ожидание возвращения (%dс)..." % int(ceil(_opp_dc_seconds_left))
			else:
				_opp_dc_label.text = "⏳ Время на переподключение соперника истекло..."


func _finish(status: String) -> void:
	var branches: int = state.timelines.size() - 1
	var text: String
	if status == "checkmate":
		var winner: int = 1 - state.turn
		var won: bool = (mode == MODE_LOCAL) or (winner == human_color)
		var delta: int = 0
		if mode != MODE_LOCAL:
			delta = Profile.record_game(won, false, mode, branches)

		var mate_details: Dictionary = state.get_checkmate_details()
		view.mate_info = mate_details
		view.interactive = false
		view.shake(14.0)
		var v_center: Vector2 = view.screen_to_world(view.size * 0.5)
		if mate_details.get("has_mate", false):
			var ml: int = int(mate_details.get("board_l", 0))
			var mt: int = int(mate_details.get("board_t", 0))
			var kx: int = int(mate_details.get("king_x", 4))
			var ky: int = int(mate_details.get("king_y", 4))
			v_center = view.square_rect(Vector4i(ml, mt, kx, ky)).get_center()
			view.focus_board(ml, mt, true)
		view.emit_sparks(v_center, Color(1.0, 0.85, 0.25), 55, 270.0, true)
		view.add_floating_text("👑 МАТ В МУЛЬТИВСЕЛЕННОЙ!", v_center, Color(1.0, 0.9, 0.25), 26)

		text = "♔ МАТ! Победили %s\n" % _color_name(winner).to_lower()
		if mate_details.get("has_mate", false):
			var l_val: int = int(mate_details.get("board_l", 0))
			var l_str: String = ("L%+d" % l_val) if l_val != 0 else "L0"
			var t_num: int = int(mate_details.get("board_t", 0))
			var t_str: String = "T%d%s" % [floori(t_num / 2.0) + 1, "" if posmod(t_num, 2) == 0 else "b"]
			var k_sq: String = str(mate_details.get("king_sq", ""))
			var a_sq: String = str(mate_details.get("attacker_sq", ""))
			text += "\n📍 Где поставлен мат: Линия %s (ход %s)" % [l_str, t_str]
			text += "\n👑 Король под матом на поле: %s" % k_sq
			if a_sq != "":
				text += "\n⚔ Решающий удар с поля: %s" % a_sq
		if delta != 0:
			text += "\n\nРейтинг: %d (%+d)" % [Profile.rating, delta]
	else:
		if mode != MODE_LOCAL:
			Profile.record_game(false, true, mode, branches)
		text = "Пат — ничья"
	_end_with(text)


func _end_with(text: String) -> void:
	_game_over = true
	if net != null:
		net.clear_active_session()
	if _opp_dc_banner != null:
		_opp_dc_banner.visible = false
	if _self_reconnect_modal != null:
		_self_reconnect_modal.queue_free()
		_self_reconnect_modal = null

	_play("win")
	_after_state_change()
	_status.text = text.split("\n")[0]

	var modal: Array = _make_modal(12, 0.72)
	var overlay: Control = modal[0]
	var vb: VBoxContainer = modal[1]
	_modal_title(vb, "🏁 Партия окончена", 22)

	var body := Label.new()
	body.text = text
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(300, 0)
	body.add_theme_font_size_override("font_size", 15)
	body.add_theme_color_override("font_color", Color(0.88, 0.94, 1.0))
	vb.add_child(body)

	if mode == MODE_AI or mode == MODE_LOCAL:
		var rematch_btn := _button("🔄 Сыграть снова", func():
			overlay.queue_free()
			_restart_match())
		rematch_btn.custom_minimum_size = Vector2(260, 46)
		vb.add_child(rematch_btn)

	var inspect_btn := _button("👁 Осмотреть доску", func():
		_play("click")
		overlay.queue_free())
	inspect_btn.custom_minimum_size = Vector2(260, 46)
	vb.add_child(inspect_btn)

	var menu_btn := _button("🏠 В меню", func():
		overlay.queue_free()
		exit_requested.emit())
	menu_btn.custom_minimum_size = Vector2(260, 46)
	vb.add_child(menu_btn)


func _restart_match() -> void:
	_game_over = false
	_busy = false
	state = Variants.create(variant_id)
	view.state = state
	view.selected = Vector4i(-1, -1, 0, 0)
	view.targets = []
	view.hint_move = {}
	view.mate_info = {}
	view.threats = []
	view.interactive = true
	view.focus_present(true)
	_after_state_change()
	_maybe_ai_turn()


# ---------------------------------------------------------------- ИИ и сеть

func _maybe_ai_turn() -> void:
	if mode != MODE_AI or _game_over or state.turn == human_color:
		return
	_busy = true
	_after_state_change()
	# Короткая пауза, чтобы пользователь успел увидеть смену хода и статус
	await get_tree().create_timer(0.06).timeout
	if not is_inside_tree() or _game_over:
		_busy = false
		return

	var state_copy: GameState = state.clone()
	var moves: Array = []
	if _ai_thread != null and _ai_thread.is_started():
		_ai_thread.wait_to_finish()
	_ai_thread = Thread.new()
	var err: int = _ai_thread.start(func() -> Array:
		return ai.choose_turn(state_copy)
	)
	if err == OK:
		while _ai_thread.is_alive():
			await get_tree().process_frame
			if not is_inside_tree():
				_ai_thread.wait_to_finish()
				return
		moves = _ai_thread.wait_to_finish()
	else:
		moves = ai.choose_turn(state_copy)

	if not is_inside_tree() or _game_over:
		_busy = false
		return
	if moves.is_empty():
		_busy = false
		_finish("checkmate" if state.in_check() else "stalemate")
		return
	await _play_remote_moves(moves)


func _exit_tree() -> void:
	if _ai_thread != null and _ai_thread.is_started():
		_ai_thread.wait_to_finish()


## Проигрывает чужой ход (ИИ или соперника по сети) с анимацией и завершает его.
func _play_remote_moves(moves: Array) -> void:
	_busy = true
	_after_state_change()
	for m in moves:
		await get_tree().create_timer(0.08).timeout
		if not is_inside_tree() or _game_over:
			_busy = false
			return
		await _animate_and_apply(m)
		view.refresh()

	await get_tree().create_timer(0.1).timeout
	if not is_inside_tree() or _game_over:
		_busy = false
		return

	var sub_err: String = state.submit_error()
	if sub_err != "":
		# Не сбрасываем ход, чтобы не рассинхронизировать онлайн-партию (соперник уже сделал submit).
		push_warning("Remote turn validation warning: %s. Submitting to keep multiplayer in sync." % sub_err)

	state.submit()
	_play("submit")
	await _on_turn_passed()


func _on_remote_turn(moves: Array) -> void:
	if _game_over or state.turn == human_color:
		return
	await _play_remote_moves(moves)


func _on_remote_resign() -> void:
	if net != null:
		net.clear_active_session()
	var delta: int = Profile.record_game(true, false, mode, state.timelines.size() - 1)
	_end_with("Соперник сдался. Вы победили!\nРейтинг: %d (%+d)" % [Profile.rating, delta])


func _on_net_disconnected(reason: String) -> void:
	if not _game_over:
		_end_with(reason)


func _on_opponent_disconnected_temp(timeout: int) -> void:
	if _opp_dc_banner != null and _opp_dc_label != null:
		_opp_dc_seconds_left = float(timeout)
		_opp_dc_banner.add_theme_stylebox_override("panel", _banner_style(Color(0.25, 0.14, 0.04, 0.95), Color(1.0, 0.7, 0.2, 0.9)))
		_opp_dc_label.text = "⏳ Соперник временно отключился. Ожидание возвращения (%dс)..." % timeout
		_opp_dc_banner.visible = true


func _on_opponent_reconnected() -> void:
	if _opp_dc_banner != null and _opp_dc_label != null:
		_opp_dc_seconds_left = 0.0
		_opp_dc_banner.add_theme_stylebox_override("panel", _banner_style(Color(0.06, 0.22, 0.12, 0.95), Color(0.2, 0.9, 0.4, 0.9)))
		_opp_dc_label.text = "✔ Соперник успешно вернулся в игру! Продолжаем партию."
		_opp_dc_banner.visible = true
		_play("click")
		get_tree().create_timer(3.0).timeout.connect(func():
			if _opp_dc_banner != null and _opp_dc_seconds_left <= 0.0:
				_opp_dc_banner.visible = false)


func _on_self_reconnecting(attempt: int, _max_attempts: int, seconds_left: float) -> void:
	if _game_over:
		return
	if _self_reconnect_modal == null:
		var modal: Array = _make_modal(12, 0.8)
		_self_reconnect_modal = modal[0]
		var vb: VBoxContainer = modal[1]

		_modal_title(vb, "📡 Связь с сервером потеряна", 20)

		_self_reconnect_label = Label.new()
		_self_reconnect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_self_reconnect_label.add_theme_font_size_override("font_size", 14)
		_self_reconnect_label.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
		vb.add_child(_self_reconnect_label)

		var give_up_btn := _button("🚪 Сдаться и выйти", func():
			if _self_reconnect_modal != null:
				_self_reconnect_modal.queue_free()
				_self_reconnect_modal = null
			if net != null:
				net.send_resign()
			_end_with("Вы сдались."))
		give_up_btn.custom_minimum_size = Vector2(220, 48)
		vb.add_child(give_up_btn)

	if _self_reconnect_label != null:
		_self_reconnect_label.text = "Восстановление подключения к матчу...\nПопытка %d · Осталось %d сек" % [attempt, int(ceil(seconds_left))]


func _on_reconnected_to_match(missed_turns: Array, _history: Array) -> void:
	if _self_reconnect_modal != null:
		_self_reconnect_modal.queue_free()
		_self_reconnect_modal = null

	toast("✔ Связь с сервером восстановлена! Вы снова в игре.", Color(0.3, 1.0, 0.5))
	_play("click")

	# Применяем пропущенные ходы
	for m_turn in missed_turns:
		await _play_remote_moves(m_turn)


func _on_reconnect_failed(reason: String) -> void:
	if _self_reconnect_modal != null:
		_self_reconnect_modal.queue_free()
		_self_reconnect_modal = null
	if not _game_over:
		_end_with("Не удалось восстановить связь с матчем:\n%s" % reason)


func _on_menu() -> void:
	var modal: Array = _make_modal(12, 0.78)
	var overlay: Control = modal[0]
	var vb: VBoxContainer = modal[1]
	_modal_title(vb, "Пауза и настройки", 20)

	if mode == MODE_ONLINE:
		var warn := Label.new()
		warn.text = "Выход из онлайн-партии засчитает поражение."
		warn.add_theme_color_override("font_color", Color(0.95, 0.45, 0.45))
		warn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		warn.add_theme_font_size_override("font_size", 13)
		vb.add_child(warn)

	var scale_btn := _button(Settings.get_scale_label())
	scale_btn.pressed.connect(func():
		scale_btn.text = Settings.cycle_ui_scale(get_window())
		_play("click"))

	var sfx_btn := _button(Settings.sound_label(sfx == null or sfx.enabled))
	sfx_btn.pressed.connect(func():
		if sfx != null:
			sfx_btn.text = Settings.sound_label(sfx.toggle())
			_play("move"))

	var exit_btn := _button("Выйти в меню", func():
		overlay.queue_free()
		if mode == MODE_ONLINE and net != null and not _game_over:
			net.send_resign()
		elif net != null:
			net.clear_active_session()
		exit_requested.emit())

	var resume_btn := _button("Продолжить партию", func():
		_play("click")
		overlay.queue_free())

	for b in [scale_btn, sfx_btn, exit_btn, resume_btn]:
		b.custom_minimum_size = Vector2(250, 46)
		vb.add_child(b)


func _play(id: String) -> void:
	if sfx != null:
		sfx.play(id)