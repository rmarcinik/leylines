class_name Tunnel extends Node3D

const _field_scene = preload("res://scenes/field.tscn")
const _atom_scene  = preload("res://scenes/atom.tscn")

@export var field_radius: float = 6.0
@export var force: float = 30.0
@export var pull: float = -15.0
@export var ring_count: int = 4
@export var ring_radius: float = 2.0
@export var ring_pull: float = 40.0
@export var focal_lead: float = 1

func build(points: Array[Vector3]) -> void:
	var sampled := _resample(points)
	for i in sampled.size():
		var tangent := _tangent_at(sampled, i)
		_place_field(sampled[i], tangent)
		_place_ring(sampled[i], tangent)

# Walk path segments and emit points at field_radius * 1.5 intervals,
# guaranteeing adjacent field spheres always overlap.
func _resample(points: Array[Vector3]) -> Array[Vector3]:
	if points.size() < 2:
		return points
	var step := field_radius * 1.5
	var result: Array[Vector3] = [points[0]]
	var carry := step
	for i in range(1, points.size()):
		var seg := points[i] - points[i - 1]
		var seglen := seg.length()
		if seglen == 0.0:
			continue
		var dir := seg / seglen
		while carry <= seglen:
			result.append(points[i - 1] + dir * carry)
			carry += step
		carry -= seglen
	return result

func _tangent_at(points: Array[Vector3], i: int) -> Vector3:
	if points.size() == 1:
		return Vector3.FORWARD
	if i == 0:
		return (points[1] - points[0]).normalized()
	if i == points.size() - 1:
		return (points[-1] - points[-2]).normalized()
	return ((points[i] - points[i - 1]) + (points[i + 1] - points[i])).normalized()

func _perpendicular_basis(tangent: Vector3) -> Array[Vector3]:
	var ref := Vector3.UP if abs(tangent.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT
	var a := tangent.cross(ref).normalized()
	var b := tangent.cross(a).normalized()
	return [a, b]

func _place_field(pos: Vector3, direction: Vector3) -> void:
	var field: Field = _field_scene.instantiate()
	add_child(field)
	field.setup(pos, field_radius)

	var atom: Atom = _atom_scene.instantiate()
	atom.linear = direction * force
	field.add_child(atom)

	var center: Atom = _atom_scene.instantiate()
	center.focal = pull
	center.position = direction * focal_lead
	field.add_child(center)

# Place ring_count fields in a circle of ring_radius around pos.
# Each field's focal atom sits at the path center, pulling the player toward it.
func _place_ring(pos: Vector3, tangent: Vector3) -> void:
	var ring_basis := _perpendicular_basis(tangent)
	var a := ring_basis[0]
	var b := ring_basis[1]
	for i in ring_count:
		var angle := TAU * i / ring_count
		var offset := (a * cos(angle) + b * sin(angle)) * ring_radius
		var field: Field = _field_scene.instantiate()
		add_child(field)
		field.setup(pos + offset, field_radius)
		var atom: Atom = _atom_scene.instantiate()
		atom.focal = ring_pull
		atom.position = -offset  # place atom at path center in field-local space
		field.add_child(atom)
