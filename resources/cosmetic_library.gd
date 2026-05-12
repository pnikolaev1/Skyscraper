extends RefCounted
class_name CosmeticLibrary

## A static catalogue of all cosmetics. Keeps them in code so we don't risk missing-resource
## warnings from .tres references; SaveSystem tracks which are unlocked by id.

const SKINS := [
	{
		"id": "skin_glass",
		"display_name": "Glass Tower",
		"category": "skin",
		"unlock_kind": "default",
		"unlock_value": "",
		"apply_data": {"base": Color(0.50, 0.78, 0.92), "accent": Color(0.85, 0.95, 1.0), "window": Color(0.20, 0.36, 0.50)}
	},
	{
		"id": "skin_brick",
		"display_name": "Brick Heritage",
		"category": "skin",
		"unlock_kind": "endless_score",
		"unlock_value": "1500",
		"apply_data": {"base": Color(0.72, 0.36, 0.27), "accent": Color(0.86, 0.55, 0.42), "window": Color(0.97, 0.86, 0.55)}
	},
	{
		"id": "skin_neon",
		"display_name": "Neon Nights",
		"category": "skin",
		"unlock_kind": "endless_score",
		"unlock_value": "5000",
		"apply_data": {"base": Color(0.16, 0.07, 0.32), "accent": Color(0.95, 0.25, 0.78), "window": Color(0.25, 0.95, 0.93)}
	}
]

const ROOFTOPS := [
	{
		"id": "rooftop_antenna",
		"display_name": "Antenna",
		"category": "rooftop",
		"unlock_kind": "default",
		"unlock_value": "",
		"apply_data": {"type": "antenna"}
	},
	{
		"id": "rooftop_garden",
		"display_name": "Sky Garden",
		"category": "rooftop",
		"unlock_kind": "level_cleared",
		"unlock_value": "level_01_tutorial",
		"apply_data": {"type": "garden"}
	},
	{
		"id": "rooftop_helipad",
		"display_name": "Helipad",
		"category": "rooftop",
		"unlock_kind": "endless_score",
		"unlock_value": "3000",
		"apply_data": {"type": "helipad"}
	}
]

const SKYLINES := [
	{
		"id": "skyline_day",
		"display_name": "Daylight City",
		"category": "skyline",
		"unlock_kind": "default",
		"unlock_value": "",
		"apply_data": {"top": Color(0.45, 0.71, 0.92), "bottom": Color(0.85, 0.93, 1.0), "sun": Color(1.0, 0.95, 0.78), "mood": "day"}
	},
	{
		"id": "skyline_sunset",
		"display_name": "Sunset Pier",
		"category": "skyline",
		"unlock_kind": "endless_score",
		"unlock_value": "2000",
		"apply_data": {"top": Color(0.32, 0.20, 0.45), "bottom": Color(1.0, 0.62, 0.40), "sun": Color(1.0, 0.50, 0.30), "mood": "sunset"}
	},
	{
		"id": "skyline_night",
		"display_name": "Neon Skyline",
		"category": "skyline",
		"unlock_kind": "endless_score",
		"unlock_value": "4000",
		"apply_data": {"top": Color(0.04, 0.05, 0.14), "bottom": Color(0.16, 0.13, 0.34), "sun": Color(0.96, 0.93, 0.78), "mood": "night"}
	}
]

static func all_items() -> Array:
	var out: Array = []
	out.append_array(SKINS)
	out.append_array(ROOFTOPS)
	out.append_array(SKYLINES)
	return out

static func get_by_category(category: String) -> Array:
	match category:
		"skin": return SKINS
		"rooftop": return ROOFTOPS
		"skyline": return SKYLINES
		_: return []

static func get_by_id(id: String) -> Dictionary:
	for it in all_items():
		if it.id == id:
			return it
	return {}

static func unlock_label(item: Dictionary) -> String:
	match String(item.get("unlock_kind", "default")):
		"default":
			return "Unlocked"
		"endless_score":
			return "Endless score %s" % item.get("unlock_value", "")
		"level_cleared":
			return "Clear level: %s" % item.get("unlock_value", "")
		_:
			return ""
