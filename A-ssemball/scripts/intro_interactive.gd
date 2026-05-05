extends Control
class_name IntroInteractive

signal intro_finished
signal goal_clicked

@export var hold_key: Key = KEY_W
@export var move_speed: float = 15
@export var move_speed_randomness: float = 0.06
@export var move_speed_randomize_hz: float = 1.2
@export var use_explicit_end_position: bool = false
@export var end_camera_position: Vector3 = Vector3.ZERO
@export var forward_distance: float = 100
@export var auto_finish_on_reach_end: bool = false
@export var walk_bob_hz: float = 0.36
@export var motion_intensity: float = 1.0
@export var fov_breath_enabled: bool = true
@export var fov_breath_hz: float = 0.12
@export var fov_breath_amp_idle: float = 0.45
@export var fov_breath_amp_moving: float = 0.25
@export var vignette_dynamic_enabled: bool = true
@export var vignette_radius_base: float = 0.58
@export var vignette_radius_breath_delta: float = 0.06
@export var enable_goal_click_transition: bool = true
@export var goal_progressive_scale_enabled: bool = true
@export var goal_scale_start: float = 0.22
@export var goal_scale_end: float = 1.0
@export var goal_scale_curve: float = 1.2
@export var board_1_trigger_progress: float = 0.2
@export var board_2_trigger_progress: float = 0.666
@export var board_hidden_offset_y: float = 8.0
@export var board_rise_speed: float = 7.0
@export var board_ground_y: float = 0.0
@export var board_ground_clearance: float = 0.4
@export var board_target_height_offset_y: float = 0.8
@export var shake_cycles: int = 3
@export var shake_duration_sec: float = 0.48
@export var shake_amplitude_px: float = 28.0
@export var shake_amplitude_randomness: float = 0.3
@export var shake_speed_randomness: float = 0.24
@export var goal_white_spread_duration_sec: float = 1.45
@export var goal_white_hold_sec: float = 0.16
@export var goal_spread_curve: float = 1.6
@export var goal_charge_start_frequency_hz: float = 0.6
@export var goal_charge_peak_frequency_hz: float = 8.8
@export var goal_charge_shake_offset_max: float = 0.9
@export var goal_charge_shake_rotation_deg_max: float = 26.0
@export var goal_collapse_duration_sec: float = 1.35
@export var goal_collapse_shake_start_frequency_hz: float = 5.0
@export var goal_collapse_shake_peak_frequency_hz: float = 18.0
@export var goal_collapse_shake_offset_start: float = 0.38
@export var goal_collapse_shake_offset_peak: float = 1.32
@export var goal_collapse_shake_rotation_deg_start: float = 12.0
@export var goal_collapse_shake_rotation_deg_peak: float = 42.0
@export var goal_vanish_scale_end: float = 0.04
@export var blackout_duration_sec: float = 0.9
@export var transition_line_width_px: float = 4.0
@export var line_rise_duration_sec: float = 0.62
@export var line_glow_duration_sec: float = 0.2
@export var line_fade_duration_sec: float = 0.26

const WALK_BOB_VERTICAL_BASE: float = 0.68
const WALK_BOB_HORIZONTAL_BASE: float = 0.42
const WALK_BOB_DEPTH_BASE: float = 0.22
const WALK_BOB_IMPACT_RATIO: float = 0.22
const WALK_BOB_IMPACT_SHARPNESS: float = 1.8
const WALK_BOB_SMOOTH: float = 9.0
const ROLL_STEP_DEG: float = 0.6
const ROLL_SMOOTH: float = 10.0
const ROLL_DECAY: float = 7.5
const MOTION_STATE_BLEND_SMOOTH: float = 6.5
const IDLE_DRIFT_HZ: float = 0.08
const IDLE_DRIFT_AMP_X: float = 0.045
const IDLE_DRIFT_AMP_Y: float = 0.028
const IDLE_DRIFT_AMP_Z: float = 0.02
const IDLE_DRIFT_SMOOTH: float = 3.2
const FOV_BREATH_SMOOTH: float = 3.8
const FOV_BREATH_EXPAND_RATIO: float = 0.62
const FOV_BREATH_EXPAND_CURVE: float = 1.8
const FOV_BREATH_CONTRACT_CURVE: float = 0.72
const VIGNETTE_RADIUS_SMOOTH: float = 4.0
const SCREEN_SHAKE_AUDIO: AudioStream = preload("res://assets/audio/1.2屏幕震动.mp3")

@onready var sub_viewport: SubViewport = $ViewportContainer/SubViewport
@onready var viewport_container: SubViewportContainer = $ViewportContainer
@onready var camera_3d: Camera3D = $ViewportContainer/SubViewport/WorldRoot/Camera3D
@onready var goal_sphere: MeshInstance3D = $ViewportContainer/SubViewport/WorldRoot/GoalSphere
@onready var material_board_1: MeshInstance3D = $ViewportContainer/SubViewport/WorldRoot/MaterialBoard1
@onready var material_board_2: MeshInstance3D = $ViewportContainer/SubViewport/WorldRoot/MaterialBoard2
@onready var hint: Label = $Hint
@onready var vignette_overlay: ColorRect = $VignetteOverlay

var _completed: bool = false
var _camera_start_position: Vector3 = Vector3.ZERO
var _camera_end_position: Vector3 = Vector3.ZERO
var _camera_progress_position: Vector3 = Vector3.ZERO
var _camera_motion_offset: Vector3 = Vector3.ZERO
var _idle_drift_offset: Vector3 = Vector3.ZERO
var _walk_motion_time: float = 0.0
var _step_impact: float = 0.0
var _step_foot_sign: float = 1.0
var _idle_drift_time: float = 0.0
var _moving_weight: float = 0.0
var _base_fov: float = 0.0
var _fov_breath_time: float = 0.0
var _fov_offset: float = 0.0
var _vignette_material: ShaderMaterial
var _vignette_radius_current: float = 0.58
var _base_camera_rotation: Vector3 = Vector3.ZERO
var _roll_z_current: float = 0.0
var _awaiting_goal_click: bool = false
var _transition_started: bool = false
var _viewport_base_position: Vector2 = Vector2.ZERO
var _transition_layer: Control
var _transition_scatter: ColorRect
var _transition_scatter_material: ShaderMaterial
var _transition_black: ColorRect
var _transition_line: ColorRect
var _transition_line_glow: ColorRect
var _move_speed_factor_current: float = 1.0
var _move_speed_factor_target: float = 1.0
var _move_speed_random_timer: float = 0.0
var _goal_base_scale: Vector3 = Vector3.ONE
var _goal_base_position: Vector3 = Vector3.ZERO
var _goal_base_rotation: Vector3 = Vector3.ZERO
var _goal_material: ShaderMaterial
var _goal_base_color: Color = Color(0.95, 0.95, 0.96, 1.0)
var _goal_base_fresnel_strength: float = 0.07
var _goal_vanish_start_position: Vector3 = Vector3.ZERO
var _goal_vanish_start_rotation: Vector3 = Vector3.ZERO
var _goal_vanish_start_scale: Vector3 = Vector3.ONE
var _goal_vanish_start_color: Color = Color(1.0, 1.0, 1.0, 1.0)
var _goal_transition_time: float = 0.0
var _board_1_target_y: float = 0.0
var _board_2_target_y: float = 0.0
var _board_1_triggered: bool = false
var _board_2_triggered: bool = false
var _screen_shake_audio_player: AudioStreamPlayer


func _ready() -> void:
	_camera_start_position = camera_3d.position
	_camera_progress_position = _camera_start_position
	_camera_end_position = _resolve_end_position()
	_base_fov = camera_3d.fov
	_base_camera_rotation = camera_3d.rotation
	_goal_base_scale = goal_sphere.scale
	_capture_goal_visual_baseline()
	_setup_material_boards()
	_vignette_material = vignette_overlay.material as ShaderMaterial
	_vignette_radius_current = vignette_radius_base
	_viewport_base_position = viewport_container.position
	randomize()
	_ensure_transition_nodes()
	_update_dynamic_vignette(0.0)
	resized.connect(_on_resized)
	_on_resized()
	_update_hint_text()
	_update_goal_sphere_scale()
	_ensure_audio_players()


func _process(delta: float) -> void:
	var is_moving := false
	if not _completed:
		is_moving = Input.is_physical_key_pressed(hold_key)
		if is_moving:
			_update_move_speed_factor(delta, true)
			var current_pos: Vector3 = _camera_progress_position
			var remaining: float = current_pos.distance_to(_camera_end_position)
			var step_speed := maxf(0.0, move_speed) * _move_speed_factor_current
			var step: float = maxf(0.0, step_speed) * delta

			if step >= remaining:
				_camera_progress_position = _camera_end_position
				_update_camera_motion(delta, false)
				_apply_camera_position()
				_on_reached_end()
			else:
				_camera_progress_position = current_pos.move_toward(_camera_end_position, step)
				_update_camera_motion(delta, true)
				_apply_camera_position()
		else:
			_update_move_speed_factor(delta, false)
			_update_camera_motion(delta, false)
			_apply_camera_position()
	else:
		_update_move_speed_factor(delta, false)
		_update_camera_motion(delta, false)
		_apply_camera_position()

	_update_motion_state_weight(delta, is_moving)
	_update_idle_drift(delta)
	_apply_camera_position()
	_update_breathing_fov(delta)
	_update_dynamic_vignette(delta)
	_update_camera_roll(delta)
	_update_goal_sphere_scale()
	_update_material_boards(delta)


func _input(event: InputEvent) -> void:
	if not _awaiting_goal_click or _transition_started:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos: Vector2 = event.position
		if _is_click_on_goal_sphere(mouse_pos):
			get_viewport().set_input_as_handled()
			await _start_goal_transition_sequence()


func _on_resized() -> void:
	if viewport_container == null:
		return
	if not viewport_container.stretch:
		sub_viewport.size = Vector2i(maxi(1, int(size.x)), maxi(1, int(size.y)))
	_layout_transition_nodes()


func _resolve_end_position() -> Vector3:
	if use_explicit_end_position:
		return end_camera_position

	var forward_dir: Vector3 = -camera_3d.global_transform.basis.z.normalized()
	return _camera_start_position + forward_dir * forward_distance


func _on_reached_end() -> void:
	_completed = true
	if enable_goal_click_transition:
		_awaiting_goal_click = true
		hint.text = "Left Click The White Sphere"
		return
	if auto_finish_on_reach_end:
		hint.text = "Loading..."
		intro_finished.emit()
	else:
		hint.text = "Reached End"


func _update_hint_text() -> void:
	if enable_goal_click_transition:
		hint.text = "Hold W To Move Forward"
		return
	if auto_finish_on_reach_end:
		hint.text = "Hold W To Move Forward"
	else:
		hint.text = "Hold W To Move Forward (No Auto Switch)"


func _update_goal_sphere_scale() -> void:
	if goal_sphere == null:
		return
	if _transition_started:
		return
	if not goal_progressive_scale_enabled:
		goal_sphere.scale = _goal_base_scale * maxf(0.001, goal_scale_end)
		return

	var total_distance := _camera_start_position.distance_to(_camera_end_position)
	var progress := 1.0
	if total_distance > 0.0001:
		var traveled := _camera_start_position.distance_to(_camera_progress_position)
		progress = clampf(traveled / total_distance, 0.0, 1.0)
	var curve := maxf(0.05, goal_scale_curve)
	var scaled_progress := pow(progress, curve)
	var current_scale := lerpf(goal_scale_start, goal_scale_end, scaled_progress)
	goal_sphere.scale = _goal_base_scale * maxf(0.001, current_scale)


func _setup_material_boards() -> void:
	if material_board_1 != null:
		_board_1_target_y = material_board_1.position.y + board_target_height_offset_y
		material_board_1.position.y = _compute_board_hidden_start_y(material_board_1, _board_1_target_y)
	if material_board_2 != null:
		_board_2_target_y = material_board_2.position.y + board_target_height_offset_y
		material_board_2.position.y = _compute_board_hidden_start_y(material_board_2, _board_2_target_y)


func _update_material_boards(delta: float) -> void:
	var progress := _get_forward_progress()
	if not _board_1_triggered and progress >= clampf(board_1_trigger_progress, 0.0, 1.0):
		_board_1_triggered = true
	if not _board_2_triggered and progress >= clampf(board_2_trigger_progress, 0.0, 1.0):
		_board_2_triggered = true

	var rise_step := maxf(0.0, board_rise_speed) * delta
	if material_board_1 != null and _board_1_triggered:
		material_board_1.position.y = move_toward(material_board_1.position.y, _board_1_target_y, rise_step)
	if material_board_2 != null and _board_2_triggered:
		material_board_2.position.y = move_toward(material_board_2.position.y, _board_2_target_y, rise_step)


func _get_forward_progress() -> float:
	var total_distance := _camera_start_position.distance_to(_camera_end_position)
	if total_distance <= 0.0001:
		return 1.0
	var traveled := _camera_start_position.distance_to(_camera_progress_position)
	return clampf(traveled / total_distance, 0.0, 1.0)


func _compute_board_hidden_start_y(board: MeshInstance3D, target_y: float) -> float:
	var half_height := _get_board_world_half_height(board)
	var full_below_floor_y := board_ground_y - half_height - maxf(0.0, board_ground_clearance)
	var offset_hidden_y := target_y - maxf(0.0, board_hidden_offset_y)
	return minf(full_below_floor_y, offset_hidden_y)


func _get_board_world_half_height(board: MeshInstance3D) -> float:
	if board == null or board.mesh == null:
		return 0.5
	var aabb := board.mesh.get_aabb()
	var local_half := maxf(0.001, aabb.size.y * 0.5)
	var world_scale := board.global_transform.basis.get_scale()
	var scale_y := maxf(0.001, absf(world_scale.y))
	return local_half * scale_y


func _update_move_speed_factor(delta: float, moving: bool) -> void:
	var rand_strength := clampf(move_speed_randomness, 0.0, 0.35)
	if not moving or rand_strength <= 0.001:
		_move_speed_factor_target = 1.0
		_move_speed_random_timer = 0.0
	else:
		_move_speed_random_timer -= delta
		if _move_speed_random_timer <= 0.0:
			var hz := maxf(0.2, move_speed_randomize_hz)
			var interval := (1.0 / hz) * randf_range(0.72, 1.28)
			_move_speed_random_timer = maxf(0.05, interval)
			_move_speed_factor_target = randf_range(1.0 - rand_strength, 1.0 + rand_strength)

	var smooth_t := clampf(4.2 * delta, 0.0, 1.0)
	_move_speed_factor_current = lerpf(_move_speed_factor_current, _move_speed_factor_target, smooth_t)


func _update_camera_motion(delta: float, moving: bool) -> void:
	var target: Vector3
	var smooth_t: float
	var intensity := maxf(0.0, motion_intensity)

	if moving:
		_walk_motion_time += delta

		var hz := maxf(0.1, walk_bob_hz)
		var step_progress := hz * _walk_motion_time
		var step_index := int(floor(step_progress))
		var cycle := fposmod(step_progress, 1.0)
		var impact_ratio := clampf(WALK_BOB_IMPACT_RATIO, 0.05, 0.8)
		var foot_sign := -1.0 if (step_index % 2 == 0) else 1.0

		# Fast downward impact + slower recovery to feel heavy.
		var impact_weight: float
		if cycle < impact_ratio:
			impact_weight = cycle / impact_ratio
		else:
			impact_weight = 1.0 - ((cycle - impact_ratio) / (1.0 - impact_ratio))
		impact_weight = pow(maxf(0.0, impact_weight), maxf(0.1, WALK_BOB_IMPACT_SHARPNESS))
		_step_impact = impact_weight
		_step_foot_sign = foot_sign

		var vertical := -WALK_BOB_VERTICAL_BASE * intensity * impact_weight
		# Alternate the impact side each step while keeping total cadence unchanged.
		var lateral := foot_sign * WALK_BOB_HORIZONTAL_BASE * intensity * impact_weight
		var depth := cos(TAU * cycle) * WALK_BOB_DEPTH_BASE * intensity
		target = Vector3(lateral, vertical, depth)
		smooth_t = clampf(WALK_BOB_SMOOTH * delta, 0.0, 1.0)
	else:
		_step_impact = lerpf(_step_impact, 0.0, clampf(WALK_BOB_SMOOTH * delta, 0.0, 1.0))
		target = Vector3.ZERO
		smooth_t = clampf(WALK_BOB_SMOOTH * delta, 0.0, 1.0)

	_camera_motion_offset = _camera_motion_offset.lerp(target, smooth_t)


func _apply_camera_position() -> void:
	camera_3d.position = _camera_progress_position + _camera_motion_offset + _idle_drift_offset


func _update_motion_state_weight(delta: float, is_moving: bool) -> void:
	var target := 1.0 if is_moving else 0.0
	var t := clampf(MOTION_STATE_BLEND_SMOOTH * delta, 0.0, 1.0)
	_moving_weight = lerpf(_moving_weight, target, t)


func _update_idle_drift(delta: float) -> void:
	var idle_weight := 1.0 - _moving_weight
	if idle_weight <= 0.001:
		_idle_drift_offset = _idle_drift_offset.lerp(Vector3.ZERO, clampf(IDLE_DRIFT_SMOOTH * delta, 0.0, 1.0))
		return

	_idle_drift_time += delta
	var hz := maxf(0.01, IDLE_DRIFT_HZ)
	var phase := TAU * hz * _idle_drift_time
	var intensity := maxf(0.0, motion_intensity)
	var target := Vector3(
		sin(phase * 0.61 + 0.8) * IDLE_DRIFT_AMP_X * intensity,
		sin(phase) * IDLE_DRIFT_AMP_Y * intensity,
		cos(phase * 0.47 + 1.3) * IDLE_DRIFT_AMP_Z * intensity
	) * idle_weight
	var t := clampf(IDLE_DRIFT_SMOOTH * delta, 0.0, 1.0)
	_idle_drift_offset = _idle_drift_offset.lerp(target, t)


func _update_breathing_fov(delta: float) -> void:
	if not fov_breath_enabled:
		camera_3d.fov = _base_fov
		return

	_fov_breath_time += delta
	var hz := maxf(0.05, fov_breath_hz)
	var amp := lerpf(fov_breath_amp_idle, fov_breath_amp_moving, _moving_weight)
	var cycle := fposmod(_fov_breath_time * hz, 1.0)
	var split := clampf(FOV_BREATH_EXPAND_RATIO, 0.05, 0.95)
	var wave := 0.0
	if cycle < split:
		var t_expand := cycle / split
		wave = -1.0 + 2.0 * pow(t_expand, maxf(0.05, FOV_BREATH_EXPAND_CURVE))
	else:
		var t_contract := (cycle - split) / (1.0 - split)
		wave = 1.0 - 2.0 * pow(t_contract, maxf(0.05, FOV_BREATH_CONTRACT_CURVE))

	var target_offset := wave * amp
	var smooth_t := clampf(FOV_BREATH_SMOOTH * delta, 0.0, 1.0)
	_fov_offset = lerpf(_fov_offset, target_offset, smooth_t)
	camera_3d.fov = _base_fov + _fov_offset


func _update_dynamic_vignette(delta: float) -> void:
	if _vignette_material == null:
		return
	if not vignette_dynamic_enabled:
		_vignette_material.set_shader_parameter("radius", vignette_radius_base)
		return

	var max_amp := maxf(0.001, maxf(fov_breath_amp_idle, fov_breath_amp_moving))
	var breath_ratio := clampf(_fov_offset / max_amp, -1.0, 1.0)
	var target_radius := vignette_radius_base - breath_ratio * vignette_radius_breath_delta
	var smooth_t := clampf(VIGNETTE_RADIUS_SMOOTH * delta, 0.0, 1.0)
	_vignette_radius_current = lerpf(_vignette_radius_current, target_radius, smooth_t)
	_vignette_material.set_shader_parameter("radius", _vignette_radius_current)


func _update_camera_roll(delta: float) -> void:
	if motion_intensity <= 0.0:
		_roll_z_current = 0.0
		camera_3d.rotation = _base_camera_rotation
		return

	var target_roll := deg_to_rad(ROLL_STEP_DEG) * motion_intensity * _step_impact * _step_foot_sign * _moving_weight
	var speed := lerpf(ROLL_DECAY, ROLL_SMOOTH, _moving_weight)
	var t := clampf(speed * delta, 0.0, 1.0)
	_roll_z_current = lerpf(_roll_z_current, target_roll, t)
	camera_3d.rotation = Vector3(
		_base_camera_rotation.x,
		_base_camera_rotation.y,
		_base_camera_rotation.z + _roll_z_current
	)


func _is_click_on_goal_sphere(screen_pos: Vector2) -> bool:
	if goal_sphere == null:
		return false
	var container_rect := viewport_container.get_global_rect()
	if not container_rect.has_point(screen_pos):
		return false
	if camera_3d.is_position_behind(goal_sphere.global_position):
		return false

	var sphere_center_world := goal_sphere.global_position
	var sphere_radius_world := _get_goal_sphere_world_radius()

	# 1) Screen-space hit test based on projected center/radius.
	var projected_center := camera_3d.unproject_position(sphere_center_world)
	var projected_edge := camera_3d.unproject_position(
		sphere_center_world + camera_3d.global_transform.basis.x.normalized() * sphere_radius_world
	)
	var projected_radius := projected_center.distance_to(projected_edge)
	if projected_radius > 0.0:
		var projected_center_screen := _subviewport_to_screen_position(projected_center, container_rect)
		var viewport_draw_rect := _get_subviewport_draw_rect(container_rect)
		var radius_scale := viewport_draw_rect.size.x / maxf(1.0, float(sub_viewport.size.x))
		var projected_radius_screen := maxf(8.0, projected_radius * radius_scale)
		if projected_center_screen.distance_to(screen_pos) <= projected_radius_screen * 1.35:
			return true

	# 2) Ray-sphere intersection fallback for robustness.
	var viewport_pos := _screen_to_subviewport_position(screen_pos, container_rect)
	var ray_origin := camera_3d.project_ray_origin(viewport_pos)
	var ray_dir := camera_3d.project_ray_normal(viewport_pos).normalized()
	return _ray_hits_sphere(ray_origin, ray_dir, sphere_center_world, sphere_radius_world)


func _screen_to_subviewport_position(screen_pos: Vector2, container_rect: Rect2) -> Vector2:
	var viewport_draw_rect := _get_subviewport_draw_rect(container_rect)
	var local := screen_pos - viewport_draw_rect.position
	var uv := Vector2(
		local.x / maxf(1.0, viewport_draw_rect.size.x),
		local.y / maxf(1.0, viewport_draw_rect.size.y)
	)
	uv.x = clampf(uv.x, 0.0, 1.0)
	uv.y = clampf(uv.y, 0.0, 1.0)
	return Vector2(
		uv.x * float(sub_viewport.size.x),
		uv.y * float(sub_viewport.size.y)
	)


func _subviewport_to_screen_position(subviewport_pos: Vector2, container_rect: Rect2) -> Vector2:
	var viewport_draw_rect := _get_subviewport_draw_rect(container_rect)
	var uv := Vector2(
		subviewport_pos.x / maxf(1.0, float(sub_viewport.size.x)),
		subviewport_pos.y / maxf(1.0, float(sub_viewport.size.y))
	)
	return Vector2(
		viewport_draw_rect.position.x + uv.x * viewport_draw_rect.size.x,
		viewport_draw_rect.position.y + uv.y * viewport_draw_rect.size.y
	)


func _get_subviewport_draw_rect(container_rect: Rect2) -> Rect2:
	var sub_size := Vector2(float(sub_viewport.size.x), float(sub_viewport.size.y))
	if sub_size.x <= 1.0 or sub_size.y <= 1.0:
		return container_rect
	var viewport_scale := minf(
		container_rect.size.x / maxf(1.0, sub_size.x),
		container_rect.size.y / maxf(1.0, sub_size.y)
	)
	if viewport_scale <= 0.0:
		return container_rect
	var draw_size := sub_size * viewport_scale
	var offset := (container_rect.size - draw_size) * 0.5
	return Rect2(container_rect.position + offset, draw_size)


func _get_goal_sphere_world_radius() -> float:
	var base_radius := 1.0
	if goal_sphere.mesh is SphereMesh:
		base_radius = (goal_sphere.mesh as SphereMesh).radius
	var s := goal_sphere.global_transform.basis.get_scale()
	var max_scale := maxf(absf(s.x), maxf(absf(s.y), absf(s.z)))
	return maxf(0.001, base_radius * max_scale)


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


func _start_goal_transition_sequence() -> void:
	if _transition_started:
		return
	_transition_started = true
	_awaiting_goal_click = false
	_play_screen_shake_audio_once()
	goal_clicked.emit()
	hint.visible = false
	await _run_goal_transition_sequence()


func start_post_goal_effect_from_menu() -> void:
	if _transition_started:
		return
	_completed = true
	_awaiting_goal_click = false
	_transition_started = true
	_play_screen_shake_audio_once()
	goal_clicked.emit()
	hint.visible = false
	_update_move_speed_factor(0.0, false)
	_update_camera_motion(0.0, false)
	_apply_camera_position()
	await _run_goal_transition_sequence()


func _run_goal_transition_sequence() -> void:
	_restore_goal_visual_baseline()
	await _play_goal_charge_and_whiteout()
	vignette_dynamic_enabled = false
	await _collapse_white_to_black_with_intense_shake()
	await _play_screen_shake()
	vignette_dynamic_enabled = false
	await _play_line_rise_and_glow()
	intro_finished.emit()


func _ensure_audio_players() -> void:
	if _screen_shake_audio_player != null and is_instance_valid(_screen_shake_audio_player):
		return
	_screen_shake_audio_player = AudioStreamPlayer.new()
	_screen_shake_audio_player.name = "ScreenShakeAudioPlayer"
	_screen_shake_audio_player.stream = SCREEN_SHAKE_AUDIO
	add_child(_screen_shake_audio_player)


func _play_screen_shake_audio_once() -> void:
	if _screen_shake_audio_player == null or not is_instance_valid(_screen_shake_audio_player):
		return
	_screen_shake_audio_player.stop()
	_screen_shake_audio_player.play()


func _play_goal_charge_and_whiteout() -> void:
	var duration := maxf(0.01, goal_white_spread_duration_sec)
	var elapsed := 0.0
	_goal_transition_time = 0.0
	while elapsed < duration:
		var raw_progress := clampf(elapsed / duration, 0.0, 1.0)
		var spread_progress := pow(raw_progress, maxf(0.1, goal_spread_curve))
		_apply_goal_charge_state(spread_progress)
		_update_scatter_overlay(spread_progress, 0.0, 1.0)
		await get_tree().process_frame
		var dt := get_process_delta_time()
		elapsed += dt
		_goal_transition_time += dt
	_apply_goal_charge_state(1.0)
	_update_scatter_overlay(1.0, 0.0, 1.0)

	var hold_duration := maxf(0.0, goal_white_hold_sec)
	if hold_duration <= 0.0:
		return
	var hold_elapsed := 0.0
	while hold_elapsed < hold_duration:
		_apply_goal_charge_state(1.0)
		_update_scatter_overlay(1.0, 0.0, 1.0)
		await get_tree().process_frame
		var dt_hold := get_process_delta_time()
		hold_elapsed += dt_hold
		_goal_transition_time += dt_hold


func _apply_goal_charge_state(progress: float) -> void:
	var p := clampf(progress, 0.0, 1.0)
	if goal_sphere != null:
		goal_sphere.visible = true
		var charge_freq := lerpf(
			goal_charge_start_frequency_hz,
			goal_charge_peak_frequency_hz,
			pow(p, 1.45)
		)
		var charge_phase := TAU * charge_freq * _goal_transition_time
		var charge_amp := goal_charge_shake_offset_max * (0.22 + pow(p, 1.55) * 0.78)
		var charge_rot_amp := goal_charge_shake_rotation_deg_max * (0.18 + pow(p, 1.45) * 0.82)
		goal_sphere.position = _goal_base_position + Vector3(
			sin(charge_phase * 1.08) * charge_amp + randf_range(-1.0, 1.0) * charge_amp * 0.16,
			cos(charge_phase * 0.93 + 0.4) * charge_amp * 0.76 + randf_range(-1.0, 1.0) * charge_amp * 0.14,
			sin(charge_phase * 1.33 + 1.2) * charge_amp * 0.52 + randf_range(-1.0, 1.0) * charge_amp * 0.12
		)
		goal_sphere.rotation = _goal_base_rotation + Vector3(
			deg_to_rad(cos(charge_phase * 1.14) * charge_rot_amp),
			deg_to_rad(sin(charge_phase * 0.89 + 0.3) * charge_rot_amp),
			deg_to_rad(sin(charge_phase * 1.28 + 1.0) * charge_rot_amp * 0.68)
		)
		goal_sphere.scale = _goal_base_scale * (1.0 + p * 0.28)

	_set_goal_glow_strength(p)


func _collapse_white_to_black_with_intense_shake() -> void:
	if goal_sphere != null:
		_goal_vanish_start_position = goal_sphere.position
		_goal_vanish_start_rotation = goal_sphere.rotation
		_goal_vanish_start_scale = goal_sphere.scale

	_goal_vanish_start_color = _goal_base_color
	if _goal_material != null:
		var current_color: Variant = _goal_material.get_shader_parameter("base_color")
		if current_color is Color:
			_goal_vanish_start_color = current_color

	var duration := maxf(0.01, maxf(goal_collapse_duration_sec, blackout_duration_sec))
	var elapsed := 0.0
	while elapsed < duration:
		var p := clampf(elapsed / duration, 0.0, 1.0)
		_apply_goal_collapse_state(p)
		_update_scatter_overlay(1.0, p, 1.0)
		if _transition_black != null:
			_transition_black.color.a = pow(p, 1.35)
		await get_tree().process_frame
		var dt := get_process_delta_time()
		elapsed += dt
		_goal_transition_time += dt
	_apply_goal_collapse_state(1.0)
	_update_scatter_overlay(1.0, 1.0, 0.0)
	if _transition_black != null:
		_transition_black.color.a = 1.0

	if goal_sphere != null:
		goal_sphere.visible = false
		goal_sphere.position = _goal_base_position
		goal_sphere.rotation = _goal_base_rotation
		goal_sphere.scale = _goal_base_scale * maxf(0.001, goal_vanish_scale_end)


func _apply_goal_collapse_state(progress: float) -> void:
	var p := clampf(progress, 0.0, 1.0)
	if goal_sphere != null:
		var collapse_freq := lerpf(
			goal_collapse_shake_start_frequency_hz,
			goal_collapse_shake_peak_frequency_hz,
			pow(p, 1.2)
		)
		var collapse_phase := TAU * collapse_freq * _goal_transition_time
		var collapse_amp := lerpf(
			goal_collapse_shake_offset_start,
			goal_collapse_shake_offset_peak,
			pow(p, 1.3)
		)
		var collapse_rot_amp := lerpf(
			goal_collapse_shake_rotation_deg_start,
			goal_collapse_shake_rotation_deg_peak,
			pow(p, 1.2)
		)
		var collapse_offset := Vector3(
			sin(collapse_phase * 1.09 + 0.2) * collapse_amp,
			cos(collapse_phase * 0.97 + 0.9) * collapse_amp * 0.74,
			sin(collapse_phase * 1.41 + 1.6) * collapse_amp * 0.46
		) + Vector3(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		) * (collapse_amp * 0.38)
		goal_sphere.position = _goal_base_position + collapse_offset
		goal_sphere.rotation = _goal_base_rotation + Vector3(
			deg_to_rad(cos(collapse_phase * 1.09) * collapse_rot_amp),
			deg_to_rad(sin(collapse_phase * 0.91 + 0.5) * collapse_rot_amp),
			deg_to_rad(sin(collapse_phase * 1.28 + 1.1) * collapse_rot_amp * 0.65)
		)
		var end_scale := _goal_base_scale * maxf(0.001, goal_vanish_scale_end)
		goal_sphere.scale = _goal_vanish_start_scale.lerp(end_scale, p)

	if _goal_material != null:
		var c := _goal_vanish_start_color
		c.a = lerpf(_goal_vanish_start_color.a, 0.0, p)
		_goal_material.set_shader_parameter("base_color", c)
		_goal_material.set_shader_parameter("fresnel_strength", lerpf(2.15, _goal_base_fresnel_strength, p))


func _set_goal_glow_strength(strength: float) -> void:
	var s := clampf(strength, 0.0, 1.0)
	if _goal_material != null:
		var c := Color(1.0, 1.0, 1.0, lerpf(_goal_base_color.a, 1.0, s * 0.85))
		_goal_material.set_shader_parameter("base_color", c)
		_goal_material.set_shader_parameter("fresnel_strength", lerpf(_goal_base_fresnel_strength, 2.2, s))


func _update_scatter_overlay(spread_progress: float, contract_progress: float, overlay_alpha: float) -> void:
	if _transition_scatter_material == null:
		return
	_transition_scatter_material.set_shader_parameter("spread_progress", clampf(spread_progress, 0.0, 1.0))
	_transition_scatter_material.set_shader_parameter("contract_progress", clampf(contract_progress, 0.0, 1.0))
	_transition_scatter_material.set_shader_parameter("overlay_alpha", clampf(overlay_alpha, 0.0, 1.0))
	_transition_scatter_material.set_shader_parameter("time_sec", _goal_transition_time)
	_transition_scatter_material.set_shader_parameter("collapse_center", _get_goal_screen_uv())


func _get_goal_screen_uv() -> Vector2:
	if goal_sphere == null:
		return Vector2(0.5, 0.5)
	if camera_3d.is_position_behind(goal_sphere.global_position):
		return Vector2(0.5, 0.5)
	var projected_center: Vector2 = camera_3d.unproject_position(goal_sphere.global_position)
	var container_rect := viewport_container.get_global_rect()
	var screen_center := _subviewport_to_screen_position(projected_center, container_rect)
	var self_rect := get_global_rect()
	var uv := Vector2(
		(screen_center.x - self_rect.position.x) / maxf(1.0, self_rect.size.x),
		(screen_center.y - self_rect.position.y) / maxf(1.0, self_rect.size.y)
	)
	uv.x = clampf(uv.x, 0.0, 1.0)
	uv.y = clampf(uv.y, 0.0, 1.0)
	return uv


func _capture_goal_visual_baseline() -> void:
	if goal_sphere == null:
		return
	_goal_base_position = goal_sphere.position
	_goal_base_rotation = goal_sphere.rotation
	_goal_base_scale = goal_sphere.scale
	_goal_material = goal_sphere.material_override as ShaderMaterial
	if _goal_material == null:
		return

	var base_color: Variant = _goal_material.get_shader_parameter("base_color")
	if base_color is Color:
		_goal_base_color = base_color
	var fresnel: Variant = _goal_material.get_shader_parameter("fresnel_strength")
	if fresnel is float:
		_goal_base_fresnel_strength = fresnel


func _restore_goal_visual_baseline() -> void:
	if goal_sphere != null:
		goal_sphere.visible = true
		goal_sphere.position = _goal_base_position
		goal_sphere.rotation = _goal_base_rotation
		goal_sphere.scale = _goal_base_scale
	if _goal_material != null:
		_goal_material.set_shader_parameter("base_color", _goal_base_color)
		_goal_material.set_shader_parameter("fresnel_strength", _goal_base_fresnel_strength)
	if _transition_scatter_material != null:
		_transition_scatter_material.set_shader_parameter("spread_progress", 0.0)
		_transition_scatter_material.set_shader_parameter("contract_progress", 0.0)
		_transition_scatter_material.set_shader_parameter("overlay_alpha", 0.0)
		_transition_scatter_material.set_shader_parameter("time_sec", 0.0)
		_transition_scatter_material.set_shader_parameter("collapse_center", Vector2(0.5, 0.5))
	if _transition_black != null:
		_transition_black.color = Color(0.0, 0.0, 0.0, 0.0)
	if _transition_line != null:
		_transition_line.color = Color(1.0, 1.0, 1.0, 0.0)
	if _transition_line_glow != null:
		_transition_line_glow.color = Color(1.0, 1.0, 1.0, 0.0)
	_goal_transition_time = 0.0


func _play_screen_shake() -> void:
	var total_cycles := maxi(1, shake_cycles)
	var half_steps := total_cycles * 2
	var amplitude_rand := clampf(shake_amplitude_randomness, 0.0, 0.95)
	var speed_rand := clampf(shake_speed_randomness, 0.0, 0.95)
	var duration_weights: Array[float] = []
	var total_weight := 0.0
	for i in range(half_steps + 1):
		var weight := randf_range(1.0 - speed_rand, 1.0 + speed_rand)
		duration_weights.append(weight)
		total_weight += weight
	var tween := create_tween()
	for i in range(half_steps):
		var dir := -1.0 if (i % 2 == 0) else 1.0
		var falloff := 1.0 - (float(i) / float(half_steps))
		var step_sec := maxf(0.01, shake_duration_sec * (duration_weights[i] / maxf(0.0001, total_weight)))
		var step_amp := shake_amplitude_px * falloff * randf_range(1.0 - amplitude_rand, 1.0 + amplitude_rand)
		var x := dir * step_amp
		var y := randf_range(-step_amp * 0.42, step_amp * 0.42)
		tween.tween_property(viewport_container, "position", _viewport_base_position + Vector2(x, y), step_sec)
	var settle_step_sec := maxf(0.01, shake_duration_sec * (duration_weights[half_steps] / maxf(0.0001, total_weight)))
	tween.tween_property(viewport_container, "position", _viewport_base_position, settle_step_sec)
	await tween.finished


func _tween_black_overlay_alpha(target_alpha: float, duration: float) -> void:
	if _transition_black == null:
		return
	var tween := create_tween()
	tween.tween_property(_transition_black, "color:a", clampf(target_alpha, 0.0, 1.0), maxf(0.01, duration))
	await tween.finished


func _play_line_rise_and_glow() -> void:
	if _transition_line == null or _transition_line_glow == null:
		return
	_set_transition_line_height(0.0)
	_transition_line.color = Color(1.0, 1.0, 1.0, 1.0)
	_transition_line_glow.color = Color(1.0, 1.0, 1.0, 0.0)
	var line_target_height := maxf(1.0, size.y)

	var rise := create_tween()
	rise.tween_method(Callable(self, "_set_transition_line_height"), 0.0, line_target_height, maxf(0.01, line_rise_duration_sec))
	rise.parallel().tween_property(_transition_line, "color:a", 1.0, 0.08)
	rise.parallel().tween_property(_transition_line_glow, "color:a", 0.4, 0.12)
	await rise.finished

	var glow := create_tween()
	glow.tween_property(_transition_line_glow, "color:a", 1.0, maxf(0.01, line_glow_duration_sec * 0.4))
	glow.tween_property(_transition_line_glow, "color:a", 0.45, maxf(0.01, line_glow_duration_sec * 0.6))
	await glow.finished

	var fade := create_tween()
	fade.tween_property(_transition_line, "color:a", 0.0, maxf(0.01, line_fade_duration_sec))
	fade.parallel().tween_property(_transition_line_glow, "color:a", 0.0, maxf(0.01, line_fade_duration_sec))
	await fade.finished


func _ensure_transition_nodes() -> void:
	_transition_layer = Control.new()
	_transition_layer.name = "TransitionLayer"
	_transition_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_transition_layer)

	_transition_scatter = ColorRect.new()
	_transition_scatter.name = "TransitionScatter"
	_transition_scatter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_scatter.color = Color(1.0, 1.0, 1.0, 1.0)
	var scatter_shader := Shader.new()
	scatter_shader.code = """
shader_type canvas_item;
render_mode unshaded;

uniform float spread_progress : hint_range(0.0, 1.0) = 0.0;
uniform float contract_progress : hint_range(0.0, 1.0) = 0.0;
uniform float overlay_alpha : hint_range(0.0, 1.0) = 0.0;
uniform float time_sec = 0.0;
uniform vec2 collapse_center = vec2(0.5, 0.5);

float hash12(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

vec2 hash22(vec2 p) {
	float x = hash12(p + vec2(17.13, 4.71));
	float y = hash12(p + vec2(31.77, 9.23));
	return vec2(x, y);
}

float spot_layer(vec2 uv, vec2 grid, float seed_bias, float spread, float t) {
	vec2 gv = uv * grid;
	vec2 cell = floor(gv);
	vec2 f = fract(gv);
	float h = hash12(cell + seed_bias);
	vec2 center = hash22(cell + seed_bias * 7.31);
	float pulse = sin(t * (2.0 + h * 4.5) + h * 19.0) * 0.5 + 0.5;
	float active = smoothstep(h * 0.95 - 0.08, h * 0.95 + 0.22, spread + pulse * 0.12);
	float radius = mix(0.08, 0.95, pow(spread, 1.12));
	float d = distance(f, center);
	float core = 1.0 - smoothstep(radius * 0.35, radius, d);
	return core * active;
}

void fragment() {
	float spread = clamp(spread_progress, 0.0, 1.0);
	float contract = clamp(contract_progress, 0.0, 1.0);
	float t = time_sec;

	float layer = 0.0;
	layer += spot_layer(UV, vec2(10.0, 6.0), 3.1, spread, t) * 0.35;
	layer += spot_layer(UV, vec2(17.0, 10.0), 7.4, spread, t) * 0.42;
	layer += spot_layer(UV, vec2(29.0, 18.0), 11.8, spread, t) * 0.38;
	layer = clamp(layer, 0.0, 1.0);

	float full_white = smoothstep(0.72, 1.0, spread);
	float alpha = clamp(layer * 0.75 + full_white, 0.0, 1.0);

	vec2 centered = UV - collapse_center;
	centered.x *= SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	float d = length(centered);
	float collapse_radius = mix(1.15, 0.08, pow(contract, 0.95));
	float edge_noise = (hash12(floor(UV * vec2(80.0, 45.0)) + t * 6.0) - 0.5) * 0.12;
	float retain = 1.0 - smoothstep(collapse_radius + edge_noise, collapse_radius + 0.18 + edge_noise, d);
	alpha *= retain;
	alpha *= clamp(overlay_alpha, 0.0, 1.0);

	COLOR = vec4(vec3(1.0), alpha);
}
"""
	_transition_scatter_material = ShaderMaterial.new()
	_transition_scatter_material.shader = scatter_shader
	_transition_scatter.material = _transition_scatter_material
	_transition_layer.add_child(_transition_scatter)

	_transition_black = ColorRect.new()
	_transition_black.name = "TransitionBlack"
	_transition_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_black.color = Color(0.0, 0.0, 0.0, 0.0)
	_transition_layer.add_child(_transition_black)

	_transition_line_glow = ColorRect.new()
	_transition_line_glow.name = "TransitionLineGlow"
	_transition_line_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_line_glow.color = Color(1.0, 1.0, 1.0, 0.0)
	_transition_layer.add_child(_transition_line_glow)

	_transition_line = ColorRect.new()
	_transition_line.name = "TransitionLine"
	_transition_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_line.color = Color(1.0, 1.0, 1.0, 0.0)
	_transition_layer.add_child(_transition_line)

	_layout_transition_nodes()


func _layout_transition_nodes() -> void:
	if _transition_layer == null or _transition_black == null:
		return
	_transition_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_transition_layer.offset_left = 0.0
	_transition_layer.offset_top = 0.0
	_transition_layer.offset_right = 0.0
	_transition_layer.offset_bottom = 0.0

	_transition_black.set_anchors_preset(Control.PRESET_FULL_RECT)
	_transition_black.offset_left = 0.0
	_transition_black.offset_top = 0.0
	_transition_black.offset_right = 0.0
	_transition_black.offset_bottom = 0.0

	if _transition_scatter != null:
		_transition_scatter.set_anchors_preset(Control.PRESET_FULL_RECT)
		_transition_scatter.offset_left = 0.0
		_transition_scatter.offset_top = 0.0
		_transition_scatter.offset_right = 0.0
		_transition_scatter.offset_bottom = 0.0

	var line_width := maxf(1.0, transition_line_width_px)
	if _transition_line != null:
		_transition_line.set_anchors_preset(Control.PRESET_TOP_LEFT)
		_transition_line.size = Vector2(line_width, _transition_line.size.y)
	if _transition_line_glow != null:
		_transition_line_glow.set_anchors_preset(Control.PRESET_TOP_LEFT)
		_transition_line_glow.size = Vector2(line_width * 3.0, _transition_line_glow.size.y)

	_set_transition_line_height(_transition_line.size.y if _transition_line != null else 0.0)


func _set_transition_line_height(height: float) -> void:
	if _transition_line == null or _transition_line_glow == null:
		return
	var h := clampf(height, 0.0, maxf(1.0, size.y))
	var center_x := size.x * 0.5
	var line_w := maxf(1.0, transition_line_width_px)
	var glow_w := line_w * 3.0

	_transition_line.size = Vector2(line_w, h)
	_transition_line.position = Vector2(center_x - line_w * 0.5, size.y - h)
	_transition_line_glow.size = Vector2(glow_w, h)
	_transition_line_glow.position = Vector2(center_x - glow_w * 0.5, size.y - h)
