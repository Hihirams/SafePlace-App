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

Tamaños custom: `SafeDesign.scaled(...)` escala contra el estilo de texto que le corresponde (caption2 / footnote / subheadline / body). Para arte decorativo dentro de un círculo fijo (llamas, iconos de botón) existe `SafeDesign.scaled(..., cappedAt:)`, que se detiene antes de desbordar el contenedor.

**Regla:** no usar `.system(size:)` para texto de contenido; reservarlo para decorativos (cifras, iconos, badges) dentro de contenedores flexibles.

## Espaciado y radios
Escala en múltiplos de 4: `xxs 4 · xs 8 · s 12 · m 16 · l 20 · xl 24 · xxl 32 · xxxl 48`.
Radios: `radiusXS 6 · radiusS 8 · radiusM 12 · radiusL 16 · radiusXL 24 · radiusPill 100`. Preferir hairlines sobre bordes.

## Motion

La fuente de verdad es `SafeMotion` en `DesignSystem.swift`; `SafeDesign.spring`,
`springSnappy` y `springBouncy` son alias que se conservan por compatibilidad.

| Token | Valor | Uso |
| --- | --- | --- |
| `gentle` | spring 0.35 / 0.78 | entrada de pantalla, aparición de una sección |
| `quick` | spring 0.28 / 0.82 | respuesta a un toque, cambio de icono |
| `bouncy` | spring 0.42 / 0.68 | momento emocional (check-in de mood) |
| `selector` | interactiveSpring 0.26 / 0.74 | selector de la tab bar |
| `flame` | easeInOut 1.15 s en bucle | llama de la racha |
| `float` / `breathe` | easeInOut 4.2 s / 3.4 s | personaje |
| `splashTintIn`, `splashType`, `dismiss` | easeOut 0.6 / 0.18, easeInOut 0.4 | splash y salidas |

**Entrada de pantalla:** cuatro bloques (cabecera + personaje, prompt + moods,
stats, recientes) separados 40 ms, cada uno sube 12 pt y aparece con `gentle`.
Se dispara cuando el splash o el onboarding dejan de tapar la app, una sola vez.

Todo movimiento ambiental (personaje, llama, grafo) se detiene con **Reduce
Motion**, y con Reduce Motion la cascada no escalona ni desplaza: los bloques
aparecen ya colocados. Ninguna vista escribe una duración literal.

**Detalle de la racha:** la tarjeta entra con `bouncy` (escala 0.94→1 y
opacidad) y sale con `quick`; con Reduce Motion aparece sin escala. La llama
reutiliza `flame`, así que no hay tokens nuevos.

El prototipo aprobado vive en `design/SafePlace-Motion.figcraft`; el contrato
completo, en `.opencode/skills/safeplace-motion/SKILL.md`.

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
`PrimaryButton` / `SecondaryButton`, `ClayTextField` / `ClayTextArea` / `ClaySearchBar`, `SelectionPill`, `BadgePill`, `GlassIconButton`, `Hairline`, `SectionHeader`, `BrandMark`, `ClayCard`, `EditorialNoteRow`, `EntryCardView`, `MascotView`, `ProfileAvatar`, `GlassTabBar`, `SheetHeader`, `FlowLayout`, `SettingsCard`, `StreakFlameGlyph`, `StreakView`.

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
