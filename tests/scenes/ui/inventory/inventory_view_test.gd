class_name InventoryViewTest
extends GdUnitTestSuite

## Tests de l'InventoryView : une case par slot du modèle, branchée sur ce modèle.

const SLOT_SCENE_PATH := "res://scenes/ui/inventory/inventory_slot.tscn"
const MODEL_SIZE: int = 4
const SMALLER_MODEL_SIZE: int = 2
const FIRST_MANUAL_SLOT_INDEX: int = 1
const SECOND_MANUAL_SLOT_INDEX: int = 3
const ITEM_NAME := "Casque"

var _view: InventoryView


func before_test() -> void:
	_view = auto_free(InventoryView.new())
	add_child(_view)


func _count_slots() -> int:
	return _view.get_children().filter(
		func(child: Node) -> bool: return child is InventorySlot and not child.is_queued_for_deletion()).size()


func _create_manual_slot(slot_index: int) -> InventorySlot:
	var slot: InventorySlot = load(SLOT_SCENE_PATH).instantiate()
	slot.slot_index = slot_index
	_view.add_child(slot)
	return slot


func test_build_creates_one_slot_per_model_slot() -> void:
	_view.build(InventoryModel.with_size(MODEL_SIZE))

	assert_int(_count_slots()).is_equal(MODEL_SIZE)


func test_build_numbers_slots_in_model_order() -> void:
	_view.build(InventoryModel.with_size(MODEL_SIZE))

	var last_slot: InventorySlot = _view.get_child(MODEL_SIZE - 1)
	assert_int(last_slot.slot_index).is_equal(MODEL_SIZE - 1)


func test_build_binds_every_slot_to_the_model() -> void:
	var model := InventoryModel.with_size(MODEL_SIZE)

	_view.build(model)

	var bound_models: Array = _view.get_children().map(func(slot: InventorySlot) -> InventoryModel: return slot.model)
	assert_array(bound_models).contains_exactly([model, model, model, model])


func test_build_again_replaces_previous_slots() -> void:
	_view.build(InventoryModel.with_size(MODEL_SIZE))

	_view.build(InventoryModel.with_size(SMALLER_MODEL_SIZE))

	assert_int(_count_slots()).is_equal(SMALLER_MODEL_SIZE)


func test_build_with_empty_model_creates_no_slot() -> void:
	_view.build(InventoryModel.with_size(0))

	assert_int(_count_slots()).is_equal(0)


func test_bind_existing_displays_the_item_of_the_index_set_in_the_inspector() -> void:
	var slot := _create_manual_slot(SECOND_MANUAL_SLOT_INDEX)
	var model := InventoryModel.with_size(MODEL_SIZE)
	var item_data := BaseItemData.new()
	item_data.item_name = ITEM_NAME
	model.set_item(SECOND_MANUAL_SLOT_INDEX, ItemInstance.new(item_data))

	_view.bind_existing(model)

	assert_str(slot.tooltip_text).contains(ITEM_NAME)


func test_bind_existing_binds_manual_slots_to_the_model() -> void:
	var slot := _create_manual_slot(FIRST_MANUAL_SLOT_INDEX)
	var model := InventoryModel.with_size(MODEL_SIZE)

	_view.bind_existing(model)

	assert_object(slot.model).is_same(model)


func test_bind_existing_ignores_children_that_are_not_slots() -> void:
	var other_child: Control = auto_free(Control.new())
	_view.add_child(other_child)
	var slot := _create_manual_slot(FIRST_MANUAL_SLOT_INDEX)
	var model := InventoryModel.with_size(MODEL_SIZE)

	_view.bind_existing(model)

	assert_object(slot.model).is_same(model)
