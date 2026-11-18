extends Node2D

## Base d'une arme tenue : gère la visée (rotation/retournement du sprite), les munitions, le
## rechargement et les cooldowns des capacités. Les sous-classes implémentent le tir réel
## (voir `ProjectileWeapon`). `data` est injecté par `ItemInstance.get_scene`.
class_name BaseWeapon

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var muzzle: Node2D = $Muzzle

# La data est injectée lors de l'instanciation / setup dans item_instance sur get_scene
var data: BaseWeaponData

## Layers que les tirs de cette arme peuvent toucher. Réglé par le porteur (ObjectHolderComponent)
## à l'équipement, pour qu'un ennemi ne touche que le joueur et inversement.
var hit_mask: int = CollisionManager.MASK_WALLS

var can_launch_primary_ability: bool = true
var can_launch_secondary_ability: bool = true

var init_sprite_position_x: float
var init_muzzle_position_x: float

var current_ammunition: int
var is_reloading: bool = false

## Décale le sprite et la bouche (`Muzzle`) horizontalement de `muzzle_position.x` (offset du
## porteur) et recharge complètement l'arme. À appeler une fois l'arme ajoutée à son porteur.
func setup(muzzle_position: Vector2) -> void:
	init_sprite_position_x = muzzle_position.x
	init_muzzle_position_x = muzzle.position.x + muzzle_position.x
	
	animated_sprite_2d.position.x = muzzle_position.x
	muzzle.position.x = muzzle.position.x + muzzle_position.x
	
	current_ammunition = data.max_ammunitions

## Oriente l'arme vers le point monde `aim_dir` et règle son `position.y` à dix fois
## l'angle de visée (décalage visuel empirique ; le rôle exact de ce facteur n'est pas documenté).
func aim_at(aim_dir: Vector2) -> void:
	look_at(aim_dir)
	var aim_dir_angle := aim_dir.angle() * 10
	position.y = aim_dir_angle

## Retourne verticalement le sprite quand le porteur regarde vers la gauche, pour qu'il
## ne soit pas à l'envers une fois l'arme tournée.
func flip_weapon(must_reverse_flip: bool) -> void:
	animated_sprite_2d.flip_v = must_reverse_flip

## Tire la capacité primaire vers `target` si l'arme n'est pas en rechargement ni en cooldown.
## Sans munition, déclenche un rechargement à la place. Le cooldown est attendu (`await`) avant
## de réautoriser le tir.
func try_launch_primary_ability(target: Vector2) -> void:
	if is_reloading:
		return

	if not can_launch_primary_ability:
		return

	if current_ammunition == 0:
		reload()
		return
	
	can_launch_primary_ability = false
	launch_primary_ability(target)
	await get_tree().create_timer(data.primary_ability.cooldown).timeout
	can_launch_primary_ability = true

## Effet du tir primaire : animation, son, consomme une munition. Les sous-classes surchargent
## cette méthode pour appliquer l'effet réel vers `target` (non utilisé ici).
func launch_primary_ability(target: Vector2) -> void:
	animated_sprite_2d.play("primary_ability")
	SoundManager.play_tag_at("shoot", data.primary_ability.sound, global_position, 10)
	current_ammunition -= 1

## Tire la capacité secondaire vers `target` si elle n'est pas en cooldown, puis attend son
## cooldown avant de la réautoriser.
func try_launch_secondary_ability(target: Vector2) -> void:
	if not can_launch_secondary_ability:
		return

	can_launch_secondary_ability = false
	launch_secondary_ability(target)
	await get_tree().create_timer(data.secondary_ability.cooldown).timeout
	can_launch_secondary_ability = true

## Effet du tir secondaire : animation et son. Sans effet si l'arme n'a pas de capacité
## secondaire. `target` n'est pas utilisé ici (prévu pour les sous-classes).
func launch_secondary_ability(target: Vector2) -> void:
	if !data.secondary_ability:
		return
	
	animated_sprite_2d.play("secondary_ability")
	SoundManager.play_tag_at("shoot", data.secondary_ability.sound, global_position, 10)

## Même orientation que `aim_at` pour le point monde `dir`.
func set_aim_dir(dir: Vector2) -> void:
	look_at(dir)
	var aim_dir_angle := dir.angle() * 10
	position.y = aim_dir_angle

## Remplit immédiatement le chargeur, bloque le tir (`is_reloading`) et joue l'animation et le son
## de rechargement. `is_reloading` repasse à `false` à la fin de l'animation "reload".
func reload() -> void:
	current_ammunition = data.max_ammunitions
	is_reloading = true
	animated_sprite_2d.play("reload")
	SoundManager.play_tag_at("reload", data.primary_ability.reload_sound, global_position, 10)

## Réagit à un impact en `position` : joue la particule d'impact et inflige `damage` si
## `collider` est un `Damageable`. `normal` n'est pas utilisé pour l'instant.
func hit_trigger(damage: float, position: Vector2, normal: Vector2, collider: Variant) -> void:
	SceneSpawnerManager.spawn_hit_particle(position, 0)
	if collider is Damageable:
		collider.take_damage(damage)

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite_2d.animation != "reload":
		return
	
	is_reloading = false
