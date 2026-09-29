extends Area2D

class_name FovDetectionComponent

signal detect(detected_entity: Node2D)
signal lost(detected_entity: Node2D)

const DETECTION_RANGE := 900.00

var detected_body: Node2D = null

func _ready() -> void:
	# All layer and mask are set to none by default on this component
	# For now only detect caracter layer, later might have dynamic detection
	set_collision_mask_value(CollisionManager.LAYER_CARACTER, true)

func can_see_detected_body():
	if !detected_body:
		return false
	
	var space_state = get_world_2d().direct_space_state
	var result = CollisionManager.draw_ray_query_to_target(
		detected_body.global_position,
		global_position,
		DETECTION_RANGE,
		space_state,
		self
	)
	
	if !is_instance_of(result.collider, Player):
		return false
	
	return true

func _on_body_entered(body: Node2D) -> void:
	if !is_instance_of(body, Player):
		return
	
	var space_state = get_world_2d().direct_space_state
	var result = CollisionManager.draw_ray_query_to_target(
		body.global_position,
		global_position,
		DETECTION_RANGE,
		space_state,
		self
	)
	
	if !is_instance_of(result.collider, Player):
		return
	
	detected_body = body
	detect.emit(body)

func _on_body_exited(body: Node2D) -> void:
	if detected_body:
		lost.emit(body)
		detected_body = null
