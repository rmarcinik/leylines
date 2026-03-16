# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**Leylines** — a 3D emergent sandbox game built in Godot 4.6 using GDScript. The game is based around "fields". The field changes the properties of the world within it, as one example of many: the direction or strength of gravity. The world will be like an esoteric puzzle, a clockwork that has not been maintained. Certain objects "atoms" that the player can collect can change the influences of the fields when they enter them. It will allow for combinations of material with fields to solve certain puzzles or experiment with.
The rules should be simple, but they should lead to a lot of complexity. It should be a fun physics sandbox in the end.

The initialization will be like a spinning top, there will be a configuration of the game objects that keep the system moving, and before the player enters its simulated in fastforward to a state of disrepair. So there will need to be various nodes of "atoms" and "fields" that operate like machines.

The big moon the player starts on will be orbiting around a Sun. All the physics rules and how they apply will be done through "atoms" and "fields". So there will be basic "atoms" for gravity, and maintaining simple orbits.  The Sun would have the ability to create new atoms, they would emit periodically into an orbit that intersects with the players moon at certain times. The player would see them overhead like a comet shower, and need to craft things to collect them.

The strength of fields could depend on how many atoms they contain, one example could be why the Sun has such a strong gravity would be its high collection of gravity atoms.


GodotSteam P2P multiplayer.

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

**Physics layers:** `player`, `enemies`, `level` (configured in `project.godot`)

**Addons:**
- `godotsteam` — Steam API integration (multiplayer, achievements)

**Assets:** Shaders in `asset/*.gdshader`, materials as `asset/*.tres`, mesh library in `asset/prism.meshlib`.


## Releases

Tag a release from the current commit:

```
git tag v0.1-sandbox
git push origin v0.1-sandbox
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