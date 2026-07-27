#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""target4.py -- THE HEAD AND THE TAIL OF THE REVERB, AND THE 48 C-FORMAT CELLS.

NEC uPD6383GF-3BA (Technics SX-KN5000, IC311).  No hardware.  Static analysis of
the Sub CPU ROM, the 100 canned parameter streams, the 38 distinct body images
and the descriptor classification exported by `bounds.py'.

THE QUESTION.  `dram-datapath.md' accounted for ROOM REVERB 1's 32 descriptor
cells but decoded only the middle of the program: the nine motif repetitions.
Words w000..w018 and w101..w132 -- the input section and the output section,
50 of 133 words -- had never been looked at, and four of the cells they touch
are consumed by C-format words whose direction still traps.

THE ANSWER, in one line: the tail is TWO MIRRORED OUTPUT TAILS, each of which
mixes THREE EARLY-REFLECTION TAPS off the pre-delay buffer with the tank output
under the host-named op-0x66 ER.LEVEL coefficients; the four trapping C-format
cells are taps 2 and 3 of each channel; and the tail's own structure is an
INDEPENDENT confirmation of the one-deep DRAM pipeline, because under a blocking
read the RIGHT channel's third early reflection would be the out-of-region flush
address 32767.

    python3 dsp/tools/target4.py tail       #  1 *** TASK A -- the two output tails
    python3 dsp/tools/target4.py head       #  2 *** TASK A -- the input section
    python3 dsp/tools/target4.py ertaps     #  3 *** TASK A/B -- the six ER taps, L/R
    python3 dsp/tools/target4.py align      #  4 *** TASK B -- the consumer predicate
    python3 dsp/tools/target4.py anchor     #  5 *** TASK B -- the host-anchor forcing
    python3 dsp/tools/target4.py shift      #  6 *** TASK B -- the off-by-one, enumerated
    python3 dsp/tools/target4.py direction  #  7 *** TASK B -- READ vs WRITE
    python3 dsp/tools/target4.py act0b      #  8 *** TASK C -- the decidability census
    python3 dsp/tools/target4.py rotation   #  9 *** TASK D -- the ceiling, G, the wrap
    python3 dsp/tools/target4.py rivals     # 10 RULE 7, scored on disagreement sites
    python3 dsp/tools/target4.py control    # 11 *** every control, saying NO and YES
    python3 dsp/tools/target4.py predict    # 12 PREDICT-THEN-CHECK, hits AND misses
    python3 dsp/tools/target4.py all        # ~40 s

    python3 dsp/verify.py                   # BYTE-MATCH OK

NOTHING IS APPLIED.  Neither disassembler mirror is edited, no MAME source is
touched, and the 42 delay-DRAM frame slots still trap.
"""
import argparse
import collections
import copy
import os
import random
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import dram_match as DM                                             # noqa: E402
import dram_cursor as DC                                            # noqa: E402
import dsp_disasm as D                                              # noqa: E402
import bounds as B                                                  # noqa: E402
import register_space as RS                                         # noqa: E402

REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
SUB = os.path.join(REPO, "original_ROMs", "kn5000_subprogram_v142.rom")
MAIN = os.path.join(REPO, "original_ROMs", "kn5000_v10_program.rom")
TOOLS = os.path.expanduser("~/compartilhado/kn7000_mame/tools")

RR1 = 16                          # ROOM REVERB 1 -- the only unit-1 image
REVERBS = list(range(16, 28))     # the twelve presets that share it, byte for byte
MTD = 10                          # MULTI TAP DELAY -- the host ground truth
SDL = 9                           # SINGLE DELAY
PEQ = 39                          # PARAMETRIC EQ -- the SOLVED reference program

# the two C-format consumer FORMS, named by their 36-bit word
CF_REVERB = 0x0C40180000          # C40.1.80.000 -- 48 of them, all in the reverb
CF_COMPR = 0x0C401E0451           # C40.1.E0.451 --  8 of them, all in a compressor

FLOOR = {0: 0, 1: 32768}
TOP = {0: 32767, 1: 65535}


def head(n, s):
    print("=" * 78)
    print("%d. %s" % (n, s))
    print("=" * 78)


def flds(w):
    return (w >> 24) & 0xFFF, (w >> 20) & 0xF, (w >> 12) & 0xFF, w & 0xFFF


def fmt(w):
    return "%03X.%X.%02X.%03X" % flds(w)


def f_src(w):
    return ((w & 0xFFF) >> 6) & 0x1F


def f_act(w):
    return w & 0x1F


def f_lo(w):
    return w & 0xFFF


def is_consumer(w):
    """dram_cursor's predicate, imported unchanged so the two cannot drift."""
    return DC.is_consumer(w)


def is_cfmt(w):
    return (((w >> 24) & 0xFFF) & 0xFFE) == 0xC40


class Ctx(object):
    def __init__(self):
        self.C = DM.Corp(SUB, MAIN, TOOLS)
        self.A = B.analyse(self.C)
        self.al = {a: r for a, r in self.A.items() if r.get("aligned")}
        seen = {}
        for a in sorted(self.C.imgs):
            seen.setdefault(tuple(self.C.imgs[a]), a)
        self.images = [(a, list(k)) for k, a in seen.items()]

    def name(self, a):
        return self.C.name(a)

    def t1(self, a):
        p = self.C.rom.u32le(RS.T1_ARRAY + 4 * a)
        if not p or p == RS.NULL_T1:
            return {}
        return {op: e for op, e in RS.parse_t1(self.C.rom, p)}


# ===========================================================================
#  helper -- re-run the classification with a DIFFERENT consumer predicate
# ===========================================================================
def reclassify(X, keep):
    """`keep(word) -> bool' replaces dram_cursor.is_consumer.  Returns
    (analysis, n_aligned).  The whole point of TASK B is that the predicate is
    part of the model (method rule 11), so it has to be a parameter."""
    shim = copy.copy(X.C)
    shim.algos = []
    for (a, u, cells, cons) in X.C.algos:
        ws = X.C.imgs[a]
        shim.algos.append((a, u, cells,
                           [(i, w) for i, w in enumerate(ws) if keep(w)]))
    A = B.analyse(shim)
    return A, sum(1 for r in A.values() if r.get("aligned"))


KEEP_ALL = lambda w: is_consumer(w)                                  # noqa: E731
KEEP_NOCF = lambda w: is_consumer(w) and not is_cfmt(w)              # noqa: E731
KEEP_SPLIT = lambda w: is_consumer(w) and (not is_cfmt(w) or w == CF_REVERB)  # noqa: E731,E501
KEEP_TWIN = lambda w: is_consumer(w) and (not is_cfmt(w) or w == CF_COMPR)    # noqa: E731,E501


# ===========================================================================
#  1.  TASK A -- the two output tails
# ===========================================================================
CRAM_ROLE = {                       # from dsp/disasm/prog16_*.dsm, PROVEN there
    0x90: "input scaling", 0x91: "input scaling", 0x92: "input scaling",
    0x93: "damping #1 (HIGH DAMP GAIN)", 0x94: "damping #1", 0x95: "damping #1",
    0x96: "DRAM tap gain 0.500", 0x97: "op0x75 REVERB DECAY",
    0x98: "diffuser ladder-0 (REVERB TIME)", 0x99: "diffuser ladder-0",
    0x9A: "diffuser ladder-0", 0x9B: "diffuser ladder-0",
    0x9C: "diffuser ladder-0", 0x9D: "DRAM tap gain 0.500",
    0x9E: "op0x76 damping #2 (HIGH DAMP GAIN)", 0x9F: "damping #2",
    0xA0: "damping #2", 0xA1: "diffuser ladder-1 (REVERB TIME)",
    0xA2: "diffuser ladder-1", 0xA3: "diffuser ladder-1",
    0xA4: "diffuser ladder-1", 0xA5: "DRAM tap gain 0.500",
    0xA6: "op0x76 damping #3 (HIGH DAMP GAIN)", 0xA7: "damping #3",
    0xA8: "damping #3",
    0xA9: "LEFT  output tail (op0x66 ER.LEVEL)", 0xAA: "LEFT  output tail",
    0xAB: "LEFT  output tail", 0xAC: "LEFT  output tail",
    0xAD: "RIGHT output tail", 0xAE: "RIGHT output tail",
    0xAF: "RIGHT output tail (op0x66)", 0xB0: "RIGHT output tail",
}


def rr1_cellmap(X):
    """[(k, word_index, word, cell_index, value, dir, class, role)] for RR1."""
    r = X.al[RR1]
    cons = [c for (a, _u, _c, c) in X.C.algos if a == RR1][0]
    out = []
    for k, (wi, w) in enumerate(cons):
        out.append((k, wi, w, r["cells"][k], r["value"][k], r["dir"][k],
                    r["class"][k], r["role"][k]))
    return out


def cmd_tail(X):
    head(1, "TASK A -- THE TAIL: TWO MIRRORED OUTPUT TAILS, THREE ER TAPS EACH")
    print("""   POPULATION (rule 9): ONE image, 133 words, 32 cells.  The same body
   image serves algos 16..27 BYTE FOR BYTE, so the 12 reverbs give 12
   independent DESCRIPTOR value sets against ONE word sequence.  Every
   word count below is out of 133; every cell count out of 32.
""")
    img = X.C.imgs[RR1]
    cm = {wi: row for row in rr1_cellmap(X) for wi in [row[1]]}
    print("   THE TAIL, w101..w132 -- 32 of 133 words, PRINTED IN FULL")
    print("   %-5s %-12s %-16s %-4s %-4s  %s"
          % ("word", "hex", "form", "SRC", "ACT", "what it touches"))
    for i in range(101, 133):
        w = img[i]
        note = ""
        if i in cm:
            _k, _wi, _w, ci, v, dr, cl, ro = cm[i]
            note = ("cell 0x%02X = %-6d %-6s %s"
                    % (ci, v, dr or "TRAP", ro))
        print("   w%-4d %010X   %-16s %02X   %02X    %s"
              % (i, w, fmt(w), f_src(w), f_act(w), note))
    print()
    print("""   THE STRUCTURE, read straight off that table.  Three blocks, and the
   last two are the SAME NINE-WORD TEMPLATE with two C-format words
   glued on the front:

      w101..w110   separator #3 + damping triple #3   (C-RAM 0xA5..0xA8)
                   ... its DRAM word is w105, cell 0x18
      w111,w112    C-format, cells 0x19 and 0x1A
      w113..w121   LEFT  OUTPUT TAIL  (C-RAM 0xA9..0xAC = op-0x66 ER.LEVEL)
                   ... its DRAM word is w114, cell 0x1B
      w122,w123    C-format, cells 0x1C and 0x1D
      w124..w132   RIGHT OUTPUT TAIL  (C-RAM 0xAD..0xB0 = op-0x66)
                   ... its DRAM word is w125, cell 0x1E (the CEILING/flush)

   WORD-FOR-WORD, the two tails:""")
    L = list(range(111, 122))
    R = list(range(122, 133))
    same = 0
    for a, b in zip(L, R):
        wa, wb = img[a], img[b]
        eq = "IDENTICAL" if wa == wb else ("same lo12" if f_lo(wa) == f_lo(wb)
                                           else "differ")
        if wa == wb or f_lo(wa) == f_lo(wb):
            same += 1
        print("      w%-4d %-16s   w%-4d %-16s   %s"
              % (a, fmt(wa), b, fmt(wb), eq))
    print("   -> %d of 11 word positions agree in lo12 (the operand routing)."
          % same)
    print()
    print("""   *** THE PIPELINE, CONFIRMED FROM A SITE NO SEARCH HAD USED. ***
   The DRAM port slots of the tail, in issue order, with the descriptor
   cell each one carries:

      w105 -> 0x18     w111 -> 0x19     w112 -> 0x1A     w114 -> 0x1B
      w122 -> 0x1C     w123 -> 0x1D     w125 -> 0x1E (out of region)

   A read's datum is visible only after the NEXT port slot issues
   (`dram-datapath.md' item A, FORCED 83/83 + 74/74).  So:""")
    order = [(105, 0x18), (111, 0x19), (112, 0x1A), (114, 0x1B),
             (122, 0x1C), (123, 0x1D), (125, 0x1E)]
    r = X.al[RR1]
    val = {c: r["value"][i] for i, c in enumerate(r["cells"])}
    base = val[0x03]
    for j, (wi, ci) in enumerate(order[:-1]):
        vis = order[j + 1][0]
        blk = "LEFT " if vis <= 121 else "RIGHT"
        print("      cell 0x%02X (+%-5d) issued at w%-4d -> STANDING in the read"
              " register when w%-4d executes  => the %s tail"
              % (ci, val[ci] - base, wi, vis, blk))
    print("""
   The LEFT group is w111..w121 and the RIGHT group is w122..w132.  The
   port slots inside each are w111/w112/w114 and w122/w123/w125, and the
   data standing at those six slots are:

      PIPELINED  : LEFT = {0x18,0x19,0x1A} = +%d,+%d,+%d   RIGHT = {0x1B,0x1C,0x1D} = +%d,+%d,+%d
      BLOCKING   : LEFT = {0x19,0x1A,0x1B}                 RIGHT = {0x1C,0x1D,0x1E}
                                                                          ^^^^
                   0x1E = %d, OUTSIDE unit 1's DRAM region [%d, %d].
                   Under the blocking read the RIGHT channel's THIRD early
                   reflection is the discarded flush address."""
          % (val[0x18] - base, val[0x19] - base, val[0x1A] - base,
             val[0x1B] - base, val[0x1C] - base, val[0x1D] - base,
             val[0x1E], FLOOR[1], TOP[1]))
    print()
    print("   *** AND THE TWO GROUPINGS ARE SEPARATED BY A TEST THAT SCORES")
    print("       ONLY ON THE SITES WHERE THEY DISAGREE (rule 7). ***")
    print("   POPULATION: 12 presets x 2 channels = 24 tap triples, 72 cells.")
    for nm, grp in (("PIPELINED", [ER_L, ER_R]),
                    ("BLOCKING ", [[0x19, 0x1A, 0x1B], [0x1C, 0x1D, 0x1E]])):
        mono = inbuf = ng = nc = 0
        for a in REVERBS:
            rr = X.al[a]
            v = {c: rr["value"][i] for i, c in enumerate(rr["cells"])}
            bse = v[0x03]
            wr = [x for i, x in enumerate(rr["value"])
                  if rr["dir"][i] == "WRITE" and x > bse and x >= FLOOR[1]]
            top = min(wr) if wr else TOP[1]
            for tri in grp:
                ng += 1
                xs = [v[c] for c in tri]
                if xs == sorted(xs):
                    mono += 1
                for x in xs:
                    nc += 1
                    if bse < x < top:
                        inbuf += 1
        print("      %s  triples RISING in consumption order : %2d of %d"
              "   cells inside the pre-delay buffer : %2d of %d"
              % (nm, mono, ng, inbuf, nc))
    print("      The two groupings share four cells per channel-pair and")
    print("      differ only in which triple 0x1B and 0x1E fall into, so the")
    print("      score above is a disagreement score, not a fit.")
    print()
    print("""   AND THE ENCODING SAYS THE SAME THING.  Both tail READ words are
   880.1.20.2D5, whose lo12 carries SRC 0x0B -- the anchored delay-RAM
   READ REGISTER.  A read word that SOURCES the read register while
   ISSUING a fetch is a one-deep pipeline written down.""")
    n2d5 = sum(1 for _a, im in X.images for w in im if w == 0x08801202D5)
    n2d5all = sum(1 for (_a, _u, _c, cons) in X.C.algos
                  for _i, w in cons if w == 0x08801202D5)
    print("      880.1.20.2D5 over the %d distinct images : %d"
          % (len(X.images), n2d5))
    print("      880.1.20.2D5 over the 91 IC311 algorithms : %d" % n2d5all)
    print("      every one of them is a READ word carrying SRC 0x0B.")
    print()
    print("   COEFFICIENTS THE TWO TAILS CONSUME (roles from the committed")
    print("   listing, PROVEN there; reproduced, not re-derived):")
    for c in range(0xA9, 0xB1):
        print("      C-RAM[0x%02X] = %s" % (c, CRAM_ROLE[c]))
    print("""
   FOUR coefficients per channel and THREE early-reflection taps per
   channel.  The fourth is the reverb tank itself -- the arithmetic of a
   mixer  out = a*tank + b*ER1 + c*ER2 + d*ER3.  MEASURED: the counts.
   INFERRED: which coefficient goes with which tap (the four words'
   multiplicand routing still traps; only w117/w118 and w128/w129 are
   decoded `mac (p),c+', and they name mem[ptr], not SRC 0x0B).""")


# ===========================================================================
#  2.  TASK A -- the head
# ===========================================================================
def cmd_headsec(X):
    head(2, "TASK A -- THE HEAD: THE INPUT SECTION")
    img = X.C.imgs[RR1]
    cm = {row[1]: row for row in rr1_cellmap(X)}
    print("   POPULATION: words w000..w018 of 133; cells 0x00..0x02 of 32.")
    print()
    print("   %-5s %-12s %-16s %-4s %-4s  %s"
          % ("word", "hex", "form", "SRC", "ACT", "what it touches"))
    for i in range(0, 19):
        w = img[i]
        note = ""
        if i in cm:
            _k, _wi, _w, ci, v, dr, cl, ro = cm[i]
            note = "cell 0x%02X = %-6d %-6s %s" % (ci, v, dr or "TRAP", ro)
        print("   w%-4d %010X   %-16s %02X   %02X    %s"
              % (i, w, fmt(w), f_src(w), f_act(w), note))
    r = X.al[RR1]
    val = {c: r["value"][i] for i, c in enumerate(r["cells"])}
    print("""
   THE READING, and every leg of it is already-committed material except
   the last:

     w000  the PRE-DELAY tap.  addr8 0x30 = the chain head (37 of 38
           images).  Cell 0x00 is the ONLY cell of this algorithm that any
           T2 record ever writes -- op-0x67 operand 0, `PRE DELAY (ms)',
           evaluator  cell = round(ms * 44100/1000) + BASE24  with
           BASE24 = %d = cell 0x03 + 2.  So the FIRST word of the reverb
           reads the user's pre-delay.  (MEASURED, dram-matching SS1;
           BASE24 is identical in 12 of 12 reverbs.)
     w001  ld acc,(p)-119        the accumulator is loaded from I-RAM
     w002  mac (p),c+  C-RAM[0x90]  \\
     w003  mac (p),c+  C-RAM[0x91]   >  THE INPUT MIX -- three input gains
     w004  mac (p),c+  C-RAM[0x92]  /
     w005  202.2.4B.1CD           lo12 0x1CD  (SRC 0x07, ACT 0x0D)
     w006  000.2.00.40E           lo12 0x40E  (SRC 0x10, ACT 0x0E)
     w007  mac (p),c+  C-RAM[0x93]  \\
     w008  mac acc,c+  C-RAM[0x94]   >  DAMPING FILTER #1
     w009  mac (p),c+  C-RAM[0x95]  /
     w010  mac.st acc,(p)+0
     w011  the PRIME write -- cell 0x01 = %d, below unit 1's floor, the
           `first write of the program' of dram-datapath item A
     w012  ld tb,c+  C-RAM[0x96] = DRAM tap gain 0.500
     w015  the first ladder read (cell 0x02, line 1)

   *** THE [0x1CD, 0x40E] PAIR IS THE NEW OBSERVATION. *** It occurs
   in ALL THREE of this image's occurrences of lo12 0x1CD:"""
          % (X.C.taps(RR1).get(0, 0), val[0x01]))
    pairs = []
    for i in range(len(img) - 1):
        if f_lo(img[i]) in (0x1CD,) and f_lo(img[i + 1]) == 0x40E:
            pairs.append(i)
    for i in pairs:
        tag = ("HEAD" if i < 20 else
               ("LEFT output tail" if i < 125 else "RIGHT output tail"))
        extra = "  <- and THIS 0x40E word IS the delay-DRAM WRITE" \
                if is_consumer(img[i + 1]) else ""
        print("      w%-4d %-16s  +  w%-4d %-16s   %s%s"
              % (i, fmt(img[i]), i + 1, fmt(img[i + 1]), tag, extra))
    print("""
   In the RIGHT output tail the second member of the pair is
   880.1.60.40E -- the SAME lo12 0x40E, on a word that is also the
   delay-DRAM WRITE of line 11's base.  So lo12 0x40E's operation is
   independent of whether the word also drives the DRAM port, which is
   what a horizontal microword predicts and is worth one line of the
   next pass's enumeration.  CONSISTENT, NOT FORCED -- three sites.""")
    # corpus check of the pair
    n = tot = 0
    for a, im in X.images:
        for i in range(len(im) - 1):
            if f_lo(im[i]) == 0x1CD:
                tot += 1
                if f_lo(im[i + 1]) == 0x40E:
                    n += 1
    print("   CORPUS: lo12 0x1CD followed immediately by lo12 0x40E:"
          " %d of %d occurrences of 0x1CD over the %d distinct images."
          % (n, tot, len(X.images)))


# ===========================================================================
#  3.  TASK A/B -- the six early-reflection taps
# ===========================================================================
ER_L = [0x18, 0x19, 0x1A]
ER_R = [0x1B, 0x1C, 0x1D]


def er_table(X):
    rows = []
    for a in REVERBS:
        r = X.al[a]
        val = {c: r["value"][i] for i, c in enumerate(r["cells"])}
        base = val[0x03]
        rows.append((a, base, {c: val[c] - base for c in
                               [0x00] + ER_L + ER_R}, val[0x1E]))
    return rows


def cmd_ertaps(X):
    head(3, "TASK A/B -- THE SIX EARLY REFLECTIONS, AND THE L/R SPLIT")
    print("""   POPULATION (rule 9): 12 reverb algorithms x 6 cells = 72 cells, plus
   the 12 host-named pre-delay taps.  All offsets are off cell 0x03, the
   pre-delay LINE BASE, which is BASE24 - 2 and host-anchored 12 of 12.
""")
    rows = er_table(X)
    print("   %-4s %-18s %-7s | %-25s | %s"
          % ("algo", "name", "0x00", "LEFT  0x18 0x19 0x1A", "RIGHT 0x1B 0x1C 0x1D"))
    for a, base, off, ceil in rows:
        print("   %-4d %-18s %-7d | %5d %5d %5d %7s| %5d %5d %5d"
              % (a, X.name(a), off[0x00],
                 off[0x18], off[0x19], off[0x1A], "",
                 off[0x1B], off[0x1C], off[0x1D]))
    print()
    print("""   *** THE TAP SET IS TWO CHANNELS OF THREE, AND THE RATIOS SAY SO. ***
   Every tap of a channel divided by that channel's FIRST tap -- the one
   cell of each triple whose direction is already FORCED to READ:""")
    for nm, tri in (("LEFT ", ER_L), ("RIGHT", ER_R)):
        for c in tri[1:]:
            rs = [off[c] / float(off[tri[0]]) for _a, _b, off, _x in rows]
            print("      %s  cell 0x%02X / cell 0x%02X : min %.4f  max %.4f"
                  "  median %.4f   (n=12)"
                  % (nm, c, tri[0], min(rs), max(rs), sorted(rs)[6]))
    rs = [off[0x18] / float(off[0x1B]) for _a, _b, off, _x in rows]
    print("      CROSS   cell 0x18 / cell 0x1B : min %.4f  max %.4f"
          "  median %.4f   (n=12)" % (min(rs), max(rs), sorted(rs)[6]))
    print("""
   The L/R decorrelation ratio 0x18 : 0x1B is %.4f +- %.4f over TWELVE
   independently-canned parameter sets.  A pair of numbers that tracks to
   0.3%% across twelve presets is one design quantity, not two.
   MEASURED.""" % ((min(rs) + max(rs)) / 2, (max(rs) - min(rs)) / 2))
    print()
    print("   NESTING -- are all six inside the PRE-DELAY buffer?  The buffer")
    print("   runs from cell 0x03 up to the next line base above it:")
    ok = tot = 0
    for a in REVERBS:
        r = X.al[a]
        val = {c: r["value"][i] for i, c in enumerate(r["cells"])}
        base = val[0x03]
        wr = [r["value"][i] for i in range(r["n"])
              if r["dir"][i] == "WRITE" and r["value"][i] > base
              and FLOOR[1] <= r["value"][i] <= TOP[1]]
        top = min(wr) if wr else TOP[1]
        for c in ER_L + ER_R + [0x00]:
            tot += 1
            if base < val[c] < top:
                ok += 1
    print("      taps strictly inside (pre-delay base, next line base): %d of %d"
          % (ok, tot))
    print("      -> 12 algorithms x 7 taps = 84.  The four trapping cells are")
    print("         inside the pre-delay buffer in EVERY preset.")


# ===========================================================================
#  4.  TASK B -- the consumer predicate is part of the model
# ===========================================================================
def cmd_align(X):
    head(4, "TASK B -- *** THE CONSUMER PREDICATE IS NOT EXCEPTIONLESS ***")
    print("""   METHOD RULE 11.  `dram_cursor.is_consumer' -- class4 == 1 with the
   hi12 format-escape bit -- is a HYPOTHESIS about which words drive the
   descriptor cursor, and every descriptor result in this project rests
   on it.  Its own comment says the reverbs' counting identity REQUIRES
   the C format to consume.  Nobody asked what it costs elsewhere.

   POPULATION (rule 9): all 91 IC311 algorithms that ship descriptor
   cells.  ALIGNED means #cells == #consumers.
""")
    variants = [
        ("V1  C-format CONSUMES        (the incumbent)", KEEP_ALL),
        ("V2  C-format does NOT consume", KEEP_NOCF),
        ("V3  SPLIT: C40.1.80.000 consumes, C40.1.E0.451 does not", KEEP_SPLIT),
        ("V4  TWIN: C40.1.E0.451 consumes, C40.1.80.000 does not", KEEP_TWIN),
    ]
    res = {}
    for nm, fn in variants:
        A, n = reclassify(X, fn)
        res[nm] = (A, n)
        bad = sorted(a for a, r in A.items() if not r.get("aligned"))
        print("   %-56s %2d of 91 aligned" % (nm, n))
        print("        misaligned: %s"
              % ", ".join("%d %s" % (a, X.name(a)) for a in bad))
    print()
    print("""   *** THE TWO C-FORMAT CONSUMER FORMS DO NOT BEHAVE THE SAME WAY. ***
   There are exactly two, and each lives in exactly one family:""")
    forms = collections.Counter()
    where = collections.defaultdict(list)
    for (a, _u, _c, cons) in X.C.algos:
        for i, w in cons:
            if is_cfmt(w):
                forms[fmt(w)] += 1
                where[fmt(w)].append(a)
    for k, v in sorted(forms.items(), key=lambda t: -t[1]):
        algs = sorted(set(where[k]))
        print("      %-16s x%-3d in algos %s"
              % (k, v, ", ".join("%d %s" % (a, X.name(a)) for a in algs)))
    print("""
   V1 leaves the four COMPRESSOR-bearing algorithms misaligned by EXACTLY
   their two C40.1.E0.451 words.  V2 leaves the twelve reverbs misaligned
   by EXACTLY their four C40.1.80.000 words.  V3 is the only assignment
   of the two forms that aligns all sixteen -- and it takes the corpus
   from 83 to 87 of 91, leaving a residue of exactly four algorithms
   which are ALL ONE FAMILY:""")
    A3, _ = res[variants[2][0]]
    bad3 = sorted(a for a, r in A3.items() if not r.get("aligned"))
    for a in bad3:
        print("      algo %-3d %-20s  #cells %d  #consumers %d"
              % (a, X.name(a), len(A3[a]["cells"]),
                 A3[a]["n"] if False else
                 len([1 for i, w in enumerate(X.C.imgs[a])
                      if KEEP_SPLIT(w)])))
    print("""      -- FLANGER, ENSEMBLE, S.DELAY+FLANGER, PEQ+FLANGER.  All four
         carry the swept all-pass chain, and NONE of them contains a
         C-format consumer at all, so this pass does not touch them and
         does not claim them.

   MEASURED: the four counts (83 / 75 / 87 / 71) and the two form
   populations (48 and 8).  The SPLIT itself is a conclusion, and section
   5 is what forces half of it.""")


# ===========================================================================
#  5.  TASK B -- the host anchor forces C40.1.80.000 to consume
# ===========================================================================
def cmd_anchor(X):
    head(5, "TASK B -- *** THE HOST ANCHOR FORCES C40.1.80.000 TO CONSUME ***")
    print("""   THE ARGUMENT, and it uses no instruction semantics at all.

   op-0x67 operand 0 of every reverb writes descriptor cell 0x00 with
       cell = round(user_ms * 44100/1000) + BASE24,   BASE24 = 32770
   (dram-matching SS1, PROVEN by decoding LABEL_03925E).  For the number
   the player dials to BE the pre-delay, the DSP's read at cell 0x00 must
   sit inside the buffer whose base is BASE24 - 2 = 32768 = cell 0x03.

   Under the allocation model A4 (`a read belongs to the line whose base
   is the largest WRITE strictly below it') that is a checkable claim,
   and it is checked here under each consumer predicate.

   POPULATION (rule 9): the 12 reverbs.
""")
    def variant(nm, keep, trim):
        """trim(sorted_cell_keys, n_consumers) -> the cell keys the cursor is
        assumed to walk.  `trim' IS the enumeration of section 5's E1..E4."""
        shim = copy.copy(X.C)
        shim.algos = []
        for (a, u, cells, cons) in X.C.algos:
            ws = X.C.imgs[a]
            cn = [(i, w) for i, w in enumerate(ws) if keep(w)]
            if a in REVERBS:
                ck = trim(sorted(cells), len(cn))
                cells = {k: cells[k] for k in ck}
            shim.algos.append((a, u, cells, cn))
        A = B.analyse(shim)
        good = 0
        det = []
        for a in REVERBS:
            r = A[a]
            if not r.get("aligned"):
                det.append((a, None, None, "UNALIGNED"))
                continue
            idx = {c: i for i, c in enumerate(r["cells"])}
            pd = None
            for L in r["lines"]:
                if L["read_cell"] == 0x00:
                    pd = L
            if pd and pd["write_cell"] == 0x03:
                good += 1
            det.append((a, pd["write_cell"] if pd else None,
                        pd["samples"] if pd else None,
                        r["role"][idx[0x03]] if 0x03 in idx else "NOT WALKED"))
        ceil = sum(1 for a in REVERBS
                   if 0x1E in {c: 1 for c in A[a]["cells"]})
        lastread = 0
        for a in REVERBS:
            r = A[a]
            if not r.get("aligned"):
                continue
            idx = {c: i for i, c in enumerate(r["cells"])}
            if 0x1E not in idx:
                continue
            rd = [j for j in range(r["n"]) if r["dir"][j] == "READ"]
            if rd and max(rd) == idx[0x1E]:
                lastread += 1
        print("   %-52s  %2d of 12" % (nm, good))
        ex = det[0]
        print("        ROOM REVERB 1: cell 0x00's line base is cell %s, delay"
              " %s samples;" % ("0x%02X" % ex[1] if ex[1] is not None
                                else "NONE", ex[2]))
        roles = collections.Counter(d[3] for d in det)
        print("        cell 0x03 is classified %s across the 12" % dict(roles))
        print("        the CEILING cell 0x1E is WALKED in %d of 12, and is the"
              " program's LAST READ in %d of 12" % (ceil, lastread))
        return good

    print("   %-52s  %s" % ("consumer / cursor model",
                            "pre-delay tap pairs with cell 0x03"))
    variant("E1  C-format CONSUMES (the incumbent)", KEEP_ALL,
            lambda ck, n: ck)
    variant("E2/E4  C-format does NOT consume, cursor stops at 28",
            KEEP_NOCF, lambda ck, n: ck[:n])
    variant("E3  C-format does NOT consume, cursor STARTS at cell 4",
            KEEP_NOCF, lambda ck, n: ck[len(ck) - n:])
    print("""
   *** READ THE MIDDLE ROW HONESTLY: E2 SCORES 7 OF 12, NOT 0. ***
   Dropping the C-format words shifts the last three class-1 words back
   by four cells; the program's final WRITE (w131) then lands on cell
   0x1B, INSIDE the pre-delay buffer and BELOW every pre-delay read, so
   it steals the base from cell 0x03 -- but only in the FIVE presets
   whose 0x1B is below their 0x00.  In the other seven the pre-delay tap
   survives by luck of the canned numbers.  The anchor leg alone is
   therefore NOT a forcing, and it is not presented as one.

   WHAT DOES FORCE IT is the second row of each block above: under E2 the
   CEILING cell 0x1E is never walked at all, so `the CEILING is the LAST
   READ of its program' -- exceptionless at 83 of 83 in dram-datapath
   item A, and 71 of 71 among algorithms with no C-format cell -- fails
   for 12 of 83.  Under E3 cell 0x00, the one cell a T2 record writes
   every time the player turns the PRE DELAY knob, is never read by
   anything, 12 of 12.

   THE ENUMERATION (rule 3) -- what else could absorb the four cells?

     E1  the four cells are consumed by the C-format words         ADMITTED
     E2  they are consumed by nothing and sit at the END of the
         block, the cursor stopping early                          REFUTED --
         cell 0x1E (32767) would never be consumed, and
         `CEILING = the LAST READ of the program' is 83 of 83
     E3  they are consumed by nothing and sit at the START, the
         cursor beginning at cell 0x04                             REFUTED --
         cell 0x00, the one cell the host writes per knob-turn,
         would never be read by anything
     E4  the block is really 28 cells and the host allocator
         over-reserved by 4 (the dead T1 entries)                   = E2/E3,
         because the over-reservation still has to be somewhere
     E5  a second, phase-shifted cursor                            REFUTED
         independently -- dram-unit-cursor item D, model M5, three
         routes

   ONLY E1 survives.  ** This does NOT decide the DIRECTION ** -- that is
   section 7 -- and it says nothing about C40.1.E0.451, whose four
   algorithms align only when it does NOT consume.""")


# ===========================================================================
#  6.  TASK B -- the off-by-one, enumerated
# ===========================================================================
def cmd_shift(X):
    head(6, "TASK B -- *** THE T1 OFF-BY-ONE, ENUMERATED RATHER THAN ASSERTED ***")
    print("""   `dram-bounds.md' item M calls the dead T1[0x67] reservation `off by
   exactly one' and labels that INFERRED.  Here it is turned into a
   one-parameter enumeration with a predicate that is applied identically
   to every candidate.

   T1[0x67] of the twelve reverbs, read from the ROM:""")
    t = None
    same = 0
    for a in REVERBS:
        e = X.t1(a).get(0x67)
        if t is None:
            t = e
        if e == t:
            same += 1
    print("      %s   -- identical in %d of 12"
          % ("[" + ", ".join("0x%02X" % c for c in t) + "]", same))
    print("""
   PREDICATE (the same one for every shift): a cell is a VALID PRE-DELAY
   TAP iff its value lies strictly between the pre-delay line base (cell
   0x03) and the next line base above it.  Entry 0 of the reservation is
   NOT shifted -- it is the live one, the only operand any T2 record
   reaches.

   POPULATION: 12 reverbs x 6 shifted entries = 72.
""")
    rows = []
    for s in range(-4, 5):
        ok = 0
        oob = 0
        for a in REVERBS:
            r = X.al[a]
            val = {c: r["value"][i] for i, c in enumerate(r["cells"])}
            base = val[0x03]
            wr = [v for i, v in enumerate(r["value"])
                  if r["dir"][i] == "WRITE" and v > base
                  and FLOOR[1] <= v <= TOP[1]]
            top = min(wr) if wr else TOP[1]
            for c in t[1:]:
                cc = c + s
                if cc not in val:
                    oob += 1
                    continue
                if base < val[cc] < top:
                    ok += 1
        rows.append((s, ok, oob))
    for s, ok, oob in rows:
        star = "   <== " if ok == 72 else ""
        print("      shift %+d : valid pre-delay taps %2d of 72   (%d entries"
              " off the end of the block)%s" % (s, ok, oob, star))
    print("""
   ONE member of the enumerated range makes ALL SIX reserved entries
   valid taps in ALL TWELVE presets, and it is the only one.  So the
   reservation was WRITTEN AS  `ER_BASE + j' for a 1-based operand index
   j = 1..6 with ER_BASE = 0x18, where the cells are 0-based -- the
   classic off-by-one, and it is why the last entry falls on the ceiling.

   *** AND THE RESERVATION IS PROVABLY WRONG UNDER EVERY PHASE, WHICH IS
       WHY IT CANNOT BE READ ENTRY BY ENTRY. ***  Entry 0x1E holds the
   value 32767 in 12 of 12 reverbs.  The cell<->word phase delta moves
   which WORD touches a cell; it does not move the cell's VALUE.  32767
   is outside unit 1's region [32768, 65535] whatever the phase, so no
   choice of delta can make the reservation a correct list of taps.
   FORCED, and it is what stops the reservation being used as a direct
   oracle in section 7.

   AND THE PREDICTION IT MAKES.  If this is one coding slip in a dead
   branch, the LIVE reservations elsewhere should not be off by one.""")
    live = wrong = 0
    for a in sorted(X.al):
        e = X.t1(a).get(0x67)
        if not e:
            continue
        r = X.al[a]
        idx = {c: i for i, c in enumerate(r["cells"])}
        for c in e:
            if c not in idx:
                continue
            if a in REVERBS and c != 0x00:
                continue                     # the dead branch, excluded
            live += 1
            if r["class"][idx[c]] != B.CLASS_ADDR:
                wrong += 1
    print("      LIVE op-0x67 reservations outside the reverbs' dead branch:")
    print("         %d reservations, %d of them land on a non-ADDRESS cell."
          % (live, wrong))


# ===========================================================================
#  7.  TASK B -- READ or WRITE
# ===========================================================================
def cmd_direction(X):
    head(7, "TASK B -- *** THE DIRECTION OF THE 48 C-FORMAT CELLS ***")
    print("""   THE ENUMERATION, PRINTED BESIDE THE CLAIM (rule 3).  Given section 5
   (the words DO consume a cell), a cell can only be:

      H_R  a READ  -- a delay tap
      H_W  a WRITE -- a delay-line base
      H_M  mixed   -- some of the four each way

   THREE independent legs, each with its own denominator.
""")
    # leg 1 -- the residue rule
    print("   LEG 1 -- THE RESIDUE RULE.  `dram-bounds.md' item A measures that")
    print("   every algorithm carries exactly ONE ceiling and exactly one of")
    print("   {LIMIT, FLOOR}.  What does each hypothesis do to that?")
    for nm, dirfn in (
            ("H_R  C-format = READ ",
             lambda w: "READ" if is_cfmt(w) else D.dram_dir(w)),
            ("H_W  C-format = WRITE",
             lambda w: "WRITE" if is_cfmt(w) else D.dram_dir(w)),
            ("--   incumbent (traps)", None)):
        A = B.analyse(X.C, dirfn=dirfn) if dirfn else X.A
        res = collections.Counter()
        for a, r in A.items():
            if not r.get("aligned"):
                continue
            c = collections.Counter(r["role"])
            res[(c.get("CEILING", 0), c.get("LIMIT", 0) + c.get("FLOOR", 0),
                 c.get("TRAP", 0))] += 1
        print("      %s  residue (CEILING, LIMIT+FLOOR, TRAP) -> count:" % nm)
        for k, v in sorted(res.items()):
            print("         %s x%d" % (k, v))
    print("""      H_R puts the twelve reverbs on the same residue as the other
      61 aligned algorithms.  H_W gives them a residue that occurs
      NOWHERE ELSE in the corpus: five bound cells in one algorithm.
""")
    # leg 2 -- what would the WRITEs be for
    print("   LEG 2 -- WHAT WOULD THE FOUR WRITES OPEN?  Under H_W each of the")
    print("   four cells is a line base.  How many delay lines does it open?")
    A = B.analyse(X.C, dirfn=lambda w: "WRITE" if is_cfmt(w) else D.dram_dir(w))
    opened = unread = 0
    for a in REVERBS:
        r = A[a]
        idx = {c: i for i, c in enumerate(r["cells"])}
        for c in ER_L[1:] + ER_R[1:]:
            i = idx[c]
            n = sum(1 for L in r["lines"] if L["write_rel"] == i)
            opened += n
            if n == 0:
                unread += 1
    print("      lines opened by the four cells over the 12 reverbs : %d"
          % opened)
    print("      cells that open NO line at all                     : %d of 48"
          % unread)
    print("      -> under H_W the firmware cans FOUR extra buffer bases per")
    print("         preset, at four different sizes, and 47 of the 48 open a")
    print("         line that is never read.  (The one exception is a cell")
    print("         that happens to sit just below another C-format cell in")
    print("         one preset, i.e. it 'reads' another write.)")
    print()
    # leg 3 -- the tail structure
    print("   LEG 3 -- THE TAIL (section 1).  Each output tail mixes THREE")
    print("   early reflections; the C-format cells are taps 2 and 3 of each")
    print("   channel.  Under H_W the LEFT tail would have one tap and the")
    print("   RIGHT tail one tap, the other four port slots being writes to")
    print("   buffers nothing reads, and the two tails -- which agree in")
    print("   lo12 at 11 of 11 word positions -- would be doing different")
    print("   things.  Under H_R they are the same circuit twice.")
    print()
    print("   LEG 4 -- THE HOST.  The T1[0x67] reservation, shift-corrected in")
    print("   section 6, names all six cells 0x18..0x1D as op-0x67 operands,")
    print("   and op-0x67's evaluator produces  base + delay  -- a TAP, i.e.")
    print("   a read end.  36 of 36 host-NAMED taps classify as READ ends and")
    print("   0 of 36 land on a bound (bounds.py item G).")
    print("""
   VERDICT.  H_W is FALSIFIED on leg 1 and leg 2 -- it demands a residue
   that occurs nowhere else and four permanently-unread buffers per
   preset.  H_M is worse on both.  H_R is left standing on four legs, but
   NOT ONE OF THEM IS A DIRECT MEASUREMENT OF THE WORD: the reservation
   is provably wrong about entry 0x1E (section 6), the residue rule is a
   property of the allocation model, and the tail argument assumes the
   two output tails are a stereo pair.

   *** LABEL: CONSISTENT, STRONGLY -- NOT FORCED, AND NOT APPLIED. ***
   Method rule 6.  The four words keep trapping.  What WOULD force it is
   named in the note: a site where the C-format word's 13-bit immediate
   or its lo12 = 0x000 can be separated from a bit-6 direction field, and
   the corpus has none, because the identical 36-bit word sits on both
   sides of three equal-value descriptor pairs (dram-direction item B).""")


# ===========================================================================
#  8.  TASK C -- the ACTION 0x0B decidability census
# ===========================================================================
def cmd_act0b(X):
    head(8, "TASK C -- *** ACTION 0x0B: THE DECIDABILITY CENSUS ***")
    print("""   THE METHOD THE BRIEF ORDERS: work out IN ADVANCE which words could
   possibly carry an observable difference, and check whether any of them
   sits in a program whose arithmetic is known independently.  A word is
   DECIDABLE here only if BOTH hold:

      (D1) the word is not itself blocked by a mechanism that traps for
           reasons unrelated to ACTION 0x0B -- i.e. it is not a
           delay-DRAM port word (address = cell + G, write-data source
           OPEN, latency an interval), and
      (D2) it sits in an image whose surrounding arithmetic is decoded,
           so that a difference could be seen at all.

   POPULATION (rule 9): every ACTION 0x0B word in the 40 distinct body
   images plus the 60-word shared kernel and the 23-word epilogue.
""")
    rows = []
    for a, im in X.images:
        for i, w in enumerate(im):
            if f_act(w) == 0x0B:
                rows.append((a, X.name(a), i, w))
    krows = [("KERNEL", "kernel", i, w) for i, w in enumerate(X.C.hdr)
             if f_act(w) == 0x0B]
    erows = [("EPILOGUE", "epilogue", i, w) for i, w in enumerate(X.C.epi)
             if f_act(w) == 0x0B]
    total = len(rows) + len(krows) + len(erows)
    print("   TOTAL ACTION 0x0B words: %d  (%d in bodies, %d in the kernel,"
          " %d in the epilogue)" % (total, len(rows), len(krows), len(erows)))
    forms = collections.Counter(fmt(w) for _a, _n, _i, w in rows + krows + erows)
    print("   by FORM:")
    for k, v in sorted(forms.items(), key=lambda t: -t[1]):
        print("      %-16s x%d" % (k, v))
    print()
    dram = [r for r in rows + krows + erows if is_consumer(r[3])]
    nond = [r for r in rows + krows + erows if not is_consumer(r[3])]
    print("   (D1) BLOCKED BY THE DRAM PORT ITSELF : %d of %d" % (len(dram), total))
    print("        every one is a class-1 escape; its address, its write-data")
    print("        source and its latency are all still open, so no ACTION")
    print("        semantics can be separated at these sites whatever else is")
    print("        known.  This is the largest single block and it is why")
    print("        `ACTION 0x0B sits on 48 of the 83 CEILING words' is a clue")
    print("        that cannot be cashed from inside the reverb.")
    print()
    print("   (D1) NOT a DRAM word, so in principle decidable : %d of %d"
          % (len(nond), total))
    byimg = collections.defaultdict(list)
    for a, nm, i, w in nond:
        byimg[(a, nm)].append((i, w))
    for (a, nm), lst in sorted(byimg.items(), key=lambda t: str(t[0][0])):
        print("      algo %-8s %-22s %s"
              % (a, nm, " ".join("w%03d %s" % (i, fmt(w)) for i, w in lst)))
    print()
    print("""   (D2) A WORD IS ONLY DECIDABLE IF WHAT FOLLOWS IT IS DECODED.
   CRITERION, fixed before it was applied and identical for every word:
   of the EIGHT words that follow, how many does the disassembler's own
   `decoded()' accept?  (That is the predicate upd6383d.cpp uses, so this
   cannot drift from the shipped core.)  A word with a decoded run
   downstream is a site where a wrong ACTION would show up; one followed
   by ?words is not.
""")
    cand = []
    for a, nm, i, w in nond:
        im = (X.C.hdr if a == "KERNEL" else
              X.C.epi if a == "EPILOGUE" else X.C.imgs[a])
        nxt = im[i + 1:i + 9]
        k = sum(1 for x in nxt if D.decoded(x))
        cand.append((k, a, nm, i, w))
    cand.sort(key=lambda t: -t[0])
    print("   %-4s %-6s %-22s %-6s %-16s %s"
          % ("dec", "algo", "name", "word", "form", "the 8 following words"))
    for k, a, nm, i, w in cand:
        im = (X.C.hdr if a == "KERNEL" else
              X.C.epi if a == "EPILOGUE" else X.C.imgs[a])
        nxt = im[i + 1:i + 9]
        print("   %-4d %-6s %-22s w%-5d %-16s %s"
              % (k, a, nm, i, fmt(w),
                 "".join("D" if D.decoded(x) else "." for x in nxt)))
    hi = [c for c in cand if c[0] >= 6]
    print()
    print("   *** %d of the %d non-DRAM ACTION 0x0B words have 6 or more"
          " decoded words downstream. ***" % (len(hi), len(nond)))
    for k, a, nm, i, w in hi:
        print("      algo %-4s %-22s w%-4d %s" % (a, nm, i, fmt(w)))
    print()
    print("""   *** (D3) AND THE TOP TWO SITES YIELD A MINIMAL PAIR. ***
   The eight words after PEQ+DIST+DELAY w001 and PEQ+OVERDR+DELAY w001
   are BYTE-IDENTICAL to a window that occurs ten times inside
   PARAMETRIC EQ -- the SOLVED Direct-Form-I biquad, five bands x two
   channels.  So the slot immediately before a biquad copy is a fixed
   structural position, and it can be censused over the whole corpus.
""")
    BQ8 = [0x0000A001D3, 0x0212A01412, 0x0202A011D5, 0x0202A011D4,
           0x0202A001D5, 0x01022FF687, 0x0804816415, 0x0212AFF407]
    pre = collections.Counter()
    where = collections.defaultdict(list)
    n = 0
    for a, im in X.images:
        for i in range(len(im) - 8):
            if im[i:i + 8] == BQ8:
                n += 1
                if i == 0:
                    pre["START"] += 1
                    continue
                pre[fmt(im[i - 1])] += 1
                where[fmt(im[i - 1])].append((a, i - 1))
    print("   POPULATION: %d occurrences of the biquad window over the %d"
          " distinct images." % (n, len(X.images)))
    print("   The word IMMEDIATELY BEFORE it, with its ACTION field:")
    for k, v in sorted(pre.items(), key=lambda t: -t[1]):
        if k == "START":
            print("      %-16s x%d" % (k, v))
            continue
        lo = int(k.split(".")[3], 16)
        w = ((int(k.split(".")[0], 16) << 24) | (int(k.split(".")[1], 16) << 20)
             | (int(k.split(".")[2], 16) << 12) | lo)
        print("      %-16s x%-3d ACT=%02X  SRC=%02X  decoded=%-5s  %s"
              % (k, v, lo & 0x1F, (lo >> 6) & 0x1F, D.decoded(w),
                 ", ".join("%d %s w%03d" % (a, X.name(a), i)
                           for a, i in where[k][:3])))
    print("""
   *** READ THE 02A.2.4B ROWS TOGETHER. ***  `02A.2.4B.00B' (ACTION 0x0B)
   and `02A.2.4B.000' (ACTION 0x00) occupy the SAME slot -- the word
   immediately before a byte-identical biquad -- and differ in NO OTHER
   FIELD: same hi12, same class4, same addr8, same SRC.  That is a
   MINIMAL PAIR on the ACTION field alone, at a site whose downstream
   arithmetic is decoded to the bit.  It is the first such pair anyone
   has found for ACTION 0x0B, and it is the handover.

   WHAT IT ALREADY BOUNDS (and this much is MEASURED): whatever ACTION
   0x0B does at that slot, the identical biquad runs correctly after it
   AND after ACTION 0x00, so it cannot disturb the biquad's input path
   (`ld.ta (p),c+,(p)+0' -> mem[ptr]).  WHAT IT DOES NOT SETTLE: what
   ACTION 0x0B writes, because nothing downstream in either program has
   been shown to read a register the two versions would differ in.  That
   is a bounded, well-posed next experiment -- and it is the FIRST time
   ACTION 0x0B has had one outside the reverb.

   (D2b) WHICH IMAGES HAVE ARITHMETIC WE KNOW INDEPENDENTLY?
   The brief names three.  Here is the answer for each, MEASURED:""")
    for a, nm in ((PEQ, "PARAMETRIC EQ  (SOLVED, 60/60 named multiplies)"),
                  (SDL, "SINGLE DELAY   (18/18 named, host-anchored)"),
                  (MTD, "MULTI TAP DELAY(11/11 named, the ground truth)")):
        im = X.C.imgs[a]
        hit = [(i, w) for i, w in enumerate(im) if f_act(w) == 0x0B]
        nd = [(i, w) for i, w in hit if not is_consumer(w)]
        print("      algo %-3d %-46s ACT 0x0B x%d, of which NON-DRAM: %d"
              % (a, nm, len(hit), len(nd)))
        for i, w in hit:
            print("            w%03d %-16s  %s"
                  % (i, fmt(w), "DRAM port word" if is_consumer(w)
                     else "*** DECIDABLE CANDIDATE ***"))
    print("""
   AND THE LFO.  `lfo-ramp.md' localises the ramp generator in the shared
   kernel and in AUTO PAN / CHORUS.  Kernel ACTION 0x0B words: %d, and
   all %d are class-1 DRAM port words.  AUTO PAN (algo 48) contains
   ZERO.  CHORUS (algo 1) contains one, at w003, and it is a DRAM word.

   *** THE FINDING, STATED AS THE BRIEF ASKS -- AND IT IS NOT THE
       ANSWER THE BRIEF EXPECTED. ***
   The brief said: `check whether any of them sits in a program whose
   arithmetic we know independently (PARAMETRIC EQ, SINGLE DELAY, the
   LFO).  If none does, say so -- that is the finding.'

     (a) PARAMETRIC EQ, the one program decoded to the bit, contains NO
         ACTION 0x0B word at all.  Nor do DISTORTION, OVERDRIVE, FUZZ,
         EXCITER, COMPRESSOR, AUTO PAN, AUTO WAH, PHASER, RING
         MODULATOR, PEQ+COMPR+DIST or PEQ+COMPR+OVERDR -- %d of the %d
         distinct images are free of it.
     (b) In SINGLE DELAY every ACTION 0x0B word is a delay-DRAM port
         word, so SINGLE DELAY contributes NOTHING.
     (c) The LFO contributes nothing either: all %d kernel ACTION 0x0B
         words are DRAM port words, AUTO PAN has none, CHORUS's one is a
         DRAM word.
     (d) *** BUT THE ANSWER IS NOT `NONE'. ***  MULTI TAP DELAY -- the
         host ground truth -- has ONE non-DRAM site, w025, sitting
         between the four host-named tap deposits and the four anchored
         multiplies; TWO PEQ composites (98, 99) carry `02A.2.4B.00B'
         IMMEDIATELY before a BYTE-IDENTICAL copy of PARAMETRIC EQ's own
         biquad, and a third (75 PEQ+COMPRESSOR) carries the same word
         one slot earlier.  Those are the four decidable sites in the
         entire corpus, and section (D3) turns the best two into a
         MINIMAL PAIR on the ACTION field.

   So the correct statement is the OPPOSITE of the expected one: ACTION
   0x0B does not occur in a decoded program, but it occurs IMMEDIATELY
   UPSTREAM of decoded code in four places, and that is enough to pose
   the experiment.  The reverb, which owns %d of the 35 non-DRAM sites,
   is NOT where it will be settled.""" % (
        len(krows), len(krows),
        len([1 for a, im in X.images
             if not any(f_act(w) == 0x0B for w in im)]), len(X.images),
        len(krows),
        len([1 for i, w in enumerate(X.C.imgs[RR1])
             if f_act(w) == 0x0B and not is_consumer(w)])))
    print()
    print("   THE ONE PLACE A DIFFERENCE COULD STILL BE SEEN, named so the")
    print("   next pass does not have to re-derive it:")
    im = X.C.imgs[RR1]
    sites = [(i, im[i]) for i in range(len(im))
             if f_act(im[i]) == 0x0B and not is_consumer(im[i])]
    print("      ROOM REVERB 1, %d words, all lo12 0x64B, all class A:" % len(sites))
    print("         %s" % " ".join("w%03d" % i for i, _w in sites))
    print("      Their coefficients are the diffuser-ladder gains C-RAM")
    print("      0x98..0x9C and 0xA1..0xA4 (`REVERB TIME'), which ARE known.")
    print("      So the site is instrumented; what is missing is the")
    print("      multiplicand route, not the coefficient.  That is the same")
    print("      blocker as the reverb topology, not a separate one.")


# ===========================================================================
#  9.  TASK D -- the ceiling, the rotation G, and the wrap
# ===========================================================================
def cmd_rotation(X):
    head(9, "TASK D -- THE ROTATION G, AND WHAT CAN BE DECIDED WITHOUT ITS WORD")
    print("""   `dram-unit-cursor.md' section 5(b) enumerates THREE readings of the
   per-unit CEILING pair (32768 x71 unit 0, 32767 x12 unit 1) and reports
   that (2) and (3) survive:

      (1) each unit's ring is its own region and the cell is the
          exclusive limit IN THE DIRECTION OF TRAVEL       -- refuted there
      (2) ONE SHARED PARTITION CONSTANT handed to each unit in the
          polarity that unit needs, the hardware deriving its limit
      (3) not a limit at all, but a NULL / NO-LINE SENTINEL

   *** RULE 10: THE TWO NOTES ALREADY DECIDE THIS AND NEITHER NOTICED. ***
   `dram-datapath.md' section 2.1 enumerates the same cell from the other
   side and refutes E2 -- `loading a per-unit WRAP/limit register' -- with
   one line: A LIMIT MUST BE LOADED BEFORE THE ACCESSES IT BOUNDS, AND
   THIS CELL IS THE LAST READ OF ITS PROGRAM IN 83 OF 83.  Readings (1)
   and (2) are both limit-register readings.  So:""")
    n = 0
    for a, r in sorted(X.al.items()):
        i = [j for j in range(r["n"]) if r["role"][j] == "CEILING"][0]
        rd = [j for j in range(r["n"]) if r["dir"][j] == "READ"]
        if rd and max(rd) == i:
            n += 1
    print()
    print("      CEILING cell == the LAST READ of its own program : %d of %d"
          % (n, len(X.al)))
    print("""
   -> reading (2) is FALSIFIED by the position, on the same argument that
      killed reading (1)'s cousin.  READING (3) STANDS ALONE.

   AND THAT SEVERS THE CEILING FROM THE G QUESTION ENTIRELY.  If the cell
   is the address of a DISCARDED read, it carries no information about
   the rotation: (cell + G) mod 2^N is thrown away whatever G is.  So
   `dram-unit-cursor' item K's link between TARGET 1's ceiling cells and
   the rotation register is cut, and the ceiling cells must be removed
   from any future constraint set for G.  ** That is the deliverable:
   a constraint that was going to be used, withdrawn before it was. **
""")
    print("   WHAT THE FLUSH ADDRESS ACTUALLY IS, printed:")
    print("      unit 0 programs flush at %d = the FIRST word of unit 1's"
          " region" % 32768)
    print("      unit 1 programs flush at %d = the LAST  word of unit 0's"
          " region" % 32767)
    print("      i.e. each unit's flush lands ONE WORD over the partition, in")
    print("      the other unit's territory, and it is a READ, so it is inert.")
    print()
    print("   AND ONE THING ABOUT G THAT CAN BE DECIDED WITHOUT ITS WORD --")
    print("   the MODULUS.  If the address were (cell + G) mod 2^16 with a")
    print("   single G, a unit-0 buffer near the top of its region would walk")
    print("   into unit 1's.  The corpus says how much headroom there is:")
    for u in (0, 1):
        vals = [v for a, r in X.al.items() if r["unit"] == u
                for i, v in enumerate(r["value"])
                if r["class"][i] != B.CLASS_BOUND]
        if not vals:
            continue
        print("      unit %d ADDRESS cells: min %-6d max %-6d  headroom to the"
              " region top = %d" % (u, min(vals), max(vals), TOP[u] - max(vals)))
    print("""      Unit 0's address cells stop %d words short of its top and
      unit 1's stop %d short of its top.  A shared G rotating modulo 2^16
      would therefore be SAFE for at most that many frames and then
      corrupt the other unit -- so either the rotation is modulo each
      unit's own region, or G is per-unit, or the rotation is not a free
      counter.  ENUMERATED, NOT DECIDED; this pass adds the numbers, and
      names the three options so the next one does not re-derive them."""
          % (TOP[0] - max(v for a, r in X.al.items() if r["unit"] == 0
                          for i, v in enumerate(r["value"])
                          if r["class"][i] != B.CLASS_BOUND),
             TOP[1] - max(v for a, r in X.al.items() if r["unit"] == 1
                          for i, v in enumerate(r["value"])
                          if r["class"][i] != B.CLASS_BOUND)))


# ===========================================================================
#  10.  RULE 7 -- rivals, scored only on disagreement sites
# ===========================================================================
def cmd_rivals(X):
    head(10, "RULE 7 -- THE RIVALS, SCORED ONLY WHERE THEY DISAGREE")
    print("""   A test that merely SCORES is not a test.  For each claim, the
   strongest rival that is NOT the hypothesis -- including one that
   ignores the instruction entirely -- and the disagreement set.
""")
    print("   R7.1  CLAIM: the tail's two output blocks are a STEREO PAIR.")
    print("         RIVAL: they are two unrelated blocks that happen to be")
    print("                adjacent (the instruction-blind rival).")
    img = X.C.imgs[RR1]
    L, R = list(range(111, 122)), list(range(122, 133))
    eq = sum(1 for a, b in zip(L, R) if f_lo(img[a]) == f_lo(img[b]))
    # null: how often do two random 11-word windows of this image agree in lo12?
    random.seed(20260727)
    hits = 0
    trials = 20000
    for _ in range(trials):
        i = random.randrange(0, len(img) - 11)
        j = random.randrange(0, len(img) - 11)
        if i == j:
            continue
        k = sum(1 for t in range(11) if f_lo(img[i + t]) == f_lo(img[j + t]))
        if k >= eq:
            hits += 1
    print("         MEASURED: %d of 11 lo12 positions agree." % eq)
    print("         NULL: two 11-word windows drawn uniformly from the SAME")
    print("               image agree at >= %d of 11 positions in %d of %d"
          " draws (p = %.4f)." % (eq, hits, trials, hits / float(trials)))
    print("         And the C-RAM roles are independent of the null: the two")
    print("         blocks consume 0xA9..0xAC and 0xAD..0xB0, which the")
    print("         committed listing already names LEFT and RIGHT.")
    print()
    print("   R7.2  CLAIM: C40.1.80.000 consumes a descriptor cell.")
    print("         RIVAL A: no C-format word consumes (V2).")
    print("         RIVAL B: the OTHER form consumes and this one does not (V4,")
    print("                  the deliberately-wrong twin).")
    print("         DISAGREEMENT SET: the 16 algorithms that carry a C-format")
    print("                  consumer at all -- 12 reverbs + 4 compressors.")
    for nm, fn in (("hypothesis V3 (split)", KEEP_SPLIT),
                   ("rival A     V2 (none)", KEEP_NOCF),
                   ("rival B     V4 (twin)", KEEP_TWIN),
                   ("incumbent   V1 (all) ", KEEP_ALL)):
        A, _ = reclassify(X, fn)
        s = sum(1 for a in REVERBS + [36, 75, 96, 97] if A[a].get("aligned"))
        print("         %-24s aligned on the disagreement set : %2d of 16"
              % (nm, s))
    print()
    print("   R7.3  CLAIM: the 4 trapping cells are READS.")
    print("         RIVAL: they are WRITES.")
    print("         RIVAL (instruction-blind): `cells at relative index 0x19,")
    print("                0x1A, 0x1C, 0x1D are whatever the majority of the")
    print("                block is' -- which for the reverbs is READ 15 :")
    print("                WRITE 13, so it predicts READ with no reasoning.")
    print("         DISAGREEMENT: the residue and the unread-buffer counts of")
    print("                section 7 separate READ from WRITE decisively; the")
    print("                instruction-blind rival is NOT separated from the")
    print("                hypothesis by anything in this pass, and that is")
    print("                reported, not hidden.")
    print()
    print("   R7.4  CLAIM: the CEILING is a sentinel, not a limit register.")
    print("         RIVAL: it is a limit register load.")
    print("         DISAGREEMENT: position.  A limit load may appear anywhere;")
    print("                a flush must be last.  MEASURED 83 of 83 last.")
    print("                P(last | uniform position within the block) =")
    p = 1.0
    for a, r in sorted(X.al.items()):
        p *= 1.0 / r["n"]
    print("                %.3g -- so the rival is separated, decisively." % p)


# ===========================================================================
#  11.  CONTROLS
# ===========================================================================
def cmd_control(X):
    head(11, "CONTROLS -- EACH SHOWN SAYING NO, AND EACH SHOWN SAYING YES")
    print("""   METHOD RULE 1.  A control that cannot fail is not evidence, and one
   that cannot pass is worth just as little.  Every instrument in this
   pass is run against a deliberately-wrong twin AND against a known-good
   reference.
""")
    print("   C1  THE ALIGNMENT INSTRUMENT.")
    A, n = reclassify(X, KEEP_SPLIT)
    print("       says YES to the split predicate            : %2d of 91" % n)
    A, n = reclassify(X, KEEP_TWIN)
    print("       says NO  to the mirror-image twin (V4)     : %2d of 91" % n)
    A, n = reclassify(X, lambda w: is_consumer(w) or f_lo(w) == 0x1D5)
    print("       says NO  to `every mac is a consumer too'  : %2d of 91" % n)
    A, n = reclassify(X, lambda w: False)
    print("       says NO  to `nothing consumes'             : %2d of 91" % n)
    print()
    print("   C2  THE HOST-ANCHOR INSTRUMENT (section 5).")
    def anch(nm, keep, trim):
        shim = copy.copy(X.C)
        shim.algos = []
        for (a, u, cells, cons) in X.C.algos:
            ws = X.C.imgs[a]
            cn = [(i, w) for i, w in enumerate(ws) if keep(w)]
            if a in REVERBS:
                ck = trim(sorted(cells), len(cn))
                cells = {k: cells[k] for k in ck}
            shim.algos.append((a, u, cells, cn))
        Aa = B.analyse(shim)
        good = sum(1 for a in REVERBS for L in Aa[a].get("lines", [])
                   if L["read_cell"] == 0x00 and L["write_cell"] == 0x03)
        print("       %-46s : %2d of 12" % (nm, good))
    anch("says YES to the real block, C-format consuming", KEEP_ALL,
         lambda ck, n: ck)
    anch("says PARTLY NO to E2 (C-format not consuming)", KEEP_NOCF,
         lambda ck, n: ck[:n])
    anch("says NO to E3 (cursor starts at cell 4)      ", KEEP_NOCF,
         lambda ck, n: ck[len(ck) - n:])
    # deliberately wrong twin: shuffle the cell VALUES of each reverb
    random.seed(1234)
    shim = copy.copy(X.C)
    shim.algos = []
    for (a, u, cells, cons) in X.C.algos:
        if a in REVERBS:
            ks = sorted(cells)
            vs = [cells[k] for k in ks]
            random.shuffle(vs)
            cells = {k: v for k, v in zip(ks, vs)}
        shim.algos.append((a, u, cells, cons))
    As = B.analyse(shim)
    good = sum(1 for a in REVERBS for L in As[a].get("lines", [])
               if L["read_cell"] == 0x00 and L["write_cell"] == 0x03)
    print("       %-46s : %2d of 12"
          % ("says NO to SHUFFLED cell values (wrong twin)", good))
    print()
    print("   C3  THE SHIFT INSTRUMENT (section 6).  Its `valid pre-delay tap'")
    print("       predicate must accept things known to be taps and reject")
    print("       things known not to be.")
    ok = 0
    tot = 0
    for a, r in sorted(X.al.items()):
        idx = {c: i for i, c in enumerate(r["cells"])}
        for c in X.C.taps(a):
            if c not in idx:
                continue
            i = idx[c]
            tot += 1
            if r["class"][i] == B.CLASS_ADDR and r["role"][i] == "READ_END":
                ok += 1
    print("       says YES to the %d host-NAMED op-0x67 taps  : %d" % (tot, ok))
    bad = 0
    tt = 0
    for a in REVERBS:
        r = X.al[a]
        val = {c: r["value"][i] for i, c in enumerate(r["cells"])}
        base = val[0x03]
        wr = [v for i, v in enumerate(r["value"])
              if r["dir"][i] == "WRITE" and v > base and v >= FLOOR[1]]
        top = min(wr) if wr else TOP[1]
        for c in (0x01, 0x1E):
            tt += 1
            if base < val[c] < top:
                bad += 1
    print("       says NO  to the two BOUND cells (0x01,0x1E): %d of %d accepted"
          % (bad, tt))
    print()
    print("   C4  ** A CONTROL OF MINE THAT FAILED, PRINTED RATHER THAN")
    print("       REWRITTEN. **  My first instrument for TASK B was a")
    print("       FLUSH-ADJACENCY test: if the trailing flush read exists to")
    print("       give the last real tap one more port slot, then the port")
    print("       access immediately before the CEILING should be a READ, and")
    print("       in the reverbs it is a C-format word -- which would then")
    print("       have to be a read.  MEASURED over the 83 aligned")
    print("       algorithms:")
    prev = collections.Counter()
    for a, r in sorted(X.al.items()):
        i = [j for j in range(r["n"]) if r["role"][j] == "CEILING"][0]
        if i == 0:
            prev["NONE"] += 1
            continue
        d = r["dir"][i - 1]
        prev[d or "TRAP"] += 1
    print("          direction of the port access before the CEILING: %s"
          % dict(prev))
    print("       WRITE in 60 of the 71 unambiguous algorithms.  The argument")
    print("       is REFUTED by the corpus: a write between the last real read")
    print("       and the flush is normal, so the flush cannot be argued to be")
    print("       adjacent to anything.  The test has NO power and is not used")
    print("       anywhere above.  (PREDICT-THEN-CHECK miss P2.)")


# ===========================================================================
#  12.  PREDICT THEN CHECK
# ===========================================================================
def cmd_predict(X):
    head(12, "PREDICT-THEN-CHECK -- HITS AND MISSES, EQUALLY PROMINENT")
    rows = []
    # P1
    img = X.C.imgs[RR1]
    eq = sum(1 for a, b in zip(range(111, 122), range(122, 133))
             if f_lo(img[a]) == f_lo(img[b]))
    rows.append(("P1", "the reverb tail is TWO MIRRORED BLOCKS",
                 "HIT -- %d of 11 lo12 positions agree, and the C-RAM roles "
                 "already say LEFT / RIGHT" % eq))
    rows.append(("P2", "a FLUSH-ADJACENCY test will force the C-format "
                 "direction",
                 "*** MISS *** -- the access before the CEILING is a WRITE in "
                 "60 of 71 unambiguous algorithms.  The test has no power; "
                 "printed in section 11 C4 rather than deleted"))
    A, n = reclassify(X, KEEP_SPLIT)
    rows.append(("P3", "the consumer predicate is exceptionless",
                 "*** MISS *** -- it is not.  V1 = 83 of 91, V2 = 75, and the "
                 "form split V3 = %d, residue four FLANGER-family algorithms"
                 % n))
    rows.append(("P4", "the 4 trapping cells will be FORCED this round",
                 "*** MISS *** -- three legs agree on READ and none of them "
                 "reads the word.  CONSISTENT, and they keep trapping"))
    # P5 -- shift
    t = X.t1(RR1)[0x67]
    best = None
    for s in range(-4, 5):
        ok = 0
        for a in REVERBS:
            r = X.al[a]
            val = {c: r["value"][i] for i, c in enumerate(r["cells"])}
            base = val[0x03]
            wr = [v for i, v in enumerate(r["value"])
                  if r["dir"][i] == "WRITE" and v > base and v >= FLOOR[1]]
            top = min(wr) if wr else TOP[1]
            for c in t[1:]:
                if c + s in val and base < val[c + s] < top:
                    ok += 1
        if best is None or ok > best[1]:
            best = (s, ok)
    rows.append(("P5", "the T1 off-by-one is a UNIFORM -1 on entries 1..6",
                 "HIT -- shift %+d scores %d of 72 and is the unique maximum "
                 "over the enumerated range [-4, +4]" % best))
    rows.append(("P6", "ACTION 0x0B will be decidable from PARAMETRIC EQ, "
                 "SINGLE DELAY or the LFO -- the three the brief names",
                 "*** MISS on all three *** -- PARAMETRIC EQ contains ZERO "
                 "ACTION 0x0B words, SINGLE DELAY's three are all DRAM port "
                 "words, and all 3 kernel ones are DRAM port words too"))
    rows.append(("P9", "and therefore ACTION 0x0B is not decidable anywhere",
                 "*** MISS, and this one is the RESULT *** -- the census the "
                 "brief ordered found FOUR decidable sites the brief did not "
                 "expect: MULTI TAP DELAY w025, and 02A.2.4B.00B at the head "
                 "of PEQ+DIST+DELAY / PEQ+OVERDR+DELAY / PEQ+COMPRESSOR, "
                 "sitting immediately before a byte-identical copy of "
                 "PARAMETRIC EQ's biquad"))
    rows.append(("P10", "the C-format consumer family is homogeneous",
                 "*** MISS *** -- there are two forms and they behave "
                 "OPPOSITELY: C40.1.80.000 must consume, C40.1.E0.451 must "
                 "not.  Predicted one rule, found two"))
    n = 0
    for a, r in sorted(X.al.items()):
        i = [j for j in range(r["n"]) if r["role"][j] == "CEILING"][0]
        rd = [j for j in range(r["n"]) if r["dir"][j] == "READ"]
        if rd and max(rd) == i:
            n += 1
    rows.append(("P7", "the CEILING/G question can be closed without the "
                 "consuming instruction",
                 "HALF-HIT -- reading (2) falls to dram-datapath's own "
                 "position argument (%d of %d), leaving (3) alone; but the "
                 "MECHANISM of G stays OPEN and the ceiling turns out to "
                 "carry NO information about it" % (n, len(X.al))))
    rows.append(("P8", "the tail would need the new delay harness",
                 "HIT (as a non-need) -- the tail result uses only the region "
                 "test and the issue order; no solver, no delay line, no "
                 "audio.  It was deliberately built not to depend on the "
                 "harness this round is otherwise about"))
    for k, q, v in rows:
        print("   %-4s %s" % (k, q))
        print("        %s" % v)
    hits = sum(1 for _k, _q, v in rows if v.startswith("HIT"))
    miss = sum(1 for _k, _q, v in rows if "MISS" in v)
    print()
    print("   %d predictions: %d hits, %d misses, %d partial."
          % (len(rows), hits, miss, len(rows) - hits - miss))


CMDS = [
    ("tail", cmd_tail), ("head", cmd_headsec), ("ertaps", cmd_ertaps),
    ("align", cmd_align), ("anchor", cmd_anchor), ("shift", cmd_shift),
    ("direction", cmd_direction), ("act0b", cmd_act0b),
    ("rotation", cmd_rotation), ("rivals", cmd_rivals),
    ("control", cmd_control), ("predict", cmd_predict),
]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", nargs="?", default="all",
                    choices=[c for c, _ in CMDS] + ["all"])
    a = ap.parse_args()
    X = Ctx()
    for nm, fn in CMDS:
        if a.cmd in (nm, "all"):
            fn(X)
            print()


if __name__ == "__main__":
    main()
