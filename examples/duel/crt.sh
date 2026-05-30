#!/usr/bin/env bash
# Give a video an old-CRT look: phosphor scanlines, bloom/glow, slight barrel
# curvature, chromatic aberration, and a vignette. Pure ffmpeg post-process, so
# it works on any clip (here: the duel videos).
#
#   ./crt.sh in.mp4 out.mp4
set -euo pipefail
IN=${1:?usage: crt.sh in.mp4 out.mp4}
OUT=${2:?usage: crt.sh in.mp4 out.mp4}

# tunables (env). Defaults are deliberately SUBTLE (a hint of CRT, not a costume).
# Push SCAN toward 0.4, K1 toward 0.09, BLOOM toward 0.5 for a heavier look.
BRIGHT=${BRIGHT:-0.03}; CONTR=${CONTR:-1.05}; SAT=${SAT:-1.10}
K1=${K1:-0.035}; K2=${K2:-0.012}; BLOOM=${BLOOM:-0.30}
SCAN=${SCAN:-0.12}; VIG=${VIG:-7}        # scanline depth; vignette = PI/VIG
BASE=$(awk "BEGIN{print 1-$SCAN}")

CRT="format=rgb24,\
eq=brightness=${BRIGHT}:contrast=${CONTR}:saturation=${SAT},\
lenscorrection=k1=${K1}:k2=${K2},\
rgbashift=rh=1:bh=-1,\
split[b][g];[g]gblur=sigma=3[gb];\
[b][gb]blend=all_mode=screen:all_opacity=${BLOOM}[bl];\
[bl]geq=\
r='r(X,Y)*(${BASE}+${SCAN}*sin(Y*PI/1.5))':\
g='g(X,Y)*(${BASE}+${SCAN}*sin(Y*PI/1.5))':\
b='b(X,Y)*(${BASE}+${SCAN}*sin(Y*PI/1.5))'[sc];\
[sc]vignette=PI/${VIG},format=yuv420p"

ffmpeg -y -loglevel error -i "$IN" -filter_complex "$CRT" \
  -c:v libx264 -pix_fmt yuv420p -movflags +faststart "$OUT"
echo "-> $OUT"
