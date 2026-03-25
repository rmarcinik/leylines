class_name InventoryItem extends Node

## Shared component for inventory items (Atom, Land, Tower).
## Add as a child in _ready. Handles preview visuals and player pickup connect/disconnect.
##
## Automatically calls enable_preview() and emits preview_mode (deferred)
## when parent is held by Player. Items connect preview_mode for extra logic.
## Items supply their own areas and call on_player_enter/exit from their handlers.

signal preview_mode

var is_preview: bool = false

var _preview_material: Material = preload("res://asset/preview.tres")

func _ready() -> void:
	is_preview = get_parent().get_parent() is Player
	if is_preview:
		_enter_preview.call_deferred()
	else:
		_setup_cursor_area()

func _setup_cursor_area() -> void:
	var area := Area3D.new()
	var col := CollisionShape3D.new()
	col.shape = SphereShape3D.new()
	area.add_child(col)
	get_parent().add_child(area)
	area.area_entered.connect(func(a): _on_cursor_overlap(a, true))
	area.area_exited.connect(func(a): _on_cursor_overlap(a, false))

func _on_cursor_overlap(area: Area3D, entered: bool) -> void:
	var player := area.get_parent().get_parent() as Player
	if not player:
		return
	if entered:
		on_player_enter(player)
	else:
		on_player_exit(player)

func enable_preview() -> void:
	_set_colliders_disabled(true)
	_apply_preview_material()

func on_player_enter(player: Player) -> void:
	if not player.item_action.is_connected(get_parent().queue_free):
		player.item_action.connect(get_parent().queue_free)

func on_player_exit(player: Player) -> void:
	if player.item_action.is_connected(get_parent().queue_free):
		player.item_action.disconnect(get_parent().queue_free)

func _enter_preview() -> void:
	enable_preview()
	preview_mode.emit()

func _set_colliders_disabled(disabled: bool) -> void:
	for child in get_parent().find_children("*", "CollisionShape3D", true, false):
		child.disabled = disabled
	for child in get_parent().find_children("*", "CollisionPolygon3D", true, false):
		child.disabled = disabled

func _apply_preview_material() -> void:
	for mi: MeshInstance3D in get_parent().find_children("*", "MeshInstance3D", true, false):
		for s in mi.get_surface_override_material_count():
			mi.set_surface_override_material(s, _preview_material)
