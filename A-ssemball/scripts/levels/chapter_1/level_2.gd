extends Control
class_name LevelC1L2

signal chapter_completed(chapter_index: int)

const StructureShapeProviderRef = preload("res://scripts/structure/structure_shape_provider.gd")
const RouteBurnMaskCanvas2DRef = preload("res://scripts/route_burn_mask_canvas_2d.gd")
const AshFragmentOverlay2DRef = preload("res://scripts/ash_fragment_overlay_2d.gd")
const ASH_DEPOSIT_TEXTURE: Texture2D = preload("res://assets/ui/chapter_1_stage_2/ash_deposit.jpg")
const HAND_TEXTURE: Texture2D = preload("res://assets/ui/chapter_1_stage_2/Hand04.png")
const SPHERE_CLICK_AUDIO: AudioStream = preload("res://assets/audio/单击球面音效.mp3")
const HAND_POINTER_TEXTURE_PATH := "res://assets/ui/chapter_1_stage_2/Hand06.png"
const POINTER_HAND_TIP_UV := Vector2(0.3716, 0.1141)
const POINTER_HAND_WRIST_UV := Vector2(0.5, 0.96)

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
const EDGE_WIDTH_FROM_LENGTH: float = 0.16
const EDGE_DEPTH_FROM_WIDTH: float = 0.42
const EDGE_MIN_RADIUS_RATIO: float = 0.008
const EDGE_MAX_RADIUS_RATIO: float = 0.045
const EDGE_SURFACE_LIFT_RATIO: float = 0.0025
const GOLDBERG_DYNAMIC_EDGE_WIDTH_SCALE: float = 1.0 / 3.0
const TRANSITION_LIFT_RADIUS: float = 1.5
const TRANSITION_LIFT_OUT_SEC: float = 3.2
const TRANSITION_FILM_SWITCH_SEC: float = 2.0
const TRANSITION_SETTLE_IN_SEC: float = 3.2

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
@export_range(0.12, 1.0, 0.01) var cell_hold_sec: float = 0.52
@export_range(0.0, 0.4, 0.01) var drag_grace_sec: float = 0.18
@export_range(0.2, 2.0, 0.05) var rollback_step_sec: float = 1.0
@export_range(0.05, 1.0, 0.01) var target_hint_fade_sec: float = 0.38
@export_range(0.75, 0.98, 0.01) var cell_face_inset: float = 0.9
@export_range(1.0, 1.08, 0.005) var cell_hit_scale: float = 1.02
@export_range(0.0, 0.03, 0.001) var cell_surface_offset: float = 0.004
@export_range(0.4, 1.2, 0.01) var cone_depth_scale: float = 0.86
@export_range(0.0, 0.06, 0.001) var texture_motion_amplitude: float = 0.022
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
var _cell_edge_nodes: Dictionary = {}
var _cell_edge_materials: Dictionary = {}
var _cell_runtime_data: Dictionary = {}

var _stage_data: Array[Dictionary] = []
var _current_stage_index: int = 0
var _current_stage_route_ids: Array[int] = []
var _current_stage_core_lookup: Dictionary = {}
var _current_stage_height_map: Dictionary = {}
var _current_preview_uvs: PackedVector2Array = PackedVector2Array()
var _current_route_guide_uvs: PackedVector2Array = PackedVector2Array()
var _current_route_guide_closed: bool = false

var _selected_route_ids: Array[int] = []
var _drag_active: bool = false
var _drag_anchor_cell_id: int = -1
var _hover_cell_id: int = -1
var _hover_hold_elapsed: float = 0.0
var _charging_cell_id: int = -1
var _charge_elapsed: float = 0.0
var _charge_start_hint_t: float = 1.0
var _drag_grace_left: float = 0.0
var _rollback_active: bool = false
var _rollback_elapsed: float = 0.0
var _rollback_fading_cell_id: int = -1
var _rollback_fading_committed: bool = true
var _rollback_fading_charge_t: float = 1.0
var _rollback_fading_hint_t: float = 1.0
var _target_hint_elapsed: float = 0.0
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
var _stage_elapsed: float = 0.0

var _panel_root: Control
var _panel_backdrop: ColorRect
var _stage_image_rect: TextureRect
var _stage_image_material: ShaderMaterial
var _stage_image_next_rect: TextureRect
var _stage_image_wipe_material: ShaderMaterial
var _stage_image_burn_material: ShaderMaterial
var _transition_flash_rect: ColorRect
var _transition_flash_material: ShaderMaterial
var _film_overlay_rect: ColorRect
var _film_overlay_material: ShaderMaterial
var _burn_heat_rect: ColorRect
var _burn_heat_material: ShaderMaterial
var _ash_fragment_overlay
var _suppress_stage_image_refresh: bool = false
var _stage_badge_label: Label
var _title_label: Label
var _desc_label: Label
var _progress_label: Label
var _hint_label: Label
var _status_label: Label
var _hand_rect: TextureRect
var _pointer_hand_rect: TextureRect
var _route_guide_canvas: LineCanvas2D
var _route_burn_canvas
var _pointer_hand_target_pos: Vector2 = Vector2.ZERO
var _pointer_hand_visible_target: bool = false
var _pointer_hand_alpha: float = 0.0
var _pointer_hand_enter_t: float = 0.0
var _hand_pointer_texture: Texture2D
var _hand_pointer_material: ShaderMaterial
var _transition_lift_offsets: Dictionary = {}
var _transition_color_flash_strength: float = 0.0
var _transition_burn_progress: float = 0.0
var _transition_burn_route_points: PackedVector2Array = PackedVector2Array()
var _transition_burn_route_closed: bool = false
var _sphere_click_audio_player: AudioStreamPlayer


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
	_ensure_audio_players()
	sphere.rotation = Vector3.ZERO

	resized.connect(_on_layout_changed)
	left_3d.resized.connect(_on_layout_changed)
	chapter_1_split.dragged.connect(_on_chapter_1_split_dragged)
	_on_layout_changed()
	_apply_stage(0, false)


func _process(delta: float) -> void:
	_stage_elapsed += delta
	if not _transition_running and not _rollback_active and _charging_cell_id < 0:
		_target_hint_elapsed += delta
		_refresh_cell_materials()
	_update_rotation_input(delta)
	if _drag_active and not _transition_running:
		_update_drag_progress(delta)
	if _rollback_active and not _transition_running:
		_update_rollback(delta)
	if _drag_active or _rollback_active:
		_refresh_route_preview()
	_update_pointer_hand(delta)
	_update_texture_surface_motion()
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
			if _rollback_active:
				_try_resume_rollback()
				return
			_try_begin_drag()
		elif _drag_active:
			_start_rollback("描摹中断，路径开始回撤。")
			get_viewport().set_input_as_handled()


func _build_stage_data() -> Array[Dictionary]:
	return [
		{
			"title": "树木年轮",
			"subtitle": "沿着绿色参考标出的年轮主纹理描摹",
			"image_path": "res://assets/ui/chapter_1_stage_2/wood_rings.jpg",
			"pattern": STAGE_PATTERN_RINGS,
			"core_cells": [0],
			"focus_yaw_deg": 0.0,
			"focus_pitch_deg": -18.0,
			"low_color": Color(0.16, 0.09, 0.045, 1.0),
			"high_color": Color(0.74, 0.42, 0.18, 1.0),
			"route_color": Color(0.98, 0.72, 0.28, 1.0),
			"selected_color": Color(1.0, 0.92, 0.54, 1.0),
			"target_color": Color(1.0, 0.82, 0.34, 1.0),
			"panel_color": Color(0.04, 0.05, 0.08, 1.0),
			"panel_tint": Color(0.02, 0.018, 0.014, 0.22),
			"noise_axis": Vector3(0.0, 1.0, 0.2).normalized(),
			"route_closed": false,
			"route_span": 0.62,
			"left_route_count": 16,
			"left_route_scale": Vector2(0.74, 0.9),
			"left_route_offset": Vector2(0.03, 0.02),
			"preview_template": PackedVector2Array([
				Vector2(0.376, 0.007),
				Vector2(0.527, 0.076),
				Vector2(0.635, 0.154),
				Vector2(0.695, 0.230),
				Vector2(0.738, 0.307),
				Vector2(0.774, 0.383),
				Vector2(0.793, 0.461),
				Vector2(0.805, 0.537),
				Vector2(0.805, 0.615),
				Vector2(0.783, 0.691),
				Vector2(0.745, 0.769),
				Vector2(0.703, 0.845),
				Vector2(0.627, 0.922),
				Vector2(0.560, 0.991),
			]),
		},
		{
			"title": "干涸的大地",
			"subtitle": "沿着绿色参考标出的裂缝主纹理描摹",
			"image_path": "res://assets/ui/chapter_1_stage_2/dry_soil.jpg",
			"pattern": STAGE_PATTERN_CRACK,
			"core_cells": [58, 59, 60, 61],
			"focus_yaw_deg": -16.0,
			"focus_pitch_deg": -22.0,
			"low_color": Color(0.045, 0.04, 0.035, 1.0),
			"high_color": Color(0.55, 0.43, 0.31, 1.0),
			"route_color": Color(0.76, 0.86, 0.78, 1.0),
			"selected_color": Color(0.92, 0.98, 0.82, 1.0),
			"target_color": Color(0.78, 0.95, 0.76, 1.0),
			"panel_color": Color(0.04, 0.05, 0.08, 1.0),
			"panel_tint": Color(0.02, 0.02, 0.018, 0.20),
			"noise_axis": Vector3(0.35, 0.92, -0.18).normalized(),
			"route_closed": false,
			"route_span": 0.72,
			"left_route_count": 18,
			"left_route_scale": Vector2(0.9, 1.0),
			"left_route_offset": Vector2(0.0, 0.0),
			"preview_template": PackedVector2Array([
				Vector2(0.00, 0.00),
				Vector2(0.01, 0.08),
				Vector2(0.04, 0.18),
				Vector2(0.15, 0.22),
				Vector2(0.30, 0.19),
				Vector2(0.48, 0.16),
				Vector2(0.68, 0.17),
				Vector2(0.83, 0.24),
				Vector2(0.92, 0.35),
				Vector2(0.94, 0.47),
				Vector2(0.85, 0.53),
				Vector2(0.78, 0.64),
				Vector2(0.74, 0.74),
				Vector2(0.66, 0.83),
				Vector2(0.65, 0.93),
				Vector2(0.68, 1.00),
			]),
		},
		{
			"title": "岩石",
			"subtitle": "沿着绿色参考标出的岩层纹理描摹",
			"image_path": "res://assets/ui/chapter_1_stage_2/rock.png",
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
			"panel_tint": Color(0.04, 0.05, 0.08, 0.88),
			"noise_axis": Vector3(0.9, -0.2, 0.36).normalized(),
			"route_closed": false,
			"route_span": 0.78,
			"left_route_count": 20,
			"left_route_scale": Vector2(0.92, 0.82),
			"left_route_offset": Vector2(0.0, -0.03),
			"preview_template": PackedVector2Array([
				Vector2(0.005, 0.535),
				Vector2(0.053, 0.561),
				Vector2(0.105, 0.583),
				Vector2(0.158, 0.597),
				Vector2(0.211, 0.606),
				Vector2(0.262, 0.611),
				Vector2(0.315, 0.595),
				Vector2(0.368, 0.542),
				Vector2(0.420, 0.445),
				Vector2(0.473, 0.342),
				Vector2(0.526, 0.301),
				Vector2(0.579, 0.271),
				Vector2(0.630, 0.259),
				Vector2(0.683, 0.249),
				Vector2(0.736, 0.247),
				Vector2(0.788, 0.249),
				Vector2(0.841, 0.250),
				Vector2(0.894, 0.244),
				Vector2(0.946, 0.204),
				Vector2(0.993, 0.149),
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

	_stage_image_rect = TextureRect.new()
	_stage_image_rect.name = "TextureImage"
	_stage_image_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stage_image_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage_image_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_stage_image_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_stage_image_material = _create_film_material()
	_stage_image_rect.material = _stage_image_material
	_panel_root.add_child(_stage_image_rect)

	_stage_image_next_rect = TextureRect.new()
	_stage_image_next_rect.name = "TextureImageWipeNext"
	_stage_image_next_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stage_image_next_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage_image_next_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_stage_image_next_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_stage_image_next_rect.visible = false
	_stage_image_wipe_material = _create_wipe_material()
	_stage_image_next_rect.material = _stage_image_wipe_material
	_panel_root.add_child(_stage_image_next_rect)
	_panel_root.move_child(_stage_image_next_rect, 0)
	_stage_image_burn_material = _create_burn_reveal_material()

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
	_stage_badge_label.visible = false
	_stage_badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stage_badge_label.add_theme_font_size_override("font_size", 18)
	layout.add_child(_stage_badge_label)

	var spacer_top := Control.new()
	spacer_top.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(spacer_top)

	_title_label = Label.new()
	_title_label.visible = false
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_label.add_theme_font_size_override("font_size", 34)
	layout.add_child(_title_label)

	_desc_label = Label.new()
	_desc_label.visible = false
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
	_progress_label.visible = false
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_progress_label.add_theme_font_size_override("font_size", 18)
	layout.add_child(_progress_label)

	_hint_label = Label.new()
	_hint_label.visible = false
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_label.add_theme_font_size_override("font_size", 18)
	layout.add_child(_hint_label)

	_status_label = Label.new()
	_status_label.visible = false
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

	_pointer_hand_rect = TextureRect.new()
	_pointer_hand_rect.name = "TracingHand"
	_pointer_hand_rect.texture = _load_pointer_hand_texture()
	_hand_pointer_material = _create_pointer_hand_material()
	_pointer_hand_rect.material = _hand_pointer_material
	_pointer_hand_rect.visible = false
	_pointer_hand_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pointer_hand_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_pointer_hand_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	right_panel.add_child(_pointer_hand_rect)

	_route_guide_canvas = LineCanvas2D.new()
	_route_guide_canvas.name = "TextureRouteGuide"
	_route_guide_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right_panel.add_child(_route_guide_canvas)

	line_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	line_canvas.offset_left = 0.0
	line_canvas.offset_top = 0.0
	line_canvas.offset_right = 0.0
	line_canvas.offset_bottom = 0.0
	line_canvas.line_shadow_color = Color(0.86, 0.84, 0.76, 0.16)
	line_canvas.line_shadow_extra_width = 2.6
	line_canvas.rough_pencil = true
	line_canvas.particle_enabled = true
	_route_guide_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_route_guide_canvas.offset_left = 0.0
	_route_guide_canvas.offset_top = 0.0
	_route_guide_canvas.offset_right = 0.0
	_route_guide_canvas.offset_bottom = 0.0
	_route_guide_canvas.rough_pencil = true
	_route_guide_canvas.particle_enabled = false
	_route_guide_canvas.visible = false
	line_canvas.move_to_front()
	_pointer_hand_rect.move_to_front()
	_hand_rect.move_to_front()

	_transition_flash_rect = ColorRect.new()
	_transition_flash_rect.name = "TextureTransitionExposure"
	_transition_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_transition_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_flash_rect.color = Color.WHITE
	_transition_flash_rect.visible = false
	_transition_flash_material = _create_transition_flash_material()
	_transition_flash_rect.material = _transition_flash_material
	right_panel.add_child(_transition_flash_rect)
	_transition_flash_rect.move_to_front()

	_film_overlay_rect = ColorRect.new()
	_film_overlay_rect.name = "FilmProjectionOverlay"
	_film_overlay_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_film_overlay_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_film_overlay_rect.color = Color.WHITE
	_film_overlay_material = _create_film_overlay_material()
	_film_overlay_rect.material = _film_overlay_material
	right_panel.add_child(_film_overlay_rect)
	_film_overlay_rect.move_to_front()

	_burn_heat_rect = ColorRect.new()
	_burn_heat_rect.name = "TextureBurnHeatOverlay"
	_burn_heat_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_burn_heat_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_burn_heat_rect.color = Color.WHITE
	_burn_heat_rect.visible = false
	_burn_heat_material = _create_burn_heat_overlay_material()
	_burn_heat_rect.material = _burn_heat_material
	right_panel.add_child(_burn_heat_rect)
	_burn_heat_rect.move_to_front()

	_route_burn_canvas = RouteBurnMaskCanvas2DRef.new()
	_route_burn_canvas.name = "TextureRouteBurnMask"
	_route_burn_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_route_burn_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_route_burn_canvas.offset_left = 0.0
	_route_burn_canvas.offset_top = 0.0
	_route_burn_canvas.offset_right = 0.0
	_route_burn_canvas.offset_bottom = 0.0
	_route_burn_canvas.visible = false
	right_panel.add_child(_route_burn_canvas)
	_route_burn_canvas.move_to_front()

	_ash_fragment_overlay = AshFragmentOverlay2DRef.new()
	_ash_fragment_overlay.name = "AshFragmentOverlay"
	_ash_fragment_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ash_fragment_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ash_fragment_overlay.offset_left = 0.0
	_ash_fragment_overlay.offset_top = 0.0
	_ash_fragment_overlay.offset_right = 0.0
	_ash_fragment_overlay.offset_bottom = 0.0
	_ash_fragment_overlay.visible = false
	_ash_fragment_overlay.set_ash_texture(ASH_DEPOSIT_TEXTURE)
	right_panel.add_child(_ash_fragment_overlay)
	_ash_fragment_overlay.move_to_front()


func _create_film_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float saturation : hint_range(0.0, 1.0) = 0.22;
uniform float contrast : hint_range(0.2, 2.0) = 0.86;
uniform float lift : hint_range(0.0, 0.5) = 0.12;
uniform float fade : hint_range(0.0, 1.0) = 0.34;
uniform float grain_strength : hint_range(0.0, 0.2) = 0.065;
uniform float weave_strength : hint_range(0.0, 0.02) = 0.006;
uniform float flicker_strength : hint_range(0.0, 0.4) = 0.12;
uniform vec4 paper_tint : source_color = vec4(0.83, 0.75, 0.58, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
	float jump = step(0.93, hash(vec2(floor(TIME * 18.0), 18.41)));
	vec2 weave = vec2(
		sin(TIME * 2.2) * 0.55 + sin(TIME * 5.1 + 1.7) * 0.24,
		sin(TIME * 1.6 + 0.4) * 0.38 + jump * 2.8
	) * weave_strength;
	vec2 sample_uv = clamp(UV + weave, vec2(0.001), vec2(0.999));
	vec4 src = texture(TEXTURE, sample_uv);
	float luma = dot(src.rgb, vec3(0.299, 0.587, 0.114));
	vec3 grey = vec3(luma);
	vec3 color = mix(grey, src.rgb, saturation);
	color = (color - vec3(0.5)) * contrast + vec3(0.5);
	color = mix(color, paper_tint.rgb, fade);
	color = color + vec3(lift) * (1.0 - color);
	float shutter = sin(TIME * 38.0) * 0.5 + sin(TIME * 61.0 + 1.3) * 0.22;
	color *= 1.0 + shutter * flicker_strength;
	float grain = hash(UV * vec2(820.0, 960.0) + vec2(floor(TIME * 24.0), floor(TIME * 19.0))) - 0.5;
	color += grain * grain_strength;
	float frame_line = smoothstep(0.018, 0.0, abs(fract(UV.y * 2.0 + TIME * 0.18) - 0.018));
	color *= 1.0 - frame_line * 0.08;
	float vignette = smoothstep(0.98, 0.28, distance(UV, vec2(0.5)));
	color *= mix(0.74, 1.08, vignette);
	COLOR = vec4(clamp(color, vec3(0.0), vec3(1.0)), src.a);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	return material


func _create_wipe_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float reveal_progress : hint_range(0.0, 1.0) = 0.0;
uniform float soft_width : hint_range(0.0, 0.2) = 0.045;
uniform float saturation : hint_range(0.0, 1.0) = 0.22;
uniform float contrast : hint_range(0.2, 2.0) = 0.86;
uniform float lift : hint_range(0.0, 0.5) = 0.12;
uniform float fade : hint_range(0.0, 1.0) = 0.34;
uniform float grain_strength : hint_range(0.0, 0.2) = 0.065;
uniform float weave_strength : hint_range(0.0, 0.02) = 0.006;
uniform float flicker_strength : hint_range(0.0, 0.4) = 0.12;
uniform vec4 paper_tint : source_color = vec4(0.83, 0.75, 0.58, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
	float jump = step(0.93, hash(vec2(floor(TIME * 18.0), 18.41)));
	vec2 weave = vec2(
		sin(TIME * 2.2) * 0.55 + sin(TIME * 5.1 + 1.7) * 0.24,
		sin(TIME * 1.6 + 0.4) * 0.38 + jump * 2.8
	) * weave_strength;
	vec2 sample_uv = clamp(UV + weave, vec2(0.001), vec2(0.999));
	vec4 color = texture(TEXTURE, sample_uv);
	float luma = dot(color.rgb, vec3(0.299, 0.587, 0.114));
	vec3 grey = vec3(luma);
	vec3 film = mix(grey, color.rgb, saturation);
	film = (film - vec3(0.5)) * contrast + vec3(0.5);
	film = mix(film, paper_tint.rgb, fade);
	film = film + vec3(lift) * (1.0 - film);
	float shutter = sin(TIME * 38.0) * 0.5 + sin(TIME * 61.0 + 1.3) * 0.22;
	film *= 1.0 + shutter * flicker_strength;
	float grain = hash(UV * vec2(820.0, 960.0) + vec2(floor(TIME * 24.0), floor(TIME * 19.0))) - 0.5;
	film += grain * grain_strength;
	float frame_line = smoothstep(0.018, 0.0, abs(fract(UV.y * 2.0 + TIME * 0.18) - 0.018));
	film *= 1.0 - frame_line * 0.08;
	float vignette = smoothstep(0.98, 0.28, distance(UV, vec2(0.5)));
	film *= mix(0.74, 1.08, vignette);
	float alpha = 1.0 - smoothstep(reveal_progress, reveal_progress + soft_width, UV.x);
	COLOR = vec4(clamp(film, vec3(0.0), vec3(1.0)), color.a * alpha);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("reveal_progress", 0.0)
	material.set_shader_parameter("soft_width", 0.045)
	return material


func _create_burn_reveal_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float burn_progress : hint_range(0.0, 1.0) = 0.0;
uniform float edge_width : hint_range(0.01, 0.24) = 0.105;
uniform float char_width : hint_range(0.01, 0.3) = 0.15;
uniform vec2 origin_a = vec2(0.45, 0.5);
uniform vec2 origin_b = vec2(0.62, 0.42);
uniform vec2 origin_c = vec2(0.52, 0.58);
uniform vec2 origin_d = vec2(0.38, 0.55);
uniform vec2 origin_e = vec2(0.56, 0.47);
uniform vec2 origin_f = vec2(0.70, 0.38);
uniform vec2 origin_g = vec2(0.48, 0.64);
uniform vec4 hot_color : source_color = vec4(1.0, 0.72, 0.22, 1.0);
uniform vec4 ash_color : source_color = vec4(0.06, 0.035, 0.018, 1.0);
uniform vec4 paper_tint : source_color = vec4(0.83, 0.75, 0.58, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float burn_field(vec2 uv, vec2 origin, float radius, float stretch) {
	vec2 p = uv - origin;
	p.x *= stretch;
	float d = length(p);
	float coarse = noise(uv * 7.0 + vec2(TIME * 0.08, -TIME * 0.05));
	float fine = noise(uv * 34.0 + vec2(floor(TIME * 14.0), floor(TIME * 11.0)));
	float tear = sin((uv.y + coarse * 0.12) * 38.0 + TIME * 4.0) * 0.018;
	return radius - d + (coarse - 0.5) * 0.115 + (fine - 0.5) * 0.038 + tear;
}

vec3 film_grade(vec3 src, vec2 uv) {
	float luma = dot(src, vec3(0.299, 0.587, 0.114));
	vec3 color = mix(vec3(luma), src, 0.22);
	color = (color - vec3(0.5)) * 0.86 + vec3(0.5);
	color = mix(color, paper_tint.rgb, 0.34);
	color = color + vec3(0.12) * (1.0 - color);
	float shutter = sin(TIME * 38.0) * 0.5 + sin(TIME * 61.0 + 1.3) * 0.22;
	color *= 1.0 + shutter * 0.12;
	float grain = hash(uv * vec2(820.0, 960.0) + vec2(floor(TIME * 24.0), floor(TIME * 19.0))) - 0.5;
	color += grain * 0.065;
	float vignette = smoothstep(0.98, 0.28, distance(uv, vec2(0.5)));
	color *= mix(0.74, 1.08, vignette);
	return clamp(color, vec3(0.0), vec3(1.0));
}

void fragment() {
	float jump = step(0.93, hash(vec2(floor(TIME * 18.0), 18.41)));
	vec2 weave = vec2(
		sin(TIME * 2.2) * 0.55 + sin(TIME * 5.1 + 1.7) * 0.24,
		sin(TIME * 1.6 + 0.4) * 0.38 + jump * 2.8
	) * 0.006;
	vec2 sample_uv = clamp(UV + weave, vec2(0.001), vec2(0.999));
	vec4 src = texture(TEXTURE, sample_uv);

	float radius = mix(-0.06, 1.02, burn_progress);
	float field = max(burn_field(UV, origin_a, radius, 0.92), burn_field(UV, origin_b, radius * 0.9, 1.12));
	field = max(field, burn_field(UV, origin_c, radius * 1.06, 0.84));
	field = max(field, burn_field(UV, origin_d, radius * 0.82, 1.0));
	field = max(field, burn_field(UV, origin_e, radius * 0.88, 0.95));
	field = max(field, burn_field(UV, origin_f, radius * 0.78, 1.08));
	field = max(field, burn_field(UV, origin_g, radius * 0.92, 0.9));
	field = max(field, smoothstep(0.68, 1.0, burn_progress) * 0.42 - distance(UV, vec2(0.5)) * 0.55);

	float hole = smoothstep(0.0, edge_width, field);
	float edge = smoothstep(-edge_width, edge_width, field) * (1.0 - hole);
	float charred = smoothstep(-char_width, edge_width, field) * (1.0 - hole);
	float sparks = step(0.985, hash(floor(UV * vec2(96.0, 64.0)) + vec2(floor(TIME * 28.0), floor(TIME * 21.0)))) * edge;

	vec3 color = film_grade(src.rgb, UV);
	color = mix(color, ash_color.rgb, charred * 0.86);
	color = mix(color, hot_color.rgb, edge * 1.25);
	color += hot_color.rgb * sparks * 0.85;
	float alpha = src.a * (1.0 - hole);
	COLOR = vec4(clamp(color, vec3(0.0), vec3(1.0)), alpha);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("burn_progress", 0.0)
	material.set_shader_parameter("edge_width", 0.105)
	material.set_shader_parameter("char_width", 0.15)
	return material


func _create_film_overlay_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float overlay_alpha : hint_range(0.0, 1.0) = 0.88;
uniform float scratch_strength : hint_range(0.0, 1.0) = 0.34;
uniform float dust_strength : hint_range(0.0, 1.0) = 0.28;
uniform float sprocket_alpha : hint_range(0.0, 1.0) = 0.62;
uniform vec4 rail_color : source_color = vec4(0.015, 0.012, 0.010, 1.0);
uniform vec4 dust_color : source_color = vec4(0.92, 0.86, 0.68, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(41.31, 289.73))) * 18531.1357);
}

float rect_mask(vec2 uv, vec2 center, vec2 half_size, float softness) {
	vec2 d = abs(uv - center) - half_size;
	float outside = length(max(d, vec2(0.0)));
	return 1.0 - smoothstep(0.0, softness, outside);
}

void fragment() {
	vec2 uv = UV;
	vec3 color = vec3(0.0);
	float alpha = 0.0;

	float rail = max(1.0 - smoothstep(0.055, 0.105, uv.x), smoothstep(0.895, 0.945, uv.x));
	float side_shadow = max(1.0 - smoothstep(0.10, 0.18, uv.x), smoothstep(0.82, 0.90, uv.x));
	color = mix(color, rail_color.rgb, rail);
	alpha = max(alpha, rail * sprocket_alpha);
	alpha = max(alpha, side_shadow * 0.18);

	float hole_y = fract(uv.y * 8.0 + TIME * 0.32);
	float hole_row = 1.0 - smoothstep(0.20, 0.34, abs(hole_y - 0.5));
	float left_hole = rect_mask(uv, vec2(0.052, uv.y), vec2(0.023, 0.030), 0.006) * hole_row;
	float right_hole = rect_mask(uv, vec2(0.948, uv.y), vec2(0.023, 0.030), 0.006) * hole_row;
	float holes = max(left_hole, right_hole);
	color = mix(color, vec3(0.74, 0.66, 0.47), holes);
	alpha = max(alpha, holes * 0.26);

	for (int i = 0; i < 7; i++) {
		float seed = float(i) * 17.17;
		float x = hash(vec2(seed, floor(TIME * 0.55))) * 0.78 + 0.11;
		float drift = sin(TIME * (0.24 + seed * 0.006) + seed) * 0.018;
		float width = 0.0014 + hash(vec2(seed, 5.2)) * 0.0032;
		float broken = step(0.34, hash(vec2(floor(uv.y * 26.0 + TIME * 1.7), seed)));
		float scratch = (1.0 - smoothstep(0.0, width, abs(uv.x - x - drift))) * broken;
		alpha = max(alpha, scratch * scratch_strength * 0.42);
		color = mix(color, dust_color.rgb, scratch * 0.55);
	}

	vec2 cell = floor(uv * vec2(72.0, 44.0));
	float speck_seed = hash(cell + vec2(floor(TIME * 12.0), floor(TIME * 9.0)));
	float speck = step(0.985, speck_seed);
	float speck_shape = 1.0 - smoothstep(0.0, 0.018 + hash(cell) * 0.013, distance(fract(uv * vec2(72.0, 44.0)), vec2(0.5)));
	float dust = speck * speck_shape * dust_strength;
	color = mix(color, dust_color.rgb, dust);
	alpha = max(alpha, dust * 0.75);

	float scan = 1.0 - smoothstep(0.0, 0.035, abs(fract(uv.y + TIME * 0.42) - 0.48));
	color = mix(color, vec3(0.96, 0.86, 0.62), scan * 0.25);
	alpha = max(alpha, scan * 0.08);

	float top_bottom = max(1.0 - smoothstep(0.0, 0.06, uv.y), smoothstep(0.94, 1.0, uv.y));
	color = mix(color, rail_color.rgb, top_bottom);
	alpha = max(alpha, top_bottom * 0.18);

	COLOR = vec4(color, clamp(alpha * overlay_alpha, 0.0, 1.0));
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	return material


func _create_burn_heat_overlay_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float burn_progress : hint_range(0.0, 1.0) = 0.0;
uniform float ash_peel_progress : hint_range(0.0, 1.0) = 0.0;
uniform vec2 origin_a = vec2(0.45, 0.5);
uniform vec2 origin_b = vec2(0.62, 0.42);
uniform vec2 origin_c = vec2(0.52, 0.58);
uniform vec4 ash_color : source_color = vec4(0.035, 0.032, 0.028, 1.0);
uniform vec4 ash_lift_color : source_color = vec4(0.20, 0.19, 0.16, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(83.13, 271.91))) * 34871.73);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float ash_mask(vec2 uv, vec2 origin, float radius) {
	float n = noise(uv * 7.0 + vec2(TIME * 0.025, -TIME * 0.018));
	float d = distance(uv, origin);
	return 1.0 - smoothstep(radius, radius + 0.24, d + (n - 0.5) * 0.16);
}

void fragment() {
	vec2 uv = UV;
	float form = smoothstep(0.34, 0.96, burn_progress);
	float radius = mix(0.04, 0.86, form);
	float mask = max(ash_mask(uv, origin_a, radius), ash_mask(uv, origin_b, radius * 0.92));
	mask = max(mask, ash_mask(uv, origin_c, radius * 1.08));
	mask = max(mask, smoothstep(0.72, 1.0, form) * smoothstep(0.86, 0.18, distance(uv, vec2(0.5))));

	float peel_noise = noise(uv * 10.0 + vec2(TIME * 0.08, TIME * 0.035));
	float peel_wave = uv.y * 0.58 + peel_noise * 0.52 + noise(uv * 28.0) * 0.18;
	float peeled = smoothstep(ash_peel_progress - 0.16, ash_peel_progress + 0.22, peel_wave);
	float ash = mask * (1.0 - peeled);

	float grain = hash(floor(uv * vec2(120.0, 88.0)) + vec2(floor(TIME * 6.0), floor(TIME * 4.0)));
	vec3 color = mix(ash_color.rgb, ash_lift_color.rgb, grain * 0.28 + peel_noise * 0.18);
	float ragged_edge = smoothstep(0.0, 0.14, ash) * (1.0 - smoothstep(0.52, 1.0, ash));
	color += vec3(0.08, 0.075, 0.06) * ragged_edge;
	float alpha = clamp(ash * (0.86 + grain * 0.10), 0.0, 0.92);
	COLOR = vec4(color, alpha);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("burn_progress", 0.0)
	material.set_shader_parameter("ash_peel_progress", 0.0)
	return material


func _create_transition_flash_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float intensity : hint_range(0.0, 2.0) = 0.0;
uniform vec2 origin_a = vec2(0.5, 0.5);
uniform vec2 origin_b = vec2(0.5, 0.5);
uniform vec2 origin_c = vec2(0.5, 0.5);
uniform vec4 burn_color : source_color = vec4(1.0, 0.88, 0.48, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float radial(vec2 uv, vec2 origin, float radius, float softness) {
	float d = distance(uv, origin);
	return 1.0 - smoothstep(radius, radius + softness, d);
}

void fragment() {
	vec2 uv = UV;
	float local_radius = mix(0.02, 0.72, progress);
	float soft = mix(0.05, 0.22, progress);
	float local = max(radial(uv, origin_a, local_radius, soft), radial(uv, origin_b, local_radius * 0.88, soft));
	local = max(local, radial(uv, origin_c, local_radius * 1.08, soft));
	float global = smoothstep(0.45, 1.0, progress);
	float grain = hash(floor(uv * vec2(96.0, 72.0)) + vec2(floor(TIME * 34.0), floor(TIME * 29.0)));
	float scan = max(0.0, sin((uv.y + TIME * 0.95) * 92.0));
	float tear = smoothstep(0.78, 1.0, hash(vec2(floor(TIME * 22.0), floor(uv.y * 18.0))));
	float exposure = clamp((local + global * 0.85) * intensity, 0.0, 1.35);
	exposure += grain * 0.18 * intensity * progress;
	exposure += scan * 0.12 * intensity * progress;
	exposure += tear * 0.18 * intensity * progress;
	vec3 color = mix(burn_color.rgb, vec3(1.0), clamp(progress * 0.75 + grain * 0.22, 0.0, 1.0));
	float alpha = clamp(exposure, 0.0, 0.96);
	COLOR = vec4(color, alpha);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("progress", 0.0)
	material.set_shader_parameter("intensity", 0.0)
	return material


func _create_pointer_hand_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float shimmer : hint_range(0.0, 1.0) = 0.0;
uniform float distort_strength : hint_range(0.0, 0.01) = 0.001;
uniform float wrist_fade_start : hint_range(0.0, 1.0) = 0.82;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(41.3, 289.7))) * 18531.1357);
}

void fragment() {
	vec2 uv = UV;
	float line_wave = sin((uv.y * 32.0) + TIME * 8.0 + sin(uv.x * 11.0));
	float heat_wave = sin((uv.x + uv.y) * 18.0 + TIME * 5.2);
	uv.x += line_wave * distort_strength * shimmer;
	uv.y += heat_wave * distort_strength * 0.42 * shimmer;
	vec4 color = texture(TEXTURE, uv);
	float flicker = (hash(floor(UV * vec2(42.0, 58.0)) + vec2(TIME * 16.0)) - 0.5) * 0.035 * shimmer;
	float wrist_fade = 1.0 - smoothstep(wrist_fade_start, 1.0, UV.y) * 0.68;
	float ragged_edge = hash(floor(UV * vec2(55.0, 90.0)) + vec2(floor(TIME * 8.0), floor(TIME * 6.0)));
	wrist_fade -= smoothstep(wrist_fade_start + 0.04, 1.0, UV.y) * ragged_edge * 0.16;
	color.rgb += flicker;
	color.a *= clamp(wrist_fade, 0.0, 1.0);
	color.a *= 0.96 + sin(TIME * 18.0) * 0.006 * shimmer;
	COLOR = color;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("shimmer", 1.0)
	material.set_shader_parameter("distort_strength", 0.001)
	material.set_shader_parameter("wrist_fade_start", 0.82)
	return material


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


func _apply_base_goldberg_visual() -> void:
	_current_shape_data = _shape_provider.get_shape("goldberg:1:4", shape_radius)
	if _current_shape_data == null:
		return

	# 1-2 keeps `sphere` as the rotation parent and hides the full body mesh.
	# Edges are rendered per cone cell so they stay attached to the displaced cones.
	sphere.mesh = null
	sphere.visible = true
	_update_edge_overlay_mesh(null)
	_update_static_edge_overlay_mesh(null)
	if _sphere_material != null:
		_sphere_material.set_shader_parameter("base_color", ACT_ONE_BASE_COLOR)
	_current_stage_mode = NORMAL_STAGE_MODE
	_current_stage_abnormal_ids.clear()
	_abnormal_intensities.clear()
	_update_goldberg_wave_shader_state()
	_set_polyhedron_edge_outline_enabled(false)


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


func _apply_stage(stage_index: int, animate_focus: bool, preserve_transition_lift: bool = false, show_pointer: bool = true) -> void:
	_current_stage_index = clampi(stage_index, 0, _stage_data.size() - 1)
	_stage_elapsed = 0.0
	_selected_route_ids.clear()
	_drag_active = false
	_drag_anchor_cell_id = -1
	_hover_cell_id = -1
	_hover_hold_elapsed = 0.0
	_charging_cell_id = -1
	_charge_elapsed = 0.0
	_charge_start_hint_t = 1.0
	_drag_grace_left = 0.0
	_rollback_active = false
	_rollback_elapsed = 0.0
	_rollback_fading_cell_id = -1
	_rollback_fading_committed = true
	_rollback_fading_charge_t = 1.0
	_rollback_fading_hint_t = 1.0
	_target_hint_elapsed = target_hint_fade_sec
	_pointer_hand_visible_target = show_pointer
	if show_pointer:
		_pointer_hand_alpha = 0.0
		_pointer_hand_enter_t = 0.0
	if not preserve_transition_lift:
		_transition_lift_offsets.clear()

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
	_current_route_guide_closed = bool(stage.get("route_closed", true))
	if _current_route_guide_closed:
		_current_stage_route_ids = _apply_route_span(
			_current_stage_route_ids,
			float(stage.get("route_span", 1.0)),
			true
		)
	else:
		_current_stage_route_ids = _derive_visible_texture_route(stage)
	_current_stage_height_map = _build_stage_height_map(stage)
	_current_route_guide_uvs = stage.get("preview_template", PackedVector2Array()) as PackedVector2Array
	_current_preview_uvs = _sample_route_template(
		stage.get("preview_template", PackedVector2Array()) as PackedVector2Array,
		_current_stage_route_ids.size(),
		_current_route_guide_closed
	)

	_apply_base_goldberg_visual()
	_rebuild_cell_geometry()
	_refresh_stage_labels()
	_refresh_route_preview()
	_refresh_cell_materials()
	_set_status_text("按住鼠标，从高亮单元开始沿纹理路径拖拽。")
	_apply_focus_rotation(
		float(stage.get("focus_yaw_deg", 0.0)),
		float(stage.get("focus_pitch_deg", -18.0)),
		animate_focus
	)


func _apply_route_span(route: Array[int], span: float, closed: bool) -> Array[int]:
	if closed or route.size() <= 2:
		return route

	var clamped_span: float = clampf(span, 0.05, 1.0)
	var keep_count: int = clampi(roundi(float(route.size()) * clamped_span), 2, route.size())
	if keep_count >= route.size():
		return route

	var start_index: int = maxi(0, int(floor(float(route.size() - keep_count) * 0.5)))
	var result: Array[int] = []
	for i in range(keep_count):
		result.append(route[start_index + i])
	return result


func _derive_visible_texture_route(stage: Dictionary) -> Array[int]:
	var template := stage.get("preview_template", PackedVector2Array()) as PackedVector2Array
	if template.size() < 2:
		return _current_stage_route_ids

	var route_count: int = int(stage.get("left_route_count", 16))
	route_count = clampi(route_count, 6, 26)
	var sampled_uvs := _sample_route_template(template, route_count, false)
	var focus_basis := Basis.from_euler(Vector3(
		deg_to_rad(float(stage.get("focus_pitch_deg", -18.0))),
		deg_to_rad(float(stage.get("focus_yaw_deg", 0.0))),
		0.0
	))
	var route_scale := stage.get("left_route_scale", Vector2.ONE) as Vector2
	var route_offset := stage.get("left_route_offset", Vector2.ZERO) as Vector2

	var candidates: Array[Dictionary] = []
	for cell_id_variant in _cells_by_id.keys():
		var cell_id := int(cell_id_variant)
		var rotated := focus_basis * _get_cell_center(cell_id)
		if rotated.z < -0.08:
			continue
		candidates.append({
			"id": cell_id,
			"screen": Vector2(rotated.x, -rotated.y),
			"front": rotated.z,
		})

	if candidates.is_empty():
		return _current_stage_route_ids

	var min_x := INF
	var max_x := -INF
	var min_y := INF
	var max_y := -INF
	for candidate in candidates:
		var screen := candidate["screen"] as Vector2
		min_x = minf(min_x, screen.x)
		max_x = maxf(max_x, screen.x)
		min_y = minf(min_y, screen.y)
		max_y = maxf(max_y, screen.y)

	var picked_lookup: Dictionary = {}
	var anchors: Array[int] = []
	for uv in sampled_uvs:
		var centered := (uv - Vector2(0.5, 0.5)) * route_scale + Vector2(0.5, 0.5) + route_offset
		var target := Vector2(
			lerpf(min_x, max_x, clampf(centered.x, 0.0, 1.0)),
			lerpf(min_y, max_y, clampf(centered.y, 0.0, 1.0))
		)

		var best_id := -1
		var best_score := INF
		for candidate in candidates:
			var candidate_id := int(candidate["id"])
			if picked_lookup.has(candidate_id):
				continue
			var screen := candidate["screen"] as Vector2
			var front := float(candidate["front"])
			var score := screen.distance_squared_to(target) - front * 0.025
			if score < best_score:
				best_score = score
				best_id = candidate_id
		if best_id >= 0:
			picked_lookup[best_id] = true
			anchors.append(best_id)

	var route := _stitch_anchor_cells_to_neighbor_route(anchors)
	return route if route.size() >= 2 else _current_stage_route_ids


func _stitch_anchor_cells_to_neighbor_route(anchors: Array[int]) -> Array[int]:
	if anchors.size() <= 1:
		return anchors

	var route: Array[int] = [anchors[0]]
	var used: Dictionary = {anchors[0]: true}
	for anchor_index in range(1, anchors.size()):
		var start_id := route[route.size() - 1]
		var goal_id := anchors[anchor_index]
		if start_id == goal_id:
			continue

		var blocked := used.duplicate()
		blocked.erase(start_id)
		blocked.erase(goal_id)
		var path := _find_cell_path(start_id, goal_id, blocked)
		if path.size() < 2:
			continue

		for path_index in range(1, path.size()):
			var next_id := path[path_index]
			if route.size() >= 2 and next_id == route[route.size() - 2]:
				continue
			if used.has(next_id) and next_id != goal_id:
				continue
			route.append(next_id)
			used[next_id] = true

	return route


func _find_cell_path(start_id: int, goal_id: int, blocked: Dictionary) -> Array[int]:
	if start_id == goal_id:
		return [start_id]

	var queue: Array[int] = [start_id]
	var previous: Dictionary = {start_id: -1}
	var read_index := 0
	while read_index < queue.size():
		var current_id := queue[read_index]
		read_index += 1
		var cell: Object = _cells_by_id.get(current_id) as Object
		if cell == null:
			continue
		var neighbors: PackedInt32Array = cell.get("neighbors") as PackedInt32Array
		for neighbor_id_variant in neighbors:
			var neighbor_id := int(neighbor_id_variant)
			if blocked.has(neighbor_id) and neighbor_id != goal_id:
				continue
			if previous.has(neighbor_id):
				continue
			previous[neighbor_id] = current_id
			if neighbor_id == goal_id:
				return _reconstruct_cell_path(previous, start_id, goal_id)
			queue.append(neighbor_id)

	return []


func _reconstruct_cell_path(previous: Dictionary, start_id: int, goal_id: int) -> Array[int]:
	var reversed_path: Array[int] = []
	var current_id := goal_id
	while current_id != -1:
		reversed_path.append(current_id)
		if current_id == start_id:
			break
		current_id = int(previous.get(current_id, -1))

	if reversed_path.is_empty() or reversed_path[reversed_path.size() - 1] != start_id:
		return []

	var path: Array[int] = []
	for i in range(reversed_path.size() - 1, -1, -1):
		path.append(reversed_path[i])
	return path


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
	var route_index_map: Dictionary = {}
	var route_index := 0
	for cell_id in _current_stage_route_ids:
		route_lookup[cell_id] = true
		route_index_map[cell_id] = route_index
		route_index += 1
	var route_distance_map := _build_distance_map(_current_stage_route_ids)

	var axis := stage.get("noise_axis", Vector3.UP) as Vector3
	if axis.length_squared() < 0.000001:
		axis = Vector3.UP
	axis = axis.normalized()

	var pattern := String(stage.get("pattern", STAGE_PATTERN_RINGS))
	for cell_id_variant in _cells_by_id.keys():
		var cell_id := int(cell_id_variant)
		var dist := int(core_distance_map.get(cell_id, 999))
		var route_dist := int(route_distance_map.get(cell_id, 999))
		var axis_wave := _get_cell_normal(cell_id).dot(axis)
		var cell_hash := _hash_cell(cell_id)
		var height := -0.03

		match pattern:
			STAGE_PATTERN_RINGS:
				var ring_band := sin((axis_wave + 1.0) * 18.0 + cell_hash * 2.4)
				height = -0.035 + ring_band * 0.035 + axis_wave * 0.018
				if route_lookup.has(cell_id):
					var t := float(route_index_map.get(cell_id, 0)) / maxf(1.0, float(_current_stage_route_ids.size() - 1))
					height = 0.095 + sin(t * TAU * 1.15) * 0.025
				elif route_dist == 1:
					height += 0.035
				elif route_dist == 2:
					height += 0.015
			STAGE_PATTERN_CRACK:
				height = 0.015 + (cell_hash - 0.5) * 0.055 + axis_wave * 0.025
				if route_lookup.has(cell_id):
					height = -0.125 + (cell_hash - 0.5) * 0.018
				elif route_dist == 1:
					height = -0.055 + (cell_hash - 0.5) * 0.028
				elif route_dist == 2:
					height -= 0.018
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
	_cell_edge_nodes.clear()
	_cell_edge_materials.clear()
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

		var edge_node := MeshInstance3D.new()
		edge_node.name = "Cell_%d_Edge" % cell_id
		edge_node.mesh = _build_cell_edge_mesh(render_base_center, apex, render_polygon)
		edge_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

		var edge_material := StandardMaterial3D.new()
		edge_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		edge_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		edge_material.emission_enabled = true
		edge_material.no_depth_test = false
		edge_node.material_override = edge_material

		_cell_root.add_child(edge_node)
		_cell_edge_nodes[cell_id] = edge_node
		_cell_edge_materials[cell_id] = edge_material
		_cell_runtime_data[cell_id] = {
			"base_center": base_center,
			"apex": apex,
			"polygon": inset_polygon,
			"hit_polygon": hit_polygon,
			"normal": normal,
			"base_height": float(_current_stage_height_map.get(cell_id, 0.0)),
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


func _build_cell_edge_mesh(_base_center: Vector3, apex: Vector3, polygon: PackedVector3Array) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	if polygon.size() < 3:
		return st.commit()

	var segments: Array[Dictionary] = []
	for i in range(polygon.size()):
		segments.append({
			"a": polygon[i],
			"b": polygon[(i + 1) % polygon.size()],
		})
		segments.append({
			"a": polygon[i],
			"b": apex,
		})

	var average_edge_length := 0.0
	for segment in segments:
		average_edge_length += (segment["a"] as Vector3).distance_to(segment["b"] as Vector3)
	average_edge_length /= float(segments.size())

	var edge_width := clampf(
		average_edge_length * EDGE_WIDTH_FROM_LENGTH * GOLDBERG_DYNAMIC_EDGE_WIDTH_SCALE,
		shape_radius * EDGE_MIN_RADIUS_RATIO * GOLDBERG_DYNAMIC_EDGE_WIDTH_SCALE,
		shape_radius * EDGE_MAX_RADIUS_RATIO * GOLDBERG_DYNAMIC_EDGE_WIDTH_SCALE
	)
	var half_width := edge_width * 0.5
	var half_depth := half_width * EDGE_DEPTH_FROM_WIDTH
	var lift := half_depth + shape_radius * EDGE_SURFACE_LIFT_RATIO
	for segment in segments:
		_append_cell_edge_prism(
			st,
			segment["a"] as Vector3,
			segment["b"] as Vector3,
			half_width,
			half_depth,
			lift
		)

	return st.commit()


func _append_cell_edge_prism(
	st: SurfaceTool,
	a: Vector3,
	b: Vector3,
	half_width: float,
	half_depth: float,
	lift: float
) -> void:
	var tangent := b - a
	if tangent.length_squared() < 0.000001:
		return
	tangent = tangent.normalized()

	var outward := (a.normalized() + b.normalized()) * 0.5
	if outward.length_squared() < 0.000001:
		outward = a.normalized()
	outward = outward.normalized()

	var side := tangent.cross(outward)
	if side.length_squared() < 0.000001:
		side = tangent.cross(Vector3.UP)
	if side.length_squared() < 0.000001:
		side = tangent.cross(Vector3.RIGHT)
	side = side.normalized()

	var depth_axis := side.cross(tangent)
	if depth_axis.length_squared() < 0.000001:
		depth_axis = outward
	depth_axis = depth_axis.normalized()

	var width_offset := side * half_width
	var depth_offset := depth_axis * half_depth
	var start_center := a + depth_axis * lift
	var end_center := b + depth_axis * lift

	var start_ring := PackedVector3Array([
		start_center + width_offset + depth_offset,
		start_center - width_offset + depth_offset,
		start_center - width_offset - depth_offset,
		start_center + width_offset - depth_offset,
	])
	var end_ring := PackedVector3Array([
		end_center + width_offset + depth_offset,
		end_center - width_offset + depth_offset,
		end_center - width_offset - depth_offset,
		end_center + width_offset - depth_offset,
	])

	for side_index in range(4):
		var next_index := (side_index + 1) % 4
		_append_edge_quad(st, start_ring[side_index], end_ring[side_index], end_ring[next_index], start_ring[next_index])
	_append_edge_quad(st, start_ring[0], start_ring[1], start_ring[2], start_ring[3])
	_append_edge_quad(st, end_ring[3], end_ring[2], end_ring[1], end_ring[0])


func _append_edge_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	var normal := (b - a).cross(c - a)
	if normal.length_squared() < 0.000001:
		return
	normal = normal.normalized()

	st.set_normal(normal)
	st.add_vertex(a)
	st.set_normal(normal)
	st.add_vertex(b)
	st.set_normal(normal)
	st.add_vertex(c)

	st.set_normal(normal)
	st.add_vertex(a)
	st.set_normal(normal)
	st.add_vertex(c)
	st.set_normal(normal)
	st.add_vertex(d)


func _append_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_append_triangle(st, a, b, c)
	_append_triangle(st, a, c, d)


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

	var target_id := -1 if _rollback_active else _get_current_target_cell_id()
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
		var base_visual_color := color

		var emission := Color.BLACK
		var emission_energy := 0.0
		var edge_color := polyhedron_edge_color.darkened(0.18)
		var edge_energy := clampf(0.38 + (polyhedron_edge_line_width - 1.0) * 0.04, 0.38, 0.78)
		var edge_depth_disabled := false
		var glow_level := 0.0

		if _rollback_active and cell_id == _rollback_fading_cell_id:
			var fade_t := clampf(_rollback_elapsed / maxf(0.001, rollback_step_sec), 0.0, 1.0)
			if _rollback_fading_committed:
				glow_level = 1.0 - fade_t
			else:
				var rollback_hint := clampf(_rollback_fading_hint_t, 0.0, 1.0)
				var rollback_charge := clampf(_rollback_fading_charge_t, 0.0, 1.0)
				var smooth_rollback_hint := rollback_hint * rollback_hint * (3.0 - 2.0 * rollback_hint)
				var smooth_rollback_charge := rollback_charge * rollback_charge * (3.0 - 2.0 * rollback_charge)
				var start_level := lerpf(0.5 * smooth_rollback_hint, 1.0, smooth_rollback_charge)
				glow_level = lerpf(start_level, 0.0, fade_t)
		elif _selected_route_ids.has(cell_id):
			glow_level = 1.0
		elif _drag_active and cell_id == _charging_cell_id:
			var charge_t := clampf(_charge_elapsed / maxf(0.001, cell_hold_sec), 0.0, 1.0)
			var smooth_charge := charge_t * charge_t * (3.0 - 2.0 * charge_t)
			var start_hint_t := clampf(_charge_start_hint_t, 0.0, 1.0)
			var smooth_start_hint := start_hint_t * start_hint_t * (3.0 - 2.0 * start_hint_t)
			glow_level = lerpf(0.5 * smooth_start_hint, 1.0, smooth_charge)
		elif cell_id == target_id:
			var hint_t := clampf(_target_hint_elapsed / maxf(0.001, target_hint_fade_sec), 0.0, 1.0)
			var smooth_hint := hint_t * hint_t * (3.0 - 2.0 * hint_t)
			glow_level = 0.5 * smooth_hint
		elif route_lookup.has(cell_id):
			emission = route_color
			emission_energy = 0.16
			edge_color = route_color
			edge_energy = 0.72

		if glow_level > 0.0:
			glow_level = clampf(glow_level, 0.0, 1.0)
			if glow_level <= 0.5:
				var hint_mix := glow_level / 0.5
				color = base_visual_color.lerp(target_color, 0.42 * hint_mix)
				emission = target_color
				emission_energy = 0.46 * hint_mix
				edge_color = target_color
				edge_energy = lerpf(0.42, 1.08, hint_mix)
			else:
				var full_mix := (glow_level - 0.5) / 0.5
				var half_color := base_visual_color.lerp(target_color, 0.42)
				color = half_color.lerp(selected_color, full_mix)
				emission = target_color.lerp(selected_color, full_mix)
				emission_energy = lerpf(0.46, 1.35, full_mix)
				edge_color = target_color.lerp(selected_color, full_mix)
				edge_energy = lerpf(1.08, 2.05, full_mix)
		elif route_lookup.has(cell_id):
			emission = route_color
			emission_energy = 0.16
			edge_color = route_color
			edge_energy = 0.72

		material.albedo_color = color
		material.emission = emission
		material.emission_energy_multiplier = emission_energy
		var edge_material := _cell_edge_materials.get(cell_id) as StandardMaterial3D
		if edge_material != null:
			edge_material.no_depth_test = edge_depth_disabled
			edge_material.albedo_color = edge_color
			edge_material.emission = edge_color
			edge_material.emission_energy_multiplier = edge_energy
		var runtime := _cell_runtime_data.get(cell_id, {}) as Dictionary
		if not runtime.is_empty():
			runtime["visual_color"] = color
			runtime["visual_emission"] = emission
			runtime["visual_emission_energy"] = emission_energy
			runtime["edge_color"] = edge_color
			runtime["edge_energy"] = edge_energy
			runtime["edge_depth_disabled"] = edge_depth_disabled
			runtime["glow_level"] = glow_level


func _update_texture_surface_motion() -> void:
	if _cell_nodes.is_empty():
		return

	var stage := _stage_data[_current_stage_index]
	var pattern := String(stage.get("pattern", STAGE_PATTERN_RINGS))
	var route_color := stage.get("route_color", Color(0.9, 0.9, 0.9, 1.0)) as Color
	var selected_color := stage.get("selected_color", route_color) as Color
	var route_lookup: Dictionary = {}
	for cell_id in _current_stage_route_ids:
		route_lookup[cell_id] = true

	for cell_id_variant in _cell_nodes.keys():
		var cell_id := int(cell_id_variant)
		var node := _cell_nodes.get(cell_id) as Node3D
		var edge_node := _cell_edge_nodes.get(cell_id) as Node3D
		var material := _cell_materials.get(cell_id) as StandardMaterial3D
		var edge_material := _cell_edge_materials.get(cell_id) as StandardMaterial3D
		var runtime := _cell_runtime_data.get(cell_id, {}) as Dictionary
		if node == null or material == null or runtime.is_empty():
			continue

		var normal := runtime.get("normal", Vector3.UP) as Vector3
		var base_height := float(runtime.get("base_height", 0.0))
		var hash := _hash_cell(cell_id)
		var route_weight := 1.0 if route_lookup.has(cell_id) else 0.0
		var phase := hash * TAU * 2.0
		var motion := 0.0

		match pattern:
			STAGE_PATTERN_RINGS:
				motion = sin(_stage_elapsed * 5.6 + phase + base_height * 9.0) * texture_motion_amplitude * 0.68
				motion += sin(_stage_elapsed * 8.2 + phase * 0.73) * texture_motion_amplitude * 0.32
			STAGE_PATTERN_CRACK:
				motion = sin(_stage_elapsed * 7.4 + phase) * texture_motion_amplitude * 0.58
				motion += signf(sin(_stage_elapsed * 5.1 + phase * 1.7)) * texture_motion_amplitude * 0.20
			_:
				motion = sin(_stage_elapsed * 5.2 + phase) * texture_motion_amplitude * 0.52

		if route_weight > 0.0:
			motion += texture_motion_amplitude * (0.50 if pattern != STAGE_PATTERN_CRACK else -0.26)
		var glow_level := clampf(float(runtime.get("glow_level", 0.0)), 0.0, 1.0)
		if glow_level > 0.0:
			motion += (sin(_stage_elapsed * 8.5) * texture_motion_amplitude * 0.55 + 0.006) * glow_level

		var transition_lift := float(_transition_lift_offsets.get(cell_id, 0.0))
		node.position = normal * (motion + transition_lift)
		if edge_node != null:
			edge_node.position = node.position

		var base_color := runtime.get("visual_color", material.albedo_color) as Color
		var base_emission := runtime.get("visual_emission", Color.BLACK) as Color
		var base_emission_energy := float(runtime.get("visual_emission_energy", 0.0))
		if route_weight <= 0.0 and glow_level <= 0.0:
			var sweep := sin(_stage_elapsed * 2.35 + phase * 2.1 + base_height * 18.0)
			var sparkle := maxf(0.0, sweep)
			sparkle = sparkle * sparkle * sparkle
			var pulse_color := route_color.lerp(selected_color, 0.38 + 0.22 * sin(phase))
			base_color = base_color.lerp(pulse_color, sparkle * 0.20)
			base_emission = base_emission.lerp(pulse_color, sparkle * 0.18)
			base_emission_energy += sparkle * 0.13
		if _transition_color_flash_strength > 0.0:
			var flicker := 0.55 + 0.45 * maxf(0.0, sin(_stage_elapsed * 18.0 + phase * 1.7))
			var flash_mix := clampf(_transition_color_flash_strength * flicker, 0.0, 1.0)
			var flash_color := Color(1.0, 0.82, 0.42, 1.0).lerp(Color.WHITE, flash_mix * 0.35)
			base_color = base_color.lerp(flash_color, flash_mix * 0.72)
			base_emission = base_emission.lerp(flash_color, flash_mix)
			base_emission_energy += 0.85 * flash_mix + 0.55 * _transition_color_flash_strength
		material.albedo_color = base_color
		material.emission = base_emission
		material.emission_energy_multiplier = base_emission_energy
		if edge_material != null:
			var edge_color := runtime.get("edge_color", polyhedron_edge_color) as Color
			var edge_energy := float(runtime.get("edge_energy", 0.04))
			edge_material.no_depth_test = bool(runtime.get("edge_depth_disabled", false))
			if glow_level > 0.0 and _charging_cell_id < 0:
				edge_energy += 0.18 * glow_level * maxf(0.0, sin(_stage_elapsed * 8.5))
			elif route_weight <= 0.0:
				var edge_sweep := maxf(0.0, sin(_stage_elapsed * 2.35 + phase * 2.1 + base_height * 18.0))
				edge_sweep = edge_sweep * edge_sweep * edge_sweep
				edge_color = edge_color.lerp(route_color, edge_sweep * 0.28)
				edge_energy += edge_sweep * 0.22
			if _transition_color_flash_strength > 0.0:
				var edge_flash := clampf(_transition_color_flash_strength * (0.72 + 0.28 * sin(_stage_elapsed * 22.0 + phase)), 0.0, 1.0)
				edge_color = edge_color.lerp(Color(1.0, 0.78, 0.36, 1.0), edge_flash)
				edge_energy += edge_flash * 1.15
			edge_material.albedo_color = edge_color
			edge_material.emission = edge_color
			edge_material.emission_energy_multiplier = edge_energy


func _refresh_stage_labels() -> void:
	var stage := _stage_data[_current_stage_index]
	_refresh_stage_image(stage)
	_panel_backdrop.color = Color(0.72, 0.70, 0.62, 0.10)
	_stage_badge_label.text = "场景 %d / %d" % [_current_stage_index + 1, _stage_data.size()]
	_title_label.text = String(stage.get("title", ""))
	_desc_label.text = String(stage.get("subtitle", ""))
	_hint_label.text = "WASD 旋转结构，按住鼠标连续拖拽纹理路径。"
	_progress_label.text = "路径进度 %d / %d" % [_selected_route_ids.size(), _current_stage_route_ids.size()]
	var trace_color := _get_trace_theme_color(stage, true)
	line_canvas.line_color = trace_color
	line_canvas.line_shadow_color = _get_trace_shadow_color(trace_color)
	line_canvas.line_shadow_extra_width = 2.6
	line_canvas.particle_color = Color(
		minf(trace_color.r + 0.20, 1.0),
		minf(trace_color.g + 0.18, 1.0),
		minf(trace_color.b + 0.16, 1.0),
		0.96
	)


func _refresh_stage_image(stage: Dictionary) -> void:
	if _stage_image_rect == null:
		return
	if _suppress_stage_image_refresh:
		return

	var image_path := String(stage.get("image_path", ""))
	if image_path.is_empty():
		_stage_image_rect.texture = null
		_stage_image_rect.visible = false
		return

	var texture := load(image_path) as Texture2D
	if texture == null:
		push_warning("Missing chapter 1-2 texture image: %s" % image_path)
		_stage_image_rect.texture = null
		_stage_image_rect.visible = false
		return

	_stage_image_rect.texture = texture
	_stage_image_rect.visible = true


func _get_film_trace_color(stage: Dictionary, completed: bool) -> Color:
	var source := stage.get("selected_color", Color(0.88, 0.84, 0.72, 1.0)) as Color
	if not completed:
		source = stage.get("target_color", source) as Color
	var luma := source.r * 0.299 + source.g * 0.587 + source.b * 0.114
	var muted := Color(
		lerpf(luma, source.r, 0.18),
		lerpf(luma, source.g, 0.18),
		lerpf(luma, source.b, 0.18),
		0.0
	)
	var paper := Color(0.84, 0.82, 0.73, 1.0)
	var result := muted.lerp(paper, 0.48)
	result.a = 0.86 if completed else 0.34
	return result


func _get_trace_theme_color(stage: Dictionary, completed: bool) -> Color:
	var source := stage.get("selected_color", Color(0.95, 0.9, 0.72, 1.0)) as Color
	if not completed:
		source = stage.get("target_color", source) as Color
	var result := source.lerp(Color.WHITE, 0.08)
	result.a = 0.94 if completed else 0.42
	return result


func _get_trace_shadow_color(trace_color: Color) -> Color:
	var luma := trace_color.r * 0.299 + trace_color.g * 0.587 + trace_color.b * 0.114
	if luma > 0.72:
		return Color(0.09, 0.075, 0.055, 0.58)
	return Color(trace_color.r * 0.22, trace_color.g * 0.18, trace_color.b * 0.14, 0.58)


func _set_status_text(text: String) -> void:
	if _status_label != null:
		_status_label.text = text


func _ensure_audio_players() -> void:
	if _sphere_click_audio_player != null and is_instance_valid(_sphere_click_audio_player):
		return
	_sphere_click_audio_player = AudioStreamPlayer.new()
	_sphere_click_audio_player.name = "SphereClickAudioPlayer"
	_sphere_click_audio_player.stream = SPHERE_CLICK_AUDIO
	add_child(_sphere_click_audio_player)


func _play_sphere_click_audio() -> void:
	if _sphere_click_audio_player == null or not is_instance_valid(_sphere_click_audio_player):
		return
	_sphere_click_audio_player.stop()
	_sphere_click_audio_player.play()


func _try_begin_drag() -> void:
	if _transition_running:
		return
	if _rollback_active:
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
	_charging_cell_id = picked_id
	_charge_elapsed = 0.0
	_charge_start_hint_t = clampf(_target_hint_elapsed / maxf(0.001, target_hint_fade_sec), 0.0, 1.0)
	_drag_grace_left = drag_grace_sec
	_set_status_text("保持按住，沿着纹理路径连续拖过去。")
	_refresh_cell_materials()
	_play_sphere_click_audio()
	get_viewport().set_input_as_handled()


func _update_drag_progress(delta: float) -> void:
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_start_rollback("描摹中断，路径开始回撤。")
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
		if _charging_cell_id != picked_id:
			_charging_cell_id = picked_id
			_charge_elapsed = 0.0
			_charge_start_hint_t = clampf(_target_hint_elapsed / maxf(0.001, target_hint_fade_sec), 0.0, 1.0)
		_hover_hold_elapsed += delta
		_charge_elapsed += delta
		_drag_grace_left = drag_grace_sec
		_refresh_cell_materials()
		if _charge_elapsed >= cell_hold_sec:
			_commit_current_target_cell()
		return

	if picked_id == anchor_id and anchor_id >= 0:
		if _hover_cell_id != -1:
			_hover_cell_id = -1
			_hover_hold_elapsed = 0.0
			_charging_cell_id = -1
			_charge_elapsed = 0.0
			_charge_start_hint_t = 1.0
			_refresh_cell_materials()
		_drag_grace_left = drag_grace_sec
		return

	if _hover_cell_id != -1:
		_hover_cell_id = -1
		_hover_hold_elapsed = 0.0
		_charging_cell_id = -1
		_charge_elapsed = 0.0
		_charge_start_hint_t = 1.0
		_refresh_cell_materials()
	_drag_grace_left -= delta
	if _drag_grace_left <= 0.0:
		var reason := "光标离开路径，路径开始回撤。"
		if picked_id != -1:
			reason = "走错单元，路径开始回撤。"
		_start_rollback(reason)


func _commit_current_target_cell() -> void:
	var target_id := _get_current_target_cell_id()
	if target_id < 0:
		return

	_selected_route_ids.append(target_id)
	_drag_anchor_cell_id = target_id
	_hover_cell_id = -1
	_hover_hold_elapsed = 0.0
	_charging_cell_id = -1
	_charge_elapsed = 0.0
	_charge_start_hint_t = 1.0
	_drag_grace_left = drag_grace_sec
	_target_hint_elapsed = 0.0
	_refresh_stage_labels()
	_refresh_route_preview()
	_refresh_cell_materials()

	if _selected_route_ids.size() >= _current_stage_route_ids.size():
		_drag_active = false
		_transition_running = true
		_pointer_hand_visible_target = false
		_set_status_text("路径完成。")
		call_deferred("_complete_current_stage")


func _cancel_drag(reason: String) -> void:
	_drag_active = false
	_drag_anchor_cell_id = -1
	_hover_cell_id = -1
	_hover_hold_elapsed = 0.0
	_charging_cell_id = -1
	_charge_elapsed = 0.0
	_charge_start_hint_t = 1.0
	_drag_grace_left = 0.0
	_selected_route_ids.clear()
	_refresh_stage_labels()
	_refresh_route_preview()
	_refresh_cell_materials()
	_set_status_text(reason)


func _start_rollback(reason: String) -> void:
	var unfinished_cell_id := _charging_cell_id
	var unfinished_charge_t := clampf(_charge_elapsed / maxf(0.001, cell_hold_sec), 0.0, 1.0)
	var unfinished_hint_t := clampf(_charge_start_hint_t, 0.0, 1.0) if unfinished_cell_id >= 0 else 0.0
	if unfinished_cell_id < 0:
		var hinted_target_id := _get_current_target_cell_id()
		var hint_t := clampf(_target_hint_elapsed / maxf(0.001, target_hint_fade_sec), 0.0, 1.0)
		if hinted_target_id >= 0 and hint_t > 0.0:
			unfinished_cell_id = hinted_target_id
			unfinished_charge_t = 0.0
			unfinished_hint_t = hint_t
	_drag_active = false
	_drag_anchor_cell_id = -1
	_hover_cell_id = -1
	_hover_hold_elapsed = 0.0
	_charging_cell_id = -1
	_charge_elapsed = 0.0
	_drag_grace_left = 0.0
	if _selected_route_ids.is_empty() and unfinished_cell_id < 0:
		_cancel_drag(reason)
		return
	_rollback_active = true
	_rollback_elapsed = 0.0
	if unfinished_cell_id >= 0:
		_rollback_fading_cell_id = unfinished_cell_id
		_rollback_fading_committed = false
		_rollback_fading_charge_t = unfinished_charge_t
		_rollback_fading_hint_t = unfinished_hint_t
	else:
		_rollback_fading_cell_id = _selected_route_ids[_selected_route_ids.size() - 1]
		_rollback_fading_committed = true
		_rollback_fading_charge_t = 1.0
		_rollback_fading_hint_t = 1.0
	_set_status_text(reason + " 按住正在变暗的锥体可维持进度。")
	_refresh_cell_materials()
	get_viewport().set_input_as_handled()


func _update_rollback(delta: float) -> void:
	if _selected_route_ids.is_empty() and (_rollback_fading_cell_id < 0 or _rollback_fading_committed):
		_stop_rollback(false)
		return

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and _is_pointer_on_rollback_cell():
		_resume_rollback_progress()
		return

	_rollback_elapsed += delta
	if _rollback_elapsed < rollback_step_sec:
		_refresh_cell_materials()
		return

	if not _rollback_fading_committed:
		_rollback_elapsed = 0.0
		_rollback_fading_charge_t = 1.0
		_rollback_fading_hint_t = 1.0
		if _selected_route_ids.is_empty():
			_stop_rollback(false)
		else:
			_rollback_fading_cell_id = _selected_route_ids[_selected_route_ids.size() - 1]
			_rollback_fading_committed = true
			_drag_anchor_cell_id = _rollback_fading_cell_id
		_refresh_stage_labels()
		_refresh_route_preview()
		_refresh_cell_materials()
		return

	_selected_route_ids.pop_back()
	_rollback_elapsed = 0.0
	if _selected_route_ids.is_empty():
		_stop_rollback(false)
		_set_status_text("路径已回撤到起点。")
	else:
		_rollback_fading_cell_id = _selected_route_ids[_selected_route_ids.size() - 1]
		_drag_anchor_cell_id = _rollback_fading_cell_id
		_set_status_text("路径回撤中。按住正在变暗的锥体可维持进度。")
	_refresh_stage_labels()
	_refresh_route_preview()
	_refresh_cell_materials()


func _try_resume_rollback() -> void:
	if not _rollback_active or _rollback_fading_cell_id < 0:
		return

	if not _is_pointer_on_rollback_cell():
		return

	_resume_rollback_progress()


func _is_pointer_on_rollback_cell() -> bool:
	if _rollback_fading_cell_id < 0:
		return false
	if not left_3d.get_global_rect().has_point(_latest_mouse_pos):
		return false
	var picked_id := _pick_cell_at_screen_position(_latest_mouse_pos, [_rollback_fading_cell_id])
	return picked_id == _rollback_fading_cell_id


func _resume_rollback_progress() -> void:
	var resume_cell_id := _rollback_fading_cell_id
	var resume_was_committed := _rollback_fading_committed
	var resume_charge_t := _rollback_fading_charge_t
	var resume_hint_t := _rollback_fading_hint_t
	var resume_fade_t := clampf(_rollback_elapsed / maxf(0.001, rollback_step_sec), 0.0, 1.0)
	_stop_rollback(true)
	_drag_active = true
	_drag_anchor_cell_id = _selected_route_ids[_selected_route_ids.size() - 1] if not _selected_route_ids.is_empty() else -1
	_hover_cell_id = -1
	_hover_hold_elapsed = 0.0
	if resume_was_committed:
		_charging_cell_id = -1
		_charge_elapsed = 0.0
	else:
		_charging_cell_id = resume_cell_id
		_charge_elapsed = clampf(resume_charge_t, 0.0, 1.0) * cell_hold_sec
		_charge_start_hint_t = clampf(resume_hint_t * (1.0 - resume_fade_t), 0.0, 1.0)
	_drag_grace_left = drag_grace_sec
	_set_status_text("进度已维持，继续沿纹理路径拖拽。")
	_refresh_cell_materials()
	get_viewport().set_input_as_handled()


func _stop_rollback(keep_progress: bool) -> void:
	_rollback_active = false
	_rollback_elapsed = 0.0
	_rollback_fading_cell_id = -1
	_rollback_fading_committed = true
	_rollback_fading_charge_t = 1.0
	_rollback_fading_hint_t = 1.0
	_charging_cell_id = -1
	_charge_elapsed = 0.0
	_charge_start_hint_t = 1.0
	if not keep_progress:
		_target_hint_elapsed = 0.0
	if not keep_progress and _selected_route_ids.is_empty():
		_drag_anchor_cell_id = -1
	_refresh_cell_materials()


func _complete_current_stage() -> void:
	_refresh_route_preview()
	_refresh_cell_materials()
	_pointer_hand_visible_target = false
	await get_tree().create_timer(0.42).timeout

	var next_stage_index := _current_stage_index + 1
	if next_stage_index < _stage_data.size():
		await _play_texture_reassembly_transition(next_stage_index)
		_transition_running = false
		return

	await _play_final_texture_transition()
	_transition_running = false
	if not _chapter_completed_once:
		_chapter_completed_once = true
		chapter_completed.emit(chapter_index)


func _play_texture_reassembly_transition(next_stage_index: int) -> void:
	_set_status_text("路径显影完成，结构正在解体。")
	_pointer_hand_visible_target = false
	await _wait_pointer_hand_exit()

	var previous_route := _current_stage_route_ids.duplicate()
	var next_stage := _stage_data[next_stage_index]
	var next_texture := _load_stage_texture(next_stage)
	if _transition_flash_rect != null:
		_transition_flash_rect.visible = false
	_prepare_burn_reveal(next_texture)
	_prepare_route_burn()

	await _run_transition_lift_phase(previous_route, 0.0, TRANSITION_LIFT_RADIUS, TRANSITION_LIFT_OUT_SEC, 0.0, 0.42)

	await _run_transition_color_flash_phase(0.0, 1.0, 0.8, 0.42, 0.55)
	await _run_burn_reveal_phase(0.55, 1.0, TRANSITION_FILM_SWITCH_SEC)

	var target_yaw := float(next_stage.get("focus_yaw_deg", 0.0))
	var target_pitch := float(next_stage.get("focus_pitch_deg", -18.0))
	_sync_rotation_state_from_model()
	var hold_yaw := _yaw_deg
	var hold_pitch := _pitch_deg
	_suppress_stage_image_refresh = true
	_apply_stage(next_stage_index, false, true, false)
	_suppress_stage_image_refresh = false
	_yaw_deg = hold_yaw
	_pitch_deg = hold_pitch
	_set_model_rotation_from_state()
	_set_all_transition_lift_offsets(TRANSITION_LIFT_RADIUS)
	_restore_route_burn()
	_refresh_cell_materials()
	_set_status_text("新纹理正在重新组合。")

	_apply_focus_rotation(target_yaw, target_pitch, true)
	await _run_transition_lift_phase(_current_stage_route_ids.duplicate(), TRANSITION_LIFT_RADIUS, 0.0, TRANSITION_SETTLE_IN_SEC, 1.0, 1.0, 1.0, 0.0, 0.0, 1.0)
	_finish_route_burn()
	_finish_burn_reveal(next_texture)
	_refresh_route_preview()
	_transition_lift_offsets.clear()
	_transition_color_flash_strength = 0.0
	_pointer_hand_visible_target = true
	_pointer_hand_enter_t = 0.0
	_pointer_hand_alpha = 0.0
	_refresh_cell_materials()
	_set_status_text("按住鼠标，从高亮单元开始沿纹理路径拖拽。")


func _play_final_texture_transition() -> void:
	_set_status_text("最后一段路径显影完成。")
	_pointer_hand_visible_target = false
	await _wait_pointer_hand_exit()
	if _transition_flash_rect != null:
		_transition_flash_rect.visible = false
	_prepare_burn_reveal(null)
	_prepare_route_burn()
	await _run_transition_lift_phase(_current_stage_route_ids.duplicate(), 0.0, TRANSITION_LIFT_RADIUS, TRANSITION_LIFT_OUT_SEC, 0.0, 0.62)
	await _run_transition_color_flash_phase(0.0, 1.0, 0.8)
	await _run_burn_reveal_phase(0.62, 1.0, TRANSITION_FILM_SWITCH_SEC)


func _wait_pointer_hand_exit() -> void:
	while _pointer_hand_enter_t > 0.02:
		await get_tree().process_frame


func _run_transition_lift_phase(
	priority_route: Array,
	from_lift: float,
	to_lift: float,
	duration: float,
	from_burn: float = -1.0,
	to_burn: float = -1.0,
	from_flash: float = -1.0,
	to_flash: float = -1.0,
	from_ash_peel: float = -1.0,
	to_ash_peel: float = -1.0
) -> void:
	var delays := _build_transition_lift_delays(priority_route)
	var elapsed := 0.0
	while elapsed < duration:
		var delta := get_process_delta_time()
		elapsed = minf(duration, elapsed + delta)
		var phase := clampf(elapsed / maxf(0.001, duration), 0.0, 1.0)
		for cell_id_variant in _cell_nodes.keys():
			var cell_id := int(cell_id_variant)
			var delay := float(delays.get(cell_id, 0.0))
			var local_t := clampf((phase - delay) / 0.34, 0.0, 1.0)
			var smooth_t := local_t * local_t * (3.0 - 2.0 * local_t)
			_transition_lift_offsets[cell_id] = lerpf(from_lift, to_lift, smooth_t)
		if from_burn >= 0.0 and to_burn >= 0.0:
			_set_burn_reveal_progress(lerpf(from_burn, to_burn, phase))
		if from_flash >= 0.0 and to_flash >= 0.0:
			_transition_color_flash_strength = lerpf(from_flash, to_flash, phase)
		if from_ash_peel >= 0.0 and to_ash_peel >= 0.0:
			_set_ash_peel_progress(lerpf(from_ash_peel, to_ash_peel, phase))
		_update_texture_surface_motion()
		await get_tree().process_frame
	_set_all_transition_lift_offsets(to_lift)
	if to_burn >= 0.0:
		_set_burn_reveal_progress(to_burn)
	if to_flash >= 0.0:
		_transition_color_flash_strength = to_flash
	if to_ash_peel >= 0.0:
		_set_ash_peel_progress(to_ash_peel)
	_update_texture_surface_motion()


func _build_transition_lift_delays(priority_route: Array) -> Dictionary:
	var route_ids: Array[int] = []
	for id_variant in priority_route:
		route_ids.append(int(id_variant))
	var route_lookup: Dictionary = {}
	for cell_id in route_ids:
		route_lookup[cell_id] = true
	var distance_map := _build_distance_map(route_ids)
	var delays: Dictionary = {}
	for cell_id_variant in _cell_nodes.keys():
		var cell_id := int(cell_id_variant)
		var hash := _hash_cell(cell_id)
		if route_lookup.has(cell_id):
			var route_index := maxi(0, route_ids.find(cell_id))
			var route_batch := floorf(float(route_index) / 3.0)
			delays[cell_id] = clampf(route_batch * 0.12 + hash * 0.018, 0.0, 0.34)
		else:
			var dist := float(distance_map.get(cell_id, 6))
			var group := floorf(hash * 5.0) / 5.0
			delays[cell_id] = clampf(0.24 + dist * 0.055 + group * 0.18, 0.24, 0.66)
	return delays


func _set_all_transition_lift_offsets(value: float) -> void:
	for cell_id_variant in _cell_nodes.keys():
		_transition_lift_offsets[int(cell_id_variant)] = value


func _prepare_burn_reveal(next_texture: Texture2D) -> void:
	_setup_burn_reveal_origins()
	_set_burn_reveal_progress(0.0)
	_set_ash_peel_progress(0.0)
	if _burn_heat_rect != null:
		_burn_heat_rect.visible = false
	if _ash_fragment_overlay != null:
		_ash_fragment_overlay.prepare(_get_current_burn_origins())
	if _stage_image_next_rect != null:
		_stage_image_next_rect.texture = next_texture
		_stage_image_next_rect.material = _create_film_material()
		_stage_image_next_rect.visible = next_texture != null
	if _stage_image_rect != null and _stage_image_burn_material != null:
		_stage_image_rect.material = _stage_image_burn_material


func _finish_burn_reveal(next_texture: Texture2D) -> void:
	if _stage_image_rect != null:
		_stage_image_rect.texture = next_texture
		_stage_image_rect.visible = next_texture != null
		_stage_image_rect.material = _stage_image_material
	if _stage_image_next_rect != null:
		_stage_image_next_rect.visible = false
		_stage_image_next_rect.texture = null
		_stage_image_next_rect.material = _stage_image_wipe_material
	if _burn_heat_rect != null:
		_burn_heat_rect.visible = false
	if _ash_fragment_overlay != null:
		_ash_fragment_overlay.clear_ash()
	_set_burn_reveal_progress(0.0)
	_set_ash_peel_progress(0.0)


func _prepare_route_burn() -> void:
	_transition_burn_route_points = PackedVector2Array()
	_transition_burn_route_closed = false
	line_canvas.visible = false
	line_canvas.clear_lines()
	var pixel_points := _preview_points_to_pixels(_current_preview_uvs)
	var active_points := _build_active_preview_points(pixel_points)
	if active_points.size() < 2:
		if _route_burn_canvas != null:
			_route_burn_canvas.clear_route()
			_route_burn_canvas.visible = false
		return
	_transition_burn_route_points = active_points
	_transition_burn_route_closed = _current_route_guide_closed
	if _route_burn_canvas != null:
		_route_burn_canvas.set_route(active_points, _current_route_guide_closed, _get_current_burn_origins())
		_route_burn_canvas.set_burn_progress(0.0)
		_route_burn_canvas.visible = true
	if _ash_fragment_overlay != null:
		_ash_fragment_overlay.move_to_front()
	if _route_burn_canvas != null:
		_route_burn_canvas.move_to_front()


func _restore_route_burn() -> void:
	if _transition_burn_route_points.size() < 2:
		return
	line_canvas.visible = false
	line_canvas.clear_lines()
	if _route_burn_canvas != null:
		_route_burn_canvas.set_route(_transition_burn_route_points, _transition_burn_route_closed, _get_current_burn_origins())
		_route_burn_canvas.set_burn_progress(_get_burn_reveal_progress())
		_route_burn_canvas.visible = true
	if _ash_fragment_overlay != null:
		_ash_fragment_overlay.move_to_front()
	if _route_burn_canvas != null:
		_route_burn_canvas.move_to_front()


func _finish_route_burn() -> void:
	line_canvas.set_burn_progress(-1.0, false)
	line_canvas.visible = true
	_transition_burn_route_points = PackedVector2Array()
	_transition_burn_route_closed = false
	if _route_burn_canvas != null:
		_route_burn_canvas.clear_route()
		_route_burn_canvas.visible = false


func _run_burn_reveal_phase(from_progress: float, to_progress: float, duration: float) -> void:
	var elapsed := 0.0
	while elapsed < duration:
		var delta := get_process_delta_time()
		elapsed = minf(duration, elapsed + delta)
		var t := clampf(elapsed / maxf(0.001, duration), 0.0, 1.0)
		var smooth_t := t * t * (3.0 - 2.0 * t)
		_set_burn_reveal_progress(lerpf(from_progress, to_progress, smooth_t))
		await get_tree().process_frame
	_set_burn_reveal_progress(to_progress)


func _run_transition_color_flash_phase(
	from_strength: float,
	to_strength: float,
	duration: float,
	from_burn: float = -1.0,
	to_burn: float = -1.0
) -> void:
	var elapsed := 0.0
	while elapsed < duration:
		var delta := get_process_delta_time()
		elapsed = minf(duration, elapsed + delta)
		var t := clampf(elapsed / maxf(0.001, duration), 0.0, 1.0)
		var smooth_t := t * t * (3.0 - 2.0 * t)
		_transition_color_flash_strength = lerpf(from_strength, to_strength, smooth_t)
		if from_burn >= 0.0 and to_burn >= 0.0:
			_set_burn_reveal_progress(lerpf(from_burn, to_burn, smooth_t))
		_update_texture_surface_motion()
		await get_tree().process_frame
	_transition_color_flash_strength = to_strength
	if to_burn >= 0.0:
		_set_burn_reveal_progress(to_burn)
	_update_texture_surface_motion()


func _set_burn_reveal_progress(progress: float) -> void:
	var clamped_progress := clampf(progress, 0.0, 1.0)
	_transition_burn_progress = clamped_progress
	if _stage_image_burn_material == null:
		return
	_stage_image_burn_material.set_shader_parameter("burn_progress", clamped_progress)
	if _burn_heat_material != null:
		_burn_heat_material.set_shader_parameter("burn_progress", clamped_progress)
	if _route_burn_canvas != null:
		_route_burn_canvas.set_burn_progress(clamped_progress)
	if _ash_fragment_overlay != null:
		_ash_fragment_overlay.set_burn_progress(clamped_progress)


func _set_ash_peel_progress(progress: float) -> void:
	var clamped_progress := clampf(progress, 0.0, 1.0)
	if _burn_heat_material != null:
		_burn_heat_material.set_shader_parameter("ash_peel_progress", 0.0)
	if _ash_fragment_overlay != null:
		_ash_fragment_overlay.set_fall_progress(clamped_progress)
		_ash_fragment_overlay.move_to_front()


func _get_burn_reveal_progress() -> float:
	return _transition_burn_progress


func _get_current_burn_origins() -> Array[Vector2]:
	var template := _current_preview_uvs
	if template.is_empty():
		template = _stage_data[_current_stage_index].get("preview_template", PackedVector2Array()) as PackedVector2Array
	if template.is_empty():
		return [
			Vector2(0.45, 0.5),
			Vector2(0.62, 0.42),
			Vector2(0.52, 0.58),
			Vector2(0.38, 0.55),
			Vector2(0.56, 0.47),
			Vector2(0.70, 0.38),
			Vector2(0.48, 0.64),
		]
	var sample_count := template.size()
	return [
		template[0],
		template[clampi(roundi(float(sample_count - 1) * 0.16), 0, sample_count - 1)],
		template[clampi(roundi(float(sample_count - 1) * 0.33), 0, sample_count - 1)],
		template[clampi(roundi(float(sample_count - 1) * 0.50), 0, sample_count - 1)],
		template[clampi(roundi(float(sample_count - 1) * 0.66), 0, sample_count - 1)],
		template[clampi(roundi(float(sample_count - 1) * 0.83), 0, sample_count - 1)],
		template[sample_count - 1],
	]


func _setup_burn_reveal_origins() -> void:
	if _stage_image_burn_material == null:
		return
	var origins := _get_current_burn_origins()
	var origin_a := origins[0]
	var origin_b := origins[1]
	var origin_c := origins[2]
	var origin_d := origins[3]
	var origin_e := origins[4]
	var origin_f := origins[5]
	var origin_g := origins[6]
	_stage_image_burn_material.set_shader_parameter("origin_a", origin_a)
	_stage_image_burn_material.set_shader_parameter("origin_b", origin_b)
	_stage_image_burn_material.set_shader_parameter("origin_c", origin_c)
	_stage_image_burn_material.set_shader_parameter("origin_d", origin_d)
	_stage_image_burn_material.set_shader_parameter("origin_e", origin_e)
	_stage_image_burn_material.set_shader_parameter("origin_f", origin_f)
	_stage_image_burn_material.set_shader_parameter("origin_g", origin_g)
	_set_burn_heat_origins(origin_a, origin_d, origin_g)


func _set_burn_heat_origins(origin_a: Vector2, origin_b: Vector2, origin_c: Vector2) -> void:
	if _burn_heat_material == null:
		return
	_burn_heat_material.set_shader_parameter("origin_a", origin_a)
	_burn_heat_material.set_shader_parameter("origin_b", origin_b)
	_burn_heat_material.set_shader_parameter("origin_c", origin_c)


func _run_transition_flash_phase(from_progress: float, to_progress: float, duration: float) -> void:
	var elapsed := 0.0
	while elapsed < duration:
		var delta := get_process_delta_time()
		elapsed = minf(duration, elapsed + delta)
		var t := clampf(elapsed / maxf(0.001, duration), 0.0, 1.0)
		var smooth_t := t * t * (3.0 - 2.0 * t)
		var progress := lerpf(from_progress, to_progress, smooth_t)
		var intensity := clampf(0.35 + progress * 1.25, 0.0, 1.65)
		if to_progress < from_progress:
			intensity = progress * 1.15
		_set_transition_flash(progress, intensity)
		await get_tree().process_frame


func _set_transition_flash(progress: float, intensity: float) -> void:
	if _transition_flash_material == null:
		return
	_transition_flash_material.set_shader_parameter("progress", clampf(progress, 0.0, 1.0))
	_transition_flash_material.set_shader_parameter("intensity", clampf(intensity, 0.0, 2.0))


func _setup_transition_flash_origins() -> void:
	if _transition_flash_material == null:
		return
	var template := _current_preview_uvs
	if template.is_empty():
		template = _stage_data[_current_stage_index].get("preview_template", PackedVector2Array()) as PackedVector2Array
	if template.is_empty():
		_transition_flash_material.set_shader_parameter("origin_a", Vector2(0.45, 0.5))
		_transition_flash_material.set_shader_parameter("origin_b", Vector2(0.62, 0.42))
		_transition_flash_material.set_shader_parameter("origin_c", Vector2(0.52, 0.58))
		return
	var first := template[0]
	var middle := template[int(template.size() / 2)]
	var last := template[template.size() - 1]
	_transition_flash_material.set_shader_parameter("origin_a", first)
	_transition_flash_material.set_shader_parameter("origin_b", middle)
	_transition_flash_material.set_shader_parameter("origin_c", last)


func _play_hand_wipe_to_stage(next_stage_index: int) -> void:
	var next_stage := _stage_data[next_stage_index]
	var next_texture := _load_stage_texture(next_stage)
	_hand_rect.visible = true
	_place_hand_for_wipe(0.0)
	if _stage_image_next_rect != null:
		_stage_image_next_rect.texture = next_texture
		_stage_image_next_rect.visible = next_texture != null
	if _stage_image_wipe_material != null:
		_stage_image_wipe_material.set_shader_parameter("reveal_progress", 0.0)

	var switched_left := false
	var elapsed := 0.0
	while elapsed < hand_wipe_duration_sec:
		var delta := get_process_delta_time()
		elapsed = minf(hand_wipe_duration_sec, elapsed + delta)
		var t := clampf(elapsed / maxf(0.001, hand_wipe_duration_sec), 0.0, 1.0)
		var smooth_t := t * t * (3.0 - 2.0 * t)
		if _stage_image_wipe_material != null:
			_stage_image_wipe_material.set_shader_parameter("reveal_progress", smooth_t)
		_place_hand_for_wipe(smooth_t)
		left_3d.modulate.a = clampf(absf(smooth_t - 0.5) * 2.0, 0.0, 1.0)
		if not switched_left and smooth_t >= 0.5:
			switched_left = true
			_suppress_stage_image_refresh = true
			_apply_stage(next_stage_index, true)
			_suppress_stage_image_refresh = false
		await get_tree().process_frame

	if not switched_left:
		_suppress_stage_image_refresh = true
		_apply_stage(next_stage_index, true)
		_suppress_stage_image_refresh = false
	left_3d.modulate.a = 1.0
	if _stage_image_rect != null:
		_stage_image_rect.texture = next_texture
		_stage_image_rect.visible = next_texture != null
	if _stage_image_next_rect != null:
		_stage_image_next_rect.visible = false
		_stage_image_next_rect.texture = null
	if _stage_image_wipe_material != null:
		_stage_image_wipe_material.set_shader_parameter("reveal_progress", 0.0)
	_hand_rect.visible = false
	_set_status_text("擦除完成，进入下一张纹理。")


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
	_set_status_text("三段路径完成，准备进入下一关。")


func _place_hand_at_start() -> void:
	var panel_size := right_panel.size
	_hand_rect.size = Vector2(panel_size.x * 0.62, panel_size.y * 0.82)
	_hand_rect.pivot_offset = _hand_rect.size * 0.5
	_hand_rect.position = Vector2(panel_size.x * 1.10, -panel_size.y * 0.18)
	_hand_rect.rotation_degrees = -31.0
	_hand_rect.scale = Vector2.ONE


func _place_hand_for_wipe(progress: float) -> void:
	var panel_size := right_panel.size
	var t := clampf(progress, 0.0, 1.0)
	_hand_rect.size = Vector2(panel_size.x * 0.72, panel_size.y * 1.05)
	_hand_rect.pivot_offset = _hand_rect.size * 0.5
	var contact := smoothstep(0.04, 0.20, t) * (1.0 - smoothstep(0.82, 1.0, t))
	var exit_push := smoothstep(0.74, 1.0, t)
	var x := lerpf(-panel_size.x * 0.52, panel_size.x * 1.14, t)
	x += sin(t * PI * 1.35 + 0.45) * panel_size.x * 0.035 * contact
	var y := panel_size.y * 0.54
	y += sin(t * PI) * panel_size.y * 0.09
	y += sin(t * PI * 4.0) * panel_size.y * 0.018 * contact
	y -= exit_push * panel_size.y * 0.10
	_hand_rect.position = Vector2(x, y - _hand_rect.size.y * 0.52)
	_hand_rect.rotation_degrees = lerpf(-18.0, 15.0, t) + sin(t * PI * 2.2) * 6.0 * contact
	var pressure := 1.0 + sin(t * PI) * 0.035 * contact
	_hand_rect.scale = Vector2(pressure, 1.0 - (pressure - 1.0) * 0.45)


func _update_pointer_hand(delta: float) -> void:
	if _pointer_hand_rect == null:
		return
	var pointer_texture := _load_pointer_hand_texture()
	if pointer_texture == null:
		_pointer_hand_rect.visible = false
		return
	if _pointer_hand_rect.texture == null:
		_pointer_hand_rect.texture = pointer_texture

	var panel_size := right_panel.size
	var texture_size := pointer_texture.get_size()
	var aspect := texture_size.y / maxf(1.0, texture_size.x)
	var hand_height := clampf(panel_size.y * 1.14, 520.0, 860.0)
	var hand_width := hand_height / maxf(0.001, aspect)
	_pointer_hand_rect.size = Vector2(hand_width, hand_height)
	_pointer_hand_rect.pivot_offset = _pointer_hand_rect.size * 0.5

	var tip_local := _pointer_hand_rect.size * POINTER_HAND_TIP_UV
	var tip_point := _get_current_preview_pointer_point()
	if tip_point != Vector2.INF:
		_pointer_hand_target_pos = tip_point

	var target_visible := _pointer_hand_visible_target and _pointer_hand_target_pos != Vector2.ZERO
	var target_enter_t := 1.0 if target_visible else 0.0
	var enter_speed := 4.8 if target_visible else 3.2
	_pointer_hand_enter_t = move_toward(_pointer_hand_enter_t, target_enter_t, delta * enter_speed)
	var smooth_enter_t := _pointer_hand_enter_t * _pointer_hand_enter_t * (3.0 - 2.0 * _pointer_hand_enter_t)
	_pointer_hand_alpha = smooth_enter_t

	if _pointer_hand_enter_t <= 0.01 and not target_visible:
		_pointer_hand_rect.visible = false
		return

	_pointer_hand_rect.visible = true
	var target_rotation := _get_pointer_hand_rotation_for_target(_pointer_hand_target_pos, _pointer_hand_rect.size)
	var rotation_follow_t := 1.0 - pow(0.00004, delta)
	_pointer_hand_rect.rotation = lerp_angle(_pointer_hand_rect.rotation, target_rotation, rotation_follow_t)
	var pivot := _pointer_hand_rect.pivot_offset
	var base_position := _pointer_hand_target_pos - pivot - (tip_local - pivot).rotated(_pointer_hand_rect.rotation)
	var exit_vector := _get_pointer_hand_exit_vector(_pointer_hand_target_pos, _pointer_hand_rect.size)
	_pointer_hand_rect.position = base_position + exit_vector * (1.0 - smooth_enter_t)
	_pointer_hand_rect.modulate = Color(1.0, 1.0, 1.0, _pointer_hand_alpha)
	if _hand_pointer_material != null:
		_hand_pointer_material.set_shader_parameter("shimmer", _pointer_hand_alpha)


func _get_pointer_hand_rotation_for_target(target: Vector2, hand_size: Vector2) -> float:
	var desired_vector := _get_pointer_hand_wrist_vector(target, hand_size)
	if desired_vector.length_squared() <= 0.001:
		return 0.0

	var tip_local := hand_size * POINTER_HAND_TIP_UV
	var wrist_local := hand_size * POINTER_HAND_WRIST_UV
	var local_tip_to_wrist := wrist_local - tip_local
	if local_tip_to_wrist.length_squared() <= 0.001:
		return 0.0
	return desired_vector.angle() - local_tip_to_wrist.angle()


func _get_pointer_hand_exit_vector(target: Vector2, hand_size: Vector2) -> Vector2:
	var wrist_vector := _get_pointer_hand_wrist_vector(target, hand_size)
	if wrist_vector.length_squared() <= 0.001:
		return Vector2(0.0, hand_size.y * 0.38)
	return wrist_vector.normalized() * maxf(180.0, hand_size.y * 0.30)


func _get_pointer_hand_wrist_vector(target: Vector2, hand_size: Vector2) -> Vector2:
	var panel_size := right_panel.size
	if panel_size.x <= 1.0 or panel_size.y <= 1.0:
		return Vector2.DOWN
	var x_ratio := clampf(target.x / panel_size.x, 0.0, 1.0)
	var bottom_y := panel_size.y + hand_size.y * 0.24
	var outside_x := lerpf(panel_size.x * 0.40, panel_size.x * 0.60, x_ratio)
	if x_ratio < 0.24:
		outside_x = -hand_size.x * 0.22
	elif x_ratio > 0.76:
		outside_x = panel_size.x + hand_size.x * 0.22
	var desired_wrist := Vector2(outside_x, bottom_y)
	return desired_wrist - target


func _load_pointer_hand_texture() -> Texture2D:
	if _hand_pointer_texture != null:
		return _hand_pointer_texture
	var image := Image.new()
	var error := image.load(ProjectSettings.globalize_path(HAND_POINTER_TEXTURE_PATH))
	if error != OK:
		push_warning("Missing tracing hand pointer texture: %s" % HAND_POINTER_TEXTURE_PATH)
		return null
	_hand_pointer_texture = ImageTexture.create_from_image(image)
	return _hand_pointer_texture


func _get_current_preview_pointer_point() -> Vector2:
	if _current_preview_uvs.is_empty():
		return Vector2.INF
	var pixel_points := _preview_points_to_pixels(_current_preview_uvs)
	if pixel_points.is_empty():
		return Vector2.INF
	var active_points := _build_active_preview_points(pixel_points)
	if active_points.is_empty():
		return Vector2.INF
	return active_points[active_points.size() - 1]


func _get_visual_route_progress() -> float:
	var progress := float(_selected_route_ids.size())
	if _rollback_active and _rollback_fading_cell_id >= 0:
		var rollback_t := clampf(_rollback_elapsed / maxf(0.001, rollback_step_sec), 0.0, 1.0)
		if _rollback_fading_committed:
			progress = maxf(0.0, float(_selected_route_ids.size()) - rollback_t)
		else:
			progress = float(_selected_route_ids.size()) + (1.0 - rollback_t) * 0.5
	elif _drag_active and _charging_cell_id >= 0:
		var charge_t := clampf(_charge_elapsed / maxf(0.001, cell_hold_sec), 0.0, 1.0)
		progress = float(_selected_route_ids.size()) + charge_t
	return clampf(progress, 0.0, float(maxi(0, _current_preview_uvs.size() - 1)))


func _sample_pixel_route_at_progress(pixel_points: PackedVector2Array, progress: float) -> Vector2:
	if pixel_points.size() == 1:
		return pixel_points[0]
	var clamped_progress := clampf(progress, 0.0, float(pixel_points.size() - 1))
	var from_index := clampi(int(floor(clamped_progress)), 0, pixel_points.size() - 1)
	var to_index := clampi(from_index + 1, 0, pixel_points.size() - 1)
	var frac := clamped_progress - float(from_index)
	return pixel_points[from_index].lerp(pixel_points[to_index], frac)


func _load_stage_texture(stage: Dictionary) -> Texture2D:
	var image_path := String(stage.get("image_path", ""))
	if image_path.is_empty():
		return null
	return load(image_path) as Texture2D


func _refresh_route_preview() -> void:
	if _current_preview_uvs.is_empty() and _current_route_guide_uvs.is_empty():
		if _route_guide_canvas != null:
			_route_guide_canvas.clear_lines()
		line_canvas.clear_lines()
		return

	if _route_guide_canvas != null:
		_route_guide_canvas.clear_lines()

	var pixel_points := _preview_points_to_pixels(_current_preview_uvs)
	var active_points := _build_active_preview_points(pixel_points)
	if active_points.size() < 2:
		line_canvas.clear_lines()
		return

	var closed := _current_route_guide_closed and _selected_route_ids.size() == _current_stage_route_ids.size()
	line_canvas.set_line_points(active_points, closed, 3.15)


func _build_active_preview_points(pixel_points: PackedVector2Array) -> PackedVector2Array:
	if pixel_points.size() < 2:
		return PackedVector2Array()

	var progress := float(_selected_route_ids.size())
	if _rollback_active and _rollback_fading_cell_id >= 0:
		var rollback_t := clampf(_rollback_elapsed / maxf(0.001, rollback_step_sec), 0.0, 1.0)
		if _rollback_fading_committed:
			progress = maxf(0.0, float(_selected_route_ids.size()) - rollback_t)
		else:
			progress = float(_selected_route_ids.size()) + (1.0 - rollback_t) * 0.5
	elif _drag_active and _charging_cell_id >= 0:
		var charge_t := clampf(_charge_elapsed / maxf(0.001, cell_hold_sec), 0.0, 1.0)
		progress = float(_selected_route_ids.size()) + charge_t

	progress = clampf(progress, 0.0, float(pixel_points.size()))
	var full_count := clampi(int(floor(progress)), 0, pixel_points.size())
	var frac := progress - float(full_count)
	var active_points := PackedVector2Array()
	for i in range(full_count):
		active_points.append(pixel_points[i])

	if frac > 0.001 and full_count < pixel_points.size():
		if active_points.is_empty():
			active_points.append(pixel_points[0])
		var from_index := maxi(0, full_count - 1)
		var to_index := full_count
		active_points.append(pixel_points[from_index].lerp(pixel_points[to_index], frac))

	return active_points


func _sample_route_template(template: PackedVector2Array, sample_count: int, closed: bool) -> PackedVector2Array:
	if template.size() < 2 or sample_count <= 0:
		return PackedVector2Array()

	var segment_lengths: Array[float] = []
	var total_length := 0.0
	var segment_count := template.size() if closed else template.size() - 1
	for i in range(segment_count):
		var next_index := (i + 1) % template.size()
		var length := template[i].distance_to(template[next_index])
		segment_lengths.append(length)
		total_length += length

	if total_length <= 0.000001:
		return PackedVector2Array()

	var result := PackedVector2Array()
	for sample_index in range(sample_count):
		var denominator := float(sample_count) if closed else float(maxi(1, sample_count - 1))
		var target_distance := total_length * float(sample_index) / denominator
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
	for uv in uv_points:
		pixel_points.append(Vector2(
			clampf(uv.x, 0.0, 1.0) * canvas_size.x,
			clampf(uv.y, 0.0, 1.0) * canvas_size.y
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
	if _orientation_tween != null and _orientation_tween.is_valid():
		_orientation_tween.kill()
	if not animate:
		_yaw_deg = target_yaw_deg
		_pitch_deg = target_pitch_deg
		_set_model_rotation_from_state()
		return

	_sync_rotation_state_from_model()
	var start_yaw := _yaw_deg
	var start_pitch := _pitch_deg
	var yaw_delta := wrapf(target_yaw_deg - start_yaw, -180.0, 180.0)
	var final_yaw := start_yaw + yaw_delta
	_orientation_tween = create_tween()
	_orientation_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var focus_step := func(t: float) -> void:
		_yaw_deg = lerpf(start_yaw, final_yaw, t)
		_pitch_deg = lerpf(start_pitch, target_pitch_deg, t)
		_set_model_rotation_from_state()
	_orientation_tween.tween_method(focus_step, 0.0, 1.0, TRANSITION_SETTLE_IN_SEC)


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
