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
	Vector2(0.50, 0.4583),
	Vector2(0.46, 0.42),
	Vector2(0.50, 0.45),
	Vector2(0.50, 0.45),
	Vector2(0.50, 0.40),
	Vector2(0.48, 0.44),
	Vector2(0.50, 0.4575),
	Vector2(0.50, 0.45),
]
const HOLD_ICON_SIZES: Dictionary = {
	"baton": Vector2(62.0, 110.0),
	"violin": Vector2(96.0, 78.0),
	"piano": Vector2(116.0, 92.0),
	"snare": Vector2(88.0, 78.0),
	"harp": Vector2(78.0, 122.0),
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
	"snare",
	"triangle",
	"violin",
	"flute",
	"piano",
	"tuba",
	"harp",
	"baton",
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
const CELL_OUTER_RADIUS: float = 0.88
const SHARD_CUT_GAP_SCALE: float = 0.84
const SHARD_GROUP_SEPARATION: float = 0.11
const SHARD_CUT_DAMAGE: float = 0.018
const SHARD_OUTLINE_SCALE_MAIN: float = 1.038
const SHARD_OUTLINE_SCALE_SECONDARY: float = 1.028
const RANDOM_FLASH_ATTACK_SEC: float = 0.95
const RANDOM_FLASH_DECAY_SEC: float = 0.55
const MATCH_FLASH_PERIOD_SEC: float = 1.05
const MATCH_FLASH_ATTACK_RATIO: float = 0.52

@export var chapter_index: int = 2
@export_range(0.2, 2.0, 0.01) var slot_radius: float = 0.54
@export_range(0.0, 240.0, 0.1) var manual_rotate_speed_deg: float = 68.0
@export_range(0.1, 0.9, 0.01) var left_panel_width_ratio: float = 0.25
@export_range(8.0, 240.0, 1.0) var click_pick_radius_px: float = 86.0
@export_range(12.0, 240.0, 1.0) var drag_rotate_threshold_px: float = 34.0
@export_range(0.05, 1.5, 0.01) var snap_rotate_sec: float = 0.24
@export_range(0.05, 1.5, 0.01) var return_rotate_sec: float = 0.18
@export_range(0.05, 1.5, 0.01) var audition_sec: float = 0.72
@export_range(0.0, 0.12, 0.001) var group_idle_motion: float = 0.018
@export_range(0.2, 2.4, 0.01) var swap_sec: float = 1.15
@export var lock_scene_actor_positions: bool = true

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
var _is_swapping: bool = false
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
var _selected_piece: int = -1
var _fixed_doll_rects: Array[Rect2] = []
var _fixed_icon_rects: Array[Rect2] = []
var _initial_instruments_runtime: Array[String] = []


func _ready() -> void:
	_rng.randomize()
	_initial_instruments_runtime = INITIAL_INSTRUMENTS.duplicate()
	_initial_instruments_runtime.shuffle()
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
	call_deferred("_sync_stage_instruments")


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
		node.transform = Transform3D(Basis.IDENTITY, Vector3.ZERO)
		_pieces.append(
			{
				"node": node,
				"home_slot": i,
				"slot": i,
				"instrument": _initial_instruments_runtime[i],
				"phase": _rng.randf_range(0.0, TAU),
				"speed": _rng.randf_range(0.55, 1.25),
				"active_target": 0.0,
				"active": 0.0,
				"selected_target": 0.0,
				"selected": 0.0,
				"matched_target": 0.0,
				"matched": 0.0,
				"is_drag_layer": false,
				"is_swap_piece": false,
				"swap_progress": 0.0,
				"swap_side": 1.0,
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

	var sign := _slot_sign(piece_index)
	var shard_descriptors := _shard_descriptors_for_piece(piece_index)
	for i in range(shard_descriptors.size()):
		var cell := Node3D.new()
		cell.name = "Cell_%02d" % i
		var descriptor: Dictionary = shard_descriptors[i]
		var is_main := bool(descriptor.get("main", false))
		var build_data := _build_shard_vertex_data(sign, piece_index, i, descriptor)
		var radial_dir: Vector3 = build_data.get("radial_dir", sign.normalized())
		cell.position = build_data.get("center", Vector3.ZERO)
		cell.rotation = Vector3.ZERO
		cell.set_meta("is_main", is_main)
		cell.set_meta("base_pos", cell.position)
		cell.set_meta("radial_dir", radial_dir)
		cell.set_meta("base_rot", cell.rotation)
		cell.set_meta("phase", _rng.randf_range(0.0, TAU))
		cell.set_meta("speed", _rng.randf_range(0.65, 1.9))
		cell.set_meta("amp", _rng.randf_range(0.006, 0.014) if is_main else _rng.randf_range(0.012, 0.03))
		cell.set_meta("flash_offset", _rng.randf_range(0.0, 18.0))
		cell.set_meta("flash_period", _rng.randf_range(13.0, 20.0))
		cell.set_meta("swap_delay", _rng.randf_range(0.0, 0.32))
		root.add_child(cell)

		var mesh_instance := MeshInstance3D.new()
		mesh_instance.name = "Solid"
		var mesh := _build_shard_mesh(build_data.get("verts", []))
		mesh_instance.mesh = mesh
		mesh_instance.material_override = _create_solid_cell_material()
		cell.add_child(mesh_instance)

		var outline := MeshInstance3D.new()
		outline.name = "WhiteOutline"
		outline.mesh = mesh
		outline.scale = Vector3.ONE * (SHARD_OUTLINE_SCALE_MAIN if is_main else SHARD_OUTLINE_SCALE_SECONDARY)
		outline.material_override = _create_outline_material(is_main)
		cell.add_child(outline)

	return root


func _range2(a: float, b: float) -> Vector2:
	return Vector2(a, b)


func _shard_desc(x: Vector2, y: Vector2, z: Vector2, main: bool) -> Dictionary:
	return {
		"x": x,
		"y": y,
		"z": z,
		"main": main,
	}


func _shard_descriptors_for_piece(piece_index: int) -> Array[Dictionary]:
	var patterns := [
		[
			_shard_desc(_range2(0.05, 0.55), _range2(0.05, 0.62), _range2(0.05, 0.58), true),
			_shard_desc(_range2(0.48, 0.94), _range2(0.12, 0.54), _range2(0.08, 0.50), true),
			_shard_desc(_range2(0.18, 0.42), _range2(0.58, 0.98), _range2(0.20, 0.52), false),
			_shard_desc(_range2(0.18, 0.44), _range2(0.16, 0.48), _range2(0.55, 0.98), false),
			_shard_desc(_range2(0.58, 0.96), _range2(0.58, 0.92), _range2(0.42, 0.74), false),
			_shard_desc(_range2(0.70, 1.00), _range2(0.20, 0.44), _range2(0.58, 0.90), false),
		],
		[
			_shard_desc(_range2(0.05, 0.50), _range2(0.05, 0.52), _range2(0.05, 0.70), true),
			_shard_desc(_range2(0.44, 0.96), _range2(0.08, 0.42), _range2(0.10, 0.56), true),
			_shard_desc(_range2(0.42, 0.86), _range2(0.44, 0.92), _range2(0.48, 0.96), true),
			_shard_desc(_range2(0.08, 0.36), _range2(0.58, 0.98), _range2(0.12, 0.46), false),
			_shard_desc(_range2(0.10, 0.34), _range2(0.24, 0.58), _range2(0.70, 0.98), false),
			_shard_desc(_range2(0.68, 1.00), _range2(0.20, 0.46), _range2(0.60, 0.90), false),
			_shard_desc(_range2(0.62, 0.92), _range2(0.62, 0.96), _range2(0.12, 0.42), false),
		],
		[
			_shard_desc(_range2(0.08, 0.60), _range2(0.10, 0.55), _range2(0.08, 0.56), true),
			_shard_desc(_range2(0.22, 0.78), _range2(0.50, 0.98), _range2(0.16, 0.58), true),
			_shard_desc(_range2(0.60, 0.96), _range2(0.10, 0.38), _range2(0.18, 0.52), false),
			_shard_desc(_range2(0.10, 0.42), _range2(0.20, 0.50), _range2(0.58, 0.98), false),
			_shard_desc(_range2(0.48, 0.86), _range2(0.56, 0.92), _range2(0.56, 0.92), false),
			_shard_desc(_range2(0.72, 1.00), _range2(0.62, 0.94), _range2(0.24, 0.54), false),
		],
		[
			_shard_desc(_range2(0.05, 0.48), _range2(0.05, 0.64), _range2(0.05, 0.50), true),
			_shard_desc(_range2(0.42, 0.92), _range2(0.30, 0.86), _range2(0.15, 0.60), true),
			_shard_desc(_range2(0.16, 0.50), _range2(0.12, 0.46), _range2(0.54, 0.98), false),
			_shard_desc(_range2(0.54, 0.92), _range2(0.08, 0.36), _range2(0.56, 0.92), false),
			_shard_desc(_range2(0.08, 0.34), _range2(0.68, 0.98), _range2(0.28, 0.58), false),
			_shard_desc(_range2(0.62, 1.00), _range2(0.64, 0.96), _range2(0.54, 0.92), false),
			_shard_desc(_range2(0.78, 1.00), _range2(0.18, 0.42), _range2(0.16, 0.42), false),
		],
		[
			_shard_desc(_range2(0.10, 0.64), _range2(0.06, 0.50), _range2(0.08, 0.66), true),
			_shard_desc(_range2(0.56, 0.98), _range2(0.42, 0.96), _range2(0.16, 0.58), true),
			_shard_desc(_range2(0.16, 0.46), _range2(0.56, 0.96), _range2(0.12, 0.42), false),
			_shard_desc(_range2(0.14, 0.42), _range2(0.18, 0.48), _range2(0.68, 1.00), false),
			_shard_desc(_range2(0.52, 0.86), _range2(0.12, 0.38), _range2(0.62, 0.94), false),
			_shard_desc(_range2(0.72, 1.00), _range2(0.62, 0.92), _range2(0.58, 0.88), false),
		],
		[
			_shard_desc(_range2(0.04, 0.52), _range2(0.08, 0.58), _range2(0.08, 0.52), true),
			_shard_desc(_range2(0.36, 0.88), _range2(0.10, 0.48), _range2(0.44, 0.96), true),
			_shard_desc(_range2(0.50, 0.98), _range2(0.54, 0.98), _range2(0.14, 0.54), true),
			_shard_desc(_range2(0.12, 0.38), _range2(0.62, 0.98), _range2(0.24, 0.54), false),
			_shard_desc(_range2(0.12, 0.36), _range2(0.18, 0.46), _range2(0.58, 0.92), false),
			_shard_desc(_range2(0.68, 1.00), _range2(0.18, 0.42), _range2(0.14, 0.40), false),
			_shard_desc(_range2(0.70, 0.98), _range2(0.68, 0.96), _range2(0.58, 0.90), false),
		],
		[
			_shard_desc(_range2(0.06, 0.58), _range2(0.08, 0.62), _range2(0.10, 0.54), true),
			_shard_desc(_range2(0.50, 0.98), _range2(0.18, 0.72), _range2(0.34, 0.86), true),
			_shard_desc(_range2(0.16, 0.46), _range2(0.12, 0.44), _range2(0.60, 0.98), false),
			_shard_desc(_range2(0.16, 0.42), _range2(0.68, 0.98), _range2(0.22, 0.52), false),
			_shard_desc(_range2(0.58, 0.90), _range2(0.74, 1.00), _range2(0.48, 0.78), false),
			_shard_desc(_range2(0.74, 1.00), _range2(0.22, 0.50), _range2(0.08, 0.36), false),
		],
		[
			_shard_desc(_range2(0.08, 0.52), _range2(0.08, 0.52), _range2(0.08, 0.62), true),
			_shard_desc(_range2(0.44, 0.96), _range2(0.10, 0.58), _range2(0.10, 0.48), true),
			_shard_desc(_range2(0.20, 0.76), _range2(0.48, 0.98), _range2(0.48, 0.96), true),
			_shard_desc(_range2(0.12, 0.42), _range2(0.62, 0.96), _range2(0.12, 0.42), false),
			_shard_desc(_range2(0.14, 0.40), _range2(0.22, 0.52), _range2(0.66, 1.00), false),
			_shard_desc(_range2(0.66, 1.00), _range2(0.18, 0.44), _range2(0.56, 0.92), false),
			_shard_desc(_range2(0.70, 0.98), _range2(0.70, 0.98), _range2(0.18, 0.48), false),
			_shard_desc(_range2(0.50, 0.78), _range2(0.46, 0.74), _range2(0.12, 0.36), false),
		],
	]
	var selected: Array[Dictionary] = []
	for descriptor in patterns[piece_index % patterns.size()]:
		selected.append(descriptor)
	return selected


func _jitter_range(r: Vector2, piece_index: int, shard_index: int, axis: int) -> Vector2:
	var width := r.y - r.x
	var limit := minf(0.018, width * 0.08)
	var low := r.x + _signed_noise(piece_index, shard_index, axis * 2) * limit
	var high := r.y + _signed_noise(piece_index, shard_index, axis * 2 + 1) * limit
	low = clampf(low, 0.0, r.y - width * 0.55)
	high = clampf(high, low + width * 0.55, 1.0)
	return Vector2(low, high)


func _build_shard_vertex_data(sign: Vector3, piece_index: int, shard_index: int, descriptor: Dictionary) -> Dictionary:
	var rx := _jitter_range(descriptor.get("x", Vector2.ZERO), piece_index, shard_index, 0)
	var ry := _jitter_range(descriptor.get("y", Vector2.ZERO), piece_index, shard_index, 1)
	var rz := _jitter_range(descriptor.get("z", Vector2.ZERO), piece_index, shard_index, 2)
	var raw_verts: Array[Vector3] = []
	for z in range(2):
		for y in range(2):
			for x in range(2):
				var local := Vector3(
					rx.x if x == 0 else rx.y,
					ry.x if y == 0 else ry.y,
					rz.x if z == 0 else rz.y
				)
				var p := Vector3(sign.x * local.x, sign.y * local.y, sign.z * local.z)
				var curved := _cube_to_sphere(p) * CELL_OUTER_RADIUS
				var damage := _vertex_damage(sign, piece_index, shard_index, raw_verts.size(), curved)
				raw_verts.append(_constrain_to_octant_ball(curved + damage, sign))

	var center := Vector3.ZERO
	for v in raw_verts:
		center += v
	center /= float(raw_verts.size())

	var group_offset := sign.normalized() * SHARD_GROUP_SEPARATION
	center += group_offset

	var relative_verts: Array[Vector3] = []
	for v in raw_verts:
		var gapped := center + (v + group_offset - center) * SHARD_CUT_GAP_SCALE
		relative_verts.append(gapped - center)
	return {
		"center": center,
		"verts": relative_verts,
		"radial_dir": center.normalized(),
	}


func _vertex_damage(sign: Vector3, piece_index: int, shard_index: int, corner_index: int, base_point: Vector3) -> Vector3:
	var radial := base_point.normalized()
	var tangent_a := radial.cross(Vector3.UP)
	if tangent_a.length() < 0.01:
		tangent_a = radial.cross(Vector3.RIGHT)
	tangent_a = tangent_a.normalized()
	var tangent_b := radial.cross(tangent_a).normalized()
	var n0 := _signed_noise(piece_index, shard_index, corner_index)
	var n1 := _signed_noise(piece_index + 3, shard_index, corner_index + 5)
	var n2 := _signed_noise(piece_index + 7, shard_index, corner_index + 11)
	return tangent_a * n0 * SHARD_CUT_DAMAGE + tangent_b * n1 * SHARD_CUT_DAMAGE + radial * n2 * SHARD_CUT_DAMAGE * 0.35


func _signed_noise(a: int, b: int, c: int) -> float:
	var x := sin(float(a * 127 + b * 311 + c * 719) * 12.9898) * 43758.5453
	return (x - floor(x)) * 2.0 - 1.0


func _constrain_to_octant_ball(point: Vector3, sign: Vector3) -> Vector3:
	point.x = maxf(0.0, point.x * sign.x) * sign.x
	point.y = maxf(0.0, point.y * sign.y) * sign.y
	point.z = maxf(0.0, point.z * sign.z) * sign.z
	if point.length() > CELL_OUTER_RADIUS:
		point = point.normalized() * CELL_OUTER_RADIUS
	return point


func _cube_to_sphere(p: Vector3) -> Vector3:
	var x2 := p.x * p.x
	var y2 := p.y * p.y
	var z2 := p.z * p.z
	return Vector3(
		p.x * sqrt(maxf(0.0, 1.0 - y2 * 0.5 - z2 * 0.5 + y2 * z2 / 3.0)),
		p.y * sqrt(maxf(0.0, 1.0 - z2 * 0.5 - x2 * 0.5 + z2 * x2 / 3.0)),
		p.z * sqrt(maxf(0.0, 1.0 - x2 * 0.5 - y2 * 0.5 + x2 * y2 / 3.0))
	)


func _build_shard_mesh(verts: Array) -> ArrayMesh:
	var faces := [
		[0, 1, 3, 2],
		[4, 6, 7, 5],
		[0, 4, 5, 1],
		[2, 3, 7, 6],
		[0, 2, 6, 4],
		[1, 5, 7, 3],
	]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face in faces:
		_add_outward_quad(st, verts[face[0]], verts[face[1]], verts[face[2]], verts[face[3]])
	return st.commit()


func _add_outward_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	var center := (a + b + c + d) * 0.25
	var normal := (b - a).cross(c - a)
	if normal.dot(center) > 0.0:
		_add_quad(st, a, d, c, b)
	else:
		_add_quad(st, a, b, c, d)


func _add_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	var n := (b - a).cross(c - a).normalized()
	st.set_normal(n)
	st.add_vertex(a)
	st.set_normal(n)
	st.add_vertex(b)
	st.set_normal(n)
	st.add_vertex(c)
	st.set_normal(n)
	st.add_vertex(a)
	st.set_normal(n)
	st.add_vertex(c)
	st.set_normal(n)
	st.add_vertex(d)


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


func _create_outline_material(is_main: bool) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.94, 0.97, 1.0, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.9, 0.96, 1.0, 1.0)
	mat.emission_energy_multiplier = 0.42 if is_main else 0.34
	mat.cull_mode = BaseMaterial3D.CULL_FRONT
	mat.no_depth_test = false
	return mat


func _setup_stage_runtime_ui() -> void:
	if stage_root.get_node_or_null("StageFlash") != null:
		_foot_lights.clear()
		_top_lights.clear()
		_stage_icons.clear()
		_stage_flash = stage_root.get_node("StageFlash") as ColorRect
		for i in range(8):
			var foot := stage_root.get_node_or_null("FootLight_%d" % i) as ColorRect
			if foot != null:
				_foot_lights.append(foot)
		for i in range(4):
			var top := stage_root.get_node_or_null("TopLight_%d" % i) as ColorRect
			if top != null:
				_top_lights.append(top)
		for i in range(8):
			var icon := stage_root.get_node_or_null("StageInstrument_%d" % i) as TextureRect
			if icon != null:
				_stage_icons.append(icon)
		_progress_label = right_panel.get_node_or_null("ProgressLabel") as Label
		_audition_button = right_panel.get_node_or_null("AuditionButton") as Button
		if _audition_button != null and not _audition_button.pressed.is_connected(_start_audition):
			_audition_button.pressed.connect(_start_audition)
		_cache_scene_actor_layout()
		return

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
	_cache_scene_actor_layout()


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
			doll.visible = true
			if lock_scene_actor_positions and i < _fixed_doll_rects.size():
				var fixed_doll := _fixed_doll_rects[i]
				doll.position = fixed_doll.position
				doll.size = fixed_doll.size
			else:
				var base_rect := DOLL_BASE_RECTS[i]
				doll.position = base_rect.position * scale
				doll.size = base_rect.size * scale

		var instrument_id := _stage_instrument_at_slot(i)
		var icon := _stage_icons[i]
		icon.visible = true
		if lock_scene_actor_positions and i < _fixed_icon_rects.size():
			var fixed_icon := _fixed_icon_rects[i]
			icon.position = fixed_icon.position
			icon.size = fixed_icon.size
		else:
			var icon_size: Vector2 = HOLD_ICON_SIZES.get(instrument_id, Vector2(100.0, 86.0)) * scale
			var icon_pos := Vector2.ZERO
			if doll != null:
				icon_pos = doll.position + doll.size * HOLD_ICON_ANCHORS[i]
			else:
				icon_pos = Vector2(130.0 + float(i % 4) * 200.0, 140.0 + float(i / 4) * 260.0) * scale
			icon.position = icon_pos - icon_size * 0.5
			icon.size = icon_size
		icon.move_to_front()

		var foot := _foot_lights[i]
		var foot_pos := icon.position + Vector2(icon.size.x * 0.5 - 48.0 * scale.x, 126.0 * scale.y)
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


func _cache_scene_actor_layout() -> void:
	_fixed_doll_rects.clear()
	_fixed_icon_rects.clear()
	for i in range(DOLL_NODE_NAMES.size()):
		var doll := stage_root.get_node_or_null(DOLL_NODE_NAMES[i]) as TextureRect
		if doll == null:
			_fixed_doll_rects.append(Rect2())
		else:
			_fixed_doll_rects.append(Rect2(doll.position, doll.size))
	for i in range(_stage_icons.size()):
		var icon := _stage_icons[i]
		_fixed_icon_rects.append(Rect2(icon.position, icon.size))


func _stage_scale() -> Vector2:
	return Vector2(right_panel.size.x / 960.0, right_panel.size.y / 720.0)


func _sync_stage_instruments() -> void:
	for slot_index in range(_stage_icons.size()):
		var instrument_id := _stage_instrument_at_slot(slot_index)
		_stage_icons[slot_index].texture = INSTRUMENT_TEXTURES.get(instrument_id)
		_stage_icons[slot_index].visible = true
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


func _build_stage_moves_for_rotation(target_basis: Basis) -> Array[Dictionary]:
	var moves: Array[Dictionary] = []
	for idx in _drag_layer:
		var node := _pieces[idx].get("node") as Node3D
		if node == null:
			continue
		var start_slot := int(_drag_start_slots.get(idx, int(_pieces[idx].get("slot", 0))))
		var start_transform: Transform3D = _drag_start_transforms.get(idx, node.transform)
		var target_slot := _slot_index_from_basis(idx, target_basis * start_transform.basis)
		if start_slot == target_slot:
			continue
		moves.append(
			{
				"from": start_slot,
				"to": target_slot,
				"instrument": String(_pieces[idx].get("instrument", "")),
			}
		)
	return moves


func _animate_stage_rotation(moves: Array[Dictionary]) -> void:
	if moves.is_empty() or _stage_icons.is_empty():
		return
	var scale := _stage_scale()
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for move in moves:
		var from_slot := int(move.get("from", -1))
		var to_slot := int(move.get("to", -1))
		var instrument_id := String(move.get("instrument", ""))
		if from_slot < 0 or from_slot >= _stage_icons.size() or to_slot < 0 or to_slot >= DOLL_BASE_RECTS.size():
			continue
		var source_icon := _stage_icons[from_slot]
		var ghost := TextureRect.new()
		ghost.name = "StageMoveGhost"
		ghost.texture = INSTRUMENT_TEXTURES.get(instrument_id)
		ghost.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		ghost.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ghost.position = source_icon.position
		ghost.size = source_icon.size
		ghost.modulate = Color(1.0, 1.0, 1.0, 0.92)
		stage_root.add_child(ghost)
		ghost.move_to_front()
		source_icon.modulate.a = 0.22
		var target_pos := _stage_icon_position_for_slot(to_slot, instrument_id, scale)
		var target_size: Vector2 = HOLD_ICON_SIZES.get(instrument_id, Vector2(100.0, 86.0)) * scale
		if lock_scene_actor_positions and to_slot >= 0 and to_slot < _fixed_icon_rects.size():
			target_size = _fixed_icon_rects[to_slot].size
		tween.tween_property(ghost, "position", target_pos, snap_rotate_sec)
		tween.tween_property(ghost, "size", target_size, snap_rotate_sec)
		tween.tween_property(ghost, "modulate:a", 0.0, snap_rotate_sec).set_delay(snap_rotate_sec * 0.72)
		tween.tween_callback(_free_stage_move_ghost.bind(ghost)).set_delay(snap_rotate_sec)


func _stage_icon_position_for_slot(slot_index: int, instrument_id: String, scale: Vector2) -> Vector2:
	if lock_scene_actor_positions and slot_index >= 0 and slot_index < _fixed_icon_rects.size():
		return _fixed_icon_rects[slot_index].position
	var icon_size: Vector2 = HOLD_ICON_SIZES.get(instrument_id, Vector2(100.0, 86.0)) * scale
	var doll_rect := DOLL_BASE_RECTS[clampi(slot_index, 0, DOLL_BASE_RECTS.size() - 1)]
	var doll_pos := doll_rect.position * scale
	var doll_size := doll_rect.size * scale
	var icon_center := doll_pos + doll_size * HOLD_ICON_ANCHORS[clampi(slot_index, 0, HOLD_ICON_ANCHORS.size() - 1)]
	return icon_center - icon_size * 0.5


func _free_stage_move_ghost(ghost: TextureRect) -> void:
	if is_instance_valid(ghost):
		ghost.queue_free()


func _begin_drag(screen_pos: Vector2) -> bool:
	if _is_snapping or _is_auditioning or _is_swapping:
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
	var piece_world := _piece_visual_center(_drag_piece)
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
		node.transform = Transform3D(basis * start_transform.basis, Vector3.ZERO)


func _end_drag() -> bool:
	if not _dragging:
		return false
	_dragging = false
	if _drag_axis < 0:
		var clicked_piece := _drag_piece
		_set_piece_active(clicked_piece, false)
		_reset_drag()
		_handle_piece_click(clicked_piece)
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
	var stage_moves := _build_stage_moves_for_rotation(target_basis)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	for idx in _drag_layer:
		var node := _pieces[idx].get("node") as Node3D
		if node != null:
			var start_transform: Transform3D = _drag_start_transforms.get(idx, node.transform)
			var target_transform := Transform3D(target_basis * start_transform.basis, Vector3.ZERO)
			target_slots[idx] = _slot_index_from_basis(idx, target_transform.basis)
			tween.tween_property(node, "transform", target_transform, snap_rotate_sec)
	_animate_stage_rotation(stage_moves)
	tween.finished.connect(func() -> void: _finish_layer_motion(true, target_slots))


func _finish_layer_motion(committed: bool, target_slots: Dictionary) -> void:
	for idx in _drag_layer:
		_pieces[idx]["is_drag_layer"] = false
		_set_piece_active(idx, false)
		if committed and target_slots.has(idx):
			_pieces[idx]["slot"] = int(target_slots[idx])
			var node := _pieces[idx].get("node") as Node3D
			if node != null:
				node.position = Vector3.ZERO
	_is_snapping = false
	if committed:
		_sync_stage_instruments()
		_flash_stage(Color(0.64, 0.82, 1.0, 0.34), 0.22)
	_update_match_feedback(false)
	_reset_drag()


func _start_piece_swap(first: int, second: int) -> void:
	if first < 0 or second < 0 or first >= _pieces.size() or second >= _pieces.size() or first == second:
		return
	_is_swapping = true
	_is_snapping = true
	_pieces[first]["is_swap_piece"] = true
	_pieces[second]["is_swap_piece"] = true
	_pieces[first]["swap_progress"] = 0.0
	_pieces[second]["swap_progress"] = 0.0
	_pieces[first]["swap_side"] = 1.0
	_pieces[second]["swap_side"] = -1.0
	var first_slot := int(_pieces[first].get("slot", 0))
	var second_slot := int(_pieces[second].get("slot", 0))
	var first_node := _pieces[first].get("node") as Node3D
	var second_node := _pieces[second].get("node") as Node3D
	if first_node == null or second_node == null:
		_is_swapping = false
		_is_snapping = false
		return
	var first_target_basis := _basis_between_dirs(_slot_sign(first_slot), _slot_sign(second_slot)) * first_node.transform.basis
	var second_target_basis := _basis_between_dirs(_slot_sign(second_slot), _slot_sign(first_slot)) * second_node.transform.basis
	var stage_moves: Array[Dictionary] = [
		{"from": first_slot, "to": second_slot, "instrument": String(_pieces[first].get("instrument", ""))},
		{"from": second_slot, "to": first_slot, "instrument": String(_pieces[second].get("instrument", ""))},
	]
	_animate_stage_rotation(stage_moves)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(func(v: float) -> void: _pieces[first]["swap_progress"] = v, 0.0, 1.0, swap_sec)
	tween.tween_method(func(v: float) -> void: _pieces[second]["swap_progress"] = v, 0.0, 1.0, swap_sec)
	tween.tween_property(first_node, "transform", Transform3D(first_target_basis, Vector3.ZERO), swap_sec)
	tween.tween_property(second_node, "transform", Transform3D(second_target_basis, Vector3.ZERO), swap_sec)
	tween.finished.connect(func() -> void: _finish_piece_swap(first, second, first_slot, second_slot))


func _finish_piece_swap(first: int, second: int, first_slot: int, second_slot: int) -> void:
	_pieces[first]["slot"] = second_slot
	_pieces[second]["slot"] = first_slot
	for idx in [first, second]:
		_pieces[idx]["is_swap_piece"] = false
		_pieces[idx]["swap_progress"] = 0.0
		_set_piece_selected(idx, false)
		var node := _pieces[idx].get("node") as Node3D
		if node != null:
			node.position = Vector3.ZERO
	_selected_piece = -1
	_is_swapping = false
	_is_snapping = false
	_sync_stage_instruments()
	_update_match_feedback(false)


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
		var world_pos := _piece_visual_center(i)
		if camera_3d.is_position_behind(world_pos):
			continue
		var p := container_rect.position + camera_3d.unproject_position(world_pos)
		var dist := p.distance_to(screen_pos)
		if dist < best_dist and dist <= click_pick_radius_px:
			best_dist = dist
			best = i
	return best


func _piece_visual_center(piece_index: int) -> Vector3:
	if piece_index < 0 or piece_index >= _pieces.size():
		return Vector3.ZERO
	var node := _pieces[piece_index].get("node") as Node3D
	if node == null:
		return Vector3.ZERO
	var home_slot := int(_pieces[piece_index].get("home_slot", piece_index))
	return node.global_transform * _slot_position(home_slot)


func _set_piece_active(piece_index: int, active: bool) -> void:
	if piece_index < 0 or piece_index >= _pieces.size():
		return
	_pieces[piece_index]["active_target"] = 1.0 if active else 0.0


func _handle_piece_click(piece_index: int) -> void:
	if piece_index < 0 or piece_index >= _pieces.size() or _is_snapping or _is_auditioning or _is_swapping or _completed_once:
		return
	if _selected_piece == piece_index:
		_set_piece_selected(piece_index, false)
		_selected_piece = -1
		return
	if _selected_piece < 0:
		_selected_piece = piece_index
		_set_piece_selected(piece_index, true)
		return
	var first := _selected_piece
	var second := piece_index
	_set_piece_selected(second, true)
	_start_piece_swap(first, second)


func _set_piece_selected(piece_index: int, selected: bool) -> void:
	if piece_index < 0 or piece_index >= _pieces.size():
		return
	_pieces[piece_index]["selected_target"] = 1.0 if selected else 0.0


func _clear_piece_selection() -> void:
	if _selected_piece >= 0:
		_set_piece_selected(_selected_piece, false)
	_selected_piece = -1
	for i in range(_pieces.size()):
		if bool(_pieces[i].get("is_swap_piece", false)):
			_set_piece_selected(i, false)


func _update_piece_groups(delta: float) -> void:
	for i in range(_pieces.size()):
		var item := _pieces[i]
		var node := item.get("node") as Node3D
		if node == null:
			continue
		var active := lerpf(float(item.get("active", 0.0)), float(item.get("active_target", 0.0)), 1.0 - exp(-delta * 8.0))
		var selected := lerpf(float(item.get("selected", 0.0)), float(item.get("selected_target", 0.0)), 1.0 - exp(-delta * 5.0))
		var matched := lerpf(float(item.get("matched", 0.0)), float(item.get("matched_target", 0.0)), 1.0 - exp(-delta * 4.0))
		var is_correct := float(item.get("matched_target", 0.0)) > 0.5
		_pieces[i]["active"] = active
		_pieces[i]["selected"] = selected
		_pieces[i]["matched"] = matched
		_update_cells(i, active, selected, matched, is_correct)

		if bool(item.get("is_drag_layer", false)) or _completed_once:
			continue
		node.position = node.position.lerp(Vector3.ZERO, 1.0 - exp(-delta * 8.0))


func _update_cells(piece_index: int, active: float, selected: float, matched: float, is_correct: bool) -> void:
	var shards: Array = _pieces[piece_index].get("shards", [])
	for shard_variant in shards:
		var cell := shard_variant as Node3D
		if cell == null:
			continue
		var base_pos: Vector3 = cell.get_meta("base_pos", cell.position)
		var radial_dir: Vector3 = cell.get_meta("radial_dir", Vector3.UP)
		var base_rot: Vector3 = cell.get_meta("base_rot", cell.rotation)
		var phase := float(cell.get_meta("phase", 0.0))
		var speed := float(cell.get_meta("speed", 1.0))
		var amp := float(cell.get_meta("amp", 0.012))
		var pulse := sin(_time_sec * speed + phase)
		var tremor := sin(_time_sec * (speed * 2.7 + 0.4) + phase)
		var live_amp := amp * (1.0 + active * 0.3) * (1.0 - matched * 0.45)
		var swap_offset := _swap_cell_offset(piece_index, cell, radial_dir)
		var random_flash := _random_flash_value(cell) if not is_correct else 0.0
		var match_flash := _matched_flash_value() if is_correct else 0.0
		var flash := maxf(random_flash, match_flash)
		var selected_offset := radial_dir * selected * (0.045 if bool(cell.get_meta("is_main", false)) else 0.072)
		cell.position = base_pos + radial_dir * pulse * live_amp + selected_offset + swap_offset
		cell.rotation = base_rot + Vector3(tremor, pulse, tremor * 0.6) * (0.018 + selected * 0.01)
		for child in cell.get_children():
			if child is MeshInstance3D:
				var mesh := child as MeshInstance3D
				if mesh.name == "WhiteOutline":
					var outline_mat := mesh.material_override as StandardMaterial3D
					if outline_mat != null:
						var is_main := bool(cell.get_meta("is_main", false))
						var base_scale := SHARD_OUTLINE_SCALE_MAIN if is_main else SHARD_OUTLINE_SCALE_SECONDARY
						var base_energy := 0.42 if is_main else 0.34
						mesh.scale = Vector3.ONE * (base_scale + active * 0.008 + selected * 0.01 + matched * 0.006 + flash * 0.012)
						var match_boost := match_flash
						outline_mat.emission_energy_multiplier = base_energy + active * 0.28 + selected * 0.42 + matched * 0.1 + maxf(0.0, pulse) * 0.06 + random_flash * 0.74 + match_boost * 1.18
						outline_mat.albedo_color = Color(0.94, 0.97, 1.0, 1.0).lerp(Color.WHITE, selected * 0.28 + random_flash * 0.45 + match_boost * 0.72)
						outline_mat.emission = Color(0.9, 0.96, 1.0, 1.0).lerp(Color.WHITE, selected * 0.32 + random_flash * 0.6 + match_boost * 0.86)
				else:
					var mat := mesh.material_override as StandardMaterial3D
					if mat != null:
						var body_flash := selected * 0.36 + random_flash * 0.72 + match_flash * 0.92
						mat.albedo_color = Color(0.075, 0.084, 0.092, 1.0).lerp(Color(0.86, 0.9, 0.94, 1.0), body_flash)
						mat.emission = Color(0.02, 0.08, 0.095, 1.0).lerp(Color(0.8, 0.9, 1.0, 1.0), body_flash)
						mat.emission_energy_multiplier = 0.08 + active * 0.12 + selected * 0.26 + matched * 0.06 + maxf(0.0, pulse) * 0.05 + random_flash * 0.55 + match_flash * 0.86


func _swap_cell_offset(piece_index: int, cell: Node3D, radial_dir: Vector3) -> Vector3:
	if not bool(_pieces[piece_index].get("is_swap_piece", false)):
		return Vector3.ZERO
	var progress := float(_pieces[piece_index].get("swap_progress", 0.0))
	var delay := float(cell.get_meta("swap_delay", 0.0))
	var p := clampf((progress - delay * 0.42) / (1.0 - delay * 0.42), 0.0, 1.0)
	var arc := sin(PI * p)
	var side := float(_pieces[piece_index].get("swap_side", 1.0))
	var tangent := radial_dir.cross(Vector3.UP)
	if tangent.length() < 0.01:
		tangent = radial_dir.cross(Vector3.RIGHT)
	tangent = tangent.normalized()
	var weave := sin(TAU * (p + delay)) * 0.055
	return radial_dir * arc * 0.34 + tangent * side * arc * (0.18 + weave)


func _random_flash_value(cell: Node3D) -> float:
	var period := float(cell.get_meta("flash_period", 16.0))
	var offset := float(cell.get_meta("flash_offset", 0.0))
	var duration := RANDOM_FLASH_ATTACK_SEC + RANDOM_FLASH_DECAY_SEC
	var t := fmod(_time_sec + offset, period)
	if t > duration:
		return 0.0
	if t <= RANDOM_FLASH_ATTACK_SEC:
		var k := t / RANDOM_FLASH_ATTACK_SEC
		return smoothstep(0.0, 1.0, k)
	var d := (t - RANDOM_FLASH_ATTACK_SEC) / RANDOM_FLASH_DECAY_SEC
	return 1.0 - smoothstep(0.0, 1.0, d)


func _matched_flash_value() -> float:
	var t := fmod(_time_sec, MATCH_FLASH_PERIOD_SEC) / MATCH_FLASH_PERIOD_SEC
	if t <= MATCH_FLASH_ATTACK_RATIO:
		return smoothstep(0.0, 1.0, t / MATCH_FLASH_ATTACK_RATIO)
	return 1.0 - smoothstep(0.0, 1.0, (t - MATCH_FLASH_ATTACK_RATIO) / (1.0 - MATCH_FLASH_ATTACK_RATIO))


func _start_audition() -> void:
	if _is_snapping or _is_auditioning or _completed_once:
		return
	_is_auditioning = true
	var matched_count := _update_match_feedback(true)
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


func _update_match_feedback(_from_audition: bool) -> int:
	var matched_count := 0
	var slot_correct: Array[bool] = []
	for slot in range(TARGET_INSTRUMENTS.size()):
		slot_correct.append(false)
	for i in range(_pieces.size()):
		var slot := int(_pieces[i].get("slot", -1))
		var ok := slot >= 0 and slot < TARGET_INSTRUMENTS.size() and String(_pieces[i].get("instrument", "")) == TARGET_INSTRUMENTS[slot]
		_pieces[i]["matched_target"] = 1.0 if ok else 0.0
		if ok and slot < slot_correct.size():
			slot_correct[slot] = true
	for slot in range(TARGET_INSTRUMENTS.size()):
		var ok := bool(slot_correct[slot])
		if ok:
			matched_count += 1
		if slot < _matched.size():
			_matched[slot] = ok
		if slot < _foot_lights.size():
			_foot_lights[slot].color = Color(1.0, 0.82, 0.38, 0.82) if ok else Color(0.24, 0.42, 0.62, 0.28)
		if slot < _stage_icons.size():
			_stage_icons[slot].modulate = Color(1.0, 0.95, 0.72, 1.0) if ok else Color(0.78, 0.86, 1.0, 0.82)
	for i in range(_top_lights.size()):
		_top_lights[i].color = Color(0.72, 0.86, 1.0, 0.22)
	if _progress_label != null:
		_progress_label.text = "完整编排" if matched_count == 8 else "%d / 8" % matched_count


	return matched_count


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


func _slot_index_from_basis(piece_index: int, basis: Basis) -> int:
	var home_slot := int(_pieces[piece_index].get("home_slot", piece_index))
	var visual_dir := basis * _slot_sign(home_slot)
	return _slot_index_from_sign(Vector3(
		-1.0 if visual_dir.x < 0.0 else 1.0,
		-1.0 if visual_dir.y < 0.0 else 1.0,
		-1.0 if visual_dir.z < 0.0 else 1.0
	))


func _basis_between_dirs(from_dir: Vector3, to_dir: Vector3) -> Basis:
	var from_n := from_dir.normalized()
	var to_n := to_dir.normalized()
	var dot := clampf(from_n.dot(to_n), -1.0, 1.0)
	if dot > 0.999:
		return Basis.IDENTITY
	var axis := from_n.cross(to_n)
	if axis.length() < 0.001:
		axis = from_n.cross(Vector3.UP)
		if axis.length() < 0.001:
			axis = from_n.cross(Vector3.RIGHT)
	axis = axis.normalized()
	return Basis(axis, acos(dot))


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
