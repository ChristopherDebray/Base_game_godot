class_name ItemInstanceTest
extends GdUnitTestSuite

## Tests de l'ItemInstance (donnée + scène instanciée à la demande).
## On utilise la scène de base d'une arme : légère, et elle exerce l'injection de `data`.
## La scène n'est jamais ajoutée à l'arbre, donc son `_ready` ne s'exécute pas.

const WEAPON_SCENE_PATH := "res://scenes/weapons/base_weapon.tscn"


func _create_weapon_item() -> ItemInstance:
	var weapon_data := BaseWeaponData.new()
	weapon_data.equipped_scene_path = WEAPON_SCENE_PATH
	return ItemInstance.new(weapon_data)


func test_init_keeps_given_data() -> void:
	var item_data := BaseItemData.new()

	var item := ItemInstance.new(item_data)

	assert_object(item.data).is_same(item_data)


func test_scene_is_not_instantiated_before_first_request() -> void:
	var item := _create_weapon_item()

	assert_object(item.scene_instance).is_null()


func test_get_scene_instantiates_the_scene_of_the_item() -> void:
	var item := _create_weapon_item()

	var scene := item.get_scene()
	auto_free(scene)

	assert_object(scene).is_instanceof(BaseWeapon)


func test_get_scene_returns_the_same_instance_on_every_call() -> void:
	var item := _create_weapon_item()
	var first_scene := item.get_scene()
	auto_free(first_scene)

	var second_scene := item.get_scene()

	assert_object(second_scene).is_same(first_scene)


func test_get_scene_injects_weapon_data_into_the_weapon() -> void:
	var item := _create_weapon_item()

	var weapon: BaseWeapon = item.get_scene()
	auto_free(weapon)

	assert_object(weapon.data).is_same(item.data)
