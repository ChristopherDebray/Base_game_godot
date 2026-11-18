## Vue d'un `InventoryModel` : grille de `InventorySlot`, soit générés (`build`), soit posés à la
## main dans la scène (`bind_existing`).
class_name InventoryView
extends GridContainer

const SLOT_SCENE = preload("uid://b37dqi5t2q2ra")

## Pour un sac / coffre : remplace les enfants par un `InventorySlot` par case de `model`.
## Les anciens slots sont libérés (`queue_free`, effectif en fin de frame).
func build(model: InventoryModel) -> void:
	for child in get_children():
		child.queue_free()
	for i in model.slots.size():
		var slot: InventorySlot = SLOT_SCENE.instantiate()
		add_child(slot)
		slot.setup(model, i)

## Pour les slots posés à la main (Head, Chest, Primary...) : branche chaque `InventorySlot`
## enfant sur `model` en utilisant l'index réglé dans l'inspecteur.
func bind_existing(model: InventoryModel) -> void:
	for child in get_children():
		if child is InventorySlot:
			child.setup(model, child.slot_index)
