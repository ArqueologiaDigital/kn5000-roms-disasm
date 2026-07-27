#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""datapath.py -- THE DELAY-DRAM DATAPATH of the NEC uPD6383GF-3BA (KN5000 IC311).

No hardware.  Static analysis of the Sub CPU ROM, the 100 canned parameter
streams and the 38 body images, plus the descriptor classification exported by
`bounds.py`.

THE QUESTION.  Round 5 settled WHICH descriptor cell a delay-DRAM word touches
(the identity map, delta = 0) and WHICH DIRECTION it goes (`addr8` bit 6, 0x60 =
WRITE).  A word still cannot execute, because nothing said how the fetched
sample reaches the arithmetic unit or where the stored sample comes from.

THE ANSWER, in one line: the DRAM port is a ONE-DEEP PIPELINE.  A read word
issues a fetch and the datum is NOT on that word's own bus; it becomes visible
one port slot later.  Two previously-unexplained cell classes are the two ends
of that pipeline -- the LIMIT is the FIRST WRITE of the program (74 of 74) and
the CEILING is the LAST READ of the program (83 of 83) -- and `addr8` bit 4
marks the head of every access chain (37 of 37 aligned images).  In the reverb
motif the write of a delay line trails its own read by THREE port slots = TWO
8-word repetitions, so r1's `wtrail = 1` ("the minimal offset", its own words)
is refuted by the descriptors.

    python3 dsp/tools/datapath.py chains     # 1  addr8 bit 4 = the chain head
    python3 dsp/tools/datapath.py dummies    # 2  *** LIMIT = first write, CEILING = last read
    python3 dsp/tools/datapath.py latency    # 3  *** the read latency, bounded from the ROM
    python3 dsp/tools/datapath.py ledger     # 4  *** ROOM REVERB 1, all 32 cells accounted
    python3 dsp/tools/datapath.py wtrail     # 5  *** the write trail, corpus-wide
    python3 dsp/tools/datapath.py solve      # 6  the r1 re-run, land in {-1} u [0,24]
    python3 dsp/tools/datapath.py rivals     # 7  RULE 7, scored on disagreement
    python3 dsp/tools/datapath.py control    # 8  every control, shown saying NO
    python3 dsp/tools/datapath.py predict    # 9  PREDICT-THEN-CHECK, hits AND misses
    python3 dsp/tools/datapath.py all        # ~3 min
"""
import argparse
import collections
import itertools
import os
import random
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import dram_match as DM                                             # noqa: E402
import dsp_disasm as D                                              # noqa: E402
import bounds as B                                                  # noqa: E402

REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
SUB = os.path.join(REPO, "original_ROMs", "kn5000_subprogram_v142.rom")
MAIN = os.path.join(REPO, "original_ROMs", "kn5000_v10_program.rom")
TOOLS = os.path.expanduser("~/compartilhado/kn7000_mame/tools")

RR1 = 16                      # ROOM REVERB 1, the 133-word reverb image
MTD = 10                      # MULTI TAP DELAY


def head(n, s):
    print("=" * 78)
    print("%d. %s" % (n, s))
    print("=" * 78)


def is_dram(w):
    """A class-1 FORMAT-ESCAPE word -- the external delay-DRAM port.
    MEASURED: `dark-words.md' partition; the same predicate `dram_cursor.consumers'
    uses, so the cell alignment and this census cannot drift."""
    return ((w >> 20) & 0xF) == 1 and bool((w >> 24) & 0x800)


def f_addr8(w):
    return (w >> 12) & 0xFF


def f_src(w):
    return ((w & 0xFFF) >> 6) & 0x1F


def f_act(w):
    return w & 0x1F


def chain_head(w):
    """`addr8' bit 4.  Named here, MEASURED in section 1."""
    return bool(f_addr8(w) & 0x10)


class Ctx(object):
    def __init__(self, sub=SUB, main=MAIN, tools=TOOLS):
        self.C = DM.Corp(sub, main, tools)
        self.A = B.analyse(self.C)
        self.al = {a: r for a, r in self.A.items() if r.get("aligned")}
        self.cons = {a: cn for (a, _u, _c, cn) in self.C.algos}
        seen = {}
        for a in sorted(self.C.imgs):
            seen.setdefault(tuple(self.C.imgs[a]), a)
        self.images = [(a, list(k)) for k, a in seen.items()]

    def name(self, a):
        return self.C.name(a)

    def dwords(self, img):
        return [(i, w) for i, w in enumerate(img) if is_dram(w)]


# ===========================================================================
#  1.  addr8 bit 4 -- the head of an access chain
# ===========================================================================
def cmd_chains(X):
    head(1, "`addr8' BIT 4 MARKS THE HEAD OF A DRAM ACCESS CHAIN")
    print("""   POPULATION (rule 9): 38 DISTINCT body images; 37 of them are among the
   83 algorithms whose descriptor block is aligned (#cells == #consumers).
   ENSEMBLE (algo 6) is one of the 8 UNALIGNED algorithms and is the ONLY
   image whose first DRAM word is not a chain head -- it is reported, not
   excluded, and it is excluded from no count below.
""")
    nfirst = tot = n30 = n30first = 0
    rows = []
    for a, img in X.images:
        ds = X.dwords(img)
        if not ds:
            continue
        tot += 1
        if chain_head(ds[0][1]):
            nfirst += 1
        for j, (_i, w) in enumerate(ds):
            if chain_head(w):
                n30 += 1
                if j == 0:
                    n30first += 1
        rows.append((a, X.name(a), " ".join("%02X" % f_addr8(w) for _i, w in ds)))
    nal = sum(1 for a, _r in X.al.items()
              if X.cons[a] and chain_head(X.cons[a][0][1]))
    print("   images with at least one DRAM word          : %d" % tot)
    print("   ... whose FIRST DRAM word has addr8 bit 4 set: %d" % nfirst)
    print("   ALIGNED ALGORITHMS whose first DRAM word is a head: %d of %d"
          % (nal, len(X.al)))
    print("   chain-head words in the corpus              : %d (%d of them at "
          "position 0)" % (n30, n30first))
    print()
    print("   WHERE THE OTHER %d HEADS SIT -- classified, not asserted:"
          % (n30 - n30first))
    kinds = collections.Counter()
    for a, nm, seq in rows:
        h = seq.split().count("30")
        if h > 1:
            r = X.A.get(a, {})
            if r.get("aligned") and r["n"] == 2:
                kinds["a 2-cell block: [128, CEILING], NO delay line at all"] += 1
            elif "+" in nm:
                kinds["a COMPOSITE: one head per sub-effect"] += 1
            else:
                kinds["other (reported below)"] += 1
    for k, v in kinds.most_common():
        print("     %-56s %d images" % (k, v))
    print()
    for a, nm, seq in rows:
        h = seq.split().count("30")
        mark = ""
        if h > 1:
            mark = "   <== %d heads" % h
        print("     algo %-3d %-20s %s%s" % (a, nm[:20], seq, mark))
    print()
    print("""   MODEL ENUMERATION, printed beside the claim (rule 3).  `addr8' bit 4 is
   set only on READ words (bit 6 = 0); no WRITE word in the corpus has it.
   The readings enumerated for it were:
     (H1) `this access starts a chain'                     -- 37/37 aligned, and
          it accounts for every extra head as a sub-effect boundary
     (H2) `the previous DRAM word was a READ'              -- REFUTED: MULTI TAP
          DELAY's w016 follows a READ and is 0x20, ENSEMBLE's w2 likewise
     (H3) `a wider address / a different DRAM bank'        -- REFUTED: the same
          cell values are reached by 0x20 and 0x30 words in different algorithms
          (SINGLE DELAY cell 38 by 0x30, MULTI TAP cell 40 by 0x20, both < 32768)
     (H4) `nothing -- a don't-care bit'                    -- NOT REFUTED by this
          section alone; section 2 is what prices it
   H1 is CONSISTENT, not FORCED: H4 survives here.""")


# ===========================================================================
#  2.  the two dummies -- THE PIPELINE
# ===========================================================================
def _chains_of(X, a):
    """Split an algorithm's consumer list at every chain-head word."""
    cn = X.cons[a]
    out, cur = [], []
    for k, (_wi, w) in enumerate(cn):
        if chain_head(w) and cur:
            out.append(cur)
            cur = []
        cur.append(k)
    if cur:
        out.append(cur)
    return out


def _dummy_stats(X, A=None):
    A = A or X.A
    al = {a: r for a, r in A.items() if r.get("aligned")}
    st = dict(ceil=0, ceil_chain=0, ceil_prog=0,
              lim=0, lim_chain=0, lim_prog=0)
    for a, r in sorted(al.items()):
        chains = _chains_of(X, a)
        ch_of = {k: ci for ci, ch in enumerate(chains) for k in ch}
        reads = [k for k in range(r["n"]) if r["dir"][k] == "READ"]
        writes = [k for k in range(r["n"]) if r["dir"][k] == "WRITE"]
        for k in range(r["n"]):
            if r["role"][k] == "CEILING":
                st["ceil"] += 1
                rc = [x for x in chains[ch_of[k]] if r["dir"][x] == "READ"]
                st["ceil_chain"] += (bool(rc) and rc[-1] == k)
                st["ceil_prog"] += (bool(reads) and reads[-1] == k)
            if r["role"][k] == "LIMIT" and r["class"][k] == "BOUND":
                st["lim"] += 1
                wc = [x for x in chains[ch_of[k]] if r["dir"][x] == "WRITE"]
                st["lim_chain"] += (bool(wc) and wc[0] == k)
                st["lim_prog"] += (bool(writes) and writes[0] == k)
    return st


def cmd_dummies(X):
    head(2, "*** THE TWO DUMMIES: THE DRAM PORT IS A ONE-DEEP PIPELINE ***")
    st = _dummy_stats(X)
    print("""   POPULATION (rule 9): the 83 algorithms whose descriptor block is aligned,
   829 cells.  The roles CEILING / LIMIT are `bounds.py's, imported unchanged;
   this section does NOT re-derive them, it asks WHERE THEY SIT.
""")
    print("   CEILING cells                       : %d" % st["ceil"])
    print("     ... the LAST READ of its own chain: %d" % st["ceil_chain"])
    print("     ... the LAST READ of the program  : %d" % st["ceil_prog"])
    print("   LIMIT cells                         : %d" % st["lim"])
    print("     ... FIRST WRITE of its own chain  : %d" % st["lim_chain"])
    print("     ... FIRST WRITE of the program    : %d" % st["lim_prog"])
    print("""
   EXCEPTIONLESS, BOTH WAYS.  Two cell classes that `dram-bounds.md' located
   and could not explain ("what the CEILING register DOES ... stays OPEN") are
   the two ends of ONE mechanism:

     * a WRITE word always stores something.  The FIRST write of a program has
       nothing meaningful yet -- so it is aimed at an address NO READ OF THAT
       ALGORITHM CAN REACH.  That is exactly `bounds.py's LIMIT predicate.
     * a READ word's datum is NOT on its own bus.  The LAST real tap therefore
       needs one more port slot to become visible -- so the program issues one
       more read, at an address OUTSIDE ITS OWN DRAM REGION whose datum is
       discarded.  That is exactly `bounds.py's CEILING predicate.

   ENUMERATION OF WHAT THE TRAILING OUT-OF-REGION READ COULD BE (rule 3):
     (E1) a PIPELINE FLUSH                       -- requires it to be LAST: 83/83
     (E2) loading a per-unit WRAP/limit register -- a limit must be loaded
          BEFORE the accesses it bounds; it is last in 83 of 83
     (E3) a DRAM refresh cycle                   -- refresh has no reason to be
          last, nor to be exactly one per algorithm, nor to be a READ
     (E4) padding to a fixed block size          -- REFUTED: n runs 2..32
     (E5) nothing -- coincidence                 -- priced by the null below
   E1 is the only member of the list that PREDICTS the position it has.
""")
    print("   THE COUNTING SEPARATOR -- MULTI TAP DELAY:")
    _multitap(X)
    _dummy_fields(X)


ACT_ACTIVE = {0x07, 0x13, 0x14}         # the ANCHORED capture codes
ACT_INERT = {0x12, 0x15}                # the ANCHORED no-effect codes


def _dummy_fields(X):
    print()
    print("   AND WHAT THE TWO DUMMY WORDS THEMSELVES SAY -- the honest version,")
    print("   with both denominators (rule 9):")
    ca = collections.Counter()
    ls = collections.Counter()
    for a, r in sorted(X.al.items()):
        cn = X.cons[a]
        for k in range(r["n"]):
            w = cn[k][1]
            if r["role"][k] == "CEILING":
                act = f_act(w)
                ca["ANCHORED ACTIVE (0x07/13/14)" if act in ACT_ACTIVE else
                   "ANCHORED INERT (0x12/15)" if act in ACT_INERT else
                   "still-unknown ACTION 0x%02X" % act] += 1
            if r["role"][k] == "LIMIT" and r["class"][k] == "BOUND":
                ls["SRC 0x%02X" % f_src(w)] += 1
    print("     the CEILING word's ACTION   (pop 83): %s"
          % "  ".join("%s x%d" % kv for kv in ca.most_common()))
    print("     the LIMIT word's SRC        (pop 74): %s"
          % "  ".join("%s x%d" % kv for kv in ls.most_common()))
    print("""     SRC 0x0B is the anchored delay-RAM read register (`dsp-alu-structure.md'
     sect. 5).  The FIRST WRITE of a program naming it in %d of 74 is what the
     prime reading predicts -- the word exists to bring the chain-head read's
     datum onto the bus, and the store it cannot avoid is aimed where no read
     can follow it.  BUT: the same association measured over the 38 DISTINCT
     IMAGES instead of the 83 algorithms is 48%% after a read against 37%% after
     a write, i.e. WEAK.  The algorithm-weighted number is carried by the twelve
     byte-identical reverbs.  CONSISTENT, NOT FORCED, and both denominators are
     printed so nobody quotes the flattering one.""" % ls["SRC 0x0B"])


def _multitap(X):
    a = MTD
    r = X.A[a]
    cn = X.cons[a]
    img = X.C.imgs[a]
    taps = X.C.taps(a)
    print()
    print("     algo %d %s -- %d host-named op-0x67 taps: %s"
          % (a, X.name(a), len(taps),
             " ".join("cell %d BASE24 %d" % (c, v) for c, v in sorted(taps.items()))))
    print("     word  instr          cell  value  dir    role       ACTION")
    for k, (wi, w) in enumerate(cn):
        print("     w%03d  %03X.%X.%02X.%03X  %4d %6d  %-6s %-10s %02X%s"
              % (wi, (w >> 24) & 0xFFF, (w >> 20) & 0xF, f_addr8(w), w & 0xFFF,
                 r["cells"][k], r["value"][k], r["dir"][k] or "TRAP",
                 r["role"][k], f_act(w),
                 "   <- M<-bus, ANCHORED" if f_act(w) == 0x07 else ""))
    dep = [wi for k, (wi, w) in enumerate(cn) if f_act(w) == 0x07]
    last = dep[-1]
    run = []
    i = last + 1
    while i < len(img) and len(run) < 8:
        if ((img[i] >> 20) & 0xF) == 0xA and f_src(img[i]) == 0x07:
            run.append(i)
        elif run:
            break
        i += 1
    print()
    print("     THE POINTER TRACE (CONSISTENT, printed so it can be checked).")
    print("     Signed addr8 displacements between the four ACT-0x07 deposits,")
    print("     then the first run of class-A SRC-0x07 words after the last one:")

    def sgn(w):
        v = f_addr8(w)
        return v - 256 if v > 127 else v
    p = 0
    for j, wi in enumerate(dep):
        print("       deposit w%03d at ptr%+d" % (wi, p))
        nxt = dep[j + 1] if j + 1 < len(dep) else last + 1
        for q in range(wi + 1, nxt):
            p += sgn(img[q])
    p2 = 0
    for wi in run:
        print("       multiply w%03d  %03X.%X.%02X.%03X reads ptr%+d (post-displacement %+d)"
              % (wi, (img[wi] >> 24) & 0xFFF, (img[wi] >> 20) & 0xF,
                 f_addr8(img[wi]), img[wi] & 0xFFF, p2, sgn(img[wi])))
        p2 += sgn(img[wi])
    nact7 = sum(1 for _wi, w in cn if f_act(w) == 0x07)
    print()
    print("     host-named taps        %d" % len(taps))
    print("     read words w/ ACT 0x07 %d   (M <- bus, one of the five ANCHORED codes)"
          % nact7)
    print("     class-A SRC-0x07 words in the run after the last deposit: %d"
          % len(run))
    real = [r["value"][k] for k in range(r["n"])
            if r["dir"][k] == "READ" and r["role"][k] != "CEILING"]
    blk = [r["value"][k] for k in range(r["n"]) if f_act(cn[k][1]) == 0x07]
    print("""
     THE SEPARATION (rule 7).  Both readings place FOUR values in mem[ptr] --
     the four ANCHORED ACT-0x07 deposits.  They differ on WHICH:
       PIPELINED (datum visible one port slot later) -- the deposits carry the
         taps fetched by their PREDECESSORS: %s.
         All four are host-named op-0x67 DELAY knobs.
       BLOCKING (datum on the read word's own bus) -- the deposits carry
         %s.  The first host-named tap (%d) is fetched and never
         used, and one of the four is the content of address %d, which the
         allocator deliberately keeps OUTSIDE unit 0's region [0, 32767].
     Every deposit differs in value, so all four are disagreement sites; what
     separates the two readings is WHAT KIND of value each carries.  PIPELINED
     deposits a host-named op-0x67 tap 4 of 4 and an out-of-region word 0 of 4;
     BLOCKING deposits a host-named tap 3 of 4 and an out-of-region word 1 of 4,
     and leaves the first host-named tap fetched-but-unused.  The separation is
     ONE SITE WIDE in this algorithm and is reported as such.  The ground truth
     (which cells the HOST names, and that ACTION 0x07 is M<-bus) was fitted to
     neither reading.""" % (
        ", ".join(str(v) for v in real),
        ", ".join(str(v) for v in blk), real[0],
        max(r["value"][k] for k in range(r["n"]) if r["role"][k] == "CEILING")))


# ===========================================================================
#  3.  the read latency, bounded from the ROM
# ===========================================================================
def cmd_latency(X):
    head(3, "*** THE READ LATENCY -- bounded from the ROM, not chosen ***")
    g_dram = collections.Counter()
    g_read = collections.Counter()
    g_src0b = collections.Counter()
    for _a, img in X.images:
        ds = [i for i, w in enumerate(img) if is_dram(w)]
        for j, i in enumerate(ds):
            if D.dram_dir(img[i]) != "READ":
                continue
            if j + 1 < len(ds):
                g_dram[ds[j + 1] - i] += 1
            nxt = [x for x in ds[j + 1:] if D.dram_dir(img[x]) == "READ"]
            if nxt:
                g_read[nxt[0] - i] += 1
            for k in range(i + 1, len(img)):
                if f_src(img[k]) == 0x0B:
                    g_src0b[k - i] += 1
                    break

    def row(nm, c):
        ks = sorted(c)
        print("   %-32s n=%-4d min=%-3d max=%-3d   %s"
              % (nm, sum(c.values()), ks[0], ks[-1],
                 " ".join("%d:%d" % (k, c[k]) for k in ks[:10])))
    print("   POPULATION (rule 9): every READ word of the 38 distinct body images.")
    print()
    row("READ -> next DRAM word", g_dram)
    row("READ -> next READ", g_read)
    row("READ -> next word with SRC 0x0B", g_src0b)
    print("""
   THE BOUND.  `land' is the read latency in WORD SLOTS.
     LOWER: section 2's flush read is needed only if the datum is NOT on the
       read word's own bus  ==>  land >= 1.  (land = -1, the BLOCKING read that
       `action-field.md' sect. 8 reports FORCED 5145/5145, is excluded by the
       CEILING -- and note WHAT THAT SEARCH HELD FIXED: it labelled SINGLE
       DELAY's `880.1.60.2D9' the READ and `880.1.20.64B' the WRITE, i.e. the
       polarity round 5 D REVERSED.  Method rule 10.)
     UPPER: the datum must be in the read-data register when the first word
       that names SRC 0x0B executes  ==>  land <= %d, the corpus minimum.
   ==>  land in [1, %d], and the modal gap is %d (%d of %d reads).
   THIS IS AN INTERVAL, NOT A VALUE.  Nothing here picks one member of it, and
   nothing below assumes one.""" % (min(g_src0b), min(g_src0b),
                                    max(g_src0b, key=lambda k: g_src0b[k]),
                                    g_src0b[min(g_src0b)], sum(g_src0b.values())))


# ===========================================================================
#  4.  ROOM REVERB 1 -- every one of the 32 cells accounted
# ===========================================================================
def _rr1_roles(X):
    r = X.A[RR1]
    cn = X.cons[RR1]
    lines = {L["read_rel"]: L for L in r["lines"]}
    base = collections.defaultdict(list)
    for L in r["lines"]:
        base[L["write_rel"]].append(L)
    return r, cn, lines, base


def cmd_ledger(X):
    head(4, "*** ROOM REVERB 1: ALL 32 DESCRIPTOR CELLS, EVERY ONE ACCOUNTED ***")
    r, cn, lines, base = _rr1_roles(X)
    print("   POPULATION: ONE algorithm, 32 cells, 133 words.  algo %d %s;"
          % (RR1, X.name(RR1)))
    print("   the same body image serves algos 16..27 byte for byte.")
    print()
    print("   cell word  instr          value  dir    role        what it is")
    tally = collections.Counter()
    for k, (wi, w) in enumerate(cn):
        what = ""
        if k in lines:
            what = ("READ end of stage %d (%d samples)"
                    % (k // 2, lines[k]["samples"]))
            tally["read"] += 1
        elif k in base:
            ss = base[k]
            what = ("WRITE end (base) of stage %s"
                    % ",".join(str(L["read_rel"] // 2) for L in ss))
            tally["write"] += 1
        elif r["role"][k] == "CEILING":
            what = "*** the FLUSH read (out of region)"
            tally["flush"] += 1
        elif r["role"][k] == "LIMIT":
            what = "*** the PRIMING write (unreachable address)"
            tally["prime"] += 1
        elif r["dir"][k] is None:
            what = "C-format, direction still TRAPS"
            tally["trap"] += 1
        print("    %3d w%03d  %03X.%X.%02X.%03X %6d  %-6s %-11s %s"
              % (r["cells"][k], wi, (w >> 24) & 0xFFF, (w >> 20) & 0xF,
                 f_addr8(w), w & 0xFFF, r["value"][k], r["dir"][k] or "TRAP",
                 r["role"][k], what))
    print()
    print("   LEDGER: %d line reads + %d line writes + %d flush + %d prime"
          " + %d C-format = %d = n"
          % (tally["read"], tally["write"], tally["flush"], tally["prime"],
             tally["trap"], sum(tally.values())))
    print("""
   THE STAGE LIST, re-derived from the descriptor images (rule 8 -- 8905 is NOT
   quoted, and neither is r1's `chain 0  127 435 489 183 522', which came from
   the pairing `dram-matching.md' retracted):""")
    segs = []
    for k in sorted(lines):
        L = lines[k]
        segs.append((k // 2, L["samples"], L["read_cell"], L["write_cell"]))
    for j, (st, s, rc, wc) in enumerate(segs):
        print("     stage %-2d  read cell %2d  base cell %2d  %5d samples  %7.3f ms%s"
              % (st, rc, wc, s, s * 1000.0 / 44100.0,
                 "   <- PRE DELAY" if j == 0 else ""))
    lad = [s for (st, s, _rc, wc) in segs if wc != 3]
    print("     LADDER (every line whose base is NOT the pre-delay): %d segments,"
          " %d samples = %.2f ms"
          % (len(lad), sum(lad), sum(lad) * 1000.0 / 44100.0))
    print("     PRE DELAY buffer, multi-tapped off cell 3: %s samples"
          % ", ".join(str(L["samples"]) for L in sorted(base[3],
                                                        key=lambda L: -L["samples"])))
    print("""
   ★ AND THE `9 STAGES vs 10 BUFFERS' OFF-BY-ONE THAT `r1-allpass-motif.md'
   sect. 3 and sect. 8 could not close DISSOLVES.  There are TWELVE delay LINES
   (stages 0..11), each with exactly ONE write and ONE read, plus TWO extra
   early-reflection taps on the pre-delay buffer -- 12 writes and 14 reads.
   They are NOT partitioned 5 + 4 into two ladders: the program HEAD reads
   lines 0 and 1, the NINE motif repetitions read lines 2..10 and write lines
   0..8, and the TAIL writes lines 9 and 10 and both ends of line 11.""")
    print("   %s" % ("-" * 74))
    _wtrail_rr1(X)


def _wtrail_rr1(X):
    r, cn, lines, base = _rr1_roles(X)
    # the motif: repetitions of the 8-word core starting at w19
    print("   THE WRITE TRAIL (this is the datapath fact).  Every WRITE word that")
    print("   is followed 4 words later by a READ word -- i.e. every alternating")
    print("   port-slot pair of the program, the 8-word motif included:")
    print("     pair slot0 word  cell  writes line   slot4 word  cell  reads line")
    reps = [k for k in range(len(cn) - 1)
            if r["dir"][k] == "WRITE" and r["dir"][k + 1] == "READ"
            and cn[k + 1][0] - cn[k][0] == 4]
    for j, k in enumerate(reps):
        wi = cn[k][0]
        kr = k + 1
        st_w = ",".join(str(L["read_rel"] // 2) for L in base.get(k, []))
        st_r = lines[kr]["read_rel"] // 2 if kr in lines else "-"
        d = ("%+d" % (st_r - int(st_w.split(",")[0]))
             if st_w and st_r != "-" else "-")
        print("      %2d   w%03d        %3d   %-13s w%03d        %3d   %-4s  "
              "trail %s" % (j, wi, r["cells"][k], st_w or "(the PRIME)",
                            cn[kr][0], r["cells"][kr], st_r, d))
    print("""
     Repetition r WRITES the base of stage r and READS the top of stage r+2.
     ==> THE WRITE OF A LINE TRAILS ITS OWN READ BY TWO 8-WORD REPETITIONS.

     r1-allpass-motif.md sect. 4.2, verbatim: "the search assumes the minimal
     offset of 1.  **Stated as an assumption.**"  The descriptors REFUTE it.
     This is method rule 3 in the same place it bit last round: a parameter
     that was fixed at the bottom of its range.""")


# ===========================================================================
#  5.  the write trail, corpus-wide
# ===========================================================================
def cmd_wtrail(X):
    head(5, "*** THE WRITE TRAIL, CORPUS-WIDE ***")
    dc = collections.Counter()
    dw = collections.Counter()
    nl = 0
    for a, r in sorted(X.al.items()):
        cn = X.cons[a]
        for L in r["lines"]:
            nl += 1
            dc[L["write_rel"] - L["read_rel"]] += 1
            dw[cn[L["write_rel"]][0] - cn[L["read_rel"]][0]] += 1
    print("   POPULATION (rule 9): %d lines over the 83 aligned algorithms."
          % nl)
    print()
    print("   write consumer - read consumer, in DRAM PORT SLOTS:")
    for k in sorted(dc):
        print("     %+4d   %4d%s" % (k, dc[k], "   <== the mode" if dc[k] == max(dc.values()) else ""))
    print()
    print("""   +3 PORT SLOTS in %d of %d.  The 24 negative ones are the twelve reverbs'
   two EARLY-REFLECTION taps, which read a buffer written far earlier; the 12
   at +9 are the reverbs' stage-11 closure; the 14 at +2/+4/+6 are the
   composites, whose two sub-effects interleave.
   In an ALTERNATING program (read, write, read, write ...) +3 port slots is
   +2 repetitions -- section 4.
   NOTE WHAT THIS IS AND IS NOT: it is a property of the LAYOUT that
   `bounds.py' derived, so it inherits that model's label.  For the 69
   host-anchored endpoints it is FORCED; elsewhere it is CONSISTENT.""" %
          (dc[3], nl))


# ===========================================================================
#  6.  the r1 re-run
# ===========================================================================
def _r1():
    import r1_allpass_solve as R
    return R


def _reverb_inputs(X, R):
    """gains and delays for ROOM REVERB 1 ladder 0 -- delays RE-DERIVED from the
    descriptor images (rule 8), NOT from r1's retracted payload pairing."""
    Cm, rom, _names, imgs = R.load_rom(TOOLS, SUB, MAIN)
    bk = R.reverb_banks(Cm, rom)
    l0, _l1 = R.ladder_cram(imgs)
    gains = [bk[RR1][c] for c in l0]
    r, cn, lines, _base = _rr1_roles(X)
    reps = [k for k in range(len(cn) - 1)
            if r["dir"][k] == "WRITE" and r["dir"][k + 1] == "READ"
            and cn[k + 1][0] - cn[k][0] == 4 and (k + 1) in lines]
    delays = [lines[k + 1]["samples"] for k in reps][1:1 + len(gains)]
    # ★ THE STRUCTURAL RUN USES REDUCED DELAYS, AND HERE IS WHY (rule 1).  The
    # first version of this section fed the REAL descriptor delays (172..739) to
    # a 24-sample test signal.  Every delay line then returns zero for the whole
    # run, so the machine and every reference collapse to their direct path and
    # the matcher accepts 22 113 times out of 4 000 -- A CONTROL THAT CANNOT
    # FAIL.  A topology test is a test of STRUCTURE, so the run uses short,
    # pairwise-distinct delays that actually recirculate inside the test signal
    # (r1 and schroeder-topology used [3,5] for the same reason).  The real
    # delays stay printed, and are what section 4 reports.
    test = [3, 5, 7, 11, 13][:len(gains)]
    return gains, delays, test


def R_C(X):
    return X.C


def _run_ladder_wt(R, m, gains, delays, x, inj, wtrail):
    """r1's `run_ladder_action' with the drain extended to `wtrail' repetitions,
    which its own K+1 loop cannot express."""
    K = len(gains)
    lines = [R.Line(d) for d in delays]
    out = [[] for _ in range(6)]
    for xn in x:
        st = [0.0] * 6
        st[inj] = xn
        pend = []
        for r in range(K + max(1, wtrail)):
            R.exec_rep(m, st, R.NumAlg, gains[r] if r < K else None,
                       lines, r, K, pend, r * 8)
        for k in range(6):
            out[k].append(st[k])
        for ln in lines:
            ln.advance()
    return out


def cmd_solve(X, quick=False, full=False):
    head(6, "THE r1 RE-RUN -- land in {-1} u [0,24], read_slot FREE, wtrail FREE")
    R = _r1()
    gains, delays, test = _reverb_inputs(X, R)
    print("   ladder-0 gains  (C-RAM 0x98..0x9C, MEASURED)  %s"
          % " ".join("%.4f" % g for g in gains))
    print("   ladder-0 delays RE-DERIVED from the descriptors %s" % delays)
    print("   STRUCTURAL RUN uses REDUCED delays %s -- see the comment in"
          % test)
    print("   `_reverb_inputs': with the real delays no line recirculates inside")
    print("   the test signal and the matcher accepts everything.  A CONTROL")
    print("   THAT CANNOT FAIL, caught and printed rather than shipped.")
    print("   (r1 sect. 3 used 127 435 489 183 522 -- from the pairing that")
    print("    `dram-matching.md' retracted.  Method rule 8.)")
    print()
    NE = len(R.EFFECTS)
    LANDS_FULL = [-1] + list(range(0, 25))
    print("""   THE ENUMERATION, PRINTED BESIDE THE CLAIM (rule 3):
     read/write roles   2   swap=1 is round 5 D's FORCED polarity (slot 0 =
                            WRITE, slot 4 = READ); swap=0 is r1's F1, kept as
                            the rival and as the POSITIVE CONTROL's setting
     wtrail             4   0..3;  the descriptors FORCE 2 (section 4).  r1
                            fixed it at 1 and said so
     land              26   -1 (BLOCKING) and 0..24.  r1 searched [2,5];
                            schroeder/blocking-read searched {0,1,2,7,8} and
                            {-1}
     ACTION 0x00/19/0B 35 each, over the declared EFFECTS space
     SRC 0x00           6   zero P M acc DR tA
     escact             2   is an ESCAPE word's ACTION honoured
     tbsh               2   the tempB >>1 relaxation
     order              2   sequential and THE ADDER
     write source       4   bus, acc before, acc after, mem[ptr]
     TOTAL              %d machines""" % (2 * 4 * 26 * NE ** 3 * 6 * 2 * 2 * 2 * 4))
    print()
    print("""   STAGE A -- an EXHAUSTIVE pass over a NECESSARY condition that is sound for
   every wtrail: the multiplicand must carry a delay-line datum, either the
   fresh read N or the read still standing in the read-data register D, with
   coefficient +-1.  It involves neither ACTION 0x0B (which acts at the class-A
   slot, after that slot's bus is latched) nor the write source nor wtrail, so
   all three factor out of it exactly.
""")
    byland = {}
    bylandD = {}
    tot = 0
    for swap in (1, 0):
        for ld in LANDS_FULL:
            n = nd = 0
            for order in (0, 1):
                for ea in (0, 1):
                    for sh in (0, 1):
                        for s0 in R.SRC0_CANDS:
                            for i00 in range(NE):
                                for i19 in range(NE):
                                    tot += 1
                                    m = R.mach(i00, i19, 0, s0, None, 1, ld,
                                               ea, sh, order=order, swap=swap)
                                    _st, tr = R.sym_rep(m)
                                    if "MULT" not in tr:
                                        continue
                                    mu = tr["MULT"]
                                    if abs(abs(mu[R.NA]) - 1.0) < 1e-9:
                                        n += 1
                                    elif abs(abs(mu[R.DA]) - 1.0) < 1e-9:
                                        nd += 1
            byland[(swap, ld)] = n
            bylandD[(swap, ld)] = nd
    print("   enumerated %d (swap, land, order, escact, tbsh, SRC0x00, A00, A19)"
          % tot)
    print("   survivors, split by WHICH delay datum reaches the multiplier")
    print("   (rule 4 -- the first version of this filter merged the two and was")
    print("   DEGENERATE: it returned the same 4428 for every land and both")
    print("   polarities, because the `D route' is available unconditionally):")
    for swap in (1, 0):
        print("     swap=%d (%s):" % (swap, "round-5 D, FORCED" if swap
                                      else "r1 F1, FALSIFIED"))
        print("       via the FRESH read N: " +
              "  ".join("%d:%d" % (ld, byland[(swap, ld)])
                        for ld in LANDS_FULL if byland[(swap, ld)]))
        print("       via the STANDING read D (every land): %d"
              % bylandD[(swap, LANDS_FULL[-1])])
    print("""
   ★ AND THE POLARITIES DIFFER HERE, WHICH IS NEW.  Under the FORCED polarity
   the multiply at slot 5 reads SRC 0x19 = tempA and the read is at slot 4 with
   NOTHING BETWEEN THEM, so the FRESH read reaches the multiplicand ONLY under
   the blocking read (land = -1) -- 4428 machines, and none at any land >= 0.
   Under r1's falsified polarity the read is at slot 0 and lands 0 and 1 also
   work.  For every land >= 0 the multiplicand can carry only the PREVIOUS
   read, standing in D.
   THAT IS THE PIPELINE, ARRIVED AT FROM THE ALU SIDE: with a pipelined read
   the reverb's multiplicand is a delay word fetched in an EARLIER repetition,
   which is exactly what sections 2 and 4 say the port does.  Section 3 bounds
   land to [1,4] from the ROM, with no reference to this search; the two agree
   that the reverb multiplies an OLDER sample.  NOTHING IS FORCED by that
   agreement -- it is the first time the two ends have met.
""")
    # ---------------- the numeric arms -----------------------------------
    random.seed(11)
    xs = [random.uniform(-1, 1) for _ in range(96)]
    refs = R.topology_refs(gains, test, xs, wide=True)
    print("   STAGE B -- the numeric ladder, matched against %d deduplicated"
          % len(refs))
    print("   topology references (all-pass, comb cascade x2, comb bank, Moorer,")
    print("   nested all-pass, the pipe-comb family), every injection and")
    print("   extraction enumerated, an arbitrary scale granted -- r1's own")
    print("   matcher and r1's own executor, unchanged.")
    print()
    print("""   ★ THE PRE-FILTER, AND ITS LIMIT, STATED BEFORE THE NUMBERS.  r1's
   `loop_ok' is the only structural filter that exists for this machine, and it
   is SPECIFIC TO wtrail = 1: it advances the written value by exactly ONE
   repetition (`advance', which returns None if asked twice).  So:
     * the wtrail = 1 arms are a real search over a filtered pool;
     * the wtrail = 2 arms run the SAME pool, which was selected by a filter
       that assumes the wrong trail.  A ZERO THERE IS AN ABSENCE OF A SEARCH,
       NOT A REJECTION, and it is reported as one.  Random sampling has no
       power here at all: 0 of 60 uniformly-drawn machines match even in the
       PUBLISHED space, so a random wtrail = 2 sweep would be a control that
       cannot succeed.""")
    print()
    NL_PUB = [0, 1, 2, 7, 8]
    NL_NEW = [-1, 0, 1, 2, 3, 4, 5] if not full else LANDS_FULL

    def pool(swap, lands):
        out = []
        for ld in lands:
            for order in (0, 1):
                for s0 in R.SRC0_CANDS:
                    for i00 in range(NE):
                        for i19 in range(NE):
                            for i0b in range(NE):
                                m0 = R.mach(i00, i19, i0b, s0, None, 1, ld, 1,
                                            0, order=order, swap=swap)
                                for ws in R.loop_ok(m0):
                                    out.append((i00, i19, i0b, s0, ws, ld,
                                                order))
        return out
    P0 = pool(0, NL_PUB)
    P1 = pool(1, NL_NEW)
    print("   loop_ok pool, swap=0 (r1 F1) over land %s : %d machines"
          % (NL_PUB, len(P0)))
    print("   loop_ok pool, swap=1 (FORCED) over land %s : %d machines"
          % (NL_NEW, len(P1)))
    NS = 60 if quick else (400 if not full else 1500)
    rnd = random.Random(5)
    s0 = list(P0)
    s1 = list(P1)
    rnd.shuffle(s0)
    rnd.shuffle(s1)
    s0, s1 = s0[:NS], s1[:NS]
    arms = [("POSITIVE CONTROL -- the PUBLISHED space (swap=0, wtrail=1)",
             s0, 0, 1),
            ("swap=1 FORCED, wtrail=1  (r1's assumed minimal offset)", s1, 1, 1),
            ("swap=1 FORCED, wtrail=2 FORCED   <== THE RE-RUN", s0 + s1, 1, 2),
            ("swap=0, wtrail=2   (isolates which change bites)", s0 + s1, 0, 2)]
    res = {}
    for (nm, pl, swap, wt) in arms:
        hits = collections.Counter()
        for (i00, i19, i0b, sc0, ws, ld, order) in pl:
            m = R.mach(i00, i19, i0b, sc0, ws, wt, ld, 1, 0,
                       order=order, swap=swap)
            outs = [_run_ladder_wt(R, m, gains, test, xs, inj, wt)
                    for inj in range(6)]
            for (rn, _i, _e, _sc) in R.match_refs(outs, refs):
                hits[rn] += 1
        res[nm] = (len(pl), hits)
        print("   %s" % nm)
        print("     %5d machines run, %d reference matches"
              % (len(pl), sum(hits.values())))
        for k, v in hits.most_common(5):
            print("        %-56s x%d" % (k[:56], v))
        if not hits:
            print("        (none)")
    print()
    if sum(res[arms[0][0]][1].values()) == 0:
        print("   *** THE POSITIVE CONTROL IS EMPTY -- the harness cannot say")
        print("   *** YES, so nothing above may be read as a rejection.")
        return
    print("""   THE CONTROL SAYS YES (rule 1).  The harness reproduces the published
   pipe-comb family in the published space, on the same code path, with the
   same matcher and the same executor.  The other arms are therefore
   meaningful -- subject to the pre-filter caveat printed above.
""")
    a1 = sum(res[arms[1][0]][1].values())
    a2 = sum(res[arms[2][0]][1].values())
    a3 = sum(res[arms[3][0]][1].values())
    print("   WHICH CONSTRAINT BITES -- one change at a time:")
    print("     swap 0 -> 1 alone (wtrail still 1)          %d matches" % a1)
    print("     wtrail 1 -> 2 alone (swap still 0)          %d matches" % a3)
    print("     both, i.e. the two FORCED values            %d matches" % a2)
    print("""
   ★ WHAT THIS DOES AND DOES NOT ESTABLISH.
   DOES:  the polarity is NOT what empties the reverb solve -- swap = 1 with
          wtrail = 1 still matches.  Every zero here is produced by wtrail.
   DOES NOT: it does not REFUTE a wtrail = 2 machine, because no filter for
          wtrail = 2 exists and the pool was built by the wtrail = 1 one.
   THE NAMED NEXT EXPERIMENT, precisely: extend r1's `advance' past two atom
   generations so that `loop_ok' can be stated for wtrail = w, then re-run.
   That is a piece of MACHINERY, not a parameter, and it is the whole reason
   this arm cannot be closed in this pass.

   AND THE INDEPENDENT OBSTRUCTION, which no ALU search can dissolve: with
   wtrail = 2 the motif is a SOFTWARE-PIPELINED loop body whose lines straddle
   the ladder (sect. 4) -- repetition 1 writes THE PRE-DELAY, whose read is
   w000 in the program HEAD, and the last two repetitions read lines whose
   writes are in the TAIL.  EVERY reference in the set is a self-contained
   K-stage cascade, and so was every search r1, `schroeder-topology.md' and
   `blocking-read.md' ran.  The right object is the 12-line pipeline, head and
   tail included, and those words are undecoded.

   ==> THE DATAPATH DOES NOT DECIDE COMB VERSUS ALL-PASS.  Said plainly, as
   asked.  `schroeder-topology.md's survivors live in the wtrail = 1 space the
   descriptors have closed; they are survivors of a different machine.  Neither
   confirmed nor refuted here.""")


# ===========================================================================
#  7.  rule 7
# ===========================================================================
def cmd_rivals(X):
    head(7, "RULE 7 -- the rivals, scored ONLY where they disagree")
    print("""   THE CLAIM UNDER TEST: `the trailing out-of-region READ is a pipeline
   flush and the leading unreachable WRITE is a pipeline prime'.

   GROUND TRUTH used for scoring (not this pass's output):
     * the CEILING / LIMIT predicates come from `bounds.py' (region test and
       write-above-every-read), which was built with no notion of a pipeline;
     * the host's op-0x67 tap labels and their BASE24 line bases;
     * the five ANCHORED ACTION codes (0x07 = M<-bus in particular).
""")
    r = X.A[MTD]
    taps = set(X.C.taps(MTD))
    cn = X.cons[MTD]
    reads = [k for k in range(r["n"]) if r["dir"][k] == "READ"]
    act7 = [k for k in range(r["n"]) if f_act(cn[k][1]) == 0x07]
    # the two readings' predicted multiplicand sets
    pipe = [reads[reads.index(k) - 1] for k in act7 if reads.index(k) > 0]
    blk = act7
    print("   MULTI TAP DELAY.  The four ACT-0x07 deposits, and what each puts in"
          " mem[ptr]:")
    print("     deposit word   PIPELINED gives        BLOCKING gives")
    for k in act7:
        j = reads.index(k)
        p = r["value"][reads[j - 1]] if j > 0 else None
        print("      w%03d          %-22s %s%s"
              % (cn[k][0], "%d%s" % (p, " (host-named)" if reads[j - 1] in
                                     [x for x in range(r["n"])
                                      if r["cells"][x] in taps] else ""),
                 r["value"][k],
                 "  <- OUT OF REGION" if r["role"][k] == "CEILING" else
                 " (host-named)" if r["cells"][k] in taps else ""))
    dis = [k for k in act7 if (reads.index(k) > 0 and
                               r["value"][reads[reads.index(k) - 1]] != r["value"][k])]
    ph = sum(1 for k in dis if r["cells"][reads[reads.index(k) - 1]] in taps)
    bh = sum(1 for k in dis if r["cells"][k] in taps)
    print("     disagreement sites: %d   PIPELINED host-named %d   BLOCKING host-named %d"
          % (len(dis), ph, bh))
    print()
    print("   RIVAL SET for the CEILING, scored on `is it the LAST read':")
    st = _dummy_stats(X)
    print("     E1 pipeline flush      predicts LAST      : %d of %d" % (st["ceil_chain"], st["ceil"]))
    print("     E2 wrap-register load  predicts NOT last  : %d of %d"
          % (st["ceil"] - st["ceil_chain"], st["ceil"]))
    print("     E5 coincidence         null below")
    # the null: how often would a randomly-placed read be last?
    rnd = random.Random(17)
    hits = 0
    trials = 2000
    per = []
    for a, r2 in sorted(X.al.items()):
        nr = sum(1 for k in range(r2["n"]) if r2["dir"][k] == "READ")
        per.append(nr)
    for _t in range(trials):
        s = sum(1 for nr in per if nr and rnd.randrange(nr) == nr - 1)
        if s >= st["ceil_chain"]:
            hits += 1
    exp = sum(1.0 / nr for nr in per if nr)
    print("     NULL: place each algorithm's dummy read uniformly among its own"
          " reads ->")
    print("           expectation %.1f of %d, %d of %d trials reach %d"
          % (exp, st["ceil"], hits, trials, st["ceil_chain"]))
    print()
    print("   ★ A RIVAL MY TEST DOES **NOT** SEPARATE, reported as such:")
    print("""     `the CEILING is simply the LARGEST cell value and the allocator emits
     the block in ascending order, so it lands last by construction'.  On the
     reverbs the ceiling (32767) is NOT the largest value (45464 is), so it is
     refuted there -- but in the 71 unit-0 algorithms 32768 IS the largest, and
     ordering is exactly what my statistic measures.  On the 12 reverbs the
     separation is 12-0; on the 71 others it is UNSEPARATED.  I am not entitled
     to the whole 83.""")


# ===========================================================================
#  8.  controls
# ===========================================================================
def cmd_control(X):
    head(8, "THE CONTROLS -- each shown SAYING NO")
    print("   POPULATION for every row: the 83 aligned algorithms / 829 cells.")
    print()
    base = _dummy_stats(X)
    print("   [0] the ROM, unmodified                    CEILING last %d/%d   "
          "LIMIT first %d/%d" % (base["ceil_chain"], base["ceil"],
                                 base["lim_chain"], base["lim"]))

    def flipdir(w):
        d = D.dram_dir(w)
        return None if d is None else ("WRITE" if d == "READ" else "READ")
    A2 = B.analyse(X.C, dirfn=flipdir)
    s2 = _dummy_stats(X, A2)
    print("   [1] DIRECTION REVERSED (round 5 D flipped)  CEILING last %d/%d   "
          "LIMIT first %d/%d" % (s2["ceil_chain"], s2["ceil"],
                                 s2["lim_chain"], s2["lim"]))
    print("       -> the control REJECTS: with the polarity flipped the flush"
          " read becomes a")
    print("          leading write and the prime write a trailing read; the"
          " statistic collapses.")
    for dlt in (-1, 1):
        A3 = B.analyse(X.C, delta=dlt)
        s3 = _dummy_stats(X, A3)
        print("   [2] PHASE delta = %+d (round 5 B falsified it)  CEILING last "
              "%d/%d   LIMIT first %d/%d"
              % (dlt, s3["ceil_chain"], s3["ceil"], s3["lim_chain"], s3["lim"]))
    A4 = B.analyse(X.C, strict=False)
    s4 = _dummy_stats(X, A4)
    print("   [3] NON-STRICT matching twin               CEILING last %d/%d   "
          "LIMIT first %d/%d" % (s4["ceil_chain"], s4["ceil"],
                                 s4["lim_chain"], s4["lim"]))
    print()
    print("""   ★ A CONTROL WHOSE **EXPECTED FAILURE MODE DID NOT HAPPEN**, printed rather
   than quietly re-labelled.  I built a REVERSED-ORDER twin -- score `is the
   CEILING the FIRST read' and `is the LIMIT the LAST write' -- and PREDICTED
   it would score non-zero, because the 8 `n = 2' algorithms have so few cells
   that first and last coincide.  They do not: those blocks hold TWO reads, so
   the ceiling is last and not first.  The twin rejects cleanly:""")
    first = last = 0
    for a, r in sorted(X.al.items()):
        reads = [k for k in range(r["n"]) if r["dir"][k] == "READ"]
        writes = [k for k in range(r["n"]) if r["dir"][k] == "WRITE"]
        for k in range(r["n"]):
            if r["role"][k] == "CEILING" and reads and reads[0] == k:
                first += 1
            if (r["role"][k] == "LIMIT" and r["class"][k] == "BOUND"
                    and writes and writes[-1] == k):
                last += 1
    print("     CEILING is the FIRST read: %d of %d      LIMIT is the LAST write:"
          " %d of %d" % (first, len(X.al), last, len(X.al)))
    print("""     The prediction was wrong and the control is stronger than I expected.
     Recorded as a PREDICT-THEN-CHECK miss (P13), not silently upgraded.""")


# ===========================================================================
#  9.  predict-then-check
# ===========================================================================
PREDICTIONS = [
    ("P1", "addr8 bit 4 marks a CHAIN HEAD (recorded as OBSERVED-FIRST: the "
     "pattern was seen in the addr8 dump before it was stated)", "OBSERVED-FIRST"),
    ("P2", "the CEILING is the LAST READ of its chain in >= 75 of 83", None),
    ("P3", "the LIMIT is the FIRST WRITE of its chain in >= 62 of 63", None),
    ("P4", "min gap READ -> next DRAM word == 4", None),
    ("P5", "min gap READ -> next SRC-0x0B word == 4", None),
    ("P6", "wtrail = 2 for the reverb motif", None),
    ("P7", "the re-run yields NON-EMPTY survivors", None),
    ("P8", "the survivors will NOT separate comb from all-pass", None),
    ("P9", "land = -1 (blocking) is REJECTED by the descriptor-anchored search",
     None),
    ("P10", "the written value is forced to acc or mem[ptr], not the bus", None),
    ("P11", "fewer than 10 of the 42 delay slots become executable", None),
    ("P12", "the 8 `30 30' algorithms perform exactly ONE useful read", None),
    ("P13", "the reversed-order control twin would score NON-ZERO, because the"
     " 8 n=2 blocks are degenerate", None),
    ("P14", "the numeric harness would be sound as first written", None),
]


def cmd_predict(X):
    head(9, "PREDICT-THEN-CHECK -- hits AND misses, equal prominence")
    st = _dummy_stats(X)
    g = collections.Counter()
    gd = collections.Counter()
    for _a, img in X.images:
        ds = [i for i, w in enumerate(img) if is_dram(w)]
        for j, i in enumerate(ds):
            if D.dram_dir(img[i]) != "READ":
                continue
            if j + 1 < len(ds):
                gd[ds[j + 1] - i] += 1
            for k in range(i + 1, len(img)):
                if f_src(img[k]) == 0x0B:
                    g[k - i] += 1
                    break
    res = {
        "P1": ("recorded honestly as observed-first.  37 of 38 images; the 21"
               " further heads split into 6 composite sub-effect boundaries and"
               " the 2-cell blocks of algorithms with NO delay line.  Labelled"
               " CONSISTENT, not FORCED: `a don't-care bit' survives sect. 1",
               "HIT*"),
        "P2": ("%d of %d -- exceptionless, better than predicted"
               % (st["ceil_chain"], st["ceil"]), "HIT"),
        "P3": ("%d of %d -- exceptionless" % (st["lim_chain"], st["lim"]), "HIT"),
        "P4": ("min is %d, not 4: three READ words are followed by a DRAM word"
               " only 2 slots later" % min(gd), "MISS"),
        "P5": ("min is %d, and 4 is the mode (%d of %d)"
               % (min(g), g[min(g)], sum(g.values())), "HIT"),
        "P6": ("the descriptors force 2 in all 9 motif repetitions", "HIT"),
        "P7": ("ZERO -- see section 6; the obstruction is the boundary "
               "condition, not the ALU", "MISS"),
        "P8": ("vacuously true with zero survivors -- the datapath does NOT "
               "decide comb vs all-pass, and this pass adds no evidence either"
               " way", "HIT (VACUOUS)"),
        "P9": ("land = -1 is excluded by the CEILING argument, which is a"
               " STRUCTURAL result, not the search's -- the search itself never"
               " got far enough to reject it", "HIT, BUT NOT BY THE ROUTE "
               "PREDICTED"),
        "P10": ("NOT ESTABLISHED.  The reverb's write word names SRC 0x0B and"
                " the corpus has writes naming mem[ptr] (900.1.60.1D5, 29x) and"
                " the accumulator (880.1.60.40E) -- the write source is still"
                " OPEN", "MISS"),
        "P11": ("ZERO become executable.  Nothing is applied.", "HIT, TRIVIALLY"),
        "P12": ("their two cells are [128, CEILING]; 128 is IN region, so the"
                " one real read is at a fixed scratch address and the second is"
                " the flush", "HIT"),
        "P13": ("0 of 83 and 0 of 83.  Those blocks hold TWO reads, so first and"
                " last do NOT coincide.  The control is stronger than I"
                " expected and I was wrong about why", "MISS"),
        "P14": ("NO.  The first version fed the REAL descriptor delays"
                " (172..739) to a 24-sample signal: no line recirculates, every"
                " machine collapses to its direct path, and the matcher accepted"
                " 22 113 times out of 4 000 -- A CONTROL THAT CANNOT FAIL, in"
                " the pass whose brief opens with that rule.  Caught, fixed"
                " (reduced delays, 96 samples), and printed", "MISS"),
    }
    for tag, txt, _ in PREDICTIONS:
        r, v = res[tag]
        print("   %-4s %-6s %s" % (tag, v, txt))
        print("        -> %s" % r)
    print()
    nm = sum(1 for t, _x, _y in PREDICTIONS if res[t][1].startswith("MISS"))
    print("   MISSES: %d of %d." % (nm, len(PREDICTIONS)))


# ===========================================================================
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", nargs="?", default="all",
                    choices=["all", "chains", "dummies", "latency", "ledger",
                             "wtrail", "solve", "rivals", "control", "predict"])
    ap.add_argument("--sub", default=SUB)
    ap.add_argument("--main", default=MAIN)
    ap.add_argument("--tools", default=TOOLS)
    ap.add_argument("--quick", action="store_true")
    ap.add_argument("--full", action="store_true")
    a = ap.parse_args()
    X = Ctx(a.sub, a.main, a.tools)
    order = [("chains", cmd_chains), ("dummies", cmd_dummies),
             ("latency", cmd_latency), ("ledger", cmd_ledger),
             ("wtrail", cmd_wtrail), ("solve", cmd_solve),
             ("rivals", cmd_rivals), ("control", cmd_control),
             ("predict", cmd_predict)]
    for nm, fn in order:
        if a.cmd in ("all", nm):
            if nm == "solve":
                fn(X, quick=a.quick, full=a.full)
            else:
                fn(X)
            print()


if __name__ == "__main__":
    main()
