extends Npc

var aim_dir := Vector2(10, 0)

func _physics_process(delta):
	super._physics_process(delta)
	if _state != ENEMY_STATE.CHASING:
		return
	
	var target_pos = fov_detection_component.detected_body.global_position
	weapon_holder_component.current_weapon.try_launch_primary_ability(target_pos)
