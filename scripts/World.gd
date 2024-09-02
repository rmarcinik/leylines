extends Node3D

@onready var land = preload("res://scenes/land.tscn")
@onready var tower = preload("res://scenes/tower.tscn")
@onready var _portal = preload("res://scenes/portal.tscn")

func _ready() -> void:
	make_grid()
	make_portal()
	$Player.connect("send_preview", place_tower)
	var node = tower.instantiate()
	$Player.add_child(node)
	
func place_tower(preview):
	var node = tower.instantiate()
	add_child(node, true)
	node.global_transform = preview
	$Player.connect("action_tower", Callable(node,"action_tower"))
	
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
			node = land.instantiate()
			node.position = Vector3(x,height,z)
			add_child(node, true)

func make_portal() -> void:
	var node = _portal.instantiate()
	add_child(node, true)
	node.get_node('Enter').global_position = Vector3(40, 0, 0)
	node.get_node('Exit').global_position = Vector3(190, 180, 101)
