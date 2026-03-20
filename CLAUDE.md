# CLAUDE.md

Guidance for Claude Code when working in this repository. See README.md for project vision and design notes.

## Architecture

**Entry points:**
- `scenes/world.tscn` — main scene, configured in `project.godot`
- `scripts/Global.gd` — autoloaded singleton; manages Steam initialization and global state

**Core systems:**

| Script | Role |
|---|---|
| `scripts/world.gd` | Level generation, portal/player/tower instantiation |
| `scripts/player.gd` | Third-person controller: WASD + mouse look, jump, tower placement preview |
| `scripts/Network.gd` | Steam P2P relay networking (disabled by default in Global.gd) |
| `scripts/field.gd` | Field/area interaction |
| `scripts/tunnel.gd` | Path-following tunnel: resamples waypoints, places fields + atoms to propel and center bodies |

**Physics layers:** `player`, `enemies`, `level` (configured in `project.godot`)

**Addons:**
- `godotsteam` — Steam API integration (multiplayer, achievements)

**Assets:** Shaders in `asset/*.gdshader`, materials as `asset/*.tres`, mesh library in `asset/prism.meshlib`.


## Design Patterns

**Spatial events drive signal connections.** Nodes connect and disconnect from each other's signals based on Area3D overlap or mouse entry — not by polling `get_children()` from a parent.

- On `mouse_entered` / `body_entered`: connect to the relevant signal
- On `mouse_exited` / `body_exited`: disconnect from it
- The node manages its own subscriptions; the parent never iterates to find targets

Example: a placed Atom connects `player.item_action → queue_free` when the mouse enters its Area3D, and disconnects on exit. Right-click removes exactly the hovered atom — no world.gd polling required.

