extends HazardBase
class_name FloorSwingHazard

## Active pendulum on the rope. Drives the floor swing amplitude on the crane.

func _on_activate() -> void:
	if crane:
		var amp: float = 30.0 + float(intensity) * 22.0
		var omega: float = 2.4 + float(intensity) * 0.25
		crane.set_swing(amp, omega)

func _on_deactivate() -> void:
	if crane:
		crane.reset_swing()
