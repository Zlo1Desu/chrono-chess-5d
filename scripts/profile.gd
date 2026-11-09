class_name Profile
extends RefCounted
## Профиль игрока: статистика партий, рейтинг ELO, валюта (Хроно-кристаллы),
## коллекция скинов, ежедневные задания и сохранение прогресса в user://profile.cfg.

const PATH := "user://profile.cfg"

static var player_name: String = "Хроно-путешественник"
static var avatar_piece: int = GameState.KING
static var avatar_is_black: bool = false
static var rating: int = 1200
static var games_played: int = 0
static var wins: int = 0
static var losses: int = 0
static var draws: int = 0
static var win_streak: int = 0
static var best_streak: int = 0
static var timelines_created: int = 0
static var temporal_jumps: int = 0
static var ai_wins: int = 0
static var online_wins: int = 0

# Внутриигровая валюта и скины
static var crystals: int = 250
static var owned_skins: Array = ["classic"]
static var active_skin: String = "classic"

# Головоломки
static var solved_puzzles: Array = []

# Ежедневные задания
static var daily_quests_date: String = ""
static var daily_quests: Array = []

# Сохраненная сессия активного матча для возможности переподключения
static var active_match_code: String = ""
static var active_match_token: String = ""
static var active_match_variant: String = "standard"
static var active_match_color: int = 0
static var active_match_opponent: String = ""
static var active_match_time: int = 0


static func get_avatar_code() -> int:
	return avatar_piece | (GameState.BLACK_BIT if avatar_is_black else 0)


static func get_title() -> String:
	if rating >= 2000:
		return "⚡ Повелитель измерений (Гроссмейстер 5D)"
	elif rating >= 1750:
		return "🌌 Хранитель реальностей"
	elif rating >= 1500:
		return "🔮 Исследователь мультивселенной"
	elif rating >= 1350:
		return "⏳ Путешественник во времени"
	elif rating >= 1200:
		return "♟ Адепт квантовых шахмат"
	else:
		return "🌱 Хроно-новичок"


static func get_winrate() -> float:
	if games_played <= 0:
		return 0.0
	return (float(wins) / float(games_played)) * 100.0


static func set_nickname(new_name: String) -> void:
	var clean := new_name.strip_edges()
	if clean != "":
		player_name = clean.substr(0, 24)
		save_to_disk()


static func set_avatar(piece_type: int, is_black: bool) -> void:
	avatar_piece = piece_type
	avatar_is_black = is_black
	save_to_disk()


## Фиксирует результат завершённой партии и обновляет рейтинг и серии побед.
static func record_game(won: bool, is_draw: bool, mode: String, branches: int = 0, jumps: int = 0) -> int:
	games_played += 1
	timelines_created += maxi(0, branches)
	temporal_jumps += maxi(0, jumps)

	add_quest_progress("play_5d", 1)
	if branches > 0:
		add_quest_progress("branch", branches)

	var delta := 0
	if is_draw:
		draws += 1
		win_streak = 0
		delta = 0
	elif won:
		wins += 1
		win_streak += 1
		best_streak = maxi(best_streak, win_streak)
		add_quest_progress("win", 1)
		add_crystals(20) # Награда кристаллами за победу
		if mode == GameScreen.MODE_ONLINE:
			online_wins += 1
			delta = 25
		elif mode == GameScreen.MODE_AI:
			ai_wins += 1
			delta = 20
		else:
			delta = 10
	else:
		losses += 1
		win_streak = 0
		if mode == GameScreen.MODE_ONLINE:
			delta = -18
		elif mode == GameScreen.MODE_AI:
			delta = -14
		else:
			delta = -5

	rating = maxi(400, rating + delta)
	save_to_disk()
	return delta


# ---------------------------------------------------------------- Валюта и Магазин скинов

static func add_crystals(amount: int) -> void:
	crystals = maxi(0, crystals + amount)
	save_to_disk()


static func spend_crystals(amount: int) -> bool:
	if crystals >= amount:
		crystals -= amount
		save_to_disk()
		return true
	return false


static func buy_skin(skin_id: String) -> bool:
	if owned_skins.has(skin_id):
		equip_skin(skin_id)
		return true
	var skin_data := Skins.get_skin(skin_id)
	var price: int = int(skin_data.get("price", 0))
	if spend_crystals(price):
		if not owned_skins.has(skin_id):
			owned_skins.append(skin_id)
		equip_skin(skin_id)
		return true
	return false


static func equip_skin(skin_id: String) -> void:
	if owned_skins.has(skin_id):
		active_skin = skin_id
		save_to_disk()


# ---------------------------------------------------------------- Головоломки

static func is_puzzle_solved(id: String) -> bool:
	return solved_puzzles.has(id)


static func mark_puzzle_solved(id: String, reward: int) -> void:
	if not solved_puzzles.has(id):
		solved_puzzles.append(id)
		add_crystals(reward)
		add_quest_progress("puzzles", 1)
		save_to_disk()


# ---------------------------------------------------------------- Ежедневные задания

static func check_daily_quests() -> void:
	var today: String = Time.get_date_string_from_system()
	if daily_quests_date != today or daily_quests.is_empty():
		daily_quests_date = today
		daily_quests = [
			{
				"id": "q_puzzle",
				"type": "puzzles",
				"title": "🧠 Тактический гений",
				"desc": "Решите 2 шахматные головоломки",
				"current": 0,
				"target": 2,
				"reward": 60,
				"claimed": false
			},
			{
				"id": "q_play_5d",
				"type": "play_5d",
				"title": "⏳ Хроно-испытание",
				"desc": "Сыграйте 1 партию в 5D шахматы",
				"current": 0,
				"target": 1,
				"reward": 50,
				"claimed": false
			},
			{
				"id": "q_win",
				"type": "win",
				"title": "👑 Вкус победы",
				"desc": "Одержите 1 победу над ИИ или в сети",
				"current": 0,
				"target": 1,
				"reward": 75,
				"claimed": false
			}
		]
		save_to_disk()


static func add_quest_progress(quest_type: String, amount: int = 1) -> void:
	check_daily_quests()
	var changed := false
	for q in daily_quests:
		if q.get("type", "") == quest_type and not bool(q.get("claimed", false)):
			var cur: int = int(q.get("current", 0))
			var tgt: int = int(q.get("target", 1))
			if cur < tgt:
				q["current"] = mini(tgt, cur + amount)
				changed = true
	if changed:
		save_to_disk()


static func claim_quest_reward(quest_id: String) -> int:
	for q in daily_quests:
		if str(q.get("id", "")) == quest_id:
			if not bool(q.get("claimed", false)) and int(q.get("current", 0)) >= int(q.get("target", 1)):
				var rew: int = int(q.get("reward", 50))
				q["claimed"] = true
				add_crystals(rew)
				save_to_disk()
				return rew
	return 0


# ---------------------------------------------------------------- Сброс и сохранение

static func reset_stats() -> void:
	rating = 1200
	games_played = 0
	wins = 0
	losses = 0
	draws = 0
	win_streak = 0
	best_streak = 0
	timelines_created = 0
	temporal_jumps = 0
	ai_wins = 0
	online_wins = 0
	save_to_disk()


static func set_active_match(code: String, token: String, variant: String, color: int, opponent: String) -> void:
	active_match_code = code
	active_match_token = token
	active_match_variant = variant
	active_match_color = color
	active_match_opponent = opponent
	active_match_time = int(Time.get_unix_time_from_system())
	save_to_disk()


static func clear_active_match() -> void:
	active_match_code = ""
	active_match_token = ""
	active_match_variant = "standard"
	active_match_color = 0
	active_match_opponent = ""
	active_match_time = 0
	save_to_disk()


static func has_active_match() -> bool:
	if active_match_code == "" or active_match_token == "":
		return false
	var now := int(Time.get_unix_time_from_system())
	if now - active_match_time > 75:
		return false
	return true


static func load_from_disk() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		player_name = str(cfg.get_value("player", "name", "Хроно-путешественник"))
		avatar_piece = int(cfg.get_value("player", "avatar_piece", GameState.KING))
		avatar_is_black = bool(cfg.get_value("player", "avatar_black", false))
		rating = int(cfg.get_value("stats", "rating", 1200))
		games_played = int(cfg.get_value("stats", "games_played", 0))
		wins = int(cfg.get_value("stats", "wins", 0))
		losses = int(cfg.get_value("stats", "losses", 0))
		draws = int(cfg.get_value("stats", "draws", 0))
		win_streak = int(cfg.get_value("stats", "win_streak", 0))
		best_streak = int(cfg.get_value("stats", "best_streak", 0))
		timelines_created = int(cfg.get_value("stats", "timelines_created", 0))
		temporal_jumps = int(cfg.get_value("stats", "temporal_jumps", 0))
		ai_wins = int(cfg.get_value("stats", "ai_wins", 0))
		online_wins = int(cfg.get_value("stats", "online_wins", 0))

		crystals = int(cfg.get_value("economy", "crystals", 250))
		owned_skins = Array(cfg.get_value("economy", "owned_skins", ["classic"]))
		active_skin = str(cfg.get_value("economy", "active_skin", "classic"))

		solved_puzzles = Array(cfg.get_value("puzzles", "solved", []))

		daily_quests_date = str(cfg.get_value("quests", "date", ""))
		daily_quests = Array(cfg.get_value("quests", "list", []))

		active_match_code = str(cfg.get_value("active_match", "code", ""))
		active_match_token = str(cfg.get_value("active_match", "token", ""))
		active_match_variant = str(cfg.get_value("active_match", "variant", "standard"))
		active_match_color = int(cfg.get_value("active_match", "color", 0))
		active_match_opponent = str(cfg.get_value("active_match", "opponent", ""))
		active_match_time = int(cfg.get_value("active_match", "time", 0))

	check_daily_quests()


static func save_to_disk() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("player", "name", player_name)
	cfg.set_value("player", "avatar_piece", avatar_piece)
	cfg.set_value("player", "avatar_black", avatar_is_black)
	cfg.set_value("stats", "rating", rating)
	cfg.set_value("stats", "games_played", games_played)
	cfg.set_value("stats", "wins", wins)
	cfg.set_value("stats", "losses", losses)
	cfg.set_value("stats", "draws", draws)
	cfg.set_value("stats", "win_streak", win_streak)
	cfg.set_value("stats", "best_streak", best_streak)
	cfg.set_value("stats", "timelines_created", timelines_created)
	cfg.set_value("stats", "temporal_jumps", temporal_jumps)
	cfg.set_value("stats", "ai_wins", ai_wins)
	cfg.set_value("stats", "online_wins", online_wins)

	cfg.set_value("economy", "crystals", crystals)
	cfg.set_value("economy", "owned_skins", owned_skins)
	cfg.set_value("economy", "active_skin", active_skin)

	cfg.set_value("puzzles", "solved", solved_puzzles)

	cfg.set_value("quests", "date", daily_quests_date)
	cfg.set_value("quests", "list", daily_quests)

	cfg.set_value("active_match", "code", active_match_code)
	cfg.set_value("active_match", "token", active_match_token)
	cfg.set_value("active_match", "variant", active_match_variant)
	cfg.set_value("active_match", "color", active_match_color)
	cfg.set_value("active_match", "opponent", active_match_opponent)
	cfg.set_value("active_match", "time", active_match_time)
	cfg.save(PATH)
