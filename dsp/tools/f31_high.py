#!/usr/bin/env python3
"""hi12[3:1] > 2 -- the accumulator operation select, and what can decide it.

`act0b-reverb.md' sect. 4 sized this field for the first time: `step()' decodes
hi12[3:1] for 0, 1 and 2 and REFUSES 3..7, which is 203 of 3154 corpus words --
31 of them otherwise fully anchored, trapping for this reason alone.  It is also
what blocks the ACTION 0x0B minimal pair, the one site in the corpus with known
mathematics downstream.

    python3 dsp/tools/f31_high.py shape     # ★ is bit 2 an independent modifier?
    python3 dsp/tools/f31_high.py biquad    # ★ the control that cannot fail
    python3 dsp/tools/f31_high.py census    # the decidability census

See ../analysis/f31-high.md.
"""
import collections
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import action00_discriminate as A0    # noqa: E402
import delayline as DL                # noqa: E402
import dsp_disasm as DIS              # noqa: E402
import lfo_ramp as L                  # noqa: E402

KNOWN = {39: "PARAMETRIC EQ", 9: "SINGLE DELAY", 1: "CHORUS", 48: "AUTO PAN"}


def hdr(t):
    print("\n" + "=" * 78 + "\n== %s\n" % t + "=" * 78)


def images():
    C = DL.ctx()
    seen = {}
    for a in sorted(C.imgs):
        seen.setdefault(tuple(C.imgs[a]), a)
    return {a: list(k) for k, a in seen.items()}


def cmd_shape(imgs):
    hdr("IS BIT 2 OF hi12[3:1] AN INDEPENDENT MODIFIER?")
    c = collections.Counter()
    for ws in imgs.values():
        for w in ws:
            c[DIS.hi_f31(DIS.hi12(w))] += 1
    lo, hi = [c[i] for i in range(4)], [c[i] for i in range(4, 8)]
    print("""  If bit 2 were an independent flag over a 2-bit base op, the base
  distribution should have the SAME SHAPE in both halves of the field.
""")
    print("  bit2=0 (f=0..3): %-26s total %d" % (lo, sum(lo)))
    print("  bit2=1 (f=4..7): %-26s total %d" % (hi, sum(hi)))
    print("\n  normalised to base 0:")
    print("     bit2=0 : %s" % ["%.3f" % (v / lo[0]) for v in lo])
    print("     bit2=1 : %s" % ["%.3f" % (v / hi[0]) for v in hi])
    exp = [v * sum(hi) / sum(lo) for v in lo]
    chi = sum((o - e) ** 2 / e for o, e in zip(hi, exp) if e)
    print("\n  expected bit2=1 if the shape matched : %s"
          % ["%.1f" % e for e in exp])
    print("  observed                             : %s" % hi)
    print("""
  ★ BASES 0, 1 AND 2 TRACK ALMOST EXACTLY (1.000 / 0.997 / 0.213 against
  1.000 / 0.983 / 0.203).  BASE 3 DOES NOT -- 21 observed against 2.6
  expected, and chi2 = %.1f on 3 df is driven almost entirely by that one
  cell.  So "bit 2 is a modifier over the same three base operations" is
  CONSISTENT for bases 0..2 and REFUTED as a complete account, because a
  pure modifier cannot change how often its base occurs.

  This is a frequency argument and nothing more: it says the field has
  structure, not what the structure MEANS.  It is offered as a lead, not
  as a decode.""" % chi)
    return {"lo": lo, "hi": hi, "chi2": chi}


def _ir(prefix, m, coefs, n, amp=1 << 22):
    st = A0.State()
    out = []
    words = tuple(prefix) + A0.PEQ
    for _t in range(n):
        x = amp if _t == 0 else 0
        st.acc = x << A0.ASH
        st.P = x << A0.ASH
        st.p = 0
        cur = 0
        for w in words:
            c = coefs[cur % len(coefs)] if DIS.cursor_fetch(w) else None
            if not A0.step(m, st, w, c, None, ash=A0.ASH, psh=A0.PSH):
                return None
            if DIS.coeff_consumer(w):
                cur += 1
        out.append(max(-(1 << 23), min(A0.MASK23, st.acc >> A0.ASH)))
    return out


def _wdb(prefix, m, banks, n=512):
    worst = 0.0
    for _nm, cram in banks:
        r = _ir(prefix, m, cram, n)
        if r is None:
            return None
        for f in A0.FREQS:
            want = A0.ideal_H(cram, f)
            if abs(want) < 1e-9:
                continue
            got = A0.dft_at(r, f) / (1 << 22)
            if abs(got) == 0.0:
                return 999.0
            worst = max(worst, abs(20 * math.log10(abs(got) / abs(want))))
    return worst


def cmd_biquad():
    hdr("★ THE BIQUAD CANNOT DECIDE THIS FIELD -- a control that cannot fail")
    ws = L.algo_to_image()[39][2]
    banks = A0.peq_banks()
    pre = (ws[2], ws[3], ws[4])
    pre2 = (ws[55], ws[56], ws[57])
    print("""  PARAMETRIC EQ carries four f>2 words, and two of them sit in an
  identical structural position: an f=1 word, then an f=5 word, then a
  word that stores the accumulator to mem[ptr] -- immediately before a
  biquad copy.  That looks like the input stage feeding a filter whose
  response we know to the bit.  It is not usable, and the reason is
  worth more than the experiment would have been.
""")
    M = (lambda hi: A0.Machine("adder", "load", "before", "b7_f31_1_off",
                               f31hi=hi))
    print("  BASELINE  biquad alone            : %7.3f dB"
          % _wdb((), M(None), banks))
    print("  CONTROL   f31hi=None + the prefix : %s"
          % ("TRAPPED (correct -- the prefix carries f=5)"
             if _wdb(pre, M(None), banks) is None else "?!"))
    for nm, p in (("w002,w003,w004", pre), ("w055,w056,w057", pre2)):
        print("\n  prefix %s:" % nm)
        for hi in A0.F31HI:
            v = _wdb(p, M(hi), banks)
            print("     f31hi=%-5s : %s"
                  % (hi, "%7.3f dB" % v if v is not None else "TRAPPED"))
    print("""
  ★ EVERY READING SCORES THE BASELINE EXACTLY.  The prefix has no effect
  on the response at all, so the test cannot distinguish anything -- and
  it could not have, for a reason visible without running it:

      PEQ's biquad begins with an f31 = 0 word (acc <- P), which DISCARDS
      the accumulator.  Nothing upstream that only touches acc can be seen
      through it.

  The store at w004 does observe the difference -- it writes acc to
  mem[ptr] -- but w004 post-increments the pointer by 0x40, so the biquad
  reads a different cell and the value is never read back.  Third control
  that could not fail in one day, and the same barrier the ACTION 0x00
  census names: an f31 = 0 word kills every accumulator difference.""")
    return True


def cmd_census(imgs):
    hdr("THE DECIDABILITY CENSUS -- which of the 203 can carry a difference?")
    print("""  A difference born at an undecoded f>2 word lives in the accumulator.
  It DIES at the next f31 = 0 word (acc <- P overwrites it) and it is
  OBSERVED if it first reaches a store (hi12 bit 4), a word that captures
  the accumulator (ACTION 0x19) or a word that sources it (SRC 0x10).
""")
    born = blind = obs = 0
    why = collections.Counter()
    per = collections.Counter()
    for a, ws in imgs.items():
        for i, w in enumerate(ws):
            if DIS.hi_f31(DIS.hi12(w)) <= 2:
                continue
            born += 1
            hit = None
            for j in range(i + 1, len(ws)):
                v = ws[j]
                if DIS.hi12(v) & 0x10:
                    hit = "store"
                    break
                if DIS.lo_act(v) == 0x19 or DIS.lo_src(v) == 0x10:
                    hit = "acc read"
                    break
                if DIS.hi_f31(DIS.hi12(v)) == 0:
                    break
            if hit:
                obs += 1
                why[hit] += 1
                per[a] += 1
            else:
                blind += 1
    print("  words carrying an undecoded f31              : %d" % born)
    print("  BLIND (an f31=0 word overwrites acc first)   : %d" % blind)
    print("  can carry a difference to an observable      : %d" % obs)
    print("  first observable reached: %s" % dict(why))
    print("\n  ★ in the programs whose arithmetic is known independently:")
    for a, nm in KNOWN.items():
        print("     algo %-3d %-14s : %d observable" % (a, nm, per.get(a, 0)))
    print("""
  ★★ AND `OBSERVABLE' IS NECESSARY, NOT SUFFICIENT.  PARAMETRIC EQ's three
  observable sites all reach a STORE, and a store is only decidable if the
  cell is read back -- which for w004 it is not (see `biquad').  AUTO PAN
  is the better lead: 4 observable sites in a program whose LFO ramp is
  anchored nine-fold to `floor(f x 2^23 / 44100)' for round decimal rates
  (`lfo-ramp.md'), i.e. known mathematics that does NOT run through a
  biquad's f31=0 barrier.""")
    return {"born": born, "blind": blind, "obs": obs}


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "all"
    imgs = images()
    if cmd in ("all", "shape"):
        cmd_shape(imgs)
    if cmd in ("all", "biquad"):
        cmd_biquad()
    if cmd in ("all", "census"):
        cmd_census(imgs)


if __name__ == "__main__":
    main()
