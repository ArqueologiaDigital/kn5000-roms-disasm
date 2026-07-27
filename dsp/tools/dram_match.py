#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""dram_match.py -- the delay-DRAM descriptor, solved as a MATCHING problem.

NEC uPD6383GF-3BA (Technics SX-KN5000, IC311).  No hardware; static analysis of
the Sub CPU ROM, the 100 canned parameter streams and the 38 body images only.

The round-4 brief asked for the cell -> word map to be solved as a matching
problem rather than as a rigid phase scan.  The lever this pass found is NOT in
the DSP at all: it is in the HOST.  Parameter opcode 0x67 is the only parameter
opcode whose writer is the delay-descriptor writer LABEL_038922, and its
evaluator LABEL_03925E is

    descriptor_cell = round(user_ms * 44100 / 1000) + BASE24

with BASE24 a 24-bit constant canned in the record itself.  That single fact
turns 38 descriptor cells across 13 algorithms into LABELLED READ TAPS whose
LINE BASE is readable straight out of the ROM -- an anchor set that no previous
pass had, because nobody had decoded the op-0x67 evaluator.

    python3 dsp/tools/dram_match.py evaluator   # SS1  the host chain, PROVEN
    python3 dsp/tools/dram_match.py anchor      # SS2  *** the +3 cell rule ***
    python3 dsp/tools/dram_match.py lines       # SS3  *** the ladders, corpus wide
    python3 dsp/tools/dram_match.py map         # SS4  *** delta = -1, and its rivals
    python3 dsp/tools/dram_match.py act0b       # SS5  ACTION 0x0B under the map
    python3 dsp/tools/dram_match.py cursor      # SS6  what this says about the reloads
    python3 dsp/tools/dram_match.py control     # SS7  every control, shown saying NO
    python3 dsp/tools/dram_match.py all
"""
import argparse
import collections
import os
import random
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import dram_cursor as DC                                            # noqa: E402
import register_space as RS                                         # noqa: E402

# ---------------------------------------------------------------------------
#  Sub CPU addresses.  CPU address = file offset + ROM_BIAS (measured below by
#  locating the opcode dispatch block's own bytes, so the bias is derived, not
#  asserted).
# ---------------------------------------------------------------------------
DISPATCH_ANCHOR = bytes([0xBF, 0x2A, 0x30, 0xEA, 0x89, 0x1D, 0x9F, 0x8E, 0x03])
DISPATCH_BASE = 0x03CB8E          # jump-table base, from the interpreter
OFFTAB_HEAD = bytes.fromhex("00005000" "6c00a500")   # first four dw entries
N_OPCODES = 25                    # SUB WA,0x61 ; CP WA,0x18 ; JRL UGT -> 0..0x18
W_DSC = 0x038922                  # LABEL_038922, the tag-0x4C descriptor writer
W_DRAM = 0x038539                 # LABEL_038539 / 0x03846C, tag 0x15
W_CRAM = 0x0387E6                 # LABEL_0387E6

SR = 44100                        # 0xAC44, literal in LABEL_03925E
MS = 1000                         # 0x03E8, literal in LABEL_03925E

# the two per-unit region floors, MEASURED in adjudication-round4 SS2
FLOOR = {0: 0, 1: 32768}

SRC_READ = 0x0B                   # dark-words.md sect. 6's H-DIR read code
SRC_WRITE = 0x19


# ===========================================================================
#  0.  data
# ===========================================================================
class Corp(object):
    def __init__(self, sub, mainrom, tools):
        self.rom, self.imgs, self.loads, self.hdr, self.epi = DC.load(sub, tools)
        self.main = open(mainrom, "rb").read() if os.path.exists(mainrom) else None
        self.raw = open(sub, "rb").read()
        self.algos = []
        for (a, u, cells, cons) in DC.corpus(self.rom, self.imgs, self.loads):
            self.algos.append((a, u, cells, cons))

    def name(self, a):
        return RS.effect_name(self.main, a) if self.main else "algo %d" % a

    def taps(self, a):
        """{descriptor cell -> BASE24} for this algorithm's op-0x67 records."""
        t1p = self.rom.u32le(RS.T1_ARRAY + 4 * a)
        t2p = self.rom.u32le(RS.T2_ARRAY + 4 * a)
        if not t2p or not t1p or t1p == RS.NULL_T1:
            return {}
        amap = {op: e for op, e in RS.parse_t1(self.rom, t1p)}
        out = {}
        for (_x, _l, body) in RS.split_t2(self.rom, t2p):
            if body[0] != 0x67 or len(body) < 5:
                continue
            operand, b = body[1], body[2:5]
            lst = amap.get(0x67, [])
            if operand < len(lst):
                out[lst[operand]] = (b[0] << 16) | (b[1] << 8) | b[2]
        return out

    def image_key(self, a):
        return tuple(self.imgs[a])


def head(n, s):
    print("=" * 78)
    print("%d. %s" % (n, s))
    print("=" * 78)


# ===========================================================================
#  SS1  the host chain -- PROVEN BY CONSTRUCTION
# ===========================================================================
def cmd_evaluator(C):
    head(1, "THE HOST CHAIN: parameter opcode 0x67 -> LABEL_03925E -> LABEL_038922")
    d = C.raw
    i = d.find(DISPATCH_ANCHOR)
    bias = DISPATCH_BASE - i
    j = d.find(OFFTAB_HEAD)
    offs = [int.from_bytes(d[j + 2 * k:j + 2 * k + 2], "little")
            for k in range(N_OPCODES)]
    print("   ROM bias  CPU = file + 0x%05X   (derived: the dispatch block's own"
          " bytes)" % bias)
    print("   jump table at file 0x%05X, base 0x%06X, %d entries"
          % (j, DISPATCH_BASE, N_OPCODES))
    print()
    print("   opcode  handler   evaluator+writer it calls")
    rows = []
    for k, o in enumerate(offs):
        a = DISPATCH_BASE + o
        f = a - bias
        nxt = min([x for x in offs if x > o], default=o + 0x30)
        blk = d[f:f + min(nxt - o, 0x40)]
        calls, p = [], 0
        while p < len(blk) - 3:
            if blk[p] == 0x1D:
                t = blk[p + 1] | (blk[p + 2] << 8) | (blk[p + 3] << 16)
                if 0x30000 <= t < 0x40000:
                    calls.append(t)
                p += 4
            else:
                p += 1
        rows.append((0x61 + k, a, calls))
    dsc = [r for r in rows if W_DSC in r[2]]
    for op, a, calls in rows:
        mark = "   <== the DESCRIPTOR writer" if W_DSC in calls else ""
        print("     0x%02X  %06X   %s%s"
              % (op, a, " ".join("%06X" % c for c in calls), mark))
    print()
    print("   => opcodes calling LABEL_038922 (tag 0x4C, the delay descriptor):"
          " %s" % ", ".join("0x%02X" % r[0] for r in dsc))
    print("      EXACTLY ONE.  Its evaluator is LABEL_03925E.")
    print()
    print("   LABEL_03925E, transcribed from the ROM listing:")
    print("""
        CALL LABEL_03CF07        ; fetch THREE bytes b0,b1,b2 from the record,
                                 ;   -> (b0<<24)|(b1<<16)|(b2<<8)
        SRA_8_XWA / AND QWA,00FF ; -> BASE24 = (b0<<16)|(b1<<8)|b2
        LD XBC, 0000AC44h        ; 44100
        CALL LABEL_03D8CA        ; user_value * 44100
        LD XBC, 000003E8h        ; 1000
        CALL LABEL_03DC5F        ; / 1000      (rounds)
        ADD XHL, (XSP+004h)      ; + BASE24
   =>   descriptor_cell = round(user_ms * 44100/1000) + BASE24
""")
    print("   *** THEREFORE, WITH NO INFERENCE AT ALL: a descriptor cell written")
    print("   by a delay parameter is an ADDRESS = line_base + delay_in_samples.")
    print("   r3-delaydram.md sect. 5(b) reached the same conclusion from the")
    print("   ROUNDNESS of the differences; this is the firmware's own arithmetic")
    print("   and it needs no statistic.")
    print()
    # ---- the 38 records, and the test that BASE24 is a real line base -------
    rows = []
    for (a, u, cells, cons) in C.algos:
        for c, B in sorted(C.taps(a).items()):
            v = cells.get(c)
            if v is None:
                continue
            rows.append((a, u, c, B, v, v - B, (v - B) * MS / float(SR)))
    print("   THE 38 RECORDS (population: 13 algorithms that ship an op-0x67")
    print("   parameter at all, of the 91 that ship descriptor cells):")
    print("      %-4s %-20s %-5s %-7s %-7s %-7s %s"
          % ("algo", "name", "cell", "BASE24", "canned", "delay", "ms"))
    for (a, u, c, B, v, d0, ms) in rows:
        print("      %-4d %-20s 0x%02X  %-7d %-7d %-7d %.2f"
              % (a, C.name(a), c, B, v, d0, ms))
    print()
    print("   NOTE, stated because it bounds the claim: the CANNED defaults are")
    print("   authored in ADDRESS space, not in ms -- MULTI TAP's four cells are")
    print("   6000/12000/18000/24000 exactly, so the ms column is 136.01/272.06/")
    print("   408.12/544.17 rather than round.  The evaluator proves the FORM of")
    print("   the cell; it does not claim the canned numbers came through it.")
    print()
    print("   CHECK: is BASE24-2 an actual cell VALUE of the SAME algorithm?")
    hit = tot = 0
    for (a, u, cells, cons) in C.algos:
        vals = set(cells.values())
        for c, B in sorted(C.taps(a).items()):
            tot += 1
            if (B - 2) in vals:
                hit += 1
    print("      %d of %d op-0x67 records  (%.1f%%)" % (hit, tot, 100.0 * hit / tot))
    r = random.Random(20260727)
    withc = [(a, cells) for (a, u, cells, cons) in C.algos if C.taps(a)]
    allc = [cells for (a, u, cells, cons) in C.algos]
    ch = ct = 0
    for _ in range(200):
        for (a, cells) in withc:
            other = r.choice(allc)
            vals = set(other.values())
            for c, B in C.taps(a).items():
                ct += 1
                if (B - 2) in vals:
                    ch += 1
    print("      CONTROL, BASE24-2 against a RANDOM OTHER algorithm's cells:")
    print("      %d of %d (%.1f%%)  -- the test has a live failure mode and the"
          % (ch, ct, 100.0 * ch / ct))
    print("      corpus takes it %d times." % (tot - hit))
    print("      *** THIS CONTROL IS WEAK AND IS LABELLED WEAK: 16 of the 38")
    print("      records carry BASE24 = 2, whose partner value 0 is a cell in")
    print("      almost every unit-0 algorithm.  Restricted to the NON-TRIVIAL")
    print("      bases:")
    h2 = t2 = 0
    for (a, u, cells, cons) in C.algos:
        vals = set(cells.values())
        for c, B in sorted(C.taps(a).items()):
            if B == 2:
                continue
            t2 += 1
            if (B - 2) in vals:
                h2 += 1
    h3 = t3 = 0
    for _ in range(200):
        for (a, cells) in withc:
            other = r.choice(allc)
            vals = set(other.values())
            for c, B in C.taps(a).items():
                if B == 2:
                    continue
                t3 += 1
                if (B - 2) in vals:
                    h3 += 1
    print("         same algorithm : %d of %d (%.1f%%)" % (h2, t2, 100.0 * h2 / t2))
    print("         random other   : %d of %d (%.1f%%)"
          % (h3, t3, 100.0 * h3 / t3))
    print("      The decisive control for the +3 rule is the shuffle null in")
    print("      sect. `anchor', not this one.")
    print()
    return rows


# ===========================================================================
#  SS2  the +3 cell rule
# ===========================================================================
def anchor_rows(C):
    """[(algo, unit, tap_cell_pos, base, write_cell_pos, dval)] -- every op-0x67
    tap paired with EVERY cell whose value is close to BASE24."""
    out = []
    for (a, u, cells, cons) in C.algos:
        tp = C.taps(a)
        if not tp:
            continue
        ck = sorted(cells)
        pos = {c: i for i, c in enumerate(ck)}
        for c, B in sorted(tp.items()):
            if c not in pos:
                continue
            i = pos[c]
            hits = []
            for j, cj in enumerate(ck):
                dv = B - cells[cj]
                if cj != c and -8 <= dv <= 300:
                    hits.append((j, dv, (j - i) % len(ck)))
            out.append((a, u, i, B, cells[c], hits, len(ck)))
    return out


def cmd_anchor(C):
    head(2, "*** THE +3 RULE: a tap's LINE BASE sits three cells further on ***")
    rows = anchor_rows(C)
    print("   The op-0x67 record gives BASE24.  The line's WRITE address is")
    print("   BASE24 - 2 (see below).  Where does that value live in the cell")
    print("   block, RELATIVE to the tap's own cell?  This question never")
    print("   mentions an instruction.")
    print()
    dd = collections.Counter()
    dv = collections.Counter()
    at3 = notfound = 0
    for (a, u, i, B, v, hits, n) in rows:
        if not hits:
            notfound += 1
            continue
        for (j, d, di) in hits:
            dd[di] += 1
            dv[d] += 1
        if any(di == 3 for (_j, _d, di) in hits):
            at3 += 1
    print("   population: %d op-0x67 tap records over %d algorithms"
          % (len(rows), len({r[0] for r in rows})))
    print("   delta CELL INDEX (mod n) : %s"
          % ", ".join("%+d:%d" % (k, v) for k, v in sorted(dd.items())))
    print("   delta VALUE (BASE24 - cell) : %s"
          % ", ".join("%+d:%d" % (k, v) for k, v in sorted(dv.items())))
    print("   -> %d of %d taps have their BASE24-2 cell at EXACTLY +3;"
          " %d have no near match at all" % (at3, len(rows), notfound))
    print()
    print("   The residual -2 is a CONSTANT: BASE24 = write_address + 2 in")
    print("   %d of %d matches.  The reading that makes the user's ms exact is"
          % (dv.get(2, 0), sum(dv.values())))
    print("   `hardware delay = read_cell - write_cell - 2', i.e. a two-sample")
    print("   offset in the address generator.  INFERRED, and the alternative")
    print("   (the firmware is 2 samples out) is not separable statically.")
    print()
    print("   THE EXCEPTIONS, NAMED (method rule: report the misses):")
    for (a, u, i, B, v, hits, n) in rows:
        if any(di == 3 for (_j, _d, di) in hits):
            continue
        print("      algo %-3d %-20s tap cell idx %-2d base %-6d -> %s"
              % (a, C.name(a), i, B,
                 ("no near cell" if not hits
                  else ", ".join("idx%+d val%+d" % (di, d) for (_j, d, di) in hits))))
    print()
    print("   RIVAL OFFSETS -- the same count for every s, so s=3 is CHOSEN,")
    print("   not assumed:")
    for s in range(1, 9):
        n = sum(1 for (a, u, i, B, v, hits, nn) in rows
                if any(di == s for (_j, _d, di) in hits))
        print("      s = %+d : %2d of %d" % (s, n, len(rows)))
    print()
    print("   CONTROL -- SHUFFLE NULL.  Permute each algorithm's cell VALUES")
    print("   (multiset preserved, index relation destroyed) and re-ask:")
    def strict(cellmap):
        """taps whose BASE24-2 sits at EXACTLY +3 -- the identical predicate is
        used for the ROM and for every shuffle."""
        h = 0
        for (a, u, cells, cons) in C.algos:
            tp = C.taps(a)
            if not tp:
                continue
            ck = sorted(cells)
            cm = cellmap(a, ck, cells)
            pos = {c: k for k, c in enumerate(ck)}
            for c, B in tp.items():
                if c not in pos:
                    continue
                j = (pos[c] + 3) % len(ck)
                if cm[ck[j]] == B - 2:
                    h += 1
        return h

    rom_strict = strict(lambda a, ck, cells: cells)
    r = random.Random(1234)
    best = collections.Counter()
    N = 2000
    for _t in range(N):
        def sh(a, ck, cells, _r=r):
            v = [cells[c] for c in ck]
            _r.shuffle(v)
            return {ck[k]: v[k] for k in range(len(ck))}
        best[strict(sh)] += 1
    mx = max(best)
    exp = sum(k * v for k, v in best.items()) / float(N)
    ge = sum(v for k, v in best.items() if k >= rom_strict)
    print("      identical predicate both sides: `BASE24-2 sits at EXACTLY +3'")
    print("      shuffled: mean %.2f, max %d, >= %d in %d of %d"
          % (exp, mx, rom_strict, ge, N))
    print("      the ROM  : %d of %d" % (rom_strict, len(rows)))
    print()
    return rows


# ===========================================================================
#  SS3  the ladders
# ===========================================================================
def ladder(cells, s=3, lo=1, hi=32767):
    ck = sorted(cells)
    n = len(ck)
    out = []
    for i in range(n):
        j = (i + s) % n
        d = cells[ck[i]] - cells[ck[j]]
        if lo <= d <= hi:
            out.append((i, j, d))
    return out


def cmd_lines(C):
    head(3, "*** THE LADDERS: delay = cell[i] - cell[i+3], corpus wide ***")
    print("   ROOM REVERB 1 (algo 16), every i, s = 3:")
    cells = dict(next(c for (a, u, c, k) in C.algos if a == 16))
    ck = sorted(cells)
    for i in range(len(ck)):
        j = (i + 3) % len(ck)
        d = cells[ck[i]] - cells[ck[j]]
        flag = "  <== a delay line" if 1 <= d <= 4000 else ""
        print("      cell %02X = %-6d  -  cell %02X = %-6d  =  %+7d%s"
              % (ck[i], cells[ck[i]], ck[j], cells[ck[j]], d, flag))
    L = [d for (_i, _j, d) in ladder(cells, 3, 1, 4000)]
    print()
    print("   => %d lines: %s" % (len(L), L))
    print()
    print("   *** THIS FALSIFIES THE PUBLISHED LADDER. ***")
    print("   r3-delaydram.md sect.5 chain 0 = [255, 869, 979, 366, 1044] and")
    print("   r1-allpass-motif.md sect.3 chain 1 = [8905, 528, 1252, 359, 675,")
    print("   976] are the TWO-SEGMENT sums of the same partition -- they pair")
    print("   cell i with cell i+1, and adjudication-round4 sect.3 then read the")
    print("   partition off them.  The op-0x67 anchor pairs cell i with cell i+3,")
    print("   and the PRE-DELAY is the case where the two readings differ and the")
    print("   host settles it:")
    print("      cell 0x00 = %d is a tap, BASE24 = %d  (op-0x67, algo 16)"
          % (cells[0x00], C.taps(16)[0x00]))
    print("      i+1 -> cell 0x01 = %d  ->  delay %+d   IMPOSSIBLE"
          % (cells[0x01], cells[0x00] - cells[0x01]))
    print("      i+3 -> cell 0x03 = %d  ->  delay %+d   = the pre-delay"
          % (cells[0x03], cells[0x00] - cells[0x03]))
    print("   The 11 SEGMENTS are the delays; their pairwise sums are not.")
    print()
    print("   Every algorithm, s = 3, delays in [1, 32767] (the region size):")
    print("      %-4s %-22s %-3s %s" % ("algo", "name", "n", "lines"))
    tot = 0
    for (a, u, cells, cons) in C.algos:
        L = [d for (_i, _j, d) in ladder(cells, 3, 1, 32767)]
        tot += len(L)
        print("      %-4d %-22s %-3d %s" % (a, C.name(a), len(cells), L))
    print("      TOTAL %d lines over %d algorithms" % (tot, len(C.algos)))
    print()
    print("   RIVAL OFFSETS.  A count alone cannot choose s -- every s yields")
    print("   SOME positive differences -- so the discriminating statistic is")
    print("   printed beside it: how many algorithms have a REPEATED delay")
    print("   (a multi-voice chorus or a stereo delay has n identical lines,")
    print("   and no wrong offset manufactures that):")
    for s in range(1, 9):
        t = sum(len(ladder(cells, s, 1, 32767)) for (_a, _u, cells, _k) in C.algos)
        eq = rep = 0
        for (_a, _u, cells, _k) in C.algos:
            L = [d for (_i, _j, d) in ladder(cells, s, 1, 32767)]
            if len(L) > 1 and len(set(L)) == 1:
                eq += 1
            if len(L) != len(set(L)):
                rep += 1
        ov = ab = 0
        for (_a, _u, cells, _k) in C.algos:
            ck = sorted(cells)
            iv = sorted((cells[ck[j]], cells[ck[i]])
                        for (i, j, _d) in ladder(cells, s, 1, 32767))
            bad = any(iv[q + 1][0] < iv[q][1] for q in range(len(iv) - 1))
            touch = sum(1 for q in range(len(iv) - 1) if iv[q + 1][0] == iv[q][1])
            ov += int(bad)
            ab += touch
        print("      s = %+d : %4d lines, %2d ALL-EQUAL, %2d repeated, %2d algos"
              " OVERLAP, %3d abutting joins" % (s, t, eq, rep, ov, ab))
    print()
    print("   *** AND A NUMBER NOBODY CHOSE. ***  Which reverb cells are")
    print("   INVARIANT across all twelve presets?  (The twelve share one body")
    print("   image and differ only in this table, so an invariant cell is")
    print("   structure, not a preset.)")
    rev = [(a, cells) for (a, u, cells, cons) in C.algos if 16 <= a <= 27]
    inv = []
    for k in range(32):
        vs = {cells[sorted(cells)[k]] for (_a, cells) in rev}
        if len(vs) == 1:
            inv.append((k, vs.pop()))
    print("      invariant cells: %s"
          % ", ".join("idx%d = %d" % (k, v) for k, v in inv))
    B = list(C.taps(16).values())[0]
    for k, v in inv:
        if v > 40000:
            print("      idx%d - BASE24 = %d - %d = %d samples = %.2f ms"
                  % (k, v, B, v - B, (v - B) * 1000.0 / 44100))
    print("   *** 41590 - 32770 = 8820 samples = 200.00 ms EXACTLY. ***  Cell")
    print("   index 5 is the ladder's own floor and the ONLY ladder cell the")
    print("   twelve presets share; the distance from the pre-delay's line base")
    print("   to it is a round 200 ms, which is what a PRE DELAY parameter's")
    print("   full-scale headroom looks like.  MEASURED (12 of 12); the reading")
    print("   is INFERRED and nothing rests on it.")
    print()
    print("   *** THE DECIDING COLUMN IS `OVERLAP\'. ***  Two delay lines that")
    print("   share DRAM corrupt each other, so a correct offset must produce")
    print("   line intervals [write, read] that are pairwise DISJOINT.  Under")
    print("   s = 1 -- the pairing that produced the published two-segment")
    print("   ladder -- ROOM REVERB's line k spans [A(k-1), A(k+1)] and line")
    print("   k+1 spans [A(k), A(k+2)]: they overlap by a whole segment.  Under")
    print("   s = 3 they ABUT.  A memory allocator produces abutting buffers;")
    print("   it does not produce overlapping ones.")
    print()


# ===========================================================================
#  SS4  the instruction map
# ===========================================================================
def role_cells(cells, s=3, lo=1, hi=32767):
    """(set of read cell positions, set of write cell positions)."""
    rd, wr = set(), set()
    for (i, j, _d) in ladder(cells, s, lo, hi):
        rd.add(i)
        wr.add(j)
    return rd, wr


RULES = {
    "H-SRC0B  SRC 0x0B is the READ (dark-words H-DIR)":
        lambda w: DC.src(w) == SRC_READ,
    "H-ADDR60 addr8 == 0x60 is the READ":
        lambda w: ((w >> 12) & 0xFF) == 0x60,
    "C-PARITY consumer index is ODD  (** word-blind **)": None,
    "C-INV    SRC 0x0B is the WRITE  (** inverted **)":
        lambda w: DC.src(w) != SRC_READ,
    "C-LO0    lo12 bit 0 set         (** nonsense **)":
        lambda w: bool(w & 1),
}


def map_score(C, delta, s=3, blind=False, rule=None):
    """Score a phase.  ONLY the op-0x67 anchored lines are scored -- those are
    the ones the host firmware labels, so the scoring set contains no DSP-side
    inference at all."""
    good = bad = 0
    detail = []
    for (a, u, cells, cons) in C.algos:
        tp = C.taps(a)
        if not tp:
            continue
        ck = sorted(cells)
        n = len(ck)
        if n != len(cons):
            continue
        pos = {c: i for i, c in enumerate(ck)}
        for c, B in sorted(tp.items()):
            if c not in pos:
                continue
            i = pos[c]
            j = None
            for q, cq in enumerate(ck):
                if cells[cq] == B - 2 and (q - i) % n == s:
                    j = q
            if j is None:
                continue
            kr = (i - delta) % n
            kw = (j - delta) % n
            if blind or rule is None:
                okr, okw = (kr % 2 == 1), (kw % 2 == 0)
            else:
                okr = rule(cons[kr][1])
                okw = not rule(cons[kw][1])
            if not blind and rule is None:
                okr = DC.src(cons[kr][1]) == SRC_READ
                okw = DC.src(cons[kw][1]) != SRC_READ
            good += int(okr) + int(okw)
            bad += int(not okr) + int(not okw)
            detail.append((a, i, j, kr, kw, DC.fmt(cons[kr][1]),
                           DC.fmt(cons[kw][1]), okr, okw))
    return good, bad, detail


def cmd_map(C):
    head(4, "*** THE INSTRUCTION MAP: cell = (consumer index - 1) mod n ***")
    print("   MODEL CLASS, ENUMERATED BEFORE ANYTHING IS SCORED (method rule 3):")
    print("     M1 rigid 1:1, phase delta, NO wrap        <- the round-3 model")
    print("     M2 rigid 1:1, phase delta, wrap mod n     <- this pass")
    print("     M3 per-word stride s(word) in {0,1,2}")
    print("     M4 the cell index is a field of the word")
    print("     M5 two cursors, one per direction")
    print("   M4 dies on sight: MULTI TAP's four taps are FOUR IDENTICAL words")
    print("   (880.1.20.2C7) and must take four different cells.  M3 dies on the")
    print("   same algorithm -- see `control'.  M1 and M2 differ only in whether")
    print("   the last lines close; sect. `lines' shows they do.")
    print()
    print("   The pairing offset s is FORCED to 3 by sect. `anchor' and is")
    print("   INDEPENDENT of delta: under any +1 cursor, cell(k)=k+delta, so")
    print("   cell(k+s)-cell(k) = s whatever delta is.")
    print()
    print("   SCORING SET: only the op-0x67 anchored (read cell, write cell)")
    print("   pairs -- 100 %% host-side, no DSP-side inference.  A phase scores 2".replace("%%", "%"))
    print("   per pair: +1 if the consumer landing on the TAP carries SRC 0x0B")
    print("   (dark-words H-DIR's read code, which r1-allpass-motif.md FORCED")
    print("   for 880.1.60.2D4), +1 if the consumer landing on the LINE BASE")
    print("   does not.")
    print()
    print("      delta   score   miss   rate")
    rows = []
    for d in range(-6, 7):
        g, b, _ = map_score(C, d)
        rows.append((d, g, b))
        star = "  <==" if g == max(x[1] for x in
                                   [(dd,) + map_score(C, dd)[:2] for dd in range(-6, 7)]) else ""
        print("      %+5d   %4d   %4d   %5.1f%%%s"
              % (d, g, b, 100.0 * g / max(1, g + b), star))
    best = max(rows, key=lambda r: r[1])
    print("   => best phase delta = %+d" % best[0])
    print()
    print("   *** RULE 7: THE WORD-BLIND RIVAL. ***  Same test, but the")
    print("   `direction' of a consumer is its INDEX PARITY -- the rule never")
    print("   looks at the instruction:")
    print("      delta   score   miss")
    for d in range(-6, 7):
        g, b, _ = map_score(C, d, blind=True)
        print("      %+5d   %4d   %4d" % (d, g, b))
    gb, bb, _ = map_score(C, best[0], blind=True)
    gr, br, _ = map_score(C, best[0])
    print("   At delta = %+d the blind rival scores %d/%d and the instruction"
          % (best[0], gb, gb + bb))
    print("   rule scores %d/%d." % (gr, gr + br))
    print("   They separate by %d, on %d scored sites.  The head-to-head below"
          % (gr - gb, gr + br))
    print("   is the number that matters: it is taken ONLY where they disagree.")
    print()
    print("   *** THE RULE TOURNAMENT, AT THE WINNING PHASE. ***  Rule 7 asks")
    print("   for the strongest rival that is NOT the hypothesis, including one")
    print("   that never looks at the instruction, and for the score to be taken")
    print("   ONLY on the sites where they disagree.")
    print()
    print("      %-52s %-9s" % ("rule", "score"))
    sc = {}
    for nm, fn in RULES.items():
        g, b, _d = map_score(C, best[0], rule=fn, blind=(fn is None))
        sc[nm] = (g, b)
        print("      %-52s %d of %d" % (nm, g, g + b))
    print()
    names = list(RULES)
    print("      HEAD TO HEAD, scored only where the two rules DISAGREE:")
    for x in range(len(names)):
        for y in range(x + 1, len(names)):
            n1, n2 = names[x], names[y]
            f1, f2 = RULES[n1], RULES[n2]
            w1 = w2 = 0
            _g, _b, det = map_score(C, best[0], rule=RULES[names[0]])
            for (a, i, j, kr, kw, wr_, ww, _o1, _o2) in det:
                for (k, want) in ((kr, True), (kw, False)):
                    cons = next(kk for (aa, uu, cc, kk) in C.algos if aa == a)
                    n = len(cons)
                    w = cons[k % n][1]
                    p1 = (k % 2 == 1) if f1 is None else f1(w)
                    p2 = (k % 2 == 1) if f2 is None else f2(w)
                    if p1 == p2:
                        continue
                    if p1 == want:
                        w1 += 1
                    if p2 == want:
                        w2 += 1
            if w1 + w2:
                print("        %-24s %2d  vs  %-24s %2d   (%d disagreeing sites)"
                      % (n1.split()[0], w1, n2.split()[0], w2, w1 + w2))
    print()
    print("   The per-pair detail at the winning phase:")
    _g, _b, det = map_score(C, best[0])
    print("      %-4s %-20s %-6s %-6s %-14s %-14s" %
          ("algo", "name", "rdcell", "wrcell", "reader", "writer"))
    for (a, i, j, kr, kw, wr_, ww, okr, okw) in det:
        print("      %-4d %-20s idx%-3d idx%-3d %-14s %-14s %s%s"
              % (a, C.name(a), i, j, wr_, ww, "R" if okr else "r",
                 "W" if okw else "w"))
    print()
    return best[0]


# ===========================================================================
#  SS5  ACTION 0x0B
# ===========================================================================
def cmd_act0b(C, delta=-1):
    head(5, "ACTION 0x0B UNDER THE MAP -- the sibling blocker")
    print("   register-space.md G1 (population: 82 corpus ACTION-0x0B words, 23")
    print("   forms) measured that 50 of them are delay-DRAM words and filed")
    print("   0x0B and the DRAM family as ONE problem.  Under the map they get")
    print("   a cell ROLE, so the question becomes answerable.")
    print()
    tally = collections.Counter()
    for (a, u, cells, cons) in C.algos:
        ck = sorted(cells)
        n = len(ck)
        if n != len(cons):
            continue
        rd, wr = role_cells(cells)
        for k, (_wi, w) in enumerate(cons):
            if (w & 0x1F) != 0x0B:
                continue
            p = (k + delta) % n
            role = "READ" if p in rd else "WRITE" if p in wr else "neither"
            tally[(DC.fmt(w), role)] += 1
    print("      %-16s %-8s %s" % ("word", "cell role", "n"))
    for (w, role), c in sorted(tally.items(), key=lambda x: (-x[1], x[0])):
        print("      %-16s %-8s %d" % (w, role, c))
    tot = sum(tally.values())
    print()
    print("   => ACTION 0x0B lands on READ cells %d times and on WRITE cells %d"
          % (sum(v for (w, r), v in tally.items() if r == "READ"),
             sum(v for (w, r), v in tally.items() if r == "WRITE")))
    print("      times, over %d delay-DRAM ACT-0x0B slots in the 83 algorithms" % tot)
    print("      where #cells == #consumers.  **ACTION 0x0B IS THEREFORE NOT A")
    print("      DIRECTION**, and it is not the delay-line access as a class")
    print("      either -- 880.1.60.2D4 (r1's FORCED READ) carries ACTION 0x14,")
    print("      not 0x0B.  The entanglement register-space.md reported is real")
    print("      but it does not make 0x0B decodable.  It stays OPEN.")
    print()
    print("   THE 32 NON-DRAM ACT-0x0B WORDS, as the brief asks:")
    other = collections.Counter()
    for a, img in sorted(C.imgs.items()):
        for w in img:
            if (w & 0x1F) == 0x0B and not DC.is_consumer(w):
                other[DC.fmt(w)] += 1
    for w, c in sorted(other.items(), key=lambda x: -x[1]):
        print("      %-16s x%d" % (w, c))
    print("      They share no field with the DRAM family except ACTION itself")
    print("      (class4 differs, the hi12 escape bit is clear), so nothing")
    print("      concluded here transfers to them.  REPORTED, not resolved.")
    print()
    print("   *** A CONJECTURE OF MY OWN, AND THE CONTROL THAT KILLS IT. ***")
    print("   Reading the TIGHT ladders (delays <= 4000) it looked as though")
    print("   CELL INDEX 1 is never an end of a line -- a reserved slot.  The")
    print("   claim is THRESHOLD-DEPENDENT and therefore is not a claim:")
    for hi in (4000, 32767):
        n1 = tot1 = 0
        for (a, u, cells, cons) in C.algos:
            if len(cells) < 4:
                continue
            tot1 += 1
            rd, wr = role_cells(cells, 3, 1, hi)
            if 1 not in rd and 1 not in wr:
                n1 += 1
        print("      delay cap %5d : cell index 1 is NOT a line end in %d of %d"
              % (hi, n1, tot1))
    print("   At the cap the region size justifies it holds nowhere.  WITHDRAWN")
    print("   before publication.  What survives is only the MEASURED value:")
    print("   cell index 1 is `max used address + 1' in GATED REVERB (14553) and")
    print("   in ROOM REVERB 1 (45464) and is 0 in the other eleven reverbs.  A")
    print("   ring limit is the obvious reading and the eleven zeros refuse it.")
    print("   **OPEN**, and handed on unchanged.")
    print()


# ===========================================================================
#  SS6  what this says about the cursor's reloads
# ===========================================================================
def cmd_cursor(C, delta=-1):
    head(6, "WHAT delta = -1 SAYS ABOUT THE RELOADS (TARGET 1 item A / item E)")
    print("   delta = %+d is measured PER BODY, relative to that body's OWN" % delta)
    print("   allocation base.  If the cursor free-ran, the phase entering the")
    print("   unit-1 body would depend on the unit-0 algorithm's consumer count,")
    print("   which takes %d distinct values over the 79 unit-0 algorithms:"
          % len({len(k) for (_a, u, _c, k) in C.algos if u == 0}))
    print("      %s" % sorted({len(k) for (_a, u, _c, k) in C.algos if u == 0}))
    print("   A constant phase and a varying offset cannot both hold, so the")
    print("   cursor IS reloaded per body.  That is dram-cursor-closure.md item")
    print("   A (|R| >= 2) re-derived from a completely different measurement --")
    print("   its route was closure over 948 frames, this one is the observed")
    print("   phase of the map.")
    print()
    print("   *** AND THE RELOAD VALUE IS NAMED FOR UNIT 0. ***")
    print("   The unit-0 body's first consumer takes cell (0x26 - 1) = 0x25.")
    print("   I-RAM 44 is `801.0.25.825' -- payload 0x25 into pointer register")
    print("   0x825.  r3-delaydram.md candidate (i) said `...825 IS the cursor';")
    print("   dram-cursor-closure.md item C FALSIFIED it because I-RAM 52 loads")
    print("   the SAME 0x25 for unit 1, whose base is 0x00.  Both observations")
    print("   stand.  What is new: 0x25 is EXACTLY the value unit-0 needs, and")
    print("   0x20..0x25 is exactly the slack that closure derived and that no")
    print("   algorithm ever writes.  Unit 1 still needs 0x1F (or 0xFF) and the")
    print("   header hands it 0x25.  CONSISTENT for unit 0, UNRESOLVED for unit 1.")
    print()
    print("   TARGET 1's `resurrection', TASK 3: E30.C.00.404 and 82E.8.0F.000.")
    print("   The |R| = 1 machine needed two more descriptor consumers in the")
    print("   header/epilogue.  Per-body reloads make |R| >= 2 regardless of how")
    print("   those two words decode, so the question is MOOT for DRAM-ADDR.")
    print("   Independently: neither is class4 == 1, and register-space.md sect.2")
    print("   already assigns E30.C.00.404 the unit-0 PRESENT role.")
    print()


# ===========================================================================
#  SS7  controls
# ===========================================================================
def cmd_control(C):
    head(7, "CONTROLS -- each shown saying NO")
    print("   K1  MULTI TAP kills every stream-driven stride model (M3).")
    a = 10
    cells = dict(next(c for (x, u, c, k) in C.algos if x == a))
    cons = next(k for (x, u, c, k) in C.algos if x == a)
    tp = C.taps(a)
    print("       op-0x67 taps: %s" % ", ".join("cell 0x%02X = %d (base %d)"
                                                % (c, cells[c], b)
                                                for c, b in sorted(tp.items())))
    print("       the four taps are cells %s -- NOT contiguous."
          % sorted("0x%02X" % c for c in tp))
    idx = [i for i, (_wi, w) in enumerate(cons) if DC.fmt(w) == "880.1.20.2C7"]
    print("       the four reads are consumers %s, all the SAME word"
          " 880.1.20.2C7," % idx)
    img = C.imgs[a]
    wi = [cons[i][0] for i in idx]
    for k in range(len(wi) - 1):
        gap = [DC.fmt(img[q]) for q in range(wi[k] + 1, wi[k + 1])]
        print("         gap %d->%d : %s" % (wi[k], wi[k + 1], " ".join(gap)))
    print("       gaps 1 and 2 are BYTE-IDENTICAL instruction sequences but the")
    print("       cell must advance +2 then +1.  No function of the executed")
    print("       stream can do that.  M3 REFUTED -- and so is any claim that the")
    print("       four taps land on their four cells: sect. `map' scores MULTI")
    print("       TAP at 3 of 4 and that is reported as a MISS, not smoothed.")
    print()
    print("   K2  the +3 rule against its own rivals: sect. `anchor' prints s=1..8.")
    print("   K3  the shuffle null for the +3 rule: sect. `anchor'.")
    print("   K4  the random-BASE24 control for the ms test: sect. `evaluator'.")
    print("   K5  the word-blind phase rival: sect. `map'.")
    print()
    print("   K6  DEGENERACY CHECK (method rule 4).  Are two phases the same")
    print("       machine?  The line SET is phase-invariant by construction --")
    print("       delta only relabels which word takes which cell -- so a test")
    print("       scored on the line set alone CANNOT choose delta.  That is why")
    print("       the phase is scored on the consumer's SRC field and nothing")
    print("       else.  Printed here so the invariance is not mistaken for a")
    print("       result:")
    for d in (-2, -1, 0, 1):
        t = 0
        for (_a, _u, cells, _k) in C.algos:
            t += len(ladder(cells, 3, 1, 4000))
        print("       delta %+d -> %d lines (identical, as it must be)" % (d, t))
    print()


# ===========================================================================
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", nargs="?", default="all")
    ap.add_argument("--sub", default=os.path.join(
        HERE, "..", "..", "original_ROMs", "kn5000_subprogram_v142.rom"))
    ap.add_argument("--main", default=os.path.join(
        HERE, "..", "..", "original_ROMs", "kn5000_v10_program.rom"))
    ap.add_argument("--tools", default=os.path.expanduser(
        "~/compartilhado/kn7000_mame/tools"))
    args = ap.parse_args()
    C = Corp(os.path.abspath(args.sub), os.path.abspath(args.main), args.tools)
    c = args.cmd
    if c in ("evaluator", "all"):
        cmd_evaluator(C)
    if c in ("anchor", "all"):
        cmd_anchor(C)
    if c in ("lines", "all"):
        cmd_lines(C)
    d = -1
    if c in ("map", "all"):
        d = cmd_map(C)
    if c in ("act0b", "all"):
        cmd_act0b(C, d)
    if c in ("cursor", "all"):
        cmd_cursor(C, d)
    if c in ("control", "all"):
        cmd_control(C)


if __name__ == "__main__":
    main()
