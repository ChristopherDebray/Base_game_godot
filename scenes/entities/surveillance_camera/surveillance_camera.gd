extends Node2D

## Caméra de surveillance : quand son champ de vision voit le joueur, elle demande à sa zone
## d'alerte d'envoyer les ennemis proches à la position du joueur. Elle ne référence aucun
## ennemi : la zone les récupère elle-même. Sortir puis rentrer dans le cône relance l'alerte
## (`detect` est ré-émis par le champ de vision). L'orientation se règle par la rotation du node ;
## si `sweep_enabled` est coché, la caméra balaie de gauche à droite autour de cette orientation.
## Elle n'a pas de visuel propre : elle pilote une `SurveillanceCameraView` (position, cône de lumière
## vert/rouge) placée par le niveau hors du `LitViewport`, pour rester visible dans le fog of war.
class_name SurveillanceCamera

@export var fov_detection: FovDetectionComponent
@export var alert_zone: AlertZoneComponent
## Visuel de la caméra, optionnel. Il peut vivre dans un autre viewport : la caméra lui copie sa
## transformation globale, ce qui suppose que les deux viewports partagent le même repère
## (c'est le cas du `LitViewport`, affiché tel quel à l'origine du niveau).
@export var view: SurveillanceCameraView
## Active le balayage gauche-droite. Décoché, la caméra garde son orientation fixe.
@export var sweep_enabled: bool = false
## Amplitude totale du balayage, répartie de part et d'autre de l'orientation de départ.
@export var sweep_angle_degrees: float = 90.0
@export var sweep_speed_degrees: float = 30.0

var _base_rotation: float
var _sweep_offset: float = 0.0
var _sweep_direction: float = 1.0

func _ready() -> void:
	_base_rotation = rotation
	_init_view()
	fov_detection.detect.connect(_on_fov_detection_detect)
	fov_detection.lost.connect(_on_fov_detection_lost)

# Rotation en physique : le cône est une `Area2D`, sa détection suit les frames physiques.
func _physics_process(delta: float) -> void:
	_sweep(delta)
	_refresh_alert_target()
	_sync_view_transform()

func _init_view() -> void:
	if not is_instance_valid(view):
		return

	view.set_cone_polygon(fov_detection.get_cone_polygon())
	_sync_view_transform()

func _sync_view_transform() -> void:
	if not is_instance_valid(view):
		return

	view.global_transform = global_transform

func _show_detected(detected: bool) -> void:
	if not is_instance_valid(view):
		return

	view.set_detected(detected)

# Va-et-vient entre les deux bornes : on borne l'écart puis on inverse le sens, pour ne
# jamais dépasser l'amplitude même avec un gros `delta`.
func _sweep(delta: float) -> void:
	if not sweep_enabled:
		return

	var half_angle := deg_to_rad(sweep_angle_degrees) / 2.0
	_sweep_offset += _sweep_direction * deg_to_rad(sweep_speed_degrees) * delta
	if absf(_sweep_offset) >= half_angle:
		_sweep_offset = clampf(_sweep_offset, -half_angle, half_angle)
		_sweep_direction = -_sweep_direction
	rotation = _base_rotation + _sweep_offset

# Tant que le joueur est vu, la cible suit ses déplacements pour les ennemis qui entrent
# dans la zone d'alerte plus tard. S'il reste dans le cône mais passe derrière un mur (le champ
# de vision ne contrôle la ligne de vue qu'à l'entrée), on cesse de donner sa position.
func _refresh_alert_target() -> void:
	if not is_instance_valid(fov_detection.detected_body):
		return
	
	if not fov_detection.can_see_detected_body():
		alert_zone.clear_target()
		_show_detected(false)
		return
	
	alert_zone.set_target(fov_detection.detected_body.global_position)
	_show_detected(true)

func _on_fov_detection_detect(detected_entity: Node2D) -> void:
	alert_zone.set_target(detected_entity.global_position)
	alert_zone.alert(detected_entity.global_position)
	_show_detected(true)

func _on_fov_detection_lost(_detected_entity: Node2D) -> void:
	alert_zone.clear_target()
	_show_detected(false)
