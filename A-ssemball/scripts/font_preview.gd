extends Control

signal preview_closed

const FONT_CANDIDATE_DIR := "res://dev/font_candidates"

var _scroll: ScrollContainer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_preview()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_BACKSPACE:
			get_viewport().set_input_as_handled()
			preview_closed.emit()


func _build_preview() -> void:
	var background := ColorRect.new()
	background.name = "Background"
	background.color = Color(0.018, 0.024, 0.034, 1.0)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_top", 34)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_bottom", 34)
	add_child(margin)

	var root := VBoxContainer.new()
	root.name = "Root"
	root.add_theme_constant_override("separation", 22)
	margin.add_child(root)

	var header := Label.new()
	header.text = "ASSEMBALL FONT PREVIEW"
	header.add_theme_font_size_override("font_size", 18)
	header.add_theme_color_override("font_color", Color(0.62, 0.72, 0.82, 0.72))
	header.add_theme_constant_override("outline_size", 1)
	header.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.45))
	root.add_child(header)

	_scroll = ScrollContainer.new()
	_scroll.name = "FontScroll"
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(_scroll)

	var grid := GridContainer.new()
	grid.name = "FontGrid"
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	_scroll.add_child(grid)

	var font_paths := _collect_font_candidate_paths()
	if font_paths.is_empty():
		grid.add_child(_create_empty_state_card())
		return
	for font_path in font_paths:
		grid.add_child(_create_font_card(font_path))


func _create_font_card(font_path: String) -> Control:
	var font_name := font_path.get_file().get_basename()
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0.0, 104.0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.058, 0.078, 0.92)
	style.border_color = Color(0.50, 0.58, 0.68, 0.32)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 6)
	margin.add_child(stack)

	var sample := Label.new()
	sample.text = "Assemball"
	sample.clip_text = true
	sample.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var font_resource := load(font_path) as Font
	if font_resource != null:
		sample.add_theme_font_override("font", font_resource)
	sample.add_theme_font_size_override("font_size", 42)
	sample.add_theme_color_override("font_color", Color(0.82, 0.88, 0.94, 0.94))
	sample.add_theme_constant_override("outline_size", 1)
	sample.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.8))
	stack.add_child(sample)

	var caption := Label.new()
	caption.text = font_name
	caption.add_theme_font_size_override("font_size", 14)
	caption.add_theme_color_override("font_color", Color(0.46, 0.56, 0.66, 0.82))
	stack.add_child(caption)

	return panel


func _collect_font_candidate_paths() -> Array[String]:
	var paths: Array[String] = []
	var dir := DirAccess.open(FONT_CANDIDATE_DIR)
	if dir == null:
		return paths
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			var lower_name := file_name.to_lower()
			if lower_name.ends_with(".ttf") or lower_name.ends_with(".otf"):
				paths.append(FONT_CANDIDATE_DIR + "/" + file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	paths.sort()
	return paths


func _create_empty_state_card() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0.0, 120.0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.058, 0.078, 0.92)
	style.border_color = Color(0.50, 0.58, 0.68, 0.32)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	panel.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = "No font candidates found in res://dev/font_candidates"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.68, 0.76, 0.84, 0.86))
	panel.add_child(label)
	return panel
