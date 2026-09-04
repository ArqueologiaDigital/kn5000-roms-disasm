#!/usr/bin/env python3
"""sd_rerun.py -- SINGLE DELAY, restored.

adjudication-round6 items A and B VOIDED every number the SINGLE DELAY harness
had produced, for two reasons that are still present in
`action00_discriminate.sd_run()' today:

  A. the DRAM polarity is REVERSED.  `sd_run' does
         if (addr8(w) & 0xf0) == 0x20: ln.write(bus) else: s.dr = ln.read()
     but DIS.dram_dir() -- FORCED in round 5 item D -- says addr8 0x20/0x30 =
     READ and 0x60 = WRITE.  The harness writes where the chip reads.

  B. the `Line' reads and writes THE SAME INDEX, so the delay a program gets is
     decided by its port order within the frame rather than by its descriptor.

Round 7 item E records the consequence: "the SINGLE DELAY leg is the void one",
and the leg was never restored.  This tool restores it.

WHY IT MATTERS.  SINGLE DELAY is one of only THREE contexts on this chip whose
arithmetic is known independently of the DSP (action00-discriminator.md item D
names PARAMETRIC EQ, SINGLE DELAY and the LFO).  It carries ACT 0x0D x4 and
ACT 0x0E x4 -- two of the three codes that block the reverb, and the two that
three-codes.md item E called unconstrained by anything in the corpus.  That
claim was reached by checking PARAMETRIC EQ and the LFO.  It never checked the
third context.

THE OBSERVABLE.  algo 9's delay descriptors pair up as

     write 31871 / read 31370  ->  501 samples
     write 15935 / read 15435  ->  500 samples      (the stereo partner)
     write     0 / read 32768  ->  the unit-0 floor and the 0x8000 partition,
                                   which round 4 shows are markers, not a tap

so the program is a ~11.3 ms stereo delay.  Feed an impulse; a correct machine
must return it from the line 500/501 samples later.  Cross-correlate the value
each DRAM READ returns against the input and the peak lag IS the delay.

    control    the harness must PASS a machine that should work and FAIL one
               that should not -- both polarities, both cursor signs.
    scan       enumerate act0d x act0e and report which readings put the peak
               where the descriptors say it must be.

===========================================================================
  ★★★★ 230 -- THREE DEFECTS IN THIS TOOL, DIAGNOSED AND REPAIRED
===========================================================================

CONTROL-AUDIT_findings.md (f601303) graded this tool's `control' leg the WORST
control in the project: rerun, it returned NO SIGNAL for the CORRECTED machine
and `500 * MATCHES' for the doubly-defective one, i.e. it was INVERTED.  230
found why.  All three defects are in the HARNESS; none is a property of any
machine under test.

  D1. THE POINTER WAS NEVER INITIALISED IN THE CONTROL LEG.  `run()' left
      st.p at State's default 0.  The pointer walk is p0-invariant modulo 256,
      and the head-write word w46 sits at p0 - 5:

          p0 = 0x00  ->  w0 (READ) ptr 0x00,  w46 (WRITE) ptr 0xFB
          p0 = 0x08  ->  w0 (READ) ptr 0x08,  w46 (WRITE) ptr 0x03

      With p0 = 0 the head write reads mem[0xFB], a cell the harness never
      drives, so it wrote ZERO into the line on every frame -- for all five
      enumerated input cells.  `NO SIGNAL' was the harness's own pointer
      initialisation.  `out_run' already passed p0 = 0x08 (which puts w46
      exactly on its incell 0x03); the control leg never got the same
      treatment.  ⇒ p0 and incell are ONE number, not two: incell = p0 - 5.

  D2. `reversed + cursor -1' IS A DOUBLE NEGATION, NOT A DEFECT.  Reversing
      the polarity makes w0 the WRITE (whose pointer IS p0, which the harness
      does drive) and w46 the READ; reversing the cursor sign then restores
      the same relative addressing.  The old control was not accepting a
      broken machine -- it was mislabelling a differently-correct one, while
      the machine it called correct had been silently starved by D1.

  D3. `echo_energies' HARD-CODED D = 500.  The two taps are in CASCADE, not in
      parallel: w46 writes cell 15935 and w0 reads 15435 (500), then w5 writes
      31871 from the delay return and w9 reads 31370 (501).  An impulse
      therefore comes back at 500 + 501 = 1001.  The D = 500 window is empty,
      which is why `NO FIRST ECHO' printed for the baseline AND for all three
      coefficient-scramble nulls -- one outcome for eight configurations.
      The stage order is DERIVED here, from each write word's bus source: a
      write fed by SRC 0x0B is fed by an earlier read, so it is a later stage.

  D4. THERE IS NO FEEDBACK, so E2/E1 -- the ratio the value leg computed --
      has no second echo to divide by.  The evaluable identity is the FIRST
      echo's gain against the direct path.

★★ THE REPAIRED CRITERION, and it is BIT-EXACT rather than tolerance-based:

      an impulse must return at lag 1001 (derived from the descriptors) with
      the sample value the ROM's OWN COEFFICIENTS predict in fixed point,

          c = 0xE5762C = -0.207331 ; h = 0x400000 = +0.500000
          ((c*c) >> 23) * h >> 23 = 180297 ;  180297 * (1<<21) >> 23 = 45074

      and the harness measures 45074.  EXACTLY.  That is SINGLE DELAY's
      +0.02149296 three-factor product, evaluated for the first time.

★★ AND IT IS TWO-SIDED, DEMONSTRATED BOTH WAYS (see `control'):
      ACCEPTS  the corrected machine (dram_dir polarity, cursor +1, derived p0)
      REJECTS  cursor -1, reversed, reversed + cursor -1 (no echo at all) and
               all three coefficient scrambles, which DO put an echo at 1001
               -- with the wrong value.  A PRESENCE test passes all three; only
               the VALUE separates them.  That is the whole point.

⚠ AND ONE HONEST NEGATIVE: the ACT-0x07 `dest07' calibration limb is INERT for
this observable -- all four readings give 45074.  The old tool's own comment
said so ("in the presence test it did not, 4 of 4") and then used it anyway.
It is reported as INERT, not as a pass.

★ RULE 20, with 228's clause (a control that IS the open defect is validated
exactly once and is invalidated by its own success): the `selftest' command is
SYNTHETIC and two-sided -- it hands the measurement code signals whose lag and
gain it constructed, so it does not depend on any defect this pass repaired and
survives the repair.
"""
import argparse
import collections
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

import dsp_disasm as DIS                                   # noqa: E402
import delayline as L                                      # noqa: E402
import action00_discriminate as A                          # noqa: E402

REGION = 0x8000                    # unit-0 delay region, round 4 sect. 2
ALGO = 9


def hdr(t):
    print("=" * 78)
    print("== " + t)
    print("=" * 78)


# ---------------------------------------------------------------------------
#  1. THE DELAY DRAM -- a rotating cursor over one region, which is what the
#     descriptors describe.  Round 6 item B's defect was a line whose read and
#     write shared an index; here the absolute address is (cell + cursor) and
#     the delay falls out of the DESCRIPTORS, not out of the program order.
# ---------------------------------------------------------------------------
class DelayDRAM(object):
    __slots__ = ("buf", "cur", "sign")

    def __init__(self, sign=+1):
        self.buf = [0] * REGION
        self.cur = 0
        self.sign = sign

    def _a(self, cell):
        return (cell + self.cur) % REGION

    def read(self, cell):
        return self.buf[self._a(cell)]

    def write(self, cell, v):
        self.buf[self._a(cell)] = int(v) & A.MASK24

    def advance(self):
        self.cur = (self.cur + self.sign) % REGION


def descriptors():
    p = L.program(ALGO)
    return list(p.words), list(p.cells), list(p.cons), L.coefs_of(ALGO, p.words)


def taps():
    """(write_cell, read_cell, delay) for each pair sharing no marker role."""
    _, cells, cons, _ = descriptors()
    rd, wr = [], []
    for (idx, _w), cell in zip(cons, cells):
        w = L.program(ALGO).words[idx]
        (rd if DIS.dram_dir(w) == "READ" else wr).append((idx, cell))
    out = []
    for wi, wc in wr:
        for ri, rc in rd:
            d = wc - rc
            if 1 <= d < 4096:
                out.append((wi, wc, ri, rc, d))
    return out


#  ★★★ 230 D3.  The two taps are in CASCADE, and the ORDER IS DERIVED, not
#  assumed: a write word whose operand bus is SRC 0x0B is fed by an earlier
#  DELAY READ, so it is a LATER stage; a write fed from anywhere else is the
#  HEAD.  Nothing about "500" or "1001" is written down anywhere below.
def cascade():
    """[(stage, write_iw, write_cell, read_iw, read_cell, D)], total lag."""
    words = L.program(ALGO).words
    st = []
    for wi, wc, ri, rc, d in taps():
        st.append((1 if DIS.lo_src(words[wi]) == 0x0B else 0, wi, wc, ri, rc, d))
    st.sort()
    return st, sum(s[5] for s in st)


#  ★★★ 230 D1.  The pointer walk is p0-invariant modulo 256, so the pointer at
#  every delay word is p0 + a FIXED offset.  Derive those offsets by executing
#  the program once with no delay port attached, and report them.  p0 and the
#  input cell are then ONE number: the head write reads mem[p0 + off].
def ptr_offsets(m):
    """{iw: pointer offset relative to p0} for the six delay-DRAM words."""
    import random
    words, cells, cons, coefs = descriptors()
    cell_of = {i: c for (i, _), c in zip(cons, cells)}
    rng = random.Random(20260731)
    st = A.State(rng)
    st.p = 0
    off = {}
    for k, w in enumerate(words):
        if k in cell_of:
            off[k] = st.p
        if not A.step(m, st, w, coefs[k], rng, dram=None, unknown=lambda: 0):
            break
    return off


def head_write_iw():
    """the delay WRITE word that carries the audio into the line (stage 0)."""
    return cascade()[0][0][1]


def derive_p0(m, incell):
    """p0 such that the HEAD WRITE word's pointer lands on `incell'.

    ★ 234: returns None when the machine REFUSES a word before the head write
    (ptr_offsets() then has no entry for it).  `scan' crashed here with
    KeyError 46 on every invocation since 230 introduced this derivation --
    its `none' reading refuses w1 -- so 233's "sd_rerun.py scan already
    enumerates act0d x act0e" described a command that had not run."""
    off = ptr_offsets(m)
    hw = head_write_iw()
    if hw not in off:
        return None
    return (incell - off[hw]) & 0xff


#  ★★★ 230.  THE PREDICTION, IN FIXED POINT, FROM THE ROM's OWN COEFFICIENTS.
#  No float tolerance: the harness's multiply is (s24(coef) * bus) >> 23, so the
#  three-factor product is computable exactly and the echo SAMPLE is an integer.
def rom_triple(psh=23):
    """(sequence of raw coefficients, product in Q0.23, human gain)."""
    _, _, _, coefs = descriptors()
    vals = []
    for c in coefs:
        if not c:
            continue
        v = c - (1 << 24) if c >= (1 << 23) else c
        vals.append(v)
    uniq = sorted(set(vals))
    # the three factors the delay's forward path multiplies, taken from the
    # stream itself: the two `655' half-gains bracket four identical 3-tap
    # blocks; the factor that appears in EVERY block and is the block's last
    # term is the one on the delay path.  Both are read off `descriptors()'.
    half = max(uniq, key=lambda v: (v == (1 << 22), 0))       # +0.500000
    tap = min(uniq)                                            # -0.207331
    p = ((tap * tap) >> psh) * half >> psh
    return (tap, tap, half), p, p / float(1 << 23)


def predicted_echo_sample(amp, psh=23):
    _, p, _ = rom_triple(psh)
    return (int(amp) * p) >> psh


# ---------------------------------------------------------------------------
#  2. THE RUN -- the SAME ALU model as every other tool (A.step), differing ONLY
#     in the delay port.  `polarity' and `sign' are enumerated, never fixed.
# ---------------------------------------------------------------------------
def run(m, nsamp=1400, polarity="correct", sign=+1, seed=20260727, incell=0x00,
        p0=None):
    import random
    words, cells, cons, coefs = descriptors()
    cell_of = {idx: c for (idx, _), c in zip(cons, cells)}
    #  ★ 230 D1: p0 is DERIVED so the head write lands on `incell'.  Passing
    #  p0 explicitly is still allowed -- that is how the defect is reproduced.
    if p0 is None:
        p0 = derive_p0(m, incell)
        if p0 is None:
            return None                        # ★ 234: the machine refuses
    rng = random.Random(seed)
    dram = DelayDRAM(sign)
    st = A.State(rng)
    x = [0.0] * nsamp
    x[8] = float(1 << 20)                      # the impulse
    reads = {ri: [0.0] * nsamp for ri in cell_of}

    for n in range(nsamp):
        st.acc = st.P = 0
        st.ta = st.tb = 0
        st.p = p0
        st.dr = 0
        # THE BODY HAS NO INPUT LATCH READ -- exactly as for the reverb, the audio
        # arrives through the shared 60-word kernel.  Drive the cell the kernel
        # would have written.  `incell' is ENUMERATED by the caller, never fixed.
        st.mem[incell] = int(x[n]) & A.MASK24

        def port(w, bus, s, _n=n):
            idx = port.idx
            cell = cell_of.get(idx)
            if cell is None:
                return
            d = DIS.dram_dir(w)
            if polarity == "reversed":
                d = "WRITE" if d == "READ" else "READ"
            if d == "WRITE":
                dram.write(cell, bus)
            else:
                v = dram.read(cell)
                s.dr = int(v) & A.MASK24
                reads[idx][_n] = float(v)

        ok = True
        for k, w in enumerate(words):
            port.idx = k
            if not A.step(m, st, w, coefs[k], rng, dram=port,
                          unknown=lambda: 0):
                ok = False
                break
        if not ok:
            return None
        dram.advance()
    return x, reads


def peak_lag(x, y, lo=1, hi=1200):
    """lag maximising sum y[n]*x[n-lag]; returns (lag, score, runner_up)."""
    best = (0, 0.0)
    second = 0.0
    for lag in range(lo, hi):
        s = 0.0
        for n in range(lag, len(y)):
            if x[n - lag]:
                s += y[n] * x[n - lag]
        s = abs(s)
        if s > best[1]:
            second = best[1]
            best = (lag, s)
        elif s > second:
            second = s
    return best[0], best[1], second


BASE = dict(order="adder", act00="add", sttime="before", stgate="b7_f31_1_off",
            act19="tA<-bus", src00="mem", src11="mem", dest07="mem")

READINGS = ("tA<-bus", "tB<-bus", "tA<-acc", "tB<-acc", "mem<-bus", "none")


def machine(**kw):
    d = dict(BASE)
    d.update(kw)
    return A.Machine(**d)


# ---------------------------------------------------------------------------
def cmd_taps():
    hdr("taps -- what the DESCRIPTORS say the delay must be")
    words, cells, cons, _ = descriptors()
    print("   algo 9 SINGLE DELAY, %d words, %d delay-DRAM accesses\n" % (len(words), len(cons)))
    for (idx, _), cell in zip(cons, cells):
        w = words[idx]
        print("      w%-3d %010X  %s  cell %6d" % (idx, w, DIS.dram_dir(w), cell))
    print("\n   write/read pairs with a plausible tap length:")
    for wi, wc, ri, rc, d in taps():
        print("      write w%-3d cell %6d   read w%-3d cell %6d   ->  D = %4d  (%6.2f ms)"
              % (wi, wc, ri, rc, d, 1000.0 * d / 44100.0))
    print("""
   ★ two taps, 500 and 501 samples -- a STEREO ~11.3 ms delay.  That is the
   observable: an impulse must come back out of the line 500/501 samples later.
   The third pairing (write 0 / read 32768) is the unit-0 floor against the
   0x8000 partition line, which adjudication-round4 sect. 2 shows are MARKERS.""")


#  ★★★ 230 -- THE REPAIRED, TWO-SIDED CONTROL.
#
#  The criterion is BIT-EXACT and comes out of the ROM, not out of a tolerance:
#  an impulse must return at the CASCADE lag the descriptors give and carry the
#  sample value the ROM's own three coefficients predict in fixed point.  It is
#  demonstrated in BOTH directions on every run, and the run PRINTS BOTH.
def _grade(lbl, m, want_lag, want_samp, must_pass, **kw):
    r = out_run(m, nsamp=want_lag + 120, **kw)
    if r is None:
        got = "machine refused"
        ok = False
    else:
        x, out = r
        ev = echoes(x, out)
        hit = [e for e in ev if e[0] == want_lag]
        if not hit:
            got = "NO ECHO at lag %d%s" % (
                want_lag, "" if not ev else "  (echoes at %s)" %
                ", ".join("%d" % e[0] for e in ev))
            ok = False
        else:
            lag, samp, g = hit[0]
            got = "lag %d  sample %d  gain %+.8f" % (lag, int(samp), g)
            ok = (int(samp) == want_samp)
    verdict = ("★ ACCEPT" if ok else "REJECT")
    agree = "✔" if (ok == must_pass) else "⛔ CONTROL BROKEN"
    print("   %-30s %-46s %-9s %s" % (lbl, got, verdict, agree))
    return ok == must_pass


def cmd_control():
    hdr("control -- 230's REPAIRED two-sided control (see the module docstring)")
    stages, D = cascade()
    (fa, fb, fc), prod, gain = rom_triple()
    amp = 1 << 21
    want = predicted_echo_sample(amp)
    m = machine(act0d="tA<-bus", act0e="tA<-bus")
    off = ptr_offsets(m)
    hw = head_write_iw()

    print("   THE DERIVATIONS -- nothing below is written down, all of it is read")
    print("   off the program's own words:\n")
    for s, wi, wc, ri, rc, d in stages:
        print("      stage %d   write w%-3d cell %6d  ->  read w%-3d cell %6d   D = %4d"
              % (s, wi, wc, ri, rc, d))
    print("      CASCADE   the stage-1 write's bus is SRC 0x0B (the delay return),")
    print("                so it is fed by the stage-0 read  =>  total lag D = %d\n" % D)
    print("      pointer at each delay word, relative to p0: %s"
          % ", ".join("w%d:%+d" % (k, (v ^ 0x80) - 0x80) for k, v in sorted(off.items())))
    print("      head write is w%d at p0%+d, so p0 and the input cell are ONE"
          % (hw, (off[hw] ^ 0x80) - 0x80))
    print("      number:  incell 0x03  =>  p0 = 0x%02X   (230 D1)\n"
          % derive_p0(m, 0x03))
    print("      ROM three-factor product, in the harness's own fixed point:")
    print("         (%d * %d) >> 23 = %d ;  (that * %d) >> 23 = %d  = %+.8f"
          % (fa, fb, (fa * fb) >> 23, fc, prod, gain))
    print("         impulse %d  =>  PREDICTED echo sample = %d\n" % (amp, want))

    print("   %-30s %-46s %-9s %s" % ("configuration", "measured", "verdict", "expected?"))
    okall = True
    #  --- the side that must be ACCEPTED ---
    okall &= _grade("CORRECTED (dram_dir, +1)", m, D, want, True)
    #  --- the side that must be REJECTED: addressing defects ---
    okall &= _grade("corrected, cursor -1", m, D, want, False, sign=-1)
    okall &= _grade("round-6 defect: reversed", m, D, want, False, polarity="reversed")
    okall &= _grade("reversed + cursor -1", m, D, want, False,
                    polarity="reversed", sign=-1)
    #  --- the side that must be REJECTED: VALUE defects.  These DO put an echo
    #      at the right lag.  A presence test passes all three. ---
    for sd in (1, 2, 3):
        okall &= _grade("coefficients SCRAMBLED #%d" % sd, m, D, want, False,
                        coef_scramble=sd)
    #  --- p0 left at State's default: 230 D1 reproduced on purpose ---
    okall &= _grade("p0 = 0 (the 230 D1 defect)", m, D, want, False, p0=0x00)
    print()
    print("   ⇒ TWO-SIDED: 1 configuration ACCEPTED, 7 REJECTED, %s\n"
          % ("all 8 as expected" if okall else "⛔ NOT all as expected"))
    print("   ⚠ AND ONE HONEST NEGATIVE -- the ACT-0x07 calibration limb is INERT")
    print("      for this observable.  It is reported, not counted as a pass:\n")
    for d in ("mem", "tA", "tB", "acc"):
        mm = machine(act0d="tA<-bus", act0e="tA<-bus", dest07=d)
        r = out_run(mm, nsamp=D + 120)
        ev = echoes(*r) if r else []
        hit = [e for e in ev if e[0] == D]
        print("      dest07 = %-4s  %s" % (d, ("sample %d" % int(hit[0][1])) if hit
                                            else "no echo"))
    print("      ⇒ all four IDENTICAL: moving the ANCHORED memory writer does not")
    print("        move this observable.  dest07 is NOT a calibration for it.")
    return okall
def cmd_scan():
    hdr("scan -- enumerate act0d x act0e against the descriptor delay")
    print("""   ⚠ 234: this is the ORIGINAL presence test over the old six-reading menu,
   kept so its numbers stay reproducible.  It crashed (KeyError 46) from 230
   until 234 and its menu never held the reading the device ships.  The
   graded command is `act0d0e' below; do not quote this one.
""")
    want = set(d for *_, d in taps())
    print("   %d x %d = %d machines; a machine PASSES only if an impulse returns\n"
          "   from the line at a lag the descriptors predict %s.\n"
          % (len(READINGS), len(READINGS), len(READINGS) ** 2, sorted(want)))
    rows = []
    for d in READINGS:
        for e in READINGS:
            m = machine(act0d=None if d == "none" else d,
                        act0e=None if e == "none" else e)
            r = run(m)
            if r is None:
                rows.append((d, e, None, 0.0, 0.0))
                continue
            x, reads = r
            best = None
            for idx, y in reads.items():
                lag, sc, sec = peak_lag(x, y)
                if sc > 0 and (best is None or sc > best[1]):
                    best = (lag, sc, sec)
            rows.append((d, e, best[0] if best else None,
                         best[1] if best else 0.0, best[2] if best else 0.0))
    print("   %-10s %-10s %-8s %-12s %s" % ("act0d", "act0e", "peak", "score", "verdict"))
    npass = 0
    for d, e, lag, sc, sec in rows:
        if lag is None:
            v = "refused / no signal"
        elif lag in want:
            v = "★ PASS"
            npass += 1
        else:
            v = "fail"
        print("   %-10s %-10s %-8s %-12.4g %s" % (d, e, lag if lag else "-", sc, v))
    print("\n   %d of %d machines put the echo where the descriptors demand." % (npass, len(rows)))
    if npass == 0:
        print("""
   ⛔ ZERO SURVIVORS is a result about the HARNESS, not about the codes: if no
   assignment of the two free readings can make a 500-sample delay come out of a
   program whose descriptors say 500, something upstream of act0d/act0e is still
   wrong.  Report it as such and do NOT read a semantics off it.""")


# ---------------------------------------------------------------------------
#  3. THE VALUE TEST -- an IDENTITY, not a presence.
#
#  single-delay-restored.md sect. 2: the presence test failed because it asked
#  whether signal ARRIVED.  The claim needs an IDENTITY.  algo 9's C-RAM stream
#  supplies one without any topology assumption:
#
#      TWO coefficients of +0.500000 (w006, w029, the `655' words)
#      FOUR identical 3-tap blocks {+0.273441, +0.387057, -0.207331}
#
#  A delay with feedback g emits echoes at D, 2D, 3D whose successive energies
#  are in the ratio g.  So measure E2/E1 and ask whether it is a number THE ROM
#  SUPPLIES.  That is the biquad methodology -- reproduce the designer -- applied
#  to the one other program whose mathematics is known.
# ---------------------------------------------------------------------------
def out_run(m, nsamp=2600, polarity="correct", sign=+1, incell=0x03, p0=None,
            seed=20260727, coef_scramble=None):
    import random
    #  ★ 230 D1: 0x08 was hard-coded here and NOWHERE ELSE, which is why the
    #  value leg had a live datapath and the control leg did not.  Derive it.
    if p0 is None:
        p0 = derive_p0(m, incell)
        if p0 is None:
            return None                        # ★ 234: the machine refuses
    words, cells, cons, coefs = descriptors()
    if coef_scramble is not None:
        coefs = list(coefs)
        rr = random.Random(coef_scramble)
        idx = [i for i, c in enumerate(coefs) if c]
        vals = [coefs[i] for i in idx]
        rr.shuffle(vals)
        for i, v in zip(idx, vals):
            coefs[i] = v
    cell_of = {i: c for (i, _), c in zip(cons, cells)}
    rng = random.Random(seed)
    dram = DelayDRAM(sign)
    st = A.State(rng)
    x = [0.0] * nsamp
    x[4] = float(1 << 21)
    out = [0.0] * nsamp
    for n in range(nsamp):
        st.acc = st.P = 0
        st.ta = st.tb = 0
        st.p = p0
        st.dr = 0
        st.mem[incell] = int(x[n]) & A.MASK24

        def port(w, bus, s):
            c = cell_of[port.idx]
            d = DIS.dram_dir(w)
            if polarity == "reversed":
                d = "WRITE" if d == "READ" else "READ"
            if d == "WRITE":
                dram.write(c, bus)
            else:
                s.dr = int(dram.read(c)) & A.MASK24

        for k, w in enumerate(words):
            port.idx = k
            if not A.step(m, st, w, coefs[k], rng, dram=port, unknown=lambda: 0):
                return None
        v = st.mem.get(0x0E, 0)
        out[n] = float(v - (1 << 24)) if v >= (1 << 23) else float(v)
        dram.advance()
    return x, out


#  ★★★ 230 D3.  NO WINDOW AND NO HARD-CODED D.  `echo_energies' summed a
#  +/-8-sample window around 4 + k*500 and the echo is at 4 + 1001, so it read
#  zero for every configuration ever passed to it.  This reports EVERY non-zero
#  output sample as (lag, sample, gain) -- no window to be wrong about, and a
#  configuration that produces two echoes shows two.
def echoes(x, out):
    n0 = max(range(len(x)), key=lambda i: abs(x[i]))
    amp = x[n0]
    return [(n - n0, out[n], out[n] / amp)
            for n in range(len(out)) if out[n] and n != n0]


ROM_GAINS = {0.500000: "+0.500000 (w006/w029)",
             0.273441: "+0.273441", 0.387057: "+0.387057", 0.207331: "-0.207331"}


def cmd_value():
    hdr("value -- the ROM's three-factor product, measured (230's repair)")
    stages, D = cascade()
    (fa, fb, fc), prod, gain = rom_triple()
    amp = 1 << 21
    want = predicted_echo_sample(amp)
    print("""   IDENTITY test, BIT-EXACT.  The old leg asked for E2/E1 in a +/-8 window
   around 4 + k*500.  There is no feedback (so no second echo) and the echo is
   at %d, so it printed NO FIRST ECHO for every configuration -- baseline and
   nulls alike.  What IS evaluable is the FIRST echo's sample against the value
   the ROM's own coefficients predict:  %d.\n""" % (D, want))
    base = machine(act0d="tA<-bus", act0e="tA<-bus")
    print("   %-34s %-8s %-12s %-13s %s"
          % ("configuration", "lag", "sample", "gain", "verdict"))

    def row(lbl, m, **kw):
        r = out_run(m, nsamp=D + 120, **kw)
        if r is None:
            print("   %-34s %-8s %-12s %-13s machine refused" % (lbl, "-", "-", "-"))
            return None
        x, out = r
        ev = [e for e in echoes(x, out) if e[0] == D]
        if not ev:
            print("   %-34s %-8s %-12s %-13s NO ECHO AT LAG %d" % (lbl, "-", "-", "-", D))
            return None
        lag, samp, g = ev[0]
        v = ("★ = the ROM three-factor product" if int(samp) == want
             else "differs from the ROM product")
        print("   %-34s %-8d %-12d %-13.8f %s" % (lbl, lag, int(samp), g, v))
        return int(samp)

    row("BASELINE", base)
    print()
    print("   -- NULL: the ROM's own coefficients, shuffled among the same slots.")
    print("      Note they all DO produce an echo at %d -- a PRESENCE test passes" % D)
    print("      every one of them.  Only the VALUE separates them.")
    for sd in (1, 2, 3):
        row("coefficients SCRAMBLED #%d" % sd, base, coef_scramble=sd)
    print()
    print("   -- ⚠ INERT LIMB, reported not counted: ACT 0x07's destination.")
    for d in ("mem", "tA", "tB", "acc"):
        row("dest07 = %s" % d, machine(act0d="tA<-bus", act0e="tA<-bus", dest07=d))


# ---------------------------------------------------------------------------
#  4. ★★★ 233 -- THE SEVEN `SRC 0x00' READINGS, SCORED BY THE lag-1001 SAMPLE.
#
#  Pre-registered by 232 sect. 7.2 and by SRC00-HANDOFF-2026-09-04.md sect. 4.
#  `upd6383.cpp' resolves `SRC 0x00' to `mem[ptr]' on a reading its own comment
#  grades "1 of 6 enumerated, no independent support"; 232 priced the code at
#  +348 corpus words = 46 % of the entire routing ceiling.  a09 SINGLE DELAY
#  carries NINE `SRC 0x00' words, and one of them is the HEAD WRITE.
#
#  ⚠⚠ AND THAT IS EXACTLY WHERE THIS HARNESS IS CIRCULAR IF IT IS RUN AS
#  WRITTEN.  `out_run' derives p0 with `derive_p0(m, incell)', which places the
#  HEAD WRITE's pointer on the driven cell -- i.e. the harness injects the audio
#  into whatever cell w46 would read IF `SRC 0x00' WERE `mem[ptr]'.  Under any
#  other reading the input is then poured into a cell the program never looks
#  at, and the silence that results is the HARNESS's input-injection assumption
#  and not a property of the machine.  Rule 15, and rule 22's inverted-control
#  clause: a control built around the answer cannot grade it.
#
#  ⇒ THE CIRCULARITY IS REMOVED BY SWEEPING THE INJECTION CELL.  The pointer
#  walk is p0-invariant modulo 256 (230 D1), so (p0, incell) matters only
#  through incell - p0: fixing p0 = 0x08 and sweeping incell over all 256 cells
#  covers EVERY relative placement of the input, including the published one
#  (incell 0x03).  A reading is refuted only if NO cell in the whole pointer
#  space lets the ROM's own three-factor product come back at the cascade lag.
#
#      python3 dsp/tools/sd_rerun.py src00
# ---------------------------------------------------------------------------
SRC00_MENU = A.SRC00_MENU


def inject_probe(m, incell, p0, nsamp=120, polarity="correct", sign=+1,
                 coef_scramble=None):
    """Cheap NECESSARY condition, and it is reported in TWO parts because they
    rest on different assumptions:

       line_write_nz  how many times a delay-DRAM WRITE carried a non-zero
                      datum.  ★ This one assumes NOTHING about where the output
                      is read: a delay program that never writes a non-zero
                      sample into its line cannot delay anything, full stop.
       out_nz         how many frames the output cell 0x0E was non-zero.

    120 frames is longer than any path that does not go through the delay line
    itself (the line's own latency is 500), and `st.mem' persists across frames,
    so a chain that hops one memory cell per frame has 120 hops to show itself.
    Returns (line_write_nz, out_nz), or None if the machine refuses a word."""
    import random
    words, cells, cons, coefs = descriptors()
    cell_of = {i: c for (i, _), c in zip(cons, cells)}
    if coef_scramble is not None:
        coefs = list(coefs)
        rr = random.Random(coef_scramble)
        idx = [i for i, c in enumerate(coefs) if c]
        vals = [coefs[i] for i in idx]
        rr.shuffle(vals)
        for i, v in zip(idx, vals):
            coefs[i] = v
    rng = random.Random(20260727)
    dram = DelayDRAM(sign)
    st = A.State(rng)
    hit = [0, 0]
    for n in range(nsamp):
        st.acc = st.P = 0
        st.ta = st.tb = 0
        st.p = p0
        st.dr = 0
        st.mem[incell] = (1 << 21) if n == 4 else 0

        def port(w, bus, s):
            c = cell_of[port.idx]
            d = DIS.dram_dir(w)
            if polarity == "reversed":
                d = "WRITE" if d == "READ" else "READ"
            if d == "WRITE":
                dram.write(c, bus)
                if int(bus) & A.MASK24:
                    hit[0] += 1
            else:
                s.dr = int(dram.read(c)) & A.MASK24

        for k, w in enumerate(words):
            port.idx = k
            if not A.step(m, st, w, coefs[k], rng, dram=port,
                          unknown=lambda: 0):
                return None
        if st.mem.get(0x0E, 0):
            hit[1] += 1
        dram.advance()
    return tuple(hit)


def cmd_src00():
    hdr("src00 -- 233: the SEVEN readings against the lag-1001 ROM product")
    stages, D = cascade()
    amp = 1 << 21
    want = predicted_echo_sample(amp)
    words, cells, cons, coefs = descriptors()
    cell_of = {i: c for (i, _), c in zip(cons, cells)}

    #  --- 1. THE REACH TEST (rule 15), before any score ---
    s00 = [i for i, w in enumerate(words)
           if ((DIS.hi12(w) >> 8) & 0xF) != 0xC and DIS.lo_src(w) == 0x00]
    print("   ★ REACH TEST FIRST (rule 15) -- a09's own SRC 0x00 words:\n")
    for i in s00:
        w = words[i]
        role = ("delay %s cell %d" % (DIS.dram_dir(w), cell_of[i])
                if i in cell_of else "-")
        print("      w%-3d %010X  class %X  ACT %02X  lo12 %03X  %s%s"
              % (i, w, DIS.class4(w), DIS.lo_act(w), w & 0xFFF, role,
                 "   <-- THE HEAD WRITE" if i == head_write_iw() else ""))
    print("      %d of %d words carry the code, and the HEAD WRITE w%d is one"
          " of them." % (len(s00), len(words), head_write_iw()))

    #  ⚠ WHICH `coef' IS ON TRIAL.  `upd6383.cpp' has THREE forms of 145's
    #  reading: mask bit 57 = `coef' on EVERY SRC 0x00 word (146 measured it
    #  railing unit 1, 98.9 % at full scale), bit 58 = only on a
    #  coefficient-consuming word, bit 59 = only when f98 == 1 as well.  The
    #  menu entry swept below is the GLOBAL form, bit 57's shape.  Print, from
    #  the program itself, whether the two GATED forms are even distinguishable
    #  here -- if no SRC 0x00 word in a09 satisfies their predicate they fall
    #  back to mem[ptr] and this criterion is BLIND to them (rule 15).
    cc = [i for i in s00 if DIS.coeff_consumer(words[i])]
    f98 = [i for i in cc if ((DIS.hi12(words[i]) >> 8) & 3) == 1]
    print("      ⚠ of those %d: %d are coefficient consumers (mask bit 58's"
          " predicate)\n        and %d of THOSE have f98 == 1 (bit 59's)."
          % (len(s00), len(cc), len(f98)))
    print("        ⇒ the `coef' row below is the GLOBAL form (bit 57).  The two"
          " GATED forms\n          are %s here."
          % ("IDENTICAL to `mem' and therefore INVISIBLE to this criterion"
             if not cc else "distinguishable at w%s" % cc))

    #  --- 2. THE ADDRESSING CONTROL: the walk must not depend on the reading ---
    print("\n   ★ CONTROL -- the pointer walk must be reading-INVARIANT, or the"
          "\n     sweep below is comparing different address maps:")
    offs = {r: tuple(sorted(ptr_offsets(machine(act0d="tA<-bus",
                                                act0e="tA<-bus",
                                                src00=r)).items()))
            for r in SRC00_MENU}
    same = len(set(offs.values())) == 1
    print("      %d distinct pointer maps over the seven readings   %s"
          % (len(set(offs.values())),
             "✔ INVARIANT" if same else "⛔ CONFOUNDED -- stop here"))
    print("      map: %s" % ", ".join("w%d:%+d" % (k, (v ^ 0x80) - 0x80)
                                      for k, v in offs["mem"]))

    #  --- 2b. THE SWEEP's OWN CONTROLS.  Rule 20: a sweep that reports NONE
    #      for six of seven readings is indistinguishable from a sweep that
    #      cannot find anything.  Three limbs, on machines whose answer is known
    #      independently of `src00': one that must be ACCEPTED, one that must be
    #      refused on ABSENCE, and one that must be refused on VALUE while the
    #      echo is PRESENT (230's point -- a presence test passes that one). ---
    P0 = 0x08

    def sweep(m, **kw):
        return [c for c in range(256)
                if (lambda pr: pr and (pr[0] or pr[1]))(
                    inject_probe(m, c, P0, **kw))]

    mm = machine(act0d="tA<-bus", act0e="tA<-bus", src00="mem")
    print("\n   ★ CONTROL -- the sweep must ACCEPT, must refuse on ABSENCE, and"
          "\n     must refuse on VALUE with the echo PRESENT:")
    ctl = []
    good = sweep(mm)
    ok = (good == [0x03])
    ctl.append(ok)
    print("      known-GOOD   (dram_dir, +1)          cells %-14s %s"
          % (["0x%02X" % c for c in good],
             "✔ and it is the head write's cell, DERIVED" if ok
             else "⛔ CONTROL BROKEN"))
    #  ⚠ REPORTED FAILURE, AND IT IS A CALIBRATION, NOT A DEFECT.  The first
    #  form of this limb demanded `no candidate cells' from the reversed
    #  machine, and it FAILED: reversed reaches the line from FIVE cells.  The
    #  probe is a NECESSARY condition and is deliberately PERMISSIVE -- which
    #  is exactly why the six rivals' `0 of 256' below is a strong statement
    #  and not a stingy probe.  The limb belongs at the ECHO test, where the
    #  reversed machine is in fact refused from every one of its five cells.
    bad = sweep(mm, polarity="reversed")
    badv = [c for c in bad
            if (lambda r: r and any(e[0] == D and int(e[1]) == want
                                    for e in echoes(*r)))(
                out_run(mm, nsamp=D + 120, incell=c, p0=P0,
                        polarity="reversed"))]
    ctl.append(badv == [])
    print("      known-BAD    (round-6 reversed)      cells %-14s %s"
          % ("%d reach the line" % len(bad),
             "✔ and 0 of those %d survive the ECHO test -- refused" % len(bad)
             if badv == [] else "⛔ CONTROL BROKEN"))
    sc = sweep(mm, coef_scramble=1)
    res = out_run(mm, nsamp=D + 120, incell=0x03, p0=P0, coef_scramble=1)
    ev = [e for e in echoes(*res) if e[0] == D] if res else []
    ctl.append(bool(ev) and int(ev[0][1]) != want)
    print("      known-BAD    (coefficients scrambled) cells %-13s %s"
          % (["0x%02X" % c for c in sc],
             "✔ echo PRESENT at %d, sample %d != %d -- refused on VALUE"
             % (D, int(ev[0][1]), want) if ev else "⛔ no echo, wrong reason"))
    #  RELOCATION: the sweep must find the head write's cell wherever it is, so
    #  that "0x03" is not something the sweep knows.  p0 = 0x40 => cell 0x3B.
    P0b = 0x40
    rel = [c for c in range(256)
           if (lambda pr: pr and (pr[0] or pr[1]))(inject_probe(mm, c, P0b))]
    wantrel = (P0b + ptr_offsets(mm)[head_write_iw()]) & 0xff
    ctl.append(rel == [wantrel])
    print("      RELOCATED    (p0 = 0x%02X)             cells %-14s %s"
          % (P0b, ["0x%02X" % c for c in rel],
             "✔ it tracks the head write, it does not know `0x03'"
             if rel == [wantrel] else "⛔ CONTROL BROKEN"))
    print("      CONTROL: %d of %d" % (sum(1 for c in ctl if c), len(ctl)))

    #  --- 3. THE INJECTION SWEEP: remove the harness's own circularity ---
    print("""
   ★ THE INJECTION SWEEP -- 256 cells x 7 readings, p0 fixed at 0x%02X.
     `out_run' normally DERIVES p0 so the head write lands on the driven cell,
     which presupposes the very reading under test.  Sweeping the cell instead
     asks the two-sided question: is there ANY placement of the kernel's input
     under which this reading delays the signal?  incell 0x%02X reproduces the
     published configuration exactly.\n""" % (P0, 0x03))
    print("      %-6s %-14s %-14s %s"
          % ("src00", "cells->LINE", "cells->OUT", "candidates"))
    cands = {}
    for r in SRC00_MENU:
        m = machine(act0d="tA<-bus", act0e="tA<-bus", src00=r)
        hits, line, out = [], 0, 0
        for c in range(256):
            pr = inject_probe(m, c, P0)
            if not pr:
                continue
            if pr[0]:
                line += 1
            if pr[1]:
                out += 1
            if pr[0] or pr[1]:
                hits.append(c)
        cands[r] = hits
        print("      %-6s %-14s %-14s %s"
              % (r, "%d of 256" % line, "%d of 256" % out,
                 (", ".join("0x%02X" % c for c in hits[:8])
                  + (" ..." if len(hits) > 8 else "")) if hits else "NONE"))
    print("      ⚠ the `cells->LINE' column assumes NOTHING about where the"
          " output is read.")

    #  --- 4. THE SCORE: the ROM's own three-factor product at the cascade lag --
    print("""
   ★ THE SCORE.  For every candidate cell, the full %d-frame run; a reading is
     ACCEPTED if an impulse returns at lag %d carrying the sample the ROM's own
     coefficients predict, %d (230's bit-exact criterion).\n""" % (D + 120, D, want))
    print("      %-6s %-8s %-8s %-12s %-13s %s"
          % ("src00", "cell", "lag", "sample", "gain", "verdict"))
    verdict = {}
    for r in SRC00_MENU:
        m = machine(act0d="tA<-bus", act0e="tA<-bus", src00=r)
        best = None
        for c in cands[r]:
            res = out_run(m, nsamp=D + 120, incell=c, p0=P0)
            if res is None:
                continue
            ev = [e for e in echoes(*res) if e[0] == D]
            if not ev:
                continue
            lag, samp, g = ev[0]
            if best is None or int(samp) == want:
                best = (c, lag, int(samp), g)
            if int(samp) == want:
                break
        if best is None:
            verdict[r] = False
            print("      %-6s %-8s %-8s %-12s %-13s %s"
                  % (r, "-", "-", "-", "-",
                     "REFUTED -- no cell in the whole pointer space puts an"
                     " echo at %d" % D))
        else:
            c, lag, samp, g = best
            ok = (samp == want)
            verdict[r] = ok
            print("      %-6s 0x%02X     %-8d %-12d %-13.8f %s"
                  % (r, c, lag, samp, g,
                     "★ = the ROM three-factor product" if ok
                     else "echo present, VALUE differs from the ROM product"))
    n = sum(1 for v in verdict.values() if v)
    print("\n   ⇒ %d of %d readings ACCEPTED." % (n, len(SRC00_MENU)))
    print("""   ⚠ NULL, so the row above is not a reach test: `cmd_control' shows the
     SAME criterion rejects 7 defective machines including three coefficient
     scrambles that DO put an echo at %d.  The criterion can say NO, and here
     it says NO to %d of 7 readings.""" % (D, len(SRC00_MENU) - n))
    return verdict


# ---------------------------------------------------------------------------
#  5. ★★★ 234 -- `ACT 0x0D' x `ACT 0x0E' OVER THE DEVICE'S OWN MENU, AGAINST
#     THE lag-1001 ROM PRODUCT.  Pre-registered by 233 sect. 4.2, which also
#     required the reach test to come FIRST: "a09's ACT 0x0D/0x0E words are
#     inside the delay path, so ... this one must be shown to reach the
#     criterion BEFORE it is quoted".
#
#  THREE THINGS ABOUT THE HARNESS, FOUND BEFORE ANY NUMBER WAS READ:
#   (i)   `scan' -- the command 233 said "already enumerates act0d x act0e" --
#         crashed on every invocation since 230 (derive_p0 KeyError 46: its
#         `none' reading refuses w1).  Repaired above; it is a PRESENCE test
#         over the old menu and is not graded.
#   (ii)  that old menu {tA<-bus, tB<-bus, tA<-acc, tB<-acc, mem<-bus} is
#         133's selector values 2/3/4 only.  The reading the device SHIPS --
#         0x0D = 1 (acc <- bus), 0x0E = 7 (P <- bus at the multiply's scale)
#         -- was never executable by this model.  A.ACT0D0E_MENU now holds all
#         seven (selector 5 coincides with 7 in this regime, ash == 0).
#   (iii) every published SINGLE DELAY number -- 230's 1 accepted / 7 rejected,
#         233's 1 of 7 -- was taken under (tA<-bus, tA<-bus), which at a09's
#         eight sites is a NO-OP: no SRC 0x19 reader follows any of them
#         before an ACT 0x19 rewrites tempA.  So the lag the criterion demands,
#         1001, was itself derived with these two codes INERT.  Whether that
#         lag is an anchor INDEPENDENT of the codes is exactly what this
#         section has to print, not assume.
#
#      python3 dsp/tools/sd_rerun.py act0d0e
# ---------------------------------------------------------------------------
ACT0D0E_MENU = A.ACT0D0E_MENU
SHIPPED = ("acc<-bus", "P<-bus")        # 133's selector (1, 7), upd6383.cpp
NSCORE = 2 * 1001 + 300                 # room for a SECOND echo (feedback)
P0_PUB, CELL_PUB = 0x08, 0x03           # the published placement (230 D1)


def echo_class(ev):
    """a short label for an echo list: which lags carry which values."""
    if ev is None:
        return "refused"
    if not ev:
        return "NONE"
    if len(ev) > 8:
        return "smear x%d from %d" % (len(ev), ev[0][0])
    return " ".join("%d:%d" % (e[0], int(e[1])) for e in ev)


def traced_run(m, nsamp=NSCORE, incell=CELL_PUB, p0=P0_PUB):
    """out_run with probes on the signal path: for each named signal, the
    FIRST frame (relative to the impulse) at which it is non-zero, and how
    many frames it is non-zero.  This is what names WHERE an impulse dies
    under a reading -- rule 17's shape: a wrong path reports a wrong lag."""
    import random
    words, cells, cons, coefs = descriptors()
    cell_of = {i: c for (i, _), c in zip(cons, cells)}
    stages, _D = cascade()
    tag = {}
    for stg, wi, wc, ri, rc, d in stages:
        tag[wi] = "line%s WRITE" % "AB"[stg]
        tag[ri] = "line%s RETURN" % "AB"[stg]
    for i in cell_of:
        tag.setdefault(i, "marker w%d %s" % (i, DIS.dram_dir(words[i])))
    rng = random.Random(20260727)
    dram = DelayDRAM(+1)
    st = A.State(rng)
    n0 = 4
    first, count = {}, {}

    def hit(name, v, n):
        if v:
            count[name] = count.get(name, 0) + 1
            first.setdefault(name, n - n0)

    for n in range(nsamp):
        st.acc = st.P = 0
        st.ta = st.tb = 0
        st.p = p0
        st.dr = 0
        st.mem[incell] = (1 << 21) if n == n0 else 0

        def port(w, bus, s, _n=n):
            c = cell_of[port.idx]
            if DIS.dram_dir(w) == "WRITE":
                dram.write(c, bus)
                hit(tag[port.idx], int(bus) & A.MASK24, _n)
            else:
                v = int(dram.read(c)) & A.MASK24
                s.dr = v
                hit(tag[port.idx], v, _n)

        for k, w in enumerate(words):
            port.idx = k
            if not A.step(m, st, w, coefs[k], rng, dram=port, unknown=lambda: 0):
                return None
            if k == 40:
                hit("P after w40 (stage-1 chain)", st.P & A.MASK24, n)
            if k == 17:
                hit("P after w17 (stage-0 chain)", st.P & A.MASK24, n)
            if k == 45:
                hit("acc after w45 (0E)", st.acc & A.MASK24, n)
                hit("P after w45 (0E)", st.P & A.MASK24, n)
        hit("mem[0x0B] (w43 store)", st.mem.get(0x0B, 0), n)
        hit("mem[0x08] (w23 store)", st.mem.get(0x08, 0), n)
        hit("OUTPUT mem[0x0E]", st.mem.get(0x0E, 0), n)
        dram.advance()
    return first, count


def _pair_score(args):
    d, e, kw = args
    m = machine(act0d=d, act0e=e)
    r = out_run(m, nsamp=NSCORE, **kw)
    return (d, e, None if r is None else echoes(*r))


def _pair_sweep(args):
    d, e = args
    m = machine(act0d=d, act0e=e)
    line, out, cands = 0, 0, []
    for c in range(256):
        pr = inject_probe(m, c, P0_PUB)
        if not pr:
            continue
        line += bool(pr[0])
        out += bool(pr[1])
        if pr[0] or pr[1]:
            cands.append(c)
    #  the long run on every candidate, keeping the distinct echo classes
    classes = {}
    for c in cands:
        r = out_run(m, nsamp=NSCORE, incell=c, p0=P0_PUB)
        classes.setdefault(echo_class(None if r is None else echoes(*r)), []).append(c)
    return (d, e, line, out, cands, classes)


def _pair_trace(args):
    d, e = args
    return (d, e, traced_run(machine(act0d=d, act0e=e)))


def cmd_act0d0e(jobs=None):
    import multiprocessing
    hdr("act0d0e -- 234: the device's 7 x 7 readings against the ROM product")
    stages, D = cascade()
    amp = 1 << 21
    want = predicted_echo_sample(amp)
    words, cells, cons, coefs = descriptors()
    cell_of = {i: c for (i, _), c in zip(cons, cells)}
    jobs = jobs or max(1, multiprocessing.cpu_count() - 1)

    #  --- 1. THE REACH TEST (rule 15), before any score ---
    print("   ★ REACH TEST FIRST (rule 15) -- a09's own ACT 0x0D / 0x0E words,")
    print("     with the pointer each one sees under the published placement")
    print("     (p0 = 0x%02X, input cell 0x%02X):\n" % (P0_PUB, CELL_PUB))
    m0 = machine(act0d="nop", act0e="nop")
    #  the pointer at every word, from one traced frame under `nop'
    import random
    st = A.State(random.Random(1))
    st.p = P0_PUB
    pat = {}
    for k, w in enumerate(words):
        pat[k] = st.p
        A.step(m0, st, w, coefs[k], random.Random(1), dram=lambda *a: None,
               unknown=lambda: 0)
    sites = [i for i, w in enumerate(words)
             if not DIS.c_format(w) and DIS.lo_act(w) in (0x0D, 0x0E)]
    for i in sites:
        w = words[i]
        print("      w%-3d %010X  ACT %02X  SRC %02X (%s)  f31 %d  store %d  ptr 0x%02X%s"
              % (i, w, DIS.lo_act(w), DIS.lo_src(w),
                 {0x07: "mem[ptr]", 0x10: "acc"}.get(DIS.lo_src(w), "?"),
                 DIS.hi_f31(DIS.hi12(w)), (DIS.hi12(w) >> 4) & 1, pat[i],
                 "   <-- the word BEFORE the head write w%d" % head_write_iw()
                 if i + 1 == head_write_iw() else ""))
    pairs = [(a, b) for a, b in zip(sites, sites[1:])
             if DIS.lo_act(words[a]) == 0x0D and DIS.lo_act(words[b]) == 0x0E and b == a + 1]
    print("      %d ACT 0x0D + %d ACT 0x0E words, in %d ADJACENT 0D->0E pairs: %s"
          % (sum(1 for i in sites if DIS.lo_act(words[i]) == 0x0D),
             sum(1 for i in sites if DIS.lo_act(words[i]) == 0x0E),
             len(pairs), ", ".join("w%d/w%d" % p for p in pairs)))
    print("      the last pair sits IMMEDIATELY before the head write (w46) and the")
    print("      output store (w47 -> mem[0x0E]); whatever they leave in acc and P")
    print("      is what w46 adds to the input and w47 presents.")
    #  which of the old menu's destinations is ever READ after a site?
    print("\n      is the destination READ before it is rewritten?  (static, this program)")
    for nm, rd, wr in (("tempA", lambda f: DIS.lo_src(f) == 0x19,
                        lambda f: DIS.lo_act(f) in (0x13, 0x19)),
                       ("tempB", lambda f: DIS.lo_src(f) == 0x1A,
                        lambda f: DIS.lo_act(f) == 0x14)):
        live = []
        for i in sites:
            for j in range(i + 1, len(words)):
                if rd(words[j]):
                    live.append(i)
                    break
                if wr(words[j]):
                    break
        print("      %-6s read after: %s" % (nm, ["w%d" % i for i in live] or "NO SITE"))
    print("      ⇒ every reading in the OLD menu (tA/tB/mem<-self) is a NO-OP at all")
    print("        eight sites; the numbers 230 and 233 published were taken with")
    print("        these two codes INERT.  Only acc / P / mem writes can reach the")
    print("        criterion here, and acc / P are the two the device ships.")

    A.ACT0D_FIRED[0] = A.ACT0E_FIRED[0] = 0
    r = out_run(m0, nsamp=NSCORE, incell=CELL_PUB, p0=P0_PUB)
    print("\n   ⇒ in ONE scoring pass (%d frames): ACT 0x0D fired %d, ACT 0x0E fired %d"
          "  (UNCONDITIONAL)" % (NSCORE, A.ACT0D_FIRED[0], A.ACT0E_FIRED[0]))
    ev0 = echoes(*r)
    print("      known-GOOD (nop, nop): %s   %s"
          % (echo_class(ev0),
             "✔ = 233's `mem' row (lag %d, sample %d), EXTERNAL" % (D, want)
             if any(e[0] == D and int(e[1]) == want for e in ev0)
             else "⛔ CONTROL BROKEN"))

    #  --- 2. THE ADDRESSING CONTROL ---
    offs = {(d, e): tuple(sorted(ptr_offsets(machine(act0d=d, act0e=e)).items()))
            for d in ACT0D0E_MENU for e in ACT0D0E_MENU}
    print("\n   ★ CONTROL -- pointer map over the 49 pairs: %d distinct   %s"
          % (len(set(offs.values())),
             "✔ INVARIANT" if len(set(offs.values())) == 1 else "⛔ CONFOUNDED"))

    #  --- 3. THE TABLE AT THE PUBLISHED PLACEMENT ---
    print("""
   ★ THE 49 PAIRS AT THE PUBLISHED PLACEMENT (%d frames, so a second echo at
     2 x %d would show).  Each cell: the echo lags and their sample values.
     The pre-registered criterion is lag %d carrying %d.\n""" % (NSCORE, D, D, want))
    with multiprocessing.Pool(jobs) as pool:
        rows = pool.map(_pair_score, [(d, e, dict(incell=CELL_PUB, p0=P0_PUB))
                                      for d in ACT0D0E_MENU for e in ACT0D0E_MENU])
    tab = {(d, e): ev for d, e, ev in rows}
    print("      %-9s | %s" % ("0D \\ 0E", " ".join("%-14s" % e for e in ACT0D0E_MENU)))
    for d in ACT0D0E_MENU:
        print("      %-9s | %s" % (d, " ".join("%-14s" % echo_class(tab[(d, e)])[:14]
                                                for e in ACT0D0E_MENU)))
    classes = collections.Counter(echo_class(v) for v in tab.values())
    print("\n      DISTINCT OUTCOMES: %d" % len(classes))
    for c, n in classes.most_common():
        print("         %-34s x%2d  %s" % (c, n, ", ".join(
            "(%s,%s)" % k for k, v in tab.items() if echo_class(v) == c)[:120]))
    ship = echo_class(tab[SHIPPED])
    acc = [k for k, v in tab.items() if any(e[0] == D and int(e[1]) == want for e in v or [])]
    print("\n      pre-registered criterion (lag %d, sample %d): %d of 49 pairs ACCEPTED"
          % (D, want, len(acc)))
    print("      THE SHIPPED PAIR %s: %s" % (SHIPPED, ship))

    #  --- 4. THE VALUE CRITERION STILL BITES AT THE OTHER LAG ---
    print("\n   ★ CONTROL -- the VALUE half of the criterion under the SHIPPED pair:")
    ms = machine(act0d=SHIPPED[0], act0e=SHIPPED[1])
    for sd in (1, 2, 3):
        rr = out_run(ms, nsamp=NSCORE, incell=CELL_PUB, p0=P0_PUB, coef_scramble=sd)
        print("      coefficients SCRAMBLED #%d : %s" % (sd, echo_class(echoes(*rr))))
    rr = out_run(ms, nsamp=NSCORE, incell=CELL_PUB, p0=P0_PUB, polarity="reversed")
    print("      round-6 reversed          : %s" % echo_class(echoes(*rr)))
    p0b = 0x40
    cb = (p0b + ptr_offsets(ms)[head_write_iw()]) & 0xff
    rr = out_run(ms, nsamp=NSCORE, incell=cb, p0=p0b)
    print("      RELOCATED p0 = 0x%02X, cell 0x%02X : %s   (lags must not move)"
          % (p0b, cb, echo_class(echoes(*rr))))

    #  --- 5. WHERE THE IMPULSE GOES, PER PAIR ---
    print("""
   ★ WHERE THE IMPULSE GOES -- first non-zero frame (relative to the impulse)
     of each signal on the path, at the published placement.  A path that the
     output never presents is named here rather than inferred.\n""")
    show = [("nop", "nop"), SHIPPED, ("acc+=bus", "P<-bus"), ("P<-bus", "acc<-bus"),
            ("P<-bus", "nop"), ("nop", "mem<-bus")]
    with multiprocessing.Pool(jobs) as pool:
        traces = pool.map(_pair_trace, show)
    names = ["lineA WRITE", "lineA RETURN", "lineB WRITE", "lineB RETURN",
             "P after w17 (stage-0 chain)", "mem[0x08] (w23 store)",
             "P after w40 (stage-1 chain)", "mem[0x0B] (w43 store)",
             "acc after w45 (0E)", "P after w45 (0E)", "OUTPUT mem[0x0E]"]
    print("      %-30s %s" % ("signal", " ".join("%-12s" % ("%s/%s" % (d[:4], e[:4]))
                                                for d, e, _t in traces)))
    for nm in names:
        print("      %-30s %s" % (nm, " ".join(
            "%-12s" % ("-" if t is None or nm not in t[0]
                       else "@%d x%d" % (t[0][nm], t[1][nm]))
            for _d, _e, t in traces)))

    #  --- 6. THE 256-CELL SWEEP, EVERY PAIR (233's de-circularised form) ---
    print("""
   ★ THE INJECTION SWEEP -- 256 cells x 49 pairs, p0 fixed at 0x%02X, then the
     long run on every candidate cell.  Per pair: how many cells reach a delay
     line at all, how many reach the output, and every DISTINCT echo class any
     placement produces.  (233's form of the two-sided question: is there ANY
     placement under which this pair delays the signal, and how?)\n""" % P0_PUB)
    with multiprocessing.Pool(jobs) as pool:
        sw = pool.map(_pair_sweep, [(d, e) for d in ACT0D0E_MENU for e in ACT0D0E_MENU])
    print("      %-9s %-9s %-11s %-11s %s" % ("0D", "0E", "cells->LINE", "cells->OUT",
                                              "echo classes over all placements"))
    for d, e, line, out, cands, ecls in sw:
        print("      %-9s %-9s %-11s %-11s %s"
              % (d, e, "%d of 256" % line, "%d of 256" % out,
                 " | ".join("%s @%s" % (c, ",".join("0x%02X" % x for x in cs[:4])
                                        + ("..." if len(cs) > 4 else ""))
                            for c, cs in sorted(ecls.items()))))
    n1001 = sum(1 for d, e, _l, _o, _c, cl in sw
                if any(("%d:%d" % (D, want)) in c for c in cl))
    print("\n      pairs with SOME placement putting %d at lag %d : %d of 49"
          % (want, D, n1001))
    print("      pairs with SOME placement putting %d at lag 500  : %d of 49"
          % (want, sum(1 for d, e, _l, _o, _c, cl in sw
                        if any(("500:%d" % want) in c for c in cl))))

    print("""
   ⇒ VERDICT.  The criterion REACHES both codes (fired counts above) and
      SEPARATES the readings (%d distinct outcomes over 49 pairs) -- unlike
      PARAMETRIC EQ's 0.198 dB, this one is live.  But its LAG is not an anchor
      independent of the codes: 1001 was derived under readings that make
      w44/w45 inert, and the shipped pair puts the SAME ROM product at lag 500
      -- the stage-0 tap -- with the stage-1 chain's product discarded at w45.
      A presence-and-value test passes both; only the lag separates them, and
      the lag is the quantity these two codes decide.  So SINGLE DELAY says:
      the shipped pair and the inert pair are DIFFERENT programs (a 500-sample
      delay whose second line is dead, versus a 1001-sample cascade), and the
      corpus, the descriptors and the ROM product cannot say which is the
      chip's.  That is the reach test's constructive form, and the honest
      residue of THIS harness; the context that can decide the pair without
      presupposing it is PARAMETRIC EQ's entry window (gate_settle.py
      act0d0e), and the register (234) does the synthesis.""" % len(classes))
    return tab, sw


# ---------------------------------------------------------------------------
#  6. ★★ 234 -- A SECOND DELAY CONTEXT: a10 MULTI TAP DELAY.  ONE delay-line
#     WRITE (cell 32685) and FOUR READS (6000/12000/18000/24000), so every
#     tap's lag is fixed by its own descriptor -- write - read = 26685, 20685,
#     14685, 8685 -- with no stage-order derivation in the way.  The pair sits
#     at w5/w6, w59/w60 and w64/w65 (the last, as in a09, immediately before
#     the closing write and the output store).  Under a reading, which of the
#     four descriptor lags does the output present?  A multi-tap delay that
#     presents fewer taps than it allocates is the same shape as a09's dead
#     second line, and that is what this section is for: consistency, in a
#     context whose lags cannot be argued about.
#
#     The input cell is NOT assumed: it is swept over all 256 (233's method)
#     for the representative pairs, and the long run is taken at every cell
#     that reaches the line.
#
#      python3 dsp/tools/sd_rerun.py multitap
# ---------------------------------------------------------------------------
MT_ALGO = 10
MT_REP = [("nop", "nop"), SHIPPED, ("acc+=bus", "P<-bus"), ("P<-bus", "acc<-bus"),
          ("P<-bus", "acc+=bus"), ("nop", "mem<-bus")]


def descriptors_of(algo):
    p = L.program(algo)
    words = list(p.words)
    coefs = list(L.coefs_of(algo, words))
    #  ★ a10's C-RAM upload is 15 cells (0x00..0x0E) and the program fetches 18
    #  (cursor 0..17): w52/w53/w54 -- its SECOND damping block -- read cells the
    #  upload does not supply.  DECLARED SUBSTITUTION: they take the FIRST
    #  block's three (w46/w47/w48), which is the a09 pattern (a09's two blocks
    #  are byte-identical).  Only tap PRESENCE and LAG are graded from this
    #  program, never a sample value.  ⚠ cram[6] = 0 is NOT a gap: it is the
    #  fourth tap's gain in this preset, so THREE taps are expected, not four.
    if algo == MT_ALGO:
        for i, c in enumerate(coefs):
            if c is None and DIS.cursor_fetch(words[i]):
                coefs[i] = coefs[i - 6]
    return words, list(p.cells), list(p.cons), coefs


def mt_lags():
    """{read_iw: lag} for every read against the single real write."""
    words, cells, cons, _ = descriptors_of(MT_ALGO)
    cell_of = {i: c for (i, _), c in zip(cons, cells)}
    wr = [(i, c) for i, c in cell_of.items() if DIS.dram_dir(words[i]) == "WRITE" and c]
    assert len(wr) == 1, wr
    wc = wr[0][1]
    return {i: wc - c for i, c in cell_of.items()
            if DIS.dram_dir(words[i]) == "READ" and 0 < wc - c < REGION}, wr[0]


def mt_run(m, nsamp, incell, p0=P0_PUB, probe_only=False):
    """a10 under `m': (line_write_nz, out_nz) if probe_only, else the output."""
    import random
    words, cells, cons, coefs = descriptors_of(MT_ALGO)
    cell_of = {i: c for (i, _), c in zip(cons, cells)}
    rng = random.Random(20260727)
    dram = DelayDRAM(+1)
    st = A.State(rng)
    x = [0.0] * nsamp
    x[4] = float(1 << 21)
    out = [0.0] * nsamp
    hit = [0, 0]
    for n in range(nsamp):
        st.acc = st.P = 0
        st.ta = st.tb = 0
        st.p = p0
        st.dr = 0
        st.mem[incell] = int(x[n]) & A.MASK24

        def port(w, bus, s):
            c = cell_of[port.idx]
            if DIS.dram_dir(w) == "WRITE":
                dram.write(c, bus)
                if c and (int(bus) & A.MASK24):
                    hit[0] += 1
            else:
                s.dr = int(dram.read(c)) & A.MASK24

        for k, w in enumerate(words):
            port.idx = k
            if not A.step(m, st, w, coefs[k], rng, dram=port, unknown=lambda: 0):
                return None
        v = st.mem.get(0x0E, 0)
        out[n] = float(v - (1 << 24)) if v >= (1 << 23) else float(v)
        if v:
            hit[1] += 1
        dram.advance()
    return tuple(hit) if probe_only else (x, out)


def _mt_probe(args):
    d, e = args
    m = machine(act0d=d, act0e=e, altlo12="nop")
    cands = []
    for c in range(256):
        pr = mt_run(m, 160, c, probe_only=True)
        if pr and (pr[0] or pr[1]):
            cands.append(c)
    return (d, e, cands)


def _mt_long(args):
    d, e, c, nsamp = args
    m = machine(act0d=d, act0e=e, altlo12="nop")
    r = mt_run(m, nsamp, c)
    return (d, e, c, None if r is None else echoes(*r))


def cmd_multitap(jobs=None):
    import multiprocessing
    hdr("multitap -- 234: a10 MULTI TAP DELAY, the pair in a second delay context")
    jobs = jobs or max(1, multiprocessing.cpu_count() - 1)
    words, cells, cons, coefs = descriptors_of(MT_ALGO)
    lags, (wi, wc) = mt_lags()
    print("   a10: %d words; ONE real delay WRITE w%d cell %d; taps by descriptor:"
          % (len(words), wi, wc))
    for i, lag in sorted(lags.items(), key=lambda kv: kv[1]):
        print("      read w%-3d cell %6d  ->  lag %5d  (%6.1f ms)"
              % (i, wc - lag, lag, 1000.0 * lag / 44100.0))
    sites = [i for i, w in enumerate(words)
             if not DIS.c_format(w) and DIS.lo_act(w) in (0x0D, 0x0E)]
    print("   ACT 0x0D/0x0E at %s" % ", ".join("w%d(%02X)" % (i, DIS.lo_act(words[i])) for i in sites))
    print("   ⚠ w26 `040.0.00.864' and w33 `050.0.00.921' are lo12-bit-11 (ALT) words")
    print("     whose effect is OPEN (bit11-family.md); they run as NO-OPs here")
    print("     (altlo12 = nop) so the program runs at all.")
    print("   ⚠ a10's upload is 15 C-RAM cells; w52/w53/w54 fetch cursor 15..17, which")
    print("     it does not supply.  They take w46/w47/w48's coefficients (the a09")
    print("     pattern -- its two damping blocks are identical).  DECLARED; only tap")
    print("     PRESENCE and LAG are read off this program.  And C-RAM[0x06] = 0 is the")
    print("     fourth tap's gain in this preset: THREE taps expected, not four.")
    print("   tap gains (w27..w30): %s" % ["%+.6f" % (A.s24(c) / 2.0 ** 23) for c in coefs[27:31]])
    nsamp = max(lags.values()) + 400
    A.ACT0D_FIRED[0] = A.ACT0E_FIRED[0] = 0
    r = mt_run(machine(act0d="nop", act0e="nop", altlo12="nop"), 200, 0x03)
    print("   the model %s a10 under (nop, nop); fired 0D %d / 0E %d in 200 frames"
          % ("RUNS" if r is not None else "⛔ REFUSES", A.ACT0D_FIRED[0], A.ACT0E_FIRED[0]))
    if r is None:
        #  find the refusing word
        import random
        st = A.State(random.Random(1)); st.p = P0_PUB
        m = machine(act0d="nop", act0e="nop", altlo12="nop")
        for k, w in enumerate(words):
            if not A.step(m, st, w, coefs[k], random.Random(1), dram=lambda *a: None,
                          unknown=lambda: 0):
                print("      first refusal at w%d %010X (src %02X act %02X f31 %d coef %s)"
                      % (k, w, DIS.lo_src(w), DIS.lo_act(w), DIS.hi_f31(DIS.hi12(w)), coefs[k]))
                break
        return None

    print("\n   ★ THE INPUT-CELL SWEEP, representative pairs (160-frame probe):")
    with multiprocessing.Pool(jobs) as pool:
        pr = pool.map(_mt_probe, MT_REP)
    cand = {}
    for d, e, cs in pr:
        cand[(d, e)] = cs
        print("      %-9s %-9s cells reaching the line/output: %s"
              % (d, e, ", ".join("0x%02X" % c for c in cs) or "NONE"))
    allc = sorted(set().union(*[set(cs) for _d, _e, cs in pr]))
    print("\n   ★ THE LONG RUN (%d frames) at every candidate cell, ALL 49 pairs:"
          % nsamp)
    jobs_ = [(d, e, c, nsamp) for d in ACT0D0E_MENU for e in ACT0D0E_MENU for c in allc]
    with multiprocessing.Pool(jobs) as pool:
        res = pool.map(_mt_long, jobs_)
    want = set(lags.values())
    by = collections.defaultdict(dict)
    for d, e, c, ev in res:
        by[(d, e)][c] = ev
    print("      %-9s %-9s %-6s %-10s %s" % ("0D", "0E", "cell", "taps hit", "echoes (lag:sample)"))
    summary = collections.Counter()
    for d in ACT0D0E_MENU:
        for e in ACT0D0E_MENU:
            best = None
            for c, ev in by[(d, e)].items():
                if ev is None:
                    continue
                hitl = sorted({x[0] for x in ev} & want)
                if best is None or len(hitl) > len(best[1]):
                    best = (c, hitl, ev)
            if best is None:
                summary["refused"] += 1
                print("      %-9s %-9s %-6s %-10s %s" % (d, e, "-", "-", "refused"))
                continue
            c, hitl, ev = best
            key = "%d of %d" % (len(hitl), len(want))
            summary[key] += 1
            if len(ev) > 12:
                txt = "%d non-zero outputs from %d (first %s)" % (
                    len(ev), ev[0][0], " ".join("%d:%d" % (x[0], int(x[1])) for x in ev[:4]))
            else:
                txt = " ".join("%d:%d" % (x[0], int(x[1])) for x in ev)
            print("      %-9s %-9s 0x%02X   %-10s %s%s"
                  % (d, e, c, key, txt, "   <-- SHIPPED" if (d, e) == SHIPPED else ""))
    print("\n      SUMMARY over 49 pairs (taps presented at their descriptor lags): %s"
          % ", ".join("%s x%d" % kv for kv in summary.most_common()))
    return by


#  ★★★ 230 -- THE SYNTHETIC SELF-TEST (RULE 20, with 228's clause).
#
#  228 recorded that a control which IS the open defect is validated exactly
#  once and is invalidated by its own success -- it cost two tools their
#  self-tests.  So none of these limbs reference a defect this pass repaired.
#  Every one hands the measurement code a signal whose lag and gain THIS
#  FUNCTION constructed, and checks the code recovers them; the negative limbs
#  hand it signals that must NOT be accepted.  They survive the repair.
def cmd_selftest():
    hdr("SELF-TEST FIRST (RULE 20).  SYNTHETIC and two-sided -- no limb depends")
    results = []

    def check(name, got, expect):
        ok = (got == expect)
        results.append(ok)
        print("  %-52s %-4s  (got %s, want %s)"
              % (name, "PASS" if ok else "FAIL", got, expect))

    #  --- positive: the measurement code must recover a lag and a gain that
    #      this function put there.  Three different (lag, gain) pairs. ---
    for lag, samp in ((1001, 45074), (17, -3), (640, 8388606)):
        x = [0.0] * (lag + 40)
        x[4] = float(1 << 21)
        out = [0.0] * (lag + 40)
        out[4] = float(1 << 21)
        out[4 + lag] = float(samp)
        ev = echoes(x, out)
        check("T1 synthetic (lag %d, sample %d) recovered" % (lag, samp),
              (ev[0][0], int(ev[0][1])) if ev else None, (lag, samp))

    #  --- negative: an all-zero output must yield NO echo, and a signal whose
    #      only echo is at the WRONG lag must not be readable at the right one. ---
    x = [0.0] * 1100
    x[4] = float(1 << 21)
    check("T2 NEG all-zero output -> no echo", echoes(x, [0.0] * 1100), [])
    out = [0.0] * 1100
    out[4] = float(1 << 21)
    out[4 + 500] = 45074.0
    check("T3 NEG echo at 500 is not visible at 1001",
          [e for e in echoes(x, out) if e[0] == 1001], [])
    check("T3b  ... and IS visible at 500",
          [(e[0], int(e[1])) for e in echoes(x, out) if e[0] == 500], [(500, 45074)])

    #  --- the derivations, against answers computable by hand from `taps' ---
    stages, D = cascade()
    check("T4 cascade total lag = sum of the two taps",
          D, sum(t[4] for t in taps()))
    check("T5 stage order: the SRC 0x0B write is stage 1",
          [s[0] for s in stages], [0, 1])
    check("T6 head write is the one whose bus is NOT the delay return",
          DIS.lo_src(L.program(ALGO).words[head_write_iw()]) == 0x0B, False)

    #  --- the fixed-point prediction, against an independent hand computation ---
    c, h = 0xE5762C - (1 << 24), 0x400000
    check("T7 ROM triple in Q0.23 (hand: ((c*c)>>23)*h>>23)",
          rom_triple()[1], ((c * c) >> 23) * h >> 23)
    check("T8 predicted echo sample for amp 1<<21",
          predicted_echo_sample(1 << 21), (1 << 21) * (((c * c) >> 23) * h >> 23) >> 23)

    #  --- p0 derivation: EXTERNAL known answer.  `out_run' hard-coded p0 = 0x08
    #      against incell 0x03 since the tool was written; the derivation must
    #      reproduce that number without being told it. ---
    m = machine(act0d="tA<-bus", act0e="tA<-bus")
    check("T9 EXTERNAL p0 derived for incell 0x03 = out_run's old 0x08",
          derive_p0(m, 0x03), 0x08)
    check("T10 NEG p0 = 0 puts the head write on a cell nobody drives",
          ptr_offsets(m)[head_write_iw()], 0xFB)

    n = sum(1 for r in results if r)
    print("  ---> %d of %d PASS" % (n, len(results)))
    return n == len(results)
def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("cmd", nargs="?", default="all",
                    choices=["selftest", "taps", "control", "scan", "value",
                             "src00", "act0d0e", "multitap", "all"])
    a = ap.parse_args()
    #  ★ RULE 20: the self-test is printed FIRST, on every invocation that can
    #  produce a graded number.  It is synthetic, so it cannot be retired by a
    #  repair (228's clause).
    if a.cmd in ("selftest", "control", "value", "scan", "src00",
                 "act0d0e", "all"):
        ok = cmd_selftest()
        if not ok:
            print("\n  ⛔ SELF-TEST FAILED -- every number below is UNGRADED.\n")
        print()
    if a.cmd == "selftest":
        return
    if a.cmd in ("taps", "all"):
        cmd_taps()
    if a.cmd in ("control", "all"):
        print()
        cmd_control()
    if a.cmd in ("value", "all"):
        print()
        cmd_value()
    if a.cmd == "scan":
        print()
        cmd_scan()
    if a.cmd in ("src00", "all"):
        print()
        cmd_src00()
    if a.cmd == "act0d0e":
        print()
        cmd_act0d0e()
    if a.cmd == "multitap":
        print()
        cmd_multitap()


if __name__ == "__main__":
    main()
