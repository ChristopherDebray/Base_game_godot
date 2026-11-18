class_name ObjectsHolderComponentTest
extends GdUnitTestSuite

## Tests de l'ObjectsHolderComponent (choisit l'arme active selon le slot d'un InventoryModel).
##
## Les `ItemInstance` reçoivent directement une arme espion dans `scene_instance` : `get_scene()`
## la renvoie sans charger de scène. Le `ObjectHolderComponent` est réel et sert d'observateur
## (`current_weapon`).

const SLOT_COUNT: int = 3
const FIRST_SLOT: int = 0
const SECOND_SLOT: int = 1
const LAST_SLOT: int = SLOT_COUNT - 1
const OUT_OF_RANGE_INDEX: int = 99
const NEGATIVE_INDEX: int = -1
const MUZZLE_POSITION := Vector2(5.0, 0.0)

## Arme sans la hiérarchie de la vraie scène : `setup()` mémorise juste le muzzle reçu.
class WeaponStub extends BaseWeapon:
	var last_muzzle_position: Vector2 = Vector2.ZERO

	func _init() -> void:
		var sprite := AnimatedSprite2D.new()
		sprite.name = "AnimatedSprite2D"
		add_child(sprite)
		var muzzle_node := Node2D.new()
		muzzle_node.name = "Muzzle"
		add_child(muzzle_node)

	func setup(muzzle_position: Vector2) -> void:
		last_muzzle_position = muzzle_position


var _holder: ObjectsHolderComponent
var _object_holder: ObjectHolderComponent
var _model: InventoryModel


func before_test() -> void:
	_object_holder = auto_free(ObjectHolderComponent.new())
	add_child(_object_holder)
	var muzzle: Node2D = auto_free(Node2D.new())
	muzzle.position = MUZZLE_POSITION
	add_child(muzzle)
	_holder = auto_free(ObjectsHolderComponent.new())
	_holder.object_holder = _object_holder
	_holder.muzzle = muzzle
	add_child(_holder)
	_model = InventoryModel.with_size(SLOT_COUNT)
	_holder.bind(_model)


## Crée un item déjà « instancié » : `get_scene()` renverra l'arme fournie.
func _create_item_with_weapon() -> ItemInstance:
	var item := ItemInstance.new(BaseItemData.new())
	item.scene_instance = auto_free(WeaponStub.new())
	return item


func test_set_holded_object_to_equips_weapon_of_slot() -> void:
	var item := _create_item_with_weapon()
	_model.set_item(SECOND_SLOT, item)

	_holder.set_holded_object_to(SECOND_SLOT)

	assert_object(_object_holder.current_weapon).is_same(item.scene_instance)


func test_set_holded_object_to_passes_muzzle_position_to_weapon() -> void:
	var item := _create_item_with_weapon()
	_model.set_item(SECOND_SLOT, item)

	_holder.set_holded_object_to(SECOND_SLOT)

	assert_vector(item.scene_instance.last_muzzle_position).is_equal(MUZZLE_POSITION)


func test_set_holded_object_to_updates_targeted_index() -> void:
	_model.set_item(SECOND_SLOT, _create_item_with_weapon())

	_holder.set_holded_object_to(SECOND_SLOT)

	assert_int(_holder.current_targeted_index).is_equal(SECOND_SLOT)


func test_set_holded_object_to_empty_slot_keeps_targeted_index() -> void:
	_holder.set_holded_object_to(SECOND_SLOT)

	assert_int(_holder.current_targeted_index).is_equal(FIRST_SLOT)


func test_set_holded_object_to_empty_slot_keeps_current_weapon() -> void:
	var equipped_item := _create_item_with_weapon()
	_model.set_item(FIRST_SLOT, equipped_item)
	_holder.set_holded_object_to(FIRST_SLOT)

	_holder.set_holded_object_to(SECOND_SLOT)

	assert_object(_object_holder.current_weapon).is_same(equipped_item.scene_instance)


func test_set_holded_object_to_out_of_range_index_keeps_targeted_index() -> void:
	_holder.set_holded_object_to(OUT_OF_RANGE_INDEX)

	assert_int(_holder.current_targeted_index).is_equal(FIRST_SLOT)


func test_set_holded_object_to_negative_index_keeps_targeted_index() -> void:
	_holder.set_holded_object_to(NEGATIVE_INDEX)

	assert_int(_holder.current_targeted_index).is_equal(FIRST_SLOT)


func test_set_holded_object_to_next_moves_to_following_slot() -> void:
	_model.set_item(SECOND_SLOT, _create_item_with_weapon())

	_holder.set_holded_object_to_next()

	assert_int(_holder.current_targeted_index).is_equal(SECOND_SLOT)


func test_set_holded_object_to_next_on_last_slot_stays_on_last_slot() -> void:
	_model.set_item(LAST_SLOT, _create_item_with_weapon())
	_holder.set_holded_object_to(LAST_SLOT)

	_holder.set_holded_object_to_next()

	assert_int(_holder.current_targeted_index).is_equal(LAST_SLOT)


func test_set_holded_object_to_next_with_empty_following_slot_keeps_targeted_index() -> void:
	_model.set_item(FIRST_SLOT, _create_item_with_weapon())
	_holder.set_holded_object_to(FIRST_SLOT)

	_holder.set_holded_object_to_next()

	assert_int(_holder.current_targeted_index).is_equal(FIRST_SLOT)


func test_set_holded_object_to_previous_moves_to_preceding_slot() -> void:
	_model.set_item(FIRST_SLOT, _create_item_with_weapon())
	_model.set_item(SECOND_SLOT, _create_item_with_weapon())
	_holder.set_holded_object_to(SECOND_SLOT)

	_holder.set_holded_object_to_previous()

	assert_int(_holder.current_targeted_index).is_equal(FIRST_SLOT)


func test_set_holded_object_to_previous_on_first_slot_stays_on_first_slot() -> void:
	_model.set_item(FIRST_SLOT, _create_item_with_weapon())
	_holder.set_holded_object_to(FIRST_SLOT)

	_holder.set_holded_object_to_previous()

	assert_int(_holder.current_targeted_index).is_equal(FIRST_SLOT)


func test_slot_change_on_targeted_slot_equips_new_item() -> void:
	var item := _create_item_with_weapon()

	_model.set_item(_holder.current_targeted_index, item)

	assert_object(_object_holder.current_weapon).is_same(item.scene_instance)


func test_removing_item_of_targeted_slot_keeps_weapon_in_hand() -> void:
	# Comportement actuel figé : retirer l'item du slot ciblé n'enlève pas l'arme tenue.
	var item := _create_item_with_weapon()
	_model.set_item(FIRST_SLOT, item)

	_model.set_item(FIRST_SLOT, null)

	assert_object(_object_holder.current_weapon).is_same(item.scene_instance)


func test_slot_change_on_other_slot_does_not_equip() -> void:
	_model.set_item(SECOND_SLOT, _create_item_with_weapon())

	assert_object(_object_holder.current_weapon).is_null()
