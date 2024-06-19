extends Area3D


# Called when the node enters the scene tree for the first time.
func _ready():
	connect("body_entered",Callable(self,"_on_body_entered"))

func _on_body_entered(body: PhysicsBody3D):
	var exit_node
	var timer = get_node('/root/World/Portal/portal_cooldown')
	if body.is_in_group("Player") and timer.is_stopped():
		if get_parent().name == 'entermesh':
			exit_node = '/root/World/Portal/exitmesh'
		else:
			exit_node = '/root/World/Portal/entermesh'
		
		timer.start()
		body.global_position = get_node(exit_node).global_position
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
