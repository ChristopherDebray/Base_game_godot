class_name BaseWeaponTest
extends GdUnitTestSuite

## Tests de la logique de tir de BaseWeapon (garde-fous, cadence, état de rechargement).
##
## Les effets de bord réels (animation, son via `SoundManager`, particules) ne sont pas
## testables ici : l'arme espion remplace `launch_*` et `reload` par des compteurs, ce qui permet
## de tester les décisions de `try_launch_*` sans autoload. Le corps de `reload()` lui-même
## (appel direct à `SoundManager`) n'est donc pas couvert, voir la PR.

const TARGET: Vector2 = Vector2(40.0, 0.0)
const COOLDOWN_SECONDS: float = 0.01
const AMMUNITION_LEFT: int = 5
const NO_AMMUNITION: int = 0
const RELOAD_ANIMATION := "reload"
const OTHER_ANIMATION := "primary_ability"
const SPRITE_NODE_NAME := "AnimatedSprite2D"
const MUZZLE_NODE_NAME := "Muzzle"

## Remplace les effets de bord de l'arme par des compteurs observables.
class WeaponSpy extends BaseWeapon:
	var primary_launch_count: int = 0
	var secondary_launch_count: int = 0
	var reload_call_count: int = 0
	var last_primary_target: Vector2 = Vector2.ZERO

	func _init() -> void:
		var sprite := AnimatedSprite2D.new()
		sprite.name = SPRITE_NODE_NAME
		var frames := SpriteFrames.new()
		frames.add_animation(RELOAD_ANIMATION)
		frames.add_animation(OTHER_ANIMATION)
		sprite.sprite_frames = frames
		add_child(sprite)
		var muzzle_node := Node2D.new()
		muzzle_node.name = MUZZLE_NODE_NAME
		add_child(muzzle_node)

	func launch_primary_ability(target: Vector2) -> void:
		primary_launch_count += 1
		last_primary_target = target

	func launch_secondary_ability(_target: Vector2) -> void:
		secondary_launch_count += 1

	func reload() -> void:
		reload_call_count += 1


var _weapon: WeaponSpy


func before_test() -> void:
	var ability := BaseAbilityData.new()
	ability.cooldown = COOLDOWN_SECONDS
	var weapon_data := BaseWeaponData.new()
	weapon_data.primary_ability = ability
	weapon_data.secondary_ability = ability
	_weapon = auto_free(WeaponSpy.new())
	_weapon.data = weapon_data
	_weapon.current_ammunition = AMMUNITION_LEFT
	add_child(_weapon)


## Laisse le temps au cooldown lancé sans `await` de se terminer : sinon la coroutine serait
## reprise sur une arme déjà libérée à la fin du test.
func _wait_until_cooldown_ends() -> void:
	await get_tree().create_timer(COOLDOWN_SECONDS).timeout
	await get_tree().process_frame


# ---------- capacité primaire ----------

func test_primary_ability_launches_toward_target() -> void:
	await _weapon.try_launch_primary_ability(TARGET)

	assert_vector(_weapon.last_primary_target).is_equal(TARGET)


func test_primary_ability_launches_once_per_call() -> void:
	await _weapon.try_launch_primary_ability(TARGET)

	assert_int(_weapon.primary_launch_count).is_equal(1)


func test_primary_ability_is_blocked_during_cooldown() -> void:
	_weapon.try_launch_primary_ability(TARGET)

	assert_bool(_weapon.can_launch_primary_ability).is_false()
	await _wait_until_cooldown_ends()


func test_primary_ability_second_call_during_cooldown_does_not_launch() -> void:
	_weapon.try_launch_primary_ability(TARGET)

	_weapon.try_launch_primary_ability(TARGET)

	assert_int(_weapon.primary_launch_count).is_equal(1)
	await _wait_until_cooldown_ends()


func test_primary_ability_is_available_again_after_cooldown() -> void:
	await _weapon.try_launch_primary_ability(TARGET)

	assert_bool(_weapon.can_launch_primary_ability).is_true()


func test_primary_ability_does_not_launch_while_reloading() -> void:
	_weapon.is_reloading = true

	await _weapon.try_launch_primary_ability(TARGET)

	assert_int(_weapon.primary_launch_count).is_equal(0)


func test_primary_ability_without_ammunition_does_not_launch() -> void:
	_weapon.current_ammunition = NO_AMMUNITION

	await _weapon.try_launch_primary_ability(TARGET)

	assert_int(_weapon.primary_launch_count).is_equal(0)


func test_primary_ability_without_ammunition_triggers_a_reload() -> void:
	_weapon.current_ammunition = NO_AMMUNITION

	await _weapon.try_launch_primary_ability(TARGET)

	assert_int(_weapon.reload_call_count).is_equal(1)


func test_primary_ability_while_reloading_without_ammunition_does_not_reload_again() -> void:
	_weapon.is_reloading = true
	_weapon.current_ammunition = NO_AMMUNITION

	await _weapon.try_launch_primary_ability(TARGET)

	assert_int(_weapon.reload_call_count).is_equal(0)


func test_primary_ability_with_ammunition_does_not_reload() -> void:
	await _weapon.try_launch_primary_ability(TARGET)

	assert_int(_weapon.reload_call_count).is_equal(0)


# ---------- capacité secondaire ----------

func test_secondary_ability_launches_once_per_call() -> void:
	await _weapon.try_launch_secondary_ability(TARGET)

	assert_int(_weapon.secondary_launch_count).is_equal(1)


func test_secondary_ability_is_blocked_during_cooldown() -> void:
	_weapon.try_launch_secondary_ability(TARGET)

	assert_bool(_weapon.can_launch_secondary_ability).is_false()
	await _wait_until_cooldown_ends()


func test_secondary_ability_second_call_during_cooldown_does_not_launch() -> void:
	_weapon.try_launch_secondary_ability(TARGET)

	_weapon.try_launch_secondary_ability(TARGET)

	assert_int(_weapon.secondary_launch_count).is_equal(1)
	await _wait_until_cooldown_ends()


func test_primary_cooldown_does_not_block_secondary_ability() -> void:
	_weapon.try_launch_primary_ability(TARGET)

	_weapon.try_launch_secondary_ability(TARGET)

	assert_int(_weapon.secondary_launch_count).is_equal(1)
	await _wait_until_cooldown_ends()


func test_secondary_ability_is_available_again_after_cooldown() -> void:
	await _weapon.try_launch_secondary_ability(TARGET)

	assert_bool(_weapon.can_launch_secondary_ability).is_true()


# ---------- fin d'animation de rechargement ----------
# Le signal `animation_finished` est connecté dans la scène .tscn, pas dans le script : sur une
# arme créée en code, on appelle donc directement le handler.

func test_reload_animation_finished_ends_reloading() -> void:
	_weapon.is_reloading = true
	_weapon.animated_sprite_2d.animation = RELOAD_ANIMATION

	_weapon._on_animated_sprite_2d_animation_finished()

	assert_bool(_weapon.is_reloading).is_false()


func test_other_animation_finished_keeps_reloading() -> void:
	_weapon.is_reloading = true
	_weapon.animated_sprite_2d.animation = OTHER_ANIMATION

	_weapon._on_animated_sprite_2d_animation_finished()

	assert_bool(_weapon.is_reloading).is_true()
