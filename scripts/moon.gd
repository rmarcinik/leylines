class_name Moon extends RigidBody3D

@export var mesh_radius: float = 25
@export var mesh_col_radius: float

@export var area_radius: float
@export var area_col_radius: float

func _ready() -> void:
	$MeshInstance3D.mesh.set_radius(mesh_radius)
	pass
