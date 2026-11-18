class_name InventoryModel
extends RefCounted

signal slot_changed(index: int)

var slots: Array[ItemInstance] = []
# rules[i] = types acceptés par le slot i, [] = tout
var rules: Array = []

func _init(slots_rules: Array) -> void:
	rules = slots_rules
	slots.resize(slots_rules.size())

static func with_size(size: int) -> InventoryModel:
	var slots_rules: Array = []
	for i in size:
		slots_rules.append([])
	return InventoryModel.new(slots_rules)

func get_item(i: int) -> ItemInstance:
	return slots[i]

func set_item(i: int, item: ItemInstance) -> void:
	slots[i] = item
	slot_changed.emit(i)

## Indique si `index` désigne un slot existant. Les index viennent du drag & drop (donnée
## externe) : on les valide avant tout accès au tableau pour éviter une erreur d'exécution.
func is_valid_index(index: int) -> bool:
	return index >= 0 and index < slots.size()

func can_place(i: int, item: ItemInstance) -> bool:
	if not is_valid_index(i):
		return false
	if item == null:
		return true
	var types: Array = rules[i]
	return types.is_empty() or item.data.type in types

## Renvoie l'index du premier slot vide qui accepte `item`, ou -1 s'il n'y en a pas.
func find_slot_for(item: ItemInstance) -> int:
	if item == null:
		return -1
	for slot_index in slots.size():
		if slots[slot_index] == null and can_place(slot_index, item):
			return slot_index
	return -1

func can_move(from: InventoryModel, from_index: int, to_index: int) -> bool:
	if not from.is_valid_index(from_index) or not is_valid_index(to_index):
		return false
	if from == self and from_index == to_index:
		return false
	var item_instance := from.slots[from_index]
	if item_instance == null:
		return false
	return can_place(to_index, item_instance) and from.can_place(from_index, slots[to_index])

func move(from: InventoryModel, from_index: int, to_index: int) -> bool:
	if not can_move(from, from_index, to_index):
		return false
	var from_item_instance := from.slots[from_index]
	var target_item_instance := slots[to_index]
	slots[to_index] = from_item_instance
	from.slots[from_index] = target_item_instance
	slot_changed.emit(to_index)
	from.slot_changed.emit(from_index)
	return true
