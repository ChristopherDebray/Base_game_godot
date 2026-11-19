## Stratégie de combat d'un `Npc` : décide s'il doit se rapprocher ou attaquer, et comment
## attaquer. Base mince : les sous-classes (`RangedBehavior`, `MeleeBehavior`, `KamikazeBehavior`)
## surchargent `perform_attack`. Resource pour être réglable dans l'inspecteur ; le `Npc` la duplique à son
## `setup()` afin que l'état propre à une instance (ex. cooldown) ne soit pas partagé.
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

## Exécute une attaque de `attacker` sur `target`. No-op par défaut ; à surcharger.
@warning_ignore("unused_parameter")
func perform_attack(attacker: Npc, target: Node2D) -> void:
	pass
