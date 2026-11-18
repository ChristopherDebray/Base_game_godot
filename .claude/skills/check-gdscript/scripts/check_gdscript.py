#!/usr/bin/env python3
"""Vérifie les règles de style de CLAUDE.md sur des scripts GDScript.

Règles (toutes bloquantes, exit 1 si au moins une violation) :
  SINGLE_LETTER_NAME   variable, constante ou paramètre de fonction d'une seule lettre
  MISSING_RETURN_TYPE  fonction sans `-> type` (y compris `-> void`)
  UNTYPED_PARAM        paramètre de fonction sans type
  UNTYPED_VAR          variable sans type explicite ni `:=`
  DEBUG_PRINT          print / prints / printt / print_debug / print_rich oublié
  MISSING_DOC          fonction publique ou `class_name` sans commentaire `##` juste au-dessus
                       (fichiers `*_test.gd` exemptés)

Usage :
  check_gdscript.py                 fichiers .gd modifiés (commits, index, working tree) ou
                                    non suivis par rapport à origin/main
  check_gdscript.py --all           tout le projet (hors addons/ et .godot/)
  check_gdscript.py fichier.gd ...  fichiers explicites

Codes de sortie : 0 propre, 1 violations, 2 erreur d'utilisation (fichier non analysable,
origin/main introuvable, hors dépôt git) : jamais de « propre » silencieux.

Analyse par lignes, sans AST GDScript. Non vérifiés (faux négatifs connus) : les boucles
`for`, les paramètres de lambdas et de `signal`, les chaînes multi-lignes (triples guillemets) et les
déclarations de `var` réparties sur plusieurs lignes.
"""

import os
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

BASE_REF = "origin/main"
EXCLUDED_DIRECTORIES = {"addons", ".godot", ".git", "reports"}
TEST_FILE_SUFFIX = "_test.gd"
EXIT_VIOLATIONS = 1
EXIT_USAGE_ERROR = 2

# Un niveau de parenthèses imbriquées suffit (`@export_range(0, 1, Vector2(1, 2).x)`).
ANNOTATION_ARGUMENTS = r"\((?:[^()]|\([^()]*\))*\)"
ANNOTATION_PATTERN = re.compile(rf"^\s*@\w+({ANNOTATION_ARGUMENTS})?\s*$")
FUNC_PATTERN = re.compile(r"^\s*(?:static\s+)?func\s+(\w+)\s*\(")
VAR_PATTERN = re.compile(rf"^\s*(?:@\w+(?:{ANNOTATION_ARGUMENTS})?\s+)*(?:static\s+)?var\s+(\w+)\s*(.*)$")
CONST_PATTERN = re.compile(r"^\s*const\s+(\w+)")
CLASS_NAME_PATTERN = re.compile(r"^\s*class_name\s+\w+")
PRINT_PATTERN = re.compile(r"(?<![\w.])(?:print|prints|printt|print_debug|print_rich)\s*\(")
STRING_PATTERN = re.compile(r'"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'')


@dataclass(frozen=True)
class Violation:
    path: Path
    line_number: int
    code: str
    message: str

    def __str__(self) -> str:
        return f"{self.path}:{self.line_number}: {self.code} {self.message}"


def strip_strings_and_comment(line: str) -> str:
    """Retire les chaînes puis le commentaire de fin de ligne, pour ne pas matcher leur contenu."""
    without_strings = STRING_PATTERN.sub('""', line)
    return without_strings.split("#", 1)[0]


def split_parameters(parameter_text: str) -> list[str]:
    """Découpe une liste de paramètres sur les virgules de premier niveau."""
    parameters: list[str] = []
    depth = 0
    current = ""
    for character in parameter_text:
        if character in "([{":
            depth += 1
        elif character in ")]}":
            depth -= 1
        if character == "," and depth == 0:
            parameters.append(current.strip())
            current = ""
            continue
        current += character
    if current.strip():
        parameters.append(current.strip())
    return parameters


def read_signature(lines: list[str], start_index: int) -> str:
    """Rassemble une signature de fonction, éventuellement répartie sur plusieurs lignes."""
    signature = ""
    depth = 0
    for line in lines[start_index:]:
        code = strip_strings_and_comment(line)
        signature += code.strip() + " "
        depth += code.count("(") - code.count(")")
        if depth <= 0:
            break
    return signature


def has_doc_above(lines: list[str], line_index: int) -> bool:
    """Vrai si la ligne au-dessus (hors annotations) est un commentaire `##`."""
    index = line_index - 1
    while index >= 0 and ANNOTATION_PATTERN.match(lines[index]):
        index -= 1
    return index >= 0 and lines[index].strip().startswith("##")


def check_signature(path: Path, line_number: int, signature: str) -> list[Violation]:
    open_index = signature.index("(")
    depth = 0
    close_index = open_index
    for offset, character in enumerate(signature[open_index:], start=open_index):
        depth += character == "("
        depth -= character == ")"
        if depth == 0:
            close_index = offset
            break
    violations: list[Violation] = []
    if "->" not in signature[close_index:]:
        violations.append(Violation(path, line_number, "MISSING_RETURN_TYPE", "fonction sans type de retour"))
    for parameter in split_parameters(signature[open_index + 1 : close_index]):
        name = parameter.split(":", 1)[0].split("=", 1)[0].strip()
        if len(name) == 1:
            violations.append(Violation(path, line_number, "SINGLE_LETTER_NAME", f"paramètre '{name}'"))
        if ":" not in parameter:
            violations.append(Violation(path, line_number, "UNTYPED_PARAM", f"paramètre '{name}' sans type"))
    return violations


def check_lines(path: Path, lines: list[str], require_doc: bool) -> list[Violation]:
    violations: list[Violation] = []
    for index, raw_line in enumerate(lines):
        line_number = index + 1
        if raw_line.strip().startswith("#"):
            continue
        code = strip_strings_and_comment(raw_line)

        func_match = FUNC_PATTERN.match(code)
        if func_match:
            violations.extend(check_signature(path, line_number, read_signature(lines, index)))
            if require_doc and not func_match.group(1).startswith("_") and not has_doc_above(lines, index):
                violations.append(Violation(path, line_number, "MISSING_DOC", f"fonction publique '{func_match.group(1)}' sans commentaire ##"))
            continue

        if CLASS_NAME_PATTERN.match(code) and require_doc and not has_doc_above(lines, index):
            violations.append(Violation(path, line_number, "MISSING_DOC", "class_name sans commentaire ##"))

        if PRINT_PATTERN.search(code):
            violations.append(Violation(path, line_number, "DEBUG_PRINT", "print oublié"))

        var_match = VAR_PATTERN.match(code)
        if var_match:
            name, remainder = var_match.group(1), var_match.group(2).lstrip()
            if len(name) == 1:
                violations.append(Violation(path, line_number, "SINGLE_LETTER_NAME", f"variable '{name}'"))
            if not remainder.startswith(":"):
                violations.append(Violation(path, line_number, "UNTYPED_VAR", f"variable '{name}' sans type"))

        const_match = CONST_PATTERN.match(code)
        if const_match and len(const_match.group(1)) == 1:
            violations.append(Violation(path, line_number, "SINGLE_LETTER_NAME", f"constante '{const_match.group(1)}'"))
    return violations


def check_file(path: Path) -> list[Violation]:
    lines = path.read_text(encoding="utf-8").splitlines()
    require_doc = not path.name.endswith(TEST_FILE_SUFFIX)
    return check_lines(path, lines, require_doc)


def is_checkable(path: Path) -> bool:
    return path.suffix == ".gd" and not EXCLUDED_DIRECTORIES.intersection(path.parts) and path.is_file()


def fail(message: str) -> None:
    """Erreur d'utilisation : message sur stderr et code distinct d'une violation de style."""
    print(f"check_gdscript: {message}", file=sys.stderr)
    sys.exit(EXIT_USAGE_ERROR)


def run_git(arguments: list[str], error_message: str) -> list[str]:
    result = subprocess.run(["git", *arguments], capture_output=True, text=True, check=False)
    if result.returncode != 0:
        fail(error_message)
    return [line for line in result.stdout.splitlines() if line]


def enter_repository_root() -> None:
    """Se place à la racine du dépôt contenant ce script : `--all` et git ne dépendent plus du dossier d'appel."""
    script_directory = str(Path(__file__).resolve().parent)
    top_level = run_git(["-C", script_directory, "rev-parse", "--show-toplevel"], "pas dans un dépôt git")
    os.chdir(top_level[0])


def changed_files() -> list[Path]:
    """Fichiers .gd modifiés (commits, indexés ou non) ou non suivis par rapport à BASE_REF."""
    base = run_git(["merge-base", BASE_REF, "HEAD"], f"{BASE_REF} introuvable : lancer `git fetch origin`")[0]
    tracked = run_git(["diff", "--name-only", "--diff-filter=d", base], "git diff a échoué")
    untracked = run_git(["ls-files", "--others", "--exclude-standard"], "git ls-files a échoué")
    return [Path(name) for name in sorted(set(tracked + untracked))]


def all_files() -> list[Path]:
    return sorted(Path(".").rglob("*.gd"))


def is_checkable(path: Path) -> bool:
    return path.suffix == ".gd" and not EXCLUDED_DIRECTORIES.intersection(path.parts) and path.is_file()


def select_files(arguments: list[str]) -> list[Path]:
    explicit = [Path(argument) for argument in arguments if not argument.startswith("--")]
    if explicit:
        for path in explicit:
            if not is_checkable(path):
                fail(f"fichier non analysable : {path} (inexistant, non .gd, ou dans un dossier exclu)")
        return explicit
    enter_repository_root()
    candidates = all_files() if "--all" in arguments else changed_files()
    return [path for path in candidates if is_checkable(path)]


def main() -> None:
    files = select_files(sys.argv[1:])
    violations = [violation for path in files for violation in check_file(path)]
    for violation in violations:
        print(violation)
    print(f"{len(files)} fichier(s) analysé(s), {len(violations)} violation(s)")
    sys.exit(EXIT_VIOLATIONS if violations else 0)


if __name__ == "__main__":
    main()
