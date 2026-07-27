#!/usr/bin/env python3
"""The consumer-lag signature, CALIBRATED -- and it cannot name a destination.

`adjudication-round8.md' item G established the shipped justification for
`LO_ACT_CAP_TA2' (ACTION 0x19) with this statistic: an ACTION site is followed,
at a characteristic lag, by a word that SOURCES the register the ACTION wrote,
far above a permutation null.  The device comment says "DESTINATION measured".

This tool runs that statistic against the two ACTION codes whose destinations
are known INDEPENDENTLY of it -- `LO_ACT_CAP_TA' (0x13 -> tempA) and
`LO_ACT_CAP_TB' (0x14 -> tempB) -- which is the rule-7 question nobody asked:
does the instrument, given a code whose answer we already know, point at the
right register?

It does not.  See `../analysis/capture-signature.md'.

    python3 dsp/tools/capture_sig.py            # everything
    python3 dsp/tools/capture_sig.py calib      # the two known codes
    python3 dsp/tools/capture_sig.py targets    # ACTION 0x0B and 0x1A
    python3 dsp/tools/capture_sig.py census     # the ACTION code census

Population (rule 9): the 40 DISTINCT body images, 3154 words.  Per-ALGORITHM
counting replicates the twelve byte-identical reverbs and inflates every count
by ~4.79x -- the defect `adjudication-round8.md' item E caught in the very pass
this tool re-examines.
"""
import collections
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import delayline as DL          # noqa: E402
import dsp_disasm as DIS        # noqa: E402

MAXLAG = 12
NNULL = 200
SEED = 20260727

REG = ((DIS.LO_SRC_TA, "tempA"), (DIS.LO_SRC_TB, "tempB"),
       (DIS.LO_SRC_MEM, "mem"), (DIS.LO_SRC_ACC, "acc"))


def images():
    """The DISTINCT body images -- rule 9, see the module docstring."""
    C = DL.ctx()
    seen = {}
    for a in sorted(C.imgs):
        seen.setdefault(tuple(C.imgs[a]), a)
    return [list(k) for k in seen]


def profile(imgs, act, src):
    """(#sites, {lag: #sites whose word at that lag SOURCES `src'})."""
    per, n = collections.Counter(), 0
    for ws in imgs:
        for i, w in enumerate(ws):
            if DIS.lo_act(w) != act:
                continue
            n += 1
            for d in range(1, MAXLAG + 1):
                if i + d < len(ws) and DIS.lo_src(ws[i + d]) == src:
                    per[d] += 1
    return n, per


def nulls(imgs, rng):
    """Shuffle the ACTION field WITHIN each image -- round 8's own null.

    Keeps every word's hi12/class4/addr8/SRC and the program's SRC sequence
    intact, so the null preserves exactly the structure the statistic is
    supposed to see through.
    """
    out = []
    for _ in range(NNULL):
        o = []
        for ws in imgs:
            acts = [DIS.lo_act(w) for w in ws]
            rng.shuffle(acts)
            o.append([(w & ~0x1F) | a for w, a in zip(ws, acts)])
        out.append(o)
    return out


def best(imgs, NUL, act, src):
    n, p = profile(imgs, act, src)
    hit = max(p.items(), key=lambda kv: kv[1]) if p else (0, 0)
    nb = 0
    for sh in NUL:
        _, q = profile(sh, act, src)
        if q:
            nb = max(nb, max(q.values()))
    return n, hit[0], hit[1], nb


def table(imgs, NUL, act, label):
    rows = [(nm,) + best(imgs, NUL, act, s)[1:] + (best(imgs, NUL, act, s)[0],)
            for s, nm in REG]
    n = rows[0][-1]
    print("  ACTION 0x%02X  %-44s sites=%d" % (act, label, n))
    for nm, lag, hit, nb, _ in rows:
        print("      %-6s best lag %2d : %3d/%3d = %5.1f%%   null(best of %d) "
              "%3d = %5.1f%%%s"
              % (nm, lag, hit, n, 100.0 * hit / n, NNULL, nb, 100.0 * nb / n,
                 "   ** above null **" if hit > nb else "   (at/below null)"))
    return {nm: (lag, hit, nb, n) for nm, lag, hit, nb, _ in rows}


def hdr(t):
    print("\n" + "=" * 78 + "\n== %s\n" % t + "=" * 78)


def cmd_census(imgs):
    hdr("THE ACTION CODE CENSUS -- and a hypothesis of mine that FAILED")
    c = collections.Counter()
    for ws in imgs:
        for w in ws:
            c[DIS.lo_act(w)] += 1
    print("  population: %d words over %d DISTINCT images\n"
          % (sum(len(w) for w in imgs), len(imgs)))
    print("  code  popcount  count  anchored")
    for a in sorted(c):
        print("  0x%02X     %d     %5d   %s"
              % (a, bin(a).count("1"), c[a],
                 "YES" if a in DIS._ANCHORED_ACT else ""))
    three = [a for a in range(32) if bin(a).count("1") == 3]
    print("""
  ★ A HYPOTHESIS OF MINE, FALSIFIED BY THIS TABLE AND PRINTED ANYWAY.
  Every ACTION code the device has decoded except 0x00/0x12/0x14 has
  exactly THREE of its five bits set, and all ten 3-of-5 codes occur.
  That looked like a 3-of-5 constant-weight encoding, which would have
  bounded the whole field at ten values plus a no-op.  It is WRONG:
  %d of the 32 codes occur and their popcounts run 0,1,2,3,4,5 --
  every weight class is populated, including 0x1F (all five bits).
  A constant-weight code cannot have members of two different weights.
  Reported because a falsified structural guess costs nothing and a
  quietly-dropped one costs the next reader an afternoon.""" % len(c))
    return {"three": [a for a in three if c[a]], "codes": len(c)}


def cmd_calib(imgs, NUL):
    hdr("CALIBRATION -- given a code whose destination we ALREADY KNOW, "
        "does the\n   statistic point at the right register?  (rule 7)")
    print("""  A capture into register R should be followed by a word SOURCING R.
  Two codes have destinations established independently of this statistic:
      LO_ACT_CAP_TA = 0x13  ->  tempA   (SRC 0x19)
      LO_ACT_CAP_TB = 0x14  ->  tempB   (SRC 0x1A)
  If the instrument works, each should score highest on its OWN register.
""")
    r13 = table(imgs, NUL, 0x13, "-> tempA, known independently")
    print()
    r14 = table(imgs, NUL, 0x14, "-> tempB, known independently")
    print()
    r19 = table(imgs, NUL, 0x19, "-> tempA, CLAIMED by round 8 item G")

    ok13 = r13["tempA"][1] > r13["tempB"][1] and \
        r13["tempA"][1] > r13["mem"][1] and r13["tempA"][1] > r13["acc"][1]
    ok14 = r14["tempB"][1] > r14["tempA"][1] and \
        r14["tempB"][1] > r14["mem"][1] and r14["tempB"][1] > r14["acc"][1]
    print("""
  ★★★ THE VERDICT, AND IT IS NEGATIVE.
      0x13 (tempA): its own register ties tempB EXACTLY (%d = %d) and both
                    are BEATEN by mem (%d).  Top signal names the WRONG place.
      0x14 (tempB): its own register scores %d; the OTHER temp scores %d.
                    The instrument prefers the WRONG REGISTER, by %.1f points.
      names its own register correctly: 0x13 %s, 0x14 %s  -> %d of 2.

  So the statistic has real power against NOISE -- every row above beats a
  200-fold permutation null -- and NO DEMONSTRATED POWER to choose between
  the candidate destinations.  That is the H-DIR failure mode exactly
  (`dram-cursor-closure.md' item F, `dram-direction.md'): a rule that scores
  well and cannot discriminate.  What it actually measures is STRUCTURAL
  ADJACENCY in a motif that interleaves two temporaries, not dataflow.

  ⚠ CONSEQUENCE FOR THE SHIPPED DEVICE.  `LO_ACT_CAP_TA2' (ACTION 0x19)
  ships on the owner's explicit decision (2026-07-27) with its FORCING
  withdrawn, justified by exactly this measurement -- "DESTINATION measured
  (74/89, lag 1)".  0x19 IS the cleanest of the three profiles: its own
  register is far above null while BOTH other candidates sit at or below it,
  which neither known code manages.  But "cleanest" is not a calibrated
  criterion, because NEITHER code with a known answer produces a clean
  profile to calibrate it against.  The succession is real; the inference
  from succession to DESTINATION is what fails here.  The semantic is NOT
  refuted and nothing is re-trapped -- the comment is corrected, the
  behaviour is not.""" % (r13["tempA"][1], r13["tempB"][1], r13["mem"][1],
                          r14["tempB"][1], r14["tempA"][1],
                          100.0 * (r14["tempA"][1] - r14["tempB"][1])
                          / r14["tempA"][3],
                          "YES" if ok13 else "NO",
                          "YES" if ok14 else "NO", int(ok13) + int(ok14)))
    return {"ok13": ok13, "ok14": ok14, "r19": r19}


def cmd_targets(imgs, NUL):
    hdr("THE TARGETS -- ACTION 0x0B and 0x1A, the codes that gate the reverb")
    print("""  Measured this pass: the whole 133-word reverb image is gated on SIX
  unanchored codes -- ACT 0x0B / 0x0D / 0x1A and SRC 0x00 / 0x0B / 0x11 --
  distributed BLOCK A (x9): ACT 0x0B; BLOCK B (x2): ACT 0x0B, 0x1A;
  BLOCK C (x2): ACT 0x0D.  ACTION 0x0E does not occur in the reverb at all.
""")
    r0b = table(imgs, NUL, 0x0B, "gates BLOCK A and BLOCK B")
    print()
    r1a = table(imgs, NUL, 0x1A, "gates BLOCK B")
    print("""
  ★ ACTION 0x0B IS NOT A TEMPORARY-REGISTER CAPTURE.  Its tempA profile is
  AT the null to the count (%d vs %d) and its tempB profile is 6 points over
  it; mem and acc lead, and both by margins smaller than 0x13's or 0x14's.
  Whatever 0x0B does, no temporary is read after it at any lag up to %d more
  often than the ACTION labels being shuffled at random.  Given the
  calibration above this CANNOT be turned into a positive identification --
  but the NEGATIVE survives it, because a statistic that over-reports
  adjacency can only make a capture look MORE present, never less.

  ★ ACTION 0x1A leans tempA (%d/%d) with tempB at null -- which is the exact
  shape 0x14 shows while writing tempB.  Per the calibration it is NOT
  evidence that 0x1A writes tempA.  21 sites, and the smallest population
  here.""" % (r0b["tempA"][1], r0b["tempA"][2], MAXLAG,
              r1a["tempA"][1], r1a["tempA"][3]))
    return {"r0b": r0b, "r1a": r1a}


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "all"
    imgs = images()
    rng = random.Random(SEED)
    NUL = nulls(imgs, rng)
    if cmd in ("all", "census"):
        cmd_census(imgs)
    if cmd in ("all", "calib"):
        cmd_calib(imgs, NUL)
    if cmd in ("all", "targets"):
        cmd_targets(imgs, NUL)


if __name__ == "__main__":
    main()
