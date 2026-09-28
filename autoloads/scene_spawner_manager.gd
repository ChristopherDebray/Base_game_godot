extends Node

const HIT_PARTICLE = preload("uid://p554j53dng6n")
const DEATH_PARTICLE = preload("uid://dy17d1da57hic")
const HIT_PARTICLES_POOL_SIZE = 20
const DEATH_PARTICLES_POOL_SIZE = 5

var hit_particles_pool: Array[Node2D] = []
var death_particles_pool: Array[Node2D] = []
var particle_container: Node = null

func setup(container: Node) -> void:
	particle_container = container
	_setup_hit_particles(container)
	_setup_death_particles(container)
	
func _setup_hit_particles(container: Node) -> void:
	for i in HIT_PARTICLES_POOL_SIZE:
		var p = HIT_PARTICLE.instantiate()
		p.visible = false
		particle_container.add_child(p)
		hit_particles_pool.append(p)

func _setup_death_particles(container: Node) -> void:
	for i in DEATH_PARTICLES_POOL_SIZE:
		var p = DEATH_PARTICLE.instantiate()
		p.visible = false
		particle_container.add_child(p)
		death_particles_pool.append(p)

func spawn_hit_particle(pos: Vector2, rot: float):
	for p in hit_particles_pool:
		if not p.visible:
			p.global_position = pos
			p.rotation = rot
			p.visible = true
			p.restart()
			await get_tree().create_timer(p.lifetime).timeout
			p.visible = false
			return

func spawn_death_particle(pos: Vector2):
	for p in death_particles_pool:
		if not p.visible:
			p.global_position = pos
			p.visible = true
			p.restart()
			await get_tree().create_timer(p.lifetime).timeout
			p.visible = false
			return
