---
name: review
description: Lance une review indépendante (subagent sans contexte de dev) d'une PR ou du travail en cours et retourne le verdict, puis corrige les retours si demandé. À utiliser quand l'utilisateur dit "review", "relis mon code", "fais une review", "review la PR 24", "review ma branche", éventuellement suivi de "puis corrige les retours".
argument-hint: "[numéro de PR] [puis corrige]"
---

# Review indépendante

Arguments : `$ARGUMENTS`

## Pourquoi un subagent

La review tourne dans un contexte vierge : elle n'est pas biaisée par ce qu'on vient d'écrire, et elle ne relit pas à chaque tour tout le contexte accumulé de la session (c'est ce qui la rend moins chère). Seul son verdict revient dans la session.

## Étapes

1. **Cible** :
   - un numéro de PR dans `$ARGUMENTS` ou dans la demande → cette PR (`gh pr view <n>`, `gh pr diff <n>`) ;
   - sinon le **travail en cours de la branche courante** : commits depuis `main` (`git diff $(git merge-base origin/main HEAD)`), modifications non commitées, et fichiers non suivis (`git status --short`).
2. **Règles de review** : le fichier `.claude/review-rules.md` du dépôt existe ; le reviewer doit le lire.
3. **Lancer le reviewer** avec l'outil Agent, `subagent_type: "reviewer"` (jamais `fork` : il doit rester à froid). Dans le prompt, ne donne que :
   - la cible (numéro de PR, ou « travail en cours de la branche courante ») et l'intention en une ou deux phrases, telle que l'utilisateur ou la description de la PR la formule ;
   - le chemin `.claude/review-rules.md` ;
   - les vérifications à lancer, **uniquement si la cible est le travail en cours ou la branche actuellement checkout** (sinon dis qu'elles n'ont pas été exécutées) :
     ```bash
     export GODOT_BIN="${GODOT_BIN:-$HOME/Applications/godot/Godot_v4.7.2-stable_linux.x86_64}"
     addons/gdUnit4/runtest.sh -a res://tests
     ```
     Si `GODOT_BIN` n'existe pas, le reviewer le signale sans chercher ailleurs.
   Tu peux aussi indiquer les fichiers hors périmètre à ignorer (modifications préexistantes, fichiers non suivis étrangers à la tâche). Ne transmets ni ton raisonnement, ni l'historique de dev, ni tes doutes sur le code : l'indépendance est le but.
4. **Restituer** le verdict tel quel (bloquants, à améliorer, vérifications).
5. **Corriger** uniquement si l'utilisateur l'a demandé (« puis corrige », « applique les retours ») :
   - traiter les bloquants, puis les améliorations évidentes ; dire lesquelles sont ignorées et pourquoi ;
   - respecter `CLAUDE.md` (TDD, style), relancer les tests ;
   - ne pas commit ni push sans demande explicite ;
   - si les correctifs sont importants, proposer une 2e passe du reviewer (nouvel agent, toujours à froid).

Sans demande de correction, s'arrêter après la restitution du verdict.
