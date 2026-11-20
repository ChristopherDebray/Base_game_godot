class_name EnemyScenesTest
extends GdUnitTestSuite

## Vérifie le câblage des scènes d'ennemis et d'armes (behavior, arme et data assignés dans
## l'éditeur) : une erreur de `.tscn` ne se voit sinon qu'en jouant le niveau. Les scènes ne sont
## pas ajoutées à l'arbre, seules les propriétés exportées sont lues.

const SOLDIER_SCENE_PATH := "res://scenes/entities/npcs/soldier/soldier.tscn"
const KAMIKAZE_SCENE_PATH := "res://scenes/entities/npcs/kamikaze/kamikaze.tscn"
const FIST_SCENE_PATH := "res://scenes/weapons/melee/fist.tscn"
const BOMB_BLAST_DAMAGE: float = 20.0
const FIST_DAMAGE: float = 5.0

func test_soldier_uses_ranged_behavior_and_has_a_weapon() -> void:
	var soldier: Npc = auto_free(load(SOLDIER_SCENE_PATH).instantiate())

	assert_object(soldier.combat_behavior).is_instanceof(RangedBehavior)
	assert_object(soldier.initial_weapon).is_not_null()

func test_kamikaze_uses_kamikaze_behavior_and_carries_a_bomb() -> void:
	var kamikaze: Npc = auto_free(load(KAMIKAZE_SCENE_PATH).instantiate())
	var weapon: Node = auto_free(kamikaze.initial_weapon.instantiate())

	assert_object(kamikaze.combat_behavior).is_instanceof(KamikazeBehavior)
	assert_object(weapon).is_instanceof(ExplosiveWeapon)
	assert_float(weapon.data.primary_ability.damage).is_equal(BOMB_BLAST_DAMAGE)

func test_fist_is_a_melee_weapon_with_data() -> void:
	var fist: MeleeWeapon = auto_free(load(FIST_SCENE_PATH).instantiate())

	assert_float(fist.data.primary_ability.damage).is_equal(FIST_DAMAGE)
