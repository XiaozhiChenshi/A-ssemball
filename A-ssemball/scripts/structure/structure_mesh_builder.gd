extends RefCounted
class_name StructureMeshBuilder

const EDGE_KEY_PRECISION: float = 1000000.0
const EDGE_WIDTH_FROM_LENGTH: float = 0.16
const EDGE_DEPTH_FROM_WIDTH: float = 0.42
const EDGE_MIN_RADIUS_RATIO: float = 0.008
const EDGE_MAX_RADIUS_RATIO: float = 0.045
const EDGE_SURFACE_LIFT_RATIO: float = 0.0025
const GOLDBERG_WAVE_DIRECTION: Vector3 = Vector3(0.36, 0.81, -0.47)
const GOLDBERG_DYNAMIC_EDGE_WIDTH_SCALE: float = 1.0 / 3.0
const GOLDBERG_SCAFFOLD_EDGE_WIDTH_SCALE: float = 0.42 / 3.0
const GOLDBERG_SCAFFOLD_EDGE_EXTRA_LIFT_RATIO: float = 0.0065


func build_meshes(shape_data: Object) -> void:
	_build_neighbors(shape_data)
	shape_data.set("body_mesh", _build_body_mesh(shape_data))
	if _is_goldberg_shape(shape_data):
		shape_data.set("edge_mesh", _build_goldberg_cone_edge_mesh(shape_data))
		shape_data.set(
			"static_edge_mesh",
			_build_scaffold_edge_mesh(
				shape_data,
				GOLDBERG_SCAFFOLD_EDGE_WIDTH_SCALE,
				GOLDBERG_SCAFFOLD_EDGE_EXTRA_LIFT_RATIO
			)
		)
	else:
		shape_data.set("edge_mesh", _build_scaffold_edge_mesh(shape_data, 1.0, 0.0))
		shape_data.set("static_edge_mesh", null)


func _build_neighbors(shape_data: Object) -> void:
	var cells: Array = _get_shape_cells(shape_data)
	var edge_to_cells: Dictionary = {}
	for cell_index in range(cells.size()):
		var cell: Object = cells[cell_index] as Object
		var poly: PackedVector3Array = _get_cell_polygon(cell)
		if poly.size() < 2:
			continue
		for vertex_index in range(poly.size()):
			var a := poly[vertex_index]
			var b := poly[(vertex_index + 1) % poly.size()]
			var edge_key := _edge_key_from_positions(a, b)
			if not edge_to_cells.has(edge_key):
				edge_to_cells[edge_key] = []
			(edge_to_cells[edge_key] as Array).append(cell_index)

	var neighbor_sets: Array[Dictionary] = []
	neighbor_sets.resize(cells.size())
	for i in range(neighbor_sets.size()):
		neighbor_sets[i] = {}

	for cell_indices in edge_to_cells.values():
		var owners := cell_indices as Array
		if owners.size() != 2:
			continue
		var a := owners[0] as int
		var b := owners[1] as int
		(neighbor_sets[a] as Dictionary)[b] = true
		(neighbor_sets[b] as Dictionary)[a] = true

	for cell_index in range(cells.size()):
		var ordered_neighbors := PackedInt32Array()
		for neighbor_id in (neighbor_sets[cell_index] as Dictionary).keys():
			ordered_neighbors.append(neighbor_id)
		ordered_neighbors.sort()
		var cell: Object = cells[cell_index] as Object
		cell.set("neighbors", ordered_neighbors)


func _build_body_mesh(shape_data: Object) -> ArrayMesh:
	var cells: Array = _get_shape_cells(shape_data)
	var is_goldberg := _is_goldberg_shape(shape_data)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for cell_variant in cells:
		var cell: Object = cell_variant as Object
		var poly: PackedVector3Array = _get_cell_polygon(cell)
		if poly.size() < 3:
			continue

		var cell_id := _get_cell_id(cell)
		var normal: Vector3 = _get_cell_normal(cell).normalized()
		var base_center: Vector3 = _get_cell_center(cell)
		var mesh_center: Vector3 = _get_cell_mesh_center(cell)
		var wave_phase := _get_cell_wave_phase(shape_data, cell)
		var wave_axis := _get_cell_wave_axis(cell)
		var wave_depth := _get_cell_wave_depth(cell)
		for vertex_index in range(poly.size()):
			var a := mesh_center
			var b := poly[vertex_index]
			var c := poly[(vertex_index + 1) % poly.size()]

			if (b - a).cross(c - a).dot(normal) < 0.0:
				var swap := b
				b = c
				c = swap

			_append_body_triangle(
				st,
				a,
				b,
				c,
				wave_phase,
				wave_depth,
				wave_axis,
				cell_id,
				is_goldberg
			)

		if is_goldberg:
			for vertex_index in range(poly.size()):
				var base_a := base_center
				var base_b := poly[vertex_index]
				var base_c := poly[(vertex_index + 1) % poly.size()]

				if (base_b - base_a).cross(base_c - base_a).dot(normal) < 0.0:
					var base_swap := base_b
					base_b = base_c
					base_c = base_swap

				_append_body_triangle(
					st,
					base_a,
					base_b,
					base_c,
					wave_phase,
					wave_depth,
					wave_axis,
					cell_id,
					true
				)

	return st.commit()


func _build_scaffold_edge_mesh(
	shape_data: Object,
	width_scale: float,
	extra_lift_ratio: float
) -> ArrayMesh:
	return _build_edge_mesh_from_segments(
		shape_data,
		_collect_unique_edges(shape_data),
		width_scale,
		false,
		extra_lift_ratio
	)


func _build_goldberg_cone_edge_mesh(shape_data: Object) -> ArrayMesh:
	return _build_edge_mesh_from_segments(
		shape_data,
		_collect_goldberg_cone_edge_segments(shape_data),
		GOLDBERG_DYNAMIC_EDGE_WIDTH_SCALE,
		true
	)


func _build_edge_mesh_from_segments(
	shape_data: Object,
	segments: Array[Dictionary],
	width_scale: float,
	use_metadata: bool,
	extra_lift_ratio: float = 0.0
) -> ArrayMesh:
	if segments.is_empty():
		return ArrayMesh.new()

	var average_edge_length := 0.0
	for segment in segments:
		var a := segment["a"] as Vector3
		var b := segment["b"] as Vector3
		average_edge_length += a.distance_to(b)
	average_edge_length /= float(segments.size())

	var shape_radius := _get_shape_radius(shape_data)
	var clamped_width_scale := maxf(0.05, width_scale)
	var edge_width := clampf(
		average_edge_length * EDGE_WIDTH_FROM_LENGTH * clamped_width_scale,
		shape_radius * EDGE_MIN_RADIUS_RATIO * clamped_width_scale,
		shape_radius * EDGE_MAX_RADIUS_RATIO * clamped_width_scale
	)
	var half_width := edge_width * 0.5
	var half_depth := half_width * EDGE_DEPTH_FROM_WIDTH
	var lift := half_depth + shape_radius * (EDGE_SURFACE_LIFT_RATIO + maxf(0.0, extra_lift_ratio))

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for segment in segments:
		if use_metadata:
			_append_edge_prism_with_metadata(
				st,
				segment["a"] as Vector3,
				segment["b"] as Vector3,
				half_width,
				half_depth,
				lift,
				float(segment["wave_phase"]),
				float(segment["wave_depth"]),
				segment["wave_axis"] as Vector3,
				int(segment["cell_id"])
			)
		else:
			_append_edge_prism(
				st,
				segment["a"] as Vector3,
				segment["b"] as Vector3,
				half_width,
				half_depth,
				lift
			)

	return st.commit()


func _collect_unique_edges(shape_data: Object) -> Array[Dictionary]:
	var cells: Array = _get_shape_cells(shape_data)
	var edges: Array[Dictionary] = []
	var edge_seen: Dictionary = {}
	for cell_variant in cells:
		var cell: Object = cell_variant as Object
		var poly: PackedVector3Array = _get_cell_polygon(cell)
		if poly.size() < 2:
			continue
		for vertex_index in range(poly.size()):
			var a := poly[vertex_index]
			var b := poly[(vertex_index + 1) % poly.size()]
			var edge_key := _edge_key_from_positions(a, b)
			if edge_seen.has(edge_key):
				continue
			edge_seen[edge_key] = true
			edges.append({
				"a": a,
				"b": b,
			})
	return edges


func _collect_goldberg_cone_edge_segments(shape_data: Object) -> Array[Dictionary]:
	var cells: Array = _get_shape_cells(shape_data)
	var segments: Array[Dictionary] = []

	for cell_variant in cells:
		var cell: Object = cell_variant as Object
		var poly: PackedVector3Array = _get_cell_polygon(cell)
		if poly.size() < 2:
			continue

		var apex := _get_cell_mesh_center(cell)
		var cell_id := _get_cell_id(cell)
		var wave_phase := _get_cell_wave_phase(shape_data, cell)
		var wave_axis := _get_cell_wave_axis(cell)
		var wave_depth := _get_cell_wave_depth(cell)

		for vertex_index in range(poly.size()):
			var a := poly[vertex_index]
			var b := poly[(vertex_index + 1) % poly.size()]
			segments.append({
				"a": a,
				"b": b,
				"wave_phase": wave_phase,
				"wave_depth": wave_depth,
				"wave_axis": wave_axis,
				"cell_id": cell_id,
			})

		for point in poly:
			segments.append({
				"a": point,
				"b": apex,
				"wave_phase": wave_phase,
				"wave_depth": wave_depth,
				"wave_axis": wave_axis,
				"cell_id": cell_id,
			})

	return segments


func _append_edge_prism(
	st: SurfaceTool,
	a: Vector3,
	b: Vector3,
	half_width: float,
	half_depth: float,
	lift: float
) -> void:
	var tangent := b - a
	if tangent.length_squared() < 0.000001:
		return
	tangent = tangent.normalized()

	var outward := (a.normalized() + b.normalized()) * 0.5
	if outward.length_squared() < 0.000001:
		outward = a.normalized()
	outward = outward.normalized()

	var side := tangent.cross(outward)
	if side.length_squared() < 0.000001:
		side = tangent.cross(Vector3.UP)
	if side.length_squared() < 0.000001:
		side = tangent.cross(Vector3.RIGHT)
	side = side.normalized()

	var depth_axis := side.cross(tangent)
	if depth_axis.length_squared() < 0.000001:
		depth_axis = outward
	depth_axis = depth_axis.normalized()

	var width_offset := side * half_width
	var depth_offset := depth_axis * half_depth
	var start_center := a + depth_axis * lift
	var end_center := b + depth_axis * lift

	var start_ring := PackedVector3Array([
		start_center + width_offset + depth_offset,
		start_center - width_offset + depth_offset,
		start_center - width_offset - depth_offset,
		start_center + width_offset - depth_offset,
	])
	var end_ring := PackedVector3Array([
		end_center + width_offset + depth_offset,
		end_center - width_offset + depth_offset,
		end_center - width_offset - depth_offset,
		end_center + width_offset - depth_offset,
	])

	for side_index in range(4):
		var next_index := (side_index + 1) % 4
		_append_quad(
			st,
			start_ring[side_index],
			end_ring[side_index],
			end_ring[next_index],
			start_ring[next_index]
		)

	_append_quad(st, start_ring[0], start_ring[1], start_ring[2], start_ring[3])
	_append_quad(st, end_ring[3], end_ring[2], end_ring[1], end_ring[0])


func _append_edge_prism_with_metadata(
	st: SurfaceTool,
	a: Vector3,
	b: Vector3,
	half_width: float,
	half_depth: float,
	lift: float,
	wave_phase: float,
	wave_depth: float,
	wave_axis: Vector3,
	cell_id: int
) -> void:
	var tangent := b - a
	if tangent.length_squared() < 0.000001:
		return
	tangent = tangent.normalized()

	var outward := (a.normalized() + b.normalized()) * 0.5
	if outward.length_squared() < 0.000001:
		outward = a.normalized()
	outward = outward.normalized()

	var side := tangent.cross(outward)
	if side.length_squared() < 0.000001:
		side = tangent.cross(Vector3.UP)
	if side.length_squared() < 0.000001:
		side = tangent.cross(Vector3.RIGHT)
	side = side.normalized()

	var depth_axis := side.cross(tangent)
	if depth_axis.length_squared() < 0.000001:
		depth_axis = outward
	depth_axis = depth_axis.normalized()

	var width_offset := side * half_width
	var depth_offset := depth_axis * half_depth
	var start_center := a + depth_axis * lift
	var end_center := b + depth_axis * lift

	var start_ring := PackedVector3Array([
		start_center + width_offset + depth_offset,
		start_center - width_offset + depth_offset,
		start_center - width_offset - depth_offset,
		start_center + width_offset - depth_offset,
	])
	var end_ring := PackedVector3Array([
		end_center + width_offset + depth_offset,
		end_center - width_offset + depth_offset,
		end_center - width_offset - depth_offset,
		end_center + width_offset - depth_offset,
	])

	for side_index in range(4):
		var next_index := (side_index + 1) % 4
		_append_quad_with_metadata(
			st,
			start_ring[side_index],
			end_ring[side_index],
			end_ring[next_index],
			start_ring[next_index],
			wave_phase,
			wave_depth,
			wave_axis,
			cell_id
		)

	_append_quad_with_metadata(
		st,
		start_ring[0],
		start_ring[1],
		start_ring[2],
		start_ring[3],
		wave_phase,
		wave_depth,
		wave_axis,
		cell_id
	)
	_append_quad_with_metadata(
		st,
		end_ring[3],
		end_ring[2],
		end_ring[1],
		end_ring[0],
		wave_phase,
		wave_depth,
		wave_axis,
		cell_id
	)


func _append_quad(
	st: SurfaceTool,
	a: Vector3,
	b: Vector3,
	c: Vector3,
	d: Vector3
) -> void:
	var normal := (b - a).cross(c - a)
	if normal.length_squared() < 0.000001:
		return
	normal = normal.normalized()

	_add_surface_vertex(st, a, normal, Color.WHITE, Vector2.ZERO)
	_add_surface_vertex(st, b, normal, Color.WHITE, Vector2.ZERO)
	_add_surface_vertex(st, c, normal, Color.WHITE, Vector2.ZERO)

	_add_surface_vertex(st, a, normal, Color.WHITE, Vector2.ZERO)
	_add_surface_vertex(st, c, normal, Color.WHITE, Vector2.ZERO)
	_add_surface_vertex(st, d, normal, Color.WHITE, Vector2.ZERO)


func _append_quad_with_metadata(
	st: SurfaceTool,
	a: Vector3,
	b: Vector3,
	c: Vector3,
	d: Vector3,
	wave_phase: float,
	wave_depth: float,
	wave_axis: Vector3,
	cell_id: int
) -> void:
	var normal := (b - a).cross(c - a)
	if normal.length_squared() < 0.000001:
		return
	normal = normal.normalized()

	var axis_color := _encode_wave_axis_color(wave_axis)
	var wave_uv := Vector2(wave_phase, wave_depth)
	var cell_uv2 := Vector2(float(cell_id), 0.0)

	_add_surface_vertex(st, a, normal, axis_color, wave_uv, cell_uv2)
	_add_surface_vertex(st, b, normal, axis_color, wave_uv, cell_uv2)
	_add_surface_vertex(st, c, normal, axis_color, wave_uv, cell_uv2)

	_add_surface_vertex(st, a, normal, axis_color, wave_uv, cell_uv2)
	_add_surface_vertex(st, c, normal, axis_color, wave_uv, cell_uv2)
	_add_surface_vertex(st, d, normal, axis_color, wave_uv, cell_uv2)


func _append_body_triangle(
	st: SurfaceTool,
	a: Vector3,
	b: Vector3,
	c: Vector3,
	wave_phase: float,
	wave_depth: float,
	wave_axis: Vector3,
	cell_id: int,
	double_sided: bool = false
) -> void:
	var triangle_normal := (b - a).cross(c - a)
	if triangle_normal.length_squared() < 0.000001:
		return
	triangle_normal = triangle_normal.normalized()

	var axis_color := _encode_wave_axis_color(wave_axis)
	var wave_uv := Vector2(wave_phase, wave_depth)
	var cell_uv2 := Vector2(float(cell_id), 0.0)

	_add_surface_vertex(st, a, triangle_normal, axis_color, wave_uv, cell_uv2)
	_add_surface_vertex(st, b, triangle_normal, axis_color, wave_uv, cell_uv2)
	_add_surface_vertex(st, c, triangle_normal, axis_color, wave_uv, cell_uv2)

	if double_sided:
		var reverse_normal := -triangle_normal
		_add_surface_vertex(st, a, reverse_normal, axis_color, wave_uv, cell_uv2)
		_add_surface_vertex(st, c, reverse_normal, axis_color, wave_uv, cell_uv2)
		_add_surface_vertex(st, b, reverse_normal, axis_color, wave_uv, cell_uv2)


func _add_surface_vertex(
	st: SurfaceTool,
	position: Vector3,
	normal: Vector3,
	vertex_color: Color,
	uv: Vector2,
	uv2: Vector2 = Vector2.ZERO
) -> void:
	st.set_normal(normal)
	st.set_color(vertex_color)
	st.set_uv(uv)
	st.set_uv2(uv2)
	st.add_vertex(position)


func _get_shape_cells(shape_data: Object) -> Array:
	return shape_data.get("cells") as Array


func _get_shape_radius(shape_data: Object) -> float:
	return float(shape_data.get("radius"))


func _get_cell_id(cell: Object) -> int:
	return int(cell.get("id"))


func _get_cell_polygon(cell: Object) -> PackedVector3Array:
	return cell.get("polygon") as PackedVector3Array


func _get_cell_normal(cell: Object) -> Vector3:
	return cell.get("normal") as Vector3


func _get_cell_mesh_center(cell: Object) -> Vector3:
	return cell.get("mesh_center") as Vector3


func _get_cell_wave_phase(shape_data: Object, cell: Object) -> float:
	if String(shape_data.get("topology_kind")) != "goldberg":
		return 0.0

	var center := _get_cell_center(cell)
	if center.length_squared() < 0.000001:
		return 0.0

	return center.normalized().dot(GOLDBERG_WAVE_DIRECTION.normalized())


func _get_cell_center(cell: Object) -> Vector3:
	return cell.get("center") as Vector3


func _get_cell_wave_axis(cell: Object) -> Vector3:
	var center := _get_cell_center(cell)
	if center.length_squared() < 0.000001:
		return Vector3.UP
	return center.normalized()


func _get_cell_wave_depth(cell: Object) -> float:
	return _get_cell_center(cell).distance_to(_get_cell_mesh_center(cell))


func _encode_wave_axis_color(axis: Vector3) -> Color:
	var normalized_axis := axis
	if normalized_axis.length_squared() < 0.000001:
		normalized_axis = Vector3.UP
	else:
		normalized_axis = normalized_axis.normalized()

	return Color(
		normalized_axis.x * 0.5 + 0.5,
		normalized_axis.y * 0.5 + 0.5,
		normalized_axis.z * 0.5 + 0.5,
		1.0
	)


func _is_goldberg_shape(shape_data: Object) -> bool:
	return String(shape_data.get("topology_kind")) == "goldberg"


func _edge_key_from_positions(a: Vector3, b: Vector3) -> String:
	var a_key := _vec_key(a)
	var b_key := _vec_key(b)
	return "%s|%s" % [a_key, b_key] if a_key < b_key else "%s|%s" % [b_key, a_key]


func _vec_key(v: Vector3) -> String:
	return "%d:%d:%d" % [
		int(round(v.x * EDGE_KEY_PRECISION)),
		int(round(v.y * EDGE_KEY_PRECISION)),
		int(round(v.z * EDGE_KEY_PRECISION)),
	]
