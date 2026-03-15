class_name Atom extends Node3D

@export var linear: Vector3 = Vector3.ZERO  # fixed directional force
@export var radial: float = 0.0             # positive = push, negative = pull

func _ready() -> void:
	if get_parent().get_name() == "Player":
		toggle_visible()

func toggle_visible() -> void:
	visible = not visible
