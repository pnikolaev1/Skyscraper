extends RefCounted
class_name Scoring

## Pure helpers for classifying placement quality.

static func classify(offset_x: float, floor_width: float) -> int:
	var perfect_ratio := Config.get_f("perfect_ratio", 0.05)
	var good_ratio := Config.get_f("good_ratio", 0.30)
	var drop_ratio := Config.get_f("drop_ratio", 0.65)
	var d := absf(offset_x)
	if d <= perfect_ratio * floor_width:
		return Session.Quality.PERFECT
	if d <= good_ratio * floor_width:
		return Session.Quality.GOOD
	if d <= drop_ratio * floor_width:
		return Session.Quality.MISS
	return Session.Quality.DROPPED
