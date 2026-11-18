class_name AimComponentTest
extends GdUnitTestSuite

## Tests de la visée à la manette de l'AimComponent (zone morte, rayon, visibilité).
##
## Le composant lit l'autoload `InputSchemeManager` en dur : pour activer la visée manette on
## change son schéma puis on le restaure après chaque test. Les entrées sont simulées avec
## `Input.action_press` (relâchées dans `after_test`). La visée souris n'est pas testée :
## elle dépend de la position réelle de la souris.

const PLAYER_POSITION := Vector2(100.0, 100.0)
const DEADZONE: float = 0.25
const MAX_RADIUS: float = 250.0
const FRAME_DELTA: float = 0.016
const ACTION_AIM_RIGHT := &"aim_right"
const ACTION_AIM_LEFT := &"aim_left"
const ACTION_AIM_DOWN := &"aim_down"
const AIM_ACTIONS: Array[StringName] = [ACTION_AIM_RIGHT, ACTION_AIM_LEFT, &"aim_up", ACTION_AIM_DOWN]
const STICK_BELOW_DEADZONE: float = 0.1
const STICK_FULL: float = 1.0
const STICK_AT_DEADZONE: float = 0.25
const DIAGONAL_RADIUS_OFFSET: float = 176.7767 # 250 * cos(45°) sur chaque axe
const STICK_HALF_WAY: float = 0.625 # (0.625 - zone morte) / (1 - zone morte) = 0.5
const EXPECTED_RADIUS_AT_HALF_WAY: float = 125.0
const POSITION_TOLERANCE := Vector2(0.01, 0.01)

## Remplace le vrai joueur : pas de scène, pas d'arme. Enregistre la direction de visée reçue.
class PlayerSpy extends Player:
	var received_aim_dir: Vector2 = Vector2.ZERO

	func _init() -> void:
		_add_named_child(AnimatedSprite2D.new(), "AnimatedSprite2D")
		_add_named_child(CollisionShape2D.new(), "CollisionShape2D")
		_add_named_child(Node2D.new(), "Muzzle")
		_add_named_child(ObjectHolderComponent.new(), "ObjectHolderComponent")
		_add_named_child(ObjectsHolderComponent.new(), "ObjectsHolderComponent")

	func _add_named_child(child: Node, child_name: String) -> void:
		child.name = child_name
		add_child(child)

	func _ready() -> void:
		pass

	func set_aim_dir(dir: Vector2) -> void:
		received_aim_dir = dir


var _previous_scheme: int
var _player: PlayerSpy
var _aim: AimComponent


func before_test() -> void:
	_previous_scheme = InputSchemeManager.current_scheme
	_player = auto_free(PlayerSpy.new())
	_player.global_position = PLAYER_POSITION
	add_child(_player)
	_aim = auto_free(AimComponent.new())
	_aim.player = _player
	_aim.deadzone = DEADZONE
	_aim.max_radius = MAX_RADIUS
	add_child(_aim)


func after_test() -> void:
	for action in AIM_ACTIONS:
		Input.action_release(action)
	if InputSchemeManager.current_scheme == _previous_scheme:
		return
	InputSchemeManager.current_scheme = _previous_scheme
	InputSchemeManager.scheme_changed.emit(_previous_scheme)


func _use_gamepad_scheme() -> void:
	InputSchemeManager.current_scheme = InputSchemeManager.SCHEME.XBOX
	InputSchemeManager.scheme_changed.emit(InputSchemeManager.SCHEME.XBOX)


func test_stick_below_deadzone_hides_the_aim() -> void:
	_use_gamepad_scheme()
	Input.action_press(ACTION_AIM_RIGHT, STICK_BELOW_DEADZONE)

	_aim._process(FRAME_DELTA)

	assert_bool(_aim.visible).is_false()


func test_stick_below_deadzone_recenters_the_aim_next_to_the_player() -> void:
	_use_gamepad_scheme()
	Input.action_press(ACTION_AIM_RIGHT, STICK_BELOW_DEADZONE)

	_aim._process(FRAME_DELTA)

	assert_vector(_aim.global_position).is_equal_approx(PLAYER_POSITION + _player.facing_direction, POSITION_TOLERANCE)


func test_stick_beyond_deadzone_shows_the_aim() -> void:
	_aim.visible = false
	_use_gamepad_scheme()
	Input.action_press(ACTION_AIM_RIGHT, STICK_FULL)

	_aim._process(FRAME_DELTA)

	assert_bool(_aim.visible).is_true()


func test_full_stick_places_the_aim_at_max_radius_from_the_player() -> void:
	_use_gamepad_scheme()
	Input.action_press(ACTION_AIM_RIGHT, STICK_FULL)

	_aim._process(FRAME_DELTA)

	assert_vector(_aim.global_position).is_equal_approx(PLAYER_POSITION + Vector2(MAX_RADIUS, 0.0), POSITION_TOLERANCE)


func test_half_way_stick_places_the_aim_at_half_radius() -> void:
	_use_gamepad_scheme()
	Input.action_press(ACTION_AIM_RIGHT, STICK_HALF_WAY)

	_aim._process(FRAME_DELTA)

	assert_vector(_aim.global_position).is_equal_approx(PLAYER_POSITION + Vector2(EXPECTED_RADIUS_AT_HALF_WAY, 0.0), POSITION_TOLERANCE)


func test_half_way_stick_without_stick_magnitude_still_uses_max_radius() -> void:
	_aim.use_stick_magnitude = false
	_use_gamepad_scheme()
	Input.action_press(ACTION_AIM_RIGHT, STICK_HALF_WAY)

	_aim._process(FRAME_DELTA)

	assert_vector(_aim.global_position).is_equal_approx(PLAYER_POSITION + Vector2(MAX_RADIUS, 0.0), POSITION_TOLERANCE)


func test_stick_to_the_left_rotates_the_aim_toward_the_left() -> void:
	_use_gamepad_scheme()
	Input.action_press(ACTION_AIM_LEFT, STICK_FULL)

	_aim._process(FRAME_DELTA)

	assert_float(_aim.rotation).is_equal_approx(Vector2.LEFT.angle(), 0.001)


func test_stick_direction_is_sent_to_the_player() -> void:
	_use_gamepad_scheme()
	Input.action_press(ACTION_AIM_RIGHT, STICK_FULL)

	_aim._process(FRAME_DELTA)

	assert_vector(_player.received_aim_dir).is_equal(Vector2.RIGHT)


func test_aim_world_position_with_gamepad_is_the_aim_node_position() -> void:
	_use_gamepad_scheme()
	Input.action_press(ACTION_AIM_RIGHT, STICK_FULL)
	_aim._process(FRAME_DELTA)

	assert_vector(_aim.get_aim_world_position()).is_equal_approx(PLAYER_POSITION + Vector2(MAX_RADIUS, 0.0), POSITION_TOLERANCE)


func test_stick_pushed_down_places_the_aim_below_the_player() -> void:
	_use_gamepad_scheme()
	Input.action_press(ACTION_AIM_DOWN, STICK_FULL)

	_aim._process(FRAME_DELTA)

	assert_vector(_aim.global_position).is_equal_approx(PLAYER_POSITION + Vector2(0.0, MAX_RADIUS), POSITION_TOLERANCE)


func test_stick_exactly_at_deadzone_shows_the_aim_on_the_player() -> void:
	_aim.visible = false
	_use_gamepad_scheme()
	Input.action_press(ACTION_AIM_RIGHT, STICK_AT_DEADZONE)

	_aim._process(FRAME_DELTA)

	assert_bool(_aim.visible).is_true()
	assert_vector(_aim.global_position).is_equal_approx(PLAYER_POSITION, POSITION_TOLERANCE)


func test_diagonal_stick_beyond_unit_length_is_capped_at_max_radius() -> void:
	_use_gamepad_scheme()
	Input.action_press(ACTION_AIM_RIGHT, STICK_FULL)
	Input.action_press(ACTION_AIM_DOWN, STICK_FULL)

	_aim._process(FRAME_DELTA)

	var diagonal_offset := Vector2(DIAGONAL_RADIUS_OFFSET, DIAGONAL_RADIUS_OFFSET)
	assert_vector(_aim.global_position).is_equal_approx(PLAYER_POSITION + diagonal_offset, POSITION_TOLERANCE)


func test_stick_below_deadzone_without_return_to_center_leaves_position_untouched() -> void:
	_aim.return_to_center_on_idle = false
	_aim.global_position = Vector2.ZERO
	_use_gamepad_scheme()
	Input.action_press(ACTION_AIM_RIGHT, STICK_BELOW_DEADZONE)

	_aim._process(FRAME_DELTA)

	assert_vector(_aim.global_position).is_equal_approx(Vector2.ZERO, POSITION_TOLERANCE)
