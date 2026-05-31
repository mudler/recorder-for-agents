#!/usr/bin/env bash
# Trim the dead lead-in (the empty terminal the recorder shows while the program
# starts up). The blank is a perfectly static frame, so we find the first frozen
# segment that starts at t=0 and cut to where motion begins (the first rendered
# frame). Robust whether the content is dark or bright.
#
#   ./trim_lead.sh in.mp4 out.mp4
set -euo pipefail
IN=${1:?usage: trim_lead.sh in.mp4 out.mp4}
OUT=${2:?usage: trim_lead.sh in.mp4 out.mp4}

read -r fstart fend < <(ffmpeg -hide_banner -i "$IN" -vf "freezedetect=n=-50dB:d=0.2" \
    -map 0:v -f null - 2>&1 \
    | grep -oiE 'freeze_(start|end): *[0-9.]+' | head -2 \
    | grep -oE '[0-9.]+' | paste -sd' ')

# only trim if the very first frozen segment starts at the beginning
start=0
if [ -n "${fstart:-}" ] && awk "BEGIN{exit !(${fstart}<0.2 && ${fend:-0}>0)}"; then
  start=$fend
fi
ffmpeg -y -loglevel error -ss "$start" -i "$IN" \
  -c:v libx264 -pix_fmt yuv420p -movflags +faststart "$OUT"
echo "trimmed ${start}s of lead-in -> $OUT"
