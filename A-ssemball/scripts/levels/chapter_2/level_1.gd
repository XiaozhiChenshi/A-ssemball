@tool
extends Control
class_name LevelC2L1

signal chapter_completed(chapter_index: int)

const RIGHT_SCENE_TEXTURES: Array[Texture2D] = [
	preload("res://assets/materials/room2-1-1.png"),
	preload("res://assets/materials/room2-1-2.png"),
	preload("res://assets/materials/room2-1-3.png"),
	preload("res://assets/materials/room2-1-4.png"),
]
const SECOND_CUBE_UV_TEXTURE: Texture2D = preload("res://assets/textures/uv1.png")
const THIRD_CUBE_UV_TEXTURE: Texture2D = preload("res://assets/textures/uv2.png")
const NOTE_TEXTURES: Array[Texture2D] = [
	preload("res://assets/textures/note1.png"),
	preload("res://assets/textures/note2.png"),
	preload("res://assets/textures/note3.png"),
	preload("res://assets/textures/note4.png"),
	preload("res://assets/textures/note5.png"),
	preload("res://assets/textures/note6.png"),
]

@export var light_rotation_speed_deg: float = 0.0
@export var light_energy: float = 0.85
@export var chapter_index: int = 2
@export_range(4, 256, 1) var left_sphere_face_count: int = 12
@export_range(1, 64, 1) var left_sphere_gp_m: int = 1
@export_range(0, 64, 1) var left_sphere_gp_n: int = 0
@export_range(0.1, 1.0, 0.01) var left_sphere_scale: float = 0.62
@export var left_sphere_color: Color = Color(0.46, 0.30, 0.18, 1.0)
@export_range(0.0, 0.25, 0.005) var left_sphere_relief_strength: float = 0.075
@export_range(0.0, 1.0, 0.01) var left_sphere_emission_strength: float = 0.18
@export_range(0.0, 1.0, 0.01) var left_sphere_emission_pulse: float = 0.08
@export var rotation_step_deg: float = 90.0
@export var rotation_step_duration: float = 0.18
@export var rotation_input_block_sec: float = 0.2
@export var hold_rotate_interval_sec: float = 0.3
@export var drag_step_threshold_px: float = 40.0
@export var vertical_swipe_threshold_px: float = 48.0
@export var sync_right_scene_on_rotate: bool = true
@export var enable_vertical_face_preview: bool = true
@export var vertical_face_hold_sec: float = 3.5
@export var vertical_face_anim_sec: float = 0.22
@export var up_face_x_deg: float = -90.0
@export var down_face_x_deg: float = 90.0
@export_range(0.0, 1.0, 0.01) var moire_strength: float = 0.82
@export_range(0.0, 0.6, 0.01) var moire_noise_strength: float = 0.16
@export_range(0.0, 12.0, 0.1) var moire_noise_speed: float = 2.1
@export_range(120.0, 2200.0, 10.0) var moire_noise_density: float = 1250.0
@export_range(0.0, 1.0, 0.01) var left_moire_intensity_scale: float = 0.38
@export_range(0.0, 0.2, 0.001) var camera_frag_shift: float = 0.003
@export_range(0.0, 0.2, 0.001) var camera_frag_chroma: float = 0.001
@export_range(0.0, 1.0, 0.01) var camera_frag_noise: float = 0.02
@export_range(0.0, 1.0, 0.01) var camera_frag_line_mix: float = 0.08
@export_range(0.0, 4.0, 0.01) var camera_frag_speed: float = 0.6
@export_range(2.0, 128.0, 1.0) var camera_frag_quantize_steps: float = 32.0
@export_range(0.0, 1.0, 0.01) var camera_frag_quantize_mix: float = 0.05
@export_range(0.2, 2.0, 0.01) var orbit_radius: float = 1.08
@export_range(2.0, 30.0, 0.1) var orbit_period_sec: float = 16.0
@export_range(-0.5, 0.5, 0.01) var orbit_height: float = 0.0
@export_range(0.1, 1.0, 0.01) var orbit_cube_size: float = 0.26
@export_range(0.1, 2.0, 0.01) var orbit_snap_radius: float = 0.28
@export_range(8.0, 240.0, 1.0) var orbit_snap_screen_radius_px: float = 52.0
@export_range(0.05, 1.0, 0.01) var orbit_snap_anim_sec: float = 0.22
@export_range(0.1, 20.0, 0.1) var orbit_return_fast_speed: float = 8.2
@export_range(0.1, 20.0, 0.1) var orbit_return_slow_speed: float = 2.0
@export_range(0.1, 2.0, 0.01) var orbit_reject_wait_sec: float = 0.5
@export_range(0.1, 3.0, 0.01) var orbit_completed_eject_delay_sec: float = 1.0
@export_range(0.05, 1.0, 0.01) var orbit_eject_anim_sec: float = 0.28
@export_range(0.05, 3.0, 0.01) var orbit_eject_distance: float = 0.55
@export_range(0.1, 3.0, 0.01) var final_close_to_black_sec: float = 1.05
@export_range(0.0, 1.0, 0.01) var final_black_hold_sec: float = 0.2
@export var anchor_frame_y_offset: float = -1.43
@export_range(0.1, 20.0, 0.1) var anchor_frame_spin_speed_deg: float = 1.8
@export_range(0.1, 3.0, 0.01) var intro_frame_fade_in_sec: float = 0.35
@export_range(0.1, 4.0, 0.01) var intro_split_push_sec: float = 1.0
@export_range(0.1, 4.0, 0.01) var intro_sphere_appear_sec: float = 1.15
@export_range(0.05, 2.0, 0.01) var intro_orbit_cube_step_sec: float = 0.14
@export_range(0.05, 2.0, 0.01) var intro_orbit_cube_scale_sec: float = 0.30
@export_range(0.1, 3.0, 0.01) var intro_right_panel_fade_in_sec: float = 0.45
@export_range(0.1, 3.0, 0.01) var intro_anchor_frame_appear_sec: float = 0.36
@export var start_as_post_intro_scene: bool = false
@export var preview_post_intro_in_editor: bool = true
@export_range(0.1, 0.9, 0.01) var locked_left_panel_width_ratio: float = 0.25
@export var lock_split_dragging: bool = true
@export var camera_frag_region_use_scene_stage: bool = true
@export var camera_frag_region_left_px: float = 26.0
@export var camera_frag_region_top_px: float = 74.0
@export var camera_frag_region_right_px: float = 26.0
@export var camera_frag_region_bottom_px: float = 26.0
@export var camera_frag_region_inset_left_px: float = 0.0
@export var camera_frag_region_inset_top_px: float = 0.0
@export var camera_frag_region_inset_right_px: float = 0.0
@export var camera_frag_region_inset_bottom_px: float = 0.0
@export var camera_focus_region_use_ratio: bool = true
@export_range(0.0, 0.49, 0.001) var camera_focus_region_left_ratio: float = 0.073
@export_range(0.0, 0.49, 0.001) var camera_focus_region_top_ratio: float = 0.113
@export_range(0.0, 0.49, 0.001) var camera_focus_region_right_ratio: float = 0.098
@export_range(0.0, 0.49, 0.001) var camera_focus_region_bottom_ratio: float = 0.095
@export var camera_focus_region_use_absolute_rect: bool = false
@export var camera_focus_region_x_px: float = 202.0
@export var camera_focus_region_y_px: float = 22.0
@export var camera_focus_region_width_px: float = 554.0
@export var camera_focus_region_height_px: float = 338.0
@export var camera_focus_region_use_scene_flash_overlay: bool = true
@export var camera_focus_region_after_intro_only: bool = true
@export var right_scene_stage_left_px: float = 0.0
@export var right_scene_stage_top_px: float = 0.0
@export var right_scene_stage_right_px: float = 0.0
@export var right_scene_stage_bottom_px: float = 0.0
@export var right_scene_image_left_px: float = 0.0
@export var right_scene_image_top_px: float = 0.0
@export var right_scene_image_right_px: float = 0.0
@export var right_scene_image_bottom_px: float = 0.0
@export_range(0.0, 0.8, 0.01) var right_scene_dim_alpha: float = 0.20
@export_range(1.0, 20.0, 1.0) var split_divider_width_px: float = 5.0

@onready var chapter_1_split: HSplitContainer = $Chapter1Split
@onready var left_3d: SubViewportContainer = $Chapter1Split/Left3D
@onready var left_viewport: SubViewport = $Chapter1Split/Left3D/LeftViewport
@onready var camera_3d: Camera3D = $Chapter1Split/Left3D/LeftViewport/World3D/Camera3D
@onready var world_3d: Node3D = $Chapter1Split/Left3D/LeftViewport/World3D
@onready var model_root: Node3D = $Chapter1Split/Left3D/LeftViewport/World3D/ModelRoot
@onready var sphere: MeshInstance3D = $Chapter1Split/Left3D/LeftViewport/World3D/ModelRoot/Sphere
@onready var marker: MeshInstance3D = $Chapter1Split/Left3D/LeftViewport/World3D/ModelRoot/Sphere/Marker
@onready var right_panel: ColorRect = $Chapter1Split/RightPanel
@onready var line_canvas: LineCanvas2D = $Chapter1Split/RightPanel/LineCanvas
@onready var dir_light: DirectionalLight3D = $Chapter1Split/Left3D/LeftViewport/World3D/DirectionalLight3D

var _is_dragging_sphere: bool = false
var _drag_accum_x: float = 0.0
var _drag_accum_y: float = 0.0
var _rotation_step_count: int = 0
var _sphere_rotate_tween: Tween
var _model_x_tween: Tween
var _rotation_input_block_until_ms: int = 0
var _hold_rotate_dir: int = 0
var _hold_rotate_elapsed: float = 0.0
var _right_art_base_size: Vector2 = Vector2.ZERO
var _vertical_preview_phase: int = 0 # 0 none, 1 holding, 2 returning
var _vertical_preview_return_at_ms: int = 0
var _vertical_preview_saved_rotation: Vector3 = Vector3.ZERO
var _chapter_completed_once: bool = false
var _chapter_hint_label: Label
var _continue_button: Button
var _right_placeholder_root: Control
var _left_moire_overlay: ColorRect
var _right_moire_overlay: ColorRect
var _camera_data_overlay: ColorRect
var _right_scene_root: Control
var _right_scene_cards: Array[Control] = []
var _right_scene_current_index: int = -1
var _right_scene_transition_tween: Tween
var _right_scene_transition_id: int = 0
var _right_scene_status_labels: Array[Label] = []
var _right_scene_completed: Array[bool] = []
var _right_scene_flash_overlay: ColorRect
var _right_scene_dim_overlay: ColorRect
var _right_scene_flash_tween: Tween
var _orbit_root: Node3D
var _orbit_cube_entries: Array[Dictionary] = []
var _orbit_time_sec: float = 0.0
var _anchor_frame_root: Node3D
var _dragging_orbit_cube_index: int = -1
var _drag_cube_depth: float = 0.0
var _final_transition_running: bool = false
var _final_curtain_layer: Control
var _final_curtain_left: ColorRect
var _final_curtain_right: ColorRect
var _intro_sequence_running: bool = true
var _intro_overlay: Control
var _intro_left_frame: Panel
var _intro_right_frame: Panel
var _intro_divider_line: ColorRect
var _split_programmatic_motion: bool = false
var _right_frag_region_hint: Control
var _right_frag_hint_outer_lines: Array[ColorRect] = []
var _right_frag_hint_inner_lines: Array[ColorRect] = []
var _right_frag_hint_corner_marks: Array[ColorRect] = []
var _right_frag_hint_scan_line: ColorRect
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _orbit_particles_enabled: bool = true
var _camera_focus_intensity_baseline: Dictionary = {}
var _camera_focus_intensity_captured: bool = false
var _camera_focus_intensity_boost_active: bool = false


func _ready() -> void:
	_rng.randomize()
	if Engine.is_editor_hint():
		_ready_editor_preview()
		return

	_validate_input_actions()
	chapter_1_split.add_theme_constant_override("separation", int(split_divider_width_px))
	set_left_sphere_gp(left_sphere_gp_m, left_sphere_gp_n)
	_setup_default_sphere_material()
	chapter_1_split.dragger_visibility = 1
	_setup_anchor_frame_cube()
	_setup_orbit_cubes()
	_setup_right_placeholder()
	_setup_moire_overlays()
	_setup_camera_data_fragment_overlay()
	_setup_right_fragment_region_hint()
	_setup_final_curtains()
	dir_light.light_energy = light_energy
	right_panel.clip_contents = true
	resized.connect(_on_layout_changed)
	left_3d.resized.connect(_on_layout_changed)
	chapter_1_split.dragged.connect(_on_chapter_1_split_dragged)
	_on_layout_changed()
	_ensure_chapter_hint_label()
	_setup_intro_overlay()
	if start_as_post_intro_scene:
		_apply_post_intro_state()
	else:
		_apply_intro_hidden_state()
		call_deferred("_play_intro_sequence")
	call_deferred("_sync_right_scene_with_rotation")


func _ready_editor_preview() -> void:
	_rng.randomize()
	set_process(false)
	set_process_input(false)
	_validate_input_actions()
	chapter_1_split.add_theme_constant_override("separation", int(split_divider_width_px))
	set_left_sphere_gp(left_sphere_gp_m, left_sphere_gp_n)
	_setup_default_sphere_material()
	chapter_1_split.dragger_visibility = 1
	# Keep editor preview lightweight and avoid runtime-only mesh/material warnings.
	_setup_right_placeholder()
	_setup_moire_overlays()
	_setup_camera_data_fragment_overlay()
	_setup_right_fragment_region_hint()
	_setup_final_curtains()
	dir_light.light_energy = light_energy
	right_panel.clip_contents = true
	_on_layout_changed()
	_ensure_chapter_hint_label()
	_setup_intro_overlay()
	if preview_post_intro_in_editor:
		_apply_post_intro_state()
	else:
		_apply_intro_hidden_state()
	_sync_right_scene_with_rotation()


func set_left_sphere_face_count(face_count: int) -> void:
	left_sphere_face_count = maxi(4, face_count)

	var sphere_mesh := sphere.mesh as SphereMesh
	if sphere_mesh == null:
		sphere_mesh = SphereMesh.new()
		sphere.mesh = sphere_mesh

	# SphereMesh uses radial_segments/rings to control visible polygon density.
	sphere_mesh.radial_segments = maxi(24, left_sphere_face_count)
	sphere_mesh.rings = maxi(12, int(float(left_sphere_face_count) / 2.0))
	sphere_mesh.radius = 1.0


func set_left_sphere_gp(m: int, n: int) -> void:
	left_sphere_gp_m = maxi(1, m)
	left_sphere_gp_n = maxi(0, n)

	# Goldberg index T = m^2 + m*n + n^2, total faces = 10*T + 2.
	var t := left_sphere_gp_m * left_sphere_gp_m + left_sphere_gp_m * left_sphere_gp_n + left_sphere_gp_n * left_sphere_gp_n
	var target_face_count := 10 * t + 2
	set_left_sphere_face_count(target_face_count)


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
	var mesh_scale := target_radius / maxf(0.0001, max_len)
	for i in range(verts.size()):
		verts[i] *= mesh_scale

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

		# Triangulate each pentagon as a fan to keep flat polygon faces.
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


func _process(delta: float) -> void:
	_update_anchor_frame_cube(delta)
	_update_orbit_cubes(delta)
	_update_vertical_preview_state()
	_update_hold_rotation(delta)
	_update_intro_overlay_geometry()
	_update_right_fragment_region_hint()

	if light_rotation_speed_deg == 0.0:
		return
	dir_light.rotate_y(deg_to_rad(light_rotation_speed_deg) * delta)


func _input(event: InputEvent) -> void:
	if _intro_sequence_running:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_try_begin_orbit_cube_drag(event.position)
		else:
			_end_orbit_cube_drag(event.position)
		return

	if event is InputEventMouseMotion and _dragging_orbit_cube_index >= 0:
		_update_orbit_cube_drag(event.position)
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_action_pressed("rotate_sphere_left"):
			_try_rotate_sphere_step(-1)
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("rotate_sphere_right"):
			_try_rotate_sphere_step(1)
			get_viewport().set_input_as_handled()
			return


func _setup_default_sphere_material() -> void:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode depth_draw_opaque, cull_back;

uniform vec4 base_color : source_color = vec4(0.46, 0.30, 0.18, 1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.76;
uniform float specular_strength : hint_range(0.0, 1.0) = 0.16;
uniform float relief_strength : hint_range(0.0, 0.25) = 0.048;
uniform float emission_strength : hint_range(0.0, 1.0) = 0.18;
uniform float emission_pulse : hint_range(0.0, 1.0) = 0.08;
uniform float fracture_line_strength : hint_range(0.0, 1.0) = 0.12;
uniform float fracture_density : hint_range(0.5, 12.0) = 4.6;
uniform float drift_speed : hint_range(0.0, 2.0) = 0.14;

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i + vec2(0.0, 0.0));
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	float freq = 1.0;
	for (int i = 0; i < 5; i++) {
		v += value_noise(p * freq) * a;
		freq *= 1.98;
		a *= 0.5;
	}
	return v;
}

float voronoi_soft(vec2 p, out float edge) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float md = 10.0;
	float sd = 10.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			vec2 o = vec2(hash21(i + g), hash21(i + g + vec2(13.1, 7.3)));
			vec2 r = g + o - f;
			float d = dot(r, r);
			if (d < md) {
				sd = md;
				md = d;
			} else if (d < sd) {
				sd = d;
			}
		}
	}
	edge = max(0.0, sd - md);
	return sqrt(md);
}

void vertex() {
	vec3 n = normalize(NORMAL);
	vec2 uv = UV * fracture_density + vec2(TIME * drift_speed, -TIME * drift_speed * 0.6);
	float wav = fbm(uv) * 0.6 + fbm(uv * 2.0 + 3.1) * 0.4;
	float h = (wav * 2.0 - 1.0) * relief_strength;
	VERTEX += n * h;
}

void fragment() {
	vec3 n = normalize(NORMAL);
	vec2 uv = UV * fracture_density + vec2(TIME * drift_speed * 0.7, TIME * drift_speed * 0.35);
	float edge;
	float cell = voronoi_soft(uv, edge);
	float cracks = 1.0 - smoothstep(0.012, 0.065, edge);
	float calm_noise = fbm(uv * 0.8 + 4.7);
	float lat = n.y * 0.5 + 0.5;
	vec3 cool = base_color.rgb * vec3(0.78, 0.86, 1.03);
	vec3 warm = base_color.rgb * vec3(1.05, 0.98, 0.88);
	vec3 albedo = mix(cool, warm, lat * 0.55 + calm_noise * 0.45);
	albedo = mix(albedo, albedo * 0.84, smoothstep(0.0, 1.0, cell));

	float pulse = sin(TIME * 1.4) * 0.5 + 0.5;
	float fres = pow(1.0 - clamp(dot(n, normalize(VIEW)), 0.0, 1.0), 2.8);
	vec3 fracture_tint = vec3(0.66, 0.86, 1.0) * cracks * fracture_line_strength;

	ALBEDO = albedo;
	ROUGHNESS = roughness;
	SPECULAR = specular_strength;
	EMISSION = albedo * (emission_strength * (0.72 + pulse * emission_pulse)) + fracture_tint + vec3(fres * emission_strength * 0.24);
}
"""
	var sphere_material := ShaderMaterial.new()
	sphere_material.shader = shader
	sphere_material.set_shader_parameter("base_color", left_sphere_color)
	sphere_material.set_shader_parameter("relief_strength", left_sphere_relief_strength)
	sphere_material.set_shader_parameter("emission_strength", left_sphere_emission_strength)
	sphere_material.set_shader_parameter("emission_pulse", left_sphere_emission_pulse)
	sphere.set_surface_override_material(0, sphere_material)
	sphere.scale = Vector3.ONE * maxf(0.1, left_sphere_scale)
	marker.visible = false


func _create_particle_sprite_material(sprite_tex: Texture2D, tint: Color, emission_energy: float) -> ORMMaterial3D:
	var mat := ORMMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.billboard_keep_scale = true
	mat.albedo_texture = sprite_tex
	mat.albedo_color = tint
	mat.emission_enabled = true
	mat.emission = Color(tint.r, tint.g, tint.b, 1.0)
	mat.emission_energy_multiplier = emission_energy
	return mat


func _get_particle_sprite_texture(fallback_index: int = 0) -> Texture2D:
	if NOTE_TEXTURES.is_empty():
		return null
	var idx := posmod(fallback_index, NOTE_TEXTURES.size())
	return NOTE_TEXTURES[idx]


func _build_particle_variants(
	base_emitter: GPUParticles3D,
	host: Node3D,
	base_name: String,
	tint: Color,
	emission_energy: float
) -> Array[GPUParticles3D]:
	var emitters: Array[GPUParticles3D] = []
	if base_emitter == null:
		return emitters
	if NOTE_TEXTURES.is_empty() or host == null:
		emitters.append(base_emitter)
		return emitters

	var base_quad := base_emitter.draw_pass_1 as QuadMesh
	var base_size := Vector2(0.5, 0.5)
	if base_quad != null:
		base_size = base_quad.size
	base_emitter.name = "%s_1" % base_name
	base_emitter.material_override = _create_particle_sprite_material(NOTE_TEXTURES[0], tint, emission_energy)
	emitters.append(base_emitter)

	for i in range(1, NOTE_TEXTURES.size()):
		var emitter := base_emitter.duplicate() as GPUParticles3D
		if emitter == null:
			continue
		emitter.name = "%s_%d" % [base_name, i + 1]
		emitter.material_override = _create_particle_sprite_material(NOTE_TEXTURES[i], tint, emission_energy)
		emitter.emitting = false
		if emitter.draw_pass_1 is QuadMesh:
			(emitter.draw_pass_1 as QuadMesh).size = base_size
		host.add_child(emitter)
		emitters.append(emitter)
	return emitters


func _drive_particle_variants(
	emitters: Array,
	active_idx: int,
	emitting: bool,
	amount_ratio: float,
	speed_scale: float
) -> void:
	if emitters.is_empty():
		return
	var safe_idx := clampi(active_idx, 0, emitters.size() - 1)
	for i in range(emitters.size()):
		var ps := emitters[i] as GPUParticles3D
		if ps == null:
			continue
		ps.emitting = emitting and i == safe_idx
		ps.amount_ratio = amount_ratio
		ps.speed_scale = speed_scale


func _apply_particle_kill_bounds(particle_system: GPUParticles3D, kill_radius: float) -> void:
	if particle_system == null:
		return
	# In local_coords mode particles move in emitter-local space.
	# Cube center in emitter-local coordinates is `-particle_system.position`.
	var center_local := -particle_system.position
	var ext := Vector3.ONE * maxf(0.01, kill_radius)
	particle_system.visibility_aabb = AABB(center_local - ext, ext * 2.0)


func _compute_particle_speed_cap(max_radius: float, spawn_offset: float, lifetime: float, base_velocity_max: float) -> float:
	var travel_cap := maxf(0.0, max_radius - spawn_offset)
	return travel_cap / maxf(0.001, lifetime * base_velocity_max)


func _capture_camera_focus_intensity_baseline() -> void:
	if _camera_focus_intensity_captured:
		return
	if _camera_data_overlay == null or not is_instance_valid(_camera_data_overlay):
		return
	var frag_mat := _camera_data_overlay.material as ShaderMaterial
	if frag_mat == null:
		return
	_camera_focus_intensity_baseline = {
		"overlay_alpha": _camera_data_overlay.color.a,
		"shift_strength": float(frag_mat.get_shader_parameter("shift_strength")),
		"chroma_amount": float(frag_mat.get_shader_parameter("chroma_amount")),
		"noise_amount": float(frag_mat.get_shader_parameter("noise_amount")),
		"line_mix": float(frag_mat.get_shader_parameter("line_mix")),
		"speed": float(frag_mat.get_shader_parameter("speed")),
		"quantize_steps": float(frag_mat.get_shader_parameter("quantize_steps")),
		"quantize_mix": float(frag_mat.get_shader_parameter("quantize_mix")),
	}
	_camera_focus_intensity_captured = true


func _apply_camera_focus_intensity_boost() -> void:
	if _camera_focus_intensity_boost_active:
		return
	_capture_camera_focus_intensity_baseline()
	if not _camera_focus_intensity_captured:
		return
	if _camera_data_overlay == null or not is_instance_valid(_camera_data_overlay):
		return
	var frag_mat := _camera_data_overlay.material as ShaderMaterial
	if frag_mat == null:
		return

	var base_alpha := float(_camera_focus_intensity_baseline.get("overlay_alpha", 0.35))
	var boosted_alpha := clampf(base_alpha * 1.95 + 0.12, 0.0, 0.95)
	_camera_data_overlay.color.a = boosted_alpha

	var base_shift := float(_camera_focus_intensity_baseline.get("shift_strength", camera_frag_shift))
	var base_chroma := float(_camera_focus_intensity_baseline.get("chroma_amount", camera_frag_chroma))
	var base_noise := float(_camera_focus_intensity_baseline.get("noise_amount", camera_frag_noise))
	var base_line := float(_camera_focus_intensity_baseline.get("line_mix", camera_frag_line_mix))
	var base_speed := float(_camera_focus_intensity_baseline.get("speed", camera_frag_speed))
	var base_quant_steps := float(_camera_focus_intensity_baseline.get("quantize_steps", camera_frag_quantize_steps))
	var base_quant_mix := float(_camera_focus_intensity_baseline.get("quantize_mix", camera_frag_quantize_mix))

	frag_mat.set_shader_parameter("shift_strength", clampf(base_shift * 2.6, 0.0, 0.2))
	frag_mat.set_shader_parameter("chroma_amount", clampf(base_chroma * 2.8 + 0.001, 0.0, 0.2))
	frag_mat.set_shader_parameter("noise_amount", clampf(base_noise * 2.4 + 0.03, 0.0, 1.0))
	frag_mat.set_shader_parameter("line_mix", clampf(base_line * 2.6 + 0.18, 0.0, 1.0))
	frag_mat.set_shader_parameter("speed", clampf(base_speed * 1.4, 0.0, 4.0))
	frag_mat.set_shader_parameter("quantize_steps", clampf(base_quant_steps * 0.75, 2.0, 128.0))
	frag_mat.set_shader_parameter("quantize_mix", clampf(base_quant_mix * 2.6 + 0.1, 0.0, 1.0))
	_camera_focus_intensity_boost_active = true


func _restore_camera_focus_intensity() -> void:
	if not _camera_focus_intensity_captured:
		return
	if _camera_data_overlay == null or not is_instance_valid(_camera_data_overlay):
		return
	var frag_mat := _camera_data_overlay.material as ShaderMaterial
	if frag_mat == null:
		return

	_camera_data_overlay.color.a = float(_camera_focus_intensity_baseline.get("overlay_alpha", 0.35))
	frag_mat.set_shader_parameter("shift_strength", float(_camera_focus_intensity_baseline.get("shift_strength", camera_frag_shift)))
	frag_mat.set_shader_parameter("chroma_amount", float(_camera_focus_intensity_baseline.get("chroma_amount", camera_frag_chroma)))
	frag_mat.set_shader_parameter("noise_amount", float(_camera_focus_intensity_baseline.get("noise_amount", camera_frag_noise)))
	frag_mat.set_shader_parameter("line_mix", float(_camera_focus_intensity_baseline.get("line_mix", camera_frag_line_mix)))
	frag_mat.set_shader_parameter("speed", float(_camera_focus_intensity_baseline.get("speed", camera_frag_speed)))
	frag_mat.set_shader_parameter("quantize_steps", float(_camera_focus_intensity_baseline.get("quantize_steps", camera_frag_quantize_steps)))
	frag_mat.set_shader_parameter("quantize_mix", float(_camera_focus_intensity_baseline.get("quantize_mix", camera_frag_quantize_mix)))
	_camera_focus_intensity_boost_active = false


func _setup_orbit_cubes() -> void:
	if _orbit_root != null and is_instance_valid(_orbit_root):
		return

	_orbit_root = Node3D.new()
	_orbit_root.name = "OrbitRoot"
	model_root.add_child(_orbit_root)

	var configs: Array[Dictionary] = [
		{
			"name": "CubeOrangeRed",
			"color": Color(1.0, 0.37, 0.22, 0.46),
			"phase": 0.0,
			"spin_period": 1.4,
			"particle_period": 1.05,
		},
		{
			"name": "CubeLightGreen",
			"color": Color(0.70, 0.98, 0.64, 0.44),
			"phase": PI * 0.5,
			"spin_period": 1.9,
			"particle_period": 1.32,
		},
		{
			"name": "CubeCyan",
			"color": Color(0.44, 0.94, 0.97, 0.42),
			"phase": PI,
			"spin_period": 1.65,
			"particle_period": 0.92,
		},
		{
			"name": "CubeLavender",
			"color": Color(0.86, 0.76, 0.98, 0.45),
			"phase": PI * 1.5,
			"spin_period": 2.2,
			"particle_period": 1.48,
		},
	]

	for cfg in configs:
		var pivot := Node3D.new()
		pivot.name = String(cfg.get("name", "CubePivot"))
		var is_red_cube := pivot.name == "CubeOrangeRed"
		var is_second_cube := pivot.name == "CubeLightGreen"
		var is_third_cube := pivot.name == "CubeCyan"
		var is_fourth_cube := pivot.name == "CubeLavender"
		var is_piano_cube := pivot.name == "CubeOrangeRed"
		_orbit_root.add_child(pivot)

		var cube := MeshInstance3D.new()
		cube.name = "Cube"
		if is_fourth_cube:
			var cyl := CylinderMesh.new()
			cyl.top_radius = maxf(0.02, orbit_cube_size * 0.5)
			cyl.bottom_radius = maxf(0.02, orbit_cube_size * 0.5)
			cyl.height = maxf(0.08, orbit_cube_size * 0.8)
			cyl.radial_segments = 48
			cube.mesh = cyl
		else:
			var box := BoxMesh.new()
			box.size = Vector3.ONE * maxf(0.1, orbit_cube_size)
			cube.mesh = box

		var cube_color := cfg.get("color", Color.WHITE) as Color
		if is_red_cube:
			var split_shader := Shader.new()
			split_shader.code = """
shader_type spatial;
render_mode depth_draw_opaque, cull_back;

uniform vec4 left_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 right_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float split_softness : hint_range(0.0, 0.15) = 0.01;
uniform float emission_strength : hint_range(0.0, 1.0) = 0.22;

varying vec3 v_local_pos;

void vertex() {
	v_local_pos = VERTEX;
}

void fragment() {
	float t = smoothstep(-split_softness, split_softness, v_local_pos.x);
	vec3 col = mix(left_color.rgb, right_color.rgb, t);
	ALBEDO = col;
	ROUGHNESS = 0.58;
	SPECULAR = 0.16;
	EMISSION = col * emission_strength;
}
"""
			var split_mat := ShaderMaterial.new()
			split_mat.shader = split_shader
			split_mat.set_shader_parameter("left_color", Color(1.0, 1.0, 1.0, 1.0))
			split_mat.set_shader_parameter("right_color", Color(0.0, 0.0, 0.0, 1.0))
			split_mat.set_shader_parameter("split_softness", 0.008)
			split_mat.set_shader_parameter("emission_strength", 0.24)
			cube.material_override = split_mat
		elif is_second_cube:
			var metal_mat := ORMMaterial3D.new()
			metal_mat.albedo_texture = SECOND_CUBE_UV_TEXTURE
			metal_mat.albedo_color = Color(0.95, 0.97, 1.0, 1.0)
			metal_mat.metallic = 0.95
			metal_mat.roughness = 0.18
			metal_mat.emission_enabled = true
			metal_mat.emission = Color(0.82, 0.9, 1.0, 1.0)
			metal_mat.emission_energy_multiplier = 0.18
			cube.material_override = metal_mat
		elif is_third_cube:
			var wood_mat_third := ORMMaterial3D.new()
			wood_mat_third.albedo_texture = THIRD_CUBE_UV_TEXTURE
			wood_mat_third.albedo_color = Color(0.88, 0.76, 0.60, 1.0)
			wood_mat_third.metallic = 0.02
			wood_mat_third.roughness = 0.78
			wood_mat_third.emission_enabled = true
			wood_mat_third.emission = Color(0.22, 0.16, 0.10, 1.0)
			wood_mat_third.emission_energy_multiplier = 0.06
			cube.material_override = wood_mat_third
		elif is_fourth_cube:
			var black_metal_mat := ORMMaterial3D.new()
			black_metal_mat.albedo_color = Color(0.03, 0.03, 0.04, 1.0)
			black_metal_mat.metallic = 0.96
			black_metal_mat.roughness = 0.14
			black_metal_mat.emission_enabled = true
			black_metal_mat.emission = Color(0.02, 0.02, 0.025, 1.0)
			black_metal_mat.emission_energy_multiplier = 0.05
			cube.material_override = black_metal_mat
		else:
			var mat := ORMMaterial3D.new()
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.albedo_color = cube_color
			mat.emission_enabled = true
			mat.emission = Color(cube_color.r, cube_color.g, cube_color.b, 1.0)
			mat.emission_energy_multiplier = 0.35
			cube.material_override = mat
		pivot.add_child(cube)

		var particles := GPUParticles3D.new()
		particles.name = "PulseParticles"
		particles.amount = 4
		particles.lifetime = 1.0
		particles.one_shot = false
		particles.emitting = true
		particles.local_coords = not is_fourth_cube
		particles.fixed_fps = 60
		particles.explosiveness = 0.0
		particles.randomness = 0.55
		particles.speed_scale = 1.0
		particles.draw_pass_1 = QuadMesh.new()
		var particle_quad := particles.draw_pass_1 as QuadMesh
		var sprite_size := maxf(0.30, orbit_cube_size * 1.08)
		var inlet_sprite_scale := 0.82 if is_second_cube else 1.0
		particle_quad.size = Vector2(sprite_size * inlet_sprite_scale, sprite_size * inlet_sprite_scale)
		var particle_tint := Color(cube_color.r, cube_color.g, cube_color.b, 0.92)
		var particle_emission := 1.22
		if is_second_cube:
			particle_tint = Color(0.92, 0.96, 1.0, 0.94)
			particle_emission = 1.12
		elif is_piano_cube:
			particle_tint = Color(1.0, 0.82, 0.72, 0.9)
			particle_emission = 1.08
		particles.material_override = _create_particle_sprite_material(_get_particle_sprite_texture(0), particle_tint, particle_emission)

		var proc := ParticleProcessMaterial.new()
		if is_second_cube:
			# Inlet stream: collected into the cube from one face.
			particles.amount = 4
			particles.lifetime = 1.0
			particles.position = Vector3(-orbit_cube_size * 1.08, 0.0, 0.0)
			proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
			proc.emission_box_extents = Vector3(maxf(0.007, orbit_cube_size * 0.018), orbit_cube_size * 0.13, orbit_cube_size * 0.13)
			proc.initial_velocity_min = 0.72
			proc.initial_velocity_max = 1.12
			proc.direction = Vector3(1.0, 0.0, 0.0)
			proc.spread = 1.6
			proc.gravity = Vector3.ZERO
		elif is_fourth_cube:
			proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			proc.emission_sphere_radius = maxf(0.02, orbit_cube_size * 0.24)
			proc.initial_velocity_min = 0.26
			proc.initial_velocity_max = 0.82
			proc.gravity = Vector3.ZERO
			proc.direction = Vector3.UP
			proc.spread = 0.0
		else:
			proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			proc.emission_sphere_radius = maxf(0.02, orbit_cube_size * 0.26)
			proc.initial_velocity_min = 0.24
			proc.initial_velocity_max = 0.88
			proc.gravity = Vector3(0.0, -0.06, 0.0)
			proc.direction = Vector3(0.0, 1.0, 0.0)
			proc.spread = 120.0
		proc.scale_min = 0.28
		proc.scale_max = 0.8
		if is_red_cube:
			var grad := Gradient.new()
			grad.add_point(0.0, Color(1.0, 1.0, 1.0, 0.85))
			grad.add_point(0.5, Color(0.62, 0.62, 0.62, 0.78))
			grad.add_point(1.0, Color(0.04, 0.04, 0.04, 0.70))
			var grad_tex := GradientTexture1D.new()
			grad_tex.gradient = grad
			proc.color_ramp = grad_tex
		particles.process_material = proc
		cube.add_child(particles)

		var particles_exit: GPUParticles3D = null
		if is_second_cube:
			particles_exit = GPUParticles3D.new()
			particles_exit.name = "PulseParticlesExit"
			particles_exit.amount = 4
			particles_exit.lifetime = 1.0
			particles_exit.one_shot = false
			particles_exit.emitting = true
			particles_exit.local_coords = true
			particles_exit.fixed_fps = 60
			particles_exit.explosiveness = 0.0
			particles_exit.randomness = 0.60
			particles_exit.speed_scale = 1.0
			particles_exit.position = Vector3(orbit_cube_size * 0.50, 0.0, 0.0)
			particles_exit.draw_pass_1 = QuadMesh.new()
			var exit_quad := particles_exit.draw_pass_1 as QuadMesh
			exit_quad.size = Vector2(sprite_size * 0.70, sprite_size * 0.70)
			particles_exit.material_override = _create_particle_sprite_material(
				_get_particle_sprite_texture(1),
				Color(0.95, 0.98, 1.0, 0.9),
				1.15
			)

			var proc_exit := ParticleProcessMaterial.new()
			proc_exit.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
			proc_exit.emission_box_extents = Vector3(maxf(0.007, orbit_cube_size * 0.018), orbit_cube_size * 0.13, orbit_cube_size * 0.13)
			proc_exit.initial_velocity_min = 0.52
			proc_exit.initial_velocity_max = 0.86
			proc_exit.scale_min = 0.26
			proc_exit.scale_max = 0.74
			proc_exit.gravity = Vector3.ZERO
			proc_exit.direction = Vector3(1.0, 0.0, 0.0)
			proc_exit.spread = 26.0
			particles_exit.process_material = proc_exit
			cube.add_child(particles_exit)

		var cube_vertex_radius := sqrt(3.0) * orbit_cube_size * 0.5
		var hard_kill_radius := 3.0 * cube_vertex_radius
		_apply_particle_kill_bounds(particles, hard_kill_radius)
		_apply_particle_kill_bounds(particles_exit, hard_kill_radius)
		var particle_variants := _build_particle_variants(particles, cube, "PulseParticles", particle_tint, particle_emission)
		var particle_exit_variants: Array[GPUParticles3D] = []
		if particles_exit != null:
			particle_exit_variants = _build_particle_variants(
				particles_exit,
				cube,
				"PulseParticlesExit",
				Color(0.95, 0.98, 1.0, 0.9),
				1.15
			)
		for ps in particle_variants:
			_apply_particle_kill_bounds(ps as GPUParticles3D, hard_kill_radius)
		for ps in particle_exit_variants:
			_apply_particle_kill_bounds(ps as GPUParticles3D, hard_kill_radius)

		_orbit_cube_entries.append(
			{
				"index": _orbit_cube_entries.size(),
				"pivot": pivot,
				"cube": cube,
				"particles": particles,
				"particles_exit": particles_exit,
				"particle_variants": particle_variants,
				"particle_exit_variants": particle_exit_variants,
				"is_second_cube": is_second_cube,
				"is_piano_cube": is_piano_cube,
				"phase": float(cfg.get("phase", 0.0)),
				"spin_period": float(cfg.get("spin_period", 1.6)),
				"particle_period": float(cfg.get("particle_period", 1.2)),
				"state": "orbit",
				"reject_wait": 0.0,
				"snap_anim_t": 0.0,
				"snap_anim_dur": 0.0,
				"snap_anim_start": Vector3.ZERO,
				"snap_anim_end": Vector3.ZERO,
				"pending_match": false,
				"eject_wait": -1.0,
				"eject_t": 0.0,
				"eject_dur": 0.0,
				"eject_start": Vector3.ZERO,
				"eject_end": Vector3.ZERO,
			}
		)


func _update_orbit_cubes(delta: float) -> void:
	if _orbit_cube_entries.is_empty():
		return
	_orbit_time_sec += delta

	for i in range(_orbit_cube_entries.size()):
		var entry := _orbit_cube_entries[i] as Dictionary
		var pivot := entry.get("pivot") as Node3D
		var cube := entry.get("cube") as MeshInstance3D
		var particles := entry.get("particles") as GPUParticles3D
		var particles_exit := entry.get("particles_exit") as GPUParticles3D
		var particle_variants := entry.get("particle_variants", []) as Array
		var particle_exit_variants := entry.get("particle_exit_variants", []) as Array
		var is_second_cube := bool(entry.get("is_second_cube", false))
		var is_piano_cube := bool(entry.get("is_piano_cube", false))
		if pivot == null or cube == null or particles == null:
			continue
		var is_fourth_cube := pivot.name == "CubeLavender"

		var phase := float(entry.get("phase", 0.0))
		var orbit_period := maxf(0.001, orbit_period_sec)
		var spin_period := maxf(0.001, float(entry.get("spin_period", 1.6)))
		var particle_period := maxf(0.001, float(entry.get("particle_period", 1.2)))
		var state := String(entry.get("state", "orbit"))

		var orbit_angle := phase + TAU * (_orbit_time_sec / orbit_period)
		var home_position := Vector3(
			cos(orbit_angle) * orbit_radius,
			orbit_height + sin(orbit_angle * 1.17 + phase) * 0.06,
			sin(orbit_angle) * orbit_radius
		)

		match state:
			"orbit":
				pivot.position = home_position
			"return_fast":
				pivot.position = pivot.position.move_toward(home_position, maxf(0.01, orbit_return_fast_speed) * delta)
				if pivot.position.distance_to(home_position) < 0.02:
					entry["state"] = "orbit"
			"return_slow":
				pivot.position = pivot.position.move_toward(home_position, maxf(0.01, orbit_return_slow_speed) * delta)
				if pivot.position.distance_to(home_position) < 0.02:
					entry["state"] = "orbit"
			"snap_reject_wait":
				var wait_left := maxf(0.0, float(entry.get("reject_wait", orbit_reject_wait_sec)) - delta)
				entry["reject_wait"] = wait_left
				pivot.global_position = _get_anchor_snap_world_position()
				if wait_left <= 0.0:
					entry["state"] = "return_slow"
			"snapped":
				pivot.global_position = _get_anchor_snap_world_position()
				var eject_wait := float(entry.get("eject_wait", -1.0))
				if eject_wait >= 0.0:
					eject_wait = maxf(0.0, eject_wait - delta)
					entry["eject_wait"] = eject_wait
					if eject_wait <= 0.0:
						var home_world: Vector3 = _orbit_root.to_global(home_position) if _orbit_root != null else home_position
						var eject_dir: Vector3 = home_world - _get_anchor_snap_world_position()
						if eject_dir.length_squared() < 0.0001:
							eject_dir = Vector3(0.0, 0.0, -1.0)
						eject_dir = eject_dir.normalized()
						entry["state"] = "eject_anim"
						entry["eject_t"] = 0.0
						entry["eject_dur"] = maxf(0.05, orbit_eject_anim_sec)
						entry["eject_start"] = _get_anchor_snap_world_position()
						entry["eject_end"] = _get_anchor_snap_world_position() + eject_dir * maxf(0.05, orbit_eject_distance)
			"snap_anim":
				var snap_dur := maxf(0.05, float(entry.get("snap_anim_dur", orbit_snap_anim_sec)))
				var snap_t := minf(1.0, float(entry.get("snap_anim_t", 0.0)) + delta / snap_dur)
				entry["snap_anim_t"] = snap_t
				var snap_start := entry.get("snap_anim_start", pivot.global_position) as Vector3
				var snap_end := _get_anchor_snap_world_position()
				entry["snap_anim_end"] = snap_end
				var snap_eased := snap_t * snap_t * (3.0 - 2.0 * snap_t)
				pivot.global_position = snap_start.lerp(snap_end, snap_eased)
				if snap_t >= 1.0:
					var cube_index := int(entry.get("index", i))
					var pending_match := bool(entry.get("pending_match", false))
					if pending_match:
						entry["state"] = "snapped"
						entry["eject_wait"] = maxf(0.0, orbit_completed_eject_delay_sec)
						_mark_scene_completed(cube_index)
						_flash_right_scene()
					else:
						entry["state"] = "snap_reject_wait"
						entry["reject_wait"] = maxf(0.0, orbit_reject_wait_sec)
			"eject_anim":
				var eject_dur := maxf(0.05, float(entry.get("eject_dur", orbit_eject_anim_sec)))
				var eject_t := minf(1.0, float(entry.get("eject_t", 0.0)) + delta / eject_dur)
				entry["eject_t"] = eject_t
				var eject_start := entry.get("eject_start", _get_anchor_snap_world_position()) as Vector3
				var eject_end := entry.get("eject_end", eject_start) as Vector3
				var eject_eased := 1.0 - pow(1.0 - eject_t, 3.0)
				pivot.global_position = eject_start.lerp(eject_end, eject_eased)
				if eject_t >= 1.0:
					entry["state"] = "return_fast"
					entry["reject_wait"] = 0.0
					entry["eject_wait"] = -1.0
					# Keep motion continuous on the transition frame to avoid a visible pause.
					pivot.position = pivot.position.move_toward(home_position, maxf(0.01, orbit_return_fast_speed) * delta)
			"drag":
				pass
			_:
				entry["state"] = "orbit"

		var spin_speed := TAU / spin_period
		if is_second_cube:
			var slow_spin := spin_speed * 0.16
			cube.rotate_x(delta * slow_spin * 0.35)
			cube.rotate_y(delta * slow_spin * 0.7)
			cube.rotate_z(delta * slow_spin * 0.22)
		else:
			cube.rotate_x(delta * spin_speed * 0.77)
			cube.rotate_y(delta * spin_speed * 1.0)
			cube.rotate_z(delta * spin_speed * 0.63)

		var pulse_period := 1.0
		var pulse := maxf(0.0, sin(TAU * (_orbit_time_sec / pulse_period) + phase))
		var note_cycle_count: int = maxi(1, NOTE_TEXTURES.size())
		var cycle_tick: int = int(floor(_orbit_time_sec / 0.25))
		var cycle_idx: int = 0
		if note_cycle_count > 0:
			cycle_idx = int(cycle_tick % note_cycle_count)
		# r = distance from cube rotation center to cube vertex.
		var cube_vertex_radius := sqrt(3.0) * orbit_cube_size * 0.5
		var max_note_radius := 2.0 * cube_vertex_radius
		if is_fourth_cube:
			max_note_radius = 2.7 * cube_vertex_radius
		var hard_kill_radius := 3.0 * cube_vertex_radius
		for ps in particle_variants:
			_apply_particle_kill_bounds(ps as GPUParticles3D, hard_kill_radius)
		for ps in particle_exit_variants:
			_apply_particle_kill_bounds(ps as GPUParticles3D, hard_kill_radius)
		var inlet_lifetime := maxf(0.001, particles.lifetime)
		var inlet_proc := particles.process_material as ParticleProcessMaterial
		var inlet_base_vmax := 1.0
		if inlet_proc != null:
			inlet_base_vmax = maxf(0.001, inlet_proc.initial_velocity_max)
		if is_second_cube:
			var inlet_amount := 1.0
			var inlet_target_speed := 0.38 + pulse * 0.16
			var inlet_offset := absf(orbit_cube_size * 1.08)
			var inlet_soft_speed_cap := _compute_particle_speed_cap(max_note_radius, inlet_offset, inlet_lifetime, inlet_base_vmax)
			var inlet_hard_speed_cap := _compute_particle_speed_cap(hard_kill_radius, inlet_offset, inlet_lifetime, inlet_base_vmax)
			var inlet_speed_cap := minf(inlet_soft_speed_cap, inlet_hard_speed_cap)
			var inlet_speed := minf(inlet_target_speed, inlet_speed_cap)
			_drive_particle_variants(particle_variants, cycle_idx, _orbit_particles_enabled, inlet_amount, inlet_speed)
			if particle_variants.is_empty():
				particles.emitting = _orbit_particles_enabled
			if particle_variants.is_empty():
				particles.amount_ratio = inlet_amount
				particles.speed_scale = inlet_speed
			if particles_exit != null:
				var outlet_lifetime := maxf(0.001, particles_exit.lifetime)
				var outlet_proc := particles_exit.process_material as ParticleProcessMaterial
				var outlet_base_vmax := 1.0
				if outlet_proc != null:
					outlet_base_vmax = maxf(0.001, outlet_proc.initial_velocity_max)
				var outlet_amount := 1.0
				var outlet_target_speed := 0.36 + pulse * 0.16
				var outlet_offset := absf(orbit_cube_size * 0.50)
				var outlet_soft_speed_cap := _compute_particle_speed_cap(max_note_radius, outlet_offset, outlet_lifetime, outlet_base_vmax)
				var outlet_hard_speed_cap := _compute_particle_speed_cap(hard_kill_radius, outlet_offset, outlet_lifetime, outlet_base_vmax)
				var outlet_speed_cap := minf(outlet_soft_speed_cap, outlet_hard_speed_cap)
				var outlet_speed := minf(outlet_target_speed, outlet_speed_cap)
				_drive_particle_variants(particle_exit_variants, cycle_idx, _orbit_particles_enabled, outlet_amount, outlet_speed)
				if particle_exit_variants.is_empty():
					particles_exit.emitting = _orbit_particles_enabled
				if particle_exit_variants.is_empty():
					particles_exit.amount_ratio = outlet_amount
					particles_exit.speed_scale = outlet_speed
		elif is_piano_cube:
			var piano_amount := 1.0
			var piano_target_speed := 0.30 + pulse * 0.18
			var piano_soft_speed_cap := _compute_particle_speed_cap(max_note_radius, 0.0, inlet_lifetime, inlet_base_vmax)
			var piano_hard_speed_cap := _compute_particle_speed_cap(hard_kill_radius, 0.0, inlet_lifetime, inlet_base_vmax)
			var piano_speed_cap := minf(piano_soft_speed_cap, piano_hard_speed_cap)
			var piano_speed := minf(piano_target_speed, piano_speed_cap)
			_drive_particle_variants(particle_variants, cycle_idx, _orbit_particles_enabled, piano_amount, piano_speed)
			if particle_variants.is_empty():
				particles.emitting = _orbit_particles_enabled
			if particle_variants.is_empty():
				particles.amount_ratio = piano_amount
				particles.speed_scale = piano_speed
		else:
			var orbit_amount := 1.0
			var orbit_target_speed := 0.34 + pulse * 0.20
			var orbit_soft_speed_cap := _compute_particle_speed_cap(max_note_radius, 0.0, inlet_lifetime, inlet_base_vmax)
			var orbit_hard_speed_cap := _compute_particle_speed_cap(hard_kill_radius, 0.0, inlet_lifetime, inlet_base_vmax)
			var orbit_speed_cap := minf(orbit_soft_speed_cap, orbit_hard_speed_cap)
			var orbit_speed := minf(orbit_target_speed, orbit_speed_cap)
			_drive_particle_variants(particle_variants, cycle_idx, _orbit_particles_enabled, orbit_amount, orbit_speed)
			if particle_variants.is_empty():
				particles.emitting = _orbit_particles_enabled
			if particle_variants.is_empty():
				particles.amount_ratio = orbit_amount
				particles.speed_scale = orbit_speed

		_orbit_cube_entries[i] = entry


func _try_begin_orbit_cube_drag(screen_pos: Vector2) -> void:
	if _final_transition_running:
		return
	if _dragging_orbit_cube_index >= 0:
		return
	var cube_index := _pick_orbit_cube(screen_pos)
	if cube_index < 0:
		return
	var entry := _orbit_cube_entries[cube_index] as Dictionary
	var state := String(entry.get("state", "orbit"))
	if state == "snapped" or state == "snap_anim" or state == "snap_reject_wait" or state == "eject_anim":
		return
	entry["state"] = "drag"
	entry["reject_wait"] = 0.0
	_orbit_cube_entries[cube_index] = entry
	_dragging_orbit_cube_index = cube_index

	var pivot := entry.get("pivot") as Node3D
	if pivot != null:
		_drag_cube_depth = camera_3d.global_position.distance_to(pivot.global_position)
	else:
		_drag_cube_depth = 3.0
	get_viewport().set_input_as_handled()


func _update_orbit_cube_drag(screen_pos: Vector2) -> void:
	if _dragging_orbit_cube_index < 0 or _dragging_orbit_cube_index >= _orbit_cube_entries.size():
		return
	var entry := _orbit_cube_entries[_dragging_orbit_cube_index] as Dictionary
	var pivot := entry.get("pivot") as Node3D
	if pivot == null:
		return

	var container_rect := left_3d.get_global_rect()
	if not container_rect.has_point(screen_pos):
		return
	var viewport_pos := _screen_to_left_viewport_position(screen_pos, container_rect)
	var ray_origin := camera_3d.project_ray_origin(viewport_pos)
	var ray_dir := camera_3d.project_ray_normal(viewport_pos).normalized()
	var target_world := ray_origin + ray_dir * _drag_cube_depth
	pivot.global_position = target_world


func _end_orbit_cube_drag(screen_pos: Vector2) -> void:
	if _dragging_orbit_cube_index < 0 or _dragging_orbit_cube_index >= _orbit_cube_entries.size():
		_dragging_orbit_cube_index = -1
		return
	var entry := _orbit_cube_entries[_dragging_orbit_cube_index] as Dictionary
	var pivot := entry.get("pivot") as Node3D
	if pivot == null:
		entry["state"] = "orbit"
		_orbit_cube_entries[_dragging_orbit_cube_index] = entry
		_dragging_orbit_cube_index = -1
		return

	var hit_anchor_on_screen := _is_point_near_anchor_on_screen(screen_pos)
	var snap_distance := pivot.global_position.distance_to(_get_anchor_snap_world_position())
	if hit_anchor_on_screen or snap_distance <= maxf(0.02, orbit_snap_radius):
		var cube_index := int(entry.get("index", _dragging_orbit_cube_index))
		entry["state"] = "snap_anim"
		entry["snap_anim_t"] = 0.0
		entry["snap_anim_dur"] = maxf(0.05, orbit_snap_anim_sec)
		entry["snap_anim_start"] = pivot.global_position
		entry["snap_anim_end"] = _get_anchor_snap_world_position()
		entry["pending_match"] = cube_index == _right_scene_current_index
		entry["eject_wait"] = -1.0
	else:
		entry["state"] = "return_fast"
		entry["reject_wait"] = 0.0
		entry["pending_match"] = false
		entry["eject_wait"] = -1.0

	_orbit_cube_entries[_dragging_orbit_cube_index] = entry
	_dragging_orbit_cube_index = -1


func _pick_orbit_cube(screen_pos: Vector2) -> int:
	var container_rect := left_3d.get_global_rect()
	if not container_rect.has_point(screen_pos):
		return -1

	var viewport_mouse := _screen_to_left_viewport_position(screen_pos, container_rect)
	var best_index := -1
	var best_dist := 1.0e20
	var hit_radius := 42.0 + orbit_cube_size * 30.0

	for i in range(_orbit_cube_entries.size()):
		var entry := _orbit_cube_entries[i] as Dictionary
		var state := String(entry.get("state", "orbit"))
		if state == "snapped" or state == "snap_anim" or state == "snap_reject_wait" or state == "eject_anim":
			continue
		var pivot := entry.get("pivot") as Node3D
		if pivot == null:
			continue
		if camera_3d.is_position_behind(pivot.global_position):
			continue
		var projected := camera_3d.unproject_position(pivot.global_position)
		var d := projected.distance_to(viewport_mouse)
		if d <= hit_radius and d < best_dist:
			best_dist = d
			best_index = i
	return best_index


func _screen_to_left_viewport_position(screen_pos: Vector2, container_rect: Rect2) -> Vector2:
	var local := screen_pos - container_rect.position
	var uv := Vector2(
		local.x / maxf(1.0, container_rect.size.x),
		local.y / maxf(1.0, container_rect.size.y)
	)
	uv.x = clampf(uv.x, 0.0, 1.0)
	uv.y = clampf(uv.y, 0.0, 1.0)
	return Vector2(
		uv.x * float(left_viewport.size.x),
		uv.y * float(left_viewport.size.y)
	)


func _get_anchor_snap_world_position() -> Vector3:
	if _anchor_frame_root == null:
		return Vector3.ZERO
	return _anchor_frame_root.global_position


func _is_point_near_anchor_on_screen(screen_pos: Vector2) -> bool:
	if camera_3d == null or left_viewport == null:
		return false
	if _anchor_frame_root == null:
		return false
	var container_rect := left_3d.get_global_rect()
	if not container_rect.has_point(screen_pos):
		return false
	if camera_3d.is_position_behind(_get_anchor_snap_world_position()):
		return false
	var viewport_anchor := camera_3d.unproject_position(_get_anchor_snap_world_position())
	var viewport_size := left_viewport.size
	var viewport_w := maxf(1.0, float(viewport_size.x))
	var viewport_h := maxf(1.0, float(viewport_size.y))
	var anchor_uv := Vector2(
		viewport_anchor.x / viewport_w,
		viewport_anchor.y / viewport_h
	)
	var anchor_screen := container_rect.position + Vector2(
		anchor_uv.x * container_rect.size.x,
		anchor_uv.y * container_rect.size.y
	)
	return anchor_screen.distance_to(screen_pos) <= maxf(8.0, orbit_snap_screen_radius_px)


func _is_anchor_occupied() -> bool:
	for entry in _orbit_cube_entries:
		var state := String((entry as Dictionary).get("state", ""))
		if state == "snapped" or state == "snap_anim" or state == "snap_reject_wait":
			return true
	return false


func _setup_final_curtains() -> void:
	if _final_curtain_layer != null and is_instance_valid(_final_curtain_layer):
		return

	_final_curtain_layer = Control.new()
	_final_curtain_layer.name = "FinalCurtainLayer"
	_final_curtain_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_final_curtain_layer.offset_left = 0.0
	_final_curtain_layer.offset_top = 0.0
	_final_curtain_layer.offset_right = 0.0
	_final_curtain_layer.offset_bottom = 0.0
	_final_curtain_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_final_curtain_layer.visible = false
	add_child(_final_curtain_layer)
	_final_curtain_layer.move_to_front()

	_final_curtain_left = ColorRect.new()
	_final_curtain_left.name = "FinalCurtainLeft"
	_final_curtain_left.anchor_left = 0.0
	_final_curtain_left.anchor_top = 0.0
	_final_curtain_left.anchor_right = 0.0
	_final_curtain_left.anchor_bottom = 1.0
	_final_curtain_left.offset_left = 0.0
	_final_curtain_left.offset_top = 0.0
	_final_curtain_left.offset_right = 0.0
	_final_curtain_left.offset_bottom = 0.0
	_final_curtain_left.color = Color(0.0, 0.0, 0.0, 1.0)
	_final_curtain_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_final_curtain_layer.add_child(_final_curtain_left)

	_final_curtain_right = ColorRect.new()
	_final_curtain_right.name = "FinalCurtainRight"
	_final_curtain_right.anchor_left = 1.0
	_final_curtain_right.anchor_top = 0.0
	_final_curtain_right.anchor_right = 1.0
	_final_curtain_right.anchor_bottom = 1.0
	_final_curtain_right.offset_left = 0.0
	_final_curtain_right.offset_top = 0.0
	_final_curtain_right.offset_right = 0.0
	_final_curtain_right.offset_bottom = 0.0
	_final_curtain_right.color = Color(0.0, 0.0, 0.0, 1.0)
	_final_curtain_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_final_curtain_layer.add_child(_final_curtain_right)


func _setup_intro_overlay() -> void:
	if _intro_overlay != null and is_instance_valid(_intro_overlay):
		return

	_intro_overlay = Control.new()
	_intro_overlay.name = "IntroSplitOverlay"
	_intro_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_intro_overlay.offset_left = 0.0
	_intro_overlay.offset_top = 0.0
	_intro_overlay.offset_right = 0.0
	_intro_overlay.offset_bottom = 0.0
	_intro_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_intro_overlay.modulate = Color(1.0, 1.0, 1.0, 0.0)
	add_child(_intro_overlay)
	_intro_overlay.move_to_front()

	_intro_left_frame = _create_intro_frame_panel("IntroLeftFrame")
	_intro_overlay.add_child(_intro_left_frame)

	_intro_right_frame = _create_intro_frame_panel("IntroRightFrame")
	_intro_overlay.add_child(_intro_right_frame)

	_intro_divider_line = ColorRect.new()
	_intro_divider_line.name = "IntroDividerLine"
	_intro_divider_line.color = Color(0.95, 0.95, 0.95, 0.95)
	_intro_divider_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_intro_overlay.add_child(_intro_divider_line)
	_update_intro_overlay_geometry()


func _create_intro_frame_panel(node_name: String) -> Panel:
	var panel := Panel.new()
	panel.name = node_name
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	style.border_width_left = 0
	style.border_width_top = 0
	style.border_width_right = 0
	style.border_width_bottom = 0
	style.border_color = Color(0.0, 0.0, 0.0, 0.0)
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _get_split_x() -> float:
	var w := maxf(1.0, size.x)
	return clampf(w * 0.5 + float(chapter_1_split.split_offset), 0.0, w)


func _update_intro_overlay_geometry() -> void:
	if _intro_overlay == null or not is_instance_valid(_intro_overlay):
		return
	if _intro_left_frame == null or _intro_right_frame == null or _intro_divider_line == null:
		return

	var split_x := _get_split_x()
	var w := maxf(1.0, size.x)
	var h := maxf(1.0, size.y)
	var divider_w := maxf(1.0, split_divider_width_px)

	_intro_left_frame.position = Vector2(0.0, 0.0)
	_intro_left_frame.size = Vector2(maxf(1.0, split_x), h)

	_intro_right_frame.position = Vector2(split_x, 0.0)
	_intro_right_frame.size = Vector2(maxf(1.0, w - split_x), h)

	_intro_divider_line.position = Vector2(split_x - divider_w * 0.5, 0.0)
	_intro_divider_line.size = Vector2(divider_w, h)


func _apply_intro_hidden_state() -> void:
	_intro_sequence_running = true
	_orbit_particles_enabled = false

	if _right_placeholder_root != null:
		_right_placeholder_root.visible = false
		_right_placeholder_root.modulate.a = 0.0

	if _right_moire_overlay != null:
		_right_moire_overlay.visible = false

	if _left_moire_overlay != null:
		_left_moire_overlay.visible = true
		_left_moire_overlay.modulate.a = 0.0

	if _camera_data_overlay != null:
		_camera_data_overlay.visible = true
		_camera_data_overlay.color.a = 0.0

	sphere.visible = false
	sphere.scale = Vector3.ONE * 0.02

	if _orbit_root != null:
		_orbit_root.visible = false
		for entry in _orbit_cube_entries:
			var cube := (entry as Dictionary).get("cube") as MeshInstance3D
			var particles := (entry as Dictionary).get("particles") as GPUParticles3D
			var particles_exit := (entry as Dictionary).get("particles_exit") as GPUParticles3D
			var particle_variants := (entry as Dictionary).get("particle_variants", []) as Array
			var particle_exit_variants := (entry as Dictionary).get("particle_exit_variants", []) as Array
			var pivot := (entry as Dictionary).get("pivot") as Node3D
			if pivot != null:
				pivot.visible = true
			if cube != null:
				cube.scale = Vector3.ONE * 0.02
			if particles != null:
				particles.emitting = false
			if particles_exit != null:
				particles_exit.emitting = false
			_drive_particle_variants(particle_variants, 0, false, 0.0, 0.0)
			_drive_particle_variants(particle_exit_variants, 0, false, 0.0, 0.0)

	if _anchor_frame_root != null:
		_anchor_frame_root.visible = false
		_anchor_frame_root.scale = Vector3.ONE * 0.02

	chapter_1_split.split_offset = 0
	_update_intro_overlay_geometry()


func _apply_post_intro_state() -> void:
	_intro_sequence_running = false
	_split_programmatic_motion = false
	_orbit_particles_enabled = true
	chapter_1_split.split_offset = _get_locked_split_offset()
	_update_intro_overlay_geometry()

	if _intro_overlay != null:
		_intro_overlay.modulate.a = 0.0
		_intro_overlay.visible = false

	if _right_placeholder_root != null:
		_right_placeholder_root.visible = true
		_right_placeholder_root.modulate.a = 1.0

	if _right_moire_overlay != null:
		_right_moire_overlay.visible = true

	if _left_moire_overlay != null:
		_left_moire_overlay.visible = true
		_left_moire_overlay.modulate.a = 1.0

	if _camera_data_overlay != null:
		_camera_data_overlay.visible = true
		_camera_data_overlay.color.a = 0.35

	sphere.visible = true
	sphere.scale = Vector3.ONE * maxf(0.1, left_sphere_scale)

	if _orbit_root != null:
		_orbit_root.visible = true
		for entry in _orbit_cube_entries:
			var cube := (entry as Dictionary).get("cube") as MeshInstance3D
			var particles := (entry as Dictionary).get("particles") as GPUParticles3D
			var particles_exit := (entry as Dictionary).get("particles_exit") as GPUParticles3D
			var particle_variants := (entry as Dictionary).get("particle_variants", []) as Array
			var particle_exit_variants := (entry as Dictionary).get("particle_exit_variants", []) as Array
			var pivot := (entry as Dictionary).get("pivot") as Node3D
			if pivot != null:
				pivot.visible = true
			if cube != null:
				cube.scale = Vector3.ONE
			if particles != null:
				particles.emitting = true
				particles.amount_ratio = 1.0
			if particles_exit != null:
				particles_exit.emitting = true
				particles_exit.amount_ratio = 1.0
			_drive_particle_variants(particle_variants, 0, true, 1.0, 1.0)
			_drive_particle_variants(particle_exit_variants, 0, true, 1.0, 1.0)

	if _anchor_frame_root != null:
		_anchor_frame_root.visible = true
		_anchor_frame_root.scale = Vector3.ONE

	_update_camera_data_overlay_region()
	_capture_camera_focus_intensity_baseline()
	_apply_camera_focus_intensity_boost()
	_update_right_fragment_region_hint()


func _play_intro_sequence() -> void:
	_intro_overlay.visible = true
	_orbit_particles_enabled = false
	var frame_tween := create_tween()
	frame_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	frame_tween.tween_property(_intro_overlay, "modulate:a", 1.0, maxf(0.01, intro_frame_fade_in_sec))
	await frame_tween.finished

	var pre_moire_tween := create_tween()
	pre_moire_tween.set_parallel(true)
	pre_moire_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if _left_moire_overlay != null:
		pre_moire_tween.tween_property(_left_moire_overlay, "modulate:a", 1.0, 0.32)
	if _camera_data_overlay != null:
		pre_moire_tween.tween_property(_camera_data_overlay, "color:a", 0.35, 0.36)
	await pre_moire_tween.finished

	var target_split_offset := _get_locked_split_offset()
	var split_tween := create_tween()
	split_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_split_programmatic_motion = true
	split_tween.tween_property(chapter_1_split, "split_offset", target_split_offset, maxf(0.01, intro_split_push_sec))
	await split_tween.finished
	_split_programmatic_motion = false

	sphere.visible = true
	var sphere_tween := create_tween()
	sphere_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	sphere_tween.tween_property(sphere, "scale", Vector3.ONE * maxf(0.1, left_sphere_scale), maxf(0.01, intro_sphere_appear_sec))
	await sphere_tween.finished

	if _orbit_root != null:
		_orbit_root.visible = true
		for i in range(_orbit_cube_entries.size()):
			var entry := _orbit_cube_entries[i] as Dictionary
			var cube := entry.get("cube") as MeshInstance3D
			var particles := entry.get("particles") as GPUParticles3D
			var particles_exit := entry.get("particles_exit") as GPUParticles3D
			var particle_variants := entry.get("particle_variants", []) as Array
			var particle_exit_variants := entry.get("particle_exit_variants", []) as Array
			if cube == null:
				continue
			var cube_tween := create_tween()
			cube_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			cube_tween.tween_property(cube, "scale", Vector3.ONE, maxf(0.01, intro_orbit_cube_scale_sec))
			await cube_tween.finished
			if particles != null:
				particles.emitting = false
				particles.amount_ratio = 1.0
			if particles_exit != null:
				particles_exit.emitting = false
				particles_exit.amount_ratio = 1.0
			_drive_particle_variants(particle_variants, 0, false, 1.0, 1.0)
			_drive_particle_variants(particle_exit_variants, 0, false, 1.0, 1.0)
			if i < _orbit_cube_entries.size() - 1:
				await get_tree().create_timer(maxf(0.01, intro_orbit_cube_step_sec)).timeout

	if _right_placeholder_root != null:
		_right_placeholder_root.visible = true
		var right_tween := create_tween()
		right_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		right_tween.tween_property(_right_placeholder_root, "modulate:a", 1.0, maxf(0.01, intro_right_panel_fade_in_sec))
		await right_tween.finished

	if _right_moire_overlay != null:
		_right_moire_overlay.visible = true
	if _left_moire_overlay != null:
		_left_moire_overlay.visible = true

	if _anchor_frame_root != null:
		_anchor_frame_root.visible = true
		var anchor_tween := create_tween()
		anchor_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		anchor_tween.tween_property(_anchor_frame_root, "scale", Vector3.ONE, maxf(0.01, intro_anchor_frame_appear_sec))
		await anchor_tween.finished

	_orbit_particles_enabled = true
	if _orbit_root != null:
		for entry in _orbit_cube_entries:
			var particles := (entry as Dictionary).get("particles") as GPUParticles3D
			var particles_exit := (entry as Dictionary).get("particles_exit") as GPUParticles3D
			var particle_variants := (entry as Dictionary).get("particle_variants", []) as Array
			var particle_exit_variants := (entry as Dictionary).get("particle_exit_variants", []) as Array
			if particles != null:
				particles.emitting = true
			if particles_exit != null:
				particles_exit.emitting = true
			_drive_particle_variants(particle_variants, 0, true, 1.0, 1.0)
			_drive_particle_variants(particle_exit_variants, 0, true, 1.0, 1.0)

	var hide_frame_tween := create_tween()
	hide_frame_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	hide_frame_tween.tween_property(_intro_overlay, "modulate:a", 0.0, 0.22)
	await hide_frame_tween.finished
	_intro_overlay.visible = false
	_intro_sequence_running = false
	_capture_camera_focus_intensity_baseline()
	_apply_camera_focus_intensity_boost()


func _setup_anchor_frame_cube() -> void:
	if _anchor_frame_root != null and is_instance_valid(_anchor_frame_root):
		return

	_anchor_frame_root = Node3D.new()
	_anchor_frame_root.name = "AnchorFrameCube"
	_anchor_frame_root.position = Vector3(0.0, anchor_frame_y_offset, 0.0)
	world_3d.add_child(_anchor_frame_root)

	var frame_size := maxf(0.08, orbit_cube_size)
	var half := frame_size * 0.5
	var rod_t := frame_size * 0.09

	var rod_mesh_x := BoxMesh.new()
	rod_mesh_x.size = Vector3(frame_size, rod_t, rod_t)
	var rod_mesh_y := BoxMesh.new()
	rod_mesh_y.size = Vector3(rod_t, frame_size, rod_t)
	var rod_mesh_z := BoxMesh.new()
	rod_mesh_z.size = Vector3(rod_t, rod_t, frame_size)

	var mat := ORMMaterial3D.new()
	mat.albedo_color = Color(0.36, 0.38, 0.42, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.40, 0.44, 0.50, 1.0)
	mat.emission_energy_multiplier = 0.28

	var x_edges := [
		Vector3(0.0, half, half),
		Vector3(0.0, half, -half),
		Vector3(0.0, -half, half),
		Vector3(0.0, -half, -half),
	]
	for p in x_edges:
		var rod := MeshInstance3D.new()
		rod.mesh = rod_mesh_x
		rod.position = p
		rod.material_override = mat
		rod.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_anchor_frame_root.add_child(rod)

	var y_edges := [
		Vector3(half, 0.0, half),
		Vector3(half, 0.0, -half),
		Vector3(-half, 0.0, half),
		Vector3(-half, 0.0, -half),
	]
	for p in y_edges:
		var rod := MeshInstance3D.new()
		rod.mesh = rod_mesh_y
		rod.position = p
		rod.material_override = mat
		rod.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_anchor_frame_root.add_child(rod)

	var z_edges := [
		Vector3(half, half, 0.0),
		Vector3(half, -half, 0.0),
		Vector3(-half, half, 0.0),
		Vector3(-half, -half, 0.0),
	]
	for p in z_edges:
		var rod := MeshInstance3D.new()
		rod.mesh = rod_mesh_z
		rod.position = p
		rod.material_override = mat
		rod.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_anchor_frame_root.add_child(rod)


func _update_anchor_frame_cube(delta: float) -> void:
	if _anchor_frame_root == null:
		return
	var spin_rad := deg_to_rad(anchor_frame_spin_speed_deg) * delta
	_anchor_frame_root.rotate_y(spin_rad)
	_anchor_frame_root.rotate_x(spin_rad * 0.37)


func _setup_right_placeholder() -> void:
	if line_canvas != null and is_instance_valid(line_canvas):
		if line_canvas.has_method("clear_lines"):
			line_canvas.clear_lines()
		line_canvas.visible = false

	_right_placeholder_root = right_panel.get_node_or_null("RightPlaceholder") as Control
	if _right_placeholder_root == null:
		_right_placeholder_root = Control.new()
		_right_placeholder_root.name = "RightPlaceholder"
		_right_placeholder_root.set_anchors_preset(Control.PRESET_FULL_RECT)
		_right_placeholder_root.offset_left = 0.0
		_right_placeholder_root.offset_top = 0.0
		_right_placeholder_root.offset_right = 0.0
		_right_placeholder_root.offset_bottom = 0.0
		_right_placeholder_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		right_panel.add_child(_right_placeholder_root)

	var bg := _right_placeholder_root.get_node_or_null("PlaceholderBg") as ColorRect
	if bg == null:
		bg = ColorRect.new()
		bg.name = "PlaceholderBg"
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.offset_left = 0.0
		bg.offset_top = 0.0
		bg.offset_right = 0.0
		bg.offset_bottom = 0.0
		bg.color = Color(0.09, 0.08, 0.06, 1.0)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_right_placeholder_root.add_child(bg)

	_right_scene_root = _right_placeholder_root.get_node_or_null("SceneStage") as Control
	if _right_scene_root == null:
		_right_scene_root = Control.new()
		_right_scene_root.name = "SceneStage"
		_right_scene_root.set_anchors_preset(Control.PRESET_FULL_RECT)
		_right_scene_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_right_placeholder_root.add_child(_right_scene_root)
	_right_scene_root.offset_left = right_scene_stage_left_px
	_right_scene_root.offset_top = right_scene_stage_top_px
	_right_scene_root.offset_right = -right_scene_stage_right_px
	_right_scene_root.offset_bottom = -right_scene_stage_bottom_px

	_right_scene_cards.clear()
	_right_scene_status_labels.clear()
	_right_scene_completed.clear()

	for i in range(RIGHT_SCENE_TEXTURES.size()):
		var card_name := "SceneCard%d" % (i + 1)
		var panel := _right_scene_root.get_node_or_null(card_name) as Control
		if panel == null:
			var created_panel := PanelContainer.new()
			created_panel.name = card_name
			created_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
			created_panel.offset_left = 0.0
			created_panel.offset_top = 0.0
			created_panel.offset_right = 0.0
			created_panel.offset_bottom = 0.0
			created_panel.custom_minimum_size = Vector2.ZERO
			created_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			created_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
			created_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var style := StyleBoxFlat.new()
			style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
			style.border_width_left = 0
			style.border_width_top = 0
			style.border_width_right = 0
			style.border_width_bottom = 0
			created_panel.add_theme_stylebox_override("panel", style)
			_right_scene_root.add_child(created_panel)
			panel = created_panel
		else:
			panel.set_anchors_preset(Control.PRESET_FULL_RECT)
			panel.offset_left = 0.0
			panel.offset_top = 0.0
			panel.offset_right = 0.0
			panel.offset_bottom = 0.0

		var image := panel.get_node_or_null("SceneImage") as TextureRect
		if image == null:
			image = TextureRect.new()
			image.name = "SceneImage"
			panel.add_child(image)
		image.set_anchors_preset(Control.PRESET_FULL_RECT)
		image.offset_left = right_scene_image_left_px
		image.offset_top = right_scene_image_top_px
		image.offset_right = -right_scene_image_right_px
		image.offset_bottom = -right_scene_image_bottom_px
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_SCALE
		image.texture = RIGHT_SCENE_TEXTURES[i]
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var status := panel.get_node_or_null("Status") as Label
		if status == null:
			status = Label.new()
			status.name = "Status"
			status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			status.vertical_alignment = VERTICAL_ALIGNMENT_TOP
			status.mouse_filter = Control.MOUSE_FILTER_IGNORE
			panel.add_child(status)
		status.text = "Pending"
		status.visible = false

		panel.visible = false
		panel.modulate.a = 0.0
		_right_scene_cards.append(panel)
		_right_scene_status_labels.append(status)
		_right_scene_completed.append(false)

	_right_scene_flash_overlay = _right_scene_root.get_node_or_null("SceneFlashOverlay") as ColorRect
	if _right_scene_flash_overlay == null:
		_right_scene_flash_overlay = ColorRect.new()
		_right_scene_flash_overlay.name = "SceneFlashOverlay"
		_right_scene_flash_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		_right_scene_flash_overlay.offset_left = 0.0
		_right_scene_flash_overlay.offset_top = 0.0
		_right_scene_flash_overlay.offset_right = 0.0
		_right_scene_flash_overlay.offset_bottom = 0.0
		_right_scene_flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_right_scene_root.add_child(_right_scene_flash_overlay)
	_right_scene_flash_overlay.color = Color(1.0, 1.0, 1.0, 0.0)

	_right_scene_dim_overlay = _right_scene_root.get_node_or_null("RightSceneDimOverlay") as ColorRect
	if _right_scene_dim_overlay == null:
		_right_scene_dim_overlay = ColorRect.new()
		_right_scene_dim_overlay.name = "RightSceneDimOverlay"
		_right_scene_dim_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		_right_scene_dim_overlay.offset_left = 0.0
		_right_scene_dim_overlay.offset_top = 0.0
		_right_scene_dim_overlay.offset_right = 0.0
		_right_scene_dim_overlay.offset_bottom = 0.0
		_right_scene_dim_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_right_scene_root.add_child(_right_scene_dim_overlay)
	_right_scene_dim_overlay.color = Color(0.0, 0.0, 0.0, clampf(right_scene_dim_alpha, 0.0, 0.8))
	_right_scene_dim_overlay.move_to_front()

	_right_scene_flash_overlay.move_to_front()
	_right_placeholder_root.move_to_front()

	_switch_right_scene(0, true)


func _setup_moire_overlays() -> void:
	_left_moire_overlay = _create_moire_overlay("LeftMoireOverlay")
	right_panel.add_child(_left_moire_overlay)
	_left_moire_overlay.move_to_front()
	if _left_moire_overlay.material is ShaderMaterial:
		var left_mat := _left_moire_overlay.material as ShaderMaterial
		left_mat.set_shader_parameter("effect_strength", moire_strength * clampf(left_moire_intensity_scale, 0.0, 1.0))

	_right_moire_overlay = _create_moire_overlay("RightMoireOverlay")
	left_3d.add_child(_right_moire_overlay)
	_right_moire_overlay.move_to_front()


func _setup_camera_data_fragment_overlay() -> void:
	if _camera_data_overlay != null and is_instance_valid(_camera_data_overlay):
		return

	_camera_data_overlay = ColorRect.new()
	_camera_data_overlay.name = "CameraDataFragmentOverlay"
	_camera_data_overlay.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_camera_data_overlay.offset_left = 0.0
	_camera_data_overlay.offset_top = 0.0
	_camera_data_overlay.offset_right = 0.0
	_camera_data_overlay.offset_bottom = 0.0
	_camera_data_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_camera_data_overlay.color = Color(1.0, 1.0, 1.0, 0.0)

	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float shift_strength : hint_range(0.0, 0.2) = 0.012;
uniform float chroma_amount : hint_range(0.0, 0.2) = 0.004;
uniform float noise_amount : hint_range(0.0, 1.0) = 0.09;
uniform float line_mix : hint_range(0.0, 1.0) = 0.22;
uniform float speed : hint_range(0.0, 4.0) = 0.6;
uniform float quantize_steps : hint_range(2.0, 128.0) = 32.0;
uniform float quantize_mix : hint_range(0.0, 1.0) = 0.22;

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float t = TIME * speed;
	float band = floor(uv.y * 110.0 + t * 6.0);
	float n = hash21(vec2(band, floor(t * 18.0)));
	float s = (n - 0.5) * shift_strength;
	vec2 suv = uv + vec2(s, 0.0);

	float r = texture(screen_tex, suv + vec2(chroma_amount, 0.0)).r;
	float g = texture(screen_tex, suv).g;
	float b = texture(screen_tex, suv - vec2(chroma_amount, 0.0)).b;
	vec3 base = vec3(r, g, b);

	float scan = sin((uv.y + t * 0.08) * 900.0) * 0.5 + 0.5;
	float grain = hash21(uv * vec2(1900.0, 1060.0) + t * 31.0) - 0.5;
	vec3 glitched = base + vec3(grain * noise_amount * 0.12);
	glitched *= mix(1.0, 0.92 + scan * 0.08, line_mix);
	vec3 quantized = floor(glitched * quantize_steps) / quantize_steps;
	glitched = mix(glitched, quantized, quantize_mix);

	COLOR = vec4(glitched, 1.0);
}
"""

	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("shift_strength", camera_frag_shift)
	material.set_shader_parameter("chroma_amount", camera_frag_chroma)
	material.set_shader_parameter("noise_amount", camera_frag_noise)
	material.set_shader_parameter("line_mix", camera_frag_line_mix)
	material.set_shader_parameter("speed", camera_frag_speed)
	material.set_shader_parameter("quantize_steps", camera_frag_quantize_steps)
	material.set_shader_parameter("quantize_mix", camera_frag_quantize_mix)
	_camera_data_overlay.material = material

	if _right_scene_root != null and is_instance_valid(_right_scene_root):
		_right_scene_root.add_child(_camera_data_overlay)
	else:
		right_panel.add_child(_camera_data_overlay)
	_update_camera_data_overlay_region()
	_camera_data_overlay.move_to_front()


func _setup_right_fragment_region_hint() -> void:
	# Intentionally disabled: user requested no fragment-region border UI.
	if _right_frag_region_hint != null and is_instance_valid(_right_frag_region_hint):
		_right_frag_region_hint.visible = false


func _update_right_fragment_region_hint() -> void:
	if _right_frag_region_hint != null and is_instance_valid(_right_frag_region_hint):
		_right_frag_region_hint.visible = false


func _update_right_fragment_region_hint_visuals() -> void:
	return


func _update_camera_data_overlay_region() -> void:
	if _camera_data_overlay == null:
		return

	if _right_scene_root == null or not is_instance_valid(_right_scene_root):
		_camera_data_overlay.visible = false
		_update_right_fragment_region_hint()
		return

	if _camera_data_overlay.get_parent() != _right_scene_root:
		if _camera_data_overlay.get_parent() != null:
			_camera_data_overlay.get_parent().remove_child(_camera_data_overlay)
		_right_scene_root.add_child(_camera_data_overlay)
		_camera_data_overlay.move_to_front()

	if _right_scene_flash_overlay == null or not is_instance_valid(_right_scene_flash_overlay):
		_camera_data_overlay.visible = false
		_update_right_fragment_region_hint()
		return

	var left_px := maxf(0.0, camera_frag_region_inset_left_px)
	var top_px := maxf(0.0, camera_frag_region_inset_top_px)
	var right_px := maxf(0.0, camera_frag_region_inset_right_px)
	var bottom_px := maxf(0.0, camera_frag_region_inset_bottom_px)

	var flash_pos := _right_scene_flash_overlay.position
	var flash_size := _right_scene_flash_overlay.size
	var x := maxf(0.0, flash_pos.x + left_px)
	var y := maxf(0.0, flash_pos.y + top_px)
	var w := maxf(1.0, flash_size.x - left_px - right_px)
	var h := maxf(1.0, flash_size.y - top_px - bottom_px)
	x = clampf(x, 0.0, maxf(0.0, _right_scene_root.size.x - 1.0))
	y = clampf(y, 0.0, maxf(0.0, _right_scene_root.size.y - 1.0))
	w = clampf(w, 1.0, maxf(1.0, _right_scene_root.size.x - x))
	h = clampf(h, 1.0, maxf(1.0, _right_scene_root.size.y - y))
	_camera_data_overlay.position = Vector2(x, y)
	_camera_data_overlay.size = Vector2(w, h)
	_camera_data_overlay.visible = true
	_camera_data_overlay.move_to_front()
	_update_right_fragment_region_hint()


func _create_moire_overlay(node_name: String) -> ColorRect:
	var overlay := ColorRect.new()
	overlay.name = node_name
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.offset_left = 0.0
	overlay.offset_top = 0.0
	overlay.offset_right = 0.0
	overlay.offset_bottom = 0.0
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.color = Color(1.0, 1.0, 1.0, 1.0)

	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
render_mode unshaded;

uniform float effect_strength : hint_range(0.0, 1.0) = 0.82;
uniform float noise_strength : hint_range(0.0, 0.6) = 0.16;
uniform float noise_speed : hint_range(0.0, 12.0) = 2.1;
uniform float noise_density : hint_range(120.0, 2200.0) = 1250.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
	vec2 uv = UV;
	float t = TIME;
	vec2 grid = floor(uv * vec2(noise_density * 0.018, noise_density * 0.010));
	float n = hash(grid + vec2(t * noise_speed * 0.55, -t * noise_speed * 0.42));
	float line_a = sin((uv.x + uv.y) * 150.0 + t * noise_speed * 2.1);
	float line_b = sin((uv.x - uv.y) * 123.0 - t * noise_speed * 1.7);
	float moire = abs(line_a * line_b);
	float alpha = clamp((moire * (0.08 + noise_strength * 0.22) + n * 0.06) * effect_strength, 0.0, 0.28);
	COLOR = vec4(vec3(1.0), alpha);
}
"""

	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("effect_strength", moire_strength)
	material.set_shader_parameter("noise_strength", moire_noise_strength)
	material.set_shader_parameter("noise_speed", moire_noise_speed)
	material.set_shader_parameter("noise_density", moire_noise_density)
	overlay.material = material
	return overlay


func _draw_default_line_art() -> void:
	_switch_right_scene(0, true)


func _on_layout_changed() -> void:
	_enforce_chapter_1_constraints()
	_setup_fixed_right_canvas()
	_update_camera_data_overlay_region()
	for card in _right_scene_cards:
		_normalize_right_scene_card(card)

	# Redraw default line art when the panel size changes.
	if sync_right_scene_on_rotate:
		_sync_right_scene_with_rotation()
	else:
		_switch_right_scene(0, true)


func _rotate_sphere_step(step_direction: int) -> void:
	if step_direction == 0:
		return

	_rotation_input_block_until_ms = Time.get_ticks_msec() + int(rotation_input_block_sec * 1000.0)

	# Use cumulative angle so crossing 360 deg keeps rotating in the same direction.
	_rotation_step_count += step_direction
	var target_y := deg_to_rad(rotation_step_deg * float(_rotation_step_count))

	if is_instance_valid(_sphere_rotate_tween):
		_sphere_rotate_tween.kill()

	_sphere_rotate_tween = create_tween()
	_sphere_rotate_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_sphere_rotate_tween.tween_property(model_root, "rotation:y", target_y, rotation_step_duration)

	if sync_right_scene_on_rotate:
		_sync_right_scene_with_rotation()


func _sync_right_scene_with_rotation() -> void:
	var idx := posmod(_rotation_step_count, 4)
	_switch_right_scene(idx, false)


func _switch_right_scene(scene_index: int, immediate: bool = false) -> void:
	if _right_scene_cards.is_empty():
		return
	var target := posmod(scene_index, _right_scene_cards.size())
	if not immediate and _right_scene_current_index == target:
		return

	if is_instance_valid(_right_scene_transition_tween):
		_right_scene_transition_tween.kill()
	_right_scene_transition_tween = null

	if immediate or _right_scene_current_index < 0:
		_right_scene_transition_id += 1
		for i in range(_right_scene_cards.size()):
			var card := _right_scene_cards[i]
			_normalize_right_scene_card(card)
			var active := i == target
			card.visible = active
			card.modulate.a = 1.0 if active else 0.0
		_right_scene_current_index = target
		return

	var old_index := _right_scene_current_index
	var old_card := _right_scene_cards[old_index]
	var new_card := _right_scene_cards[target]
	var direction := 1.0 if target > old_index else -1.0
	if old_index == _right_scene_cards.size() - 1 and target == 0:
		direction = 1.0
	elif old_index == 0 and target == _right_scene_cards.size() - 1:
		direction = -1.0

	_right_scene_transition_id += 1
	var transition_id := _right_scene_transition_id
	_normalize_right_scene_card(old_card)
	_normalize_right_scene_card(new_card)
	new_card.visible = true
	new_card.position = Vector2(56.0 * direction, 0.0)
	new_card.modulate.a = 0.0
	old_card.position = Vector2.ZERO
	old_card.modulate.a = 1.0

	_right_scene_current_index = target
	_right_scene_transition_tween = create_tween()
	_right_scene_transition_tween.set_parallel(true)
	_right_scene_transition_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_right_scene_transition_tween.tween_property(old_card, "position", Vector2(-56.0 * direction, 0.0), 0.28)
	_right_scene_transition_tween.tween_property(old_card, "modulate:a", 0.0, 0.24)
	_right_scene_transition_tween.tween_property(new_card, "position", Vector2.ZERO, 0.30)
	_right_scene_transition_tween.tween_property(new_card, "modulate:a", 1.0, 0.28)
	_right_scene_transition_tween.finished.connect(
		Callable(self, "_on_right_scene_transition_finished").bind(transition_id),
		CONNECT_ONE_SHOT
	)


func _on_right_scene_transition_finished(transition_id: int) -> void:
	if transition_id != _right_scene_transition_id:
		return
	for i in range(_right_scene_cards.size()):
		var card := _right_scene_cards[i]
		if card == null:
			continue
		_normalize_right_scene_card(card)
		var active := i == _right_scene_current_index
		card.visible = active
		card.modulate.a = 1.0 if active else 0.0
	_right_scene_transition_tween = null


func _normalize_right_scene_card(card: Control) -> void:
	if card == null:
		return
	card.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.offset_left = 0.0
	card.offset_top = 0.0
	card.offset_right = 0.0
	card.offset_bottom = 0.0
	card.position = Vector2.ZERO
	card.scale = Vector2.ONE
	card.rotation = 0.0


func _mark_scene_completed(scene_index: int) -> void:
	_restore_camera_focus_intensity()
	var idx := posmod(scene_index, _right_scene_status_labels.size())
	if idx < 0 or idx >= _right_scene_status_labels.size():
		return
	_right_scene_completed[idx] = true
	var status := _right_scene_status_labels[idx]
	if status != null:
		status.text = "Completed"
		status.modulate = Color(1.0, 0.95, 0.68, 1.0)
	if _are_all_right_scenes_completed():
		call_deferred("_show_continue_button")


func _are_all_right_scenes_completed() -> bool:
	if _right_scene_completed.is_empty():
		return false
	for done_variant in _right_scene_completed:
		if not bool(done_variant):
			return false
	return true


func _start_final_close_transition() -> void:
	if _final_transition_running or _chapter_completed_once:
		return
	_final_transition_running = true
	_chapter_completed_once = true

	if _dragging_orbit_cube_index >= 0:
		_dragging_orbit_cube_index = -1

	if _final_curtain_layer == null or not is_instance_valid(_final_curtain_layer):
		_setup_final_curtains()
	if _final_curtain_layer == null:
		chapter_completed.emit(chapter_index)
		return

	_final_curtain_layer.visible = true
	_final_curtain_layer.move_to_front()
	_final_curtain_left.offset_right = 0.0
	_final_curtain_right.offset_left = 0.0

	var half_width := maxf(1.0, size.x * 0.5 + 2.0)
	var close_tween := create_tween()
	close_tween.set_parallel(true)
	close_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	close_tween.tween_property(_final_curtain_left, "offset_right", half_width, maxf(0.05, final_close_to_black_sec))
	close_tween.tween_property(_final_curtain_right, "offset_left", -half_width, maxf(0.05, final_close_to_black_sec))
	await close_tween.finished

	if final_black_hold_sec > 0.0:
		await get_tree().create_timer(final_black_hold_sec).timeout

	chapter_completed.emit(chapter_index)


func _flash_right_scene() -> void:
	if _right_scene_flash_overlay == null:
		return
	if is_instance_valid(_right_scene_flash_tween):
		_right_scene_flash_tween.kill()
	_right_scene_flash_overlay.color.a = 0.0
	_right_scene_flash_tween = create_tween()
	_right_scene_flash_tween.tween_property(_right_scene_flash_overlay, "color:a", 0.78, 0.12)
	_right_scene_flash_tween.tween_property(_right_scene_flash_overlay, "color:a", 0.0, 0.36)


func _show_continue_button() -> void:
	if _continue_button == null:
		_ensure_continue_button()
	if _continue_button == null:
		return
	_continue_button.visible = true
	_continue_button.disabled = false
	_continue_button.modulate.a = 0.0
	_continue_button.scale = Vector2(0.92, 0.92)
	_continue_button.move_to_front()

	var t := create_tween()
	t.set_parallel(true)
	t.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_continue_button, "modulate:a", 1.0, 0.24)
	t.tween_property(_continue_button, "scale", Vector2.ONE, 0.30)


func _on_continue_button_pressed() -> void:
	if _continue_button != null:
		_continue_button.disabled = true
		_continue_button.visible = false
	_start_final_close_transition()


func _is_rotation_input_blocked() -> bool:
	return Time.get_ticks_msec() < _rotation_input_block_until_ms


func _is_sphere_input_locked() -> bool:
	return _intro_sequence_running or _final_transition_running or _is_rotation_input_blocked() or _vertical_preview_phase != 0 or _is_anchor_occupied()


func _try_rotate_sphere_step(step_direction: int) -> void:
	if _is_sphere_input_locked():
		return
	_rotate_sphere_step(step_direction)


func _update_hold_rotation(delta: float) -> void:
	var desired_dir := 0
	if Input.is_action_pressed("rotate_sphere_left"):
		desired_dir -= 1
	if Input.is_action_pressed("rotate_sphere_right"):
		desired_dir += 1

	if desired_dir == 0:
		_hold_rotate_dir = 0
		_hold_rotate_elapsed = 0.0
		return

	if desired_dir != _hold_rotate_dir:
		_hold_rotate_dir = desired_dir
		_hold_rotate_elapsed = 0.0
		return

	if _is_sphere_input_locked():
		_hold_rotate_elapsed = 0.0
		return

	_hold_rotate_elapsed += delta
	if _hold_rotate_elapsed >= hold_rotate_interval_sec:
		_try_rotate_sphere_step(_hold_rotate_dir)
		_hold_rotate_elapsed = 0.0


func _try_vertical_face_preview_from_drag() -> bool:
	if not enable_vertical_face_preview:
		return false
	if _vertical_preview_phase != 0:
		return false
	if not _is_dragging_sphere:
		return false
	if _is_sphere_input_locked():
		return false

	var threshold := maxf(1.0, vertical_swipe_threshold_px)
	if absf(_drag_accum_y) < threshold:
		return false

	var to_up := _drag_accum_y < 0.0
	_start_vertical_face_preview(to_up)
	get_viewport().set_input_as_handled()
	return true


func _start_vertical_face_preview(to_up_face: bool) -> void:
	_vertical_preview_phase = 1
	_vertical_preview_saved_rotation = model_root.rotation
	_vertical_preview_return_at_ms = Time.get_ticks_msec() + int(vertical_face_hold_sec * 1000.0)
	_rotation_input_block_until_ms = _vertical_preview_return_at_ms
	_drag_accum_x = 0.0
	_drag_accum_y = 0.0
	_hold_rotate_elapsed = 0.0

	var target_x := deg_to_rad(up_face_x_deg if to_up_face else down_face_x_deg)
	_play_model_x_tween(target_x, vertical_face_anim_sec)
	_sync_right_scene_with_vertical_face(to_up_face)


func _update_vertical_preview_state() -> void:
	if _vertical_preview_phase != 1:
		return
	if Time.get_ticks_msec() < _vertical_preview_return_at_ms:
		return

	_vertical_preview_phase = 2
	_play_model_x_tween(_vertical_preview_saved_rotation.x, vertical_face_anim_sec, Callable(self, "_on_vertical_preview_return_finished"))


func _on_vertical_preview_return_finished() -> void:
	_vertical_preview_phase = 0
	if sync_right_scene_on_rotate:
		_sync_right_scene_with_rotation()
	else:
		_draw_default_line_art()


func _play_model_x_tween(target_x: float, duration: float, finished_callback: Callable = Callable()) -> void:
	if is_instance_valid(_model_x_tween):
		_model_x_tween.kill()

	_model_x_tween = create_tween()
	_model_x_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_model_x_tween.tween_property(model_root, "rotation:x", target_x, duration)
	if finished_callback.is_valid():
		_model_x_tween.finished.connect(finished_callback, CONNECT_ONE_SHOT)


func _sync_right_scene_with_vertical_face(is_up_face: bool) -> void:
	_switch_right_scene(0 if is_up_face else 2, false)


func _validate_input_actions() -> void:
	_ensure_input_action("rotate_sphere_left", [KEY_A, KEY_LEFT])
	_ensure_input_action("rotate_sphere_right", [KEY_D, KEY_RIGHT])


func _ensure_input_action(action_name: StringName, keycodes: Array[Key]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var events := InputMap.action_get_events(action_name)
	if events.is_empty():
		for keycode in keycodes:
			var ev := InputEventKey.new()
			ev.keycode = keycode
			InputMap.action_add_event(action_name, ev)


func _on_chapter_1_split_dragged(_offset: int) -> void:
	if _split_programmatic_motion:
		return
	_enforce_chapter_1_constraints()


func _enforce_chapter_1_constraints() -> void:
	if _intro_sequence_running:
		right_panel.custom_minimum_size.x = maxf(1.0, size.x * 0.5)
		if chapter_1_split.split_offset > 0:
			chapter_1_split.split_offset = 0
		return

	if lock_split_dragging:
		right_panel.custom_minimum_size.x = maxf(1.0, size.x * (1.0 - locked_left_panel_width_ratio))
		var target := _get_locked_split_offset()
		if chapter_1_split.split_offset != target:
			chapter_1_split.split_offset = target
	else:
		# Fallback: keep right side at least 50% of total width.
		var min_right_width := maxf(1.0, size.x * 0.5)
		right_panel.custom_minimum_size.x = min_right_width
		if chapter_1_split.split_offset > 0:
			chapter_1_split.split_offset = 0


func _get_locked_split_offset() -> int:
	return -int(maxf(0.0, size.x * clampf(locked_left_panel_width_ratio, 0.1, 0.9)))


func _setup_fixed_right_canvas() -> void:
	if line_canvas == null or not is_instance_valid(line_canvas):
		return

	# Fix right 2D image size so dragging splitter reveals/clips it rather than scaling.
	if _right_art_base_size == Vector2.ZERO and line_canvas.size.x > 1.0 and line_canvas.size.y > 1.0:
		_right_art_base_size = line_canvas.size
	if _right_art_base_size == Vector2.ZERO:
		return

	line_canvas.set_anchors_preset(Control.PRESET_TOP_LEFT)
	line_canvas.position = Vector2.ZERO
	line_canvas.size = _right_art_base_size


func _ensure_chapter_hint_label() -> void:
	if _chapter_hint_label != null:
		return
	_chapter_hint_label = Label.new()
	_chapter_hint_label.name = "ChapterFlowHint"
	_chapter_hint_label.text = ""
	_chapter_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_chapter_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_chapter_hint_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_chapter_hint_label.offset_left = 0.0
	_chapter_hint_label.offset_right = 0.0
	_chapter_hint_label.offset_top = -40.0
	_chapter_hint_label.offset_bottom = -10.0
	_chapter_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chapter_hint_label.visible = false
	add_child(_chapter_hint_label)


func _ensure_continue_button() -> void:
	if _continue_button != null:
		return
	_continue_button = Button.new()
	_continue_button.name = "ContinueButton"
	_continue_button.text = "Continue"
	_continue_button.custom_minimum_size = Vector2(180.0, 56.0)
	_continue_button.visible = false
	_continue_button.focus_mode = Control.FOCUS_NONE
	_continue_button.set_anchors_preset(Control.PRESET_CENTER)
	_continue_button.anchor_left = 0.5
	_continue_button.anchor_top = 0.5
	_continue_button.anchor_right = 0.5
	_continue_button.anchor_bottom = 0.5
	_continue_button.offset_left = -90.0
	_continue_button.offset_top = -28.0
	_continue_button.offset_right = 90.0
	_continue_button.offset_bottom = 28.0
	_continue_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_continue_button.pressed.connect(_on_continue_button_pressed)
	add_child(_continue_button)
	_continue_button.move_to_front()
