extends Control
class_name LevelC3L1

signal chapter_completed(chapter_index: int)

const PAINTING_TEXTURES: Array[Texture2D] = [
	preload("res://assets/ui/chapter_3/left_1.png"),
	preload("res://assets/ui/chapter_3/left_2.png"),
	preload("res://assets/ui/chapter_3/left_3.png"),
]
const PAINT_ROLL_COLOR_TEXTURE: Texture2D = preload("res://assets/ui/chapter_3/giving/right_4_color.png")
const PAINT_ROLL_BW_TEXTURE: Texture2D = preload("res://assets/ui/chapter_3/giving/right_4_bw.png")
const PAINT_ROLL_RIGHT_5_TEXTURE: Texture2D = preload("res://assets/ui/chapter_3/giving/right_5_color.jpg")
const ColorReticleRef = preload("res://scripts/levels/chapter_3/color_reticle.gd")
const InputMappingStateRef = preload("res://scripts/input_mapping_state.gd")
const InputHintOverlayRef = preload("res://scripts/input_hint_overlay.gd")
const LeftHelpPromptOverlayRef = preload("res://scripts/levels/left_help_prompt_overlay.gd")
const MIRROR_LAYER_CONTACT_SEC: float = 8.0

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
@export_range(1.0, 2.4, 0.05) var crack_spread_sec: float = 1.75
@export_range(1.4, 4.5, 0.05) var core_dye_width_scale: float = 3.2
@export_range(10.0, 20.0, 0.1) var final_reveal_sec: float = 12.0
@export_range(0.12, 0.32, 0.005) var paint_roll_ball_screen_scale: float = 0.20
@export_range(0.02, 0.16, 0.002) var paint_roll_brush_radius_uv: float = 0.055
@export_range(0.04, 0.32, 0.005) var paint_roll_speed_uv: float = 0.14
@export_range(0.15, 2.5, 0.01) var paint_roll_acceleration_uv: float = 1.25
@export_range(0.12, 1.8, 0.01) var paint_roll_max_speed_uv: float = 0.92
@export_range(0.05, 4.0, 0.01) var paint_roll_friction_uv: float = 0.52
@export_range(0.1, 0.9, 0.01) var paint_roll_bounce: float = 0.42
@export_range(0.8, 1.8, 0.01) var paint_roll_canvas_zoom: float = 1.22
@export_range(0.5, 0.999, 0.001) var paint_roll_complete_threshold: float = 0.90
@export_range(2.0, 16.0, 0.1) var paint_roll_mirror_wait_sec: float = 10.0
@export_range(2.0, 16.0, 0.1) var paint_roll_mirror_collapse_sec: float = 10.0
@export_range(0.0, 2.5, 0.01) var paint_roll_mirror_slope_force_uv: float = 0.82
@export_range(0.0, 0.8, 0.01) var paint_roll_mirror_tilt_force_uv: float = 0.18
@export_range(0.0, 0.8, 0.01) var paint_roll_mirror_surface_force_uv: float = 0.22
@export_range(0.0, 2.0, 0.01) var paint_roll_mirror_break_kick_uv: float = 1.15
@export_range(0.0, 0.8, 0.01) var paint_roll_mirror_control_loss: float = 0.16
@export_range(24, 72, 1) var shell_latitude_segments: int = 56
@export_range(48, 144, 1) var shell_longitude_segments: int = 112
@export_range(0.01, 0.16, 0.001) var shell_thickness: float = 0.055

@onready var chapter_split: HSplitContainer = $ChapterSplit
@onready var left_3d: SubViewportContainer = $ChapterSplit/Left3D
@onready var left_viewport: SubViewport = $ChapterSplit/Left3D/LeftViewport
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
var _shell_root: Node3D
var _shell_chunks: Array[MeshInstance3D] = []
var _shell_cell_to_chunk: Array[int] = []
var _shell_rebuild_queue: Array[int] = []
var _shell_rebuild_queued: Dictionary = {}
var _shell_chunk_cols: int = 1
var _shell_chunk_rows: int = 1
var _shell_chunk_cell_size: int = 14
var _shell_material: ShaderMaterial
var _shell_cuts: Array[Dictionary] = []
var _shell_cut_cells: Array[bool] = []
var _shell_cell_dirs: Array[Vector3] = []
var _core_mesh: MeshInstance3D
var _core_material: ShaderMaterial
var _core_radius: float = 0.0
var _core_dye_image: Image
var _core_dye_texture: ImageTexture
var _core_dye_mask_size: Vector2i = Vector2i(256, 128)
var _core_dye_queue: Array[Dictionary] = []
var _core_dye_upload_pending: bool = false
var _active_crack_emitters: Array[Dictionary] = []
var _overflow_emit_timer: float = 0.0
var _final_reveal_running: bool = false
var _final_reveal_elapsed: float = 0.0
var _final_break_cursor: int = 0
var _final_break_order: Array[int] = []
var _final_detached_chunks: Dictionary = {}
var _final_detach_tween_count: int = 0
var _core_color_accum: Color = Color(0.0, 0.0, 0.0, 1.0)
var _core_color_count: int = 0
var _core_flow_palette: Array[Color] = []
var _paint_roll_root: Control
var _paint_roll_frame: ColorRect
var _paint_roll_canvas: Control
var _paint_roll_mirror_back: ColorRect
var _paint_roll_bw: TextureRect
var _paint_roll_color: TextureRect
var _paint_roll_trail: TextureRect
var _paint_roll_mirror_overlay: Control
var _paint_roll_mirror_plate: ColorRect
var _paint_roll_mirror: TextureRect
var _paint_roll_mirror_material: ShaderMaterial
var _paint_roll_mirror_piece_root: Control
var _paint_roll_mirror_piece_size: Vector2 = Vector2.ZERO
var _paint_roll_mirror_piece_layers: Array[Control] = []
var _paint_roll_mirror_piece_materials: Array[ShaderMaterial] = []
var _paint_roll_mirror_piece_shards: Array[Array] = []
var _paint_roll_mirror_piece_uv_texture: ImageTexture
var _paint_roll_mirror_crack_root: Control
var _paint_roll_mirror_crack_lines: Array[Dictionary] = []
var _paint_roll_shard_root: Control
var _paint_roll_shards: Array[Dictionary] = []
var _paint_roll_material: ShaderMaterial
var _paint_roll_trail_material: ShaderMaterial
var _paint_roll_mask_image: Image
var _paint_roll_mask_texture: ImageTexture
var _paint_roll_trail_image: Image
var _paint_roll_trail_texture: ImageTexture
var _paint_roll_deposit_image: Image
var _paint_roll_resistance_image: Image
var _paint_roll_mask_size: Vector2i = Vector2i(256, 256)
var _paint_roll_source_image: Image
var _paint_roll_bw_reference_image: Image
var _paint_roll_stage_data: Array[Dictionary] = []
var _paint_roll_stage_index: int = 0
var _paint_roll_view_uv: Vector2 = Vector2(0.5, 0.5)
var _paint_roll_velocity_uv: Vector2 = Vector2.ZERO
var _paint_roll_running: bool = false
var _paint_roll_transitioning: bool = false
var _paint_roll_completion_timer: float = 0.0
var _paint_roll_canvas_size: Vector2 = Vector2.ZERO
var _paint_roll_finished: bool = false
var _paint_roll_stage_transitioning: bool = false
var _paint_roll_mirror_elapsed: float = 0.0
var _paint_roll_mirror_layer_index: int = 0
var _paint_roll_mirror_contact_timer: float = 0.0
var _paint_roll_mirror_breaking: bool = false
var _paint_roll_mirror_collapsing: bool = false
var _paint_roll_mirror_done: bool = false
var _paint_roll_finish_start_uv: Vector2 = Vector2(0.5, 0.5)
var _paint_roll_finish_overview_scale: float = 1.0
var _paint_roll_ball_diameter_px: float = 160.0
var _paint_roll_sphere_fill_ratio: float = 0.52
var _core_drag_vector: Vector2 = Vector2.ZERO
var _core_drag_strength: float = 0.0
var _paint_roll_trail_decay_timer: float = 0.0
var _dev_paint_roll_skip_enabled: bool = false
var _dev_paint_roll_skip_hold_sec: float = 0.0
var _dev_paint_roll_skip_triggered: bool = false
var _left_input_hint_overlay: Control
var _paint_roll_input_hint_overlay: Control
var _left_help_prompt_overlay: LeftHelpPromptOverlay


func _ready() -> void:
	_stage_data = _build_stage_data()
	_paint_roll_stage_data = _build_paint_roll_stage_data()
	_setup_sphere_material()
	_setup_right_panel()
	_setup_fx_layer()
	_setup_paint_roll_scene()
	_ensure_input_hint_overlays()
	_ensure_left_help_prompt_overlay()
	_apply_stage(0, true)


func _process(delta: float) -> void:
	_update_left_color_flow(delta)
	_process_shell_rebuild_queue()
	_process_core_dye_queue()
	_update_crack_overflow_emitters(delta)
	_update_final_shell_reveal(delta)
	_update_dev_paint_roll_skip(delta)
	_update_paint_roll_diffusion(delta)
	_update_paint_roll_trail_decay(delta)
	_update_paint_roll_mirror_stage(delta)
	_update_idle_rotation(delta)
	_update_rotation_and_reticle(delta)
	_update_input_hint_visibility()
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


func _ensure_input_hint_overlays() -> void:
	if _left_input_hint_overlay == null or not is_instance_valid(_left_input_hint_overlay):
		_left_input_hint_overlay = InputHintOverlayRef.new()
		_left_input_hint_overlay.name = "LeftInputHintOverlay"
		_left_input_hint_overlay.set_mode_wasd()
		left_3d.add_child(_left_input_hint_overlay)
		_fit_input_hint_overlay(_left_input_hint_overlay)
	if _paint_roll_root != null and (_paint_roll_input_hint_overlay == null or not is_instance_valid(_paint_roll_input_hint_overlay)):
		_paint_roll_input_hint_overlay = InputHintOverlayRef.new()
		_paint_roll_input_hint_overlay.name = "PaintRollInputHintOverlay"
		_paint_roll_input_hint_overlay.set_mode_wasd()
		_paint_roll_input_hint_overlay.z_index = 120
		_paint_roll_root.add_child(_paint_roll_input_hint_overlay)
		_fit_input_hint_overlay(_paint_roll_input_hint_overlay)
	_update_input_hint_visibility()


func _ensure_left_help_prompt_overlay() -> void:
	if _left_help_prompt_overlay != null and is_instance_valid(_left_help_prompt_overlay):
		return
	_left_help_prompt_overlay = LeftHelpPromptOverlayRef.new()
	_left_help_prompt_overlay.name = "LeftHelpPromptOverlay"
	add_child(_left_help_prompt_overlay)
	_left_help_prompt_overlay.setup(left_3d, left_camera, model_root, left_sphere_radius)
	_left_help_prompt_overlay.inactivity_delay_sec = 10.0
	_left_help_prompt_overlay.hint_fade_in_sec = 5.0
	_left_help_prompt_overlay.set_popup_size(Vector2(460.0, 262.0))
	_left_help_prompt_overlay.set_hint_text_style(24, Color(0.97, 0.97, 0.97, 1.0))
	_left_help_prompt_overlay.set_hint_text("收集散落的染料\n之后涂满房间的经历\n可以尝试一下")


func _fit_input_hint_overlay(overlay: Control) -> void:
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.offset_left = 0.0
	overlay.offset_top = 0.0
	overlay.offset_right = 0.0
	overlay.offset_bottom = 0.0


func _update_input_hint_visibility() -> void:
	var paint_roll_visible := _paint_roll_root != null and is_instance_valid(_paint_roll_root) and _paint_roll_root.visible
	if _left_input_hint_overlay != null and is_instance_valid(_left_input_hint_overlay):
		_left_input_hint_overlay.visible = not paint_roll_visible
	if _paint_roll_input_hint_overlay != null and is_instance_valid(_paint_roll_input_hint_overlay):
		_paint_roll_input_hint_overlay.visible = paint_roll_visible


func _set_dev_paint_roll_skip_enabled(enabled: bool) -> void:
	_dev_paint_roll_skip_enabled = enabled
	_dev_paint_roll_skip_hold_sec = 0.0
	_dev_paint_roll_skip_triggered = false


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


func _build_paint_roll_stage_data() -> Array[Dictionary]:
	return [
		{
			"color_texture": PAINT_ROLL_COLOR_TEXTURE,
			"reference_texture": PAINT_ROLL_BW_TEXTURE,
			"start_uv": Vector2(0.5, 0.5),
		},
		{
			"color_texture": PAINT_ROLL_RIGHT_5_TEXTURE,
			"reference_texture": null,
			"start_uv": Vector2(0.5, 0.5),
		},
		{
			"color_texture": PAINT_ROLL_RIGHT_5_TEXTURE,
			"reference_texture": null,
			"start_uv": Vector2(0.5, 0.5),
			"type": "mirror",
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
	if _paint_roll_running or _paint_roll_transitioning or _paint_roll_finished:
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
	_setup_core_dye_mask()


func _create_color_core_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode blend_mix, cull_back, depth_draw_opaque;

uniform vec4 core_color : source_color = vec4(0.05, 0.055, 0.065, 1.0);
uniform vec4 pulse_color : source_color = vec4(1.0, 0.2, 0.1, 1.0);
uniform sampler2D dye_mask : source_color;
uniform vec4 flow_color_0 : source_color = vec4(0.9, 0.12, 0.08, 1.0);
uniform vec4 flow_color_1 : source_color = vec4(0.1, 0.36, 0.9, 1.0);
uniform vec4 flow_color_2 : source_color = vec4(0.96, 0.72, 0.12, 1.0);
uniform vec4 flow_color_3 : source_color = vec4(0.18, 0.62, 0.34, 1.0);
uniform vec2 drag_vector = vec2(0.0, 0.0);
uniform float drag_strength = 0.0;
uniform float fill_progress = 0.0;
uniform float roll_flow_boost = 0.0;
uniform float pulse_mix = 0.0;
uniform float time = 0.0;

varying vec3 local_pos;

float hash(vec3 p) {
	return fract(sin(dot(p, vec3(31.17, 53.31, 97.77))) * 43758.5453);
}

float wave(vec3 p, float offset) {
	return 0.5 + 0.5 * sin(dot(p, vec3(2.7, 4.1, 3.3)) + offset);
}

float luminance(vec3 color) {
	return dot(color, vec3(0.299, 0.587, 0.114));
}

vec3 quiet_ink_color(vec3 color, float keep_saturation, float value_scale) {
	float luma = luminance(color);
	return mix(vec3(luma), color, keep_saturation) * value_scale;
}

vec2 sphere_uv(vec3 dir) {
	return vec2(fract(atan(dir.z, dir.x) / 6.2831853), acos(clamp(dir.y, -1.0, 1.0)) / 3.1415926);
}

vec2 safe_uv(vec2 uv) {
	return vec2(fract(uv.x), clamp(uv.y, 0.002, 0.998));
}

vec3 palette_flow(vec3 dir) {
	float a = wave(dir, time * 0.32 + wave(dir.zxy, time * -0.21) * 1.7);
	float b = wave(dir.yzx, time * -0.27 + 2.1);
	float c = wave(dir.zxy + vec3(a * 0.12, b * 0.09, 0.0), time * 0.18 - 0.8);
	vec3 first = mix(flow_color_0.rgb, flow_color_1.rgb, smoothstep(0.18, 0.86, a));
	vec3 second = mix(flow_color_2.rgb, flow_color_3.rgb, smoothstep(0.15, 0.88, b));
	return mix(first, second, smoothstep(0.12, 0.92, c));
}

vec2 flow_vector(vec3 dir, float phase) {
	float swirl_a = sin(dir.y * 5.7 + dir.z * 3.2 + phase * 0.83);
	float swirl_b = cos(dir.x * 4.9 - dir.y * 2.6 - phase * 0.67);
	float swirl_c = sin(dot(dir, vec3(3.4, -5.1, 4.2)) + phase);
	return vec2(swirl_a + swirl_c * 0.55, swirl_b - swirl_c * 0.45);
}

vec3 mineralize_color(vec3 color, float band) {
	vec3 vivid = quiet_ink_color(color, 0.92, 0.82);
	vec3 depth_tint = mix(vec3(0.05, 0.045, 0.052), vec3(0.07, 0.085, 0.10), smoothstep(-0.45, 0.55, band));
	return mix(vivid, depth_tint, 0.10);
}

vec4 sample_source_dye_flow(vec2 uv, vec3 dir, float lift) {
	float band = sin(dir.y * 13.0 + sin(dir.y * 5.0) * 0.65);
	vec2 wobble_dir = normalize(vec2(
		sin(dot(dir, vec3(2.8, 5.1, -3.3)) + 1.7),
		cos(dot(dir, vec3(-4.0, 2.7, 3.6)) - 0.4)
	));
	float wobble_phase = sin(time * 0.58 + dot(dir, vec3(3.1, -2.4, 4.6)));
	vec2 wobble = wobble_dir * wobble_phase * mix(0.006, 0.018, lift);
	vec2 drag_dir = drag_vector;
	float drag_len = length(drag_dir);
	if (drag_len > 0.001) {
		drag_dir /= drag_len;
	}
	float pull = clamp(drag_strength, 0.0, 1.0) * lift;
	vec2 trail = drag_dir * pull * 0.48;
	vec2 lift_wobble = wobble * lift;
	vec4 d0 = texture(dye_mask, safe_uv(uv + lift_wobble));
	vec4 d1 = texture(dye_mask, safe_uv(uv + lift_wobble - trail * 0.55));
	vec4 d2 = texture(dye_mask, safe_uv(uv + lift_wobble - trail * 1.15));
	vec4 d3 = texture(dye_mask, safe_uv(uv + lift_wobble - trail * 1.95));
	vec4 d4 = texture(dye_mask, safe_uv(uv - lift_wobble * 0.65 + trail * 0.32));
	vec4 d5 = texture(dye_mask, safe_uv(uv + wobble_dir.yx * vec2(-1.0, 1.0) * 0.018 * lift));
	vec4 d6 = texture(dye_mask, safe_uv(uv - wobble_dir.yx * vec2(-1.0, 1.0) * 0.024 * lift));
	float w0 = d0.a * mix(2.8, 1.25, lift);
	float w1 = d1.a * mix(0.45, 1.75, pull);
	float w2 = d2.a * mix(0.22, 1.55, pull);
	float w3 = d3.a * mix(0.08, 1.18, pull);
	float w4 = d4.a * mix(0.24, 0.86, pull);
	float w5 = d5.a * mix(0.42, 0.72, pull);
	float w6 = d6.a * mix(0.34, 0.62, pull);
	float weight = w0 + w1 + w2 + w3 + w4 + w5 + w6;
	if (weight <= 0.001) {
		return vec4(0.0);
	}
	vec3 color = (d0.rgb * w0 + d1.rgb * w1 + d2.rgb * w2 + d3.rgb * w3 + d4.rgb * w4 + d5.rgb * w5 + d6.rgb * w6) / weight;
	color = mineralize_color(color, band);
	float alpha = clamp(weight / mix(2.2, 4.6, lift), 0.0, 1.0);
	return vec4(color, alpha);
}

vec4 sample_flowing_dye(vec2 uv, vec3 dir, float spread) {
	vec2 drift_a = vec2(
		sin(time * 0.19 + dir.y * 4.3 + dir.z * 2.1),
		cos(time * 0.16 + dir.x * 3.7 - dir.y * 1.8)
	) * spread;
	vec2 drift_b = vec2(
		cos(time * 0.13 - dir.z * 3.8 + dir.x * 1.4),
		sin(time * 0.15 + dir.y * 2.5 + 1.7)
	) * spread * 0.72;
	vec4 d0 = texture(dye_mask, safe_uv(uv));
	vec4 d1 = texture(dye_mask, safe_uv(uv + drift_a));
	vec4 d2 = texture(dye_mask, safe_uv(uv - drift_a * 0.78));
	vec4 d3 = texture(dye_mask, safe_uv(uv + drift_b));
	vec4 d4 = texture(dye_mask, safe_uv(uv - drift_b * 1.18));
	float weight = d0.a * 1.55 + d1.a + d2.a + d3.a * 0.82 + d4.a * 0.82;
	if (weight <= 0.001) {
		return vec4(0.0);
	}
	vec3 color = (
		d0.rgb * d0.a * 1.55 +
		d1.rgb * d1.a +
		d2.rgb * d2.a +
		d3.rgb * d3.a * 0.82 +
		d4.rgb * d4.a * 0.82
	) / weight;
	return vec4(color, clamp(weight / 3.2, 0.0, 1.0));
}

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	vec3 dir = normalize(local_pos);
	vec2 dye_uv = sphere_uv(dir);
	vec4 dye = texture(dye_mask, dye_uv);
	float progress = smoothstep(0.0, 1.0, fill_progress);
	float source_lift = clamp(max(smoothstep(0.52, 1.0, progress), roll_flow_boost), 0.0, 1.0);
	float liquid = max(smoothstep(0.10, 0.82, progress), source_lift * 0.92);
	float spread = mix(0.002, 0.074, liquid);
	vec4 source_flow = sample_source_dye_flow(dye_uv, dir, source_lift);
	vec4 flowing_dye = sample_flowing_dye(dye_uv, dir, spread);
	flowing_dye.rgb = mix(flowing_dye.rgb, source_flow.rgb, source_flow.a);
	flowing_dye.a = max(flowing_dye.a, source_flow.a);
	vec3 palette = palette_flow(dir);
	float grain = hash(floor((dir + vec3(time * 0.035, -time * 0.024, time * 0.029)) * mix(28.0, 34.0, roll_flow_boost)));
	float fresnel = pow(1.0 - clamp(dot(normalize(NORMAL), VIEW), 0.0, 1.0), 2.1);
	vec3 deep_base = vec3(0.014, 0.015, 0.018);
	vec3 pulse_tint = quiet_ink_color(pulse_color.rgb, 0.48, 0.34);
	vec3 base_color = mix(deep_base, pulse_tint, pulse_mix * 0.10);
	float band_value = sin(dir.y * 13.0 + sin(dir.y * 5.0) * 0.65);
	vec3 quiet_dye = mineralize_color(dye.rgb, band_value);
	vec3 quiet_flow = mineralize_color(flowing_dye.rgb, band_value);
	vec3 quiet_palette = mineralize_color(palette, band_value) * 0.92;
	vec3 anchored_color = mix(base_color, quiet_dye, clamp(dye.a, 0.0, 1.0));
	vec3 advected_color = mix(anchored_color, quiet_flow, flowing_dye.a * liquid);
	float late_fill = smoothstep(0.34, 1.0, progress);
	float seeded_fill = smoothstep(0.16, 0.92, late_fill + source_flow.a * 0.85);
	float open_coverage = max(dye.a, max(flowing_dye.a * liquid, seeded_fill));
	vec3 quiet_source = source_flow.rgb;
	vec3 seeded_color = mix(quiet_palette, quiet_source, source_flow.a);
	vec3 filled_color = mix(advected_color, seeded_color, max(0.0, seeded_fill - dye.a * 0.38));
	vec3 lifted_flow = mix(filled_color, mix(filled_color, seeded_color, 0.28 + flowing_dye.a * 0.24), source_lift * 0.68);
	vec3 color = mix(base_color, lifted_flow, clamp(open_coverage + source_lift * 0.38, 0.0, 1.0));
	float cloud_band = 0.90 + band_value * 0.045 + sin(dir.y * 29.0 + time * 0.05) * 0.018;
	float contrast = mix(0.82 + grain * 0.020, cloud_band, source_lift);
	ALBEDO = color * contrast;
	ROUGHNESS = 0.58;
	METALLIC = 0.0;
	float source_glow = clamp(source_flow.a * 0.16 + dye.a * 0.08, 0.0, 0.22);
	EMISSION = color * (0.06 + fresnel * 0.16 + pulse_mix * 0.10 + source_glow);
	ALPHA = 1.0;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("core_color", Color(0.045, 0.05, 0.06, 1.0))
	material.set_shader_parameter("pulse_color", Color(1.0, 0.2, 0.1, 1.0))
	material.set_shader_parameter("flow_color_0", Color(0.9, 0.12, 0.08, 1.0))
	material.set_shader_parameter("flow_color_1", Color(0.1, 0.36, 0.9, 1.0))
	material.set_shader_parameter("flow_color_2", Color(0.96, 0.72, 0.12, 1.0))
	material.set_shader_parameter("flow_color_3", Color(0.18, 0.62, 0.34, 1.0))
	material.set_shader_parameter("drag_vector", Vector2.ZERO)
	material.set_shader_parameter("drag_strength", 0.0)
	material.set_shader_parameter("fill_progress", 0.0)
	material.set_shader_parameter("roll_flow_boost", 0.0)
	material.set_shader_parameter("pulse_mix", 0.0)
	material.set_shader_parameter("time", 0.0)
	return material


func _setup_core_dye_mask() -> void:
	_core_dye_image = Image.create(_core_dye_mask_size.x, _core_dye_mask_size.y, false, Image.FORMAT_RGBA8)
	_core_dye_image.fill(Color(0.0, 0.0, 0.0, 0.0))
	_core_dye_texture = ImageTexture.create_from_image(_core_dye_image)
	if _core_material != null:
		_core_material.set_shader_parameter("dye_mask", _core_dye_texture)


func _setup_cracked_shell() -> void:
	_shell_cuts.clear()
	_build_shell_cell_cache()
	_shell_material = _create_shell_material()
	_shell_root = Node3D.new()
	_shell_root.name = "CrackedShellChunks"
	model_root.add_child(_shell_root)
	_setup_shell_chunks()
	_rebuild_cracked_shell()


func _build_shell_cell_cache() -> void:
	var cell_count: int = shell_latitude_segments * shell_longitude_segments
	_shell_cut_cells.clear()
	_shell_cut_cells.resize(cell_count)
	_shell_cell_dirs.clear()
	_shell_cell_dirs.resize(cell_count)
	_shell_cell_to_chunk.clear()
	_shell_cell_to_chunk.resize(cell_count)
	_shell_chunk_cols = ceili(float(shell_longitude_segments) / float(_shell_chunk_cell_size))
	_shell_chunk_rows = ceili(float(shell_latitude_segments) / float(_shell_chunk_cell_size))
	for y in range(shell_latitude_segments):
		var theta: float = PI * (float(y) + 0.5) / float(shell_latitude_segments)
		for x in range(shell_longitude_segments):
			var phi: float = TAU * (float(x) + 0.5) / float(shell_longitude_segments)
			var index: int = _shell_cell_index(y, x)
			_shell_cut_cells[index] = false
			_shell_cell_dirs[index] = _spherical_dir(theta, phi)
			_shell_cell_to_chunk[index] = _shell_chunk_index_for_cell(y, x)


func _setup_shell_chunks() -> void:
	_shell_chunks.clear()
	var chunk_count: int = _shell_chunk_rows * _shell_chunk_cols
	for chunk_index in range(chunk_count):
		var chunk := MeshInstance3D.new()
		chunk.name = "CrackedShellChunk_%03d" % chunk_index
		chunk.material_override = _shell_material
		_shell_root.add_child(chunk)
		_shell_chunks.append(chunk)


func _create_shell_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode cull_back, depth_draw_opaque;

void fragment() {
	float wall = clamp(COLOR.r, 0.0, 1.0);
	float inner = clamp(COLOR.g, 0.0, 1.0);
	vec3 outer_color = vec3(0.014, 0.013, 0.016);
	vec3 inner_color = vec3(0.006, 0.006, 0.008);
	vec3 wall_color = vec3(0.018, 0.015, 0.020);
	vec3 color = mix(outer_color, inner_color, inner);
	color = mix(color, wall_color, wall);
	ALBEDO = color;
	ROUGHNESS = mix(0.88, 0.97, wall);
	METALLIC = 0.025;
	EMISSION = vec3(0.012, 0.015, 0.020) + vec3(0.030, 0.045, 0.065) * wall;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	return material


func _rebuild_cracked_shell() -> void:
	for chunk_index in range(_shell_chunks.size()):
		_rebuild_shell_chunk(chunk_index)


func _rebuild_shell_chunk(chunk_index: int) -> void:
	if chunk_index < 0 or chunk_index >= _shell_chunks.size():
		return
	var chunk := _shell_chunks[chunk_index]
	if chunk == null or not is_instance_valid(chunk):
		return
	chunk.mesh = _build_shell_chunk_mesh(chunk_index)


func _rebuild_shell_chunks(chunk_indices: Array[int]) -> void:
	for chunk_index in chunk_indices:
		_enqueue_shell_chunk_rebuild(chunk_index)


func _enqueue_shell_chunk_rebuild(chunk_index: int) -> void:
	if chunk_index < 0 or chunk_index >= _shell_chunks.size():
		return
	if bool(_shell_rebuild_queued.get(chunk_index, false)):
		return
	_shell_rebuild_queued[chunk_index] = true
	_shell_rebuild_queue.append(chunk_index)


func _process_shell_rebuild_queue() -> void:
	var budget: int = 1
	while budget > 0 and not _shell_rebuild_queue.is_empty():
		var chunk_index: int = int(_shell_rebuild_queue.pop_front())
		_shell_rebuild_queued.erase(chunk_index)
		_rebuild_shell_chunk(chunk_index)
		budget -= 1


func _build_shell_chunk_mesh(chunk_index: int) -> ArrayMesh:
	var vertices: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	var colors: PackedColorArray = PackedColorArray()
	var indices: PackedInt32Array = PackedInt32Array()
	var chunk_col: int = chunk_index % _shell_chunk_cols
	var chunk_row: int = int(chunk_index / _shell_chunk_cols)
	var y0: int = chunk_row * _shell_chunk_cell_size
	var y1: int = mini(shell_latitude_segments, y0 + _shell_chunk_cell_size)
	var x0: int = chunk_col * _shell_chunk_cell_size
	var x1: int = mini(shell_longitude_segments, x0 + _shell_chunk_cell_size)

	for y in range(y0, y1):
		for x in range(x0, x1):
			if _is_shell_cell_cut(y, x):
				continue
			var d00: Vector3 = _grid_shell_dir(y, x)
			var d10: Vector3 = _grid_shell_dir(y, x + 1)
			var d01: Vector3 = _grid_shell_dir(y + 1, x)
			var d11: Vector3 = _grid_shell_dir(y + 1, x + 1)
			_append_shell_quad(vertices, normals, uvs, colors, indices, d00, d10, d11, d01, left_sphere_radius, true)
			_append_shell_quad(vertices, normals, uvs, colors, indices, d01, d11, d10, d00, left_sphere_radius - shell_thickness, false)

			if _is_shell_cell_cut(y, x - 1):
				_append_shell_wall(vertices, normals, uvs, colors, indices, d00, d01)
			if _is_shell_cell_cut(y, x + 1):
				_append_shell_wall(vertices, normals, uvs, colors, indices, d10, d11)
			if y == 0 or _is_shell_cell_cut(y - 1, x):
				_append_shell_wall(vertices, normals, uvs, colors, indices, d00, d10)
			if y == shell_latitude_segments - 1 or _is_shell_cell_cut(y + 1, x):
				_append_shell_wall(vertices, normals, uvs, colors, indices, d01, d11)

	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh: ArrayMesh = ArrayMesh.new()
	if not vertices.is_empty():
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _shell_cell_index(y: int, x: int) -> int:
	return y * shell_longitude_segments + posmod(x, shell_longitude_segments)


func _shell_chunk_index_for_cell(y: int, x: int) -> int:
	var chunk_col: int = clampi(int(posmod(x, shell_longitude_segments) / _shell_chunk_cell_size), 0, _shell_chunk_cols - 1)
	var chunk_row: int = clampi(int(y / _shell_chunk_cell_size), 0, _shell_chunk_rows - 1)
	return chunk_row * _shell_chunk_cols + chunk_col


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
	colors: PackedColorArray,
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
	var surface_color: Color = Color(0.0, 0.0, 0.0, 1.0) if outer else Color(0.0, 1.0, 0.0, 1.0)
	colors.append(surface_color)
	colors.append(surface_color)
	colors.append(surface_color)
	colors.append(surface_color)
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
	colors: PackedColorArray,
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
	var wall_color := Color(1.0, 0.0, 0.0, 1.0)
	colors.append(wall_color)
	colors.append(wall_color)
	colors.append(wall_color)
	colors.append(wall_color)
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


func _setup_paint_roll_scene() -> void:
	_ensure_paint_roll_mirror_piece_uv_texture()
	_paint_roll_root = Control.new()
	_paint_roll_root.name = "PaintRollStage"
	_paint_roll_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paint_roll_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_paint_roll_root.offset_left = 0.0
	_paint_roll_root.offset_top = 0.0
	_paint_roll_root.offset_right = 0.0
	_paint_roll_root.offset_bottom = 0.0
	_paint_roll_root.clip_contents = true
	_paint_roll_root.modulate.a = 0.0
	_paint_roll_root.visible = false
	add_child(_paint_roll_root)

	_paint_roll_canvas = Control.new()
	_paint_roll_canvas.name = "RollingPaintingCanvas"
	_paint_roll_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paint_roll_canvas.z_index = 1

	_paint_roll_frame = ColorRect.new()
	_paint_roll_frame.name = "RollingPaintingFrame"
	_paint_roll_frame.color = Color(0.20, 0.145, 0.075, 1.0)
	_paint_roll_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paint_roll_frame.z_index = 0
	_paint_roll_root.add_child(_paint_roll_frame)

	_paint_roll_root.add_child(_paint_roll_canvas)

	_paint_roll_mirror_back = ColorRect.new()
	_paint_roll_mirror_back.name = "MirrorFrameInterior"
	_paint_roll_mirror_back.color = Color.WHITE
	_paint_roll_mirror_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paint_roll_mirror_back.visible = false
	_paint_roll_mirror_back.material = _create_paint_roll_mirror_back_material()
	_paint_roll_canvas.add_child(_paint_roll_mirror_back)

	_paint_roll_bw = TextureRect.new()
	_paint_roll_bw.name = "BlackWhitePainting"
	_paint_roll_bw.texture = PAINT_ROLL_COLOR_TEXTURE
	_paint_roll_bw.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_paint_roll_bw.stretch_mode = TextureRect.STRETCH_SCALE
	_paint_roll_bw.material = _create_grayscale_material()
	_paint_roll_bw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paint_roll_canvas.add_child(_paint_roll_bw)

	_paint_roll_mask_image = Image.create(_paint_roll_mask_size.x, _paint_roll_mask_size.y, false, Image.FORMAT_RGBA8)
	_paint_roll_mask_image.fill(Color(0.0, 0.0, 0.0, 0.0))
	_paint_roll_trail_image = Image.create(_paint_roll_mask_size.x, _paint_roll_mask_size.y, false, Image.FORMAT_RGBA8)
	_paint_roll_trail_image.fill(Color(0.0, 0.0, 0.0, 0.0))
	_paint_roll_trail_texture = ImageTexture.create_from_image(_paint_roll_trail_image)
	_paint_roll_deposit_image = Image.create(_paint_roll_mask_size.x, _paint_roll_mask_size.y, false, Image.FORMAT_RGBA8)
	_paint_roll_deposit_image.fill(Color(0.0, 0.0, 0.0, 0.0))
	_paint_roll_mask_texture = ImageTexture.create_from_image(_paint_roll_mask_image)

	_paint_roll_color = TextureRect.new()
	_paint_roll_color.name = "RestoredColorPainting"
	_paint_roll_color.texture = PAINT_ROLL_COLOR_TEXTURE
	_paint_roll_color.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_paint_roll_color.stretch_mode = TextureRect.STRETCH_SCALE
	_paint_roll_color.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paint_roll_material = _create_paint_roll_reveal_material()
	_paint_roll_color.material = _paint_roll_material
	_paint_roll_canvas.add_child(_paint_roll_color)

	_paint_roll_trail = TextureRect.new()
	_paint_roll_trail.name = "MotionColorTrails"
	_paint_roll_trail.texture = _paint_roll_trail_texture
	_paint_roll_trail.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_paint_roll_trail.stretch_mode = TextureRect.STRETCH_SCALE
	_paint_roll_trail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paint_roll_trail_material = _create_paint_roll_trail_material()
	_paint_roll_trail.material = _paint_roll_trail_material
	_paint_roll_canvas.add_child(_paint_roll_trail)

	_paint_roll_mirror_overlay = Control.new()
	_paint_roll_mirror_overlay.name = "MirrorOverlay"
	_paint_roll_mirror_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paint_roll_mirror_overlay.visible = false
	_paint_roll_mirror_overlay.z_index = 2
	_paint_roll_canvas.add_child(_paint_roll_mirror_overlay)

	_paint_roll_mirror_plate = ColorRect.new()
	_paint_roll_mirror_plate.name = "MirrorGlassPlate"
	_paint_roll_mirror_plate.color = Color.WHITE
	_paint_roll_mirror_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paint_roll_mirror_plate.visible = false
	_paint_roll_mirror_overlay.add_child(_paint_roll_mirror_plate)

	_paint_roll_mirror = TextureRect.new()
	_paint_roll_mirror.name = "SphereMirrorReflection"
	_paint_roll_mirror.texture = left_viewport.get_texture()
	_paint_roll_mirror.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_paint_roll_mirror.stretch_mode = TextureRect.STRETCH_SCALE
	_paint_roll_mirror.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paint_roll_mirror.visible = false
	_paint_roll_mirror_material = _create_paint_roll_mirror_material()
	_paint_roll_mirror.material = _paint_roll_mirror_material
	_paint_roll_mirror_overlay.add_child(_paint_roll_mirror)

	_paint_roll_mirror_piece_root = Control.new()
	_paint_roll_mirror_piece_root.name = "LayeredBrokenMirror"
	_paint_roll_mirror_piece_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paint_roll_mirror_piece_root.visible = false
	_paint_roll_mirror_piece_root.z_index = 3
	_paint_roll_mirror_overlay.add_child(_paint_roll_mirror_piece_root)

	_paint_roll_mirror_crack_root = Control.new()
	_paint_roll_mirror_crack_root.name = "MirrorCrackLines"
	_paint_roll_mirror_crack_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paint_roll_mirror_crack_root.visible = false
	_paint_roll_mirror_crack_root.z_index = 4
	_paint_roll_mirror_overlay.add_child(_paint_roll_mirror_crack_root)
	_update_right6_mirror_shader()

	_paint_roll_shard_root = Control.new()
	_paint_roll_shard_root.name = "PaintRollLargeShardCollapse"
	_paint_roll_shard_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paint_roll_shard_root.visible = false
	_paint_roll_shard_root.z_index = 8
	_paint_roll_canvas.add_child(_paint_roll_shard_root)

	_apply_paint_roll_stage(0)


func _ensure_paint_roll_mirror_piece_uv_texture() -> void:
	if _paint_roll_mirror_piece_uv_texture != null:
		return
	var image := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	image.set_pixel(0, 0, Color.WHITE)
	_paint_roll_mirror_piece_uv_texture = ImageTexture.create_from_image(image)


func _create_paint_roll_reveal_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform sampler2D reveal_mask;
uniform float edge_softness = 0.18;
uniform float final_fill = 0.0;
uniform float wet_strength = 0.62;
uniform float burn_progress : hint_range(0.0, 1.0) = 0.0;

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
	float coarse = noise(uv * 7.0 + vec2(TIME * 0.08, -TIME * 0.05));
	float fine = noise(uv * 34.0 + vec2(floor(TIME * 14.0), floor(TIME * 11.0)));
	float tear = sin((uv.y + coarse * 0.12) * 38.0 + TIME * 4.0) * 0.018;
	return radius - length(p) + (coarse - 0.5) * 0.115 + (fine - 0.5) * 0.038 + tear;
}

float burn_total_field(vec2 uv) {
	float radius = mix(-0.06, 1.02, burn_progress);
	float field = max(burn_field(uv, vec2(0.45, 0.50), radius, 0.92), burn_field(uv, vec2(0.62, 0.42), radius * 0.90, 1.12));
	field = max(field, burn_field(uv, vec2(0.52, 0.58), radius * 1.06, 0.84));
	field = max(field, burn_field(uv, vec2(0.38, 0.55), radius * 0.82, 1.00));
	field = max(field, burn_field(uv, vec2(0.56, 0.47), radius * 0.88, 0.95));
	field = max(field, burn_field(uv, vec2(0.70, 0.38), radius * 0.78, 1.08));
	field = max(field, burn_field(uv, vec2(0.48, 0.64), radius * 0.92, 0.90));
	field = max(field, smoothstep(0.68, 1.0, burn_progress) * 0.42 - distance(uv, vec2(0.5)) * 0.55);
	if (burn_progress >= 0.995) {
		field = 1.0;
	}
	return field;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec2 px = TEXTURE_PIXEL_SIZE * 7.0;
	float m0 = texture(reveal_mask, UV).a;
	float m = m0;
	m = max(m, texture(reveal_mask, UV + vec2(px.x, 0.0)).a * 0.76);
	m = max(m, texture(reveal_mask, UV - vec2(px.x, 0.0)).a * 0.76);
	m = max(m, texture(reveal_mask, UV + vec2(0.0, px.y)).a * 0.76);
	m = max(m, texture(reveal_mask, UV - vec2(0.0, px.y)).a * 0.76);
	m = max(m, texture(reveal_mask, UV + px).a * 0.52);
	m = max(m, texture(reveal_mask, UV - px).a * 0.52);
	m = max(m, final_fill);
	float visible = step(0.001, m);
	float grain = hash(floor(UV * 420.0));
	float full_reveal = smoothstep(0.86, 0.98, m);
	float partial_reveal = smoothstep(0.02, edge_softness, m + (grain - 0.5) * 0.055) * visible;
	float color_amount = mix(partial_reveal * 0.33, 1.0, full_reveal);
	float wet_edge = partial_reveal * (1.0 - full_reveal) * visible;
	vec3 muted = mix(vec3(dot(c.rgb, vec3(0.299, 0.587, 0.114))), c.rgb, 0.33);
	vec3 visible_color = mix(muted, c.rgb, full_reveal);
	visible_color = mix(visible_color, vec3(1.0), wet_edge * wet_strength * 0.04);
	float burn_field_value = burn_total_field(UV);
	float hole = smoothstep(0.0, 0.105, burn_field_value);
	float edge = smoothstep(-0.105, 0.105, burn_field_value) * (1.0 - hole);
	float charred = smoothstep(-0.15, 0.105, burn_field_value) * (1.0 - hole);
	visible_color = mix(visible_color, vec3(0.06, 0.043, 0.032), charred * 0.78);
	visible_color += vec3(0.80, 0.48, 0.18) * edge * 0.36;
	COLOR = vec4(visible_color, c.a * color_amount * (1.0 - hole));
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("reveal_mask", _paint_roll_mask_texture)
	material.set_shader_parameter("final_fill", 0.0)
	material.set_shader_parameter("wet_strength", 0.62)
	material.set_shader_parameter("burn_progress", 0.0)
	return material


func _create_paint_roll_trail_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(41.7, 289.3))) * 43758.5453123);
}

void fragment() {
	vec4 t = texture(TEXTURE, UV);
	float n = hash(floor(UV * 360.0));
	float edge = smoothstep(0.02, 0.34, t.a + (n - 0.5) * 0.045);
	vec3 color = mix(t.rgb * 0.62, t.rgb, edge);
	COLOR = vec4(color, t.a * edge * 0.72);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	return material


func _create_paint_roll_mirror_back_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float burn_progress : hint_range(0.0, 1.0) = 0.0;

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
	float coarse = noise(uv * 7.0 + vec2(TIME * 0.08, -TIME * 0.05));
	float fine = noise(uv * 34.0 + vec2(floor(TIME * 14.0), floor(TIME * 11.0)));
	float tear = sin((uv.y + coarse * 0.12) * 38.0 + TIME * 4.0) * 0.018;
	return radius - length(p) + (coarse - 0.5) * 0.115 + (fine - 0.5) * 0.038 + tear;
}

float burn_total_field(vec2 uv) {
	if (burn_progress >= 0.995) {
		return 1.0;
	}
	float radius = mix(-0.06, 1.02, burn_progress);
	float field = max(burn_field(uv, vec2(0.45, 0.50), radius, 0.92), burn_field(uv, vec2(0.62, 0.42), radius * 0.90, 1.12));
	field = max(field, burn_field(uv, vec2(0.52, 0.58), radius * 1.06, 0.84));
	field = max(field, burn_field(uv, vec2(0.38, 0.55), radius * 0.82, 1.00));
	field = max(field, burn_field(uv, vec2(0.56, 0.47), radius * 0.88, 0.95));
	field = max(field, burn_field(uv, vec2(0.70, 0.38), radius * 0.78, 1.08));
	field = max(field, burn_field(uv, vec2(0.48, 0.64), radius * 0.92, 0.90));
	field = max(field, smoothstep(0.68, 1.0, burn_progress) * 0.42 - distance(uv, vec2(0.5)) * 0.55);
	return field;
}

void fragment() {
	vec2 uv = UV;
	float paper = noise(uv * vec2(8.0, 5.0)) * 0.08 + noise(uv * vec2(36.0, 28.0)) * 0.035;
	float vignette = smoothstep(0.92, 0.18, distance(uv, vec2(0.5)));
	vec3 base = mix(vec3(0.105, 0.090, 0.075), vec3(0.24, 0.205, 0.155), vignette);
	base += vec3(paper);
	float inner_line = max(
		max(1.0 - smoothstep(0.018, 0.034, uv.x), smoothstep(0.966, 0.982, uv.x)),
		max(1.0 - smoothstep(0.018, 0.034, uv.y), smoothstep(0.966, 0.982, uv.y))
	);
	base = mix(base, vec3(0.46, 0.35, 0.19), inner_line * 0.58);
	float mirror_shadow = smoothstep(0.38, 0.12, distance((uv - vec2(0.5)) * vec2(1.0, 1.0), vec2(0.0)));
	base *= 1.0 - mirror_shadow * 0.20;
	float burn_field_value = burn_total_field(uv);
	float hole = smoothstep(0.0, 0.105, burn_field_value);
	float edge = smoothstep(-0.105, 0.105, burn_field_value) * (1.0 - hole);
	float charred = smoothstep(-0.15, 0.105, burn_field_value) * (1.0 - hole);
	base = mix(base, vec3(0.055, 0.041, 0.032), charred * 0.82);
	base += vec3(0.72, 0.42, 0.16) * edge * 0.30;
	COLOR = vec4(clamp(base, vec3(0.0), vec3(1.0)), 1.0 - hole);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("burn_progress", 0.0)
	return material


func _create_paint_roll_mirror_plate_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float burn_progress : hint_range(0.0, 1.0) = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(91.7, 271.3))) * 43758.5453123);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	p.x *= 0.82;
	float r = length(p);
	if (r > 1.0) {
		discard;
	}
	float rim = smoothstep(0.72, 0.98, r);
	float outer_rim = smoothstep(0.88, 0.99, r);
	float glass = smoothstep(1.0, 0.0, r);
	float highlight = pow(max(0.0, 1.0 - distance(UV, vec2(0.34, 0.25)) * 2.5), 5.0);
	float lower_sheen = pow(max(0.0, 1.0 - distance(UV, vec2(0.64, 0.72)) * 2.2), 3.0);
	float grain = hash(floor(UV * 180.0) + vec2(floor(TIME * 8.0), floor(TIME * 6.0)));
	vec3 deep = vec3(0.035, 0.047, 0.060);
	vec3 blue = vec3(0.13, 0.19, 0.24);
	vec3 metal = vec3(0.64, 0.50, 0.28);
	vec3 color = mix(deep, blue, glass);
	color += vec3(0.62, 0.78, 0.88) * highlight * 0.72;
	color += vec3(0.26, 0.36, 0.42) * lower_sheen * 0.28;
	color = mix(color, metal, outer_rim);
	color += (grain - 0.5) * 0.018;
	float burn_noise = hash(floor(UV * vec2(48.0, 60.0)) + vec2(floor(TIME * 6.0), floor(TIME * 5.0)));
	float burn_value = UV.y + burn_noise * 0.20 + r * 0.16;
	float burn_front = 1.12 - burn_progress * 1.32;
	float burn_line = smoothstep(burn_front, burn_front + 0.16, burn_value);
	if (burn_progress <= 0.001) {
		burn_line = 0.0;
	}
	float alpha = (0.88 + rim * 0.12) * (1.0 - burn_line);
	COLOR = vec4(clamp(color, vec3(0.0), vec3(1.0)), alpha);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("burn_progress", 0.0)
	return material


func _create_paint_roll_mirror_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float burn_progress : hint_range(0.0, 1.0) = 0.0;
uniform vec3 ball_center = vec3(0.0, 0.0, -1.55);
uniform float ball_radius = 0.24;
uniform vec2 ball_velocity = vec2(0.0, 0.0);
uniform float camera_distance = 3.2;
uniform vec3 ball_basis_x = vec3(1.0, 0.0, 0.0);
uniform vec3 ball_basis_y = vec3(0.0, 1.0, 0.0);
uniform vec3 ball_basis_z = vec3(0.0, 0.0, 1.0);
uniform sampler2D ball_dye_mask : source_color;
uniform vec4 flow_color_0 : source_color = vec4(0.9, 0.12, 0.08, 1.0);
uniform vec4 flow_color_1 : source_color = vec4(0.1, 0.36, 0.9, 1.0);
uniform vec4 flow_color_2 : source_color = vec4(0.96, 0.72, 0.12, 1.0);
uniform vec4 flow_color_3 : source_color = vec4(0.18, 0.62, 0.34, 1.0);
uniform float flow_time = 0.0;
uniform int mirror_layer = 0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(121.7, 317.3))) * 43758.5453123);
}

float noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float n000 = hash(i.xy + vec2(i.z, 0.0));
	float n100 = hash(i.xy + vec2(1.0 + i.z, 0.0));
	float n010 = hash(i.xy + vec2(i.z, 1.0));
	float n110 = hash(i.xy + vec2(1.0 + i.z, 1.0));
	float n001 = hash(i.xy + vec2(i.z, 2.0));
	float n101 = hash(i.xy + vec2(1.0 + i.z, 2.0));
	float n011 = hash(i.xy + vec2(i.z, 3.0));
	float n111 = hash(i.xy + vec2(1.0 + i.z, 3.0));
	float n00 = mix(n000, n100, f.x);
	float n10 = mix(n010, n110, f.x);
	float n01 = mix(n001, n101, f.x);
	float n11 = mix(n011, n111, f.x);
	return mix(mix(n00, n10, f.y), mix(n01, n11, f.y), f.z);
}

float ray_sphere(vec3 ro, vec3 rd, vec3 center, float radius) {
	vec3 oc = ro - center;
	float b = dot(oc, rd);
	float c = dot(oc, oc) - radius * radius;
	float h = b * b - c;
	if (h < 0.0) {
		return -1.0;
	}
	float root = sqrt(h);
	float near_t = -b - root;
	float far_t = -b + root;
	if (near_t > 0.0005) {
		return near_t;
	}
	if (far_t > 0.0005) {
		return far_t;
	}
	return -1.0;
}

vec3 sky_reflection(vec3 rd, vec2 p, float r) {
	float horizon = smoothstep(-0.35, 0.75, rd.y);
	vec3 deep = vec3(0.030, 0.036, 0.044);
	vec3 wall = vec3(0.155, 0.135, 0.105);
	vec3 color = mix(deep, wall, horizon);
	float side = smoothstep(0.30, 1.0, abs(rd.x));
	color = mix(color, vec3(0.055, 0.064, 0.072), side * 0.45);
	float floor_line = smoothstep(-0.88, -0.38, rd.y) * (1.0 - smoothstep(-0.34, 0.08, rd.y));
	color += vec3(0.09, 0.075, 0.052) * floor_line;
	float radial = smoothstep(0.0, 1.0, r);
	color *= 0.86 + 0.14 * (1.0 - radial);
	color += vec3(0.020, 0.025, 0.030) * sin((p.x + rd.x) * 9.0 + rd.y * 4.0);
	return clamp(color, vec3(0.0), vec3(1.0));
}

vec2 sphere_uv(vec3 dir) {
	return vec2(fract(atan(dir.z, dir.x) / 6.2831853), acos(clamp(dir.y, -1.0, 1.0)) / 3.1415926);
}

float mirror_height(vec2 p) {
	float r2 = dot(p, p);
	float r = sqrt(r2);
	float theta = atan(p.y, p.x);
	float edge_falloff = 1.0 - smoothstep(0.72, 1.0, sqrt(r2));
	if (mirror_layer == 0) {
		float sector = floor((theta + 3.1415926) / 6.2831853 * 7.0);
		float sector_angle = (sector + 0.5) / 7.0 * 6.2831853 - 3.1415926;
		vec2 sector_axis = vec2(cos(sector_angle), sin(sector_angle));
		float seam = abs(sin((theta - sector_angle) * 3.5));
		float local_push = dot(p, sector_axis);
		float facet_tilt = local_push * (0.075 + 0.055 * hash(vec2(sector, 2.7))) * edge_falloff;
		float facet_bulge = sin(sector * 2.17 + 1.3) * 0.050 * edge_falloff;
		float convex = -sqrt(max(0.025, 1.0 - r2 * (0.86 + 0.18 * hash(vec2(sector, 9.1)))));
		return convex + facet_tilt + facet_bulge - smoothstep(0.84, 0.98, seam) * 0.018 * edge_falloff;
	}
	if (mirror_layer == 1) {
		vec2 q = p - vec2(0.16, -0.08);
		float upper_lobe = exp(-dot(q - vec2(-0.18, -0.30), q - vec2(-0.18, -0.30)) * 3.8);
		float lower_lobe = exp(-dot(q - vec2(0.22, 0.34), q - vec2(0.22, 0.34)) * 2.5);
		float waist = exp(-dot(q - vec2(0.02, 0.02), q - vec2(0.02, 0.02)) * 8.5);
		float gourd_metric = q.x * q.x * (1.05 + lower_lobe * 0.95) + q.y * q.y * (0.72 + upper_lobe * 1.25);
		float convex = -sqrt(max(0.025, 1.0 - gourd_metric));
		float bias = (q.x * q.x * q.x * 0.30 - q.x * q.y * q.y * 0.36 + upper_lobe * 0.11 - lower_lobe * 0.09) * edge_falloff;
		return convex + bias - waist * 0.065 * edge_falloff;
	}
	float convex = -sqrt(max(0.025, 1.0 - r2));
	float swirl = sin(theta * 3.0 + r * 12.0) * 0.125 * edge_falloff;
	float fold = sin(theta * 5.0 - r * 7.5 + p.x * 2.0) * 0.070 * edge_falloff;
	float spiral_pull = (p.x * sin(r * 5.0) - p.y * cos(r * 4.0)) * 0.055 * edge_falloff;
	return convex + swirl + fold + spiral_pull;
}

vec3 mirror_surface(vec2 p) {
	return vec3(p.x, -p.y, mirror_height(p));
}

vec3 mirror_normal(vec2 p) {
	float e = 0.004;
	vec3 sx = mirror_surface(p + vec2(e, 0.0)) - mirror_surface(p - vec2(e, 0.0));
	vec3 sy = mirror_surface(p + vec2(0.0, e)) - mirror_surface(p - vec2(0.0, e));
	return normalize(cross(sx, sy));
}

vec3 flowing_ball_color(vec3 local_n, vec2 drag) {
	float band = sin(local_n.y * 12.0 + sin(local_n.x * 5.2 + flow_time * 0.42) * 0.85 + flow_time * 0.34);
	float storm = noise(local_n * 5.0 + vec3(flow_time * 0.09, -flow_time * 0.05, flow_time * 0.07));
	float streak = sin((local_n.x + drag.x * 0.22) * 18.0 + local_n.y * 7.0 + flow_time * 0.48 + storm * 1.6);
	vec3 c01 = mix(flow_color_0.rgb, flow_color_1.rgb, smoothstep(-0.72, 0.72, band));
	vec3 c23 = mix(flow_color_2.rgb, flow_color_3.rgb, smoothstep(-0.48, 0.86, streak));
	vec3 color = mix(c01, c23, smoothstep(0.18, 0.92, storm));
	vec4 dye = texture(ball_dye_mask, sphere_uv(local_n));
	color = mix(color, dye.rgb, clamp(dye.a, 0.0, 1.0));
	float luma = dot(color, vec3(0.299, 0.587, 0.114));
	color = mix(vec3(luma), color, 0.95) * 0.86;
	color += vec3(0.08, 0.10, 0.12) * pow(1.0 - abs(local_n.z), 1.7);
	return clamp(color, vec3(0.0), vec3(1.0));
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	if (r > 1.0) {
		discard;
	}
	vec3 surface = mirror_surface(p);
	vec3 normal = mirror_normal(p);
	vec3 camera = vec3(0.0, 0.0, -camera_distance);
	vec3 incident = normalize(surface - camera);
	vec3 ray_dir = normalize(reflect(incident, normal));
	float t = ray_sphere(surface + normal * 0.004, ray_dir, ball_center, ball_radius);
	float gloss = pow(max(0.0, dot(normalize(vec3(-0.42, -0.58, -0.70)), normal)), 28.0);
	float grain = hash(floor(UV * 180.0) + vec2(floor(TIME * 12.0), floor(TIME * 9.0)));
	vec3 color = sky_reflection(ray_dir, p, r);
	if (t > 0.0) {
		vec3 hit = surface + ray_dir * t;
		vec3 world_n = normalize(hit - ball_center);
		vec3 local_n = normalize(vec3(dot(world_n, ball_basis_x), dot(world_n, ball_basis_y), dot(world_n, ball_basis_z)));
		vec3 ball_color = flowing_ball_color(local_n, ball_velocity);
		float lambert = max(0.0, dot(world_n, normalize(vec3(-0.35, -0.52, -0.78))));
		float shade = 0.38 + 0.62 * lambert;
		float rim = pow(1.0 - max(0.0, dot(world_n, -ray_dir)), 2.8);
		float spec = pow(max(0.0, dot(reflect(ray_dir, world_n), normalize(vec3(-0.25, -0.40, -0.88)))), 36.0);
		color = clamp(ball_color * shade + vec3(0.92, 0.96, 1.0) * (rim * 0.13 + spec * 0.24), vec3(0.0), vec3(1.0));
	}
	float fresnel = pow(1.0 - max(0.0, dot(-incident, normal)), 2.0);
	color += vec3(0.92, 0.96, 1.0) * gloss * 0.58;
	color += vec3(0.18, 0.22, 0.26) * fresnel * 0.34;
	color += (grain - 0.5) * 0.025;
	float alpha = smoothstep(1.0, 0.94, r);
	COLOR = vec4(clamp(color, vec3(0.0), vec3(1.0)), alpha);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("burn_progress", 0.0)
	material.set_shader_parameter("ball_center", Vector3(0.0, 0.0, -1.55))
	material.set_shader_parameter("ball_radius", 0.24)
	material.set_shader_parameter("ball_velocity", Vector2.ZERO)
	material.set_shader_parameter("camera_distance", 3.2)
	material.set_shader_parameter("ball_basis_x", Vector3.RIGHT)
	material.set_shader_parameter("ball_basis_y", Vector3.UP)
	material.set_shader_parameter("ball_basis_z", Vector3.BACK)
	if _core_dye_texture != null:
		material.set_shader_parameter("ball_dye_mask", _core_dye_texture)
	material.set_shader_parameter("flow_color_0", Color(0.9, 0.12, 0.08, 1.0))
	material.set_shader_parameter("flow_color_1", Color(0.1, 0.36, 0.9, 1.0))
	material.set_shader_parameter("flow_color_2", Color(0.96, 0.72, 0.12, 1.0))
	material.set_shader_parameter("flow_color_3", Color(0.18, 0.62, 0.34, 1.0))
	material.set_shader_parameter("flow_time", 0.0)
	material.set_shader_parameter("mirror_layer", 0)
	return material


func _set_visible_paint_roll_mirror_layer(layer_index: int) -> void:
	var clamped_layer := clampi(layer_index, 0, 2)
	if _paint_roll_mirror_material != null:
		_paint_roll_mirror_material.set_shader_parameter("mirror_layer", clamped_layer)
	if _paint_roll_mirror != null:
		_paint_roll_mirror.visible = _is_paint_roll_mirror_stage() and _paint_roll_mirror_piece_layers.is_empty()
	for i in range(_paint_roll_mirror_piece_layers.size()):
		var layer := _paint_roll_mirror_piece_layers[i]
		if layer == null or not is_instance_valid(layer):
			continue
		layer.visible = _is_paint_roll_mirror_stage() and i >= clamped_layer
		layer.z_index = -i
		if layer.visible:
			layer.modulate.a = 1.0


func _build_paint_roll_resistance_image() -> void:
	_paint_roll_resistance_image = Image.create(_paint_roll_mask_size.x, _paint_roll_mask_size.y, false, Image.FORMAT_RGBA8)
	if _paint_roll_source_image == null or _paint_roll_source_image.is_empty() or _paint_roll_bw_reference_image == null or _paint_roll_bw_reference_image.is_empty():
		_paint_roll_resistance_image.fill(Color(0.0, 0.0, 0.0, 1.0))
		return
	for y in range(_paint_roll_mask_size.y):
		for x in range(_paint_roll_mask_size.x):
			var uv := Vector2(float(x) / float(_paint_roll_mask_size.x - 1), float(y) / float(_paint_roll_mask_size.y - 1))
			var resistance: float = _sample_paint_roll_reference_difference(uv)
			_paint_roll_resistance_image.set_pixel(x, y, Color(resistance, resistance, resistance, 1.0))
	_soften_paint_roll_resistance()


func _sample_paint_roll_reference_difference(uv: Vector2) -> float:
	var color_size := Vector2i(_paint_roll_source_image.get_width(), _paint_roll_source_image.get_height())
	var bw_size := Vector2i(_paint_roll_bw_reference_image.get_width(), _paint_roll_bw_reference_image.get_height())
	var cx: int = clampi(int(uv.x * float(color_size.x - 1)), 0, color_size.x - 1)
	var cy: int = clampi(int(uv.y * float(color_size.y - 1)), 0, color_size.y - 1)
	var bx: int = clampi(int(uv.x * float(bw_size.x - 1)), 0, bw_size.x - 1)
	var by: int = clampi(int(uv.y * float(bw_size.y - 1)), 0, bw_size.y - 1)
	var color_px := _paint_roll_source_image.get_pixel(cx, cy)
	var bw_px := _paint_roll_bw_reference_image.get_pixel(bx, by)
	var diff: float = abs(color_px.r - bw_px.r) + abs(color_px.g - bw_px.g) + abs(color_px.b - bw_px.b)
	var color_saturation: float = maxf(color_px.r, maxf(color_px.g, color_px.b)) - minf(color_px.r, minf(color_px.g, color_px.b))
	var bw_saturation: float = maxf(bw_px.r, maxf(bw_px.g, bw_px.b)) - minf(bw_px.r, minf(bw_px.g, bw_px.b))
	var saturation_drop: float = maxf(0.0, color_saturation - bw_saturation)
	return clampf(smoothstep(0.06, 0.32, diff + saturation_drop * 1.8), 0.0, 1.0)


func _soften_paint_roll_resistance() -> void:
	if _paint_roll_resistance_image == null:
		return
	for pass_index in range(2):
		var source := _paint_roll_resistance_image.duplicate()
		for y in range(_paint_roll_mask_size.y):
			for x in range(_paint_roll_mask_size.x):
				var max_value: float = source.get_pixel(x, y).r
				for oy in range(-2, 3):
					for ox in range(-2, 3):
						var sx: int = clampi(x + ox, 0, _paint_roll_mask_size.x - 1)
						var sy: int = clampi(y + oy, 0, _paint_roll_mask_size.y - 1)
						var distance := Vector2(float(ox), float(oy)).length()
						var weight: float = clampf(1.0 - distance / 3.0, 0.0, 1.0)
						max_value = maxf(max_value, source.get_pixel(sx, sy).r * weight)
				_paint_roll_resistance_image.set_pixel(x, y, Color(max_value, max_value, max_value, 1.0))


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
	_layout_paint_roll_scene()


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


func _layout_paint_roll_scene() -> void:
	if _paint_roll_root == null or _paint_roll_canvas == null:
		return
	var viewport_size := size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		viewport_size = get_viewport_rect().size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		return
	_paint_roll_root.size = viewport_size
	var texture: Texture2D = _paint_roll_color.texture if _paint_roll_color != null else PAINT_ROLL_COLOR_TEXTURE
	if texture == null:
		return
	var texture_size := texture.get_size()
	if texture_size.x <= 1.0 or texture_size.y <= 1.0:
		return
	var viewport_aspect := viewport_size.x / viewport_size.y
	var texture_aspect := texture_size.x / texture_size.y
	_paint_roll_canvas_size = viewport_size * paint_roll_canvas_zoom
	if viewport_aspect > texture_aspect:
		_paint_roll_canvas_size.y = _paint_roll_canvas_size.x / texture_aspect
	else:
		_paint_roll_canvas_size.x = _paint_roll_canvas_size.y * texture_aspect
	_paint_roll_ball_diameter_px = _compute_paint_roll_ball_diameter(viewport_size)
	_update_paint_roll_canvas_transform()
	for rect in [_paint_roll_mirror_back, _paint_roll_bw, _paint_roll_color, _paint_roll_trail]:
		if rect == null:
			continue
		rect.position = Vector2.ZERO
		rect.size = _paint_roll_canvas_size
	_layout_paint_roll_mirror_and_ash()


func _layout_paint_roll_mirror_and_ash() -> void:
	if _paint_roll_canvas_size.x <= 1.0 or _paint_roll_canvas_size.y <= 1.0:
		return
	_sync_paint_roll_mirror_overlay()
	if _paint_roll_shard_root != null:
		_paint_roll_shard_root.position = Vector2.ZERO
		_paint_roll_shard_root.size = _paint_roll_canvas_size


func _sync_paint_roll_mirror_overlay() -> void:
	if _paint_roll_mirror_overlay == null:
		return
	if _paint_roll_canvas_size.x <= 1.0 or _paint_roll_canvas_size.y <= 1.0:
		return
	var diameter := minf(_paint_roll_canvas_size.x, _paint_roll_canvas_size.y) * 0.92
	var plate_size := Vector2(diameter, diameter)
	var center := Vector2(_paint_roll_canvas_size.x * 0.5, _paint_roll_canvas_size.y * 0.50)
	_paint_roll_mirror_overlay.position = center - plate_size * 0.5
	_paint_roll_mirror_overlay.size = plate_size
	_paint_roll_mirror_overlay.pivot_offset = plate_size * 0.5
	_paint_roll_mirror_overlay.rotation_degrees = 0.0
	if _paint_roll_mirror_plate != null:
		_paint_roll_mirror_plate.position = Vector2.ZERO
		_paint_roll_mirror_plate.size = plate_size
		_paint_roll_mirror_plate.pivot_offset = plate_size * 0.5
		_paint_roll_mirror_plate.visible = false
	if _paint_roll_mirror != null:
		var reflection_size := Vector2(diameter, diameter)
		_paint_roll_mirror.size = reflection_size
		_paint_roll_mirror.pivot_offset = reflection_size * 0.5
		_paint_roll_mirror.position = plate_size * 0.5 - reflection_size * 0.5
		_paint_roll_mirror.visible = _is_paint_roll_mirror_stage() and _paint_roll_mirror_piece_layers.is_empty()
		if _paint_roll_mirror_material != null:
			_paint_roll_mirror_material.set_shader_parameter("mirror_layer", clampi(_paint_roll_mirror_layer_index, 0, 2))
	if _paint_roll_mirror_piece_root != null:
		_paint_roll_mirror_piece_root.position = Vector2.ZERO
		_paint_roll_mirror_piece_root.size = plate_size
		_paint_roll_mirror_piece_root.visible = _is_paint_roll_mirror_stage()
		_rebuild_paint_roll_mirror_layers_if_needed(plate_size)
		_set_visible_paint_roll_mirror_layer(_paint_roll_mirror_layer_index)
	if _paint_roll_mirror_crack_root != null:
		_paint_roll_mirror_crack_root.position = Vector2.ZERO
		_paint_roll_mirror_crack_root.size = plate_size
		_paint_roll_mirror_crack_root.visible = _is_paint_roll_mirror_stage()


func _rebuild_paint_roll_mirror_layers_if_needed(plate_size: Vector2) -> void:
	if _paint_roll_mirror_piece_root == null:
		return
	if not _paint_roll_mirror_piece_layers.is_empty() and _paint_roll_mirror_piece_size.distance_to(plate_size) < 1.0:
		return
	_clear_paint_roll_mirror_layers()
	_paint_roll_mirror_piece_size = plate_size
	_paint_roll_mirror_piece_root.size = plate_size
	var layer_count := 3
	for layer_index in range(layer_count):
		var layer_root := Control.new()
		layer_root.name = "MirrorLayer%d" % layer_index
		layer_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer_root.position = Vector2.ZERO
		layer_root.size = plate_size
		layer_root.z_index = layer_count - layer_index
		_paint_roll_mirror_piece_root.add_child(layer_root)

		var material := _create_paint_roll_mirror_material()
		material.set_shader_parameter("mirror_layer", layer_index)
		_paint_roll_mirror_piece_materials.append(material)

		var layer_shards: Array = []
		_build_paint_roll_mirror_piece_layer(layer_root, layer_shards, material, layer_index, plate_size)
		_paint_roll_mirror_piece_layers.append(layer_root)
		_paint_roll_mirror_piece_shards.append(layer_shards)
	_set_visible_paint_roll_mirror_layer(_paint_roll_mirror_layer_index)
	_update_right6_mirror_shader()


func _clear_paint_roll_mirror_layers() -> void:
	_paint_roll_mirror_piece_layers.clear()
	_paint_roll_mirror_piece_materials.clear()
	_paint_roll_mirror_piece_shards.clear()
	if _paint_roll_mirror_piece_root == null:
		return
	for child in _paint_roll_mirror_piece_root.get_children():
		child.queue_free()


func _build_paint_roll_mirror_piece_layer(layer_root: Control, layer_shards: Array, material: ShaderMaterial, layer_index: int, plate_size: Vector2) -> void:
	var center := plate_size * 0.5
	var radius := minf(plate_size.x, plate_size.y) * 0.5
	var segment_count := 10
	var ring_count := 3
	if layer_index == 1:
		segment_count = 12
		ring_count = 3
	elif layer_index == 2:
		segment_count = 14
		ring_count = 4
	var rings: Array[Array] = []
	for ring in range(ring_count):
		var ring_points: Array[Vector2] = []
		var ring_ratio := float(ring) / float(ring_count - 1)
		for i in range(segment_count):
			var seed := Vector2(float(i + 1), float((ring + 1) * (layer_index + 3)))
			var angle := (float(i) / float(segment_count)) * TAU
			if layer_index == 0:
				angle += (_hash_2d(seed + Vector2(7.1, 2.3)) - 0.5) * 0.070
				angle += sin(float(i) * 0.58 + float(ring) * 1.7) * 0.030 * ring_ratio
			elif layer_index == 1:
				angle += sin(float(i) * 1.13 + float(ring) * 2.4) * 0.105
				angle += (_hash_2d(seed + Vector2(7.1, 2.3)) - 0.5) * 0.095
			else:
				angle += ring_ratio * 0.72
				angle += sin(float(i) * 0.71 + float(ring) * 1.9) * 0.080
				angle += (_hash_2d(seed + Vector2(7.1, 2.3)) - 0.5) * 0.070
			var ratio := ring_ratio
			if ring > 0 and ring < ring_count - 1:
				if layer_index == 0:
					ratio += (_hash_2d(seed + Vector2(11.5, 19.2)) - 0.5) * 0.13
				elif layer_index == 1:
					ratio += sin(angle * 2.0 + float(ring) * 0.9) * 0.075
					ratio += (_hash_2d(seed + Vector2(11.5, 19.2)) - 0.5) * 0.15
				else:
					ratio += sin(angle * 3.0 - ring_ratio * 4.2) * 0.060
					ratio += (_hash_2d(seed + Vector2(11.5, 19.2)) - 0.5) * 0.12
			ratio = clampf(ratio, 0.0, 1.0)
			var direction := Vector2(cos(angle), sin(angle))
			var point := center + direction * radius * ratio
			if layer_index == 1 and ring > 0 and ring < ring_count - 1:
				point += Vector2(cos(angle * 2.0), sin(angle * 3.0)) * radius * 0.035
			ring_points.append(point)
		rings.append(ring_points)

	var center_jitter := Vector2(
		(_hash_2d(Vector2(layer_index + 0.2, 4.7)) - 0.5) * radius * 0.12,
		(_hash_2d(Vector2(layer_index + 9.4, 1.3)) - 0.5) * radius * 0.12
	)
	if layer_index == 1:
		center_jitter += Vector2(radius * 0.18, -radius * 0.12)
	elif layer_index == 2:
		center_jitter += Vector2(-radius * 0.10, radius * 0.16)
	var center_point := center + center_jitter
	for i in range(segment_count):
		var next_i := (i + 1) % segment_count
		_add_paint_roll_mirror_piece(layer_root, layer_shards, material, [center_point, rings[1][i], rings[1][next_i]], plate_size, layer_index, i)
	for ring in range(1, ring_count - 1):
		for i in range(segment_count):
			var next_i := (i + 1) % segment_count
			var a: Vector2 = rings[ring][i]
			var b: Vector2 = rings[ring + 1][i]
			var c: Vector2 = rings[ring + 1][next_i]
			var d: Vector2 = rings[ring][next_i]
			if _hash_2d(Vector2(float(layer_index * 101 + ring * 31 + i), 0.37)) > 0.5:
				_add_paint_roll_mirror_piece(layer_root, layer_shards, material, [a, b, c], plate_size, layer_index, i + ring * segment_count)
				_add_paint_roll_mirror_piece(layer_root, layer_shards, material, [a, c, d], plate_size, layer_index, i + ring * segment_count + 1000)
			else:
				_add_paint_roll_mirror_piece(layer_root, layer_shards, material, [a, b, d], plate_size, layer_index, i + ring * segment_count)
				_add_paint_roll_mirror_piece(layer_root, layer_shards, material, [b, c, d], plate_size, layer_index, i + ring * segment_count + 1000)


func _add_paint_roll_mirror_piece(layer_root: Control, layer_shards: Array, material: ShaderMaterial, points: Array, plate_size: Vector2, layer_index: int, piece_index: int) -> void:
	var centroid := Vector2.ZERO
	for point_variant in points:
		centroid += point_variant as Vector2
	centroid /= float(points.size())
	var polygon := PackedVector2Array()
	var uvs := PackedVector2Array()
	for point_variant in points:
		var point := point_variant as Vector2
		polygon.append(point - centroid)
		uvs.append(Vector2(point.x / maxf(1.0, plate_size.x), point.y / maxf(1.0, plate_size.y)))
	var shard := Polygon2D.new()
	shard.name = "MirrorPiece_%d_%03d" % [layer_index, piece_index]
	shard.polygon = polygon
	shard.uv = uvs
	shard.texture = _paint_roll_mirror_piece_uv_texture
	shard.position = centroid
	shard.color = Color.WHITE
	shard.material = material
	layer_root.add_child(shard)
	layer_shards.append({
		"node": shard,
		"origin": centroid,
		"material": material,
		"delay": _hash_2d(Vector2(float(piece_index), float(layer_index) + 0.27)) * 0.22,
		"drift": Vector2(centroid.x - plate_size.x * 0.5, centroid.y - plate_size.y * 0.5).normalized() * lerpf(90.0, 260.0, _hash_2d(Vector2(float(piece_index), 8.91))),
		"drop": lerpf(plate_size.y * 0.85, plate_size.y * 1.75, _hash_2d(Vector2(float(piece_index), 19.4))),
		"spin": lerpf(-1.8, 1.8, _hash_2d(Vector2(float(piece_index), 23.7))) * TAU,
	})


func _update_right6_mirror_shader() -> void:
	if _paint_roll_mirror_material == null and _paint_roll_mirror_piece_materials.is_empty():
		return
	var mirror_uv := Vector2(0.5, 0.5)
	var rel := _paint_roll_view_uv - mirror_uv
	var distance := rel.length()
	var z := -1.42 - clampf(distance, 0.0, 0.85) * 0.72
	var center := Vector3(rel.x * 2.15, -rel.y * 2.15, z)
	var radius := clampf(_get_paint_roll_ball_radius_uv() * 2.35 * 1.8, 0.32, 0.65)
	var velocity := _paint_roll_velocity_uv / maxf(0.001, paint_roll_max_speed_uv)
	var basis := Basis.IDENTITY
	if model_root != null:
		basis = model_root.transform.basis.orthonormalized()
	var palette := _get_core_flow_palette_for_shader()
	var materials: Array[ShaderMaterial] = []
	if _paint_roll_mirror_material != null:
		var visible_layer := _paint_roll_mirror_layer_index
		if _paint_roll_mirror_breaking:
			visible_layer += 1
		_paint_roll_mirror_material.set_shader_parameter("mirror_layer", clampi(visible_layer, 0, 2))
		materials.append(_paint_roll_mirror_material)
	for material in _paint_roll_mirror_piece_materials:
		if material != null:
			materials.append(material)
	for material in materials:
		material.set_shader_parameter("ball_center", center)
		material.set_shader_parameter("ball_radius", radius)
		material.set_shader_parameter("ball_velocity", velocity)
		material.set_shader_parameter("camera_distance", 3.2)
		material.set_shader_parameter("flow_time", _color_flow_time)
		material.set_shader_parameter("ball_basis_x", basis.x.normalized())
		material.set_shader_parameter("ball_basis_y", basis.y.normalized())
		material.set_shader_parameter("ball_basis_z", basis.z.normalized())
		if _core_dye_texture != null:
			material.set_shader_parameter("ball_dye_mask", _core_dye_texture)
		material.set_shader_parameter("flow_color_0", palette[0])
		material.set_shader_parameter("flow_color_1", palette[1])
		material.set_shader_parameter("flow_color_2", palette[2])
		material.set_shader_parameter("flow_color_3", palette[3])


func _get_core_flow_palette_for_shader() -> Array[Color]:
	var fallback: Array[Color] = [
		Color(0.9, 0.12, 0.08, 1.0),
		Color(0.1, 0.36, 0.9, 1.0),
		Color(0.96, 0.72, 0.12, 1.0),
		Color(0.18, 0.62, 0.34, 1.0),
	]
	if _core_flow_palette.is_empty():
		return fallback
	var result: Array[Color] = []
	for i in range(4):
		result.append(_core_flow_palette[i % _core_flow_palette.size()])
	return result


func _apply_paint_roll_stage(stage_index: int) -> void:
	if _paint_roll_stage_data.is_empty():
		return
	_paint_roll_stage_index = clampi(stage_index, 0, _paint_roll_stage_data.size() - 1)
	var stage := _paint_roll_stage_data[_paint_roll_stage_index]
	var color_texture: Texture2D = stage["color_texture"]
	var reference_texture: Texture2D = stage["reference_texture"]
	var is_mirror_stage := _is_paint_roll_mirror_stage()
	_paint_roll_source_image = color_texture.get_image() if color_texture != null else null
	_paint_roll_bw_reference_image = reference_texture.get_image() if reference_texture != null else null
	if _paint_roll_bw != null:
		_paint_roll_bw.texture = color_texture
		_paint_roll_bw.visible = not is_mirror_stage
	if _paint_roll_color != null:
		_paint_roll_color.texture = color_texture
		_paint_roll_color.visible = not is_mirror_stage
	if _paint_roll_trail != null:
		_paint_roll_trail.visible = not is_mirror_stage
	if _paint_roll_mirror_overlay != null:
		_paint_roll_mirror_overlay.visible = is_mirror_stage
		_paint_roll_mirror_overlay.modulate.a = 1.0
	if _paint_roll_mirror_back != null:
		_paint_roll_mirror_back.visible = is_mirror_stage
		if _paint_roll_mirror_back.material is ShaderMaterial:
			(_paint_roll_mirror_back.material as ShaderMaterial).set_shader_parameter("burn_progress", 0.0)
	if _paint_roll_mirror_plate != null:
		_paint_roll_mirror_plate.visible = false
		_paint_roll_mirror_plate.modulate.a = 1.0
		if _paint_roll_mirror_plate.material is ShaderMaterial:
			(_paint_roll_mirror_plate.material as ShaderMaterial).set_shader_parameter("burn_progress", 0.0)
	if _paint_roll_mirror != null:
		_paint_roll_mirror.visible = is_mirror_stage
		_paint_roll_mirror.modulate.a = 1.0
	if _paint_roll_mirror_piece_root != null:
		_paint_roll_mirror_piece_root.visible = is_mirror_stage
		_paint_roll_mirror_piece_root.modulate.a = 1.0
		_reset_paint_roll_mirror_layers()
	if _paint_roll_mirror_material != null:
		_paint_roll_mirror_material.set_shader_parameter("burn_progress", 0.0)
		_update_right6_mirror_shader()
	_clear_paint_roll_shards()
	if _paint_roll_canvas != null:
		_paint_roll_canvas.modulate.a = 1.0
	if _paint_roll_frame != null:
		_paint_roll_frame.modulate.a = 1.0
	_paint_roll_view_uv = stage.get("start_uv", Vector2(0.5, 0.5))
	_paint_roll_velocity_uv = Vector2.ZERO
	_paint_roll_completion_timer = 0.0
	_paint_roll_finished = false
	_paint_roll_mirror_elapsed = 0.0
	_paint_roll_mirror_layer_index = 0
	_paint_roll_mirror_contact_timer = 0.0
	_paint_roll_mirror_breaking = false
	_clear_paint_roll_mirror_cracks()
	_paint_roll_mirror_collapsing = false
	_paint_roll_mirror_done = false
	_reset_paint_roll_mask()
	_build_paint_roll_resistance_image()
	if is_mirror_stage and _paint_roll_material != null:
		_paint_roll_material.set_shader_parameter("final_fill", 1.0)
		_paint_roll_material.set_shader_parameter("burn_progress", 0.0)
	if _paint_roll_root != null and _paint_roll_root.size.x > 1.0:
		_layout_paint_roll_scene()
	if is_mirror_stage:
		_sync_paint_roll_mirror_overlay()
		_update_right6_mirror_shader()


func _is_paint_roll_mirror_stage() -> bool:
	if _paint_roll_stage_data.is_empty():
		return false
	var stage := _paint_roll_stage_data[clampi(_paint_roll_stage_index, 0, _paint_roll_stage_data.size() - 1)]
	return String(stage.get("type", "")) == "mirror"


func _compute_paint_roll_ball_diameter(viewport_size: Vector2) -> float:
	var painting_area: float = maxf(1.0, viewport_size.x * viewport_size.y)
	var target_projection_area: float = painting_area / 25.0
	var visual_diameter: float = sqrt(target_projection_area * 4.0 / PI)
	return clampf(visual_diameter, minf(viewport_size.x, viewport_size.y) * 0.14, minf(viewport_size.x, viewport_size.y) * 0.32)


func _apply_stage(next_stage_index: int, animate_entry: bool) -> void:
	if _left_help_prompt_overlay != null:
		_left_help_prompt_overlay.set_hint_enabled(true)
		_left_help_prompt_overlay.reset_inactivity_tracking()
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
	if _paint_roll_running:
		_update_paint_roll_input(delta)
		return

	var input_vec := InputMappingStateRef.get_raw_wasd_vector()

	if input_vec.length_squared() <= 0.0:
		return

	input_vec = input_vec.normalized()
	var rotate_amount := deg_to_rad(sphere_rotate_speed_deg) * delta
	model_root.rotate_y(-input_vec.x * rotate_amount)
	model_root.rotate_object_local(Vector3.RIGHT, -input_vec.y * rotate_amount)

	if _transition_running:
		return

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
	if _left_help_prompt_overlay != null:
		_left_help_prompt_overlay.notify_valid_action()

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
	_play_sphere_hit_beacon(color, local_dir)
	var cut: Dictionary = _add_shell_cut(local_dir)
	_add_core_dye_to_mask(color, cut)
	_register_crack_overflow(color, cut)


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
	_register_core_flow_color(color)
	if _core_material != null:
		_core_material.set_shader_parameter("pulse_color", color)


func _register_core_flow_color(color: Color) -> void:
	var clean := Color(color.r, color.g, color.b, 1.0)
	if _core_flow_palette.size() < 4:
		_core_flow_palette.append(clean)
	else:
		var slot: int = (_core_color_count - 1) % 4
		_core_flow_palette[slot] = _core_flow_palette[slot].lerp(clean, 0.58)
	_update_core_flow_palette()


func _update_core_flow_palette() -> void:
	if _core_material == null:
		return
	var fallback: Array[Color] = [
		Color(0.9, 0.12, 0.08, 1.0),
		Color(0.1, 0.36, 0.9, 1.0),
		Color(0.96, 0.72, 0.12, 1.0),
		Color(0.18, 0.62, 0.34, 1.0),
	]
	for i in range(4):
		var color := fallback[i]
		if i < _core_flow_palette.size():
			color = _core_flow_palette[i]
		_core_material.set_shader_parameter("flow_color_%d" % i, color)


func _add_core_dye_to_mask(color: Color, cut: Dictionary) -> void:
	if _core_dye_image == null or _core_dye_texture == null:
		return
	_core_dye_queue.append({
		"color": color,
		"cut": cut,
		"candidate_cells": cut.get("dye_candidate_cells", []),
		"index": 0,
	})


func _process_core_dye_queue() -> void:
	if _core_dye_queue.is_empty():
		if _core_dye_upload_pending and _core_dye_texture != null:
			_core_dye_texture.update(_core_dye_image)
			_core_dye_upload_pending = false
		return
	var budget: int = 42
	while budget > 0 and not _core_dye_queue.is_empty():
		var entry: Dictionary = _core_dye_queue[0]
		var color: Color = entry["color"] as Color
		var cut: Dictionary = entry["cut"] as Dictionary
		var candidate_cells: Array = entry["candidate_cells"] as Array
		var index: int = int(entry["index"])
		while budget > 0 and index < candidate_cells.size():
			var cell_index: int = int(candidate_cells[index])
			var dir: Vector3 = _shell_cell_dirs[cell_index]
			if _does_cut_hit_direction(cut, dir, 1.0, core_dye_width_scale):
				var y: int = int(cell_index / shell_longitude_segments)
				var x: int = cell_index % shell_longitude_segments
				_paint_core_dye_cell(color, y, x)
				_core_dye_upload_pending = true
			index += 1
			budget -= 1
		if index >= candidate_cells.size():
			_core_dye_queue.pop_front()
		else:
			entry["index"] = index
			_core_dye_queue[0] = entry
	if _core_dye_upload_pending and _core_dye_texture != null:
		_core_dye_texture.update(_core_dye_image)
		_core_dye_upload_pending = false


func _paint_core_dye_cell(color: Color, y: int, x: int) -> void:
	var px0: int = int(floor(float(x) / float(shell_longitude_segments) * float(_core_dye_mask_size.x)))
	var px1: int = int(ceil(float(x + 1) / float(shell_longitude_segments) * float(_core_dye_mask_size.x)))
	var py0: int = int(floor(float(y) / float(shell_latitude_segments) * float(_core_dye_mask_size.y)))
	var py1: int = int(ceil(float(y + 1) / float(shell_latitude_segments) * float(_core_dye_mask_size.y)))
	var pad_x: int = 1
	var pad_y: int = 1
	for py in range(maxi(0, py0 - pad_y), mini(_core_dye_mask_size.y, py1 + pad_y + 1)):
		for px in range(px0 - pad_x, px1 + pad_x + 1):
			var wrapped_px: int = posmod(px, _core_dye_mask_size.x)
			var current: Color = _core_dye_image.get_pixel(wrapped_px, py)
			if current.a <= 0.01:
				_core_dye_image.set_pixel(wrapped_px, py, Color(color.r, color.g, color.b, 0.74))
			else:
				var existing_weight: float = clampf(current.a, 0.0, 1.0)
				var new_weight: float = 0.42
				var total_weight: float = existing_weight + new_weight
				var mixed := Color(
					(current.r * existing_weight + color.r * new_weight) / total_weight,
					(current.g * existing_weight + color.g * new_weight) / total_weight,
					(current.b * existing_weight + color.b * new_weight) / total_weight,
					clampf(current.a + 0.16, 0.0, 1.0)
				)
				_core_dye_image.set_pixel(wrapped_px, py, mixed)


func _play_sphere_hit_beacon(color: Color, local_dir: Vector3) -> void:
	var dir: Vector3 = local_dir.normalized()
	var beam := MeshInstance3D.new()
	beam.name = "PersistentSphereHitBeacon"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.006
	mesh.bottom_radius = 0.014
	mesh.height = 0.76
	mesh.radial_segments = 16
	beam.mesh = mesh
	beam.material_override = _create_beacon_material(color)
	beam.position = dir * (left_sphere_radius + 0.38)
	beam.basis = Basis(Quaternion(Vector3.UP, -dir))
	beam.add_to_group("c3l1_crack_residue")
	model_root.add_child(beam)


func _create_beacon_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(color.r, color.g, color.b, 0.50)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 1.65
	return material


func _register_crack_overflow(color: Color, cut: Dictionary) -> void:
	_active_crack_emitters.append({
		"color": color,
		"cut": cut,
	})


func _update_crack_overflow_emitters(delta: float) -> void:
	if _paint_roll_running or _paint_roll_finished:
		return
	if _active_crack_emitters.is_empty():
		return
	_overflow_emit_timer -= delta
	if _overflow_emit_timer > 0.0:
		return
	_overflow_emit_timer = 0.055
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var emitter_count: int = mini(_active_crack_emitters.size(), 5)
	for i in range(emitter_count):
		var emitter_index: int = rng.randi_range(0, _active_crack_emitters.size() - 1)
		var emitter: Dictionary = _active_crack_emitters[emitter_index]
		_emit_one_crack_overflow_particle(emitter["color"] as Color, emitter["cut"] as Dictionary, rng)


func _emit_one_crack_overflow_particle(color: Color, cut: Dictionary, rng: RandomNumberGenerator) -> void:
	var center: Vector3 = cut["center"] as Vector3
	var tangent_a: Vector3 = cut["tangent_a"] as Vector3
	var tangent_b: Vector3 = cut["tangent_b"] as Vector3
	var segments: Array = cut["segments"] as Array
	if segments.is_empty():
		return
	var segment: Dictionary = segments[rng.randi_range(0, segments.size() - 1)]
	var a: Vector2 = segment["a"] as Vector2
	var b: Vector2 = segment["b"] as Vector2
	var offset: Vector2 = a.lerp(b, rng.randf_range(0.04, 0.98))
	var dir: Vector3 = (center + tangent_a * offset.x + tangent_b * offset.y).normalized()
	var side: Vector3 = (tangent_a * rng.randf_range(-0.5, 0.5) + tangent_b * rng.randf_range(-0.5, 0.5)).normalized()
	_spawn_overflow_particle(color, dir, side, rng)


func _spawn_overflow_particle(color: Color, dir: Vector3, side: Vector3, rng: RandomNumberGenerator) -> void:
	var particle := MeshInstance3D.new()
	particle.name = "CrackOverflowParticle"
	var mesh := SphereMesh.new()
	var radius: float = rng.randf_range(0.009, 0.022)
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 8
	mesh.rings = 4
	particle.mesh = mesh
	var material := _create_overflow_particle_material(color, rng)
	particle.material_override = material
	particle.position = dir * (left_sphere_radius + 0.035)
	particle.add_to_group("c3l1_crack_residue")
	model_root.add_child(particle)
	var target: Vector3 = particle.position + dir * rng.randf_range(0.12, 0.26) + side * rng.randf_range(0.04, 0.16)
	var life: float = rng.randf_range(1.15, 1.85)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(particle, "position", target, life).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(particle, "scale", Vector3.ONE * rng.randf_range(0.12, 0.30), life).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(material, "albedo_color", Color(color.r, color.g, color.b, 0.0), life).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(material, "emission_energy_multiplier", 0.0, life).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(func() -> void:
		if is_instance_valid(particle):
			particle.queue_free()
	)


func _create_overflow_particle_material(color: Color, rng: RandomNumberGenerator) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var shifted := color.lerp(Color(1.0, 1.0, 1.0, 1.0), rng.randf_range(0.0, 0.18))
	material.albedo_color = Color(shifted.r, shifted.g, shifted.b, rng.randf_range(0.62, 0.84))
	material.emission_enabled = true
	material.emission = shifted
	material.emission_energy_multiplier = rng.randf_range(0.9, 1.7)
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
	var step_count: int = 5
	for step in range(1, step_count + 1):
		var progress: float = float(step) / float(step_count)
		var delay: float = spread_sec * float(step - 1) / float(step_count)
		var timer := get_tree().create_timer(delay)
		timer.timeout.connect(
			func() -> void:
				var dirty_chunks: Array[int] = _apply_shell_cut_to_cells(cut, progress)
				_rebuild_shell_chunks(dirty_chunks),
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
	var candidate_cells: Array[int] = _collect_cut_candidate_cells(center_dir, max_radius)
	var dye_candidate_cells: Array[int] = _collect_cut_candidate_cells(center_dir, max_radius * core_dye_width_scale)
	return {
		"center": center_dir,
		"tangent_a": tangent_a,
		"tangent_b": tangent_b,
		"segments": segments,
		"cavity_radius": cavity_radius,
		"max_radius": max_radius,
		"candidate_cells": candidate_cells,
		"dye_candidate_cells": dye_candidate_cells,
	}


func _collect_cut_candidate_cells(center_dir: Vector3, max_radius: float) -> Array[int]:
	var cells: Array[int] = []
	var center_theta: float = acos(clampf(center_dir.y, -1.0, 1.0))
	var center_phi: float = atan2(center_dir.z, center_dir.x)
	if center_phi < 0.0:
		center_phi += TAU
	var theta0: float = clampf(center_theta - max_radius, 0.0, PI)
	var theta1: float = clampf(center_theta + max_radius, 0.0, PI)
	var y0: int = clampi(int(floor(theta0 / PI * float(shell_latitude_segments))) - 1, 0, shell_latitude_segments - 1)
	var y1: int = clampi(int(ceil(theta1 / PI * float(shell_latitude_segments))) + 1, 0, shell_latitude_segments - 1)
	for y in range(y0, y1 + 1):
		var theta: float = PI * (float(y) + 0.5) / float(shell_latitude_segments)
		var phi_span: float = max_radius / maxf(0.12, sin(theta))
		if phi_span >= PI:
			for x_all in range(shell_longitude_segments):
				var index_all: int = _shell_cell_index(y, x_all)
				if center_dir.angle_to(_shell_cell_dirs[index_all]) <= max_radius:
					cells.append(index_all)
			continue
		var x0: int = int(floor((center_phi - phi_span) / TAU * float(shell_longitude_segments))) - 1
		var x1: int = int(ceil((center_phi + phi_span) / TAU * float(shell_longitude_segments))) + 1
		for x_raw in range(x0, x1 + 1):
			var x: int = posmod(x_raw, shell_longitude_segments)
			var index: int = _shell_cell_index(y, x)
			if center_dir.angle_to(_shell_cell_dirs[index]) <= max_radius:
				cells.append(index)
	return cells


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


func _apply_shell_cut_to_cells(cut: Dictionary, progress: float = 1.0) -> Array[int]:
	var dirty: Dictionary = {}
	var candidate_cells: Array = cut.get("candidate_cells", [])
	for cell_variant in candidate_cells:
		var i: int = int(cell_variant)
		if bool(_shell_cut_cells[i]):
			continue
		if _does_cut_hit_direction(cut, _shell_cell_dirs[i], progress):
			_shell_cut_cells[i] = true
			var chunk_index: int = int(_shell_cell_to_chunk[i])
			dirty[chunk_index] = true
			_mark_neighbor_chunks_dirty(dirty, i)
	var dirty_chunks: Array[int] = []
	for key in dirty.keys():
		dirty_chunks.append(int(key))
	return dirty_chunks


func _mark_neighbor_chunks_dirty(dirty: Dictionary, cell_index: int) -> void:
	var y: int = int(cell_index / shell_longitude_segments)
	var x: int = cell_index % shell_longitude_segments
	dirty[_shell_chunk_index_for_cell(y, x - 1)] = true
	dirty[_shell_chunk_index_for_cell(y, x + 1)] = true
	if y > 0:
		dirty[_shell_chunk_index_for_cell(y - 1, x)] = true
	if y < shell_latitude_segments - 1:
		dirty[_shell_chunk_index_for_cell(y + 1, x)] = true


func _does_cut_hit_direction(cut: Dictionary, dir: Vector3, progress: float = 1.0, width_scale: float = 1.0) -> bool:
	var center: Vector3 = cut["center"] as Vector3
	var angle: float = center.angle_to(dir)
	var max_radius: float = float(cut.get("max_radius", crack_max_angular_length)) * width_scale
	if angle > max_radius:
		return false
	var cavity_radius: float = float(cut["cavity_radius"]) * width_scale
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
		var width: float = float(segment["width"]) * width_scale
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


func _start_final_shell_reveal() -> void:
	if _final_reveal_running:
		return
	_final_reveal_running = true
	_final_reveal_elapsed = 0.0
	_final_break_cursor = 0
	_final_detached_chunks.clear()
	_final_detach_tween_count = 0
	_final_break_order = _build_final_break_order()
	_update_core_fill_color()
	if _core_material != null:
		_core_material.set_shader_parameter("fill_progress", 0.0)
	_status_label.text = ""


func _build_final_break_order() -> Array[int]:
	var scored: Array[Dictionary] = []
	for i in range(_shell_cell_dirs.size()):
		var dir: Vector3 = _shell_cell_dirs[i]
		var score: float = 10.0
		for crack_dir in _crack_surface_dirs:
			score = minf(score, dir.angle_to(crack_dir))
		score += abs(dir.y) * 0.08
		scored.append({"index": i, "score": score})
	scored.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["score"]) < float(b["score"])
	)
	var order: Array[int] = []
	for item in scored:
		order.append(int(item["index"]))
	return order


func _update_core_fill_color() -> void:
	if _core_material == null:
		return
	_update_core_flow_palette()


func _update_final_shell_reveal(delta: float) -> void:
	if not _final_reveal_running:
		return
	_final_reveal_elapsed += delta
	var progress: float = clampf(_final_reveal_elapsed / final_reveal_sec, 0.0, 1.0)
	var fill_progress: float = smoothstep(0.03, 0.62, progress)
	if _core_material != null:
		_core_material.set_shader_parameter("fill_progress", fill_progress)
		var reveal_flow: float = smoothstep(0.54, 0.94, progress) * 0.72
		_core_material.set_shader_parameter("roll_flow_boost", reveal_flow)
	_update_final_shell_cut(progress)
	if progress > 0.58:
		_detach_final_shell_chunks(progress)
	if progress >= 1.0 and _shell_rebuild_queue.is_empty() and _final_detach_tween_count <= 0:
		_final_reveal_running = false
		_start_paint_roll_transition()


func _update_final_shell_cut(progress: float) -> void:
	if _final_break_order.is_empty():
		return
	var eased: float = smoothstep(0.04, 0.86, progress)
	var target_count: int = clampi(int(float(_final_break_order.size()) * eased), 0, _final_break_order.size())
	var dirty: Dictionary = {}
	var budget: int = 42
	while _final_break_cursor < target_count and budget > 0:
		var cell_index: int = _final_break_order[_final_break_cursor]
		_final_break_cursor += 1
		if bool(_shell_cut_cells[cell_index]):
			continue
		_shell_cut_cells[cell_index] = true
		dirty[int(_shell_cell_to_chunk[cell_index])] = true
		_mark_neighbor_chunks_dirty(dirty, cell_index)
		budget -= 1
	var dirty_chunks: Array[int] = []
	for key in dirty.keys():
		dirty_chunks.append(int(key))
	_rebuild_shell_chunks(dirty_chunks)


func _detach_final_shell_chunks(progress: float) -> void:
	var detach_progress: float = smoothstep(0.58, 0.96, progress)
	var target_count: int = int(float(_shell_chunks.size()) * detach_progress)
	var detached_count: int = _final_detached_chunks.size()
	if detached_count >= target_count:
		return
	for chunk_index in range(_shell_chunks.size()):
		if detached_count >= target_count:
			return
		if bool(_final_detached_chunks.get(chunk_index, false)):
			continue
		_final_detached_chunks[chunk_index] = true
		_animate_shell_chunk_detach(chunk_index)
		detached_count += 1


func _animate_shell_chunk_detach(chunk_index: int) -> void:
	if chunk_index < 0 or chunk_index >= _shell_chunks.size():
		return
	var chunk := _shell_chunks[chunk_index]
	if chunk == null or not is_instance_valid(chunk):
		return
	var center_dir: Vector3 = _shell_chunk_center_dir(chunk_index)
	_final_detach_tween_count += 1
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(chunk, "position", center_dir * 0.42, 2.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(chunk, "rotation", Vector3(center_dir.z, center_dir.x, center_dir.y) * 1.8, 2.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(chunk, "scale", Vector3.ONE * 0.62, 2.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(func() -> void:
		if is_instance_valid(chunk):
			chunk.visible = false
		_final_detach_tween_count = maxi(0, _final_detach_tween_count - 1)
	)


func _shell_chunk_center_dir(chunk_index: int) -> Vector3:
	var chunk_col: int = chunk_index % _shell_chunk_cols
	var chunk_row: int = int(chunk_index / _shell_chunk_cols)
	var y: int = clampi(chunk_row * _shell_chunk_cell_size + _shell_chunk_cell_size / 2, 0, shell_latitude_segments - 1)
	var x: int = posmod(chunk_col * _shell_chunk_cell_size + _shell_chunk_cell_size / 2, shell_longitude_segments)
	return _shell_cell_dirs[_shell_cell_index(y, x)]


func _start_paint_roll_transition() -> void:
	if _paint_roll_running or _paint_roll_finished:
		return
	if _left_help_prompt_overlay != null:
		_left_help_prompt_overlay.set_hint_enabled(false)
	_transition_running = true
	_paint_roll_transitioning = true
	_prepare_ball_for_paint_roll()
	_fade_crack_residue_for_paint_roll()
	_apply_paint_roll_stage(0)
	_layout_paint_roll_scene()
	_paint_roll_root.visible = true
	_paint_roll_root.modulate.a = 0.0
	_paint_roll_velocity_uv = Vector2.ZERO

	var root_global := get_global_rect().position
	var source_rect := left_3d.get_global_rect()
	if left_3d.get_parent() != self:
		left_3d.reparent(self)
	left_3d.set_anchors_preset(Control.PRESET_TOP_LEFT)
	left_3d.position = source_rect.position - root_global
	left_3d.size = source_rect.size
	left_3d.custom_minimum_size = Vector2.ZERO
	left_3d.z_index = 20
	left_3d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_3d.stretch = true

	var viewport_size := get_viewport_rect().size
	if size.x > 1.0 and size.y > 1.0:
		viewport_size = size
	var render_box_size := _paint_roll_ball_diameter_px / maxf(0.15, _paint_roll_sphere_fill_ratio)
	var target_size := Vector2(render_box_size, render_box_size)
	var target_pos := viewport_size * 0.5 - target_size * 0.5

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_paint_roll_root, "modulate:a", 1.0, 1.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(right_panel, "modulate:a", 0.0, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(left_3d, "position", target_pos, 1.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(left_3d, "size", target_size, 1.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_run_paint_roll_stage_entry(false)
	await tween.finished
	while _paint_roll_stage_transitioning:
		await get_tree().process_frame
	_paint_roll_running = true
	_paint_roll_transitioning = false
	_paint_roll_completion_timer = 0.0
	_paint_roll_finished = false
	_status_label.text = ""
	_ease_core_flow_into_paint_roll()


func _run_paint_roll_stage_entry(from_stage_switch: bool) -> void:
	if _paint_roll_root == null or _paint_roll_canvas == null:
		return
	_paint_roll_stage_transitioning = true
	_paint_roll_running = false
	_layout_paint_roll_scene()
	var viewport_size := _paint_roll_root.size
	var start_scale := 0.52 if from_stage_switch else 0.58
	var start_offset := Vector2(viewport_size.x * 0.86, 0.0)
	var target_scale := 1.0
	var target_rotation := painting_tilt_degrees
	if from_stage_switch:
		target_scale = _get_paint_roll_overview_scale()
		target_rotation = 0.0
	_set_paint_roll_picture_transform(_paint_roll_view_uv, target_scale, target_rotation, Vector2.ZERO)
	var target_canvas_position := _paint_roll_canvas.position
	var target_frame_position := _paint_roll_frame.position
	var target_canvas_scale := _paint_roll_canvas.scale
	var target_frame_scale := _paint_roll_frame.scale
	var target_canvas_rotation := _paint_roll_canvas.rotation_degrees
	var target_frame_rotation := _paint_roll_frame.rotation_degrees
	_set_paint_roll_picture_transform(_paint_roll_view_uv, start_scale, 0.0, start_offset)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_paint_roll_canvas, "position", target_canvas_position, 1.05).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_paint_roll_frame, "position", target_frame_position, 1.05).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_paint_roll_canvas, "scale", target_canvas_scale, 1.05).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_paint_roll_frame, "scale", target_frame_scale, 1.05).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_paint_roll_canvas, "rotation_degrees", target_canvas_rotation, 1.05).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_paint_roll_frame, "rotation_degrees", target_frame_rotation, 1.05).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tween.finished
	if from_stage_switch:
		var zoom_tween := create_tween()
		zoom_tween.tween_method(
			func(value: float) -> void:
				_set_paint_roll_picture_transform(
					_paint_roll_view_uv,
					lerpf(target_scale, 1.0, value),
					lerpf(target_rotation, painting_tilt_degrees, value),
					Vector2.ZERO
				),
			0.0,
			1.0,
			stage_entry_zoom_sec
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		await zoom_tween.finished
	_set_paint_roll_picture_transform(_paint_roll_view_uv, 1.0, painting_tilt_degrees, Vector2.ZERO)
	_paint_roll_stage_transitioning = false


func _reset_paint_roll_mask() -> void:
	if _paint_roll_mask_image == null:
		return
	_paint_roll_mask_image.fill(Color(0.0, 0.0, 0.0, 0.0))
	if _paint_roll_deposit_image != null:
		_paint_roll_deposit_image.fill(Color(0.0, 0.0, 0.0, 0.0))
	if _paint_roll_trail_image != null:
		_paint_roll_trail_image.fill(Color(0.0, 0.0, 0.0, 0.0))
		if _paint_roll_trail_texture != null:
			_paint_roll_trail_texture.update(_paint_roll_trail_image)
	if _paint_roll_mask_texture != null:
		_paint_roll_mask_texture.update(_paint_roll_mask_image)
	if _paint_roll_material != null:
		_paint_roll_material.set_shader_parameter("final_fill", 0.0)
		_paint_roll_material.set_shader_parameter("burn_progress", 0.0)


func _update_dev_paint_roll_skip(delta: float) -> void:
	if not _dev_paint_roll_skip_enabled:
		return
	if not _paint_roll_running or _paint_roll_stage_transitioning or _paint_roll_finished:
		_dev_paint_roll_skip_hold_sec = 0.0
		_dev_paint_roll_skip_triggered = false
		return
	if _is_paint_roll_mirror_stage():
		_dev_paint_roll_skip_hold_sec = 0.0
		_dev_paint_roll_skip_triggered = false
		return
	if not Input.is_key_pressed(KEY_SPACE):
		_dev_paint_roll_skip_hold_sec = 0.0
		_dev_paint_roll_skip_triggered = false
		return
	_dev_paint_roll_skip_hold_sec += delta
	if _dev_paint_roll_skip_hold_sec >= 3.0 and not _dev_paint_roll_skip_triggered:
		_dev_paint_roll_skip_triggered = true
		_dev_fill_current_paint_roll_stage()


func _dev_fill_current_paint_roll_stage() -> void:
	if _paint_roll_mask_image == null or _paint_roll_mask_texture == null:
		return
	for y in range(_paint_roll_mask_size.y):
		for x in range(_paint_roll_mask_size.x):
			_paint_roll_mask_image.set_pixel(x, y, Color(1.0, 1.0, 1.0, 1.0))
	_paint_roll_mask_texture.update(_paint_roll_mask_image)
	if _paint_roll_material != null:
		_paint_roll_material.set_shader_parameter("final_fill", 1.0)
	_finish_paint_roll_stage()


func _prepare_ball_for_paint_roll() -> void:
	if left_viewport != null:
		left_viewport.transparent_bg = true
	if _left_environment != null:
		_left_environment.background_color = Color(0.0, 0.0, 0.0, 0.0)
	if sphere_mesh != null:
		sphere_mesh.visible = false
	if _shell_root != null and is_instance_valid(_shell_root):
		_shell_root.visible = false
	if _core_mesh != null and is_instance_valid(_core_mesh):
		_core_mesh.visible = true
	if _core_material != null:
		_core_material.set_shader_parameter("fill_progress", 1.0)
		_core_material.set_shader_parameter("pulse_mix", 0.0)
		_update_core_flow_palette()


func _ease_core_flow_into_paint_roll() -> void:
	if _core_material == null:
		return
	var current_boost: float = 0.72
	var current_variant: Variant = _core_material.get_shader_parameter("roll_flow_boost")
	if current_variant is float:
		current_boost = float(current_variant)
	var tween := create_tween()
	tween.tween_method(
		Callable(self, "_set_core_roll_flow_boost_for_tween"),
		current_boost,
		0.92,
		2.8
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _set_core_roll_flow_boost_for_tween(value: float) -> void:
	if _core_material != null:
		_core_material.set_shader_parameter("roll_flow_boost", value)


func _fade_crack_residue_for_paint_roll() -> void:
	_active_crack_emitters.clear()
	_overflow_emit_timer = 9999.0
	for node in get_tree().get_nodes_in_group("c3l1_crack_residue"):
		if node is Node3D:
			_fade_and_remove_mesh_instance(node as Node3D, 0.45)
	if model_root == null:
		return
	_fade_crack_residue_recursive(model_root)


func _fade_crack_residue_recursive(node: Node) -> void:
	for child in node.get_children():
		if child == null or not is_instance_valid(child):
			continue
		if child.name.begins_with("PersistentSphereHitBeacon") or child.name.begins_with("CrackOverflowParticle"):
			if child is Node3D:
				_fade_and_remove_mesh_instance(child as Node3D, 0.45)
		else:
			_fade_crack_residue_recursive(child)


func _fade_and_remove_mesh_instance(node: Node3D, duration: float) -> void:
	if node == null or not is_instance_valid(node):
		return
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(node, "scale", Vector3.ONE * 0.01, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		var material := mesh_instance.material_override
		if material is StandardMaterial3D:
			var standard := material as StandardMaterial3D
			tween.tween_property(standard, "albedo_color", Color(standard.albedo_color.r, standard.albedo_color.g, standard.albedo_color.b, 0.0), duration)
			if standard.emission_enabled:
				tween.tween_property(standard, "emission_energy_multiplier", 0.0, duration)
	tween.chain().tween_callback(Callable(node, "queue_free"))


func _update_paint_roll_input(delta: float) -> void:
	if _paint_roll_stage_transitioning:
		return
	var input_vec := InputMappingStateRef.get_raw_wasd_vector()

	if input_vec.length_squared() > 0.0:
		input_vec = input_vec.normalized()
		var control_scale := 1.0
		if _is_paint_roll_mirror_stage():
			control_scale = maxf(0.05, 1.0 - paint_roll_mirror_control_loss)
		_paint_roll_velocity_uv += input_vec * paint_roll_acceleration_uv * control_scale * delta
	else:
		_paint_roll_velocity_uv = _paint_roll_velocity_uv.move_toward(Vector2.ZERO, paint_roll_friction_uv * delta)

	if _is_paint_roll_mirror_stage():
		_apply_paint_roll_mirror_slope_force(delta)

	if _paint_roll_velocity_uv.length() > paint_roll_max_speed_uv:
		_paint_roll_velocity_uv = _paint_roll_velocity_uv.normalized() * paint_roll_max_speed_uv

	_update_core_drag_flow()
	var previous_uv := _paint_roll_view_uv
	_paint_roll_view_uv += _paint_roll_velocity_uv * delta
	_bounce_paint_roll_at_edges()
	_update_paint_roll_canvas_transform()
	if _is_paint_roll_mirror_stage():
		_update_right6_mirror_shader()
	var movement := _paint_roll_view_uv - previous_uv
	if movement.length_squared() > 0.00000001:
		var movement_dir := movement.normalized()
		_roll_sphere_for_paint_movement(movement_dir, movement.length())
		if not _is_paint_roll_mirror_stage():
			_paint_roll_at(_paint_roll_view_uv)
			_paint_roll_trail_at(previous_uv, _paint_roll_view_uv, movement_dir)

	if not _is_paint_roll_mirror_stage():
		_paint_roll_completion_timer -= delta
		if _paint_roll_completion_timer <= 0.0:
			_paint_roll_completion_timer = 0.45
			_check_paint_roll_completion()


func _apply_paint_roll_mirror_slope_force(delta: float) -> void:
	if paint_roll_mirror_slope_force_uv <= 0.0 and paint_roll_mirror_tilt_force_uv <= 0.0 and paint_roll_mirror_surface_force_uv <= 0.0:
		return
	var layer_index := clampi(_paint_roll_mirror_layer_index, 0, 2)
	var uv := _paint_roll_view_uv
	var p := uv * 2.0 - Vector2.ONE
	var downhill := _get_paint_roll_mirror_ring_force(p, layer_index) * paint_roll_mirror_slope_force_uv
	var tilt := _get_paint_roll_mirror_layer_tilt(layer_index) * paint_roll_mirror_tilt_force_uv
	var surface_force := _get_paint_roll_mirror_layer_surface_force(p, layer_index) * paint_roll_mirror_surface_force_uv
	var layer_scale := 1.0 + float(layer_index) * 0.24
	_paint_roll_velocity_uv += (downhill + tilt + surface_force) * layer_scale * delta


func _get_paint_roll_mirror_ring_force(p: Vector2, layer_index: int) -> Vector2:
	var radial := p.normalized() if p.length_squared() > 0.0001 else _get_paint_roll_mirror_layer_tilt(layer_index).normalized()
	var r := p.length()
	var center_push := smoothstep(0.02, 0.22, r) * (1.0 - smoothstep(0.24, 0.40, r)) * 0.72
	var ring_center := 0.54 + float(layer_index) * 0.035
	var ring_width := 0.19 - float(layer_index) * 0.018
	var ring_delta := (r - ring_center) / maxf(0.001, ring_width)
	var ring_push := exp(-ring_delta * ring_delta) * 1.25
	var edge_flatten := 1.0 - smoothstep(0.74, 0.98, r)
	return radial * (center_push + ring_push) * edge_flatten


func _get_paint_roll_mirror_layer_tilt(layer_index: int) -> Vector2:
	match layer_index:
		0:
			return Vector2(0.34, -0.18)
		1:
			return Vector2(-0.25, 0.36)
		_:
			return Vector2(0.28, 0.30)


func _get_paint_roll_mirror_layer_surface_force(p: Vector2, layer_index: int) -> Vector2:
	var r := p.length()
	var radial := p.normalized() if r > 0.0001 else Vector2(0.0, 0.0)
	var edge_flatten := 1.0 - smoothstep(0.72, 0.98, r)
	match layer_index:
		0:
			var theta := atan2(p.y, p.x)
			var sector: float = floor((theta + PI) / TAU * 7.0)
			var sector_angle: float = (sector + 0.5) / 7.0 * TAU - PI
			var sector_axis := Vector2(cos(sector_angle), sin(sector_angle))
			return (radial * 0.35 + sector_axis * 0.65).normalized() * (0.20 + r * 0.45) * edge_flatten
		1:
			var q := p - Vector2(0.16, -0.08)
			var lobe_a := (q - Vector2(-0.18, -0.30)).normalized() if (q - Vector2(-0.18, -0.30)).length_squared() > 0.0001 else radial
			var lobe_b := (q - Vector2(0.22, 0.34)).normalized() if (q - Vector2(0.22, 0.34)).length_squared() > 0.0001 else radial
			return (radial * 0.38 + lobe_a * 0.31 + lobe_b * 0.31).normalized() * (0.24 + r * 0.52) * edge_flatten
		_:
			var tangent := Vector2(-radial.y, radial.x)
			var spin := sin((r - 0.54) * 8.0 + atan2(p.y, p.x) * 2.0)
			return (radial * 0.42 + tangent * (0.58 + spin * 0.18)).normalized() * (0.28 + r * 0.58) * edge_flatten


func _sample_paint_roll_mirror_height(p: Vector2, layer_index: int) -> float:
	var r2 := p.length_squared()
	var r := sqrt(r2)
	var theta := atan2(p.y, p.x)
	var edge_falloff := 1.0 - smoothstep(0.72, 1.0, r)
	if layer_index == 0:
		var sector: float = floor((theta + PI) / TAU * 7.0)
		var sector_angle: float = (sector + 0.5) / 7.0 * TAU - PI
		var sector_axis := Vector2(cos(sector_angle), sin(sector_angle))
		var seam := absf(sin((theta - sector_angle) * 3.5))
		var local_push := p.dot(sector_axis)
		var facet_tilt := local_push * (0.075 + 0.055 * _hash_2d(Vector2(sector, 2.7))) * edge_falloff
		var facet_bulge := sin(sector * 2.17 + 1.3) * 0.050 * edge_falloff
		var convex := sqrt(maxf(0.025, 1.0 - r2 * (0.86 + 0.18 * _hash_2d(Vector2(sector, 9.1)))))
		return convex + facet_tilt + facet_bulge - smoothstep(0.84, 0.98, seam) * 0.018 * edge_falloff
	if layer_index == 1:
		var q := p - Vector2(0.16, -0.08)
		var upper_lobe := exp(-(q - Vector2(-0.18, -0.30)).length_squared() * 3.8)
		var lower_lobe := exp(-(q - Vector2(0.22, 0.34)).length_squared() * 2.5)
		var waist := exp(-(q - Vector2(0.02, 0.02)).length_squared() * 8.5)
		var gourd_metric := q.x * q.x * (1.05 + lower_lobe * 0.95) + q.y * q.y * (0.72 + upper_lobe * 1.25)
		var convex := sqrt(maxf(0.025, 1.0 - gourd_metric))
		var bias := (q.x * q.x * q.x * 0.30 - q.x * q.y * q.y * 0.36 + upper_lobe * 0.11 - lower_lobe * 0.09) * edge_falloff
		return convex + bias - waist * 0.065 * edge_falloff
	var convex := sqrt(maxf(0.025, 1.0 - r2))
	var swirl := sin(theta * 3.0 + r * 12.0) * 0.125 * edge_falloff
	var fold := sin(theta * 5.0 - r * 7.5 + p.x * 2.0) * 0.070 * edge_falloff
	var spiral_pull := (p.x * sin(r * 5.0) - p.y * cos(r * 4.0)) * 0.055 * edge_falloff
	return convex + swirl + fold + spiral_pull


func _update_core_drag_flow() -> void:
	if _core_material == null:
		return
	var speed_ratio: float = clampf(_paint_roll_velocity_uv.length() / maxf(0.001, paint_roll_max_speed_uv * 0.72), 0.0, 1.0)
	var target_vec := _core_drag_vector
	if _paint_roll_velocity_uv.length_squared() > 0.000001:
		target_vec = _paint_roll_velocity_uv.normalized()
	_core_drag_vector = _core_drag_vector.lerp(target_vec, 0.28)
	if _core_drag_vector.length_squared() > 0.000001:
		_core_drag_vector = _core_drag_vector.normalized()
	_core_drag_strength = lerpf(_core_drag_strength, speed_ratio, 0.34) if speed_ratio > _core_drag_strength else lerpf(_core_drag_strength, speed_ratio, 0.028)
	_core_material.set_shader_parameter("drag_vector", _core_drag_vector)
	_core_material.set_shader_parameter("drag_strength", _core_drag_strength)


func _bounce_paint_roll_at_edges() -> void:
	if _paint_roll_view_uv.x < 0.0:
		_paint_roll_view_uv.x = 0.0
		_paint_roll_velocity_uv.x = absf(_paint_roll_velocity_uv.x) * paint_roll_bounce
	elif _paint_roll_view_uv.x > 1.0:
		_paint_roll_view_uv.x = 1.0
		_paint_roll_velocity_uv.x = -absf(_paint_roll_velocity_uv.x) * paint_roll_bounce
	if _paint_roll_view_uv.y < 0.0:
		_paint_roll_view_uv.y = 0.0
		_paint_roll_velocity_uv.y = absf(_paint_roll_velocity_uv.y) * paint_roll_bounce
	elif _paint_roll_view_uv.y > 1.0:
		_paint_roll_view_uv.y = 1.0
		_paint_roll_velocity_uv.y = -absf(_paint_roll_velocity_uv.y) * paint_roll_bounce


func _roll_sphere_for_paint_movement(input_vec: Vector2, uv_distance: float) -> void:
	if model_root == null or left_camera == null:
		return
	var camera_basis := left_camera.global_transform.basis
	var screen_right := camera_basis.x.normalized()
	var screen_up := camera_basis.y.normalized()
	var surface_normal_toward_camera := camera_basis.z.normalized()
	var screen_motion := (screen_right * input_vec.x - screen_up * input_vec.y).normalized()
	if screen_motion.length_squared() <= 0.0001:
		return
	var axis_world := surface_normal_toward_camera.cross(screen_motion).normalized()
	var axis_local := (model_root.global_transform.basis.inverse() * axis_world).normalized()
	var contact_radius_px: float = maxf(1.0, _paint_roll_ball_diameter_px * 0.5)
	var pixel_distance: float = uv_distance * minf(_paint_roll_canvas_size.x, _paint_roll_canvas_size.y)
	var angle: float = pixel_distance / contact_radius_px
	model_root.rotate_object_local(axis_local, angle)


func _update_paint_roll_canvas_transform() -> void:
	if _paint_roll_canvas == null or _paint_roll_root == null:
		return
	_set_paint_roll_picture_transform(_paint_roll_view_uv, 1.0, painting_tilt_degrees, Vector2.ZERO)


func _set_paint_roll_picture_transform(view_uv: Vector2, visual_scale: float, rotation_deg: float, center_offset: Vector2 = Vector2.ZERO) -> void:
	if _paint_roll_canvas == null or _paint_roll_root == null:
		return
	var viewport_size := _paint_roll_root.size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0 or _paint_roll_canvas_size.x <= 1.0:
		return
	view_uv.x = clampf(view_uv.x, 0.0, 1.0)
	view_uv.y = clampf(view_uv.y, 0.0, 1.0)
	_paint_roll_canvas.size = _paint_roll_canvas_size
	_paint_roll_canvas.pivot_offset = view_uv * _paint_roll_canvas_size
	_paint_roll_canvas.position = viewport_size * 0.5 + center_offset - _paint_roll_canvas.pivot_offset
	_paint_roll_canvas.scale = Vector2.ONE * visual_scale
	_paint_roll_canvas.rotation_degrees = rotation_deg
	_sync_paint_roll_frame_transform(visual_scale, rotation_deg)


func _sync_paint_roll_frame_transform(visual_scale: float, rotation_deg: float) -> void:
	if _paint_roll_frame == null or _paint_roll_canvas == null:
		return
	var margin := _get_paint_roll_frame_margin()
	var margin_vec := Vector2(margin, margin)
	_paint_roll_frame.size = _paint_roll_canvas_size + margin_vec * 2.0
	_paint_roll_frame.pivot_offset = _paint_roll_canvas.pivot_offset + margin_vec
	_paint_roll_frame.position = _paint_roll_canvas.position - margin_vec
	_paint_roll_frame.scale = Vector2.ONE * visual_scale
	_paint_roll_frame.rotation_degrees = rotation_deg


func _get_paint_roll_frame_margin() -> float:
	if _paint_roll_canvas_size.x <= 1.0 or _paint_roll_canvas_size.y <= 1.0:
		return 24.0
	return maxf(18.0, minf(_paint_roll_canvas_size.x, _paint_roll_canvas_size.y) * gallery_frame_margin_uv)


func _get_paint_roll_overview_scale() -> float:
	if _paint_roll_root == null:
		return 0.72
	var viewport_size := _paint_roll_root.size
	var margin := _get_paint_roll_frame_margin()
	var framed_size := _paint_roll_canvas_size + Vector2(margin, margin) * 2.0
	if framed_size.x <= 1.0 or framed_size.y <= 1.0:
		return 0.72
	return clampf(minf(viewport_size.x / framed_size.x, viewport_size.y / framed_size.y) * 0.82, 0.18, 1.0)


func _clamp_paint_roll_view_uv() -> void:
	_paint_roll_view_uv.x = clampf(_paint_roll_view_uv.x, 0.0, 1.0)
	_paint_roll_view_uv.y = clampf(_paint_roll_view_uv.y, 0.0, 1.0)


func _get_paint_roll_brush_radius_uv() -> float:
	if _paint_roll_canvas_size.x <= 1.0 or _paint_roll_canvas_size.y <= 1.0:
		return paint_roll_brush_radius_uv
	var contact_radius_px: float = _paint_roll_ball_diameter_px * 0.42
	var radius_uv: float = contact_radius_px / minf(_paint_roll_canvas_size.x, _paint_roll_canvas_size.y)
	return clampf(radius_uv, paint_roll_brush_radius_uv * 0.75, paint_roll_brush_radius_uv * 1.75)


func _get_paint_roll_ball_radius_uv() -> float:
	if _paint_roll_canvas_size.x <= 1.0 or _paint_roll_canvas_size.y <= 1.0:
		return paint_roll_brush_radius_uv
	var radius_uv: float = (_paint_roll_ball_diameter_px * 0.5) / minf(_paint_roll_canvas_size.x, _paint_roll_canvas_size.y)
	return maxf(radius_uv, 0.001)


func _paint_roll_at(uv: Vector2) -> void:
	if _paint_roll_mask_image == null:
		return
	var center := Vector2(
		uv.x * float(_paint_roll_mask_size.x - 1),
		uv.y * float(_paint_roll_mask_size.y - 1)
	)
	var ball_radius_uv: float = _get_paint_roll_ball_radius_uv()
	var radius_scale: float = 1.0 / 3.0
	var strong_radius_px: float = ball_radius_uv * 3.0 * radius_scale * float(mini(_paint_roll_mask_size.x, _paint_roll_mask_size.y))
	var weak_radius_px: float = ball_radius_uv * 4.0 * radius_scale * float(mini(_paint_roll_mask_size.x, _paint_roll_mask_size.y))
	var x0: int = maxi(0, int(floor(center.x - weak_radius_px)))
	var x1: int = mini(_paint_roll_mask_size.x - 1, int(ceil(center.x + weak_radius_px)))
	var y0: int = maxi(0, int(floor(center.y - weak_radius_px)))
	var y1: int = mini(_paint_roll_mask_size.y - 1, int(ceil(center.y + weak_radius_px)))
	var ordinary_gain: float = 1.0
	var apple_strong_gain: float = 0.34
	var apple_weak_gain: float = 0.08
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var offset := Vector2(float(x), float(y)) - center
			var dist: float = offset.length()
			if dist > weak_radius_px:
				continue
			var strong: float = 1.0 - smoothstep(strong_radius_px * 0.72, strong_radius_px, dist)
			var weak: float = 1.0 - smoothstep(strong_radius_px, weak_radius_px, dist)
			var falloff: float = maxf(strong, weak * 0.22)
			if falloff <= 0.0:
				continue
			var px_uv := Vector2(float(x) / float(_paint_roll_mask_size.x - 1), float(y) / float(_paint_roll_mask_size.y - 1))
			var resistance: float = _get_paint_roll_resistance(x, y)
			var is_apple := resistance > 0.35
			var current := _paint_roll_mask_image.get_pixel(x, y)
			var next_alpha: float
			if is_apple:
				var gain: float = apple_strong_gain * strong + apple_weak_gain * weak * (1.0 - strong)
				next_alpha = clampf(current.a + gain * lerpf(1.0, 0.62, resistance), 0.0, 1.0)
			else:
				next_alpha = maxf(current.a, clampf(falloff * ordinary_gain, 0.0, 1.0))
			_paint_roll_mask_image.set_pixel(x, y, Color(1.0, 1.0, 1.0, next_alpha))
	_paint_roll_mask_texture.update(_paint_roll_mask_image)


func _update_paint_roll_diffusion(delta: float) -> void:
	return


func _paint_roll_trail_at(previous_uv: Vector2, current_uv: Vector2, movement_dir: Vector2) -> void:
	if _paint_roll_trail_image == null:
		return
	var speed_ratio: float = clampf(_paint_roll_velocity_uv.length() / maxf(0.001, paint_roll_max_speed_uv), 0.0, 1.0)
	if speed_ratio <= 0.03:
		return
	var color := _get_current_trail_color()
	var dir := movement_dir.normalized()
	var side := Vector2(-dir.y, dir.x)
	var center := Vector2(
		current_uv.x * float(_paint_roll_mask_size.x - 1),
		current_uv.y * float(_paint_roll_mask_size.y - 1)
	)
	var ball_radius_px: float = _get_paint_roll_ball_radius_uv() * float(mini(_paint_roll_mask_size.x, _paint_roll_mask_size.y))
	var trail_length: float = ball_radius_px * lerpf(1.8, 4.8, speed_ratio)
	var trail_width: float = maxf(2.0, ball_radius_px * lerpf(0.18, 0.38, speed_ratio))
	var back := -dir
	var p0 := center + back * ball_radius_px * 0.7
	var p1 := center + back * trail_length
	var min_x: int = maxi(0, int(floor(minf(p0.x, p1.x) - trail_width * 2.5)))
	var max_x: int = mini(_paint_roll_mask_size.x - 1, int(ceil(maxf(p0.x, p1.x) + trail_width * 2.5)))
	var min_y: int = maxi(0, int(floor(minf(p0.y, p1.y) - trail_width * 2.5)))
	var max_y: int = mini(_paint_roll_mask_size.y - 1, int(ceil(maxf(p0.y, p1.y) + trail_width * 2.5)))
	var segment := p1 - p0
	var segment_len_sq: float = maxf(0.001, segment.length_squared())
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var p := Vector2(float(x), float(y))
			var t: float = clampf((p - p0).dot(segment) / segment_len_sq, 0.0, 1.0)
			var closest := p0.lerp(p1, t)
			var dist: float = p.distance_to(closest)
			var taper: float = 1.0 - t
			var strand: float = 0.72 + 0.28 * sin(t * TAU * 2.7 + side.dot(p) * 0.17)
			var width: float = trail_width * lerpf(1.0, 0.22, t) * strand
			if dist > width:
				continue
			var alpha: float = (1.0 - smoothstep(width * 0.35, width, dist)) * taper * lerpf(0.28, 0.72, speed_ratio)
			var current := _paint_roll_trail_image.get_pixel(x, y)
			var next_alpha: float = clampf(current.a + alpha, 0.0, 0.82)
			var next_color := Color(
				lerpf(current.r, color.r, alpha),
				lerpf(current.g, color.g, alpha),
				lerpf(current.b, color.b, alpha),
				next_alpha
			)
			_paint_roll_trail_image.set_pixel(x, y, next_color)
	_paint_roll_trail_texture.update(_paint_roll_trail_image)


func _get_current_trail_color() -> Color:
	if _core_flow_palette.is_empty():
		return Color(0.9, 0.18, 0.12, 1.0)
	var color := Color(0.0, 0.0, 0.0, 1.0)
	for c in _core_flow_palette:
		color.r += c.r
		color.g += c.g
		color.b += c.b
	var inv: float = 1.0 / float(_core_flow_palette.size())
	color.r *= inv
	color.g *= inv
	color.b *= inv
	var slot: int = int(Time.get_ticks_msec() / 700) % _core_flow_palette.size()
	color = color.lerp(_core_flow_palette[slot], 0.45)
	return Color(color.r, color.g, color.b, 1.0)


func _update_paint_roll_trail_decay(delta: float) -> void:
	if _paint_roll_trail_image == null or _paint_roll_trail_texture == null:
		return
	if not _paint_roll_running:
		return
	_paint_roll_trail_decay_timer -= delta
	if _paint_roll_trail_decay_timer > 0.0:
		return
	_paint_roll_trail_decay_timer = 0.045
	for y in range(_paint_roll_mask_size.y):
		for x in range(_paint_roll_mask_size.x):
			var c := _paint_roll_trail_image.get_pixel(x, y)
			if c.a <= 0.004:
				if c.a > 0.0:
					_paint_roll_trail_image.set_pixel(x, y, Color(0.0, 0.0, 0.0, 0.0))
				continue
			var next_alpha: float = maxf(0.0, c.a - 0.055)
			_paint_roll_trail_image.set_pixel(x, y, Color(c.r, c.g, c.b, next_alpha))
	_paint_roll_trail_texture.update(_paint_roll_trail_image)


func _update_paint_roll_mirror_stage(delta: float) -> void:
	if not _paint_roll_running or not _is_paint_roll_mirror_stage() or _paint_roll_mirror_done:
		return
	_update_right6_mirror_shader()
	if _paint_roll_mirror_breaking or _paint_roll_mirror_collapsing:
		return
	if _is_paint_roll_ball_on_mirror():
		_paint_roll_mirror_contact_timer += delta
	else:
		_paint_roll_mirror_contact_timer = maxf(0.0, _paint_roll_mirror_contact_timer - delta * 1.5)
	_update_paint_roll_mirror_cracks(clampf(_paint_roll_mirror_contact_timer / MIRROR_LAYER_CONTACT_SEC, 0.0, 1.0))
	if _paint_roll_mirror_contact_timer >= MIRROR_LAYER_CONTACT_SEC:
		_start_paint_roll_mirror_piece_break(_paint_roll_mirror_layer_index)


func _start_paint_roll_mirror_collapse() -> void:
	_paint_roll_mirror_collapsing = true
	_build_paint_roll_large_shards()


func _is_paint_roll_ball_on_mirror() -> bool:
	if _paint_roll_mirror_overlay == null or _paint_roll_mirror == null or _paint_roll_canvas_size.x <= 1.0 or _paint_roll_canvas_size.y <= 1.0:
		return false
	var ball_px := Vector2(
		_paint_roll_view_uv.x * _paint_roll_canvas_size.x,
		_paint_roll_view_uv.y * _paint_roll_canvas_size.y
	)
	var mirror_center := _paint_roll_mirror_overlay.position + _paint_roll_mirror.position + _paint_roll_mirror.size * 0.5
	var mirror_radius := minf(_paint_roll_mirror.size.x, _paint_roll_mirror.size.y) * 0.5
	return ball_px.distance_to(mirror_center) <= mirror_radius


func _reset_paint_roll_mirror_layers() -> void:
	_paint_roll_mirror_layer_index = 0
	_paint_roll_mirror_contact_timer = 0.0
	_paint_roll_mirror_breaking = false
	_clear_paint_roll_mirror_cracks()
	if _paint_roll_mirror_piece_layers.is_empty():
		return
	for layer_index in range(_paint_roll_mirror_piece_layers.size()):
		var layer := _paint_roll_mirror_piece_layers[layer_index]
		if layer == null or not is_instance_valid(layer):
			continue
		layer.visible = true
		layer.modulate.a = 1.0
		layer.z_index = -layer_index
		var layer_shards: Array = _paint_roll_mirror_piece_shards[layer_index]
		for shard_data in layer_shards:
			var node := shard_data.get("node", null) as Polygon2D
			if node == null or not is_instance_valid(node):
				continue
			node.visible = true
			node.position = shard_data.get("origin", node.position) as Vector2
			node.rotation = 0.0
			node.scale = Vector2.ONE
			node.z_index = 0
			node.modulate = Color.WHITE
			node.color = Color.WHITE
			node.material = shard_data.get("material", node.material) as Material
			var edge := node.get_node_or_null("ShardEdge") as Line2D
			if edge != null:
				edge.queue_free()
			var glint := node.get_node_or_null("ShardGlint") as Line2D
			if glint != null:
				glint.queue_free()
	_set_visible_paint_roll_mirror_layer(_paint_roll_mirror_layer_index)


func _clear_paint_roll_mirror_cracks() -> void:
	_paint_roll_mirror_crack_lines.clear()
	if _paint_roll_mirror_crack_root == null:
		return
	for child in _paint_roll_mirror_crack_root.get_children():
		child.queue_free()
	_paint_roll_mirror_crack_root.visible = _is_paint_roll_mirror_stage()


func _build_paint_roll_mirror_cracks(layer_index: int) -> void:
	if _paint_roll_mirror_crack_root == null or _paint_roll_mirror_piece_size.x <= 1.0:
		return
	_clear_paint_roll_mirror_cracks()
	_paint_roll_mirror_crack_root.visible = true
	if layer_index < 0 or layer_index >= _paint_roll_mirror_piece_shards.size():
		return
	var center := _paint_roll_mirror_piece_size * 0.5
	var radius := minf(_paint_roll_mirror_piece_size.x, _paint_roll_mirror_piece_size.y) * 0.5
	var impact := center
	if _paint_roll_mirror_overlay != null and _paint_roll_canvas_size.x > 1.0 and _paint_roll_canvas_size.y > 1.0:
		var ball_px := Vector2(_paint_roll_view_uv.x * _paint_roll_canvas_size.x, _paint_roll_view_uv.y * _paint_roll_canvas_size.y)
		impact = ball_px - _paint_roll_mirror_overlay.position
	var impact_offset := impact - center
	if impact_offset.length() > radius * 0.52:
		impact = center + impact_offset.normalized() * radius * 0.52
	var line_index := 0
	var base_angle := atan2((impact - center).y, (impact - center).x)
	if impact.distance_to(center) < radius * 0.08:
		base_angle = _hash_2d(Vector2(float(layer_index) + 10.0, 2.0)) * TAU
	var primary_count := 7 + layer_index
	for i in range(primary_count):
		var seed := Vector2(float(i + 1), float(layer_index + 1) * 31.0)
		var angle := base_angle + (float(i) / float(primary_count)) * TAU
		angle += (_hash_2d(seed + Vector2(1.7, 4.2)) - 0.5) * 0.68
		var length := radius * lerpf(0.48, 0.98, _hash_2d(seed + Vector2(8.0, 3.0)))
		var crack_points := _build_jagged_crack_polyline(impact, angle, length, radius, center, seed, 6 + layer_index)
		_add_paint_roll_mirror_crack_line(crack_points, line_index, layer_index, clampf(float(i) * 0.035, 0.0, 0.38))
		line_index += 1
		var branch_count := 1 + int(_hash_2d(seed + Vector2(5.0, 13.0)) * 2.0)
		for branch_index in range(branch_count):
			var t := lerpf(0.32, 0.74, _hash_2d(seed + Vector2(float(branch_index) + 3.0, 17.0)))
			var source_index := clampi(int(round(t * float(crack_points.size() - 1))), 1, crack_points.size() - 1)
			var origin := crack_points[source_index]
			var side := -1.0 if _hash_2d(seed + Vector2(float(branch_index), 29.0)) < 0.5 else 1.0
			var branch_angle := angle + side * lerpf(0.56, 1.16, _hash_2d(seed + Vector2(float(branch_index), 41.0)))
			var branch_length := radius * lerpf(0.12, 0.30, _hash_2d(seed + Vector2(float(branch_index), 53.0)))
			var branch_points := _build_jagged_crack_polyline(origin, branch_angle, branch_length, radius, center, seed + Vector2(float(branch_index) * 7.0, 19.0), 3)
			_add_paint_roll_mirror_crack_line(branch_points, line_index, layer_index, clampf(0.30 + t * 0.42 + float(branch_index) * 0.04, 0.0, 0.86))
			line_index += 1
	var arc_count := 2 + layer_index
	for arc_index in range(arc_count):
		var seed := Vector2(float(arc_index + 101), float(layer_index + 1) * 11.0)
		var arc_radius := radius * lerpf(0.18, 0.44, _hash_2d(seed))
		var start_angle := base_angle + lerpf(-1.1, 1.1, _hash_2d(seed + Vector2(2.0, 7.0)))
		var span := lerpf(0.46, 1.04, _hash_2d(seed + Vector2(3.0, 9.0)))
		var arc_points := PackedVector2Array()
		var segment_count := 5
		for segment in range(segment_count + 1):
			var t := float(segment) / float(segment_count)
			var angle := start_angle + span * t
			var jitter := (_hash_2d(seed + Vector2(float(segment) * 2.0, 5.0)) - 0.5) * radius * 0.025
			var point := impact + Vector2(cos(angle), sin(angle)) * (arc_radius + jitter)
			arc_points.append(_clamp_point_to_mirror_disc(point, center, radius * 0.965))
		_add_paint_roll_mirror_crack_line(arc_points, line_index, layer_index, clampf(0.42 + float(arc_index) * 0.12, 0.0, 0.82))
		line_index += 1


func _build_jagged_crack_polyline(origin: Vector2, angle: float, length: float, radius: float, center: Vector2, seed: Vector2, segment_count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	var direction := Vector2(cos(angle), sin(angle))
	var normal := Vector2(-direction.y, direction.x)
	points.append(origin)
	var bend_accum := 0.0
	for segment in range(1, segment_count + 1):
		var t := float(segment) / float(segment_count)
		bend_accum += (_hash_2d(seed + Vector2(float(segment) * 2.7, 6.0)) - 0.5) * radius * 0.035
		var taper := 1.0 - t * 0.72
		var point := origin + direction * length * t + normal * bend_accum * taper
		points.append(_clamp_point_to_mirror_disc(point, center, radius * 0.965))
	return points


func _clamp_point_to_mirror_disc(point: Vector2, center: Vector2, max_radius: float) -> Vector2:
	var offset := point - center
	if offset.length() <= max_radius:
		return point
	return center + offset.normalized() * max_radius


func _add_paint_roll_mirror_crack_line(points: PackedVector2Array, line_index: int, layer_index: int, distance_ratio: float) -> void:
	var dark_line := Line2D.new()
	dark_line.name = "MirrorCrackDark_%d_%03d" % [layer_index, line_index]
	dark_line.width = 4.2
	dark_line.default_color = Color(0.015, 0.028, 0.040, 0.0)
	dark_line.points = PackedVector2Array([points[0], points[0]])
	dark_line.visible = false
	_paint_roll_mirror_crack_root.add_child(dark_line)

	var light_line := Line2D.new()
	light_line.name = "MirrorCrackGlint_%d_%03d" % [layer_index, line_index]
	light_line.width = 1.35
	light_line.default_color = Color(0.78, 0.92, 1.0, 0.0)
	light_line.position = Vector2(1.4, -1.1)
	light_line.points = PackedVector2Array([points[0], points[0]])
	light_line.visible = false
	_paint_roll_mirror_crack_root.add_child(light_line)

	_paint_roll_mirror_crack_lines.append({
		"dark": dark_line,
		"light": light_line,
		"points": points,
		"delay": clampf(distance_ratio * 0.66 + _hash_2d(Vector2(float(line_index), float(layer_index) + 21.0)) * 0.16, 0.0, 0.82),
	})


func _update_paint_roll_mirror_cracks(progress: float) -> void:
	if _paint_roll_mirror_crack_root == null:
		return
	if _paint_roll_mirror_crack_lines.is_empty():
		_build_paint_roll_mirror_cracks(_paint_roll_mirror_layer_index)
	for crack_data in _paint_roll_mirror_crack_lines:
		var dark_line := crack_data.get("dark", null) as Line2D
		var light_line := crack_data.get("light", null) as Line2D
		if dark_line == null or light_line == null or not is_instance_valid(dark_line) or not is_instance_valid(light_line):
			continue
		var delay := float(crack_data.get("delay", 0.0))
		var local := clampf((progress - delay) / maxf(0.001, 1.0 - delay), 0.0, 1.0)
		var reveal := 0.0
		if local < 0.32:
			reveal = lerpf(0.0, 0.78, smoothstep(0.0, 0.32, local))
		else:
			reveal = lerpf(0.78, 1.0, smoothstep(0.32, 1.0, local))
		dark_line.visible = local > 0.0
		light_line.visible = local > 0.0
		var alpha := smoothstep(0.0, 0.42, local)
		dark_line.default_color = Color(0.010, 0.020, 0.032, alpha * 0.88)
		light_line.default_color = Color(0.78, 0.92, 1.0, alpha * 0.64)
		var source_points := crack_data.get("points", PackedVector2Array()) as PackedVector2Array
		if source_points.size() < 2:
			continue
		var drawn := PackedVector2Array()
		var scaled_count: float = reveal * float(source_points.size() - 1)
		var full_segments := int(floor(scaled_count))
		var remainder := scaled_count - float(full_segments)
		for i in range(full_segments + 1):
			drawn.append(source_points[i])
		if full_segments < source_points.size() - 1:
			drawn.append(source_points[full_segments].lerp(source_points[full_segments + 1], remainder))
		dark_line.points = drawn
		light_line.points = drawn


func _start_paint_roll_mirror_piece_break(layer_index: int) -> void:
	if _paint_roll_mirror_breaking or layer_index < 0 or layer_index >= _paint_roll_mirror_piece_shards.size():
		return
	_paint_roll_mirror_breaking = true
	_paint_roll_mirror_contact_timer = 0.0
	_clear_paint_roll_mirror_cracks()
	_kick_paint_roll_ball_off_mirror(layer_index)
	var next_layer_index := layer_index + 1
	if next_layer_index < _paint_roll_mirror_piece_layers.size():
		_set_visible_paint_roll_mirror_layer(next_layer_index)
	elif _paint_roll_mirror != null:
		_paint_roll_mirror.visible = false
	if layer_index < _paint_roll_mirror_piece_layers.size():
		var active_layer := _paint_roll_mirror_piece_layers[layer_index]
		if active_layer != null and is_instance_valid(active_layer):
			active_layer.visible = true
			active_layer.modulate.a = 1.0
			active_layer.z_index = 8
	var layer_shards: Array = _paint_roll_mirror_piece_shards[layer_index]
	var duration := 2.35
	var tween := create_tween()
	tween.set_parallel(true)
	for shard_index in range(layer_shards.size()):
		var shard_data := layer_shards[shard_index] as Dictionary
		var node := shard_data.get("node", null) as Polygon2D
		if node == null or not is_instance_valid(node):
			continue
		_prepare_visible_paint_roll_mirror_piece(node, layer_index, shard_index)
		var origin := shard_data.get("origin", node.position) as Vector2
		var drift := shard_data.get("drift", Vector2.ZERO) as Vector2
		var drop := float(shard_data.get("drop", 0.0))
		var delay := float(shard_data.get("delay", 0.0)) * 0.18
		var spin := float(shard_data.get("spin", 0.0))
		node.position = origin
		node.scale = Vector2(0.985, 0.985)
		var target := origin + drift + Vector2(0.0, drop)
		tween.tween_property(node, "position", target, duration).set_delay(delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tween.tween_property(node, "rotation", spin, duration).set_delay(delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tween.tween_property(node, "scale", Vector2(0.94, 0.94), duration * 0.55).set_delay(delay).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(node, "modulate:a", 0.0, duration * 0.52).set_delay(delay + duration * 0.48)
	await tween.finished
	if layer_index < _paint_roll_mirror_piece_layers.size():
		var layer := _paint_roll_mirror_piece_layers[layer_index]
		if layer != null and is_instance_valid(layer):
			layer.visible = false
	_paint_roll_mirror_layer_index += 1
	_paint_roll_mirror_breaking = false
	_clear_paint_roll_mirror_cracks()
	if _paint_roll_mirror_layer_index >= _paint_roll_mirror_piece_layers.size():
		await _run_final_paint_roll_canvas_break()
	else:
		_set_visible_paint_roll_mirror_layer(_paint_roll_mirror_layer_index)


func _kick_paint_roll_ball_off_mirror(layer_index: int) -> void:
	var p := _paint_roll_view_uv * 2.0 - Vector2.ONE
	var dir := p.normalized() if p.length_squared() > 0.0001 else _get_paint_roll_mirror_layer_tilt(layer_index).normalized()
	var tangent := Vector2(-dir.y, dir.x)
	var side := -1.0 if _hash_2d(Vector2(float(layer_index) + 17.0, _color_flow_time + 3.0)) < 0.5 else 1.0
	var kick_dir := (dir * 0.88 + tangent * side * 0.30).normalized()
	_paint_roll_velocity_uv = kick_dir * paint_roll_mirror_break_kick_uv


func _prepare_visible_paint_roll_mirror_piece(node: Polygon2D, _layer_index: int, _shard_index: int) -> void:
	node.visible = true
	node.z_index = 0
	node.modulate = Color.WHITE
	node.color = Color.WHITE
	var old_edge := node.get_node_or_null("ShardEdge") as Line2D
	if old_edge != null:
		old_edge.queue_free()
	var edge_points := PackedVector2Array()
	for point in node.polygon:
		edge_points.append(point)
	if node.polygon.size() > 0:
		edge_points.append(node.polygon[0])
	var edge := Line2D.new()
	edge.name = "ShardEdge"
	edge.width = 2.6
	edge.default_color = Color(0.0, 0.0, 0.0, 0.72)
	edge.points = edge_points
	node.add_child(edge)
	var glint := Line2D.new()
	glint.name = "ShardGlint"
	glint.width = 0.9
	glint.default_color = Color(0.18, 0.22, 0.24, 0.30)
	glint.position = Vector2(1.2, -1.0)
	glint.points = edge_points
	node.add_child(glint)


func _run_final_paint_roll_canvas_break() -> void:
	if _paint_roll_mirror_collapsing:
		return
	_paint_roll_stage_transitioning = true
	_paint_roll_running = false
	_paint_roll_velocity_uv = Vector2.ZERO
	await _run_paint_roll_pre_final_break_scale()
	_start_paint_roll_mirror_collapse()
	var tween := create_tween()
	tween.tween_method(Callable(self, "_paint_roll_apply_collapse_progress"), 0.0, 1.0, 1.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tween.finished
	await _finish_paint_roll_mirror_stage()


func _run_paint_roll_pre_final_break_scale() -> void:
	if _paint_roll_canvas == null or _paint_roll_frame == null or _paint_roll_root == null:
		return
	var start_view_uv := _paint_roll_view_uv
	var target_view_uv := Vector2(0.5, 0.5)
	var start_scale := _paint_roll_canvas.scale.x
	var target_scale := _get_paint_roll_overview_scale()
	var start_rotation := _paint_roll_canvas.rotation_degrees
	var tween := create_tween()
	tween.tween_method(
		func(value: float) -> void:
			_set_paint_roll_picture_transform(
				start_view_uv.lerp(target_view_uv, value),
				lerpf(start_scale, target_scale, value),
				lerpf(start_rotation, 0.0, value),
				Vector2.ZERO
			),
		0.0,
		1.0,
		0.62
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await tween.finished


func _paint_roll_apply_collapse_progress(progress: float) -> void:
	var fall_progress := smoothstep(0.38, 1.0, progress)
	if _paint_roll_canvas != null:
		_paint_roll_canvas.modulate.a = 1.0 - smoothstep(0.76, 1.0, progress)
	_update_paint_roll_large_shards(fall_progress)


func _clear_paint_roll_shards() -> void:
	_paint_roll_shards.clear()
	if _paint_roll_shard_root == null:
		return
	for child in _paint_roll_shard_root.get_children():
		child.queue_free()
	_paint_roll_shard_root.visible = false


func _build_paint_roll_large_shards() -> void:
	if _paint_roll_shard_root == null or _paint_roll_canvas_size.x <= 1.0 or _paint_roll_canvas_size.y <= 1.0:
		return
	_clear_paint_roll_shards()
	_paint_roll_shard_root.visible = true
	_paint_roll_shard_root.position = Vector2.ZERO
	_paint_roll_shard_root.size = _paint_roll_canvas_size
	var shard_texture: Texture2D = null
	if not _paint_roll_stage_data.is_empty():
		var stage := _paint_roll_stage_data[clampi(_paint_roll_stage_index, 0, _paint_roll_stage_data.size() - 1)]
		var texture_variant: Variant = stage.get("color_texture", null)
		if texture_variant is Texture2D:
			shard_texture = texture_variant as Texture2D
	var cell_points := _build_final_canvas_fracture_cells(_paint_roll_canvas_size)
	for i in range(cell_points.size()):
		var points := cell_points[i]
		var shard_center := Vector2.ZERO
		for point in points:
			shard_center += point
		shard_center /= float(points.size())
		var local_points := PackedVector2Array()
		var uvs := PackedVector2Array()
		for point in points:
			local_points.append(point - shard_center)
			uvs.append(Vector2(
				point.x / maxf(1.0, _paint_roll_canvas_size.x),
				point.y / maxf(1.0, _paint_roll_canvas_size.y)
			))
		var shard := Polygon2D.new()
		shard.name = "PaintRollShard%03d" % i
		shard.polygon = local_points
		shard.uv = uvs
		shard.texture = shard_texture
		shard.position = shard_center
		var shard_uv := Vector2(
			shard_center.x / maxf(1.0, _paint_roll_canvas_size.x),
			shard_center.y / maxf(1.0, _paint_roll_canvas_size.y)
		)
		shard.color = Color.WHITE if shard_texture != null else _sample_right6_shard_color(shard_uv)
		shard.visible = false
		_paint_roll_shard_root.add_child(shard)
		var outward := (shard_center - _paint_roll_canvas_size * 0.5).normalized()
		_paint_roll_shards.append({
			"node": shard,
			"origin": shard_center,
			"delay": _hash_2d(Vector2(float(i), 9.0)) * 0.26,
			"drift": outward.x * lerpf(0.12, 0.36, _hash_2d(Vector2(float(i), 10.0))) * _paint_roll_canvas_size.x,
			"drop": lerpf(0.95, 1.55, _hash_2d(Vector2(float(i), 11.0))) * _paint_roll_canvas_size.y,
			"spin": lerpf(-0.62, 0.62, _hash_2d(Vector2(float(i), 12.0))) * TAU,
		})


func _build_final_canvas_fracture_cells(canvas_size: Vector2) -> Array[PackedVector2Array]:
	var cols := 4
	var rows := 3
	var points: Array[Array] = []
	for y in range(rows + 1):
		var row: Array[Vector2] = []
		for x in range(cols + 1):
			var base := Vector2(
				canvas_size.x * float(x) / float(cols),
				canvas_size.y * float(y) / float(rows)
			)
			var can_jitter_x := x > 0 and x < cols
			var can_jitter_y := y > 0 and y < rows
			var jitter := Vector2.ZERO
			if can_jitter_x:
				jitter.x = (_hash_2d(Vector2(float(x * 19 + y * 7), 3.1)) - 0.5) * canvas_size.x * 0.13
			if can_jitter_y:
				jitter.y = (_hash_2d(Vector2(float(x * 11 + y * 23), 8.4)) - 0.5) * canvas_size.y * 0.16
			row.append(base + jitter)
		points.append(row)
	var cells: Array[PackedVector2Array] = []
	for y in range(rows):
		for x in range(cols):
			var a: Vector2 = points[y][x]
			var b: Vector2 = points[y][x + 1]
			var c: Vector2 = points[y + 1][x + 1]
			var d: Vector2 = points[y + 1][x]
			var mid := (a + b + c + d) * 0.25
			var split_seed := _hash_2d(Vector2(float(x * 41 + y * 17), 12.9))
			if split_seed < 0.22 and cells.size() < 14:
				var center_jitter := Vector2(
					(_hash_2d(Vector2(float(x), float(y) + 31.0)) - 0.5) * canvas_size.x * 0.035,
					(_hash_2d(Vector2(float(x) + 12.0, float(y))) - 0.5) * canvas_size.y * 0.035
				)
				var local_mid := mid + center_jitter
				cells.append(PackedVector2Array([a, b, local_mid, d]))
				cells.append(PackedVector2Array([b, c, local_mid]))
			else:
				cells.append(PackedVector2Array([a, b, c, d]))
	return cells


func _build_irregular_canvas_boundary(canvas_size: Vector2) -> Array[Vector2]:
	var points: Array[Vector2] = []
	var per_side := 8
	for i in range(per_side):
		var t := float(i) / float(per_side)
		points.append(Vector2(canvas_size.x * t, 0.0))
	for i in range(per_side):
		var t := float(i) / float(per_side)
		points.append(Vector2(canvas_size.x, canvas_size.y * t))
	for i in range(per_side):
		var t := 1.0 - float(i) / float(per_side)
		points.append(Vector2(canvas_size.x * t, canvas_size.y))
	for i in range(per_side):
		var t := 1.0 - float(i) / float(per_side)
		points.append(Vector2(0.0, canvas_size.y * t))
	return points


func _update_paint_roll_large_shards(progress: float) -> void:
	if _paint_roll_shard_root == null or _paint_roll_shards.is_empty():
		return
	_paint_roll_shard_root.visible = true
	for shard_data in _paint_roll_shards:
		var node := shard_data.get("node", null) as Polygon2D
		if node == null or not is_instance_valid(node):
			continue
		var delay := float(shard_data.get("delay", 0.0))
		var local := smoothstep(delay, minf(1.0, delay + 0.54), progress)
		node.visible = local > 0.001 and local < 0.995
		var origin := shard_data.get("origin", Vector2.ZERO) as Vector2
		var drift := float(shard_data.get("drift", 0.0)) * local
		var drop := float(shard_data.get("drop", 0.0)) * local * local
		node.position = origin + Vector2(drift, drop)
		node.rotation = float(shard_data.get("spin", 0.0)) * local
		node.modulate.a = pow(1.0 - local, 0.32)


func _sample_right6_shard_color(uv: Vector2) -> Color:
	var center_distance := uv.distance_to(Vector2(0.5, 0.5))
	var warm := Color(0.23, 0.19, 0.14, 1.0).lerp(Color(0.10, 0.09, 0.08, 1.0), clampf(center_distance * 1.35, 0.0, 1.0))
	var mirror := Color(0.10, 0.14, 0.17, 1.0)
	return warm.lerp(mirror, smoothstep(0.08, 0.46, 0.48 - center_distance))


func _hash_2d(p: Vector2) -> float:
	var value := sin(p.dot(Vector2(127.1, 311.7))) * 43758.5453123
	return value - floorf(value)


func _finish_paint_roll_mirror_stage() -> void:
	if _paint_roll_mirror_done:
		return
	_paint_roll_mirror_done = true
	_paint_roll_running = false
	_paint_roll_stage_transitioning = true
	_transition_running = true
	_paint_roll_stage_transitioning = false
	_emit_completed()


func _run_paint_roll_overview_transition(center_to_middle: bool) -> void:
	if _paint_roll_root == null or _paint_roll_canvas == null or _paint_roll_frame == null:
		return
	_paint_roll_finish_start_uv = _paint_roll_view_uv
	_paint_roll_finish_overview_scale = _get_paint_roll_overview_scale()
	var start_view_uv := _paint_roll_view_uv
	var target_view_uv := Vector2(0.5, 0.5) if center_to_middle else start_view_uv
	var start_scale := _paint_roll_canvas.scale.x
	var start_rotation := _paint_roll_canvas.rotation_degrees
	var target_scale := _paint_roll_finish_overview_scale
	var tween := create_tween()
	tween.tween_method(
		func(value: float) -> void:
			var current_view_uv := start_view_uv.lerp(target_view_uv, value)
			_set_paint_roll_picture_transform(
				current_view_uv,
				lerpf(start_scale, target_scale, value),
				lerpf(start_rotation, 0.0, value),
				Vector2.ZERO
			),
		0.0,
		1.0,
		1.05
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await tween.finished


func _run_paint_roll_stage_exit_transition() -> void:
	if _paint_roll_root == null or _paint_roll_canvas == null or _paint_roll_frame == null:
		return
	var exit := create_tween()
	exit.set_parallel(true)
	exit.tween_property(_paint_roll_canvas, "position", _paint_roll_canvas.position - Vector2(_paint_roll_root.size.x * 0.24, 0.0), 0.82).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	exit.tween_property(_paint_roll_frame, "position", _paint_roll_frame.position - Vector2(_paint_roll_root.size.x * 0.24, 0.0), 0.82).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	exit.tween_property(_paint_roll_canvas, "modulate:a", 0.0, 0.72).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	exit.tween_property(_paint_roll_frame, "modulate:a", 0.0, 0.72).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if _paint_roll_mirror_overlay != null:
		exit.tween_property(_paint_roll_mirror_overlay, "modulate:a", 0.0, 0.72).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await exit.finished


func _get_paint_roll_resistance(x: int, y: int) -> float:
	if _paint_roll_resistance_image == null:
		return 0.0
	return _paint_roll_resistance_image.get_pixel(
		clampi(x, 0, _paint_roll_mask_size.x - 1),
		clampi(y, 0, _paint_roll_mask_size.y - 1)
	).r


func _is_paint_roll_apple_uv(uv: Vector2) -> bool:
	if _paint_roll_resistance_image != null:
		var x: int = clampi(int(uv.x * float(_paint_roll_mask_size.x - 1)), 0, _paint_roll_mask_size.x - 1)
		var y: int = clampi(int(uv.y * float(_paint_roll_mask_size.y - 1)), 0, _paint_roll_mask_size.y - 1)
		return _paint_roll_resistance_image.get_pixel(x, y).r > 0.35
	if _paint_roll_source_image == null or _paint_roll_source_image.is_empty():
		return false
	var sx: int = clampi(int(uv.x * float(_paint_roll_source_image.get_width() - 1)), 0, _paint_roll_source_image.get_width() - 1)
	var sy: int = clampi(int(uv.y * float(_paint_roll_source_image.get_height() - 1)), 0, _paint_roll_source_image.get_height() - 1)
	var c := _paint_roll_source_image.get_pixel(sx, sy)
	var red_like := c.r > 0.34 and c.r > c.g * 1.12 and c.r > c.b * 1.18
	var yellow_like := c.r > 0.45 and c.g > 0.28 and c.b < 0.28 and c.r > c.b * 1.45
	return red_like or yellow_like


func _check_paint_roll_completion() -> void:
	if _paint_roll_finished or _paint_roll_mask_image == null:
		return
	var sample_step: int = 8
	var total: int = 0
	var restored: int = 0
	var apple_total: int = 0
	var apple_restored: int = 0
	for y in range(0, _paint_roll_mask_size.y, sample_step):
		for x in range(0, _paint_roll_mask_size.x, sample_step):
			var uv := Vector2(float(x) / float(_paint_roll_mask_size.x - 1), float(y) / float(_paint_roll_mask_size.y - 1))
			var alpha: float = _paint_roll_mask_image.get_pixel(x, y).a
			var is_apple := _is_paint_roll_apple_uv(uv)
			total += 1
			if alpha >= 0.95:
				restored += 1
			if is_apple:
				apple_total += 1
				if alpha >= 0.95:
					apple_restored += 1
	var coverage: float = float(restored) / float(maxi(1, total))
	var apple_coverage: float = 1.0 if apple_total <= 0 else float(apple_restored) / float(apple_total)
	if coverage >= paint_roll_complete_threshold and apple_coverage >= paint_roll_complete_threshold:
		_finish_paint_roll_stage()


func _finish_paint_roll_stage() -> void:
	if _paint_roll_finished or _paint_roll_stage_transitioning:
		return
	_paint_roll_finished = true
	_paint_roll_running = false
	_paint_roll_stage_transitioning = true
	_paint_roll_velocity_uv = Vector2.ZERO
	await _run_paint_roll_overview_transition(true)
	await _run_paint_roll_auto_fill_transition()

	var next_stage_index := _paint_roll_stage_index + 1
	if next_stage_index < _paint_roll_stage_data.size():
		await _run_paint_roll_stage_exit_transition()
		_apply_paint_roll_stage(next_stage_index)
		await _run_paint_roll_stage_entry(true)
		_paint_roll_running = true
		_paint_roll_finished = false
		_paint_roll_stage_transitioning = false
		_paint_roll_completion_timer = 0.0
	else:
		_paint_roll_stage_transitioning = false
		_emit_completed()


func _run_paint_roll_auto_fill_transition() -> void:
	if _paint_roll_material == null or _paint_roll_mask_image == null or _paint_roll_mask_texture == null:
		return
	_paint_roll_material.set_shader_parameter("final_fill", 0.0)
	var spread_steps: int = 20
	var source: Image = _paint_roll_mask_image.duplicate()
	var target: Image = _paint_roll_mask_image.duplicate()
	for step in range(spread_steps):
		for y in range(_paint_roll_mask_size.y):
			for x in range(_paint_roll_mask_size.x):
				var base_alpha: float = source.get_pixel(x, y).a
				var max_neighbor: float = base_alpha
				for oy in range(-1, 2):
					var ny: int = clampi(y + oy, 0, _paint_roll_mask_size.y - 1)
					for ox in range(-1, 2):
						var nx: int = clampi(x + ox, 0, _paint_roll_mask_size.x - 1)
						max_neighbor = maxf(max_neighbor, source.get_pixel(nx, ny).a)
				var grown: float = lerpf(base_alpha, max_neighbor, 0.86)
				var min_step: float = 0.012 + 0.015 * (float(step) / float(spread_steps - 1))
				var next_alpha: float = maxf(base_alpha, minf(1.0, grown + min_step))
				target.set_pixel(x, y, Color(1.0, 1.0, 1.0, next_alpha))
		var swap: Image = source
		source = target
		target = swap
		_paint_roll_mask_image.copy_from(source)
		_paint_roll_mask_texture.update(_paint_roll_mask_image)
		await get_tree().process_frame
	for y in range(_paint_roll_mask_size.y):
		for x in range(_paint_roll_mask_size.x):
			_paint_roll_mask_image.set_pixel(x, y, Color(1.0, 1.0, 1.0, 1.0))
	_paint_roll_mask_texture.update(_paint_roll_mask_image)


func _dev_jump_to_paint_roll_stage() -> void:
	if _paint_roll_transitioning or _paint_roll_running:
		return
	_transition_running = true
	_start_paint_roll_transition()


func _set_paint_roll_final_fill_for_tween(value: float) -> void:
	if _paint_roll_material != null:
		_paint_roll_material.set_shader_parameter("final_fill", value)


func _set_paint_roll_finish_overview_for_tween(value: float) -> void:
	_paint_roll_view_uv = _paint_roll_finish_start_uv.lerp(Vector2(0.5, 0.5), value)
	_set_paint_roll_picture_transform(
		_paint_roll_view_uv,
		lerpf(1.0, _paint_roll_finish_overview_scale, value),
		lerpf(painting_tilt_degrees, 0.0, value),
		Vector2.ZERO
	)


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
		var final_exit := create_tween()
		final_exit.set_parallel(true)
		final_exit.tween_property(_frame_root, "modulate:a", 0.0, stage_pan_sec * 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		final_exit.tween_property(_frame_root, "scale", Vector2.ONE * 0.96, stage_pan_sec * 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		await final_exit.finished
		_start_final_shell_reveal()
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
	if _paint_roll_running:
		_layout_paint_roll_scene()


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
