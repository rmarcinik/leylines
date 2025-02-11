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
	node.get_node('Enter').global_position = Vector3(40, 4, 0)
	node.get_node('Exit').get_node('EnterView').get_node('EnterCam').global_position = Vector3(190, 180, 101)
	node.get_node('Exit').global_position = Vector3(190, 180, 101)
	node.get_node('Enter').get_node('ExitView').get_node('ExitCam').global_position = Vector3(40, 4, 0)

	var farnode = place_node(_portal)
	farnode.get_node('Enter').global_position = Vector3(-40, 0, 0)
	farnode.get_node('Exit').global_position = Vector3(0, 180, 2700)

func move_moon() -> void:
	var moon = _moon.instantiate()
	_path_follower.add_child(moon, true)
	moon.global_position = Vector3(210,20,-200)

func moon_move_static(delta):
	#var moon = _path_3d.get_child(0)
	time+=delta
	_path_follower.progress += (sin(time * 1) * 1)
	#var target_position = Vector3.UP * (sin(time * .7) * 4)
	#moon.position = moon.position + target_position
	print(_path_follower.progress)

func _physics_process(_delta: float) -> void:
	moon_move_static(_delta)
