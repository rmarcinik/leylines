## Push-atom MP test — Host process.
##
## Protocol:
##   1. Both peers exchange their announced position via "push_pos".
##   2. Each creates a RigidBody3D + Field + push Atom at the RECEIVED position,
##      so the body sits inside the field and gets pushed.
##   3. After physics settles, each sends displacement via "push_result".
##   4. Pass only when BOTH peers report displacement >= MIN_DISP.
##
## Run with: godot --path . -s res://tests/mp_runners/mp_push_host_runner.gd
## Writes result to user://mp_push_host.json
extends SceneTree

const RESULT_PATH      := "user://mp_push_host.json"
const TIMEOUT_SEC      := 30.0
const MY_POS           := Vector3(5.0, 2.0, 0.0)  # position announced to peer
const FIELD_RADIUS     := 10.0
const PUSH_FORCE       := 50.0   # linear +X force on bodies inside the field
const WARMUP_FRAMES    := 10     # frames before counting physics (Area3D needs time to register)
const PHYSICS_DURATION := 1.5   # seconds of physics to run
const MIN_DISP         := 2.0   # minimum expected displacement (metres)

var _net     : Node
var _body    : RigidBody3D
var _started := false
var _elapsed := 0.0
var _done    := false

var _warmup_n       := 0
var _physics_t      := 0.0
var _my_disp        := -1.0
var _peer_disp      := -1.0
var _start_pos      : Vector3

func _initialize() -> void:
	pass  # too early for autoloads

func _process(delta: float) -> bool:
	if not _started:
		_started = true
		_net = get_root().get_node("Network")
		_net.register("push_pos",    _on_push_pos)
		_net.register("push_result", _on_push_result)
		_net.peer_connected.connect(_on_peer_connected)
		_net.create_local_lobby()

	if _done:
		return false

	_elapsed += delta
	if _elapsed >= TIMEOUT_SEC:
		_finish(false, "timeout")
		return false

	if _body:
		if _warmup_n < WARMUP_FRAMES:
			_warmup_n += 1
		elif _physics_t < PHYSICS_DURATION:
			_physics_t += delta
		elif _my_disp < 0.0:
			_my_disp = _body.global_position.distance_to(_start_pos)
			print("[PUSH HOST] displacement=%.3f" % _my_disp)
			_net.send("push_result", {"d": _my_disp}, true)
			_check_finish()

	return false

func _on_peer_connected(_id: int, _name: String) -> void:
	_net.send("push_pos", {"x": MY_POS.x, "y": MY_POS.y, "z": MY_POS.z}, true)

func _on_push_pos(_sender: int, data: Dictionary) -> void:
	var pos := Vector3(data["x"], data["y"], data["z"])
	_start_pos = pos
	_build_at(pos)

func _build_at(pos: Vector3) -> void:
	_body = RigidBody3D.new()
	_body.gravity_scale = 0.0
	var col := CollisionShape3D.new()
	col.shape = SphereShape3D.new()
	_body.add_child(col)
	get_root().add_child(_body)
	_body.global_position = pos

	var field := preload("res://scenes/field.tscn").instantiate() as Field
	field.default_radius = FIELD_RADIUS
	field.accepts_placed_atoms = true
	get_root().add_child(field)
	field.global_position = pos

	var atom := preload("res://scenes/atom.tscn").instantiate() as Atom
	atom.linear = Vector3(PUSH_FORCE, 0.0, 0.0)
	get_root().add_child(atom)
	atom.global_position = pos

func _on_push_result(_sender: int, data: Dictionary) -> void:
	_peer_disp = data["d"]
	_check_finish()

func _check_finish() -> void:
	if _my_disp < 0.0 or _peer_disp < 0.0:
		return
	var ok := _my_disp >= MIN_DISP and _peer_disp >= MIN_DISP
	_finish(ok, "host=%.3f guest=%.3f min=%.3f" % [_my_disp, _peer_disp, MIN_DISP])

func _finish(ok: bool, msg: String) -> void:
	if _done:
		return
	_done = true
	var f := FileAccess.open(RESULT_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify({passed = ok, message = msg, role = "push_host"}))
	f.close()
	print("[PUSH HOST] %s - %s" % ["PASS" if ok else "FAIL", msg])
	quit(0 if ok else 1)
