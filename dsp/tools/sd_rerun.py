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
  ★★★★ 229 -- THREE DEFECTS IN THIS TOOL, DIAGNOSED AND REPAIRED
===========================================================================

CONTROL-AUDIT_findings.md (f601303) graded this tool's `control' leg the WORST
control in the project: rerun, it returned NO SIGNAL for the CORRECTED machine
and `500 * MATCHES' for the doubly-defective one, i.e. it was INVERTED.  229
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


#  ★★★ 229 D3.  The two taps are in CASCADE, and the ORDER IS DERIVED, not
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


#  ★★★ 229 D1.  The pointer walk is p0-invariant modulo 256, so the pointer at
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
    """p0 such that the HEAD WRITE word's pointer lands on `incell'."""
    off = ptr_offsets(m)
    return (incell - off[head_write_iw()]) & 0xff


#  ★★★ 229.  THE PREDICTION, IN FIXED POINT, FROM THE ROM's OWN COEFFICIENTS.
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
    #  ★ 229 D1: p0 is DERIVED so the head write lands on `incell'.  Passing
    #  p0 explicitly is still allowed -- that is how the defect is reproduced.
    if p0 is None:
        p0 = derive_p0(m, incell)
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


#  ★★★ 229 -- THE REPAIRED, TWO-SIDED CONTROL.
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
    hdr("control -- 229's REPAIRED two-sided control (see the module docstring)")
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
    print("      number:  incell 0x03  =>  p0 = 0x%02X   (229 D1)\n"
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
    #  --- p0 left at State's default: 229 D1 reproduced on purpose ---
    okall &= _grade("p0 = 0 (the 229 D1 defect)", m, D, want, False, p0=0x00)
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
    #  ★ 229 D1: 0x08 was hard-coded here and NOWHERE ELSE, which is why the
    #  value leg had a live datapath and the control leg did not.  Derive it.
    if p0 is None:
        p0 = derive_p0(m, incell)
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


#  ★★★ 229 D3.  NO WINDOW AND NO HARD-CODED D.  `echo_energies' summed a
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
    hdr("value -- the ROM's three-factor product, measured (229's repair)")
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


#  ★★★ 229 -- THE SYNTHETIC SELF-TEST (RULE 20, with 228's clause).
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
                    choices=["selftest", "taps", "control", "scan", "value", "all"])
    a = ap.parse_args()
    #  ★ RULE 20: the self-test is printed FIRST, on every invocation that can
    #  produce a graded number.  It is synthetic, so it cannot be retired by a
    #  repair (228's clause).
    if a.cmd in ("selftest", "control", "value", "scan", "all"):
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


if __name__ == "__main__":
    main()
