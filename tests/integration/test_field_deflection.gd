extends GdUnitTestSuite

# Player starts facing away from the goal (+Z direction).
# A focal atom at the goal should pull the player's path toward it,
# ending closer than a naive "+Z only" trajectory would.

const GOAL   := Vector3(40.0, 4.0, -20.0)
const FRAMES := 180
const SPEED  := 4.0

var _runner: GdUnitSceneRunner
var _player: Player

func before_test() -> void:
	_runner = scene_runner("res://tests/scenes/test_player_ground.tscn")
	_player = _runner.find_child("Player") as Player
	_player.is_local = false
	_player.global_position = Vector3(0.0, 2.0, 0.0)
	_player.basis = Basis()   # identity — faces +Z, which is AWAY from the goal
	_player.linear_velocity = Vector3.ZERO

func test_focal_atom_curves_path_toward_goal() -> void:
	# Place a large field that encloses both the player start and the goal
	var field := preload("res://scenes/field.tscn").instantiate() as Field
	field.accepts_placed_atoms = true
	field.default_radius = 200.0
	field.global_position = Vector3(20.0, 3.0, -10.0)

	# Focal atom positioned at the goal — strong pull
	var atom := preload("res://scenes/atom.tscn").instantiate() as Atom
	atom.focal = 800.0
	atom.global_position = GOAL

	_runner.scene().add_child(field)
	_runner.scene().add_child(atom)
	# Two physics frames so Area3D overlaps register and the atom joins the field
	await get_tree().physics_frame
	await get_tree().physics_frame

	# Naïve endpoint: player moving straight +Z with no field influence
	var naive_end  := Vector3(0.0, 2.0, SPEED * FRAMES / 60.0)
	var naive_dist := naive_end.distance_to(GOAL)

	for _i in FRAMES:
		_player.linear_velocity = Vector3(0.0, 0.0, SPEED)
		await get_tree().physics_frame

	assert_float(_player.global_position.distance_to(GOAL)).is_less(naive_dist)
