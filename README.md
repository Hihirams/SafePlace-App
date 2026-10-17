# SafePlace App

App de iPhone para guardar las pequeñas cosas que te ayudan: hábitos, personas, lugares, música y autocuidado. SwiftUI puro (iOS 17+), con una dirección de arte **warm editorial paper**: papel blanco cálido, títulos en serif, un único acento que se deriva de tu estado de ánimo y el contenido estructurado en secciones y listas con hairlines — no en una cuadrícula de tarjetas.

## Características

- **Home** sobria: header fijo con avatar + wordmark + buscador; personaje que toma el color de tu estado de ánimo; check-in de mood; "On this day"; segmentado **Overview / Insights**.
- **Create** (centro de la navbar): editor a pantalla completa sin campos encajonados, con auto-categoría y color derivado del mood.
- **Notas con color de tarjeta** (paleta viva) con estado de ánimo, categoría y color seleccionables.
- **Journal** — línea de tiempo agrupada por día, con búsqueda y filtro por mood.
- **Saved** — enlaces, citas y recordatorios.
- **Búsqueda** — por palabra exacta, keyword, similitud difusa o emoción, con preview y términos resaltados.
- **Insights** (Swift Charts) — notas por día, distribución por mood/categoría, palabras frecuentes y mejor racha. Observacional, sin culpa.
- **Mind** — grafo tipo Obsidian: una red viva de tus notas agrupadas por categoría. Los nodos se mueven, cambian de color y de tamaño; la energía del movimiento reacciona a cuántas notas tienes y a qué tan feliz te sientes.
- **Compatibilidad con NOTAS de iPhone** — extensión de compartir (Share Extension): comparte texto desde la app Notas de Apple (o cualquier app) directo a SafePlace.
- **Barra de navegación liquid glass** flotante con 4 destinos y botón central **Create**, y un selector que sigue tu dedo.
- **Responsive**: iPhone pequeños y grandes, rotación horizontal/vertical, iPad (grids de 3-4 columnas y ancho de lectura acotado) y Dynamic Type.
- Onboarding de primera vez con splash animado.
- Tema claro/oscuro/sistema.

## Diseño

- **Base sobria**: papel blanco cálido (`#FAF8F4`) en claro y negro puro (`#000`) en oscuro; el color es acento, no fondo.
- **Acento dinámico**: se deriva del estado emocional (mood dominante) y tiñe acciones, el personaje, las gráficas y un glow de fondo muy leve.
- **Tipografía**: títulos en **serif del sistema**; cuerpo y UI en **SF**; fuentes semánticas que escalan con Dynamic Type.
- **Layout editorial**: secciones y listas separadas por hairlines. Las tarjetas se reservan para interacciones (una nota que tocas), nunca anidadas.
- **Liquid glass**: barra de pestañas flotante con `.ultraThinMaterial` (y Liquid Glass nativo en iOS 26) y bordes translúcidos.
- **Mascota**: un personaje "dumpling" sin cara que flota y respira, teñido por tu estado de ánimo.
- Reglas completas de tokens, tipografía y componentes en [`DESIGN.md`](DESIGN.md).

## Pantallas

- **Home** (`DashboardView`) — header fijo (avatar → Ajustes, wordmark, buscador), mascota, check-in de mood, "On this day", segmentado Overview/Insights, estadísticas (cosas guardadas, categorías, barras por categoría, sentimientos) y notas recientes en filas editoriales.
- **Create** (`CreateView`) — lienzo en blanco para crear o editar una nota; sugiere categoría según el contenido y deriva el color del mood.
- **Quick capture** (`QuickCaptureView`) — captura exprés de un momento en segundos.
- **Journal** (`JournalView`) — línea de tiempo por día (secciones colapsables), búsqueda y filtro por mood.
- **Saved** (`ResourcesView`) — enlaces, citas y recordatorios; copiar, compartir, convertir en nota o borrar.
- **Notes** (`NotesView`) — notas compartidas desde Apple Notes: leer, "Keep it" (guardar) o descartar.
- **Search** (`SearchView`) — motor `SearchRanker`: coincidencia exacta, keywords, similitud difusa y emoción ("me siento triste"), con snippet y resaltado.
- **Insights** (`InsightsView`) — Swift Charts (últimos 14 días, distribución por mood) y nube de palabras frecuentes.
- **Mind** (`MindView`) — grafo interactivo (ver abajo).
- **Settings** (`SettingsView`) — foto de perfil, tema, mascota, shared notes, recordatorio diario, export/import JSON, borrar datos, versión y feed de actualización.
- **Onboarding** (`OnboardingView`) — 3 páginas la primera vez.

## Versión y releases

- **Esquema**: la versión se calcula en CI como `1.<run_number>` y el build es `<run_number>` (el número de ejecución de GitHub Actions). Es monótono creciente, así que LiveContainer/AltStore detectan correctamente cada update.
- **Versión actual: `1.23` (build 23)** — último release publicado (tag `build-23`).
- **Fuente de la verdad**: el `run_number` del workflow. Los valores en `SafePlace.xcodeproj` (`MARKETING_VERSION` / `CURRENT_PROJECT_VERSION`) y en `docs/source.json` son la **línea base / última publicada** y se sobrescriben en cada build de CI.
- **Cómo se publica**: push a `main` (o **Run workflow**) → job de tests → archive sin firma → GitHub Release `build-<n>` → regenera `docs/source.json` (AltSource) → deploy a GitHub Pages.
- Los cambios notables se registran en [`CHANGELOG.md`](CHANGELOG.md).

## Estructura

```
SafePlace-App/
├── SafePlace.xcodeproj/
├── SafePlace/
│   ├── App.swift                      # Entry point
│   ├── ContentView.swift              # Root + shell de pestañas + GlassTabBar + splash
│   ├── DesignSystem.swift             # Tokens (SafeDesign) + layout adaptativo (SafeLayout)
│   ├── LiquidGlass.swift              # Modificadores liquid glass
│   ├── BackgroundOrbs.swift           # Lienzo + glow del tinte emocional
│   ├── SymbolEffects.swift            # Haptics, tema de interfaz, símbolos, botón "pressable"
│   ├── Extensions/
│   │   └── ColorExtension.swift       # Color(hex:), blended(with:)
│   ├── Models/
│   │   ├── Entry.swift                # Nota (título, descripción, categoría, mood, color)
│   │   ├── Mood.swift                 # Estados de ánimo (valence + energy)
│   │   ├── MoodState.swift            # Mood dominante derivado + AppTheme
│   │   ├── CardColor.swift            # Colores de tarjeta
│   │   ├── Resource.swift             # Recurso (link / cita)
│   │   ├── MindGraph.swift            # Hubs, nodos y aristas del grafo
│   │   └── NoteStats.swift            # Agregaciones puras (Home / Insights)
│   ├── Services/
│   │   ├── Store.swift                # Persistencia + notas compartidas (app group)
│   │   ├── Categorizer.swift          # Auto-categoría
│   │   ├── MindSimulation.swift       # Física force-directed del grafo
│   │   └── Reminders.swift            # Recordatorio diario
│   └── Views/
│       ├── DashboardView.swift        # Home
│       ├── CreateView.swift           # Editor de nota (lienzo en blanco)
│       ├── JournalView.swift          # Línea de tiempo
│       ├── ResourcesView.swift        # Saved (enlaces y recordatorios)
│       ├── NotesView.swift            # Notas compartidas desde el iPhone
│       ├── MindView.swift             # Grafo interactivo
│       ├── InsightsView.swift         # Swift Charts + FlowLayout
│       ├── SearchView.swift           # Búsqueda + SearchRanker
│       ├── SettingsView.swift         # Ajustes (versión, tema, datos, …)
│       ├── OnboardingView.swift       # Onboarding de 3 páginas
│       ├── QuickCaptureView.swift     # Captura rápida
│       ├── MascotView.swift           # Personaje "dumpling"
│       ├── EntryCardView.swift        # Tarjeta de nota (clásica)
│       ├── EntryFormView.swift        # Formulario clásico de alta/edición
│       ├── GlassCard.swift            # Hairline, SectionHeader, BrandMark, EditorialNoteRow,
│       │                              #   ClayCard, BadgePill, GlassIconButton, ProfileAvatar
│       └── FormComponents.swift       # Botones, campos, pills, SheetHeader
├── SafePlaceShare/
│   ├── ShareViewController.swift      # Extensión de compartir (Notas → SafePlace)
│   ├── Info.plist
│   └── SafePlaceShare.entitlements
├── SafePlaceTests/
│   └── LogicTests.swift               # Swift Testing (Categorizer, MindGraph, Store, SearchRanker, …)
├── SafePlaceUITests/
│   └── SmokeUITests.swift             # XCTest (arranque a Home + navbar alcanzable)
├── docs/                              # GitHub Pages (feed AltSource)
│   ├── source.json
│   └── icon.png
├── .github/workflows/
│   ├── build-ios.yml                  # test → build → Release → AltSource → Pages
│   └── build-check.yml                # build check en cada rama
├── DESIGN.md · QA.md · CHANGELOG.md
└── README.md
```

## Build

### Requisitos
- macOS con Xcode 15+
- Cuenta de Apple Developer (para firma)
- O usar GitHub Actions para build sin firma

### GitHub Actions

El workflow `.github/workflows/build-ios.yml` corre tests y luego compila y publica el IPA sin firma automáticamente. Se dispara en **cada push a `main`** (o manualmente con **Run workflow**). En cada build:

1. Corre los tests (`xcodebuild test`); si fallan, el release se cancela.
2. Compila el archive (`CODE_SIGNING_ALLOWED=NO`) con versión `1.<run_number>` / build `<run_number>`.
3. Publica el IPA como **GitHub Release** (tag `build-<run_number>`) con URL estable y pública.
4. Regenera `docs/source.json` (formato **AltSource**) apuntando a ese Release.
5. Despliega `docs/` a **GitHub Pages**.

> **Prerrequisito:** el repositorio debe ser **público** (los assets de Release y GitHub Pages no son alcanzables por LiveContainer sin token). Pages se habilita automáticamente en el primer run; si falla, actívalo en *Settings → Pages → Build and deployment → Source: GitHub Actions*.

### Instalación / updates en LiveContainer

El feed AltSource queda en:

```
https://hihirams.github.io/SafePlace-App/source.json
```

Para agregarlo en el iPhone (una sola vez), abre este enlace en Safari/Notas:

```
livecontainer://sources?url=https://hihirams.github.io/SafePlace-App/source.json
```

LiveContainer consulta el feed y, cuando un nuevo push a `main` genera un release, el botón de la app muestra **Update**; un toque descarga e instala la versión nueva (conservando tus datos). También puedes instalar/actualizar de forma puntual con:

```
livecontainer://install?url=https://github.com/Hihirams/SafePlace-App/releases/latest/download/SafePlace.ipa
```

AltStore/SideStore y otras herramientas compatibles con AltSource también pueden consumir el mismo feed. La instalación no puede ser silenciosa en segundo plano: iOS requiere confirmación.

## NOTAS (Apple Notes) — cómo funciona

La app Notas de Apple no expone una API pública para leer notas de terceros, así que la integración se hace con la **hoja de compartir de iOS**:

1. Abre una nota en la app **Notas**
2. Toca el botón **Compartir** (cuadrado con flecha hacia arriba)
3. Elige **SafePlace**
4. La nota llega a la pestaña **Notes** de la app, donde puedes leerla y decidir "Keep it" (guardarla en tu safe place) o descartarla

> Nota: para que la extensión funcione en un dispositivo real se necesita una build firmada con tu cuenta de Apple Developer (las builds sin firma vía Actions, instaladas con LiveContainer/AltStore, no activan app groups).

## Mind (grafo de pensamientos)

La pestaña **Mind** dibuja tus notas como una red viva:

- **Agrupación**: cada categoría es un *hub* y sus notas orbitan alrededor. El grafo se renderiza con `Canvas` + `TimelineView` sobre la física de `MindSimulation`.
- **Color**: modo **Wave** (el mood dominante "contagia" el color) o **Category** (color por categoría).
- **Tamaño**: los nodos crecen con notas más extensas; los hubs, con más miembros.
- **Movimiento**: la física *force-directed* mantiene el grafo flotando; la energía depende del ánimo promedio y del número de notas (más "bright" y más notas = más vivo). Se puede pausar.
- **Interacción**: toca un nodo/hub para enfocarlo y ver su tarjeta, arrastra para mover, pellizca para zoom (0.6–3.0) y usa **Pin** para fijar un nodo. **Show all / Hide all** despliega u oculta las etiquetas.
- Respeta **Reduce Motion** (cámara sin animación).

## Documentación

- [`DESIGN.md`](DESIGN.md) — sistema de diseño (tokens, tipografía, motivos, componentes, reglas).
- [`QA.md`](QA.md) — checklist de QA manual y tests automáticos.
- [`CHANGELOG.md`](CHANGELOG.md) — historial de versiones.

## License

MIT
