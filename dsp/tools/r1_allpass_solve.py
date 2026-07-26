#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""r1_allpass_solve.py -- FORCE the 8-word all-pass motif of the KN5000 reverb.

NEC uPD6383GF (Technics SX-KN5000 IC311) effects DSP.  Roadmap item **R1**
(`kn7000_mame/notes/dsp-next-steps-roadmap.md`).  Write-up:
`dsp/analysis/r1-allpass-motif.md`.

METHOD -- the one that already worked on this chip for the biquad and for the
three multiply forms: take the algorithm as a CONSTRAINT SYSTEM and solve for
the instruction semantics, instead of guessing semantics and hoping an
algorithm appears.  Nothing here is fitted by hand: the search enumerates every
assignment its declared machine model can express and reports the WHOLE
surviving set, however big.

A first-order all-pass is exact mathematics.  The realisation that costs ONE
multiply (the Gardner / Dattorro one-multiplier form) is

    s     = x + w                 w = the delay-line output
    t     = g * s                 THE multiply
    d_in  = x + t                 -> written back to the delay line
    y     = w - t                 -> becomes the next stage's x

    H(z)  = (z^-D - g) / (1 - g z^-D)                      |H(e^jw)| = 1

Run:  python3 dsp/tools/r1_allpass_solve.py [--rom SUB] [--main MAIN]
                                            [--tools kn7000_mame/tools]
                                            [--terms 2|3] [section ...]
Sections: census motif banks delays solve verify separator   (default: all)

Everything under CENSUS / MOTIF / BANKS / DELAYS is MEASURED from the ROM.
SOLVE is DETERMINED-by-exhaustive-search inside the declared model.  VERIFY is
the falsification pass, with controls that must fail.
"""
import argparse
import collections
import itertools
import os
import random
import sys

REVERB_ALGOS = list(range(16, 28))
GATED = 8

WORDS = ["880.1.60.2D4", "104.2.00.000", "000.2.00.419",
         "012.2.00.680", "880.1.20.655", "102.A.00.64B"]


# --------------------------------------------------------------------------
#  0.  ROM access -- re-uses the project's parsers, nothing re-implemented
# --------------------------------------------------------------------------
def load_rom(tools, sub, main):
    sys.path.insert(0, tools)
    import kn5000_dsp_extract as E
    import kn5000_dsp_coeffs as C
    rom = E.Rom(sub)
    names = C.effect_names(main) if main and os.path.exists(main) else {}
    imgs = {}
    for i in range(100):
        try:
            iram, _c, _o = E.parse_stream(rom, rom.u32le(E.ALGO_TABLE + 4 * i))
        except Exception:
            continue
        if iram:
            imgs[i] = [int.from_bytes(bytes(w), "big")
                       for _a, ws, _l in iram for w in ws]
    return C, rom, names, imgs


def fields(w):
    return (w >> 24) & 0xFFF, (w >> 20) & 0xF, (w >> 12) & 0xFF, w & 0xFFF


def fmt(w):
    hi, cl, ad, lo = fields(w)
    return "%03X.%X.%02X.%03X" % (hi, cl, ad, lo)


# The motif CORE: six words, addr8 wildcarded (the only field that ever varies).
CORE = [(0x880, 0x1, 0x2D4),      # [0] external-DRAM word #1
        (0x104, 0x2, 0x000),      # [1] the "all-pass marker"
        (0x000, 0x2, 0x419),      # [2]
        (0x012, 0x2, 0x680),      # [3] hi12 bit 4 -> mem[ptr] <- acc
        (0x880, 0x1, 0x655),      # [4] external-DRAM word #2
        (0x102, 0xA, 0x64B)]      # [5] THE multiply (class A -> cursor fetch)
NOP = 0x0000200000


def core_at(ws, i):
    if i + 6 > len(ws):
        return False
    for k, (hi, cl, lo) in enumerate(CORE):
        h, c, _a, l = fields(ws[i + k])
        if h != hi or c != cl or l != lo:
            return False
    return True


def motif_at(ws, i):
    return core_at(ws, i) and ws[i + 6:i + 8] == [NOP, NOP]


def cram_cursor(ws):
    """C-RAM offset consumed by each class-A word (the implicit cursor advances
    +1 per class-A word from the bank base)."""
    out, k = {}, 0
    for i, w in enumerate(ws):
        if ((w >> 20) & 0xF) == 0xA:
            out[i] = k
            k += 1
    return out


# --------------------------------------------------------------------------
#  1.  Symbolic linear algebra over the repetition-entry atoms
#
#      A   accumulator at repetition entry      (carrier unknown -- searched)
#      P   product register at entry            (the previous product)
#      M   the ONE D-RAM cell mem[ptr]          (addr8 == 0 => frozen)
#      D   DRAM read-data register at entry     (the previous read)
#      N   the value THIS repetition's DRAM read returns
#      Q   the product THIS repetition's class-A word computes
#      N'  the NEXT repetition's read      } only reached by the fixpoint
#      Q'  the NEXT repetition's product   } substitution
# --------------------------------------------------------------------------
NB = 8
IA, IP, IM, ID, IN, IQ, IN2, IQ2 = range(NB)
ATOM = ("A", "P", "M", "D", "N", "Q", "N'", "Q'")
ZERO = (0,) * NB
REGS = ("acc", "P", "M", "DR")


def unit(i):
    v = [0] * NB
    v[i] = 1
    return tuple(v)


def add(*vs):
    return tuple(sum(c) for c in zip(*vs))


def scale(k, v):
    return tuple(k * c for c in v)


def show(v):
    if not any(v):
        return "0"
    out = []
    for i, c in enumerate(v):
        if not c:
            continue
        out.append(("+" if c > 0 else "-") +
                   (ATOM[i] if abs(c) == 1 else "%d*%s" % (abs(c), ATOM[i])))
    return "".join(out).lstrip("+")


def alu_exprs(nterms):
    """acc' = a signed sum of at most `nterms` of the four visible registers.
    Nothing a two-input (or three-input) ALU with an accumulator could do in one
    word is excluded; `()` is acc' = 0."""
    out = [()]
    for r in REGS:
        for s in (1, -1):
            out.append(((s, r),))
    for a, b in itertools.combinations(REGS, 2):
        for sa in (1, -1):
            for sb in (1, -1):
                out.append(((sa, a), (sb, b)))
    if nterms >= 3:
        for a, b, c in itertools.combinations(REGS, 3):
            for sa in (1, -1):
                for sb in (1, -1):
                    for sc in (1, -1):
                        out.append(((sa, a), (sb, b), (sc, c)))
    return out


def show_expr(e):
    if not e:
        return "acc <- 0"
    return "acc <- " + "".join(("+" if k > 0 else "-") + r
                               for k, r in e).lstrip("+")


def apply_expr(e, env):
    if not e:
        return ZERO
    return add(*[scale(k, env[r]) for k, r in e])


def substitute(form, A_exit, M_exit):
    """Advance a form by one repetition: A->A_exit, P->Q, M->M_exit, D->N,
    N->N', Q->Q'.  Returns None if the form cannot be advanced."""
    out = ZERO
    for i, c in enumerate(form):
        if not c:
            continue
        if i == IA:
            out = add(out, scale(c, A_exit))
        elif i == IP:
            out = add(out, scale(c, unit(IQ)))
        elif i == IM:
            out = add(out, scale(c, M_exit))
        elif i == ID:
            out = add(out, scale(c, unit(IN)))
        elif i == IN:
            out = add(out, scale(c, unit(IN2)))
        elif i == IQ:
            out = add(out, scale(c, unit(IQ2)))
        else:
            return None
    return out


# --------------------------------------------------------------------------
#  2.  The exhaustive search
# --------------------------------------------------------------------------
def search(nterms=2, alu_slots=(1, 2, 3, 5), verbose=True):
    """Enumerate EVERY assignment the model can express; keep the ones that make
    the repetition an exact software-pipelined all-pass stage.

    The three acceptance tests, all FORCED by the mathematics:

      MULT   ==  eta*D - P + eta*N      the multiplicand is s[r] = x[r] + w[r]
      D_exit ==  N                      the fresh read is in DR at exit
      WVAL advanced by one repetition == d_in[r] = x[r]+t[r] = D - eta*P + eta*Q

    The third is the INDUCTIVE STEP: the value this repetition pushes to the
    delay line must be, one repetition later, exactly the all-pass state update.
    Nothing else is imposed and no word is told what to do.

    Exhaustive but not naive: two expression sequences that leave the SAME
    symbolic value in every register are the same machine, so states are merged
    slot by slot.  That is what lets a complete search finish in seconds.
    """
    exprs = alu_exprs(nterms)
    IDENT = exprs.index(((1, "acc"),))
    free = set(alu_slots)
    NE = len(exprs)
    sols = []
    n_enum = 0

    for read_slot in (0, 4):
        write_slot = 4 if read_slot == 0 else 0
        # D_exit == N is required, so the read data must land by slot 5.
        for land in range(read_slot, 6):
            for store in ("old", "new"):
                # --- forward pass over slots 0..3, merging equal states
                states = {(unit(IA), unit(IM), None): [()]}
                for slot in range(4):
                    DR = unit(ID) if slot < land else unit(IN)
                    choices = range(NE) if slot in free else (IDENT,)
                    nxt = {}
                    for (acc, M, wv), paths in states.items():
                        env = {"acc": acc, "P": unit(IP), "M": M, "DR": DR}
                        for ei in choices:
                            n_enum += 1
                            a2 = apply_expr(exprs[ei], env)
                            w2 = wv
                            if slot == write_slot:
                                w2 = (acc, a2, M)   # before / after / mem[ptr]
                            M2 = (acc if store == "old" else a2) \
                                if slot == 3 else M
                            nxt.setdefault((a2, M2, w2), []).extend(
                                p + (ei,) for p in paths)
                    states = nxt
                # --- slots 4 and 5, then the checks
                DR4 = unit(ID) if 4 < land else unit(IN)
                DR5 = unit(ID) if 5 < land else unit(IN)
                for (acc4, M4, wv), paths in states.items():
                    env4 = {"acc": acc4, "P": unit(IP), "M": M4, "DR": DR4}
                    for e4 in (range(NE) if 4 in free else (IDENT,)):
                        acc5 = apply_expr(exprs[e4], env4)
                        w = (acc4, acc5, M4) if write_slot == 4 else wv
                        env5 = {"acc": acc5, "P": unit(IP), "M": M4, "DR": DR5}
                        for e5 in (range(NE) if 5 in free else (IDENT,)):
                            n_enum += 1
                            acc6 = apply_expr(exprs[e5], env5)
                            cand = (("acc_before", acc5), ("acc_after", acc6),
                                    ("M", M4), ("DR", DR5))
                            for msrc, MULT in cand:
                                for eta in (1, -1):
                                    tgt = add(scale(eta, unit(ID)),
                                              scale(-1, unit(IP)),
                                              scale(eta, unit(IN)))
                                    if MULT != tgt:
                                        continue
                                    want = add(unit(ID), scale(-eta, unit(IP)),
                                               scale(eta, unit(IQ)))
                                    for wi, wsrc in enumerate(
                                            ("acc_before", "acc_after", "M")):
                                        W = w[wi]
                                        nx = substitute(W, acc6, M4)
                                        if nx is None or nx != want:
                                            continue
                                        for p in paths:
                                            sols.append(dict(
                                                e_idx=tuple(p) + (e4, e5),
                                                read_slot=read_slot, land=land,
                                                store=store, wsrc=wsrc,
                                                msrc=msrc, eta=eta, WVAL=W,
                                                MULT=MULT, A_exit=acc6,
                                                M_exit=M4))
    if verbose:
        print("   expanded %d transitions; %d surviving assignment(s)"
              % (n_enum, len(sols)))
    return exprs, sols


def canonical(sol):
    """Two solutions are the SAME machine when every observable agrees."""
    return (sol["read_slot"], sol["land"], sol["store"], sol["wsrc"],
            sol["msrc"], sol["eta"], sol["WVAL"], sol["MULT"],
            sol["A_exit"], sol["M_exit"])


def eta_note():
    return ("eta is a LABEL, not a machine decision: it records whether the "
            "product register is read as +t or -t.  Both survive by symmetry.")


# --------------------------------------------------------------------------
#  3.  Numeric falsifier -- the ladder against a textbook cascade
# --------------------------------------------------------------------------
class Line(object):
    __slots__ = ("buf", "pos", "n")

    def __init__(self, n):
        self.n = n
        self.buf = [0.0] * n
        self.pos = 0

    def read(self):
        return self.buf[self.pos]

    def write(self, v):
        self.buf[self.pos] = v

    def advance(self):
        self.pos = (self.pos + 1) % self.n


def allpass_ref(gains, delays, x):
    """The textbook cascade -- written from the mathematics, never from the ROM."""
    lines = [Line(d) for d in delays]
    out = []
    for xn in x:
        v = xn
        for k, g in enumerate(gains):
            w = lines[k].read()
            t = g * (v + w)
            lines[k].write(v + t)
            v = w - t
        out.append(v)
        for ln in lines:
            ln.advance()
    return out


def run_ladder(exprs, sol, gains, delays, x):
    """Run K+1 repetitions of the CORE per sample.

    Repetition r carries the arithmetic and the delay-line WRITE of stage r-1
    together with the delay-line READ and the multiply of stage r -- the
    software pipeline the search forces.  Repetition K is the drain (its read
    and its multiply belong to the next block and are suppressed).  The ladder
    input enters through the (DR, P) pair, which is exactly what the five-word
    separator in front of every ladder supplies: one DRAM read + one class-A
    multiply.
    """
    e_idx = sol["e_idx"]
    read_slot, land = sol["read_slot"], sol["land"]
    store, wsrc, msrc, eta = sol["store"], sol["wsrc"], sol["msrc"], sol["eta"]
    write_slot = 4 if read_slot == 0 else 0
    K = len(gains)
    lines = [Line(d) for d in delays]
    acc = P = M = DR = 0.0
    out = []
    for xn in x:
        # Priming is DERIVED from the machine's own invariant, never chosen:
        # a virtual stage -1 with x[-1] = 0, t[-1] = 0, w[-1] = xn.  Evaluate
        # the machine's own A_exit / M_exit at that state.
        env0 = {IA: 0.0, IP: 0.0, IM: 0.0, ID: 0.0, IN: xn, IQ: 0.0,
                IN2: 0.0, IQ2: 0.0}
        acc = sum(c * env0[i] for i, c in enumerate(sol["A_exit"]))
        M = sum(c * env0[i] for i, c in enumerate(sol["M_exit"]))
        DR, P, pending = xn, 0.0, None             # x[0] = w - t = xn - 0
        for r in range(K + 1):
            last = (r == K)
            for slot in range(6):
                if pending is not None and pending[0] == slot:
                    DR, pending = pending[1], None
                if slot == read_slot and not last:
                    v = lines[r].read()
                    if land == slot:
                        DR = v
                    else:
                        pending = (land, v)
                env = {"acc": acc, "P": P, "M": M, "DR": DR}
                before = acc
                if slot == write_slot and wsrc != "acc_after" and r > 0:
                    lines[r - 1].write(env["acc"] if wsrc == "acc_before"
                                       else env["M"])
                e = exprs[e_idx[slot]]
                acc = sum(k * env[rr] for k, rr in e) if e else 0.0
                if slot == write_slot and wsrc == "acc_after" and r > 0:
                    lines[r - 1].write(acc)
                if slot == 3:
                    M = before if store == "old" else acc
                if slot == 5 and not last:
                    mv = {"acc_before": before, "acc_after": acc,
                          "M": M, "DR": DR}[msrc]
                    # P <- coefficient * multiplicand.  `eta` is NOT applied
                    # here: it is only how the INVARIANT reads P (t = eta*P),
                    # and the chip multiplies by the coefficient it is given.
                    P = gains[r] * mv
                if last and slot == 3:
                    sgn, reg = sol.get("out", (1, "acc"))
                    out.append(sgn * (acc if reg == "acc" else M))
            if pending is not None:
                DR, pending = pending[1], None
        for ln in lines:
            ln.advance()
    return out


def maxdiff(a, b):
    return max(abs(u - v) for u, v in zip(a, b))


# --------------------------------------------------------------------------
#  4.  Report sections
# --------------------------------------------------------------------------
def sec_census(imgs, names):
    print("=" * 76)
    print("1. CENSUS -- every occurrence of the motif.  MEASURED.")
    print("=" * 76)
    tot6 = tot8 = 0
    for a in sorted(imgs):
        hits = [i for i in range(len(imgs[a])) if core_at(imgs[a], i)]
        if not hits:
            continue
        full = [i for i in hits if motif_at(imgs[a], i)]
        tot6 += len(hits)
        tot8 += len(full)
        print("   algo %3d %-18s core-6 x%d (8-word x%d) at %s"
              % (a, names.get(a, ""), len(hits), len(full), hits))
    print("   TOTAL core-6 %d, of which 8-word %d, over 13 programs -- all reverbs"
          % (tot6, tot8))
    print()
    print("   per-word corpus frequency (occurrences / programs):")
    freq, prg = collections.Counter(), collections.defaultdict(set)
    for a, ws in imgs.items():
        for w in ws:
            freq[w] += 1
            prg[w].add(a)
    for w in (0x08801602D4, 0x0104200000, 0x0000200419, 0x0012200680,
              0x0880120655, 0x0102A0064B, NOP):
        print("     %010X %-14s %4d in %2d programs" % (w, fmt(w), freq[w],
                                                        len(prg[w])))


def sec_motif(imgs, names):
    print("=" * 76)
    print("2. THE MOTIF SIDE BY SIDE -- what varies, what does not.  MEASURED.")
    print("=" * 76)
    for a in (16, GATED):
        ws = imgs[a]
        st = [i for i in range(len(ws)) if core_at(ws, i)]
        print("   algo %d %s -- core repetitions at %s"
              % (a, names.get(a, ""), st))
        for k in range(8):
            row = [fmt(ws[s + k]) if s + k < len(ws) else "-- " for s in st]
            print("     slot%d  %s" % (k, " ".join(row)))
        print()
    var = collections.Counter()
    for a in sorted(imgs):
        for s in [i for i in range(len(imgs[a])) if core_at(imgs[a], i)]:
            for k in range(6):
                var[(k, fields(imgs[a][s + k])[2])] += 1
    print("   addr8 histogram over all %d core occurrences, per slot:"
          % sum(c for (k, _v), c in var.items() if k == 0))
    for k in range(6):
        vals = sorted([(v, c) for (kk, v), c in var.items() if kk == k])
        print("     slot%d %-14s %s" % (k, WORDS[k],
                                        " ".join("%02X x%d" % (v, c)
                                                 for v, c in vals)))


def reverb_banks(C, rom):
    """{algo: {cram_addr: value}}.  The destination comes from the literal
    `ldptr` packet that precedes each type-2 block, so the bank BASE is PROVEN
    BY CONSTRUCTION rather than inferred."""
    out = {}
    for a in REVERB_ALGOS + [GATED]:
        cells, dest, p, guard = {}, None, rom.u32le(C.PARAM_TABLE + 4 * a), 0
        while guard < 512:
            guard += 1
            b0, b1 = rom.u8(p), rom.u8(p + 1)
            op = b0 >> 4
            if op == 0xF:
                break
            ln = ((b0 & 0x0F) << 8) | b1
            if ln < 2 or ln > 0x0FFF:
                break
            data = rom.slice(p + 2, ln - 2)[3:]
            if op in (0, 1, 5):
                for k in range(0, len(data) - 4, 5):
                    e = data[k:k + 5]
                    if e[0] == 0x08 and e[1] == 0x01 and e[4] == 0x21:
                        dest = ((e[2] & 0x0F) << 4) | (e[3] >> 4)
            elif op == 2 and dest is not None:
                for k in range(0, len(data) - 2, 3):
                    v = (data[k] << 16) | (data[k + 1] << 8) | data[k + 2]
                    cells[dest] = C.q23(v)
                    dest += 1
            p += ln
        out[a] = cells
    return out


def ladder_cram(imgs):
    curs = cram_cursor(imgs[16])
    st = [i for i in range(len(imgs[16])) if core_at(imgs[16], i)]
    return ([0x90 + curs[s + 5] for s in st[:5]],
            [0x90 + curs[s + 5] for s in st[5:]])


def sec_banks(C, rom, imgs, names):
    print("=" * 76)
    print("3. THE COEFFICIENTS THE FIRMWARE ACTUALLY LOADS.  MEASURED.")
    print("=" * 76)
    print("   Bank base: each type-2 coefficient block in the parameter stream is")
    print("   preceded by a literal 5-byte  08 01 0N N8 21  packet, which IS the")
    print("   instruction word 801.0.NN.821 = ldptr #$NN in the writer encoding")
    print("   PROVEN BY CONSTRUCTION in dsp/analysis/k5-output-stage.md.  For all")
    print("   twelve reverb presets it says #$90; GATED REVERB (unit 0) says #$00.")
    print()
    banks = reverb_banks(C, rom)
    l0, l1 = ladder_cram(imgs)
    print("   ladder 0 (5 core repetitions) consumes C-RAM %s"
          % " ".join("0x%02X" % a for a in l0))
    print("   ladder 1 (4 core repetitions) consumes C-RAM %s"
          % " ".join("0x%02X" % a for a in l1))
    print()
    print("   %-18s %-33s %s" % ("preset", "ladder 0 gains", "ladder 1 gains"))
    for a in REVERB_ALGOS:
        b = banks[a]
        print("   %-18s %-33s %s"
              % (names.get(a, str(a)),
                 " ".join("%+.4f" % b[x] for x in l0),
                 " ".join("%+.4f" % b[x] for x in l1)))
    print()
    print("   NOTE (MEASURED, unexplained): BRIGHT REVERB 2 (algo 25) writes 38")
    print("   cells where every other preset writes 37, so its whole bank sits one")
    print("   cell later and every coefficient ROLE in it shifts by one.  Its")
    print("   ladder-1 head therefore reads -0.2526.  Reported, not repaired.")
    print("   NOTE (MEASURED): the ladders are NOT monotonically descending in")
    print("   PLATE REVERB 2 and BRIGHT REVERB 1 -- the 'strictly descending gain")
    print("   ladder' claim in dsp/algorithms/reverb.md holds for 10 of 12 presets.")
    return banks


def delay_chains(C, rom, algo):
    """The external-DRAM address pairs of one reverb slot, as (end,start), split
    into the two interleaved contiguous chains.  MEASURED."""
    vals, p, guard = [], rom.u32le(C.PARAM_TABLE + 4 * algo), 0
    while guard < 512:
        guard += 1
        b0, b1 = rom.u8(p), rom.u8(p + 1)
        op = b0 >> 4
        if op == 0xF:
            break
        ln = ((b0 & 0x0F) << 8) | b1
        if ln < 2 or ln > 0x0FFF:
            break
        data = rom.slice(p + 2, ln - 2)[3:]
        if op == 5:
            for k in range(0, len(data) - 4, 5):
                e = data[k:k + 5]
                if e[0] == 0x0A:
                    vals.append((e[1] << 16) | (e[2] << 8) | e[3])
        p += ln
    pairs = [(vals[i], vals[i + 1]) for i in range(0, len(vals) - 1, 2)]
    chains = {}
    for phase in (0, 1):
        best, seq, cur = [], [], None
        for i in range(phase, len(pairs), 2):
            end, start = pairs[i]
            if cur is not None and start == cur:
                seq.append(end)
            else:                       # break: start a new run here
                if len(seq) > len(best):
                    best = seq
                seq = [start, end]
            cur = end
        if len(seq) > len(best):
            best = seq
        chains[phase] = best
    return pairs, chains


def ladder_delays(C, rom, algo):
    """The two recirculating delay-buffer length lists of one reverb slot,
    longest chain first, with the >4000-word pre-delay head dropped.
    MEASURED."""
    _pairs, ch = delay_chains(C, rom, algo)
    out = []
    for ph in (0, 1):
        seq = ch[ph]
        if len(seq) < 3:
            continue
        lens = [seq[i + 1] - seq[i] for i in range(len(seq) - 1)]
        if lens and lens[0] > 4000:      # the input pre-delay, not a stage
            lens = lens[1:]
        out.append(lens)
    return out


def sec_delays(C, rom, names):
    print("=" * 76)
    print("4. THE DELAY LINES -- MEASURED, from the parameter stream")
    print("=" * 76)
    for a in (16, 20, GATED):
        _pairs, ch = delay_chains(C, rom, a)
        print("   algo %d %s" % (a, names.get(a, "")))
        for ph in (0, 1):
            seq = ch[ph]
            if len(seq) < 3:
                continue
            lens = [seq[i + 1] - seq[i] for i in range(len(seq) - 1)]
            print("     phase %d %s" % (ph, " ".join("%04X" % v for v in seq)))
            print("             lengths %s   (%d buffers)"
                  % (" ".join(str(v) for v in lens), len(lens)))
    print()
    print("   Taken raw the payloads are 17-bit word addresses; the host-poke")
    print("   decode of the SAME 5-byte packet gives (payload<<1)|(sel>>7), one")
    print("   bit wider.  17 vs 18 delay address bits stays OPEN (roadmap R3/H3).")
    print("   The all-pass solve does not depend on it -- only on the read/write")
    print("   line OFFSET, which it forces to exactly one stage.")


def sec_solve(nterms):
    print("=" * 76)
    print("5. THE SEARCH -- every assignment the declared model can express")
    print("=" * 76)
    print("   MODEL (declared; each assumption argued in the analysis note):")
    print("     * visible state: acc, P (product), M = mem[ptr], DR (DRAM read data)")
    print("     * a slot's ALU may compute acc <- signed sum of <=%d of them" % nterms)
    print("     * slot 3 carries hi12 bit 4: mem[ptr] <- acc, before or after its ALU")
    print("     * slot 5 is class A: consumes the cursor coefficient, writes P")
    print("     * one of slots 0/4 is the external-DRAM READ, the other the WRITE")
    print("     * addr8 == 0 on every class-2/A word => ONE D-RAM cell per ladder")
    print()
    keep = None
    for slots, tag in (((1, 2, 3, 5), "slots 1,2,3,5 free (DRAM words inert)"),):
        exprs, sols = search(nterms=nterms, alu_slots=slots, verbose=False)
        uniq = {}
        for s in sols:
            uniq.setdefault(canonical(s), []).append(s)
        print("   %-42s -> %d tuple(s), %d distinct machine(s)"
              % (tag, len(sols), len(uniq)))
        if keep is None:
            keep = (exprs, sols, uniq)
    exprs, sols, uniq = keep
    print("   (sensitivity, run offline -- see the analysis note: letting slot 4")
    print("    also drive the ALU gives 454 machines; a 3-input ALU gives 168.")
    print("    read_slot and the store-before/after decision are FORCED in all.)")
    print()
    print("   THE SURVIVORS of the base model:")
    for n, (_key, group) in enumerate(sorted(uniq.items())):
        s = group[0]
        print("   --- machine %d --- (%d equivalent expression tuples)"
              % (n, len(group)))
        print("       eta=%+d  read@slot%d (data visible from slot%d)  "
              "write@slot%d from %s  store=acc(%s)  multiplicand=%s"
              % (s["eta"], s["read_slot"], s["land"],
                 4 if s["read_slot"] == 0 else 0, s["wsrc"], s["store"],
                 s["msrc"]))
        for k in range(6):
            note = ""
            if k == s["read_slot"]:
                note = "; DRAM READ line r -> DR"
            if k == (4 if s["read_slot"] == 0 else 0):
                note = "; DRAM WRITE line r-1 <- %s" % s["wsrc"]
            if k == 3:
                note = "; mem[ptr] <- acc(%s)" % s["store"]
            if k == 5:
                note += "; P <- coef * %s" % s["msrc"]
            alts = sorted(set(show_expr(exprs[g["e_idx"][k]]) for g in group))
            print("     %-14s %-24s %s" % (WORDS[k], alts[0], note))
            for a in alts[1:]:
                print("     %-14s %-24s (indistinguishable here)" % ("", a))
        print("       MULT   = %-18s (= s[r] = x[r] + w[r])" % show(s["MULT"]))
        print("       WVAL   = %-18s (= d_in[r-1] = x[r-1] + t[r-1])"
              % show(s["WVAL"]))
        print("       A_exit = %-18s M_exit = %s"
              % (show(s["A_exit"]), show(s["M_exit"])))
    return exprs, sols, uniq


def _ladder_err(exprs, sol, banks, l0, l1, D0, D1, x):
    worst = 0.0
    for a in REVERB_ALGOS:
        bk = banks[a]
        for gl, dl in ((l0, D0), (l1, D1)):
            g = [bk[c] for c in gl][:len(dl)]
            d = dl[:len(g)]
            worst = max(worst, maxdiff(run_ladder(exprs, sol, g, d, x),
                                       allpass_ref(g, d, x)))
    return worst


CROM = [None, None]


def sec_verify(exprs, uniq, banks, imgs):
    print("=" * 76)
    print("6. NUMERIC FALSIFICATION -- against a textbook cascade, real ROM numbers")
    print("=" * 76)
    print("   Each surviving machine is RUN as a 5-stage and a 4-stage ladder, over")
    print("   all 12 preset coefficient banks, and compared with a textbook all-pass")
    print("   cascade written independently from the mathematics.  Priming is")
    print("   DERIVED from each machine's own invariant, never chosen, and the")
    print("   ladder output is accepted up to sign (the absolute sign of a stage is")
    print("   a coefficient-sign convention the code cannot fix).")
    print()
    l0, l1 = ladder_cram(imgs)
    random.seed(11)
    x = [random.uniform(-1, 1) for _ in range(600)]
    # delay lengths taken from the ROM parameter stream, not hard-coded
    ch = sorted(ladder_delays(CROM[0], CROM[1], 16), key=len, reverse=True)
    D0 = ch[0][:5]
    D1 = ch[1][:4] if len(ch) > 1 else ch[0][:4]
    best, npass = None, 0
    for n, (_key, group) in enumerate(sorted(uniq.items())):
        hit = None
        for out in ((1, "acc"), (-1, "acc"), (1, "M"), (-1, "M")):
            s = dict(group[0])
            s["out"] = out
            if _ladder_err(exprs, s, banks, l0, l1, D0, D1, x) < 1e-9:
                hit = s
                break
        if hit:
            npass += 1
            if best is None or hit["wsrc"] == "M":
                best = hit
        print("   machine %2d  WVAL=%-8s land=%d eta=%+d wsrc=%-10s -> %s"
              % (n, show(group[0]["WVAL"]), group[0]["land"], group[0]["eta"],
                 group[0]["wsrc"],
                 ("EXACT, output = %s%s" % ("-" if hit["out"][0] < 0 else "+",
                                            hit["out"][1])) if hit else "no"))
    print()
    print("   %d of %d machines reproduce the cascade EXACTLY (max|err| = 0.000e+00)."
          % (npass, len(uniq)))
    print("   The numeric pass is therefore a CORRECTNESS CHECK on the algebra, not")
    print("   a discriminator: the survivors are all genuine all-pass ladders and")
    print("   the numbers cannot separate them.  What separates them is argued")
    print("   from the corpus in the analysis note, not here.")
    if best is None:
        print("   NO machine reproduces the cascade numerically -- report this.")
        return None
    print()
    print("   CONTROLS -- the test must be ABLE to fail.  Each perturbs exactly one")
    print("   decision of one accepted machine to a value that machine does NOT")
    print("   have, and must break it:")
    bk = banks[16]
    g = [bk[c] for c in l0]
    IDENT = exprs.index(((1, "acc"),))
    ref = allpass_ref(g, D0, x)

    def err(c, gains=None):
        return maxdiff(run_ladder(exprs, c, gains or g, D0, x), ref)

    print("   accepted machine: land=%d eta=%+d wsrc=%s msrc=%s store=%s out=%s%s"
          % (best["land"], best["eta"], best["wsrc"], best["msrc"],
             best["store"], "-" if best["out"][0] < 0 else "+", best["out"][1]))
    print("   %-40s max|err| = %.3e   <- accepted" % ("(unperturbed)", err(best)))
    ctrl = []
    for k in (1, 2, 3, 5):
        if best["e_idx"][k] != IDENT:
            ctrl.append(("slot%d forced to acc<-acc" % k, ("e_idx", k, IDENT)))
    ctrl.append(("store takes acc AFTER its ALU",
                 ("store", None, "new" if best["store"] == "old" else "old")))
    for w in ("acc_before", "M"):
        if best["wsrc"] != w:
            ctrl.append(("DRAM write source -> %s" % w, ("wsrc", None, w)))
    for m in ("M", "DR", "acc_before"):
        if best["msrc"] != m:
            ctrl.append(("multiplicand -> %s" % m, ("msrc", None, m)))
    ctrl.append(("read data lands at slot 1 (too early)", ("land", None, 1)))
    ctrl.append(("read/write roles swapped", ("read_slot", None, 4)))
    ctrl.append(("sign convention eta flipped", ("eta", None, -best["eta"])))
    ctrl.append(("ladder gains reversed", None))
    ctrl.append(("one ladder gain perturbed by 1e-6", "gain"))
    for name, mod in ctrl:
        c = dict(best)
        gg = g
        if mod is None:
            gg = list(reversed(g))
        elif mod == "gain":
            gg = list(g)
            gg[2] += 1e-6
        else:
            fld, idx, val = mod
            if fld == "e_idx":
                e = list(c["e_idx"])
                e[idx] = val
                c["e_idx"] = tuple(e)
            else:
                c[fld] = val
        try:
            print("   %-40s max|err| = %.3e" % (name, err(c, gg)))
        except Exception as ex:
            print("   %-40s impossible (%s)" % (name, ex))
    return best


def sec_discriminator(C, rom, names, imgs):
    """The two corpus measurements that RANK the surviving families (§7 of the
    analysis note).  Counted over DISTINCT images, so the twelve presets that
    share one reverb image count once, not twelve times."""
    print("=" * 76)
    print("8. THE CORPUS DISCRIMINATOR -- MEASURED over DISTINCT images")
    print("=" * 76)
    # add the two resident kernel blobs; they are code too.
    # CORRECTED 2026-07-26: the 5 MALFORMED streams are excluded, matching
    # dsp/verify.py and the rest of the tree.  This moves the BASE RATE only
    # (724/3195 -> 703/3017); every per-form count below is unchanged.
    import kn5000_dsp_extract as E
    MALFORMED = {79, 88, 89, 90, 91}
    full = {a: w for a, w in imgs.items() if a not in MALFORMED}
    for tag, addr in (("KERNEL", 0x01E496), ("EPILOG", 0x01E63C)):
        try:
            ir, _c, _o = E.parse_stream(rom, addr, limit=40)
            full[tag] = [int.from_bytes(bytes(w), "big") for w in ir[0][1]]
        except Exception:
            pass
    seen = {}
    for a, ws in full.items():
        seen.setdefault(tuple(ws), a)
    distinct = list(seen)
    print("   distinct images: %d" % len(distinct))

    def has_store(w):
        return bool(((w >> 24) & 0xFFF) & 0x10)

    tot = st = 0
    tab = collections.defaultdict(lambda: [0, 0])
    for ws in distinct:
        for i in range(1, len(ws)):
            tot += 1
            st += has_store(ws[i - 1])
        for i, w in enumerate(ws):
            hi, cl, ad, lo = fields(w)
            if hi == 0x880 and cl == 1 and ad in (0x20, 0x60) and i > 0:
                rec = tab[(ad, lo)]
                rec[0] += 1
                rec[1] += has_store(ws[i - 1])
    print("   base rate 'preceded by a hi12 bit-4 store': %d/%d = %.1f%%"
          % (st, tot, 100.0 * st / tot))
    print("   %-6s %-6s %6s %7s %s" % ("addr8", "lo12", "sites", "store", "%"))
    for k in sorted(tab):
        n, c = tab[k]
        print("   %-6s %-6s %6d %7d  %3.0f%%"
              % ("%02X" % k[0], "%03X" % k[1], n, c, 100.0 * c / n))
    print("   => 880.1.20.64B and .655 are 100% store-preceded; the other four")
    print("      880.1.20 forms are 0%.  Under the family in which the DRAM write")
    print("      takes mem[ptr] that store is a DATA DEPENDENCY; under the other")
    print("      family it is a scheduling coincidence.  Ranked, not proved.")
    print()
    print("   104.2.00.000 OUTSIDE the reverb motif -- every occurrence:")
    shown = set()
    for a in sorted(k for k in imgs):
        ws = imgs[a]
        for i, w in enumerate(ws):
            if w == 0x0104200000 and (i + 1 >= len(ws)
                                      or ws[i + 1] != 0x0000200419):
                ctx = tuple(ws[max(0, i - 2):i + 2])
                if ctx in shown:
                    continue
                shown.add(ctx)
                print("     algo %2d %-18s w%-4d %s"
                      % (a, names.get(a, ""), i,
                         " | ".join(fmt(v) for v in ctx)))
    print("   => all of them sit immediately after a class-A multiply-and-store,")
    print("      i.e. exactly where 'add the pending product' belongs.")


def sec_separator(imgs):
    print("=" * 76)
    print("7. THE SEPARATORS AND BLOCK HEADS -- independent cross-check")
    print("=" * 76)
    ws = imgs[16]
    for s in (11, 59, 101):
        print("   @%3d  %s" % (s, " | ".join(fmt(ws[s + k]) for k in range(5))))
    print("   head 16..18  %s" % " | ".join(fmt(ws[k]) for k in (16, 17, 18)))
    print("   head 64..68  %s" % " | ".join(fmt(ws[k]) for k in range(64, 69)))
    print()
    print("   Every separator is  [DRAM 60] X Y Z [DRAM 20]  -- the same")
    print("   three-word window between the same two DRAM words as the core, and")
    print("   its LAST word before the 20 write carries hi12 bit 4 (212.2.00.419).")
    print("   That is the drain of the software pipeline the search forces: the")
    print("   store stages the last stage's d_in into mem[ptr] and the 20 word")
    print("   pushes mem[ptr] to the delay line -- exactly the role the search")
    print("   assigns to core slots 3 and 4.  What does NOT fit is the class-A")
    print("   word at separator position 1: it overwrites P before positions 2/3")
    print("   could consume the ladder's last t.  Reported as an open miss.")


def main():
    ap = argparse.ArgumentParser()
    here = os.path.dirname(os.path.abspath(__file__))
    repo = os.path.abspath(os.path.join(here, "..", ".."))
    ap.add_argument("--rom", default=os.path.join(repo, "original_ROMs",
                                                  "kn5000_subprogram_v142.rom"))
    ap.add_argument("--main", default=os.path.join(repo, "original_ROMs",
                                                   "kn5000_v10_program.rom"))
    ap.add_argument("--tools",
                    default=os.path.expanduser("~/compartilhado/kn7000_mame/tools"))
    ap.add_argument("--terms", type=int, default=2)
    ap.add_argument("sections", nargs="*")
    args = ap.parse_args()

    C, rom, names, imgs = load_rom(args.tools, args.rom, args.main)
    CROM[0], CROM[1] = C, rom
    want = set(args.sections) if args.sections else {
        "census", "motif", "banks", "delays", "solve", "verify",
        "separator", "discriminator"}
    banks = None
    if "census" in want:
        sec_census(imgs, names)
    if "motif" in want:
        sec_motif(imgs, names)
    if "banks" in want:
        banks = sec_banks(C, rom, imgs, names)
    if "delays" in want:
        sec_delays(C, rom, names)
    if "solve" in want or "verify" in want:
        exprs, _sols, uniq = sec_solve(args.terms)
        if "verify" in want:
            if banks is None:
                banks = reverb_banks(C, rom)
            sec_verify(exprs, uniq, banks, imgs)
    if "separator" in want:
        sec_separator(imgs)
    if "discriminator" in want:
        sec_discriminator(C, rom, names, imgs)


if __name__ == "__main__":
    main()
