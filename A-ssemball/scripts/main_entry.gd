extends Control

const GAME_SCENE: PackedScene = preload("res://scenes/chapter_1.tscn")
const INTRO_SCENE: PackedScene = preload("res://scenes/intro_interactive.tscn")

@export var fade_to_black_sec: float = 0.45
@export var reveal_game_sec: float = 0.45

@onready var game_root: Control = $GameRoot
@onready var menu_layer: Control = $MenuLayer
@onready var fade_layer: ColorRect = $FadeLayer

var _is_starting: bool = false


func _ready() -> void:
	fade_layer.color = Color(0.0, 0.0, 0.0, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if _is_starting:
		return

	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		_is_starting = true
		get_viewport().set_input_as_handled()
		_start_sequence()


func _start_sequence() -> void:
	var fade_out := create_tween()
	fade_out.tween_property(fade_layer, "color:a", 1.0, fade_to_black_sec)
	await fade_out.finished

	menu_layer.visible = false
	var intro := _spawn_intro_scene()

	var show_intro := create_tween()
	show_intro.tween_property(fade_layer, "color:a", 0.0, reveal_game_sec)
	await show_intro.finished

	if intro != null:
		await intro.intro_finished

	fade_layer.color = Color(0.0, 0.0, 0.0, 1.0)

	_clear_game_root()
	_spawn_game_scene()

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


func _spawn_game_scene() -> void:
	var game := GAME_SCENE.instantiate()
	game_root.add_child(game)

	if game is Control:
		_fit_full_rect(game as Control)

	if game.has_method("_set_game_started"):
		game.call("_set_game_started", true)


func _clear_game_root() -> void:
	for child in game_root.get_children():
		child.queue_free()


func _fit_full_rect(node: Control) -> void:
	node.set_anchors_preset(Control.PRESET_FULL_RECT)
	node.offset_left = 0.0
	node.offset_top = 0.0
	node.offset_right = 0.0
	node.offset_bottom = 0.0
