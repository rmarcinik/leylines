extends Node3D

@onready var _land = preload("res://scenes/land.tscn")
@onready var _tower = preload("res://scenes/tower.tscn")
@onready var _portal = preload("res://scenes/portal.tscn")
@onready var _moon = preload("res://scenes/moon.tscn")
@onready var _pillar = $Blocks/Foundation2/Pillar

func _ready() -> void:
	make_grid()
	make_portal()
	move_moon()
	$Player.send_preview.connect(place_tower)
	var node = _tower.instantiate()
	$Player.add_child(node)

func place_node(node, globaltransform: Transform3D):
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
	var node = _portal.instantiate()
	add_child(node, true)
	node.get_node('Enter').global_position = Vector3(40, 0, 0)
	node.get_node('Exit').global_position = Vector3(190, 180, 101)

	var farnode = _portal.instantiate()
	add_child(farnode, true)
	farnode.get_node('Enter').global_position = Vector3(-40, 0, 0)
	farnode.get_node('Exit').global_position = Vector3(0, 180, 2700)

func move_moon() -> void:
	var moon = _moon.instantiate()
	_pillar.add_child(moon, true)
	moon.global_position = Vector3(-60,20,80)
	moon.freeze = true

func moon_move():
	var moon = _pillar.get_child(0)
	moon.freeze = false
	var moon_y = moon.global_transform.origin.y
	var pillar_origin = _pillar.global_transform.origin
	var pillar_height = _pillar.height
	var base_position = pillar_origin.y - pillar_height / 2
	var top_position = base_position + pillar_height
	if moon_y < base_position + 50:
		moon.apply_central_impulse(Vector3.UP * 200000)
	if moon_y > top_position:
		moon.apply_central_impulse(Vector3.DOWN * 200000)

func _physics_process(_delta: float) -> void:
	moon_move()
