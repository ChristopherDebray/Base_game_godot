extends Node2D

## Visuel d'une `SurveillanceCamera` : cône de lumière vert au repos, rouge quand le joueur est vu.
## Séparé de la caméra pour pouvoir être placé hors du `LitViewport`, donc visible même dans le fog of war, alors que la détection reste dans le monde physique du joueur.
## Le cône est une `PointLight2D` avec ombres : les murs du viewport principal (qui ont des
## occluders) le bloquent. Il ne décide rien : la caméra lui donne sa position, son cône et son état.
class_name SurveillanceCameraView

# Résolution de la texture générée : la lumière est floue par nature, inutile d'aller plus haut.
const CONE_IMAGE_SIZE := 128

@export var idle_color: Color = Color(0.2, 1.0, 0.2)
@export var detected_color: Color = Color(1.0, 0.2, 0.2)
## Lumière du cône (optionnelle). Son intensité se règle avec son `energy` dans l'inspecteur.
@export var cone_light: PointLight2D

# Privés : les modifier sans passer par les setters sauterait la mise à jour de la lumière.
var _is_detected: bool = false
var _cone_polygon: PackedVector2Array = PackedVector2Array()

func _ready() -> void:
	_color_cone_light()

## Passe le cône au rouge (`true`) ou au vert (`false`). Ne met à jour que si l'état
## change, car la caméra l'appelle à chaque frame physique.
func set_detected(detected: bool) -> void:
	if detected == _is_detected:
		return

	_is_detected = detected
	_color_cone_light()

func is_detected() -> bool:
	return _is_detected

## Couleur courante du cône, selon l'état de détection.
func get_status_color() -> Color:
	if _is_detected:
		return detected_color
	return idle_color

## Remplace le cône affiché (points dans le repère local de la caméra, sommet à l'origine) et
## régénère la texture de la lumière à ses dimensions.
func set_cone_polygon(polygon: PackedVector2Array) -> void:
	_cone_polygon = polygon
	_build_cone_light()

func get_cone_polygon() -> PackedVector2Array:
	return _cone_polygon

# La texture a son sommet au centre : sa demi-largeur, mise à l'échelle, doit valoir le rayon du cône.
func _build_cone_light() -> void:
	if not is_instance_valid(cone_light) or _cone_polygon.is_empty():
		return

	var cone_image := ConeLightImage.build(ConeLightImage.half_angle_of(_cone_polygon), CONE_IMAGE_SIZE)
	cone_light.texture = ImageTexture.create_from_image(cone_image)
	cone_light.texture_scale = ConeLightImage.radius_of(_cone_polygon) / (CONE_IMAGE_SIZE / 2.0)

func _color_cone_light() -> void:
	if not is_instance_valid(cone_light):
		return

	cone_light.color = get_status_color()
