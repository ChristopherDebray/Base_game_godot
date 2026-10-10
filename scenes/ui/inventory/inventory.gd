extends Control
class_name Inventory

@onready var inventory_container: GridContainer = $VBoxContainer/MarginContainer/GridContainer

@export var inventory_size: int = 8

var inventory := []

const INVENTORY_SLOT = preload("uid://b37dqi5t2q2ra")
const MACHINE_GUN = preload("uid://dqw2hvpvfgwgr")

func _ready() -> void:
	for i in inventory_size:
		var slot := INVENTORY_SLOT.instantiate()
		inventory_container.add_child(slot)
		inventory.push_back(slot)
	
	add_item_to_index(1, MACHINE_GUN)

func add_item_to_index(index: int, data: BaseWeaponData):
	var inventory_slot: InventorySlot = inventory.get(index)
	if !inventory_slot:
		return
		
	inventory_slot.texture_rect.texture = data.item_texture

func pop_item_at_index(index: int):
	return inventory.pop_at(index)

func swap_item_at_index(prev_index: int, new_index: int, base_inventory: Inventory):
	var targeted_slot_item = inventory.pop_at(prev_index)
	if !targeted_slot_item:
		return
	
	# We take the item at index from the initial inventory, can be same or another
	var new_item = base_inventory.pop_item_at_index(new_index)
	add_item_to_index(new_item, new_item)
