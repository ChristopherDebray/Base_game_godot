class_name MeleeBehaviorTest
extends GdUnitTestSuite

## Teste `MeleeBehavior.perform_attack` : dégâts au contact, cooldown entre deux coups et cible
## non blessable ignorée.

const MELEE_DAMAGE: float = 5.0
const LONG_COOLDOWN_SECONDS: float = 60.0
const NO_COOLDOWN_SECONDS: float = 0.0

## Cible espion : mémorise les dégâts reçus sans passer par un `HealthComponent`.
class DamageableSpy extends Damageable:
	var received_damages: Array[float] = []

	func take_damage(amount: float) -> void:
		received_damages.append(amount)

var _behavior: MeleeBehavior
var _attacker: NpcTest.NpcStub

func before_test() -> void:
	_behavior = MeleeBehavior.new()
	_behavior.damage = MELEE_DAMAGE
	_attacker = auto_free(NpcTest.NpcStub.new())
	add_child(_attacker)

func test_perform_attack_damages_target() -> void:
	var target: DamageableSpy = auto_free(DamageableSpy.new())

	_behavior.perform_attack(_attacker, target)

	assert_array(target.received_damages).contains_exactly([MELEE_DAMAGE])

func test_perform_attack_during_cooldown_does_not_damage_again() -> void:
	_behavior.attack_cooldown = LONG_COOLDOWN_SECONDS
	var target: DamageableSpy = auto_free(DamageableSpy.new())

	_behavior.perform_attack(_attacker, target)
	_behavior.perform_attack(_attacker, target)

	assert_array(target.received_damages).has_size(1)

func test_perform_attack_without_cooldown_damages_each_call() -> void:
	_behavior.attack_cooldown = NO_COOLDOWN_SECONDS
	var target: DamageableSpy = auto_free(DamageableSpy.new())

	_behavior.perform_attack(_attacker, target)
	_behavior.perform_attack(_attacker, target)

	assert_array(target.received_damages).has_size(2)

func test_perform_attack_on_non_damageable_target_does_nothing() -> void:
	var target: Node2D = auto_free(Node2D.new())

	_behavior.perform_attack(_attacker, target)

	assert_object(target).is_not_null()
