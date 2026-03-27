extends RigidBody3D

func _ready() -> void:
	var inv := InventoryItem.new()
	inv.name = "InventoryItem"
	add_child(inv)
