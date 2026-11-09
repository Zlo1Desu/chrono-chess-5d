class_name Net
extends Node
## Сетевой стек ChronoChess:
## 1. Онлайн-мультиплеер через мастер-сервер (WebSocket) с комнатами по 4-значным кодам.
## 2. Локальный мультиплеер (LAN ENet + UDP Discovery) без интернета.

signal connected
signal disconnected(reason: String)
signal game_started(variant_id: String, my_color: int)
signal turn_received(moves: Array)
signal resign_received
signal server_list_updated(servers: Array)
signal room_created(code: String)
signal status_message(msg: String)

# Сигналы мульти-шахмат
signal multi_game_started(sub_mode: String, my_color: int, player_slots: Array, is_d20: bool)
signal multi_turn_received(move: Dictionary)
signal room_lobby_updated(data: Dictionary)
signal player_resigned(color: int, player_name: String)

# Сигналы переподключения (Reconnection System)
signal opponent_disconnected_temporary(timeout: int)
signal opponent_reconnected
signal reconnecting(attempt: int, max_attempts: int, seconds_left: float)
signal reconnected_to_match(missed_turns: Array, turn_history: Array)
signal reconnect_failed(reason: String)

const DEFAULT_SERVER_URL := "ws://207.127.89.191:7575"
const PORT := 7575
const BEACON_PORT := 7576
const CODE_CHARS := "23456789ABCDEFGHJKLMNPQRSTUVWXYZ"
const MAX_RECONNECT_TIME: float = 60.0
const RECONNECT_INTERVAL: float = 2.0

# Сигналы синхронизации скинов игроков
signal player_skin_updated(color: int, skin_id: String)

var is_host: bool = false
var active: bool = false
var is_online_mode: bool = true
var room_code: String = ""
var room_name: String = "Комната 5D"
var server_url: String = DEFAULT_SERVER_URL
var opponent_skin: String = "classic"
var player_skins: Dictionary = {}

# Тип игры и вместимость лобби
var game_type: String = "5d" # "5d" или "multi"
var max_players: int = 2
var room_slots: Array = []

# Данные сессии для восстановления связи
var session_token: String = ""
var session_room_code: String = ""
var session_variant: String = "standard"
var session_my_color: int = GameState.WHITE
var session_opponent_name: String = ""
var turns_played_count: int = 0
var is_reconnecting: bool = false
var _reconnect_timer: float = 0.0
var _reconnect_elapsed: float = 0.0
var _reconnect_attempts: int = 0

# WebSocket (Онлайн)
var _ws: WebSocketPeer
var _ws_ping_timer: float = 0.0
var _ws_poll_rooms_timer: float = 0.0
var _pending_create: Dictionary = {}
var _pending_join_code: String = ""

# ENet (LAN)
var _pending_variant: String = "standard"
var _pending_host_color: int = GameState.WHITE
var _broadcaster: PacketPeerUDP
var _listener: PacketPeerUDP
var _broadcast_timer: float = 0.0
var _discovery_active: bool = false
var _found_servers: Dictionary = {}


func _ready() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	_load_config()


func _process(delta: float) -> void:
	if is_online_mode and _ws != null:
		_process_online(delta)
	else:
		_process_lan(delta)


# ==============================================================================
# ОНЛАЙН МУЛЬТИПЛЕЕР (WebSocket через Мастер-сервер)
# ==============================================================================

func connect_online(p_url: String = "") -> void:
	if p_url != "":
		server_url = p_url
		_save_config()
	close()
	is_online_mode = true
	_ws = WebSocketPeer.new()
	var err := _ws.connect_to_url(server_url)
	if err != OK:
		status_message.emit("Не удалось подключиться к серверу (%d)" % err)
		return
	status_message.emit("Подключение к мастер-серверу…")


func online_create_room(variant_id: String, host_color: int, p_room_name: String = "") -> void:
	game_type = "5d"
	max_players = 2
	_pending_create = {
		"game_type": "5d",
		"variant": variant_id,
		"color": host_color,
		"name": p_room_name if p_room_name != "" else "Комната 5D"
	}
	is_host = true
	if _ws == null or _ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
		connect_online()
	else:
		_send_create_room()


func online_create_multi_room(p_sub_mode: String, host_color: int, p_room_name: String = "", p_is_d20: bool = false) -> void:
	game_type = "d20_multi" if p_is_d20 else "multi"
	max_players = 3 if p_sub_mode == "1v1v1" else 4
	_pending_create = {
		"game_type": game_type,
		"variant": p_sub_mode,
		"color": host_color,
		"name": p_room_name if p_room_name != "" else (("🎲 D20 " if p_is_d20 else "Мульти-шахматы ") + p_sub_mode)
	}
	is_host = true
	if _ws == null or _ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
		connect_online()
	else:
		_send_create_room()


func online_start_room_game() -> void:
	if _ws != null and _ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_ws_send({"type": "start_room_game"})


func send_multi_turn(move: Dictionary) -> void:
	turns_played_count += 1
	if is_online_mode:
		_ws_send({"type": "multi_turn", "move": move})
	else:
		_rpc_multi_turn.rpc(move)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_multi_turn(move: Dictionary) -> void:
	multi_turn_received.emit(move)


func online_join_room(code: String) -> void:
	var clean := code.strip_edges().to_upper().replace("-", "").replace(" ", "")
	_pending_join_code = clean
	is_host = false
	if _ws == null or _ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
		connect_online()
	else:
		_send_join_room()


func online_request_rooms() -> void:
	if _ws != null and _ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_ws_send({"type": "list_rooms"})


func online_leave_room() -> void:
	if is_online_mode and _ws != null and _ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_ws_send({"type": "leave_room"})
	room_code = ""
	active = false


func _send_create_room() -> void:
	if _pending_create.is_empty():
		return
	_ws_send({
		"type": "create_room",
		"name": _pending_create.get("name", "Комната " + Profile.player_name),
		"game_type": _pending_create.get("game_type", "5d"),
		"variant": _pending_create.get("variant", "standard"),
		"color": int(_pending_create.get("color", 0)),
		"player_name": Profile.player_name,
		"skin": Profile.active_skin
	})
	_pending_create = {}


func _send_join_room() -> void:
	if _pending_join_code == "":
		return
	_ws_send({
		"type": "join_room",
		"code": _pending_join_code,
		"player_name": Profile.player_name,
		"skin": Profile.active_skin
	})
	_pending_join_code = ""


func reconnect_to_match(code: String, token: String, last_turn: int = 0) -> void:
	is_online_mode = true
	session_room_code = code
	session_token = token
	turns_played_count = last_turn
	is_reconnecting = true
	_reconnect_timer = 0.0
	_reconnect_elapsed = 0.0
	_reconnect_attempts = 1
	status_message.emit("Переподключение к матчу %s…" % code)
	if _ws == null or _ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
		_ws = WebSocketPeer.new()
		_ws.connect_to_url(server_url)
	else:
		_send_reconnect()


func _send_reconnect() -> void:
	if session_token == "" or session_room_code == "":
		return
	_ws_send({
		"type": "reconnect",
		"code": session_room_code,
		"token": session_token,
		"last_turn_index": turns_played_count,
		"skin": Profile.active_skin
	})


func clear_active_session() -> void:
	session_token = ""
	session_room_code = ""
	session_variant = "standard"
	session_my_color = GameState.WHITE
	session_opponent_name = ""
	turns_played_count = 0
	is_reconnecting = false
	_reconnect_elapsed = 0.0
	_reconnect_timer = 0.0
	_pending_join_code = ""
	Profile.clear_active_match()


func _process_online(delta: float) -> void:
	if _ws == null:
		if is_reconnecting and session_token != "":
			_reconnect_elapsed += delta
			_reconnect_timer += delta
			var seconds_left: float = max(0.0, MAX_RECONNECT_TIME - _reconnect_elapsed)
			reconnecting.emit(_reconnect_attempts, int(MAX_RECONNECT_TIME / RECONNECT_INTERVAL), seconds_left)
			if _reconnect_elapsed >= MAX_RECONNECT_TIME:
				is_reconnecting = false
				clear_active_session()
				reconnect_failed.emit("Время ожидания переподключения истекло")
				disconnected.emit("Не удалось восстановить связь с сервером (таймаут 60 сек)")
				return
			if _reconnect_timer >= RECONNECT_INTERVAL:
				_reconnect_timer = 0.0
				_reconnect_attempts += 1
				_ws = WebSocketPeer.new()
				_ws.connect_to_url(server_url)
		return

	_ws.poll()
	var state := _ws.get_ready_state()

	if state == WebSocketPeer.STATE_OPEN:
		# Пинг каждые 12 секунд для предотвращения таймаутов NAT
		_ws_ping_timer += delta
		if _ws_ping_timer >= 12.0:
			_ws_ping_timer = 0.0
			_ws_send({"type": "ping"})

		# Авто-опрос списка комнат в лобби
		if not active and not is_reconnecting and room_code == "":
			_ws_poll_rooms_timer += delta
			if _ws_poll_rooms_timer >= 2.5:
				_ws_poll_rooms_timer = 0.0
				online_request_rooms()

		# Если выполняется переподключение
		if is_reconnecting:
			_reconnect_elapsed += delta
			var seconds_left: float = max(0.0, MAX_RECONNECT_TIME - _reconnect_elapsed)
			reconnecting.emit(_reconnect_attempts, int(MAX_RECONNECT_TIME / RECONNECT_INTERVAL), seconds_left)
			if _reconnect_elapsed >= MAX_RECONNECT_TIME:
				is_reconnecting = false
				clear_active_session()
				reconnect_failed.emit("Время ожидания переподключения истекло")
				disconnected.emit("Не удалось восстановить связь с сервером")
				return
			if _pending_join_code != "__reconnect_sent__":
				_pending_join_code = "__reconnect_sent__"
				_send_reconnect()

		# Если было отложенное действие создания/входа
		if not _pending_create.is_empty():
			_send_create_room()
		if _pending_join_code != "" and _pending_join_code != "__reconnect_sent__":
			_send_join_room()

		# Чтение входящих пакетов
		while _ws.get_available_packet_count() > 0:
			var pkt: PackedByteArray = _ws.get_packet()
			var text: String = pkt.get_string_from_utf8()
			_handle_online_message(text)

	elif state == WebSocketPeer.STATE_CLOSED:
		var code: int = _ws.get_close_code()
		var reason: String = _ws.get_close_reason()
		_ws = null

		if session_token != "" and (active or is_reconnecting):
			# Разрыв произошел во время активного матча — активируем переподключение!
			is_reconnecting = true
			_pending_join_code = ""
			_reconnect_timer = 0.0
			var seconds_left: float = max(0.0, MAX_RECONNECT_TIME - _reconnect_elapsed)
			reconnecting.emit(_reconnect_attempts, int(MAX_RECONNECT_TIME / RECONNECT_INTERVAL), seconds_left)
		else:
			if active:
				disconnected.emit("Связь с сервером разорвана: %s (код %d)" % [reason, code])
			else:
				status_message.emit("Нет связи с сервером")
			active = false


func _handle_online_message(text: String) -> void:
	var data: Variant = JSON.parse_string(text)
	if not (data is Dictionary):
		return

	var msg_type: String = data.get("type", "")

	match msg_type:
		"room_created":
			room_code = data.get("code", "")
			room_name = data.get("name", "")
			game_type = data.get("game_type", "5d")
			max_players = int(data.get("max_players", 2))
			session_token = data.get("token", "")
			room_created.emit(room_code)
			status_message.emit("Комната создана! Код: %s" % room_code)

		"joined_room":
			room_code = data.get("code", "")
			game_type = data.get("game_type", "5d")
			max_players = int(data.get("max_players", 2))
			session_token = data.get("token", "")
			session_my_color = int(data.get("color", 0))
			status_message.emit("Вход в комнату %s успешен!" % room_code)

		"room_lobby_update":
			game_type = data.get("game_type", game_type)
			max_players = int(data.get("max_players", max_players))
			room_slots = data.get("players", [])
			for pl in room_slots:
				if pl is Dictionary:
					var p_col: int = int(pl.get("color", 0))
					var p_sk: String = str(pl.get("skin", "classic"))
					player_skins[p_col] = p_sk
			room_lobby_updated.emit(data)

		"game_start":
			active = true
			is_reconnecting = false
			_pending_join_code = ""
			room_code = data.get("code", room_code)
			session_room_code = room_code
			session_token = data.get("token", session_token)
			session_variant = data.get("variant", "standard")
			session_my_color = int(data.get("my_color", GameState.WHITE))
			session_opponent_name = data.get("opponent_name", "Соперник")
			opponent_skin = str(data.get("opponent_skin", "classic"))
			player_skins = {
				session_my_color: Profile.active_skin,
				(1 - session_my_color): opponent_skin
			}
			send_skin_sync(Profile.active_skin)
			game_type = "5d"
			turns_played_count = 0
			Profile.set_active_match(session_room_code, session_token, session_variant, session_my_color, session_opponent_name)
			connected.emit()
			game_started.emit(session_variant, session_my_color)

		"multi_game_start":
			active = true
			is_reconnecting = false
			_pending_join_code = ""
			room_code = data.get("code", room_code)
			session_room_code = room_code
			session_token = data.get("token", session_token)
			game_type = data.get("game_type", "multi")
			var is_d20: bool = bool(data.get("is_d20", false)) or (game_type == "d20_multi")
			var sub_mode: String = data.get("sub_mode", "1v1v1")
			session_variant = sub_mode
			session_my_color = int(data.get("my_color", 0))
			room_slots = data.get("players", [])
			player_skins.clear()
			for pl in room_slots:
				if pl is Dictionary:
					player_skins[int(pl.get("color", 0))] = str(pl.get("skin", "classic"))
			player_skins[session_my_color] = Profile.active_skin
			send_skin_sync(Profile.active_skin)
			turns_played_count = 0
			Profile.set_active_match(session_room_code, session_token, session_variant, session_my_color, ("🎲 D20 " if is_d20 else "") + "Мульти-шахматы " + sub_mode)
			connected.emit()
			multi_game_started.emit(sub_mode, session_my_color, room_slots, is_d20)

		"skin_sync":
			var s_col: int = int(data.get("color", -1))
			var s_skin: String = str(data.get("skin", "classic"))
			if s_col >= 0:
				player_skins[s_col] = s_skin
				if s_col != session_my_color:
					opponent_skin = s_skin
				player_skin_updated.emit(s_col, s_skin)

		"multi_turn":
			turns_played_count += 1
			var move: Dictionary = data.get("move", {})
			multi_turn_received.emit(move)

		"player_resigned":
			var r_color := int(data.get("color", -1))
			var r_name := str(data.get("name", ""))
			player_resigned.emit(r_color, r_name)

		"room_list":
			var rooms_data: Array = data.get("rooms", [])
			server_list_updated.emit(rooms_data)

		"turn":
			turns_played_count += 1
			var raw_moves: Array = data.get("moves", [])
			var moves: Array = []
			for a in raw_moves:
				moves.append(GameState.move_from_array(a))
			turn_received.emit(moves)

		"reconnected":
			is_reconnecting = false
			active = true
			_pending_join_code = ""
			room_code = data.get("code", session_room_code)
			session_room_code = room_code
			session_variant = data.get("variant", session_variant)
			session_my_color = int(data.get("my_color", session_my_color))
			session_opponent_name = data.get("opponent_name", session_opponent_name)
			var total_turns: int = int(data.get("total_turns", turns_played_count))
			turns_played_count = total_turns
			Profile.set_active_match(session_room_code, session_token, session_variant, session_my_color, session_opponent_name)

			var missed_raw: Array = data.get("missed_turns", [])
			var missed_turns: Array = []
			for t_arr in missed_raw:
				var m_list: Array = []
				for a in t_arr:
					m_list.append(GameState.move_from_array(a))
				missed_turns.append(m_list)

			var hist_raw: Array = data.get("turn_history", [])
			var history_turns: Array = []
			for t_arr in hist_raw:
				var m_list: Array = []
				for a in t_arr:
					m_list.append(GameState.move_from_array(a))
				history_turns.append(m_list)

			reconnected_to_match.emit(missed_turns, history_turns)

		"reconnect_failed":
			is_reconnecting = false
			clear_active_session()
			var msg: String = data.get("message", "Матч завершён или время вышло")
			reconnect_failed.emit(msg)
			disconnected.emit(msg)

		"opponent_disconnected_temporary":
			var tout: int = int(data.get("timeout", 60))
			opponent_disconnected_temporary.emit(tout)

		"opponent_reconnected":
			opponent_reconnected.emit()

		"resign":
			resign_received.emit()

		"opponent_disconnected":
			clear_active_session()
			active = false
			is_reconnecting = false
			disconnected.emit(data.get("message", "Соперник отключился"))

		"error":
			status_message.emit("Ошибка: " + data.get("message", ""))

		"pong":
			pass


func _ws_send(data: Dictionary) -> void:
	if _ws != null and _ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_ws.send_text(JSON.stringify(data))


# ==============================================================================
# ЛОКАЛЬНАЯ СЕТЬ (LAN ENet + UDP Beacon)
# ==============================================================================

func host(variant_id: String, host_color: int, p_room_name: String = "") -> String:
	close()
	is_online_mode = false
	var peer := ENetMultiplayerPeer.new()
	var max_clients: int = 3 if (game_type in ["multi", "d20_multi"] or variant_id in ["1v1v1", "2v2", "1v1v1v1"]) else 1
	var err: int = peer.create_server(PORT, max_clients)
	if err != OK:
		return "Не удалось открыть порт %d (ошибка %d)" % [PORT, err]

	multiplayer.multiplayer_peer = peer
	is_host = true
	active = true
	_pending_variant = variant_id
	_pending_host_color = host_color

	room_code = ip_to_code(primary_address())
	room_name = p_room_name if p_room_name != "" else ("Комната " + room_code.substr(0, 3))

	_connect_enet_signals()
	_start_beacon_broadcasting()
	return ""


func join_by_code(code_or_ip: String) -> String:
	is_online_mode = false
	var ip: String = code_to_ip(code_or_ip)
	return join(ip)


func join(address: String) -> String:
	close()
	is_online_mode = false
	var peer := ENetMultiplayerPeer.new()
	var target_ip: String = address.strip_edges()
	var err: int = peer.create_client(target_ip, PORT)
	if err != OK:
		return "Не удалось подключиться к %s:%d (ошибка %d)" % [target_ip, PORT, err]

	multiplayer.multiplayer_peer = peer
	is_host = false
	active = true
	_connect_enet_signals()
	return ""


func _process_lan(delta: float) -> void:
	if is_host and active and _broadcaster != null:
		_broadcast_timer += delta
		if _broadcast_timer >= 1.0:
			_broadcast_timer = 0.0
			_send_beacon()

	if _discovery_active and _listener != null:
		_poll_beacons()


# ==============================================================================
# ОБЩИЙ ИНТЕРФЕЙС ИГРЫ (ОДИНАКОВ ДЛЯ ОНЛАЙНА И LAN)
# ==============================================================================

func send_turn(moves: Array) -> void:
	turns_played_count += 1
	var data: Array = []
	for m in moves:
		data.append(GameState.move_to_array(m))

	if is_online_mode:
		_ws_send({"type": "turn", "moves": data})
	else:
		_rpc_turn.rpc(data)


func send_resign() -> void:
	if is_online_mode:
		_ws_send({"type": "resign"})
	else:
		_rpc_resign.rpc()
	clear_active_session()


func send_skin_sync(skin_id: String = "") -> void:
	var s_id: String = skin_id if skin_id != "" else Profile.active_skin
	if is_online_mode:
		if _ws != null and _ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
			_ws_send({
				"type": "skin_sync",
				"color": session_my_color,
				"skin": s_id
			})
	else:
		if multiplayer.multiplayer_peer != null and not (multiplayer.multiplayer_peer is OfflineMultiplayerPeer):
			_rpc_skin_sync.rpc(session_my_color, s_id)


func close() -> void:
	if _ws != null:
		_ws.close()
		_ws = null
	_stop_beacon_broadcasting()
	stop_lan_discovery()
	if multiplayer.multiplayer_peer != null and not (multiplayer.multiplayer_peer is OfflineMultiplayerPeer):
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	active = false
	is_host = false
	room_code = ""
	clear_active_session()


# ==============================================================================
# УТИЛИТЫ И КОНФИГУРАЦИЯ
# ==============================================================================

func _load_config() -> void:
	var f := ConfigFile.new()
	if f.load("user://network.cfg") == OK:
		server_url = f.get_value("net", "server_url", DEFAULT_SERVER_URL)


func _save_config() -> void:
	var f := ConfigFile.new()
	f.set_value("net", "server_url", server_url)
	f.save("user://network.cfg")


static func ip_to_code(ip: String) -> String:
	var parts := ip.split(".")
	if parts.size() != 4:
		return ip.to_upper()
	var n: int = (int(parts[0]) << 24) | (int(parts[1]) << 16) | (int(parts[2]) << 8) | int(parts[3])
	var un: int = n & 0xFFFFFFFF
	var res := ""
	while un > 0:
		var rem: int = un % 32
		res = CODE_CHARS[rem] + res
		un = un / 32
	while res.length() < 7:
		res = "2" + res
	return res.substr(0, 3) + "-" + res.substr(3)


static func code_to_ip(code: String) -> String:
	var clean: String = code.replace("-", "").replace(" ", "").to_upper().strip_edges()
	if clean.contains("."):
		return clean
	var un: int = 0
	for ch in clean:
		var idx: int = CODE_CHARS.find(ch)
		if idx >= 0:
			un = un * 32 + idx
		else:
			return clean
	var a: int = (un >> 24) & 0xFF
	var b: int = (un >> 16) & 0xFF
	var c: int = (un >> 8) & 0xFF
	var d: int = un & 0xFF
	return "%d.%d.%d.%d" % [a, b, c, d]


static func local_addresses() -> Array:
	var res: Array = []
	for a in IP.get_local_addresses():
		var s: String = a
		if s.count(".") == 3 and not s.begins_with("127.") and not s.begins_with("169.254."):
			res.append(s)
	return res


## Основной локальный IPv4-адрес устройства (или 127.0.0.1, если сети нет).
static func primary_address() -> String:
	var ips: Array = local_addresses()
	return ips[0] if not ips.is_empty() else "127.0.0.1"


## Хост из URL мастер-сервера (для подписи в интерфейсе).
func server_host() -> String:
	var u: String = server_url.replace("wss://", "").replace("ws://", "")
	return u.get_slice("/", 0).get_slice(":", 0)


func _connect_enet_signals() -> void:
	var mp: MultiplayerAPI = multiplayer
	if not mp.peer_connected.is_connected(_on_peer_connected):
		mp.peer_connected.connect(_on_peer_connected)
		mp.peer_disconnected.connect(_on_peer_disconnected)
		mp.connected_to_server.connect(_on_connected_to_server)
		mp.connection_failed.connect(_on_connection_failed)
		mp.server_disconnected.connect(_on_server_disconnected)


func _on_peer_connected(id: int) -> void:
	if is_host:
		connected.emit()
		player_skins[_pending_host_color] = Profile.active_skin
		var is_multi: bool = (game_type in ["multi", "d20_multi"]) or (_pending_variant in ["1v1v1", "2v2", "1v1v1v1"])
		if is_multi:
			var max_p: int = 3 if _pending_variant == "1v1v1" else 4
			var guest_col: int = 1 if _pending_host_color == 0 else 0
			var slots_data: Array = [
				{"name": Profile.player_name, "color": _pending_host_color, "is_bot": false, "skin": Profile.active_skin},
				{"name": "Соперник (LAN)", "color": guest_col, "is_bot": false, "skin": "classic"}
			]
			for c in range(max_p):
				if c != _pending_host_color and c != guest_col:
					slots_data.append({"name": "Бот %d (ИИ)" % (c + 1), "color": c, "is_bot": true, "skin": "classic"})
			_rpc_multi_start.rpc_id(id, _pending_variant, guest_col, slots_data, game_type == "d20_multi")
			multi_game_started.emit(_pending_variant, _pending_host_color, slots_data, game_type == "d20_multi")
		else:
			_rpc_start.rpc_id(id, _pending_variant, 1 - _pending_host_color, Profile.active_skin)
			game_started.emit(_pending_variant, _pending_host_color)


func _on_peer_disconnected(_id: int) -> void:
	if active:
		disconnected.emit("Соперник отключился")


func _on_connected_to_server() -> void:
	connected.emit()


func _on_connection_failed() -> void:
	active = false
	disconnected.emit("Не удалось подключиться к серверу")


func _on_server_disconnected() -> void:
	active = false
	disconnected.emit("Соединение с сервером потеряно")


@rpc("authority", "call_remote", "reliable")
func _rpc_multi_start(sub_mode: String, my_color: int, player_slots: Array, is_d20: bool) -> void:
	session_variant = sub_mode
	session_my_color = my_color
	room_slots = player_slots
	player_skins.clear()
	for pl in room_slots:
		if pl is Dictionary:
			player_skins[int(pl.get("color", 0))] = str(pl.get("skin", "classic"))
	player_skins[my_color] = Profile.active_skin
	_rpc_client_skin.rpc_id(1, my_color, Profile.active_skin)
	multi_game_started.emit(sub_mode, my_color, player_slots, is_d20)


@rpc("authority", "call_remote", "reliable")
func _rpc_start(variant_id: String, my_color: int, host_skin: String = "classic") -> void:
	opponent_skin = host_skin
	player_skins = {
		my_color: Profile.active_skin,
		1 - my_color: host_skin
	}
	_rpc_client_skin.rpc_id(1, my_color, Profile.active_skin)
	game_started.emit(variant_id, my_color)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_client_skin(color: int, client_skin: String) -> void:
	opponent_skin = client_skin
	player_skins[color] = client_skin
	player_skin_updated.emit(color, client_skin)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_skin_sync(color: int, skin_id: String) -> void:
	player_skins[color] = skin_id
	if color != session_my_color:
		opponent_skin = skin_id
	player_skin_updated.emit(color, skin_id)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_turn(data: Array) -> void:
	var moves: Array = []
	for a in data:
		moves.append(GameState.move_from_array(a))
	turn_received.emit(moves)


@rpc("any_peer", "call_remote", "reliable")
func _rpc_resign() -> void:
	resign_received.emit()


func _start_beacon_broadcasting() -> void:
	_broadcaster = PacketPeerUDP.new()
	_broadcaster.set_broadcast_enabled(true)
	_broadcast_timer = 0.9


func _stop_beacon_broadcasting() -> void:
	if _broadcaster != null:
		_broadcaster.close()
		_broadcaster = null


func _send_beacon() -> void:
	if _broadcaster == null:
		return
	var payload: Dictionary = {
		"tag": "CHRONO5D",
		"name": room_name,
		"variant": _pending_variant,
		"code": room_code,
		"ip": primary_address(),
		"port": PORT,
	}
	var msg: String = JSON.stringify(payload)
	_broadcaster.set_dest_address("255.255.255.255", BEACON_PORT)
	_broadcaster.put_packet(msg.to_utf8_buffer())


func start_lan_discovery() -> void:
	stop_lan_discovery()
	_found_servers.clear()
	_listener = PacketPeerUDP.new()
	var err: int = _listener.bind(BEACON_PORT)
	_discovery_active = (err == OK)


func stop_lan_discovery() -> void:
	_discovery_active = false
	if _listener != null:
		_listener.close()
		_listener = null


func _poll_beacons() -> void:
	if _listener == null:
		return
	var changed := false
	while _listener.get_available_packet_count() > 0:
		var pkt: PackedByteArray = _listener.get_packet()
		var text: String = pkt.get_string_from_utf8()
		var data: Variant = JSON.parse_string(text)
		if data is Dictionary and data.get("tag") == "CHRONO5D":
			var key: String = "%s:%s" % [data.get("ip", ""), data.get("code", "")]
			data["time"] = Time.get_ticks_msec()
			_found_servers[key] = data
			changed = true

	var now: int = Time.get_ticks_msec()
	var expired := []
	for k in _found_servers:
		if now - int(_found_servers[k].get("time", 0)) > 3500:
			expired.append(k)
	for k in expired:
		_found_servers.erase(k)
		changed = true

	if changed:
		server_list_updated.emit(_found_servers.values())
