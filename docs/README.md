# Landing de SafePlace

Página de presentación de la app, servida por GitHub Pages junto al feed de
AltSource. Hereda el sistema visual de la app (`../DESIGN.md`): papel cálido,
serif de display, un único acento que cambia con el estado de ánimo.

## Archivos

| Archivo | Qué es |
| --- | --- |
| `index.html` | Landing en español (por defecto) |
| `en.html` | Landing en inglés |
| `landing.css` | Tokens y componentes compartidos. Sin build step |
| `assets/hero-wide.webp` | Ilustración del hero (1672×941) |
| `assets/scene-1.webp` | Escena del tren (1672×941) |
| `assets/scene-3.webp` | Escena de la cama (1200 px) |
| `assets/band-kitchen.webp` | Banda de la cocina (1914×822) |
| `assets/og.png` | Imagen para compartir (1200×630) |
| `icon.png` | Icono de la app. **Copia de `AppIcon-1024.png`**: no editar aquí |
| `source.json` | Feed AltSource. **Lo regenera el CI en cada release** |

El workflow publica toda la carpeta `docs/`, así que la landing y el feed viven
en el mismo dominio: `https://hihirams.github.io/SafePlace-App/`.

## Cambiar las capturas de la app

La sección **Tres pantallas** usa marcadores con el color del sistema hasta que
haya capturas reales. Para reemplazarlos, en `index.html` y `en.html` busca los
comentarios `REEMPLAZAR` / `REPLACE` dentro de `.device-screen`.

Cada marcador es esto:

```html
<div class="shot-slot" data-shot="home">
  <img class="slot-mascot" src="assets/logo.webp" alt="">
  <b>Inicio</b>
  <span>captura pendiente</span>
</div>
```

Cámbialo por una imagen con la misma proporción (9:19.5):

```html
<img src="assets/shot-home.png" alt="Pantalla de inicio de SafePlace">
```

En móvil el carrusel **no usa scroll horizontal nativo**: un visor con
`overflow:hidden` recorta un riel que se mueve por `transform`, y las flechas
cambian de diapositiva. Si le devuelves `overflow-x:auto`, el gesto horizontal
vuelve a competir con el scroll vertical de la página.

Nombres sugeridos: `shot-home.png`, `shot-journal.png`, `shot-mind.png`.
Exporta desde el simulador a 1179×2556 (iPhone 15 Pro) o equivalente; el marco
recorta lo que sobre.

## Probar en local

```bash
npx serve docs
# o
python -m http.server 8100 --directory docs
```

Abre `http://localhost:8100/`. Con `file://` funciona todo menos la lectura de
`source.json` (la versión cae al valor por defecto).

## Reglas que no se negocian

- Un solo acento; el color va en el detalle, nunca en el fondo.
- Sin tarjetas anidadas, sin sombras decorativas, sin degradados fuertes.
- El papel `#FAF8F4` es el token `canvas` de la app: no es un beige genérico.
  El detector de Impeccable lo marca como patrón por defecto; está desactivado
  con razón escrita en el `<head>`.
- Todo el texto vive en HTML, no dentro de las imágenes.
