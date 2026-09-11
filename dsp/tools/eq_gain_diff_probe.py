#!/usr/bin/env python3
"""eq_gain_diff_probe.py  --  N1': which C-RAM coefficients move when ONE EQ band
is boosted +12 dB, vs the flat default?

QUESTION IT ANSWERS
    eq_role_split_probe.py showed the ~13.5 kHz clustering is a property of the
    captured (near-default) coefficients, not the b/a decode, and asked for a
    DIFFERENTIAL capture instead of role-permuting.  This runs it: two captures
    with the SAME rig (peq_gain.lua, PARAMETER cursor on gain G), one flat
    (NVALUE=0) and one with band 0's gain driven up +12 dB (NVALUE=24).  The
    cells whose C-RAM coefficient MOVES are the ones that carry gain; the cells
    that stay put are frequency/Q.  This directly assigns coefficient roles from
    an intervention, not an inference.

CAPTURE RECIPE (binary built -DKN5000_ENABLE_DSP1=1; needs MAME -log)
    cd ~/compartilhado/kn7000_mame_build
    # FLAT control:
    DISPLAY=:0 TYPEIDX=15 NPARAM=2 NVALUE=0  UPD6383_TRACE_FRAME=2100000 timeout 420 \
      ./kn7000 kn5000 -rompath ./roms -skip_gameinfo -log \
      -autoboot_script ~/compartilhado/kn5000-roms-disasm/dsp/tools/peq_gain.lua
    cp error.log <flat.log>
    # BOOSTED (band-0 gain +12 dB):
    DISPLAY=:0 TYPEIDX=15 NPARAM=2 NVALUE=24 UPD6383_TRACE_FRAME=2400000 timeout 420 \
      ./kn7000 kn5000 -rompath ./roms -skip_gameinfo -log \
      -autoboot_script ~/compartilhado/kn5000-roms-disasm/dsp/tools/peq_gain.lua
    cp error.log <boost.log>
    # NPARAM = 0 (FC / centre freq), 1 (Q), 2 (gain).  The C-RAM dump is static
    # once the effect is selected, so the exact trace frame only has to land after
    # the edit and before the rig exits.
    python3 dsp/tools/eq_gain_diff_probe.py <flat.log> <boost.log>

FALSIFIER
    A +12 dB gain edit must move SOME coefficient(s).  If the two C-RAM dumps are
    identical, either the gain key was not driven or gain is applied outside C-RAM
    -- a finding either way.  If gain moves cells that the role decode calls
    "frequency", the decode is wrong.
"""
import re, sys, os

def load_cram(path):
    cram = {}
    for ln in open(path, encoding="utf-8", errors="replace"):
        m = re.search(r"C-RAM ([0-9A-Fa-f]{2}):\s+(.+)", ln)
        if not m:
            continue
        base = int(m.group(1), 16)
        for i, v in enumerate(m.group(2).split()):
            if re.fullmatch(r"[0-9A-Fa-f]{6}", v):
                cram[base + i] = int(v, 16)
    return cram

def q22(x):                      # 24-bit two's complement, Q1.22
    return (x - 0x1000000 if x >= 0x800000 else x) / 2.0 ** 22

def main():
    if len(sys.argv) < 3:
        print(__doc__); sys.exit(2)
    flat, boost = load_cram(sys.argv[1]), load_cram(sys.argv[2])
    fname = os.path.basename(sys.argv[2])
    cells = sorted(set(flat) | set(boost))
    print(f"eq_gain_diff_probe: flat={os.path.basename(sys.argv[1])}  "
          f"boost={fname}")
    print(f"  {len(flat)} flat cells, {len(boost)} boost cells, "
          f"{len(cells)} union\n")

    moved = []
    for c in cells:
        fa, ba = flat.get(c), boost.get(c)
        if fa is None or ba is None:
            moved.append((c, fa, ba, None)); continue
        if abs(q22(fa) - q22(ba)) > 1e-4:
            moved.append((c, fa, ba, q22(ba) - q22(fa)))
    if not moved:
        print("  *** NO C-RAM cell moved -- gain edit did not reach C-RAM "
              "(see falsifier).")
        return
    print(f"  {len(moved)} C-RAM cells changed flat -> boost:")
    print("   cell   flat (Q1.22)   boost (Q1.22)     delta")
    for c, fa, ba, d in moved:
        fs = f"{q22(fa):+.5f}" if fa is not None else "   --   "
        bs = f"{q22(ba):+.5f}" if ba is not None else "   --   "
        ds = f"{d:+.5f}" if d is not None else "  (appeared/vanished)"
        print(f"   0x{c:02X}   {fs:>10s}   {bs:>10s}   {ds}")

    # Cluster the moved cells to see whether the gain edit is localised (one band)
    # or global (a shared makeup), which the role model must match.
    lo = [c for c, *_ in moved if c < 0x40]
    hi = [c for c, *_ in moved if c >= 0x40]
    print(f"\n  moved in 0x00-0x3F (biquad-coeff region): {len(lo)}  cells "
          f"{['0x%02X'%c for c in lo]}")
    print(f"  moved in 0x40+     (tap/descriptor region): {len(hi)}  cells "
          f"{['0x%02X'%c for c in hi]}")
    print("\n  READ: the cells that MOVE are the ones the edited parameter controls;\n"
          "  cells that stay fixed are controlled by the other parameters.  Compare a\n"
          "  gain edit (NPARAM=2) with an FC edit (NPARAM=0) to separate the roles.")

    # Per-band centre-frequency readout from the FLAT dump, treating each band's
    # 6-cell C-RAM group [0x00+6b .. 0x05+6b] as near-RBJ, with the +~2.0 cell the
    # -2cos(w0) frequency term.  Shows whether the 5 bands are SPREAD (real EQ) or
    # clustered (the earlier 13.5 kHz artefact from the cursor-walk operand cells).
    import math
    print("\n  per-band centre freq from the FLAT dump (2cos term = the ~+2.0 cell "
          "in each 6-cell group):")
    for b in range(5):
        freq_cell = 0x00 + 6 * b + 3                 # the FC edit (NPARAM=0) moves this cell
        if freq_cell not in flat:
            continue
        two_cos = q22(flat[freq_cell])               # near-RBJ +2cos(w0) term
        c = max(-1.0, min(1.0, two_cos / 2.0))
        w0 = math.acos(c)
        print(f"    band {b}: 2cos={two_cos:+.4f} -> w0={w0:.3f} rad -> "
              f"f_norm={w0/math.pi:.3f}  (~{w0/math.pi*22050:5.0f} Hz at fs=44.1k)")
    print("  (monotone spread across bands => a real multi-band EQ; the ~13.5 kHz\n"
          "   cluster came from mis-reading the cursor-walk D-RAM operands as coeffs.)")

if __name__ == "__main__":
    main()
