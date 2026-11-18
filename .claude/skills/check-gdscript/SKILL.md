---
name: check-gdscript
description: Vérifie les règles de style de CLAUDE.md sur les scripts GDScript (variables d'une lettre, typage manquant, print oublié, commentaire ## manquant). Par défaut sur les fichiers modifiés par rapport à main. À lancer avant d'ouvrir une PR ou quand l'utilisateur demande de vérifier le style.
disable-model-invocation: true
---

# Vérification du style GDScript

Lance le script, il ne modifie aucun fichier :

```bash
python3 .claude/skills/check-gdscript/scripts/check_gdscript.py            # fichiers modifiés ou non suivis vs origin/main
python3 .claude/skills/check-gdscript/scripts/check_gdscript.py --all      # tout le projet (hors addons/)
python3 .claude/skills/check-gdscript/scripts/check_gdscript.py a.gd b.gd  # fichiers explicites
```

Une ligne par violation : `fichier:ligne: CODE message`. Exit 0 propre, **1** violations, **2** erreur d'utilisation (fichier inexistant, non `.gd` ou dans `addons/`, `origin/main` introuvable : lancer `git fetch origin`). Un exit 2 n'est jamais un « tout est propre ». Les modes par défaut et `--all` se placent seuls à la racine du dépôt, d'où qu'on lance le script.

| Code | Règle de `CLAUDE.md` |
|---|---|
| `SINGLE_LETTER_NAME` | pas de variable, constante ou paramètre d'une lettre (boucles `for` tolérées) |
| `MISSING_RETURN_TYPE` | typage statique partout, `-> void` inclus |
| `UNTYPED_PARAM`, `UNTYPED_VAR` | typage statique des paramètres et variables (`:=` accepté) |
| `DEBUG_PRINT` | pas de `print` de debug oublié |
| `MISSING_DOC` | commentaire `##` au-dessus de chaque fonction publique et de chaque `class_name` (fichiers `*_test.gd` exemptés) |

## Comment l'utiliser

- Le code existant a beaucoup de dette connue (voir « Points connus » de `CLAUDE.md`) : `--all` en signale environ 200. Ne pas la corriger au passage d'une autre tâche ; corriger ce que la tâche touche, et proposer le reste à l'utilisateur.
- C'est une analyse par lignes, sans AST. Faux négatifs connus : boucles `for`, paramètres de lambdas et de `signal`, chaînes multi-lignes, `var` sur plusieurs lignes, annotations avec plus d'un niveau de parenthèses imbriquées. En cas de doute sur une violation, lire le code avant de « corriger ».
- Elle ne vérifie **pas** que le projet se charge : pour cela, lancer les tests gdUnit (skill `test-conventions`). `godot --check-only --script` sur un fichier isolé donne de faux échecs dès qu'un script utilise un autoload.

## Tester le script lui-même

```bash
python3 .claude/skills/check-gdscript/scripts/check_gdscript_test.py
```
