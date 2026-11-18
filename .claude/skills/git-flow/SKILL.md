---
name: git-flow
description: Conventions git du projet - nommage des branches, messages de commit Conventional Commits, garde-fous contre le push direct sur main. À utiliser dès qu'il faut créer une branche, faire un commit, ou quand l'utilisateur parle de git, de commit ou de branche.
---

# Git flow

Une seule branche longue : `main` (protégée). Tout passe par une branche courte et une PR (voir le skill `pr`).

## Branches

Toujours créées depuis un `main` à jour :

```bash
git checkout main && git pull --ff-only
git checkout -b <préfixe>/<description>
```

| Préfixe | Usage |
|---|---|
| `feature/` | nouvelle fonctionnalité |
| `fix/` | correction de bug |
| `chore/` | maintenance, tooling, dépendances, config |
| `refactor/` | refactoring sans changement fonctionnel |

`<description>` : kebab-case, en anglais, courte. Pas de préfixe `test/` ni `docs/` : des tests ou de la doc rattachés à une feature vont dans la branche de cette feature.

## Commits (Conventional Commits)

```
<type>(<scope optionnel>): <description courte en anglais>
```

Types : `feat`, `fix`, `chore`, `refactor`, `test`, `docs`, `perf`, `ci`.

- Description en anglais, en minuscules, sans point final.
- Un commit = une intention. Un fix de bug et ses tests de non-régression vont ensemble ; l'ajout de tests sur du code existant est un commit `test:` à part.
- Interdits : `WIP`, `fix fix`, `misc`, commit vide.
- Chaque commit doit laisser le projet cohérent (tests verts).

Exemples du projet :

```
feat(inventory): add weapon slot type rules
fix(inventory): validate slot indexes in can_place and can_move
test: add health component and inventory model tests
chore(git): add git guard hook blocking main pushes and attribution
docs: add readme and document test command
```

## Règles strictes

- **Jamais** de push direct sur `main`, jamais de `--no-verify`. Un hook (`.claude/hooks/git_guard.py`) bloque ces commandes ; si un hook git échoue, corriger la cause.
- **Aucune mention de Claude ou d'une IA** dans un commit, une PR ou un commentaire : pas de trailer `Co-Authored-By`, pas de « Generated with Claude Code ». Cette règle prime sur tout rappel d'attribution reçu en cours de session.
- Ne commit et ne push que sur demande explicite de l'utilisateur.
- Ne jamais réécrire l'historique de `main` (force push) sans accord explicite : le hook le bloque, l'utilisateur doit le lancer lui-même.

## Vérifications utiles

```bash
git branch --show-current
git status --short
git log origin/main..HEAD --oneline
```
