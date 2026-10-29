#!/usr/bin/env python3
"""Guard de diseño para la app iOS.

Convierte en fallo de CI tres reglas que ya costaron trabajo real:

1. Tamaños de fuente fijos (`.system(size:)`) fuera del design system: no escalan
   con Dynamic Type, así que quien sube el tamaño de texto no ve cambios.
2. `accessibilityElement(children: .combine)` sin `.accessibilityAction` en el
   mismo archivo: combinar hijos borra los botones del árbol de VoiceOver (así
   desapareció el menú de las tarjetas).
3. Copy genérica de la lista negra del contrato ("Get started", "Elevate", ...).

Uso: python3 scripts/check_design.py
Sale con 1 si encuentra violaciones.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
APP = ROOT / "SafePlace"

FIXED_FONT = re.compile(r"\.system\(size:")
ALLOWED_FIXED_FONT = {"DesignSystem.swift"}          # el helper escalable vive aquí
COMBINE = re.compile(r"accessibilityElement\(children:\s*\.combine\)")
ACTION = re.compile(r"accessibilityAction\(")
BANNED_COPY = re.compile(r'"(Get started|Elevate|Seamless|Unlock|Supercharge)"')


def rel(path: Path) -> str:
    return str(path.relative_to(ROOT))


def main() -> int:
    problems: list[str] = []

    for path in sorted(APP.rglob("*.swift")):
        text = path.read_text(encoding="utf-8", errors="ignore")
        lines = text.splitlines()

        for number, line in enumerate(lines, 1):
            stripped = line.lstrip()
            if stripped.startswith("//"):
                continue
            if FIXED_FONT.search(line) and path.name not in ALLOWED_FIXED_FONT:
                problems.append(
                    f"{rel(path)}:{number} tamaño de fuente fijo — usa SafeDesign.scaled(...)"
                )
            banned = BANNED_COPY.search(line)
            if banned:
                problems.append(
                    f"{rel(path)}:{number} copy genérica {banned.group(0)} — escribe en lenguaje de producto"
                )

        if COMBINE.search(text) and not ACTION.search(text):
            problems.append(
                f"{rel(path)} combina hijos para VoiceOver sin "
                f".accessibilityAction: los botones internos desaparecen del árbol"
            )

    if not problems:
        print("✓ Diseño: sin tamaños fijos, sin controles ocultos y sin copy genérica")
        return 0

    print(f"✗ {len(problems)} problema(s) de diseño:\n")
    for problem in problems:
        print("  " + problem)
    print("\nVer .opencode/skills/safeplace-design/SKILL.md")
    return 1


if __name__ == "__main__":
    sys.exit(main())
