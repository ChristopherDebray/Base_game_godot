extends Node2D

## Choisit l'arme tenue selon l'index d'un slot de l'inventaire d'armes (`InventoryModel`) et la
## délègue à `ObjectHolderComponent`. Ré-équipe automatiquement si le slot ciblé change.
class_name ObjectsHolderComponent

@export var object_holder: ObjectHolderComponent
@export var muzzle: Node2D

var weapons: InventoryModel
var current_targeted_index: int = 0

## Branche le composant sur le modèle d'armes `model` et écoute ses changements de slot.
func bind(model: InventoryModel) -> void:
	weapons = model
	weapons.slot_changed.connect(_on_slot_changed)

func _on_slot_changed(slot_index: int) -> void:
	if slot_index != current_targeted_index:
		return
	
	_equip(slot_index)

## Équipe l'objet du slot `slot_index` et le mémorise comme slot ciblé. Sans effet si l'index
## est hors bornes ou si le slot est vide (le slot ciblé précédent est conservé).
func set_holded_object_to(slot_index: int) -> void:
	if _equip(slot_index):
		current_targeted_index = slot_index

## Cible le slot suivant (voir `set_holded_object_to`).
func set_holded_object_to_next() -> void:
	set_holded_object_to(current_targeted_index + 1)

## Cible le slot précédent (voir `set_holded_object_to`).
func set_holded_object_to_previous() -> void:
	set_holded_object_to(current_targeted_index - 1)

func _equip(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= weapons.slots.size():
		return false
	var item := weapons.get_item(slot_index)
	if item == null:
		return false
	object_holder.switch_weapon(item.get_scene() as BaseWeapon, muzzle.position)
	return true
