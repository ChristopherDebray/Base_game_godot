extends Node

## État d'un appareil électronique (allumé, éteint, cassé), à ajouter en enfant de n'importe quel
## node (caméra, porte, tourelle…). Le propriétaire écoute `state_changed` pour réagir : le composant
## ne connaît pas son parent. Un appareil cassé est définitif : il ignore toute commande.
class_name ElectronicDeviceComponent

enum DeviceState { ON, OFF, BROKEN }

## Émis uniquement quand l'état change réellement.
signal state_changed(new_state: DeviceState)

@export var state: DeviceState = DeviceState.ON

## Vrai si l'appareil fonctionne (allumé).
func is_active() -> bool:
	return state == DeviceState.ON

## Allume l'appareil. Sans effet s'il est cassé.
func turn_on() -> void:
	_set_state(DeviceState.ON)

## Éteint l'appareil. Sans effet s'il est cassé.
func turn_off() -> void:
	_set_state(DeviceState.OFF)

## Inverse allumé / éteint. Sans effet s'il est cassé.
func toggle() -> void:
	if is_active():
		turn_off()
		return
	turn_on()

## Casse l'appareil définitivement : il ne pourra plus être rallumé.
func break_device() -> void:
	_set_state(DeviceState.BROKEN)

func _set_state(new_state: DeviceState) -> void:
	if state == DeviceState.BROKEN or state == new_state:
		return

	state = new_state
	state_changed.emit(new_state)
