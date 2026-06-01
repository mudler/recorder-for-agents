#!/usr/bin/env bash
# Render an HTML file to a crisp PNG (social card, diagram, chart) via headless
# Chrome. No display, no Docker, no image model - just the browser you have.
#
#   ./render-card.sh <input.html> [output.png]
#
# Pipeline: headless Chrome screenshots the page at a high device-scale-factor
# (retina-crisp), then ImageMagick crops to the exact target size. We render in
# a slightly TALLER window than the target and crop the top, because headless
# Chrome's real viewport is often shorter than the requested window height and
# silently clips the bottom of the page. Cropping from a taller shot is the
# reliable fix.
#
# Your HTML should size itself to the target (e.g. `html,body{width:1600px;
# height:900px}`). Google Fonts load fine - Chrome has network during render.
#
# Knobs via env:
#   WIDTH HEIGHT   target logical size in px      (default 1600 x 900)
#   SCALE          retina multiplier              (default 2  -> 3200x1800 file)
#   PAD            extra render height for anti-clip (default 220)
#   DELAY          ms to wait for fonts/layout    (default 600)
#   CHROME         chrome/chromium binary to use  (default: autodetect)
#
# Examples:
#   ./render-card.sh examples/cards/card.html
#   WIDTH=1200 HEIGHT=675 ./render-card.sh card.html twitter.png
#   SCALE=3 ./render-card.sh chart.html chart@3x.png
set -euo pipefail

IN=${1:?usage: render-card.sh <input.html> [output.png]}
[[ -f "$IN" ]] || { echo "error: no such file: $IN" >&2; exit 1; }
OUT=${2:-${IN%.*}.png}

WIDTH=${WIDTH:-1600}
HEIGHT=${HEIGHT:-900}
SCALE=${SCALE:-2}
PAD=${PAD:-220}
DELAY=${DELAY:-600}

# --- locate a Chrome/Chromium and an ImageMagick ---------------------------
CHROME=${CHROME:-}
if [[ -z "$CHROME" ]]; then
  for c in google-chrome google-chrome-stable chromium chromium-browser chrome; do
    if command -v "$c" >/dev/null 2>&1; then CHROME=$c; break; fi
  done
fi
[[ -n "$CHROME" ]] || { echo "error: no chrome/chromium found (set CHROME=...)" >&2; exit 1; }

IM=""
for m in magick convert; do
  if command -v "$m" >/dev/null 2>&1; then IM=$m; break; fi
done
[[ -n "$IM" ]] || { echo "error: ImageMagick not found (need 'magick' or 'convert')" >&2; exit 1; }

# --- render ----------------------------------------------------------------
ABS=$(cd "$(dirname "$IN")" && pwd)/$(basename "$IN")
TMP=$(mktemp --suffix=.png)
trap 'rm -f "$TMP"' EXIT

"$CHROME" --headless --disable-gpu --no-sandbox --hide-scrollbars \
  --force-device-scale-factor="$SCALE" \
  --virtual-time-budget=$((DELAY + 400)) \
  --window-size="${WIDTH},$((HEIGHT + PAD))" \
  --screenshot="$TMP" "file://$ABS" 2>/dev/null

# Crop the top-left target region at the scaled resolution.
"$IM" "$TMP" -crop "$((WIDTH * SCALE))x$((HEIGHT * SCALE))+0+0" +repage "$OUT"

echo "-> $OUT  ($((WIDTH * SCALE))x$((HEIGHT * SCALE)), from ${WIDTH}x${HEIGHT} @${SCALE}x)"
