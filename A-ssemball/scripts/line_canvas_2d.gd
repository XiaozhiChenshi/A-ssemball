@tool
extends Control
class_name LineCanvas2D

@export var line_color: Color = Color.WHITE
@export var line_width: float = 3.0
@export var line_shadow_color: Color = Color(0.0, 0.0, 0.0, 0.62)
@export var line_shadow_extra_width: float = 4.0
@export var rough_pencil: bool = false
@export var particle_enabled: bool = false
@export var particle_color: Color = Color(0.9, 0.86, 0.72, 0.42)
@export_range(-1.0, 1.0, 0.001) var burn_progress: float = -1.0
@export var burn_fire_only: bool = false
@export var burn_fire_color: Color = Color(1.0, 0.58, 0.18, 0.9)
@export var burn_ash_color: Color = Color(0.05, 0.025, 0.012, 0.82)

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
	burn_progress = -1.0
	queue_redraw()


func set_burn_progress(progress: float, fire_only: bool = false) -> void:
	burn_progress = progress
	burn_fire_only = fire_only
	queue_redraw()


func _process(_delta: float) -> void:
	if (particle_enabled or burn_progress >= 0.0) and _points.size() >= 2:
		queue_redraw()


func _draw() -> void:
	if _points.size() < 2:
		return

	if burn_progress >= 0.0:
		_draw_burning_line()
		return

	if rough_pencil:
		_draw_rough_line()
		return

	var shadow_width := line_width + line_shadow_extra_width
	for i in range(_points.size() - 1):
		draw_line(_points[i], _points[i + 1], line_shadow_color, shadow_width, true)
		draw_line(_points[i], _points[i + 1], line_color, line_width, true)

	if _closed:
		draw_line(_points[_points.size() - 1], _points[0], line_shadow_color, shadow_width, true)
		draw_line(_points[_points.size() - 1], _points[0], line_color, line_width, true)


func _draw_rough_line() -> void:
	var segment_count := _points.size() - 1
	for i in range(segment_count):
		_draw_rough_segment(_points[i], _points[i + 1], i)
	if _closed:
		_draw_rough_segment(_points[_points.size() - 1], _points[0], segment_count)
	if particle_enabled:
		_draw_evaporating_particles()
		_draw_route_twinkle_stars()


func _draw_burning_line() -> void:
	var progress: float = clampf(burn_progress, 0.0, 1.0)
	var path_points := PackedVector2Array(_points)
	if _closed:
		path_points.append(_points[0])
	if path_points.size() < 2:
		return

	var disappear := smoothstep(0.08, 1.0, progress)
	var alpha := pow(1.0 - disappear, 1.18)
	if alpha <= 0.015:
		return

	if burn_fire_only:
		return

	var shadow := line_shadow_color
	shadow.a *= alpha * 0.7
	var color := line_color
	color.a *= alpha
	draw_polyline(path_points, shadow, line_width + line_shadow_extra_width, false)
	draw_polyline(path_points, color, line_width, false)


func _draw_rough_segment(a: Vector2, b: Vector2, segment_index: int) -> void:
	var dir := b - a
	var length := dir.length()
	if length <= 0.001:
		return
	var normal := Vector2(-dir.y, dir.x).normalized()
	var steps := maxi(3, int(length / 7.0))
	var shadow_points := PackedVector2Array()
	for step in range(steps + 1):
		var t := float(step) / float(steps)
		var seed := float(segment_index * 101 + step * 19)
		var jitter := (sin(seed * 8.71) * 0.55 + sin(seed * 2.39) * 0.3) * line_width * 0.82
		shadow_points.append(a.lerp(b, t) + normal * jitter)
	for step in range(shadow_points.size() - 1):
		if step % 3 == 1:
			continue
		var shadow_seed := float(segment_index * 131 + step * 23)
		var shadow_color := line_shadow_color
		shadow_color.a *= 0.42 + 0.18 * absf(sin(shadow_seed))
		draw_line(
			shadow_points[step],
			shadow_points[step + 1],
			shadow_color,
			maxf(1.0, line_width * 0.62),
			false
		)

	for pass_index in range(7):
		var rough_points := PackedVector2Array()
		for step in range(steps + 1):
			var t := float(step) / float(steps)
			var seed := float(segment_index * 97 + pass_index * 31 + step * 17)
			var jitter := (sin(seed * 12.9898) * 0.5 + sin(seed * 4.13) * 0.35) * line_width * 1.08
			rough_points.append(a.lerp(b, t) + normal * jitter)
		var color_mix := 0.78 + sin(float(segment_index + pass_index) * 1.81) * 0.14
		var pass_color := Color(
			clampf(line_color.r * color_mix, 0.0, 1.0),
			clampf(line_color.g * color_mix, 0.0, 1.0),
			clampf(line_color.b * color_mix, 0.0, 1.0),
			clampf(line_color.a * (0.42 + float(pass_index) * 0.07), 0.0, 0.92)
		)
		draw_polyline(rough_points, pass_color, line_width * (0.72 + pass_index * 0.06), false)

	var highlight := Color(
		minf(line_color.r + 0.20, 1.0),
		minf(line_color.g + 0.18, 1.0),
		minf(line_color.b + 0.12, 1.0),
		clampf(line_color.a * 0.48, 0.0, 0.72)
	)
	for step in range(shadow_points.size() - 1):
		if step % 4 != 0:
			continue
		draw_line(
			shadow_points[step],
			shadow_points[step + 1],
			highlight,
			maxf(1.0, line_width * 0.36),
			false
		)


func _draw_evaporating_particles() -> void:
	var time_sec := Time.get_ticks_msec() / 1000.0
	for i in range(_points.size() - 1):
		var a := _points[i]
		var b := _points[i + 1]
		var length := a.distance_to(b)
		var count := clampi(int(length / 7.0), 5, 34)
		for n in range(count):
			var seed := float(i * 113 + n * 29 + 7)
			var random_phase_value: float = sin(seed) * 43758.5453
			var random_phase: float = random_phase_value - floor(random_phase_value)
			var phase: float = fmod(time_sec * (0.46 + fmod(seed, 5.0) * 0.055) + random_phase, 1.0)
			var t := clampf((float(n) + 0.5) / float(count) + sin(seed * 1.7) * 0.08, 0.0, 1.0)
			var base := a.lerp(b, t)
			var drift_x := sin(seed * 3.11 + time_sec * 1.7) * 11.0
			var rise := phase * (34.0 + fmod(seed, 17.0))
			var pos := base + Vector2(drift_x, -rise)
			var alpha := particle_color.a * pow(1.0 - phase, 1.22)
			var tint_selector := fmod(seed, 3.0)
			var color := particle_color
			if tint_selector < 1.0:
				color = particle_color.lerp(Color.WHITE, 0.28)
			elif tint_selector < 2.0:
				color = particle_color.darkened(0.36)
			else:
				color = particle_color.lerp(Color(0.82, 0.86, 0.78, particle_color.a), 0.18)
			var radius := 1.65 + fmod(seed, 5.0) * 0.48
			draw_circle(pos, radius, Color(color.r, color.g, color.b, alpha))


func _draw_route_twinkle_stars() -> void:
	var time_sec := Time.get_ticks_msec() / 1000.0
	var segment_count := _points.size() - 1
	for i in range(segment_count):
		_draw_twinkles_on_segment(_points[i], _points[i + 1], i, time_sec)
	if _closed:
		_draw_twinkles_on_segment(_points[_points.size() - 1], _points[0], segment_count, time_sec)


func _draw_twinkles_on_segment(a: Vector2, b: Vector2, segment_index: int, time_sec: float) -> void:
	var length := a.distance_to(b)
	if length <= 0.001:
		return
	var dir := (b - a) / length
	var normal := Vector2(-dir.y, dir.x)
	var count := clampi(int(length / 42.0), 1, 5)
	for n in range(count):
		var seed := float(segment_index * 173 + n * 47 + 23)
		var t := clampf((float(n) + 0.5) / float(count) + sin(seed * 1.31) * 0.16, 0.08, 0.92)
		var phase := fmod(time_sec * (1.5 + fmod(seed, 5.0) * 0.18) + sin(seed) * 4.7, 1.0)
		var pulse := smoothstep(0.0, 0.18, phase) * (1.0 - smoothstep(0.38, 1.0, phase))
		if pulse <= 0.01:
			continue
		var pos := a.lerp(b, t) + normal * sin(seed * 2.77 + time_sec * 2.1) * 3.6
		var radius := (3.2 + fmod(seed, 4.0) * 1.25) * pulse
		var color := Color(
			minf(particle_color.r + 0.18, 1.0),
			minf(particle_color.g + 0.16, 1.0),
			minf(particle_color.b + 0.12, 1.0),
			clampf(particle_color.a * pulse, 0.0, 0.95)
		)
		draw_line(pos - Vector2(radius, 0.0), pos + Vector2(radius, 0.0), color, 1.15, false)
		draw_line(pos - Vector2(0.0, radius), pos + Vector2(0.0, radius), color, 1.15, false)
		var diagonal := radius * 0.52
		draw_line(pos - Vector2(diagonal, diagonal), pos + Vector2(diagonal, diagonal), Color(color.r, color.g, color.b, color.a * 0.62), 0.8, false)
		draw_line(pos - Vector2(-diagonal, diagonal), pos + Vector2(-diagonal, diagonal), Color(color.r, color.g, color.b, color.a * 0.62), 0.8, false)
