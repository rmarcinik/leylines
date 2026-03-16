extends Node3D

@onready var field_area: Area3D = $area_3d
@onready var field_collision_shape: CollisionShape3D = $area_3d/collision_shape_3d

@export var default_radius := 10.0

func _ready() -> void:
	field_collision_shape.shape = field_collision_shape.shape
	field_collision_shape.shape.radius = default_radius

func _sum_influence() -> Dictionary:
	var linear := Vector3.ZERO
	var radial := 0.0
	for area in field_area.get_overlapping_areas():
		var atom := area.get_parent() as Atom
		if atom and not atom.is_held:
			linear += atom.linear
			radial += atom.radial
	return {linear = linear, radial = radial}

func _force_for(body: RigidBody3D, influence: Dictionary) -> Vector3:
	var radial_dir := (body.global_position - global_position).normalized()
	return (influence.linear + radial_dir * influence.radial) * body.mass

func _physics_process(_delta: float) -> void:
	var influence := _sum_influence()
	for body in field_area.get_overlapping_bodies():
		if body is RigidBody3D:
			body.apply_central_force(_force_for(body, influence))
