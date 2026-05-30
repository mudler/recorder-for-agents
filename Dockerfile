# recorder-for-agents: a headless rig that records any terminal/GUI command to
# an MP4. Xvfb (virtual X) + i3 (fullscreen the window) + xterm + ffmpeg
# (x11grab) + x11vnc (optional live preview). Python + rich are preinstalled
# since agent demos are often rich TUIs; install anything else in your CMD or
# extend this image.
FROM python:3.12-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        xvfb i3 xterm ffmpeg x11vnc fonts-dejavu-core ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir rich==13.9.4

COPY i3.config entrypoint.sh /app/
RUN chmod +x /app/entrypoint.sh

# All knobs are env vars; CMD is required at run time. Mount code at /work and
# an output dir at /out.
ENV WIDTH=1280 HEIGHT=720 DURATION=15 FPS=30 FONTSIZE=16 VNC=0 \
    OUT=out.mp4 WORKDIR=/work START_DELAY=1.0 END_HOLD=1.5
WORKDIR /app
ENTRYPOINT ["/app/entrypoint.sh"]
