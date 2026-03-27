class_name Player extends RigidBody3D

@onready var _camera_pivot: Node3D    = $CameraPivot
@onready var _camera_arm: SpringArm3D = $CameraPivot/CameraArm
@onready var _camera: Camera3D        = $CameraPivot/CameraArm/Camera3D
@onready var _raycast: RayCast3D      = $Downward

@export var mouse_sens          := 0.01
@export var y_mouse_sens        := 0.1
@export var speed               := 6000.0
@export var jump_strength       := 200.0
@export var local_gravity       := Vector3.DOWN
@export var ground_acceleration := 30.0
@export var air_acceleration    := 20.0
@export var ground_friction     := 1.1
@export var air_friction        := 0.8
@export var accel_curve: Curve
@export var inventory: Array[Node3D]
## Set false on nodes that represent remote peers — disables input, camera, and broadcasting.
var is_local: bool = true

var _pos_sent_logged      := false
var _move_direction       := Vector3.ZERO
var _last_strong_direction := Vector3.FORWARD
var _current_velocity     := Vector3.ZERO
var _target_velocity      := Vector3.ZERO
var mouseMotion_x: float
var mouseMotion_y: float

signal send_preview(node, position)
signal item_action()

var active_slot: Node3D
var cursor: Node3D

func _ready() -> void:
	for item in inventory:
		add_child(item)
		item.visible = false


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
		_rotate_camera_from_mouse(event)

func _rotate_camera_from_mouse(event: InputEventMouseMotion) -> void:
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

func _integrate_forces(state) -> void:
	_current_velocity = linear_velocity
	_resolve_local_gravity(state)

	if not is_local:
		return

	_move_direction        = _get_model_oriented_input()
	_last_strong_direction = _camera_pivot.global_basis.z
	basis = _orient_character_to_direction(_last_strong_direction, local_gravity, state.step)

	_target_velocity = _move_direction * speed
	_apply_movement_physics(state.step)

	if is_jumping():
		apply_central_impulse(-local_gravity * jump_strength)
	if is_falling():
		apply_central_impulse(local_gravity * jump_strength)
		dampen_velocity()

func _resolve_local_gravity(state) -> void:
	var raw_gravity = state.total_gravity
	local_gravity = raw_gravity.normalized() if raw_gravity.length_squared() > 0.001 else -_camera_pivot.global_basis.y

func _apply_movement_physics(step: float) -> void:
	#var velocity_difference := (_target_velocity - _current_velocity).length()
	#var curve_sample        := accel_curve.sample_baked(velocity_difference)
	var accel   := ground_acceleration if is_grounded() else air_acceleration
	var friction := ground_friction    if is_grounded() else air_friction
	_current_velocity *= friction
	_current_velocity = _current_velocity.lerp(_target_velocity, step * accel)
	apply_central_force(_current_velocity)

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
		
	_handle_inventory_hotkeys()

	cursor.global_position = get_mouse_preview()
	_update_slot_preview()

	if Input.is_action_just_pressed("rightclick"):
		item_action.emit()

	# Broadcast position — reliable for now until unreliable ENet is confirmed working
	if not _pos_sent_logged:
		print("[Player] sending player_pos pos=", global_position, " lobby_id=", Network.lobby_id)
		_pos_sent_logged = true
	Network.send("player_pos", {'pos': global_position, 'rot': global_rotation}, true)

func _handle_inventory_hotkeys() -> void:
	if Input.is_action_just_pressed("Inventory1"):
		_select_slot(0)
	if Input.is_action_just_pressed("Inventory2"):
		_select_slot(1)
	if Input.is_action_just_pressed("Inventory3"):
		_select_slot(2)
	if Input.is_action_just_pressed("Inventory4"):
		_select_slot(3)
	if Input.is_action_just_pressed("Inventory5"):
		_select_slot(4)
	if Input.is_action_just_pressed("Inventory6"):
		_select_slot(5)

func _update_slot_preview() -> void:
	if not active_slot:
		return
	active_slot.global_transform.origin = cursor.global_position
	active_slot.global_transform.basis  = transform.basis
	active_slot.global_transform.basis.z = -global_transform.basis.z
	if Input.is_action_just_pressed("leftclick") and active_slot.visible:
		send_preview.emit(active_slot, active_slot.global_transform)

func _select_slot(index: int) -> void:
	if index >= inventory.size():
		return
	var slot := inventory[index]
	if active_slot == slot:
		slot.visible = not slot.visible
		if not slot.visible:
			active_slot = null
	else:
		if active_slot:
			active_slot.visible = false
		active_slot = slot
		active_slot.visible = true

func dampen_velocity() -> void:
	var tween := create_tween()
	tween.tween_property(self, "linear_damp", 10.0, 0.2)
	tween.tween_property(self, "linear_damp", 0, 1)
