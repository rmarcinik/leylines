class_name Player extends RigidBody3D

@onready var _camera_pivot: Node3D    = $CameraPivot
@onready var _camera_arm: SpringArm3D = $CameraPivot/CameraArm
@onready var _camera: Camera3D        = $CameraPivot/CameraArm/Camera3D
@onready var _raycast: RayCast3D      = $Downward

@export var mouse_sens          := 0.01
@export var y_mouse_sens        := 0.1
@export var speed               := 3000.0
@export var jump_strength       := 200.0
@export var local_gravity       := Vector3.DOWN
@export var ground_acceleration := 30.0
@export var air_acceleration    := 20.0
@export var ground_friction     := 1.1
@export var air_friction        := 0.8
@export var accel_curve: Curve

## Set false on nodes that represent remote peers — disables input, camera, and broadcasting.
var is_local: bool = true

var _move_direction       := Vector3.ZERO
var _last_strong_direction := Vector3.FORWARD
var _current_velocity     := Vector3.ZERO
var _target_velocity      := Vector3.ZERO
var mouseMotion_x: float
var mouseMotion_y: float

signal send_preview(position)
signal action_tower()

func _ready() -> void:
	if is_local:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		_camera.current = false

func _unhandled_input(event: InputEvent) -> void:
	if not is_local:
		return
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
	if event is InputEventMouseMotion:
		mouseMotion_x = event.relative.x
		mouseMotion_y = event.relative.y
		_camera_pivot.rotate_y(-mouseMotion_x * mouse_sens)
		_camera_arm.rotate_x(-mouseMotion_y * mouse_sens * y_mouse_sens)
		_camera_arm.rotation.x = clamp(_camera_arm.rotation.x, -PI / 2, PI / 2)

func is_grounded() -> bool:
	return _raycast.is_colliding()

func is_jumping() -> bool:
	return Input.is_action_pressed("jump")

func is_falling() -> bool:
	return Input.is_action_pressed("fall")

func get_gravity_direction(state) -> Vector3:
	return state.total_gravity.normalized()

func _integrate_forces(state) -> void:
	_current_velocity = linear_velocity
	local_gravity     = get_gravity_direction(state)

	if not is_local:
		return

	_move_direction        = _get_model_oriented_input()
	_last_strong_direction = _camera_pivot.global_basis.z
	basis = _orient_character_to_direction(_last_strong_direction, local_gravity, state.step)

	_target_velocity = _move_direction * speed
	var velocity_difference := (_target_velocity - _current_velocity).length()
	var curve_sample        := accel_curve.sample_baked(velocity_difference)
	var accel := ground_acceleration if is_grounded() else air_acceleration
	var friction := ground_friction if is_grounded() else air_friction

	_current_velocity *= friction
	_current_velocity = _current_velocity.lerp(_target_velocity, state.step * accel)
	apply_central_force(_current_velocity)

	if is_jumping():
		apply_central_impulse(-local_gravity * jump_strength)
	if is_falling():
		apply_central_impulse(local_gravity * jump_strength)
		dampen_velocity()

func _get_model_oriented_input() -> Vector3:
	var raw_input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if raw_input == Vector2.ZERO:
		return Vector3.ZERO
	var input := Vector3(raw_input.x, 0.0, raw_input.y)
	return basis * input.normalized()

func _orient_character_to_direction(direction: Vector3, gravity: Vector3, delta: float) -> Quaternion:
	var left_axis      := -gravity.cross(direction)
	var rotation_basis := Basis(left_axis, -gravity, direction).orthonormalized()
	return basis.get_rotation_quaternion().slerp(rotation_basis.get_rotation_quaternion(), delta * 10)

func get_mouse_preview() -> Vector3:
	var space_state := get_world_3d().get_direct_space_state()
	var params      := PhysicsRayQueryParameters3D.new()
	var mouse_pos   := get_viewport().get_mouse_position()
	params.from     = _camera.project_ray_origin(mouse_pos)
	params.to       = params.from + _camera.project_ray_normal(mouse_pos) * 100
	params.exclude  = [get_rid()]
	var result      := space_state.intersect_ray(params)
	return result.position if not result.is_empty() else params.to

func _process(_delta: float) -> void:
	if not is_local:
		return

	_camera_pivot.global_basis = $Head.global_basis
	$Tower.global_transform.origin = get_mouse_preview()
	$Tower.global_transform.basis  = transform.basis
	$Tower.global_transform.basis.z = -global_transform.basis.z

	if Input.is_action_just_pressed("Inventory1"):
		$Tower.toggle_visible()
	if Input.is_action_just_pressed("leftclick") and $Tower.visible:
		send_preview.emit($Tower.global_transform)
	if Input.is_action_just_pressed("rightclick"):
		action_tower.emit()

	# Broadcast position to peers every frame (unreliable — drops are fine)
	Network.send("player_pos", {'pos': global_position, 'rot': global_rotation})

func dampen_velocity() -> void:
	var tween := create_tween()
	tween.tween_property(self, "linear_damp", 10.0, 0.2)
	tween.tween_property(self, "linear_damp", 0, 1)
