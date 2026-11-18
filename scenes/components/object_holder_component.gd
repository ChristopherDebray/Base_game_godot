extends Node2D

## Tient l'arme active comme enfant du node : gère le remplacement d'une arme par une autre et
## lui applique le masque de collision `hit_mask`.
class_name  ObjectHolderComponent

## Layers que touchent les armes tenues (murs + camp adverse). À régler dans l'inspecteur.
@export_flags_2d_physics var hit_mask: int = CollisionManager.MASK_WALLS

var current_weapon: BaseWeapon

## Équipe `weapon` (ajoutée comme enfant, `hit_mask` appliqué, `setup(muzzle_pos)` appelé) et
## retire l'arme précédente de l'arbre sans la libérer. Renvoie l'arme précédente (ou `null`),
## ou l'arme courante inchangée si `weapon` est déjà équipée.
func switch_weapon(weapon: BaseWeapon, muzzle_pos: Vector2) -> BaseWeapon:
	if weapon == current_weapon:
		return current_weapon
	
	var previous_weapon := current_weapon
	if previous_weapon and previous_weapon.get_parent() == self:
		remove_child(previous_weapon)
	
	add_child(weapon)
	weapon.hit_mask = hit_mask
	current_weapon = weapon
	weapon.setup(muzzle_pos)
	
	return previous_weapon
