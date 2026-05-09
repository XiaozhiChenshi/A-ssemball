extends Control
class_name IntroCorridorV2

signal intro_finished

const QUANTICO_FONT: FontFile = preload("res://assets/fonts/Quantico.ttf")
const GLITCH_SHADER: Shader = preload("res://shaders/input_hint_glitch.gdshader")
const OPENING_AUDIO: AudioStream = preload("res://assets/audio/初始界面 .mp3")
const ELECTRONIC_NOISE_AUDIO: AudioStream = preload("res://assets/audio/1.9.1电子杂音.mp3")
const SUCCESS_AUDIO: AudioStream = preload("res://assets/audio/1.9.2成功运行电子音.mp3")
const CLICK_SPHERE_AUDIO: AudioStream = preload("res://assets/audio/单击球面音效.mp3")
const SCREEN_SHAKE_AUDIO: AudioStream = preload("res://assets/audio/1.2屏幕震动.mp3")

@export var startup_sec: float = 2.15
@export var move_speed: float = 17.0
@export var corridor_length: float = 94.0
@export var goal_z: float = -72.0
@export var circuit_event_interval_min: float = 0.035
@export var circuit_event_interval_max: float = 0.095
@export var circuit_active_min: int = 10
@export var circuit_active_max: int = 20

var _viewport_container: SubViewportContainer
var _sub_viewport: SubViewport
var _world_root: Node3D
var _camera: Camera3D
var _goal_root: Node3D
var _sphere_form: Node3D
var _variant_forms: Array[Node3D] = []
var _lamp_rows: Array[Dictionary] = []
var _floor_blocks: Array[Dictionary] = []
var _floor_edge_mesh_instance: MeshInstance3D
var _floor_edge_mesh: ImmediateMesh
var _starfield_overlay: ColorRect
var _starfield_material: ShaderMaterial
var _circuit_mesh_instance: MeshInstance3D
var _circuit_mesh: ImmediateMesh
var _circuit_paths: Array[Dictionary] = []
var _circuit_events: Array[Dictionary] = []
var _circuit_spawn_timer: float = 0.0
var _black_overlay: ColorRect
var _white_overlay: ColorRect
var _w_hint: Label
var _lmb_hint: Label
var _hint_materials: Array[ShaderMaterial] = []
var _ambient_player: AudioStreamPlayer
var _noise_player: AudioStreamPlayer
var _success_player: AudioStreamPlayer
var _click_player: AudioStreamPlayer
var _shake_player: AudioStreamPlayer

var _rng := RandomNumberGenerator.new()
var _startup_time: float = 0.0
var _move_progress: float = 0.0
var _moving_weight: float = 0.0
var _reached_goal: bool = false
var _transition_started: bool = false
var _glitch_timer: float = 0.0
var _variant_time_left: float = 0.0
var _active_variant_index: int = -1
var _startup_complete_audio_played: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_rng.randomize()
	_build_scene()
	_build_ui()
	_build_audio()
	_seed_circuit_paths()
	resized.connect(_on_resized)
	_on_resized()


func _process(delta: float) -> void:
	_startup_time += delta
	var input_enabled := _startup_time >= startup_sec and not _transition_started
	var moving := input_enabled and not _reached_goal and Input.is_physical_key_pressed(KEY_W)
	_moving_weight = lerpf(_moving_weight, 1.0 if moving else 0.0, clampf(delta * 6.0, 0.0, 1.0))
	if moving:
		_move_progress = minf(1.0, _move_progress + (move_speed * delta / corridor_length))
		if _move_progress >= 1.0:
			_reached_goal = true
	_update_camera(delta)
	_update_lamps()
	_update_goal_glitch()
	_update_circuits(delta)
	_update_starfield()
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
	for player in [_ambient_player, _noise_player, _success_player, _click_player, _shake_player]:
		if player != null and is_instance_valid(player):
			player.stop()
	if _circuit_mesh != null:
		_circuit_mesh.clear_surfaces()


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
	env.background_color = Color(0.0, 0.0, 0.0, 1.0)
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
	_build_floor_edge_renderer()
	_build_circuit_renderer()


func _build_floor() -> void:
	var columns := 7
	var rows := 34
	for z_index in range(rows):
		for x_index in range(columns):
			var mesh := BoxMesh.new()
			var width := _rng.randf_range(2.05, 2.75)
			var depth := _rng.randf_range(2.25, 3.6)
			var height := _rng.randf_range(0.18, 0.86)
			mesh.size = Vector3(width, height, depth)
			var block := MeshInstance3D.new()
			block.name = "FloorBlock"
			block.mesh = mesh
			var material := _make_floor_material()
			block.material_override = material
			var x := (float(x_index) - float(columns - 1) * 0.5) * 2.58 + _rng.randf_range(-0.12, 0.12)
			var z := -float(z_index) * 3.05 + _rng.randf_range(-0.16, 0.16) + 10.0
			block.position = Vector3(x, -height * 0.5, z)
			_world_root.add_child(block)
			_floor_blocks.append({
				"z_index": z_index,
				"center": Vector3(x, 0.018, z),
				"half": Vector2(width * 0.5, depth * 0.5),
			})


func _make_floor_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode depth_draw_opaque;

uniform vec4 base_color : source_color = vec4(0.0015, 0.002, 0.003, 1.0);

void fragment() {
	ALBEDO = base_color.rgb;
	ROUGHNESS = 0.62;
	SPECULAR = 0.28;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	return material


func _build_lamps() -> void:
	var row_count := 26
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


func _build_goal() -> void:
	_goal_root = Node3D.new()
	_goal_root.name = "DistortedGoal"
	_goal_root.position = Vector3(0.0, 3.1, goal_z)
	_world_root.add_child(_goal_root)

	_sphere_form = Node3D.new()
	_sphere_form.name = "SphereForm"
	_goal_root.add_child(_sphere_form)
	_add_mesh_with_outline(_sphere_form, _make_goal_sphere_mesh(), Transform3D.IDENTITY, 1.0)

	_variant_forms.append(_build_cube_pyramid_form())
	_variant_forms.append(_build_split_sphere_form())
	_variant_forms.append(_build_shard_form())
	for form in _variant_forms:
		form.visible = false
		_goal_root.add_child(form)


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

uniform vec4 base_color : source_color = vec4(0.78, 0.90, 1.0, 1.0);
uniform float distortion = 0.08;

void vertex() {
	float n = sin(VERTEX.x * 4.1 + TIME * 5.2) * sin(VERTEX.y * 3.7 - TIME * 3.8) * cos(VERTEX.z * 3.3 + TIME * 4.6);
	VERTEX += NORMAL * n * distortion;
}

void fragment() {
	float fresnel = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 2.5);
	ALBEDO = base_color.rgb * 0.42;
	EMISSION = base_color.rgb * (0.35 + fresnel * 2.3);
	ROUGHNESS = 0.18;
	SPECULAR = 0.55;
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
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.72, 0.18, 1.0)
	mat.emission_energy_multiplier = 1.6
	_circuit_mesh_instance.material_override = mat
	_world_root.add_child(_circuit_mesh_instance)


func _build_floor_edge_renderer() -> void:
	_floor_edge_mesh = ImmediateMesh.new()
	_floor_edge_mesh_instance = MeshInstance3D.new()
	_floor_edge_mesh_instance.name = "FloorEdgeLines"
	_floor_edge_mesh_instance.mesh = _floor_edge_mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.no_depth_test = false
	mat.emission_enabled = true
	mat.emission = Color(0.34, 0.46, 0.58, 1.0)
	mat.emission_energy_multiplier = 0.7
	_floor_edge_mesh_instance.material_override = mat
	_world_root.add_child(_floor_edge_mesh_instance)


func _update_camera(delta: float) -> void:
	var target_z := lerpf(18.0, goal_z + 9.5, _move_progress)
	var bob := sin(Time.get_ticks_msec() * 0.0017) * 0.035 * _moving_weight
	_camera.position = Vector3(0.0, 4.2 + bob, target_z)
	_camera.fov = lerpf(64.0, 70.0, _moving_weight)
	_camera.look_at(Vector3(0.0, 3.0, goal_z), Vector3.UP)


func _update_lamps() -> void:
	var row_delay := startup_sec / maxf(1.0, float(_lamp_rows.size()))
	for i in range(_lamp_rows.size()):
		var row := _lamp_rows[i]
		var local := clampf((_startup_time - float(i) * row_delay) / 0.18, 0.0, 1.0)
		var pulse := 1.0 + (1.0 - local) * 2.6
		var energy := smoothstep(0.0, 1.0, local) * pulse
		for mat in row["materials"] as Array:
			(mat as StandardMaterial3D).emission_energy_multiplier = energy * 1.7
		var light := row["light"] as OmniLight3D
		light.light_energy = energy * 0.75
	_update_floor_edges(row_delay)
	if not _startup_complete_audio_played and _startup_time >= startup_sec:
		_startup_complete_audio_played = true
		_play_audio(_success_player, -8.0)


func _update_floor_edges(row_delay: float) -> void:
	if _floor_edge_mesh == null:
		return
	_floor_edge_mesh.clear_surfaces()
	var has_vertices := false
	_floor_edge_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for block in _floor_blocks:
		var z_index := int(block["z_index"])
		var center := block["center"] as Vector3
		var half := block["half"] as Vector2
		var lamp_index := clampi(int(round(float(z_index) * 26.0 / 34.0)), 0, maxi(0, _lamp_rows.size() - 1))
		var local := clampf((_startup_time - float(lamp_index) * row_delay) / 0.28, 0.0, 1.0)
		var reveal := smoothstep(0.0, 1.0, local)
		if reveal <= 0.001:
			continue
		var flash := maxf(0.0, 1.0 - local) * 0.28
		var alpha := clampf(0.13 * reveal + flash, 0.0, 0.36)
		var color := Color(0.20, 0.29, 0.38, alpha)
		var gold := Color(0.75, 0.48, 0.16, alpha * 0.55)
		var a := center + Vector3(-half.x, 0.0, -half.y)
		var b := center + Vector3(half.x, 0.0, -half.y)
		var c := center + Vector3(half.x, 0.0, half.y)
		var d := center + Vector3(-half.x, 0.0, half.y)
		_add_edge_line(a, b, color)
		_add_edge_line(b, c, gold)
		_add_edge_line(c, d, color)
		_add_edge_line(d, a, gold)
		has_vertices = true
	if has_vertices:
		_floor_edge_mesh.surface_end()
	else:
		_floor_edge_mesh.clear_surfaces()


func _add_edge_line(a: Vector3, b: Vector3, color: Color) -> void:
	_floor_edge_mesh.surface_set_color(color)
	_floor_edge_mesh.surface_add_vertex(a)
	_floor_edge_mesh.surface_set_color(Color(color.r, color.g, color.b, color.a * 0.72))
	_floor_edge_mesh.surface_add_vertex(b)


func _update_goal_glitch() -> void:
	var delta := get_process_delta_time()
	_glitch_timer -= delta
	if _variant_time_left > 0.0:
		_variant_time_left -= delta
		if _variant_time_left <= 0.0:
			_set_goal_variant(-1)
		return
	if _glitch_timer <= 0.0:
		_glitch_timer = _rng.randf_range(0.30, 0.82)
		_set_goal_variant(_rng.randi_range(0, _variant_forms.size() - 1))
		_variant_time_left = _rng.randf_range(1.0, 1.34)
		if _rng.randf() < 0.55:
			_play_audio(_noise_player, -17.0)
	_goal_root.rotation.y += delta * 0.35
	_goal_root.rotation.x = sin(Time.get_ticks_msec() * 0.0019) * 0.045
	_update_goal_outline_energy()


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
	var columns := 7
	var rows := 34
	for z_index in range(rows):
		if z_index % 2 != 0:
			continue
		for x_index in range(columns):
			if _rng.randf() > 0.38:
				continue
			var x := (float(x_index) - float(columns - 1) * 0.5) * 2.58
			var z := -float(z_index) * 3.05 + 10.0
			_circuit_paths.append(_make_circuit_path(Vector3(x, 0.032, z)))
	_circuit_spawn_timer = 0.2


func _make_circuit_path(origin: Vector3) -> Dictionary:
	var points: Array[Vector3] = [origin]
	var dir := Vector3(0.0, 0.0, -1.0)
	var p := origin
	var segment_count := _rng.randi_range(3, 6)
	for _i in range(segment_count):
		if _rng.randf() < 0.36:
			dir = Vector3(_rng.randf_range(-1.0, 1.0), 0.0, 0.0).normalized()
			if dir.length() < 0.1:
				dir = Vector3.RIGHT
		else:
			dir = Vector3(0.0, 0.0, -1.0)
		p += dir * _rng.randf_range(0.8, 1.85)
		points.append(p)
	var branches: Array[Array] = []
	for branch_index in range(_rng.randi_range(1, 2)):
		var anchor_index := _rng.randi_range(1, maxi(1, points.size() - 2))
		var branch: Array[Vector3] = [points[anchor_index]]
		var bp := points[anchor_index]
		var side := -1.0 if branch_index % 2 == 0 else 1.0
		for _j in range(_rng.randi_range(2, 3)):
			bp += Vector3(side * _rng.randf_range(0.45, 1.15), 0.0, -_rng.randf_range(0.35, 1.0))
			branch.append(bp)
		branches.append(branch)
	return {
		"main": points,
		"branches": branches,
	}


func _update_circuits(delta: float) -> void:
	_circuit_spawn_timer -= delta
	var target_active := clampi(circuit_active_min, 0, maxi(circuit_active_min, circuit_active_max))
	while _circuit_events.size() < target_active and not _circuit_paths.is_empty():
		_spawn_circuit_event()
	if _circuit_spawn_timer <= 0.0 and not _circuit_paths.is_empty() and _circuit_events.size() < circuit_active_max:
		_circuit_spawn_timer = _rng.randf_range(circuit_event_interval_min, circuit_event_interval_max)
		_spawn_circuit_event()
	for i in range(_circuit_events.size() - 1, -1, -1):
		_circuit_events[i]["age"] = float(_circuit_events[i]["age"]) + delta
		if float(_circuit_events[i]["age"]) > float(_circuit_events[i]["life"]):
			_circuit_events.remove_at(i)
	_draw_circuit_events()


func _spawn_circuit_event() -> void:
	_circuit_events.append({
		"path": _circuit_paths[_rng.randi_range(0, _circuit_paths.size() - 1)],
		"age": _rng.randf_range(0.0, 0.28),
		"speed": _rng.randf_range(4.8, 8.8),
		"life": _rng.randf_range(1.25, 2.1),
	})


func _draw_circuit_events() -> void:
	_circuit_mesh.clear_surfaces()
	var has_vertices := false
	_circuit_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for event in _circuit_events:
		var path := event["path"] as Dictionary
		var age := float(event["age"])
		var speed := float(event["speed"])
		var life := float(event["life"])
		var travel := age * speed
		var fade := 1.0 - smoothstep(life * 0.58, life, age)
		has_vertices = _draw_polyline_energy(path["main"] as Array, travel, fade, 0.0) or has_vertices
		var branches := path["branches"] as Array
		for branch in branches:
			has_vertices = _draw_polyline_energy(branch as Array, travel - 1.2, fade * 0.78, 0.0) or has_vertices
	if has_vertices:
		_circuit_mesh.surface_end()
	else:
		_circuit_mesh.clear_surfaces()


func _draw_polyline_energy(points: Array, travel: float, fade: float, y_offset: float) -> bool:
	if travel <= 0.0 or points.size() < 2:
		return false
	var drew := false
	var distance_accum := 0.0
	for i in range(points.size() - 1):
		var a := points[i] as Vector3
		var b := points[i + 1] as Vector3
		var length := a.distance_to(b)
		var local_head := travel - distance_accum
		var local_tail := local_head - 1.9
		if local_head > 0.0 and local_tail < length:
			var start_t := clampf(local_tail / maxf(0.001, length), 0.0, 1.0)
			var end_t := clampf(local_head / maxf(0.001, length), 0.0, 1.0)
			if end_t > start_t:
				var alpha := fade * smoothstep(0.0, 0.36, end_t) * (1.0 - start_t * 0.45)
				var head_color := Color(1.0, 0.86, 0.38, alpha)
				var tail_color := Color(0.95, 0.48, 0.10, alpha * 0.28)
				_circuit_mesh.surface_set_color(tail_color)
				_circuit_mesh.surface_add_vertex(a.lerp(b, start_t) + Vector3(0.0, y_offset, 0.0))
				_circuit_mesh.surface_set_color(head_color)
				_circuit_mesh.surface_add_vertex(a.lerp(b, end_t) + Vector3(0.0, y_offset, 0.0))
				drew = true
		distance_accum += length
	return drew


func _update_starfield() -> void:
	if _starfield_material == null:
		return
	_starfield_material.set_shader_parameter("time_phase", Time.get_ticks_msec() * 0.001)
	_starfield_material.set_shader_parameter("motion", _moving_weight)
	_starfield_material.set_shader_parameter("focus", _goal_screen_uv())
	_starfield_material.set_shader_parameter("aspect", size.x / maxf(1.0, size.y))


func _build_ui() -> void:
	_starfield_overlay = ColorRect.new()
	_starfield_overlay.name = "RelativisticStarfieldOverlay"
	_starfield_overlay.color = Color.WHITE
	_starfield_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_starfield_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_starfield_material = _make_starfield_material()
	_starfield_overlay.material = _starfield_material
	add_child(_starfield_overlay)

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

	_w_hint = _make_hint_label("W")
	_w_hint.position = Vector2(26.0, 0.0)
	add_child(_w_hint)

	_lmb_hint = _make_hint_label("LMB")
	_lmb_hint.visible = false
	add_child(_lmb_hint)


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
	_w_hint.visible = false
	_lmb_hint.visible = false
	_play_audio(_click_player, -5.0)
	var flash := create_tween()
	flash.tween_property(_white_overlay, "color:a", 1.0, 0.52)
	flash.tween_property(_white_overlay, "color:a", 0.0, 0.18)
	await flash.finished
	_play_audio(_shake_player, -12.0)
	var black := create_tween()
	black.tween_property(_black_overlay, "color:a", 1.0, 0.42)
	await black.finished
	intro_finished.emit()


func _build_audio() -> void:
	_ambient_player = _make_audio_player(OPENING_AUDIO, -20.0, true)
	_noise_player = _make_audio_player(ELECTRONIC_NOISE_AUDIO, -16.0, false)
	_success_player = _make_audio_player(SUCCESS_AUDIO, -8.0, false)
	_click_player = _make_audio_player(CLICK_SPHERE_AUDIO, -5.0, false)
	_shake_player = _make_audio_player(SCREEN_SHAKE_AUDIO, -12.0, false)
	_play_audio(_ambient_player, -21.0)
	_play_audio(_noise_player, -18.0)


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
