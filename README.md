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

- **Canvas**: `#FFFaf0` (crema cálido)
- **Tarjetas brand**: pink `#FF4D8B`, teal `#1A3A3A`, lavender `#B8A4ED`, peach `#FFB084`, ochre `#E8B94A`, mint `#A4D4C5`, coral `#FF6B5A`, cream `#F5F0E0`
- **Liquid glass**: efectos `.ultraThinMaterial` con bordes translúcidos (y Liquid Glass nativo de Apple en iOS 26)
- **Tipografía**: SF Rounded para cifras y encabezados

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
El workflow `.github/workflows/build-ios.yml` genera un IPA sin firma automáticamente.

1. Ir a **Actions** en el repositorio
2. Seleccionar **Build iOS IPA**
3. Click en **Run workflow**
4. Descargar el IPA desde **Artifacts**

### Instalación en iPhone
- Usar [AltStore](https://altstore.io/) o similar para instalar IPAs sin firma
- O configurar certificados de Apple Developer en GitHub Secrets

## NOTAS (Apple Notes) — cómo funciona

La app Notas de Apple no expone una API pública para leer notas de terceros, así que la integración se hace con la **hoja de compartir de iOS**:

1. Abre una nota en la app **Notas**
2. Toca el botón **Compartir** (cuadrado con flecha hacia arriba)
3. Elige **SafePlace**
4. La nota llega a la pestaña **Notes** de la app, donde puedes leerla y decidir "Keep it" (guardarla en tu safe place) o descartarla

> Nota: para que la extensión funcione en un dispositivo real se necesita una build firmada con tu cuenta de Apple Developer (las builds sin firma vía Actions requieren AltStore y no activan app groups).

## Mind (grafo de pensamientos)

La pestaña **Mind** dibuja tus notas como una red viva:

- **Conexiones**: dos notas se conectan si comparten categoría, mood, color de tarjeta o palabras clave. El slider ajusta la sensibilidad (cuántas conexiones se dibujan).
- **Color**: por estado de ánimo, por categoría o por color de tarjeta.
- **Tamaño**: los nodos crecen con más conexiones y con notas más extensas.
- **Movimiento**: la física *force-directed* mantiene el grafo flotando; la energía depende del ánimo promedio y del número de notas (más "bright" y más notas = más vivo). Se puede pausar.
- **Interacción**: toca un nodo para enfocarlo (resalta sus conexiones y muestra su tarjeta), arrastra para mover el grafo, pellizca para zoom, y usa **Pin** para fijar un nodo.

## License

MIT