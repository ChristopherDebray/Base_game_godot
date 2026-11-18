## Données statiques d'un objet (type de slot, nom, texture, scène équipée).
## Resource partagée : l'état runtime d'un objet vit dans `ItemInstance`.
class_name BaseItemData
extends Resource

enum ITEM_TYPE {HEAD, CHEST, LEGS, FEET, BACK, PRIMARY, SECONDARY, GADGET, OTHER, ANY}

@export var type: ITEM_TYPE
@export var item_name: String
@export_multiline var description: String
@export var item_texture: Texture2D
@export_file("*.tscn") var equipped_scene_path: String
