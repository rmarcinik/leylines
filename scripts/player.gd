extends RigidBody3D

@export var mouse_sens := 0.002
@export var speed := 4000.0
@export var jump_strength := 500.0
@export var local_gravity := Vector3.DOWN
var _move_direction = Vector3.ZERO
var _last_strong_direction = Vector3.FORWARD

var mouseMotion_x :float
var mouseMotion_y :float
var rot_vec: Vector3
var v_rot: Vector3
var h_rot: Vector3

signal send_preview(position)
signal action_tower()

@onready var _camera_pivot: Node3D = $CameraPivot
@onready var _camera_arm: SpringArm3D = $CameraPivot/CameraArm
@onready var _camera: Camera3D = $CameraPivot/CameraArm/Camera3D
@onready var _raycast: RayCast3D = $Downward
@onready var _frontraycast: RayCast3D = $Forward

func _ready() -> void:
	add_to_group('Player')
	$Timer.connect("timeout",Callable(self,"_on_Timer_timeout"))
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
		
	if(event is InputEventMouseMotion):
		_camera_pivot.rotate_y(-event.relative.x * mouse_sens)
		_camera_arm.rotate_x(-event.relative.y * mouse_sens)
		_camera_arm.rotation.x = clamp(_camera_arm.rotation.x, -PI/4, PI/4)
		mouseMotion_x = event.relative.x
		mouseMotion_y = event.relative.y

func _on_Timer_timeout():
	print('''
	camera arm basis
	%s 
	player basis
	%s
	player front basis
	%s
	''' % [_camera_arm.basis, transform.basis, _frontraycast.basis])

func floored() -> bool:
	return _raycast.is_colliding()

func _integrate_forces(state) -> void:

	# Get direction of gravity
	local_gravity = state.total_gravity.normalized()
	
	# stop player from falling down
	state.angular_velocity = Vector3.ZERO

	# orient player to the camera direction
	_last_strong_direction = _camera_arm.basis.z
	_orient_character_to_direction(_last_strong_direction, state.step)
	
	_move_direction = _get_model_oriented_input()

	if is_jumping():
		#print('applying force when jumping')
		apply_central_impulse(-local_gravity * jump_strength)
	if floored():
		#print('applying force when on the ground')
		apply_central_force(_move_direction * speed)
	else:
		#print('applying force when in the air')
		apply_central_force(_move_direction * speed)

func _get_model_oriented_input() -> Vector3:
	var raw_input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var input = Vector3.ZERO
	input.x = raw_input.x * sqrt(1.0 - raw_input.y * raw_input.y / 2.0)
	input.z = raw_input.y * sqrt(1.0 - raw_input.x * raw_input.x / 2.0)
	return  basis * input #_move_direction

func _orient_character_to_direction(direction: Vector3, delta: float) -> void:
	var left_axis := -local_gravity.cross(direction)
	var rotation_basis := Basis(left_axis, -local_gravity, direction).orthonormalized()
	# get rotation quaternion is finding how to change the basis to fit the direction of gravity, and player input
	# spherical linear interpolation tries to make a smooth movement
	global_basis = basis.get_rotation_quaternion().slerp(rotation_basis.get_rotation_quaternion(), delta * 10)

func is_jumping():
	return Input.is_action_pressed("jump")

func get_mouse_preview() -> Vector3:
	var space_state = get_world_3d().get_direct_space_state()
	var params = PhysicsRayQueryParameters3D.new()
	var mouse_pos = get_viewport().get_mouse_position()
	params.from = _camera.project_ray_origin(mouse_pos)
	# distance that player can place object: 100
	params.to = params.from + _camera.project_ray_normal(mouse_pos) * 100
	var result = space_state.intersect_ray(params)
	if result.is_empty():
		return params.to
	else:
		return result.position


func _process(_delta: float) -> void:
	# move the tower preview to wherever the mouse is looking at a surface
	$Tower.global_transform.origin = get_mouse_preview()
	# setting the tower basis to rotate with the player, but its facing towards, still needs work
	$Tower.global_transform.basis = transform.basis
	if Input.is_action_just_pressed("Inventory1"):
		$Tower.toggle_visible()
	if Input.is_action_just_pressed("leftclick") and $Tower.visible:
		send_preview.emit($Tower.global_transform)
	if Input.is_action_just_pressed("rightclick"):
		action_tower.emit()
