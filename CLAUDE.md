# CLAUDE.md

## But du projet

Projet d'**apprentissage de Godot 4.7** (GDScript, renderer GL Compatibility, 2D). L'objectif n'est pas de finir un jeu vite, mais d'apprendre les bonnes pratiques Godot, en particulier la **composition** (petits composants réutilisables plutôt que de gros héritages).

Le jeu : un top-down 2D avec un joueur armé, des PNJ ennemis (patrouille, FOV, poursuite), un système d'armes à tir par raycast, un inventaire drag & drop, un éclairage/visibilité via SubViewports + shaders.

Quand tu proposes une solution, explique brièvement le *pourquoi* côté Godot (nodes, signaux, resources, groupes…) : l'utilisateur veut comprendre, pas seulement obtenir du code.

## Règles de travail

- **Sois sûr de toi** : ne devine pas une API Godot. Si tu n'es pas certain d'une signature ou d'un comportement, vérifie dans le code existant ou la doc 4.x, ou dis explicitement que tu n'es pas sûr.
- Lis le code concerné avant de modifier. Ne change pas ce qui n'est pas demandé.
- Ne modifie jamais à la main `.godot/`, les `*.uid`, les `*.import`. Les `.tscn`/`.tres` s'éditent avec prudence (les `uid://` doivent rester valides) ; préfère modifier les scripts et dire à l'utilisateur quoi configurer dans l'éditeur quand c'est plus sûr.
- Ne commit / push que sur demande. Messages de commit style existant : `feat: …`, `fix: …`, `refactor: …`.

## Style de code (strict)

### Nommage
- **Interdit : les variables d'une lettre ou abréviations cryptiques** (`var c`, `var p`, `var d`, `var t`, `var i` hors boucle triviale). Toujours un nom qui dit ce que c'est (`child`, `particle`, `drag_data`, `preview_texture`).
- `snake_case` pour variables/fonctions/fichiers, `PascalCase` pour `class_name`, `UPPER_SNAKE` pour constantes et valeurs d'enum.
- Fonctions privées préfixées par `_`, handlers de signaux : `_on_<source>_<signal>`.
- Pas de constante/alias cryptique du type `const T = BaseItemData.ITEM_TYPE` : préférer un nom explicite (`ItemType`).

### Typage et qualité
- **Typage statique partout** : paramètres, retours (`-> void` inclus), variables (`var health: float`, `:=` quand le type est évident). Pas de `Variant` implicite sans raison.
- **Return early / guard clauses** : valider et sortir en premier, éviter l'imbrication. Pas de `else` après un `return`.
- Pas de nombres/chaînes magiques : constantes nommées, `@export` pour ce qui se règle dans l'inspecteur, noms d'actions d'input en constantes si réutilisés.
- Fonctions courtes, une seule responsabilité. Pas de code mort, pas de `print` de debug oublié, pas de code commenté.
- Utiliser `is_instance_valid()` / `null` checks avant d'accéder à un node qui peut avoir été libéré ou ne pas exister (`get_parent()`, `get_first_node_in_group()`, `Resource` optionnelle…).
- Ne jamais faire confiance aux entrées externes (fichiers `user://`, JSON, drag data, index) : valider type, bornes d'index, existence avant usage. Vérifier le retour de `FileAccess.open`, `load`, `ResourceLoader.exists`, `JSON.parse_string`.
- Pas de `await` sur un node qui peut être libéré entre-temps sans vérification ; déconnecter les signaux d'objets qui ne vivent pas aussi longtemps que la source.
- Pas de `get_node("chemin/fragile")` répété : `@onready` avec `%UniqueName` ou `@export` d'un node assigné dans l'éditeur.

## Philosophie

Ce projet suit les principes du **Software Craftsmanship** : code propre, testé, bien architecturé, livré en continu avec discipline. Chaque contribution doit laisser le code dans un meilleur état qu'elle ne l'a trouvé (règle du boy scout).

- **TDD** : écrire le test avant le code de production. Les tests documentent l'intention, pas l'implémentation.
- **Baby Steps** : avancer par petits incréments vérifiables. Chaque étape doit compiler, passer les tests, et laisser le code dans un état cohérent.
- **Clean Code** : noms explicites, fonctions courtes à responsabilité unique, pas de commentaires inutiles, pas de code mort.
- **YAGNI / KISS** : ne pas anticiper. Implémenter ce qui est demandé, rien de plus.

### Commentaires
- Un commentaire `##` (doc comment GDScript) **au-dessus de chaque fonction publique et de chaque `class_name`**, qui explique le *rôle*, les paramètres non évidents, la valeur de retour, et les effets de bord (signaux émis, état modifié).
- Commenter le **pourquoi**, jamais le quoi. Pas de `# incrémente i`. Un commentaire est utile s'il apporte une contrainte, une raison de design, un piège ou un `TODO` précis.
- Pas de commentaire sur les fonctions triviales (getter évident, handler d'une ligne).
- Langue : français (comme l'essentiel des commentaires existants). Identifiants de code en anglais.

## Architecture

### Principes
- **Composition avant héritage.** Un comportement = un composant (node avec script `class_name …Component`) ajouté comme enfant et branché via `@export`. L'héritage n'est utilisé que pour des bases minces (`Damageable`, `BaseWeapon`).
- **« Call down, signal up »** : un parent appelle les méthodes de ses enfants ; un enfant notifie vers le haut par signal. Un composant ne doit pas connaître le type concret de son parent plus que nécessaire.
- **Données = `Resource`** (`.tres` dans `datas/`), **état runtime = `RefCounted`/node**. Ne pas muter une `Resource` partagée pour de l'état propre à une instance (utiliser `ItemInstance`).
- **Autoloads parcimonieux** : uniquement pour des services globaux. Pas de logique de gameplay dedans.
- **Modèle / vue séparés** pour l'UI (voir inventaire) : le modèle ne connaît pas l'UI, la vue écoute ses signaux.

### Arborescence
```
autoloads/   Services globaux (singletons)
datas/       Resources de données + leurs scripts (items, armes, abilities)
scenes/
  components/  Composants réutilisables (health, aim, fov, object holder…)
  entities/    Damageable (base) → Player, Npc → Soldier
  weapons/     BaseWeapon → ProjectileWeapon (+ scènes guns/)
  items/       WorldItem (objet au sol, Area2D)
  levels/      BaseLevel + niveaux, shader de masque de lumière
  ui/          Menus, pause, inventaire (inventory/)
  fx/          Particules (hit, death)
shaders/  assets/
tests/       Tests gdUnit4, en miroir de scenes/ et datas/
```

### Autoloads (project.godot)
| Autoload | Rôle |
|---|---|
| `SignalManager` | Bus d'événements globaux (ex. `on_death`). Ajouter un signal ici seulement s'il est réellement transversal. |
| `GameManager` | État global (santé, type de contrôle), chargement de scènes. |
| `DataManager` | Sauvegarde/chargement `user://` (settings, bindings, meta, run) avec écriture atomique et migrations de schéma. |
| `SceneSpawnerManager` | Pools de particules (hit/death), initialisés par le niveau via `setup(container)`. |
| `CollisionManager` | Helpers de raycast 2D. |
| `SoundManager` | Lecture de sons par tag/position. |
| `InputSchemeManager` | Détecte clavier/manette, émet `scheme_changed`. |
| `RebindManager`, `SettingsManager` | Rebind des touches et réglages. |
| `MenuManager` | Pile de menus (`push`/`pop`) + gestion du focus. |

### Systèmes principaux
- **Entités** : `Damageable` (`CharacterBody2D`, `die()`) ← `Player`, `Npc` ← `Soldier`. La vie est un `HealthComponent` ; à 0 il émet `SignalManager.on_death` puis appelle `entity.die()`.
- **Armes** : `BaseWeaponData` (Resource) → scène `BaseWeapon` / `ProjectileWeapon` (raycast via `CollisionManager`). `ObjectHolderComponent` tient l'arme active ; `ObjectsHolderComponent` choisit l'arme selon l'index du slot et se `bind` à un `InventoryModel`.
- **Inventaire** : `InventoryModel` (logique pure, règles de type par slot, signal `slot_changed`) ; `ItemInstance` (data + scène instanciée à la demande) ; UI : `Inventory` → `InventoryView` → `InventorySlot` (drag & drop via `_get_drag_data` / `_can_drop_data` / `_drop_data`). Le joueur possède 3 modèles : `bag`, `armor`, `weapons`.
- **Visée** : `AimComponent` choisit souris ou manette selon `InputSchemeManager`, appelle `Player.set_aim_dir`.
- **Niveau** : `BaseLevel` orchestre caméra, lumière, viewports (`LitViewport`, `VisibilityViewport`) et initialise les pools de particules.

### Ajouter du contenu
- Nouvelle arme : un `.tres` héritant de `BaseWeaponData` + une scène sous `scenes/weapons/guns/` (pas de nouveau script si `ProjectileWeapon` suffit).
- Nouveau comportement d'entité : nouveau composant dans `scenes/components/`, exposé par `@export`, communiquant par signaux.
- Nouvel item : `.tres` de `BaseItemData` (type, texture, `equipped_scene_path`).

## Conventions Godot
- **Dossiers de premier niveau au pluriel** (`autoloads/`, `datas/`, `scenes/`, `shaders/`, `assets/`, `tests/`). Ne pas créer `test/`, `data/`, `scene/`…
- Un script par scène, à côté du `.tscn`, même nom. `class_name` sur tout ce qui est référencé ailleurs.
- Layers de physique nommés dans `project.godot` (`walls`, `caracters`) ; ne pas utiliser de numéros en dur ailleurs que dans une constante.
- Inputs : actions définies dans `project.godot` (`up/down/left/right`, `primary_ability`, `reload`, `open_bag`, `get_object_1..3`, `next_object`, `previous_object`, `pause`, `interact`, `aim_*`). Ne pas lire de touches brutes.
- Mouvement physique dans `_physics_process`, visuel/UI dans `_process`. Pas de travail coûteux par frame sans nécessité.

## Points connus à ne pas reproduire
Le code existant n'est pas toujours conforme à ces règles (projet d'apprentissage). Ne copie pas ces défauts dans du nouveau code, et propose de les corriger quand tu touches à la zone :
- Variables à une lettre (`p`, `t`, `d`, `T`) dans `scene_spawner_manager.gd`, `inventory_slot.gd`, `player.gd`.
- `InventoryView.bind_existing` lit `child.index` alors que la propriété est `slot_index`.
- Pas de garde-fous sur `object_holder_component.current_weapon` (peut être `null`) dans `player.gd`.
- Signal `test` inutilisé dans `health_component.gd` ; `print` de debug dans `game_manager.gd` / `menu_manager.gd`.
- Doublons `object_holder_component` / `objects_holder_component` (noms très proches : bien lire lequel on modifie).
- Fonctions sans type de retour ou sans commentaire dans plusieurs scripts.

## Tests

- Framework : gdUnit4 (addons/gdUnit4). Tests dans `tests/`, en miroir de l'arborescence du projet.
- Nommage : `<nom_du_script>_test.gd`, fonctions `test_<comportement>_<condition_ou_résultat>` 
  (ex: `test_take_damage_at_zero_emits_death`).
- Commande de lancement (headless) : `GODOT_BIN=/chemin/vers/godot addons/gdUnit4/runtest.sh -a res://tests` (voir README.md)
- Tout node créé dans un test est libéré (`auto_free`). Attendre les frames/physique avant d'asserter 
  sur un comportement dépendant du temps.
- Priorité de test : 1) logique pure et composants (Health, InventoryModel, états ennemis), 
  2) interactions entre nodes via scene runner, 3) pas de tests de rendu/shaders/feeling.
- Un test = un comportement. Pas de logique (if/boucle) dans un test. Pas de dépendance à l'ordre des tests.
- Ne jamais écrire un test qui passe en reproduisant l'implémentation ; tester le comportement observable.
- Ne pas modifier un test pour le faire passer sans me l'expliquer : un test qui échoue est peut-être un vrai bug.
- Hors périmètre : ne pas ajouter de tests sur le rendu, les shaders ou les SubViewports.
Ça évite les tests fragiles inutiles.

## Définition de "terminé"

Avant de dire qu'une tâche est finie :
1. Le projet se charge sans erreur (`godot --headless --check-only` ou équivalent).
2. Les tests existants passent.
3. Un nouveau comportement non trivial a au moins un test, ou tu dis pourquoi il n'est pas testable.
4. Tu listes les vérifications manuelles que je dois faire dans l'éditeur.

## Testabilité du code

- Un composant reçoit ses dépendances par `@export` ou paramètre, pas via `get_node` fragile 
  ni autoload en dur, pour pouvoir l'instancier seul dans un test.
- La logique de décision (détection, règles d'inventaire) vit dans des classes/fonctions sans dépendance au 
  SceneTree quand c'est possible.
- Pas d'accès direct aux autoloads dans la logique pure : passer la valeur ou le signal en argument.

## Git

### Branches

Modèle **Git Feature Branching** :

- `main` — production, protégée
- `feature/<description>` — nouvelle fonctionnalité
- `fix/<description>` — correction de bug
- `chore/<description>` — maintenance, tooling, dépendances
- `refactor/<description>` — refactoring sans changement fonctionnel

**Workflow :**

1. Créer une branche depuis `main`.
2. Ouvrir une PR vers `main`.
3. Merger dans `main` après review.

**Règles strictes :**
- Ne jamais pousser directement sur `main` — toujours passer par une branche et une PR, sauf exception vraiment justifiée (hotfix critique, commit de doc mineur en accord explicite).

### Commits

Format **Conventional Commits** obligatoire :

```
<type>(<scope optionnel>): <description courte en anglais>
```

Types : `feat`, `fix`, `chore`, `refactor`, `test`, `docs`, `perf`, `ci`

Exemples :
```
feat(detection): add detection for camera nodes
fix(player): handle invalid JSON in probable_cause
chore: update gitignore for .history and .claude files
test(saves): add roles params to list assertions
```

- Description en anglais, minuscule, sans point final
- Un commit = une intention claire
- Pas de `WIP`, pas de `fix fix`, pas de `misc`

### Pull Requests

Titre et description en français, template obligatoire :

```markdown
### Problème

### Solution

### Implémentation

### Recette
```
