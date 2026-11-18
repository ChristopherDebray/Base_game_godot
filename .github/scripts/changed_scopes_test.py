#!/usr/bin/env python3
"""Tests de changed_scopes.py. Lancer : `python3 .github/scripts/changed_scopes_test.py` (exit 1 si échec)."""

import subprocess
import sys
from pathlib import Path

SCRIPT_PATH = Path(__file__).with_name("changed_scopes.py")

# (nom, fichiers modifiés, game attendu, tooling attendu)
CASES: list[tuple[str, list[str], bool, bool]] = [
    ("README seul", ["README.md"], False, False),
    ("CLAUDE.md et skill markdown", ["CLAUDE.md", ".claude/skills/pr/SKILL.md"], False, False),
    ("règles de review et agent", [".claude/review-rules.md", ".claude/agents/reviewer.md"], False, False),
    ("gitignore seul", [".gitignore"], False, False),
    ("script GDScript", ["autoloads/data_manager.gd"], True, False),
    ("test GDScript", ["tests/autoloads/data_manager_test.gd"], True, False),
    ("scène", ["scenes/ui/main_menu.tscn"], True, False),
    ("project.godot", ["project.godot"], True, False),
    ("asset", ["assets/player.png"], True, False),
    ("plugin gdUnit4", ["addons/gdUnit4/plugin.cfg"], True, False),
    ("doc et code mélangés", ["README.md", "scenes/ui/main_menu.gd"], True, False),
    ("hook git seul", [".claude/hooks/git_guard.py"], False, True),
    ("script de skill seul", [".claude/skills/check-gdscript/scripts/check_gdscript.py"], False, True),
    ("hook et jeu mélangés", [".claude/hooks/git_guard.py", "scenes/ui/main_menu.gd"], True, True),
    ("config de la CI", [".github/workflows/tests.yml"], True, True),
    ("liste vide", [], True, True),
]


def run_script(changed_files: list[str]) -> dict[str, str]:
    result = subprocess.run(
        [sys.executable, str(SCRIPT_PATH)],
        input="\n".join(changed_files),
        capture_output=True,
        text=True,
        check=False,
    )
    return dict(line.split("=", 1) for line in result.stdout.splitlines())


def main() -> None:
    failures = 0
    for name, changed_files, expected_game, expected_tooling in CASES:
        actual = run_script(changed_files)
        expected = {"game": str(expected_game).lower(), "tooling": str(expected_tooling).lower()}
        if actual != expected:
            failures += 1
            print(f"ECHEC {name} : attendu {expected}, obtenu {actual}")
    print(f"{len(CASES)} cas, {failures} échec(s)")
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
