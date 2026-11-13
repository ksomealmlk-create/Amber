extends Control
# الواجهة: قلوب، جمرات، اسم المرحلة، أزرار لمس متعددة (يسار/يمين/قفز/ضرب/اندفاع)، شاشتا الموت والفوز.

var sim
var font: Font
var state := {"left": false, "right": false, "jump": false, "atk": false, "dash": false}
var touches := {}
var title_t: float = 0.0
var level_name: String = ""
var fade_dead: float = 0.0
var win_t: float = 0.0
var want_restart := false

func setup(s, f: Font, lname: String) -> void:
	sim = s
	font = f
	level_name = lname
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)

func _unit() -> float:
	return size.y / 720.0

func _buttons() -> Dictionary:
	var u: float = _unit()
	var w: float = size.x
	var h: float = size.y
	return {
		"left": [Vector2(150.0 * u, h - 130.0 * u), 86.0 * u],
		"right": [Vector2(340.0 * u, h - 130.0 * u), 86.0 * u],
		"jump": [Vector2(w - 140.0 * u, h - 140.0 * u), 92.0 * u],
		"atk": [Vector2(w - 330.0 * u, h - 100.0 * u), 74.0 * u],
		"dash": [Vector2(w - 200.0 * u, h - 300.0 * u), 62.0 * u],
	}

func _hit(pos: Vector2) -> String:
	var best := ""
	var best_d: float = 1e9
	var b: Dictionary = _buttons()
	for k in b.keys():
		var c: Vector2 = b[k][0]
		var r: float = b[k][1] * 1.3
		var d: float = pos.distance_to(c)
		if d < r and d < best_d:
			best = k
			best_d = d
	return best

func _input(ev: InputEvent) -> void:
	if ev is InputEventScreenTouch:
		if ev.pressed:
			touches[ev.index] = _hit(ev.position)
			if sim.phase == "won" and win_t > 1.5:
				want_restart = true
		else:
			touches.erase(ev.index)
		_recompute()
	elif ev is InputEventScreenDrag:
		touches[ev.index] = _hit(ev.position)
		_recompute()

func _recompute() -> void:
	for k in state.keys():
		state[k] = false
	for v in touches.values():
		if v != "":
			state[v] = true

func get_input() -> Dictionary:
	var l: bool = state["left"] or Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A)
	var r: bool = state["right"] or Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D)
	var j: bool = state["jump"] or Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W)
	var a: bool = state["atk"] or Input.is_key_pressed(KEY_J) or Input.is_key_pressed(KEY_X)
	var d: bool = state["dash"] or Input.is_key_pressed(KEY_K) or Input.is_key_pressed(KEY_SHIFT)
	if sim.phase == "won" and win_t > 1.5 and (Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_SPACE)):
		want_restart = true
	return {"left": l, "right": r, "jump": j, "atk": a, "dash": d}

func _process(dt: float) -> void:
	title_t += dt
	if sim.phase == "dead":
		fade_dead = minf(1.0, fade_dead + dt * 1.6)
	else:
		fade_dead = maxf(0.0, fade_dead - dt * 2.5)
	if sim.phase == "won":
		win_t += dt
	queue_redraw()

func _text(txt: String, pos: Vector2, sz: int, col: Color, align: int = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0) -> void:
	draw_string(font, pos + Vector2(2, 2), txt, align, width, sz, Color(0, 0, 0, col.a * 0.6))
	draw_string(font, pos, txt, align, width, sz, col)

func _heart(c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(0, 41):
		var t: float = float(i) / 40.0 * TAU
		var x: float = 16.0 * pow(sin(t), 3.0)
		var y: float = -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
		pts.append(c + Vector2(x, y) * (r / 17.0))
	draw_colored_polygon(pts, col)

func _draw() -> void:
	if sim == null:
		return
	var u: float = _unit()
	var w: float = size.x
	var h: float = size.y

	# قلوب
	for i in range(sim.max_hp):
		var c := Vector2(54.0 * u + i * 52.0 * u, 52.0 * u)
		if i < sim.p.hp:
			_heart(c + Vector2(0, 2 * u), 24.0 * u, Color(0, 0, 0, 0.35))
			_heart(c, 22.0 * u, Color("ff4d6d"))
			_heart(c + Vector2(-4 * u, -5 * u), 8.0 * u, Color(1, 1, 1, 0.35))
		else:
			_heart(c, 20.0 * u, Color(0.25, 0.2, 0.3, 0.6))

	# عدّاد الجمرات
	var ec := Vector2(w - 190.0 * u, 52.0 * u)
	draw_circle(ec, 18.0 * u, Color(1.0, 0.6, 0.2, 0.25))
	draw_circle(ec, 11.0 * u, Color("ffb347"))
	draw_circle(ec, 5.0 * u, Color("fff2c8"))
	_text("%d / %d" % [sim.collected, sim.total_embers], ec + Vector2(30.0 * u, 12.0 * u), int(34.0 * u), Color("ffe2b0"))

	# اسم المرحلة (يظهر ثم يختفي)
	var ta: float = 0.0
	if title_t < 4.5:
		ta = clampf(minf(title_t / 0.8, (4.5 - title_t) / 0.8), 0.0, 1.0)
	if ta > 0.0:
		_text("العالم الأول · المغارة المنسية", Vector2(0, h * 0.27), int(30.0 * u), Color(0.75, 0.9, 1.0, ta * 0.85), HORIZONTAL_ALIGNMENT_CENTER, w)
		_text(level_name, Vector2(0, h * 0.27 + 62.0 * u), int(58.0 * u), Color(1.0, 0.86, 0.6, ta), HORIZONTAL_ALIGNMENT_CENTER, w)

	# أزرار اللمس
	var b: Dictionary = _buttons()
	for k in b.keys():
		var c2: Vector2 = b[k][0]
		var r: float = b[k][1]
		var down: bool = state[k]
		var a: float = 0.55 if down else 0.28
		draw_circle(c2, r, Color(0.05, 0.08, 0.14, a))
		draw_arc(c2, r, 0.0, TAU, 48, Color(0.75, 0.9, 1.0, a + 0.2), 3.0 * u, true)
		if down:
			draw_circle(c2, r * 0.9, Color(1.0, 0.8, 0.45, 0.18))
		_icon(k, c2, r, Color(1, 1, 1, 0.9 if down else 0.7))

	# شاشة الموت
	if fade_dead > 0.0:
		draw_rect(Rect2(0, 0, w, h), Color(0.35, 0.02, 0.04, fade_dead * 0.55))
		_text("سقطت…", Vector2(0, h * 0.5), int(70.0 * u), Color(1, 0.8, 0.75, fade_dead), HORIZONTAL_ALIGNMENT_CENTER, w)

	# شاشة الفوز
	if sim.phase == "won":
		var wa: float = clampf(win_t / 1.2, 0.0, 1.0)
		draw_rect(Rect2(0, 0, w, h), Color(0.05, 0.02, 0.12, wa * 0.6))
		_text("أنجزت المرحلة!", Vector2(0, h * 0.38), int(84.0 * u), Color(1.0, 0.9, 0.7, wa), HORIZONTAL_ALIGNMENT_CENTER, w)
		_text("الجمرات: %d / %d   ·   الأعداء: %d   ·   السقطات: %d" % [sim.collected, sim.total_embers, sim.kills, sim.deaths], Vector2(0, h * 0.38 + 80.0 * u), int(32.0 * u), Color(0.85, 0.92, 1.0, wa), HORIZONTAL_ALIGNMENT_CENTER, w)
		if win_t > 1.5:
			_text("المس الشاشة للإعادة", Vector2(0, h * 0.38 + 150.0 * u), int(30.0 * u), Color(1, 1, 1, 0.6 + 0.4 * sin(win_t * 4.0)), HORIZONTAL_ALIGNMENT_CENTER, w)

func _icon(k: String, c: Vector2, r: float, col: Color) -> void:
	var s: float = r * 0.42
	match k:
		"left":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-s, 0), c + Vector2(s * 0.7, -s), c + Vector2(s * 0.7, s)]), col)
		"right":
			draw_colored_polygon(PackedVector2Array([c + Vector2(s, 0), c + Vector2(-s * 0.7, -s), c + Vector2(-s * 0.7, s)]), col)
		"jump":
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s * 1.1), c + Vector2(s, s * 0.2), c + Vector2(-s, s * 0.2)]), col)
			draw_rect(Rect2(c + Vector2(-s * 0.35, s * 0.1), Vector2(s * 0.7, s * 0.9)), col)
		"atk":
			draw_line(c + Vector2(-s, s), c + Vector2(s, -s), col, 7.0 * _unit())
			draw_line(c + Vector2(-s * 0.2, s * 0.2), c + Vector2(s * 0.3, s * 0.7), col, 6.0 * _unit())
		"dash":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-s, -s * 0.8), c + Vector2(0, 0), c + Vector2(-s, s * 0.8)]), col)
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s * 0.8), c + Vector2(s, 0), c + Vector2(0, s * 0.8)]), col)
