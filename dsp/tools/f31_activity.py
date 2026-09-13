#!/usr/bin/env python3
"""f31_activity.py -- is `f31' an ACTIVE operation field on words that fetch no coefficient?

QUESTION IT ANSWERS
    The device models `f31 = hi12[3:1]' as a three-code accumulator operation on EVERY word:

        0 = LOAD   acc <- P + bus        1 = ADD   acc <- acc + P + bus
        2 = HOLD   acc <- acc + bus      >2 = treated as HOLD (undecoded)

    N-INPUT-GATE-OPENED §55 MEASURED that this is what kills the output: in 14 of 14 programs
    whose body leaves a constant accumulator, the killer is an `f31 == 0' LOAD, and 13 of the 14
    fetch NO coefficient -- so the product they load is one that nothing in that slot produced.
    §55's own instruction was to decide `f31 == 0' "from the corpus and the HLE, not from another
    arm".  This is the corpus half, and it is a test the BYTECODE can answer on its own.

THE TEST, and why it is falsifiable
    If `f31' is a real operation field everywhere, then on words that fetch no coefficient the
    assembler must still have CHOSEN a value -- so the same instruction shape should appear with
    DIFFERENT `f31' codes somewhere in 38 programs.  A field nobody chooses is a field that is
    always the same.

        MINIMAL PAIR = two corpus words identical in EVERY OTHER BIT (all 36, with hi12[3:1]
        masked out) that carry different `f31'.

    * many minimal pairs among non-fetching words  => the field is ACTIVE there; the LOAD is a
      real operation and §55's erasure is real chip behaviour we are mis-modelling elsewhere.
    * no minimal pairs, and `f31' constant per shape => the field is not being chosen there,
      which is evidence (not proof) that it is not an accumulator op on those words.

    The COEFFICIENT-FETCHING population is the built-in positive control: a multiply chain must
    start (LOAD) and continue (ADD), so minimal pairs MUST exist there.  If the control shows none,
    the instrument is broken and the result on the other population means nothing.

USAGE
    python3 dsp/tools/f31_activity.py [dsp/disasm/*.dsm]

Predicates are the device's own (upd6383d.h): f31 = hi12[3:1]; coeff_fetch = (class & 8) and not
c_format; c_format = (hi12 & 0xf00) == 0xc00.
"""
import collections
import glob
import os
import re
import sys

ROW = re.compile(r"^\s+w(\d+)\s+([0-9A-F]{10})\s")
F31_MASK = ~(0x7 << 25) & ((1 << 40) - 1)     # every bit EXCEPT hi12[3:1]
NAME = {0: "LOAD", 1: "ADD", 2: "HOLD"}


def load(files):
    words = []
    for f in files:
        prog = os.path.basename(f).replace(".dsm", "")
        for ln in open(f, errors="replace"):
            m = ROW.match(ln)
            if m:
                words.append((prog, int(m.group(1)), int(m.group(2), 16)))
    return words


def main():
    files = sys.argv[1:] or sorted(glob.glob(os.path.join(
        os.path.dirname(os.path.abspath(__file__)), "..", "disasm", "*.dsm")))
    words = load(files)
    if not words:
        print("no listing rows matched -- wrong path?")
        return 1

    # key = the word with the f31 field removed -> {f31: [(prog, iw)]}
    shapes = {False: collections.defaultdict(lambda: collections.defaultdict(list)),
              True: collections.defaultdict(lambda: collections.defaultdict(list))}
    dist = {False: collections.Counter(), True: collections.Counter()}
    percls = collections.defaultdict(collections.Counter)

    for prog, iw, w in words:
        hi12 = (w >> 24) & 0xfff
        cls = (w >> 20) & 0xf
        f31 = (hi12 >> 1) & 7
        cf = bool(cls & 8) and (hi12 & 0xf00) != 0xc00
        dist[cf][f31] += 1
        shapes[cf][w & F31_MASK][f31].append((prog, iw))
        if not cf:
            percls[cls][f31] += 1

    print("=== f31 ACTIVITY CENSUS -- %d words, %d listings ===" % (len(words), len(files)))
    for cf, title in ((True, "COEFFICIENT-FETCHING (the positive control)"),
                      (False, "NO COEFFICIENT FETCH")):
        tot = sum(dist[cf].values())
        print("\n-- %s : %d words" % (title, tot))
        for v in sorted(dist[cf]):
            print("   f31 = %d %-5s %6d  %5.1f%%" % (v, NAME.get(v, ""), dist[cf][v],
                                                     100.0 * dist[cf][v] / tot))
        multi = {k: d for k, d in shapes[cf].items() if len(d) > 1}
        print("   distinct shapes (f31 masked out) : %d" % len(shapes[cf]))
        print("   ★ MINIMAL PAIRS (same shape, different f31) : %d shapes" % len(multi))
        for k, d in sorted(multi.items())[:12]:
            codes = " vs ".join("%d%s(%d)" % (v, NAME.get(v, ""), len(d[v])) for v in sorted(d))
            ex = sorted(d)[0]
            print("      %010X  %-38s e.g. %s w%d" % (k, codes, d[ex][0][0], d[ex][0][1]))
        if len(multi) > 12:
            print("      ... %d more" % (len(multi) - 12))

    print("\n-- NO-COEFFICIENT words, f31 by CLASS (is the code a property of the class?)")
    print("   cls |" + "".join("  f31=%d " % v for v in range(8)) + "  shapes  multi")
    for cls in sorted(percls):
        row = "".join("%7d " % percls[cls].get(v, 0) for v in range(8))
        sh = {k: d for k, d in shapes[False].items() if ((k >> 20) & 0xf) == cls}
        mu = sum(1 for d in sh.values() if len(d) > 1)
        print("    %2X  |%s %6d  %5d" % (cls, row, len(sh), mu))
    return 0


if __name__ == "__main__":
    sys.exit(main())
