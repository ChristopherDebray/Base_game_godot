extends RefCounted

## Génère la texture d'une lumière en cône pour une `PointLight2D` : image carrée, sommet au centre,
## cône orienté vers +X. La lumière décroît avec la distance, les bords de l'angle sont adoucis et un
## halo rond entoure le sommet pour que le faisceau parte de la source sans pointe ni bord plat.
## Sans dépendance au SceneTree : testable seule.
class_name ConeLightImage

# Largeur (radians) du fondu sur les bords de l'angle.
const EDGE_SOFTNESS_ANGLE := 0.15
# Rayon du halo autour du sommet, en fraction du rayon du cône.
const GLOW_RADIUS_RATIO := 0.08
# Exposant de décroissance : > 1 concentre la lumière près de la source, plus naturel qu'un linéaire.
const DISTANCE_FALLOFF_EXPONENT := 1.5

## Construit l'image du cône. `half_angle` : demi-ouverture en radians ; `image_size` : côté en
## pixels (le rayon du cône vaut la moitié). Renvoie une image vide si `image_size` n'est pas positif.
static func build(half_angle: float, image_size: int) -> Image:
	if image_size <= 0:
		return Image.new()

	var image := Image.create_empty(image_size, image_size, false, Image.FORMAT_RGBA8)
	var radius := image_size / 2.0
	var apex := Vector2(radius, radius)
	for pixel_y in image_size:
		for pixel_x in image_size:
			# Centre du pixel, pour que le sommet tombe pile entre les quatre pixels centraux.
			var offset := Vector2(pixel_x + 0.5, pixel_y + 0.5) - apex
			var brightness := _brightness_at(offset / radius, half_angle)
			image.set_pixel(pixel_x, pixel_y, Color(brightness, brightness, brightness))
	return image

## Demi-ouverture (radians) d'un cône décrit par un polygone dont le sommet est l'origine et l'axe +X.
static func half_angle_of(polygon: PackedVector2Array) -> float:
	var widest := 0.0
	for point in polygon:
		if point.is_zero_approx():
			continue
		widest = maxf(widest, absf(point.angle()))
	return widest

## Distance entre l'origine (sommet) et le point le plus lointain du polygone.
static func radius_of(polygon: PackedVector2Array) -> float:
	var farthest := 0.0
	for point in polygon:
		farthest = maxf(farthest, point.length())
	return farthest

# `normalized_offset` : position relative au sommet, en fractions du rayon (1 = bord du cône).
static func _brightness_at(normalized_offset: Vector2, half_angle: float) -> float:
	var distance := normalized_offset.length()
	if distance >= 1.0:
		return 0.0

	var glow := 1.0 - smoothstep(0.0, GLOW_RADIUS_RATIO, distance)
	var angular := 1.0 - smoothstep(half_angle - EDGE_SOFTNESS_ANGLE, half_angle, absf(normalized_offset.angle()))
	var radial := pow(1.0 - distance, DISTANCE_FALLOFF_EXPONENT)
	return maxf(glow, angular * radial)
