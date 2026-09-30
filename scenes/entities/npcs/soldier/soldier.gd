extends Npc

@onready var _9_mm_pistol: BaseWeapon = $"9mmPistol"
var aim_dir := Vector2(10, 0)

func _physics_process(delta):
	super._physics_process(delta)
	if _state != ENEMY_STATE.CHASING:
		return
	
	var target_pos = fov_detection_component.detected_body.global_position
	set_aim_dir(target_pos)
	_9_mm_pistol.try_launch_primary_ability(target_pos)

func set_aim_dir(dir: Vector2):
	aim_dir = dir
	_9_mm_pistol.look_at(aim_dir)
	# @todo fix to move weapond in radius
	var aim_dir_angle = aim_dir.angle() * 10
	_9_mm_pistol.position.y = aim_dir_angle
