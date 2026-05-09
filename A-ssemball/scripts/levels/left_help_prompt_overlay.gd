extends CanvasLayer
class_name LeftHelpPromptOverlay

@export_range(0.0, 60.0, 0.1) var inactivity_delay_sec: float = 20.0
@export_range(0.0, 20.0, 0.1) var hint_fade_in_sec: float = 5.0

const DEFAULT_HINT_TEXT: String = "请输入文本（占位符）"
const BUTTON_SIZE: Vector2 = Vector2(34.0, 34.0)
const BUTTON_PADDING: Vector2 = Vector2(12.0, 12.0)
const POPUP_SIZE: Vector2 = Vector2(420.0, 118.0)
const POPUP_REVEAL_SEC: float = 0.34
const DEFAULT_HINT_FONT_COLOR: Color = Color(0.96, 0.96, 0.96, 1.0)

var _anchor_container: Control
var _camera: Camera3D
var _target_node: Node3D
var _target_world_radius: float = 1.0
var _hint_text: String = DEFAULT_HINT_TEXT
var _popup_size: Vector2 = POPUP_SIZE
var _hint_font_size: int = 24
var _hint_font_color: Color = DEFAULT_HINT_FONT_COLOR
var _always_visible: bool = false
var _hint_enabled: bool = true
var _action_registered: bool = false
var _time_since_enter: float = 0.0
var _button_latched_visible: bool = false
var _button_reveal_elapsed: float = -1.0

var _ui_root: Control
var _hint_button: Button
var _popup_root: Control
var _popup_panel: Panel
var _popup_label: Label
var _popup_tween: Tween
var _popup_open: bool = false
var _popup_fully_open: bool = false


func _ready() -> void:
	layer = 100
	_build_ui()


func _process(delta: float) -> void:
	if not _hint_enabled:
		_hint_button.visible = false
		_popup_root.visible = false
		return
	if not _always_visible and not _action_registered and not _button_latched_visible and _button_reveal_elapsed < 0.0:
		_time_since_enter += delta
		if _time_since_enter >= inactivity_delay_sec:
			_button_reveal_elapsed = 0.0
	if _button_reveal_elapsed >= 0.0:
		_button_reveal_elapsed += delta
		if _button_reveal_elapsed >= maxf(0.001, hint_fade_in_sec):
			_button_reveal_elapsed = -1.0
			_button_latched_visible = true
	var button_alpha := 0.0
	if _always_visible or _button_latched_visible:
		button_alpha = 1.0
	elif _button_reveal_elapsed >= 0.0:
		button_alpha = clampf(_button_reveal_elapsed / maxf(0.001, hint_fade_in_sec), 0.0, 1.0)
	_hint_button.visible = button_alpha > 0.0
	_hint_button.modulate = Color(1.0, 1.0, 1.0, button_alpha)
	_update_button_position()


func _unhandled_input(event: InputEvent) -> void:
	if not _popup_open:
		return
	var should_close := false
	if event is InputEventKey:
		var key_event := event as InputEventKey
		should_close = key_event.pressed and not key_event.echo
	elif event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		should_close = mouse_event.pressed
	if not should_close:
		return
	_close_popup()
	get_viewport().set_input_as_handled()


func setup(anchor_container: Control, camera: Camera3D, target_node: Node3D, target_world_radius: float = 1.0) -> void:
	_anchor_container = anchor_container
	_camera = camera
	_target_node = target_node
	_target_world_radius = maxf(0.001, target_world_radius)
	reset_inactivity_tracking()


func set_hint_text(text: String) -> void:
	_hint_text = text
	if _popup_label != null:
		_popup_label.text = _hint_text


func set_popup_size(size: Vector2) -> void:
	_popup_size = Vector2(maxf(220.0, size.x), maxf(120.0, size.y))
	if _popup_panel != null:
		_popup_panel.size = _popup_size
	if _popup_open and _popup_root != null:
		var viewport_size := get_viewport().get_visible_rect().size
		_popup_root.position = (viewport_size - _popup_size) * 0.5


func set_hint_text_style(font_size: int, font_color: Color = DEFAULT_HINT_FONT_COLOR) -> void:
	_hint_font_size = maxi(14, font_size)
	_hint_font_color = font_color
	if _popup_label != null:
		_popup_label.add_theme_font_size_override("font_size", _hint_font_size)
		_popup_label.add_theme_color_override("font_color", _hint_font_color)


func set_always_visible_hint(enabled: bool) -> void:
	_always_visible = enabled
	if enabled:
		_button_latched_visible = true


func set_hint_enabled(enabled: bool) -> void:
	var was_enabled := _hint_enabled
	_hint_enabled = enabled
	if not enabled:
		if _hint_button != null:
			_hint_button.visible = false
		_close_popup_immediate()
	elif not was_enabled:
		reset_inactivity_tracking()


func notify_valid_action() -> void:
	if _button_latched_visible or _always_visible:
		return
	_action_registered = true
	_button_reveal_elapsed = -1.0


func reset_inactivity_tracking(preserve_visibility: bool = true) -> void:
	_action_registered = false
	_time_since_enter = 0.0
	_button_reveal_elapsed = -1.0
	if preserve_visibility and _button_latched_visible:
		return
	_button_latched_visible = _always_visible


func _build_ui() -> void:
	_ui_root = Control.new()
	_ui_root.name = "UiRoot"
	_ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui_root.offset_left = 0.0
	_ui_root.offset_top = 0.0
	_ui_root.offset_right = 0.0
	_ui_root.offset_bottom = 0.0
	add_child(_ui_root)

	_hint_button = Button.new()
	_hint_button.name = "HintButton"
	_hint_button.text = "!"
	_hint_button.visible = false
	_hint_button.focus_mode = Control.FOCUS_NONE
	_hint_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_hint_button.custom_minimum_size = BUTTON_SIZE
	_hint_button.size = BUTTON_SIZE
	_hint_button.add_theme_font_size_override("font_size", 22)
	_hint_button.add_theme_color_override("font_color", Color.BLACK)
	_hint_button.add_theme_color_override("font_hover_color", Color.BLACK)
	_hint_button.add_theme_color_override("font_pressed_color", Color.BLACK)
	var button_style := StyleBoxFlat.new()
	button_style.bg_color = Color.WHITE
	button_style.border_color = Color.BLACK
	button_style.border_width_left = 2
	button_style.border_width_top = 2
	button_style.border_width_right = 2
	button_style.border_width_bottom = 2
	button_style.corner_radius_top_left = 6
	button_style.corner_radius_top_right = 6
	button_style.corner_radius_bottom_left = 6
	button_style.corner_radius_bottom_right = 6
	_hint_button.add_theme_stylebox_override("normal", button_style)
	_hint_button.add_theme_stylebox_override("hover", button_style)
	_hint_button.add_theme_stylebox_override("pressed", button_style)
	_hint_button.pressed.connect(_on_hint_button_pressed)
	_ui_root.add_child(_hint_button)

	_popup_root = Control.new()
	_popup_root.name = "HintPopupRoot"
	_popup_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_popup_root.clip_contents = true
	_popup_root.visible = false
	_ui_root.add_child(_popup_root)

	_popup_panel = Panel.new()
	_popup_panel.name = "HintPopupPanel"
	_popup_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_popup_panel.size = _popup_size
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.35, 0.35, 0.35, 0.78)
	panel_style.border_color = Color.BLACK
	panel_style.border_width_left = 3
	panel_style.border_width_top = 3
	panel_style.border_width_right = 3
	panel_style.border_width_bottom = 3
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	_popup_panel.add_theme_stylebox_override("panel", panel_style)
	_popup_root.add_child(_popup_panel)

	_popup_label = Label.new()
	_popup_label.name = "HintPopupLabel"
	_popup_label.text = _hint_text
	_popup_label.visible = false
	_popup_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_popup_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_popup_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_popup_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_popup_label.add_theme_font_size_override("font_size", _hint_font_size)
	_popup_label.add_theme_color_override("font_color", _hint_font_color)
	_popup_label.add_theme_constant_override("line_spacing", 8)
	_popup_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_popup_label.offset_left = 24.0
	_popup_label.offset_top = 20.0
	_popup_label.offset_right = -24.0
	_popup_label.offset_bottom = -20.0
	_popup_root.add_child(_popup_label)


func _update_button_position() -> void:
	if _anchor_container == null or not is_instance_valid(_anchor_container):
		return
	var anchor_origin := _anchor_container.get_global_rect().position
	var anchor_size := _anchor_container.size
	var button_pos := anchor_origin + anchor_size - BUTTON_SIZE - BUTTON_PADDING
	_hint_button.position = button_pos


func _on_hint_button_pressed() -> void:
	if _popup_open and _popup_fully_open:
		_close_popup()
		return
	if not _popup_open:
		_open_popup()


func _open_popup() -> void:
	if _popup_tween != null and is_instance_valid(_popup_tween):
		_popup_tween.kill()
	_popup_open = true
	_popup_fully_open = false
	_popup_root.visible = true
	_popup_label.visible = false
	_popup_label.text = _hint_text
	var viewport_size := get_viewport().get_visible_rect().size
	var popup_pos := (viewport_size - _popup_size) * 0.5
	_popup_root.position = popup_pos
	_popup_root.size = Vector2(0.0, _popup_size.y)
	_popup_panel.position = Vector2.ZERO
	_popup_panel.size = _popup_size
	_popup_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_popup_tween = create_tween()
	_popup_tween.tween_property(_popup_root, "size:x", _popup_size.x, POPUP_REVEAL_SEC).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_popup_tween.finished.connect(_on_popup_reveal_finished, CONNECT_ONE_SHOT)


func _on_popup_reveal_finished() -> void:
	_popup_label.visible = true
	_popup_fully_open = true


func _close_popup() -> void:
	if _popup_tween != null and is_instance_valid(_popup_tween):
		_popup_tween.kill()
	_popup_fully_open = false
	_popup_label.visible = false
	_popup_tween = create_tween()
	_popup_tween.tween_property(_popup_root, "size:x", 0.0, POPUP_REVEAL_SEC * 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_popup_tween.finished.connect(_close_popup_immediate, CONNECT_ONE_SHOT)


func _close_popup_immediate() -> void:
	_popup_open = false
	_popup_fully_open = false
	if _popup_root != null:
		_popup_root.visible = false
		_popup_root.size = Vector2.ZERO
	if _popup_label != null:
		_popup_label.visible = false
