extends RigidBody3D

func _ready() -> void:
	$Timer.connect("timeout",Callable(self,"_on_Timer_timeout"))

func _on_Timer_timeout():
	queue_free()
