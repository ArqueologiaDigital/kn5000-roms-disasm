#!/usr/bin/env python3
"""prom_d round 6 -- ARE THE 614 REMAINING FRAMED LABELS NAMEABLE AT ALL?
                     The classification is exhaustive; 301 of them turn out to be.

QUESTION IT ANSWERS
    Round 5 left prom_d at 83.2%% content on notes/wave7_documentation_metrics.py
    with 614 framed labels and zero sub_XXXXXX, and said of 594 of the 614 that
    they sit on 43-byte WAVE-SELECT RECORDS that carry no name field, that the
    two candidate name transfers for one of the arrays CONTRADICT each other, and
    that they therefore stay framed.  The first half of that is still true.  The
    second half was the wrong question.

    ★★ THE MECHANISM ROUND 5 MISSED, and it is the wave's own thesis applied one
    step further: NAME AN OBJECT FROM WHAT IT CONTAINS -- including when what it
    contains is a COPY OF A NAMED OBJECT'S BYTES.  Round 5 ran that test and got
    a zero ("0 of 322 occur anywhere else in the image") because it compared all
    43 bytes.  Round 5 had ALSO just proved that byte +0x0B of a wave-select
    record is a preset number that prom_c rewrites.  Excluding the one field the
    firmware is known to overwrite turns the zero into 167.

        Q2  167 of the 322 records at slot +0x18 are identical to the wave-select
            block of a NAMED TONE RECORD in 42 of their 43 bytes.  The one
            differing byte is +0x0B in 167 of 167 -- no record differs from a
            tone's block in exactly one byte at any OTHER position, and 0 of
            3,000 random 43-byte windows match under the same rule.
        Q3  196 of the 208 records at slot +0x20 are BYTE-IDENTICAL to the
            43-byte tail of a NAMED DRUM-INSTRUMENT record (round 5 already had
            this half; what is new is that the melodic side now shows the same
            relation where NO competing catalogue exists, which is what tells the
            two round-5 proposals apart).
        Q4  ★ AND THE ONE BLOCK THAT WAS NAMED BY ITS READER RATHER THAN ITS
            CONTENT.  `Unk_0FC8_Table`, 8 x 128 bytes, "PURPOSE UNKNOWN" since
            round 1, is an OCTAVE-SHIFT TABLE indexed by [tone bank][program
            number], and prom_c's sub_FA72E9 -- the only reader -- is called only
            from Voice_ComputePitch.  Its other arm reads a 16-entry table at
            prom_c 0xFDF22A whose entries are -96,-84,...,+84: multiples of 12.
            Both arms return the value shifted left 8.  prom_d's table holds only
            0xF4 (-12) and 0x0C (+12).  And the cells it marks name themselves:
            programs 88-95 of every one of the 8 banks are the ORGAN family, and
            the others are Tubular Bells / Gamelan (program 14), Timpani (126)
            and Agogo (122, the only +12 in the image).

    So 301 of the 614 are promoted and 313 stay framed WITH THE GAP STATED, and
    Q1 says which is which for every one of the 614 rather than by class.

WHAT ELSE IT ESTABLISHES (reproduced below; run it, do not quote this list)
    Q1  ★ THE EXHAUSTIVE CLASSIFICATION.  Every one of the 614 framed labels gets
        exactly one verdict, the verdicts partition the 614, and the count is
        re-derived from prom_d/wsa1_prom_d.s itself rather than assumed.
    Q2b THE SECOND, INDEPENDENT WITNESS for the +0x18 array, and it also answers
        "what selects a record of this array", which round 5 listed as open.  The
        1,024-entry map at slot +0x0C is the ONLY map in the image whose range
        reaches 321, this array's last index.  911 of its entries point at a
        record the byte test matched; in 637 of those 911 (69.9%) the program-map
        tone at the same position is exactly the tone the byte test assigned.
        Shuffling the map gives 1.0-1.3%; the other ten 1,024-entry maps give
        0.0-3.3%.  ⚠ 69.9% is NOT 100% and the label is NOT changed on it -- it
        is corroboration for the record names, not a proof about the map.
    Q5  ★ THE REFUSALS, KEPT, AND ONE OF THEM SHARPENED RATHER THAN WEAKENED.
        (a) slot +0x70's three pool objects still fail the round-4 index chain,
            0 of 3.  Still refused.
        (b) the 161 perc catalogue names still transfer through maps that agree
            in only 988 of 1,024.  Still refused.
        (c) the POSITIONAL transfer from the 208-row catalogue at slot +0x8C is
            still refused, and round 6 says WHY it disagrees instead of only that
            it does: the catalogue is a DIFFERENT LIST.  Over the 141 rows this
            round's byte identity resolves, the catalogue carries the same name
            at the SAME index 61 times, carries it at a DIFFERENT index 62 times,
            and 18 times names something the drum records do not have at all.
            The alignment is NOT monotone, so it is not a simple drift either.
            Catalogue row 1 is 'Square Wave' where the identical bytes come from
            'Square Click'; rows 7 and 8 are 'PowerBassDrmL' and 'PowerBassDrmR'
            where array record 7 matches nothing and record 8 matches
            'PowerBassDrm1/2'.  (⚠ these four numbers are catalogue_alignment()'s
            and the generator quotes THAT, not this paragraph.)
        ⚠ The names this round DOES give are relations, not ownership: a label
        says `_SameAs_<X>`, which is what was measured -- these bytes and X's
        bytes are the same -- and NOT "this record belongs to X".
    Q6  ★ TWO MECHANISMS MEASURED AND REJECTED, recorded so a later round does
        not re-invent them.
        (a) RENAMING `ToneDB_WaveSelTailPresets_063` TO `..._Preset63`.  It would
            move 64 labels from framed to content on the goal metric and add
            nothing: the number already means the preset number (round 5 Q7) and
            the word "Preset" is already in the block label.  Refused.
        (b) NAMING THE 64 PRESET RECORDS FROM A TONE THEY MATCH.  Measured with
            the Q2 rule: their minimum distance to any of the 451 tone
            wave-select blocks is 6, and NONE is at distance 0 or 1.  A preset
            replaces only the 30-byte tail, so it has no head to match with.
            The mechanism genuinely does not reach them.
    Q7  ★ THE BASE-ADDRESS SEARCH, extended, and it still comes up empty -- which
        is the result.  Round 5 searched prom_c's 76,013 instruction lines for an
        ABSOLUTE prom_d address and found exactly one literal in
        0x00F00000-0x00F7FFFF, the base itself.  Round 6 adds the CONVERSE
        census, which is positive evidence rather than an absence: prom_c holds
        46 `add <Xrr>,(0x00D7ED|0x00D7F1)` instructions, every one adding the base
        to a value computed from prom_d's own words.  And Q4 adds a CONTENT-level
        tie of the kind the round-6 brief asked for: 0xFA7332 reads slot +0xA8,
        0xFA7351 scales by 128 and 0xFA7358 adds the base, and the bytes at the
        resulting file offsets are a coherent octave table keyed by the program
        map at slot +0x04.  ⚠ ORIGIN in prom_d/prom_d.ld is NOT changed, and this
        round did not find anything that could have changed it.
    Q8  nulls, so Q2, Q3 and Q4 can fail -- including the one that had to be
        REWRITTEN because its first form could not test what it was aimed at: a
        null that slides the program index along by 1-3 stays inside the organ run
        and scores HIGHER than the real reading.  A null that slides along a run
        cannot test a run.  Q8c tests the SHAPE instead.
    Q9  ★ THE TWO CHECKS ROUND 3'S REVIEWERS HAD TO MAKE BY HAND, made by machine.
        (a) the one word this round introduces that is not copied verbatim out of
        a record's own name field is "Octave" -- and it occurs 7 times across the
        four images, twice in prom_d (' Octave Strings ' at 0x08521 and
        '  Octave Brass  ' at 0x0E412).  Round 3 shipped five prom_a labels built
        on "Home", which occurs ZERO times anywhere.  (b) all 15 prom_c addresses
        this round cites are instruction STARTS in the gate-verified listing;
        round 1 shipped 31 citations one byte past the instruction.

HOW TO RUN
    python3 notes/prom_d_understanding_round6.py            # every check
    python3 notes/prom_d_understanding_round6.py --quiet    # failures only
    Exit status is non-zero if ANY check fails.

    scripts/analysis/gen_prom_d_asm.py imports wavesel_twins(), wavesel_labels()
    and octave_rows() from this file and REFUSES to emit if any of the three
    shapes moved, so a label in prom_d/wsa1_prom_d.s cannot outlive the
    measurement that justifies it.

WHAT IS *NOT* ESTABLISHED, said before the results
    * NOT that a matched record BELONGS to the tone or drum instrument it matches.
      What is measured is an identity of BYTES.  Where the same bytes are carried
      by records with more than one distinct name the label is NOT given.
    * NOT what any of bytes 0..10 or 12..42 of a wave-select record means.  Q2
      identifies no new field; it identifies a COPY.
    * NOT what selects a record of the array at slot +0x20.  Q2b's witness exists
      only on the melodic side.
    * NOT the numeric unit of the octave table.  Q4 shows the two arms of
      sub_FA72E9 use the SAME encoding and that prom_c's arm holds only multiples
      of 12; "an octave" is what the values are, not a claim about the scaling.
    * NOT which physical part prom_d is.  Q7 is about the ADDRESS, not the device.
"""
import collections
import os
import random
import re
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_lines, image_text   # noqa: E402
D = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_d.bin"), "rb").read()
C = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_c.ic28"), "rb").read()
assert len(D) == 0x80000 and len(C) == 0x80000
PROM_C_BASE = 0xF80000

u16 = lambda o: struct.unpack_from("<H", D, o)[0]
u32 = lambda o: struct.unpack_from("<I", D, o)[0]
DIR = [u32(4 * i) for i in range(48)]
S = lambda slot: DIR[slot // 4]

PAYLOAD_END = 0x50B09                      # prom_d/prom_d.ld records the erased run
BOUNDS = sorted(set(v for v in DIR if v != 0xFFFFFFFF)) + [PAYLOAD_END - 1]

QUIET = "--quiet" in sys.argv
FAILED = []
NCHECK = [0]


def say(*a):
    if not QUIET:
        print(*a)


def check(label, cond, detail=""):
    NCHECK[0] += 1
    if cond:
        say("  PASS  %-72s %s" % (label, detail))
    else:
        FAILED.append(label)
        print("  FAIL  %-72s %s" % (label, detail))


# ---------------------------------------------------------------------------
# Shared readings of the image.  Nothing below is a typed-in constant that the
# image can supply: the strides come from the directory's own words and the
# region bounds from the directory's own values.
# ---------------------------------------------------------------------------
WAVESEL_STRIDE = u16(0xEA)                 # 43, and prom_c reads this word
PERC_STRIDE = u16(0xEE)                    # 150
TONE_PTRS = [u32(0xB80 + 4 * i) for i in range(274)]
PRESET_FIELD = 0x0B                        # round 5 Q7: the byte prom_c rewrites
PROG_ROWS, PROG_COLS, PROG_BASE = 10, 128, S(0x04)
OCT_TABLE, OCT_STRIDE, OCT_N = S(0xA8), 128, 8


def camel(s):
    """The same label-safe CamelCase rule round 4 used for record name fields."""
    out = re.sub(r"[^A-Za-z0-9]+", " ", s).strip()
    return "".join(p[0].upper() + p[1:] for p in out.split() if p) or "Unnamed"


def next_bound(a):
    return min(v for v in BOUNDS if v > a)


def array_records(slot):
    """The 43-byte records of one wave-select array, and where they start."""
    a = S(slot)
    b = next_bound(a)
    assert (b - a) % WAVESEL_STRIDE == 0, hex(slot)
    n = (b - a) // WAVESEL_STRIDE
    return a, n, [D[a + WAVESEL_STRIDE * i: a + WAVESEL_STRIDE * (i + 1)] for i in range(n)]


def _tone_end(p):
    """A tone record ends at the next tone pointer or the next directory bound."""
    return min([q for q in sorted(set(TONE_PTRS)) if q > p] + [x for x in BOUNDS if x > p])


def tone_wavesel_blocks():
    """[(tone index, element, 43 bytes, camel name)] for every ordinary tone record.

    The 217 + n*(81+43) geometry is round 3's, from prom_c's own `ld C,0x51` /
    `add XBC,0xd9`; a record whose size does not fit it (the 18 drum kits, the two
    drawbar records) carries no wave-select array and contributes nothing.
    """
    out = []
    for i, p in enumerate(TONE_PTRS):
        size = _tone_end(p) - p
        if size < 217 or (size - 217) % 124:
            continue
        n = (size - 217) // 124
        nm = camel(D[p:p + 16].decode("latin1"))
        for j in range(n):
            a = p + 217 + 81 * n + WAVESEL_STRIDE * j
            out.append((i, j, D[a:a + WAVESEL_STRIDE], nm))
    return out


def perc_wavesel_tails():
    """[(record index, 43 bytes, camel name)] for every drum-instrument record."""
    a = S(0x78)
    n = (next_bound(a) - a) // PERC_STRIDE
    off = PERC_STRIDE - WAVESEL_STRIDE
    return [(i, D[a + PERC_STRIDE * i + off: a + PERC_STRIDE * (i + 1)],
             camel(D[a + PERC_STRIDE * i: a + PERC_STRIDE * i + 13].decode("latin1")))
            for i in range(n)]


def _mask(b):
    """A wave-select record with the one field prom_c is KNOWN to rewrite removed.

    ⚠ This is the whole of the round-6 rule and it is not a free parameter: round
    5 proved +0x0B is a preset number that prom_c writes over (0xFBC7D6), so it is
    the one byte a copy of a record may legitimately differ in.  Q8a shows that
    excluding any OTHER single byte instead finds nothing.
    """
    return b[:PRESET_FIELD] + b[PRESET_FIELD + 1:]


# ---------------------------------------------------------------------------
# The round-6 result, in the form the generator consumes.
# ---------------------------------------------------------------------------
def wavesel_twins(slot):
    """{record index: [(owner index, element or None, camel name)]}.

    A "twin" is a record of the array at `slot` whose bytes equal a NAMED
    record's wave-select block outside field +0x0B.  Melodic owners are tone
    records and carry an element number; drum owners are drum-instrument records
    and do not.
    """
    _a, n, recs = array_records(slot)
    idx = collections.defaultdict(list)
    if slot == 0x20:
        for i, b, nm in perc_wavesel_tails():
            idx[_mask(b)].append((i, None, nm))
    else:
        for i, j, b, nm in tone_wavesel_blocks():
            idx[_mask(b)].append((i, j, nm))
    return dict((k, idx.get(_mask(recs[k]), [])) for k in range(n))


def _strip_digits(s):
    return re.sub(r"[0-9]+$", "", s)


def wavesel_labels(slot):
    """{record index: label suffix} for the records a twin NAMES.

    The suffix is DERIVED, never typed: it is the owner's own CamelCase name
    field, plus `_WaveSel<j>` when every twin agrees on the element.  A record
    whose twins disagree on the name gets NO label -- except when they differ
    only by a trailing digit ('RoomBassDrm1' / 'RoomBassDrm2'), where the shared
    stem is still one name.  Both counts are reported separately by Q3 so a
    reader can discount the second rule if they want to.
    """
    out = {}
    for k, tw in wavesel_twins(slot).items():
        if not tw:
            continue
        names = set(x[2] for x in tw)
        if len(names) == 1:
            base = names.pop()
        else:
            stems = set(_strip_digits(x) for x in names)
            if len(stems) != 1 or not stems.copy().pop():
                continue
            base = stems.pop()
        els = set(x[1] for x in tw)
        if len(els) == 1 and els.copy().pop() is not None:
            base += "_WaveSel%d" % els.copy().pop()
        # ⚠ A label whose last underscore-delimited part is bare digits reads as
        # POSITIONAL to notes/wave7_documentation_metrics.py and, more to the
        # point, to a human.  Round 5 hit exactly this with an organ registration
        # whose camel form is all digits.  Such a name is refused, not patched.
        if re.fullmatch(r"[0-9]{1,4}", base.split("_")[-1]):
            continue
        out[k] = base
    return out


def catalogue_alignment():
    """(resolvable, same index, different index, absent) for the +0x8C catalogue.

    ★ THE NUMBER ROUND 5's REFUSAL RESTS ON, said as a shape instead of a score.
    For each record of the +0x20 array that the byte identity names, where does
    that name sit in the 208-row catalogue at slot +0x8C -- the same row, another
    row, or nowhere?  The catalogue is compared in the SAME CamelCase form the
    labels use, so the two sides are commensurable.
    """
    lab = wavesel_labels(0x20)
    a = S(0x8C)
    n = len(array_records(0x20)[2])
    cat = [camel(D[a + 16 * i: a + 16 * i + 13].decode("latin1")) for i in range(n)]
    same = elsewhere = absent = 0
    for k, v in lab.items():
        stem = _strip_digits(v)
        hits = [i for i, c in enumerate(cat) if c in (v, stem)]
        if k in hits:
            same += 1
        elif hits:
            elsewhere += 1
        else:
            absent += 1
    return len(lab), same, elsewhere, absent


def octave_rows():
    """{bank row: [(program, signed semitones, tone name)]} for the +0xA8 table.

    Every nonzero cell of the 8 x 128 table, with the tone the program map puts
    at that (bank, program).  The tone name is what makes the reading checkable:
    the cells are not scattered, they are an instrument family.
    """
    out = {}
    for r in range(OCT_N):
        rec = D[OCT_TABLE + OCT_STRIDE * r: OCT_TABLE + OCT_STRIDE * (r + 1)]
        row = []
        for prog in range(OCT_STRIDE):
            if not rec[prog]:
                continue
            t = u16(PROG_BASE + 0x100 * r + 2 * prog)
            row.append((prog, rec[prog] - 256 if rec[prog] > 127 else rec[prog],
                        D[TONE_PTRS[t]:TONE_PTRS[t] + 16].decode("latin1").strip()))
        out[r] = row
    return out


OCT_SIBLING = 0xFDF22A      # prom_c's other-arm table, read at 0xFA737C


def oct_sibling():
    """The 16 signed bytes of prom_c's octave-select table at 0xFDF22A.

    It is the OTHER arm of the same routine that reads prom_d's +0xA8 table, and
    it is what fixes the units: every entry is a multiple of 12, entry 8 is 0.
    """
    o = OCT_SIBLING - PROM_C_BASE
    return [v - 256 if v > 127 else v for v in C[o:o + 16]]


# ★ THE SHAPES THE GENERATOR PINS.  Each is the audited value of a MEASUREMENT,
# not a constant the emitter needs: if the measurement moves, the emitter stops.
AUDITED_TWINS = {0x18: (322, 167, 152), 0x20: (208, 196, 141)}
AUDITED_OCTAVE = (8, 84, {-12: 79, 12: 5})
AUDITED_ALIGNMENT = (141, 61, 62, 18)
AUDITED_FRAMED = 614
AUDITED_PROMOTED = 301


def _twin_shape(slot):
    tw = wavesel_twins(slot)
    return len(tw), sum(1 for v in tw.values() if v), len(wavesel_labels(slot))


def _octave_shape():
    rows = octave_rows()
    cells = [c for r in rows.values() for c in r]
    return len(rows), len(cells), dict(collections.Counter(c[1] for c in cells))


# ---------------------------------------------------------------------------
# Q1.  THE EXHAUSTIVE CLASSIFICATION OF THE 614.
# ---------------------------------------------------------------------------
FRAMED_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)_(?:[0-9A-Fa-f]{4,6}|[0-9]{1,4}):$")
INTERNAL_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*__[0-9A-Fa-f]{4,6}:$")


# A label this round PROMOTED still has to be counted in the denominator, or the
# classification would shrink every time it succeeded.  These two patterns undo
# the promotion so the set being classified is the one round 5 actually left.
PROMOTED_TWIN = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*_[0-9]{1,4})_SameAs_[A-Za-z0-9_]+:$")
PROMOTED_OCT = re.compile(r"^ToneDB_OctaveShiftByProgram_Bank([0-9]):$")
# ⚠ ADDED IN WAVE 7 ROUND 11, AND IT REPAIRS A CHECK THAT HAD BEEN FAILING SINCE
# ROUND 10.  Q8d's whole point is that this denominator must NOT move when a
# later round promotes a label, and the two patterns above only mapped round 6's
# own `_SameAs_` promotions back.  Round 10 then promoted 29 records to
# `_SelectedFor_<tone>` and round 11 promoted 8 more to
# `_SelectedForGroup_<GROUP>`, so the set read back off the .s fell 614 -> 585 ->
# 577 and Q8d has been RED ever since -- a check nobody re-ran, which is the
# exact failure mode this file exists to catch.  The pattern below restores the
# round-5 denominator; the round-11 lane found it by running every prom_d script
# rather than only its own.
PROMOTED_SEL = re.compile(
    r"^([A-Za-z_][A-Za-z0-9_]*_[0-9]{1,4})_SelectedFor(?:Group)?_[A-Za-z0-9_]+:$")


def framed_labels():
    """The 614 labels round 5 left FRAMED, read back off prom_d/wsa1_prom_d.s.

    ⚠ Deliberately re-derived from the emitted file and not from this script's own
    model of the image: the number this round is judged on is the one
    notes/wave7_documentation_metrics.py reads, and a classification that counted
    its own intentions would be unfalsifiable.

    ⚠ AND IT IS THE ROUND-5 SET, not today's.  A label this round promoted no
    longer matches the framed pattern, so counting only what still matches would
    make the classification shrink in exact proportion to how well it worked --
    a denominator that moves with the result is not a denominator.  The two
    PROMOTED_ patterns map a promoted label back to the name it had.
    """
    out = []
    for ln in image_lines(ROOT, "prom_d/wsa1_prom_d.s"):
        if not ln or ln[0] in " \t;\n.":
            continue
        t = ln.strip()
        if INTERNAL_RE.match(t):
            continue
        m = PROMOTED_TWIN.match(t)
        if m:
            out.append(m.group(1))
            continue
        m = PROMOTED_OCT.match(t)
        if m:
            out.append("Unk_0FC8_Rec_%s" % m.group(1))
            continue
        m = PROMOTED_SEL.match(t)
        if m:
            out.append(m.group(1))
            continue
        if FRAMED_RE.match(t):
            out.append(t[:-1])
    return out


def classify():
    """[(label, verdict, reason)] for every framed label, one verdict each."""
    lab18, lab20 = wavesel_labels(0x18), wavesel_labels(0x20)
    tw18, tw20 = wavesel_twins(0x18), wavesel_twins(0x20)
    rows = []
    for name in framed_labels():
        stem, _, num = name.rpartition("_")
        k = int(num, 10) if num.isdigit() else None
        if stem == "ToneDB_MixerDefaultTable":
            if k in lab18:
                rows.append((name, "NAMED-BY-CONTENT",
                             "byte-identical outside +0x%02X to tone %s"
                             % (PRESET_FIELD, lab18[k])))
            elif tw18.get(k):
                rows.append((name, "NAMELESS-AMBIGUOUS",
                             "%d tone wave-select blocks carry these bytes, under %d "
                             "different names" % (len(tw18[k]),
                                                  len(set(x[2] for x in tw18[k])))))
            else:
                rows.append((name, "NAMELESS-NO-TWIN",
                             "no tone wave-select block is within one byte of it"))
        elif stem == "ToneDB_PercMixerDefaultTable":
            if k in lab20:
                rows.append((name, "NAMED-BY-CONTENT",
                             "byte-identical to the wave-select tail of drum "
                             "instrument %s" % lab20[k]))
            elif tw20.get(k):
                rows.append((name, "NAMELESS-AMBIGUOUS",
                             "%d drum-instrument records carry these bytes, under %d "
                             "different names" % (len(tw20[k]),
                                                  len(set(x[2] for x in tw20[k])))))
            else:
                rows.append((name, "NAMELESS-NO-TWIN",
                             "no drum-instrument record carries these bytes"))
        elif stem == "ToneDB_WaveSelTailPresets":
            rows.append((name, "NAMELESS-NUMBER-IS-THE-MEANING",
                         "the suffix IS the 6-bit preset number prom_c indexes by "
                         "(round 5 Q7); it replaces a tail only, so it has no head "
                         "to match a named record with (Q6b: min distance 6)"))
        elif stem == "ToneNumBank_Melodic":
            rows.append((name, "NAMELESS-UNDIFFERENTIATED",
                         "round 5 Q2: rows 0-7 all select melodic tones only and "
                         "nothing in the image says what the variation between them "
                         "means.  The BankMap at 0x%05X maps bank-select value r to "
                         "row r, which is what the suffix already says" % S(0x6C)))
        elif stem == "Unk_0FC8_Rec":
            rows.append((name, "NAMED-BY-READER",
                         "Q4: prom_c sub_FA72E9 indexes this table by bank*128 + "
                         "program and returns the value as a pitch offset"))
        elif stem == "DrawbarPreset_EnvDescTable_Pool":
            rows.append((name, "NAMELESS-REFUSED",
                         "round 4 Q4 / round 5 Q4a: these pool objects do NOT obey "
                         "the three-stage index chain that names the other pools, "
                         "0 of 3.  Refusal kept"))
        elif stem == "ToneRec_05D":
            rows.append((name, "METRIC-ARTEFACT",
                         "round 5 Q1e: this record IS named from its own bytes, "
                         "\"    16' & 1'    \", whose camel form is all digits"))
        else:
            rows.append((name, "UNCLASSIFIED", "round 6 has no verdict for this stem"))
    return rows


def q1():
    say("\n=== Q1.  ALL %d FRAMED LABELS, CLASSIFIED, ONE VERDICT EACH ===\n"
        % AUDITED_FRAMED)
    rows = classify()
    by = collections.Counter(v for _n, v, _r in rows)
    for verdict, n in by.most_common():
        ex = next(r for r in rows if r[1] == verdict)
        say("  %-32s %4d   e.g. %s" % (verdict, n, ex[0]))
        say("  %-32s        %s" % ("", ex[2][:90]))
    check("Q1a  the classification is exhaustive -- every framed label has a verdict",
          by.get("UNCLASSIFIED", 0) == 0, "%d unclassified" % by.get("UNCLASSIFIED", 0))
    check("Q1b  and it partitions: the verdicts sum to the framed count",
          sum(by.values()) == len(rows), "%d verdicts over %d labels"
          % (sum(by.values()), len(rows)))
    named = by.get("NAMED-BY-CONTENT", 0) + by.get("NAMED-BY-READER", 0)
    say("")
    say("  ★ %d of the %d are NAMEABLE and %d are not, and the second number is the"
        % (named, len(rows), len(rows) - named))
    say("    answer this lane was asked for, not a shortfall: %d records carry bytes"
        % by.get("NAMELESS-NO-TWIN", 0))
    say("    that no named record in the image carries, %d carry bytes that more than"
        % by.get("NAMELESS-AMBIGUOUS", 0))
    say("    one differently-named record carries, and %d more are refusals or"
        % (by.get("NAMELESS-NUMBER-IS-THE-MEANING", 0)
           + by.get("NAMELESS-UNDIFFERENTIATED", 0) + by.get("NAMELESS-REFUSED", 0)
           + by.get("METRIC-ARTEFACT", 0)))
    say("    statements that a number is already the meaning.")
    # the LAST element as well as the first -- the rule this tree is graded on
    check("Q1c  the FIRST and the LAST framed label both carry a verdict",
          rows[0][1] != "UNCLASSIFIED" and rows[-1][1] != "UNCLASSIFIED",
          "first %s -> %s; last %s -> %s"
          % (rows[0][0], rows[0][1], rows[-1][0], rows[-1][1]))
    return rows


# ---------------------------------------------------------------------------
# Q2.  THE MELODIC TWINS.
# ---------------------------------------------------------------------------
def q2():
    say("\n=== Q2.  THE 322 RECORDS AT SLOT +0x18 vs THE TONE RECORDS' OWN "
        "WAVE-SELECT BLOCKS ===\n")
    ws = tone_wavesel_blocks()
    _a, n, recs = array_records(0x18)
    check("Q2a  tone wave-select blocks available to match against", len(ws) == 451,
          "%d blocks over %d tone records with the 217+n*(81+43) geometry"
          % (len(ws), len(set(t for t, _j, _b, _n in ws))))
    # the DECISIVE measurement: minimum Hamming distance and WHERE the byte falls
    hist = collections.Counter()
    pos = collections.Counter()
    for r in recs:
        best, bpos = WAVESEL_STRIDE + 1, None
        for _i, _j, b, _nm in ws:
            h = sum(1 for x, y in zip(r, b) if x != y)
            if h < best:
                best, bpos = h, [k for k in range(WAVESEL_STRIDE) if r[k] != b[k]]
        hist[best] += 1
        if best == 1:
            pos[bpos[0]] += 1
    check("Q2b  records at Hamming distance EXACTLY 1 from some tone block",
          hist[1] == 167, "%d of %d" % (hist[1], n))
    check("Q2c  ★ and the differing byte is +0x%02X in ALL of them" % PRESET_FIELD,
          list(pos.items()) == [(PRESET_FIELD, hist[1])],
          "positions seen: %s" % dict(pos))
    check("Q2d  no record is at distance 0 -- round 5's 'no copy anywhere' was right",
          hist[0] == 0, "the zero it reported is reproduced here")
    say("      distance histogram, all %d records: %s"
        % (n, dict(sorted(hist.items())[:8])))
    # what the twin says about the preset field, from both sides
    side_a = collections.Counter()
    side_b = collections.Counter()
    tw = wavesel_twins(0x18)
    for k, t in tw.items():
        if not t:
            continue
        side_a[recs[k][PRESET_FIELD]] += 1
        for i, j, _nm in t:
            for i2, j2, b, _n2 in ws:
                if (i2, j2) == (i, j):
                    side_b[b[PRESET_FIELD]] += 1
    check("Q2e  the tone side's +0x%02X is 0 in nearly every twin" % PRESET_FIELD,
          side_b[0] >= 0.99 * sum(side_b.values()),
          "tone side %s ; array side %s"
          % (dict(sorted(side_b.items())), dict(sorted(side_a.items()))))
    say("      ★ which is round 5's semantic seen from the data: 0 means 'no preset',")
    say("        and the copies in this array carry a NONZERO preset number.")
    lab = wavesel_labels(0x18)
    check("Q2f  twins that resolve to exactly ONE tone name, so a label is possible",
          len(lab) == 152, "%d of %d matched; %d matched but under several names"
          % (len(lab), hist[1], hist[1] - len(lab)))
    say("      first: %s -> %s" % (min(lab), lab[min(lab)]))
    say("      last:  %s -> %s" % (max(lab), lab[max(lab)]))


def q2b():
    say("\n=== Q2b.  THE SECOND WITNESS -- the 1,024-entry map at slot +0x0C ===\n")
    maps = [s for s in range(0, 0xB8, 4)
            if S(s) != 0xFFFFFFFF and next_bound(S(s)) - S(s) == 2048]
    ranges = {}
    for s in maps:
        v = [u16(S(s) + 2 * i) for i in range(1024)]
        real = [x for x in v if x != 0xFFFF]
        ranges[s] = (min(real), max(real))
    _a, n18, _r = array_records(0x18)
    reach = [s for s in maps if ranges[s][1] == n18 - 1]
    check("Q2b1  maps whose range reaches %d, this array's last index" % (n18 - 1),
          reach == [0x0C], "slots %s of %d maps of 1,024 entries"
          % (["+0x%02X" % s for s in reach], len(maps)))
    tw = wavesel_twins(0x18)
    matched = set(k for k, v in tw.items() if v)
    prog = [[u16(PROG_BASE + 0x100 * r + 2 * p) for p in range(PROG_COLS)]
            for r in range(PROG_ROWS)]

    def agreement(vals):
        tot = ok = 0
        for r in range(8):
            for p in range(PROG_COLS):
                k = vals[r * PROG_COLS + p]
                if k not in matched:
                    continue
                tot += 1
                if any(t == prog[r][p] for t, _j, _nm in tw[k]):
                    ok += 1
        return tot, ok

    m0c = [u16(S(0x0C) + 2 * i) for i in range(1024)]
    tot, ok = agreement(m0c)
    check("Q2b2  map +0x0C entries landing on a matched record, and the tone agreeing",
          tot == 911 and ok == 637, "%d entries, %d agree (%.1f%%)"
          % (tot, ok, 100.0 * ok / tot))
    worst = 0.0
    for s in maps:
        if s == 0x0C:
            continue
        t2, o2 = agreement([u16(S(s) + 2 * i) for i in range(1024)])
        if t2:
            worst = max(worst, 100.0 * o2 / t2)
    check("Q2b3  NULL: the best of the other %d maps scores far lower" % (len(maps) - 1),
          worst < 5.0, "best other map %.1f%% against +0x0C's %.1f%%"
          % (worst, 100.0 * ok / tot))
    rnd = random.Random(20260830)
    sh = []
    for _t in range(3):
        perm = list(range(1024))
        rnd.shuffle(perm)
        t3, o3 = agreement([m0c[i] for i in perm])
        sh.append(100.0 * o3 / t3 if t3 else 0.0)
    check("Q2b4  NULL: shuffling map +0x0C destroys the agreement",
          max(sh) < 5.0, "shuffled: %s" % ", ".join("%.1f%%" % x for x in sh))
    say("")
    say("  ⚠ 69.9% is not 100% and NO label is changed on it.  The map is one entry")
    say("    per PROGRAM and a tone has up to four elements, so a single entry cannot")
    say("    name all of a tone's records.  This is corroboration for the Q2 names,")
    say("    and the slot +0x0C banner is NOT renamed on it.")


# ---------------------------------------------------------------------------
# Q3.  THE DRUM TWINS, AND WHY THE CATALOGUE DISAGREES.
# ---------------------------------------------------------------------------
def q3():
    say("\n=== Q3.  THE 208 RECORDS AT SLOT +0x20 vs THE DRUM-INSTRUMENT RECORDS ===\n")
    tails = perc_wavesel_tails()
    _a, n, recs = array_records(0x20)
    exact = collections.defaultdict(list)
    for i, b, nm in tails:
        exact[b].append(nm)
    nex = sum(1 for r in recs if r in exact)
    tw = wavesel_twins(0x20)
    check("Q3a  records BYTE-IDENTICAL to a drum-instrument wave-select tail",
          nex == 196, "%d of %d" % (nex, n))
    check("Q3b  and the +0x%02X-blind rule finds the same set, so the drum side needs"
          " no allowance" % PRESET_FIELD,
          sum(1 for v in tw.values() if v) == nex,
          "%d under the Q2 rule" % sum(1 for v in tw.values() if v))
    lab = wavesel_labels(0x20)
    uniq = sum(1 for k, v in tw.items() if v and len(set(x[2] for x in v)) == 1)
    check("Q3c  twins resolving to ONE name outright", uniq == 106, "%d" % uniq)
    check("Q3d  plus twins whose names differ only by a trailing digit", 
          len(lab) - uniq == 35, "%d ('RoomBassDrm1'/'RoomBassDrm2' -> 'RoomBassDrm')"
          % (len(lab) - uniq))
    say("      first: %s -> %s" % (min(lab), lab[min(lab)]))
    say("      last:  %s -> %s" % (max(lab), lab[max(lab)]))
    # ★ Q3e: the round-5 contradiction, explained rather than only restated.
    cat_at = S(0x8C)
    res, same, elsewhere, absent = catalogue_alignment()
    check("Q3e  ★ the catalogue at +0x8C is a DIFFERENT LIST, not a wrong one",
          same + elsewhere + absent == res == AUDITED_ALIGNMENT[0]
          and (same, elsewhere, absent) == AUDITED_ALIGNMENT[1:],
          "of %d resolvable rows: %d agree at the same index, %d carry the name at a "
          "DIFFERENT index, %d name something the drum records do not have"
          % (res, same, elsewhere, absent))
    say("      catalogue row 1 is %r where the identical bytes come from %r;"
        % (D[cat_at + 16: cat_at + 29].decode("latin1").strip(),
           next(x[2] for x in tw[1])))
    say("      rows 7 and 8 are %r and %r, while array record 7 matches NOTHING and"
        % (D[cat_at + 7 * 16: cat_at + 7 * 16 + 13].decode("latin1").strip(),
           D[cat_at + 8 * 16: cat_at + 8 * 16 + 13].decode("latin1").strip()))
    say("      record 8 matches %s.  So the two lists carry different rows, which is"
        % "/".join(sorted(set(x[2] for x in tw[8]))))
    say("      what round 5 measured as a disagreement.  The POSITIONAL transfer stays")
    say("      REFUSED; the byte identity is what the labels use, and it is an")
    say("      identity of CONTENT, which is why every label says `SameAs`.")


# ---------------------------------------------------------------------------
# Q4.  THE OCTAVE TABLE -- a block named by its READER.
# ---------------------------------------------------------------------------
def q4():
    say("\n=== Q4.  Unk_0FC8_Table IS AN OCTAVE-SHIFT TABLE ===\n")
    sib = oct_sibling()
    check("Q4a  prom_c's sibling table at 0x%06X is 16 entries, ALL multiples of 12"
          % OCT_SIBLING, len(sib) == 16 and all(v % 12 == 0 for v in sib),
          "%s" % sib)
    check("Q4b  and it is centred: entry 8 is 0, the ends are -96 and +84",
          sib[8] == 0 and sib[0] == -96 and sib[15] == 84,
          "an octave-select field, `and C,0x0f` at 0xFA7375")
    rows = octave_rows()
    cells = [c for r in rows.values() for c in r]
    vals = collections.Counter(c[1] for c in cells)
    check("Q4c  prom_d's table holds ONLY the same two magnitudes",
          set(vals) == {-12, 12}, "%d nonzero cells: %s" % (len(cells), dict(vals)))
    check("Q4d  the table is %d records of %d bytes, and %d is the program map's width"
          % (OCT_N, OCT_STRIDE, PROG_COLS),
          OCT_TABLE + OCT_N * OCT_STRIDE == min(TONE_PTRS) and OCT_STRIDE == PROG_COLS,
          "0x%05X..0x%05X -- the low end is directory slot +0xA8 and the high end is "
          "the FIRST tone record, 0x%05X; prom_c's 0xFA7351 `sll 0x07,BC` scales by %d"
          % (OCT_TABLE, OCT_TABLE + OCT_N * OCT_STRIDE - 1, min(TONE_PTRS), OCT_STRIDE))
    # ★ the reading is checkable because the marked cells name themselves
    organ = [c for c in cells if 88 <= c[0] <= 95]
    check("Q4e  ★ programs 88-95 of EVERY bank are marked, and they are the organ "
          "family", len(organ) == 8 * 8,
          "%d cells; e.g. %s" % (len(organ), ", ".join(sorted(set(c[2] for c in organ))[:4])))
    other = sorted(set((c[0], c[1], c[2]) for c in cells if not 88 <= c[0] <= 95))
    check("Q4f  and every OTHER marked program is an octave instrument too",
          set(c[0] for c in other) == {14, 122, 126},
          "; ".join("prog %d %+d %r" % (p, v, nm) for p, v, nm in other[:6]))
    check("Q4g  the ONLY +12 in the table is program 122", 
          set(c[1] for c in cells if c[0] == 122) == {12}
          and all(c[1] == -12 for c in cells if c[0] != 122),
          "%r, and %d banks carry it"
          % (next(c[2] for c in cells if c[0] == 122),
             sum(1 for r in rows.values() if any(c[0] == 122 for c in r))))
    # ★ The two shifts, re-decoded from prom_c's ROM BYTES rather than taken on the
    # word of the .s listing.  They differ in ONE byte, the shift count, which is
    # what makes the pair a check rather than two assertions: `sll 0x07,BC` scales
    # the bank into the table and `sll 0x08,BC` is the value's own encoding.
    b7 = C[0xFA7351 - PROM_C_BASE: 0xFA7351 - PROM_C_BASE + 3]
    b8 = C[0xFA735F - PROM_C_BASE: 0xFA735F - PROM_C_BASE + 3]
    check("Q4h  0xFA7351 is `sll 0x07,BC` in prom_c's BYTES", b7 == b"\xd9\xee\x07",
          "bytes %s" % b7.hex())
    check("Q4i  0xFA735F is the SAME opcode with count 8 -- `sll 0x08,BC`",
          b8 == b7[:2] + b"\x08", "bytes %s, differing from 0xFA7351 in the count only"
          % b8.hex())
    say("")
    say("  ★ AND THAT SHIFT IS WHY A BYTE TABLE IS READ WITH A WORD INSTRUCTION.")
    say("    0xFA735D `ld BC,(XIY)` loads 16 bits and 0xFA735F shifts left 8, so the")
    say("    HIGH byte of the word is discarded.  The other arm does `ld A,(XBC)` /")
    say("    `exts WA` / `sll 0x08,WA` on the sibling table -- the same value in the")
    say("    same place.  Both arms return a pitch offset to Voice_ComputePitch.")
    say("  ⚠ NOT established: the numeric unit.  What is measured is that the two")
    say("    arms encode identically and that prom_c's arm holds only multiples of 12.")


# ---------------------------------------------------------------------------
# Q5.  THE REFUSALS, RE-MEASURED.
# ---------------------------------------------------------------------------
def q5():
    say("\n=== Q5.  THE REFUSALS, KEPT ===\n")
    import importlib.util as ilu
    spec = ilu.spec_from_file_location(
        "prom_d_understanding_round5",
        os.path.join(ROOT, "notes", "prom_d_understanding_round5.py"))
    r5 = ilu.module_from_spec(spec)
    saved, sys.argv = sys.argv, ["prom_d_understanding_round5", "--quiet"]
    try:
        spec.loader.exec_module(r5)
    finally:
        sys.argv = saved
    ov = r5.perc_overlap()
    check("Q5a  round 5's slot +0x20 / drum overlap shape is unchanged",
          ov == r5.AUDITED_PERC, "%s" % (ov,))
    idx = r5.wavesel_preset_index()
    check("Q5b  round 5's +0x3C self-index shape is unchanged",
          idx == r5.AUDITED_SELFIDX, "%s" % (idx,))
    say("  Q5c  slot +0x70's three pool objects: still refused (round 4 Q4, 0 of 3).")
    say("  Q5d  the 161 perc catalogue transfer: still refused (maps agree 988/1024).")
    say("  Q5e  the POSITIONAL transfer from the +0x8C catalogue: still refused; Q3e")
    say("       now says WHY it disagrees rather than only that it does.")


# ---------------------------------------------------------------------------
# Q6.  MECHANISMS MEASURED AND REJECTED.
# ---------------------------------------------------------------------------
def q6():
    say("\n=== Q6.  TWO MECHANISMS REJECTED, recorded so they are not re-invented ===\n")
    say("  Q6a  REJECTED: renaming `ToneDB_WaveSelTailPresets_063` to `..._Preset63`.")
    say("       It moves 64 labels from framed to content on the goal metric and adds")
    say("       NOTHING a reader did not have: the number already means the preset")
    say("       number (round 5 Q7) and the word Preset is already in the block name.")
    say("       A metric that moves when you rewrite a suffix is measuring the suffix.")
    ws = tone_wavesel_blocks()
    _a, _n, presets = array_records(0x3C)
    best = []
    for r in presets:
        best.append(min(sum(1 for x, y in zip(r, b) if x != y) for _i, _j, b, _nm in ws))
    check("Q6b  REJECTED: naming the 64 presets from a tone block they match",
          min(best) >= 6, "closest of the 64 is at Hamming distance %d; %d are at 0 or 1"
          % (min(best), sum(1 for x in best if x <= 1)))
    say("       A preset supplies bytes 13..42 only, so it has no 13-byte head to")
    say("       match a whole record with.  The Q2 mechanism does not reach them and")
    say("       saying so is the answer.")


# ---------------------------------------------------------------------------
# Q7.  THE BASE-ADDRESS SEARCH, EXTENDED.
# ---------------------------------------------------------------------------
BASE_SLOTS = (0x00D7ED, 0x00D7F1)


def base_adds():
    """prom_c instruction lines that ADD prom_d's base to a computed value.

    Each one is positive evidence for ORIGIN 0: a value that must have the base
    added to it is a FILE OFFSET, not an address.  Read off the converted
    assembly, which is byte-identical to the ROM by the gate.
    """
    out = []
    pat = re.compile(r"^\s*add\S*\s+\S+,\s*\(0x(D7ED|D7F1)\)", re.I)
    for ln in image_lines(ROOT, "prom_c/wsa1_prom_c.s"):
        if pat.match(ln):
            m = re.search(r";\s*([0-9A-F]{6})", ln)
            out.append((int(m.group(1), 16) if m else None, ln.strip()))
    return out


def q7():
    say("\n=== Q7.  THE BASE ADDRESS -- the search that could have moved ORIGIN ===\n")
    say("  Round 5 Q5 searched prom_c's instructions for an ABSOLUTE prom_d address")
    say("  and found exactly one literal in 0x00F00000-0x00F7FFFF: the base itself at")
    say("  0xFB051E.  That is an ABSENCE.  Round 6 adds the converse, which is not.")
    adds = base_adds()
    check("Q7a  prom_c instructions that ADD prom_d's base to a computed value",
          len(adds) == 46, "%d `add <Xrr>,(0x00D7ED|0x00D7F1)`" % len(adds))
    pages = sorted(set(a >> 12 for a, _l in adds if a))
    check("Q7b  and they are spread over the image, not one routine", len(pages) == 6,
          "%d distinct 4 KiB pages: %s"
          % (len(pages), ", ".join("0x%03X" % p for p in pages)))
    say("      first 0x%06X, last 0x%06X" % (adds[0][0], adds[-1][0]))
    say("")
    say("  ★ AND Q4 IS THE CONTENT-LEVEL TIE THE ROUND-6 BRIEF ASKED FOR.  0xFA7332")
    say("    reads directory slot +0xA8, 0xFA7351 scales an index by 128, 0xFA7358")
    say("    adds the base, and the bytes at the resulting FILE OFFSETS are a")
    say("    coherent octave table whose marked cells are named by the program map at")
    say("    slot +0x04.  If the directory held addresses rather than offsets, that")
    say("    add would double the base and the cells would land in the erased tail.")
    say("")
    say("  ⚠ ORIGIN in prom_d/prom_d.ld is NOT changed and nothing here proposes")
    say("    changing it.  What round 6 rules out is the same thing round 5 ruled")
    say("    out, by a second and opposite route: prom_d holds no absolute addresses")
    say("    and prom_c treats every value it reads out of prom_d as an offset.")
    say("  ⚠ THE LIMIT IS UNCHANGED: the 65,972-byte byte-code stream at")
    say("    0xFCD0F7-0xFDD2AA is emitted as .byte, and a pointer hidden in it would")
    say("    not be seen by either search.")


# ---------------------------------------------------------------------------
# Q8.  NULLS.
# ---------------------------------------------------------------------------
def q8():
    say("\n=== Q8.  NULLS -- so Q2, Q3 and Q4 can fail ===\n")
    ws = tone_wavesel_blocks()
    _a, n, recs = array_records(0x18)
    # (a) the mask is not a free parameter: any OTHER single-byte allowance finds 0
    idx_by_pos = {}
    for skip in range(WAVESEL_STRIDE):
        s = set(b[:skip] + b[skip + 1:] for _i, _j, b, _nm in ws)
        idx_by_pos[skip] = sum(1 for r in recs if (r[:skip] + r[skip + 1:]) in s)
    others = max(v for k, v in idx_by_pos.items() if k != PRESET_FIELD)
    check("Q8a  NULL: excluding any byte OTHER than +0x%02X finds far fewer twins"
          % PRESET_FIELD, others == 0,
          "best other position scores %d against +0x%02X's %d"
          % (others, PRESET_FIELD, idx_by_pos[PRESET_FIELD]))
    # (b) random windows of the payload must not match
    rnd = random.Random(20260830)
    # ⚠ The null corpus must exclude BOTH sets, or a random window that lands on a
    # tone's own wave-select block counts as a false positive of the mechanism when
    # it is really a true positive of the corpus.  Excluding only the array scored
    # 3 of 3,000 for exactly that reason.
    excl = set(range(S(0x18), S(0x18) + n * WAVESEL_STRIDE))
    for _i, _j, _b, _nm in ws:
        pass
    for i, p in enumerate(TONE_PTRS):
        size = _tone_end(p) - p
        if size < 217 or (size - 217) % 124:
            continue
        k = (size - 217) // 124
        excl |= set(range(p + 217 + 81 * k, p + size))
    sset = set(_mask(b) for _i, _j, b, _nm in ws)
    hits = tot = 0
    while tot < 3000:
        o = rnd.randrange(0, PAYLOAD_END - WAVESEL_STRIDE)
        if any(x in excl for x in (o, o + WAVESEL_STRIDE - 1)):
            continue
        tot += 1
        if _mask(D[o:o + WAVESEL_STRIDE]) in sset:
            hits += 1
    check("Q8b  NULL: random 43-byte windows of the payload matching the same rule",
          hits == 0, "%d of %d, with both the array and the tone blocks excluded"
          % (hits, tot))
    # (c) ★ THE NULL FOR Q4, and the first draft of it was WRONG in a way worth
    # recording: it counted how many marked cells name a tone with 'Organ' in it and
    # compared that against the same count with the program index shifted.  A shift
    # of 1-3 still lands inside the organ family, so the null scored HIGHER than the
    # real reading and the check failed while the finding was right.  A null that
    # slides along a run cannot test a run.  What follows tests the SHAPE instead.
    rows = octave_rows()
    cells = [(r, p) for r, v in rows.items() for p, _s, _n in v]
    cols = set(p for _r, p in cells)
    # If the second index were unrelated to the program, the 85 marks would not
    # line up in columns.  Placing 85 marks at random in 8 x 128 fills ~63 columns.
    exp = PROG_COLS * (1.0 - (1.0 - 1.0 / PROG_COLS) ** len(cells))
    check("Q8c  NULL: the %d marks fall in %d columns, not the ~%d of a random table"
          % (len(cells), len(cols), round(exp)),
          len(cols) * 3 < exp,
          "columns %s -- every bank marks the same programs, which is what an index "
          "BY PROGRAM predicts and a scattered index does not" % sorted(cols))
    # (c2) and the within-record index cannot be a TONE index: it would not fit.
    check("Q8c2 NULL: the second index cannot be a tone index -- it would not fit",
          len(TONE_PTRS) > OCT_STRIDE,
          "a tone index runs 0..%d and the record is %d bytes, so %d of the %d tones "
          "would address the NEXT bank's record; a program number is 0..%d and fits "
          "exactly" % (len(TONE_PTRS) - 1, OCT_STRIDE, len(TONE_PTRS) - OCT_STRIDE,
                       len(TONE_PTRS), OCT_STRIDE - 1))
    # (d) the classification's own denominator
    fr = framed_labels()
    check("Q8d  the round-5 framed set read back off the .s is still %d labels"
          % AUDITED_FRAMED, len(fr) == AUDITED_FRAMED and len(set(fr)) == AUDITED_FRAMED,
          "%d labels, %d distinct -- the count does NOT move when a label is promoted"
          % (len(fr), len(set(fr))))
    still = sum(1 for _n, v, _r in classify() if v.startswith("NAMELESS")
                or v == "METRIC-ARTEFACT")
    # ⚠ REWORDED IN ROUND 11.  This check used to say "what the metric should NOW
    # read", and that sentence went stale the moment round 7 promoted anything:
    # it is round 6's OWN arithmetic over round 6's OWN classification, and the
    # live figure has since fallen much further.  Both are printed so neither can
    # be mistaken for the other.
    _live = sum(1 for ln in image_lines(ROOT, "prom_d/wsa1_prom_d.s")
                if ln and ln[0] not in " \t;\n." and not INTERNAL_RE.match(ln.strip())
                and FRAMED_RE.match(ln.strip()))
    check("Q8d2 and what the metric read for prom_d after ROUND 6 is that minus "
          "round 6's own promotions", still == AUDITED_FRAMED - AUDITED_PROMOTED,
          "%d framed after round 6, from %d - %d; the LIVE figure is now %d, "
          "because rounds 7-11 promoted %d more"
          % (still, AUDITED_FRAMED, AUDITED_PROMOTED, _live,
             AUDITED_FRAMED - AUDITED_PROMOTED - _live))


# ---------------------------------------------------------------------------
# Q9.  THE TWO CHECKS THE ROUND-3 REVIEWERS HAD TO MAKE BY HAND.
# ---------------------------------------------------------------------------
CITED_PROM_C = (0xFA72E9, 0xFA7301, 0xFA7332, 0xFA734A, 0xFA7351, 0xFA7356,
                0xFA7358, 0xFA735D, 0xFA735F, 0xFA7375, 0xFA737C, 0xFA7F7A,
                0xFB051E, 0xFBC744, 0xFBC7D6)


def q9():
    say("\n=== Q9.  THE TWO CHECKS ROUND 3'S REVIEWERS HAD TO MAKE BY HAND ===\n")
    # (a) an INVENTED MORPHEME.  Round 3 shipped five prom_a labels built on
    # "Home", a word that occurs ZERO times in all four images.  The one word this
    # round introduces that is not copied verbatim out of a record's name field is
    # "Octave", so it is the one to check.
    hits = {}
    for tag, fn in (("prom_a", "wsa1_prom_a.ic12"), ("prom_b", "wsa1_prom_b.ic13"),
                    ("prom_c", "wsa1_prom_c.ic28"), ("prom_d", "wsa1_prom_d.bin")):
        blob = open(os.path.join(ROOT, "original_ROMs", fn), "rb").read()
        hits[tag] = blob.count(b"ctave") + blob.count(b"CTAVE")
    check("Q9a  the morpheme 'Octave' is IN the images, not invented",
          hits["prom_d"] == 2 and sum(hits.values()) == 7,
          "occurrences: %s -- prom_d's two are the tone names ' Octave Strings ' at "
          "0x08521 and '  Octave Brass  ' at 0x0E412; prom_b's four and prom_a's one "
          "are the UI spelling OCTAVE" % hits)
    # (b) a CITATION ONE BYTE PAST THE INSTRUCTION.  Round 1 shipped 31 of those.
    # Every prom_c address this round quotes must be the START of an instruction,
    # which the gate-verified listing settles: it prints the address of each.
    src = image_text(ROOT, "prom_c/wsa1_prom_c.s")
    starts = set(int(m, 16) for m in re.findall(r";\s+([0-9A-F]{6})\s+\S", src))
    bad = [a for a in CITED_PROM_C if a not in starts]
    check("Q9b  every prom_c address this round cites is an INSTRUCTION START",
          not bad, "%d cited, %d not a listed instruction address%s"
          % (len(CITED_PROM_C), len(bad),
             ": " + ", ".join("0x%06X" % a for a in bad) if bad else ""))
    # ⚠ The round-1 bug's signature was a citation whose PREDECESSOR byte was an
    # opcode.  Here cited-1 is also an instruction start for two of the fifteen,
    # which is legal (a one-byte opcode precedes them) and is listed rather than
    # hidden -- a check that cannot fail is not a pass, so this is a statement.
    off = [a for a in CITED_PROM_C if (a - 1) in starts]
    say("  Q9c  %d of the %d cited addresses have an instruction starting at cited-1 "
        "as" % (len(off), len(CITED_PROM_C)))
    say("       well: %s.  That is legal -- a one-byte opcode precedes them -- and it"
        % (", ".join("0x%06X" % a for a in off) or "none"))
    say("       is listed rather than hidden, because it is the shape round 1's 31")
    say("       one-byte-off citations had.  Q9b is the check; this is the detail.")


def main():
    say("prom_d round 6 -- can the 614 be named?  %d of them can." % AUDITED_PROMOTED)
    q1()
    q2()
    q2b()
    q3()
    q4()
    q5()
    q6()
    q7()
    q8()
    q9()
    print("\n%d checks, %d failed." % (NCHECK[0], len(FAILED)))
    for f in FAILED:
        print("  FAILED: %s" % f)
    return 1 if FAILED else 0


if __name__ == "__main__":
    sys.exit(main())
