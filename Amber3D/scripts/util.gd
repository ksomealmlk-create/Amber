extends RefCounted
# أدوات بناء المجسمات وتحويل الإحداثيات (بكسل اللعبة الأصلي -> وحدات العالم 3D).

const S := 0.05          # وحدة العالم = 20 بكسل
const FLOOR_PX := 440.0  # سطح الأرض الأصلي => Y = 0

static func wx(px: float) -> float:
	return px * S

static func wy(py: float) -> float:
	return (FLOOR_PX - py) * S

static func v(px: float, py: float, z: float = 0.0) -> Vector3:
	return Vector3(px * S, (FLOOR_PX - py) * S, z)

static func mesh(parent: Node, m: Mesh, mat: Material, pos: Vector3 = Vector3.ZERO, rot: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	mi.scale = scl
	parent.add_child(mi)
	return mi

static func box(parent: Node, pos: Vector3, size: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var bm := BoxMesh.new()
	bm.size = size
	return mesh(parent, bm, mat, pos, rot)

static func sphere(parent: Node, pos: Vector3, r: float, mat: Material, scl: Vector3 = Vector3.ONE, segs: int = 10) -> MeshInstance3D:
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = segs
	sm.rings = maxi(3, int(segs / 2))
	return mesh(parent, sm, mat, pos, Vector3.ZERO, scl)

static func dome(parent: Node, pos: Vector3, r: float, mat: Material, scl: Vector3 = Vector3.ONE, segs: int = 12) -> MeshInstance3D:
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r
	sm.is_hemisphere = true
	sm.radial_segments = segs
	sm.rings = maxi(3, int(segs / 3))
	return mesh(parent, sm, mat, pos, Vector3.ZERO, scl)

static func cyl(parent: Node, pos: Vector3, rt: float, rb: float, h: float, mat: Material, segs: int = 8, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var cm := CylinderMesh.new()
	cm.top_radius = rt
	cm.bottom_radius = rb
	cm.height = h
	cm.radial_segments = segs
	cm.rings = 1
	return mesh(parent, cm, mat, pos, rot)

static func quad(parent: Node, pos: Vector3, size: Vector2, mat: Material) -> MeshInstance3D:
	var qm := QuadMesh.new()
	qm.size = size
	var mi := mesh(parent, qm, mat, pos)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi

static func halo(parent: Node, pos: Vector3, size: float, col: Color, mats) -> MeshInstance3D:
	return quad(parent, pos, Vector2(size, size), mats.halo(col))
