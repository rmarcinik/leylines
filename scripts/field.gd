class_name Field extends Node3D

@onready var field_area: Area3D = $area_3d
@onready var field_collision_shape: CollisionShape3D = $area_3d/collision_shape_3d

@export var default_radius := 10.0

var _linear := Vector3.ZERO
var _radial := 0.0
var _orient_linear := Vector3.ZERO
var _orient_radial := 0.0
var _focal: Array[Atom] = []
var _orient_dirty := false

func _ready() -> void:
	field_collision_shape.shape = field_collision_shape.shape
	field_collision_shape.shape.radius = default_radius
	_orient_dirty = true

func setup(pos: Vector3, radius: float = default_radius) -> void:
	global_position = pos
	field_collision_shape.shape.radius = radius

func add_atom(atom: Atom) -> void:
	if atom.orient:
		_orient_linear += atom.linear
		_orient_radial += atom.radial
		_orient_dirty = true
	else:
		_linear += atom.linear
		_radial += atom.radial
		if atom.focal != 0.0:
			_focal.append(atom)

func remove_atom(atom: Atom) -> void:
	if atom.orient:
		_orient_linear -= atom.linear
		_orient_radial -= atom.radial
		_orient_dirty = true
	else:
		_linear -= atom.linear
		_radial -= atom.radial
		_focal.erase(atom)

func _configure_area_gravity() -> void:
	if _orient_radial != 0.0:
		field_area.gravity_space_override = Area3D.SPACE_OVERRIDE_REPLACE
		field_area.gravity_point = true
		field_area.gravity_point_center = Vector3.ZERO
		field_area.gravity_point_unit_distance = 0.0
		field_area.gravity = -_orient_radial
	elif _orient_linear != Vector3.ZERO:
		field_area.gravity_space_override = Area3D.SPACE_OVERRIDE_REPLACE
		field_area.gravity_point = false
		field_area.gravity_direction = _orient_linear.normalized()
		field_area.gravity = _orient_linear.length()
	else:
		field_area.gravity_space_override = Area3D.SPACE_OVERRIDE_DISABLED

func _physics_process(_delta: float) -> void:
	if _orient_dirty:
		_configure_area_gravity()
		_orient_dirty = false
	if _linear == Vector3.ZERO and _radial == 0.0 and _focal.is_empty():
		return
	for body in field_area.get_overlapping_bodies():
		if body is RigidBody3D:
			var radial_dir := (body.global_position - global_position).normalized()
			var force: Vector3 = (_linear + radial_dir * _radial) * body.mass
			for atom in _focal:
				force += (atom.global_position - body.global_position).normalized() * atom.focal * body.mass
			body.apply_central_force(force)
