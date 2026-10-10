extends BaseWeapon

class_name ProjectileWeapon

func launch_primary_ability(target: Vector2):
	await super.launch_primary_ability(target)

	var space_state = get_world_2d().direct_space_state
	var result = CollisionManager.draw_ray_query_to_target(
		target,
		muzzle.global_position,
		data.primary_ability.range,
		space_state,
		self
	)
	
	if result:
		hit_trigger(data.primary_ability.damage, result.position, result.normal, result.collider)
