#!/usr/bin/env python3
"""class_twins.py -- what does `class4' change, asked with the SECOND PRODUCT's corpus added.

QUESTION IT ANSWERS
    `dark-words.md' sect. 4.4 named the lever and nobody pulled it: *"`012.4.01.1CE' differs from
    the K6 input-stage word `012.2.FF.1CE' in NOTHING BUT `class4' (4 vs 2) and `addr8'.  A minimal
    pair across the class field, with one side forced, is the cleanest possible probe of what
    class 4 changes."*  It is better than that, and the missing half was in the other product.

    ★ THE SX-WSA1R RUNS THE SAME uPD6383 ISA and its 60 effect programs (4946 words) are
    disassembled in `wsa1/dsp/disasm/'.  Pooled with the KN5000's 38 images the corpus is 7558
    occurrences of 1129 distinct non-C-format words, and among them:

        `012.2.01.1CE'  x2    WSA1R eff54_pitch_shifter        ★ DECODED
        `012.4.01.1CE'  x99   53 KN5000 + 46 WSA1R             ⛔ traps

    **Identical in `hi12', in `addr8' AND in `lo12'.  The only difference in the 36-bit word is
    `class4'.**  The KN5000 corpus alone does not contain the class-2 member.

    ⇒ this tool enumerates every (hi12, addr8, lo12) triple that occurs with MORE THAN ONE
    `class4', over the pooled corpus.  It has a built-in positive control: the commonest pairing is
    `2 <-> A' on 19 triples, xor = 8 -- which recovers the known CURSOR-FETCH bit from the data.

    ★★ AND THE SECOND HALF, which is what the pair is for.  The `C63' macro (`bit11-family.md',
    N-INPUT-GATE-OPENED sect. 97/98) is spelled TWO ways in the pooled ROM:

        99 instances   [ x.0.00.C63 ] [ 000.6.TT.4CD|407 ] [ 012.4.01.1CE ] [ 104.2.dd.1CE ]
         2 instances   [ 142.0.00.C62 ] [ 022.2.1B.4CD ]   [ 092.2.01.1CE ] [ 184.2.FF.1CE ]
                       ★ the pitch shifter -- classes 2/2/2, where the pointer arithmetic is
                         FORCED -- and the ONLY program in either product using `lo12 = 0xC62'.

    Net pointer displacement over the three words after the head:

        shipped model (only class 2/A move) : the 99 spread over [-14, +9], the 2 at **+27**
                                              -- an outlier three times beyond the whole range
        classes 4 and 6 move by (s8)addr8   : the 99 spread over [+11, +41], the 2 at **+27**
                                              -- inside the range, and 6 of the 99 land on it

    A model under which the ROM's two spellings of one macro differ by 25 cells, against one under
    which they agree exactly.

    ★★ AND THE SAME INSTRUMENT AIMED AT `hi12' BIT 7 (`--bit7'), the store gate's own bit.  Over
    the pooled corpus **23 pairs** differ in bit 7 and in NOTHING ELSE -- same `class4', same
    `addr8', same `lo12', same every other `hi12' bit -- and in **10** of them the bit-7 member is
    the open gate (`bit-4 store' + `f31 == 1') while its twin is DECODED and stores `acc' to
    `mem[ptr]'.  That is ten minimal pairs across the one bit whose meaning `store-gate.md' item D
    left three-way open, and the corpus had never been asked for them.

    ⚠ ONE OF THEM IS THE LFO RAMP WORD.  `092.A.00.200' (46 occurrences, 26 images) is the ramp
    whose increment `lfo-ramp.md' anchors NINE-FOLD, and its bit-7-clear twin `012.A.00.200`
    exists -- once.  The LFO is the project's best-anchored arithmetic and the gate's survivors
    differ only in the accumulator, which is exactly what a phase accumulator is made of.

USAGE
    python3 dsp/tools/class_twins.py            # the twins and the control
    python3 dsp/tools/class_twins.py --macro    # the macro's net displacement, both models
    python3 dsp/tools/class_twins.py --bit7     # ★ the store gate's own minimal pairs

⚠ WHAT THIS IS NOT.  It does not promote anything.  n = 2 for the alternative spelling, in ONE
  program, and `closure_pointer.py variants' row V12 is mild counter-evidence (adding classes 4 and
  6 to the pointer walk takes the unit-0 pool from 8 distinct nets to 15, and closes nothing) --
  though that instrument's own premise was falsified in `closure-pointer.md' item F, and item G's
  rejections were at 29 and 31.  The decode this points at has to pass the catalogue regression at
  the true device default, the way `UPD6383_SRC0B2' did.
"""
import collections
import glob
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import dsp_disasm as D                                                   # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
ROW = re.compile(r"^\s+w(\d+)\s+([0-9A-F]{10})\s")
CORPORA = (("KN", os.path.join(HERE, "..", "disasm", "*.dsm")),
           ("WSA", os.path.join(HERE, "..", "..", "wsa1", "dsp", "disasm", "*.dsm")))


def s8(a):
    return a - 256 if a >= 128 else a


def images():
    for label, pat in CORPORA:
        for f in sorted(glob.glob(pat)):
            b = os.path.basename(f)[:-4]
            if b == "index":
                continue
            ws, sl = [], []
            for ln in open(f, errors="replace"):
                m = ROW.match(ln)
                if m:
                    sl.append(int(m.group(1)))
                    ws.append(int(m.group(2), 16))
            if ws:
                yield label, b, sl, ws


def bit7_twins(words, where):
    """★ Pairs identical in everything but `hi12' bit 7 -- the store gate's own bit.

    ⚠⚠ THE CO-OCCURRENCE FIGURE BELOW IS POST-HOC AND IS LABELLED SO.  I noticed the WSA1R pitch
    shifter carrying both spellings of one word four slots apart, and only then asked how often
    the two spellings share an image.  5 of 10 against a shuffled null of 2.72 +- 0.76
    (P = 0.019, 2000 shuffles preserving each word's image count) is a LEAD, not a test: the
    hypothesis was formed on the same data that scores it.  A real test needs a prediction made
    before looking -- the obvious one being the ORDER of the two spellings inside an image under
    the `bit 7 = memory-port DIRECTION' reading, which nothing here has examined."""
    g = collections.defaultdict(dict)
    for w in words:
        key = (D.hi12(w) & ~D.HI_B7, D.class4(w), D.addr8(w), D.lo12(w))
        g[key][1 if (D.hi12(w) & D.HI_B7) else 0] = w
    tw = [v for v in g.values() if len(v) == 2]
    gate = [v for v in tw if (D.hi12(v[1]) & D.HI_ST) and D.hi_f31(D.hi12(v[1])) == 1]
    print("\n=== ★★ BIT-7 TWINS -- identical but for `hi12' bit 7: %d pairs, %d of them THE GATE ==="
          % (len(tw), len(gate)))
    print("   %-14s %-6s %-14s %-6s %-7s %s"
          % ("bit 7 CLEAR", "x", "bit 7 SET", "x", "shared", "an image holding both"))
    for v in sorted(gate, key=lambda v: -(words[v[0]] + words[v[1]])):
        a, b = v[0], v[1]
        ov = sorted(where[a] & where[b])
        print("   %010X %-6d %010X %-6d %-7d %s"
              % (a, words[a], b, words[b], len(ov), ov[0] if ov else ""))
    print("   ⇒ %d of %d gate pairs put BOTH spellings in one image. ⚠ post-hoc -- see the"
          % (sum(1 for v in gate if where[v[0]] & where[v[1]]), len(gate)))
    print("     docstring; the null is 2.72 +- 0.76 and the hypothesis came from the same data.")


def main():
    words, where = collections.Counter(), collections.defaultdict(set)
    macro = []
    for label, b, sl, ws in images():
        for i, w in enumerate(ws):
            if D.c_format(w):
                continue
            words[w] += 1
            where[w].add(label + ":" + b)
            #   the macro: a bit-11 head `C63'/`C62' and the three words after it
            if (D.lo12(w) & 0x800) and D.lo12(w) in (0xC63, 0xC62) and i + 3 < len(ws):
                trio = ws[i + 1:i + 4]
                macro.append((label, b, sl[i], D.lo12(w),
                              [D.class4(x) for x in trio], [D.addr8(x) for x in trio]))

    print("=== POOLED CORPUS: %d distinct non-C-format words, %d occurrences ==="
          % (len(words), sum(words.values())))

    g = collections.defaultdict(dict)
    for w, n in words.items():
        g[(D.hi12(w), D.addr8(w), D.lo12(w))][D.class4(w)] = n
    multi = {k: v for k, v in g.items() if len(v) > 1}
    pairs = collections.Counter()
    for v in multi.values():
        cs = sorted(v)
        for i in range(len(cs)):
            for j in range(i + 1, len(cs)):
                pairs[(cs[i], cs[j])] += 1

    print("\n=== ★ TWINS: one (hi12, addr8, lo12), more than one `class4' -- %d of %d triples ==="
          % (len(multi), len(g)))
    for (a, b), n in pairs.most_common():
        note = ("   ← the CURSOR-FETCH bit, recovered from the data: POSITIVE CONTROL"
                if (a, b) == (2, 0xA) else
                "   ★ the idiom's third word" if (a, b) == (2, 4) else "")
        print("   class %X <-> %X   %3d triple(s)   xor = %X%s" % (a, b, n, a ^ b, note))
    print("\n   every twin, in full:")
    for k in sorted(multi):
        hi, ad, lo = k
        for c in sorted(multi[k]):
            w = (hi << 24) | (c << 20) | (ad << 12) | lo
            print("      %03X.%X.%02X.%03X  x%-4d decoded=%-5s  %s"
                  % (hi, c, ad, lo, multi[k][c], D.decoded(w),
                     ", ".join(sorted(where[w])[:2])))

    if "--bit7" in sys.argv:
        bit7_twins(words, where)
    if "--macro" in sys.argv:
        print("\n=== ★★ THE MACRO, BOTH SPELLINGS -- net pointer displacement of the three"
              " words after the head ===")
        print("   %-4s %-26s %5s %5s  %-9s %-11s %8s %8s"
              % ("prod", "program", "slot", "head", "classes", "addr8", "shipped", "4+6 move"))
    ship, hyp = collections.Counter(), collections.Counter()
    for label, b, slot, head, cls, ads in macro:
        a = sum(s8(x) for c, x in zip(cls, ads) if (c & 7) == 2)
        h = sum(s8(x) for c, x in zip(cls, ads) if c in (2, 4, 6, 0xA))
        ship[a] += 1
        hyp[h] += 1
        if "--macro" in sys.argv and (head == 0xC62 or len(ship) <= 6):
            print("   %-4s %-26s %5d  %03X  %-9s %-11s %8d %8d"
                  % (label, b, slot, head, "/".join("%X" % c for c in cls),
                     "/".join("%02X" % x for x in ads), a, h))
    print("\n=== ★★ NET DISPLACEMENT over %d macro instances ===" % len(macro))
    print("   shipped (only class 2/A move) : %2d values, range %+d..%+d"
          % (len(ship), min(ship), max(ship)))
    print("   classes 4 and 6 move too      : %2d values, range %+d..%+d"
          % (len(hyp), min(hyp), max(hyp)))
    c62 = [m for m in macro if m[3] == 0xC62]
    if c62:
        a = sum(s8(x) for c, x in zip(c62[0][4], c62[0][5]) if (c & 7) == 2)
        print("   ★ the %d CLASS-2 SPELLING instance(s) net %+d under BOTH models (all class 2)."
              % (len(c62), a))
        print("     shipped: that is %+d against a range of %+d..%+d for the other %d -- an"
              % (a, min(x for x in ship if x != a), max(x for x in ship if x != a),
                 len(macro) - len(c62)))
        print("     OUTLIER.  With 4 and 6 moving it is INSIDE the range (%+d..%+d) and %d of the"
              % (min(hyp), max(hyp), hyp.get(a, 0)))
        print("     %d land on EXACTLY %+d." % (len(macro) - len(c62), a))
    return 0


if __name__ == "__main__":
    sys.exit(main())
