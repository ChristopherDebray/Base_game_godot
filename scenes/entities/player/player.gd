extends Damageable

class_name Player

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var muzzle: Node2D = $Muzzle

@export var light_holder: Node2D

@onready var object_holder_component: ObjectHolderComponent = $ObjectHolderComponent
@onready var objects_holder_component: ObjectsHolderComponent = $ObjectsHolderComponent

const _9_MM_PISTOL = preload("uid://du8sytr0jrmyu")
const MACHINE_GUN = preload("uid://0q4gltcb58aj")

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

func _ready() -> void:
	#object_holder_component.switch_weapon(_9_MM_PISTOL.instantiate(), muzzle.position)
	objects_holder_component.set_object_at(0, _9_MM_PISTOL.instantiate())
	objects_holder_component.set_object_at(1, MACHINE_GUN.instantiate())

func _physics_process(delta: float) -> void:
	var transform = Transform2D()
	transform = transform.translated(-global_position + PROBE_SIZE/2)
	
	get_movement_inputs()
	get_action_inputs()
	get_object_selection_inputs()
	move_and_slide()
	_update_facing()
	_update_anim()

func set_aim_dir(dir: Vector2):
	aim_dir = dir
	object_holder_component.current_weapon.aim_at(aim_dir)
	facing_position = global_position - aim_dir

func get_movement_inputs() -> void:
	var nv: Vector2 = Vector2.ZERO
	# Returns a value from 0 to 1, depending on the "strength" used mostly for controllers
	nv.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	nv.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	velocity = nv.normalized() * SPEED

func get_action_inputs():
	if Input.is_action_just_released("primary_ability"):
		object_holder_component.current_weapon.try_launch_primary_ability(aim_dir)
	
	if Input.is_action_just_released("reload"):
		object_holder_component.current_weapon.reload()


func get_object_selection_inputs():
	# TODO use better naming with primary / secondary weapon ?
	if Input.is_action_just_released("get_object_1"):
		objects_holder_component.set_holded_object_to(0)
	
	if Input.is_action_just_released("get_object_2"):
		objects_holder_component.set_holded_object_to(1)
	
	if Input.is_action_just_released("get_object_3"):
		objects_holder_component.set_holded_object_to(2)
	
	if Input.is_action_just_released("next_object"):
		objects_holder_component.set_holded_object_to_next()
	
	if Input.is_action_just_released("previous_object"):
		objects_holder_component.set_holded_object_to_previous()

func _update_facing() -> void:
	if facing_position.x < -0.05:
		flip_facing(false)
		object_holder_component.current_weapon.flip_weapon(false)
	elif facing_position.x > 0.05:
		flip_facing(true)
		object_holder_component.current_weapon.flip_weapon(true)
	
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
