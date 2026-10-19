extends Control
class_name Inventory

@onready var inventory_container: GridContainer = $VBoxContainer/MarginContainer/GridContainer

@export var inventory_size: int = 8

const INVENTORY_SLOT = preload("uid://b37dqi5t2q2ra")
const MACHINE_GUN = preload("uid://dqw2hvpvfgwgr")
const _9_MM_GUN = preload("uid://ddwe31sqyyulb")

func _ready() -> void:
	for i in inventory_size:
		var slot := INVENTORY_SLOT.instantiate()
		inventory_container.add_child(slot)
	
	var item = InventoryItem.new()
	item.init(MACHINE_GUN)
	add_item_to_index(0, item)
	
	var item2 = InventoryItem.new()
	item2.init(_9_MM_GUN)
	add_item_to_index(1, item2)

func add_item_to_index(index: int, item: InventoryItem):
	var inventory_slot: InventorySlot = inventory_container.get_child(index)
	if !inventory_slot:
		return
	
	inventory_slot.add_child(item)

func pop_item_at_index(index: int):
	var inventory_slot: InventorySlot = inventory_container.get_child(index)
	if !inventory_slot:
		return
	
	var child = inventory_slot.get_child(0)
	if !child:
		return
	
	inventory_slot.remove_child(child)

	return child
#
func swap_item_at_index(prev_index: int, new_index: int, base_inventory: Inventory):
	var targeted_slot_item = pop_item_at_index(prev_index)
	if !targeted_slot_item:
		return
	
	# We take the item at index from the initial inventory, can be same or another
	var new_item = base_inventory.pop_item_at_index(new_index)
	add_item_to_index(new_item, new_item)
