extends Control
class_name IntroCorridorV2

signal intro_finished

const QUANTICO_FONT: FontFile = preload("res://assets/fonts/Quantico.ttf")
const GLITCH_SHADER: Shader = preload("res://shaders/input_hint_glitch.gdshader")
const OPENING_AUDIO: AudioStream = preload("res://assets/audio/初始界面 .mp3")
const CIRCUIT_RIBBON_WIDTH: float = 0.040
const CIRCUIT_BASE_ALPHA: float = 0.038
const FLOOR_INITIAL_REVEAL_DISTANCE: float = 126.0
const FLOOR_RUNNING_REVEAL_DISTANCE: float = 42.0
const FLOOR_INITIAL_REVEAL_SEC: float = 3.65
const FLOOR_SPAWN_DEPTH: float = 10.5
const FLOOR_SPAWN_DURATION: float = 1.25
const CIRCUIT_DRAW_BEHIND_DISTANCE: float = 20.0
const CIRCUIT_DRAW_AHEAD_DISTANCE: float = 96.0
const LAMP_UPDATE_BEHIND_DISTANCE: float = 18.0
const LAMP_UPDATE_AHEAD_DISTANCE: float = 92.0
const GOAL_CLOSE_Z: float = 6.0
const GOAL_FIRST_ESCAPE_Z: float = -82.0
const GOAL_CHASE_DISTANCE: float = 58.0
const GOAL_ESCAPE_TRIGGER_DISTANCE: float = 28.0
const GOAL_OBSERVE_TRIGGER_DISTANCE: float = 9.5
const GOAL_FORM_COUNT: int = 5
const GOAL_OBSERVE_SECONDS: float = 6.0
const GOAL_PARTICLE_CAP: int = 150
const GOAL_ENTER_SECONDS: float = 2.05

@export var startup_sec: float = 2.15
@export var move_speed: float = 9.5
@export var corridor_length: float = 376.0
@export var goal_z: float = -346.0
@export var circuit_event_interval_min: float = 0.45
@export var circuit_event_interval_max: float = 0.95
@export var circuit_active_min: int = 2
@export var circuit_active_max: int = 4

var _viewport_container: SubViewportContainer
var _sub_viewport: SubViewport
var _world_root: Node3D
var _camera: Camera3D
var _goal_root: Node3D
var _sphere_form: Node3D
var _variant_forms: Array[Node3D] = []
var _lamp_rows: Array[Dictionary] = []
var _grazing_lights: Array[Dictionary] = []
var _floor_blocks: Array[Dictionary] = []
var _circuit_mesh_instance: MeshInstance3D
var _circuit_mesh: ImmediateMesh
var _circuit_paths: Array[Dictionary] = []
var _circuit_events: Array[Dictionary] = []
var _circuit_spawn_timer: float = 0.0
var _black_overlay: ColorRect
var _white_overlay: ColorRect
var _w_hint: Label
var _lmb_hint: Label
var _subtitle_root: Control
var _subtitle_particles: Array[Dictionary] = []
var _subtitle_label: Label
var _subtitle_shadow: Label
var _subtitle_material: ShaderMaterial
var _hint_materials: Array[ShaderMaterial] = []
var _ambient_player: AudioStreamPlayer

var _rng := RandomNumberGenerator.new()
var _startup_time: float = 0.0
var _move_progress: float = 0.0
var _moving_weight: float = 0.0
var _run_phase: float = 0.0
var _reached_goal: bool = false
var _transition_started: bool = false
var _entering_goal: bool = false
var _enter_goal_timer: float = 0.0
var _enter_camera_start: Vector3 = Vector3.ZERO
var _enter_camera_fov_start: float = 64.0
var _glitch_timer: float = 0.0
var _variant_time_left: float = 0.0
var _active_variant_index: int = -1
var _startup_complete_audio_played: bool = false
var _floor_rows: int = 0
var _goal_target_z: float = GOAL_CLOSE_Z
var _goal_target_x: float = 0.0
var _goal_target_y: float = 3.1
var _goal_escape_side: int = 1
var _goal_escape_started: bool = false
var _goal_escape_in_progress: bool = false
var _next_goal_escape_progress: float = 0.28
var _goal_escape_cooldown: float = 0.0
var _goal_observe_active: bool = false
var _goal_observe_timer: float = 0.0
var _goal_particle_accum: float = 0.0
var _goal_particles: Array[Dictionary] = []
var _goal_particle_mesh: SphereMesh
var _goal_particle_material: StandardMaterial3D
var _goal_form_pieces: Array[Array] = []
var _goal_form_index: int = 0
var _goal_next_form_index: int = 1
var _goal_cycle_time: float = 0.0
var _goal_cycle_duration: float = 5.8
var _goal_flicker_time: float = 0.0
var _goal_flicker_duration: float = 0.44
var _goal_is_flickering: bool = false
var _subtitle_timer: float = 0.0
var _subtitle_life: float = 0.0
var _subtitle_next_random: float = 14.0
var _subtitle_sequence_index: int = 0
var _subtitle_active: bool = false
var _subtitle_base_position: Vector2 = Vector2.ZERO
var _subtitle_missing_shown: bool = false
var _subtitle_intro_shown: bool = false
var _last_goal_trail_start: Vector2 = Vector2.ZERO
var _last_goal_trail_end: Vector2 = Vector2.ZERO
var _has_goal_trail: bool = false
var _subtitle_messages: Array[String] = [
	"球记得它的碎片。",
	"缺失之物。",
	"你已经沉溺于此太久了。",
	"你不记得水里的尸体。",
	"归于完整。",
	"拼装它的残躯。",
]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_rng.randomize()
	_goal_escape_side = 1 if _rng.randf() >= 0.5 else -1
	_build_scene()
	_build_ui()
	_build_audio()
	_seed_circuit_paths()
	resized.connect(_on_resized)
	_on_resized()


func _process(delta: float) -> void:
	_startup_time += delta
	if _entering_goal:
		_enter_goal_timer += delta
	var input_enabled := _startup_time >= startup_sec and not _transition_started
	var moving := input_enabled and not _reached_goal and Input.is_physical_key_pressed(KEY_W)
	var movement_multiplier := _goal_observe_move_multiplier()
	var moving_visual := moving and movement_multiplier > 0.18
	_moving_weight = lerpf(_moving_weight, 1.0 if moving_visual else 0.0, clampf(delta * 6.0, 0.0, 1.0))
	if moving:
		_move_progress = minf(1.0, _move_progress + (move_speed * movement_multiplier * delta / corridor_length))
		if _move_progress >= 1.0:
			_reached_goal = true
	_update_camera(delta)
	_update_floor_reconstruction(delta)
	_update_lamps()
	_update_goal_glitch()
	_update_goal_chase(delta)
	_update_circuits(delta)
	_update_subtitles(delta)
	_update_ui()
	_update_overlays()


func _input(event: InputEvent) -> void:
	if not _reached_goal or _transition_started:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _is_click_near_goal(event.position):
			get_viewport().set_input_as_handled()
			await _run_exit_transition()


func _exit_tree() -> void:
	for player in [_ambient_player]:
		if player != null and is_instance_valid(player):
			player.stop()
	if _circuit_mesh != null:
		_circuit_mesh.clear_surfaces()
	_clear_goal_particles()


func _build_scene() -> void:
	_viewport_container = SubViewportContainer.new()
	_viewport_container.name = "ViewportContainer"
	_viewport_container.stretch = true
	_viewport_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_viewport_container)

	_sub_viewport = SubViewport.new()
	_sub_viewport.name = "SubViewport"
	_sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_sub_viewport.handle_input_locally = false
	_viewport_container.add_child(_sub_viewport)

	_world_root = Node3D.new()
	_world_root.name = "WorldRoot"
	_sub_viewport.add_child(_world_root)

	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.17, 0.18, 0.19, 1.0)
	env.glow_enabled = true
	env.glow_intensity = 0.65
	env.glow_bloom = 0.18
	environment.environment = env
	_world_root.add_child(environment)

	_camera = Camera3D.new()
	_camera.name = "Camera3D"
	_camera.position = Vector3(0.0, 4.2, 18.0)
	_camera.rotation_degrees = Vector3(-3.8, 0.0, 0.0)
	_camera.fov = 64.0
	_camera.current = true
	_world_root.add_child(_camera)

	var fill := DirectionalLight3D.new()
	fill.light_energy = 0.22
	fill.light_color = Color(0.64, 0.72, 0.86, 1.0)
	fill.rotation_degrees = Vector3(-52.0, 28.0, 0.0)
	_world_root.add_child(fill)

	_build_floor()
	_build_lamps()
	_build_goal()
	_build_circuit_renderer()


func _build_floor() -> void:
	var rows := 56
	_floor_rows = rows
	var z_cursor := 14.0
	for z_index in range(rows):
		var total_width := _rng.randf_range(15.5, 21.0)
		var lane_count := _rng.randi_range(2, 4)
		var lane_edges: Array[float] = [-total_width * 0.5]
		var lane_weights: Array[float] = []
		var weight_sum := 0.0
		for lane_index in range(lane_count):
			var weight := _rng.randf_range(0.72, 1.44)
			lane_weights.append(weight)
			weight_sum += weight
		var x_cursor := -total_width * 0.5
		for lane_index in range(lane_count):
			var lane_width := total_width * float(lane_weights[lane_index]) / weight_sum
			if lane_index == lane_count - 1:
				lane_width = total_width * 0.5 - x_cursor
			x_cursor += lane_width
			lane_edges.append(x_cursor)
		var row_depth := _rng.randf_range(7.2, 12.8)
		var row_end_z := z_cursor - row_depth
		var top_y_base := _rng.randf_range(-0.10, 0.98)
		for lane_index in range(lane_count):
			var left := lane_edges[lane_index]
			var right := lane_edges[lane_index + 1]
			var block_z := z_cursor
			while block_z > row_end_z + 0.12:
				var max_depth := block_z - row_end_z
				var depth := minf(max_depth, _rng.randf_range(2.6, 7.2))
				if max_depth < 3.1:
					depth = max_depth
				var inset := _rng.randf_range(0.00, 0.10)
				var width := maxf(2.8, (right - left) - inset * 2.0)
				var center_x := (left + right) * 0.5 + _rng.randf_range(-0.10, 0.10)
				var center_z := block_z - depth * 0.5
				var height := _rng.randf_range(1.25, 4.25)
				var top_y := top_y_base + _rng.randf_range(-0.52, 0.56)
				_add_floor_block(z_index, Vector3(center_x, top_y - height * 0.5, center_z), Vector3(width, height, depth), top_y)
				block_z -= depth
		z_cursor = row_end_z


func _add_floor_block(row_index: int, position_value: Vector3, size_value: Vector3, top_y: float) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size_value
	var block := MeshInstance3D.new()
	block.name = "MassiveFloorBlock"
	block.mesh = mesh
	block.material_override = _make_floor_material()
	block.position = position_value
	_world_root.add_child(block)
	var edge_bars := _add_floor_edge_frame(position_value, size_value)
	var block_id := _floor_blocks.size()
	block.visible = false
	for bar in edge_bars:
		(bar as MeshInstance3D).visible = false
	_floor_blocks.append({
		"id": block_id,
		"z_index": row_index,
		"center": Vector3(position_value.x, position_value.y, position_value.z),
		"half": Vector2(size_value.x * 0.5, size_value.z * 0.5),
		"top_y": top_y,
		"bottom_y": top_y - size_value.y,
		"block": block,
		"block_target": position_value,
		"edge_bars": edge_bars,
		"edge_targets": _edge_target_positions(edge_bars),
		"spawn_progress": 0.0,
		"spawn_started": false,
		"spawn_time": -1.0,
	})
	block.position = position_value + Vector3.DOWN * FLOOR_SPAWN_DEPTH
	for i in range(edge_bars.size()):
		var bar := edge_bars[i] as MeshInstance3D
		bar.position = (edge_bars[i] as MeshInstance3D).position + Vector3.DOWN * FLOOR_SPAWN_DEPTH


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


func _edge_target_positions(edge_bars: Array[MeshInstance3D]) -> Array[Vector3]:
	var positions: Array[Vector3] = []
	for bar in edge_bars:
		positions.append((bar as MeshInstance3D).position)
	return positions


func _add_floor_edge_frame(center: Vector3, size_value: Vector3) -> Array[MeshInstance3D]:
	var bars: Array[MeshInstance3D] = []
	var material := _make_floor_edge_material()
	var t := 0.055
	var hx := size_value.x * 0.5
	var hy := size_value.y * 0.5
	var hz := size_value.z * 0.5
	for y in [center.y - hy, center.y + hy]:
		bars.append(_add_edge_bar(Vector3(center.x, y, center.z - hz), Vector3(size_value.x + t, t, t), material))
		bars.append(_add_edge_bar(Vector3(center.x, y, center.z + hz), Vector3(size_value.x + t, t, t), material))
		bars.append(_add_edge_bar(Vector3(center.x - hx, y, center.z), Vector3(t, t, size_value.z + t), material))
		bars.append(_add_edge_bar(Vector3(center.x + hx, y, center.z), Vector3(t, t, size_value.z + t), material))
	for x in [center.x - hx, center.x + hx]:
		for z in [center.z - hz, center.z + hz]:
			bars.append(_add_edge_bar(Vector3(x, center.y, z), Vector3(t, size_value.y + t, t), material))
	return bars


func _add_edge_bar(center: Vector3, size_value: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size_value
	var bar := MeshInstance3D.new()
	bar.name = "FloorSolidEdge"
	bar.mesh = mesh
	bar.material_override = material
	bar.position = center
	_world_root.add_child(bar)
	return bar


func _build_lamps() -> void:
	var row_count := int(ceil((12.0 - goal_z + 18.0) / 3.35))
	for i in range(row_count):
		var z := 12.0 - float(i) * 3.35
		var row := {
			"z": z,
			"materials": [],
			"light": null,
		}
		for x in [-8.0, 8.0]:
			var mat := StandardMaterial3D.new()
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mat.albedo_color = Color(0.05, 0.045, 0.032, 1.0)
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.68, 0.22, 1.0)
			mat.emission_energy_multiplier = 0.0
			var mesh := BoxMesh.new()
			mesh.size = Vector3(0.16, 0.16, 2.4)
			var lamp := MeshInstance3D.new()
			lamp.name = "CorridorLamp"
			lamp.mesh = mesh
			lamp.material_override = mat
			lamp.position = Vector3(x, 2.1, z)
			lamp.visible = false
			_world_root.add_child(lamp)
			(row["materials"] as Array).append(mat)
		var light := OmniLight3D.new()
		light.name = "LampRowLight"
		light.position = Vector3(0.0, 3.2, z)
		light.omni_range = 10.0
		light.light_color = Color(1.0, 0.70, 0.28, 1.0)
		light.light_energy = 0.0
		_world_root.add_child(light)
		row["light"] = light
		_lamp_rows.append(row)
		if i % 2 == 0:
			_add_grazing_light_pair(i, z)


func _add_grazing_light_pair(row_index: int, z: float) -> void:
	for side in [-1.0, 1.0]:
		var light := SpotLight3D.new()
		light.name = "InvisibleGrazingLight"
		light.position = Vector3(side * 12.8, 0.82, z + 0.8)
		light.light_color = Color(1.0, 0.78, 0.42, 1.0)
		light.light_energy = 0.0
		light.spot_range = 25.0
		light.spot_angle = 42.0
		light.spot_attenuation = 0.72
		light.transform = Transform3D(Basis.looking_at(Vector3(0.0, 0.08, z - 5.5) - light.position, Vector3.UP), light.position)
		_world_root.add_child(light)
		_grazing_lights.append({
			"row_index": row_index,
			"light": light,
		})


func _build_goal() -> void:
	_goal_root = Node3D.new()
	_goal_root.name = "DistortedGoal"
	_goal_root.position = Vector3(0.0, 3.1, GOAL_CLOSE_Z)
	_world_root.add_child(_goal_root)

	_sphere_form = Node3D.new()
	_sphere_form.name = "SphereForm"
	_goal_root.add_child(_sphere_form)
	_sphere_form.visible = false

	_variant_forms.append(_build_missing_shell_form())
	_variant_forms.append(_build_offset_slices_form())
	_variant_forms.append(_build_orbit_rings_form())
	_variant_forms.append(_build_imploded_core_form())
	_variant_forms.append(_build_polyhedral_remains_form())
	for form in _variant_forms:
		form.visible = false
		_goal_root.add_child(form)
	_set_goal_variant(0)
	_build_goal_particle_resources()


func _build_goal_particle_resources() -> void:
	_goal_particle_mesh = SphereMesh.new()
	_goal_particle_mesh.radius = 0.055
	_goal_particle_mesh.height = 0.11
	_goal_particle_mesh.radial_segments = 8
	_goal_particle_mesh.rings = 4
	_goal_particle_material = StandardMaterial3D.new()
	_goal_particle_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_goal_particle_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_goal_particle_material.albedo_color = Color(0.86, 0.92, 1.0, 0.82)
	_goal_particle_material.emission_enabled = true
	_goal_particle_material.emission = Color(0.86, 0.93, 1.0, 1.0)
	_goal_particle_material.emission_energy_multiplier = 1.8


func _make_goal_sphere_mesh() -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = 2.4
	mesh.height = 4.8
	mesh.radial_segments = 20
	mesh.rings = 10
	return mesh


func _make_goal_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode cull_back, depth_draw_opaque;

uniform vec4 base_color : source_color = vec4(0.025, 0.040, 0.060, 1.0);
uniform float distortion = 0.025;

void vertex() {
	float n = sin(VERTEX.x * 4.1 + TIME * 5.2) * sin(VERTEX.y * 3.7 - TIME * 3.8) * cos(VERTEX.z * 3.3 + TIME * 4.6);
	VERTEX += NORMAL * n * distortion;
}

void fragment() {
	float fresnel = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 2.5);
	ALBEDO = base_color.rgb;
	EMISSION = vec3(0.05, 0.10, 0.16) * fresnel * 0.55;
	ROUGHNESS = 0.34;
	SPECULAR = 0.38;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	return mat


func _make_outline_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.94, 0.97, 1.0, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.90, 0.96, 1.0, 1.0)
	mat.emission_energy_multiplier = 0.52
	mat.cull_mode = BaseMaterial3D.CULL_FRONT
	mat.no_depth_test = false
	return mat


func _add_mesh_with_outline(parent: Node3D, mesh: Mesh, transform_value: Transform3D, scale_value: float) -> void:
	var body := MeshInstance3D.new()
	body.mesh = mesh
	body.material_override = _make_goal_material()
	body.transform = transform_value
	body.scale *= scale_value
	parent.add_child(body)

	var outline := MeshInstance3D.new()
	outline.name = "WhiteOutline"
	outline.mesh = mesh
	outline.material_override = _make_outline_material()
	outline.transform = transform_value
	outline.scale *= scale_value * 1.038
	parent.add_child(outline)


func _new_goal_form(name_value: String) -> Dictionary:
	var root := Node3D.new()
	root.name = name_value
	var pieces: Array[Dictionary] = []
	_goal_form_pieces.append(pieces)
	return {
		"root": root,
		"pieces": pieces,
	}


func _make_goal_piece(form_data: Dictionary, mesh: Mesh, base_transform: Transform3D, broken_transform: Transform3D, scale_value: float = 1.0) -> void:
	var piece := Node3D.new()
	piece.transform = base_transform
	(form_data["root"] as Node3D).add_child(piece)
	_add_mesh_with_outline(piece, mesh, Transform3D.IDENTITY, scale_value)
	(form_data["pieces"] as Array).append({
		"node": piece,
		"base": base_transform,
		"broken": broken_transform,
		"phase": _rng.randf_range(0.0, TAU),
	})


func _goal_piece_basis(direction: Vector3, twist: float = 0.0) -> Basis:
	var dir := direction.normalized()
	var up := Vector3.UP
	if absf(dir.dot(up)) > 0.92:
		up = Vector3.RIGHT
	return Basis.looking_at(dir, up).rotated(dir, twist)


func _build_missing_shell_form() -> Node3D:
	var data := _new_goal_form("MissingShellForm")
	for i in range(22):
		if i in [3, 9, 17]:
			continue
		var theta := float(i) * TAU / 22.0
		var y := _rng.randf_range(-1.45, 1.45)
		var radius := sqrt(maxf(0.1, 1.0 - pow(y / 2.05, 2.0))) * 2.2
		var dir := Vector3(cos(theta) * radius, y, sin(theta) * radius).normalized()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(_rng.randf_range(0.58, 1.05), 0.075, _rng.randf_range(0.38, 0.78))
		var base := Transform3D(_goal_piece_basis(dir, _rng.randf_range(-0.5, 0.5)), dir * 2.18)
		var broken_dir := (dir + Vector3(_rng.randf_range(-0.28, 0.28), _rng.randf_range(-0.20, 0.32), _rng.randf_range(-0.28, 0.28))).normalized()
		var broken := Transform3D(_goal_piece_basis(broken_dir, _rng.randf_range(-1.2, 1.2)), dir * _rng.randf_range(2.75, 3.8))
		_make_goal_piece(data, mesh, base, broken, 1.0)
	return data["root"] as Node3D


func _build_offset_slices_form() -> Node3D:
	var data := _new_goal_form("OffsetSlicesForm")
	for i in range(8):
		var angle := float(i) * TAU / 8.0
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.44, _rng.randf_range(2.8, 4.1), _rng.randf_range(0.72, 1.25))
		var dir := Vector3(cos(angle), 0.0, sin(angle))
		var base_origin := dir * 1.25 + Vector3(0.0, _rng.randf_range(-0.18, 0.18), 0.0)
		var base_basis := Basis().rotated(Vector3.UP, angle).rotated(Vector3.FORWARD, _rng.randf_range(-0.18, 0.18))
		var broken_origin := dir * _rng.randf_range(2.0, 3.25) + Vector3(0.0, _rng.randf_range(-0.75, 0.75), 0.0)
		var broken_basis := base_basis.rotated(Vector3.RIGHT, _rng.randf_range(-0.85, 0.85)).rotated(Vector3.UP, _rng.randf_range(-0.65, 0.65))
		_make_goal_piece(data, mesh, Transform3D(base_basis, base_origin), Transform3D(broken_basis, broken_origin), 1.0)
	return data["root"] as Node3D


func _build_orbit_rings_form() -> Node3D:
	var data := _new_goal_form("OrbitRingsForm")
	for ring in range(4):
		var tilt := Vector3(_rng.randf_range(-0.9, 0.9), _rng.randf_range(-0.9, 0.9), _rng.randf_range(-0.9, 0.9)).normalized()
		var ring_basis := Basis().rotated(Vector3.RIGHT, tilt.x).rotated(Vector3.UP, tilt.y).rotated(Vector3.FORWARD, tilt.z)
		var segments := 10
		for i in range(segments):
			if _rng.randf() < 0.16:
				continue
			var angle := float(i) * TAU / float(segments)
			var local := Vector3(cos(angle) * 2.15, sin(angle) * 2.15, 0.0)
			var dir := ring_basis * local.normalized()
			var mesh := BoxMesh.new()
			mesh.size = Vector3(0.72, 0.052, 0.18)
			var base_basis := ring_basis.rotated(Vector3.FORWARD, angle)
			var base := Transform3D(base_basis, ring_basis * local)
			var broken := Transform3D(base_basis.rotated(Vector3.UP, _rng.randf_range(-0.9, 0.9)), dir * _rng.randf_range(2.8, 4.2))
			_make_goal_piece(data, mesh, base, broken, 1.0)
	return data["root"] as Node3D


func _build_imploded_core_form() -> Node3D:
	var data := _new_goal_form("ImplodedCoreForm")
	for i in range(28):
		var dir := Vector3(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0)).normalized()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(_rng.randf_range(0.18, 0.52), _rng.randf_range(0.34, 1.15), _rng.randf_range(0.18, 0.52))
		var base := Transform3D(_goal_piece_basis(dir, _rng.randf_range(-1.0, 1.0)), dir * _rng.randf_range(0.45, 1.65))
		var broken := Transform3D(_goal_piece_basis(dir, _rng.randf_range(-1.4, 1.4)), dir * _rng.randf_range(2.2, 4.1))
		_make_goal_piece(data, mesh, base, broken, 1.0)
	return data["root"] as Node3D


func _build_polyhedral_remains_form() -> Node3D:
	var data := _new_goal_form("PolyhedralRemainsForm")
	for i in range(18):
		var dir := Vector3(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-0.85, 0.85), _rng.randf_range(-1.0, 1.0)).normalized()
		var mesh: Mesh
		if i % 3 == 0:
			var cone := CylinderMesh.new()
			cone.top_radius = 0.0
			cone.bottom_radius = _rng.randf_range(0.35, 0.75)
			cone.height = _rng.randf_range(0.9, 1.8)
			cone.radial_segments = 4
			mesh = cone
		else:
			var box := BoxMesh.new()
			box.size = Vector3(_rng.randf_range(0.65, 1.35), _rng.randf_range(0.08, 0.22), _rng.randf_range(0.55, 1.1))
			mesh = box
		var base := Transform3D(_goal_piece_basis(dir, _rng.randf_range(-0.7, 0.7)), dir * _rng.randf_range(1.45, 2.35))
		var broken_dir := (dir + Vector3(_rng.randf_range(-0.38, 0.38), _rng.randf_range(-0.32, 0.32), _rng.randf_range(-0.38, 0.38))).normalized()
		var broken := Transform3D(_goal_piece_basis(broken_dir, _rng.randf_range(-1.2, 1.2)), broken_dir * _rng.randf_range(2.6, 4.0))
		_make_goal_piece(data, mesh, base, broken, 1.0)
	return data["root"] as Node3D


func _build_cube_pyramid_form() -> Node3D:
	var root := Node3D.new()
	root.name = "CubePyramidForm"
	var cube := BoxMesh.new()
	cube.size = Vector3(3.7, 3.7, 3.7)
	_add_mesh_with_outline(root, cube, Transform3D.IDENTITY, 1.0)
	for i in range(4):
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 1.1
		cone.height = 3.4
		cone.radial_segments = 4
		var t := Transform3D.IDENTITY
		t.origin = Vector3(sin(float(i) * TAU / 4.0) * 2.2, cos(float(i) * TAU / 4.0) * 2.2, 0.0)
		t = t.rotated(Vector3.FORWARD, float(i) * TAU / 4.0)
		_add_mesh_with_outline(root, cone, t, 1.0)
	return root


func _build_split_sphere_form() -> Node3D:
	var root := Node3D.new()
	root.name = "SplitSphereForm"
	for x in [-1.0, 1.0]:
		for y in [-1.0, 1.0]:
			for z in [-1.0, 1.0]:
				var mesh := _make_goal_sphere_mesh()
				var t := Transform3D.IDENTITY
				t.origin = Vector3(x, y, z) * 0.72
				_add_mesh_with_outline(root, mesh, t, 0.43)
	return root


func _build_shard_form() -> Node3D:
	var root := Node3D.new()
	root.name = "ShardForm"
	for i in range(9):
		var mesh := BoxMesh.new()
		mesh.size = Vector3(_rng.randf_range(0.35, 1.1), _rng.randf_range(1.0, 2.4), _rng.randf_range(0.3, 0.9))
		var t := Transform3D.IDENTITY
		t.origin = Vector3(_rng.randf_range(-1.9, 1.9), _rng.randf_range(-1.7, 1.7), _rng.randf_range(-1.2, 1.2))
		t = t.rotated(Vector3.RIGHT, _rng.randf_range(-1.4, 1.4))
		t = t.rotated(Vector3.UP, _rng.randf_range(-1.4, 1.4))
		_add_mesh_with_outline(root, mesh, t, 1.0)
	return root


func _build_circuit_renderer() -> void:
	_circuit_mesh = ImmediateMesh.new()
	_circuit_mesh_instance = MeshInstance3D.new()
	_circuit_mesh_instance.name = "FloorCircuitEvents"
	_circuit_mesh_instance.mesh = _circuit_mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.no_depth_test = false
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.72, 0.18, 1.0)
	mat.emission_energy_multiplier = 1.6
	_circuit_mesh_instance.material_override = mat
	_world_root.add_child(_circuit_mesh_instance)


func _update_camera(delta: float) -> void:
	if _entering_goal:
		_update_enter_goal_camera()
		return
	_run_phase += delta * lerpf(3.8, 5.9, _moving_weight) * _moving_weight
	var target_z := lerpf(18.0, goal_z + 14.0, _move_progress)
	var stride := _run_phase
	var stretch := pow(_moving_weight, 1.45)
	var vertical_bob := (absf(sin(stride * 2.0)) * 0.046 + sin(stride * 4.0) * 0.006) * _moving_weight
	var lateral_sway := sin(stride) * 0.010 * _moving_weight
	var forward_pulse := (sin(stride * 2.0 + 0.4) * 0.030 - stretch * 0.18) * _moving_weight
	var look_sway := sin(stride + 0.7) * 0.010 * _moving_weight
	var look_bob := sin(stride * 2.0 + 1.2) * 0.020 * _moving_weight
	_camera.position = Vector3(lateral_sway, 4.2 + vertical_bob, target_z + forward_pulse)
	_camera.fov = lerpf(64.0, 78.0, stretch)
	_camera.look_at(Vector3(look_sway, 3.0 + look_bob, goal_z - 18.0 * stretch), Vector3.UP)
	_camera.rotate_object_local(Vector3.FORWARD, sin(stride) * 0.0014 * _moving_weight)
	_viewport_container.scale = Vector2.ONE


func _update_enter_goal_camera() -> void:
	if _goal_root == null:
		return
	var t := clampf(_enter_goal_timer / GOAL_ENTER_SECONDS, 0.0, 1.0)
	var pull := smoothstep(0.0, 1.0, t)
	var goal_pos := _goal_root.global_position
	var from_goal := _enter_camera_start - goal_pos
	if from_goal.length_squared() < 0.001:
		from_goal = Vector3(0.0, 0.0, 1.0)
	var dir := from_goal.normalized()
	var distance := lerpf(from_goal.length(), 0.42, pull)
	var spiral := Vector3(sin(t * TAU * 2.8) * 0.34, cos(t * TAU * 2.1) * 0.22, 0.0) * (1.0 - t)
	_camera.position = goal_pos + dir * distance + spiral
	_camera.fov = lerpf(_enter_camera_fov_start, 122.0, pull)
	_camera.look_at(goal_pos + Vector3(0.0, sin(t * TAU * 5.0) * 0.08, 0.0), Vector3.UP)
	_camera.rotate_object_local(Vector3.FORWARD, sin(t * TAU * 7.0) * 0.035 * pull)
	_viewport_container.scale = Vector2.ONE


func _goal_observe_move_multiplier() -> float:
	if not _goal_observe_active:
		return 1.0
	var t := clampf(_goal_observe_timer / GOAL_OBSERVE_SECONDS, 0.0, 1.0)
	var brake := 1.0 - smoothstep(0.0, 0.22, t)
	return brake * 0.14


func _update_floor_reconstruction(delta: float) -> void:
	var reveal_distance := FLOOR_INITIAL_REVEAL_DISTANCE if _startup_time < FLOOR_INITIAL_REVEAL_SEC else FLOOR_RUNNING_REVEAL_DISTANCE
	var reveal_z := _camera.position.z - reveal_distance
	for i in range(_floor_blocks.size()):
		var data := _floor_blocks[i] as Dictionary
		var center := data["center"] as Vector3
		if bool(data["spawn_started"]) and float(data["spawn_progress"]) >= 1.0 and center.z > _camera.position.z + 18.0:
			continue
		if not bool(data["spawn_started"]) and center.z >= reveal_z:
			var reveal_t := clampf((_camera.position.z - center.z) / maxf(1.0, reveal_distance), 0.0, 1.0)
			if _startup_time < FLOOR_INITIAL_REVEAL_SEC:
				reveal_t = clampf((18.0 - center.z) / FLOOR_INITIAL_REVEAL_DISTANCE, 0.0, 1.0)
			data["spawn_started"] = true
			data["spawn_time"] = _startup_time + reveal_t * (1.15 if _startup_time < FLOOR_INITIAL_REVEAL_SEC else 0.34) + _rng.randf_range(0.0, 0.22)
		if bool(data["spawn_started"]) and _startup_time >= float(data["spawn_time"]):
			var progress := float(data["spawn_progress"])
			progress = minf(1.0, progress + delta / FLOOR_SPAWN_DURATION)
			data["spawn_progress"] = progress
		_apply_floor_spawn_state(data)
		_floor_blocks[i] = data


func _apply_floor_spawn_state(data: Dictionary) -> void:
	var progress := float(data["spawn_progress"])
	var visible := progress > 0.001
	var eased := _floor_spawn_ease(progress)
	var offset := Vector3.DOWN * (FLOOR_SPAWN_DEPTH * (1.0 - eased))
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
	if block_id < 0 or block_id >= _floor_blocks.size():
		return 0.0
	var data := _floor_blocks[block_id] as Dictionary
	return -FLOOR_SPAWN_DEPTH * (1.0 - _floor_spawn_ease(float(data["spawn_progress"])))


func _floor_block_spawn_alpha(block_id: int) -> float:
	if block_id < 0 or block_id >= _floor_blocks.size():
		return 1.0
	return smoothstep(0.0, 0.18, float((_floor_blocks[block_id] as Dictionary)["spawn_progress"]))


func _update_lamps() -> void:
	var row_delay := startup_sec / maxf(1.0, float(_lamp_rows.size()))
	for i in range(_lamp_rows.size()):
		var row := _lamp_rows[i]
		var row_z := float(row["z"])
		if row_z > _camera.position.z + LAMP_UPDATE_BEHIND_DISTANCE or row_z < _camera.position.z - LAMP_UPDATE_AHEAD_DISTANCE:
			var inactive_light := row["light"] as OmniLight3D
			inactive_light.light_energy = 0.0
			for inactive_mat in row["materials"] as Array:
				(inactive_mat as StandardMaterial3D).emission_energy_multiplier = 0.0
			continue
		var local := clampf((_startup_time - float(i) * row_delay) / 0.18, 0.0, 1.0)
		var pulse := 1.0 + (1.0 - local) * 2.6
		var energy := smoothstep(0.0, 1.0, local) * pulse
		for mat in row["materials"] as Array:
			(mat as StandardMaterial3D).emission_energy_multiplier = energy * 1.7
		var light := row["light"] as OmniLight3D
		light.light_energy = energy * 0.24
	for data in _grazing_lights:
		var row_index := int(data["row_index"])
		var light := data["light"] as SpotLight3D
		var light_z := light.position.z
		if light_z > _camera.position.z + LAMP_UPDATE_BEHIND_DISTANCE or light_z < _camera.position.z - LAMP_UPDATE_AHEAD_DISTANCE:
			light.light_energy = 0.0
			continue
		var local := clampf((_startup_time - float(row_index) * row_delay) / 0.22, 0.0, 1.0)
		var energy := smoothstep(0.0, 1.0, local)
		light.light_energy = energy * 5.8
	if not _startup_complete_audio_played and _startup_time >= startup_sec:
		_startup_complete_audio_played = true


func _update_goal_glitch() -> void:
	_update_goal_form_cycle(get_process_delta_time())
	return
	var delta := get_process_delta_time()
	_glitch_timer -= delta
	if _variant_time_left > 0.0:
		_variant_time_left -= delta
		if _variant_time_left <= 0.0:
			_set_goal_variant(-1)
		return
	if _glitch_timer <= 0.0:
		_glitch_timer = _rng.randf_range(2.2, 4.8)
		_set_goal_variant(_rng.randi_range(0, _variant_forms.size() - 1))
		_variant_time_left = _rng.randf_range(1.0, 1.22)
	_goal_root.rotation.y += delta * 0.35
	_goal_root.rotation.x = sin(Time.get_ticks_msec() * 0.0019) * 0.045
	_update_goal_outline_energy()


func _update_goal_form_cycle(delta: float) -> void:
	if _variant_forms.is_empty():
		return
	if _entering_goal:
		delta *= 9.0
	_goal_root.rotation.y += delta * 0.28
	_goal_root.rotation.x = sin(Time.get_ticks_msec() * 0.0019) * 0.035
	if _goal_is_flickering:
		_goal_flicker_time += delta
		var flicker_rate := 72.0 if _entering_goal else 32.0
		var flicker_index := (_goal_next_form_index + int(_goal_flicker_time * flicker_rate)) % _variant_forms.size()
		_set_goal_variant(flicker_index)
		_apply_goal_form_integrity(flicker_index, _rng.randf_range(0.0, 0.32), true)
		_goal_root.position.x += _rng.randf_range(-0.018, 0.018)
		_goal_root.position.y += _rng.randf_range(-0.012, 0.012)
		if _goal_flicker_time >= _goal_flicker_duration:
			_goal_is_flickering = false
			_goal_form_index = _goal_next_form_index
			_goal_next_form_index = (_goal_form_index + 1) % _variant_forms.size()
			_goal_cycle_time = 0.0
			_goal_cycle_duration = _rng.randf_range(0.38, 0.72) if _entering_goal else _rng.randf_range(4.8, 7.2)
			_set_goal_variant(_goal_form_index)
			_apply_goal_form_integrity(_goal_form_index, 1.0, false)
		_update_goal_outline_energy()
		return
	_goal_cycle_time += delta
	var t := clampf(_goal_cycle_time / maxf(0.001, _goal_cycle_duration), 0.0, 1.0)
	var integrity := 1.0 - smoothstep(0.12, 1.0, t)
	_set_goal_variant(_goal_form_index)
	_apply_goal_form_integrity(_goal_form_index, integrity, false)
	if _goal_cycle_time >= _goal_cycle_duration:
		_start_goal_flicker()
	_update_goal_outline_energy()


func _start_goal_flicker() -> void:
	_goal_is_flickering = true
	_goal_flicker_time = 0.0
	_goal_flicker_duration = _rng.randf_range(0.075, 0.14) if _entering_goal else _rng.randf_range(0.34, 0.56)
	_goal_next_form_index = (_goal_form_index + _rng.randi_range(1, GOAL_FORM_COUNT - 1)) % GOAL_FORM_COUNT


func _apply_goal_form_integrity(form_index: int, integrity: float, violent: bool) -> void:
	if form_index < 0 or form_index >= _goal_form_pieces.size():
		return
	var damage := 1.0 - clampf(integrity, 0.0, 1.0)
	for piece_data in _goal_form_pieces[form_index]:
		var piece := (piece_data as Dictionary)["node"] as Node3D
		var base := (piece_data as Dictionary)["base"] as Transform3D
		var broken := (piece_data as Dictionary)["broken"] as Transform3D
		var phase := float((piece_data as Dictionary)["phase"])
		var local_damage := clampf(damage + sin(Time.get_ticks_msec() * 0.0018 + phase) * 0.05, 0.0, 1.0)
		if violent:
			local_damage = _rng.randf_range(0.35, 1.0)
		var interp := _transform_lerp(base, broken, smoothstep(0.0, 1.0, local_damage))
		piece.transform = interp
		piece.visible = not (local_damage > 0.82 and sin(phase * 9.1 + _goal_cycle_time * 5.0) > 0.62)
	_apply_outline_energy(_variant_forms[form_index], lerpf(0.48, 1.25, damage) if not violent else 1.35)


func _transform_lerp(a: Transform3D, b: Transform3D, t: float) -> Transform3D:
	var basis := a.basis.slerp(b.basis, t)
	var origin := a.origin.lerp(b.origin, t)
	return Transform3D(basis, origin)


func _update_goal_chase(delta: float) -> void:
	_update_goal_chase_discrete(delta)
	return
	if _goal_root == null:
		return
	_goal_escape_cooldown = maxf(0.0, _goal_escape_cooldown - delta)
	if not _goal_escape_started and _startup_time >= FLOOR_INITIAL_REVEAL_SEC:
		_goal_escape_started = true
		_goal_target_z = GOAL_FIRST_ESCAPE_Z
		_show_subtitle("归于完整。", 2.1, Vector2(0.54, 0.28))
		_set_goal_variant(_rng.randi_range(0, _variant_forms.size() - 1))
		_variant_time_left = 1.1
	if _goal_escape_started and not _reached_goal:
		var desired_z := maxf(goal_z, _camera.position.z - GOAL_CHASE_DISTANCE)
		_goal_target_z = minf(_goal_target_z, desired_z)
		var distance := _camera.position.z - _goal_root.position.z
		if distance < GOAL_ESCAPE_TRIGGER_DISTANCE and _move_progress < 0.93 and _goal_escape_cooldown <= 0.0:
			_goal_target_z = maxf(goal_z, _goal_root.position.z - _rng.randf_range(42.0, 66.0))
			_next_goal_escape_progress = minf(0.94, _move_progress + _rng.randf_range(0.16, 0.24))
			_goal_escape_cooldown = 4.5
			_show_subtitle(_subtitle_messages[_rng.randi_range(0, _subtitle_messages.size() - 1)], 2.0, _subtitle_anchor_near_goal())
			_set_goal_variant(_rng.randi_range(0, _variant_forms.size() - 1))
			_variant_time_left = 1.05
		if _move_progress >= _next_goal_escape_progress and _move_progress < 0.93:
			_goal_target_z = maxf(goal_z, _camera.position.z - _rng.randf_range(60.0, 78.0))
			_next_goal_escape_progress = minf(0.94, _move_progress + _rng.randf_range(0.16, 0.23))
	if _move_progress >= 0.94:
		_goal_target_z = goal_z
	var speed := 24.0 if _goal_escape_started else 7.0
	if absf(_goal_root.position.z - _goal_target_z) > 6.0:
		speed = 58.0
	_goal_root.position.z = move_toward(_goal_root.position.z, _goal_target_z, speed * delta)


func _update_goal_chase_discrete(delta: float) -> void:
	if _goal_root == null:
		return
	if _entering_goal:
		return
	_goal_escape_cooldown = maxf(0.0, _goal_escape_cooldown - delta)
	if _goal_observe_active:
		_update_goal_observe_lock(delta)
		return
	if not _goal_escape_started and _startup_time >= FLOOR_INITIAL_REVEAL_SEC:
		_goal_escape_started = true
		_goal_escape_in_progress = true
		_goal_target_z = GOAL_FIRST_ESCAPE_Z
		_goal_target_x = _next_goal_escape_x(1.8, 3.8)
		_goal_target_y = _rng.randf_range(2.4, 4.9)
		_capture_goal_trail(_goal_root.position.z, _goal_target_z)
		_show_subtitle(_next_subtitle_text(), 6.4, Vector2(0.54, 0.28))
		_start_goal_flicker()
	if _goal_escape_started and not _reached_goal:
		var distance := _camera.position.z - _goal_root.position.z
		if not _goal_escape_in_progress and distance < GOAL_OBSERVE_TRIGGER_DISTANCE and _move_progress < 0.93 and _goal_escape_cooldown <= 0.0:
			_start_goal_observe_lock()
			return
	if _move_progress >= 0.94:
		_goal_target_z = goal_z
		_goal_target_x = 0.0
		_goal_target_y = 3.1
		_goal_escape_in_progress = true
	var speed := 8.0
	if _goal_escape_in_progress:
		speed = 92.0
	_goal_root.position.x = move_toward(_goal_root.position.x, _goal_target_x, speed * 0.18 * delta)
	_goal_root.position.y = move_toward(_goal_root.position.y, _goal_target_y, speed * 0.13 * delta)
	_goal_root.position.z = move_toward(_goal_root.position.z, _goal_target_z, speed * delta)
	if absf(_goal_root.position.z - _goal_target_z) <= 0.35 and absf(_goal_root.position.x - _goal_target_x) <= 0.12:
		_goal_escape_in_progress = false


func _start_goal_observe_lock() -> void:
	_goal_observe_active = true
	_goal_observe_timer = 0.0
	_goal_particle_accum = 0.0
	_goal_escape_cooldown = GOAL_OBSERVE_SECONDS + 1.2
	_start_goal_flicker()


func _next_goal_escape_x(min_abs: float, max_abs: float) -> float:
	_goal_escape_side *= -1
	return float(_goal_escape_side) * _rng.randf_range(min_abs, max_abs)


func _update_goal_observe_lock(delta: float) -> void:
	_goal_observe_timer += delta
	_update_goal_silver_particles(delta)
	if _goal_observe_timer >= GOAL_OBSERVE_SECONDS:
		_finish_goal_observe_lock()


func _finish_goal_observe_lock() -> void:
	_goal_observe_active = false
	_clear_goal_particles()
	var previous_z := _goal_root.position.z
	_goal_target_z = maxf(goal_z, _goal_root.position.z - _rng.randf_range(82.0, 118.0))
	_goal_target_x = _next_goal_escape_x(2.4, 5.4)
	_goal_target_y = _rng.randf_range(2.25, 5.35)
	_goal_escape_in_progress = true
	_goal_escape_cooldown = 3.8
	_capture_goal_trail(previous_z, _goal_target_z)
	_show_subtitle(_next_subtitle_text(), 6.8, _subtitle_anchor_near_goal())
	_start_goal_flicker()


func _update_goal_silver_particles(delta: float) -> void:
	var t := clampf(_goal_observe_timer / GOAL_OBSERVE_SECONDS, 0.0, 1.0)
	var spawn_rate := lerpf(10.0, 110.0, smoothstep(0.08, 0.96, t))
	_goal_particle_accum += spawn_rate * delta
	while _goal_particle_accum >= 1.0 and _goal_particles.size() < GOAL_PARTICLE_CAP:
		_goal_particle_accum -= 1.0
		_spawn_goal_silver_particle(t)
	for i in range(_goal_particles.size() - 1, -1, -1):
		var data := _goal_particles[i] as Dictionary
		var node := data["node"] as MeshInstance3D
		if node == null or not is_instance_valid(node):
			_goal_particles.remove_at(i)
			continue
		var age := float(data["age"]) + delta
		var life := float(data["life"])
		if age >= life:
			node.queue_free()
			_goal_particles.remove_at(i)
			continue
		var velocity := data["velocity"] as Vector3
		velocity = velocity.move_toward(Vector3.UP * 0.18, delta * 1.65)
		node.position += velocity * delta
		var fade := 1.0 - smoothstep(life * 0.44, life, age)
		var scale_value := float(data["scale"]) * fade
		node.scale = Vector3.ONE * maxf(0.01, scale_value)
		var material := node.material_override as StandardMaterial3D
		if material != null:
			material.albedo_color = Color(0.86, 0.93, 1.0, 0.82 * fade)
			material.emission_energy_multiplier = lerpf(2.6, 0.25, age / life)
		data["age"] = age
		data["velocity"] = velocity
		_goal_particles[i] = data


func _spawn_goal_silver_particle(lock_t: float) -> void:
	if _goal_particle_mesh == null or _goal_particle_material == null:
		return
	var particle := MeshInstance3D.new()
	particle.name = "GoalSilverParticle"
	particle.mesh = _goal_particle_mesh
	particle.material_override = _goal_particle_material.duplicate()
	var angle := _rng.randf_range(0.0, TAU)
	var radius := _rng.randf_range(1.2, 2.85)
	var height := _rng.randf_range(-0.85, 1.1)
	particle.position = _goal_root.position + Vector3(cos(angle) * radius, height, sin(angle) * radius)
	_world_root.add_child(particle)
	var outward := Vector3(cos(angle), _rng.randf_range(0.55, 1.45), sin(angle)).normalized()
	var speed := _rng.randf_range(0.9, 2.2) * lerpf(0.8, 1.55, lock_t)
	_goal_particles.append({
		"node": particle,
		"age": 0.0,
		"life": _rng.randf_range(0.9, 1.75),
		"velocity": outward * speed + Vector3.UP * _rng.randf_range(0.55, 1.35),
		"scale": _rng.randf_range(0.7, 1.8),
	})


func _clear_goal_particles() -> void:
	for data in _goal_particles:
		var node := (data as Dictionary)["node"] as MeshInstance3D
		if node != null and is_instance_valid(node):
			node.queue_free()
	_goal_particles.clear()
	_goal_particle_accum = 0.0


func _capture_goal_trail(from_z: float, to_z: float) -> void:
	if _camera == null or _viewport_container == null or _sub_viewport == null:
		_has_goal_trail = false
		return
	var from_world := Vector3(_goal_root.position.x, _goal_root.position.y, from_z)
	var to_world := Vector3(_goal_root.position.x, _goal_root.position.y, to_z)
	var rect := _viewport_container.get_global_rect()
	var vp_size := Vector2(_sub_viewport.size)
	var from_projected := _camera.unproject_position(from_world)
	var to_projected := _camera.unproject_position(to_world)
	_last_goal_trail_start = rect.position + Vector2(from_projected.x / maxf(1.0, vp_size.x) * rect.size.x, from_projected.y / maxf(1.0, vp_size.y) * rect.size.y)
	_last_goal_trail_end = rect.position + Vector2(to_projected.x / maxf(1.0, vp_size.x) * rect.size.x, to_projected.y / maxf(1.0, vp_size.y) * rect.size.y)
	_has_goal_trail = true


func _set_goal_variant(index: int) -> void:
	_active_variant_index = index
	_sphere_form.visible = index < 0
	for i in range(_variant_forms.size()):
		_variant_forms[i].visible = i == index
	_update_goal_outline_energy()


func _update_goal_outline_energy() -> void:
	var glitch_energy := 0.48 if _active_variant_index < 0 else 0.95
	_apply_outline_energy(_sphere_form, glitch_energy)
	for i in range(_variant_forms.size()):
		_apply_outline_energy(_variant_forms[i], 1.05 if i == _active_variant_index else 0.48)


func _apply_outline_energy(root: Node, energy: float) -> void:
	if root == null:
		return
	for child in root.get_children():
		if child is MeshInstance3D and child.name == "WhiteOutline":
			var mat := (child as MeshInstance3D).material_override as StandardMaterial3D
			if mat != null:
				mat.emission_energy_multiplier = energy
		_apply_outline_energy(child, energy)


func _seed_circuit_paths() -> void:
	_circuit_paths.clear()
	for block in _floor_blocks:
		_seed_block_circuit_tracks(block)
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
	var side_mains := _rng.randi_range(3, 5)
	var side_main_nodes: Array[Array] = []
	for side_index in range(side_mains):
		var face := "left" if side_index % 2 == 0 else "right"
		var nodes := _make_side_through_track(center, half, top_y, bottom_y, face)
		side_main_nodes.append(nodes)
		_add_circuit_track(nodes, block_id)
	for _i in range(_rng.randi_range(2, 5)):
		_add_circuit_track(_make_side_branch_track(center, half, top_y, bottom_y, side_main_nodes), block_id)


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


func _add_circuit_track(nodes: Array[Dictionary], block_id: int = -1) -> void:
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
		"width": _rng.randf_range(CIRCUIT_RIBBON_WIDTH * 0.72, CIRCUIT_RIBBON_WIDTH * 1.22),
		"block_id": block_id,
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
	return {
		"pos": Vector3(center.x + clampf(u, -half.x, half.x), top_y + offset, center.z + clampf(v, -half.y, half.y)),
		"normal": Vector3.UP,
	}


func _track_pos(node: Variant) -> Vector3:
	return (node as Dictionary)["pos"] as Vector3


func _track_normal(node: Variant) -> Vector3:
	return ((node as Dictionary)["normal"] as Vector3).normalized()


func _surface_state_point(center: Vector3, half: Vector2, top_y: float, bottom_y: float, face: String, u: float, v: float, side_y: float) -> Vector3:
	var offset := 0.046
	match face:
		"left":
			return Vector3(center.x - half.x - offset, clampf(side_y, bottom_y + 0.12, top_y - 0.04), center.z + clampf(v, -half.y, half.y))
		"right":
			return Vector3(center.x + half.x + offset, clampf(side_y, bottom_y + 0.12, top_y - 0.04), center.z + clampf(v, -half.y, half.y))
	return Vector3(center.x + clampf(u, -half.x, half.x), top_y + offset, center.z + clampf(v, -half.y, half.y))


func _surface_point(center: Vector3, half: Vector2, top_y: float, bottom_y: float, face: String, u: float, v: float) -> Vector3:
	var offset := 0.038
	match face:
		"top":
			return Vector3(center.x + clampf(u, -half.x, half.x), top_y + offset, center.z + clampf(v, -half.y, half.y))
		"left":
			return Vector3(center.x - half.x - offset, clampf(_surface_vertical_from_v(face, v, top_y, bottom_y), bottom_y, top_y), center.z + clampf(v, -half.y, half.y))
		"right":
			return Vector3(center.x + half.x + offset, clampf(_surface_vertical_from_v(face, v, top_y, bottom_y), bottom_y, top_y), center.z + clampf(v, -half.y, half.y))
		"front":
			return Vector3(center.x + clampf(u, -half.x, half.x), clampf(_surface_vertical_from_v(face, v, top_y, bottom_y), bottom_y, top_y), center.z - half.y - offset)
		"back":
			return Vector3(center.x + clampf(u, -half.x, half.x), clampf(_surface_vertical_from_v(face, v, top_y, bottom_y), bottom_y, top_y), center.z + half.y + offset)
	return Vector3(center.x, top_y + offset, center.z)


func _surface_vertical_from_v(face: String, v: float, top_y: float, bottom_y: float) -> float:
	if face == "top":
		return top_y
	var t := clampf((v + 1.0) * 0.5, 0.0, 1.0)
	return lerpf(bottom_y + 0.08, top_y - 0.03, t)


func _surface_v_from_vertical(_face: String, y: float, top_y: float, bottom_y: float, half: Vector2) -> float:
	var t := inverse_lerp(bottom_y + 0.08, top_y - 0.03, y)
	return lerpf(-half.y, half.y, clampf(t, 0.0, 1.0))


func _update_circuits(delta: float) -> void:
	_circuit_spawn_timer -= delta
	var target_active := clampi(circuit_active_min, 0, maxi(circuit_active_min, circuit_active_max))
	while _circuit_events.size() < target_active:
		_spawn_circuit_wave()
	if _circuit_spawn_timer <= 0.0 and _circuit_events.size() < circuit_active_max:
		_circuit_spawn_timer = _rng.randf_range(circuit_event_interval_min, circuit_event_interval_max)
		_spawn_circuit_wave()
	for i in range(_circuit_events.size() - 1, -1, -1):
		var wave := _circuit_events[i] as Dictionary
		wave["z"] = float(wave["z"]) - float(wave["speed"]) * delta
		wave["age"] = float(wave["age"]) + delta
		_circuit_events[i] = wave
		if float(wave["z"]) < goal_z - 18.0:
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
		track["charge"] = clampf(charge, 0.0, 1.0)
		_circuit_paths[i] = track
	_draw_circuit_events()


func _update_subtitles(delta: float) -> void:
	_update_subtitles_particles_entry(delta)
	return


func _update_subtitles_particles_entry(delta: float) -> void:
	if _subtitle_root == null:
		return
	if not _subtitle_active:
		if not _subtitle_missing_shown and _startup_time > 0.55:
			_subtitle_missing_shown = true
			_show_subtitle(_next_subtitle_text(), 6.2, Vector2(0.30, 0.68))
			return
		if _goal_escape_started and not _transition_started:
			_subtitle_next_random -= delta
			if _subtitle_next_random <= 0.0:
				_subtitle_next_random = _rng.randf_range(10.0, 16.0)
				_show_subtitle(_next_subtitle_text(), _rng.randf_range(6.3, 7.4), _random_subtitle_anchor())
		return
	_update_subtitle_particles(delta)
	return
	if not _subtitle_active:
		if not _subtitle_missing_shown and _startup_time > 0.55:
			_subtitle_missing_shown = true
			_show_subtitle("缺失之物。", 1.8, Vector2(0.30, 0.68))
			return
		if not _subtitle_intro_shown and _startup_time > 1.95:
			_subtitle_intro_shown = true
			_show_subtitle("球记得它的碎片。", 2.0, _subtitle_anchor_near_goal())
			return
		if _goal_escape_started and not _transition_started:
			_subtitle_next_random -= delta
			if _subtitle_next_random <= 0.0:
				_subtitle_next_random = _rng.randf_range(9.5, 16.0)
				_show_subtitle(_subtitle_messages[_rng.randi_range(0, _subtitle_messages.size() - 1)], _rng.randf_range(1.65, 2.35), _random_subtitle_anchor())
		return
	_subtitle_timer += delta
	var t := _subtitle_timer / maxf(0.001, _subtitle_life)
	if t >= 1.0:
		_subtitle_active = false
		_subtitle_label.visible = false
		_subtitle_shadow.visible = false
		return
	var preflash := t < 0.16
	var breaking := t > 0.78
	var alpha := 0.0
	if preflash:
		alpha = 0.86 if int(_subtitle_timer * 34.0) % 2 == 0 else 0.18
	elif breaking:
		alpha = (1.0 - smoothstep(0.78, 1.0, t)) * (0.85 if int(_subtitle_timer * 28.0) % 2 == 0 else 0.36)
	else:
		alpha = 0.92
	var jitter := Vector2(_rng.randf_range(-2.0, 2.0), _rng.randf_range(-0.8, 0.8)) if (preflash or breaking) else Vector2.ZERO
	_subtitle_label.position = _subtitle_base_position + jitter
	_subtitle_shadow.position = _subtitle_label.position + Vector2(2.0, 2.0)
	_subtitle_label.add_theme_color_override("font_color", Color(0.82, 0.88, 0.92, alpha))
	_subtitle_shadow.add_theme_color_override("font_color", Color(0.03, 0.05, 0.08, alpha * 0.52))
	if _subtitle_material != null:
		var glitch := 0.46 if preflash else (0.34 if breaking else 0.075)
		_subtitle_material.set_shader_parameter("glitch_amount", glitch)
		_subtitle_material.set_shader_parameter("slice_strength", glitch * 1.2)
		_subtitle_material.set_shader_parameter("dropout_strength", glitch * 0.45)
		_subtitle_material.set_shader_parameter("rgb_split", glitch * 0.42)
		_subtitle_material.set_shader_parameter("scan_strength", 0.22)
		_subtitle_material.set_shader_parameter("alpha", alpha)


func _show_subtitle(text_value: String, life: float, anchor: Vector2) -> void:
	_show_subtitle_particles(text_value, life, anchor)
	return
	if _subtitle_label == null:
		return
	_subtitle_active = true
	_subtitle_timer = 0.0
	_subtitle_life = life
	_subtitle_label.text = text_value
	_subtitle_shadow.text = text_value
	_subtitle_label.visible = true
	_subtitle_shadow.visible = true
	var pos := Vector2(size.x * anchor.x, size.y * anchor.y) - _subtitle_label.size * 0.5
	pos.x = clampf(pos.x, 24.0, maxf(24.0, size.x - _subtitle_label.size.x - 24.0))
	pos.y = clampf(pos.y, 36.0, maxf(36.0, size.y - _subtitle_label.size.y - 36.0))
	_subtitle_label.position = pos
	_subtitle_shadow.position = pos + Vector2(2.0, 2.0)
	_subtitle_base_position = pos


func _show_subtitle_particles(text_value: String, life: float, anchor: Vector2) -> void:
	if _subtitle_root == null:
		return
	_clear_subtitle_particles()
	_subtitle_active = true
	_subtitle_timer = 0.0
	_subtitle_life = life
	var chars := _string_to_chars(text_value)
	var emphasis_ranges := _subtitle_emphasis_ranges(text_value)
	var spacing := 48.0
	var target_offsets: Array[float] = []
	var cursor := 0.0
	for i in range(chars.size()):
		var emphasized := _is_subtitle_index_emphasized(i, emphasis_ranges)
		target_offsets.append(cursor)
		var next_emphasized := _is_subtitle_index_emphasized(i + 1, emphasis_ranges)
		var extra_spacing := 34.0 if emphasized or next_emphasized else 0.0
		cursor += spacing + extra_spacing
	var total_width := maxf(1.0, cursor - spacing)
	var base := Vector2(size.x * anchor.x, size.y * anchor.y) - Vector2(total_width * 0.5, 0.0)
	base.x = clampf(base.x, 32.0, maxf(32.0, size.x - total_width - 32.0))
	base.y = clampf(base.y, 44.0, maxf(44.0, size.y - 92.0))
	for i in range(chars.size()):
		var emphasized := _is_subtitle_index_emphasized(i, emphasis_ranges)
		var target := base + Vector2(target_offsets[i], 0.0)
		var start := _subtitle_start_position(i, chars.size(), target)
		var exit := target + Vector2(_rng.randf_range(-80.0, 80.0), _rng.randf_range(-58.0, 58.0))
		var shadow := _make_subtitle_char(chars[i], true)
		var label := _make_subtitle_char(chars[i], false)
		_subtitle_root.add_child(shadow)
		_subtitle_root.add_child(label)
		_subtitle_particles.append({
			"label": label,
			"shadow": shadow,
			"start": start,
			"target": target,
			"exit": exit,
			"rot_start": deg_to_rad(_rng.randf_range(-30.0, 30.0)),
			"rot_target": deg_to_rad(_rng.randf_range(-7.0, 7.0)),
			"rot_exit": deg_to_rad(_rng.randf_range(-30.0, 30.0)),
			"scale_start": _rng.randf_range(1.8, 4.2) if emphasized else _rng.randf_range(0.65, 3.35),
			"scale_target": _rng.randf_range(1.9, 2.85) if emphasized else _rng.randf_range(0.78, 1.12),
			"scale_exit": _rng.randf_range(1.2, 3.6) if emphasized else _rng.randf_range(0.28, 2.1),
			"delay": float(i) * 0.035 + _rng.randf_range(0.0, 0.08),
			"seed": _rng.randf_range(0.0, TAU),
			"emphasis": emphasized,
		})


func _subtitle_start_position(index: int, count: int, fallback: Vector2) -> Vector2:
	if _has_goal_trail:
		var t := float(index) / maxf(1.0, float(count - 1))
		var along := _last_goal_trail_start.lerp(_last_goal_trail_end, t)
		return along + Vector2(_rng.randf_range(-60.0, 60.0), _rng.randf_range(-34.0, 34.0))
	return fallback + Vector2(_rng.randf_range(-180.0, 180.0), _rng.randf_range(-120.0, 120.0))


func _update_subtitle_particles(delta: float) -> void:
	_subtitle_timer += delta
	var t := _subtitle_timer / maxf(0.001, _subtitle_life)
	if t >= 1.0:
		_subtitle_active = false
		_clear_subtitle_particles()
		return
	for particle in _subtitle_particles:
		var delay := float((particle as Dictionary)["delay"])
		var local := clampf((_subtitle_timer - delay) / maxf(0.001, _subtitle_life - delay), 0.0, 1.0)
		var assemble := clampf(local / 0.34, 0.0, 1.0)
		var break_t := smoothstep(0.78, 1.0, local)
		var label := (particle as Dictionary)["label"] as Label
		var shadow := (particle as Dictionary)["shadow"] as Label
		var emphasized := bool((particle as Dictionary)["emphasis"])
		var target := (particle as Dictionary)["target"] as Vector2
		var start := (particle as Dictionary)["start"] as Vector2
		var exit := (particle as Dictionary)["exit"] as Vector2
		var pos := start.lerp(target, _ease_out_cubic(assemble)).lerp(exit, break_t)
		var rot := lerpf(float((particle as Dictionary)["rot_start"]), float((particle as Dictionary)["rot_target"]), _ease_out_cubic(assemble))
		rot = lerpf(rot, float((particle as Dictionary)["rot_exit"]), break_t)
		var scale_value := lerpf(float((particle as Dictionary)["scale_start"]), float((particle as Dictionary)["scale_target"]), _ease_out_cubic(assemble))
		scale_value = lerpf(scale_value, float((particle as Dictionary)["scale_exit"]), break_t)
		var alpha := smoothstep(0.0, 0.22, local) * (1.0 - smoothstep(0.82, 1.0, local))
		if int((_subtitle_timer + float((particle as Dictionary)["seed"])) * 18.0) % 11 == 0:
			pos.x += _rng.randf_range(-4.0, 4.0)
			alpha *= 0.55
		if emphasized and local > 0.22 and local < 0.82:
			var tremor := 1.0 + sin(_subtitle_timer * 31.0 + float((particle as Dictionary)["seed"])) * 0.035
			scale_value *= tremor
			rot += sin(_subtitle_timer * 24.0 + float((particle as Dictionary)["seed"])) * 0.018
			pos += Vector2(_rng.randf_range(-2.2, 2.2), _rng.randf_range(-1.5, 1.5))
		label.position = pos
		label.rotation = rot
		label.scale = Vector2.ONE * scale_value
		label.add_theme_color_override("font_color", Color(1.0, 0.05, 0.10, alpha * 0.96) if emphasized else Color(0.84, 0.90, 0.94, alpha))
		label.add_theme_color_override("font_outline_color", Color(0.22, 0.0, 0.02, 0.94) if emphasized else Color(0.04, 0.08, 0.13, 0.88))
		label.add_theme_constant_override("outline_size", 2 if emphasized else 1)
		shadow.position = pos + Vector2(2.0, 2.0)
		shadow.rotation = rot
		shadow.scale = Vector2.ONE * scale_value
		shadow.add_theme_color_override("font_color", Color(0.20, 0.0, 0.02, alpha * 0.62) if emphasized else Color(0.02, 0.04, 0.07, alpha * 0.55))


func _make_subtitle_char(text_value: String, shadow: bool) -> Label:
	var label := Label.new()
	label.text = text_value
	label.size = Vector2(58.0, 72.0)
	label.pivot_offset = Vector2(29.0, 36.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 40)
	label.add_theme_color_override("font_color", Color(0.02, 0.04, 0.07, 0.0) if shadow else Color(0.84, 0.90, 0.94, 0.0))
	label.add_theme_color_override("font_outline_color", Color(0.04, 0.08, 0.13, 0.88))
	label.add_theme_constant_override("outline_size", 1)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _clear_subtitle_particles() -> void:
	for particle in _subtitle_particles:
		var label := (particle as Dictionary)["label"] as Label
		var shadow := (particle as Dictionary)["shadow"] as Label
		if label != null and is_instance_valid(label):
			label.queue_free()
		if shadow != null and is_instance_valid(shadow):
			shadow.queue_free()
	_subtitle_particles.clear()


func _string_to_chars(value: String) -> Array[String]:
	var chars: Array[String] = []
	for i in range(value.length()):
		chars.append(value.substr(i, 1))
	return chars


func _subtitle_emphasis_ranges(value: String) -> Array[Vector2i]:
	var keywords: Array[String] = ["缺失", "碎片", "太久", "尸体", "完整", "残躯"]
	var ranges: Array[Vector2i] = []
	for keyword in keywords:
		var start := value.find(keyword)
		if start >= 0:
			ranges.append(Vector2i(start, start + keyword.length()))
	return ranges


func _is_subtitle_index_emphasized(index: int, ranges: Array[Vector2i]) -> bool:
	for range_value in ranges:
		if index >= range_value.x and index < range_value.y:
			return true
	return false


func _subtitle_text(index: int) -> String:
	match index:
		0:
			return "缺失之物。"
		1:
			return "球记得它的碎片。"
		2:
			return "你已经沉溺于此太久了。"
		3:
			return "你不记得水里的尸体。"
		4:
			return "归于完整。"
	return "拼装它的残躯。"


func _next_subtitle_text() -> String:
	var text_value := _subtitle_text(_subtitle_sequence_index)
	_subtitle_sequence_index = (_subtitle_sequence_index + 1) % 6
	return text_value


func _ease_out_cubic(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	return 1.0 - pow(1.0 - t, 3.0)


func _random_subtitle_anchor() -> Vector2:
	var anchors := [
		Vector2(0.24, 0.32),
		Vector2(0.72, 0.36),
		Vector2(0.50, 0.22),
		Vector2(0.50, 0.72),
		Vector2(0.30, 0.62),
	]
	return anchors[_rng.randi_range(0, anchors.size() - 1)]


func _subtitle_anchor_near_goal() -> Vector2:
	var p := _goal_screen_position()
	return Vector2(clampf(p.x / maxf(1.0, size.x), 0.18, 0.82), clampf(p.y / maxf(1.0, size.y), 0.18, 0.72))


func _spawn_circuit_wave() -> void:
	_circuit_events.append({
		"z": 18.0 + _rng.randf_range(0.0, 10.0),
		"speed": _rng.randf_range(44.0, 68.0),
		"width": _rng.randf_range(7.0, 15.0),
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
		var alpha := CIRCUIT_BASE_ALPHA + charge * 0.78
		if alpha < 0.018:
			continue
		var flicker := 0.90 + 0.10 * sin(now * 18.0 + float((track as Dictionary)["seed"]))
		var color := Color(
			lerpf(0.42, 1.0, charge),
			lerpf(0.21, 0.78, charge),
			lerpf(0.045, 0.20, charge),
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


func _update_starfield() -> void:
	return


func _build_ui() -> void:
	_black_overlay = ColorRect.new()
	_black_overlay.color = Color.BLACK
	_black_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_black_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_black_overlay)

	_white_overlay = ColorRect.new()
	_white_overlay.color = Color(1.0, 1.0, 1.0, 0.0)
	_white_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_white_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_white_overlay)

	_subtitle_shadow = _make_subtitle_label()
	_subtitle_shadow.add_theme_color_override("font_color", Color(0.08, 0.12, 0.16, 0.0))
	_subtitle_shadow.position = Vector2(2.0, 2.0)
	add_child(_subtitle_shadow)

	_subtitle_label = _make_subtitle_label()
	_subtitle_material = ShaderMaterial.new()
	_subtitle_material.shader = GLITCH_SHADER
	_subtitle_label.material = _subtitle_material
	add_child(_subtitle_label)

	_subtitle_root = Control.new()
	_subtitle_root.name = "AssembledSubtitleParticles"
	_subtitle_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_subtitle_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_subtitle_root)

	_w_hint = _make_hint_label("W")
	_w_hint.position = Vector2(26.0, 0.0)
	add_child(_w_hint)

	_lmb_hint = _make_hint_label("LMB")
	_lmb_hint.visible = false
	add_child(_lmb_hint)


func _make_subtitle_label() -> Label:
	var label := Label.new()
	label.visible = false
	label.text = ""
	label.add_theme_font_size_override("font_size", 27)
	label.add_theme_color_override("font_color", Color(0.82, 0.88, 0.92, 0.0))
	label.add_theme_color_override("font_outline_color", Color(0.06, 0.10, 0.16, 0.82))
	label.add_theme_constant_override("outline_size", 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.size = Vector2(460.0, 58.0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _make_starfield_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
render_mode unshaded;

uniform float time_phase = 0.0;
uniform float motion : hint_range(0.0, 1.0) = 0.0;
uniform vec2 focus = vec2(0.5, 0.45);
uniform float aspect = 1.7777778;

float hash(float n) {
	return fract(sin(n) * 43758.5453123);
}

float ray_event(vec2 uv, float id, float radius_scale, float motion_amount) {
	float angle = hash(id * 19.17) * 6.2831853;
	float radial_jitter = mix(0.04, 0.42, pow(hash(id * 7.31), 2.2));
	vec2 dir = vec2(cos(angle), sin(angle) * 0.62);
	vec2 from_focus = uv - focus;
	from_focus.x *= aspect;
	float along = dot(from_focus, dir);
	float side = abs(dot(from_focus, vec2(-dir.y, dir.x)));
	float cycle = fract(time_phase * mix(0.26, 0.72, motion_amount) + hash(id * 3.7));
	float burst = smoothstep(0.08, 0.18, cycle) * (1.0 - smoothstep(0.58, 1.0, cycle));
	float head = radial_jitter + cycle * mix(0.16, 1.18, motion_amount);
	float tail = mix(0.018, 0.28, motion_amount) * burst;
	float line_window = smoothstep(head - tail, head, along) * (1.0 - smoothstep(head, head + 0.035, along));
	float width = mix(0.0025, 0.008, hash(id * 13.1)) * mix(0.55, 1.0, motion_amount);
	float line = exp(-side * side / max(0.00001, width * width));
	float center_gate = smoothstep(0.00, 0.28, along) * (1.0 - smoothstep(1.28, 1.55, along));
	return line * line_window * burst * center_gate * radius_scale;
}

void fragment() {
	vec2 centered = UV - focus;
	centered.x *= aspect;
	float d = length(centered);
	float core = exp(-d * d / 0.010);
	float shimmer = 0.60 + 0.40 * sin(time_phase * 5.0 + d * 70.0);
	vec3 color = vec3(1.0, 0.78, 0.32) * core * shimmer * 0.16;
	float alpha = core * 0.12;

	for (int i = 0; i < 44; i++) {
		float id = float(i) + 1.0;
		float ray = ray_event(UV, id, mix(0.45, 1.0, hash(id * 5.9)), motion);
		vec3 ray_col = mix(vec3(0.70, 0.92, 1.0), vec3(1.0, 0.72, 0.25), hash(id * 11.4));
		color += ray_col * ray * mix(0.18, 1.55, motion);
		alpha += ray * mix(0.10, 0.82, motion);
	}

	float dust = step(0.9975, hash(floor(UV.x * 380.0) + floor(UV.y * 214.0) * 29.0 + floor(time_phase * 6.0)));
	color += vec3(0.95, 0.82, 0.52) * dust * (0.10 + motion * 0.18);
	alpha += dust * (0.08 + motion * 0.12);
	COLOR = vec4(color, clamp(alpha, 0.0, 0.88));
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	return material


func _make_hint_label(text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_override("font", QUANTICO_FONT)
	label.add_theme_font_size_override("font_size", 34)
	label.add_theme_color_override("font_color", Color(0.70, 0.78, 0.84, 0.72))
	label.add_theme_color_override("font_outline_color", Color(0.10, 0.18, 0.28, 0.72))
	label.add_theme_constant_override("outline_size", 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = Vector2(96.0, 44.0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = GLITCH_SHADER
	label.material = mat
	_hint_materials.append(mat)
	return label


func _update_ui() -> void:
	var ready := _startup_time >= startup_sec
	_w_hint.visible = ready and not _reached_goal and not _transition_started
	_w_hint.position.y = size.y * 0.68
	var w_active := Input.is_physical_key_pressed(KEY_W)
	_update_hint_material(_w_hint, 0, 0.12 if w_active else 0.22, 1.0 if w_active else 0.72)

	_lmb_hint.visible = _reached_goal and not _transition_started
	if _lmb_hint.visible:
		var goal_screen := _goal_screen_position()
		_lmb_hint.position = goal_screen + Vector2(-48.0, 62.0)
		var hovered := _is_click_near_goal(get_viewport().get_mouse_position())
		_update_hint_material(_lmb_hint, 1, 0.10 if hovered else 0.24, 1.0 if hovered else 0.74)


func _update_hint_material(label: Label, material_index: int, glitch: float, alpha: float) -> void:
	if material_index < 0 or material_index >= _hint_materials.size():
		return
	var mat := _hint_materials[material_index]
	mat.set_shader_parameter("glitch_amount", glitch)
	mat.set_shader_parameter("slice_strength", glitch)
	mat.set_shader_parameter("dropout_strength", glitch * 0.58)
	mat.set_shader_parameter("rgb_split", glitch * 0.55)
	mat.set_shader_parameter("scan_strength", 0.26)
	mat.set_shader_parameter("opacity", alpha)
	mat.set_shader_parameter("time_phase", Time.get_ticks_msec() * 0.001)
	label.add_theme_color_override("font_color", Color(0.86, 0.96, 1.0, 0.96) if alpha > 0.9 else Color(0.70, 0.78, 0.84, 0.72))


func _update_overlays() -> void:
	if _transition_started:
		return
	var startup_alpha := 1.0 - smoothstep(0.18, 1.0, clampf(_startup_time / startup_sec, 0.0, 1.0))
	_black_overlay.color.a = startup_alpha


func _goal_screen_position() -> Vector2:
	var p := _camera.unproject_position(_goal_root.global_position)
	var rect := _viewport_container.get_global_rect()
	var vp_size := Vector2(_sub_viewport.size)
	return rect.position + Vector2(p.x / maxf(1.0, vp_size.x) * rect.size.x, p.y / maxf(1.0, vp_size.y) * rect.size.y)


func _goal_screen_uv() -> Vector2:
	if _camera == null or _goal_root == null or _camera.is_position_behind(_goal_root.global_position):
		return Vector2(0.5, 0.45)
	var p := _camera.unproject_position(_goal_root.global_position)
	var vp_size := Vector2(_sub_viewport.size)
	return Vector2(
		clampf(p.x / maxf(1.0, vp_size.x), 0.0, 1.0),
		clampf(p.y / maxf(1.0, vp_size.y), 0.0, 1.0)
	)


func _is_click_near_goal(screen_pos: Vector2) -> bool:
	if _camera.is_position_behind(_goal_root.global_position):
		return false
	return screen_pos.distance_to(_goal_screen_position()) <= 76.0


func _run_exit_transition() -> void:
	_transition_started = true
	_entering_goal = true
	_enter_goal_timer = 0.0
	_enter_camera_start = _camera.position
	_enter_camera_fov_start = _camera.fov
	_goal_observe_active = false
	_goal_escape_in_progress = false
	_clear_goal_particles()
	_goal_cycle_duration = 0.42
	_start_goal_flicker()
	_w_hint.visible = false
	_lmb_hint.visible = false
	await get_tree().create_timer(GOAL_ENTER_SECONDS).timeout
	var flash := create_tween()
	flash.tween_property(_white_overlay, "color:a", 1.0, 0.52)
	flash.tween_property(_white_overlay, "color:a", 0.0, 0.18)
	await flash.finished
	var black := create_tween()
	black.tween_property(_black_overlay, "color:a", 1.0, 0.42)
	await black.finished
	intro_finished.emit()


func _build_audio() -> void:
	_ambient_player = _make_audio_player(OPENING_AUDIO, -20.0, true)
	_play_audio(_ambient_player, -21.0)


func _make_audio_player(stream: AudioStream, volume_db: float, loop: bool) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	if loop and player.stream is AudioStreamMP3:
		(player.stream as AudioStreamMP3).loop = true
	add_child(player)
	return player


func _play_audio(player: AudioStreamPlayer, volume_db: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	player.stop()
	player.volume_db = volume_db
	player.play()


func _on_resized() -> void:
	if _sub_viewport != null and _viewport_container != null and not _viewport_container.stretch:
		_sub_viewport.size = Vector2i(maxi(1, int(size.x)), maxi(1, int(size.y)))
