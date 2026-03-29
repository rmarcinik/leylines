## Standalone SceneTree script for multiplayer guest integration test.
## Run with:
##   godot --path . -s res://tests/mp_runners/mp_guest_runner.gd -- --guest-index N
## Writes result to user://mp_test_guest_N.json then exits.
extends SceneTree

const TIMEOUT_SEC := 15.0

var _net         : Node
var _idx         := 0
var _result_path := ""
var _elapsed     := 0.0
var _done        := false
var _started     := false

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--guest-index" and i + 1 < args.size():
			_idx = int(args[i + 1])
	_result_path = "user://mp_test_guest_%d.json" % _idx

func _process(delta: float) -> bool:
	if not _started:
		_started = true
		_net = get_root().get_node("Network")
		_net.lobby_ready.connect(_on_lobby_ready)
		_net.join_local_lobby()
		print("[GUEST %d] joining localhost:%d" % [_idx, _net.LOCAL_PORT])
	if _done:
		return false
	_elapsed += delta
	if _elapsed >= TIMEOUT_SEC:
		_finish(false, "timeout waiting for lobby_ready")
	return false

func _on_lobby_ready(lobby_id: int) -> void:
	_finish(true, "joined lobby %d" % lobby_id)

func _finish(ok: bool, msg: String) -> void:
	_done = true
	var f := FileAccess.open(_result_path, FileAccess.WRITE)
	f.store_string(JSON.stringify({passed = ok, message = msg, role = "guest", index = _idx}))
	f.close()
	print("[GUEST %d] %s - %s" % [_idx, "PASS" if ok else "FAIL", msg])
	quit(0 if ok else 1)
