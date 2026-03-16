extends Node3D

var time: float

@onready var _land          = preload("res://scenes/land.tscn")
@onready var _tower         = preload("res://scenes/tower.tscn")
@onready var _atom         = preload("res://scenes/atom.tscn")
@onready var _portal        = preload("res://scenes/portal.tscn")
@onready var _moon          = preload("res://scenes/moon.tscn")
@onready var _path_follower = $path_3d/path_follow_3d

var _remote_players: Dictionary = {}   # steam_id (int) -> Node3D ghost
var _scenes: Dictionary = {}           # preview Node3D -> {scene: PackedScene, config: Dictionary}
var _scene_by_path: Dictionary = {}    # resource_path -> PackedScene

func _ready() -> void:
	make_grid()
	make_portal()
	move_moon()
	ready_player()
	_connect_network()
	add_child(preload("res://scripts/LobbyUI.gd").new())

func _connect_network() -> void:
	Network.peer_connected.connect(_on_peer_connected)
	Network.peer_disconnected.connect(_on_peer_disconnected)
	Network.register("player_pos", _on_player_pos)
	Network.register("item_place", _on_item_place_remote)

# ── Player setup ──────────────────────────────────────────────────────────────

func ready_player() -> void:
	$Player.send_preview.connect(_on_send_preview)
	_register_item(_tower)
	_register_item(_atom, {radial = -100.0})

func _register_item(scene: PackedScene, config: Dictionary = {}) -> void:
	var preview = scene.instantiate()
	_apply_config(preview, config)
	$Player.add_child(preview)
	$Player.inventory.append(preview)
	_scenes[preview] = {scene = scene, config = config}
	_scene_by_path[scene.resource_path] = scene

func _on_send_preview(node: Node3D, xform: Transform3D) -> void:
	var entry = _scenes[node]
	_place_item(entry.scene, xform, entry.config, true)
	Network.send("item_place", {
		'scene': entry.scene.resource_path,
		'origin': xform.origin,
		'basis': xform.basis,
		'config': entry.config,
	}, true)

func _on_item_place_remote(_sender: int, data: Dictionary) -> void:
	var scene: PackedScene = _scene_by_path.get(data['scene'], load(data['scene']))
	_place_item(scene, Transform3D(data['basis'], data['origin']), data.get('config', {}), false)

func _place_item(scene: PackedScene, xform: Transform3D, config: Dictionary = {}, is_local: bool = true) -> Node:
	var instance = place_node(scene, xform)
	_apply_config(instance, config)
	if is_local and instance.has_method("item_action"):
		if not $Player.item_action.is_connected(instance.item_action):
			$Player.item_action.connect(instance.item_action)
	return instance

func _apply_config(node: Node, config: Dictionary) -> void:
	for key in config:
		node.set(key, config[key])

# ── World generation ──────────────────────────────────────────────────────────

func make_grid() -> void:
	var step   := 8
	var width  := 6
	var length := 6
	var height := 4
	for x in range(0, width * step, step):
		for z in range(0, length * step, step):
			var node = _land.instantiate()
			node.position = Vector3(x, height, z)
			add_child(node, true)


func make_portal() -> void:
	var node = place_node(_portal)
	node.get_node('Enter').global_position = Vector3(40, 4, -20)
	node.get_node('Enter').get_node('EnterView').get_node('EnterCam').global_position = Vector3(40, 4, -20)
	node.get_node('Exit').global_position  = Vector3(190, 180, 100)
	node.get_node('Exit').get_node('ExitView').get_node('ExitCam').global_position  = Vector3(190, 180, 100)

	var farnode = place_node(_portal)
	farnode.get_node('Enter').global_position = Vector3(-40, 4, 0)
	farnode.get_node('Enter').get_node('EnterView').get_node('EnterCam').global_position = Vector3(-40, 4, 0)
	farnode.get_node('Exit').global_position  = Vector3(0, 180, 2700)
	farnode.get_node('Exit').get_node('ExitView').get_node('ExitCam').global_position  = Vector3(0, 180, 2700)

func place_node(scene: PackedScene, xform: Transform3D = Transform3D()) -> Node:
	var instance = scene.instantiate()
	add_child(instance, true)
	instance.global_transform = xform
	return instance

# ── Remote peers ──────────────────────────────────────────────────────────────

func _on_peer_connected(steam_id: int, _username: String) -> void:
	if steam_id == Global.steam_id:
		return
	_spawn_remote_player(steam_id)

func _on_peer_disconnected(steam_id: int) -> void:
	if _remote_players.has(steam_id):
		_remote_players[steam_id].queue_free()
		_remote_players.erase(steam_id)

func _spawn_remote_player(steam_id: int) -> void:
	if _remote_players.has(steam_id):
		return
	var ghost := Node3D.new()
	var mesh  := MeshInstance3D.new()
	var cap   := CapsuleMesh.new()
	cap.radius = 0.4
	cap.height = 1.8
	var mat   := StandardMaterial3D.new()
	mat.albedo_color = Color.CYAN
	mesh.mesh = cap
	mesh.material_override = mat
	mesh.position.y = cap.height
	ghost.add_child(mesh)
	add_child(ghost, true)
	_remote_players[steam_id] = ghost
	print("ghost spawned for peer: ", steam_id)

var _pos_logged := false
func _on_player_pos(sender: int, data: Dictionary) -> void:
	if not _pos_logged:
		print("player_pos received from ", sender, " pos=", data.get('pos', 'MISSING'))
		_pos_logged = true
	if not _remote_players.has(sender):
		_spawn_remote_player(sender)
	var ghost: Node3D = _remote_players[sender]
	ghost.global_position = data['pos']
	ghost.global_rotation = data['rot']

# ── Moon ──────────────────────────────────────────────────────────────────────

func move_moon() -> void:
	var moon        = _moon.instantiate()
	moon.freeze     = false
	var path_target = Node3D.new()
	_path_follower.add_child(path_target, true)
	add_child(moon, true)
	moon.global_position = Vector3(210, 20, -200)
	moon.name            = "elevator"
	moon.mesh_radius     = 10
	path_target.name     = "path_target"

func moon_move_static(delta: float) -> void:
	time += delta
	var moon        = get_node('elevator')
	var path_target = _path_follower.get_node("path_target")
	_path_follower.progress_ratio = (sin(time * 0.1) + 1) * 0.5
	var to_target: Vector3 = path_target.global_position - moon.global_position
	moon.apply_central_impulse(to_target * 1)
	var to_moon = Vector3(209, 143, 54) - $moon.global_position
	$moon.apply_central_impulse(to_moon * 10)

func _physics_process(_delta: float) -> void:
	moon_move_static(_delta)
