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
		_set_radial_gravity(_orient_radial)
	elif _orient_linear != Vector3.ZERO:
		_set_linear_gravity(_orient_linear)
	else:
		_clear_gravity()

func _set_radial_gravity(strength: float) -> void:
	field_area.gravity_space_override = Area3D.SPACE_OVERRIDE_REPLACE
	field_area.gravity_point = true
	field_area.gravity_point_center = Vector3.ZERO
	field_area.gravity_point_unit_distance = 0.0
	field_area.gravity = -strength

func _set_linear_gravity(direction: Vector3) -> void:
	field_area.gravity_space_override = Area3D.SPACE_OVERRIDE_REPLACE
	field_area.gravity_point = false
	field_area.gravity_direction = direction.normalized()
	field_area.gravity = direction.length()

func _clear_gravity() -> void:
	field_area.gravity_space_override = Area3D.SPACE_OVERRIDE_DISABLED

func _is_force_idle() -> bool:
	return _linear == Vector3.ZERO and _radial == 0.0 and _focal.is_empty()

func _compute_force_on(body: RigidBody3D) -> Vector3:
	var radial_dir := (body.global_position - global_position).normalized()
	var force: Vector3 = (_linear + radial_dir * _radial) * body.mass
	for atom in _focal:
		force += (atom.global_position - body.global_position).normalized() * atom.focal * body.mass
	return force

func _physics_process(_delta: float) -> void:
	if _orient_dirty:
		_configure_area_gravity()
		_orient_dirty = false
	if _is_force_idle():
		return
	for body in field_area.get_overlapping_bodies():
		if body is RigidBody3D:
			body.apply_central_force(_compute_force_on(body))
