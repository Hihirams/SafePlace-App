---
name: safeplace-motion
description: >-
  Contrato de movimiento de SafePlace. Úsala antes de añadir, cambiar o revisar
  cualquier animación de la app (SwiftUI) o de un prototipo en FigCraft: entrada
  de pantalla, feedback al tocar, loops ambientales, transiciones entre estados,
  splash. Fija los springs aprobados, la coreografía, el comportamiento con
  Reduce Motion y el checklist que se corre antes de dar un motion por bueno.
---

# SafePlace motion

El movimiento es parte del contrato de diseño. Si un valor no está aquí, no
existe: se propone, se aprueba en FigCraft y se añade a esta tabla.

## Los tres springs

Estos números son los del código (`SafeDesign.spring*`), expresados como los
toma FigCraft. No se inventan otros.

| Token | Swift | FigCraft `customSpring` | Duración |
| --- | --- | --- | --- |
| `gentle` | `.spring(response: 0.35, dampingFraction: 0.78)` | `{mass: 1, stiffness: 322, damping: 28}` | 350 ms |
| `quick` | `.spring(response: 0.28, dampingFraction: 0.82)` | `{mass: 1, stiffness: 503, damping: 37}` | 280 ms |
| `bouncy` | `.spring(response: 0.42, dampingFraction: 0.68)` | `{mass: 1, stiffness: 224, damping: 20}` | 420 ms |

Los loops ambientales **no** usan spring: usan `easeInOut` con autoreverse,
porque un spring en bucle se lee como temblor nervioso.

| Loop | Curva | Periodo | Amplitud |
| --- | --- | --- | --- |
| Llama de racha | `easeInOut` | 1.15 s | escala 0.92↔1.08 anclada abajo, offset y ±0.5, opacidad 0.86↔1 |
| Mascota · flotar | `easeInOut` | 4.2 s | offset y ±6 |
| Mascota · respirar | `easeInOut` | 3.4 s | escala x 0.99↔1.03, y 1.02↔0.98, anclada abajo |
| Splash · tecleo | `easeOut` 0.18 por letra | 1.45 s las 8 letras | letra a letra |
| Splash · tinte | `easeOut` 0.6 | una vez | opacidad 0→1 |
| Splash · salida | `easeInOut` 0.55 | una vez | cross-fade al Home |

## Coreografía

- **Máximo 2–3 movimientos intencionados por pantalla.** Lo que no aclara un
  cambio de estado, fuera.
- **Entrada al Home:** cascada de 4 bloques (cabecera+mascota+prompt → moods y
  racha → stats → recientes), 40 ms de separación, cada bloque con `gentle` y
  opacidad 0→1. Nunca se repite en la misma sesión.
- **Feedback al tocar:** `quick`. Un toque no se contesta con `bouncy`.
- **Cambio de estado con significado** (check-in de mood, selección de tab):
  `bouncy` si es un momento emocional, `quick` si es navegación.
- **Salidas más cortas que las entradas:** la mitad de duración.
- **Un solo elemento con protagonismo.** La llama y la mascota son ambiente:
  nunca compiten con la interacción principal.
- **Nada de movimiento en interacciones de alta frecuencia** (scroll, tecleo,
  hover): respuesta instantánea.

## Reduce Motion (no negociable)

Cada movimiento tiene su variante estática y se elige con
`@Environment(\.accessibilityReduceMotion)`:

| Movimiento | Con Reduce Motion |
| --- | --- |
| Cascada de entrada | los bloques aparecen, sin desplazamiento ni stagger |
| Llama | queda en la pose de reposo, sin bucle |
| Mascota | queda quieta |
| Splash | wordmark completo desde el primer frame, sin tecleo |
| Cambio de mood/tab | cross-fade de opacidad, sin escala |

El movimiento nunca es el único canal: todo cambio de estado deja una señal
estática (color, icono o texto).

## Cómo se aprueba

1. El movimiento se dibuja en FigCraft (`design/SafePlace-Motion.figcraft`) con
   los valores de las tablas de arriba, no con valores "parecidos".
2. Se revisa en `proto.preview` dentro de la app, en el flujo que corresponda.
3. Solo después se toca Swift: `SafeMotion` en `SafePlace/DesignSystem.swift` es
   la única fuente de duraciones y curvas. Las vistas leen tokens, no números.
4. `python scripts/check_design.py` debe pasar.

## Checklist antes de decir "listo"

- [ ] El valor existe en la tabla; si es nuevo, se aprobó en FigCraft y se añadió.
- [ ] La vista lee un token de `SafeMotion`, no una duración literal.
- [ ] Hay rama de Reduce Motion y termina en un estado legible.
- [ ] El cambio de estado tiene señal no animada.
- [ ] La animación no se dispara más de una vez por sesión si es de entrada.
- [ ] Se probó en modo oscuro y a tamaño de texto AX5.
- [ ] El prototipo de FigCraft y el código usan el mismo número.
