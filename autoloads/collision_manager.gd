extends Node

const LAYER_CARACTER = 16

func draw_ray_query_to_target(
	to: Vector2,
	from: Vector2,
	range: float,
	space_state : PhysicsDirectSpaceState2D,
	node_from: Node2D
):
	var dir = (to - from).normalized()

	var query = PhysicsRayQueryParameters2D.create(
		from,
		from + dir * range
	)
	query.exclude = [node_from]  # évite de se toucher soi-même

	return space_state.intersect_ray(query)
