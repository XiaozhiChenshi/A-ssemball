extends Control
class_name InputHintOverlay

enum HintMode { AD, WASD }
enum HintState { INTRO, READY, COMPLETE_WAIT, OUTRO, HIDDEN }

const QUANTICO_FONT: FontFile = preload("res://assets/fonts/Quantico.ttf")
const GLITCH_SHADER: Shader = preload("res://shaders/input_hint_glitch.gdshader")
const KEY_ORDER: Array[String] = ["W", "A", "S", "D"]
const KEY_CODES: Dictionary = {
	"W": KEY_W,
	"A": KEY_A,
	"S": KEY_S,
	"D": KEY_D,
}

@export var mode: int = HintMode.WASD:
	set(value):
		mode = value
		_sync_key_visibility()
		restart_hint()
@export var edge_padding: float = 14.0
@export var min_font_size: int = 18
@export var max_font_size: int = 34
@export var normal_color: Color = Color(0.68, 0.76, 0.84, 0.58)
@export var normal_outline_color: Color = Color(0.10, 0.18, 0.28, 0.70)
@export var active_color: Color = Color(0.86, 0.96, 1.0, 0.96)
@export var active_outline_color: Color = Color(0.36, 0.88, 1.0, 0.92)
@export var disabled_alpha: float = 1.0
@export var intro_sec: float = 0.48
@export var complete_hold_sec: float = 5.6
@export var outro_sec: float = 0.58
@export var idle_soft_timeout_sec: float = 22.0

var _keys: Dictionary = {}
var _label_materials: Dictionary = {}
var _base_positions: Dictionary = {}
var _pressed_once: Dictionary = {}
var _state: int = HintState.INTRO
var _state_time: float = 0.0
var _time_phase: float = 0.0
var _was_visible_last_frame: bool = true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_keys()
	_sync_key_visibility()
	_layout_labels()
	resized.connect(_layout_labels)
	visibility_changed.connect(_on_visibility_changed)
	restart_hint()


func _process(delta: float) -> void:
	_time_phase += delta
	if visible and not _was_visible_last_frame:
		restart_hint()
	_was_visible_last_frame = visible
	if _state == HintState.HIDDEN:
		return

	_state_time += delta
	var required_keys := _get_required_keys()
	for key_name in required_keys:
		if Input.is_physical_key_pressed(KEY_CODES[key_name]):
			_pressed_once[key_name] = true

	if _state == HintState.INTRO and _state_time >= intro_sec:
		_enter_state(HintState.READY)
	elif _state == HintState.READY:
		if _has_pressed_all_required(required_keys):
			_enter_state(HintState.COMPLETE_WAIT)
		elif _state_time >= idle_soft_timeout_sec:
			_enter_state(HintState.OUTRO)
	elif _state == HintState.COMPLETE_WAIT and _state_time >= complete_hold_sec:
		_enter_state(HintState.OUTRO)
	elif _state == HintState.OUTRO and _state_time >= outro_sec:
		_enter_state(HintState.HIDDEN)

	_update_visuals()


func set_mode_wasd() -> void:
	mode = HintMode.WASD


func set_mode_ad() -> void:
	mode = HintMode.AD


func restart_hint() -> void:
	_pressed_once.clear()
	for key_name in _get_required_keys():
		_pressed_once[key_name] = false
	modulate.a = 1.0
	_enter_state(HintState.INTRO)
	_update_visuals()


func _build_keys() -> void:
	if not _keys.is_empty():
		return
	for key_name in KEY_ORDER:
		var label := Label.new()
		label.name = "InputHint" + key_name
		label.text = key_name
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.z_index = 90
		label.add_theme_font_override("font", QUANTICO_FONT)
		var material := ShaderMaterial.new()
		material.shader = GLITCH_SHADER
		label.material = material
		add_child(label)

		_keys[key_name] = {
			"label": label,
		}
		_label_materials[key_name] = material


func _sync_key_visibility() -> void:
	if _keys.is_empty():
		return
	var show_wasd := mode == HintMode.WASD
	_set_key_visible("W", show_wasd)
	_set_key_visible("S", show_wasd)
	_set_key_visible("A", true)
	_set_key_visible("D", true)


func _set_key_visible(key_name: String, is_visible: bool) -> void:
	if not _keys.has(key_name):
		return
	((_keys[key_name] as Dictionary)["label"] as Control).visible = is_visible


func _layout_labels() -> void:
	if _keys.is_empty():
		return
	var shortest := maxf(1.0, minf(size.x, size.y))
	var font_size := clampi(int(shortest * 0.052), min_font_size, max_font_size)
	var box := Vector2(float(font_size) * 1.42, float(font_size) * 1.24)
	var pad := minf(edge_padding, maxf(6.0, shortest * 0.034))
	var center := size * 0.5
	_place_key("W", Vector2(center.x - box.x * 0.5, pad))
	_place_key("A", Vector2(pad, center.y - box.y * 0.5))
	_place_key("S", Vector2(center.x - box.x * 0.5, size.y - pad - box.y))
	_place_key("D", Vector2(size.x - pad - box.x, center.y - box.y * 0.5))
	for key_name in _keys.keys():
		var entry := _keys[key_name] as Dictionary
		var label := entry["label"] as Label
		label.size = box
		label.pivot_offset = box * 0.5
		label.add_theme_font_size_override("font_size", font_size)
		label.add_theme_constant_override("outline_size", maxi(2, int(font_size * 0.080)))


func _place_key(key_name: String, position_value: Vector2) -> void:
	if not _keys.has(key_name):
		return
	_base_positions[key_name] = position_value
	((_keys[key_name] as Dictionary)["label"] as Control).position = position_value


func _update_visuals() -> void:
	var lifecycle_alpha := _get_lifecycle_alpha()
	var glitch_amount := _get_glitch_amount()
	for key_name in KEY_ORDER:
		if not _keys.has(key_name):
			continue
		var entry := _keys[key_name] as Dictionary
		var label := entry["label"] as Label
		if not label.visible:
			continue
		label.position = _base_positions.get(key_name, label.position) as Vector2
		var active := Input.is_physical_key_pressed(KEY_CODES[key_name])
		var seen := bool(_pressed_once.get(key_name, false))
		var alpha := lifecycle_alpha * disabled_alpha * (1.0 if active or not seen else 0.64)
		label.modulate.a = 1.0
		label.add_theme_color_override("font_color", active_color if active else normal_color)
		label.add_theme_color_override("font_outline_color", active_outline_color if active else normal_outline_color)
		label.scale = Vector2.ONE * (1.055 if active else 1.0)
		var material := _label_materials[key_name] as ShaderMaterial
		var active_multiplier := 0.64 if active else 1.0
		material.set_shader_parameter("glitch_amount", glitch_amount * active_multiplier)
		material.set_shader_parameter("opacity", alpha)
		material.set_shader_parameter("time_phase", _time_phase)
		material.set_shader_parameter("slice_strength", _get_slice_strength() * active_multiplier)
		material.set_shader_parameter("dropout_strength", _get_dropout_strength() * active_multiplier)
		material.set_shader_parameter("rgb_split", _get_rgb_split() * active_multiplier)
		material.set_shader_parameter("scan_strength", _get_scan_strength())


func _get_required_keys() -> Array[String]:
	if mode == HintMode.AD:
		return ["A", "D"]
	return ["W", "A", "S", "D"]


func _has_pressed_all_required(required_keys: Array[String]) -> bool:
	for key_name in required_keys:
		if not bool(_pressed_once.get(key_name, false)):
			return false
	return true


func _enter_state(next_state: int) -> void:
	_state = next_state
	_state_time = 0.0
	if _state == HintState.HIDDEN:
		modulate.a = 0.0


func _get_lifecycle_alpha() -> float:
	if _state == HintState.INTRO:
		return smoothstep(0.0, 1.0, clampf(_state_time / maxf(0.001, intro_sec), 0.0, 1.0))
	if _state == HintState.OUTRO:
		return 1.0 - smoothstep(0.0, 1.0, clampf(_state_time / maxf(0.001, outro_sec), 0.0, 1.0))
	if _state == HintState.HIDDEN:
		return 0.0
	return 1.0


func _get_glitch_amount() -> float:
	if _state == HintState.INTRO:
		var t := clampf(_state_time / maxf(0.001, intro_sec), 0.0, 1.0)
		return 1.0 - smoothstep(0.0, 1.0, t)
	if _state == HintState.OUTRO:
		var t := clampf(_state_time / maxf(0.001, outro_sec), 0.0, 1.0)
		return smoothstep(0.0, 1.0, t)
	if _state == HintState.COMPLETE_WAIT:
		return 0.25
	return 0.18


func _get_slice_strength() -> float:
	if _state == HintState.INTRO or _state == HintState.OUTRO:
		return _get_glitch_amount()
	if _state == HintState.COMPLETE_WAIT:
		return 0.22
	return 0.16


func _get_dropout_strength() -> float:
	if _state == HintState.INTRO or _state == HintState.OUTRO:
		return _get_glitch_amount() * 0.82
	if _state == HintState.COMPLETE_WAIT:
		return 0.16
	return 0.10


func _get_rgb_split() -> float:
	if _state == HintState.INTRO or _state == HintState.OUTRO:
		return _get_glitch_amount() * 0.72
	if _state == HintState.COMPLETE_WAIT:
		return 0.15
	return 0.11


func _get_scan_strength() -> float:
	if _state == HintState.INTRO or _state == HintState.OUTRO:
		return 0.48 + _get_glitch_amount() * 0.42
	if _state == HintState.COMPLETE_WAIT:
		return 0.28
	return 0.22


func _on_visibility_changed() -> void:
	if visible:
		restart_hint()
