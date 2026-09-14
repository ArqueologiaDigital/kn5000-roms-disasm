#!/usr/bin/env python3
"""f31_oracle_pin.py -- the ROM pins what `f31 = 4' computes, at three sites, with no emulator run.

QUESTION IT ANSWERS
    `f31' 3..7 is 257 undecoded occurrences and nothing positive has ever been said about any of
    them.  This file says something about **4**, from two things the project already had and had
    never put together:

      1. `kn5000_dsp_namedcoeff.host_coeff_map()' -- the HOST WRITER's own layout:
         *"MULTI-CELL coefficients are EXPANDED: op0x70 (biquad) writes 6 consecutive cells per
         band (b1, b0, b2, -a1, -a2, makeup)"*.  So where `op0x70' writes, the cell ORDER is not
         an assumption -- it is what the firmware does.
      2. `dsp/hle/lle_oracle.py::BIQUAD_SCHEDULE' -- the accumulator op PER SLOT:
         slot 0 `load' (acc <- b1*x1), slots 1..4 `mac' (acc += ...).

    Cross them and any undecoded word sitting on an `op0x70' cell has its accumulator operation
    pinned by the ROM's own two halves.

    ★ RESULT.  Eleven algorithms carry an `op0x70' band.  **Three contain an undecoded word**, and
    it is the SAME instruction in all three -- `0018A001D5` (class A, SRC 0x07 mem, ACT 0x15
    ANCHORED, **f31 = 4 the only open axis**) -- at the SAME slot:

        algo 75 PEQ+COMPRESSOR      w42  cell 0x11  band 1 slot 2 (b2)   acc_op = mac
        algo 96 PEQ+COMPR+DIST      w58  cell 0x15  band 1 slot 2 (b2)   acc_op = mac
        algo 97 PEQ+COMPR+OVERDR    w61  cell 0x18  band 1 slot 2 (b2)   acc_op = mac

    ⇒ **`f31 = 4' computes `acc += P' there -- the same ALGEBRA as `f31 = 1' (ADD).**

USAGE
    python3 dsp/tools/f31_oracle_pin.py

⛔ WHAT THIS IS NOT, and why it is NOT promoted
    * **One distinct instruction** (rule 9).  Three PROGRAMS is better than three occurrences in
      one, but it is still a single word shape.
    * **The oracle is a FLOAT model** (`BiquadOracle.c = [float(v) ...]`).  It pins the ALGEBRA,
      `acc += product`, and cannot separate ADD from ADD-with-a-different-shift, rounding or
      saturation -- exactly the fixed-point detail `f31` might encode.  "Same algebra as `f31 = 1`"
      is therefore weaker than "`f31 4` IS `f31 1`".
    * It says nothing about `f31` 3, 5, 6 or 7.
    ⇒ a first POSITIVE constraint on the family, not a decode.  `alu_decoded()` is unchanged.
"""
import os
import sys

sys.path.insert(0, "/home/fsanches/compartilhado/kn7000_mame/tools")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kn5000_dsp_namedcoeff as NC                                        # noqa: E402
import kn5000_dsp_params as P                                             # noqa: E402
import sd_rerun as SD                                                     # noqa: E402
import dsp_disasm as DIS                                                  # noqa: E402
import acc_blind as B                                                     # noqa: E402

#   dsp/hle/lle_oracle.py BIQUAD_SCHEDULE, verbatim in its own order.
SCHEDULE = (("b1", "x1", "load"), ("b0", "x0", "mac"), ("b2", "x2", "mac"),
            ("-a1", "y1", "mac"), ("-a2", "y2", "mac"))
SUB = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                   "..", "..", "original_ROMs", "kn5000_subprogram_v142.rom")


def main():
    rom = P.Rom(SUB, P.SUB_BASE)
    print("=" * 100)
    print("  f31_oracle_pin -- the host writer's layout x the oracle's schedule")
    print("=" * 100)

    bands = []
    for algo in range(100):
        try:
            p = SD.L.program(algo)
        except Exception:
            continue
        m = NC.host_coeff_map(rom, algo)
        cells = sorted(a for a in m if m[a][0] == 0x70)
        if cells:
            bands.append((algo, getattr(p, "name", ""), cells, list(p.words)))
    print("\n   ★ algorithms carrying an `op0x70' biquad band: %d\n" % len(bands))
    for a, nm, c, _ in bands:
        print("      %-4d %-26s %s" % (a, str(nm)[:26], " ".join("%02X" % x for x in c)))

    print("\n   ★ UNDECODED words sitting on an `op0x70' cell -- the ROM pins their accumulator op\n")
    print("      %-5s %-24s %-6s %-7s %-6s %-6s %-6s %s"
          % ("algo", "name", "word", "cell", "band", "slot", "role", "acc_op PINNED"))
    hits = []
    for algo, nm, cells, words in bands:
        grp = [cells[i:i + 6] for i in range(0, len(cells), 6)]
        cur = 0
        for i, w in enumerate(words):
            if DIS.c_format(w):
                continue
            if DIS.cursor_fetch(w):
                if (not DIS.decoded(w)) and cur in cells:
                    bi = [k for k, b in enumerate(grp) if cur in b][0]
                    sl = grp[bi].index(cur)
                    role, _op, acc = SCHEDULE[sl] if sl < 5 else ("makeup", "-", "post")
                    hits.append((algo, nm, i, w, cur, bi, sl, role, acc))
                    print("      %-5d %-24s w%-5d 0x%02X    %-6d %-6d %-6s %s"
                          % (algo, str(nm)[:24], i, cur, bi, sl, role, acc))
                if DIS.coeff_consumer(w):
                    cur += 1
    if not hits:
        print("      NONE.")
        return 0
    ws = {h[3] for h in hits}
    ax = {tuple(B.open_axes(w)) for w in ws}
    print("\n   ⇒ %d sites, %d DISTINCT instruction(s): %s"
          % (len(hits), len(ws), " ".join("%010X" % w for w in ws)))
    print("     open axes: %s" % (", ".join("/".join(a) for a in ax)))
    slots = {h[6] for h in hits}
    accs = {h[8] for h in hits}
    print("     band slot(s): %s   accumulator op the schedule pins: %s"
          % (sorted(slots), sorted(accs)))
    print("\n   ⇒ ★ `f31 = %d' computes `acc += P' at these sites -- the same ALGEBRA as `f31 = 1'."
          % DIS.hi_f31(DIS.hi12(sorted(ws)[0])))
    print("   ⛔ NOT PROMOTED: one distinct instruction (rule 9), and the oracle is a FLOAT model")
    print("     so it cannot separate ADD from ADD-with-a-different-shift/rounding/saturation --")
    print("     the very fixed-point detail `f31' might encode.  Nothing is said about 3, 5, 6, 7.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
