## Exemplaire runtime d'un objet : associe la Resource partagée `BaseItemData` à la scène
## instanciée, pour que l'état (munitions...) soit propre à chaque exemplaire.
class_name ItemInstance
extends RefCounted

var data: BaseItemData
# Créée à la demande, garde les munitions etc
var scene_instance: Node2D

func _init(item_data: BaseItemData) -> void:
	data = item_data

## Renvoie la scène équipée de l'objet, instanciée au premier appel puis réutilisée
## (même nœud ensuite, afin de conserver son état). Injecte `data` dans une `BaseWeapon`.
func get_scene() -> Node2D:
	if scene_instance == null:
		var packed: PackedScene = load(data.equipped_scene_path)
		scene_instance = packed.instantiate()
		if scene_instance is BaseWeapon:
			scene_instance.data = data as BaseWeaponData
	return scene_instance
