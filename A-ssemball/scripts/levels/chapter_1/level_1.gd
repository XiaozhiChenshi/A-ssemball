extends Control
class_name LevelC1L1

signal act_one_completed
signal chapter_completed(chapter_index: int)

const StructureShapeProviderRef = preload("res://scripts/structure/structure_shape_provider.gd")

const ACT_ONE_BASE_COLOR: Color = Color(0.68, 0.74, 0.82, 1.0)
const SHAPE_RADIUS: float = 1.0
const MAX_ABNORMAL_TARGETS: int = 5
const ABNORMAL_FACE_MODE := "abnormal_face"
const ABNORMAL_CONE_MODE := "abnormal_cone"
const NORMAL_STAGE_MODE := "normal"
const ABNORMAL_RESOLVE_DURATION_SEC: float = 3.0
const POST_CLEAR_NORMAL_HOLD_SEC: float = 5.0

@export var chapter_index: int = 1

@export var light_rotation_speed_deg: float = 0.0
@export var light_energy: float = 0.85
@export var sphere_rotate_speed_deg: float = 120.0
@export var polyhedron_edge_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export_range(1.0, 1.05, 0.001) var polyhedron_edge_thickness_scale: float = 1.01
@export_range(1.0, 8.0, 0.1) var polyhedron_edge_line_width: float = 2.0
@export_range(0.0, 1.0, 0.001) var goldberg_wave_displacement_ratio: float = 1.0 / 6.0
@export_range(0.0, 6.0, 0.01) var goldberg_wave_speed: float = 1.05
@export_range(0.0, 24.0, 0.1) var goldberg_wave_phase_scale: float = 8.5
@export_range(0.0, 1.0, 0.01) var goldberg_scaffold_edge_alpha: float = 0.24
@export_range(0.0, 1.0, 0.01) var goldberg_scaffold_edge_brightness: float = 0.3
@export var idle_jitter_rotation_deg: float = 0.8
@export var idle_jitter_offset: float = 0.05
@export var idle_jitter_speed_hz: float = 0.55
@export var click_shake_rotation_deg: float = 8.0
@export var click_shake_offset: float = 0.18
@export var shake_duration_base_sec: float = 0.42
@export var shake_duration_step_sec: float = 0.12
@export var auto_stage_gap_sec: float = 0.42
@export_range(0.1, 2.5, 0.01) var stage_image_crossfade_sec: float = 0.9
@export_range(0.05, 2.0, 0.01) var right_panel_filter_settle_speed: float = 0.9
@export_range(0.05, 1.0, 0.01) var right_panel_filter_burst_decay_speed: float = 0.28
@export_range(0.2, 2.0, 0.01) var click_feedback_duration_sec: float = 1.0
@export_range(0.05, 2.0, 0.01) var click_confirm_shake_duration_sec: float = 0.8
@export var click_confirm_shake_rotation_deg: float = 5.0
@export var click_confirm_shake_offset: float = 0.085
@export_range(0.0, 1.0, 0.01) var click_feedback_burst_strength: float = 0.95
@export_range(0.05, 10.0, 0.01) var clear_charge_start_frequency_hz: float = 0.28
@export_range(0.1, 14.0, 0.01) var clear_charge_peak_frequency_hz: float = 5.6
@export var clear_charge_rotation_deg: float = 5.2
@export var clear_charge_offset: float = 0.085
@export_range(0.1, 6.0, 0.01) var transition_aftershock_duration_sec: float = 2.6
@export_range(0.1, 18.0, 0.01) var transition_aftershock_start_frequency_hz: float = 7.2
@export_range(0.1, 8.0, 0.01) var transition_aftershock_end_frequency_hz: float = 0.9
@export var transition_aftershock_rotation_deg: float = 4.2
@export var transition_aftershock_offset: float = 0.07

@onready var chapter_1_split: HSplitContainer = $Chapter1Split
@onready var left_3d: SubViewportContainer = $Chapter1Split/Left3D
@onready var left_viewport: SubViewport = $Chapter1Split/Left3D/LeftViewport
@onready var camera_3d: Camera3D = $Chapter1Split/Left3D/LeftViewport/World3D/Camera3D
@onready var model_root: Node3D = $Chapter1Split/Left3D/LeftViewport/World3D/ModelRoot
@onready var sphere: MeshInstance3D = $Chapter1Split/Left3D/LeftViewport/World3D/ModelRoot/Dodecahedron
@onready var marker: MeshInstance3D = $Chapter1Split/Left3D/LeftViewport/World3D/ModelRoot/Dodecahedron/Marker
@onready var right_panel: ColorRect = $Chapter1Split/RightPanel
@onready var line_canvas: LineCanvas2D = $Chapter1Split/RightPanel/LineCanvas
@onready var dir_light: DirectionalLight3D = $Chapter1Split/Left3D/LeftViewport/World3D/DirectionalLight3D

var _stage_data: Array[Dictionary] = []
var _current_stage_index: int = 0
var _completed_stage_advances: int = 0
var _transition_locked: bool = false
var _act_one_completed: bool = false

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _shape_provider
var _sphere_material: ShaderMaterial
var _polyhedron_edge_material: StandardMaterial3D
var _cone_edge_material: ShaderMaterial
var _scaffold_edge_material: StandardMaterial3D
var _edge_overlay_instance: MeshInstance3D
var _static_edge_overlay_instance: MeshInstance3D
var _current_shape_data
var _current_cells_by_id: Dictionary = {}
var _current_stage_mode: String = NORMAL_STAGE_MODE
var _current_stage_abnormal_target_count: int = 0
var _current_stage_abnormal_ids: Array[int] = []
var _remaining_abnormal_ids: Array[int] = []
var _normalizing_abnormal_ids: Array[int] = []
var _abnormal_intensities: Dictionary = {}
var _stage_interaction_revision: int = 0
var _has_seen_abnormal_face: bool = false
var _has_seen_abnormal_cone: bool = false
var _stage_clear_sequence_running: bool = false

var _idle_time: float = 0.0
var _shake_time_left: float = 0.0
var _shake_total_duration: float = 0.0
var _shake_strength_rot: float = 0.0
var _shake_strength_pos: float = 0.0
var _sphere_pulse: float = 0.0

var _noise_floor_strength: float = 1.0
var _noise_burst_strength: float = 0.0
var _noise_display_strength: float = 1.0
var _click_feedback_axis: Vector3 = Vector3.UP
var _click_feedback_time_left: float = 0.0
var _click_feedback_total_duration: float = 0.0
var _click_feedback_progress: float = 1.0
var _click_feedback_strength: float = 0.0
var _stage_clear_charge_active: bool = false
var _stage_clear_charge_elapsed: float = 0.0
var _stage_clear_charge_duration: float = 0.0
var _stage_clear_charge_strength: float = 0.0
var _transition_aftershock_time_left: float = 0.0
var _transition_aftershock_total_duration: float = 0.0
var _transition_aftershock_strength: float = 0.0
var _stage_texture_cache: Dictionary = {}

var _panel_root: Control
var _stage_title_label: Label
var _stage_desc_label: Label
var _stage_image_frame: AspectRatioContainer
var _stage_image_prev_rect: TextureRect
var _stage_image_rect: TextureRect
var _stage_image_missing_label: Label
var _stage_image_crossfade_tween: Tween
var _stage_image_filter_materials: Array[ShaderMaterial] = []
var _stage_image_transition_progress: float = 1.0
var _stage_image_transition_strength: float = 0.0
var _stage_image_transition_prev_alpha_start: float = 0.0
var _stage_image_transition_next_alpha_target: float = 1.0
var _shape_label: Label
var _progress_label: Label
var _hint_label: Label
var _status_label: Label
var _noise_overlay: ColorRect
var _noise_material: ShaderMaterial
var _flash_overlay: ColorRect


func _ready() -> void:
	_rng.randomize()
	_shape_provider = StructureShapeProviderRef.new()
	_stage_data = _build_stage_data()
	line_canvas.visible = false
	marker.visible = false
	dir_light.light_energy = light_energy

	_setup_sphere_material()
	_ensure_edge_overlay_instance()
	_setup_right_panel_ui()
	_ensure_flash_overlay()

	_apply_stage(_current_stage_index)
	_update_hint_and_progress_text()

	resized.connect(_on_layout_changed)
	chapter_1_split.dragged.connect(_on_chapter_1_split_dragged)
	_on_layout_changed()
	call_deferred("_prime_structure_cache")


func _process(delta: float) -> void:
	_update_feedback_state(delta)
	_update_sphere_wasd_rotate(delta)
	_update_model_idle_and_shake(delta)
	_update_right_panel_effect(delta)
	_apply_edge_outline_style()
	if light_rotation_speed_deg != 0.0:
		dir_light.rotate_y(deg_to_rad(light_rotation_speed_deg) * delta)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not _is_click_on_sphere(event.position):
			return

		get_viewport().set_input_as_handled()
		if _transition_locked:
			_set_status_text("Structure is still settling.")
			return
		if _act_one_completed:
			_set_status_text("Act 1 complete. Waiting at the Act 2 entry shape.")
			return
		await _handle_stage_click(event.position)


func _build_stage_data() -> Array[Dictionary]:
	return [
		{
			"image_title": "Stone Tools",
			"image_desc": "Archaeological stone implements",
			"image_path": "res://assets/ui/chapter_1_stages/polished_stone_implements.png",
			"shape_label": "Dodecahedron",
			"shape_id": "dodecahedron",
			"interaction_mode": ABNORMAL_FACE_MODE,
			"abnormal_count": 2,
			"noise_floor": 0.95,
			"sphere_color": ACT_ONE_BASE_COLOR,
			"show_edges": true,
		},
		{
			"image_title": "Wheel",
			"image_desc": "Weathered wooden wheel",
			"image_path": "res://assets/ui/chapter_1_stages/wooden_wheel.png",
			"shape_label": "Icosahedron",
			"shape_id": "icosahedron",
			"interaction_mode": ABNORMAL_FACE_MODE,
			"abnormal_count": 3,
			"noise_floor": 0.82,
			"sphere_color": ACT_ONE_BASE_COLOR,
			"show_edges": true,
		},
		{
			"image_title": "Watermill / Windmill",
			"image_desc": "Waterwheel",
			"image_path": "res://assets/ui/chapter_1_stages/waterwheel.png",
			"shape_label": "G(2,1)",
			"shape_id": "goldberg:2:1",
			"interaction_mode": ABNORMAL_CONE_MODE,
			"abnormal_count": 3,
			"noise_floor": 0.68,
			"sphere_color": ACT_ONE_BASE_COLOR,
			"show_edges": true,
		},
		{
			"image_title": "Pendulum Clock",
			"image_desc": "Pendulum clock",
			"image_path": "res://assets/ui/chapter_1_stages/clock.png",
			"shape_label": "G(3,0)",
			"shape_id": "goldberg:3:0",
			"interaction_mode": ABNORMAL_CONE_MODE,
			"abnormal_count": 4,
			"noise_floor": 0.55,
			"sphere_color": ACT_ONE_BASE_COLOR,
			"show_edges": true,
		},
		{
			"image_title": "Steam Engine",
			"image_desc": "Steam engine",
			"image_path": "res://assets/ui/chapter_1_stages/steam_engine.png",
			"shape_label": "G(3,3)",
			"shape_id": "goldberg:3:3",
			"interaction_mode": ABNORMAL_CONE_MODE,
			"abnormal_count": 5,
			"noise_floor": 0.40,
			"sphere_color": ACT_ONE_BASE_COLOR,
			"show_edges": true,
		},
		{
			"image_title": "Combustion Engine",
			"image_desc": "Internal combustion engine",
			"image_path": "res://assets/ui/chapter_1_stages/internal_combustion_engine.png",
			"shape_label": "G(4,4)",
			"shape_id": "goldberg:4:4",
			"interaction_mode": ABNORMAL_CONE_MODE,
			"abnormal_count": 5,
			"noise_floor": 0.28,
			"sphere_color": ACT_ONE_BASE_COLOR,
			"show_edges": true,
		},
		{
			"image_title": "Integrated Circuit",
			"image_desc": "Integrated circuit",
			"image_path": "res://assets/ui/chapter_1_stages/integrated_circuit.png",
			"shape_label": "G(8,8)",
			"shape_id": "goldberg:8:8",
			"interaction_mode": ABNORMAL_CONE_MODE,
			"abnormal_count": 5,
			"noise_floor": 0.16,
			"sphere_color": ACT_ONE_BASE_COLOR,
			"show_edges": true,
		},
	]


func _setup_sphere_material() -> void:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode depth_draw_opaque, cull_disabled;

uniform vec4 base_color : source_color = vec4(0.82, 0.87, 0.96, 1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.4;
uniform float specular_strength : hint_range(0.0, 1.0) = 0.18;
uniform float emission_strength : hint_range(0.0, 1.0) = 0.08;
uniform float pulse_strength : hint_range(0.0, 1.0) = 0.0;
uniform float rim_strength : hint_range(0.0, 1.0) = 0.16;
uniform float rim_power : hint_range(0.5, 8.0) = 2.8;
uniform float wave_enabled : hint_range(0.0, 1.0) = 0.0;
uniform float wave_displacement : hint_range(0.0, 1.0) = 0.16666667;
uniform float wave_speed : hint_range(0.0, 6.0) = 1.05;
uniform float wave_phase_scale : hint_range(0.0, 24.0) = 8.5;
uniform float abnormal_mode : hint_range(0.0, 2.0) = 0.0;
uniform vec4 abnormal_cell_ids_a = vec4(-1.0, -1.0, -1.0, -1.0);
uniform vec4 abnormal_cell_intensities_a = vec4(0.0, 0.0, 0.0, 0.0);
uniform vec4 abnormal_cell_ids_b = vec4(-1.0, -1.0, -1.0, -1.0);
uniform vec4 abnormal_cell_intensities_b = vec4(0.0, 0.0, 0.0, 0.0);
uniform float abnormal_flash_strength : hint_range(0.0, 4.0) = 0.0;
uniform float abnormal_motion_strength : hint_range(0.0, 1.0) = 0.0;
uniform float abnormal_shake_strength : hint_range(0.0, 0.25) = 0.0;
uniform float hit_strength : hint_range(0.0, 1.0) = 0.0;
uniform float hit_progress : hint_range(0.0, 1.0) = 1.0;
uniform vec3 hit_axis = vec3(0.0, 1.0, 0.0);

float outward_only_wave(float phase) {
	return max(0.0, sin(phase));
}

float cell_seed(float cell_id) {
	return fract(sin(cell_id * 12.9898) * 43758.5453123);
}

float abnormal_slot_weight(float target_id, float cell_id, float intensity) {
	return abs(cell_id - target_id) < 0.25 ? intensity : 0.0;
}

float abnormal_weight(float cell_id) {
	return abnormal_slot_weight(abnormal_cell_ids_a.x, cell_id, abnormal_cell_intensities_a.x)
		+ abnormal_slot_weight(abnormal_cell_ids_a.y, cell_id, abnormal_cell_intensities_a.y)
		+ abnormal_slot_weight(abnormal_cell_ids_a.z, cell_id, abnormal_cell_intensities_a.z)
		+ abnormal_slot_weight(abnormal_cell_ids_a.w, cell_id, abnormal_cell_intensities_a.w)
		+ abnormal_slot_weight(abnormal_cell_ids_b.x, cell_id, abnormal_cell_intensities_b.x)
		+ abnormal_slot_weight(abnormal_cell_ids_b.y, cell_id, abnormal_cell_intensities_b.y)
		+ abnormal_slot_weight(abnormal_cell_ids_b.z, cell_id, abnormal_cell_intensities_b.z)
		+ abnormal_slot_weight(abnormal_cell_ids_b.w, cell_id, abnormal_cell_intensities_b.w);
}

float abnormal_flicker(float time_value, float seed) {
	float fast = sin(time_value * (12.0 + seed * 6.0) + seed * 19.0);
	float mid = sin(time_value * (23.0 + seed * 5.0) + seed * 37.0);
	float burst = sin(time_value * (41.0 + seed * 9.0) + seed * 53.0);
	return clamp(abs(fast) * 0.45 + abs(mid) * 0.35 + max(0.0, burst) * 0.6, 0.0, 1.0);
}

vec3 stable_perpendicular(vec3 axis) {
	vec3 reference = abs(axis.y) > 0.92 ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 1.0, 0.0);
	return normalize(cross(axis, reference));
}

vec3 safe_normalize(vec3 value) {
	float len = length(value);
	return len > 0.0001 ? value / len : vec3(0.0, 1.0, 0.0);
}

float hit_wave(vec3 axis) {
	float strength = clamp(hit_strength, 0.0, 1.0);
	if (strength <= 0.0001) {
		return 0.0;
	}

	float distance = clamp((1.0 - dot(safe_normalize(axis), safe_normalize(hit_axis))) * 0.5, 0.0, 1.0);
	float front = clamp(hit_progress, 0.0, 1.0);
	float ring_width = 0.05 + front * 0.1;
	float core = 1.0 - smoothstep(0.04, 0.14 + front * 0.22, distance);
	float ring = 1.0 - smoothstep(ring_width, ring_width + 0.08, abs(distance - front));
	float fill = 1.0 - smoothstep(front + 0.05, front + 0.2, distance);
	return max(core, max(ring, fill * 0.72)) * strength;
}

void vertex() {
	float wave_value = outward_only_wave(TIME * wave_speed - UV.x * wave_phase_scale);
	float displacement = wave_enabled * wave_displacement * wave_value;
	vec3 wave_axis = COLOR.rgb * 2.0 - vec3(1.0);
	float axis_len = length(wave_axis);
	if (axis_len > 0.0001) {
		wave_axis /= axis_len;
		VERTEX += wave_axis * displacement;
	}

	float cell_id = UV2.x;
	float abnormal = abnormal_weight(cell_id);
	if (abnormal_mode > 1.5 && abnormal > 0.0001 && axis_len > 0.0001) {
		float seed = cell_seed(cell_id);
		float twitch = sin(TIME * (13.0 + seed * 7.0) + seed * 11.0) * 0.58;
		twitch += sin(TIME * (27.0 + seed * 5.0) + seed * 23.0) * 0.31;
		twitch += sin(TIME * (43.0 + seed * 9.0) + seed * 41.0) * 0.16;
		twitch = clamp(twitch, -1.0, 1.0);
		VERTEX += wave_axis * abnormal_motion_strength * abnormal * twitch;

		vec3 tangent = stable_perpendicular(wave_axis);
		vec3 bitangent = normalize(cross(wave_axis, tangent));
		float shake_a = sin(TIME * (19.0 + seed * 4.0) + dot(VERTEX.xyz, vec3(7.1, 4.3, 5.7)));
		float shake_b = cos(TIME * (23.0 + seed * 6.0) + dot(VERTEX.zxy, vec3(3.7, 6.1, 5.3)));
		VERTEX += (tangent * shake_a + bitangent * shake_b) * abnormal_shake_strength * abnormal;
	}

	float hit = hit_wave(axis_len > 0.0001 ? wave_axis : hit_axis);
	if (hit > 0.0001 && axis_len > 0.0001) {
		VERTEX += wave_axis * (0.03 + wave_displacement * 0.18) * hit;
	}
}

void fragment() {
	vec3 lit = clamp(base_color.rgb + vec3(pulse_strength * 0.16), vec3(0.0), vec3(1.0));
	float rim = pow(clamp(1.0 - dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), rim_power);
	float abnormal = abnormal_weight(UV2.x);
	float flash = abnormal_flicker(TIME, cell_seed(UV2.x)) * abnormal_flash_strength * abnormal;
	vec3 abnormal_glow = vec3(flash);
	vec3 axis = COLOR.rgb * 2.0 - vec3(1.0);
	float hit = hit_wave(axis);
	vec3 hit_tint = mix(vec3(1.0, 0.95, 0.84), vec3(0.84, 0.95, 1.0), clamp(hit_progress, 0.0, 1.0));
	vec3 hit_glow = hit_tint * hit;
	ALBEDO = clamp(lit + hit_glow * 0.08, vec3(0.0), vec3(1.0));
	ROUGHNESS = roughness;
	SPECULAR = specular_strength;
	EMISSION = lit * (emission_strength + pulse_strength * 0.3) + vec3(rim * rim_strength) + abnormal_glow + hit_glow * (1.05 + pulse_strength * 0.45);
}
"""
	_sphere_material = ShaderMaterial.new()
	_sphere_material.shader = shader
	sphere.material_override = _sphere_material
	_update_goldberg_wave_shader_state()


func _setup_right_panel_ui() -> void:
	right_panel.color = Color(0.02, 0.02, 0.03, 1.0)
	right_panel.clip_contents = true

	for child in right_panel.get_children():
		if child == line_canvas:
			continue
		child.queue_free()

	_stage_image_filter_materials.clear()
	_stage_image_crossfade_tween = null
	_stage_image_transition_progress = 1.0
	_stage_image_transition_strength = 0.0
	_stage_image_transition_prev_alpha_start = 0.0
	_stage_image_transition_next_alpha_target = 1.0
	_panel_root = Control.new()
	_panel_root.name = "PanelRoot"
	_panel_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right_panel.add_child(_panel_root)

	var backdrop := ColorRect.new()
	backdrop.name = "StageBackdrop"
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.color = Color(0.01, 0.01, 0.015, 1.0)
	_panel_root.add_child(backdrop)

	var image_shader := Shader.new()
	image_shader.code = """
shader_type canvas_item;
render_mode unshaded;

uniform float effect_strength : hint_range(0.0, 1.0) = 1.0;
uniform float abnormal_strength : hint_range(0.0, 1.0) = 0.0;
uniform float click_strength : hint_range(0.0, 1.0) = 0.0;
uniform float charge_strength : hint_range(0.0, 1.0) = 0.0;
uniform float aftershock_strength : hint_range(0.0, 1.0) = 0.0;
uniform float burst_strength : hint_range(0.0, 1.0) = 0.0;
uniform float image_transition_strength : hint_range(0.0, 1.0) = 0.0;
uniform float image_transition_progress : hint_range(0.0, 1.0) = 1.0;
uniform float transition_direction : hint_range(-1.0, 1.0) = 1.0;

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
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

vec3 apply_sepia(vec3 color) {
	return vec3(
		dot(color, vec3(0.393, 0.769, 0.189)),
		dot(color, vec3(0.349, 0.686, 0.168)),
		dot(color, vec3(0.272, 0.534, 0.131))
	);
}

void fragment() {
	float strength = clamp(effect_strength, 0.0, 1.0);
	float abnormal = clamp(abnormal_strength, 0.0, 1.0);
	float click_pulse = clamp(click_strength, 0.0, 1.0);
	float charge = clamp(charge_strength, 0.0, 1.0);
	float aftershock = clamp(aftershock_strength, 0.0, 1.0);
	float peak = clamp(burst_strength, 0.0, 1.0);
	float image_transition = clamp(image_transition_strength, 0.0, 1.0);
	float transition_phase = clamp(image_transition_progress, 0.0, 1.0);
	float transition = max(charge, aftershock);
	float t = TIME;
	vec2 uv = UV;
	vec2 centered = uv * 2.0 - 1.0;
	float radius2 = dot(centered, centered);

	float charge_freq = mix(0.8, 12.0, pow(charge, 1.45));
	float aftershock_freq = mix(12.0, 1.1, 1.0 - aftershock);
	float global_flash = (sin(t * (1.1 + charge_freq)) * 0.5 + 0.5) * charge;
	global_flash += (sin(t * (1.8 + aftershock_freq) + UV.y * 18.0) * 0.5 + 0.5) * aftershock * 0.72;
	global_flash = clamp(global_flash, 0.0, 1.0);

	float transition_wave = sin(transition_phase * 3.14159);
	float barrel = 0.015 + 0.05 * strength + 0.08 * abnormal + 0.05 * click_pulse + 0.06 * charge + 0.05 * aftershock + 0.11 * peak + 0.14 * image_transition;
	centered *= 1.0 + radius2 * barrel;
	uv = centered * 0.5 + 0.5;

	float wave = sin((UV.y * 18.0 + t * 3.4) * 1.3) * cos((UV.x * 11.0 - t * 1.7) * 1.1);
	float drift = 0.004 + 0.012 * strength + 0.024 * abnormal + 0.018 * click_pulse + 0.016 * transition + 0.026 * peak + 0.04 * image_transition;
	uv.x += wave * drift;
	uv.y += sin(UV.x * 15.0 + t * 2.6) * (0.001 + 0.005 * strength + 0.016 * abnormal + 0.012 * transition + 0.024 * image_transition);

	vec2 smear_axis = normalize(vec2(max(0.0001, abs(transition_direction)) * sign(transition_direction), 0.28 + 0.22 * sin(t * 1.2 + transition_phase * 4.4)));
	float smear_noise = noise(UV * vec2(36.0, 22.0) + vec2(t * 1.7, -t * 1.1));
	float smear_gate = smoothstep(0.18, 0.92, transition_wave);
	uv += smear_axis * (smear_noise - 0.5) * image_transition * smear_gate * (0.12 + 0.08 * transition_wave);

	float band_noise = noise(vec2(floor(UV.y * 140.0), floor(t * 9.0 + UV.x * 4.0)));
	float band_gate = smoothstep(0.52, 1.0, band_noise + abnormal * 0.18 + click_pulse * 0.16 + transition * 0.12 + peak * 0.22 + image_transition * 0.24);
	uv.x += (band_noise - 0.5) * band_gate * (0.018 * strength + 0.055 * abnormal + 0.035 * click_pulse + 0.03 * transition + 0.05 * peak + 0.065 * image_transition);

	vec2 sample_uv = clamp(uv, vec2(0.0), vec2(1.0));
	vec2 chroma = vec2((0.002 + 0.006 * strength + 0.012 * click_pulse + 0.008 * transition + 0.012 * peak + 0.022 * image_transition) * (1.0 - abs(UV.y - 0.5) * 0.7), 0.0);
	vec3 color = vec3(
		texture(TEXTURE, clamp(sample_uv + chroma, vec2(0.0), vec2(1.0))).r,
		texture(TEXTURE, sample_uv).g,
		texture(TEXTURE, clamp(sample_uv - chroma, vec2(0.0), vec2(1.0))).b
	);

	float luma = dot(color, vec3(0.299, 0.587, 0.114));
	vec3 gray = vec3(luma);
	vec3 sepia = apply_sepia(gray);
	color = mix(color, gray, 0.08 + strength * 0.14 + abnormal * 0.18 + transition * 0.06 + image_transition * 0.22);
	color = mix(color, sepia, 0.08 + strength * 0.12 + abnormal * 0.16 + peak * 0.08);

	vec3 top_tint = vec3(1.02, 0.94, 0.82);
	vec3 bottom_tint = vec3(0.62, 0.72, 0.96);
	vec3 gradient_tint = mix(bottom_tint, top_tint, smoothstep(-0.1, 1.0, UV.y + sin(t * (0.23 + charge * 0.9 + aftershock * 1.2)) * (0.08 + transition * 0.05)));
	color *= mix(vec3(1.0), gradient_tint, 0.06 + strength * 0.12 + abnormal * 0.18 + click_pulse * 0.06 + transition * 0.08 + peak * 0.12 + image_transition * 0.18);

	float coarse = noise(UV * vec2(170.0, 96.0) + vec2(t * 3.1, -t * 1.6));
	float medium = noise(UV * vec2(420.0, 236.0) + vec2(-t * 5.4, t * 3.7));
	float fine = hash((UV + vec2(t * 0.021, -t * 0.017)) * vec2(1280.0, 960.0));
	float grain = (coarse - 0.5) * 0.18 + (medium - 0.5) * 0.12 + (fine - 0.5) * 0.08;
	color += grain * (0.1 + strength * 0.22 + abnormal * 0.42 + click_pulse * 0.22 + transition * 0.18 + peak * 0.35 + image_transition * 0.42);

	float vertical_bloom = smoothstep(0.15, 0.85, sin(UV.y * (9.0 + charge * 14.0 + aftershock * 18.0) - t * (1.4 + charge * 3.0 + aftershock * 3.8)) * 0.5 + 0.5);
	float click_flash = smoothstep(0.08, 1.0, sin(t * 38.0) * 0.5 + 0.5) * click_pulse;
	color += vec3(vertical_bloom) * (abnormal * 0.04 + transition * 0.06 + peak * 0.08);
	color += vec3(0.16, 0.13, 0.1) * click_flash * 0.8;
	color += vec3(global_flash) * 0.08;
	color = mix(color, vec3(dot(color, vec3(0.299, 0.587, 0.114))), image_transition * (0.14 + transition_wave * 0.12));
	color += vec3(smear_noise - 0.5) * image_transition * (0.08 + transition_wave * 0.08);

	float contrast = 1.0 + strength * 0.08 + abnormal * 0.12 + click_pulse * 0.1 + transition * 0.1 + peak * 0.12;
	color = (color - 0.5) * contrast + 0.5;
	color *= 1.02 - strength * 0.03 - abnormal * 0.06 + click_pulse * 0.06 + global_flash * 0.05 + peak * 0.04 + image_transition * (0.06 + transition_wave * 0.04);

	float vignette = smoothstep(1.35, 0.18, length(centered));
	color *= mix(1.0, vignette, 0.08 + strength * 0.18 + abnormal * 0.22 + transition * 0.08);

	COLOR = vec4(clamp(color, vec3(0.0), vec3(1.0)), texture(TEXTURE, sample_uv).a);
}
"""

	_stage_image_prev_rect = _create_stage_image_rect("StageImagePrevious", image_shader, -1.0)
	_stage_image_prev_rect.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_panel_root.add_child(_stage_image_prev_rect)

	_stage_image_rect = _create_stage_image_rect("StageImageCurrent", image_shader, 1.0)
	_stage_image_rect.modulate = Color(1.0, 1.0, 1.0, 1.0)
	_panel_root.add_child(_stage_image_rect)

	_noise_overlay = ColorRect.new()
	_noise_overlay.name = "NoiseOverlay"
	_noise_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_noise_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_noise_overlay.color = Color(1.0, 1.0, 1.0, 1.0)
	_panel_root.add_child(_noise_overlay)

	var overlay_shader := Shader.new()
	overlay_shader.code = """
shader_type canvas_item;
render_mode unshaded;

uniform float effect_strength : hint_range(0.0, 1.0) = 1.0;
uniform float abnormal_strength : hint_range(0.0, 1.0) = 0.0;
uniform float click_strength : hint_range(0.0, 1.0) = 0.0;
uniform float charge_strength : hint_range(0.0, 1.0) = 0.0;
uniform float aftershock_strength : hint_range(0.0, 1.0) = 0.0;
uniform float burst_strength : hint_range(0.0, 1.0) = 0.0;
uniform float image_transition_strength : hint_range(0.0, 1.0) = 0.0;
uniform float image_transition_progress : hint_range(0.0, 1.0) = 1.0;

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
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void fragment() {
	float strength = clamp(effect_strength, 0.0, 1.0);
	float abnormal = clamp(abnormal_strength, 0.0, 1.0);
	float click_pulse = clamp(click_strength, 0.0, 1.0);
	float charge = clamp(charge_strength, 0.0, 1.0);
	float aftershock = clamp(aftershock_strength, 0.0, 1.0);
	float peak = clamp(burst_strength, 0.0, 1.0);
	float image_transition = clamp(image_transition_strength, 0.0, 1.0);
	float transition_phase = clamp(image_transition_progress, 0.0, 1.0);
	float t = TIME;
	vec2 uv = UV;
	float charge_scan = sin((uv.y * mix(4.0, 26.0, charge) - t * mix(0.6, 8.0, charge)) * 3.14159) * 0.5 + 0.5;
	float aftershock_scan = sin((uv.y * mix(22.0, 6.0, 1.0 - aftershock) + t * mix(9.5, 1.2, 1.0 - aftershock)) * 3.14159) * 0.5 + 0.5;
	float transition_scan = sin((uv.x * mix(2.8, 17.0, image_transition) + uv.y * 4.2 - t * mix(0.5, 5.2, image_transition)) * 3.14159 + transition_phase * 5.0) * 0.5 + 0.5;

	float coarse = noise(uv * vec2(120.0, 84.0) + vec2(t * 2.6, -t * 1.8));
	float fine = hash((uv + vec2(t * 0.013, -t * 0.019)) * vec2(1800.0, 1200.0));
	float scratch = smoothstep(0.994, 1.0, hash(vec2(floor(uv.x * 52.0) + floor(t * 2.4), floor(uv.y * 5.0))));
	float scan = sin((uv.y + t * 0.014) * (980.0 + peak * 240.0)) * 0.5 + 0.5;
	float pulse_band = smoothstep(0.22, 0.78, sin((uv.y * 5.0 - t * 0.6) * 3.14159) * 0.5 + 0.5);

	float alpha = abs(coarse - 0.5) * 0.2 + abs(fine - 0.5) * 0.12 + scan * (0.05 + abnormal * 0.08 + click_pulse * 0.08);
	alpha += scratch * (0.22 + peak * 0.28);
	alpha += scratch * abnormal * 0.26;
	alpha += pulse_band * peak * 0.18;
	alpha += charge_scan * charge * 0.26;
	alpha += aftershock_scan * aftershock * 0.22;
	alpha += click_pulse * 0.16;
	alpha += transition_scan * image_transition * 0.24;
	alpha *= 0.06 + strength * 0.16 + abnormal * 0.36 + click_pulse * 0.2 + charge * 0.18 + aftershock * 0.16 + image_transition * 0.22;

	vec3 warm = vec3(1.0, 0.94, 0.84);
	vec3 cool = vec3(0.74, 0.82, 1.0);
	vec3 tint = mix(cool, warm, smoothstep(0.0, 1.0, uv.y + sin(t * (0.18 + charge * 0.7 + aftershock * 1.0)) * (0.03 + abnormal * 0.02 + charge * 0.04)));
	tint = mix(tint, vec3(1.0, 0.96, 0.88), click_pulse * 0.32);
	tint = mix(tint, vec3(0.92, 0.95, 1.0), image_transition * 0.22);
	COLOR = vec4(tint, clamp(alpha, 0.0, 0.72));
}
"""
	_noise_material = ShaderMaterial.new()
	_noise_material.shader = overlay_shader
	_noise_overlay.material = _noise_material

	_stage_title_label = null
	_stage_desc_label = null
	_shape_label = null
	_progress_label = null
	_hint_label = null
	_status_label = null
	_stage_image_missing_label = null
	_stage_image_frame = null


func _create_stage_image_rect(node_name: String, shader: Shader, transition_direction: float) -> TextureRect:
	var rect := TextureRect.new()
	rect.name = node_name
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.visible = false

	var image_filter_material := ShaderMaterial.new()
	image_filter_material.shader = shader
	image_filter_material.set_shader_parameter("transition_direction", transition_direction)
	rect.material = image_filter_material
	_stage_image_filter_materials.append(image_filter_material)
	return rect


func _ensure_flash_overlay() -> void:
	_flash_overlay = ColorRect.new()
	_flash_overlay.name = "FlashOverlay"
	_flash_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_overlay.color = Color(1.0, 1.0, 1.0, 0.0)
	add_child(_flash_overlay)


func _load_stage_texture(image_path: String) -> Texture2D:
	var normalized_path := image_path.strip_edges()
	if normalized_path.is_empty():
		return null
	if _stage_texture_cache.has(normalized_path):
		return _stage_texture_cache[normalized_path] as Texture2D

	var texture := load(normalized_path) as Texture2D
	if texture == null:
		var image := Image.load_from_file(ProjectSettings.globalize_path(normalized_path))
		if image != null and not image.is_empty():
			texture = ImageTexture.create_from_image(image)

	_stage_texture_cache[normalized_path] = texture
	if texture == null:
		push_warning("Missing chapter 1 stage image: %s" % normalized_path)
	return texture


func _update_stage_image(image_path: String) -> void:
	if _stage_image_rect == null or _stage_image_prev_rect == null:
		return

	var texture := _load_stage_texture(image_path)
	if is_instance_valid(_stage_image_crossfade_tween):
		_stage_image_crossfade_tween.kill()

	var previous_texture := _stage_image_rect.texture
	var previous_alpha := _stage_image_rect.modulate.a
	var had_previous := previous_texture != null and previous_alpha > 0.001

	_stage_image_prev_rect.texture = previous_texture
	_stage_image_prev_rect.visible = had_previous
	_stage_image_prev_rect.modulate = Color(1.0, 1.0, 1.0, previous_alpha if had_previous else 0.0)

	_stage_image_rect.texture = texture
	_stage_image_rect.visible = texture != null
	_stage_image_rect.modulate = Color(1.0, 1.0, 1.0, 1.0 if texture != null and not had_previous else 0.0)

	if not had_previous:
		_stage_image_transition_prev_alpha_start = 0.0
		_stage_image_transition_next_alpha_target = 1.0 if texture != null else 0.0
		_set_stage_image_transition_progress(1.0)
		if texture == null:
			_stage_image_rect.visible = false
		_stage_image_prev_rect.visible = false
		return

	_stage_image_transition_prev_alpha_start = previous_alpha
	_stage_image_transition_next_alpha_target = 1.0 if texture != null else 0.0
	_set_stage_image_transition_progress(0.0)

	_stage_image_crossfade_tween = create_tween()
	_stage_image_crossfade_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_stage_image_crossfade_tween.tween_method(
		Callable(self, "_set_stage_image_transition_progress"),
		0.0,
		1.0,
		stage_image_crossfade_sec
	)
	await _stage_image_crossfade_tween.finished
	if _stage_image_prev_rect != null:
		_stage_image_prev_rect.visible = false
		_stage_image_prev_rect.texture = null
	_set_stage_image_transition_progress(1.0)


func _set_stage_image_transition_progress(progress: float) -> void:
	var t := clampf(progress, 0.0, 1.0)
	_stage_image_transition_progress = t
	_stage_image_transition_strength = pow(sin(t * PI), 0.72)

	if _stage_image_prev_rect != null:
		var prev_curve := 1.0 - smoothstep(0.18, 0.74, t)
		var prev_alpha := _stage_image_transition_prev_alpha_start * prev_curve
		_stage_image_prev_rect.modulate.a = prev_alpha
		_stage_image_prev_rect.visible = _stage_image_prev_rect.texture != null and prev_alpha > 0.001

	if _stage_image_rect != null:
		var next_curve := smoothstep(0.46, 0.98, t)
		var next_alpha := _stage_image_transition_next_alpha_target * next_curve
		_stage_image_rect.modulate.a = next_alpha
		_stage_image_rect.visible = _stage_image_rect.texture != null and next_alpha > 0.001


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


func _update_feedback_state(delta: float) -> void:
	if _click_feedback_time_left > 0.0:
		_click_feedback_time_left = maxf(0.0, _click_feedback_time_left - delta)
		var click_t := 1.0 - (_click_feedback_time_left / maxf(0.001, _click_feedback_total_duration))
		_click_feedback_progress = clampf(click_t, 0.0, 1.0)
		_click_feedback_strength = pow(maxf(0.0, 1.0 - click_t), 0.55)
	else:
		_click_feedback_progress = 1.0
		_click_feedback_strength = 0.0

	if _stage_clear_charge_active:
		_stage_clear_charge_elapsed = minf(_stage_clear_charge_duration, _stage_clear_charge_elapsed + delta)
		var charge_t := _stage_clear_charge_elapsed / maxf(0.001, _stage_clear_charge_duration)
		_stage_clear_charge_strength = charge_t * charge_t * (3.0 - 2.0 * charge_t)
	else:
		_stage_clear_charge_strength = 0.0

	if _transition_aftershock_time_left > 0.0:
		_transition_aftershock_time_left = maxf(0.0, _transition_aftershock_time_left - delta)
		var aftershock_t := _transition_aftershock_time_left / maxf(0.001, _transition_aftershock_total_duration)
		_transition_aftershock_strength = pow(aftershock_t, 0.82)
	else:
		_transition_aftershock_strength = 0.0

	_update_goldberg_wave_shader_state()


func _update_model_idle_and_shake(delta: float) -> void:
	_idle_time += delta
	var idle_phase := TAU * idle_jitter_speed_hz * _idle_time

	var idle_offset := Vector3(
		sin(idle_phase * 0.83) * idle_jitter_offset,
		cos(idle_phase * 1.07) * idle_jitter_offset * 0.85,
		sin(idle_phase * 0.61 + 1.4) * idle_jitter_offset * 0.45
	)
	var idle_rotation := Vector3(
		deg_to_rad(cos(idle_phase * 1.11) * idle_jitter_rotation_deg),
		deg_to_rad(sin(idle_phase * 0.69 + 0.2) * idle_jitter_rotation_deg),
		deg_to_rad(sin(idle_phase * 0.93 + 0.9) * idle_jitter_rotation_deg * 0.6)
	)

	var shake_offset := Vector3.ZERO
	var shake_rotation := Vector3.ZERO
	var charge_offset := Vector3.ZERO
	var charge_rotation := Vector3.ZERO
	if _shake_time_left > 0.0:
		_shake_time_left = maxf(0.0, _shake_time_left - delta)
		var progress := 1.0 - (_shake_time_left / maxf(0.001, _shake_total_duration))
		var falloff := maxf(0.0, 1.0 - progress)
		shake_offset = Vector3(
			_rng.randf_range(-1.0, 1.0),
			_rng.randf_range(-1.0, 1.0),
			_rng.randf_range(-0.4, 0.4)
		) * _shake_strength_pos * falloff
		shake_rotation = Vector3(
			deg_to_rad(_rng.randf_range(-1.0, 1.0) * _shake_strength_rot * falloff),
			deg_to_rad(_rng.randf_range(-1.0, 1.0) * _shake_strength_rot * falloff),
			deg_to_rad(_rng.randf_range(-1.0, 1.0) * _shake_strength_rot * 0.6 * falloff)
		)
		_sphere_pulse = maxf(_sphere_pulse, falloff)
	else:
		_sphere_pulse = move_toward(_sphere_pulse, 0.0, delta * 2.0)

	if _stage_clear_charge_strength > 0.0:
		var charge_freq := lerpf(
			clear_charge_start_frequency_hz,
			clear_charge_peak_frequency_hz,
			pow(_stage_clear_charge_strength, 1.45)
		)
		var charge_phase := TAU * charge_freq * _idle_time
		var charge_wave := sin(charge_phase) * 0.5 + 0.5
		var charge_amp := clear_charge_offset * (0.22 + pow(_stage_clear_charge_strength, 1.55) * 0.78)
		var charge_rot_amp := clear_charge_rotation_deg * (0.18 + pow(_stage_clear_charge_strength, 1.45) * 0.82)
		charge_offset += Vector3(
			sin(charge_phase * 1.1) * charge_amp,
			cos(charge_phase * 0.93 + 0.4) * charge_amp * 0.75,
			sin(charge_phase * 1.37 + 1.2) * charge_amp * 0.48
		)
		charge_rotation += Vector3(
			deg_to_rad(cos(charge_phase * 1.14) * charge_rot_amp),
			deg_to_rad(sin(charge_phase * 0.88 + 0.3) * charge_rot_amp),
			deg_to_rad(sin(charge_phase * 1.32 + 1.0) * charge_rot_amp * 0.7)
		)
		_sphere_pulse = maxf(_sphere_pulse, charge_wave * (0.22 + _stage_clear_charge_strength * 0.9))

	if _transition_aftershock_strength > 0.0:
		var recovery_t := 1.0 - _transition_aftershock_strength
		var aftershock_freq := lerpf(
			transition_aftershock_start_frequency_hz,
			transition_aftershock_end_frequency_hz,
			recovery_t
		)
		var aftershock_phase := TAU * aftershock_freq * _idle_time
		var aftershock_amp := transition_aftershock_offset * pow(_transition_aftershock_strength, 0.85)
		var aftershock_rot_amp := transition_aftershock_rotation_deg * pow(_transition_aftershock_strength, 0.82)
		charge_offset += Vector3(
			sin(aftershock_phase * 1.08 + 0.2) * aftershock_amp,
			cos(aftershock_phase * 0.97 + 0.9) * aftershock_amp * 0.7,
			sin(aftershock_phase * 1.41 + 1.6) * aftershock_amp * 0.44
		)
		charge_rotation += Vector3(
			deg_to_rad(cos(aftershock_phase * 1.09) * aftershock_rot_amp),
			deg_to_rad(sin(aftershock_phase * 0.91 + 0.5) * aftershock_rot_amp),
			deg_to_rad(sin(aftershock_phase * 1.28 + 1.1) * aftershock_rot_amp * 0.65)
		)
		_sphere_pulse = maxf(_sphere_pulse, (sin(aftershock_phase) * 0.5 + 0.5) * (0.28 + _transition_aftershock_strength * 0.72))

	model_root.position = idle_offset + shake_offset + charge_offset
	model_root.rotation = idle_rotation + shake_rotation + charge_rotation
	if _sphere_material != null:
		_sphere_material.set_shader_parameter("pulse_strength", _sphere_pulse)
	if _cone_edge_material != null:
		_cone_edge_material.set_shader_parameter("global_pulse_strength", _sphere_pulse)


func _update_right_panel_effect(delta: float) -> void:
	var abnormal_visual_strength := _get_current_abnormal_visual_strength()
	_noise_burst_strength = move_toward(_noise_burst_strength, 0.0, delta * right_panel_filter_burst_decay_speed)
	var target_strength := clampf(
		_noise_floor_strength * abnormal_visual_strength + _transition_aftershock_strength * 0.12,
		0.0,
		1.0
	)
	var response_speed := 4.2 if target_strength > _noise_display_strength else right_panel_filter_settle_speed
	var smooth_t := clampf(delta * response_speed, 0.0, 1.0)
	_noise_display_strength = lerpf(_noise_display_strength, target_strength, smooth_t)
	for filter_material in _stage_image_filter_materials:
		if filter_material == null:
			continue
		filter_material.set_shader_parameter("effect_strength", _noise_display_strength)
		filter_material.set_shader_parameter("abnormal_strength", abnormal_visual_strength)
		filter_material.set_shader_parameter("click_strength", _click_feedback_strength * click_feedback_burst_strength)
		filter_material.set_shader_parameter("charge_strength", _stage_clear_charge_strength)
		filter_material.set_shader_parameter("aftershock_strength", _transition_aftershock_strength)
		filter_material.set_shader_parameter("burst_strength", _noise_burst_strength)
		filter_material.set_shader_parameter("image_transition_strength", _stage_image_transition_strength)
		filter_material.set_shader_parameter("image_transition_progress", _stage_image_transition_progress)
	if _noise_material != null:
		_noise_material.set_shader_parameter("effect_strength", _noise_display_strength)
		_noise_material.set_shader_parameter("abnormal_strength", abnormal_visual_strength)
		_noise_material.set_shader_parameter("click_strength", _click_feedback_strength * click_feedback_burst_strength)
		_noise_material.set_shader_parameter("charge_strength", _stage_clear_charge_strength)
		_noise_material.set_shader_parameter("aftershock_strength", _transition_aftershock_strength)
		_noise_material.set_shader_parameter("burst_strength", _noise_burst_strength)
		_noise_material.set_shader_parameter("image_transition_strength", _stage_image_transition_strength)
		_noise_material.set_shader_parameter("image_transition_progress", _stage_image_transition_progress)


func _handle_stage_click(screen_pos: Vector2) -> void:
	if _current_stage_mode == NORMAL_STAGE_MODE:
		_transition_locked = true
		await _advance_to_next_stage()
		_transition_locked = false
		return

	if _remaining_abnormal_ids.is_empty() and not _normalizing_abnormal_ids.is_empty():
		_set_status_text("Abnormal structures are still stabilizing.")
		return

	var clicked_cell_id := _find_clicked_abnormal_cell(screen_pos)
	if clicked_cell_id < 0:
		if _current_stage_mode == ABNORMAL_FACE_MODE:
			_set_status_text("That face is stable. Find the flickering abnormal face.")
		else:
			_set_status_text("That cone is stable. Find every violent abnormal cone.")
		return

	if not _remaining_abnormal_ids.has(clicked_cell_id):
		_set_status_text("That abnormal structure is already stabilizing.")
		return

	_remaining_abnormal_ids.erase(clicked_cell_id)
	_trigger_click_feedback(clicked_cell_id)
	_begin_abnormal_normalization(clicked_cell_id, _stage_interaction_revision)
	if _remaining_abnormal_ids.is_empty():
		_set_status_text("Final abnormal structure stabilizing...")
	else:
		_set_status_text("Abnormal targets remaining: %d" % _remaining_abnormal_ids.size())
	_update_hint_and_progress_text()


func _advance_to_next_stage() -> void:
	if _current_stage_index >= _stage_data.size() - 1:
		await _play_final_transition_to_act_two_entry()
		return

	_completed_stage_advances += 1
	_update_hint_and_progress_text()
	await _play_transition_to_stage(_current_stage_index + 1, _completed_stage_advances)
	_update_hint_and_progress_text()


func _play_transition_to_stage(target_stage_index: int, sequence_index: int) -> void:
	var duration := shake_duration_base_sec + shake_duration_step_sec * float(maxi(0, sequence_index - 1)) + auto_stage_gap_sec
	var amplitude_mul := 1.22 + float(maxi(0, sequence_index - 1)) * 0.16
	_start_shake(duration, click_shake_rotation_deg * amplitude_mul, click_shake_offset * amplitude_mul)
	_trigger_noise_burst(1.0)
	_set_status_text("Structure vibrating: %s" % _stage_data[target_stage_index].get("shape_label", ""))

	var bump := create_tween()
	bump.tween_property(sphere, "scale", Vector3.ONE * (1.0 + 0.06 * amplitude_mul), duration * 0.24)
	bump.tween_property(sphere, "scale", Vector3.ONE, duration * 0.76)

	await get_tree().create_timer(duration * 0.55).timeout
	_stop_stage_clear_charge()
	_apply_stage(target_stage_index)
	_start_transition_aftershock(maxf(transition_aftershock_duration_sec, duration * 1.15))
	await get_tree().create_timer(duration * 0.65).timeout

	if _current_stage_mode == NORMAL_STAGE_MODE:
		_set_status_text("Structure stable. Click again to continue.")


func _play_final_transition_to_act_two_entry() -> void:
	_set_status_text("Converging into the Act 2 entry shape.")
	for i in range(3):
		var amplitude_mul := 1.35 + float(i) * 0.28
		_start_shake(0.24, click_shake_rotation_deg * amplitude_mul, click_shake_offset * amplitude_mul)
		_trigger_noise_burst(1.0)
		await get_tree().create_timer(0.24 + auto_stage_gap_sec * 0.18).timeout

	var flash := create_tween()
	flash.tween_method(Callable(self, "_set_flash_alpha"), 0.0, 0.85, 0.18)
	flash.tween_method(Callable(self, "_set_flash_alpha"), 0.85, 0.0, 0.42)

	var final_entry := {
		"image_title": "Page Turn",
		"image_desc": "Act 2 entry transition image pending",
		"image_path": "",
		"shape_label": "G(1,4)",
		"shape_id": "goldberg:1:4",
		"interaction_mode": NORMAL_STAGE_MODE,
		"abnormal_count": 0,
		"noise_floor": 0.12,
		"sphere_color": ACT_ONE_BASE_COLOR,
		"show_edges": true,
	}
	_stop_stage_clear_charge()
	_apply_stage_from_dictionary(final_entry)
	_noise_floor_strength = 0.12
	_noise_burst_strength = 0.08
	_start_transition_aftershock(transition_aftershock_duration_sec)
	_act_one_completed = true
	_set_status_text("Act 1 complete. Holding on G(1,4).")
	_update_hint_and_progress_text()
	act_one_completed.emit()
	chapter_completed.emit(chapter_index)
	await flash.finished


func _begin_abnormal_normalization(cell_id: int, interaction_revision: int) -> void:
	if _normalizing_abnormal_ids.has(cell_id):
		return

	_normalizing_abnormal_ids.append(cell_id)
	var start_value := float(_abnormal_intensities.get(cell_id, 1.0))
	var tween := create_tween()
	tween.tween_method(
		Callable(self, "_set_abnormal_cell_intensity").bind(cell_id),
		start_value,
		0.0,
		ABNORMAL_RESOLVE_DURATION_SEC
	)
	await tween.finished

	if interaction_revision != _stage_interaction_revision:
		return

	_normalizing_abnormal_ids.erase(cell_id)
	_abnormal_intensities.erase(cell_id)
	_update_goldberg_wave_shader_state()

	if not _remaining_abnormal_ids.is_empty():
		_set_status_text("Abnormal targets remaining: %d" % _remaining_abnormal_ids.size())
		return

	if not _normalizing_abnormal_ids.is_empty():
		_set_status_text("Abnormal structures are still stabilizing.")
		return

	_current_stage_abnormal_ids.clear()
	_remaining_abnormal_ids.clear()
	_abnormal_intensities.clear()
	_update_goldberg_wave_shader_state()

	if _stage_clear_sequence_running:
		return

	_stage_clear_sequence_running = true
	_transition_locked = true
	await _run_post_clear_transition_sequence(interaction_revision)
	_transition_locked = false
	_stage_clear_sequence_running = false


func _run_post_clear_transition_sequence(interaction_revision: int) -> void:
	if interaction_revision != _stage_interaction_revision:
		return

	_begin_stage_clear_charge(POST_CLEAR_NORMAL_HOLD_SEC)
	await get_tree().create_timer(POST_CLEAR_NORMAL_HOLD_SEC).timeout
	if interaction_revision != _stage_interaction_revision:
		_stop_stage_clear_charge()
		return

	_trigger_noise_burst(1.0)
	await _advance_to_next_stage()


func _trigger_click_feedback(cell_id: int) -> void:
	_click_feedback_axis = _get_cell_axis(cell_id)
	_click_feedback_total_duration = maxf(0.01, click_feedback_duration_sec)
	_click_feedback_time_left = _click_feedback_total_duration
	_click_feedback_progress = 0.0
	_click_feedback_strength = 1.0
	_start_shake(
		click_confirm_shake_duration_sec,
		click_confirm_shake_rotation_deg,
		click_confirm_shake_offset
	)
	_update_goldberg_wave_shader_state()


func _begin_stage_clear_charge(duration: float) -> void:
	_stage_clear_charge_active = true
	_stage_clear_charge_duration = maxf(0.01, duration)
	_stage_clear_charge_elapsed = 0.0
	_stage_clear_charge_strength = 0.0


func _stop_stage_clear_charge() -> void:
	_stage_clear_charge_active = false
	_stage_clear_charge_elapsed = 0.0
	_stage_clear_charge_duration = 0.0
	_stage_clear_charge_strength = 0.0


func _start_transition_aftershock(duration: float) -> void:
	_transition_aftershock_total_duration = maxf(0.01, duration)
	_transition_aftershock_time_left = _transition_aftershock_total_duration
	_transition_aftershock_strength = 1.0


func _get_cell_axis(cell_id: int) -> Vector3:
	var cell: Object = _current_cells_by_id.get(cell_id) as Object
	if cell == null:
		return Vector3.UP
	var center := cell.get("center") as Vector3
	if center.length_squared() < 0.000001:
		center = cell.get("mesh_center") as Vector3
	if center.length_squared() < 0.000001:
		return Vector3.UP
	return center.normalized()


func _set_abnormal_cell_intensity(value: float, cell_id: int) -> void:
	_abnormal_intensities[cell_id] = clampf(value, 0.0, 1.0)
	_update_goldberg_wave_shader_state()


func _get_current_abnormal_visual_strength() -> float:
	if _current_stage_mode == NORMAL_STAGE_MODE or _current_stage_abnormal_target_count <= 0:
		return 0.0

	var total_intensity := 0.0
	for cell_id in _current_stage_abnormal_ids:
		total_intensity += float(_abnormal_intensities.get(cell_id, 0.0))

	return clampf(total_intensity / float(maxi(1, _current_stage_abnormal_target_count)), 0.0, 1.0)


func _reset_stage_abnormal_state() -> void:
	_stage_interaction_revision += 1
	_current_stage_mode = NORMAL_STAGE_MODE
	_current_stage_abnormal_target_count = 0
	_current_stage_abnormal_ids.clear()
	_remaining_abnormal_ids.clear()
	_normalizing_abnormal_ids.clear()
	_abnormal_intensities.clear()
	_stage_clear_sequence_running = false
	_click_feedback_axis = Vector3.UP
	_click_feedback_time_left = 0.0
	_click_feedback_total_duration = 0.0
	_click_feedback_progress = 1.0
	_click_feedback_strength = 0.0


func _rebuild_current_cell_lookup() -> void:
	_current_cells_by_id.clear()
	if _current_shape_data == null:
		return

	var cells: Array = _current_shape_data.get("cells") as Array
	for cell_variant in cells:
		var cell: Object = cell_variant as Object
		_current_cells_by_id[int(cell.get("id"))] = cell


func _configure_stage_interaction(stage: Dictionary) -> void:
	_reset_stage_abnormal_state()
	_rebuild_current_cell_lookup()

	_current_stage_mode = String(stage.get("interaction_mode", NORMAL_STAGE_MODE))
	if _current_stage_mode == NORMAL_STAGE_MODE or _current_cells_by_id.is_empty():
		return

	var abnormal_count := clampi(int(stage.get("abnormal_count", 1)), 1, MAX_ABNORMAL_TARGETS)
	var prefer_front_facing := false
	if _current_stage_mode == ABNORMAL_FACE_MODE and not _has_seen_abnormal_face:
		prefer_front_facing = true
		_has_seen_abnormal_face = true
	elif _current_stage_mode == ABNORMAL_CONE_MODE and not _has_seen_abnormal_cone:
		prefer_front_facing = true
		_has_seen_abnormal_cone = true

	_current_stage_abnormal_ids = _select_stage_abnormal_cells(abnormal_count, prefer_front_facing)
	_remaining_abnormal_ids = _current_stage_abnormal_ids.duplicate()
	_current_stage_abnormal_target_count = _current_stage_abnormal_ids.size()
	for cell_id in _current_stage_abnormal_ids:
		_abnormal_intensities[cell_id] = 1.0

	if _current_stage_abnormal_target_count == 0:
		_current_stage_mode = NORMAL_STAGE_MODE


func _select_stage_abnormal_cells(target_count: int, prefer_front_facing: bool) -> Array[int]:
	var selected: Array[int] = []
	if _current_cells_by_id.is_empty() or target_count <= 0:
		return selected

	var available_ids: Array[int] = []
	for key in _current_cells_by_id.keys():
		available_ids.append(int(key))

	var front_candidates := _get_front_facing_cell_ids()
	if prefer_front_facing and not front_candidates.is_empty():
		selected.append(_choose_best_front_facing_cell_id(front_candidates))

	while selected.size() < target_count:
		var next_id := _choose_spread_out_cell_id(available_ids, selected)
		if next_id < 0:
			break
		selected.append(next_id)

	return selected


func _get_front_facing_cell_ids() -> Array[int]:
	var front_ids: Array[int] = []
	for key in _current_cells_by_id.keys():
		var cell_id := int(key)
		if _get_cell_front_facing_score(cell_id) > 0.12:
			front_ids.append(cell_id)
	return front_ids


func _choose_best_front_facing_cell_id(candidate_ids: Array[int]) -> int:
	var best_id := -1
	var best_score := -1.0e20
	for cell_id in candidate_ids:
		var score := _get_cell_front_facing_score(cell_id) + _rng.randf() * 0.025
		if score > best_score:
			best_score = score
			best_id = cell_id
	return best_id


func _choose_spread_out_cell_id(candidate_ids: Array[int], selected_ids: Array[int]) -> int:
	var best_id := -1
	var best_score := -1.0e20
	for cell_id in candidate_ids:
		if selected_ids.has(cell_id):
			continue

		var score := _get_cell_front_facing_score(cell_id) * 0.18 + _rng.randf() * 0.02
		if not selected_ids.is_empty():
			var min_distance := 1.0e20
			for selected_id in selected_ids:
				var cell_a := _current_cells_by_id.get(cell_id) as Object
				var cell_b := _current_cells_by_id.get(selected_id) as Object
				if cell_a == null or cell_b == null:
					continue
				var center_a := cell_a.get("center") as Vector3
				var center_b := cell_b.get("center") as Vector3
				min_distance = minf(min_distance, center_a.distance_to(center_b))
			score += min_distance
		else:
			score += _get_cell_front_facing_score(cell_id)

		if score > best_score:
			best_score = score
			best_id = cell_id

	return best_id


func _get_cell_front_facing_score(cell_id: int) -> float:
	var cell: Object = _current_cells_by_id.get(cell_id) as Object
	if cell == null:
		return -1.0

	var center_local := cell.get("center") as Vector3
	var normal_local := cell.get("normal") as Vector3
	var center_world := sphere.global_transform * center_local
	var normal_world := (sphere.global_transform.basis * normal_local).normalized()
	var to_camera := (camera_3d.global_position - center_world).normalized()
	return normal_world.dot(to_camera)


func _apply_stage(stage_index: int) -> void:
	_current_stage_index = clampi(stage_index, 0, _stage_data.size() - 1)
	_apply_stage_from_dictionary(_stage_data[_current_stage_index])
	_update_hint_and_progress_text()


func _apply_stage_from_dictionary(stage: Dictionary) -> void:
	var shape_id := String(stage.get("shape_id", "dodecahedron"))
	_current_shape_data = _shape_provider.get_shape(shape_id, SHAPE_RADIUS)
	if _current_shape_data == null:
		return

	var body_mesh: Mesh = _current_shape_data.get("body_mesh")
	var edge_mesh: Mesh = _current_shape_data.get("edge_mesh")
	var static_edge_mesh: Mesh = _current_shape_data.get("static_edge_mesh")
	sphere.mesh = body_mesh
	_update_edge_overlay_mesh(edge_mesh)
	_update_static_edge_overlay_mesh(static_edge_mesh)

	var base_color := stage.get("sphere_color", ACT_ONE_BASE_COLOR) as Color
	if _sphere_material != null:
		_sphere_material.set_shader_parameter("base_color", base_color)

	_noise_floor_strength = float(stage.get("noise_floor", 0.5))
	_configure_stage_interaction(stage)
	_update_goldberg_wave_shader_state()
	_set_polyhedron_edge_outline_enabled(bool(stage.get("show_edges", false)))
	_update_stage_image(String(stage.get("image_path", "")))

	match _current_stage_mode:
		ABNORMAL_FACE_MODE:
			_set_status_text("Find and click the single flickering abnormal face.")
		ABNORMAL_CONE_MODE:
			_set_status_text("Find and click every violent abnormal cone before the structure can evolve.")
		_:
			_set_status_text("Structure stable. Click to continue.")


func _prime_structure_cache() -> void:
	var seen: Dictionary = {}
	var shape_ids: Array[String] = []
	for stage in _stage_data:
		var shape_id := String(stage.get("shape_id", ""))
		if shape_id.is_empty() or seen.has(shape_id):
			continue
		seen[shape_id] = true
		shape_ids.append(shape_id)

	if not seen.has("goldberg:1:4"):
		shape_ids.append("goldberg:1:4")

	for shape_id in shape_ids:
		_shape_provider.get_shape(shape_id, SHAPE_RADIUS)
		await get_tree().process_frame


func _update_hint_and_progress_text() -> void:
	return


func _set_status_text(_text: String) -> void:
	return


func _find_clicked_abnormal_cell(screen_pos: Vector2) -> int:
	if _remaining_abnormal_ids.is_empty():
		return -1

	var container_rect := left_3d.get_global_rect()
	var viewport_pos := _screen_to_left_viewport_position(screen_pos, container_rect)
	var ray_origin_world := camera_3d.project_ray_origin(viewport_pos)
	var ray_dir_world := camera_3d.project_ray_normal(viewport_pos).normalized()
	var to_local := sphere.global_transform.affine_inverse()
	var ray_origin := to_local * ray_origin_world
	var ray_dir := (to_local.basis * ray_dir_world).normalized()

	var best_cell_id := -1
	var best_t := 1.0e20
	for cell_id in _remaining_abnormal_ids:
		var cell: Object = _current_cells_by_id.get(cell_id) as Object
		if cell == null:
			continue
		var hit_t := _ray_intersects_cell(ray_origin, ray_dir, cell)
		if hit_t >= 0.0 and hit_t < best_t:
			best_t = hit_t
			best_cell_id = cell_id

	return best_cell_id


func _ray_intersects_cell(ray_origin: Vector3, ray_dir: Vector3, cell: Object) -> float:
	var best_t := 1.0e20
	var poly := cell.get("polygon") as PackedVector3Array
	if poly.size() < 3:
		return -1.0

	var apex := cell.get("mesh_center") as Vector3
	var base_center := cell.get("center") as Vector3

	for vertex_index in range(poly.size()):
		var t_side := _ray_intersects_triangle(
			ray_origin,
			ray_dir,
			apex,
			poly[vertex_index],
			poly[(vertex_index + 1) % poly.size()]
		)
		if t_side >= 0.0 and t_side < best_t:
			best_t = t_side

	if _current_stage_mode == ABNORMAL_CONE_MODE:
		for vertex_index in range(poly.size()):
			var t_base := _ray_intersects_triangle(
				ray_origin,
				ray_dir,
				base_center,
				poly[vertex_index],
				poly[(vertex_index + 1) % poly.size()]
			)
			if t_base >= 0.0 and t_base < best_t:
				best_t = t_base

	return best_t if best_t < 1.0e20 else -1.0


func _ray_intersects_triangle(
	ray_origin: Vector3,
	ray_dir: Vector3,
	a: Vector3,
	b: Vector3,
	c: Vector3
) -> float:
	var edge_ab := b - a
	var edge_ac := c - a
	var p_vec := ray_dir.cross(edge_ac)
	var det := edge_ab.dot(p_vec)
	if absf(det) < 0.000001:
		return -1.0

	var inv_det := 1.0 / det
	var t_vec := ray_origin - a
	var u := t_vec.dot(p_vec) * inv_det
	if u < 0.0 or u > 1.0:
		return -1.0

	var q_vec := t_vec.cross(edge_ab)
	var v := ray_dir.dot(q_vec) * inv_det
	if v < 0.0 or u + v > 1.0:
		return -1.0

	var t := edge_ac.dot(q_vec) * inv_det
	return t if t >= 0.0 else -1.0


func _update_goldberg_wave_shader_state() -> void:
	if _sphere_material == null:
		return

	var is_goldberg := _is_current_shape_goldberg()
	var shape_radius := SHAPE_RADIUS
	if _current_shape_data != null:
		var data_radius := float(_current_shape_data.get("radius"))
		if data_radius > 0.0:
			shape_radius = data_radius

	var wave_displacement := shape_radius * goldberg_wave_displacement_ratio
	var abnormal_ids_a := Vector4(-1.0, -1.0, -1.0, -1.0)
	var abnormal_intensities_a := Vector4(0.0, 0.0, 0.0, 0.0)
	var abnormal_ids_b := Vector4(-1.0, -1.0, -1.0, -1.0)
	var abnormal_intensities_b := Vector4(0.0, 0.0, 0.0, 0.0)
	for slot_index in range(mini(MAX_ABNORMAL_TARGETS, _current_stage_abnormal_ids.size())):
		var cell_id := _current_stage_abnormal_ids[slot_index]
		var intensity := float(_abnormal_intensities.get(cell_id, 0.0))
		match slot_index:
			0:
				abnormal_ids_a.x = float(cell_id)
				abnormal_intensities_a.x = intensity
			1:
				abnormal_ids_a.y = float(cell_id)
				abnormal_intensities_a.y = intensity
			2:
				abnormal_ids_a.z = float(cell_id)
				abnormal_intensities_a.z = intensity
			3:
				abnormal_ids_a.w = float(cell_id)
				abnormal_intensities_a.w = intensity
			4:
				abnormal_ids_b.x = float(cell_id)
				abnormal_intensities_b.x = intensity

	var abnormal_mode_value := 0.0
	var abnormal_flash_strength := 0.0
	var abnormal_motion_strength := 0.0
	var abnormal_shake_strength := 0.0
	var hit_axis := _click_feedback_axis
	var hit_progress := _click_feedback_progress
	var hit_strength := _click_feedback_strength
	match _current_stage_mode:
		ABNORMAL_FACE_MODE:
			abnormal_mode_value = 1.0
			abnormal_flash_strength = 1.25
		ABNORMAL_CONE_MODE:
			abnormal_mode_value = 2.0
			abnormal_flash_strength = 1.45
			abnormal_motion_strength = shape_radius * 0.18
			abnormal_shake_strength = shape_radius * 0.012

	_sphere_material.set_shader_parameter("wave_enabled", 1.0 if is_goldberg else 0.0)
	_sphere_material.set_shader_parameter("wave_displacement", maxf(0.0, wave_displacement))
	_sphere_material.set_shader_parameter("wave_speed", maxf(0.0, goldberg_wave_speed))
	_sphere_material.set_shader_parameter("wave_phase_scale", maxf(0.0, goldberg_wave_phase_scale))
	_sphere_material.set_shader_parameter("abnormal_mode", abnormal_mode_value)
	_sphere_material.set_shader_parameter("abnormal_cell_ids_a", abnormal_ids_a)
	_sphere_material.set_shader_parameter("abnormal_cell_intensities_a", abnormal_intensities_a)
	_sphere_material.set_shader_parameter("abnormal_cell_ids_b", abnormal_ids_b)
	_sphere_material.set_shader_parameter("abnormal_cell_intensities_b", abnormal_intensities_b)
	_sphere_material.set_shader_parameter("abnormal_flash_strength", abnormal_flash_strength)
	_sphere_material.set_shader_parameter("abnormal_motion_strength", abnormal_motion_strength)
	_sphere_material.set_shader_parameter("abnormal_shake_strength", abnormal_shake_strength)
	_sphere_material.set_shader_parameter("hit_axis", hit_axis)
	_sphere_material.set_shader_parameter("hit_progress", hit_progress)
	_sphere_material.set_shader_parameter("hit_strength", hit_strength)

	if _cone_edge_material != null:
		_cone_edge_material.set_shader_parameter("wave_enabled", 1.0 if is_goldberg else 0.0)
		_cone_edge_material.set_shader_parameter("wave_displacement", maxf(0.0, wave_displacement))
		_cone_edge_material.set_shader_parameter("wave_speed", maxf(0.0, goldberg_wave_speed))
		_cone_edge_material.set_shader_parameter("wave_phase_scale", maxf(0.0, goldberg_wave_phase_scale))
		_cone_edge_material.set_shader_parameter("abnormal_mode", abnormal_mode_value if is_goldberg else 0.0)
		_cone_edge_material.set_shader_parameter("abnormal_cell_ids_a", abnormal_ids_a)
		_cone_edge_material.set_shader_parameter("abnormal_cell_intensities_a", abnormal_intensities_a)
		_cone_edge_material.set_shader_parameter("abnormal_cell_ids_b", abnormal_ids_b)
		_cone_edge_material.set_shader_parameter("abnormal_cell_intensities_b", abnormal_intensities_b)
		_cone_edge_material.set_shader_parameter("abnormal_flash_strength", abnormal_flash_strength if is_goldberg else 0.0)
		_cone_edge_material.set_shader_parameter("abnormal_motion_strength", abnormal_motion_strength if is_goldberg else 0.0)
		_cone_edge_material.set_shader_parameter("abnormal_shake_strength", abnormal_shake_strength if is_goldberg else 0.0)
		_cone_edge_material.set_shader_parameter("global_pulse_strength", _sphere_pulse)
		_cone_edge_material.set_shader_parameter("hit_axis", hit_axis)
		_cone_edge_material.set_shader_parameter("hit_progress", hit_progress)
		_cone_edge_material.set_shader_parameter("hit_strength", hit_strength)


func _start_shake(duration: float, rotation_strength_deg: float, position_strength: float) -> void:
	_shake_total_duration = maxf(0.01, duration)
	_shake_time_left = _shake_total_duration
	_shake_strength_rot = maxf(0.0, rotation_strength_deg)
	_shake_strength_pos = maxf(0.0, position_strength)
	_sphere_pulse = 1.0


func _trigger_noise_burst(amount: float) -> void:
	_noise_burst_strength = maxf(_noise_burst_strength, clampf(amount, 0.0, 1.0))


func _set_flash_alpha(alpha: float) -> void:
	if _flash_overlay != null:
		_flash_overlay.color.a = clampf(alpha, 0.0, 1.0)


func _is_click_on_sphere(screen_pos: Vector2) -> bool:
	var container_rect := left_3d.get_global_rect()
	if not container_rect.has_point(screen_pos):
		return false
	if camera_3d.is_position_behind(sphere.global_position):
		return false

	var viewport_pos := _screen_to_left_viewport_position(screen_pos, container_rect)
	var ray_origin := camera_3d.project_ray_origin(viewport_pos)
	var ray_dir := camera_3d.project_ray_normal(viewport_pos).normalized()
	return _ray_hits_sphere(ray_origin, ray_dir, sphere.global_position, _get_sphere_world_radius())


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


func _ray_hits_sphere(ray_origin: Vector3, ray_dir: Vector3, sphere_center: Vector3, sphere_radius: float) -> bool:
	var to_origin := ray_origin - sphere_center
	var a := ray_dir.dot(ray_dir)
	var b := 2.0 * to_origin.dot(ray_dir)
	var c := to_origin.dot(to_origin) - sphere_radius * sphere_radius
	var disc := b * b - 4.0 * a * c
	if disc < 0.0:
		return false
	var sqrt_disc := sqrt(disc)
	var inv_denom := 0.5 / maxf(0.000001, a)
	var t0 := (-b - sqrt_disc) * inv_denom
	var t1 := (-b + sqrt_disc) * inv_denom
	return t0 >= 0.0 or t1 >= 0.0


func _get_sphere_world_radius() -> float:
	if sphere.mesh == null:
		return SHAPE_RADIUS
	var aabb := sphere.mesh.get_aabb()
	var radius := maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z)) * 0.5
	var scale_basis := sphere.global_transform.basis.get_scale()
	var max_scale := maxf(absf(scale_basis.x), maxf(absf(scale_basis.y), absf(scale_basis.z)))
	return maxf(0.1, radius * max_scale)


func _ensure_edge_overlay_instance() -> void:
	if _edge_overlay_instance == null or not is_instance_valid(_edge_overlay_instance):
		_edge_overlay_instance = sphere.get_node_or_null("EdgeOverlay") as MeshInstance3D
		if _edge_overlay_instance == null:
			_edge_overlay_instance = MeshInstance3D.new()
			_edge_overlay_instance.name = "EdgeOverlay"
			_edge_overlay_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			_edge_overlay_instance.visible = false
			_edge_overlay_instance.scale = Vector3.ONE
			sphere.add_child(_edge_overlay_instance)

	if _static_edge_overlay_instance == null or not is_instance_valid(_static_edge_overlay_instance):
		_static_edge_overlay_instance = sphere.get_node_or_null("StaticEdgeOverlay") as MeshInstance3D
		if _static_edge_overlay_instance == null:
			_static_edge_overlay_instance = MeshInstance3D.new()
			_static_edge_overlay_instance.name = "StaticEdgeOverlay"
			_static_edge_overlay_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			_static_edge_overlay_instance.visible = false
			_static_edge_overlay_instance.scale = Vector3.ONE
			sphere.add_child(_static_edge_overlay_instance)


func _set_polyhedron_edge_outline_enabled(enabled: bool) -> void:
	_ensure_edge_overlay_instance()
	var edge_mesh: Mesh = null
	var static_edge_mesh: Mesh = null
	if _current_shape_data != null:
		edge_mesh = _current_shape_data.get("edge_mesh")
		static_edge_mesh = _current_shape_data.get("static_edge_mesh")
	if not enabled or _current_shape_data == null or edge_mesh == null:
		if _edge_overlay_instance != null:
			_edge_overlay_instance.visible = false
		if _static_edge_overlay_instance != null:
			_static_edge_overlay_instance.visible = false
		return

	if _is_current_shape_goldberg():
		_ensure_cone_edge_material()
		_ensure_scaffold_edge_material()
		_edge_overlay_instance.material_override = _cone_edge_material
		_update_edge_overlay_mesh(edge_mesh)
		_edge_overlay_instance.visible = true
		_update_static_edge_overlay_mesh(static_edge_mesh)
		_static_edge_overlay_instance.material_override = _scaffold_edge_material
		_static_edge_overlay_instance.visible = static_edge_mesh != null
	else:
		if _polyhedron_edge_material == null:
			_polyhedron_edge_material = StandardMaterial3D.new()
			_polyhedron_edge_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			_polyhedron_edge_material.cull_mode = BaseMaterial3D.CULL_DISABLED
			_polyhedron_edge_material.roughness = 0.0
			_polyhedron_edge_material.metallic = 0.0
			_polyhedron_edge_material.emission_enabled = true

		_edge_overlay_instance.material_override = _polyhedron_edge_material
		_update_edge_overlay_mesh(edge_mesh)
		_edge_overlay_instance.visible = true
		if _static_edge_overlay_instance != null:
			_static_edge_overlay_instance.visible = false
	_apply_edge_outline_style()


func _ensure_cone_edge_material() -> void:
	if _cone_edge_material != null:
		return

	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

uniform vec4 edge_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float edge_emission_strength : hint_range(0.0, 4.0) = 1.0;
uniform float wave_enabled : hint_range(0.0, 1.0) = 0.0;
uniform float wave_displacement : hint_range(0.0, 1.0) = 0.16666667;
uniform float wave_speed : hint_range(0.0, 6.0) = 1.05;
uniform float wave_phase_scale : hint_range(0.0, 24.0) = 8.5;
uniform float abnormal_mode : hint_range(0.0, 2.0) = 0.0;
uniform vec4 abnormal_cell_ids_a = vec4(-1.0, -1.0, -1.0, -1.0);
uniform vec4 abnormal_cell_intensities_a = vec4(0.0, 0.0, 0.0, 0.0);
uniform vec4 abnormal_cell_ids_b = vec4(-1.0, -1.0, -1.0, -1.0);
uniform vec4 abnormal_cell_intensities_b = vec4(0.0, 0.0, 0.0, 0.0);
uniform float abnormal_flash_strength : hint_range(0.0, 4.0) = 0.0;
uniform float abnormal_motion_strength : hint_range(0.0, 1.0) = 0.0;
uniform float abnormal_shake_strength : hint_range(0.0, 0.25) = 0.0;
uniform float global_pulse_strength : hint_range(0.0, 1.0) = 0.0;
uniform float hit_strength : hint_range(0.0, 1.0) = 0.0;
uniform float hit_progress : hint_range(0.0, 1.0) = 1.0;
uniform vec3 hit_axis = vec3(0.0, 1.0, 0.0);

float outward_only_wave(float phase) {
	return max(0.0, sin(phase));
}

float cell_seed(float cell_id) {
	return fract(sin(cell_id * 12.9898) * 43758.5453123);
}

float abnormal_slot_weight(float target_id, float cell_id, float intensity) {
	return abs(cell_id - target_id) < 0.25 ? intensity : 0.0;
}

float abnormal_weight(float cell_id) {
	return abnormal_slot_weight(abnormal_cell_ids_a.x, cell_id, abnormal_cell_intensities_a.x)
		+ abnormal_slot_weight(abnormal_cell_ids_a.y, cell_id, abnormal_cell_intensities_a.y)
		+ abnormal_slot_weight(abnormal_cell_ids_a.z, cell_id, abnormal_cell_intensities_a.z)
		+ abnormal_slot_weight(abnormal_cell_ids_a.w, cell_id, abnormal_cell_intensities_a.w)
		+ abnormal_slot_weight(abnormal_cell_ids_b.x, cell_id, abnormal_cell_intensities_b.x)
		+ abnormal_slot_weight(abnormal_cell_ids_b.y, cell_id, abnormal_cell_intensities_b.y)
		+ abnormal_slot_weight(abnormal_cell_ids_b.z, cell_id, abnormal_cell_intensities_b.z)
		+ abnormal_slot_weight(abnormal_cell_ids_b.w, cell_id, abnormal_cell_intensities_b.w);
}

float abnormal_flicker(float time_value, float seed) {
	float fast = sin(time_value * (12.0 + seed * 6.0) + seed * 19.0);
	float mid = sin(time_value * (23.0 + seed * 5.0) + seed * 37.0);
	float burst = sin(time_value * (41.0 + seed * 9.0) + seed * 53.0);
	return clamp(abs(fast) * 0.45 + abs(mid) * 0.35 + max(0.0, burst) * 0.6, 0.0, 1.0);
}

vec3 stable_perpendicular(vec3 axis) {
	vec3 reference = abs(axis.y) > 0.92 ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 1.0, 0.0);
	return normalize(cross(axis, reference));
}

vec3 safe_normalize(vec3 value) {
	float len = length(value);
	return len > 0.0001 ? value / len : vec3(0.0, 1.0, 0.0);
}

float hit_wave(vec3 axis) {
	float strength = clamp(hit_strength, 0.0, 1.0);
	if (strength <= 0.0001) {
		return 0.0;
	}

	float distance = clamp((1.0 - dot(safe_normalize(axis), safe_normalize(hit_axis))) * 0.5, 0.0, 1.0);
	float front = clamp(hit_progress, 0.0, 1.0);
	float ring_width = 0.05 + front * 0.1;
	float core = 1.0 - smoothstep(0.04, 0.14 + front * 0.22, distance);
	float ring = 1.0 - smoothstep(ring_width, ring_width + 0.08, abs(distance - front));
	float fill = 1.0 - smoothstep(front + 0.05, front + 0.2, distance);
	return max(core, max(ring, fill * 0.72)) * strength;
}

void vertex() {
	float wave_value = outward_only_wave(TIME * wave_speed - UV.x * wave_phase_scale);
	float displacement = wave_enabled * wave_displacement * wave_value;
	vec3 wave_axis = COLOR.rgb * 2.0 - vec3(1.0);
	float axis_len = length(wave_axis);
	if (axis_len > 0.0001) {
		wave_axis /= axis_len;
		VERTEX += wave_axis * displacement;
	}

	float cell_id = UV2.x;
	float abnormal = abnormal_weight(cell_id);
	if (abnormal_mode > 1.5 && abnormal > 0.0001 && axis_len > 0.0001) {
		float seed = cell_seed(cell_id);
		float twitch = sin(TIME * (13.0 + seed * 7.0) + seed * 11.0) * 0.58;
		twitch += sin(TIME * (27.0 + seed * 5.0) + seed * 23.0) * 0.31;
		twitch += sin(TIME * (43.0 + seed * 9.0) + seed * 41.0) * 0.16;
		twitch = clamp(twitch, -1.0, 1.0);
		VERTEX += wave_axis * abnormal_motion_strength * abnormal * twitch;

		vec3 tangent = stable_perpendicular(wave_axis);
		vec3 bitangent = normalize(cross(wave_axis, tangent));
		float shake_a = sin(TIME * (19.0 + seed * 4.0) + dot(VERTEX.xyz, vec3(6.7, 5.1, 4.3)));
		float shake_b = cos(TIME * (23.0 + seed * 6.0) + dot(VERTEX.zxy, vec3(3.3, 6.4, 5.5)));
		VERTEX += (tangent * shake_a + bitangent * shake_b) * abnormal_shake_strength * abnormal;
	}

	float hit = hit_wave(axis_len > 0.0001 ? wave_axis : hit_axis);
	if (hit > 0.0001 && axis_len > 0.0001) {
		VERTEX += wave_axis * (0.01 + wave_displacement * 0.08) * hit;
	}
}

void fragment() {
	float abnormal = abnormal_weight(UV2.x);
	float flash = abnormal_flicker(TIME, cell_seed(UV2.x)) * abnormal_flash_strength * abnormal;
	vec3 axis = COLOR.rgb * 2.0 - vec3(1.0);
	float hit = hit_wave(axis);
	vec3 hit_tint = mix(vec3(1.0, 0.95, 0.84), vec3(0.84, 0.95, 1.0), clamp(hit_progress, 0.0, 1.0));
	vec3 edge_lit = clamp(edge_color.rgb + vec3(flash * 0.12 + global_pulse_strength * 0.08) + hit_tint * hit * 0.14, vec3(0.0), vec3(1.0));
	ALBEDO = edge_lit;
	EMISSION = edge_color.rgb * (edge_emission_strength + global_pulse_strength * 0.55) + vec3(flash) + hit_tint * hit * 1.2;
}
"""
	_cone_edge_material = ShaderMaterial.new()
	_cone_edge_material.shader = shader
	_update_goldberg_wave_shader_state()


func _ensure_scaffold_edge_material() -> void:
	if _scaffold_edge_material != null:
		return

	_scaffold_edge_material = StandardMaterial3D.new()
	_scaffold_edge_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_scaffold_edge_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_scaffold_edge_material.roughness = 0.0
	_scaffold_edge_material.metallic = 0.0
	_scaffold_edge_material.emission_enabled = true


func _update_edge_overlay_mesh(edge_mesh: Mesh = null) -> void:
	if _edge_overlay_instance == null or not is_instance_valid(_edge_overlay_instance):
		return
	if edge_mesh == null and _current_shape_data != null:
		edge_mesh = _current_shape_data.get("edge_mesh")
	_edge_overlay_instance.mesh = edge_mesh


func _update_static_edge_overlay_mesh(edge_mesh: Mesh = null) -> void:
	if _static_edge_overlay_instance == null or not is_instance_valid(_static_edge_overlay_instance):
		return
	if edge_mesh == null and _current_shape_data != null:
		edge_mesh = _current_shape_data.get("static_edge_mesh")
	_static_edge_overlay_instance.mesh = edge_mesh


func _apply_edge_outline_style() -> void:
	if _edge_overlay_instance != null and is_instance_valid(_edge_overlay_instance):
		_edge_overlay_instance.scale = Vector3.ONE
	if _static_edge_overlay_instance != null and is_instance_valid(_static_edge_overlay_instance):
		_static_edge_overlay_instance.scale = Vector3.ONE

	if _is_current_shape_goldberg():
		if _cone_edge_material != null:
			var glow_strength := clampf(0.75 + (polyhedron_edge_line_width - 1.0) * 0.08 + _sphere_pulse * 0.42, 0.75, 1.75)
			_cone_edge_material.set_shader_parameter("edge_color", polyhedron_edge_color)
			_cone_edge_material.set_shader_parameter("edge_emission_strength", glow_strength)
		if _scaffold_edge_material != null:
			var scaffold_intensity := clampf(goldberg_scaffold_edge_alpha, 0.0, 1.0)
			var scaffold_color := Color(
				polyhedron_edge_color.r * scaffold_intensity,
				polyhedron_edge_color.g * scaffold_intensity,
				polyhedron_edge_color.b * scaffold_intensity,
				1.0
			)
			_scaffold_edge_material.albedo_color = scaffold_color
			_scaffold_edge_material.emission = scaffold_color
			_scaffold_edge_material.emission_energy_multiplier = goldberg_scaffold_edge_brightness + _sphere_pulse * 0.18
	elif _polyhedron_edge_material != null:
		var edge_color := polyhedron_edge_color
		var glow_strength := clampf(0.75 + (polyhedron_edge_line_width - 1.0) * 0.08 + _sphere_pulse * 0.5, 0.75, 1.8)
		_polyhedron_edge_material.albedo_color = edge_color
		_polyhedron_edge_material.emission = edge_color
		_polyhedron_edge_material.emission_energy_multiplier = glow_strength


func _is_current_shape_goldberg() -> bool:
	return _current_shape_data != null and String(_current_shape_data.get("topology_kind")) == "goldberg"


func _on_chapter_1_split_dragged(_offset: int) -> void:
	_enforce_chapter_1_constraints()


func _on_layout_changed() -> void:
	left_viewport.size = Vector2i(maxi(1, int(left_3d.size.x)), maxi(1, int(left_3d.size.y)))
	_enforce_chapter_1_constraints()


func _enforce_chapter_1_constraints() -> void:
	var min_right_width := maxf(1.0, size.x * 0.5)
	right_panel.custom_minimum_size.x = min_right_width
	if chapter_1_split.split_offset > 0:
		chapter_1_split.split_offset = 0
