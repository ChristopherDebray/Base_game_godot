extends Node2D

## Caméra de surveillance : quand son champ de vision voit le joueur, elle demande à sa zone
## d'alerte d'envoyer les ennemis proches à la position du joueur. Elle ne référence aucun
## ennemi : la zone les récupère elle-même. Sortir puis rentrer dans le cône relance l'alerte
## (`detect` est ré-émis par le champ de vision). L'orientation se règle par la rotation du node.
class_name SurveillanceCamera

@export var fov_detection: FovDetectionComponent
@export var alert_zone: AlertZoneComponent
## Polygone visible qui représente le cône, pour que le joueur voie la zone surveillée.
@export var cone_visual: Polygon2D

func _ready() -> void:
	cone_visual.polygon = fov_detection.get_cone_polygon()
	fov_detection.detect.connect(_on_fov_detection_detect)
	fov_detection.lost.connect(_on_fov_detection_lost)

# Tant que le joueur est vu, la cible suit ses déplacements pour les ennemis qui entrent
# dans la zone d'alerte plus tard. S'il reste dans le cône mais passe derrière un mur (le champ
# de vision ne contrôle la ligne de vue qu'à l'entrée), on cesse de donner sa position.
func _physics_process(_delta: float) -> void:
	if not is_instance_valid(fov_detection.detected_body):
		return
	
	if not fov_detection.can_see_detected_body():
		alert_zone.clear_target()
		return
	
	alert_zone.set_target(fov_detection.detected_body.global_position)

func _on_fov_detection_detect(detected_entity: Node2D) -> void:
	alert_zone.set_target(detected_entity.global_position)
	alert_zone.alert(detected_entity.global_position)

func _on_fov_detection_lost(_detected_entity: Node2D) -> void:
	alert_zone.clear_target()
