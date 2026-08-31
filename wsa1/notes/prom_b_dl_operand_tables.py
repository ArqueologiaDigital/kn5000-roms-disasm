#!/usr/bin/env python3
"""What is in the gaps BETWEEN prom_b's display lists?  The lists themselves say.

QUESTION ANSWERED
  prom_b 0xF01800-0xF3E15B is 129 spans of display-list records separated by
  .incbin gaps.  Those gaps are not padding: display-list records carry 32-bit
  pointers, and the handler that consumes each pointer also fixes the SIZE of the
  thing pointed at.  This script follows every such pointer, computes the size
  the handler implies, and reports which gaps are EXACTLY partitioned by the
  objects that point into them.

  Exact partition is the whole point.  A pointer alone proves an object starts
  there; only "the objects tile the gap end to end, with no slack" proves how big
  each one is.  That is the same argument the glyph block already uses
  (29 bitmaps x 72 bytes ending exactly where the block ends).

THE FOUR OBJECT KINDS, and where each size comes from
  interpreter A, handler 0xF31ABE (ops 03 04):
      +2 is a 32-bit pointer -> XIY, +8 -> BC, +0x0A -> HL, and the handler
      issues `swi 7` with A = the opcode = 3.  Service 3 is draw-bitmap with
      BC = width in BYTES and HL = height in rows (established in
      notes/FINDINGS-ui-display-list.md from three call sites).  SIZE = BC * HL.
  interpreter B, handlers 0xF31B21 (op 02) and 0xF31B39 (op 07):
      +7 is a 32-bit pointer -> XIY and +0x0B -> BC.  HL is the extracted
      bit-field, i.e. the ENTRY INDEX, so the object is an array of BC-byte
      entries.  The number of entries the record can ever select is
      (mask >> shift) + 1, from +4 and +5.   SIZE = BC * that.
  interpreter B, handler 0xF31B57 (ops 03 08):
      `sla 3,HL` then add to the +7 pointer  =>  8-byte entries.
  interpreter B, handler 0xF31B86 (op 04):
      `mul HL,6` then add to the +7 pointer  =>  6-byte entries.

  For the two B array kinds the entry count is again (mask >> shift) + 1.  That
  is an UPPER BOUND on the index, not a measurement of the array, so a size
  derived from it is a CANDIDATE until the partition test confirms it.

RUN
  python3 notes/prom_b_dl_operand_tables.py             # gap-by-gap verdict
  python3 notes/prom_b_dl_operand_tables.py --exact     # only the exact gaps
  python3 notes/prom_b_dl_operand_tables.py --dump 0xF031C9
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import prom_b_display_lists as DL

B_BASE = 0xF00000


def objects(b, sites, own, hta, htb):
    """{start: (size, kind, [records that point here])}, candidates only."""
    out = {}
    for p, which in own.items():
        op, ln = b[p - B_BASE], b[p - B_BASE + 1]
        d = b[p - B_BASE:p - B_BASE + ln]
        if which == {DL.RUN_B}:
            h = htb[op]
            if h not in (0xF31B21, 0xF31B39, 0xF31B57, 0xF31B86):
                continue
            ptr = int.from_bytes(d[7:11], "little")
            n = (d[4] >> (d[5] & 7)) + 1
            if h in (0xF31B21, 0xF31B39):
                esz = int.from_bytes(d[11:13], "little")
                kind = "B string table, %d x %d" % (n, esz)
            else:
                esz = 8 if h == 0xF31B57 else 6
                kind = "B %d-byte-entry array, %d entries" % (esz, n)
            size = esz * n
        else:
            h = hta[op]
            if h != 0xF31ABE:
                continue
            ptr = int.from_bytes(d[2:6], "little")
            bc = int.from_bytes(d[8:10], "little")
            hl = int.from_bytes(d[10:12], "little") if ln >= 12 else None
            if hl is None:
                continue
            size = bc * hl
            kind = "A bitmap, %d bytes x %d rows" % (bc, hl)
        if size == 0:
            continue
        out.setdefault(ptr, [size, kind, []])
        out[ptr][2].append(p)
        out[ptr][0] = max(out[ptr][0], size)
        if size > 0 and "x" in kind and size >= out[ptr][0]:
            out[ptr][1] = kind
    return out


def entry_size(kind):
    """Bytes per entry, taken back out of the kind string this script built."""
    if "string table" in kind:
        return int(kind.rsplit("x", 1)[1])
    if "byte-entry array" in kind:
        return int(kind.split()[1].split("-")[0])
    return 1                                   # a bitmap is not an array


def gaps(b, sites):
    sp = [(s, e) for s, e in DL.spans(sites) if DL.walk(b, s, e)]
    g, cur = [], 0xF01800
    for s, e in sp:
        if s > cur:
            g.append((cur, s))
        cur = max(cur, e)
    return g


def main():
    a, b = DL.load()
    sites = DL.call_sites(a, b)
    hta = [int.from_bytes(b[DL.HTBL + i * 4:DL.HTBL + i * 4 + 4], "little") for i in range(36)]
    htb = [int.from_bytes(b[0x31DB1 + i * 4:0x31DB1 + i * 4 + 4], "little") for i in range(15)]
    own = {}
    for s, e, t in sorted(sites):
        if not (B_BASE <= s < 0xF80000):
            continue
        r = DL.walk(b, s, e)
        if r is None:
            continue
        for p, op, ln in r:
            own.setdefault(p, set()).add(t)
    objs = objects(b, sites, own, hta, htb)

    if "--dump" in sys.argv:
        at = int(sys.argv[sys.argv.index("--dump") + 1], 0)
        size, kind, refs = objs[at]
        print("0x%06X  %s  %d bytes, referenced by %s"
              % (at, kind, size, ", ".join("0x%06X" % x for x in refs)))
        n = int(kind.split()[-1]) if kind.split()[-1].isdigit() else 0
        esz = size // max(1, (kind.count("x") and int(kind.split(" x ")[0].split()[-1]) or 1))
        for o in range(0, size, 8):
            raw = b[at - B_BASE + o:at - B_BASE + min(o + 8, size)]
            print("   +%04X  %-24s |%s|" % (o, " ".join("%02X" % c for c in raw),
                  "".join(chr(c) if 0x20 <= c <= 0x7E else "." for c in raw)))
        return 0

    exact = tiled = tot = 0
    for gs, ge in gaps(b, sites):
        inside = sorted((p, v) for p, v in objs.items() if gs <= p < ge)
        if not inside:
            continue
        tot += 1
        starts = [p for p, v in inside]
        extents = [(starts[i + 1] if i + 1 < len(starts) else ge) - starts[i]
                   for i in range(len(starts))]
        ok_exact = (starts[0] == gs and
                    all(v[0] == extents[i] for i, (p, v) in enumerate(inside)))
        # weaker: starts partition the gap, every extent is a whole number of
        # entries, and the LAST object's implied size is its extent exactly
        ok_tiled = (starts[0] == gs and
                    all(extents[i] % entry_size(v[1]) == 0 for i, (p, v) in enumerate(inside)) and
                    inside[-1][1][0] == extents[-1])
        if ok_exact:
            exact += 1
        elif ok_tiled:
            tiled += 1
        if ok_exact or ok_tiled or "--exact" not in sys.argv:
            tag = "EXACT " if ok_exact else ("TILED " if ok_tiled else "partial")
            print("%s gap 0x%06X-0x%06X (%d B): %d objects" % (tag, gs, ge - 1, ge - gs, len(inside)))
            for i, (p, (size, kind, refs)) in enumerate(inside):
                mark = "" if size == extents[i] else "   (implied %d, extent %d = %d entries)" % (
                    size, extents[i], extents[i] // entry_size(kind))
                print("        0x%06X +%4d  %s%s" % (p, extents[i], kind, mark))

    print("gaps with at least one pointer into them: %d ; EXACTLY tiled: %d ; "
          "tiled by starts with the last size exact: %d" % (tot, exact, tiled))
    return 0


if __name__ == "__main__":
    sys.exit(main())
