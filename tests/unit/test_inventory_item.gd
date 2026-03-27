extends GdUnitTestSuite

func test_on_player_enter_connects_item_action() -> void:
	var player := auto_free(preload("res://scenes/player.tscn").instantiate()) as Player
	player.is_local = false
	add_child(player)

	var atom := auto_free(preload("res://scenes/atom.tscn").instantiate()) as Atom
	add_child(atom)
	await get_tree().process_frame

	var inv := atom.find_child("InventoryItem", true, false) as InventoryItem
	inv.on_player_enter(player)
	assert_bool(player.item_action.is_connected(atom.queue_free)).is_true()

func test_on_player_exit_disconnects_item_action() -> void:
	var player := auto_free(preload("res://scenes/player.tscn").instantiate()) as Player
	player.is_local = false
	add_child(player)

	var atom := auto_free(preload("res://scenes/atom.tscn").instantiate()) as Atom
	add_child(atom)
	await get_tree().process_frame

	var inv := atom.find_child("InventoryItem", true, false) as InventoryItem
	inv.on_player_enter(player)
	inv.on_player_exit(player)
	assert_bool(player.item_action.is_connected(atom.queue_free)).is_false()

func test_on_player_enter_does_not_double_connect() -> void:
	var player := auto_free(preload("res://scenes/player.tscn").instantiate()) as Player
	player.is_local = false
	add_child(player)

	var atom := auto_free(preload("res://scenes/atom.tscn").instantiate()) as Atom
	add_child(atom)
	await get_tree().process_frame

	var inv := atom.find_child("InventoryItem", true, false) as InventoryItem
	inv.on_player_enter(player)
	inv.on_player_enter(player)   # second call should be a no-op
	assert_bool(player.item_action.is_connected(atom.queue_free)).is_true()
	# disconnect once should fully remove it (not require two disconnects)
	player.item_action.disconnect(atom.queue_free)
	assert_bool(player.item_action.is_connected(atom.queue_free)).is_false()
