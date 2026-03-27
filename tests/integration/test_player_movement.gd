extends GdUnitTestSuite

const GOAL   := Vector3(40.0, 4.0, -20.0)
const FRAMES := 120

var _runner: GdUnitSceneRunner
var _player: Player

func before_test() -> void:
	_runner = scene_runner("res://tests/scenes/test_player_ground.tscn")
	_player = _runner.find_child("Player") as Player
	_player.is_local = false
	_player.global_position = Vector3(0.0, 2.0, 0.0)
	var fwd := (GOAL - _player.global_position).normalized()
	_player.basis = Basis.looking_at(fwd, Vector3.UP)
	_player.linear_velocity = Vector3.ZERO

func test_player_moves_closer_to_goal() -> void:
	var start_dist := _player.global_position.distance_to(GOAL)
	var fwd := -_player.global_transform.basis.z
	for _i in FRAMES:
		_player.linear_velocity = fwd * 10.0
		await get_tree().physics_frame
	assert_float(_player.global_position.distance_to(GOAL)).is_less(start_dist)

func test_no_lateral_drift() -> void:
	var start := _player.global_position
	var fwd   := -_player.global_transform.basis.z
	for _i in FRAMES:
		_player.linear_velocity = fwd * 10.0
		await get_tree().physics_frame
	var displacement := _player.global_position - start
	var lateral      := displacement - displacement.project(fwd)
	assert_float(lateral.length()).is_less(2.0)
