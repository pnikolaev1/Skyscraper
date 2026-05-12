@tool
extends Resource
class_name CosmeticItem

# a cosmetic you can unlock and apply. apply_data depends on the category

enum Category { SKIN, ROOFTOP, SKYLINE }

@export var id: String = ""
@export var display_name: String = ""
@export var category: Category = Category.SKIN
# "endless_score" or "level_cleared" or "default"
@export var unlock_kind: String = "default"
@export var unlock_value: String = ""  # eg "1500" for score, or a level_id for level_cleared
# the visual data, varies by category:
#   skin:    { base: Color, accent: Color, window: Color }
#   rooftop: { type: String } - antenna / garden / helipad
#   skyline: { top: Color, bottom: Color, sun: Color, mood: String }
@export var apply_data: Dictionary = {}
