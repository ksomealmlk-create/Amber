extends Node3D
# العالم الثابت: بيئة الكهف (إضاءة، ضباب، توهج)، التضاريس، الصخور، البلورات، المشاعل، الحمم.

const U = preload("res://scripts/util.gd")
const S := 0.05

const ROCK_DARK := Color("1c2336")
const ROCK := Color("34405c")
const ROCK_LIGHT := Color("52607f")
const WALL := Color("151b2c")
const MOSS := Color("2fa58a")

var mats
var data: Dictionary
var length_u: float = 170.0
var ceil_y: float = 17.0
var rng := RandomNumberGenerator.new()
var torches: Array = []     # [{light, flame, base}]
var lava_mat: StandardMaterial3D
var crystal_lights: int = 0
var sun: DirectionalLight3D

func build(level: Dictionary, m) -> void:
	mats = m
	data = level
	rng.seed = 20261113
	length_u = float(level["length"]) * S
	# ارتفاع السقف يعلو أعلى منصة في المرحلة
	var top: float = 0.0
	for key in ["platforms", "vanish", "crumbs"]:
		for a in level[key]:
			top = maxf(top, U.wy(a[1]))
	for c in level["chests"]:
		top = maxf(top, U.wy(c[1]))
	ceil_y = maxf(17.0, top + 8.0)
	_environment()
	_shell()
	_terrain()
	_decor()

# ------------------------------------------------------------------ البيئة
func _environment() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("03050b")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("56689e")
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.1
	env.glow_enabled = true
	env.glow_intensity = 0.85
	env.glow_strength = 1.1
	env.glow_bloom = 0.06
	env.glow_hdr_threshold = 0.9
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	env.fog_enabled = true
	env.fog_light_color = Color("0c1830")
	env.fog_density = 0.0085
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.1
	env.adjustment_saturation = 1.18
	we.environment = env
	add_child(we)

	# ضوء قمري بارد من جهة الكاميرا (يرسم الظلال)
	sun = DirectionalLight3D.new()
	sun.light_color = Color("8fb0ff")
	sun.light_energy = 0.62
	sun.rotation_degrees = Vector3(-48.0, 28.0, 0.0)
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 70.0
	sun.shadow_blur = 1.4
	add_child(sun)

	# ضوء حافّة سماوي من الخلف يفصل الشخصية عن الخلفية
	var rim := DirectionalLight3D.new()
	rim.light_color = Color("4fe3c1")
	rim.light_energy = 0.45
	rim.rotation_degrees = Vector3(-18.0, 165.0, 0.0)
	rim.shadow_enabled = false
	add_child(rim)

# ------------------------------------------------------------------ القشرة (خلفية/سقف/أعمدة/حمم)
func _tiled(x0: float, x1: float, cy: float, h: float, cz: float, d: float, mat, tile: float = 8.0) -> void:
	var n: int = maxi(1, int(ceil((x1 - x0) / tile)))
	var w: float = (x1 - x0) / n
	for i in range(n):
		U.box(self, Vector3(x0 + w * (i + 0.5), cy, cz), Vector3(w + 0.02, h, d), mat)

func _shell() -> void:
	# جدار خلفي بعيد
	_tiled(-30.0, length_u + 30.0, 4.0, 52.0, -20.0, 1.0, mats.stone(WALL, 0.07, 1.0), 10.0)
	# سقف
	_tiled(-12.0, length_u + 12.0, ceil_y + 3.0, 6.0, -5.0, 22.0, mats.stone(ROCK_DARK, 0.15), 10.0)

	# أعمدة صخرية بعمق مختلف (بارالاكس حقيقي بسبب الكاميرا المنظورية)
	var x: float = -8.0
	while x < length_u + 8.0:
		var z: float = rng.randf_range(-15.0, -7.0)
		var w: float = rng.randf_range(2.5, 6.5)
		var h: float = rng.randf_range(16.0, 34.0)
		var d: float = rng.randf_range(2.5, 6.0)
		var shade: float = clampf(remap(z, -15.0, -7.0, 0.55, 1.0), 0.4, 1.0)
		var col := Color(ROCK_DARK.r * shade, ROCK_DARK.g * shade, ROCK_DARK.b * shade * 1.1)
		var mi: MeshInstance3D = U.box(self, Vector3(x, h * 0.5 - 12.0, z), Vector3(w, h, d), mats.stone(col, 0.12), Vector3(0.0, rng.randf_range(-0.5, 0.5), rng.randf_range(-0.04, 0.04)))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# بلورات بعيدة تتلألأ بين الأعمدة
		if rng.randf() < 0.55:
			var cc: Color = [Color("3fd4ff"), Color("7a6bff"), Color("4fe3c1")][rng.randi() % 3]
			var cz: float = z + d * 0.5 + 0.2
			for k in range(rng.randi_range(2, 4)):
				var ch: float = rng.randf_range(1.0, 3.2)
				var cm := U.cyl(self, Vector3(x + rng.randf_range(-w * 0.4, w * 0.4), rng.randf_range(-1.0, 7.0), cz), 0.0, rng.randf_range(0.2, 0.45), ch, mats.glow(cc, 2.4, 0.3), 6, Vector3(rng.randf_range(-0.3, 0.3), 0.0, rng.randf_range(-0.5, 0.5)))
				cm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		x += rng.randf_range(3.5, 7.5)

	# نواتئ السقف (stalactites) مع تجنّب مناطق المنصات العالية
	var high: Array = []
	for key in ["platforms", "vanish", "crumbs"]:
		for a in data[key]:
			if U.wy(a[1]) > 6.0:
				high.append([a[0] * S - 4.0, (a[0] + a[2]) * S + 4.0])
	for c in data["chests"]:
		high.append([c[0] * S - 4.0, c[0] * S + 5.0])
	var sx: float = 0.0
	while sx < length_u:
		sx += rng.randf_range(1.6, 4.2)
		var skip := false
		for hz in high:
			if sx > hz[0] and sx < hz[1]:
				skip = true
		if skip:
			continue
		var h2: float = rng.randf_range(1.5, 5.5)
		var r2: float = rng.randf_range(0.3, 0.8)
		var zz: float = rng.randf_range(-6.0, 1.0)
		U.cyl(self, Vector3(sx, ceil_y - h2 * 0.5, zz), r2, 0.0, h2, mats.stone(ROCK_DARK, 0.3), 6)

	# حمم/جمر متوهج في قاع الهاوية (سقوط = خسارة قلب)
	lava_mat = StandardMaterial3D.new()
	lava_mat.albedo_color = Color(0.25, 0.04, 0.02)
	lava_mat.emission_enabled = true
	lava_mat.emission = Color(1.0, 0.36, 0.08)
	lava_mat.emission_energy_multiplier = 1.8
	lava_mat.emission_texture = mats.stone_albedo
	lava_mat.uv1_scale = Vector3(0.2, 0.2, 1.0)
	lava_mat.roughness = 0.4
	var pm := PlaneMesh.new()
	pm.size = Vector2(length_u + 60.0, 26.0)
	var lava := U.mesh(self, pm, lava_mat, Vector3(length_u * 0.5, -5.0, -2.0))
	lava.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

# ------------------------------------------------------------------ التضاريس
func _terrain() -> void:
	var body_mat = mats.stone(ROCK_DARK, 0.18)
	var top_mat = mats.stone(ROCK, 0.3)
	var light_mat = mats.stone(ROCK_LIGHT, 0.35)
	var moss_mat = mats.glow(MOSS, 0.9, 0.25)

	var gs: Array = data["grounds"].duplicate()
	for g in gs:
		var x0: float = g[0] * S
		var x1: float = (g[0] + g[2]) * S
		# جسم الصخرة عميق ليبدو الجرف حقيقياً
		_tiled(x0, x1, -4.62, 9.2, 0.0, 8.0, body_mat, 8.0)
		# سطح المشي
		_tiled(x0, x1, -0.15, 0.3, 0.0, 8.2, top_mat, 8.0)
		# حافة أمامية متوهجة بطحلب
		U.box(self, Vector3((x0 + x1) * 0.5, 0.02, 4.12), Vector3(x1 - x0, 0.1, 0.12), moss_mat)
		# حجارة الرصف: خطوط عمق على السطح
		var px: float = x0 + 1.0
		while px < x1 - 0.5:
			U.box(self, Vector3(px, 0.005, rng.randf_range(-3.5, 3.5)), Vector3(rng.randf_range(0.6, 1.8), 0.02, 0.08), light_mat)
			px += rng.randf_range(0.8, 2.2)
		# صخور حافة الجرف (تكسر استقامة الحواف)
		for xe in [x0, x1]:
			for k in range(5):
				_boulder(Vector3(xe + rng.randf_range(-0.25, 0.25), rng.randf_range(-4.5, -0.3), rng.randf_range(-3.6, 3.8)), rng.randf_range(0.35, 0.9), body_mat)

	for p in data["platforms"]:
		var cx: float = (p[0] + p[2] * 0.5) * S
		var wu: float = p[2] * S
		var top: float = U.wy(p[1])
		U.box(self, Vector3(cx, top - 0.38, 0.0), Vector3(wu, 0.76, 3.4), top_mat)
		U.box(self, Vector3(cx, top + 0.02, 1.72), Vector3(wu, 0.09, 0.1), moss_mat)
		# خط رونيّ متوهج تحت المنصة
		U.box(self, Vector3(cx, top - 0.62, 1.72), Vector3(wu * 0.8, 0.05, 0.05), mats.glow(Color("4fe3c1"), 2.0, 0.3))
		# نتوء بلوري تحتها
		U.cyl(self, Vector3(cx + rng.randf_range(-wu * 0.3, wu * 0.3), top - 1.2, rng.randf_range(-0.6, 0.6)), 0.14, 0.0, 1.0, mats.glow(Color("4fe3c1"), 2.0, 0.3), 6)
		_boulder(Vector3(cx - wu * 0.5, top - 0.45, 0.2), 0.45, body_mat)
		_boulder(Vector3(cx + wu * 0.5, top - 0.45, -0.3), 0.4, body_mat)

	for e in data["extra"]:
		var x0: float = e[0] * S
		var wu2: float = e[2] * S
		var top_y: float = U.wy(e[1])
		var bot_y: float = U.wy(e[1] + e[3])
		var hanging: bool = e[1] < 120.0
		if hanging:
			top_y = maxf(top_y, ceil_y + 5.0)
		var hh: float = top_y - bot_y
		var cx2: float = x0 + wu2 * 0.5
		U.box(self, Vector3(cx2, bot_y + hh * 0.5, 0.0), Vector3(wu2, hh, 4.6), body_mat)
		if not hanging:
			U.box(self, Vector3(cx2, top_y - 0.15, 0.0), Vector3(wu2, 0.3, 4.8), top_mat)
			U.box(self, Vector3(cx2, top_y + 0.02, 2.4), Vector3(wu2, 0.1, 0.1), moss_mat)
		# صخور تكسر الشكل الصندوقي
		var nb: int = int(wu2 / 1.2) + 3
		for k in range(nb):
			var bx: float = x0 + rng.randf_range(0.0, wu2)
			_boulder(Vector3(bx, bot_y + rng.randf_range(0.0, hh), rng.randf_range(1.6, 2.6)), rng.randf_range(0.5, 1.1), body_mat)
		if hanging:
			# أسنان صخرية في الأسفل
			var tx: float = x0 + 0.5
			while tx < x0 + wu2 - 0.3:
				var th: float = rng.randf_range(0.6, 1.8)
				U.cyl(self, Vector3(tx, bot_y - th * 0.5 + 0.1, rng.randf_range(-1.5, 1.8)), rng.randf_range(0.25, 0.5), 0.0, th, body_mat, 6)
				tx += rng.randf_range(0.7, 1.5)

	# جدران البداية والنهاية
	U.box(self, Vector3(-3.0, 4.0, 0.0), Vector3(6.0, 40.0, 8.0), body_mat)
	U.box(self, Vector3(length_u + 3.0, 4.0, 0.0), Vector3(6.0, 40.0, 8.0), body_mat)

	# أضواء الهاوية: توهّج برتقالي يصعد على جدران الفجوات
	var sorted: Array = gs.duplicate()
	sorted.sort_custom(func(a, b): return a[0] < b[0])
	var lights: int = 0
	for i in range(sorted.size() - 1):
		var ga: float = sorted[i][0] + sorted[i][2]
		var gb: float = sorted[i + 1][0]
		if gb - ga > 40.0 and lights < 4:
			var l := OmniLight3D.new()
			l.light_color = Color("ff6a2a")
			l.light_energy = 2.2
			l.omni_range = 9.0
			l.position = Vector3((ga + gb) * 0.5 * S, -3.5, 1.5)
			add_child(l)
			lights += 1

func _boulder(pos: Vector3, r: float, mat) -> void:
	var mi: MeshInstance3D = U.sphere(self, pos, r, mat, Vector3(rng.randf_range(1.0, 1.5), rng.randf_range(0.7, 1.0), rng.randf_range(0.8, 1.2)), 8)
	mi.rotation = Vector3(rng.randf() * 3.0, rng.randf() * 3.0, rng.randf() * 3.0)

# ------------------------------------------------------------------ الزينة
func _decor() -> void:
	var rock_mat = mats.stone(ROCK_DARK, 0.3)
	var moss_mat = mats.glow(MOSS, 0.7, 0.2)
	var mush_cols: Array = [Color("4fe3c1"), Color("ff6aa8"), Color("ffb347"), Color("7a6bff")]
	var crystal_cols: Array = [Color("3fd4ff"), Color("4fe3c1"), Color("8a6bff"), Color("ff6aa8")]
	var hazard_ranges: Array = []
	for h in data["hazards"]:
		hazard_ranges.append([h[0] * S - 1.0, (h[0] + h[2]) * S + 1.0])

	var cluster_i: int = 0
	for g in data["grounds"]:
		var x0: float = g[0] * S
		var x1: float = (g[0] + g[2]) * S
		var x: float = x0 + 1.0
		while x < x1 - 1.0:
			x += rng.randf_range(1.4, 3.4)
			var r: float = rng.randf()
			if r < 0.34:
				# نتوءات صاعدة خلف البطل
				var h: float = rng.randf_range(0.6, 2.6)
				U.cyl(self, Vector3(x, h * 0.5, rng.randf_range(-3.6, -1.3)), 0.0, rng.randf_range(0.22, 0.6), h, rock_mat, 6)
			elif r < 0.52:
				# عنقود بلورات
				var col: Color = crystal_cols[rng.randi() % crystal_cols.size()]
				var with_light: bool = (cluster_i % 5 == 0) and crystal_lights < 6
				cluster_i += 1
				_crystals(Vector3(x, 0.0, rng.randf_range(-3.4, -1.5)), col, with_light)
			elif r < 0.7:
				# فطر متوهج
				var mc: Color = mush_cols[rng.randi() % mush_cols.size()]
				var behind: bool = rng.randf() < 0.6
				_mushroom(Vector3(x, 0.0, rng.randf_range(-3.2, -1.0) if behind else rng.randf_range(1.8, 3.4)), mc, rng.randf_range(0.6, 1.5) if behind else rng.randf_range(0.4, 0.8))
			elif r < 0.86:
				# حصى وصخور أمامية صغيرة
				var inrange := false
				for hr in hazard_ranges:
					if x > hr[0] and x < hr[1]:
						inrange = true
				if not inrange:
					_boulder(Vector3(x, 0.1, rng.randf_range(1.9, 3.6)), rng.randf_range(0.14, 0.34), rock_mat)
			else:
				# طحلب متوهج على الأرض
				U.sphere(self, Vector3(x, 0.02, rng.randf_range(-2.8, 3.2)), rng.randf_range(0.3, 0.7), moss_mat, Vector3(1.0, 0.12, 0.8), 8)

	# جذور متدلية من السقف
	var rx: float = 0.0
	while rx < length_u:
		rx += rng.randf_range(5.0, 11.0)
		var rl: float = rng.randf_range(2.0, 4.5)
		U.cyl(self, Vector3(rx, ceil_y - rl * 0.5, rng.randf_range(-4.0, -1.0)), 0.05, 0.03, rl, mats.plain(Color("1d1710"), 0.9), 5, Vector3(0.0, 0.0, rng.randf_range(-0.12, 0.12)))

	# مشاعل: ضوء دافئ يتراقص + جمرات صاعدة
	for g in data["grounds"]:
		var gx0: float = g[0] * S
		var gx1: float = (g[0] + g[2]) * S
		var tx: float = gx0 + 2.5
		while tx < gx1 - 1.5:
			_torch(Vector3(tx, 0.0, -2.4))
			tx += 14.0

func _crystals(pos: Vector3, col: Color, with_light: bool) -> void:
	var root := Node3D.new()
	root.position = pos
	add_child(root)
	_boulder_local(root, Vector3(0, 0.1, 0), 0.45)
	var n: int = rng.randi_range(3, 5)
	for i in range(n):
		var h: float = rng.randf_range(0.7, 2.0)
		var tilt: Vector3 = Vector3(rng.randf_range(-0.25, 0.25), 0.0, rng.randf_range(-0.45, 0.45))
		var c := U.cyl(root, Vector3(rng.randf_range(-0.3, 0.3), h * 0.5, rng.randf_range(-0.2, 0.2)), 0.0, rng.randf_range(0.12, 0.24), h, mats.glow(col, 2.6, 0.3), 6, tilt)
		c.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if with_light:
		var l := OmniLight3D.new()
		l.light_color = col
		l.light_energy = 1.3
		l.omni_range = 6.0
		l.position = Vector3(0.0, 1.0, 1.2)
		root.add_child(l)
		crystal_lights += 1

func _boulder_local(parent: Node, pos: Vector3, r: float) -> void:
	var mi: MeshInstance3D = U.sphere(parent, pos, r, mats.stone(ROCK_DARK, 0.4), Vector3(1.4, 0.8, 1.1), 7)
	mi.rotation = Vector3(0.0, rng.randf() * 3.0, 0.0)

func _mushroom(pos: Vector3, col: Color, scale_f: float) -> void:
	var root := Node3D.new()
	root.position = pos
	root.scale = Vector3.ONE * scale_f
	add_child(root)
	U.cyl(root, Vector3(0, 0.22, 0), 0.05, 0.08, 0.44, mats.plain(Color("c9c3b0"), 0.8), 6)
	var cap := U.dome(root, Vector3(0, 0.42, 0), 0.3, mats.glow(col, 2.0, 0.3), Vector3(1.0, 0.9, 1.0), 10)
	cap.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	U.sphere(root, Vector3(0.12, 0.55, 0.06), 0.04, mats.glow(Color("ffffff"), 2.0, 0.9), Vector3.ONE, 5)
	U.sphere(root, Vector3(-0.1, 0.52, -0.1), 0.035, mats.glow(Color("ffffff"), 2.0, 0.9), Vector3.ONE, 5)

func _torch(pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	add_child(root)
	U.cyl(root, Vector3(0, 0.7, 0), 0.13, 0.2, 1.4, mats.stone(ROCK, 0.5), 8)
	U.cyl(root, Vector3(0, 1.45, 0), 0.3, 0.16, 0.22, mats.plain(Color("3b3347"), 0.5, 0.7), 10)
	var flame := U.sphere(root, Vector3(0, 1.75, 0), 0.2, mats.glow(Color("ffa63a"), 3.2, 0.5), Vector3(0.8, 1.5, 0.8), 8)
	flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	U.halo(root, Vector3(0, 1.8, 0.2), 2.6, Color(1.0, 0.55, 0.2, 0.5), mats)
	var l := OmniLight3D.new()
	l.light_color = Color("ff9a45")
	l.light_energy = 2.0
	l.omni_range = 8.5
	l.omni_attenuation = 1.2
	l.position = Vector3(0, 1.9, 1.4)
	root.add_child(l)
	# جمرات صاعدة
	var ps := CPUParticles3D.new()
	ps.amount = 8
	ps.lifetime = 1.6
	ps.local_coords = false
	ps.direction = Vector3(0, 1, 0)
	ps.spread = 25.0
	ps.initial_velocity_min = 0.6
	ps.initial_velocity_max = 1.4
	ps.gravity = Vector3(0, 0.2, 0)
	ps.scale_amount_min = 0.05
	ps.scale_amount_max = 0.1
	ps.color = Color(1.0, 0.7, 0.3, 1.0)
	var gr := Gradient.new()
	gr.offsets = PackedFloat32Array([0.0, 1.0])
	gr.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	ps.color_ramp = gr
	var qm := QuadMesh.new()
	qm.size = Vector2(1, 1)
	qm.material = mats.particle(Color(1, 1, 1, 1), true)
	ps.mesh = qm
	ps.position = Vector3(0, 1.8, 0)
	root.add_child(ps)
	torches.append({"light": l, "flame": flame, "seed": rng.randf() * 10.0})

# ------------------------------------------------------------------ تحديث
func update(time_s: float) -> void:
	lava_mat.uv1_offset = Vector3(time_s * 0.012, time_s * 0.02, 0.0)
	lava_mat.emission_energy_multiplier = 1.6 + sin(time_s * 1.7) * 0.25
	for tdata in torches:
		var s: float = tdata["seed"]
		var f: float = 1.0 + sin(time_s * 11.0 + s) * 0.12 + sin(time_s * 23.0 + s * 2.0) * 0.08
		tdata["light"].light_energy = 2.0 * f
		tdata["flame"].scale = Vector3(0.8, 1.5 * f, 0.8)
