extends HazardBase
class_name TowerWobbleHazard

## Boosts the tower's wobble level temporarily. Note: stability-derived wobble is
## applied separately; this hazard just adds a forced minimum.

var _previous_min: int = 0
var _forced: int = 0

func _on_activate() -> void:
	if tower:
		_forced = clampi(intensity, 1, 3)
		_previous_min = tower.wobble_level
		tower.set_wobble_level(max(tower.wobble_level, _forced))

func _on_deactivate() -> void:
	if tower:
		# Will be re-evaluated by the manager on next stability update.
		tower.set_wobble_level(_previous_min)
