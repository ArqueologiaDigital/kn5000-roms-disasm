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

    print("\n-- DENSITY per program (corpus rate %.1f%%) -- is bit 5 an EFFECT-KIND marker?"
          % (100.0 * len(b5) / total))
    dens = sorted(((sum(1 for _, w in v if fields(w)["b5"]) / len(v), len(v), p)
                   for p, v in prog.items()), reverse=True)
    for r, n, p in dens[:8]:
        print("   %-26s %2d/%-3d = %4.1f%%" % (p, round(r * n), n, 100 * r))
    #  ⛔⛔ DO NOT re-invent the control I got wrong.  I used `prog00_no_operation' as the control
    #  that kills the envelope reading -- "a pass-through program cannot be dense in detection".
    #  `dsp/algorithms/families.md' ("Filter / dynamics") had ALREADY classified it, on independent
    #  COEFFICIENT evidence (the 2/pi scale constant + the one-pole smoother coefficients), as one
    #  of the FOUR level-detector programs, and says in as many words: "NO OPERATION is not empty:
    #  it is a dry pass-through that still runs that level detector".  So its above-rate density
    #  CONFIRMS the reading it was supposed to refute.  The groups below are that file's, not mine.
    rate = len(b5) / total
    GROUPS = {
        "decoded LEVEL-DETECTOR family (families.md 'Filter / dynamics')":
            ["prog03_enhancer", "prog52_auto_wah", "prog36_compressor", "prog00_no_operation"],
        "pure delay/modulation networks (the zero-density set)":
            ["prog01_chorus", "prog02_modulated_chorus", "prog04_flanger", "prog09_single_delay",
             "prog10_multi_tap_delay", "prog16_room_reverb_1", "prog50_vibrato", "prog56_mix_up"],
    }
    print("   -- against the NULL (uniform at the corpus rate):")
    for nm, grp in GROUPS.items():
        grp = [p for p in grp if p in prog]
        n = sum(len(prog[p]) for p in grp)
        o = sum(1 for p in grp for _, w in prog[p] if fields(w)["b5"])
        print("      %-58s words=%4d observed=%3d expected=%5.1f" % (nm, n, o, n * rate))
        if o == 0:
            print("      %-58s P(observe 0 | uniform) = %.2e" % ("", (1 - rate) ** n))

    #  ★ SITE-level control for the same reading.  If bit 5 were the control-bus / VCA operation
    #  (DECODE-by-correlation §8: SRC 0x1C is "the effect's control/modulation bus, always
    #  multiplied into the signal path"), bit-5 words should sit NEAR SRC 0x1C words.  The null is
    #  the same statistic over every word that is NOT bit-5.
    print("   -- SITE-level control: distance to a SRC 0x1C (control-bus) word, vs the null")
    for win in (1, 2, 3):
        hit = tot_ = nhit = ntot = 0
        for p, v in prog.items():
            near = set()
            for k, (_, w) in enumerate(v):
                if fields(w)["src"] == 0x1c:
                    near.update(range(k - win, k + win + 1))
            for k, (_, w) in enumerate(v):
                if fields(w)["b5"]:
                    tot_ += 1
                    hit += k in near
                else:
                    ntot += 1
                    nhit += k in near
        print("      ±%d slots: bit-5 %3d/%3d = %4.1f%%   NULL %4d/%4d = %4.1f%%"
              % (win, hit, tot_, 100.0 * hit / tot_, nhit, ntot, 100.0 * nhit / ntot))

    #  ★ bit 10 with bit 11 clear is ALREADY DECODED as END OF BLOCK (dsp_disasm.py:426, and the
    #  kernel's own annotations call w6/w11 "END OF BLOCK A/B").  Confirmed here with the null it
    #  never had: 39 of 40 images end on such a word (the 40th, the epilogue, ends on a C-FORMAT
    #  word, where bit 10 is part of the 0xC00 format code and means nothing).  Crossing it with
    #  bit 5 partitions the bit-5 population -- and turns up a hard constraint.
    end_of = lambda w: bool(fields(w)["hi"] & 0x400) and not (fields(w)["hi"] & 0x800)
    print("\n-- CROSSED WITH `END OF BLOCK' (hi12 bit 10, bit 11 clear -- an EXISTING decode)")
    cell = collections.Counter((end_of(w), fields(w)["b5"]) for v in prog.values() for _, w in v)
    print("               bit5=0  bit5=1")
    for e in (False, True):
        print("   END=%-5s %7d %7d" % (e, cell[(e, False)], cell[(e, True)]))
    exp = (len(b5) * sum(1 for v in prog.values() for _, w in v if end_of(w))) / float(total)
    print("   bit-5 AND END: observed %d, expected %.1f under independence (%.1fx)"
          % (cell[(True, True)], exp, cell[(True, True)] / max(exp, 1e-9)))
    print("   ★ f31 inside each page, split by END  (the null is the bit5=0 row)")
    for pg in (True, False):
        for e in (True, False):
            c = collections.Counter(fields(w)["f31"] for v in prog.values() for _, w in v
                                    if fields(w)["b5"] == pg and end_of(w) == e)
            print("      bit5=%d %s : %s" % (pg, "END   " if e else "notEND",
                                             " ".join("%d:%d" % (k, c.get(k, 0)) for k in range(8))))
    ev = sum(1 for v in prog.values() for _, w in v
             if fields(w)["b5"] and end_of(w) and fields(w)["f31"] % 2 == 0)
    od = sum(1 for v in prog.values() for _, w in v
             if fields(w)["b5"] and end_of(w) and fields(w)["f31"] % 2)
    nev = sum(1 for v in prog.values() for _, w in v
              if fields(w)["b5"] and not end_of(w) and fields(w)["f31"] % 2 == 0)
    nod = sum(1 for v in prog.values() for _, w in v
              if fields(w)["b5"] and not end_of(w) and fields(w)["f31"] % 2)
    p_even = nev / float(nev + nod)
    print("   ★★ INSIDE THE BIT-5 PAGE, END words take only EVEN f31: %d even / %d odd."
          % (ev, od))
    print("      Non-END bit-5 words are %.0f%% even, so P(all %d even by chance) = %.1e"
          % (100 * p_even, ev, p_even ** ev))

    print("\n-- BIT-5 MINIMAL PAIRS: is bit 5 a MODIFIER on an otherwise identical instruction?")
    B5 = 1 << 29
    words = [w for v in prog.values() for _, w in v]
    have, cnt = set(words), collections.Counter(words)
    ex = sorted({(w & ~B5, w | B5) for w in have if (w & ~B5) in have and (w | B5) in have})
    print("   EXACT pairs (identical in all 40 bits but bit 5): %d" % len(ex))
    for lo, hi in ex:
        print("      %010X n=%-4d vs %010X n=%-4d  f31=%d"
              % (lo, cnt[lo], hi, cnt[hi], (lo >> 25) & 7))
    g = collections.defaultdict(lambda: [0, 0])
    for w in words:
        g[w & ~(B5 | (7 << 25)) & ((1 << 40) - 1)][1 if w & B5 else 0] += 1
    both = [k for k, v in g.items() if v[0] and v[1]]
    print("   shapes (bit5 AND f31 masked) written BOTH ways: %d of %d" % (len(both), len(g)))
    for k in sorted(both, key=lambda k: -sum(g[k]))[:6]:
        f = fields(k)
        print("      %010X  bit5=0:%-4d bit5=1:%-4d  cls %X ACT %02X SRC %02X addr8 %02X"
              % (k, g[k][0], g[k][1], f["cls"], f["act"], f["src"], f["a8"]))

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
