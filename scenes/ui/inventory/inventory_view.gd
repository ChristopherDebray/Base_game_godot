class_name InventoryView
extends GridContainer

const SLOT_SCENE = preload("uid://b37dqi5t2q2ra")

# Pour un sac / coffre : génère un slot par case du modèle
func build(model: InventoryModel) -> void:
	for child in get_children():
		child.queue_free()
	for i in model.slots.size():
		var slot: InventorySlot = SLOT_SCENE.instantiate()
		add_child(slot)
		slot.setup(model, i)

# Pour tes slots posés à la main (Head, Chest, Primary...) : index réglé dans l'inspecteur
func bind_existing(model: InventoryModel) -> void:
	for child in get_children():
		if child is InventorySlot:
			child.setup(model, child.index)
