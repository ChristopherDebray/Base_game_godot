#!/usr/bin/env python3
"""Hook PreToolUse : bloque les commandes git/gh dangereuses lancées par Claude Code.

Protocole : le payload JSON arrive sur stdin ; exit 0 laisse passer, exit 2 bloque
et renvoie le message écrit sur stderr au modèle.

Règles :
  1. `--no-verify` sur git commit / git push.
  2. Push vers la branche protégée (`main`), y compris `HEAD:main`, `--delete main`,
     `--all`, `--mirror`, ou un `git push` sans destination alors qu'on est sur `main`.
  3. Marqueurs d'attribution à Claude dans un commit, une PR, une issue ou un appel `gh api`.

Périmètre : ne protège que l'outil Bash de Claude Code, pas les actions manuelles.
Limite connue : un message passé par fichier (`git commit -F`) n'est pas inspecté.
"""

import json
import re
import shlex
import subprocess
import sys

PROTECTED_BRANCH = "main"
PROTECTED_REFS = {PROTECTED_BRANCH, f"refs/heads/{PROTECTED_BRANCH}"}
BLOCKING_EXIT_CODE = 2
# `claude.md` est un vrai nom de fichier : on ne cible donc pas le mot « claude » seul.
ATTRIBUTION_PATTERN = re.compile(
    r"co-authored-by:|generated with \[?claude|noreply@anthropic\.com",
    re.IGNORECASE,
)
ATTRIBUTION_COMMAND_PATTERN = re.compile(r"^(git\s+commit|gh\s+(pr|issue|api))\b")
SEGMENT_SEPARATOR_PATTERN = re.compile(r"&&|\|\||;|\||\n")
PUSH_ALL_FLAGS = {"--all", "--mirror"}


def deny(message: str) -> None:
    """Bloque la commande : le message va sur stderr pour être renvoyé au modèle."""
    print(f"Bloqué par git_guard : {message}", file=sys.stderr)
    sys.exit(BLOCKING_EXIT_CODE)


def split_segments(command: str) -> list[str]:
    """Découpe une commande composée (`a && b | c`) en commandes simples."""
    return [segment.strip() for segment in SEGMENT_SEPARATOR_PATTERN.split(command) if segment.strip()]


def current_branch(working_directory: str | None) -> str:
    """Branche courante, ou chaîne vide si git est indisponible (HEAD détaché inclus)."""
    try:
        result = subprocess.run(
            ["git", "branch", "--show-current"],
            capture_output=True,
            text=True,
            cwd=working_directory or None,
            timeout=5,
            check=False,
        )
    except (OSError, subprocess.SubprocessError):
        return ""
    return result.stdout.strip()


def tokenize(segment: str) -> list[str]:
    """Découpe façon shell ; retombe sur un split simple si les guillemets sont mal formés."""
    try:
        return shlex.split(segment)
    except ValueError:
        return segment.split()


def refspec_destination(refspec: str) -> str:
    """Branche visée par un refspec : `+src:dst` -> `dst`, `branche` -> `branche`."""
    refspec = refspec.lstrip("+")
    return refspec.split(":", 1)[-1]


def check_no_verify(segment: str) -> None:
    if re.match(r"^git\s+(commit|push)\b", segment) and "--no-verify" in segment:
        deny("--no-verify est interdit. Si un hook git échoue, corriger la cause au lieu de le contourner.")


def check_push(segment: str, working_directory: str | None) -> None:
    tokens = tokenize(segment)
    if len(tokens) < 2 or tokens[0] != "git" or tokens[1] != "push":
        return
    options = [token for token in tokens[2:] if token.startswith("-")]
    positional = [token for token in tokens[2:] if not token.startswith("-")]
    if PUSH_ALL_FLAGS.intersection(options):
        deny(f"`git push {' '.join(sorted(PUSH_ALL_FLAGS.intersection(options)))}` peut pousser '{PROTECTED_BRANCH}'.")
    refspecs = positional[1:]
    if any(refspec_destination(refspec) in PROTECTED_REFS for refspec in refspecs):
        deny(f"push direct sur '{PROTECTED_BRANCH}' interdit. Passer par une branche et une PR.")
    if not refspecs and current_branch(working_directory) == PROTECTED_BRANCH:
        deny(f"`git push` depuis '{PROTECTED_BRANCH}' interdit. Créer une branche et ouvrir une PR.")


def check_attribution(command: str, segments: list[str]) -> None:
    """Cherche l'attribution dans la commande entière : un message multi-lignes (heredoc)
    place la ligne `Co-Authored-By` dans un autre segment que `git commit`."""
    targets_attribution = any(ATTRIBUTION_COMMAND_PATTERN.match(segment) for segment in segments)
    if targets_attribution and ATTRIBUTION_PATTERN.search(command):
        deny(
            "aucune attribution à Claude dans les commits, PR ou issues "
            "(pas de Co-Authored-By, pas de « Generated with Claude Code »)."
        )


def main() -> None:
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, EOFError):
        sys.exit(0)

    if not isinstance(payload, dict) or payload.get("tool_name") != "Bash":
        sys.exit(0)
    tool_input = payload.get("tool_input")
    command = tool_input.get("command", "") if isinstance(tool_input, dict) else ""
    if not isinstance(command, str):
        sys.exit(0)

    working_directory = payload.get("cwd")
    segments = split_segments(command)
    for segment in segments:
        check_no_verify(segment)
        check_push(segment, working_directory)
    check_attribution(command, segments)
    sys.exit(0)


if __name__ == "__main__":
    main()
