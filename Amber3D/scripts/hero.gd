extends Node3D
# البطل: راكون بقبعة وعباءة وسيف، مبني من مجسمات إجرائية ويتحرك بمفاصل (ورك/كتف/ذيل/رأس).
# الوجه الأمامي للنموذج = محور X الموجب. زوايا الأطراف تأتي من sim.gd (نفس قيم النسخة 2D).

var mats
var yaw_a: float = 0.45          # زاوية النظر في المستوى XZ
var pivot: Node3D                 # يميل ويهتز
var torso: Node3D
var head: Node3D
var hat: Node3D
var arm_n: Node3D
var arm_f: Node3D
var leg_n: Node3D
var leg_f: Node3D
var tail: Array = []
var cloak: Node3D
var sword: Node3D
var slash: MeshInstance3D
var slash_mat: StandardMaterial3D
var body_mats: Array = []
var eye_l: MeshInstance3D
var eye_r: MeshInstance3D
var light: OmniLight3D
var t: float = 0.0

const FUR := Color("8b8f9c")
const FUR_DARK := Color("2b2d38")
const FUR_LIGHT := Color("d9dce6")
const CLOAK := Color("1b1722")
const CLOAK_IN := Color("5b2a3a")

func _mesh(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3 = Vector3.ZERO, rot: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	mi.scale = scl
	parent.add_child(mi)
	return mi

func _sphere(r: float, segs: int = 16) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = segs
	s.rings = int(segs / 2)
	return s

func _capsule(r: float, h: float) -> CapsuleMesh:
	var c := CapsuleMesh.new()
	c.radius = r
	c.height = h
	c.radial_segments = 12
	c.rings = 4
	return c

func _cyl(rt: float, rb: float, h: float, segs: int = 12) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = rt
	c.bottom_radius = rb
	c.height = h
	c.radial_segments = segs
	c.rings = 1
	return c

func _fur_mat(col: Color) -> StandardMaterial3D:
	var m: StandardMaterial3D = mats.plain(col, 0.85)
	return m

func build(m) -> void:
	mats = m
	# الأبعاد بوحدات العالم (1 وحدة = 20 بكسل). ارتفاع اللاعب الفيزيائي 1.1 وحدة.
	pivot = Node3D.new()
	add_child(pivot)

	# ---- الساقان (مفصل الورك عند الأعلى)
	leg_f = _make_leg(-0.12, 0.0)
	leg_n = _make_leg(0.12, 0.0)

	# ---- الجذع + العباءة
	torso = Node3D.new()
	torso.position = Vector3(0, 0.46, 0)
	pivot.add_child(torso)
	_mesh(torso, _capsule(0.22, 0.58), _fur_mat(FUR), Vector3(0, 0.12, 0))
	# بطن فاتح
	_mesh(torso, _sphere(0.15), _fur_mat(FUR_LIGHT), Vector3(0.12, 0.08, 0.0), Vector3.ZERO, Vector3(0.7, 1.15, 0.9))
	# حزام + إبزيم متوهج
	_mesh(torso, _cyl(0.235, 0.235, 0.07, 14), _fur_mat(Color("3a2a1e")), Vector3(0, -0.02, 0))
	_mesh(torso, _sphere(0.045, 8), mats.glow(Color("ffb347"), 2.5), Vector3(0.22, -0.02, 0.0))
	# عباءة خلفية
	cloak = Node3D.new()
	cloak.position = Vector3(-0.1, 0.34, 0)
	torso.add_child(cloak)
	var cm := _mesh(cloak, _cyl(0.1, 0.34, 0.9, 10), mats.plain(CLOAK, 0.9), Vector3(-0.06, -0.38, 0.0), Vector3(0, 0, 0.18), Vector3(0.7, 1.0, 1.05))
	cm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_mesh(cloak, _cyl(0.1, 0.34, 0.9, 10), mats.plain(CLOAK_IN, 0.9), Vector3(-0.045, -0.38, 0.0), Vector3(0, 0, 0.18), Vector3(0.62, 0.97, 0.95))

	# ---- الرأس
	head = Node3D.new()
	head.position = Vector3(0.04, 0.46, 0)
	torso.add_child(head)
	_mesh(head, _sphere(0.27, 20), _fur_mat(FUR), Vector3(0, 0.22, 0), Vector3.ZERO, Vector3(1.05, 0.95, 1.0))
	# الخطم
	_mesh(head, _sphere(0.12, 12), _fur_mat(FUR_LIGHT), Vector3(0.24, 0.14, 0), Vector3.ZERO, Vector3(1.25, 0.8, 0.85))
	_mesh(head, _sphere(0.05, 8), mats.plain(Color("0d0d12"), 0.3), Vector3(0.38, 0.17, 0))
	# قناع داكن حول العينين
	for z in [-0.14, 0.14]:
		_mesh(head, _sphere(0.1, 10), mats.plain(FUR_DARK, 0.9), Vector3(0.17, 0.25, z), Vector3.ZERO, Vector3(1.4, 0.8, 0.5))
	# العينان
	eye_l = _mesh(head, _sphere(0.045, 10), mats.glow(Color("fff2c8"), 1.6, 0.9), Vector3(0.24, 0.27, -0.15))
	eye_r = _mesh(head, _sphere(0.045, 10), mats.glow(Color("fff2c8"), 1.6, 0.9), Vector3(0.24, 0.27, 0.15))
	# الأذنان
	for z2 in [-0.19, 0.19]:
		_mesh(head, _cyl(0.0, 0.1, 0.17, 8), _fur_mat(FUR_DARK), Vector3(-0.02, 0.5, z2), Vector3(0.25 * signf(z2), 0, 0))
	# القبعة
	hat = Node3D.new()
	hat.position = Vector3(-0.01, 0.43, 0)
	head.add_child(hat)
	_mesh(hat, _cyl(0.36, 0.36, 0.035, 20), mats.plain(Color("141218"), 0.7), Vector3.ZERO)
	_mesh(hat, _cyl(0.2, 0.23, 0.22, 16), mats.plain(Color("1d1a24"), 0.7), Vector3(0, 0.12, 0))
	_mesh(hat, _cyl(0.235, 0.235, 0.05, 16), mats.plain(Color("a33b2c"), 0.6), Vector3(0, 0.05, 0))

	# ---- الذراعان (مفصل الكتف عند الأعلى)
	arm_f = _make_arm(-0.0, -0.2, false)
	arm_n = _make_arm(0.0, 0.2, true)

	# ---- الذيل المخطّط (سلسلة كرات)
	for i in range(6):
		var seg := Node3D.new()
		pivot.add_child(seg)
		var r: float = 0.15 - i * 0.008
		var col: Color = FUR_DARK if i % 2 == 1 else FUR_LIGHT
		_mesh(seg, _sphere(r, 10), _fur_mat(col), Vector3.ZERO, Vector3.ZERO, Vector3(1.3, 1.0, 1.0))
		tail.append(seg)

	# ---- ضوء الجمرة: يتبع البطل ويضيء الكهف بدفء
	light = OmniLight3D.new()
	light.light_color = Color("ffb066")
	light.light_energy = 1.7
	light.omni_range = 9.0
	light.omni_attenuation = 1.3
	light.shadow_enabled = false
	light.position = Vector3(0.3, 1.2, 1.5)
	add_child(light)

	# ---- أثر الضربة (قوس متوهج)
	slash_mat = mats.halo(Color("bdefff"), false)
	slash_mat.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED
	slash_mat.albedo_texture = null
	slash_mat.albedo_color = Color(0.75, 0.95, 1.0, 0.0)
	slash = MeshInstance3D.new()
	slash.mesh = _arc_mesh(0.7, 1.55, 2.2)
	slash.material_override = slash_mat
	slash.visible = false
	slash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(slash)

func _make_leg(z: float, x: float) -> Node3D:
	var hip := Node3D.new()
	hip.position = Vector3(x, 0.5, z)
	pivot.add_child(hip)
	_mesh(hip, _capsule(0.09, 0.5), _fur_mat(FUR_DARK), Vector3(0, -0.2, 0))
	_mesh(hip, _sphere(0.115, 10), _fur_mat(FUR_DARK), Vector3(0.06, -0.43, 0), Vector3.ZERO, Vector3(1.5, 0.7, 1.0))
	return hip

func _make_arm(x: float, z: float, with_sword: bool) -> Node3D:
	var sh := Node3D.new()
	sh.position = Vector3(x, 0.92, z)
	pivot.add_child(sh)
	_mesh(sh, _capsule(0.075, 0.46), _fur_mat(FUR_DARK), Vector3(0, -0.18, 0))
	_mesh(sh, _sphere(0.095, 10), _fur_mat(FUR_LIGHT), Vector3(0, -0.4, 0))
	if with_sword:
		sword = Node3D.new()
		sword.position = Vector3(0, -0.4, 0)
		sword.rotation = Vector3(0, 0, deg_to_rad(-135.0))
		sh.add_child(sword)
		_mesh(sword, _cyl(0.03, 0.03, 0.16, 8), mats.plain(Color("3a2a1e"), 0.6), Vector3(0, 0, 0))
		var guard := BoxMesh.new()
		guard.size = Vector3(0.05, 0.05, 0.3)
		_mesh(sword, guard, mats.plain(Color("c89b3c"), 0.35, 0.8), Vector3(0, 0.09, 0))
		var blade := BoxMesh.new()
		blade.size = Vector3(0.035, 0.85, 0.11)
		_mesh(sword, blade, mats.plain(Color("c9d6e6"), 0.2, 0.9), Vector3(0, 0.55, 0))
		var edge := BoxMesh.new()
		edge.size = Vector3(0.02, 0.8, 0.02)
		_mesh(sword, edge, mats.glow(Color("9fe8ff"), 2.2, 0.9), Vector3(0, 0.56, 0.058))
	return sh

# قوس الضربة: شريط مثلثات على شكل هلال
func _arc_mesh(r0: float, r1: float, span: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n: int = 16
	for i in range(n):
		var a0: float = -span * 0.5 + span * float(i) / n
		var a1: float = -span * 0.5 + span * float(i + 1) / n
		var p00 := Vector3(cos(a0) * r0, sin(a0) * r0, 0)
		var p01 := Vector3(cos(a0) * r1, sin(a0) * r1, 0)
		var p10 := Vector3(cos(a1) * r0, sin(a1) * r0, 0)
		var p11 := Vector3(cos(a1) * r1, sin(a1) * r1, 0)
		st.add_vertex(p00)
		st.add_vertex(p01)
		st.add_vertex(p11)
		st.add_vertex(p00)
		st.add_vertex(p11)
		st.add_vertex(p10)
	return st.commit()

# تحديث كل إطار: يستقبل حالة اللاعب من المحاكاة
func pose(p, dt: float, time_s: float) -> void:
	t = time_s
	# الاتجاه (التفاف سلس 3/4 نحو الكاميرا)
	var target: float = 0.45 if p.f > 0 else PI - 0.45
	yaw_a = lerp_angle(yaw_a, target, clampf(dt * 14.0, 0.0, 1.0))
	rotation.y = -yaw_a

	# ميلان واهتزاز وسحق/تمدد (squash & stretch)
	var sq: float = p.sq
	pivot.scale = Vector3(1.0 + sq * 0.35, 1.0 - sq * 0.45, 1.0 + sq * 0.35)
	pivot.position = Vector3(0, -p.bob * 0.05, 0)
	pivot.rotation.z = -p.lean * 0.9

	leg_n.rotation.z = -p.l_n
	leg_f.rotation.z = -p.l_f
	arm_n.rotation.z = -p.a_n
	arm_f.rotation.z = -p.a_f
	# مرجحة الجذع المعاكسة أثناء الجري
	torso.rotation.y = sin(p.anim) * 0.12 * (1.0 if absf(p.vx) > 0.5 else 0.0)
	head.rotation.z = -p.lean * 0.4 + (0.1 if not p.g and p.vy < 0.0 else 0.0)
	head.rotation.y = sin(t * 1.3) * 0.05

	# العباءة تتطاير بعكس الحركة
	var fly: float = clampf(-p.vx * 0.12 + (0.0 if p.g else clampf(-p.vy * 0.03, -0.3, 0.3)), -0.5, 0.5)
	cloak.rotation.z = 0.15 + fly * 0.6 + sin(t * 3.0) * 0.03

	# الذيل: موجة تتبع السرعة
	var amp: float = 0.25 + absf(p.vx) * 0.1
	for i in range(tail.size()):
		var seg: Node3D = tail[i]
		var k: float = float(i)
		var wave: float = sin(t * 4.0 - k * 0.8 + p.anim * 0.8)
		seg.position = Vector3(-0.2 - k * 0.15, 0.38 + k * 0.07 + wave * amp * 0.05 * k, wave * 0.04 * k)
		seg.rotation.z = 0.5 + wave * 0.1

	# وميض الضرر (إعادة الحصانة)
	pivot.visible = true
	if p.inv > 0 and ((p.inv >> 2) % 2 == 0):
		pivot.visible = false

	# أثر الضربة
	if p.atk > 8 and p.atk < 20:
		slash.visible = true
		var k2: float = 1.0 - absf(float(p.atk) - 14.0) / 6.0
		slash_mat.albedo_color = Color(0.75, 0.95, 1.0, clampf(k2, 0.0, 1.0) * 0.8)
		slash.position = Vector3(0.45, 0.62, 0.0)
		slash.rotation = Vector3(0.0, 0.0, deg_to_rad(-20.0) - (20.0 - p.atk) * 0.05)
		slash.scale = Vector3.ONE * (0.9 + (20.0 - p.atk) * 0.03)
	else:
		slash.visible = false

	# وهج العينين يزداد عند الضرر
	light.light_energy = 1.6 + sin(t * 5.0) * 0.12 + (1.2 if p.inv > 55 else 0.0)
