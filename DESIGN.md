# Diseño — SafePlace

Guía viva del sistema de diseño. Todo lo que se construya en la app debería respetar estas reglas. El sistema vive en `SafePlace/DesignSystem.swift` (`SafeDesign` para tokens, `SafeLayout` para layout adaptativo).

## Tesis visual

**Warm editorial paper.** La app debe sentirse como un cuaderno bien hecho: papel blanco cálido, tipografía de tinta, un serif de display para los títulos, un único acento teñido por el estado de ánimo usado con intención, y contenido expresado como secciones y listas separadas por hairlines — no una cuadrícula de tarjetas genéricas redondeadas. Calmo, táctil, pausado, personal.

Por pantalla: una idea, un elemento dominante, copy escaso. En interacción: como máximo 2–3 movimientos con propósito (entrada escalonada, transición de selección, un loop ambiental), todos respetando Reduce Motion.

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
| `canvas` | `#FAF8F4` | `#000000` | Fondo |
| `surfaceSoft` | `#F3EFE8` | `#141414` | Agrupación sutil (campos) |
| `surfaceCard` | `#FFFFFF` | `#0E0E0E` | Tarjetas / superficies |
| `surfaceStrong` | `#ECE7DF` | `#1C1C1C` | Presionado / elevado |
| `hairline` | ink 10% | white 12% | Bordes finos y separadores |

### Tinta
| Token | Light | Dark |
|---|---|---|
| `ink` | `#2A2622` | `#F3EEE7` |
| `inkSecondary` | `#6B625A` | `#B8AFA6` |
| `muted` | ink 66% | white 55% |

### Acento dinámico (`AppTheme`)
- `appTheme.tint` = color del mood dominante.
- `appTheme.tintStrong` = variante profunda para botones/links.
- Se inyecta en `RootView` con `.environment(\.appTheme, AppTheme(moodState:))`. Sin mood, cae a `AppTheme.standard` (peach glow).
- **Nunca** introducir un segundo acento decorativo.

### Paleta base
powder-blush `#FEC5BB`, almond-silk `#FCD5CE`, soft-blush `#FAE1DD`, seashell `#F8EDEB`, alabaster `#E8E8E4`, alabaster-2 `#D8E2DC`, linen `#ECE4DB`, powder-petal `#FFE5D9`, peach-fuzz `#FFD7BA`, peach-glow `#FEC89A`.

### Tarjetas de nota (`CardColor`)
Vivos y distintos: pink, teal, lavender, peach, ochre, mint, coral, cream. El texto usa `foreground`/`accent` elegidos para contraste AA (teal → blanco; el resto → ink).

### Moods (`Mood`)
bright (peach `#FEC89A`), calm (sage `#D8E2DC`), hopeful (blush `#FEC5BB`), mixed (peach-fuzz `#FFD7BA`), heavy (azul triste `#A9BCD0`). Cada uno con `valence` (−1…+1) que tiñe la app y `energy` (0…1) que alimenta el movimiento del grafo Mind.

## Tipografía

Fuentes **semánticas** (escalan con Dynamic Type). Los títulos usan el serif del sistema; el cuerpo y la UI, SF.

| Token | Estilo | Uso |
|---|---|---|
| `serifHero` | serif `.largeTitle` semibold | Título héroe |
| `serifTitle` | serif `.title2` semibold | Wordmark, títulos de sección |
| `serifHead` | serif `.title3` semibold | Título de nota |
| `heroFont` / `displayFont` | serif `.title` semibold | Display |
| `largeTitle` | serif `.title2` semibold | Títulos de sheet |
| `title` | SF `.title3` bold | Título de UI |
| `headline` | SF `.headline` | Encabezados, botones |
| `body` | SF `.subheadline` medium | Texto de contenido |
| `caption` | SF `.footnote` medium | Secundario |
| `micro` | SF `.caption2` medium | Metadatos |
| `tabLabel` | SF `.caption2` semibold | Etiquetas del navbar |

Wordmark "SafePlace": serif del sistema.

**Regla:** no usar `.system(size:)` para texto de contenido; reservarlo para decorativos (cifras, iconos, badges) dentro de contenedores flexibles.

## Espaciado y radios
Escala en múltiplos de 4: `xxs 4 · xs 8 · s 12 · m 16 · l 20 · xl 24 · xxl 32 · xxxl 48`.
Radios: `radiusXS 6 · radiusS 8 · radiusM 12 · radiusL 16 · radiusXL 24 · radiusPill 100`. Preferir hairlines sobre bordes.

## Motion
`spring`, `springSnappy`, `springBouncy`, `easeOut`. Todo movimiento ambiental (personaje, grafo) debe respetar **Reduce Motion**; los loops ambientales se detienen cuando está activo.

## Layout adaptativo
- `pageColumn` limita el ancho de lectura (720) y aplica insets por tamaño de clase.
- `AdaptiveStack` pliega filas horizontales a verticales en tallas de accesibilidad (`dynamicTypeSize.isAccessibilitySize`).
- `FlowLayout` (en `InsightsView`) para tags que envuelven.
- Preferir `ViewThatFits`/`AnyLayout` antes que `GeometryReader`.
- Barras fijas (navbar) acotan su Dynamic Type y usan `minTouchTarget`.
- `readingWidth` captura el ancho disponible para grids adaptativos.

## Motivos de marca
- **Asterisco / starburst** fino (`BrandMark`) como glifo recurrente.
- **Jerarquía de fecha**: numeral serif grande sobre etiqueta sans pequeña.
- **Filas de dos polos**: una acción secundaria de texto alineada a la derecha, opuesta a su etiqueta.
- **Grano de papel** sutil (opacidad muy baja) para atmósfera — nunca un degradado fuerte.

## Liquid glass (`LiquidGlass.swift`)
- `glassCapsule()` — superficie de la barra de pestañas (no interactiva).
- `selectorGlass()` — la lente de selección que sigue el dedo (no interactiva, para que no se deforme).
- `glassPill()` — pastilla para controles pequeños (interactiva en iOS 26).
- `liquidGlass()` — superficie redondeada translúcida (usada con moderación).
- En iOS 26 usa Liquid Glass nativo (`glassEffect`); antes, `.ultraThinMaterial` con borde especular.

## Componentes
`PrimaryButton` / `SecondaryButton`, `ClayTextField` / `ClayTextArea` / `ClaySearchBar`, `SelectionPill`, `BadgePill`, `GlassIconButton`, `Hairline`, `SectionHeader`, `BrandMark`, `ClayCard`, `EditorialNoteRow`, `EntryCardView`, `MascotView`, `ProfileAvatar`, `GlassTabBar`, `SheetHeader`, `FlowLayout`, `SettingsCard`.

## Reglas
- **Objetivos táctiles** ≥ 44×44 (`minTouchTarget`).
- **Contraste**: texto ≥ 4.5:1 (3:1 en texto grande); controles/bordes ≥ 3:1.
- **Nunca** comunicar estado solo con color: acompañar con forma/etiqueta.
- **Alturas flexibles**: `minHeight`, no `height`, en contenedores con texto.
- Iconos decorativos: `accessibilityHidden(true)`. Botones de icono: `accessibilityLabel` + `accessibilityIdentifier`.
- Pestañas: son destinos; el botón central Create es una acción.

## Evitar (anti-slop)
- Tipografías genéricas para display; degradados púrpura/índigo sobre blanco; hero centrado + tres feature cards.
- `rounded + shadow` en cada superficie; glassmorphism reflexivo; icono-en-cuadrado-redondeado.
- Tarjetas anidadas; sopa de pills; tiras de estadísticas; emoji como bullets.
- Símbolos SF usados como única forma de comunicar significado.
- Copy genérico ("Elevate…", "Get started"); escribir en el lenguaje del producto.

## Litmus checks
- ¿La pantalla es inconfundiblemente SafePlace (y no una plantilla)?
- ¿Hay un elemento dominante claro y jerarquía por tipo/espacio?
- ¿Alguna sombra o borde podría quitarse sin dañar la interacción?
- ¿Se sostiene en tamaño AX5, dark mode y Reduce Motion?
