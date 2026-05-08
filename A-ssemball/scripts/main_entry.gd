extends Control

const InputMappingStateRef = preload("res://scripts/input_mapping_state.gd")
const INTRO_SCENE: PackedScene = preload("res://scenes/intro_interactive.tscn")
const FONT_PREVIEW_SCENE: PackedScene = preload("res://scenes/font_preview.tscn")
const CHAPTER_1_LEVEL_1_SCENE: PackedScene = preload("res://scenes/levels/chapter_1/level_1.tscn")
const CHAPTER_1_LEVEL_2_SCENE: PackedScene = preload("res://scenes/levels/chapter_1/level_2.tscn")
const CHAPTER_2_LEVEL_1_SCENE: PackedScene = preload("res://scenes/levels/chapter_2/level_1.tscn")
const CHAPTER_2_LEVEL_2_SCENE: PackedScene = preload("res://scenes/levels/chapter_2/level_2.tscn")
const CHAPTER_3_LEVEL_1_SCENE: PackedScene = preload("res://scenes/levels/chapter_3/level_1.tscn")
const CHAPTER_3_LEVEL_2_SCENE: PackedScene = preload("res://scenes/levels/chapter_3/level_2.tscn")
const CHAPTER_1_NOISE_LOOP_AUDIO: AudioStream = preload("res://assets/audio/底噪.mp3")
const TRAN_1_TEX: Texture2D = preload("res://assets/materials/tran1.png")
const TRAN_2_TEX: Texture2D = preload("res://assets/materials/tran2.png")
const TRAN_3_TEX: Texture2D = preload("res://assets/materials/tran3.png")
const TRAN_4_TEX: Texture2D = preload("res://assets/materials/tran4.png")
const CHAPTER_2_LEVEL_1_SCENE_INDEX: int = 2
const CHAPTER_2_LEVEL_2_SCENE_INDEX: int = 3

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
var _debug_mapping_label: Label
var _font_preview_hold_time: float = 0.0
var _font_preview_active: bool = false
var _font_preview_node: Control


func _process(delta: float) -> void:
	_update_font_preview_hold(delta)


func _ready() -> void:
	fade_layer.color = Color(0.0, 0.0, 0.0, 0.0)
	_chapter_scenes = _resolve_chapter_scenes()
	_ensure_chapter_transition_overlay()
	_ensure_audio_players()
	_ensure_debug_mapping_label()


func _unhandled_input(event: InputEvent) -> void:
	if _font_preview_active:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_0 or event.keycode == KEY_KP_0:
			get_viewport().set_input_as_handled()
			InputMappingStateRef.toggle_reverse_wasd_mapping()
			_show_mapping_debug_hint()
			return

	if _is_starting:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			_is_starting = true
			get_viewport().set_input_as_handled()
			_start_sequence(false, 0)
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
			_start_sequence(true, 5)
			return


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


func _start_sequence(skip_intro_to_post_click_effect: bool, start_chapter_scene_index: int = 0) -> void:
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


func _spawn_intro_scene() -> IntroInteractive:
	_clear_game_root()

	var intro := INTRO_SCENE.instantiate()
	game_root.add_child(intro)
	if intro is Control:
		_fit_full_rect(intro as Control)
	return intro as IntroInteractive


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


func _ensure_audio_players() -> void:
	if _chapter_1_noise_player != null and is_instance_valid(_chapter_1_noise_player):
		return
	_chapter_1_noise_player = AudioStreamPlayer.new()
	_chapter_1_noise_player.name = "Chapter1NoisePlayer"
	_chapter_1_noise_player.stream = CHAPTER_1_NOISE_LOOP_AUDIO
	if _chapter_1_noise_player.stream is AudioStreamMP3:
		(_chapter_1_noise_player.stream as AudioStreamMP3).loop = true
	_chapter_1_noise_player.volume_db = linear_to_db(0.4)
	_chapter_1_noise_player.autoplay = false
	add_child(_chapter_1_noise_player)


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
