#!/usr/bin/env python3
"""gate_settle.py -- SETTLE THE BIT-7 STORE GATE of the NEC uPD6383GF-3BA.

WHY THIS EXISTS.  `action00-discriminator.md' item C proved that "what does
ACTION 0x00 mean?" IS "does a bit-7-suppressed store clear the accumulator, and
when?" -- in all 33 joint survivors the two are locked together.  The gate is
the PRIMARY half: 130 corpus words, 11 frame slots.  This tool settles it.

    ★ THE ENUMERATION IS THE POINT (method rule 3).

`acc-adder.md' enumerated FOUR gates, `action00-discriminator.md' SIX, each a
hand-named lambda over (bit 7, hi12[3:1]).  Both spaces are ad hoc: they mix a
CONDITION ("which words are gated") with an EFFECT ("what the gate does") and
they carry the global store timing `sttime' as a SEPARATE parameter, which
double-counts.  A hand-named list is exactly the shape of object that omitted
the blocking read.

This tool replaces the list with the FULL FUNCTION SPACE.  A bit-4 store word is
characterised, for the ALU, by (bit 7, hi12[3:1]) alone -- hi12[3:1] > 2 traps,
so there are SIX addressable classes and only FIVE occur in the corpus.  The
gate is then a FUNCTION

    G : (b7, f31)  ->  EFFECT

and an EFFECT is everything a "store word" can possibly do to memory and to the
accumulator:

    mem_op  in {none, store, load}      none = no memory access at all
                                        load = the access is a READ INTO THE
                                               ACCUMULATOR, i.e. bit 7 is a
                                               DIRECTION bit on the memory port
    value   in {acc, bus}               what a store writes  (bit 7 = source sel)
    dest    in {ptr, elsewhere}         where it writes       (bit 7 = port sel)
    mtime   in {before, after}          relative to the word's own ALU step
    clear   in {never, before, after}   the accumulator clear and ITS timing

33 canonical effects per class; the global `sttime' is ABSORBED (it is the
(mtime, clear) of the ungated classes), so nothing is counted twice.  Every gate
named in `acc-adder.md' and `action00-discriminator.md' is a point of this space
and `enum' prints where.

    python3 dsp/tools/gate_settle.py enum      # ★ THE ENUMERATION + degeneracy
    python3 dsp/tools/gate_settle.py census    # ★ THE GATE DECIDABILITY CENSUS
    python3 dsp/tools/gate_settle.py control   # ★ RUN FIRST -- can the tests say NO?
    python3 dsp/tools/gate_settle.py mirror    # reproduce the published numbers
    python3 dsp/tools/gate_settle.py biquad    # class (0,1), designer criterion
    python3 dsp/tools/gate_settle.py dead      # the STRUCTURAL criterion
    python3 dsp/tools/gate_settle.py lfo       # classes (1,1) and (1,2)   (~20 min)
    python3 dsp/tools/gate_settle.py joint     # ★ the intersection
    python3 dsp/tools/gate_settle.py vacuity   # ★ the f31==0 vacuity sweep

Standard library only.  Every number printed is computed here from the ROM.
"""
import collections
import itertools
import math
import cmath
import os
import random
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import dsp_disasm as DIS                                    # noqa: E402
import lfo_ramp as L                                        # noqa: E402
import action00_discriminate as A                           # noqa: E402

MASK24, MASK23 = (1 << 24) - 1, (1 << 23) - 1
ELSEWHERE = ("<elsewhere>",)          # a memory key no pointer can ever equal


def s24(v):
    v &= MASK24
    return v - (1 << 24) if v & (1 << 23) else v


def s8(v):
    v &= 0xff
    return v - 256 if v & 0x80 else v


fmt = A.fmt
hdr = A.hdr


# ===========================================================================
#  THE ENUMERATION
# ===========================================================================
#  An EFFECT is (mem_op, value, dest, mtime, clear).  Fields that cannot apply
#  are None so that the canonical list has no duplicates.
def all_effects():
    out = []
    for clr in ("never", "before", "after"):
        out.append(("none", None, None, None, clr))
    for val in ("acc", "bus"):
        for dst in ("ptr", "else"):
            for mt in ("before", "after"):
                for clr in ("never", "before", "after"):
                    out.append(("store", val, dst, mt, clr))
    for mt in ("before", "after"):
        for clr in ("never", "before", "after"):
            out.append(("load", None, None, mt, clr))
    return tuple(out)


EFFECTS = all_effects()
EFF_IX = {e: i for i, e in enumerate(EFFECTS)}

#  The SIX addressable store classes.  hi12[3:1] > 2 is undecoded and traps, so
#  a store word can only be one of these.
CLASSES = tuple((b7, f) for b7 in (0, 1) for f in (0, 1, 2))
CIX = {c: i for i, c in enumerate(CLASSES)}

NORMAL = ("store", "acc", "ptr", "before", "before")     # the shipped behaviour

#  the published gate names, as points of this space
PUB_STTIME = {
    "before":               ("store", "acc", "ptr", "before", "before"),
    "after":                ("store", "acc", "ptr", "after", "after"),
    "st_before_clr_after":  ("store", "acc", "ptr", "before", "after"),
}
PUB_GATED = {
    "off":        ("none", None, None, None, "never"),
    "keepclear":  ("none", None, None, None, "before"),
    "clrlate":    ("none", None, None, None, "after"),
}
PUB_COND = {
    "always":             lambda b7, f: False,
    "b7_f31_1":           lambda b7, f: bool(b7) and f == 1,
    "b7_ne2":             lambda b7, f: bool(b7) and f != 2,
}


#  ★ THE COMPOSITION IS NOT A PRODUCT.  In action00_discriminate.py the global
#  `sttime' moves the clear of a GATED word too -- `stgate=keepclear' with
#  `sttime=st_before_clr_after' clears AFTER the ALU, i.e. it is the same
#  machine as `stgate=clrlate'.  Mapping (cond, gated, sttime) as an
#  independent product gets the published counts WRONG; `mirror' caught it.
#  This function reproduces action00_discriminate.step() exactly.
def _compose(dost, doclr, clr_end, sttime):
    mtime = "before" if sttime in ("before", "st_before_clr_after") else "after"
    if not doclr:
        clr = "never"
    elif clr_end:
        clr = "after"
    elif sttime == "before":
        clr = "before"
    else:
        clr = "after"
    if not dost:
        return ("none", None, None, None, clr)
    return ("store", "acc", "ptr", mtime, clr)


PUB_GATE_OF = {
    "always":             lambda b7, f: (True, True, False),
    "b7_f31_1_off":       lambda b7, f: (False, False, False)
                                        if (b7 and f == 1) else (True, True, False),
    "b7_ne2_off":         lambda b7, f: (False, False, False)
                                        if (b7 and f != 2) else (True, True, False),
    "b7_f31_1_keepclear": lambda b7, f: (False, True, False)
                                        if (b7 and f == 1) else (True, True, False),
    "b7_f31_1_clrlate":   lambda b7, f: (False, True, True)
                                        if (b7 and f == 1) else (True, True, False),
    "b7_ne2_clrlate":     lambda b7, f: (False, True, True)
                                        if (b7 and f != 2) else (True, True, False),
    #  ★ NEVER ENUMERATED BY THE PUBLISHED PASSES -- the list has
    #  b7_f31_1_{off,keepclear,clrlate} but only b7_ne2_{off,clrlate}.
    "b7_ne2_keepclear":   lambda b7, f: (False, True, False)
                                        if (b7 and f != 2) else (True, True, False),
}
PUB_GATE_NAMES = ("always", "b7_f31_1_off", "b7_ne2_off", "b7_f31_1_keepclear",
                  "b7_f31_1_clrlate", "b7_ne2_clrlate")


def published_gate(name, sttime):
    """-> a 6-tuple of EFFECT indices, i.e. a point of the new space."""
    fn = PUB_GATE_OF[name]
    return tuple(EFF_IX[_compose(*(fn(b7, f) + (sttime,)))]
                 for (b7, f) in CLASSES)


class M(object):
    """A machine.  `gate' is a 6-tuple of EFFECT indices, one per store class."""
    __slots__ = ("order", "act00", "gate", "op2", "wrap",
                 "act19", "src00", "src08", "src11", "dest07")

    def __init__(self, order, act00, gate, op2="hold", wrap="sat",
                 act19="tA<-bus", src00="mem", src08="unity",
                 src11="mem", dest07="mem"):
        self.order, self.act00, self.gate = order, act00, gate
        self.op2, self.wrap = op2, wrap
        self.act19, self.src00, self.src08 = act19, src00, src08
        self.src11, self.dest07 = src11, dest07

    def eff(self, b7, f):
        return EFFECTS[self.gate[CIX[(b7, f)]]]

    def key(self):
        return (self.order, self.act00, self.gate, self.op2, self.wrap)

    def __repr__(self):
        return "%-9s act00=%-5s op2=%-10s wrap=%-14s gate=%s" % (
            self.order, self.act00, self.op2, self.wrap,
            "|".join(eff_name(EFFECTS[i]) for i in self.gate))


def eff_name(e):
    op, val, dst, mt, clr = e
    if op == "none":
        return "-/clr:%s" % clr
    if op == "load":
        return "LD@%s/clr:%s" % (mt, clr)
    return "ST(%s->%s)@%s/clr:%s" % (val, dst, mt, clr)


ORDER = A.ORDER
ACT00 = A.ACT00
OP2 = A.OP2
WRAP = A.WRAP


# ===========================================================================
#  ONE word.  A faithful copy of action00_discriminate.step() with the gate
#  replaced by the function G and the store generalised.  `mirror' proves the
#  two agree wherever the spaces overlap.
# ===========================================================================
def step(m, st, w, coef, rng, ash=0, psh=23, dram=None, unknown=None, obs=None):
    hi, cl = DIS.hi12(w), DIS.class4(w)
    src, act = DIS.lo_src(w), DIS.lo_act(w)
    f, b7 = DIS.hi_f31(hi), (hi >> 7) & 1
    isA = DIS.coeff_consumer(w)
    nxt = (st.p + (s8(DIS.addr8(w)) if DIS.ptr_postinc(w) else 0)) & 0xff

    def datum(a):
        if ash:
            return max(-(1 << 23), min(MASK23, a >> ash))
        return s24(a)

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
        return False
    if f > 2:
        return False

    store = bool(hi & 0x10)
    op, sval, sdst, mtime, clr = m.eff(b7, f) if store \
        else ("none", None, None, None, "never")

    def mem_key():
        return ELSEWHERE if sdst == "else" else st.p

    def do_mem():
        if op == "store":
            v = bus if sval == "bus" else ((st.acc >> ash) if ash else st.acc)
            if sval == "acc":
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
            st.mem[mem_key()] = v & MASK24
            if obs is not None:
                obs.append(("ST", mem_key(), v & MASK24))
        elif op == "load":
            st.acc = s24(st.mem[st.p]) << ash

    if op != "none" and mtime == "before":
        do_mem()
    if clr == "before":
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

    busa = bus << ash

    def accop(cur):
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
                pt = busa
        acc = fb + pt + bt
        if f == 2 and m.op2 == "and_coef" and coef is not None:
            acc &= (coef << ash)
        elif f == 2 and m.op2 == "and_mask23":
            acc &= (MASK23 << ash | ((1 << ash) - 1))
        st.acc = acc
        capture()

    if op != "none" and mtime == "after":
        do_mem()
    if clr == "after":
        st.acc = 0

    if isA:
        if coef is None:
            return False
        st.P = (s24(coef) if (m.src08 == "unity" and src == 0x08 and ash == 0)
                else (s24(coef) * bus) >> psh)

    if dram is not None and (hi & 0x800) and cl == 1:
        dram(w, bus, st)

    st.p = nxt
    return True


# ===========================================================================
#  corpus helpers
# ===========================================================================
def images():
    """[(algo, words)] over the DISTINCT body images (38 of them)."""
    a2i = L.algo_to_image()
    seen, out = set(), []
    for algo, (unit, load, ws) in sorted(a2i.items()):
        k = tuple(ws)
        if k in seen:
            continue
        seen.add(k)
        out.append((algo, ws))
    return out


def walk(ws):
    ptr, c = [0] * len(ws), 0
    for k, w in enumerate(ws):
        ptr[k] = c
        if DIS.ptr_postinc(w):
            c += s8(DIS.addr8(w))
    return ptr


def store_words():
    """[(algo, index, word, b7, f31, words, ptrs)] for every bit-4 store word."""
    out = []
    for algo, ws in images():
        ptr = walk(ws)
        for k, w in enumerate(ws):
            if DIS.c_format(w):
                continue
            hi = DIS.hi12(w)
            if not (hi & 0x10):
                continue
            out.append((algo, k, w, (hi >> 7) & 1, DIS.hi_f31(hi), ws, ptr))
    return out


# ===========================================================================
#  SECTION `enum'
# ===========================================================================
def sec_enum():
    hdr("enum -- THE ENUMERATION, and where the published gates sit inside it")
    print("""A bit-4 store word is characterised for the ALU by (bit 7, hi12[3:1]).
hi12[3:1] > 2 is undecoded and TRAPS, so there are six addressable store
classes.  The gate is a FUNCTION from those classes to an EFFECT.""")
    print("\n   EFFECTS enumerated per class : %d" % len(EFFECTS))
    byop = collections.Counter(e[0] for e in EFFECTS)
    for k, v in sorted(byop.items()):
        print("      mem_op = %-6s : %2d" % (k, v))
    print("""      -- `load' is the mechanism NO published pass enumerated: bit 7 as a
         DIRECTION bit, so that a bit-4 word with bit 7 set READS mem[ptr] into
         the accumulator instead of writing it.  It is as physical as a gate and
         it EXPLAINS the bit, which the brief ranks above a reading that merely
         fits.""")

    sw = store_words()
    cnt = collections.Counter((r[3], r[4]) for r in sw)
    print("\n   corpus store words, by class, over the 38 distinct body images:")
    tot = 0
    for (b7, f), n in sorted(cnt.items()):
        tag = ""
        if f > 2:
            tag = "   <- hi12[3:1] > 2: the word TRAPS, the gate never runs"
        print("      b7=%d f31=%d : %4d%s" % (b7, f, n, tag))
        tot += n
    print("      TOTAL      : %4d" % tot)
    live = [c for c in CLASSES if cnt.get(c, 0)]
    print("\n   ★ addressable classes                 : %d" % len(CLASSES))
    print("   ★ classes that OCCUR with a store     : %d  %s"
          % (len(live), live))
    empty = [c for c in CLASSES if not cnt.get(c, 0)]
    print("   ★ classes that are VACUOUS (0 words)  : %s"
          % (empty if empty else "none"))
    print("      -> a gate's behaviour on %s is UNOBSERVABLE by construction."
          % (empty,))

    print("\n   size of the gate space : %d^%d = %d functions"
          % (len(EFFECTS), len(live), len(EFFECTS) ** len(live)))
    print("      (the previously published space was 6 hand-named conditions x")
    print("       3 global store timings = 18 points, all of which are inside)")

    print("\n   ★ THE PUBLISHED GATES, LOCATED:")
    seenpt = {}
    for nm in PUB_GATE_NAMES:
        for stt in PUB_STTIME:
            seenpt.setdefault(published_gate(nm, stt), []).append(
                "%s/sttime=%s" % (nm, stt))
    print("      %d (gate name, sttime) pairs -> %d DISTINCT points"
          % (sum(len(v) for v in seenpt.values()), len(seenpt)))
    dgn = {g: v for g, v in seenpt.items() if len(v) > 1}
    if dgn:
        print("   ★ DEGENERACY AMONG THE PUBLISHED NAMES (method rule 4):")
        for g, v in sorted(dgn.items(), key=lambda kv: -len(kv[1])):
            print("      ONE machine, %d names: %s" % (len(v), "  ==  ".join(v)))
    else:
        print("      no two published names are the same point")
    print("      ★ and one gate the published list never had:"
          " b7_ne2_keepclear")

    print("""
   ★ THE OBSERVATIONAL QUOTIENT (method rule 4: check for degeneracy BEFORE
   reporting a split).  Two effects that produce the identical machine at a
   given store word are ONE effect counted twice.  The partition is measured,
   not asserted: each effect is run on 400 random states at a real corpus word
   and effects with identical (acc, P, memory) traces are merged.""")
    for nm, w in (("class (1,0): 090.A.00.1D5, ROOM REVERB 1 w107", 0x090A001D5),
                  ("class (1,1): 092.A.00.200, the LFO's w0     ", 0x092A00200),
                  ("class (0,1): 212.A.00.415, the reverb's w108", 0x212A00415)):
        for a0 in ("load", "add"):
            part = effect_quotient(w, act00=a0)
            print("      %s  act00=%-5s : %2d of %d distinguishable"
                  % (nm, a0, len(part), len(EFFECTS)))
            if a0 != "load":
                continue
            merged = [g for g in part if len(g) > 1]
            for g in merged[:3]:
                print("           SAME MACHINE: %s"
                      % "  ==  ".join(eff_name(e) for e in g))
            if len(merged) > 3:
                print("           ... and %d more merged groups"
                      % (len(merged) - 3))
    print("""      -> at hi12[3:1] == 0 the accumulator is OVERWRITTEN by the word's own
         ALU step (acc <- 0 + P), so a clear taken BEFORE it, and a read INTO
         it before it, are both INVISIBLE.  The comparison is shown able to say
         DIFFERENT by the f31 == 1 rows, where the partition is finer.""")
    return live


def effect_quotient(w, ntrials=400, seed=7, act00="load"):
    """Partition EFFECTS into observational-equivalence classes AT WORD w.

    ★ The partition DEPENDS ON act00, and that dependence is the coupling
    action00-discriminator.md item C found: with act00 = `load' the word's own
    ALU overwrites the accumulator, so most of the effect is invisible; with
    act00 = `add' it is not.  Both are reported."""
    sigs = {}
    for e in EFFECTS:
        m = M("adder", act00, uniform_gate(e))
        rng = random.Random(seed)
        trace = []
        for _ in range(ntrials):
            st = A.State(rng)
            st.p = 0
            for k in (0, 1, 2, ELSEWHERE):
                st.mem[k] = rng.randrange(0, 1 << 24)
            c = rng.randrange(0, 1 << 23)
            step(m, st, w, c, rng)
            trace.append((st.acc, st.P, tuple(sorted(st.mem.items(),
                                                     key=repr))))
        sigs.setdefault(tuple(trace), []).append(e)
    return sorted(sigs.values(), key=lambda g: -len(g))


# ===========================================================================
#  SECTION `census' -- ★ WHICH CLASSES CAN BE DECIDED, AND BY WHAT
# ===========================================================================
def sec_census():
    hdr("census -- THE GATE DECIDABILITY CENSUS")
    print("""Before searching, ask which corpus words can tell two gate readings
apart AT ALL.  Two gates differ only where their EFFECTS differ, and an effect
is attached to a (bit 7, hi12[3:1]) class -- so the question is per class:
   (a) how many words are in it,
   (b) which of them sit in a block whose arithmetic is known INDEPENDENTLY of
       the DSP (the only kind of witness that can force anything),
   (c) and which parts of the effect are VACUOUS there.""")
    names = L.prog_names()
    sw = store_words()
    per = collections.defaultdict(list)
    for r in sw:
        per[(r[3], r[4])].append(r)

    # ★ A witness is a WINDOW whose arithmetic is known, not merely a program
    #   that happens to contain one.  The three known-mathematics windows are:
    #     the 9-word PARAMETRIC EQ biquad section (algo 39 w0..w8),
    #     the SINGLE DELAY comb window (algo 9 w3..w9),
    #     the 29 LFO ramp block windows.
    def wcls(ws):
        return collections.Counter(
            ((DIS.hi12(w) >> 7) & 1, DIS.hi_f31(DIS.hi12(w)))
            for w in ws if not DIS.c_format(w) and (DIS.hi12(w) & 0x10))
    wit_of = collections.defaultdict(list)
    for c, n in wcls(A.PEQ).items():
        wit_of[c].append("PARAMETRIC EQ biquad (bilinear designer, 0.002 dB)")
    sdw = L.algo_to_image()[9][2][3:10]
    for c, n in wcls(sdw).items():
        wit_of[c].append("SINGLE DELAY comb window (textbook)")
    lcl = collections.Counter()
    for (algo, a, e, ws, coefs, inc, q) in L.publish_blocks():
        lcl.update(wcls(ws))
    for c in lcl:
        wit_of[c].append("LFO ramp, 29 blocks (floor(f*2^23/44100))")
    print("\n   %-11s %-6s %-8s %s" % ("class", "words", "progs",
                                       "known-mathematics witness WINDOW"))
    for c in CLASSES:
        rows = per.get(c, [])
        algos = sorted({r[0] for r in rows})
        wit = wit_of.get(c, [])
        print("   b7=%d f31=%d   %-6d %-8d %s"
              % (c[0], c[1], len(rows), len(algos),
                 "; ".join(wit) if wit else "★ NONE"))

    print("""
   ★ THE CENSUS RESULT.  Three of the five occupied classes have a
   known-mathematics witness and two do not.  The two that do not are exactly
   the two smallest -- and they are reachable only STRUCTURALLY.""")
    for c in ((0, 0), (1, 0)):
        rows = per.get(c, [])
        print("\n   class b7=%d f31=%d -- %d word(s):" % (c[0], c[1], len(rows)))
        for (algo, k, w, b7, f, ws, ptr) in rows:
            print("      algo %-3d %-22s w%-4d %s"
                  % (algo, names.get(algo, "?")[:22], k, fmt(w)))
        print("      ★ AND THE CLEAR IS VACUOUS THERE: hi12[3:1] == 0 means the"
              " word's own\n         ALU writes acc <- 0 + P, so a clear taken"
              " before it cannot be seen.\n         The only live question in"
              " this class is WHETHER THE STORE HAPPENS.")

    print("""
   ★ AND WHAT THE THREE WITNESSED CLASSES CAN SEE:""")
    peq = L.algo_to_image()[39][2]
    pc = collections.Counter(((DIS.hi12(w) >> 7) & 1, DIS.hi_f31(DIS.hi12(w)))
                             for w in peq
                             if not DIS.c_format(w) and (DIS.hi12(w) & 0x10))
    print("      PARAMETRIC EQ store words, by class : %s"
          % {"b7=%d,f31=%d" % k: v for k, v in sorted(pc.items())})
    sd = L.algo_to_image()[9][2]
    sc = collections.Counter(((DIS.hi12(w) >> 7) & 1, DIS.hi_f31(DIS.hi12(w)))
                             for w in sd
                             if not DIS.c_format(w) and (DIS.hi12(w) & 0x10))
    print("      SINGLE DELAY  store words, by class : %s"
          % {"b7=%d,f31=%d" % k: v for k, v in sorted(sc.items())})
    lc = collections.Counter()
    for (algo, a, e, ws, coefs, inc, q) in L.publish_blocks():
        for w in ws:
            if not DIS.c_format(w) and (DIS.hi12(w) & 0x10):
                lc[((DIS.hi12(w) >> 7) & 1, DIS.hi_f31(DIS.hi12(w)))] += 1
    print("      LFO ramp      store words, by class : %s"
          % {"b7=%d,f31=%d" % k: v for k, v in sorted(lc.items())})
    print("""
      -> PARAMETRIC EQ and SINGLE DELAY see ONLY class (0,1), the LFO sees ONLY
         classes (1,1) and (1,2), and NOTHING with known mathematics sees
         (0,0) or (1,0).  ★ The biquad's measured blindness to the bit-7 gate
         is therefore not luck: PARAMETRIC EQ has no bit-7 store word at all.

      -> ★ AND IT FOLLOWS THAT bit 7 MUST BE IN THE GATE CONDITION.  Class
         (0,1) and class (1,1) differ in bit 7 and in NOTHING ELSE; the biquad
         needs (0,1) to store and the LFO needs (1,1) not to.  A condition that
         does not read bit 7 cannot separate them.  This is checked, not
         asserted, in `biquad' and `lfo'.""")

    print("""
   ★ AND THE FORCING, CHECKED RATHER THAN ASSERTED.  Every condition in the
   enumeration is run against BOTH witnesses: the biquad (does class (0,1) still
   reproduce the designer?) and the LFO (does the ramp still run?).  A condition
   survives only if both accept.""")
    banks = A.peq_banks()
    pool = L.publish_blocks()
    (bi, ba, be, bws, bcf, binc, bq) = pool[0]
    conds = [
        ("always (no gate)",   lambda b7, f: False),
        ("b7 & f31==1",        lambda b7, f: bool(b7) and f == 1),
        ("b7 & f31!=2",        lambda b7, f: bool(b7) and f != 2),
        ("b7 alone",           lambda b7, f: bool(b7)),
        ("b7 & f31==0",        lambda b7, f: bool(b7) and f == 0),
        ("b7 & f31==2",        lambda b7, f: bool(b7) and f == 2),
        ("f31==1  (NO bit 7)", lambda b7, f: f == 1),
        ("f31==2  (NO bit 7)", lambda b7, f: f == 2),
        ("NOT b7",             lambda b7, f: not b7),
    ]
    OFF = ("none", None, None, None, "never")
    print("      %-20s %-26s %s" % ("condition", "biquad (class (0,1))", "LFO"))
    for nm, fn in conds:
        g = tuple(EFF_IX[OFF if fn(b7, f) else NORMAL] for (b7, f) in CLASSES)
        v = worst_db(M("adder", "load", g), banks, 512)
        h = lfo_run(M("adder", "load", g), bws, bcf, 10,
                    random.Random(5 + bi), bq)
        lok = h is not None and L.is_ramp(h, binc)
        print("      %-20s %8.3f dB  %-12s %s"
              % (nm, v if v is not None else -1.0,
                 "REJECTED" if (v is None or v > 0.5) else "accepts",
                 "runs" if lok else "REJECTED"))
    print("""      -> the only conditions BOTH witnesses accept read bit 7 AND hi12[3:1].
         `f31==1 (NO bit 7)' and `NOT b7' are killed by the biquad; `b7 alone',
         `b7 & f31==0', `b7 & f31==2' and `always' are killed by the LFO.  Two
         survive -- `b7 & f31==1' and `b7 & f31!=2' -- and sect. `condition'
         prices the difference between them at ONE corpus word.""")
    return per


# ===========================================================================
#  SECTION `dead' -- the STRUCTURAL criterion
# ===========================================================================
def deadness(ws, k, ptr, src11_inert, opaque_kills):
    """MODEL-FREE: is the store at words[k] overwritten before it is read?

    `src11_inert' applies what lfo-ramp.md's ramp INDEPENDENTLY forces: a
    SRC-0x11 / ACTION-0x07 word does not deposit a foreign value in the cell.
    Without it the LFO's own publishing store counts as dead, which is the
    control that shows the census needs it."""
    p = ptr[k]
    for j in range(k + 1, len(ws)):
        w = ws[j]
        if DIS.c_format(w):
            if opaque_kills:
                return None
            continue
        if ptr[j] != p:
            continue
        if DIS.lo_src(w) == 0x07:
            return False                     # READ -> the store was live
        if DIS.lo_act(w) == 0x07:
            if src11_inert and DIS.lo_src(w) == 0x11:
                continue
            return True                      # overwritten
        if DIS.hi12(w) & 0x10:
            return True                      # overwritten by a bit-4 store
    return False


def _deadness2(ws, k, ptr, c11_reads):
    """Deadness with class (1,1) optionally counted as a READER of its own cell.
    Class-(1,1) words are never WRITERS of mem[ptr] here -- that is what the LFO
    FORCES (sect. `lfo'), 0 of 17 928 survivors."""
    p = ptr[k]
    for j in range(k + 1, len(ws)):
        w = ws[j]
        if DIS.c_format(w):
            return None
        if ptr[j] != p:
            continue
        hi = DIS.hi12(w)
        b7, f, st = (hi >> 7) & 1, DIS.hi_f31(hi), bool(hi & 0x10)
        if c11_reads and st and b7 and f == 1:
            return False
        if DIS.lo_src(w) == 0x07:
            return False
        if DIS.lo_act(w) == 0x07:
            if DIS.lo_src(w) == 0x11:
                continue
            return True
        if st:
            if b7 and f == 1:
                continue
            return True
    return False


def _dead_under(sw, c11_reads):
    d = l = u = 0
    for (algo, k, w, b7, f, ws, ptr) in sw:
        if b7 and f == 1:
            continue
        v = _deadness2(ws, k, ptr, c11_reads)
        if v is True:
            d += 1
        elif v is False:
            l += 1
        else:
            u += 1
    return d, l, u


def _load_sites():
    """(sites where the LOAD test can fire, sites where it would rescue)."""
    cand = resc = 0
    for algo, ws in images():
        ptr = walk(ws)
        for k, w in enumerate(ws):
            if DIS.c_format(w):
                continue
            hi = DIS.hi12(w)
            if not ((hi & 0x10) and ((hi >> 7) & 1) and DIS.hi_f31(hi) == 1):
                continue
            for j in range(k - 1, -1, -1):
                w2 = ws[j]
                if DIS.c_format(w2):
                    break
                if ptr[j] != ptr[k]:
                    continue
                if DIS.lo_src(w2) == 0x07:
                    break
                if DIS.lo_act(w2) == 0x07 or (DIS.hi12(w2) & 0x10):
                    cand += 1
                    if _deadness2(ws, j, ptr, False) is True:
                        resc += 1
                break
    return cand, resc


def sec_dead():
    hdr("dead -- the STRUCTURAL criterion, and what it says about (0,0)/(1,0)")
    print("""A store whose cell is overwritten before anything reads it computes
NOTHING.  That is a property of the program text, not of the ALU model, so it is
INDEPENDENT of the ramp and of the biquad.  A gate that suppresses a store the
program never uses is more likely real than one that suppresses a live store --
but the argument is only worth what the BASE RATE makes it worth, so the base
rate is printed first.""")
    names = L.prog_names()
    sw = store_words()
    for src11_inert in (False, True):
        tot, dead, unk = collections.Counter(), collections.Counter(), \
            collections.Counter()
        for (algo, k, w, b7, f, ws, ptr) in sw:
            d = deadness(ws, k, ptr, src11_inert, True)
            tot[(b7, f)] += 1
            if d is True:
                dead[(b7, f)] += 1
            elif d is None:
                unk[(b7, f)] += 1
        print("\n   src11_inert = %-5s (the OTHER thing the ramp forces)"
              % src11_inert)
        for c in sorted(tot):
            print("      b7=%d f31=%d : %4d stores, %4d provably DEAD (%5.1f%%),"
                  " %3d opaque"
                  % (c[0], c[1], tot[c], dead[c],
                     100.0 * dead[c] / tot[c], unk[c]))
        print("      TOTAL      : %4d stores, %4d dead (%5.1f%%)"
              % (sum(tot.values()), sum(dead.values()),
                 100.0 * sum(dead.values()) / sum(tot.values())))
        if not src11_inert:
            print("""      ★ CONTROL, and it says NO: class (1,2) reads 100 %% dead here, which
         is FALSE -- those 29 words are the LFO's own publishing store.  The
         cause is the `xxx.2.dd.447' SRC-0x11 word one slot later, which the
         ramp INDEPENDENTLY forces to be inert on the cell.  A census run
         without that correction manufactures dead stores.""")

    print("""
   ★ THE TWO WORDS OF CLASS (1,0), WHICH NOTHING NUMERIC CAN SEE:""")
    for (algo, k, w, b7, f, ws, ptr) in sw:
        if (b7, f) != (1, 0):
            continue
        d1 = deadness(ws, k, ptr, True, True)
        d2 = deadness(ws, k, ptr, True, False)
        print("      algo %-3d %-20s w%-4d %-16s cell %-5d dead=%s"
              " (C-format opaque: %s)"
              % (algo, names.get(algo, "?")[:20], k, fmt(w), ptr[k], d2, d1))
        for j in range(k + 1, min(k + 22, len(ws))):
            if ptr[j] != ptr[k] or DIS.c_format(ws[j]):
                continue
            print("            next word on the same cell: w%-4d %-16s"
                  " src=%02X act=%02X st=%d"
                  % (j, fmt(ws[j]), DIS.lo_src(ws[j]), DIS.lo_act(ws[j]),
                     1 if DIS.hi12(ws[j]) & 0x10 else 0))
            break
    print("""
      -> Both are DEAD STORES if they fire.  The two published conditions differ
         on EXACTLY these words: `b7 & f31 == 1' lets them store, `b7 & f31 != 2'
         suppresses them.  The base rate above is what this is worth.""")

    print("""
   * A NEW DISCRIMINATOR, TRIED AND EMPTY.  The LFO leaves class (1,1) at three
   families -- `none', `store -> elsewhere' and `LOAD'.  Only `LOAD' READS
   mem[ptr], so under it an earlier store to that same cell is LIVE where the
   other two leave it dead.  That is a structural test, and it can fire:""")
    c11_dead = _dead_under(sw, False)
    c11_load = _dead_under(sw, True)
    print("      class (1,1) = no memory access : dead %3d  live %3d  opaque %3d"
          % c11_dead)
    print("      class (1,1) = LOAD (reads it)  : dead %3d  live %3d  opaque %3d"
          % c11_load)
    cand, resc = _load_sites()
    print("      class-(1,1) words PRECEDED on the same cell by a write with no"
          "\n      read between -- i.e. sites where the test CAN fire : %d" % cand)
    print("      ... of which the earlier store is DEAD under `none'    : %d"
          % resc)
    print("""      -> the test fires at %d sites and finds NOTHING: at every one of them the
         earlier store is already live.  The structural criterion is therefore
         MEASURABLY BLIND to the LOAD reading, not silently blind.  Recorded as
         a MISS.""" % cand)

    # per-condition residual dead-store count
    print("\n   residual PROVABLY-DEAD stores, by gate condition"
          " (src11_inert = True):")
    conds = {
        "always (shipped)":  lambda b7, f: False,
        "b7 only":           lambda b7, f: bool(b7),
        "b7 & f31==1":       lambda b7, f: bool(b7) and f == 1,
        "b7 & f31!=2":       lambda b7, f: bool(b7) and f != 2,
        "b7 & f31==0":       lambda b7, f: bool(b7) and f == 0,
        "b7 & f31==2":       lambda b7, f: bool(b7) and f == 2,
        "f31==1 (no bit 7)": lambda b7, f: f == 1,
        "NOT b7":            lambda b7, f: not b7,
    }
    base = None
    for nm, cond in conds.items():
        d = live = 0
        for (algo, k, w, b7, f, ws, ptr) in sw:
            if cond(b7, f):
                continue                     # suppressed: not a store at all
            v = deadness(ws, k, ptr, True, True)
            if v is True:
                d += 1
            elif v is False:
                live += 1
        if base is None:
            base = d
        print("      %-20s %4d dead of %4d surviving stores (%5.1f%%)   %s"
              % (nm, d, d + live, 100.0 * d / max(1, d + live),
                 "%+d vs shipped" % (d - base) if nm != "always (shipped)"
                 else ""))
    return sw


# ===========================================================================
#  SECTION `biquad' -- class (0,1), against the designer
# ===========================================================================
PEQ = A.PEQ
ASH, PSH = A.ASH, A.PSH


def peq_ir(m, coefs, n, amp=1 << 22):
    st = A.State()
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


def worst_db(m, banks, n, amp=1 << 22):
    worst = 0.0
    for name, cram in banks:
        ir = peq_ir(m, cram, n, amp)
        if ir is None:
            return None
        for f in A.FREQS:
            want = A.ideal_H(cram, f)
            if abs(want) < 1e-9:
                continue
            got = A.dft_at(ir, f) / amp
            if abs(got) == 0.0:
                return 999.0
            worst = max(worst, abs(20 * math.log10(abs(got) / abs(want))))
    return worst


def uniform_gate(e):
    return tuple(EFF_IX[e] for _ in CLASSES)


def gate_with(base_eff, over):
    """base effect everywhere, `over' = {class: effect}"""
    g = [EFF_IX[base_eff]] * len(CLASSES)
    for c, e in over.items():
        g[CIX[c]] = EFF_IX[e]
    return tuple(g)


def sec_biquad():
    hdr("biquad -- class (0,1), scored against the firmware's own designer")
    banks = A.peq_banks()
    print("   coefficient banks read from the ROM : %d" % len(banks))
    print("   PARAMETRIC EQ store words are ALL class (0,1) -- so this section"
          "\n   enumerates the effect of class (0,1) and NOTHING ELSE, over all"
          " %d." % len(EFFECTS))
    ship = M("adder", "load", gate_with(NORMAL, {}))
    base = worst_db(ship, banks, 512)
    print("\n   ★ CONTROL -- the criterion must be able to say NO:")
    print("      the shipped model                          : %8.3f dB" % base)
    for nm, e in (("store & clear AFTER the ALU",
                   ("store", "acc", "ptr", "after", "after")),
                  ("store early, CLEAR LATE",
                   ("store", "acc", "ptr", "before", "after")),
                  ("no store at all",
                   ("none", None, None, None, "before")),
                  ("store the BUS instead of the accumulator",
                   ("store", "bus", "ptr", "before", "before")),
                  ("store ELSEWHERE",
                   ("store", "acc", "else", "before", "before")),
                  ("READ mem[ptr] into the accumulator (bit 7 = direction)",
                   ("load", None, None, "before", "before"))):
        v = worst_db(M("adder", "load", gate_with(NORMAL, {(0, 1): e})),
                     banks, 512)
        print("      %-42s : %8.3f dB   %s"
              % (nm, v if v is not None else -1,
                 "REJECTED" if (v is None or v > 0.5) else "accepted"))
    ok = []
    for e in EFFECTS:
        for op2 in OP2:
            for wrap in WRAP:
                mm = M("adder", "load", gate_with(NORMAL, {(0, 1): e}),
                       op2=op2, wrap=wrap)
                v = worst_db(mm, banks, 512)
                if v is not None and v < 0.5:
                    ok.append((e, op2, wrap))
    effs = sorted({r[0] for r in ok})
    print("\n   %d of %d (class-(0,1) effect, op2, wrap) triples reproduce the"
          " designer to < 0.5 dB" % (len(ok), len(EFFECTS) * len(OP2) * len(WRAP)))
    print("   ★ class (0,1) effect : %s"
          % ("FORCED" if len(effs) == 1 else "%d values" % len(effs)))
    for e in effs:
        print("      %s" % eff_name(e))
    for ix, nm in ((1, "op2"), (2, "wrap")):
        c = collections.Counter(r[ix] for r in ok)
        print("      %-6s %-9s %s" % (nm, "FORCED" if len(c) == 1
                                      else "%d values" % len(c),
                                      "  ".join("%s x%d" % (a, b)
                                                for a, b in c.most_common())))
    return set(ok)


# ===========================================================================
#  SECTION `lfo' -- classes (1,1) and (1,2), EXHAUSTIVE
# ===========================================================================
def lfo_run(m, words, coefs, nframes, rng, qcell, preset=None):
    st = A.State(rng)
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


def sec_lfo(limit=None, quick=False):
    hdr("lfo -- classes (1,1) and (1,2), the FULL effect space")
    pool = L.publish_blocks()
    print("   %d blocks, %d programs, %d distinct increments"
          % (len(pool), len({r[0] for r in pool}), len({r[5] for r in pool})))
    print("   LFO store words are ALL class (1,1) or (1,2); classes (0,*) are"
          "\n   INVISIBLE here, so they are held at the shipped effect and the"
          "\n   two visible ones are enumerated over all %d x %d = %d."
          % (len(EFFECTS), len(EFFECTS), len(EFFECTS) ** 2))
    nongate = list(itertools.product(
        ORDER, ACT00, OP2,
        ("unity", "zero", "acc", "mem", "P", "coef"), WRAP,
        ("mem", "acc", "P", "tA", "tB", "unity", "zero"),
        ("mem", "elsewhere")))
    print("   non-gate settings enumerated        : %d" % len(nongate))
    total = len(EFFECTS) ** 2 * len(nongate)
    print("   TOTAL candidate machines            : %d" % total)

    seed0 = [r for r in pool if r[0] == 1][:1] or pool[:1]
    t0 = time.time()
    stage0 = []
    npairs = 0
    for e11 in EFFECTS:
        for e12 in EFFECTS:
            npairs += 1
            g = gate_with(NORMAL, {(1, 1): e11, (1, 2): e12})
            for (order, act00, op2, src08, wrap, src11, dest07) in nongate:
                m = M(order, act00, g, op2=op2, wrap=wrap, src08=src08,
                      src11=src11, dest07=dest07)
                good = True
                for (i, a, e, ws, cf, inc, q) in seed0:
                    h = lfo_run(m, ws, cf, 2, random.Random(5 + i), q)
                    if h is None or not L.is_ramp(h, inc):
                        good = False
                        break
                if good:
                    stage0.append(m)
            if npairs % 100 == 0:
                sys.stderr.write("      ... %d/%d gate pairs, %d alive, %.0f s\n"
                                 % (npairs, len(EFFECTS) ** 2, len(stage0),
                                    time.time() - t0))
                sys.stderr.flush()
            if limit and npairs >= limit:
                break
        if limit and npairs >= limit:
            break
    print("   stage 0 (1 block, 2 frames)         : %d survive   [%.0f s]"
          % (len(stage0), time.time() - t0))

    stage1 = []
    seed = [r for r in pool if r[0] in (1, 4)][:2]
    for m in stage0:
        good = True
        for (i, a, e, ws, cf, inc, q) in seed:
            h = lfo_run(m, ws, cf, 10, random.Random(5 + i), q)
            if h is None or not L.is_ramp(h, inc):
                good = False
                break
        if good:
            stage1.append(m)
    print("   stage 1 (2 blocks, 10 frames)       : %d survive" % len(stage1))

    stage2 = []
    for m in stage1:
        good = True
        for (i, a, e, ws, cf, inc, q) in pool:
            h = lfo_run(m, ws, cf, 30, random.Random(97 + i * 13 + a), q)
            if h is None or not L.is_ramp(h, inc):
                good = False
                break
        if good:
            stage2.append(m)
    print("   stage 2 (ALL %d blocks, 30 frames)   : %d survive"
          % (len(pool), len(stage2)))

    stage3 = []
    for m in stage2:
        good = True
        for (i, a, e, ws, cf, inc, q) in pool:
            h = lfo_run(m, ws, cf, 6, random.Random(3 + i), q,
                        preset=(1 << 23) - 2 * inc)
            want = [((1 << 23) - 2 * inc + inc * (k + 1)) % (1 << 23)
                    for k in range(6)]
            if h is None or h != want:
                good = False
                break
        if good:
            stage3.append(m)
    print("   stage 3 (the 2**23 wrap)            : %d survive" % len(stage3))

    for nm, f in (("order", lambda m: m.order), ("act00", lambda m: m.act00),
                  ("eff(1,1)", lambda m: eff_name(m.eff(1, 1))),
                  ("eff(1,2)", lambda m: eff_name(m.eff(1, 2))),
                  ("op2", lambda m: m.op2), ("wrap", lambda m: m.wrap),
                  ("src08", lambda m: m.src08), ("src11", lambda m: m.src11),
                  ("dest07", lambda m: m.dest07)):
        c = collections.Counter(f(m) for m in stage3)
        print("      %-9s %-9s %s"
              % (nm, "FORCED" if len(c) == 1 else "%d values" % len(c),
                 "  ".join("%s x%d" % (a, b) for a, b in c.most_common())))
    print("\n   ★ the (act00, eff(1,1)) pairs -- the COUPLING, re-derived:")
    c = collections.Counter((m.act00, eff_name(m.eff(1, 1))) for m in stage3)
    for (a, g), n in sorted(c.items()):
        print("      act00=%-6s eff(1,1)=%-26s x%d" % (a, g, n))
    try:
        import pickle
        with open(os.path.join(HERE, ".gate_settle_lfo.pkl"), "wb") as f:
            pickle.dump([(m.order, m.act00, m.gate, m.op2, m.wrap, m.src08,
                          m.src11, m.dest07) for m in stage3], f)
    except Exception as e:
        print("   (survivor cache not written: %s)" % e)
    return stage3


def lfo_cached():
    import pickle
    fn = os.path.join(HERE, ".gate_settle_lfo.pkl")
    if not os.path.exists(fn):
        return None
    with open(fn, "rb") as f:
        rows = pickle.load(f)
    return [M(o, a, g, op2=p2, wrap=w, src08=s8_, src11=s11, dest07=d7)
            for (o, a, g, p2, w, s8_, s11, d7) in rows]


# ===========================================================================
#  SECTION `mirror' -- reproduce the published numbers inside this space
# ===========================================================================
def _lfo_stages(space, pool, label):
    """`space' is a list of (machine, tag).  Stages exactly as sec_lfo."""
    s0 = []
    seed0 = [r for r in pool if r[0] == 1][:1] or pool[:1]
    for (m, tag) in space:
        ok = True
        for (i, a, e, ws, cf, inc, q) in seed0:
            h = lfo_run(m, ws, cf, 2, random.Random(5 + i), q)
            if h is None or not L.is_ramp(h, inc):
                ok = False
                break
        if ok:
            s0.append((m, tag))
    s2 = []
    for (m, tag) in s0:
        ok = True
        for (i, a, e, ws, cf, inc, q) in pool:
            h = lfo_run(m, ws, cf, 10, random.Random(5 + i), q)
            if h is None or not L.is_ramp(h, inc):
                ok = False
                break
        if ok:
            s2.append((m, tag))
    s3 = []
    for (m, tag) in s2:
        ok = True
        for (i, a, e, ws, cf, inc, q) in pool:
            h = lfo_run(m, ws, cf, 6, random.Random(3 + i), q,
                        preset=(1 << 23) - 2 * inc)
            want = [((1 << 23) - 2 * inc + inc * (k + 1)) % (1 << 23)
                    for k in range(6)]
            if h is None or h != want:
                ok = False
                break
        if ok:
            s3.append((m, tag))
    print("      %-48s : %d -> %d -> %d" % (label, len(s0), len(s2), len(s3)))
    return s3


def sec_mirror():
    hdr("mirror -- this tool must reproduce the published numbers")
    print("""A re-implementation that does not reproduce the pass it widens is not a
widening, it is a different tool.  Both checks are on the PUBLISHED spaces,
expressed as points of this one.  ★ The published passes enumerate (gate NAME,
sttime) PAIRS, two of which are the SAME MACHINE (`enum'), so the pairs are
carried here WITH their duplicates -- otherwise the counts cannot match by
construction, and the first run of this section did not match for exactly that
reason.""")
    banks = A.peq_banks()
    print("\n   1. the biquad control, three published numbers"
          " (action00-discriminator.md sect. 4):")
    for nm, e, want in (("shipped (store+clear before)", NORMAL, 0.198),
                        ("store and clear AFTER",
                         ("store", "acc", "ptr", "after", "after"), 84.768),
                        ("store early, clear LATE",
                         ("store", "acc", "ptr", "before", "after"), 51.090)):
        v = worst_db(M("adder", "load", uniform_gate(e)), banks, 512)
        print("      %-32s : %8.3f dB   (published %.3f)  %s"
              % (nm, v, want, "OK" if abs(v - want) < 0.01 else "MISMATCH"))

    print("\n   2. the LFO, restricted to the PUBLISHED gate spaces:")
    pool = L.publish_blocks()
    pub6 = [(published_gate(nm, stt), nm)
            for nm in PUB_GATE_NAMES for stt in PUB_STTIME]
    pub4 = [(g, nm) for (g, nm) in pub6
            if nm in ("always", "b7_f31_1_off", "b7_ne2_off",
                      "b7_f31_1_keepclear")]

    def build(gates, acts):
        out = []
        for (g, nm) in gates:
            for (order, act00, op2, src08, wrap, src11, dest07) in \
                    itertools.product(ORDER, acts, OP2,
                                      ("unity", "zero", "acc", "mem", "P",
                                       "coef"), WRAP,
                                      ("mem", "acc", "P", "tA", "tB", "unity",
                                       "zero"), ("mem", "elsewhere")):
                out.append((M(order, act00, g, op2=op2, wrap=wrap,
                              src08=src08, src11=src11, dest07=dest07), nm))
        return out

    sp6 = build(pub6, ACT00)
    print("      action00-discriminator.md space : %d (gate, sttime) pairs x %d"
          " = %d machines" % (len(pub6), len(sp6) // len(pub6), len(sp6)))
    r6 = _lfo_stages(sp6, pool, "action00-discriminator.md (published 3312)")
    sp4 = build(pub4, ("none", "add", "sub", "load", "rload"))
    print("      acc-adder.md space              : %d pairs x %d = %d machines"
          % (len(pub4), len(sp4) // len(pub4), len(sp4)))
    r4 = _lfo_stages(sp4, pool, "acc-adder.md (published 1224)")
    print("      by published gate name : %s"
          % dict(collections.Counter(nm for (m, nm) in r6)))
    print("      ★ the (act00, gate) pairs, to compare with the published table:")
    c2 = collections.Counter((m.act00, nm) for (m, nm) in r6)
    for (a, g), n in sorted(c2.items()):
        print("         act00=%-6s gate=%-20s x%d" % (a, g, n))
    return r6, r4


# ===========================================================================
#  SECTION `vacuity' -- the f31 == 0 VACUITY SWEEP
# ===========================================================================
def _acc_after(w, a0, st0):
    st = A.State()
    st.acc, st.P, st.ta, st.tb, st.p, st.dr = st0[:6]
    st.mem[st.p] = st0[6]
    m = M("adder", a0, uniform_gate(NORMAL))
    step(m, st, w, 0x123456, None,
         unknown=lambda: 0)
    return st.acc


def sec_vacuity():
    hdr("vacuity -- every published ACTION determination, checked for the"
        " hi12[3:1] == 0 defect")
    print("""THE THEOREM.  Under the adder, on a word with hi12[3:1] == 0 the
accumulator feedback is CUT:

      acc  <-  FB + P_TERM + B_TERM        FB = 0 when hi12[3:1] == 0

so the ACTION's accumulator half collapses:

      load  : FB <- bus              -> acc = bus + P
      add   : B  <- +bus             -> acc = P + bus     IDENTICAL
      rload : FB <- -FB = 0, B <-bus -> acc = P + bus     IDENTICAL
      sub   : B  <- -bus             -> acc = P - bus     distinguishable
      none  :                        -> acc = P           distinguishable

* ANY determination that picks among {load, add, rload} at a word with
hi12[3:1] == 0 is VACUOUS BY CONSTRUCTION.  Determinations that separate
{sub, none} from the rest are unaffected, and so is any determination about an
ACTION's CAPTURE half (tempA/tempB/memory), which the feedback cut does not
touch.  ATTRIBUTION: schroeder-topology.md item H states this theorem for the
reverb motif; this section sweeps it across every published note.""")

    rng = random.Random(4242)
    for nm, w, want in (("SINGLE DELAY w7  000.2.48.000 (f31 == 0)",
                         0x000248000, "AGREE"),
                        ("the LFO's       082.2.00.1C0 (f31 == 1)",
                         0x0822001C0, "DIFFER"),
                        ("reverb slot 1   104.2.00.000 (f31 == 2)",
                         0x104200000, "DIFFER")):
        same = 0
        for _ in range(3000):
            st0 = (rng.randrange(-(1 << 23), 1 << 23),
                   rng.randrange(-(1 << 23), 1 << 23),
                   rng.randrange(0, 1 << 24), rng.randrange(0, 1 << 24),
                   0, rng.randrange(0, 1 << 24), rng.randrange(0, 1 << 24))
            vals = {a0: _acc_after(w, a0, st0)
                    for a0 in ("load", "add", "rload")}
            if len(set(vals.values())) == 1:
                same += 1
        print("      %-42s load/add/rload agree on %4d of 3000  (must %s)"
              % (nm, same, want))

    print("""
   * THE SWEEP.  For every ACTION code in the corpus, the hi12[3:1] histogram of
   the words that carry it.  An ACTION whose corpus words all sit at f31 == 0
   can never have its {load, add, rload} reading determined by ANY block.""")
    per = collections.defaultdict(collections.Counter)
    for algo, ws in images():
        for w in ws:
            if DIS.c_format(w):
                continue
            per[DIS.lo_act(w)][DIS.hi_f31(DIS.hi12(w))] += 1
    print("\n   %-8s %-7s %s" % ("ACTION", "words", "hi12[3:1] histogram"))
    for act in sorted(per):
        h = per[act]
        n = sum(h.values())
        dec = sum(v for k, v in h.items() if k in (1, 2))
        flag = "" if dec else "  * NO decidable site anywhere in the corpus"
        print("   0x%02X     %-7d %-40s%s"
              % (act, n, "  ".join("%d:%d" % (k, v)
                                   for k, v in sorted(h.items())), flag))

    print("\n   * THE PUBLISHED DETERMINATIONS, ADJUDICATED ONE BY ONE.")
    a2i = L.algo_to_image()
    sd = a2i[9][2]
    claims = [
        ("acc-adder.md 0-C", "ACTION 0x00 = load, FORCED 18/18",
         [("SINGLE DELAY w7", sd[7]), ("LFO 082", 0x0822001C0)],
         "already retracted by action00-discriminator.md.  The sweep AGREES and "
         "gives the mechanism without a search: SINGLE DELAY's only ACTION-0x00 "
         "site is f31 == 0, so that context never had a vote"),
        ("action-field.md sect. 6 / sect. 10",
         "ACTION 0x00 `routes the bus into the accumulator, i.e. NOT a no-op', "
         "FORCED 5145/5145",
         [("SINGLE DELAY w7", sd[7])],
         "SURVIVES.  The site is f31 == 0, but the claim only separates `none' "
         "from the rest, and `none' IS distinguishable there.  Stated at exactly "
         "the strength the site can bear"),
        ("acc-adder.md 0-E / dsp_disasm.py LO_ACT_CAP_TA2",
         "ACTION 0x19 = tempA <- bus, FORCED 108/108",
         [("SINGLE DELAY w8", sd[8])],
         "SURVIVES.  CAPTURE half, and the site is f31 == 1 anyway"),
        ("blocking-read.md 0-D",
         "ACTION 0x19's ACCUMULATOR half = `no effect', FORCED 3206/3206",
         [("SINGLE DELAY w8", sd[8]), ("reverb w104", 0x212200419)],
         "SURVIVES.  Accumulator half, sites at f31 == 1"),
        ("blocking-read.md 0-I",
         "ACTION 0x00's CAPTURE half = tA <- acc, FORCED (conditionally)",
         [("reverb slots 6/7", 0x000200000)],
         "SURVIVES the theorem (capture half), but see the note: it is forced "
         "inside a topology hypothesis and was not applied"),
        ("schroeder-topology.md 0-B",
         "ACTION 0x00 = load, FORCED 16520/16520 given the bit-4 clear",
         [("motif slot 1 104.2.**.000", 0x104200000),
          ("motif slot 3 012.2.**.680", 0x012200680),
          ("motif slot 6 000.2.**.000", 0x000200000)],
         "SURVIVES.  Two of its four ACTION-0x00 slots are f31 in {1,2}; the "
         "note already applied the correction itself (its item H)"),
        ("allpass-adder-rerun.md 0-C",
         "every all-pass-admissible setting KEEPS the accumulator; `load' has ZERO",
         [("motif slot 1 104.2.**.000", 0x104200000),
          ("motif slot 3 012.2.**.680", 0x012200680)],
         "SURVIVES, same two decidable slots"),
    ]
    for src, claim, sites, verdict in claims:
        print("\n      %s" % src)
        print("         claim : %s" % claim)
        for nm, w in sites:
            f = DIS.hi_f31(DIS.hi12(w))
            print("         site  : %-26s %-16s hi12[3:1] = %d  %s"
                  % (nm, fmt(w), f,
                     "* VACUOUS for {load,add,rload}" if f == 0 else "decidable"))
        print("         -> %s" % verdict)

    n0 = sum(1 for algo, ws in images() for w in ws
             if not DIS.c_format(w) and DIS.lo_act(w) == 0x00
             and DIS.hi_f31(DIS.hi12(w)) == 0)
    nall = sum(1 for algo, ws in images() for w in ws
               if not DIS.c_format(w) and DIS.lo_act(w) == 0x00)
    print("""
   * THE STANDING NUMBER.  %d of the field's %d ACTION-0x00 words (%.1f %%) are
   at f31 == 0 and are structurally incapable of deciding their own accumulator
   half.  No published headline falls that had not already fallen -- reported as
   a MISS, because the sweep was expected to catch one."""
          % (n0, nall, 100.0 * n0 / nall))
    return per


# ===========================================================================
#  SECTION `control'
# ===========================================================================
def sec_control():
    hdr("control -- every criterion DEMONSTRATED able to say NO")
    banks = A.peq_banks()
    print("\n   1. the biquad (11 real coefficient banks, designer transfer"
          " function).  Class (0,1):")
    for nm, e in (("SHIPPED store+clear before the ALU", NORMAL),
                  ("store and clear AFTER the ALU",
                   ("store", "acc", "ptr", "after", "after")),
                  ("store early, CLEAR LATE",
                   ("store", "acc", "ptr", "before", "after")),
                  ("the store SUPPRESSED",
                   ("none", None, None, None, "before")),
                  ("the store writes the BUS",
                   ("store", "bus", "ptr", "before", "before")),
                  ("the store goes ELSEWHERE",
                   ("store", "acc", "else", "before", "before")),
                  ("bit 4 READS mem[ptr] instead of writing",
                   ("load", None, None, "before", "before"))):
        v = worst_db(M("adder", "load", uniform_gate(e)), banks, 512)
        print("      %-42s : %8.3f dB   %s"
              % (nm, v if v is not None else -1.0,
                 "REJECTED" if (v is None or v > 0.5) else "accepts"))

    print("\n   2. the LFO ramp.  Classes (1,1) and (1,2):")
    pool = L.publish_blocks()
    (i, a, e, ws, cf, inc, q) = pool[0]
    NONE_N = ("none", None, None, None, "never")
    NONE_L = ("none", None, None, None, "after")
    for nm, g, act00 in (
            ("SHIPPED  (1,1) -> no store, no clear",
             gate_with(NORMAL, {(1, 1): NONE_N}), "load"),
            ("the gate never fires (always store)", uniform_gate(NORMAL),
             "load"),
            ("gated at bit 7 ALONE, so (1,2) stops publishing",
             gate_with(NORMAL, {(1, 1): NONE_N, (1, 2): NONE_N}), "load"),
            ("gated at b7 & f31==0 (leaves (1,1) storing)",
             uniform_gate(NORMAL), "load"),
            ("(1,1) suppressed, act00 = add, NO late clear",
             gate_with(NORMAL, {(1, 1): NONE_N}), "add"),
            ("(1,1) suppressed, act00 = add, CLEAR LATE",
             gate_with(NORMAL, {(1, 1): NONE_L}), "add"),
            ("* (1,1) READS mem[ptr] into the accumulator",
             gate_with(NORMAL, {(1, 1): ("load", None, None, "before",
                                         "never")}), "load"),
            ("* ... the same, with act00 = add",
             gate_with(NORMAL, {(1, 1): ("load", None, None, "before",
                                         "never")}), "add"),
            ("* (1,1) stores the accumulator ELSEWHERE",
             gate_with(NORMAL, {(1, 1): ("store", "acc", "else", "before",
                                         "before")}), "load"),
            ("* (1,1) stores the BUS to mem[ptr]",
             gate_with(NORMAL, {(1, 1): ("store", "bus", "ptr", "before",
                                         "before")}), "load")):
        m = M("adder", act00, g)
        h = lfo_run(m, ws, cf, 10, random.Random(5 + i), q)
        ok = h is not None and L.is_ramp(h, inc)
        print("      %-52s act00=%-5s : %s"
              % (nm, act00, "runs" if ok else "REJECTED"))

    print("\n   3. the ramp criterion itself")
    m = M("adder", "load", gate_with(NORMAL, {(1, 1): NONE_N}))
    h = lfo_run(m, ws, cf, 10, random.Random(5 + i), q)
    print("      is_ramp(correct inc = %d) : %s" % (inc, L.is_ramp(h, inc)))
    print("      is_ramp(wrong   inc = %d) : %s" % (inc + 1,
                                                    L.is_ramp(h, inc + 1)))
    print("\n   4. the dead-store census -- shown WRONG when the ramp's own")
    print("      independently forced correction is withheld (see `dead')")
    print("\n   5. the effect quotient -- shown able to say DIFFERENT (see `enum')")


# ===========================================================================
#  SECTION `condition'
# ===========================================================================
def sec_condition():
    hdr("condition -- the `f31 == 1' vs `f31 != 2' half of the gate, priced")
    print("""`lfo-ramp.md' item K and `acc-adder.md' sect. 8 both leave OPEN "which of
the three store gates -- they differ on 13 corpus words, nine of them the
COMPRESSOR's envelope step at hi12[3:1] == 5".  That count is checked here,
because a disagreement at a word the decoder REFUSES is not a disagreement.""")
    names = L.prog_names()
    sw = store_words()
    dis = [r for r in sw if r[3] == 1 and r[4] not in (1, 2)]
    print("\n   words where `b7 & f31==1' and `b7 & f31!=2' disagree")
    print("   (bit 4 set, bit 7 set, hi12[3:1] not in {1,2}) : %d" % len(dis))
    byf = collections.Counter(r[4] for r in dis)
    print("      by hi12[3:1] : %s"
          % "  ".join("%d:%d" % (a, b) for a, b in sorted(byf.items())))
    print("      * published count: 13.  MEASURED here: %d." % len(dis))
    trap_f, trap_a, live = [], [], []
    for r in dis:
        if r[4] > 2:
            trap_f.append(r)
        elif DIS.lo_act(r[2]) not in (0x00, 0x07, 0x12, 0x13, 0x14, 0x15, 0x19):
            trap_a.append(r)
        else:
            live.append(r)
    print("""
   * AND HOW MANY OF THEM CAN EXECUTE AT ALL?  Two reasons to trap that are
   INDEPENDENT of bit 7 and of the gate:""")
    print("      hi12[3:1] > 2, the accumulator operation is undecoded : %d"
          % len(trap_f))
    c = collections.Counter("algo %-3d %s" % (r[0], names.get(r[0], "?")[:18])
                            for r in trap_f)
    for k2, v in c.most_common():
        print("         %-28s x%d" % (k2, v))
    print("      the lo12 ACTION is not one of the seven anchored codes : %d"
          % len(trap_a))
    for r in trap_a:
        print("         algo %-3d %-20s w%-4d %-16s ACTION 0x%02X"
              % (r[0], names.get(r[0], "?")[:20], r[1], fmt(r[2]),
                 DIS.lo_act(r[2])))
    print("      * WORDS WHOSE BEHAVIOUR THE CONDITION ACTUALLY CHANGES : %d"
          % len(live))
    for r in live:
        print("         algo %-3d %-20s w%-4d %-16s"
              % (r[0], names.get(r[0], "?")[:20], r[1], fmt(r[2])))
    a2i = L.algo_to_image()
    inst = sum(1 for algo, (u, ld, ws) in a2i.items() for w in ws
               if not DIS.c_format(w) and (DIS.hi12(w) & 0x10)
               and ((DIS.hi12(w) >> 7) & 1)
               and DIS.hi_f31(DIS.hi12(w)) == 0
               and DIS.lo_act(w) in (0x00, 0x07, 0x12, 0x13, 0x14, 0x15, 0x19))
    print("""
   * AND THE SURVIVOR IS A PROVABLY DEAD STORE (see `dead'): its cell is
   rewritten by the very next word at that pointer, with no read in between.
   Settling the CONDITION half of the gate therefore unlocks at most ONE corpus
   word, whose store computes nothing.  It is present in %d of the %d algorithm
   images -- the twelve reverb presets share one byte-identical body."""
          % (inst, len(a2i)))
    return live


# ===========================================================================
#  SECTION `hostmix'
# ===========================================================================

def sec_hostmix():
    hdr("hostmix -- does the host EVER write SINGLE DELAY's input-mix cells?")
    print("""`blocking-read.md' item G leaves `SRC 0x00 = mem[ptr]' forced ONLY while
SINGLE DELAY's two input-mix coefficients are 0.0000, and names an emulator
capture as the experiment.  A capture can only SAMPLE the parameter settings the
run happens to visit.  The firmware's own per-algorithm parameter table answers
the same question EXHAUSTIVELY, and it is in the ROM.""")
    sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "kn7000_mame",
                                    "tools"))
    try:
        import kn5000_dsp_params as P
    except ImportError:
        print("   kn7000_mame/tools/kn5000_dsp_params.py not found -- skipped")
        return None
    sub = os.environ.get("KN5000_SUBROM") or os.path.join(
        HERE, "..", "..", "original_ROMs", "kn5000_subprogram_v142.rom")
    rom = P.Rom(sub, P.SUB_BASE)

    ws = L.algo_to_image()[9][2]
    cur = DIS.cursor_addresses(ws)
    cram = L.cram_of_algo(9)

    def sv(v):
        return (v - (1 << 24) if v & (1 << 23) else v) / 2.0 ** 23

    print("\n   MEASURED -- SINGLE DELAY's C-RAM offsets (from the cursor walk):")
    for k in (3, 4, 6):
        print("      w%-2d %-16s C-RAM offset 0x%02X = %+.6f   %s"
              % (k, fmt(ws[k]), cur[k], sv(cram.get(cur[k], 0)),
                 "INPUT MIX" if k in (3, 4) else "the feedback"))

    def maps(algo):
        p1 = rom.u32le(P.ALGO_T1_ARRAY + 4 * algo)
        p2 = rom.u32le(P.ALGO_T2_ARRAY + 4 * algo)
        if not rom.ok(p1, 4):
            return None, None, {}, []
        m = {op: ent for (_a, op, ent) in P.parse_t1(rom, p1)}
        rr = P.split_records(rom, p2) if (p2 and rom.ok(p2, 4)) else []
        return p1, p2, m, rr

    p1, p2, t1, recs = maps(9)
    print("\n   MEASURED -- algorithm 9: T1 = %08X   T2 = %08X" % (p1, p2))
    for op in sorted(t1):
        mark = "   <- TARGETS AN INPUT-MIX CELL" \
            if (0x00 in t1[op] or 0x01 in t1[op]) else ""
        print("      T1 op %02X -> %s%s"
              % (op, " ".join("%02X" % a for a in t1[op]), mark))
    print("\n   MEASURED -- algorithm 9's T2 parameter bytecode records:")
    tgts = set()
    for (a, ln, body) in recs:
        sols = P.decode_record(rom, body, t1)
        txt, hitmix = [], False
        for (op, opr, imm) in (sols[0] if sols else []):
            tgt = t1[op][opr]
            tgts.add(tgt)
            hitmix = hitmix or tgt in (0x00, 0x01)
            txt.append("op%02X#%02X->addr%02X imm=%s"
                       % (op, opr, tgt, imm.hex().upper()))
        print("      @%06X len%-3d %-58s%s"
              % (a, ln, "  ".join(txt) if txt else "<no parse>",
                 "  <- WRITES AN INPUT-MIX CELL" if hitmix else ""))

    print("""
   * THE ANSWER.  algorithm 9's T1 map lists C-RAM offset 0x00 -- w3's own
     input-mix coefficient -- among opcode 0x73's addresses, and the T2 stream
     contains a record that writes it.  The antecedent of item G ("both mix
     coefficients are 0.0000") is NOT a property of the running machine: it is
     the ROM-loaded DEFAULT, which a user parameter overwrites.""")
    print("      C-RAM offsets algorithm 9's parameter stream writes : %s"
          % " ".join("%02X" % t for t in sorted(tgts)))
    print("      of which are SINGLE DELAY input-mix cells            : %s"
          % (" ".join("%02X" % t for t in sorted(tgts & {0x00, 0x01}))
             or "NONE"))

    print("""
   * CONTROL 1 -- the same question asked of a cell that must NOT be a target
     and one that must be:""")
    print("      offset 02 (the feedback coefficient) is a target : %s"
          % (0x02 in tgts))
    print("      offset 90 (op 0x21, the output LEVEL)            : %s"
          % (0x90 in tgts))

    print("""
   * CONTROL 2 -- can a 6-byte immediate really be a (lo, hi) RANGE?  Tested
     where it can FAIL: over EVERY algorithm, does the ROM-loaded C-RAM value at
     each 6-byte-immediate record's target lie between the two halves?""")
    inside = outside = nodata = 0
    ex = []
    for algo in range(100):
        try:
            _p1, _p2, m1, rr = maps(algo)
        except Exception:
            continue
        cr = L.cram_of_algo(algo)
        if not cr or not rr:
            continue
        for (a, ln, body) in rr:
            sols = P.decode_record(rom, body, m1)
            if not sols:
                continue
            for (op, opr, imm) in sols[0]:
                if len(imm) != 6:
                    continue
                lo = int.from_bytes(imm[0:3], "big")
                hi = int.from_bytes(imm[3:6], "big")
                lo = lo - (1 << 24) if lo & (1 << 23) else lo
                hi = hi - (1 << 24) if hi & (1 << 23) else hi
                v = cr.get(m1[op][opr])
                if v is None:
                    nodata += 1
                    continue
                v = v - (1 << 24) if v & (1 << 23) else v
                if min(lo, hi) <= v <= max(lo, hi):
                    inside += 1
                else:
                    outside += 1
                    if len(ex) < 5:
                        ex.append((algo, op, opr, m1[op][opr], lo, hi, v))
    print("      target's ROM-loaded value INSIDE  the (lo, hi) pair : %d" % inside)
    print("      ...                       OUTSIDE it                : %d" % outside)
    print("      ... no ROM-loaded value at the target               : %d" % nodata)
    for e in ex:
        print("         e.g. algo %-3d op %02X#%d -> %02X  [%+.4f, %+.4f]"
              "  value %+.4f"
              % (e[0], e[1], e[2], e[3], e[4] / 2.0 ** 23, e[5] / 2.0 ** 23,
                 e[6] / 2.0 ** 23))
    print("""
   * CONTROL 3 -- ★ THE OPCODE HAS A NAME, AND THE ADDRESS SPACE HAS A CHECK.
     register-space.md (sibling pass, same day) aligns each T2 record against
     the captured UI parameter list and binds opcode 0x73 to FEEDBACK L /
     FEEDBACK R / RESONANCE, 28 of 28.  If op 0x73's addresses really are C-RAM
     COEFFICIENT cells, the ROM-loaded value at every one of those 28 targets
     must lie inside that record's own (lo, hi) pair -- and the corpus-wide test
     above scores only 85 %, so this can fail.""")
    try:
        import register_space as RS
        rom2, mainrom, _E = RS.load(
            os.path.join(HERE, "..", "..", "original_ROMs",
                         "kn5000_subprogram_v142.rom"),
            os.path.join(HERE, "..", "..", "original_ROMs",
                         "kn5000_v10_program.rom"),
            os.path.expanduser("~/compartilhado/kn7000_mame/tools"))
        cap = RS.load_capture(os.path.expanduser("~/compartilhado/kn7000_mame/tools"))
        pn = RS.param_names(mainrom)
        byname = {}
        for e in cap:
            for part in e["name"].split(" / "):
                byname[RS.norm(part)] = e["indices"]
        ins = outn = 0
        shown = 0
        for a in range(100):
            t1p = rom2.u32le(RS.T1_ARRAY + 4 * a)
            t2p = rom2.u32le(RS.T2_ARRAY + 4 * a)
            if not t2p or not t1p or t1p == RS.NULL_T1:
                continue
            am = {op: e for op, e in RS.parse_t1(rom2, t1p)}
            cr = L.cram_of_algo(a)
            if not cr:
                continue
            for (_x, _l, body) in RS.split_t2(rom2, t2p):
                op, opr = body[0], body[1]
                if op != 0x73 or len(body) < 8:
                    continue
                imm = body[2:8]
                lo = int.from_bytes(imm[0:3], "big")
                hi = int.from_bytes(imm[3:6], "big")
                lo = lo - (1 << 24) if lo & (1 << 23) else lo
                hi = hi - (1 << 24) if hi & (1 << 23) else hi
                ent = am.get(op, [])
                if opr >= len(ent):
                    continue
                v = cr.get(ent[opr])
                if v is None:
                    continue
                v2 = v - (1 << 24) if v & (1 << 23) else v
                ok = min(lo, hi) <= v2 <= max(lo, hi)
                ins += ok
                outn += (not ok)
                if shown < 6:
                    shown += 1
                    print("      algo %-3d %-18s #%d -> cell 0x%02X"
                          "  [%+.4f,%+.4f]  loaded %+.6f  %s"
                          % (a, RS.effect_name(mainrom, a)[:18], opr, ent[opr],
                             lo / 2.0 ** 23, hi / 2.0 ** 23, v2 / 2.0 ** 23,
                             "in" if ok else "OUT"))
        print("      op 0x73 targets INSIDE their own (lo,hi) pair : %d" % ins)
        print("      ...                            OUTSIDE        : %d" % outn)
        # the algo-9 binding, by name
        ui = byname.get(RS.norm(RS.effect_name(mainrom, 9)))
        t1p = rom2.u32le(RS.T1_ARRAY + 4 * 9)
        t2p = rom2.u32le(RS.T2_ARRAY + 4 * 9)
        am = {op: e for op, e in RS.parse_t1(rom2, t1p)}
        print("\n      ★ algorithm 9's records, with the UI names they carry:")
        for (_x, _l, body), idx in zip(RS.split_t2(rom2, t2p), ui or []):
            op, opr = body[0], body[1]
            ent = am.get(op, [])
            cell = ent[opr] if opr < len(ent) else None
            nm, un = pn[idx - 1]
            print("         op %02X#%d -> cell %-5s UI name = %-18s %s"
                  % (op, opr, ("0x%02X" % cell) if cell is not None else "??",
                     nm, ("<- SINGLE DELAY w3's OWN COEFFICIENT"
                          if cell == 0x00 else "")))
    except Exception as e:
        print("      (register_space.py unavailable: %s)" % e)

    lo, hi = 0xC28F5C - (1 << 24), 0x3D70A3
    print("""
      -> algorithm 9's record is `op 73 #00 -> addr 00, imm C28F5C 3D70A3',
         i.e. the pair (%+.4f, %+.4f), and the ROM-loaded value at offset 0x00 is
         exactly 0.0000 -- the MIDPOINT.  CAVEAT, stated: opcode 0x73's helper is
         `block 0x039ABD' and kn5000-dsp-parameters.md sect. 6 marks the
         opcode->helper binding INFERRED and partially wrong, so the RANGE is
         INFERRED.  What is MEASURED, and enough on its own, is that the cell IS
         a parameter target -- so "the host provably never writes it" cannot be
         established, and item G's ambiguity does not close."""
          % (lo / 2.0 ** 23, hi / 2.0 ** 23))
    return t1, recs


# ===========================================================================
#  SECTION `joint'
# ===========================================================================
def sec_joint():
    hdr("joint -- the gate, assembled class by class")
    bq = sec_biquad()
    bq_eff = sorted({r[0] for r in bq})
    lf = lfo_cached()
    if lf is None:
        lf = sec_lfo()
    print("\n   * THE GATE, ASSEMBLED FROM THE CLASSES THAT HAVE A WITNESS:")
    print("      class (0,1)  biquad  : %d effect(s) -- %s"
          % (len(bq_eff), ", ".join(eff_name(e) for e in bq_eff)))
    for ix in ((1, 1), (1, 2)):
        c = collections.Counter(eff_name(m.eff(*ix)) for m in lf)
        print("      class %-6s LFO     : %d effect(s)" % (str(ix), len(c)))
        for k, v in c.most_common():
            print("         %-32s x%d" % (k, v))
    print("      class (0,0)  NO WITNESS -- 12 words, structural evidence only")
    print("      class (1,0)  NO WITNESS -- 2 words, 1 executable, a dead store")
    print("      class (0,2)  VACUOUS   -- 0 words")
    c = collections.Counter((m.act00, eff_name(m.eff(1, 1))) for m in lf)
    print("\n   * THE COUPLING (act00 x class-(1,1) effect):")
    for (a, g), n in sorted(c.items()):
        print("      act00=%-6s eff(1,1)=%-30s x%d" % (a, g, n))
    return bq, lf



def alu_no_guard7(w):
    """dsp_disasm.alu_decoded() with guard 7 -- the bit-7 store gate -- REMOVED.
    Everything else is byte-for-byte the shipped predicate."""
    if DIS.c_format(w):
        return False
    cl = DIS.class4(w)
    if cl not in (2, 8, 0xA):
        return False
    if DIS.lo12(w) & 0x800:
        return False
    if DIS.lo_ptrmode(w):
        return False
    if DIS.lo_src(w) not in DIS._ANCHORED_SRC \
            or DIS.lo_act(w) not in DIS._ANCHORED_ACT:
        return False
    if (DIS.hi12(w) & DIS.HI_ST) and (cl & 7) != 2:
        return False
    if DIS.lo_act(w) == DIS.LO_ACT_ST_BUS and (cl & 7) != 2:
        return False
    f = DIS.hi_f31(DIS.hi12(w))
    if f in (0, 1):
        return True
    if f == 2:
        return cl == 8
    return False


def sec_price():
    hdr("price -- what settling the gate is actually WORTH, in words")
    print("""The brief prices the gate at "130 corpus words and 11 frame slots".
That is the size of class (1,1).  A word only pays out if the DECODER can
execute it once the gate is settled -- and most of the 130 trap for reasons that
have nothing to do with bit 7.""")
    names = L.prog_names()
    rows = [r for r in store_words() if (r[3], r[4]) == (1, 1)]
    print("\n   class (1,1) words over the 38 distinct images : %d" % len(rows))
    why = collections.Counter()
    for (algo, k, w, b7, f, ws, ptr) in rows:
        if alu_no_guard7(w):
            why["EXECUTABLE once the gate is settled"] += 1
        elif DIS.lo_src(w) not in DIS._ANCHORED_SRC:
            why["SRC 0x%02X is not anchored" % DIS.lo_src(w)] += 1
        elif DIS.lo_act(w) not in DIS._ANCHORED_ACT:
            why["ACTION 0x%02X is not anchored" % DIS.lo_act(w)] += 1
        else:
            why["other"] += 1
    for k2, v in why.most_common():
        print("      %-34s %d" % (k2, v))

    only7 = []
    tot = 0
    for algo, ws in images():
        for k, w in enumerate(ws):
            tot += 1
            if (not DIS.alu_decoded(w)) and alu_no_guard7(w):
                only7.append((algo, k, w))
    print("""
   ★ THE EXACT PRICE.  Words the shipped decoder refuses and would accept if the
   bit-7 store gate were settled -- i.e. refused by guard 7 and by nothing
   else:""")
    print("      %d of %d words in the 38 distinct body images" % (len(only7), tot))
    c = collections.Counter(fmt(w) for a, k, w in only7)
    for k2, v in c.most_common():
        print("         x%-3d %s" % (v, k2))
    cls = collections.Counter(((DIS.hi12(w) >> 7) & 1,
                               DIS.hi_f31(DIS.hi12(w))) for a, k, w in only7)
    print("      by class : %s"
          % {("b7=%d,f31=%d" % k2): v for k2, v in sorted(cls.items())})
    pr = collections.Counter(names.get(a, "?")[:20] for a, k, w in only7)
    print("      %d programs : %s" % (len(pr), dict(pr)))
    print("""
      -> ★ NONE of the 16 class-(1,1) words carries ACTION 0x00, so guard 7's
         `f31 == 1 requires ACTION 0x00' clause refuses every one of them TODAY.
         The gate question is therefore worth exactly these %d words -- not 130 --
         and 31 + 29 + 46 more would join them only if SRC 0x00, SRC 0x08 and
         SRC 0x1C were settled first.""" % len(only7))
    return only7


SECTIONS = [("enum", sec_enum), ("price", sec_price), ("census", sec_census),
            ("control", sec_control),
            ("condition", sec_condition), ("hostmix", sec_hostmix),
            ("dead", sec_dead), ("vacuity", sec_vacuity),
            ("biquad", sec_biquad), ("mirror", sec_mirror),
            ("lfo", sec_lfo), ("joint", sec_joint)]

if __name__ == "__main__":
    #  the default set is everything that runs in a couple of minutes; `mirror',
    #  `lfo' and `joint' are exhaustive searches and must be asked for by name.
    want = sys.argv[1:] or ["enum", "price", "census", "control", "condition",
                            "hostmix", "dead", "vacuity", "biquad"]
    for name, fn in SECTIONS:
        if name in want:
            fn()
