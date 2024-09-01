extends Node3D
@onready var _timer = $portal_cooldown
@onready var _enterarea = $entermesh/Area3D
@onready var _exitarea = $exitmesh/Area3D

# Called when the node enters the scene tree for the first time.
func _ready():
	_enterarea.connect("body_entered", _on_body_entered)
	_exitarea.connect("body_entered", _on_body_entered)
	
func _on_body_entered(body: PhysicsBody3D):
	if body.is_in_group("Player") and _timer.is_stopped():
		_timer.start()
		body.global_position = _exitarea.global_position if _enterarea.overlaps_body(body) else _enterarea.global_position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
