extends Node3D

@onready var _timer: Timer = $Portal_timer # Timer node, wait time: 5s, one shot: true
@onready var _enter: Node3D = $Enter
@onready var _exit: Node3D = $Exit
@onready var _enterarea: Area3D = $Enter/Area3D
@onready var _exitarea: Area3D = $Exit/Area3D
@onready var _entercam: Camera3D = $Enter/EnterView/EnterCam
@onready var _exitcam: Camera3D = $Exit/ExitView/ExitCam

func _ready():
	_enterarea.body_entered.connect(_on_body_entered.bind(_exitarea))
	_exitarea.body_entered.connect(_on_body_entered.bind(_enterarea))

func _on_body_entered(body: PhysicsBody3D, exit: Node3D):
	if body.is_in_group("Player") and _timer.is_stopped():
		_timer.start()
		body.global_position = exit.global_position

func portal_mover():
	var viewport = get_viewport()
	var camera = viewport.get_camera_3d()
	var view_pos = camera.global_position

	# Make portal entrances look at viewport camera
	_enter.look_at(view_pos)
	_exit.look_at(view_pos)

	# Make cameras face opposite direction by rotating 180° around Y axis
	_entercam.basis = _exit.basis.rotated(Vector3.UP, PI)
	_exitcam.basis = _enter.basis.rotated(Vector3.UP, PI)

func _process(_delta: float) -> void:
	portal_mover()
