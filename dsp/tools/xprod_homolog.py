#!/usr/bin/env python3
"""xprod_homolog.py -- every HOMOLOGOUS program pair between the KN5000 and the SX-WSA1R.

QUESTION IT ANSWERS
    `kernel_homolog.py' found ONE homolog by accident -- the WSA1R's unnamed `struct_00_fd4093'
    turned out to be this chip's kernel header, 34 of 42 words byte-identical and in order -- and
    that one pair supplied the RELOCATION TEST, which is the only instrument in this project that
    separates an ADDRESS field from a DATA field with no semantic assumption at all:

        two copies of one routine at different offsets.  A field that is an address must shift by
        the number of words inserted before it; a field that is data must not.

    sect. 122 used it once (the C-format payload: `A' tracks the move 4 of 4, `B' and `f31' do
    not) and it decoded eleven words.  ⇒ THE INSTRUMENT IS WORTH MORE THAN THE ACCIDENT.  This
    file asks the pooled corpus for every OTHER pair it could be pointed at.

USAGE
    python3 dsp/tools/xprod_homolog.py             # the ranked pairs and the null
    python3 dsp/tools/xprod_homolog.py --reloc     # ★ run the relocation test on each pair found
    python3 dsp/tools/xprod_homolog.py --min 8     # lower the reporting floor

THE NULL, and it is the whole point.  Two programs of one ISA share idioms, so "N words match"
means nothing on its own.  Every pair is scored by the longest in-order byte-identical run count,
and the same statistic is computed for EVERY pair -- including same-product pairs, which are the
control: if unrelated KN5000 bodies routinely align 20 words deep, a 20-word cross-product hit is
noise.  The reported figure for each candidate is its score AND its rank among all pairs.

⚠ WHAT THIS IS NOT.  A homolog is a place to point an experiment, not a result.  The kernel pair
  took a relocation test and a null of its own before it decoded anything, and the four fields it
  separated were separated by MEASUREMENT, not by the pairing.
"""
import collections
import difflib
import glob
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import dsp_disasm as DIS                                                  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
ROW = re.compile(r"^\s*w(\d+)\s+([0-9A-Fa-f]{10})")
CORPORA = (("KN", os.path.join(HERE, "..", "disasm", "*.dsm")),
           ("WSA", os.path.join(HERE, "..", "..", "wsa1", "dsp", "disasm", "*.dsm")))
MIN = 6


def images():
    for label, pat in CORPORA:
        for f in sorted(glob.glob(pat)):
            b = os.path.basename(f)[:-4]
            if b == "index":
                continue
            o = {}
            for ln in open(f, errors="replace"):
                m = ROW.match(ln)
                if m:
                    o[int(m.group(1))] = int(m.group(2), 16)
            if o:
                yield label, b, [o[k] for k in sorted(o)]


def score(a, b):
    sm = difflib.SequenceMatcher(None, ["%010X" % x for x in a], ["%010X" % x for x in b],
                                 autojunk=False)
    ops = sm.get_opcodes()
    return sum(i2 - i1 for op, i1, i2, _, _ in ops if op == "equal"), ops


def reloc_on(a, b, ops):
    """The relocation test on one pair: for every C-format word inside a divergent run, does its
    payload shift by the running alignment offset?"""
    anchor = {}
    for op, i1, i2, j1, j2 in ops:
        if op == "equal":
            for k in range(i2 - i1):
                anchor[i1 + k] = j1 + k

    def off(i):
        for k in range(i, len(a) + 40):
            if k in anchor:
                return anchor[k] - k
        return None

    out = []
    for op, i1, i2, j1, j2 in ops:
        if op == "equal":
            continue
        ka = [k for k in range(i1, i2) if DIS.c_format(a[k])]
        kb = [k for k in range(j1, j2) if DIS.c_format(b[k])]
        for i, j in zip(ka, kb):
            if DIS.lo12(a[i]) != DIS.lo12(b[j]):
                continue                         # different destination: not the same instruction
            o = off(i)
            if o is None:
                continue
            out.append((i, j, DIS.c_a(a[i]), DIS.c_a(b[j]), o,
                        DIS.c_a(b[j]) - DIS.c_a(a[i]) == o,
                        DIS.c_b(a[i]) == DIS.c_b(b[j])))
    return out


def main():
    global MIN
    if "--min" in sys.argv:
        MIN = int(sys.argv[sys.argv.index("--min") + 1])
    imgs = list(images())
    print("=" * 100)
    print("  xprod_homolog -- homologous program pairs across the two products (%d images)"
          % len(imgs))
    print("=" * 100 + "\n")

    cross, within = [], []
    cache = {}
    for x in range(len(imgs)):
        for y in range(x + 1, len(imgs)):
            la, na, wa = imgs[x]
            lb, nb, wb = imgs[y]
            s, ops = score(wa, wb)
            cache[(x, y)] = ops
            (cross if la != lb else within).append((s, x, y))
    cross.sort(reverse=True)
    within.sort(reverse=True)

    #  ---- the null, computed from the same statistic ----------------------
    wn = [s for s, _, _ in within]
    cn = [s for s, _, _ in cross]
    print("   ★ THE NULL, from the same statistic (rule 15)\n")
    print("      SAME-product pairs  : %d, mean %.1f, median %d, 95th pct %d, max %d"
          % (len(wn), sum(wn) / len(wn), sorted(wn)[len(wn) // 2],
             sorted(wn)[int(.95 * len(wn))], max(wn)))
    print("      CROSS-product pairs : %d, mean %.1f, median %d, 95th pct %d, max %d"
          % (len(cn), sum(cn) / len(cn), sorted(cn)[len(cn) // 2],
             sorted(cn)[int(.95 * len(cn))], max(cn)))
    floor = max(MIN, sorted(wn)[int(.99 * len(wn))] + 1)
    print("      ⇒ reporting floor = max(%d, 99th pct of the same-product null + 1) = %d"
          % (MIN, floor))

    print("\n   ★ CROSS-PRODUCT PAIRS ABOVE THE FLOOR\n")
    hits = [(s, x, y) for s, x, y in cross if s >= floor]
    if not hits:
        print("      NONE.  The kernel header is the only homolog in the pooled corpus, and the")
        print("      relocation instrument has exactly one place to stand.  That is a real answer")
        print("      to `is there more of this': there is not, and it is worth knowing before")
        print("      building a pass on the assumption that there is.")
    for s, x, y in hits:
        la, na, wa = imgs[x]
        lb, nb, wb = imgs[y]
        print("      %-4d %-7s %-26s  <->  %-7s %-26s   (%d / %d words)"
              % (s, la, na, lb, nb, len(wa), len(wb)))
        if "--reloc" in sys.argv:
            r = reloc_on(wa, wb, cache[(x, y)])
            if not r:
                print("           relocation test: no comparable C-format pair in the divergences")
                continue
            ok = sum(1 for t in r if t[5])
            bs = sum(1 for t in r if t[6])
            print("           ★ relocation test: A tracks the offset %d of %d; B identical %d of %d"
                  % (ok, len(r), bs, len(r)))
            for i, j, ai, aj, o, hit, bsame in r:
                print("             w%-3d A=%-4d | w%-3d A=%-4d | offset %+-4d dA %+-4d %s"
                      % (i, ai, j, aj, o, aj - ai, "★" if hit else "⛔"))

    #  ---- the same-product control, shown so the floor can be judged -------
    print("\n   ★ THE TOP OF THE SAME-PRODUCT NULL, for comparison\n")
    for s, x, y in within[:5]:
        print("      %-4d %-7s %-26s  <->  %-7s %s"
              % (s, imgs[x][0], imgs[x][1], imgs[y][0], imgs[y][1]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
