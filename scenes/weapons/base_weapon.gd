extends Node2D

class_name BaseWeapon

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var muzzle: Node2D = $Muzzle

@export var primary_ability: BaseAbility
@export var secondary_ability: BaseAbility = null
@export var fire_rate: float = 0.15  # secondes entre 2 tirs

var can_launch_primary_ability: bool = true
var can_launch_secondary_ability: bool = true

func try_launch_primary_ability(target: Vector2):
	if not can_launch_primary_ability:
		return
	
	can_launch_primary_ability = false
	launch_primary_ability(target)
	await get_tree().create_timer(primary_ability.cooldown).timeout
	can_launch_primary_ability = true

func launch_primary_ability(target: Vector2):
	animated_sprite_2d.play("primary_ability")
	SoundManager.play_tag_at("shoot", primary_ability.sound, global_position, 10)

func try_launch_secondary_ability(target: Vector2):
	if not can_launch_secondary_ability:
		return

	can_launch_secondary_ability = false
	launch_secondary_ability(target)
	await get_tree().create_timer(secondary_ability.cooldown).timeout
	can_launch_secondary_ability = true
	
	return can_launch_secondary_ability

func launch_secondary_ability(target: Vector2):
	if !secondary_ability:
		return
	
	animated_sprite_2d.play("secondary_ability")
	SoundManager.play_tag_at("shoot", secondary_ability.sound, global_position, 10)
