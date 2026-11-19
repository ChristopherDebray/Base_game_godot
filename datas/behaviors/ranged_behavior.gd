## Combat à distance : l'ennemi s'arrête à portée d'engagement et tire avec l'arme qu'il tient.
class_name RangedBehavior
extends CombatBehavior

const DEFAULT_RANGED_ENGAGEMENT_RANGE: float = 300.0

func _init() -> void:
	engagement_range = DEFAULT_RANGED_ENGAGEMENT_RANGE

## Tire sur la position de `target` avec l'arme de `attacker`. Sans arme équipée (avant
## `late_setup`, ou ennemi désarmé), ne fait rien. Le cooldown et les munitions sont gérés par l'arme.
func perform_attack(attacker: Npc, target: Node2D) -> void:
	var weapon: BaseWeapon = attacker.object_holder_component.current_weapon
	if weapon == null:
		return

	weapon.try_launch_primary_ability(target.global_position)
