extends Node2D
class_name Crane

# crane sweeps left/right at the top, holds a floor on a rope.
# release_floor input drops the floor.

signal floor_released(piece: FloorPiece, velocity: Vector2)
signal next_floor_ready

@export var x_min: float = 160.0
@export var x_max: float = 1760.0

var speed: float = 360.0          # pixels per second
var direction: int = 1
var rope_length: float = 220.0
var cooldown_t: float = 0.0
var cooldown_dur: float = 0.4
var has_floor: bool = true
var input_locked: bool = false

# hazards that mess with the hanging floor
var swing_amplitude: float = 0.0    # px from rope anchor
var swing_omega: float = 3.0        # rad/sec
var swing_t: float = 0.0
var wind_amplitude: float = 0.0
var wind_omega: float = 1.6
var wind_t: float = 0.0

# skin to slap onto new floors as they spawn
var skin_data: Dictionary

@onready var rope: Line2D = $Rope
@onready var hook_sprite: Node2D = $Hook
@onready var floor_holder: Node2D = $FloorHolder
@onready var cab: Node2D = $Cab
@onready var beam_left: ColorRect = $Beam/Left
@onready var beam_right: ColorRect = $Beam/Right

const FLOOR_SCENE := preload("res://scenes/floor_piece.tscn")

var current_floor: FloorPiece = null

func _ready() -> void:
	rope_length = Config.get_f("rope_length", 220.0)
	cooldown_dur = Config.get_f("crane_cooldown", 0.4)
	_spawn_floor()

func setup(p_x_min: float, p_x_max: float, p_skin: Dictionary) -> void:
	x_min = p_x_min
	x_max = p_x_max
	skin_data = p_skin
	speed = Config.get_f("crane_speed_start", 360.0)
	if current_floor:
		current_floor.set_skin(skin_data)

func set_skin(p_skin: Dictionary) -> void:
	skin_data = p_skin
	if current_floor:
		current_floor.set_skin(skin_data)

func set_speed(s: float) -> void:
	speed = clampf(s, 60.0, Config.get_f("crane_speed_max", 900.0))

func get_speed() -> float:
	return speed

func _physics_process(delta: float) -> void:
	if not input_locked:
		_update_movement(delta)
	if has_floor and current_floor:
		_update_floor_hang(delta)
	# rope visual
	if rope and current_floor and has_floor:
		rope.points = PackedVector2Array([
			to_local(hook_sprite.global_position),
			to_local(current_floor.global_position - Vector2(0, current_floor.height * 0.5))
		])
	elif rope:
		# rope just dangles while we wait for the next floor
		rope.points = PackedVector2Array([
			to_local(hook_sprite.global_position),
			to_local(hook_sprite.global_position) + Vector2(0, 30)
		])
	# cooldown tick
	if cooldown_t > 0.0:
		cooldown_t -= delta
		if cooldown_t <= 0.0 and not has_floor:
			_spawn_floor()
			emit_signal("next_floor_ready")
	# input
	if has_floor and not input_locked and Input.is_action_just_pressed("release_floor"):
		_release()

func _update_movement(delta: float) -> void:
	position.x += direction * speed * delta
	if position.x <= x_min:
		position.x = x_min
		direction = 1
	elif position.x >= x_max:
		position.x = x_max
		direction = -1

func _update_floor_hang(delta: float) -> void:
	swing_t += delta
	wind_t += delta
	# pendulum
	var swing_x := sin(swing_t * swing_omega) * swing_amplitude
	# wind shove
	var wind_x := sin(wind_t * wind_omega) * wind_amplitude
	var offset_x := swing_x + wind_x
	# little tilt on the floor so it looks like its leaning into the swing
	var combined: float = swing_x + wind_x
	var tilt := clampf(combined * 0.0025, -0.25, 0.25)
	current_floor.position = floor_holder.position + Vector2(offset_x, rope_length)
	if current_floor.body:
		current_floor.body.rotation = tilt

func _spawn_floor() -> void:
	current_floor = FLOOR_SCENE.instantiate()
	add_child(current_floor)
	current_floor.set_skin(skin_data)
	current_floor.position = floor_holder.position + Vector2(0, rope_length)
	# slide it in from the side so it doesnt just pop into existence
	var start_pos := current_floor.position + Vector2(direction * -400.0, 0)
	current_floor.position = start_pos
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(current_floor, "position", floor_holder.position + Vector2(0, rope_length), 0.25)
	has_floor = true

func _release() -> void:
	if not current_floor:
		return
	# horizontal velocity at release = derivative of the swing offset
	var swing_vx := cos(swing_t * swing_omega) * swing_amplitude * swing_omega
	var wind_vx := cos(wind_t * wind_omega) * wind_amplitude * wind_omega
	var vx := swing_vx + wind_vx
	# could add a tiny bias toward crane direction here but it feels fine without
	var vy := 0.0
	# detach
	var f := current_floor
	current_floor = null
	has_floor = false
	# reparent to scene root so crane can keep moving without dragging the floor along
	var world_pos := f.global_position
	f.get_parent().remove_child(f)
	get_tree().current_scene.add_child(f)
	f.global_position = world_pos
	f.release(Vector2(vx, vy))
	emit_signal("floor_released", f, Vector2(vx, vy))
	cooldown_t = cooldown_dur
	AudioManager.play_sfx("click", randf_range(0.95, 1.05))

# hazard accessors
func set_swing(amplitude: float, omega: float) -> void:
	swing_amplitude = amplitude
	swing_omega = max(0.3, omega)

func set_wind(amplitude: float, omega: float) -> void:
	wind_amplitude = amplitude
	wind_omega = max(0.3, omega)

func reset_swing() -> void:
	swing_amplitude = 0.0

func reset_wind() -> void:
	wind_amplitude = 0.0
