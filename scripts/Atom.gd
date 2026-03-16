class_name Atom extends Node3D

@export var linear: Vector3 = Vector3.ZERO  # fixed directional force
@export var radial: float = 0.0             # positive = push, negative = pull
var is_held := false

@onready var _area: Area3D = $area_3d

func _ready() -> void:
	if get_parent() is Player:
		is_held = true
		visible = false
	else:
		_area.area_entered.connect(_on_area_entered)
		_area.area_exited.connect(_on_area_exited)

func _on_area_entered(area: Area3D) -> void:
	var player := area.get_parent().get_parent() as Player
	if player:
		player.item_action.connect(queue_free)

func _on_area_exited(area: Area3D) -> void:
	var player := area.get_parent().get_parent() as Player
	if player and player.item_action.is_connected(queue_free):
		player.item_action.disconnect(queue_free)
