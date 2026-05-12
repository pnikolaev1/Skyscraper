# Skyscraper

A relaxing 2D arcade tower-stacking game built in Godot 4. A crane sweeps across the top of the screen carrying a floor on a rope; release the floor at the right moment to stack it on the tower below. Perfect alignment grows a combo and rewards a higher score. Misses cost stability (in Endless) or lives (in Level mode). The skyline behind the tower drifts from day to sunset to night as your tower grows.

Built for ages 6+ — soft gradients, readable silhouettes, satisfying placement effects.

## Running the project

1. Install **Godot 4.x** (latest stable). The project was authored against Godot 4.6 with the GL Compatibility renderer.
2. Open the Godot editor and choose **Import**, then point it at this folder's `project.godot`.
3. Wait for the import to finish, then press **F5** (Play). The main menu is the default scene.

If you'd rather run from the command line:

```
godot4 --path C:/uni/Skyscraper
```

## Controls

| Action            | Input                       |
|-------------------|-----------------------------|
| Release the floor | Left mouse click • Spacebar |
| Pause             | Escape                      |
| Back in menus     | Escape • Right mouse click  |

## Game modes

**Endless** — Stack as high as you can. Each miss subtracts from your *stability* bar. When stability reaches zero, the run ends and your score is added to the local leaderboard. Difficulty escalates with height: the crane sweeps faster and hazards (wind, fog, swing) appear more often.

**Level** — Hand-crafted goals. Each level has a target height, a score goal, optional time limit, and a hazard schedule. You have 3 lives; each miss costs one. Earn up to 3 stars based on how far above the score goal you finish.

## How to add a new level

1. Duplicate `resources/levels/level_01_tutorial.tres` (right-click in the FileSystem dock → Duplicate, or copy the file in your OS file manager).
2. Rename the copy, e.g. `level_02_winds.tres`.
3. Open the new file in the Godot inspector and edit:
   * `id` — internal id, must match the filename stem
   * `display_name` — shown on the level card
   * `target_height` — number of floors required
   * `score_goal` — score required to clear
   * `time_limit` — seconds, or `0` for no limit
   * `intro_text` — shown in an overlay at level start
   * `hazards` — array of `HazardConfig` resources (see below)
   * `star_thresholds` — multipliers of `score_goal` for 1, 2, 3 stars (default `[1.0, 1.5, 2.0]`)
4. Open `resources/level_library.gd` and add the new entry to `LEVELS`:

```gdscript
const LEVELS: Array = [
    {"id": "level_01_tutorial", "path": "res://resources/levels/level_01_tutorial.tres"},
    {"id": "level_02_winds",    "path": "res://resources/levels/level_02_winds.tres"},
]
```

5. (Optional) To add a hazard, click `+` next to `hazards` in the inspector, choose **New HazardConfig**, then set:
   * `hazard_id` — one of `wind`, `fog`, `floor_swing`, `tower_wobble`
   * `intensity` — 1 to 5
   * `duration` — seconds (0 = permanent)
   * `start_at_floor` — number of floors placed before this hazard first activates
   * `repeat_every` — seconds between repeats (0 = no repeat)

The new level will appear automatically in the Level Select grid.

## How to add a new cosmetic

Cosmetics are stored in `resources/cosmetic_library.gd` as code constants (kept inline so there's no risk of missing-resource warnings and no need for a .tres per item). To add one:

1. Pick a category — `SKINS`, `ROOFTOPS`, or `SKYLINES` — and append a dictionary like:

```gdscript
{
    "id": "skin_concrete",
    "display_name": "Concrete Towers",
    "category": "skin",
    "unlock_kind": "endless_score",    # default | endless_score | level_cleared
    "unlock_value": "6000",            # threshold or level id
    "apply_data": {
        "base":   Color(0.62, 0.62, 0.65),
        "accent": Color(0.85, 0.85, 0.88),
        "window": Color(0.30, 0.30, 0.35)
    }
}
```

2. Save the file. The new item will appear in the Cosmetics screen and unlock automatically when the condition is met. To make it unlocked by default, set `"unlock_kind": "default"` and add the id to `SaveSystem._default_data()` under `"unlocks"`.

The three categories use slightly different `apply_data`:
* **skin**: `{ base, accent, window }` Colors used on the floor sprite.
* **rooftop**: `{ type: String }` — `antenna`, `garden`, or `helipad`. To add a new rooftop type, extend `_add_rooftop()` in `scripts/gameplay/floor_piece.gd`.
* **skyline**: `{ top, bottom, sun, mood }` — colours for the day-time gradient; the engine blends toward night as the tower grows tall.

## Tuning constants

Gameplay constants live in `data/defaults.json` and are read at runtime by `scripts/gameplay/config.gd`. Useful knobs:

| Key                          | Meaning                                                  |
|------------------------------|----------------------------------------------------------|
| `base_pts`                   | Base score per placement                                 |
| `perfect_bonus`              | Bonus added on a perfect placement                       |
| `speed_bonus`                | Bonus for quick consecutive placements (level mode)      |
| `speed_threshold`            | Seconds within which a placement counts as "quick"       |
| `perfect_ratio`              | Offset (relative to floor width) that counts as perfect  |
| `good_ratio`                 | Offset (relative to floor width) that still counts       |
| `drop_ratio`                 | Offset beyond this and the floor slips off the side and is discarded (no height gain) |
| `min_floors_for_sway`        | Tower stays rigid until it's at least this tall          |
| `shake_threshold_bads`       | Bads-in-pool below this still don't shake (one whoopsie is forgiven) |
| `shake_per_bad`              | Px of sway amplitude added per "bad" beyond the threshold |
| `shake_max_intensity`        | Cap on the bad-pool's contribution (multiples of `shake_per_bad`) |
| `shake_decay_rate`           | Bad-pool drained per second (so the building calms down naturally) |
| `shake_perfect_recovery`     | Bad-pool drained instantly per perfect placement         |
| `lean_threshold_px`          | Top-of-stack drift below this is "fine" and doesn't add shake |
| `shake_per_lean_px`          | Extra shake amplitude added per pixel of drift past the threshold |
| `shake_max_lean_amp`         | Cap on lean's contribution to amplitude                  |
| `stability_gain_perfect`     | Stability gained on perfect                              |
| `stability_loss_miss`        | Stability lost on miss                                   |
| `crane_speed_start`          | Initial crane sweep speed (px/sec)                       |
| `crane_speed_step`           | Extra speed per `crane_speed_step_every` floors (endless)|
| `crane_speed_max`            | Hard cap on crane sweep speed                            |
| `wobble_amp_per_level`       | Pixels of tower sway per wobble level                    |
| `fog_ping_interval`          | Seconds between fairness pings during fog               |
| `endless_wind_chance_per_floor` | Base probability a wind hazard starts on each placement |

Edit the JSON and restart the run — no recompile needed.

## Save data

Persisted to `user://savegame.json`. On Windows this is at `%APPDATA%\Godot\app_userdata\Skyscraper\savegame.json`. Saved data includes:

* Audio volumes (music + SFX)
* Cosmetic unlocks and current selection
* Per-level best score and stars
* Top 10 endless runs

To wipe and start fresh, delete that file.

## Known limitations / what's stubbed

* **Leaderboard is local only.** The `SaveSystem` interface (`add_endless_score`, `get_leaderboard`) is designed so it could later be swapped for an online backend, but currently writes to the JSON above and is not shared between machines.
* **Procedural audio.** If you don't drop .ogg music and .wav sfx into `assets/audio/`, the game synthesizes simple tones at runtime via `AudioManager`. They're functional but plain — drop in real samples (see CREDITS.md for sources) for the intended atmosphere.
* **One designed level.** Adding more is intentionally a drop-in resource edit (see above).

## Credits

See [`CREDITS.md`](CREDITS.md) for asset and library attributions.
