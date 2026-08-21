#!/usr/bin/env python3
"""style_cell_census.py -- the custom-data style banks' cell and event structure.

QUESTION ANSWERED: what is actually in the 639,296 bytes of IC19 style data, and how much of
the demo-preset event grammar does it share?

Answers, measured (2026-08-21):

  * CELL HEADER is 6 bytes: 80 FF FF <next u16 LE> 87. The earlier probe searched for the
    literal `80 FF FF FF FF 87` and found 725 cells; that pattern is just the subset whose
    NEXT POINTER IS 0xFFFF, i.e. the last cell of a chain. Matching the header shape instead
    finds 1050 cells -- 150 in section_0 and 300 in each of the three double sections.
  * Of section_0's 150 cells, 105 end a chain (next = 0xFFFF) and 45 point onward. The
    non-terminal pointers are values like 0x1096, 0x109A, 0x109B, 0x109D -- a high byte of 0x10
    with an incrementing low byte. THE POINTER ENCODING IS NOT DECODED: at the demo-preset rule
    of `0x800 + (c-1)*256` a cell number of 0x1096 would land far outside the section, so styles
    address cells differently (bank-relative, or a split bank/index field). That is the next
    thing to settle, and it is what a chain-following converter needs.
  * 718 of 1050 cells (68.4%) reach status 0x83, and EXACTLY 718 cells carry next = 0xFFFF.
    The two counts are computed from different fields -- one from the event stream, one from
    the header -- and they agree cell for cell across all four sections (105/206/182/225).
    That is the strongest evidence the format reading is right: only the last cell of a chain
    terminates its event stream, the other 332 straddle into their successor.
  * The event grammar is the demo-preset one (scripts/build/demo_preset_to_midi.py): a byte
    with bit 7 set is a status, following bit7-clear bytes are its arguments.

    status  args   count   meaning
    0x90       5   16,654  note: pos, note, velocity, dur_ticks, dur_beats (base 96)
    0x81       0   11,339  advance one beat
    0x91       7    5,453  NOT DECODED
    0xD2       2      958  NOT DECODED
    0xD3       2      576  NOT DECODED
    0xD1       2      100  NOT DECODED
    0x83       -      718  end of chain

    The stray low-argument-count 0x90s (3, 2, 1, 4 args: 47/43/35/32) are events cut off at a
    cell boundary; they resolve once chains are followed rather than cells read in isolation.

    python3 scripts/analysis/style_cell_census.py
"""
import pathlib
from collections import Counter

REPO = pathlib.Path(__file__).resolve().parent.parent.parent
SECTIONS = ['section_0', 'section_1_2', 'section_3_4', 'section_5_6']


def main():
    tot = framed = 0
    stat, argc = Counter(), Counter()
    for sec in SECTIONS:
        d = (REPO / 'custom_data' / 'includes' / f'{sec}.bin').read_bytes()
        n = 0
        for off in range(0, len(d) - 255, 256):
            b = d[off:off + 256]
            if not (b[0] == 0x80 and b[1] == 0xFF and b[2] == 0xFF and b[5] == 0x87):
                continue
            n += 1
            cur, k = None, 0
            for by in b[6:]:
                if by & 0x80:
                    if cur is not None:
                        argc[(cur, k)] += 1
                    cur, k = by, 0
                    stat[by] += 1
                    if by == 0x83:
                        framed += 1
                        break
                else:
                    k += 1
        cells = [off for off in range(0, len(d) - 255, 256)
                 if d[off] == 0x80 and d[off+1] == 0xFF and d[off+2] == 0xFF and d[off+5] == 0x87]
        ends = sum(1 for o in cells if d[o+3] == 0xFF and d[o+4] == 0xFF)
        print(f"{sec:<14} {n:>5} cells   chain ends {ends}   chained {len(cells) - ends}")
        tot += n
    print(f"\ntotal cells {tot}, {framed} reach 0x83 ({100.0 * framed / tot:.1f}%)")
    print("status census:", [(hex(s), c) for s, c in stat.most_common()])
    print("(status, argcount):", [(hex(s), k, c) for (s, k), c in argc.most_common(8)])


if __name__ == '__main__':
    main()
