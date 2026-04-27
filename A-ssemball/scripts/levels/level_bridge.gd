extends Control
class_name LevelBridge

signal chapter_completed(chapter_index: int)

@export var source_scene: PackedScene
@export var chapter_number: int = 1
@export var level_number: int = 1
@export_multiline var placeholder_note: String = "Level placeholder."
@export var fallback_complete_key: Key = KEY_ENTER

@onready var content_root: Control = $ContentRoot
@onready var placeholder_ui: Control = $PlaceholderUi
@onready var title_label: Label = $PlaceholderUi/Title
@onready var note_label: Label = $PlaceholderUi/Note
@onready var hint_label: Label = $PlaceholderUi/Hint

var _completed: bool = false
var _has_forwarded_source_signal: bool = false


func _ready() -> void:
	_load_source_scene()
	_setup_placeholder_ui()


func _unhandled_input(event: InputEvent) -> void:
	if _completed:
		return
	if _has_forwarded_source_signal:
		return
	if not _is_fallback_skip_enabled():
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == fallback_complete_key:
		get_viewport().set_input_as_handled()
		_emit_completed_once()


func _load_source_scene() -> void:
	if source_scene == null:
		return
	var node := source_scene.instantiate()
	content_root.add_child(node)
	if node is Control:
		var c := node as Control
		c.set_anchors_preset(Control.PRESET_FULL_RECT)
		c.offset_left = 0.0
		c.offset_top = 0.0
		c.offset_right = 0.0
		c.offset_bottom = 0.0
	if node.has_signal("chapter_completed"):
		_has_forwarded_source_signal = true
		node.connect("chapter_completed", Callable(self, "_on_source_completed"), CONNECT_ONE_SHOT)


func _setup_placeholder_ui() -> void:
	title_label.text = "Chapter %d - Level %d" % [chapter_number, level_number]
	note_label.text = placeholder_note
	if _has_forwarded_source_signal:
		placeholder_ui.visible = false
	else:
		placeholder_ui.visible = true
		hint_label.text = "Press Enter to continue" if _is_fallback_skip_enabled() else "Complete objective to continue"


func _on_source_completed(_source_chapter_index: int = 0) -> void:
	_emit_completed_once()


func _emit_completed_once() -> void:
	if _completed:
		return
	_completed = true
	chapter_completed.emit(chapter_number)


func _is_fallback_skip_enabled() -> bool:
	# Disable Enter-skip for implemented chapters/levels.
	if chapter_number == 1:
		return false
	if chapter_number == 2 and level_number == 1:
		return false
	return true

