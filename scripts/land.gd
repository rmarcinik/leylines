extends RigidBody3D

func _ready() -> void:
	var inv := InventoryItem.new()
	add_child(inv)
