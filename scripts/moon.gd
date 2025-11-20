class_name Moon extends RigidBody3D

@export var mesh_radius: float = 25

@export var mesh_col_radius: float

@export var area_radius: float = 50
@export var area_col_radius: float

#@onready var _mesh = $MeshInstance3D.mesh.duplicate()
#@onready var _mesh_col = $CollisionShape3D
#@onready var _area = $Area3D
#@onready var _area_col = $Area3D/CollisionShape3D



func _ready() -> void:
	#var sphere = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = mesh_radius
	sphere_mesh.height = mesh_radius * 2
	sphere_mesh.material = preload("res://asset/crater.tres")
	$MeshInstance3D.mesh = sphere_mesh

	#add_area_with_sphere_shape(Vector3.ZERO, area_radius)
	freeze = true
	var timer = Timer.new()
	timer.wait_time = 10
	timer.autostart = true
	timer.timeout.connect(rotate_gravity)
	add_child(timer)


	pass



# Function to add a new Area3D with a CollisionShape3D of SphereShape3D
func add_area_with_sphere_shape(pos: Vector3, radius: float) -> void:
	var area = Area3D.new()
	var collision_shape = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()

	sphere_shape.radius = radius  # Set the radius of the sphere shape
	collision_shape.shape = sphere_shape  # Assign the sphere shape to the collision shape
	area.add_child(collision_shape)  # Add the collision shape to the area
	area.position = pos  # Set the position of the area
	area.gravity_space_override = Area3D.SPACE_OVERRIDE_REPLACE
	area.gravity_point = true
	area.gravity_point_unit_distance = 50
	area.linear_damp_space_override = Area3D.SPACE_OVERRIDE_REPLACE
	area.linear_damp = 10
	
	add_child(area)  # Add the area to the parent node


# Function to rotate the moon's gravity direction by a given angle (in radians)
func rotate_gravity() -> void:
	var area = get_node("Area3D")  # Assuming the last child is the Area3D
	if area is Area3D:
		var current_gravity = area.gravity_direction  # Get the current gravity direction
		
		var rotation_axis = Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
		var angle = randf_range(0, TAU) # TAU is 2*PI, a full circle in radians
		var new_gravity = current_gravity + rotation_axis * angle
		area.gravity_direction = new_gravity
		print("OLD GRAVITY", current_gravity, "NEW GRAVITY", new_gravity)

	
