extends Control
class_name MainMenu

@onready var play_btn: Button = $Center/VBox/Play
@onready var cosmetics_btn: Button = $Center/VBox/Cosmetics
@onready var leaderboard_btn: Button = $Center/VBox/Leaderboard
@onready var settings_btn: Button = $Center/VBox/Settings
@onready var quit_btn: Button = $Center/VBox/Quit
@onready var settings_panel: Control = $SettingsPanel
@onready var fade: ColorRect = $Fade
@onready var bg: SkylineBackground = $SkylineBackground
@onready var bg_tower: Node2D = $BackgroundTower

func _ready() -> void:
	AudioManager.play_music("menu")
	play_btn.pressed.connect(func(): _go("res://scenes/mode_select.tscn"))
	cosmetics_btn.pressed.connect(func(): _go("res://scenes/cosmetics_screen.tscn"))
	leaderboard_btn.pressed.connect(func(): _go("res://scenes/leaderboard_screen.tscn"))
	settings_btn.pressed.connect(_open_settings)
	quit_btn.pressed.connect(func(): get_tree().quit())

	settings_panel.visible = false
	_wire_settings()
	# little tower in the bg that grows slowly
	_animate_bg_tower()

	# fade in
	fade.color = Color(0, 0, 0, 1)
	create_tween().tween_property(fade, "color:a", 0.0, 0.45)

func _go(path: String) -> void:
	AudioManager.play_sfx("ui_blip")
	var t := create_tween()
	t.tween_property(fade, "color:a", 1.0, 0.3)
	t.tween_callback(func(): get_tree().change_scene_to_file(path))

func _open_settings() -> void:
	settings_panel.visible = not settings_panel.visible

func _wire_settings() -> void:
	var music: HSlider = $SettingsPanel/Panel/VBox/Music/Slider
	var sfx: HSlider = $SettingsPanel/Panel/VBox/SFX/Slider
	var close: Button = $SettingsPanel/Panel/VBox/Close
	music.value = SaveSystem.get_music_vol()
	sfx.value = SaveSystem.get_sfx_vol()
	music.value_changed.connect(func(v):
		SaveSystem.set_music_vol(v)
		AudioManager.set_music_volume(v)
	)
	sfx.value_changed.connect(func(v):
		SaveSystem.set_sfx_vol(v)
		AudioManager.set_sfx_volume(v)
	)
	close.pressed.connect(func(): settings_panel.visible = false)

func _animate_bg_tower() -> void:
	# stack a few floors way off to the side, slowly drift them upward
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var y := 980.0
	for c in bg_tower.get_children():
		c.queue_free()
	for i in range(8):
		var f := ColorRect.new()
		f.color = Color(0.30, 0.40, 0.62, 0.85)
		f.size = Vector2(180, 36)
		f.position = Vector2(rng.randf_range(1500, 1700), y)
		bg_tower.add_child(f)
		y -= 38
	# slow drift
	var t := bg_tower.create_tween().set_loops()
	t.tween_property(bg_tower, "position:y", -50.0, 60.0)
	t.tween_callback(func(): bg_tower.position.y = 0.0)
