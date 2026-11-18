class_name NpcTest
extends GdUnitTestSuite

## Tests de l'alerte externe d'un `Npc` (`alert_to`), utilisée par les caméras de surveillance.
##
## On utilise un sous-type de `Npc` qui neutralise `_ready` et `_physics_process` (arme, navigation
## réelle) et fournit les enfants que le script attend par chemin.

const ALERT_POSITION := Vector2(120.0, 80.0)
const OTHER_POSITION := Vector2(-40.0, 10.0)
const NAV_AGENT_NAME := "NavigationAgent2D"
const ANIMATED_SPRITE_NAME := "AnimatedSprite2D"
const COLLISION_SHAPE_NAME := "CollisionShape2D"
const FOV_NAME := "FovDetectionComponent"
const MUZZLE_NAME := "Muzzle"
const OBJECT_HOLDER_NAME := "ObjectHolderComponent"
const HEALTH_NAME := "HealthComponent"

## PNJ sans scène : aucun traitement automatique, seuls les enfants nécessaires existent.
class NpcStub extends Npc:
	func _init() -> void:
		_add_named_child(NavigationAgent2D.new(), NAV_AGENT_NAME)
		_add_named_child(AnimatedSprite2D.new(), ANIMATED_SPRITE_NAME)
		_add_named_child(CollisionShape2D.new(), COLLISION_SHAPE_NAME)
		_add_named_child(FovDetectionComponent.new(), FOV_NAME)
		_add_named_child(Node2D.new(), MUZZLE_NAME)
		_add_named_child(ObjectHolderComponent.new(), OBJECT_HOLDER_NAME)
		_add_named_child(HealthComponent.new(), HEALTH_NAME)

	func _add_named_child(child: Node, child_name: String) -> void:
		child.name = child_name
		add_child(child)

	func _ready() -> void:
		pass

	func _physics_process(_delta: float) -> void:
		pass


var _npc: NpcStub


func before_test() -> void:
	_npc = auto_free(NpcStub.new())
	add_child(_npc)


func test_alert_to_while_patrolling_switches_to_searching() -> void:
	_npc.set_state(Npc.ENEMY_STATE.PATROLLING)

	_npc.alert_to(ALERT_POSITION)

	assert_int(_npc._state).is_equal(Npc.ENEMY_STATE.SEARCHING)


func test_alert_to_while_patrolling_navigates_to_alert_position() -> void:
	_npc.set_state(Npc.ENEMY_STATE.PATROLLING)

	_npc.alert_to(ALERT_POSITION)

	assert_vector(_npc.nav_agent.target_position).is_equal(ALERT_POSITION)


func test_alert_to_while_chasing_keeps_chasing() -> void:
	_npc.set_state(Npc.ENEMY_STATE.CHASING)

	_npc.alert_to(ALERT_POSITION)

	assert_int(_npc._state).is_equal(Npc.ENEMY_STATE.CHASING)


func test_alert_to_while_chasing_keeps_current_destination() -> void:
	_npc.set_state(Npc.ENEMY_STATE.CHASING)
	_npc.nav_agent.target_position = OTHER_POSITION

	_npc.alert_to(ALERT_POSITION)

	assert_vector(_npc.nav_agent.target_position).is_equal(OTHER_POSITION)
