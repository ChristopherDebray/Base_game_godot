extends Area2D

## Détection par champ de vision (Area2D) : repère le `Player` entré dans la zone, à condition
## qu'aucun mur ne le cache (raycast). Émet `detect` à la détection et `lost` à la sortie.
class_name FovDetectionComponent

signal detect(detected_entity: Node2D)
signal lost(detected_entity: Node2D)

const DETECTION_RANGE := 900.00
# Le regard est bloqué par les murs et par le joueur, mais pas par les autres ennemis.
const SIGHT_MASK := CollisionManager.MASK_WALLS | CollisionManager.MASK_PLAYER

var detected_body: Node2D = null

func _ready() -> void:
	# All layer and mask are set to none by default on this component
	# For now only detect caracter layer, later might have dynamic detection
	set_collision_mask_value(CollisionManager.LAYER_CARACTER, true)

## Indique si le corps détecté est toujours en ligne de vue (aucun mur entre les deux).
## Renvoie `false` s'il n'y a pas de corps détecté.
func can_see_detected_body() -> bool:
	if !detected_body:
		return false
	
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var result: Dictionary = CollisionManager.draw_ray_query_to_target(
		detected_body.global_position,
		global_position,
		DETECTION_RANGE,
		space_state,
		self,
		SIGHT_MASK
	)
	
	if result.is_empty() or !is_instance_of(result.collider, Player):
		return false
	
	return true

## Renvoie les points du cône de vision (repère local), tels que définis par le
## `CollisionPolygon2D` enfant, pour pouvoir le dessiner sans dupliquer sa forme.
## Renvoie un tableau vide s'il n'y a pas de polygone.
func get_cone_polygon() -> PackedVector2Array:
	for child in get_children():
		if child is CollisionPolygon2D:
			return child.polygon
	return PackedVector2Array()

func _on_body_entered(body: Node2D) -> void:
	if !is_instance_of(body, Player):
		return
	
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var result: Dictionary = CollisionManager.draw_ray_query_to_target(
		body.global_position,
		global_position,
		DETECTION_RANGE,
		space_state,
		self,
		SIGHT_MASK
	)
	
	if result.is_empty() or !is_instance_of(result.collider, Player):
		return
	
	detected_body = body
	detect.emit(body)

func _on_body_exited(body: Node2D) -> void:
	if detected_body:
		lost.emit(body)
		detected_body = null
