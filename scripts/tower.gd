extends RigidBody3D

var previewmesh = preload("res://asset/preview.tres")
var projectile = preload("res://scenes/projectile.tscn")
var SPEED = 100

func _ready() -> void:
	$Timer.timeout.connect(self._on_Timer_timeout)

	if get_parent() is Player:
		visible = not visible
		enable_preview()

func _on_Timer_timeout():
	item_action()

func item_action():
	var rock = projectile.instantiate()
	add_child(rock, true)
	rock.global_transform = $Spawner.global_transform
	var outwards = rock.global_transform.basis.z + rock.global_transform.basis.y
	rock.apply_central_impulse(outwards*SPEED)

func enable_preview():
	# previewmesh is a transparent green mesh to replace the tower
	# we also need to disable collision
	#
	$Timer.stop()
	$Base.set_surface_override_material(0, previewmesh)
	$Base/Spout.set_surface_override_material(0, previewmesh)
	$BaseCollider.set_disabled(true)
	$SpoutCollider.set_disabled(true)
