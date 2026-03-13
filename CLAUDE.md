# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**Leylines** — a 3D magic automation game built in Godot 4.6 using GDScript. Players manipulate mana flowing through leylines to power structures and defeat enemies. Features a dual-view system (real world + magic world) and Steam P2P multiplayer.

## Running & Developing

Open `project.godot` in the Godot 4.6 editor. There is no CLI build step.

- **Run game:** F5 in Godot editor (launches `scenes/world.tscn`)
- **Run current scene:** F6
- **Export/build:** Godot editor → Project → Export (output goes to `/build/`)
- **No test framework** — testing is manual via the editor

## Architecture

**Entry points:**
- `scenes/world.tscn` — main scene, configured in `project.godot`
- `scripts/Global.gd` — autoloaded singleton; manages Steam initialization and global state

**Core systems:**

| Script | Role |
|---|---|
| `scripts/world.gd` | Level generation, portal/player/tower instantiation |
| `scripts/player.gd` | Third-person controller: WASD + mouse look, jump, tower placement preview |
| `scripts/tower.gd` | Turret that spawns `projectile.tscn` with physics-based targeting |
| `scripts/portal.gd` | Viewport-based see-through portals |
| `scripts/Network.gd` | Steam P2P relay networking (disabled by default in Global.gd) |
| `scripts/moon.gd` | Moon orbit logic |
| `scripts/field.gd` | Field/area interaction |

**Physics layers:** `player`, `enemies`, `level` (configured in `project.godot`)

**Addons:**
- `godotsteam` — Steam API integration (multiplayer, achievements)
- `godot-jolt` — Jolt physics engine
- `godot-git-plugin` — Git integration inside the editor

**Assets:** Shaders in `asset/*.gdshader`, materials as `asset/*.tres`, mesh library in `asset/prism.meshlib`.

## Key Design Notes

See `leyliones.txt` for the full game design document. Core mechanic: players place towers along leylines (invisible mana streams) to automate spellcasting. The magic world is a "cyberspace" visualization of those streams.
