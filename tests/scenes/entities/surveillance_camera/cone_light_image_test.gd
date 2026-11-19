class_name ConeLightImageTest
extends GdUnitTestSuite

## Tests de la génération de texture de cône de lumière : sommet au centre de l'image, cône vers +X,
## halo rond sur le sommet, lumière nulle derrière, hors de l'angle et au-delà du rayon.

const HALF_ANGLE := PI / 6.0
const IMAGE_SIZE := 64
# Échantillons dans le repère de l'image (pixels).
const AHEAD_NEAR := Vector2i(40, 32)
const AHEAD_FAR := Vector2i(56, 32)
const BEHIND_FAR := Vector2i(8, 32)
const OUTSIDE_ANGLE := Vector2i(44, 50)
# Dans l'angle du cône mais plus loin que le rayon (coin de l'image).
const BEYOND_RADIUS := Vector2i(62, 47)
const BEHIND_GLOW := Vector2i(31, 32)

const CONE_POINTS: PackedVector2Array = [Vector2(200.0, -90.0), Vector2(200.0, 90.0), Vector2.ZERO]
const CONE_HALF_ANGLE := 0.42285393
const CONE_RADIUS := 219.31712
const TOLERANCE := 0.001

var _image: Image


func before_test() -> void:
	_image = ConeLightImage.build(HALF_ANGLE, IMAGE_SIZE)


func _brightness(pixel: Vector2i) -> float:
	return _image.get_pixelv(pixel).r


func test_build_returns_square_image_of_requested_size() -> void:
	assert_vector(Vector2(_image.get_size())).is_equal(Vector2(IMAGE_SIZE, IMAGE_SIZE))


func test_build_lights_pixels_ahead_of_apex() -> void:
	assert_float(_brightness(AHEAD_NEAR)).is_greater(0.5)


func test_build_fades_light_with_distance() -> void:
	assert_float(_brightness(AHEAD_FAR)).is_less(_brightness(AHEAD_NEAR))


func test_build_leaves_behind_apex_dark() -> void:
	assert_float(_brightness(BEHIND_FAR)).is_equal(0.0)


func test_build_leaves_outside_angle_dark() -> void:
	assert_float(_brightness(OUTSIDE_ANGLE)).is_equal(0.0)


func test_build_leaves_beyond_radius_dark() -> void:
	assert_float(_brightness(BEYOND_RADIUS)).is_equal(0.0)


func test_build_rounds_apex_with_glow_behind_it() -> void:
	# Juste derrière le sommet, hors du cône : seul le halo rond éclaire, le départ n'est pas pointu.
	assert_float(_brightness(BEHIND_GLOW)).is_greater(0.0)


func test_build_with_invalid_size_returns_empty_image() -> void:
	assert_bool(ConeLightImage.build(HALF_ANGLE, 0).is_empty()).is_true()


func test_half_angle_of_polygon_is_widest_point_angle() -> void:
	assert_float(ConeLightImage.half_angle_of(CONE_POINTS)).is_equal_approx(CONE_HALF_ANGLE, TOLERANCE)


func test_radius_of_polygon_is_farthest_point_distance() -> void:
	assert_float(ConeLightImage.radius_of(CONE_POINTS)).is_equal_approx(CONE_RADIUS, TOLERANCE)
