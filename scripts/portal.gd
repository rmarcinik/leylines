extends Node3D

@onready var _timer: Timer = $Portal_timer # Timer node, wait time: 5s, one shot: true
@onready var _enterarea: Area3D = $Enter/Area3D
@onready var _exitarea: Area3D = $Exit/Area3D

func _ready():
	_enterarea.body_entered.connect(_on_body_entered.bind(_exitarea))
	_exitarea.body_entered.connect(_on_body_entered.bind(_enterarea))

func _on_body_entered(body: PhysicsBody3D, exit: Node3D):
	if body.is_in_group("Player") and _timer.is_stopped():
		_timer.start()
		body.global_position = exit.global_position
