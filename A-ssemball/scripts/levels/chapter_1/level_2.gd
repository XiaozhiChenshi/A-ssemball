extends Control
class_name LevelC1L2

signal chapter_completed(chapter_index: int)

const StructureShapeProviderRef = preload("res://scripts/structure/structure_shape_provider.gd")
const HAND_TEXTURE: Texture2D = preload("res://assets/ui/chapter_1_stage_2/Hand04.png")

const STAGE_PATTERN_RINGS := "rings"
const STAGE_PATTERN_CRACK := "crack"
const STAGE_PATTERN_FACETS := "facets"
const MAX_ABNORMAL_TARGETS: int = 5
const ABNORMAL_FACE_MODE := "abnormal_face"
const ABNORMAL_CONE_MODE := "abnormal_cone"
const NORMAL_STAGE_MODE := "normal"
const ACT_ONE_BASE_COLOR: Color = Color(0.68, 0.74, 0.82, 1.0)
const ACT_ONE_LOW_COLOR: Color = Color(0.17, 0.21, 0.29, 1.0)
const ACT_ONE_HIGH_COLOR: Color = Color(0.78, 0.84, 0.92, 1.0)
const ACT_ONE_EDGE_COLOR: Color = Color(1.0, 1.0, 1.0, 1.0)
const ACT_ONE_BACKGROUND_COLOR: Color = Color(0.01, 0.015, 0.025, 1.0)

@export var chapter_index: int = 1
@export var light_rotation_speed_deg: float = 0.0
@export var light_energy: float = 0.85
@export var sphere_rotate_speed_deg: float = 120.0
@export var polyhedron_edge_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export_range(1.0, 8.0, 0.1) var polyhedron_edge_line_width: float = 2.0
@export_range(0.0, 1.0, 0.001) var goldberg_wave_displacement_ratio: float = 1.0 / 6.0
@export_range(0.0, 6.0, 0.01) var goldberg_wave_speed: float = 1.05
@export_range(0.0, 24.0, 0.1) var goldberg_wave_phase_scale: float = 8.5
@export_range(0.0, 1.0, 0.01) var goldberg_scaffold_edge_alpha: float = 0.24
@export_range(0.0, 1.0, 0.01) var goldberg_scaffold_edge_brightness: float = 0.3
@export var shape_radius: float = 1.0
@export_range(0.03, 0.4, 0.01) var cell_hold_sec: float = 0.08
@export_range(0.0, 0.4, 0.01) var drag_grace_sec: float = 0.18
@export_range(0.75, 0.98, 0.01) var cell_face_inset: float = 0.9
@export_range(1.0, 1.08, 0.005) var cell_hit_scale: float = 1.02
@export_range(0.0, 0.03, 0.001) var cell_surface_offset: float = 0.004
@export_range(0.4, 1.2, 0.01) var cone_depth_scale: float = 0.86
@export_range(15.0, 180.0, 1.0) var rotation_yaw_speed_deg: float = 84.0
@export_range(15.0, 180.0, 1.0) var rotation_pitch_speed_deg: float = 66.0
@export_range(10.0, 89.0, 1.0) var pitch_limit_deg: float = 72.0
@export_range(0.2, 2.0, 0.01) var hand_wipe_duration_sec: float = 1.15

@onready var chapter_1_split: HSplitContainer = $Chapter1Split
@onready var left_3d: SubViewportContainer = $Chapter1Split/Left3D
@onready var left_viewport: SubViewport = $Chapter1Split/Left3D/LeftViewport
@onready var world_environment: WorldEnvironment = $Chapter1Split/Left3D/LeftViewport/World3D/WorldEnvironment
@onready var camera_3d: Camera3D = $Chapter1Split/Left3D/LeftViewport/World3D/Camera3D
@onready var model_root: Node3D = $Chapter1Split/Left3D/LeftViewport/World3D/ModelRoot
@onready var sphere: MeshInstance3D = $Chapter1Split/Left3D/LeftViewport/World3D/ModelRoot/Sphere
@onready var marker: MeshInstance3D = $Chapter1Split/Left3D/LeftViewport/World3D/ModelRoot/Sphere/Marker
@onready var right_panel: ColorRect = $Chapter1Split/RightPanel
@onready var line_canvas: LineCanvas2D = $Chapter1Split/RightPanel/LineCanvas
@onready var dir_light: DirectionalLight3D = $Chapter1Split/Left3D/LeftViewport/World3D/DirectionalLight3D
@onready var fill_light: DirectionalLight3D = $Chapter1Split/Left3D/LeftViewport/World3D/DirectionalLight3D2

var _shape_provider
var _base_shape_data
var _cells_by_id: Dictionary = {}

var _cell_root: Node3D
var _cell_nodes: Dictionary = {}
var _cell_materials: Dictionary = {}
var _cell_runtime_data: Dictionary = {}

var _stage_data: Array[Dictionary] = []
var _current_stage_index: int = 0
var _current_stage_route_ids: Array[int] = []
var _current_stage_core_lookup: Dictionary = {}
var _current_stage_height_map: Dictionary = {}
var _current_preview_uvs: PackedVector2Array = PackedVector2Array()

var _selected_route_ids: Array[int] = []
var _drag_active: bool = false
var _drag_anchor_cell_id: int = -1
var _hover_cell_id: int = -1
var _hover_hold_elapsed: float = 0.0
var _drag_grace_left: float = 0.0
var _latest_mouse_pos: Vector2 = Vector2.ZERO

var _transition_running: bool = false
var _chapter_completed_once: bool = false
var _yaw_deg: float = 0.0
var _pitch_deg: float = -18.0
var _orientation_tween: Tween
var _sphere_material: ShaderMaterial
var _polyhedron_edge_material: StandardMaterial3D
var _cone_edge_material: ShaderMaterial
var _scaffold_edge_material: StandardMaterial3D
var _current_shape_data
var _current_stage_mode: String = NORMAL_STAGE_MODE
var _current_stage_abnormal_ids: Array[int] = []
var _abnormal_intensities: Dictionary = {}
var _sphere_pulse: float = 0.0
var _click_feedback_axis: Vector3 = Vector3.UP
var _click_feedback_progress: float = 1.0
var _click_feedback_strength: float = 0.0
var _scaffold_material: StandardMaterial3D
var _edge_overlay_instance: MeshInstance3D
var _static_edge_overlay_instance: MeshInstance3D
var _edge_overlay_material: StandardMaterial3D
var _static_edge_overlay_material: StandardMaterial3D

var _panel_root: Control
var _panel_backdrop: ColorRect
var _stage_badge_label: Label
var _title_label: Label
var _desc_label: Label
var _progress_label: Label
var _hint_label: Label
var _status_label: Label
var _hand_rect: TextureRect


func _ready() -> void:
	_shape_provider = StructureShapeProviderRef.new()
	_base_shape_data = _shape_provider.get_goldberg(1, 4, shape_radius)
	_rebuild_cell_lookup()

	marker.visible = false
	dir_light.light_energy = light_energy
	right_panel.color = ACT_ONE_BACKGROUND_COLOR
	right_panel.clip_contents = true
	line_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_setup_world_style()
	_setup_sphere_material()
	_ensure_edge_overlay_instance()

	_setup_right_panel_ui()
	_stage_data = _build_stage_data()
	_ensure_cell_root()
	sphere.rotation = Vector3.ZERO

	resized.connect(_on_layout_changed)
	left_3d.resized.connect(_on_layout_changed)
	chapter_1_split.dragged.connect(_on_chapter_1_split_dragged)
	_on_layout_changed()
	_apply_stage(0, false)


func _process(delta: float) -> void:
	_update_rotation_input(delta)
	if _drag_active and not _transition_running:
		_update_drag_progress(delta)
	_apply_edge_outline_style()
	if light_rotation_speed_deg != 0.0:
		dir_light.rotate_y(deg_to_rad(light_rotation_speed_deg) * delta)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_latest_mouse_pos = event.position
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_latest_mouse_pos = event.position
		if event.pressed:
			_try_begin_drag()
		elif _drag_active:
			_cancel_drag("描摹中断，已重置。")
			get_viewport().set_input_as_handled()


func _build_stage_data() -> Array[Dictionary]:
	return [
		{
			"title": "树木年轮",
			"subtitle": "文字占位贴图：树木年轮",
			"pattern": STAGE_PATTERN_RINGS,
			"core_cells": [0],
			"focus_yaw_deg": 0.0,
			"focus_pitch_deg": -18.0,
			"low_color": ACT_ONE_LOW_COLOR,
			"high_color": ACT_ONE_HIGH_COLOR,
			"route_color": Color(0.86, 0.90, 0.97, 1.0),
			"selected_color": Color(1.0, 0.95, 0.84, 1.0),
			"target_color": Color(0.95, 0.98, 1.0, 1.0),
			"panel_color": Color(0.04, 0.05, 0.08, 1.0),
			"noise_axis": Vector3(0.0, 1.0, 0.2).normalized(),
			"preview_template": PackedVector2Array([
				Vector2(0.50, 0.20),
				Vector2(0.70, 0.30),
				Vector2(0.78, 0.50),
				Vector2(0.70, 0.70),
				Vector2(0.50, 0.80),
				Vector2(0.30, 0.70),
				Vector2(0.22, 0.50),
				Vector2(0.30, 0.30),
			]),
		},
		{
			"title": "干涸的大地",
			"subtitle": "文字占位贴图：干涸的大地",
			"pattern": STAGE_PATTERN_CRACK,
			"core_cells": [58, 59, 60, 61],
			"focus_yaw_deg": -16.0,
			"focus_pitch_deg": -22.0,
			"low_color": ACT_ONE_LOW_COLOR,
			"high_color": ACT_ONE_HIGH_COLOR,
			"route_color": Color(0.88, 0.90, 0.95, 1.0),
			"selected_color": Color(1.0, 0.95, 0.84, 1.0),
			"target_color": Color(0.95, 0.98, 1.0, 1.0),
			"panel_color": Color(0.04, 0.05, 0.08, 1.0),
			"noise_axis": Vector3(0.35, 0.92, -0.18).normalized(),
			"preview_template": PackedVector2Array([
				Vector2(0.22, 0.30),
				Vector2(0.38, 0.22),
				Vector2(0.56, 0.30),
				Vector2(0.72, 0.18),
				Vector2(0.82, 0.34),
				Vector2(0.76, 0.58),
				Vector2(0.62, 0.74),
				Vector2(0.42, 0.78),
				Vector2(0.24, 0.68),
				Vector2(0.18, 0.48),
			]),
		},
		{
			"title": "花岗岩",
			"subtitle": "文字占位贴图：花岗岩",
			"pattern": STAGE_PATTERN_FACETS,
			"core_cells": [133, 136, 140],
			"focus_yaw_deg": -68.0,
			"focus_pitch_deg": -14.0,
			"low_color": ACT_ONE_LOW_COLOR,
			"high_color": ACT_ONE_HIGH_COLOR,
			"route_color": Color(0.86, 0.90, 0.97, 1.0),
			"selected_color": Color(0.97, 0.98, 1.0, 1.0),
			"target_color": Color(0.95, 0.98, 1.0, 1.0),
			"panel_color": Color(0.04, 0.05, 0.08, 1.0),
			"noise_axis": Vector3(0.9, -0.2, 0.36).normalized(),
			"preview_template": PackedVector2Array([
				Vector2(0.30, 0.24),
				Vector2(0.64, 0.18),
				Vector2(0.82, 0.42),
				Vector2(0.70, 0.76),
				Vector2(0.34, 0.82),
				Vector2(0.18, 0.54),
			]),
		},
	]


func _setup_right_panel_ui() -> void:
	_panel_root = Control.new()
	_panel_root.name = "StagePanel"
	_panel_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right_panel.add_child(_panel_root)
	right_panel.move_child(_panel_root, 0)

	_panel_backdrop = ColorRect.new()
	_panel_backdrop.name = "Backdrop"
	_panel_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel_root.add_child(_panel_backdrop)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.offset_left = 28.0
	margin.offset_top = 28.0
	margin.offset_right = -28.0
	margin.offset_bottom = -28.0
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel_root.add_child(margin)

	var layout := VBoxContainer.new()
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 14)
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(layout)

	_stage_badge_label = Label.new()
	_stage_badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stage_badge_label.add_theme_font_size_override("font_size", 18)
	layout.add_child(_stage_badge_label)

	var spacer_top := Control.new()
	spacer_top.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(spacer_top)

	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_label.add_theme_font_size_override("font_size", 34)
	layout.add_child(_title_label)

	_desc_label = Label.new()
	_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_desc_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_label.add_theme_font_size_override("font_size", 20)
	layout.add_child(_desc_label)

	var spacer_mid := Control.new()
	spacer_mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer_mid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(spacer_mid)

	_progress_label = Label.new()
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_progress_label.add_theme_font_size_override("font_size", 18)
	layout.add_child(_progress_label)

	_hint_label = Label.new()
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_label.add_theme_font_size_override("font_size", 18)
	layout.add_child(_hint_label)

	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_size_override("font_size", 16)
	layout.add_child(_status_label)

	_hand_rect = TextureRect.new()
	_hand_rect.name = "HandWipe"
	_hand_rect.texture = HAND_TEXTURE
	_hand_rect.visible = false
	_hand_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hand_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hand_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	right_panel.add_child(_hand_rect)
	_hand_rect.move_to_front()

	line_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	line_canvas.offset_left = 0.0
	line_canvas.offset_top = 0.0
	line_canvas.offset_right = 0.0
	line_canvas.offset_bottom = 0.0
	line_canvas.move_to_front()
	_hand_rect.move_to_front()


func _rebuild_cell_lookup() -> void:
	_cells_by_id.clear()
	if _base_shape_data == null:
		return
	var cells: Array = _base_shape_data.get("cells") as Array
	for cell_variant in cells:
		var cell: Object = cell_variant as Object
		if cell == null:
			continue
		_cells_by_id[int(cell.get("id"))] = cell


func _ensure_cell_root() -> void:
	if _cell_root != null and is_instance_valid(_cell_root):
		return
	_cell_root = Node3D.new()
	_cell_root.name = "CellRoot"
	sphere.add_child(_cell_root)


func _setup_sphere_material() -> void:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode depth_draw_opaque, cull_disabled;

uniform vec4 base_color : source_color = vec4(0.82, 0.87, 0.96, 1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.4;
uniform float specular : hint_range(0.0, 1.0) = 0.18;
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
	SPECULAR = specular;
	EMISSION = lit * (emission_strength + pulse_strength * 0.3) + vec3(rim * rim_strength) + abnormal_glow + hit_glow * (1.05 + pulse_strength * 0.45);
}
"""
	_sphere_material = ShaderMaterial.new()
	_sphere_material.shader = shader
	sphere.material_override = _sphere_material
	_update_goldberg_wave_shader_state()


func _apply_base_goldberg_visual() -> void:
	_current_shape_data = _shape_provider.get_shape("goldberg:1:4", shape_radius)
	if _current_shape_data == null:
		return

	var body_mesh: Mesh = _current_shape_data.get("body_mesh")
	var edge_mesh: Mesh = _current_shape_data.get("edge_mesh")
	var static_edge_mesh: Mesh = _current_shape_data.get("static_edge_mesh")
	sphere.mesh = body_mesh
	sphere.visible = body_mesh != null
	_update_edge_overlay_mesh(edge_mesh)
	_update_static_edge_overlay_mesh(static_edge_mesh)
	if _sphere_material != null:
		_sphere_material.set_shader_parameter("base_color", ACT_ONE_BASE_COLOR)
	_current_stage_mode = NORMAL_STAGE_MODE
	_current_stage_abnormal_ids.clear()
	_abnormal_intensities.clear()
	_update_goldberg_wave_shader_state()
	_set_polyhedron_edge_outline_enabled(true)


func _update_goldberg_wave_shader_state() -> void:
	if _sphere_material == null:
		return

	var is_goldberg := _is_current_shape_goldberg()
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
	# Act 1-2 stays static at rest. Only interaction-driven feedback is allowed.
	_sphere_material.set_shader_parameter("wave_enabled", 0.0)
	_sphere_material.set_shader_parameter("wave_displacement", 0.0)
	_sphere_material.set_shader_parameter("wave_speed", 0.0)
	_sphere_material.set_shader_parameter("wave_phase_scale", 0.0)
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
		_cone_edge_material.set_shader_parameter("wave_enabled", 0.0)
		_cone_edge_material.set_shader_parameter("wave_displacement", 0.0)
		_cone_edge_material.set_shader_parameter("wave_speed", 0.0)
		_cone_edge_material.set_shader_parameter("wave_phase_scale", 0.0)
		_cone_edge_material.set_shader_parameter("abnormal_mode", 0.0)
		_cone_edge_material.set_shader_parameter("abnormal_cell_ids_a", abnormal_ids_a)
		_cone_edge_material.set_shader_parameter("abnormal_cell_intensities_a", abnormal_intensities_a)
		_cone_edge_material.set_shader_parameter("abnormal_cell_ids_b", abnormal_ids_b)
		_cone_edge_material.set_shader_parameter("abnormal_cell_intensities_b", abnormal_intensities_b)
		_cone_edge_material.set_shader_parameter("abnormal_flash_strength", 0.0)
		_cone_edge_material.set_shader_parameter("abnormal_motion_strength", 0.0)
		_cone_edge_material.set_shader_parameter("abnormal_shake_strength", 0.0)
		_cone_edge_material.set_shader_parameter("global_pulse_strength", 0.0)
		_cone_edge_material.set_shader_parameter("hit_axis", hit_axis)
		_cone_edge_material.set_shader_parameter("hit_progress", hit_progress)
		_cone_edge_material.set_shader_parameter("hit_strength", hit_strength)


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


func _setup_world_style() -> void:
	if world_environment != null and world_environment.environment != null:
		world_environment.environment.background_mode = Environment.BG_COLOR
		world_environment.environment.background_color = ACT_ONE_BACKGROUND_COLOR
		world_environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		world_environment.environment.ambient_light_color = Color(0.24, 0.28, 0.36, 1.0)
		world_environment.environment.ambient_light_energy = 0.36

	dir_light.light_color = Color(0.93, 0.97, 1.0, 1.0)
	dir_light.light_angular_distance = 2.2
	if fill_light != null:
		fill_light.light_color = Color(0.87, 0.91, 1.0, 1.0)
		fill_light.light_energy = 0.35


func _setup_scaffold_shell() -> void:
	if _base_shape_data == null:
		sphere.visible = false
		return

	var body_mesh := _base_shape_data.get("body_mesh") as Mesh
	sphere.mesh = body_mesh
	sphere.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sphere.visible = body_mesh != null

	if _scaffold_material == null:
		_scaffold_material = StandardMaterial3D.new()
		_scaffold_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_scaffold_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		_scaffold_material.roughness = 0.35
		_scaffold_material.metallic = 0.0
		_scaffold_material.emission_enabled = true
	sphere.material_override = _scaffold_material

	_ensure_scaffold_edge_instances()
	_refresh_scaffold_shell_style()


func _ensure_scaffold_edge_instances() -> void:
	if _edge_overlay_instance == null or not is_instance_valid(_edge_overlay_instance):
		_edge_overlay_instance = sphere.get_node_or_null("EdgeOverlay") as MeshInstance3D
		if _edge_overlay_instance == null:
			_edge_overlay_instance = MeshInstance3D.new()
			_edge_overlay_instance.name = "EdgeOverlay"
			_edge_overlay_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			sphere.add_child(_edge_overlay_instance)

	if _static_edge_overlay_instance == null or not is_instance_valid(_static_edge_overlay_instance):
		_static_edge_overlay_instance = sphere.get_node_or_null("StaticEdgeOverlay") as MeshInstance3D
		if _static_edge_overlay_instance == null:
			_static_edge_overlay_instance = MeshInstance3D.new()
			_static_edge_overlay_instance.name = "StaticEdgeOverlay"
			_static_edge_overlay_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			sphere.add_child(_static_edge_overlay_instance)

	if _edge_overlay_material == null:
		_edge_overlay_material = StandardMaterial3D.new()
		_edge_overlay_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_edge_overlay_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_edge_overlay_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		_edge_overlay_material.roughness = 0.0
		_edge_overlay_material.metallic = 0.0
		_edge_overlay_material.emission_enabled = true

	if _static_edge_overlay_material == null:
		_static_edge_overlay_material = StandardMaterial3D.new()
		_static_edge_overlay_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_static_edge_overlay_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_static_edge_overlay_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		_static_edge_overlay_material.roughness = 0.0
		_static_edge_overlay_material.metallic = 0.0
		_static_edge_overlay_material.emission_enabled = true

	var edge_mesh := _base_shape_data.get("edge_mesh") as Mesh
	var static_edge_mesh := _base_shape_data.get("static_edge_mesh") as Mesh
	_edge_overlay_instance.mesh = edge_mesh
	_edge_overlay_instance.material_override = _edge_overlay_material
	_edge_overlay_instance.visible = edge_mesh != null
	_static_edge_overlay_instance.mesh = static_edge_mesh
	_static_edge_overlay_instance.material_override = _static_edge_overlay_material
	_static_edge_overlay_instance.visible = static_edge_mesh != null


func _refresh_scaffold_shell_style() -> void:
	if _scaffold_material != null:
		_scaffold_material.albedo_color = Color(
			ACT_ONE_BASE_COLOR.r,
			ACT_ONE_BASE_COLOR.g,
			ACT_ONE_BASE_COLOR.b,
			0.08
		)
		_scaffold_material.emission = ACT_ONE_BASE_COLOR * 0.45
		_scaffold_material.emission_energy_multiplier = 0.14

	if _edge_overlay_material != null:
		_edge_overlay_material.albedo_color = Color(
			ACT_ONE_EDGE_COLOR.r,
			ACT_ONE_EDGE_COLOR.g,
			ACT_ONE_EDGE_COLOR.b,
			0.52
		)
		_edge_overlay_material.emission = ACT_ONE_EDGE_COLOR
		_edge_overlay_material.emission_energy_multiplier = 0.95

	if _static_edge_overlay_material != null:
		var scaffold_color := Color(0.24, 0.24, 0.24, 0.24)
		_static_edge_overlay_material.albedo_color = scaffold_color
		_static_edge_overlay_material.emission = scaffold_color
		_static_edge_overlay_material.emission_energy_multiplier = 0.3


func _apply_stage(stage_index: int, animate_focus: bool) -> void:
	_current_stage_index = clampi(stage_index, 0, _stage_data.size() - 1)
	_selected_route_ids.clear()
	_drag_active = false
	_drag_anchor_cell_id = -1
	_hover_cell_id = -1
	_hover_hold_elapsed = 0.0
	_drag_grace_left = 0.0

	var stage := _stage_data[_current_stage_index]
	_current_stage_core_lookup = {}
	for cell_id_variant in stage.get("core_cells", []):
		_current_stage_core_lookup[int(cell_id_variant)] = true

	_current_stage_route_ids = _derive_route_from_core(stage.get("core_cells", []))
	_current_stage_route_ids = _reorder_route_for_focus(
		_current_stage_route_ids,
		float(stage.get("focus_yaw_deg", 0.0)),
		float(stage.get("focus_pitch_deg", -18.0))
	)
	_current_stage_height_map = _build_stage_height_map(stage)
	_current_preview_uvs = _sample_closed_template(
		stage.get("preview_template", PackedVector2Array()) as PackedVector2Array,
		_current_stage_route_ids.size()
	)

	_apply_base_goldberg_visual()
	_rebuild_cell_geometry()
	_refresh_stage_labels()
	_refresh_route_preview()
	_refresh_cell_materials()
	_set_status_text("按住鼠标，从高亮单元开始连续拖拽整条回路。")
	_apply_focus_rotation(
		float(stage.get("focus_yaw_deg", 0.0)),
		float(stage.get("focus_pitch_deg", -18.0)),
		animate_focus
	)


func _derive_route_from_core(core_cells_variant: Variant) -> Array[int]:
	var core_cells: Array[int] = []
	for cell_id_variant in core_cells_variant:
		core_cells.append(int(cell_id_variant))
	if core_cells.is_empty():
		return []

	var core_lookup: Dictionary = {}
	for cell_id in core_cells:
		core_lookup[cell_id] = true

	var route_lookup: Dictionary = {}
	for cell_id in core_cells:
		var cell: Object = _cells_by_id.get(cell_id) as Object
		if cell == null:
			continue
		var neighbors: PackedInt32Array = cell.get("neighbors") as PackedInt32Array
		for neighbor_id in neighbors:
			var cast_id := int(neighbor_id)
			if not core_lookup.has(cast_id):
				route_lookup[cast_id] = true
	if route_lookup.is_empty():
		return []

	var centroid := Vector3.ZERO
	for route_id in route_lookup.keys():
		centroid += _get_cell_center(int(route_id))
	centroid /= float(route_lookup.size())

	var normal := centroid.normalized()
	if normal.length_squared() < 0.000001:
		for cell_id in core_cells:
			normal += _get_cell_normal(cell_id)
		if normal.length_squared() < 0.000001:
			normal = Vector3.UP
		else:
			normal = normal.normalized()

	var tangent := normal.cross(Vector3.UP)
	if tangent.length_squared() < 0.000001:
		tangent = normal.cross(Vector3.RIGHT)
	tangent = tangent.normalized()
	var bitangent := normal.cross(tangent).normalized()

	var sortable: Array[Dictionary] = []
	for route_id in route_lookup.keys():
		var center := _get_cell_center(int(route_id))
		var projected := center - normal * center.dot(normal)
		var angle := atan2(projected.dot(bitangent), projected.dot(tangent))
		sortable.append({
			"id": int(route_id),
			"angle": angle,
		})
	sortable.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["angle"]) < float(b["angle"])
	)

	var route: Array[int] = []
	for entry in sortable:
		route.append(int(entry["id"]))

	var valid := true
	for i in range(route.size()):
		var current_id := route[i]
		var next_id := route[(i + 1) % route.size()]
		if not _are_cells_neighbors(current_id, next_id):
			valid = false
			break
	if not valid:
		push_warning("Derived route is not a closed neighbor loop for stage %d." % _current_stage_index)
	return route


func _reorder_route_for_focus(route: Array[int], target_yaw_deg: float, target_pitch_deg: float) -> Array[int]:
	if route.size() <= 1:
		return route

	var basis := Basis.from_euler(Vector3(deg_to_rad(target_pitch_deg), deg_to_rad(target_yaw_deg), 0.0))
	var best_index := 0
	var best_score := -INF
	for i in range(route.size()):
		var rotated_center := basis * _get_cell_center(route[i])
		var score := rotated_center.z + rotated_center.y * 0.18
		if score > best_score:
			best_score = score
			best_index = i

	var forward_route: Array[int] = []
	var reverse_route: Array[int] = []
	for offset in range(route.size()):
		forward_route.append(route[(best_index + offset) % route.size()])
		reverse_route.append(route[posmod(best_index - offset, route.size())])

	var forward_score := _get_route_follow_visibility_score(forward_route, basis)
	var reverse_score := _get_route_follow_visibility_score(reverse_route, basis)
	return forward_route if forward_score >= reverse_score else reverse_route


func _get_route_follow_visibility_score(route: Array[int], basis: Basis) -> float:
	if route.size() < 2:
		return 0.0
	var first := basis * _get_cell_center(route[0])
	var second := basis * _get_cell_center(route[1])
	return first.z * 1.5 + second.z * 0.8 + second.x * 0.08


func _build_stage_height_map(stage: Dictionary) -> Dictionary:
	var height_map: Dictionary = {}
	var core_cells: Array[int] = []
	for cell_id_variant in stage.get("core_cells", []):
		core_cells.append(int(cell_id_variant))
	var core_distance_map := _build_distance_map(core_cells)
	var route_lookup: Dictionary = {}
	for cell_id in _current_stage_route_ids:
		route_lookup[cell_id] = true

	var axis := stage.get("noise_axis", Vector3.UP) as Vector3
	if axis.length_squared() < 0.000001:
		axis = Vector3.UP
	axis = axis.normalized()

	var pattern := String(stage.get("pattern", STAGE_PATTERN_RINGS))
	for cell_id_variant in _cells_by_id.keys():
		var cell_id := int(cell_id_variant)
		var dist := int(core_distance_map.get(cell_id, 999))
		var axis_wave := _get_cell_normal(cell_id).dot(axis)
		var cell_hash := _hash_cell(cell_id)
		var height := -0.03

		match pattern:
			STAGE_PATTERN_RINGS:
				height = -0.055 + axis_wave * 0.01
				if dist == 0:
					height = 0.18
				elif route_lookup.has(cell_id):
					height = 0.055
				elif dist == 2:
					height = 0.01
				elif dist == 3:
					height = -0.015
			STAGE_PATTERN_CRACK:
				height = -0.045 - minf(float(dist), 5.0) * 0.012 + (cell_hash - 0.5) * 0.025
				if dist == 0:
					height = -0.17
				elif route_lookup.has(cell_id):
					height = 0.032
				elif dist == 1:
					height = -0.082
			STAGE_PATTERN_FACETS:
				height = clampf(axis_wave * 0.055 + (cell_hash - 0.5) * 0.035 - minf(float(dist), 4.0) * 0.012, -0.09, 0.09)
				if dist == 0:
					height = 0.14
				elif route_lookup.has(cell_id):
					height = 0.012 + axis_wave * 0.018

		height_map[cell_id] = height

	return height_map


func _build_distance_map(seed_ids: Array[int]) -> Dictionary:
	var distance_map: Dictionary = {}
	var queue: Array[int] = []
	for cell_id in seed_ids:
		if distance_map.has(cell_id):
			continue
		distance_map[cell_id] = 0
		queue.append(cell_id)

	var read_index := 0
	while read_index < queue.size():
		var current_id := queue[read_index]
		read_index += 1
		var current_distance := int(distance_map.get(current_id, 0))
		var cell: Object = _cells_by_id.get(current_id) as Object
		if cell == null:
			continue
		var neighbors: PackedInt32Array = cell.get("neighbors") as PackedInt32Array
		for neighbor_id in neighbors:
			var cast_id := int(neighbor_id)
			if distance_map.has(cast_id):
				continue
			distance_map[cast_id] = current_distance + 1
			queue.append(cast_id)

	return distance_map


func _rebuild_cell_geometry() -> void:
	if _cell_root != null and is_instance_valid(_cell_root):
		_cell_root.free()
	_cell_root = Node3D.new()
	_cell_root.name = "CellRoot"
	sphere.add_child(_cell_root)

	_cell_nodes.clear()
	_cell_materials.clear()
	_cell_runtime_data.clear()

	var sorted_ids := _cells_by_id.keys()
	sorted_ids.sort()
	for cell_id_variant in sorted_ids:
		var cell_id := int(cell_id_variant)
		var cell: Object = _cells_by_id.get(cell_id) as Object
		if cell == null:
			continue

		var normal := cell.get("normal") as Vector3
		var base_center_original := cell.get("center") as Vector3
		var apex_original := cell.get("mesh_center") as Vector3
		var polygon_original := cell.get("polygon") as PackedVector3Array
		var offset := normal * float(_current_stage_height_map.get(cell_id, 0.0))

		var base_center := base_center_original + offset
		var apex := base_center + (apex_original - base_center_original) * cone_depth_scale
		var hit_scale := maxf(cell_hit_scale, cell_face_inset)
		var render_offset := normal * cell_surface_offset
		var render_base_center := base_center + render_offset
		var inset_polygon := PackedVector3Array()
		var render_polygon := PackedVector3Array()
		var hit_polygon := PackedVector3Array()
		for point in polygon_original:
			var shifted := point + offset
			var inset_point := base_center + (shifted - base_center) * cell_face_inset
			inset_polygon.append(inset_point)
			render_polygon.append(inset_point + render_offset)
			hit_polygon.append(base_center + (shifted - base_center) * hit_scale)

		var cell_node := MeshInstance3D.new()
		cell_node.name = "Cell_%d" % cell_id
		cell_node.mesh = _build_cell_mesh(render_base_center, apex, render_polygon)
		cell_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

		var material := StandardMaterial3D.new()
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		material.roughness = 0.52
		material.metallic = 0.0
		material.emission_enabled = true
		cell_node.material_override = material

		_cell_root.add_child(cell_node)
		_cell_nodes[cell_id] = cell_node
		_cell_materials[cell_id] = material
		_cell_runtime_data[cell_id] = {
			"base_center": base_center,
			"apex": apex,
			"polygon": inset_polygon,
			"hit_polygon": hit_polygon,
			"normal": normal,
		}


func _build_cell_mesh(base_center: Vector3, apex: Vector3, polygon: PackedVector3Array) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	if polygon.size() < 3:
		return st.commit()

	for i in range(polygon.size()):
		_append_triangle(st, base_center, polygon[i], polygon[(i + 1) % polygon.size()])

	for i in range(polygon.size()):
		_append_triangle(st, apex, polygon[(i + 1) % polygon.size()], polygon[i])

	return st.commit()


func _append_triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var normal := (b - a).cross(c - a)
	if normal.length_squared() < 0.000001:
		return

	var triangle_center := (a + b + c) / 3.0
	if normal.dot(triangle_center) < 0.0:
		var swap := b
		b = c
		c = swap
		normal = (b - a).cross(c - a)
		if normal.length_squared() < 0.000001:
			return

	normal = normal.normalized()

	st.set_normal(normal)
	st.add_vertex(a)
	st.set_normal(normal)
	st.add_vertex(b)
	st.set_normal(normal)
	st.add_vertex(c)


func _refresh_cell_materials() -> void:
	var stage := _stage_data[_current_stage_index]
	var route_lookup: Dictionary = {}
	for cell_id in _current_stage_route_ids:
		route_lookup[cell_id] = true

	var target_id := _get_current_target_cell_id()
	for cell_id_variant in _cell_materials.keys():
		var cell_id := int(cell_id_variant)
		var material := _cell_materials.get(cell_id) as StandardMaterial3D
		if material == null:
			continue

		var height := float(_current_stage_height_map.get(cell_id, 0.0))
		var height_lerp := inverse_lerp(-0.18, 0.18, height)
		var low_color := stage.get("low_color", Color(0.2, 0.2, 0.2, 1.0)) as Color
		var high_color := stage.get("high_color", Color(0.8, 0.8, 0.8, 1.0)) as Color
		var route_color := stage.get("route_color", Color(0.9, 0.9, 0.9, 1.0)) as Color
		var selected_color := stage.get("selected_color", Color(1.0, 1.0, 1.0, 1.0)) as Color
		var target_color := stage.get("target_color", Color(0.9, 0.9, 0.9, 1.0)) as Color

		var color := low_color.lerp(high_color, clampf(height_lerp, 0.0, 1.0))
		color = color.lerp(ACT_ONE_BASE_COLOR, 0.42)
		if route_lookup.has(cell_id):
			color = color.lerp(route_color, 0.22)
		if _current_stage_core_lookup.has(cell_id):
			color = color.darkened(0.05)

		var emission := Color.BLACK
		var emission_energy := 0.0

		if _selected_route_ids.has(cell_id):
			color = selected_color
			emission = selected_color
			emission_energy = 1.25
		elif cell_id == target_id:
			color = target_color
			emission = target_color
			emission_energy = 0.92
		elif _hover_cell_id == cell_id and _drag_active:
			color = target_color.lerp(selected_color, clampf(_hover_hold_elapsed / maxf(0.001, cell_hold_sec), 0.0, 1.0))
			emission = target_color
			emission_energy = 0.7
		elif route_lookup.has(cell_id):
			emission = route_color
			emission_energy = 0.14

		material.albedo_color = color
		material.emission = emission
		material.emission_energy_multiplier = emission_energy


func _refresh_stage_labels() -> void:
	var stage := _stage_data[_current_stage_index]
	_panel_backdrop.color = stage.get("panel_color", Color(0.15, 0.15, 0.15, 1.0)) as Color
	_stage_badge_label.text = "场景 %d / %d" % [_current_stage_index + 1, _stage_data.size()]
	_title_label.text = String(stage.get("title", ""))
	_desc_label.text = String(stage.get("subtitle", ""))
	_hint_label.text = "WASD 旋转结构，按住鼠标连续拖拽整条回路。"
	_progress_label.text = "回路进度 %d / %d" % [_selected_route_ids.size(), _current_stage_route_ids.size()]
	_stage_badge_label.text = "Scene %d / %d" % [_current_stage_index + 1, _stage_data.size()]
	_hint_label.text = "WASD rotate. Hold LMB and trace the full loop."
	_progress_label.text = "Loop progress %d / %d" % [_selected_route_ids.size(), _current_stage_route_ids.size()]
	line_canvas.line_color = stage.get("selected_color", Color.WHITE) as Color


func _set_status_text(text: String) -> void:
	if _status_label != null:
		_status_label.text = text


func _try_begin_drag() -> void:
	if _transition_running:
		return
	if not left_3d.get_global_rect().has_point(_latest_mouse_pos):
		return

	var target_id := _get_current_target_cell_id()
	if target_id < 0:
		return

	var picked_id := _pick_cell_at_screen_position(_latest_mouse_pos, [target_id])
	if picked_id != target_id:
		_set_status_text("从当前发亮的起始单元开始。")
		return

	_drag_active = true
	_drag_anchor_cell_id = picked_id
	_hover_cell_id = picked_id
	_hover_hold_elapsed = 0.0
	_drag_grace_left = drag_grace_sec
	_set_status_text("保持按住，沿着回路连续拖过去。")
	_set_status_text("Keep holding and continue into the next cell.")
	_refresh_cell_materials()
	get_viewport().set_input_as_handled()


func _update_drag_progress(delta: float) -> void:
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_cancel_drag("描摹中断，已重置。")
		return

	var target_id := _get_current_target_cell_id()
	if target_id < 0:
		return

	var anchor_id := _get_drag_anchor_cell_id()
	var picked_id := _pick_cell_at_screen_position(_latest_mouse_pos, [target_id, anchor_id])
	if picked_id == target_id:
		if _hover_cell_id != picked_id:
			_hover_cell_id = picked_id
			_hover_hold_elapsed = 0.0
			_refresh_cell_materials()
		_hover_hold_elapsed += delta
		_drag_grace_left = drag_grace_sec
		if _hover_hold_elapsed >= cell_hold_sec:
			_commit_current_target_cell()
		return

	if picked_id == anchor_id and anchor_id >= 0:
		if _hover_cell_id != -1:
			_hover_cell_id = -1
			_hover_hold_elapsed = 0.0
			_refresh_cell_materials()
		_drag_grace_left = drag_grace_sec
		return

	if _hover_cell_id != -1:
		_hover_cell_id = -1
		_hover_hold_elapsed = 0.0
		_refresh_cell_materials()
	_drag_grace_left -= delta
	if _drag_grace_left <= 0.0:
		var reason := "光标离开回路，已重置。"
		if picked_id != -1:
			reason = "走错单元，已重置。"
		_cancel_drag(reason)


func _commit_current_target_cell() -> void:
	var target_id := _get_current_target_cell_id()
	if target_id < 0:
		return

	_selected_route_ids.append(target_id)
	_drag_anchor_cell_id = target_id
	_hover_cell_id = -1
	_hover_hold_elapsed = 0.0
	_drag_grace_left = drag_grace_sec
	_refresh_stage_labels()
	_refresh_route_preview()
	_refresh_cell_materials()

	if _selected_route_ids.size() >= _current_stage_route_ids.size():
		_drag_active = false
		_transition_running = true
		_set_status_text("回路完成。")
		_set_status_text("Loop complete.")
		call_deferred("_complete_current_stage")


func _cancel_drag(reason: String) -> void:
	_drag_active = false
	_drag_anchor_cell_id = -1
	_hover_cell_id = -1
	_hover_hold_elapsed = 0.0
	_drag_grace_left = 0.0
	_selected_route_ids.clear()
	_refresh_stage_labels()
	_refresh_route_preview()
	_refresh_cell_materials()
	_set_status_text(reason)


func _complete_current_stage() -> void:
	_refresh_route_preview()
	_refresh_cell_materials()
	await get_tree().create_timer(0.18).timeout

	var next_stage_index := _current_stage_index + 1
	if next_stage_index < _stage_data.size():
		await _play_hand_wipe_to_stage(next_stage_index)
		_transition_running = false
		return

	await _play_final_hand_wipe()
	_transition_running = false
	if not _chapter_completed_once:
		_chapter_completed_once = true
		chapter_completed.emit(chapter_index)


func _play_hand_wipe_to_stage(next_stage_index: int) -> void:
	_hand_rect.visible = true
	_place_hand_at_start()

	var panel_size := right_panel.size
	var mid_pos := Vector2(panel_size.x * 0.12, panel_size.y * 0.06)
	var exit_pos := Vector2(-panel_size.x * 0.52, panel_size.y * 0.36)

	var first_tween := create_tween()
	first_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	first_tween.tween_property(_hand_rect, "position", mid_pos, hand_wipe_duration_sec * 0.48)
	first_tween.parallel().tween_property(_hand_rect, "rotation_degrees", 22.0, hand_wipe_duration_sec * 0.48)
	await first_tween.finished

	_apply_stage(next_stage_index, true)
	_set_status_text("Hand04 擦拭完成，进入下一张贴图。")

	var second_tween := create_tween()
	second_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	second_tween.tween_property(_hand_rect, "position", exit_pos, hand_wipe_duration_sec * 0.52)
	second_tween.parallel().tween_property(_hand_rect, "rotation_degrees", 68.0, hand_wipe_duration_sec * 0.52)
	await second_tween.finished

	_hand_rect.visible = false


func _play_final_hand_wipe() -> void:
	_hand_rect.visible = true
	_place_hand_at_start()

	var panel_size := right_panel.size
	var exit_pos := Vector2(-panel_size.x * 0.5, panel_size.y * 0.26)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_hand_rect, "position", exit_pos, hand_wipe_duration_sec)
	tween.parallel().tween_property(_hand_rect, "rotation_degrees", 64.0, hand_wipe_duration_sec)
	await tween.finished

	_hand_rect.visible = false
	_set_status_text("三段回路完成，准备进入下一关。")


func _place_hand_at_start() -> void:
	var panel_size := right_panel.size
	_hand_rect.size = Vector2(panel_size.x * 0.62, panel_size.y * 0.82)
	_hand_rect.pivot_offset = _hand_rect.size * 0.5
	_hand_rect.position = Vector2(panel_size.x * 1.02, -panel_size.y * 0.12)
	_hand_rect.rotation_degrees = -28.0


func _refresh_route_preview() -> void:
	if _current_preview_uvs.is_empty() or _selected_route_ids.is_empty():
		line_canvas.clear_lines()
		return

	var pixel_points := _preview_points_to_pixels(_current_preview_uvs)
	var active_points := PackedVector2Array()
	for i in range(_selected_route_ids.size()):
		if i >= pixel_points.size():
			break
		active_points.append(pixel_points[i])

	var closed := _selected_route_ids.size() == _current_stage_route_ids.size()
	line_canvas.set_line_points(active_points, closed, 6.0)


func _sample_closed_template(template: PackedVector2Array, sample_count: int) -> PackedVector2Array:
	if template.size() < 2 or sample_count <= 0:
		return PackedVector2Array()

	var segment_lengths: Array[float] = []
	var total_length := 0.0
	for i in range(template.size()):
		var length := template[i].distance_to(template[(i + 1) % template.size()])
		segment_lengths.append(length)
		total_length += length

	if total_length <= 0.000001:
		return PackedVector2Array()

	var result := PackedVector2Array()
	for sample_index in range(sample_count):
		var target_distance := total_length * float(sample_index) / float(sample_count)
		var accumulated := 0.0
		for segment_index in range(segment_lengths.size()):
			var segment_length := segment_lengths[segment_index]
			if target_distance <= accumulated + segment_length or segment_index == segment_lengths.size() - 1:
				var from_point := template[segment_index]
				var to_point := template[(segment_index + 1) % template.size()]
				var local_distance := target_distance - accumulated
				var t := 0.0 if segment_length <= 0.000001 else local_distance / segment_length
				result.append(from_point.lerp(to_point, clampf(t, 0.0, 1.0)))
				break
			accumulated += segment_length

	return result


func _preview_points_to_pixels(uv_points: PackedVector2Array) -> PackedVector2Array:
	var pixel_points := PackedVector2Array()
	var canvas_size := line_canvas.size
	var pad_x := canvas_size.x * 0.14
	var pad_y := canvas_size.y * 0.16
	for uv in uv_points:
		pixel_points.append(Vector2(
			lerpf(pad_x, canvas_size.x - pad_x, uv.x),
			lerpf(pad_y, canvas_size.y - pad_y, uv.y)
		))
	return pixel_points


func _pick_cell_at_screen_position(screen_pos: Vector2, preferred_ids: Array[int] = []) -> int:
	var container_rect := left_3d.get_global_rect()
	if not container_rect.has_point(screen_pos):
		return -1

	var viewport_pos := _screen_to_left_viewport_position(screen_pos, container_rect)
	var ray_origin_world := camera_3d.project_ray_origin(viewport_pos)
	var ray_dir_world := camera_3d.project_ray_normal(viewport_pos).normalized()

	var to_local := sphere.global_transform.affine_inverse()
	var ray_origin := to_local * ray_origin_world
	var ray_dir := (to_local.basis * ray_dir_world).normalized()

	var best_t := INF
	var best_cell_id := -1
	var preferred_hits: Dictionary = {}
	for cell_id_variant in _cell_runtime_data.keys():
		var cell_id := int(cell_id_variant)
		var hit_t := _ray_intersects_cell(ray_origin, ray_dir, _cell_runtime_data[cell_id])
		if hit_t < 0.0:
			continue
		if preferred_ids.has(cell_id):
			preferred_hits[cell_id] = hit_t
		if hit_t < best_t:
			best_t = hit_t
			best_cell_id = cell_id
	for preferred_id in preferred_ids:
		if preferred_hits.has(preferred_id):
			return int(preferred_id)
	return best_cell_id


func _ray_intersects_cell(ray_origin: Vector3, ray_dir: Vector3, cell_runtime: Dictionary) -> float:
	var base_center := cell_runtime.get("base_center", Vector3.ZERO) as Vector3
	var hit_polygon := cell_runtime.get("hit_polygon", PackedVector3Array()) as PackedVector3Array
	if hit_polygon.size() < 3:
		return -1.0

	var best_t := INF
	for i in range(hit_polygon.size()):
		var face_t := _ray_intersects_triangle(
			ray_origin,
			ray_dir,
			base_center,
			hit_polygon[i],
			hit_polygon[(i + 1) % hit_polygon.size()]
		)
		if face_t >= 0.0 and face_t < best_t:
			best_t = face_t

	return best_t if best_t < INF else -1.0


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


func _get_current_target_cell_id() -> int:
	return -1 if _selected_route_ids.size() >= _current_stage_route_ids.size() else _current_stage_route_ids[_selected_route_ids.size()]


func _get_drag_anchor_cell_id() -> int:
	if not _selected_route_ids.is_empty():
		return _selected_route_ids[_selected_route_ids.size() - 1]
	return _drag_anchor_cell_id


func _get_cell_center(cell_id: int) -> Vector3:
	var cell: Object = _cells_by_id.get(cell_id) as Object
	if cell == null:
		return Vector3.ZERO
	return cell.get("center") as Vector3


func _get_cell_normal(cell_id: int) -> Vector3:
	var cell: Object = _cells_by_id.get(cell_id) as Object
	if cell == null:
		return Vector3.UP
	return cell.get("normal") as Vector3


func _are_cells_neighbors(cell_a: int, cell_b: int) -> bool:
	var cell: Object = _cells_by_id.get(cell_a) as Object
	if cell == null:
		return false
	var neighbors: PackedInt32Array = cell.get("neighbors") as PackedInt32Array
	return neighbors.has(cell_b)


func _hash_cell(cell_id: int) -> float:
	var value := absf(sin(float(cell_id) * 12.9898 + 78.233) * 43758.5453)
	return value - floor(value)


func _update_rotation_input(delta: float) -> void:
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


func _apply_focus_rotation(target_yaw_deg: float, target_pitch_deg: float, animate: bool) -> void:
	_yaw_deg = target_yaw_deg
	_pitch_deg = target_pitch_deg
	sphere.rotation = Vector3(deg_to_rad(target_pitch_deg), deg_to_rad(target_yaw_deg), 0.0)


func _set_model_rotation_from_state() -> void:
	sphere.rotation = Vector3(deg_to_rad(_pitch_deg), deg_to_rad(_yaw_deg), 0.0)


func _sync_rotation_state_from_model() -> void:
	_pitch_deg = rad_to_deg(sphere.rotation.x)
	_yaw_deg = rad_to_deg(sphere.rotation.y)


func _on_chapter_1_split_dragged(_offset: int) -> void:
	_enforce_layout_constraints()


func _on_layout_changed() -> void:
	if not left_3d.stretch:
		left_viewport.size = Vector2i(maxi(1, int(left_3d.size.x)), maxi(1, int(left_3d.size.y)))
	_enforce_layout_constraints()
	_refresh_route_preview()
	if _hand_rect != null and _hand_rect.visible:
		_place_hand_at_start()


func _enforce_layout_constraints() -> void:
	var min_right_width := maxf(1.0, size.x * 0.5)
	right_panel.custom_minimum_size.x = min_right_width
	if chapter_1_split.split_offset > 0:
		chapter_1_split.split_offset = 0


func _unhandled_input(event: InputEvent) -> void:
	if _chapter_completed_once:
		return
	if _transition_running and event is InputEventMouseButton:
		get_viewport().set_input_as_handled()
