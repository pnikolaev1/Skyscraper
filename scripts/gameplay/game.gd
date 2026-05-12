extends Node2D
class_name Game

# main gameplay scene. glues together Session + Crane + Tower + HazardManager + HUD

@onready var session: Session = $Session as Session
@onready var crane: Crane = $Crane as Crane
@onready var tower: Tower = $World/Tower as Tower
@onready var hazards: HazardManager = $HazardManager as HazardManager
@onready var hud: HUD = $HUD as HUD
@onready var camera: Camera2D = $Camera2D
@onready var sky: SkylineBackground = $SkylineBackground as SkylineBackground
@onready var fog_layer: CanvasLayer = $FogLayer
@onready var ping_layer: Node2D = $World/PingLayer
@onready var fx_layer: Node2D = $World/FXLayer
@onready var pause_layer: CanvasLayer = $PauseLayer
@onready var pause_menu: Control = $PauseLayer/PauseMenu
@onready var results_layer: CanvasLayer = $ResultsLayer
@onready var transition: ColorRect = $TransitionLayer/Fade

const RESULTS_SCENE := preload("res://scenes/results_screen.tscn")

var _base_y: float = 920.0
var _world_left: float = 0.0
var _world_right: float = 1920.0
var _crane_y: float = 120.0
var _floors_until_speedup: int = 4
var _camera_target_y: float = 0.0
var _shake_t: float = 0.0
var _shake_amp: float = 0.0
var _rng := RandomNumberGenerator.new()
var _ended: bool = false
var _new_unlocks: Array[String] = []

func _ready() -> void:
	_rng.randomize()
	# grab the cosmetics the user picked
	var skin_id := SaveSystem.get_selected("skin")
	var rooftop_id := SaveSystem.get_selected("rooftop")
	var skyline_id := SaveSystem.get_selected("skyline")
	var skin_item := CosmeticLibrary.get_by_id(skin_id)
	var roof_item := CosmeticLibrary.get_by_id(rooftop_id)
	var sky_item := CosmeticLibrary.get_by_id(skyline_id)
	var skin_data: Dictionary = (skin_item["apply_data"] if not skin_item.is_empty() else {})
	var rooftop_type: String = String((roof_item["apply_data"] if not roof_item.is_empty() else {}).get("type", "antenna"))
	var skyline_data: Dictionary = (sky_item["apply_data"] if not sky_item.is_empty() else {})

	# put stuff in place
	camera.position = Vector2(960, 540)
	_camera_target_y = 540.0
	crane.position = Vector2(960, _crane_y)
	tower.set_base_x(960)
	tower.base_y = _base_y
	# spawn the base floor we build on
	tower.setup(skin_data, rooftop_type)
	var base_floor: FloorPiece = tower.spawn_base_floor(Config.get_f("floor_width", 260.0) + 80.0, _base_y)
	base_floor.set_rooftop(rooftop_type)

	sky.setup(skyline_data)

	crane.setup(_world_left + 120.0, _world_right - 120.0, skin_data)

	# figure out mode and level
	var mode := GameState.current_mode
	var level: LevelData = null
	if mode == GameState.Mode.LEVEL:
		level = LevelLibrary.load_by_id(GameState.current_level_id)
		if level == null:
			level = LevelLibrary.load_all().front() if LevelLibrary.load_all().size() > 0 else null

	# kick the session off
	session.start(mode, level)
	hazards.setup(crane, tower, fog_layer, ping_layer, session)
	hazards.configure_for_level(level)
	hud.setup_for_mode(mode, level)
	hud.on_stability_changed(session.stability)
	hud.on_lives_changed(session.lives)
	hud.on_height_changed(0)

	# hook up signals
	crane.floor_released.connect(_on_crane_released)
	session.score_awarded.connect(hud.on_score_changed)
	session.combo_updated.connect(hud.on_combo_changed)
	session.stability_updated.connect(_on_stability_updated)
	session.life_lost.connect(hud.on_lives_changed)
	session.height_changed.connect(_on_height_changed)
	session.placement_evaluated.connect(_on_placement_evaluated)
	session.session_ended.connect(_on_session_ended)
	session.perfect_streak.connect(_on_perfect_streak)
	hazards.hazard_started.connect(_on_hazard_started)
	hud.pause_requested.connect(open_pause)

	# pause + results hidden initially
	pause_menu.visible = false
	pause_layer.layer = 100
	results_layer.layer = 110
	# wire pause menu buttons
	$PauseLayer/PauseMenu/Panel/VBox/Resume.pressed.connect(resume)
	$PauseLayer/PauseMenu/Panel/VBox/Restart.pressed.connect(restart)
	$PauseLayer/PauseMenu/Panel/VBox/QuitToMenu.pressed.connect(quit_to_menu)
	# let the pause menu actually work while paused
	pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	$TransitionLayer.process_mode = Node.PROCESS_MODE_ALWAYS

	# remember unlocks so we can show em on results
	SaveSystem.cosmetic_unlocked.connect(_on_cosmetic_unlocked)

	# music
	AudioManager.play_music("gameplay")

	# fade in. bind the tween to `transition` so it runs even when the level
	# intro overlay paused the tree (TransitionLayer is PROCESS_MODE_ALWAYS)
	transition.color = Color(0, 0, 0, 1)
	var t := transition.create_tween()
	t.tween_property(transition, "color:a", 0.0, 0.5)

func _physics_process(delta: float) -> void:
	_update_camera(delta)
	_update_shake(delta)
	_update_falling_floor()
	# Endless mode: ramp crane speed periodically
	if session.mode == GameState.Mode.ENDLESS:
		var step_every: int = Config.get_i("crane_speed_step_every", 4)
		var target := Config.get_f("crane_speed_start", 360.0) + Config.get_f("crane_speed_step", 18.0) * float(session.floors_placed / step_every)
		crane.set_speed(min(target, Config.get_f("crane_speed_max", 900.0)))

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause") and not _ended and not results_layer.visible:
		# esc bails out of the run. theres still a pause button in the HUD if
		# you actually want to pause
		quit_to_menu()
		return
	# parallax bg follows camera
	sky.apply_parallax(camera.position.y - 540.0)
	sky.set_height_blend(session.height)

func _update_camera(delta: float) -> void:
	# follow top of tower but keep crane near top of view
	var top_y := tower.get_top_y_world()
	# want top of tower around y=700 on screen (upper third).
	# camera.y - 540 + 700 = top_y, so camera.y = top_y - 160
	var desired := top_y - 160.0
	# dont go below ground baseline
	desired = min(desired, 540.0)
	_camera_target_y = desired
	var lerp_speed := Config.get_f("camera_lerp", 5.0)
	camera.position.y = lerpf(camera.position.y, _camera_target_y, delta * lerp_speed)
	# crane stays anchored to top of viewport
	crane.position.y = camera.position.y - (540.0 - _crane_y)

func _update_shake(delta: float) -> void:
	if _shake_t > 0.0:
		_shake_t -= delta
		var off := Vector2(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0)) * _shake_amp
		camera.offset = off
		if _shake_t <= 0.0:
			camera.offset = Vector2.ZERO

# ---------- falling floor tracking ----------
var _falling_floor: FloorPiece = null

func _on_crane_released(piece: FloorPiece, _vel: Vector2) -> void:
	session.notify_floor_released()
	_falling_floor = piece

func _update_falling_floor() -> void:
	if _falling_floor == null:
		return
	# fell way off the bottom of the world, just clean it up
	if _falling_floor.global_position.y > _base_y + 800.0:
		_falling_floor.queue_free()
		_falling_floor = null
		return
	var top := tower.get_top_floor()
	if top == null:
		return
	var floor_bottom: float = _falling_floor.global_position.y + _falling_floor.height * 0.5
	var top_surface: float = top.global_position.y - top.height * 0.5
	if floor_bottom >= top_surface and _falling_floor.velocity.y > 0:
		_resolve_landing(_falling_floor, top, top_surface)

func _resolve_landing(f: FloorPiece, top: FloorPiece, top_surface_y: float) -> void:
	# classify BEFORE placing - we use the swayed top position
	var world_x: float = f.global_position.x
	var offset_x: float = world_x - top.global_position.x
	var quality: int = Scoring.classify(offset_x, f.width)

	if quality == Session.Quality.DROPPED:
		# too far off, slips off the side and tumbles away
		_drop_off_side(f, offset_x, top_surface_y)
	else:
		# normal landing - snap bottom flush with top surface and hand to tower
		f.global_position = Vector2(world_x, top_surface_y - f.height * 0.5)
		tower.place_floor(f, world_x)
		_squash_floor(f, quality)
		match quality:
			Session.Quality.PERFECT:
				_shake_camera(0.0, 0.0)
				_perfect_burst(Vector2(top.global_position.x, top_surface_y))
				AudioManager.play_sfx("chime_perfect", 1.0)
			Session.Quality.GOOD:
				_shake_camera(0.10, 5.0)
				AudioManager.play_sfx("thud_good", randf_range(0.95, 1.05))
			Session.Quality.MISS:
				_shake_camera(0.30, 14.0)
				AudioManager.play_sfx("thunk_miss", 1.0)

	session.report_placement(quality, offset_x)
	hazards.notify_floor_placed(session.floors_placed)
	_falling_floor = null

func _drop_off_side(f: FloorPiece, offset_x: float, top_surface_y: float) -> void:
	# start the topple a hair above the top so the player sees it slip
	var side := signf(offset_x)
	if side == 0.0:
		side = 1.0
	# nudge it up so the next phys tick wont immediately re-trigger the landing check
	f.global_position.y = top_surface_y - f.height * 0.5 - 2.0
	f.drop(side)
	_shake_camera(0.35, 18.0)
	AudioManager.play_sfx("thunk_miss", 0.85)
	# clean it up after a bit so it doesnt fall into infinity
	var floor_ref := f
	get_tree().create_timer(3.0).timeout.connect(func():
		if is_instance_valid(floor_ref):
			floor_ref.queue_free()
	)

func _squash_floor(f: FloorPiece, quality: int) -> void:
	var body := f.get_node_or_null("Body")
	if body == null:
		return
	var amt: float = 1.10 if quality == Session.Quality.MISS else (1.06 if quality == Session.Quality.GOOD else 1.04)
	body.scale = Vector2(amt, 2.0 - amt)
	var t := body.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(body, "scale", Vector2.ONE, 0.25)

func _shake_camera(duration: float, amplitude: float) -> void:
	_shake_t = duration
	_shake_amp = amplitude

func _perfect_burst(at_world: Vector2) -> void:
	for i in range(14):
		var p := ColorRect.new()
		fx_layer.add_child(p)
		p.color = Color(1.0, 0.92, 0.4, 1.0)
		p.size = Vector2(6, 6)
		p.position = at_world - Vector2(3, 3)
		var angle := _rng.randf_range(-PI, 0.0)
		var dist := _rng.randf_range(60.0, 160.0)
		var target := p.position + Vector2(cos(angle), sin(angle)) * dist
		var t := p.create_tween().set_parallel(true)
		t.tween_property(p, "position", target, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.tween_property(p, "modulate:a", 0.0, 0.55)
		t.chain().tween_callback(func():
			if is_instance_valid(p):
				p.queue_free()
		)

func _on_stability_updated(value: int) -> void:
	# stability doesnt drive the wobble anymore, recent bad placements do
	hud.on_stability_changed(value)
	tower.set_wobble_level(_forced_wobble_floor())

func _forced_wobble_floor() -> int:
	# tower_wobble hazard can force a minimum wobble level
	if hazards and hazards.is_active("tower_wobble"):
		return int(hazards.hazards["tower_wobble"].intensity)
	return 0

func _on_placement_evaluated(quality: int, _offset: float) -> void:
	hud.on_placement(quality)
	# feed the shake pool: bad adds to it, perfect drains
	match quality:
		Session.Quality.MISS:
			tower.notify_bad_placement(1.0)
		Session.Quality.DROPPED:
			tower.notify_bad_placement(1.5)
		Session.Quality.PERFECT:
			tower.notify_perfect_placement()

func _on_height_changed(h: int) -> void:
	hud.on_height_changed(h)

func _on_perfect_streak(streak: int) -> void:
	# combo audio cue rises in pitch per step
	if streak >= 2:
		var pitch: float = 1.0 + clampf(float(streak - 1) * 0.07, 0.0, 0.7)
		AudioManager.play_sfx("combo_step", pitch)

func _on_hazard_started(id: String, _intensity: int, _duration: float) -> void:
	var label := ""
	match id:
		"wind": label = "⚠ Wind"
		"fog": label = "Fog rolling in"
		"floor_swing": label = "Floor swinging"
		"tower_wobble": label = "Tower wobbling"
	hud.show_hazard_banner(label)

func _on_session_ended(reason: String, results: Dictionary) -> void:
	if _ended:
		return
	_ended = true
	# write scores / leaderboard
	if results["mode"] == GameState.Mode.ENDLESS:
		SaveSystem.add_endless_score(results["score"], results["height"])
		_check_endless_unlocks(results["score"])
		AudioManager.play_sfx("fail")
	else:
		if results["success"]:
			SaveSystem.record_level_result(results["level_id"], results["score"], results["stars"])
			_check_level_unlocks(results["level_id"])
			AudioManager.play_sfx("fanfare")
		else:
			AudioManager.play_sfx("fail")
	results["unlocks"] = _new_unlocks.duplicate()
	GameState.store_results(results)
	# stop the crane from accepting input
	crane.input_locked = true
	# tiny delay before the results pop up
	await get_tree().create_timer(0.6).timeout
	_show_results()

func _check_endless_unlocks(score: int) -> void:
	for item in CosmeticLibrary.all_items():
		if SaveSystem.is_unlocked(item.id):
			continue
		if String(item.unlock_kind) == "endless_score":
			var threshold: int = int(String(item.unlock_value))
			if score >= threshold:
				SaveSystem.unlock(item.id)

func _check_level_unlocks(level_id: String) -> void:
	for item in CosmeticLibrary.all_items():
		if SaveSystem.is_unlocked(item.id):
			continue
		if String(item.unlock_kind) == "level_cleared" and String(item.unlock_value) == level_id:
			SaveSystem.unlock(item.id)

func _show_results() -> void:
	var screen := RESULTS_SCENE.instantiate()
	results_layer.add_child(screen)

func _on_cosmetic_unlocked(item_id: String) -> void:
	_new_unlocks.append(item_id)
	AudioManager.play_sfx("unlock")

# ---------- pause ----------
func open_pause() -> void:
	if _ended:
		return
	pause_menu.visible = true
	get_tree().paused = true

func resume() -> void:
	pause_menu.visible = false
	get_tree().paused = false

func restart() -> void:
	get_tree().paused = false
	transition.color.a = 0.0
	var t := create_tween()
	t.tween_property(transition, "color:a", 1.0, 0.3)
	t.tween_callback(func(): get_tree().reload_current_scene())

func quit_to_menu() -> void:
	get_tree().paused = false
	transition.color.a = 0.0
	var t := create_tween()
	t.tween_property(transition, "color:a", 1.0, 0.3)
	t.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
