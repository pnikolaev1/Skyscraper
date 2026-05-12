extends Node2D
class_name Tower

# the tower of placed floors. the whole thing wobbles as a single rigid body,
# driven by a pool of recent bad placements that decays over time.
# perfect placement drains it, miss/drop adds to it.
# every floor translates by the same amount so the whole stack moves together

signal floor_added(floor_piece: FloorPiece, height: int)

@export var base_y: float = 0.0       # ground y, set by Game on spawn

var floors: Array[FloorPiece] = []  # bottom to top
var wobble_level: int = 0           # hazard adds to amplitude on top of the pool
var shake_t: float = 0.0
var current_amp: float = 0.0
# how many bad placements are still being "felt". decays toward 0
var bad_pool: float = 0.0
var skin_data: Dictionary
var rooftop_type: String = "antenna"

const FLOOR_SCENE := preload("res://scenes/floor_piece.tscn")

func setup(p_skin: Dictionary, p_rooftop: String) -> void:
	skin_data = p_skin
	rooftop_type = p_rooftop

func _process(delta: float) -> void:
	if not has_meta("base_x"):
		set_meta("base_x", position.x)

	shake_t += delta
	# pool of recent badness slowly drains
	bad_pool = maxf(0.0, bad_pool - Config.get_f("shake_decay_rate", 0.4) * delta)

	# whole tower translates as one, all floors move together
	position.x = float(get_meta("base_x")) + _compute_offset(delta)

func _compute_offset(delta: float) -> float:
	var min_floors: int = Config.get_i("min_floors_for_sway", 5)
	var threshold: float = Config.get_f("shake_threshold_bads", 1.0)
	var per_bad: float = Config.get_f("shake_per_bad", 8.0)
	var max_intensity: float = Config.get_f("shake_max_intensity", 3.0)

	var target: float = 0.0
	if floors.size() >= min_floors:
		# only the part of the pool over the threshold counts.
		# 1 bad = no visible shake, 2 = small, 3+ = pretty obvious
		target = clampf(bad_pool - threshold, 0.0, max_intensity) * per_bad
		# off balance: top floor drifted from center? extra shake on top of pool.
		# top-heavy buildings sway more under load
		var lean_px: float = get_lean_offset()
		var lean_threshold: float = Config.get_f("lean_threshold_px", 20.0)
		var lean_excess: float = maxf(0.0, lean_px - lean_threshold)
		var lean_amp: float = clampf(lean_excess * Config.get_f("shake_per_lean_px", 0.25), 0.0, Config.get_f("shake_max_lean_amp", 32.0))
		target += lean_amp
	# tower_wobble hazard piles on top of everything else
	target += float(wobble_level) * Config.get_f("wobble_amp_per_level", 8.0)

	current_amp = lerpf(current_amp, target, delta * 4.0)
	var freq: float = Config.get_f("wobble_frequency", 1.5)
	return current_amp * sin(shake_t * TAU * freq)

# How far the top of the stack has drifted from the base axis, in local pixels.
func get_lean_offset() -> float:
	if floors.size() < 2:
		return 0.0
	var base_local_x: float = floors[0].position.x
	var top_local_x: float = floors.back().position.x
	return absf(top_local_x - base_local_x)

func set_base_x(x: float) -> void:
	position.x = x
	set_meta("base_x", x)

func spawn_base_floor(width: float, y: float) -> FloorPiece:
	var f: FloorPiece = FLOOR_SCENE.instantiate()
	add_child(f)
	f.position = Vector2(0, to_local(Vector2(0, y)).y)
	f.set_size(width, Config.get_f("floor_height", 56.0))
	f.set_skin(skin_data)
	f.mark_placed()
	floors.append(f)
	emit_signal("floor_added", f, 0)
	return f

func place_floor(f: FloorPiece, world_x: float) -> void:
	# stick it onto the top floor. since everything moves together as one block
	# this local x becomes the floors permanent resting spot
	var top := floors.back() as FloorPiece
	var local_y: float = to_local(Vector2(world_x, top.global_position.y - top.height)).y

	if f.get_parent() != self:
		var gpos := f.global_position
		f.get_parent().remove_child(f)
		add_child(f)
		f.global_position = gpos

	# local x relative to whatever the towers currently doing. the floor will
	# follow the tower from now on so no per-floor tracking needed
	f.position.x = world_x - global_position.x
	f.position.y = local_y
	if f.body:
		f.body.rotation = 0.0
	f.mark_placed()

	if floors.size() > 0:
		floors.back().set_rooftop("")
	f.set_rooftop(rooftop_type)
	floors.append(f)
	emit_signal("floor_added", f, floors.size() - 1)

func get_top_floor() -> FloorPiece:
	if floors.is_empty():
		return null
	return floors.back()

func get_top_y_world() -> float:
	var t := get_top_floor()
	if t == null:
		return base_y
	return t.global_position.y - t.height * 0.5

func get_top_center_x_world() -> float:
	var t := get_top_floor()
	if t == null:
		return global_position.x
	return t.global_position.x

func set_wobble_level(level: int) -> void:
	wobble_level = clampi(level, 0, 3)

# game calls these so the tower can react to whats happening
func notify_bad_placement(severity: float = 1.0) -> void:
	bad_pool += severity

func notify_perfect_placement() -> void:
	bad_pool = maxf(0.0, bad_pool - Config.get_f("shake_perfect_recovery", 1.0))

func get_current_amp() -> float:
	return current_amp
