## Standalone SceneTree script for multiplayer host integration test.
## Run headlessly with: godot --headless -s res://tests/mp_runners/mp_host_runner.gd
## Writes result to user://mp_test_host.json then exits.
extends SceneTree

const RESULT_PATH  := "user://mp_test_host.json"
const TIMEOUT_SEC  := 20.0
const WANT_PEERS   := 2

var _count   := 0
var _elapsed := 0.0
var _done    := false

func _initialize() -> void:
	Network.peer_connected.connect(_on_peer_connected)
	Network.create_local_lobby()
	print("[HOST] lobby created on port ", Network.LOCAL_PORT)

func _process(delta: float) -> bool:
	if _done:
		return false
	_elapsed += delta
	if _elapsed >= TIMEOUT_SEC:
		_finish(false, "timeout — got %d/%d peers" % [_count, WANT_PEERS])
	return false

func _on_peer_connected(_id: int, _name: String) -> void:
	_count += 1
	print("[HOST] peer connected (%d/%d)" % [_count, WANT_PEERS])
	if _count >= WANT_PEERS:
		_finish(true, "all %d peers connected" % WANT_PEERS)

func _finish(ok: bool, msg: String) -> void:
	_done = true
	var f := FileAccess.open(RESULT_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify({passed = ok, message = msg, role = "host"}))
	f.close()
	print("[HOST] ", "PASS" if ok else "FAIL", " — ", msg)
	quit(0 if ok else 1)
