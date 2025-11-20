extends Node3D

var apply: bool = false
var target_body: Node3D
var default_sphere_shape = SphereShape3D

@export var default_radius := 10
@export var default_mag := 100
@export var default_damp := 10

func _ready() -> void:
	add_area_with_sphere_shape(default_radius)
	#modify_radius(100)

func add_area_with_sphere_shape(radius: float, damp: float = 10) -> void:
	var area = Area3D.new()
	var collision_shape = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	
	default_sphere_shape = sphere_shape
	sphere_shape.radius = radius  # Set the radius of the sphere shape
	collision_shape.shape = sphere_shape  # Assign the sphere shape to the collision shape
	
	area.linear_damp = damp
	area.linear_damp_space_override = Area3D.SPACE_OVERRIDE_REPLACE
	
	area.add_child(collision_shape)  # Add the collision shape to the area
	add_child(area)  # Add the area to the parent node

	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func modify_radius(rad: float) -> void:
	default_radius = rad
	var n  =  get_child(0).get_child(0)
	print(n)
	n.shape.radius = rad
	#$Area3D/CollisionShape3D
	#default_sphere_shape.radius = rad


func modify_magnitude(mag: float) -> void:
	default_mag = mag



func _on_body_entered(body: Node3D) -> void:
	print(body.name)
	if body is Player:
		
		apply = true
		target_body = body

func _on_body_exited(body: Node3D) -> void:
	if body is Player:	
		body.dampen_velocity()
		apply = false
		target_body = null

func _physics_process(delta: float) -> void:
	
	if apply:
		var mag = max(target_body.linear_velocity.length(), default_mag)
		var direction = target_body.position - position
		target_body.apply_central_impulse(direction * mag)
