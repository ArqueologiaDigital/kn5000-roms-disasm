#!/usr/bin/env python3
"""bit5_words.py -- profile the `hi12 bit 5' population, and ask whether the device's COLLAPSE of
the high `f31' codes can ever be observed.

QUESTION IT ANSWERS
    `f31_activity.py' established from the bytecode that `f31 = hi12[3:1]' is an ACTIVELY CHOSEN
    field, and that the corpus splits in two:

        hi12 bit 5 CLEAR : 2 852 of 2 885 words (98.9 %) use only f31 in {0, 1, 2}
        hi12 bit 5 SET   : 129 of 172 words (75 %) use f31 in {3..7}

    The device gives EVERY code above 2 one behaviour (`op > HI_ACC_HOLD' contributes no product
    and still carries the accumulator, i.e. `acc <- acc + bus'), so five distinct codes the corpus
    writes deliberately are collapsed into one.  Before that gap can be called load-bearing it has
    to be shown to be OBSERVABLE, and there is a specific reason it might not be: in the parametric
    EQ the bit-5 word at the body entry (`w3', `iw87') adds a term that the very next word throws
    away with an `f31 = 0' LOAD.  A term that is overwritten one slot later cannot be measured.

    So this reports, for every bit-5 word in the corpus:

        * the field profile of the population (class / ACT / SRC / store), and its shapes
        * PADDING test  -- are they at the tail of the image, or scattered through the body?
        * TERMINATOR test -- is the last word of each program a bit-5 word?
        * ★ SUCCESSOR test -- is the NEXT word an `f31 = 0' LOAD, which discards whatever this
          word left in the accumulator?  Those sites are BLIND: no arm can be graded there.

    The surviving sites -- bit-5 words whose accumulator term is NOT immediately discarded -- are
    where a reading of `hi12 bit 5' has to be tested.

USAGE
    python3 dsp/tools/bit5_words.py [dsp/disasm/*.dsm]

⚠ The successor test is STATIC and therefore approximate: it reads the listing in address order,
  which is execution order only inside a straight run.  A site it calls blind is blind; a site it
  calls live could still be discarded further downstream.  It is a lower bound on blindness.
"""
import collections
import glob
import os
import re
import sys

ROW = re.compile(r"^\s+w(\d+)\s+([0-9A-F]{10})\s")


def fields(w):
    hi = (w >> 24) & 0xfff
    return dict(hi=hi, cls=(w >> 20) & 0xf, a8=(w >> 12) & 0xff, act=w & 0x1f,
                src=(w >> 6) & 0x1f, f31=(hi >> 1) & 7, b5=bool(hi & 0x20),
                store=bool(hi & 0x10))


def main():
    files = sys.argv[1:] or sorted(glob.glob(os.path.join(
        os.path.dirname(os.path.abspath(__file__)), "..", "disasm", "*.dsm")))
    prog = {}
    for f in files:
        v = [(int(m.group(1)), int(m.group(2), 16))
             for ln in open(f, errors="replace") if (m := ROW.match(ln))]
        if v:
            prog[os.path.basename(f)[:-4]] = v
    total = sum(len(v) for v in prog.values())
    b5 = [(p, i, w) for p, v in prog.items() for i, w in v if fields(w)["b5"]]

    print("=== hi12 BIT 5: %d of %d words (%.1f%%) in %d of %d programs ==="
          % (len(b5), total, 100.0 * len(b5) / total,
             len({p for p, _, _ in b5}), len(prog)))
    none = sorted(p for p in prog if not any(fields(w)["b5"] for _, w in prog[p]))
    print("  programs with NO bit-5 word (%d): %s" % (len(none), ", ".join(none)))
    #  ⚠ A C-format word carries an IMMEDIATE where the other formats carry fields, so its
    #  hi12 bits are not the bit-5/f31 encoding at all.  Counted and named, not silently dropped.
    cf = [(p, i, w) for p, i, w in b5 if (fields(w)["hi"] & 0xf00) == 0xc00]
    print("  ⚠ of these, C-FORMAT (hi12 & 0xf00 == 0xc00, an immediate -- NOT this encoding): %d %s"
          % (len(cf), ["%s w%d" % (p, i) for p, i, _ in cf]))

    for nm, key in (("class", "cls"), ("ACT", "act"), ("SRC", "src"), ("f31", "f31")):
        c = collections.Counter(fields(w)[key] for _, _, w in b5)
        print("  %-5s : %s" % (nm, " ".join("%02X:%d" % kv for kv in c.most_common(8))))
    print("  store bit set: %d of %d" % (sum(fields(w)["store"] for _, _, w in b5), len(b5)))

    print("\n-- SHAPES (the word with f31 masked out)")
    sh = collections.Counter(w & ~(7 << 25) & ((1 << 40) - 1) for _, _, w in b5)
    for k, v in sh.most_common(8):
        f = fields(k)
        print("   %010X n=%-3d cls %X ACT %02X SRC %02X addr8 %02X store=%d"
              % (k, v, f["cls"], f["act"], f["src"], f["a8"], f["store"]))

    tails = collections.Counter(prog[p][-1][0] - i for p, i, _ in b5)
    print("\n-- PADDING test: distance from the image's last word")
    print("   at the last word: %d ; within the last 3: %d ; of %d"
          % (tails.get(0, 0), sum(v for k, v in tails.items() if k < 3), len(b5)))
    lastb5 = [p for p, v in prog.items() if fields(v[-1][1])["b5"]]
    print("-- TERMINATOR test: the image's last word has bit 5 in %d of %d programs"
          % (len(lastb5), len(prog)))

    print("\n-- ★ SUCCESSOR test: does the NEXT word discard the accumulator (f31 == 0, a LOAD)?")
    blind = live = noeat = 0
    livesites = []
    for p, v in prog.items():
        idx = {i: k for k, (i, _) in enumerate(v)}
        for i, w in v:
            if not fields(w)["b5"]:
                continue
            k = idx[i] + 1
            if k >= len(v):
                noeat += 1
                continue
            nxt = fields(v[k][1])
            if nxt["f31"] == 0:
                blind += 1
            else:
                live += 1
                livesites.append((p, i, w, v[k][0], v[k][1]))
    print("   next word is an f31 = 0 LOAD  (term DISCARDED -- site is BLIND) : %d" % blind)
    print("   next word is NOT a LOAD       (term SURVIVES  -- site is LIVE ) : %d" % live)
    print("   no next word in the image                                      : %d" % noeat)
    c = collections.Counter(fields(w)["f31"] for _, _, w, _, _ in livesites)
    print("   LIVE sites by f31: %s" % " ".join("%d:%d" % kv for kv in sorted(c.items())))
    print("   LIVE sites, first 20:")
    for p, i, w, ni, nw in sorted(livesites)[:20]:
        print("      %-26s w%-3d %010X f31=%d  ->  w%-3d %010X f31=%d"
              % (p, i, w, fields(w)["f31"], ni, nw, fields(nw)["f31"]))
    if len(livesites) > 20:
        print("      ... %d more" % (len(livesites) - 20))
    return 0


if __name__ == "__main__":
    sys.exit(main())
