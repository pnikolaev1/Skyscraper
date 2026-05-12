extends Control
class_name ResultsScreen

@onready var title_label: Label = $Panel/VBox/Title
@onready var score_label: Label = $Panel/VBox/Stats/Score/Value
@onready var combo_label: Label = $Panel/VBox/Stats/Combo/Value
@onready var height_label: Label = $Panel/VBox/Stats/Height/Value
@onready var stars_box: HBoxContainer = $Panel/VBox/Stars
@onready var unlock_label: Label = $Panel/VBox/Unlock
@onready var retry_btn: Button = $Panel/VBox/Buttons/Retry
@onready var continue_btn: Button = $Panel/VBox/Buttons/Continue
@onready var dim: ColorRect = $Dim
@onready var panel: PanelContainer = $Panel

func _ready() -> void:
	# Slide / fade in
	dim.modulate.a = 0.0
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.85, 0.85)
	var t := create_tween().set_parallel(true)
	t.tween_property(dim, "modulate:a", 1.0, 0.25)
	t.tween_property(panel, "modulate:a", 1.0, 0.35)
	t.tween_property(panel, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	retry_btn.pressed.connect(_on_retry)
	continue_btn.pressed.connect(_on_continue)

	var res := GameState.last_session_results
	_populate(res)

func _populate(res: Dictionary) -> void:
	score_label.text = "%d" % int(res.get("score", 0))
	combo_label.text = "x%d" % int(res.get("max_combo", 1))
	height_label.text = "Floor %d" % int(res.get("height", 0))

	if int(res.get("mode", 0)) == GameState.Mode.LEVEL:
		if bool(res.get("success", false)):
			title_label.text = "Level Complete!"
			_show_stars(int(res.get("stars", 0)))
		else:
			title_label.text = "Try Again"
			_show_stars(0)
	else:
		title_label.text = "Run Over"
		stars_box.visible = false

	# Show unlock if anything new was unlocked recently
	_check_recent_unlocks()

	# Continue button label
	if int(res.get("mode", 0)) == GameState.Mode.LEVEL and bool(res.get("success", false)):
		continue_btn.text = "Continue"
	else:
		continue_btn.text = "Main Menu"

func _show_stars(count: int) -> void:
	stars_box.visible = true
	for i in range(stars_box.get_child_count()):
		var star := stars_box.get_child(i) as Label
		if star:
			star.modulate = Color(1, 0.85, 0.20, 1) if i < count else Color(1, 1, 1, 0.2)

func _check_recent_unlocks() -> void:
	var unlocks: Array = GameState.last_session_results.get("unlocks", [])
	if unlocks.is_empty():
		unlock_label.text = ""
		return
	var names: Array = []
	for id in unlocks:
		var item := CosmeticLibrary.get_by_id(String(id))
		if not item.is_empty():
			names.append(String(item["display_name"]))
	unlock_label.text = "🎉 Unlocked: %s" % ", ".join(names)
	# Fanfare flourish
	unlock_label.modulate.a = 0.0
	var t := create_tween()
	t.tween_interval(0.4)
	t.tween_property(unlock_label, "modulate:a", 1.0, 0.5)

func _on_retry() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_continue() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
