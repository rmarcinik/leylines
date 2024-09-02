extends Node3D
@onready var _timer = $Portal_timer # Timer node, wait time: 5s, one shot: true
@onready var _enterarea = $Enter/Area3D
@onready var _exitarea = $Exit/Area3D

func _ready():
	_enterarea.connect("body_entered", _on_body_entered)
	_exitarea.connect("body_entered", _on_body_entered)
	
func _on_body_entered(body: PhysicsBody3D):
	if body.is_in_group("Player") and _timer.is_stopped():
		_timer.start()
		body.global_position = _exitarea.global_position if _enterarea.overlaps_body(body) else _enterarea.global_position
