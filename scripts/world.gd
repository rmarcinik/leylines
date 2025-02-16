extends Node3D
var time : float
@onready var _land = preload("res://scenes/land.tscn")
@onready var _tower = preload("res://scenes/tower.tscn")
@onready var _portal = preload("res://scenes/portal.tscn")
@onready var _moon = preload("res://scenes/moon.tscn")
#@onready var _pillar = $Blocks/Foundation2/Pillar
@onready var _path_follower = $path_3d/path_follow_3d

func _ready() -> void:
	make_grid()
	make_portal()
	move_moon()
	$Player.send_preview.connect(place_tower)
	var node = _tower.instantiate()
	$Player.add_child(node)

func place_node(node, globaltransform: Transform3D = Transform3D()):
	var instance = node.instantiate()
	add_child(instance, true)
	instance.global_transform = globaltransform
	return instance

func place_tower(preview):
	#var node = tower.instantiate()
	#add_child(node, true)
	#node.global_transform = preview
	var node = place_node(_tower, preview)
	$Player.action_tower.connect(node.action_tower)

func make_grid() -> void:
	var width = 6
	var length = 6
	var height = 4
	var step = 8
	var xrange = width * step
	var zrange = length * step
	var node

	for x in range(0, xrange, step):
		for z in range(0, zrange, step):
			node = _land.instantiate()
			node.position = Vector3(x,height,z)
			add_child(node, true)

func make_portal() -> void:
	var node = place_node(_portal)
	node.get_node('Enter').global_position = Vector3(40, 4, -20)
	node.get_node('Enter').get_node('EnterView').get_node('EnterCam').global_position = Vector3(40, 4, -20)
	node.get_node('Exit').global_position = Vector3(190, 180, 100)
	node.get_node('Exit').get_node('ExitView').get_node('ExitCam').global_position = Vector3(190, 180, 100)

	var farnode = place_node(_portal)
	farnode.get_node('Enter').global_position = Vector3(-40, 4, 0)
	farnode.get_node('Enter').get_node('EnterView').get_node('EnterCam').global_position = Vector3(-40, 4, 0)
	farnode.get_node('Exit').global_position = Vector3(0, 180, 2700)
	farnode.get_node('Exit').get_node('ExitView').get_node('ExitCam').global_position = Vector3(0, 180, 2700)

func move_moon() -> void:
	var moon = _moon.instantiate()
	moon.add_to_group('elevator')
	moon.freeze = false
	var path_target = Node3D.new()  # Create bare Node3D to follow path
	_path_follower.add_child(path_target, true)  # Add target to path follower
	add_child(moon, true)  # Add moon to world instead of path follower
	moon.global_position = Vector3(210,20,-200)
	moon.name = "moon"  # Name it so we can find it easily
	path_target.name = "path_target"

func moon_move_static(delta: float) -> void:
	time += delta
	var moon = get_tree().get_nodes_in_group('elevator')[0]
	var path_target = _path_follower.get_node("path_target")

	# Update path follower position
	var progress = (sin(time * 0.1) + 1) * 0.5
	_path_follower.progress_ratio = progress

	# Calculate direction to path target
	var to_target = path_target.global_position - moon.global_position
	# Apply force towards target
	moon.apply_central_impulse(to_target * .1)  # Adjust multiplier as needed

func _physics_process(_delta: float) -> void:
	moon_move_static(_delta)
