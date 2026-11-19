class_name SurveillanceCameraTest
extends GdUnitTestSuite

## Tests de la SurveillanceCamera : elle relie le champ de vision à la zone d'alerte.
##
## Les trois composants sont injectés par `@export` (pas de scène) ; la zone est un espion qui
## enregistre les appels reçus. On déclenche la détection en émettant les signaux du champ de vision.

const PLAYER_POSITION := Vector2(150.0, 40.0)
const MOVED_PLAYER_POSITION := Vector2(220.0, -10.0)
const CONE_POINTS: PackedVector2Array = [Vector2(200.0, -90.0), Vector2(200.0, 90.0), Vector2.ZERO]
# Orientation de départ non nulle : le balayage doit osciller autour d'elle, pas autour de zéro.
const BASE_ROTATION_DEGREES := 20.0
const SWEEP_ANGLE_DEGREES := 90.0
const SWEEP_SPEED_DEGREES := 30.0
const ONE_SECOND := 1.0
const TWO_SECONDS := 2.0
const THREE_SECONDS := 3.0
const ROTATION_TOLERANCE := 0.0001

## Zone d'alerte qui note ses appels au lieu d'agir sur des `Npc`.
class AlertZoneSpy extends AlertZoneComponent:
	var alerts: Array[Vector2] = []
	var targets: Array[Vector2] = []
	var clear_count: int = 0

	func alert(target_position: Vector2) -> void:
		alerts.append(target_position)

	func set_target(target_position: Vector2) -> void:
		targets.append(target_position)

	func clear_target() -> void:
		clear_count += 1


## Champ de vision dont la ligne de vue est pilotée par le test (pas de monde physique).
class FovStub extends FovDetectionComponent:
	var has_line_of_sight: bool = true

	func can_see_detected_body() -> bool:
		return has_line_of_sight


var _camera: SurveillanceCamera
var _fov: FovStub
var _zone: AlertZoneSpy
var _cone_visual: Polygon2D
var _player: Node2D


func before_test() -> void:
	_fov = auto_free(FovStub.new())
	var cone_shape := CollisionPolygon2D.new()
	cone_shape.polygon = CONE_POINTS
	_fov.add_child(cone_shape)
	_zone = auto_free(AlertZoneSpy.new())
	_cone_visual = auto_free(Polygon2D.new())
	_player = auto_free(Node2D.new())
	_player.global_position = PLAYER_POSITION
	add_child(_player)
	_camera = auto_free(SurveillanceCamera.new())
	_camera.fov_detection = _fov
	_camera.alert_zone = _zone
	_camera.cone_visual = _cone_visual
	_camera.rotation_degrees = BASE_ROTATION_DEGREES
	_camera.sweep_angle_degrees = SWEEP_ANGLE_DEGREES
	_camera.sweep_speed_degrees = SWEEP_SPEED_DEGREES
	add_child(_camera)


func _assert_rotation_degrees(expected_degrees: float) -> void:
	assert_float(_camera.rotation_degrees).is_equal_approx(expected_degrees, ROTATION_TOLERANCE)


func test_ready_draws_cone_from_fov_polygon() -> void:
	assert_array(_cone_visual.polygon).is_equal(CONE_POINTS)


func test_detect_alerts_zone_toward_player_position() -> void:
	_fov.detect.emit(_player)

	assert_array(_zone.alerts).contains_exactly([PLAYER_POSITION])


func test_detect_sets_zone_target_to_player_position() -> void:
	_fov.detect.emit(_player)

	assert_array(_zone.targets).contains_exactly([PLAYER_POSITION])


func test_lost_clears_zone_target() -> void:
	_fov.detect.emit(_player)

	_fov.lost.emit(_player)

	assert_int(_zone.clear_count).is_equal(1)


func test_detect_again_after_lost_alerts_again() -> void:
	_fov.detect.emit(_player)
	_fov.lost.emit(_player)

	_fov.detect.emit(_player)

	assert_array(_zone.alerts).has_size(2)


func test_physics_process_refreshes_target_while_player_is_seen() -> void:
	_fov.detected_body = _player
	_player.global_position = MOVED_PLAYER_POSITION

	_camera._physics_process(0.0)

	assert_array(_zone.targets).contains_exactly([MOVED_PLAYER_POSITION])


func test_physics_process_clears_target_when_line_of_sight_is_lost() -> void:
	# Le joueur est resté dans le cône mais un mur le cache : sa position ne doit plus être donnée.
	_fov.detected_body = _player
	_fov.has_line_of_sight = false

	_camera._physics_process(0.0)

	assert_int(_zone.clear_count).is_equal(1)
	assert_array(_zone.targets).is_empty()


func test_physics_process_without_detected_body_leaves_target_untouched() -> void:
	_camera._physics_process(0.0)

	assert_array(_zone.targets).is_empty()


func test_scene_wires_components_and_draws_cone() -> void:
	var scene: PackedScene = load("res://scenes/entities/surveillance_camera/surveillance_camera.tscn")
	var camera: SurveillanceCamera = auto_free(scene.instantiate())
	add_child(camera)

	assert_object(camera.fov_detection).is_not_null()
	assert_object(camera.alert_zone).is_not_null()
	assert_array(camera.cone_visual.polygon).is_not_empty()


func test_physics_process_with_sweep_disabled_keeps_rotation() -> void:
	_camera.sweep_enabled = false

	_camera._physics_process(ONE_SECOND)

	_assert_rotation_degrees(BASE_ROTATION_DEGREES)


func test_physics_process_with_sweep_enabled_rotates_at_sweep_speed() -> void:
	_camera.sweep_enabled = true

	_camera._physics_process(ONE_SECOND)

	_assert_rotation_degrees(BASE_ROTATION_DEGREES + SWEEP_SPEED_DEGREES)


func test_sweep_stops_at_half_angle() -> void:
	_camera.sweep_enabled = true

	_camera._physics_process(TWO_SECONDS)

	_assert_rotation_degrees(BASE_ROTATION_DEGREES + SWEEP_ANGLE_DEGREES / 2.0)


func test_sweep_reverses_after_reaching_limit() -> void:
	_camera.sweep_enabled = true
	_camera._physics_process(TWO_SECONDS)

	_camera._physics_process(ONE_SECOND)

	_assert_rotation_degrees(BASE_ROTATION_DEGREES + SWEEP_ANGLE_DEGREES / 2.0 - SWEEP_SPEED_DEGREES)


func test_sweep_stops_at_opposite_half_angle() -> void:
	_camera.sweep_enabled = true
	_camera._physics_process(TWO_SECONDS)

	_camera._physics_process(THREE_SECONDS)

	_assert_rotation_degrees(BASE_ROTATION_DEGREES - SWEEP_ANGLE_DEGREES / 2.0)
