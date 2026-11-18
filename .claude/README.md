# Dossier `.claude/`

Configuration de Claude Code pour ce projet : des skills (instructions chargées à la demande), un agent de review, un hook de sécurité git et des règles. `CLAUDE.md` (à la racine) garde ce qui doit s'appliquer à chaque tour ; tout le reste est ici, pour ne pas alourdir le contexte.

## Skills (`skills/`)

Un skill est un dossier avec un `SKILL.md`. Seule sa description est toujours en contexte ; le contenu se charge quand le sujet arrive.

| Skill | Déclenchement | À quoi ça sert |
|---|---|---|
| `git-flow` | auto | Nommage des branches (`feature/`, `fix/`, `chore/`, `refactor/`), commits Conventional Commits, règles strictes (jamais de push sur `main`, aucune attribution à Claude). |
| `pr` | auto | Ouvrir, modifier et merger une PR : titre et description en français, gabarit Problème / Solution / Implémentation / Recette, merge en `--rebase`. |
| `test-conventions` | auto | Écrire et lancer des tests gdUnit4 : nommage, `auto_free`, signaux, espions, et **quand un test est requis ou non**. |
| `review` | auto | Lance l'agent `reviewer` sur une PR ou sur le travail en cours, rend un verdict, corrige les retours si on le demande. |
| `scaffold-component` | auto | Créer un composant réutilisable test d'abord (rôle, dépendances `@export`, signaux, gabarit de script, étapes de l'éditeur pour la scène). |
| `check-gdscript` | **manuel** | Vérifie les règles de style de `CLAUDE.md` par script (détail ci-dessous). |

*auto* : Claude le charge de lui-même quand le sujet s'y prête. *manuel* : il ne se lance que si on le demande explicitement (par exemple « lance check-gdscript »).

### `check-gdscript` : ce qu'il vérifie

Script Python sans dépendance (`skills/check-gdscript/scripts/check_gdscript.py`) qui lit les `.gd` ligne par ligne et applique les règles de style de `CLAUDE.md`. Il ne modifie rien.

| Code | Règle | Exemple signalé |
|---|---|---|
| `SINGLE_LETTER_NAME` | pas de variable, constante ou paramètre d'une lettre | `var p = ...`, `func _on_slot_changed(i: int)` |
| `MISSING_RETURN_TYPE` | typage du retour partout, `-> void` inclus | `func setup():` |
| `UNTYPED_PARAM` | paramètres typés | `func _process(delta):` |
| `UNTYPED_VAR` | variables typées (`:=` accepté) | `var result = compute()` |
| `DEBUG_PRINT` | pas de `print` de debug oublié | `print("ici")` |
| `MISSING_DOC` | commentaire `##` au-dessus de chaque fonction publique et de chaque `class_name` | `func can_place(...)` sans `##` (fichiers `*_test.gd` exemptés) |

```bash
python3 .claude/skills/check-gdscript/scripts/check_gdscript.py          # fichiers modifiés ou non suivis vs origin/main
python3 .claude/skills/check-gdscript/scripts/check_gdscript.py --all    # tout le projet
python3 .claude/skills/check-gdscript/scripts/check_gdscript.py a.gd     # fichiers précis
```

- Code de sortie : `0` propre, `1` violations, `2` erreur d'utilisation (fichier introuvable, `origin/main` absent). Un `2` n'est jamais un « tout est propre ».
- Par défaut il ne regarde que ce que tu as touché : le code existant a beaucoup de dette connue (environ 200 violations avec `--all`), à ne pas corriger au passage d'une autre tâche.
- C'est une analyse par lignes, sans arbre syntaxique : elle ne voit pas les boucles `for`, les lambdas, les paramètres de `signal` ni les `var` sur plusieurs lignes. En cas de doute, lire le code avant de « corriger ».
- Il ne vérifie pas que le projet se charge : c'est le rôle des tests gdUnit.

## Agent (`agents/reviewer.md`)

Relecteur en lecture seule (outils Read, Grep, Glob, Bash) qui démarre **sans le contexte de dev** : il juge ce qu'il voit, ce qui évite le biais de l'auteur et le coût de relire toute la session. On le lance via le skill `review`. Il applique `CLAUDE.md` et `review-rules.md`, et répond au format : verdict, bloquants, à améliorer, vérifications automatiques.

## Règles de review (`review-rules.md`)

Lu uniquement par le `reviewer` : ce qui est bloquant, ce qu'il faut regarder en priorité, ce qu'il faut ignorer (dette connue, `addons/`, rendu). Il complète `CLAUDE.md` sans le dupliquer.

## Hook de sécurité git (`hooks/git_guard.py`)

Déclaré dans `settings.json`, il s'exécute avant chaque commande Bash de Claude Code et la bloque si elle :
- pousse vers `main` (y compris `HEAD:main`, `--delete main`, `--all`, ou un `git push` nu depuis `main`) ;
- utilise `--no-verify` ;
- contient une attribution à Claude (`Co-Authored-By`, « Generated with Claude Code ») dans un commit, une PR ou une issue.

Il ne protège que les actions de Claude : pas tes propres commandes, ni un message passé par fichier (`git commit -F`). La protection de `main` côté GitHub (PR obligatoire, checks) est la vraie barrière.

Test : `python3 .claude/hooks/git_guard_test.py`.

## `settings.json`

Désactive l'attribution automatique à Claude dans les commits et PR (`attribution` vide + `includeCoAuthoredBy: false`) et déclare le hook. À ne pas modifier sans raison.

## CI (hors de ce dossier)

`.github/workflows/tests.yml` lance sur chaque PR vers `main` : les tests gdUnit4 (si la PR touche autre chose que de la doc ou `.claude/`) et les tests Python des outils (si le hook ou les scripts des skills changent). Un job de détection décide ce qui est utile ; les jobs ignorés comptent comme réussis pour la règle de protection de `main`.

## Ajouter un skill ou un agent

- Skill : `skills/<nom>/SKILL.md` avec un frontmatter `name` et `description` (c'est la description qui déclenche le chargement : la garder courte et précise). `disable-model-invocation: true` pour un skill manuel.
- Agent : `agents/<nom>.md` avec `name`, `description` et `tools`.
- Un script Python va dans `skills/<nom>/scripts/` avec son test `*_test.py` à côté. La CI ne lance un test que s'il est listé dans le job `tooling` de `.github/workflows/tests.yml` : l'y ajouter.
- Les nouveaux skills et agents sont chargés au démarrage de Claude Code : redémarrer après un merge.
