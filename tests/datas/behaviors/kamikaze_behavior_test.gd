class_name KamikazeBehaviorTest
extends GdUnitTestSuite

## Teste `KamikazeBehavior` : explosion de zone (joueur et autres ennemis touchés, hors rayon épargné,
## kamikaze détruit) et armement unique de la mèche. Le clignotement (rendu) n'est pas testé.

const EXPLOSION_DAMAGE: float = 20.0
const EXPLOSION_RADIUS: float = 80.0
const INSIDE_OFFSET := Vector2(40.0, 0.0)
const OUTSIDE_OFFSET := Vector2(200.0, 0.0)
const BODY_SHAPE_RADIUS: float = 4.0
const SHORT_FUSE_SECONDS: float = 0.05
const LONG_FUSE_SECONDS: float = 60.0
const FUSE_WAIT_MILLISECONDS: int = 300
const HEALTH_NAME := "HealthComponent"

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

## Kamikaze espion : compte les appels à `die` (le vrai `die` fait `queue_free`, inobservable).
class AttackerSpy extends NpcTest.NpcStub:
	var die_call_count: int = 0

	func die() -> void:
		die_call_count += 1

var _behavior: KamikazeBehavior
var _attacker: AttackerSpy

func before_test() -> void:
	_behavior = KamikazeBehavior.new()
	_behavior.damage = EXPLOSION_DAMAGE
	_behavior.explosion_radius = EXPLOSION_RADIUS
	_attacker = auto_free(AttackerSpy.new())
	add_child(_attacker)

func test_explode_damages_player_in_radius() -> void:
	var player_spy: DamageableSpy = await _spawn_victim(CollisionManager.MASK_PLAYER, INSIDE_OFFSET)

	_behavior.explode(_attacker)

	assert_array(player_spy.received_damages).contains_exactly([EXPLOSION_DAMAGE])

func test_explode_damages_other_enemy_in_radius() -> void:
	var enemy_spy: DamageableSpy = await _spawn_victim(CollisionManager.MASK_ENEMY, INSIDE_OFFSET)

	_behavior.explode(_attacker)

	assert_array(enemy_spy.received_damages).contains_exactly([EXPLOSION_DAMAGE])

func test_explode_spares_body_outside_radius() -> void:
	var far_spy: DamageableSpy = await _spawn_victim(CollisionManager.MASK_PLAYER, OUTSIDE_OFFSET)

	_behavior.explode(_attacker)

	assert_array(far_spy.received_damages).is_empty()

func test_explode_kills_the_kamikaze() -> void:
	await get_tree().physics_frame

	_behavior.explode(_attacker)

	assert_int(_attacker.die_call_count).is_equal(1)

func test_perform_attack_arms_the_fuse() -> void:
	_behavior.fuse_duration = LONG_FUSE_SECONDS
	var target: Node2D = auto_free(Node2D.new())

	_behavior.perform_attack(_attacker, target)

	assert_bool(_behavior.is_armed).is_true()

func test_perform_attack_explodes_after_fuse_duration() -> void:
	_behavior.fuse_duration = SHORT_FUSE_SECONDS
	var target: Node2D = auto_free(Node2D.new())

	_behavior.perform_attack(_attacker, target)
	await await_millis(FUSE_WAIT_MILLISECONDS)

	assert_int(_attacker.die_call_count).is_equal(1)

func test_perform_attack_twice_explodes_only_once() -> void:
	_behavior.fuse_duration = SHORT_FUSE_SECONDS
	var target: Node2D = auto_free(Node2D.new())

	_behavior.perform_attack(_attacker, target)
	_behavior.perform_attack(_attacker, target)
	await await_millis(FUSE_WAIT_MILLISECONDS)

	assert_int(_attacker.die_call_count).is_equal(1)

## Crée une victime sur le layer `layer_bit`, à `offset` du kamikaze, et attend que le moteur
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
	victim.global_position = _attacker.global_position + offset
	await get_tree().physics_frame
	await get_tree().physics_frame
	return victim
