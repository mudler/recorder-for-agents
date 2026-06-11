#!/usr/bin/env bash
# Render the image-race in all three layouts and append the branding outro.
#
#   ./make.sh [spec.json]
#
# env:
#   LAYOUTS  space-separated subset of: cols square vertical   (default: all)
#   TITLE LOGO LINK1   forwarded to ../duel/outro.sh
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
SPEC="${1:-}"
LAYOUTS="${LAYOUTS:-cols square vertical}"
mkdir -p "$HERE/out"

declare -A DIM=( [cols]="1280 720" [square]="1080 1080" [vertical]="1080 1920" )

for L in $LAYOUTS; do
  echo "== $L =="
  python3 "$HERE/image_race.py" ${SPEC:+--spec "$SPEC"} --layout "$L" --gif \
      --out "$HERE/out/image_race_$L.mp4"
  read -r OW OH <<<"${DIM[$L]}"
  OW="$OW" OH="$OH" \
    TITLE="${TITLE:-made with recorder-for-agents}" \
    LOGO="${LOGO:-$HERE/../batch_demo/localai_logo.png}" \
    LINK1="${LINK1:-github.com/mudler/recorder-for-agents}" \
    "$HERE/../duel/outro.sh" "$HERE/out/image_race_$L.mp4" "$HERE/out/image_race_${L}_final.mp4" 2>/dev/null \
    && echo "  -> out/image_race_${L}_final.mp4" \
    || echo "  (outro skipped — needs host ffmpeg + fonts)"
done
