class_name SurveillanceCameraViewTest
extends GdUnitTestSuite

## Tests du visuel de la caméra de surveillance : cône de lumière vert au repos, rouge quand
## le joueur est vu, avec une texture générée ajustée au cône de détection.

const IDLE_COLOR := Color.GREEN
const DETECTED_COLOR := Color.RED
const CONE_POINTS: PackedVector2Array = [Vector2(200.0, -90.0), Vector2(200.0, 90.0), Vector2.ZERO]
# Distance du sommet au coin le plus lointain du cône : sqrt(200² + 90²).
const CONE_RADIUS := 219.31712
const TOLERANCE := 0.001

var _view: SurveillanceCameraView
var _cone_light: PointLight2D


func before_test() -> void:
	_view = auto_free(SurveillanceCameraView.new())
	_view.idle_color = IDLE_COLOR
	_view.detected_color = DETECTED_COLOR
	_cone_light = PointLight2D.new()
	_view.add_child(_cone_light)
	_view.cone_light = _cone_light
	add_child(_view)


func test_new_view_shows_idle_color() -> void:
	assert_that(_view.get_status_color()).is_equal(IDLE_COLOR)


func test_set_detected_true_shows_detected_color() -> void:
	_view.set_detected(true)

	assert_that(_view.get_status_color()).is_equal(DETECTED_COLOR)


func test_set_detected_false_after_detection_shows_idle_color() -> void:
	_view.set_detected(true)

	_view.set_detected(false)

	assert_that(_view.get_status_color()).is_equal(IDLE_COLOR)


func test_set_cone_polygon_stores_polygon() -> void:
	_view.set_cone_polygon(CONE_POINTS)

	assert_array(_view.get_cone_polygon()).is_equal(CONE_POINTS)


func test_set_cone_polygon_gives_generated_texture_to_light() -> void:
	_view.set_cone_polygon(CONE_POINTS)

	assert_object(_cone_light.texture).is_not_null()


func test_set_cone_polygon_scales_texture_radius_to_cone_radius() -> void:
	# La texture est carrée, sommet au centre : sa demi-largeur doit couvrir le rayon du cône.
	_view.set_cone_polygon(CONE_POINTS)

	var texture_half_size := _cone_light.texture.get_width() / 2.0
	assert_float(texture_half_size * _cone_light.texture_scale).is_equal_approx(CONE_RADIUS, TOLERANCE)


func test_new_view_colors_light_with_idle_color() -> void:
	assert_that(_cone_light.color).is_equal(IDLE_COLOR)


func test_set_detected_true_colors_light_with_detected_color() -> void:
	_view.set_detected(true)

	assert_that(_cone_light.color).is_equal(DETECTED_COLOR)


func test_set_cone_polygon_without_light_keeps_polygon() -> void:
	_view.cone_light = null

	_view.set_cone_polygon(CONE_POINTS)

	assert_array(_view.get_cone_polygon()).is_equal(CONE_POINTS)


func test_scene_starts_idle_with_shadowed_light_above_lit_view() -> void:
	# z_index > 0 : le visuel doit passer au-dessus du `LitView` masqué par le fog of war.
	var scene: PackedScene = load("res://scenes/entities/surveillance_camera/surveillance_camera_view.tscn")
	var view: SurveillanceCameraView = auto_free(scene.instantiate())
	add_child(view)

	assert_bool(view.is_detected()).is_false()
	assert_int(view.z_index).is_greater(0)
	assert_object(view.cone_light).is_not_null()
	assert_bool(view.cone_light.shadow_enabled).is_true()
