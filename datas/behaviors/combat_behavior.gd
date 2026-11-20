## Stratégie de combat d'un `Npc` : décide QUAND il s'arrête de poursuivre pour attaquer (portée
## d'engagement, vue dégagée). Le COMMENT est porté par l'arme équipée : attaquer = déclencher sa
## capacité primaire (tir, coup, explosion...), qui gère elle-même cooldown, dégâts et portée.
## Les sous-classes (`RangedBehavior`, `MeleeBehavior`, `KamikazeBehavior`) ne fixent que la
## portée d'engagement par défaut. Resource pour être réglable dans l'inspecteur.
class_name CombatBehavior
extends Resource

enum Action { APPROACH, ATTACK }

## Distance maximale (en pixels) à laquelle l'ennemi s'arrête pour attaquer.
@export var engagement_range: float = 100.0

## Choisit l'action selon la distance à la cible et la visibilité. Logique pure, sans SceneTree :
## attaquer exige d'être à portée ET de voir la cible, sinon on se rapproche.
func decide(distance_to_target: float, has_line_of_sight: bool) -> Action:
	if not has_line_of_sight:
		return Action.APPROACH
	if distance_to_target > engagement_range:
		return Action.APPROACH
	return Action.ATTACK

## Déclenche la capacité primaire de l'arme tenue par `attacker`, en visant la position de
## `target`. Sans arme équipée (avant `late_setup`, ou ennemi désarmé), ne fait rien. Cooldown et
## munitions sont gérés par l'arme.
func perform_attack(attacker: Npc, target: Node2D) -> void:
	var weapon: BaseWeapon = attacker.object_holder_component.current_weapon
	if weapon == null:
		return

	weapon.try_launch_primary_ability(target.global_position)
