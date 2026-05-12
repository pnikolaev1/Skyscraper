extends Control
class_name LevelSelect

@onready var grid: GridContainer = $Center/Scroll/Grid
@onready var back_btn: Button = $Back
@onready var fade: ColorRect = $Fade

func _ready() -> void:
	back_btn.pressed.connect(func(): _go("res://scenes/mode_select.tscn"))
	_populate()
	fade.color = Color(0, 0, 0, 1)
	create_tween().tween_property(fade, "color:a", 0.0, 0.35)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_back"):
		_go("res://scenes/mode_select.tscn")

func _populate() -> void:
	for c in grid.get_children():
		c.queue_free()
	var levels := LevelLibrary.load_all()
	for level in levels:
		var card := _make_card(level)
		grid.add_child(card)

func _make_card(level: LevelData) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(340, 260)
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	card.add_child(vbox)

	var title := Label.new()
	title.text = level.display_name
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(title)

	var info := Label.new()
	info.text = "Reach floor %d  •  Score %d" % [level.target_height, level.score_goal]
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 20)
	info.add_theme_color_override("font_color", Color(0.85, 0.92, 1, 1))
	vbox.add_child(info)

	var best := SaveSystem.get_level_score(level.id)
	var stars_box := HBoxContainer.new()
	stars_box.alignment = BoxContainer.ALIGNMENT_CENTER
	stars_box.add_theme_constant_override("separation", 10)
	vbox.add_child(stars_box)
	for i in range(3):
		var s := Label.new()
		s.text = "★"
		s.add_theme_font_size_override("font_size", 36)
		s.modulate = Color(1, 0.85, 0.20, 1) if i < int(best.get("stars", 0)) else Color(1, 1, 1, 0.2)
		stars_box.add_child(s)

	var hi := Label.new()
	hi.text = "Best: %d" % int(best.get("best_score", 0))
	hi.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hi.add_theme_font_size_override("font_size", 20)
	hi.add_theme_color_override("font_color", Color(1, 0.95, 0.5, 1))
	vbox.add_child(hi)

	var btn := Button.new()
	btn.text = "Play"
	btn.custom_minimum_size = Vector2(220, 60)
	btn.add_theme_font_size_override("font_size", 24)
	btn.pressed.connect(func():
		GameState.set_level_mode(level.id)
		_go("res://scenes/game.tscn")
	)
	vbox.add_child(btn)
	return card

func _go(path: String) -> void:
	AudioManager.play_sfx("ui_blip")
	var t := create_tween()
	t.tween_property(fade, "color:a", 1.0, 0.3)
	t.tween_callback(func(): get_tree().change_scene_to_file(path))
