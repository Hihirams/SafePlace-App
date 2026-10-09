# Diseño — SafePlace

Guía viva del sistema de diseño. Todo lo que se construya en la app debería respetar estas reglas.

## Principios

1. **Blanco y sobrio primero.** El color es un acento, no el fondo. La app se ve limpia; la paleta aparece en detalles.
2. **El color sigue al estado.** El acento se deriva del estado emocional (mood dominante) y tiñe solo acentos: botones, selector de pestaña, personaje, gráficas y un glow de fondo muy leve.
3. **Baja fricción.** Registrar un momento debe tomar segundos. Nada de campos obligatorios que estorben.
4. **Sin culpa.** Rachas "personal-best", nunca castigos ni rojos de alarma.
5. **Accesible por defecto.** Dynamic Type, contraste AA, objetivos táctiles de 44pt y Reduce Motion se tratan como requisitos, no extras.

## Tokens (`DesignSystem.swift`)

### Superficies (adaptativas)
| Token | Light | Dark | Uso |
|---|---|---|---|
| `canvas` | `#FCFBFA` | `#000000` | Fondo |
| `surfaceSoft` | `#F6F4F2` | `#141414` | Agrupación sutil |
| `surfaceCard` | `#FFFFFF` | `#0E0E0E` | Tarjetas |
| `surfaceStrong` | `#EFEBE7` | `#1C1C1C` | Presionado / elevado |
| `hairline` | ink 9% | white 12% | Bordes finos |

### Tinta
| Token | Light | Dark |
|---|---|---|
| `ink` | `#2B2320` | `#F5F0EC` |
| `inkSecondary` | `#6B5E57` | `#B8AFA8` |
| `muted` | ink 66% | white 55% |

### Acento dinámico (`AppTheme`)
- `appTheme.tint` = color del mood dominante.
- `appTheme.tintStrong` = variante profunda para botones/links.
- Se inyecta en `RootView` con `.environment(\.appTheme, AppTheme(moodState:))`.

### Paleta base
powder-blush `#FEC5BB`, almond-silk `#FCD5CE`, soft-blush `#FAE1DD`, seashell `#F8EDEB`, alabaster `#E8E8E4`, alabaster-2 `#D8E2DC`, linen `#ECE4DB`, powder-petal `#FFE5D9`, peach-fuzz `#FFD7BA`, peach-glow `#FEC89A`.

### Tarjetas de nota (`CardColor`)
Vivos y distintos: pink, teal, lavender, peach, ochre, mint, coral, cream. El texto usa `foreground`/`accent` elegidos para contraste AA (teal → blanco; el resto → ink).

### Moods (`Mood`)
bright (peach), calm (sage), hopeful (blush), mixed (peach-fuzz), heavy (azul triste `#A9BCD0`). Cada uno con `valence` (−1…+1) y `energy` (0…1).

## Tipografía

Fuentes **semánticas** (escalan con Dynamic Type): `heroFont`, `displayFont`, `largeTitle`, `title`, `headline`, `body`, `caption`, `micro`, `tabLabel`. No usar `.system(size:)` para texto de contenido; reservarlo para decorativos (cifras, iconos, badges) dentro de contenedores flexibles.

Wordmark "SafePlace": serif del sistema.

## Espaciado y radios
Escala en múltiplos de 4: `xxs 4 · xs 8 · s 12 · m 16 · l 20 · xl 24 · xxl 32 · xxxl 48`.
Radios: `XS 6 · S 8 · M 12 · L 16 · XL 24 · pill 100`.

## Motion
`spring`, `springSnappy`, `springBouncy`, `easeOut`. Todo movimiento ambiental (personaje, grafo) debe respetar **Reduce Motion**.

## Layout adaptativo
- `pageColumn` limita el ancho de lectura (720) y aplica insets por tamaño de clase.
- `AdaptiveStack` pliega filas horizontales a verticales en tallas de accesibilidad (`dynamicTypeSize.isAccessibilitySize`).
- `FlowLayout` para tags que envuelven.
- Preferir `ViewThatFits`/`AnyLayout` antes que `GeometryReader`.
- Barras fijas (navbar) acotan su Dynamic Type y usan `minTouchTarget`.

## Reglas
- **Objetivos táctiles** ≥ 44×44 (`minTouchTarget`).
- **Contraste**: texto ≥ 4.5:1 (3:1 en texto grande); controles/bordes ≥ 3:1.
- **Nunca** comunicar estado solo con color: acompañar con forma/etiqueta.
- **Alturas flexibles**: `minHeight`, no `height`, en contenedores con texto.
- Iconos decorativos: `accessibilityHidden(true)`. Botones de icono: `accessibilityLabel` + `accessibilityIdentifier`.
- Pestañas: son destinos; el botón central Create es una acción.

## Componentes
`PrimaryButton`/`SecondaryButton`, `ClayTextField`/`ClayTextArea`/`ClaySearchBar`, `SelectionPill`, `BadgePill`, `GlassIconButton`, `Hairline`, `SectionHeader`, `ClayCard`, `EntryCardView`, `MascotView`, `GlassTabBar`.
