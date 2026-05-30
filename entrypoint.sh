#!/bin/bash
# Generic headless screen recorder.
#
# Runs $CMD inside a virtual X session (Xvfb + i3) and captures the screen to
# /out/$OUT with ffmpeg. By default $CMD runs in a fullscreen xterm (for
# terminal programs / TUIs); set GUI=1 to launch $CMD directly as a windowed
# app (i3 fullscreens the first window). Nothing here is project-specific:
# mount your code at /work, pass CMD, get a video.
set -e
W=${WIDTH:-1280}; H=${HEIGHT:-720}; DUR=${DURATION:-15}; FPS=${FPS:-30}
FS=${FONTSIZE:-16}; OUT=${OUT:-out.mp4}; WD=${WORKDIR:-/work}
START_DELAY=${START_DELAY:-1.0}; END_HOLD=${END_HOLD:-1.5}
: "${CMD:?set CMD to the command to record}"

Xvfb :99 -screen 0 "${W}x${H}x24" -nolisten tcp >/tmp/xvfb.log 2>&1 &
export DISPLAY=:99
sleep 1
i3 -c /app/i3.config >/tmp/i3.log 2>&1 &
sleep 1
if [ "${VNC:-0}" = "1" ]; then
  x11vnc -display :99 -forever -shared -nopw -rfbport "${VNC_PORT:-5900}" -quiet >/tmp/vnc.log 2>&1 &
  echo "[recorder] x11vnc live preview on :${VNC_PORT:-5900}"
fi

# START_DELAY gives ffmpeg time to attach before the program draws its first frame.
if [ "${GUI:-0}" = "1" ]; then
  ( cd "$WD" && sleep "$START_DELAY" && eval "$CMD" ) &
else
  xterm -fa "${FONT:-DejaVu Sans Mono}" -fs "$FS" -bg "${BG:-black}" -fg "${FG:-white}" +sb \
    -e bash -lc "cd '$WD'; sleep $START_DELAY; $CMD; sleep $END_HOLD" &
fi

mkdir -p /out
ffmpeg -y -loglevel error -f x11grab -draw_mouse 0 -video_size "${W}x${H}" -framerate "$FPS" \
  -i :99 -t "$DUR" -pix_fmt yuv420p -movflags +faststart "/out/$OUT"
echo "[recorder] wrote /out/$OUT  (${W}x${H} @ ${FPS}fps, ${DUR}s)"
