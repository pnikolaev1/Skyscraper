extends Node
class_name Session

## Owner of run-time session state. Emits signals in the order required by the design spec.

enum Quality { PERFECT, GOOD, MISS, DROPPED }

signal floor_released
signal placement_evaluated(quality: int, offset: float)
signal combo_updated(new_combo: int)
signal score_awarded(points: int, new_total: int)
signal stability_updated(new_stability: int)
signal hazard_triggered(hazard_id: String, intensity: int, duration: float)
signal life_lost(remaining: int)
signal session_ended(reason: String, results: Dictionary)
signal height_changed(new_height: int)
signal perfect_streak(streak: int)

var mode: int = GameState.Mode.ENDLESS
var level: LevelData = null

var score: int = 0
var combo: int = 1
var max_combo: int = 1
var stability: int = 100
var lives: int = 3
var elapsed_time: float = 0.0
var height: int = 0
var floors_placed: int = 0
var perfects: int = 0
var goods: int = 0
var misses: int = 0
var perfect_streak_count: int = 0
var ended: bool = false

# Time of last placement, for level mode speed bonus
var _last_place_time: float = 0.0

func _ready() -> void:
	set_process(true)

func start(p_mode: int, p_level: LevelData = null) -> void:
	mode = p_mode
	level = p_level
	score = 0
	combo = 1
	max_combo = 1
	stability = Config.get_i("stability_start", 100)
	lives = Config.get_i("lives_start", 3)
	elapsed_time = 0.0
	height = 0
	floors_placed = 0
	perfects = 0
	goods = 0
	misses = 0
	perfect_streak_count = 0
	ended = false
	_last_place_time = 0.0

func _process(delta: float) -> void:
	if ended:
		return
	elapsed_time += delta
	if mode == GameState.Mode.LEVEL and level and level.time_limit > 0.0:
		if elapsed_time >= level.time_limit:
			_end_session("time_up")

func notify_floor_released() -> void:
	emit_signal("floor_released")

func report_placement(quality: int, offset: float) -> void:
	if ended:
		return
	# A "DROPPED" placement is a floor that fell off the building — it doesn't count
	# toward height/floors_placed, but still costs stability/lives like a miss.
	var counted: bool = quality != Quality.DROPPED
	if counted:
		floors_placed += 1
		height = floors_placed  # 1 floor placed = floor 1 (the base isn't counted)
	# 2: placement_evaluated
	emit_signal("placement_evaluated", quality, offset)
	if counted:
		emit_signal("height_changed", height)

	# 3: combo_updated
	match quality:
		Quality.PERFECT:
			combo += 1
			perfects += 1
			perfect_streak_count += 1
			emit_signal("perfect_streak", perfect_streak_count)
		Quality.GOOD:
			# combo unchanged
			goods += 1
			perfect_streak_count = 0
		Quality.MISS, Quality.DROPPED:
			combo = 1
			misses += 1
			perfect_streak_count = 0
	max_combo = max(max_combo, combo)
	emit_signal("combo_updated", combo)

	# 4: score_awarded (no score for miss or dropped)
	var base: int = Config.get_i("base_pts", 100)
	var bonus: int = 0
	if quality == Quality.PERFECT:
		bonus += Config.get_i("perfect_bonus", 50)
	# Speed bonus (level mode only, on landed placements)
	if mode == GameState.Mode.LEVEL and (quality == Quality.PERFECT or quality == Quality.GOOD):
		var dt := elapsed_time - _last_place_time
		if dt > 0.0 and dt <= Config.get_f("speed_threshold", 1.5):
			bonus += Config.get_i("speed_bonus", 50)
	var pts: int = 0
	if quality == Quality.PERFECT or quality == Quality.GOOD:
		pts = base * combo + bonus
	score += pts
	_last_place_time = elapsed_time
	emit_signal("score_awarded", pts, score)

	# 5: stability_updated
	match quality:
		Quality.PERFECT:
			stability = min(Config.get_i("stability_max", 100), stability + Config.get_i("stability_gain_perfect", 5))
		Quality.MISS, Quality.DROPPED:
			stability = max(0, stability - Config.get_i("stability_loss_miss", 15))
	emit_signal("stability_updated", stability)

	# (6: hazard_triggered is independent, fired by HazardManager via notify_hazard)

	# 7: life_lost (level mode, on miss or dropped)
	if (quality == Quality.MISS or quality == Quality.DROPPED) and mode == GameState.Mode.LEVEL:
		lives = max(0, lives - 1)
		emit_signal("life_lost", lives)

	# 8: session_ended (if conditions met)
	_check_end_conditions()

func notify_hazard(hazard_id: String, intensity: int, duration: float) -> void:
	emit_signal("hazard_triggered", hazard_id, intensity, duration)

func _check_end_conditions() -> void:
	if mode == GameState.Mode.ENDLESS:
		if stability <= 0:
			_end_session("stability_lost")
	elif mode == GameState.Mode.LEVEL:
		if lives <= 0:
			_end_session("no_lives")
			return
		if level and height >= level.target_height and score >= level.score_goal:
			_end_session("level_complete")

func _end_session(reason: String) -> void:
	if ended:
		return
	ended = true
	var results := build_results(reason)
	emit_signal("session_ended", reason, results)

func build_results(reason: String) -> Dictionary:
	var stars := 0
	if mode == GameState.Mode.LEVEL and level and reason == "level_complete":
		# 1, 2, or 3 stars based on thresholds (score_goal * factor)
		var thresholds: PackedFloat32Array = level.star_thresholds
		var goal := float(level.score_goal)
		var ratio: float = float(score) / maxf(1.0, goal)
		stars = 0
		for t in thresholds:
			if ratio >= float(t):
				stars += 1
		stars = clampi(stars, 1, 3)
	var success := false
	if mode == GameState.Mode.LEVEL:
		success = reason == "level_complete"
	else:
		success = false  # endless never "succeeds"
	return {
		"mode": mode,
		"reason": reason,
		"success": success,
		"score": score,
		"max_combo": max_combo,
		"height": height,
		"floors_placed": floors_placed,
		"perfects": perfects,
		"goods": goods,
		"misses": misses,
		"elapsed_time": elapsed_time,
		"stars": stars,
		"level_id": (level.id if level else "")
	}
