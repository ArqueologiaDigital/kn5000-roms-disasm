#!/usr/bin/env python3
"""acc_adjudicate.py -- ADJUDICATE the accumulator model across THREE contexts
at once.

WHY THIS EXISTS.  Three concurrent passes each solved a piece of the uPD6383 ALU
in its own model, and two of them reached determinations that CANNOT BOTH BE
TRUE:

  * TARGET 3 (`lfo_ramp.py publish') FORCES `order = act_first' -- the lo12
    ACTION acts BEFORE the hi12[3:1] accumulator operation -- as a singleton
    marginal over 432 machines and 29 blocks.
  * TARGET 2 (`r1_allpass_solve.py singledelay') FORCES that ACTION 0x00 routes
    the bus into the accumulator, over 5145 survivors -- but every one of those
    survivors was computed at `actfirst = 0', the OPPOSITE order, because
    `sec_singledelay' never passed the parameter.  Its block cannot run at
    act_first: its `000.2.48.000' has hi12[3:1] == 0 (`acc <- P'), which
    overwrites anything an earlier ACTION did to the accumulator.

Neither pass enumerated the other's parameter, so neither could see the clash.
This tool puts BOTH blocks -- and the PARAMETRIC EQ biquad, which is the
project's strongest numeric result and must not regress -- into ONE search over
ONE declared model space, and reports what survives all three.

The space deliberately contains a fourth reading that neither pass had:

    ADDER      acc_new = FB(f31) + P(f31) + (ACTION == 0x00 ? +-bus : 0)

i.e. the ACTION is not a step that happens before or after the operation, it is
a THIRD INPUT to the accumulator's adder.  Both blocks demand the same
expression at the word where their sum forms --

    LFO  082.2.00.1C0   f31 = 1, ACTION 0x00, bus = phase  ->  acc = bus + P
    SD   000.2.48.000   f31 = 0, ACTION 0x00, bus = x      ->  acc = P + bus

-- which no sequential ordering delivers, and which an adder does.

    python3 dsp/tools/acc_adjudicate.py            # all sections
    python3 dsp/tools/acc_adjudicate.py biquad     # just one

Sections
    biquad   the PARAMETRIC EQ 9-word section: which models are BIT-IDENTICAL to
             the shipping ALU (and therefore keep its 0.094 dB validation)
    single   SINGLE DELAY (algo 9 w5..w9) with a REAL D-RAM array, the measured
             pointer walk, and a RANDOMISED entering state
    lfo      all 29 LFO blocks: ramp at the ROM's own rate, and wrap at 2**23
    joint    the intersection -- the deliverable

Standard library only.  Every number printed is computed here from the ROM.
"""
import collections
import itertools
import os
import random
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import dsp_disasm as DIS                                    # noqa: E402
import lfo_ramp as L                                        # noqa: E402

MASK24, MASK23 = (1 << 24) - 1, (1 << 23) - 1


def s24(v):
    v &= MASK24
    return v - (1 << 24) if v & (1 << 23) else v


def s8(v):
    v &= 0xff
    return v - 256 if v & 0x80 else v


def fmt(w):
    return "%03X.%X.%02X.%03X" % (DIS.hi12(w), DIS.class4(w),
                                  DIS.addr8(w), DIS.lo12(w))


# --------------------------------------------------------------------------
#  THE DECLARED MODEL SPACE
# --------------------------------------------------------------------------
#  ORDER
#     act_last   hi12[3:1] operates, THEN the ACTION           (what SHIPS)
#     act_first  the ACTION, THEN hi12[3:1]                    (TARGET 3)
#     adder      one accumulator input:  FB + Pterm + busterm  (new here)
ORDER = ("act_last", "act_first", "adder")

#  ACTION 0x00's accumulator effect.  For the two sequential orders this is a
#  step; for `adder' it is the sign with which the bus enters the adder.
ACT00 = ("none", "add", "sub", "load", "rload")

#  hi12 bit 4 -- the store AND the clear, and WHEN they happen.
#     before          mem[p] <- acc ; acc := 0   BEFORE the ALU   (what SHIPS)
#     after           the same, but at the END of the word
#     st_before_clr_after   store early, clear late
STTIME = ("before", "after", "st_before_clr_after")

#  the LFO gate on the bit-4 store, from analysis/lfo-ramp.md Part II sect. 8.3
STGATE = ("always", "b7_f31_1_off", "b7_ne2_off", "b7_f31_1_keepclear")

#  what hi12[3:1] == 2 does
OP2 = ("hold", "and_coef", "and_mask23")


def gate_of(stgate, b7, f):
    """-> (do_store, do_clear)"""
    if stgate == "always":
        return True, True
    if stgate == "b7_f31_1_off":
        return (False, False) if (b7 and f == 1) else (True, True)
    if stgate == "b7_ne2_off":
        return (False, False) if (b7 and f != 2) else (True, True)
    if stgate == "b7_f31_1_keepclear":
        return (False, True) if (b7 and f == 1) else (True, True)
    raise KeyError(stgate)


class Machine(object):
    """One candidate.  The ONLY thing that varies between contexts is which
    sources the context can supply; the word semantics live here, once."""

    __slots__ = ("order", "act00", "sttime", "stgate", "op2", "act19",
                 "src00", "src08", "wrap", "src11", "dest07")

    def __init__(self, order, act00, sttime, stgate, op2,
                 act19="tA<-bus", src00="mem", src08="unity", wrap="sat",
                 src11="mem", dest07="mem"):
        self.order, self.act00, self.sttime = order, act00, sttime
        self.stgate, self.op2, self.act19 = stgate, op2, act19
        self.src00, self.src08, self.wrap = src00, src08, wrap
        self.src11, self.dest07 = src11, dest07

    def key(self):
        """The parameters BOTH the biquad and the LFO can see.  SINGLE DELAY has
        no `hi12[3:1] == 2' word and never reads back its own bit-4 store, so it
        constrains only the first four -- `key4()'."""
        return (self.order, self.act00, self.sttime, self.stgate,
                self.op2, self.wrap)

    def key4(self):
        return (self.order, self.act00, self.sttime, self.stgate)

    def __repr__(self):
        return "%-9s act00=%-5s st=%-19s gate=%-18s op2=%s" % self.key()


class State(object):
    __slots__ = ("acc", "P", "ta", "tb", "mem", "p", "dr", "scratch")

    def __init__(self, rng=None):
        r = (lambda: rng.randrange(-(1 << 23), 1 << 23)) if rng else (lambda: 0)
        self.acc, self.P = r(), r()
        self.ta = self.tb = 0 if rng is None else rng.randrange(0, 1 << 24)
        self.mem = collections.defaultdict(int)
        self.p = 0
        self.dr = 0
        self.scratch = 0


def step(m, st, w, coef, rng, dram=None, unknown=None):
    """Execute ONE word under machine `m'.  Returns False if the word needs
    something this model cannot supply (the candidate is then rejected, never
    guessed at).  `dram' is the external delay-RAM hook for SINGLE DELAY."""
    hi, cl = DIS.hi12(w), DIS.class4(w)
    src, act = DIS.lo_src(w), DIS.lo_act(w)
    f, b7 = DIS.hi_f31(hi), (hi >> 7) & 1
    isA = DIS.coeff_consumer(w)
    nxt = st.p + (s8(DIS.addr8(w)) if DIS.ptr_postinc(w) else 0)
    nxt &= 0xff

    # ---- the operand bus, latched FIRST (anchored; not a free parameter) ----
    if src == 0x07:
        bus = s24(st.mem[st.p])
    elif src == 0x10:
        bus = s24(st.acc)
    elif src == 0x19:
        bus = s24(st.ta)
    elif src == 0x1A:
        bus = s24(st.tb) >> 1
    elif src == 0x0B:
        bus = s24(st.dr)
    elif src == 0x00:
        bus = {"mem": lambda: s24(st.mem[st.p]), "P": lambda: s24(st.P),
               "acc": lambda: s24(st.acc), "zero": lambda: 0,
               "DR": lambda: s24(st.dr), "tA": lambda: s24(st.ta)}[m.src00]()
    elif src == 0x08:
        bus = {"unity": lambda: MASK23, "zero": lambda: 0,
               "acc": lambda: s24(st.acc), "mem": lambda: s24(st.mem[st.p]),
               "P": lambda: s24(st.P),
               "coef": lambda: s24(coef) if coef is not None else 0}[m.src08]()
    elif src == 0x11:
        bus = {"mem": lambda: s24(st.mem[st.p]), "acc": lambda: s24(st.acc),
               "P": lambda: s24(st.P), "tA": lambda: s24(st.ta),
               "tB": lambda: s24(st.tb), "unity": lambda: MASK23,
               "zero": lambda: 0}[m.src11]()
    elif unknown is not None:
        bus = unknown()
    else:
        return False

    def do_store():
        v = st.acc
        if m.wrap == "sat":
            v = max(-(1 << 23), min(MASK23, v))
        elif m.wrap == "wrap23":
            v = v & MASK23
        elif m.wrap == "f31_2_and_coef":
            v = (v & coef) if (f == 2 and coef is not None) \
                else max(-(1 << 23), min(MASK23, v))
        elif m.wrap == "b7_and_coef":
            v = (v & coef) if (b7 and coef is not None) \
                else max(-(1 << 23), min(MASK23, v))
        st.mem[st.p] = v & MASK24

    store = bool(hi & 0x10)
    dost, doclr = gate_of(m.stgate, b7, f) if store else (False, False)
    if store and dost and m.sttime in ("before", "st_before_clr_after"):
        do_store()
    if store and doclr and m.sttime == "before":
        st.acc = 0

    # ---- the ACTION's capture half (order-independent: it reads the bus) ----
    def capture():
        if act == 0x13:
            st.ta = bus & MASK24
        elif act == 0x14:
            st.tb = bus & MASK24
        elif act == 0x07:
            # R2 FORCED that this destination is MODE-DEPENDENT, so "somewhere
            # that is not this D-RAM cell" is a declared alternative, not a dodge.
            if m.dest07 == "mem":
                st.mem[st.p] = bus & MASK24
        elif act == 0x19:
            if m.act19 == "tA<-bus":
                st.ta = bus & MASK24
            elif m.act19 == "tA<-acc":
                st.ta = st.acc & MASK24
            elif m.act19 == "tB<-bus":
                st.tb = bus & MASK24

    def accop(cur):
        if f == 0:
            return st.P
        if f == 1:
            return cur + st.P
        if f == 2:
            if m.op2 == "and_coef":
                return cur & (coef if coef is not None else MASK24)
            if m.op2 == "and_mask23":
                return cur & MASK23
            return cur
        return None                       # f31 in 3..7: NOT decoded

    def actop(cur):
        if act != 0x00:
            return cur
        return {"none": cur, "add": cur + bus, "sub": cur - bus,
                "load": bus, "rload": bus - cur}[m.act00]

    if act not in (0x00, 0x07, 0x12, 0x13, 0x14, 0x15, 0x19, 0x0B):
        return False
    if f > 2:
        return False

    if m.order == "act_first":
        st.acc = actop(st.acc)
        capture()
        st.acc = accop(st.acc)
    elif m.order == "act_last":
        st.acc = accop(st.acc)
        st.acc = actop(st.acc)
        capture()
    else:                                   # adder
        fb = 0 if f == 0 else st.acc
        pt = 0 if f == 2 else st.P
        bt = 0
        if act == 0x00:
            bt = {"none": 0, "add": bus, "sub": -bus,
                  "load": bus, "rload": bus}[m.act00]
            if m.act00 in ("load", "rload"):
                fb = bus if m.act00 == "load" else -fb
                bt = 0 if m.act00 == "load" else bus
        acc = fb + pt + bt if f != 2 else (fb + bt)
        if f == 2 and m.op2 == "and_coef" and coef is not None:
            acc &= coef
        elif f == 2 and m.op2 == "and_mask23":
            acc &= MASK23
        st.acc = acc
        capture()

    if store and dost and m.sttime == "after":
        do_store()
    if store and doclr and m.sttime in ("after", "st_before_clr_after"):
        st.acc = 0

    if isA:
        if coef is None:
            return False
        st.P = s24(coef) if (m.src08 == "unity" and src == 0x08) \
            else (s24(coef) * bus) >> 23

    if dram is not None and (hi & 0x800) and cl == 1:
        dram(w, bus, st)

    st.p = nxt
    return True


# --------------------------------------------------------------------------
#  CONTEXT B -- the PARAMETRIC EQ biquad.  It must not regress.
# --------------------------------------------------------------------------
#  The nine words are the SAME array tools/kn5000_dsp_alu_mirror.py builds its
#  acceptance test from (algo 39 words 5..13, ten identical repetitions).
PEQ = (0x0000A001D3, 0x0212A01412, 0x0202A011D5, 0x0202A011D4,
       0x0202A001D5, 0x01022FF687, 0x0804816415, 0x0212AFF407,
       0x0000203647)

SHIPPED = Machine("act_last", "none", "before", "always", "hold")


def peq_impulse(m, coefs, n=64, amp=1 << 22):
    """The section's impulse response under machine `m' -- the same driving
    convention as the generated C++ mirror (the band input arrives in BOTH the
    accumulator and the product latch)."""
    st = State()
    out = []
    for t in range(n):
        x = amp if t == 0 else 0
        st.acc = x
        st.P = x
        st.p = 0
        cur = 0
        for w in PEQ:
            c = None
            if DIS.cursor_fetch(w):
                c = coefs[cur % len(coefs)]
            ok = step(m, st, w, c, None)
            if not ok:
                return None
            if DIS.coeff_consumer(w):
                cur += 1
        out.append(max(-(1 << 23), min(MASK23, st.acc)))
    return out


def sec_biquad():
    L.hdr("biquad -- which models stay BIT-IDENTICAL to the shipping ALU?")
    print("""The PARAMETRIC EQ section reproduces the firmware's own bilinear
designer to 0.094 dB under the SHIPPED model.  Any candidate that is
observationally identical to the shipped model ON THIS SECTION inherits that
validation; any candidate that is not has to earn 57 dB back by itself.
The section carries NO ACTION 0x00 word, so `order' and `act00' cannot show
here -- which is exactly why the biquad never constrained them.""")
    coefs = [0x400000, 0x200000, 0x100000, 0x080000, 0x040000, 0x020000]
    ref = peq_impulse(SHIPPED, coefs)
    assert ref is not None
    acts = sorted({DIS.lo_act(w) for w in PEQ})
    print("\n   the section's ACTION codes: %s"
          % " ".join("%02X" % a for a in acts))
    print("   its bit-4 store words, by (bit7, hi12[3:1]): %s"
          % dict(collections.Counter(
              ((DIS.hi12(w) >> 7) & 1, DIS.hi_f31(DIS.hi12(w)))
              for w in PEQ if DIS.hi12(w) & 0x10)))
    rows = []
    for order, act00, sttime, stgate, op2, wrap in itertools.product(
            ORDER, ACT00, STTIME, STGATE, OP2,
            ("sat", "wrap23", "f31_2_and_coef", "b7_and_coef")):
        m = Machine(order, act00, sttime, stgate, op2, wrap=wrap)
        r = peq_impulse(m, coefs)
        rows.append((m, r is not None and r == ref))
    ok = [m for m, good in rows if good]
    print("\n   %d of %d enumerated models are BIT-IDENTICAL on the section"
          % (len(ok), len(rows)))
    for nm, ix in (("order", 0), ("act00", 1), ("sttime", 2), ("stgate", 3),
                   ("op2", 4), ("wrap", 5)):
        v = collections.Counter(m.key()[ix] for m in ok)
        print("      %-8s %-8s %s"
              % (nm, "FORCED" if len(v) == 1 else "%d values" % len(v),
                 "  ".join("%s x%d" % (a, b) for a, b in v.most_common())))
    for ix, nm in ((2, "store timing"), (5, "store wrap")):
        bad = collections.Counter(m.key()[ix] for m, good in rows if not good)
        print("   models that CHANGE the section, by %s: %s" % (nm, dict(bad)))
    return set(m.key() for m in ok)


# --------------------------------------------------------------------------
#  CONTEXT S -- SINGLE DELAY (algo 9), with a REAL D-RAM and a randomised entry
# --------------------------------------------------------------------------
def sd_words():
    a2i = L.algo_to_image()
    return a2i[9][2][5:10]


class Line(object):
    __slots__ = ("buf", "n", "i", "wrote")

    def __init__(self, n):
        self.n, self.buf, self.i, self.wrote = n, [0.0] * n, 0, []

    def read(self):
        return self.buf[self.i]

    def write(self, v):
        self.buf[self.i] = v
        self.wrote.append(v)

    def advance(self):
        self.i = (self.i + 1) % self.n


def comb_ref(fb, D, x):
    ln, out = Line(D), []
    for xn in x:
        v = xn + fb * ln.read()
        ln.write(v)
        out.append(v)
        ln.advance()
    return out


def sd_run(m, words, fb, D, x, blocking=True):
    """Run the block once per sample with a REAL 256-cell D-RAM, the MEASURED
    pointer walk, and every register the block does not itself set RANDOMISED.
    The input is deposited in the cell the walk reads, not injected into a
    register of the searcher's choosing."""
    rng = random.Random(20260726)
    ln = Line(D)
    p0 = 0x80
    incell = p0
    for w in words:                       # find the cell SRC 0x00 will read
        if DIS.lo_src(w) == 0x00:
            break
        if DIS.ptr_postinc(w):
            incell = (incell + s8(DIS.addr8(w))) & 0xff
    st = State(rng)
    for xn in x:
        st.acc = rng.randrange(-(1 << 23), 1 << 23)
        st.P = rng.randrange(-(1 << 23), 1 << 23)
        st.ta = rng.randrange(0, 1 << 24)
        st.tb = rng.randrange(0, 1 << 24)
        st.p = p0
        st.mem[incell] = int(xn) & MASK24
        st.dr = 0

        def dram(w, bus, s):
            lo = DIS.lo12(w)
            wr = (DIS.addr8(w) & 0xf0) == 0x20
            if wr:
                ln.write(bus)
            else:
                s.dr = int(ln.read()) & MASK24

        # a BLOCKING read: the reading word's own bus already sees the word.
        # (FORCED at 5145/5145 by r1_allpass_solve.py singledelay.)
        for w in words:
            if blocking and (DIS.hi12(w) & 0x800) and DIS.class4(w) == 1 \
                    and (DIS.addr8(w) & 0xf0) == 0x60:
                st.dr = int(ln.read()) & MASK24
            c = None
            if DIS.cursor_fetch(w):
                c = int(fb * (1 << 23))
            if not step(m, st, w, c, rng, dram=dram,
                        unknown=lambda: rng.randrange(-(1 << 23), 1 << 23)):
                return None
        ln.advance()
    return ln.wrote


def sec_single(admissible=None):
    L.hdr("single -- SINGLE DELAY (algo 9) with a real D-RAM and a random entry")
    words = sd_words()
    for w in words:
        print("     %-16s src=%02X act=%02X f31=%d%s%s"
              % (fmt(w), DIS.lo_src(w), DIS.lo_act(w),
                 DIS.hi_f31(DIS.hi12(w)),
                 " ST" if DIS.hi12(w) & 0x10 else "",
                 "  ESC" if DIS.hi12(w) & 0x800 else ""))
    print("""
   The previous pass injected x into one of six REGISTERS and started every
   sample from an all-zero state.  Here the input is written to the D-RAM cell
   the MEASURED pointer walk reads, and every register the block does not set is
   randomised per sample -- so a machine that leans on an undecoded value fails.""")
    fb, D = 0.3, 7
    rng = random.Random(3)
    amp = 1 << 18
    x = [rng.randrange(-amp, amp) for _ in range(24)]
    ref = comb_ref(fb, D, x)
    hits = []
    space = list(itertools.product(ORDER, ACT00, STTIME, STGATE,
                                   ("tA<-bus", "tA<-acc", "tB<-bus"),
                                   ("mem", "P", "acc", "zero", "DR", "tA")))
    for order, act00, sttime, stgate, act19, src00 in space:
        m = Machine(order, act00, sttime, stgate, "hold",
                    act19=act19, src00=src00)
        if admissible is not None and m.key4() not in admissible:
            continue
        w = sd_run(m, words, fb, D, x)
        if w is None or len(w) != len(ref):
            continue
        den = sum(v * v for v in w)
        if den < 1e-6:
            continue
        sc = sum(a * b for a, b in zip(w, ref)) / den
        if abs(sc) < 1e-6:
            continue
        mx = max(abs(v) for v in ref)
        if max(abs(sc * a - b) for a, b in zip(w, ref)) < 1e-4 * mx:
            hits.append(m)
    print("\n   %d of %d enumerated machines reproduce v[n] = x[n] + fb*v[n-D]"
          % (len(hits), len(space)))
    for nm, f in (("order", lambda m: m.order), ("act00", lambda m: m.act00),
                  ("sttime", lambda m: m.sttime), ("stgate", lambda m: m.stgate),
                  ("act19", lambda m: m.act19), ("src00", lambda m: m.src00)):
        v = collections.Counter(f(m) for m in hits)
        print("      %-8s %-8s %s"
              % (nm, "FORCED" if len(v) == 1 else "%d values" % len(v),
                 "  ".join("%s x%d" % (a, b) for a, b in v.most_common())))
    return set(m.key4() for m in hits), hits


# --------------------------------------------------------------------------
#  CONTEXT L -- all 29 LFO blocks
# --------------------------------------------------------------------------
def lfo_run(m, words, coefs, nframes, rng, qcell, preset=None):
    st = State(rng)
    if preset is not None:
        st.mem[qcell] = preset
    hist = []
    for _ in range(nframes):
        st.acc = rng.randrange(-(1 << 23), 1 << 23)
        st.P = rng.randrange(-(1 << 23), 1 << 23)
        st.ta = rng.randrange(0, 1 << 24)
        st.tb = rng.randrange(0, 1 << 24)
        st.p = 0
        for k, w in enumerate(words):
            if not step(m, st, w, coefs[k], rng,
                        unknown=lambda: rng.randrange(-(1 << 23), 1 << 23)):
                return None
        hist.append(st.mem[qcell] & MASK24)
    return hist


def sec_lfo(admissible=None):
    L.hdr("lfo -- all 29 blocks, the ramp and the 2**23 wrap")
    pool = L.publish_blocks()
    print("   %d blocks, %d programs" % (len(pool), len({r[0] for r in pool})))
    space = []
    for (order, act00, sttime, stgate, op2, src08, wrap,
         src11, dest07) in itertools.product(
            ORDER, ACT00, STTIME, STGATE, OP2,
            ("unity", "zero", "acc", "mem", "P", "coef"),
            ("sat", "wrap23", "f31_2_and_coef", "b7_and_coef"),
            ("mem", "acc", "P", "tA", "tB", "unity", "zero"),
            ("mem", "elsewhere")):
        m = Machine(order, act00, sttime, stgate, op2, src08=src08, wrap=wrap,
                    src11=src11, dest07=dest07)
        if admissible is not None and m.key() not in admissible:
            continue
        space.append(m)
    print("   candidate machines: %d" % len(space))
    seed = [r for r in pool if r[0] in (1, 4)][:2]
    st1 = []
    for m in space:
        ok = True
        for (i, a, e, words, coefs, inc, q) in seed:
            h = lfo_run(m, words, coefs, 10, random.Random(5 + i), q)
            if h is None or not L.is_ramp(h, inc):
                ok = False
                break
        if ok:
            st1.append(m)
    print("   stage 1 (2 blocks)              : %d survive" % len(st1))
    st2 = []
    for m in st1:
        ok = True
        for (i, a, e, words, coefs, inc, q) in pool:
            h = lfo_run(m, words, coefs, 30, random.Random(97 + i * 13 + a), q)
            if h is None or not L.is_ramp(h, inc):
                ok = False
                break
        if ok:
            st2.append(m)
    print("   stage 2 (ALL %d blocks)          : %d survive" % (len(pool), len(st2)))
    st3 = []
    for m in st2:
        ok = True
        for (i, a, e, words, coefs, inc, q) in pool:
            h = lfo_run(m, words, coefs, 6, random.Random(3 + i), q,
                        preset=(1 << 23) - 2 * inc)
            want = [((1 << 23) - 2 * inc + inc * (k + 1)) % (1 << 23)
                    for k in range(6)]
            if h is None or h != want:
                ok = False
                break
        if ok:
            st3.append(m)
    print("   stage 3 (the 2**23 wrap)        : %d survive" % len(st3))
    for nm, f in (("order", lambda m: m.order), ("act00", lambda m: m.act00),
                  ("sttime", lambda m: m.sttime),
                  ("stgate", lambda m: m.stgate), ("op2", lambda m: m.op2),
                  ("src08", lambda m: m.src08), ("wrap", lambda m: m.wrap),
                  ("src11", lambda m: m.src11), ("dest07", lambda m: m.dest07)):
        v = collections.Counter(f(m) for m in st3)
        print("      %-8s %-8s %s"
              % (nm, "FORCED" if len(v) == 1 else "%d values" % len(v),
                 "  ".join("%s x%d" % (a, b) for a, b in v.most_common())))
    return set(m.key() for m in st3), st3


def main():
    want = set(sys.argv[1:]) or {"biquad", "single", "lfo", "joint"}
    B = S = LL = None
    if "biquad" in want or "joint" in want:
        B = sec_biquad()
    if "single" in want or "joint" in want:
        S, _ = sec_single()
    if "lfo" in want or "joint" in want:
        LL, _ = sec_lfo()
    if "joint" in want:
        L.hdr("joint -- the intersection, which is the deliverable")
        print("""   biquad and LFO are scored on (order, act00, sttime, stgate,
   op2, wrap); SINGLE DELAY has no hi12[3:1] == 2 word and never reads back its
   own bit-4 store, so it is scored on the first FOUR and joined on those.""")
        print("\n   biquad-identical models (6 params) : %d" % len(B))
        print("   LFO models              (6 params) : %d" % len(LL))
        print("   SINGLE DELAY models     (4 params) : %d" % len(S))
        print("   biquad AND lfo                     : %d" % len(B & LL))
        print("   biquad, 4-param projection AND SD  : %d"
              % len({k[:4] for k in B} & S))
        print("   lfo,    4-param projection AND SD  : %d"
              % len({k[:4] for k in LL} & S))
        j = sorted(k for k in (B & LL) if k[:4] in S)
        print("   ★ ALL THREE                        : %d" % len(j))
        for k in j:
            print("        %-9s act00=%-5s st=%-8s gate=%-20s op2=%-5s wrap=%s" % k)
        for ix, nm in ((0, "order"), (1, "act00"), (2, "sttime"),
                       (3, "stgate"), (4, "op2"), (5, "wrap")):
            v = collections.Counter(k[ix] for k in j)
            print("      %-8s %-8s %s"
                  % (nm, "FORCED" if len(v) == 1 else "%d values" % len(v),
                     "  ".join("%s x%d" % (a, b) for a, b in v.most_common())))
        if not j:
            print("\n   NO MODEL IN THE DECLARED SPACE SATISFIES ALL THREE.")


if __name__ == "__main__":
    main()
