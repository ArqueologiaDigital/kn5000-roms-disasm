#!/usr/bin/env python3
"""unreached_naka_spans.py -- what are the NAKA spans the nakarest headers call "nothing points into"?

QUESTION THIS ANSWERS
  nakarest headers say, for 22 spans of v10, "purpose not established: N B at 0xADDR that no
  registered NAKA table, symbol, 24/32-bit literal or data word points into".  The claims
  review (items 39, 40 of open_items_2026-10-02.json) found two of them inside registered
  tables after all.  For every such header in a tree this prints what the registered tables
  (scripts/analysis/nakarest_objtab_map.py's Map) say about the span:
    * CLASSDEF  -- inside a Class table: entry k, byte offset o (a class definition whose
                   first o bytes -- its proc word -- end the previous blob);
    * TERMINATOR-- at table + 4*count of a pointer table, and the word there points just past
                   itself at an "" (00 ff): the table's empty-string terminator entry;
    * RECORD-TAIL -- inside a registered widget record (record start + class allsize);
    * else the bytes, for a person to read.

USAGE
  make all
  python3 notes/lanes/wave2-2026-09-25/claims-review/probes/unreached_naka_spans.py [v10|v9|v7]
"""
import glob
import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), *[".."] * 5))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
import nakarest_objtab_map as nom  # noqa: E402

HDR = re.compile(r'purpose not established: (\d+) B at (0x[0-9a-f]+) that no registered')


def main():
    v = sys.argv[1] if len(sys.argv) > 1 else "v10"
    m = nom.Map(v)
    spans = []
    for f in sorted(glob.glob(os.path.join(ROOT, v, "maincpu", "**", "*.s"), recursive=True)):
        for i, l in enumerate(open(f, "rb").read().decode("latin-1").split("\n")):
            h = HDR.search(l)
            if h:
                spans.append((int(h.group(2), 16), int(h.group(1)), "%s:%d" % (os.path.relpath(f, ROOT), i + 1)))
    records = []
    for r in m.regs:
        if nom.CLASS.get(r["cls"]) == "Viewable":
            for k, e in enumerate(m.entries(r)):
                c = m.record_class(e) if m.inrom(e) else None
                if c:
                    records.append((e, c["allsize"], r, k, c["name"]))
    for a, n, where in sorted(spans):
        out = []
        for r in m.regs:
            name = nom.CLASS.get(r["cls"])
            if not name or not m.inrom(r["table"]):
                continue
            esz = 24 if name == "Class" else 4
            T, cnt = r["table"], r["count"]
            if T <= a < T + esz * cnt:
                k, o = divmod(a - T, esz)
                if name == "Class":
                    c = m.classes.get(((r["slot"] & 0xFFF) << 16) | k)
                    out.append("CLASSDEF entry %d (+%d) of Class slot 0x%X (table 0x%06X, %d entries, %s): %s"
                               % (k, o, r["slot"], T, cnt, r["init"], c["name"] if c else "?"))
                else:
                    out.append("inside %s slot 0x%X table 0x%06X: entry %d +%d" % (name, r["slot"], T, k, o))
            if esz == 4 and a == T + 4 * cnt:
                p = m.u32(a)
                tail = m.rom[p - nom.BASE:p - nom.BASE + 2] if m.inrom(p) else b""
                out.append("%s %s slot 0x%X (table 0x%06X, %d entries, %s): word -> 0x%06X %r"
                           % ("TERMINATOR of" if p == a + 4 and tail == b"\0\xff" else "just after",
                              name, r["slot"], T, cnt, r["init"], p, tail))
        for e, sz, r, k, cn in records:
            if e < a < e + sz:
                out.append("RECORD-TAIL of element %d of Viewable slot 0x%X (record 0x%06X, %s, %d B): +%d"
                           % (k, r["slot"], e, cn, sz, a - e))
        print("0x%06X %4d B  %s" % (a, n, where))
        for o in out or ["(no registered table) bytes " + m.rom[a - nom.BASE:a - nom.BASE + min(n, 24)].hex(" ")]:
            print("    " + o)
    return 0


if __name__ == "__main__":
    sys.exit(main())
