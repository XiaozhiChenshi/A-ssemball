extends Control
class_name IntroInteractive

signal intro_finished

@export var hold_key: Key = KEY_W
@export var move_speed: float = 15
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

@onready var sub_viewport: SubViewport = $ViewportContainer/SubViewport
@onready var camera_3d: Camera3D = $ViewportContainer/SubViewport/WorldRoot/Camera3D
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


func _ready() -> void:
	_camera_start_position = camera_3d.position
	_camera_progress_position = _camera_start_position
	_camera_end_position = _resolve_end_position()
	_base_fov = camera_3d.fov
	_base_camera_rotation = camera_3d.rotation
	_vignette_material = vignette_overlay.material as ShaderMaterial
	_vignette_radius_current = vignette_radius_base
	_update_dynamic_vignette(0.0)
	resized.connect(_on_resized)
	_on_resized()
	_update_hint_text()


func _process(delta: float) -> void:
	var is_moving := false
	if not _completed:
		is_moving = Input.is_physical_key_pressed(hold_key)
		if is_moving:
			var current_pos: Vector3 = _camera_progress_position
			var remaining: float = current_pos.distance_to(_camera_end_position)
			var step: float = maxf(0.0, move_speed) * delta

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
			_update_camera_motion(delta, false)
			_apply_camera_position()
	else:
		_update_camera_motion(delta, false)
		_apply_camera_position()

	_update_motion_state_weight(delta, is_moving)
	_update_idle_drift(delta)
	_apply_camera_position()
	_update_breathing_fov(delta)
	_update_dynamic_vignette(delta)
	_update_camera_roll(delta)


func _on_resized() -> void:
	var viewport_container := sub_viewport.get_parent() as SubViewportContainer
	if viewport_container != null and viewport_container.stretch:
		return
	sub_viewport.size = Vector2i(maxi(1, int(size.x)), maxi(1, int(size.y)))


func _resolve_end_position() -> Vector3:
	if use_explicit_end_position:
		return end_camera_position

	var forward_dir: Vector3 = -camera_3d.global_transform.basis.z.normalized()
	return _camera_start_position + forward_dir * forward_distance


func _on_reached_end() -> void:
	_completed = true
	if auto_finish_on_reach_end:
		hint.text = "Loading..."
		intro_finished.emit()
	else:
		hint.text = "Reached End"


func _update_hint_text() -> void:
	if auto_finish_on_reach_end:
		hint.text = "Hold W To Move Forward"
	else:
		hint.text = "Hold W To Move Forward (No Auto Switch)"


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
