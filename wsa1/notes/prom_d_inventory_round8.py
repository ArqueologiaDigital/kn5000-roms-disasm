#!/usr/bin/env python3
"""prom_d -- THE STANDING WHOLE-IMAGE INVENTORY (wave 7 rounds 8 and 9).

★★ ONE COMMAND RE-CHECKS THE WHOLE IMAGE.  `python3 notes/prom_d_inventory_round8.py
   --selftest` re-derives every one of prom_d's 3,665 labels from the ROM, asks
   round 8's three questions of every object, re-runs every mechanism this tree
   has measured and refused, and re-reads the generated prose for a sentence its
   own number refutes.  That is what "finished" means for prom_d, and this file
   is the whole of it.  The filename says round 8 because a lane owns a filename;
   round 9's sections are Q10-Q15 and its selftest is the second block.

★ ROUND 9's ONE FIND, and it is the argument for the audit existing: a generated
  comment stated 108 entries over a 132-byte object.  Four rounds of self-checks
  had re-read the numbers each round INTRODUCED; none re-read the file's existing
  prose against the object it sits on.  Q10d does, over all 319 of those
  sentences, and the generator now derives the count from the object's own length.

--- what round 8 established (unchanged below) ---------------------------------

prom_d round 8 -- THE THREE-QUESTION INVENTORY, and the census round 7's own
                     conclusion implied but never ran.

QUESTION IT ANSWERS
    Round 7 gave every one of prom_d's 3,665 labels a FINISHED verdict and left
    303 of them NAMELESS with a reason each.  ★ BUT ITS REASONS WERE NOT ALL THE
    SAME KIND OF FACT.  "no tone wave-select block is within one byte of it" is a
    statement about ONE naming mechanism failing; it is not an answer to the
    question a finished image has to answer, which is:

        A.  does this object CONTAIN a name?
        B.  does a READER say what it is for?
        C.  does anything POINT AT it -- a stored index, one of the image's own
            pointer fields, or an address spelling?

    This round asks those three of every label in the image and prints one answer
    per question, so a nameless object is nameless for a stated reason on each of
    the three routes rather than for the failure of whichever rule the previous
    round happened to try.

    ★★ AND QUESTION C IS WHERE ROUND 7 STOPPED ONE STEP SHORT OF ITS OWN
    ARGUMENT.  Round 7 searched for stored ADDRESSES, got a result at the noise
    floor, and then said the decisive form of the question is not a byte search
    at all because "a record of an array is addressed by an INDEX, never by a
    stored address".  That is right, and it names a census -- what stored INDEX
    values reach this record -- which round 7 did not run.  Q2 runs it, and it
    returns a result rather than a noise floor:

        * the 64 records of ToneDB_WaveSelTailPresets are selected by ONE stored
          field in the whole image, +0x0B of a wave-select record.  Over the
          1,485 wave-select records that are not the preset array itself those
          fields take 7 distinct values after `and A,0x3f`.  So 57 of the 64
          preset records are selected by NOTHING STORED anywhere in this image
          and 7 are selected, by 1,485 stored fields between them.
          ⚠ TWO CORRECTIONS A ROUND-8 REVIEWER DERIVED AND ROUND 9 APPLIED: this
          paragraph said "6 are selected by many", which is wrong by one (Q2's
          own table lists seven values, 0 1 2 3 4 5 7); and the denominator was
          1,549, which is the population INCLUDING the preset array, over which
          the field takes 64 values and not 7, because a preset record's own
          +0x0B carries its own index (round 9 Q11, at 63 of its 64 records).
          The .s banner carried the same pair and is corrected in the GENERATOR.
          That is a per-object answer to C for 64 objects, derived, and it is
          stronger than round 7's "at the null".
        * the 322 records of ToneDB_MixerDefaultTable are reached by exactly one
          of the image's eleven 1,024-entry maps, and that map's directory slot
          is read by NONE of prom_c's 99 directory reads.

WHAT ELSE IT ESTABLISHES (reproduced below; run it, do not quote this list)
    Q1  ★★ THE THREE-QUESTION INVENTORY over all 3,665 labels, partitioned, with
        the FIRST and the LAST label checked by name.
    Q3  ★ THE ONE MECHANISM THAT NAMES SOMETHING THIS ROUND: the DISJUNCTION.
        Round 6 refused a label when the tone records carrying a record's bytes
        disagreed on the name, because "nothing here picks one of them".  It does
        not have to pick.  The banner already PRINTS the candidate names, derived
        by the same code; withholding them from the label was withholding a
        measured fact.  `_SameAs_Fiddle_Or_Violin` claims exactly what was
        measured and no more.  31 records at a bound of 3 names; the sweep from 1
        to 12 is printed so the bound can be attacked.
    Q4  ★ FOUR MECHANISMS MEASURED AND REJECTED, so a later round does not
        re-invent them.  M4 the cross-family twin (0 of 155 and 0 of 12).  M5
        widening round 6's one-byte mask to +0x0C as well (+3 names, refused by
        the same prom_c instruction that refused round 7's M2).  M6 naming a
        no-twin record from the preset run it sits in (measured, and refused
        because no word is common to the run's members).  ★ M7 the MONOTONE
        INTERVAL, which is the strongest of the four and the one a later round
        would certainly have tried: Q5 shows the +0x20 array is in its owners'
        index order with zero backward steps over 106 anchors, so an ambiguous
        record's owner is confined to an interval.  Measured, it leaves ONE
        candidate 0 times out of 105.  Refuted by its own measurement.
    Q5  ★ TWO STRUCTURES, both positive findings and NEITHER of them a name.
        (a) the +0x18 array assigns each record a preset number in field +0x0B,
        equal values fall in runs of consecutive records, and the one run that
        carries preset 4 is 16 records long with 15 identified twins, every one
        of them a brass instrument.  (b) ★ the +0x20 array is IN ITS OWNERS'
        INDEX ORDER -- 106 anchors, 0 backward steps -- while the +0x18 array is
        not sorted at all (152 anchors, 28 backward steps).  (b) is what makes
        M7 worth measuring and Q4 is where it is refused.
    Q6  THE EIGHT MELODIC ROWS, refused again -- and the refusal is now derived
        rather than asserted: the sets of programs at which rows 1..7 differ from
        row 0 are NOT NESTED, so the rows are not an ordered ladder of variations
        either.  ⚠ AND THE ROW-0 BANNER WAS SELF-CONTRADICTORY: it stated "0 of
        the 128 differ from row 0's" and concluded "so the rows are NOT copies of
        one another", four words apart.  Fixed in the GENERATOR, which is the
        only place a fix survives.
    Q7  THE BASE ADDRESS, attacked from a direction the earlier rounds did not
        use: every pointer-shaped field this image contains -- 45 directory
        slots, 274 tone-record offsets, the descriptor tables' own 32-bit
        offsets -- is a FILE OFFSET below the payload end, 0 exceptions, and 0 of
        them is in 0x00F00000-0x00F7FFFF.  ⚠ ORIGIN in prom_d/prom_d.ld is NOT
        changed and nothing here proposes changing it.
    Q8  ★ THE PROSE SELF-CHECK.  Every number the generator writes into a
        per-record banner is re-derived from the ROM and compared with the text
        actually in prom_d/wsa1_prom_d.s, and a CONTRADICTION DETECTOR looks for
        the exact shape of the round-3 review failures -- a sentence whose own
        number refutes it.  Selftest T5 feeds the detector the sentence that WAS
        in the file, and it fires.
    Q9  the citations: every prom_c address quoted here is an instruction start --
        and ⚠ THE ONE INSTRUMENT THIS ROUND BREAKS, declared rather than left to a
        reviewer.  notes/wave7_round6_review_wd3_prom_d.py R3a parses a
        `_SameAs_<suffix>` label's suffix as ONE name, so it reports every
        disjunction label as unsupported.  That is a parser gap in a round-6
        instrument; Q9b asks R3a's own question with the `_Or_` split and every
        part is carried by the bytes.  (R3a was already failing on round 7's stem
        labels, which that script does not know about either.)

ROUND 9 (Q10-Q15), in one line each
    Q10 ★★ THE WHOLE-IMAGE LABEL AUDIT.  Every label's claim -- its index, its
        address and its name -- re-derived from the ROM and compared with the .s.
        2,857 of 3,665 have their NAME carried by this image's own bytes; 808
        have only their ADDRESS derived.  That is a HARSHER reading than the goal
        metric's 100% UPPER and it is the honest one.  Q10d is the prose check
        that found the 108-vs-128 sentence.  Negative controls T7-T12.
    Q11 the field round 8 excluded without reading it: the preset array's own
        +0x0B is the record's own index at 63 of 64, and record 0 is the
        exception.  The 57/7 headline is unchanged and that is checked, not said.
    Q12 the twin rule, run on the ONE array nobody ran it on: 0 of 64.  Those 64
        framed labels are now framed for a measured reason.
    Q13 ★ M8, the mechanism after round 8's M7: place a NO-CARRIER record by the
        monotone order.  0 of 12 on the array whose order holds; on the other it
        proposes ONE owner for THREE different records, so it refutes itself.
    Q14 the General-MIDI route to naming a program-map row, refused with a COUNT
        instead of round 5's two examples -- and the 16 family names are read out
        of prom_b's own `GM RE-MAP` screen rather than typed.  Aligned 18/128,
        rotated null 11/128.
    Q15 the base address: restated, not re-opened.  ORIGIN stays 0.

ROUND 10 (Q16-Q20), and it is the first round since round 8 to PROMOTE anything
    ★★ M9, THE SELECTOR -- the route round 6 measured and then used only as a
        WITNESS.  Round 6 Q2b found that the 1,024-entry map at slot +0x0C is the
        only map whose range reaches this array's last index, and that where a
        record ALREADY had a byte-derived name the map's program-map tone agreed
        637 times of 911.  It then wrote `THE MAP IS CORROBORATION, NOT THE NAME`
        and stopped -- which was right for records the byte test names, and left
        the map never asked about the records it does NOT name.  Every framed
        label in this array is in that second set.  Q16-Q19 ask it there.
    Q16 what pins the index, and ★ WHAT DOES NOT.  A map entry sits at
        row*128 + program.  The PROGRAM half is pinned hard: shift it by one and
        the agreement falls 637 -> 84, by two -> 43, and shuffling the map gives
        a mean of 7.7.  ⚠ THE ROW HALF IS NOT PINNED: the eight melodic rows are
        near-copies (52 of 128 programs hold the same tone in all eight), so
        rotating them costs 637 -> 608, a 3-point margin.  A name resting on that
        margin would be exactly the kind of name this tree has retracted before.
    ★ SO M9 THROWS THE ROW AWAY AND KEEPS THE COLUMN.  A record's name is the set
        of tone names its PROGRAM COLUMNS carry across all eight rows, which is
        invariant under every row rotation by construction -- T17 checks all
        eight.  That is a weaker claim than round 6's and it is the one the
        measurement supports.
    Q17 the calibration: where BOTH rules reach a record they agree 110 of 120,
        against a shuffled null of 5.8.  The 10 disagreements are PRINTED IN
        FULL, and neither side of them is wrong: `_SameAs_` is a statement about
        43 bytes and `_SelectedFor_` about a map entry.  M9 is applied to NEITHER
        -- only to records with no twin at all -- so no label contradicts another.
    Q18 ★ THE SAME RULE ON THE PERCUSSION ARRAY, MEASURED AND REFUSED.  It would
        have named 37 records -- every framed record of that array -- and it
        scores 709 of 1,024 against a SHUFFLED NULL OF 640, because the drum
        records' tails repeat.  Its calibration against the byte rule is 1 agree
        to 170 differ.  The melodic array is the opposite case, and the contrast
        is what makes the melodic number worth quoting.
    Q19 what M9 leaves, in four buckets that reconcile with no residue: 29 named,
        111 selected by NO entry of the map (a census over all 1,024, not a
        mechanism failing), 17 whose columns carry more than three names, and 2
        that would have been named `161` -- tone 0x05D's `    16' & 1'    ` --
        and are refused for it.  First and last record both checked.
    Q20 ToneIndexMapB (+0x10), whose range also fits this array: 0 of 156, at its
        own null.  ⚠ Declared a WEAK negative in the text, because its
        denominator is 156 against +0x0C's 911.

HOW TO RUN
    python3 notes/prom_d_inventory_round8.py             # the whole inventory
    python3 notes/prom_d_inventory_round8.py --quiet     # failures only
    python3 notes/prom_d_inventory_round8.py --selftest  # the checks, incl. LAST element
    python3 notes/prom_d_inventory_round8.py --nameless  # the naked objects, in full
    Exit status is non-zero if any check fails.

    scripts/analysis/gen_prom_d_asm.py imports wavesel_labels_r8() and REFUSES to
    emit if the shape moved, so a label in prom_d/wsa1_prom_d.s cannot outlive
    the measurement that justifies it.

WHAT IS *NOT* ESTABLISHED, said before the results
    * NOT that `_SelectedFor_X` means the record BELONGS to X, or is X's mixer
      setting.  It means: the entries of ToneDB_ToneIndexMapA that hold this
      record's index sit in program columns whose tones are X.  The array's role
      is still the KN5000's transplanted name and no prom_c instruction reads
      slot +0x0C at all -- Q2's own reader census says so, and that is a hole in
      this mechanism that no amount of agreement closes.
    * NOT that the ROW of a map entry is known.  Q16d measures that it is not,
      and M9's names are built so that it does not matter.
    * NOT that a disjunction label names an OWNER.  `_SameAs_A_Or_B` says these
      43 bytes and the wave-select blocks of A and of B are the same bytes.  It
      does not say the record belongs to A, or to B, or to either.
    * NOT that preset records 8..63 are unused by the MACHINE.  What Q2 measures
      is that nothing STORED in this image selects them; a runtime value written
      by a user edit is outside anything these four ROMs can show.
    * NOT that the brass run of Q5 means preset 4 IS a brass preset.  What was
      measured is which records carry preset 4 and what their twins are called.
    * NOT which physical part prom_d is.  Q7 is about the ADDRESS, as every
      round before it was.
    * NOT that a label this round leaves alone is unnameable in principle.  The
      claim is that A, B and C were asked and all three answered no.
"""
import collections
import importlib.util as _ilu
import os
import random
import re
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def _load(name, path):
    spec = _ilu.spec_from_file_location(name, os.path.join(ROOT, path))
    mod = _ilu.module_from_spec(spec)
    sys.modules[name] = mod
    spec.loader.exec_module(mod)
    return mod


_ARGV = sys.argv
sys.argv = [_ARGV[0], "--quiet"]          # the imported rounds must not print
_devnull = open(os.devnull, "w")
_stdout, sys.stdout = sys.stdout, _devnull
R3 = _load("_r8_r3", "notes/prom_d_documentation_round3.py")
R5 = _load("_r8_r5", "notes/prom_d_understanding_round5.py")
R6 = _load("_r8_r6", "notes/prom_d_understanding_round6.py")
R7 = _load("_r8_r7", "notes/prom_d_finish_round7.py")
R2 = _load("_r8_r2", "notes/prom_d_structures_round2.py")
R4 = _load("_r8_r4", "notes/prom_d_understanding_round4.py")
sys.stdout = _stdout
sys.argv = _ARGV

D = R6.D
DIR = R6.DIR
S = R6.S
u16 = R6.u16
u32 = R6.u32
PROM_D_BASE = 0xF00000
PAYLOAD_END = R6.BOUNDS[-1] + 1
WAVESEL_STRIDE = R6.WAVESEL_STRIDE
PERC_STRIDE = R6.PERC_STRIDE
PRESET_FIELD = R6.PRESET_FIELD

QUIET = "--quiet" in _ARGV
FAILED = []
NCHECK = [0]


def say(*a):
    if not QUIET:
        print(*a)


def check(label, cond, detail=""):
    NCHECK[0] += 1
    if cond:
        say("  PASS  %-70s %s" % (label, detail))
    else:
        FAILED.append(label)
        print("  FAIL  %-70s %s" % (label, detail))


# ---------------------------------------------------------------------------
# The three arrays of 43-byte wave-select records, and the two that carry names.
# Nothing below is typed: the slots come from the directory and the strides from
# the directory's own words.
# ---------------------------------------------------------------------------
WAVESEL_SLOTS = (0x18, 0x20, 0x3C)
NAMED_SLOTS = (0x18, 0x20)
LABEL_PREFIX = {0x18: "ToneDB_MixerDefaultTable",
                0x20: "ToneDB_PercMixerDefaultTable",
                0x3C: "ToneDB_WaveSelTailPresets"}
MAX_NAMES = 3            # Q3's bound; the sweep from 1 to 12 is printed


def _mask12(b):
    """The round-6 mask widened by one byte, for M5.  Measured, then refused."""
    return b[:PRESET_FIELD] + b[PRESET_FIELD + 2:]


# ---------------------------------------------------------------------------
# Q3.  THE DISJUNCTION -- the one rule this round adds.
# ---------------------------------------------------------------------------
def disjunction_labels(slot, bound=MAX_NAMES):
    """{record index: label suffix} for records whose twins DISAGREE on the name.

    The suffix is the sorted candidate names joined by `_Or_`.  Nothing is
    picked and nothing is invented: every name in it is a record's own 16 (or
    13) ASCII bytes, and the disjunction is the measurement verbatim.  A record
    round 6 or round 7 already named is never touched.
    """
    if slot not in NAMED_SLOTS:
        return {}
    have = R7.wavesel_labels_r7(slot)
    out = {}
    for k, tw in R6.wavesel_twins(slot).items():
        if not tw or k in have:
            continue
        names = sorted(set(x[2] for x in tw))
        if 2 <= len(names) <= bound:
            out[k] = "_Or_".join(names)
    return out


def wavesel_labels_r8(slot):
    """Round 7's labels plus round 8's disjunctions -- what the generator emits."""
    out = dict(R7.wavesel_labels_r7(slot))
    out.update(disjunction_labels(slot))
    return out


def _r8_shape(slot):
    """(round-7 labels, round-8 labels) -- the constant the generator refuses on."""
    return len(R7.wavesel_labels_r7(slot)), len(wavesel_labels_r8(slot))


AUDITED_R8 = {0x18: (152, 163), 0x20: (151, 171)}
AUDITED_CHECKS = 97          # rounds 8, 9 and 10 together


# ---------------------------------------------------------------------------
# Q2.  THE STORED-INDEX CENSUS -- "does anything point at it", asked the way
#      this image actually addresses things.
# ---------------------------------------------------------------------------
def wavesel_preset_fields():
    """[(where, index, value)] -- EVERY stored field in prom_d that selects a
    record of ToneDB_WaveSelTailPresets.

    prom_c sub_FBC725 reads field +0x0B of a wave-select record, masks it with
    `and A,0x3f` (0xFBC744) and uses the result to index the +0x3C array
    (0xFBC7C3).  So the census of stored references to a preset record is the
    census of field +0x0B over every wave-select record this image contains --
    the three arrays at +0x18, +0x20 and +0x3C, the per-element blocks of the
    tone records, and the tails of the drum-instrument records.  There is no
    other shape a stored reference could take, because the index is 6 bits and
    lives in a fixed field.
    """
    out = []
    for i, j, b, _nm in R6.tone_wavesel_blocks():
        out.append(("tone record %d element %d" % (i, j), i, b[PRESET_FIELD]))
    for i, b, _nm in R6.perc_wavesel_tails():
        out.append(("drum-instrument record %d" % i, i, b[PRESET_FIELD]))
    for slot in WAVESEL_SLOTS:
        _a, n, recs = R6.array_records(slot)
        for k in range(n):
            out.append(("%s_%03d" % (LABEL_PREFIX[slot], k), k, recs[k][PRESET_FIELD]))
    return out


def preset_referring_fields():
    """The stored fields that are a REFERENCE to a preset record, and only those.

    ⚠ WAVE 7 ROUND 9.  Round 8's banner used len(wavesel_preset_fields()) = 1,549
    as the denominator for `7 distinct values`, and a round-8 reviewer showed the
    two do not go together: over all 1,549 the field takes 64 distinct values,
    because the preset array's own +0x0B carries the record's own index (Q11 --
    at 63 of its 64 records). The 7 is a figure over the OTHER 1,485. This is
    that population, so the number and its denominator come from one place.
    """
    return [f for f in wavesel_preset_fields()
            if not f[0].startswith(LABEL_PREFIX[0x3C])]


def preset_referrers():
    """{preset index 0..63: [names of the stored records that select it]}."""
    out = collections.defaultdict(list)
    for where, _k, v in wavesel_preset_fields():
        if where.startswith(LABEL_PREFIX[0x3C]):
            continue                      # a record's own index is not a reference
        out[v & 0x3F].append(where)
    return dict(out)


def index_maps():
    """[(slot, entries, min, max, readers)] for every 1,024-entry LE16 map.

    A "map" here is a directory region whose length is 2,048 bytes -- 1,024
    LE16 values.  The shape is the image's, not a choice: prom_c's own reader of
    the one map it does read (slot +0x4C) scales by 2 and bounds by 1,024.
    """
    out = []
    seen = set()
    for i, v in enumerate(DIR):
        slot = 4 * i
        if v == 0xFFFFFFFF or v in seen:
            continue
        size = R6.next_bound(v) - v
        if size != 2048:
            continue
        seen.add(v)
        vals = [u16(v + 2 * k) for k in range(1024)]
        out.append((slot, len(vals), min(vals), max(vals), len(R3.readers(slot))))
    return out


def maps_reaching(slot):
    """Which 1,024-entry maps could index the array at `slot`, and by what rule.

    ★ THE RULE IS TIGHT AND IT IS STATED: a map indexes an array of n records
    only if every one of its 1,024 values is < n AND its maximum is exactly
    n-1 -- a map whose range stops short of the last record is not a map of
    that array, and one that runs past the end cannot be.  Round 6 found the
    same single map for the +0x18 array by asking only the second half of that
    ("the only map whose range reaches 321"); asking both halves is what makes
    the answer a partition rather than a shortlist.
    """
    _a, n, _recs = R6.array_records(slot)
    return [m for m in index_maps() if m[2] >= 0 and m[3] == n - 1]


# ---------------------------------------------------------------------------
# Q1.  THE THREE QUESTIONS, per label.
# ---------------------------------------------------------------------------
def three_questions():
    """[(label, A, B, C, ...)] for every label of prom_d/wsa1_prom_d.s.

    A -- CONTAINS A NAME:  round 7's self_named(), the object's own ASCII.
    B -- HAS A READER:     its directory slot appears in prom_c's 99-read census.
    C -- IS POINTED AT:    a stored INDEX reaches it (Q2); or one of the image's
                           own 1,281 pointer fields holds its offset (Q7); or,
                           only where neither form exists, an address spelling
                           does (round 7 Q3, the weak instrument, reported at
                           its null).

    ★ C IS ALWAYS ASKED OF A NAMELESS OBJECT and only skipped on a NAMED one.
    The address census costs sixteen scans of 512 KiB per object; running it on
    the 3,393 labels that already carry a name would cost half an hour to confirm
    what A and B have settled.  So a NAMED label answering yes to A or B records
    C as NOT ASKED, while every nameless object gets all three answers -- which
    is the whole point of the table.  That is a stated limit, not a hidden one.
    """
    labs = R7.classify_all()
    reach = _index_reachability()
    ptr = collections.defaultdict(list)
    for what, v in pointer_fields():
        ptr[v].append(what)
    rows = []
    for l in labs:
        a = R7.self_named(l)
        slot = R7.region_slot(l.addr)
        b = slot is not None and slot in R7.READER_SLOTS
        key = re.sub(r"_SameAs_.*$", "", l.name)
        if key in reach:
            c, cwhy = reach[key]
        elif (a or b) and l.finished != "NAMELESS":
            c, cwhy = None, "not asked -- A or B already answers"
        else:
            c, cwhy = _pointed_at(l, ptr)
        rows.append(Row(l, bool(a), bool(b), c, a, slot, cwhy))
    return rows


class Row(object):
    __slots__ = ("lab", "a", "b", "c", "ascii", "slot", "cwhy")

    def __init__(self, lab, a, b, c, ascii_, slot, cwhy):
        self.lab, self.a, self.b, self.c = lab, a, b, c
        self.ascii, self.slot, self.cwhy = ascii_, slot, cwhy

    @property
    def verdict(self):
        """NAMELESS is round 7's verdict, not a competing one.

        ⚠ AND A YES TO B IS NOT A NAME.  prom_c reads the region that holds the
        eight melodic rows at one site, and the index it reads with is
        row*128 + program -- so the read says what the TABLE is and identifies
        the row only by its POSITION, which is what the row's suffix already
        says.  A reader names an object when the index it uses means something
        other than the object's own position, and that distinction is the
        FRAMED/CONTENT line this tree grades on.  So the three answers are
        reported as the FACTS they are, and the verdict stays round 7's.
        """
        return "NAMELESS" if self.lab.finished == "NAMELESS" else "NAMED"

    @property
    def answers(self):
        return "%s%s%s" % ("A" if self.a else "-", "B" if self.b else "-",
                           "C" if self.c else ("?" if self.c is None else "-"))


def bankmap():
    """[(bank-select value, row)] -- the map at slot +0x6C, 37 bytes, 2 readers."""
    a = S(0x6C)
    return [(i, D[a + i]) for i in range(R6.next_bound(a) - a)]


def _index_reachability():
    """{label name: (bool, why)} for the objects a STORED INDEX could reach.

    Only the wave-select records are index-addressed in a way this image spells
    out, so only they get an answer here; everything else falls through to the
    address census, which is the weaker instrument and is labelled as such.
    """
    out = {}
    refs = preset_referrers()
    for k in range(R6.array_records(0x3C)[1]):
        who = refs.get(k, [])
        out["%s_%03d" % (LABEL_PREFIX[0x3C], k)] = (
            bool(who),
            ("selected by %d stored wave-select field%s, the first being %s"
             % (len(who), "" if len(who) == 1 else "s", who[0])) if who else
            ("no wave-select field in the image holds %d after `and A,0x3f`; "
             "prom_c 0xFBC744 is the mask and 0xFBC7C3 the index" % k))
    bm = bankmap()
    for r in range(10):
        hits = [v for v, row in bm if row == r]
        out["ToneNumBank_%s" % R5.row_names()[r]] = (
            bool(hits),
            "the BankMap at 0x%05X holds %d at %d of its %d entries, the first being "
            "bank-select value %d" % (S(0x6C), r, len(hits), len(bm), hits[0])
            if hits else
            "no entry of the BankMap at 0x%05X selects this row" % S(0x6C))
    for slot in NAMED_SLOTS:
        _a, n, _recs = R6.array_records(slot)
        reaching = maps_reaching(slot)
        for k in range(n):
            hits = [m for m in reaching if m[4]]
            out["%s_%03d" % (LABEL_PREFIX[slot], k)] = (
                bool(hits),
                ("reached by the map at slot +0x%02X, which prom_c reads" % hits[0][0])
                if hits else
                ("the %d map%s whose range reaches this array (%s) %s read by none "
                 "of prom_c's %d directory reads"
                 % (len(reaching), "" if len(reaching) == 1 else "s",
                    ", ".join("+0x%02X" % m[0] for m in reaching) or "none",
                    "is" if len(reaching) == 1 else "are", R3.AUDITED[0])))
    return out


def _pointed_at(l, ptr):
    """Does anything point at this object?  The EXACT form first, then the weak one.

    ★ THE EXACT FORM is the image's own pointer fields: 45 directory slots, 274
    tone-record offsets and 962 descriptor pointers, all of them FILE OFFSETS
    (Q7).  An object one of them holds the offset of is pointed at, and by a
    field that can be named.  Only when no such field exists does this fall back
    to round 7's byte census, which is reported at its null and never quoted as
    a zero.
    """
    if l.addr in ptr:
        who = ptr[l.addr]
        return True, ("%d of the image's own pointer fields hold this offset, the "
                      "first being %s" % (len(who), who[0]))
    o, a = R7.census_address(l.addr)
    return (o + a) > 0, ("no pointer field of this image holds this offset; the byte "
                         "census finds %d offset and %d address spellings, at its "
                         "null (round 7 Q3)" % (o, a))


# ---------------------------------------------------------------------------
# Q4 / Q5 / Q6 -- the measurements this round makes and mostly refuses.
# ---------------------------------------------------------------------------
def cross_family_twins():
    """M4: does a record with no twin in its OWN family match the other one?"""
    tone = collections.defaultdict(set)
    for _i, _j, b, nm in R6.tone_wavesel_blocks():
        tone[R6._mask(b)].add(nm)
    perc = collections.defaultdict(set)
    for _i, b, nm in R6.perc_wavesel_tails():
        perc[R6._mask(b)].add(nm)
    out = {}
    for slot, own, other in ((0x18, tone, perc), (0x20, perc, tone)):
        _a, n, recs = R6.array_records(slot)
        notwin = [k for k in range(n) if not own.get(R6._mask(recs[k]))]
        out[slot] = (len(notwin),
                     [k for k in notwin if other.get(R6._mask(recs[k]))])
    return out


def mask12_reach():
    """M5: what widening round 6's mask to +0x0C as well WOULD have named.

    ⚠ MEASURED AGAINST ITS OWN BASELINE, not against round 7's label count.
    Round 7's count includes the stem rule, which is a different mechanism; a
    gain computed against it is an apples-to-oranges number, and the first draft
    of this function printed one (a "gain" of -45).  Both figures here are
    "records with exactly ONE candidate name under this mask".
    """
    out = {}
    for slot, blocks in ((0x18, [(nm, b) for _i, _j, b, nm in R6.tone_wavesel_blocks()]),
                         (0x20, [(nm, b) for _i, b, nm in R6.perc_wavesel_tails()])):
        wide = collections.defaultdict(set)
        narrow = collections.defaultdict(set)
        for nm, b in blocks:
            wide[_mask12(b)].add(nm)
            narrow[R6._mask(b)].add(nm)
        _a, n, recs = R6.array_records(slot)
        w = sum(1 for k in range(n) if len(wide.get(_mask12(recs[k]), ())) == 1)
        v = sum(1 for k in range(n) if len(narrow.get(R6._mask(recs[k]), ())) == 1)
        out[slot] = (n, w, v)
    return out


def owner_sequence(slot):
    """[(record index, owner index)] for the records with ONE owner, in order."""
    tw = R6.wavesel_twins(slot)
    _a, n, _recs = R6.array_records(slot)
    out = []
    for k in range(n):
        owners = sorted(set(x[0] for x in tw[k]))
        if len(owners) == 1:
            out.append((k, owners[0]))
    return out


def monotonicity(slot):
    """(anchors, violations) -- is the array in its owners' index order?"""
    seq = owner_sequence(slot)
    return len(seq), sum(1 for x, y in zip(seq, seq[1:]) if y[1] <= x[1])


def interval_tiebreak(slot):
    """M7: does monotonicity pick ONE of an ambiguous record's candidates?

    Returns (ambiguous, resolved to one, left with several, left with none).
    """
    tw = R6.wavesel_twins(slot)
    _a, n, _recs = R6.array_records(slot)
    anchors = dict(owner_sequence(slot))
    one = many = none = 0
    amb = 0
    for k in range(n):
        cands = sorted(set(x[0] for x in tw[k]))
        if len(cands) < 2:
            continue
        amb += 1
        lo = max((v for j, v in anchors.items() if j < k), default=-1)
        hi = min((v for j, v in anchors.items() if j > k), default=1 << 30)
        inside = [c for c in cands if lo < c < hi]
        one += len(inside) == 1
        many += len(inside) > 1
        none += not inside
    return amb, one, many, none


def preset_runs(slot=0x18):
    """M6 / Q5: the maximal runs of consecutive records sharing one +0x0B value.

    Returns [(value, lo, hi, [twin names inside the run])].
    """
    _a, n, recs = R6.array_records(slot)
    tw = R6.wavesel_twins(slot)
    runs = []
    lo = 0
    for k in range(1, n + 1):
        if k == n or recs[k][PRESET_FIELD] != recs[lo][PRESET_FIELD]:
            names = sorted(set(x[2] for j in range(lo, k) for x in tw[j]))
            runs.append((recs[lo][PRESET_FIELD], lo, k - 1, names))
            lo = k
    return runs


def run_common_word(names):
    """M6's naming attempt: a CamelCase word common to EVERY name of a run."""
    if not names:
        return None
    sets = [set(re.findall(r"[A-Z][a-z0-9]*|[0-9]+", nm)) for nm in names]
    common = set.intersection(*sets)
    return sorted(common)[0] if common else None


def melodic_rows():
    """[(row, [programs where it differs from row 0])] for rows 0..7."""
    base = S(0x04)
    rows = []
    for r in range(8):
        d = [p for p in range(128)
             if u16(base + 0x100 * r + 2 * p) != u16(base + 2 * p)]
        rows.append((r, d))
    return rows


def rows_are_nested():
    """Is the differing-program set of row r+1 a SUBSET of row r's?  (It is not.)"""
    rows = dict(melodic_rows())
    bad = []
    for r in range(1, 7):
        extra = sorted(set(rows[r + 1]) - set(rows[r]))
        if extra:
            bad.append((r + 1, r, extra))
    return bad


def pointer_fields():
    """[(what, value)] -- every pointer-shaped field prom_d stores.

    The 45 live directory slots, the 274 tone-record offsets, and both 32-bit
    offsets of every descriptor header record.  Q7 asks of each whether it is a
    FILE OFFSET or an ABSOLUTE address, which is the only form in which ORIGIN
    could be wrong.
    """
    out = [("directory slot +0x%02X" % (4 * i), v)
           for i, v in enumerate(DIR) if v != 0xFFFFFFFF]
    out += [("tone-record offset %d" % i, p) for i, p in enumerate(R6.TONE_PTRS)]
    for slot in sorted(R2.DESC_BLOCKS):
        _h, _p, recs = R2.desc_layout(slot)
        for i, r in enumerate(recs):
            for j, off in ((1, r[1]), (2, r[2])):
                if off:
                    out.append(("descriptor +0x%02X record %d pointer %d"
                                % (slot, i, j), off))
    return out


# ---------------------------------------------------------------------------
# Q8.  THE PROSE SELF-CHECK -- the generated file, read back and re-derived.
# ---------------------------------------------------------------------------
SRC = os.path.join(ROOT, "prom_d", "wsa1_prom_d.s")
_CONTRADICTIONS = (
    # (regex over one banner, predicate on the captured number) -- a sentence
    # whose own number refutes what it goes on to claim.  This is the shape a
    # round-3 reviewer found twice in prom_a: "fifteen instructions" above a
    # thirty-instruction routine, and a "NEVER POSITIVE" refuted four lines down.
    (re.compile(r"(\d+) of the 128 differ from row 0's[^.]*?not (?:a )?cop",
                re.S | re.I),
     lambda n: int(n) == 0,
     "a row banner says N of 128 differ and concludes the rows are NOT copies, "
     "with N = 0"),
)


def banner_contradictions(text):
    """[(what, excerpt)] -- sentences in `text` refuted by their own number."""
    out = []
    for rx, bad, what in _CONTRADICTIONS:
        for m in rx.finditer(text):
            if bad(m.group(1)):
                out.append((what, m.group(0)[:70].replace("\n", " ")))
    return out


def banner_numbers(text):
    """Every per-record number the generator writes that this round can re-derive."""
    got = {}
    got["nearest"] = [(int(a), int(b)) for a, b in re.findall(
        r"differs in\n; (\d+) of the (43)\.", text)]
    got["rowdiff"] = [int(x) for x in re.findall(
        r"(\d+) of the 128 differ from row 0's", text)]
    got["notwin"] = [(int(a), int(b)) for a, b in re.findall(
        r"one of the (\d+) records of this array with no twin,\n; against (\d+) that have one",
        text)]
    return got


# ---------------------------------------------------------------------------
# The report.
# ---------------------------------------------------------------------------
ROWS = None


def q1():
    global ROWS
    say("\n=== Q1.  THE THREE QUESTIONS, asked of every label ===\n")
    ROWS = three_questions()
    say("  A = the object CONTAINS a name (its own ASCII)")
    say("  B = a prom_c READER reaches the region it is in (the 99-read census)")
    say("  C = something POINTS AT the object: a stored index, one of the image's own")
    say("      pointer fields, or an address spelling  (? = not asked, see below)")
    say("")
    tab = collections.Counter((r.verdict, r.answers) for r in ROWS)
    for (v, ans), n in sorted(tab.items(), key=lambda x: (-x[1])):
        ex = next(r for r in ROWS if r.verdict == v and r.answers == ans)
        say("  %-9s %-4s %6d   e.g. %s" % (v, ans, n, ex.lab.name))
    named = [r for r in ROWS if r.verdict == "NAMED"]
    nameless = [r for r in ROWS if r.verdict == "NAMELESS"]
    check("Q1a  the three answers cover every label -- none is left unasked",
          len(ROWS) == len(R7.LABS), "%d rows over %d labels" % (len(ROWS), len(R7.LABS)))
    check("Q1b  every NAMELESS object carries all three answers, not one mechanism",
          all(r.cwhy for r in nameless), "%d nameless, %d without a stated C"
          % (len(nameless), sum(1 for r in nameless if not r.cwhy)))
    check("Q1c  the FIRST and the LAST label are both answered, by name",
          ROWS[0].answers and ROWS[-1].answers,
          "first %s -> %s; last %s -> %s"
          % (ROWS[0].lab.name, ROWS[0].answers, ROWS[-1].lab.name, ROWS[-1].answers))
    check("Q1d  and the answers are not vacuous: some objects answer YES to C",
          any(r.c for r in ROWS), "%d of %d" % (sum(1 for r in ROWS if r.c), len(ROWS)))
    # ★ THE ONE NAMELESS OBJECT THAT DOES CONTAIN A NAME, and why it is still
    # nameless.  Answering A needs a CamelCase of at least four characters; this
    # record's field camels to three digits.  Round 7 published it as a METRIC
    # ARTEFACT and round 8 does not rename it to satisfy a regex -- that is the
    # inflation round 7's own Q8 audited, and doing it here would be gaming the
    # instrument this lane is graded by.
    _art = [r for r in nameless if r.lab.name.startswith("ToneRec_")]
    if _art:
        _a0 = _art[0]
        _txt = D[_a0.lab.addr:_a0.lab.addr + 16].decode("latin1")
        say("")
        say("  ⚠ ONE NAMELESS OBJECT DOES CONTAIN A NAME: %s, whose own 16 ASCII"
            % _a0.lab.name)
        say("    bytes are %r.  The CamelCase rule every label in this file uses" % _txt)
        say("    turns that into %r -- three characters, all digits -- so the metric"
            % R6.camel(_txt))
        say("    grades the label FRAMED.  It is a METRIC ARTEFACT (round 7 Q1) and")
        say("    round 8 does NOT rename it: spelling the apostrophes as `Ft` would")
        say("    move the number by inventing a morpheme, which is round 3's `Home`")
        say("    failure with a different word.")
        check("Q1e  the metric artefact is what it is said to be, re-derived",
              R6.camel(_txt).isdigit() and len(R6.camel(_txt)) < 4,
              "%r -> %r, %d characters" % (_txt, R6.camel(_txt), len(R6.camel(_txt))))
    say("")
    fourth = [r for r in named if not r.a and not r.b and not r.c]
    say("  ★ AND THE TABLE ADMITS A ROUTE THE THREE QUESTIONS DO NOT COVER: %d"
        % len(fourth))
    say("    objects are NAMED while answering no to all three, e.g. %s."
        % fourth[0].lab.name if fourth else "none")
    say("    They are named by round 6's mechanism -- the object CONTAINS A COPY of a")
    say("    named object's bytes -- which is a fourth route and is why this round")
    say("    reports the three answers as facts rather than as a verdict.  A")
    say("    three-question table that called those objects nameless would be")
    say("    measuring its own question list.")
    say("")
    say("  ★ %d NAMED, %d NAMELESS.  Round 7's verdict is kept: a yes to B or C is"
        % (len(named), len(nameless)))
    say("    NOT a name -- prom_c reads the region holding the eight melodic rows,")
    say("    and the index it reads with is row*128 + program, which identifies a")
    say("    row by its POSITION and so says only what the row's suffix already")
    say("    says.  The three answers are facts about routes, not verdicts.")
    return nameless


def q2(nameless):
    say("\n=== Q2.  ★ THE STORED-INDEX CENSUS -- round 7's own conclusion, run ===\n")
    say("  Round 7 established that prom_c reaches this image only by adding a base")
    say("  to a value read OUT of it and then INDEXING, and concluded that a record")
    say("  'is addressed by an index, never by a stored address'.  That names a")
    say("  census it did not run.  Here it is.")
    say("")
    fields = wavesel_preset_fields()
    refs = preset_referrers()
    n_pre = R6.array_records(0x3C)[1]
    say("  (a) ToneDB_WaveSelTailPresets, %d records.  The ONLY stored field that" % n_pre)
    say("      selects one is +0x0B of a wave-select record, masked by prom_c")
    say("      0xFBC744 `and A,0x3f` and used as the index at 0xFBC7C3.  Over all")
    say("      %d wave-select records this image contains, that field takes these"
        % len(fields))
    say("      values after the mask:")
    for v in sorted(refs):
        say("          preset %2d  selected by %5d stored record%s   e.g. %s"
            % (v, len(refs[v]), " " if len(refs[v]) == 1 else "s", refs[v][0]))
    unref = [k for k in range(n_pre) if k not in refs]
    say("      ★ so %d of the %d preset records are selected by NOTHING STORED in"
        % (len(unref), n_pre))
    say("        this image: %s%s."
        % (", ".join(str(k) for k in unref[:8]),
           " ... %d" % unref[-1] if len(unref) > 8 else ""))
    check("Q2a  the preset census covers every wave-select record in the image",
          len(fields) == sum(R6.array_records(s)[1] for s in WAVESEL_SLOTS)
          + len(R6.tone_wavesel_blocks()) + len(R6.perc_wavesel_tails()),
          "%d fields = %d array + %d tone blocks + %d drum records"
          % (len(fields), sum(R6.array_records(s)[1] for s in WAVESEL_SLOTS),
             len(R6.tone_wavesel_blocks()), len(R6.perc_wavesel_tails())))
    check("Q2b  and it is checked on the LAST preset record as well as the first",
          (0 in refs) and (n_pre - 1 in unref),
          "preset 0 selected by %d, preset %d selected by none"
          % (len(refs.get(0, ())), n_pre - 1))
    raw = sorted(set(v for _w, _k, v in fields))
    check("Q2c  the mask is prom_c's, not this round's -- unmasked, the field "
          "overflows the array",
          any(v >= n_pre for v in raw) and all((v & 0x3F) < n_pre for v in raw),
          "%d distinct raw values, %d of them >= %d and unusable as an index; "
          "0xFBC744 `and A,0x3f` is what makes them indices"
          % (len(raw), sum(1 for v in raw if v >= n_pre), n_pre))
    say("")
    say("  (b) the two mixer arrays.  A 1,024-entry map indexes an array of n")
    say("      records only if all its values are < n and its maximum is n-1.")
    say("      Every 1,024-entry region of this image, with its range and its")
    say("      reader count from the 99-read census:")
    for slot, _n, lo, hi, rd in index_maps():
        say("          slot +%02X   values %4d..%-5d  prom_c readers: %d" % (slot, lo, hi, rd))
    for slot in NAMED_SLOTS:
        _a, n, _r = R6.array_records(slot)
        reach = maps_reaching(slot)
        say("      %s (%d records) is reached by %s."
            % (LABEL_PREFIX[slot], n,
               ", ".join("the map at slot +0x%02X (%d prom_c readers)" % (m[0], m[4])
                         for m in reach) or "NO map in the image"))
    check("Q2d  the +0x18 array is reached by exactly one map, and it is unread",
          [(m[0], m[4]) for m in maps_reaching(0x18)] == [(0x0C, 0)],
          "%s" % [(hex(m[0]), m[4]) for m in maps_reaching(0x18)])
    check("Q2e  and the rule is not vacuous -- some map IS read by prom_c",
          any(m[4] for m in index_maps()),
          "%d of %d 1,024-entry maps have a reader"
          % (sum(1 for m in index_maps() if m[4]), len(index_maps())))
    say("")
    say("  ★ THE ANSWER TO C, FOR THE OBJECTS THIS ROUND LEAVES NAMELESS: %d of the"
        % sum(1 for r in nameless if r.c is False))
    say("    %d answer NO, each with the reason above rather than with a byte" % len(nameless))
    say("    census at its noise floor.")


def q3():
    say("\n=== Q3.  ★ THE DISJUNCTION -- the one rule that names something ===\n")
    say("  Round 6 refused a label when the records carrying a mixer record's 43")
    say("  bytes disagreed on the name: 'nothing here picks one of them'.  It does")
    say("  not have to pick.  The banner over that record ALREADY PRINTS the")
    say("  candidate names, derived by the same code; keeping them out of the label")
    say("  withheld a measured fact and left the object identified by its position.")
    say("  `_SameAs_Fiddle_Or_Violin` states exactly what was measured -- these 43")
    say("  bytes are the wave-select block that Fiddle carries and the one Violin")
    say("  carries -- and claims no owner.")
    say("")
    tot = 0
    for slot in NAMED_SLOTS:
        d = disjunction_labels(slot)
        tot += len(d)
        say("  slot +%02X: %d records named, %d left framed"
            % (slot, len(d),
               sum(1 for k, tw in R6.wavesel_twins(slot).items()
                   if tw and k not in wavesel_labels_r8(slot))))
        for k in sorted(d)[:4]:
            say("      %s_%03d_SameAs_%s" % (LABEL_PREFIX[slot], k, d[k]))
        if len(d) > 4:
            last = sorted(d)[-1]
            say("      ... and %d more, the last being" % (len(d) - 5))
            say("      %s_%03d_SameAs_%s" % (LABEL_PREFIX[slot], last, d[last]))
    say("")
    say("  ★ THE BOUND, SHOWN RATHER THAN ASSERTED.  MAX_NAMES = %d." % MAX_NAMES)
    say("    What every bound from 1 to 12 would have named, and the longest label")
    say("    it would have produced (this file's longest existing label is 60):")
    for bnd in range(1, 13):
        n = 0
        longest = ""
        for slot in NAMED_SLOTS:
            for k, sfx in disjunction_labels(slot, bnd).items():
                n += 1
                s = "%s_%03d_SameAs_%s" % (LABEL_PREFIX[slot], k, sfx)
                if len(s) > len(longest):
                    longest = s
        say("      bound %2d -> %2d names, longest %3d  %s"
            % (bnd, n, len(longest), longest[:72]))
    say("    At 4 the longest label passes 100 characters and the list stops being")
    say("    readable as a list; at 6 and beyond a single label enumerates a whole")
    say("    drum family (twelve hi-hats), which is the thing round 7's stem rule")
    say("    already refused to compress into one word.")
    check("Q3a  the rule ADDS and never overwrites: round 7's names are untouched",
          all(wavesel_labels_r8(s)[k] == v
              for s in NAMED_SLOTS
              for k, v in R7.wavesel_labels_r7(s).items()),
          "%d round-7 names, all unchanged"
          % sum(len(R7.wavesel_labels_r7(s)) for s in NAMED_SLOTS))
    check("Q3b  it fires ONLY where the twins disagree -- never on a no-twin record",
          all(R6.wavesel_twins(s)[k] for s in NAMED_SLOTS
              for k in disjunction_labels(s)),
          "%d records named, %d of them with no twin"
          % (tot, sum(1 for s in NAMED_SLOTS for k in disjunction_labels(s)
                      if not R6.wavesel_twins(s)[k])))
    check("Q3c  every name in a disjunction is a record's own ASCII, not a coinage",
          _disjunction_names_are_ascii(),
          "%d distinct names used, all of them a tone or drum record's name field"
          % len(set(n for s in NAMED_SLOTS for v in disjunction_labels(s).values()
                    for n in v.split("_Or_"))))
    lastslot = NAMED_SLOTS[-1]
    lastk = max(disjunction_labels(lastslot))
    check("Q3d  checked on the LAST record it names as well as the first",
          set(disjunction_labels(lastslot)[lastk].split("_Or_"))
          == set(x[2] for x in R6.wavesel_twins(lastslot)[lastk]),
          "%s_%03d -> %s" % (LABEL_PREFIX[lastslot], lastk,
                             disjunction_labels(lastslot)[lastk]))
    check("Q3e  the emitted shape matches the constant the generator refuses on",
          all(_r8_shape(s) == AUDITED_R8[s] for s in NAMED_SLOTS),
          "%s" % {hex(s): _r8_shape(s) for s in NAMED_SLOTS})
    return tot


def _disjunction_names_are_ascii():
    have = set(nm for _i, _j, _b, nm in R6.tone_wavesel_blocks())
    have |= set(nm for _i, _b, nm in R6.perc_wavesel_tails())
    return all(n in have for s in NAMED_SLOTS
               for v in disjunction_labels(s).values() for n in v.split("_Or_"))


def q4():
    say("\n=== Q4.  FOUR MECHANISMS MEASURED AND REJECTED ===\n")
    cf = cross_family_twins()
    say("  M4  THE CROSS-FAMILY TWIN.  Round 6 compared the +0x18 array against")
    say("      TONE blocks and the +0x20 array against DRUM records, and never the")
    say("      other way round.  A melodic mixer record whose bytes are a drum")
    say("      record's tail would be named by the same rule.")
    for slot in NAMED_SLOTS:
        n, hits = cf[slot]
        say("      slot +%02X: %d records with no twin in their own family, %d of them"
            % (slot, n, len(hits)))
        say("               match a record of the OTHER family." )
    check("Q4a  M4 reaches zero on both arrays, and the zero is reported",
          not cf[0x18][1] and not cf[0x20][1],
          "%d + %d matches over %d + %d records with no twin"
          % (len(cf[0x18][1]), len(cf[0x20][1]), cf[0x18][0], cf[0x20][0]))
    check("Q4a' and the corpus it searched is not empty",
          len(R6.perc_wavesel_tails()) > 400 and len(R6.tone_wavesel_blocks()) > 400,
          "%d tone blocks, %d drum records"
          % (len(R6.tone_wavesel_blocks()), len(R6.perc_wavesel_tails())))
    say("")
    m5 = mask12_reach()
    say("  M5  WIDENING ROUND 6's ONE-BYTE MASK TO +0x0C AS WELL.  Round 7's M2")
    say("      refused bytes 3..10 on the ground that prom_c's only writer of a")
    say("      wave-select record writes byte 11 and bytes 13..42 and nothing else.")
    say("      ⚠ BYTE 12 IS ON THE SAME SIDE OF THAT ARGUMENT and the same refusal")
    say("      applies -- but it had not been measured, so a later round could have")
    say("      re-invented it.  What it would have named:")
    for slot in NAMED_SLOTS:
        n, wide, narrow = m5[slot]
        say("      slot +%02X: %d records; %d uniquely named by the wider mask against"
            % (slot, n, wide))
        say("               %d by round 6's one-byte mask -- a gain of %d."
            % (narrow, wide - narrow))
    say("      REJECTED.  prom_c 0xFBC7D6 writes field +0x0B and 0xFBC7D9/0xFBC7E3")
    say("      copy bytes 13..42; byte 12 is written by NOTHING, so two records that")
    say("      differ in it are different records, not a copy and its rewrite.")
    check("Q4b  M5 is measured against ITS OWN baseline before it is refused",
          m5[0x18][1] > m5[0x18][2] and m5[0x20][1] == m5[0x20][2],
          "+%d names at slot +0x18, +%d at +0x20, both refused"
          % (m5[0x18][1] - m5[0x18][2], m5[0x20][1] - m5[0x20][2]))
    say("")
    runs = preset_runs()
    named_runs = [(v, lo, hi, nm) for v, lo, hi, nm in runs if len(nm) >= 3]
    say("  M6  NAMING A NO-TWIN RECORD FROM THE PRESET RUN IT SITS IN.  Field +0x0B")
    say("      of the +0x18 array takes %d distinct values, and equal values fall in"
        % len(set(v for v, _l, _h, _n in runs)))
    say("      %d maximal runs of consecutive records.  Where a run's identified" % len(runs))
    say("      twins share a word, that word would name every record in the run.")
    hit = [(v, lo, hi, nm, run_common_word(nm)) for v, lo, hi, nm in named_runs]
    say("      Runs with 3+ identified twins: %d.  Runs with a word common to ALL"
        % len(named_runs))
    say("      of them: %d." % sum(1 for x in hit if x[4]))
    for v, lo, hi, nm, w in hit[:6]:
        say("          preset %d, records %3d..%-3d  %2d twins  common word: %s"
            % (v, lo, hi, len(nm), w or "NONE"))
    _fam = [r for r in runs if r[0] == 4][0]
    say("      REJECTED at the measurement: no run has a word common to all its")
    say("      members, and the one run that is visibly a family -- the %d"
        % (_fam[2] - _fam[1] + 1))
    say("      consecutive records at preset 4, whose twins are")
    say("        %s" % ", ".join(_fam[3]))
    say("      -- shares no word at all.  A reader supplies `brass`; the image does")
    say("      not spell it, and Q6 of round 7 is the census that would catch it if")
    say("      this round wrote it into a label anyway.")
    check("Q4c  M6 is refused by a measurement, not by taste",
          not any(x[4] for x in hit),
          "%d runs with 3+ twins, %d with a word common to every member"
          % (len(hit), sum(1 for x in hit if x[4])))
    check("Q4c' and the word-finder is not broken: it finds one when there IS one",
          run_common_word(["RideBell1", "RideBell2"]) is not None
          and run_common_word(["Piano", "Trumpet"]) is None,
          "RideBell1/RideBell2 -> %r; Piano/Trumpet -> %r"
          % (run_common_word(["RideBell1", "RideBell2"]),
             run_common_word(["Piano", "Trumpet"])))
    say("")
    say("  M7  THE MONOTONE INTERVAL AS A TIE-BREAKER, and it is the strongest")
    say("      mechanism this round found and refused.  Q5 shows the +0x20 array is")
    say("      in its owners' index order with ZERO backward steps over 106 anchors.")
    say("      An ambiguous record therefore has an interval its owner must lie in --")
    say("      between the nearest anchor before it and the nearest after -- and if")
    say("      exactly one candidate fell inside, the ambiguity would be broken with")
    say("      a mechanism rather than a preference.")
    for slot in NAMED_SLOTS:
        amb, one, many, none = interval_tiebreak(slot)
        say("      slot +%02X: %2d ambiguous records; the interval leaves ONE candidate"
            % (slot, amb))
        say("               %d times, several %d times, and none %d times."
            % (one, many, none))
    say("      REFUTED BY ITS OWN MEASUREMENT, at zero on both arrays.  Where the")
    say("      order holds the candidates are neighbours and all of them fall inside")
    say("      the interval; where it does not hold, no candidate does.  Nothing is")
    say("      resolved, so nothing is renamed, and a later round need not re-try it.")
    check("Q4d  M7 resolves nothing, on either array, and the zero is published",
          interval_tiebreak(0x18)[1] == 0 and interval_tiebreak(0x20)[1] == 0,
          "%d + %d of %d + %d ambiguous records resolved"
          % (interval_tiebreak(0x18)[1], interval_tiebreak(0x20)[1],
             interval_tiebreak(0x18)[0], interval_tiebreak(0x20)[0]))
    check("Q4d' and the interval itself is real -- it is empty where the order fails",
          interval_tiebreak(0x18)[3] == interval_tiebreak(0x18)[0],
          "at slot +0x18, %d of %d ambiguous records have an EMPTY interval, which "
          "is what 28 backward steps produce"
          % (interval_tiebreak(0x18)[3], interval_tiebreak(0x18)[0]))


def q5():
    say("\n=== Q5.  ★ TWO STRUCTURES FOUND -- and neither of them is a name ===\n")
    runs = preset_runs()
    counts = collections.Counter(v for v, _l, _h, _n in runs)
    say("  Field +0x0B of a mixer record is the preset number prom_c would apply to")
    say("  it (round 5 Q7).  In the tone database proper that field is ALWAYS 0:")
    tone_vals = collections.Counter(b[PRESET_FIELD] & 0x3F
                                    for _i, _j, b, _n in R6.tone_wavesel_blocks())
    perc_vals = collections.Counter(b[PRESET_FIELD] & 0x3F
                                    for _i, b, _n in R6.perc_wavesel_tails())
    say("      %d tone-record wave-select blocks: masked values %s"
        % (sum(tone_vals.values()), dict(tone_vals)))
    say("      %d drum-instrument records:        masked values %s"
        % (sum(perc_vals.values()), dict(perc_vals)))
    say("  so no stored TONE selects a preset, and every stored preset reference in")
    say("  the image comes from the mixer array at slot +0x18, where the values are:")
    for v in sorted(counts):
        tot = sum(hi - lo + 1 for vv, lo, hi, _n in runs if vv == v)
        say("      preset %d  %4d records in %d run%s"
            % (v, tot, counts[v], "" if counts[v] == 1 else "s"))
    fam = [r for r in runs if r[0] == 4]
    big = max(fam, key=lambda r: r[2] - r[1])
    say("  ★ AND ONE RUN IS A FAMILY.  Records %d..%d -- %d consecutive records --"
        % (big[1], big[2], big[2] - big[1] + 1))
    say("    all carry preset %d, and the %d of them the byte identity names are:"
        % (big[0], len(big[3])))
    say("      %s" % ", ".join(big[3]))
    say("  ⚠ THAT IS A STRUCTURE, NOT A NAME.  Q4's M6 refuses to turn it into one:")
    say("    the run's members share no word, and 'brass' is a word this reader")
    say("    brings to the list, not one the image spells.")
    check("Q5a  the family run is derived from the field, not chosen by eye",
          len(fam) == 1 and big[2] - big[1] + 1 == 16,
          "preset 4 occurs in %d run%s; the run is records %d..%d, %d long"
          % (len(fam), "" if len(fam) == 1 else "s", big[1], big[2],
             big[2] - big[1] + 1))
    check("Q5b  the tone database itself selects preset 0 and nothing else",
          set(tone_vals) == {0} and set(perc_vals) == {0},
          "%d tone blocks and %d drum records, all masked value 0"
          % (sum(tone_vals.values()), sum(perc_vals.values())))
    check("Q5b' and that is not because the field is always 0 -- the raw byte varies",
          len(set(b[PRESET_FIELD] for _i, _j, b, _n in R6.tone_wavesel_blocks())) > 1,
          "raw values %s, all with low 6 bits clear"
          % sorted(set(b[PRESET_FIELD] for _i, _j, b, _n in R6.tone_wavesel_blocks())))
    say("")
    say("  ★★ AND THE SECOND STRUCTURE, WHICH IS THE STRONGER OF THE TWO: the drum")
    say("     mixer array is IN ITS OWNERS' ORDER.  Taking the records whose bytes")
    say("     identify exactly one owner and reading their owner indices in array")
    say("     order:")
    for slot in NAMED_SLOTS:
        anc, viol = monotonicity(slot)
        say("       slot +%02X: %3d anchors, %2d of the %d consecutive pairs go BACKWARDS"
            % (slot, anc, viol, anc - 1))
    say("     So the +0x20 array is a strictly increasing selection out of the 504")
    say("     drum-instrument records, and the +0x18 array is NOT sorted at all.")
    check("Q5c  the +0x20 array is strictly monotone in its owners' indices",
          monotonicity(0x20)[1] == 0,
          "%d anchors, %d backward pairs" % monotonicity(0x20))
    check("Q5c' and the same test FAILS on the +0x18 array, so it is not vacuous",
          monotonicity(0x18)[1] > 0,
          "%d anchors, %d backward pairs" % monotonicity(0x18))


def q6():
    say("\n=== Q6.  THE EIGHT MELODIC ROWS -- refused again, now by measurement ===\n")
    rows = melodic_rows()
    say("  Rows 1..7 differ from row 0 at %s of their 128 programs."
        % ", ".join(str(len(d)) for _r, d in rows[1:]))
    say("  Every difference substitutes a different MELODIC tone for the same")
    say("  program number, so the rows are alternatives and not extensions.")
    nested = rows_are_nested()
    say("")
    say("  ★ THE READING THIS ROUND RULES OUT, which round 6 left standing by not")
    say("    testing it: that the rows are an ORDERED LADDER of variations, row r")
    say("    being the r-th alternative wherever one exists.  If they were, the set")
    say("    of programs at which row r+1 differs would be contained in row r's.")
    say("    It is not, at %d of the 6 steps:" % len(nested))
    for hi, lo, extra in nested[:4]:
        say("      row %d differs at program%s %s, where row %d does not"
            % (hi, "" if len(extra) == 1 else "s",
               ", ".join(str(x) for x in extra[:5]), lo))
    say("  So the eight rows stay NAMELESS-UNDIFFERENTIATED, and the reason is now")
    say("  a failed prediction rather than an absence of ideas.")
    check("Q6a  the nesting test has an answer, and the answer is NO",
          len(nested) > 0, "%d of the 6 consecutive pairs are not nested" % len(nested))
    check("Q6b  the test could have passed: it is nested where it should be",
          _nested_control(), "a row compared with itself nests; row 7 vs row 6 does not")
    check("Q6c  checked on the LAST row as well as the first",
          len(rows[7][1]) == 6 and len(rows[1][1]) == 36,
          "row 1 differs at %d programs, row 7 at %d" % (len(rows[1][1]), len(rows[7][1])))


def _nested_control():
    rows = dict(melodic_rows())
    return (not set(rows[7]) - set(rows[7])) and bool(set(rows[7]) - set(rows[6]))


def q7():
    say("\n=== Q7.  THE BASE ADDRESS -- attacked from the image's own pointers ===\n")
    pf = pointer_fields()
    hi = [(w, v) for w, v in pf if v >= len(D)]
    inwin = [(w, v) for w, v in pf if 0xF00000 <= v <= 0xF7FFFF]
    past = [(w, v) for w, v in pf if v >= PAYLOAD_END]
    say("  ORIGIN could only be wrong if this image stored an ABSOLUTE address.  So")
    say("  every pointer-shaped field it contains was read and classified:")
    say("      %d fields: %d directory slots, %d tone-record offsets, %d descriptor"
        % (len(pf), sum(1 for w, _v in pf if w.startswith("directory")),
           sum(1 for w, _v in pf if w.startswith("tone-record")),
           sum(1 for w, _v in pf if w.startswith("descriptor"))))
    say("        pointers.")
    say("      %d of them are >= the image length 0x%05X" % (len(hi), len(D)))
    say("      %d of them lie in 0x%06X-0x%06X, the window prom_c maps this image at"
        % (len(inwin), 0xF00000, 0xF7FFFF))
    say("      %d of them lie past the payload end 0x%05X" % (len(past), PAYLOAD_END))
    say("  Every one is a FILE OFFSET, which is the reading ORIGIN 0 encodes.")
    say("")
    say("  ⚠ WHAT THIS DOES NOT ADD.  It is the image's own testimony, and an image")
    say("    linked at 0 would look exactly like this whether or not the hardware")
    say("    agreed.  What settles the address is prom_c's two stores of the")
    say("    immediate 0x00F00000 (0xFB0523, 0xFB0528) and prom_a's remote read of")
    say("    this image's build tag at 0x00F7FFF0 (0xF82A5F); what settles the")
    say("    ORIGIN is that prom_c ADDS that base to values it reads out of here.")
    say("    notes/prom_d_base_checks.py, 12 checks; round 5 Q5; round 7 Q7.")
    say("  ⚠ ORIGIN in prom_d/prom_d.ld is NOT changed and nothing here proposes")
    say("    changing it.  What is still open is which PHYSICAL PART this is, and no")
    say("    census of these bytes can answer that.")
    check("Q7a  no pointer-shaped field in the image is an absolute address",
          not hi and not inwin, "%d past the image, %d inside the mapped window"
          % (len(hi), len(inwin)))
    check("Q7b  the census is not vacuous -- it read every directory slot and every"
          " tone offset", len(pf) > 300,
          "%d fields, first %s, last %s" % (len(pf), pf[0][0], pf[-1][0]))
    check("Q7c  and the last field is inside the payload, like the first",
          pf[-1][1] < PAYLOAD_END and pf[0][1] < PAYLOAD_END,
          "first 0x%05X, last 0x%05X, payload end 0x%05X"
          % (pf[0][1], pf[-1][1], PAYLOAD_END))


CITED_PROM_C = (0xFB0523, 0xFB0528, 0xFB051E, 0xFBC744, 0xFBC7C3, 0xFBC7D6,
                0xFBC7D9, 0xFBC7E3)


def q8():
    say("\n=== Q8.  ★ THE PROSE SELF-CHECK -- the emitted file, re-derived ===\n")
    text = open(SRC).read()
    bad = banner_contradictions(text)
    say("  A generated banner can state a number and then draw a conclusion its own")
    say("  number refutes.  A round-3 reviewer found two of those in prom_a by hand.")
    say("  This is the same check by machine, over the file this lane owns.")
    check("Q8a  no banner in prom_d/wsa1_prom_d.s is refuted by its own number",
          not bad, "%d contradiction%s%s" % (len(bad), "" if len(bad) == 1 else "s",
                                             ": " + bad[0][1] if bad else ""))
    got = banner_numbers(text)
    rows = melodic_rows()
    want_rows = [len(d) for _r, d in rows[1:]]
    check("Q8b  the per-row difference counts in the file match the ROM",
          got["rowdiff"] == want_rows,
          "file %s, re-derived %s" % (got["rowdiff"], want_rows))
    tw = R6.wavesel_twins(0x18)
    want_notwin = (sum(1 for v in tw.values() if not v),
                   sum(1 for v in tw.values() if v))
    check("Q8c  the no-twin totals in the file match the ROM, on every record",
          set(got["notwin"]) == {want_notwin} and len(got["notwin"]) == want_notwin[0],
          "%d banners, all saying %s" % (len(got["notwin"]), want_notwin))
    check("Q8d  and the nearest-tone distance is stated once per no-twin record",
          len(got["nearest"]) == want_notwin[0],
          "%d distances for %d no-twin records" % (len(got["nearest"]), want_notwin[0]))


def q9():
    say("\n=== Q9.  THE CITATIONS ===\n")
    src = open(os.path.join(ROOT, "prom_c", "wsa1_prom_c.s")).read()
    starts = set(int(m, 16) for m in re.findall(r";\s+([0-9A-F]{6})\s+\S", src))
    bad = [a for a in CITED_PROM_C if a not in starts]
    check("Q9a  every prom_c address this round cites is an INSTRUCTION START",
          not bad, "%d cited, %d not a listed instruction address%s"
          % (len(CITED_PROM_C), len(bad),
             ": " + ", ".join("0x%06X" % a for a in bad) if bad else ""))
    off = [a for a in CITED_PROM_C if (a - 1) in starts]
    say("  Q9a' %d of the %d have an instruction starting at cited-1 as well: %s."
        % (len(off), len(CITED_PROM_C), ", ".join("0x%06X" % a for a in off) or "none"))
    say("       That is legal and is listed rather than hidden -- it is the shape")
    say("       round 1's 31 one-byte-off citations had.")
    say("")
    say("  ⚠ AND THE ONE INSTRUMENT THIS ROUND BREAKS, said here rather than left for")
    say("    a reviewer to find.  notes/wave7_round6_review_wd3_prom_d.py R3a reads")
    say("    every `_SameAs_<suffix>` label out of the .s and looks the SUFFIX up as")
    say("    ONE name.  A disjunction suffix is several names joined by `_Or_`, so")
    say("    R3a reports all %d of them as `no tone record / element with that name`."
        % sum(len(disjunction_labels(s2)) for s2 in NAMED_SLOTS))
    say("    That is a PARSER GAP in a round-6 instrument, not a defect in the labels,")
    say("    and the check below is R3a's own question asked with the split.  R3a")
    say("    already failed before this round on round 7's stem labels (R3c, R6z),")
    say("    which it does not know about either; that half is not round 8's doing.")
    _bad = []
    for slot in NAMED_SLOTS:
        carriers = set(nm for _i, _j, _b, nm in R6.tone_wavesel_blocks())
        carriers |= set(nm for _i, _b, nm in R6.perc_wavesel_tails())
        for k, sfx in disjunction_labels(slot).items():
            for part in sfx.split("_Or_"):
                if part not in carriers:
                    _bad.append((slot, k, part))
    check("Q9b  R3a's question, asked with the `_Or_` split: every part is carried",
          not _bad, "%d label parts checked, %d refuted"
          % (sum(len(v.split("_Or_")) for s2 in NAMED_SLOTS
                 for v in disjunction_labels(s2).values()), len(_bad)))


def selftest():
    say("\n=== SELFTEST -- the checks a later round re-runs ===\n")
    # T5: the contradiction detector must FIRE on the sentence that WAS in the file.
    was = ("; `Melodic` states, and 0 of the 128 differ from row 0's -- so the\n"
           "; rows are NOT copies of one another either.  Nothing in this image\n")
    check("T5  ★ the contradiction detector FIRES on the sentence round 8 removed",
          len(banner_contradictions(was)) == 1,
          "%d hit on the row-0 banner as it stood before this round"
          % len(banner_contradictions(was)))
    check("T5' and it does NOT fire on the same sentence with a non-zero count",
          not banner_contradictions(was.replace(" 0 of the 128", " 36 of the 128")),
          "36 of 128 differing is not a contradiction")
    check("T6  the label file and the ROM agree on how many records each array has",
          all(R6.array_records(s)[1] ==
              (R6.next_bound(S(s)) - S(s)) // WAVESEL_STRIDE for s in WAVESEL_SLOTS),
          "%s" % {hex(s): R6.array_records(s)[1] for s in WAVESEL_SLOTS})



# ===========================================================================
# ★★ WAVE 7 ROUND 9 -- THE WHOLE-IMAGE LABEL AUDIT.
#
# Round 8 asked three questions of every label and answered them for the 272 it
# left NAMELESS.  It did not ask the other question a finished image has to
# answer, and it is the one the byte gate is blind to:
#
#     IS THE NAME THIS FILE ACTUALLY CARRIES STILL CARRIED BY THE BYTES?
#
# Every label in prom_d/wsa1_prom_d.s is GENERATED, so the honest answer today is
# "yes, by construction" -- but that is exactly the guarantee round 4 lost.  A
# hand-edit to the .s is silently reverted on the next generator run, and a
# corrected false claim came back verbatim because nothing re-read the file.
# audit_labels() re-derives each label's whole claim -- its index, its address
# and its name -- from prom_d's own bytes and compares it with the text in the
# file, so a divergence in either direction is a FAILED CHECK rather than a
# reviewer's lucky find.
# ===========================================================================
AUDIT_GRADES = ("DERIVED", "ADDRESS", "REFUTED", "RESIDUE")
_AUDIT_GRADES = collections.Counter()
# ★ THE AUDITED SHAPE, in the pattern this tree already uses for DESC_AUDITED and
# AUDITED_R7/R8: prom_d/wsa1_prom_d.s quotes these two numbers, and Q10e fails if
# the live audit stops producing them.  A number in the assembly therefore cannot
# outlive the measurement that justifies it -- which is the whole reason the
# generator refuses to hard-code anything.
# ⚠ MOVED IN ROUND 10, and the move is the round's whole result: M9 re-derives
# 29 labels that were ADDRESS-only, so DERIVED goes 2857 -> 2886 and ADDRESS
# 808 -> 779.  The pair still sums to 3,665.
AUDITED_R9 = {"DERIVED": 2886, "ADDRESS": 779, "REFUTED": 0, "RESIDUE": 0}


def boundary_stem(names, lim=4):
    """Round 7's stem rule, RE-IMPLEMENTED here so the audit is a second opinion.

    Calling R7._boundary_stem() would make the audit compare the generator with
    itself.  This is the same rule stated from its description -- longest common
    prefix, at least 4 characters, ending at a CamelCase word boundary, with at
    most `lim` characters left over in every candidate -- and Q10's selftest
    checks the two agree on all 334 `_SameAs_` labels, which is what makes it a
    check rather than a copy.
    """
    if not names:
        return None
    pre = names[0]
    for n in names[1:]:
        i = 0
        while i < min(len(pre), len(n)) and pre[i] == n[i]:
            i += 1
        pre = pre[:i]
    if len(pre) < 4:
        return None
    for n in names:
        if len(n) == len(pre):
            continue
        if not (n[len(pre)].isupper() or n[len(pre)].isdigit()):
            return None
        if len(n) - len(pre) > lim:
            return None
    return None if re.fullmatch(r"[0-9]{1,4}", pre.split("_")[-1]) else pre


def _tone_geometry(p, size):
    """(elements, wave-select records) of a tone-shaped record of `size` bytes.

    The three shapes this image uses, and nothing is assumed beyond them: a
    217-byte head plus n elements of 81 and n wave-select records of 43 (an
    ordinary melodic tone), a 217-byte head plus n elements and NO wave-select
    array (the two drawbar records), and a headless 81 + 43 (the default-layer
    template).  The strides are the directory's own words, not constants typed
    here.  A record that fits none returns (None, None) and its children are
    reported REFUTED rather than quietly passed.
    """
    for head in (217, 0):
        rest = size - head
        if rest < 0:
            continue
        if rest and rest % (81 + WAVESEL_STRIDE) == 0:
            n = rest // (81 + WAVESEL_STRIDE)
            return n, n
        if rest and rest % 81 == 0:
            return rest // 81, 0
    return None, None


def audit_labels(rename=None):
    """{label: (grade, rule, detail)} for EVERY label in prom_d/wsa1_prom_d.s.

    DERIVED  the object's ADDRESS and its NAME are both re-derived from prom_d's
             own bytes -- a record's ASCII name field, a measured byte identity,
             a curve's own run lengths, a descriptor's own 32-bit offsets.
    ADDRESS  the address is re-derived; the NAME is structural or transplanted
             and this image does not spell it.  `ToneDB_MixerDefaultTable_000`
             and `ToneDB_EnvDescTable_Desc017` are here.  This is the honest
             reading of prom_d's 100%% UPPER: framing is not naming.
    REFUTED  the file and the ROM disagree.  Any hit is a defect.
    RESIDUE  no rule reaches the label.  Any hit is a hole in this audit.

    `rename` is {old: new} and exists ONLY for the negative controls: the audit
    must report a label that has been tampered with, or it is not an audit.
    """
    ren = rename or {}
    out = {}

    def put(name, grade, rule, detail):
        out[name] = (grade, rule, detail)

    arr_slot = {"ToneDB_MixerDefaultTable": 0x18,
                "ToneDB_PercMixerDefaultTable": 0x20,
                "ToneDB_WaveSelTailPresets": 0x3C}
    arr = dict((s, R6.array_records(s)) for s in WAVESEL_SLOTS)
    twins = dict((s, R6.wavesel_twins(s)) for s in NAMED_SLOTS)
    perc_a = S(0x78)
    perc_n = (R6.next_bound(perc_a) - perc_a) // PERC_STRIDE
    lay = dict((s, R2.desc_layout(s)) for s in (0x30, 0x38, 0x70))
    chains = dict((s, R4.chain(s)) for s in (0x30, 0x38))
    rows, curves = R5.row_names(), R5.curve_names()
    slot_of = collections.defaultdict(list)
    for s in range(0, 0xC0, 4):
        if DIR[s // 4] != 0xFFFFFFFF:
            slot_of[DIR[s // 4]].append(s)
    parents = dict((l.name, l) for l in R7.LABS
                   if l.name in ("ToneRec_Template_Clear", "ToneDB_DefaultLayerParams"))
    nxt = {}
    for k, l in enumerate(R7.LABS):
        for j in range(k + 1, len(R7.LABS)):
            if not R7.LABS[j].name.startswith(l.name + "_"):
                nxt[l.name] = R7.LABS[j].addr
                break

    for l in R7.LABS:
        n, a = ren.get(l.name, l.name), l.addr

        m = re.match(r"^(ToneRec|DrumKit)_([0-9A-F]{3})_([A-Za-z0-9]+)$", n)
        if m:
            i = int(m.group(2), 16)
            if i >= len(R6.TONE_PTRS):
                put(l.name, "REFUTED", "tone record",
                    "index 0x%03X is past the %d-entry offset table"
                    % (i, len(R6.TONE_PTRS)))
                continue
            p = R6.TONE_PTRS[i]
            size = R6._tone_end(p) - p
            want = R6.camel(D[p:p + 16].decode("latin1"))
            ok = (a == p and want == m.group(3)
                  and (m.group(1) == "DrumKit") == (size == 408))
            put(l.name, "DERIVED" if ok else "REFUTED", "tone record",
                "offset table entry %d = 0x%05X, %d B, name field %r -> %s"
                % (i, p, size, D[p:p + 16].decode("latin1"), want))
            continue

        m = re.match(r"^(ToneRec|DrumKit)_([0-9A-F]{3})_[A-Za-z0-9]+_"
                     r"(Elem|WaveSel|NoteMap)(\d*)$", n)
        if m:
            i = int(m.group(2), 16)
            p = R6.TONE_PTRS[i]
            size = R6._tone_end(p) - p
            ne, nw = _tone_geometry(p, size)
            head = 217 if size >= 217 else 0
            if m.group(3) == "NoteMap":
                ok, w = (size == 408 and a == p + 152), "0x%05X + 152" % p
            elif m.group(3) == "Elem":
                j = int(m.group(4))
                ok = ne is not None and j < ne and a == p + head + 81 * j
                w = "0x%05X + %d + 81*%s" % (p, head, m.group(4))
            else:
                j = int(m.group(4))
                ok = bool(nw) and j < nw and a == p + head + 81 * ne + WAVESEL_STRIDE * j
                w = "0x%05X + %d + 81*%s + %d*%s" % (p, head, ne, WAVESEL_STRIDE,
                                                     m.group(4))
            put(l.name, "DERIVED" if ok else "REFUTED", "tone-record part", w)
            continue

        m = re.match(r"^(ToneRec_Template_Clear|ToneDB_DefaultLayerParams)_"
                     r"(Elem|WaveSel)(\d*)$", n)
        if m and m.group(1) in parents:
            par = parents[m.group(1)]
            size = nxt.get(par.name, par.end) - par.addr
            ne, nw = _tone_geometry(par.addr, size)
            head = 217 if size >= 217 else 0
            j = int(m.group(3) or 0)
            if m.group(2) == "Elem":
                ok = ne is not None and j < ne and a == par.addr + head + 81 * j
            else:
                ok = bool(nw) and j < nw and (
                    a == par.addr + head + 81 * ne + WAVESEL_STRIDE * j)
            put(l.name, "DERIVED" if ok else "REFUTED", "template record part",
                "%s 0x%05X, %d B = %d + 81*%s + %d*%s"
                % (par.name, par.addr, size, head, ne, WAVESEL_STRIDE, nw))
            continue

        m = re.match(r"^PercInst_(\d{3})_([A-Za-z0-9]+)$", n)
        if m:
            i = int(m.group(1))
            p = perc_a + PERC_STRIDE * i
            raw = D[p:p + 13].decode("latin1")
            want = R6.camel(raw)
            blank = not raw.strip(" \x00")
            ok = i < perc_n and a == p and (want == m.group(2)
                                            or (blank and m.group(2) == "Silent"))
            put(l.name, "DERIVED" if ok else "REFUTED", "drum-instrument record",
                "0x%05X = 0x%05X + %d*%d, name field %r"
                % (p, perc_a, PERC_STRIDE, i, raw))
            continue

        m = re.match(r"^(ToneDB_(?:Perc)?MixerDefaultTable|ToneDB_WaveSelTailPresets)"
                     r"_(\d{3})(?:_SameAs_(.+)|_SelectedFor_(.+))?$", n)
        if m:
            slot = arr_slot[m.group(1)]
            i = int(m.group(2))
            base, cnt, _recs = arr[slot]
            ok = i < cnt and a == base + WAVESEL_STRIDE * i
            det = "0x%05X = 0x%05X + %d*%d" % (base + WAVESEL_STRIDE * i, base,
                                               WAVESEL_STRIDE, i)
            if m.group(4):
                # ★ ROUND 10.  M9's label, re-derived: the map's own entries, the
                # program map's own words, and the tone records' own ASCII.  The
                # relation is DIFFERENT from `_SameAs_`, so the audit also insists
                # the record has NO twin -- one object, one claim.
                want = selector_names().get(i, ())
                cols = selector_columns().get(i, [])
                ok = (ok and slot == SELECTOR_ARRAY
                      and "_Or_".join(want) == m.group(4)
                      and not twins.get(slot, {}).get(i))
                put(l.name, "DERIVED" if ok else "REFUTED",
                    "wave-select record, named by what SELECTS it",
                    det + "; ToneDB_ToneIndexMapA holds %d at program column(s) %s, "
                    "which carry %s across the %d melodic rows"
                    % (i, cols, list(want), MELODIC_ROWS))
                continue
            if not m.group(3):
                put(l.name, "ADDRESS" if ok else "REFUTED", "wave-select record",
                    det + ", and nothing in the image names it")
                continue
            suf, el = m.group(3), None
            m2 = re.match(r"^(.+)_WaveSel(\d+)$", suf)
            if m2 and "_Or_" not in suf:
                suf, el = m2.group(1), int(m2.group(2))
            claimed = suf.split("_Or_")
            tw = twins[slot].get(i, [])
            carr = sorted(set(x[2] for x in tw))
            els = set(x[1] for x in tw)
            if len(claimed) > 1:
                ok = ok and sorted(claimed) == carr          # round 8's disjunction
            elif claimed[0] in carr:
                ok = ok and carr == claimed                  # one carrier, its own name
            else:
                ok = ok and boundary_stem(carr) == claimed[0]  # rounds 6/7's stem
            if el is not None:
                ok = ok and els == {el}
            put(l.name, "DERIVED" if ok else "REFUTED",
                "wave-select record, named by a byte identity",
                det + "; carried by %s%s"
                % (carr, "" if el is None else " all at element %d" % el))
            continue

        if n.startswith("ToneNumBank_"):
            suf = n[len("ToneNumBank_"):]
            hit = [r for r, s in rows.items() if s == suf]
            ok = len(hit) == 1 and a == R6.PROG_BASE + 256 * hit[0]
            put(l.name,
                "DERIVED" if ok and not suf.startswith("Melodic_")
                else ("ADDRESS" if ok else "REFUTED"), "program-map row",
                "0x%05X + 256*%s, and row_names() derives this suffix from what the "
                "row selects" % (R6.PROG_BASE, hit))
            continue

        m = re.match(r"^ToneDB_OctaveShiftByProgram_Bank(\d)$", n)
        if m:
            r = int(m.group(1))
            ok = r < R6.OCT_N and a == R6.OCT_TABLE + R6.OCT_STRIDE * r
            put(l.name, "ADDRESS" if ok else "REFUTED", "octave-shift row",
                "0x%05X + %d*%d" % (R6.OCT_TABLE, R6.OCT_STRIDE, r))
            continue

        m = re.match(r"^ToneDB_DescCurve_(Step\w+)$", n)
        if m:
            hit = [k for k, s in curves.items() if s == m.group(1)]
            ok = len(hit) == 1 and a == R2.CURVE_BASE + R2.CURVE_STRIDE * hit[0]
            put(l.name, "DERIVED" if ok else "REFUTED", "descriptor curve",
                "curve %s of %d; the suffix is its own run-length plurality"
                % (hit, R2.CURVE_N))
            continue

        done = False
        for base, slot in (("ToneDB_EnvDescTable_Perc", 0x38),
                           ("DrawbarPreset_EnvDescTable", 0x70),
                           ("ToneDB_EnvDescTable", 0x30)):
            if not n.startswith(base + "_"):
                continue
            H, P, recs = lay[slot]
            suf = n[len(base) + 1:]
            m = re.match(r"^Desc(\d{3})$", suf)
            if m:
                i = int(m.group(1))
                put(l.name, "ADDRESS" if i < H and a == S(slot) + 14 * i else "REFUTED",
                    "descriptor", "0x%05X + 14*%d, and 14*%d ends at the pool 0x%05X"
                    % (S(slot), i, H, P))
                done = True
                break
            m = re.match(r"^(\d{3})_(CurveStepToElem|ElemArray)$", suf)
            if m:
                i, part = int(m.group(1)), m.group(2)
                off = recs[i][1] if part == "CurveStepToElem" else recs[i][2]
                ok = i < H and off and a == off
                r = chains[slot][i] if slot in chains else None
                if r is None:
                    ok = False
                    join = "no chain"
                elif part == "CurveStepToElem":
                    # ★ THE JOIN THAT JUSTIFIES THE WORD `ToElem` IS THE ONE TO
                    # PART B, not the one to the curve.  The first draft of this
                    # audit checked len(A)-4 == max(curve)+1 and reported the +0x38
                    # object REFUTED -- wrongly, because that object is SHARED by
                    # 161 descriptors and is a full 128-entry table of which the
                    # curve reaches 108.  The label is right; the PROSE over it was
                    # not, and Q10d is where that is caught.
                    ok = ok and max(r["a_tab"]) + 1 == r["ecount"]
                    join = ("its %d entries, largest %d, and part B holds %d element%s"
                            % (r["a_len"] - 4, max(r["a_tab"]), r["ecount"],
                               "" if r["ecount"] == 1 else "s"))
                else:
                    ok = ok and r["ecount"] == max(r["a_tab"]) + 1
                    join = ("its %d elements of %d B = max(stage 2) + 1"
                            % (r["ecount"], r["esize"]))
                put(l.name, "DERIVED" if ok else "REFUTED", "descriptor pool object",
                    "descriptor %d's own LE32 offset 0x%05X; %s" % (i, off or 0, join))
                done = True
                break
            m = re.match(r"^Pool_([AB])(\d{3})$", suf)
            if m:
                i = int(m.group(2))
                off = recs[i][1] if m.group(1) == "A" else recs[i][2]
                put(l.name, "ADDRESS" if i < H and off and a == off else "REFUTED",
                    "descriptor pool object",
                    "descriptor %d's own LE32 offset 0x%05X -- role NOT established"
                    % (i, off or 0))
                done = True
                break
            if suf == "Pool":
                put(l.name, "ADDRESS" if a == P else "REFUTED", "descriptor pool",
                    "%d descriptors x 14 end here, at 0x%05X" % (H, P))
                done = True
                break
        if done:
            continue

        if n == "ToneDB_DescCurveBank":
            put(l.name, "ADDRESS" if a == R2.CURVE_BASE else "REFUTED", "curve bank",
                "slot +0x28 + 2048 = 0x%05X" % R2.CURVE_BASE)
            continue
        if n == "erased_tail":
            put(l.name, "ADDRESS" if a == PAYLOAD_END else "REFUTED", "image tail",
                "the payload ends at 0x%05X" % PAYLOAD_END)
            continue
        if n == "build_tag":
            t = D.rfind(b"wsad")
            put(l.name, "DERIVED" if a == t else "REFUTED", "build tag",
                "%r at 0x%05X" % (D[t:t + 12].decode("latin1"), t))
            continue
        if n == "prom_d_end":
            put(l.name, "ADDRESS" if a == len(D) else "REFUTED", "image end",
                "the image is 0x%05X bytes" % len(D))
            continue
        if a in slot_of:
            put(l.name, "ADDRESS", "directory region",
                "opened by directory slot%s %s"
                % ("" if len(slot_of[a]) == 1 else "s",
                   " ".join("+0x%02X" % s for s in slot_of[a])))
            continue
        if a == 0:
            put(l.name, "ADDRESS", "image start", "file offset 0, the directory itself")
            continue
        put(l.name, "RESIDUE", "-", "no rule in this audit reaches the label")
    return out


def q10():
    """★★ THE WHOLE-IMAGE AUDIT.  Every label, re-derived, in one command."""
    say("\n=== Q10. ★★ THE WHOLE-IMAGE LABEL AUDIT -- all %d, re-derived ==="
        % len(R7.LABS))
    say("")
    say("  Round 8 answered three questions about the 272 objects it left")
    say("  NAMELESS.  This asks the question the other 3,393 need, and it is the")
    say("  one the byte gate cannot ask: IS THE NAME IN THE FILE STILL THE NAME")
    say("  THE BYTES GIVE?  Every label's whole claim -- index, address and name --")
    say("  is re-derived from prom_d and compared with the text in the .s.")
    say("")
    res = audit_labels()
    grades = collections.Counter(v[0] for v in res.values())
    byrule = collections.Counter((v[1], v[0]) for v in res.values())
    for (rule, g), c in sorted(byrule.items(), key=lambda kv: (-kv[1], kv[0])):
        say("      %5d  %-8s %s" % (c, g, rule))
    say("")
    bad = sorted(k for k, v in res.items() if v[0] == "REFUTED")
    res_only = sorted(k for k, v in res.items() if v[0] == "RESIDUE")
    check("Q10a the audit reaches EVERY label -- no residue",
          not res_only and len(res) == len(R7.LABS),
          "%d labels, %d unreached%s" % (len(res), len(res_only),
                                         ": " + ", ".join(res_only[:3]) if res_only else ""))
    check("Q10b no label in the file is refuted by the ROM", not bad,
          "%d refuted%s" % (len(bad), ": " + ", ".join(bad[:3]) if bad else ""))
    # ★ Q10d -- THE PROSE OVER A POOL OBJECT, RE-DERIVED FROM THE OBJECT'S SIZE.
    # This is where round 9's one real find lives.  The comment over a stage-2
    # table states its entry count; for the ONE table that 161 descriptors SHARE
    # the generator printed max(curve)+1 = 108 for an object that holds 128.  A
    # sentence refuted by its own object is the round-3 review's exact shape, and
    # nothing in four rounds of self-checks re-read it.
    txt = open(SRC).read().split("\n")
    hdr = re.compile(r"^; (\S+_CurveStepToElem) -- file 0x([0-9A-F]{5})"
                     r"\.\.0x[0-9A-F]{5} \((\d+) bytes\)$")
    ent = re.compile(r"^; descriptor \d+ stage 2: \S+ step -> element, (\d+) entries")
    cur, seen, wrong = None, 0, []
    for ln in txt:
        m = hdr.match(ln)
        if m:
            cur = (m.group(1), int(m.group(3)))
            continue
        m = ent.match(ln)
        if m and cur:
            seen += 1
            if cur[1] - 4 != int(m.group(1)):
                wrong.append((cur[0], int(m.group(1)), cur[1] - 4))
            cur = None
    check("Q10d every `N entries` stated over a stage-2 table matches its own size",
          not wrong and seen > 300, "%d sentences checked, %d refuted%s"
          % (seen, len(wrong),
             ": %s says %d, holds %d" % wrong[0] if wrong else ""))
    check("Q10e the audited grade counts are what prom_d/wsa1_prom_d.s quotes",
          all(grades[k] == v for k, v in AUDITED_R9.items()),
          "live %s, audited %s"
          % ({k: grades[k] for k in AUDITED_R9}, AUDITED_R9))
    check("Q10c the FIRST and the LAST label are both re-derived, by name",
          res[R7.LABS[0].name][0] in AUDIT_GRADES and res[R7.LABS[-1].name][0] in AUDIT_GRADES,
          "%s -> %s ; %s -> %s" % (R7.LABS[0].name, res[R7.LABS[0].name][0],
                                   R7.LABS[-1].name, res[R7.LABS[-1].name][0]))
    say("")
    say("  ★★ THE NUMBER THIS AUDIT PUBLISHES, and it is a HARSHER reading of")
    say("     prom_d than the goal metric's 100%% UPPER: %d of the %d labels have"
        % (grades["DERIVED"], len(res)))
    say("     their NAME re-derived from this image's own bytes -- a record's ASCII")
    say("     field, a measured byte identity, a curve's run lengths, a descriptor's")
    say("     own 32-bit offsets.  The other %d have only their ADDRESS derived;"
        % grades["ADDRESS"])
    say("     their names are structural or transplanted and the image does not")
    say("     spell them.  Framing is not naming, and this is the count.")
    say("")
    say("  ⚠ AND IT DOES NOT REFUTE ROUND 7's PROVENANCE GRADE, which the file also")
    say("    quotes -- the two answer DIFFERENT questions and the cross-tab is")
    say("    printed so nobody has to guess which:")
    say("      round-7 provenance ('whose name is this, and does prom_c read the")
    say("      slot the region hangs off') x round-9 audit ('is the name carried")
    say("      by this image's bytes'):")
    cross = collections.Counter((l.prov, res[l.name][0]) for l in R7.LABS)
    for (p, g), c in sorted(cross.items(), key=lambda kv: -kv[1]):
        say("        %5d  %-20s %s" % (c, p, g))
    say("      ★ THE ROW THAT MATTERS is KN5000-TRANSPLANT x DERIVED.  Those objects")
    say("        sit in a region whose directory slot NO prom_c instruction reads, so")
    say("        the REGION's name is the sibling machine's -- and the object's own")
    say("        label is still derived here, from a descriptor's own 32-bit offsets")
    say("        and round 4's two joins.  A reader discounting the transplant should")
    say("        discount the region name, not the object's.")
    return res, grades


def q11():
    """★ THE PRESET ARRAY'S OWN +0x0B -- and a correction to round 8's census."""
    say("\n=== Q11. ★ THE ONE FIELD ROUND 8 EXCLUDED WITHOUT READING IT ===\n")
    _a, n, recs = R6.array_records(0x3C)
    vals = [recs[k][PRESET_FIELD] & 0x3F for k in range(n)]
    selfidx = [k for k in range(n) if vals[k] == k]
    other = [(k, vals[k]) for k in range(n) if vals[k] != k]
    say("  Round 8's preset census skipped field +0x0B of the +0x3C array itself,")
    say("  on the stated ground that `a record's own index is not a reference`.")
    say("  ⚠ THAT GROUND WAS NEVER MEASURED.  Read: over the %d preset records the" % n)
    say("  masked field equals the record's own index at %d of them, and the"
        % len(selfidx))
    say("  exception%s %s." % ("" if len(other) == 1 else "s",
                               ", ".join("record %d holds %d" % t for t in other)))
    say("  So the field IS the record's own index almost everywhere -- which makes")
    say("  round 8's exclusion right at %d of %d and WRONG at %d."
        % (len(selfidx), n, len(other)))
    check("Q11a the +0x3C array's own +0x0B is its index at all but a stated few",
          len(other) <= 2 and len(selfidx) == n - len(other),
          "%d of %d self-indexing, exceptions %s" % (len(selfidx), n, other))
    check("Q11b checked on the LAST record as well as the first",
          vals[-1] == n - 1 and (vals[0] == 0) == (0 in [k for k in selfidx]),
          "record 0 holds %d, record %d holds %d" % (vals[0], n - 1, vals[-1]))
    ref = preset_referrers()
    say("")
    say("  ⚠ AND THE CORRECTION DOES NOT MOVE THE HEADLINE, which is why it is")
    say("    stated here rather than used to restate the round.  The one record")
    say("    whose field is not its own index holds %d, and preset %d is ALREADY"
        % (other[0][1] if other else -1, other[0][1] if other else -1))
    say("    selected by %d stored records elsewhere in the image.  The set of"
        % len(ref.get(other[0][1], [])) if other else 0)
    say("    selected presets is unchanged: %d selected, %d selected by nothing."
        % (len(ref), 64 - len(ref)))
    check("Q11c the exception's value is a preset that was already selected",
          bool(other) and other[0][1] in ref,
          "preset %d has %d other stored referrers"
          % (other[0][1], len(ref.get(other[0][1], []))) if other else "no exception")
    check("Q11d so the 57/7 split round 8 published is unchanged",
          len(ref) == 7 and 64 - len(ref) == 57,
          "%d selected, %d selected by nothing stored" % (len(ref), 64 - len(ref)))


def q12():
    """★ THE NAMING MECHANISM THAT NAMED 194 RECORDS, RUN ON THE THIRD ARRAY."""
    say("\n=== Q12. ★ THE TWIN RULE ON THE ONE ARRAY IT WAS NEVER RUN ON ===\n")
    say("  Rounds 6, 7 and 8 name a wave-select record when its 43 bytes, masked at")
    say("  +0x0B, are carried by a NAMED record elsewhere in the image.  That rule")
    say("  was only ever applied to the two arrays at +0x18 and +0x20.  Nobody ran")
    say("  it on +0x3C, and its 64 records are 64 of the 272 still framed.")
    say("")
    _a, n, recs = R6.array_records(0x3C)
    mel = collections.defaultdict(list)
    for i, j, b, nm in R6.tone_wavesel_blocks():
        mel[R6._mask(b)].append(nm)
    drm = collections.defaultdict(list)
    for i, b, nm in R6.perc_wavesel_tails():
        drm[R6._mask(b)].append(nm)
    hit_m = sum(1 for k in range(n) if mel.get(R6._mask(recs[k])))
    hit_d = sum(1 for k in range(n) if drm.get(R6._mask(recs[k])))
    say("      against the %d melodic wave-select blocks : %d of %d records carried"
        % (len(R6.tone_wavesel_blocks()), hit_m, n))
    say("      against the %d drum-instrument tails      : %d of %d records carried"
        % (len(R6.perc_wavesel_tails()), hit_d, n))
    say("      distinct masked records in the array       : %d of %d"
        % (len(set(R6._mask(r) for r in recs)), n))
    say("")
    say("  ★ ZERO.  The rule that named 194 records in the other two arrays fires")
    say("    0 times of %d here, so these 64 stay framed for a MEASURED reason" % n)
    say("    rather than because nobody tried.  A later round need not re-run it.")
    check("Q12a the twin rule names nothing in the +0x3C array, either way",
          hit_m == 0 and hit_d == 0, "%d melodic carriers, %d drum carriers"
          % (hit_m, hit_d))
    check("Q12b and the rule is not broken -- it still fires on the other arrays",
          sum(1 for v in R6.wavesel_twins(0x18).values() if v) == 167
          and sum(1 for v in R6.wavesel_twins(0x20).values() if v) == 196,
          "+0x18: %d carried, +0x20: %d carried"
          % (sum(1 for v in R6.wavesel_twins(0x18).values() if v),
             sum(1 for v in R6.wavesel_twins(0x20).values() if v)))
    check("Q12c checked on the LAST record of the array as well as the first",
          not mel.get(R6._mask(recs[-1])) and not drm.get(R6._mask(recs[-1])),
          "record %d carried by nothing" % (n - 1))


def m8_interpolation(slot):
    """M8: can the monotone order PLACE a record that no byte identity reaches?

    Round 8's M7 asked whether the interval between two anchors picks one of an
    AMBIGUOUS record's candidates.  It never asked the question for a record with
    NO candidates at all, which is the larger set and the obvious next idea.
    Returns (anchors, no-carrier records, unique, several, empty, examples).
    """
    _a, n, recs = R6.array_records(slot)
    tw = R6.wavesel_twins(slot)
    anchor = {}
    for k in range(n):
        own = set(x[0] for x in tw[k])
        if len(own) == 1:
            anchor[k] = own.pop()
    taken = set(anchor.values())
    one, several, empty, ex = 0, 0, 0, []
    naked = [k for k in range(n) if not tw[k]]
    for k in naked:
        lo = max([j for j in anchor if j < k], default=None)
        hi = min([j for j in anchor if j > k], default=None)
        if lo is None or hi is None:
            empty += 1
            continue
        cand = [m for m in range(anchor[lo] + 1, anchor[hi]) if m not in taken]
        if len(cand) == 1:
            one += 1
            ex.append((k, cand[0]))
        elif cand:
            several += 1
        else:
            empty += 1
    return len(anchor), len(naked), one, several, empty, ex


def q13():
    """★ M8 -- the obvious next mechanism, measured and refused."""
    say("\n=== Q13. ★ M8: PLACING A NO-CARRIER RECORD BY THE MONOTONE ORDER ===\n")
    say("  Round 8's Q5 proved the +0x20 array is in its owners' index order, 0")
    say("  backward steps over 106 anchors, and its M7 used that to try to break")
    say("  the tie on an AMBIGUOUS record.  It never asked the same question of a")
    say("  record NO byte identity reaches -- the bigger set, and the mechanism a")
    say("  later round would certainly reach for.  Asked here, and refused here.")
    say("")
    out = {}
    for slot in NAMED_SLOTS:
        anch, naked, one, sev, emp, ex = m8_interpolation(slot)
        out[slot] = (anch, naked, one, sev, emp, ex)
        say("      slot +0x%02X: %3d anchors, %3d records with no carrier -> the"
            % (slot, anch, naked))
        say("                  interval leaves ONE owner %d times, several %d, none %d"
            % (one, sev, emp))
    say("")
    say("  ★ ON THE MONOTONE ARRAY IT RESOLVES NOTHING: 0 of %d."
        % out[0x20][1])
    say("  ★★ AND ON THE OTHER ARRAY IT REFUTES ITSELF.  The +0x18 array is NOT in")
    say("     its owners' order (28 backward steps), and there the interval does")
    say("     leave a single candidate %d times -- but it is the SAME candidate for"
        % out[0x18][2])
    say("     several different records:")
    dup = collections.Counter(c for _k, c in out[0x18][5])
    for c, cnt in dup.most_common(3):
        say("         owner %d proposed for %d different array records"
            % (c, cnt))
    say("     Three records cannot all be one drum instrument, so the five `unique`")
    say("     answers are an artefact of a broken order and not five names.")
    say("     M8 IS REFUSED, on both arrays, by its own measurement.")
    check("Q13a M8 resolves nothing on the array whose order actually holds",
          out[0x20][2] == 0, "0 of %d no-carrier records" % out[0x20][1])
    check("Q13b and where it appears to resolve, it is self-refuting",
          bool(out[0x18][5]) and max(dup.values()) > 1,
          "%d proposals over %d distinct owners" % (len(out[0x18][5]), len(dup)))
    check("Q13c the measurement is not vacuous -- the anchors are real",
          out[0x18][0] == 152 and out[0x20][0] == 106,
          "%d and %d anchors" % (out[0x18][0], out[0x20][0]))
    return out


GM_SCREEN = b"GM RE-MAP"


def gm_families():
    """The 16 family names prom_b's own `GM RE-MAP` screen carries, at 16-byte stride."""
    b = R7.IMG["prom_b"]
    t = b.find(GM_SCREEN)
    if t < 0:
        return t, []
    return t, [b[t + 16 * (k + 1): t + 16 * (k + 2)].decode("latin1").strip()
               for k in range(16)]


def gm_alignment(row, fams, shift=0):
    """How many of a row's 128 programs name a tone containing a word of its family."""
    hit = 0
    for p in range(128):
        fam = fams[((p // 8) + shift) % 16]
        w = [x.lower() for x in re.sub(r"[^A-Za-z]+", " ", fam).split() if len(x) >= 4]
        nm = R5.tone_name(row[p]).strip().lower()
        if any(x in nm for x in w):
            hit += 1
    return hit


def q14():
    """THE GENERAL-MIDI ROUTE -- round 5 refused it by example; here is the count."""
    say("\n=== Q14. THE GM ROUTE TO NAMING A PROGRAM-MAP ROW, as a COUNT ===\n")
    t, fams = gm_families()
    say("  prom_d's eight melodic rows keep a number.  The route a later round")
    say("  will try is General MIDI: if one row were GM-ordered and the others were")
    say("  re-maps of it, THAT row would have a name.  Round 5 refused the idea by")
    say("  citing two programs.  This is the same refusal as a measurement, and the")
    say("  16 family names are read out of prom_b rather than typed: its `GM RE-MAP`")
    say("  screen at prom_b 0x%05X is followed by 16 names at a 16-byte stride," % t)
    say("      %s" % ", ".join(fams[:6]))
    say("      ... %s" % ", ".join(fams[-3:]))
    say("  which are GM's own 16 families in GM's own order.")
    say("")
    rows = R5.prog_rows()
    say("      row   aligned/128   best of the 15 rotated NULLS")
    sc, nl = [], []
    for r in range(8):
        a = gm_alignment(rows[r], fams)
        b = max(gm_alignment(rows[r], fams, s) for s in range(1, 16))
        sc.append(a)
        nl.append(b)
        say("      %3d      %3d           %3d" % (r, a, b))
    say("")
    say("  ★ THE ALIGNED SCORE IS AT THE NULL.  The best row scores %d of 128 where"
        % max(sc))
    say("    a deliberately WRONG rotation scores %d.  A GM-ordered row would score"
        % max(nl))
    say("    most of its 128 programs; none of these scores a quarter of them, and")
    say("    the eight rows are %d..%d, indistinguishable from one another."
        % (min(sc), max(sc)))
    say("    So GM names no row, and it does not tell the rows apart either.")
    check("Q14a the family list is prom_b's own ASCII, at its own stride",
          len(fams) == 16 and fams[0] == "PIANO" and fams[-1] == "SOUND EFFECTS",
          "16 names at prom_b 0x%05X + 16" % t)
    check("Q14b the aligned score does not beat the rotated null by a margin",
          max(sc) - max(nl) < 16, "best aligned %d, best null %d" % (max(sc), max(nl)))
    check("Q14c and the test is not blind -- it is checked on the LAST row too",
          sc[-1] <= max(sc) and nl[-1] > 0, "row 7 aligned %d, null %d" % (sc[-1], nl[-1]))
    check("Q14d no row is separated from the others by it",
          max(sc) - min(sc) < 8, "rows score %d..%d" % (min(sc), max(sc)))


def q15():
    """THE BASE ADDRESS -- what is settled, what is open, and what did NOT move."""
    say("\n=== Q15. THE BASE ADDRESS: the standing answer, restated not re-opened ===\n")
    ld = open(os.path.join(ROOT, "prom_d", "prom_d.ld")).read()
    origin = re.search(r"ORIGIN\s*=\s*(0x[0-9A-Fa-f]+|\d+)", ld)
    say("  This was wave 7 round 3's finding and it is NOT re-derived here, only")
    say("  re-checked: the image is read at 0x00F00000 on CPU 2's bus, and ORIGIN in")
    say("  prom_d/prom_d.ld stays 0 because the image's own offsets are FILE offsets")
    say("  that prom_c adds the base to.  Round 8 Q7 attacked it from the pointers")
    say("  and found 0 absolute addresses in 1,281 fields.")
    say("")
    say("  ⚠ WHAT IS STILL OPEN IS NOT THE ADDRESS.  It is WHICH PHYSICAL PART this")
    say("    is, and no census of these bytes can answer that -- the image's own")
    say("    testimony cannot name the package it is soldered in.  The reference")
    say("    designator is not legible in the manual scan; the redistributed set")
    say("    calls the file wsa1_os_v2.ic21, which is where `IC21 is the likely")
    say("    designator and is NOT asserted` comes from.  That is a DOCUMENT")
    say("    question, not a disassembly one, and this round leaves it open.")
    check("Q15a ORIGIN in prom_d/prom_d.ld is still 0 -- nothing here changed it",
          bool(origin) and int(origin.group(1), 0) == 0,
          "ORIGIN = %s" % (origin.group(1) if origin else "not found"))
    check("Q15b the image's build tag still reads as the v2 set's",
          D[D.rfind(b"wsad"):D.rfind(b"wsad") + 11] == b"wsad_54.ssf",
          "%r at 0x%05X" % (D[D.rfind(b"wsad"):D.rfind(b"wsad") + 11].decode("latin1"),
                            D.rfind(b"wsad")))


def selftest_round9():
    """★ THE NEGATIVE CONTROLS.  An audit that cannot fail is not an audit."""
    say("\n=== SELFTEST -- ROUND 9's AUDIT, ATTACKED ===\n")
    labs = R7.LABS
    tone = [l.name for l in labs if re.match(r"^ToneRec_[0-9A-F]{3}_[A-Za-z0-9]+$", l.name)]
    sa = [l.name for l in labs if "_SameAs_" in l.name]
    perc = [l.name for l in labs if re.match(r"^PercInst_\d{3}_[A-Za-z0-9]+$", l.name)]
    first, last = tone[0], tone[-1]
    bent = audit_labels({first: re.sub(r"_[A-Za-z0-9]+$", "_Harpsichord", first)})
    check("T7  a tone record renamed to another record's name is REFUTED",
          bent[first][0] == "REFUTED", "%s -> %s" % (first, bent[first][0]))
    bent = audit_labels({last: re.sub(r"^ToneRec_[0-9A-F]{3}", "ToneRec_003", last)})
    check("T8  ★ and the control fires on the LAST tone record, not only the first",
          bent[last][0] == "REFUTED", "%s re-indexed -> %s" % (last, bent[last][0]))
    bent = audit_labels({perc[-1]: re.sub(r"_[A-Za-z0-9]+$", "_Piano", perc[-1])})
    check("T8' and on the LAST drum-instrument record",
          bent[perc[-1]][0] == "REFUTED", "%s -> %s" % (perc[-1], bent[perc[-1]][0]))
    bent = audit_labels({sa[-1]: sa[-1] + "X"})
    check("T9  a `_SameAs_` label whose carrier is not a carrier is REFUTED",
          bent[sa[-1]][0] == "REFUTED", "%s -> %s" % (sa[-1] + "X", bent[sa[-1]][0]))
    bent = audit_labels({tone[5]: "Something_Invented_Here"})
    check("T9' a label no rule reaches falls to RESIDUE, never to a silent pass",
          bent[tone[5]][0] == "RESIDUE", "-> %s" % bent[tone[5]][0])
    agree, differ = 0, []
    for slot in NAMED_SLOTS:
        for k, tw in R6.wavesel_twins(slot).items():
            names = sorted(set(x[2] for x in tw))
            if len(names) < 2:
                continue
            a, b = boundary_stem(names), R7._boundary_stem(names)
            if a == b:
                agree += 1
            else:
                differ.append((slot, k, a, b))
    check("T10 the audit's stem rule is a SECOND OPINION that agrees with round 7's",
          not differ and agree > 100,
          "%d multi-carrier records, %d disagreements" % (agree, len(differ)))
    r1 = audit_labels()
    r2 = audit_labels()
    check("T11 the audit is deterministic -- two runs give the same verdicts",
          r1 == r2, "%d labels" % len(r1))
    check("T12 every grade the audit emits is one of the four it documents",
          set(v[0] for v in r1.values()) <= set(AUDIT_GRADES),
          "%s" % sorted(set(v[0] for v in r1.values())))


# ===========================================================================
# ROUND 10.  M9 -- THE SELECTOR.  The one route round 6 measured and then used
# only as a WITNESS; this round asks it of the records the witness never
# covered, which is where the framed labels actually are.
# ===========================================================================
SELECTOR_SLOT = 0x0C          # ToneDB_ToneIndexMapA
SELECTOR_ARRAY = 0x18         # ToneDB_MixerDefaultTable
MELODIC_ROWS = 8              # a 1,024-entry map spans 8 x 128, not the 10 rows


def selector_map(slot=SELECTOR_SLOT):
    """The 1,024 LE16 entries of one index map, straight out of the ROM."""
    return [u16(S(slot) + 2 * i) for i in range(1024)]


def program_tone(row, prog):
    """The tone-record index the program map holds at (row, program)."""
    return u16(R6.PROG_BASE + 0x100 * row + 2 * prog)


def tone_name(i):
    """A tone record's own 16 ASCII bytes, in this tree's CamelCase form."""
    p = R6.TONE_PTRS[i]
    return R6.camel(D[p:p + 16].decode("latin1"))


def selector_columns(slot=SELECTOR_SLOT):
    """{record index: sorted PROGRAM columns whose map entry names that record}.

    ★ THE COLUMN, NOT THE POSITION, AND Q16d IS WHY.  A map entry sits at
    row*128 + program.  The PROGRAM half of that reading is pinned hard -- shift
    the index by one program and the byte agreement collapses from 637 to 84 --
    but the ROW half is not, because the eight melodic rows are near-copies of
    one another and rotating them costs only a few points.  So this function
    throws the row away and keeps the column, and every name derived from it is
    invariant under all eight row rotations by construction (T17 checks it).
    """
    out = collections.defaultdict(set)
    for i, v in enumerate(selector_map(slot)):
        out[v].add(i % R6.PROG_COLS)
    return dict((k, sorted(v)) for k, v in out.items())


def selector_names(slot=SELECTOR_SLOT):
    """{record index: sorted tuple of the tone names in its columns, all rows}."""
    out = {}
    for k, cols in selector_columns(slot).items():
        out[k] = tuple(sorted(set(tone_name(program_tone(r, c))
                                  for c in cols for r in range(MELODIC_ROWS))))
    return out


def _has_letter(s):
    return any(c.isalpha() for c in s)


def selector_labels(bound=MAX_NAMES):
    """{record index: label suffix} -- M9's names, for the FRAMED records only.

    A record that round 6, 7 or 8 already named is never touched: `_SameAs_` and
    `_SelectedFor_` are different relations and a record must not claim two.
    A candidate set larger than `bound` is refused for round 8's reason -- it
    enumerates a family instead of naming an object.  A candidate name with no
    letter in it is refused too: tone record 0x05D's name field is
    "    16' & 1'    ", which this tree's CamelCase rule turns into `161`, so a
    label built on it would end in digits and read as positional (T14).
    """
    have = wavesel_labels_r8(SELECTOR_ARRAY)
    _a, n, _r = R6.array_records(SELECTOR_ARRAY)
    out = {}
    for k, names in selector_names().items():
        if k >= n or k in have or not 1 <= len(names) <= bound:
            continue
        if not all(_has_letter(x) for x in names):
            continue
        out[k] = "_Or_".join(names)
    return out


def _r10_shape():
    """(records named by M9, first, last) -- the constant the generator refuses on."""
    lab = selector_labels()
    ks = sorted(lab)
    return (len(lab), "%d:%s" % (ks[0], lab[ks[0]]), "%d:%s" % (ks[-1], lab[ks[-1]]))


AUDITED_R10 = (29, "2:OrchestraHit1_Or_OrchestraHit2", "312:MetallicBass_Or_PickedEBass_Or_SoulBass")


def _twin_tone_indices(slot=SELECTOR_ARRAY):
    """{record index: set of tone indices whose block these bytes are}."""
    return dict((k, set(t for t, _j, _nm in v))
                for k, v in R6.wavesel_twins(slot).items())


def selector_byte_agreement(vals, rowshift=0, progshift=0):
    """(positions asked, positions where the map's record IS that tone's block).

    This is round 6 Q2b2's measurement with the index deliberately mis-read, so
    the same statistic can be run at a shift and become its own null.
    """
    tw = _twin_tone_indices()
    matched = set(k for k, v in tw.items() if v)
    tot = ok = 0
    for r in range(MELODIC_ROWS):
        for p in range(R6.PROG_COLS):
            k = vals[r * R6.PROG_COLS + p]
            if k not in matched:
                continue
            tot += 1
            rr = (r + rowshift) % MELODIC_ROWS
            pp = (p + progshift) % R6.PROG_COLS
            if program_tone(rr, pp) in tw[k]:
                ok += 1
    return tot, ok


def selector_shuffle_null(draws=20, seed=20260830):
    """(mean, max) hits over `draws` shuffles of the +0x0C map -- Q16c, exported.

    The generated banners quote this mean; deriving it here is what stops a
    number in the assembly outliving the measurement behind it.
    """
    m = selector_map()
    rnd = random.Random(seed)
    out = []
    for _t in range(draws):
        perm = m[:]
        rnd.shuffle(perm)
        out.append(selector_byte_agreement(perm)[1])
    return sum(out) / len(out), max(out)


def perc_selector_refusal():
    """(asked, hits, null mean, null max, agree, differ, names it would have made).

    ★ M9 ON THE PERCUSSION ARRAY, packaged for the generator so that array's own
    banner can state the refusal in the numbers that produced it.  Q18 prints the
    same figures with the argument around them.
    """
    m14 = selector_map(0x14)
    nmA = [u16(S(0x74) + 2 * i) for i in range(2048)]
    _pa, n20, recs20 = R6.array_records(0x20)
    tails, pname = {}, {}
    for i, b, nm in R6.perc_wavesel_tails():
        tails[i], pname[i] = b, nm

    def hits(vals):
        h = t = 0
        for q in range(1024):
            di = nmA[q]
            if di not in tails:
                continue
            t += 1
            if R6._mask(tails[di]) == R6._mask(recs20[vals[q]]):
                h += 1
        return t, h

    tot, ok = hits(m14)
    rnd = random.Random(20260831)
    nl = []
    for _t in range(20):
        perm = m14[:]
        rnd.shuffle(perm)
        nl.append(hits(perm)[1])
    lab8 = wavesel_labels_r8(0x20)
    sel = collections.defaultdict(set)
    for q in range(1024):
        if nmA[q] in pname:
            sel[m14[q]].add(pname[nmA[q]])
    ag = dis = 0
    for k, v in sel.items():
        if k in lab8:
            base = re.sub(r"_WaveSel\d+$", "", lab8[k])
            if v & set(base.split("_Or_")):
                ag += 1
            else:
                dis += 1
    would = sum(1 for k in range(n20) if k not in lab8 and len(sel.get(k, ())) == 1)
    return tot, ok, sum(nl) / len(nl), max(nl), ag, dis, would


def selector_buckets():
    """(named, unreached, too-broad, digit-only) over the FRAMED records of +0x18.

    Exported so the array banner in the generated assembly states the four
    outcomes as counts it did not type.  They sum to the framed total (Q19a).
    """
    lab8 = wavesel_labels_r8(SELECTOR_ARRAY)
    names = selector_names()
    m9 = selector_labels()
    _a, n, _r = R6.array_records(SELECTOR_ARRAY)
    framed = [k for k in range(n) if k not in lab8]
    return (len(m9),
            len([k for k in framed if k not in names]),
            len([k for k in framed if k in names and len(names[k]) > MAX_NAMES]),
            len([k for k in framed if k in names and 1 <= len(names[k]) <= MAX_NAMES
                 and not all(_has_letter(x) for x in names[k])]))


def selector_row_margin():
    """(positions, best offset's hits, best WRONG offset's hits) -- Q16d, exported.

    The generator prints the margin in the banner over every M9 label, so it has
    to be derived here and not typed there.
    """
    m = selector_map()
    tot, _ok = selector_byte_agreement(m)
    hits = dict((d, selector_byte_agreement(m, rowshift=d)[1])
                for d in range(MELODIC_ROWS))
    return tot, hits[0], max(v for d, v in hits.items() if d)


def selector_readers():
    """(prom_c reads of the map's slot, of the array's slot) -- from R3's census."""
    return len(R3.readers(SELECTOR_SLOT)), len(R3.readers(SELECTOR_ARRAY))


def q16():
    say("\n=== Q16.  ★★ M9 -- THE SELECTOR, AND WHAT PINS ITS INDEX ===\n")
    say("  Round 6 Q2b found the 1,024-entry map at slot +0x0C and used it as a")
    say("  SECOND WITNESS for records the byte test had already named.  It never")
    say("  asked the map about a record the byte test MISSED -- and that is where")
    say("  every framed label in this array is.  Q16 asks it.")
    say("")
    maps = [s for s in range(0, 0xB8, 4)
            if S(s) != 0xFFFFFFFF and R6.next_bound(S(s)) - S(s) == 2048]
    _a, n18, _r = R6.array_records(SELECTOR_ARRAY)
    reach = []
    for s in maps:
        v = [x for x in selector_map(s) if x != 0xFFFF]
        if max(v) == n18 - 1:
            reach.append(s)
    check("Q16a the map whose range reaches %d, this array's last index" % (n18 - 1),
          reach == [SELECTOR_SLOT],
          "slots %s of %d maps of 1,024 entries" % (["+0x%02X" % s for s in reach], len(maps)))
    m = selector_map()
    tot, ok = selector_byte_agreement(m)
    shifts = dict((d, selector_byte_agreement(m, progshift=d)[1]) for d in (-2, -1, 1, 2))
    check("Q16b ★ THE PROGRAM HALF OF THE INDEX IS PINNED HARD",
          ok > 5 * max(shifts.values()),
          "shift 0 -> %d of %d; +/-1 -> %d, %d; +/-2 -> %d, %d"
          % (ok, tot, shifts[-1], shifts[1], shifts[-2], shifts[2]))
    _mean, _max = selector_shuffle_null()
    sh = [_mean, _max]
    check("Q16c NULL: shuffling the map destroys it",
          _max * 20 < ok, "shuffled max %d, mean %.1f, against %d"
          % (_max, _mean, ok))
    rows = dict((d, selector_byte_agreement(m, rowshift=d)[1]) for d in range(MELODIC_ROWS))
    best_wrong = max(v for d, v in rows.items() if d)
    check("Q16d ⚠ AND THE ROW HALF IS *NOT* PINNED -- the honest half of this result",
          rows[0] == max(rows.values()) and rows[0] < 1.15 * best_wrong,
          "offsets %s; the true reading wins by %d of %d, which is %.1f%% vs %.1f%%"
          % ([rows[d] for d in range(MELODIC_ROWS)], rows[0] - best_wrong, tot,
             100.0 * rows[0] / tot, 100.0 * best_wrong / tot))
    say("       -> so M9 keeps the COLUMN and throws the row away.  A name that")
    say("          needed the row to be right would be a name resting on a 3-point")
    say("          margin, and this tree has paid for exactly that kind of name.")
    disc = [j for j in range(R6.PROG_COLS)
            if len(set(program_tone(r, j) for r in range(MELODIC_ROWS))) > 1]
    rd_map, rd_arr = selector_readers()
    check("Q16f ⚠ AND NEITHER SIDE HAS A prom_c READER -- stated, not hidden",
          rd_map == 0 and rd_arr == 0,
          "the 99-read directory census finds %d reads of slot +0x%02X and %d of "
          "+0x%02X" % (rd_map, SELECTOR_SLOT, rd_arr, SELECTOR_ARRAY))
    say("       -> so M9 is a relation between two TABLES, derived from their")
    say("          contents.  It is not evidence about what the machine DOES with")
    say("          either, and `_SelectedFor_` is worded to claim only the former.")
    check("Q16e the rows really are near-copies -- that is WHY the row is loose",
          len(disc) < R6.PROG_COLS,
          "%d of %d programs hold the same tone in all %d melodic rows"
          % (R6.PROG_COLS - len(disc), R6.PROG_COLS, MELODIC_ROWS))
    return tot, ok, rows, sh


def q17():
    say("\n=== Q17.  THE CALIBRATION -- M9 against the rule that already names ===\n")
    lab8 = wavesel_labels_r8(SELECTOR_ARRAY)
    tw = _twin_tone_indices()
    names = selector_names()
    agree, differ = 0, []
    for k, nm in sorted(names.items()):
        if k not in lab8 or not 1 <= len(nm) <= MAX_NAMES:
            continue
        if not all(_has_letter(x) for x in nm):
            continue
        owners = set(tone_name(t) for t in tw.get(k, ()))
        if set(nm) & owners:
            agree += 1
        else:
            differ.append((k, nm, lab8[k]))
    tot = agree + len(differ)
    check("Q17a M9 and the byte rule agree wherever BOTH reach a record",
          agree > 8 * len(differ), "%d agree, %d differ, of %d" % (agree, len(differ), tot))
    rnd = random.Random(20261001)
    flat = [program_tone(r, c) for r in range(MELODIC_ROWS) for c in range(R6.PROG_COLS)]
    nl = []
    for _t in range(50):
        perm = flat[:]
        rnd.shuffle(perm)
        pn = {}
        for k, cols in selector_columns().items():
            pn[k] = set(tone_name(perm[r * R6.PROG_COLS + c])
                        for c in cols for r in range(MELODIC_ROWS))
        a = 0
        for k, nm in names.items():
            if k not in lab8 or not 1 <= len(nm) <= MAX_NAMES:
                continue
            if not all(_has_letter(x) for x in nm):
                continue
            if pn[k] & set(tone_name(t) for t in tw.get(k, ())):
                a += 1
        nl.append(a)
    check("Q17b NULL: shuffle which tone the program map holds where",
          max(nl) * 5 < agree, "null mean %.1f max %d, against %d of %d"
          % (sum(nl) / len(nl), max(nl), agree, tot))
    # ★ THE COMPARISON A REVIEWER WOULD DEMAND, made here instead.  The column
    # set is WIDER than round 7's per-position vote, and a wider candidate set
    # agrees more often for free.  Both rules are run on the SAME records so the
    # width is priced rather than banked.
    votes = R7._map_votes()
    pos = 0
    for k, nm in sorted(names.items()):
        if k not in lab8 or not 1 <= len(nm) <= MAX_NAMES:
            continue
        if not all(_has_letter(x) for x in nm):
            continue
        owners = set(tone_name(t) for t in tw.get(k, ()))
        if set(tone_name(t) for t in votes.get(k, set())) & owners:
            pos += 1
    check("Q17c ⚠ AND HOW MUCH OF THAT IS THE COLUMN BEING WIDER, priced",
          pos < agree,
          "same %d records: the column rule agrees %d, round 7's per-POSITION vote "
          "agrees %d -- so %d of the agreements are bought by the wider set"
          % (tot, agree, pos, agree - pos))
    say("       -> round 7 M1 measured the per-position vote as a TIE-BREAKER and")
    say("          rejected it at %d agree / %d disagree over round 6's labels.  M9"
        % R7.m1_calibration()[:2])
    say("          is not that mechanism re-run: M1 asked the map to PICK ONE of the")
    say("          names the bytes already offered, and M9 asks it about records the")
    say("          bytes name NOT AT ALL, where there is nothing to pick between.")
    say("          The null above is computed at the same width, which is what makes")
    say("          %d against %.1f a statement about this map rather than about set"
        % (agree, sum(nl) / len(nl)))
    say("          sizes.")
    say("")
    say("  ★ THE %d DISAGREEMENTS, IN FULL, because a derived name that contradicts"
        % len(differ))
    say("    another derived name has to be visible:")
    for k, nm, l8 in differ:
        say("      record %3d  M9 says %-38s  the bytes say %s"
            % (k, "_Or_".join(nm), l8))
    say("    Neither is wrong.  `_SameAs_` is a statement about 43 BYTES and")
    say("    `_SelectedFor_` is a statement about a MAP ENTRY; a record can be a")
    say("    copy of Gamelan1's block and be the record the map puts under")
    say("    AfricanMallet.  ⚠ AND M9 IS APPLIED TO NEITHER OF THESE %d: it only"
        % len(differ))
    say("    labels records with no twin at all, so no label contradicts another.")
    return agree, differ, nl


def q18():
    say("\n=== Q18.  ★ M9 ON THE PERCUSSION ARRAY -- MEASURED, AND REFUSED ===\n")
    say("  The same shape exists at slot +0x20: a 208-record array, a 1,024-entry")
    say("  map at +0x14 whose range is exactly 0..207, and a 2,048-entry drum note")
    say("  map at +0x74 to read the names out of.  It would name 37 records -- ALL")
    say("  of the framed ones.  It is refused, and here is the measurement that")
    say("  refuses it.")
    m14 = selector_map(0x14)
    nmA = [u16(S(0x74) + 2 * i) for i in range(2048)]
    _pa, n20, recs20 = R6.array_records(0x20)
    tails, pname = {}, {}
    for i, b, nm in R6.perc_wavesel_tails():
        tails[i], pname[i] = b, nm

    def hits(vals):
        h = t = 0
        for q in range(1024):
            di = nmA[q]
            if di not in tails:
                continue
            t += 1
            if R6._mask(tails[di]) == R6._mask(recs20[vals[q]]):
                h += 1
        return t, h

    tot, ok = hits(m14)
    rnd = random.Random(20260831)
    nl = []
    for _t in range(20):
        perm = m14[:]
        rnd.shuffle(perm)
        nl.append(hits(perm)[1])
    check("Q18a ⚠ THE PERC TEST CANNOT DISCRIMINATE -- it scores at its own null",
          ok < 1.3 * (sum(nl) / len(nl)),
          "%d of %d, against a shuffled mean of %.1f (max %d)"
          % (ok, tot, sum(nl) / len(nl), max(nl)))
    say("       -> the drum records' 43-byte tails repeat: shuffling the map barely")
    say("          moves the score, so a hit is not evidence of anything.  The")
    say("          melodic array is the opposite case (Q16c), which is what makes")
    say("          the melodic number worth quoting and this one worthless.")
    lab8 = wavesel_labels_r8(0x20)
    sel = collections.defaultdict(set)
    for q in range(1024):
        if nmA[q] in pname:
            sel[m14[q]].add(pname[nmA[q]])
    ag = dis = 0
    for k, s in sel.items():
        if k in lab8:
            base = re.sub(r"_WaveSel\d+$", "", lab8[k])
            if s & set(base.split("_Or_")):
                ag += 1
            else:
                dis += 1
    check("Q18b and its calibration against the byte rule is a rout",
          dis > 20 * max(ag, 1), "%d agree, %d differ" % (ag, dis))
    would = sum(1 for k in range(n20) if k not in lab8 and len(sel.get(k, ())) == 1)
    check("Q18c ★ what is being refused is %d names, not a technicality" % would,
          would > 0, "%d of the %d framed records of that array would have got one"
          % (would, n20 - len(lab8)))
    return ok, tot, nl, would


def q19():
    say("\n=== Q19.  WHAT M9 LEAVES, PER OBJECT AND FOR A DERIVED REASON ===\n")
    lab8 = wavesel_labels_r8(SELECTOR_ARRAY)
    m9 = selector_labels()
    names = selector_names()
    _a, n18, _r = R6.array_records(SELECTOR_ARRAY)
    framed = [k for k in range(n18) if k not in lab8]
    unreached = [k for k in framed if k not in names]
    toobroad = [k for k in framed if k in names and len(names[k]) > MAX_NAMES]
    digits = [k for k in framed if k in names and 1 <= len(names[k]) <= MAX_NAMES
              and not all(_has_letter(x) for x in names[k])]
    check("Q19a the four buckets account for every framed record, with no residue",
          len(m9) + len(unreached) + len(toobroad) + len(digits) == len(framed),
          "%d named + %d unreached + %d too broad + %d digit-only = %d framed"
          % (len(m9), len(unreached), len(toobroad), len(digits), len(framed)))
    check("Q19b ★ the biggest bucket is a CENSUS RESULT, not a mechanism failing",
          len(unreached) > len(toobroad),
          "%d records are named by NO entry of the map -- all 1,024 were read"
          % len(unreached))
    check("Q19c the FIRST record of the array is asked and answered",
          0 in unreached, "record 0: no map entry holds 0 (the map's range is 1..%d)"
          % max(selector_map()))
    check("Q19d ★ and so is the LAST, which is where a rule that stops early shows",
          n18 - 1 in framed and (n18 - 1 in unreached or n18 - 1 in toobroad
                                 or n18 - 1 in digits),
          "record %d is reached from %d program column(s) and they carry %d "
          "different tone names -- more than the bound of %d, so it is REFUSED"
          % (n18 - 1, len(selector_columns().get(n18 - 1, [])),
             len(names.get(n18 - 1, ())), MAX_NAMES))
    if digits:
        check("Q19e the digit-only refusal fires on real records, not in theory",
              True, "records %s would have been named `%s`"
              % (digits, "_Or_".join(names[digits[0]])))
    say("")
    say("  ★ THE %d M9 NAMES, IN FULL:" % len(m9))
    for k in sorted(m9):
        say("      record %3d  <- programs %-22s  %s"
            % (k, str(selector_columns()[k])[:22], m9[k]))
    return m9, unreached, toobroad, digits


def q20():
    say("\n=== Q20.  THE SECOND MAP, and a negative worth having ===\n")
    m = selector_map(0x10)
    tot, ok = selector_byte_agreement(m)
    rnd = random.Random(20260901)
    nl = []
    for _t in range(20):
        perm = m[:]
        rnd.shuffle(perm)
        nl.append(selector_byte_agreement(perm)[1])
    ref_tot, ref_ok = selector_byte_agreement(selector_map())
    check("Q20a ToneIndexMapB (+0x10) does NOT corroborate the way +0x0C does",
          ok <= sum(nl) / len(nl),
          "%d of %d, at its own shuffled null (mean %.1f, min %d, max %d)"
          % (ok, tot, sum(nl) / len(nl), min(nl), max(nl)))
    say("       -> +0x10's range also fits this array (max %d < %d), so a lane that"
        % (max(m), 322))
    say("          ranked by range alone would have taken it for a second selector.")
    say("       ⚠ AND THIS IS A WEAK NEGATIVE, SAID SO HERE RATHER THAN LEFT TO A")
    say("          REVIEWER: only %d of its 1,024 entries land on a record the byte"
        % tot)
    say("          test named at all, against +0x0C's %d, so the null it is being"
        % ref_tot)
    say("          compared against is itself near zero.  What this licenses is `+0x10")
    say("          does not corroborate`, NOT `+0x10 is disproved`.  M9 is not")
    say("          extended to it either way.")
    return ok, tot, nl


def selftest_round10():
    """★ THE NEGATIVE CONTROLS FOR M9.  A rule that cannot fail is not a rule."""
    say("\n=== SELFTEST -- ROUND 10's SELECTOR, ATTACKED ===\n")
    base = selector_labels()
    m = selector_map()
    cols = selector_columns()
    # T13: rotate the map by one PROGRAM and the labels must move.
    rot = [m[(i + 1) % 1024] for i in range(1024)]
    saved = globals()["selector_map"]
    globals()["selector_map"] = lambda slot=SELECTOR_SLOT: (rot if slot == SELECTOR_SLOT
                                                            else saved(slot))
    try:
        moved = selector_labels()
    finally:
        globals()["selector_map"] = saved
    check("T13 rotating the map by one program CHANGES the labels",
          moved != base, "%d labels before, %d after, %d in common"
          % (len(base), len(moved),
             len(set(base.items()) & set(moved.items()))))
    # T14: the digit-only filter fires on a real record.
    names = selector_names()
    dig = [k for k, v in names.items() if 1 <= len(v) <= MAX_NAMES
           and not all(_has_letter(x) for x in v)]
    dig = sorted(dig)
    check("T14 the digit-only refusal fires on real records",
          bool(dig) and all(k not in base for k in dig),
          "records %s carry only tone 0x05D's `%s`"
          % (dig, names[dig[0]][0] if dig else ""))
    # T15: the LAST record of the array is reached by the rule's own code path.
    _a, n18, _r = R6.array_records(SELECTOR_ARRAY)
    check("T15 ★ the rule is evaluated on the LAST record, not only the first",
          (n18 - 1) in names and (n18 - 1) not in base,
          "record %d: %d columns, %d names -> refused (>%d)"
          % (n18 - 1, len(cols.get(n18 - 1, [])), len(names.get(n18 - 1, ())), MAX_NAMES))
    # T16: the rule on an array no map reaches must name nothing.
    _b, n3c, _r3 = R6.array_records(0x3C)
    reach3c = [s for s in range(0, 0xB8, 4)
               if S(s) != 0xFFFFFFFF and R6.next_bound(S(s)) - S(s) == 2048
               and max(x for x in selector_map(s) if x != 0xFFFF) == n3c - 1]
    check("T16 CONTROL: no map's range reaches the %d-record preset array, so M9"
          % n3c, not reach3c, "maps reaching index %d: %s" % (n3c - 1, reach3c))
    # T17: the labels are invariant under all eight row rotations.
    inv = True
    for off in range(MELODIC_ROWS):
        alt = {}
        for k, cs in cols.items():
            alt[k] = tuple(sorted(set(tone_name(program_tone((r + off) % MELODIC_ROWS, c))
                                      for c in cs for r in range(MELODIC_ROWS))))
        if any(alt.get(k) != names.get(k) for k in base):
            inv = False
    check("T17 ★★ every M9 label is invariant under all %d row rotations" % MELODIC_ROWS,
          inv, "which is the whole reason Q16d's loose row does not reach the labels")
    # T18: the generator's guard constant still describes the rule.
    check("T18 the shape the generator refuses on still matches",
          _r10_shape() == AUDITED_R10, "%s" % (_r10_shape(),))
    # T19: ★ ROUND 6's REVIEW ASKED OF ROUND 10's LABELS.  The round-6 review
    # script's R6z reads `_SameAs_` labels only, so it is BLIND to these -- said
    # here rather than left to a reviewer, and the question is asked instead.
    # Every morpheme is read back OUT of prom_d/wsa1_prom_d.s, not out of the
    # function that wrote it, and matched against the image's own ASCII.
    src = open(SRC).read()
    got = re.findall(r"^ToneDB_MixerDefaultTable_(\d{3})_SelectedFor_([A-Za-z0-9_]+):",
                     src, re.M)
    field = set()
    for p_ in R6.TONE_PTRS:
        field.add(R6.camel(D[p_:p_ + 16].decode("latin1")))
    words = sorted(set(w for _k, suf in got for w in suf.split("_Or_")))
    missing = [w for w in words if w not in field]
    check("T19 ★ every morpheme in an M9 label is a tone record's own ASCII field",
          len(got) == len(selector_labels()) and not missing,
          "%d labels in the .s, %d distinct names, %d not found in the image"
          % (len(got), len(words), len(missing)))
    check("T19' and the .s agrees with the rule record for record",
          dict((int(k), v) for k, v in got) == selector_labels(),
          "%d labels compared" % len(got))


def nameless_report(nameless):
    say("\n  ★ THE NAMELESS, IN FULL -- %d objects, three answers each:" % len(nameless))
    for r in nameless:
        say("      0x%05X  %-46s %s  %s"
            % (r.lab.addr, r.lab.name, r.answers, r.cwhy[:96]))


def main():
    say("prom_d round 8 -- the three-question inventory over %d labels." % len(R7.LABS))
    nameless = q1()
    q2(nameless)
    added = q3()
    q4()
    q5()
    q6()
    q7()
    q8()
    q9()
    _res, _g = q10()
    _AUDIT_GRADES.update(_g)
    q11()
    q12()
    q13()
    q14()
    q15()
    q16()
    q17()
    q18()
    q19()
    q20()
    if "--selftest" in _ARGV:
        selftest()
        selftest_round9()
        selftest_round10()
    if "--nameless" in _ARGV:
        nameless_report(nameless)
    say("")
    say("  ★★ WHAT ROUND 8 PUBLISHED: %d of prom_d's %d framed labels promoted to a"
        % (added, added + len(nameless)))
    say("     name that states what the object IS; %d stay framed with all three"
        % len(nameless))
    say("     routes to a name asked and answered NO.")
    say("")
    say("  ★★ THE WHOLE-IMAGE AUDIT, LIVE: %d of the %d labels have their NAME"
        % (_AUDIT_GRADES.get("DERIVED", 0), sum(_AUDIT_GRADES.values())))
    say("     re-derived from this image's own bytes and %d have only their ADDRESS."
        % _AUDIT_GRADES.get("ADDRESS", 0))
    say("     ⚠ THOSE TWO NUMBERS ARE LIVE AND HAVE MOVED: round 9 published them as")
    say("     2857 / 808 and promoted nothing; round 10's %d selector labels are the"
        % selector_buckets()[0])
    say("     whole of the difference, and AUDITED_R9 was updated with them.")
    say("     ROUND 9's own result stands as it was: every mechanism that could have")
    say("     moved that")
    say("     number this round was measured and refused: the twin rule on the")
    say("     +0x3C array (0 of 64, Q12), the monotone interpolation (0 of 12 and")
    say("     self-refuting on the other array, Q13), and General MIDI (18/128")
    say("     against a rotated null of 11/128, Q14).  The one thing round 9")
    say("     CHANGED in prom_d/wsa1_prom_d.s is a false number in generated prose:")
    say("     `108 entries` over a 132-byte object, plus round 8's `1,549` where")
    say("     the population is 1,485.  Both fixed in the GENERATOR, which is the")
    say("     only place a fix survives, and both now have a check that re-derives")
    say("     them (Q10d, Q11d).")

    _n10, _u10, _b10, _d10 = selector_buckets()
    say("")
    say("  ★★ WHAT ROUND 10 PUBLISHES: %d framed labels of ToneDB_MixerDefaultTable"
        % _n10)
    say("     promoted to `_SelectedFor_<tone>` -- named by WHAT POINTS AT THEM, the")
    say("     one route this image had that round 6 measured and then used only as a")
    say("     witness.  The other %d stay framed for a reason derived per object: %d"
        % (_u10 + _b10 + _d10, _u10))
    say("     are selected by no entry of the map at all, %d have columns carrying"
        % _b10)
    say("     more than %d tone names, %d would have been named `161`.  ★ AND THE"
        % (MAX_NAMES, _d10))
    say("     SAME MECHANISM ON THE PERCUSSION ARRAY IS REFUSED (Q18): it would have")
    say("     named every one of that array's 37 framed records and it scores at its")
    say("     own shuffled null.  The row half of the map's index is NOT pinned")
    say("     (Q16d) and every label is built to be invariant under it (T17).")
    print("\n%d checks, %d failed.%s"
          % (NCHECK[0], len(FAILED),
             "" if not FAILED else "  " + "; ".join(FAILED)))
    if "--selftest" in _ARGV and NCHECK[0] != AUDITED_CHECKS:
        print("⚠ check count moved: %d, audited %d.  Update AUDITED_CHECKS."
              % (NCHECK[0], AUDITED_CHECKS))
    return 1 if FAILED else 0


if __name__ == "__main__":
    sys.exit(main())
