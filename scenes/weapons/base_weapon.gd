extends Node2D

class_name BaseWeapon

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

@export var primary_ability: BaseAbility
@export var secondary_ability: BaseAbility = null

func launchPrimaryAbility():
	print(primary_ability)
	animated_sprite_2d.play("primary_ability")

func launchSecondaryAbility():
	if !secondary_ability:
		print("no secondary ability")
		return
	
	print(secondary_ability)
	animated_sprite_2d.play("secondary_ability")
