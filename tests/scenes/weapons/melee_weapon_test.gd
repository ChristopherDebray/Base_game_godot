class_name MeleeWeaponTest
extends GdUnitTestSuite

## Teste `MeleeWeapon.launch_primary_ability` : dégâts de la capacité primaire sur les `Damageable`
## à portée (filtrés par `hit_mask`) et absence de consommation de munition. Animation, son et
## particules d'impact ne sont pas testés.

const MELEE_DAMAGE: float = 5.0
const MELEE_RANGE: float = 30.0
const INSIDE_OFFSET := Vector2(15.0, 0.0)
const OUTSIDE_OFFSET := Vector2(120.0, 0.0)
const BODY_SHAPE_RADIUS: float = 4.0
const PRIMARY_ANIMATION := "primary_ability"
const SPRITE_NODE_NAME := "AnimatedSprite2D"
const MUZZLE_NODE_NAME := "Muzzle"
const HEALTH_NAME := "HealthComponent"
const MAX_AMMUNITION: int = 1

## Cible espion : mémorise les dégâts reçus. Porte un `HealthComponent` factice car `Damageable`
## le résout par chemin à son `_ready`.
class DamageableSpy extends Damageable:
	var received_damages: Array[float] = []

	func _init() -> void:
		var health: HealthComponent = HealthComponent.new()
		health.name = HEALTH_NAME
		add_child(health)

	func take_damage(amount: float) -> void:
		received_damages.append(amount)

var _weapon: MeleeWeapon

func before_test() -> void:
	_weapon = auto_free(MeleeWeapon.new())
	var sprite: AnimatedSprite2D = AnimatedSprite2D.new()
	sprite.name = SPRITE_NODE_NAME
	var frames: SpriteFrames = SpriteFrames.new()
	frames.add_animation(PRIMARY_ANIMATION)
	sprite.sprite_frames = frames
	_weapon.add_child(sprite)
	var muzzle_node: Node2D = Node2D.new()
	muzzle_node.name = MUZZLE_NODE_NAME
	_weapon.add_child(muzzle_node)
	_weapon.data = _build_weapon_data()
	_weapon.hit_mask = CollisionManager.MASK_PLAYER
	_weapon.current_ammunition = MAX_AMMUNITION
	add_child(_weapon)

func test_launch_primary_ability_damages_target_in_range() -> void:
	var victim: DamageableSpy = await _spawn_victim(CollisionManager.MASK_PLAYER, INSIDE_OFFSET)

	_weapon.launch_primary_ability(Vector2.ZERO)

	assert_array(victim.received_damages).contains_exactly([MELEE_DAMAGE])

func test_launch_primary_ability_spares_target_out_of_range() -> void:
	var victim: DamageableSpy = await _spawn_victim(CollisionManager.MASK_PLAYER, OUTSIDE_OFFSET)

	_weapon.launch_primary_ability(Vector2.ZERO)

	assert_array(victim.received_damages).is_empty()

func test_launch_primary_ability_spares_target_outside_hit_mask() -> void:
	var victim: DamageableSpy = await _spawn_victim(CollisionManager.MASK_ENEMY, INSIDE_OFFSET)

	_weapon.launch_primary_ability(Vector2.ZERO)

	assert_array(victim.received_damages).is_empty()

func test_launch_primary_ability_does_not_consume_ammunition() -> void:
	_weapon.launch_primary_ability(Vector2.ZERO)

	assert_int(_weapon.current_ammunition).is_equal(MAX_AMMUNITION)

func _build_weapon_data() -> BaseWeaponData:
	var ability: BaseAbilityData = BaseAbilityData.new()
	ability.damage = MELEE_DAMAGE
	ability.range = MELEE_RANGE
	var weapon_data: BaseWeaponData = BaseWeaponData.new()
	weapon_data.primary_ability = ability
	weapon_data.max_ammunitions = MAX_AMMUNITION
	return weapon_data

## Crée une victime sur le layer `layer_bit` à `offset` de l'arme, et attend que le moteur
## physique l'ait enregistrée (sinon la requête de forme ne la voit pas).
func _spawn_victim(layer_bit: int, offset: Vector2) -> DamageableSpy:
	var victim: DamageableSpy = auto_free(DamageableSpy.new())
	var shape_node: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = BODY_SHAPE_RADIUS
	shape_node.shape = shape
	victim.add_child(shape_node)
	victim.collision_layer = layer_bit
	add_child(victim)
	victim.global_position = _weapon.global_position + offset
	await get_tree().physics_frame
	await get_tree().physics_frame
	return victim
