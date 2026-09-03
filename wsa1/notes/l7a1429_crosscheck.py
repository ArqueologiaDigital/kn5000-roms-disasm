#!/usr/bin/env python3
"""Do the L7A1429 findings agree with each other, and does the key claim hold?

QUESTION THIS ANSWERS
    Three lanes documented the acoustic-modelling LSI from different evidence --
    write sequencing, curve-table numerics, and topology. Each was gated on its
    own terms. Nothing checked that they AGREE, and the HLE guide is built on
    all of them at once.

    This is the integration check: every register block should appear in both
    the sequencing and the curve document, or its absence should be explained;
    and the curve lane's headline unit derivation should reproduce from first
    principles rather than from its own code.

WHY THE ARITHMETIC CHECK IS HERE
    The curve lane's central claim is that the filter-cutoff table's index is a
    SEMITONE, established by forcing the fitted slope to 1/12 and solving for
    the index-0 frequency from the ROM alone. That gives 65.4201 Hz against a
    true MIDI 36 of 65.4064 Hz. Re-deriving the discrepancy independently -- in
    cents, from the equal-tempered definition -- is a one-line check that the
    claim is arithmetically what it says it is, and it is worth having beside
    the claim rather than in a transcript.

    ⚠ It checks CONSISTENCY, not truth. It cannot tell you the table really is a
    cutoff; the curve lane's residuals and nulls do that. A green run here means
    the documents do not contradict each other.

RUN
    python3 wsa1/notes/l7a1429_crosscheck.py
    python3 wsa1/notes/l7a1429_crosscheck.py --selftest
"""
import math
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
SEQ = HERE / "FINDINGS-l7a1429-write-sequencing.md"
CUR = HERE / "FINDINGS-l7a1429-curve-tables.md"

# Blocks with a documented reason to be absent from the curve document.
EXPECTED_ABSENT = {
    "0x0800": "written with the literal 0x1100 at init; no curve in its path",
}

BLOCKS = ["0x0040", "0x0080", "0x00C0", "0x0100", "0x0140", "0x0180", "0x01C0",
          "0x0200", "0x0240", "0x0280", "0x02C0", "0x0300", "0x0340", "0x0380",
          "0x03C0", "0x0400", "0x0440", "0x0480", "0x0800"]

XTAL_HZ = 33_868_800      # IC4, from the tree's hardware findings
XTAL_DIV = 768            # 768 * 44100
ROM_F0_HZ = 65.4201       # curve lane's index-0 frequency, solved from the ROM
TICK_HZ = 40.69           # write-sequencing lane's measured refresh


def midi_hz(n):
    return 440.0 * 2 ** ((n - 69) / 12)


def cents(a, b):
    return 1200 * math.log2(a / b)


def main(selftest=False):
    fails = []
    seq, cur = SEQ.read_text(), CUR.read_text()

    print("  register blocks named in both documents")
    for b in BLOCKS:
        in_seq, in_cur = b in seq, b in cur
        if in_seq and in_cur:
            verdict = "ok"
        elif in_seq and b in EXPECTED_ABSENT:
            verdict = f"absent from curves -- {EXPECTED_ABSENT[b]}"
        elif not in_seq and not in_cur:
            verdict = "IN NEITHER -- is it a real block?"
            fails.append(b)
        else:
            verdict = ("MISSING from the curve document -- unexplained"
                       if in_seq else
                       "MISSING from the sequencing document -- is it written?")
            fails.append(b)
        print(f"    {b}   seq={'y' if in_seq else 'n'} "
              f"cur={'y' if in_cur else 'n'}   {verdict}")

    print("\n  the sample rate, from the crystal")
    fs = XTAL_HZ / XTAL_DIV
    ok = abs(fs - 44100) < 1e-9
    fails += [] if ok else ["fs"]
    print(f"    {XTAL_HZ/1e6:.4f} MHz / {XTAL_DIV} = {fs:.1f} Hz"
          f"   {'ok -- exactly 44100' if ok else 'NOT 44100'}")

    print("\n  the semitone claim, re-derived from equal temperament")
    true36 = midi_hz(36)
    err = cents(ROM_F0_HZ, true36)
    ok = abs(err) < 1.63          # the lane's own reported scatter
    fails += [] if ok else ["semitone"]
    print(f"    MIDI 36 = {true36:.4f} Hz;  ROM index 0 = {ROM_F0_HZ} Hz")
    print(f"    discrepancy {err:+.2f} cents, against 1.63 cents of fit scatter"
          f"   {'ok -- inside the scatter' if ok else 'OUTSIDE the scatter'}")

    print("\n  the refresh period")
    print(f"    {TICK_HZ} Hz -> {1000/TICK_HZ:.2f} ms per refresh")

    if selftest:
        print("\n  --selftest: the checks must reject a wrong value")
        bad = cents(midi_hz(37), true36)          # a whole semitone out
        rejected = abs(bad) >= 1.63
        print(f"    an index-0 one semitone high is {bad:+.0f} cents   "
              f"{'ok -- rejected' if rejected else 'ACCEPTED -- check is blind'}")
        if not rejected:
            fails.append("selftest")
        blind = abs(XTAL_HZ / 512 - 44100) < 1e-9
        print(f"    the wrong divider (512) gives {XTAL_HZ/512:.1f} Hz   "
              f"{'ok -- rejected' if not blind else 'ACCEPTED -- check is blind'}")
        if blind:
            fails.append("selftest-div")

    if fails:
        print(f"\nFAIL: {len(fails)} inconsistency(ies): {fails}")
        return 1
    print("\nPASS: the documents agree, and the unit derivation reproduces.")
    return 0


if __name__ == "__main__":
    sys.exit(main("--selftest" in sys.argv))
