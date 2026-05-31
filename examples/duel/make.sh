#!/usr/bin/env bash
# Build the demo end to end: render the duel TUI, record it to MP4 with the
# recorder, append a branding outro, and (optionally) add a subtle CRT pass.
#
#   ./make.sh [out.mp4]
#
# env:
#   KEYS      trace keys to race      (default: fast,baseline)
#   DILATE    slow-mo factor          (default: 1 = real time)
#   NOTE      header / eyebrow text   (default: "same output")
#   LINK      end-card footer link
#   CRT       1 = also write *_crt.mp4
#   DURATION FONTSIZE  passed to the recorder
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)        # recorder-for-agents root (has record.sh)
OUT=${1:-duel.mp4}
KEYS=${KEYS:-fast,baseline}; DILATE=${DILATE:-1}; NOTE=${NOTE:-same output}
LINK=${LINK:-github.com/mudler/recorder-for-agents}
# layout + frame size: default 16:9 side-by-side; LAYOUT=rows + a square/vertical
# WIDTHxHEIGHT gives a mobile cut.
LAYOUT=${LAYOUT:-cols}; W=${WIDTH:-1280}; H=${HEIGHT:-720}

# render + record (tinted dark background via the recorder's BG knob)
WORK="$HERE" BG="#0d1117" FG="#d7dde5" FONTSIZE="${FONTSIZE:-18}" DURATION="${DURATION:-12}" \
  WIDTH="$W" HEIGHT="$H" \
  "$ROOT/record.sh" "python3 duel.py --traces traces --keys $KEYS --dilate $DILATE --layout $LAYOUT --note '$NOTE' --link '$LINK'" "$OUT"

# branding outro (needs ffmpeg on the host); LOGO is optional, OW/OH match the frame
NOEXT="${OUT%.mp4}"
OW="$W" OH="$H" "$HERE/outro.sh" "$HERE/out/$OUT" "$HERE/out/${NOEXT}_final.mp4"
echo "-> $HERE/out/${NOEXT}_final.mp4"

if [ "${CRT:-0}" = "1" ]; then
  "$HERE/crt.sh" "$HERE/out/${NOEXT}_final.mp4" "$HERE/out/${NOEXT}_crt.mp4"
fi
