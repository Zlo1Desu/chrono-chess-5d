class_name CosmicBackground
extends Control
## Процедурный живой космический фон: мерцающие квантовые звёзды,
## мягкие туманности, легкие световые авроры и падающие метеоры.

var _anim_time: float = 0.0
var _stars: Array = []
var _shooting_stars: Array = []
var _nebulae: Array = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var rng := RandomNumberGenerator.new()
	rng.seed = 333

	# 1. Звёздное поле (130 звёзд)
	var star_palette := [
		Color(1.0, 1.0, 1.0),          # Белый бриллиант
		Color(0.65, 0.88, 1.0),        # Квантовый циан
		Color(1.0, 0.88, 0.65),        # Тёплый звёздный свет
		Color(0.85, 0.70, 1.0),        # Неоновый аметист
	]

	for i in 130:
		var col: Color = star_palette[rng.randi_range(0, star_palette.size() - 1)]
		_stars.append({
			"pos": Vector2(rng.randf(), rng.randf()),
			"size": rng.randf_range(0.8, 2.2),
			"alpha": rng.randf_range(0.25, 0.85),
			"speed": rng.randf_range(1.2, 3.8),
			"phase": rng.randf_range(0.0, TAU),
			"color": col,
			"glint": rng.randf() > 0.82
		})

	# 2. Туманности (дрейфующие энергетические облака)
	_nebulae = [
		{"pos": Vector2(0.22, 0.30), "radius": 280.0, "color": Color(0.10, 0.22, 0.55, 0.16), "drift": Vector2(0.015, 0.02), "phase": 0.0},
		{"pos": Vector2(0.78, 0.68), "radius": 340.0, "color": Color(0.28, 0.10, 0.48, 0.14), "drift": Vector2(-0.02, 0.012), "phase": 1.8},
		{"pos": Vector2(0.50, 0.82), "radius": 260.0, "color": Color(0.08, 0.32, 0.42, 0.15), "drift": Vector2(0.018, -0.015), "phase": 3.4},
	]

	# 3. Метеоры (падающие квантовые искры)
	for i in 2:
		_shooting_stars.append({
			"active": false,
			"pos": Vector2.ZERO,
			"dir": Vector2(1.0, 0.55).normalized(),
			"speed": 620.0,
			"len": 120.0,
			"prog": 0.0,
			"cooldown": rng.randf_range(1.5, 5.0)
		})


func _process(delta: float) -> void:
	_anim_time += delta

	# Обновление метеоров
	for comet in _shooting_stars:
		if comet["active"]:
			comet["prog"] += delta * 1.6
			comet["pos"] += comet["dir"] * (float(comet["speed"]) * delta)
			if comet["prog"] >= 1.0:
				comet["active"] = false
				comet["cooldown"] = randf_range(3.0, 8.0)
		else:
			comet["cooldown"] -= delta
			if comet["cooldown"] <= 0.0:
				comet["active"] = true
				comet["prog"] = 0.0
				var start_x: float = randf_range(-0.1, 0.85) * size.x
				var start_y: float = randf_range(-0.1, 0.4) * size.y
				comet["pos"] = Vector2(start_x, start_y)
				var angle := randf_range(0.45, 0.75)
				comet["dir"] = Vector2(cos(angle), sin(angle))
				comet["speed"] = randf_range(500.0, 800.0)
				comet["len"] = randf_range(90.0, 160.0)

	if visible and is_inside_tree():
		queue_redraw()


func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	if w <= 0.0 or h <= 0.0:
		return

	# Глубокий темный космический градиент
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.03, 0.045, 0.09, 1.0))

	# Мягкие квантовые туманности
	for neb in _nebulae:
		var n_pos: Vector2 = neb["pos"] * size + Vector2(sin(_anim_time * 0.4 + neb["phase"]), cos(_anim_time * 0.35 + neb["phase"])) * 28.0
		var n_pulse: float = sin(_anim_time * 0.8 + neb["phase"]) * 0.15 + 0.85
		var n_rad: float = neb["radius"] * n_pulse
		var col: Color = neb["color"]
		# Отрисовка ореолов туманности
		draw_circle(n_pos, n_rad, Color(col.r, col.g, col.b, col.a * 0.5))
		draw_circle(n_pos, n_rad * 0.65, Color(col.r, col.g, col.b, col.a * 0.8))
		draw_circle(n_pos, n_rad * 0.35, Color(col.r, col.g, col.b, col.a * 1.2))

	# Мерцающие звёзды с крестообразными бликами
	for s in _stars:
		var sp := Vector2(s["pos"].x * w, s["pos"].y * h)
		var twinkle: float = sin(_anim_time * float(s["speed"]) + float(s["phase"])) * 0.35 + 0.65
		var base_col: Color = s["color"]
		var col := Color(base_col.r, base_col.g, base_col.b, float(s["alpha"]) * twinkle)
		var rad: float = float(s["size"])
		draw_circle(sp, rad, col)

		if bool(s.get("glint", false)) and twinkle > 0.82:
			var flare_len: float = rad * 3.5 * (twinkle - 0.78) * 4.5
			var flare_col := Color(base_col.r, base_col.g, base_col.b, col.a * 0.65)
			draw_line(sp - Vector2(flare_len, 0.0), sp + Vector2(flare_len, 0.0), flare_col, 1.0)
			draw_line(sp - Vector2(0.0, flare_len), sp + Vector2(0.0, flare_len), flare_col, 1.0)

	# Падающие метеоры
	for comet in _shooting_stars:
		if not bool(comet["active"]):
			continue
		var head_pos: Vector2 = comet["pos"]
		var d: Vector2 = comet["dir"]
		var prog: float = float(comet["prog"])
		var tail_len: float = float(comet["len"]) * 0.7
		var tail_pos: Vector2 = head_pos - d * tail_len
		var comet_alpha: float = sin(prog * PI) * 0.88
		var comet_col := Color(0.7, 0.92, 1.0, comet_alpha)
		draw_line(tail_pos, head_pos, comet_col, 1.6)
		draw_circle(head_pos, 2.2, Color(1.0, 1.0, 1.0, comet_alpha))
