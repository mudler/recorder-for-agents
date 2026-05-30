#!/usr/bin/env python3
"""Trivial TUI so you can smoke-test the recorder:
    cd examples/hello && ../../record.sh "python3 demo.py" hello.mp4
"""
import time
from rich.live import Live
from rich.panel import Panel
from rich.align import Align
from rich.text import Text

with Live(screen=True, refresh_per_second=30) as live:
    for i in range(0, 101, 2):
        bar = "█" * (i // 2) + "░" * (50 - i // 2)
        body = Text(f"\nrecorder-for-agents\n\n{bar}\n\n{i}%\n", justify="center", style="white")
        live.update(Align.center(Panel(body, border_style="green", padding=(1, 4)), vertical="middle"))
        time.sleep(0.04)
    live.update(Align.center(Panel(Text("\n✓ recorded\n", justify="center", style="bold green"),
                                   border_style="green", padding=(1, 4)), vertical="middle"))
    time.sleep(1.5)
