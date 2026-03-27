extends GdUnitTestSuite

# Mirrors world.gd ready_player() — the 6 registered inventory items
const ITEMS := [
	{scene = "res://scenes/tower.tscn",  config = {}},
	{scene = "res://scenes/atom.tscn",   config = {focal = 100.0}},
	{scene = "res://scenes/atom.tscn",   config = {radial = 100.0}},
	{scene = "res://scenes/land.tscn",   config = {}},
	{scene = "res://scenes/atom.tscn",   config = {light = 2.0, light_color = Color(1.0, 0.9, 0.5), light_range = 100.0}},
	{scene = "res://scenes/field.tscn",  config = {accepts_placed_atoms = true}},
]

var _runner: GdUnitSceneRunner
var _player: Player

func before_test() -> void:
	_runner = scene_runner("res://tests/scenes/test_player_ground.tscn")
	_player = _runner.find_child("Player") as Player
	_player.is_local = false

func test_all_items_place_and_remove() -> void:
	for entry in ITEMS:
		var packed: PackedScene = load(entry.scene)
		var placed := packed.instantiate() as Node3D
		for key in entry.config:
			placed.set(key, entry.config[key])

		_runner.scene().add_child(placed)
		placed.global_position = Vector3(5.0, 1.0, 5.0)
		await get_tree().process_frame   # let _ready() run

		assert_bool(is_instance_valid(placed)).is_true()
		assert_bool(placed.is_inside_tree()).is_true()

		# Each item creates its own InventoryItem in _ready()
		var inv := placed.find_child("InventoryItem", true, false) as InventoryItem
		assert_bool(inv != null).is_true()

		inv.on_player_enter(_player)
		assert_bool(_player.item_action.is_connected(placed.queue_free)).is_true()

		_player.item_action.emit()
		await get_tree().process_frame   # queue_free processes here

		assert_bool(is_instance_valid(placed)).is_false()
