extends Control
class_name LevelC3L2

signal chapter_completed(chapter_index: int)

const QUANTICO_FONT: FontFile = preload("res://assets/fonts/Quantico.ttf")
const IM_FELL_FONT: FontFile = preload("res://assets/fonts/IMFellGreatPrimerSC-Regular.ttf")
const FINALE_DOOR_VIDEO_PATH := "res://assets/video/chapter_3/finale_door_mask.ogv"
const FINALE_DOOR_AUDIO_PATH := "res://assets/audio/chapter_3/finale_door_audio.mp3"

const STAIR_COUNT := 34
const FLAT_COUNT := 7
const PATH_START_Z := 7.0
const STAIR_END_PROGRESS := 0.84
const PATH_END_Z := -96.0
const PATH_END_Y := 18.6
const BLOCK_SPAWN_DEPTH := 5.8
const CIRCUIT_RIBBON_WIDTH: float = 0.040
const CIRCUIT_BASE_ALPHA: float = 0.006
const CIRCUIT_DRAW_BEHIND_DISTANCE: float = 22.0
const CIRCUIT_DRAW_AHEAD_DISTANCE: float = 62.0
const DOOR_OPEN_START := 0.91
const DOOR_ENTER_START := 0.965
const FINALE_TRIGGER_PROGRESS := STAIR_END_PROGRESS
const FINALE_APPROACH_END := 0.865
const FINALE_APPROACH_SEC := 3.2
const FINALE_ORBIT_SEC := 6.4
const FINALE_ENTER_SEC := 3.8
const FINALE_CLEARANCE_SEC := 1.8
const FINALE_CLOSE_SEC := 2.2
const FINALE_LEAK_SEC := 2.8
const FINALE_FADE_SEC := 3.2
const FINALE_TITLE_HOLD_SEC := 2.4
const FINALE_VIDEO_FAILSAFE_SEC := 36.0
const FINALE_VIDEO_TARGET_SEC := 23.0
const FINALE_VIDEO_MASK_CENTER_RATIO := Vector2(984.5 / 1920.0, 576.5 / 1076.0)

@export var chapter_index: int = 3
@export_range(0.4, 4.0, 0.05) var reveal_sec: float = 2.2
@export_range(0.5, 4.0, 0.05) var aurora_intensity: float = 1.18
@export_range(0.2, 3.0, 0.05) var aurora_motion_speed: float = 1.28
@export_range(0.32, 1.00, 0.01) var finale_video_sphere_size_ratio: float = 0.92
@export var finale_video_sphere_offset: Vector2 = Vector2.ZERO
@export var move_speed: float = 8.6
@export var path_length: float = 108.0

var _viewport_container: SubViewportContainer
var _sub_viewport: SubViewport
var _background_rect: ColorRect
var _finale_video_overlay: Control
var _finale_video_player: VideoStreamPlayer
var _finale_video_sphere_viewport_container: SubViewportContainer
var _finale_video_sphere_viewport: SubViewport
var _finale_video_sphere_root: Node3D
var _finale_video_sphere_aurora_root: Node3D
var _finale_video_sphere_aurora_sheets: Array[MeshInstance3D] = []
var _finale_video_sphere_aurora_materials: Array[ShaderMaterial] = []
var _finale_video_reflection_probe: ReflectionProbe
var _finale_video_reflection_backdrop_material: StandardMaterial3D
var _finale_video_sphere_mirror_material: ShaderMaterial
var _finale_video_audio_player: AudioStreamPlayer
var _world_root: Node3D
var _environment: Environment
var _camera: Camera3D
var _title_label: Label
var _thanks_label: Label
var _sphere_root: Node3D
var _sphere_material: StandardMaterial3D
var _reflection_probe: ReflectionProbe
var _aurora_root: Node3D
var _aurora_sheets: Array[MeshInstance3D] = []
var _aurora_sheet_params: Array[Dictionary] = []
var _aurora_materials: Array[ShaderMaterial] = []
var _sphere_motion_history: Array[Vector3] = []
var _sphere_motion_velocity: Vector3 = Vector3.ZERO
var _last_sphere_motion_offset: Vector3 = Vector3.ZERO
var _aurora_mesh_refresh_timer: float = 0.0
var _stair_root: Node3D
var _door_root: Node3D
var _door_leaf: MeshInstance3D
var _door_pivot: Node3D
var _door_circuit_mesh: ImmediateMesh
var _door_circuit_instance: MeshInstance3D
var _door_circuit_tracks: Array[Dictionary] = []
var _door_glow_material: StandardMaterial3D
var _path_blocks: Array[Dictionary] = []
var _circuit_mesh_instance: MeshInstance3D
var _circuit_mesh: ImmediateMesh
var _circuit_paths: Array[Dictionary] = []
var _circuit_events: Array[Dictionary] = []
var _circuit_spawn_timer: float = 0.0
var _rng := RandomNumberGenerator.new()
var _time: float = 0.0
var _reveal: float = 0.0
var _move_progress: float = 0.0
var _moving_weight: float = 0.0
var _run_phase: float = 0.0
var _path_started: bool = false
var _complete_emitted: bool = false
var _finale_active: bool = false
var _finale_time: float = 0.0
var _finale_start_progress: float = FINALE_TRIGGER_PROGRESS
var _finale_orbit_start_position: Vector3 = Vector3.ZERO
var _finale_orbit_start_set: bool = false
var _finale_enter_start_position: Vector3 = Vector3.ZERO
var _finale_enter_start_set: bool = false
var _finale_video_started: bool = false
var _finale_video_finished: bool = false
var _finale_video_holding: bool = false
var _finale_video_elapsed: float = 0.0


func _ready() -> void:
	_rng.seed = 3202
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_scene()
	resized.connect(_on_resized)
	_on_resized()


func _process(delta: float) -> void:
	_time += delta
	_reveal = minf(1.0, _reveal + delta / maxf(0.001, reveal_sec))
	_update_forward_progress(delta)
	_update_background_and_fade()
	_update_door()
	_update_sphere()
	_update_aurora()
	_update_finale_video_overlay()
	_update_camera(delta)
	_update_path_reveal(delta)
	_update_completion()


func _build_scene() -> void:
	_background_rect = get_node_or_null("Background") as ColorRect
	_viewport_container = SubViewportContainer.new()
	_viewport_container.name = "ViewportContainer"
	_viewport_container.stretch = true
	_viewport_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_viewport_container)

	_sub_viewport = SubViewport.new()
	_sub_viewport.name = "SubViewport"
	_sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_sub_viewport.msaa_3d = Viewport.MSAA_4X
	_viewport_container.add_child(_sub_viewport)

	_world_root = Node3D.new()
	_world_root.name = "WorldRoot"
	_sub_viewport.add_child(_world_root)

	_build_environment()
	_build_camera()
	_build_ascending_path()
	_build_circuit_renderer()
	_seed_circuit_paths()
	_build_door()
	_build_mirror_sphere()
	_build_aurora()
	_build_reflection_probe()
	_build_finale_video_overlay()
	_build_title_overlay()


func _build_environment() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.BLACK
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.015, 0.018, 0.026, 1.0)
	env.ambient_light_energy = 0.35
	env.glow_enabled = true
	env.glow_intensity = 1.45
	env.glow_bloom = 0.34
	env.glow_hdr_threshold = 0.58
	environment.environment = env
	_environment = env
	_world_root.add_child(environment)

	var key := OmniLight3D.new()
	key.name = "MirrorSpecularKey"
	key.position = Vector3(-4.5, 3.2, 4.5)
	key.light_color = Color(0.82, 0.92, 1.0, 1.0)
	key.light_energy = 2.0
	key.omni_range = 14.0
	_world_root.add_child(key)

	var rim := OmniLight3D.new()
	rim.name = "AuroraRimLight"
	rim.position = Vector3(3.4, 2.6, -2.8)
	rim.light_color = Color(0.30, 0.86, 1.0, 1.0)
	rim.light_energy = 2.8
	rim.omni_range = 16.0
	_world_root.add_child(rim)


func _build_title_overlay() -> void:
	_title_label = Label.new()
	_title_label.name = "FinalTitle"
	_title_label.text = "Assemball"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_title_label.add_theme_font_override("font", IM_FELL_FONT)
	_title_label.add_theme_font_size_override("font_size", 118)
	_title_label.add_theme_color_override("font_color", Color(0.08, 0.075, 0.068, 1.0))
	_title_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_title_label)

	_thanks_label = Label.new()
	_thanks_label.name = "FinalThanks"
	_thanks_label.text = "Thank you for playing"
	_thanks_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_thanks_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_thanks_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_thanks_label.offset_left = 48.0
	_thanks_label.offset_top = 36.0
	_thanks_label.offset_right = -48.0
	_thanks_label.offset_bottom = -36.0
	_thanks_label.add_theme_font_override("font", IM_FELL_FONT)
	_thanks_label.add_theme_font_size_override("font_size", 30)
	_thanks_label.add_theme_color_override("font_color", Color(0.08, 0.075, 0.068, 1.0))
	_thanks_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_thanks_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_thanks_label)


func _build_finale_video_overlay() -> void:
	_finale_video_overlay = Control.new()
	_finale_video_overlay.name = "FinaleDoorVideoOverlay"
	_finale_video_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_finale_video_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_finale_video_overlay.visible = false
	add_child(_finale_video_overlay)

	_finale_video_player = VideoStreamPlayer.new()
	_finale_video_player.name = "DoorMaskVideoPlayer"
	_finale_video_player.set_anchors_preset(Control.PRESET_FULL_RECT)
	_finale_video_player.expand = true
	_finale_video_player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_finale_video_player.volume_db = -80.0
	var video_stream := load(FINALE_DOOR_VIDEO_PATH) as VideoStream
	if video_stream != null:
		_finale_video_player.stream = video_stream
	if not _finale_video_player.finished.is_connected(_on_finale_video_finished):
		_finale_video_player.finished.connect(_on_finale_video_finished)
	_finale_video_overlay.add_child(_finale_video_player)

	_finale_video_sphere_viewport_container = SubViewportContainer.new()
	_finale_video_sphere_viewport_container.name = "CenteredAuroraSphereViewport"
	_finale_video_sphere_viewport_container.stretch = true
	_finale_video_sphere_viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_finale_video_overlay.add_child(_finale_video_sphere_viewport_container)

	_finale_video_sphere_viewport = SubViewport.new()
	_finale_video_sphere_viewport.name = "CenteredAuroraSphereSubViewport"
	_finale_video_sphere_viewport.transparent_bg = true
	_finale_video_sphere_viewport.own_world_3d = true
	_finale_video_sphere_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_finale_video_sphere_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	_finale_video_sphere_viewport.msaa_3d = Viewport.MSAA_4X
	_finale_video_sphere_viewport_container.add_child(_finale_video_sphere_viewport)

	_build_finale_video_sphere_world()

	_finale_video_audio_player = AudioStreamPlayer.new()
	_finale_video_audio_player.name = "FinaleDoorIndependentAudioPlayer"
	var audio_stream := load(FINALE_DOOR_AUDIO_PATH) as AudioStream
	if audio_stream != null:
		_finale_video_audio_player.stream = audio_stream
	_finale_video_audio_player.volume_db = 0.0
	add_child(_finale_video_audio_player)


func _build_finale_video_sphere_world() -> void:
	var world := Node3D.new()
	world.name = "CenteredAuroraSphereWorld"
	_finale_video_sphere_viewport.add_child(world)

	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.015, 0.018, 0.026, 1.0)
	env.ambient_light_energy = 0.72
	env.glow_enabled = true
	env.glow_intensity = 1.45
	env.glow_bloom = 0.34
	env.glow_hdr_threshold = 0.58
	environment.environment = env
	world.add_child(environment)

	var key := OmniLight3D.new()
	key.name = "CenteredSphereMirrorSpecularKey"
	key.position = Vector3(-4.5, 3.2, 4.5)
	key.light_color = Color(0.82, 0.92, 1.0, 1.0)
	key.light_energy = 2.0
	key.omni_range = 14.0
	world.add_child(key)

	var rim := OmniLight3D.new()
	rim.name = "CenteredSphereAuroraRimLight"
	rim.position = Vector3(3.4, 2.6, -2.8)
	rim.light_color = Color(0.30, 0.86, 1.0, 1.0)
	rim.light_energy = 2.8
	rim.omni_range = 16.0
	world.add_child(rim)

	var camera := Camera3D.new()
	camera.name = "CenteredAuroraSphereCamera"
	camera.current = true
	camera.cull_mask = 1
	camera.fov = 42.0
	camera.position = Vector3(0.0, 0.0, 4.85)
	world.add_child(camera)
	camera.look_at(Vector3.ZERO, Vector3.UP)

	_build_finale_video_reflection_environment(world)

	_finale_video_sphere_root = Node3D.new()
	_finale_video_sphere_root.name = "CenteredAuroraSphereRoot"
	_finale_video_sphere_root.scale = Vector3.ONE * 1.0
	world.add_child(_finale_video_sphere_root)

	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 96
	mesh.rings = 48

	_finale_video_sphere_mirror_material = _make_finale_video_sphere_mirror_material()

	var sphere := MeshInstance3D.new()
	sphere.name = "CenteredCompleteMirrorSphere"
	sphere.mesh = mesh
	sphere.material_override = _finale_video_sphere_mirror_material
	_finale_video_sphere_root.add_child(sphere)

	_finale_video_sphere_aurora_root = Node3D.new()
	_finale_video_sphere_aurora_root.name = "CenteredAuroraRoot"
	_finale_video_sphere_root.add_child(_finale_video_sphere_aurora_root)

	var palette_sets := [
		[Color(0.06, 0.95, 0.72, 1.0), Color(0.16, 0.48, 1.0, 1.0), Color(0.90, 0.22, 1.0, 1.0)],
		[Color(0.30, 1.0, 0.46, 1.0), Color(0.06, 0.78, 0.96, 1.0), Color(0.70, 0.32, 1.0, 1.0)],
		[Color(0.92, 0.96, 0.28, 1.0), Color(0.10, 0.90, 0.78, 1.0), Color(0.24, 0.36, 1.0, 1.0)]
	]
	for i in range(9):
		var mat := _make_aurora_material(palette_sets[i % palette_sets.size()], 71.0 + float(i) * 9.6)
		mat.set_shader_parameter("fade", 1.0)
		mat.set_shader_parameter("intensity", aurora_intensity)
		var sheet := MeshInstance3D.new()
		sheet.name = "CenteredAuroraSheet_%02d" % i
		sheet.mesh = _make_aurora_mesh(
			1.75 + float(i % 3) * 0.10,
			2.35,
			0.94,
			40 + i,
			float(i) / 9.0 * TAU,
			0.0,
			0.46,
			0.14
		)
		sheet.material_override = mat
		sheet.rotation_degrees.y = float(i) / 9.0 * 360.0
		sheet.set_meta("phase", float(i) * 1.41)
		sheet.set_meta("sway", 0.18 + float(i % 3) * 0.025)
		_finale_video_sphere_aurora_root.add_child(sheet)
		_finale_video_sphere_aurora_sheets.append(sheet)
		_finale_video_sphere_aurora_materials.append(mat)


func _build_finale_video_reflection_environment(world: Node3D) -> void:
	var backdrop_mesh := SphereMesh.new()
	backdrop_mesh.radius = 8.0
	backdrop_mesh.height = 16.0
	backdrop_mesh.radial_segments = 96
	backdrop_mesh.rings = 48

	_finale_video_reflection_backdrop_material = StandardMaterial3D.new()
	_finale_video_reflection_backdrop_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_finale_video_reflection_backdrop_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_finale_video_reflection_backdrop_material.albedo_color = Color.WHITE

	var backdrop := MeshInstance3D.new()
	backdrop.name = "VideoReflectionBackdrop"
	backdrop.layers = 2
	backdrop.mesh = backdrop_mesh
	backdrop.material_override = _finale_video_reflection_backdrop_material
	world.add_child(backdrop)

	_finale_video_reflection_probe = ReflectionProbe.new()
	_finale_video_reflection_probe.name = "CenteredVideoReflectionProbe"
	_finale_video_reflection_probe.position = Vector3.ZERO
	_finale_video_reflection_probe.size = Vector3(18.0, 18.0, 18.0)
	_finale_video_reflection_probe.intensity = 4.2
	_finale_video_reflection_probe.update_mode = ReflectionProbe.UPDATE_ALWAYS
	_finale_video_reflection_probe.cull_mask = 3
	world.add_child(_finale_video_reflection_probe)


func _make_finale_video_sphere_mirror_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D video_texture : source_color, filter_linear_mipmap;
uniform float mirror_zoom = 0.58;
uniform float video_mix = 0.96;
uniform vec3 base_tint = vec3(0.72, 0.74, 0.77);

void fragment() {
	vec3 n = normalize(NORMAL);
	vec2 uv = vec2(0.5 - n.x * mirror_zoom, 0.5 - n.y * mirror_zoom);
	uv = clamp(uv, vec2(0.001), vec2(0.999));
	vec3 reflected_video = texture(video_texture, uv).rgb;
	float rim = pow(clamp(1.0 - abs(n.z), 0.0, 1.0), 2.2);
	float highlight = pow(max(dot(n, normalize(vec3(-0.45, -0.50, 0.74))), 0.0), 18.0);
	ALBEDO = mix(base_tint, reflected_video, video_mix);
	METALLIC = 1.0;
	ROUGHNESS = 0.0;
	SPECULAR = 1.0;
	CLEARCOAT = 1.0;
	CLEARCOAT_ROUGHNESS = 0.0;
	EMISSION = reflected_video * 0.18 + vec3(0.12, 0.55, 0.68) * rim * 0.55 + vec3(1.0) * highlight * 0.50;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	return material


func _build_camera() -> void:
	_camera = Camera3D.new()
	_camera.name = "Camera3D"
	_camera.fov = 48.0
	_camera.current = true
	_world_root.add_child(_camera)
	_camera.position = _path_point(0.0) + Vector3(0.0, 2.05, 0.72)
	_camera.look_at(Vector3(0.0, 1.12, 0.0), Vector3.UP)


func _build_mirror_sphere() -> void:
	_sphere_root = Node3D.new()
	_sphere_root.name = "MirrorSphereRoot"
	_sphere_root.position = Vector3(0.0, 1.12, 0.0)
	_sphere_root.scale = Vector3.ONE * 0.72
	_world_root.add_child(_sphere_root)

	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 96
	mesh.rings = 48

	_sphere_material = StandardMaterial3D.new()
	_sphere_material.albedo_color = Color(0.72, 0.74, 0.77, 1.0)
	_sphere_material.metallic = 1.0
	_sphere_material.roughness = 0.0
	_sphere_material.clearcoat_enabled = true
	_sphere_material.clearcoat = 1.0
	_sphere_material.clearcoat_roughness = 0.0
	_sphere_material.rim_enabled = true
	_sphere_material.rim = 0.18
	_sphere_material.rim_tint = 0.06

	var sphere := MeshInstance3D.new()
	sphere.name = "CompleteMirrorSphere"
	sphere.mesh = mesh
	sphere.material_override = _sphere_material
	_sphere_root.add_child(sphere)


func _build_ascending_path() -> void:
	_stair_root = Node3D.new()
	_stair_root.name = "AscendingCuboidPath"
	_world_root.add_child(_stair_root)

	var block_index := 0
	for i in range(STAIR_COUNT):
		var t0 := float(i) / float(STAIR_COUNT) * STAIR_END_PROGRESS
		var t1 := float(i + 1) / float(STAIR_COUNT) * STAIR_END_PROGRESS
		var p0 := _path_point(t0)
		var p1 := _path_point(t1)
		var z_cursor := p0.z
		var row_end_z := p1.z
		var row_t := (t0 + t1) * 0.5
		var lane_count := _rng.randi_range(2, 4)
		var total_width := _rng.randf_range(6.2, 8.8)
		var lane_weights: Array[float] = []
		var weight_sum := 0.0
		for _lane in range(lane_count):
			var weight := _rng.randf_range(0.78, 1.38)
			lane_weights.append(weight)
			weight_sum += weight
		var lane_edges: Array[float] = [-total_width * 0.5]
		var x_cursor := -total_width * 0.5
		for lane_index in range(lane_count):
			var lane_width := total_width * lane_weights[lane_index] / weight_sum
			if lane_index == lane_count - 1:
				lane_width = total_width * 0.5 - x_cursor
			x_cursor += lane_width
			lane_edges.append(x_cursor)
		var top_y_base := p0.y - 1.20
		for lane_index in range(lane_count):
			var left := lane_edges[lane_index]
			var right := lane_edges[lane_index + 1]
			var block_z := z_cursor
			while block_z > row_end_z + 0.16:
				var max_depth := block_z - row_end_z
				var depth := minf(max_depth, _rng.randf_range(1.25, 2.55))
				if max_depth < 1.35:
					depth = max_depth
				var z_gap := 0.040
				var solid_depth := maxf(0.10, depth - z_gap)
				var seam_gap := 0.030
				var width := maxf(1.35, (right - left) - seam_gap)
				var center_x := (left + right) * 0.5
				var center_z := block_z - z_gap * 0.5 - solid_depth * 0.5
				var height := _rng.randf_range(1.25, 4.25)
				var top_y := top_y_base + _rng.randf_range(-0.10, 0.14)
				_add_path_block(block_index, row_t, Vector3(center_x, top_y - height * 0.5, center_z), Vector3(width, height, solid_depth), top_y)
				block_index += 1
				block_z -= depth

	for i in range(FLAT_COUNT):
		var t0 := lerpf(STAIR_END_PROGRESS, 1.0, float(i) / float(FLAT_COUNT))
		var t1 := lerpf(STAIR_END_PROGRESS, 1.0, float(i + 1) / float(FLAT_COUNT))
		var p0 := _path_point(t0)
		var p1 := _path_point(t1)
		var lane_count := _rng.randi_range(2, 3)
		var total_width := _rng.randf_range(6.4, 8.2)
		var lane_width := total_width / float(lane_count)
		for lane_index in range(lane_count):
			var width := lane_width - 0.030
			var center_x := -total_width * 0.5 + lane_width * (float(lane_index) + 0.5)
			var depth := maxf(0.10, absf(p1.z - p0.z) - 0.040)
			var center_z := (p0.z + p1.z) * 0.5
			var top_y := PATH_END_Y - 1.20 + _rng.randf_range(-0.08, 0.08)
			var height := _rng.randf_range(1.8, 3.9)
			_add_path_block(block_index, (t0 + t1) * 0.5, Vector3(center_x, top_y - height * 0.5, center_z), Vector3(width, height, depth), top_y)
			block_index += 1


func _add_path_block(index: int, path_t: float, target: Vector3, size_value: Vector3, top_y: float) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size_value

	var block := MeshInstance3D.new()
	block.name = "C3L2PathBlock_%02d" % index
	block.mesh = mesh
	block.material_override = _make_floor_material()
	block.position = target + Vector3.DOWN * BLOCK_SPAWN_DEPTH
	block.visible = false
	_stair_root.add_child(block)

	var edge_bars := _add_floor_edge_frame(target, size_value)
	for bar in edge_bars:
		(bar as MeshInstance3D).visible = false
	_path_blocks.append({
		"id": index,
		"t": path_t,
		"center": Vector3(target.x, target.y, target.z),
		"half": Vector2(size_value.x * 0.5, size_value.z * 0.5),
		"size": size_value,
		"top_y": top_y,
		"bottom_y": top_y - size_value.y,
		"target": target,
		"block": block,
		"block_target": target,
		"edge_bars": edge_bars,
		"edge_targets": _edge_target_positions(edge_bars),
		"spawn_progress": 0.0,
		"spawn_started": false,
		"spawn_time": -1.0,
	})


func _make_floor_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode depth_draw_opaque;

uniform vec4 base_color : source_color = vec4(0.004, 0.0048, 0.0062, 1.0);

void fragment() {
	ALBEDO = base_color.rgb;
	ROUGHNESS = 0.78;
	SPECULAR = 0.28;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	return material


func _make_floor_edge_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.92, 0.96, 1.0, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.90, 0.96, 1.0, 1.0)
	mat.emission_energy_multiplier = 0.72
	mat.roughness = 0.36
	return mat


func _add_floor_edge_frame(center: Vector3, size_value: Vector3) -> Array[MeshInstance3D]:
	var bars: Array[MeshInstance3D] = []
	var material := _make_floor_edge_material()
	var t := 0.055
	var hx := size_value.x * 0.5
	var hy := size_value.y * 0.5
	var hz := size_value.z * 0.5
	for y in [center.y - hy, center.y + hy]:
		bars.append(_add_edge_bar(Vector3(center.x, y, center.z - hz + t * 0.5), Vector3(maxf(0.05, size_value.x - t), t, t), material))
		bars.append(_add_edge_bar(Vector3(center.x, y, center.z + hz - t * 0.5), Vector3(maxf(0.05, size_value.x - t), t, t), material))
		bars.append(_add_edge_bar(Vector3(center.x - hx + t * 0.5, y, center.z), Vector3(t, t, maxf(0.05, size_value.z - t)), material))
		bars.append(_add_edge_bar(Vector3(center.x + hx - t * 0.5, y, center.z), Vector3(t, t, maxf(0.05, size_value.z - t)), material))
	for x in [center.x - hx, center.x + hx]:
		for z in [center.z - hz, center.z + hz]:
			bars.append(_add_edge_bar(Vector3(x + (t * 0.5 if x < center.x else -t * 0.5), center.y, z + (t * 0.5 if z < center.z else -t * 0.5)), Vector3(t, maxf(0.05, size_value.y - t), t), material))
	return bars


func _add_edge_bar(center: Vector3, size_value: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size_value
	var bar := MeshInstance3D.new()
	bar.name = "FloorSolidEdge"
	bar.mesh = mesh
	bar.material_override = material
	bar.position = center + Vector3.DOWN * BLOCK_SPAWN_DEPTH
	_stair_root.add_child(bar)
	return bar


func _edge_target_positions(edge_bars: Array[MeshInstance3D]) -> Array[Vector3]:
	var result: Array[Vector3] = []
	for bar in edge_bars:
		result.append(bar.position - Vector3.DOWN * BLOCK_SPAWN_DEPTH)
	return result


func _build_circuit_renderer() -> void:
	_circuit_mesh = ImmediateMesh.new()
	_circuit_mesh_instance = MeshInstance3D.new()
	_circuit_mesh_instance.name = "FloorCircuitEvents"
	_circuit_mesh_instance.mesh = _circuit_mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.72, 0.18, 1.0)
	mat.emission_energy_multiplier = 1.6
	_circuit_mesh_instance.material_override = mat
	_world_root.add_child(_circuit_mesh_instance)


func _build_door() -> void:
	_door_root = Node3D.new()
	_door_root.name = "FinalDoorRoot"
	var end_path := _path_point(1.0)
	var road_top_y := end_path.y - 1.20
	var door_pos := Vector3(0.0, road_top_y, end_path.z - 1.75)
	_door_root.position = door_pos
	_door_root.visible = false
	_world_root.add_child(_door_root)

	var door_scale := 1.32
	var door_mat := _make_floor_material()
	var edge_mat := _make_floor_edge_material()

	_door_glow_material = StandardMaterial3D.new()
	_door_glow_material.albedo_color = Color(0.86, 0.84, 0.78, 0.72)
	_door_glow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_door_glow_material.emission_enabled = true
	_door_glow_material.emission = Color(0.86, 0.78, 0.66, 1.0)
	_door_glow_material.emission_energy_multiplier = 0.18

	_add_door_part("DoorThreshold", Vector3(0.0, 0.07, 0.08) * door_scale, Vector3(3.18, 0.14, 0.50) * door_scale, door_mat, _door_root)
	_add_door_part("DoorFrameLeft", Vector3(-1.48, 1.98, 0.0) * door_scale, Vector3(0.22, 3.90, 0.48) * door_scale, door_mat, _door_root)
	_add_door_part("DoorFrameRight", Vector3(1.48, 1.98, 0.0) * door_scale, Vector3(0.22, 3.90, 0.48) * door_scale, door_mat, _door_root)
	_add_door_part("DoorFrameTop", Vector3(0.0, 3.78, 0.0) * door_scale, Vector3(3.18, 0.24, 0.48) * door_scale, door_mat, _door_root)
	_add_door_part("DoorBlackInterior", Vector3(0.0, 1.98, -0.34) * door_scale, Vector3(2.56, 3.44, 0.12) * door_scale, _door_glow_material, _door_root)
	_add_door_outline_strips(door_scale, edge_mat)

	_door_pivot = Node3D.new()
	_door_pivot.name = "SingleDoorPivot"
	_door_pivot.position = Vector3(-1.18, 1.96, 0.08) * door_scale
	_door_root.add_child(_door_pivot)
	_door_leaf = _add_door_part("SingleDoorLeaf", Vector3(1.18, 0.0, 0.0) * door_scale, Vector3(2.36, 3.42, 0.24) * door_scale, door_mat, _door_pivot)
	_add_door_leaf_outline_strips(door_scale, edge_mat)
	_add_door_surface_circuits(door_scale)


func _add_door_part(part_name: String, local_position: Vector3, size_value: Vector3, mat: Material, parent: Node = null) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size_value
	var part := MeshInstance3D.new()
	part.name = part_name
	part.mesh = mesh
	part.material_override = mat
	part.position = local_position
	var target_parent := parent if parent != null else _door_root
	target_parent.add_child(part)
	return part


func _add_door_outline_strips(door_scale: float, mat: Material) -> void:
	var t := 0.034 * door_scale
	var z := 0.266 * door_scale
	var left_x := -1.62 * door_scale
	var right_x := 1.62 * door_scale
	var bottom_y := 0.18 * door_scale
	var top_y := 3.92 * door_scale
	_add_door_part("DoorThinWhiteEdge", Vector3(left_x, (bottom_y + top_y) * 0.5, z), Vector3(t, top_y - bottom_y, t), mat, _door_root)
	_add_door_part("DoorThinWhiteEdge", Vector3(right_x, (bottom_y + top_y) * 0.5, z), Vector3(t, top_y - bottom_y, t), mat, _door_root)
	_add_door_part("DoorThinWhiteEdge", Vector3(0.0, top_y, z), Vector3(right_x - left_x, t, t), mat, _door_root)


func _add_door_leaf_outline_strips(door_scale: float, mat: Material) -> void:
	var t := 0.026 * door_scale
	var z := 0.166 * door_scale
	var left_x := 0.08 * door_scale
	var right_x := 2.28 * door_scale
	var bottom_y := -1.60 * door_scale
	var top_y := 1.60 * door_scale
	_add_door_part("DoorLeafThinWhiteEdge", Vector3(left_x, 0.0, z), Vector3(t, top_y - bottom_y, t), mat, _door_pivot)
	_add_door_part("DoorLeafThinWhiteEdge", Vector3(right_x, 0.0, z), Vector3(t, top_y - bottom_y, t), mat, _door_pivot)
	_add_door_part("DoorLeafThinWhiteEdge", Vector3((left_x + right_x) * 0.5, top_y, z), Vector3(right_x - left_x, t, t), mat, _door_pivot)
	_add_door_part("DoorLeafThinWhiteEdge", Vector3((left_x + right_x) * 0.5, bottom_y, z), Vector3(right_x - left_x, t, t), mat, _door_pivot)


func _add_door_surface_circuits(door_scale: float) -> void:
	_door_circuit_mesh = ImmediateMesh.new()
	_door_circuit_instance = MeshInstance3D.new()
	_door_circuit_instance.name = "DoorSurfaceCircuits"
	_door_circuit_instance.mesh = _door_circuit_mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.62, 0.16, 1.0)
	mat.emission_energy_multiplier = 1.9
	_door_circuit_instance.material_override = mat
	_door_pivot.add_child(_door_circuit_instance)
	_seed_door_surface_circuit_tracks(door_scale)


func _seed_door_surface_circuit_tracks(door_scale: float) -> void:
	_door_circuit_tracks.clear()
	var min_x := 0.26 * door_scale
	var max_x := 2.10 * door_scale
	var min_y := -1.34 * door_scale
	var max_y := 1.34 * door_scale
	var z := 0.148 * door_scale
	var x_steps := 14
	var y_steps := 18
	var used_columns: Array[int] = []
	for _i in range(8):
		var column := _pick_spaced_grid_index(used_columns, x_steps, 2)
		used_columns.append(column)
		var x := _jittered_grid_value(min_x, max_x, x_steps, column, 0.16)
		var y_index := _rng.randi_range(0, 3)
		var nodes: Array[Dictionary] = [_door_surface_node(x, _grid_value(min_y, max_y, y_steps, y_index), z)]
		var turn_budget := _rng.randi_range(2, 4)
		while y_index < y_steps:
			y_index = mini(y_steps, y_index + _rng.randi_range(3, 6))
			nodes.append(_door_surface_node(x, _jittered_grid_value(min_y, max_y, y_steps, y_index, 0.12), z))
			if turn_budget > 0 and y_index < y_steps - 1 and _rng.randf() < 0.72:
				column = clampi(column + (-1 if _rng.randf() < 0.5 else 1) * _rng.randi_range(2, 4), 1, x_steps - 1)
				x = _jittered_grid_value(min_x, max_x, x_steps, column, 0.14)
				nodes.append(_door_surface_node(x, _jittered_grid_value(min_y, max_y, y_steps, y_index, 0.12), z))
				turn_budget -= 1
		_add_door_surface_track(nodes)
	for _i in range(7):
		var row := _rng.randi_range(2, y_steps - 2)
		var x0 := _jittered_grid_value(min_x, max_x, x_steps, _rng.randi_range(1, 5), 0.12)
		var x1 := _jittered_grid_value(min_x, max_x, x_steps, _rng.randi_range(8, x_steps - 1), 0.12)
		var y := _jittered_grid_value(min_y, max_y, y_steps, row, 0.18)
		var nodes: Array[Dictionary] = [
			_door_surface_node(x0, y, z),
			_door_surface_node(lerpf(x0, x1, _rng.randf_range(0.38, 0.62)), y, z),
			_door_surface_node(x1, y, z),
		]
		if _rng.randf() < 0.55:
			var branch_y := _jittered_grid_value(min_y, max_y, y_steps, clampi(row + (-1 if _rng.randf() < 0.5 else 1) * _rng.randi_range(2, 4), 1, y_steps - 1), 0.12)
			nodes.append(_door_surface_node(x1, branch_y, z))
		_add_door_surface_track(nodes)


func _door_surface_node(x: float, y: float, z: float) -> Dictionary:
	return {
		"pos": Vector3(x, y, z),
		"normal": Vector3.BACK,
	}


func _add_door_surface_track(nodes: Array[Dictionary]) -> void:
	var length := _track_length(nodes)
	if nodes.size() < 2 or length < 0.20:
		return
	_door_circuit_tracks.append({
		"nodes": nodes,
		"length": length,
		"seed": _rng.randf_range(0.0, TAU),
		"width": _rng.randf_range(CIRCUIT_RIBBON_WIDTH * 0.72, CIRCUIT_RIBBON_WIDTH * 1.10),
		"charge": _rng.randf_range(0.18, 0.50),
	})


func _build_reflection_probe() -> void:
	_reflection_probe = ReflectionProbe.new()
	_reflection_probe.name = "MirrorSphereReflectionProbe"
	_reflection_probe.position = Vector3(0.0, 1.12, 0.0)
	_reflection_probe.size = Vector3(34.0, 28.0, 34.0)
	_reflection_probe.intensity = 3.8
	_reflection_probe.update_mode = ReflectionProbe.UPDATE_ALWAYS
	_world_root.add_child(_reflection_probe)


func _build_aurora() -> void:
	_aurora_root = Node3D.new()
	_aurora_root.name = "AuroraEruptionRoot"
	_aurora_root.position = Vector3(0.0, 1.12, 0.0)
	_world_root.add_child(_aurora_root)
	var palette_sets := [
		[Color(0.06, 0.98, 0.64, 1.0), Color(0.10, 0.74, 1.0, 1.0), Color(0.55, 0.18, 0.96, 1.0)],
		[Color(0.08, 0.86, 1.0, 1.0), Color(0.64, 0.32, 1.0, 1.0), Color(0.98, 0.24, 0.72, 1.0)],
		[Color(0.22, 1.0, 0.44, 1.0), Color(0.08, 0.62, 1.0, 1.0), Color(0.92, 0.72, 0.18, 1.0)],
	]
	var sheets := [
		{"angle": -2.40, "arc": 1.35, "y": -0.10, "height": 2.55, "length": 3.25, "width": 1.34, "lift": 0.18},
		{"angle": -1.55, "arc": -1.10, "y": 0.12, "height": 2.95, "length": 3.75, "width": 1.62, "lift": 0.36},
		{"angle": -0.55, "arc": 0.86, "y": -0.24, "height": 2.30, "length": 2.85, "width": 1.18, "lift": -0.04},
		{"angle": 0.35, "arc": -1.42, "y": 0.06, "height": 3.20, "length": 4.05, "width": 1.78, "lift": 0.12},
		{"angle": 1.32, "arc": 0.72, "y": -0.18, "height": 2.10, "length": 2.65, "width": 1.06, "lift": -0.18},
		{"angle": 2.12, "arc": -0.92, "y": 0.22, "height": 2.70, "length": 3.35, "width": 1.40, "lift": 0.26},
		{"angle": 2.82, "arc": 1.18, "y": -0.02, "height": 2.45, "length": 3.05, "width": 1.28, "lift": 0.02},
	]
	for i in range(sheets.size()):
		var sheet_data := sheets[i] as Dictionary
		var mat := _make_aurora_material(palette_sets[i % palette_sets.size()], float(i) * 13.17)
		var sheet := MeshInstance3D.new()
		sheet.name = "AuroraCurtain_%02d" % i
		sheet.mesh = _make_aurora_mesh(
			float(sheet_data["width"]),
			float(sheet_data["height"]),
			float(sheet_data["length"]),
			i,
			float(sheet_data["angle"]),
			float(sheet_data["y"]),
			float(sheet_data["arc"]),
			float(sheet_data["lift"])
		)
		sheet.material_override = mat
		sheet.set_meta("base_angle", float(sheet_data["angle"]))
		sheet.set_meta("phase", float(i) * 0.73)
		sheet.set_meta("sway", 0.18 + float(i % 3) * 0.045)
		_aurora_root.add_child(sheet)
		_aurora_sheet_params.append({
			"width": float(sheet_data["width"]),
			"height": float(sheet_data["height"]),
			"length": float(sheet_data["length"]),
			"seed_index": i,
			"angle": float(sheet_data["angle"]),
			"y": float(sheet_data["y"]),
			"arc": float(sheet_data["arc"]),
			"lift": float(sheet_data["lift"]),
		})
		_aurora_sheets.append(sheet)
		_aurora_materials.append(mat)


func _make_aurora_mesh(width: float, height: float, length: float, seed_index: int, angle: float, vertical_bias: float, arc: float, lift_bias: float, inertia_strength: float = 0.0) -> ArrayMesh:
	var columns := 28
	var rows := 58
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var up := Vector3.UP
	for y in range(rows + 1):
		var v := float(y) / float(rows)
		var flow := smoothstep(0.0, 1.0, v)
		var theta := angle + arc * flow + sin(v * TAU * 1.35 + float(seed_index) * 0.67) * 0.18 * v
		var core_exit := smoothstep(0.22, 0.46, v)
		var radius := pow(v, 1.34) * length
		var lift := (vertical_bias + lift_bias * v + sin(v * TAU * 0.85 + float(seed_index) * 0.53) * 0.22 * v) * core_exit
		var radial := Vector3(cos(theta), 0.0, sin(theta)).normalized()
		var tangent := Vector3(-sin(theta), 0.0, cos(theta)).normalized()
		var center := radial * radius + up * lift
		center += tangent * sin(v * TAU * 1.8 + float(seed_index) * 0.77) * 0.28 * v * core_exit
		center += _aurora_inertia_offset(v, inertia_strength)
		var side_axis := (tangent * 0.72 + up * 0.55 + radial * 0.10).normalized()
		var local_width := width * (0.012 + smoothstep(0.24, 0.62, v) * (0.58 + v * 0.58))
		var vertical_axis := (up * 0.92 - radial * 0.18).normalized()
		for x in range(columns + 1):
			var u := float(x) / float(columns)
			var centered_u := u - 0.5
			var side := centered_u * local_width
			var curtain_drop := (0.5 - absf(centered_u)) * height * smoothstep(0.34, 0.72, v)
			var ripple := sin(u * TAU * 2.0 + v * TAU * 3.8 + float(seed_index) * 0.61) * 0.075 * v * core_exit
			var filament_offset := sin(u * TAU * 8.0 + v * TAU * 2.2 + float(seed_index)) * 0.030 * smoothstep(0.22, 0.58, v)
			vertices.append(center + side_axis * (side + ripple) + tangent * filament_offset + vertical_axis * curtain_drop)
			uvs.append(Vector2(u, v))
	for y in range(rows):
		for x in range(columns):
			var a := y * (columns + 1) + x
			var b := a + 1
			var c := a + columns + 1
			var d := c + 1
			indices.append_array([a, c, b, b, c, d])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _aurora_inertia_offset(v: float, inertia_strength: float) -> Vector3:
	if inertia_strength <= 0.001 or _sphere_motion_history.size() < 3:
		return Vector3.ZERO
	var tail := smoothstep(0.06, 1.0, v)
	if tail <= 0.001:
		return Vector3.ZERO
	var max_index := _sphere_motion_history.size() - 1
	var history_index := clampi(int(round(pow(v, 1.18) * float(max_index))), 0, max_index)
	var past_offset := _sphere_motion_history[history_index]
	var current_offset := _sphere_motion_history[0]
	var lag := past_offset - current_offset
	var max_lag := lerpf(0.18, 4.8, clampf(inertia_strength, 0.0, 1.0))
	if lag.length() > max_lag:
		lag = lag.normalized() * max_lag
	return lag * tail * inertia_strength


func _make_aurora_material(colors: Array, seed_value: float) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never;

uniform vec4 color_a : source_color = vec4(0.08, 0.96, 0.72, 1.0);
uniform vec4 color_b : source_color = vec4(0.24, 0.66, 1.0, 1.0);
uniform vec4 color_c : source_color = vec4(0.92, 0.20, 0.82, 1.0);
uniform float time = 0.0;
uniform float fade : hint_range(0.0, 1.0) = 0.0;
uniform float intensity = 1.0;
uniform float seed = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
		u.y
	);
}

void vertex() {
	float root_lock = smoothstep(0.04, 0.18, UV.y);
	float travel = time * 1.15;
	float curtain = sin(UV.x * 8.0 + UV.y * 12.0 - travel + seed) * 0.30;
	float slow = sin(UV.y * 4.2 + time * 0.68 + seed * 0.37) * 0.34;
	float kink = sin(UV.y * 9.0 - time * 1.05 + seed) * sin(UV.x * 3.5 + seed) * 0.18;
	float fold = sin((UV.x + UV.y * 0.42) * 18.0 - time * 2.05 + seed) * 0.08;
	VERTEX.x += (curtain + slow + kink + fold) * UV.y * root_lock;
	VERTEX.y += sin(UV.x * 5.0 + UV.y * 8.5 - time * 0.90 + seed) * 0.20 * UV.y * root_lock;
	VERTEX.z += sin(UV.x * 5.8 + UV.y * 7.0 + time * 1.10 + seed) * 0.26 * UV.y * root_lock;
}

void fragment() {
	float root = smoothstep(0.0, 0.10, UV.y);
	float tail = 1.0 - smoothstep(0.76, 1.0, UV.y);
	float side_fade = smoothstep(0.0, 0.18, UV.x) * (1.0 - smoothstep(0.82, 1.0, UV.x));
	float lower_fade = 1.0 - smoothstep(0.72, 1.0, abs(UV.x - 0.5) * 2.0);
	float flow = fract(UV.y * 1.35 - time * 0.34 + seed * 0.021);
	float flow_front = smoothstep(0.02, 0.20, flow) * (1.0 - smoothstep(0.58, 1.0, flow));
	float moving_phase = UV.y * 3.8 - time * 0.92 + seed * 0.013;
	float sheet_wave = 0.55 + 0.45 * sin(moving_phase * 6.28318 + sin(UV.x * 7.0 + time * 0.36 + seed));
	float fine = pow(0.5 + 0.5 * sin(UV.x * 58.0 + noise(vec2(UV.x * 5.0, UV.y * 5.5 - time * 0.70)) * 9.0 + time * 1.65 + seed), 6.0);
	float curtains = pow(0.5 + 0.5 * sin(UV.x * 22.0 + UV.y * 8.5 - time * 1.18 + noise(vec2(UV.y * 3.0 + seed, time * 0.38)) * 5.0), 2.5);
	float veil = noise(vec2(UV.x * 1.4 + time * 0.12 + seed, UV.y * 6.2 - time * 0.55));
	float breathing = 0.60 + 0.40 * sin(time * 1.05 + seed + UV.y * 2.4);
	float alpha = root * tail * side_fade * lower_fade * breathing * (0.04 + flow_front * 0.26 + sheet_wave * 0.18 + curtains * 0.22 + fine * 0.34 + veil * 0.10) * fade;
	vec3 c1 = mix(color_a.rgb, color_b.rgb, smoothstep(0.08, 0.64, UV.y + sin(UV.x * 4.0 + time * 0.42) * 0.08));
	vec3 c2 = mix(c1, color_c.rgb, smoothstep(0.70, 1.0, UV.x + sin(UV.y * 3.0 - time * 0.50) * 0.10));
	ALBEDO = c2;
	EMISSION = c2 * alpha * intensity * 6.4;
	ALPHA = clamp(alpha * intensity, 0.0, 0.62);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("color_a", colors[0])
	material.set_shader_parameter("color_b", colors[1])
	material.set_shader_parameter("color_c", colors[2])
	material.set_shader_parameter("seed", seed_value)
	material.set_shader_parameter("fade", 0.0)
	material.set_shader_parameter("intensity", aurora_intensity)
	return material


func _update_sphere() -> void:
	if _sphere_root == null:
		return
	var eased := smoothstep(0.0, 1.0, _reveal)
	if _finale_active:
		var finale_target := _finale_sphere_position()
		var enter_t := _finale_segment_t(_finale_enter_start_time(), FINALE_ENTER_SEC)
		if enter_t > 0.0:
			_sphere_root.position = finale_target
		else:
			_sphere_root.position = _sphere_root.position.lerp(finale_target, clampf(get_process_delta_time() * 4.4, 0.0, 1.0))
		_sphere_root.scale = Vector3.ONE * lerpf(1.0, 0.22, smoothstep(0.0, 1.0, enter_t))
		_update_sphere_rotation()
		if _reflection_probe != null:
			_reflection_probe.position = _sphere_root.position
		if _sphere_material != null:
			var shade := lerpf(0.38, 0.74, eased)
			_sphere_material.albedo_color = Color(shade, shade + 0.012, shade + 0.028, 1.0)
		_record_sphere_motion(Vector3.ZERO)
		return
	var sphere_progress: float = _guide_progress()
	var path_pos := _path_point(sphere_progress)
	var base_position := path_pos + Vector3(0.0, 0.92, -1.15)
	var self_motion := _sphere_self_motion_offset()
	var target_position := base_position + self_motion
	if not _path_started and _move_progress <= 0.001:
		base_position = _path_point(0.0) + Vector3(0.0, 1.22, -2.55)
		self_motion = _sphere_self_motion_offset() * 0.45
		target_position = base_position + self_motion
	_sphere_root.position = _sphere_root.position.lerp(target_position, clampf(get_process_delta_time() * 5.8, 0.0, 1.0))
	if _move_progress >= DOOR_ENTER_START:
		var enter_t := smoothstep(0.0, 1.0, (_move_progress - DOOR_ENTER_START) / maxf(0.001, 1.0 - DOOR_ENTER_START))
		var door_target := _path_point(1.0) + Vector3(0.0, 0.72, -2.05)
		_sphere_root.position = _sphere_root.position.lerp(door_target, enter_t)
		_sphere_root.scale = Vector3.ONE * lerpf(1.0, 0.42, enter_t)
	else:
		_sphere_root.scale = Vector3.ONE * lerpf(0.72, 1.0, eased)
	_update_sphere_rotation()
	if _reflection_probe != null:
		_reflection_probe.position = _sphere_root.position
	if _sphere_material != null:
		var shade := lerpf(0.38, 0.74, eased)
		_sphere_material.albedo_color = Color(shade, shade + 0.012, shade + 0.028, 1.0)
	_record_sphere_motion(self_motion)


func _finale_sphere_position() -> Vector3:
	var player_anchor := _path_point(FINALE_APPROACH_END) + Vector3(0.0, 1.18, 0.10)
	if _finale_time < _finale_orbit_start_time():
		return _path_point(_guide_progress()) + Vector3(0.0, 0.92, -1.15) + _sphere_self_motion_offset() * 0.35
	if not _finale_orbit_start_set:
		_finale_orbit_start_position = _sphere_root.position
		_finale_orbit_start_set = true
	var orbit_t := _finale_segment_t(_finale_orbit_start_time(), FINALE_ORBIT_SEC)
	var orbit_eased := smoothstep(0.0, 1.0, orbit_t)
	var angle := -PI * 0.35 + orbit_eased * TAU * 2.65
	var radius := lerpf(2.85, 3.55, sin(orbit_eased * PI))
	var orbit_pos := player_anchor + Vector3(cos(angle) * radius, 0.78 + sin(angle * 1.65) * 0.30, sin(angle) * radius)
	orbit_pos.z -= 0.55
	if orbit_t < 0.18:
		var settle := smoothstep(0.0, 0.18, orbit_t)
		orbit_pos = _finale_orbit_start_position.lerp(orbit_pos, settle)
	var enter_t := _finale_segment_t(_finale_enter_start_time(), FINALE_ENTER_SEC)
	if enter_t <= 0.0:
		return orbit_pos
	if not _finale_enter_start_set:
		_finale_enter_start_position = orbit_pos
		_finale_enter_start_set = true
	var door_target := _door_entry_target()
	var enter_eased := smoothstep(0.0, 1.0, enter_t)
	return _finale_enter_start_position.lerp(door_target, enter_eased)


func _door_entry_target() -> Vector3:
	if _door_root == null:
		return _path_point(1.0) + Vector3(0.0, 2.05, -8.20)
	return _door_root.global_position + Vector3(0.0, 2.05, -7.20)


func _door_seam_origin() -> Vector3:
	if _door_root == null:
		return _path_point(1.0) + Vector3(1.55, 2.10, 0.34)
	return _door_root.global_position + Vector3(1.51, 2.12, 0.44)


func _sphere_self_motion_offset() -> Vector3:
	var active := smoothstep(0.0, 0.18, _reveal)
	var motion_gate := lerpf(0.62, 1.0, smoothstep(0.02, 0.18, _move_progress))
	var x := sin(_time * 0.72) * 1.08 + sin(_time * 1.31 + 1.4) * 0.34
	var y := sin(_time * 0.94 + 0.7) * 0.12
	var z := sin(_time * 0.58 + 2.1) * 0.34
	return Vector3(x, y, z) * active * motion_gate


func _update_sphere_rotation() -> void:
	if _sphere_root == null:
		return
	var yaw := _time * 0.34 + sin(_time * 0.47) * 0.18
	var pitch := _time * 0.21 + sin(_time * 0.63 + 1.1) * 0.22
	var roll := _time * 0.27 + sin(_time * 0.39 + 2.3) * 0.26
	var basis := Basis(Vector3.UP, yaw)
	basis = Basis(Vector3.RIGHT, pitch) * basis
	basis = Basis(Vector3.FORWARD, roll) * basis
	var current_scale := _sphere_root.scale
	_sphere_root.basis = basis.orthonormalized()
	_sphere_root.scale = current_scale


func _record_sphere_motion(self_motion: Vector3) -> void:
	var delta := maxf(0.001, get_process_delta_time())
	if _sphere_motion_history.is_empty():
		_last_sphere_motion_offset = self_motion
	var instant_velocity := (self_motion - _last_sphere_motion_offset) / delta
	_sphere_motion_velocity = _sphere_motion_velocity.lerp(instant_velocity, clampf(delta * 7.5, 0.0, 1.0))
	_last_sphere_motion_offset = self_motion
	_sphere_motion_history.push_front(self_motion)
	while _sphere_motion_history.size() > 72:
		_sphere_motion_history.pop_back()


func _guide_progress() -> float:
	if not _path_started and _move_progress <= 0.001:
		return 0.0
	var lead := 0.060
	lead += sin(_time * 0.72) * 0.038
	lead += sin(_time * 1.47 + 1.6) * 0.020
	lead = clampf(lead, 0.018, 0.125)
	if _move_progress > 0.88:
		lead = lerpf(lead, 0.030, smoothstep(0.88, 1.0, _move_progress))
	return clampf(_move_progress + lead, 0.0, 1.0)


func _update_forward_progress(delta: float) -> void:
	if _finale_active:
		if _finale_video_holding:
			_finale_video_elapsed += delta
			if _finale_video_elapsed >= FINALE_VIDEO_TARGET_SEC:
				_finish_finale_video_playback()
			_moving_weight = lerpf(_moving_weight, 0.0, clampf(delta * 1.9, 0.0, 1.0))
			return
		_finale_time += delta
		if not _finale_video_started and _finale_time >= _finale_video_start_time():
			_finale_time = _finale_video_start_time()
			_start_finale_video_playback()
			return
		var approach_t := smoothstep(0.0, 1.0, clampf(_finale_time / FINALE_APPROACH_SEC, 0.0, 1.0))
		_move_progress = lerpf(_finale_start_progress, FINALE_APPROACH_END, approach_t)
		_moving_weight = lerpf(_moving_weight, 0.0, clampf(delta * 1.9, 0.0, 1.0))
		return
	var can_move := _reveal >= 0.78 and _move_progress < 1.0
	var moving := can_move and Input.is_physical_key_pressed(KEY_W)
	_moving_weight = lerpf(_moving_weight, 1.0 if moving else 0.0, clampf(delta * 5.8, 0.0, 1.0))
	if moving:
		_path_started = true
		var top_slow := lerpf(1.0, 0.34, smoothstep(0.76, FINALE_TRIGGER_PROGRESS, _move_progress))
		_move_progress = minf(FINALE_TRIGGER_PROGRESS, _move_progress + move_speed * top_slow * delta / maxf(1.0, path_length))
		if _move_progress >= FINALE_TRIGGER_PROGRESS:
			_start_finale()


func _start_finale() -> void:
	if _finale_active:
		return
	_finale_active = true
	_finale_time = 0.0
	_finale_start_progress = _move_progress
	_finale_orbit_start_set = false
	_finale_enter_start_set = false
	_finale_video_started = false
	_finale_video_finished = false
	_finale_video_holding = false
	_finale_video_elapsed = 0.0
	_path_started = true


func _finale_orbit_start_time() -> float:
	return FINALE_APPROACH_SEC


func _finale_enter_start_time() -> float:
	return FINALE_APPROACH_SEC + FINALE_ORBIT_SEC


func _finale_close_start_time() -> float:
	return _finale_enter_start_time() + FINALE_ENTER_SEC + FINALE_CLEARANCE_SEC


func _finale_leak_start_time() -> float:
	return _finale_close_start_time() + FINALE_CLOSE_SEC


func _finale_video_start_time() -> float:
	return _finale_leak_start_time()


func _finale_fade_start_time() -> float:
	return _finale_leak_start_time() + FINALE_LEAK_SEC


func _finale_complete_time() -> float:
	return _finale_fade_start_time() + FINALE_FADE_SEC + FINALE_TITLE_HOLD_SEC


func _finale_segment_t(start_time: float, duration: float) -> float:
	if not _finale_active:
		return 0.0
	return clampf((_finale_time - start_time) / maxf(0.001, duration), 0.0, 1.0)


func _finale_leak_amount() -> float:
	return smoothstep(0.0, 1.0, _finale_segment_t(_finale_leak_start_time(), FINALE_LEAK_SEC))


func _finale_fade_amount() -> float:
	return smoothstep(0.0, 1.0, _finale_segment_t(_finale_fade_start_time(), FINALE_FADE_SEC))


func _start_finale_video_playback() -> void:
	if _finale_video_started:
		return
	_finale_video_started = true
	_finale_video_finished = false
	_finale_video_elapsed = 0.0
	if _finale_video_audio_player != null and is_instance_valid(_finale_video_audio_player) and _finale_video_audio_player.stream != null:
		_finale_video_audio_player.stop()
		_finale_video_audio_player.play()
	if _finale_video_player == null or not is_instance_valid(_finale_video_player) or _finale_video_player.stream == null:
		_finish_finale_video_playback()
		return
	if _finale_video_overlay != null:
		_finale_video_overlay.visible = true
		_finale_video_overlay.modulate = Color.WHITE
	_finale_video_holding = true
	_finale_video_player.stop()
	_finale_video_player.play()
	_sync_finale_video_reflection_texture()


func _on_finale_video_finished() -> void:
	_finish_finale_video_playback()


func _finish_finale_video_playback() -> void:
	if _finale_video_finished:
		return
	_finale_video_finished = true
	_finale_video_holding = false
	if _finale_video_player != null and is_instance_valid(_finale_video_player):
		_finale_video_player.stop()
	if _finale_video_overlay != null:
		_finale_video_overlay.visible = false


func _update_finale_video_overlay() -> void:
	_sync_finale_video_reflection_texture()
	if _finale_video_sphere_root != null and is_instance_valid(_finale_video_sphere_root):
		var yaw := _time * 0.34 + sin(_time * 0.47) * 0.18
		var pitch := _time * 0.21 + sin(_time * 0.63 + 1.1) * 0.22
		var roll := _time * 0.27 + sin(_time * 0.39 + 2.3) * 0.26
		var basis := Basis(Vector3.UP, yaw)
		basis = Basis(Vector3.RIGHT, pitch) * basis
		basis = Basis(Vector3.FORWARD, roll) * basis
		var current_scale := _finale_video_sphere_root.scale
		_finale_video_sphere_root.basis = basis.orthonormalized()
		_finale_video_sphere_root.scale = current_scale
	if _finale_video_sphere_aurora_root != null and is_instance_valid(_finale_video_sphere_aurora_root):
		var drift_basis := Basis(Vector3.UP, sin(_time * 0.28) * deg_to_rad(8.0))
		_finale_video_sphere_aurora_root.basis = drift_basis
	for i in range(_finale_video_sphere_aurora_sheets.size()):
		var sheet := _finale_video_sphere_aurora_sheets[i]
		if sheet == null or not is_instance_valid(sheet):
			continue
		var phase := float(sheet.get_meta("phase", 0.0))
		var sway := float(sheet.get_meta("sway", 0.2))
		var t := _time * aurora_motion_speed
		sheet.rotation_degrees.y = sin(t * 0.46 + phase) * rad_to_deg(sway)
		sheet.rotation_degrees.z = sin(t * 0.58 + phase * 1.7) * 4.5
		sheet.position.y = sin(t * 0.72 + phase) * 0.16
		var pulse := 1.0 + sin(t * 0.82 + phase * 1.3) * 0.075
		var stretch := 1.0 + sin(t * 0.55 + phase) * 0.12
		sheet.scale = Vector3(pulse, pulse, stretch)
	for material in _finale_video_sphere_aurora_materials:
		if material == null:
			continue
		material.set_shader_parameter("time", _time * aurora_motion_speed)
		material.set_shader_parameter("fade", 1.0)
		material.set_shader_parameter("intensity", aurora_intensity)
	if _finale_video_overlay != null and _finale_video_overlay.visible:
		var fade_in := smoothstep(0.0, 0.35, _finale_video_elapsed)
		var fade_out := 1.0
		if _finale_video_elapsed > FINALE_VIDEO_FAILSAFE_SEC - 0.45:
			fade_out = 1.0 - smoothstep(FINALE_VIDEO_FAILSAFE_SEC - 0.45, FINALE_VIDEO_FAILSAFE_SEC, _finale_video_elapsed)
		_finale_video_overlay.modulate = Color(1.0, 1.0, 1.0, fade_in * fade_out)


func _sync_finale_video_reflection_texture() -> void:
	if _finale_video_reflection_backdrop_material == null or _finale_video_player == null:
		return
	if not is_instance_valid(_finale_video_player) or not _finale_video_player.has_method("get_video_texture"):
		return
	var texture_value: Variant = _finale_video_player.call("get_video_texture")
	var texture := texture_value as Texture2D
	if texture == null:
		return
	if _finale_video_reflection_backdrop_material.albedo_texture != texture:
		_finale_video_reflection_backdrop_material.albedo_texture = texture
	if _finale_video_sphere_mirror_material != null:
		_finale_video_sphere_mirror_material.set_shader_parameter("video_texture", texture)


func _update_background_and_fade() -> void:
	var pearl_t := smoothstep(0.18, FINALE_APPROACH_END, _move_progress)
	var gray_t := smoothstep(0.0, 0.56, pearl_t)
	var white_t := smoothstep(0.48, 1.0, pearl_t)
	var bg := Color.BLACK.lerp(Color(0.42, 0.43, 0.44, 1.0), gray_t)
	bg = bg.lerp(Color(0.92, 0.90, 0.84, 1.0), white_t)
	if _background_rect != null:
		_background_rect.color = bg
	if _environment != null:
		_environment.background_color = bg
		_environment.ambient_light_color = bg.lerp(Color.WHITE, 0.18)
		_environment.ambient_light_energy = lerpf(0.35, 1.05, white_t)
	var fade := _finale_fade_amount()
	if _viewport_container != null:
		var scene_alpha := 1.0 - fade
		_viewport_container.modulate = Color(1.0, 1.0, 1.0, scene_alpha)
	if _title_label != null:
		var title_t := smoothstep(0.12, 0.82, fade)
		_title_label.modulate = Color(1.0, 1.0, 1.0, title_t)
		if _thanks_label != null:
			_thanks_label.modulate = Color(1.0, 1.0, 1.0, title_t)


func _update_camera(delta: float) -> void:
	if _camera == null:
		return
	if _reveal < 0.98 and not _path_started:
		var intro_t := smoothstep(0.0, 1.0, _reveal)
		var start := _path_point(0.0)
		var intro_pos := start + Vector3(0.0, lerpf(2.05, 2.10, intro_t), lerpf(0.72, 0.58, intro_t))
		_camera.position = intro_pos
		_camera.fov = lerpf(48.0, 52.0, intro_t)
		_camera.look_at(start + Vector3(0.0, 2.12, -2.55), Vector3.UP)
		return
	if _finale_active:
		_run_phase += delta * 0.32
		var player_anchor := _path_point(FINALE_APPROACH_END)
		var orbit_t := _finale_segment_t(_finale_orbit_start_time(), FINALE_ORBIT_SEC)
		var enter_t := _finale_segment_t(_finale_enter_start_time(), FINALE_ENTER_SEC)
		var close_t := _finale_segment_t(_finale_close_start_time(), FINALE_CLOSE_SEC)
		var camera_target := player_anchor + Vector3(0.0, 2.35, 4.65)
		_camera.position = _camera.position.lerp(camera_target, clampf(delta * 2.6, 0.0, 1.0))
		_camera.fov = lerpf(54.0, 47.0, smoothstep(0.0, 1.0, enter_t + close_t))
		var door_focus := _door_root.global_position + Vector3(0.0, 2.05, 0.0) if _door_root != null else _path_point(1.0) + Vector3(0.0, 2.05, 0.0)
		var look_target := (_sphere_root.global_position if _sphere_root != null else player_anchor).lerp(door_focus, smoothstep(0.58, 1.0, orbit_t))
		if close_t > 0.0:
			look_target = look_target.lerp(door_focus, smoothstep(0.0, 1.0, close_t))
		_camera.look_at(look_target, Vector3.UP)
		return
	_run_phase += delta * lerpf(2.9, 5.4, _moving_weight) * maxf(_moving_weight, 0.16)
	var here := _path_point(_move_progress)
	var ahead := _path_point(clampf(_move_progress + 0.095, 0.0, 1.0))
	var sphere_pos := _sphere_root.global_position if _sphere_root != null else ahead
	var speed_pull := -0.24 * pow(_moving_weight, 1.4)
	var camera_target := here + Vector3(0.0, 2.05, 0.72 + speed_pull)
	if _move_progress > 0.88:
		var end_t := smoothstep(0.88, 1.0, _move_progress)
		camera_target = camera_target.lerp(_path_point(0.94) + Vector3(0.0, 2.05, 5.0), end_t)
	_camera.position = _camera.position.lerp(camera_target, clampf(delta * 6.5, 0.0, 1.0))
	_camera.fov = lerpf(52.0, 66.0, pow(_moving_weight, 1.35))
	var look_target := sphere_pos.lerp(ahead + Vector3(0.0, 1.4, -2.0), 0.28)
	if _move_progress > DOOR_OPEN_START:
		var door_t := smoothstep(DOOR_OPEN_START, 1.0, _move_progress)
		look_target = look_target.lerp(_path_point(1.0) + Vector3(0.0, 0.72, -2.05), door_t)
	_camera.look_at(look_target, Vector3.UP)


func _path_point(t: float) -> Vector3:
	var p: float = clampf(t, 0.0, 1.0)
	if p <= STAIR_END_PROGRESS:
		var s: float = p / STAIR_END_PROGRESS
		var step_count: float = float(maxi(1, STAIR_COUNT - 1))
		var stepped: float = floorf(s * step_count) / step_count
		var smooth_y: float = lerpf(1.12, PATH_END_Y, s)
		var stair_y: float = lerpf(1.12, PATH_END_Y, stepped)
		var y: float = lerpf(stair_y, smooth_y, 0.22)
		return Vector3(0.0, y, lerpf(PATH_START_Z, -78.0, s))
	var flat_t: float = (p - STAIR_END_PROGRESS) / maxf(0.001, 1.0 - STAIR_END_PROGRESS)
	return Vector3(0.0, PATH_END_Y, lerpf(-78.0, PATH_END_Z, flat_t))


func _update_path_reveal(delta: float) -> void:
	for i in range(_path_blocks.size()):
		var data := _path_blocks[i] as Dictionary
		var block_t := float(data["t"])
		if not bool(data["spawn_started"]) and block_t <= _move_progress + _reveal * 0.10 + 0.18:
			var reveal_t := clampf((_move_progress + 0.18 - block_t) / 0.36, 0.0, 1.0)
			data["spawn_started"] = true
			data["spawn_time"] = _time + reveal_t * 0.34 + _rng.randf_range(0.0, 0.16)
		if bool(data["spawn_started"]) and _time >= float(data["spawn_time"]):
			var progress := float(data["spawn_progress"])
			progress = minf(1.0, progress + delta / 1.25)
			data["spawn_progress"] = progress
		_path_blocks[i] = data
		_apply_floor_spawn_state(data)
	_update_circuits(delta)


func _apply_floor_spawn_state(data: Dictionary) -> void:
	var progress := float(data["spawn_progress"])
	var visible := progress > 0.001
	var eased := _floor_spawn_ease(progress)
	var offset := Vector3.DOWN * (BLOCK_SPAWN_DEPTH * (1.0 - eased))
	var block := data["block"] as MeshInstance3D
	block.visible = visible
	block.position = (data["block_target"] as Vector3) + offset
	var edge_bars := data["edge_bars"] as Array
	var edge_targets := data["edge_targets"] as Array
	for i in range(edge_bars.size()):
		var bar := edge_bars[i] as MeshInstance3D
		bar.visible = visible
		bar.position = (edge_targets[i] as Vector3) + offset


func _floor_spawn_ease(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	if t < 0.42:
		var a := t / 0.42
		return 0.48 * a * a
	var b := (t - 0.42) / 0.58
	return 0.48 + 0.52 * (1.0 - pow(1.0 - b, 3.0))


func _floor_block_y_offset(block_id: int) -> float:
	if block_id < 0 or block_id >= _path_blocks.size():
		return 0.0
	var data := _path_blocks[block_id] as Dictionary
	return -BLOCK_SPAWN_DEPTH * (1.0 - _floor_spawn_ease(float(data["spawn_progress"])))


func _floor_block_spawn_alpha(block_id: int) -> float:
	if block_id < 0 or block_id >= _path_blocks.size():
		return 1.0
	return smoothstep(0.0, 0.18, float((_path_blocks[block_id] as Dictionary)["spawn_progress"]))


func _seed_circuit_paths() -> void:
	_circuit_paths.clear()
	for block in _path_blocks:
		_seed_block_circuit_tracks(block as Dictionary)
	_circuit_events.clear()
	_circuit_spawn_timer = 0.08


func _seed_block_circuit_tracks(block: Dictionary) -> void:
	var center := block["center"] as Vector3
	var half := block["half"] as Vector2
	var top_y := float(block["top_y"])
	var bottom_y := float(block["bottom_y"])
	var block_id := int(block["id"])
	var top_mains := _rng.randi_range(5, 7)
	var top_main_nodes: Array[Array] = []
	var used_top_columns: Array[int] = []
	for _i in range(top_mains):
		var nodes := _make_top_through_track(center, half, top_y, bottom_y, used_top_columns)
		top_main_nodes.append(nodes)
		_add_circuit_track(nodes, block_id)
	for _i in range(_rng.randi_range(3, 9)):
		_add_circuit_track(_make_top_branch_track(center, half, top_y, bottom_y, top_main_nodes), block_id)
	for face in ["front", "back"]:
		for _i in range(_rng.randi_range(1, 2)):
			_add_circuit_track(_make_end_face_vertical_track(center, half, top_y, bottom_y, face), block_id, true)
		if _rng.randf() < 0.56:
			_add_circuit_track(_make_end_face_branch_track(center, half, top_y, bottom_y, face), block_id, true)


func _make_top_through_track(center: Vector3, half: Vector2, top_y: float, bottom_y: float, used_columns: Array[int]) -> Array[Dictionary]:
	var x_steps := clampi(int(round(half.x * 3.2)), 14, 28)
	var z_steps := clampi(int(round(half.y * 4.2)), 22, 42)
	var min_u := -half.x * 0.90
	var max_u := half.x * 0.90
	var min_v := -half.y * _rng.randf_range(0.94, 0.985)
	var max_v := half.y * _rng.randf_range(0.94, 0.985)
	var u_index := _pick_spaced_grid_index(used_columns, x_steps, 2)
	used_columns.append(u_index)
	var u := _jittered_grid_value(min_u, max_u, x_steps, u_index, 0.34)
	var start_row := z_steps
	var end_row := 0
	var v := _jittered_grid_value(min_v, max_v, z_steps, start_row, 0.16)
	var nodes: Array[Dictionary] = [_surface_state_node(center, half, top_y, bottom_y, "top", u, v, top_y)]
	var current_row := start_row
	var lateral_budget := _rng.randi_range(1, 3)
	while current_row > end_row:
		current_row = maxi(end_row, current_row - _rng.randi_range(4, 8))
		v = _jittered_grid_value(min_v, max_v, z_steps, current_row, 0.18)
		nodes.append(_surface_state_node(center, half, top_y, bottom_y, "top", u, v, top_y))
		if lateral_budget > 0 and current_row > end_row and _rng.randf() < 0.58:
			var side_step := -1 if _rng.randf() < 0.5 else 1
			u_index = clampi(_nearest_grid_index(u, min_u, max_u, x_steps) + side_step * _rng.randi_range(2, 5), 1, x_steps - 1)
			u = _jittered_grid_value(min_u, max_u, x_steps, u_index, 0.30)
			nodes.append(_surface_state_node(center, half, top_y, bottom_y, "top", u, v, top_y))
			lateral_budget -= 1
	return nodes


func _make_top_branch_track(center: Vector3, half: Vector2, top_y: float, bottom_y: float, main_tracks: Array[Array]) -> Array[Dictionary]:
	if main_tracks.is_empty():
		return []
	var main := main_tracks[_rng.randi_range(0, main_tracks.size() - 1)]
	if main.size() < 3:
		return []
	var anchor := main[_rng.randi_range(1, main.size() - 2)] as Dictionary
	var anchor_pos := _track_pos(anchor)
	var min_u := -half.x * 0.90
	var max_u := half.x * 0.90
	var min_v := -half.y * 0.96
	var max_v := half.y * 0.96
	var x_steps := clampi(int(round(half.x * 3.2)), 14, 28)
	var u := clampf(anchor_pos.x - center.x, min_u, max_u)
	var v := clampf(anchor_pos.z - center.z, min_v, max_v)
	var dir := -1.0 if _rng.randf() < 0.5 else 1.0
	var branch_u := clampf(u + dir * _grid_step(min_u, max_u, x_steps) * _rng.randi_range(3, 8), min_u, max_u)
	var nodes: Array[Dictionary] = [
		_surface_state_node(center, half, top_y, bottom_y, "top", u, v, top_y),
		_surface_state_node(center, half, top_y, bottom_y, "top", branch_u, v, top_y),
	]
	if _rng.randf() < 0.38:
		var z_steps := clampi(int(round(half.y * 4.2)), 22, 42)
		var next_v := clampf(v - _grid_step(min_v, max_v, z_steps) * _rng.randi_range(2, 5), min_v, max_v)
		nodes.append(_surface_state_node(center, half, top_y, bottom_y, "top", branch_u, next_v, top_y))
	return nodes


func _make_side_through_track(center: Vector3, half: Vector2, top_y: float, bottom_y: float, face: String) -> Array[Dictionary]:
	var z_steps := clampi(int(round(half.y * 3.8)), 20, 38)
	var y_steps := clampi(int(round((top_y - bottom_y) * 3.4)), 9, 18)
	var min_v := -half.y * _rng.randf_range(0.94, 0.985)
	var max_v := half.y * _rng.randf_range(0.94, 0.985)
	var min_y := bottom_y + 0.18
	var max_y := top_y - 0.10
	var side_u := -half.x if face == "left" else half.x
	var start_row := z_steps
	var end_row := 0
	var v := _jittered_grid_value(min_v, max_v, z_steps, start_row, 0.16)
	var y := _jittered_grid_value(min_y, max_y, y_steps, _rng.randi_range(1, maxi(1, y_steps - 1)), 0.28)
	var nodes: Array[Dictionary] = [_surface_state_node(center, half, top_y, bottom_y, face, side_u, v, y)]
	var current_row := start_row
	var vertical_budget := _rng.randi_range(1, 3)
	while current_row > end_row:
		current_row = maxi(end_row, current_row - _rng.randi_range(4, 8))
		v = _jittered_grid_value(min_v, max_v, z_steps, current_row, 0.18)
		nodes.append(_surface_state_node(center, half, top_y, bottom_y, face, side_u, v, y))
		if vertical_budget > 0 and current_row > end_row and _rng.randf() < 0.54:
			var y_index := _nearest_grid_index(y, min_y, max_y, y_steps)
			y_index = clampi(y_index + (-1 if _rng.randf() < 0.5 else 1) * _rng.randi_range(1, 3), 0, y_steps)
			y = _jittered_grid_value(min_y, max_y, y_steps, y_index, 0.25)
			nodes.append(_surface_state_node(center, half, top_y, bottom_y, face, side_u, v, y))
			vertical_budget -= 1
	return nodes


func _make_side_branch_track(center: Vector3, half: Vector2, top_y: float, bottom_y: float, main_tracks: Array[Array]) -> Array[Dictionary]:
	if main_tracks.is_empty():
		return []
	var main := main_tracks[_rng.randi_range(0, main_tracks.size() - 1)]
	if main.size() < 3:
		return []
	var anchor := main[_rng.randi_range(1, main.size() - 2)] as Dictionary
	var normal := _track_normal(anchor)
	var face := "left" if normal.x < 0.0 else "right"
	var side_u := -half.x if face == "left" else half.x
	var anchor_pos := _track_pos(anchor)
	var min_v := -half.y * 0.96
	var max_v := half.y * 0.96
	var min_y := bottom_y + 0.18
	var max_y := top_y - 0.10
	var y_steps := clampi(int(round((top_y - bottom_y) * 3.4)), 9, 18)
	var anchor_v := clampf(anchor_pos.z - center.z, min_v, max_v)
	var anchor_y := clampf(anchor_pos.y, min_y, max_y)
	var branch_y := clampf(anchor_y + _grid_step(min_y, max_y, y_steps) * (-1.0 if _rng.randf() < 0.5 else 1.0) * _rng.randi_range(2, 5), min_y, max_y)
	return [
		_surface_state_node(center, half, top_y, bottom_y, face, side_u, anchor_v, anchor_y),
		_surface_state_node(center, half, top_y, bottom_y, face, side_u, anchor_v, branch_y),
	]


func _make_riser_through_track(center: Vector3, half: Vector2, top_y: float, bottom_y: float) -> Array[Dictionary]:
	var x_steps := clampi(int(round(half.x * 3.0)), 12, 24)
	var y_steps := clampi(int(round((top_y - bottom_y) * 3.0)), 8, 16)
	var min_u := -half.x * 0.86
	var max_u := half.x * 0.86
	var min_y := bottom_y + 0.18
	var max_y := top_y - 0.12
	var face := "back"
	var u := _jittered_grid_value(min_u, max_u, x_steps, _rng.randi_range(1, x_steps - 1), 0.28)
	var y := _jittered_grid_value(min_y, max_y, y_steps, _rng.randi_range(1, maxi(1, y_steps - 1)), 0.22)
	var nodes: Array[Dictionary] = [
		_surface_state_node(center, half, top_y, bottom_y, face, u, half.y, y)
	]
	var current_col := _nearest_grid_index(u, min_u, max_u, x_steps)
	var branch_budget := _rng.randi_range(1, 2)
	while current_col < x_steps:
		current_col = mini(x_steps, current_col + _rng.randi_range(3, 6))
		u = _jittered_grid_value(min_u, max_u, x_steps, current_col, 0.20)
		nodes.append(_surface_state_node(center, half, top_y, bottom_y, face, u, half.y, y))
		if branch_budget > 0 and _rng.randf() < 0.55:
			var y_index := _nearest_grid_index(y, min_y, max_y, y_steps)
			y_index = clampi(y_index + (-1 if _rng.randf() < 0.5 else 1) * _rng.randi_range(1, 3), 0, y_steps)
			y = _jittered_grid_value(min_y, max_y, y_steps, y_index, 0.18)
			nodes.append(_surface_state_node(center, half, top_y, bottom_y, face, u, half.y, y))
			branch_budget -= 1
	return nodes


func _make_riser_branch_track(center: Vector3, half: Vector2, top_y: float, bottom_y: float) -> Array[Dictionary]:
	var min_u := -half.x * 0.80
	var max_u := half.x * 0.80
	var min_y := bottom_y + 0.22
	var max_y := top_y - 0.16
	var x_steps := clampi(int(round(half.x * 3.0)), 12, 24)
	var y_steps := clampi(int(round((top_y - bottom_y) * 3.0)), 8, 16)
	var u := _jittered_grid_value(min_u, max_u, x_steps, _rng.randi_range(1, x_steps - 1), 0.20)
	var y := _jittered_grid_value(min_y, max_y, y_steps, _rng.randi_range(1, maxi(1, y_steps - 1)), 0.16)
	var y2 := clampf(y + _grid_step(min_y, max_y, y_steps) * (-1.0 if _rng.randf() < 0.5 else 1.0) * _rng.randi_range(2, 4), min_y, max_y)
	return [
		_surface_state_node(center, half, top_y, bottom_y, "back", u, half.y, y),
		_surface_state_node(center, half, top_y, bottom_y, "back", u, half.y, y2),
	]


func _make_end_face_vertical_track(center: Vector3, half: Vector2, top_y: float, bottom_y: float, face: String) -> Array[Dictionary]:
	var x_steps := clampi(int(round(half.x * 3.0)), 12, 24)
	var min_u := -half.x * 0.82
	var max_u := half.x * 0.82
	var u := _jittered_grid_value(min_u, max_u, x_steps, _rng.randi_range(1, x_steps - 1), 0.20)
	var v := half.y if face == "back" else -half.y
	var y0 := bottom_y + 0.18
	var y1 := top_y - 0.12
	var mid_y := lerpf(y0, y1, _rng.randf_range(0.34, 0.66))
	var u2 := clampf(u + _grid_step(min_u, max_u, x_steps) * _rng.randi_range(-2, 2), min_u, max_u)
	return [
		_surface_state_node(center, half, top_y, bottom_y, face, u, v, y0),
		_surface_state_node(center, half, top_y, bottom_y, face, u, v, mid_y),
		_surface_state_node(center, half, top_y, bottom_y, face, u2, v, mid_y),
		_surface_state_node(center, half, top_y, bottom_y, face, u2, v, y1),
	]


func _make_end_face_branch_track(center: Vector3, half: Vector2, top_y: float, bottom_y: float, face: String) -> Array[Dictionary]:
	var x_steps := clampi(int(round(half.x * 3.0)), 12, 24)
	var y_steps := clampi(int(round((top_y - bottom_y) * 3.2)), 8, 18)
	var min_u := -half.x * 0.82
	var max_u := half.x * 0.82
	var min_y := bottom_y + 0.22
	var max_y := top_y - 0.16
	var u := _jittered_grid_value(min_u, max_u, x_steps, _rng.randi_range(1, x_steps - 1), 0.18)
	var y := _jittered_grid_value(min_y, max_y, y_steps, _rng.randi_range(1, maxi(1, y_steps - 1)), 0.14)
	var y2 := clampf(y + _grid_step(min_y, max_y, y_steps) * (-1.0 if _rng.randf() < 0.5 else 1.0) * _rng.randi_range(2, 4), min_y, max_y)
	var v := half.y if face == "back" else -half.y
	return [
		_surface_state_node(center, half, top_y, bottom_y, face, u, v, y),
		_surface_state_node(center, half, top_y, bottom_y, face, u, v, y2),
	]


func _grid_step(min_value: float, max_value: float, steps: int) -> float:
	return (max_value - min_value) / maxf(1.0, float(steps))


func _grid_value(min_value: float, max_value: float, steps: int, index: int) -> float:
	return min_value + _grid_step(min_value, max_value, steps) * float(clampi(index, 0, steps))


func _jittered_grid_value(min_value: float, max_value: float, steps: int, index: int, jitter_cells: float) -> float:
	var jitter := _grid_step(min_value, max_value, steps) * _rng.randf_range(-jitter_cells, jitter_cells)
	return clampf(_grid_value(min_value, max_value, steps, index) + jitter, min_value, max_value)


func _nearest_grid_index(value: float, min_value: float, max_value: float, steps: int) -> int:
	return clampi(int(round((value - min_value) / _grid_step(min_value, max_value, steps))), 0, steps)


func _pick_spaced_grid_index(used: Array[int], steps: int, min_gap: int) -> int:
	for _attempt in range(24):
		var candidate := _rng.randi_range(1, steps - 1)
		var valid := true
		for existing in used:
			if absi(candidate - int(existing)) < min_gap:
				valid = false
				break
		if valid:
			return candidate
	return _rng.randi_range(1, steps - 1)


func _add_circuit_track(nodes: Array[Dictionary], block_id: int = -1, end_face: bool = false) -> void:
	var length := _track_length(nodes)
	if nodes.size() < 2 or length < 0.55:
		return
	var center_z := 0.0
	for node in nodes:
		center_z += _track_pos(node).z
	center_z /= float(nodes.size())
	_circuit_paths.append({
		"nodes": nodes,
		"length": length,
		"center_z": center_z,
		"charge": 0.0,
		"seed": _rng.randf_range(0.0, TAU),
		"width": _rng.randf_range(CIRCUIT_RIBBON_WIDTH * 1.05, CIRCUIT_RIBBON_WIDTH * 1.60) if end_face else _rng.randf_range(CIRCUIT_RIBBON_WIDTH * 0.72, CIRCUIT_RIBBON_WIDTH * 1.22),
		"block_id": block_id,
		"end_face": end_face,
	})


func _track_length(nodes: Array) -> float:
	var total := 0.0
	for i in range(nodes.size() - 1):
		total += _track_pos(nodes[i]).distance_to(_track_pos(nodes[i + 1]))
	return total


func _surface_state_node(center: Vector3, half: Vector2, top_y: float, bottom_y: float, face: String, u: float, v: float, side_y: float) -> Dictionary:
	var offset := 0.052
	match face:
		"left":
			return {
				"pos": Vector3(center.x - half.x - offset, clampf(side_y, bottom_y + 0.12, top_y - 0.04), center.z + clampf(v, -half.y, half.y)),
				"normal": Vector3.LEFT,
			}
		"right":
			return {
				"pos": Vector3(center.x + half.x + offset, clampf(side_y, bottom_y + 0.12, top_y - 0.04), center.z + clampf(v, -half.y, half.y)),
				"normal": Vector3.RIGHT,
			}
		"front":
			return {
				"pos": Vector3(center.x + clampf(u, -half.x, half.x), clampf(side_y, bottom_y + 0.12, top_y - 0.04), center.z - half.y - offset),
				"normal": Vector3.FORWARD,
			}
		"back":
			return {
				"pos": Vector3(center.x + clampf(u, -half.x, half.x), clampf(side_y, bottom_y + 0.12, top_y - 0.04), center.z + half.y + offset),
				"normal": Vector3.BACK,
			}
	return {
		"pos": Vector3(center.x + clampf(u, -half.x, half.x), top_y + offset, center.z + clampf(v, -half.y, half.y)),
		"normal": Vector3.UP,
	}


func _track_pos(node: Variant) -> Vector3:
	return (node as Dictionary)["pos"] as Vector3


func _track_normal(node: Variant) -> Vector3:
	return ((node as Dictionary)["normal"] as Vector3).normalized()


func _update_circuits(delta: float) -> void:
	if _circuit_mesh == null:
		return
	_circuit_spawn_timer -= delta
	while _circuit_events.size() < 3:
		_spawn_circuit_wave()
	if _circuit_spawn_timer <= 0.0 and _circuit_events.size() < 5:
		_circuit_spawn_timer = _rng.randf_range(0.45, 0.95)
		_spawn_circuit_wave()
	for i in range(_circuit_events.size() - 1, -1, -1):
		var wave := _circuit_events[i] as Dictionary
		wave["z"] = float(wave["z"]) - float(wave["speed"]) * delta
		wave["age"] = float(wave["age"]) + delta
		_circuit_events[i] = wave
		if float(wave["z"]) < PATH_END_Z - 16.0:
			_circuit_events.remove_at(i)
	for i in range(_circuit_paths.size()):
		var track := _circuit_paths[i] as Dictionary
		var charge := float(track["charge"]) * pow(0.10, delta)
		var center_z := float(track["center_z"])
		if center_z > _camera.position.z + CIRCUIT_DRAW_BEHIND_DISTANCE or center_z < _camera.position.z - CIRCUIT_DRAW_AHEAD_DISTANCE:
			track["charge"] = charge
			_circuit_paths[i] = track
			continue
		for wave in _circuit_events:
			var wave_z := float((wave as Dictionary)["z"])
			var wave_width := float((wave as Dictionary)["width"])
			var distance := absf(center_z - wave_z)
			if distance <= wave_width:
				var t := 1.0 - distance / maxf(0.001, wave_width)
				var pulse := smoothstep(0.0, 1.0, t)
				charge = maxf(charge, pulse * float((wave as Dictionary)["strength"]))
		var block_t := float((_path_blocks[int(track["block_id"])] as Dictionary)["t"]) if int(track["block_id"]) >= 0 and int(track["block_id"]) < _path_blocks.size() else 0.0
		var guide_pulse := 1.0 - smoothstep(0.0, 0.030, absf(block_t - _guide_progress()))
		track["charge"] = clampf(maxf(charge, guide_pulse * 0.58), 0.0, 1.0)
		_circuit_paths[i] = track
	_draw_circuit_events()


func _spawn_circuit_wave() -> void:
	var start_z := _camera.position.z + _rng.randf_range(0.0, 12.0)
	_circuit_events.append({
		"z": start_z,
		"speed": _rng.randf_range(28.0, 46.0),
		"width": _rng.randf_range(5.5, 12.0),
		"strength": _rng.randf_range(0.62, 1.0),
		"age": 0.0,
		"phase": _rng.randf_range(0.0, TAU),
	})


func _draw_circuit_events() -> void:
	_circuit_mesh.clear_surfaces()
	var has_vertices := false
	_circuit_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var now := Time.get_ticks_msec() * 0.001
	for track in _circuit_paths:
		var center_z := float((track as Dictionary)["center_z"])
		if center_z > _camera.position.z + CIRCUIT_DRAW_BEHIND_DISTANCE or center_z < _camera.position.z - CIRCUIT_DRAW_AHEAD_DISTANCE:
			continue
		var block_alpha := _floor_block_spawn_alpha(int((track as Dictionary)["block_id"]))
		if block_alpha <= 0.001:
			continue
		var charge := float((track as Dictionary)["charge"])
		var end_face := bool((track as Dictionary).get("end_face", false))
		var alpha := (0.024 if end_face else CIRCUIT_BASE_ALPHA) + charge * (0.78 if end_face else 0.70)
		if alpha < 0.010:
			continue
		var flicker := 0.90 + 0.10 * sin(now * 18.0 + float((track as Dictionary)["seed"]))
		var color := Color(
			lerpf(0.54, 1.0, charge),
			lerpf(0.29, 0.82, charge),
			lerpf(0.055, 0.22, charge),
			alpha * flicker * block_alpha
		)
		has_vertices = _draw_circuit_track(track as Dictionary, color) or has_vertices
	if has_vertices:
		_circuit_mesh.surface_end()
	else:
		_circuit_mesh.clear_surfaces()


func _draw_circuit_track(track: Dictionary, color: Color) -> bool:
	var nodes := track["nodes"] as Array
	if nodes.size() < 2:
		return false
	var drew := false
	var offset := Vector3.UP * _floor_block_y_offset(int(track["block_id"]))
	for i in range(nodes.size() - 1):
		var a := _track_pos(nodes[i]) + offset
		var b := _track_pos(nodes[i + 1]) + offset
		var normal := (_track_normal(nodes[i]) + _track_normal(nodes[i + 1])).normalized()
		_add_circuit_ribbon_segment(a, b, normal, float(track["width"]), color)
		drew = true
	return drew


func _add_circuit_ribbon_segment(a: Vector3, b: Vector3, normal: Vector3, width: float, color: Color) -> void:
	var dir := b - a
	if dir.length_squared() <= 0.0001:
		return
	dir = dir.normalized()
	var surface_normal := normal.normalized()
	if surface_normal.length_squared() < 0.0001:
		surface_normal = Vector3.UP
	var side := surface_normal.cross(dir)
	if side.length_squared() < 0.0001:
		side = Vector3.RIGHT
	side = side.normalized()
	var lift := surface_normal * 0.012
	var half_width := width * 0.5
	var a_left := a - side * half_width + lift
	var a_right := a + side * half_width + lift
	var b_left := b - side * half_width + lift
	var b_right := b + side * half_width + lift
	_add_circuit_vertex(a_left, color)
	_add_circuit_vertex(a_right, color)
	_add_circuit_vertex(b_right, color)
	_add_circuit_vertex(a_left, color)
	_add_circuit_vertex(b_right, color)
	_add_circuit_vertex(b_left, color)


func _add_circuit_vertex(pos: Vector3, color: Color) -> void:
	_circuit_mesh.surface_set_color(color)
	_circuit_mesh.surface_add_vertex(pos)


func _draw_door_surface_circuits(appear: float, open: float) -> void:
	if _door_circuit_mesh == null:
		return
	_door_circuit_mesh.clear_surfaces()
	if appear <= 0.01:
		return
	var has_vertices := false
	var energy := clampf(maxf(appear, smoothstep(0.88, 0.98, _move_progress)) * (1.0 - open * 0.18), 0.0, 1.0)
	var now := Time.get_ticks_msec() * 0.001
	_door_circuit_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for track in _door_circuit_tracks:
		var charge := clampf(float((track as Dictionary)["charge"]) + energy * 0.72, 0.0, 1.0)
		var flicker := 0.86 + 0.14 * sin(now * 16.0 + float((track as Dictionary)["seed"]))
		var color := Color(
			lerpf(0.58, 1.0, charge),
			lerpf(0.32, 0.78, charge),
			lerpf(0.07, 0.20, charge),
			(0.07 + charge * 0.62) * appear * flicker
		)
		has_vertices = _draw_door_circuit_track(track as Dictionary, color) or has_vertices
	if has_vertices:
		_door_circuit_mesh.surface_end()
	else:
		_door_circuit_mesh.clear_surfaces()


func _draw_door_circuit_track(track: Dictionary, color: Color) -> bool:
	var nodes := track["nodes"] as Array
	if nodes.size() < 2:
		return false
	var drew := false
	for i in range(nodes.size() - 1):
		var a := _track_pos(nodes[i])
		var b := _track_pos(nodes[i + 1])
		var normal := (_track_normal(nodes[i]) + _track_normal(nodes[i + 1])).normalized()
		_add_door_circuit_ribbon_segment(a, b, normal, float(track["width"]), color)
		drew = true
	return drew


func _add_door_circuit_ribbon_segment(a: Vector3, b: Vector3, normal: Vector3, width: float, color: Color) -> void:
	var dir := b - a
	if dir.length_squared() <= 0.0001:
		return
	dir = dir.normalized()
	var surface_normal := normal.normalized()
	if surface_normal.length_squared() < 0.0001:
		surface_normal = Vector3.BACK
	var side := surface_normal.cross(dir)
	if side.length_squared() < 0.0001:
		side = Vector3.RIGHT
	side = side.normalized()
	var lift := surface_normal * 0.010
	var half_width := width * 0.5
	var a_left := a - side * half_width + lift
	var a_right := a + side * half_width + lift
	var b_left := b - side * half_width + lift
	var b_right := b + side * half_width + lift
	_add_door_circuit_vertex(a_left, color)
	_add_door_circuit_vertex(a_right, color)
	_add_door_circuit_vertex(b_right, color)
	_add_door_circuit_vertex(a_left, color)
	_add_door_circuit_vertex(b_right, color)
	_add_door_circuit_vertex(b_left, color)


func _add_door_circuit_vertex(pos: Vector3, color: Color) -> void:
	_door_circuit_mesh.surface_set_color(color)
	_door_circuit_mesh.surface_add_vertex(pos)


func _update_door() -> void:
	if _door_root == null:
		return
	var appear := smoothstep(0.76, 0.90, _move_progress)
	if _finale_active:
		appear = maxf(appear, smoothstep(0.0, 1.0, _finale_time / 1.2))
	_door_root.visible = appear > 0.01
	_door_root.scale = Vector3.ONE * lerpf(0.82, 1.0, appear)
	var open := smoothstep(DOOR_OPEN_START, 0.985, _move_progress)
	if _finale_active:
		var open_start := _finale_orbit_start_time() + FINALE_ORBIT_SEC * 0.48
		var finale_open := smoothstep(0.0, 1.0, _finale_segment_t(open_start, FINALE_ORBIT_SEC * 0.30))
		var close_start := _finale_close_start_time()
		var close := smoothstep(0.0, 1.0, _finale_segment_t(close_start, FINALE_CLOSE_SEC))
		open = lerpf(finale_open, 0.030, close)
	if _door_pivot != null:
		_door_pivot.rotation_degrees.y = lerpf(0.0, 82.0, open)
	_draw_door_surface_circuits(appear, open)
	if _door_glow_material != null:
		_door_glow_material.emission_energy_multiplier = lerpf(0.18, 1.05, _finale_leak_amount())


func _update_completion() -> void:
	if _complete_emitted:
		return
	if _finale_active:
		if _finale_time < _finale_complete_time():
			return
		_complete_emitted = true
		chapter_completed.emit(chapter_index)
		return
	if _move_progress < 1.0:
		return
	_complete_emitted = true
	chapter_completed.emit(chapter_index)


func _update_aurora() -> void:
	var eased := smoothstep(0.0, 1.0, _reveal)
	var leak := _finale_leak_amount()
	if _aurora_root != null:
		if leak > 0.001 and _door_root != null:
			_aurora_root.position = _door_seam_origin()
			_aurora_root.basis = Basis(Vector3.UP, deg_to_rad(6.0))
			_aurora_root.scale = Vector3(lerpf(0.055, 0.48, leak), lerpf(0.30, 1.14, leak), lerpf(0.10, 0.82, leak))
		elif _sphere_root != null:
			_aurora_root.position = _sphere_root.position
			var sphere_basis := _sphere_root.basis.orthonormalized()
			var drift_basis := Basis(Vector3.UP, sin(_time * 0.28) * deg_to_rad(8.0))
			_aurora_root.basis = sphere_basis * drift_basis
			_aurora_root.scale = Vector3.ONE
	var speed := _sphere_motion_velocity.length()
	var inertia_strength := clampf(speed / 2.4, 0.0, 1.0) * eased * (1.0 - leak)
	_aurora_mesh_refresh_timer -= get_process_delta_time()
	if _aurora_mesh_refresh_timer <= 0.0:
		_aurora_mesh_refresh_timer = lerpf(0.075, 0.032, inertia_strength)
		_refresh_aurora_inertia_meshes(inertia_strength)
	for i in range(_aurora_sheets.size()):
		var sheet := _aurora_sheets[i]
		var phase := float(sheet.get_meta("phase", 0.0))
		var sway := float(sheet.get_meta("sway", 0.2))
		var t := _time * aurora_motion_speed
		sheet.rotation_degrees.y = sin(t * 0.46 + phase) * rad_to_deg(sway)
		sheet.rotation_degrees.z = sin(t * 0.58 + phase * 1.7) * 4.5
		sheet.position.y = sin(t * 0.72 + phase) * 0.16 * eased
		var pulse := 1.0 + sin(t * 0.82 + phase * 1.3) * 0.075 * eased
		var stretch := 1.0 + sin(t * 0.55 + phase) * 0.12 * eased
		sheet.scale = Vector3(pulse, pulse, stretch)
	for i in range(_aurora_materials.size()):
		var material := _aurora_materials[i]
		material.set_shader_parameter("time", _time * aurora_motion_speed)
		material.set_shader_parameter("fade", maxf(eased, leak))
		material.set_shader_parameter("intensity", aurora_intensity * lerpf(1.0, 1.55, leak))


func _refresh_aurora_inertia_meshes(inertia_strength: float) -> void:
	if _aurora_sheet_params.size() != _aurora_sheets.size():
		return
	for i in range(_aurora_sheets.size()):
		var sheet := _aurora_sheets[i]
		var params := _aurora_sheet_params[i] as Dictionary
		sheet.mesh = _make_aurora_mesh(
			float(params["width"]),
			float(params["height"]),
			float(params["length"]),
			int(params["seed_index"]),
			float(params["angle"]),
			float(params["y"]),
			float(params["arc"]),
			float(params["lift"]),
			inertia_strength
		)


func _on_resized() -> void:
	if _sub_viewport != null and _viewport_container != null and not _viewport_container.stretch:
		_sub_viewport.size = Vector2i(maxi(1, int(size.x)), maxi(1, int(size.y)))
	if _finale_video_sphere_viewport_container != null and _finale_video_sphere_viewport != null:
		var side := maxi(1, int(minf(size.x, size.y) * finale_video_sphere_size_ratio))
		var mask_center := Vector2(size.x * FINALE_VIDEO_MASK_CENTER_RATIO.x, size.y * FINALE_VIDEO_MASK_CENTER_RATIO.y)
		_finale_video_sphere_viewport_container.size = Vector2(side, side)
		_finale_video_sphere_viewport_container.position = mask_center - Vector2(side, side) * 0.5 + finale_video_sphere_offset
		_finale_video_sphere_viewport.size = Vector2i(side, side)
	if _title_label != null:
		var font_size := clampi(int(size.x * 0.115), 64, 142)
		_title_label.add_theme_font_size_override("font_size", font_size)
	if _thanks_label != null:
		var thanks_size := clampi(int(size.x * 0.028), 22, 40)
		_thanks_label.add_theme_font_size_override("font_size", thanks_size)
		var margin_x := clampf(size.x * 0.045, 28.0, 64.0)
		var margin_y := clampf(size.y * 0.050, 24.0, 54.0)
		_thanks_label.offset_left = margin_x
		_thanks_label.offset_top = margin_y
		_thanks_label.offset_right = -margin_x
		_thanks_label.offset_bottom = -margin_y
