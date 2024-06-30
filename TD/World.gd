extends Node3D

var land = preload("res://TD/Land.tscn")
var tower = preload("res://TD/Tower.tscn")

func _ready() -> void:
	make_grid()
	$Player.connect("send_preview",Callable(self,"place_tower"))
	var node = tower.instantiate()
	$Player.add_child(node)
	
func place_tower(preview):
	var node = tower.instantiate()
	add_child(node, true)
	node.global_transform = preview
	$Player.connect("action_tower",Callable(node,"action_tower"))
	
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
