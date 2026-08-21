#!/usr/bin/env python3
"""L5 TEST: reimplement the style reader from docs/accompaniment-style-format.md ALONE.

Deliberately shares no code with scripts/build/style_events.py. Everything below is written
only from what the document states, to test the spec's claim that an outsider could do so.
"""
import sys

ROM = sys.argv[1]                      # original_ROMs/kn5000_custom_data.ic19, the 1MB at 0x300000
d = open(ROM, 'rb').read()

# "eight style banks, each announced by an H\0K\0 magic on a 0x100 boundary" at these addresses
SECTION_ADDRS = [0x300000, 0x319800, 0x330000, 0x349800, 0x360000, 0x379800, 0x390000, 0x3B0000]
BASE = 0x300000

# "A cell is recognised by byte[0] == 0x80 && byte[5] == 0x87"
def is_cell(o):
    return o + 256 <= len(d) and d[o] == 0x80 and d[o + 5] == 0x87

# "status ... args" table from the Event grammar section
ARGS = {0x90: 5, 0x91: 7, 0x81: 0, 0xD1: 2, 0xD2: 2, 0xD3: 2}

cells_total = chains_total = events_total = malformed = 0
names = []
for k, addr in enumerate(SECTION_ADDRS):
    start = addr - BASE
    end = (SECTION_ADDRS[k + 1] - BASE) if k + 1 < len(SECTION_ADDRS) else len(d)
    if d[start:start + 4] != b'H\x00K\x00':
        continue
    # "At magic + 0x60, thirty records of 96 bytes ... +0x40 16 B style name"
    for r in range(30):
        rec = start + 0x60 + r * 96
        nm = d[rec + 0x40:rec + 0x50]
        if nm and 32 <= nm[0] < 127:
            names.append(nm.decode('latin1').rstrip('\x00 '))
    cells = [o for o in range(start, end - 255, 256) if is_cell(o)]
    if not cells:
        continue
    cells_total += len(cells)
    first_block = cells[0] >> 8            # "first_cell_block_of_section"
    cs = set(cells)
    # "PREV cell, 0xFFFF at a chain head"
    for h in [o for o in cells if (d[o + 1] | (d[o + 2] << 8)) == 0xFFFF]:
        chains_total += 1
        pay = bytearray()
        o, seen = h, set()
        while o is not None and o not in seen:
            seen.add(o)
            pay += d[o + 6:o + 255]        # "+0x06 249 B payload"
            nxt = d[o + 3] | (d[o + 4] << 8)
            # "target_block = (value & 0x0FFF) + first_cell_block_of_section"
            o = ((nxt & 0x0FFF) + first_block) * 256 if nxt != 0xFFFF else None
            if o is not None and o not in cs:
                break
        # "a byte with bit 7 SET is a status; the bytes after it with bit 7 CLEAR are its arguments"
        i = 0
        while i < len(pay):
            st = pay[i]
            if not (st & 0x80):
                i += 1
                continue
            if st == 0x83:                 # "0x83 END - end of the chain's stream"
                break
            n = ARGS.get(st)
            if n is None:
                malformed += 1
                i += 1
                continue
            run, j = 0, i + 1
            while j < len(pay) and not (pay[j] & 0x80) and run < n:
                j += 1
                run += 1
            if run != n:
                malformed += 1
            else:
                events_total += 1
            i = j

print(f"cells   {cells_total}")
print(f"chains  {chains_total}")
print(f"events  {events_total}   malformed {malformed}")
print(f"names   {len(names)}  e.g. {names[:3]}")
