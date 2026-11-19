## Combat kamikaze : à portée, l'ennemi clignote pendant `fuse_duration` puis explose, blessant
## tous les `Damageable` (joueur et autres ennemis) dans `explosion_radius`, et meurt.
class_name KamikazeBehavior
extends CombatBehavior

const DEFAULT_KAMIKAZE_ENGAGEMENT_RANGE: float = 48.0
const SELF_DESTRUCT_DAMAGE: float = INF
const BLINK_COLOR := Color(1.0, 0.2, 0.2)

@export var damage: float = 20.0
@export var explosion_radius: float = 80.0
## Délai en secondes entre le déclenchement et l'explosion.
@export var fuse_duration: float = 1.0
## Durée en secondes de chaque phase (normal / rouge) du clignotement.
@export var blink_interval: float = 0.1
## Layers touchés par l'explosion. Initialisé dans `_init` car les masques viennent d'un autoload.
@export_flags_2d_physics var explosion_mask: int = 0

## Vrai une fois la mèche allumée : l'attaque est alors engagée et ne se relance pas.
var is_armed: bool = false

func _init() -> void:
	engagement_range = DEFAULT_KAMIKAZE_ENGAGEMENT_RANGE
	explosion_mask = CollisionManager.MASK_PLAYER | CollisionManager.MASK_ENEMY

## Allume la mèche (une seule fois) : fait clignoter `attacker`, attend `fuse_duration`, puis
## explose. Une fois allumée, la mèche ne s'annule pas si le joueur sort de vue : le kamikaze
## s'est engagé et explose quand même (voulu). Seule sa mort ou sa libération pendant la mèche
## annule l'explosion, ce qui laisse au joueur une façon de le neutraliser à temps.
## `target` est inutilisé : l'explosion est centrée sur le kamikaze, pas sur la cible.
@warning_ignore("unused_parameter")
func perform_attack(attacker: Npc, target: Node2D) -> void:
	if is_armed:
		return

	is_armed = true
	_start_blinking(attacker)
	await attacker.get_tree().create_timer(fuse_duration).timeout

	if not is_instance_valid(attacker) or attacker.is_queued_for_deletion():
		return

	explode(attacker)

## Blesse de `damage` chaque `Damageable` dans `explosion_radius` autour de `attacker` (une seule
## fois par corps, même s'il a plusieurs formes de collision), puis détruit `attacker` en passant
## par sa vie pour que `on_death` soit émis comme pour toute mort.
func explode(attacker: Npc) -> void:
	for victim: Damageable in _find_victims(attacker):
		victim.take_damage(damage)

	attacker.take_damage(SELF_DESTRUCT_DAMAGE)

func _find_victims(attacker: Npc) -> Array[Damageable]:
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = explosion_radius

	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, attacker.global_position)
	query.collision_mask = explosion_mask
	query.exclude = [attacker.get_rid()]

	var hits: Array[Dictionary] = attacker.get_world_2d().direct_space_state.intersect_shape(query)
	var victims: Array[Damageable] = []
	for hit: Dictionary in hits:
		var victim: Damageable = hit.collider as Damageable
		if victim != null and not victims.has(victim):
			victims.append(victim)
	return victims

func _start_blinking(attacker: Npc) -> void:
	var tween: Tween = attacker.create_tween().set_loops()
	tween.tween_property(attacker.animated_sprite_2d, "modulate", BLINK_COLOR, blink_interval)
	tween.tween_property(attacker.animated_sprite_2d, "modulate", Color.WHITE, blink_interval)
