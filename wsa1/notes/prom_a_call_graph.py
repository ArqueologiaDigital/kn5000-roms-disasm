#!/usr/bin/env python3
"""Which prom_a routines are published, heavily referenced, and STILL .incbin?

QUESTION ANSWERED
  `notes/prom_b_call_graph.py` computes exactly this ranking and then throws away
  every prom_a answer -- its rows loop carries the line

      if not (B_BASE <= tgt < A_BASE): continue   # prom_a target, other lane

  so the prom_a lane had no frontier tool of its own and was choosing targets by
  eye.  This is the mirror image of that script, and it deliberately shares its
  method so the two numbers are comparable:

    1. read every `jp nnn` slot of the routine directory at prom_b 0xF40000-0xF44017
       (FINDINGS-prom_b-thunk-table.md) -- the WSA1 publishes CPU 1's routines to
       CPU 1's own upper half through that one table;
    2. rank each slot by an OPCODE-ANCHORED upper bound on its references: every
       occurrence of `1D lo mid hi` (call nnn) or `1B lo mid hi` (jp nnn) anywhere
       in prom_a+prom_b whose 24-bit operand is that slot address;
    3. parse prom_a/wsa1_prom_a.s's `.incbin` directives for what is still
       unconverted;
    4. print the slots whose TARGET is in prom_a (>= 0xF80000) and still .incbin.

  `--modules` groups the surviving slots the way notes/prom_b_thunk_modules.py
  groups them -- runs of consecutive table slots -- and sorts by TOTAL references
  rather than by slot count, because a module is the unit worth converting and a
  span of 2 KB reached by 126 slots is not the same target as one reached by 3.

WHAT A NUMBER HERE IS AND IS NOT
  The reference counts are an UPPER BOUND and rank slots only.  The scan is at every
  byte offset, not at instruction boundaries, so some hits are bytes lying inside
  another instruction or inside display-list data.  Never quote one as a call count.
  What IS exact is the converted/unconverted split: it is read from the .s's own
  .incbin directives, which the byte gate re-checks.

RUN
  python3 notes/prom_a_call_graph.py                 # top unconverted targets
  python3 notes/prom_a_call_graph.py --n 60
  python3 notes/prom_a_call_graph.py --modules       # whole thunk modules, ranked
  python3 notes/prom_a_call_graph.py --module 0xF41CD0   # one module's slots
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
SRC = image_path(ROOT, "prom_a/wsa1_prom_a.s")

FAIL = []


def check(msg, cond):
    print("  %-58s %s" % (msg, "ok" if cond else "FAIL"))
    if not cond:
        FAIL.append(msg)


def load():
    r = lambda n: open(os.path.join(ROOT, "original_ROMs", n), "rb").read()
    return r("wsa1_prom_a.ic12"), r("wsa1_prom_b.ic13")


def incbin_ranges():
    """[(lo, hi)] file-offset ranges still .incbin in prom_a/wsa1_prom_a.s."""
    pat = re.compile(r'\.incbin\s+"[^"]*wsa1_prom_a\.ic12"\s*,\s*(0x[0-9A-Fa-f]+)\s*,'
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


def modules(slots):
    """Group slot addresses into runs of consecutive table entries."""
    ks = sorted(slots)
    out, run = [], []
    for k in ks:
        if run and k == run[-1] + 4:
            run.append(k)
        else:
            if run:
                out.append(run)
            run = [k]
    if run:
        out.append(run)
    return out


def main():
    a, b = load()
    ranges = incbin_ranges()
    slots = jp_slots(b)
    cnt = refcounts(a, b)

    covered = 0x80000 - sum(hi - lo for lo, hi in ranges)
    print("prom_a: %d bytes converted, %d still .incbin in %d spans"
          % (covered, 0x80000 - covered, len(ranges)))
    a_slots = {s: t for s, t in slots.items() if t >= A_BASE}
    print("thunk table: %d `jp` slots, %d of them naming prom_a"
          % (len(slots), len(a_slots)))
    print()

    live = {s: t for s, t in a_slots.items() if is_incbin(ranges, t - A_BASE)}

    if "--module" in sys.argv:
        at = int(sys.argv[sys.argv.index("--module") + 1], 16)
        for run in modules(a_slots):
            if run[0] <= at <= run[-1]:
                print("module T_%06X-T_%06X, %d slot(s)" % (run[0], run[-1], len(run)))
                for s in run:
                    print("   T_%06X  x%-4d -> 0x%06X   %s"
                          % (s, cnt.get(s, 0), a_slots[s],
                             ".incbin" if s in live else "converted"))
                return 1 if FAIL else 0
        print("no module contains slot 0x%06X" % at)
        return 1

    if "--modules" in sys.argv:
        rows = []
        for run in modules(a_slots):
            unconv = [s for s in run if s in live]
            if not unconv:
                continue
            refs = sum(cnt.get(s, 0) for s in unconv)
            tg = [a_slots[s] for s in unconv]
            rows.append((refs, len(unconv), run[0], run[-1], min(tg), max(tg)))
        rows.sort(reverse=True)
        print("UNCONVERTED prom_a thunk MODULES, by total reference upper bound")
        print("   %-22s %6s %6s  %s" % ("module", "refs", "slots", "target span"))
        for refs, n, lo, hi, tlo, thi in rows:
            print("   T_%06X-T_%06X  x%-5d %5d   0x%06X-0x%06X  (0x%X)"
                  % (lo, hi, refs, n, tlo, thi, thi - tlo))
        print()
        print("self-checks")
        check("every module row has at least one unconverted slot",
              all(n > 0 for _, n, _, _, _, _ in rows))
        check("module reference sums equal the per-slot sum",
              sum(r[0] for r in rows) == sum(cnt.get(s, 0) for s in live))
        return 1 if FAIL else 0

    n = 40
    if "--n" in sys.argv:
        n = int(sys.argv[sys.argv.index("--n") + 1])

    rows = sorted(((cnt.get(s, 0), s, t) for s, t in live.items()), reverse=True)
    print("UNCONVERTED prom_a thunk targets, by reference upper bound (top %d of %d)"
          % (min(n, len(rows)), len(rows)))
    print("   %-12s %5s  %-10s" % ("slot", "refs", "target"))
    for k, slot, tgt in rows[:n]:
        print("   T_%06X   x%-4d  0x%06X" % (slot, k, tgt))
    print()

    print("self-checks")
    check("thunk table region itself is in prom_b, not prom_a",
          B_BASE + TBL_LO < A_BASE)
    check("known-converted 0xF857D9 (Kernel_StartTask) reads as converted",
          not is_incbin(ranges, 0xF857D9 - A_BASE))
    check("known-unconverted 0xF80000 reads as unconverted",
          is_incbin(ranges, 0x00000))
    check("every reported target really is inside an .incbin",
          all(is_incbin(ranges, t - A_BASE) for _, _, t in rows))
    check("no reported target lies below 0xF80000",
          all(t >= A_BASE for _, _, t in rows))
    sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
    import source_coverage
    sc = source_coverage.measure("a")[0]
    check("converted total agrees with scripts/analysis/source_coverage.py "
          "(%d)" % sc, covered == sc)
    return 1 if FAIL else 0


if __name__ == "__main__":
    sys.exit(main())
