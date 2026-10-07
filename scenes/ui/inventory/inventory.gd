extends Control

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
