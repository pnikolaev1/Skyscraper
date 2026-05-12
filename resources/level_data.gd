@tool
extends Resource
class_name LevelData

## Data-driven level definition. To add a new level: duplicate level_01_tutorial.tres,
## edit the fields in the Godot inspector, and add an entry to LevelLibrary.LEVEL_IDS.

@export var id: String = "level_01_tutorial"
@export var display_name: String = "Tutorial"
@export var target_height: int = 10
@export var score_goal: int = 800
@export var time_limit: float = 0.0      # 0 = no time limit
@export_multiline var intro_text: String = "Click or press Space to drop the floor.\nAim for perfect alignment for combos!"
# Elements must be HazardConfig resources. Stored as plain Array for robust .tres parsing.
@export var hazards: Array = []
# Star thresholds (relative to score_goal). 1 star = score_goal*star_thresholds[0], etc.
@export var star_thresholds: PackedFloat32Array = PackedFloat32Array([1.0, 1.5, 2.0])
