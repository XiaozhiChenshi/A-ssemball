extends RefCounted
class_name StructureOffLoader

const StructureShapeDataRef = preload("res://scripts/structure/structure_shape_data.gd")
const StructureCellDataRef = preload("res://scripts/structure/structure_cell_data.gd")
const StructureMeshBuilderRef = preload("res://scripts/structure/structure_mesh_builder.gd")
const GOLDBERG_CONE_DEPTH_FROM_FACE_RADIUS: float = 0.22
const GOLDBERG_CONE_DEPTH_MIN_RADIUS_RATIO: float = 1.0 / 3.0

var _mesh_builder


func _init() -> void:
	_mesh_builder = StructureMeshBuilderRef.new()


func load_shape_from_off(
	off_path: String,
	shape_key: String,
	display_label: String,
	topology_kind: String,
	radius: float,
	m: int = -1,
	n: int = -1
):
	var parsed := _parse_off_file(off_path)
	if parsed.is_empty():
		return StructureShapeDataRef.new()

	var source_vertices: Array = parsed.get("vertices", []) as Array
	var faces: Array = parsed.get("faces", []) as Array
	var scaled_vertices := _scale_vertices_to_radius(source_vertices, radius)

	var shape_data: Object = StructureShapeDataRef.new()
	shape_data.set("shape_key", shape_key)
	shape_data.set("display_label", display_label)
	shape_data.set("topology_kind", topology_kind)
	shape_data.set("radius", radius)
	shape_data.set("m", m)
	shape_data.set("n", n)

	var cells: Array = shape_data.get("cells") as Array
	for face_variant in faces:
		var face: PackedInt32Array = face_variant as PackedInt32Array
		if face.size() < 3:
			continue

		var polygon := PackedVector3Array()
		for vertex_index in face:
			if vertex_index < 0 or vertex_index >= scaled_vertices.size():
				continue
			polygon.append(scaled_vertices[vertex_index])
		if polygon.size() < 3:
			continue

		var face_center := Vector3.ZERO
		for point in polygon:
			face_center += point
		face_center /= float(polygon.size())

		var normal := face_center.normalized()
		if normal.length_squared() < 0.000001:
			normal = _compute_face_normal(polygon)
		if normal.length_squared() < 0.000001:
			normal = Vector3.UP

		var mesh_center := face_center
		if topology_kind == "goldberg":
			mesh_center = _build_goldberg_cone_apex(face_center, polygon, radius)

		var cell: Object = StructureCellDataRef.new()
		cell.set("id", cells.size())
		cell.set("center", face_center)
		cell.set("mesh_center", mesh_center)
		cell.set("normal", normal)
		cell.set("polygon", polygon)
		cell.set("cell_kind", _cell_kind_from_size(polygon.size()))
		cells.append(cell)

	_mesh_builder.build_meshes(shape_data)
	return shape_data


func _parse_off_file(off_path: String) -> Dictionary:
	var file := FileAccess.open(off_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open OFF file: %s" % off_path)
		return {}

	var lines: Array[String] = []
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		lines.append(line)

	if lines.is_empty():
		push_error("OFF file is empty: %s" % off_path)
		return {}

	var index := 0
	var header := lines[index]
	index += 1
	if header != "OFF":
		push_error("Unsupported OFF header in %s: %s" % [off_path, header])
		return {}

	if index >= lines.size():
		push_error("Missing OFF counts line: %s" % off_path)
		return {}

	var counts_tokens := _tokenize_line(lines[index])
	index += 1
	if counts_tokens.size() < 2:
		push_error("Invalid OFF counts line: %s" % off_path)
		return {}

	var vertex_count := int(counts_tokens[0])
	var face_count := int(counts_tokens[1])
	var vertices: Array = []
	var faces: Array = []

	for _vertex_i in range(vertex_count):
		if index >= lines.size():
			push_error("Unexpected end of OFF vertex data: %s" % off_path)
			return {}
		var vertex_tokens := _tokenize_line(lines[index])
		index += 1
		if vertex_tokens.size() < 3:
			push_error("Invalid OFF vertex line in %s: %s" % [off_path, lines[index - 1]])
			return {}
		vertices.append(Vector3(
			float(vertex_tokens[0]),
			float(vertex_tokens[1]),
			float(vertex_tokens[2])
		))

	for _face_i in range(face_count):
		if index >= lines.size():
			push_error("Unexpected end of OFF face data: %s" % off_path)
			return {}
		var face_tokens := _tokenize_line(lines[index])
		index += 1
		if face_tokens.is_empty():
			continue

		var side_count := int(face_tokens[0])
		if face_tokens.size() < side_count + 1:
			push_error("Invalid OFF face line in %s: %s" % [off_path, lines[index - 1]])
			return {}

		var face := PackedInt32Array()
		for token_index in range(1, side_count + 1):
			face.append(int(face_tokens[token_index]))
		faces.append(face)

	return {
		"vertices": vertices,
		"faces": faces,
	}


func _tokenize_line(line: String) -> PackedStringArray:
	return line.replace("\t", " ").split(" ", false)


func _scale_vertices_to_radius(source_vertices: Array, radius: float) -> Array:
	var max_length := 0.0
	for vertex_variant in source_vertices:
		var vertex: Vector3 = vertex_variant as Vector3
		max_length = maxf(max_length, vertex.length())

	var scale := radius / maxf(0.000001, max_length)
	var result: Array = []
	result.resize(source_vertices.size())
	for i in range(source_vertices.size()):
		var source_vertex: Vector3 = source_vertices[i] as Vector3
		result[i] = source_vertex * scale
	return result


func _compute_face_normal(polygon: PackedVector3Array) -> Vector3:
	if polygon.size() < 3:
		return Vector3.ZERO
	var origin := polygon[0]
	var normal := Vector3.ZERO
	for i in range(1, polygon.size() - 1):
		normal += (polygon[i] - origin).cross(polygon[i + 1] - origin)
	return normal.normalized()


func _build_goldberg_cone_apex(face_center: Vector3, polygon: PackedVector3Array, shape_radius: float) -> Vector3:
	if face_center.length_squared() < 0.000001 or polygon.is_empty():
		return face_center

	var average_face_radius := 0.0
	for point in polygon:
		average_face_radius += point.distance_to(face_center)
	average_face_radius /= float(polygon.size())

	var inward_dir := -face_center.normalized()
	var cone_depth := maxf(
		average_face_radius * GOLDBERG_CONE_DEPTH_FROM_FACE_RADIUS,
		maxf(0.0, shape_radius) * GOLDBERG_CONE_DEPTH_MIN_RADIUS_RATIO
	)
	return face_center + inward_dir * cone_depth


func _cell_kind_from_size(side_count: int) -> String:
	match side_count:
		3:
			return "triangle"
		4:
			return "quad"
		5:
			return "pentagon"
		6:
			return "hexagon"
		_:
			return "polygon_%d" % side_count
