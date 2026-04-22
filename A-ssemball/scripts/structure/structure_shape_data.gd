extends RefCounted
class_name StructureShapeData

var shape_key: String = ""
var display_label: String = ""
var topology_kind: String = ""
var m: int = -1
var n: int = -1
var radius: float = 1.0
var cells: Array = []
var body_mesh: Mesh
var edge_mesh: Mesh
var static_edge_mesh: Mesh


func get_cell_count() -> int:
	return cells.size()
