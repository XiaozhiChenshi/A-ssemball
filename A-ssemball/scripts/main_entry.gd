extends Control

class OpeningTitleParticleCanvas:
	extends Control

	var particle_data: Array[Dictionary] = []
	var timer: float = 0.0
	var particle_size: float = 3.0

	func _draw() -> void:
		for data in particle_data:
			var delay := float(data["delay"])
			var local_t := maxf(0.0, timer - delay)
			var start: Vector2 = data["start"]
			var burst: Vector2 = data["burst"]
			var ring: Vector2 = data["ring"]
			var escape: Vector2 = data["escape"]
			var pos := start
			var alpha := 1.0
			if local_t < 0.35:
				pos = start
			elif local_t < 1.35:
				var burst_t := smoothstep(0.0, 1.0, (local_t - 0.35) / 1.0)
				pos = start.lerp(burst, burst_t)
			elif local_t < 1.85:
				pos = burst
			elif local_t < 3.55:
				var ring_t := smoothstep(0.0, 1.0, (local_t - 1.85) / 1.7)
				pos = burst.lerp(ring, ring_t)
			elif local_t < 4.15:
				pos = ring
			elif local_t < 5.05:
				var unstable_t := smoothstep(0.0, 1.0, (local_t - 4.15) / 0.9)
				var wobble := Vector2(sin(unstable_t * 24.0 + delay * 91.0), cos(unstable_t * 19.0 + delay * 73.0)) * 18.0 * unstable_t
				pos = ring + wobble
			elif local_t < 5.45:
				var hold_t := (local_t - 5.05) / 0.4
				var hold_wobble := Vector2(sin(hold_t * 18.0 + delay * 91.0), cos(hold_t * 15.0 + delay * 73.0)) * 18.0
				pos = ring + hold_wobble
			else:
				var fade := clampf((local_t - 5.45) / 1.45, 0.0, 1.0)
				pos = ring.lerp(escape, smoothstep(0.0, 1.0, fade))
				alpha = 1.0 - fade
			draw_rect(Rect2(pos - Vector2.ONE * particle_size * 0.5, Vector2.ONE * particle_size), Color(0.94, 0.93, 0.9, alpha), true)

const InputMappingStateRef = preload("res://scripts/input_mapping_state.gd")
const INTRO_SCENE: PackedScene = preload("res://scenes/intro_interactive.tscn")
const INTRO_V2_SCENE: PackedScene = preload("res://scenes/intro_corridor_v2.tscn")
const FONT_PREVIEW_SCENE: PackedScene = preload("res://scenes/font_preview.tscn")
const CHAPTER_1_LEVEL_1_SCENE: PackedScene = preload("res://scenes/levels/chapter_1/level_1.tscn")
const CHAPTER_1_LEVEL_2_SCENE: PackedScene = preload("res://scenes/levels/chapter_1/level_2.tscn")
const CHAPTER_2_LEVEL_1_SCENE: PackedScene = preload("res://scenes/levels/chapter_2/level_1.tscn")
const CHAPTER_2_LEVEL_2_SCENE: PackedScene = preload("res://scenes/levels/chapter_2/level_2.tscn")
const CHAPTER_3_LEVEL_1_SCENE: PackedScene = preload("res://scenes/levels/chapter_3/level_1.tscn")
const CHAPTER_3_LEVEL_2_SCENE: PackedScene = preload("res://scenes/levels/chapter_3/level_2.tscn")
const CHAPTER_1_NOISE_LOOP_AUDIO: AudioStream = preload("res://assets/audio/底噪.mp3")
const MENU_OPENING_AUDIO: AudioStream = preload("res://assets/audio/初始界面 .mp3")
const TRAN_1_TEX: Texture2D = preload("res://assets/materials/tran1.png")
const TRAN_2_TEX: Texture2D = preload("res://assets/materials/tran2.png")
const TRAN_3_TEX: Texture2D = preload("res://assets/materials/tran3.png")
const TRAN_4_TEX: Texture2D = preload("res://assets/materials/tran4.png")
const OPENING_TITLE_FONT: FontFile = preload("res://assets/fonts/IMFellGreatPrimerSC-Regular.ttf")
const OPENING_TYPE_AUDIO: AudioStream = preload("res://assets/audio/键盘打字.mp3")
const CHAPTER_2_LEVEL_1_SCENE_INDEX: int = 2
const CHAPTER_2_LEVEL_2_SCENE_INDEX: int = 3
const OPENING_TITLE_TEXT: String = "A-ssemball"
const OPENING_TITLE_ERRORS: PackedStringArray = [
	"A-zsemball",
	"A-szemball",
	"A-ssembsll",
	"A-ssemnall",
	"A-ssrmball",
	"A-ssembzll",
	"A-ssembakk",
	"A-ssembalo",
	"A-xsemball",
	"A-ssembsll",
]

@export var fade_to_black_sec: float = 0.45
@export var reveal_game_sec: float = 0.45
@export var chapter_scene_overrides: Array[PackedScene] = []
@export_range(0.01, 1.5, 0.01) var chapter_transition_step_sec: float = 0.65
@export_range(0.2, 6.0, 0.1) var font_preview_hold_sec: float = 3.0

@onready var game_root: Control = $GameRoot
@onready var menu_layer: Control = $MenuLayer
@onready var fade_layer: ColorRect = $FadeLayer

var _is_starting: bool = false
var _chapter_scenes: Array[PackedScene] = []
var _current_chapter_scene_index: int = -1
var _active_chapter_node: Node = null
var _chapter_transition_running: bool = false
var _requested_start_chapter_scene_index: int = 0
var _chapter_transition_canvas: CanvasLayer
var _chapter_transition_overlay: TextureRect
var _chapter_1_noise_player: AudioStreamPlayer
var _menu_opening_player: AudioStreamPlayer
var _opening_type_player: AudioStreamPlayer
var _debug_mapping_label: Label
var _font_preview_hold_time: float = 0.0
var _font_preview_active: bool = false
var _font_preview_node: Control
var _use_intro_v2_next: bool = false
var _start_ch3_paint_roll_direct: bool = false
var _opening_title_root: Control
var _opening_title_bg: ColorRect
var _opening_title_label: Label
var _opening_title_caret: ColorRect
var _opening_title_prompt: Label
var _opening_particle_canvas: OpeningTitleParticleCanvas
var _opening_title_particle_data: Array[Dictionary] = []
var _opening_title_waiting: bool = false
var _opening_title_accept_requested: bool = false
var _opening_title_fast_accept: bool = false
var _opening_title_final_sequence: bool = false
var _opening_title_transition_finished: bool = false
var _opening_title_text: String = ""
var _opening_title_target: String = ""
var _opening_title_phase: String = "typing"
var _opening_title_attempt_index: int = 0
var _opening_title_char_index: int = 0
var _opening_title_timer: float = 0.0
var _opening_title_pause: float = 0.0
var _opening_title_elapsed: float = 0.0
var _opening_particle_timer: float = 0.0


func _process(delta: float) -> void:
	_update_font_preview_hold(delta)
	_update_opening_title(delta)


func _ready() -> void:
	fade_layer.color = Color(0.0, 0.0, 0.0, 0.0)
	_chapter_scenes = _resolve_chapter_scenes()
	_ensure_chapter_transition_overlay()
	_ensure_audio_players()
	_ensure_debug_mapping_label()
	_setup_opening_title()


func _unhandled_input(event: InputEvent) -> void:
	if _font_preview_active:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_0 or event.keycode == KEY_KP_0:
			_is_starting = true
			get_viewport().set_input_as_handled()
			_use_intro_v2_next = true
			_start_sequence(false, 0)
			return

	if _is_starting:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			_is_starting = true
			get_viewport().set_input_as_handled()
			_use_intro_v2_next = true
			_start_space_sequence()
			return
		if event.keycode == KEY_1 or event.keycode == KEY_KP_1:
			_is_starting = true
			get_viewport().set_input_as_handled()
			_start_sequence(true, 0)
			return
		if event.keycode == KEY_2 or event.keycode == KEY_KP_2:
			_is_starting = true
			get_viewport().set_input_as_handled()
			_start_sequence(true, 1)
			return
		if event.keycode == KEY_3 or event.keycode == KEY_KP_3:
			_is_starting = true
			get_viewport().set_input_as_handled()
			_start_sequence(true, 2)
			return
		if event.keycode == KEY_4 or event.keycode == KEY_KP_4:
			_is_starting = true
			get_viewport().set_input_as_handled()
			_start_sequence(true, 3)
			return
		if event.keycode == KEY_5 or event.keycode == KEY_KP_5:
			_is_starting = true
			get_viewport().set_input_as_handled()
			_start_sequence(true, 4)
			return
		if event.keycode == KEY_6 or event.keycode == KEY_KP_6:
			_is_starting = true
			get_viewport().set_input_as_handled()
			_start_direct_chapter_sequence(5)
			return


func _start_direct_chapter_sequence(start_chapter_scene_index: int) -> void:
	_start_ch3_paint_roll_direct = false
	_requested_start_chapter_scene_index = clampi(
		start_chapter_scene_index,
		0,
		maxi(0, _chapter_scenes.size() - 1)
	)
	var fade_out := create_tween()
	fade_out.tween_property(fade_layer, "color:a", 1.0, fade_to_black_sec)
	await fade_out.finished

	menu_layer.visible = false
	fade_layer.color = Color(0.0, 0.0, 0.0, 1.0)
	await _start_chapter_flow()

	var show_game := create_tween()
	show_game.tween_property(fade_layer, "color:a", 0.0, reveal_game_sec)
	await show_game.finished
	_notify_active_chapter_transition_finished()


func _update_font_preview_hold(delta: float) -> void:
	if _is_starting or _font_preview_active or not menu_layer.visible:
		_font_preview_hold_time = 0.0
		return
	if Input.is_physical_key_pressed(KEY_P):
		_font_preview_hold_time += delta
		if _font_preview_hold_time >= font_preview_hold_sec:
			_font_preview_hold_time = 0.0
			_open_font_preview()
		return
	_font_preview_hold_time = 0.0


func _open_font_preview() -> void:
	if _font_preview_active:
		return
	_font_preview_active = true
	menu_layer.visible = false
	_clear_game_root()
	_font_preview_node = FONT_PREVIEW_SCENE.instantiate() as Control
	game_root.add_child(_font_preview_node)
	_fit_full_rect(_font_preview_node)
	if _font_preview_node.has_signal("preview_closed"):
		_font_preview_node.connect("preview_closed", Callable(self, "_close_font_preview"), CONNECT_ONE_SHOT)


func _close_font_preview() -> void:
	if _font_preview_node != null and is_instance_valid(_font_preview_node):
		_font_preview_node.queue_free()
	_font_preview_node = null
	_clear_game_root()
	menu_layer.visible = true
	_font_preview_active = false


func _start_space_sequence() -> void:
	await _request_opening_title_accept()
	_start_sequence(false, 0)


func _request_opening_title_accept() -> void:
	_opening_title_accept_requested = true
	_opening_title_fast_accept = true
	_opening_title_phase = "deleting"
	_opening_title_timer = 0.0
	while not _opening_title_transition_finished:
		await get_tree().process_frame


func _start_sequence(skip_intro_to_post_click_effect: bool, start_chapter_scene_index: int = 0) -> void:
	if start_chapter_scene_index != 4:
		_start_ch3_paint_roll_direct = false
	_requested_start_chapter_scene_index = clampi(
		start_chapter_scene_index,
		0,
		maxi(0, _chapter_scenes.size() - 1)
	)
	var fade_out := create_tween()
	fade_out.tween_property(fade_layer, "color:a", 1.0, fade_to_black_sec)
	await fade_out.finished

	menu_layer.visible = false
	var intro := _spawn_intro_scene()

	var show_intro := create_tween()
	show_intro.tween_property(fade_layer, "color:a", 0.0, reveal_game_sec)
	await show_intro.finished

	if intro != null:
		if skip_intro_to_post_click_effect and intro.has_method("start_post_goal_effect_from_menu"):
			intro.call("start_post_goal_effect_from_menu")
		await intro.intro_finished

	fade_layer.color = Color(0.0, 0.0, 0.0, 1.0)
	await _start_chapter_flow()

	var show_game := create_tween()
	show_game.tween_property(fade_layer, "color:a", 0.0, reveal_game_sec)
	await show_game.finished
	_notify_active_chapter_transition_finished()


func _spawn_intro_scene() -> Node:
	_clear_game_root()

	var scene := INTRO_V2_SCENE if _use_intro_v2_next else INTRO_SCENE
	_use_intro_v2_next = false
	var intro := scene.instantiate()
	game_root.add_child(intro)
	if intro is Control:
		_fit_full_rect(intro as Control)
	return intro


func _start_chapter_flow() -> void:
	_current_chapter_scene_index = _requested_start_chapter_scene_index - 1
	if _requested_start_chapter_scene_index == CHAPTER_2_LEVEL_2_SCENE_INDEX:
		_chapter_transition_running = true
		await _play_chapter_2_transition(CHAPTER_2_LEVEL_2_SCENE_INDEX)
		_chapter_transition_running = false
		return
	_spawn_next_chapter()


func _spawn_next_chapter() -> void:
	var next_index := _current_chapter_scene_index + 1
	if next_index >= _chapter_scenes.size():
		_on_all_chapters_completed()
		return

	_current_chapter_scene_index = next_index
	var chapter_scene := _chapter_scenes[_current_chapter_scene_index]
	if chapter_scene == null:
		push_warning("Chapter scene at index %d is null, skipping." % _current_chapter_scene_index)
		_spawn_next_chapter()
		return

	_clear_game_root()
	var chapter := chapter_scene.instantiate()
	_active_chapter_node = chapter
	game_root.add_child(chapter)

	if chapter is Control:
		_fit_full_rect(chapter as Control)

	if chapter.has_method("_set_game_started"):
		chapter.call("_set_game_started", true)
	if _current_chapter_scene_index == 4 and _requested_start_chapter_scene_index == 4:
		if chapter.has_method("_set_dev_paint_roll_skip_enabled"):
			chapter.call("_set_dev_paint_roll_skip_enabled", true)
		if _start_ch3_paint_roll_direct and chapter.has_method("_set_dev_jump_to_paint_roll_enabled"):
			chapter.call("_set_dev_jump_to_paint_roll_enabled", true)
			_start_ch3_paint_roll_direct = false
	_update_chapter_audio_state(_current_chapter_scene_index)

	if chapter.has_signal("chapter_completed"):
		if not chapter.is_connected("chapter_completed", Callable(self, "_on_chapter_completed")):
			chapter.connect("chapter_completed", Callable(self, "_on_chapter_completed"), CONNECT_ONE_SHOT)
	else:
		push_warning("Chapter scene does not expose `chapter_completed` signal: %s" % chapter_scene.resource_path)


func _on_chapter_completed(_chapter_index: int = 0) -> void:
	if _chapter_transition_running:
		return

	var next_index := _current_chapter_scene_index + 1
	_chapter_transition_running = true
	if _should_use_chapter_2_transition(_current_chapter_scene_index, next_index):
		await _play_chapter_2_transition(next_index)
		_notify_active_chapter_transition_finished()
		_chapter_transition_running = false
		return

	await _fade_to_black()
	_spawn_next_chapter()
	await _fade_from_black()
	_notify_active_chapter_transition_finished()
	_chapter_transition_running = false


func _on_all_chapters_completed() -> void:
	# Keep the last chapter visible and unlock restart from menu key flow.
	_is_starting = false
	_update_chapter_audio_state(-1)


func _fade_to_black() -> void:
	var t := create_tween()
	t.tween_property(fade_layer, "color:a", 1.0, fade_to_black_sec)
	await t.finished


func _fade_from_black() -> void:
	var t := create_tween()
	t.tween_property(fade_layer, "color:a", 0.0, reveal_game_sec)
	await t.finished


func _resolve_chapter_scenes() -> Array[PackedScene]:
	var resolved: Array[PackedScene] = []
	for scene in chapter_scene_overrides:
		if scene != null:
			resolved.append(scene)
	if not resolved.is_empty():
		return resolved
	return [
		CHAPTER_1_LEVEL_1_SCENE,
		CHAPTER_1_LEVEL_2_SCENE,
		CHAPTER_2_LEVEL_1_SCENE,
		CHAPTER_2_LEVEL_2_SCENE,
		CHAPTER_3_LEVEL_1_SCENE,
		CHAPTER_3_LEVEL_2_SCENE,
	]


func _clear_game_root() -> void:
	for child in game_root.get_children():
		child.queue_free()


func _fit_full_rect(node: Control) -> void:
	node.set_anchors_preset(Control.PRESET_FULL_RECT)
	node.offset_left = 0.0
	node.offset_top = 0.0
	node.offset_right = 0.0
	node.offset_bottom = 0.0


func _ensure_chapter_transition_overlay() -> void:
	if _chapter_transition_canvas == null or not is_instance_valid(_chapter_transition_canvas):
		_chapter_transition_canvas = CanvasLayer.new()
		_chapter_transition_canvas.name = "ChapterTransitionCanvas"
		_chapter_transition_canvas.layer = 120
		add_child(_chapter_transition_canvas)
	if _chapter_transition_overlay != null and is_instance_valid(_chapter_transition_overlay):
		return

	_chapter_transition_overlay = TextureRect.new()
	_chapter_transition_overlay.name = "ChapterTransitionOverlay"
	_chapter_transition_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_chapter_transition_overlay.offset_left = 0.0
	_chapter_transition_overlay.offset_top = 0.0
	_chapter_transition_overlay.offset_right = 0.0
	_chapter_transition_overlay.offset_bottom = 0.0
	_chapter_transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chapter_transition_overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_chapter_transition_overlay.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_chapter_transition_overlay.visible = false
	_chapter_transition_overlay.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_chapter_transition_canvas.add_child(_chapter_transition_overlay)


func _should_use_chapter_2_transition(from_scene_index: int, to_scene_index: int) -> bool:
	return from_scene_index == CHAPTER_2_LEVEL_1_SCENE_INDEX and to_scene_index == CHAPTER_2_LEVEL_2_SCENE_INDEX


func _play_chapter_2_transition(next_index: int) -> void:
	_ensure_chapter_transition_overlay()
	fade_layer.color.a = 0.0

	var forward_textures: Array[Texture2D] = [TRAN_1_TEX, TRAN_2_TEX, TRAN_3_TEX, TRAN_4_TEX]
	var backward_textures: Array[Texture2D] = [TRAN_3_TEX, TRAN_2_TEX, TRAN_1_TEX]

	_chapter_transition_overlay.visible = true
	_chapter_transition_overlay.modulate.a = 1.0

	for texture in forward_textures:
		await _switch_transition_texture(texture)

	_current_chapter_scene_index = next_index - 1
	_spawn_next_chapter()

	for texture in backward_textures:
		await _switch_transition_texture(texture)

	_chapter_transition_overlay.visible = false


func _switch_transition_texture(texture: Texture2D) -> void:
	if _chapter_transition_canvas != null and is_instance_valid(_chapter_transition_canvas):
		_chapter_transition_canvas.layer = 120
	_chapter_transition_overlay.texture = texture
	await get_tree().create_timer(maxf(0.01, chapter_transition_step_sec)).timeout


func _tween_transition_overlay_alpha(target_alpha: float, duration: float) -> void:
	if _chapter_transition_overlay == null or not is_instance_valid(_chapter_transition_overlay):
		return
	var tween := create_tween()
	tween.tween_property(_chapter_transition_overlay, "modulate:a", clampf(target_alpha, 0.0, 1.0), maxf(0.001, duration))
	await tween.finished


func _setup_opening_title() -> void:
	if _opening_title_root != null and is_instance_valid(_opening_title_root):
		return

	var old_title := menu_layer.get_node_or_null("Title")
	if old_title is CanvasItem:
		(old_title as CanvasItem).visible = false
	var old_hint := menu_layer.get_node_or_null("Title2")
	if old_hint is CanvasItem:
		(old_hint as CanvasItem).visible = false
	var old_bg := menu_layer.get_node_or_null("MenuBg")
	if old_bg is CanvasItem:
		(old_bg as CanvasItem).visible = false

	_opening_title_root = Control.new()
	_opening_title_root.name = "OpeningTypewriterTitle"
	_opening_title_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_opening_title_root.z_index = 50
	_opening_title_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_layer.add_child(_opening_title_root)

	_opening_title_bg = ColorRect.new()
	_opening_title_bg.name = "BlackBackground"
	_opening_title_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_opening_title_bg.color = Color.BLACK
	_opening_title_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_opening_title_root.add_child(_opening_title_bg)

	_opening_title_label = _make_opening_title_label(104, Color(0.94, 0.93, 0.9, 1.0))
	_opening_title_root.add_child(_opening_title_label)

	_opening_title_caret = ColorRect.new()
	_opening_title_caret.name = "Caret"
	_opening_title_caret.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_opening_title_caret.color = Color(0.94, 0.93, 0.9, 0.9)
	_opening_title_caret.visible = false
	_opening_title_root.add_child(_opening_title_caret)

	_opening_title_prompt = _make_opening_title_label(34, Color(0.94, 0.93, 0.9, 1.0))
	_opening_title_prompt.text = "[space]"
	_opening_title_prompt.z_index = 80
	_opening_title_prompt.modulate.a = 0.0
	_opening_title_root.add_child(_opening_title_prompt)

	_start_opening_title_attempt(false)


func _make_opening_title_label(font_size: int, font_color: Color) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", OPENING_TITLE_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)
	return label


func _update_opening_title(delta: float) -> void:
	if _opening_title_root == null or not is_instance_valid(_opening_title_root):
		return

	_opening_title_root.visible = menu_layer.visible and not _font_preview_active
	if not _opening_title_root.visible:
		return

	var viewport_size := get_viewport_rect().size
	_opening_title_root.size = viewport_size
	_opening_title_label.size = Vector2(viewport_size.x, 150.0)
	_opening_title_label.position = Vector2(0.0, viewport_size.y * 0.43 - 75.0)
	_opening_title_prompt.size = Vector2(360.0, 52.0)
	_opening_title_prompt.position = Vector2(viewport_size.x * 0.5 - 180.0, viewport_size.y * 0.43 + 132.0)

	if _opening_title_final_sequence:
		_update_opening_title_particles(delta, viewport_size)
		return

	_opening_title_elapsed += delta
	_update_typewriter(delta)
	_opening_title_label.text = _opening_title_text + "|"

	var prompt_flash := 0.68 + 0.18 * sin(Time.get_ticks_msec() * 0.004)
	var prompt_target := prompt_flash if _opening_title_elapsed >= 3.0 and not _opening_title_accept_requested else 0.0
	_opening_title_prompt.modulate.a = lerpf(_opening_title_prompt.modulate.a, prompt_target, minf(1.0, delta * 8.0))


func _update_typewriter(delta: float) -> void:
	_opening_title_timer += delta
	match _opening_title_phase:
		"typing":
			if _opening_title_timer >= _typing_step_duration():
				_opening_title_timer = 0.0
				if _opening_title_char_index < _opening_title_target.length():
					_opening_title_char_index += 1
					_opening_title_text = _opening_title_target.substr(0, _opening_title_char_index)
					_play_opening_type_sound(1.0)
				else:
					if _opening_title_accept_requested and _opening_title_target == OPENING_TITLE_TEXT:
						_opening_title_phase = "final_hold"
						_opening_title_pause = 0.9
					else:
						_opening_title_phase = "pause"
						_opening_title_pause = 2.0
		"pause":
			if _opening_title_timer >= _opening_title_pause:
				_opening_title_timer = 0.0
				_opening_title_phase = "deleting"
		"deleting":
			if _opening_title_timer >= _delete_step_duration():
				_opening_title_timer = 0.0
				var delete_target := 0 if _opening_title_fast_accept else _delete_target_length(_opening_title_target)
				if _opening_title_text.length() > delete_target:
					_opening_title_text = _opening_title_text.substr(0, _opening_title_text.length() - 1)
					_play_opening_type_sound(0.72)
				else:
					if _opening_title_accept_requested:
						_start_opening_title_attempt(true)
					else:
						_opening_title_attempt_index = (_opening_title_attempt_index + 1) % OPENING_TITLE_ERRORS.size()
						_start_opening_title_attempt(false)
		"final_hold":
			if _opening_title_timer >= _opening_title_pause:
				_begin_opening_title_particle_sequence()


func _start_opening_title_attempt(correct: bool) -> void:
	_opening_title_target = OPENING_TITLE_TEXT if correct else OPENING_TITLE_ERRORS[_opening_title_attempt_index]
	_opening_title_text = ""
	_opening_title_char_index = 0
	_opening_title_timer = 0.0
	_opening_title_phase = "typing"
	_opening_title_waiting = not correct


func _typing_step_duration() -> float:
	var index: int = maxi(0, _opening_title_char_index - 1)
	var pattern := [0.42, 0.36, 0.5, 0.32, 0.46, 0.34, 0.48, 0.38, 0.5, 0.3]
	var speed_scale := 0.5 if _opening_title_fast_accept else 1.0
	return pattern[index % pattern.size()] * speed_scale


func _delete_step_duration() -> float:
	return 0.15 if _opening_title_fast_accept else 0.3


func _delete_target_length(text_value: String) -> int:
	if _opening_title_attempt_index % 3 == 0:
		return 0
	for i in range(min(text_value.length(), OPENING_TITLE_TEXT.length())):
		if text_value[i] != OPENING_TITLE_TEXT[i]:
			return maxi(0, i - 1)
	return maxi(0, text_value.length() - 3)


func _play_opening_type_sound(volume_scale: float) -> void:
	if _opening_type_player == null or not is_instance_valid(_opening_type_player):
		return
	_opening_type_player.stop()
	_opening_type_player.pitch_scale = 0.94 + randf() * 0.12
	_opening_type_player.volume_db = linear_to_db(clampf(0.62 * volume_scale, 0.01, 1.0))
	_opening_type_player.play()


func _begin_opening_title_particle_sequence() -> void:
	_opening_title_final_sequence = true
	_opening_particle_timer = 0.0
	_opening_title_label.visible = false
	_opening_title_caret.visible = false
	_opening_title_prompt.visible = false
	await _build_opening_title_particles()


func _build_opening_title_particles() -> void:
	_opening_title_particle_data.clear()
	if _opening_particle_canvas != null and is_instance_valid(_opening_particle_canvas):
		_opening_particle_canvas.queue_free()

	var viewport_size := get_viewport_rect().size
	var center := Vector2(viewport_size.x * 0.5, viewport_size.y * 0.43)

	var starts := await _build_title_pixel_points(center)
	var burst_points := _build_burst_points(center, starts)
	var ring_points := _build_circle_points(center, starts.size())
	var escape_points := _build_escape_points(center, starts.size())
	for i in range(starts.size()):
		_opening_title_particle_data.append({
			"start": starts[i],
			"burst": burst_points[i],
			"ring": ring_points[i],
			"escape": escape_points[i],
			"delay": float(i % 29) * 0.008,
		})

	_opening_particle_canvas = OpeningTitleParticleCanvas.new()
	_opening_particle_canvas.name = "OpeningTitleParticleCanvas"
	_opening_particle_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_opening_particle_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_opening_particle_canvas.particle_data = _opening_title_particle_data
	_opening_title_root.add_child(_opening_particle_canvas)


func _update_opening_title_particles(delta: float, _viewport_size: Vector2) -> void:
	_opening_particle_timer += delta
	if _opening_particle_canvas != null and is_instance_valid(_opening_particle_canvas):
		_opening_particle_canvas.timer = _opening_particle_timer
		_opening_particle_canvas.queue_redraw()

	if _opening_particle_timer >= 7.2:
		_opening_title_transition_finished = true


func _build_title_pixel_points(center: Vector2) -> Array[Vector2]:
	var viewport_size := Vector2i(980, 220)
	var sample_step := 2
	var viewport := SubViewport.new()
	viewport.name = "OpeningTitleSampler"
	viewport.size = viewport_size
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(viewport)

	var sample_label := _make_opening_title_label(104, Color(1.0, 1.0, 1.0, 1.0))
	sample_label.text = OPENING_TITLE_TEXT
	sample_label.size = Vector2(viewport_size)
	sample_label.position = Vector2.ZERO
	viewport.add_child(sample_label)

	await RenderingServer.frame_post_draw

	var image := viewport.get_texture().get_image()
	var points: Array[Vector2] = []
	var origin := center - Vector2(viewport_size) * 0.5
	for y in range(0, viewport_size.y, sample_step):
		for x in range(0, viewport_size.x, sample_step):
			var alpha := image.get_pixel(x, y).a
			if alpha > 0.18:
				points.append(origin + Vector2(float(x), float(y)))

	viewport.queue_free()

	if points.size() > 8500:
		var reduced: Array[Vector2] = []
		var stride := ceili(float(points.size()) / 8500.0)
		for i in range(0, points.size(), stride):
			reduced.append(points[i])
		points = reduced
	return points


func _build_circle_points(center: Vector2, count: int) -> Array[Vector2]:
	var points: Array[Vector2] = []
	var radius := 138.0
	var ring_thickness := 8.0
	for i in range(count):
		var theta := TAU * float(i) / float(count)
		var r := radius + sin(float(i) * 2.399963) * ring_thickness
		points.append(center + Vector2(cos(theta), sin(theta)) * r)
	return points


func _build_burst_points(center: Vector2, starts: Array[Vector2]) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for i in range(starts.size()):
		var start := starts[i]
		var dir := (start - center).normalized()
		if dir.length_squared() < 0.001:
			var angle := TAU * float(i) / float(maxi(1, starts.size()))
			dir = Vector2(cos(angle), sin(angle))
		var distance := 86.0 + 54.0 * absf(sin(float(i) * 12.9898))
		var tangent := Vector2(-dir.y, dir.x) * sin(float(i) * 4.17) * 28.0
		points.append(start + dir * distance + tangent)
	return points


func _build_escape_points(center: Vector2, count: int) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for i in range(count):
		var angle := TAU * float(i) / float(maxi(1, count)) + sin(float(i) * 0.37) * 0.7
		var distance := 380.0 + 340.0 * absf(sin(float(i) * 5.398))
		points.append(center + Vector2(cos(angle), sin(angle)) * distance)
	return points


func _ensure_audio_players() -> void:
	if _chapter_1_noise_player == null or not is_instance_valid(_chapter_1_noise_player):
		_chapter_1_noise_player = AudioStreamPlayer.new()
		_chapter_1_noise_player.name = "Chapter1NoisePlayer"
		_chapter_1_noise_player.stream = CHAPTER_1_NOISE_LOOP_AUDIO
		if _chapter_1_noise_player.stream is AudioStreamMP3:
			(_chapter_1_noise_player.stream as AudioStreamMP3).loop = true
		_chapter_1_noise_player.volume_db = linear_to_db(0.4)
		_chapter_1_noise_player.autoplay = false
		add_child(_chapter_1_noise_player)

	if _opening_type_player == null or not is_instance_valid(_opening_type_player):
		_opening_type_player = AudioStreamPlayer.new()
		_opening_type_player.name = "OpeningTypePlayer"
		_opening_type_player.stream = OPENING_TYPE_AUDIO
		_opening_type_player.volume_db = linear_to_db(0.62)
		_opening_type_player.autoplay = false
		add_child(_opening_type_player)


func _is_chapter_1_scene_index(scene_index: int) -> bool:
	return scene_index == 0 or scene_index == 1


func _update_chapter_audio_state(scene_index: int) -> void:
	if _chapter_1_noise_player == null or not is_instance_valid(_chapter_1_noise_player):
		return
	if _is_chapter_1_scene_index(scene_index):
		if not _chapter_1_noise_player.playing:
			_chapter_1_noise_player.play()
		return
	if _chapter_1_noise_player.playing:
		_chapter_1_noise_player.stop()


func _notify_active_chapter_transition_finished() -> void:
	if _active_chapter_node == null or not is_instance_valid(_active_chapter_node):
		return
	if _active_chapter_node.has_method("_on_scene_transition_finished"):
		_active_chapter_node.call("_on_scene_transition_finished")


func _ensure_debug_mapping_label() -> void:
	if _debug_mapping_label != null and is_instance_valid(_debug_mapping_label):
		return
	_debug_mapping_label = Label.new()
	_debug_mapping_label.name = "DebugMappingHint"
	_debug_mapping_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_debug_mapping_label.position = Vector2(14.0, 14.0)
	_debug_mapping_label.modulate = Color(1.0, 1.0, 0.45, 0.0)
	_debug_mapping_label.z_index = 100
	add_child(_debug_mapping_label)
	move_child(_debug_mapping_label, get_child_count() - 1)


func _show_mapping_debug_hint() -> void:
	_ensure_debug_mapping_label()
	var mode := "反向映射" if InputMappingStateRef.reverse_wasd_mapping else "正向映射"
	_debug_mapping_label.text = "[debug] 控制映射: " + mode
	_debug_mapping_label.modulate.a = 1.0
	var t := create_tween()
	t.tween_interval(1.1)
	t.tween_property(_debug_mapping_label, "modulate:a", 0.0, 0.28)
