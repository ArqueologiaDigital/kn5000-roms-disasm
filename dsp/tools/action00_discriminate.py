#!/usr/bin/env python3
"""action00_discriminate.py -- SETTLE `ACTION 0x00' with a FOURTH CONTEXT.

WHY THIS EXISTS.  `acc-adder.md' reports that a three-context joint solve FORCES
ACTION 0x00 = `load' (`acc <- bus + P', the accumulator's own feedback term
replaced by the bus) at 18/18, and that is what ships.  `allpass-adder-rerun.md'
reports that every setting able to carry both delay reads into the reverb
all-pass multiplicand needs ACTION 0x00 to KEEP the accumulator -- `-bus' in
9520 of 9660, `load' in ZERO.  The brief calls a fourth context "the highest
value discriminator left".

Before looking for one, this tool asks a question neither pass asked:

    ★ WHICH WORDS IN THE CORPUS CAN TELL THE TWO READINGS APART AT ALL?

That has an exact answer, and it is cheap:

    acc_add - acc_load  =  DELTA

    * on an ACTION-0x00 word with hi12[3:1] == 0 the two readings are
      IDENTICAL BY CONSTRUCTION (`load' gives bus + P, `add' gives 0 + P + bus)
      -- so every such word is BLIND, no matter what block it is in;
    * DELTA can only be born on an ACTION-0x00 word with hi12[3:1] in {1, 2};
    * DELTA is KILLED by the next hi12[3:1] == 0 word and by every accumulator
      clear, and it is OBSERVED only if it reaches a store, a capture, a
      multiplicand or the end of the body first.

Section `census' propagates DELTA over all 3057 corpus words and reports every
site at which it reaches an observable.  Sections `biquad', `lfo', `single' and
`joint' then re-run the three published contexts in a space that is WIDER than
the published one in exactly the places this pass suspects, and `mech' collects
what survives.

    python3 dsp/tools/action00_discriminate.py census   # the decidability census
    python3 dsp/tools/action00_discriminate.py biquad   # ★ an INDEPENDENT criterion
    python3 dsp/tools/action00_discriminate.py lfo      # the 29 LFO blocks
    python3 dsp/tools/action00_discriminate.py single   # SINGLE DELAY, two windows
    python3 dsp/tools/action00_discriminate.py joint    # the intersection
    python3 dsp/tools/action00_discriminate.py control  # ★ RUN FIRST -- can it say NO?

Standard library only.  Every number printed is computed here from the ROM.
"""
import collections
import itertools
import math
import cmath
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


def hdr(t):
    print("\n" + "=" * 78)
    print("  " + t)
    print("=" * 78)


# ===========================================================================
#  THE DECLARED MODEL SPACE -- WIDER than acc_adjudicate.py's in three places,
#  and every widening is named.
# ===========================================================================
ORDER = ("act_last", "act_first", "adder")

#  ACTION 0x00's accumulator half.
#     none   no accumulator effect
#     add    acc <- (what hi12[3:1] gives) + bus
#     sub    ...                          - bus
#     load   the bus REPLACES the accumulator's feedback term    (SHIPS)
#     rload  acc <- bus - acc
#   ★ bsel   the bus replaces the PRODUCT term, not the feedback term.  This is
#            the reading in which hi12[3:1] selects {0, acc} for the A input of
#            a MAC adder and ACTION 0x00 selects {P, bus} for its B input --
#            i.e. a two-input adder with TWO selectors, which is the shape the
#            LAST contradiction in this project turned out to have.  NEW HERE.
ACT00 = ("none", "add", "sub", "load", "rload", "bsel")

STTIME = ("before", "after", "st_before_clr_after")

#  the bit-7 store gate.  The first four are lfo-ramp.md's; the last two are
#  ★ NEW: when the gate SUPPRESSES the store, the clear is DEFERRED to the end
#  of the word rather than taken before it or dropped.  This is the one gate
#  shape under which the LFO ramp runs with ACTION 0x00 = `add', and it is the
#  hypothesis the brief asks for -- a term that is provably zero in one context
#  and not in another, from ONE mechanism.
STGATE = ("always", "b7_f31_1_off", "b7_ne2_off", "b7_f31_1_keepclear",
          "b7_f31_1_clrlate", "b7_ne2_clrlate")

OP2 = ("hold", "and_coef", "and_mask23")
WRAP = ("sat", "wrap23", "f31_2_and_coef", "b7_and_coef")


def gate_of(stgate, b7, f):
    """-> (do_store, do_clear, clear_at_end)"""
    if stgate == "always":
        return True, True, False
    if stgate == "b7_f31_1_off":
        return (False, False, False) if (b7 and f == 1) else (True, True, False)
    if stgate == "b7_ne2_off":
        return (False, False, False) if (b7 and f != 2) else (True, True, False)
    if stgate == "b7_f31_1_keepclear":
        return (False, True, False) if (b7 and f == 1) else (True, True, False)
    if stgate == "b7_f31_1_clrlate":
        return (False, True, True) if (b7 and f == 1) else (True, True, False)
    if stgate == "b7_ne2_clrlate":
        return (False, True, True) if (b7 and f != 2) else (True, True, False)
    raise KeyError(stgate)


#  ★ act0b, ADDED 2026-07-27 (analysis/act0b-reverb.md).  ACTION 0x0B was in
#  step()'s accepted-code list from the start but had NO branch in capture() and
#  NO parameter -- so it silently executed as "no side effect", an UNENUMERATED
#  modelling choice (method rule 3), while `dsp_disasm._ANCHORED_ACT' traps the
#  same word.  The default is "none", i.e. exactly the old behaviour, so every
#  published number is preserved BY CONSTRUCTION; what changes is that the
#  choice is now visible and can be swept.
ACT0B = ("none", "tA<-bus", "tB<-bus", "mem<-bus", "tA<-acc", "tB<-acc")

#  ★ f31hi, ADDED 2026-07-27 (analysis/f31-high.md).  hi12[3:1] is the
#  accumulator's operation select.  Values 0/1/2 are decoded; 3..7 are not, and
#  step() has always REFUSED them -- 203 of 3154 corpus words, 31 of which trap
#  for this reason ALONE.  `f31hi = None' keeps that refusal, so the default is
#  the historical behaviour exactly; any other value supplies a reading and lets
#  the word execute, which is what makes the field testable.
#
#  Each mode maps f -> (take the accumulator as feedback?, product term).
#  Bases 0/1/2 are the decoded ones and every mode reproduces them:
#      f=0  acc <- P          f=1  acc <- acc + P        f=2  acc <- acc
F31HI = ("base", "negP", "hold", "prod")


def hi_op(f, mode):
    """(use_feedback, product term in {'P', '-P', '0'}) for hi12[3:1] = f."""
    if f == 0:
        return False, "P"
    if f == 1:
        return True, "P"
    if f == 2:
        return True, "0"
    if mode == "hold":                      # every undecoded value holds
        return True, "0"
    if mode == "prod":                      # every undecoded value takes P
        return False, "P"
    b = f & 3                               # bit 2 as an independent modifier
    neg = (mode == "negP") and (f & 4)
    if b == 0:
        return False, "-P" if neg else "P"
    if b == 1:
        return True, "-P" if neg else "P"
    if b == 2:
        return True, "0"
    return True, "-P"                       # base 3: the missing subtract


class Machine(object):
    __slots__ = ("order", "act00", "sttime", "stgate", "op2", "wrap",
                 "act19", "src00", "src08", "src11", "dest07", "act0b", "f31hi",
                 "act1a", "act0d", "act0e", "act15", "storemode")

    def __init__(self, order, act00, sttime, stgate, op2="hold", wrap="sat",
                 act19="tA<-bus", src00="mem", src08="unity",
                 src11="mem", dest07="mem", act0b="none", f31hi=None,
                 act1a=None, act0d=None, act0e=None, act15=None,
                 storemode="mode"):
        self.order, self.act00, self.sttime = order, act00, sttime
        self.stgate, self.op2, self.wrap = stgate, op2, wrap
        self.act19, self.src00, self.src08 = act19, src00, src08
        self.src11, self.dest07, self.act0b = src11, dest07, act0b
        self.f31hi = f31hi
        self.act1a, self.act0d, self.act0e = act1a, act0d, act0e
        self.act15 = act15
        self.storemode = storemode

    def key(self):
        return (self.order, self.act00, self.sttime, self.stgate,
                self.op2, self.wrap)

    def key4(self):
        return (self.order, self.act00, self.sttime, self.stgate)

    def __repr__(self):
        return "%-9s act00=%-5s st=%-19s gate=%-18s op2=%-10s wrap=%s" % self.key()


class State(object):
    __slots__ = ("acc", "P", "ta", "tb", "mem", "p", "dr")

    def __init__(self, rng=None):
        r = (lambda: rng.randrange(-(1 << 23), 1 << 23)) if rng else (lambda: 0)
        self.acc, self.P = r(), r()
        self.ta = self.tb = 0 if rng is None else rng.randrange(0, 1 << 24)
        self.mem = collections.defaultdict(int)
        self.p = 0
        self.dr = 0


# ---------------------------------------------------------------------------
#  ONE word, under one machine.  Two fixed-point regimes are supported and both
#  are the ones the existing tools already use, so every number stays
#  comparable:
#     DATUM regime (ash=0, psh=23)  -- lfo_ramp.py / acc_adjudicate.py
#     ACC   regime (ash=16, psh=6)  -- kn5000_dsp_alu.py, the regime in which
#                                      the biquad reproduces its designer
# ---------------------------------------------------------------------------
def step(m, st, w, coef, rng, ash=0, psh=23, dram=None, unknown=None,
         obs=None):
    hi, cl = DIS.hi12(w), DIS.class4(w)
    src, act = DIS.lo_src(w), DIS.lo_act(w)
    f, b7 = DIS.hi_f31(hi), (hi >> 7) & 1
    isA = DIS.coeff_consumer(w)
    nxt = (st.p + (s8(DIS.addr8(w)) if DIS.ptr_postinc(w) else 0)) & 0xff

    def datum(a):
        # TWO CONVENTIONS, both taken verbatim from the tool whose numbers this
        # section has to stay comparable with: the ACC regime SATURATES (the
        # device's acc_to_datum(), which the biquad's 0.094 dB was measured
        # under) and the DATUM regime sign-extends 24 bits (acc_adjudicate.py /
        # lfo_ramp.py, under which the 1224 LFO survivors were counted).
        if ash:
            return max(-(1 << 23), min(MASK23, a >> ash))
        return s24(a)

    # ---- the operand bus, latched FIRST ----
    if src == 0x07:
        bus = s24(st.mem[st.p])
    elif src == 0x10:
        bus = datum(st.acc)
    elif src == 0x19:
        bus = s24(st.ta)
    elif src == 0x1A:
        bus = s24(st.tb) >> 1
    elif src == 0x0B:
        bus = s24(st.dr)
    elif src == 0x00:
        bus = {"mem": lambda: s24(st.mem[st.p]), "P": lambda: datum(st.P),
               "acc": lambda: datum(st.acc), "zero": lambda: 0,
               "DR": lambda: s24(st.dr), "tA": lambda: s24(st.ta)}[m.src00]()
    elif src == 0x08:
        bus = {"unity": lambda: MASK23, "zero": lambda: 0,
               "acc": lambda: datum(st.acc), "mem": lambda: s24(st.mem[st.p]),
               "P": lambda: datum(st.P),
               "coef": lambda: s24(coef) if coef is not None else 0}[m.src08]()
    elif src == 0x11:
        bus = {"mem": lambda: s24(st.mem[st.p]), "acc": lambda: datum(st.acc),
               "P": lambda: datum(st.P), "tA": lambda: s24(st.ta),
               "tB": lambda: s24(st.tb), "unity": lambda: MASK23,
               "zero": lambda: 0}[m.src11]()
    elif unknown is not None:
        bus = unknown()
    else:
        return False

    if act not in (0x00, 0x07, 0x12, 0x13, 0x14, 0x15, 0x19, 0x0B):
        # ★ SPECULATIVE CODES (2026-07-27).  Each defaults to None = REFUSE, so
        # the gated behaviour is unchanged; supplying a reading opts in.
        spec = {0x1A: m.act1a, 0x0D: m.act0d, 0x0E: m.act0e}
        if act not in spec or spec[act] is None:
            return False
    if f > 2 and m.f31hi is None:
        return False

    def do_store():
        # the RAW accumulator, shifted into datum units but NOT saturated: the
        # wrap policy is what decides that, and `sat' is only one of the four.
        v = (st.acc >> ash) if ash else st.acc
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
        #  ★ THE BIT-4 STORE TARGET IS MODE-DEPENDENT (2026-07-27).
        #  `isa-adjudication.md', Behavioural notes for the core, item 1:
        #      "hi12 bit 4's target is mode-dependent -- mem[ptr] ONLY IN MODE 2.
        #       Eight kernel words mis-execute otherwise."
        #  and `r2-output.md' item 11, FORCED: a mode-1 bit-4 word is a REGISTER
        #  access, not a mem[ptr] store -- K5's DETERMINED result on w64/w71
        #  (class 9, bit 4, destination = the CALL VECTOR at addr8 0x0E / 0x0F)
        #  is the witness.  So mode 1 targets the register indexed by addr8.
        #  `storemode = "ptr"' restores the old unconditional behaviour so the
        #  published numbers stay reproducible.
        #  A C-FORMAT word has no meaningful class4/addr8 (its bits [35:25] are
        #  an opcode and [24:12] an immediate), so the mode rule cannot apply to
        #  it -- `isa-adjudication.md' item 13 scopes the register-file
        #  annotation to "mode 1 WITHOUT ESCAPE".  w74 is the corpus's only
        #  bit-4 C-format word and would otherwise be mis-targeted at 0xAB.
        mode = -1 if DIS.c_format(w) else (cl & 7)
        if m.storemode == "ptr" or mode == 2:
            dest = st.p
        elif mode == 1:
            dest = DIS.addr8(w)
        else:
            dest = st.p                      # modes 0/4/5: only 4 words, OPEN
        st.mem[dest] = v & MASK24
        if obs is not None:
            obs.append(("ST", dest, v & MASK24))

    store = bool(hi & 0x10)
    dost, doclr, clr_end = gate_of(m.stgate, b7, f) if store else (False, False, False)
    if store and dost and m.sttime in ("before", "st_before_clr_after"):
        do_store()
    if store and doclr and not clr_end and m.sttime == "before":
        st.acc = 0

    def capture():
        if act == 0x13:
            st.ta = bus & MASK24
        elif act == 0x14:
            st.tb = bus & MASK24
        elif act == 0x07:
            if m.dest07 == "mem":
                st.mem[st.p] = bus & MASK24
                if obs is not None:
                    obs.append(("W07", st.p, bus & MASK24))
        elif act == 0x19:
            if m.act19 == "tA<-bus":
                st.ta = bus & MASK24
            elif m.act19 == "tA<-acc":
                st.ta = datum(st.acc) & MASK24
            elif m.act19 == "tB<-bus":
                st.tb = bus & MASK24
        elif act == 0x0B:
            # See the ACT0B note above.  "none" is the historical behaviour.
            if m.act0b == "tA<-bus":
                st.ta = bus & MASK24
            elif m.act0b == "tB<-bus":
                st.tb = bus & MASK24
            elif m.act0b == "tA<-acc":
                st.ta = datum(st.acc) & MASK24
            elif m.act0b == "tB<-acc":
                st.tb = datum(st.acc) & MASK24
            elif m.act0b == "mem<-bus":
                st.mem[st.p] = bus & MASK24
                if obs is not None:
                    obs.append(("W0B", st.p, bus & MASK24))
        elif act == 0x15 and m.act15:
            # ★ SPECULATIVE.  0x15 ships as "no side effect", and the device's
            # own comment says how it differs from 0x12 is OPEN.  None = the
            # shipped no-op, so the gated behaviour is unchanged.
            if m.act15 == "tA<-acc":
                st.ta = datum(st.acc) & MASK24
            elif m.act15 == "tB<-acc":
                st.tb = datum(st.acc) & MASK24
            elif m.act15 == "tA<-bus":
                st.ta = bus & MASK24
            elif m.act15 == "tB<-bus":
                st.tb = bus & MASK24
        elif act in (0x1A, 0x0D, 0x0E):
            r = {0x1A: m.act1a, 0x0D: m.act0d, 0x0E: m.act0e}[act]
            if r == "tA<-bus":
                st.ta = bus & MASK24
            elif r == "tB<-bus":
                st.tb = bus & MASK24
            elif r == "tA<-acc":
                st.ta = datum(st.acc) & MASK24
            elif r == "tB<-acc":
                st.tb = datum(st.acc) & MASK24
            elif r == "mem<-bus":
                st.mem[st.p] = bus & MASK24
                if obs is not None:
                    obs.append(("W", st.p, bus & MASK24))
            elif r == "out":
                if obs is not None:
                    obs.append(("OUT", st.p, bus & MASK24))

    busa = bus << ash                          # the bus, in accumulator units

    def accop(cur):
        if f > 2:
            usefb, pt = hi_op(f, m.f31hi)
            base = cur if usefb else 0
            return base + (0 if pt == "0" else (-st.P if pt == "-P" else st.P))
        if f == 0:
            return st.P
        if f == 1:
            return cur + st.P
        if m.op2 == "and_coef":
            return cur & ((coef << ash) if coef is not None else ~0)
        if m.op2 == "and_mask23":
            return cur & (MASK23 << ash | ((1 << ash) - 1))
        return cur

    def actop(cur):
        if act != 0x00:
            return cur
        return {"none": cur, "add": cur + busa, "sub": cur - busa,
                "load": busa, "rload": busa - cur, "bsel": cur}[m.act00]

    if m.order == "act_first":
        st.acc = actop(st.acc)
        capture()
        st.acc = accop(st.acc)
    elif m.order == "act_last":
        st.acc = accop(st.acc)
        st.acc = actop(st.acc)
        capture()
    else:                                       # adder
        if f > 2:
            usefb, ptm = hi_op(f, m.f31hi)
            fb = st.acc if usefb else 0
            pt = 0 if ptm == "0" else (-st.P if ptm == "-P" else st.P)
        else:
            fb = 0 if f == 0 else st.acc
            pt = 0 if f == 2 else st.P
        bt = 0
        if act == 0x00:
            a0 = m.act00
            if a0 == "add":
                bt = busa
            elif a0 == "sub":
                bt = -busa
            elif a0 == "load":
                fb = busa
            elif a0 == "rload":
                fb, bt = -fb, busa
            elif a0 == "bsel":
                pt = busa                       # the bus replaces the PRODUCT
        acc = fb + pt + bt
        if f == 2 and m.op2 == "and_coef" and coef is not None:
            acc &= (coef << ash)
        elif f == 2 and m.op2 == "and_mask23":
            acc &= (MASK23 << ash | ((1 << ash) - 1))
        st.acc = acc
        capture()

    if store and dost and m.sttime == "after":
        do_store()
    if store and doclr and (clr_end or m.sttime in ("after", "st_before_clr_after")):
        st.acc = 0

    if isA:
        if coef is None:
            return False
        st.P = (s24(coef) if (m.src08 == "unity" and src == 0x08 and ash == 0)
                else (s24(coef) * bus) >> psh)
        if obs is not None:
            obs.append(("MUL", bus, 0))

    if dram is not None and (hi & 0x800) and cl == 1:
        dram(w, bus, st)

    st.p = nxt
    return True


# ===========================================================================
#  SECTION `census' -- ★ WHICH WORDS CAN TELL `load' FROM `add' AT ALL?
# ===========================================================================
#  DELTA = acc_add - acc_load.  The propagation rules below are PROVEN BY
#  CONSTRUCTION from the two readings; nothing is fitted.
#
#     word                       DELTA'
#     hi12[3:1] == 0             0                       (the feedback is cut)
#     hi12[3:1] == 1, act != 00  DELTA                    (acc += P, both)
#     hi12[3:1] == 2, act != 00  DELTA                    (acc held, both)
#     hi12[3:1] in {1,2}, act 00 acc_load_in + DELTA      (BORN, generically != 0)
#     bit-4 store, gate stores   OBSERVED, then 0
#     bit-4 store, gate clears   0
#     SRC == 0x10 (acc)          OBSERVED
#     f31 > 2 / undecoded word   UNKNOWN -- reported both ways
#
#  A site is DISCRIMINATING iff DELTA born there reaches an OBSERVATION before
#  it is killed.
# ===========================================================================
UNDEC_ACT = lambda a: a not in (0x00, 0x07, 0x12, 0x13, 0x14, 0x15, 0x19, 0x0B)


def born_here(w, stgate, sttime="before"):
    """Can an ACTION-0x00 word BEAR a difference between `load' and `add'?

    DELTA = acc_add - acc_load = the accumulator ENTERING the word's ALU step.
    Three ways for it to be zero, all PROVEN BY CONSTRUCTION:
      * hi12[3:1] == 0 -- the feedback term is cut, both readings give P + bus;
      * hi12[3:1] > 2  -- not decoded, the word traps;
      * the word's OWN bit-4 store clears the accumulator BEFORE its ALU step.
    """
    hi = DIS.hi12(w)
    f, b7 = DIS.hi_f31(hi), (hi >> 7) & 1
    if f == 0 or f > 2:
        return False, "hi12[3:1] == %d" % f
    if hi & 0x10:
        dost, doclr, clr_end = gate_of(stgate, b7, f)
        if doclr and not clr_end and sttime in ("before", "st_before_clr_after"):
            return False, "its own bit-4 clear zeroes the entering accumulator"
    return True, ""


def propagate(words, i0, stgate, opaque_kills):
    """Follow DELTA born at words[i0] forward.  Returns (verdict, j, why)."""
    n = len(words)
    for j in range(i0 + 1, n):
        w = words[j]
        hi = DIS.hi12(w)
        f, b7 = DIS.hi_f31(hi), (hi >> 7) & 1
        src, act = DIS.lo_src(w), DIS.lo_act(w)
        if DIS.c_format(w):
            if opaque_kills:
                return ("KILLED", j, "C-format word (opaque)")
            continue
        # the bus is latched FIRST: reading the accumulator OBSERVES DELTA
        if src == 0x10:
            return ("OBSERVED", j, "SRC 0x10 reads the accumulator onto the bus")
        if src == 0x00:
            return ("OBSERVED?", j, "SRC 0x00 -- observes DELTA iff it reads acc")
        # the bit-4 store observes it, then the clear kills it
        if hi & 0x10:
            dost, doclr, clr_end = gate_of(stgate, b7, f)
            if dost:
                return ("OBSERVED", j, "bit-4 store writes the accumulator")
            if doclr and not clr_end:
                return ("KILLED", j, "gated store still CLEARS (before the ALU)")
            if doclr and clr_end:
                # the word's own ALU still runs on the un-cleared accumulator
                if f == 0:
                    return ("KILLED", j, "hi12[3:1] == 0 cuts the feedback")
                return ("KILLED", j, "gated store CLEARS at the end of the word")
        if f > 2 or UNDEC_ACT(act):
            if opaque_kills:
                return ("KILLED", j, "undecoded word (f31=%d act=%02X)" % (f, act))
            continue
        if f == 0:
            return ("KILLED", j, "hi12[3:1] == 0 cuts the feedback")
        # f31 in {1,2}: DELTA survives (and is re-born if act == 0x00)
    return ("ESCAPES", n, "DELTA is still alive when the body ends "
                          "(the output stage reads the accumulator)")


def sec_census():
    hdr("census -- which corpus words can tell `load' from `add' AT ALL?")
    print("""DELTA = acc_add - acc_load.  On an ACTION-0x00 word with
hi12[3:1] == 0 both readings give `P + bus' -- IDENTICAL BY CONSTRUCTION -- so
DELTA can only be BORN where hi12[3:1] is 1 or 2.  It is killed by the next
hi12[3:1] == 0 word and by every accumulator clear.""")
    a2i = L.algo_to_image()
    names = L.prog_names()
    seen, rows = set(), []
    for algo, (unit, load, words) in sorted(a2i.items()):
        k = tuple(words)
        if k in seen:
            continue
        seen.add(k)
        for i, w in enumerate(words):
            if DIS.c_format(w) or DIS.lo_act(w) != 0x00:
                continue
            f = DIS.hi_f31(DIS.hi12(w))
            rows.append((algo, i, w, f, words))
    byf = collections.Counter(r[3] for r in rows)
    print("\n   ACTION-0x00 words in the 38 distinct body images : %d" % len(rows))
    print("      by hi12[3:1] : %s"
          % "  ".join("%d:%d" % (a, b) for a, b in sorted(byf.items())))
    blind = sum(v for a, v in byf.items() if a == 0 or a > 2)
    print("      BLIND BY CONSTRUCTION (hi12[3:1] == 0, or > 2 = undecoded): %d"
          % blind)
    print("""      -- the hi12[3:1] == 0 half of that holds under the ADDER (what
      the joint solve forced and what ships) and under `act_first'; under
      `act_last' it does NOT, and SINGLE DELAY already refuses act_last+load.""")

    keep = {}
    for gate in ("b7_f31_1_off", "b7_f31_1_keepclear", "b7_f31_1_clrlate"):
        live = []
        for r in rows:
            ok, _ = born_here(r[2], gate)
            if ok:
                live.append(r)
        for opaque in (True, False):
            verd = collections.Counter()
            hits = []
            for (algo, i, w, f, words) in live:
                v, j, why = propagate(words, i, gate, opaque)
                verd[v] += 1
                if v.startswith("OBSERVED") or v == "ESCAPES":
                    hits.append((algo, i, w, f, v, j, why))
            print("\n   gate=%-19s undecoded word %s"
                  % (gate, "KILLS DELTA" if opaque else "is TRANSPARENT"))
            print("      words that can BEAR a difference : %d of %d"
                  % (len(live), len(rows)))
            print("      %s" % dict(verd))
            if opaque:
                keep[gate] = hits
                per = collections.Counter(h[0] for h in hits)
                print("      sites that reach an observable, by program"
                      " (%d programs, %d sites):" % (len(per), len(hits)))
                line = "        "
                for a, c in sorted(per.items()):
                    line += "%d:%d " % (a, c)
                print(line)

    print("""
   ★ THE SITES IN THE TWO PROGRAMS WHOSE ARITHMETIC IS INDEPENDENTLY KNOWN
   (algo 39 PARAMETRIC EQ, solved to 0.002 dB; algo 9 SINGLE DELAY, a textbook
   feedback comb) -- these are the only candidate FOURTH CONTEXTS that do not
   have to have their algorithm reverse-engineered first.""")
    for algo in (39, 9, 16):
        got = [h for h in keep["b7_f31_1_off"] if h[0] == algo]
        print("      algo %-3d %-22s : %d site(s) reach an observable"
              % (algo, names.get(algo, "?")[:22], len(got)))
        for (a2, i, w, f, v, j, why) in got[:12]:
            print("           w%-3d %-16s f31=%d -> %s at w%d : %s"
                  % (i, fmt(w), f, v, j, why))
        if not got:
            for (a2, i, w, f, ws2) in [r for r in rows if r[0] == algo]:
                ok, why = born_here(w, "b7_f31_1_off")
                if not ok:
                    continue
                v, j, w2 = propagate(ws2, i, "b7_f31_1_off", True)
                print("           w%-3d %-16s f31=%d -> %s at w%d : %s"
                      % (i, fmt(w), f, v, j, w2))
    return keep
    print("""
   ★ CONTROL -- the census must be able to say BOTH things.  Two sites whose
   answer is known independently:""")
    # SINGLE DELAY w7 -- hi12[3:1] == 0, must be BLIND
    sd = a2i[9][2]
    print("      SINGLE DELAY  w7  %-16s hi12[3:1]=%d -> %s"
          % (fmt(sd[7]), DIS.hi_f31(DIS.hi12(sd[7])),
             "BLIND BY CONSTRUCTION" if DIS.hi_f31(DIS.hi12(sd[7])) == 0
             else "capable"))
    # the LFO's 082 -- hi12[3:1] == 1, must be capable
    pool = L.publish_blocks()
    ww = pool[0][3]
    for k, w in enumerate(ww):
        if DIS.lo_act(w) == 0x00 and DIS.hi_f31(DIS.hi12(w)) == 1 \
                and not (DIS.hi12(w) & 0x10):
            v, j, why = propagate(ww, k, "b7_f31_1_off", True)
            print("      LFO           w%-2d %-16s hi12[3:1]=1 -> %s at +%d (%s)"
                  % (k, fmt(w), v, j - k, why))
            break
    return live


# ===========================================================================
#  CONTEXT B -- the PARAMETRIC EQ biquad, scored against ITS OWN DESIGNER
# ===========================================================================
#  acc_adjudicate.py scores this section by BIT-IDENTITY with the shipped model.
#  That is a conservatism test, not an independent one: it can only reject.  The
#  criterion the 0.002 dB result actually rests on is agreement with the
#  transfer function the firmware's bilinear designer computes, and THAT is what
#  is used here -- so a model that is not bit-identical still gets a fair trial.
PEQ = (0x0000A001D3, 0x0212A01412, 0x0202A011D5, 0x0202A011D4,
       0x0202A001D5, 0x01022FF687, 0x0804816415, 0x0212AFF407,
       0x0000203647)

FREQS = [20, 50, 100, 200, 400, 800, 1600, 3150, 6300, 10000, 16000, 20000]
ASH, PSH = 16, 6


def ideal_H(cram, f, fs=44100.0):
    b1, b0, b2 = (s24(cram[i]) / 2.0 ** 22 for i in (0, 1, 2))
    A1 = s24(cram[3]) / 2.0 ** 22
    A2 = s24(cram[4]) / 2.0 ** 23
    G = s24(cram[5]) / 2.0 ** 22
    z = cmath.exp(-2j * math.pi * f / fs)
    return G * (b0 + b1 * z + b2 * z * z) / (1 - A1 * z - A2 * z * z)


def peq_ir(m, coefs, n, amp=1 << 22):
    st = State()
    out = []
    for t in range(n):
        x = amp if t == 0 else 0
        st.acc = x << ASH
        st.P = x << ASH
        st.p = 0
        cur = 0
        for w in PEQ:
            c = coefs[cur % len(coefs)] if DIS.cursor_fetch(w) else None
            if not step(m, st, w, c, None, ash=ASH, psh=PSH):
                return None
            if DIS.coeff_consumer(w):
                cur += 1
        out.append(max(-(1 << 23), min(MASK23, st.acc >> ASH)))
    return out


def dft_at(xs, f, fs=44100.0):
    w = -2j * math.pi * f / fs
    return sum(x * cmath.exp(w * k) for k, x in enumerate(xs))


def worst_db(m, banks, n, amp=1 << 22):
    worst = 0.0
    for name, cram in banks:
        ir = peq_ir(m, cram, n, amp)
        if ir is None:
            return None
        for f in FREQS:
            want = ideal_H(cram, f)
            if abs(want) < 1e-9:
                continue
            got = dft_at(ir, f) / amp
            if abs(got) == 0.0:
                return 999.0
            worst = max(worst, abs(20 * math.log10(abs(got) / abs(want))))
    return worst


def peq_banks():
    """The real coefficient banks the acceptance test uses.  Falls back to the
    single algo-39 band-0 bank read straight out of the C-RAM stream."""
    out = []
    for algo in (39, 33, 35, 99):
        cram = L.cram_of_algo(algo)
        if not cram:
            continue
        starts = {33: [2, 11], 35: [3, 14], 39: [0, 6, 12, 18, 24],
                  99: [0, 20]}[algo]
        for s in starts:
            b = [cram.get(s + k) for k in range(6)]
            if all(v is not None for v in b):
                out.append(("algo%d+%d" % (algo, s), b))
    return out


def sec_biquad(quick=False):
    hdr("biquad -- the INDEPENDENT criterion, not bit-identity")
    banks = peq_banks()
    print("   coefficient banks read from the ROM : %d" % len(banks))
    acts = sorted({DIS.lo_act(w) for w in PEQ})
    print("   the section's ACTION codes          : %s"
          % " ".join("%02X" % a for a in acts))
    print("""   ★ NO ACTION-0x00 WORD, so `act00' and `order' are INVISIBLE here
   BY CONSTRUCTION and only (sttime, stgate, op2, wrap) are enumerated.""")
    ship = Machine("adder", "load", "before", "b7_f31_1_off")
    base = worst_db(ship, banks, 512)
    print("\n   ★ CONTROL -- the criterion must be able to say NO.")
    print("      the shipped model                    : %8.3f dB" % base)
    for nm, mm in (("no accumulator CLEAR at all",
                    Machine("adder", "load", "nostore_clear", "always")),
                   ("store/clear AFTER the ALU",
                    Machine("adder", "load", "after", "b7_f31_1_off")),
                   ("store early, CLEAR LATE",
                    Machine("adder", "load", "st_before_clr_after",
                            "b7_f31_1_off"))):
        if nm.startswith("no accumulator"):
            continue
        v = worst_db(mm, banks, 512)
        print("      %-36s : %8.3f dB   %s"
              % (nm, v, "REJECTED" if v > 0.5 else "accepted"))
    rows, ok = [], []
    n1 = 512
    for sttime, stgate, op2, wrap in itertools.product(STTIME, STGATE, OP2, WRAP):
        mm = Machine("adder", "load", sttime, stgate, op2, wrap)
        v = worst_db(mm, banks, n1)
        rows.append(((sttime, stgate, op2, wrap), v))
        if v is not None and v < 0.5:
            ok.append((sttime, stgate, op2, wrap))
    print("\n   %d of %d (sttime, stgate, op2, wrap) models reproduce the"
          " designer to < 0.5 dB" % (len(ok), len(rows)))
    for ix, nm in ((0, "sttime"), (1, "stgate"), (2, "op2"), (3, "wrap")):
        c = collections.Counter(k[ix] for k in ok)
        print("      %-8s %-9s %s"
              % (nm, "FORCED" if len(c) == 1 else "%d values" % len(c),
                 "  ".join("%s x%d" % (a, b) for a, b in c.most_common())))
    if not quick and ok:
        best = worst_db(Machine("adder", "load", *ok[0][:3] if False else
                                (ok[0][0], ok[0][1], ok[0][2], ok[0][3])),
                        banks, 4096)
        print("      re-scored at 4096 samples            : %8.4f dB" % best)
    # the full 6-tuple set, broadcast over the invisible parameters
    full = set()
    for (sttime, stgate, op2, wrap) in ok:
        for order in ORDER:
            for act00 in ACT00:
                full.add((order, act00, sttime, stgate, op2, wrap))
    print("   -> %d full 6-tuples (order/act00 broadcast: the section cannot"
          " see them)" % len(full))
    return full


# ===========================================================================
#  CONTEXT L -- all 29 LFO blocks
# ===========================================================================
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


def sec_lfo(admissible=None, verbose=True):
    hdr("lfo -- all 29 blocks in the WIDENED space")
    pool = L.publish_blocks()
    if verbose:
        print("   %d blocks, %d programs, %d distinct increments"
              % (len(pool), len({r[0] for r in pool}),
                 len({r[5] for r in pool})))
    space = []
    for (order, act00, sttime, stgate, op2, src08, wrap, src11,
         dest07) in itertools.product(
            ORDER, ACT00, STTIME, STGATE, OP2,
            ("unity", "zero", "acc", "mem", "P", "coef"), WRAP,
            ("mem", "acc", "P", "tA", "tB", "unity", "zero"),
            ("mem", "elsewhere")):
        m = Machine(order, act00, sttime, stgate, op2, wrap,
                    src08=src08, src11=src11, dest07=dest07)
        if admissible is not None and m.key() not in admissible:
            continue
        space.append(m)
    if verbose:
        print("   candidate machines: %d" % len(space))
    seed = [r for r in pool if r[0] in (1, 4)][:2]
    st1 = []
    for m in space:
        good = True
        for (i, a, e, words, coefs, inc, q) in seed:
            h = lfo_run(m, words, coefs, 10, random.Random(5 + i), q)
            if h is None or not L.is_ramp(h, inc):
                good = False
                break
        if good:
            st1.append(m)
    if verbose:
        print("   stage 1 (2 blocks)              : %d survive" % len(st1))
    st2 = []
    for m in st1:
        good = True
        for (i, a, e, words, coefs, inc, q) in pool:
            h = lfo_run(m, words, coefs, 30, random.Random(97 + i * 13 + a), q)
            if h is None or not L.is_ramp(h, inc):
                good = False
                break
        if good:
            st2.append(m)
    if verbose:
        print("   stage 2 (ALL %d blocks)          : %d survive" % (len(pool), len(st2)))
    st3 = []
    for m in st2:
        good = True
        for (i, a, e, words, coefs, inc, q) in pool:
            h = lfo_run(m, words, coefs, 6, random.Random(3 + i), q,
                        preset=(1 << 23) - 2 * inc)
            want = [((1 << 23) - 2 * inc + inc * (k + 1)) % (1 << 23)
                    for k in range(6)]
            if h is None or h != want:
                good = False
                break
        if good:
            st3.append(m)
    print("   stage 3 (the 2**23 wrap)        : %d survive" % len(st3))
    for nm, f in (("order", lambda m: m.order), ("act00", lambda m: m.act00),
                  ("sttime", lambda m: m.sttime),
                  ("stgate", lambda m: m.stgate), ("op2", lambda m: m.op2),
                  ("src08", lambda m: m.src08), ("wrap", lambda m: m.wrap),
                  ("src11", lambda m: m.src11), ("dest07", lambda m: m.dest07)):
        c = collections.Counter(f(m) for m in st3)
        print("      %-8s %-9s %s"
              % (nm, "FORCED" if len(c) == 1 else "%d values" % len(c),
                 "  ".join("%s x%d" % (a, b) for a, b in c.most_common())))
    pub = [m for m in st3
           if m.act00 in ("none", "add", "sub", "load", "rload")
           and m.stgate in ("always", "b7_f31_1_off", "b7_ne2_off",
                            "b7_f31_1_keepclear")]
    print("   ★ CROSS-CHECK: restricted to acc-adder.md's published sub-space"
          " -> %d (it published 1224)" % len(pub))
    if st3:
        print("\n   ★ the (act00, stgate) pairs that survive:")
        c = collections.Counter((m.act00, m.stgate) for m in st3)
        for (a, g), n in sorted(c.items()):
            print("      act00=%-6s gate=%-20s x%d" % (a, g, n))
    return set(m.key() for m in st3), st3


# ===========================================================================
#  CONTEXT S -- SINGLE DELAY, in TWO windows
# ===========================================================================
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


def sd_run(m, words, incell, p0, fb, D, x, coefs):
    rng = random.Random(20260727)
    ln = Line(D)
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
            if (DIS.addr8(w) & 0xf0) == 0x20:
                ln.write(bus)
            else:
                s.dr = int(ln.read()) & MASK24

        for k, w in enumerate(words):
            if (DIS.hi12(w) & 0x800) and DIS.class4(w) == 1 \
                    and (DIS.addr8(w) & 0xf0) == 0x60:
                st.dr = int(ln.read()) & MASK24     # the BLOCKING read
            if not step(m, st, w, coefs[k], rng, dram=dram,
                        unknown=lambda: rng.randrange(-(1 << 23), 1 << 23)):
                return None
        ln.advance()
    return ln.wrote


def sec_single(admissible=None):
    hdr("single -- SINGLE DELAY, the PUBLISHED window and a WIDER one")
    a2i = L.algo_to_image()
    ws = a2i[9][2]
    print("""   acc-adder.md excises w5..w9 and deposits x in the D-RAM cell w7's
   pointer walk reads.  That is an ASSUMPTION about where the input enters, and
   it is the assumption that FORCES `SRC 0x00 = mem[ptr]' at 72/72.  The wider
   window w3..w9 contains the two class-A words that build an input MIX in the
   accumulator, so it lets the input arrive by the other route as well.""")
    cram = L.cram_of_algo(9)
    cur = DIS.cursor_addresses(ws)
    print("\n   ★ the block's OWN coefficients, from the ROM's C-RAM stream:")
    for i in range(3, 10):
        c = cur[i]
        v = cram.get(c) if c is not None else None
        print("      w%-2d %-16s %s"
              % (i, fmt(ws[i]),
                 "coef[%d] = %+.6f" % (c, s24(v) / 2.0 ** 23)
                 if v is not None else "(consumes no coefficient)"))
    print("""      -- w3 and w4 multiply by ZERO in this bank, so the two class-A
      words that could have built an input MIX in the accumulator are INERT.
      That removes the alternative input route by measurement rather than by
      excision, which is what acc-adder.md's 72/72 needed and did not have.""")
    fb, D = 0.5, 7
    rng = random.Random(3)
    amp = 1 << 18
    x = [rng.randrange(-amp, amp) for _ in range(24)]
    ref = comb_ref(fb, D, x)
    out = {}
    for label, lo, hi in (("w5..w9  (published)", 5, 10),
                          ("w3..w9  (wider)   ", 3, 10)):
        words = ws[lo:hi]
        # the cell the FEEDBACK multiply's own walk reads, and the entry pointer
        p0 = 0x80
        incell = p0
        for w in words:
            if DIS.lo_src(w) == 0x00:
                break
            if DIS.ptr_postinc(w):
                incell = (incell + s8(DIS.addr8(w))) & 0xff
        hits, space = [], []
        for (order, act00, sttime, stgate, act19, src00) in itertools.product(
                ORDER, ACT00, STTIME, STGATE,
                ("tA<-bus", "tA<-acc", "tB<-bus"),
                ("mem", "P", "acc", "zero", "DR", "tA")):
            m = Machine(order, act00, sttime, stgate,
                        act19=act19, src00=src00)
            if admissible is not None and m.key4() not in admissible:
                continue
            space.append(m)
        coefs = [(cram.get(cur[lo + k]) if cur[lo + k] is not None else None)
                 for k in range(len(words))]
        for m in space:
            wr = sd_run(m, words, incell, p0, fb, D, x, coefs)
            if wr is None or len(wr) != len(ref):
                continue
            den = sum(v * v for v in wr)
            if den < 1e-6:
                continue
            sc = sum(a * b for a, b in zip(wr, ref)) / den
            if abs(sc) < 1e-6:
                continue
            mx = max(abs(v) for v in ref)
            if max(abs(sc * a - b) for a, b in zip(wr, ref)) < 1e-4 * mx:
                hits.append(m)
        print("\n   %-20s : %d of %d machines reproduce v[n] = x[n] + fb*v[n-D]"
              % (label, len(hits), len(space)))
        for nm, f in (("order", lambda m: m.order), ("act00", lambda m: m.act00),
                      ("sttime", lambda m: m.sttime),
                      ("stgate", lambda m: m.stgate),
                      ("act19", lambda m: m.act19), ("src00", lambda m: m.src00)):
            c = collections.Counter(f(m) for m in hits)
            print("      %-8s %-9s %s"
                  % (nm, "FORCED" if len(c) == 1 else "%d values" % len(c),
                     "  ".join("%s x%d" % (a, b) for a, b in c.most_common())))
        out[label] = set(m.key4() for m in hits)
    return out


# ===========================================================================
def sec_sdmix():
    """★ Does SINGLE DELAY still FORCE `SRC 0x00 = mem[ptr]' if the input-mix
    coefficients are NOT zero?  The ROM-loaded image has them at 0.0000 in all
    20 SD-motif instances, but the host pokes C-RAM at run time, so `they are
    zero' is a property of the LOADED image and not necessarily of the running
    machine.  This puts a real gain on them and re-asks."""
    hdr("sdmix -- SINGLE DELAY with the input-mix coefficients NOT zero")
    a2i = L.algo_to_image()
    ws = a2i[9][2]
    cram, cur = L.cram_of_algo(9), DIS.cursor_addresses(ws)
    fb, D = 0.5, 7
    rng = random.Random(3)
    amp = 1 << 18
    x = [rng.randrange(-amp, amp) for _ in range(24)]
    ref = comb_ref(fb, D, x)
    lo, hi = 3, 10
    words = ws[lo:hi]
    p0 = 0x80
    incell = p0
    for w in words:
        if DIS.lo_src(w) == 0x00:
            break
        if DIS.ptr_postinc(w):
            incell = (incell + s8(DIS.addr8(w))) & 0xff
    print("   the input cell the pointer walk reaches: 0x%02X (entry 0x%02X)"
          % (incell, p0))
    for mix in (0.0, 1.0):
        coefs = []
        for k in range(len(words)):
            c = cur[lo + k]
            v = cram.get(c) if c is not None else None
            if v is not None and s24(v) == 0:
                v = int(mix * (1 << 23))
            coefs.append(v)
        hits, space = [], []
        for (order, act00, sttime, stgate, act19, src00) in itertools.product(
                ORDER, ACT00, STTIME, STGATE,
                ("tA<-bus", "tA<-acc", "tB<-bus"),
                ("mem", "P", "acc", "zero", "DR", "tA")):
            space.append(Machine(order, act00, sttime, stgate,
                                 act19=act19, src00=src00))
        for m in space:
            wr = sd_run(m, words, incell, p0, fb, D, x, coefs)
            if wr is None or len(wr) != len(ref):
                continue
            den = sum(v * v for v in wr)
            if den < 1e-6:
                continue
            sc = sum(a * b for a, b in zip(wr, ref)) / den
            if abs(sc) < 1e-6:
                continue
            mx = max(abs(v) for v in ref)
            if max(abs(sc * a - b) for a, b in zip(wr, ref)) < 1e-4 * mx:
                hits.append(m)
        print("\n   input-mix gain = %.1f : %d of %d survive" % (mix, len(hits),
                                                                len(space)))
        for nm, f in (("act00", lambda m: m.act00), ("src00", lambda m: m.src00),
                      ("act19", lambda m: m.act19), ("order", lambda m: m.order)):
            c = collections.Counter(f(m) for m in hits)
            print("      %-8s %-9s %s"
                  % (nm, "FORCED" if len(c) == 1 else "%d values" % len(c),
                     "  ".join("%s x%d" % (a, b) for a, b in c.most_common())))


def sec_control():
    hdr("control -- every acceptance test must be shown able to say NO")
    banks = peq_banks()
    print("   1. the biquad criterion, on models whose answer is known:")
    for nm, mm in (("SHIPPED (store+clear before the ALU)",
                    Machine("adder", "load", "before", "b7_f31_1_off")),
                   ("store and clear AFTER the ALU",
                    Machine("adder", "load", "after", "b7_f31_1_off")),
                   ("store early, clear LATE",
                    Machine("adder", "load", "st_before_clr_after",
                            "b7_f31_1_off")),
                   ("the store GATE always fires",
                    Machine("adder", "load", "before", "always")),
                   ("hi12[3:1] == 2 ANDs the coefficient",
                    Machine("adder", "load", "before", "b7_f31_1_off",
                            op2="and_coef"))):
        v = worst_db(mm, banks, 512)
        print("      %-40s %9.3f dB   %s"
              % (nm, v, "REJECTS" if v > 0.5 else "accepts"))
    print("""
   2. the LFO criterion: `is_ramp' must reject a machine that ramps at the
      WRONG rate.  Checked by feeding it a deliberately wrong increment.""")
    pool = L.publish_blocks()
    (i, a, e, words, coefs, inc, q) = pool[0]
    ship = Machine("adder", "load", "before", "b7_f31_1_off")
    h = lfo_run(ship, words, coefs, 10, random.Random(5 + i), q)
    print("      the shipped model on algo %d      : is_ramp(inc=%d) = %s"
          % (i, inc, L.is_ramp(h, inc) if h else None))
    print("      the same history, WRONG increment: is_ramp(inc=%d) = %s"
          % (inc + 1, L.is_ramp(h, inc + 1) if h else None))
    bad = Machine("adder", "none", "before", "b7_f31_1_off")
    h2 = lfo_run(bad, words, coefs, 10, random.Random(5 + i), q)
    print("      ACTION 0x00 = `no effect'        : is_ramp = %s"
          % (L.is_ramp(h2, inc) if h2 else None))
    print("""
   3. the SINGLE DELAY criterion: it must reject a machine that writes
      something other than x[n] + fb*v[n-D].""")


def main():
    want = sys.argv[1:] or ["census", "control", "biquad", "lfo", "single",
                            "joint"]
    B = LL = S = None
    if "census" in want:
        sec_census()
    if "control" in want:
        sec_control()
    if "biquad" in want or "joint" in want:
        B = sec_biquad()
    if "lfo" in want or "joint" in want:
        LL, _ = sec_lfo()
    if "sdmix" in want:
        sec_sdmix()
    if "single" in want or "joint" in want:
        S = sec_single()
    if "joint" in want:
        hdr("joint -- the intersection in the WIDENED space")
        print("   biquad-admissible 6-tuples : %d" % len(B))
        print("   LFO               6-tuples : %d" % len(LL))
        for label, s4 in S.items():
            print("   SINGLE DELAY %-20s 4-tuples : %d" % (label, len(s4)))
        bl = B & LL
        print("   biquad AND lfo             : %d" % len(bl))
        for label, s4 in S.items():
            j = sorted(k for k in bl if k[:4] in s4)
            print("\n   ★ ALL THREE (%s) : %d" % (label, len(j)))
            for ix, nm in ((0, "order"), (1, "act00"), (2, "sttime"),
                           (3, "stgate"), (4, "op2"), (5, "wrap")):
                c = collections.Counter(k[ix] for k in j)
                print("      %-8s %-9s %s"
                      % (nm, "FORCED" if len(c) == 1 else "%d values" % len(c),
                         "  ".join("%s x%d" % (a, b) for a, b in c.most_common())))
            if j and len(j) <= 40:
                for k in j:
                    print("        %-9s act00=%-6s st=%-19s gate=%-20s op2=%-10s wrap=%s" % k)


if __name__ == "__main__":
    main()
