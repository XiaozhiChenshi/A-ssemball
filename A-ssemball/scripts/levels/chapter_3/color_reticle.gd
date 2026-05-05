extends Control


func _draw() -> void:
	var r := minf(size.x, size.y) * 0.5
	var center := size * 0.5
	draw_arc(center, r - 2.0, 0.0, TAU, 96, Color(0.92, 0.96, 1.0, 0.92), 2.0)
	draw_arc(center, r * 0.58, 0.0, TAU, 96, Color(0.92, 0.96, 1.0, 0.26), 1.0)
	draw_line(center + Vector2(-r, 0.0), center + Vector2(-r * 0.55, 0.0), Color(0.92, 0.96, 1.0, 0.7), 2.0)
	draw_line(center + Vector2(r * 0.55, 0.0), center + Vector2(r, 0.0), Color(0.92, 0.96, 1.0, 0.7), 2.0)
	draw_line(center + Vector2(0.0, -r), center + Vector2(0.0, -r * 0.55), Color(0.92, 0.96, 1.0, 0.7), 2.0)
	draw_line(center + Vector2(0.0, r * 0.55), center + Vector2(0.0, r), Color(0.92, 0.96, 1.0, 0.7), 2.0)
