extends Node3D

const PlayerScript = preload("res://scripts/player.gd")
const SAVE_PATH := "user://amber_progress.cfg"
const LEVELS_PER_WORLD := 10
const TOTAL_LEVELS := 110

var player: CharacterBody3D
var crystals := 0
var level_index := 1
var completed := {}
var hud_label: Label
var hint_label: Label
var level_root: Node3D
var world_names := ["Forgotten Cavern", "Cursed Forest", "Poison Mushroom Cave", "Skeleton Castle", "Lava Kingdom", "Ice Kingdom", "Ancient Cemetery", "Temple of Secrets", "Crystal Mine", "Dark Castle", "The Final World"]
var world_colors := [Color(0.19,0.22,0.28), Color(0.12,0.25,0.16), Color(0.28,0.19,0.31), Color(0.25,0.24,0.28), Color(0.38,0.12,0.055), Color(0.18,0.34,0.45), Color(0.22,0.23,0.25), Color(0.35,0.27,0.16), Color(0.12,0.28,0.34), Color(0.13,0.10,0.19), Color(0.28,0.12,0.16)]
var world_accents := [Color(0.55,0.66,0.78), Color(0.28,0.72,0.38), Color(0.72,0.38,0.78), Color(0.72,0.76,0.82), Color(1.0,0.30,0.08), Color(0.45,0.82,1.0), Color(0.58,0.62,0.68), Color(0.92,0.68,0.28), Color(0.25,0.88,0.95), Color(0.55,0.32,0.82), Color(1.0,0.48,0.28)]

func _ready() -> void:
	_load_progress()
	_build_environment()
	_build_player()
	_build_hud()
	_load_level(level_index)

func _build_environment() -> void:
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.025, 0.035, 0.07)
	sky_mat.sky_horizon_color = Color(0.12, 0.11, 0.16)
	sky.sky_material = sky_mat
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.42, 0.46, 0.58)
	environment.ambient_light_energy = 0.7
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = environment
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	add_child(sun)

func _load_level(index: int) -> void:
	level_index = clampi(index, 1, TOTAL_LEVELS)
	if is_instance_valid(level_root):
		level_root.queue_free()
	level_root = Node3D.new()
	level_root.name = "World_%02d_Level_%02d" % [_world_id() + 1, _level_in_world()]
	add_child(level_root)
	crystals = 0
	var wid := _world_id()
	var accent: Color = world_accents[wid]
	var base: Color = world_colors[wid]
	_build_world_floor(base, wid)
	_build_level_layout(base, accent, wid, _level_in_world())
	_build_world_decor(base, accent, wid)
	_build_exit_gate(accent)
	player.global_position = Vector3(-31, 1.2, 0)
	player.velocity = Vector3.ZERO
	_update_hud()

func _world_id() -> int:
	return int((level_index - 1) / LEVELS_PER_WORLD)

func _level_in_world() -> int:
	return ((level_index - 1) % LEVELS_PER_WORLD) + 1

func _build_world_floor(base: Color, wid: int) -> void:
	_add_box(Vector3(0, -1.0, 0), Vector3(78, 1.5, 58), base.darkened(0.42), true)
	# A broad playable area gives the third-person camera room to move in depth.
	_add_box(Vector3(0, -0.05, 0), Vector3(70, 0.18, 50), base.darkened(0.18), true)
	for side in [-1.0, 1.0]:
		_add_box(Vector3(0, 1.2, side * 26.0), Vector3(74, 2.4, 1.2), base.darkened(0.3), true)

func _build_level_layout(base: Color, accent: Color, wid: int, lev: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(level_index * 7919 + wid * 101)
	# Ten distinct route grammars, repeated with world-specific hazards and geometry.
	var pattern := (lev - 1) % 10
	for i in range(10):
		var t := float(i) / 9.0
		var x := -27.0 + t * 54.0
		var z := 0.0
		var y := 0.35
		match pattern:
			0: z = sin(t * PI * 2.0) * 7.0; y = 0.3 + float(i % 3) * 0.45
			1: z = -10.0 if i % 2 == 0 else 10.0; y = 0.45 + float(i % 2) * 0.75
			2: z = -12.0 + t * 24.0; y = 0.35 + sin(t * PI) * 2.0
			3: z = sin(t * PI * 4.0) * 11.0; y = 0.4 + float(i % 2) * 0.8
			4: z = 0.0 if i % 2 == 0 else (9.0 if i % 4 == 1 else -9.0); y = 0.4 + float(i % 3) * 0.65
			5: z = cos(t * PI * 2.0) * 13.0; y = 0.45 + float(i % 3) * 0.5
			6: z = -14.0 + float(i % 4) * 9.0; y = 0.35 + float((i * 2) % 4) * 0.48
			7: z = sin(t * PI * 3.0) * 8.0; y = 0.4 + (1.0 - abs(0.5 - t) * 2.0) * 1.8
			8: z = rng.randf_range(-13.0, 13.0); y = 0.35 + rng.randf_range(0.0, 1.8)
			9: z = 0.0; y = 0.35 + (1.0 if i % 2 == 0 else 2.0) + float(i % 3) * 0.25
		var size := Vector3(4.8 if pattern not in [8] else 4.0, 0.85, 5.0 if pattern in [1,4] else 4.2)
		_add_box(Vector3(x, y, z), size, base.lightened(0.12 + float(i % 3) * 0.07), true)
		if i % 2 == 0 or pattern == 8:
			_add_crystal(Vector3(x, y + 1.35, z), accent)
		if (i + lev + wid) % 3 == 0:
			_add_spikes(Vector3(x + 1.0, y + 0.8, z + 1.0), accent)
		if i in [2, 5, 8] and pattern in [2, 3, 5, 7, 9]:
			_add_box(Vector3(x, y + 2.2, z - 4.0), Vector3(3.2, 0.45, 2.0), accent.darkened(0.15), true)
	# Add level-specific side routes, cover, and hazards; later stages add more pressure.
	for j in range(2 + int(lev / 3)):
		var hx := rng.randf_range(-21.0, 21.0)
		var hz := rng.randf_range(-17.0, 17.0)
		if j % 2 == 0:
			_add_spikes(Vector3(hx, 0.45, hz), accent)
		else:
			_add_box(Vector3(hx, 1.0 + float(lev % 3) * 0.3, hz), Vector3(2.8, 2.0, 2.8), base.lightened(0.25), true)
	for e in range(1 + int(lev / 4)):
		_add_enemy(Vector3(-12.0 + e * (22.0 / max(1, int(lev / 4))), 0.15, 8.0 if e % 2 == 0 else -8.0), accent)
	# A larger arena and guardian on the final level of every world.
	if lev == 10:
		_add_box(Vector3(24.0, 0.25, 0), Vector3(9, 0.8, 15), accent.darkened(0.28), true)
		_add_enemy(Vector3(23.0, 0.2, 0), accent, true)

func _build_world_decor(base: Color, accent: Color, wid: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = level_index * 31337
	for i in range(34):
		var x := rng.randf_range(-35.0, 35.0)
		var z := rng.randf_range(-23.0, 23.0)
		if abs(x) < 7.0 and abs(z) < 7.0:
			continue
		if wid in [1, 4, 5, 6, 9]:
			_add_rock(Vector3(x, 0, z), base, accent)
		else:
			_add_tree(Vector3(x, 0, z), base, accent)
	# World identity landmarks.
	for i in range(5):
		var px := -28.0 + i * 14.0
		_add_box(Vector3(px, 3.0, -22.5), Vector3(1.4, 6.0, 1.4), accent.darkened(0.2), true)

func _add_tree(pos: Vector3, tint: Color, accent: Color) -> void:
	_add_mesh(CylinderMesh.new(), pos + Vector3(0, 1.6, 0), Vector3(0.45, 1.7, 0.45), Color(0.22, 0.13, 0.09))
	_add_mesh(SphereMesh.new(), pos + Vector3(0, 3.2, 0), Vector3(1.8, 2.2, 1.7), tint.lightened(0.28))

func _add_rock(pos: Vector3, tint: Color, accent: Color) -> void:
	_add_mesh(SphereMesh.new(), pos + Vector3(0, 0.8, 0), Vector3(1.2, 1.0, 1.0), tint.lightened(0.18))
	if int(abs(pos.x * 10.0)) % 3 == 0:
		_add_mesh(CapsuleMesh.new(), pos + Vector3(0, 1.8, 0), Vector3(0.28, 0.85, 0.28), accent)

func _add_crystal(pos: Vector3, tint: Color) -> void:
	var crystal := _mesh_node(CapsuleMesh.new(), pos, Vector3(0.34, 0.9, 0.34), tint)
	crystal.rotation_degrees = Vector3(0, 0, 18)
	var area := Area3D.new()
	area.position = pos
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.0
	shape.shape = sphere
	area.add_child(shape)
	area.body_entered.connect(_on_crystal_collected.bind(area))
	level_root.add_child(area)

func _on_crystal_collected(body: Node3D, area: Area3D) -> void:
	if body == player:
		crystals += 1
		area.queue_free()
		_update_hud()

func _add_spikes(pos: Vector3, tint: Color) -> void:
	var hazard := _mesh_node(ConeMesh.new(), pos, Vector3(0.8, 0.9, 0.8), Color(0.9, 0.12, 0.08))
	hazard.name = "SpikeHazard"
	var body := StaticBody3D.new()
	body.position = pos
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.0, 0.7, 1.0)
	col.shape = shape
	col.position.y = 0.25
	body.add_child(col)
	level_root.add_child(body)

func _add_enemy(pos: Vector3, tint: Color, boss: bool = false) -> void:
	var enemy := CharacterBody3D.new()
	enemy.position = pos
	var mesh := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.55 if boss else 0.42
	capsule.height = 2.1 if boss else 1.5
	mesh.mesh = capsule
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint.lightened(0.18) if boss else Color(0.72, 0.78, 0.68)
	mesh.material_override = mat
	mesh.position.y = 1.0 if boss else 0.75
	enemy.add_child(mesh)
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.55 if boss else 0.42
	shape.height = 2.1 if boss else 1.5
	col.shape = shape
	col.position.y = mesh.position.y
	enemy.add_child(col)
	var mover := GDScript.new()
	mover.source_code = "extends CharacterBody3D\nvar origin := Vector3.ZERO\nvar clock := 0.0\nfunc _ready(): origin = position\nfunc _physics_process(delta):\n clock += delta\n position.x = origin.x + sin(clock * 1.15) * 3.0\n position.z = origin.z + cos(clock * 0.8) * 1.4\n"
	mover.reload()
	enemy.set_script(mover)
	level_root.add_child(enemy)

func _build_exit_gate(tint: Color) -> void:
	var gate := Area3D.new()
	gate.position = Vector3(31.0, 2.0, 0)
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = tint
	ring_mat.emission_enabled = true
	ring_mat.emission = tint
	for p in [Vector3(-1.6, 0, 0), Vector3(1.6, 0, 0)]:
		var pillar := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.25
		mesh.bottom_radius = 0.38
		mesh.height = 4.0
		pillar.mesh = mesh
		pillar.position = p
		pillar.material_override = ring_mat
		gate.add_child(pillar)
	var top := MeshInstance3D.new()
	var beam := BoxMesh.new()
	beam.size = Vector3(0.55, 0.55, 3.5)
	top.mesh = beam
	top.position.y = 2.0
	top.material_override = ring_mat
	gate.add_child(top)
	var col := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 2.2
	col.shape = sphere
	gate.add_child(col)
	gate.body_entered.connect(_on_gate_entered)
	level_root.add_child(gate)

func _on_gate_entered(body: Node3D) -> void:
	if body != player:
		return
	completed[str(level_index)] = true
	_save_progress()
	if level_index < TOTAL_LEVELS:
		_load_level(level_index + 1)
	else:
		hint_label.text = "All 110 levels complete! You finished Amber 3D."

func _add_box(pos: Vector3, size: Vector3, color: Color, collision: bool) -> void:
	var node: Node3D
	if collision:
		node = StaticBody3D.new()
	else:
		node = Node3D.new()
	node.position = pos
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	mesh.material_override = mat
	node.add_child(mesh)
	if collision:
		var shape := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = size
		shape.shape = box_shape
		node.add_child(shape)
	level_root.add_child(node)

func _add_mesh(mesh_data: Mesh, pos: Vector3, scale_value: Vector3, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh_data
	node.position = pos
	node.scale = scale_value
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.78
	node.material_override = mat
	level_root.add_child(node)
	return node

func _mesh_node(mesh_data: Mesh, pos: Vector3, scale_value: Vector3, color: Color) -> MeshInstance3D:
	return _add_mesh(mesh_data, pos, scale_value, color)

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.set_script(PlayerScript)
	player.position = Vector3(-31, 1.2, 0)
	add_child(player)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(18, 18)
	panel.custom_minimum_size = Vector2(440, 92)
	layer.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	hud_label = Label.new()
	hud_label.add_theme_font_size_override("font_size", 18)
	box.add_child(hud_label)
	hint_label = Label.new()
	hint_label.text = "Explore freely • Reach the glowing gate to finish each level"
	hint_label.add_theme_font_size_override("font_size", 14)
	box.add_child(hint_label)
	var prev := Button.new()
	prev.text = "Previous level"
	prev.position = Vector2(18, 125)
	prev.pressed.connect(func(): _load_level(max(1, level_index - 1)))
	layer.add_child(prev)
	var next := Button.new()
	next.text = "Next level (test)"
	next.position = Vector2(150, 125)
	next.pressed.connect(func(): _load_level(min(TOTAL_LEVELS, level_index + 1)))
	layer.add_child(next)
	var directions := [["◀", "move_left"], ["▶", "move_right"], ["▲", "move_forward"], ["▼", "move_back"], ["JUMP", "jump"]]
	for i in range(directions.size()):
		var button := Button.new()
		button.text = directions[i][0]
		button.custom_minimum_size = Vector2(66, 58)
		button.position = Vector2(22 + (i % 3) * 72, 540 + int(i / 3) * 68)
		if i == 4:
			button.position = Vector2(1090, 585)
		var action: String = directions[i][1]
		button.button_down.connect(func(): Input.action_press(action))
		button.button_up.connect(func(): Input.action_release(action))
		layer.add_child(button)

func _update_hud() -> void:
	if hud_label:
		var w := _world_id() + 1
		hud_label.text = "AMBER 3D | %02d/11 %s | Level %02d/10 | Crystals: %d | Completed: %d/110" % [w, world_names[w - 1], _level_in_world(), crystals, completed.size()]

func _load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		var values: Array = cfg.get_value("progress", "completed", [])
		for value in values:
			completed[str(value)] = true

func _save_progress() -> void:
	var cfg := ConfigFile.new()
	var values: Array = []
	for key in completed.keys():
		values.append(key)
	cfg.set_value("progress", "completed", values)
	cfg.save(SAVE_PATH)
