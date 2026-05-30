# recorder-for-agents

A tiny, reusable rig for turning **any terminal program or GUI command into an
MP4** — headlessly, in a container, with no display attached. Agents (or CI)
can use it to record demos, TUIs, dashboards, or app walkthroughs into a video
without a real screen.

It's just the *recording machinery*: `Xvfb` (virtual X) → `i3` (fullscreen the
window) → `xterm` (for terminal programs) → `ffmpeg x11grab` (capture) →
`out.mp4`, with optional `x11vnc` for a live preview. What you record is up to
you — mount your code, pass a command.

A clip this rig produced, the [`duel`](examples/duel) example (two engines
racing side by side at their real measured speed, with a branding outro):

![a two-engine duel clip recorded with this rig](examples/duel/sample.gif)

## Use it

```sh
# record a terminal program / TUI
./record.sh "python3 demo.py" demo.mp4

# knobs are env vars
WIDTH=1080 HEIGHT=1080 DURATION=20 FONTSIZE=18 ./record.sh "python3 app.py" square.mp4

# record a GUI app instead of a terminal program
GUI=1 ./record.sh "mpv --fullscreen clip.mp4" play.mp4

# watch it render live while recording (VNC on :5900)
VNC=1 ./record.sh "python3 demo.py" demo.mp4
```

`record.sh` builds the image once, mounts your current dir at `/work` and
`./out` at `/out`, runs the command, and writes the video to `./out/`.

Or call the image directly:

```sh
docker build -t recorder-for-agents .
docker run --rm -v "$PWD:/work" -v "$PWD/out:/out" \
  -e CMD="python3 demo.py" -e OUT=demo.mp4 -e DURATION=12 -e FONTSIZE=18 \
  recorder-for-agents
```

## Knobs (env vars)

| var | default | meaning |
|---|---|---|
| `CMD` | (required) | command to run and record |
| `OUT` | `out.mp4` | output filename under `/out` |
| `WIDTH`/`HEIGHT` | `1280`/`720` | frame size (use `1080`/`1080` for square, `1080`/`1920` for vertical) |
| `DURATION` | `15` | seconds to record |
| `FPS` | `30` | capture frame rate |
| `FONTSIZE` | `16` | xterm font size (terminal mode) |
| `GUI` | `0` | `1` = run CMD as a windowed app instead of inside xterm |
| `VNC` | `0` | `1` = expose x11vnc on `VNC_PORT` (5900) for live preview |
| `START_DELAY`/`END_HOLD` | `1.0`/`1.5` | pad before first frame / after CMD exits |
| `FONT`/`BG`/`FG` | DejaVu/black/white | xterm look |

Python + `rich` are preinstalled (agent TUIs are often rich-based); for other
runtimes, `pip install`/`apt-get` inside `CMD` or extend the Dockerfile.

## Notes

- The command should finish within `DURATION` (it's a fixed-length capture).
- Output is silent; mux audio afterward with ffmpeg if needed.
- A real consumer of this rig: the parakeet.cpp "transcription race" demo —
  it just provides a `rich` renderer + data and calls this recorder.

## Examples

- [`examples/hello/`](examples/hello) — a trivial progress-bar TUI to smoke-test the rig.
- [`examples/duel/`](examples/duel) — a full "processing race" comparison video:
  two engines side by side, progress bars, stats card, and a configurable
  branding outro (plus an optional subtle CRT pass). Bring your own traces.
