# design/

Fuente de verdad visual de SafePlace. El movimiento se aprueba aquí antes de
tocar SwiftUI.

## Archivos

| Archivo | Qué es |
| --- | --- |
| `SafePlace-Motion.figcraft` | Documento FigCraft con los estados de Home, el set de iconos y los especímenes de movimiento |
| `build-motion.mjs` | Generador. Reconstruye el `.figcraft` entero desde cero (840 comandos) |

El `.figcraft` se puede editar a mano en FigCraft, pero entonces el generador
queda desfasado: si cambias algo importante, refléjalo también en el script o
regenera y vuelve a aplicar el cambio.

## Regenerar

```bash
node design/build-motion.mjs
```

Si FigCraft tiene el archivo abierto, el programa avisa de que cambió en disco:
`File › Revert to saved` para recargar, o `Save as` para conservar tu versión.

## Flujos del prototipo

| Flujo | Qué muestra |
| --- | --- |
| **Arranque** | Tinte del splash → tecleo del wordmark → cascada de entrada → Home |
| **Entrada** | Solo la cascada de entrada (4 bloques, 40 ms de stagger) |
| **Home** | Estado en reposo; toca *Calma* para el check-in, Journal en la tab bar para el cambio de icono |
| **Racha** | Loop de la llama: `easeInOut` 1.15 s, escala 0.92↔1.08 anclada abajo, opacidad 0.86↔1 |
| **Mascota** | Flotación 4.2 s y respiración 3.4 s |

Los loops van en frames aparte a propósito: si el Home estuviera navegando cada
1.15 s no se podría tocar nada.

## Páginas

- **Motion** — estados de Home, splash, racha, mascota.
- **Iconos** — set completo en reposo/activo a 20·22·34, y la tabla de springs.
- **Reduce Motion** — qué se apaga y qué queda en su lugar.

## Reglas

Las de `.opencode/skills/safeplace-motion/SKILL.md`: springs `gentle`/`quick`/
`bouncy`, máximo 2–3 movimientos por pantalla, y cada loop con su variante
estática. Un valor nuevo se propone aquí, se aprueba, y entonces se añade al
token en `SafePlace/Motion.swift`.

Las rarezas del motor (ids secuenciales, `absolute` dentro de auto layout, alpha
por hex de 8 dígitos, codificación del script) están en
`.opencode/skills/figcraft/SKILL.md`.
