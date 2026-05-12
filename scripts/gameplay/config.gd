extends RefCounted
class_name Config

## Loads data/defaults.json once. Read-only at runtime.

const PATH := "res://data/defaults.json"
static var _data: Dictionary

static func _load() -> void:
	if _data != null and not _data.is_empty():
		return
	if not FileAccess.file_exists(PATH):
		_data = {}
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		_data = {}
		return
	var txt := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(txt)
	if typeof(parsed) == TYPE_DICTIONARY:
		_data = parsed
	else:
		_data = {}

static func get_value(key: String, default_value: Variant = null) -> Variant:
	_load()
	return _data.get(key, default_value)

static func get_f(key: String, def: float = 0.0) -> float:
	return float(get_value(key, def))

static func get_i(key: String, def: int = 0) -> int:
	return int(get_value(key, def))
