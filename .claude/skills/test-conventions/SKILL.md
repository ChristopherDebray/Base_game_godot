---
name: test-conventions
description: Conventions de test gdUnit4 du projet - nommage, structure, auto_free, signaux, spies, lancement headless. À utiliser avant d'écrire, de modifier ou de lancer des tests, ou quand un test échoue.
---

# Conventions de test (gdUnit4)

## Où et comment nommer

- Tests dans `tests/`, **en miroir** de l'arborescence (`scenes/components/health_component.gd` → `tests/scenes/components/health_component_test.gd`).
- Fichier `<nom_du_script>_test.gd`, `class_name <Nom>Test`, `extends GdUnitTestSuite`.
- Fonctions `test_<comportement>_<condition_ou_résultat>` (ex. `test_take_damage_at_zero_emits_death`).
- Variables et constantes nommées (`MAX_HEALTH`, `OUT_OF_RANGE_INDEX`), pas de nombres magiques. Commentaires en français, sur le pourquoi.

## Quoi tester

Priorité : 1) logique pure et composants (Health, InventoryModel, états ennemis) ; 2) interactions entre nodes via scene runner ; 3) pas de tests de rendu, shaders, SubViewports ni de « feeling ».

- **Un test = un comportement.** Pas de `if` ni de boucle dans un test. Pas de dépendance à l'ordre des tests.
- Tester le comportement observable, jamais en reproduisant l'implémentation.
- Cas à couvrir : cas normal, bornes (vie à 0, index hors bornes, premier et dernier index), refus (type d'item refusé), entrées invalides, signaux émis **et** signaux non émis.
- Un bug corrigé reçoit d'abord un test qui l'échoue, puis le fix, puis le test passe.

## Règle absolue

Ne pas modifier un test pour le faire passer sans l'expliquer à l'utilisateur : un test qui échoue est peut-être un vrai bug. Si un test révèle un bug du code, le signaler et proposer le fix séparément.

## Idiomes gdUnit4 validés dans ce projet

**Libérer les nodes avec `auto_free`.** Tout node créé dans un test doit l'être, sinon il fuit entre les tests (le rapport indique `orphans`). `add_child(auto_free(node))` ajoute au suite (qui est un `Node`) et libère à la fin du test. Les `RefCounted` (`InventoryModel`, `ItemInstance`) se libèrent seuls.

**Mettre le node dans l'arbre quand il en a besoin.** `_ready`, `@onready`, `global_position` ne sont valides qu'une fois dans le SceneTree. Si un script fait `$HealthComponent`, créer l'enfant avec ce nom exact avant `add_child` du parent.

**Signaux : monitorer AVANT l'action.**

```gdscript
monitor_signals(model, false)
model.set_item(2, item)
await assert_signal(model).is_emitted("slot_changed", [2])
```

- `monitor_signals` doit précéder l'action qui émet, sinon l'émission est déjà passée.
- Passer `false` en second argument pour un objet qu'on ne possède pas (autoload comme `SignalManager`) : sans ça gdUnit le libérerait à la fin du test.
- Les arguments attendus sont dans un tableau : `[ENTITY_POSITION]`.
- `await` est requis devant `assert_signal(...)` (c'est le pattern de la doc gdUnit4).
- Vérifier qu'un signal n'est pas émis : `await assert_signal(obj).is_not_emitted("nom")`.

**Observer un effet qui détruit le node : espion en classe interne.** `Damageable.die()` fait `queue_free()`, inobservable après coup. Dans le test :

```gdscript
class DamageableSpy extends Damageable:
	var die_call_count: int = 0

	func die() -> void:
		die_call_count += 1
```

**Comportement dépendant du temps** (physique, timers) : attendre les frames avant d'asserter (`await get_tree().physics_frame`, ou scene runner), jamais de `sleep`.

## Lancer les tests

Headless, depuis la racine du projet :

```bash
export GODOT_BIN="${GODOT_BIN:-$HOME/Applications/godot/Godot_v4.7.2-stable_linux.x86_64}"
addons/gdUnit4/runtest.sh -a res://tests
```

- Un seul fichier : `-a res://tests/datas/items/inventory_model_test.gd`.
- Le code de sortie est non nul si un test échoue ; rapports dans `reports/` (ignoré par git).
- Après avoir ajouté, renommé ou déplacé un script avec `class_name`, relancer `godot --headless --import` : le cache de classes globales (`.godot/`) est périmé sinon, et gdUnit signale `hides a global script class`.
- Une ligne `Remote Debugger: Unable to connect to host '127.0.0.1:0'` dans la sortie headless est du bruit sans lien avec les tests.
