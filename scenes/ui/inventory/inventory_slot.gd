extends ColorRect
class_name InventorySlot

@export var type: BaseItemData.ITEM_TYPE

var data: BaseWeaponData

func init(t: BaseItemData.ITEM_TYPE, cms: Vector2) -> void:
	type = t
	custom_minimum_size = cms

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if data is InventoryItem:
		if type == BaseItemData.ITEM_TYPE.PRIMARY:
			if get_child_count() == 0:
				return true
			else:
				if type == data.get_parent().type:
					return true
				return get_child(0).data.type == data.type
		else:
			# TODO set a condition to check matching types
			return true
	
	return false

func _drop_data(at_position: Vector2, data: Variant) -> void:
	if get_child_count() > 0:
		var item := get_child(0)
		if item == data:
			return
		item.reparent(data.get_parent(), false)
	data.reparent(self, false)
