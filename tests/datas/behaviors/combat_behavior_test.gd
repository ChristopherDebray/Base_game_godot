class_name CombatBehaviorTest
extends GdUnitTestSuite

## Teste `CombatBehavior` : la décision pure (approcher ou attaquer selon portée et vue) et le
## déclenchement de la capacité primaire de l'arme tenue. Les sous-classes ne fixent que la portée
## par défaut, elles n'ont pas de logique à tester.

const ENGAGEMENT_RANGE: float = 100.0
const WITHIN_RANGE: float = 50.0
const OUT_OF_RANGE: float = 150.0
const TARGET_POSITION := Vector2(200.0, 50.0)

## Arme espion : mémorise les tirs au lieu de jouer sons, animations et raycast.
class WeaponSpy extends BaseWeapon:
	var fired_targets: Array[Vector2] = []

	func try_launch_primary_ability(target: Vector2) -> void:
		fired_targets.append(target)

var _behavior: CombatBehavior
var _attacker: NpcTest.NpcStub
var _target: Node2D

func before_test() -> void:
	_behavior = CombatBehavior.new()
	_behavior.engagement_range = ENGAGEMENT_RANGE
	_attacker = auto_free(NpcTest.NpcStub.new())
	add_child(_attacker)
	_target = auto_free(Node2D.new())
	add_child(_target)
	_target.global_position = TARGET_POSITION

func test_decide_within_range_with_line_of_sight_attacks() -> void:
	var action: CombatBehavior.Action = _behavior.decide(WITHIN_RANGE, true)

	assert_int(action).is_equal(CombatBehavior.Action.ATTACK)

func test_decide_exactly_at_range_attacks() -> void:
	var action: CombatBehavior.Action = _behavior.decide(ENGAGEMENT_RANGE, true)

	assert_int(action).is_equal(CombatBehavior.Action.ATTACK)

func test_decide_out_of_range_approaches() -> void:
	var action: CombatBehavior.Action = _behavior.decide(OUT_OF_RANGE, true)

	assert_int(action).is_equal(CombatBehavior.Action.APPROACH)

func test_decide_within_range_without_line_of_sight_approaches() -> void:
	var action: CombatBehavior.Action = _behavior.decide(WITHIN_RANGE, false)

	assert_int(action).is_equal(CombatBehavior.Action.APPROACH)

func test_perform_attack_fires_weapon_primary_ability_at_target_position() -> void:
	var weapon: WeaponSpy = auto_free(WeaponSpy.new())
	_attacker.object_holder_component.current_weapon = weapon

	_behavior.perform_attack(_attacker, _target)

	assert_array(weapon.fired_targets).contains_exactly([TARGET_POSITION])

func test_perform_attack_without_weapon_does_nothing() -> void:
	_attacker.object_holder_component.current_weapon = null

	_behavior.perform_attack(_attacker, _target)

	assert_object(_attacker.object_holder_component.current_weapon).is_null()
