#!/usr/bin/env python3
"""
duel.py — a two-pane "processing race" between two engines / commands, rendered
with rich and meant to be captured by recorder-for-agents into an MP4.

Each pane types its transcript (or any output text) over the engine's REAL
measured proc time and fills a progress bar; the faster engine finishes first
and gets a ★. Refined dark theme: a tinted background (set via the recorder's
BG knob), a teal accent for the first ("hero") engine, muted slate for the
rest, a green check on finish.

Sub-second races can be slowed with --dilate (the real elapsed ms are shown and
the factor is stated, so the numbers stay honest); a real-time race uses
--dilate 1.

Traces are JSON files in --traces, one per engine:
  {"key","label","device","proc_s","rtfx","text"}   ("wer" optional)

  python3 duel.py --keys fast,baseline --dilate 1 \
      --note "same output" --link github.com/you/your-tool
"""
import argparse, json, textwrap, time
from pathlib import Path

from rich import box
from rich.console import Group, Console
from rich.live import Live
from rich.panel import Panel
from rich.table import Table
from rich.text import Text
from rich.align import Align

# ---- palette (tinted dark) -------------------------------------------------
INK   = "#d7dde5"
DIM   = "#6e7681"
FAINT = "#3b424c"
RULE  = "#222b34"
HERO_FILL,  HERO_EMPTY,  HERO_IDLE  = "#3ec8e0", "#1d6c7b", "#3ec8e0"   # teal
RIVAL_FILL, RIVAL_EMPTY, RIVAL_IDLE = "#94a3b2", "#39424d", "#46515e"   # slate
GREEN = "#46c266"
GOLD  = "#e3b341"


def accent(is_hero):
    return (HERO_FILL, HERO_EMPTY, HERO_IDLE) if is_hero else (RIVAL_FILL, RIVAL_EMPTY, RIVAL_IDLE)


def load(traces_dir, keys):
    t = {}
    for f in Path(traces_dir).glob("*.json"):
        d = json.load(open(f))
        t[d["key"]] = d
    return [t[k] for k in keys if k in t]


def bar(frac, width, fill, empty):
    f = max(0, min(width, round(width * frac)))
    t = Text()
    t.append("━" * f, style=fill)
    t.append("━" * (width - f), style=empty)
    t.append(f"  {int(round(frac * 100)):>3d}%", style=(fill if frac >= 1 else DIM))
    return t


def pane(tr, real_elapsed, height, inner_width, is_hero, winner):
    proc = tr["proc_s"]
    done = real_elapsed >= proc
    frac = 1.0 if proc <= 0 else min(1.0, real_elapsed / proc)
    fill, empty, idle = accent(is_hero)

    words = tr["text"].split()
    shown = " ".join(words[:int(len(words) * frac)])
    body_lines = max(3, height - 7)
    wrapped = textwrap.wrap(shown, max(10, inner_width)) or [""]
    visible = wrapped[-body_lines:]
    txt = Text("\n".join(visible), style=INK)
    if not done:
        txt.append(" ▌", style=fill)
    pad = body_lines - len(visible)
    if pad > 0:
        txt.append("\n" * pad)

    title = Text()
    title.append(f" {tr['label']} ", style=f"bold {fill}")
    title.append(f"{tr['device']} ", style=DIM)

    status = Text()
    if done:
        status.append("✓ ", style=f"bold {GREEN}")
        status.append(f"{proc * 1000:.0f} ms", style=f"bold {INK}")
        status.append(f"   {tr['rtfx']:.0f}× realtime", style=DIM)
        if winner:
            status.append("    ★ fastest", style=f"bold {GOLD}")
    else:
        status.append("▸ ", style=fill)
        status.append(f"{real_elapsed * 1000:.0f} ms", style=f"bold {INK}")

    border = (fill if done else idle)
    body = Group(txt, Text(""), bar(frac, max(10, inner_width - 6), fill, empty), status)
    return Panel(body, title=title, title_align="left", border_style=border,
                 box=box.ROUNDED, padding=(1, 2), height=height)


def header(traces, note, dilate, cols):
    a, b = traces
    left = Text()
    left.append(a["label"], style=f"bold {HERO_FILL}")
    left.append("  vs  ", style=DIM)
    left.append(b["label"], style=f"bold {RIVAL_FILL}")

    right = Text(justify="right")
    right.append(f"{a['device']}", style=INK)
    if note:
        right.append("   " + note, style=DIM)
    if dilate > 1.5:
        right.append(f"   ·   slowed {dilate:.0f}×", style=FAINT)

    g = Table.grid(expand=True)
    g.add_column(justify="left"); g.add_column(justify="right")
    g.add_row(left, right)
    return Group(g, Text("─" * cols, style=RULE), Text(""))


def view(traces, note, real_elapsed, dilate, cols, rows):
    avail = rows - 3
    pane_h = max(10, min(avail, 20))
    top_pad = max(0, (avail - pane_h) // 2)
    inner_w = max(20, cols // 2 - 9)
    fastest = min(traces, key=lambda t: t["proc_s"])
    g = Table.grid(expand=True, padding=(0, 1))
    g.add_column(ratio=1); g.add_column(ratio=1)
    g.add_row(*[pane(t, real_elapsed, pane_h, inner_w, i == 0, t is fastest)
                for i, t in enumerate(traces)])
    return Group(header(traces, note, dilate, cols), Text("\n" * top_pad), g)


def end_card(traces, note, link):
    a, b = sorted(traces, key=lambda t: t["proc_s"])   # a = fastest
    a_hero = a is traces[0]
    ratio = b["proc_s"] / a["proc_s"]
    wbar = 34
    fastest_rtfx = max(t["rtfx"] for t in traces)

    g = Text()
    if note:
        g.append(note.upper() + "\n\n", style=f"bold {DIM}")
    for t in (a, b):
        fill, empty, _ = accent(t is traces[0])
        g.append(f"{t['label']:<20}", style=f"bold {fill}")
        f = max(1, round(wbar * t["rtfx"] / fastest_rtfx))
        g.append("━" * f, style=fill)
        g.append(" " * (wbar - f))
        g.append(f"   {t['proc_s']*1000:.0f} ms", style=INK)
        g.append(f"   {t['rtfx']:.0f}×\n", style=DIM)
    g.append("\n")
    same_dev = a["device"] if a["device"] == b["device"] else None
    g.append(f"{ratio:.0f}× faster", style=f"bold {HERO_FILL if a_hero else INK}")
    if same_dev:
        g.append(f" on the same {same_dev}", style=f"bold {INK}")
    if link:
        g.append(f"\n\n{link}", style=DIM)
    return Panel(Align.center(g, vertical="middle"), border_style=HERO_EMPTY,
                 box=box.ROUNDED, padding=(2, 6))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--traces", default=str(Path(__file__).resolve().parent / "traces"))
    ap.add_argument("--keys", default="fast,baseline")
    ap.add_argument("--note", default="same output", help="eyebrow / header qualifier")
    ap.add_argument("--link", default="", help="footer link on the end card")
    ap.add_argument("--fps", type=int, default=30)
    ap.add_argument("--dilate", type=float, default=1.0, help="slow-mo factor (1 = real time)")
    ap.add_argument("--hold", type=float, default=1.0)
    ap.add_argument("--card", type=float, default=3.0)
    a = ap.parse_args()

    traces = load(a.traces, a.keys.split(","))
    if len(traces) != 2:
        raise SystemExit(f"need exactly 2 traces, got {[t['key'] for t in traces]}")
    real_end = max(t["proc_s"] for t in traces)
    wall_end = real_end * a.dilate + a.hold
    dt = 1.0 / a.fps

    console = Console()
    cols, rows = console.size
    with Live(console=console, refresh_per_second=a.fps, screen=True) as live:
        t0 = time.perf_counter()
        while (w := time.perf_counter() - t0) < wall_end:
            live.update(view(traces, a.note, w / a.dilate, a.dilate, cols, rows))
            time.sleep(dt)
        live.update(view(traces, a.note, real_end, a.dilate, cols, rows))
        time.sleep(0.7)
        live.update(Panel(Align.center(end_card(traces, a.note, a.link), vertical="middle"),
                          border_style="black", box=box.SIMPLE, height=rows))
        time.sleep(a.card)


if __name__ == "__main__":
    main()
