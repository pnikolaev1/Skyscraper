extends Node
## Persistent storage: settings, unlocks, selected cosmetics, level scores, leaderboard.

const SAVE_PATH := "user://savegame.json"
const LEADERBOARD_MAX := 10

signal cosmetic_unlocked(item_id: String)
signal save_loaded

var data: Dictionary = _default_data()

func _ready() -> void:
	load_data()

func _default_data() -> Dictionary:
	return {
		"settings": {
			"music_vol": 0.7,
			"sfx_vol": 0.9
		},
		"unlocks": {
			"skin_glass": true,
			"rooftop_antenna": true,
			"skyline_day": true
		},
		"selected": {
			"skin": "skin_glass",
			"rooftop": "rooftop_antenna",
			"skyline": "skyline_day"
		},
		"level_scores": {},
		"endless_leaderboard": [],
		"endless_best_score": 0,
		"endless_best_height": 0
	}

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		save_data()
		emit_signal("save_loaded")
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		emit_signal("save_loaded")
		return
	var txt := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(txt)
	if typeof(parsed) == TYPE_DICTIONARY:
		# merge with defaults so new keys are populated for legacy saves
		var merged := _default_data()
		for k in parsed.keys():
			merged[k] = parsed[k]
		data = merged
	emit_signal("save_loaded")

func save_data() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("Could not open save file for writing")
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()

# ---------- Settings ----------
func set_music_vol(v: float) -> void:
	data["settings"]["music_vol"] = clampf(v, 0.0, 1.0)
	save_data()

func set_sfx_vol(v: float) -> void:
	data["settings"]["sfx_vol"] = clampf(v, 0.0, 1.0)
	save_data()

func get_music_vol() -> float:
	return float(data["settings"].get("music_vol", 0.7))

func get_sfx_vol() -> float:
	return float(data["settings"].get("sfx_vol", 0.9))

# ---------- Unlocks ----------
func is_unlocked(item_id: String) -> bool:
	return bool(data["unlocks"].get(item_id, false))

func unlock(item_id: String) -> void:
	if data["unlocks"].get(item_id, false):
		return
	data["unlocks"][item_id] = true
	save_data()
	emit_signal("cosmetic_unlocked", item_id)

func get_selected(category: String) -> String:
	return String(data["selected"].get(category, ""))

func set_selected(category: String, item_id: String) -> void:
	data["selected"][category] = item_id
	save_data()

# ---------- Level scores ----------
func record_level_result(level_id: String, score: int, stars: int) -> Dictionary:
	var existing: Dictionary = data["level_scores"].get(level_id, {"best_score": 0, "stars": 0})
	var new_best: bool = score > int(existing.get("best_score", 0))
	if new_best:
		existing["best_score"] = score
	existing["stars"] = max(int(existing.get("stars", 0)), stars)
	data["level_scores"][level_id] = existing
	save_data()
	return {"new_best": new_best, "best_score": existing["best_score"], "stars": existing["stars"]}

func get_level_score(level_id: String) -> Dictionary:
	return data["level_scores"].get(level_id, {"best_score": 0, "stars": 0})

# ---------- Endless leaderboard ----------
func add_endless_score(score: int, height: int) -> Dictionary:
	var entry := {
		"score": score,
		"height": height,
		"date": Time.get_date_string_from_system()
	}
	var lb: Array = data["endless_leaderboard"]
	lb.append(entry)
	lb.sort_custom(func(a, b): return int(a["score"]) > int(b["score"]))
	if lb.size() > LEADERBOARD_MAX:
		lb.resize(LEADERBOARD_MAX)
	data["endless_leaderboard"] = lb
	var was_best: bool = score > int(data.get("endless_best_score", 0))
	if was_best:
		data["endless_best_score"] = score
	if height > int(data.get("endless_best_height", 0)):
		data["endless_best_height"] = height
	save_data()
	return {"new_best": was_best, "rank": lb.find(entry) + 1}

func get_leaderboard() -> Array:
	return data["endless_leaderboard"]
