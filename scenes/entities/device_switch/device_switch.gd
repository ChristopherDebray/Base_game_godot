extends Area2D

## Interrupteur actionnable avec l'action `interact` quand le joueur est à portée. Il allume ou
## éteint tous les appareils liés : s'il en reste un d'allumé, tout s'éteint, sinon tout s'allume.
## Il ne connaît que `ElectronicDeviceComponent`, pas les entités qui les portent.
## Son collision_mask vise le layer 3 (`player`), comme `WorldItem`.
class_name DeviceSwitch

@export var devices: Array[ElectronicDeviceComponent] = []

@onready var prompt_label: Label = $PromptLabel

var _player_in_range: Player = null

func _ready() -> void:
	prompt_label.text = _get_interact_key_name()
	prompt_label.hide()
	# Éteint tant que le joueur n'est pas à portée : inutile de tester l'input à chaque frame.
	set_physics_process(false)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

## On interroge `Input` plutôt que `_unhandled_input` : ce node vit dans un SubViewport
## (LitViewport) qui ne reçoit pas les événements de la fenêtre principale.
func _physics_process(_delta: float) -> void:
	if not Input.is_action_just_pressed("interact"):
		return

	use()

## Actionne l'interrupteur : éteint tous les appareils liés si au moins un est allumé, sinon les
## allume tous. Les appareils cassés et les références libérées sont ignorés.
func use() -> void:
	var turn_off := _has_active_device()
	for device in devices:
		if not is_instance_valid(device):
			continue
		if turn_off:
			device.turn_off()
			continue
		device.turn_on()

func _has_active_device() -> bool:
	for device in devices:
		if is_instance_valid(device) and device.is_active():
			return true
	return false

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
