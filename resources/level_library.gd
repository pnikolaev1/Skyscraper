extends RefCounted
class_name LevelLibrary

## Ordered list of level resource paths. To add a new level: drop a new .tres at the path
## and add its id+path here.

const LEVELS: Array = [
	{"id": "level_01_tutorial", "path": "res://resources/levels/level_01_tutorial.tres"}
]

static func load_all() -> Array[LevelData]:
	var out: Array[LevelData] = []
	for entry in LEVELS:
		var path: String = entry["path"]
		if ResourceLoader.exists(path):
			var res: LevelData = load(path)
			if res:
				out.append(res)
	return out

static func load_by_id(id: String) -> LevelData:
	for entry in LEVELS:
		if entry["id"] == id and ResourceLoader.exists(entry["path"]):
			return load(entry["path"])
	return null
