extends Node

const HIT_PARTICLE = preload("uid://p554j53dng6n")
const DEATH_PARTICLE = preload("uid://dy17d1da57hic")
const HIT_PARTICLES_POOL_SIZE = 20
const DEATH_PARTICLES_POOL_SIZE = 5

var hit_particles_pool: Array[Node2D] = []
var death_particles_pool: Array[Node2D] = []
var particle_container: Node = null

## Initialise les pools de particules (cachées) dans `container`, typiquement le viewport du
## niveau. À rappeler à chaque chargement de niveau : les pools sont réinitialisés.
func setup(container: Node) -> void:
	particle_container = container
	# Le niveau peut être rechargé : les anciennes particules ont été libérées avec lui.
	hit_particles_pool.clear()
	death_particles_pool.clear()
	_setup_hit_particles(container)
	_setup_death_particles(container)
	
func _setup_hit_particles(container: Node) -> void:
	for i in HIT_PARTICLES_POOL_SIZE:
		var particle := HIT_PARTICLE.instantiate() as CPUParticles2D
		particle.visible = false
		particle_container.add_child(particle)
		hit_particles_pool.append(particle)

func _setup_death_particles(container: Node) -> void:
	for i in DEATH_PARTICLES_POOL_SIZE:
		var particle := DEATH_PARTICLE.instantiate() as CPUParticles2D
		particle.visible = false
		particle_container.add_child(particle)
		death_particles_pool.append(particle)

## Joue une particule d'impact libre du pool en `pos` avec la rotation `rot`, puis la recache à la
## fin de sa durée de vie. Sans effet si toutes les particules du pool sont déjà utilisées.
func spawn_hit_particle(pos: Vector2, rot: float) -> void:
	for particle in hit_particles_pool:
		if not particle.visible:
			particle.global_position = pos
			particle.rotation = rot
			particle.visible = true
			particle.restart()
			await get_tree().create_timer(particle.lifetime).timeout
			# Le niveau a pu être rechargé pendant l'attente.
			if is_instance_valid(particle):
				particle.visible = false
			return

## Joue une particule de mort libre du pool en `pos`, puis la recache à la fin de sa durée de vie.
## Sans effet si toutes les particules du pool sont déjà utilisées.
func spawn_death_particle(pos: Vector2) -> void:
	for particle in death_particles_pool:
		if not particle.visible:
			particle.global_position = pos
			particle.visible = true
			particle.restart()
			await get_tree().create_timer(particle.lifetime).timeout
			# Le niveau a pu être rechargé pendant l'attente.
			if is_instance_valid(particle):
				particle.visible = false
			return
