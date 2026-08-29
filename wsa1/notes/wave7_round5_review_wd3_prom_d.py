#!/usr/bin/env python3
"""REVIEW-WD3 round 5 -- ARE prom_d's ROUND-5 NAMES CARRIED BY THEIR EVIDENCE?

QUESTION IT ANSWERS
    notes/prom_d_understanding_round5.py renamed 81 labels in prom_d and added
    272 header blocks.  This script does NOT import it.  It re-reads the four
    ROM images and prom_c's assembly and asks whether each claim is true, so a
    claim and its check cannot fail together.

    Every number quoted in the REVIEW-WD3 report comes from here.

WHAT IT CHECKS
    R1  the round-5 rename is 81 labels, 1:1, and the label COUNT is unchanged
        -- so `labels_added: 0` is true and the lane converted nothing.
    R2  the header/evidence gain is NEW PROSE, not the round-3 whitespace
        artefact: comment lines added vs deleted, and blank lines added vs
        removed.
    R3  the six DescCurve_Step* suffixes are re-derived from the ROM bytes by an
        independently written run-length counter, including the 4-vs-2 tie.
    R4  the curve-bank Evidence lines: LE32 pointer counts and first-object
        addresses, counted over the raw image.
    R5  ★ the load-bearing claim of the round -- field +0x0B of a +0x3C record
        is a 6-bit index into that array -- re-measured, WITH ITS TWO NULLS.
    R6  ★ THE MORPHEME TEST that caught round 3's "Home": every significant word
        of every new name, counted over all four images.
    R7  ★ THE DEFECT THIS REVIEW FOUND.  The three wave-select banners say "No
        column is printable in every record."  That is FALSE: 3, 7 and 7 columns
        respectively are.  The refusal it supports is unaffected -- the longest
        run of CONSECUTIVE always-printable columns is 1, far short of the 13 a
        name field needs, and that is what the lane's own Q1a actually tests.
    R8  the ten program-map rows, reconstructed from the directory offset table
        rather than from the generated comments.
    R9  the base-address search: prom_c operand literals in prom_d's window.

HOW TO RUN
    python3 notes/wave7_round5_review_wd3_prom_d.py
    Exit status is non-zero if any check fails.  R7 is EXPECTED to fail while
    the "No column" sentence stands; it is the finding.
"""
import itertools, os, re, struct, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IMG = {k: open(os.path.join(ROOT, "original_ROMs", v), "rb").read() for k, v in
       (("a", "wsa1_prom_a.ic12"), ("b", "wsa1_prom_b.ic13"),
        ("c", "wsa1_prom_c.ic28"), ("d", "wsa1_prom_d.bin"))}
D = IMG["d"]
SRC = open(os.path.join(ROOT, "prom_d", "wsa1_prom_d.s")).read()
FAILED = []
RAN = []


def check(name, ok, detail=""):
    print("  %s  %-72s %s" % ("PASS" if ok else "FAIL", name, detail))
    RAN.append(name)
    if not ok:
        FAILED.append(name)


def head_of(path):
    return subprocess.run(["git", "show", "HEAD:" + path], cwd=ROOT,
                          capture_output=True, text=True).stdout


# --- R1 ------------------------------------------------------------------
print("\n=== R1.  the rename is 81 labels and nothing was converted ===\n")
LAB = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):", re.M)
old = LAB.findall(head_of("prom_d/wsa1_prom_d.s"))
new = LAB.findall(SRC)
ren = [(x, y) for x, y in zip(old, new) if x != y]
check("R1a  label COUNT unchanged, so labels_added: 0 is true",
      len(old) == len(new) == 3665, "%d before, %d after" % (len(old), len(new)))
check("R1b  positionally renamed labels", len(ren) == 81, "%d renames" % len(ren))
check("R1c  and the LAST rename in address order is a DescCurve",
      ren[-1] == ("ToneDB_DescCurve_5", "ToneDB_DescCurve_Step1"), "%s -> %s" % ren[-1])

# --- R2 ------------------------------------------------------------------
print("\n=== R2.  is the +272 header gain new prose or removed whitespace? ===\n")
diff = subprocess.run(["git", "diff", "-U0", "prom_d/wsa1_prom_d.s"], cwd=ROOT,
                      capture_output=True, text=True).stdout.split("\n")
add_c = sum(1 for l in diff if l.startswith("+;"))
del_c = sum(1 for l in diff if l.startswith("-;"))
add_b = sum(1 for l in diff if re.match(r"^\+\s*$", l))
del_b = sum(1 for l in diff if re.match(r"^-\s*$", l))
check("R2a  comment lines added exceed deleted", add_c > del_c,
      "+%d, -%d comment lines" % (add_c, del_c))
check("R2b  NO blank lines were removed, so the round-3 artefact is excluded",
      del_b == 0, "%d blank lines removed, %d added" % (del_b, add_b))

# --- R3 ------------------------------------------------------------------
print("\n=== R3.  the six curve suffixes, re-derived from the ROM ===\n")
CURVES = [(0x22A3B, "Step12"), (0x22ABB, "Step6"), (0x22B3B, "Step4"),
          (0x22BBB, "Step3"), (0x22C3B, "Step4And2"), (0x22CBB, "Step1")]


def derive(start):
    """The naming rule, written here independently: strict plurality of run
    length, or `<hi>And<lo>` on a two-way tie."""
    v = list(D[start:start + 128])
    runs = [len(list(g)) for _, g in itertools.groupby(v)]
    hist = {}
    for r in runs:
        hist[r] = hist.get(r, 0) + 1
    top = sorted(hist.items(), key=lambda t: (-t[1], -t[0]))
    if len(top) > 1 and top[0][1] == top[1][1]:
        return "Step%dAnd%d" % (max(top[0][0], top[1][0]), min(top[0][0], top[1][0])), v
    return "Step%d" % top[0][0], v


for start, want in CURVES:
    got, v = derive(start)
    mono = all(v[i] <= v[i + 1] for i in range(127))
    check("R3  0x%05X derives %-10s and is non-decreasing" % (start, want),
          got == want and mono, "derived %s, v[0]=%d v[127]=%d" % (got, v[0], v[127]))
check("R3'  curve 0 is exactly index//12",
      all(D[0x22A3B + i] == i // 12 for i in range(128)), "128 of 128")

# --- R4 ------------------------------------------------------------------
print("\n=== R4.  the curve-bank Evidence lines, counted over the raw image ===\n")
WANT = {0x22A3B: (136, 0x23E9F), 0x22ABB: (27, 0x246B6), 0x22B3B: (7, 0x27415),
        0x22BBB: (11, 0x247D2), 0x22C3B: (7, 0x24D0B), 0x22CBB: (131, 0x23EDE)}
tot = 0
for start, (n_want, first_want) in WANT.items():
    pat = struct.pack("<I", start)
    occ = []
    i = 0
    while True:
        j = D.find(pat, i)
        if j < 0:
            break
        occ.append(j)
        i = j + 1
    tot += len(occ)
    check("R4  0x%05X: %3d LE32 pointers, first at 0x%05X" % (start, n_want, first_want),
          len(occ) == n_want and occ[0] == first_want,
          "found %d, first 0x%05X" % (len(occ), occ[0]))
check("R4'  318 of them are the slot +0x30 pool, +1 is the +0x38 shared object",
      tot == 319, "%d total LE32 pointers to the six curves" % tot)

# --- R5 ------------------------------------------------------------------
print("\n=== R5.  ★ field +0x0B is a 6-bit index into the +0x3C array ===\n")
ARR = [("+0x18", 0x1D965, 322), ("+0x20", 0x416AC, 208), ("+0x3C", 0x20F7B, 64)]
score = {}
for nm, base, n in ARR:
    score[nm] = sum(1 for i in range(n) if (D[base + i * 43 + 0x0B] & 0x3F) == i)
check("R5a  +0x3C: record N carries N in +0x0B & 0x3F", score["+0x3C"] == 63,
      "%d of 64; the exception is record 0, whose +0x0B is 0x%02X"
      % (score["+0x3C"], D[0x20F7B + 0x0B]))
check("R5a' checked at the LAST record, 63", D[0x20F7B + 63 * 43 + 0x0B] == 0x3F,
      "+0x0B = 0x%02X, and the array ends at 0x%05X" % (D[0x20F7B + 63 * 43 + 0x0B], 0x20F7B + 64 * 43))
check("R5b  the 0x3F mask is not decorative",
      sum(1 for i in range(64) if D[0x20F7B + i * 43 + 0x0B] & 0x40) == 28,
      "28 records set bit 6; without the mask they would index past the array")
check("R5c  NULL: the same test on +0x18", score["+0x18"] == 2, "2 of 322")
check("R5c' NULL: the same test on +0x20", score["+0x20"] == 1, "1 of 208")

# --- R6 ------------------------------------------------------------------
print("\n=== R6.  ★ the morpheme test that caught round 3's 'Home' ===\n")
for w, expect_zero in [("Home", True), ("Kit", False), ("Jazz", False),
                       ("Special", False), ("Melodic", False), ("Drum", False),
                       ("Preset", True), ("Tail", True), ("Step", True),
                       ("Curve", True), ("Mixer", True), ("WaveSel", True)]:
    n = sum(IMG[k].count(w.encode()) for k in "abcd")
    check("R6  %-8s occurs %4d times in the four images" % (w, n),
          (n == 0) == expect_zero,
          "carried by the image" if n else "NOT a word in any image -- must be measured structure")

# --- R7 ------------------------------------------------------------------
print("\n=== R7.  ★ THE FINDING: 'No column is printable in every record' ===\n")
for nm, base, n in ARR:
    full = [c for c in range(43)
            if all(0x20 <= D[base + i * 43 + c] < 0x7F for i in range(n))]
    runs = [len(list(g)) for _, g in
            itertools.groupby(enumerate(full), lambda t: t[1] - t[0])]
    widest = max(max((len(r) for r in re.findall(
        rb"[\x20-\x7e]+", D[base + i * 43:base + i * 43 + 43])), default=0)
        for i in range(n))
    check("R7  %s: the banner's 'No column is printable in every record'" % nm,
          len(full) == 0,
          "FALSE -- %d columns are: %s" % (len(full), full))
    check("R7' %s: what is TRUE, and what the refusal needs" % nm,
          max(runs, default=0) < 3 and widest < 13,
          "longest CONSECUTIVE always-printable run %d; widest printable run in any"
          " record %d; a name field needs 13" % (max(runs, default=0), widest))

# --- R8 ------------------------------------------------------------------
print("\n=== R8.  the ten rows, rebuilt from the directory offset table ===\n")
OFFT = 0x00000B80
BANK = 0x00000180


def tone_name(i):
    return D[struct.unpack_from("<I", D, OFFT + 4 * i)[0]:][:16].decode("latin1")


rows = []
for r in range(10):
    vals = [struct.unpack_from("<H", D, BANK + (r * 128 + p) * 2)[0] for p in range(128)]
    rows.append(vals)
check("R8a  rows 0-7 hold no tone index >= 256",
      all(all(v < 256 for v in rows[r]) for r in range(8)), "over all 1,024 entries")
check("R8b  row 8: every entry names a record whose own name ends in 'Kit'",
      all(tone_name(v).rstrip().endswith("Kit") for v in rows[8]),
      "128 of 128 -- so ToneNumBank_DrumKits is carried")
check("R8c  row 9 is 127 x 'Jazz Kit' plus ONE ' Special sound '",
      rows[9].count(0x100) == 127 and rows[9][127] == 0x110,
      "and 0x110 occurs in no other row: %d"
      % sum(r.count(0x110) for r in rows[:9]))
check("R8c' ⚠ so the SpecialSound label is taken from 1 of 128 entries",
      rows[9].count(0x110) == 1,
      "0.8%% of the row; row 8 is itself %d/128 Jazz Kit" % rows[8].count(0x100))

# --- R9 ------------------------------------------------------------------
print("\n=== R9.  the base-address search, re-run over prom_c's assembly ===\n")
CS = open(os.path.join(ROOT, "prom_c", "wsa1_prom_c.s")).read().split("\n")
DIRECTIVES = {"byte", "short", "long", "ascii", "asciz", "space", "align", "fill", "word"}


def literals(lo, hi):
    out = []
    for ln in CS:
        if not ln.startswith("\t"):
            continue
        body = ln.split(";")[0]
        m = re.match(r"\t([a-z][a-z0-9]*)\s", body)
        if not m or m.group(1) in DIRECTIVES:
            continue
        for lit in re.findall(r"0x([0-9A-Fa-f]{5,8})", body):
            if lo <= int(lit, 16) <= hi:
                out.append((ln.strip(), int(lit, 16)))
    return out


hits = literals(0x00F00000, 0x00F7FFFF)
check("R9a  operand literals in prom_d's window 0x00F00000-0x00F7FFFF",
      len(hits) == 1, "%d -- and it is 0x%06X, the BASE, not an object"
      % (len(hits), hits[0][1] if hits else -1))
check("R9b  NULL: the same scan over 0xE80000-0xEFFFFF is non-empty",
      len(literals(0x00E80000, 0x00EFFFFF)) > 0,
      "%d literals, so a zero above is an absence and not a broken scanner"
      % len(literals(0x00E80000, 0x00EFFFFF)))

print("\n%d checks, %d failures" % (len(RAN), len(FAILED)))
if FAILED:
    print("FAILED: " + "; ".join(FAILED))
    print("\n⚠ R7 is EXPECTED to fail while the 'No column is printable in every\n"
          "  record' sentence stands in the three wave-select banners.  It is the\n"
          "  finding of this review, not a defect in the review.")
sys.exit(1 if [f for f in FAILED if not f.startswith("R7  ")] else 0)
