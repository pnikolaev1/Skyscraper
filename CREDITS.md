# Credits

## Engine
Built with [Godot Engine](https://godotengine.org/) 4.x — MIT License.

## Visuals
All visuals in this build are **generated procedurally in code** using Godot 2D primitives (`ColorRect`, `Polygon2D`, `Line2D`, `GradientTexture2D`). No third-party sprite assets are bundled.

If you'd like to swap in nicer art, the following are great CC0 / permissively-licensed sources to draw from:

* [Kenney.nl](https://kenney.nl/) — CC0 sprite and UI packs (especially the *Roguelike City*, *Game Icons*, and *UI Pack* sets). Drop sprites into `assets/sprites/` and update the relevant scripts.
* [OpenGameArt.org](https://opengameart.org/) — filter to CC0 / CC-BY.
* [Itch.io free game asset bundles](https://itch.io/game-assets/free).

If you add any third-party assets, list them here with their license and source URL.

## Audio
All audio in this build is **synthesized procedurally at runtime** by `scripts/autoload/audio_manager.gd`. Each SFX is a short waveform (sine / chord / noise / decay envelope) built into an `AudioStreamWAV`; the menu and gameplay music are slow harmonic pads with a 4-second loop.

To upgrade the soundscape, drop files into:
* `assets/audio/music/menu.ogg` — looping menu music
* `assets/audio/music/gameplay.ogg` — looping gameplay music
* `assets/audio/sfx/<id>.wav` — where `<id>` is one of: `click`, `whoosh`, `thud_good`, `chime_perfect`, `thunk_miss`, `combo_step`, `fanfare`, `fail`, `unlock`, `ui_blip`

`AudioManager` automatically prefers a file on disk and falls back to the procedural tone if none exists, so the game will still run if you only fill in a few.

Recommended CC0 sources for these slots:
* [Kenney Audio packs](https://kenney.nl/assets?q=audio) — UI Audio, Casino Audio, RPG Audio packs.
* [Freesound.org](https://freesound.org/) — filter to **CC0 (public domain)**.
* For music: [Free Music Archive](https://freemusicarchive.org/) (filter to CC0 / CC-BY) or any royalty-free chiptune pack.

When you add audio, list the file, author, license, and source URL here.

## Fonts
The game uses Godot's bundled default UI font. To install a friendlier rounded sans-serif:

* Download [Fredoka](https://fonts.google.com/specimen/Fredoka), [Nunito](https://fonts.google.com/specimen/Nunito), or [Baloo 2](https://fonts.google.com/specimen/Baloo+2) (all SIL Open Font License).
* Drop the `.ttf` into `assets/fonts/`.
* Open `assets/theme.tres` and set `Default Font` to the imported font.

When fonts are added, list family, author, and license here.

---

When you add third-party files, please use this format:

> **`assets/sprites/leaf_packs/leaf_yellow.png`** — by *Kenney*, CC0, https://kenney.nl/assets/particle-pack
