extends Node3D
# المؤثرات: انفجارات جسيمات، حطام يتطاير، ومضات ضوء، وغبار معلّق.

var mats
var debris: Array = []
var motes: CPUParticles3D
var flash_budget: int = 0

func setup(m) -> void:
	mats = m
	# غبار/شرر معلّق يتبع الكاميرا
	motes = CPUParticles3D.new()
	motes.amount = 90
	motes.lifetime = 9.0
	motes.preprocess = 9.0
	motes.local_coords = false
	motes.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	motes.emission_box_extents = Vector3(24.0, 9.0, 7.0)
	motes.direction = Vector3(0.2, 1.0, 0.0)
	motes.spread = 60.0
	motes.initial_velocity_min = 0.05
	motes.initial_velocity_max = 0.25
	motes.gravity = Vector3(0.0, 0.02, 0.0)
	motes.scale_amount_min = 0.05
	motes.scale_amount_max = 0.14
	motes.color = Color(1.0, 0.78, 0.5, 0.65)
	var gr := Gradient.new()
	gr.offsets = PackedFloat32Array([0.0, 0.2, 0.8, 1.0])
	gr.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	motes.color_ramp = gr
	var qm := QuadMesh.new()
	qm.size = Vector2(1, 1)
	qm.material = mats.particle(Color(1, 1, 1, 1), true)
	motes.mesh = qm
	motes.emitting = true
	add_child(motes)

func burst(pos: Vector3, col: Color, n: int, speed: float, size: float, life: float, additive: bool = true, gravity: float = -5.0) -> void:
	var ps := CPUParticles3D.new()
	ps.emitting = false
	ps.one_shot = true
	ps.amount = maxi(1, n)
	ps.lifetime = life
	ps.explosiveness = 0.95
	ps.local_coords = false
	ps.direction = Vector3(0, 1, 0)
	ps.spread = 180.0
	ps.initial_velocity_min = speed * 0.35
	ps.initial_velocity_max = speed
	ps.gravity = Vector3(0, gravity, 0)
	ps.scale_amount_min = size * 0.5
	ps.scale_amount_max = size
	ps.color = col
	var gr := Gradient.new()
	gr.offsets = PackedFloat32Array([0.0, 1.0])
	gr.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	ps.color_ramp = gr
	var qm := QuadMesh.new()
	qm.size = Vector2(1, 1)
	qm.material = mats.particle(Color(1, 1, 1, 1), additive)
	ps.mesh = qm
	ps.position = pos
	add_child(ps)
	ps.emitting = true
	get_tree().create_timer(life + 0.4).timeout.connect(ps.queue_free)

func dust(pos: Vector3, n: int) -> void:
	burst(pos, Color(0.62, 0.58, 0.55, 0.55), n, 1.6, 0.5, 0.7, false, 0.3)

func chunks(pos: Vector3, col: Color, n: int, size: float, power: float) -> void:
	var mat: StandardMaterial3D = mats.plain(col, 0.8)
	for i in range(n):
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		var s: float = size * randf_range(0.5, 1.2)
		bm.size = Vector3(s, s * randf_range(0.5, 1.0), s * randf_range(0.6, 1.0))
		mi.mesh = bm
		mi.material_override = mat
		mi.position = pos + Vector3(randf_range(-0.3, 0.3), randf_range(-0.2, 0.3), randf_range(-0.2, 0.2))
		add_child(mi)
		debris.append({
			"n": mi,
			"v": Vector3(randf_range(-1.0, 1.0) * power, randf_range(0.3, 1.2) * power, randf_range(-0.6, 0.8) * power),
			"w": Vector3(randf_range(-6.0, 6.0), randf_range(-6.0, 6.0), randf_range(-6.0, 6.0)),
			"life": randf_range(1.0, 1.7),
			"max": 1.7,
		})

func flash(pos: Vector3, col: Color, energy: float, dur: float, rng: float = 7.0) -> void:
	if flash_budget >= 4:
		return
	flash_budget += 1
	var l := OmniLight3D.new()
	l.light_color = col
	l.light_energy = energy
	l.omni_range = rng
	l.position = pos
	add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "light_energy", 0.0, dur)
	tw.tween_callback(func():
		flash_budget -= 1
		l.queue_free())

func follow(cam_pos: Vector3) -> void:
	if motes:
		motes.position = Vector3(cam_pos.x, cam_pos.y, -1.0)

func _process(dt: float) -> void:
	var i: int = debris.size() - 1
	while i >= 0:
		var d: Dictionary = debris[i]
		var n: MeshInstance3D = d["n"]
		d["life"] = d["life"] - dt
		if d["life"] <= 0.0:
			n.queue_free()
			debris.remove_at(i)
		else:
			var v: Vector3 = d["v"]
			v.y -= 14.0 * dt
			d["v"] = v
			n.position += v * dt
			n.rotation += d["w"] * dt
			var k: float = clampf(d["life"] / 0.5, 0.0, 1.0)
			n.scale = Vector3.ONE * k
		i -= 1
