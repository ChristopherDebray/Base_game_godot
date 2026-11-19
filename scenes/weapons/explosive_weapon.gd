extends BaseWeapon

## Arme explosive à usage unique (kamikaze) : sa capacité primaire allume une mèche pendant laquelle
## le porteur clignote, puis explose. `primary_ability.damage` est infligé à tout `Damageable` dans
## un rayon `primary_ability.range` autour du porteur (joueur et autres ennemis), puis le porteur
## meurt. Le porteur est le `Damageable` ancêtre de l'arme.
class_name ExplosiveWeapon

const SELF_DESTRUCT_DAMAGE: float = INF
const BLINK_COLOR := Color(1.0, 0.2, 0.2)

## Délai en secondes entre le déclenchement et l'explosion.
@export var fuse_duration: float = 1.0
## Durée en secondes de chaque phase (normal / rouge) du clignotement.
@export var blink_interval: float = 0.1
## Layers touchés par l'explosion. Initialisé dans `_init` car les masques viennent d'un autoload.
@export_flags_2d_physics var blast_mask: int = 0

## Vrai une fois la mèche allumée : l'explosion est alors engagée et ne se relance pas.
var is_armed: bool = false

func _init() -> void:
	blast_mask = CollisionManager.MASK_PLAYER | CollisionManager.MASK_ENEMY

## Allume la mèche (une seule fois) : fait clignoter le porteur, attend `fuse_duration`, puis
## explose. Une fois allumée, la mèche ne s'annule pas si le joueur sort de vue : le porteur s'est
## engagé et explose quand même (voulu). Seule sa mort ou sa libération pendant la mèche annule
## l'explosion, ce qui laisse au joueur une façon de le neutraliser à temps. Sans porteur
## `Damageable`, ne fait rien. `target` est inutilisé : le souffle est centré sur le porteur.
@warning_ignore("unused_parameter")
func launch_primary_ability(target: Vector2) -> void:
	if is_armed:
		return

	var carrier: Damageable = _find_carrier()
	if carrier == null:
		return

	is_armed = true
	_start_blinking(carrier)
	await get_tree().create_timer(fuse_duration).timeout

	if not is_instance_valid(carrier) or carrier.is_queued_for_deletion():
		return

	explode(carrier)

## Blesse de `primary_ability.damage` chaque `Damageable` dans `primary_ability.range` autour de
## `carrier`, puis détruit `carrier` en passant par sa vie pour que `on_death` soit émis comme pour
## toute mort.
func explode(carrier: Damageable) -> void:
	var victims: Array[Damageable] = CollisionManager.get_damageables_in_circle(
		carrier.global_position,
		data.primary_ability.range,
		blast_mask,
		carrier.get_world_2d().direct_space_state,
		[carrier.get_rid()]
	)
	for victim: Damageable in victims:
		victim.take_damage(data.primary_ability.damage)

	carrier.take_damage(SELF_DESTRUCT_DAMAGE)

func _find_carrier() -> Damageable:
	var ancestor: Node = get_parent()
	while ancestor != null:
		if ancestor is Damageable:
			return ancestor as Damageable
		ancestor = ancestor.get_parent()
	return null

func _start_blinking(carrier: Damageable) -> void:
	var tween: Tween = carrier.create_tween().set_loops()
	tween.tween_property(carrier, "modulate", BLINK_COLOR, blink_interval)
	tween.tween_property(carrier, "modulate", Color.WHITE, blink_interval)
