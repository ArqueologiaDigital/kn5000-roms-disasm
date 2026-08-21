#!/usr/bin/env python3
"""disk_cmp_is_ic19_format.py -- are .CMP disk files the same format as the IC19 style flash?

QUESTION ANSWERED: when the instrument saves custom accompaniment styles to floppy, does it write
the same structure it keeps in the IC19 custom-data flash?

ANSWER: YES, identically. Verified on seven real KN-series floppies:

  * the 96-byte style directory sits at magic + 0x60 with the 16-char name at +0x40, exactly as
    in IC19 -- 30 records per file, carrying user content ("DON JUAN", "a-variation1", "Foxtrot 1")
  * the cells are the IC19 cell: 0x80 at +0, u16 prev at +1, u16 next at +3, 0x87 at +5 and +0xFF
  * the pointer rule is the IC19 rule -- section nibble plus a 12-bit block index RELATIVE to the
    first cell block, which comes out as 0x014, the same base as IC19 section 0
  * 1437 cells, every pointer resolving, **388 of 388 back-links agreeing**
  * **51,443 events decode with ZERO malformed** under the IC19 event grammar, unchanged

The headers differ only in magic: IC19 sections begin `48 00 4B 00` ("H.K."), .CMP files begin
`4C 4B 45 00` ("LKE"). From offset 3 onward the two headers are byte-for-byte the same shape,
`00 x7, 5A 5A 5A, 00 00 01 00 ...`.

So `docs/accompaniment-style-format.md` documents the disk format as well as the ROM one, and
anything that reads IC19 styles reads a .CMP.

    python3 scripts/analysis/disk_cmp_is_ic19_format.py <dir-with-CMP-files>

Sample disks live in KN7000/floppy-archive/*.zip (seven, six files each).
"""
import glob
import os
import sys
from collections import Counter

ARGS = {0x90: 5, 0x91: 7, 0x81: 0, 0xD1: 2, 0xD2: 2, 0xD3: 2}


def named(n):
    return bool(n) and (32 <= n[0] < 127) and all((32 <= c < 127) or c == 0 for c in n)


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else '.'
    T = Counter()
    for f in sorted(glob.glob(os.path.join(root, '**', '*.CMP'), recursive=True)):
        d = open(f, 'rb').read()
        recs = 0
        i = 0x60
        while i + 96 <= len(d) and named(d[i + 0x40:i + 0x50]):
            recs += 1
            i += 96
        cells = [o for o in range(0, len(d) - 255, 256) if d[o] == 0x80 and d[o + 5] == 0x87]
        if not cells:
            print(f"{os.path.basename(f):<20} no IC19-shaped cells")
            continue
        cs, base = set(cells), cells[0] >> 8
        res = bad = bk = chk = ev = mal = 0
        for o in cells:
            a = d[o + 1] | (d[o + 2] << 8)
            b = d[o + 3] | (d[o + 4] << 8)
            for v in (a, b):
                if v == 0xFFFF:
                    continue
                (res, bad) = (res + 1, bad) if ((v & 0xFFF) + base) * 256 in cs else (res, bad + 1)
            if b != 0xFFFF:
                t = ((b & 0xFFF) + base) * 256
                if t in cs:
                    chk += 1
                    ba = d[t + 1] | (d[t + 2] << 8)
                    if ba != 0xFFFF and ((ba & 0xFFF) + base) * 256 == o:
                        bk += 1
        for h in [o for o in cells if (d[o + 1] | (d[o + 2] << 8)) == 0xFFFF]:
            pay = bytearray()
            o, seen = h, set()
            while o is not None and o not in seen:
                seen.add(o)
                pay += d[o + 6:o + 255]
                nx = d[o + 3] | (d[o + 4] << 8)
                o = ((nx & 0xFFF) + base) * 256 if nx != 0xFFFF else None
                if o is not None and o not in cs:
                    break
            i = 0
            while i < len(pay):
                st = pay[i]
                if not (st & 0x80):
                    i += 1
                    continue
                if st == 0x83:
                    break
                n = ARGS.get(st)
                if n is None:
                    mal += 1
                    i += 1
                    continue
                run, j = 0, i + 1
                while j < len(pay) and not (pay[j] & 0x80) and run < n:
                    j += 1
                    run += 1
                (ev, mal) = (ev + 1, mal) if run == n else (ev, mal + 1)
                i = j
        print(f"{os.path.basename(f):<20} dir {recs:2d}  cells {len(cells):3d} base 0x{base:03X}  "
              f"ptr {res}/{res + bad}  back {bk}/{chk}  events {ev} malformed {mal}")
        T.update(cells=len(cells), res=res, bad=bad, bk=bk, chk=chk, ev=ev, mal=mal, dirs=recs)
    print(f"\nTOTAL  directory records {T['dirs']}  cells {T['cells']}  "
          f"pointers {T['res']}/{T['res'] + T['bad']}  back-links {T['bk']}/{T['chk']}  "
          f"events {T['ev']}  malformed {T['mal']}")
    assert T['bad'] == 0 and T['mal'] == 0 and T['bk'] == T['chk'], \
        "the IC19 rules do NOT fully describe these files -- investigate before trusting this"
    print("The IC19 style rules describe these disk files exactly.")


if __name__ == '__main__':
    main()
