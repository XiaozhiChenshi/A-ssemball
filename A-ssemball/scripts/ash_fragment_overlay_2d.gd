@tool
extends Control
class_name AshFragmentOverlay2D

@export_range(0.0, 1.0, 0.001) var burn_progress: float = 0.0
@export_range(0.0, 1.0, 0.001) var fall_progress: float = 0.0
@export_range(4, 12, 1) var shard_columns: int = 7
@export_range(3, 10, 1) var shard_rows: int = 5

var _origins: Array[Vector2] = [
	Vector2(0.45, 0.5),
	Vector2(0.62, 0.42),
	Vector2(0.52, 0.58),
	Vector2(0.38, 0.55),
	Vector2(0.56, 0.47),
	Vector2(0.70, 0.38),
	Vector2(0.48, 0.64),
]
var _deposit_rect: ColorRect
var _shard_root: Control
var _ash_material: ShaderMaterial
var _ash_texture: Texture2D
var _peel_fragments: Array[Dictionary] = []
var _last_size: Vector2 = Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ensure_deposit_rect()
	_ensure_shard_root()
	_ensure_material()
	_layout_deposit_rect()


func prepare(origins: Array[Vector2]) -> void:
	if origins.size() > 0:
		_origins = origins.duplicate()
	burn_progress = 0.0
	fall_progress = 0.0
	visible = true
	_ensure_deposit_rect()
	_ensure_shard_root()
	_ensure_material()
	_layout_deposit_rect()
	_apply_shader_state()
	_generate_peel_fragments()
	queue_redraw()


func set_ash_texture(texture: Texture2D) -> void:
	_ash_texture = texture
	_ensure_deposit_rect()
	_ensure_shard_root()
	_ensure_material()
	_apply_shader_state()
	_rebuild_shard_nodes()


func clear_ash() -> void:
	burn_progress = 0.0
	fall_progress = 0.0
	_peel_fragments.clear()
	_clear_shard_nodes()
	_apply_shader_state()
	visible = false
	queue_redraw()


func set_burn_progress(progress: float) -> void:
	burn_progress = clampf(progress, 0.0, 1.0)
	_apply_shader_state()
	if visible:
		queue_redraw()


func set_fall_progress(progress: float) -> void:
	fall_progress = clampf(progress, 0.0, 1.0)
	_apply_shader_state()
	_update_shard_nodes()
	if visible:
		queue_redraw()


func _process(_delta: float) -> void:
	if not visible:
		return
	if _last_size != size:
		_layout_deposit_rect()
		_generate_peel_fragments()
	_update_shard_nodes()


func _generate_peel_fragments() -> void:
	_last_size = size
	_peel_fragments.clear()
	var panel_size := Vector2(maxf(1.0, size.x), maxf(1.0, size.y))
	var sites := _build_fracture_sites(panel_size)
	var bounds := PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(panel_size.x, 0.0),
		Vector2(panel_size.x, panel_size.y),
		Vector2(0.0, panel_size.y),
	])
	for i in range(sites.size()):
		var points := PackedVector2Array(bounds)
		var site := sites[i]
		for j in range(sites.size()):
			if i == j:
				continue
			points = _clip_polygon_to_site(points, site, sites[j])
			if points.size() < 3:
				break
		if points.size() < 3:
			continue
		points = _roughen_shard_edges(points, float(i + 1), panel_size)
		var center := _polygon_centroid(points)
		var order := clampf(center.y / panel_size.y * 0.48 + _hash(Vector2(float(i) + 5.5, 1.7)) * 0.42, 0.0, 1.0)
		var seed := float(i + 1)
		_peel_fragments.append({
			"points": points,
			"center": center,
			"delay": 0.06 + order * 0.58,
			"drift": lerpf(-0.30, 0.30, _hash(Vector2(seed, 6.2))),
			"drop": lerpf(1.08, 1.88, _hash(Vector2(seed, 7.4))),
			"spin": lerpf(-1.55, 1.55, _hash(Vector2(seed, 9.6))),
			"seed": seed,
		})
	_rebuild_shard_nodes()


func _build_fracture_sites(panel_size: Vector2) -> Array[Vector2]:
	var cols := maxi(4, shard_columns)
	var rows := maxi(3, shard_rows)
	var cell_size := Vector2(panel_size.x / float(cols), panel_size.y / float(rows))
	var sites: Array[Vector2] = []
	for y in range(rows):
		for x in range(cols):
			var seed := float(y * cols + x + 1)
			var base := Vector2(float(x) + 0.5, float(y) + 0.5) * cell_size
			var jitter := Vector2(
				(_hash(Vector2(seed, 1.1)) - 0.5) * cell_size.x * 0.72,
				(_hash(Vector2(seed, 2.2)) - 0.5) * cell_size.y * 0.72
			)
			sites.append(Vector2(
				clampf(base.x + jitter.x, 6.0, panel_size.x - 6.0),
				clampf(base.y + jitter.y, 6.0, panel_size.y - 6.0)
			))
	var extra_count := maxi(5, int(float(cols * rows) * 0.22))
	for i in range(extra_count):
		var seed := float(1000 + i)
		var anchor := _origins[i % _origins.size()]
		var spread := Vector2(panel_size.x * 0.24, panel_size.y * 0.24)
		var point := Vector2(anchor.x * panel_size.x, anchor.y * panel_size.y)
		point += Vector2(_hash(Vector2(seed, 3.3)) - 0.5, _hash(Vector2(seed, 4.4)) - 0.5) * spread
		sites.append(Vector2(clampf(point.x, 6.0, panel_size.x - 6.0), clampf(point.y, 6.0, panel_size.y - 6.0)))
	return sites


func _clip_polygon_to_site(points: PackedVector2Array, site: Vector2, other: Vector2) -> PackedVector2Array:
	if points.size() < 3:
		return PackedVector2Array()
	var result := PackedVector2Array()
	var normal := other - site
	var limit := (other.length_squared() - site.length_squared()) * 0.5
	var previous := points[points.size() - 1]
	var previous_inside := previous.dot(normal) <= limit
	for current in points:
		var current_inside := current.dot(normal) <= limit
		if current_inside != previous_inside:
			var intersection := _intersect_bisector(previous, current, normal, limit)
			result.append(intersection)
		if current_inside:
			result.append(current)
		previous = current
		previous_inside = current_inside
	return result


func _intersect_bisector(a: Vector2, b: Vector2, normal: Vector2, limit: float) -> Vector2:
	var ab := b - a
	var denom := ab.dot(normal)
	if absf(denom) <= 0.00001:
		return a
	var t := clampf((limit - a.dot(normal)) / denom, 0.0, 1.0)
	return a.lerp(b, t)


func _roughen_shard_edges(points: PackedVector2Array, seed: float, panel_size: Vector2) -> PackedVector2Array:
	var rough := PackedVector2Array()
	var max_jitter := minf(panel_size.x, panel_size.y) * 0.018
	for i in range(points.size()):
		var a := points[i]
		var b := points[(i + 1) % points.size()]
		rough.append(a)
		var edge := b - a
		var length := edge.length()
		if length < 42.0:
			continue
		var normal := Vector2(-edge.y, edge.x).normalized()
		var cut_count := clampi(int(length / 95.0), 1, 3)
		for n in range(cut_count):
			var local_seed := seed * 37.0 + float(i * 11 + n)
			var t := (float(n) + 1.0) / float(cut_count + 1)
			t += (_hash(Vector2(local_seed, 1.0)) - 0.5) * 0.18
			var jitter := (_hash(Vector2(local_seed, 2.0)) - 0.5) * max_jitter
			rough.append(a.lerp(b, clampf(t, 0.12, 0.88)) + normal * jitter)
	return rough


func _polygon_centroid(points: PackedVector2Array) -> Vector2:
	var center := Vector2.ZERO
	if points.is_empty():
		return center
	for point in points:
		center += point
	return center / float(points.size())


func _ensure_material() -> void:
	if _ash_material != null:
		return
	_ensure_deposit_rect()
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float burn_progress : hint_range(0.0, 1.0) = 0.0;
uniform float fall_progress : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D ash_texture : repeat_enable, filter_linear_mipmap;
uniform vec2 shard_grid = vec2(7.0, 5.0);
uniform vec2 origin_a = vec2(0.45, 0.5);
uniform vec2 origin_b = vec2(0.62, 0.42);
uniform vec2 origin_c = vec2(0.52, 0.58);
uniform vec2 origin_d = vec2(0.38, 0.55);
uniform vec2 origin_e = vec2(0.56, 0.47);
uniform vec2 origin_f = vec2(0.70, 0.38);
uniform vec2 origin_g = vec2(0.48, 0.64);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float burn_field(vec2 uv, vec2 origin, float radius, float stretch) {
	vec2 p = uv - origin;
	p.x *= stretch;
	float coarse = noise(uv * 7.0 + vec2(TIME * 0.08, -TIME * 0.05));
	float fine = noise(uv * 34.0 + vec2(floor(TIME * 14.0), floor(TIME * 11.0)));
	float tear = sin((uv.y + coarse * 0.12) * 38.0 + TIME * 4.0) * 0.018;
	return radius - length(p) + (coarse - 0.5) * 0.115 + (fine - 0.5) * 0.038 + tear;
}

float burn_total_field(vec2 uv) {
	if (burn_progress >= 0.995) {
		return 1.0;
	}
	float radius = mix(-0.06, 1.02, burn_progress);
	float field = max(burn_field(uv, origin_a, radius, 0.92), burn_field(uv, origin_b, radius * 0.9, 1.12));
	field = max(field, burn_field(uv, origin_c, radius * 1.06, 0.84));
	field = max(field, burn_field(uv, origin_d, radius * 0.82, 1.0));
	field = max(field, burn_field(uv, origin_e, radius * 0.88, 0.95));
	field = max(field, burn_field(uv, origin_f, radius * 0.78, 1.08));
	field = max(field, burn_field(uv, origin_g, radius * 0.92, 0.9));
	field = max(field, smoothstep(0.68, 1.0, burn_progress) * 0.42 - distance(uv, vec2(0.5)) * 0.55);
	field = max(field, smoothstep(0.86, 1.0, burn_progress) * 1.05 - distance(uv, vec2(0.5)) * 0.08);
	return field;
}

float burn_mask(vec2 uv) {
	if (burn_progress >= 0.995) {
		return 1.0;
	}
	float field = burn_total_field(uv);
	return smoothstep(0.0, 0.105, field);
}

void fragment() {
	float field = burn_total_field(UV);
	float burned = burn_mask(UV);
	float formed = smoothstep(0.08, 0.72, burned);
	if (burn_progress >= 0.995) {
		formed = 1.0;
	}

	float peel_keep = 1.0 - smoothstep(0.0, 0.035, fall_progress);

	float edge_clear = smoothstep(0.10, 0.24, field);
	float ash_alpha = formed * peel_keep * edge_clear;

	vec2 ash_uv = UV;
	ash_uv.x += (noise(UV * 4.0) - 0.5) * 0.018;
	ash_uv.y += (noise(UV * 5.0 + vec2(7.1, 2.3)) - 0.5) * 0.014;
	vec3 source_ash = texture(ash_texture, ash_uv).rgb;
	float source_luma = dot(source_ash, vec3(0.299, 0.587, 0.114));
	vec3 source_grey = vec3(source_luma);
	vec3 source_char = mix(source_ash, source_grey, 0.42);
	source_char = pow(max(source_char, vec3(0.0)), vec3(1.18));
	source_char *= 0.72;

	float powder = noise(UV * 120.0) * 0.055;
	vec3 color = source_char + vec3(powder);
	color += vec3(0.05, 0.045, 0.035) * smoothstep(0.0, 0.18, field) * (1.0 - smoothstep(0.18, 0.38, field));

	COLOR = vec4(clamp(color, vec3(0.0), vec3(1.0)), clamp(ash_alpha, 0.0, 0.98));
}
"""
	_ash_material = ShaderMaterial.new()
	_ash_material.shader = shader
	_deposit_rect.material = _ash_material
	_apply_shader_state()


func _ensure_deposit_rect() -> void:
	if _deposit_rect != null and is_instance_valid(_deposit_rect):
		return
	_deposit_rect = ColorRect.new()
	_deposit_rect.name = "AshDepositTexture"
	_deposit_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_deposit_rect.color = Color.WHITE
	_deposit_rect.show_behind_parent = true
	add_child(_deposit_rect)
	move_child(_deposit_rect, 0)


func _ensure_shard_root() -> void:
	if _shard_root != null and is_instance_valid(_shard_root):
		return
	_shard_root = Control.new()
	_shard_root.name = "AshShardRoot"
	_shard_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shard_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shard_root.offset_left = 0.0
	_shard_root.offset_top = 0.0
	_shard_root.offset_right = 0.0
	_shard_root.offset_bottom = 0.0
	add_child(_shard_root)


func _clear_shard_nodes() -> void:
	if _shard_root == null:
		return
	for child in _shard_root.get_children():
		child.queue_free()


func _rebuild_shard_nodes() -> void:
	_ensure_shard_root()
	_clear_shard_nodes()
	if _ash_texture == null:
		return
	var panel_size := Vector2(maxf(1.0, size.x), maxf(1.0, size.y))
	var texture_size := Vector2(maxf(1.0, _ash_texture.get_width()), maxf(1.0, _ash_texture.get_height()))
	for i in range(_peel_fragments.size()):
		var fragment := _peel_fragments[i]
		var center := fragment.get("center", Vector2.ZERO) as Vector2
		var points := fragment.get("points", PackedVector2Array()) as PackedVector2Array
		if points.size() < 3:
			continue
		var polygon := Polygon2D.new()
		polygon.name = "AshShard%02d" % i
		polygon.texture = _ash_texture
		polygon.color = Color.WHITE
		polygon.visible = false
		polygon.position = center
		polygon.z_index = 5
		var local_points := PackedVector2Array()
		var uvs := PackedVector2Array()
		for point in points:
			local_points.append(point - center)
			uvs.append(Vector2(point.x / panel_size.x, point.y / panel_size.y) * texture_size)
		polygon.polygon = local_points
		polygon.uv = uvs
		_shard_root.add_child(polygon)
		fragment["node"] = polygon
		_peel_fragments[i] = fragment
	_update_shard_nodes()


func _update_shard_nodes() -> void:
	if _shard_root == null:
		return
	var panel_size := Vector2(maxf(1.0, size.x), maxf(1.0, size.y))
	var active := fall_progress > 0.001 and burn_progress >= 0.995
	for fragment in _peel_fragments:
		var polygon := fragment.get("node", null) as Polygon2D
		if polygon == null or not is_instance_valid(polygon):
			continue
		if not active:
			polygon.visible = false
			continue
		var delay := float(fragment.get("delay", 0.0))
		var local_fall := smoothstep(delay, minf(1.0, delay + 0.28), fall_progress)
		if local_fall >= 0.995:
			polygon.visible = false
			continue
		var center := fragment.get("center", Vector2.ZERO) as Vector2
		var drift := float(fragment.get("drift", 0.0)) * local_fall * panel_size.x
		var drop := panel_size.y * float(fragment.get("drop", 1.0)) * local_fall
		var flutter := sin(Time.get_ticks_msec() * 0.003 + float(fragment.get("seed", 0.0))) * 18.0 * local_fall
		polygon.visible = true
		polygon.position = center + Vector2(drift + flutter, drop)
		polygon.rotation = float(fragment.get("spin", 0.0)) * TAU * local_fall
		polygon.modulate = Color(1.0, 1.0, 1.0, pow(1.0 - local_fall, 0.62))


func _layout_deposit_rect() -> void:
	if _deposit_rect == null:
		return
	_deposit_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_deposit_rect.offset_left = 0.0
	_deposit_rect.offset_top = 0.0
	_deposit_rect.offset_right = 0.0
	_deposit_rect.offset_bottom = 0.0
	if _shard_root != null:
		_shard_root.set_anchors_preset(Control.PRESET_FULL_RECT)
		_shard_root.offset_left = 0.0
		_shard_root.offset_top = 0.0
		_shard_root.offset_right = 0.0
		_shard_root.offset_bottom = 0.0


func _apply_shader_state() -> void:
	if _ash_material == null:
		return
	_ash_material.set_shader_parameter("burn_progress", burn_progress)
	_ash_material.set_shader_parameter("fall_progress", fall_progress)
	_ash_material.set_shader_parameter("shard_grid", Vector2(float(maxi(1, shard_columns)), float(maxi(1, shard_rows))))
	if _ash_texture != null:
		_ash_material.set_shader_parameter("ash_texture", _ash_texture)
	var origins := _origins.duplicate()
	while origins.size() < 7:
		origins.append(Vector2(0.5, 0.5))
	_ash_material.set_shader_parameter("origin_a", origins[0])
	_ash_material.set_shader_parameter("origin_b", origins[1])
	_ash_material.set_shader_parameter("origin_c", origins[2])
	_ash_material.set_shader_parameter("origin_d", origins[3])
	_ash_material.set_shader_parameter("origin_e", origins[4])
	_ash_material.set_shader_parameter("origin_f", origins[5])
	_ash_material.set_shader_parameter("origin_g", origins[6])


func _hash(p: Vector2) -> float:
	var value := sin(p.dot(Vector2(127.1, 311.7))) * 43758.5453123
	return value - floorf(value)
