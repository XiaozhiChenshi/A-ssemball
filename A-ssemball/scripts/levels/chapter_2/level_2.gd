extends Control
class_name LevelC2L2

signal chapter_completed(chapter_index: int)

@export var chapter_index: int = 2
@export_range(0.2, 3.0, 0.01) var sphere_radius: float = 1.0
@export_range(0.0, 180.0, 0.1) var manual_rotate_speed_deg: float = 56.0
@export_range(0.0, 1.0, 0.001) var chunk_gap: float = 0.12
@export_range(0.1, 0.9, 0.01) var left_panel_width_ratio: float = 0.25
@export_range(0.2, 2.0, 0.01) var shrink_min_scale: float = 0.62
@export_range(0.2, 3.0, 0.01) var shrink_speed_min: float = 0.55
@export_range(0.2, 3.0, 0.01) var shrink_speed_max: float = 1.65
@export_range(0.0, 0.25, 0.001) var jitter_amplitude: float = 0.018
@export_range(0.01, 1.0, 0.01) var jitter_speed_min: float = 0.08
@export_range(0.01, 1.0, 0.01) var jitter_speed_max: float = 0.22
@export_range(0.0, 6.0, 0.1) var selected_glow_strength: float = 2.2
@export_range(8.0, 240.0, 1.0) var click_pick_radius_px: float = 80.0
@export_range(0.05, 1.5, 0.01) var icon_swap_fade_sec: float = 0.35

@onready var chapter_split: HSplitContainer = $ChapterSplit
@onready var left_3d: SubViewportContainer = $ChapterSplit/Left3D
@onready var left_viewport: SubViewport = $ChapterSplit/Left3D/LeftViewport
@onready var chunk_root: Node3D = $ChapterSplit/Left3D/LeftViewport/World3D/ChunkRoot
@onready var right_panel: Control = $ChapterSplit/RightPanel
@onready var camera_3d: Camera3D = $ChapterSplit/Left3D/LeftViewport/World3D/Camera3D

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _chunk_items: Array[Dictionary] = []
var _time_sec: float = 0.0
var _completed_once: bool = false
var _selected_chunk: Node3D
var _icon_swap_running: bool = false


func _ready() -> void:
	_rng.randomize()
	_collect_chunk_nodes()
	left_3d.visible = true
	chunk_root.visible = true
	resized.connect(_on_layout_changed)
	left_3d.resized.connect(_on_layout_changed)
	chapter_split.dragged.connect(_on_split_dragged)
	_on_layout_changed()


func _process(delta: float) -> void:
	_time_sec += delta
	_update_rotation_input(delta)
	_update_chunk_shrink(delta)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if _handle_chunk_click(event.position):
			get_viewport().set_input_as_handled()
			return

	if _completed_once:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ENTER:
		_completed_once = true
		get_viewport().set_input_as_handled()
		chapter_completed.emit(chapter_index)


func _on_layout_changed() -> void:
	left_viewport.size = Vector2i(maxi(1, int(left_3d.size.x)), maxi(1, int(left_3d.size.y)))
	_enforce_layout_constraints()


func _on_split_dragged(_offset: int) -> void:
	_enforce_layout_constraints()


func _enforce_layout_constraints() -> void:
	var ratio := clampf(left_panel_width_ratio, 0.1, 0.9)
	right_panel.custom_minimum_size.x = maxf(1.0, size.x * (1.0 - ratio))
	var target_offset := -int(maxf(0.0, size.x * ratio))
	if chapter_split.split_offset != target_offset:
		chapter_split.split_offset = target_offset


func _collect_chunk_nodes() -> void:
	_chunk_items.clear()

	for child in chunk_root.get_children():
		if child is Node3D and child.name.begins_with("Chunk_"):
			var chunk_node := child as Node3D
			_sync_chunk_geometry(chunk_node)
			_chunk_items.append(
				{
					"node": chunk_node,
					"speed": _rng.randf_range(shrink_speed_min, shrink_speed_max),
					"phase": _rng.randf_range(0.0, TAU),
					"wobble": _rng.randf_range(0.0, TAU),
					"sign": _extract_sign_from_chunk_name(chunk_node.name),
					"jitter_phase_x": _rng.randf_range(0.0, TAU),
					"jitter_phase_y": _rng.randf_range(0.0, TAU),
					"jitter_phase_z": _rng.randf_range(0.0, TAU),
					"jitter_speed_x": _rng.randf_range(jitter_speed_min, jitter_speed_max),
					"jitter_speed_y": _rng.randf_range(jitter_speed_min, jitter_speed_max),
					"jitter_speed_z": _rng.randf_range(jitter_speed_min, jitter_speed_max),
					"is_selected": false,
					"is_swapping": false,
				}
			)


func _sync_chunk_geometry(chunk_node: Node3D) -> void:
	var sign_vec := _extract_sign_from_chunk_name(chunk_node.name)
	var mesh_instance := chunk_node.get_node_or_null("ChunkMesh") as MeshInstance3D
	if mesh_instance == null:
		mesh_instance = MeshInstance3D.new()
		mesh_instance.name = "ChunkMesh"
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		chunk_node.add_child(mesh_instance)

	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = sphere_radius
	sphere_mesh.height = sphere_radius * 2.0
	sphere_mesh.radial_segments = 48
	sphere_mesh.rings = 30
	mesh_instance.mesh = sphere_mesh
	mesh_instance.material_override = _create_octant_clip_material(sign_vec)
	mesh_instance.position = Vector3.ZERO
	mesh_instance.visible = true
	_ensure_cut_caps(chunk_node, sign_vec)


func _extract_sign_from_chunk_name(node_name: String) -> Vector3:
	var parts := node_name.split("_")
	if parts.size() < 4:
		return Vector3.ONE
	return Vector3(
		-1.0 if parts[1] == "n1" else 1.0,
		-1.0 if parts[2] == "n1" else 1.0,
		-1.0 if parts[3] == "n1" else 1.0
	)


func _update_chunk_shrink(_delta: float) -> void:
	var min_s := maxf(0.01, shrink_min_scale)
	var max_s := min_s * 1.2
	if _chunk_items.is_empty():
		return

	for item in _chunk_items:
		var node := item.get("node") as Node3D
		if node == null or not is_instance_valid(node):
			continue
		if bool(item.get("is_swapping", false)):
			# Keep tween-driven position while swapping.
			continue
		var speed := float(item.get("speed", 1.0))
		var phase := float(item.get("phase", 0.0))
		var wobble := float(item.get("wobble", 0.0))
		var sign_vec: Vector3 = item.get("sign", Vector3.ONE)
		var jpx := float(item.get("jitter_phase_x", 0.0))
		var jpy := float(item.get("jitter_phase_y", 0.0))
		var jpz := float(item.get("jitter_phase_z", 0.0))
		var jsx := float(item.get("jitter_speed_x", 0.12))
		var jsy := float(item.get("jitter_speed_y", 0.15))
		var jsz := float(item.get("jitter_speed_z", 0.18))
		var wave_a := sin(_time_sec * speed + phase)
		var wave_b := sin(_time_sec * (speed * 0.61 + 0.37) + wobble)
		var irregular := clampf(0.5 + wave_a * 0.35 + wave_b * 0.22, 0.0, 1.0)
		var scale_value := lerpf(min_s, max_s, irregular)
		node.scale = Vector3.ONE * scale_value
		if bool(item.get("is_selected", false)):
			node.scale *= 1.04
		var jitter := Vector3(
			sin(_time_sec * jsx + jpx),
			sin(_time_sec * jsy + jpy),
			sin(_time_sec * jsz + jpz)
		) * jitter_amplitude
		node.position = sign_vec * chunk_gap + jitter


func _create_chunk_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.78, 0.9, 1.0, 0.32)
	mat.roughness = 0.06
	mat.metallic = 0.0
	mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	mat.clearcoat_enabled = true
	mat.clearcoat = 1.0
	mat.clearcoat_roughness = 0.08
	mat.emission_enabled = true
	mat.emission = Color(0.12, 0.22, 0.3, 1.0)
	mat.emission_energy_multiplier = 0.35
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat


func _create_octant_clip_material(sign_vec: Vector3) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_disabled;

uniform vec3 side_sign = vec3(1.0, 1.0, 1.0);
uniform float cut_epsilon = 0.0005;
uniform vec4 base_color : source_color = vec4(0.78, 0.9, 1.0, 0.32);
uniform float roughness : hint_range(0.0, 1.0) = 0.06;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform vec3 emission_color = vec3(0.12, 0.22, 0.3);
uniform float emission_strength : hint_range(0.0, 4.0) = 0.35;
uniform float specular_strength : hint_range(0.0, 1.0) = 0.9;
uniform float rim_strength : hint_range(0.0, 2.0) = 0.22;
uniform float rim_power : hint_range(0.5, 8.0) = 2.4;

varying vec3 local_pos;

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	if (side_sign.x * local_pos.x < -cut_epsilon) { discard; }
	if (side_sign.y * local_pos.y < -cut_epsilon) { discard; }
	if (side_sign.z * local_pos.z < -cut_epsilon) { discard; }

	ALBEDO = base_color.rgb;
	ROUGHNESS = roughness;
	METALLIC = metallic;
	SPECULAR = specular_strength;
	float rim = pow(clamp(1.0 - dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), rim_power);
	EMISSION = emission_color * emission_strength + vec3(rim * rim_strength);
	ALPHA = base_color.a;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("side_sign", sign_vec)
	return mat


func _ensure_cut_caps(chunk_node: Node3D, sign_vec: Vector3) -> void:
	_ensure_single_cut_cap(chunk_node, "CapX", 0, sign_vec)
	_ensure_single_cut_cap(chunk_node, "CapY", 1, sign_vec)
	_ensure_single_cut_cap(chunk_node, "CapZ", 2, sign_vec)


func _ensure_single_cut_cap(chunk_node: Node3D, cap_name: String, axis: int, sign_vec: Vector3) -> void:
	var cap := chunk_node.get_node_or_null(cap_name) as MeshInstance3D
	if cap == null:
		cap = MeshInstance3D.new()
		cap.name = cap_name
		cap.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		chunk_node.add_child(cap)

	cap.mesh = _build_quarter_disk_mesh(axis, sign_vec)
	cap.position = Vector3.ZERO
	cap.rotation = Vector3.ZERO
	cap.material_override = _create_chunk_material()
	cap.visible = true


func _build_quarter_disk_mesh(axis: int, sign_vec: Vector3) -> ArrayMesh:
	var segments := 32
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var angles := _quarter_angle_range(axis, sign_vec)
	var start_angle := angles.x
	var end_angle := angles.y
	var normal := Vector3.ZERO
	match axis:
		0:
			normal = Vector3(1.0, 0.0, 0.0)
		1:
			normal = Vector3(0.0, 1.0, 0.0)
		_:
			normal = Vector3(0.0, 0.0, 1.0)

	for i in range(segments):
		var t0 := float(i) / float(segments)
		var t1 := float(i + 1) / float(segments)
		var a0 := lerpf(start_angle, end_angle, t0)
		var a1 := lerpf(start_angle, end_angle, t1)
		var p0 := _cap_point(axis, 0.0, 0.0)
		var p1 := _cap_point(axis, cos(a0) * sphere_radius, sin(a0) * sphere_radius)
		var p2 := _cap_point(axis, cos(a1) * sphere_radius, sin(a1) * sphere_radius)

		st.set_normal(normal)
		st.add_vertex(p0)
		st.set_normal(normal)
		st.add_vertex(p1)
		st.set_normal(normal)
		st.add_vertex(p2)

	return st.commit()


func _quarter_angle_range(axis: int, sign_vec: Vector3) -> Vector2:
	var s_a := 1.0
	var s_b := 1.0
	match axis:
		0:
			s_a = sign_vec.y
			s_b = sign_vec.z
		1:
			s_a = sign_vec.x
			s_b = sign_vec.z
		_:
			s_a = sign_vec.x
			s_b = sign_vec.y

	if s_a > 0.0 and s_b > 0.0:
		return Vector2(0.0, PI * 0.5)
	if s_a < 0.0 and s_b > 0.0:
		return Vector2(PI * 0.5, PI)
	if s_a < 0.0 and s_b < 0.0:
		return Vector2(PI, PI * 1.5)
	return Vector2(PI * 1.5, TAU)


func _cap_point(axis: int, a: float, b: float) -> Vector3:
	match axis:
		0:
			return Vector3(0.0, a, b)
		1:
			return Vector3(a, 0.0, b)
		_:
			return Vector3(a, b, 0.0)


func _handle_chunk_click(screen_pos: Vector2) -> bool:
	if _icon_swap_running:
		return false
	var clicked := _pick_chunk_at_screen_position(screen_pos)
	if clicked == null:
		return false

	if _selected_chunk == clicked:
		_set_chunk_selected(clicked, false)
		_selected_chunk = null
		return true

	if _selected_chunk == null:
		_set_chunk_selected(clicked, true)
		_selected_chunk = clicked
		return true

	var first := _selected_chunk
	var second := clicked
	_set_chunk_selected(second, true)
	_icon_swap_running = true
	_swap_instrument_icons(first, second)
	return true


func _pick_chunk_at_screen_position(screen_pos: Vector2) -> Node3D:
	var container_rect := left_3d.get_global_rect()
	if not container_rect.has_point(screen_pos):
		return null

	var best_chunk: Node3D = null
	var best_dist := INF
	var max_pick := maxf(4.0, click_pick_radius_px)
	for item in _chunk_items:
		var chunk := item.get("node") as Node3D
		if chunk == null or not is_instance_valid(chunk):
			continue
		var world_pos := chunk.global_transform.origin
		if camera_3d.is_position_behind(world_pos):
			continue
		var chunk_screen_in_viewport := camera_3d.unproject_position(world_pos)
		var chunk_screen_global := left_3d.get_global_rect().position + chunk_screen_in_viewport
		var dist := chunk_screen_global.distance_to(screen_pos)
		if dist < best_dist and dist <= max_pick:
			best_dist = dist
			best_chunk = chunk
	return best_chunk


func _ray_hits_sphere_t(ray_origin: Vector3, ray_dir: Vector3, center: Vector3, radius: float) -> float:
	var oc := ray_origin - center
	var a := ray_dir.dot(ray_dir)
	var b := 2.0 * oc.dot(ray_dir)
	var c := oc.dot(oc) - radius * radius
	var disc := b * b - 4.0 * a * c
	if disc < 0.0:
		return -1.0
	var sqrt_disc := sqrt(disc)
	var inv := 0.5 / maxf(a, 0.000001)
	var t0 := (-b - sqrt_disc) * inv
	var t1 := (-b + sqrt_disc) * inv
	if t0 >= 0.0:
		return t0
	if t1 >= 0.0:
		return t1
	return -1.0


func _screen_to_left_viewport_position(screen_pos: Vector2, container_rect: Rect2) -> Vector2:
	var local := screen_pos - container_rect.position
	var uv := Vector2(
		local.x / maxf(1.0, container_rect.size.x),
		local.y / maxf(1.0, container_rect.size.y)
	)
	uv.x = clampf(uv.x, 0.0, 1.0)
	uv.y = clampf(uv.y, 0.0, 1.0)
	return Vector2(
		uv.x * float(left_viewport.size.x),
		uv.y * float(left_viewport.size.y)
	)


func _set_chunk_selected(chunk: Node3D, selected: bool) -> void:
	for i in range(_chunk_items.size()):
		if _chunk_items[i].get("node") == chunk:
			_chunk_items[i]["is_selected"] = selected
			_apply_chunk_glow(chunk, selected)
			return


func _apply_chunk_glow(chunk: Node3D, on: bool) -> void:
	for child in chunk.get_children():
		if child is MeshInstance3D:
			var mesh_instance := child as MeshInstance3D
			var mat := mesh_instance.material_override
			if mat is ShaderMaterial:
				var shader_mat := mat as ShaderMaterial
				shader_mat.set_shader_parameter("emission_strength", selected_glow_strength if on else 0.35)
			elif mat is StandardMaterial3D:
				var std := mat as StandardMaterial3D
				std.emission_enabled = true
				std.emission_energy_multiplier = selected_glow_strength if on else 1.35

	var light_a := chunk.get_node_or_null("SelectLightA") as OmniLight3D
	var light_b := chunk.get_node_or_null("SelectLightB") as OmniLight3D
	if light_a == null:
		light_a = OmniLight3D.new()
		light_a.name = "SelectLightA"
		light_a.position = Vector3(0.18, 0.18, 0.18)
		light_a.light_color = Color(0.92, 0.98, 1.0, 1.0)
		light_a.light_energy = 1.6
		light_a.omni_range = 1.2
		chunk.add_child(light_a)
	if light_b == null:
		light_b = OmniLight3D.new()
		light_b.name = "SelectLightB"
		light_b.position = Vector3(-0.18, -0.18, -0.18)
		light_b.light_color = Color(0.92, 0.98, 1.0, 1.0)
		light_b.light_energy = 1.6
		light_b.omni_range = 1.2
		chunk.add_child(light_b)
	light_a.visible = on
	light_b.visible = on


func _find_item_index_by_chunk(chunk: Node3D) -> int:
	for i in range(_chunk_items.size()):
		if _chunk_items[i].get("node") == chunk:
			return i
	return -1


func _swap_instrument_icons(chunk_a: Node3D, chunk_b: Node3D) -> void:
	var sprite_a := _get_chunk_instrument_sprite(chunk_a)
	var sprite_b := _get_chunk_instrument_sprite(chunk_b)
	if sprite_a == null or sprite_b == null:
		_set_chunk_selected(chunk_a, false)
		_set_chunk_selected(chunk_b, false)
		_selected_chunk = null
		_icon_swap_running = false
		return

	var fade_out := create_tween()
	fade_out.set_parallel(true)
	fade_out.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	fade_out.tween_property(sprite_a, "modulate:a", 0.0, icon_swap_fade_sec)
	fade_out.tween_property(sprite_b, "modulate:a", 0.0, icon_swap_fade_sec)
	fade_out.finished.connect(
		Callable(self, "_on_icon_fade_out_finished").bind(chunk_a, chunk_b, sprite_a, sprite_b),
		CONNECT_ONE_SHOT
	)


func _on_icon_fade_out_finished(
	chunk_a: Node3D,
	chunk_b: Node3D,
	sprite_a: Sprite3D,
	sprite_b: Sprite3D
) -> void:
	var tex_a := sprite_a.texture
	var tex_b := sprite_b.texture
	var size_a := sprite_a.pixel_size
	var size_b := sprite_b.pixel_size
	sprite_a.texture = tex_b
	sprite_b.texture = tex_a
	sprite_a.pixel_size = size_b
	sprite_b.pixel_size = size_a

	var fade_in := create_tween()
	fade_in.set_parallel(true)
	fade_in.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	fade_in.tween_property(sprite_a, "modulate:a", 1.0, icon_swap_fade_sec)
	fade_in.tween_property(sprite_b, "modulate:a", 1.0, icon_swap_fade_sec)
	fade_in.finished.connect(Callable(self, "_on_icon_swap_finished").bind(chunk_a, chunk_b), CONNECT_ONE_SHOT)


func _on_icon_swap_finished(chunk_a: Node3D, chunk_b: Node3D) -> void:
	_set_chunk_selected(chunk_a, false)
	_set_chunk_selected(chunk_b, false)
	_selected_chunk = null
	_icon_swap_running = false


func _get_chunk_instrument_sprite(chunk: Node3D) -> Sprite3D:
	if chunk == null:
		return null
	for child in chunk.get_children():
		if child is Sprite3D and String(child.name).begins_with("Instrument_"):
			return child as Sprite3D
	return null


func _update_rotation_input(delta: float) -> void:
	var direction := 0.0
	if Input.is_key_pressed(KEY_A):
		direction -= 1.0
	if Input.is_key_pressed(KEY_D):
		direction += 1.0
	if direction == 0.0:
		return
	chunk_root.rotate_y(deg_to_rad(manual_rotate_speed_deg) * direction * delta)
