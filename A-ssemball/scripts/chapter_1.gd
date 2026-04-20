extends Control
class_name Chapter1

@export var light_rotation_speed_deg: float = 0.0
@export var light_energy: float = 0.85
@export_range(4, 256, 1) var left_sphere_face_count: int = 12
@export_range(1, 64, 1) var left_sphere_gp_m: int = 1
@export_range(0, 64, 1) var left_sphere_gp_n: int = 0
@export var sphere_rotate_speed_deg: float = 120.0
@export var distortion_fade_duration_sec: float = 5.0
@export var polyhedron_edge_color: Color = Color(0.58, 0.58, 0.58, 1.0)
@export_range(1.0, 1.05, 0.001) var polyhedron_edge_thickness_scale: float = 1.008
@export_range(1.0, 8.0, 0.1) var polyhedron_edge_line_width: float = 2.0

@onready var chapter_1_split: HSplitContainer = $Chapter1Split
@onready var sphere: MeshInstance3D = $Chapter1Split/Left3D/LeftViewport/World3D/ModelRoot/Dodecahedron
@onready var marker: MeshInstance3D = $Chapter1Split/Left3D/LeftViewport/World3D/ModelRoot/Dodecahedron/Marker
@onready var right_panel: ColorRect = $Chapter1Split/RightPanel
@onready var line_canvas: LineCanvas2D = $Chapter1Split/RightPanel/LineCanvas
@onready var dir_light: DirectionalLight3D = $Chapter1Split/Left3D/LeftViewport/World3D/DirectionalLight3D

var _distortion_elapsed_sec: float = 0.0
var _distortion_material: ShaderMaterial
var _polyhedron_edge_material: StandardMaterial3D
var _edge_overlay_instance: MeshInstance3D


func _ready() -> void:
	_ensure_edge_overlay_instance()
	set_left_sphere_gp(left_sphere_gp_m, left_sphere_gp_n)
	_setup_default_sphere_material()
	_sync_marker_with_dodecahedron()
	_setup_right_placeholder_scene_1()
	_distortion_elapsed_sec = 0.0
	dir_light.light_energy = light_energy

	resized.connect(_on_layout_changed)
	chapter_1_split.dragged.connect(_on_chapter_1_split_dragged)
	_on_layout_changed()


func _process(delta: float) -> void:
	_update_sphere_wasd_rotate(delta)
	_update_right_distortion_fade(delta)
	_apply_edge_outline_style()
	if light_rotation_speed_deg != 0.0:
		dir_light.rotate_y(deg_to_rad(light_rotation_speed_deg) * delta)


func _update_sphere_wasd_rotate(delta: float) -> void:
	var rotate_x := 0.0
	var rotate_y := 0.0

	if Input.is_key_pressed(KEY_A):
		rotate_y -= 1.0
	if Input.is_key_pressed(KEY_D):
		rotate_y += 1.0
	if Input.is_key_pressed(KEY_W):
		rotate_x -= 1.0
	if Input.is_key_pressed(KEY_S):
		rotate_x += 1.0

	var rotate_input := Vector2(rotate_x, rotate_y)
	if rotate_input.length_squared() <= 0.0:
		return
	var step := deg_to_rad(sphere_rotate_speed_deg) * delta
	sphere.rotate_x(rotate_input.x * step)
	sphere.rotate_y(rotate_input.y * step)


func set_left_sphere_face_count(face_count: int) -> void:
	left_sphere_face_count = maxi(4, face_count)

	if left_sphere_face_count == 12:
		sphere.mesh = _build_dodecahedron_mesh(1.0)
		_update_edge_overlay_mesh()
		_set_polyhedron_edge_outline_enabled(true)
		_sync_marker_with_dodecahedron()
		return

	var sphere_mesh := sphere.mesh as SphereMesh
	if sphere_mesh == null:
		sphere_mesh = SphereMesh.new()
		sphere.mesh = sphere_mesh

	sphere_mesh.radial_segments = left_sphere_face_count
	sphere_mesh.rings = maxi(2, int(left_sphere_face_count / 2))
	_update_edge_overlay_mesh()
	_set_polyhedron_edge_outline_enabled(false)
	_sync_marker_with_dodecahedron()


func set_left_sphere_gp(m: int, n: int) -> void:
	left_sphere_gp_m = maxi(1, m)
	left_sphere_gp_n = maxi(0, n)

	var t := left_sphere_gp_m * left_sphere_gp_m + left_sphere_gp_m * left_sphere_gp_n + left_sphere_gp_n * left_sphere_gp_n
	var target_face_count := 10 * t + 2
	set_left_sphere_face_count(target_face_count)


func _setup_default_sphere_material() -> void:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode cull_back, depth_draw_opaque;

uniform vec4 base_color : source_color = vec4(0.82, 0.87, 0.96, 1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.42;
uniform float specular : hint_range(0.0, 1.0) = 0.22;
uniform float emission_strength : hint_range(0.0, 1.0) = 0.16;

void fragment() {
	ALBEDO = base_color.rgb;
	ROUGHNESS = roughness;
	SPECULAR = specular;
	EMISSION = base_color.rgb * emission_strength;
	ALPHA = base_color.a;
}
"""
	var sphere_material := ShaderMaterial.new()
	sphere_material.shader = shader
	sphere.material_override = sphere_material


func _sync_marker_with_dodecahedron() -> void:
	if marker == null or sphere == null or sphere.mesh == null:
		return
	var aabb := sphere.mesh.get_aabb()
	var r := maxf(0.2, maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z)) * 0.5)
	marker.position = Vector3(r * 1.05, 0.0, 0.0)


func _set_polyhedron_edge_outline_enabled(enabled: bool) -> void:
	_ensure_edge_overlay_instance()
	_update_edge_overlay_mesh()
	if not enabled:
		sphere.material_overlay = null
		if _edge_overlay_instance != null:
			_edge_overlay_instance.visible = false
		return

	if _polyhedron_edge_material == null:
		_polyhedron_edge_material = StandardMaterial3D.new()
		_polyhedron_edge_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_polyhedron_edge_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		_polyhedron_edge_material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
		_polyhedron_edge_material.no_depth_test = false

	sphere.material_overlay = null
	if _edge_overlay_instance != null:
		_edge_overlay_instance.material_override = _polyhedron_edge_material
		_edge_overlay_instance.visible = true
	_apply_edge_outline_style()


func _ensure_edge_overlay_instance() -> void:
	if _edge_overlay_instance != null and is_instance_valid(_edge_overlay_instance):
		return
	_edge_overlay_instance = sphere.get_node_or_null("EdgeOverlay") as MeshInstance3D
	if _edge_overlay_instance != null:
		return

	_edge_overlay_instance = MeshInstance3D.new()
	_edge_overlay_instance.name = "EdgeOverlay"
	_edge_overlay_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_edge_overlay_instance.visible = false
	# Slightly enlarge to reduce z-fighting while keeping front-surface depth test.
	_edge_overlay_instance.scale = Vector3.ONE * polyhedron_edge_thickness_scale
	sphere.add_child(_edge_overlay_instance)


func _update_edge_overlay_mesh() -> void:
	if _edge_overlay_instance == null or not is_instance_valid(_edge_overlay_instance):
		return
	if left_sphere_face_count == 12:
		_edge_overlay_instance.mesh = _build_dodecahedron_edge_line_mesh(1.0)
	else:
		_edge_overlay_instance.mesh = null


func _apply_edge_outline_style() -> void:
	if _edge_overlay_instance != null and is_instance_valid(_edge_overlay_instance):
		var s := maxf(1.0, polyhedron_edge_thickness_scale)
		_edge_overlay_instance.scale = Vector3.ONE * s
	if _polyhedron_edge_material != null:
		_polyhedron_edge_material.albedo_color = polyhedron_edge_color
		_polyhedron_edge_material.line_width = polyhedron_edge_line_width


func _build_dodecahedron_edge_line_mesh(target_radius: float) -> ArrayMesh:
	var phi := (1.0 + sqrt(5.0)) * 0.5
	var inv_phi := 1.0 / phi

	var verts: Array[Vector3] = [
		Vector3(1, 1, 1), Vector3(1, 1, -1), Vector3(1, -1, 1), Vector3(1, -1, -1),
		Vector3(-1, 1, 1), Vector3(-1, 1, -1), Vector3(-1, -1, 1), Vector3(-1, -1, -1),
		Vector3(0, inv_phi, phi), Vector3(0, inv_phi, -phi), Vector3(0, -inv_phi, phi), Vector3(0, -inv_phi, -phi),
		Vector3(inv_phi, phi, 0), Vector3(inv_phi, -phi, 0), Vector3(-inv_phi, phi, 0), Vector3(-inv_phi, -phi, 0),
		Vector3(phi, 0, inv_phi), Vector3(phi, 0, -inv_phi), Vector3(-phi, 0, inv_phi), Vector3(-phi, 0, -inv_phi)
	]

	var faces: Array[PackedInt32Array] = [
		PackedInt32Array([0, 16, 2, 10, 8]),
		PackedInt32Array([0, 8, 4, 14, 12]),
		PackedInt32Array([16, 17, 1, 12, 0]),
		PackedInt32Array([1, 9, 5, 14, 12]),
		PackedInt32Array([1, 17, 3, 11, 9]),
		PackedInt32Array([2, 13, 3, 17, 16]),
		PackedInt32Array([2, 10, 6, 15, 13]),
		PackedInt32Array([3, 13, 15, 7, 11]),
		PackedInt32Array([4, 8, 10, 6, 18]),
		PackedInt32Array([5, 19, 7, 11, 9]),
		PackedInt32Array([4, 18, 19, 5, 14]),
		PackedInt32Array([6, 18, 19, 7, 15])
	]

	var max_len := 0.0
	for v in verts:
		max_len = maxf(max_len, v.length())
	var scale := target_radius / maxf(0.0001, max_len)
	for i in range(verts.size()):
		verts[i] *= scale

	var edge_seen: Dictionary = {}
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINES)

	for face in faces:
		for i in range(face.size()):
			var a := face[i]
			var b := face[(i + 1) % face.size()]
			var lo := mini(a, b)
			var hi := maxi(a, b)
			var key := str(lo) + ":" + str(hi)
			if edge_seen.has(key):
				continue
			edge_seen[key] = true
			st.add_vertex(verts[lo])
			st.add_vertex(verts[hi])

	return st.commit()


func _setup_right_placeholder_scene_1() -> void:
	right_panel.color = Color(1.0, 1.0, 1.0, 1.0)
	right_panel.clip_contents = true
	line_canvas.visible = false

	var existing_center := right_panel.get_node_or_null("PlaceholderCenter") as CenterContainer
	if existing_center == null:
		var center := CenterContainer.new()
		center.name = "PlaceholderCenter"
		center.set_anchors_preset(Control.PRESET_FULL_RECT)
		center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		right_panel.add_child(center)

		var title := Label.new()
		title.name = "PlaceholderLabel"
		title.text = "\u573a\u666f1"
		title.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0, 1.0))
		title.add_theme_font_size_override("font_size", 72)
		center.add_child(title)

	var existing_overlay := right_panel.get_node_or_null("DistortionOverlay") as ColorRect
	if existing_overlay == null:
		var overlay := ColorRect.new()
		overlay.name = "DistortionOverlay"
		overlay.color = Color(1.0, 1.0, 1.0, 0.0)
		overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var shader := Shader.new()
		shader.code = """
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float grain_strength : hint_range(0.0, 1.0) = 0.95;
uniform float saturation_boost : hint_range(0.0, 5.0) = 3.5;
uniform float glitch_strength : hint_range(0.0, 0.2) = 0.05;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float t = TIME;

	float row_jitter = (noise(vec2(uv.y * 700.0, t * 15.0)) - 0.5) * glitch_strength;
	uv.x += row_jitter;

	vec2 chroma = vec2(0.003 + abs(sin(t * 8.0)) * 0.01, 0.0);
	float r = textureLod(screen_texture, uv + chroma, 0.0).r;
	float g = textureLod(screen_texture, uv, 0.0).g;
	float b = textureLod(screen_texture, uv - chroma, 0.0).b;
	vec3 col = vec3(r, g, b);

	float luma = dot(col, vec3(0.2126, 0.7152, 0.0722));
	col = mix(vec3(luma), col, saturation_boost);

	float n = noise(uv * vec2(1700.0, 1100.0) + t * 26.0);
	float scan = sin((uv.y + t * 0.25) * 1400.0) * 0.12;
	float salt = step(0.997, hash(uv * vec2(2200.0, 1600.0) + t * 14.0)) * 0.9;

	col += (n - 0.5) * grain_strength;
	col += scan * grain_strength;
	col += salt * grain_strength;
	col = clamp(col, 0.0, 1.0);

	COLOR = vec4(col, 1.0);
}
"""

		var mat := ShaderMaterial.new()
		mat.shader = shader
		overlay.material = mat
		_distortion_material = mat
		right_panel.add_child(overlay)
	else:
		_distortion_material = existing_overlay.material as ShaderMaterial


func _update_right_distortion_fade(delta: float) -> void:
	if _distortion_material == null:
		return
	var duration := maxf(0.001, distortion_fade_duration_sec)
	_distortion_elapsed_sec = minf(duration, _distortion_elapsed_sec + delta)
	var t := _distortion_elapsed_sec / duration
	var k := lerpf(1.0, 0.5, t)
	_distortion_material.set_shader_parameter("grain_strength", 0.95 * k)
	_distortion_material.set_shader_parameter("saturation_boost", 3.5 * k)
	_distortion_material.set_shader_parameter("glitch_strength", 0.05 * k)


func _build_dodecahedron_mesh(target_radius: float) -> ArrayMesh:
	var phi := (1.0 + sqrt(5.0)) * 0.5
	var inv_phi := 1.0 / phi

	var verts: Array[Vector3] = [
		Vector3(1, 1, 1), Vector3(1, 1, -1), Vector3(1, -1, 1), Vector3(1, -1, -1),
		Vector3(-1, 1, 1), Vector3(-1, 1, -1), Vector3(-1, -1, 1), Vector3(-1, -1, -1),
		Vector3(0, inv_phi, phi), Vector3(0, inv_phi, -phi), Vector3(0, -inv_phi, phi), Vector3(0, -inv_phi, -phi),
		Vector3(inv_phi, phi, 0), Vector3(inv_phi, -phi, 0), Vector3(-inv_phi, phi, 0), Vector3(-inv_phi, -phi, 0),
		Vector3(phi, 0, inv_phi), Vector3(phi, 0, -inv_phi), Vector3(-phi, 0, inv_phi), Vector3(-phi, 0, -inv_phi)
	]

	var faces: Array[PackedInt32Array] = [
		PackedInt32Array([0, 16, 2, 10, 8]),
		PackedInt32Array([0, 8, 4, 14, 12]),
		PackedInt32Array([16, 17, 1, 12, 0]),
		PackedInt32Array([1, 9, 5, 14, 12]),
		PackedInt32Array([1, 17, 3, 11, 9]),
		PackedInt32Array([2, 13, 3, 17, 16]),
		PackedInt32Array([2, 10, 6, 15, 13]),
		PackedInt32Array([3, 13, 15, 7, 11]),
		PackedInt32Array([4, 8, 10, 6, 18]),
		PackedInt32Array([5, 19, 7, 11, 9]),
		PackedInt32Array([4, 18, 19, 5, 14]),
		PackedInt32Array([6, 18, 19, 7, 15])
	]

	var max_len := 0.0
	for v in verts:
		max_len = maxf(max_len, v.length())
	var scale := target_radius / maxf(0.0001, max_len)
	for i in range(verts.size()):
		verts[i] *= scale

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for face in faces:
		var poly := face
		var p0 := verts[poly[0]]
		var p1 := verts[poly[1]]
		var p2 := verts[poly[2]]
		var face_center := Vector3.ZERO
		for idx in poly:
			face_center += verts[idx]
		face_center /= float(poly.size())

		var normal := (p1 - p0).cross(p2 - p0).normalized()
		if normal.dot(face_center) < 0.0:
			poly = PackedInt32Array([poly[0], poly[4], poly[3], poly[2], poly[1]])
			p0 = verts[poly[0]]
			p1 = verts[poly[1]]
			p2 = verts[poly[2]]
			normal = (p1 - p0).cross(p2 - p0).normalized()

		for i in range(1, poly.size() - 1):
			var a := verts[poly[0]]
			var b := verts[poly[i]]
			var c := verts[poly[i + 1]]
			st.set_normal(normal)
			st.add_vertex(a)
			st.set_normal(normal)
			st.add_vertex(b)
			st.set_normal(normal)
			st.add_vertex(c)

	return st.commit()


func _on_chapter_1_split_dragged(_offset: int) -> void:
	_enforce_chapter_1_constraints()


func _on_layout_changed() -> void:
	_enforce_chapter_1_constraints()


func _enforce_chapter_1_constraints() -> void:
	var min_right_width := maxf(1.0, size.x * 0.5)
	right_panel.custom_minimum_size.x = min_right_width
	if chapter_1_split.split_offset > 0:
		chapter_1_split.split_offset = 0
