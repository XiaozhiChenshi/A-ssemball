extends RefCounted
class_name InputMappingState

static var reverse_wasd_mapping: bool = true


static func toggle_reverse_wasd_mapping() -> bool:
	reverse_wasd_mapping = not reverse_wasd_mapping
	return reverse_wasd_mapping


static func get_wasd_vector() -> Vector2:
	var x := 0.0
	var y := 0.0
	if Input.is_key_pressed(KEY_A):
		x -= 1.0
	if Input.is_key_pressed(KEY_D):
		x += 1.0
	if Input.is_key_pressed(KEY_W):
		y -= 1.0
	if Input.is_key_pressed(KEY_S):
		y += 1.0
	if reverse_wasd_mapping:
		return Vector2(-x, -y)
	return Vector2(x, y)


static func get_left_right_dir_from_actions(left_action: StringName, right_action: StringName) -> int:
	var dir := 0
	if Input.is_action_pressed(left_action):
		dir -= 1
	if Input.is_action_pressed(right_action):
		dir += 1
	if reverse_wasd_mapping:
		dir *= -1
	return dir


static func map_step_direction(step_direction: int) -> int:
	if reverse_wasd_mapping:
		return -step_direction
	return step_direction
