class_name Moon extends RigidBody3D

@export var mesh_radius: float = 25
@export var mesh_col_radius: float

@onready var _mesh: MeshInstance3D = $MeshInstance3D


func _ready() -> void:
	freeze = true
	add_sphere()

func add_sphere() -> void:
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = mesh_radius
	sphere_mesh.height = mesh_radius * 2
	sphere_mesh.material = preload("res://asset/crater.tres")
	_mesh.mesh = sphere_mesh
	
	
