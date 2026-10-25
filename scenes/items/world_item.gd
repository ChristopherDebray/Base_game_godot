extends Area2D

## Objet posé dans le niveau, ramassable avec l'action `interact` quand le joueur est à portée.
## Son collision_mask vise le layer 3 (`player`) : par défaut une Area2D ne verrait pas le joueur.
class_name WorldItem

## Taille d'affichage (en pixels) du plus grand côté du sprite, quelle que soit la taille de la texture.
@export var display_size: float = 24.0

@export var data: BaseItemData

@onready var sprite: Sprite2D = $Sprite2D
@onready var prompt_label: Label = $PromptLabel

var _player_in_range: Player = null

func _ready() -> void:
	if data == null:
		push_warning("WorldItem sans data : %s" % get_path())
		queue_free()
		return

	_setup_sprite()
	prompt_label.text = _get_interact_key_name()
	prompt_label.hide()
	# Éteint tant que le joueur n'est pas à portée : inutile de tester l'input à chaque frame.
	set_physics_process(false)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

## On interroge `Input` plutôt que d'utiliser `_unhandled_input` : ce node vit dans un SubViewport
## (LitViewport) qui ne reçoit pas les événements de la fenêtre principale.
func _physics_process(_delta: float) -> void:
	if not Input.is_action_just_pressed("interact"):
		return

	# Inventaire plein : l'objet n'est pas consommé, il reste au sol.
	if not _player_in_range.pickup(data):
		return

	queue_free()

## Réduit ou agrandit le sprite pour que son plus grand côté fasse `display_size`.
func _setup_sprite() -> void:
	sprite.texture = data.item_texture
	if sprite.texture == null:
		return

	var texture_size := sprite.texture.get_size()
	var biggest_side := maxf(texture_size.x, texture_size.y)
	if biggest_side <= 0.0:
		return
	sprite.scale = Vector2.ONE * (display_size / biggest_side)

## Nom de la touche clavier liée à `interact` (suit le rebind), "?" si aucune.
func _get_interact_key_name() -> String:
	for input_event in InputMap.action_get_events("interact"):
		if input_event is InputEventKey and input_event.physical_keycode != KEY_NONE:
			var keycode := DisplayServer.keyboard_get_keycode_from_physical(input_event.physical_keycode)
			return OS.get_keycode_string(keycode)
	return "?"

func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	_player_in_range = body
	prompt_label.show()
	set_physics_process(true)

func _on_body_exited(body: Node2D) -> void:
	if body != _player_in_range:
		return
	_player_in_range = null
	prompt_label.hide()
	set_physics_process(false)
