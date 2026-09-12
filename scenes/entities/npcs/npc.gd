extends CharacterBody2D

class_name Npc

var FOV = {
	ENEMY_STATE.IDLE: 60.0,
	ENEMY_STATE.RETURNING: 60.0,
	ENEMY_STATE.PATROLLING: 60.0,
	ENEMY_STATE.CHASING: 120.0,
	ENEMY_STATE.SEARCHING: 100.0
}
var SPEED = {
	ENEMY_STATE.IDLE: 60.0,
	ENEMY_STATE.RETURNING: 90.0,
	ENEMY_STATE.PATROLLING: 80.0,
	ENEMY_STATE.CHASING: 90.0,
	ENEMY_STATE.SEARCHING: 90.0
}

enum ENEMY_STATE { IDLE, RETURNING, PATROLLING, CHASING, SEARCHING }

@export var patrol_points: NodePath
@export var is_idle: bool = false

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

@onready var light_raycast_2d: RayCast2D = $PlayerDetect/LightRaycast2D

var _waypoints: Array = []
var _current_wp: int = 0
var _player_ref: Player
var _state: ENEMY_STATE = ENEMY_STATE.PATROLLING
var _initial_facing_direction: Vector2
var _initial_position: Vector2
var _has_detected_player: bool = false

func _ready() -> void:
	setup()
	call_deferred("late_setup")

func setup():
	set_physics_process(false)
	if is_idle:
		_state = ENEMY_STATE.IDLE
	
	create_wp()
	_player_ref = get_tree().get_first_node_in_group("player")
	_initial_facing_direction = animated_sprite_2d.global_transform.x.normalized()
	_initial_position = global_position

func late_setup():
	await get_tree().physics_frame
	await get_tree().create_timer(0.3).timeout
	call_deferred("set_physics_process", true)

func _physics_process(delta):
	update_state()
	update_movement()
	update_navigation()

func set_state(new_state: ENEMY_STATE) -> void:
	if new_state == _state:
		return
	
	match new_state:
		ENEMY_STATE.SEARCHING:
			pass
		ENEMY_STATE.CHASING:
			pass
		ENEMY_STATE.PATROLLING:
			pass
		ENEMY_STATE.IDLE:
			animated_sprite_2d.look_at(animated_sprite_2d.global_position + _initial_facing_direction)
	
	_state = new_state

func set_nav_to_player() -> void:
	nav_agent.target_position = _player_ref.global_position

func set_nav_to_position(nav_position: Vector2) -> void:
	nav_agent.target_position = nav_position

func update_state() -> void:
	var new_state = _state
	var can_see = false
	#var can_see = can_see_player()
	
	if can_see == true:
		new_state = ENEMY_STATE.CHASING
	elif can_see == false and new_state == ENEMY_STATE.CHASING:
		new_state = ENEMY_STATE.SEARCHING
	
	set_state(new_state)

func update_movement() -> void:
	match _state:
		ENEMY_STATE.IDLE:
			process_idle()
		ENEMY_STATE.RETURNING:
			process_returning()
		ENEMY_STATE.PATROLLING:
			process_patrolling()
		ENEMY_STATE.SEARCHING:
			process_searching()
		ENEMY_STATE.CHASING:
			process_chasing()

func update_navigation() -> void:
	if nav_agent.is_navigation_finished() == true:
		return
	
	var next_path_position: Vector2 = nav_agent.get_next_path_position()
	animated_sprite_2d.look_at(next_path_position)
	var ini_v = global_position.direction_to(next_path_position) * SPEED[_state]
	nav_agent.set_velocity(ini_v)

func search_player() -> void:
	set_state(ENEMY_STATE.SEARCHING)
	set_nav_to_player()

func search_position(search_position: Vector2) -> void:
	set_state(ENEMY_STATE.SEARCHING)
	set_nav_to_position(search_position)

# WAYPOINTS

func create_wp() -> void:
	if is_idle:
		return
	
	for wp in get_node(patrol_points).get_children():
		_waypoints.append(wp.global_position)

func navigate_wp() -> void:
	if _current_wp >= len(_waypoints):
		_current_wp = 0
	nav_agent.target_position = _waypoints[_current_wp]
	_current_wp += 1

# MOVEMENT PROCESSING

func process_idle() -> void:
	pass

func process_returning() -> void:
	nav_agent.target_position = _initial_position
	if nav_agent.is_navigation_finished() == true:
		set_state(ENEMY_STATE.IDLE)

func process_patrolling() -> void:
	if nav_agent.is_navigation_finished() == true:
		navigate_wp()

func process_chasing() -> void:
	set_nav_to_player()

func process_searching() -> void:
	if nav_agent.is_navigation_finished() == true:
		var _new_state = ENEMY_STATE.PATROLLING
		if is_idle:
			_new_state = ENEMY_STATE.RETURNING
		set_state(_new_state)

func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	move_and_slide()
