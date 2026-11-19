class_name CollisionManagerTest
extends GdUnitTestSuite

## Teste `CollisionManager.get_damageables_in_circle` avec de vrais corps physiques : rayon,
## masque de collision, exclusion et dédoublonnage d'un corps à plusieurs formes.

const CIRCLE_RADIUS: float = 80.0
const INSIDE_OFFSET := Vector2(40.0, 0.0)
const OUTSIDE_OFFSET := Vector2(200.0, 0.0)
const BODY_SHAPE_RADIUS: float = 4.0
const HEALTH_NAME := "HealthComponent"

## Cible factice : `Damageable` résout son `HealthComponent` par chemin à son `_ready`.
class DamageableDummy extends Damageable:
	func _init() -> void:
		var health: HealthComponent = HealthComponent.new()
		health.name = HEALTH_NAME
		add_child(health)

func test_returns_damageable_inside_radius() -> void:
	var victim: DamageableDummy = await _spawn_body(CollisionManager.MASK_PLAYER, INSIDE_OFFSET, 1)

	var found: Array[Damageable] = _query(CollisionManager.MASK_PLAYER)

	assert_array(found).contains_exactly([victim])

func test_ignores_damageable_outside_radius() -> void:
	await _spawn_body(CollisionManager.MASK_PLAYER, OUTSIDE_OFFSET, 1)

	var found: Array[Damageable] = _query(CollisionManager.MASK_PLAYER)

	assert_array(found).is_empty()

func test_ignores_body_on_layer_outside_mask() -> void:
	await _spawn_body(CollisionManager.MASK_ENEMY, INSIDE_OFFSET, 1)

	var found: Array[Damageable] = _query(CollisionManager.MASK_PLAYER)

	assert_array(found).is_empty()

func test_returns_body_with_several_shapes_only_once() -> void:
	var victim: DamageableDummy = await _spawn_body(CollisionManager.MASK_PLAYER, INSIDE_OFFSET, 2)

	var found: Array[Damageable] = _query(CollisionManager.MASK_PLAYER)

	assert_array(found).contains_exactly([victim])

func test_excludes_given_bodies() -> void:
	var victim: DamageableDummy = await _spawn_body(CollisionManager.MASK_PLAYER, INSIDE_OFFSET, 1)

	var found: Array[Damageable] = CollisionManager.get_damageables_in_circle(
		Vector2.ZERO,
		CIRCLE_RADIUS,
		CollisionManager.MASK_PLAYER,
		get_viewport().world_2d.direct_space_state,
		[victim.get_rid()]
	)

	assert_array(found).is_empty()

func _query(collision_mask: int) -> Array[Damageable]:
	return CollisionManager.get_damageables_in_circle(
		Vector2.ZERO,
		CIRCLE_RADIUS,
		collision_mask,
		get_viewport().world_2d.direct_space_state
	)

## Crée un corps blessable sur le layer `layer_bit` avec `shape_count` formes de collision, puis
## attend que le moteur physique l'ait enregistré (sinon la requête de forme ne le voit pas).
func _spawn_body(layer_bit: int, offset: Vector2, shape_count: int) -> DamageableDummy:
	var body: DamageableDummy = auto_free(DamageableDummy.new())
	for shape_index: int in shape_count:
		var shape_node: CollisionShape2D = CollisionShape2D.new()
		var shape: CircleShape2D = CircleShape2D.new()
		shape.radius = BODY_SHAPE_RADIUS
		shape_node.shape = shape
		body.add_child(shape_node)
	body.collision_layer = layer_bit
	add_child(body)
	body.global_position = offset
	await get_tree().physics_frame
	await get_tree().physics_frame
	return body
