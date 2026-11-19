class_name NpcCombatTest
extends GdUnitTestSuite

## Teste l'intégration du `CombatBehavior` dans `Npc` : choix CHASING / ATTACKING selon la portée,
## perte de vue, exécution de l'attaque, duplication de la Resource et ennemi sans arme.
## Réutilise `NpcTest.NpcStub` (pas d'arme, pas de navigation réelle).

const ENGAGEMENT_RANGE: float = 100.0
const IN_RANGE_POSITION := Vector2(50.0, 0.0)
const OUT_OF_RANGE_POSITION := Vector2(500.0, 0.0)
const AIM_POSITION := Vector2(30.0, 0.0)
const ALERT_POSITION := Vector2(120.0, 80.0)

## Behavior espion : compte les attaques déclenchées.
class BehaviorSpy extends CombatBehavior:
	var attack_count: int = 0
	var last_target: Node2D

	func perform_attack(_attacker: Npc, target: Node2D) -> void:
		attack_count += 1
		last_target = target

var _npc: NpcTest.NpcStub
var _behavior: BehaviorSpy
var _target: Node2D

func before_test() -> void:
	_behavior = BehaviorSpy.new()
	_behavior.engagement_range = ENGAGEMENT_RANGE
	_npc = auto_free(NpcTest.NpcStub.new())
	_npc.combat_behavior = _behavior
	add_child(_npc)
	_target = auto_free(Node2D.new())
	add_child(_target)
	_npc.fov_detection_component.detected_body = _target

func test_apply_sight_target_in_range_switches_to_attacking() -> void:
	_target.global_position = IN_RANGE_POSITION

	_npc.apply_sight(true)

	assert_int(_npc._state).is_equal(Npc.ENEMY_STATE.ATTACKING)

func test_apply_sight_target_out_of_range_switches_to_chasing() -> void:
	_target.global_position = OUT_OF_RANGE_POSITION

	_npc.apply_sight(true)

	assert_int(_npc._state).is_equal(Npc.ENEMY_STATE.CHASING)

func test_apply_sight_without_behavior_chases_even_in_range() -> void:
	_npc.combat_behavior = null
	_target.global_position = IN_RANGE_POSITION

	_npc.apply_sight(true)

	assert_int(_npc._state).is_equal(Npc.ENEMY_STATE.CHASING)

func test_apply_sight_lost_while_attacking_switches_to_searching() -> void:
	_npc.set_state(Npc.ENEMY_STATE.ATTACKING)

	_npc.apply_sight(false)

	assert_int(_npc._state).is_equal(Npc.ENEMY_STATE.SEARCHING)

func test_apply_sight_lost_while_chasing_switches_to_searching() -> void:
	_npc.set_state(Npc.ENEMY_STATE.CHASING)

	_npc.apply_sight(false)

	assert_int(_npc._state).is_equal(Npc.ENEMY_STATE.SEARCHING)

func test_apply_sight_lost_while_patrolling_keeps_patrolling() -> void:
	_npc.set_state(Npc.ENEMY_STATE.PATROLLING)

	_npc.apply_sight(false)

	assert_int(_npc._state).is_equal(Npc.ENEMY_STATE.PATROLLING)

func test_alert_to_while_attacking_keeps_attacking() -> void:
	_npc.set_state(Npc.ENEMY_STATE.ATTACKING)

	_npc.alert_to(ALERT_POSITION)

	assert_int(_npc._state).is_equal(Npc.ENEMY_STATE.ATTACKING)

func test_process_attacking_performs_attack_on_detected_body() -> void:
	_npc.process_attacking()

	assert_object(_behavior.last_target).is_same(_target)

func test_process_attacking_without_detected_body_does_not_attack() -> void:
	_npc.fov_detection_component.detected_body = null

	_npc.process_attacking()

	assert_int(_behavior.attack_count).is_equal(0)

func test_setup_duplicates_combat_behavior() -> void:
	_npc.setup()

	assert_object(_npc.combat_behavior).is_not_same(_behavior)

func test_set_aim_dir_without_weapon_updates_facing() -> void:
	_npc.set_aim_dir(AIM_POSITION)

	assert_vector(_npc.facing_position).is_equal(_npc.global_position - AIM_POSITION)
