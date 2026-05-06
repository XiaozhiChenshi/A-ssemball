extends Control
class_name LevelC3L1

signal chapter_completed(chapter_index: int)

const PAINTING_TEXTURES: Array[Texture2D] = [
	preload("res://assets/ui/chapter_3/left_1.png"),
	preload("res://assets/ui/chapter_3/left_2.png"),
	preload("res://assets/ui/chapter_3/left_3.png"),
]
const ColorReticleRef = preload("res://scripts/levels/chapter_3/color_reticle.gd")

@export var chapter_index: int = 3
@export_range(0.1, 2.0, 0.01) var left_sphere_radius: float = 0.92
@export_range(20.0, 180.0, 1.0) var sphere_rotate_speed_deg: float = 82.0
@export_range(0.08, 0.65, 0.01) var reticle_speed_uv: float = 0.24
@export_range(0.02, 0.18, 0.005) var reticle_collect_radius_uv: float = 0.064
@export_range(0.1, 1.0, 0.01) var collect_cooldown_sec: float = 0.22
@export_range(0.2, 2.0, 0.01) var color_reveal_sec: float = 1.25
@export_range(0.05, 0.7, 0.01) var color_reveal_tolerance: float = 0.34
@export_range(0.02, 0.35, 0.01) var color_reveal_softness: float = 0.16
@export_range(1.5, 4.0, 0.01) var art_zoom: float = 3.0
@export_range(0.35, 1.0, 0.01) var stage_entry_zoom: float = 1.0
@export_range(1.0, 2.5, 0.01) var min_interactive_art_zoom: float = 1.0
@export_range(0.1, 1.8, 0.01) var art_zoom_step_sec: float = 0.9
@export_range(0.1, 2.0, 0.01) var stage_entry_zoom_sec: float = 1.15
@export_range(0.08, 0.75, 0.01) var max_art_zoom_drop_per_collect: float = 0.34
@export_range(0.02, 0.25, 0.005) var next_spot_visibility_padding_uv: float = 0.08
@export_range(0.05, 0.35, 0.005) var initial_spot_clearance_uv: float = 0.16
@export_range(0.035, 0.12, 0.001) var ink_dot_diameter_uv: float = 0.075
@export_range(0.35, 1.0, 0.01) var dot_capture_radius_scale: float = 0.72
@export_range(12, 80, 1) var transfer_particle_count: int = 38
@export_range(0.25, 1.2, 0.01) var transfer_particle_sec: float = 0.62
@export_range(0.04, 0.35, 0.005) var gallery_wall_margin_uv: float = 0.20
@export_range(0.01, 0.14, 0.005) var gallery_frame_margin_uv: float = 0.045
@export_range(-12.0, 12.0, 0.1) var painting_tilt_degrees: float = -4.2
@export_range(0.2, 2.0, 0.01) var frame_settle_sec: float = 0.8
@export_range(0.2, 2.0, 0.01) var stage_pan_sec: float = 0.72
@export_range(0.05, 1.8, 0.01) var sphere_flow_speed: float = 0.42
@export_range(0.05, 0.45, 0.01) var left_background_darkness: float = 0.17
@export_range(0.0, 24.0, 0.1) var sphere_idle_rotate_speed_deg: float = 5.0
@export_range(0.0, 0.5, 0.01) var sphere_color_drift_speed: float = 0.08
@export_range(3, 10, 1) var crack_primary_branch_count: int = 5
@export_range(0.18, 1.35, 0.005) var crack_max_angular_length: float = 0.96
@export_range(0.025, 0.16, 0.001) var crack_dark_width: float = 0.058
@export_range(0.006, 0.07, 0.001) var shell_crack_open_radius: float = 0.012
@export_range(1.0, 2.0, 0.05) var crack_spread_sec: float = 1.25
@export_range(1.4, 4.5, 0.05) var core_dye_width_scale: float = 3.2
@export_range(24, 72, 1) var shell_latitude_segments: int = 56
@export_range(48, 144, 1) var shell_longitude_segments: int = 112
@export_range(0.01, 0.16, 0.001) var shell_thickness: float = 0.055

@onready var chapter_split: HSplitContainer = $ChapterSplit
@onready var left_3d: SubViewportContainer = $ChapterSplit/Left3D
@onready var model_root: Node3D = $ChapterSplit/Left3D/LeftViewport/World3D/ModelRoot
@onready var sphere_mesh: MeshInstance3D = $ChapterSplit/Left3D/LeftViewport/World3D/ModelRoot/Sphere
@onready var left_camera: Camera3D = $ChapterSplit/Left3D/LeftViewport/World3D/Camera3D
@onready var world_environment: WorldEnvironment = $ChapterSplit/Left3D/LeftViewport/World3D/WorldEnvironment
@onready var right_panel: Control = $ChapterSplit/RightPanel

var _stage_data: Array[Dictionary] = []
var _stage_index: int = 0
var _stage_spots: Array[Dictionary] = []
var _collected_in_stage: int = 0
var _view_uv: Vector2 = Vector2(0.5, 0.5)
var _collect_cooldown: float = 0.0
var _transition_running: bool = false
var _right_panel_size: Vector2 = Vector2.ZERO
var _current_art_zoom: float = 3.0
var _art_zoom_tween: Tween

var _sphere_material: ShaderMaterial
var _frame_root: Control
var _art_root: Control
var _viewport_wall_back: ColorRect
var _art_canvas: Control
var _wall_back: ColorRect
var _wood_frame: ColorRect
var _painting_root: Control
var _gray_art: TextureRect
var _reveal_root: Control
var _dot_root: Control
var _reticle: Control
var _progress_label: Label
var _status_label: Label
var _fx_layer: Control
var _left_environment: Environment
var _color_flow_time: float = 0.0
var _pulse_color: Color = Color(0.86, 0.18, 0.14, 1.0)
var _pulse_mix: float = 0.0
var _crack_surface_dirs: Array[Vector3] = []
var _shell_mesh: MeshInstance3D
var _shell_material: StandardMaterial3D
var _shell_cuts: Array[Dictionary] = []
var _shell_cut_cells: Array[bool] = []
var _shell_cell_dirs: Array[Vector3] = []
var _core_mesh: MeshInstance3D
var _core_material: ShaderMaterial
var _core_patch_root: Node3D
var _core_radius: float = 0.0
var _core_color_accum: Color = Color(0.0, 0.0, 0.0, 1.0)
var _core_color_count: int = 0


func _ready() -> void:
	_stage_data = _build_stage_data()
	_setup_sphere_material()
	_setup_right_panel()
	_setup_fx_layer()
	_apply_stage(0, true)


func _process(delta: float) -> void:
	_update_left_color_flow(delta)
	_update_idle_rotation(delta)
	_update_rotation_and_reticle(delta)
	_update_collect_cooldown(delta)
	_update_reticle_visual()
	_try_collect_active_spot()
	_update_layout_if_needed()


func _input(event: InputEvent) -> void:
	if _transition_running:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ENTER:
		if _stage_index >= _stage_data.size() - 1 and _collected_in_stage >= _stage_spots.size():
			get_viewport().set_input_as_handled()
			_emit_completed()


func _build_stage_data() -> Array[Dictionary]:
	return [
		{
			"texture": PAINTING_TEXTURES[0],
			"title": "3-1 / left painting 1",
			"start_uv": Vector2(0.50, 0.72),
			"spots": [
				{"uv": Vector2(0.22, 0.28), "color": Color(0.92, 0.12, 0.10), "radius": 0.18},
				{"uv": Vector2(0.68, 0.24), "color": Color(0.12, 0.38, 0.82), "radius": 0.16},
				{"uv": Vector2(0.58, 0.30), "color": Color(0.96, 0.72, 0.18), "radius": 0.17},
				{"uv": Vector2(0.76, 0.62), "color": Color(0.18, 0.60, 0.38), "radius": 0.16},
				{"uv": Vector2(0.30, 0.74), "color": Color(0.78, 0.20, 0.58), "radius": 0.18},
			],
		},
		{
			"texture": PAINTING_TEXTURES[1],
			"title": "3-1 / left painting 2",
			"start_uv": Vector2(0.50, 0.82),
			"spots": [
				{"uv": Vector2(0.30, 0.22), "color": Color(0.94, 0.10, 0.08), "radius": 0.19},
				{"uv": Vector2(0.67, 0.28), "color": Color(0.08, 0.30, 0.86), "radius": 0.18},
				{"uv": Vector2(0.48, 0.48), "color": Color(0.98, 0.76, 0.08), "radius": 0.20},
				{"uv": Vector2(0.24, 0.72), "color": Color(0.95, 0.12, 0.10), "radius": 0.17},
				{"uv": Vector2(0.52, 0.74), "color": Color(0.10, 0.36, 0.88), "radius": 0.17},
				{"uv": Vector2(0.78, 0.68), "color": Color(0.98, 0.74, 0.12), "radius": 0.18},
			],
		},
		{
			"texture": PAINTING_TEXTURES[2],
			"title": "3-1 / left painting 3",
			"start_uv": Vector2(0.50, 0.50),
			"spots": [
				{"uv": Vector2(0.18, 0.32), "color": Color(0.86, 0.08, 0.12), "radius": 0.15},
				{"uv": Vector2(0.42, 0.22), "color": Color(0.10, 0.38, 0.86), "radius": 0.15},
				{"uv": Vector2(0.64, 0.36), "color": Color(0.96, 0.76, 0.12), "radius": 0.16},
				{"uv": Vector2(0.30, 0.58), "color": Color(0.18, 0.64, 0.32), "radius": 0.15},
				{"uv": Vector2(0.80, 0.58), "color": Color(0.72, 0.18, 0.72), "radius": 0.15},
				{"uv": Vector2(0.52, 0.78), "color": Color(0.96, 0.44, 0.10), "radius": 0.16},
			],
		},
	]


func _setup_sphere_material() -> void:
	_sphere_material = _create_glass_sphere_material()
	sphere_mesh.material_override = _sphere_material
	sphere_mesh.visible = false
	_setup_color_core()
	_setup_cracked_shell()
	_left_environment = world_environment.environment
	_update_left_color_flow(0.0)


func _update_left_color_flow(delta: float) -> void:
	_color_flow_time += delta * sphere_flow_speed
	_pulse_mix = maxf(0.0, _pulse_mix - delta * 1.35)

	var flow_color := _sample_flow_color(_color_flow_time)
	var sphere_color := flow_color.lerp(_pulse_color, _pulse_mix * 0.58)
	if _sphere_material != null:
		_sphere_material.set_shader_parameter("base_tint", sphere_color)
		_sphere_material.set_shader_parameter("pulse_color", _pulse_color)
		_sphere_material.set_shader_parameter("pulse_mix", _pulse_mix)
		_sphere_material.set_shader_parameter("time", _color_flow_time)
	if _core_material != null:
		_core_material.set_shader_parameter("pulse_mix", _pulse_mix)
		_core_material.set_shader_parameter("time", _color_flow_time)

	if _left_environment == null:
		return
	var dark := clampf(left_background_darkness, 0.05, 0.45)
	var bg_color := Color(
		sphere_color.r * dark,
		sphere_color.g * dark,
		sphere_color.b * dark,
		1.0
	)
	_left_environment.background_color = bg_color
	_left_environment.ambient_light_color = bg_color


func _update_idle_rotation(delta: float) -> void:
	if model_root == null:
		return
	if sphere_idle_rotate_speed_deg == 0.0:
		return
	model_root.rotate_y(deg_to_rad(sphere_idle_rotate_speed_deg) * delta)


func _sample_flow_color(t: float) -> Color:
	var phase := t * (1.0 + sphere_color_drift_speed)
	var r := 0.5 + 0.5 * sin(phase)
	var g := 0.5 + 0.5 * sin(phase + TAU / 3.0)
	var b := 0.5 + 0.5 * sin(phase + TAU * 2.0 / 3.0)
	var color := Color(r, g, b, 1.0)
	var peak := maxf(color.r, maxf(color.g, color.b))
	if peak > 0.0:
		color.r /= peak
		color.g /= peak
		color.b /= peak
	return color.lerp(Color(1.0, 1.0, 1.0, 1.0), 0.08)


func _create_glass_sphere_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode blend_mix, cull_back, depth_draw_opaque;

uniform vec4 base_tint : source_color = vec4(0.78, 0.84, 0.92, 1.0);
uniform vec4 pulse_color : source_color = vec4(1.0, 0.16, 0.10, 1.0);
uniform float pulse_mix = 0.0;
uniform float time = 0.0;

varying vec3 local_pos;

float hash(vec3 p) {
	return fract(sin(dot(p, vec3(17.17, 43.31, 91.77))) * 43758.5453);
}

float soft_noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float n000 = hash(i + vec3(0.0, 0.0, 0.0));
	float n100 = hash(i + vec3(1.0, 0.0, 0.0));
	float n010 = hash(i + vec3(0.0, 1.0, 0.0));
	float n110 = hash(i + vec3(1.0, 1.0, 0.0));
	float n001 = hash(i + vec3(0.0, 0.0, 1.0));
	float n101 = hash(i + vec3(1.0, 0.0, 1.0));
	float n011 = hash(i + vec3(0.0, 1.0, 1.0));
	float n111 = hash(i + vec3(1.0, 1.0, 1.0));
	float nx00 = mix(n000, n100, f.x);
	float nx10 = mix(n010, n110, f.x);
	float nx01 = mix(n001, n101, f.x);
	float nx11 = mix(n011, n111, f.x);
	float nxy0 = mix(nx00, nx10, f.y);
	float nxy1 = mix(nx01, nx11, f.y);
	return mix(nxy0, nxy1, f.z);
}

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	vec3 n = normalize(NORMAL);
	vec3 local_dir = normalize(local_pos);
	float fresnel = pow(1.0 - clamp(dot(n, VIEW), 0.0, 1.0), 2.45);
	float shell_grain = soft_noise(local_dir * 9.0 + vec3(time * 0.08, time * 0.05, -time * 0.04));
	float inner_current = soft_noise(local_dir * 3.5 + vec3(time * 0.16, -time * 0.10, time * 0.07));
	vec3 tint = mix(vec3(0.06, 0.075, 0.095), pulse_color.rgb, pulse_mix * 0.16);
	vec3 body = mix(vec3(0.018, 0.017, 0.021), tint, 0.54 + inner_current * 0.16);
	ALBEDO = body * (0.78 + shell_grain * 0.08);
	ROUGHNESS = 0.34;
	METALLIC = 0.02;
	SPECULAR = 0.78;
	EMISSION = body * 0.08 + vec3(0.34, 0.50, 0.72) * fresnel * 0.34 + pulse_color.rgb * pulse_mix * 0.18;
	ALPHA = 1.0;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("base_tint", Color(0.78, 0.84, 0.92, 1.0))
	material.set_shader_parameter("pulse_color", Color(0.86, 0.18, 0.14, 1.0))
	material.set_shader_parameter("pulse_mix", 0.0)
	material.set_shader_parameter("time", 0.0)
	return material


func _setup_color_core() -> void:
	_core_mesh = MeshInstance3D.new()
	_core_mesh.name = "ColorCoreSphere"
	var mesh := SphereMesh.new()
	_core_radius = maxf(0.05, left_sphere_radius - shell_thickness - 0.018)
	mesh.radius = _core_radius
	mesh.height = _core_radius * 2.0
	mesh.radial_segments = 96
	mesh.rings = 48
	_core_mesh.mesh = mesh
	_core_material = _create_color_core_material()
	_core_mesh.material_override = _core_material
	model_root.add_child(_core_mesh)
	_core_patch_root = Node3D.new()
	_core_patch_root.name = "CoreColorPatches"
	model_root.add_child(_core_patch_root)


func _create_color_core_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode blend_mix, cull_back, depth_draw_opaque;

uniform vec4 core_color : source_color = vec4(0.05, 0.055, 0.065, 1.0);
uniform vec4 pulse_color : source_color = vec4(1.0, 0.2, 0.1, 1.0);
uniform float pulse_mix = 0.0;
uniform float time = 0.0;

varying vec3 local_pos;

float hash(vec3 p) {
	return fract(sin(dot(p, vec3(31.17, 53.31, 97.77))) * 43758.5453);
}

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	vec3 dir = normalize(local_pos);
	float grain = hash(floor((dir + vec3(time * 0.035, -time * 0.02, time * 0.025)) * 18.0));
	float fresnel = pow(1.0 - clamp(dot(normalize(NORMAL), VIEW), 0.0, 1.0), 2.1);
	vec3 color = mix(core_color.rgb, pulse_color.rgb, pulse_mix * 0.28);
	ALBEDO = color * (0.72 + grain * 0.12);
	ROUGHNESS = 0.46;
	METALLIC = 0.0;
	EMISSION = color * (0.34 + fresnel * 0.62 + pulse_mix * 0.45);
	ALPHA = 1.0;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("core_color", Color(0.045, 0.05, 0.06, 1.0))
	material.set_shader_parameter("pulse_color", Color(1.0, 0.2, 0.1, 1.0))
	material.set_shader_parameter("pulse_mix", 0.0)
	material.set_shader_parameter("time", 0.0)
	return material


func _setup_cracked_shell() -> void:
	_shell_cuts.clear()
	_build_shell_cell_cache()
	_shell_mesh = MeshInstance3D.new()
	_shell_mesh.name = "CrackedShellMesh"
	_shell_material = _create_shell_material()
	_shell_mesh.material_override = _shell_material
	model_root.add_child(_shell_mesh)
	_rebuild_cracked_shell()


func _build_shell_cell_cache() -> void:
	var cell_count: int = shell_latitude_segments * shell_longitude_segments
	_shell_cut_cells.clear()
	_shell_cut_cells.resize(cell_count)
	_shell_cell_dirs.clear()
	_shell_cell_dirs.resize(cell_count)
	for y in range(shell_latitude_segments):
		var theta: float = PI * (float(y) + 0.5) / float(shell_latitude_segments)
		for x in range(shell_longitude_segments):
			var phi: float = TAU * (float(x) + 0.5) / float(shell_longitude_segments)
			var index: int = _shell_cell_index(y, x)
			_shell_cut_cells[index] = false
			_shell_cell_dirs[index] = _spherical_dir(theta, phi)


func _create_shell_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.014, 0.013, 0.016, 1.0)
	material.roughness = 0.88
	material.metallic = 0.03
	material.emission_enabled = true
	material.emission = Color(0.015, 0.018, 0.022, 1.0)
	material.emission_energy_multiplier = 0.2
	return material


func _rebuild_cracked_shell() -> void:
	if _shell_mesh == null or not is_instance_valid(_shell_mesh):
		return
	_shell_mesh.mesh = _build_cracked_shell_mesh()


func _build_cracked_shell_mesh() -> ArrayMesh:
	var vertices: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	var indices: PackedInt32Array = PackedInt32Array()

	for y in range(shell_latitude_segments):
		for x in range(shell_longitude_segments):
			if _is_shell_cell_cut(y, x):
				continue
			var d00: Vector3 = _grid_shell_dir(y, x)
			var d10: Vector3 = _grid_shell_dir(y, x + 1)
			var d01: Vector3 = _grid_shell_dir(y + 1, x)
			var d11: Vector3 = _grid_shell_dir(y + 1, x + 1)
			_append_shell_quad(vertices, normals, uvs, indices, d00, d10, d11, d01, left_sphere_radius, true)
			_append_shell_quad(vertices, normals, uvs, indices, d01, d11, d10, d00, left_sphere_radius - shell_thickness, false)

			if _is_shell_cell_cut(y, x - 1):
				_append_shell_wall(vertices, normals, uvs, indices, d00, d01)
			if _is_shell_cell_cut(y, x + 1):
				_append_shell_wall(vertices, normals, uvs, indices, d10, d11)
			if y == 0 or _is_shell_cell_cut(y - 1, x):
				_append_shell_wall(vertices, normals, uvs, indices, d00, d10)
			if y == shell_latitude_segments - 1 or _is_shell_cell_cut(y + 1, x):
				_append_shell_wall(vertices, normals, uvs, indices, d01, d11)

	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _shell_cell_index(y: int, x: int) -> int:
	return y * shell_longitude_segments + posmod(x, shell_longitude_segments)


func _is_shell_cell_cut(y: int, x: int) -> bool:
	if y < 0 or y >= shell_latitude_segments:
		return false
	return bool(_shell_cut_cells[_shell_cell_index(y, x)])


func _grid_shell_dir(y: int, x: int) -> Vector3:
	var theta: float = PI * float(y) / float(shell_latitude_segments)
	var phi: float = TAU * float(x % shell_longitude_segments) / float(shell_longitude_segments)
	return _spherical_dir(theta, phi)


func _append_shell_quad(
	vertices: PackedVector3Array,
	normals: PackedVector3Array,
	uvs: PackedVector2Array,
	indices: PackedInt32Array,
	d0: Vector3,
	d1: Vector3,
	d2: Vector3,
	d3: Vector3,
	radius: float,
	outer: bool
) -> void:
	var base: int = vertices.size()
	var n0: Vector3 = d0 if outer else -d0
	var n1: Vector3 = d1 if outer else -d1
	var n2: Vector3 = d2 if outer else -d2
	var n3: Vector3 = d3 if outer else -d3
	vertices.append(d0 * radius)
	vertices.append(d1 * radius)
	vertices.append(d2 * radius)
	vertices.append(d3 * radius)
	normals.append(n0)
	normals.append(n1)
	normals.append(n2)
	normals.append(n3)
	uvs.append(Vector2.ZERO)
	uvs.append(Vector2.RIGHT)
	uvs.append(Vector2.ONE)
	uvs.append(Vector2.DOWN)
	indices.append(base)
	indices.append(base + 1)
	indices.append(base + 2)
	indices.append(base)
	indices.append(base + 2)
	indices.append(base + 3)


func _append_shell_wall(
	vertices: PackedVector3Array,
	normals: PackedVector3Array,
	uvs: PackedVector2Array,
	indices: PackedInt32Array,
	a: Vector3,
	b: Vector3
) -> void:
	if a.distance_squared_to(b) < 0.000001:
		return
	var normal: Vector3 = (a + b).normalized()
	var base: int = vertices.size()
	vertices.append(a * left_sphere_radius)
	vertices.append(b * left_sphere_radius)
	vertices.append(b * (left_sphere_radius - shell_thickness))
	vertices.append(a * (left_sphere_radius - shell_thickness))
	normals.append(normal)
	normals.append(normal)
	normals.append(normal)
	normals.append(normal)
	uvs.append(Vector2.ZERO)
	uvs.append(Vector2.RIGHT)
	uvs.append(Vector2.ONE)
	uvs.append(Vector2.DOWN)
	indices.append(base)
	indices.append(base + 1)
	indices.append(base + 2)
	indices.append(base)
	indices.append(base + 2)
	indices.append(base + 3)


func _spherical_dir(theta: float, phi: float) -> Vector3:
	return Vector3(
		sin(theta) * cos(phi),
		cos(theta),
		sin(theta) * sin(phi)
	).normalized()


func _setup_right_panel() -> void:
	right_panel.clip_contents = true

	_frame_root = Control.new()
	_frame_root.name = "PaintingViewport"
	_frame_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right_panel.add_child(_frame_root)

	_art_root = Control.new()
	_art_root.name = "ArtRoot"
	_art_root.clip_contents = true
	_art_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame_root.add_child(_art_root)

	_viewport_wall_back = ColorRect.new()
	_viewport_wall_back.name = "ViewportWallBack"
	_viewport_wall_back.color = Color(0.025, 0.023, 0.026, 1.0)
	_viewport_wall_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art_root.add_child(_viewport_wall_back)

	_art_canvas = Control.new()
	_art_canvas.name = "ArtCanvas"
	_art_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art_root.add_child(_art_canvas)

	_wall_back = ColorRect.new()
	_wall_back.name = "GalleryWall"
	_wall_back.color = Color(0.025, 0.023, 0.026, 1.0)
	_wall_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art_canvas.add_child(_wall_back)

	_wood_frame = ColorRect.new()
	_wood_frame.name = "WoodFrame"
	_wood_frame.color = Color(0.72, 0.54, 0.24, 1.0)
	_wood_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art_canvas.add_child(_wood_frame)

	_painting_root = Control.new()
	_painting_root.name = "PaintingRoot"
	_painting_root.clip_contents = true
	_painting_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art_canvas.add_child(_painting_root)

	_gray_art = TextureRect.new()
	_gray_art.name = "GrayArt"
	_gray_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_gray_art.stretch_mode = TextureRect.STRETCH_SCALE
	_gray_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gray_art.material = _create_grayscale_material()
	_painting_root.add_child(_gray_art)

	_reveal_root = Control.new()
	_reveal_root.name = "RevealRoot"
	_reveal_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_painting_root.add_child(_reveal_root)

	_dot_root = Control.new()
	_dot_root.name = "InkDots"
	_dot_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_painting_root.add_child(_dot_root)

	_reticle = ColorReticleRef.new()
	_reticle.name = "ColorReticle"
	_reticle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art_root.add_child(_reticle)

	_progress_label = Label.new()
	_progress_label.name = "ProgressLabel"
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_progress_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_progress_label.add_theme_font_size_override("font_size", 20)
	_progress_label.modulate = Color(0.86, 0.9, 0.94, 0.42)
	right_panel.add_child(_progress_label)

	_status_label = Label.new()
	_status_label.name = "StatusLabel"
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 18)
	_status_label.modulate = Color(0.86, 0.9, 0.94, 0.56)
	right_panel.add_child(_status_label)

	_layout_right_scene()


func _setup_fx_layer() -> void:
	_fx_layer = Control.new()
	_fx_layer.name = "TransferParticleLayer"
	_fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fx_layer.offset_left = 0.0
	_fx_layer.offset_top = 0.0
	_fx_layer.offset_right = 0.0
	_fx_layer.offset_bottom = 0.0
	add_child(_fx_layer)


func _create_grayscale_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform float contrast = 1.16;
uniform float brightness = -0.035;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float g = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	g = clamp((g - 0.5) * contrast + 0.5 + brightness, 0.0, 1.0);
	COLOR = vec4(vec3(g), c.a);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	return material


func _create_reveal_material(target_color: Color) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform vec4 target_color : source_color = vec4(1.0, 0.1, 0.1, 1.0);
uniform float progress = 0.0;
uniform float tolerance = 0.34;
uniform float softness = 0.16;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float color_distance = distance(c.rgb, target_color.rgb);
	float mask = 1.0 - smoothstep(tolerance, tolerance + softness, color_distance);
	float saturation = max(c.r, max(c.g, c.b)) - min(c.r, min(c.g, c.b));
	mask *= smoothstep(0.035, 0.12, saturation);
	mask *= progress;
	COLOR = vec4(c.rgb, c.a * mask);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("target_color", target_color)
	material.set_shader_parameter("tolerance", color_reveal_tolerance)
	material.set_shader_parameter("softness", color_reveal_softness)
	material.set_shader_parameter("progress", 0.0)
	return material


func _create_ink_dot_material(color: Color) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform vec4 ink_color : source_color = vec4(1.0, 0.1, 0.1, 1.0);
uniform float alpha_scale = 1.0;
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}
void fragment() {
	vec2 p = UV - vec2(0.5);
	float d = length(p);
	float n = hash(floor(UV * 18.0));
	float edge = 0.43 + (n - 0.5) * 0.075;
	float a = 1.0 - smoothstep(edge, edge + 0.08, d);
	float grain = 0.78 + hash(floor(UV * 42.0)) * 0.28;
	COLOR = vec4(ink_color.rgb * grain, ink_color.a * a * alpha_scale);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("ink_color", color)
	return material


func _layout_right_scene() -> void:
	if right_panel == null:
		return
	var panel_size := right_panel.size
	if panel_size.x <= 1.0 or panel_size.y <= 1.0:
		return
	_right_panel_size = panel_size

	var frame_size := panel_size
	_frame_root.position = Vector2.ZERO
	_frame_root.size = frame_size
	_frame_root.pivot_offset = frame_size * 0.5

	_art_root.position = Vector2.ZERO
	_art_root.size = frame_size
	_viewport_wall_back.set_anchors_preset(Control.PRESET_FULL_RECT)
	_viewport_wall_back.offset_left = 0.0
	_viewport_wall_back.offset_top = 0.0
	_viewport_wall_back.offset_right = 0.0
	_viewport_wall_back.offset_bottom = 0.0

	_art_canvas.size = _art_root.size * _current_art_zoom
	_layout_art_canvas_contents()

	_update_art_canvas_transform()
	_progress_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_progress_label.offset_left = 0.0
	_progress_label.offset_top = 10.0
	_progress_label.offset_right = 0.0
	_progress_label.offset_bottom = 42.0
	_status_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_status_label.offset_left = 0.0
	_status_label.offset_top = -48.0
	_status_label.offset_right = 0.0
	_status_label.offset_bottom = -12.0

	_update_reticle_visual()


func _layout_art_canvas_contents() -> void:
	if _art_canvas == null:
		return
	if _art_canvas.size.x <= 1.0 or _art_canvas.size.y <= 1.0:
		return
	_wall_back.set_anchors_preset(Control.PRESET_FULL_RECT)
	_wall_back.offset_left = 0.0
	_wall_back.offset_top = 0.0
	_wall_back.offset_right = 0.0
	_wall_back.offset_bottom = 0.0

	var painting_rect := _get_painting_rect()
	var frame_margin := minf(_art_canvas.size.x, _art_canvas.size.y) * gallery_frame_margin_uv
	_wood_frame.position = painting_rect.position - Vector2(frame_margin, frame_margin)
	_wood_frame.size = painting_rect.size + Vector2(frame_margin * 2.0, frame_margin * 2.0)
	_painting_root.position = painting_rect.position
	_painting_root.size = painting_rect.size

	_gray_art.set_anchors_preset(Control.PRESET_FULL_RECT)
	_gray_art.offset_left = 0.0
	_gray_art.offset_top = 0.0
	_gray_art.offset_right = 0.0
	_gray_art.offset_bottom = 0.0
	_reveal_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_reveal_root.offset_left = 0.0
	_reveal_root.offset_top = 0.0
	_reveal_root.offset_right = 0.0
	_reveal_root.offset_bottom = 0.0
	_dot_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dot_root.offset_left = 0.0
	_dot_root.offset_top = 0.0
	_dot_root.offset_right = 0.0
	_dot_root.offset_bottom = 0.0

	_refresh_spot_layout()


func _apply_stage(next_stage_index: int, animate_entry: bool) -> void:
	_stage_index = clampi(next_stage_index, 0, _stage_data.size() - 1)
	_stage_spots.clear()
	_collected_in_stage = 0
	_collect_cooldown = 0.0
	_current_art_zoom = stage_entry_zoom if animate_entry else art_zoom

	for child in _reveal_root.get_children():
		child.queue_free()
	for child in _dot_root.get_children():
		child.queue_free()

	var stage := _stage_data[_stage_index]
	var texture := stage["texture"] as Texture2D
	_gray_art.texture = texture
	_frame_root.rotation_degrees = 0.0
	_frame_root.modulate.a = 1.0
	_art_canvas.scale = Vector2.ONE
	_art_canvas.rotation_degrees = painting_tilt_degrees
	_art_canvas.size = _art_root.size * _current_art_zoom
	_layout_art_canvas_contents()
	_view_uv = Vector2(0.5, 0.5) if animate_entry else _get_stage_start_view_uv(_stage_index)

	var spot_defs: Array = stage["spots"]
	for i in range(spot_defs.size()):
		var def: Dictionary = spot_defs[i]
		var uv := def["uv"] as Vector2
		var color := def["color"] as Color
		var radius := float(def["radius"])

		var reveal := TextureRect.new()
		reveal.name = "ColorReveal_%d" % i
		reveal.texture = texture
		reveal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		reveal.stretch_mode = TextureRect.STRETCH_SCALE
		reveal.mouse_filter = Control.MOUSE_FILTER_IGNORE
		reveal.material = _create_reveal_material(color)
		_reveal_root.add_child(reveal)

		var dot := ColorRect.new()
		dot.name = "InkDot_%d" % i
		dot.color = Color(1, 1, 1, 1)
		dot.material = _create_ink_dot_material(color)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_dot_root.add_child(dot)

		_stage_spots.append({
			"uv": uv,
			"color": color,
			"radius": radius,
			"collected": false,
			"reveal": reveal,
			"dot": dot,
		})

	_refresh_spot_layout()
	_update_art_canvas_transform()
	_update_progress_label()
	_status_label.text = "WASD - move painting"

	if animate_entry:
		var base_pos := _frame_root.position
		_frame_root.position = base_pos + Vector2(right_panel.size.x * 0.22, 0.0)
		_frame_root.modulate.a = 0.0
		var entry := create_tween()
		entry.set_parallel(true)
		entry.tween_property(_frame_root, "position", base_pos, stage_pan_sec).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		entry.tween_property(_frame_root, "modulate:a", 1.0, stage_pan_sec * 0.75)
		await entry.finished

		var target_view_uv := _get_stage_start_view_uv(_stage_index)
		var zoom_in := create_tween()
		zoom_in.set_parallel(true)
		zoom_in.tween_method(
			Callable(self, "_set_art_zoom_for_tween"),
			_current_art_zoom,
			art_zoom,
			stage_entry_zoom_sec
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		zoom_in.tween_method(
			Callable(self, "_set_view_uv_for_tween"),
			_view_uv,
			target_view_uv,
			stage_entry_zoom_sec
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		await zoom_in.finished
		_transition_running = false


func _refresh_spot_layout() -> void:
	if _painting_root == null:
		return
	var art_size := _painting_root.size
	if art_size.x <= 1.0 or art_size.y <= 1.0:
		return
	for i in range(_stage_spots.size()):
		var spot := _stage_spots[i]
		var reveal_variant: Variant = spot.get("reveal")
		if is_instance_valid(reveal_variant):
			var reveal := reveal_variant as TextureRect
			reveal.set_anchors_preset(Control.PRESET_FULL_RECT)
			reveal.offset_left = 0.0
			reveal.offset_top = 0.0
			reveal.offset_right = 0.0
			reveal.offset_bottom = 0.0

		var dot_variant: Variant = spot.get("dot")
		if not is_instance_valid(dot_variant):
			continue
		var dot := dot_variant as ColorRect
		var dot_size := minf(art_size.x, art_size.y) * ink_dot_diameter_uv
		var pos := (spot["uv"] as Vector2) * art_size - Vector2(dot_size, dot_size) * 0.5
		dot.position = pos
		dot.size = Vector2(dot_size, dot_size)
		dot.pivot_offset = dot.size * 0.5


func _update_rotation_and_reticle(delta: float) -> void:
	if _transition_running:
		return

	var input_vec := Vector2.ZERO
	if Input.is_key_pressed(KEY_A):
		input_vec.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		input_vec.x += 1.0
	if Input.is_key_pressed(KEY_W):
		input_vec.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		input_vec.y += 1.0

	if input_vec.length_squared() <= 0.0:
		return

	input_vec = input_vec.normalized()
	var rotate_amount := deg_to_rad(sphere_rotate_speed_deg) * delta
	model_root.rotate_y(-input_vec.x * rotate_amount)
	model_root.rotate_object_local(Vector3.RIGHT, -input_vec.y * rotate_amount)

	_view_uv += input_vec * reticle_speed_uv * delta
	_clamp_view_uv()
	_update_art_canvas_transform()


func _update_collect_cooldown(delta: float) -> void:
	if _collect_cooldown > 0.0:
		_collect_cooldown = maxf(0.0, _collect_cooldown - delta)


func _update_reticle_visual() -> void:
	if _reticle == null or _art_root == null:
		return
	var art_size := _art_root.size
	if art_size.x <= 1.0 or art_size.y <= 1.0:
		return
	var diameter := minf(art_size.x, art_size.y) * reticle_collect_radius_uv * 2.0
	diameter = clampf(diameter, 58.0, 118.0)
	_reticle.size = Vector2(diameter, diameter)
	_reticle.position = art_size * 0.5 - _reticle.size * 0.5
	_reticle.queue_redraw()


func _try_collect_active_spot() -> void:
	if _transition_running or _collect_cooldown > 0.0:
		return
	if _art_canvas == null or _reticle == null:
		return
	var canvas_size := _art_canvas.size
	if canvas_size.x <= 1.0 or canvas_size.y <= 1.0:
		return
	var reticle_radius_px := _reticle.size.x * 0.5
	for i in range(_stage_spots.size()):
		var spot := _stage_spots[i]
		if bool(spot["collected"]):
			continue
		var uv := _painting_uv_to_canvas_uv(spot["uv"] as Vector2)
		var spot_distance_px := ((uv - _view_uv) * canvas_size).length()
		var spot_radius_px := _get_spot_capture_radius_px(spot)
		if spot_distance_px + spot_radius_px <= reticle_radius_px:
			_collect_spot(i)
			return


func _get_spot_capture_radius_px(spot: Dictionary) -> float:
	var dot_variant: Variant = spot.get("dot")
	if is_instance_valid(dot_variant):
		var dot := dot_variant as Control
		return minf(dot.size.x, dot.size.y) * 0.5 * dot_capture_radius_scale
	if _painting_root != null:
		return maxf(32.0, minf(_painting_root.size.x, _painting_root.size.y) * 0.032)
	return 32.0


func _collect_spot(spot_index: int) -> void:
	if spot_index < 0 or spot_index >= _stage_spots.size():
		return
	var spot := _stage_spots[spot_index]
	if bool(spot["collected"]):
		return

	spot["collected"] = true
	_stage_spots[spot_index] = spot
	_collected_in_stage += 1
	_collect_cooldown = collect_cooldown_sec

	var color := spot["color"] as Color
	_play_dot_absorb(spot["dot"] as Control)
	_play_reveal(spot["reveal"] as TextureRect)
	_play_color_transfer(color)
	_update_progress_label()

	if _collected_in_stage >= _stage_spots.size():
		_start_stage_complete_transition()
	else:
		_animate_art_zoom(_compute_zoom_for_next_visible_spot())


func _play_dot_absorb(dot: Control) -> void:
	if dot == null or not is_instance_valid(dot):
		return
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(dot, "scale", Vector2(0.08, 0.08), 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(dot, "modulate:a", 0.0, 0.24)
	tween.chain().tween_callback(Callable(dot, "queue_free"))


func _play_reveal(reveal: TextureRect) -> void:
	if reveal == null or reveal.material == null:
		return
	var material := reveal.material as ShaderMaterial
	var tween := create_tween()
	tween.tween_method(
		func(value: float) -> void:
			material.set_shader_parameter("progress", value),
		0.0,
		1.0,
		color_reveal_sec
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _play_color_transfer(color: Color) -> void:
	if _fx_layer == null or _reticle == null or left_3d == null:
		_add_sphere_color_cloud(color)
		_pulse_sphere(color)
		return

	var fx_origin := _fx_layer.get_global_rect().position
	var start: Vector2 = _reticle.get_global_rect().get_center() - fx_origin
	var left_rect := left_3d.get_global_rect()
	var end: Vector2 = left_rect.position + Vector2(left_rect.size.x * 0.52, left_rect.size.y * 0.50) - fx_origin
	var bend := Vector2((start.x + end.x) * 0.5, minf(start.y, end.y) - 90.0)
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	for i in range(transfer_particle_count):
		var particle := ColorRect.new()
		particle.name = "TransferParticle"
		particle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var size := rng.randf_range(5.0, 13.0)
		particle.size = Vector2(size, size)
		particle.pivot_offset = particle.size * 0.5
		particle.position = start - particle.pivot_offset + Vector2(rng.randf_range(-16.0, 16.0), rng.randf_range(-16.0, 16.0))
		particle.color = Color(1, 1, 1, 1)
		particle.material = _create_transfer_particle_material(color)
		particle.modulate.a = 0.0
		_fx_layer.add_child(particle)

		var delay := float(i) / float(maxi(1, transfer_particle_count - 1)) * 0.20
		var duration := transfer_particle_sec * rng.randf_range(0.82, 1.16)
		var control := bend + Vector2(rng.randf_range(-36.0, 36.0), rng.randf_range(-42.0, 42.0))
		var landing: Vector2 = end + Vector2(rng.randf_range(-22.0, 22.0), rng.randf_range(-22.0, 22.0))
		var tween := create_tween()
		tween.tween_interval(delay)
		tween.tween_callback(func() -> void:
			if is_instance_valid(particle):
				particle.modulate.a = rng.randf_range(0.62, 0.92)
		)
		tween.tween_method(
			Callable(self, "_update_transfer_particle").bind(particle, start, control, landing),
			0.0,
			1.0,
			duration
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_callback(func() -> void:
			if is_instance_valid(particle):
				particle.queue_free()
		)

	var arrival := create_tween()
	arrival.tween_interval(transfer_particle_sec * 0.72)
	arrival.tween_callback(func() -> void:
		_add_sphere_color_cloud(color)
		_pulse_sphere(color)
		_play_sphere_arrival_burst(color, end)
	)


func _update_transfer_particle(t: float, particle: Control, start: Vector2, control: Vector2, landing: Vector2) -> void:
	if not is_instance_valid(particle):
		return
	var pos := _quadratic_bezier(start, control, landing, t)
	var taper := sin(t * PI)
	particle.position = pos - particle.pivot_offset
	particle.scale = Vector2.ONE * lerpf(0.72, 1.45, taper)
	particle.modulate.a = taper * 0.92


func _play_sphere_arrival_burst(color: Color, center: Vector2) -> void:
	if _fx_layer == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in range(16):
		var particle := ColorRect.new()
		particle.name = "SphereArrivalParticle"
		particle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var size := rng.randf_range(6.0, 15.0)
		particle.size = Vector2(size, size)
		particle.pivot_offset = particle.size * 0.5
		particle.position = center - particle.pivot_offset
		particle.color = Color(1, 1, 1, 1)
		particle.material = _create_transfer_particle_material(color)
		_fx_layer.add_child(particle)
		var angle := rng.randf_range(0.0, TAU)
		var distance := rng.randf_range(24.0, 72.0)
		var target := center + Vector2(cos(angle), sin(angle)) * distance
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(particle, "position", target - particle.pivot_offset, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(particle, "modulate:a", 0.0, 0.32)
		tween.tween_property(particle, "scale", Vector2.ONE * 0.18, 0.32)
		tween.chain().tween_callback(func() -> void:
			if is_instance_valid(particle):
				particle.queue_free()
		)


func _quadratic_bezier(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	var ab := a.lerp(b, t)
	var bc := b.lerp(c, t)
	return ab.lerp(bc, t)


func _create_transfer_particle_material(color: Color) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform vec4 particle_color : source_color = vec4(1.0, 0.2, 0.1, 1.0);
void fragment() {
	vec2 p = UV - vec2(0.5);
	float d = length(p);
	float core = 1.0 - smoothstep(0.10, 0.32, d);
	float glow = 1.0 - smoothstep(0.18, 0.50, d);
	float alpha = max(core, glow * 0.48);
	COLOR = vec4(particle_color.rgb * (0.65 + core * 0.95), particle_color.a * alpha);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("particle_color", color)
	return material


func _add_sphere_color_cloud(color: Color) -> void:
	var local_dir := _get_visible_sphere_local_direction()
	_add_color_to_core(color)
	var cut: Dictionary = _add_shell_cut(local_dir)
	_add_core_color_patch(color, cut, crack_spread_sec)


func _add_color_to_core(color: Color) -> void:
	_core_color_accum.r += color.r
	_core_color_accum.g += color.g
	_core_color_accum.b += color.b
	_core_color_count += 1
	var inv := 1.0 / float(maxi(1, _core_color_count))
	var mixed := Color(
		clampf(_core_color_accum.r * inv, 0.0, 1.0),
		clampf(_core_color_accum.g * inv, 0.0, 1.0),
		clampf(_core_color_accum.b * inv, 0.0, 1.0),
		1.0
	)
	mixed = mixed.lerp(color, 0.28)
	if _core_material != null:
		_core_material.set_shader_parameter("pulse_color", color)


func _add_core_color_patch(color: Color, cut: Dictionary, spread_sec: float) -> void:
	if _core_patch_root == null or not is_instance_valid(_core_patch_root):
		return
	var patch := MeshInstance3D.new()
	patch.name = "CoreColorPatch_%d" % _core_color_count
	patch.mesh = _build_core_color_patch_mesh(cut)
	var material := _create_core_patch_material(color)
	patch.material_override = material
	_core_patch_root.add_child(patch)
	patch.scale = Vector3.ONE * 0.12
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(patch, "scale", Vector3.ONE, spread_sec).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_method(
		func(alpha: float) -> void:
			material.albedo_color = Color(color.r, color.g, color.b, alpha)
			material.emission_energy_multiplier = lerpf(0.2, 1.7, alpha),
		0.0,
		0.92,
		spread_sec
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _build_core_color_patch_mesh(cut: Dictionary) -> ArrayMesh:
	var vertices: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	var indices: PackedInt32Array = PackedInt32Array()
	var radius: float = _core_radius + 0.006
	for y in range(shell_latitude_segments):
		for x in range(shell_longitude_segments):
			var index: int = _shell_cell_index(y, x)
			var dir: Vector3 = _shell_cell_dirs[index]
			if _does_cut_hit_direction(cut, dir, 1.0, core_dye_width_scale):
				_append_core_patch_cell(vertices, normals, uvs, indices, y, x, radius)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh: ArrayMesh = ArrayMesh.new()
	if not vertices.is_empty():
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _append_core_patch_cell(
	vertices: PackedVector3Array,
	normals: PackedVector3Array,
	uvs: PackedVector2Array,
	indices: PackedInt32Array,
	y: int,
	x: int,
	radius: float
) -> void:
	var d00: Vector3 = _grid_shell_dir(y, x)
	var d10: Vector3 = _grid_shell_dir(y, x + 1)
	var d11: Vector3 = _grid_shell_dir(y + 1, x + 1)
	var d01: Vector3 = _grid_shell_dir(y + 1, x)
	var base: int = vertices.size()
	vertices.append(d00 * radius)
	vertices.append(d10 * radius)
	vertices.append(d11 * radius)
	vertices.append(d01 * radius)
	normals.append(d00)
	normals.append(d10)
	normals.append(d11)
	normals.append(d01)
	uvs.append(Vector2.ZERO)
	uvs.append(Vector2.RIGHT)
	uvs.append(Vector2.ONE)
	uvs.append(Vector2.DOWN)
	indices.append(base)
	indices.append(base + 1)
	indices.append(base + 2)
	indices.append(base)
	indices.append(base + 2)
	indices.append(base + 3)


func _append_core_patch_disk(
	vertices: PackedVector3Array,
	normals: PackedVector3Array,
	uvs: PackedVector2Array,
	indices: PackedInt32Array,
	center: Vector3,
	tangent_a: Vector3,
	tangent_b: Vector3,
	radius_2d: float,
	radius: float
) -> void:
	var base: int = vertices.size()
	vertices.append(center * radius)
	normals.append(center)
	uvs.append(Vector2(0.5, 0.5))
	var ring_count: int = 18
	for i in range(ring_count):
		var angle: float = TAU * float(i) / float(ring_count)
		var offset: Vector2 = Vector2(cos(angle), sin(angle)) * radius_2d
		var dir: Vector3 = _core_patch_dir(center, tangent_a, tangent_b, offset)
		vertices.append(dir * radius)
		normals.append(dir)
		uvs.append(Vector2(0.5, 0.5) + offset)
	for i in range(ring_count):
		indices.append(base)
		indices.append(base + 1 + i)
		indices.append(base + 1 + ((i + 1) % ring_count))


func _core_patch_dir(center: Vector3, tangent_a: Vector3, tangent_b: Vector3, offset: Vector2) -> Vector3:
	return (center + tangent_a * offset.x + tangent_b * offset.y).normalized()


func _create_core_patch_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(color.r, color.g, color.b, 0.92)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 1.7
	return material


func _add_shell_cut(local_dir: Vector3) -> Dictionary:
	var center_dir: Vector3 = local_dir.normalized()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	var cut: Dictionary = _create_shell_cut(center_dir, rng)
	_shell_cuts.append(cut)
	_crack_surface_dirs.append(center_dir)
	_animate_shell_cut(cut, crack_spread_sec)
	return cut


func _animate_shell_cut(cut: Dictionary, spread_sec: float) -> void:
	var step_count: int = 12
	for step in range(1, step_count + 1):
		var progress: float = float(step) / float(step_count)
		var delay: float = spread_sec * float(step - 1) / float(step_count)
		var timer := get_tree().create_timer(delay)
		timer.timeout.connect(
			func() -> void:
				_apply_shell_cut_to_cells(cut, progress)
				_rebuild_cracked_shell(),
			CONNECT_ONE_SHOT
		)


func _create_shell_cut(center_dir: Vector3, rng: RandomNumberGenerator) -> Dictionary:
	var basis: Array[Vector3] = _build_crack_basis(center_dir)
	var tangent_a: Vector3 = basis[0]
	var tangent_b: Vector3 = basis[1]
	var pattern: int = rng.randi_range(1, 3)
	var segments: Array[Dictionary] = _generate_shell_cut_segments(pattern, rng)
	var cavity_radius: float = shell_crack_open_radius * rng.randf_range(0.28, 0.55)
	var max_radius: float = cavity_radius
	var avoid_turn: float = float(_count_nearby_crack_dirs(center_dir, 0.34)) * 0.43
	for i in range(segments.size()):
		var segment: Dictionary = segments[i]
		var a: Vector2 = segment["a"] as Vector2
		var b: Vector2 = segment["b"] as Vector2
		var rotated_a: Vector2 = a.rotated(avoid_turn)
		var rotated_b: Vector2 = b.rotated(avoid_turn)
		segment["a"] = rotated_a
		segment["b"] = rotated_b
		segment["reveal_start"] = clampf(rotated_a.length() / maxf(crack_max_angular_length, 0.001), 0.0, 1.0)
		segment["reveal_end"] = clampf(rotated_b.length() / maxf(crack_max_angular_length, 0.001), 0.0, 1.0)
		max_radius = maxf(max_radius, maxf(rotated_a.length(), rotated_b.length()) + float(segment["width"]))
		segments[i] = segment
	return {
		"center": center_dir,
		"tangent_a": tangent_a,
		"tangent_b": tangent_b,
		"segments": segments,
		"cavity_radius": cavity_radius,
		"max_radius": max_radius,
	}


func _generate_shell_cut_segments(pattern: int, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var segments: Array[Dictionary] = []
	var start_angle: float = rng.randf_range(0.0, TAU)
	var trunk_count: int = 1

	for trunk_index in range(trunk_count):
		var angle: float = start_angle + rng.randf_range(-0.25, 0.25)
		if trunk_count > 1:
			angle += TAU * float(trunk_index) / float(trunk_count) + rng.randf_range(-0.16, 0.16)
		if pattern == 2:
			angle += PI * float(trunk_index) / float(maxi(1, trunk_count))
		var heading: Vector2 = Vector2(cos(angle), sin(angle)).normalized()
		var pos: Vector2 = heading * rng.randf_range(0.014, 0.028)
		var previous: Vector2 = Vector2.ZERO
		var segment_count: int = rng.randi_range(7, 12)
		var branch_length: float = crack_max_angular_length * rng.randf_range(0.82, 1.22)
		if pattern == 1 and trunk_index == 0:
			segment_count = rng.randi_range(11, 16)
			branch_length *= 1.32
		for step_index in range(segment_count):
			var turn: float = rng.randf_range(-0.32, 0.32)
			if pattern == 2:
				turn += sin(float(step_index) * 1.4 + start_angle) * 0.18
			heading = heading.rotated(turn).normalized()
			var step_length: float = branch_length / float(segment_count) * rng.randf_range(0.76, 1.24)
			pos += heading * step_length
			pos += Vector2(-heading.y, heading.x) * rng.randf_range(-0.014, 0.014)
			var progress: float = float(step_index) / float(maxi(1, segment_count - 1))
			var width: float = crack_dark_width * lerpf(0.78, 0.30, progress) * rng.randf_range(0.82, 1.10)
			segments.append({"a": previous, "b": pos, "width": width})

			if step_index >= 3 and rng.randf() < 0.28:
				_append_shell_cut_fork(segments, pos, heading, rng, progress)
			previous = pos

	var extra_forks: int = crack_primary_branch_count + rng.randi_range(-1, 2)
	for fork_index in range(maxi(0, extra_forks)):
		if segments.is_empty():
			break
		var source: Dictionary = segments[rng.randi_range(0, segments.size() - 1)]
		var source_a: Vector2 = source["a"] as Vector2
		var source_b: Vector2 = source["b"] as Vector2
		var source_pos: Vector2 = source_a.lerp(source_b, rng.randf_range(0.35, 0.90))
		var source_heading: Vector2 = (source_b - source_a).normalized()
		if source_heading.length_squared() <= 0.000001:
			source_heading = Vector2(cos(start_angle), sin(start_angle))
		_append_shell_cut_fork(segments, source_pos, source_heading, rng, rng.randf_range(0.4, 0.9))
	return segments


func _append_shell_cut_fork(
	segments: Array[Dictionary],
	start_pos: Vector2,
	source_heading: Vector2,
	rng: RandomNumberGenerator,
	progress: float
) -> void:
	var fork_heading: Vector2 = source_heading.rotated((1.0 if rng.randf() > 0.5 else -1.0) * rng.randf_range(0.54, 1.18)).normalized()
	var previous: Vector2 = start_pos
	var fork_steps: int = rng.randi_range(3, 6)
	var fork_length: float = crack_max_angular_length * rng.randf_range(0.18, 0.42) * (1.08 - progress * 0.35)
	for fork_step in range(fork_steps):
		fork_heading = fork_heading.rotated(rng.randf_range(-0.34, 0.34)).normalized()
		var fork_pos: Vector2 = previous + fork_heading * (fork_length / float(fork_steps)) * rng.randf_range(0.74, 1.24)
		var fork_progress: float = float(fork_step) / float(maxi(1, fork_steps - 1))
		var fork_width: float = crack_dark_width * lerpf(0.58, 0.24, fork_progress) * rng.randf_range(0.82, 1.14)
		segments.append({"a": previous, "b": fork_pos, "width": fork_width})
		previous = fork_pos


func _apply_shell_cut_to_cells(cut: Dictionary, progress: float = 1.0) -> void:
	for i in range(_shell_cell_dirs.size()):
		if bool(_shell_cut_cells[i]):
			continue
		if _does_cut_hit_direction(cut, _shell_cell_dirs[i], progress):
			_shell_cut_cells[i] = true


func _does_cut_hit_direction(cut: Dictionary, dir: Vector3, progress: float = 1.0) -> bool:
	var center: Vector3 = cut["center"] as Vector3
	var angle: float = center.angle_to(dir)
	var max_radius: float = float(cut.get("max_radius", crack_max_angular_length))
	if angle > max_radius:
		return false
	var cavity_radius: float = float(cut["cavity_radius"])
	if progress > 0.02 and angle < cavity_radius:
		return true
	var tangent_a: Vector3 = cut["tangent_a"] as Vector3
	var tangent_b: Vector3 = cut["tangent_b"] as Vector3
	var center_dot: float = maxf(0.28, dir.dot(center))
	var point: Vector2 = Vector2(dir.dot(tangent_a), dir.dot(tangent_b)) / center_dot
	var segments: Array = cut["segments"] as Array
	for segment_variant in segments:
		var segment: Dictionary = segment_variant as Dictionary
		var reveal_start: float = float(segment.get("reveal_start", 0.0))
		var reveal_end: float = float(segment.get("reveal_end", 1.0))
		if progress < reveal_start:
			continue
		var a: Vector2 = segment["a"] as Vector2
		var b: Vector2 = segment["b"] as Vector2
		if progress < reveal_end:
			var span: float = maxf(0.001, reveal_end - reveal_start)
			var local_progress: float = clampf((progress - reveal_start) / span, 0.0, 1.0)
			b = a.lerp(b, local_progress)
		var width: float = float(segment["width"])
		if _distance_to_cut_segment(point, a, b) <= width:
			return true
	return false


func _distance_to_cut_segment(point: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var length_squared: float = ab.length_squared()
	if length_squared <= 0.000001:
		return point.distance_to(a)
	var t: float = clampf((point - a).dot(ab) / length_squared, 0.0, 1.0)
	return point.distance_to(a + ab * t)


func _build_crack_basis(center_dir: Vector3) -> Array[Vector3]:
	var reference := Vector3.UP
	if abs(center_dir.dot(reference)) > 0.88:
		reference = Vector3.RIGHT
	var tangent_a := center_dir.cross(reference).normalized()
	var tangent_b := tangent_a.cross(center_dir).normalized()
	return [tangent_a, tangent_b]


func _count_nearby_crack_dirs(center_dir: Vector3, angular_threshold: float) -> int:
	var count := 0
	for dir in _crack_surface_dirs:
		if center_dir.angle_to(dir) < angular_threshold:
			count += 1
	return count


func _pulse_sphere(color: Color) -> void:
	_pulse_color = color
	_pulse_mix = 1.0

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(model_root, "scale", Vector3.ONE * 1.045, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(model_root, "scale", Vector3.ONE, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _start_stage_complete_transition() -> void:
	if _transition_running:
		return
	_transition_running = true
	_status_label.text = ""
	_run_stage_complete_transition()


func _run_stage_complete_transition() -> void:
	if _art_zoom_tween != null and _art_zoom_tween.is_valid():
		_art_zoom_tween.kill()

	var overview := create_tween()
	overview.set_parallel(true)
	overview.tween_method(
		Callable(self, "_set_art_zoom_for_tween"),
		_current_art_zoom,
		1.0,
		frame_settle_sec * 0.72
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	overview.tween_method(
		Callable(self, "_set_view_uv_for_tween"),
		_view_uv,
		Vector2(0.5, 0.5),
		frame_settle_sec * 0.72
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await overview.finished

	var straighten := create_tween()
	straighten.set_parallel(true)
	straighten.tween_property(_art_canvas, "rotation_degrees", 0.0, frame_settle_sec * 0.46).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	straighten.tween_property(_frame_root, "scale", Vector2.ONE * 1.01, frame_settle_sec * 0.22)
	straighten.chain().tween_property(_frame_root, "scale", Vector2.ONE, frame_settle_sec * 0.20)
	await straighten.finished

	if _stage_index >= _stage_data.size() - 1:
		_emit_completed()
		return

	var base_pos := _frame_root.position
	var exit := create_tween()
	exit.set_parallel(true)
	exit.tween_property(_frame_root, "position", base_pos - Vector2(right_panel.size.x * 0.24, 0.0), stage_pan_sec).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	exit.tween_property(_frame_root, "modulate:a", 0.0, stage_pan_sec * 0.72)
	await exit.finished

	_stage_spots.clear()
	_layout_right_scene()
	await _apply_stage(_stage_index + 1, true)


func _update_progress_label() -> void:
	if _progress_label == null:
		return
	_progress_label.text = "%d / %d" % [_collected_in_stage, _stage_spots.size()]


func _update_layout_if_needed() -> void:
	if right_panel == null:
		return
	if right_panel.size.distance_to(_right_panel_size) > 1.0:
		_layout_right_scene()


func _emit_completed() -> void:
	_transition_running = true
	chapter_completed.emit(chapter_index)


func _get_stage_start_view_uv(stage_index: int) -> Vector2:
	return _painting_uv_to_canvas_uv(Vector2(0.5, 0.5))


func _is_view_clear_from_stage_spots(view_uv: Vector2, stage_index: int) -> bool:
	return _nearest_stage_spot_distance(view_uv, stage_index) >= initial_spot_clearance_uv


func _nearest_stage_spot_distance(view_uv: Vector2, stage_index: int) -> float:
	var stage := _stage_data[stage_index]
	var spots: Array = stage["spots"]
	if spots.is_empty():
		return INF
	var nearest := INF
	for spot_variant in spots:
		var spot := spot_variant as Dictionary
		var spot_uv := _painting_uv_to_canvas_uv(spot["uv"] as Vector2)
		nearest = minf(nearest, view_uv.distance_to(spot_uv))
	return nearest


func _clamp_view_uv() -> void:
	var frame_pad := gallery_frame_margin_uv
	_view_uv.x = clampf(_view_uv.x, frame_pad, 1.0 - frame_pad)
	_view_uv.y = clampf(_view_uv.y, frame_pad, 1.0 - frame_pad)


func _update_art_canvas_transform() -> void:
	if _art_canvas == null or _art_root == null:
		return
	var viewport_size := _art_root.size
	var canvas_size := _art_canvas.size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0 or canvas_size.x <= 1.0 or canvas_size.y <= 1.0:
		return
	_clamp_view_uv()
	_art_canvas.pivot_offset = _view_uv * canvas_size
	_art_canvas.position = viewport_size * 0.5 - _art_canvas.pivot_offset


func _get_painting_rect() -> Rect2:
	if _art_canvas == null:
		return Rect2()
	var canvas_size := _art_canvas.size
	if canvas_size.x <= 1.0 or canvas_size.y <= 1.0:
		return Rect2()
	var available_pos := Vector2(canvas_size.x * gallery_wall_margin_uv, canvas_size.y * gallery_wall_margin_uv)
	var available_size := canvas_size - available_pos * 2.0
	if available_size.x <= 1.0 or available_size.y <= 1.0:
		return Rect2(available_pos, Vector2.ZERO)

	var texture := _gray_art.texture if _gray_art != null else null
	if texture == null:
		return Rect2(available_pos, available_size)
	var texture_size := texture.get_size()
	if texture_size.x <= 1.0 or texture_size.y <= 1.0:
		return Rect2(available_pos, available_size)

	var texture_aspect := texture_size.x / texture_size.y
	var available_aspect := available_size.x / available_size.y
	var painting_size := available_size
	if available_aspect > texture_aspect:
		painting_size.x = available_size.y * texture_aspect
	else:
		painting_size.y = available_size.x / texture_aspect
	var painting_pos := available_pos + (available_size - painting_size) * 0.5
	return Rect2(painting_pos, painting_size)


func _painting_uv_to_canvas_uv(painting_uv: Vector2) -> Vector2:
	var canvas_size := _art_canvas.size if _art_canvas != null else Vector2.ZERO
	if canvas_size.x <= 1.0 or canvas_size.y <= 1.0:
		return Vector2(0.5, 0.5)
	var painting_rect := _get_painting_rect()
	if painting_rect.size.x <= 1.0 or painting_rect.size.y <= 1.0:
		return Vector2(0.5, 0.5)
	var canvas_pos := painting_rect.position + painting_uv * painting_rect.size
	return Vector2(
		canvas_pos.x / canvas_size.x,
		canvas_pos.y / canvas_size.y
	)


func _compute_zoom_for_next_visible_spot() -> float:
	var next_uv := _find_next_uncollected_spot_uv()
	if next_uv.x < 0.0:
		return 1.0
	var delta := (next_uv - _view_uv).abs()
	var needed_half_span := maxf(delta.x, delta.y) + next_spot_visibility_padding_uv
	if needed_half_span <= 0.0:
		return _current_art_zoom
	var zoom_to_fit := 0.5 / needed_half_span
	var progress_zoom := lerpf(art_zoom, 1.0, float(_collected_in_stage) / float(maxi(1, _stage_spots.size())))
	var desired_zoom := minf(zoom_to_fit, progress_zoom)
	var smallest_step_zoom := _current_art_zoom - max_art_zoom_drop_per_collect
	var target_zoom := minf(_current_art_zoom, maxf(desired_zoom, smallest_step_zoom))
	return clampf(target_zoom, min_interactive_art_zoom, art_zoom)


func _find_next_uncollected_spot_uv() -> Vector2:
	var best_uv := Vector2(-1.0, -1.0)
	var best_distance := INF
	for spot in _stage_spots:
		if bool(spot["collected"]):
			continue
		var uv := _painting_uv_to_canvas_uv(spot["uv"] as Vector2)
		var distance := _view_uv.distance_to(uv)
		if distance < best_distance:
			best_distance = distance
			best_uv = uv
	return best_uv


func _animate_art_zoom(target_zoom: float) -> void:
	target_zoom = clampf(target_zoom, min_interactive_art_zoom, art_zoom)
	if is_equal_approx(target_zoom, _current_art_zoom):
		return
	if _art_zoom_tween != null and _art_zoom_tween.is_valid():
		_art_zoom_tween.kill()
	_art_zoom_tween = create_tween()
	_art_zoom_tween.tween_method(
		Callable(self, "_set_art_zoom_for_tween"),
		_current_art_zoom,
		target_zoom,
		art_zoom_step_sec
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _set_art_zoom_for_tween(value: float) -> void:
	_current_art_zoom = value
	if _art_canvas == null or _art_root == null:
		return
	_art_canvas.size = _art_root.size * _current_art_zoom
	_layout_art_canvas_contents()
	_update_art_canvas_transform()


func _set_view_uv_for_tween(value: Vector2) -> void:
	_view_uv = value
	_update_art_canvas_transform()


func _get_visible_sphere_local_direction() -> Vector3:
	if left_camera == null or not is_instance_valid(left_camera):
		return Vector3(0.0, 0.0, 1.0)
	var center := model_root.global_transform.origin
	var camera_pos := left_camera.global_transform.origin
	var world_dir := camera_pos - center
	if world_dir.length_squared() <= 0.0001:
		return Vector3(0.0, 0.0, 1.0)
	return (model_root.global_transform.basis.inverse() * world_dir.normalized()).normalized()
