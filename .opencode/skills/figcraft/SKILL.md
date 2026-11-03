---
name: figcraft
description: >-
  Cómo trabajar con FigCraft desde este repo: el servidor MCP, el CLI headless y
  las rarezas del motor que cuestan horas redescubrir (ids, auto layout,
  posicionamiento absoluto, alpha, codificación). Úsala cuando haya que abrir,
  generar, editar o prototipar en `design/SafePlace-Motion.figcraft`, o cuando
  el MCP de FigCraft falle.
---

# FigCraft

Diseño en `design/SafePlace-Motion.figcraft`. Se genera por script y se aprueba
en la app. Fuente de verdad del movimiento: skill `safeplace-motion`.

## Dos caminos

**MCP (app abierta).** Herramientas `figcraft.*` vía `execute`. Requiere la app
lanzada con puerto de control, con las mismas raíces:

```
figcraft.exe --control 9229 ^
  --automation-read-root  "…\design" ^
  --automation-write-root "…\design" ^
  "…\design\SafePlace-Motion.figcraft"
```

Y en `~/.config/opencode/opencode.json`:

```json
"figcraft": { "type": "local", "command": [
  "C:\\Program Files\\ArtCraft\\FigCraft\\figcraft-cli.exe", "mcp", "--attach", "127.0.0.1:9229" ] }
```

**CLI headless (sin app).** `figcraft-cli run script.json --in X.figcraft --out X.figcraft`.
Es lo que usa `design/build-motion.mjs`. Sirve para reconstruir el documento
entero; el MCP para tocar el documento vivo.

## Rarezas del motor (verificadas, no teóricas)

1. **`--attach` no acepta `--automation-read-root/write-root`.** Las raíces van
   solo en la app. Si se pasan al servidor, el proceso sale con código 2 y el
   MCP queda en `failed`. El error está en `~/.local/share/opencode/log/opencode.log`.
2. **Los ids son secuenciales y globales.** Empiezan en 2 (la página es 1) y
   `page.add` **también consume un id**. Para generar scripts sin leer ids hace
   falta reservar en el mismo orden en que se crean nodos; si no, los `parent`
   apuntan a nodos inexistentes.
3. **`absolute: true` no funciona dentro de un frame con auto layout**, ni con
   `constraints`. Un hijo absoluto se coloca en el flujo. Solución: el elemento
   flotante va como frame hermano a nivel de página, posicionado con `x/y`.
4. **`node.create` de tipo `ellipse` ignora `width`/`height`** y crea 100×100.
   Usar `frame.create` con `cornerRadius = d/2`.
5. **`hug` exige que el propio frame tenga auto layout**; `fill` exige un padre
   con auto layout. Un frame con `layout: "none"` no puede hacer ninguna de las
   dos: `fixed`.
6. **`layout: null` no es válido**: se escribe `"none"`.
7. **Alpha por hex de 8 dígitos** (`#2A26221A`), no por objeto `{color, opacity}`.
8. **El CLI lee el script como Latin-1**: hay que escapar todo lo no-ASCII a
   `\uXXXX` antes de escribir el JSON, o "Música" sale "MÃºsica".
9. **`node.set` sí acepta `opacity: 0`** (crear con `opacity: 0` en props también
   funciona); útil para estados de entrada vacíos.
10. **`proto.interaction.add` quiere `dest` dentro de `action`**, no solo al
    nivel superior: `{action: {type: "navigate", dest: ID}, dest: ID}`.
11. **`proto.flow.add` usa `start`**, no `id`.
12. Un script es **todo o nada**: si un paso falla, no cambia nada. Se reporta un
    JSON por paso con `ok` y `error`.

## Verificar sin mirar la pantalla

```bash
figcraft-cli render design/SafePlace-Motion.figcraft --out x.png --page "Motion" --scale 1
```

Y para el documento vivo, `figcraft.screenshot({ids, maxSize})` devuelve PNG.
Nunca dar un diseño por bueno sin ver el render: la mitad de los errores de
layout solo se ven.

## Regenerar el documento

```bash
node design/build-motion.mjs    # 700+ comandos, 0 fallos, y escribe el .figcraft
```

Después, si la app lo tiene abierto: `open_file` del mismo path para recargar,
o `save_file` desde la app para que su estado mande. Nunca regenerar mientras la
app tenga cambios sin guardar.

## Nombres de capa

El `smartAnimate` empareja capas **por nombre** entre frames. Al duplicar un
estado, los nombres deben coincidir exactamente (`MoodDisc-calm`, `StreakBadge`,
`TabBar`…). Si una capa se renombra en un solo frame, la transición se rompe y
la capa entra con fade en vez de interpolar.
