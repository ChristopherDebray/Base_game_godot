class_name ObjectHolderComponentTest
extends GdUnitTestSuite

## Tests de l'ObjectHolderComponent (tient l'arme active et la remplace).
##
## On utilise une arme espion qui remplace `setup()` : la vraie arme exige sa scène complète
## (sprite animé, muzzle, data) alors qu'ici seul le contrat du porteur nous intéresse.

const MUZZLE_POSITION := Vector2(12.0, 3.0)
const HOLDER_HIT_MASK: int = CollisionManager.MASK_WALLS | CollisionManager.MASK_PLAYER

## Enregistre les appels à `setup()` au lieu d'exiger les enfants de la vraie scène.
class WeaponSpy extends BaseWeapon:
	var setup_call_count: int = 0
	var last_muzzle_position: Vector2 = Vector2.ZERO

	func _init() -> void:
		var sprite := AnimatedSprite2D.new()
		sprite.name = "AnimatedSprite2D"
		add_child(sprite)
		var muzzle_node := Node2D.new()
		muzzle_node.name = "Muzzle"
		add_child(muzzle_node)

	func setup(muzzle_position: Vector2) -> void:
		setup_call_count += 1
		last_muzzle_position = muzzle_position


var _holder: ObjectHolderComponent


func before_test() -> void:
	_holder = auto_free(ObjectHolderComponent.new())
	_holder.hit_mask = HOLDER_HIT_MASK
	add_child(_holder)


func _create_weapon() -> WeaponSpy:
	return auto_free(WeaponSpy.new())


func test_switch_weapon_adds_weapon_as_child() -> void:
	var weapon := _create_weapon()

	_holder.switch_weapon(weapon, MUZZLE_POSITION)

	assert_object(weapon.get_parent()).is_same(_holder)


func test_switch_weapon_sets_current_weapon() -> void:
	var weapon := _create_weapon()

	_holder.switch_weapon(weapon, MUZZLE_POSITION)

	assert_object(_holder.current_weapon).is_same(weapon)


func test_switch_weapon_applies_holder_hit_mask_to_weapon() -> void:
	var weapon := _create_weapon()

	_holder.switch_weapon(weapon, MUZZLE_POSITION)

	assert_int(weapon.hit_mask).is_equal(HOLDER_HIT_MASK)


func test_switch_weapon_sets_up_weapon_with_muzzle_position() -> void:
	var weapon := _create_weapon()

	_holder.switch_weapon(weapon, MUZZLE_POSITION)

	assert_vector(weapon.last_muzzle_position).is_equal(MUZZLE_POSITION)


func test_first_switch_returns_no_previous_weapon() -> void:
	var previous_weapon := _holder.switch_weapon(_create_weapon(), MUZZLE_POSITION)

	assert_object(previous_weapon).is_null()


func test_second_switch_returns_previous_weapon() -> void:
	var first_weapon := _create_weapon()
	_holder.switch_weapon(first_weapon, MUZZLE_POSITION)

	var previous_weapon := _holder.switch_weapon(_create_weapon(), MUZZLE_POSITION)

	assert_object(previous_weapon).is_same(first_weapon)


func test_second_switch_detaches_previous_weapon_from_holder() -> void:
	var first_weapon := _create_weapon()
	_holder.switch_weapon(first_weapon, MUZZLE_POSITION)

	_holder.switch_weapon(_create_weapon(), MUZZLE_POSITION)

	assert_object(first_weapon.get_parent()).is_null()


func test_second_switch_sets_new_weapon_as_current() -> void:
	_holder.switch_weapon(_create_weapon(), MUZZLE_POSITION)
	var second_weapon := _create_weapon()

	_holder.switch_weapon(second_weapon, MUZZLE_POSITION)

	assert_object(_holder.current_weapon).is_same(second_weapon)


func test_switch_to_same_weapon_returns_current_weapon() -> void:
	var weapon := _create_weapon()
	_holder.switch_weapon(weapon, MUZZLE_POSITION)

	var returned_weapon := _holder.switch_weapon(weapon, MUZZLE_POSITION)

	assert_object(returned_weapon).is_same(weapon)


func test_switch_to_same_weapon_does_not_set_it_up_again() -> void:
	var weapon := _create_weapon()
	_holder.switch_weapon(weapon, MUZZLE_POSITION)

	_holder.switch_weapon(weapon, MUZZLE_POSITION)

	assert_int(weapon.setup_call_count).is_equal(1)
