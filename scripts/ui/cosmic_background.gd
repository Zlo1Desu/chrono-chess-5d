class_name CosmicBackground
extends Control
## Спокойный атмосферный фон глубокого космоса без резких кругов и визуального шума.

var _anim_time: float = 0.0
var _stars: Array = []
var _shooting_stars: Array = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var rng := RandomNumberGenerator.new()
	rng.seed = 333

	var star_palette := [
		Color(0.95, 0.97, 1.0),
		Color(0.72, 0.85, 1.0),
		Color(0.98, 0.90, 0.74),
	]

	for i in 85:
		var col: Color = star_palette[rng.randi_range(0, star_palette.size() - 1)]
		_stars.append({
			"pos": Vector2(rng.randf(), rng.randf()),
			"size": rng.randf_range(0.8, 1.8),
			"alpha": rng.randf_range(0.18, 0.58),
			"speed": rng.randf_range(0.8, 2.2),
			"phase": rng.randf_range(0.0, TAU),
			"color": col,
		})

	for i in 2:
		_shooting_stars.append({
			"active": false,
			"pos": Vector2.ZERO,
			"dir": Vector2(1.0, 0.55).normalized(),
			"speed": 540.0,
			"len": 110.0,
			"prog": 0.0,
			"cooldown": rng.randf_range(3.0, 8.0)
		})


func _process(delta: float) -> void:
	_anim_time += delta

	for comet in _shooting_stars:
		if comet["active"]:
			comet["prog"] += delta * 1.5
			comet["pos"] += comet["dir"] * (float(comet["speed"]) * delta)
			if comet["prog"] >= 1.0:
				comet["active"] = false
				comet["cooldown"] = randf_range(5.0, 12.0)
		else:
			comet["cooldown"] -= delta
			if comet["cooldown"] <= 0.0:
				comet["active"] = true
				comet["prog"] = 0.0
				var start_x: float = randf_range(0.05, 0.80) * size.x
				var start_y: float = randf_range(0.05, 0.35) * size.y
				comet["pos"] = Vector2(start_x, start_y)
				var angle := randf_range(0.45, 0.72)
				comet["dir"] = Vector2(cos(angle), sin(angle))
				comet["speed"] = randf_range(460.0, 680.0)
				comet["len"] = randf_range(80.0, 140.0)

	if visible and is_inside_tree():
		queue_redraw()


func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	if w <= 0.0 or h <= 0.0:
		return

	# Глубокий графитово-сланцевый фон (#0B0F19)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.043, 0.059, 0.098, 1.0))

	# Мягкое рассеянное свечение сверху
	for step in 6:
		var t: float = float(step + 1) / 6.0
		var r: float = maxf(w, h) * 0.55 * t
		draw_circle(Vector2(w * 0.5, h * 0.12), r, Color(0.11, 0.18, 0.34, 0.022 * (1.0 - t * 0.6)))

	for s in _stars:
		var sp := Vector2(s["pos"].x * w, s["pos"].y * h)
		var twinkle: float = sin(_anim_time * float(s["speed"]) + float(s["phase"])) * 0.30 + 0.70
		var base_col: Color = s["color"]
		var col := Color(base_col.r, base_col.g, base_col.b, float(s["alpha"]) * twinkle)
		draw_circle(sp, float(s["size"]), col)

	for comet in _shooting_stars:
		if not bool(comet["active"]):
			continue
		var head_pos: Vector2 = comet["pos"]
		var d: Vector2 = comet["dir"]
		var prog: float = float(comet["prog"])
		var tail_pos: Vector2 = head_pos - d * (float(comet["len"]) * 0.7)
		var comet_alpha: float = sin(prog * PI) * 0.65
		draw_line(tail_pos, head_pos, Color(0.75, 0.88, 1.0, comet_alpha), 1.4)
		draw_circle(head_pos, 1.8, Color(1.0, 1.0, 1.0, comet_alpha))
