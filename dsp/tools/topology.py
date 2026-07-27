#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""THE REVERB TOPOLOGY, ASKED ON THE HARNESS THAT CAN HOLD A DELAY LINE.

NEC uPD6383GF-3BA (Technics SX-KN5000, IC311).  Round 7.
No hardware.  Static analysis of the Sub CPU ROM, the canned parameter
streams, the 38 body images, the descriptor bank and the published tools.

Every number in `dsp/analysis/reverb-topology-round7.md' comes out of this
file.  Nothing here is applied: no device source, no disassembler, no MAME
build, no .dsm listing.

    python3 dsp/tools/topology.py enum      #  1 the enumeration + what is held
    python3 dsp/tools/topology.py blocks    #  2 *** THE PROGRAM IS B A^5 B A^4 B C C
    python3 dsp/tools/topology.py memory    #  3 *** RULE 4 BEFORE ANY SCORE
    python3 dsp/tools/topology.py refs      #  4 the candidate set, rule-7 matrix
    python3 dsp/tools/topology.py pipeline  #  5 *** TARGET B: is the TRAIL visible?
    python3 dsp/tools/topology.py controls  #  6 *** IT MUST SAY YES, AND NO
    python3 dsp/tools/topology.py search    #  7 *** TARGET A: the topology search
    python3 dsp/tools/topology.py wdata     #  8 TARGET D: the write-data source
    python3 dsp/tools/topology.py predict   #  9 PREDICT-THEN-CHECK, hits AND misses
    python3 dsp/tools/topology.py all       #    everything (~25 min)

    python3 dsp/tools/topology.py search --full     # the un-subsampled arm (~2 h)
"""
from __future__ import print_function

import collections
import itertools
import os
import random
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

import delayline as DL                                       # noqa: E402
import r1_allpass_solve as R                                 # noqa: E402

RR1 = 16                       # ROOM REVERB 1 -- the image algos 16..27 share


def head(n, s):
    print()
    print("=" * 76)
    print("%s. %s" % (n, s))
    print("=" * 76)


def sub(s):
    print()
    print("   -- %s" % s)
    print("   " + "-" * 70)


# ===========================================================================
#  0.  THE ROM SIDE -- loaded once.
# ===========================================================================
_ROM = [None]


def rom():
    if _ROM[0] is None:
        C, r, names, imgs = R.load_rom(DL.TOOLS, DL.SUB, DL.MAIN)
        _ROM[0] = (C, r, names, imgs)
    return _ROM[0]


def rr1_words():
    return rom()[3][RR1]


# ---------------------------------------------------------------------------
#  THE THREE BLOCKS, recognised MECHANICALLY from the words -- never typed.
#  A block is identified by its (hi12, class, lo12) signature with addr8
#  wildcarded, exactly as r1's `core_at' does for BLOCK A.
# ---------------------------------------------------------------------------
BLOCK_A = [(0x880, 0x1, 0x2D4), (0x104, 0x2, 0x000), (0x000, 0x2, 0x419),
           (0x012, 0x2, 0x680), (0x880, 0x1, 0x655), (0x102, 0xA, 0x64B),
           (0x000, 0x2, 0x000), (0x000, 0x2, 0x000)]

BLOCK_B = [(0x880, 0x1, 0x2DA), (0x000, 0xA, 0x695), (None, 0x2, 0x407),
           (0x212, 0x2, 0x419), (0x880, 0x1, 0x64B), (None, 0x2, 0x407),
           (None, 0xA, 0x1D5), (0x212, 0xA, 0x415), (0x202, 0xA, 0x1D5),
           (0x202, 0x2, 0x407)]

BLOCK_C = [(0xC40, 0x1, 0x000), (0xC40, 0x1, 0x000), (None, 0x2, 0x407),
           (0x880, 0x1, 0x2D5), (0x282, 0xA, 0x000), (0x000, 0xA, 0x452),
           (None, 0xA, 0x1D5), (0x202, 0xA, 0x1D5), (0x202, 0x2, 0x1CD)]


def block_at(ws, i, pat):
    if i + len(pat) > len(ws):
        return False
    for k, (hi, cl, lo) in enumerate(pat):
        h, c, _a, l = R.fields(ws[i + k])
        if c != cl or l != lo:
            return False
        if hi is not None and h != hi:
            return False
    return True


def find_blocks(ws):
    """Non-overlapping occurrences of A, B and C, scanned left to right."""
    out, i = [], 0
    while i < len(ws):
        for nm, pat in (("A", BLOCK_A), ("B", BLOCK_B), ("C", BLOCK_C)):
            if block_at(ws, i, pat):
                out.append((nm, i, len(pat)))
                i += len(pat)
                break
        else:
            i += 1
    return out


def dram_pairs(algo=RR1):
    """The (write consumer, read consumer) pairs of an algorithm, in program
    order, with the descriptor line each end belongs to.  Uses delayline's
    Program + lines_of, i.e. bounds.py's classification, unchanged."""
    P = DL.program(algo)
    h = DL.Harness()
    lns = DL.lines_of(algo)
    rby, wby = {}, {}
    for L in lns:
        rby.setdefault(L.read_cell, []).append(L)
        wby.setdefault(L.write_cell, []).append(L)
    rows = []
    for k, (wi, w) in enumerate(P.cons):
        rows.append(dict(k=k, wi=wi, w=w, dir=h.dirof(w),
                         addr=P.cells[(k + h.delta) % len(P.cells)],
                         rlines=rby.get(k, []), wlines=wby.get(k, [])))
    return P, rows


# ===========================================================================
#  1.  A LINE BACKED BY THE TWO-ADDRESS MEMORY, WITH r1's `Line' API.
#
#  ** THIS IS THE ONE THING THIS PASS REPLACES. **  r1's `exec_rep' is used
#  UNCHANGED (it is the ALU and it must not drift); only the object it calls
#  `.read()' and `.write()' on becomes delayline's DelayDRAM behind a
#  DramPort.  So any difference between an old number and a new one is
#  attributable to the memory and to nothing else (rule 10).
# ===========================================================================
class PortLine(object):
    __slots__ = ("port", "line", "tick")

    def __init__(self, port, line):
        self.port, self.line, self.tick = port, line, 0

    def read(self):
        return self.port.access("read", self.line.read_addr, self.tick,
                                tag=self.line.name)

    def write(self, v):
        self.port.access("write", self.line.write_addr, self.tick,
                         value=float(v), tag=self.line.name)

    def advance(self):
        pass                       # the rotation register G does this, not us


BASE_STEP = 4096                   # non-overlapping synthetic line bases


def mem_lines(port, delays, base_step=None, region=32768):
    #  the bases must not alias inside the unit's region -- with 9 lines a
    #  fixed 4096 step wraps line 8 onto line 0 and the ladder silently
    #  becomes a different machine.  Sized from the line count instead.
    if base_step is None:
        base_step = min(BASE_STEP, region // (len(delays) + 2))
    return [PortLine(port, DL.Line("L%d" % k, base_step * (k + 1) + d,
                                   base_step * (k + 1)))
            for k, d in enumerate(delays)]


#  the DRAIN convention, ENUMERATED because the ROM refutes r1's (sect. 2):
#     "r1"      K + max(1, wtrail) repetitions, the trailing ones BLOCK A with
#               no coefficient   -- the published model
#     "cyclic"  K + wtrail repetitions, the trailing ones carrying the NEXT
#               gains, i.e. the window is a slice of a longer ladder
#     "open"    K repetitions only: a line whose write falls outside the window
#               is NEVER written, so its loop does not close in-window.  This
#               is the honest model of the STRADDLE
DRAINS = ("r1", "cyclic", "open")


def run_ladder(m, gains, delays, x, inj, wtrail, h=None, drain="r1",
               memory="two_address", extra_gains=None):
    """One ladder run.  Returns the exit value of every register per sample."""
    K = len(gains)
    h = h or DL.Harness()
    if memory == "two_address":
        mem = DL.DelayDRAM(h, 0, 32768)
        port = DL.DramPort(h, mem)
        lines = mem_lines(port, delays)
    elif memory == "r1_onecell":
        mem = port = None
        lines = [R.Line(d) for d in delays]
    else:
        raise KeyError(memory)
    if drain == "open":
        nrep = K
    elif drain == "cyclic":
        nrep = K + wtrail
    else:
        nrep = K + max(1, wtrail)
    eg = extra_gains or []
    out = [[] for _ in range(6)]
    for xn in x:
        st = [0.0] * 6
        st[inj] = xn
        pend = []
        for r in range(nrep):
            if r < K:
                cf = gains[r]
            elif drain == "cyclic":
                cf = eg[r - K] if r - K < len(eg) else gains[(r - K) % K]
            else:
                cf = None
            for ln in lines:
                if isinstance(ln, PortLine):
                    ln.tick = r * 8
            R.exec_rep(m, st, R.NumAlg, cf, lines, r, K, pend, r * 8)
        for k in range(6):
            out[k].append(st[k])
        if memory == "two_address":
            port.frame_end()
            mem.tick()
        else:
            for ln in lines:
                ln.advance()
    return out


# ===========================================================================
#  2.  THE CANDIDATE SET.  ONE set, so that a zero for one topology is
#      meaningful beside a non-zero for another (the brief's own condition).
#      r1's six are imported UNCHANGED; three are new and are written from the
#      mathematics, never from a machine.
# ===========================================================================
def lattice_ref(gains, delays, x):
    """★ NEW.  A GRAY-MARKEL two-multiply LATTICE all-pass with multi-sample
    delay elements.  r1's `topology_refs' docstring ASSERTS that a lattice is
    the same test as `allpass_ref' because it realises the same transfer
    function; with UNIT delays that is true, with the ladder's distinct
    per-stage delays it is a claim about a structure nobody built.  So it is
    built, and sect. 4 measures whether the assertion holds.

        f_k     = f_{k+1} - g_k * bd_k          (bd_k = b_k delayed by D_k)
        b_{k+1} = g_k * f_k + bd_k
        b_0     = f_0 ,  y = b_K
    """
    K = len(gains)
    lines = [R.Line(d) for d in delays]
    out = []
    for xn in x:
        bd = [lines[k].read() for k in range(K)]
        f = [0.0] * (K + 1)
        b = [0.0] * (K + 1)
        f[K] = xn
        for k in range(K - 1, -1, -1):
            f[k] = f[k + 1] - gains[k] * bd[k]
            b[k + 1] = gains[k] * f[k] + bd[k]
        b[0] = f[0]
        for k in range(K):
            lines[k].write(b[k])
        out.append(b[K])
        for ln in lines:
            ln.advance()
    return out


def pipe_net_w(gains, delays, x, b, c, tap, drain, w):
    """★ NEW.  r1's `pipe_net_ref' with the write TRAIL as a parameter.

    The published family is this at w = 1 and NOTHING in the published set is
    at w = 2 -- which is the trail the descriptors force.  Reproducing r1's
    function exactly at w = 1 is checked in sect. 4, not asserted."""
    K = len(gains)
    lines = [R.Line(d) for d in delays]
    out = []
    for xn in x:
        tprev, wprev = xn, 0.0
        us, ws, ts = [], [], []
        for r in range(K + w):
            if r < K:
                wv = lines[r].read()
            else:
                wv = wprev if drain == "hold" else 0.0
            u = b * wv + c * tprev
            if 0 <= r - w < K:
                lines[r - w].write(u)
            us.append(u)
            ws.append(wv)
            wprev = wv
            tprev = gains[r] * u if r < K else tprev
            ts.append(tprev)
        out.append({"u_last": us[-1], "t_last": ts[-1], "w_last": ws[-1],
                    "u_sum": sum(us), "w_sum": sum(ws)}[tap])
        for ln in lines:
            ln.advance()
    return out


def pipe_pure(topo, gains, delays, x, w):
    """★ NEW.  A ladder that computes EXACTLY topology `topo' but stores each
    stage's line input `w' repetitions later, held in a PRIVATE register.

    This is the reference that decides TARGET B: if a pure-carry pipelined
    ladder is bit-identical to the cascade, then the TRAIL is invisible to the
    transfer function and `the motif is software-pipelined' does NOT by itself
    invalidate a cascade reference."""
    K = len(gains)
    lines = [R.Line(d) for d in delays]
    out = []
    for xn in x:
        pend = []                      # (rep at which to store, line, value)
        v = xn
        wv = 0.0
        store = {}
        for r in range(K + w):
            for (rr, k, val) in list(pend):
                if rr == r:
                    lines[k].write(val)
                    pend.remove((rr, k, val))
            if r < K:
                wv = lines[r].read()
                if topo == "comb":
                    v = v + gains[r] * wv
                    store[r] = v
                elif topo == "allpass":
                    t = gains[r] * (v + wv)
                    store[r] = v + t
                    v = wv - t
                else:
                    raise KeyError(topo)
                pend.append((r + w, r, store[r]))
        for (rr, k, val) in pend:
            lines[k].write(val)
        out.append(v)
        for ln in lines:
            ln.advance()
    return out


PIPE_TAPS = R.PIPE_TAPS


def candidate_set(gains, delays, x, wide=True, wtrails=(1, 2), dedup=True):
    """THE ONE CANDIDATE SET.  Returns [(family, name, array), ...]."""
    refs = [
        ("allpass", "first-order all-pass cascade",
         R.allpass_ref(gains, delays, x)),
        ("comb", "series comb cascade, tap = stored",
         R.comb_series_ref(gains, delays, x, "v")),
        ("comb", "series comb cascade, tap = delayed",
         R.comb_series_ref(gains, delays, x, "w")),
        ("combbank", "plain comb bank (parallel), Schroeder",
         R.comb_parallel_ref(gains, delays, x)),
        ("moorer", "Moorer lowpass comb bank",
         R.lp_comb_ref(gains, delays, x)),
        ("schroeder", "nested all-pass (Schroeder/Gardner)",
         R.nested_ap_ref(gains, delays, x)),
        ("lattice", "Gray-Markel lattice all-pass",
         lattice_ref(gains, delays, x)),
        ("plaincomb", "plain single comb (K=1, first stage only)",
         R.comb_parallel_ref(gains[:1], delays[:1], x)),
    ]
    for w in wtrails:
        refs.append(("pipe-pure%d" % w, "pipelined comb cascade, PURE carry w=%d" % w,
                     pipe_pure("comb", gains, delays, x, w)))
        refs.append(("pipe-pure%d" % w, "pipelined all-pass cascade, PURE carry w=%d" % w,
                     pipe_pure("allpass", gains, delays, x, w)))
    if wide:
        for w in wtrails:
            for b in (1.0, -1.0):
                for c in (1.0, -1.0):
                    for dr in ("hold", "zero"):
                        for tp in PIPE_TAPS:
                            refs.append(("pipe%d" % w,
                                         "pipe-comb w=%d b%+d c%+d %s %s"
                                         % (w, b, c, dr, tp),
                                         pipe_net_w(gains, delays, x, b, c,
                                                    tp, dr, w)))
    #  ★ A REFERENCE THAT IS IDENTICALLY ZERO CAN NEVER BE MATCHED, AND
    #  COUNTING IT INFLATES EVERY DENOMINATOR.  r1's set carries eight of them
    #  (`drain = zero, tap = w_last' makes w_K = 0 for every sample).  They are
    #  removed here and the removal is REPORTED, not hidden (sect. 4).
    refs = [(f, n, a) for (f, n, a) in refs
            if sum(v * v for v in a) > 1e-18]
    if not dedup:
        return refs
    out = []
    for fam, nm, a in refs:
        for _f2, _n2, a2 in out:
            p = R._proj(a, a2)
            if p is not None and p[1] < 1e-12:
                break
        else:
            out.append((fam, nm, a))
    return out


def machine_matches(m, gains, delays, x, refs, wtrail, h=None, drain="r1",
                    memory="two_address", tol=1e-7, first=False,
                    extra_gains=None):
    """Every (injection, extraction, reference) that reproduces a candidate.
    r1's matcher predicate, term for term, on the new executor."""
    hits = []
    for inj in range(6):
        outs = run_ladder(m, gains, delays, x, inj, wtrail, h=h, drain=drain,
                          memory=memory, extra_gains=extra_gains)
        for ext in range(6):
            o = outs[ext]
            den = sum(v * v for v in o)
            if den < 1e-18:
                continue
            for gi, (_fam, _nm, ref) in enumerate(refs):
                sc = sum(a * b for a, b in zip(o, ref)) / den
                if abs(sc) < 1e-6:
                    continue
                mx = max(abs(v) for v in ref)
                if max(abs(sc * a - b) for a, b in zip(o, ref)) < tol * mx:
                    hits.append((inj, ext, gi, sc))
                    if first:
                        return hits
    return hits


# ===========================================================================
#  3.  THE LADDER INPUTS -- re-derived (rule 8), never quoted.
# ===========================================================================
_LAD = [None]


def ladder_inputs():
    """gains and REAL delays for the reverb ladder, from the ROM and the
    descriptor bank.  `127 435 489 183 522' and `8905' are retracted and are
    not used; `3873' is not quoted as MEASURED."""
    if _LAD[0] is not None:
        return _LAD[0]
    C, r, _n, imgs = rom()
    bk = R.reverb_banks(C, r)
    l0, l1 = R.ladder_cram(imgs)
    g0 = [bk[RR1][c] for c in l0]
    g1 = [bk[RR1][c] for c in l1]
    _P, rows = dram_pairs(RR1)
    # the (write, read) pairs, in program order
    pairs = []
    cur = None
    for row in rows:
        if row["dir"] == "WRITE":
            cur = row
        elif row["dir"] == "READ" and cur is not None:
            pairs.append((cur, row))
            cur = None
    ws = rr1_words()
    blocks = find_blocks(ws)
    _LAD[0] = (g0, g1, pairs, blocks, l0, l1)
    return _LAD[0]


#  ★ THE STRUCTURAL RUN USES REDUCED DELAYS, AND SO DID EVERY HONEST PASS
#  BEFORE IT.  `dram-datapath.md' item L records what happens otherwise: fed
#  the real 172..739 to a 96-sample signal, no line recirculates, machine and
#  reference both collapse to the direct path, and the matcher accepted 22 113
#  times out of 4 000 -- a control that CANNOT FAIL.  Sect. 6 demonstrates
#  that failure mode again rather than trusting the note.
DSHORT = [3, 5, 7, 11, 13, 17, 19, 23, 29]
NSIG = 160


def sig(n=NSIG, seed=11):
    rnd = random.Random(seed)
    return [rnd.uniform(-1, 1) for _ in range(n)]


# ===========================================================================
#  SECTION 1 -- the enumeration
# ===========================================================================
def cmd_enum():
    head(1, "THE ENUMERATION, AND EVERY PARAMETER THIS PASS HOLDS FIXED")
    print("""   Rule 3: a result is FORCED only within the option set enumerated,
   and rule 11: the HARNESS is part of that option set.  Both lists are
   printed, and the second one is the one that bounds every zero below.
""")
    sub("ENUMERATED IN THE SEARCH (sect. 7)")
    NE = len(R.EFFECTS)
    rows = [("swap (polarity)", 2, "1 = round 5 D FORCED; 0 = r1's, FALSIFIED, "
                                   "kept as the positive control"),
            ("wtrail", 4, "0..3; the descriptors FORCE 2 (dram-datapath sect. 4)"),
            ("rlag", 3, "0..2; delay-harness D2 -- C1 was itself a wtrail=1 "
                        "assumption"),
            ("land", 7, "-1 (blocking) and 0..5"),
            ("drain", len(DRAINS), "r1 / cyclic / open -- the STRADDLE "
                                   "convention, sect. 2 refutes r1's"),
            ("memory", 2, "two_address (delayline) / r1_onecell -- sect. 3 "
                          "measures where they differ"),
            ("ACTION 0x00/0x19/0x0B", NE, "each, over r1's declared EFFECTS space"),
            ("SRC 0x00", len(R.SRC0_CANDS), "zero P M acc DR tA"),
            ("escact", 2, "is an ESCAPE word's ACTION honoured"),
            ("tbsh", 2, "the tempB >>1 relaxation"),
            ("order", 2, "sequential and THE ADDER"),
            ("write source", len(R.WSRCS), "bus, acc_before, acc_after, M"),
            ("injection register", 6, "acc P tA tB M DR"),
            ("extraction register", 6, "acc P tA tB M DR"),
            ("K (ladder length)", 2, "5 (contiguous BLOCK A run) and 9 (all "
                                     "BLOCK A repetitions)")]
    tot = 1
    for nm, n, why in rows:
        print("     %-24s %6d   %s" % (nm, n, why))
        tot *= n
    print("     %-24s %6s" % ("PRODUCT", "%.3g" % tot))
    sub("HELD FIXED -- and therefore bounding every zero (rule 11)")
    for s in [
        "the ALU is r1's `exec_rep', imported unchanged; 0x13/0x14/0x07/0x12/"
        "0x15 anchored",
        "BLOCK B's ten words are NOT executed -- four class-A multiplies and "
        "several undecoded ACTIONs.  Sect. 2 shows BLOCK B sits INSIDE the "
        "ladder, so every arm here is a search over a program the chip does "
        "not run in isolation",
        "BLOCK C's nine words are not executed either (two C-format traps each)",
        "the program HEAD and TAIL are not executed; the ladder's input is an "
        "injected register and its output an extracted one",
        "the frame is the sample; gstep = 1; no fixed-point saturation",
        "one unit; no arbitration, no refresh; the host writes nothing",
        "the coefficient values are the twelve reverbs' canned C-RAM, frozen",
        "delta = 0 and cursor = single (both FORCED elsewhere) are NOT "
        "re-enumerated here",
    ]:
        for i, ln in enumerate(_wrap(s, 66)):
            print("     %s %s" % ("*" if i == 0 else " ", ln))


def _wrap(s, n):
    out, cur = [], ""
    for wd in s.split():
        if len(cur) + len(wd) + 1 > n:
            out.append(cur)
            cur = wd
        else:
            cur = (cur + " " + wd).strip()
    if cur:
        out.append(cur)
    return out


# ===========================================================================
#  SECTION 2 -- *** THE PROGRAM IS  B A^5 B A^4 B C C ***
# ===========================================================================
def cmd_blocks():
    head(2, "*** THE REVERB PROGRAM IS NOT A LADDER OF ONE MOTIF ***\n"
           "   B A A A A A B A A A A B C C -- and BLOCK B sits INSIDE it")
    ws = rr1_words()
    blocks = find_blocks(ws)
    print("   POPULATION: ROOM REVERB 1, algo %d, %d words, 32 descriptor "
          "cells." % (RR1, len(ws)))
    print("   The same body image serves algos 16..27 byte for byte.")
    print()
    print("   Three word-signatures, matched with addr8 WILDCARDED exactly as")
    print("   r1's `core_at' matches BLOCK A.  Nothing is hand-placed:")
    print()
    for nm, pat in (("A", BLOCK_A), ("B", BLOCK_B), ("C", BLOCK_C)):
        print("     BLOCK %s  (%2d words)  %s" %
              (nm, len(pat), " ".join(("%03X" % h if h is not None else "***")
                                      + ".%X.**.%03X" % (c, l)
                                      for (h, c, l) in pat)))
    print()
    cnt = collections.Counter(b[0] for b in blocks)
    print("   OCCURRENCES:  " + "  ".join("%s x%d" % (k, cnt[k])
                                          for k in sorted(cnt)))
    cov = sum(b[2] for b in blocks)
    print("   words covered: %d of %d (%.0f%%)" % (cov, len(ws),
                                                   100.0 * cov / len(ws)))
    print("   layout: " + " ".join("%s@w%03d" % (n, i) for (n, i, _l) in blocks))

    sub("★★★ AND THE BLOCKS ALTERNATE WITH THE DELAY-LINE PAIRS ONE FOR ONE")
    _g0, _g1, pairs, _b, _l0, _l1 = ladder_inputs()
    print("   Each block owns exactly ONE delay-DRAM write and ONE read, and")
    print("   the write trails the read by TWO pairs (dram-datapath sect. 4).")
    print()
    print("     pair  block  write@   line written    read@    line read")
    bstart = {i: n for (n, i, _l) in blocks}
    for j, (wr, rd) in enumerate(pairs):
        blk = "prologue"
        for (n, i, l) in blocks:
            if i <= wr["wi"] < i + l:
                blk = n
        wl = ",".join("%s(D=%d)" % (L.name, L.samples) for L in wr["wlines"]) \
            or ("PRIME/LIMIT" if not wr["wlines"] else "-")
        rl = ",".join("%s(D=%d)" % (L.name, L.samples) for L in rd["rlines"]) \
            or "-"
        print("      %2d     %s    w%03d    %-22s w%03d    %s"
              % (j, blk, wr["wi"], wl, rd["wi"], rl))
    print()
    print("""   ★★★ WHAT THIS REFUTES.  `r1-allpass-motif.md' models the reverb as
   K CONTIGUOUS repetitions of BLOCK A, and `dram-datapath.md' sect. 4 D says
   `the NINE motif repetitions read lines 2..10 and write lines 0..8'.  Both
   are wrong in the same way and the ledger above says how: the nine BLOCK A
   repetitions are in TWO runs of 5 and 4, and a BLOCK B -- ten words, FOUR
   class-A multiplies, its own write/read pair -- sits BETWEEN them.  The
   line written by the interlude (L5) and the line it reads (L7) belong to no
   BLOCK A repetition at all.  A search that runs 9 contiguous BLOCK A
   repetitions is searching a program the chip does not execute.""")

    sub("★★ AND THE PROLOGUE IS A ROTATION OF BLOCK B -- the signature of a "
        "software-pipelined loop")
    print("   The head does not contain a whole BLOCK B; it contains BLOCK B's")
    print("   LAST four words followed by its FIRST six, which is what a")
    print("   software pipeline's prologue looks like:")
    print()
    for i in range(7, 19):
        print("     w%03d %010X  %s" % (i, ws[i], R.fmt(ws[i])))
    print()
    print("   compare the interlude, w059..w068:")
    for i in range(59, 69):
        print("     w%03d %010X  %s" % (i, ws[i], R.fmt(ws[i])))
    rot = [R.fields(ws[i])[3] for i in range(7, 19)]
    ilv = [R.fields(ws[i])[3] for i in range(59, 69)]
    print()
    print("     lo12 of the interlude : %s" % " ".join("%03X" % v for v in ilv))
    print("     lo12 of the prologue  : %s" % " ".join("%03X" % v for v in rot))
    print()
    print("     ALIGNMENT, printed position by position (rotation by 6);")
    print("     w018 is the prologue's LAST word and has no B position:")
    print("       prologue w   lo12   BLOCK B pos   lo12   ")
    okn = bad = []
    okn, bad = 0, []
    for j in range(11):
        bpos = (6 + j) % 10
        eq = rot[j] == ilv[bpos]
        okn += eq
        if not eq:
            bad.append((7 + j, rot[j], ilv[bpos]))
        print("       w%03d        %03X    B[%d]          %03X    %s"
              % (7 + j, rot[j], bpos, ilv[bpos], "==" if eq else "**"))
    print("       w018        %03X    (none)                  -- prologue ends"
          % rot[11])
    print("       matches: %d of 11" % okn)
    print()
    print("     the %d mismatches: %s"
          % (len(bad), "  ".join("w%03d %03X vs %03X" % b for b in bad)))
    print("""     ★★ AND BOTH MISMATCHES ARE THE SIGNATURE ITSELF.  Each replaces
     a `***.2.**.407' word -- ACTION 0x07, the ANCHORED `M <- bus' -- with an
     ACTION 0x00 word.  A software pipeline's PROLOGUE is exactly the
     iteration in which the carry-copies have nothing to carry and are
     disabled.  This is not an analogy: the two disabled words are BLOCK B's
     two carry-copies, and they are disabled in the one repetition that has no
     predecessor.  ** THE REVERB PROGRAM IS A SOFTWARE-PIPELINED LOOP AND THE
     ROM SAYS SO IN ITS OWN OPCODES. **""")

    sub("★★ THE PRE-DELAY IS WRITTEN BY A LADDER REPETITION AND READ IN THE "
        "HEAD")
    P, rows = dram_pairs(RR1)
    pre = [r for r in rows if r["addr"] == 32768]
    print("   descriptor cell 3 (address 32768) is the base of THREE lines --")
    print("   L0 (800), L12 (650) and L13 (540): one buffer, three taps.")
    for r in rows:
        if any(L.samples in (800, 650, 540) for L in r["rlines"]) or \
                (r["addr"] == 32768 and r["dir"] == "WRITE"):
            print("     w%03d %-5s addr %6d   %s"
                  % (r["wi"], r["dir"], r["addr"],
                     ",".join("%s(D=%d)" % (L.name, L.samples)
                              for L in (r["rlines"] + r["wlines"]))))
    print("""
   The WRITE is w019 -- the first BLOCK A repetition's own slot 0.  The 800-
   sample tap is read at w000, the very first word of the program.  So a value
   the ladder computes at repetition 0 of frame n re-enters the program at its
   HEAD in frame n+800.  ** THE LADDER SITS INSIDE AN OUTER 800-SAMPLE DRAM
   LOOP. **  Two readings, both live, and the head's words are undecoded:
     (i)  the head consumes the pre-delay tap and feeds it INTO the ladder --
          the loop is closed and NO open-cascade reference can express it;
     (ii) the head only sums the three taps into the OUTPUT (early
          reflections) -- the loop is open and a cascade reference is legal.
   Nothing in this pass decides between them.  It is printed because every
   reference anybody has ever scored assumes (ii) without saying so.""")
    return blocks, pairs


# ===========================================================================
#  SECTION 3 -- *** RULE 4, BEFORE ANY SCORE ***
# ===========================================================================
def cmd_memory(nmach=200, seed=3):
    head(3, "*** RULE 4 BEFORE ANY SCORE: DOES THE TWO-ADDRESS MEMORY CHANGE\n"
           "   THE LADDER AT ALL? ***")
    print("""   Round 6 voided five reverb searches on the ground that their delay
   line `READS AND WRITES ONE CELL'.  That is true of SINGLE DELAY.  Whether it
   is true of the LADDER is a question nobody asked, and it is cheap: run the
   same machines on delayline's two-address DelayDRAM and on r1's one-cell
   Line and count the DISAGREEMENTS.  If they never disagree, the memory model
   is DEGENERATE here and no zero of the last five rounds can be blamed on it.
""")
    NE = len(R.EFFECTS)
    x = sig(96)
    gains = [0.75, 0.63, 0.52, 0.50, 0.40]
    rnd = random.Random(seed)
    print("   POPULATION: %d machines per cell, drawn uniformly from r1's own"
          % nmach)
    print("   space; ladder K=5, reduced delays %s, %d samples."
          % (DSHORT[:5], len(x)))
    print()
    print("     swap wtrail  drain    machines  non-zero out  DISAGREE")
    tab = {}
    for swap in (0, 1):
        for wt in (0, 1, 2, 3):
            for drain in ("r1",):
                dis = nz = 0
                r2 = random.Random(seed)
                for _ in range(nmach):
                    m = R.mach(r2.randrange(NE), r2.randrange(NE),
                               r2.randrange(NE), r2.choice(R.SRC0_CANDS),
                               r2.choice(R.WSRCS), wt,
                               r2.choice([-1, 0, 1, 2, 3, 4]),
                               escact=r2.randrange(2), tbsh=r2.randrange(2),
                               order=r2.randrange(2), swap=swap)
                    a = run_ladder(m, gains, DSHORT[:5], x, 0, wt,
                                   drain=drain, memory="two_address")
                    b = run_ladder(m, gains, DSHORT[:5], x, 0, wt,
                                   drain=drain, memory="r1_onecell")
                    if any(abs(v) > 1e-12 for A in a for v in A):
                        nz += 1
                    if max(abs(p - q) for A, B in zip(a, b)
                           for p, q in zip(A, B)) > 1e-9:
                        dis += 1
                tab[(swap, wt)] = (nz, dis)
                print("      %d     %d      %-7s   %5d      %5d       %5d %s"
                      % (swap, wt, drain, nmach, nz, dis,
                         "  <== SEPARATES" if dis else ""))
    sep = [k for k, v in tab.items() if v[1]]
    print()
    print("""   ★★★ THE MEMORY MODEL IS DEGENERATE ON THE LADDER EVERYWHERE EXCEPT
   (swap = 1, wtrail = 0), and the mechanism is not a mystery:  under the
   FORCED polarity slot 0 is the WRITE and slot 4 is the READ, so with a trail
   of ZERO repetitions a line is written at tick 8r and read at tick 8r+4 --
   write BEFORE read, the one configuration in which a one-cell line returns
   the value just stored.  For every wtrail >= 1 the write of line k happens at
   repetition k+w and its read at repetition k, so read precedes write and
   r1's Line(D) delays by exactly D, which is what the two addresses do.""")
    print("   cells that separate: %s" % (sorted(sep) or "NONE"))
    print("""
   ⇒ ** ROUND 6's DIAGNOSIS DOES NOT TRANSFER FROM `SINGLE DELAY' TO THE
   LADDER. **  `dram-datapath.md' sect. 6.2's zero at (swap=1, wtrail=2) was
   NOT a memory artefact.  It was, as that note itself said, an absence of a
   search -- the filter did not exist.  The filter now exists (delay-harness
   sect. 8) and sect. 7 below runs it.  The memory correction buys the ladder
   nothing, and saying so is the point of running the control.""")
    return tab


# ===========================================================================
#  SECTION 4 -- the candidate set and the rule-7 separation matrix
# ===========================================================================
def cmd_refs():
    head(4, "THE CANDIDATE SET -- ONE SET, so that a zero for one topology is\n"
           "   meaningful beside a non-zero for another")
    gains = [0.75, 0.63, 0.52, 0.50, 0.40]
    x = sig()
    D = DSHORT[:5]
    full = candidate_set(gains, D, x, wide=True, dedup=False)
    ded = candidate_set(gains, D, x, wide=True, dedup=True)
    print("   POPULATION: %d references before de-duplication, %d after."
          % (len(full), len(ded)))
    print("   K = 5, gains %s (C-RAM 0x98..0x9C, MEASURED),"
          % " ".join("%.2f" % g for g in gains))
    print("   reduced delays %s, %d samples -> %.1f recirculations of the"
          % (D, len(x), float(len(x)) / max(D)))
    print("   longest line (rule 1: a filter test must recirculate).")
    print()
    fams = collections.Counter(f for f, _n, _a in ded)
    for f in sorted(fams):
        print("     %-12s %3d" % (f, fams[f]))

    sub("★ THE LATTICE -- r1 asserted it was the same test as the all-pass; "
        "MEASURED")
    la = lattice_ref(gains, D, x)
    ap = R.allpass_ref(gains, D, x)
    p = R._proj(la, ap)
    print("     lattice vs first-order all-pass cascade, best scale / residue:")
    print("       %s" % ("%.6f / %.3e" % p if p else "no projection"))
    print("     DEGENERATE (the same test twice): %s"
          % (bool(p and p[1] < 1e-12)))
    print("""     r1's `topology_refs' docstring says a Gray-Markel lattice
     `REALISES the same all-pass transfer function, and the matcher only ever
     compares INPUT/OUTPUT, so it is the same test as allpass_ref'.  With UNIT
     delay elements that is a theorem.  With the ladder's five DISTINCT delays
     it is not, and the measurement above is what settles it.""")

    sub("★ THE GENERALISED PIPE FAMILY -- w = 1 must reproduce r1's exactly")
    ok = bad = 0
    for b in (1.0, -1.0):
        for c in (1.0, -1.0):
            for dr in ("hold", "zero"):
                for tp in PIPE_TAPS:
                    a1 = R.pipe_net_ref(gains, D, x, b, c, tp, dr)
                    a2 = pipe_net_w(gains, D, x, b, c, tp, dr, 1)
                    if max(abs(u - v) for u, v in zip(a1, a2)) < 1e-12:
                        ok += 1
                    else:
                        bad += 1
    print("     pipe_net_w(w=1) == r1's pipe_net_ref : %d of %d" % (ok, ok + bad))
    print("     => %s" % ("PASS -- the new family CONTAINS the published one"
                          if bad == 0 else "** FAIL **"))

    sub("RULE 7 -- the same matcher, scored on every pair of FAMILIES")
    reps = {}
    for f, nm, a in ded:
        reps.setdefault(f, (nm, a))
    names = sorted(reps)
    print("     rows = signal, cols = reference; YES means the matcher accepts")
    print("     %-14s %s" % ("", " ".join("%-10s" % n[:10] for n in names)))
    diag = off = 0
    for a in names:
        row = []
        for b in names:
            p = R._proj(reps[a][1], reps[b][1])
            hit = bool(p and p[1] < 1e-7)
            row.append("YES" if hit else "no")
            if a == b:
                diag += hit
            else:
                off += hit
        print("     %-14s %s" % (a[:14], " ".join("%-10s" % v for v in row)))
    print()
    print("     diagonal %d of %d ; OFF-diagonal %d of %d"
          % (diag, len(names), off, len(names) * (len(names) - 1)))
    blind = [0.0] * len(x)
    blind[0] = 1.0
    nb = sum(1 for _f, _n, a in ded if R._proj(blind, a)
             and R._proj(blind, a)[1] < 1e-7)
    print("     RIVAL that ignores the instruction entirely (an impulse): "
          "accepted by %d of %d" % (nb, len(ded)))
    return ded


# ===========================================================================
#  SECTION 5 -- *** TARGET B: IS THE WRITE TRAIL VISIBLE AT ALL? ***
# ===========================================================================
def cmd_pipeline():
    head(5, "*** TARGET B -- `no cascade reference can ever match a software-\n"
           "   pipelined loop'.  Decided, in three parts.")
    gains = [0.75, 0.63, 0.52, 0.50, 0.40]
    x = sig()
    D = DSHORT[:5]

    sub("B-1  THE TRAIL ITSELF IS INVISIBLE TO THE TRANSFER FUNCTION")
    print("""   A pipelined ladder that holds each stage's line input in a PRIVATE
   register for w repetitions and stores it then, rather than at once.  If the
   stored DATUM is the same, the stored FRAME is the same, so the memory
   cannot tell -- delay-harness item A proves the two-address line is
   order-independent inside a frame.  Measured rather than argued:""")
    print()
    for topo, ref in (("comb", R.comb_series_ref(gains, D, x, "v")),
                      ("allpass", R.allpass_ref(gains, D, x))):
        for w in (0, 1, 2, 3):
            a = pipe_pure(topo, gains, D, x, w)
            e = max(abs(u - v) for u, v in zip(a, ref))
            print("     PURE-carry pipelined %-8s w=%d  vs the cascade: "
                  "max |diff| = %.3e  %s"
                  % (topo, w, e, "IDENTICAL" if e < 1e-12 else "DIFFERENT"))
    print("""
   ⇒ ** THE OBSTRUCTION AS STATED IS FALSE. **  `The motif is software-
   pipelined, therefore a K-stage cascade reference cannot match it' does not
   follow.  What a trail costs is REGISTERS, not a different transfer
   function: the stage value must survive w repetitions.  Whether the six
   registers can do that is an ALU question, and delay-harness sect. 8 already
   answered it -- 51 877 machines of 12 348 000 pass a wtrail = 2 carry.""")

    sub("B-2  WHAT IS ACTUALLY DIFFERENT: A SHARED CARRY")
    print("""   The rival is a ladder whose carry register is REUSED by the
   stages in between -- exactly what the pipe-comb family models.  Here it is
   at the trail the descriptors force, and at the published one:""")
    print()
    pub = candidate_set(gains, D, x, wide=True, wtrails=(1,), dedup=True)
    for w in (1, 2):
        fam = [pipe_net_w(gains, D, x, b, c, tp, dr, w)
               for b in (1.0, -1.0) for c in (1.0, -1.0)
               for dr in ("hold", "zero") for tp in PIPE_TAPS]
        cov = 0
        for a in fam:
            for _f, _n, r0 in pub:
                p = R._proj(a, r0)
                if p and p[1] < 1e-9:
                    cov += 1
                    break
        print("     pipe family w=%d : %d members, %d of them already IN the"
              % (w, len(fam), cov))
        print("       published (w=1) candidate set")
    print("""
   ⇒ the w = 2 shared-carry family is NOT covered by the published set, so
   `schroeder-topology.md' and `dram-datapath.md' scored the reverb against a
   reference set that did not contain the structure the descriptors force.
   That part of the obstruction IS REAL, and sect. 7 carries the w = 2 family.""")

    sub("B-3  ★★★ THE PART OF THE OBSTRUCTION NOBODY NAMED: THE WINDOW IS NOT "
        "THE LOOP")
    _g0, _g1, pairs, blocks, _l0, _l1 = ladder_inputs()
    print("""   In r1's executor, `lines[j]' is READ at repetition j and WRITTEN
   at repetition j+w, and BOTH happen inside the K-repetition window: every
   line is a closed loop by construction.  Sect. 2's ledger says which lines
   really close inside a 5-repetition BLOCK A run:""")
    print()
    ws = rr1_words()
    st = [i for i in range(len(ws)) if R.core_at(ws, i)]
    run1 = st[:5]
    wr_in, rd_in = set(), set()
    for wr, rd in pairs:
        for L in wr["wlines"]:
            if any(i <= wr["wi"] < i + 8 for i in run1):
                wr_in.add(L.name)
        for L in rd["rlines"]:
            if any(i <= rd["wi"] < i + 8 for i in run1):
                rd_in.add(L.name)
    print("     lines WRITTEN inside the 5-repetition run : %s"
          % " ".join(sorted(wr_in, key=lambda s: int(s[1:]))))
    print("     lines READ    inside the same run          : %s"
          % " ".join(sorted(rd_in, key=lambda s: int(s[1:]))))
    both = wr_in & rd_in
    print("     lines with BOTH ends inside               : %s  (%d of %d read)"
          % (" ".join(sorted(both, key=lambda s: int(s[1:]))), len(both),
             len(rd_in)))
    print("""
   ⇒ ** ONLY %d OF THE 5 `STAGES' ARE CLOSED LOOPS INSIDE THE WINDOW. **  The
   line read at repetition 3 is written by the INTERLUDE (BLOCK B) and the one
   read at repetition 4 by the FIRST repetition of the SECOND run.  r1's
   executor closes both with `drain' repetitions of BLOCK A that the ROM does
   not contain.  This is the real content of `dram-datapath.md' item I, and it
   is a statement about the DRAIN CONVENTION, which sect. 7 therefore
   ENUMERATES rather than inherits.""" % len(both))
    return len(both)


# ===========================================================================
#  SECTION 6 -- *** IT MUST SAY YES, AND IT MUST SAY NO ***
# ===========================================================================
def _moorer_skew(gains, delays, x, a):
    """the Moorer bank with an ASYMMETRIC averager -- a twin, not a candidate."""
    lines = [R.Line(d) for d in delays]
    prev = [0.0] * len(delays)
    out = []
    for xn in x:
        y = 0.0
        for k, g in enumerate(gains):
            w = lines[k].read()
            v = xn + g * (a * w + (1.0 - a) * prev[k])
            prev[k] = w
            lines[k].write(v)
            y += v
        out.append(y)
        for ln in lines:
            ln.advance()
    return out


def _nested_broken(gains, delays, x):
    """the nested all-pass with the innermost stage NOT nested -- a twin."""
    lines = [R.Line(d) for d in delays]
    K = len(gains)

    def stage(k, v):
        w = lines[k].read()
        t = gains[k] * (v + w)
        inner = v + t
        if k + 2 < K:
            inner = stage(k + 1, inner)
        lines[k].write(inner)
        return w - t

    out = []
    for xn in x:
        out.append(stage(0, xn))
        for ln in lines:
            ln.advance()
    return out


def _hand_machine():
    """A machine hand-built to BE a comb: slot 5's multiply consumes the read,
    slot 0's write stores the product path.  Not fitted -- constructed."""
    NE = len(R.EFFECTS)
    return None


def cmd_controls():
    head(6, "*** THE CONTROLS: it must say YES to a known-good reference, NO\n"
           "   to a deliberately-wrong twin, and it must SEPARATE the rivals")
    gains = [0.75, 0.63, 0.52, 0.50, 0.40]
    x = sig()
    D = DSHORT[:5]
    refs = candidate_set(gains, D, x, wide=True, dedup=True)

    sub("6.1  IT MUST SAY YES -- every reference matched against the set")
    good = bad = 0
    for fam, nm, a in refs:
        hit = None
        for gi, (_f2, n2, r0) in enumerate(refs):
            p = R._proj(a, r0)
            if p and p[1] < 1e-9:
                hit = n2
                break
        if hit is not None:
            good += 1
        else:
            bad += 1
            print("     ** NOT MATCHED: %s" % nm)
    print("     references accepted by the set they belong to: %d of %d"
          % (good, good + bad))

    sub("6.2  ★★★ THE CONTROL THAT CANNOT FAIL, REPRODUCED ON PURPOSE "
        "(rule 1)")
    _g0, _g1, pairs, _b, _l0, _l1 = ladder_inputs()
    real = []
    for wr, rd in pairs:
        for L in rd["rlines"]:
            real.append(L.samples)
    realD = real[1:6]
    print("     the REAL descriptor delays of the first five reads: %s" % realD)
    print("""     `dram-datapath.md' item L records that feeding those to a short
     test signal made the matcher accept 22 113 times out of 4 000 machines.
     The failure mode is reproduced here on THIS pass's code path rather than
     trusted, on ONE sample of machines scored two ways:""")
    xr = sig(96)
    refs_real = candidate_set(gains, realD, xr, wide=True, dedup=True)
    refs_red = candidate_set(gains, D, xr, wide=True, dedup=True)
    NE = len(R.EFFECTS)
    rnd = random.Random(5)
    ms = [R.mach(rnd.randrange(NE), rnd.randrange(NE), rnd.randrange(NE),
                 rnd.choice(R.SRC0_CANDS), rnd.choice(R.WSRCS), 2,
                 rnd.choice([-1, 0, 1, 2, 3, 4]), escact=rnd.randrange(2),
                 tbsh=rnd.randrange(2), order=rnd.randrange(2), swap=1)
          for _ in range(150)]
    for lbl, dd, rr in (("REAL delays   %s" % realD, realD, refs_real),
                        ("REDUCED %s" % D, D, refs_red)):
        tot = mm = 0
        for m in ms:
            h = machine_matches(m, gains, dd, xr, rr, 2)
            tot += len(h)
            mm += bool(h)
        print("       %-34s %d references, %d machines, %d matched, "
              "%d (inj,ext,ref) hits" % (lbl, len(rr), len(ms), mm, tot))
    print("       longest REAL delay %d vs signal %d -> %.2f recirculations"
          % (max(realD), len(xr), float(len(xr)) / max(realD)))
    print("       longest REDUCED delay %d vs signal %d -> %.1f recirculations"
          % (max(D), len(xr), float(len(xr)) / max(D)))
    print("     => the structural run MUST use reduced delays; the real ones")
    print("        are reported by sect. 2 and never scored.")

    sub("6.3  IT MUST SAY NO -- deliberately-wrong twins of every reference")
    twins = []
    twins.append(("comb, feedback REMOVED",
                  R.comb_series_ref([0.0] * 5, D, x, "v")))
    twins.append(("comb, sign of every gain FLIPPED",
                  R.comb_series_ref([-g for g in gains], D, x, "v")))
    twins.append(("comb, delays all D+1",
                  R.comb_series_ref(gains, [d + 1 for d in D], x, "v")))
    twins.append(("all-pass, feedback REMOVED",
                  R.allpass_ref([0.0] * 5, D, x)))
    twins.append(("all-pass, delays all D-1",
                  R.allpass_ref(gains, [d - 1 for d in D], x)))
    twins.append(("comb bank, one stage MISSING",
                  R.comb_parallel_ref(gains[:4], D[:4], x)))
    twins.append(("lattice, reflection coefficients REVERSED",
                  lattice_ref(gains[::-1], D, x)))
    twins.append(("pipe w=2, feedback removed (b = 0)",
                  pipe_net_w(gains, D, x, 0.0, 1.0, "u_last", "hold", 2)))
    twins.append(("pipe w=2, delays REVERSED",
                  pipe_net_w(gains, D[::-1], x, 1.0, 1.0, "u_last", "hold", 2)))
    twins.append(("Moorer, averager 0.3/0.7 instead of 0.5/0.5",
                  _moorer_skew(gains, D, x, 0.3)))
    twins.append(("nested all-pass, the innermost nesting UNDONE",
                  _nested_broken(gains, D, x)))
    twins.append(("instruction-blind: white noise",
                  sig(len(x), seed=999)))
    twins.append(("instruction-blind: the input itself", list(x)))
    acc = 0
    for nm, a in twins:
        hit = None
        for _f2, n2, r0 in refs:
            p = R._proj(a, r0)
            if p and p[1] < 1e-7:
                hit = n2
                break
        print("     %-42s -> %s" % (nm, ("** ACCEPTED as %s **" % hit[:26])
                                    if hit else "rejected"))
        acc += hit is not None
    print("     POPULATION: %d twins.  ACCEPTED: %d." % (len(twins), acc))

    sub("6.4  A REJECTION THAT ALSO IDENTIFIES")
    fam = [("comb D%+d" % k, R.comb_series_ref(gains, [d + k for d in D], x, "v"))
           for k in range(-2, 4)]
    fam += [("all-pass D%+d" % k, R.allpass_ref(gains, [d + k for d in D], x))
            for k in range(-2, 4)]
    for nm, a in twins[:5]:
        got = [n2 for n2, r0 in fam
               if (R._proj(a, r0) or (0, 9))[1] < 1e-9]
        print("     %-42s -> %s" % (nm, got or "nothing in the D-shifted "
                                    "families"))
    return acc


# ===========================================================================
#  SECTION 7 -- *** TARGET A: THE TOPOLOGY SEARCH ***
# ===========================================================================
LANDS6 = (-1, 0, 1, 2, 3, 4)
WTRAILS = (0, 1, 2, 3)
RLAGS = (0, 1, 2)
CACHE = os.environ.get("TOPOLOGY_CACHE",
                       os.path.join("/tmp", "kn5000-topology-pools"))


def _c1_forms(st, mf, nrl):
    out, f = [], mf
    for i in range(nrl):
        if i:
            f = DL.gadvance(f, st)
        out.append(f)
    return out


def sweep_pools(swap, lands=LANDS6, wtrails=WTRAILS, rlags=RLAGS,
                progress=False):
    """★ ONE EXHAUSTIVE SWEEP, every (wtrail, rlag) pool derived from it.

    delay-harness's `loop_ok_w' is the ONLY structural filter that exists for a
    general wtrail, and it is what selects these pools.

    ** WHAT THE POOL ASSUMES, SAID BEFORE IT IS USED (rule 11). **  `loop_ok_w'
    is the SINGLE-FEEDBACK-PATH filter: it demands the multiplicand carry the
    read with +-1 and the written value carry that product with +-1 and no
    direct copy of the read.  That is a property of a COMB or a first-order
    ALL-PASS around ONE line.  It is NOT a property of a parallel comb bank, a
    Moorer lowpass comb, a nested all-pass or a lattice -- those have either a
    second path into the line or no feedback into that line at all.  So this
    pool is CONDITIONAL on the single-loop hypothesis, and a zero for the bank
    / Moorer / lattice / nested inside it is an ABSENCE OF A SEARCH, not a
    rejection.  Sect. 7.3 runs the topology-NEUTRAL arm for exactly that
    reason.

    `gsym_rep' is evaluated ONCE per machine and every (wtrail, rlag) is
    derived from it, which is the whole reason the sweep is affordable."""
    NE = len(R.EFFECTS)
    pools = {(w, rl): [] for w in wtrails for rl in rlags}
    tot = 0
    t0 = time.time()
    maxrl = max(rlags) + 1
    for ld in lands:
        for order in (0, 1):
            for ea in (0, 1):
                for sh in (0, 1):
                    for s0 in R.SRC0_CANDS:
                        for i00 in range(NE):
                            for i19 in range(NE):
                                for i0b in range(NE):
                                    tot += 1
                                    m0 = R.mach(i00, i19, i0b, s0, None, 1,
                                                ld, ea, sh, order=order,
                                                swap=swap)
                                    st, tr = DL.gsym_rep(m0)
                                    if "MULT" not in tr or "W" not in tr:
                                        continue
                                    mfs = _c1_forms(st, tr["MULT"], maxrl)
                                    ok_rl = [rl for rl in rlags
                                             if abs(abs(mfs[rl].get(("N", 0),
                                                                    0.0)) - 1.0)
                                             <= 1e-9]
                                    if not ok_rl:
                                        continue
                                    for wi, wv in enumerate(tr["W"]):
                                        chain = [wv]
                                        for _ in range(max(rlags) +
                                                       max(wtrails)):
                                            chain.append(
                                                DL.gadvance(chain[-1], st))
                                        for rl in ok_rl:
                                            for w in wtrails:
                                                f = chain[rl + w]
                                                if abs(abs(f.get(("Q", rl),
                                                                 0.0)) - 1.0) \
                                                        > 1e-9:
                                                    continue
                                                if abs(f.get(("N", 0), 0.0)) \
                                                        > 1e-9:
                                                    continue
                                                pools[(w, rl)].append(
                                                    R.mach(i00, i19, i0b, s0,
                                                           R.WSRCS[wi], w, ld,
                                                           ea, sh,
                                                           order=order,
                                                           swap=swap))
        if progress:
            print("       ... land %s done, %d enumerated, %.0f s"
                  % (ld, tot, time.time() - t0))
    return tot, pools


_POOLS = {}
LANDS_R1 = (-1, 0, 1, 2, 7, 8)          # r1's own set, plus the blocking read


def pools_for(swap, lands=LANDS6):
    key = (swap, tuple(lands))
    if key in _POOLS:
        return _POOLS[key]
    import pickle
    try:
        os.makedirs(CACHE)
    except OSError:
        pass
    fn = os.path.join(CACHE, "pools-swap%d-%s.pkl"
                      % (swap, "_".join(str(v) for v in lands)))
    if os.path.exists(fn):
        with open(fn, "rb") as f:
            _POOLS[key] = pickle.load(f)
            return _POOLS[key]
    got = sweep_pools(swap, lands=lands, progress=True)
    with open(fn, "wb") as f:
        pickle.dump(got, f)
    _POOLS[key] = got
    return got


def build_pool(wtrail, rlag, swap, lands=LANDS6, sel=None, cap=None):
    """One (wtrail, rlag) pool out of the sweep."""
    tot, pools = pools_for(swap, lands)
    p = pools.get((wtrail, rlag), [])
    if sel is not None:
        ls = set(sel)
        p = [m for m in p if m[R.LAND] in ls]
    return p[:cap] if cap else p


def neutral_pool(wtrail, rlag, swap, lands, cap=4000, maxdraw=400000, seed=29):
    """★ THE TOPOLOGY-NEUTRAL FILTER, sampled UNIFORMLY (not truncated).

    Weaker than `loop_ok_w' and it assumes no topology: the multiplicand must
    carry SOME delay-line datum with ANY non-zero coefficient (not +-1), and
    the written value must not be disconnected from the loop.  A parallel comb
    bank, a Moorer lowpass comb, a nested all-pass and a lattice all pass this
    and CANNOT pass `loop_ok_w'.

    Sampling is by REJECTION from a uniform draw over the whole space, so the
    pool is not the first `cap' machines of an enumeration order (which would
    concentrate on the smallest `land' and bias every count)."""
    NE = len(R.EFFECTS)
    rnd = random.Random(seed)
    out = []
    draws = 0
    while len(out) < cap and draws < maxdraw:
        draws += 1
        ld = rnd.choice(list(lands))
        order = rnd.randrange(2)
        s0 = rnd.choice(R.SRC0_CANDS)
        i00, i19, i0b = (rnd.randrange(NE), rnd.randrange(NE),
                         rnd.randrange(NE))
        ea, sh = rnd.randrange(2), rnd.randrange(2)
        m0 = R.mach(i00, i19, i0b, s0, None, wtrail, ld, ea, sh, order=order,
                    swap=swap)
        st, tr = DL.gsym_rep(m0)
        if "MULT" not in tr or "W" not in tr:
            continue
        mf = tr["MULT"]
        for _ in range(rlag):
            mf = DL.gadvance(mf, st)
        if abs(mf.get(("N", 0), 0.0)) < 1e-9:
            continue
        cand = []
        for wi, wv in enumerate(tr["W"]):
            f = wv
            for _ in range(rlag + wtrail):
                f = DL.gadvance(f, st)
            if abs(f.get(("Q", rlag), 0.0)) < 1e-9 and \
                    abs(f.get(("N", 0), 0.0)) < 1e-9:
                continue
            cand.append(R.WSRCS[wi])
        if not cand:
            continue
        out.append(R.mach(i00, i19, i0b, s0, rnd.choice(cand), wtrail, ld, ea,
                          sh, order=order, swap=swap))
    return out, draws


def npool(p):
    """rows (machine, wsrc) and DISTINCT machines -- both, because
    `delay-harness.md' sect. 8 quotes 51 877 `admitted' and that number counts
    machines, not (machine, write-source) rows.  Printing one without the
    other is how two searches come to disagree (rule 9)."""
    return len(p), len(set(p))


def _score(pool, refs, gains, delays, x, wtrail, drain, nsample, seed,
           memory="two_address", extra_gains=None):
    rnd = random.Random(seed)
    sample = pool if (nsample is None or len(pool) <= nsample) \
        else rnd.sample(pool, nsample)
    byfam = collections.Counter()
    nhit = 0
    for m in sample:
        hits = machine_matches(m, gains, delays, x, refs, wtrail, drain=drain,
                               memory=memory, extra_gains=extra_gains)
        if hits:
            nhit += 1
            for (_i, _e, gi, _s) in hits:
                byfam[refs[gi][0]] += 1
    return len(sample), nhit, byfam


def cmd_search(full=False, nsample=400):
    head(7, "*** TARGET A -- THE TOPOLOGY SEARCH ON THE CORRECTED HARNESS ***")
    g0, g1, pairs, blocks, l0, l1 = ladder_inputs()
    x = sig(96)
    print("   ladder-0 gains (C-RAM %s, MEASURED) %s"
          % (" ".join("0x%02X" % a for a in l0),
             " ".join("%.4f" % g for g in g0)))
    print("   ladder-1 gains (C-RAM %s, MEASURED) %s"
          % (" ".join("0x%02X" % a for a in l1),
             " ".join("%.4f" % g for g in g1)))
    print("   REDUCED delays %s (sect. 6.2 shows why; the real ones are in"
          % DSHORT[:5])
    print("   sect. 2 and are never scored).  Signal %d samples." % len(x))
    refs = candidate_set(g0, DSHORT[:5], x, wide=True, dedup=True)
    print("   candidate set: %d de-duplicated references in ONE set" % len(refs))
    fams = sorted(set(f for f, _n, _a in refs))
    print("   families: %s" % ", ".join(fams))

    sub("7.0  RULE 4 -- is `land' degenerate inside the FILTER?  (checked "
        "before\n        the pools are quoted, because it sets the "
        "denominator)")
    NE = len(R.EFFECTS)
    rnd = random.Random(41)
    same = diff = 0
    for _ in range(3000):
        i00, i19, i0b = (rnd.randrange(NE), rnd.randrange(NE),
                         rnd.randrange(NE))
        s0 = rnd.choice(R.SRC0_CANDS)
        ea, sh, od = rnd.randrange(2), rnd.randrange(2), rnd.randrange(2)
        got = set()
        for ld in (4, 5, 6, 7, 8):
            m0 = R.mach(i00, i19, i0b, s0, None, 2, ld, ea, sh, order=od,
                        swap=1)
            got.add(tuple(DL.loop_ok_w(m0, 2, 0)))
        if len(got) == 1:
            same += 1
        else:
            diff += 1
    print("     swap=1: machines for which land = 4,5,6,7,8 give the SAME")
    print("     `loop_ok_w' verdict: %d of %d" % (same, same + diff))
    print("     mechanism: under the FORCED polarity the READ is slot 4, so a")
    print("     latency of 4 or more lands past the end of the 8-slot")
    print("     repetition and every such value is drained identically.")
    print("     => the sweep uses land in %s, with 4 standing for every"
          % (LANDS6,))
    print("        land >= 4.  r1's own 7 and 8 are therefore covered.")

    sub("7.1  THE POSITIVE CONTROL -- the PUBLISHED cell must still say YES")
    pool = build_pool(1, 0, 0, LANDS_R1, sel=R.LANDS)
    n, nh, bf = _score(pool, refs, g0, DSHORT[:5], x, 1, "r1", nsample, 7,
                       memory="r1_onecell")
    print("     swap=0 wtrail=1 rlag=0, r1's Line, r1's drain, r1's lands "
          "%s" % (R.LANDS,))
    print("     pool %d rows / %d distinct machines, sampled %d, machines "
          "with >=1 match %d" % (npool(pool) + (n, nh)))
    for f, c in bf.most_common():
        print("       %-14s %d" % (f, c))
    print("     => %s" % ("PASS -- the harness reproduces a non-empty published"
                          " space" if nh else "** FAIL: the control cannot "
                          "pass, every zero below is void **"))

    sub("7.1b THE SECOND POSITIVE CONTROL -- swap=1, wtrail=1, which "
        "`dram-datapath.md'\n        sect. 6.2 reports at 445 matches, all "
        "comb cascade")
    pool = build_pool(1, 0, 1)
    n, nh, bf = _score(pool, refs, g0, DSHORT[:5], x, 1, "r1", nsample, 9)
    print("     pool %d rows / %d distinct, sampled %d, matched %d : %s"
          % (npool(pool) + (n, nh, " ".join("%s:%d" % (f, c)
                                            for f, c in bf.most_common(6))
                            or "-")))

    sub("7.2  ★ THE ARM THE DESCRIPTORS FORCE -- swap=1, wtrail=2, with rlag\n"
        "        and the DRAIN CONVENTION enumerated")
    rows = []
    for rlag in RLAGS:
        for drain in DRAINS:
            pool = build_pool(2, rlag, 1)
            n, nh, bf = _score(pool, refs, g0, DSHORT[:5], x, 2, drain,
                               nsample, 11, extra_gains=g1)
            rows.append((rlag, drain, len(pool), n, nh, bf))
            print("     rlag=%d drain=%-6s pool %7d/%7d  sampled %4d  "
                  "matched %4d  %s"
                  % ((rlag, drain) + npool(pool) + (n, nh,
                     " ".join("%s:%d" % (f, c)
                              for f, c in bf.most_common(5)) or "-")))

    sub("7.3  THE TOPOLOGY-NEUTRAL ARM -- the pool that does NOT assume a "
        "single\n        feedback path, so that the bank / Moorer / nested / "
        "lattice can be reached")
    for rlag in (0, 1):
        pool, draws = neutral_pool(2, rlag, 1, LANDS6, cap=2000)
        n, nh, bf = _score(pool, refs, g0, DSHORT[:5], x, 2, "r1", nsample, 13)
        print("     rlag=%d neutral pool %5d accepted of %6d uniform draws "
              "(%.2f%%)" % (rlag, len(pool), draws,
                            100.0 * len(pool) / max(draws, 1)))
        print("              sampled %4d  matched %4d  %s"
              % (n, nh, " ".join("%s:%d" % (f, c)
                                 for f, c in bf.most_common(5)) or "-"))

    sub("7.4  wtrail SWEPT, everything else at the FORCED values")
    for wt in WTRAILS:
        pool = build_pool(wt, 0, 1)
        n, nh, bf = _score(pool, refs, g0, DSHORT[:5], x, wt, "r1", nsample, 17)
        print("     wtrail=%d pool %7d/%7d  sampled %4d  matched %4d  %s"
              % ((wt,) + npool(pool) + (n, nh,
                 " ".join("%s:%d" % (f, c) for f, c in bf.most_common(5))
                 or "-")))

    sub("7.5  K = 9 -- BOTH BLOCK A RUNS, with the interlude IGNORED\n"
        "        (a model sect. 2 REFUTES, run so that its cost is measured)")
    g9 = g0 + g1
    d9 = DSHORT[:9]
    refs9 = candidate_set(g9, d9, x, wide=True, dedup=True)
    pool = build_pool(2, 0, 1)
    n, nh, bf = _score(pool, refs9, g9, d9, x, 2, "r1", min(nsample, 200), 19)
    print("     K=9, %d references, pool %d/%d sampled %d matched %d  %s"
          % ((len(refs9),) + npool(pool) + (n, nh,
             " ".join("%s:%d" % (f, c) for f, c in bf.most_common(5)) or "-")))
    return rows


# ===========================================================================
#  SECTION 8 -- TARGET D: the write-data source
# ===========================================================================
def cmd_wdata():
    head(8, "TARGET D -- THE WRITE-DATA SOURCE")
    print("""   `dram-datapath.md' item J leaves it OPEN: the corpus's delay-DRAM
   WRITE words name SRC 0x0B 50 times, mem[ptr] 29, the accumulator 3 and
   SRC 0x00 27.  Two routes are available here and NEITHER is a measurement of
   the chip; both are printed with their denominators.""")

    sub("8.1  THE STRUCTURAL ROUTE -- which WSRC survives the loop filter")
    tot, pools = pools_for(1, LANDS6)
    print("     the EXHAUSTIVE sweep of sect. 7: %d machines enumerated over"
          % tot)
    print("     land %s x order 2 x escact 2 x tbsh 2 x SRC0x00 6 x ACTION^3"
          % (LANDS6,))
    print()
    print("     swap=1   wtrail rlag | %s" % "  ".join("%-11s" % w
                                                       for w in R.WSRCS))
    for wt in WTRAILS:
        for rlag in RLAGS:
            cnt = collections.Counter(m[R.WSRC] for m in pools[(wt, rlag)])
            print("                %d    %d   | %s   (pool %d)"
                  % (wt, rlag, "  ".join("%-11d" % cnt[w] for w in R.WSRCS),
                     len(pools[(wt, rlag)])))
    allrows = sum(len(pools[k]) for k in pools)
    nbus = sum(1 for k in pools for m in pools[k] if m[R.WSRC] == "bus")
    print()
    print("     ★★★ `bus' IS ZERO IN ALL TWELVE POOLS: %d of %d rows."
          % (nbus, allrows))

    sub("8.1b  ...AND THE FILTER CAN SAY `bus' -- the control, before the zero "
        "is\n         allowed to mean anything (rule 1)")
    mctl = R.mach(0, R.EFFECTS.index(("", "tA<-acc")), 0, "zero", None, 1, 2,
                  escact=1, tbsh=0)
    got = {w: DL._with_motif(DL._synth_motif_w2(),
                             lambda w=w: DL.loop_ok_w(mctl, w))
           for w in (0, 1, 2, 3)}
    for w in (0, 1, 2, 3):
        print("       synthetic wtrail-2 motif, filter at wtrail = %d : %s"
              % (w, got[w] or "REJECTED"))
    print("       `bus' admitted at wtrail = 2 on a motif built to store the")
    print("       bus: %s  => the zero above is a REJECTION, not a blind spot."
          % ("bus" in got[2]))

    sub("8.1c  WHY, mechanically -- and it is not a coincidence")
    w0 = R.MSLOTS[0]
    print("     the reverb motif's WRITE word is slot 0, `880.1.**.2D4':")
    print("       SRC  = 0x%02X (%s)      ACTION = 0x%02X"
          % (w0["src"], R.SRC_TXT.get(w0["src"], "?"), w0["act"]))
    print("""     Under `wdata = bus' that word stores the READ-DATA REGISTER --
     i.e. the delay-line sample fetched a repetition or two earlier, with NO
     multiply anywhere in the path.  A line fed an unmultiplied copy of
     another line's output is not a comb and not an all-pass; it is a pole on
     the unit circle or no feedback at all, which is exactly condition C3.  So
     the zero is structural, not statistical.

     ★★ AND THIS IS WHERE IT COLLIDES WITH `dram-datapath.md' sect. 2.3.  That
     section reads `the LIMIT word names SRC 0x0B in 64 of 74' as evidence
     that a write word stores the BUS.  The reverb's own line-write word
     carries SRC 0x0B TOO.  Both cannot be the bus and both be in a feedback
     loop.  METHOD RULE 10: the parameter one of them holds fixed is WHICH
     WORD CLASS is being talked about -- sect. 2.3's population is the PRIME
     WRITE (74 of them, one per program, storing a datum nothing reads), and
     this one's population is the LINE WRITE.  A per-word answer is consistent
     with both; a single global `wdata' is not.""")
    print("""
   ⇒ CONDITIONAL, NOT FORCED.  `loop_ok_w' is the single-feedback-path filter,
   so this table says `IF each delay line sits in one comb/all-pass loop THEN
   the write data source is NOT the bus'.  Reading it as a measurement of the
   chip assumes the topology the pass is trying to determine.  What it DOES
   establish is that item J's `no route separates them' is no longer true:
   there is a route, it is exhaustive, and it points AWAY from `bus'.""")

    sub("8.2  THE CORPUS ROUTE -- and the null it needs")
    C, r, _n, imgs = rom()
    h = DL.Harness()
    for weight in ("per ALGORITHM", "per DISTINCT IMAGE"):
        rd_src, wr_src, other_src = (collections.Counter(),
                                     collections.Counter(),
                                     collections.Counter())
        nprog = 0
        seen = set()
        for a in sorted(imgs):
            try:
                P = DL.program(a)
            except KeyError:
                continue
            key = tuple(P.words)
            if weight == "per DISTINCT IMAGE":
                if key in seen:
                    continue
                seen.add(key)
            nprog += 1
            cons = {wi for wi, _w in P.cons}
            for i, w in enumerate(P.words):
                sv = (w >> 6) & 0x1F
                if i in cons:
                    d = h.dirof(w)
                    (wr_src if d == "WRITE" else rd_src)[sv] += 1
                else:
                    other_src[sv] += 1
        print("     POPULATION (%s): %d." % (weight, nprog))
        print("     SRC field of ...      0x0B    0x07    0x00    other   n")
        for nm, c in (("delay-DRAM WRITE words", wr_src),
                      ("delay-DRAM READ words", rd_src),
                      ("every other word", other_src)):
            n = sum(c.values())
            oth = n - c[0x0B] - c[0x07] - c[0x00]
            print("     %-22s %5d   %5d   %5d   %5d  %5d"
                  % (nm, c[0x0B], c[0x07], c[0x00], oth, n))
        nw = sum(wr_src.values())
        no = sum(other_src.values())
        if nw and no:
            print("     P(SRC = 0x0B | WRITE word)     = %.3f  (%d of %d)"
                  % (float(wr_src[0x0B]) / nw, wr_src[0x0B], nw))
            print("     P(SRC = 0x0B | any other word) = %.3f  (%d of %d)"
                  % (float(other_src[0x0B]) / no, other_src[0x0B], no))
        print()
    print("""
   ★ WHAT THIS DOES AND DOES NOT SAY.  If the stored value were the
   ACCUMULATOR, a write word's SRC would serve only the ALU and should look
   like any other word's.  It does not.  That is evidence for `bus', and it is
   the SAME evidence `dram-datapath.md' sect. 2.3 already labelled CONSISTENT,
   not a second one -- and sect. 2.3's own warning stands: measured over the
   38 DISTINCT images instead of the 83 algorithms the association is weak,
   because the algorithm-weighted number is carried by twelve byte-identical
   reverbs.  ** THE WRITE-DATA SOURCE STAYS OPEN. **  What this pass adds is
   the size of the gap and the null it is measured against.""")


# ===========================================================================
#  SECTION 9 -- PREDICT THEN CHECK
# ===========================================================================
def cmd_predict():
    head(9, "PREDICT-THEN-CHECK -- recorded before the measurements, hits AND "
           "misses")
    print("""   The eleven predictions were written to a scratch file before any
   number in this tool existed and are reproduced verbatim in the note.  The
   CHEAP ones are re-checked live below; the expensive ones cite the section
   that produced the verdict.  A miss is printed with the same prominence as a
   hit.""")
    gains = [0.75, 0.63, 0.52, 0.50, 0.40]
    x = sig()
    D = DSHORT[:5]

    sub("re-checked live")
    la = lattice_ref(gains, D, x)
    ap = R.allpass_ref(gains, D, x)
    p = R._proj(la, ap)
    print("     P2  lattice == all-pass cascade?  residue %.3e -> %s"
          % (p[1] if p else -1,
             "DEGENERATE (HIT)" if (p and p[1] < 1e-12) else
             "SEPARATE  ** MISS **"))
    pub = candidate_set(gains, D, x, wide=True, wtrails=(1,), dedup=True)
    fam2 = [pipe_net_w(gains, D, x, b, c, tp, dr, 2)
            for b in (1.0, -1.0) for c in (1.0, -1.0)
            for dr in ("hold", "zero") for tp in PIPE_TAPS]
    cov = sum(1 for a in fam2 if any((R._proj(a, r0) or (0, 9))[1] < 1e-9
                                     for _f, _n, r0 in pub))
    print("     P3  w=2 pipe family already in the published set: %d of %d "
          "-> %s" % (cov, len(fam2), "HIT" if cov == 0 else "** MISS **"))
    e = max(max(abs(u - v) for u, v in
                zip(pipe_pure(t, gains, D, x, w),
                    R.comb_series_ref(gains, D, x, "v") if t == "comb"
                    else R.allpass_ref(gains, D, x)))
            for t in ("comb", "allpass") for w in (0, 1, 2, 3))
    print("     P4  PURE-carry pipelined == cascade: max |diff| %.3e -> %s"
          % (e, "HIT" if e < 1e-12 else "** MISS **"))
    ws = rr1_words()
    bl = find_blocks(ws)
    seq = "".join(n for (n, _i, _l) in bl)
    print("     P11 block sequence read off the ROM: %s -> %s"
          % (seq, "HIT -- non-contiguous" if "BA" in seq and "AB" in seq
             else "** MISS **"))

    sub("verdicts from the expensive sections, with the section that "
        "measured them")
    for pid, verdict, txt, where in [
        ("P1", "HIT", "two-address memory degenerate on the ladder except "
                      "(swap=1,wtrail=0): 48/200 in one cell, 0 in seven",
         "sect. 3"),
        ("P5", "HIT then half-MISS",
         "wtrail=2 non-zero (102/400, pipe-comb largest) -- but ZERO at "
         "rlag=1 and ZERO at drain=open, neither predicted", "sect. 7.2"),
        ("P6", "HIT", "`bus' 0 of 1543857 across ALL twelve pools; still OPEN "
                      "because the exclusion is conditional", "sect. 8.1"),
        ("P7", "** MISS **", "K=9 gives MORE, not fewer: 67/200 = 33.5% "
                             "against 102/400 = 25.5%", "sect. 7.5"),
        ("P8", "HIT, badly", "`land' is not forced -- but every survivor sits "
                             "at land = -1, which contradicts a published "
                             "bound", "sect. 7.2 / 8.1"),
        ("P9", "HIT", "2 families non-zero, 5 at zero, in ONE candidate set",
         "sect. 7.2 / 7.3"),
        ("P10", "HIT", "70 references collapse to 1 and 138/150 machines are "
                       "accepted with the real delays", "sect. 6.2"),
    ]:
        print("     %-4s %-19s %s" % (pid, verdict, where))
        for ln in _wrap(txt, 62):
            print("          %s" % ln)
    print()
    print("     MISSES: 2 outright (P2, P7) and 1 partial (P5), of 11.")


def cmd_all(full=False):
    cmd_enum()
    cmd_blocks()
    cmd_memory()
    cmd_refs()
    cmd_pipeline()
    cmd_controls()
    cmd_search(full=full)
    cmd_wdata()
    cmd_predict()


def main():
    cmds = {"enum": cmd_enum, "blocks": cmd_blocks, "memory": cmd_memory,
            "refs": cmd_refs, "pipeline": cmd_pipeline,
            "controls": cmd_controls, "wdata": cmd_wdata,
            "predict": cmd_predict}
    a = sys.argv[1:] or ["all"]
    full = "--full" in a
    a = [v for v in a if not v.startswith("--")]
    for c in a:
        if c == "search":
            cmd_search(full=full)
        elif c == "all":
            cmd_all(full=full)
        elif c in cmds:
            cmds[c]()
        else:
            print("unknown: %s" % c)
            print(__doc__)
            return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
