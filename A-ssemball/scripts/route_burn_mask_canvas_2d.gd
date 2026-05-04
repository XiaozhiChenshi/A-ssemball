@tool
extends Control
class_name RouteBurnMaskCanvas2D

@export var ink_color: Color = Color(0.94, 0.80, 0.46, 0.82)
@export var ember_color: Color = Color(1.0, 0.55, 0.16, 0.95)
@export var char_color: Color = Color(0.045, 0.028, 0.018, 0.92)
@export_range(0.0, 1.0, 0.001) var burn_progress: float = 0.0
@export_range(1.0, 10.0, 0.1) var sample_step_px: float = 4.5

var _points: PackedVector2Array = PackedVector2Array()
var _closed: bool = false
var _origins: Array[Vector2] = [
	Vector2(0.45, 0.5),
	Vector2(0.62, 0.42),
	Vector2(0.52, 0.58),
	Vector2(0.38, 0.55),
	Vector2(0.56, 0.47),
	Vector2(0.70, 0.38),
	Vector2(0.48, 0.64),
]


func set_route(points: PackedVector2Array, closed: bool, origins: Array[Vector2]) -> void:
	_points = points
	_closed = closed
	if origins.size() >= 1:
		_origins = origins.duplicate()
	queue_redraw()


func clear_route() -> void:
	_points = PackedVector2Array()
	_closed = false
	burn_progress = 0.0
	queue_redraw()


func set_burn_progress(progress: float) -> void:
	burn_progress = clampf(progress, 0.0, 1.0)
	queue_redraw()


func _process(_delta: float) -> void:
	if visible and _points.size() >= 2:
		queue_redraw()


func _draw() -> void:
	if _points.size() < 2:
		return

	var path := PackedVector2Array(_points)
	if _closed:
		path.append(_points[0])

	for i in range(path.size() - 1):
		_draw_fragmented_segment(path[i], path[i + 1], i)


func _draw_fragmented_segment(a: Vector2, b: Vector2, segment_index: int) -> void:
	var dir := b - a
	var length := dir.length()
	if length <= 0.001:
		return

	var normal := Vector2(-dir.y, dir.x).normalized()
	var tangent := dir / length
	var steps := maxi(2, int(ceil(length / sample_step_px)))
	for step in range(steps + 1):
		var t := float(step) / float(steps)
		var p := a.lerp(b, t)
		var uv := Vector2(p.x / maxf(1.0, size.x), p.y / maxf(1.0, size.y))
		var mask := _burn_mask(uv)
		if mask >= 0.92:
			continue

		var seed := float(segment_index * 151 + step * 37 + 11)
		var keep := _hash(Vector2(seed, floor(Time.get_ticks_msec() / 120.0)))
		var char_edge := smoothstep(0.48, 0.91, mask)
		if keep < char_edge * 0.36:
			continue

		var jitter := (_hash(Vector2(seed, 2.7)) - 0.5) * 5.0
		var offset_p := p + normal * jitter
		var dash_len := 2.2 + _hash(Vector2(seed, 9.1)) * 5.0
		var width := 0.75 + _hash(Vector2(seed, 4.4)) * 1.05
		var angle_jitter := (_hash(Vector2(seed, 6.2)) - 0.5) * 0.85
		var stroke_dir := tangent.rotated(angle_jitter)
		var alpha := clampf((1.0 - mask) * (0.44 + keep * 0.38), 0.0, 0.78)
		var color := ink_color.lerp(char_color, char_edge * 0.78)
		color.a *= alpha
		draw_line(offset_p - stroke_dir * dash_len * 0.5, offset_p + stroke_dir * dash_len * 0.5, color, width, false)

		var ember := smoothstep(0.50, 0.86, mask) * (1.0 - smoothstep(0.86, 0.98, mask))
		if ember > 0.05 and keep > 0.62:
			var ember_tint := ember_color
			ember_tint.a *= ember * 0.72
			draw_circle(offset_p + normal * 1.2, 1.0 + keep * 1.5, ember_tint)


func _burn_mask(uv: Vector2) -> float:
	var radius := lerpf(-0.06, 1.02, burn_progress)
	var field := -INF
	for i in range(_origins.size()):
		var origin := _origins[i]
		var stretch := 1.0
		if i == 0:
			stretch = 0.92
		elif i == 1:
			stretch = 1.12
		elif i == 2:
			stretch = 0.84
		elif i == 5:
			stretch = 1.08
		var local_radius := radius
		if i == 1:
			local_radius *= 0.9
		elif i == 2:
			local_radius *= 1.06
		elif i == 3:
			local_radius *= 0.82
		elif i == 4:
			local_radius *= 0.88
		elif i == 5:
			local_radius *= 0.78
		elif i == 6:
			local_radius *= 0.92
		field = maxf(field, _burn_field(uv, origin, local_radius, stretch))
	field = maxf(field, smoothstep(0.68, 1.0, burn_progress) * 0.42 - uv.distance_to(Vector2(0.5, 0.5)) * 0.55)
	return smoothstep(0.0, 0.105, field)


func _burn_field(uv: Vector2, origin: Vector2, radius: float, stretch: float) -> float:
	var p := uv - origin
	p.x *= stretch
	var coarse := _noise(uv * 7.0 + Vector2(Time.get_ticks_msec() * 0.00008, -Time.get_ticks_msec() * 0.00005))
	var fine := _noise(uv * 34.0 + Vector2(floor(Time.get_ticks_msec() * 0.014), floor(Time.get_ticks_msec() * 0.011)))
	var tear := sin((uv.y + coarse * 0.12) * 38.0 + Time.get_ticks_msec() * 0.004) * 0.018
	return radius - p.length() + (coarse - 0.5) * 0.115 + (fine - 0.5) * 0.038 + tear


func _noise(p: Vector2) -> float:
	var i := p.floor()
	var f := p - i
	f = f * f * (Vector2.ONE * 3.0 - f * 2.0)
	var a := _hash(i)
	var b := _hash(i + Vector2(1.0, 0.0))
	var c := _hash(i + Vector2(0.0, 1.0))
	var d := _hash(i + Vector2(1.0, 1.0))
	return lerpf(lerpf(a, b, f.x), lerpf(c, d, f.x), f.y)


func _hash(p: Vector2) -> float:
	var value := sin(p.dot(Vector2(127.1, 311.7))) * 43758.5453123
	return value - floorf(value)
