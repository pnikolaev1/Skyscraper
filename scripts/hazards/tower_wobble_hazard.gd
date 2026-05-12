extends HazardBase
class_name TowerWobbleHazard

# forces a minimum wobble level for a bit. the bad-placement pool stacks on top

var _previous_min: int = 0
var _forced: int = 0

func _on_activate() -> void:
	if tower:
		_forced = clampi(intensity, 1, 3)
		_previous_min = tower.wobble_level
		tower.set_wobble_level(max(tower.wobble_level, _forced))

func _on_deactivate() -> void:
	if tower:
		# game.gd re-evaluates this on the next stability tick anyway
		tower.set_wobble_level(_previous_min)
