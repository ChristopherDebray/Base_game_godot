#!/usr/bin/env python3
"""Tests de check_gdscript.py. Lancer : `python3 .claude/skills/check-gdscript/scripts/check_gdscript_test.py`.

Chaque cas écrit un petit script GDScript dans un dossier temporaire, lance le vérificateur
dessus et compare les codes de violation obtenus. Exit 1 si un cas échoue.
"""

import re
import subprocess
import sys
import tempfile
from pathlib import Path

CHECKER_PATH = Path(__file__).with_name("check_gdscript.py")
NO_VIOLATION: list[str] = []

CLEAN_SCRIPT = '''extends Node

## Compte les points.
class_name Counter

const MAX_SCORE: int = 10

@export var score: int = 0
var label := "score"

## Ajoute des points au score.
func add_points(amount: int) -> void:
	score += amount

func _ready() -> void:
	for i in 3:
		score += i
'''

# (nom, contenu du script, codes de violation attendus triés)
CASES: list[tuple[str, str, list[str]]] = [
	("script conforme", CLEAN_SCRIPT, NO_VIOLATION),
	("variable d'une lettre", "extends Node\nfunc _ready() -> void:\n\tvar p: int = 1\n", ["SINGLE_LETTER_NAME"]),
	("constante d'une lettre", "extends Node\nconst T: int = 1\n", ["SINGLE_LETTER_NAME"]),
	("boucle for avec i tolérée", "extends Node\nfunc _ready() -> void:\n\tfor i in 3:\n\t\tpass\n", NO_VIOLATION),
	("paramètre d'une lettre", "extends Node\nfunc _on_slot_changed(i: int) -> void:\n\tpass\n", ["SINGLE_LETTER_NAME"]),
	("retour manquant", "extends Node\nfunc _ready():\n\tpass\n", ["MISSING_RETURN_TYPE"]),
	("paramètre sans type", "extends Node\nfunc _process(delta) -> void:\n\tpass\n", ["UNTYPED_PARAM"]),
	("variable sans type", "extends Node\nvar speed = 5\n", ["UNTYPED_VAR"]),
	("variable onready sans type", "extends Node\n@onready var child = $Child\n", ["UNTYPED_VAR"]),
	("variable avec := acceptée", "extends Node\nvar speed := 5\n", NO_VIOLATION),
	("print oublié", 'extends Node\nfunc _ready() -> void:\n\tprint("debug")\n', ["DEBUG_PRINT"]),
	("print dans une chaîne ignoré", 'extends Node\nvar label := "print(1)"\n', NO_VIOLATION),
	("print dans un commentaire ignoré", "extends Node\n# print(1)\n", NO_VIOLATION),
	("fonction publique sans doc", "extends Node\nfunc shoot() -> void:\n\tpass\n", ["MISSING_DOC"]),
	("fonction privée sans doc acceptée", "extends Node\nfunc _shoot() -> void:\n\tpass\n", NO_VIOLATION),
	("class_name sans doc", "extends Node\nclass_name Gun\n", ["MISSING_DOC"]),
	("doc au-dessus d'une annotation", "extends Node\n## Tire.\n@warning_ignore(\"unused_parameter\")\nfunc shoot() -> void:\n\tpass\n", NO_VIOLATION),
	(
		"signature sur plusieurs lignes",
		"extends Node\nfunc _move(\n\tdirection: Vector2,\n\tspeed\n) -> void:\n\tpass\n",
		["UNTYPED_PARAM"],
	),
	("fonction statique sans doc", "extends Node\nstatic func create() -> Node:\n\treturn null\n", ["MISSING_DOC"]),
	("doc séparée de la fonction par une ligne vide", "extends Node\n## Tire.\n\nfunc shoot() -> void:\n\tpass\n", ["MISSING_DOC"]),
	("class_name documenté", "extends Node\n## Un pistolet.\nclass_name Gun\n", NO_VIOLATION),
	("constante de plusieurs lettres acceptée", "extends Node\nconst MAX_SCORE: int = 10\n", NO_VIOLATION),
	("print appelé comme méthode ignoré", "extends Node\nfunc _ready() -> void:\n\tlogger.print(1)\n", NO_VIOLATION),
	("annotation à parenthèses imbriquées", "extends Node\n@export_range(0, 1, Vector2(1, 2).x) var speed = 1\n", ["UNTYPED_VAR"]),
	(
		"doc au-dessus d'une annotation à parenthèses imbriquées",
		"extends Node\n## Tire.\n@warning_ignore(\"a\", f(1))\nfunc shoot() -> void:\n\tpass\n",
		NO_VIOLATION,
	),
]

PUBLIC_FUNCTION_SCRIPT = "extends Node\nfunc shoot() -> void:\n\tpass\n"
VIOLATION_LINE_PATTERN = re.compile(r":\d+: ([A-Z_]+) ")
USAGE_ERROR_EXIT_CODE = 2


def run_checker(script_path: Path) -> tuple[int, list[str]]:
    result = subprocess.run([sys.executable, str(CHECKER_PATH), str(script_path)], capture_output=True, text=True, check=False)
    codes = sorted(VIOLATION_LINE_PATTERN.search(line).group(1) for line in result.stdout.splitlines() if VIOLATION_LINE_PATTERN.search(line))
    return result.returncode, codes


def check_case(name: str, actual: object, expected: object) -> int:
    if actual == expected:
        return 0
    print(f"ECHEC {name} : attendu {expected}, obtenu {actual}")
    return 1


def main() -> None:
    failures = 0
    total = 0
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        for index, (name, content, expected_codes) in enumerate(CASES):
            script_path = root / f"case_{index}.gd"
            script_path.write_text(content, encoding="utf-8")
            exit_code, codes = run_checker(script_path)
            expected_exit = 1 if expected_codes else 0
            failures += check_case(name, (codes, exit_code), (sorted(expected_codes), expected_exit))
            total += 1

        # L'exemption de MISSING_DOC dépend du nom `*_test.gd`, pas d'un dossier `tests/` du chemin.
        exempt_script = root / "gun_test.gd"
        exempt_script.write_text(PUBLIC_FUNCTION_SCRIPT, encoding="utf-8")
        failures += check_case("fichier *_test.gd exempté de MISSING_DOC", run_checker(exempt_script)[1], NO_VIOLATION)
        (root / "tests").mkdir()
        in_tests_directory = root / "tests" / "gun.gd"
        in_tests_directory.write_text(PUBLIC_FUNCTION_SCRIPT, encoding="utf-8")
        failures += check_case("script dans un dossier tests/ non exempté", run_checker(in_tests_directory)[1], ["MISSING_DOC"])
        total += 2

        (root / "notes.txt").write_text("x", encoding="utf-8")
        (root / "addons").mkdir()
        (root / "addons" / "plugin.gd").write_text(PUBLIC_FUNCTION_SCRIPT, encoding="utf-8")
        for name, unusable in [("fichier inexistant", root / "nope.gd"), ("fichier non .gd", root / "notes.txt"), ("dossier exclu", root / "addons" / "plugin.gd")]:
            failures += check_case(f"{name} refusé avec exit 2", run_checker(unusable)[0], USAGE_ERROR_EXIT_CODE)
            total += 1

    print(f"{total} cas, {failures} échec(s)")
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
