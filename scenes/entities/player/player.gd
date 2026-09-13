extends CharacterBody2D

class_name Player

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var muzzle: Node2D = $Muzzle

@export var light_holder: Node2D

@onready var _9_mm_pistol: BaseWeapon = $"9mmPistol"

const SPEED: float = 130.0
const PROBE_SIZE = Vector2(50, 50)
const MUZZLE_INVERTION_POS: float = -10
const BOX = preload("uid://crheon3n34s26")

var facing_direction: Vector2 = Vector2.RIGHT
var facing_position: Vector2

var muzzle_initial_position: float = 27
var idle_anim_name := "idle" 
var run_anim_name := "walk" 
var idle_frame_index := 1
# The aim_dir will be set via the aim_component on base_level scene
var aim_dir := Vector2(10, 0)

const LIGHT_RADIANT_OFFSET := deg_to_rad(-90)

func _ready() -> void:
	return

func _physics_process(delta: float) -> void:
	var transform = Transform2D()
	transform = transform.translated(-global_position + PROBE_SIZE/2)
	
	get_movement_input()
	get_actions_input()
	move_and_slide()
	_update_facing()
	_update_anim()

func set_aim_dir(dir: Vector2):
	aim_dir = dir
	_9_mm_pistol.look_at(aim_dir)
	facing_position = global_position - aim_dir

func get_movement_input() -> void:
	var nv: Vector2 = Vector2.ZERO
	# Returns a value from 0 to 1, depending on the "strength" used mostly for controllers
	nv.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	nv.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	velocity = nv.normalized() * SPEED

func get_actions_input():
	if Input.is_action_just_released("primary_ability"):
		var box = BOX.instantiate()
		box.global_position = aim_dir
		get_tree().current_scene.add_child(box)
		

func _update_facing() -> void:
	if facing_position.x < -0.05:
		animated_sprite_2d.flip_h = false
		muzzle.position.x = muzzle_initial_position
		facing_direction = Vector2.RIGHT
	elif facing_position.x > 0.05:
		animated_sprite_2d.flip_h = true
		muzzle.position.x = MUZZLE_INVERTION_POS
		facing_direction = Vector2.LEFT

func _update_anim() -> void:
	# seuil pour éviter de “jouer/arrêter” quand la vitesse est quasi nulle
	var moving := velocity.length_squared() > 1.0
	#move_toward()

	if moving:
		if animated_sprite_2d.animation != run_anim_name or !animated_sprite_2d.is_playing():
			animated_sprite_2d.play(run_anim_name)
	else:
		animated_sprite_2d.play(idle_anim_name)
