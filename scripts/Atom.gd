class_name Atom extends Node3D

@export var linear: Vector3 = Vector3.ZERO  # fixed directional force
@export var radial: float = 0.0             # positive = push, negative = pull
var is_held := false

func _ready() -> void:
	if get_parent() is Player:
		is_held = true
		visible = not visible
