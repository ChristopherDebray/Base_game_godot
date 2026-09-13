extends Node2D

@onready var player: Player = $LitViewport/Entities/Player
@onready var camera_2d: Camera2D = $Camera2D
@onready var light_holder: Node2D = $VisibilityViewport/LightHolder
@onready var aim_component: AimComponent = $AimComponent

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	camera_2d.position = player.position
	var mouse_position := get_global_mouse_position()
	# ! Mouse position toujours 0.0
	light_holder.look_at(mouse_position)
	light_holder.position = player.position

func get_aim_direction() -> Vector2:
	var aim_world_pos := aim_component.get_aim_world_position()
	return global_position.direction_to(aim_world_pos)
