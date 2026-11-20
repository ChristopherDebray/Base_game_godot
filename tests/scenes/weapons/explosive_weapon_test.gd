class_name ExplosiveWeaponTest
extends GdUnitTestSuite

## Teste `ExplosiveWeapon` : explosion de zone (joueur et autres ennemis touchés, hors rayon
## épargné), mort du porteur, mèche allumée une seule fois et annulée si le porteur meurt avant.
## Le clignotement (rendu) n'est pas testé.

const BLAST_DAMAGE: float = 20.0
const BLAST_RADIUS: float = 80.0
const INSIDE_OFFSET := Vector2(40.0, 0.0)
const OUTSIDE_OFFSET := Vector2(200.0, 0.0)
const BODY_SHAPE_RADIUS: float = 4.0
const SHORT_FUSE_SECONDS: float = 0.05
const LONG_FUSE_SECONDS: float = 60.0
const FUSE_WAIT_MILLISECONDS: int = 300
const HEALTH_NAME := "HealthComponent"
const SPRITE_NODE_NAME := "AnimatedSprite2D"
const MUZZLE_NODE_NAME := "Muzzle"

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

## Porteur espion : compte les appels à `die` (le vrai `die` fait `queue_free`, inobservable).
class CarrierSpy extends NpcTest.NpcStub:
	var die_call_count: int = 0

	func die() -> void:
		die_call_count += 1

var _carrier: CarrierSpy
var _weapon: ExplosiveWeapon

func before_test() -> void:
	_carrier = auto_free(CarrierSpy.new())
	add_child(_carrier)
	_weapon = _build_weapon()
	_weapon.fuse_duration = SHORT_FUSE_SECONDS
	_carrier.add_child(_weapon)

func test_explode_damages_player_in_radius() -> void:
	var victim: DamageableSpy = await _spawn_victim(CollisionManager.MASK_PLAYER, INSIDE_OFFSET)

	_weapon.explode(_carrier)

	assert_array(victim.received_damages).contains_exactly([BLAST_DAMAGE])

func test_explode_damages_other_enemy_in_radius() -> void:
	var victim: DamageableSpy = await _spawn_victim(CollisionManager.MASK_ENEMY, INSIDE_OFFSET)

	_weapon.explode(_carrier)

	assert_array(victim.received_damages).contains_exactly([BLAST_DAMAGE])

func test_explode_spares_body_outside_radius() -> void:
	var victim: DamageableSpy = await _spawn_victim(CollisionManager.MASK_PLAYER, OUTSIDE_OFFSET)

	_weapon.explode(_carrier)

	assert_array(victim.received_damages).is_empty()

func test_explode_kills_the_carrier() -> void:
	await get_tree().physics_frame

	_weapon.explode(_carrier)

	assert_int(_carrier.die_call_count).is_equal(1)

func test_launch_primary_ability_arms_the_fuse() -> void:
	_weapon.fuse_duration = LONG_FUSE_SECONDS

	_weapon.launch_primary_ability(Vector2.ZERO)

	assert_bool(_weapon.is_armed).is_true()

func test_launch_primary_ability_explodes_after_fuse_duration() -> void:
	_weapon.launch_primary_ability(Vector2.ZERO)
	await await_millis(FUSE_WAIT_MILLISECONDS)

	assert_int(_carrier.die_call_count).is_equal(1)

func test_launch_primary_ability_twice_explodes_only_once() -> void:
	_weapon.launch_primary_ability(Vector2.ZERO)
	_weapon.launch_primary_ability(Vector2.ZERO)
	await await_millis(FUSE_WAIT_MILLISECONDS)

	assert_int(_carrier.die_call_count).is_equal(1)

func test_launch_primary_ability_without_carrier_does_not_arm() -> void:
	var lone_weapon: ExplosiveWeapon = _build_weapon()
	add_child(auto_free(lone_weapon))

	lone_weapon.launch_primary_ability(Vector2.ZERO)

	assert_bool(lone_weapon.is_armed).is_false()

func test_carrier_freed_during_fuse_cancels_explosion() -> void:
	var victim: DamageableSpy = await _spawn_victim(CollisionManager.MASK_PLAYER, INSIDE_OFFSET)

	_weapon.launch_primary_ability(Vector2.ZERO)
	_carrier.free()
	await await_millis(FUSE_WAIT_MILLISECONDS)

	assert_array(victim.received_damages).is_empty()

## Arme avec les enfants que `BaseWeapon` résout par chemin (`AnimatedSprite2D`, `Muzzle`).
func _build_weapon() -> ExplosiveWeapon:
	var weapon: ExplosiveWeapon = ExplosiveWeapon.new()
	var sprite: AnimatedSprite2D = AnimatedSprite2D.new()
	sprite.name = SPRITE_NODE_NAME
	weapon.add_child(sprite)
	var muzzle_node: Node2D = Node2D.new()
	muzzle_node.name = MUZZLE_NODE_NAME
	weapon.add_child(muzzle_node)
	weapon.data = _build_weapon_data()
	return weapon

func _build_weapon_data() -> BaseWeaponData:
	var ability: BaseAbilityData = BaseAbilityData.new()
	ability.damage = BLAST_DAMAGE
	ability.range = BLAST_RADIUS
	var weapon_data: BaseWeaponData = BaseWeaponData.new()
	weapon_data.primary_ability = ability
	return weapon_data

## Crée une victime sur le layer `layer_bit` à `offset` du porteur, et attend que le moteur
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
	victim.global_position = _carrier.global_position + offset
	await get_tree().physics_frame
	await get_tree().physics_frame
	return victim
