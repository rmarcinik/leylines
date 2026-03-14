extends Node3D


@onready var field_area: Area3D = $area_3d
@onready var field_collision_shape: CollisionShape3D = $area_3d/collision_shape_3d

@export var default_radius := 10.0
@export var default_field_vector := Vector3.DOWN

var apply: bool = false
var target_body: Node3D
@export var default_mag := 10

var overlapping_bodies: Array[RigidBody3D] = []

func _ready() -> void:
	modify_radius(default_radius)
	modify_gravity_vector(default_field_vector)

	field_area.body_entered.connect(_on_body_entered)
	field_area.body_exited.connect(_on_body_exited)
	
func modify_radius(rad: float) -> void:
	default_radius = rad
	field_collision_shape.shape.radius = rad

func modify_damp(damp: float) -> void:
	field_area.linear_damp = damp

func modify_gravity_vector(vector: Vector3) -> void:
	field_area.gravity_space_override = Area3D.SPACE_OVERRIDE_COMBINE
	field_area.gravity_direction = vector

func append_body(body: RigidBody3D):
	overlapping_bodies.append(body)

func _on_body_entered(body: Node3D) -> void:
	if body is RigidBody3D:
		append_body(body)

func _on_body_exited(body: Node3D) -> void:
	if body is RigidBody3D and body in overlapping_bodies:
		overlapping_bodies.erase(body)
		
func push_force(body, mag):
	var new_mag = max(body.linear_velocity.length(), mag)
	var direction = body.position - position
	body.apply_central_impulse(direction * new_mag)


func pull_force(body, mag):
	var new_mag = max(body.linear_velocity.length(), mag)
	var direction = position - body.position
	body.apply_central_impulse(direction * new_mag)	

func _physics_process(delta: float) -> void:
	for body in overlapping_bodies:
		push_force(body, default_mag)
