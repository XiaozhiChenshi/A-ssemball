extends RefCounted
class_name StructureShapeProvider

const StructureOffLoaderRef = preload("res://scripts/structure/structure_off_loader.gd")
const StructureMeshBuilderRef = preload("res://scripts/structure/structure_mesh_builder.gd")
const StructureShapeDataRef = preload("res://scripts/structure/structure_shape_data.gd")
const StructureCellDataRef = preload("res://scripts/structure/structure_cell_data.gd")
const GOLDBERG_OFF_BASE_PATH := "res://assets/generated/goldberg"

var _cache: Dictionary = {}
var _off_loader
var _mesh_builder


func _init() -> void:
	_off_loader = StructureOffLoaderRef.new()
	_mesh_builder = StructureMeshBuilderRef.new()


func get_shape(shape_id: String, radius: float = 1.0):
	var normalized_id := shape_id.strip_edges().to_lower()
	match normalized_id:
		"dodecahedron":
			return get_dodecahedron(radius)
		"icosahedron":
			return get_icosahedron(radius)
		_:
			var parsed := _parse_goldberg_shape_id(normalized_id)
			if parsed.get("valid", false):
				return get_goldberg(parsed.get("m", 0), parsed.get("n", 0), radius)

	push_error("Unsupported structure shape id: %s" % shape_id)
	return StructureShapeDataRef.new()


func get_dodecahedron(radius: float = 1.0):
	return _get_or_build(_cache_key("dodecahedron", radius), func():
		return _build_dodecahedron(radius)
	)


func get_icosahedron(radius: float = 1.0):
	return _get_or_build(_cache_key("icosahedron", radius), func():
		return _build_icosahedron(radius)
	)


func get_goldberg(m: int, n: int, radius: float = 1.0):
	var mm := maxi(0, m)
	var nn := maxi(0, n)
	var shape_name := "goldberg_%d_%d" % [mm, nn]
	return _get_or_build(_cache_key(shape_name, radius), func():
		return _load_goldberg_from_off(mm, nn, radius)
	)


func clear_cache() -> void:
	_cache.clear()


func _get_or_build(cache_key: String, builder: Callable):
	if _cache.has(cache_key):
		return _cache[cache_key]

	var shape_data
	shape_data = builder.call()
	_cache[cache_key] = shape_data
	return shape_data


func _cache_key(shape_name: String, radius: float) -> String:
	return "%s@%d" % [shape_name, roundi(radius * 1000000.0)]


func _parse_goldberg_shape_id(shape_id: String) -> Dictionary:
	if shape_id.begins_with("goldberg:"):
		var parts := shape_id.split(":")
		if parts.size() == 3 and parts[1].is_valid_int() and parts[2].is_valid_int():
			return {
				"valid": true,
				"m": int(parts[1]),
				"n": int(parts[2]),
			}

	if shape_id.begins_with("g(") and shape_id.ends_with(")"):
		var body := shape_id.substr(2, shape_id.length() - 3)
		var parts := body.split(",")
		if parts.size() == 2 and parts[0].is_valid_int() and parts[1].is_valid_int():
			return {
				"valid": true,
				"m": int(parts[0]),
				"n": int(parts[1]),
			}

	return {"valid": false}


func _build_dodecahedron(radius: float):
	var phi := (1.0 + sqrt(5.0)) * 0.5
	var inv_phi := 1.0 / phi
	var vertices: Array[Vector3] = [
		Vector3(1, 1, 1), Vector3(1, 1, -1), Vector3(1, -1, 1), Vector3(1, -1, -1),
		Vector3(-1, 1, 1), Vector3(-1, 1, -1), Vector3(-1, -1, 1), Vector3(-1, -1, -1),
		Vector3(0, inv_phi, phi), Vector3(0, inv_phi, -phi), Vector3(0, -inv_phi, phi), Vector3(0, -inv_phi, -phi),
		Vector3(inv_phi, phi, 0), Vector3(inv_phi, -phi, 0), Vector3(-inv_phi, phi, 0), Vector3(-inv_phi, -phi, 0),
		Vector3(phi, 0, inv_phi), Vector3(phi, 0, -inv_phi), Vector3(-phi, 0, inv_phi), Vector3(-phi, 0, -inv_phi)
	]
	var faces: Array[PackedInt32Array] = [
		PackedInt32Array([0, 16, 2, 10, 8]),
		PackedInt32Array([0, 8, 4, 14, 12]),
		PackedInt32Array([16, 17, 1, 12, 0]),
		PackedInt32Array([1, 9, 5, 14, 12]),
		PackedInt32Array([1, 17, 3, 11, 9]),
		PackedInt32Array([2, 13, 3, 17, 16]),
		PackedInt32Array([2, 10, 6, 15, 13]),
		PackedInt32Array([3, 13, 15, 7, 11]),
		PackedInt32Array([4, 8, 10, 6, 18]),
		PackedInt32Array([5, 19, 7, 11, 9]),
		PackedInt32Array([4, 18, 19, 5, 14]),
		PackedInt32Array([6, 18, 19, 7, 15])
	]
	return _build_polyhedral_shape("dodecahedron", "Dodecahedron", "platonic", radius, vertices, faces)


func _build_icosahedron(radius: float):
	var phi := (1.0 + sqrt(5.0)) * 0.5
	var vertices: Array[Vector3] = [
		Vector3(-1, phi, 0),
		Vector3(1, phi, 0),
		Vector3(-1, -phi, 0),
		Vector3(1, -phi, 0),
		Vector3(0, -1, phi),
		Vector3(0, 1, phi),
		Vector3(0, -1, -phi),
		Vector3(0, 1, -phi),
		Vector3(phi, 0, -1),
		Vector3(phi, 0, 1),
		Vector3(-phi, 0, -1),
		Vector3(-phi, 0, 1),
	]
	var faces: Array[PackedInt32Array] = [
		PackedInt32Array([0, 11, 5]),
		PackedInt32Array([0, 5, 1]),
		PackedInt32Array([0, 1, 7]),
		PackedInt32Array([0, 7, 10]),
		PackedInt32Array([0, 10, 11]),
		PackedInt32Array([1, 5, 9]),
		PackedInt32Array([5, 11, 4]),
		PackedInt32Array([11, 10, 2]),
		PackedInt32Array([10, 7, 6]),
		PackedInt32Array([7, 1, 8]),
		PackedInt32Array([3, 9, 4]),
		PackedInt32Array([3, 4, 2]),
		PackedInt32Array([3, 2, 6]),
		PackedInt32Array([3, 6, 8]),
		PackedInt32Array([3, 8, 9]),
		PackedInt32Array([4, 9, 5]),
		PackedInt32Array([2, 4, 11]),
		PackedInt32Array([6, 2, 10]),
		PackedInt32Array([8, 6, 7]),
		PackedInt32Array([9, 8, 1]),
	]
	return _build_polyhedral_shape("icosahedron", "Icosahedron", "platonic", radius, vertices, faces)


func _build_polyhedral_shape(
	shape_key: String,
	display_label: String,
	topology_kind: String,
	radius: float,
	source_vertices: Array[Vector3],
	faces: Array[PackedInt32Array]
):
	var vertices := _scale_vertices_to_radius(source_vertices, radius)

	var shape_data: Object = StructureShapeDataRef.new()
	shape_data.set("shape_key", shape_key)
	shape_data.set("display_label", display_label)
	shape_data.set("topology_kind", topology_kind)
	shape_data.set("radius", radius)
	var cells: Array = shape_data.get("cells") as Array

	for face in faces:
		if face.size() < 3:
			continue

		var polygon := PackedVector3Array()
		for vertex_index in face:
			polygon.append(vertices[vertex_index])

		var mesh_center := Vector3.ZERO
		for point in polygon:
			mesh_center += point
		mesh_center /= float(polygon.size())

		var cell: Object = StructureCellDataRef.new()
		cell.set("id", cells.size())
		cell.set("center", mesh_center)
		cell.set("mesh_center", mesh_center)
		cell.set("normal", mesh_center.normalized())
		cell.set("polygon", polygon)
		cell.set("cell_kind", _cell_kind_from_size(polygon.size()))
		cells.append(cell)

	_mesh_builder.build_meshes(shape_data)
	return shape_data


func _scale_vertices_to_radius(source_vertices: Array[Vector3], radius: float) -> Array[Vector3]:
	var max_length := 0.0
	for vertex in source_vertices:
		max_length = maxf(max_length, vertex.length())

	var scale := radius / maxf(0.000001, max_length)
	var result: Array[Vector3] = []
	result.resize(source_vertices.size())
	for i in range(source_vertices.size()):
		result[i] = source_vertices[i] * scale
	return result


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


func _load_goldberg_from_off(m: int, n: int, radius: float):
	var off_path := "%s/g_%d_%d.off" % [GOLDBERG_OFF_BASE_PATH, m, n]
	if not FileAccess.file_exists(off_path):
		push_error("Goldberg OFF asset missing: %s" % off_path)
		return StructureShapeDataRef.new()

	return _off_loader.load_shape_from_off(
		off_path,
		"goldberg_%d_%d" % [m, n],
		"G(%d,%d)" % [m, n],
		"goldberg",
		radius,
		m,
		n
	)
