#!/usr/bin/env python3
"""Do the L7A1429 documents agree with each other, and does the key claim hold?

QUESTION THIS ANSWERS
    The acoustic-modelling LSI is documented in FOUR artefacts that live in THREE
    repositories -- the disassembly's notes, the disassembly's HLE guide, the
    public documentation site, and the MAME driver.  Each is gated on its own
    terms.  Nothing checked that they AGREE, and in September 2026 a run of late
    corrections left them out of step: the driver still printed "(unidentified)"
    for two blocks the notes had named, and two documents still framed a settled
    question as an open six-way choice.

    This is the integration check.  It asks four things:

      1. every register BLOCK appears in both the sequencing and the curve
         document, or its absence is explained;
      2. every register block carries the SAME NAME in all four artefacts, and
         the blocks one artefact leaves unnamed are unnamed in the others too;
      3. every artefact's own count of how many blocks are named agrees with how
         many are actually named;
      4. the curve lane's headline unit derivation reproduces from first
         principles rather than from its own code.

    ⚠ It checks CONSISTENCY, not truth.  A green run means the documents do not
    contradict each other.  Whether the names are RIGHT is settled by the
    evidence in FINDINGS-l7a1429-editor-pages.md, not here.

WHY THE ARITHMETIC CHECK IS HERE
    The curve lane's central claim is that the filter-cutoff table's index is a
    SEMITONE, established by forcing the fitted slope to 1/12 and solving for the
    index-0 frequency from the ROM alone.  That gives 65.4201 Hz against a true
    MIDI 36 of 65.4064 Hz.  Re-deriving the discrepancy independently -- in
    cents, from the equal-tempered definition -- is a one-line check that the
    claim is arithmetically what it says it is, and it is worth having beside the
    claim rather than in a transcript.

WHERE THE NAMES ARE READ FROM
    Three of the four artefacts are markdown and carry a visible sentinel,
    `CROSSCHECK-NAME-TABLE`, on a line before the table this script reads.  The
    sentinel exists because two of those files hold MORE than one register table
    on purpose: the tree's convention is to leave a superseded table exactly as
    its lane wrote it and add the correction beside it, so "the last table in the
    file" would be a guess.  The fourth artefact is the MAME driver, where the
    names live twice -- in `block_name()` and in the header's register list --
    and both are read, because that is precisely where a rename drifts.

RUN
    python3 wsa1/notes/l7a1429_crosscheck.py
    python3 wsa1/notes/l7a1429_crosscheck.py --selftest
    python3 wsa1/notes/l7a1429_crosscheck.py --docs-root ... --mame-root ...

    The three repositories are expected side by side.  Any that is not where this
    script looks is a FAILURE with the path it wanted and the flag that overrides
    it -- never a silent skip, because a check that skips is worse than no check.
"""
import argparse
import math
import os
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
DISASM_DEFAULT = HERE.parents[1]                       # <repo>/wsa1/notes -> <repo>

# ---------------------------------------------------------------------------
# 1. the block-presence check, unchanged
# ---------------------------------------------------------------------------

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

# ---------------------------------------------------------------------------
# 2. the name registry
# ---------------------------------------------------------------------------
#
# A block's NAME is reduced to a set of ATOMS before comparison, because the four
# artefacts spell the same caption differently on purpose: the driver needs a
# short symbol for a bus trace ("MAIN MUTING Q16"), the docs quote the editor's
# own caption ("MAIN `MUTING`, Q16 form"), and the notes' name column also lists
# the touch-depth companion the same register carries.  Reducing to atoms
# compares the CLAIM and not the prose.
#
#   CORE     atoms that name the control.  All four artefacts must produce the
#            same core set for a block, or the check fails.
#   VARIANT  atoms that only DISAMBIGUATE two blocks carrying one caption --
#            MAIN FITTING decay vs rise, MAIN MUTING Q13 vs Q16.  An artefact may
#            omit a variant; but any artefact that states one must state the same
#            one, so a swapped pair is still caught.
#
# ⚠ THE LIMIT, stated rather than hidden: because DECAY/RISE and Q13/Q16 are
# optional, two blocks sharing a caption could be swapped in an artefact that
# names neither variant, and this check would pass.  The MAME driver names every
# variant, so a swap there is caught; a swap in a document that omits them is
# not.  Closing that would mean requiring the variant everywhere, which would
# mean rewording notes this tree does not reword.
CORE_ATOMS = {"MAIN", "SUB", "TUNE", "POSITION", "FITTING", "MUTING",
              "GAIN", "DEPTH", "INTERACTION"}
VARIANT_ATOMS = {"DECAY", "RISE", "Q13", "Q16"}

# Applied to the upper-cased cell before tokenising.
SYNONYMS = [
    ("P0SITI0N", "POSITION"),   # the editor's own zero-for-O spelling
    ("M0VEMENT", "MOVEMENT"),
    ("DETUNE", "TUNE"),         # PAGE1/3's column header stacks as DE / TUNE
]
# Phrases that name a COMPANION control inside a register's name cell, not the
# register.  Stripped first, so "MAIN FITTING + its TOUCH DEPTH" does not leak
# the atom DEPTH, which belongs to block 0x0240.
STRIP_PHRASES = ["TOUCH DEPTH", "KEY FOLLOW", "KEY SHIFT", "RESO MODE",
                 "RESO SCALE", "MOVEMENT"]

UNNAMED_RE = re.compile(r"NO EDITOR NAME|UNIDENTIFIED|CONSTANT|LITERAL|NO NAME")

# Blocks the name check does not apply to, each with the reason PRINTED.
NAME_EXEMPT = {
    "0x0000": "the four artefacts name this word's FIELDS (bits 15/14 RESO MODE, "
              "bits 6..4 the GROUP enable, bit 7 the sign of SUB GAIN) and none "
              "names the word itself",
}
# (artefact, block) pairs that are legitimately absent from that artefact.
DECLARED_ABSENT = {
    ("notes", "0x0800"): "the editor-pages table covers the nineteen per-channel "
                         "blocks; 0x0800 has no channel and no editor page",
}

SENTINEL = "CROSSCHECK-NAME-TABLE"

COUNT_RE = re.compile(
    r"\b([A-Za-z]+) of the nineteen\b[^.\n]{0,60}?\b"
    r"(?:carry a name|carry names|are named)\b")
WORDNUM = {"nine": 9, "ten": 10, "eleven": 11, "twelve": 12, "thirteen": 13,
           "fourteen": 14, "fifteen": 15, "sixteen": 16, "seventeen": 17,
           "eighteen": 18, "nineteen": 19}
# Artefacts that must state their own count, so the sentence cannot be deleted
# to make this check pass.
COUNT_REQUIRED = {"guide", "docs", "driver"}


# ---------------------------------------------------------------------------
# 3. extraction
# ---------------------------------------------------------------------------

def strip_markup(cell):
    s = cell.replace("`", "").replace("**", "").replace("*", "")
    for ch in "★⚠":                       # the tree's star and warning
        s = s.replace(ch, "")
    return s.strip()


def classify(cell):
    """-> ('named', core, variant) | ('unnamed', ...) | ('unrecognised', ...)"""
    txt = strip_markup(cell)
    up = txt.upper()
    for a, b in SYNONYMS:
        up = up.replace(a, b)
    for phrase in STRIP_PHRASES:
        up = up.replace(phrase, " ")
    tokens = set(re.split(r"[^A-Z0-9]+", up))
    core = frozenset(tokens & CORE_ATOMS)
    variant = frozenset(tokens & VARIANT_ATOMS)
    if core:
        return "named", core, variant
    if not txt or txt[0] in "—-" or UNNAMED_RE.search(up):
        return "unnamed", frozenset(), frozenset()
    return "unrecognised", frozenset(), frozenset()


def md_table_after_sentinel(text, path):
    """The first markdown table following the sentinel line."""
    at = text.find(SENTINEL)
    if at < 0:
        raise Crosscheck(f"{path}: no {SENTINEL} marker -- this script cannot "
                         f"tell which of the file's register tables is current")
    rows, started = [], False
    for line in text[at:].splitlines()[1:]:
        if line.lstrip().startswith("|"):
            started = True
            rows.append(line)
        elif started:
            break
    if len(rows) < 4:
        raise Crosscheck(f"{path}: no markdown table after the {SENTINEL} marker")
    return rows


def parse_md(path, label):
    text = read(path)
    rows = md_table_after_sentinel(text, path)
    header = [strip_markup(c).lower() for c in rows[0].strip().strip("|").split("|")]
    cols = [i for i, h in enumerate(header) if "name" in h]
    if len(cols) != 1:
        raise Crosscheck(f"{path}: the {SENTINEL} table needs exactly one column "
                         f"whose header mentions 'name'; found {len(cols)} in {header}")
    col = cols[0]
    out = {}
    for line in rows[2:]:
        cells = line.strip().strip("|").split("|")
        # the block number, allowing a trailing annotation such as *(no channel)*
        m = re.match(r"\s*\**`?(0x[0-9A-Fa-f]{4})`?\b", cells[0])
        if not m or len(cells) <= col:
            continue
        out[m.group(1).upper().replace("0X", "0x")] = cells[col]
    # the count sentence, inside the same section as the table
    end = text.find("\n## ", text.find(SENTINEL))
    region = text[text.find(SENTINEL):] if end < 0 else text[text.find(SENTINEL):end]
    return out, counts(region, label)


def counts(region, label):
    found = []
    for word in COUNT_RE.findall(strip_markup(region)):
        n = WORDNUM.get(word.lower())
        if n is None:
            raise Crosscheck(f"{label}: cannot read the number word {word!r} in a "
                             f"'... of the nineteen ... are named' sentence")
        found.append(n)
    return found


def parse_driver(cpp_path, h_path):
    """block_name()'s switch AND the header's register list -- both, on purpose."""
    cpp = read(cpp_path)
    m = re.search(r"block_name\(unsigned block\)\s*\{(.*?)\n\}", cpp, re.S)
    if not m:
        raise Crosscheck(f"{cpp_path}: block_name(unsigned block) not found")
    body = m.group(1)
    switch = {}
    for blk, name in re.findall(r'case\s+(0x[0-9a-fA-F]{4}):\s*return\s+"([^"]*)"', body):
        switch[blk.upper().replace("0X", "0x")] = name
    if "default:" not in body or "nullptr" not in body:
        raise Crosscheck(f"{cpp_path}: block_name() has no `default: return nullptr`"
                         " -- unnamed blocks would not be reported as unnamed")

    hdr = read(h_path)
    a, b = hdr.find("    THE REGISTERS"), hdr.find("    Units, for the decoded view")
    if a < 0 or b < 0 or b < a:
        raise Crosscheck(f"{h_path}: the THE REGISTERS block was not found where "
                         "this script looks (between 'THE REGISTERS' and 'Units,')")
    table = {}
    for line in hdr[a:b].splitlines():
        fields = re.split(r"\s{2,}", line.strip())
        if len(fields) >= 2 and re.fullmatch(r"0x[0-9A-F]{4}", fields[0]):
            table[fields[0]] = fields[1]

    names = {}
    for blk in BLOCKS + ["0x0000"]:
        names[blk] = switch.get(blk, "--")
    for blk, nm in table.items():
        if blk not in names:
            raise Crosscheck(f"{h_path}: register list names block {blk}, which is "
                             "not in this script's BLOCKS list")
        if not same_name(nm, names[blk]):
            raise Crosscheck(
                f"driver disagrees WITH ITSELF for block {blk}: "
                f"acoustic_modeling.h says {nm!r}, block_name() says {names[blk]!r}")
    missing = set(names) - set(table)
    if missing:
        raise Crosscheck(f"{h_path}: register list is missing "
                         f"{sorted(missing)} -- it must list every block")
    return names, counts(cpp, "driver .cpp") + counts(hdr, "driver .h")


def same_name(a, b):
    """Do two spellings of one block's name make the same claim?"""
    x, y = classify(a), classify(b)
    if x[:2] != y[:2]:
        return False
    return not (x[2] and y[2] and x[2] != y[2])


class Crosscheck(Exception):
    pass


def read(path):
    if not path.exists():
        raise Crosscheck(
            f"NOT FOUND: {path}\n"
            f"    This check reads three repositories.  Point it at yours with\n"
            f"    --disasm-root / --docs-root / --mame-root (or the environment\n"
            f"    variables KN5000_DISASM_ROOT / KN5000_DOCS_ROOT / KN7000_MAME_ROOT).")
    return path.read_bytes().decode("utf-8")


# ---------------------------------------------------------------------------
# 4. the name comparison, as a pure function so --selftest can mutate its input
# ---------------------------------------------------------------------------

def compare_names(per_artefact, verbose=True):
    """per_artefact: {label: {block: raw name cell}} -> list of failure strings."""
    fails = []
    named_count = None
    for blk in ["0x0000"] + BLOCKS:
        if blk in NAME_EXEMPT:
            if verbose:
                print(f"    {blk}   EXEMPT -- {NAME_EXEMPT[blk]}")
            continue
        verdicts = {}
        for label, table in per_artefact.items():
            if blk not in table:
                why = DECLARED_ABSENT.get((label, blk))
                if why:
                    if verbose:
                        print(f"    {blk}   absent from {label} -- {why}")
                    continue
                fails.append(f"{blk} missing from {label}")
                verdicts[label] = ("MISSING", frozenset(), frozenset())
                continue
            verdicts[label] = classify(table[blk])
        bad = [l for l, v in verdicts.items() if v[0] == "unrecognised"]
        if bad:
            for l in bad:
                fails.append(f"{blk} in {l}: {per_artefact[l][blk].strip()!r} is "
                             "neither a known name nor marked unnamed")
        kinds = {l: v[0] for l, v in verdicts.items()}
        cores = {l: v[1] for l, v in verdicts.items()}
        variants = {l: v[2] for l, v in verdicts.items() if v[2]}
        agree = len(set(kinds.values())) == 1 and len(set(cores.values())) == 1
        agree = agree and len(set(variants.values())) <= 1
        if not agree and not bad:
            fails.append(f"{blk}: " + "; ".join(
                f"{l}={sorted(cores[l] | verdicts[l][2]) or kinds[l]}"
                for l in sorted(verdicts)))
        if verbose and blk not in NAME_EXEMPT:
            shown = sorted(next(iter(cores.values())) | (
                next(iter(variants.values())) if variants else frozenset()))
            print(f"    {blk}   {'ok  ' if agree and not bad else 'FAIL'}   "
                  f"{' '.join(shown) if shown else kinds[next(iter(kinds))]}")
    counted = sum(1 for blk in BLOCKS if blk not in NAME_EXEMPT
                  and classify(next(iter(per_artefact.values())).get(blk, "--"))[0] == "named")
    return fails, counted


def check_counts(per_counts, named_count, verbose=True):
    fails = []
    for label, found in per_counts.items():
        if not found and label in COUNT_REQUIRED:
            fails.append(f"{label} states no '<N> of the nineteen ... are named' "
                         "count; that sentence is required so it cannot drift away")
        for n in found:
            if n != named_count:
                fails.append(f"{label} says {n} blocks are named; {named_count} are")
        if verbose:
            print(f"    {label:8s} states {found or 'no count'} "
                  f"(actual {named_count})")
    return fails


# ---------------------------------------------------------------------------

def midi_hz(n):
    return 440.0 * 2 ** ((n - 69) / 12)


def cents(a, b):
    return 1200 * math.log2(a / b)


def main(argv):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--disasm-root", default=os.environ.get("KN5000_DISASM_ROOT"),
                    help="the kn5000-roms-disasm checkout (default: this file's repo)")
    ap.add_argument("--docs-root", default=os.environ.get("KN5000_DOCS_ROOT"),
                    help="the technics-docs checkout (default: ../technics-docs)")
    ap.add_argument("--mame-root", default=os.environ.get("KN7000_MAME_ROOT"),
                    help="the kn7000_mame overlay (default: ../kn7000_mame)")
    ap.add_argument("--selftest", action="store_true",
                    help="prove the checks can go red")
    args = ap.parse_args(argv)

    disasm = pathlib.Path(args.disasm_root or DISASM_DEFAULT).resolve()
    docs = pathlib.Path(args.docs_root or disasm.parent / "technics-docs").resolve()
    mame = pathlib.Path(args.mame_root or disasm.parent / "kn7000_mame").resolve()

    notes = disasm / "wsa1" / "notes"
    SEQ = notes / "FINDINGS-l7a1429-write-sequencing.md"
    CUR = notes / "FINDINGS-l7a1429-curve-tables.md"
    NOTES_TABLE = notes / "FINDINGS-l7a1429-editor-pages.md"
    GUIDE = notes / "HLE-GUIDE-l7a1429.md"
    DOCS_PAGE = docs / "wsa1-modeling-lsi.md"
    DRV_CPP = mame / "src" / "mame" / "matsushita" / "acoustic_modeling.cpp"
    DRV_H = mame / "src" / "mame" / "matsushita" / "acoustic_modeling.h"

    print("  the four artefacts")
    for label, p in (("notes", NOTES_TABLE), ("guide", GUIDE),
                     ("docs", DOCS_PAGE), ("driver", DRV_CPP), ("driver", DRV_H)):
        print(f"    {label:8s} {p}")

    fails = []

    # ---- 1. blocks present in both wave-19 documents -----------------------
    print("\n  register blocks named in both documents")
    seq, cur = read(SEQ), read(CUR)
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

    # ---- 2. the same NAME in all four --------------------------------------
    print("\n  every block's name, across all four artefacts")
    per_artefact, per_counts = {}, {}
    per_artefact["notes"], per_counts["notes"] = parse_md(NOTES_TABLE, "notes")
    per_artefact["guide"], per_counts["guide"] = parse_md(GUIDE, "guide")
    per_artefact["docs"], per_counts["docs"] = parse_md(DOCS_PAGE, "docs")
    per_artefact["driver"], per_counts["driver"] = parse_driver(DRV_CPP, DRV_H)
    for label, table in per_artefact.items():
        if len(table) < 15:
            fails.append(f"{label}: only {len(table)} register rows were parsed -- "
                         "an extractor that reads nothing agrees with everything")
    name_fails, named_count = compare_names(per_artefact)
    fails += name_fails

    print(f"\n  each artefact's own count of how many blocks are named")
    fails += check_counts(per_counts, named_count)

    # ---- 3. the arithmetic --------------------------------------------------
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

    if args.selftest:
        fails += selftest(per_artefact, per_counts, named_count)

    if fails:
        print(f"\nFAIL: {len(fails)} inconsistency(ies):")
        for f in fails:
            print(f"    {f}")
        return 1
    print("\nPASS: the four documents agree, and the unit derivation reproduces.")
    return 0


def selftest(per_artefact, per_counts, named_count):
    """Every check below must go RED.  A check that cannot fail is not a check."""
    print("\n  --selftest: the checks must reject a wrong document")
    fails = []

    def expect_red(what, mutate):
        mutated = {k: dict(v) for k, v in per_artefact.items()}
        mutate(mutated)
        got, _ = compare_names(mutated, verbose=False)
        print(f"    {what:52s} {'ok -- rejected' if got else 'ACCEPTED -- BLIND'}")
        if not got:
            fails.append(f"selftest: {what} was accepted")

    expect_red("a block RENAMED in one artefact",
               lambda m: m["driver"].__setitem__("0x0300", "FITTING"))
    expect_red("a named block made UNNAMED in one artefact",
               lambda m: m["driver"].__setitem__("0x0240", "--"))
    expect_red("an unnamed block given a NAME in one artefact",
               lambda m: m["docs"].__setitem__("0x03C0", "**`FORMANT GAIN`**"))
    expect_red("MAIN and SUB swapped in one artefact",
               lambda m: (m["guide"].__setitem__("0x0040", "**SUB RESONATOR `TUNE`**"),
                          m["guide"].__setitem__("0x0080", "**MAIN RESONATOR `TUNE`**")))
    expect_red("the Q13/Q16 disambiguator swapped in the driver",
               lambda m: (m["driver"].__setitem__("0x0340", "MAIN MUTING Q16"),
                          m["driver"].__setitem__("0x0400", "MAIN MUTING Q13")))
    expect_red("a block row deleted from one artefact",
               lambda m: m["docs"].pop("0x0280"))
    expect_red("the stale 'candidate DEPTH / FORMANT / INTERACTION GAIN' cell",
               lambda m: m["guide"].__setitem__(
                   "0x0240", "candidate `DEPTH` / `FORMANT` / `INTERACTION GAIN`"))

    # a name outside the vocabulary must be reported, not silently ignored
    kind = classify("**`FROBNICATE`**")[0]
    print(f"    {'a name outside the atom vocabulary':52s} "
          f"{'ok -- flagged' if kind == 'unrecognised' else 'IGNORED -- BLIND'}")
    if kind != "unrecognised":
        fails.append("selftest: an unknown name was silently ignored")

    # a stale count sentence must be caught
    got = check_counts({"docs": [12]}, named_count, verbose=False)
    print(f"    {'a stale named-block count (twelve, not 14)':52s} "
          f"{'ok -- rejected' if got else 'ACCEPTED -- BLIND'}")
    if not got:
        fails.append("selftest: a stale count was accepted")
    got = check_counts({"docs": []}, named_count, verbose=False)
    print(f"    {'the count sentence deleted outright':52s} "
          f"{'ok -- rejected' if got else 'ACCEPTED -- BLIND'}")
    if not got:
        fails.append("selftest: a missing count sentence was accepted")

    # the extractors must actually have read something
    for label, table in per_artefact.items():
        n = sum(1 for b, v in table.items()
                if b not in NAME_EXEMPT and classify(v)[0] == "named")
        print(f"    {label + ' extractor found ' + str(n) + ' named blocks':52s} "
              f"{'ok' if n >= 14 else 'TOO FEW -- extractor is blind'}")
        if n < 14:
            fails.append(f"selftest: the {label} extractor found only {n} names")

    # the driver's two surfaces must agree WITH EACH OTHER
    pairs = [("MAIN MUTING Q16", "MAIN MUTING Q13"),   # variant drifted
             ("DEPTH", "--"),                          # one surface renamed
             ("SUB GAIN", "MAIN GAIN")]                # side swapped
    blind = [p for p in pairs if same_name(*p)]
    print(f"    {'the driver header disagreeing with block_name()':52s} "
          f"{'ok -- rejected' if not blind else 'ACCEPTED -- BLIND'}")
    if blind:
        fails.append(f"selftest: the driver's two surfaces agreed on {blind}")
    if not same_name("MAIN MUTING Q16", "**MAIN `MUTING`**, Q16 form"):
        fails.append("selftest: same_name() rejects two correct spellings of one name")

    # the arithmetic checks, unchanged
    true36 = midi_hz(36)
    bad = cents(midi_hz(37), true36)
    rejected = abs(bad) >= 1.63
    print(f"    {'an index-0 one semitone high':52s} "
          f"{'ok -- rejected' if rejected else 'ACCEPTED -- check is blind'}")
    if not rejected:
        fails.append("selftest: semitone")
    blind = abs(XTAL_HZ / 512 - 44100) < 1e-9
    print(f"    {'the wrong crystal divider (512)':52s} "
          f"{'ok -- rejected' if not blind else 'ACCEPTED -- check is blind'}")
    if blind:
        fails.append("selftest: divider")
    return fails


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv[1:]))
    except Crosscheck as e:
        print(f"\nFAIL: {e}")
        sys.exit(1)
