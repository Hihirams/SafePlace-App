# SafePlace App

App de iPhone para guardar las pequeñas cosas que te ayudan: hábitos, personas, lugares, música y autocuidado. El diseño replica la versión web de SafePlace (paleta "clay": canvas crema, tarjetas rosa/teal/lavanda/durazno/ocre) y toma la estructura de navegación con **liquid glass** del proyecto Luma.

## Características

- **Dashboard** con hero, estadísticas (cosas guardadas, categorías, barras por categoría, sentimientos) y cuadrícula de notas
- **Notas de colores** estilo clay con estado de ánimo, categoría y color seleccionable
- **Journal** — línea de tiempo agrupada por día
- **Resources** — enlaces, citas y recordatorios
- **Mind** — grafo tipo Obsidian: una red viva de tus pensamientos, temas y estados de ánimo. Los nodos se mueven, cambian de color (mood/categoría/card), de tamaño (conexiones + extensión del texto) y las conexiones se dibujan según lo que escribes. La energía del movimiento reacciona a cuántas notas tienes y a qué tan feliz te sientes
- **Compatibilidad con NOTAS de iPhone** — extensión de compartir (Share Extension): comparte texto desde la app Notas de Apple (o cualquier app) directo a SafePlace
- **Barra de navegación liquid glass** flotante (Luma) con selector que sigue tu dedo
- **Responsive**: se adapta a iPhone pequeños y grandes, rotación horizontal/vertical, iPad (grids de 3-4 columnas, hero lado a lado, ancho máximo de contenido) y Dynamic Type
- Onboarding de primera vez con splash animado
- Tema claro/oscuro/sistema

## Diseño

- **Base blanca y sobria** con la paleta solo en detalles; el color de acento es **dinámico**: se deriva del estado emocional (mood dominante) y tiñe acentos, el personaje, las gráficas y un glow de fondo muy leve
- **Paleta**: powder-blush `#FEC5BB`, almond-silk `#FCD5CE`, soft-blush `#FAE1DD`, seashell `#F8EDEB`, alabaster `#E8E8E4`, alabaster-2 `#D8E2DC`, linen `#ECE4DB`, powder-petal `#FFE5D9`, peach-fuzz `#FFD7BA`, peach-glow `#FEC89A`; las tarjetas de nota conservan su paleta viva
- **Modo oscuro**: negro puro `#000` (superficies casi negras, sin gris)
- **Logo**: icono de app (escudo + corazón); wordmark "SafePlace" en serif
- **Liquid glass**: efectos `.ultraThinMaterial` con bordes translúcidos (y Liquid Glass nativo de Apple en iOS 26)
- **Tipografía**: serif para el wordmark, SF Rounded para cifras

## Funciones

- **Home sobria**: header con avatar + wordmark centrado + buscador; personaje grande que cambia de color con tu estado de ánimo; check-in de mood; "on this day"; segmentado **Overview / Insights**
- **Create (centro del navbar)**: botón central elevado que abre una pantalla dedicada de composición
- **Búsqueda**: busca notas por palabras exactas, keywords, similitud difusa o emoción, con **preview** del texto y términos resaltados
- **Insights** (Swift Charts): notas por día, distribución por mood/categoría, palabras frecuentes y mejor racha — observacional, sin culpa
- **Ajustes** (desde el avatar): tema (único lugar), recordatorio diario, **importar notas compartidas**, export/import JSON, borrar datos, versión y feed de actualización
- **Journal**: búsqueda, filtro por mood y secciones por día colapsables
- **Saved**: copiar/compartir/convertir en nota/borrar
- **Auto-categoría**: al escribir una nota se sugiere una categoría según el contenido (puedes cambiarla antes de guardar)
- **Mind**: grafo force-directed responsive con nodos con degradado, glow, zoom, pan, pin y etiquetas; el **contagio** del mood dominante es siempre activo y la vista **Wave** lo hace más fuerte
- **Notas de iPhone**: comparte desde Apple Notes; se revisan/importan desde **Ajustes → Shared notes**


## Estructura

```
SafePlace - IOS/
├── SafePlace.xcodeproj/
├── SafePlace/
│   ├── App.swift                    # Entry point
│   ├── ContentView.swift            # Root + tab shell + glass tab bar + splash
│   ├── DesignSystem.swift           # Tokens de diseño (paleta clay)
│   ├── LiquidGlass.swift            # Modificadores liquid glass
│   ├── BackgroundOrbs.swift         # Canvas con brillos suaves
│   ├── SymbolEffects.swift          # Efectos de símbolos + botones pressable
│   ├── Extensions/
│   │   └── ColorExtension.swift     # Color(hex:)
│   ├── Models/
│   │   ├── Entry.swift              # Nota (título, descripción, categoría, mood, color)
│   │   ├── Mood.swift               # Estados de ánimo
│   │   ├── CardColor.swift          # Colores clay
│   │   ├── Resource.swift           # Recurso (link/note)
│   │   └── MindGraph.swift          # Nodos/aristas + heurísticas del grafo Mind
│   ├── Services/
│   │   ├── Store.swift              # Persistencia + notas compartidas (app group)
│   │   └── MindSimulation.swift     # Física force-directed del grafo Mind
│   └── Views/
│       ├── DashboardView.swift      # Pantalla principal
│       ├── JournalView.swift        # Línea de tiempo
│       ├── ResourcesView.swift      # Enlaces y recordatorios
│       ├── NotesView.swift          # Notas compartidas desde el iPhone
│       ├── MindView.swift           # Grafo neural (Canvas + controles glass)
│       ├── EntryCardView.swift      # Tarjeta de nota
│       ├── EntryFormView.swift      # Formulario alta/edición
│       ├── OnboardingView.swift     # Onboarding de primera vez
│       ├── GlassCard.swift          # Bloques compartidos (hairline, badges)
│       └── FormComponents.swift     # Campos, botones, buscador
└── SafePlaceShare/
    ├── ShareViewController.swift    # Extensión de compartir (Notas → SafePlace)
    ├── Info.plist
    └── SafePlaceShare.entitlements
```

## Build

### Requisitos
- macOS con Xcode 15+
- Cuenta de Apple Developer (para firma)
- O usar GitHub Actions para build sin firma

### GitHub Actions

El workflow `.github/workflows/build-ios.yml` compila y publica el IPA sin firma automáticamente. Se dispara en **cada push a `main`** (o manualmente con **Run workflow**). En cada build:

1. Compila el archive (`CODE_SIGNING_ALLOWED=NO`) bumpeando la versión a `1.0.<run_number>` / build `<run_number>`.
2. Publica el IPA como **GitHub Release** (tag `build-<run_number>`) con URL estable y pública.
3. Regenera `docs/source.json` (formato **AltSource**) apuntando a ese Release.
4. Despliega `docs/` a **GitHub Pages**.

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

- **Conexiones**: dos notas se conectan si comparten categoría, mood, color de tarjeta o palabras clave. El slider ajusta la sensibilidad (cuántas conexiones se dibujan).
- **Color**: por estado de ánimo, por categoría o por color de tarjeta.
- **Tamaño**: los nodos crecen con más conexiones y con notas más extensas.
- **Movimiento**: la física *force-directed* mantiene el grafo flotando; la energía depende del ánimo promedio y del número de notas (más "bright" y más notas = más vivo). Se puede pausar.
- **Interacción**: toca un nodo para enfocarlo (resalta sus conexiones y muestra su tarjeta), arrastra para mover el grafo, pellizca para zoom, y usa **Pin** para fijar un nodo.

## License

MIT