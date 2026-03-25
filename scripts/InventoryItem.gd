## Base class for placeable inventory items.
##
## Subclass this and override `item_action()` to implement placement behaviour.
## The player calls `item_action.emit()` (signal on Player) which world.gd
## connects to each placed item's `item_action` method.
##
## Preview mode (while held in inventory):
##   - mesh is swapped to the transparent preview material
##   - colliders are disabled
##   - `is_preview` is true so subclasses can gate logic
##
## Usage in world.gd:
##   _register_item(load("res://scenes/my_item.tscn"))
class_name InventoryItem extends Node3D

## Emitted when this item performs its action (placement, fire, etc).
## Connected by world.gd to player.item_action when the item is placed.
signal activated()

## Material applied while the node is the active inventory preview.
@export var preview_material: Material = preload("res://asset/preview.tres")

## True while this node lives inside the Player's inventory (pre-placement).
var is_preview := false

# ── Subclass API ──────────────────────────────────────────────────────────────

## Override in subclasses to implement the item's action on placement/use.
func item_action() -> void:
	activated.emit()

# ── Preview mode ──────────────────────────────────────────────────────────────

## Call to enter preview mode (transparent mesh, colliders off).
## world.gd calls this automatically via _register_item.
func enable_preview() -> void:
	is_preview = true
	_set_colliders_disabled(true)
	_apply_material_to_meshes(preview_material)

## Called by world.gd when the item is placed into the world.
func disable_preview() -> void:
	is_preview = false
	_set_colliders_disabled(false)
	_apply_material_to_meshes(null)

# ── Helpers ───────────────────────────────────────────────────────────────────

func _set_colliders_disabled(disabled: bool) -> void:
	for col in _find_children_of_type(CollisionShape3D):
		col.disabled = disabled
	for col in _find_children_of_type(CollisionPolygon3D):
		col.disabled = disabled

func _apply_material_to_meshes(material: Material) -> void:
	for mi in _find_children_of_type(MeshInstance3D):
		for s in mi.get_surface_override_material_count():
			mi.set_surface_override_material(s, material)

func _find_children_of_type(type: Variant) -> Array:
	var result := []
	for child in find_children("*", "", true, false):
		if is_instance_of(child, type):
			result.append(child)
	return result
