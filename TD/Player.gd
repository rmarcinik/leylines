extends RigidBody3D

@export var speed := 400.0
@export var jump_strength := 400.0
@export var gravity := 10.0
@export var local_gravity := Vector3.DOWN
var _move_direction = Vector3.ZERO
var _last_strong_direction = Vector3.FORWARD

signal send_preview(position)
signal action_tower()

var _velocity := Vector3.ZERO
var _snap_vector := Vector3.DOWN

@onready var _spring_arm: SpringArm3D = $CameraArm
@onready var _raycast: RayCast3D = $RayCast3D

func _ready() -> void:
	$Timer.connect("timeout",Callable(self,"_on_Timer_timeout"))

func _on_Timer_timeout():
	print(get_input())
	print(_move_direction)
	
func get_input() -> Vector3:
	var move_direction := Vector3.ZERO
	move_direction.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	move_direction.z = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	move_direction = move_direction.rotated(Vector3.UP, _spring_arm.rotation.y).normalized()	
	return move_direction

func floored() -> bool:
	return _raycast.is_colliding()

func _integrate_forces(state) -> void:
	# Get direction of gravity
	local_gravity = state.total_gravity.normalized()
	
	_move_direction = _get_model_oriented_input()
	_orient_character_to_direction(_last_strong_direction, state.step)
	
	if is_jumping(state):
		print('applying force when jumping')
		apply_central_impulse(-local_gravity * jump_strength)
	if floored():
		print('applying force when on the ground')
		apply_central_force(_move_direction * speed)

func _get_model_oriented_input() -> Vector3:
	var raw_input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var input = Vector3.ZERO
	
	input.x = raw_input.x * sqrt(1.0 - raw_input.y * raw_input.y / 2.0)
	input.z = raw_input.y * sqrt(1.0 - raw_input.x * raw_input.x / 2.0)
	_move_direction = basis * input
	return  _move_direction

func _orient_character_to_direction(direction: Vector3, delta: float) -> void:
	var left_axis := -local_gravity.cross(direction)
	var rotation_basis := Basis(left_axis, -local_gravity, direction).orthonormalized()
	basis = basis.get_rotation_quaternion().slerp(rotation_basis.get_rotation_quaternion(), delta * 50)

func is_on_floor(state) -> bool:
	for contact in state.get_contact_count():
		var contact_normal = state.get_contact_local_normal(contact)
		if contact_normal.dot(-local_gravity) > 0.5:
			return true
	return false

func is_jumping(state):
	return Input.is_action_just_pressed("jump")
	
#func _physics_process(delta: float) -> void:
	#var move_direction := get_input()
	#
	##_velocity.x = move_direction.x * speed
	##_velocity.z = move_direction.z * speed
	#_velocity.y -= 6*gravity * delta
	#
	#var just_landed := floored() and _snap_vector == Vector3.ZERO
	#var is_jumping := Input.is_action_just_pressed("jump") # and floored() 
	#var in_air := not floored()
	#
	## if the player is the the air reduce their input strength, and reduce velocity
	#if in_air:
		#_velocity.x = move_direction.x * speed #/ 2
		#_velocity.z = move_direction.z * speed #/ 2
	#else:
		#_velocity.x = move_direction.x * speed
		#_velocity.z = move_direction.z * speed
	#if is_jumping:
		#_velocity.y = jump_strength
		#_snap_vector = Vector3.ZERO
	#elif just_landed:
		#_snap_vector =  Vector3.DOWN
	#
	## rotation is in radians so to get the opposite side of the spring arm, subtract pi
	#rotation.y = _spring_arm.rotation.y - PI
	## weird effect
	##self.global_transform.basis.z = $CameraArm/Camera3D.global_transform.basis.z
		#
	## gdscript doesnt have named parameters and we need to set the last param to false
	## max_slides and floor_max_angle need to be added (4 and PI/4), so that infinite_inertia can be set to false
	##apply_central_impulse(_velocity)
	##set_velocity(_velocity)
	## TODOConverter40 looks that snap in Godot 4.0 is float, not vector like in Godot 3 - previous value `_snap_vector`
	##set_up_direction(Vector3.UP)
	##set_floor_stop_on_slope_enabled(true)
	##set_max_slides(4)
	## set the denominator of floor max angle lower to stick to walls
	## PI/3 is a good balance to climb steep slopes but not vertical walls
	##set_floor_max_angle(PI/3)
	## TODOConverter40 infinite_inertia were removed in Godot 4.0 - previous value `false`
	##move_and_slide()
	##_velocity = velocity
	
func get_mouse_preview():
	var space_state = get_world_3d().get_direct_space_state()
	var params = PhysicsRayQueryParameters3D.new()
	var mouse_pos = get_viewport().get_mouse_position()
	params.from = $CameraArm/Camera3D.project_ray_origin(mouse_pos)
	params.to = params.from + $CameraArm/Camera3D.project_ray_normal(mouse_pos) * 1000
	var result = space_state.intersect_ray(params)
	if result.is_empty():
		return params.to
	else:
		return result.position

func _process(_delta: float) -> void:
	# move the tower preview to wherever the mouse is looking at a surface
	_spring_arm.position = position + Vector3(0,8,0)
	$Tower.global_transform.origin = get_mouse_preview()
	if Input.is_action_just_pressed("leftclick"):
		emit_signal('send_preview', $Tower.global_transform)
	if Input.is_action_just_pressed("rightclick"):
		emit_signal('action_tower')
