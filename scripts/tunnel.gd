class_name Tunnel extends Node3D

const _field_scene = preload("res://scenes/field.tscn")
const _atom_scene  = preload("res://scenes/atom.tscn")

@export var field_radius: float = 6.0
@export var force: float = 30.0

func build(points: Array[Vector3]) -> void:
	for i in points.size():
		_place_field(points[i], _tangent_at(points, i))

func _tangent_at(points: Array[Vector3], i: int) -> Vector3:
	if points.size() == 1:
		return Vector3.FORWARD
	if i == 0:
		return (points[1] - points[0]).normalized()
	if i == points.size() - 1:
		return (points[-1] - points[-2]).normalized()
	# average of incoming and outgoing segments for smooth joints
	return ((points[i] - points[i - 1]) + (points[i + 1] - points[i])).normalized()

func _place_field(pos: Vector3, direction: Vector3) -> void:
	var field: Node3D = _field_scene.instantiate()
	field.default_radius = field_radius
	add_child(field)
	field.global_position = pos

	var atom: Atom = _atom_scene.instantiate()
	atom.linear = direction * force
	field.add_child(atom)
