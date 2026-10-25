extends Node2D

## Gère la vie d'une entité `Damageable` (son parent par défaut) et la tue à 0.
class_name HealthComponent

@export var health: float = 100
var current_health: float
var entity: Damageable

func _ready() -> void:
	if entity == null:
		entity = get_parent() as Damageable
	current_health = health

## Retire `value` points de vie. À 0 : émet `on_death` puis appelle `entity.die()`.
## Ignoré si l'entité est déjà morte, pour ne pas déclencher la mort deux fois.
func apply_damage(value: float) -> void:
	if entity == null or current_health <= 0:
		return

	current_health -= value
	if current_health > 0:
		return

	SignalManager.on_death.emit(entity.global_position)
	entity.die()
