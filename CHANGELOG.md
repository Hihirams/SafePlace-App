# Changelog

Todos los cambios notables de SafePlace. El formato sigue [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/).

Desde el **build 23** la versión se calcula como `1.<build>` (ver [README → Versión y releases](README.md#versión-y-releases)). Los builds anteriores se listan por su número de build, que es el identificador estable de cada release.

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
