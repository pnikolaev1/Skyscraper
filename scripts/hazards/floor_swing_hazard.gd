extends HazardBase
class_name FloorSwingHazard

# rocks the floor on the rope like a pendulum. crane handles the math

func _on_activate() -> void:
	if crane:
		var amp: float = 30.0 + float(intensity) * 22.0
		var omega: float = 2.4 + float(intensity) * 0.25
		crane.set_swing(amp, omega)

func _on_deactivate() -> void:
	if crane:
		crane.reset_swing()
