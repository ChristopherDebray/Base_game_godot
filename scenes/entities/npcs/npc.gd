extends Damageable

## Ennemi contrôlé par une machine à états (IDLE, RETURNING, PATROLLING, CHASING, ATTACKING,
## SEARCHING) : patrouille entre waypoints, détecte le joueur via `FovDetectionComponent`, le
## poursuit par navigation puis l'attaque selon son `CombatBehavior` (distance, corps à corps,
## kamikaze...) une fois à portée d'engagement.
class_name Npc

var FOV: Dictionary = {
	ENEMY_STATE.IDLE: 60.0,
	ENEMY_STATE.RETURNING: 60.0,
	ENEMY_STATE.PATROLLING: 60.0,
	ENEMY_STATE.CHASING: 120.0,
	ENEMY_STATE.SEARCHING: 100.0,
	ENEMY_STATE.ATTACKING: 120.0
}
var SPEED: Dictionary = {
	ENEMY_STATE.IDLE: 60.0,
	ENEMY_STATE.RETURNING: 80.0,
	ENEMY_STATE.PATROLLING: 70.0,
	ENEMY_STATE.CHASING: 80.0,
	ENEMY_STATE.SEARCHING: 80.0,
	ENEMY_STATE.ATTACKING: 0.0
}

enum ENEMY_STATE { IDLE, RETURNING, PATROLLING, CHASING, SEARCHING, ATTACKING }

@export var patrol_points: NodePath
@export var initial_weapon: PackedScene
## Façon de combattre une fois le joueur en vue. Sans behavior, l'ennemi poursuit sans attaquer.
@export var combat_behavior: CombatBehavior

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var fov_detection_component: FovDetectionComponent = $FovDetectionComponent
@onready var muzzle: Node2D = $Muzzle
@onready var object_holder_component: ObjectHolderComponent = $ObjectHolderComponent

var _waypoints: Array = []
var _current_wp: int = 0
var _player_ref: Player
var _state: ENEMY_STATE = ENEMY_STATE.PATROLLING
var _initial_facing_direction: Vector2
var _initial_position: Vector2
var next_ms := 0
var is_idle: bool = false
var facing_direction: Vector2 = Vector2.RIGHT
var facing_position: Vector2
var aim_target: Vector2

func _ready() -> void:
	setup()
	call_deferred("late_setup")

## Prépare le PNJ : coupe le traitement physique (réactivé par `late_setup`), passe en IDLE s'il
## n'a pas de points de patrouille, construit les waypoints, retrouve le joueur (groupe
## "player") et branche le signal `detect` du champ de vision. Duplique le `combat_behavior` :
## la Resource est partagée entre toutes les instances de la scène, or le behavior porte de
## l'état propre à chaque ennemi (cooldown, mèche armée).
func setup() -> void:
	set_physics_process(false)
	if combat_behavior != null:
		combat_behavior = combat_behavior.duplicate() as CombatBehavior
	is_idle = patrol_points.is_empty()
	if is_idle:
		_state = ENEMY_STATE.IDLE
	
	create_wp()
	_player_ref = get_tree().get_first_node_in_group("player")
	_initial_facing_direction = animated_sprite_2d.global_transform.x.normalized()
	_initial_position = global_position
	fov_detection_component.detect.connect(_on_detect)

## Appelée en différé après `setup` : attend une frame physique et 0,3 s (le temps que la
## navigation soit prête), réactive le traitement physique puis équipe l'arme initiale (si le PNJ
## en a une : un kamikaze ou un corps à corps n'en a pas).
func late_setup() -> void:
	await get_tree().physics_frame
	await get_tree().create_timer(0.3).timeout
	call_deferred("set_physics_process", true)
	if initial_weapon == null:
		return

	object_holder_component.switch_weapon(
		initial_weapon.instantiate(),
		muzzle.position
	)

func _physics_process(delta: float) -> void:
	update_state()
	update_movement()
	update_navigation()
	_update_facing()
	set_aim_dir(aim_target)

## Passe dans l'état `new_state` (sans effet s'il est déjà courant). Entrer en IDLE ré-oriente
## le sprite vers sa direction initiale.
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

## Définit la destination de navigation sur la position actuelle du joueur.
func set_nav_to_player() -> void:
	nav_agent.target_position = _player_ref.global_position

## Définit la destination de navigation sur `nav_position`.
func set_nav_to_position(nav_position: Vector2) -> void:
	nav_agent.target_position = nav_position

## Choisit l'état selon la vue (voir `apply_sight`).
func update_state() -> void:
	apply_sight(fov_detection_component.can_see_detected_body())

## Applique le résultat de la vue : si le joueur détecté est visible, attaque s'il est à portée
## d'engagement du `combat_behavior` (poursuite sans behavior ou hors portée) ; s'il disparaît
## pendant une poursuite ou une attaque, passe en recherche.
func apply_sight(can_see: bool) -> void:
	if not can_see:
		if _state == ENEMY_STATE.CHASING or _state == ENEMY_STATE.ATTACKING:
			set_state(ENEMY_STATE.SEARCHING)
		return

	set_state(_state_for_visible_target())

func _state_for_visible_target() -> ENEMY_STATE:
	var target: Node2D = fov_detection_component.detected_body
	if combat_behavior == null or not is_instance_valid(target):
		return ENEMY_STATE.CHASING

	var distance: float = global_position.distance_to(target.global_position)
	if combat_behavior.decide(distance, true) == CombatBehavior.Action.ATTACK:
		return ENEMY_STATE.ATTACKING
	return ENEMY_STATE.CHASING

## Exécute le comportement de déplacement de l'état courant.
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
		ENEMY_STATE.ATTACKING:
			process_attacking()

func _update_facing() -> void:
	var weapon: BaseWeapon = object_holder_component.current_weapon
	if facing_position.x < -0.05:
		flip_facing(false)
		if weapon != null:
			weapon.flip_weapon(false)
	elif facing_position.x > 0.05:
		flip_facing(true)
		if weapon != null:
			weapon.flip_weapon(true)

## Met à jour `facing_position` pour regarder le point monde `dir` et, si une arme est équipée,
## l'oriente vers ce point.
func set_aim_dir(dir: Vector2) -> void:
	var weapon: BaseWeapon = object_holder_component.current_weapon
	if weapon != null:
		weapon.aim_at(dir)
	facing_position = global_position - dir

## Retourne le sprite horizontalement et met `facing_direction` à gauche (si
## `must_reverse_flip`) ou à droite.
func flip_facing(must_reverse_flip: bool) -> void:
	animated_sprite_2d.flip_h = must_reverse_flip
	if must_reverse_flip:
		facing_direction = Vector2.LEFT
		return
	facing_direction = Vector2.RIGHT

## En ATTACKING, immobilise le PNJ. Sinon, tant que la navigation n'est pas finie : vise le
## prochain point du chemin, oriente le champ de vision et transmet la vitesse souhaitée à
## l'agent. Le déplacement réel est appliqué dans `_on_navigation_agent_2d_velocity_computed`
## (évitement).
func update_navigation() -> void:
	if _state == ENEMY_STATE.ATTACKING:
		nav_agent.set_velocity(Vector2.ZERO)
		return

	if nav_agent.is_navigation_finished() == true:
		return
	
	var next_path_position: Vector2 = nav_agent.get_next_path_position()
	aim_target = next_path_position
	fov_detection_component.look_at(next_path_position)
	var desired_velocity: Vector2 = global_position.direction_to(next_path_position) * SPEED[_state]
	nav_agent.set_velocity(desired_velocity)

## Passe en recherche et navigue vers la position actuelle du joueur.
func search_player() -> void:
	set_state(ENEMY_STATE.SEARCHING)
	set_nav_to_player()

## Alerte externe (ex. caméra de surveillance) : le PNJ part chercher en `target_position`.
## Sans effet pendant une poursuite ou une attaque, pour ne pas dégrader une détection directe
## plus précise.
func alert_to(target_position: Vector2) -> void:
	if _state == ENEMY_STATE.CHASING or _state == ENEMY_STATE.ATTACKING:
		return

	search_position(target_position)

## Passe en recherche et navigue vers `pos`.
func search_position(pos: Vector2) -> void:
	set_state(ENEMY_STATE.SEARCHING)
	set_nav_to_position(pos)

# WAYPOINTS

## Construit la liste des waypoints à partir des enfants du node `patrol_points`. Sans effet
## pour un PNJ statique (sans patrouille).
func create_wp() -> void:
	if is_idle:
		return
	
	for wp in get_node(patrol_points).get_children():
		_waypoints.append(wp.global_position)

## Cible le waypoint suivant, en repartant du premier après le dernier.
func navigate_wp() -> void:
	if _current_wp >= len(_waypoints):
		_current_wp = 0
	nav_agent.target_position = _waypoints[_current_wp]
	_current_wp += 1

# MOVEMENT PROCESSING

## État IDLE : ne fait rien (le PNJ reste en place).
func process_idle() -> void:
	pass

## État RETURNING : retourne à la position initiale puis passe en IDLE à l'arrivée.
func process_returning() -> void:
	nav_agent.target_position = _initial_position
	if nav_agent.is_navigation_finished() == true:
		set_state(ENEMY_STATE.IDLE)

## État PATROLLING : joue un bruit de pas au plus une fois par seconde et enchaîne les
## waypoints à chaque arrivée.
func process_patrolling() -> void:
	var now_ms := Time.get_ticks_msec()
	if now_ms > next_ms:
		SoundManager.play_footstep(global_position)
		next_ms = Time.get_ticks_msec() + 1000
	if nav_agent.is_navigation_finished() == true:
		navigate_wp()

## État CHASING : navigue vers la position du joueur détecté. Suppose `detected_body` non nul.
func process_chasing() -> void:
	set_nav_to_position(fov_detection_component.detected_body.global_position)

## État ATTACKING : se tourne vers le joueur détecté et délègue l'attaque au `combat_behavior`.
## Sans cible valide ou sans behavior, ne fait rien.
func process_attacking() -> void:
	var target: Node2D = fov_detection_component.detected_body
	if combat_behavior == null or not is_instance_valid(target):
		return

	aim_target = target.global_position
	fov_detection_component.look_at(target.global_position)
	combat_behavior.perform_attack(self, target)

## État SEARCHING : à l'arrivée à destination, reprend la patrouille (ou retourne à son poste
## si le PNJ est statique).
func process_searching() -> void:
	if nav_agent.is_navigation_finished() == false:
		return
	
	var next_state: ENEMY_STATE = ENEMY_STATE.PATROLLING
	if is_idle:
		next_state = ENEMY_STATE.RETURNING
	set_state(next_state)

func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	move_and_slide()

func _on_detect(body: Node2D) -> void:
	set_nav_to_position(body.global_position)
	set_state(ENEMY_STATE.CHASING)

func _on_lost(body: Node2D) -> void:
	set_nav_to_position(body.global_position)
	set_state(ENEMY_STATE.SEARCHING)
