extends Node2D

class_name ObjectsHolderComponent

@export var object_holder: ObjectHolderComponent
@export var muzzle: Node2D

# TODO add typing to only allow specific type in specific location
const OBJECT_MAPPING = {
	"1": "weapon",
	"2": "weapon",
	"3": "weapon",
	"4": "weapon",
	"5": "weapon",
}

var objects: Array[BaseWeapon] = [null, null, null, null, null]
var current_targeted_index: int = 0

func get_object_at(index: int) -> BaseWeapon:
	return objects.get(index)

func set_object_at(index: int, object: BaseWeapon):
	objects.set(index, object)
	if current_targeted_index == index:
		set_holded_object_to(index)

func set_holded_object_to(index: int):
	var object = get_object_at(index)
	if !object:
		return
	
	_set_holded_object(object, index)

func set_holded_object_to_next():
	var next_index = 1 + current_targeted_index
	var object = objects.get(next_index)
	if !object:
		return

	_set_holded_object(object, next_index)

func set_holded_object_to_previous():
	var previous_index = -1 + current_targeted_index
	var object = objects.get(previous_index)
	if !object:
		return

	_set_holded_object(object, previous_index)

func _set_holded_object(object: BaseWeapon, index: int):
	object_holder.switch_weapon(object, muzzle.position)
	current_targeted_index = index
