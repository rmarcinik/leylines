class_name Moon extends RigidBody3D

@export var mesh_radius: float = 25
@export var mesh_col_radius: float

@onready var _mesh = $MeshInstance3D.mesh


func _ready() -> void:
	freeze = true
	add_sphere()
	#add_timer()
	set_gravity_to_center()
	
func add_sphere() -> void:
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = mesh_radius
	sphere_mesh.height = mesh_radius * 2
	sphere_mesh.material = preload("res://asset/crater.tres")
	_mesh = sphere_mesh
	
func add_timer() -> void:
	var timer = Timer.new()
	timer.wait_time = 10
	timer.autostart = true
	timer.timeout.connect(rotate_gravity)
	add_child(timer)
	
func set_gravity_to_center() -> void:
	var area := get_node("Area3D")
	if not area is Area3D:
		return
	area.gravity_space_override = Area3D.SPACE_OVERRIDE_REPLACE
	area.gravity_point        = true
	area.gravity_point_center = Vector3.ZERO

# Function to rotate the moon's gravity direction by a given angle (in radians)
func rotate_gravity() -> void:
	var area = get_node("Area3D")  # Assuming the last child is the Area3D
	if area is Area3D:
		var current_gravity = area.gravity_direction  # Get the current gravity direction
		
		var rotation_axis = Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
		var angle = randf_range(0, TAU) # TAU is 2*PI, a full circle in radians
		var new_gravity = current_gravity + rotation_axis * angle
		area.gravity_direction = new_gravity
		#print("OLD GRAVITY", current_gravity, "NEW GRAVITY", new_gravity)

	
