@tool
extends Control
class_name LineCanvas2D

@export var line_color: Color = Color.WHITE
@export var line_width: float = 3.0

var _points: PackedVector2Array = PackedVector2Array()
var _closed: bool = false


func set_line_points(points: PackedVector2Array, closed: bool = false, width: float = 3.0) -> void:
	_points = points
	_closed = closed
	line_width = width
	queue_redraw()


func clear_lines() -> void:
	_points = PackedVector2Array()
	_closed = false
	queue_redraw()


func _draw() -> void:
	if _points.size() < 2:
		return

	for i in range(_points.size() - 1):
		draw_line(_points[i], _points[i + 1], line_color, line_width, true)

	if _closed:
		draw_line(_points[_points.size() - 1], _points[0], line_color, line_width, true)
