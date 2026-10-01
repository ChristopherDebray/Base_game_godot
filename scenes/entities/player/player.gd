extends Damageable

class_name Player

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var muzzle: Node2D = $Muzzle

@export var light_holder: Node2D

@onready var _9_mm_pistol: BaseWeapon = $"9mmPistol"

const SPEED: float = 130.0
const PROBE_SIZE = Vector2(50, 50)

var facing_direction: Vector2 = Vector2.RIGHT
var facing_position: Vector2

var idle_anim_name := "idle" 
var run_anim_name := "walk" 
var idle_frame_index := 1
# The aim_dir will be set via the aim_component on base_level scene
var aim_dir := Vector2(10, 0)

const LIGHT_RADIANT_OFFSET := deg_to_rad(-90)

# Rotate weapon
## Je veux que l'arme se déplace en direction de la cible directement plutot que juste tourner
## Créer un block et mettre l'arme dedans, rotate le block, pas l'arme
## Problèmes
### On ser retrouves avec un node en plus et aussi il faut gérer l'offset à la main pr chaque.
## Solutions
### Faire en sorte uqe lors de l'init de l'arme, tu initialise l'offset à la position du muzzle
### Pour le sprite de l'arme

func _ready() -> void:
	_9_mm_pistol.setup(muzzle.position)

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
	_9_mm_pistol.aim_at(aim_dir)
	facing_position = global_position - aim_dir

func get_movement_input() -> void:
	var nv: Vector2 = Vector2.ZERO
	# Returns a value from 0 to 1, depending on the "strength" used mostly for controllers
	nv.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	nv.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	velocity = nv.normalized() * SPEED

func get_actions_input():
	if Input.is_action_just_released("primary_ability"):
		_9_mm_pistol.try_launch_primary_ability(aim_dir)

func _update_facing() -> void:
	if facing_position.x < -0.05:
		flip_facing(false)
		_9_mm_pistol.flip_weapon(false)
	elif facing_position.x > 0.05:
		flip_facing(true)
		_9_mm_pistol.flip_weapon(true)
	
func flip_facing(must_reverse_flip: bool):
	animated_sprite_2d.flip_h = must_reverse_flip
	if must_reverse_flip:
		facing_direction = Vector2.LEFT
		return
	facing_direction = Vector2.RIGHT

func _update_anim() -> void:
	# seuil pour éviter de “jouer/arrêter” quand la vitesse est quasi nulle
	var moving := velocity.length_squared() > 1.0
	#move_toward()

	if moving:
		if animated_sprite_2d.animation != run_anim_name or !animated_sprite_2d.is_playing():
			animated_sprite_2d.play(run_anim_name)
	else:
		animated_sprite_2d.play(idle_anim_name)
