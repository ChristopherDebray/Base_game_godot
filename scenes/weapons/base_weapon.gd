extends Node2D

class_name BaseWeapon

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var muzzle: Node2D = $Muzzle

@export var primary_ability: BaseAbility
@export var secondary_ability: BaseAbility = null
@export var max_ammunitions: int
@export var fire_rate: float = 0.15  # secondes entre 2 tirs

var can_launch_primary_ability: bool = true
var can_launch_secondary_ability: bool = true

var init_sprite_position_x: float
var init_muzzle_position_x: float

var current_ammunition: int
var is_reloading: bool = false

func setup(muzzle_position: Vector2):
	init_sprite_position_x = muzzle_position.x
	init_muzzle_position_x = muzzle.position.x + muzzle_position.x
	
	animated_sprite_2d.position.x = muzzle_position.x
	muzzle.position.x = muzzle.position.x + muzzle_position.x
	
	current_ammunition = max_ammunitions

func aim_at(aim_dir: Vector2):
	look_at(aim_dir)
	var aim_dir_angle = aim_dir.angle() * 10
	position.y = aim_dir_angle

func flip_weapon(must_reverse_flip: bool):
	animated_sprite_2d.flip_v = must_reverse_flip

func try_launch_primary_ability(target: Vector2):
	if is_reloading:
		return

	if not can_launch_primary_ability:
		return

	if current_ammunition == 0:
		reload()
		return
	
	can_launch_primary_ability = false
	launch_primary_ability(target)
	await get_tree().create_timer(primary_ability.cooldown).timeout
	can_launch_primary_ability = true

func launch_primary_ability(target: Vector2):
	animated_sprite_2d.play("primary_ability")
	SoundManager.play_tag_at("shoot", primary_ability.sound, global_position, 10)
	current_ammunition -= 1

func try_launch_secondary_ability(target: Vector2):
	if not can_launch_secondary_ability:
		return

	can_launch_secondary_ability = false
	launch_secondary_ability(target)
	await get_tree().create_timer(secondary_ability.cooldown).timeout
	can_launch_secondary_ability = true
	
	return can_launch_secondary_ability

func launch_secondary_ability(target: Vector2):
	if !secondary_ability:
		return
	
	animated_sprite_2d.play("secondary_ability")
	SoundManager.play_tag_at("shoot", secondary_ability.sound, global_position, 10)

func set_aim_dir(dir: Vector2):
	look_at(dir)
	var aim_dir_angle = dir.angle() * 10
	position.y = aim_dir_angle

func reload():
	current_ammunition = max_ammunitions
	is_reloading = true
	animated_sprite_2d.play("reload")
	SoundManager.play_tag_at("reload", primary_ability.reload_sound, global_position, 10)

func hit_trigger(damage: float, position: Vector2, normal: Vector2, collider: Variant):
	SceneSpawnerManager.spawn_hit_particle(position, 0)
	if is_instance_of(collider, Npc):
		var npc: Npc = collider
		npc.health_component.apply_damage(damage)

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite_2d.animation != "reload":
		return
	
	is_reloading = false
