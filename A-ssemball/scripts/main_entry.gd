extends Control

const INTRO_SCENE: PackedScene = preload("res://scenes/intro_interactive.tscn")
const CHAPTER_1_LEVEL_1_SCENE: PackedScene = preload("res://scenes/levels/chapter_1/level_1.tscn")
const CHAPTER_1_LEVEL_2_SCENE: PackedScene = preload("res://scenes/levels/chapter_1/level_2.tscn")
const CHAPTER_2_LEVEL_1_SCENE: PackedScene = preload("res://scenes/levels/chapter_2/level_1.tscn")
const CHAPTER_2_LEVEL_2_SCENE: PackedScene = preload("res://scenes/levels/chapter_2/level_2.tscn")
const CHAPTER_3_LEVEL_1_SCENE: PackedScene = preload("res://scenes/levels/chapter_3/level_1.tscn")
const CHAPTER_3_LEVEL_2_SCENE: PackedScene = preload("res://scenes/levels/chapter_3/level_2.tscn")
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

@onready var game_root: Control = $GameRoot
@onready var menu_layer: Control = $MenuLayer
@onready var fade_layer: ColorRect = $FadeLayer

var _is_starting: bool = false
var _chapter_scenes: Array[PackedScene] = []
var _current_chapter_scene_index: int = -1
var _active_chapter_node: Node = null
var _chapter_transition_running: bool = false
var _requested_start_chapter_scene_index: int = 0
var _chapter_transition_overlay: TextureRect


func _ready() -> void:
	fade_layer.color = Color(0.0, 0.0, 0.0, 0.0)
	_chapter_scenes = _resolve_chapter_scenes()
	_ensure_chapter_transition_overlay()


func _unhandled_input(event: InputEvent) -> void:
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
		_chapter_transition_running = false
		return

	await _fade_to_black()
	_spawn_next_chapter()
	await _fade_from_black()
	_chapter_transition_running = false


func _on_all_chapters_completed() -> void:
	# Keep the last chapter visible and unlock restart from menu key flow.
	_is_starting = false


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
	add_child(_chapter_transition_overlay)
	move_child(_chapter_transition_overlay, get_child_count() - 1)


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
	_chapter_transition_overlay.texture = texture
	await get_tree().create_timer(maxf(0.01, chapter_transition_step_sec)).timeout


func _tween_transition_overlay_alpha(target_alpha: float, duration: float) -> void:
	if _chapter_transition_overlay == null or not is_instance_valid(_chapter_transition_overlay):
		return
	var tween := create_tween()
	tween.tween_property(_chapter_transition_overlay, "modulate:a", clampf(target_alpha, 0.0, 1.0), maxf(0.001, duration))
	await tween.finished
