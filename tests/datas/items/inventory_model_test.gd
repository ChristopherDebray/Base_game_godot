class_name InventoryModelTest
extends GdUnitTestSuite

## Tests de l'InventoryModel : logique pure (RefCounted), aucun SceneTree requis.
## Les ItemInstance sont aussi des RefCounted : libérés automatiquement, pas besoin d'`auto_free`.

const ItemType = BaseItemData.ITEM_TYPE
const BAG_SIZE: int = 3
const OUT_OF_RANGE_INDEX: int = 99

func _create_item(type: ItemType) -> ItemInstance:
	var item_data := BaseItemData.new()
	item_data.type = type
	return ItemInstance.new(item_data)


## Slots 0 = armes primaires uniquement, 1 = tête uniquement, 2 = libre.
func _create_restricted_model() -> InventoryModel:
	return InventoryModel.new([[ItemType.PRIMARY], [ItemType.HEAD], []])


# --- Construction ---

func test_with_size_creates_empty_slots() -> void:
	var model := InventoryModel.with_size(BAG_SIZE)

	assert_int(model.slots.size()).is_equal(BAG_SIZE)
	assert_object(model.get_item(0)).is_null()


func test_init_creates_one_slot_per_rule() -> void:
	var model := _create_restricted_model()

	assert_int(model.slots.size()).is_equal(3)


# --- set_item / get_item ---

func test_set_item_then_get_item_returns_same_item() -> void:
	var model := InventoryModel.with_size(BAG_SIZE)
	var item := _create_item(ItemType.OTHER)

	model.set_item(1, item)

	assert_object(model.get_item(1)).is_same(item)


func test_set_item_emits_slot_changed_with_index() -> void:
	var model := InventoryModel.with_size(BAG_SIZE)
	monitor_signals(model, false)

	model.set_item(2, _create_item(ItemType.OTHER))

	await assert_signal(model).is_emitted("slot_changed", [2])


# --- can_place ---

func test_can_place_null_is_always_allowed() -> void:
	var model := _create_restricted_model()

	assert_bool(model.can_place(0, null)).is_true()


func test_can_place_in_unrestricted_slot_accepts_any_type() -> void:
	var model := _create_restricted_model()

	assert_bool(model.can_place(2, _create_item(ItemType.FEET))).is_true()


func test_can_place_accepts_type_listed_in_rules() -> void:
	var model := _create_restricted_model()

	assert_bool(model.can_place(0, _create_item(ItemType.PRIMARY))).is_true()


func test_can_place_refuses_type_not_listed_in_rules() -> void:
	var model := _create_restricted_model()

	assert_bool(model.can_place(0, _create_item(ItemType.HEAD))).is_false()


func test_can_place_out_of_range_index_returns_false() -> void:
	var model := InventoryModel.with_size(BAG_SIZE)

	assert_bool(model.can_place(OUT_OF_RANGE_INDEX, _create_item(ItemType.OTHER))).is_false()


# --- find_slot_for ---

func test_find_slot_for_returns_first_empty_slot() -> void:
	var model := InventoryModel.with_size(BAG_SIZE)
	model.set_item(0, _create_item(ItemType.OTHER))

	assert_int(model.find_slot_for(_create_item(ItemType.OTHER))).is_equal(1)


func test_find_slot_for_skips_slots_refusing_the_type() -> void:
	var model := _create_restricted_model()

	# Les slots 0 et 1 refusent FEET : le premier slot valide est le 2.
	assert_int(model.find_slot_for(_create_item(ItemType.FEET))).is_equal(2)


func test_find_slot_for_full_inventory_returns_minus_one() -> void:
	var model := InventoryModel.with_size(2)
	model.set_item(0, _create_item(ItemType.OTHER))
	model.set_item(1, _create_item(ItemType.OTHER))

	assert_int(model.find_slot_for(_create_item(ItemType.OTHER))).is_equal(-1)


func test_find_slot_for_null_item_returns_minus_one() -> void:
	var model := InventoryModel.with_size(BAG_SIZE)

	assert_int(model.find_slot_for(null)).is_equal(-1)


# --- can_move ---

func test_can_move_to_same_slot_of_same_model_is_refused() -> void:
	var model := InventoryModel.with_size(BAG_SIZE)
	model.set_item(0, _create_item(ItemType.OTHER))

	assert_bool(model.can_move(model, 0, 0)).is_false()


func test_can_move_from_empty_slot_is_refused() -> void:
	var model := InventoryModel.with_size(BAG_SIZE)

	assert_bool(model.can_move(model, 0, 1)).is_false()


func test_can_move_refuses_item_rejected_by_destination() -> void:
	var bag := InventoryModel.with_size(BAG_SIZE)
	var weapons := _create_restricted_model()
	bag.set_item(0, _create_item(ItemType.HEAD))

	# Slot 0 de `weapons` n'accepte que PRIMARY.
	assert_bool(weapons.can_move(bag, 0, 0)).is_false()


func test_can_move_refuses_swap_when_origin_rejects_the_displaced_item() -> void:
	var bag := InventoryModel.with_size(BAG_SIZE)
	var weapons := _create_restricted_model()
	weapons.set_item(0, _create_item(ItemType.PRIMARY))
	bag.set_item(0, _create_item(ItemType.HEAD))

	# La destination (bag) accepte PRIMARY, mais l'échange renverrait HEAD dans le slot 0
	# de `weapons`, qui n'accepte que PRIMARY : le déplacement entier doit être refusé.
	assert_bool(bag.can_move(weapons, 0, 0)).is_false()


func test_can_move_out_of_range_source_index_returns_false() -> void:
	var model := InventoryModel.with_size(BAG_SIZE)

	assert_bool(model.can_move(model, OUT_OF_RANGE_INDEX, 0)).is_false()


func test_can_move_out_of_range_destination_index_returns_false() -> void:
	var model := InventoryModel.with_size(BAG_SIZE)
	model.set_item(0, _create_item(ItemType.OTHER))

	assert_bool(model.can_move(model, 0, OUT_OF_RANGE_INDEX)).is_false()


# --- move ---

func test_move_to_empty_slot_transfers_item() -> void:
	var model := InventoryModel.with_size(BAG_SIZE)
	var item := _create_item(ItemType.OTHER)
	model.set_item(0, item)

	var moved := model.move(model, 0, 2)

	assert_bool(moved).is_true()
	assert_object(model.get_item(2)).is_same(item)
	assert_object(model.get_item(0)).is_null()


func test_move_onto_occupied_slot_swaps_items() -> void:
	var model := InventoryModel.with_size(BAG_SIZE)
	var first_item := _create_item(ItemType.OTHER)
	var second_item := _create_item(ItemType.OTHER)
	model.set_item(0, first_item)
	model.set_item(1, second_item)

	model.move(model, 0, 1)

	assert_object(model.get_item(0)).is_same(second_item)
	assert_object(model.get_item(1)).is_same(first_item)


func test_move_between_models_emits_slot_changed_on_both() -> void:
	var bag := InventoryModel.with_size(BAG_SIZE)
	var weapons := _create_restricted_model()
	bag.set_item(1, _create_item(ItemType.PRIMARY))
	monitor_signals(bag, false)
	monitor_signals(weapons, false)

	weapons.move(bag, 1, 0)

	await assert_signal(weapons).is_emitted("slot_changed", [0])
	await assert_signal(bag).is_emitted("slot_changed", [1])


func test_move_refused_returns_false_and_keeps_state() -> void:
	var bag := InventoryModel.with_size(BAG_SIZE)
	var weapons := _create_restricted_model()
	var helmet := _create_item(ItemType.HEAD)
	bag.set_item(0, helmet)

	var moved := weapons.move(bag, 0, 0)

	assert_bool(moved).is_false()
	assert_object(bag.get_item(0)).is_same(helmet)
	assert_object(weapons.get_item(0)).is_null()


func test_move_refused_emits_no_signal() -> void:
	var bag := InventoryModel.with_size(BAG_SIZE)
	var weapons := _create_restricted_model()
	bag.set_item(0, _create_item(ItemType.HEAD))
	monitor_signals(weapons, false)
	monitor_signals(bag, false)

	weapons.move(bag, 0, 0)

	await assert_signal(weapons).is_not_emitted("slot_changed")
	await assert_signal(bag).is_not_emitted("slot_changed")
