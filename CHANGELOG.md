# Changelog

Todos los cambios notables de SafePlace. El formato sigue [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/).

Desde el **build 23** la versión se calcula como `1.<build>` (ver [README → Versión y releases](README.md#versión-y-releases)). Los builds anteriores se listan por su número de build, que es el identificador estable de cada release.

## [1.41] — build 41 · 2026-10-29
### Añadido
- **Textura de papel** (grano determinista al 3%) en el fondo, el motivo que pedía el contrato y no existía.
- **Guard de diseño en CI** (`scripts/check_design.py`): falla si aparece un tamaño de fuente fijo fuera del design system, si se combinan hijos para VoiceOver sin acciones de reemplazo, o si vuelve copy genérica de la lista negra.
### Cambiado
- Jerarquía de fecha en **Journal**: numeral serif grande con el día/mes en sans pequeño.
- Chips de mood y muestras de color con **44 pt de área de toque** conservando el círculo de 34/36.

## [1.40] — build 40 · 2026-10-29
### Cambiado
- **Splash de 2.4 s** (antes 5 s). Con Reduce Motion el wordmark aparece completo y la salida es inmediata.
### Corregido
- El avatar ya no es un círculo con glifo de persona: usa el asterisco de SafePlace sobre el orbe del mood.

## [1.39] — build 39 · 2026-10-29
### Corregido
- **Modo oscuro ilegible en las notas**: el texto usaba la tinta dinámica y se volvía casi blanco sobre el pastel de la ficha (~1.4:1). Nuevo token `inkOnFill` y test que mide claro y oscuro.
### Cambiado
- Los tamaños tipográficos custom escalan contra el estilo de texto que les corresponde, no siempre contra `.body`.

## [1.38] — build 38 · 2026-10-28
### Cambiado
- **Insights** deja de ser una tira de tarjetas: una línea editorial y secciones separadas por hairline.
- "How it works" en Notes pasa de tarjeta a sección (es contenido, no interacción).
- Copy fuera de la lista negra: "Get started"/"Continue" → "Abrir mi lugar seguro"/"Siguiente".

## [1.37] — build 37 · 2026-10-28
### Añadido
- Test de **contraste WCAG AA** que mide fichas, píldoras de mood y tokens de texto en claro y oscuro, componiendo el alpha de los colores translúcidos.

## [1.36] — build 36 · 2026-10-29
### Añadido
- Tests de UI que crean una nota de verdad y comprueban que aparece en Home.
### Corregido
- **VoiceOver**: la tarjeta combinaba sus hijos y el menú desaparecía del árbol. Ahora expone Editar, Duplicar y Borrar como acciones de accesibilidad.

## [1.35] — build 35 · 2026-10-28
### Añadido
- Confirmación antes de borrar una nota o un elemento guardado.

## [1.34] — build 34 · 2026-10-28
### Añadido
- **Exportar a Markdown** desde Ajustes › Tus datos.

## [1.33] — build 33 · 2026-10-28
### Añadido
- Cobertura de pruebas: stats diarias, grafo de Mind, operaciones del Store y exportación (de 20 a 65 pruebas).

## [1.32] — build 32 · 2026-10-28
### Corregido
- `Store` deja de tragarse los errores de guardado: publica el fallo y Ajustes lo muestra.

## [1.31] — build 31 · 2026-10-28
### Añadido
- Etiquetas de VoiceOver en los controles de solo icono y áreas de toque de 44 pt.

## [1.30] — build 30 · 2026-10-28
### Cambiado
- **Tipografía que escala con Dynamic Type**: 88 tamaños fijos convertidos a `SafeDesign.scaled(...)`.

## [1.29] — build 29 · 2026-10-28
### Corregido
- Los identificadores de accesibilidad de las pestañas ya no dependen del idioma (rompían los UI tests al traducir).

## [1.28] — build 28 · 2026-10-28
### Añadido
- Guard de localización en CI: falla si aparece copia de UI que no esté en `Localizable.xcstrings`.

## [1.27] — build 27 · 2026-10-28
### Corregido
- Español completo: las cadenas que se mostraban desde variables, enums y ternarios seguían en inglés (pestañas, Ajustes, onboarding, formularios, filtros, insights).

## [1.26] — build 26 · 2026-10-28
### Añadido
- **La app habla español**: `Localizable.xcstrings` con 92 cadenas, categorías por defecto en español y migración idempotente de las heredadas en inglés.
### Cambiado
- El categorizador entiende vocabulario en español además del inglés.

## [1.25] — build 25 · 2026-10-28
### Corregido
- El estado de ánimo dominante se elegía con el orden aleatorio de un diccionario: el tinte de la app cambiaba de color solo entre lanzamientos. Empates ahora deterministas (mood más reciente y luego orden fijo).
- Rachas: se comparan días de calendario en vez de sumar 86 400 s (se rompían con cambios de horario).
- Listas (categorías, moods, keywords, resultados de búsqueda) ya no se reordenan solas.

## [1.23] — build 23 · 2026-10-16
### Añadido
- Splash de 5 s con el wordmark "SafePlace" escribiéndose letra a letra.

## build 22 · 2026-10-10
### Corregido
- Parpadeo de la vista **Wave** (stats cacheadas y orbes en un solo pase).
- El foco del hub ahora alterna (toggle).
- Se añadió *drift* ambiental y la acción **Show all**.
- El bounce del navbar ocurre solo en la pestaña seleccionada.

## build 21 · 2026-10-10
### Añadido
- Cámara del grafo Mind dirigida por frames (focus/zoom suaves).
- Transición de color fluida en la vista Wave.

## build 20 · 2026-10-09
### Añadido
- Filas editoriales para **Saved** y las notas compartidas.

## build 19 · 2026-10-09
### Corregido
- Trigonometría con `CGFloat` en el layout de los clústeres de Mind.

## build 18 · 2026-10-09
### Añadido
- Mind agrupado por categoría (modos **Wave** / **Category** y foco por categoría).
- Foto de perfil y splash teñido por el mood.
### Cambiado
- **Create** pasa a ser un editor a pantalla completa.
- Tematización en sheets y filas editoriales en Today/estadísticas.

## build 17 · 2026-10-09
### Cambiado
- Rediseño **"warm editorial paper"**: navbar centrada, cambio de tema inmediato, header fijo en Home, avatar de marca, Mind compacto (Wave por defecto), **Create** como lienzo en blanco y filas de nota editoriales.

## builds 14–16 · 2026-10-09
### Añadido
- Targets de tests (unit + UI), scheme compartido y bloqueo del release hasta que pasen los tests.
- `NoteStats` y `SearchRanker` como motores puros con tests.
### Corregido
- Hashing estable del grafo, unwraps seguros, unión de categorías, stopwords en español y ajuste de hápticos.

## builds ≤ 13
Historial anterior en `git log` y en los **GitHub Releases** del repositorio.
