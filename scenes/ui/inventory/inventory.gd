extends Control
class_name Inventory

@onready var inventory_container: GridContainer = $MarginContainer/VBoxContainer/GridContainer

@export var inventory_size: int = 8

const INVENTORY_SLOT = preload("uid://b37dqi5t2q2ra")
const MACHINE_GUN_PATH = "uid://dqw2hvpvfgwgr"
const _9_MM_GUN_PATH = "uid://ddwe31sqyyulb"

func _ready() -> void:
	for i in inventory_size:
		var slot := INVENTORY_SLOT.instantiate()
		inventory_container.add_child(slot)
	
	add_test_items()

func add_item_to_index(index: int, item: InventoryItem):
	var inventory_slot: InventorySlot = inventory_container.get_child(index)
	if not inventory_slot or not inventory_slot.accepts(item):
		return
	
	inventory_slot.add_child(item)

func add_test_items():
	var item = InventoryItem.new()
	item.init(load(MACHINE_GUN_PATH))
	add_item_to_index(0, item)
	
	var item2 = InventoryItem.new()
	item2.init(load(_9_MM_GUN_PATH))
	add_item_to_index(1, item2)
