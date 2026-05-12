extends Control
class_name LeaderboardScreen

# local leaderboard for endless mode. just lists best runs in order

@onready var list: VBoxContainer = $Center/Scroll/List
@onready var empty: Label = $Center/Empty
@onready var back_btn: Button = $Back
@onready var fade: ColorRect = $Fade

func _ready() -> void:
	back_btn.pressed.connect(func(): _go("res://scenes/main_menu.tscn"))
	_populate()
	fade.color = Color(0, 0, 0, 1)
	create_tween().tween_property(fade, "color:a", 0.0, 0.35)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_back"):
		_go("res://scenes/main_menu.tscn")

func _populate() -> void:
	for c in list.get_children():
		c.queue_free()
	var entries := SaveSystem.get_leaderboard()
	if entries.is_empty():
		empty.visible = true
		return
	empty.visible = false
	var rank := 1
	for entry in entries:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 24)

		var r := Label.new()
		r.text = "#%d" % rank
		r.custom_minimum_size = Vector2(80, 0)
		r.add_theme_font_size_override("font_size", 28)
		r.add_theme_color_override("font_color", Color(1, 0.95, 0.45, 1))
		row.add_child(r)

		var s := Label.new()
		s.text = "%d pts" % int(entry["score"])
		s.custom_minimum_size = Vector2(200, 0)
		s.add_theme_font_size_override("font_size", 28)
		s.add_theme_color_override("font_color", Color.WHITE)
		row.add_child(s)

		var h := Label.new()
		h.text = "Floor %d" % int(entry["height"])
		h.custom_minimum_size = Vector2(160, 0)
		h.add_theme_font_size_override("font_size", 22)
		h.add_theme_color_override("font_color", Color(0.85, 0.92, 1, 1))
		row.add_child(h)

		var d := Label.new()
		d.text = String(entry.get("date", ""))
		d.add_theme_font_size_override("font_size", 22)
		d.add_theme_color_override("font_color", Color(0.85, 0.92, 1, 1))
		row.add_child(d)

		list.add_child(row)
		rank += 1

func _go(path: String) -> void:
	AudioManager.play_sfx("ui_blip")
	var t := create_tween()
	t.tween_property(fade, "color:a", 1.0, 0.3)
	t.tween_callback(func(): get_tree().change_scene_to_file(path))
