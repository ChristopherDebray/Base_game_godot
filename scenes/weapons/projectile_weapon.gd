extends BaseWeapon

## Arme à tir par raycast : trace un rayon depuis la bouche vers la cible, limité à la portée de
## la capacité primaire et filtré par `hit_mask`, puis déclenche l'impact sur le premier touché.
class_name ProjectileWeapon

## Joue l'effet de base du tir (`super`) puis lance le raycast vers `target` ; applique les
## dégâts via `hit_trigger` si le rayon touche quelque chose.
func launch_primary_ability(target: Vector2) -> void:
	await super.launch_primary_ability(target)

	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var result: Dictionary = CollisionManager.draw_ray_query_to_target(
		target,
		muzzle.global_position,
		data.primary_ability.range,
		space_state,
		self,
		hit_mask
	)
	
	if result:
		hit_trigger(data.primary_ability.damage, result.position, result.normal, result.collider)
