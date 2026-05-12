extends Control
class_name CosmeticsScreen

@onready var skin_grid: GridContainer = $Center/Scroll/VBox/Skins/Grid
@onready var roof_grid: GridContainer = $Center/Scroll/VBox/Rooftops/Grid
@onready var sky_grid: GridContainer = $Center/Scroll/VBox/Skylines/Grid
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
	_fill(skin_grid, "skin", CosmeticLibrary.SKINS)
	_fill(roof_grid, "rooftop", CosmeticLibrary.ROOFTOPS)
	_fill(sky_grid, "skyline", CosmeticLibrary.SKYLINES)

func _fill(grid: GridContainer, category: String, items: Array) -> void:
	for c in grid.get_children():
		c.queue_free()
	for item in items:
		grid.add_child(_make_card(category, item))

func _make_card(category: String, item: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(220, 220)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(v)

	# preview swatch
	var swatch := _make_swatch(category, item)
	v.add_child(swatch)

	var label := Label.new()
	label.text = String(item["display_name"])
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color.WHITE)
	v.add_child(label)

	var unlocked := SaveSystem.is_unlocked(String(item["id"]))
	var status := Label.new()
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.add_theme_font_size_override("font_size", 18)
	if not unlocked:
		swatch.modulate = Color(0.1, 0.1, 0.1, 1)
		status.text = CosmeticLibrary.unlock_label(item)
		status.add_theme_color_override("font_color", Color(0.85, 0.75, 0.4, 1))
	else:
		var selected_id := SaveSystem.get_selected(category)
		if selected_id == String(item["id"]):
			status.text = "Selected"
			status.add_theme_color_override("font_color", Color(0.4, 0.95, 0.5, 1))
		else:
			status.text = ""
	v.add_child(status)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(160, 44)
	btn.add_theme_font_size_override("font_size", 20)
	if unlocked:
		btn.text = "Select"
		btn.pressed.connect(func():
			SaveSystem.set_selected(category, String(item["id"]))
			AudioManager.play_sfx("ui_blip")
			_populate()
		)
	else:
		btn.text = "Locked"
		btn.disabled = true
	v.add_child(btn)
	return card

func _make_swatch(category: String, item: Dictionary) -> Control:
	var swatch := ColorRect.new()
	swatch.custom_minimum_size = Vector2(180, 100)
	var data: Dictionary = item.get("apply_data", {})
	match category:
		"skin":
			swatch.color = Color(data.get("base", Color.GRAY))
			# accent stripe across the top
			var accent := ColorRect.new()
			accent.color = Color(data.get("accent", Color.WHITE))
			accent.size = Vector2(180, 12)
			swatch.add_child(accent)
			var win_row := HBoxContainer.new()
			win_row.position = Vector2(12, 40)
			win_row.add_theme_constant_override("separation", 8)
			swatch.add_child(win_row)
			for i in range(5):
				var w := ColorRect.new()
				w.color = Color(data.get("window", Color.BLACK))
				w.custom_minimum_size = Vector2(20, 28)
				win_row.add_child(w)
		"rooftop":
			swatch.color = Color(0.30, 0.40, 0.55)
			var lbl := Label.new()
			lbl.text = String(data.get("type", "?")).to_upper()
			lbl.add_theme_font_size_override("font_size", 24)
			lbl.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
			lbl.size = Vector2(180, 100)
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			swatch.add_child(lbl)
		"skyline":
			swatch.color = Color(data.get("bottom", Color.WHITE))
			var top := ColorRect.new()
			top.color = Color(data.get("top", Color.BLACK))
			top.size = Vector2(180, 50)
			swatch.add_child(top)
			var sun := ColorRect.new()
			sun.color = Color(data.get("sun", Color.YELLOW))
			sun.size = Vector2(30, 30)
			sun.position = Vector2(130, 14)
			swatch.add_child(sun)
	return swatch

func _go(path: String) -> void:
	AudioManager.play_sfx("ui_blip")
	var t := create_tween()
	t.tween_property(fade, "color:a", 1.0, 0.3)
	t.tween_callback(func(): get_tree().change_scene_to_file(path))
