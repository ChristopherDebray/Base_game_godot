extends Resource

class_name BaseItemData

enum ITEM_TYPE {HEAD, CHEST, LEGS, FEET, PRIMARY, SECONDARY, GADGET, OTHER}

@export var type: ITEM_TYPE
@export var item_name: String
@export_multiline var description: String
@export var item_texture: Texture2D
@export var equipped_scene: PackedScene  # la scène utilisée quand c'est équipé (arme, gadget...)
