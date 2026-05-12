@tool
extends Resource
class_name CosmeticItem

## A cosmetic that can be unlocked and applied. The apply_data dictionary varies by category.

enum Category { SKIN, ROOFTOP, SKYLINE }

@export var id: String = ""
@export var display_name: String = ""
@export var category: Category = Category.SKIN
## "endless_score" or "level_cleared" or "default"
@export var unlock_kind: String = "default"
@export var unlock_value: String = ""  # e.g. "1500" for score, or a level_id for level_cleared
## Visual data:
##   skin: { base: Color, accent: Color, window: Color }
##   rooftop: { type: String }  type in [antenna, garden, helipad]
##   skyline: { top: Color, bottom: Color, sun: Color, mood: String }
@export var apply_data: Dictionary = {}
