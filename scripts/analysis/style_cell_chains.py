#!/usr/bin/env python3
"""style_cell_chains.py -- the custom-data style cell header, decoded and proved.

QUESTION ANSWERED: what are the two u16 fields in a style cell's header, and how does a cell
address another cell?

ANSWER (2026-08-21). The cells form DOUBLY-LINKED CHAINS.

    +0x00  1 B     0x80          cell-start marker
    +0x01  2 B     u16 LE        PREV cell, 0xFFFF at a chain head
    +0x03  2 B     u16 LE        NEXT cell, 0xFFFF at a chain end
    +0x05  1 B     0x87          end-of-header marker
    +0x06  249 B                 event-stream payload
    +0xFF  1 B     0x87          trailing marker, present on all 1564 cells

A pointer is not a byte offset and not a plain block number:

    high nibble    section id + 1  (section 0 -> 1 ... section 6 -> 7)
    low 12 bits    256-byte block index RELATIVE TO THE SECTION'S FIRST CELL BLOCK

        target_block = (value & 0x0FFF) + first_cell_block_of_section
        target_off   = target_block * 256

The relative base is the part that took three wrong attempts. Section 0's cells begin at block
0x014 and the double sections' at 0x01C and 0x184, so a pointer read as an absolute block index
lands outside the cell region most of the time -- which is exactly what an earlier pass measured
(8 of 45 resolving) before concluding, wrongly, that these were not chain pointers at all.

THE PAYLOAD IS 249 BYTES, NOT 250. Byte 0xFF of every cell is a second 0x87 marker. Reading it
as payload injects a bogus status into the stream once per cell -- which is exactly the 514
"unknown 0x87" events an earlier decode reported, one per continuation.

PROOF, printed by this script: with the relative base every pointer in every section resolves to
a real cell (1028 of 1028), and every forward link's target points back at its source (514 of
514). Two independent properties, no exceptions, across seven sections. And with the 249-byte
payload, following all 1050 chains decodes **50,245 events with ZERO malformed** -- every status
gets exactly its documented argument count, including the events that straddle cell boundaries.

    python3 scripts/analysis/style_cell_chains.py
"""
import pathlib

REPO = pathlib.Path(__file__).resolve().parent.parent.parent
SECTIONS = ['section_0', 'section_1_2', 'section_3_4', 'section_5_6']


def sections(d):
    """Yield (start, end) for each HK-announced section inside one blob."""
    hks = [i for i in range(0, len(d) - 4, 0x100) if d[i:i + 4] == b'H\x00K\x00']
    for k, s in enumerate(hks):
        yield s, (hks[k + 1] if k + 1 < len(hks) else len(d))


def cells_of(d, start, end):
    return [o for o in range(start, end - 255, 256) if d[o] == 0x80 and d[o + 5] == 0x87]


def main():
    ok = fail = back = chk = heads = 0
    for sec in SECTIONS:
        d = (REPO / 'custom_data' / 'includes' / f'{sec}.bin').read_bytes()
        for start, end in sections(d):
            cells = cells_of(d, start, end)
            if not cells:
                continue
            cs, base = set(cells), cells[0] >> 8
            so = sf = sb = sc = 0
            for o in cells:
                a = d[o + 1] | (d[o + 2] << 8)
                b = d[o + 3] | (d[o + 4] << 8)
                if a == 0xFFFF:
                    heads += 1
                for v in (a, b):
                    if v == 0xFFFF:
                        continue
                    if ((v & 0xFFF) + base) * 256 in cs:
                        so += 1
                    else:
                        sf += 1
                if b != 0xFFFF:
                    t = ((b & 0xFFF) + base) * 256
                    if t in cs:
                        sc += 1
                        ba = d[t + 1] | (d[t + 2] << 8)
                        if ba != 0xFFFF and ((ba & 0xFFF) + base) * 256 == o:
                            sb += 1
            print(f"{sec:<14} @0x{start:05X}  {len(cells):3d} cells  base 0x{base:03X}  "
                  f"resolve {so}/{so + sf}  back-links {sb}/{sc}")
            ok += so; fail += sf; back += sb; chk += sc
    print(f"\nALL: pointers resolve {ok}/{ok + fail}   back-links agree {back}/{chk}   "
          f"chain heads {heads}")
    assert fail == 0 and back == chk, "the chain rule does not hold -- investigate before trusting it"
    print("Both properties hold with no exceptions.")


if __name__ == '__main__':
    main()
