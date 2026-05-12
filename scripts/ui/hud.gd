extends CanvasLayer
class_name HUD

## Gameplay HUD. Score top-left, combo top-centre, stability/lives top-right,
## height bottom-centre, hazard banner side, intro overlay for level mode.

signal pause_requested

@onready var score_label: Label = $Top/Score/Value
@onready var combo_panel: Control = $Top/Combo
@onready var combo_label: Label = $Top/Combo/Value
@onready var stability_panel: Control = $Top/RightSide/Stability
@onready var stability_bar: ProgressBar = $Top/RightSide/Stability/Bar
@onready var lives_panel: Control = $Top/RightSide/Lives
@onready var lives_hbox: HBoxContainer = $Top/RightSide/Lives/HBox
@onready var height_label: Label = $Bottom/Height
@onready var hazard_banner: Control = $HazardBanner
@onready var hazard_label: Label = $HazardBanner/Label
@onready var pause_button: Button = $Top/PauseButton
@onready var intro_overlay: Control = $IntroOverlay
@onready var intro_text: Label = $IntroOverlay/Panel/Text
@onready var intro_button: Button = $IntroOverlay/Panel/Continue
@onready var feedback_label: Label = $Feedback

var _score_displayed: int = 0
var _combo_visible: bool = false

func _ready() -> void:
	combo_panel.modulate.a = 0.0
	hazard_banner.position.x = -hazard_banner.size.x - 60
	intro_overlay.visible = false
	feedback_label.modulate.a = 0.0
	pause_button.pressed.connect(func(): emit_signal("pause_requested"))
	intro_button.pressed.connect(_hide_intro)

func setup_for_mode(mode: int, level: LevelData = null) -> void:
	if mode == GameState.Mode.ENDLESS:
		stability_panel.visible = true
		lives_panel.visible = false
	else:
		stability_panel.visible = false
		lives_panel.visible = true
		_rebuild_lives(Config.get_i("lives_start", 3))
	if level and level.intro_text != "":
		_show_intro(level.intro_text)

func _show_intro(text: String) -> void:
	intro_text.text = text
	intro_overlay.visible = true
	intro_overlay.modulate.a = 0.0
	# Bind the tween to intro_overlay (PROCESS_MODE_ALWAYS) so it animates even when paused.
	var t := intro_overlay.create_tween()
	t.tween_property(intro_overlay, "modulate:a", 1.0, 0.3)
	get_tree().paused = true

func _hide_intro() -> void:
	var t := intro_overlay.create_tween()
	t.tween_property(intro_overlay, "modulate:a", 0.0, 0.25)
	t.tween_callback(func():
		intro_overlay.visible = false
		get_tree().paused = false
	)

func on_score_changed(points: int, total: int) -> void:
	# tween the displayed score up to total
	var start := _score_displayed
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_method(func(v: float):
		_score_displayed = int(round(v))
		score_label.text = "%d" % _score_displayed
	, float(start), float(total), 0.35)
	# small pop
	score_label.scale = Vector2(1.15, 1.15)
	create_tween().tween_property(score_label, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func on_combo_changed(new_combo: int) -> void:
	if new_combo >= 2:
		combo_label.text = "x%d" % new_combo
		if not _combo_visible:
			combo_panel.scale = Vector2(0.4, 0.4)
			var t := create_tween().set_parallel(true)
			t.tween_property(combo_panel, "modulate:a", 1.0, 0.18)
			t.tween_property(combo_panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			_combo_visible = true
		else:
			combo_panel.scale = Vector2(1.25, 1.25)
			create_tween().tween_property(combo_panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		if _combo_visible:
			var t := create_tween()
			t.tween_property(combo_panel, "modulate:a", 0.0, 0.18)
			_combo_visible = false

func on_stability_changed(value: int) -> void:
	stability_bar.value = value
	var col := Color.GREEN
	if value < 60:
		col = Color(0.95, 0.78, 0.20)
	if value < 30:
		col = Color(0.95, 0.30, 0.25)
	stability_bar.modulate = col

func on_lives_changed(remaining: int) -> void:
	for i in range(lives_hbox.get_child_count()):
		var heart := lives_hbox.get_child(i) as TextureRect
		if heart:
			heart.modulate = Color(1, 1, 1, 1) if i < remaining else Color(1, 1, 1, 0.25)

func _rebuild_lives(count: int) -> void:
	for c in lives_hbox.get_children():
		c.queue_free()
	for i in range(count):
		var lbl := Label.new()
		lbl.text = "♥"
		lbl.add_theme_font_size_override("font_size", 42)
		lbl.add_theme_color_override("font_color", Color(0.95, 0.30, 0.40))
		lives_hbox.add_child(lbl)

func on_height_changed(h: int) -> void:
	height_label.text = "Floor %d" % h

func on_placement(quality: int) -> void:
	var msg := ""
	var col := Color.WHITE
	match quality:
		Session.Quality.PERFECT:
			msg = "PERFECT!"
			col = Color(1.0, 0.9, 0.3)
		Session.Quality.GOOD:
			msg = "Good"
			col = Color(0.7, 0.95, 0.7)
		Session.Quality.MISS:
			msg = "Miss"
			col = Color(1.0, 0.5, 0.5)
		Session.Quality.DROPPED:
			msg = "Slipped off!"
			col = Color(1.0, 0.35, 0.30)
	feedback_label.text = msg
	feedback_label.add_theme_color_override("font_color", col)
	feedback_label.modulate.a = 1.0
	feedback_label.scale = Vector2(0.6, 0.6)
	var t := create_tween().set_parallel(true)
	t.tween_property(feedback_label, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.chain().tween_interval(0.6)
	t.chain().tween_property(feedback_label, "modulate:a", 0.0, 0.4)

func show_hazard_banner(text: String) -> void:
	hazard_label.text = text
	var slide_in := -8.0
	var slide_out := -hazard_banner.size.x - 60
	hazard_banner.position.x = slide_out
	var t := create_tween()
	t.tween_property(hazard_banner, "position:x", slide_in, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_interval(1.6)
	t.tween_property(hazard_banner, "position:x", slide_out, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
