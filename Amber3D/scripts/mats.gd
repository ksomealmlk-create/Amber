extends RefCounted
# مصنع المواد: صخور بخامة إجرائية (Triplanar + Normal) ومواد متوهجة وهالات ضوئية.

var stone_albedo: ImageTexture
var stone_normal: ImageTexture
var halo_tex: GradientTexture2D
var cache := {}

func _init():
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_CELLULAR
	n.frequency = 0.035
	n.fractal_type = FastNoiseLite.FRACTAL_FBM
	n.fractal_octaves = 4
	n.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB
	var img: Image = n.get_seamless_image(256, 256)
	img.convert(Image.FORMAT_RGBA8)
	stone_albedo = ImageTexture.create_from_image(img)
	var bump := Image.new()
	bump.copy_from(img)
	bump.bump_map_to_normal_map(6.0)
	stone_normal = ImageTexture.create_from_image(bump)

	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.3, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.32), Color(1, 1, 1, 0)])
	halo_tex = GradientTexture2D.new()
	halo_tex.gradient = g
	halo_tex.fill = GradientTexture2D.FILL_RADIAL
	halo_tex.fill_from = Vector2(0.5, 0.5)
	halo_tex.fill_to = Vector2(1.0, 0.5)
	halo_tex.width = 128
	halo_tex.height = 128

func stone(col: Color, tri_scale: float = 0.3, rough: float = 0.92) -> StandardMaterial3D:
	var key := "stone_%s_%s_%s" % [col.to_html(), tri_scale, rough]
	if cache.has(key):
		return cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.albedo_texture = stone_albedo
	m.normal_enabled = true
	m.normal_texture = stone_normal
	m.normal_scale = 1.2
	m.roughness = rough
	m.metallic = 0.0
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(tri_scale, tri_scale, tri_scale)
	cache[key] = m
	return m

func plain(col: Color, rough: float = 0.8, metal: float = 0.0) -> StandardMaterial3D:
	var key := "plain_%s_%s_%s" % [col.to_html(), rough, metal]
	if cache.has(key):
		return cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	m.metallic = metal
	cache[key] = m
	return m

func glow(col: Color, energy: float = 2.0, base: float = 0.25) -> StandardMaterial3D:
	var key := "glow_%s_%s_%s" % [col.to_html(), energy, base]
	if cache.has(key):
		return cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(col.r * base, col.g * base, col.b * base, 1.0)
	m.roughness = 0.35
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = energy
	cache[key] = m
	return m

func glow_unique(col: Color, energy: float = 2.0) -> StandardMaterial3D:
	# مادة مستقلة (تُعدَّل لاحقاً أثناء اللعب)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(col.r * 0.25, col.g * 0.25, col.b * 0.25, 1.0)
	m.roughness = 0.35
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = energy
	return m

func halo(col: Color, billboard: bool = true) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = col
	m.albedo_texture = halo_tex
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.disable_receive_shadows = true
	m.no_depth_test = false
	if billboard:
		m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	return m

func particle(col: Color, additive: bool = true) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if additive else BaseMaterial3D.BLEND_MODE_MIX
	m.albedo_color = col
	m.albedo_texture = halo_tex
	m.vertex_color_use_as_albedo = true
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.particles_anim_h_frames = 1
	m.particles_anim_v_frames = 1
	m.disable_receive_shadows = true
	return m
