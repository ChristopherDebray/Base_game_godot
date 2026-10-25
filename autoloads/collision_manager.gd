extends Node

const LAYER_CARACTER = 16

# Masques de collision (valeur binaire d'un layer, pas son numéro) : voir [layer_names] dans project.godot.
# Les murs sont sur le layer 1, le joueur sur le layer 3, les ennemis sur le layer 4.
const MASK_WALLS := 1 << 0
const MASK_PLAYER := 1 << 2
const MASK_ENEMY := 1 << 3

## Lance un rayon depuis `from` vers `to`, sur `range` pixels, et renvoie le premier corps touché
## (dictionnaire de `intersect_ray`, vide si rien n'est touché).
## `collision_mask` choisit ce qui peut être touché : c'est ce qui évite qu'un ennemi
## blesse un autre ennemi (voir MASK_*). Par défaut seuls les murs arrêtent le rayon.
func draw_ray_query_to_target(
	to: Vector2,
	from: Vector2,
	range: float,
	space_state: PhysicsDirectSpaceState2D,
	node_from: Node2D,
	collision_mask: int = MASK_WALLS
) -> Dictionary:
	var dir := (to - from).normalized()

	var query := PhysicsRayQueryParameters2D.create(
		from,
		from + dir * range,
		collision_mask
	)
	query.exclude = [node_from]  # évite de se toucher soi-même

	return space_state.intersect_ray(query)
