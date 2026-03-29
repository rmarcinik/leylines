# Run Tests

You are an agent running the automated test suite for this Godot 4.6.1 project and fixing any failures.

## Step 1 — Pre-flight: ensure GdUnitFileAccess.gd is patched

Read `addons/gdUnit4/src/core/GdUnitFileAccess.gd` line 191. If `resource_as_string` calls `file.get_as_text(true)`, change it to `file.get_as_text()`. Godot 4.6.1 removed the `skip_cr` parameter. This fix gets reverted by linters — always check before running.

## Step 2 — Run tests

Run the test script (handles both gdUnit4 and multiplayer tests):

```
powershell -ExecutionPolicy Bypass -File run_tests.ps1
```

Do NOT use the `-d` flag — it activates the interactive debugger which hangs on any parse error.

Capture stdout. Exit code 0 = all pass. Non-zero = failures to triage.

## Step 3 — Read the output

Scan stdout for lines containing:
- `FAILED` or `ERROR` — test name and failure message
- `Parse Error` — GDScript compilation issue (fix the addon or game script)
- `GdUnitConsole` or `GdUnitFileAccess` errors — addon compat issue (see pre-flight)

## Step 4 — Triage each failure

| Pattern | Cause | Action |
|---|---|---|
| `get_as_text` / `Too many arguments` | GdUnitFileAccess not patched | Re-apply Step 1 fix |
| `test_player_moves_closer_to_goal` | Physics non-determinism | Increase `FRAMES` constant in the test |
| `test_no_lateral_drift` | Gravity drift | Raise lateral threshold from 1.0 → 2.0 in the assertion |
| `test_focal_atom_curves_path_toward_goal` | Atom not registered with field | Add extra `await get_tree().physics_frame` after adding nodes |
| `test_all_items_place_and_remove` on specific item | find_child("InventoryItem") returns null | Confirm the item's _ready() does `inv.name = "InventoryItem"` before add_child — Godot names nodes by native base type, not class_name |
| Any `Parse Error` in a test file | API mismatch | Read the test, read the relevant game script, align them |
| Consistent logic failure | Game code wrong | Read game script, fix the behavior |

## Step 5 — Fix

**Flaky physics test:** increase `FRAMES` or the force magnitude. Do NOT loosen assertions.

**Logic failure:** read the relevant game script first to understand actual behavior, then either:
- Fix game code if the behavior is wrong
- Fix the test if the assertion assumed the wrong thing (e.g. wrong node name)

**Compilation error in a test:** read the test file and the scripts it imports, resolve API mismatches.

## Step 6 — Re-run and confirm

After fixes, re-run the same command from Step 2. Report pass/fail for each test. If all pass, report success. If any still fail, continue triaging.

## Known issues

- `GdUnitFileAccess.gd:191` — `get_as_text(true)` is invalid in Godot 4.6.1. Always check before running.
- `InventoryItem.new()` node name — Godot 4 auto-names nodes by native base type (`@Node@3`), NOT by `class_name`. Any script that dynamically creates InventoryItem must set `inv.name = "InventoryItem"` before `add_child(inv)`.
- `CallableDoubler.gd:84` — Parse error about `call()` signature mismatch; this is a GdUnit4 internal issue that prints as SCRIPT ERROR but does NOT block test execution.
- `SceneTree._process` must return `bool` in Godot 4.6 — MP runners use `-> bool` and `return false`.
- MP runners must NOT use `--headless` — it prevents GodotSteam from registering `Steam`, causing `Network.gd` to fail to compile, which means the `Network` autoload is never registered, causing `Identifier not found: Network` in the runner scripts.
- MP runners must NOT reference `Network` as a bare global identifier — GDScript checks it at compile time before autoloads are ready. Use `get_root().get_node("Network")` at runtime instead.
- MP runners must NOT call `Network` methods in `_initialize()` — autoload nodes are not yet in the tree. Do setup in the first `_process()` frame using a `_started` flag.
- Push-atom test output shows `Identifier not found: Network` in `player.gd:152` cascading to `field.gd` — this is a startup-time parse error (hot-reload artifact). Scripts are compiled from cache by the time test code runs; the physics works correctly. Ignore this noise if the test passes.
- Multiplayer tests spawn host + 2 guest processes and read JSON results from `%APPDATA%\Godot\app_userdata\leylines\`.
