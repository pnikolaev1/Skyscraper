extends HazardBase
class_name FogHazard

# fog overlay that kills visibility for a bit. fairness pings every 2s at the
# crane hook and the center of the top floor so its not totally blind

var _fog_rect: ColorRect
var _ping_timer: float = 0.0
var _ping_interval: float = 2.0

func _on_activate() -> void:
	_ping_interval = Config.get_f("fog_ping_interval", 2.0)
	_ping_timer = 0.2  # quick first ping so player isnt blind for 2s
	# make the fog overlay
	if fog_layer:
		var rect := ColorRect.new()
		var alpha := clampf(0.35 + 0.10 * float(intensity), 0.35, 0.75)
		rect.color = Color(0.92, 0.94, 0.97, 0.0)
		rect.anchor_right = 1.0
		rect.anchor_bottom = 1.0
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fog_layer.add_child(rect)
		_fog_rect = rect
		var t := rect.create_tween()
		t.tween_property(rect, "color:a", alpha, 0.6)

func _on_deactivate() -> void:
	if _fog_rect and is_instance_valid(_fog_rect):
		var rect := _fog_rect
		var t := rect.create_tween()
		t.tween_property(rect, "color:a", 0.0, 0.5)
		t.tween_callback(func():
			if is_instance_valid(rect):
				rect.queue_free()
		)
		_fog_rect = null

func _on_tick(delta: float) -> void:
	_ping_timer -= delta
	if _ping_timer <= 0.0:
		_ping_timer = _ping_interval
		_emit_pings()

func _emit_pings() -> void:
	if not ping_layer:
		return
	# ping at crane hook
	if crane and is_instance_valid(crane):
		var hook := crane.get_node_or_null("Hook")
		if hook:
			_spawn_ping(hook.global_position, Color(1.0, 0.95, 0.30))
	# ping at top floor center
	if tower and is_instance_valid(tower):
		var top := tower.get_top_floor()
		if top:
			_spawn_ping(Vector2(top.global_position.x, top.global_position.y - top.height * 0.5), Color(0.30, 0.95, 1.0))

func _spawn_ping(world_pos: Vector2, color: Color) -> void:
	var sprite := Node2D.new()
	ping_layer.add_child(sprite)
	sprite.global_position = world_pos
	sprite.z_index = 25

	var ring := ColorRect.new()
	ring.color = color
	ring.size = Vector2(22, 22)
	ring.position = Vector2(-11, -11)
	sprite.add_child(ring)
	ring.pivot_offset = Vector2(11, 11)

	var glow := ColorRect.new()
	glow.color = Color(color.r, color.g, color.b, 0.4)
	glow.size = Vector2(60, 60)
	glow.position = Vector2(-30, -30)
	sprite.add_child(glow)
	glow.pivot_offset = Vector2(30, 30)

	var tween := sprite.create_tween().set_parallel(true)
	tween.tween_property(ring, "scale", Vector2(2.4, 2.4), 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, "color:a", 0.0, 0.6)
	tween.tween_property(glow, "scale", Vector2(3.0, 3.0), 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(glow, "color:a", 0.0, 0.6)
	tween.chain().tween_callback(func():
		if is_instance_valid(sprite):
			sprite.queue_free()
	)
