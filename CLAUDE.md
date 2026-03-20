# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**Leylines** — a 3D emergent sandbox game built in Godot 4.6 using GDScript. The game is based around "fields". The field changes the properties of the world within it, as one example of many: the direction or strength of gravity. The world will be like an esoteric puzzle, a clockwork that has not been maintained. Certain objects "atoms" that the player can collect can change the influences of the fields when they enter them. It will allow for combinations of material with fields to solve certain puzzles or experiment with.
The rules should be simple, but they should lead to a lot of complexity. It should be a fun physics sandbox in the end.

The initialization will be like a spinning top, there will be a configuration of the game objects that keep the system moving, and before the player enters its simulated in fastforward to a state of disrepair. So there will need to be various nodes of "atoms" and "fields" that operate like machines.

The big moon the player starts on will be orbiting around a Sun. All the physics rules and how they apply will be done through "atoms" and "fields". So there will be basic "atoms" for gravity, and maintaining simple orbits.  The Sun would have the ability to create new atoms, they would emit periodically into an orbit that intersects with the players moon at certain times. The player would see them overhead like a comet shower, and need to craft things to collect them.

The strength of fields could depend on how many atoms they contain, one example could be why the Sun has such a strong gravity would be its high collection of gravity atoms.


GodotSteam P2P multiplayer.

**Emergent mechanic — cursor field propulsion:** The player carries a Field at the mouse preview position. Because `field.gd` applies atom forces to all `RigidBody3D` bodies inside the field, the player can accelerate or decelerate themselves by sweeping the cursor over placed force atoms. Rows of radial atoms create pull/push thrust; linear atoms fix a direction. The cursor becomes a steering tool — no special-casing required, it emerges from the existing field/atom physics.

**Emergent mechanic — focal atom pitons:** A positive `focal` atom pulls everything in its field toward the atom's own position. Placed on a wall or ceiling, sweeping the cursor field over it pulls the player toward that point — like a piton or grapple anchor. Chained up a surface they form a climbing system. The field's radius acts as natural reach; the atom must be within the cursor field to take effect.

**Emergent mechanic — tunnel propulsion:** The `Tunnel` node places fields along any path. Each path field has a linear atom directing force along the tangent. A ring of off-axis fields surrounds each path point, each with a focal atom positioned at the path center — pulling any body inside back to the axis. The result is a tube that carries the player along the path like a tornado, with no special player logic. Curve the path, reverse the force, vary the radius, and entirely different transport behaviors emerge from the same atom/field primitives.

## Running & Developing

TODO Add testing and developing guidlines

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

## Releases

```
# 1. Make sure you're on main and up to date
git checkout main
git pull

# 2. Tag and push the tag
git tag v0.11
git push origin v0.11

# 3. Create the GitHub release (auto-generates notes from commits)
gh release create v0.11 --title "v0.11" --generate-notes

# 4. (Optional) Attach exported build zips after exporting from Godot
gh release upload v0.11 path/to/build.zip
```

## TODO
~~Make multiplayer object syncing more general, so as to apply to any number of world objects. Right now its limited to "tower"~~ — done: `item_place` network message + `_place_item` handle any registered item
ability for player to place fields, with action_item to remove
atom item_action to remove itself
function to create any arbitrary atom, and random atoms
- atoms that apply force in one arbitrary direction rather than radially
- atoms that increase field size
- atoms that change collision
- atoms that produce light
- atoms that inform which portals connect

reimplement player controls to use fields and atoms. get mouse preview will move a field to where the player is aiming and input will do things in that field
atom for placing nodes
atom for removing nodes