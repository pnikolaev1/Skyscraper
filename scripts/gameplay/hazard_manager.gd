extends Node
class_name HazardManager

## Schedules and owns hazard instances. Endless: random by tower height curve.
## Level: driven by HazardConfig list with floor-based start and repeat cadence.

signal hazard_started(id: String, intensity: int, duration: float)
signal hazard_ended(id: String)

var crane: Crane
var tower: Tower
var fog_layer: CanvasLayer
var ping_layer: Node2D
var session: Session

var hazards: Dictionary = {}  # id -> HazardBase

var _level_state: Array = []  # parallel to level.hazards: { config, next_t, started_once }
var _endless_rng := RandomNumberGenerator.new()
var _endless_first_floor: int = 4

func setup(p_crane: Crane, p_tower: Tower, p_fog_layer: CanvasLayer, p_ping_layer: Node2D, p_session: Session) -> void:
	crane = p_crane
	tower = p_tower
	fog_layer = p_fog_layer
	ping_layer = p_ping_layer
	session = p_session
	_endless_rng.randomize()
	_endless_first_floor = Config.get_i("endless_hazard_first_at_floor", 4)
	_instantiate_hazards()

func _instantiate_hazards() -> void:
	var defs := {
		"wind": WindHazard,
		"fog": FogHazard,
		"floor_swing": FloorSwingHazard,
		"tower_wobble": TowerWobbleHazard
	}
	for id in defs.keys():
		var h: HazardBase = defs[id].new()
		h.name = id
		add_child(h)
		h.setup(crane, tower, fog_layer, ping_layer)
		h.activated.connect(func(intensity, duration): _on_activated(id, intensity, duration))
		h.deactivated.connect(func(): _on_deactivated(id))
		hazards[id] = h

func _on_activated(id: String, intensity: int, duration: float) -> void:
	if session:
		session.notify_hazard(id, intensity, duration)
	emit_signal("hazard_started", id, intensity, duration)

func _on_deactivated(id: String) -> void:
	emit_signal("hazard_ended", id)

func configure_for_level(level: LevelData) -> void:
	_level_state.clear()
	if level == null:
		return
	for cfg in level.hazards:
		_level_state.append({"config": cfg, "next_t": 0.0, "started": false})

func _process(delta: float) -> void:
	if session == null or session.ended:
		return
	if session.mode == GameState.Mode.LEVEL:
		_process_level(delta)
	else:
		_process_endless(delta)

func _process_level(delta: float) -> void:
	for state in _level_state:
		var cfg: HazardConfig = state["config"]
		var dur: float = float(cfg.duration if cfg.duration > 0.0 else 5.0)
		if not state["started"]:
			if session.floors_placed >= cfg.start_at_floor:
				_activate(cfg.hazard_id, cfg.intensity, dur)
				state["started"] = true
				state["next_t"] = cfg.repeat_every if cfg.repeat_every > 0.0 else 0.0
		elif cfg.repeat_every > 0.0:
			state["next_t"] -= delta
			if state["next_t"] <= 0.0:
				_activate(cfg.hazard_id, cfg.intensity, dur)
				state["next_t"] = cfg.repeat_every

func _process_endless(_delta: float) -> void:
	# Trigger on floor changes only (cheap and avoids retriggering)
	pass

func notify_floor_placed(floor_n: int) -> void:
	if session == null or session.mode != GameState.Mode.ENDLESS:
		return
	if floor_n < _endless_first_floor:
		return
	# escalating chance per floor placed (capped)
	var bump: float = clampf(float(floor_n - _endless_first_floor) * 0.005, 0.0, 0.10)
	var c_wind: float = Config.get_f("endless_wind_chance_per_floor", 0.018) + bump
	var c_fog: float = Config.get_f("endless_fog_chance_per_floor", 0.010) + bump * 0.6
	var c_swing: float = Config.get_f("endless_swing_chance_per_floor", 0.014) + bump
	if not hazards["wind"].is_active and _endless_rng.randf() < c_wind:
		var intensity: int = clampi(1 + int(floor_n / 10), 1, 4)
		_activate("wind", intensity, Config.get_f("wind_default_duration", 6.0))
	if not hazards["fog"].is_active and floor_n >= 8 and _endless_rng.randf() < c_fog:
		var fog_intensity: int = clampi(1 + int(floor_n / 12), 1, 4)
		_activate("fog", fog_intensity, Config.get_f("fog_default_duration", 7.0))
	if not hazards["floor_swing"].is_active and _endless_rng.randf() < c_swing:
		var s_intensity: int = clampi(1 + int(floor_n / 8), 1, 4)
		_activate("floor_swing", s_intensity, Config.get_f("swing_default_duration", 5.0))

func _activate(id: String, intensity: int, duration: float) -> void:
	if not hazards.has(id):
		return
	var h: HazardBase = hazards[id]
	if h.is_active:
		return
	h.activate(intensity, duration)

func is_active(id: String) -> bool:
	return hazards.has(id) and hazards[id].is_active

func deactivate_all() -> void:
	for h in hazards.values():
		if h.is_active:
			h.deactivate()
