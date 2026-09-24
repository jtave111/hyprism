#!/usr/bin/env python3
"""palettes-svg — draw every palette in palettes/*.env as a card grid.

    tools/palettes-svg.py palettes docs/assets/palettes.svg

Each card is the palette itself: its background, a mock window border in
the accent, text in fg/dim, and the swatches Hyprism uses.
"""
import glob
import html
import os
import sys

COLS, CW, CH, GAP, PAD = 3, 300, 112, 14, 20
FONT = '"JetBrains Mono","Fira Code","DejaVu Sans Mono",Menlo,Consolas,monospace'


def load(path):
    d = {}
    for line in open(path, encoding="utf-8"):
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            k, v = line.split("=", 1)
            d[k.strip()] = v.strip()
    return d


def main(src, dst):
    pals = []
    for p in sorted(glob.glob(os.path.join(src, "*.env"))):
        name = os.path.basename(p)[:-4]
        if name.startswith("sddm-"):          # internal login-screen variant
            continue
        pals.append((name, load(p)))
    rows = (len(pals) + COLS - 1) // COLS
    w = PAD * 2 + COLS * CW + (COLS - 1) * GAP
    h = PAD * 2 + rows * CH + (rows - 1) * GAP
    o = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}" role="img" aria-label="Hyprism palettes">',
         f'<style>text{{font-family:{FONT}}}</style>',
         f'<rect width="100%" height="100%" rx="12" fill="#0c0c0e"/>']
    for i, (name, c) in enumerate(pals):
        x = PAD + (i % COLS) * (CW + GAP)
        y = PAD + (i // COLS) * (CH + GAP)
        bg, bg2, fg = c.get("bg", "#111"), c.get("bg2", "#222"), c.get("fg", "#ddd")
        dim, acc, lit = c.get("dim", "#888"), c.get("accent", "#888"), c.get("accent_lit", "#aaa")
        sel, line = c.get("sel", "#333"), c.get("line", "#333")
        o.append(f'<rect x="{x}" y="{y}" width="{CW}" height="{CH}" rx="8" fill="{bg}" stroke="{line}"/>')
        o.append(f'<rect x="{x+10}" y="{y+10}" width="{CW-20}" height="54" rx="5" fill="{bg2}" stroke="{acc}" stroke-width="2"/>')
        o.append(f'<text x="{x+22}" y="{y+32}" font-size="14" font-weight="700" fill="{fg}">{html.escape(name)}</text>')
        o.append(f'<text x="{x+22}" y="{y+52}" font-size="11.5" fill="{dim}">one palette → the whole desktop</text>')
        for j, col in enumerate((bg, bg2, sel, dim, fg, acc, lit)):
            o.append(f'<rect x="{x+10+j*40}" y="{y+76}" width="34" height="24" rx="4" fill="{col}" stroke="{line}"/>')
    o.append("</svg>")
    open(dst, "w", encoding="utf-8").write("\n".join(o))


if __name__ == "__main__":
    main(*(sys.argv[1:3] if len(sys.argv) >= 3 else ("palettes", "docs/assets/palettes.svg")))
