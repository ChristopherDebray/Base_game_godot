extends Control
class_name Inventory

@onready var inventory_container: GridContainer = $MarginContainer/VBoxContainer/GridContainer

@export var armor_view: InventoryView
@export var weapons_view: InventoryView
@export var bag_view: InventoryView

func open(bag: InventoryModel, armor: InventoryModel, weapons: InventoryModel) -> void:
	armor_view.bind_existing(armor)
	weapons_view.bind_existing(weapons)
	bag_view.build(bag)
