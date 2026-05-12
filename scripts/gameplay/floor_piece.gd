extends Node2D
class_name FloorPiece

# one building floor. it has a few states:
#   hanging - crane controls position
#   falling - just gravity (and maybe horizontal velocity from swing)
#   placed  - static, glued to the tower
#   dropped - slipped off the side, tumbling away

signal landed(landing_offset_x: float, on_floor: FloorPiece)

enum State { HANGING, FALLING, PLACED, DROPPED }

var state: int = State.HANGING
var width: float = 260.0
var height: float = 56.0
var velocity: Vector2 = Vector2.ZERO
var angular_velocity: float = 0.0  # rad/sec, only used while DROPPED
var swing_angle: float = 0.0   # tilt while hanging
var skin_data: Dictionary = {
	"base": Color(0.50, 0.78, 0.92),
	"accent": Color(0.85, 0.95, 1.0),
	"window": Color(0.20, 0.36, 0.50)
}
var rooftop_type: String = ""  # only the topmost floor actually gets the deco
var has_decoration: bool = false
var _gravity: float = 2400.0

@onready var body: Node2D = $Body
@onready var shadow: Polygon2D = $Shadow

func _ready() -> void:
	width = Config.get_f("floor_width", 260.0)
	height = Config.get_f("floor_height", 56.0)
	_gravity = float(ProjectSettings.get_setting("physics/2d/default_gravity", 2400.0))
	_redraw()

func set_size(w: float, h: float) -> void:
	width = w
	height = h
	_redraw()

func set_skin(d: Dictionary) -> void:
	if d.is_empty():
		return
	skin_data = d
	_redraw()

func set_rooftop(type: String) -> void:
	rooftop_type = type
	has_decoration = type != "" and type != "none"
	_redraw()

func _physics_process(delta: float) -> void:
	if state == State.FALLING or state == State.DROPPED:
		velocity.y += _gravity * delta
		position += velocity * delta
		if state == State.DROPPED and body:
			body.rotation += angular_velocity * delta

func release(initial_velocity: Vector2 = Vector2.ZERO) -> void:
	state = State.FALLING
	velocity = initial_velocity
	swing_angle = 0.0
	if body:
		body.rotation = 0.0

func drop(side: float) -> void:
	# slipping off the building. side is the sign of how far off it was
	# (positive = right, negative = left). floor keeps falling but slides sideways
	# and spins outward like a toppling slab
	state = State.DROPPED
	# sideways nudge so it actually clears the tower
	velocity.x += signf(side) * 220.0
	# tiny upward kick so you can actually see it tumble before gravity wins
	if velocity.y > 0:
		velocity.y *= 0.6
	angular_velocity = signf(side) * randf_range(3.5, 5.5)

func mark_placed() -> void:
	state = State.PLACED
	velocity = Vector2.ZERO
	angular_velocity = 0.0

func get_top_y() -> float:
	# top edge in world coords
	return global_position.y - height * 0.5

func get_center_x() -> float:
	return global_position.x

func get_half_width() -> float:
	return width * 0.5

func _redraw() -> void:
	if body == null:
		return
	# nuke whatevers there
	for c in body.get_children():
		c.queue_free()
	# main rect
	var rect := ColorRect.new()
	rect.color = Color(skin_data.get("base", Color(0.5, 0.8, 0.9)))
	rect.size = Vector2(width, height)
	rect.position = Vector2(-width * 0.5, -height * 0.5)
	body.add_child(rect)
	# top accent stripe
	var accent := ColorRect.new()
	accent.color = Color(skin_data.get("accent", Color.WHITE))
	accent.size = Vector2(width, 6)
	accent.position = Vector2(-width * 0.5, -height * 0.5)
	body.add_child(accent)
	# row of windows
	var win_color: Color = Color(skin_data.get("window", Color(0.2, 0.36, 0.5)))
	var window_w := 22.0
	var window_h := 22.0
	var gap := 14.0
	var inset := 18.0
	var count := int((width - inset * 2.0) / (window_w + gap))
	if count > 0:
		var span := count * (window_w + gap) - gap
		var start_x := -span * 0.5
		var y := -window_h * 0.5 + 4.0
		for i in range(count):
			var w := ColorRect.new()
			w.color = win_color
			w.size = Vector2(window_w, window_h)
			w.position = Vector2(start_x + i * (window_w + gap), y)
			body.add_child(w)
	# rooftop deco only goes on the actual top floor
	if has_decoration:
		_add_rooftop()
	# shadow
	if shadow:
		shadow.polygon = PackedVector2Array([
			Vector2(-width * 0.5 + 6, height * 0.5),
			Vector2(width * 0.5 + 12, height * 0.5),
			Vector2(width * 0.5 + 22, height * 0.5 + 12),
			Vector2(-width * 0.5 - 4, height * 0.5 + 12)
		])
		shadow.color = Color(0, 0, 0, 0.18)

func _add_rooftop() -> void:
	var top := Node2D.new()
	body.add_child(top)
	top.position = Vector2(0, -height * 0.5)
	match rooftop_type:
		"antenna":
			var pole := ColorRect.new()
			pole.color = Color(0.20, 0.22, 0.28)
			pole.size = Vector2(4, 56)
			pole.position = Vector2(-2, -56)
			top.add_child(pole)
			var dish := ColorRect.new()
			dish.color = Color(0.95, 0.30, 0.30)
			dish.size = Vector2(18, 18)
			dish.position = Vector2(-9, -68)
			top.add_child(dish)
		"garden":
			var planter := ColorRect.new()
			planter.color = Color(0.40, 0.28, 0.20)
			planter.size = Vector2(width * 0.7, 10)
			planter.position = Vector2(-width * 0.35, -10)
			top.add_child(planter)
			var leaf := ColorRect.new()
			leaf.color = Color(0.34, 0.66, 0.30)
			leaf.size = Vector2(width * 0.6, 14)
			leaf.position = Vector2(-width * 0.3, -22)
			top.add_child(leaf)
			# tiny tree silhouettes
			for i in range(3):
				var t := ColorRect.new()
				t.color = Color(0.20, 0.45, 0.25)
				t.size = Vector2(14, 30)
				t.position = Vector2(-30 + i * 30, -52)
				top.add_child(t)
		"helipad":
			var pad := ColorRect.new()
			pad.color = Color(0.16, 0.16, 0.20)
			pad.size = Vector2(width * 0.7, 14)
			pad.position = Vector2(-width * 0.35, -14)
			top.add_child(pad)
			var stripe := ColorRect.new()
			stripe.color = Color(1, 0.85, 0.20)
			stripe.size = Vector2(20, 6)
			stripe.position = Vector2(-10, -10)
			top.add_child(stripe)
			# H letter, kinda. close enough
			var bar1 := ColorRect.new()
			bar1.color = Color(1, 0.95, 0.7)
			bar1.size = Vector2(6, 28)
			bar1.position = Vector2(-30, -38)
			top.add_child(bar1)
			var bar2 := ColorRect.new()
			bar2.color = Color(1, 0.95, 0.7)
			bar2.size = Vector2(6, 28)
			bar2.position = Vector2(24, -38)
			top.add_child(bar2)
			var crossbar := ColorRect.new()
			crossbar.color = Color(1, 0.95, 0.7)
			crossbar.size = Vector2(60, 5)
			crossbar.position = Vector2(-30, -26)
			top.add_child(crossbar)
