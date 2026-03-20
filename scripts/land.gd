extends Node3D

var _held := false

func _ready() -> void:
	if get_parent() is Player:
		_held = true
		visible = false
		$Land.freeze = true
		$Land.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
		return
	var area  := Area3D.new()
	var shape := CollisionShape3D.new()
	var box   := BoxShape3D.new()
	box.size  = Vector3(8, 1, 8)
	shape.shape = box
	area.add_child(shape)
	add_child(area)
	area.area_entered.connect(_on_area_entered)
	area.area_exited.connect(_on_area_exited)

func _process(_delta: float) -> void:
	if _held:
		$Land.global_transform = global_transform

func _on_area_entered(area: Area3D) -> void:
	var player := area.get_parent().get_parent() as Player
	if player and not player.item_action.is_connected(queue_free):
		player.item_action.connect(queue_free)

func _on_area_exited(area: Area3D) -> void:
	var player := area.get_parent().get_parent() as Player
	if player and player.item_action.is_connected(queue_free):
		player.item_action.disconnect(queue_free)
