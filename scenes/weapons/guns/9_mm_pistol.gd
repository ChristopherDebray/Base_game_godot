extends BaseWeapon

func launch_primary_ability(target: Vector2):
	print(target)
	var dir = (target - global_position).normalized()
	
	var raycast = RayCast2D.new()
	raycast.global_position = muzzle.global_position
	# RayCast2D.target_position est relatif à la position du RayCast lui-même,
	# pas une position globale dans le monde.
	# target est une position globale, donc le rayon part dans une direction complètement fausse
	# Le multiplicateur = la distance max du rayon
	raycast.target_position = dir * 100
	print(raycast)
	get_tree().current_scene.get_node("LitViewport").add_child(raycast)
	
	# Quand on créer un raycast et qu'il est ajouté on ne calcule pas sa position encore,
	# Il faut donc forcer la mise à jour
	raycast.force_raycast_update()
	print(raycast.get_collision_point())
	print(raycast.is_colliding())
	
	animated_sprite_2d.play("primary_ability")
