#!/usr/bin/env python3
"""Regenerate Special Stage zone themes from the project's current zone palettes.
Original zone and SS palettes are never changed. Outputs are ordinary palette .bin files.
"""
from pathlib import Path
import colorsys
ROOT = Path(__file__).resolve().parents[1]
PAL = ROOT / 'palette'
ZONES = ['Green Hill Zone', 'Labyrinth Zone', 'Marble Zone', 'Star Light Zone', 'Spring Yard Zone', 'SBZ Act 1']
def read(name):
    b = (PAL / (name + '.bin')).read_bytes()
    return [int.from_bytes(b[i:i+2], 'big') for i in range(0, len(b), 2)]
def rgb(v):
    return ((v & 14)/14, ((v >> 4) & 14)/14, ((v >> 8) & 14)/14)
def match(v, choices):
    r, g, b = rgb(v)
    h, s, brightness = colorsys.rgb_to_hsv(r, g, b)
    def distance(c):
        cr, cg, cb = rgb(c)
        ch, cs, cv = colorsys.rgb_to_hsv(cr, cg, cb)
        hue = min(abs(h-ch), 1-abs(h-ch))
        # Preserve hue families for colored art, lightness for neutral shading.
        return (2.8*hue*hue*min(s, cs) + .7*(s-cs)**2 + 1.5*(brightness-cv)**2
                + .15*((r-cr)**2+(g-cg)**2+(b-cb)**2))
    return min(choices, key=distance)
base = read('Special Stage')
cycles = [read('Cycle - Special Stage 1'), read('Cycle - Special Stage 2')]
out = PAL / 'Special Stage Zones'
out.mkdir(exist_ok=True)
for i, zone in enumerate(ZONES, 1):
    colors = read(zone)
    assert len(colors) == 48
    choices = sorted(set(colors))
    mapped = [match(v, choices) for v in base]
    # Player/HUD palette keeps original neutral grays and Sonic's blue/red ramps.
    mapped[:16] = base[:16]
    # Each original zone's second line supplies its main background/sky color.
    for slot in [16, 32, 48]:
        mapped[slot] = colors[16]
    # Preserve readable black/white outlines on stage objects.
    for line in [1, 2, 3]:
        mapped[line*16+1] = match(0x000, choices)
    variants = [('Base', mapped)] + [('Cycle '+str(n+1), [match(v, choices) for v in cyc]) for n, cyc in enumerate(cycles)]
    for suffix, data in variants:
        (out / f'{i} - {suffix}.bin').write_bytes(b''.join(v.to_bytes(2, 'big') for v in data))
    print(f'Stage {i}: {zone}; sky ${colors[16]:03X}')
