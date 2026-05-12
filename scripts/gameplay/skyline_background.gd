extends CanvasLayer
class_name SkylineBackground

## Procedural parallax skyline. Three layers of building silhouettes scroll at
## different speeds, with a sky gradient that interpolates over tower height.

@onready var sky_gradient: ColorRect = $SkyRect
@onready var sun: ColorRect = $Sun
@onready var stars: Node2D = $Stars
@onready var clouds: Node2D = $Clouds
@onready var far_layer: Node2D = $FarBuildings
@onready var mid_layer: Node2D = $MidBuildings
@onready var near_layer: Node2D = $NearBuildings

var skyline_data: Dictionary = {
	"top": Color(0.45, 0.71, 0.92),
	"bottom": Color(0.85, 0.93, 1.0),
	"sun": Color(1.0, 0.95, 0.78),
	"mood": "day"
}
var blend_target: float = 0.0  # for height-based mood shift
var current_blend: float = 0.0
var night_data: Dictionary = {
	"top": Color(0.04, 0.05, 0.14),
	"bottom": Color(0.16, 0.13, 0.34),
	"sun": Color(0.96, 0.93, 0.78),
	"mood": "night"
}

const SUN_BASE_POS := Vector2(1560.0, 120.0)
const FAR_LAYER_BASE_Y := 700.0
const MID_LAYER_BASE_Y := 760.0
const NEAR_LAYER_BASE_Y := 820.0

var _cloud_base_positions: Array[Vector2] = []

func _ready() -> void:
	_build_buildings()
	_build_stars()
	_build_clouds()
	_apply_sky()

func setup(p_skyline: Dictionary) -> void:
	skyline_data = p_skyline
	_apply_sky()
	# Adjust whether stars are visible by default
	stars.modulate.a = 1.0 if String(p_skyline.get("mood", "day")) == "night" else 0.0

func set_height_blend(h: int) -> void:
	# Every 10 floors -> 0.5 toward "sunset". Every 20 -> 1.0 toward night.
	# This is a single 0..1 blend toward `night_data`.
	blend_target = clampf(float(h) / 25.0, 0.0, 1.0)

func _process(delta: float) -> void:
	current_blend = lerpf(current_blend, blend_target, delta * 0.6)
	_apply_sky()

func _apply_sky() -> void:
	var t := current_blend
	var top: Color = (Color(skyline_data.get("top"))).lerp(Color(night_data["top"]), t)
	var bot: Color = (Color(skyline_data.get("bottom"))).lerp(Color(night_data["bottom"]), t)
	var sun_c: Color = (Color(skyline_data.get("sun"))).lerp(Color(night_data["sun"]), t)
	# Build a simple gradient by recoloring a vertical gradient texture procedurally
	var grad := Gradient.new()
	grad.set_color(0, top)
	grad.set_color(1, bot)
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill_from = Vector2(0.5, 0)
	tex.fill_to = Vector2(0.5, 1)
	tex.width = 8
	tex.height = 256
	if sky_gradient.has_method("set_texture"):
		# ColorRect doesn't support texture: use TextureRect-like with shader trick — but our scene uses TextureRect alternative.
		pass
	# Instead, since sky_gradient is a ColorRect, just blend the bottom and use a child TextureRect for gradient
	sky_gradient.color = bot
	var tex_rect: TextureRect = $SkyTex
	tex_rect.texture = tex
	sun.color = sun_c
	# stars fade in as we approach night
	stars.modulate.a = clampf((t - 0.5) * 2.0, 0.0, 1.0)
	# clouds fade as we go night
	clouds.modulate.a = clampf(1.0 - t * 1.5, 0.0, 1.0)

func _build_buildings() -> void:
	# Far layer: distant tall silhouettes
	_build_layer(far_layer, 36, 1700.0, 40.0, 120.0, 0.55, Color(0.28, 0.40, 0.62))
	_build_layer(mid_layer, 28, 1700.0, 80.0, 220.0, 0.70, Color(0.16, 0.26, 0.45))
	_build_layer(near_layer, 18, 1700.0, 140.0, 340.0, 0.85, Color(0.08, 0.16, 0.30))

func _build_layer(parent: Node2D, count: int, span: float, h_min: float, h_max: float, alpha: float, color: Color) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var x := -200.0
	while x < span + 200.0:
		var w := rng.randf_range(80.0, 200.0)
		var h := rng.randf_range(h_min, h_max)
		var rect := ColorRect.new()
		rect.color = Color(color.r, color.g, color.b, alpha)
		rect.size = Vector2(w, h)
		rect.position = Vector2(x, 0.0)
		parent.add_child(rect)
		# windows on the building
		if h > 100:
			var win_count := int(h / 28)
			for i in range(win_count):
				if rng.randf() < 0.35:
					var win := ColorRect.new()
					win.color = Color(1.0, 0.95, 0.6, 0.6 * alpha)
					win.size = Vector2(6, 8)
					win.position = Vector2(rng.randf_range(8, w - 14), 16 + i * 28)
					rect.add_child(win)
		x += w + rng.randf_range(4.0, 28.0)

func _build_stars() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in range(80):
		var dot := ColorRect.new()
		var sz := rng.randf_range(2.0, 4.0)
		dot.size = Vector2(sz, sz)
		dot.color = Color(1, 1, 0.95, rng.randf_range(0.5, 1.0))
		dot.position = Vector2(rng.randf_range(0.0, 1920.0), rng.randf_range(0.0, 540.0))
		stars.add_child(dot)

func _build_clouds() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in range(6):
		var c := Node2D.new()
		clouds.add_child(c)
		c.position = Vector2(rng.randf_range(-200.0, 1920.0), rng.randf_range(60.0, 320.0))
		_cloud_base_positions.append(c.position)
		for j in range(rng.randi_range(3, 6)):
			var p := ColorRect.new()
			var w := rng.randf_range(60.0, 110.0)
			p.color = Color(1, 1, 1, 0.85)
			p.size = Vector2(w, 36)
			p.position = Vector2(j * 38.0, rng.randf_range(-8.0, 8.0))
			c.add_child(p)
		# drift
		var tween := c.create_tween().set_loops()
		tween.tween_property(c, "position:x", c.position.x + 400.0, rng.randf_range(40.0, 70.0))
		tween.tween_callback(func(): c.position.x = -260.0)

func apply_parallax(cam_y: float) -> void:
	# cam_y is camera's y in world. When the gameplay camera rises, its y decreases.
	# In screen space we want the skyline to slide downward, revealing more sky.
	var baseline := 0.0
	var dy := cam_y - baseline
	var rise_offset := -dy
	far_layer.position.y = FAR_LAYER_BASE_Y + rise_offset * 0.05
	mid_layer.position.y = MID_LAYER_BASE_Y + rise_offset * 0.12
	near_layer.position.y = NEAR_LAYER_BASE_Y + rise_offset * 0.22
	sun.position = SUN_BASE_POS + Vector2(0.0, rise_offset * 0.03)
	for i in range(min(clouds.get_child_count(), _cloud_base_positions.size())):
		var cloud := clouds.get_child(i) as Node2D
		if cloud == null:
			continue
		cloud.position.y = _cloud_base_positions[i].y + rise_offset * 0.08
