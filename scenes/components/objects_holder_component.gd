extends Node2D

class_name ObjectsHolderComponent

@export var object_holder: ObjectHolderComponent
@export var muzzle: Node2D

var weapons: InventoryModel
var current_targeted_index: int = 0

func bind(model: InventoryModel) -> void:
	weapons = model
	weapons.slot_changed.connect(_on_slot_changed)

func _on_slot_changed(i: int) -> void:
	if i != current_targeted_index:
		return
	
	_equip(i)

func set_holded_object_to(i: int) -> void:
	if _equip(i):
		current_targeted_index = i

func set_holded_object_to_next() -> void:
	set_holded_object_to(current_targeted_index + 1)

func set_holded_object_to_previous() -> void:
	set_holded_object_to(current_targeted_index - 1)

func _equip(i: int) -> bool:
	if i < 0 or i >= weapons.slots.size():
		return false
	var item := weapons.get_item(i)
	if item == null:
		return false
	object_holder.switch_weapon(item.get_scene() as BaseWeapon, muzzle.position)
	return true
