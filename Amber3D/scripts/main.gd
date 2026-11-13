extends Node3D
# نقطة الدخول: يجمع العالم والمحاكاة والبطل والكاميرا والواجهة، ويشغّل حلقة 60 خطوة/ثانية مع استيفاء للرسم.

const LevelData = preload("res://scripts/level_data.gd")
const Sim = preload("res://scripts/sim.gd")
const Mats = preload("res://scripts/mats.gd")
const WorldNode = preload("res://scripts/world.gd")
const View = preload("res://scripts/view.gd")
const Hero = preload("res://scripts/hero.gd")
const Fx = preload("res://scripts/fx.gd")
const Hud = preload("res://scripts/hud.gd")
const U = preload("res://scripts/util.gd")

const STEP := 1.0 / 60.0
const VIEW_H := 19.0      # ارتفاع ما تراه الكاميرا (وحدات) عند مستوى اللعب
const CAM_DIST := 26.0

var sim
var mats
var world
var view
var hero
var fx
var hud
var cam: Camera3D
var acc: float = 0.0
var cam_x: float = 0.0
var cam_y: float = 0.0
var prev_x: float = 0.0
var prev_y: float = 0.0
var time_s: float = 0.0
var shake_vec := Vector3.ZERO
var started := false

func _ready() -> void:
	get_viewport().msaa_3d = Viewport.MSAA_2X
	var level: Dictionary = LevelData.LEVEL
	mats = Mats.new()
	sim = Sim.new(level)

	world = WorldNode.new()
	add_child(world)
	world.build(level, mats)

	fx = Fx.new()
	add_child(fx)
	fx.setup(mats)

	view = View.new()
	add_child(view)
	view.build(sim, mats, fx)

	hero = Hero.new()
	add_child(hero)
	hero.build(mats)
	hero.scale = Vector3.ONE * 0.8

	cam = Camera3D.new()
	cam.fov = 2.0 * rad_to_deg(atan(VIEW_H * 0.5 / CAM_DIST))
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	cam.near = 1.0
	cam.far = 160.0
	add_child(cam)
	cam.make_current()

	var layer := CanvasLayer.new()
	add_child(layer)
	# تظليل الحواف (Vignette)
	var vg := ColorRect.new()
	vg.set_anchors_preset(Control.PRESET_FULL_RECT)
	vg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = "shader_type canvas_item;\nvoid fragment() {\n\tvec2 uv = UV - 0.5;\n\tfloat d = dot(uv, uv);\n\tfloat v = smoothstep(0.12, 0.62, d) * 0.6;\n\tCOLOR = vec4(0.0, 0.0, 0.03, v);\n}\n"
	var sm := ShaderMaterial.new()
	sm.shader = sh
	vg.material = sm
	layer.add_child(vg)

	var font: Font = load("res://fonts/DejaVuSans-Bold.ttf")
	hud = Hud.new()
	layer.add_child(hud)
	hud.setup(sim, font, level["name"])

	cam_x = sim.p.x + 7.0
	cam_y = 330.0
	prev_x = sim.p.x
	prev_y = sim.p.y
	_place_camera(0.0)

func _process(dt: float) -> void:
	dt = minf(dt, 0.05)
	time_s += dt

	var inp: Dictionary = hud.get_input()
	if hud.want_restart:
		get_tree().reload_current_scene()
		return
	sim.inp_left = inp["left"]
	sim.inp_right = inp["right"]
	sim.inp_jump = inp["jump"]
	sim.inp_atk = inp["atk"]
	sim.inp_dash = inp["dash"]

	acc += dt
	while acc >= STEP:
		prev_x = sim.p.x
		prev_y = sim.p.y
		sim.step()
		acc -= STEP
	var alpha: float = acc / STEP

	for ev in sim.events:
		view.handle_event(ev)
		if ev[0] == "respawn":
			prev_x = sim.p.x
			prev_y = sim.p.y
	sim.events.clear()

	# تموضع البطل مع استيفاء بين خطوتين
	var p = sim.p
	var rx: float = lerpf(prev_x, p.x, alpha)
	var ry: float = lerpf(prev_y, p.y, alpha)
	if absf(p.x - prev_x) > 60.0 or absf(p.y - prev_y) > 60.0:
		rx = p.x
		ry = p.y
	hero.position = U.v(rx + 7.0, ry + 22.0, 0.0)
	hero.visible = sim.phase != "dead"
	hero.pose(p, dt, time_s)

	view.update(dt)
	world.update(time_s)
	_update_camera(dt, rx, ry)
	fx.follow(cam.position)

func _update_camera(dt: float, rx: float, ry: float) -> void:
	var tx: float = rx + 7.0 + sim.p.f * 60.0
	tx = clampf(tx, 380.0, sim.length - 380.0)
	var ty: float = clampf(ry - 10.0, 235.0, 335.0)
	if sim.phase == "won":
		tx = sim.goal_x
	var kx: float = 1.0 - exp(-6.5 * dt)
	var ky: float = 1.0 - exp(-4.0 * dt)
	cam_x += (tx - cam_x) * kx
	cam_y += (ty - cam_y) * ky
	_place_camera(dt)

func _place_camera(dt: float) -> void:
	var sh: float = 0.0
	if sim.shake > 0:
		sh = float(sim.shake) * 0.035
	shake_vec = Vector3(randf_range(-sh, sh), randf_range(-sh, sh), 0.0)
	var focus: Vector3 = U.v(cam_x, cam_y, 0.0)
	var pos := focus + Vector3(0.0, 2.2, CAM_DIST) + shake_vec
	cam.look_at_from_position(pos, focus + Vector3(0.0, -0.3, 0.0) + shake_vec * 0.5, Vector3.UP)
