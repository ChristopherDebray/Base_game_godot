extends Node2D

class_name  ObjectHolderComponent

var current_weapon: BaseWeapon

func switch_weapon(weapon: BaseWeapon, muzzle_pos: Vector2) -> BaseWeapon:
	if weapon == current_weapon:
		return current_weapon
	
	var previous_weapon := current_weapon
	if previous_weapon and previous_weapon.get_parent() == self:
		remove_child(previous_weapon)
	
	add_child(weapon)
	current_weapon = weapon
	weapon.setup(muzzle_pos)
	
	return previous_weapon
