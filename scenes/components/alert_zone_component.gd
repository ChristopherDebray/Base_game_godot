extends Area2D

## Zone d'alerte circulaire : alerte les `Npc` qui s'y trouvent vers une position. Elle ne connaît
## ni la caméra ni le joueur, elle reçoit seulement une position (réutilisable pour une alarme).
## Tant qu'une cible est définie (`set_target`), un `Npc` qui entre dans la zone est alerté lui
## aussi : l'alerte ne dépend donc pas de qui était déjà là au moment de la détection.
class_name AlertZoneComponent

@export var radius: float = 300.0

var _target: Vector2 = Vector2.INF

func _ready() -> void:
	# Les ennemis sont sur leur propre layer ; la zone ne détecte rien d'autre.
	collision_layer = 0
	collision_mask = CollisionManager.MASK_ENEMY
	_build_shape()
	body_entered.connect(_on_body_entered)

## Alerte immédiatement chaque `Npc` actuellement dans la zone vers `target_position`.
func alert(target_position: Vector2) -> void:
	for body in get_overlapping_bodies():
		_alert_body(body, target_position)

## Mémorise la position à communiquer aux `Npc` qui entreront dans la zone.
func set_target(target_position: Vector2) -> void:
	_target = target_position

## Oublie la cible : les `Npc` qui entrent ensuite ne sont plus alertés.
func clear_target() -> void:
	_target = Vector2.INF

func _build_shape() -> void:
	var circle := CircleShape2D.new()
	circle.radius = radius
	var shape := CollisionShape2D.new()
	shape.shape = circle
	add_child(shape)

func _alert_body(body: Node2D, target_position: Vector2) -> void:
	if not body is Npc:
		return

	body.alert_to(target_position)

func _on_body_entered(body: Node2D) -> void:
	if _target == Vector2.INF:
		return

	_alert_body(body, _target)
