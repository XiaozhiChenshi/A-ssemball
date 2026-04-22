extends RefCounted
class_name GoldbergTopologyGenerator

const StructureMeshBuilderRef = preload("res://scripts/structure/structure_mesh_builder.gd")
const StructureShapeDataRef = preload("res://scripts/structure/structure_shape_data.gd")
const StructureCellDataRef = preload("res://scripts/structure/structure_cell_data.gd")

const VERTEX_KEY_PRECISION: float = 1000000.0
var _mesh_builder


func _init() -> void:
	_mesh_builder = StructureMeshBuilderRef.new()


func generate_shape(m: int, n: int, radius: float = 1.0):
	var mm := maxi(0, m)
	var nn := maxi(0, n)
	if mm == 0 and nn == 0:
		push_error("GoldbergTopologyGenerator requires m and n not both zero.")
		return StructureShapeDataRef.new()

	var triangulated := _build_geodesic_triangulation(mm, nn, radius)
	return _build_dual_shape_data(mm, nn, radius, triangulated.vertices, triangulated.triangles)


func _build_geodesic_triangulation(m: int, n: int, radius: float) -> Dictionary:
	var vertices := PackedVector3Array()
	var triangles: Array[PackedInt32Array] = []
	var global_vertex_map: Dictionary = {}

	var base_vertices := _get_icosahedron_vertices(radius)
	var base_faces := _get_icosahedron_faces()

	for face in base_faces:
		var a := base_vertices[face[0]]
		var b := base_vertices[face[1]]
		var c := base_vertices[face[2]]
		var local_points := _build_face_lattice_points(a, b, c, m, n, radius, vertices, global_vertex_map)
		_append_face_triangles(local_points, vertices, triangles)

	return {
		"vertices": vertices,
		"triangles": triangles,
	}


func _build_face_lattice_points(
	a: Vector3,
	b: Vector3,
	c: Vector3,
	m: int,
	n: int,
	radius: float,
	vertices: PackedVector3Array,
	global_vertex_map: Dictionary
) -> Dictionary:
	var local_points: Dictionary = {}
	var u := Vector2i(m, n)
	var v := Vector2i(-n, m + n)
	var total := float(m * m + m * n + n * n)

	var min_x := mini(0, mini(u.x, v.x))
	var max_x := maxi(0, maxi(u.x, v.x))
	var min_y := mini(0, mini(u.y, v.y))
	var max_y := maxi(0, maxi(u.y, v.y))

	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			var alpha_num := (m + n) * x + n * y
			var beta_num := -n * x + m * y
			if alpha_num < 0 or beta_num < 0:
				continue
			if alpha_num + beta_num > int(total):
				continue

			var alpha := float(alpha_num) / total
			var beta := float(beta_num) / total
			var point := (a * (1.0 - alpha - beta) + b * alpha + c * beta).normalized() * radius
			var vertex_key := _vec_key(point)
			var global_index := -1
			if global_vertex_map.has(vertex_key):
				global_index = global_vertex_map[vertex_key] as int
			else:
				global_index = vertices.size()
				vertices.append(point)
				global_vertex_map[vertex_key] = global_index

			local_points[Vector2i(x, y)] = global_index

	return local_points


func _append_face_triangles(
	local_points: Dictionary,
	vertices: PackedVector3Array,
	triangles: Array[PackedInt32Array]
) -> void:
	for key in local_points.keys():
		var point := key as Vector2i
		var right := point + Vector2i(1, 0)
		var up := point + Vector2i(0, 1)
		var diagonal := point + Vector2i(1, 1)

		if local_points.has(right) and local_points.has(up):
			triangles.append(_make_oriented_triangle(
				local_points[point] as int,
				local_points[right] as int,
				local_points[up] as int,
				vertices
			))

		if local_points.has(right) and local_points.has(diagonal) and local_points.has(up):
			triangles.append(_make_oriented_triangle(
				local_points[right] as int,
				local_points[diagonal] as int,
				local_points[up] as int,
				vertices
			))


func _make_oriented_triangle(
	a_index: int,
	b_index: int,
	c_index: int,
	vertices: PackedVector3Array
) -> PackedInt32Array:
	var a := vertices[a_index]
	var b := vertices[b_index]
	var c := vertices[c_index]
	if (b - a).cross(c - a).dot((a + b + c) / 3.0) < 0.0:
		return PackedInt32Array([a_index, c_index, b_index])
	return PackedInt32Array([a_index, b_index, c_index])


func _build_dual_shape_data(
	m: int,
	n: int,
	radius: float,
	vertices: PackedVector3Array,
	triangles: Array[PackedInt32Array]
):
	var triangle_centers := PackedVector3Array()
	var incident_triangles: Array = []
	incident_triangles.resize(vertices.size())
	for vertex_index in range(vertices.size()):
		incident_triangles[vertex_index] = []

	for triangle_index in range(triangles.size()):
		var tri := triangles[triangle_index]
		var center := (
			vertices[tri[0]] +
			vertices[tri[1]] +
			vertices[tri[2]]
		) / 3.0
		triangle_centers.append(center.normalized() * radius)

		(incident_triangles[tri[0]] as Array).append(triangle_index)
		(incident_triangles[tri[1]] as Array).append(triangle_index)
		(incident_triangles[tri[2]] as Array).append(triangle_index)

	var shape_data: Object = StructureShapeDataRef.new()
	shape_data.set("shape_key", "goldberg_%d_%d" % [m, n])
	shape_data.set("display_label", "G(%d,%d)" % [m, n])
	shape_data.set("topology_kind", "goldberg")
	shape_data.set("m", m)
	shape_data.set("n", n)
	shape_data.set("radius", radius)
	var cells: Array = shape_data.get("cells") as Array

	for vertex_index in range(vertices.size()):
		var sorted_triangle_indices := _sort_incident_triangles(
			vertices[vertex_index],
			incident_triangles[vertex_index] as Array,
			triangle_centers
		)

		var polygon := PackedVector3Array()
		for triangle_index in sorted_triangle_indices:
			polygon.append(triangle_centers[triangle_index])

		if polygon.is_empty():
			continue

		var polygon_center := Vector3.ZERO
		for point in polygon:
			polygon_center += point
		polygon_center /= float(polygon.size())

		var cell: Object = StructureCellDataRef.new()
		cell.set("id", vertex_index)
		cell.set("center", polygon_center)
		cell.set("mesh_center", polygon_center)
		cell.set("normal", polygon_center.normalized())
		cell.set("polygon", polygon)
		cell.set("cell_kind", "pentagon" if polygon.size() == 5 else "hexagon" if polygon.size() == 6 else "polygon_%d" % polygon.size())
		cells.append(cell)

	_mesh_builder.build_meshes(shape_data)
	return shape_data


func _sort_incident_triangles(
	vertex: Vector3,
	incident: Array,
	triangle_centers: PackedVector3Array
) -> Array[int]:
	var tangent_x := vertex.cross(Vector3.UP)
	if tangent_x.length_squared() < 0.000001:
		tangent_x = vertex.cross(Vector3.RIGHT)
	tangent_x = tangent_x.normalized()
	var tangent_y := vertex.cross(tangent_x).normalized()

	var sortable: Array[Dictionary] = []
	for triangle_index in incident:
		var center := triangle_centers[triangle_index as int]
		var tangent := center - vertex * center.dot(vertex.normalized())
		if tangent.length_squared() > 0.000001:
			tangent = tangent.normalized()
		var angle := atan2(tangent.dot(tangent_y), tangent.dot(tangent_x))
		sortable.append({
			"triangle_index": triangle_index as int,
			"angle": angle,
		})

	sortable.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["angle"]) < float(b["angle"])
	)

	var result: Array[int] = []
	for entry in sortable:
		result.append(entry["triangle_index"] as int)
	return result


func _get_icosahedron_vertices(radius: float) -> PackedVector3Array:
	var phi := (1.0 + sqrt(5.0)) * 0.5
	var vertices := PackedVector3Array([
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
	])
	for i in range(vertices.size()):
		vertices[i] = vertices[i].normalized() * radius
	return vertices


func _get_icosahedron_faces() -> Array[PackedInt32Array]:
	return [
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


func _vec_key(v: Vector3) -> String:
	return "%d:%d:%d" % [
		int(round(v.x * VERTEX_KEY_PRECISION)),
		int(round(v.y * VERTEX_KEY_PRECISION)),
		int(round(v.z * VERTEX_KEY_PRECISION)),
	]
