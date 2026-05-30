#!/usr/bin/env bash
# Append a branding outro (optional logo + a title + up to two links) to a video.
# Everything is configurable via env, so there's nothing project-specific here.
#
#   ./outro.sh in.mp4 out.mp4 [seconds]
#
# env:
#   TITLE   headline line              (default: "made with recorder-for-agents")
#   LINK1   first link line (accent)   (default: github URL)
#   LINK2   second link line (dim)     (default: empty)
#   LOGO    path to a PNG logo         (optional; text-only if unset)
#   BG TEAL INK DIM   palette hex (0xRRGGBB)
set -euo pipefail
IN=${1:?usage: outro.sh in.mp4 out.mp4 [seconds]}
OUT=${2:?usage: outro.sh in.mp4 out.mp4 [seconds]}
SECS=${3:-3.2}
TITLE=${TITLE:-made with recorder-for-agents}
LINK1=${LINK1:-github.com/mudler/recorder-for-agents}
LINK2=${LINK2:-}
LOGO=${LOGO:-}
BG=${BG:-0x0D1117}; TEAL=${TEAL:-0x3EC8E0}; INK=${INK:-0xD7DDE5}; DIM=${DIM:-0x6E7681}
FONT=$(fc-match -f '%{file}' "DejaVu Sans Mono" 2>/dev/null || echo /usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf)
FONTB=$(fc-match -f '%{file}' "DejaVu Sans Mono:bold" 2>/dev/null || echo /usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf)
W=1280; H=720
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

# vertical anchors: with a logo the text sits lower; without, it centers
if [ -n "$LOGO" ] && [ -f "$LOGO" ]; then RY=412; TY=452; L1=528; L2=584
else RY=250; TY=290; L1=372; L2=428; fi

draw="drawbox=x=(iw-110)/2:y=${RY}:w=110:h=3:color=${TEAL}:t=fill,\
drawtext=fontfile=${FONTB}:text='${TITLE//\'/\\\'}':fontcolor=${INK}:fontsize=42:x=(w-tw)/2:y=${TY},\
drawtext=fontfile=${FONT}:text='${LINK1//\'/\\\'}':fontcolor=${TEAL}:fontsize=33:x=(w-tw)/2:y=${L1}"
[ -n "$LINK2" ] && draw="${draw},drawtext=fontfile=${FONT}:text='${LINK2//\'/\\\'}':fontcolor=${DIM}:fontsize=31:x=(w-tw)/2:y=${L2}"

if [ -n "$LOGO" ] && [ -f "$LOGO" ]; then
  ffmpeg -y -loglevel error \
    -f lavfi -i "color=c=${BG}:s=${W}x${H}:r=30:d=${SECS}" -loop 1 -t "$SECS" -i "$LOGO" \
    -filter_complex "[1:v]scale=-1:300[lg];[0:v][lg]overlay=(W-w)/2:78[bg];[bg]${draw}" \
    -pix_fmt yuv420p -c:v libx264 -an "$TMP/outro.mp4"
else
  ffmpeg -y -loglevel error \
    -f lavfi -i "color=c=${BG}:s=${W}x${H}:r=30:d=${SECS}" \
    -vf "$draw" -pix_fmt yuv420p -c:v libx264 -an "$TMP/outro.mp4"
fi

ffmpeg -y -loglevel error -i "$IN" -i "$TMP/outro.mp4" \
  -filter_complex "[0:v]scale=${W}:${H},setsar=1,fps=30[a];[1:v]scale=${W}:${H},setsar=1,fps=30[b];[a][b]concat=n=2:v=1[v]" \
  -map "[v]" -pix_fmt yuv420p -c:v libx264 "$OUT"
echo "-> $OUT"
