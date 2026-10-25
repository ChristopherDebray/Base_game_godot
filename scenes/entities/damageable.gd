extends CharacterBody2D

## Entité pouvant subir des dégâts. La vie est portée par un enfant `HealthComponent`
## (nommé "HealthComponent") ; sans lui, l'entité est invulnérable.
class_name Damageable

@onready var health_component: HealthComponent = $HealthComponent

## Point d'entrée unique des dégâts : les armes n'ont pas besoin de connaître le type de la cible.
func take_damage(amount: float) -> void:
	if health_component == null:
		return
	health_component.apply_damage(amount)

## Appelé par le HealthComponent quand la vie tombe à 0. Surchargé par les entités
## qui ne doivent pas simplement disparaître (ex. le joueur).
func die() -> void:
	queue_free()
