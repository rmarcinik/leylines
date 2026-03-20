class_name Field extends Node3D

@onready var field_area: Area3D = $area_3d
@onready var field_collision_shape: CollisionShape3D = $area_3d/collision_shape_3d

@export var default_radius := 10.0

func _ready() -> void:
	field_collision_shape.shape = field_collision_shape.shape
	field_collision_shape.shape.radius = default_radius

func setup(pos: Vector3, radius: float = default_radius) -> void:
	global_position = pos
	field_collision_shape.shape.radius = radius

func _sum_influence() -> Dictionary:
	var linear := Vector3.ZERO
	var radial := 0.0
	var focal: Array[Atom] = []
	var orient_linear := Vector3.ZERO
	var orient_radial := 0.0
	for area in field_area.get_overlapping_areas():
		var atom := area.get_parent() as Atom
		if atom and not atom.is_held and not _in_inner_field(area):
			if atom.orient:
				orient_linear += atom.linear
				orient_radial += atom.radial
			else:
				linear += atom.linear
				radial += atom.radial
				if atom.focal != 0.0:
					focal.append(atom)
	return {linear = linear, radial = radial, focal = focal, orient_linear = orient_linear, orient_radial = orient_radial}

func _in_inner_field(atom_area: Area3D) -> bool:
	for area in atom_area.get_overlapping_areas():
		var field := area.get_parent() as Field
		if field and field != self and field.default_radius < default_radius:
			return true
	return false

func _configure_area_gravity(orient_linear: Vector3, orient_radial: float) -> void:
	if orient_radial != 0.0:
		field_area.gravity_space_override = Area3D.SPACE_OVERRIDE_REPLACE
		field_area.gravity_point = true
		field_area.gravity_point_center = Vector3.ZERO
		field_area.gravity_point_unit_distance = 0.0
		field_area.gravity = -orient_radial  # atom radial < 0 = pull; Godot point gravity > 0 = pull
	elif orient_linear != Vector3.ZERO:
		field_area.gravity_space_override = Area3D.SPACE_OVERRIDE_REPLACE
		field_area.gravity_point = false
		field_area.gravity_direction = orient_linear.normalized()
		field_area.gravity = orient_linear.length()
	else:
		field_area.gravity_space_override = Area3D.SPACE_OVERRIDE_DISABLED

func _force_for(body: RigidBody3D, influence: Dictionary) -> Vector3:
	var radial_dir := (body.global_position - global_position).normalized()
	var force = (influence.linear + radial_dir * influence.radial) * body.mass
	for atom: Atom in influence.focal:
		force += (atom.global_position - body.global_position).normalized() * atom.focal * body.mass
	return force

func _physics_process(_delta: float) -> void:
	var influence := _sum_influence()
	_configure_area_gravity(influence.orient_linear, influence.orient_radial)
	for body in field_area.get_overlapping_bodies():
		if body is RigidBody3D:
			body.apply_central_force(_force_for(body, influence))
