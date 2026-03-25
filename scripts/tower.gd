extends RigidBody3D

var projectile = preload("res://scenes/projectile.tscn")
var SPEED = 100

func _ready() -> void:
	$Timer.timeout.connect(_on_Timer_timeout)
	var inv := InventoryItem.new()
	add_child(inv)
	inv.preview_mode.connect($Timer.stop)

func _on_Timer_timeout():
	item_action()

func item_action():
	var rock = projectile.instantiate()
	add_child(rock, true)
	rock.global_transform = $Spawner.global_transform
	var outwards = rock.global_transform.basis.z + rock.global_transform.basis.y
	rock.apply_central_impulse(outwards * SPEED)
