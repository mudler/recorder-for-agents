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
W=${OW:-1280}; H=${OH:-720}    # OW/OH let callers make square (1080x1080) / vertical outros
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
i() { awk "BEGIN{printf \"%d\", $1}"; }
FS=$(i "$W*0.033"); FS2=$(i "$W*0.026")        # title / link font sizes scale with width

# vertical anchors scale with height; with a logo the text sits lower, else it centers
if [ -n "$LOGO" ] && [ -f "$LOGO" ]; then
  LH=$(i "$H*0.42"); LY=$(i "$H*0.11")
  RY=$(i "$H*0.575"); TY=$(i "$H*0.625"); L1=$(i "$H*0.73"); L2=$(i "$H*0.81")
else
  RY=$(i "$H*0.34"); TY=$(i "$H*0.40"); L1=$(i "$H*0.52"); L2=$(i "$H*0.59")
fi

draw="drawbox=x=(iw-110)/2:y=${RY}:w=110:h=3:color=${TEAL}:t=fill,\
drawtext=fontfile=${FONTB}:text='${TITLE//\'/\\\'}':fontcolor=${INK}:fontsize=${FS}:x=(w-tw)/2:y=${TY},\
drawtext=fontfile=${FONT}:text='${LINK1//\'/\\\'}':fontcolor=${TEAL}:fontsize=${FS2}:x=(w-tw)/2:y=${L1}"
[ -n "$LINK2" ] && draw="${draw},drawtext=fontfile=${FONT}:text='${LINK2//\'/\\\'}':fontcolor=${DIM}:fontsize=${FS2}:x=(w-tw)/2:y=${L2}"

if [ -n "$LOGO" ] && [ -f "$LOGO" ]; then
  ffmpeg -y -loglevel error \
    -f lavfi -i "color=c=${BG}:s=${W}x${H}:r=30:d=${SECS}" -loop 1 -t "$SECS" -i "$LOGO" \
    -filter_complex "[1:v]scale=-1:${LH}[lg];[0:v][lg]overlay=(W-w)/2:${LY}[bg];[bg]${draw}" \
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
