class_name EnemyScenesTest
extends GdUnitTestSuite

## Vérifie le câblage des scènes d'ennemis (behavior et arme assignés dans l'éditeur) : une
## erreur de `.tscn` ne se voit sinon qu'en jouant le niveau. Les scènes ne sont pas ajoutées à
## l'arbre, seules les propriétés exportées sont lues.

const SOLDIER_SCENE_PATH := "res://scenes/entities/npcs/soldier/soldier.tscn"
const KAMIKAZE_SCENE_PATH := "res://scenes/entities/npcs/kamikaze/kamikaze.tscn"

func test_soldier_uses_ranged_behavior_and_has_a_weapon() -> void:
	var soldier: Npc = auto_free(load(SOLDIER_SCENE_PATH).instantiate())

	assert_object(soldier.combat_behavior).is_instanceof(RangedBehavior)
	assert_object(soldier.initial_weapon).is_not_null()

func test_kamikaze_uses_kamikaze_behavior_and_has_no_weapon() -> void:
	var kamikaze: Npc = auto_free(load(KAMIKAZE_SCENE_PATH).instantiate())

	assert_object(kamikaze.combat_behavior).is_instanceof(KamikazeBehavior)
	assert_object(kamikaze.initial_weapon).is_null()
