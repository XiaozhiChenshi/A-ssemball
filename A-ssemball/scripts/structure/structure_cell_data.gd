extends RefCounted
class_name StructureCellData

var id: int = -1
var cell_kind: String = ""
var center: Vector3 = Vector3.ZERO
var mesh_center: Vector3 = Vector3.ZERO
var normal: Vector3 = Vector3.UP
var polygon: PackedVector3Array = PackedVector3Array()
var neighbors: PackedInt32Array = PackedInt32Array()
