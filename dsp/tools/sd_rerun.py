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


# ---------------------------------------------------------------------------
#  2. THE RUN -- the SAME ALU model as every other tool (A.step), differing ONLY
#     in the delay port.  `polarity' and `sign' are enumerated, never fixed.
# ---------------------------------------------------------------------------
def run(m, nsamp=1400, polarity="correct", sign=+1, seed=20260727, incell=0x00):
    import random
    words, cells, cons, coefs = descriptors()
    cell_of = {idx: c for (idx, _), c in zip(cons, cells)}
    rng = random.Random(seed)
    dram = DelayDRAM(sign)
    st = A.State(rng)
    x = [0.0] * nsamp
    x[8] = float(1 << 20)                      # the impulse
    reads = {ri: [0.0] * nsamp for ri in cell_of}

    for n in range(nsamp):
        st.acc = st.P = 0
        st.ta = st.tb = 0
        st.p = 0
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


def cmd_control():
    hdr("control -- the instrument must PASS what should work and FAIL what should not")
    print("""   Method rule 1: a control that cannot fail is not a control.  Four
   configurations; the two DEFECTS round 6 identified must NOT reproduce the
   descriptors' delay, and the corrected one must.\n""")
    m = machine(act0d="tA<-bus", act0e="mem<-bus")
    want = sorted(set(d for *_, d in taps()))
    print("   INPUT CELLS -- the body reads these before writing them, so the kernel")
    print("   supplies them.  Which one carries the audio is ENUMERATED, not assumed.\n")
    print("   %-10s %-26s %-8s %s" % ("in cell", "configuration", "peak lag", "verdict"))
    for ic in (0x00, 0x03, 0x0A, 0x4C, 0x4E):
        for lbl, pol, sg in (("CORRECTED (dram_dir,+1)", "correct", +1),
                             ("reversed (round-6 defect)", "reversed", +1)):
            r = run(m, polarity=pol, sign=sg, incell=ic)
            if r is None:
                print("   0x%02X       %-26s %-8s machine refused" % (ic, lbl, "-"))
                continue
            xx, rr = r
            best = None
            for idx, y in rr.items():
                lag, sc, sec = peak_lag(xx, y)
                if sc > 0 and (best is None or sc > best[1]):
                    best = (lag, sc, sec, idx)
            if best is None:
                print("   0x%02X       %-26s %-8s no signal" % (ic, lbl, "-"))
            else:
                lag, sc, sec, idx = best
                v = "★ MATCHES DESCRIPTOR" if lag in want else "does not match"
                print("   0x%02X       %-26s %-8d %s (w%d, x%.2f)"
                      % (ic, lbl, lag, v, idx, sc / sec if sec else 9e9))
    print()
    print("   descriptors demand a peak at one of: %s\n" % want)
    print("   %-28s %-8s %s" % ("configuration", "peak lag", "verdict"))
    for lbl, pol, sg in (("CORRECTED (dram_dir, +1)", "correct", +1),
                         ("corrected, cursor -1", "correct", -1),
                         ("round-6 defect: reversed", "reversed", +1),
                         ("reversed + cursor -1", "reversed", -1)):
        r = run(m, polarity=pol, sign=sg)
        if r is None:
            print("   %-28s %-8s machine refused" % (lbl, "-"))
            continue
        x, reads = r
        best = None
        for idx, y in reads.items():
            lag, sc, sec = peak_lag(x, y)
            if sc > 0 and (best is None or sc > best[1]):
                best = (lag, sc, sec, idx)
        if best is None:
            print("   %-28s %-8s NO SIGNAL -- nothing came back" % (lbl, "-"))
        else:
            lag, sc, sec, idx = best
            ok = "★ MATCHES the descriptor" if lag in want else "does not match"
            marg = sc / sec if sec else float("inf")
            print("   %-28s %-8d %s  (w%d, margin x%.2f)" % (lbl, lag, ok, idx, marg))


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


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("cmd", nargs="?", default="all",
                    choices=["taps", "control", "scan", "all"])
    a = ap.parse_args()
    if a.cmd in ("taps", "all"):
        cmd_taps()
    if a.cmd in ("control", "all"):
        print()
        cmd_control()
    if a.cmd in ("scan", "all"):
        print()
        cmd_scan()


if __name__ == "__main__":
    main()
