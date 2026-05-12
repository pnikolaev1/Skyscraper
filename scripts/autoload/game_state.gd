extends Node
# keeps track of which mode were playing and stuff shared between scenes

enum Mode { NONE, ENDLESS, LEVEL }

var current_mode: int = Mode.NONE
var current_level_id: String = ""
var last_session_results: Dictionary = {}

func set_endless_mode() -> void:
	current_mode = Mode.ENDLESS
	current_level_id = ""

func set_level_mode(level_id: String) -> void:
	current_mode = Mode.LEVEL
	current_level_id = level_id

func clear_mode() -> void:
	current_mode = Mode.NONE
	current_level_id = ""

func store_results(results: Dictionary) -> void:
	last_session_results = results
