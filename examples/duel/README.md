# duel — a two-engine "processing race" video

A self-contained example of using recorder-for-agents to produce a shareable
comparison clip: two engines transcribe (or process) the same input side by
side, each pane typing its output at the engine's *real measured speed*, so the
faster one finishes first and gets a ★. Ends on a stats card and a branding
outro.

![sample duel](sample.gif)

It's a `rich` renderer (`duel.py`) plus two ffmpeg post-steps (`outro.sh`,
`crt.sh`); the recorder just captures the TUI to MP4. Nothing here is tied to a
specific tool — swap in your own traces and text.

## Run it

```sh
./make.sh                      # -> out/duel_final.mp4
CRT=1 ./make.sh                # also writes out/duel_crt.mp4 (subtle CRT look)
```

Knobs (env): `KEYS` (which traces to race), `DILATE` (slow-mo factor, 1 = real
time), `NOTE` (header/eyebrow text), `LINK` (end-card footer), `DURATION`,
`FONTSIZE`. `make.sh` calls the recorder for you and runs the outro.

## Layouts (16:9 vs square / vertical)

Default is `cols`: two panes side by side, for a 16:9 clip. Set `LAYOUT=rows`
with a square or vertical `WIDTH`x`HEIGHT` for a stacked, full-width layout that
reads better on a phone (the outro scales to match):

```sh
LAYOUT=rows WIDTH=1080 HEIGHT=1080 FONTSIZE=20 ./make.sh duel_sq.mp4   # square
LAYOUT=rows WIDTH=1080 HEIGHT=1920 FONTSIZE=22 ./make.sh duel_v.mp4    # vertical
```

![stacked square layout](sample_square.gif)

## Bring your own data

Each engine is one JSON file in `traces/`:

```json
{ "key": "fast", "label": "fast-path", "device": "CPU",
  "proc_s": 0.42, "rtfx": 56, "text": "the text it produced ..." }
```

- `proc_s` is the real processing time (drives how fast the pane fills).
- `rtfx` is audio-seconds / proc-seconds (or any throughput number) shown on the
  bar and end card.
- The first key in `--keys` is the "hero" (teal accent); the other is the rival
  (slate). The fastest by `proc_s` gets the ★.
- Sub-second races: set `DILATE` so the replay is watchable (the real ms are
  still shown and the factor is stated in the header).

## Pieces

| file | what |
|------|------|
| `duel.py` | the `rich` TUI (panes, progress bars, header, end card) |
| `outro.sh` | append a branding card: optional `LOGO`, plus `TITLE`/`LINK1`/`LINK2` |
| `crt.sh` | optional subtle CRT post-process (scanlines, bloom, curvature, vignette) |
| `make.sh` | render -> record -> outro -> (optional) CRT |
| `traces/` | sample data (`fast` vs `baseline`) |

`outro.sh` and `crt.sh` need `ffmpeg` on the host; `duel.py` needs `rich` (the
recorder image already has it).
