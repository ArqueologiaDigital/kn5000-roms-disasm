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
          control action singledelay price adjudicate
          adder   -- section 10 RE-DECIDED under analysis/acc-adder.md's adder.
                     Sub-parts via ADDER_PARTS=gate,control,count,route,search,gardner,
                     forms,price ; one search row via ADDER_ROW=0|1.

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


# ==========================================================================
#  9.  THE SECTION-9 RESTRICTION, TAKEN LITERALLY, INSIDE R1's OWN MODEL
#
#  `notes/dsp-alu-structure.md' sect. 9 observes that the all-pass core's DRAM
#  WRITE (880.1.20.655) and its gain MULTIPLY (102.A.00.64B) carry the SAME
#  lo12 SOURCE code (0x19), and reads that as the signature of a one-multiplier
#  Schroeder all-pass in which the delay input and the multiplicand are ONE
#  value in ONE register.  That is a testable restriction on R1's search and it
#  costs nothing to test: keep only the machines whose WRITTEN VALUE and whose
#  MULTIPLICAND are the same symbolic value.
#
#  The restriction is applied to the SOLUTION SET, not to the search, so that
#  the unrestricted count is printed beside it and the reader can see the price.
# ==========================================================================
def sec_schroeder(nterms):
    print("=" * 76)
    print("9. THE SECT.-9 RESTRICTION TAKEN LITERALLY -- write value == multiplicand")
    print("=" * 76)
    print("   dsp-alu-structure.md sect. 9: `880.1.20.655' (the DRAM write) and")
    print("   `102.A.00.64B' (the gain multiply) carry the SAME lo12 SOURCE 0x19.")
    print("   Slots 4 and 5 are ADJACENT and nothing between them can rewrite that")
    print("   register, so under a literal reading the two words move ONE value.")
    print()
    for tag, slots, terms in (("base: 2-input ALU, DRAM words inert", (1, 2, 3, 5), nterms),
                              ("slot 4 (the DRAM write) may drive the ALU too",
                               (1, 2, 3, 4, 5), nterms),
                              ("3-input ALU, DRAM words inert", (1, 2, 3, 5), 3)):
        exprs, sols = search(nterms=terms, alu_slots=slots, verbose=False)
        uniq, rest = {}, {}
        for s in sols:
            uniq.setdefault(canonical(s), []).append(s)
            if s["WVAL"] == s["MULT"]:
                rest.setdefault(canonical(s), []).append(s)
        print("   %-46s %4d machines -> %d with WVAL == MULT"
              % (tag, len(uniq), len(rest)))
    print()
    print("   THIS IS NOT A SEARCH RESULT, IT IS ALGEBRA, and the search only")
    print("   confirms it.  R1's two acceptance tests are")
    print("       MULT            == eta*D - P + eta*N          (= s[r])")
    print("       substitute(WVAL) == D - eta*P + eta*Q          (= d_in[r])")
    print("   If WVAL == MULT then substitute(MULT) = eta*N - Q + eta*N', which")
    print("   shares no atom with D - eta*P + eta*Q.  The write and the multiply")
    print("   are ONE REPETITION APART in the software pipeline, so one register")
    print("   cannot hold both -- for ANY ALU width and ANY number of registers.")
    print("   => the literal sect.-9 reading is FALSIFIED.  What survives it is in")
    print("      section 10: the shared SOURCE is a shared OPERAND, and only the")
    print("      MULTIPLY consumes it as the multiplicand.")


# ==========================================================================
#  10.  THE ACTION FIELD -- solved INSIDE THE SHIPPED ALU, with lo12 SRC fixed
#
#  Section 9 tested `dsp-alu-structure.md' sect. 9 inside R1's OWN machine model
#  -- four registers (acc, P, mem[ptr], DR), a free two-input ALU per slot and no
#  notion of a routing field.  That model cannot express the thing the
#  observation is about: `lo12' SRC names WHICH REGISTER supplies a word's
#  operand, and tempA / tempB are registers R1 did not have.
#
#  This section re-runs the solve in the model that DOES express it -- the one
#  the biquad forced and that ships in MAME (`upd6383_device::exec_alu()'):
#
#      bus  := SRC[ lo12[10:6] ]                       latched FIRST
#      if hi12 bit 4 :  mem[ptr] <- acc ; acc := 0     store AND clear
#      hi12[3:1]     :  0 -> acc <- P   1 -> acc += P   2 -> acc unchanged
#      lo12[4:0]     :  the ACTION -- the field this section solves
#      if class4 == A :  P := coef[cursor++] * bus
#
#  What is ENUMERATED is the unknown: what ACTION 0x00 (the largest open code in
#  the ISA, 824 corpus words), 0x19 and 0x0B do, plus the model parameters they
#  cannot be separated from -- what SRC 0x00 reads, what the DRAM write takes its
#  data from, which line it targets, when the read lands, whether an ESCAPE word
#  honours lo12, and whether the tempB bus carries the biquad's >>1.
#
#  The acceptance test is R1's: the ladder must reproduce a textbook all-pass
#  cascade with the MEASURED ROM gains and the MEASURED ROM delay lengths.
#  `price' then re-runs the whole search with ONE fixed assumption relaxed at a
#  time, so an empty survivor set is a priced result and not a shrug.
# ==========================================================================

R_ACC, R_P, R_TA, R_TB, R_M, R_DR = range(6)
RNAME = ("acc", "P", "tA", "tB", "M", "DR")

# the anchored SRC map (dsp-alu-applied.md sect. 3.1; 0x0B from
# dsp-alu-structure.md sect. 5, 99/106 sit on the delay-RAM word itself)
SRC_REG = {0x07: R_M, 0x10: R_ACC, 0x19: R_TA, 0x1A: R_TB, 0x0B: R_DR}
SRC_TXT = {0x07: "mem[ptr]", 0x10: "acc", 0x19: "tempA", 0x1A: "tempB",
           0x0B: "dram-rd", 0x00: "(OPEN)"}
SRC0_CANDS = ("zero", "P", "M", "acc", "DR", "tA")

# The declared ACTION effect space.  It CONTAINS the five anchored codes --
# 0x13 = ('', 'tA<-bus'), 0x14 = ('', 'tB<-bus'), 0x07 = ('', 'M<-bus'),
# 0x12/0x15 = ('', '') -- which is the sanity property a semantic space must
# have before it is used to solve for the codes it does not know.
ACC_OPS = ("", "+bus", "-bus", "bus", "bus-acc")
#   "bus-acc" is NOT decoration: R1's family B needs `acc <- DR - P' in one word,
#   and with the accumulator operation living in hi12[3:1] (which only ever ADDS
#   P) a reversed subtract is the only way the ACTION field could supply it.
#   Leaving it out makes the search vacuously empty -- which is how it was found.
CAPS = ("", "tA<-bus", "tB<-bus", "tA<-acc", "tB<-acc", "M<-bus", "M<-acc")
EFFECTS = [(a, c) for a in ACC_OPS for c in CAPS]
WSRCS = ("bus", "acc_before", "acc_after", "M")
LANDS = (0, 1, 2, 7, 8)

(F00, F19, F0B, SRC0, WSRC, WTRAIL, LAND, ESCOP, ESCACT, TBSH,
 NOPI, NOCLR, S1OP, SWAP, ACTFIRST, ORDERM) = range(16)
NOMINAL = dict(escop=0, escact=1, nopi=0, noclr=0, s1op=2, swap=0, actfirst=0,
               order=0)


def mach(f00, f19, f0b, src0, wsrc, wtrail, land, escact=1, tbsh=0,
         escop=0, nopi=0, noclr=0, s1op=2, swap=0, actfirst=0, order=0):
    # `order': 0 = the SEQUENTIAL model of sect. 10 (ACTFIRST then picks which
    # side of hi12[3:1] the ACTION lands on); 1 = THE ADDER (analysis/acc-adder.md
    # sect. 2), in which the ACTION is a SELECTOR on the accumulator's adder
    # inputs rather than a step.  `noclr': 0 = store AND clear (the shipped
    # reading), 1 = store without clearing, 2 = neither store nor clear.
    return (f00, f19, f0b, src0, wsrc, wtrail, land, escop, escact, tbsh,
            nopi, noclr, s1op, swap, actfirst, order)


def eff_str(e):
    a, c = e
    if not a and not c:
        return "-"
    if not a:
        return c
    a = ("acc <- bus" if a == "bus" else "acc <- bus-acc" if a == "bus-acc"
         else "acc %s= bus" % a[0])
    return a if not c else "%s ; %s" % (a, c)


def motif_slots():
    """The 8 motif words, decoded mechanically -- never hand-typed."""
    out = []
    for hi, cl, lo in CORE + [(0x000, 0x2, 0x000), (0x000, 0x2, 0x000)]:
        esc = bool(hi & 0x800)
        out.append(dict(word="%03X.%X.**.%03X" % (hi, cl, lo), esc=esc, cls=cl,
                        src=(lo >> 6) & 0x1F, act=lo & 0x1F,
                        accop=(hi >> 1) & 7, store=bool(hi & 0x10),
                        dram=(None if not (esc and cl == 1)
                              else "rd" if lo == 0x2D4 else "wr")))
    return out


MSLOTS = motif_slots()
#  ★ `s1op' is a relaxation of ONE WORD OF THE REVERB MOTIF -- slot 1's
#  `104.2.**.000'.  `exec_rep' selected it by POSITION (`s == 1'), so it leaked
#  into every context that swaps MSLOTS out: SINGLE DELAY's slot 1 is
#  `202.A.B8.655' (accop = 1) and was being executed with accop = 2 instead.
#  Identity against the motif is what makes the relaxation mean what it says.
MOTIF_MSLOTS = MSLOTS


EXTRA_ACT = {}          # control-only ACTION codes; empty for every real run


def act_effect(m, act):
    if act in EXTRA_ACT:
        return EXTRA_ACT[act]
    if act in (0x12, 0x15):
        return ("", "")
    if act == 0x13:
        return ("", "tA<-bus")
    if act == 0x14:
        return ("", "tB<-bus")
    if act == 0x07:
        return ("", "M<-bus")
    return EFFECTS[m[{0x00: F00, 0x19: F19, 0x0B: F0B}[act]]]


class NumAlg(object):
    """floats -- the numeric ladder run."""
    zero = 0.0
    add = staticmethod(lambda a, b: a + b)
    sub = staticmethod(lambda a, b: a - b)
    half = staticmethod(lambda a: a * 0.5)
    prod = staticmethod(lambda g, v: g * v)


NATOM = 10
XA, PA, MA, DA, TAA, TBA, NA, QA, NA2, QA2 = range(NATOM)
ANAME = ("A", "P", "M", "D", "TA", "TB", "N", "Q", "N'", "Q'")
ENT_ATOM = (XA, PA, TAA, TBA, MA, DA)          # register k -> its entry atom


def _sym_unit(a):
    u = [0.0] * NATOM
    u[a] = 1.0
    return tuple(u)


def show_form(f):
    return "".join(("+" if v > 0 else "-") +
                   (ANAME[i] if abs(abs(v) - 1) < 1e-9
                    else "%g*%s" % (abs(v), ANAME[i]))
                   for i, v in enumerate(f) if abs(v) > 1e-12).lstrip("+") or "0"


class SymAlg(object):
    """linear forms over the entry / fresh atoms -- the structural filters."""
    zero = (0.0,) * NATOM
    add = staticmethod(lambda a, b: tuple(x + y for x, y in zip(a, b)))
    sub = staticmethod(lambda a, b: tuple(x - y for x, y in zip(a, b)))
    half = staticmethod(lambda a: tuple(0.5 * x for x in a))
    # the multiplier's OUTPUT is the fresh product ATOM: the search never uses a
    # coefficient VALUE, exactly as R1's did not.
    prod = staticmethod(lambda _g, _v: _sym_unit(QA))


def exec_rep(m, st, alg, coef, lines, r, K, pending, base, trace=None):
    """ONE 8-slot repetition.  A single implementation, shared by the symbolic
    filters and the numeric ladder, so the two cannot drift."""
    src0 = m[SRC0]
    for s in range(len(MSLOTS)):
        sl = MSLOTS[s]
        if s >= 6 and m[NOPI] and MSLOTS is MOTIF_MSLOTS:
            continue                       # relaxation: the two nops are inert
        tick = base + s
        if sl["dram"] == "rd" and m[LAND] < 0:
            # land = -1: a BLOCKING read -- the read word's OWN bus already sees
            # the returned word.  SINGLE DELAY needs it; R1's model excluded it
            # by construction (its test 2 demanded the data land inside DR).
            if lines is None:
                st[R_DR] = _sym_unit(NA)
            elif 0 <= r < K:
                st[R_DR] = lines[r].read()
        while pending and pending[0][0] <= tick:
            st[R_DR] = pending.pop(0)[1]
        # ---- the operand bus, latched before anything else ----------------
        sc = sl["src"]
        if sc == 0x00:
            bus = (alg.zero if src0 == "zero" else
                   st[{"P": R_P, "M": R_M, "acc": R_ACC,
                       "DR": R_DR, "tA": R_TA}[src0]])
        else:
            reg = SRC_REG[sc]
            bus = st[reg]
            if reg == R_TB and m[TBSH]:
                bus = alg.half(bus)
        acc_before = st[R_ACC]
        # ---- hi12 bit 4: store the accumulator to mem[ptr] AND clear it ----
        if sl["store"]:
            if m[NOCLR] != 2:
                st[R_M] = st[R_ACC]
            if not m[NOCLR]:
                st[R_ACC] = alg.zero
        aop, cap = act_effect(m, sl["act"])

        def do_capture():
            if cap:
                st[{"tA": R_TA, "tB": R_TB, "M": R_M}[cap.split("<-")[0]]] = \
                    bus if cap.endswith("bus") else st[R_ACC]

        def do_action():
            if aop == "+bus":
                st[R_ACC] = alg.add(st[R_ACC], bus)
            elif aop == "-bus":
                st[R_ACC] = alg.sub(st[R_ACC], bus)
            elif aop == "bus":
                st[R_ACC] = bus
            elif aop == "bus-acc":
                st[R_ACC] = alg.sub(bus, st[R_ACC])
            do_capture()

        honour = (not sl["esc"]) or m[ESCACT]
        if m[ORDERM]:
            # ---- ★ THE ADDER  (analysis/acc-adder.md sect. 2) ------------
            #   acc <- FB + P_TERM + BUS_TERM,  where the ACTION selects which
            #   inputs are enabled instead of being a step applied before or
            #   after hi12[3:1].  This is `order = adder' of acc_adjudicate.py,
            #   transcribed term for term; the two tools must not drift.
            #   An ESCAPE word with escop = 0 holds the accumulator, i.e. it
            #   behaves as hi12[3:1] == 2 -- the adder's own way of spelling
            #   "the operation is skipped", and identical to the sequential
            #   model on every word whose ACTION has no accumulator half.
            op = (m[S1OP] if (s == 1 and MSLOTS is MOTIF_MSLOTS)
                  else sl["accop"])
            if sl["esc"] and not m[ESCOP]:
                op = 2
            fb = alg.zero if op in (0, 3) else st[R_ACC]
            pt = alg.zero if op in (2, 3) else st[R_P]
            bt = alg.zero
            if honour:
                if aop == "+bus":
                    bt = bus
                elif aop == "-bus":
                    bt = alg.sub(alg.zero, bus)
                elif aop == "bus":          # `load'  -- the bus REPLACES FB
                    fb, bt = bus, alg.zero
                elif aop == "bus-acc":      # `rload' -- FB enters negated
                    fb, bt = alg.sub(alg.zero, fb), bus
            st[R_ACC] = alg.add(alg.add(fb, pt), bt)
            if honour:
                do_capture()
        else:
            if honour and m[ACTFIRST]:
                do_action()
            # ---- hi12[3:1]: the accumulator operation ---------------------
            op = (m[S1OP] if (s == 1 and MSLOTS is MOTIF_MSLOTS)
                  else sl["accop"])
            if (not sl["esc"]) or m[ESCOP]:
                if op == 0:
                    st[R_ACC] = st[R_P]
                elif op == 1:
                    st[R_ACC] = alg.add(st[R_ACC], st[R_P])
                elif op == 3:
                    st[R_ACC] = alg.zero
            if honour and not m[ACTFIRST]:
                do_action()
        # ---- class A: the coefficient fetch and the multiply ---------------
        if sl["cls"] == 0xA:
            if trace is not None:
                trace["MULT"] = bus
            if coef is not None:
                st[R_P] = alg.prod(coef, bus)
        # ---- the external delay-DRAM access -------------------------------
        dram = sl["dram"]
        if dram and m[SWAP]:
            dram = "wr" if dram == "rd" else "rd"
        if dram == "rd" and m[LAND] >= 0:
            if lines is None:
                pending.append((tick + m[LAND], _sym_unit(NA)))
            elif 0 <= r < K:
                pending.append((tick + m[LAND], lines[r].read()))
        elif dram == "wr":
            val = (bus if m[WSRC] == "bus" else
                   acc_before if m[WSRC] == "acc_before" else
                   st[R_ACC] if m[WSRC] == "acc_after" else st[R_M])
            if trace is not None:
                trace["W"] = (bus, acc_before, st[R_ACC], st[R_M])
            k = r - m[WTRAIL]
            if lines is not None and 0 <= k < K:
                lines[k].write(val)
    return st


def sym_rep(m):
    """One repetition from fresh entry atoms; returns (exits, trace)."""
    st = [_sym_unit(a) for a in ENT_ATOM]
    tr, pend = {}, []
    # coef = 1.0 is a MARKER: SymAlg.prod ignores the value and writes the fresh
    # product ATOM, so P really does become Q inside the repetition.
    exec_rep(m, st, SymAlg, 1.0, None, 0, 1, pend, 0, tr)
    while pend:
        st[R_DR] = pend.pop(0)[1]
    return st, tr


def advance(form, ex):
    """Advance a form by one repetition: every entry atom -> this repetition's
    exit form for that register, N -> N', Q -> Q'."""
    out = [0.0] * NATOM
    for i, c in enumerate(form):
        if not c:
            continue
        if i == NA:
            out[NA2] += c
        elif i == QA:
            out[QA2] += c
        elif i in (NA2, QA2):
            return None
        else:
            for j, cc in enumerate(ex[ENT_ATOM.index(i)]):
                out[j] += c * cc
    return tuple(out)


def loop_ok(m):
    """The DELAY-LOOP filter.  Returns the DRAM-write data sources that pass.

    A first-order all-pass stage has denominator (1 - g z^-D) EXACTLY, so around
    delay line k there is one and only one feedback path and it goes through the
    multiply.  With the write trailing the read by one repetition that says:

      C1  the class-A word's bus (the multiplicand) carries the FRESH read with
          coefficient +-1                      -- w_k reaches the multiplier;
      C2  the value written one repetition later carries that product with
          coefficient +-1                      -- g_k w_k reaches the line;
      C3  and carries NO DIRECT copy of the fresh read -- an unmultiplied path
          from w_k back to d_k would put the pole on the unit circle.

    All three are properties of the FILTER, not of the ALU model, so they stay
    valid under every relaxation `price' applies.
    """
    st, tr = sym_rep(m)
    if "MULT" not in tr or "W" not in tr:
        return []
    if abs(abs(tr["MULT"][NA]) - 1.0) > 1e-9:
        return []
    out = []
    for i, wv in enumerate(tr["W"]):
        nx = advance(wv, st)
        if nx is None or abs(abs(nx[QA]) - 1.0) > 1e-9 or abs(nx[NA]) > 1e-9:
            continue
        out.append(WSRCS[i])
    return out


def run_ladder_action(m, gains, delays, x, inj):
    """Run the ladder as the microcode does: K core repetitions per sample, one
    delay line per repetition, plus a drain repetition.  The registers are zeroed
    and the ladder input injected into `inj' at the top -- the two words
    IMMEDIATELY before Ladder0 (`0000A0A1D5 ld (p),c+' then `0202200000') leave
    a sum in the ACCUMULATOR, which is why acc is one of the injections; all six
    are tried.  Returns the exit value of EVERY register for every sample, so the
    extraction point is enumerated rather than chosen."""
    K = len(gains)
    lines = [Line(d) for d in delays]
    out = [[] for _ in range(6)]
    for xn in x:
        st = [0.0] * 6
        st[inj] = xn
        pend = []
        for r in range(K + 1):
            exec_rep(m, st, NumAlg, gains[r] if r < K else None,
                     lines, r, K, pend, r * 8)
        for k in range(6):
            out[k].append(st[k])
        for ln in lines:
            ln.advance()
    return out


def machine_matches(m, gains, delays, x, refs, tol=1e-7, first=False):
    """Every (injection, extraction, sign-of-g, scale) that reproduces one of the
    reference cascades.  An arbitrary non-zero SCALE is accepted, not just a
    sign: a constant factor anywhere in the loop is a coefficient convention, and
    refusing it would reject a correct machine for a reason the ROM cannot fix."""
    hits = []
    for inj in range(6):
        outs = run_ladder_action(m, gains, delays, x, inj)
        for ext in range(6):
            o = outs[ext]
            den = sum(v * v for v in o)
            if den < 1e-18:
                continue
            for ng, ref in enumerate(refs):
                sc = sum(a * b for a, b in zip(o, ref)) / den
                if abs(sc) < 1e-6:
                    continue
                mx = max(abs(v) for v in ref)
                if max(abs(sc * a - b) for a, b in zip(o, ref)) < tol * mx:
                    hits.append((inj, ext, ng, sc))
                    if first:
                        return hits
    return hits


def _ladder_inputs(C, rom, imgs):
    banks = reverb_banks(C, rom)
    l0, l1 = ladder_cram(imgs)
    ch = sorted(ladder_delays(C, rom, 16), key=len, reverse=True)
    return banks, l0, l1, ch[0][:5], (ch[1][:4] if len(ch) > 1 else ch[0][:4])


def mult_can_be_s(base=None, ranges=None):
    """How many parameter settings put BOTH delay reads into the multiplicand?

    The all-pass multiplicand is  s[r] = x[r] + w[r] = (D - eta*P) + N, so it must
    contain the PREVIOUS read D and the FRESH read N at once.  This counts the
    settings that even COULD -- the exhaustive form of the obstruction, and it
    needs no numeric run at all.

    TWO counts are returned, because the first one asks a NARROWER question than
    its headline suggests:

      n_ND   the multiplicand's ONE-REPETITION form carries atom D, i.e. the
             previous read as it survives IN THE DRAM READ-DATA REGISTER.  This
             is what the note published as "BOTH reads 0 / 5 145 000".
      n_NDa  the ROUTE-AGNOSTIC form: advance the multiplicand by one repetition
             (`advance', the same fixpoint substitution the delay-loop filter
             uses) and ask whether it carries the fresh read N' AND the previous
             read N by ANY route -- through tempA, tempB, mem[ptr] or the
             accumulator as well as through DR.  A machine that carries the
             previous read forward in tempA is invisible to n_ND and visible
             here.  `ranges' restricts the three unknown ACTION codes to a
             sub-space (sequences of EFFECTS indices), which is how the STRICT
             adder -- only ACTION 0x00 may route the bus -- is expressed."""
    base = base or {}
    n_all = n_N = n_ND = n_NDa = 0
    NE = len(EFFECTS)
    r00, r19, r0b = ranges or (range(NE), range(NE), range(NE))
    for i00 in r00:
        for i19 in r19:
            for i0b in r0b:
                for s0 in SRC0_CANDS:
                    for ld in LANDS:
                        for ea in ((0, 1) if "escact" not in base
                                   else (base["escact"],)):
                            for sh in (0, 1):
                                k = dict(base)
                                k.pop("escact", None)
                                _st, tr = sym_rep(mach(i00, i19, i0b, s0, None,
                                                       1, ld, ea, sh, **k))
                                n_all += 1
                                if "MULT" not in tr:
                                    continue
                                hN = abs(tr["MULT"][NA]) > 1e-12
                                hD = abs(tr["MULT"][DA]) > 1e-12
                                n_N += hN
                                n_ND += (hN and hD)
                                adv = advance(tr["MULT"], _st)
                                if (adv is not None and abs(adv[NA2]) > 1e-12
                                        and abs(adv[NA]) > 1e-12):
                                    n_NDa += 1
    return n_all, n_N, n_ND, n_NDa


def action_search(banks, l0, D0, base=None, quiet=False, ranges=None,
                  numeric=True, lands=None):
    """The whole pipeline for ONE set of fixed assumptions.  Returns
    (n_enumerated, loop survivors, numeric survivors).

    ★ `lands' EXISTS BECAUSE THE DEFAULT IS NOT NEUTRAL.  `LANDS' omits the
    BLOCKING read (`land = -1'), which is the read model SINGLE DELAY FORCES
    (5145/5145, action-field.md sect. 8) -- so the reverb and SINGLE DELAY were
    being solved under DIFFERENT read models, and that asymmetry is what made
    `SRC 0x00 = DR' look forced here.  Passing it explicitly makes the choice
    visible instead of inherited.  Callers that pass nothing keep the published
    space exactly."""
    base = base or {}
    g2 = [banks[16][c] for c in l0][:2]
    random.seed(7)
    xs = [random.uniform(-1, 1) for _ in range(32)]
    refs = [allpass_ref(g2, [3, 5], xs), allpass_ref([-v for v in g2], [3, 5], xs)]
    tot, sl = 0, []
    NE = len(EFFECTS)
    r00, r19, r0b = ranges or (range(NE), range(NE), range(NE))
    for i00 in r00:
        for i19 in r19:
            for i0b in r0b:
                for s0 in SRC0_CANDS:
                    for ld in (LANDS if lands is None else lands):
                        for ea in ((0, 1) if "escact" not in base
                                   else (base["escact"],)):
                            for sh in (0, 1):
                                tot += len(WSRCS)
                                k = dict(base)
                                k.pop("escact", None)
                                for w in loop_ok(mach(i00, i19, i0b, s0, None,
                                                      1, ld, ea, sh, **k)):
                                    sl.append(mach(i00, i19, i0b, s0, w, 1, ld,
                                                   ea, sh, **k))
    if not numeric:
        return tot, sl, None          # structural stage only -- the diagnostics
    num = [(m, machine_matches(m, g2, [3, 5], xs, refs, first=True))
           for m in sl]
    num = [(m, h) for m, h in num if h]
    if not quiet:
        print("     %-9d enumerated  %-8d pass the delay-loop filter  %d "
              "reproduce a 2-stage cascade" % (tot, len(sl), len(num)))
    return tot, sl, num


def sec_action(C, rom, imgs, names):
    print("=" * 76)
    print("10. THE lo12 ACTION FIELD -- solved in the SHIPPED ALU, SRC fixed")
    print("=" * 76)
    print("   the motif as the DECODER reads it -- MEASURED:")
    for sl in MSLOTS:
        print("     %-16s %-4s src=%02X %-9s act=%02X  accop=%d%s%s"
              % (sl["word"], "ESC" if sl["esc"] else "", sl["src"],
                 SRC_TXT[sl["src"]], sl["act"], sl["accop"],
                 " ST" if sl["store"] else "",
                 (" DRAM-" + sl["dram"].upper()) if sl["dram"] else ""))
    print()
    print("   The DRAM WRITE (slot 4) and the MULTIPLY (slot 5) carry the SAME")
    print("   SRC 0x19 and nothing between them can rewrite it -- the observation")
    print("   sect. 9 is built on -- and here it is a MEASURED input, not a")
    print("   hypothesis: both words simply read tempA.")
    print()
    banks, l0, l1, D0, D1 = _ladder_inputs(C, rom, imgs)
    print("   THE SHIPPED MODEL, nothing relaxed:")
    tot, sl, num = action_search(banks, l0, D0)
    if sl:
        for nm, ix in (("SRC 0x00 reads", SRC0), ("read lands +n slots", LAND),
                       ("ACTION 0x19", F19)):
            v = collections.Counter(
                (eff_str(EFFECTS[m[ix]]) if ix in (F00, F19, F0B) else m[ix])
                for m in sl)
            print("       %-22s %s" % (nm, "  ".join("%s x%d" % (a, b)
                                                     for a, b in v.most_common(4))))
    return num



# --- THE POSITIVE CONTROL -------------------------------------------------
#  A search that cannot succeed proves nothing.  This builds an 8-slot program
#  that IS a Gardner one-multiplier all-pass ladder, expressed with the SAME
#  executor, the same delay lines, the same reference and the same matcher, and
#  checks that the harness accepts it.  It deliberately uses SRC codes the real
#  motif does not have: the point is to test the HARNESS, not the ISA reading.
CONTROL_SLOTS = [
    dict(word="ctl0 read",  esc=True,  cls=1, src=0x0B, act=0x15, accop=2,
         store=False, dram="rd"),
    dict(word="ctl1",       esc=False, cls=2, src=0x1A, act=0x00, accop=2,
         store=False, dram=None),          # acc <- tB          = w[r-1]
    dict(word="ctl2",       esc=False, cls=2, src=0x00, act=0x19, accop=2,
         store=False, dram=None),          # acc -= P           = x[r]
    dict(word="ctl3",       esc=False, cls=2, src=0x0B, act=0x0B, accop=2,
         store=True,  dram=None),          # M <- x[r] ; acc += w[r] ; tB <- w[r]
    dict(word="ctl4 write", esc=True,  cls=1, src=0x19, act=0x15, accop=2,
         store=False, dram="wr"),          # line r-1 <- tA = d_in[r-1]
    dict(word="ctl5 mult",  esc=False, cls=0xA, src=0x10, act=0x15, accop=2,
         store=False, dram=None),          # P <- g * acc = g * s[r]
    dict(word="ctl6",       esc=False, cls=2, src=0x07, act=0x01, accop=0,
         store=False, dram=None),          # acc <- P + M = t[r] + x[r]
    dict(word="ctl7",       esc=False, cls=2, src=0x10, act=0x02, accop=2,
         store=False, dram=None)]          # tA <- acc = d_in[r]


def sec_control(C, rom, imgs, names, order=0):
    global MSLOTS, EXTRA_ACT
    print("=" * 76)
    print("10a. POSITIVE CONTROL -- the harness must be able to SAY YES%s"
          % ("   [ORDER = ADDER]" if order else ""))
    print("=" * 76)
    banks, l0, l1, D0, D1 = _ladder_inputs(C, rom, imgs)
    g = [banks[16][c] for c in l0]
    random.seed(7)
    xs = [random.uniform(-1, 1) for _ in range(64)]
    save_slots, save_extra = MSLOTS, EXTRA_ACT
    MSLOTS = CONTROL_SLOTS
    EXTRA_ACT = {0x01: ("+bus", ""), 0x02: ("", "tA<-bus")}
    m = mach(EFFECTS.index(("bus", "")), EFFECTS.index(("-bus", "")),
             EFFECTS.index(("+bus", "tB<-bus")), "P", "bus", 1, 0,
             escact=0, noclr=1, order=order)
    ok = []
    for nst in (2, 4, 5):
        refs = [allpass_ref(g[:nst], D0[:nst], xs)]
        h = machine_matches(m, g[:nst], D0[:nst], xs, refs)
        ok.append((nst, h))
        print("   %d-stage ladder, ROM gains %s: %s"
              % (nst, " ".join("%.2f" % v for v in g[:nst]),
                 ("MATCH  inject=%s extract=%s scale=%+.3f"
                  % (RNAME[h[0][0]], RNAME[h[0][1]], h[0][3])) if h else "NO"))
    print("   loop filter on the control: %s" % (loop_ok(m) or "REJECTED"))
    MSLOTS, EXTRA_ACT = save_slots, save_extra
    print()
    print("   The harness therefore CAN accept a correct machine, and the delay-")
    print("   loop filter passes it.  An empty survivor set in section 10 is a")
    print("   statement about the MODEL, not about the harness.")
    return all(h for _n, h in ok)



# --- SECOND CONTEXT: SINGLE DELAY -----------------------------------------
#  The all-pass core is not the only place ACTION 0x00 / 0x19 / 0x0B occur.
#  SINGLE DELAY (algo 9) carries all three in a FIVE-word block that needs no
#  pipelining argument at all, and whose algorithm is not in doubt: a delay line
#  with feedback,  v[n] = x[n] + fb * v[n-D].  Solving the same three codes in
#  that block is a genuine cross-check -- it can agree with the reverb, disagree
#  with it, or come out empty, and each of those is a different result.
def sd_slots(imgs, first=True):
    ws = imgs[9][5:10] if first else imgs[9][28:33]
    out = []
    for w in ws:
        hi, cl, _a, lo = fields(w)
        esc = bool(hi & 0x800)
        out.append(dict(word=fmt(w), esc=esc, cls=cl, src=(lo >> 6) & 0x1F,
                        act=lo & 0x1F, accop=(hi >> 1) & 7,
                        store=bool(hi & 0x10),
                        dram=(None if not (esc and cl == 1)
                              else "rd" if (w >> 12) & 0xFF == 0x60 else "wr")))
    return out


def comb_ref(fb, D, x):
    """v[n] = x[n] + fb * v[n-D] -- the textbook feedback delay, written from the
    mathematics."""
    line = Line(D)
    out = []
    for xn in x:
        v = xn + fb * line.read()
        line.write(v)
        out.append(v)
        line.advance()
    return out


def sec_singledelay(C, rom, imgs, names):
    print("=" * 76)
    print("10b. SECOND CONTEXT -- SINGLE DELAY (algo 9), the same three codes")
    print("=" * 76)
    slots = sd_slots(imgs)
    for sl in slots:
        print("     %-16s %-4s src=%02X %-9s act=%02X  accop=%d%s%s"
              % (sl["word"], "ESC" if sl["esc"] else "", sl["src"],
                 SRC_TXT.get(sl["src"], "?"), sl["act"], sl["accop"],
                 " ST" if sl["store"] else "",
                 (" DRAM-" + sl["dram"].upper()) if sl["dram"] else ""))
    random.seed(3)
    x = [random.uniform(-1, 1) for _ in range(22)]
    fb, D = 0.3, 7
    ref = comb_ref(fb, D, x)
    hits = []
    save = globals()["MSLOTS"]
    globals()["MSLOTS"] = slots
    try:
        for i00 in range(len(EFFECTS)):
            for i19 in range(len(EFFECTS)):
                for i0b in range(len(EFFECTS)):
                    for s0 in SRC0_CANDS:
                        for ld in (-1, 0, 1, 2):
                            for inj in range(6):
                                m = mach(i00, i19, i0b, s0, "bus", 0, ld)
                                w = sd_line_values(m, fb, D, x, inj)
                                if w is None:
                                    continue
                                den = sum(v * v for v in w)
                                if den < 1e-18:
                                    continue
                                sc = sum(a * b for a, b in zip(w, ref)) / den
                                if abs(sc) < 1e-6:
                                    continue
                                mx = max(abs(v) for v in ref)
                                if max(abs(sc * a - b)
                                       for a, b in zip(w, ref)) < 1e-7 * mx:
                                    hits.append((m, inj, sc))
    finally:
        globals()["MSLOTS"] = save
    print()
    print("   %d assignments make the block  v[n] = x[n] + fb*v[n-D]  exactly"
          % len(hits))
    for nm, ix in (("ACTION 0x00", F00), ("ACTION 0x19", F19),
                   ("ACTION 0x0B", F0B), ("SRC 0x00 reads", SRC0),
                   ("read lands +n", LAND)):
        v = collections.Counter(
            (eff_str(EFFECTS[m[ix]]) if ix in (F00, F19, F0B) else m[ix])
            for m, _i, _s in hits)
        print("     %-16s %-8s %s"
              % (nm, "FORCED" if len(v) == 1 else "%d values" % len(v),
                 "  ".join("%s x%d" % (a, b) for a, b in v.most_common(6))))
    v = collections.Counter(RNAME[i] for _m, i, _s in hits)
    print("     %-16s %s" % ("x arrives in",
                             "  ".join("%s x%d" % (a, b) for a, b in v.most_common())))
    # A field is FORCED when every survivor agrees; a code's two HALVES can be
    # forced separately, so project them rather than only counting whole effects.
    print()
    print("   PROJECTED ONTO THE TWO HALVES OF AN ACTION -- what is really forced:")
    for nm, ix in (("ACTION 0x00", F00), ("ACTION 0x19", F19),
                   ("ACTION 0x0B", F0B)):
        for half, sel in (("acc op ", 0), ("capture", 1)):
            v = collections.Counter(EFFECTS[m[ix]][sel] or "-"
                                    for m, _i, _s in hits)
            print("     %-11s %-8s %-8s %s"
                  % (nm, half, "FORCED" if len(v) == 1 else "%d" % len(v),
                     "  ".join("%s x%d" % (a, b) for a, b in v.most_common())))
    v = collections.Counter(EFFECTS[m[F19]][1].split("<-")[0]
                            for m, _i, _s in hits if EFFECTS[m[F19]][1])
    print("     ACTION 0x19 captures into: %s   (of %d survivors, %d capture)"
          % ("  ".join("%s x%d" % (a, b) for a, b in v.most_common()),
             len(hits), sum(v.values())))
    return hits


class RecLine(Line):
    """a delay line that records what was written to it"""
    __slots__ = ("wrote",)

    def __init__(self, n):
        Line.__init__(self, n)
        self.wrote = []

    def write(self, v):
        Line.write(self, v)
        self.wrote.append(v)


def sd_line_values(m, fb, D, x, inj):
    """The sequence of values the block WRITES to its delay line."""
    line = RecLine(D)
    for xn in x:
        st = [0.0] * 6
        st[inj] = xn
        exec_rep(m, st, NumAlg, fb, [line], 0, 1, [], 0)
        line.advance()
    return line.wrote if len(line.wrote) == len(x) else None


def sec_adjudicate(C, rom, imgs, names):
    """★ THE ORDER ADJUDICATION.

    `sec_singledelay' calls mach(...) WITHOUT an `actfirst' argument, so its
    5 145 survivors were all computed at the NOMINAL ordering `actfirst = 0'
    (the ACTION acts AFTER the hi12[3:1] operation) -- which is what the shipped
    exec_alu() does.  TARGET 3's LFO pass independently FORCES the OPPOSITE
    ordering, `act_first', as a singleton marginal over 432 machines and 29
    blocks.  The two determinations were therefore reached in models that
    disagree about the one thing neither of them enumerated jointly.

    So: run the SINGLE DELAY search with the ordering ENUMERATED, and report the
    ACTION-0x00 marginal SEPARATELY for each order.  Whatever survives at
    `actfirst = 1' is the only reading that can satisfy both contexts at once.
    """
    print("=" * 76)
    print("12. ★ ADJUDICATION -- SINGLE DELAY with the ACTION/OPERATION ORDER"
          " enumerated")
    print("=" * 76)
    slots = sd_slots(imgs)
    for sl in slots:
        print("     %-16s %-4s src=%02X %-9s act=%02X  accop=%d%s%s"
              % (sl["word"], "ESC" if sl["esc"] else "", sl["src"],
                 SRC_TXT.get(sl["src"], "?"), sl["act"], sl["accop"],
                 " ST" if sl["store"] else "",
                 (" DRAM-" + sl["dram"].upper()) if sl["dram"] else ""))
    random.seed(3)
    x = [random.uniform(-1, 1) for _ in range(22)]
    fb, D = 0.3, 7
    ref = comb_ref(fb, D, x)
    save = globals()["MSLOTS"]
    globals()["MSLOTS"] = slots
    by_order = {0: [], 1: []}
    try:
        for af in (0, 1):
            for i00 in range(len(EFFECTS)):
                for i19 in range(len(EFFECTS)):
                    for i0b in range(len(EFFECTS)):
                        for s0 in SRC0_CANDS:
                            for ld in (-1, 0, 1, 2):
                                for inj in range(6):
                                    m = mach(i00, i19, i0b, s0, "bus", 0, ld,
                                             actfirst=af)
                                    w = sd_line_values(m, fb, D, x, inj)
                                    if w is None:
                                        continue
                                    den = sum(v * v for v in w)
                                    if den < 1e-18:
                                        continue
                                    sc = sum(a * b for a, b in zip(w, ref)) / den
                                    if abs(sc) < 1e-6:
                                        continue
                                    mx = max(abs(v) for v in ref)
                                    if max(abs(sc * a - b)
                                           for a, b in zip(w, ref)) < 1e-7 * mx:
                                        by_order[af].append((m, inj, sc))
    finally:
        globals()["MSLOTS"] = save

    for af in (0, 1):
        hits = by_order[af]
        print()
        print("   ---- actfirst = %d  (%s) : %d survivors"
              % (af, "ACTION before the hi12[3:1] operation" if af else
                 "ACTION after -- the SHIPPED order", len(hits)))
        if not hits:
            print("        NOTHING SURVIVES.")
            continue
        for nm, ix in (("ACTION 0x00", F00), ("ACTION 0x19", F19),
                       ("ACTION 0x0B", F0B), ("SRC 0x00 reads", SRC0),
                       ("read lands +n", LAND)):
            v = collections.Counter(
                (eff_str(EFFECTS[m[ix]]) if ix in (F00, F19, F0B) else m[ix])
                for m, _i, _s in hits)
            print("        %-16s %-8s %s"
                  % (nm, "FORCED" if len(v) == 1 else "%d values" % len(v),
                     "  ".join("%s x%d" % (a, b) for a, b in v.most_common(6))))
        for nm, ix in (("ACTION 0x00", F00), ("ACTION 0x19", F19)):
            for half, sel in (("acc op ", 0), ("capture", 1)):
                v = collections.Counter(EFFECTS[m[ix]][sel] or "-"
                                        for m, _i, _s in hits)
                print("        %-11s %-8s %-8s %s"
                      % (nm, half, "FORCED" if len(v) == 1 else "%d" % len(v),
                         "  ".join("%s x%d" % (a, b) for a, b in v.most_common())))

    # ---- the joint question, asked directly ------------------------------
    print()
    print("   ★ THE JOINT READING -- what SINGLE DELAY allows at the LFO's order")
    lfo = [(m, i, s) for m, i, s in by_order[1]
           if EFFECTS[m[F00]][0] == "bus"]
    print("        actfirst=1 AND ACTION 0x00 acc-half == `acc <- bus' :"
          " %d survivors" % len(lfo))
    if lfo:
        for nm, ix in (("ACTION 0x00 capture", F00), ("ACTION 0x19", F19),
                       ("SRC 0x00 reads", SRC0), ("read lands +n", LAND)):
            v = collections.Counter(
                (EFFECTS[m[ix]][1] or "-") if ix == F00 else
                (eff_str(EFFECTS[m[ix]]) if ix == F19 else m[ix])
                for m, _i, _s in lfo)
            print("        %-20s %-8s %s"
                  % (nm, "FORCED" if len(v) == 1 else "%d values" % len(v),
                     "  ".join("%s x%d" % (a, b) for a, b in v.most_common(6))))
        v = collections.Counter(EFFECTS[m[F19]][1].split("<-")[0]
                                for m, _i, _s in lfo if EFFECTS[m[F19]][1])
        print("        ACTION 0x19 captures into: %s  (%d of %d capture)"
              % ("  ".join("%s x%d" % (a, b) for a, b in v.most_common()),
                 sum(v.values()), len(lfo)))
        v = collections.Counter(EFFECTS[m[F19]][1] or "-" for m, _i, _s in lfo)
        print("        ACTION 0x19 capture forms: %s"
              % "  ".join("%s x%d" % (a, b) for a, b in v.most_common()))
    return by_order


def sec_price(C, rom, imgs, names):
    """One fixed assumption relaxed at a time.  ~1 min per row."""
    print("=" * 76)
    print("11. THE PRICE LIST -- one FIXED assumption relaxed at a time")
    print("=" * 76)
    banks, l0, l1, D0, D1 = _ladder_inputs(C, rom, imgs)
    rows = (("(nothing relaxed -- the shipped model)", {}),
            ("the two trailing nops are INERT", dict(nopi=1)),
            ("hi12 bit 4 stores WITHOUT clearing acc", dict(noclr=1)),
            ("slot 1's hi12[3:1]=2 is acc<-P", dict(s1op=0)),
            ("slot 1's hi12[3:1]=2 is acc+=P", dict(s1op=1)),
            ("slot 1's hi12[3:1]=2 is acc:=0", dict(s1op=3)),
            ("the ACTION acts BEFORE hi12[3:1]", dict(actfirst=1)),
            ("the DRAM read/write directions swapped", dict(swap=1)),
            ("an ESCAPE word honours hi12[3:1] too", dict(escop=1)),
            ("an ESCAPE word ignores lo12 entirely", dict(escact=0)))
    only = os.environ.get("PRICE_ROW")
    for n, (tag, base) in enumerate(rows):
        if only is not None and int(only) != n:
            continue
        print("   [%d] %s" % (n, tag), flush=True)
        na, nn, nnd, nnda = mult_can_be_s(base)
        print("       multiplicand can hold the FRESH read %d/%d, BOTH reads %d/%d"
              " (route-agnostic %d/%d)" % (nn, na, nnd, na, nnda, na), flush=True)
        action_search(banks, l0, D0, base)


# ==========================================================================
#  13.  ★ THE ADDER RE-RUN -- section 10 re-decided under analysis/acc-adder.md
#
#  Section 10's empty set was proved against a model that no longer exists: it
#  named the accumulator CLEAR as the cause, and `acc-adder.md' replaced exactly
#  the semantics that clear was part of.  The honest status of the strongest
#  negative result on this chip was therefore UNKNOWN, not established.  This
#  section re-decides it, reusing section 10's machine enumeration, its
#  delay-loop filter and its numeric matcher unchanged -- only `order = adder'
#  is new, and it is transcribed from acc_adjudicate.py term for term.
#
#  TWO sub-spaces are reported, because "the adder" is two claims:
#
#    GENEROUS  the accumulator's inputs are SELECTED rather than sequenced, but
#              any of the three unknown ACTION codes may drive the bus term.
#              Same 35 x 35 x 35 enumeration as section 10 -- the apples-to-
#              apples re-run against 20 580 000.
#    STRICT    what actually SHIPS: only ACTION 0x00 routes the bus; 0x19 and
#              0x0B are capture-only.  A sub-space of GENEROUS, so an empty
#              GENEROUS result implies an empty STRICT one -- but the STRICT
#              space needs its OWN control, because a space too poor to express
#              an all-pass at all would give an empty set for free.
# ==========================================================================
CAPONLY = range(len(CAPS))              # EFFECTS indices whose acc half is ""
GENEROUS = None                         # = the full 35 x 35 x 35
STRICT = (range(len(EFFECTS)), CAPONLY, CAPONLY)


#  A Gardner one-multiplier all-pass written INSIDE THE STRICT VOCABULARY: one
#  bus-routing ACTION code (0x00, one mode, one capture half) plus capture-only
#  codes and hi12[3:1].  If the harness accepts THIS, the strict sub-space is
#  expressive enough for an empty result in it to mean something.
#  Carried between repetitions: tA = d_in[r-1], tB = w[r-1], P = t[r-1].
STRICT_CTL = [
    dict(word="s0 read",  esc=True,  cls=1, src=0x0B, act=0x15, accop=2,
         store=False, dram="rd"),
    dict(word="s1",       esc=False, cls=2, src=0x10, act=0x12, accop=0,
         store=False, dram=None),      # acc <- P            = t[r-1]
    dict(word="s2",       esc=False, cls=2, src=0x1A, act=0x00, accop=2,
         store=False, dram=None),      # acc <- tB - acc     = x[r]
    dict(word="s3",       esc=False, cls=2, src=0x10, act=0x03, accop=2,
         store=False, dram=None),      # M <- acc            = x[r]
    dict(word="s4",       esc=False, cls=2, src=0x00, act=0x00, accop=2,
         store=False, dram=None),      # acc <- 0 - acc      = -x[r]
    dict(word="s5",       esc=False, cls=2, src=0x0B, act=0x00, accop=2,
         store=False, dram=None),      # acc <- DR - acc     = w[r] + x[r] = s[r]
    dict(word="s6 write", esc=True,  cls=1, src=0x19, act=0x15, accop=2,
         store=False, dram="wr"),      # line r-1 <- tA = d_in[r-1]
    dict(word="s7 mult",  esc=False, cls=0xA, src=0x10, act=0x12, accop=2,
         store=False, dram=None),      # P <- g * s[r]       = t[r]
    dict(word="s8",       esc=False, cls=2, src=0x07, act=0x00, accop=0,
         store=False, dram=None),      # acc <- P + M        = t[r] + x[r]
    dict(word="s9",       esc=False, cls=2, src=0x10, act=0x04, accop=2,
         store=False, dram=None),      # tA <- acc           = d_in[r]
    dict(word="s10",      esc=False, cls=2, src=0x0B, act=0x14, accop=2,
         store=False, dram=None)]      # tB <- bus           = w[r]


def sec_strict_control(C, rom, imgs, names):
    """The control for the STRICT sub-space -- one bus-routing ACTION code."""
    global MSLOTS, EXTRA_ACT
    print("=" * 76)
    print("13a. STRICT-VOCABULARY CONTROL -- can `only 0x00 routes the bus'")
    print("     express a one-multiplier all-pass AT ALL?")
    print("=" * 76)
    banks, l0, l1, D0, D1 = _ladder_inputs(C, rom, imgs)
    g = [banks[16][c] for c in l0]
    random.seed(7)
    xs = [random.uniform(-1, 1) for _ in range(64)]
    save_slots, save_extra = MSLOTS, EXTRA_ACT
    MSLOTS = STRICT_CTL
    EXTRA_ACT = {0x03: ("", "M<-acc"), 0x04: ("", "tA<-acc")}
    m = mach(EFFECTS.index(("bus-acc", "")), 0, 0, "zero", "bus", 1, -1,
             escact=0, order=1)
    ok = []
    for nst in (2, 4, 5):
        refs = [allpass_ref(g[:nst], D0[:nst], xs)]
        h = machine_matches(m, g[:nst], D0[:nst], xs, refs)
        ok.append((nst, h))
        print("   %d-stage ladder, ROM gains %s: %s"
              % (nst, " ".join("%.2f" % v for v in g[:nst]),
                 ("MATCH  inject=%s extract=%s scale=%+.3f"
                  % (RNAME[h[0][0]], RNAME[h[0][1]], h[0][3])) if h else "NO"))
    print("   loop filter on the strict control: %s" % (loop_ok(m) or "REJECTED"))
    MSLOTS, EXTRA_ACT = save_slots, save_extra
    return all(h for _n, h in ok)


def sec_adder(C, rom, imgs, names):
    parts = set((os.environ.get("ADDER_PARTS") or
                 "gate,control,count,route,search,gardner,forms,price").split(","))
    banks, l0, l1, D0, D1 = _ladder_inputs(C, rom, imgs)

    if "gate" in parts:
        print("=" * 76)
        print("13. ★ THE ADDER RE-RUN -- and first, does the STORE GATE even"
              " reach this motif?")
        print("=" * 76)
        print("   acc-adder.md adopts a bit-7 gate on the hi12 bit-4 store.  All")
        print("   three surviving gates agree that bit7 = 0 STORES.  So: MEASURE")
        print("   bit 7 on every storing word of the motif before assuming.")
        for i, sl in enumerate(MSLOTS):
            hi = int(sl["word"].split(".")[0], 16)
            if sl["store"]:
                b7 = (hi >> 7) & 1
                print("     slot %d  %-16s hi12 bit7 = %d -> all three gates say"
                      " %s" % (i, sl["word"], b7,
                               "STORE + CLEAR" if not b7 else "they DISAGREE"))
        print("   => the gate does not reach the motif; the clear is in force"
              " here under every adopted gate.  MEASURED.")
        print()

    if "control" in parts:
        sec_control(C, rom, imgs, names, order=1)
        print()
        sec_strict_control(C, rom, imgs, names)
        print()

    if "count" in parts:
        print("=" * 76)
        print("13b. THE OBSTRUCTION, RECOUNTED -- can the multiplicand hold BOTH"
              " reads?")
        print("=" * 76)
        for tag, base, rng in (
                ("sequential (section 10, reproduced)", {}, GENEROUS),
                ("ADDER, generous", dict(order=1), GENEROUS),
                ("ADDER, strict  ", dict(order=1), STRICT),
                ("sequential + no clear", dict(noclr=1), GENEROUS),
                ("ADDER, generous + no clear", dict(order=1, noclr=1), GENEROUS),
                ("ADDER, strict   + no clear", dict(order=1, noclr=1), STRICT),
                ("ADDER, generous + no store at all",
                 dict(order=1, noclr=2), GENEROUS)):
            na, nn, nnd, nnda = mult_can_be_s(base, rng)
            print("   %-34s  %8d enumerated   FRESH read %7d   BOTH (via DR)"
                  " %6d   BOTH (any route) %6d" % (tag, na, nn, nnd, nnda),
                  flush=True)
        print()

    if "search" in parts:
        print("=" * 76)
        print("13c. THE FULL SEARCH, RE-RUN UNDER THE ADDER")
        print("=" * 76)
        rows = [("ADDER, generous -- nothing else relaxed", dict(order=1),
                 GENEROUS),
                ("ADDER, strict   -- nothing else relaxed", dict(order=1),
                 STRICT)]
        only = os.environ.get("ADDER_ROW")
        for n, (tag, base, rng) in enumerate(rows):
            if only is not None and int(only) != n:
                continue
            print("   [%d] %s" % (n, tag), flush=True)
            action_search(banks, l0, D0, base, ranges=rng)
        print()

    if "route" in parts:
        print("=" * 76)
        print("13f. ★ THE ROUTE THE OLD COUNT COULD NOT SEE -- and the ONE"
              " parameter that closes it")
        print("=" * 76)
        print("   Section 10 counted the settings whose multiplicand carries the")
        print("   previous read IN THE DRAM READ-DATA REGISTER, and got 0.  The")
        print("   previous read can also arrive through the ACCUMULATOR, which")
        print("   crosses the repetition boundary.  Marginals of the settings that")
        print("   DO carry both reads, by any route:")
        NE = len(EFFECTS)
        for order in (0, 1):
            by00 = collections.Counter()
            by19 = collections.Counter()
            bysrc = collections.Counter()
            byland = collections.Counter()
            tot = 0
            for i00 in range(NE):
                for i19 in range(NE):
                    for i0b in range(NE):
                        for s0 in SRC0_CANDS:
                            for ld in LANDS:
                                mm = mach(i00, i19, i0b, s0, None, 1, ld, 1, 0,
                                          order=order)
                                st, tr = sym_rep(mm)
                                if "MULT" not in tr:
                                    continue
                                adv = advance(tr["MULT"], st)
                                if (adv is None or abs(adv[NA2]) <= 1e-12
                                        or abs(adv[NA]) <= 1e-12):
                                    continue
                                tot += 1
                                by00[EFFECTS[i00][0] or "(none)"] += 1
                                by19[EFFECTS[i19][1] or "(none)"] += 1
                                bysrc[s0] += 1
                                byland[ld] += 1
            print()
            print("   order = %-10s  %d settings carry BOTH reads"
                  % ("adder" if order else "sequential", tot), flush=True)
            for nm, cc in (("ACTION 0x00 acc half", by00),
                           ("ACTION 0x19 capture ", by19),
                           ("SRC 0x00 reads      ", bysrc),
                           ("the read lands at   ", byland)):
                print("       %s %-8s %s"
                      % (nm, "FORCED" if len(cc) == 1 else "%d values" % len(cc),
                         "  ".join("%s x%d" % (a, b) for a, b in cc.most_common())))
        print()

    if "gardner" in parts:
        print("=" * 76)
        print("13g. ★★★ CAN THE MOTIF BE A GARDNER STAGE, TERM BY TERM?")
        print("=" * 76)
        print("   Two exact symbolic predicates, at steady state, up to one")
        print("   overall sign and with NO other atom allowed:")
        print("     the MULTIPLICAND  s[r]    = w[r] + w[r-1] - t[r-1]"
              "   ->  +-(N' + N - Q)")
        print("     the WRITE-BACK    d_in[r] = x[r] + t[r]"
              "              ->  +-(N - Q + Q')")
        print("   The delay-loop filter never pins the second one down, which is")
        print("   why an empty numeric set could survive a correct multiplicand.")

        def _exact(f, want, tol=1e-9):
            for sgn in (1.0, -1.0):
                if all(abs(f[i] - sgn * want.get(i, 0.0)) < tol
                       for i in range(NATOM)):
                    return True
            return False

        MULT_WANT = {NA2: 1.0, NA: 1.0, QA: -1.0}
        WR_WANT = {NA: 1.0, QA: -1.0, QA2: 1.0}
        NE = len(EFFECTS)
        for nm, order in (("sequential", 0), ("adder", 1)):
            n_g = n_gl = n_gw = n_glw = 0
            by00 = collections.Counter()
            for i00 in range(NE):
                for i19 in range(NE):
                    for i0b in range(NE):
                        for s0 in SRC0_CANDS:
                            for ld in LANDS:
                                for ea in (0, 1):
                                    for sh in (0, 1):
                                        mm = mach(i00, i19, i0b, s0, None, 1, ld,
                                                  ea, sh, order=order)
                                        st, tr = sym_rep(mm)
                                        if "MULT" not in tr or "W" not in tr:
                                            continue
                                        adv = advance(tr["MULT"], st)
                                        if adv is None or not _exact(adv, MULT_WANT):
                                            continue
                                        n_g += 1
                                        by00[EFFECTS[i00][0] or "(none)"] += 1
                                        ok = loop_ok(mm)
                                        if ok:
                                            n_gl += 1
                                        for i, wv in enumerate(tr["W"]):
                                            nx = advance(wv, st)
                                            if nx is not None and _exact(nx, WR_WANT):
                                                n_gw += 1
                                                if WSRCS[i] in ok:
                                                    n_glw += 1
                                                break
            print()
            print("   %-11s EXACT multiplicand %6d | of those, pass the loop "
                  "filter %5d" % (nm, n_g, n_gl), flush=True)
            print("   %-11s EXACT write-back   %6d | BOTH exact AND "
                  "loop-consistent %5d" % ("", n_gw, n_glw), flush=True)
            print("   %-11s ACTION 0x00 acc half among them: %s"
                  % ("", "  ".join("%s x%d" % (a, b)
                                   for a, b in by00.most_common())), flush=True)
        print()

    if "forms" in parts:
        print("=" * 76)
        print("13e. WHAT THE SURVIVORS OF THE LOOP FILTER ACTUALLY MULTIPLY")
        print("=" * 76)
        print("   The numeric stage says NO.  This says WHAT it is saying no to:")
        print("   for every machine that passes the delay-loop filter, the")
        print("   SYMBOLIC multiplicand, and whether the two delay reads can meet")
        print("   in it at all (route-agnostic).  A first-order all-pass needs")
        print("   s[r] = x[r] + w[r] with x[r] = w[r-1] - t[r-1], i.e. at steady")
        print("   state the multiplicand must carry N', N and Q with the SAME")
        print("   magnitude and NOTHING else that the loop does not cancel.")
        for tag, base, rng in (("sequential (section 10)", {}, GENEROUS),
                               ("ADDER, generous", dict(order=1), GENEROUS),
                               ("ADDER, strict", dict(order=1), STRICT)):
            _t, sl, _n = action_search(banks, l0, D0, base, quiet=True,
                                       ranges=rng, numeric=False)
            forms = collections.Counter()
            both = 0
            for mm in sl:
                st, tr = sym_rep(mm)
                adv = advance(tr["MULT"], st)
                if (adv is not None and abs(adv[NA2]) > 1e-12
                        and abs(adv[NA]) > 1e-12):
                    both += 1
                forms[show_form(tr["MULT"])] += 1
            print()
            print("   %-24s %6d loop survivors, %d of them can hold BOTH reads"
                  % (tag, len(sl), both), flush=True)
            for f, n in forms.most_common(8):
                print("        %-40s x%d" % (f, n))

    if "price" in parts:
        print("=" * 76)
        print("13d. THE PRICE LIST, UNDER THE ADDER -- is the CLEAR still the"
              " assumption that moves the count?")
        print("=" * 76)
        rows = (("(nothing relaxed -- the adder as shipped)", dict(order=1)),
                ("hi12 bit 4 stores WITHOUT clearing acc",
                 dict(order=1, noclr=1)),
                ("hi12 bit 4 neither stores NOR clears", dict(order=1, noclr=2)),
                ("the two trailing nops are INERT", dict(order=1, nopi=1)),
                ("slot 1's hi12[3:1]=2 is acc<-P", dict(order=1, s1op=0)),
                ("slot 1's hi12[3:1]=2 is acc+=P", dict(order=1, s1op=1)),
                ("the DRAM read/write directions swapped", dict(order=1, swap=1)),
                ("an ESCAPE word honours hi12[3:1] too", dict(order=1, escop=1)),
                ("an ESCAPE word ignores lo12 entirely",
                 dict(order=1, escact=0)))
        only = os.environ.get("PRICE_ROW")
        for n, (tag, base) in enumerate(rows):
            if only is not None and int(only) != n:
                continue
            print("   [%d] %s" % (n, tag), flush=True)
            na, nn, nnd, nnda = mult_can_be_s(base)
            print("       multiplicand: FRESH %d/%d   BOTH via DR %d   BOTH any"
                  " route %d" % (nn, na, nnd, nnda), flush=True)
            action_search(banks, l0, D0, base)


# ==========================================================================
#  14.  ★ THE SCHROEDER / NESTED-COMB TEST
#
#  NAMING.  `sec_schroeder' above is ALREADY TAKEN, by a different and much
#  older question (section 9: can a GARDNER machine have WVAL == MULT, inside
#  R1's four-register model -- answer no).  This section is the one the brief
#  asks for and it is called `sec_schroeder2' / CLI `schroeder2' so that the
#  published reproduce lines for section 9 keep working.
#
#  WHY IT EXISTS.  `allpass-adder-rerun.md' sect. 6.3 located the obstruction
#  exhaustively: slot 4 (the DRAM WRITE, src 0x19) and slot 5 (THE MULTIPLY,
#  src 0x19) are ADJACENT and slot 4's ACTION 0x15 has no capture half, so
#  whenever the write takes its data from the BUS the value stored into the
#  delay line and the value handed to the multiplier are THE SAME NUMBER.
#  Call it u.  Then
#
#        line <- u ,   t = g*u ,   w = u[n-D]      =>   g*w[n] = t[n-D]
#
#  A first-order all-pass stage stores x+t and multiplies x+w -- two different
#  numbers -- so it is excluded, which is the published zero.  What is NOT
#  excluded is a recirculating COMB: with the write trailing the read by one
#  repetition, u_r = a*x + b*w_r + c*t_{r-1} gives
#
#        d_k[n] = (b*c*g_k) * d_k[n-D_k] + (terms not involving line k)
#
#  -- loop gain b*c*g_k, closed through the multiplier exactly once, ACROSS the
#  repetition boundary.  That is the comb denominator 1 - g z^-D.
#
#  ★ AND THAT REFRAMES THE EXISTING FILTER.  `loop_ok's C1/C2/C3 are conditions
#  on the DENOMINATOR alone (the fresh read reaches the multiplier +-1; the
#  product reaches the line one repetition later +-1; nothing unmultiplied gets
#  back).  They are the COMB conditions.  The all-pass lives entirely in the
#  NUMERATOR, which only the numeric matcher ever tested.  So the 74 508 adder
#  survivors already have a correct comb denominator and were rejected on the
#  numerator only -- which is exactly why re-testing the SAME survivor set
#  against COMB references is the cheap, well-posed next question.
# ==========================================================================

# --- the candidate topologies, each written FROM THE MATHEMATICS -----------
#  Every one of these is a textbook structure transcribed from its difference
#  equation with the same `Line' class the ladder uses.  None of them is
#  derived from the executor, from the ROM words or from a search result.

def comb_series_ref(gains, delays, x, tap="v"):
    """A CASCADE of feedback combs:  V_k = V_{k-1} / (1 - g_k z^-D_k).
    Line k stores v; reading it returns v[n-D_k]."""
    lines = [Line(d) for d in delays]
    out = []
    for xn in x:
        v, w = xn, 0.0
        for k, g in enumerate(gains):
            w = lines[k].read()
            v = v + g * w
            lines[k].write(v)
        out.append(v if tap == "v" else w)
        for ln in lines:
            ln.advance()
    return out


def comb_parallel_ref(gains, delays, x):
    """Schroeder's parallel comb BANK:  y = SUM_k x/(1 - g_k z^-D_k)."""
    lines = [Line(d) for d in delays]
    out = []
    for xn in x:
        y = 0.0
        for k, g in enumerate(gains):
            v = xn + g * lines[k].read()
            lines[k].write(v)
            y += v
        out.append(y)
        for ln in lines:
            ln.advance()
    return out


def lp_comb_ref(gains, delays, x):
    """A MOORER comb: the feedback runs through a fixed one-zero averager
    (1 + z^-1)/2, which the chip could supply with the tempB >>1 and no second
    multiplier.  y = SUM_k of  v_k[n] = x[n] + g_k*(w_k[n] + w_k[n-1])/2."""
    lines = [Line(d) for d in delays]
    prev = [0.0] * len(delays)
    out = []
    for xn in x:
        y = 0.0
        for k, g in enumerate(gains):
            w = lines[k].read()
            v = xn + g * 0.5 * (w + prev[k])
            prev[k] = w
            lines[k].write(v)
            y += v
        out.append(y)
        for ln in lines:
            ln.advance()
    return out


def nested_ap_ref(gains, delays, x):
    """GARDNER's NESTED all-pass: stage k is a one-multiplier all-pass whose
    delay line is fed by stage k+1's output -- an all-pass inside the delay of
    an all-pass.  Written from the recursion, not from any machine."""
    lines = [Line(d) for d in delays]
    K = len(gains)

    def stage(k, v):
        w = lines[k].read()
        t = gains[k] * (v + w)
        inner = v + t
        if k + 1 < K:
            inner = stage(k + 1, inner)
        lines[k].write(inner)
        return w - t

    out = []
    for xn in x:
        out.append(stage(0, xn))
        for ln in lines:
            ln.advance()
    return out


#  ★ THE STRUCTURE THE OBSTRUCTION ITSELF IMPLIES.  Not a textbook name: the
#  difference equation of the note's own §6.3, written out.  Repetition r reads
#  line r, forms u_r = b*w_r + c*t_{r-1}, writes u_r into line r-1 (the write
#  trails by one) and multiplies the SAME u_r by g_r.  The ladder input enters
#  as t_{-1}, i.e. through the product register -- which is what the five-word
#  separator in front of every ladder supplies (one DRAM read + one class-A
#  multiply), the same injection `run_ladder' documents.
#  `drain' is the ONE boundary convention, enumerated and not chosen: at the
#  K-th (drain) repetition there is no read, so the read-data register either
#  reads as zero or HOLDS the previous repetition's value.
def pipe_net_ref(gains, delays, x, b, c, tap, drain="hold"):
    K = len(gains)
    lines = [Line(d) for d in delays]
    out = []
    for xn in x:
        tprev, wprev = xn, 0.0
        us, ws, ts = [], [], []
        for r in range(K + 1):
            if r < K:
                w = lines[r].read()
            else:
                w = wprev if drain == "hold" else 0.0
            u = b * w + c * tprev
            if r - 1 >= 0:
                lines[r - 1].write(u)
            us.append(u)
            ws.append(w)
            wprev = w
            tprev = gains[r] * u if r < K else tprev
            ts.append(tprev)
        out.append({"u_last": us[-1], "t_last": ts[-1], "w_last": ws[-1],
                    "u_sum": sum(us), "w_sum": sum(ws)}[tap])
        for ln in lines:
            ln.advance()
    return out


PIPE_TAPS = ("u_last", "t_last", "w_last", "u_sum", "w_sum")


def topology_refs(gains, delays, x, wide=True):
    """The reference set.  Returns [(name, array), ...].

    A LATTICE is deliberately NOT here, and the reason is stated rather than
    assumed: a Gray-Markel one-multiplier lattice REALISES the same all-pass
    transfer function, and the matcher only ever compares INPUT/OUTPUT, so it
    is the same test as `allpass_ref' -- already zero, twice.  The same
    argument retires the two-multiply Schroeder all-pass (comb + feed-forward):
    identical transfer function, and it needs g twice per stage where the core
    has one class-A word."""
    refs = [("allpass (the published zero, kept as a NEGATIVE control)",
             allpass_ref(gains, delays, x)),
            ("comb cascade, tap = stored", comb_series_ref(gains, delays, x, "v")),
            ("comb cascade, tap = delayed", comb_series_ref(gains, delays, x, "w")),
            ("comb bank, parallel", comb_parallel_ref(gains, delays, x)),
            ("Moorer lowpass comb bank", lp_comb_ref(gains, delays, x)),
            ("nested all-pass (Gardner)", nested_ap_ref(gains, delays, x))]
    if wide:
        for b in (1.0, -1.0):
            for c in (1.0, -1.0):
                for dr in ("hold", "zero"):
                    for tp in PIPE_TAPS:
                        refs.append(("pipe-comb b%+d c%+d %s %s"
                                     % (b, c, dr, tp),
                                     pipe_net_ref(gains, delays, x, b, c, tp,
                                                  dr)))
    # DEDUPLICATE.  The matcher grants a free scale, so two references that are
    # PROPORTIONAL are the same test twice and would inflate every count.  The
    # pipe-comb family is symmetric under (b,c) -> (-b,-c) -- an overall sign --
    # and at drain = zero u_K = c*t_{K-1}, so u_last and t_last coincide there.
    # Both are real identities, so the duplicates are merged, not hidden.
    out = []
    for nm, a in refs:
        for _n2, a2 in out:
            p = _proj(a, a2)
            if p is not None and p[1] < 1e-12:
                break
        else:
            out.append((nm, a))
    return out


def _proj(o, ref):
    """best scale and the worst relative residue -- the matcher's own test."""
    den = sum(v * v for v in o)
    if den < 1e-18:
        return None
    sc = sum(a * bb for a, bb in zip(o, ref)) / den
    if abs(sc) < 1e-6:
        return None
    mx = max(abs(v) for v in ref)
    if mx < 1e-12:
        return None
    return sc, max(abs(sc * a - bb) for a, bb in zip(o, ref)) / mx


def match_refs(outs, refs, tol=1e-7):
    """Every (reference, injection, extraction, scale) that reproduces one of
    the references.  Same acceptance rule as `machine_matches', applied to a
    SET of references over ONE ladder run -- which is the whole point: the
    expensive part is the ladder, not the comparison.

    The probe-sample early-out is an OPTIMISATION ONLY: a candidate that clears
    the probe is still checked on every sample, so the accept/reject decision is
    identical to `_proj's, and `refs_selftest' asserts that on real data."""
    prep = [(nm, ref, tol * max(abs(v) for v in ref)) for nm, ref in refs]
    hits = []
    for inj in range(6):
        for ext in range(6):
            o = outs[inj][ext]
            den = 0.0
            for v in o:
                den += v * v
            if den < 1e-18:
                continue
            probe = range(0, len(o), max(1, len(o) // 5))
            for nm, ref, lim in prep:
                sc = 0.0
                for a, b in zip(o, ref):
                    sc += a * b
                sc /= den
                if abs(sc) < 1e-6:
                    continue
                for i in probe:
                    if abs(sc * o[i] - ref[i]) > lim:
                        break
                else:
                    if max(abs(sc * a - b) for a, b in zip(o, ref)) <= lim:
                        hits.append((nm, inj, ext, sc))
    return hits


def machine_outputs(m, gains, delays, x):
    return [run_ladder_action(m, gains, delays, x, inj) for inj in range(6)]


# --- CONTROLS THAT CAN SAY NO ---------------------------------------------
#  Rule, earned the hard way: a control that cannot fail is not evidence.  The
#  previous positive control produced BIT-IDENTICAL output across both settings
#  of the parameter it was built to validate.  So each control below is shipped
#  WITH a deliberately wrong twin, and the twin's rejection is printed next to
#  the acceptance.

#  (a) a COMB CASCADE, built where the write and the multiplicand DIFFER --
#      the multiplicand is the fresh read w, the written value is the running
#      accumulator v.  This is the control for the comb REFERENCE.
COMB_CTL = [
    dict(word="c0 read",  esc=True,  cls=1, src=0x0B, act=0x15, accop=2,
         store=False, dram="rd"),                      # DR <- w[k]
    dict(word="c1 mult",  esc=False, cls=0xA, src=0x0B, act=0x15, accop=2,
         store=False, dram=None),                      # P  <- g_k * w[k]
    dict(word="c2",       esc=False, cls=2, src=0x00, act=0x15, accop=1,
         store=False, dram=None),                      # acc += P   -> v
    dict(word="c3",       esc=False, cls=2, src=0x10, act=0x13, accop=2,
         store=False, dram=None),                      # tA <- acc
    dict(word="c4 write", esc=True,  cls=1, src=0x19, act=0x15, accop=2,
         store=False, dram="wr")]                      # line k <- tA = v

#  (a') THE WRONG TWIN, and it is wrong in EXACTLY the way this pass is about:
#       tA is captured BEFORE the accumulate, so the written value becomes the
#       value the multiplier consumed -- WRITE == MULTIPLICAND.  If the comb
#       reference cannot tell these two apart it is worthless.
COMB_CTL_WRITEEQ = [COMB_CTL[0], COMB_CTL[1],
                    dict(word="c2' tA<-DR", esc=False, cls=2, src=0x0B,
                         act=0x13, accop=2, store=False, dram=None),
                    dict(word="c3' acc+=P", esc=False, cls=2, src=0x00,
                         act=0x15, accop=1, store=False, dram=None),
                    COMB_CTL[4]]

#  (b) THE PIPELINED COMB the obstruction implies: write == multiplicand, the
#      write trailing the read by one repetition.  b = c = +1.
PIPE_CTL = [
    dict(word="p0 read",  esc=True,  cls=1, src=0x0B, act=0x15, accop=2,
         store=False, dram="rd"),                      # DR <- w[r] (lands +1)
    dict(word="p1",       esc=False, cls=2, src=0x0B, act=0x01, accop=0,
         store=False, dram=None),                      # acc <- P + DR = u_r
    dict(word="p2",       esc=False, cls=2, src=0x10, act=0x13, accop=2,
         store=False, dram=None),                      # tA <- acc = u_r
    dict(word="p3 write", esc=True,  cls=1, src=0x19, act=0x15, accop=2,
         store=False, dram="wr"),                      # line r-1 <- tA
    dict(word="p4 mult",  esc=False, cls=0xA, src=0x19, act=0x15, accop=2,
         store=False, dram=None)]                      # P <- g_r * tA

#  (b') THE WRONG TWINS OF (b).  Two of the twins tried first were NOT twins at
#  all and the run said so, which is itself a measured fact about the adder:
#  ★ AT A WORD WITH hi12[3:1] == 0 THE FEEDBACK INPUT IS ALREADY ZERO, so the
#  ACTION halves `+bus', `bus' (load) and `bus-acc' (rload) ALL PRODUCE P + bus
#  and are INDISTINGUISHABLE THERE.  The twins below therefore perturb things
#  the model can actually separate: the sign of b, the presence of the product
#  in the loop (hi12[3:1] = 3 drops it), and the pipeline trail of the write.
PIPE_CTL_NOLOOP = [PIPE_CTL[0],
                   dict(word="p1' acc<-DR", esc=False, cls=2, src=0x0B,
                        act=0x15, accop=3, store=False, dram=None),
                   PIPE_CTL[2], PIPE_CTL[3], PIPE_CTL[4]]
#  tA captured straight from the delay read: the line then stores a RAW read,
#  which is a pure delay chain and not a comb at all.
PIPE_CTL_RAW = [PIPE_CTL[0],
                dict(word="p1'' tA<-DR", esc=False, cls=2, src=0x0B, act=0x13,
                     accop=2, store=False, dram=None),
                dict(word="p2'' idle", esc=False, cls=2, src=0x00, act=0x15,
                     accop=2, store=False, dram=None),
                PIPE_CTL[3], PIPE_CTL[4]]


#  a nominal machine, only ever used to ASK the anchored half of `act_effect'
#  (0x15 has no unknown half, so nothing about it depends on this choice)
NOMINAL_M = mach(0, 0, 0, "zero", "bus", 1, 0)

#  Delay sets SHORT ENOUGH TO RECIRCULATE inside a 32/64-sample run.  The ROM's
#  real ladder-0 lengths are [127, 435, 489, 183, 522] and the shipped controls
#  used them over 64 samples, so not one line ever returned a written value --
#  see 14c.  Two independent sets, because one could be a coincidence.
DSHORT = [3, 5, 7, 11, 13]
DSHORT2 = [2, 3, 4, 5, 6]


class _ProbeLine(Line):
    __slots__ = ("nz",)

    def __init__(self, n):
        Line.__init__(self, n)
        self.nz = 0

    def read(self):
        v = Line.read(self)
        if v:
            self.nz += 1
        return v


def _probe_reads(gains, delays, x):
    """How many delay reads actually return a written value?  A reference whose
    lines never recirculate is not a reference to a delay network at all."""
    lines = [_ProbeLine(d) for d in delays]
    for xn in x:
        v = xn
        for k, g in enumerate(gains):
            w = lines[k].read()
            t = g * (v + w)
            lines[k].write(v + t)
            v = w - t
        for ln in lines:
            ln.advance()
    return [ln.nz for ln in lines]


def _run_ctl(slots, extra, m, gains, delays, x, refs, tol=1e-7):
    global MSLOTS, EXTRA_ACT
    sv, se = MSLOTS, EXTRA_ACT
    MSLOTS, EXTRA_ACT = slots, extra
    try:
        outs = machine_outputs(m, gains, delays, x)
        hits = match_refs(outs, refs, tol)
        lp = loop_ok(m)
    finally:
        MSLOTS, EXTRA_ACT = sv, se
    return hits, lp


def sec_schroeder2(C, rom, imgs, names):
    parts = set((os.environ.get("SCH_PARTS") or
                 "facts,theory,refs,degeneracy,control,search").split(","))
    banks, l0, l1, D0, D1 = _ladder_inputs(C, rom, imgs)
    g2 = [banks[16][c] for c in l0][:2]
    random.seed(7)
    xs = [random.uniform(-1, 1) for _ in range(32)]
    DEL = [3, 5]

    # ---------------------------------------------------------------- facts
    if "facts" in parts:
        print("=" * 76)
        print("14. ★ SCHROEDER / NESTED-COMB -- the constraints, MEASURED first")
        print("=" * 76)
        rev = [i for i in sorted(imgs)
               if "REVERB" in (names.get(i, "") or "").upper()]
        grp = collections.Counter(tuple(imgs[i]) for i in rev)
        big = [i for i in rev if len(imgs[i]) == 133]
        print("   reverb algos: %s" % ", ".join("%d(%d w)" % (i, len(imgs[i]))
                                                for i in rev))
        print("   distinct word images among them: %d  (sizes %s)"
              % (len(grp), sorted(len(k) for k in grp)))
        print("   the %d presets with a 133-word body: %s"
              % (len(big), "ONE image, byte-identical"
                 if len({tuple(imgs[i]) for i in big}) == 1 else "DIFFER"))
        print("   => any surviving assignment is automatically PRESET-")
        print("      INDEPENDENT: nothing below reads a preset at all, only the")
        print("      shared image, and the gains enter only the numeric stage.")
        img = imgs[16]
        esc1 = sum(1 for w in img if ((w >> 24) & 0x800) and ((w >> 20) & 0xF) == 1)
        print("   external-DRAM words (escape, class 1) in the 133-word image: %d"
              % esc1)
        print()

    # --------------------------------------------------------------- theory
    if "theory" in parts:
        print("=" * 76)
        print("14a. WRITE == MULTIPLICAND -- proven by construction, then spot-"
              "measured")
        print("=" * 76)
        s4, s5 = MSLOTS[4], MSLOTS[5]
        print("   slot 4 %-16s src=%02X  act=%02X -> %s" %
              (s4["word"], s4["src"], s4["act"], act_effect(NOMINAL_M, s4["act"])))
        print("   slot 5 %-16s src=%02X  act=%02X   (class A: THE multiply)" %
              (s5["word"], s5["src"], s5["act"]))
        print("   Same SRC, adjacent, and slot 4's ACTION 0x15 is anchored to")
        print("   ('','') -- no capture half at all.  Nothing between the two")
        print("   words can rewrite tempA, for ANY assignment of the three")
        print("   unknown codes: they are not even reachable at slot 4.")
        print("   => PROVEN BY CONSTRUCTION.  Now measured anyway, on a random")
        print("      sample of the same 5 145 000-setting space:")
        random.seed(11)
        NE = len(EFFECTS)
        agree = tot = 0
        for _ in range(20000):
            mm = mach(random.randrange(NE), random.randrange(NE),
                      random.randrange(NE), random.choice(SRC0_CANDS), None, 1,
                      random.choice(LANDS), random.choice((0, 1)),
                      random.choice((0, 1)), order=random.choice((0, 1)))
            _st, tr = sym_rep(mm)
            if "MULT" not in tr or "W" not in tr:
                continue
            tot += 1
            agree += (tr["W"][0] == tr["MULT"])
        print("      bus write value == multiplicand: %d / %d settings"
              % (agree, tot))
        print()
        print("   THE DIFFERENCE EQUATION THAT PRODUCES (write source = bus):")
        print("      line <- u ;  t = g*u ;  w = u[n-D]   =>   g*w[n] = t[n-D]")
        print("      u_r = a*x + b*w_r + c*t_{r-1}   (a,b,c in {0,+-1}: the ALU"
              " only adds)")
        print("      d_k[n] = u_{k+1}[n] = a*x + b*w_{k+1}[n] + c*g_k*u_k[n]")
        print("      =>  d_k[n] = (b*c*g_k)*d_k[n-D_k] + (no line-k terms)")
        print("   ★ loop gain b*c*g_k, through the multiplier exactly once, and")
        print("     it closes ACROSS the repetition boundary.  A first-order")
        print("     all-pass needs line <- x+t while the multiplicand is x+w --")
        print("     two different numbers -- so it is excluded; a COMB is not.")
        print()

    # ----------------------------------------------------------------- refs
    if "refs" in parts:
        print("=" * 76)
        print("14b. ARE THE REFERENCES EVEN DISTINGUISHABLE?")
        print("=" * 76)
        print("   The matcher grants an arbitrary scale and enumerates 6 x 6")
        print("   injection/extraction pairs.  With that much freedom, two")
        print("   references that happen to be proportional would make a `hit'")
        print("   meaningless.  So: pairwise, after the best scale, the worst")
        print("   relative residue between every pair.  Anything at 0 is a")
        print("   DUPLICATE and the section would have to say so.")
        refs = topology_refs(g2, DEL, xs)
        worst = 1e30
        dup = []
        for i in range(len(refs)):
            for j in range(i + 1, len(refs)):
                p = _proj(refs[i][1], refs[j][1])
                r = 1e30 if p is None else p[1]
                worst = min(worst, r)
                if r < 1e-7:
                    dup.append((refs[i][0], refs[j][0]))
        print("   %d references; closest pair residue %.3g; duplicate pairs %d"
              % (len(refs), worst, len(dup)))
        for a, b in dup[:12]:
            print("       DUPLICATE  %-38s == %s" % (a, b))
        # the fast matcher must decide EXACTLY what the plain one decides
        random.seed(23)
        mism = trials = 0
        for _ in range(60):
            mm = mach(random.randrange(len(EFFECTS)),
                      random.randrange(len(EFFECTS)),
                      random.randrange(len(EFFECTS)), random.choice(SRC0_CANDS),
                      random.choice(WSRCS), 1, random.choice(LANDS),
                      order=random.choice((0, 1)))
            outs = machine_outputs(mm, g2, DEL, xs)
            fast = {(a, i, e) for a, i, e, _s in match_refs(outs, refs)}
            slow = set()
            for i in range(6):
                for e in range(6):
                    for nmr, rf in refs:
                        p = _proj(outs[i][e], rf)
                        trials += 1
                        if p is not None and p[1] < 1e-7:
                            slow.add((nmr, i, e))
            mism += (fast != slow)
        print("   fast matcher vs plain _proj: %d disagreements over %d "
              "reference tests on %d random machines" % (mism, trials, 60))
        print()

    # ----------------------------------------------------------- degeneracy
    #  ★ FOUND BY THIS PASS, AND IT IS IN THE PUBLISHED CONTROLS.
    if "degeneracy" in parts:
        print("=" * 76)
        print("14c. ★ A DEGENERATE CONTROL -- the published positive controls"
              " never exercised a delay")
        print("=" * 76)
        g5 = [banks[16][c] for c in l0]
        print("   sec_control / sec_strict_control run the reference with the")
        print("   ROM's REAL ladder-0 delays %s over %d samples."
              % (D0, 64))
        print("   Count the delay reads that return a NON-ZERO value:")
        for nst in (2, 4, 5):
            nz = _probe_reads(g5[:nst], D0[:nst],
                              [random.uniform(-1, 1) for _ in range(64)])
            print("       %d-stage, 64 samples: non-zero reads per line = %s"
                  % (nst, nz))
        print("   ZERO.  min(delay) = %d > 64 samples, so no line recirculates"
              % min(D0))
        print("   and the all-pass reference collapses to y = x * PROD(-g_k),")
        print("   a pure scalar.  The control was asserting `the machine's")
        print("   output is a scalar multiple of x'.  It could not fail.")
        print()
        print("   RE-RUN, with delays short enough to recirculate:")
        for nm, slots, extra, m in (
                ("gardner (sec_control)", CONTROL_SLOTS,
                 {0x01: ("+bus", ""), 0x02: ("", "tA<-bus")},
                 mach(EFFECTS.index(("bus", "")), EFFECTS.index(("-bus", "")),
                      EFFECTS.index(("+bus", "tB<-bus")), "P", "bus", 1, 0,
                      escact=0, noclr=1, order=1)),
                ("strict (13a)", STRICT_CTL,
                 {0x03: ("", "M<-acc"), 0x04: ("", "tA<-acc")},
                 mach(EFFECTS.index(("bus-acc", "")), 0, 0, "zero", "bus", 1,
                      -1, escact=0, order=1))):
            for dd in (D0[:5], DSHORT, DSHORT2):
                random.seed(7)
                x64 = [random.uniform(-1, 1) for _ in range(64)]
                sv, se = MSLOTS, EXTRA_ACT
                globals()["MSLOTS"], globals()["EXTRA_ACT"] = slots, extra
                try:
                    h = machine_matches(m, g5[:5], dd[:5], x64,
                                        [allpass_ref(g5[:5], dd[:5], x64)])
                finally:
                    globals()["MSLOTS"], globals()["EXTRA_ACT"] = sv, se
                print("       %-22s delays %-22s %s"
                      % (nm, str(dd[:5]),
                         ("MATCH inj=%s ext=%s sc=%+.4f"
                          % (RNAME[h[0][0]], RNAME[h[0][1]], h[0][3])) if h
                         else "NO MATCH"))
        print("   => the control SURVIVES repair, but its PUBLISHED figures do")
        print("      not: `extract = P, scale = +1.000' is the zero-delay")
        print("      artefact; with a recirculating line it is extract = M,")
        print("      scale = -1.000.  The SEARCH is unaffected -- action_search")
        print("      uses delays [3, 5] over 32 samples, which do recirculate.")
        print()

    # -------------------------------------------------------------- control
    if "control" in parts:
        print("=" * 76)
        print("14d. ★ THE CONTROLS -- each one shipped WITH the case where it"
              " says NO")
        print("=" * 76)
        g5 = [banks[16][c] for c in l0]
        random.seed(5)
        x64 = [random.uniform(-1, 1) for _ in range(64)]
        print("   Delays %s and %s -- SHORT ON PURPOSE, over %d samples, so"
              % (DSHORT, DSHORT2, len(x64)))
        print("   every line recirculates many times.  Non-zero delay reads per")
        print("   line: %s / %s" % (_probe_reads(g5[:5], DSHORT, x64),
                                    _probe_reads(g5[:5], DSHORT2, x64)))
        print("   (a control run on lines that never return anything is the")
        print("    defect 14c just retired -- it must not be repeated here.)")
        print()

        def _ctl(tag, slots, extra, m):
            for dd in (DSHORT, DSHORT2):
                for nst in (2, 3, 5):
                    gg, d = g5[:nst], dd[:nst]
                    rr = topology_refs(gg, d, x64)
                    h, _lp = _run_ctl(slots, extra, m, gg, d, x64, rr)
                    names_ = sorted({n for n, _i, _e, _s in h})
                    print("       %-30s %d-stage %-18s %s"
                          % (tag, nst, str(d),
                             ", ".join(names_) if names_
                             else "NO MATCH   <- SAYS NO"))

        print("   (a) COMB CASCADE, built with write != multiplicand:")
        m = mach(0, 0, 0, "zero", "bus", 0, -1, escact=0, order=1)
        _ctl("comb cascade", COMB_CTL, {0x01: ("+bus", "")}, m)
        print("       loop filter on it: %s"
              % (loop_ok_ctl(COMB_CTL, {0x01: ("+bus", "")}, m) or "REJECTED"))
        print()
        print("   (a') THE WRONG TWIN -- identical except tA is captured BEFORE")
        print("        the accumulate, so WRITE == MULTIPLICAND, the exact")
        print("        property this whole pass is about:")
        _ctl("comb cascade, write==mult", COMB_CTL_WRITEEQ, {}, m)
        print()
        print("   (b) THE PIPELINED COMB the obstruction implies (write ==")
        print("       multiplicand, the write trailing the read by one rep):")
        mp = mach(0, 0, 0, "zero", "bus", 1, 1, escact=0, order=1)
        _ctl("pipe-comb b=+1 c=+1", PIPE_CTL, {0x01: ("+bus", "")}, mp)
        print("       loop filter on it: %s"
              % (loop_ok_ctl(PIPE_CTL, {0x01: ("+bus", "")}, mp) or "REJECTED"))
        print()
        print("   (b') THE WRONG TWINS OF (b).  If the reference set is worth")
        print("        anything, flipping the ALU op must MOVE the match to the")
        print("        matching (b,c) label and BREAKING the loop must kill it.")
        print("        ★ NOTE first what the run itself taught: at hi12[3:1]=0")
        print("        the feedback input is ALREADY zero, so `+bus', `bus'")
        print("        (load) and `bus-acc' all give P+bus and are the SAME")
        print("        machine there.  Two of the twins tried first were not")
        print("        twins; these are:")
        _ctl("b = -1  (p1 does acc<-P-DR)", PIPE_CTL, {0x01: ("-bus", "")}, mp)
        _ctl("c = 0   (hi12[3:1]=3, no P)", PIPE_CTL_NOLOOP, {}, mp)
        _ctl("line stores a RAW read", PIPE_CTL_RAW, {}, mp)
        _ctl("write does not trail (wtrail=0)", PIPE_CTL, {0x01: ("+bus", "")},
             mach(0, 0, 0, "zero", "bus", 0, 1, escact=0, order=1))
        _ctl("read lands too late (land=7)", PIPE_CTL, {0x01: ("+bus", "")},
             mach(0, 0, 0, "zero", "bus", 1, 7, escact=0, order=1))
        print()

    # --------------------------------------------------------------- search
    if "search" in parts:
        print("=" * 76)
        print("14e. ★ THE SEARCH -- the SAME loop-filter survivor set, re-tested"
              " against every topology")
        print("=" * 76)
        print("   The structural stage is `action_search's, unchanged and")
        print("   delay-independent.  What is new is the numeric stage: the")
        print("   ladder is run ONCE per survivor and compared against every")
        print("   reference, and a hit is only reported if it SURVIVES A SECOND")
        print("   run at a different delay set and twice the samples -- the")
        print("   guard against a numerical accident at one delay pair.")
        #  ★ ROW 3 IS THE JOINT ROW.  SINGLE DELAY -- a block whose algorithm is
        #  not in doubt -- FORCES `ACTION 0x19' to capture into tempA (5145/5145,
        #  action-field.md sect. 6).  The STRICT reverb survivors say tempB, and
        #  the GENEROUS ones say tempA by a majority.  So intersect: enumerate
        #  ONLY the 0x19 effects that capture into tempA and ask what the comb
        #  then forces.  A parameter settled in another context is not settled
        #  inside this search -- so it is ENUMERATED here, restricted, never
        #  assumed.
        TA_CAP = [i for i, e in enumerate(EFFECTS)
                  if e[1] in ("tA<-bus", "tA<-acc")]
        JOINT = (range(len(EFFECTS)), TA_CAP, range(len(EFFECTS)))
        rows = [("ADDER, generous", dict(order=1), GENEROUS, None),
                ("ADDER, strict  ", dict(order=1), STRICT, None),
                ("sequential, generous", {}, GENEROUS, None),
                ("ADDER, generous + SINGLE DELAY's ACTION 0x19 -> tempA",
                 dict(order=1), JOINT, None),
                #  ★ ROBUSTNESS AGAINST THE PARALLEL PASS.
                #  `action00-discriminator.md' (2026-07-27) falsifies the 18/18
                #  forcing of `load' by widening the STORE GATE -- a suppressed
                #  store whose CLEAR is deferred.  The motif's only storing word
                #  has hi12 bit 7 = 0, so the SUPPRESSION cannot reach it
                #  (allpass-adder-rerun.md sect. 3, MEASURED) -- but the CLEAR
                #  itself can still be wrong, and a parameter settled elsewhere
                #  is not settled inside this search.  So enumerate it here:
                ("ADDER, strict + bit-4 stores WITHOUT clearing",
                 dict(order=1, noclr=1), STRICT, None),
                ("ADDER, strict + bit-4 neither stores NOR clears",
                 dict(order=1, noclr=2), STRICT, None),
                ("ADDER, joint + bit-4 stores WITHOUT clearing",
                 dict(order=1, noclr=1), JOINT, None),
                ("ADDER, joint + bit-4 neither stores NOR clears",
                 dict(order=1, noclr=2), JOINT, None),
                #  ★★ ROWS 8-10: THE BLOCKING READ.  See sec_blockread() for the
                #  whole argument; these rows are here so the marginals can be
                #  read side by side with rows 0-7 in one output.
                ("ADDER, strict + THE BLOCKING READ (land = -1)",
                 dict(order=1), STRICT, (-1,)),
                ("ADDER, joint  + THE BLOCKING READ (land = -1)",
                 dict(order=1), JOINT, (-1,)),
                ("sequential, strict + THE BLOCKING READ (land = -1)",
                 {}, STRICT, (-1,))]
        only = os.environ.get("SCH_ROW")
        refs = topology_refs(g2, DEL, xs)
        random.seed(5)
        x64 = [random.uniform(-1, 1) for _ in range(64)]
        DEL2 = [3, 7]
        refs2 = topology_refs(g2, DEL2, x64)
        for n, (tag, base, rng, lnd) in enumerate(rows):
            if only is not None and int(only) != n:
                continue
            print("   [%d] %s" % (n, tag), flush=True)
            _t, sl, _x = action_search(banks, l0, D0, base, quiet=True,
                                       ranges=rng, numeric=False, lands=lnd)
            print("       %d machines pass the delay-loop filter" % len(sl),
                  flush=True)
            byref = collections.Counter()
            keep = []
            for k, mm in enumerate(sl):
                if k and k % 10000 == 0:
                    print("          ... %d/%d, %d hits so far"
                          % (k, len(sl), len(keep)), flush=True)
                outs = machine_outputs(mm, g2, DEL, xs)
                h = match_refs(outs, refs)
                if not h:
                    continue
                o2 = machine_outputs(mm, g2, DEL2, x64)
                h2 = match_refs(o2, refs2)
                names2 = {a for a, _i, _e, _s in h2}
                h = [t for t in h if t[0] in names2]
                if h:
                    keep.append((mm, h))
                    for nmr, _i, _e, _s in h:
                        byref[nmr] += 1
            print("       %d machines reproduce SOME topology at BOTH delay sets"
                  % len(keep), flush=True)
            for nmr, cnt in byref.most_common():
                print("          %-46s x%d" % (nmr, cnt))
            if keep:
                for nm, ix in (("SRC 0x00 reads", SRC0),
                               ("read lands +n", LAND),
                               ("write data from", WSRC),
                               #  escact and tbsh were ENUMERATED all along and
                               #  never printed.  tbsh in particular is a live
                               #  cross-block constraint -- see sec_blockread().
                               ("escact", ESCACT), ("tempB >>1", TBSH),
                               ("ACTION 0x00", F00), ("ACTION 0x19", F19),
                               ("ACTION 0x0B", F0B)):
                    v = collections.Counter(
                        (eff_str(EFFECTS[mm[ix]]) if ix in (F00, F19, F0B)
                         else mm[ix]) for mm, _h in keep)
                    print("       %-16s %-8s %s"
                          % (nm, "FORCED" if len(v) == 1 else "%d" % len(v),
                             "  ".join("%s x%d" % (a, b)
                                       for a, b in v.most_common(6))))
                for nm, ix in (("ACTION 0x00", F00), ("ACTION 0x19", F19),
                               ("ACTION 0x0B", F0B)):
                    for half, sel in (("acc op ", 0), ("capture", 1)):
                        v = collections.Counter(EFFECTS[mm[ix]][sel] or "-"
                                                for mm, _h in keep)
                        print("       %-11s %-8s %-8s %s"
                              % (nm, half,
                                 "FORCED" if len(v) == 1 else "%d" % len(v),
                                 "  ".join("%s x%d" % (a, b)
                                           for a, b in v.most_common())))
        print()


# ==========================================================================
#  15. ★★★ THE BLOCKING READ -- the shared assumption behind BOTH halves of
#      the reverb-vs-SINGLE-DELAY contradiction
#
#  `action-field.md' sect. 8 tabulates TWO rows of disagreement:
#
#      SRC 0x00        reverb: DR (52696/52696)  |  SINGLE DELAY: never DR (0/5145)
#      read latency    reverb: land in {0,1}     |  SINGLE DELAY: land = -1 FORCED
#
#  They are ONE row.  `land = -1' is the BLOCKING read: the DRAM read word's own
#  operand bus already carries the word it fetched.  `LANDS' omits it, so in the
#  reverb's search space the fresh delay sample could reach the ALU by exactly
#  ONE route -- `SRC 0x00 = DR' at slot 1.  Enumerate the blocking read and a
#  SECOND route opens that needs no `SRC 0x00' at all:
#
#      slot 0  880.1.60.2D4  is an ESCAPE word whose ACTION is 0x14, the
#                            ANCHORED `tempB <- bus'.  Under a blocking read its
#                            bus IS w[r], so tempB <- w[r] at slot 0;
#      slot 3  012.2.00.680  reads SRC 0x1A = tempB and computes acc <- tB + P
#                            = w[r] + t[r-1], which is the comb multiplicand
#                            sect. 14 published -- unchanged.
#
#  dark-words.md sect. 10.3 named this ACTION 0x14 and asked that any nested-comb
#  model satisfy both halves of the read/write pair.  This is that model.
# ==========================================================================
def sec_blockread(C, rom, imgs, names):
    parts = set((os.environ.get("BLK_PARTS") or
                 "degeneracy,route,control,search").split(","))
    banks, l0, l1, D0, D1 = _ladder_inputs(C, rom, imgs)
    g2 = [banks[16][c] for c in l0][:2]

    # ------------------------------------------------- 15a. the degeneracy
    if "degeneracy" in parts:
        print("=" * 76)
        print("15a. ★ `land = 0' AND `land = 1' ARE THE SAME MACHINE")
        print("=" * 76)
        print("   exec_rep appends the read at tick+land and pops it at the")
        print("   START of a slot when deadline <= tick.  The read is at slot 0,")
        print("   so 0+0 and 0+1 are BOTH first visible at slot 1.  Every")
        print("   published row's LAND split is therefore exactly 50/50 -- and")
        print("   it is (8260/8260 generous, 56/56 strict, 6370/6370 joint).")
        random.seed(3)
        NE = len(EFFECTS)
        rows = collections.Counter()
        random.seed(7)
        xs = [random.uniform(-1, 1) for _ in range(32)]
        for _ in range(4000):
            a = dict(f00=random.randrange(NE), f19=random.randrange(NE),
                     f0b=random.randrange(NE), src0=random.choice(SRC0_CANDS),
                     wsrc=random.choice(WSRCS), wtrail=1,
                     escact=random.choice((0, 1)), tbsh=random.choice((0, 1)),
                     order=random.choice((0, 1)), noclr=random.choice((0, 1, 2)))
            s0, t0 = sym_rep(mach(land=0, **a))
            s1, t1 = sym_rep(mach(land=1, **a))
            rows["0 vs 1"] += ((s0, sorted(t0.items())) ==
                               (s1, sorted(t1.items())))
        print("   SYMBOLIC, 4000 random machines: identical %d / 4000"
              % rows["0 vs 1"])
        # ...AND THE COMPARISON MUST BE ABLE TO SAY `DIFFERENT'.
        for other in (2, -1):
            random.seed(19)
            same = 0
            for _ in range(300):
                a = dict(f00=random.randrange(NE), f19=random.randrange(NE),
                         f0b=random.randrange(NE),
                         src0=random.choice(SRC0_CANDS),
                         wsrc=random.choice(WSRCS), wtrail=1,
                         escact=random.choice((0, 1)),
                         tbsh=random.choice((0, 1)), order=1)
                same += (machine_outputs(mach(land=0, **a), g2, [3, 5], xs) ==
                         machine_outputs(mach(land=other, **a), g2, [3, 5], xs))
            print("   CONTROL land 0 vs %-2d on the real ladder: identical %d / 300"
                  "   <- MUST NOT be 300" % (other, same))
        print("   => `read lands +n: 2 values' is ONE machine counted twice, and")
        print("      the BLOCKING read (land = -1) -- the one SINGLE DELAY FORCES")
        print("      5145/5145 -- was never in the reverb's space at all.")
        print()

    # ----------------------------------------------------- 15b. the route
    if "route" in parts:
        print("=" * 76)
        print("15b. ★★ THE SECOND ROUTE, and it needs NOTHING from SRC 0x00")
        print("=" * 76)
        for i, sl in enumerate(MSLOTS):
            print("   slot %d %-16s %-4s src=%02X %-9s act=%02X -> %-12s accop=%d%s"
                  % (i, sl["word"], "ESC" if sl["esc"] else "", sl["src"],
                     SRC_TXT.get(sl["src"], "?"), sl["act"],
                     eff_str(act_effect(NOMINAL_M, sl["act"]))
                     if sl["act"] in (0x12, 0x13, 0x14, 0x15, 0x07) else "(OPEN)",
                     sl["accop"], " ST" if sl["store"] else ""))
        print("   ★ slot 0's ACTION 0x14 is ANCHORED: tempB <- bus.  With a")
        print("     BLOCKING read its bus is w[r], so the delay sample lands in")
        print("     tempB before slot 1 executes -- and slot 3 reads tempB.")
        m = mach(EFFECTS.index(("bus", "tA<-acc")),
                 EFFECTS.index(("", "tA<-bus")), EFFECTS.index(("", "")),
                 "zero", "bus", 1, -1, escact=1, tbsh=0, order=1)
        st, tr = sym_rep(m)
        print()
        print("   SYMBOLIC repetition, SRC 0x00 = ZERO, land = -1, escact = 1:")
        print("       MULTIPLICAND = %s        (P = t[r-1], N = w[r])"
              % show_form(tr["MULT"]))
        print("       write value  = %s" % show_form(tr["W"][0]))
        print("       exit tA=%s tB=%s acc=%s DR=%s"
              % (show_form(st[R_TA]), show_form(st[R_TB]),
                 show_form(st[R_ACC]), show_form(st[R_DR])))
        print("       delay-loop filter -> %s" % (loop_ok(m) or "REJECTED"))
        print("   => the SAME multiplicand w[r] + t[r-1] sect. 14 published, with")
        print("      SRC 0x00 reading NOTHING.")
        print()

    # --------------------------------------------------- 15c. the controls
    if "control" in parts:
        print("=" * 76)
        print("15c. ★ CONTROLS -- each shown able to say NO")
        print("=" * 76)
        # (1) kill the route by refusing the escape word its lo12: the machine
        #     above must STOP passing the loop filter.
        for tag, kw in (("escact = 1 (the route open)", dict(escact=1)),
                        ("escact = 0 (read word's ACTION 0x14 ignored)",
                         dict(escact=0))):
            m = mach(EFFECTS.index(("bus", "tA<-acc")),
                     EFFECTS.index(("", "tA<-bus")), EFFECTS.index(("", "")),
                     "zero", "bus", 1, -1, tbsh=0, order=1, **kw)
            lp = loop_ok(m)
            print("   %-44s loop filter -> %s"
                  % (tag, lp if lp else "REJECTED   <- SAYS NO"))
        # (2) and the same machine with a PIPELINED read: the route needs the
        #     block, so it must die there too.
        for ld in (0, 1, 2):
            m = mach(EFFECTS.index(("bus", "tA<-acc")),
                     EFFECTS.index(("", "tA<-bus")), EFFECTS.index(("", "")),
                     "zero", "bus", 1, ld, escact=1, tbsh=0, order=1)
            lp = loop_ok(m)
            print("   %-44s loop filter -> %s"
                  % ("land = %d (pipelined, SRC 0x00 = zero)" % ld,
                     lp if lp else "REJECTED   <- SAYS NO"))
        print()

    # ----------------------------------------------------- 15d. the search
    if "search" in parts:
        print("=" * 76)
        print("15d. ★★★ THE SEARCH -- run sect. 14e rows 8, 9, 10")
        print("=" * 76)
        print("   SCH_PARTS=search SCH_ROW=8   strict  + blocking read")
        print("   SCH_PARTS=search SCH_ROW=9   joint   + blocking read")
        print("   SCH_PARTS=search SCH_ROW=10  sequential strict + blocking")
        print("   SCH_PARTS=search SCH_ROW=1   the PUBLISHED strict row, which")
        print("                                must still return 112.")
        print()


def loop_ok_ctl(slots, extra, m):
    global MSLOTS, EXTRA_ACT
    sv, se = MSLOTS, EXTRA_ACT
    MSLOTS, EXTRA_ACT = slots, extra
    try:
        return loop_ok(m)
    finally:
        MSLOTS, EXTRA_ACT = sv, se


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
        "separator", "discriminator", "schroeder", "control", "action",
        "singledelay"}
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
    if "schroeder" in want:
        sec_schroeder(args.terms)
    if "control" in want:
        sec_control(C, rom, imgs, names)
    if "action" in want:
        sec_action(C, rom, imgs, names)
    if "singledelay" in want:
        sec_singledelay(C, rom, imgs, names)
    if "price" in want:
        sec_price(C, rom, imgs, names)
    if "adjudicate" in want:
        sec_adjudicate(C, rom, imgs, names)
    if "adder" in want:
        sec_adder(C, rom, imgs, names)
    if "schroeder2" in want:
        sec_schroeder2(C, rom, imgs, names)
    if "blockread" in want:
        sec_blockread(C, rom, imgs, names)


if __name__ == "__main__":
    main()
