# Multiplayer Plan — Steam P2P

## Current State

`Network.gd` already handles:
- Lobby create/join via Steam
- P2P session accept + relay
- Member list tracking
- Packet send (broadcast or targeted) + read loop
- Handshake message on join

`Global.gd` has Steam init **commented out** (avoids spamming Spacewar app ID 480 during dev).

Everything else (`world.gd`, `player.gd`, `tower.gd`) is fully local with no network awareness.

---

## Authority Model

**Client-authoritative position, host-authoritative world seed.**

- Each peer simulates their own player physics and broadcasts their state.
- The host generates the world and sends the seed to joiners.
- Co-op only — no need for server-side cheat detection.

---

## Packet Types to Add

Extend the `match readable_data['message']` block in `Network.gd`:

| message | payload | direction |
|---|---|---|
| `handshake` | `steam_id`, `username` | peer → all (exists) |
| `world_seed` | `seed: int` | host → joining peer |
| `player_state` | `steam_id`, `position`, `rotation` | peer → all, every frame |
| `tower_place` | `steam_id`, `origin`, `basis` | peer → all, on place |
| `tower_action` | `steam_id`, `tower_index` | peer → all, on right-click |

Send `player_state` as **unreliable** (`send_type = 0`). Send `tower_place` / `tower_action` as **reliable** (`send_type = 2`) so placements never drop.

---

## Step-by-Step Changes

### 1. Enable Steam — `Global.gd`

Uncomment `steamInit`, `getSteamID`, `getPersonaName`, and `run_callbacks()`. Keep app ID 480 for local testing (Spacewar); swap to real ID at ship time.

```gdscript
func _ready() -> void:
    var init = Steam.steamInit()
    steam_id = Steam.getSteamID()
    steam_username = Steam.getPersonaName()

func _process(_delta):
    Steam.run_callbacks()
```

Also add `Network` as an **Autoload** in `project.godot` (currently it is not — it only exists as a script).

---

### 2. Lobby UI — new `scenes/lobby.tscn`

Minimal: two buttons ("Host" / "Join") and a text field for lobby ID. On Host: call `Network.create_lobby()`. On Join: call `Network.join_lobby(id)`. Can be a CanvasLayer overlay on `world.tscn`.

---

### 3. World Seed Sync — `world.gd`

```gdscript
func _ready():
    if Network.is_host:
        make_grid(randi())           # host picks seed
        Network.send_world_seed()    # broadcast to peers
    # clients wait for world_seed packet before calling make_grid

func make_grid(seed: int) -> void:
    seed_rng(seed)                   # use seed for any random tile variation
    ...
```

In `Network.gd`, on `world_seed` receipt: call `get_tree().get_root().get_node("world").make_grid(seed)`.

---

### 4. Remote Player Spawning

Create `scenes/remote_player.tscn`: a `Node3D` with a mesh (same capsule as Player) but **no** input, camera, or physics — just a visual ghost.

In `Network.gd`, when a `handshake` arrives:
```gdscript
'handshake':
    get_lobby_members()
    world.spawn_remote_player(readable_data['steam_id'])
```

Add to `world.gd`:
```gdscript
var remote_players: Dictionary = {}   # steam_id -> Node3D

func spawn_remote_player(steam_id: int) -> void:
    var rp = _remote_player.instantiate()
    add_child(rp, true)
    remote_players[steam_id] = rp
```

---

### 5. Player State Broadcast — `player.gd`

Add an `is_local: bool = true` export. Remote instances set it false (no input, no camera).

In `_process`:
```gdscript
if is_local:
    # existing input / camera code
    Network.send_player_state(global_position, global_rotation)
```

In `Network.gd`, on `player_state` receipt:
```gdscript
'player_state':
    var rp = world.remote_players.get(packet_sender)
    if rp:
        rp.global_position = readable_data['position']
        rp.global_rotation = readable_data['rotation']
```

Optional: lerp position on the remote player for smoothness.

---


## File Change Summary

| File | Change |
|---|---|
| `Global.gd` | Uncomment Steam init + callbacks |
| `project.godot` | Add `Network` as Autoload |
| `Network.gd` | Add packet handlers for `world_seed`, `player_state`, `tower_place`, `tower_action` |
| `world.gd` | Seed-based `make_grid`, `spawn_remote_player`, `place_tower_remote`, tower index array |
| `player.gd` | `is_local` flag, broadcast position in `_process` |
| `scenes/lobby.tscn` | New: Host/Join UI |
| `scenes/remote_player.tscn` | New: ghost mesh for remote peers |

---

## Dev / Test Flow

1. Keep app ID 480 (Spacewar) — both clients must own it (free).
2. Launch two instances on same machine: one hosts, one joins via lobby ID printed to console.
3. Swap to real App ID before shipping; request one via Steamworks partner portal.
