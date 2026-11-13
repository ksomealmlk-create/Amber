extends Node3D
# عناصر اللعب الديناميكية: جمرات، أعداء، فخاخ، منصات تنهار، صناديق، نقاط حفظ، بوابة الهدف.
# تتزامن كل إطار مع حالة المحاكاة (sim.gd)، وتستقبل أحداث المحاكاة لتطلق المؤثرات.

const U = preload("res://scripts/util.gd")
const S := 0.05

var mats
var fx
var sim
var rng := RandomNumberGenerator.new()
var time_s: float = 0.0

var ember_nodes: Array = []
var enemy_nodes: Array = []
var crumb_nodes: Array = []
var brk_nodes: Array = []
var timed_nodes: Array = []
var faller_nodes: Array = []
var vanish_nodes: Array = []
var chest_nodes: Array = []
var check_nodes: Array = []
var goal_light: OmniLight3D

const STEEL := Color("646c80")

func build(s, m, f) -> void:
	sim = s
	mats = m
	fx = f
	rng.seed = 77
	_hazards()
	_embers()
	_enemies()
	_crumbles()
	_breakables()
	_timed()
	_fallers()
	_vanish()
	_chests()
	_checks()
	_goal()

# ------------------------------------------------------------------ أشواك ثابتة
func _spike_cluster(parent: Node, width_u: float, height_u: float, danger: bool) -> void:
	var steel = mats.plain(STEEL, 0.32, 0.85)
	var n: int = maxi(2, int(width_u / 0.5))
	U.box(parent, Vector3(0, 0.05, 0), Vector3(width_u + 0.1, 0.1, 1.3), mats.plain(Color("2a2e3c"), 0.5, 0.6))
	for row in range(2):
		var z: float = -0.28 if row == 0 else 0.28
		for i in range(n):
			var x: float = -width_u * 0.5 + (i + 0.5 + (0.0 if row == 0 else 0.5)) * width_u / n
			if x > width_u * 0.5:
				continue
			var hh: float = height_u * rng.randf_range(0.85, 1.1)
			U.cyl(parent, Vector3(x, 0.1 + hh * 0.5, z), 0.0, 0.17, hh, steel, 6)
	if danger:
		U.halo(parent, Vector3(0, 0.45, 0.8), width_u + 1.2, Color(1.0, 0.2, 0.15, 0.28), mats)

func _hazards() -> void:
	for h in sim.haz:
		var root := Node3D.new()
		root.position = U.v(h.x + h.w * 0.5, h.y + h.h, 0.0)
		add_child(root)
		_spike_cluster(root, h.w * S, maxf(0.6, h.h * S), true)

# ------------------------------------------------------------------ جمرات
func _embers() -> void:
	for m in sim.embers:
		var root := Node3D.new()
		root.position = U.v(m.x, m.y, 0.0)
		add_child(root)
		var core := U.sphere(root, Vector3.ZERO, 0.17, mats.glow(Color("ffb347"), 3.6, 0.6), Vector3(1.0, 1.15, 1.0), 10)
		core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var tip := U.cyl(root, Vector3(0, 0.26, 0), 0.0, 0.1, 0.42, mats.glow(Color("ff7a2a"), 3.0, 0.5), 6)
		tip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		U.sphere(root, Vector3.ZERO, 0.08, mats.glow(Color("fff2c8"), 4.0, 0.9), Vector3.ONE, 6)
		U.halo(root, Vector3(0, 0.05, 0.1), 1.5, Color(1.0, 0.65, 0.25, 0.55), mats)
		ember_nodes.append({"root": root, "y0": root.position.y, "ph": rng.randf() * 6.28})

# ------------------------------------------------------------------ أعداء
func _enemies() -> void:
	for e in sim.en:
		var root := Node3D.new()
		add_child(root)
		var body := StandardMaterial3D.new()
		body.roughness = 0.5
		body.metallic = 0.15
		body.emission_enabled = true
		body.emission = Color.BLACK
		body.emission_energy_multiplier = 2.5
		var d := {"root": root, "mat": body, "kind": e.kind}
		if e.kind == 1:
			# خفّاش متوهج
			body.albedo_color = Color("2b1b2e")
			U.sphere(root, Vector3.ZERO, 0.28, body, Vector3(1.0, 1.15, 0.9), 12)
			var eyec: Material = mats.glow(Color("ff5a7a"), 3.0, 0.5)
			U.sphere(root, Vector3(0.14, 0.05, 0.16), 0.05, eyec, Vector3.ONE, 6)
			U.sphere(root, Vector3(0.14, 0.05, -0.16), 0.05, eyec, Vector3.ONE, 6)
			var wings: Array = []
			for sgn in [-1.0, 1.0]:
				var piv := Node3D.new()
				piv.position = Vector3(0, 0.05, sgn * 0.2)
				root.add_child(piv)
				var wm := U.box(piv, Vector3(0.0, 0.0, sgn * 0.45), Vector3(0.5, 0.04, 0.9), body)
				wm.scale = Vector3(1.0, 1.0, 1.0)
				wings.append([piv, sgn])
			d["wings"] = wings
			U.halo(root, Vector3.ZERO, 1.8, Color(1.0, 0.35, 0.5, 0.3), mats)
		else:
			# زاحف بقبة بنفسجية وعين برتقالية
			body.albedo_color = Color("3a2548")
			U.dome(root, Vector3(0, -0.3, 0), 0.5, body, Vector3(1.0, 1.0, 0.9), 14)
			U.cyl(root, Vector3(0, -0.3, 0), 0.5, 0.5, 0.08, mats.plain(Color("150c1a"), 0.7), 12)
			for i in range(3):
				U.sphere(root, Vector3(-0.22 + i * 0.22, -0.12 + (i % 2) * 0.08, 0.38), 0.04, mats.glow(Color("4fe3c1"), 2.5, 0.5), Vector3.ONE, 6)
			var eye := U.sphere(root, Vector3(0.3, -0.08, 0.22), 0.1, mats.glow(Color("ff8a5d"), 4.0, 0.6), Vector3.ONE, 8)
			d["eye"] = eye
			var legs: Array = []
			for i in range(3):
				for z in [-0.34, 0.34]:
					var hip := Node3D.new()
					hip.position = Vector3(-0.3 + i * 0.3, -0.3, z)
					root.add_child(hip)
					U.cyl(hip, Vector3(0, -0.12, 0), 0.03, 0.02, 0.28, mats.plain(Color("150c1a"), 0.6), 5)
					legs.append([hip, float(i)])
			d["legs"] = legs
			U.halo(root, Vector3(0, -0.1, 0.4), 1.6, Color(1.0, 0.42, 0.3, 0.2), mats)
		enemy_nodes.append(d)

# ------------------------------------------------------------------ منصات تنهار
func _crumbles() -> void:
	for c in sim.crums:
		var root := Node3D.new()
		var base: Vector3 = U.v(c.x + c.w * 0.5, c.y, 0.0)
		root.position = base - Vector3(0, 0.35, 0)
		add_child(root)
		var wu: float = c.w * S
		U.box(root, Vector3.ZERO, Vector3(wu, 0.7, 3.0), mats.stone(Color("5a5068"), 0.4))
		U.box(root, Vector3(0, 0.37, 0), Vector3(wu, 0.06, 3.1), mats.stone(Color("77708a"), 0.4))
		var crack = mats.glow_unique(Color("ff7a2a"), 0.2)
		U.box(root, Vector3(-wu * 0.2, 0.1, 1.52), Vector3(wu * 0.35, 0.05, 0.04), crack, Vector3(0, 0, 0.3))
		U.box(root, Vector3(wu * 0.18, -0.1, 1.52), Vector3(wu * 0.3, 0.05, 0.04), crack, Vector3(0, 0, -0.4))
		crumb_nodes.append({"root": root, "base": root.position, "crack": crack})

# ------------------------------------------------------------------ صناديق قابلة للكسر
func _breakables() -> void:
	for b in sim.brks:
		var root := Node3D.new()
		var wu: float = b.w * S
		var hu: float = b.h * S
		root.position = U.v(b.x + b.w * 0.5, b.y + b.h * 0.5, 0.0)
		add_child(root)
		var wood = mats.plain(Color("8a5a2b"), 0.8)
		var iron = mats.plain(Color("2b2f3a"), 0.45, 0.7)
		if b.kind == 0 or b.kind == 1:
			U.box(root, Vector3.ZERO, Vector3(wu, hu, 1.4), wood)
			for sx in [-1.0, 1.0]:
				U.box(root, Vector3(sx * (wu * 0.5 - 0.07), 0, 0.0), Vector3(0.14, hu + 0.02, 1.44), iron)
			U.box(root, Vector3(0, hu * 0.5 - 0.07, 0.0), Vector3(wu + 0.02, 0.14, 1.44), iron)
			U.box(root, Vector3(0, -hu * 0.5 + 0.07, 0.0), Vector3(wu + 0.02, 0.14, 1.44), iron)
			U.box(root, Vector3(0, 0.0, 0.72), Vector3(wu * 0.8, 0.1, 0.03), iron, Vector3(0, 0, 0.6))
			U.box(root, Vector3(0, 0.0, 0.72), Vector3(wu * 0.8, 0.1, 0.03), iron, Vector3(0, 0, -0.6))
		else:
			U.sphere(root, Vector3.ZERO, wu * 0.55, mats.stone(Color("6a6f7a"), 0.5), Vector3(1.0, 0.9, 0.9), 8)
		if b.drop:
			U.halo(root, Vector3(0, 0, 0.9), 1.1, Color(1.0, 0.7, 0.3, 0.22), mats)
		brk_nodes.append({"root": root, "base": root.position})

# ------------------------------------------------------------------ فخاخ زمنية
func _timed() -> void:
	for h in sim.timed_h:
		var root := Node3D.new()
		add_child(root)
		var d := {"root": root, "kind": h.kind}
		var cx: float = h.x + h.w * 0.5
		var wu: float = h.w * S
		var hu: float = h.h * S
		if h.kind == 1:
			# أشواك تخرج من الأرض عند الإنذار
			root.position = U.v(cx, h.y + h.h, 0.0)
			U.box(root, Vector3(0, 0.02, 0), Vector3(wu + 0.2, 0.08, 1.4), mats.plain(Color("1f2330"), 0.5, 0.7))
			var slit = mats.glow_unique(Color("ff3a2a"), 0.2)
			U.box(root, Vector3(0, 0.07, 0.0), Vector3(wu * 0.8, 0.03, 0.1), slit)
			var grp := Node3D.new()
			root.add_child(grp)
			_spike_cluster(grp, wu, hu, false)
			grp.scale = Vector3(1, 0.01, 1)
			d["grp"] = grp
			d["slit"] = slit
			d["halo"] = U.halo(root, Vector3(0, 0.5, 0.9), wu + 1.4, Color(1.0, 0.25, 0.15, 0.0), mats)
		else:
			# سلك كهربائي عمودي بين مصدرين
			root.position = U.v(cx, h.y + h.h * 0.5, 0.0)
			var orb = mats.glow_unique(Color("7fd0ff"), 0.6)
			U.sphere(root, Vector3(0, hu * 0.5, 0), 0.2, orb, Vector3.ONE, 8)
			U.sphere(root, Vector3(0, -hu * 0.5, 0), 0.2, orb, Vector3.ONE, 8)
			U.cyl(root, Vector3(0, hu * 0.5 + 0.18, 0), 0.12, 0.12, 0.3, mats.plain(Color("2b2f3a"), 0.4, 0.8), 8)
			U.cyl(root, Vector3(0, -hu * 0.5 - 0.1, 0), 0.12, 0.12, 0.2, mats.plain(Color("2b2f3a"), 0.4, 0.8), 8)
			var beam_mat := StandardMaterial3D.new()
			beam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			beam_mat.albedo_color = Color(0.7, 0.92, 1.0, 1.0)
			var beam := U.cyl(root, Vector3.ZERO, 0.08, 0.08, hu, beam_mat, 6)
			beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var bolts: Array = []
			for i in range(3):
				var bolt := U.cyl(root, Vector3.ZERO, 0.025, 0.025, hu * 0.9, beam_mat, 4)
				bolt.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				bolts.append(bolt)
			var halo := U.halo(root, Vector3(0, 0, 0.5), hu * 0.9, Color(0.4, 0.75, 1.0, 0.0), mats)
			var l := OmniLight3D.new()
			l.light_color = Color("8fd0ff")
			l.light_energy = 0.0
			l.omni_range = 7.0
			l.position = Vector3(0, 0, 1.5)
			root.add_child(l)
			d["orb"] = orb
			d["beam"] = beam
			d["bolts"] = bolts
			d["halo"] = halo
			d["light"] = l
			d["hu"] = hu
		timed_nodes.append(d)

# ------------------------------------------------------------------ صخور ساقطة
func _fallers() -> void:
	for f in sim.fallers:
		var rock := Node3D.new()
		add_child(rock)
		var rm = mats.stone(Color("6b6f7e"), 0.5)
		var core := U.sphere(rock, Vector3.ZERO, 0.45, rm, Vector3(1.0, 0.9, 0.95), 7)
		core.rotation = Vector3(0.3, 0.8, 0.2)
		U.sphere(rock, Vector3(0.28, 0.12, 0.2), 0.22, rm, Vector3(1.0, 0.8, 1.0), 6)
		U.sphere(rock, Vector3(-0.2, -0.2, 0.25), 0.2, rm, Vector3(1.0, 1.0, 0.8), 6)
		U.halo(rock, Vector3.ZERO, 1.7, Color(1.0, 0.4, 0.2, 0.18), mats)
		var ring_mat := StandardMaterial3D.new()
		ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ring_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		ring_mat.albedo_color = Color(1.0, 0.25, 0.12, 0.0)
		ring_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		var tm := TorusMesh.new()
		tm.inner_radius = 0.55
		tm.outer_radius = 0.9
		var ring := U.mesh(self, tm, ring_mat, Vector3(f.x * S, 0.06, 0.0), Vector3.ZERO, Vector3(1.0, 0.05, 1.0))
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		faller_nodes.append({"rock": rock, "ring": ring, "ring_mat": ring_mat})

# ------------------------------------------------------------------ منصات مخفية تنكشف بالاقتراب
func _vanish() -> void:
	for v in sim.vplats:
		var root := Node3D.new()
		root.position = U.v(v.x + v.w * 0.5, v.y, 0.0) - Vector3(0, 0.35, 0)
		add_child(root)
		var wu: float = v.w * S
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.4, 0.45, 0.7, 0.2)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.roughness = 0.4
		m.emission_enabled = true
		m.emission = Color("9a7bff")
		m.emission_energy_multiplier = 0.4
		var slab := U.box(root, Vector3.ZERO, Vector3(wu, 0.7, 3.0), m)
		slab.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var rune = mats.glow_unique(Color("b59bff"), 1.0)
		var rl := U.box(root, Vector3(0, 0.37, 0.0), Vector3(wu * 0.8, 0.04, 0.5), rune)
		rl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		vanish_nodes.append({"mat": m, "rune": rune})

# ------------------------------------------------------------------ صناديق الكنز
func _chests() -> void:
	for c in sim.chests:
		var root := Node3D.new()
		root.position = U.v(c.x + 10.0, c.y + 16.0, 0.0)
		add_child(root)
		var wood = mats.plain(Color("7d4e26"), 0.75)
		var iron = mats.plain(Color("2b3140"), 0.4, 0.8)
		var gold = mats.glow(Color("ffc24a"), 1.2, 0.6)
		U.box(root, Vector3(0, 0.32, 0), Vector3(1.1, 0.64, 0.8), wood)
		for sx in [-1.0, 1.0]:
			U.box(root, Vector3(sx * 0.42, 0.32, 0), Vector3(0.12, 0.66, 0.84), iron)
		var inner = mats.glow_unique(Color("ffd27a"), 0.0)
		var glow_quad := U.box(root, Vector3(0, 0.64, 0), Vector3(0.95, 0.04, 0.66), inner)
		var hinge := Node3D.new()
		hinge.position = Vector3(0, 0.64, -0.4)
		root.add_child(hinge)
		var lid := U.cyl(hinge, Vector3(0, 0.0, 0.4), 0.38, 0.38, 1.1, wood, 12, Vector3(0, 0, deg_to_rad(90.0)))
		lid.scale = Vector3(1.0, 1.0, 1.0)
		U.cyl(hinge, Vector3(-0.42, 0.0, 0.4), 0.4, 0.4, 0.12, iron, 12, Vector3(0, 0, deg_to_rad(90.0)))
		U.cyl(hinge, Vector3(0.42, 0.0, 0.4), 0.4, 0.4, 0.12, iron, 12, Vector3(0, 0, deg_to_rad(90.0)))
		U.sphere(hinge, Vector3(0, 0.0, 0.8), 0.07, gold, Vector3.ONE, 6)
		var l := OmniLight3D.new()
		l.light_color = Color("ffc24a")
		l.light_energy = 0.0
		l.omni_range = 6.0
		l.position = Vector3(0, 1.0, 1.0)
		root.add_child(l)
		var halo := U.halo(root, Vector3(0, 0.8, 0.5), 2.8, Color(1.0, 0.75, 0.3, 0.0), mats)
		chest_nodes.append({"root": root, "hinge": hinge, "light": l, "halo": halo, "inner": inner})

# ------------------------------------------------------------------ فوانيس نقاط الحفظ
func _checks() -> void:
	for c in sim.checks:
		var root := Node3D.new()
		root.position = U.v(c[0], c[1], -0.9)
		add_child(root)
		U.cyl(root, Vector3(0, 0.1, 0), 0.4, 0.5, 0.2, mats.stone(Color("3a4560"), 0.4), 8)
		U.cyl(root, Vector3(0, 1.0, 0), 0.07, 0.1, 1.8, mats.plain(Color("2b3140"), 0.4, 0.8), 6)
		U.box(root, Vector3(0, 2.1, 0), Vector3(0.62, 0.1, 0.62), mats.plain(Color("2b3140"), 0.4, 0.8))
		var gm = mats.glow_unique(Color("9fe8ff"), 0.4)
		U.box(root, Vector3(0, 1.8, 0), Vector3(0.42, 0.5, 0.42), gm)
		U.cyl(root, Vector3(0, 2.25, 0), 0.0, 0.4, 0.3, mats.plain(Color("2b3140"), 0.4, 0.8), 4)
		var l := OmniLight3D.new()
		l.light_color = Color("9fe8ff")
		l.light_energy = 0.0
		l.omni_range = 7.0
		l.position = Vector3(0, 1.9, 1.5)
		root.add_child(l)
		var halo := U.halo(root, Vector3(0, 1.85, 0.4), 2.4, Color(0.6, 0.9, 1.0, 0.0), mats)
		check_nodes.append({"mat": gm, "light": l, "halo": halo, "level": 0.0, "active": false})

# ------------------------------------------------------------------ بوابة الهدف
func _goal() -> void:
	var root := Node3D.new()
	root.position = U.v(sim.goal_x + 7.0, 440.0, -0.6)
	add_child(root)
	var stone = mats.stone(Color("3c4666"), 0.3)
	var rune = mats.glow(Color("c8a0ff"), 2.4, 0.3)
	U.box(root, Vector3(-1.5, 2.0, 0), Vector3(0.7, 4.0, 1.2), stone)
	U.box(root, Vector3(1.5, 2.0, 0), Vector3(0.7, 4.0, 1.2), stone)
	U.box(root, Vector3(0, 4.15, 0), Vector3(3.9, 0.7, 1.3), stone)
	U.box(root, Vector3(-1.5, 2.0, 0.62), Vector3(0.12, 3.4, 0.05), rune)
	U.box(root, Vector3(1.5, 2.0, 0.62), Vector3(0.12, 3.4, 0.05), rune)
	U.box(root, Vector3(0, 4.15, 0.67), Vector3(3.2, 0.1, 0.05), rune)
	# سطح الدوامة
	var sh := Shader.new()
	sh.code = "shader_type spatial;\nrender_mode unshaded, blend_add, cull_disabled, depth_draw_never;\nuniform vec4 col1 : source_color = vec4(0.65, 0.3, 1.0, 1.0);\nuniform vec4 col2 : source_color = vec4(0.25, 0.9, 1.0, 1.0);\nvoid fragment() {\n\tvec2 uv = UV * 2.0 - 1.0;\n\tfloat r = length(uv);\n\tfloat a = atan(uv.y, uv.x);\n\tfloat s1 = sin(a * 3.0 + r * 8.0 - TIME * 2.5) * 0.5 + 0.5;\n\tfloat s2 = sin(a * 5.0 - r * 12.0 + TIME * 1.7) * 0.5 + 0.5;\n\tfloat edge = smoothstep(1.0, 0.7, r);\n\tfloat core = smoothstep(0.9, 0.0, r);\n\tvec3 c = mix(col1.rgb, col2.rgb, s1 * s2) * (0.7 + core * 2.0);\n\tALBEDO = c;\n\tALPHA = edge * (0.4 + 0.6 * s1);\n}\n"
	var sm := ShaderMaterial.new()
	sm.shader = sh
	var q := U.quad(root, Vector3(0, 2.0, 0.1), Vector2(2.8, 3.8), sm)
	q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	goal_light = OmniLight3D.new()
	goal_light.light_color = Color("b98bff")
	goal_light.light_energy = 2.4
	goal_light.omni_range = 11.0
	goal_light.position = Vector3(0, 2.2, 2.0)
	root.add_child(goal_light)
	var ps := CPUParticles3D.new()
	ps.amount = 24
	ps.lifetime = 2.0
	ps.local_coords = false
	ps.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	ps.emission_box_extents = Vector3(1.2, 1.6, 0.2)
	ps.direction = Vector3(0, 1, 0)
	ps.spread = 30.0
	ps.initial_velocity_min = 0.3
	ps.initial_velocity_max = 0.9
	ps.gravity = Vector3.ZERO
	ps.scale_amount_min = 0.08
	ps.scale_amount_max = 0.18
	ps.color = Color(0.85, 0.65, 1.0, 1.0)
	var gr := Gradient.new()
	gr.offsets = PackedFloat32Array([0.0, 1.0])
	gr.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	ps.color_ramp = gr
	var qm := QuadMesh.new()
	qm.size = Vector2(1, 1)
	qm.material = mats.particle(Color(1, 1, 1, 1), true)
	ps.mesh = qm
	ps.position = Vector3(0, 2.0, 0.2)
	root.add_child(ps)

func _alpha(mi, a: float) -> void:
	var m = mi.material_override
	var c: Color = m.albedo_color
	c.a = a
	m.albedo_color = c

# ------------------------------------------------------------------ تحديث كل إطار
func update(dt: float) -> void:
	time_s += dt
	var px: float = sim.p.x + 7.0
	var py: float = sim.p.y + 11.0

	for i in range(ember_nodes.size()):
		var d: Dictionary = ember_nodes[i]
		var m = sim.embers[i]
		var root: Node3D = d["root"]
		root.visible = not m.taken
		if not m.taken:
			root.position.y = d["y0"] + sin(time_s * 2.6 + d["ph"]) * 0.14
			root.rotation.y = time_s * 2.0

	for i in range(enemy_nodes.size()):
		var d2: Dictionary = enemy_nodes[i]
		var e = sim.en[i]
		var root2: Node3D = d2["root"]
		if e.hp <= 0:
			root2.visible = false
			continue
		root2.visible = true
		root2.position = U.v(e.x + 9.0, e.y + 6.0, 0.0)
		var flash: bool = e.hit > 0 and e.kb > 0
		d2["mat"].emission = Color.WHITE if flash else Color.BLACK
		if d2["kind"] == 1:
			var flap: float = sin(time_s * 16.0 + float(i)) * 0.7
			for w in d2["wings"]:
				w[0].rotation = Vector3(w[1] * (0.25 + flap), 0.0, 0.0)
		else:
			d2["eye"].position = Vector3(0.3 * e.d, -0.08, 0.22)
			for lg in d2["legs"]:
				lg[0].rotation.z = sin(time_s * 12.0 + lg[1] * 2.0 + (0.0 if lg[0].position.z < 0.0 else 3.14)) * 0.5

	for i in range(crumb_nodes.size()):
		var d3: Dictionary = crumb_nodes[i]
		var c = sim.crums[i]
		var root3: Node3D = d3["root"]
		root3.visible = c.active
		if c.active:
			if c.timer >= 0:
				var k: float = 1.0 - float(c.timer) / 28.0
				root3.position = d3["base"] + Vector3((randf() - 0.5) * 0.09, (randf() - 0.5) * 0.06, 0.0)
				d3["crack"].emission_energy_multiplier = 0.4 + k * 3.5
			else:
				root3.position = d3["base"]
				d3["crack"].emission_energy_multiplier = 0.25

	for i in range(brk_nodes.size()):
		var d4: Dictionary = brk_nodes[i]
		var b = sim.brks[i]
		var root4: Node3D = d4["root"]
		root4.visible = b.alive
		if b.alive:
			if b.hit > 0:
				root4.position = d4["base"] + Vector3((randf() - 0.5) * 0.12, 0.0, 0.0)
			else:
				root4.position = d4["base"]

	for i in range(timed_nodes.size()):
		var d5: Dictionary = timed_nodes[i]
		var h = sim.timed_h[i]
		if d5["kind"] == 1:
			var grp: Node3D = d5["grp"]
			var target: float = 1.0 if h.on else (0.3 + randf() * 0.12 if h.warn else 0.01)
			grp.scale.y = lerpf(grp.scale.y, target, clampf(dt * (30.0 if h.on else 12.0), 0.0, 1.0))
			d5["slit"].emission_energy_multiplier = 0.2 + (2.5 if h.warn else 0.0) + (3.0 if h.on else 0.0)
			_alpha(d5["halo"], 0.35 if (h.warn or h.on) else 0.0)
		else:
			var on_now: bool = h.on
			var warn_flick: bool = h.warn and randf() < 0.35
			var show: bool = on_now or warn_flick
			d5["beam"].visible = show
			var hu: float = d5["hu"]
			for bt in d5["bolts"]:
				bt.visible = show
				if show:
					bt.position = Vector3(randf_range(-0.3, 0.3), randf_range(-hu * 0.06, hu * 0.06), randf_range(-0.1, 0.1))
					bt.rotation = Vector3(randf_range(-0.2, 0.2), 0.0, randf_range(-0.35, 0.35))
			d5["orb"].emission_energy_multiplier = 0.6 + (4.0 if on_now else (1.5 if h.warn else 0.0))
			_alpha(d5["halo"], 0.5 if on_now else (0.15 if warn_flick else 0.0))
			d5["light"].light_energy = (3.0 + randf() * 1.5) if on_now else 0.0

	for i in range(faller_nodes.size()):
		var d6: Dictionary = faller_nodes[i]
		var f = sim.fallers[i]
		var rock: Node3D = d6["rock"]
		var rm: StandardMaterial3D = d6["ring_mat"]
		if f.st == 2:
			rock.visible = true
			rock.position = U.v(f.x, f.y, 0.0)
			rock.rotation += Vector3(0.12, 0.08, 0.05)
		else:
			rock.visible = false
		if f.st == 1 or f.st == 2:
			var pulse: float = 0.5 + 0.5 * sin(time_s * 18.0)
			rm.albedo_color.a = 0.35 + pulse * 0.4
			d6["ring"].visible = true
			if f.st == 1 and f.tm % 6 == 0:
				fx.dust(Vector3(f.x * S + randf_range(-0.6, 0.6), 12.0, 0.0), 1)
		else:
			d6["ring"].visible = false

	for i in range(vanish_nodes.size()):
		var d7: Dictionary = vanish_nodes[i]
		var v = sim.vplats[i]
		var dist: float = Vector2(px - (v.x + v.w * 0.5), py - v.y).length()
		var reveal: float = clampf(1.0 - (dist - 60.0) / 150.0, 0.0, 1.0)
		var vm: StandardMaterial3D = d7["mat"]
		vm.albedo_color.a = 0.12 + reveal * 0.88
		vm.emission_energy_multiplier = 0.3 + reveal * 1.5
		d7["rune"].emission_energy_multiplier = 0.4 + reveal * 3.0

	for i in range(chest_nodes.size()):
		var d8: Dictionary = chest_nodes[i]
		var ch = sim.chests[i]
		var k2: float = clampf(float(ch.anim) / 30.0, 0.0, 1.0)
		if ch.open:
			k2 = maxf(k2, 0.05)
		d8["hinge"].rotation = Vector3(lerpf(0.0, -1.9, ease(k2, 0.4)), 0.0, 0.0)
		d8["light"].light_energy = k2 * 2.4
		_alpha(d8["halo"], k2 * 0.6)
		d8["inner"].emission_energy_multiplier = k2 * 3.0

	for d9 in check_nodes:
		var target2: float = 1.0 if d9["active"] else 0.12
		d9["level"] = lerpf(d9["level"], target2, clampf(dt * 4.0, 0.0, 1.0))
		var lv: float = d9["level"]
		d9["mat"].emission_energy_multiplier = 0.3 + lv * 3.6
		d9["light"].light_energy = lv * 2.0 * (1.0 + sin(time_s * 7.0) * 0.06)
		_alpha(d9["halo"], lv * 0.55)

	goal_light.light_energy = 2.4 + sin(time_s * 3.0) * 0.5

# ------------------------------------------------------------------ أحداث المحاكاة
func handle_event(ev: Array) -> void:
	var kind: String = ev[0]
	var pos: Vector3 = U.v(ev[1], ev[2], 0.5)
	var data = ev[3]
	match kind:
		"spark":
			var n: int = data[0]
			var col: Color = data[1]
			fx.burst(pos, col, n, 3.6, 0.22, 0.55, true, -3.0)
		"dust":
			fx.dust(pos, data)
		"land":
			fx.dust(pos, 6)
		"break":
			var col2: Color = sim.brk_color(data.kind)
			fx.chunks(pos, col2, 12, 0.3, 4.0)
			fx.flash(pos, Color("ffb347"), 1.6, 0.25)
		"drop":
			fx.burst(pos, Color("ffd98a"), 8, 2.0, 0.3, 0.9, true, 1.5)
		"crumble_fall":
			fx.chunks(pos, Color("6a6280"), 8, 0.4, 3.0)
		"crumble_back":
			var idx: int = sim.crums.find(data)
			if idx >= 0:
				var rt: Node3D = crumb_nodes[idx]["root"]
				rt.scale = Vector3(0.4, 0.4, 0.4)
				var tw := create_tween()
				tw.tween_property(rt, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		"rock_hit":
			fx.chunks(pos, Color("707484"), 7, 0.35, 3.5)
			fx.flash(pos, Color("ffb070"), 1.2, 0.2)
		"hurt":
			fx.burst(pos, Color("ff5a5a"), 16, 4.0, 0.3, 0.6, true, -2.0)
			fx.flash(pos, Color("ff4040"), 2.2, 0.3)
		"die":
			fx.burst(pos, Color("ffb347"), 60, 7.0, 0.35, 1.1, true, -2.0)
			fx.flash(pos, Color("ff9a45"), 3.5, 0.6, 10.0)
		"respawn":
			fx.burst(pos, Color("9fe8ff"), 30, 4.0, 0.3, 0.9, true, 0.5)
			fx.flash(pos, Color("9fe8ff"), 2.0, 0.5)
		"fell":
			fx.burst(pos, Color("ff6a2a"), 24, 5.0, 0.3, 0.8, true, -4.0)
		"dash":
			fx.burst(pos, Color("66aadd"), 10, 2.0, 0.25, 0.4, true, 0.0)
		"enemy_hit":
			fx.burst(pos, Color("ffd27a"), 12, 5.0, 0.2, 0.35, true, -6.0)
			fx.flash(pos, Color("ffc070"), 1.8, 0.15)
		"enemy_die":
			fx.burst(pos, Color("c58bff"), 30, 5.0, 0.35, 0.8, true, -3.0)
			fx.chunks(pos, Color("3a2548"), 8, 0.25, 4.0)
			fx.flash(pos, Color("c58bff"), 2.2, 0.35)
		"ember":
			fx.flash(pos, Color("ffb347"), 1.2, 0.18, 5.0)
		"heal":
			fx.burst(pos, Color("8dff9a"), 16, 2.5, 0.3, 0.9, true, 2.0)
		"chest":
			fx.burst(pos, Color("ffd27a"), 50, 6.0, 0.3, 1.0, true, -2.0)
			fx.flash(pos, Color("ffc24a"), 3.0, 0.6, 9.0)
		"checkpoint":
			var ci: int = data
			if ci >= 0 and ci < check_nodes.size():
				check_nodes[ci]["active"] = true
			fx.burst(pos + Vector3(0, 1.5, 0), Color("9fe8ff"), 30, 4.0, 0.3, 1.0, true, 0.5)
			fx.flash(pos + Vector3(0, 1.8, 0.5), Color("9fe8ff"), 2.5, 0.6)
		"win":
			fx.burst(pos, Color("e6c8ff"), 80, 8.0, 0.4, 1.4, true, -1.0)
			fx.flash(pos, Color("c8a0ff"), 4.0, 1.0, 12.0)
