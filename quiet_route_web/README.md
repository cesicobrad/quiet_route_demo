# Quiet Route Web Prototype

This is a standalone HTML prototype for the Quiet Route simulation using MapLibre GL JS. It is isolated from the Flutter app.

## Run locally

From the repo root:

```bash
cd quiet_route_web
python -m http.server 8000
```

Then open `http://localhost:8000` in your browser.

## MapTiler key

Paste your MapTiler key in `app.js`:

```js
const MAPTILER_KEY = "YOUR_KEY_HERE";
```

If the key is blank, the prototype will fall back to the public MapLibre demo tiles and the bundled GeoJSON route.
