class_name AlertZoneComponentTest
extends GdUnitTestSuite

## Tests de l'AlertZoneComponent (zone circulaire qui alerte les `Npc` vers une position).
##
## Les handlers `_on_body_entered` sont câblés dans le `.tscn` : sur un composant instancié seul,
## on les appelle directement. `alert()` lit `get_overlapping_bodies()`, qui dépend du moteur
## physique : il est couvert avec de vrais corps et une attente de frames physiques.

const TARGET_POSITION := Vector2(300.0, 200.0)
const OTHER_TARGET_POSITION := Vector2(-50.0, 70.0)
const ZONE_RADIUS := 100.0
const BODY_SIZE := Vector2(10.0, 10.0)

## Npc (stub de `NpcTest`, sans scène) qui enregistre les alertes reçues.
class NpcSpy extends NpcTest.NpcStub:
	var alerted_positions: Array[Vector2] = []

	func alert_to(target_position: Vector2) -> void:
		alerted_positions.append(target_position)


var _zone: AlertZoneComponent


func before_test() -> void:
	_zone = auto_free(AlertZoneComponent.new())
	_zone.radius = ZONE_RADIUS
	add_child(_zone)


func _create_npc_in_zone() -> NpcSpy:
	var npc: NpcSpy = auto_free(NpcSpy.new())
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = BODY_SIZE
	shape.shape = rectangle
	npc.add_child(shape)
	npc.collision_layer = CollisionManager.MASK_ENEMY
	add_child(npc)
	return npc


func test_alert_reaches_npc_inside_zone() -> void:
	var npc: NpcSpy = _create_npc_in_zone()
	await get_tree().physics_frame
	await get_tree().physics_frame

	_zone.alert(TARGET_POSITION)

	assert_array(npc.alerted_positions).contains_exactly([TARGET_POSITION])


func test_npc_entering_with_active_target_is_alerted() -> void:
	var npc: NpcSpy = _create_npc_in_zone()
	_zone.set_target(TARGET_POSITION)

	_zone._on_body_entered(npc)

	assert_array(npc.alerted_positions).contains_exactly([TARGET_POSITION])


func test_npc_entering_without_target_is_not_alerted() -> void:
	var npc: NpcSpy = _create_npc_in_zone()

	_zone._on_body_entered(npc)

	assert_array(npc.alerted_positions).is_empty()


func test_npc_entering_after_clear_target_is_not_alerted() -> void:
	var npc: NpcSpy = _create_npc_in_zone()
	_zone.set_target(TARGET_POSITION)
	_zone.clear_target()

	_zone._on_body_entered(npc)

	assert_array(npc.alerted_positions).is_empty()


func test_npc_entering_uses_latest_target() -> void:
	var npc: NpcSpy = _create_npc_in_zone()
	_zone.set_target(TARGET_POSITION)
	_zone.set_target(OTHER_TARGET_POSITION)

	_zone._on_body_entered(npc)

	assert_array(npc.alerted_positions).contains_exactly([OTHER_TARGET_POSITION])
