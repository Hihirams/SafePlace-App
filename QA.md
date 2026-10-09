# QA — SafePlace

Checklist repetible antes de dar por buena una versión.

## Automático (CI)

En cada push a `main` (y en cada rama, vía `Build check`) se ejecuta:

```bash
xcodebuild test \
  -project SafePlace.xcodeproj \
  -scheme SafePlace \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

- **Unit tests** (`SafePlaceTests`, Swift Testing): `Categorizer`, `MindGraph`, `MindState`, `Store`, `SearchRanker`, helpers de fecha.
- **UI tests** (`SafePlaceUITests`, XCTest): arranque a Home y navbar alcanzable.

El release de `main` está **bloqueado** hasta que pasen los tests (`needs: test`). Los resultados (`.xcresult`) se suben como artefacto.

## Manual — antes de cada release

### Dynamic Type
- Ajustes → Pantalla y brillo → Tamaño de texto → **AX5 (máximo)**. Recorrer Home, Journal, Mind, Saved, Create, Ajustes, Search. Nada debe truncarse, desbordar ni quedar inalcanzable.
- Repetir en tamaño **xSmall** (no debe verse comprimido).

### Accesibilidad
- **VoiceOver**: activar y recorrer cada pantalla. Cada control interactivo tiene etiqueta; los tabs se anuncian como botón y se activan; los iconos decorativos se saltan.
- **Increase Contrast** y **Bold Text**: activar; verificar que bordes/texto se refuerzan.
- **Reduce Motion**: activar; el personaje y el grafo no deben animarse en bucle.
- **Color**: ninguna información depende solo del color (mood también por icono/etiqueta).

### Responsive
- iPhone **SE** (≈320pt), iPhone Pro Max, **iPad**, y **landscape**.
- Teclado: los formularios no deben quedar tapados por el teclado.

### Flujos críticos
1. Create → guardar nota (con auto-categoría y cambio manual).
2. Check-in de mood desde Home.
3. Búsqueda: por palabra exacta, keyword y emoción ("me siento triste"); preview con resaltado; abrir resultado.
4. Mind: cambiar color mode (Mood/Category/Card/Wave), zoom, pan, pin, seleccionar nodo.
5. Ajustes: tema, recordatorio, export/import, borrar datos, shared notes.
6. Persistencia: cerrar y reabrir la app; los datos siguen.

### Errores / bordes
- Sin datos (estados vacíos) en cada pestaña.
- Texto muy largo en una nota.
- Muchas notas (rendimiento de Mind).

## Cómo correr local (macOS)
- Xcode: `Product → Test` (⌘U) con el scheme `SafePlace`.
- Simulador con Dynamic Type/contraste desde el menú **Environment Overrides** de Xcode.
- Accessibility Inspector para auditar etiquetas, contraste y áreas táctiles.

## Pendiente / ideas
- Añadir `performAccessibilityAudit()` como UI test cuando el pase de accesibilidad esté estable.
- Snapshots visuales (multi-dispositivo/tema) si se desea regresión visual automática.
