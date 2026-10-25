class_name ItemInstance
extends RefCounted

var data: BaseItemData
# Créée à la demande, garde les munitions etc
var scene_instance: Node2D

func _init(item_data: BaseItemData) -> void:
	data = item_data

func get_scene() -> Node2D:
	if scene_instance == null:
		var packed: PackedScene = load(data.equipped_scene_path)
		scene_instance = packed.instantiate()
		if scene_instance is BaseWeapon:
			scene_instance.data = data as BaseWeaponData
	return scene_instance
