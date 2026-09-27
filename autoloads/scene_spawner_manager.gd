extends Node

const HIT_PARTICLE = preload("uid://p554j53dng6n")
const POOL_SIZE = 20

var pool: Array[Node2D] = []
var particle_container: Node = null

func setup(container: Node) -> void:
	particle_container = container
	for i in POOL_SIZE:
		var p = HIT_PARTICLE.instantiate()
		p.visible = false
		particle_container.add_child(p)
		pool.append(p)

func spawn_hit_particle(pos: Vector2, rot: float):
	for p in pool:
		if not p.visible:
			p.global_position = pos
			p.rotation = rot
			p.visible = true
			p.restart()
			await get_tree().create_timer(p.lifetime).timeout
			p.visible = false
			return
