extends Node2D
class_name Tower

## Owns the stack of placed floors. The tower shakes as a single rigid body driven by a
## pool of recent bad placements that decays over time. A perfect placement drains the
## pool; a miss or drop adds to it. The base stays planted only because the camera doesn't
## see below it — every floor in the stack translates with the same offset.

signal floor_added(floor_piece: FloorPiece, height: int)

@export var base_y: float = 0.0       # ground y, set by Game on spawn

var floors: Array[FloorPiece] = []  # bottom -> top
var wobble_level: int = 0           # hazard-driven additive amplitude bump
var shake_t: float = 0.0
var current_amp: float = 0.0
# How many bad placements are "still being felt". Decays toward 0.
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
	# Bad-placement pool decays steadily over time.
	bad_pool = maxf(0.0, bad_pool - Config.get_f("shake_decay_rate", 0.4) * delta)

	# Translate the entire tower as one — every floor moves the same amount.
	position.x = float(get_meta("base_x")) + _compute_offset(delta)

func _compute_offset(delta: float) -> float:
	var min_floors: int = Config.get_i("min_floors_for_sway", 5)
	var threshold: float = Config.get_f("shake_threshold_bads", 1.0)
	var per_bad: float = Config.get_f("shake_per_bad", 8.0)
	var max_intensity: float = Config.get_f("shake_max_intensity", 3.0)

	var target: float = 0.0
	if floors.size() >= min_floors:
		# Only the part of the pool that exceeds the threshold actually shakes the tower.
		# 1 bad placement = no visible shake; 2 = small; 3+ = obvious.
		target = clampf(bad_pool - threshold, 0.0, max_intensity) * per_bad
		# Off-balance: the further the top floor drifts from the base axis, the more
		# the whole tower shakes (top-heavy structures sway more under load).
		var lean_px: float = get_lean_offset()
		var lean_threshold: float = Config.get_f("lean_threshold_px", 20.0)
		var lean_excess: float = maxf(0.0, lean_px - lean_threshold)
		var lean_amp: float = clampf(lean_excess * Config.get_f("shake_per_lean_px", 0.25), 0.0, Config.get_f("shake_max_lean_amp", 32.0))
		target += lean_amp
	# Hazard-driven wobble (tower_wobble hazard) stays additive.
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
	# Snap to the top of the highest floor; every floor moves with the tower as one block,
	# so the local position captured here is the floor's permanent resting position.
	var top := floors.back() as FloorPiece
	var local_y: float = to_local(Vector2(world_x, top.global_position.y - top.height)).y

	if f.get_parent() != self:
		var gpos := f.global_position
		f.get_parent().remove_child(f)
		add_child(f)
		f.global_position = gpos

	# Just set local x relative to the (currently shaken) tower; the floor will track the
	# tower's translation from now on, so no per-floor rest tracking is needed.
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

# Called by Game on every placement so the tower can react to recent bad placements.
func notify_bad_placement(severity: float = 1.0) -> void:
	bad_pool += severity

func notify_perfect_placement() -> void:
	bad_pool = maxf(0.0, bad_pool - Config.get_f("shake_perfect_recovery", 1.0))

func get_current_amp() -> float:
	return current_amp
