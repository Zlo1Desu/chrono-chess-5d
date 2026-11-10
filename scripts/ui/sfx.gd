class_name Sfx
extends Node
## Процедурный синтезатор звуков для 5D Chess (чистый синтез PCM без внешних файлов).

const RATE := 44100

var _players: Array = []
var _streams: Dictionary = {}
var _ambient_player: AudioStreamPlayer
var enabled: bool = true
var _ambient_active: bool = false


func _ready() -> void:
	# Создаём фоновый плеер для эмбиента
	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.bus = "Master"
	add_child(_ambient_player)

	# Создаём пул из 8 плееров для насыщенного полифонического звучания
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)

	_generate_all()


func start_ambient() -> void:
	_ambient_active = true
	if not enabled or _ambient_player == null or not _streams.has("ambient"):
		return
	if not _ambient_player.playing:
		_ambient_player.stream = _streams["ambient"]
		_ambient_player.volume_db = -12.0
		_ambient_player.play()


func stop_ambient() -> void:
	_ambient_active = false
	if _ambient_player != null and _ambient_player.playing:
		_ambient_player.stop()


func play(id: String) -> void:
	# Тактильный отклик (Haptic Feedback) на поддерживаемых платформах (Android / мобилки)
	_trigger_haptic(id)

	if not enabled or not _streams.has(id):
		return
	for p in _players:
		if not p.playing:
			p.stream = _streams[id]
			p.play()
			return
	# Если все плееры заняты, переиспользуем первый
	if not _players.is_empty():
		_players[0].stream = _streams[id]
		_players[0].play()


func _trigger_haptic(id: String) -> void:
	match id:
		"click":
			Input.vibrate_handheld(12)
		"move":
			Input.vibrate_handheld(18)
		"capture":
			Input.vibrate_handheld(35)
		"travel":
			Input.vibrate_handheld(50)
		"branch":
			Input.vibrate_handheld(75)
		"crit":
			Input.vibrate_handheld(80)
		"check":
			Input.vibrate_handheld(65)
		"block", "error":
			Input.vibrate_handheld(40)
		"win":
			Input.vibrate_handheld(100)


## Переключает звук, сохраняет настройку и возвращает новое состояние.
func toggle() -> bool:
	enabled = not enabled
	Settings.sound_enabled = enabled
	Settings.save_to_disk()
	if not enabled:
		if _ambient_player != null and _ambient_player.playing:
			_ambient_player.stop()
	else:
		if _ambient_active:
			start_ambient()
	return enabled


# ---------------------------------------------------------------- Генерация звуков

func _generate_all() -> void:
	_streams["ambient"] = _synth_ambient()
	_streams["click"] = _synth_click()
	_streams["move"] = _synth_move()
	_streams["capture"] = _synth_capture()
	_streams["travel"] = _synth_travel()
	_streams["branch"] = _synth_branch()
	_streams["submit"] = _synth_submit()
	_streams["error"] = _synth_error()
	_streams["check"] = _synth_check()
	_streams["undo"] = _synth_undo()
	_streams["win"] = _synth_win()
	_streams["dice"] = _synth_dice()
	_streams["crit"] = _synth_crit()
	_streams["block"] = _synth_block()


func _make(samples: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		var val: float = clampf(samples[i], -1.0, 1.0)
		data.encode_s16(i * 2, int(val * 32000.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = data
	return s


func _make_looping(samples: PackedFloat32Array) -> AudioStreamWAV:
	var s := _make(samples)
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_begin = 0
	s.loop_end = samples.size()
	return s


## 0. Атмосферный космический хроно-эмбиент главного меню (бесшовный 8-секундный пад)
func _synth_ambient() -> AudioStreamWAV:
	var dur: float = 8.0
	var n: int = int(dur * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)

	# Частоты гармоник подобраны так, чтобы на длительности dur = 8.0 сек
	# укладывалось точное целочисленное количество циклов (фазовая непрерывность при зацикливании):
	var c_sub: float = 294.0      # 36.75 Гц (D1)
	var c_root: float = 588.0     # 73.50 Гц (D2)
	var c_root_det: float = 590.0 # 73.75 Гц (мягкий хорус 0.25 Гц)
	var c_fifth: float = 882.0    # 110.25 Гц (A2)
	var c_fifth_det: float = 883.0# 110.375 Гц
	var c_oct: float = 1176.0     # 147.00 Гц (D3)
	var c_oct_det: float = 1178.0 # 147.25 Гц
	var c_min3: float = 1398.0    # 174.75 Гц (F3 - минорная квантовая загадка)
	var c_fifth2: float = 1764.0  # 220.50 Гц (A3)
	var c_min7: float = 2090.0    # 261.25 Гц (C4 - септаккорд Dm7)
	var c_ext9: float = 2646.0    # 330.75 Гц (E4 - нона, воздушный объем)
	var c_shimmer: float = 3528.0 # 441.00 Гц (A4 - звездный мерцающий резонанс)

	for i in n:
		var t_norm: float = float(i) / float(n)
		var t: float = t_norm * dur

		# Медленные дыхательные LFO (периоды 8.0с, 4.0с, 2.67с, 2.0с)
		var lfo1: float = 0.5 + 0.5 * sin(TAU * 1.0 * t_norm)
		var lfo2: float = 0.5 + 0.5 * sin(TAU * 2.0 * t_norm + 1.2)
		var lfo3: float = 0.5 + 0.5 * sin(TAU * 3.0 * t_norm + 2.5)
		var lfo4: float = 0.5 + 0.5 * sin(TAU * 4.0 * t_norm + 0.7)

		# Глубокий суббас и фундаментальный тон времени
		var sub: float = sin(TAU * (c_sub / dur) * t) * 0.22
		var bass: float = (sin(TAU * (c_root / dur) * t) + 0.7 * sin(TAU * (c_root_det / dur) * t)) * 0.20

		# Теплая квинта и октава
		var mid5: float = (sin(TAU * (c_fifth / dur) * t) + 0.6 * sin(TAU * (c_fifth_det / dur) * t)) * (0.12 + 0.06 * lfo1)
		var midoct: float = (sin(TAU * (c_oct / dur) * t) + 0.5 * sin(TAU * (c_oct_det / dur) * t)) * (0.10 + 0.05 * lfo2)

		# Космические гармоники аккорда Dm9
		var chord: float = sin(TAU * (c_min3 / dur) * t) * (0.07 + 0.04 * lfo3) \
						 + sin(TAU * (c_fifth2 / dur) * t) * (0.06 + 0.03 * lfo2) \
						 + sin(TAU * (c_min7 / dur) * t) * (0.04 + 0.03 * lfo4) \
						 + sin(TAU * (c_ext9 / dur) * t) * (0.03 + 0.02 * lfo1)

		# Мерцание хроно-поля
		var shimmer: float = sin(TAU * (c_shimmer / dur) * t) * (0.015 + 0.015 * lfo3)

		var total: float = sub + bass + mid5 + midoct + chord + shimmer

		# Мягкое аналоговое насыщение для приятного ненавязчивого звучания
		buf[i] = (total / (1.0 + 0.4 * absf(total))) * 0.55

	return _make_looping(buf)


## 1. Мягкий тактильный клик интерфейса
func _synth_click() -> AudioStreamWAV:
	var n: int = int(0.035 * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	for i in n:
		var t: float = float(i) / RATE
		var env: float = exp(-t * 140.0)
		var v: float = sin(TAU * 1250.0 * t) * 0.7 + sin(TAU * 2500.0 * t) * 0.3
		buf[i] = v * env * 0.4
	return _make(buf)


## 2. Натуральный тактильный стук деревянной фигуры о доску
func _synth_move() -> AudioStreamWAV:
	var n: int = int(0.08 * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 101
	for i in n:
		var t: float = float(i) / RATE
		var click: float = (rng.randf() * 2.0 - 1.0) * exp(-t * 900.0) * 0.6
		var f: float = lerpf(240.0, 120.0, minf(1.0, t * 25.0))
		var body: float = (sin(TAU * f * t) * 0.8 + sin(TAU * (f * 1.8) * t) * 0.2) * exp(-t * 55.0)
		buf[i] = (click + body) * 0.75
	return _make(buf)


## 3. Сокрушительный удар взятия фигуры с кристальным резонансом
func _synth_capture() -> AudioStreamWAV:
	var n: int = int(0.16 * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 202
	for i in n:
		var t: float = float(i) / RATE
		var f_sub: float = lerpf(120.0, 50.0, minf(1.0, t * 20.0))
		var sub: float = sin(TAU * f_sub * t) * exp(-t * 30.0) * 0.8
		var snap: float = (rng.randf() * 2.0 - 1.0) * exp(-t * 400.0) * 0.7
		var ring: float = sin(TAU * 680.0 * t) * exp(-t * 35.0) * 0.35
		buf[i] = (sub + snap + ring) * 0.8
	return _make(buf)


## 4. Эпический портальный переход во времени сквозь червоточину
func _synth_travel() -> AudioStreamWAV:
	var dur: float = 0.52
	var n: int = int(dur * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var phase_main: float = 0.0
	var phase_sub: float = 0.0
	for i in n:
		var k: float = float(i) / n
		var t: float = float(i) / RATE
		var env: float = sin(PI * pow(k, 0.75))
		var f_sweep: float = lerpf(180.0, 950.0, pow(k, 1.4))
		var mod_freq: float = 14.0 + k * 8.0
		var fm: float = sin(TAU * mod_freq * t) * 45.0
		phase_main += TAU * (f_sweep + fm) / RATE
		var wave: float = sin(phase_main) * 0.7 + sin(phase_main * 0.5) * 0.3

		phase_sub += TAU * (55.0 + k * 40.0) / RATE
		var sub: float = sin(phase_sub) * 0.45 * (1.0 - k * 0.5)

		var shimmer: float = 0.0
		if k > 0.3:
			var sk: float = (k - 0.3) / 0.7
			shimmer = (sin(TAU * 1760.0 * t) * 0.2 + sin(TAU * 2640.0 * t) * 0.15) * sin(PI * sk)

		buf[i] = (wave * 0.65 + sub + shimmer) * env * 0.85
	return _make(buf)


## 5. Рождение новой временной шкалы (раскол пространства-времени)
func _synth_branch() -> AudioStreamWAV:
	var dur: float = 0.42
	var n: int = int(dur * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	for i in n:
		var t: float = float(i) / RATE
		var k: float = float(i) / n
		var boom: float = sin(TAU * lerpf(90.0, 42.0, k) * t) * exp(-t * 12.0) * 0.85
		var c1: float = sin(TAU * 659.25 * t) * exp(-t * 9.0) * 0.35
		var c2: float = sin(TAU * 987.77 * t) * exp(-t * 11.0) * 0.3
		var c3: float = sin(TAU * 1318.5 * t) * exp(-t * 14.0) * 0.25
		buf[i] = (boom + c1 + c2 + c3) * 0.8
	return _make(buf)


## 6. Завершение хода: высокотехнологичный квантовый замок
func _synth_submit() -> AudioStreamWAV:
	var dur: float = 0.24
	var n: int = int(dur * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	for i in n:
		var t: float = float(i) / RATE
		var p1: float = sin(TAU * 587.33 * t) * exp(-t * 28.0) * 0.45
		var p2: float = 0.0
		if t > 0.08:
			var t2: float = t - 0.08
			p2 = (sin(TAU * 880.0 * t2) * 0.6 + sin(TAU * 1760.0 * t2) * 0.25) * exp(-t2 * 20.0)
		buf[i] = (p1 + p2) * 0.75
	return _make(buf)


## 7. Ошибка / Недопустимый ход
func _synth_error() -> AudioStreamWAV:
	var dur: float = 0.16
	var n: int = int(dur * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	for i in n:
		var t: float = float(i) / RATE
		var tone: float = sin(TAU * 130.81 * t) * 0.7 + sin(TAU * 123.47 * t) * 0.5
		var buzz: float = fposmod(t * 130.81, 1.0) * 2.0 - 1.0
		var env: float = exp(-t * 22.0)
		buf[i] = (tone * 0.6 + buzz * 0.25) * env * 0.7
	return _make(buf)


## 8. Шах / Угроза королю: тревожный диссонанс
func _synth_check() -> AudioStreamWAV:
	var dur: float = 0.38
	var n: int = int(dur * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	for i in n:
		var t: float = float(i) / RATE
		var p1: float = (sin(TAU * 440.0 * t) + sin(TAU * 622.25 * t) * 0.8) * exp(-fmod(t, 0.15) * 20.0)
		buf[i] = p1 * 0.55
	return _make(buf)


## 9. Перемотка времени назад (Отмена хода)
func _synth_undo() -> AudioStreamWAV:
	var dur: float = 0.22
	var n: int = int(dur * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var phase: float = 0.0
	for i in n:
		var k: float = float(i) / n
		var t: float = float(i) / RATE
		var f: float = lerpf(900.0, 160.0, k * k)
		phase += TAU * f / RATE
		var env: float = pow(k, 0.6) * (1.0 - pow(k, 8.0))
		buf[i] = sin(phase) * env * 0.65
	return _make(buf)


## 10. Победный фанфарный аккорд
func _synth_win() -> AudioStreamWAV:
	var dur: float = 0.75
	var n: int = int(dur * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var freqs: Array = [523.25, 659.25, 783.99, 1046.5, 1318.5]
	for j in freqs.size():
		var delay: float = j * 0.065
		var f: float = freqs[j]
		for i in n:
			var t: float = float(i) / RATE - delay
			if t > 0.0:
				var env: float = exp(-t * 4.5) * minf(1.0, t * 250.0)
				buf[i] += sin(TAU * f * t) * env * 0.22
	return _make(buf)


## 11. Грохот броска кубика d20 по столу
func _synth_dice() -> AudioStreamWAV:
	var dur: float = 0.28
	var n: int = int(dur * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 505
	var impacts := [0.0, 0.055, 0.115, 0.17]
	for imp in impacts:
		for i in n:
			var t: float = float(i) / RATE - imp
			if t > 0.0 and t < 0.06:
				var click: float = (rng.randf() * 2.0 - 1.0) * exp(-t * 800.0) * 0.45
				var wood: float = sin(TAU * 340.0 * t) * exp(-t * 90.0) * 0.35
				buf[i] += (click + wood) * 0.7
	return _make(buf)


## 12. Триумфальный звон критического успеха (Нат 20)
func _synth_crit() -> AudioStreamWAV:
	var dur: float = 0.85
	var n: int = int(dur * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var freqs: Array = [1046.5, 1318.5, 1567.98, 2093.0]
	for j in freqs.size():
		var delay: float = j * 0.05
		var f: float = freqs[j]
		for i in n:
			var t: float = float(i) / RATE - delay
			if t > 0.0:
				var env: float = exp(-t * 5.0) * minf(1.0, t * 400.0)
				var bell: float = sin(TAU * f * t) * 0.6 + sin(TAU * (f * 2.76) * t) * 0.25
				buf[i] += bell * env * 0.3
	return _make(buf)


## 13. Звонкий металлический отскок/парирование удара щитом
func _synth_block() -> AudioStreamWAV:
	var dur: float = 0.26
	var n: int = int(dur * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 777
	for i in n:
		var t: float = float(i) / RATE
		var clank: float = (sin(TAU * 1840.0 * t) * 0.45 + sin(TAU * 2920.0 * t) * 0.35 + sin(TAU * 4200.0 * t) * 0.2) * exp(-t * 22.0)
		var snap: float = (rng.randf() * 2.0 - 1.0) * exp(-t * 600.0) * 0.4
		var low_thud: float = sin(TAU * 160.0 * t) * exp(-t * 35.0) * 0.5
		buf[i] = (clank + snap + low_thud) * 0.75
	return _make(buf)
