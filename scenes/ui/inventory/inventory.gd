extends Control
class_name Inventory

@onready var inventory_container: GridContainer = $MarginContainer/VBoxContainer/GridContainer

@export var armor_view: InventoryView
@export var weapons_view: InventoryView
@export var bag_view: InventoryView

## Affiche les trois inventaires : un slot est généré par case de chaque modèle,
## donc le nombre de slots affichés suit toujours le modèle du joueur.
func open(bag: InventoryModel, armor: InventoryModel, weapons: InventoryModel) -> void:
	armor_view.build(armor)
	weapons_view.build(weapons)
	bag_view.build(bag)
