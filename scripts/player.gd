extends RigidBody3D

@onready var _camera_pivot: Node3D = $CameraPivot
@onready var _camera_arm: SpringArm3D = $CameraPivot/CameraArm
@onready var _camera: Camera3D = $CameraPivot/CameraArm/Camera3D
@onready var _raycast: RayCast3D = $Downward
#@onready var _frontraycast: RayCast3D = $Forward

@export var mouse_sens := 0.01
@export var y_mouse_sens := 0.1
@export var speed := 4000.0
@export var jump_strength := 600.0
@export var local_gravity := Vector3.DOWN
@export var ground_acceleration := 20.0
@export var air_acceleration := 10.0
@export var ground_friction := 1.0
@export var air_friction := 1.1

var _move_direction = Vector3.ZERO
var _last_strong_direction = Vector3.FORWARD
var mouseMotion_x :float
var mouseMotion_y :float
var _current_velocity := Vector3.ZERO
var _target_velocity := Vector3.ZERO

signal send_preview(position)
signal action_tower()

func _ready() -> void:
	add_to_group('Player')
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()

	if(event is InputEventMouseMotion):
		mouseMotion_x = event.relative.x
		mouseMotion_y = event.relative.y
		# look right and left
		_camera_pivot.rotate_y(-mouseMotion_x * mouse_sens)
		# look up an down
		_camera_arm.rotate_x(-mouseMotion_y * mouse_sens * y_mouse_sens)
		_camera_arm.rotation.x = clamp(_camera_arm.rotation.x, -PI/4, PI/4)

func is_grounded() -> bool:
	return _raycast.is_colliding()
func is_jumping() -> bool:
	return Input.is_action_pressed("jump")
func is_falling() -> bool:
	return Input.is_action_pressed("fall")

func get_gravity_direction(state) -> Vector3:
	return state.total_gravity.normalized()

func _integrate_forces(state) -> void:
	## Orient Player
	local_gravity = get_gravity_direction(state)
	_move_direction = _get_model_oriented_input()
	_last_strong_direction = _camera_pivot.global_basis.z
	basis = _orient_character_to_direction(_last_strong_direction, local_gravity, state.step)

	## Move Player
	# Calculate target velocity
	_target_velocity = _move_direction * speed

	# Apply acceleration and friction
	var accel = ground_acceleration if is_grounded() else air_acceleration
	var friction = ground_friction if is_grounded() else air_friction

	_current_velocity = _current_velocity.lerp(_target_velocity, state.step * accel)
	_current_velocity *= friction

	# Apply movement force
	apply_central_force(_current_velocity)

	# Handle jumping/falling
	if is_jumping():
		apply_central_impulse(-local_gravity * jump_strength)
	if is_falling():
		apply_central_impulse(local_gravity * jump_strength)

func _get_model_oriented_input() -> Vector3:
	var raw_input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if raw_input == Vector2.ZERO:
		return Vector3.ZERO

	var input = Vector3.ZERO
	# Normalize input for consistent movement speed in all directions
	input.x = raw_input.x
	input.z = raw_input.y

	return basis * input.normalized()

func _orient_character_to_direction(direction: Vector3, gravity: Vector3, delta: float):
	var left_axis := -gravity.cross(direction)
	var rotation_basis := Basis(left_axis, -gravity, direction).orthonormalized()
	# get rotation quaternion is finding how to change the basis to fit the direction of gravity, and player input
	# spherical linear interpolation tries to make a smooth movement
	return basis.get_rotation_quaternion().slerp(rotation_basis.get_rotation_quaternion(), delta * 10)

func get_mouse_preview() -> Vector3:
	var space_state = get_world_3d().get_direct_space_state()
	var params = PhysicsRayQueryParameters3D.new()
	var mouse_pos = get_viewport().get_mouse_position()
	params.from = _camera.project_ray_origin(mouse_pos)
	# distance that player can place object: 100
	params.to = params.from + _camera.project_ray_normal(mouse_pos) * 100
	var rid_array : Array[RID]
	rid_array.append(get_rid())
	params.exclude = rid_array
	var result = space_state.intersect_ray(params)
	if result.is_empty():
		return params.to
	else:
		return result.position

func _process(_delta: float) -> void:
	_camera_pivot.global_basis = $Head.global_basis
	# move the tower preview to wherever the mouse is looking at a surface
	$Tower.global_transform.origin = get_mouse_preview()
	# setting the tower basis to rotate with the player
	$Tower.global_transform.basis = transform.basis
	$Tower.global_transform.basis.z = -global_transform.basis.z
	if Input.is_action_just_pressed("Inventory1"):
		$Tower.toggle_visible()
	if Input.is_action_just_pressed("leftclick") and $Tower.visible:
		send_preview.emit($Tower.global_transform)
	if Input.is_action_just_pressed("rightclick"):
		action_tower.emit()
