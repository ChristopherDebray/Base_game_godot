# New Game Project

Top-down 2D en Godot 4.7 (GDScript, GL Compatibility), projet d'apprentissage. Voir `CLAUDE.md` pour l'architecture et les conventions.

## Prérequis

- Godot **4.7.x**.
- Rien d'autre à installer : le plugin de test gdUnit4 est versionné dans `addons/gdUnit4/`.

## Premier lancement après un clone

Le dossier `.godot/` (cache) n'est pas versionné. Il faut le régénérer une fois :

```bash
godot --headless --import
```

Ou simplement ouvrir le projet dans l'éditeur.

## Lancer les tests (gdUnit4)

Dans l'éditeur : dock **gdUnit4** → *Run*.

En ligne de commande (headless) :

```bash
export GODOT_BIN=/chemin/vers/Godot_v4.7.2-stable_linux.x86_64
addons/gdUnit4/runtest.sh -a res://tests
```

- Le code de sortie est non nul si un test échoue (utilisable en CI).
- Les rapports HTML/XML sont écrits dans `reports/` (ignoré par git).
- Un test ciblé : `addons/gdUnit4/runtest.sh -a res://tests/datas/items/inventory_model_test.gd`

## Organisation des tests

`tests/` reprend l'arborescence du projet (`tests/scenes/...`, `tests/datas/...`). Un fichier `<script>_test.gd` par script testé.

## Mettre à jour gdUnit4

Télécharger la release sur <https://github.com/godot-gdunit-labs/gdUnit4/releases>, remplacer `addons/gdUnit4/`, puis relancer `godot --headless --import`.
