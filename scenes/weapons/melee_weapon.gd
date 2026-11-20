extends BaseWeapon

## Arme de corps à corps : sa capacité primaire frappe tous les `Damageable` dans un cercle autour
## de l'arme, de rayon `primary_ability.range`, filtrés par `hit_mask`. Pas de visée ni de
## projectile : au contact, la direction du coup importe peu.
class_name MeleeWeapon

## Joue l'effet de base (animation, son) puis inflige `primary_ability.damage` aux cibles à portée.
## La munition consommée par le tir de base est rendue : un coup de poing ne se recharge pas.
func launch_primary_ability(target: Vector2) -> void:
	super.launch_primary_ability(target)
	current_ammunition = data.max_ammunitions

	var victims: Array[Damageable] = CollisionManager.get_damageables_in_circle(
		global_position,
		data.primary_ability.range,
		hit_mask,
		get_world_2d().direct_space_state
	)
	for victim: Damageable in victims:
		hit_trigger(data.primary_ability.damage, victim.global_position, Vector2.ZERO, victim)
