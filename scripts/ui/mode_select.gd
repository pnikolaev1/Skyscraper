extends Control
class_name ModeSelect

@onready var level_btn: Button = $Center/HBox/Level/VBox/Button
@onready var endless_btn: Button = $Center/HBox/Endless/VBox/Button
@onready var back_btn: Button = $Back
@onready var fade: ColorRect = $Fade

func _ready() -> void:
	level_btn.pressed.connect(func(): _go("res://scenes/level_select.tscn"))
	endless_btn.pressed.connect(_play_endless)
	back_btn.pressed.connect(func(): _go("res://scenes/main_menu.tscn"))
	fade.color = Color(0, 0, 0, 1)
	create_tween().tween_property(fade, "color:a", 0.0, 0.35)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_back"):
		_go("res://scenes/main_menu.tscn")

func _play_endless() -> void:
	GameState.set_endless_mode()
	_go("res://scenes/game.tscn")

func _go(path: String) -> void:
	AudioManager.play_sfx("ui_blip")
	var t := create_tween()
	t.tween_property(fade, "color:a", 1.0, 0.3)
	t.tween_callback(func(): get_tree().change_scene_to_file(path))
