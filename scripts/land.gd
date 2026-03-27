extends RigidBody3D

func _ready() -> void:
	add_child(InventoryItem.new())
