class_name HealthComponentTest
extends GdUnitTestSuite

## Tests du HealthComponent. Le composant dépend d'un `Damageable` parent et de l'autoload
## `SignalManager` : on utilise un espion qui compte les appels à `die()` au lieu de libérer
## le node, pour pouvoir observer la mort après coup.

const MAX_HEALTH: float = 100.0
const ENTITY_POSITION := Vector2(10.0, 20.0)

## Remplace `die()` (qui fait `queue_free`) par un compteur observable.
class DamageableSpy extends Damageable:
	var die_call_count: int = 0

	func die() -> void:
		die_call_count += 1


## Construit un Damageable avec son enfant "HealthComponent" (nom requis par `Damageable`)
## et l'ajoute à l'arbre : `_ready` et `global_position` ne sont valides qu'une fois dans l'arbre.
## `auto_free` libère le node à la fin du test, sinon il fuirait entre les tests.
func _create_entity(max_health: float = MAX_HEALTH) -> DamageableSpy:
	var entity := DamageableSpy.new()
	entity.position = ENTITY_POSITION
	var health_component := HealthComponent.new()
	health_component.name = "HealthComponent"
	health_component.health = max_health
	entity.add_child(health_component)
	add_child(auto_free(entity))
	return entity


func test_ready_sets_current_health_to_max() -> void:
	var entity := _create_entity(MAX_HEALTH)

	assert_float(entity.health_component.current_health).is_equal(MAX_HEALTH)


func test_apply_damage_reduces_current_health() -> void:
	var entity := _create_entity()

	entity.take_damage(30.0)

	assert_float(entity.health_component.current_health).is_equal(70.0)


func test_apply_damage_above_zero_does_not_kill() -> void:
	var entity := _create_entity()
	monitor_signals(SignalManager, false)

	entity.take_damage(MAX_HEALTH - 1.0)

	assert_int(entity.die_call_count).is_equal(0)
	await assert_signal(SignalManager).is_not_emitted("on_death", [ENTITY_POSITION])


func test_apply_damage_to_exactly_zero_kills_entity() -> void:
	var entity := _create_entity()

	entity.take_damage(MAX_HEALTH)

	assert_int(entity.die_call_count).is_equal(1)


func test_apply_damage_to_zero_emits_on_death_with_entity_position() -> void:
	var entity := _create_entity()
	# Le monitoring doit démarrer AVANT l'action, sinon l'émission est déjà passée.
	monitor_signals(SignalManager, false)

	entity.take_damage(MAX_HEALTH)

	await assert_signal(SignalManager).is_emitted("on_death", [ENTITY_POSITION])


func test_apply_damage_beyond_health_kills_entity_once() -> void:
	var entity := _create_entity()

	entity.take_damage(MAX_HEALTH * 10.0)

	assert_int(entity.die_call_count).is_equal(1)


func test_apply_damage_on_dead_entity_does_not_kill_twice() -> void:
	var entity := _create_entity()
	entity.take_damage(MAX_HEALTH)
	monitor_signals(SignalManager, false)

	entity.take_damage(5.0)

	assert_int(entity.die_call_count).is_equal(1)
	await assert_signal(SignalManager).is_not_emitted("on_death", [ENTITY_POSITION])


func test_apply_damage_zero_keeps_health_unchanged() -> void:
	var entity := _create_entity()

	entity.take_damage(0.0)

	assert_float(entity.health_component.current_health).is_equal(MAX_HEALTH)


func test_apply_damage_without_entity_is_ignored() -> void:
	# Pas de parent Damageable : le composant doit être inerte plutôt que de planter.
	var health_component: HealthComponent = auto_free(HealthComponent.new())
	health_component.health = MAX_HEALTH
	add_child(health_component)

	health_component.apply_damage(MAX_HEALTH)

	assert_float(health_component.current_health).is_equal(MAX_HEALTH)
