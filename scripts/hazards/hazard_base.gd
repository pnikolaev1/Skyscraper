extends Node
class_name HazardBase

# base class for hazards. subclasses override _on_activate / _on_deactivate / _on_tick

signal activated(intensity: int, duration: float)
signal deactivated

var is_active: bool = false
var intensity: int = 1
var remaining: float = 0.0

# refs passed in from outside
var crane: Crane
var tower: Tower
var fog_layer: CanvasLayer
var ping_layer: Node2D

func setup(p_crane: Crane, p_tower: Tower, p_fog_layer: CanvasLayer, p_ping_layer: Node2D) -> void:
	crane = p_crane
	tower = p_tower
	fog_layer = p_fog_layer
	ping_layer = p_ping_layer

func activate(p_intensity: int, p_duration: float) -> void:
	intensity = clampi(p_intensity, 1, 5)
	remaining = p_duration
	is_active = true
	_on_activate()
	emit_signal("activated", intensity, p_duration)

func deactivate() -> void:
	if not is_active:
		return
	is_active = false
	_on_deactivate()
	emit_signal("deactivated")

func _process(delta: float) -> void:
	if not is_active:
		return
	if remaining > 0.0:
		remaining -= delta
		if remaining <= 0.0:
			deactivate()
			return
	_on_tick(delta)

func _on_activate() -> void:
	pass

func _on_deactivate() -> void:
	pass

func _on_tick(_delta: float) -> void:
	pass
