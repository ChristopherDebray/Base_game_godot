extends ColorRect
class_name InventorySlot

@export var accepted_types: Array[BaseItemData.ITEM_TYPE] = []

var data: BaseWeaponData

func init(types: Array[BaseItemData.ITEM_TYPE], cms: Vector2) -> void:
	accepted_types = types
	custom_minimum_size = cms

func accepts(item: InventoryItem) -> bool:
	return accepted_types.is_empty() or item.data.type in accepted_types

func get_item() -> InventoryItem:
	# If we use get_child(0) we get an out of bound error
	for c in get_children():
		if c is InventoryItem:
			return c
	return null

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if data is not InventoryItem:
		return false
	var item: InventoryItem = data
	if not accepts(item):
		return false
	
	var occupant := get_item()
	if occupant and occupant != item:
		var origin := item.get_slot()
		return origin == null or origin.accepts(occupant)
	return true

func _drop_data(at_position: Vector2, data: Variant) -> void:
	var item: InventoryItem = data
	var occupant := get_item()
	if occupant == item:
		return
	if occupant:
		var origin := item.get_slot()
		if origin:
			occupant.reparent(origin, false)
	item.reparent(self, false)
