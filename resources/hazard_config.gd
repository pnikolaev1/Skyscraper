@tool
extends Resource
class_name HazardConfig

# describes when/how a hazard fires inside a level.
# endless mode doesnt use these - hazards there are random based on height

@export var hazard_id: String = "wind"  # wind | fog | floor_swing | tower_wobble
@export_range(1, 5) var intensity: int = 1
@export var duration: float = 5.0      # 0 = lasts the whole level
@export var start_at_floor: int = 0    # how many floors placed before this kicks in
@export var repeat_every: float = 0.0  # seconds between repeats. 0 = one-shot
