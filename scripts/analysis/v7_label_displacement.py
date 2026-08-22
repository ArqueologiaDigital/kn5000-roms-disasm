#!/usr/bin/env python3
"""Which v7 labels sit on the WRONG routine, and by how much -- decided by bytes.

QUESTION ANSWERED
-----------------
153 v7 names are known to resolve to a different routine than their v9/v10
namesake, 152 of them off by exactly 0x41A. That figure came from a pointer-table
cross-check which can no longer be re-run in place (the blobs it read are now
`.long` lines -- spec anti-pattern 14). This re-derives it from first principles,
using only the ROMs and the per-link symbol files, and it will keep working.

METHOD -- byte evidence, never names
    For each name defined in BOTH the v7 and v9 links:
      * take a WINDOW of v9's bytes at v9's address for that name;
      * score it against v7's bytes at v7's address for the same name;
      * if that score is poor, slide a search over v7 near its address looking
        for a window that scores well.
      * report a DISPLACEMENT only when the far site scores well AND the
        label's own site scores badly -- both halves are required, because a
        routine can legitimately differ between revisions.

⚠ WHY BYTES AND NOT NAMES: a v7/v9 name pair is not guaranteed to be the same
routine (that is the very defect under test), so name identity is the QUESTION,
not the evidence. Scoring is on raw bytes, and a call/jump operand differing
between revisions is expected -- which is why the threshold is a fraction, not
equality.

⚠ WHAT THIS DOES NOT DO: it does not move anything. Relocating a label changes
NO BYTES, so `make all` reports 9/9 whether the label is right or wrong (spec
anti-patterns 12 and 13). The gate cannot review this class of edit, so each
move needs a human reading this evidence.

Run:  python3 scripts/analysis/v7_label_displacement.py [--limit N] [--window N]
"""
import collections, os, subprocess, sys

REPO = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
BASE = 0xE00000
WINDOW = int(sys.argv[sys.argv.index("--window") + 1]) if "--window" in sys.argv else 24
LIMIT = int(sys.argv[sys.argv.index("--limit") + 1]) if "--limit" in sys.argv else 0
SEARCH = 0x800          # how far around the label to look for the real routine
GOOD, BAD = 0.85, 0.55  # score at the true site / at the mislabelled site


def syms(path):
    d = {}
    for line in open(os.path.join(REPO, "symbols", path), encoding="latin1"):
        if line.startswith("#") or not line.strip():
            continue
        f = line.split()
        if len(f) == 2:
            try:
                d[f[0]] = int(f[1], 16)
            except ValueError:
                pass
    return d


def score(a, b):
    return sum(1 for x, y in zip(a, b) if x == y) / max(len(a), 1)


def main():
    rom7 = open(os.path.join(REPO, "original_ROMs", "kn5000_v7_program.rom"), "rb").read()
    rom9 = open(os.path.join(REPO, "original_ROMs", "kn5000_v9_program.rom"), "rb").read()
    s7, s9 = syms("maincpu_v7_symbols_reference.txt"), syms("maincpu_v9_symbols_reference.txt")
    common = sorted(set(s7) & set(s9))
    hits, checked, deltas = [], 0, collections.Counter()
    for n in common:
        a7, a9 = s7[n], s9[n]
        o7, o9 = a7 - BASE, a9 - BASE
        if not (0 <= o9 < len(rom9) - WINDOW and 0 <= o7 < len(rom7) - WINDOW):
            continue
        checked += 1
        ref = rom9[o9:o9 + WINDOW]
        here = score(rom7[o7:o7 + WINDOW], ref)
        if here >= BAD:
            continue                      # the label is where the routine is
        best, bd = 0.0, None
        lo, hi = max(0, o7 - SEARCH), min(len(rom7) - WINDOW, o7 + SEARCH)
        for o in range(lo, hi):
            sc = score(rom7[o:o + WINDOW], ref)
            if sc > best:
                best, bd = sc, o - o7
        if best >= GOOD and bd:
            hits.append((n, a7, a7 + bd, bd, here, best))
            deltas[bd] += 1
        if LIMIT and len(hits) >= LIMIT:
            break

    print(f"  names defined in both v7 and v9 : {len(common):,}")
    print(f"  comparable (both in range)      : {checked:,}")
    print(f"  LABEL SITS OFF ITS ROUTINE      : {len(hits):,}"
          f"   (score < {BAD} at the label, >= {GOOD} elsewhere within +/-0x{SEARCH:X})")
    if deltas:
        print("\n  displacement histogram (bytes, most common first):")
        for d, c in deltas.most_common(8):
            print(f"    {d:+#8x}  {c:>4} name(s)")
    print(f"\n  {'name':46}{'label at':>10}{'routine at':>12}{'delta':>9}"
          f"{'@label':>8}{'@routine':>10}")
    for n, a7, real, d, here, best in sorted(hits, key=lambda r: (r[3], r[0]))[:25]:
        print(f"  {n:46}{a7:#010x}{real:#12x}{d:+9d}{here:8.2f}{best:10.2f}")
    print("\n  ⚠ Nothing was moved. Relocating a label changes no bytes, so the byte-match")
    print("     gate cannot review it -- read the evidence per name before acting.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
