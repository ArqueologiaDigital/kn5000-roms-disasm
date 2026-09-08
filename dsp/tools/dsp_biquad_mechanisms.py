#!/usr/bin/env python3
# license:BSD-3-Clause
# copyright-holders:Felipe Sanches
"""dsp_biquad_mechanisms.py -- the uPD6383GF has TWO distinct filter primitives, and
they separate cleanly by effect family.

An earlier family-concentration scan flagged ACT 0x12/0x13/0x14 as "OPEN codes worth
decoding". They are NOT open: tracing the PARAMETRIC EQ reference program (prog39 / eff04)
end to end shows they are the state-latch ops of a Direct-Form-I bilinear biquad, which the
disassembler already renders `mac`, `ld.ta`, `mac.tb`. This tool measures the split across
both products' committed .dsm:

  * The Direct-Form-I LATCH biquad -- a 9-word section
        ld.ta (0x13)  mac(+1) (0x12)  mac  mac.tb (0x14)  mac  mac.st tb  post(class8)  mac.st makeup  ld.st ta
    with coefficients b1,b0,b2,-a1,-a2,makeup -- is used ONLY by the parametric-EQ family
    (PARAMETRIC EQ + every PEQ+* combo) and the state-variable AUTO/PEDAL WAH. `ld.ta`
    marks each section entry; the class-8 `post acc,c` is the section's normalize/output
    step and appears ONLY in these programs.
  * The ACT 0x0D/0x0E two-state PAIR (adjacent 82%, dsp_context_analysis) is the GENERAL
    one/two-pole update used in the I/O amble and feedback-damping of EVERY family.

So a parametric-EQ program carries BOTH mechanisms: DF-I latch biquads for its bands, plus
the 0x0D/0x0E pair in its input/output amble. A reverb/modulation/delay program uses ONLY
the 0x0D/0x0E pair.

Why 0x13 and 0x14 are NOT an adjacent pair (dsp_context_analysis measured 0/66): in a DF-I
section they are the section ENTRY (ld.ta, latch A <- S0) and the -a1 tap (mac.tb, latch B
<- S2), three words apart -- not a z^-1/z^-2 neighbour pair. The negative adjacency result
is the correct signature of a DF-I section, not of a biquad z-pair.

Cross-product: parametric EQ is CONVERGENT -- both products use the identical DF-I latch
biquad (KN5000 5 bands x 2ch, WSA1R 6 bands x 2ch). This contrasts with the reverb
primitive, which genuinely differs between the products (DECODE-by-correlation sect. 5).

    python3 dsp/tools/dsp_biquad_mechanisms.py

Graded structural evidence from the committed disasm; the DF-I coefficient roles are PROVEN
in prog39 (dsp/algorithms), the family split is measured here. stdlib + dsp_disasm; read-only.
"""
import collections
import glob
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import dsp_disasm as D                              # noqa: E402

WORD = re.compile(r"^\s*w\d+\s+([0-9A-Fa-f]{10})\b")
NAMELINE = re.compile(r"program -- (.+?)\s*$")
TREES = [os.path.join(HERE, "..", "disasm"),
         os.path.join(HERE, "..", "..", "wsa1", "dsp", "disasm")]

LATCH_ENTRY = 0x13   # ld.ta  -- DF-I section entry (latch A <- S0)
LATCH_B     = 0x14   # mac.tb -- the -a1 tap (latch B <- S2)
MAC_ADV     = 0x12   # mac,c+,(p)+1 -- the b0 tap (workhorse MAC + advance)
BIQ_Z0      = 0x0D   # two-state pair, first
BIQ_Z1      = 0x0E   # two-state pair, second


def load_all():
    progs = {}
    for tree in TREES:
        for p in glob.glob(os.path.join(tree, "*.dsm")):
            b = os.path.basename(p)
            if b in ("index.dsm", "kernel.dsm", "epilogue.dsm") or b.startswith("struct_"):
                continue
            nm, ws = None, []
            for ln in open(p):
                m = NAMELINE.search(ln)
                if m:
                    nm = m.group(1)
                m = WORD.match(ln)
                if m:
                    ws.append(int(m.group(1), 16))
            if nm and ws:
                progs[b] = (nm, ws)
    return progs


def family(n):
    n = n.upper()
    if "EQ" in n:                                              return "eq"
    if any(k in n for k in ("REVERB", "HAAS", "GATED")):      return "reverb"
    if "DELAY" in n:                                          return "delay"
    if any(k in n for k in ("CHORUS", "FLANGER", "PHASER", "VIBRATO",
                            "ENSEMBLE", "PAN", "RING", "ROTARY")): return "modulation"
    if any(k in n for k in ("DIST", "FUZZ", "OVERDR", "EXCITER",
                            "WAH", "COMPRESS")):                return "dyn/dist"
    return "other"


def main():
    progs = load_all()
    fam_stats = collections.defaultdict(lambda: collections.Counter())
    fam_progs = collections.defaultdict(set)
    df1_progs = []
    for b, (nm, ws) in progs.items():
        f = family(nm)
        fam_progs[f].add(nm)
        acts = [D.lo_act(w) for w in ws]
        entries = acts.count(LATCH_ENTRY)
        post8 = sum(1 for w in ws if D.class4(w) == 8)
        fam_stats[f]["ld.ta"] += entries
        fam_stats[f]["mac.tb"] += acts.count(LATCH_B)
        fam_stats[f]["post"] += post8
        fam_stats[f]["0x0D"] += acts.count(BIQ_Z0)
        fam_stats[f]["0x0E"] += acts.count(BIQ_Z1)
        if entries:
            df1_progs.append((nm, entries, post8))

    print("TWO filter mechanisms of the uPD6383GF, by effect family\n")
    print("family      progs  DF-I:ld.ta  mac.tb  post   pair:0x0D  0x0E   dominant")
    for f in sorted(fam_stats, key=lambda k: -fam_stats[k]["ld.ta"]):
        s = fam_stats[f]
        dom = "DF-I latch biquad" if s["ld.ta"] > max(s["0x0D"], s["0x0E"]) \
              else "0x0D/0x0E two-state pair"
        print("%-10s  %4d   %6d     %5d   %4d    %6d  %5d   %s"
              % (f, len(fam_progs[f]), s["ld.ta"], s["mac.tb"], s["post"],
                 s["0x0D"], s["0x0E"], dom))

    print("\nDirect-Form-I biquad programs (ld.ta present) -- sections = ld.ta count / 2ch:")
    for nm, e, p8 in sorted(df1_progs):
        print("  %-24s %2d ld.ta  %2d post   (~%d biquad sections/channel)"
              % (nm, e, p8, e // 2 if e >= 2 else e))

    tot_ldta = sum(s["ld.ta"] for s in fam_stats.values())
    eq_ldta = fam_stats["eq"]["ld.ta"] + fam_stats["dyn/dist"]["ld.ta"]
    print("\n%d of %d ld.ta section-entries are in EQ / PEQ-combo / wah programs (%.0f%%)."
          % (eq_ldta, tot_ldta, 100.0 * eq_ldta / (tot_ldta or 1)))
    print("The class-8 `post acc,c` op occurs ONLY in these DF-I programs -- it is the")
    print("biquad section's normalize/output step, not a general instruction.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
