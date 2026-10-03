extends Node2D

class_name  WeaponHolderComponent

var current_weapon: BaseWeapon

func switch_weapon(weapon: BaseWeapon, muzzle_pos: Vector2) -> BaseWeapon:
	var previous_weapon = current_weapon
	remove_child(current_weapon)

	add_child(weapon)
	current_weapon = weapon
	current_weapon.setup(muzzle_pos)
	
	return previous_weapon
