class_name FovDetectionComponentTest
extends GdUnitTestSuite

## Tests du FovDetectionComponent (détection du joueur par un champ de vision).
##
## Ce qui est couvert : état de détection, signaux `detect` / `lost`, rejet des corps qui ne sont
## pas le joueur, absence de ligne de vue, nouvelle tentative tant que le joueur reste dans le cône.
## Le raycast réel (« le joueur est vu à travers un espace libre ») n'est pas couvert : il faut un
## vrai `Player`, dont le script exige sa scène complète, et un monde physique. Pour la logique de
## détection, `FovStub` remplace le type de cible et la ligne de vue par des drapeaux.
## Les handlers `_on_body_*` sont câblés dans la scène `.tscn`, pas dans le script : sur un
## composant instancié seul, on les appelle directement.

const LOST_SIGNAL := "lost"
const BODY_POSITION := Vector2(500.0, 0.0)

## Champ de vision dont la cible et la ligne de vue sont pilotées par le test.
class FovStub extends FovDetectionComponent:
	var line_of_sight: bool = false

	func is_detectable(_body: Node2D) -> bool:
		return true

	func has_line_of_sight_to(_body: Node2D) -> bool:
		return line_of_sight


var _component: FovDetectionComponent
# `is_not_emitted` de gdUnit n'écoute qu'À PARTIR du `await` : une émission déjà passée n'est pas vue.
# Pour prouver qu'un signal n'est PAS émis, on le collecte donc dès l'arrivée du composant.
var _detected_bodies: Array[Node2D] = []
var _lost_bodies: Array[Node2D] = []


func before_test() -> void:
	_component = auto_free(FovDetectionComponent.new())
	add_child(_component)
	_detected_bodies.clear()
	_lost_bodies.clear()
	_component.detect.connect(func(body: Node2D) -> void: _detected_bodies.append(body))
	_component.lost.connect(func(body: Node2D) -> void: _lost_bodies.append(body))


func _create_body() -> Node2D:
	var body: Node2D = auto_free(Node2D.new())
	body.global_position = BODY_POSITION
	add_child(body)
	return body


func test_ready_enables_character_layer_detection() -> void:
	assert_bool(_component.get_collision_mask_value(CollisionManager.LAYER_CARACTER)).is_true()


func test_cannot_see_without_detected_body() -> void:
	assert_bool(_component.can_see_detected_body()).is_false()


func test_cannot_see_detected_body_when_ray_hits_nothing() -> void:
	# Aucun corps physique dans le monde : le rayon ne touche rien, donc pas de ligne de vue.
	_component.detected_body = _create_body()

	assert_bool(_component.can_see_detected_body()).is_false()


func test_body_entered_ignores_bodies_that_are_not_the_player() -> void:
	_component._on_body_entered(_create_body())

	assert_array(_detected_bodies).is_empty()


func test_body_entered_with_non_player_body_keeps_detected_body_empty() -> void:
	_component._on_body_entered(_create_body())

	assert_object(_component.detected_body).is_null()


func test_body_exited_emits_lost_with_the_exited_body() -> void:
	var body := _create_body()
	_component.detected_body = body
	monitor_signals(_component, false)

	_component._on_body_exited(body)

	await assert_signal(_component).is_emitted(LOST_SIGNAL, [body])


func test_body_exited_clears_detected_body() -> void:
	var body := _create_body()
	_component.detected_body = body

	_component._on_body_exited(body)

	assert_object(_component.detected_body).is_null()


func test_body_exited_without_detection_emits_nothing() -> void:
	_component._on_body_exited(_create_body())

	assert_array(_lost_bodies).is_empty()


func test_body_exited_twice_emits_lost_only_once() -> void:
	var body := _create_body()
	_component.detected_body = body
	_component._on_body_exited(body)

	_component._on_body_exited(body)

	assert_array(_lost_bodies).has_size(1)


func test_cone_polygon_returns_collision_polygon_points() -> void:
	var cone_points := PackedVector2Array([Vector2(200.0, -90.0), Vector2(200.0, 90.0), Vector2.ZERO])
	var cone_shape := CollisionPolygon2D.new()
	cone_shape.polygon = cone_points
	_component.add_child(cone_shape)

	assert_array(_component.get_cone_polygon()).is_equal(cone_points)


func test_cone_polygon_without_collision_polygon_is_empty() -> void:
	assert_array(_component.get_cone_polygon()).is_empty()


func _create_stub() -> FovStub:
	var stub: FovStub = auto_free(FovStub.new())
	add_child(stub)
	stub.detect.connect(func(body: Node2D) -> void: _detected_bodies.append(body))
	return stub


func test_body_entered_in_line_of_sight_detects_it() -> void:
	var stub := _create_stub()
	stub.line_of_sight = true
	var body := _create_body()

	stub._on_body_entered(body)

	assert_array(_detected_bodies).contains_exactly([body])


func test_body_entered_without_line_of_sight_is_not_detected() -> void:
	var stub := _create_stub()

	stub._on_body_entered(_create_body())

	assert_array(_detected_bodies).is_empty()


func test_body_inside_is_detected_once_line_of_sight_is_gained() -> void:
	# Entré sans ligne de vue (ex. collé à la caméra) puis avancé dans le cône sans en sortir.
	var stub := _create_stub()
	var body := _create_body()
	stub._on_body_entered(body)
	stub.line_of_sight = true

	stub._physics_process(0.0)

	assert_array(_detected_bodies).contains_exactly([body])
	assert_object(stub.detected_body).is_same(body)


func test_body_that_left_unseen_is_not_detected_later() -> void:
	var stub := _create_stub()
	var body := _create_body()
	stub._on_body_entered(body)
	stub._on_body_exited(body)
	stub.line_of_sight = true

	stub._physics_process(0.0)

	assert_array(_detected_bodies).is_empty()


func test_detected_body_is_not_detected_again_each_frame() -> void:
	var stub := _create_stub()
	stub.line_of_sight = true
	stub._on_body_entered(_create_body())

	stub._physics_process(0.0)

	assert_array(_detected_bodies).has_size(1)
