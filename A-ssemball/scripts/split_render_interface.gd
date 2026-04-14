extends Control
class_name SplitRenderInterface

@export var light_rotation_speed_deg: float = 0.0
@export var light_energy: float = 0.85
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

@onready var split: HSplitContainer = $Split
@onready var left_3d: SubViewportContainer = $Split/Left3D
@onready var model_root: Node3D = $Split/Left3D/LeftViewport/World3D/ModelRoot
@onready var sphere: MeshInstance3D = $Split/Left3D/LeftViewport/World3D/ModelRoot/Sphere
@onready var right_panel: ColorRect = $Split/RightPanel
@onready var line_canvas: LineCanvas2D = $Split/RightPanel/LineCanvas
@onready var dir_light: DirectionalLight3D = $Split/Left3D/LeftViewport/World3D/DirectionalLight3D

var _is_dragging_sphere: bool = false
var _drag_accum_x: float = 0.0
var _drag_accum_y: float = 0.0
var _rotation_step_count: int = 0
var _sphere_rotate_tween: Tween
var _rotation_input_block_until_ms: int = 0
var _hold_rotate_dir: int = 0
var _hold_rotate_elapsed: float = 0.0
var _right_art_base_size: Vector2 = Vector2.ZERO
var _vertical_preview_phase: int = 0 # 0 none, 1 holding, 2 returning
var _vertical_preview_return_at_ms: int = 0
var _vertical_preview_saved_rotation: Vector3 = Vector3.ZERO


func _ready() -> void:
	_ensure_input_actions()
	_setup_default_sphere_material()
	dir_light.light_energy = light_energy
	right_panel.clip_contents = true
	resized.connect(_on_layout_changed)
	left_3d.resized.connect(_on_layout_changed)
	split.dragged.connect(_on_split_dragged)
	_on_layout_changed()
	call_deferred("_sync_right_scene_with_rotation")


func _process(delta: float) -> void:
	_update_vertical_preview_state()
	_update_hold_rotation(delta)

	if light_rotation_speed_deg == 0.0:
		return
	dir_light.rotate_y(deg_to_rad(light_rotation_speed_deg) * delta)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_action_pressed("rotate_sphere_left"):
			_try_rotate_sphere_step(-1)
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("rotate_sphere_right"):
			_try_rotate_sphere_step(1)
			get_viewport().set_input_as_handled()
			return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_is_dragging_sphere = left_3d.get_global_rect().has_point(event.position)
			_drag_accum_x = 0.0
			_drag_accum_y = 0.0
		else:
			_is_dragging_sphere = false
			_drag_accum_x = 0.0
			_drag_accum_y = 0.0
		return

	if _is_dragging_sphere and event is InputEventMouseMotion:
		if _is_sphere_input_locked():
			_drag_accum_x = 0.0
			_drag_accum_y = 0.0
			return
		_drag_accum_y += event.relative.y
		if _try_vertical_face_preview_from_drag():
			_drag_accum_x = 0.0
			_drag_accum_y = 0.0
			return

		_drag_accum_x += event.relative.x
		var threshold := maxf(1.0, drag_step_threshold_px)
		if absf(_drag_accum_x) >= threshold:
			var step_dir := 1 if _drag_accum_x > 0.0 else -1
			_try_rotate_sphere_step(step_dir)
			_drag_accum_x = 0.0


func _setup_default_sphere_material() -> void:
	var sphere_material := StandardMaterial3D.new()
	sphere_material.albedo_color = Color(0.82, 0.87, 0.96, 1.0)
	sphere_material.roughness = 0.42
	sphere.set_surface_override_material(0, sphere_material)


func _draw_default_line_art() -> void:
	var w := line_canvas.size.x
	var h := line_canvas.size.y
	if w <= 0.0 or h <= 0.0:
		return

	# A simple white-line wireframe shape as default content.
	var points := PackedVector2Array([
		Vector2(w * 0.20, h * 0.55),
		Vector2(w * 0.40, h * 0.35),
		Vector2(w * 0.62, h * 0.62),
		Vector2(w * 0.80, h * 0.40)
	])
	line_canvas.set_line_points(points, false, 4.0)


func _on_layout_changed() -> void:
	_enforce_split_constraints()
	_setup_fixed_right_canvas()

	# Redraw default line art when the panel size changes.
	if sync_right_scene_on_rotate:
		_sync_right_scene_with_rotation()
	else:
		_draw_default_line_art()


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
	_sphere_rotate_tween.tween_property(sphere, "rotation:y", target_y, rotation_step_duration)

	if sync_right_scene_on_rotate:
		_sync_right_scene_with_rotation()


func _sync_right_scene_with_rotation() -> void:
	var w := line_canvas.size.x
	var h := line_canvas.size.y
	if w <= 0.0 or h <= 0.0:
		return

	var idx := posmod(_rotation_step_count, 4)
	var points: PackedVector2Array

	# 4 linked 2D line scenes matching 3D quarter turns.
	match idx:
		0:
			points = PackedVector2Array([
				Vector2(w * 0.20, h * 0.55),
				Vector2(w * 0.40, h * 0.35),
				Vector2(w * 0.62, h * 0.62),
				Vector2(w * 0.80, h * 0.40)
			])
		1:
			points = PackedVector2Array([
				Vector2(w * 0.25, h * 0.28),
				Vector2(w * 0.52, h * 0.42),
				Vector2(w * 0.36, h * 0.72),
				Vector2(w * 0.74, h * 0.66)
			])
		2:
			points = PackedVector2Array([
				Vector2(w * 0.18, h * 0.42),
				Vector2(w * 0.40, h * 0.64),
				Vector2(w * 0.60, h * 0.36),
				Vector2(w * 0.82, h * 0.58)
			])
		_:
			points = PackedVector2Array([
				Vector2(w * 0.30, h * 0.25),
				Vector2(w * 0.24, h * 0.62),
				Vector2(w * 0.58, h * 0.48),
				Vector2(w * 0.78, h * 0.72)
			])

	line_canvas.set_line_points(points, false, 4.0)


func _is_rotation_input_blocked() -> bool:
	return Time.get_ticks_msec() < _rotation_input_block_until_ms


func _is_sphere_input_locked() -> bool:
	return _is_rotation_input_blocked() or _vertical_preview_phase != 0


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
	if is_instance_valid(_sphere_rotate_tween):
		_sphere_rotate_tween.kill()

	_sphere_rotate_tween = create_tween()
	_sphere_rotate_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_sphere_rotate_tween.tween_property(model_root, "rotation:x", target_x, duration)
	if finished_callback.is_valid():
		_sphere_rotate_tween.finished.connect(finished_callback, CONNECT_ONE_SHOT)


func _sync_right_scene_with_vertical_face(is_up_face: bool) -> void:
	var w := line_canvas.size.x
	var h := line_canvas.size.y
	if w <= 0.0 or h <= 0.0:
		return

	var points: PackedVector2Array
	if is_up_face:
		points = PackedVector2Array([
			Vector2(w * 0.22, h * 0.66),
			Vector2(w * 0.50, h * 0.26),
			Vector2(w * 0.78, h * 0.66),
			Vector2(w * 0.50, h * 0.54),
			Vector2(w * 0.22, h * 0.66)
		])
	else:
		points = PackedVector2Array([
			Vector2(w * 0.22, h * 0.34),
			Vector2(w * 0.50, h * 0.74),
			Vector2(w * 0.78, h * 0.34),
			Vector2(w * 0.50, h * 0.46),
			Vector2(w * 0.22, h * 0.34)
		])
	line_canvas.set_line_points(points, false, 4.0)


func _ensure_input_actions() -> void:
	if not InputMap.has_action("rotate_sphere_left"):
		InputMap.add_action("rotate_sphere_left")
		var a_key := InputEventKey.new()
		a_key.keycode = KEY_A
		InputMap.action_add_event("rotate_sphere_left", a_key)
		var left_key := InputEventKey.new()
		left_key.keycode = KEY_LEFT
		InputMap.action_add_event("rotate_sphere_left", left_key)

	if not InputMap.has_action("rotate_sphere_right"):
		InputMap.add_action("rotate_sphere_right")
		var d_key := InputEventKey.new()
		d_key.keycode = KEY_D
		InputMap.action_add_event("rotate_sphere_right", d_key)
		var right_key := InputEventKey.new()
		right_key.keycode = KEY_RIGHT
		InputMap.action_add_event("rotate_sphere_right", right_key)


func _on_split_dragged(_offset: int) -> void:
	_enforce_split_constraints()


func _enforce_split_constraints() -> void:
	# Keep right side at least 50% of total width.
	var min_right_width := maxf(1.0, size.x * 0.5)
	right_panel.custom_minimum_size.x = min_right_width
	if split.split_offset > 0:
		split.split_offset = 0


func _setup_fixed_right_canvas() -> void:
	# Fix right 2D image size so dragging splitter reveals/clips it rather than scaling.
	if _right_art_base_size == Vector2.ZERO and line_canvas.size.x > 1.0 and line_canvas.size.y > 1.0:
		_right_art_base_size = line_canvas.size
	if _right_art_base_size == Vector2.ZERO:
		return

	line_canvas.set_anchors_preset(Control.PRESET_TOP_LEFT)
	line_canvas.position = Vector2.ZERO
	line_canvas.size = _right_art_base_size
