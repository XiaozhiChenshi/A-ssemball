extends Control
class_name IntroInteractive

signal intro_finished

@export var placeholder_texture_path: String = "res://assets/ui/scene1_start.png"
@export var fallback_texture_path: String = "res://assets/ui/scene1_start.png"
@export var pulse_scale: float = 1.03
@export var pulse_duration: float = 1.2
@export var finish_fade_sec: float = 0.25

@onready var bg: TextureRect = $Bg
@onready var dim: ColorRect = $Dim
@onready var hint: Label = $Hint

var _ending: bool = false
var _pulse_tween: Tween


func _ready() -> void:
	_apply_placeholder_texture()
	_start_pulse()


func _unhandled_input(event: InputEvent) -> void:
	if _ending:
		return

	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		get_viewport().set_input_as_handled()
		_finish_intro()
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		_finish_intro()


func _apply_placeholder_texture() -> void:
	var tex: Texture2D = null
	if ResourceLoader.exists(placeholder_texture_path):
		tex = load(placeholder_texture_path)
	elif ResourceLoader.exists(fallback_texture_path):
		tex = load(fallback_texture_path)
	bg.texture = tex


func _start_pulse() -> void:
	if is_instance_valid(_pulse_tween):
		_pulse_tween.kill()
	bg.scale = Vector2.ONE
	_pulse_tween = create_tween()
	_pulse_tween.set_loops()
	_pulse_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.tween_property(bg, "scale", Vector2(pulse_scale, pulse_scale), pulse_duration)
	_pulse_tween.tween_property(bg, "scale", Vector2.ONE, pulse_duration)


func _finish_intro() -> void:
	_ending = true
	hint.text = "Loading..."
	if is_instance_valid(_pulse_tween):
		_pulse_tween.kill()

	var t := create_tween()
	t.tween_property(dim, "color:a", 0.75, finish_fade_sec)
	await t.finished
	intro_finished.emit()
