extends Control
## Корневой контроллер приложения: управляет звуками, сетью и переключением
## между главным меню и экраном партии.

var sfx: Sfx
var net: Net
var _current: Control


func _ready() -> void:
	Settings.load_from_disk()
	Settings.apply_scale(get_window())
	Profile.load_from_disk()

	sfx = Sfx.new()
	sfx.name = "Sfx"
	sfx.enabled = Settings.sound_enabled
	add_child(sfx)

	net = Net.new()
	net.name = "Net"
	add_child(net)

	show_menu()


func show_menu() -> void:
	if _current != null:
		_current.queue_free()
		_current = null
	net.close()
	if sfx != null:
		sfx.start_ambient()
	var menu := MenuScreen.new()
	menu.setup(net, sfx)
	menu.start_game.connect(_on_start_game)
	menu.start_multi_game.connect(_on_start_multi_game)
	menu.start_puzzle_game.connect(_on_start_puzzle_game)
	add_child(menu)
	_current = menu


func _on_start_game(variant_id: String, mode: String, color: int, ai_level: int, initial_turns: Array = []) -> void:
	if sfx != null:
		sfx.stop_ambient()
	if _current != null:
		_current.queue_free()
		_current = null
	var game := GameScreen.new()
	game.setup(variant_id, mode, color, ai_level, net, sfx, initial_turns)
	game.exit_requested.connect(show_menu)
	add_child(game)
	_current = game


func _on_start_multi_game(sub_mode: String, is_pass_and_play: bool, color: int, ai_level: int, p_net: Net = null, p_slots: Array = [], p_is_d20: bool = false) -> void:
	if sfx != null:
		sfx.stop_ambient()
	if _current != null:
		_current.queue_free()
		_current = null
	var multi_game := MultiGameScreen.new()
	multi_game.setup(sub_mode, is_pass_and_play, color, ai_level, sfx, p_net, p_slots, p_is_d20)
	multi_game.exit_requested.connect(show_menu)
	add_child(multi_game)
	_current = multi_game


func _on_start_puzzle_game(puzzle_data: Dictionary) -> void:
	if sfx != null:
		sfx.stop_ambient()
	if _current != null:
		_current.queue_free()
		_current = null
	var game := GameScreen.new()
	game.setup("standard", GameScreen.MODE_PUZZLE, GameState.WHITE, ChessAI.NORMAL, net, sfx, [], puzzle_data)
	game.exit_requested.connect(show_menu)
	add_child(game)
	_current = game
