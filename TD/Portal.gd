extends Area3D
@onready var _timer = get_node('../../portal_cooldown')
@onready var _entermesh = get_node('../../entermesh')
@onready var _exitmesh = get_node('../../exitmesh')

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group('PortalEntry')
	connect("body_entered",Callable(self,"_on_body_entered"))
	
func _on_body_entered(body: PhysicsBody3D):
	if body.is_in_group("Player") and _timer.is_stopped():
		_timer.start()
		body.global_position = get_exit_position()
		

func get_exit_position():
	for portal in get_tree().get_nodes_in_group('PortalEntry'):
		if portal != self: 
			return portal.global_position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
