#!/usr/bin/env python3
"""Tests de git_guard.py. Lancer : `python3 .claude/hooks/git_guard_test.py` (exit 1 si échec).

Chaque cas envoie un payload de hook réel sur stdin et vérifie le code de sortie
(0 = autorisé, 2 = bloqué). Le cas « git push depuis main » utilise un dépôt temporaire
sur `main`, pour ne pas dépendre de la branche courante du projet.
"""

import json
import subprocess
import sys
import tempfile
from pathlib import Path

GUARD_PATH = Path(__file__).with_name("git_guard.py")
ALLOWED_EXIT_CODE = 0
BLOCKED_EXIT_CODE = 2
MAIN_REPO_MARKER = "REPO_MAIN"

HEREDOC_BAD = 'git commit -m "$(cat <<\'EOF\'\nfeat: x\n\nCo-Authored-By: Claude Sonnet <noreply@anthropic.com>\nEOF\n)"'
HEREDOC_OK = 'git commit -m "$(cat <<\'EOF\'\nchore: track claude.md\n\nEOF\n)"'
# (attendu, commande, emplacement)
CASES = [
 ("allow", "git status", "."),
 ("allow", "git push -u origin chore/x", "."),
 ("allow", "git push --force-with-lease=chore/x:abc origin chore/x", "."),
 ("allow", "git push", "."),  # branche courante != main
 ("allow", HEREDOC_OK, "."),
 ("allow", 'gh pr create --title "t" --body "### Problème"', "."),
 ("allow", "gh pr merge 20 --rebase --delete-branch", "."),
 ("allow", "echo main", "."),
 ("allow", "git checkout main && git pull", "."),
 ("deny", "git push origin main", "."),
 ("deny", "git push -u origin main", "."),
 ("deny", "git push origin HEAD:main", "."),
 ("deny", "git push origin +feature:refs/heads/main", "."),
 ("deny", "git push --force-with-lease=main:97d689d origin main", "."),
 ("deny", "git push origin --delete main", "."),
 ("deny", "git push --all", "."),
 ("deny", "git add . && git push origin main", "."),
 ("deny", "git push", MAIN_REPO_MARKER),  # branche courante == main
 ("deny", "git commit --no-verify -m x", "."),
 ("deny", "git push --no-verify origin chore/x", "."),
 ("deny", HEREDOC_BAD, "."),
 ("deny", 'git commit -m "x" -m "Co-authored-by: Claude <a@b.c>"', "."),
 ("deny", 'gh pr create --title t --body "x\n🤖 Generated with [Claude Code](https://claude.com/claude-code)"', "."),
 ("deny", 'gh api -X PATCH repos/o/r/pulls/1 -f body="Generated with Claude Code"', "."),
]

INVALID_INPUTS = ["", "pas du json", "[]", '{"tool_name":"Bash","tool_input":null}', '{"tool_name":"Read"}']


def run_guard(command: str, working_directory: str, raw_input: str | None = None) -> subprocess.CompletedProcess[str]:
    payload = raw_input
    if payload is None:
        payload = json.dumps({"tool_name": "Bash", "tool_input": {"command": command}, "cwd": working_directory})
    return subprocess.run([sys.executable, str(GUARD_PATH)], input=payload, capture_output=True, text=True, check=False)


def main() -> None:
    failures = 0
    with tempfile.TemporaryDirectory() as main_repo:
        subprocess.run(["git", "init", "-q", "-b", "main", main_repo], check=True)
        for expected, command, location in CASES:
            working_directory = main_repo if location == MAIN_REPO_MARKER else "."
            exit_code = run_guard(command, working_directory).returncode
            expected_code = BLOCKED_EXIT_CODE if expected == "deny" else ALLOWED_EXIT_CODE
            if exit_code != expected_code:
                failures += 1
                print(f"ECHEC attendu={expected} obtenu={exit_code} : {command.splitlines()[0]}")
    for raw_input in INVALID_INPUTS:
        if run_guard("", ".", raw_input).returncode != ALLOWED_EXIT_CODE:
            failures += 1
            print(f"ECHEC entrée invalide non tolérée : {raw_input!r}")
    print(f"{len(CASES) + len(INVALID_INPUTS)} cas, {failures} échec(s)")
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
