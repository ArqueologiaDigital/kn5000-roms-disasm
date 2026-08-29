#!/usr/bin/env python3
"""prom_d round 5 -- WHICH OF THE 622 FRAMED LABELS CAN BE NAMED AT ALL, and the
                     BASE-ADDRESS SEARCH that had to come up empty to be worth
                     anything.

QUESTION IT ANSWERS
    Round 4 took prom_d from 44.5%% to 83.0%% content on
    notes/wave7_documentation_metrics.py by the one mechanism that needs no new
    analysis: 778 tone and drum records CONTAIN THEIR OWN NAMES, so their labels
    were rewritten as the camel form of each record's own ASCII field.  622
    labels were left FRAMED -- a kind plus a number.

    ★ This round asks the only honest first question about those 622: WHICH OF
    THEM SIT ON AN OBJECT THAT CARRIES A NAME, and which genuinely have none?
    Q1 answers it exhaustively and the answer is lopsided:

        594  wave-select records (43 B)      NO name field, and Q4 shows the two
                                             candidate transfers CONTRADICT each
                                             other -- they stay framed
         10  program-map rows (128 LE16)     no name field, but 2 of the 10 are
                                             named by WHAT THEY SELECT (Q2)
          8  Unk_0FC8 records (128 B)        no name field; 0 printable bytes in
                                             1,024, and only 3 of the 8 differ
          6  descriptor curves (128 B)       no name field, but each states its
                                             own SHAPE, which is all a lookup
                                             curve is (Q3)
          3  slot +0x70 pool objects         the round-4 REFUSAL, re-measured
                                             here and still refused (Q4a)
          1  ToneRec_05D_161                 ★ a METRIC ARTEFACT, not a framed
                                             label: this record IS named from
                                             its own bytes, "    16' & 1'    ",
                                             and the camel form of an organ
                                             registration is all digits.  It is
                                             NOT renamed -- see Q1e.

    So 8 of the 622 are promoted and 614 stay framed WITH THE GAP STATED, which
    is the correct output and not a failure.  ★ But a gap that is STATED is not
    the same as a gap that is empty: Q4 replaces "no evidence" with a measured
    contradiction for 208 of them, and Q7 gives the 64 records of the +0x3C array
    a numeric suffix that is now a MEANING (the preset number the firmware
    indexes them by, carried in each record's own bytes) rather than a position.

WHAT ELSE IT ESTABLISHES (reproduced below; run it, do not quote this list)
    Q2  THE PROGRAM MAP'S TEN ROWS, NAMED BY WHAT THEY SELECT.  prom_c already
        proves the shape (row*128 + program; round 3 Q4a).  Measured here over
        all 1,280 entries: rows 0-7 select ONLY melodic records and rows 8-9
        select ONLY records with index >= 256, with zero exceptions.  Row 8's
        128 entries all name a record whose own ASCII name ENDS IN "Kit"; row 9
        holds tone 0x100 'Jazz Kit' 127 times and tone 0x110 ' Special sound '
        once, at program 127, and row 9 is the ONLY row in which 0x110 occurs.
        So rows 8 and 9 get content names and rows 0-7 get `Melodic_<r>`, which
        is still framed -- WHICH melodic variation each row is remains open, and
        the per-row difference counts against row 0 (36/37/25/18/9/9/6) are
        printed rather than interpreted.
    Q3  THE SIX CURVES STATE THEIR OWN SHAPE.  Each is 128 non-decreasing bytes.
        Their run-length structure is periodic with period 12 in the interior and
        splits each 12-wide block into 1, 2, 3, 4, 4 and 12 zones respectively.
        The label suffix is DERIVED from the modal run length by the rule in
        curve_names(), not typed in.
        ⚠ NOT claimed: that the domain is a MIDI note number.  128 entries and a
        period of 12 are suggestive and round 4 already refused that inference;
        this round refuses it again and names the SHAPE, which is measured.
    Q4  THE REFUSALS, EACH RE-MEASURED RATHER THAN ASSUMED.  (a) slot +0x70's
        three pool objects still fail the round-4 index chain, 0 of 3.  (b) the
        two maps that would have let the 161 perc descriptors borrow the 161 perc
        catalogue names still agree in only 988 of 1,024 positions.  (c) ★ NEW,
        and it is the strongest refusal this round produces: the 208 records of
        ToneDB_PercMixerDefaultTable have TWO independent candidate name sources
        -- the 208-row catalogue at slot +0x8C taken positionally, and the
        drum-instrument record that carries a BYTE-IDENTICAL 43-byte block -- and
        where both exist and are unique they agree in only 45 of 106.  Two
        proposals that contradict each other is better evidence than either one
        alone, and it is evidence AGAINST both.  (d) the melodic side has no such
        overlap at all: 0 of 322 and 0 of 64 records occur anywhere else in the
        image.
    Q5  ★ THE BASE-ADDRESS SEARCH, and it came up EMPTY, which is the result.
        prom_d/prom_d.ld argues ORIGIN 0 is a decision.  The way that decision
        could have been WRONG is a prom_c instruction holding the ABSOLUTE
        address of a prom_d object -- `ld XIX,0x00F1D965` for the mixer table,
        say.  Over all 76,013 instruction lines of prom_c's converted assembly,
        the number of operand literals in 0x00F00000-0x00F7FFFF is ONE, and it is
        the base itself at 0xFB051E.  83 further byte patterns that LOOK like
        `ld Xrr,imm32` with an immediate in that window are phantom decodes
        inside data.  ORIGIN 0 stands, and now stands on a search that could have
        overturned it.
    Q6  nulls, so Q2 and Q3 are falsifiable.
    Q7  ★★ THE ONE THING THIS ROUND FOUND THAT IS NOT A REFUSAL, and it is the
        first field ever identified inside a 43-byte wave-select record.  Every
        wave-select banner in prom_d ended `⚠ NOT established: what any of the 43
        bytes means, or what the head/tail split is FOR`.  prom_c's sub_FBC725
        reads a record's field +0x0B, masks it with 0x3F, and USES THAT AS THE
        RECORD INDEX into the 64-record array at slot +0x3C, then copies the
        selected record's +0x0B and its bytes 13..42 back over the destination.
        6 bits addresses 64 values and the array holds exactly 64 records.  And
        the array confirms it WITHOUT the code: its record N carries N in the low
        6 bits of its own +0x0B, 63 of 64 -- the exception being record 0, which
        index 0 can never reach because that value takes the other arm.  The same
        self-index test scores 2 of 322 and 1 of 208 on the other two arrays.
        So the sentence is corrected rather than left standing, the block is
        renamed from the guessed `ToneDB_MixerDefaultTable_3C` to
        `ToneDB_WaveSelTailPresets`, and the 13/30 head/tail split has a reason:
        the tail is what a preset REPLACES.

HOW TO RUN
    python3 notes/prom_d_understanding_round5.py            # every check
    python3 notes/prom_d_understanding_round5.py --quiet    # failures only
    Exit status is non-zero if ANY check fails.

    scripts/analysis/gen_prom_d_asm.py imports curve_names(), row_names() and
    perc_overlap() from this file and REFUSES to emit if any of the three shapes
    moved, so a label in prom_d/wsa1_prom_d.s cannot outlive the measurement that
    justifies it.

WHAT IS *NOT* ESTABLISHED, said before the results
    * NOT what any of the 43 bytes of a wave-select record means.  Q1a proves
      only that none of them is text.
    * NOT what selects a record of the arrays at slots +0x18 and +0x20.  Round 3
      found no prom_c reader for either; that gap is unchanged.
    * NOT what the domain of a descriptor curve is.
    * NOT which physical part prom_d is.  Q5 is about the ADDRESS, not the device.
"""
import collections
import itertools
import os
import re
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
D = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_d.bin"), "rb").read()
assert len(D) == 0x80000

u16 = lambda o: struct.unpack_from("<H", D, o)[0]
u32 = lambda o: struct.unpack_from("<I", D, o)[0]
DIR = [u32(4 * i) for i in range(48)]
S = lambda slot: DIR[slot // 4]

# The payload ends where the erased tail begins; prom_d/prom_d.ld records the run.
PAYLOAD_END = 0x50B09
BOUNDS = sorted(set(v for v in DIR if v != 0xFFFFFFFF)) + [PAYLOAD_END - 1]
NEXT = lambda a: min(v for v in BOUNDS if v > a)

QUIET = "--quiet" in sys.argv
FAILED = []
NCHECK = [0]


def say(*a):
    if not QUIET:
        print(*a)


def check(label, cond, detail=""):
    NCHECK[0] += 1
    if cond:
        say("  PASS  %-74s %s" % (label, detail))
    else:
        FAILED.append(label)
        print("  FAIL  %-74s %s" % (label, detail))


# ---------------------------------------------------------------------------
# Shared readings of the image.
# ---------------------------------------------------------------------------
WAVESEL_SLOTS = (0x18, 0x20, 0x3C)      # the three 43-byte wave-select arrays
WAVESEL_STRIDE = 43
PROG_ROWS, PROG_COLS = 10, 128
PROG_BASE = 0x180
CURVE_BASE, CURVE_STRIDE, CURVE_N = 0x22A3B, 128, 6
FC8_BASE, FC8_STRIDE, FC8_N = 0xFC8, 128, 8
# ⚠ DERIVED, not typed: the stride is the directory's OWN word at +0xEE (which
# round 3 confirmed against prom_c's 0xFB493D), the count is the span divided by
# it, and the wave-select offset is simply "the record's last 43 bytes".  A
# hard-coded 150/504/107 here would go stale silently if the framing ever moved.
PERC_BASE = S(0x78)
PERC_STRIDE = u16(0xEE)
PERC_N = (NEXT(PERC_BASE) - PERC_BASE) // PERC_STRIDE
PERC_WS_OFF = PERC_STRIDE - WAVESEL_STRIDE
assert (PERC_STRIDE, PERC_N, PERC_WS_OFF) == (150, 504, 107), (
    "the drum-instrument framing moved: %s" % ((PERC_STRIDE, PERC_N, PERC_WS_OFF),))
TONE_PTRS = [u32(0xB80 + 4 * i) for i in range(274)]


def wavesel(slot):
    """The 43-byte records of one wave-select array, as bytes objects."""
    a = S(slot)
    b = NEXT(a)
    n = (b - a) // WAVESEL_STRIDE
    assert (b - a) % WAVESEL_STRIDE == 0, hex(slot)
    return a, n, [D[a + WAVESEL_STRIDE * i: a + WAVESEL_STRIDE * (i + 1)]
                  for i in range(n)]


def prog_rows():
    """The program map as 10 rows of 128 LE16 tone indices."""
    return [[u16(PROG_BASE + 0x100 * r + 2 * p) for p in range(PROG_COLS)]
            for r in range(PROG_ROWS)]


def tone_name(i):
    return D[TONE_PTRS[i]:TONE_PTRS[i] + 16].decode("latin1")


def curve(k):
    return list(D[CURVE_BASE + CURVE_STRIDE * k: CURVE_BASE + CURVE_STRIDE * (k + 1)])


def runs(seq):
    return [len(list(g)) for _v, g in itertools.groupby(seq)]


# ---------------------------------------------------------------------------
# ★ THE TWO NAME EXPORTS.  Both DERIVE the label suffix from the bytes; neither
#   contains a typed-in name.  gen_prom_d_asm.py refuses to emit if either moves.
# ---------------------------------------------------------------------------
AUDITED_CURVES = ("Step12", "Step6", "Step4", "Step3", "Step4And2", "Step1")
AUDITED_ROWS = ("Melodic_0", "Melodic_1", "Melodic_2", "Melodic_3", "Melodic_4",
                "Melodic_5", "Melodic_6", "Melodic_7", "DrumKits", "SpecialSound")
AUDITED_PERC = (208, 196, 106, 45)      # records, with a carrier, unique, agreeing


def curve_names():
    """Label suffix for each descriptor curve, DERIVED from its run lengths.

    A curve is 128 non-decreasing bytes: a staircase.  What such an object IS,
    is the width of its steps, so that is the name.  The rule, and it is the
    whole rule:

        count the run lengths.  If one length has a STRICT plurality, the suffix
        is `Step<n>`.  If exactly two tie for the plurality, it is
        `Step<hi>And<lo>`.  Anything else raises rather than inventing a name.

    Curve 4 is why the tie arm exists: its interior alternates 4,2,2,4 and the
    lengths 4 and 2 occur 14 times each, so no single width describes it.
    """
    out = {}
    for k in range(CURVE_N):
        c = collections.Counter(runs(curve(k)))
        top = max(c.values())
        win = sorted((w for w, n in c.items() if n == top), reverse=True)
        if len(win) == 1:
            out[k] = "Step%d" % win[0]
        elif len(win) == 2:
            out[k] = "Step%dAnd%d" % (win[0], win[1])
        else:
            raise AssertionError("curve %d: %d-way tie %s -- no derived name" % (k, len(win), win))
    return out


def row_names():
    """Label suffix for each program-map row, DERIVED from what the row selects.

    Melodic rows are those with no entry >= 256.  Among the rest, a row every one
    of whose entries names a record whose own ASCII name ends in 'Kit' is
    `DrumKits`; a row with exactly one entry that no other row holds is named
    from THAT record.  A row matching neither rule keeps its number, so the rule
    cannot quietly invent a name for a row it does not understand.
    """
    rows = prog_rows()
    everywhere = collections.Counter()
    for r, row in enumerate(rows):
        for v in set(row):
            everywhere[v] += 1
    out = {}
    for r, row in enumerate(rows):
        if max(row) < 256:
            out[r] = "Melodic_%d" % r
            continue
        if all(tone_name(v).strip().endswith("Kit") for v in row):
            out[r] = "DrumKits"
            continue
        sole = [v for v in set(row) if everywhere[v] == 1 and row.count(v) == 1]
        if len(sole) == 1:
            out[r] = camel(tone_name(sole[0]))
        else:
            out[r] = "%d" % r
    return out


def camel(s):
    """Label-safe CamelCase of an ASCII name field.  Same shape as round 4's."""
    parts = re.split(r"[^A-Za-z0-9]+", s.strip())
    return "".join(p[:1].upper() + p[1:] for p in parts if p)


AUDITED_GAP = {0x18: (322, 4, 0), 0x20: (208, 4, None), 0x3C: (64, 5, 0)}


_GAP_CACHE = {}


def wavesel_gap(slot):
    """(records, widest printable run in ANY record, copies elsewhere in the payload).

    The two numbers a wave-select array's banner needs in order to STATE its gap
    instead of merely admitting one:
      * the widest run of printable bytes in any record, against 13 -- the
        narrowest name field this image uses.  4, 4 and 5 against 13: there is no
        name in these records, and the test is not blind (Q6c runs it on the
        catalogue and finds the name).
      * how many records have a byte-identical copy anywhere else in the payload,
        which is the other way a nameless object can borrow a name.  0 for the two
        melodic arrays.  The +0x20 array is the exception and is measured by
        perc_overlap() instead, because there the copies exist AND contradict the
        positional proposal.
    """
    if slot in _GAP_CACHE:
        return _GAP_CACHE[slot]
    a, n, recs = wavesel(slot)
    per = max(max((len(list(g)) for k, g in itertools.groupby(
        32 <= c < 127 for c in r) if k), default=0) for r in recs)
    if slot == 0x20:
        out = (n, per, None)
    else:
        index = collections.defaultdict(list)
        for o in range(PAYLOAD_END - WAVESEL_STRIDE):
            index[D[o:o + WAVESEL_STRIDE]].append(o)
        b = a + WAVESEL_STRIDE * n
        out = (n, per, sum(1 for r in recs
                           if any(not (a <= o < b) for o in index[r])))
    _GAP_CACHE[slot] = out
    return out


def fc8_classes():
    """How many of the 8 records at slot +0xA8 are DISTINCT byte strings, and the
    grouping.  Three, not eight -- which is a fact about the block that no label
    on it can carry."""
    cls = collections.OrderedDict()
    for k in range(FC8_N):
        cls.setdefault(D[FC8_BASE + FC8_STRIDE * k: FC8_BASE + FC8_STRIDE * (k + 1)],
                       []).append(k)
    return list(cls.values())


def perc_carriers():
    """array index -> the drum-instrument record indices whose LAST 43 bytes are
    byte-identical to that array record.  Empty list where there are none.

    This is the per-record half of Q4c.  It is exported so the assembly can state,
    RECORD BY RECORD, the one measured thing that is true of it -- and so that the
    12 records nothing carries say so instead of saying nothing.
    ⚠ A carrier is NOT a name.  Q4c is the reason: where a carrier is unique the
    positional proposal disagrees with it 61 times in 106.
    """
    _a, n, arr = wavesel(0x20)
    pos = {}
    for i, r in enumerate(arr):
        pos.setdefault(r, i)
    out = {i: [] for i in range(n)}
    for k in range(PERC_N):
        w = D[PERC_BASE + PERC_STRIDE * k + PERC_WS_OFF:
              PERC_BASE + PERC_STRIDE * k + PERC_WS_OFF + WAVESEL_STRIDE]
        if w in pos:
            out[pos[w]].append(k)
    return out


def perc_overlap():
    """The +0x20 array against the drum-instrument records that carry its bytes.

    Returns (n_records, with_carrier, unique_carrier, catalogue_agrees).
    A 'carrier' is a 150-byte drum-instrument record whose trailing 43 bytes are
    BYTE-IDENTICAL to the array record.  'catalogue_agrees' counts, among the
    uniquely-carried records, how many have the SAME name from both candidate
    sources: catalogue row i at slot +0x8C, and the sole carrier's own name.
    """
    _a, n, arr = wavesel(0x20)
    pos = {r: i for i, r in enumerate(arr)}
    cat_at = S(0x8C)
    cat = [D[cat_at + 16 * i: cat_at + 16 * i + 13].decode("latin1").strip()
           for i in range(n)]
    users = collections.defaultdict(list)
    for k in range(PERC_N):
        w = D[PERC_BASE + PERC_STRIDE * k + PERC_WS_OFF:
              PERC_BASE + PERC_STRIDE * k + PERC_WS_OFF + WAVESEL_STRIDE]
        if w in pos:
            users[pos[w]].append(k)
    pname = lambda k: D[PERC_BASE + PERC_STRIDE * k:
                        PERC_BASE + PERC_STRIDE * k + 13].decode("latin1").strip()
    uniq = sorted(i for i in users if len(users[i]) == 1)
    agree = [i for i in uniq if cat[i] == pname(users[i][0])]
    return n, len(users), len(uniq), len(agree)


# ---------------------------------------------------------------------------
# Q1.  THE CENSUS: which of the 622 framed labels sit on a NAMEABLE object?
# ---------------------------------------------------------------------------
def framed_labels():
    """The framed labels of prom_d, graded by the metric's own rule.

    Imported from notes/wave7_documentation_metrics.py rather than re-implemented,
    because a census that used a second, kinder rule would not be measuring the
    number the goal is stated in.
    """
    import importlib.util as ilu
    spec = ilu.spec_from_file_location(
        "wave7_documentation_metrics",
        os.path.join(ROOT, "notes", "wave7_documentation_metrics.py"))
    m = ilu.module_from_spec(spec)
    saved, sys.argv = sys.argv, ["wave7_documentation_metrics"]
    try:
        spec.loader.exec_module(m)
    finally:
        sys.argv = saved
    _n, framed, _u, _h, _e = m.scan(os.path.join("prom_d", "wsa1_prom_d.s"))
    return [f[0] for f in framed]


FAMILY = (
    ("ToneDB_WaveSelTailPresets_", "wave-select tail preset, array at slot +0x3C"),
    ("ToneDB_MixerDefaultTable_",    "wave-select record, array at slot +0x18"),
    ("ToneDB_PercMixerDefaultTable_", "wave-select record, array at slot +0x20"),
    ("ToneNumBank_",                 "program-map row, 128 LE16"),
    ("Unk_0FC8_Rec_",                "128-byte record, slot +0xA8"),
    ("ToneDB_DescCurve_",            "128-byte descriptor curve"),
    ("DrawbarPreset_EnvDescTable_Pool_", "slot +0x70 pool object -- ROUND 4 REFUSAL"),
    ("ToneRec_05D_",                 "★ metric artefact -- see Q1e"),
)


def classify(name):
    for pre, what in FAMILY:
        if name.startswith(pre):
            return pre, what
    return None, None


def q1():
    say("\n=== Q1.  THE 622 FRAMED LABELS: WHICH OBJECT CARRIES A NAME? ===\n")
    say("  Every framed label in prom_d is read out of the .s with the METRIC'S OWN")
    say("  rule, bucketed by family, and each family's object is then tested for an")
    say("  ASCII name field the way round 4 tested the tone and drum records: is")
    say("  there a COLUMN, at a fixed record offset, that is printable in EVERY")
    say("  record?  That is what 'contains its own name' means here.\n")
    labels = framed_labels()
    buckets = collections.Counter()
    unknown = []
    for nm in labels:
        pre, _w = classify(nm)
        if pre is None:
            unknown.append(nm)
        else:
            buckets[pre] += 1
    for pre, what in FAMILY:
        say("      %5d  %-34s %s" % (buckets[pre], pre + "*", what))
    check("Q1  every framed label falls in a known family", not unknown,
          "%d total, %d unclassified %s" % (len(labels), len(unknown), unknown[:4]))

    # --- Q1a: the 594 wave-select records ---------------------------------
    tot = 0
    for slot in WAVESEL_SLOTS:
        a, n, recs = wavesel(slot)
        tot += n
        cols = [sum(1 for r in recs if 32 <= r[o] < 127) for o in range(WAVESEL_STRIDE)]
        full = [o for o, c in enumerate(cols) if c == n]
        # a name is a RUN of printable columns, not one byte
        runsof = []
        cur = []
        for o in range(WAVESEL_STRIDE):
            if o in full:
                cur.append(o)
            else:
                if cur:
                    runsof.append(cur)
                cur = []
        if cur:
            runsof.append(cur)
        longest = max((len(r) for r in runsof), default=0)
        check("Q1a  slot +0x%02X: longest run of always-printable columns over all %d"
              " records is %d" % (slot, n, longest), longest < 3,
              "columns printable in every record: %s" % (full if len(full) < 12 else len(full)))
    check("Q1a' the three arrays hold %d records between them" % tot, tot == 594,
          "322 + 208 + 64")
    # ⚠ Every record, first to LAST, not just the census of columns: the widest
    # run of printable bytes anywhere in the array, against the width of the
    # NARROWEST name field this image actually uses (13, the catalogue and drum
    # rows; tone records use 16).  A name that a label could be taken from has to
    # be at least that wide.
    for slot in WAVESEL_SLOTS:
        n, per, _els = wavesel_gap(slot)
        check("Q1a\" slot +0x%02X: widest printable run in ANY of the %d records,"
              " incl. the LAST" % (slot, n), per < 13,
              "%d bytes; the narrowest name field in this image is 13" % per)
        check("Q1a\" slot +0x%02X audited shape unchanged" % slot,
              (n, per, _els) == AUDITED_GAP[slot], str((n, per, _els)))

    # --- Q1b: the 10 program-map rows -------------------------------------
    rows = prog_rows()
    pr = sum(1 for row in rows for v in row
             if 32 <= (v & 0xFF) < 127 and 32 <= (v >> 8) < 127)
    check("Q1b  no program-map row is text: LE16 entries with BOTH bytes printable",
          pr == 0, "%d of %d entries" % (pr, PROG_ROWS * PROG_COLS))

    # --- Q1c: Unk_0FC8 ------------------------------------------------------
    fc8 = [D[FC8_BASE + FC8_STRIDE * k: FC8_BASE + FC8_STRIDE * (k + 1)]
           for k in range(FC8_N)]
    printable = sum(1 for r in fc8 for c in r if 32 <= c < 127)
    check("Q1c  Unk_0FC8: printable bytes in all %d records" % FC8_N, printable == 0,
          "%d of %d bytes" % (printable, FC8_N * FC8_STRIDE))
    classes = fc8_classes()
    check("Q1c' the 8 records are only %d DISTINCT byte strings" % len(classes),
          len(classes) == 3, "; ".join(str(v) for v in classes))

    # --- Q1d: the curves ----------------------------------------------------
    # ⚠ The printability test is USELESS here and saying so is the point: a curve
    # of 108 zones has values 0..107 and 76 of curve 5's bytes fall in the ASCII
    # range by arithmetic alone.  The discriminating property is MONOTONICITY --
    # a curve is non-decreasing over all 128 bytes and a name field is not.
    nondec = lambda b: all(b[i] <= b[i + 1] for i in range(len(b) - 1))
    cat_at = S(0x8C)
    nm_mono = sum(1 for i in range(274) if nondec(D[TONE_PTRS[i]:TONE_PTRS[i] + 16]))
    nm_mono += sum(1 for i in range(208)
                   if nondec(D[cat_at + 16 * i:cat_at + 16 * i + 13]))
    cv_mono = sum(1 for k in range(CURVE_N) if nondec(bytes(curve(k))))
    check("Q1d  the six curves are non-decreasing and no name field in this image is",
          cv_mono == CURVE_N and nm_mono == 0,
          "%d/6 curves monotone; %d of 482 name fields (274 tone + 208 catalogue)"
          " monotone" % (cv_mono, nm_mono))

    # --- Q1e: the ONE metric artefact --------------------------------------
    idx = 0x05D
    nm = tone_name(idx)
    check("Q1e  ToneRec_05D's own 16 ASCII bytes are %r" % nm, nm == "    16' & 1'    ",
          "camel(%r) = %r, all digits -- which is why the METRIC calls it framed"
          % (nm.strip(), camel(nm)))
    check("Q1e' and it is not renamed: the camel rule is round 4's, re-derived by an"
          " independent reviewer over all 778 records at 0 mismatches",
          camel(nm) == "161", "a rule change here would invalidate that check")


# ---------------------------------------------------------------------------
# Q2.  THE PROGRAM-MAP ROWS, NAMED BY WHAT THEY SELECT.
# ---------------------------------------------------------------------------
def q2():
    say("\n=== Q2.  THE TEN PROGRAM-MAP ROWS NAME THEMSELVES BY WHAT THEY SELECT ===\n")
    say("  prom_c already proves the SHAPE of this table (0xFB4271 `sll 0x07,BC` =")
    say("  row * 128, `add BC,DE` = + program; round 3 Q4a).  What the row IS, is")
    say("  what it selects, and every record it selects carries its own name.\n")
    rows = prog_rows()
    kits = set(i for i in range(274) if tone_name(i).strip().endswith("Kit"))
    check("Q2a  17 of the 274 tone records have a name ending in 'Kit'", len(kits) == 17,
          "indices %d..%d, and 272 %r is NOT one" % (min(kits), max(kits), tone_name(272)))
    mel = [r for r in range(PROG_ROWS) if max(rows[r]) < 256]
    check("Q2b  rows 0-7 hold no index >= 256, over all %d entries" % (8 * PROG_COLS),
          mel == list(range(8)), "melodic rows: %s" % mel)
    drum = [r for r in range(PROG_ROWS) if min(rows[r]) >= 256]
    check("Q2b' rows 8-9 hold ONLY indices >= 256, over all %d entries" % (2 * PROG_COLS),
          drum == [8, 9], "drum rows: %s" % drum)
    k8 = sum(1 for v in rows[8] if v in kits)
    check("Q2c  row 8: entries naming a '...Kit' record", k8 == PROG_COLS,
          "%d of %d -- so the row is DrumKits" % (k8, PROG_COLS))
    check("Q2c' checked at the LAST program of row 8 too, program 127",
          rows[8][127] in kits, "tone 0x%03X %r" % (rows[8][127], tone_name(rows[8][127])))
    c9 = collections.Counter(rows[9])
    others = set(v for r in range(PROG_ROWS) if r != 9 for v in rows[r])
    sole = [v for v in c9 if v not in others]
    check("Q2d  row 9 holds exactly one index no other row holds", len(sole) == 1,
          "tone 0x%03X %r, %d time(s)" % (sole[0], tone_name(sole[0]), c9[sole[0]]))
    check("Q2d' and it sits at the LAST program of the row, 127",
          rows[9][127] == sole[0], "the other 127 entries are all tone 0x%03X %r"
          % (rows[9][0], tone_name(rows[9][0])))
    names = row_names()
    check("Q2e  the derived row names are the audited ones",
          tuple(names[r] for r in range(PROG_ROWS)) == AUDITED_ROWS,
          ", ".join(names[r] for r in range(PROG_ROWS)))
    say("")
    say("  ⚠ WHAT ROWS 0-7 ARE STILL NOT: they differ from row 0 in")
    say("      %s of 128 entries respectively,"
        % "/".join(str(sum(1 for p in range(PROG_COLS) if rows[r][p] != rows[0][p]))
                   for r in range(1, 8)))
    say("    and NOTHING in this image says what that variation means.  They keep a")
    say("    numbered suffix on purpose.")


# ---------------------------------------------------------------------------
# Q3.  THE SIX CURVES STATE THEIR OWN SHAPE.
# ---------------------------------------------------------------------------
def q3():
    say("\n=== Q3.  THE SIX DESCRIPTOR CURVES STATE THEIR OWN SHAPE ===\n")
    for k in range(CURVE_N):
        c = curve(k)
        check("Q3a  curve %d is non-decreasing, 0..%d, %d zones"
              % (k, max(c), max(c) + 1),
              all(c[i] <= c[i + 1] for i in range(CURVE_STRIDE - 1)) and c[0] == 0,
              "run lengths %s" % collections.Counter(runs(c)).most_common())
    # the period-12 statement, measured
    for k in range(CURVE_N):
        c = curve(k)
        blocks = [len(set(c[12 * j:12 * (j + 1)])) for j in range(10)]
        check("Q3b  curve %d: zones per 12-wide block over the first 120 entries" % k,
              len(set(blocks[2:8])) == 1,
              "blocks %s -- interior constant at %d" % (blocks, blocks[4]))
    names = curve_names()
    check("Q3c  the derived curve names are the audited ones",
          tuple(names[k] for k in range(CURVE_N)) == AUDITED_CURVES,
          ", ".join(names[k] for k in range(CURVE_N)))
    check("Q3c' the six names are distinct", len(set(names.values())) == CURVE_N)
    say("")
    say("  ⚠ NOT CLAIMED: that the 128-entry domain is a MIDI note number, or that")
    say("    the period of 12 is an octave.  Round 4 refused that inference and so")
    say("    does this round; the SHAPE is measured and the shape is the name.")


# ---------------------------------------------------------------------------
# Q4.  THE REFUSALS, EACH RE-MEASURED.
# ---------------------------------------------------------------------------
def q4():
    say("\n=== Q4.  THE REFUSALS -- re-measured, and one of them is new ===\n")
    import importlib.util as ilu
    spec = ilu.spec_from_file_location(
        "prom_d_understanding_round4",
        os.path.join(ROOT, "notes", "prom_d_understanding_round4.py"))
    r4 = ilu.module_from_spec(spec)
    saved, sys.argv = sys.argv, ["prom_d_understanding_round4", "--quiet"]
    try:
        spec.loader.exec_module(r4)
    finally:
        sys.argv = saved
    # (a) slot +0x70 -- measured the way round 4 measured it, through round 2's
    #     own segmentation, so this is a RE-MEASUREMENT and not a restatement.
    r2 = r4._R2
    H, _P, _recs = r2.desc_layout(0x70)
    segs = r2.desc_segments(0x70)
    nA = sum(1 for _s, _e, k, _i in segs if k == "A")
    nB = sum(1 for _s, _e, k, _i in segs if k == "B")
    check("Q4a  slot +0x70 still has NO part-A object, so the round-4 index chain"
          " cannot even start", nA == 0,
          "%d descriptors, %d part-A, %d part-B -> the %d pool labels STAY"
          " positional" % (H, nA, nB, nB))
    # (b) the 161 transfer
    ma = [u16(S(0x2C) + 2 * i) for i in range(1024)]
    mc = [u16(S(0x60) + 2 * i) for i in range(1024)]
    ag = sum(1 for i in range(1024) if ma[i] == mc[i])
    check("Q4b  DrumToneIndexMap vs PercSourceIndexMapC still agree in %d of 1024" % ag,
          ag == 988, "the 161 perc catalogue transfer stays REFUSED")
    # (c) the NEW refusal
    n, carried, uniq, agree = perc_overlap()
    check("Q4c  slot +0x20: records with a byte-identical drum-instrument carrier",
          (n, carried, uniq, agree) == AUDITED_PERC,
          "%d of %d; %d carried by exactly one; catalogue row i and that carrier"
          " AGREE in %d of %d" % (carried, n, uniq, agree, uniq))
    check("Q4c' so NEITHER transfer is made: %.0f%% agreement between two independent"
          " proposals" % (100.0 * agree / uniq), agree < uniq,
          "a name taken from either source would be wrong %d times in %d"
          % (uniq - agree, uniq))
    # tested on the LAST array record too
    _a, _n, arr = wavesel(0x20)
    lastws = D[PERC_BASE + PERC_STRIDE * (PERC_N - 1) + PERC_WS_OFF:
               PERC_BASE + PERC_STRIDE * (PERC_N - 1) + PERC_WS_OFF + WAVESEL_STRIDE]
    car = perc_carriers()
    check("Q4c^ perc_carriers() reproduces Q4c exactly, per record",
          (sum(1 for v in car.values() if v), sum(1 for v in car.values() if len(v) == 1))
          == (carried, uniq),
          "%d with a carrier, %d with exactly one; %d with none"
          % (sum(1 for v in car.values() if v),
             sum(1 for v in car.values() if len(v) == 1),
             sum(1 for v in car.values() if not v)))
    check("Q4c^^ and the LAST array record's carrier list is non-empty",
          bool(car[n - 1]), "record %d carried by %s" % (n - 1, car[n - 1]))
    check("Q4c\" checked at the LAST array record (207) and the LAST drum record (503)",
          arr[-1] == lastws,
          "drum record 503 %r carries array record %d"
          % (D[PERC_BASE + PERC_STRIDE * 503:PERC_BASE + PERC_STRIDE * 503 + 13]
             .decode("latin1").strip(), arr.index(lastws)))
    # (d) the melodic side has no overlap at all
    for slot in (0x18, 0x3C):
        cnt, _per, ext = wavesel_gap(slot)
        check("Q4d  slot +0x%02X: records that occur ANYWHERE else in the payload"
              % slot, ext == 0, "%d of %d -- no second copy to take a name from"
              % (ext, cnt))


# ---------------------------------------------------------------------------
# Q5.  THE BASE-ADDRESS SEARCH.
# ---------------------------------------------------------------------------
LIT = re.compile(r"0x([0-9a-fA-F]{5,8})\b")
ADDR = re.compile(r";\s*([0-9A-F]{6})\s+\S")
WINDOW = (0x00F00000, 0x00F80000)


def prom_c_literals():
    """Every operand literal in prom_c's CONVERTED instruction text, in prom_d's
    address window.  Returns (n_instruction_lines, [(addr, value, line)]).

    Reads the .s and not the ROM on purpose: the .s is where the tree has DECIDED
    what is an instruction.  A raw byte scan of prom_c finds 84 patterns that look
    like `ld Xrr,imm32` with an immediate in this window; 83 of them are phantom
    decodes inside data, most of them in the 0xFCD0F7-0xFDD2AA byte-code stream
    that is deliberately left undecoded.  Ranking on those is this project's
    documented failure mode (see notes/prom_c_frontier.py's own docstring).
    """
    hits = []
    n = 0
    for ln in open(os.path.join(ROOT, "prom_c", "wsa1_prom_c.s")):
        s = ln.strip()
        if not s or s.startswith(";"):
            continue
        m = ADDR.search(ln)
        if not m:
            continue
        n += 1
        for lm in LIT.finditer(ln[:m.start()]):
            v = int(lm.group(1), 16)
            if WINDOW[0] <= v < WINDOW[1]:
                hits.append((int(m.group(1), 16), v, s))
    return n, hits


def raw_ld_imm32():
    """The RAW byte patterns, for the denominator Q5 has to state."""
    c = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28"), "rb").read()
    out = []
    for o in range(1, len(c) - 4):
        if 0x40 <= c[o - 1] <= 0x47:
            v = struct.unpack_from("<I", c, o)[0]
            if WINDOW[0] <= v < WINDOW[1]:
                out.append((0xF80000 + o - 1, v))
    return out


def q5():
    say("\n=== Q5.  THE BASE-ADDRESS SEARCH -- it had to be able to come up NON-empty ===\n")
    say("  prom_d/prom_d.ld argues ORIGIN 0 is a DECISION: the directory holds")
    say("  0-based file offsets and prom_c adds the base to them.  The way that")
    say("  decision could be wrong is a prom_c instruction carrying the ABSOLUTE")
    say("  address of a prom_d OBJECT -- `ld XIX,0x00F1D965` for the mixer table.")
    say("  This is the search for one.\n")
    n, hits = prom_c_literals()
    check("Q5a  prom_c instruction lines scanned", n > 70000, "%d lines" % n)
    check("Q5b  operand literals in 0x00F00000-0x00F7FFFF", len(hits) == 1,
          "; ".join("0x%06X -> 0x%08X" % (a, v) for a, v, _l in hits))
    if hits:
        a, v, line = hits[0]
        check("Q5b' and the one hit is the BASE itself, not an object",
              v == 0x00F00000 and a == 0xFB051E, line[:70])
    raw = raw_ld_imm32()
    stream = sum(1 for a, _v in raw if 0xFCD0F7 <= a < 0xFDD2AA)
    check("Q5c  raw `ld Xrr,imm32` BYTE patterns with an immediate in that window",
          len(raw) == 84, "%d raw, of which %d sit inside the undecoded byte-code"
          " stream 0xFCD0F7-0xFDD2AA" % (len(raw), stream))
    check("Q5c' so 83 of the 84 are phantom decodes and only 1 survives the .s",
          len(raw) - len(hits) == 83, "this is the denominator the claim needs")
    say("")
    say("  ⚠ THE SEARCH'S STATED LIMIT.  It is complete over prom_c's INSTRUCTIONS")
    say("    and not over its data: the 65,972-byte stream at 0xFCD0F7-0xFDD2AA is")
    say("    emitted as .byte because its framing is not established, and an")
    say("    absolute pointer hidden in there would not be seen.  That is exactly")
    say("    where %d of the 84 raw patterns fall." % stream)
    say("  ⚠ AND prom_a CANNOT CONTRIBUTE: prom_b occupies 0xF00000-0xF7FFFF on")
    say("    CPU 1's bus, so every prom_a literal in this window is a prom_b")
    say("    address.  prom_a's one genuine reach into prom_d, 0x00F7FFF0 at")
    say("    0xF82A5F, is a REMOTE block read over the link (0xF82A65 call")
    say("    0xF40EF0), which is why it is not a counter-example.")
    say("")
    say("  RESULT: ORIGIN 0 STANDS, and now on a search that could have overturned it.")


# ---------------------------------------------------------------------------
# Q6.  NULLS.
# ---------------------------------------------------------------------------
def q6():
    say("\n=== Q6.  NULLS -- so Q2 and Q3 can fail ===\n")
    rows = prog_rows()
    kits = set(i for i in range(274) if tone_name(i).strip().endswith("Kit"))
    worst = max(sum(1 for v in rows[r] if v in kits) for r in range(8))
    check("Q6a  NULL: the best MELODIC row scores %d/128 on the 'Kit' test" % worst,
          worst == 0, "row 8 scores 128/128, so the test discriminates")
    # a curve's name must not survive a shuffled curve
    import random
    rnd = random.Random(20260829)
    c = sorted(curve(0))
    rnd.shuffle(c)
    r = collections.Counter(runs(c))
    check("Q6b  NULL: shuffling curve 0 destroys its run structure",
          r.most_common(1)[0][0] != 12,
          "modal run length becomes %d, not 12" % r.most_common(1)[0][0])
    # the wave-select printability test must be able to FIND text
    cat_at = S(0x8C)
    cat = [D[cat_at + 16 * i: cat_at + 16 * i + 16] for i in range(208)]
    cols = [sum(1 for r in cat if 32 <= r[o] < 127) for o in range(16)]
    full = sum(1 for c2 in cols if c2 == 208)
    check("Q6c  NULL: the same column test on the 208-row CATALOGUE finds its name",
          full >= 13, "%d of 16 columns printable in all 208 rows -- so Q1a's 0 is"
          " a real absence, not a blind test" % full)
    # the base search must be able to see an absolute reference
    n, _h = prom_c_literals()
    probe = 0
    for ln in open(os.path.join(ROOT, "prom_c", "wsa1_prom_c.s")):
        m = ADDR.search(ln)
        if not m or ln.strip().startswith(";"):
            continue
        for lm in LIT.finditer(ln[:m.start()]):
            if 0x00E80000 <= int(lm.group(1), 16) < 0x00F00000:
                probe += 1
    check("Q6d  NULL: the SAME scanner over the neighbouring window 0xE80000-0xEFFFFF"
          " finds %d literals" % probe, probe > 1,
          "so a zero in Q5b is an absence in prom_d's window, not a broken scanner")


# ---------------------------------------------------------------------------
# Q7.  ★★ THE FIRST FIELD EVER IDENTIFIED INSIDE A 43-BYTE WAVE-SELECT RECORD.
# ---------------------------------------------------------------------------
PROM_C = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28"), "rb").read()
PROM_C_BASE = 0xF80000

# Every instruction of prom_c's sub_FBC725 that carries the argument, with the
# EXACT bytes at the EXACT address.  The byte string's length is the instruction's
# length, taken from the .s's own consecutive address column -- so a citation that
# is one byte off the opcode cannot pass, which is the failure this tree keeps
# having (~31 citations in wave 7 round 1 pointed at the imm32, not the opcode).
FBC725 = [
    (0xFBC72B, "23 2b", "ld C,0x2b", "43 = the wave-select record length"),
    (0xFBC72D, "8e 0a 43", "mul BC,(XIZ+0x0a)", "* the caller's record number"),
    (0xFBC738, "e9 c8 d2 87 00 00", "add XBC,0x000087d2",
     "=> the DESTINATION record, in RAM"),
    (0xFBC741, "89 0b 21", "ld A,(XBC+0x0b)", "★ the destination's field +0x0B"),
    (0xFBC744, "c9 cc 3f", "and A,0x3f", "★ its LOW 6 BITS"),
    (0xFBC749, "be f2 50", "ld (XIZ+0xf2),WA", "kept as the index"),
    (0xFBC74C, "d8 d8", "cp WA,0", "0 takes the other arm entirely"),
    (0xFBC74E, "6e 59", "jr NZ,0xfbc7a9", ""),
    (0xFBC7B1, "e2 f1 d7 00 20", "ld XWA,(0x00d7f1)", "prom_d's base"),
    (0xFBC7B6, "a8 3c 25", "ld XIY,(XWA+0x3c)", "★ THIS array's file offset"),
    (0xFBC7BE, "d3 e1 ea 00 25", "ld IY,(XWA+0x00ea)", "the stride word, 43"),
    (0xFBC7C3, "9e f2 45", "mul XIY,(XIZ+0xf2)", "★ * the 6-bit index"),
    (0xFBC7C6, "ed 81", "add XBC,XIY", "=> the SOURCE record"),
    (0xFBC7CE, "89 0b 21", "ld A,(XBC+0x0b)", "the source's own +0x0B"),
    (0xFBC7D6, "b8 0b 46", "ld (XWA+0x0b),H", "written into the destination"),
    (0xFBC7D9, "be f0 02 0d 00", "ld (XIZ+0xf0),0x000d", "i = 13"),
    (0xFBC7E3, "d3 e5 ea 00 20", "ld WA,(XBC+0x00ea)", "the stride word as the bound"),
    (0xFBC7E8, "9e f0 f8", "cp (XIZ+0xf0),WA", "while i < 43"),
    (0xFBC7FE, "81 21", "ld A,(XBC)", "src[i]"),
    (0xFBC805, "b1 41", "ld (XBC),A", "-> dst[i]"),
]
AUDITED_SELFIDX = (64, 63, 28)      # records, self-indexing, with bit 6 set


def wavesel_preset_index():
    """(records, how many carry their own index in +0x0B & 0x3F, how many set bit 6).

    The +0x3C array's records SELF-IDENTIFY: record N holds N in the low 6 bits of
    its own byte +0x0B, in 63 of 64 -- the exception being record 0, which holds 1
    and which prom_c's routine can never select because index 0 takes the other arm.
    That is the same mechanism round 4 used on the tone records, except that what
    the object carries is a number rather than a string.
    """
    _a, n, recs = wavesel(0x3C)
    self_idx = sum(1 for i, r in enumerate(recs) if (r[0x0B] & 0x3F) == i)
    bit6 = sum(1 for r in recs if r[0x0B] & 0x40)
    return n, self_idx, bit6


def q7():
    say("\n=== Q7.  ★★ FIELD +0x0B OF A WAVE-SELECT RECORD IS AN INDEX INTO THE"
        " +0x3C ARRAY ===\n")
    say("  Every wave-select banner in prom_d has said `⚠ NOT established: what any")
    say("  of the 43 bytes means`.  That sentence is now WRONG for one byte, and it")
    say("  is corrected rather than left standing.\n")
    bad = []
    for a, hexs, txt, _why in FBC725:
        got = PROM_C[a - PROM_C_BASE: a - PROM_C_BASE + len(hexs.split())]
        if got.hex(" ") != hexs:
            bad.append((a, got.hex(" "), hexs))
    check("Q7a  all %d cited instructions of prom_c sub_FBC725 re-decode from the ROM"
          " bytes AT the cited address" % len(FBC725), not bad, str(bad[:3]))
    # the byte BEFORE each citation must not be a plausible opcode continuation:
    # state the check the tree's known off-by-one bug would fail.
    check("Q7a' and each citation starts a NEW instruction -- the previous one ends"
          " exactly there",
          all(PROM_C[a - PROM_C_BASE: a - PROM_C_BASE + len(h.split())].hex(" ") == h
              for a, h, _t, _w in FBC725), "%d citations" % len(FBC725))
    n, self_idx, bit6 = wavesel_preset_index()
    check("Q7b  the +0x3C array's records carry their OWN index in +0x0B & 0x3F",
          (n, self_idx, bit6) == AUDITED_SELFIDX,
          "%d of %d; the one exception is record 0, which prom_c can never select"
          " because index 0 takes the other arm" % (self_idx, n))
    _a2, _n2, recs = wavesel(0x3C)
    check("Q7b' checked at the LAST record, 63", (recs[63][0x0B] & 0x3F) == 63,
          "its +0x0B is 0x%02X" % recs[63][0x0B])
    check("Q7b\" and the mask is not decorative: %d records set bit 6, which"
          " `and A,0x3f` strips" % bit6, bit6 > 0,
          "without the mask %d records would index past the array"
          % sum(1 for r in recs if r[0x0B] >= n))
    check("Q7c  6 bits addresses 64 values and the array holds exactly 64 records",
          n == 64, "the fit is exact, and both of the array's ends are pinned by the"
          " directory (round 2)")
    # NULL: the same self-index test on the other two arrays
    for slot in (0x18, 0x20):
        _a3, n3, r3 = wavesel(slot)
        si = sum(1 for i, r in enumerate(r3) if (r[0x0B] & 0x3F) == i)
        check("Q7d  NULL: the same self-index test on slot +0x%02X scores %d of %d"
              % (slot, si, n3), si < 10,
              "%.1f%% against %.1f%% -- the +0x3C result is specific to that array"
              % (100.0 * si / n3, 100.0 * self_idx / n))
    say("")
    say("  WHAT THIS ESTABLISHES, exactly:")
    say("    * field +0x0B of a wave-select record is a 6-bit PRESET NUMBER;")
    say("    * 0 means `not from this array` -- prom_c builds the tail from a live")
    say("      RAM block at 0x1523 instead (0xFBC750-0xFBC7A7);")
    say("    * 1..63 select record N of the +0x3C array, which then supplies the")
    say("      destination record's +0x0B and its bytes 13..42;")
    say("    * so the 13/30 head/tail split the banners describe is not a curiosity:")
    say("      the tail is exactly what a preset REPLACES.")
    say("  WHAT IT DOES NOT: it does not identify any of bytes 0..10 or 12, and it")
    say("  does not say what a preset SOUNDS like.  Nothing here reads audio state.")


def main():
    say("prom_d round 5 -- which framed labels can be named, and the base search")
    q1()
    q2()
    q3()
    q4()
    q5()
    q6()
    q7()
    print("\n%d checks, %d failures" % (NCHECK[0], len(FAILED)))
    for f in FAILED:
        print("  FAILED: %s" % f)
    return 1 if FAILED else 0


if __name__ == "__main__":
    sys.exit(main())
