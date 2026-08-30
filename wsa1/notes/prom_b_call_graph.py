#!/usr/bin/env python3
"""Which prom_b routines are reachable, heavily referenced, and STILL .incbin?

QUESTION ANSWERED
  Conversion is supposed to proceed by REACHABILITY, not by address order.  This
  script answers "what should be converted next" mechanically:

    1. read every `jp` slot of the thunk table at 0xF40000-0xF44017 (the routine
       directory -- see FINDINGS-prom_b-thunk-table.md);
    2. rank each slot by an OPCODE-ANCHORED upper bound on its references, the
       same measure scripts/analysis/prom_b_thunk_table.py --census uses:
       occurrences of `1D lo mid hi` (call nnn) and `1B lo mid hi` (jp nnn)
       anywhere in prom_a+prom_b whose operand is that slot;
    3. parse prom_b/wsa1_prom_b.s's `.incbin` directives to learn exactly which
       file offsets are still unconverted;
    4. print the slots whose TARGET is in prom_b and still inside an .incbin.

WHAT A NUMBER HERE IS AND IS NOT
  The reference counts are an UPPER BOUND and rank slots only -- the scan is at
  every byte offset, not at instruction boundaries, so some hits are bytes inside
  another instruction or inside display-list data.  Never quote one as a call
  count.  What IS exact is the converted/unconverted split: it is read from the
  .s's own .incbin directives, which the build gate re-checks byte for byte.

RUN
  python3 notes/prom_b_call_graph.py                 # top unconverted targets
  python3 notes/prom_b_call_graph.py --n 60
  python3 notes/prom_b_call_graph.py --covered       # what IS converted
  python3 notes/prom_b_call_graph.py --callees ADDR  # thunk slots called by the
                                                     # 200 bytes at ADDR
Exit status is non-zero if a self-check fails.
"""
import collections
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
B_BASE = 0xF00000
A_BASE = 0xF80000
TBL_LO, TBL_HI = 0x40000, 0x44018          # file offsets into prom_b, [lo, hi)
SRC = image_path(ROOT, "prom_b/wsa1_prom_b.s")

FAIL = []


def check(msg, cond):
    print("  %-58s %s" % (msg, "ok" if cond else "FAIL"))
    if not cond:
        FAIL.append(msg)


def load():
    r = lambda n: open(os.path.join(ROOT, "original_ROMs", n), "rb").read()
    return r("wsa1_prom_a.ic12"), r("wsa1_prom_b.ic13")


def incbin_ranges():
    """[(lo, hi)] file-offset ranges still .incbin in prom_b/wsa1_prom_b.s."""
    pat = re.compile(r'\.incbin\s+"[^"]*wsa1_prom_b\.ic13"\s*,\s*(0x[0-9A-Fa-f]+)\s*,'
                     r'\s*(0x[0-9A-Fa-f]+)')
    out = []
    for line in open(SRC, encoding="utf-8"):
        m = pat.search(line)
        if m:
            o, n = int(m.group(1), 16), int(m.group(2), 16)
            out.append((o, o + n))
    return sorted(out)


def is_incbin(ranges, off):
    for lo, hi in ranges:
        if lo <= off < hi:
            return True
    return False


def jp_slots(b):
    """{slot_addr: target} for every `jp nnn` slot of the thunk table."""
    out = {}
    for o in range(TBL_LO, TBL_HI, 4):
        s = b[o:o + 4]
        if s[0] == 0x1B and 0xF0 <= s[3] <= 0xFF:
            out[B_BASE + o] = s[1] | s[2] << 8 | s[3] << 16
    return out


def refcounts(a, b):
    """Opcode-anchored upper bound on references to each thunk slot address."""
    cnt = collections.Counter()
    for blob in (a, b):
        n = len(blob)
        for i in range(n - 3):
            if blob[i] in (0x1D, 0x1B):
                t = blob[i + 1] | blob[i + 2] << 8 | blob[i + 3] << 16
                if B_BASE + TBL_LO <= t < B_BASE + TBL_HI and t % 4 == 0:
                    cnt[t] += 1
    return cnt


def main():
    a, b = load()
    ranges = incbin_ranges()
    slots = jp_slots(b)
    cnt = refcounts(a, b)

    covered = 0x80000 - sum(hi - lo for lo, hi in ranges)
    print("prom_b: %d bytes converted, %d still .incbin in %d spans"
          % (covered, 0x80000 - covered, len(ranges)))
    print("thunk table: %d `jp` slots" % len(slots))
    print()

    if "--covered" in sys.argv:
        prev = 0
        print("converted spans (file offsets / CPU addresses):")
        for lo, hi in ranges:
            if lo > prev:
                print("   0x%05X-0x%05X   0x%06X-0x%06X   %d bytes"
                      % (prev, lo - 1, B_BASE + prev, B_BASE + lo - 1, lo - prev))
            prev = hi
        if prev < 0x80000:
            print("   0x%05X-0x7FFFF   0x%06X-0xF7FFFF   %d bytes"
                  % (prev, B_BASE + prev, 0x80000 - prev))
        print()

    if "--callees" in sys.argv:
        at = int(sys.argv[sys.argv.index("--callees") + 1], 16)
        o = at - B_BASE
        print("thunk slots referenced in prom_b 0x%06X..0x%06X:" % (at, at + 0x200))
        seen = collections.Counter()
        for i in range(o, min(o + 0x200, len(b) - 3)):
            if b[i] in (0x1D, 0x1B):
                t = b[i + 1] | b[i + 2] << 8 | b[i + 3] << 16
                if B_BASE + TBL_LO <= t < B_BASE + TBL_HI and t % 4 == 0:
                    seen[t] += 1
        for t, k in sorted(seen.items()):
            tgt = slots.get(t)
            print("   T_%06X x%-3d -> %s" % (t, k,
                  "0x%06X" % tgt if tgt else "(not a jp slot)"))
        return 1 if FAIL else 0

    n = 40
    if "--n" in sys.argv:
        n = int(sys.argv[sys.argv.index("--n") + 1])

    rows = []
    for slot, tgt in slots.items():
        if not (B_BASE <= tgt < A_BASE):
            continue                                   # prom_a target, other lane
        if not is_incbin(ranges, tgt - B_BASE):
            continue                                   # already converted
        rows.append((cnt.get(slot, 0), slot, tgt))
    rows.sort(reverse=True)

    # ⚠ STATE THE UNIT.  `rows` is one row per SLOT, and two slots can name the
    #    same routine, so len(rows) is a SLOT count and not a target count.  This
    #    header said "targets" until 2026-08-25, and the difference is not
    #    academic: converting 0xF44018-0xF477FF retired 64 slots resolving to 62
    #    distinct targets, and a reconciliation done in the wrong unit is off by
    #    two with nothing to show why.
    ntgt = len(set(t for _, _, t in rows))
    print("UNCONVERTED prom_b thunk SLOTS, by reference upper bound (top %d of %d "
          "slots, %d distinct targets)" % (min(n, len(rows)), len(rows), ntgt))
    print("   %-12s %5s  %-10s" % ("slot", "refs", "target"))
    for k, slot, tgt in rows[:n]:
        print("   T_%06X   x%-4d  0x%06X" % (slot, k, tgt))
    print()

    print("self-checks")
    check("thunk table region itself is NOT .incbin",
          not is_incbin(ranges, TBL_LO) and not is_incbin(ranges, TBL_HI - 4))
    check("known-converted 0xF31A09 (DisplayList_Run) reads as converted",
          not is_incbin(ranges, 0x31A09))
    check("known-unconverted 0xF00000 reads as unconverted",
          is_incbin(ranges, 0x00000))
    check("every reported target really is inside an .incbin",
          all(is_incbin(ranges, t - B_BASE) for _, _, t in rows))
    # Compare against the COMMITTED measure, not against a literal.  A frozen
    # number here would go stale on the next conversion and start failing for
    # the wrong reason; what matters is that the two parsers agree.
    sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
    import source_coverage
    sc = source_coverage.measure("b")[0]
    check("converted total agrees with scripts/analysis/source_coverage.py "
          "(%d)" % sc, covered == sc)
    return 1 if FAIL else 0


if __name__ == "__main__":
    sys.exit(main())
