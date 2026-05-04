extends Control
class_name LevelC2L2

signal chapter_completed(chapter_index: int)

const INSTRUMENT_TEXTURES: Dictionary = {
	"baton": preload("res://assets/materials/指挥棒.png"),
	"violin": preload("res://assets/materials/小提琴.png"),
	"piano": preload("res://assets/materials/钢琴.png"),
	"snare": preload("res://assets/materials/军鼓.png"),
	"harp": preload("res://assets/materials/竖琴.png"),
	"triangle": preload("res://assets/materials/三角铁.png"),
	"flute": preload("res://assets/materials/长笛.png"),
	"tuba": preload("res://assets/materials/低音号.png"),
}
const HOLD_ICON_ANCHORS: Array[Vector2] = [
	Vector2(0.50, 0.46),
	Vector2(0.46, 0.42),
	Vector2(0.50, 0.45),
	Vector2(0.50, 0.45),
	Vector2(0.50, 0.42),
	Vector2(0.48, 0.44),
	Vector2(0.50, 0.42),
	Vector2(0.50, 0.45),
]
const HOLD_ICON_SIZES: Dictionary = {
	"baton": Vector2(62.0, 110.0),
	"violin": Vector2(96.0, 78.0),
	"piano": Vector2(116.0, 92.0),
	"snare": Vector2(88.0, 78.0),
	"harp": Vector2(106.0, 122.0),
	"triangle": Vector2(78.0, 78.0),
	"flute": Vector2(112.0, 58.0),
	"tuba": Vector2(104.0, 122.0),
}
const DOLL_BASE_RECTS: Array[Rect2] = [
	Rect2(40.0, 40.0, 180.0, 240.0),
	Rect2(240.0, 40.0, 180.0, 240.0),
	Rect2(440.0, 40.0, 180.0, 240.0),
	Rect2(640.0, 40.0, 180.0, 240.0),
	Rect2(40.0, 300.0, 180.0, 240.0),
	Rect2(240.0, 300.0, 180.0, 240.0),
	Rect2(440.0, 300.0, 180.0, 240.0),
	Rect2(640.0, 300.0, 180.0, 240.0),
]
const CHUNK_NODE_ORDER: Array[String] = [
	"Chunk_n1_n1_n1",
	"Chunk_n1_n1_p1",
	"Chunk_n1_p1_n1",
	"Chunk_n1_p1_p1",
	"Chunk_p1_n1_n1",
	"Chunk_p1_n1_p1",
	"Chunk_p1_p1_n1",
	"Chunk_p1_p1_p1",
]
const INITIAL_INSTRUMENTS: Array[String] = [
	"snare",
	"triangle",
	"violin",
	"flute",
	"piano",
	"tuba",
	"harp",
	"baton",
]
const TARGET_INSTRUMENTS: Array[String] = [
	"piano",
	"violin",
	"flute",
	"snare",
	"harp",
	"baton",
	"triangle",
	"tuba",
]
const DOLL_NODE_NAMES: Array[String] = [
	"Doll_1_1_1",
	"Doll_1_1_2",
	"Doll_1_2_1",
	"Doll_1_2_2",
	"Doll_2_1_1",
	"Doll_2_1_2",
	"Doll_2_2_1",
	"Doll_2_2_2",
]
const SHARDS_PER_GROUP: int = 8
const CELL_INNER_RADIUS: float = 0.46
const CELL_OUTER_RADIUS: float = 0.83

@export var chapter_index: int = 2
@export_range(0.2, 2.0, 0.01) var slot_radius: float = 0.54
@export_range(0.0, 180.0, 0.1) var manual_rotate_speed_deg: float = 46.0
@export_range(0.1, 0.9, 0.01) var left_panel_width_ratio: float = 0.25
@export_range(8.0, 240.0, 1.0) var click_pick_radius_px: float = 86.0
@export_range(12.0, 240.0, 1.0) var drag_rotate_threshold_px: float = 34.0
@export_range(0.05, 1.5, 0.01) var snap_rotate_sec: float = 0.24
@export_range(0.05, 1.5, 0.01) var return_rotate_sec: float = 0.18
@export_range(0.05, 1.5, 0.01) var audition_sec: float = 0.72
@export_range(0.0, 0.12, 0.001) var group_idle_motion: float = 0.018

@onready var chapter_split: HSplitContainer = $ChapterSplit
@onready var left_3d: SubViewportContainer = $ChapterSplit/Left3D
@onready var left_viewport: SubViewport = $ChapterSplit/Left3D/LeftViewport
@onready var chunk_root: Node3D = $ChapterSplit/Left3D/LeftViewport/World3D/ChunkRoot
@onready var right_panel: Control = $ChapterSplit/RightPanel
@onready var stage_root: Control = $ChapterSplit/RightPanel/InteractiveFragments
@onready var camera_3d: Camera3D = $ChapterSplit/Left3D/LeftViewport/World3D/Camera3D

var _rng := RandomNumberGenerator.new()
var _pieces: Array[Dictionary] = []
var _stage_icons: Array[TextureRect] = []
var _foot_lights: Array[ColorRect] = []
var _top_lights: Array[ColorRect] = []
var _matched: Array[bool] = []
var _time_sec: float = 0.0
var _completed_once: bool = false
var _is_snapping: bool = false
var _is_auditioning: bool = false
var _dragging: bool = false
var _drag_start_pos: Vector2 = Vector2.ZERO
var _drag_piece: int = -1
var _drag_axis: int = -1
var _drag_side: float = 1.0
var _drag_layer: Array[int] = []
var _drag_start_transforms: Dictionary = {}
var _drag_start_slots: Dictionary = {}
var _drag_axis_local: Vector3 = Vector3.UP
var _drag_tangent_screen: Vector2 = Vector2.RIGHT
var _drag_angle: float = 0.0
var _stage_flash: ColorRect
var _progress_label: Label
var _audition_button: Button


func _ready() -> void:
	_rng.randomize()
	_setup_piece_groups()
	_setup_stage_runtime_ui()
	_sync_stage_instruments()
	_update_match_feedback(false)
	left_3d.visible = true
	chunk_root.visible = true
	resized.connect(_on_layout_changed)
	left_3d.resized.connect(_on_layout_changed)
	chapter_split.dragged.connect(_on_split_dragged)
	_on_layout_changed()


func _process(delta: float) -> void:
	_time_sec += delta
	_update_rotation_input(delta)
	_update_piece_groups(delta)


func _input(event: InputEvent) -> void:
	if _completed_once:
		return
	if event is InputEventMouseMotion and _dragging:
		_update_drag(event.position)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if _begin_drag(event.position):
				get_viewport().set_input_as_handled()
			elif right_panel.get_global_rect().has_point(event.position):
				_start_audition()
				get_viewport().set_input_as_handled()
		else:
			if _end_drag():
				get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			_start_audition()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ENTER and _are_all_matched():
			_start_final_performance()
			get_viewport().set_input_as_handled()


func _on_layout_changed() -> void:
	if not left_3d.stretch:
		left_viewport.size = Vector2i(maxi(1, int(left_3d.size.x)), maxi(1, int(left_3d.size.y)))
	_enforce_layout_constraints()
	_layout_stage_runtime_ui()


func _on_split_dragged(_offset: int) -> void:
	_enforce_layout_constraints()


func _enforce_layout_constraints() -> void:
	var ratio := clampf(left_panel_width_ratio, 0.1, 0.9)
	right_panel.custom_minimum_size.x = maxf(1.0, size.x * (1.0 - ratio))
	var target_offset := -int(maxf(0.0, size.x * ratio))
	if chapter_split.split_offset != target_offset:
		chapter_split.split_offset = target_offset


func _setup_piece_groups() -> void:
	_pieces.clear()
	for i in range(CHUNK_NODE_ORDER.size()):
		var node := chunk_root.get_node_or_null(CHUNK_NODE_ORDER[i]) as Node3D
		if node == null:
			continue
		_hide_old_chunk_visuals(node)
		var shard_root := _ensure_shard_group(node, i)
		node.transform = Transform3D(Basis.IDENTITY, _slot_position(i))
		_pieces.append(
			{
				"node": node,
				"slot": i,
				"instrument": INITIAL_INSTRUMENTS[i],
				"phase": _rng.randf_range(0.0, TAU),
				"speed": _rng.randf_range(0.55, 1.25),
				"active_target": 0.0,
				"active": 0.0,
				"matched_target": 0.0,
				"matched": 0.0,
				"is_drag_layer": false,
				"shards": _collect_shards(shard_root),
			}
		)
		_matched.append(false)


func _hide_old_chunk_visuals(node: Node3D) -> void:
	for child in node.get_children():
		if child is MeshInstance3D or child is Sprite3D:
			(child as Node3D).visible = false


func _ensure_shard_group(node: Node3D, piece_index: int) -> Node3D:
	var root := node.get_node_or_null("ShardGroup") as Node3D
	if root == null:
		root = Node3D.new()
		root.name = "ShardGroup"
		node.add_child(root)
	for child in root.get_children():
		child.queue_free()

	for i in range(SHARDS_PER_GROUP):
		var cell := Node3D.new()
		cell.name = "Cell_%02d" % i
		var sign := _slot_sign(piece_index)
		var base_pos := _cell_base_position(sign, i)
		cell.position = base_pos
		cell.rotation = Vector3(_rng.randf_range(-0.7, 0.7), _rng.randf_range(-0.7, 0.7), _rng.randf_range(-0.7, 0.7))
		cell.set_meta("base_pos", base_pos)
		cell.set_meta("base_rot", cell.rotation)
		cell.set_meta("phase", _rng.randf_range(0.0, TAU))
		cell.set_meta("speed", _rng.randf_range(0.65, 1.9))
		cell.set_meta("amp", _rng.randf_range(0.006, 0.021))
		root.add_child(cell)

		var mesh_instance := MeshInstance3D.new()
		mesh_instance.name = "Solid"
		var mesh := BoxMesh.new()
		mesh.size = Vector3(
			_rng.randf_range(0.105, 0.18),
			_rng.randf_range(0.075, 0.16),
			_rng.randf_range(0.09, 0.17)
		)
		mesh_instance.mesh = mesh
		mesh_instance.material_override = _create_solid_cell_material()
		cell.add_child(mesh_instance)

		var outline := MeshInstance3D.new()
		outline.name = "WhiteOutline"
		outline.mesh = mesh
		outline.scale = Vector3.ONE * 1.075
		outline.material_override = _create_outline_material()
		cell.add_child(outline)

	return root


func _cell_base_position(sign: Vector3, index: int) -> Vector3:
	var cols := [
		Vector3(0.00, 0.00, 0.00),
		Vector3(0.16, 0.02, -0.04),
		Vector3(-0.15, -0.01, 0.05),
		Vector3(0.04, 0.15, 0.02),
		Vector3(-0.03, -0.15, -0.02),
		Vector3(0.06, -0.05, 0.16),
		Vector3(-0.05, 0.04, -0.15),
		Vector3(0.12, 0.13, 0.10),
	]
	var base: Vector3 = cols[index % cols.size()]
	base.x *= sign.x
	base.y *= sign.y
	base.z *= sign.z
	return base


func _collect_shards(root: Node3D) -> Array[Node3D]:
	var out: Array[Node3D] = []
	for child in root.get_children():
		if child is Node3D:
			out.append(child as Node3D)
	return out


func _create_solid_cell_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.075, 0.084, 0.092, 1.0)
	mat.roughness = 0.72
	mat.metallic = 0.02
	mat.emission_enabled = true
	mat.emission = Color(0.02, 0.08, 0.095, 1.0)
	mat.emission_energy_multiplier = 0.11
	return mat


func _create_outline_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.92, 0.96, 1.0, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.9, 0.97, 1.0, 1.0)
	mat.emission_energy_multiplier = 0.46
	mat.cull_mode = BaseMaterial3D.CULL_FRONT
	mat.no_depth_test = false
	return mat


func _setup_stage_runtime_ui() -> void:
	_stage_flash = ColorRect.new()
	_stage_flash.name = "StageFlash"
	_stage_flash.color = Color(1.0, 0.94, 0.72, 0.0)
	_stage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_root.add_child(_stage_flash)

	for i in range(8):
		var foot := ColorRect.new()
		foot.name = "FootLight_%d" % i
		foot.color = Color(0.24, 0.42, 0.62, 0.28)
		foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stage_root.add_child(foot)
		_foot_lights.append(foot)

	for i in range(4):
		var top := ColorRect.new()
		top.name = "TopLight_%d" % i
		top.color = Color(0.72, 0.86, 1.0, 0.22)
		top.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stage_root.add_child(top)
		_top_lights.append(top)

	for i in range(8):
		var icon := TextureRect.new()
		icon.name = "StageInstrument_%d" % i
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stage_root.add_child(icon)
		_stage_icons.append(icon)

	_progress_label = Label.new()
	_progress_label.name = "ProgressLabel"
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_progress_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_progress_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_progress_label.add_theme_font_size_override("font_size", 22)
	_progress_label.modulate = Color(0.92, 0.96, 1.0, 0.88)
	right_panel.add_child(_progress_label)

	_audition_button = Button.new()
	_audition_button.name = "AuditionButton"
	_audition_button.text = "试听"
	_audition_button.focus_mode = Control.FOCUS_NONE
	_audition_button.custom_minimum_size = Vector2(96.0, 42.0)
	_audition_button.pressed.connect(_start_audition)
	right_panel.add_child(_audition_button)


func _layout_stage_runtime_ui() -> void:
	if stage_root == null or not is_instance_valid(stage_root):
		return
	var scale := _stage_scale()
	_stage_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stage_flash.offset_left = 0.0
	_stage_flash.offset_top = 0.0
	_stage_flash.offset_right = 0.0
	_stage_flash.offset_bottom = 0.0
	_stage_flash.move_to_front()

	for i in range(_stage_icons.size()):
		var doll := stage_root.get_node_or_null(DOLL_NODE_NAMES[i]) as TextureRect
		if doll != null and i < DOLL_BASE_RECTS.size():
			var base_rect := DOLL_BASE_RECTS[i]
			doll.position = base_rect.position * scale
			doll.size = base_rect.size * scale

		var instrument_id := _stage_instrument_at_slot(i)
		var icon_size: Vector2 = HOLD_ICON_SIZES.get(instrument_id, Vector2(100.0, 86.0)) * scale
		var icon_pos := Vector2.ZERO
		if doll != null:
			icon_pos = doll.position + doll.size * HOLD_ICON_ANCHORS[i]
		else:
			icon_pos = Vector2(130.0 + float(i % 4) * 200.0, 140.0 + float(i / 4) * 260.0) * scale
		var icon := _stage_icons[i]
		icon.position = icon_pos - icon_size * 0.5
		icon.size = icon_size
		icon.move_to_front()

		var foot := _foot_lights[i]
		var foot_pos := icon_pos + Vector2(-48.0, 126.0) * scale
		if doll != null:
			foot_pos = doll.position + Vector2(doll.size.x * 0.5 - 48.0 * scale.x, doll.size.y * 0.92)
		foot.position = foot_pos
		foot.size = Vector2(96.0, 8.0) * scale
		foot.move_to_front()

	for i in range(_top_lights.size()):
		var top := _top_lights[i]
		top.position = Vector2(180.0 + float(i) * 180.0, 24.0) * scale
		top.size = Vector2(110.0, 10.0) * scale
		top.move_to_front()

	if _progress_label != null:
		_progress_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		_progress_label.offset_left = 0.0
		_progress_label.offset_right = 0.0
		_progress_label.offset_top = -46.0
		_progress_label.offset_bottom = -10.0
	if _audition_button != null:
		_audition_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		_audition_button.offset_left = -116.0
		_audition_button.offset_top = 18.0
		_audition_button.offset_right = -20.0
		_audition_button.offset_bottom = 60.0


func _stage_scale() -> Vector2:
	return Vector2(right_panel.size.x / 960.0, right_panel.size.y / 720.0)


func _sync_stage_instruments() -> void:
	for slot_index in range(_stage_icons.size()):
		var instrument_id := _stage_instrument_at_slot(slot_index)
		_stage_icons[slot_index].texture = INSTRUMENT_TEXTURES.get(instrument_id)
		_stage_icons[slot_index].modulate = Color(0.82, 0.9, 1.0, 0.9)
	_layout_stage_runtime_ui()


func _stage_instrument_at_slot(slot_index: int) -> String:
	var piece_index := _piece_at_slot(slot_index)
	if piece_index < 0:
		return ""
	return String(_pieces[piece_index].get("instrument", ""))


func _piece_at_slot(slot_index: int) -> int:
	for i in range(_pieces.size()):
		if int(_pieces[i].get("slot", -1)) == slot_index:
			return i
	return -1


func _begin_drag(screen_pos: Vector2) -> bool:
	if _is_snapping or _is_auditioning:
		return false
	if not left_3d.get_global_rect().has_point(screen_pos):
		return false
	_drag_piece = _pick_piece_at_screen_position(screen_pos)
	if _drag_piece < 0:
		return false
	_dragging = true
	_drag_start_pos = screen_pos
	_set_piece_active(_drag_piece, true)
	return true


func _update_drag(screen_pos: Vector2) -> void:
	if not _dragging or _drag_piece < 0:
		return
	var delta := screen_pos - _drag_start_pos
	if _drag_axis < 0:
		if delta.length() < drag_rotate_threshold_px:
			return
		_begin_layer_drag(delta)
	if _drag_axis < 0:
		return
	var signed_pixels := delta.dot(_drag_tangent_screen)
	_drag_angle = clampf(signed_pixels / 140.0, -1.0, 1.0) * PI * 0.5
	_apply_layer_transform(Basis(_drag_axis_local, _drag_angle))


func _begin_layer_drag(delta: Vector2) -> void:
	var slot := int(_pieces[_drag_piece].get("slot", 0))
	var slot_sign := _slot_sign(slot)
	var best_axis := -1
	var best_score := 0.0
	var best_tangent := Vector2.RIGHT
	var piece_node := _pieces[_drag_piece].get("node") as Node3D
	if piece_node == null:
		return
	var piece_world := piece_node.global_transform.origin
	for axis in range(3):
		var local_axis := _axis_local_vector(axis)
		var world_axis := chunk_root.global_transform.basis * local_axis
		var tangent_world := world_axis.cross(piece_world - chunk_root.global_transform.origin)
		if tangent_world.length() < 0.001:
			continue
		var screen_a := camera_3d.unproject_position(piece_world)
		var screen_b := camera_3d.unproject_position(piece_world + tangent_world.normalized())
		var tangent_screen := (screen_b - screen_a)
		if tangent_screen.length() < 0.001:
			continue
		tangent_screen = tangent_screen.normalized()
		var score := absf(delta.normalized().dot(tangent_screen))
		if score > best_score:
			best_axis = axis
			best_score = score
			best_tangent = tangent_screen
	if best_axis < 0:
		return

	_drag_axis = best_axis
	_drag_side = _axis_value(slot_sign, _drag_axis)
	_drag_axis_local = _axis_local_vector(_drag_axis)
	_drag_tangent_screen = best_tangent
	if delta.dot(_drag_tangent_screen) < 0.0:
		_drag_tangent_screen *= -1.0
	_drag_layer = _pieces_on_layer(_drag_axis, _drag_side)
	_drag_start_transforms.clear()
	_drag_start_slots.clear()
	for idx in _drag_layer:
		var node := _pieces[idx].get("node") as Node3D
		if node == null:
			continue
		_drag_start_transforms[idx] = node.transform
		_drag_start_slots[idx] = int(_pieces[idx].get("slot", 0))
		_pieces[idx]["is_drag_layer"] = true
		_set_piece_active(idx, true)


func _apply_layer_transform(basis: Basis) -> void:
	for idx in _drag_layer:
		var node := _pieces[idx].get("node") as Node3D
		if node == null:
			continue
		var start_transform: Transform3D = _drag_start_transforms.get(idx, node.transform)
		node.transform = Transform3D(basis * start_transform.basis, basis * start_transform.origin)


func _end_drag() -> bool:
	if not _dragging:
		return false
	_dragging = false
	if _drag_axis < 0:
		_set_piece_active(_drag_piece, false)
		_reset_drag()
		return true
	if absf(_drag_angle) < deg_to_rad(28.0):
		_return_layer_to_start()
	else:
		_commit_layer_rotation(1 if _drag_angle >= 0.0 else -1)
	return true


func _return_layer_to_start() -> void:
	_is_snapping = true
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	for idx in _drag_layer:
		var node := _pieces[idx].get("node") as Node3D
		if node != null:
			tween.tween_property(node, "transform", _drag_start_transforms[idx], return_rotate_sec)
	tween.finished.connect(func() -> void: _finish_layer_motion(false, {}))


func _commit_layer_rotation(direction: int) -> void:
	_is_snapping = true
	var target_basis := Basis(_drag_axis_local, PI * 0.5 * float(direction))
	var target_slots: Dictionary = {}
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	for idx in _drag_layer:
		var start_slot := int(_drag_start_slots.get(idx, int(_pieces[idx].get("slot", 0))))
		var target_slot := _slot_index_from_sign(_rotate_sign_quarter(_slot_sign(start_slot), _drag_axis, direction))
		target_slots[idx] = target_slot
		var node := _pieces[idx].get("node") as Node3D
		if node != null:
			var start_transform: Transform3D = _drag_start_transforms.get(idx, node.transform)
			var target_transform := Transform3D(target_basis * start_transform.basis, _slot_position(target_slot))
			tween.tween_property(node, "transform", target_transform, snap_rotate_sec)
	tween.finished.connect(func() -> void: _finish_layer_motion(true, target_slots))


func _finish_layer_motion(committed: bool, target_slots: Dictionary) -> void:
	for idx in _drag_layer:
		_pieces[idx]["is_drag_layer"] = false
		_set_piece_active(idx, false)
		if committed and target_slots.has(idx):
			_pieces[idx]["slot"] = int(target_slots[idx])
			var node := _pieces[idx].get("node") as Node3D
			if node != null:
				node.position = _slot_position(int(target_slots[idx]))
	_is_snapping = false
	if committed:
		_sync_stage_instruments()
		_flash_stage(Color(0.64, 0.82, 1.0, 0.34), 0.22)
	_update_match_feedback(false)
	_reset_drag()


func _reset_drag() -> void:
	_drag_piece = -1
	_drag_axis = -1
	_drag_side = 1.0
	_drag_layer.clear()
	_drag_start_transforms.clear()
	_drag_start_slots.clear()
	_drag_axis_local = Vector3.UP
	_drag_tangent_screen = Vector2.RIGHT
	_drag_angle = 0.0


func _pieces_on_layer(axis: int, side: float) -> Array[int]:
	var result: Array[int] = []
	for i in range(_pieces.size()):
		var slot := int(_pieces[i].get("slot", 0))
		if is_equal_approx(_axis_value(_slot_sign(slot), axis), side):
			result.append(i)
	return result


func _pick_piece_at_screen_position(screen_pos: Vector2) -> int:
	var container_rect := left_3d.get_global_rect()
	if not container_rect.has_point(screen_pos):
		return -1
	var best := -1
	var best_dist := INF
	for i in range(_pieces.size()):
		var node := _pieces[i].get("node") as Node3D
		if node == null:
			continue
		var world_pos := node.global_transform.origin
		if camera_3d.is_position_behind(world_pos):
			continue
		var p := container_rect.position + camera_3d.unproject_position(world_pos)
		var dist := p.distance_to(screen_pos)
		if dist < best_dist and dist <= click_pick_radius_px:
			best_dist = dist
			best = i
	return best


func _set_piece_active(piece_index: int, active: bool) -> void:
	if piece_index < 0 or piece_index >= _pieces.size():
		return
	_pieces[piece_index]["active_target"] = 1.0 if active else 0.0


func _update_piece_groups(delta: float) -> void:
	for i in range(_pieces.size()):
		var item := _pieces[i]
		var node := item.get("node") as Node3D
		if node == null:
			continue
		var active := lerpf(float(item.get("active", 0.0)), float(item.get("active_target", 0.0)), 1.0 - exp(-delta * 8.0))
		var matched := lerpf(float(item.get("matched", 0.0)), float(item.get("matched_target", 0.0)), 1.0 - exp(-delta * 4.0))
		_pieces[i]["active"] = active
		_pieces[i]["matched"] = matched
		_update_cells(i, active, matched)

		if bool(item.get("is_drag_layer", false)) or _completed_once:
			continue
		var slot := int(item.get("slot", 0))
		var phase := float(item.get("phase", 0.0))
		var speed := float(item.get("speed", 1.0))
		var pulse := sin(_time_sec * speed + phase)
		var settle := lerpf(1.0, 0.28, matched)
		var pos := _slot_position(slot) * lerpf(1.0, 0.72, matched)
		pos += _slot_sign(slot).normalized() * pulse * group_idle_motion * settle
		node.position = node.position.lerp(pos, 1.0 - exp(-delta * 5.5))


func _update_cells(piece_index: int, active: float, matched: float) -> void:
	var shards: Array = _pieces[piece_index].get("shards", [])
	for shard_variant in shards:
		var cell := shard_variant as Node3D
		if cell == null:
			continue
		var base_pos: Vector3 = cell.get_meta("base_pos", cell.position)
		var base_rot: Vector3 = cell.get_meta("base_rot", cell.rotation)
		var phase := float(cell.get_meta("phase", 0.0))
		var speed := float(cell.get_meta("speed", 1.0))
		var amp := float(cell.get_meta("amp", 0.012))
		var pulse := sin(_time_sec * speed + phase)
		var tremor := sin(_time_sec * (speed * 2.7 + 0.4) + phase)
		var live_amp := amp * (1.0 + active * 0.3) * (1.0 - matched * 0.45)
		cell.position = base_pos + base_pos.normalized() * pulse * live_amp
		cell.rotation = base_rot + Vector3(tremor, pulse, tremor * 0.6) * 0.018
		for child in cell.get_children():
			if child is MeshInstance3D:
				var mesh := child as MeshInstance3D
				if mesh.name == "WhiteOutline":
					mesh.scale = Vector3.ONE * (1.075 + active * 0.035 + matched * 0.02)
					var outline_mat := mesh.material_override as StandardMaterial3D
					if outline_mat != null:
						outline_mat.emission_energy_multiplier = 0.38 + active * 0.48 + matched * 0.32 + maxf(0.0, pulse) * 0.08
				else:
					var mat := mesh.material_override as StandardMaterial3D
					if mat != null:
						mat.emission_energy_multiplier = 0.08 + active * 0.12 + matched * 0.10 + maxf(0.0, pulse) * 0.05


func _start_audition() -> void:
	if _is_snapping or _is_auditioning or _completed_once:
		return
	_is_auditioning = true
	var matched_count := 0
	for i in range(TARGET_INSTRUMENTS.size()):
		var ok := _stage_instrument_at_slot(i) == TARGET_INSTRUMENTS[i]
		_matched[i] = ok
		if ok:
			matched_count += 1
	_update_match_feedback(true)
	_play_audition_motion()
	_flash_stage(Color(1.0, 0.88, 0.55, 0.36), audition_sec * 0.5)
	var t := get_tree().create_timer(audition_sec)
	t.timeout.connect(
		func() -> void:
			_is_auditioning = false
			if matched_count == TARGET_INSTRUMENTS.size():
				_start_final_performance()
	)


func _play_audition_motion() -> void:
	for i in range(DOLL_NODE_NAMES.size()):
		var doll := stage_root.get_node_or_null(DOLL_NODE_NAMES[i]) as TextureRect
		if doll == null:
			continue
		var start_pos := doll.position
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		if bool(_matched[i]):
			tween.tween_property(doll, "rotation", deg_to_rad(1.6), audition_sec * 0.25)
			tween.tween_property(doll, "rotation", deg_to_rad(-1.0), audition_sec * 0.25)
			tween.tween_property(doll, "rotation", 0.0, audition_sec * 0.25)
		else:
			tween.tween_property(doll, "position:x", start_pos.x + 8.0, audition_sec * 0.12)
			tween.tween_property(doll, "position:x", start_pos.x - 6.0, audition_sec * 0.12)
			tween.tween_property(doll, "position:x", start_pos.x, audition_sec * 0.12)


func _update_match_feedback(from_audition: bool) -> void:
	var matched_count := 0
	for slot in range(TARGET_INSTRUMENTS.size()):
		var ok := _stage_instrument_at_slot(slot) == TARGET_INSTRUMENTS[slot]
		if ok:
			matched_count += 1
		var confirmed := bool(_matched[slot]) and from_audition or ok
		if slot < _foot_lights.size():
			_foot_lights[slot].color = Color(1.0, 0.82, 0.38, 0.82) if confirmed else Color(0.24, 0.42, 0.62, 0.28)
		if slot < _stage_icons.size():
			_stage_icons[slot].modulate = Color(1.0, 0.95, 0.72, 1.0) if confirmed else Color(0.78, 0.86, 1.0, 0.82)
		var piece_index := _piece_at_slot(slot)
		if piece_index >= 0:
			_pieces[piece_index]["matched_target"] = 1.0 if confirmed else 0.0
	var warm_lights := mini(_top_lights.size(), int(ceil(float(matched_count) / 2.0)))
	for i in range(_top_lights.size()):
		_top_lights[i].color = Color(1.0, 0.78, 0.42, 0.72) if i < warm_lights else Color(0.72, 0.86, 1.0, 0.22)
	if _progress_label != null:
		_progress_label.text = "完整编排" if matched_count == 8 else "%d / 8" % matched_count


func _flash_stage(color: Color, duration: float) -> void:
	if _stage_flash == null:
		return
	_stage_flash.color = color
	var tween := create_tween()
	tween.tween_property(_stage_flash, "color:a", 0.0, maxf(0.08, duration))


func _are_all_matched() -> bool:
	for i in range(TARGET_INSTRUMENTS.size()):
		if _stage_instrument_at_slot(i) != TARGET_INSTRUMENTS[i]:
			return false
	return true


func _start_final_performance() -> void:
	if _completed_once:
		return
	_completed_once = true
	for i in range(_matched.size()):
		_matched[i] = true
	_update_match_feedback(true)
	_flash_stage(Color(1.0, 0.95, 0.78, 0.82), 1.2)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for i in range(_pieces.size()):
		var node := _pieces[i].get("node") as Node3D
		if node == null:
			continue
		tween.tween_property(node, "position", _slot_position(int(_pieces[i].get("slot", 0))) * 0.34, 1.2)
		tween.tween_property(node, "scale", Vector3.ONE * 0.94, 1.2)
	tween.finished.connect(
		func() -> void:
			var hold := get_tree().create_timer(0.35)
			hold.timeout.connect(func() -> void: chapter_completed.emit(chapter_index))
	)


func _slot_position(slot_index: int) -> Vector3:
	return _slot_sign(slot_index).normalized() * slot_radius


func _slot_sign(slot_index: int) -> Vector3:
	return _extract_sign_from_chunk_name(CHUNK_NODE_ORDER[clampi(slot_index, 0, CHUNK_NODE_ORDER.size() - 1)])


func _slot_index_from_sign(sign_vec: Vector3) -> int:
	for i in range(CHUNK_NODE_ORDER.size()):
		var s := _slot_sign(i)
		if is_equal_approx(s.x, sign_vec.x) and is_equal_approx(s.y, sign_vec.y) and is_equal_approx(s.z, sign_vec.z):
			return i
	return 0


func _extract_sign_from_chunk_name(node_name: String) -> Vector3:
	var parts := node_name.split("_")
	if parts.size() < 4:
		return Vector3.ONE
	return Vector3(
		-1.0 if parts[1] == "n1" else 1.0,
		-1.0 if parts[2] == "n1" else 1.0,
		-1.0 if parts[3] == "n1" else 1.0
	)


func _axis_local_vector(axis: int) -> Vector3:
	match axis:
		0:
			return Vector3.RIGHT
		1:
			return Vector3.UP
		_:
			return Vector3.FORWARD


func _axis_value(v: Vector3, axis: int) -> float:
	match axis:
		0:
			return v.x
		1:
			return v.y
		_:
			return v.z


func _rotate_sign_quarter(sign_vec: Vector3, axis: int, direction: int) -> Vector3:
	var x := sign_vec.x
	var y := sign_vec.y
	var z := sign_vec.z
	if direction >= 0:
		match axis:
			0:
				return Vector3(x, -z, y)
			1:
				return Vector3(z, y, -x)
			_:
				return Vector3(-y, x, z)
	match axis:
		0:
			return Vector3(x, z, -y)
		1:
			return Vector3(-z, y, x)
		_:
			return Vector3(y, -x, z)


func _update_rotation_input(delta: float) -> void:
	if _is_snapping or _is_auditioning or _completed_once or _dragging:
		return
	var direction := 0.0
	if Input.is_key_pressed(KEY_A):
		direction -= 1.0
	if Input.is_key_pressed(KEY_D):
		direction += 1.0
	if direction == 0.0:
		return
	chunk_root.rotate_y(deg_to_rad(manual_rotate_speed_deg) * direction * delta)
