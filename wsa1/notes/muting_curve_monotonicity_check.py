#!/usr/bin/env python3
"""Is the MUTING cutoff table monotone, and in which sense?

QUESTION THIS ANSWERS
    The source once described `Curve_Muting_Cutoff_Q16_128` as "rising from
    -510 to +28591". Read as s16 it does not rise: it falls to -31655 and jumps.
    A later pass corrected that to "under fold the table is strictly monotone".

    That is right in direction and wrong in one word, which this script pins.
    The table is NON-DECREASING under fold(), not strictly increasing: it has
    plateaus, so it is not invertible there. Anyone fitting the curve, or
    inverting it to recover a cutoff index from a coefficient, needs the
    difference.

WHY IT IS A COMMITTED SCRIPT
    Both statements about this table -- the original and its correction -- were
    written from reading, not measuring, and each was wrong in a different way.
    The measurement is three lines; it should not have to be redone by eye a
    third time.

RUN
    python3 wsa1/notes/muting_curve_monotonicity_check.py
    python3 wsa1/notes/muting_curve_monotonicity_check.py --selftest
"""
import pathlib
import struct
import sys

ROM = pathlib.Path(__file__).resolve().parents[1] / "original_ROMs/wsa1_prom_c.ic28"
ADDR, ROM_BASE, N = 0xFE04C9, 0xF80000, 128


def fold(x):
    x &= 0xFFFF
    return 0x8000 - (x & 0x7FFF) if (x & 0x8000) else x + 0x8000


def entries():
    rom = ROM.read_bytes()
    off = ADDR - ROM_BASE
    return [struct.unpack_from("<h", rom, off + 2 * k)[0] for k in range(N)]


def census(seq):
    dec = sum(1 for a, b in zip(seq, seq[1:]) if b < a)
    flat = sum(1 for a, b in zip(seq, seq[1:]) if b == a)
    return dec, flat


def main(selftest=False):
    v = entries()
    f = [fold(x) for x in v]
    fails = []

    for name, seq in (("as s16", v), ("under fold()", f)):
        dec, flat = census(seq)
        print(f"  {name:<14} decreasing pairs {dec:>3}   equal pairs {flat:>3}   "
              f"range {min(seq)} .. {max(seq)}")

    dec_s16, _ = census(v)
    dec_f, flat_f = census(f)
    print()
    print(f"  as s16 the table is NOT non-decreasing            "
          f"({dec_s16} violations)")
    print(f"  under fold() it IS non-decreasing                 "
          f"({dec_f} violations)")
    print(f"  but it is NOT strictly increasing: {flat_f} adjacent pairs are equal,")
    print(f"    so the curve has plateaus and is not invertible there.")

    if dec_s16 == 0:
        fails.append("s16 unexpectedly non-decreasing")
    if dec_f != 0:
        fails.append(f"fold() has {dec_f} decreasing pairs")
    if flat_f == 0:
        fails.append("no plateaus -- 'strictly monotone' would be right after all")

    if selftest:
        print("\n  --selftest: the check must reject a curve that IS strictly rising")
        strict = list(range(N))
        d, fl = census(strict)
        ok = (d == 0 and fl == 0)
        print(f"    a strictly rising control gives {d} decreasing, {fl} equal   "
              f"{'ok -- distinguishable' if ok else 'WRONG'}")
        if not ok:
            fails.append("selftest")

    if fails:
        print(f"\nFAIL: {fails}")
        return 1
    print("\nPASS: non-decreasing under fold(), with plateaus -- monotone in the "
          "weak sense only.")
    return 0


if __name__ == "__main__":
    sys.exit(main("--selftest" in sys.argv))
