extends Node2D

class_name HealthComponent

@export var health: float = 100

var current_health: float
var entity: Damageable

func _ready():
	if entity == null:
		entity = get_parent()
	current_health = health

func apply_damage(value: float):
	current_health = current_health - value
	if current_health <= 0:
		SignalManager.on_death.emit(entity.global_position)
		entity.die()
