# Leylines

A 3D emergent sandbox game built in Godot 4.6 using GDScript.

The game is based around **fields** and **atoms**. Fields change the properties of the world within them — gravity direction, strength, and more. Atoms are collectible objects that influence any field they enter. Combinations of atoms and fields solve puzzles or produce emergent behaviors.

The rules are simple. The complexity emerges.

---

## Vision

The world starts like a spinning top: a configuration of atoms and fields keeping the system in motion. Before the player enters, it's simulated in fast-forward until it reaches a state of disrepair. The player inherits a clockwork that hasn't been maintained.

The player starts on a moon orbiting a Sun. All physics — orbits, gravity, propulsion — runs through atoms and fields. The Sun emits new atoms periodically into an orbit that intersects the moon; the player sees them overhead like a comet shower and must craft tools to collect them. A field's strength scales with how many atoms it contains — the Sun's gravity is strong because it holds many gravity atoms.

GodotSteam P2P multiplayer.

---

## Emergent Mechanics

**Cursor field propulsion** — The player carries a field at the mouse preview position. Sweeping the cursor over placed force atoms accelerates or steers the player. Rows of radial atoms create thrust; linear atoms fix a direction. No special-casing — it emerges from the existing field/atom physics.

**Focal atom pitons** — A `focal` atom pulls everything in its field toward the atom's own position. Placed on a wall or ceiling, sweeping the cursor field over it pulls the player toward that point — like a grapple anchor. Chained up a surface they form a climbing system.

**Tunnel propulsion** — The `Tunnel` node places fields along a path. Each field has a linear atom directing force along the tangent; surrounding fields have focal atoms pointing to the path center. The result is a tube that carries the player along the path. Curve the path, reverse the force, vary the radius — entirely different behaviors emerge from the same primitives.

**Shadow choreography** — Moving light sources (orbiting sun, placed light atoms) illuminate low-poly faces one at a time. Hard-edged shadows read as distinct events. Paths only appear when lit from a specific angle; sequences only reveal at the right time of day. Emerges from orbital motion + scene geometry.

**Camouflage field** — A field that warps lines of sight around itself, hiding anything inside. Shader distortion at the boundary bends screen-space UVs so the interior is invisible or misleading. Emerges from the field primitive + a boundary shader; no special-casing required.  Changes mesh properties of things inside, example: making it invisible in shadows by turning off emission color

---

## Running & Developing

TODO — add setup and testing guidelines

---
## Development
### Git Development Commands

Common commands for typical development workflow:

```sh
# Clone the repository
git clone https://github.com/yourusername/leylines.git

# Create and switch to a new branch for your feature or fix
git checkout -b feature/my-new-feature

# Stage changes
git add .

# Commit changes
git commit -m "Describe your change"

# Rebase onto latest main (keep your history linear)
git fetch origin
git rebase origin/main

# Push your branch to GitHub
git push origin feature/my-new-feature

# Open a pull request from your branch (use GitHub UI)
```

For merging, prefer fast-forward or squash merges via the GitHub UI to keep the main branch linear.


## Releases

```sh
# 1. Make sure you're on main and up to date
git checkout main
git pull

# 2. Tag and push
git tag v0.X
git push origin v0.X

# 3. Create GitHub release with auto-generated notes
gh release create v0.X --title "v0.X" --generate-notes

# 4. (Optional) Attach exported build
gh release upload v0.X path/to/build.zip
```

---

## TODO

- ability for player to place fields, with action_item to remove
- atom item_action to remove itself
- function to create any arbitrary atom, and random atoms
  - atoms that apply force in one arbitrary direction rather than radially
  - atoms that increase field size
  - atoms that change collision
  - atoms that produce light
  - atoms that inform which portals connect
- reimplement player controls to use fields and atoms: mouse preview moves a field to where the player is aiming, input acts within that field
- atom for placing nodes
- atom for removing nodes
