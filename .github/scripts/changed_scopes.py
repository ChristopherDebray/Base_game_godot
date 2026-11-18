#!/usr/bin/env python3
"""Décide quels jobs de test lancer d'après la liste des fichiers modifiés par une PR.

Entrée : un chemin de fichier par ligne sur stdin (`git diff --name-only`).
Sortie : `game=true|false` et `tooling=true|false`, au format de $GITHUB_OUTPUT.

  game     le contenu Godot peut avoir changé : lancer la suite gdUnit4.
           Faux si tous les fichiers sont de la doc, de la config d'outillage (`.claude/`)
           ou `.gitignore` : Godot ignore les dossiers cachés et ces fichiers ne sont pas du jeu.
  tooling  un outil testé en Python a changé (hook git, scripts des skills, CI).

Les changements sous `.github/` déclenchent tout : on vérifie la CI en la modifiant.
Une liste vide (ex. lancement manuel) déclenche tout, par prudence.
"""

import re
import sys

NON_GAME_PATTERNS = [
    re.compile(r"^\.claude/"),
    re.compile(r"\.md$"),
    re.compile(r"^\.gitignore$"),
    re.compile(r"^LICENSE"),
]
TOOLING_PATTERNS = [
    re.compile(r"^\.claude/hooks/"),
    re.compile(r"^\.claude/skills/[^/]+/scripts/"),
]
CI_PATTERN = re.compile(r"^\.github/")


def matches_any(path: str, patterns: list[re.Pattern[str]]) -> bool:
    return any(pattern.search(path) for pattern in patterns)


def detect_scopes(changed_files: list[str]) -> dict[str, bool]:
    """Renvoie quels jobs lancer ; tout si la liste est vide ou si la CI elle-même change."""
    if not changed_files or any(CI_PATTERN.match(path) for path in changed_files):
        return {"game": True, "tooling": True}
    return {
        "game": any(not matches_any(path, NON_GAME_PATTERNS) for path in changed_files),
        "tooling": any(matches_any(path, TOOLING_PATTERNS) for path in changed_files),
    }


def main() -> None:
    changed_files = [line.strip() for line in sys.stdin.read().splitlines() if line.strip()]
    for scope, enabled in detect_scopes(changed_files).items():
        print(f"{scope}={str(enabled).lower()}")


if __name__ == "__main__":
    main()
