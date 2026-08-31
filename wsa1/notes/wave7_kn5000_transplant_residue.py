#!/usr/bin/env python3
"""Is the KN5000 label transplant into prom_c finished, and what are the leftovers?

QUESTION IT ANSWERS
    "scripts/analysis/transplant_kn5000_labels.py emits byte-verified proposals.
     How many are already applied, how many are not -- and are the unapplied ones
     a GAP or a deliberate difference in how the two trees model the same bytes?"

THE ANSWER: THE TRANSPLANT IS COMPLETE. NOTHING IS MISSING.
    Of the 19 distinct names proposed at the default --min-run, 15 are already
    labels in prom_c.  The remaining FOUR are not a gap: every one is a name the
    KN5000 tree gives to a SUB-OBJECT of a structure this tree models as a whole,
    and this tree's model is the better one -- it is the one that carries the
    record stride.  Applying them would split a documented structure to import a
    less informative name.

        DSP_AlgoChannel_SelectorByte4  0xFDE6AD -> byte 4 of record 0 of
        DSP_AlgoChannel_SelectorByte5  0xFDE6AE -> byte 5 of record 0 of
            DSP_AlgoChannel_SelectorRecords (0xFDE6A9, 12 records x 6 bytes)

        DSP_ChanFreq_Dispatch1_Curves  0xFDEA21 -> ROW 8  exactly, and
        DSP_ChanFreq_Packet1_Curve     0xFDEB53 -> ROW 11 exactly, of
            DSP_ChanFreq_CurvePool (0xFDE6F1, 12 rows x 51 u16, stride 0x66)

    Both row offsets divide by the stride with remainder ZERO, which is what makes
    this a conclusion rather than an impression.  And the pool's own header already
    says so in as many words: "addressed with three different row bases in the
    sibling".  The KN5000 side names three bases; this side names one pool and its
    stride, and records that the sibling splits it.

★ THE GENERAL POINT, worth more than the four names
    Byte identity tells you the CODE is the same.  It does not tell you the better
    NAME is the sibling's.  A transplant that is "incomplete" by name count can be
    complete by meaning -- and a residue is worth explaining before it is worth
    importing.  The tool's own banner already warns that byte identity establishes
    the code is the same, not that the surrounding machine is; this is the same
    caution one level up, about the model rather than the machine.

RUN
    python3 notes/wave7_kn5000_transplant_residue.py            # the four, explained
    python3 notes/wave7_kn5000_transplant_residue.py --selftest # 10 checks
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
SRC = image_path(ROOT, "prom_c/wsa1_prom_c.s")

POOL, POOL_STRIDE, POOL_ROWS = 0xFDE6F1, 0x66, 12
RECS, REC_STRIDE, REC_COUNT = 0xFDE6A9, 6, 12

RESIDUE = [
    (0xFDE6AD, "DSP_AlgoChannel_SelectorByte4", "record", RECS, REC_STRIDE),
    (0xFDE6AE, "DSP_AlgoChannel_SelectorByte5", "record", RECS, REC_STRIDE),
    (0xFDEA21, "DSP_ChanFreq_Dispatch1_Curves", "row", POOL, POOL_STRIDE),
    (0xFDEB53, "DSP_ChanFreq_Packet1_Curve", "row", POOL, POOL_STRIDE),
]


def proposals():
    """Re-run the transplant tool rather than quoting it."""
    out = subprocess.run(
        [sys.executable, os.path.join(ROOT, "scripts", "analysis",
                                      "transplant_kn5000_labels.py")],
        capture_output=True, text=True, cwd=ROOT).stdout
    rx = re.compile(r'^\s+prom_c\s+0x([0-9A-F]{6})\s+(\S+)\s+run=\s*(\d+)\s+kn5000=(0x[0-9A-Fa-f]+)')
    return [(int(m.group(1), 16), m.group(2), int(m.group(3)), m.group(4))
            for m in (rx.match(l) for l in out.splitlines()) if m]


def report():
    src = open(SRC).read()
    props = proposals()
    names = sorted(set(n for _a, n, _r, _k in props))
    applied = [n for n in names if (n + ":") in src]
    print("byte-verified proposals: %d, distinct names: %d" % (len(props), len(names)))
    print("already labels in prom_c: %d   residue: %d\n" % (len(applied), len(names) - len(applied)))
    for a, n, what, base, stride in RESIDUE:
        off = a - base
        print("  0x%06X  %-32s  %s %d of the object at 0x%06X"
              % (a, n, what, off // stride, base))
        print("            offset %d / stride 0x%02X = %s, remainder %d%s"
              % (off, stride, off // stride, off % stride,
                 "  <- exact, so it is a boundary, not an interior address"
                 if off % stride == 0 else "  <- interior"))
    print("\nNone of the four is a missing label. See this file's docstring.")


def selftest():
    ok = fail = 0

    def check(desc, cond):
        nonlocal ok, fail
        print(("  ok   " if cond else "  FAIL ") + desc)
        ok, fail = ok + (1 if cond else 0), fail + (0 if cond else 1)

    src = open(SRC).read()
    props = proposals()
    names = sorted(set(n for _a, n, _r, _k in props))
    check("the transplant tool still emits proposals", len(props) > 0)
    check("15 of its 19 distinct names are already labels in prom_c",
          (len(names), sum(1 for n in names if (n + ":") in src)) == (19, 15))
    check("the residue is exactly the four this file explains",
          sorted(n for n in names if (n + ":") not in src)
          == sorted(r[1] for r in RESIDUE))
    for a, n, what, base, stride in RESIDUE:
        off = a - base
        if what == "row":
            check("%s at 0x%06X is row %d of the pool, remainder 0"
                  % (n, a, off // stride), off % stride == 0)
        else:
            check("%s at 0x%06X is byte %d of a %d-byte record"
                  % (n, a, off % stride, stride), 0 < off % stride < stride)
    check("the containing structures ARE labelled here",
          "DSP_ChanFreq_CurvePool:" in src and "DSP_AlgoChannel_SelectorRecords:" in src)
    check("...and the pool's header already records the sibling's different model",
          "three different row bases in the sibling" in src)
    # the LAST row of the pool, not just the first
    check("the pool's LAST row (11) starts inside the pool's stated extent",
          POOL + (POOL_ROWS - 1) * POOL_STRIDE < 0xFDEBB8)
    print("\n%d checks, %d failures" % (ok + fail, fail))
    return 1 if fail else 0


if __name__ == "__main__":
    sys.exit(selftest() if "--selftest" in sys.argv else (report() or 0))
