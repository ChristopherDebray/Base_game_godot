extends Node2D

class_name BaseWeapon

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var muzzle: Node2D = $Muzzle

@export var primary_ability: BaseAbility
@export var secondary_ability: BaseAbility = null

func launch_primary_ability(target: Vector2):
	print(primary_ability)
	animated_sprite_2d.play("primary_ability")

func launch_secondary_ability(target: Vector2):
	if !secondary_ability:
		print("no secondary ability")
		return
	
	print(secondary_ability)
	animated_sprite_2d.play("secondary_ability")
