---
name: scaffold-component
description: Crée un nouveau composant réutilisable (script *_component.gd + son test gdUnit4 rouge) selon les conventions de composition du projet. À utiliser quand l'utilisateur veut ajouter un comportement à une entité (vie, détection, visée, inventaire…) ou demande un nouveau composant.
---

# Nouveau composant

Un comportement = un composant : un node avec un script `class_name <Nom>Component`, ajouté comme enfant de l'entité et branché par `@export` (composition avant héritage, voir `CLAUDE.md`). Procéder en TDD : test rouge d'abord.

## 1. Cadrer avant d'écrire

Avant de créer quoi que ce soit, établir en une phrase chacun de ces points (demander à l'utilisateur s'il manque un seul) :

- **Rôle** : une seule responsabilité. Si la description contient « et », ce sont deux composants.
- **Dépendances** : ce que le composant reçoit (`@export` d'un node ou d'une Resource assigné dans l'éditeur, ou paramètre de méthode). Jamais `get_node("chemin/fragile")`, jamais un autoload en dur : sans ça on ne peut pas l'instancier seul dans un test.
- **Sorties** : les signaux qu'il émet vers le haut (« call down, signal up »). Il ne connaît pas le type concret de son parent plus que nécessaire.
- **Racine de la scène** : `Node` par défaut, `Node2D` seulement s'il a besoin d'une position.

Vérifier qu'il n'existe pas déjà un composant proche dans `scenes/components/` (attention aux doublons `object_holder_component` / `objects_holder_component`).

## 2. Le test d'abord

`tests/scenes/components/<nom>_component_test.gd` (miroir du script, voir le skill `test-conventions`). Un test par comportement attendu, qui doit **échouer** avant l'implémentation : cas normal, bornes, entrées invalides, signaux émis et non émis. Lancer les tests et constater le rouge.

## 3. Le script

`scenes/components/<nom>_component.gd`, à côté de la scène du même nom. Gabarit :

```gdscript
extends Node

## Rôle du composant en une phrase, et ce qu'il attend de l'entité qui le porte.
class_name ExampleComponent

## Émis quand <événement>, avec <ce que contient l'argument>.
signal example_happened(amount: float)

@export var target: Node2D
@export var max_amount: float = 100.0

## Ce que fait la méthode, paramètres non évidents, valeur de retour, signaux émis.
func apply(amount: float) -> void:
	if target == null:
		return
	example_happened.emit(amount)
```

Règles à respecter (détail dans `CLAUDE.md`) : typage statique partout (`-> void` inclus), guard clauses plutôt que `if` imbriqués, constantes nommées ou `@export` plutôt que des nombres magiques, noms explicites, `##` au-dessus du `class_name` et de chaque fonction publique, `is_instance_valid()` avant d'utiliser un node qui peut être libéré.

## 4. La scène (à faire par l'utilisateur)

Ne pas écrire de `.tscn` ni de `.uid` à la main. Donner à l'utilisateur les étapes de l'éditeur :

1. Scene → New Scene, racine du type choisi (`Node` ou `Node2D`), renommée `<Nom>Component`.
2. Attacher `scenes/components/<nom>_component.gd`.
3. Enregistrer sous `scenes/components/<nom>_component.tscn`.
4. Dans la scène de l'entité : instancier le composant en enfant et assigner ses `@export` dans l'inspecteur.

## 5. Vérifier

- Les tests passent (skill `test-conventions` pour la commande).
- `python3 .claude/skills/check-gdscript/scripts/check_gdscript.py` ne signale rien sur les nouveaux fichiers (ce skill n'existe qu'une fois sa PR mergée ; sinon relire à la main les règles de style).
- Donner à l'utilisateur la liste des vérifications manuelles dans l'éditeur (étapes de la section 4, valeurs d'inspecteur à renseigner).
