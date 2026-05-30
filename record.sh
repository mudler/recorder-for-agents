#!/usr/bin/env bash
# Build (once) + run the recorder against a command.
#
#   ./record.sh "<command>" [output.mp4]
#
# Mounts the current dir (or $WORK) at /work and ./out at /out, so the command
# runs against your files and the video lands in ./out. Knobs via env:
#   WIDTH HEIGHT DURATION FPS FONTSIZE GUI VNC   (see README)
#
# Examples:
#   ./record.sh "python3 demo.py" demo.mp4
#   DURATION=20 FONTSIZE=18 ./record.sh "python3 render/race.py" race.mp4
#   GUI=1 ./record.sh "mpv --fullscreen clip.mp4" play.mp4
set -euo pipefail
IMG=${IMG:-recorder-for-agents}
HERE=$(cd "$(dirname "$0")" && pwd)
CMD=${1:?usage: record.sh "<command>" [out.mp4]}
OUT=${2:-out.mp4}
WORK=${WORK:-$PWD}

docker image inspect "$IMG" >/dev/null 2>&1 || docker build -t "$IMG" "$HERE"
mkdir -p "$WORK/out"

docker run --rm \
  -v "$WORK:/work" -v "$WORK/out:/out" \
  -e CMD="$CMD" -e OUT="$OUT" \
  -e WIDTH="${WIDTH:-1280}" -e HEIGHT="${HEIGHT:-720}" -e DURATION="${DURATION:-15}" \
  -e FPS="${FPS:-30}" -e FONTSIZE="${FONTSIZE:-16}" -e GUI="${GUI:-0}" \
  -e FONT="${FONT:-DejaVu Sans Mono}" -e BG="${BG:-black}" -e FG="${FG:-white}" \
  -e START_DELAY="${START_DELAY:-1.0}" -e END_HOLD="${END_HOLD:-1.5}" \
  -e VNC="${VNC:-0}" ${VNC:+-p "${VNC_PORT:-5900}:${VNC_PORT:-5900}"} \
  "$IMG"
echo "-> $WORK/out/$OUT"
