class_name PlayerTest
extends GdUnitTestSuite

## Tests de la logique du Player : rangement des objets ramassés, mort, orientation.
##
## On utilise un sous-type de `Player` qui neutralise `_ready` (qui équipe un pistolet réel) et
## `_physics_process` (qui lit les entrées), et qui fournit les enfants que le script attend
## par chemin (`$AnimatedSprite2D`, `$Muzzle`…). Les modèles d'inventaire (`bag`, `armor`,
## `weapons`) sont des variables du Player : ils sont donc réels.

const BAG_SIZE: int = 20
const FIRST_SLOT: int = 0
const ItemType = BaseItemData.ITEM_TYPE
const SECOND_SLOT: int = 1
const THIRD_SLOT: int = 2
const FOURTH_SLOT: int = 3
const LAST_BAG_SLOT: int = BAG_SIZE - 1
const MOVING_VELOCITY := Vector2(50.0, 0.0)
const ANIMATED_SPRITE_NAME := "AnimatedSprite2D"
const COLLISION_SHAPE_NAME := "CollisionShape2D"
const MUZZLE_NAME := "Muzzle"
const OBJECT_HOLDER_NAME := "ObjectHolderComponent"
const OBJECTS_HOLDER_NAME := "ObjectsHolderComponent"

## Joueur sans scène : pas d'arme équipée, pas de lecture des entrées.
class PlayerStub extends Player:
	func _init() -> void:
		_add_named_child(AnimatedSprite2D.new(), ANIMATED_SPRITE_NAME)
		_add_named_child(CollisionShape2D.new(), COLLISION_SHAPE_NAME)
		_add_named_child(Node2D.new(), MUZZLE_NAME)
		_add_named_child(ObjectHolderComponent.new(), OBJECT_HOLDER_NAME)
		_add_named_child(ObjectsHolderComponent.new(), OBJECTS_HOLDER_NAME)

	func _add_named_child(child: Node, child_name: String) -> void:
		child.name = child_name
		add_child(child)

	func _ready() -> void:
		pass

	func _physics_process(_delta: float) -> void:
		pass


var _player: PlayerStub
var _death_signal_count: int = 0


func before_test() -> void:
	_player = auto_free(PlayerStub.new())
	add_child(_player)
	_death_signal_count = 0
	SignalManager.on_player_died.connect(_on_player_died)


func after_test() -> void:
	SignalManager.on_player_died.disconnect(_on_player_died)


func _on_player_died() -> void:
	_death_signal_count += 1


func _create_item_data(type: ItemType) -> BaseItemData:
	var item_data := BaseItemData.new()
	item_data.type = type
	return item_data


func _fill_bag_up_to(last_filled_slot: int) -> void:
	for slot_index in last_filled_slot + 1:
		_player.bag.set_item(slot_index, ItemInstance.new(_create_item_data(ItemType.OTHER)))


func _fill_bag() -> void:
	for slot_index in BAG_SIZE:
		_player.bag.set_item(slot_index, ItemInstance.new(_create_item_data(ItemType.OTHER)))


# ---------- pickup ----------

func test_pickup_null_data_is_refused() -> void:
	assert_bool(_player.pickup(null)).is_false()


func test_pickup_weapon_goes_to_the_weapon_slot() -> void:
	var weapon_data := _create_item_data(ItemType.PRIMARY)

	_player.pickup(weapon_data)

	assert_object(_player.weapons.get_item(FIRST_SLOT).data).is_same(weapon_data)


func test_pickup_weapon_returns_true() -> void:
	assert_bool(_player.pickup(_create_item_data(ItemType.PRIMARY))).is_true()


func test_pickup_equipment_goes_to_the_armor_slot() -> void:
	var helmet_data := _create_item_data(ItemType.HEAD)

	_player.pickup(helmet_data)

	assert_object(_player.armor.get_item(FIRST_SLOT).data).is_same(helmet_data)


func test_pickup_other_item_goes_to_the_bag() -> void:
	var other_data := _create_item_data(ItemType.OTHER)

	_player.pickup(other_data)

	assert_object(_player.bag.get_item(FIRST_SLOT).data).is_same(other_data)


func test_pickup_second_weapon_overflows_to_the_bag_when_weapon_slot_is_taken() -> void:
	_player.pickup(_create_item_data(ItemType.PRIMARY))
	var second_weapon_data := _create_item_data(ItemType.PRIMARY)

	_player.pickup(second_weapon_data)

	assert_object(_player.bag.get_item(FIRST_SLOT).data).is_same(second_weapon_data)


func test_pickup_secondary_weapon_goes_to_the_second_weapon_slot() -> void:
	var secondary_data := _create_item_data(ItemType.SECONDARY)

	_player.pickup(secondary_data)

	assert_object(_player.weapons.get_item(SECOND_SLOT).data).is_same(secondary_data)


func test_pickup_first_gadget_goes_to_the_third_weapon_slot() -> void:
	var gadget_data := _create_item_data(ItemType.GADGET)

	_player.pickup(gadget_data)

	assert_object(_player.weapons.get_item(THIRD_SLOT).data).is_same(gadget_data)


func test_pickup_second_gadget_goes_to_the_fourth_weapon_slot() -> void:
	_player.pickup(_create_item_data(ItemType.GADGET))
	var second_gadget_data := _create_item_data(ItemType.GADGET)

	_player.pickup(second_gadget_data)

	assert_object(_player.weapons.get_item(FOURTH_SLOT).data).is_same(second_gadget_data)


func test_pickup_third_gadget_overflows_to_the_bag() -> void:
	_player.pickup(_create_item_data(ItemType.GADGET))
	_player.pickup(_create_item_data(ItemType.GADGET))
	var third_gadget_data := _create_item_data(ItemType.GADGET)

	_player.pickup(third_gadget_data)

	assert_object(_player.bag.get_item(FIRST_SLOT).data).is_same(third_gadget_data)


func test_pickup_chest_equipment_goes_to_the_armor_chest_slot() -> void:
	var chest_data := _create_item_data(ItemType.CHEST)

	_player.pickup(chest_data)

	assert_object(_player.armor.get_item(SECOND_SLOT).data).is_same(chest_data)


func test_pickup_uses_the_last_bag_slot_when_the_others_are_taken() -> void:
	_fill_bag_up_to(LAST_BAG_SLOT - 1)
	var last_item_data := _create_item_data(ItemType.OTHER)

	_player.pickup(last_item_data)

	assert_object(_player.bag.get_item(LAST_BAG_SLOT).data).is_same(last_item_data)


func test_pickup_weapon_with_full_bag_still_succeeds_when_a_weapon_slot_is_free() -> void:
	_fill_bag()

	assert_bool(_player.pickup(_create_item_data(ItemType.PRIMARY))).is_true()


func test_pickup_with_full_bag_is_refused() -> void:
	_fill_bag()

	assert_bool(_player.pickup(_create_item_data(ItemType.OTHER))).is_false()


func test_pickup_does_not_touch_other_inventories() -> void:
	_player.pickup(_create_item_data(ItemType.OTHER))

	assert_object(_player.weapons.get_item(FIRST_SLOT)).is_null()
	assert_object(_player.armor.get_item(FIRST_SLOT)).is_null()


# ---------- die ----------

func test_die_marks_the_player_as_dead() -> void:
	_player.die()

	assert_bool(_player.is_dead).is_true()


func test_die_hides_the_player() -> void:
	_player.die()

	assert_bool(_player.visible).is_false()


func test_die_stops_the_player_movement() -> void:
	_player.velocity = MOVING_VELOCITY

	_player.die()

	assert_vector(_player.velocity).is_equal(Vector2.ZERO)


func test_die_stops_physics_processing() -> void:
	_player.die()

	assert_bool(_player.is_physics_processing()).is_false()


func test_die_disables_the_collision_shape() -> void:
	_player.die()
	await get_tree().process_frame

	assert_bool(_player.collision_shape_2d.disabled).is_true()


func test_die_notifies_the_rest_of_the_game_once() -> void:
	_player.die()

	assert_int(_death_signal_count).is_equal(1)


func test_die_twice_notifies_only_once() -> void:
	_player.die()

	_player.die()

	assert_int(_death_signal_count).is_equal(1)


# ---------- orientation ----------

func test_flip_facing_with_reverse_looks_left() -> void:
	_player.flip_facing(true)

	assert_vector(_player.facing_direction).is_equal(Vector2.LEFT)


func test_flip_facing_without_reverse_looks_right() -> void:
	_player.flip_facing(true)

	_player.flip_facing(false)

	assert_vector(_player.facing_direction).is_equal(Vector2.RIGHT)


func test_flip_facing_with_reverse_mirrors_the_sprite() -> void:
	_player.flip_facing(true)

	assert_bool(_player.animated_sprite_2d.flip_h).is_true()


func test_flip_facing_without_reverse_restores_the_sprite() -> void:
	_player.flip_facing(true)

	_player.flip_facing(false)

	assert_bool(_player.animated_sprite_2d.flip_h).is_false()
