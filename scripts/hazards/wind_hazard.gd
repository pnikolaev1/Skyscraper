extends HazardBase
class_name WindHazard

# horizontal wind that modulates the rope swing on the hanging floor.
# also spawns leaf particles drifting across the screen

var _dir: int = 1
var _particle_root: Node2D

func _on_activate() -> void:
	_dir = 1 if randf() < 0.5 else -1
	var amp := 12.0 + float(intensity) * 14.0
	var omega := 1.3 + float(intensity) * 0.15
	if crane:
		crane.set_wind(amp * _dir, omega)
	_spawn_particles()
	AudioManager.play_sfx("whoosh", 0.9)

func _on_deactivate() -> void:
	if crane:
		crane.reset_wind()
	if _particle_root and is_instance_valid(_particle_root):
		_particle_root.queue_free()
		_particle_root = null

func _spawn_particles() -> void:
	# put particles on the fog (screen-space) layer so they drift across the
	# screen no matter where the camera is
	var root := Node2D.new()
	root.z_index = 20
	var host: Node = fog_layer if fog_layer else get_tree().current_scene
	host.add_child(root)
	root.name = "WindParticles"
	_particle_root = root
	# a bunch of small drifting rects (poor mans particles)
	for i in range(30):
		var leaf := ColorRect.new()
		var hue := randf_range(0.10, 0.18)
		var col := Color.from_hsv(hue, 0.5, 0.95, 0.85)
		leaf.color = col
		var sx := randf_range(6.0, 14.0)
		leaf.size = Vector2(sx, sx * 0.6)
		leaf.position = Vector2(randf_range(-200.0, 2120.0), randf_range(-200.0, 1100.0))
		root.add_child(leaf)
		var tween := leaf.create_tween().set_loops()
		var target_x := leaf.position.x + _dir * 1800.0
		tween.tween_property(leaf, "position:x", target_x, randf_range(2.5, 4.0))
		tween.parallel().tween_property(leaf, "rotation", randf_range(-6.0, 6.0), randf_range(2.5, 4.0))
		tween.tween_callback(func():
			leaf.position.x = -100.0 if _dir > 0 else 2020.0
			leaf.position.y = randf_range(-200.0, 1100.0)
		)
