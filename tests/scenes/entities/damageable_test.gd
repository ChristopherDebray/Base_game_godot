class_name DamageableTest
extends GdUnitTestSuite

## Tests de la base Damageable : transmission des dégâts et mort.
## Un espion remplace `die()` (qui fait `queue_free`) par un compteur observable.

const MAX_HEALTH: float = 20.0
const DAMAGE_AMOUNT: float = 5.0
const EXPECTED_HEALTH_AFTER_DAMAGE: float = 15.0
const HEALTH_COMPONENT_NAME := "HealthComponent"

class DamageableSpy extends Damageable:
	var die_call_count: int = 0

	func die() -> void:
		die_call_count += 1


func _create_damageable_with_health() -> DamageableSpy:
	var entity: DamageableSpy = auto_free(DamageableSpy.new())
	var health_component := HealthComponent.new()
	health_component.name = HEALTH_COMPONENT_NAME
	health_component.health = MAX_HEALTH
	entity.add_child(health_component)
	add_child(entity)
	return entity


func test_take_damage_forwards_damage_to_the_health_component() -> void:
	var entity := _create_damageable_with_health()

	entity.take_damage(DAMAGE_AMOUNT)

	assert_float(entity.health_component.current_health).is_equal(EXPECTED_HEALTH_AFTER_DAMAGE)


func test_take_lethal_damage_calls_die() -> void:
	var entity := _create_damageable_with_health()

	entity.take_damage(MAX_HEALTH)

	assert_int(entity.die_call_count).is_equal(1)


func test_die_frees_the_entity_by_default() -> void:
	var entity: Damageable = auto_free(Damageable.new())
	add_child(entity)

	entity.die()

	assert_bool(entity.is_queued_for_deletion()).is_true()
