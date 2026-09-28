extends BaseWeapon

func launch_primary_ability(target: Vector2):
	await super.launch_primary_ability(target)

	var dir = (target - muzzle.global_position).normalized()
	var space_state = get_world_2d().direct_space_state
	
	var query = PhysicsRayQueryParameters2D.create(
		muzzle.global_position,
		muzzle.global_position + dir * primary_ability.range
	)
	query.exclude = [self]  # évite de se toucher soi-même
	
	var result = space_state.intersect_ray(query)
	
	if result:
		hit_trigger(primary_ability.damage, result.position, result.normal, result.collider)

func hit_trigger(damage: float, position: Vector2, normal: Vector2, collider: Variant):
	SceneSpawnerManager.spawn_hit_particle(position, 0)
	if is_instance_of(collider, Npc):
		var npc: Npc = collider
		npc.health_component.apply_damage(damage)
