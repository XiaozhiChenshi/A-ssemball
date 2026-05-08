extends Control
class_name InputHintOverlay

enum HintMode { AD, WASD }

@export var mode: int = HintMode.WASD:
	set(value):
		mode = value
		_sync_key_visibility()
@export var edge_padding: float = 18.0
@export var min_font_size: int = 22
@export var max_font_size: int = 44
@export var normal_color: Color = Color(0.08, 0.12, 0.18, 0.58)
@export var normal_outline_color: Color = Color(0.88, 0.94, 1.0, 0.58)
@export var active_color: Color = Color(0.42, 0.52, 0.64, 0.94)
@export var active_outline_color: Color = Color(1.0, 1.0, 1.0, 0.96)
@export var disabled_alpha: float = 1.0

var _labels: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_labels()
	_sync_key_visibility()
	_layout_labels()
	resized.connect(_layout_labels)


func _process(_delta: float) -> void:
	_update_key_state("W", KEY_W)
	_update_key_state("A", KEY_A)
	_update_key_state("S", KEY_S)
	_update_key_state("D", KEY_D)


func set_mode_wasd() -> void:
	mode = HintMode.WASD


func set_mode_ad() -> void:
	mode = HintMode.AD


func _build_labels() -> void:
	if not _labels.is_empty():
		return
	for key_name in ["W", "A", "S", "D"]:
		var label := Label.new()
		label.name = "InputHint" + key_name
		label.text = key_name
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.z_index = 90
		add_child(label)
		_labels[key_name] = label


func _sync_key_visibility() -> void:
	if _labels.is_empty():
		return
	var show_wasd := mode == HintMode.WASD
	(_labels["W"] as Label).visible = show_wasd
	(_labels["S"] as Label).visible = show_wasd
	(_labels["A"] as Label).visible = true
	(_labels["D"] as Label).visible = true


func _layout_labels() -> void:
	if _labels.is_empty():
		return
	var shortest := maxf(1.0, minf(size.x, size.y))
	var font_size := clampi(int(shortest * 0.065), min_font_size, max_font_size)
	var box := Vector2(float(font_size) * 1.18, float(font_size) * 1.08)
	var pad := minf(edge_padding, maxf(8.0, shortest * 0.045))
	var center := size * 0.5
	_place_label("W", Vector2(center.x - box.x * 0.5, pad))
	_place_label("A", Vector2(pad, center.y - box.y * 0.5))
	_place_label("S", Vector2(center.x - box.x * 0.5, size.y - pad - box.y))
	_place_label("D", Vector2(size.x - pad - box.x, center.y - box.y * 0.5))
	for key_name in _labels.keys():
		var label := _labels[key_name] as Label
		label.size = box
		label.add_theme_font_size_override("font_size", font_size)
		label.add_theme_constant_override("outline_size", maxi(2, int(font_size * 0.07)))


func _place_label(key_name: String, position_value: Vector2) -> void:
	if not _labels.has(key_name):
		return
	(_labels[key_name] as Label).position = position_value


func _update_key_state(key_name: String, keycode: Key) -> void:
	if not _labels.has(key_name):
		return
	var label := _labels[key_name] as Label
	if not label.visible:
		return
	var active := Input.is_physical_key_pressed(keycode)
	label.modulate.a = disabled_alpha
	label.add_theme_color_override("font_color", active_color if active else normal_color)
	label.add_theme_color_override("font_outline_color", active_outline_color if active else normal_outline_color)
	label.scale = Vector2.ONE * (1.03 if active else 1.0)
	label.pivot_offset = label.size * 0.5
