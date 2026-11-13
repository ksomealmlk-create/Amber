extends CharacterBody3D

@export var move_speed: float = 7.0
@export var acceleration: float = 22.0
@export var jump_velocity: float = 8.5
@export var mouse_sensitivity: float = 0.003
var gravity: float = 22.0
var camera_yaw: float = 0.0
var camera_pitch: float = -0.18
var camera_pivot: Node3D
var camera: Camera3D
var visual: Node3D

func _ready() -> void:
	add_to_group("player")
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.8
	var collider := CollisionShape3D.new()
	collider.shape = capsule
	collider.position.y = 0.92
	add_child(collider)
	_build_character()
	camera_pivot = Node3D.new()
	camera_pivot.position = Vector3(0, 1.45, 0)
	add_child(camera_pivot)
	camera = Camera3D.new()
	camera.position = Vector3(0, 1.1, 5.8)
	camera.fov = 72
	camera.current = true
	camera_pivot.add_child(camera)
	camera_pivot.rotation.x = camera_pitch
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if not OS.has_feature("mobile") else Input.MOUSE_MODE_VISIBLE

func _build_character() -> void:
	visual = Node3D.new()
	add_child(visual)
	_add_mesh(visual, CapsuleMesh.new(), Vector3(0, 0.95, 0), Vector3(0.43, 0.55, 0.43), Color(0.16, 0.19, 0.24))
	_add_mesh(visual, SphereMesh.new(), Vector3(0, 1.68, 0), Vector3(0.32, 0.32, 0.32), Color(0.83, 0.63, 0.43))
	_add_mesh(visual, BoxMesh.new(), Vector3(0, 1.05, -0.31), Vector3(0.25, 0.24, 0.08), Color(1.0, 0.42, 0.08))
	_add_mesh(visual, BoxMesh.new(), Vector3(-0.52, 1.0, 0), Vector3(0.16, 0.55, 0.18), Color(0.13, 0.16, 0.2))
	_add_mesh(visual, BoxMesh.new(), Vector3(0.52, 1.0, 0), Vector3(0.16, 0.55, 0.18), Color(0.13, 0.16, 0.2))
	_add_mesh(visual, BoxMesh.new(), Vector3(-0.2, 0.28, 0), Vector3(0.2, 0.55, 0.22), Color(0.09, 0.11, 0.15))
	_add_mesh(visual, BoxMesh.new(), Vector3(0.2, 0.28, 0), Vector3(0.2, 0.55, 0.22), Color(0.09, 0.11, 0.15))

func _add_mesh(parent: Node3D, mesh: Mesh, pos: Vector3, scale_value: Vector3, color: Color) -> void:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = pos
	node.scale = scale_value
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.82
	node.material_override = mat
	parent.add_child(node)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera_yaw -= event.relative.x * mouse_sensitivity
		camera_pitch = clamp(camera_pitch - event.relative.y * mouse_sensitivity, -0.85, 0.28)
		camera_pivot.rotation = Vector3(camera_pitch, camera_yaw, 0)
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not OS.has_feature("mobile"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var basis := camera_pivot.global_transform.basis
	var forward := -basis.z
	var right := basis.x
	forward.y = 0
	right.y = 0
	forward = forward.normalized()
	right = right.normalized()
	var direction := (right * input.x + forward * input.y).normalized()
	var target := direction * move_speed
	velocity.x = move_toward(velocity.x, target.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target.z, acceleration * delta)
	if direction.length() > 0.1:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-direction.x, -direction.z), 12.0 * delta)
	move_and_slide()
	camera_pivot.global_position = global_position + Vector3(0, 1.45, 0)
