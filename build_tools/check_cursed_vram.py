#!/usr/bin/env python3
"""Run after build.lua to verify SS interface VRAM against actual asset sizes."""
from pathlib import Path
import re
root = Path(__file__).resolve().parents[1]
listing = (root / 'sonic.lst').read_text(errors='replace')
source = (root / 'sonic.asm').read_text()
def symbol(name):
    hits = re.findall(r'\b' + re.escape(name) + r'\s*:\s*([0-9A-F]+)\s+[-C]', listing)
    assert hits, f'Missing assembled symbol: {name}'
    return int(hits[-1], 16)
def overlap(a, b):
    return a[0] < b[1] and b[0] < a[1]
plc = (root / '_inc/Pattern Load Cues.asm').read_text().split('PLC_SpecialStage:\tplcheader')[1].split('PLC_SpecialStage_end:')[0]
occupied = []
for art, dest in re.findall(r'plcm\s+(\w+),\s*(\w+)', plc):
    path = re.search(r'^' + art + r':\s*binclude\s+"([^"]+)"', source, re.M).group(1)
    count = int.from_bytes((root / path).read_bytes()[:2], 'big') & 0x7FFF
    start = symbol(dest) * 32
    occupied.append((start, start + count * 32, art))
# Conservatively reserve every map byte; never reclaim the original art islands.
occupied += [(0x4000, 0xF000, 'background maps'),
             (symbol('vram_sprites'), symbol('vram_sprites') + 80 * 8, 'sprite DMA'),
             (symbol('vram_hscroll'), symbol('vram_hscroll') + symbol('v_hscrolltablebuffer_end') - symbol('v_hscrolltablebuffer'), 'scroll DMA'),
             (symbol('ArtTile_Sonic') * 32, symbol('ArtTile_Sonic') * 32 + 23 * 32, 'Sonic DMA')]
low, high = [symbol(n) * 32 for n in ('ArtTile_SS_TimerLow', 'ArtTile_SS_TimerHigh')]
timer = [(low, low + 12 * 32, 'timer glyph slots 0-5'), (high, high + 4 * 32, 'timer glyph slots 6-7')]
for a in timer:
    for b in occupied:
        assert not overlap(a, b), (a, b)
assert not overlap(*timer)
assert high + 4 * 32 <= 0x10000
assert any(x[2] == 'Nem_Ring' for x in occupied), 'Rings must be included in the live art audit'
font, note, panel = [symbol(n) * 32 for n in ('ArtTile_SS_PauseFont', 'ArtTile_SS_PauseNote', 'ArtTile_SS_PausePanel')]
pause = [(font, font + 46 * 32, 'pause font/divider/question'), (note, note + 16 * 32, 'pause note'), (panel, panel + 16 * 32, 'confirmation panel')]
wall = next(x for x in occupied if x[2] == 'Nem_SSWalls')
assert len((root / 'artunc/Level Select & Debug Text.unc').read_bytes()) == 41 * 32
for i, a in enumerate(pause):
    assert wall[0] <= a[0] < a[1] <= wall[1]
    for b in occupied + timer:
        if b != wall:
            assert not overlap(a, b), (a, b)
    for b in pause[i + 1:]:
        assert not overlap(a, b)
clock = (root / '_inc/Cursed Run Timer.asm').read_text()
interface = (root / '_inc/Cursed Emerald Interface.asm').read_text()
menu = (root / '_inc/PauseGame.asm').read_text()
assert clock.count('bsr.w\tSS_LoadTimerMapped') == 2
assert interface.count('bsr.w\tSS_LoadTimerMapped') == 1
resume = menu.split('.spriteContinue:')[1].split('.spriteRestartStage:')[0]
assert resume.index('SS_RestorePauseWallArt') < resume.index('clr.w\t(f_pause)')
restore = interface.split('SS_RestorePauseWallArt:')[1]
assert 'ArtTile_SS_Wall*tile_size' in restore and '(Nem_SSWalls)' in restore and 'bsr.w\tNemDec' in restore
for start, end, name in timer + pause:
    print(f'{start:04X}-{end - 1:04X}: {name}')
print('PASS: no interface overlap with background maps, other live art, or DMA; pause wall art has a restore path.')
