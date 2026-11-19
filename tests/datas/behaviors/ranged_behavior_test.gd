class_name RangedBehaviorTest
extends GdUnitTestSuite

## Teste `RangedBehavior.perform_attack` : tir sur la cible avec l'arme tenue, et sans arme
## l'attaque est ignorée (pas de crash). Le tir réel est remplacé par un espion.

const TARGET_POSITION := Vector2(200.0, 50.0)

## Arme espion : mémorise les tirs au lieu de jouer sons, animations et raycast.
class WeaponSpy extends BaseWeapon:
	var fired_targets: Array[Vector2] = []

	func try_launch_primary_ability(target: Vector2) -> void:
		fired_targets.append(target)

var _behavior: RangedBehavior
var _attacker: NpcTest.NpcStub
var _target: Node2D

func before_test() -> void:
	_behavior = RangedBehavior.new()
	_attacker = auto_free(NpcTest.NpcStub.new())
	add_child(_attacker)
	_target = auto_free(Node2D.new())
	add_child(_target)
	_target.global_position = TARGET_POSITION

func test_perform_attack_fires_weapon_at_target_position() -> void:
	var weapon: WeaponSpy = auto_free(WeaponSpy.new())
	_attacker.object_holder_component.current_weapon = weapon

	_behavior.perform_attack(_attacker, _target)

	assert_array(weapon.fired_targets).contains_exactly([TARGET_POSITION])

func test_perform_attack_without_weapon_does_nothing() -> void:
	_attacker.object_holder_component.current_weapon = null

	_behavior.perform_attack(_attacker, _target)

	assert_object(_attacker.object_holder_component.current_weapon).is_null()
