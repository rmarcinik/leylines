extends RigidBody3D

@export var speed := 10000.0
@export var jump_strength := 10000.0
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

@onready var _spring_arm: SpringArm3D = $CameraArm
@onready var _raycast: RayCast3D = $Downward
@onready var _frontraycast: RayCast3D = $Forward

func _ready() -> void:
	$Timer.connect("timeout",Callable(self,"_on_Timer_timeout"))
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event): 
	if(event is InputEventMouseMotion): 
		mouseMotion_x = event.relative.x
		mouseMotion_y = event.relative.y

func _on_Timer_timeout():
	print(_move_direction)

func floored() -> bool:
	return _raycast.is_colliding()

func _integrate_forces(state) -> void:

	
	if(mouseMotion_y != null):
		v_rot = -Vector3(transform.basis.x*mouseMotion_y*0.2)
	if(mouseMotion_x != null):
		h_rot = -Vector3(transform.basis.y*mouseMotion_x*0.2)
	rot_vec = v_rot + h_rot
	state.angular_velocity = rot_vec
	
	
	
	
	# Get direction of gravity
	local_gravity = state.total_gravity.normalized()
		
	_move_direction = _get_model_oriented_input()
	_last_strong_direction = _frontraycast.target_position.normalized()
	_last_strong_direction = get_mouse_preview().normalized()
	_orient_character_to_direction(_last_strong_direction, state.step)
	
	if is_jumping():
		#print('applying force when jumping')
		apply_central_impulse(-local_gravity * jump_strength)
	if floored():
		#print('applying force when on the ground')
		apply_central_force(_move_direction * speed)
	else:
		#print('applying force when in the air')
		apply_central_force(_move_direction * speed / 2)
		
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
	print(rotation_basis)
	basis = basis.get_rotation_quaternion().slerp(rotation_basis.get_rotation_quaternion(), delta * 20)

func is_jumping():
	return Input.is_action_pressed("jump")

func get_mouse_preview() -> Vector3:
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
	$Tower.global_transform.origin = get_mouse_preview()
	if Input.is_action_just_pressed("Inventory1"):
		$Tower.toggle_visible()
	if Input.is_action_just_pressed("leftclick"):
		emit_signal('send_preview', $Tower.global_transform)
	if Input.is_action_just_pressed("rightclick"):
		emit_signal('action_tower')
