#!/usr/bin/env python3
"""ansi2svg — turn a colored terminal capture into a crisp SVG "screenshot".

Used to build the README images from real Hyprism screens, so they stay
reproducible and never leak a personal desktop:

    tmux new-session -d -s shot -x 120 -y 30 "visualconf"
    tmux capture-pane -t shot -e -p > shot.ansi
    tools/ansi2svg.py shot.ansi docs/assets/visualconf.svg --title "visualconf"

Understands SGR: reset, bold, reverse, 16/256/truecolor fg and bg.
Every text run gets an explicit x and textLength, so borders stay aligned
whatever monospace font the viewer has.
"""
import argparse
import html
import re
import sys

CW, LH, FS = 8.6, 18.0, 14.2          # cell width, line height, font size (px)
PAD, BAR = 18, 34                      # outer padding, title bar height
DEF_FG, DEF_BG = "#c8c8c8", "#0c0c0e"

BASE16 = ["#1c1c1c", "#cd3131", "#0dbc79", "#e5e510", "#2472c8", "#bc3fbc", "#11a8cd", "#e5e5e5",
          "#666666", "#f14c4c", "#23d18b", "#f5f543", "#3b8eea", "#d670d6", "#29b8db", "#ffffff"]


def xterm256(n):
    if n < 16:
        return BASE16[n]
    if n < 232:
        n -= 16
        steps = [0, 95, 135, 175, 215, 255]
        return "#%02x%02x%02x" % (steps[n // 36], steps[(n // 6) % 6], steps[n % 6])
    v = 8 + (n - 232) * 10
    return "#%02x%02x%02x" % (v, v, v)


SGR = re.compile(r"\x1b\[([0-9;:]*)m")
OTHER = re.compile(r"\x1b\[[0-9;?]*[A-Za-ln-z]|\x1b\][^\x07]*\x07|\x1b[()][AB012]")


def parse(text):
    """-> list of lines, each a list of (char, fg, bg, bold)"""
    rows = []
    fg, bg, bold, rev = None, None, False, False
    for raw in text.split("\n"):
        raw = OTHER.sub("", raw)
        row, pos = [], 0
        for m in SGR.finditer(raw + "\x1b[m"):
            for ch in raw[pos:m.start()]:
                f, b = (bg or DEF_BG, fg or DEF_FG) if rev else (fg, bg)
                row.append((ch, f, b, bold))
            pos = m.end()
            codes = [c for c in re.split("[;:]", m.group(1)) if c != ""] or ["0"]
            i = 0
            while i < len(codes):
                c = int(codes[i])
                if c == 0:
                    fg, bg, bold, rev = None, None, False, False
                elif c == 1:
                    bold = True
                elif c == 22:
                    bold = False
                elif c == 7:
                    rev = True
                elif c == 27:
                    rev = False
                elif c in (38, 48) and i + 1 < len(codes):
                    if codes[i + 1] == "2" and i + 4 < len(codes):
                        col = "#%02x%02x%02x" % tuple(int(x) for x in codes[i + 2:i + 5])
                        i += 4
                    elif codes[i + 1] == "5" and i + 2 < len(codes):
                        col = xterm256(int(codes[i + 2]))
                        i += 2
                    else:
                        col = None
                    if c == 38:
                        fg = col
                    else:
                        bg = col
                elif c == 39:
                    fg = None
                elif c == 49:
                    bg = None
                elif 30 <= c <= 37:
                    fg = BASE16[c - 30]
                elif 90 <= c <= 97:
                    fg = BASE16[c - 90 + 8]
                elif 40 <= c <= 47:
                    bg = BASE16[c - 40]
                elif 100 <= c <= 107:
                    bg = BASE16[c - 100 + 8]
                i += 1
        rows.append(row)
    while rows and not "".join(ch for ch, *_ in rows[-1]).strip():
        rows.pop()
    return rows


def render(rows, title, accent):
    cols = max((len(r) for r in rows), default=0)
    w = PAD * 2 + cols * CW
    h = BAR + PAD * 2 + len(rows) * LH
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w:.0f} {h:.0f}" width="{w:.0f}" height="{h:.0f}" role="img" aria-label="{html.escape(title)}" xml:space="preserve">',
           '<style>text{font-family:"JetBrains Mono","Fira Code","DejaVu Sans Mono",Menlo,Consolas,monospace;'
           f'font-size:{FS}px;white-space:pre}}.b{{font-weight:700}}</style>',
           f'<rect width="100%" height="100%" rx="10" fill="{DEF_BG}"/>',
           f'<rect x="0.5" y="0.5" width="{w-1:.0f}" height="{h-1:.0f}" rx="10" fill="none" stroke="#2a2a2e"/>',
           f'<rect x="1" y="1" width="{w-2:.0f}" height="{BAR-1}" rx="9" fill="#141417"/>',
           f'<rect x="1" y="{BAR-10}" width="{w-2:.0f}" height="10" fill="#141417"/>',
           f'<line x1="1" y1="{BAR}" x2="{w-1:.0f}" y2="{BAR}" stroke="#2a2a2e"/>']
    for i, col in enumerate(("#ff5f57", "#febc2e", "#28c840")):
        out.append(f'<circle cx="{PAD + 6 + i * 20}" cy="{BAR / 2}" r="6" fill="{col}" opacity=".85"/>')
    out.append(f'<text x="{w / 2:.0f}" y="{BAR / 2 + 5}" text-anchor="middle" fill="#8a8a8a">{html.escape(title)}</text>')
    top = BAR + PAD
    for y, row in enumerate(rows):
        base = top + y * LH
        # backgrounds, merged per run
        x = 0
        while x < len(row):
            b = row[x][2]
            j = x
            while j < len(row) and row[j][2] == b:
                j += 1
            if b and b != DEF_BG:
                out.append(f'<rect x="{PAD + x * CW:.1f}" y="{base:.1f}" width="{(j - x) * CW + .4:.1f}" height="{LH:.1f}" fill="{b}"/>')
            x = j
        # text runs of equal style
        x = 0
        while x < len(row):
            _, f, _, bo = row[x]
            j = x
            while j < len(row) and row[j][1] == f and row[j][3] == bo:
                j += 1
            seg = "".join(ch for ch, *_ in row[x:j])
            if seg.strip():
                cls = ' class="b"' if bo else ""
                out.append(f'<text x="{PAD + x * CW:.1f}" y="{base + LH * .74:.1f}" fill="{f or DEF_FG}"{cls} '
                           f'textLength="{(j - x) * CW:.1f}" lengthAdjust="spacingAndGlyphs">{html.escape(seg)}</text>')
            x = j
    out.append("</svg>")
    return "\n".join(out)


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("src")
    ap.add_argument("dst")
    ap.add_argument("--title", default="hyprism")
    ap.add_argument("--accent", default="#ff3b3b")
    a = ap.parse_args()
    text = sys.stdin.read() if a.src == "-" else open(a.src, encoding="utf-8", errors="replace").read()
    with open(a.dst, "w", encoding="utf-8") as fh:
        fh.write(render(parse(text), a.title, a.accent))


if __name__ == "__main__":
    main()
