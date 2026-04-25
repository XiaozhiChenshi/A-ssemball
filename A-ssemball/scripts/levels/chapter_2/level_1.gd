extends Control
class_name LevelC2L1

signal chapter_completed(chapter_index: int)

@export var light_rotation_speed_deg: float = 0.0
@export var light_energy: float = 0.85
@export var chapter_index: int = 2
@export var complete_key: Key = KEY_ENTER
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
var _right_placeholder_root: Control
var _left_moire_overlay: ColorRect
var _right_moire_overlay: ColorRect
var _right_scene_root: Control
var _right_scene_cards: Array[Control] = []
var _right_scene_current_index: int = -1
var _right_scene_transition_tween: Tween
var _right_scene_transition_id: int = 0
var _right_scene_status_labels: Array[Label] = []
var _right_scene_completed: Array[bool] = []
var _right_scene_flash_overlay: ColorRect
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


func _ready() -> void:
	_validate_input_actions()
	set_left_sphere_gp(left_sphere_gp_m, left_sphere_gp_n)
	_setup_default_sphere_material()
	_setup_anchor_frame_cube()
	_setup_orbit_cubes()
	_setup_right_placeholder()
	_setup_moire_overlays()
	_setup_final_curtains()
	dir_light.light_energy = light_energy
	right_panel.clip_contents = true
	resized.connect(_on_layout_changed)
	left_3d.resized.connect(_on_layout_changed)
	chapter_1_split.dragged.connect(_on_chapter_1_split_dragged)
	_on_layout_changed()
	_ensure_chapter_hint_label()
	call_deferred("_sync_right_scene_with_rotation")


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

	if light_rotation_speed_deg == 0.0:
		return
	dir_light.rotate_y(deg_to_rad(light_rotation_speed_deg) * delta)


func _input(event: InputEvent) -> void:
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


func _unhandled_input(event: InputEvent) -> void:
	if _chapter_completed_once:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == complete_key:
		_chapter_completed_once = true
		get_viewport().set_input_as_handled()
		chapter_completed.emit(chapter_index)


func _setup_default_sphere_material() -> void:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode depth_draw_opaque, cull_back;

uniform vec4 base_color : source_color = vec4(0.46, 0.30, 0.18, 1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.76;
uniform float specular : hint_range(0.0, 1.0) = 0.16;
uniform float relief_strength : hint_range(0.0, 0.25) = 0.075;
uniform float emission_strength : hint_range(0.0, 1.0) = 0.18;
uniform float emission_pulse : hint_range(0.0, 1.0) = 0.08;

float hash(vec3 p) {
	return fract(sin(dot(p, vec3(12.9898, 78.233, 45.164))) * 43758.5453123);
}

float value_noise(vec3 p) {
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

float fbm(vec3 p) {
	float v = 0.0;
	float a = 0.5;
	float freq = 1.0;
	for (int i = 0; i < 5; i++) {
		v += value_noise(p * freq) * a;
		freq *= 2.03;
		a *= 0.5;
	}
	return v;
}

void vertex() {
	vec3 n = normalize(NORMAL);
	vec3 p = n * 3.4;
	float low = fbm(p + vec3(0.0, 0.0, TIME * 0.03));
	float high = fbm(p * 2.9 + vec3(7.3, 4.1, 2.8));
	float ridged = abs(high * 2.0 - 1.0);
	float terrain = low * 0.72 + ridged * 0.28;
	float signed_h = terrain * 2.0 - 1.0;
	VERTEX += n * signed_h * relief_strength;
}

void fragment() {
	vec3 n = normalize(NORMAL);
	float lat = n.y * 0.5 + 0.5;
	float bands = sin(UV.y * 24.0 + UV.x * 4.0) * 0.5 + 0.5;
	vec3 rock = base_color.rgb;
	vec3 bright = rock * vec3(1.15, 1.1, 1.06);
	vec3 dark = rock * vec3(0.66, 0.62, 0.58);
	vec3 albedo = mix(dark, bright, lat * 0.72 + bands * 0.28);

	float pulse = sin(TIME * 1.4) * 0.5 + 0.5;
	float fres = pow(1.0 - clamp(dot(n, normalize(VIEW)), 0.0, 1.0), 2.8);

	ALBEDO = albedo;
	ROUGHNESS = roughness;
	SPECULAR = specular;
	EMISSION = albedo * (emission_strength * (0.78 + pulse * emission_pulse)) + vec3(fres * emission_strength * 0.32);
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
		_orbit_root.add_child(pivot)

		var cube := MeshInstance3D.new()
		cube.name = "Cube"
		var box := BoxMesh.new()
		box.size = Vector3.ONE * maxf(0.1, orbit_cube_size)
		cube.mesh = box

		var mat := StandardMaterial3D.new()
		var cube_color := cfg.get("color", Color.WHITE) as Color
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = cube_color
		mat.roughness = 0.46
		mat.specular = 0.2
		mat.emission_enabled = true
		mat.emission = Color(cube_color.r, cube_color.g, cube_color.b, 1.0)
		mat.emission_energy_multiplier = 0.35
		cube.material_override = mat
		pivot.add_child(cube)

		var particles := GPUParticles3D.new()
		particles.name = "PulseParticles"
		particles.amount = 48
		particles.lifetime = 1.15
		particles.one_shot = false
		particles.emitting = true
		particles.explosiveness = 0.7
		particles.randomness = 0.85
		particles.speed_scale = 1.0
		particles.draw_pass_1 = SphereMesh.new()
		var particle_mesh := particles.draw_pass_1 as SphereMesh
		particle_mesh.radius = 0.018
		particle_mesh.height = 0.036

		var particle_mat := StandardMaterial3D.new()
		particle_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		particle_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		particle_mat.albedo_color = Color(cube_color.r, cube_color.g, cube_color.b, 0.68)
		particle_mat.emission_enabled = true
		particle_mat.emission = Color(cube_color.r, cube_color.g, cube_color.b, 1.0)
		particle_mat.emission_energy_multiplier = 1.35
		particles.material_override = particle_mat

		var proc := ParticleProcessMaterial.new()
		proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		proc.emission_sphere_radius = maxf(0.02, orbit_cube_size * 0.26)
		proc.initial_velocity_min = 0.2
		proc.initial_velocity_max = 1.35
		proc.scale_min = 0.28
		proc.scale_max = 0.8
		proc.gravity = Vector3(0.0, -0.06, 0.0)
		proc.direction = Vector3(0.0, 1.0, 0.0)
		proc.spread = 180.0
		particles.process_material = proc
		pivot.add_child(particles)

		_orbit_cube_entries.append(
			{
				"index": _orbit_cube_entries.size(),
				"pivot": pivot,
				"cube": cube,
				"particles": particles,
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
		if pivot == null or cube == null or particles == null:
			continue

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
		cube.rotate_x(delta * spin_speed * 0.77)
		cube.rotate_y(delta * spin_speed * 1.0)
		cube.rotate_z(delta * spin_speed * 0.63)

		var pulse := maxf(0.0, sin(TAU * (_orbit_time_sec / particle_period) + phase))
		particles.amount_ratio = 0.18 + pulse * 0.82
		particles.speed_scale = 0.7 + pulse * 1.25
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

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.04, 0.04, 0.04, 1.0)
	mat.roughness = 0.82
	mat.specular = 0.04
	mat.emission_enabled = true
	mat.emission = Color(0.05, 0.05, 0.05, 1.0)
	mat.emission_energy_multiplier = 0.08

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
	line_canvas.clear_lines()
	line_canvas.visible = false
	if _right_placeholder_root != null and is_instance_valid(_right_placeholder_root):
		return

	_right_placeholder_root = Control.new()
	_right_placeholder_root.name = "RightPlaceholder"
	_right_placeholder_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_right_placeholder_root.offset_left = 0.0
	_right_placeholder_root.offset_top = 0.0
	_right_placeholder_root.offset_right = 0.0
	_right_placeholder_root.offset_bottom = 0.0
	_right_placeholder_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right_panel.add_child(_right_placeholder_root)
	_right_placeholder_root.move_to_front()

	var bg := ColorRect.new()
	bg.name = "PlaceholderBg"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.offset_left = 0.0
	bg.offset_top = 0.0
	bg.offset_right = 0.0
	bg.offset_bottom = 0.0
	bg.color = Color(0.09, 0.08, 0.06, 1.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_right_placeholder_root.add_child(bg)

	var title := Label.new()
	title.name = "PlaceholderTitle"
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_left = 0.0
	title.offset_top = 18.0
	title.offset_right = 0.0
	title.offset_bottom = 58.0
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.text = "Chapter 2-1 场景占位（Scene 1~4）"
	title.add_theme_font_size_override("font_size", 22)
	title.modulate = Color(0.96, 0.93, 0.84, 1.0)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_right_placeholder_root.add_child(title)

	_right_scene_root = Control.new()
	_right_scene_root.name = "SceneStage"
	_right_scene_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_right_scene_root.offset_left = 26.0
	_right_scene_root.offset_top = 74.0
	_right_scene_root.offset_right = -26.0
	_right_scene_root.offset_bottom = -26.0
	_right_scene_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_right_placeholder_root.add_child(_right_scene_root)
	_right_scene_cards.clear()
	_right_scene_status_labels.clear()
	_right_scene_completed.clear()

	var scene_cards: Array[Dictionary] = [
		{"title": "场景1占位符", "color_name": "红色", "bg": Color(0.72, 0.20, 0.22, 1.0)},
		{"title": "场景2占位符", "color_name": "绿色", "bg": Color(0.25, 0.60, 0.27, 1.0)},
		{"title": "场景3占位符", "color_name": "蓝色", "bg": Color(0.20, 0.38, 0.72, 1.0)},
		{"title": "场景4占位符", "color_name": "紫色", "bg": Color(0.54, 0.34, 0.70, 1.0)},
	]
	for info in scene_cards:
		var panel := PanelContainer.new()
		panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		panel.offset_left = 0.0
		panel.offset_top = 0.0
		panel.offset_right = 0.0
		panel.offset_bottom = 0.0
		panel.custom_minimum_size = Vector2.ZERO
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := StyleBoxFlat.new()
		style.bg_color = info.get("bg", Color(0.3, 0.3, 0.3, 1.0)) as Color
		style.border_width_left = 3
		style.border_width_top = 3
		style.border_width_right = 3
		style.border_width_bottom = 3
		style.border_color = Color(1.0, 1.0, 1.0, 0.35)
		style.corner_radius_top_left = 12
		style.corner_radius_top_right = 12
		style.corner_radius_bottom_right = 12
		style.corner_radius_bottom_left = 12
		panel.add_theme_stylebox_override("panel", style)
		_right_scene_root.add_child(panel)

		var text := Label.new()
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.text = "%s\n（%s）" % [String(info.get("title", "")), String(info.get("color_name", ""))]
		text.add_theme_font_size_override("font_size", 34)
		text.modulate = Color(0.98, 0.98, 0.98, 1.0)
		text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text.set_anchors_preset(Control.PRESET_FULL_RECT)
		text.offset_left = 18.0
		text.offset_top = 18.0
		text.offset_right = -18.0
		text.offset_bottom = -18.0
		panel.add_child(text)

		var subtitle := Label.new()
		subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		subtitle.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		subtitle.text = "按 A / D 切换场景"
		subtitle.add_theme_font_size_override("font_size", 18)
		subtitle.modulate = Color(0.96, 0.96, 0.96, 0.82)
		subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		subtitle.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		subtitle.offset_left = 0.0
		subtitle.offset_top = -38.0
		subtitle.offset_right = 0.0
		subtitle.offset_bottom = -10.0
		panel.add_child(subtitle)

		var status := Label.new()
		status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		status.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		status.text = "未完成"
		status.add_theme_font_size_override("font_size", 18)
		status.modulate = Color(1.0, 1.0, 1.0, 0.88)
		status.mouse_filter = Control.MOUSE_FILTER_IGNORE
		status.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		status.offset_left = -170.0
		status.offset_top = 14.0
		status.offset_right = -14.0
		status.offset_bottom = 38.0
		panel.add_child(status)

		panel.visible = false
		panel.modulate.a = 0.0
		_right_scene_cards.append(panel)
		_right_scene_status_labels.append(status)
		_right_scene_completed.append(false)

	_right_scene_flash_overlay = ColorRect.new()
	_right_scene_flash_overlay.name = "SceneFlashOverlay"
	_right_scene_flash_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_right_scene_flash_overlay.offset_left = 0.0
	_right_scene_flash_overlay.offset_top = 0.0
	_right_scene_flash_overlay.offset_right = 0.0
	_right_scene_flash_overlay.offset_bottom = 0.0
	_right_scene_flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_right_scene_flash_overlay.color = Color(1.0, 1.0, 1.0, 0.0)
	_right_scene_root.add_child(_right_scene_flash_overlay)
	_right_scene_flash_overlay.move_to_front()

	_switch_right_scene(0, true)


func _setup_moire_overlays() -> void:
	_left_moire_overlay = _create_moire_overlay("LeftMoireOverlay")
	left_3d.add_child(_left_moire_overlay)
	_left_moire_overlay.move_to_front()

	_right_moire_overlay = _create_moire_overlay("RightMoireOverlay")
	right_panel.add_child(_right_moire_overlay)
	_right_moire_overlay.move_to_front()


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
	var idx := posmod(scene_index, _right_scene_status_labels.size())
	if idx < 0 or idx >= _right_scene_status_labels.size():
		return
	_right_scene_completed[idx] = true
	var status := _right_scene_status_labels[idx]
	if status != null:
		status.text = "已完成"
		status.modulate = Color(1.0, 0.95, 0.68, 1.0)
	if _are_all_right_scenes_completed():
		call_deferred("_start_final_close_transition")


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


func _is_rotation_input_blocked() -> bool:
	return Time.get_ticks_msec() < _rotation_input_block_until_ms


func _is_sphere_input_locked() -> bool:
	return _final_transition_running or _is_rotation_input_blocked() or _vertical_preview_phase != 0 or _is_anchor_occupied()


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
	if not InputMap.has_action("rotate_sphere_left"):
		push_warning("Missing input action: rotate_sphere_left. Configure it in Project Settings > Input Map.")
	if not InputMap.has_action("rotate_sphere_right"):
		push_warning("Missing input action: rotate_sphere_right. Configure it in Project Settings > Input Map.")


func _on_chapter_1_split_dragged(_offset: int) -> void:
	_enforce_chapter_1_constraints()


func _enforce_chapter_1_constraints() -> void:
	# Keep right side at least 50% of total width.
	var min_right_width := maxf(1.0, size.x * 0.5)
	right_panel.custom_minimum_size.x = min_right_width
	if chapter_1_split.split_offset > 0:
		chapter_1_split.split_offset = 0


func _setup_fixed_right_canvas() -> void:
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
	_chapter_hint_label.text = "Chapter 2-1 ready. Press Enter to continue."
	_chapter_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_chapter_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_chapter_hint_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_chapter_hint_label.offset_left = 0.0
	_chapter_hint_label.offset_right = 0.0
	_chapter_hint_label.offset_top = -40.0
	_chapter_hint_label.offset_bottom = -10.0
	_chapter_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_chapter_hint_label)
