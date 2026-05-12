@tool
extends Resource
class_name HazardConfig

## Describes when and how a hazard activates within a level.
## In endless mode hazards are driven internally by HazardManager, not from configs.

@export var hazard_id: String = "wind"  # wind | fog | floor_swing | tower_wobble
@export_range(1, 5) var intensity: int = 1
@export var duration: float = 5.0      # 0 = permanent
@export var start_at_floor: int = 0    # number of floors placed before this hazard first activates
@export var repeat_every: float = 0.0  # seconds between repeats; 0 = no repeat
