class_name InventorySlotTest
extends GdUnitTestSuite

## Tests de l'InventorySlot : validation des données de drag & drop (entrée externe) et
## synchronisation avec le modèle. On n'affiche rien : seule la logique est vérifiée.
##
## Non couvert : `_get_drag_data` sur un slot rempli. Il appelle `set_drag_preview`, qui exige un
## vrai drag en cours : hors drag, l'aperçu créé fuit (orphelins) et le moteur logue une erreur.
## Refactoring proposé : extraire la construction de `{"model", "index"}` dans une fonction pure.
##
## Les méthodes `_get_drag_data`, `_can_drop_data` et `_drop_data` sont des callbacks moteur
## sans équivalent public : on les appelle directement.

const SLOT_SCENE_PATH := "res://scenes/ui/inventory/inventory_slot.tscn"
const SLOT_COUNT: int = 3
const SOURCE_INDEX: int = 0
const TARGET_INDEX: int = 1
const OUT_OF_RANGE_INDEX: int = 99
const NEGATIVE_INDEX: int = -1
const DRAG_POSITION := Vector2.ZERO
const ITEM_NAME := "Pistolet"
const ITEM_DESCRIPTION := "Une arme de poing"
const KEY_MODEL := "model"
const KEY_INDEX := "index"
const ItemType = BaseItemData.ITEM_TYPE

var _model: InventoryModel
var _slot: InventorySlot


func before_test() -> void:
	_model = InventoryModel.with_size(SLOT_COUNT)
	_slot = auto_free(load(SLOT_SCENE_PATH).instantiate())
	add_child(_slot)
	_slot.setup(_model, TARGET_INDEX)


func _create_item(type: ItemType = ItemType.OTHER) -> ItemInstance:
	var item_data := BaseItemData.new()
	item_data.type = type
	item_data.item_name = ITEM_NAME
	item_data.description = ITEM_DESCRIPTION
	return ItemInstance.new(item_data)


func _drag_data(model: Variant, index: Variant) -> Dictionary:
	return {KEY_MODEL: model, KEY_INDEX: index}


# ---------- _get_drag_data ----------

func test_drag_from_empty_slot_starts_nothing() -> void:
	assert_that(_slot._get_drag_data(DRAG_POSITION)).is_null()


# ---------- _can_drop_data ----------

func test_drop_of_valid_move_is_accepted() -> void:
	_model.set_item(SOURCE_INDEX, _create_item())

	assert_bool(_slot._can_drop_data(DRAG_POSITION, _drag_data(_model, SOURCE_INDEX))).is_true()


func test_drop_of_non_dictionary_is_refused() -> void:
	assert_bool(_slot._can_drop_data(DRAG_POSITION, "pas un dictionnaire")).is_false()


func test_drop_of_null_is_refused() -> void:
	assert_bool(_slot._can_drop_data(DRAG_POSITION, null)).is_false()


func test_drop_without_model_is_refused() -> void:
	assert_bool(_slot._can_drop_data(DRAG_POSITION, {KEY_INDEX: SOURCE_INDEX})).is_false()


func test_drop_with_model_of_wrong_type_is_refused() -> void:
	assert_bool(_slot._can_drop_data(DRAG_POSITION, _drag_data("pas un modèle", SOURCE_INDEX))).is_false()


func test_drop_from_out_of_range_index_is_refused() -> void:
	assert_bool(_slot._can_drop_data(DRAG_POSITION, _drag_data(_model, OUT_OF_RANGE_INDEX))).is_false()


func test_drop_from_negative_index_is_refused() -> void:
	assert_bool(_slot._can_drop_data(DRAG_POSITION, _drag_data(_model, NEGATIVE_INDEX))).is_false()


func test_drop_from_empty_slot_is_refused() -> void:
	assert_bool(_slot._can_drop_data(DRAG_POSITION, _drag_data(_model, SOURCE_INDEX))).is_false()


func test_drop_refused_by_slot_type_rules_is_refused() -> void:
	var restricted_model := InventoryModel.new([[ItemType.HEAD], [ItemType.HEAD]])
	var restricted_slot: InventorySlot = auto_free(load(SLOT_SCENE_PATH).instantiate())
	add_child(restricted_slot)
	restricted_slot.setup(restricted_model, TARGET_INDEX)
	_model.set_item(SOURCE_INDEX, _create_item(ItemType.PRIMARY))

	assert_bool(restricted_slot._can_drop_data(DRAG_POSITION, _drag_data(_model, SOURCE_INDEX))).is_false()


func test_drop_on_the_same_slot_is_refused() -> void:
	_model.set_item(TARGET_INDEX, _create_item())

	assert_bool(_slot._can_drop_data(DRAG_POSITION, _drag_data(_model, TARGET_INDEX))).is_false()


func test_drop_from_another_model_is_accepted() -> void:
	var other_model := InventoryModel.with_size(SLOT_COUNT)
	other_model.set_item(SOURCE_INDEX, _create_item())

	assert_bool(_slot._can_drop_data(DRAG_POSITION, _drag_data(other_model, SOURCE_INDEX))).is_true()


func test_drop_refused_by_source_slot_rules_when_swapping_is_refused() -> void:
	# L'échange renverrait l'objet de la cible vers un slot source qui ne l'accepte pas.
	var restricted_model := InventoryModel.new([[ItemType.HEAD], []])
	restricted_model.set_item(SOURCE_INDEX, _create_item(ItemType.HEAD))
	_model.set_item(TARGET_INDEX, _create_item(ItemType.PRIMARY))

	assert_bool(_slot._can_drop_data(DRAG_POSITION, _drag_data(restricted_model, SOURCE_INDEX))).is_false()


# ---------- _drop_data ----------

func test_drop_moves_the_dragged_item_into_the_slot() -> void:
	var item := _create_item()
	_model.set_item(SOURCE_INDEX, item)

	_slot._drop_data(DRAG_POSITION, _drag_data(_model, SOURCE_INDEX))

	assert_object(_model.get_item(TARGET_INDEX)).is_same(item)


func test_drop_empties_the_source_slot() -> void:
	_model.set_item(SOURCE_INDEX, _create_item())

	_slot._drop_data(DRAG_POSITION, _drag_data(_model, SOURCE_INDEX))

	assert_object(_model.get_item(SOURCE_INDEX)).is_null()


func test_drop_on_occupied_slot_swaps_the_two_items() -> void:
	var dragged_item := _create_item()
	var displaced_item := _create_item()
	_model.set_item(SOURCE_INDEX, dragged_item)
	_model.set_item(TARGET_INDEX, displaced_item)

	_slot._drop_data(DRAG_POSITION, _drag_data(_model, SOURCE_INDEX))

	assert_object(_model.get_item(SOURCE_INDEX)).is_same(displaced_item)


func test_refused_drop_leaves_the_model_untouched() -> void:
	var item := _create_item()
	_model.set_item(SOURCE_INDEX, item)

	_slot._drop_data(DRAG_POSITION, _drag_data(_model, OUT_OF_RANGE_INDEX))

	assert_object(_model.get_item(SOURCE_INDEX)).is_same(item)


# ---------- synchronisation avec le modèle ----------

func test_refresh_shows_item_tooltip() -> void:
	_model.set_item(TARGET_INDEX, _create_item())

	assert_str(_slot.tooltip_text).is_equal("%s\n%s" % [ITEM_NAME, ITEM_DESCRIPTION])


func test_refresh_after_item_removed_clears_tooltip() -> void:
	_model.set_item(TARGET_INDEX, _create_item())

	_model.set_item(TARGET_INDEX, null)

	assert_str(_slot.tooltip_text).is_empty()


func test_change_on_other_slot_does_not_refresh_the_tooltip() -> void:
	_model.set_item(SOURCE_INDEX, _create_item())

	assert_str(_slot.tooltip_text).is_empty()


func test_setup_with_new_model_disconnects_from_the_previous_model() -> void:
	_slot.setup(InventoryModel.with_size(SLOT_COUNT), TARGET_INDEX)

	assert_array(_model.slot_changed.get_connections()).is_empty()


func test_setup_on_model_with_existing_item_shows_its_tooltip() -> void:
	var filled_model := InventoryModel.with_size(SLOT_COUNT)
	filled_model.set_item(TARGET_INDEX, _create_item())

	_slot.setup(filled_model, TARGET_INDEX)

	assert_str(_slot.tooltip_text).is_equal("%s\n%s" % [ITEM_NAME, ITEM_DESCRIPTION])


func test_refresh_shows_item_texture_in_the_icon() -> void:
	var texture := ImageTexture.create_from_image(Image.create(2, 2, false, Image.FORMAT_RGBA8))
	var item := _create_item()
	item.data.item_texture = texture

	_model.set_item(TARGET_INDEX, item)

	assert_object(_slot.icon.texture).is_same(texture)
