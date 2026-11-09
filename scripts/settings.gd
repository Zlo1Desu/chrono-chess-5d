class_name Settings
extends RefCounted
## Менеджер глобальных настроек: масштабирование интерфейса (UI Scale) для телефонов и ПК,
## управление звуком и сохранение конфигурации в user://settings.cfg.

const PATH := "user://settings.cfg"

# -1: Автоопределение (на телефонах ~165-175%, на ПК 100%)
# 0: 100%, 1: 125%, 2: 150%, 3: 175%, 4: 200%
static var ui_scale_preset: int = -1
static var sound_enabled: bool = true

const PRESETS: Array[Dictionary] = [
	{"label": "100% (Мелкий)", "scale": 1.0},
	{"label": "125% (Средний)", "scale": 1.25},
	{"label": "150% (Крупный)", "scale": 1.5},
	{"label": "175% (Очень крупный)", "scale": 1.75},
	{"label": "200% (Максимальный)", "scale": 2.0},
]


static func get_auto_scale() -> float:
	var is_mobile: bool = OS.has_feature("mobile") or OS.get_name() in ["Android", "iOS"]
	var dpi: float = float(DisplayServer.screen_get_dpi())
	var win_size: Vector2i = DisplayServer.window_get_size()
	var min_dim: int = mini(win_size.x, win_size.y) if win_size.x > 0 and win_size.y > 0 else 720

	if is_mobile:
		if dpi >= 460.0 or min_dim >= 1400:
			return 1.8
		elif dpi >= 360.0 or min_dim >= 1000:
			return 1.65
		elif dpi >= 250.0:
			return 1.5
		else:
			return 1.65 # Стабильный комфортный масштаб для любого телефона
	else:
		if dpi >= 200.0:
			return 1.5
		elif dpi >= 140.0:
			return 1.25
		return 1.0


static func get_current_scale() -> float:
	if ui_scale_preset >= 0 and ui_scale_preset < PRESETS.size():
		return float(PRESETS[ui_scale_preset]["scale"])
	return get_auto_scale()


static func get_scale_label() -> String:
	if ui_scale_preset == -1:
		return "⚙ Масштаб UI: Авто (%d%%)" % int(roundf(get_auto_scale() * 100.0))
	elif ui_scale_preset >= 0 and ui_scale_preset < PRESETS.size():
		return "⚙ Масштаб UI: %s" % PRESETS[ui_scale_preset]["label"]
	return "⚙ Масштаб UI: 100%"


static func sound_label(on: bool) -> String:
	return "🔊 Звук: ВКЛ" if on else "🔇 Звук: ВЫКЛ"


static func cycle_ui_scale(target_window: Window) -> String:
	# -1 (Авто) -> 0 (100%) -> 1 (125%) -> 2 (150%) -> 3 (175%) -> 4 (200%) -> -1 (Авто)
	if ui_scale_preset == -1:
		ui_scale_preset = 0
	elif ui_scale_preset >= PRESETS.size() - 1:
		ui_scale_preset = -1
	else:
		ui_scale_preset += 1

	apply_scale(target_window)
	save_to_disk()
	return get_scale_label()


static func set_preset(idx: int, target_window: Window) -> void:
	ui_scale_preset = clampi(idx, -1, PRESETS.size() - 1)
	apply_scale(target_window)
	save_to_disk()


static func apply_scale(target_window: Window) -> void:
	if target_window != null:
		target_window.content_scale_factor = get_current_scale()


## Отступы безопасной зоны экрана (вырезы камеры, скруглённые углы, системные панели)
## в координатах вьюпорта размера `vp_size`. Используется меню и экраном партии.
static func safe_insets(vp_size: Vector2) -> Dictionary:
	var zero := {"left": 0.0, "top": 0.0, "right": 0.0, "bottom": 0.0}
	var safe := DisplayServer.get_display_safe_area()
	var win_size := DisplayServer.window_get_size()
	if win_size.x <= 0 or win_size.y <= 0:
		return zero
	if safe.position == Vector2i.ZERO and safe.size == win_size:
		return zero
	var scale_x: float = vp_size.x / float(win_size.x)
	var scale_y: float = vp_size.y / float(win_size.y)
	return {
		"left": maxf(0.0, float(safe.position.x) * scale_x),
		"top": maxf(0.0, float(safe.position.y) * scale_y),
		"right": maxf(0.0, float(win_size.x - (safe.position.x + safe.size.x)) * scale_x),
		"bottom": maxf(0.0, float(win_size.y - (safe.position.y + safe.size.y)) * scale_y),
	}


static func load_from_disk() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		ui_scale_preset = int(cfg.get_value("ui", "scale_preset", -1))
		sound_enabled = bool(cfg.get_value("audio", "enabled", true))


static func save_to_disk() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("ui", "scale_preset", ui_scale_preset)
	cfg.set_value("audio", "enabled", sound_enabled)
	cfg.save(PATH)
