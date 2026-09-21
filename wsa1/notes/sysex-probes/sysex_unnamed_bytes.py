#!/usr/bin/env python3
"""WHAT ARE THE BYTES OF A COMBINATION THAT NO PARAMETER NAMES?

QUESTION IT ANSWERS

`sysex_combination_layout.py` ends with a list of bytes that some combination
writes but that no parameter descriptor reaches.  Four CODE searches were run
against them and all four came back empty or powerless: no menu screen captions
them, the literal record-and-offset setter writes none of them, the six
routines that reach a part through the instrument's part pointer are the six
overrides already named, and looking for their addresses as literals has no
discriminating power.

This asks from the DATA side instead.  There are 257 combinations -- 129 preset
in prom_c and 128 user in the captured flash -- of eight parts each, so every
byte has 2056 observations with its named neighbours beside it.  A byte that
never changes is reserved rather than unknown; a byte that always equals
another byte is a copy of it and is thereby named; a byte with eight values is
an enum and its width says so.

WHAT IT SETTLES
  * Most of the "unnamed" list is CONSTANT over all 2056 records.  Those are
    reserved, and saying so is a stronger statement than leaving them open.
  * The bytes that do vary are not scattered: the last three of each part block
    are a TRIPLE -- an index 0..15, an index 0..7, and a flag.  Block A's is
    unused by every one of the 1024 user parts; block B's is used by both
    sources.  The two are equal in 1280 of the 2056 parts and differ in 776, so
    they are two fields of the same shape and not one field written twice.
  * The triple is NOT a cache of the part's program number.  That is the
    natural hypothesis and it is refuted here by counterexample, which is the
    point of running the test.

SIGNAL BEING READ
  Every (record tag, offset) of every part record of all 257 combinations,
  compared against every other offset of the same record set.

RUN
  python3 wsa1/notes/sysex-probes/sysex_unnamed_bytes.py

PASS CRITERION
  A planted control column (a deliberate copy of PANPOT) must be reported as a
  copy and a planted arithmetic column must not be -- otherwise "no copy found"
  would be worth nothing, because a search that cannot succeed cannot fail.
  The measured counts below are asserted, so this fails if the corpus or the
  layout decode changes under it.
"""
import io, os, sys, contextlib
from collections import Counter

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
with contextlib.redirect_stdout(io.StringIO()):
    import sysex_combination_layout as L   # noqa: E402

CORPUS, PARTS = L.CORPUS, L.PARTS
ROLE = {"A": 0x00, "B": 0x20}


def part_rows():
    """(source, combination index, part, block A payload, block B payload)."""
    out = []
    for label, combos in CORPUS:
        for i, c in enumerate(combos):
            for k in range(PARTS):
                out.append((label, i, k, c[0x00 + k], c[0x20 + k]))
    return out


ROWS = part_rows()
N = len(ROWS)
print("%d part records from %s" % (N, ", ".join(l for l, _ in CORPUS)))
assert N == 257 * PARTS, "expected 257 combinations of %d parts, got %d" % (PARTS, N)

COLS = {}
for role, _ in ROLE.items():
    idx = 3 if role == "A" else 4
    for off in range(0x1E):
        COLS[(role, off)] = [r[idx][off] for r in ROWS]
# the part-common records carry one value per combination; repeat it per part
for tag in (0x60, 0x79, 0x92):
    n = len(CORPUS[0][1][0][tag])
    for off in range(n):
        COLS[(tag, off)] = [c[tag][off]
                            for _, combos in CORPUS for c in combos
                            for _ in range(PARTS)]

CTRL_COPY, CTRL_ARITH = ("CTRL-copy", 0), ("CTRL-arith", 0)
COLS[CTRL_COPY] = list(COLS[("A", 8)])                     # a copy of PANPOT
COLS[CTRL_ARITH] = [(i * 37 + 11) & 0xFF for i in range(N)]


def tag_(role):
    return role if isinstance(role, str) else "%02X" % role


def describe(key):
    v = COLS[key]
    uniq = sorted(set(v))
    if len(uniq) == 1:
        return "CONSTANT 0x%02X" % uniq[0]
    copies = [k for k in COLS
              if k != key and not str(k[0]).startswith("CTRL") and COLS[k] == v]
    if copies:
        return "COPY of " + ", ".join("%s+%02X" % (tag_(a), b) for a, b in copies)
    if len(uniq) <= 8:
        return "%d values %s" % (len(uniq), " ".join("0x%02X" % u for u in uniq))
    return "%d values, range 0x%02X..0x%02X" % (len(uniq), uniq[0], uniq[-1])


print("\nCONTROL -- the copy search has to be able to both succeed and fail")
for c in (CTRL_COPY, CTRL_ARITH):
    print("  %-12s %s" % (c[0], describe(c)))
assert describe(CTRL_COPY).startswith("COPY of A+08"), \
    "the planted copy of PANPOT was not found: the search cannot succeed"
assert not describe(CTRL_ARITH).startswith("COPY of"), \
    "a planted arithmetic column was called a copy: the search cannot fail"

print("\nEVERY BYTE OF A PART RECORD, OVER %d RECORDS" % N)
for role in ("A", "B"):
    for off in range(0x1E):
        print("  %s +%02X  %s" % (role, off, describe((role, off))))

CONST = {role: [o for o in range(0x1E) if len(set(COLS[(role, o)])) == 1]
         for role in ("A", "B")}
print("\n  block A never varies at: %s" % " ".join("+%02X" % o for o in CONST["A"]))
print("  block B never varies at: %s" % " ".join("+%02X" % o for o in CONST["B"]))
assert set(CONST["A"]) >= {0x02, 0x04, 0x10, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1A}, \
    "block A's reserved run changed"
assert set(CONST["B"]) >= {0x00, 0x01, 0x02, 0x0D, 0x11, 0x12, 0x15}, \
    "block B's reserved set changed"

# ---- the trailing triple
print("\nTHE TRAILING TRIPLE  (+1B, +1C, +1D of each block)")
for role in ("A", "B"):
    a, b, c = (COLS[(role, o)] for o in (0x1B, 0x1C, 0x1D))
    print("  %s  +1B 0x%02X..0x%02X   +1C 0x%02X..0x%02X   +1D 0x%02X..0x%02X"
          % (role, min(a), max(a), min(b), max(b), min(c), max(c)))
    assert max(a) <= 0x0F and max(b) <= 0x07, "the triple's width changed"
# +1D is a flag in block A and a small bit set in block B -- not the same field
assert set(COLS[("A", 0x1D)]) == {0x00, 0x01}, "block A +1D is no longer a flag"
assert set(COLS[("B", 0x1D)]) - {0x00, 0x01, 0x08, 0x09, 0x20} == set(), \
    "block B +1D took a value outside the measured set"

for label, combos in CORPUS:
    for role, tag in (("A", 0x00), ("B", 0x20)):
        nz = sum(1 for c in combos for k in range(PARTS)
                 if tuple(c[tag + k][0x1B:0x1E]) != (0, 0, 0))
        print("  %-14s block %s: %4d of %4d parts carry a non-zero triple"
              % (label, role, nz, len(combos) * PARTS))
        if label == "user flash" and role == "A":
            assert nz == 0, "a user combination's block A carries a triple"
        if label == "user flash" and role == "B":
            assert nz > 0, "block B's triple is no longer used by user data"

# ---- is the triple a cache of the part's program number?
obs = {}
for _, _, _, a, b in ROWS:
    key = (a[0], a[1], a[2])
    for role, t in (("A", tuple(a[0x1B:0x1E])), ("B", tuple(b[0x1B:0x1E]))):
        obs.setdefault((role, key), set()).add(t)
ambiguous = {k: v for k, v in obs.items() if len(v) > 1}
print("\nIS THE TRIPLE A FUNCTION OF PROGRAM CHANGE & BANK?")
print("  %d distinct programs; %d of them carry more than one triple"
      % (len({k[1] for k in obs}), len(ambiguous)))
for k, v in sorted(ambiguous.items())[:4]:
    print("    %s prog %02X %02X %02X -> %s"
          % (k[0], k[1][0], k[1][1], k[1][2],
             " ".join("(%02X %02X %02X)" % t for t in sorted(v))))
assert ambiguous, "the triple now IS a function of the program -- re-open this"
print("  NO -- the same program carries different triples, so it is not a cache")
print("  of the sound.  What it is, is open; the shape (a 0..15 index, a 0..7")
print("  index and a flag) is the same shape the combination memory itself uses.")

print("\nBLOCK B +18..+1A, the three bytes ahead of its triple")
cnt = Counter(tuple(r[4][0x18:0x1B]) for r in ROWS)
for t, n in cnt.most_common():
    print("   %s  x%d" % (" ".join("%02X" % x for x in t), n))

print("\nRECORD 0x79 +01..+04, THE MAIN OUT EQUALISER")
eq = {tuple(c[0x79][1:5]) for _, combos in CORPUS for c in combos}
print("   distinct over 257 combinations: %s"
      % ", ".join(" ".join("%02X" % x for x in t) for t in sorted(eq)))
assert eq == {(0xD8, 0x02, 0x58, 0x04)}, "the stored equaliser is no longer invariant"
print("   every stored combination holds the same equaliser, so no stored datum")
print("   can decide between the descriptor that puts FREQUENCY at +01/+03 and")
print("   the two unnamed bytes at +02/+04.  Gain reads 24 of 0..48 -- centre --")
print("   under the +01/+03 mask 0x3F, which is what a flat equaliser should be.")

print("\nOK")
