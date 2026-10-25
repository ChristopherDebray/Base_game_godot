extends Damageable

class_name Player

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var muzzle: Node2D = $Muzzle

@export var light_holder: Node2D
@export var inventory_ui: Inventory

@onready var object_holder_component: ObjectHolderComponent = $ObjectHolderComponent
@onready var objects_holder_component: ObjectsHolderComponent = $ObjectsHolderComponent

const PISTOL_DATA = preload("uid://ddwe31sqyyulb")
const MACHINE_GUN_DATA = preload("uid://dqw2hvpvfgwgr")
const T = BaseItemData.ITEM_TYPE

const SPEED: float = 130.0
const PROBE_SIZE = Vector2(50, 50)

var is_dead := false
var facing_direction: Vector2 = Vector2.RIGHT
var facing_position: Vector2

var idle_anim_name := "idle" 
var run_anim_name := "walk" 
var idle_frame_index := 1
# The aim_dir will be set via the aim_component on base_level scene
var aim_dir := Vector2(10, 0)

var bag := InventoryModel.with_size(20)
var armor := InventoryModel.new([[T.HEAD], [T.CHEST], [T.FEET], [T.BACK]])
var weapons := InventoryModel.new([[T.PRIMARY], [T.SECONDARY], [T.GADGET], [T.GADGET]])

func _ready() -> void:
	objects_holder_component.bind(weapons)
	# s'équipe tout seul via le signal
	weapons.set_item(0, ItemInstance.new(PISTOL_DATA))
	weapons.set_item(1, ItemInstance.new(MACHINE_GUN_DATA))

## Le joueur n'est pas libéré à sa mort (la caméra et la visée en dépendent) :
## on le désactive et on prévient le reste du jeu.
func die() -> void:
	if is_dead:
		return
	is_dead = true
	set_physics_process(false)
	velocity = Vector2.ZERO
	hide()
	collision_shape_2d.set_deferred("disabled", true)
	SignalManager.on_player_died.emit()

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
	
	if Input.is_action_just_released("open_bag"):
		inventory_ui.open(bag, armor, weapons)


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
