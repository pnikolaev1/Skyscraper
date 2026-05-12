@tool
extends Resource
class_name LevelData

# one level definition.
# to add a new level: duplicate level_01_tutorial.tres, edit the fields in the
# godot inspector, and add it to LevelLibrary.LEVELS

@export var id: String = "level_01_tutorial"
@export var display_name: String = "Tutorial"
@export var target_height: int = 10
@export var score_goal: int = 800
@export var time_limit: float = 0.0      # 0 = no time limit
@export_multiline var intro_text: String = "Click or press Space to drop the floor.\nAim for perfect alignment for combos!"
# elements should be HazardConfig resources. kept as a plain Array so .tres files
# parse reliably (typed arrays of script classes can be fussy)
@export var hazards: Array = []
# star thresholds, relative to score_goal. 1 star = goal * thresh[0] etc
@export var star_thresholds: PackedFloat32Array = PackedFloat32Array([1.0, 1.5, 2.0])
