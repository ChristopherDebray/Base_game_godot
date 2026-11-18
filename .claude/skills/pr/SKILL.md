---
name: pr
description: Crée une Pull Request vers main avec la description en français au format du projet (Problème, Solution, Implémentation, Recette) via gh, et gère son merge. À utiliser quand l'utilisateur veut ouvrir une PR, la mettre à jour, la merger ou la relire.
---

# Pull Requests

Cible : toujours `main`. Titre et description **en français**. Les commits restent en anglais (voir `git-flow`).

## Ouvrir une PR

1. Vérifier la branche (`git branch --show-current`) : refuser si c'est `main`, proposer d'en créer une (skill `git-flow`).
2. Vérifier qu'il y a des commits : `git log origin/main..HEAD --oneline`.
3. Lancer les tests (voir `CLAUDE.md`, section Tests) : ne pas ouvrir une PR avec des tests rouges.
4. Pousser : `git push -u origin <branche>`.
5. Créer la PR avec `gh pr create --base main --head <branche> --title "<titre>" --body "<description>"`.

Le titre suit Conventional Commits (`type(scope): résumé`) mais le résumé est en français.

Pour une description multi-lignes, passer le corps par un heredoc (`--body "$(cat <<'EOF' ... EOF)"`) avec ce gabarit obligatoire :

```markdown
### Problème

### Solution

### Implémentation

### Recette
```

## Contenu des sections

- **Problème** : pourquoi ce changement existe (bug observé, manque, risque).
- **Solution** : l'approche et pourquoi celle-là.
- **Implémentation** : ce qui a changé techniquement. Si la PR a plusieurs commits, les lister avec leur rôle, pour que le reviewer sache comment les relire. Signaler ce qui n'est volontairement pas traité.
- **Recette** : étapes de vérification concrètes (commande de test avec le résultat attendu, vérifications manuelles dans l'éditeur ou dans le jeu).

## Une PR = un sujet relisable

L'utilisateur relit chaque diff. Séparer en PR distinctes ce qui n'a pas le même niveau d'attention : par exemple l'installation d'un plugin tiers (code non relu, à signaler comme tel dans la description) à part du code du projet. Si les branches s'empilent, le préciser dans la description.

## Merger

Seulement sur demande explicite de l'utilisateur :

```bash
gh pr merge <numéro> --rebase --delete-branch
git checkout main && git pull --ff-only
```

`--rebase` garde l'historique linéaire et les messages de commit tels quels. Si `pull --ff-only` échoue, ne rien forcer : analyser la divergence (`git log origin/main..main` et `git log main..origin/main`) avant d'agir.

## Modifier une PR existante

`gh pr edit` échoue avec une erreur GraphQL (« Projects (classic) is being deprecated ») : passer par l'API REST.

```bash
gh api -X PATCH 'repos/{owner}/{repo}/pulls/<numéro>' -f body="<nouvelle description>"
```

## Rappels

- Aucune ligne de signature ni mention de Claude/IA dans le titre ou la description (voir `git-flow`).
- Ne jamais supprimer ni réécrire `main` pour « nettoyer » : demander à l'utilisateur.
