#!/usr/bin/env python3
"""disk_seq_container.py -- do KN-series DISK song files use the ROM's cell container?

QUESTION ANSWERED: the .SEQ files written to floppy by the instrument, and the accompaniment
styles baked into the IC19 flash, and the demo songs in the table_data mask ROM -- are they the
same container?

ANSWER: yes, the same 256-byte cell with a 0x80 marker and two u16 fields, but with a DIFFERENT
addressing convention in each. That is worth knowing before anyone writes a reader for one of
them assuming another's rules.

    variant        marker   "none"    pointer means                      payload
    IC19 styles    0x80/0x87 0xFFFF   section nibble + block index        +0x06, 249 B
                                      RELATIVE to the section's first cell
    demo songs     0x80 only 0xFFFF   cell number, cell c at             +0x05, 251 B
                                      0x800 + (c-1)*256
    disk .SEQ      0x80 only 0x0000   plain block index within the file   +0x05, ?

Run over a directory of extracted disk files:

    python3 scripts/analysis/disk_seq_container.py <dir-with-SEQ-files>

MEASURED over 7 disks (596 cells): every one of the 1087 in-range pointers lands on a real cell.

⚠ BUT THE TWO FIELDS ARE NOT A PREV/NEXT PAIR HERE. Only 48 of 540 forward links have their
target pointing back, against 514 of 514 in the IC19 styles. Whatever the field at +1 is on disk,
it is not the reverse of the field at +3, and this script prints that ratio rather than assuming.
Each file also has exactly ONE pointer that lands outside the file.
"""
import glob
import os
import sys


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else '.'
    tot = ok = fail = back = chk = heads = 0
    for f in sorted(glob.glob(os.path.join(root, '**', '*.SEQ'), recursive=True)):
        d = open(f, 'rb').read()
        n = len(d) // 256
        cells = [i for i in range(n) if d[i * 256] == 0x80]
        cs = set(cells)
        so = sf = sb = sc = 0
        for i in cells:
            o = i * 256
            a = d[o + 1] | (d[o + 2] << 8)
            b = d[o + 3] | (d[o + 4] << 8)
            if a == 0:
                heads += 1
            for v in (a, b):
                if v in (0, 0xFFFF):
                    continue
                if v in cs:
                    so += 1
                else:
                    sf += 1
            if b not in (0, 0xFFFF) and b in cs:
                sc += 1
                if (d[b * 256 + 1] | (d[b * 256 + 2] << 8)) == i:
                    sb += 1
        print(f"{os.path.basename(f):<20} {len(d):6d} B  cells {len(cells):3d}  "
              f"resolve {so}  out-of-file {sf}  back-links {sb}/{sc}")
        tot += len(cells); ok += so; fail += sf; back += sb; chk += sc
    print(f"\nTOTAL cells {tot}  pointers in-file {ok}  out-of-file {fail}  "
          f"back-links agree {back}/{chk}  heads(field+1 == 0) {heads}")
    print("Back-links agreeing rarely => the two fields are NOT prev/next here, unlike IC19.")


if __name__ == '__main__':
    main()
