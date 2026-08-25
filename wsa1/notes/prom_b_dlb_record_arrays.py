#!/usr/bin/env python3
"""Is the unconverted region above 0xF13D34 made of INTERPRETER-B RECORD ARRAYS?

QUESTION IT ANSWERS
  notes/FINDINGS-prom_b-f0ea9f-module.md sec.5 says the region cannot be framed
  with scripts/analysis/prom_b_display_lists.py, because that tool finds a list's
  ENDS from `ld XIY,start / ld XIX,end` call sites and these lists have no such
  call site.  This is the evidence for what to do instead.

  The block at 0xF0EA9F-0xF13D33 contains two instructions that hand a computed
  address to interpreter B ONE RECORD AT A TIME:

      0xF110B9   add XBC,0x00f157a8 / push XBC / call 0xf42e0c
      0xF11154   add XBC,0x00f15820 / push XBC / call 0xf42e0c

  and T_F42E0C is `jp DisplayListB_RunOne_Stack` (prom_b 0xF3183D), already
  converted and already named in prom_b/wsa1_prom_b.s.  So the region holds
  ARRAYS of interpreter-B records addressed by index, and the framing argument
  that IS available is: walk the length bytes from the array base and require the
  walk to consume whole records and stop on a boundary another base also reaches.

WHAT IT MEASURES
  From each named base, walk records by the length byte at +1 (interpreter B's
  own rule) and report how many records, which opcodes, and where the walk ends.
  Two bases that end at the SAME address are two entry points into one array,
  which is what an index-addressed array looks like from two call sites.

WHY IT ALSO MATTERS FOR sec.2.4
  0xF15B03 is one of the runs round 4's `selfconsistent()` rule would have called
  CODE.  It walks as EIGHT interpreter-B records.  That is an independent second
  reason -- not the tail rule -- to believe the demotion was right.

RUN
  python3 notes/prom_b_dlb_record_arrays.py
Exit status is non-zero if a walk fails to produce whole records.
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IMG = os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13")
B_BASE = 0xF00000
LIMIT = 0xF18000
BASES = [(0xF157A8, "pushed at 0xF110B9"),
         (0xF15820, "pushed at 0xF11154"),
         (0xF15B03, "a run round 4's rule would have called CODE")]
B_BOUND = 0x0F                      # interpreter B's opcode bound (0xF31AF0)


def walk(d, a):
    p, recs, ops = a, [], {}
    while p < LIMIT:
        op, ln = d[p - B_BASE], d[p + 1 - B_BASE]
        if ln == 0 or op >= B_BOUND or p + ln > LIMIT:
            break
        ops[op] = ops.get(op, 0) + 1
        recs.append((p, op, ln))
        p += ln
    return p, recs, ops


def main():
    d = open(IMG, "rb").read()
    ends, bad = {}, 0
    for a, why in BASES:
        e, recs, ops = walk(d, a)
        if not recs:
            bad += 1
        ends.setdefault(e, []).append(a)
        print("0x%06X (%s):" % (a, why))
        print("   %d records, all opcode %s, %d bytes each, walk ends at 0x%06X"
              % (len(recs), "/".join("0x%02X" % o for o in sorted(ops)),
                 recs[0][2] if recs else 0, e))
    for e, srcs in sorted(ends.items()):
        if len(srcs) > 1:
            print("⚠ %s end at the SAME address 0x%06X, and their bases differ by "
                  "%d = %d records: two entry points into ONE array."
                  % (" and ".join("0x%06X" % s for s in srcs), e,
                     max(srcs) - min(srcs),
                     (max(srcs) - min(srcs)) // walk(d, min(srcs))[1][0][2]))
    print("\n%s" % ("PASS" if not bad else "FAIL: %d base(s) walked 0 records"
                    % bad))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
