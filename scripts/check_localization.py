#!/usr/bin/env python3
"""Falla si hay texto de UI en Swift que no esté en Localizable.xcstrings.

Motivo: la app tiene `developmentRegion = es` y las claves del catálogo son las
cadenas en inglés. Un literal nuevo que se muestre al usuario y no esté en el
catálogo se queda en inglés sin que nada avise — es exactamente el bug que se
coló al traducir la app por primera vez.

Reglas:
  * Un literal que se pasa directamente como clave localizable
    (Text("..."), Label("..."), Button("..."), .navigationTitle("..."),
    placeholder:, .accessibilityLabel(...), .accessibilityValue(...))
    debe existir en el catálogo.
  * Un literal devuelto por una propiedad `String` (return "...") también,
    porque SwiftUI lo renderiza como verbatim y no lo localiza solo.

Uso:  python3 scripts/check_localization.py [--fix-list]
Sale con código 1 si encuentra cadenas sin traducir.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
APP = ROOT / "SafePlace"
CATALOG = APP / "Localizable.xcstrings"

# Marcas y tokens que se muestran igual en todos los idiomas.
ALLOWLIST = {"SafePlace", "LiveContainer"}

# Claves localizables directas: literal usado como LocalizedStringKey / String.
DIRECT = re.compile(
    r"(?:Text|Label|Button|Section|navigationTitle|navigationBarTitleDisplayMode|"
    r"accessibilityLabel|accessibilityValue|alert|confirmationDialog)\("
    r"\s*\"((?:[^\"\\]|\\.)*)\""
)
NAMED = re.compile(
    r"(?:placeholder|title|subtitle|label|text|message)\s*:\s*\"((?:[^\"\\]|\\.)*)\""
)
RETURNED = re.compile(r"return\s+\"((?:[^\"\\]|\\.)*)\"")

INTERPOLATION = "\\("


def load_keys() -> set[str]:
    data = json.loads(CATALOG.read_text(encoding="utf-8"))
    return set(data.get("strings", {}))


def wrapped(line: str, literal: str, start: int) -> bool:
    """¿El literal ya está envuelto en String(localized:)?"""
    return line[:start].rstrip().endswith('String(localized:')


def is_ui_copy(value: str) -> bool:
    if not value or INTERPOLATION in value:
        return False
    if value in ALLOWLIST:
        return False
    # Nombres de SF Symbols, ids, keys y hex de color no son texto de UI.
    if re.fullmatch(r"[a-z0-9_.\-/]+", value):
        return False
    if re.fullmatch(r"[0-9A-Fa-f]{6}", value):
        return False
    return bool(re.search(r"[A-Za-z]{2}", value))


def preview_lines(lines: list[str]) -> set[int]:
    """Índices (0-based) que pertenecen a bloques #Preview: son datos de ejemplo."""
    inside: set[int] = set()
    depth = 0
    active = False
    for index, line in enumerate(lines):
        if not active and line.lstrip().startswith("#Preview"):
            active, depth = True, 0
        if active:
            inside.add(index)
            depth += line.count("{") - line.count("}")
            if depth <= 0 and "{" in "".join(lines[max(0, index - 1): index + 1]):
                active = False
    return inside


def scan() -> list[tuple[str, int, str, str]]:
    keys = load_keys()
    problems: list[tuple[str, int, str, str]] = []
    for path in sorted(APP.rglob("*.swift")):
        lines = path.read_text(encoding="utf-8").splitlines()
        skip = preview_lines(lines)
        # Los títulos de datos (semilla, ejemplos) viven fuera de Views.
        in_views = "Views" in path.parts or path.name == "ContentView.swift"
        rules = ((DIRECT, "literal"), (RETURNED, "return"))
        if in_views:
            rules = rules + ((NAMED, "named"),)
        for index, line in enumerate(lines):
            lineno = index + 1
            if index in skip or line.lstrip().startswith("//"):
                continue
            for pattern, rule in rules:
                for match in pattern.finditer(line):
                    value = match.group(1)
                    if not is_ui_copy(value) or value in keys:
                        continue
                    if wrapped(line, value, match.start(1) - 1):
                        continue
                    problems.append((str(path.relative_to(ROOT)), lineno, value, rule))
    return problems


def main() -> int:
    problems = scan()
    if not problems:
        print("✓ Toda la copia de UI está en Localizable.xcstrings")
        return 0
    print(f"✗ {len(problems)} cadena(s) de UI sin entrada en el catálogo:\n")
    for path, lineno, value, rule in problems:
        print(f"  {path}:{lineno}  [{rule}]  {value!r}")
    print(
        "\nAgrega la clave a SafePlace/Localizable.xcstrings (con su valor en es) "
        "o envuélvela en String(localized:) si viene de una variable."
    )
    return 1


if __name__ == "__main__":
    sys.exit(main())
