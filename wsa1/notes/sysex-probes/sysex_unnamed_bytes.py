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
  * Most of the "unnamed" list is CONSTANT over all 3080 records, across THREE
    corpora that were produced independently of one another -- the presets in
    the program, a user's flash dump, and the combination area of a native
    disk file.  Those bytes are reserved, and saying so is a stronger
    statement than leaving them open.  A fourth corpus would be worth adding
    for the same reason: a constancy claim is worth what its corpus is worth.
  * The bytes that do vary are not scattered: the last three of each part block
    are a TRIPLE -- an index 0..15, an index 0..7, and a flag.  Block A's is
    unused by every one of the 1024 user parts; block B's is used by both
    sources.  The two are equal in 1280 of the 2056 parts and differ in 776, so
    they are two fields of the same shape and not one field written twice.
  * The triple is NOT a cache of the part's program number.  That is the
    natural hypothesis and it is refuted here by counterexample, which is the
    point of running the test.
  * The MAIN OUT EQUALISER is no longer invariant.  The disk corpus holds a
    different setting from the other two, and the two differ at +01 and +02
    only.  That is what places the two frequency fields -- see the end of the
    output.

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
import hashlib, io, os, sys, zipfile, contextlib
from collections import Counter

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
with contextlib.redirect_stdout(io.StringIO()):
    import sysex_combination_layout as L   # noqa: E402

CORPUS, PARTS = list(L.CORPUS), L.PARTS

# A THIRD corpus, independent of both: the combination area of a native disk
# file.  It matters because "this byte never varies" is only worth what its
# corpus is worth, and this one was produced by a different user on different
# hardware from the flash capture.
DISK_ZIP = "/home/fsanches/compartilhado/KN7000/WSA1R_files/GJS1.zip"
DISK_SHA = "c098228819824593d0f426eb053625fa70ac582c3fe29727564544d4d9979524"
DISK_MEMBER, DISK_BASE, DISK_N = "GJS1/01220497.CMB", 0x300, 128
if os.path.exists(DISK_ZIP):
    assert hashlib.sha256(open(DISK_ZIP, "rb").read()).hexdigest() == DISK_SHA, \
        "GJS1.zip is not the archive checked here"
    with zipfile.ZipFile(DISK_ZIP) as z:
        _d = z.read(DISK_MEMBER)
    CORPUS.append(("disk .CMB",
                   [L.combination(_d, DISK_BASE + i * L.COMB) for i in range(DISK_N)]))
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
EXPECT_N = (257 + DISK_N) * PARTS if len(CORPUS) == 3 else 257 * PARTS
assert N == EXPECT_N, "expected %d part records, got %d" % (EXPECT_N, N)

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
        if label == "disk .CMB":
            assert nz == 0, "the disk corpus now uses the triple"

# ---- what the triple IS.  Its shape is a 7-bit number split four bits and
# three -- 0..15 and 0..7 -- and the disk's re-map files use exactly that split:
# a re-map is 16 GROUPS of 8, 128 entries of (number, source).  So test the
# triple as a second PROGRAM CHANGE & BANK for the same part.
TRIPLES = []
for _, _, _, a_, b_ in ROWS:
    for r in (a_, b_):
        t = (r[0x1B], r[0x1C], r[0x1D])
        if t != (0, 0, 0):
            TRIPLES.append((t, a_[0], a_[1]))

both = num_only = bank_only = neither = 0
for t, prog, bank in TRIPLES:
    n, bk = (t[0] * 8 + t[1]) == prog, t[2] == bank
    if n and bk:
        both += 1
    elif n:
        num_only += 1
    elif bk:
        bank_only += 1
    else:
        neither += 1
print("\nWHAT THE TRAILING TRIPLE IS")
print("  %d parts carry a non-zero triple.  Reading +1B and +1C as one 7-bit"
      % len(TRIPLES))
print("  number, +1B * 8 + +1C, and +1D as a bank:")
print("    number AND bank both equal the part's own PROGRAM CHANGE & BANK : %d (%.0f%%)"
      % (both, 100.0 * both / len(TRIPLES)))
print("    the number matches but the bank does not                        : %d" % num_only)
print("    the bank matches but the number does not                        : %d" % bank_only)
print("    neither                                                         : %d" % neither)

# the null: the same test against a different part's program and bank
shifted = [TRIPLES[(i + 1) % len(TRIPLES)] for i in range(len(TRIPLES))]
ctrl = sum(1 for (t, _, _), (_, p2, b2) in zip(TRIPLES, shifted)
           if (t[0] * 8 + t[1]) == p2 and t[2] == b2)
print("  control -- the same test against the NEXT part's program and bank: %d (%.1f%%)"
      % (ctrl, 100.0 * ctrl / len(TRIPLES)))

assert num_only == 0, \
    "the number now matches without the bank matching, which breaks the reading"
assert both > 6 * ctrl, "the agreement is no longer well above its control"
print("  The number NEVER matches without the bank matching too, and the pair")
print("  agrees %.1f times as often as the control.  So the triple is a second"
      % (float(both) / ctrl))
print("  PROGRAM CHANGE & BANK for the part: a 7-bit number split four bits and")
print("  three, plus a bank drawn from the same values the part's own bank uses.")
print("  It equals the part's own in a third of cases and differs in the rest --")
print("  which is what the far side of a re-map looks like, and it is why the")
print("  triple is not a function of the program: an indirection sits between.")

print("\nBLOCK B +18..+1A, the three bytes ahead of its triple")
cnt = Counter(tuple(r[4][0x18:0x1B]) for r in ROWS)
for t, n in cnt.most_common():
    print("   %s  x%d" % (" ".join("%02X" % x for x in t), n))

print("\nRECORD 0x79 +01..+04, THE MAIN OUT EQUALISER")
for label, combos in CORPUS:
    eq = sorted({tuple(c[0x79][1:5]) for c in combos})
    print("   %-14s %s" % (label, ", ".join(" ".join("%02X" % x for x in t) for t in eq)))

# The guide's own packing note says EQ Fc is 5 bits and EQ G is 6 bits.  Eleven
# bits do not fit in a byte, which is why no single-byte descriptor could ever
# place the frequency -- a band is a 16-bit field spanning two bytes.  The
# declared ranges give the test: GAIN 0..48, LOW Fc 0..17, HIGH Fc 17..26,
# those two being sub-ranges of one 27-entry frequency table (they overlap at
# 17).  Only one bit assignment puts every stored value inside them.
DECLARED = {"GAIN": (0, 48), "LOW": (0, 17), "HIGH": (17, 26)}
BANDS = [(c[0x79][1], c[0x79][2], "LOW") for _, cs in CORPUS for c in cs] + \
        [(c[0x79][3], c[0x79][4], "HIGH") for _, cs in CORPUS for c in cs]


def fits(order, gpos, fpos):
    for b0, b1, nm in BANDS:
        v = (b0 | (b1 << 8)) if order == "LE" else ((b0 << 8) | b1)
        g, fc = (v >> gpos) & 0x3F, (v >> fpos) & 0x1F
        lo, hi = DECLARED[nm]
        if not (DECLARED["GAIN"][0] <= g <= DECLARED["GAIN"][1] and lo <= fc <= hi):
            return False
    return True


# Search the WHOLE space rather than a few hand-picked candidates: every
# placement of a contiguous 6-bit gain and a contiguous 5-bit index inside the
# two bytes, both byte orders.  A single survivor is a much stronger result
# than beating three chosen alternatives.
OK_LAYOUTS = [(o, g, f)
              for o in ("LE", "BE")
              for g in range(11)
              for f in range(12)
              if (f + 5 <= g or g + 6 <= f) and fits(o, g, f)]
print("\n   %d band observations; assignments of a 6-bit gain and 5-bit index"
      % len(BANDS))
print("   that put EVERY one inside its declared range: %d" % len(OK_LAYOUTS))
for o, g, f in OK_LAYOUTS:
    print("     %s, gain at bit %d, index at bit %d" % (o, g, f))
assert OK_LAYOUTS == [("LE", 0, 6)], \
    "the equaliser bit assignment is no longer uniquely determined"
print("   -> a band is a 16-bit LITTLE-ENDIAN word: GAIN in bits 0-5, frequency")
print("      INDEX in bits 6-10, indexing the guide's 27-entry PEQ Fc table.")
print("      LOW band at +01/+02 (dump 1002B3), HIGH at +03/+04 (dump 1002B5).")
print("      The index takes TWO bits from the low byte and THREE from the high.")
print("   !! The guide's packed-field note for its pre/post equaliser format says")
print("      the split is three bits in the first byte and two in the second.")
print("      For MAIN OUT EQUALIZER that is the other way round, and no such")
print("      layout fits: it is in the search space above and it fails.")
assert not fits("LE", 0, 3) and not fits("BE", 0, 6), "a rejected layout now fits"

settings = Counter()
for _, combos in CORPUS:
    for c in combos:
        r = c[0x79]
        lo, hi = r[1] | (r[2] << 8), r[3] | (r[4] << 8)
        settings[(lo & 0x3F, (lo >> 6) & 0x1F, hi & 0x3F, (hi >> 6) & 0x1F)] += 1
print("\n   the settings actually stored:")
for (lg, lf, hg, hf), n in settings.most_common():
    print("     LOW gain %2d Fc %2d | HIGH gain %2d Fc %2d   x%d" % (lg, lf, hg, hf, n))
assert set(settings) == {(24, 11, 24, 17), (18, 7, 24, 17)}, \
    "the stored equaliser settings have changed"
print("   both gains read 24 of 0..48 -- centre -- in the factory setting, and the")
print("   one instrument that moved its low band moved gain and frequency together.")

print("\nOK")
