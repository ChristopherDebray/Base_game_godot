extends BaseWeapon

func launch_primary_ability(target: Vector2):
	await super.launch_primary_ability(target)

	var space_state = get_world_2d().direct_space_state
	var result = CollisionManager.draw_ray_query_to_target(
		target,
		muzzle.global_position,
		primary_ability.range,
		space_state,
		self
	)
	
	if result:
		hit_trigger(primary_ability.damage, result.position, result.normal, result.collider)

func hit_trigger(damage: float, position: Vector2, normal: Vector2, collider: Variant):
	SceneSpawnerManager.spawn_hit_particle(position, 0)
	if is_instance_of(collider, Npc):
		var npc: Npc = collider
		npc.health_component.apply_damage(damage)
