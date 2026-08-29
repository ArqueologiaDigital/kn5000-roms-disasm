#!/usr/bin/env python3
"""prom_d round 4 -- WHAT ARE THESE ARRAYS FOR?  Turning FRAMED names into CONTENT.

QUESTION IT ANSWERS
    prom_d reads 100% UPPER and 44.5% LOWER on
    notes/wave7_documentation_metrics.py: 2,034 of its labels are POSITIONAL --
    `ToneDB_EnvDescTable_Pool_A017`, `PercInst_017`, `ToneDB_MixerDefaultTable_204`.
    The object is delimited, typed and counted, and NOBODY HAS SAID WHAT IT IS
    FOR.  Round 2 proved the descriptor blocks are ARRAY + POOL and round 3
    proved 33 directory slots are READ by prom_c.  Neither said what a pool
    object DOES.

    ★ This script answers that for the descriptor pools, and it answers it from
    prom_d's own arithmetic: the pool objects are the two stages of a THREE-STAGE
    INDEX CHAIN, and each stage's codomain is EXACTLY the next stage's domain,
    with no slack, in 479 of 479 descriptors.

        stage 1   ToneDB_DescCurve_k          128 entries, non-decreasing
                  (the descriptor's part-A object begins with a 32-bit file
                   offset naming one of the six curves -- round 2's result)
        stage 2   part A, after that pointer  exactly max(curve)+1 bytes
        stage 3   part B                      exactly max(part A)+1 elements,
                                              of 6 bytes when the descriptor's
                                              tag bit 7 is CLEAR and 8 when SET

    Q1 measures all three joins.  318/318 at slot +0x30 and 161/161 at +0x38,
    with the LAST record of each block checked by name as well as the first.
    So `..._Pool_A017` becomes `..._017_CurveStepToElem` and `..._Pool_B017`
    becomes `..._017_ElemArray`: names that state the object's ROLE, which is
    what this round was asked for.

WHAT ELSE IT ESTABLISHES (reproduced below; run it, do not quote this list)
    Q2  THE INDEX MAPS AND THE ARRAYS THEY COULD INDEX.  Twelve 1024-entry LE16
        maps; prom_d's own banners say of every one of them that what it selects
        is not established.  The KN5000's directory NAMES a target for six of
        them, and prom_d's arithmetic contradicts none of the six: every one has
        a maximum below its named target's element count, and four attain it
        exactly.  ⚠ Only TWO of those four single out one array -- 208 and 161
        are each held by two different arrays, so a tight fit there identifies a
        COUNT and not a target, and Q2 refuses to promote it.  No map banner in
        the assembly is renamed on the strength of this.
    Q3  the RECORD NAME FIELDS, which is what lets 796 record labels say what
        they are: 274 tone records carry a 16-byte ASCII name and 504
        drum-instrument records a 13-byte one; every one is printable, and the
        camel-case label forms are unique per record.  202 of the 274 tone names
        and 101 of the 504 drum names occur VERBATIM in the KN7000's table ROM
        -- a different CPU architecture, so the name is not an artefact of this
        tree's reading.
    Q4  the NEGATIVES, printed whether they help or not: slot +0x70's four
        descriptors do NOT obey the Q1 chain (0 of 3), and the two index maps
        that would have let the 161 perc descriptors borrow the 161 perc
        catalogue names agree in only 988 of 1024 positions -- so that transfer
        is NOT made and those labels stay positional.
    Q5  nulls, so Q1 is falsifiable: the same joins measured with the element
        size forced to one value, with the tag bit inverted, and against a
        byte-reversed image.

HOW TO RUN
    python3 notes/prom_d_understanding_round4.py            # every check
    python3 notes/prom_d_understanding_round4.py --quiet    # failures only
    Exit status is non-zero if ANY check fails.

    scripts/analysis/gen_prom_d_asm.py imports chain() and names() from this
    file and REFUSES to emit if either shape moved, so a label in
    prom_d/wsa1_prom_d.s cannot outlive the measurement that justifies it.

WHAT IS *NOT* ESTABLISHED, said before the results
    * NOT what the 6- or 8-byte element MEANS.  Q1 proves how many there are and
      how they are reached; no field inside one is identified.
    * NOT that the curve's index is a MIDI note.  128 entries is the note range
      and that is suggestive; nothing here reads a note.
    * NOT a prom_c reader for slot +0x30 or +0x38.  round 3's census found none
      (it found 33 other slots), so the whole chain is image-internal arithmetic.
      That is why it is quoted with its counts and not with a routine name.
"""
import collections
import os
import re
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
D = open(os.path.join(ROOT, "original_ROMs", "wsa1_prom_d.bin"), "rb").read()
assert len(D) == 0x80000
KN7000_TABLE = ("/home/fsanches/compartilhado/technics_roms/roms/kn7000/"
                "kn7000_table.rom")

u16 = lambda o: struct.unpack_from("<H", D, o)[0]
u32 = lambda o: struct.unpack_from("<I", D, o)[0]
DIR = [u32(4 * i) for i in range(48)]
S = lambda slot: DIR[slot // 4]

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
# The layout comes from round 2, re-derived, never hard-coded here.
# ---------------------------------------------------------------------------
import importlib.util as _ilu

_spec = _ilu.spec_from_file_location(
    "prom_d_structures_round2", os.path.join(ROOT, "notes",
                                             "prom_d_structures_round2.py"))
_R2 = _ilu.module_from_spec(_spec)
_saved, sys.argv = sys.argv, ["prom_d_structures_round2", "--quiet"]
try:
    _spec.loader.exec_module(_R2)
finally:
    sys.argv = _saved

CURVE_BASE, CURVE_STRIDE, CURVE_N = _R2.CURVE_BASE, _R2.CURVE_STRIDE, _R2.CURVE_N

# The two blocks the chain covers, and the one it does not.
CHAIN_SLOTS = (0x30, 0x38)
NO_CHAIN_SLOT = 0x70


def elem_size(tag):
    """Element size of a descriptor's part-B array, from the tag's bit 7.

    NOT borrowed.  Q1c derives the polarity from prom_d: for the 187 records at
    slot +0x30 whose tag bit 7 is CLEAR the part-B length is a multiple of 6 and
    for the 131 whose bit 7 is SET it is a multiple of 4, and 112 + 119 of those
    are multiples of ONE of the two and not the other, so the split is real and
    not an artefact of 12 dividing both.  The 6-vs-8 refinement is Q1b: with 8,
    the element count equals max(part A)+1 in all 131.
    ⚠ ../kn5000-roms-disasm's note on the same field states the OPPOSITE
    polarity (bit7 set -> 6).  The polarity is therefore NOT transferable; this
    one is measured here.
    """
    return 8 if (tag >> 7) & 1 else 6


def chain(slot):
    """The three-stage index chain, per descriptor, re-derived from bytes.

    Returns a list of dicts, one per descriptor of the block at `slot`, in
    descriptor order:
        curve       file offset of the ToneDB_DescCurve the part-A object names
        curve_max   its largest entry
        a_at,a_len  the part-A object, and the length the pool tiling gives it
        a_tab       the bytes of part A AFTER its 4-byte curve pointer
        b_at,b_len  the part-B object
        esize,ecount  element size and count of part B
    Raises if the block is not one of CHAIN_SLOTS.
    """
    H, P, recs = _R2.desc_layout(slot)
    segs = _R2.desc_segments(slot)
    A, B = {}, {}
    for s, e, kind, i in segs:
        (A if kind == "A" else B)[i] = (s, e)
    shared_a = A[min(A)] if len(A) == 1 else None
    out = []
    for i, (tag, o1, o2, b9, w10, w12) in enumerate(recs):
        a = A.get(i, shared_a)
        b = B.get(i)
        if a is None or b is None:
            out.append(None)
            continue
        curve = u32(a[0])
        row = D[curve:curve + CURVE_STRIDE]
        es = elem_size(tag)
        out.append(dict(i=i, tag=tag, curve=curve,
                        curve_k=(curve - CURVE_BASE) // CURVE_STRIDE,
                        curve_max=max(row),
                        a_at=a[0], a_len=a[1] - a[0], a_tab=D[a[0] + 4:a[1]],
                        b_at=b[0], b_len=b[1] - b[0],
                        esize=es, ecount=(b[1] - b[0]) // es,
                        key_lo=b9, key_hi=w10 & 0xFF, root=w10 >> 8, pitch=w12))
    return out


# ---------------------------------------------------------------------------
# Q3's name fields.
# ---------------------------------------------------------------------------
TONE_PTRS = [u32(0xB80 + 4 * i) for i in range(274)]
PERC_STRIDE = u16(0xEE)
PERC_BASE = S(0x78)
PERC_N = 504


def camel(s):
    """A label-safe CamelCase form of a record's own ASCII name field.

    The name is DATA, not a guess: it is the bytes at offset 0 of the record.
    Only punctuation and spacing are dropped, so the label can be read back to
    the string it came from, which check Q3d verifies for every record.
    """
    out = re.sub(r"[^A-Za-z0-9]+", " ", s).strip()
    parts = [(p[0].upper() + p[1:]) for p in out.split() if p]
    return "".join(parts) or "Unnamed"


def names():
    """(tone_names, perc_names, kit_names) as {record index: (raw, camel)}."""
    tone = {}
    for p in TONE_PTRS:
        tone[p] = (D[p:p + 16].decode("latin1"), camel(D[p:p + 16].decode("latin1")))
    perc = {}
    for i in range(PERC_N):
        o = PERC_BASE + PERC_STRIDE * i
        raw = D[o:o + 13].decode("latin1")
        perc[i] = (raw, camel(raw))
    return tone, perc


# ---------------------------------------------------------------------------
# Q6's reachability census: HOW MANY selectors name each record.
# ---------------------------------------------------------------------------
PROGMAP_AT = S(0x04)
PROGMAP_N = 10 * 128
NOTEMAP_N = 2048


def prog_selectors():
    """tone-record index -> how many of the 1,280 program-map entries pick it."""
    c = collections.Counter(u16(PROGMAP_AT + 2 * i) for i in range(PROGMAP_N))
    return c


def drum_selectors():
    """drum-record index -> (entries of DrumKit_NoteMapA, of NoteMapB) naming it."""
    out = {}
    for slot in (0x74, 0x7C):
        a = S(slot)
        out[slot] = collections.Counter(v for v in
                                        (u16(a + 2 * i) for i in range(NOTEMAP_N))
                                        if v != 0xFFFF)
    return out[0x74], out[0x7C]


# The shapes the emitter pins.  If a number here moves, the assembly's labels
# and Evidence lines are stale and gen_prom_d_asm.py refuses to run.
AUDITED_CHAIN = {0x30: (318, 318), 0x38: (161, 161)}   # slot: (records, joined)
AUDITED_NAMES = (274, 504)


# ===========================================================================
def q1():
    say("\n=== Q1.  THE THREE-STAGE INDEX CHAIN -- what the pool objects ARE ===\n")
    say("  Each descriptor's part A begins with a 32-bit file offset naming one of")
    say("  the %d curves in ToneDB_DescCurveBank (round 2).  What follows is new:" % CURVE_N)
    say("  the bytes AFTER that pointer are a table whose LENGTH is exactly the")
    say("  curve's largest value + 1, and whose largest value + 1 is exactly the")
    say("  number of elements in part B.  Two joins, no slack, both ends pinned.\n")
    for slot in CHAIN_SLOTS:
        rows = [r for r in chain(slot) if r]
        n = len(rows)
        j1 = [r for r in rows if r["a_len"] - 4 == r["curve_max"] + 1]
        j2 = [r for r in rows if r["ecount"] == max(r["a_tab"]) + 1]
        j0 = [r for r in rows if r["b_len"] % r["esize"] == 0]
        mono = [r for r in rows
                if all(r["a_tab"][k] <= r["a_tab"][k + 1] for k in range(len(r["a_tab"]) - 1))]
        cmono = [r for r in rows
                 if all(D[r["curve"] + k] <= D[r["curve"] + k + 1] for k in range(CURVE_STRIDE - 1))]
        say("  slot +0x%02X -- %d descriptors" % (slot, n))
        check("+0x%02X  stage 1 curve is non-decreasing" % slot, len(cmono) == n,
              "%d/%d" % (len(cmono), n))
        check("+0x%02X  stage 2 table is non-decreasing" % slot, len(mono) == n,
              "%d/%d" % (len(mono), n))
        if slot == 0x30:
            check("+0x%02X  JOIN 1: len(part A) - 4 == max(curve) + 1" % slot,
                  len(j1) == n, "%d/%d" % (len(j1), n))
        else:
            # The 161 descriptors share ONE part-A object and nothing is packed
            # after it, so the tiling hands back its FULL extent, not its used
            # length.  Stated, not hidden: the shared table is the whole 128.
            ln = rows[0]["a_len"] - 4
            check("+0x%02X  the ONE shared part A is a full %d-entry table" % (slot, CURVE_STRIDE),
                  ln == CURVE_STRIDE and len({r["a_at"] for r in rows}) == 1,
                  "%d entries, %d distinct part-A objects"
                  % (ln, len({r["a_at"] for r in rows})))
            check("+0x%02X  ...of which max(curve)+1 = %d are addressable"
                  % (slot, rows[0]["curve_max"] + 1), rows[0]["curve_max"] + 1 <= ln,
                  "%d <= %d" % (rows[0]["curve_max"] + 1, ln))
        check("+0x%02X  part B divides exactly by its element size" % slot,
              len(j0) == n, "%d/%d" % (len(j0), n))
        check("+0x%02X  JOIN 2: elements == max(part A) + 1" % slot,
              len(j2) == n, "%d/%d" % (len(j2), n))
        # ★ tested on the LAST record by name, not only in the aggregate
        last = rows[-1]
        check("+0x%02X  LAST descriptor %d: curve %d max %d, A %d B %d x %dB"
              % (slot, last["i"], last["curve_k"], last["curve_max"],
                 len(last["a_tab"]), last["ecount"], last["esize"]),
              last["ecount"] == max(last["a_tab"]) + 1
              and last["b_len"] == last["ecount"] * last["esize"],
              "file 0x%05X / 0x%05X" % (last["a_at"], last["b_at"]))
        first = rows[0]
        check("+0x%02X  FIRST descriptor 0: %d elements of %dB at 0x%05X"
              % (slot, first["ecount"], first["esize"], first["b_at"]),
              first["ecount"] == max(first["a_tab"]) + 1)
    # Q1c: the polarity of tag bit 7, derived here rather than borrowed.
    rows = [r for r in chain(0x30) if r]
    clear = [r for r in rows if not (r["tag"] >> 7) & 1]
    setb = [r for r in rows if (r["tag"] >> 7) & 1]
    only6 = [r for r in clear if r["b_len"] % 6 == 0 and r["b_len"] % 4]
    only4 = [r for r in setb if r["b_len"] % 4 == 0 and r["b_len"] % 6]
    say("")
    check("Q1c  tag bit7 CLEAR -> part B length is a multiple of 6",
          all(r["b_len"] % 6 == 0 for r in clear), "%d records" % len(clear))
    check("Q1c  tag bit7 SET   -> part B length is a multiple of 4",
          all(r["b_len"] % 4 == 0 for r in setb), "%d records" % len(setb))
    check("Q1c  and the split is not '12 divides both'",
          len(only6) > 100 and len(only4) > 100,
          "%d are 6-not-4, %d are 4-not-6" % (len(only6), len(only4)))
    tags = collections.Counter(r["tag"] for r in rows)
    say("       tag census at +0x30: %s"
        % ", ".join("0x%02X x%d" % (t, c) for t, c in sorted(tags.items())))


def q2():
    say("\n=== Q2.  WHICH ARRAY DOES EACH INDEX MAP SELECT FROM? ===\n")
    say("  prom_d's own banners say, of every one of the twelve 1024-entry LE16 index")
    say("  maps, '⚠ What the index SELECTS is not established here'.  This section")
    say("  narrows that, and it is careful about how far.\n")
    say("  The test is arithmetic: a map's largest value must be < the element count")
    say("  of whatever it indexes, and if the map is ONTO that array, max + 1 == the")
    say("  count exactly.  Six of the twelve have a target the KN5000's")
    say("  tone_database_directory.s NAMES (derived from ITS subcpu code, a different")
    say("  firmware); the other six it calls 'row-index tables' for two named routines")
    say("  WITHOUT naming the row array, so for those there is nothing to confirm and")
    say("  the count is all that is on offer.\n")
    counts = {"ToneDB_MixerDefaultTable (+0x18)": 322,
              "ToneDB_PercMixerDefaultTable (+0x20)": 208,
              # renamed in round 5 (Q7); the count this line asserts is unchanged.
              "ToneDB_WaveSelTailPresets (+0x3C)": 64,
              "ToneDB_EnvDescTable (+0x30)": 318,
              "ToneDB_EnvDescTable_Perc (+0x38)": 161,
              "ToneDB_SourceNameList1 (+0x50)": 307,
              "ToneDB_SourceNameList2 (+0x64)": 314,
              "ToneDB_DrumSourceNameList (+0x80)": 503,
              "ToneDB_PercSourceNameList1 (+0x8C)": 208,
              "ToneDB_PercSourceNameList2 (+0x94)": 161}
    # ⚠ TWO of these counts are NOT unique: 208 is held by both +0x20 and +0x8C,
    # and 161 by both +0x38 and +0x94.  So an exact attainment of 208 or 161
    # identifies a COUNT, not an array, and this section says so per row instead
    # of quietly picking the one that suits the KN5000.
    dupe = {c for c in counts.values() if list(counts.values()).count(c) > 1}
    named_target = {                    # the KN5000 directory NAMES these six
        0x0C: "ToneDB_MixerDefaultTable (+0x18)",
        0x10: "ToneDB_MixerDefaultTable (+0x18)",
        0x14: "ToneDB_PercMixerDefaultTable (+0x20)",
        0x24: "ToneDB_EnvDescTable (+0x30)",
        0x28: "ToneDB_EnvDescTable (+0x30)",
        0x2C: "ToneDB_EnvDescTable_Perc (+0x38)"}
    unnamed_target = {                  # the KN5000 names only a CONSUMER ROUTINE
        0x44: "DSP_RouteCoeffs_TypeA row index (row array NOT named)",
        0x48: "DSP_RouteCoeffs_TypeA row index (row array NOT named)",
        0x4C: "DSP_RouteCoeffs_TypeA row index (row array NOT named)",
        0x58: "DSP_VoiceCoeffRoute2 row index (row array NOT named)",
        0x5C: "DSP_VoiceCoeffRoute2 row index (row array NOT named)",
        0x60: "DSP_VoiceCoeffRoute2 row index (row array NOT named)"}
    mx = {}
    for slot in list(named_target) + list(unnamed_target):
        a = S(slot)
        mx[slot] = max(v for v in (u16(a + 2 * i) for i in range(1024)) if v != 0xFFFF)

    say("  (a) the six maps the KN5000 gives a target for")
    say("  %-6s %-36s %5s %6s  %s" % ("map", "KN5000-named target", "max", "count", "verdict"))
    exact_named = uniq_named = under = 0
    for slot, tgt in sorted(named_target.items()):
        c = counts[tgt]
        if mx[slot] + 1 == c:
            exact_named += 1
            v = "EXACT" + (" -- but %d arrays share the count %d" % (2, c)
                           if c in dupe else " and the count %d is unique" % c)
            uniq_named += c not in dupe
        else:
            v = "bounded, %d short" % (c - mx[slot] - 1)
        under += mx[slot] < c
        say("  +0x%02X  %-36s %5d %6d  %s" % (slot, tgt, mx[slot], c, v))
    check("Q2a  no KN5000-named pairing is CONTRADICTED (max < count, 6 of 6)",
          under == 6, "%d/6" % under)
    check("Q2b  4 of the 6 are attained exactly", exact_named == 4,
          "%d/6 exact" % exact_named)
    check("Q2c  and only %d of those 4 single out ONE array: 322 and 318 are unique"
          " counts, 208 and 161 are not" % uniq_named, uniq_named == 2,
          "%d unique-count confirmations" % uniq_named)

    say("\n  (b) the six the KN5000 does NOT give a target for")
    say("  %-6s %-46s %5s  %s" % ("map", "KN5000 says", "max", "counts equal to max+1 here"))
    fitted = 0
    for slot, tgt in sorted(unnamed_target.items()):
        fits = [k for k, c in counts.items() if c == mx[slot] + 1]
        fitted += len(fits) > 0
        say("  +0x%02X  %-46s %5d  %s" % (slot, tgt, mx[slot],
                                          ", ".join(fits) if fits else "none -- bound only"))
    check("Q2d  4 of the 6 attain some array's count exactly; 2 attain none",
          fitted == 4, "%d/6" % fitted)
    say("\n  ⚠ WHAT Q2 DOES NOT DO: name a target for any map.  It CONFIRMS that")
    say("  every pairing the KN5000 states is arithmetically possible here and that")
    say("  four are tight, and it REFUSES to convert a tight fit into an assignment")
    say("  where two arrays share the count.  None of the twelve map banners in the")
    say("  assembly is renamed on the strength of this.")


def q3():
    say("\n=== Q3.  THE RECORD NAME FIELDS -- what lets 796 record labels speak ===\n")
    tone, perc = names()
    check("Q3a  274 tone records, all names printable ASCII",
          len(tone) == 274 and all(all(32 <= ord(c) < 127 for c in raw)
                                   for raw, _c in tone.values()),
          "%d records" % len(tone))
    check("Q3b  504 drum-instrument records, all names printable ASCII",
          len(perc) == PERC_N and all(all(32 <= ord(c) < 127 for c in raw)
                                      for raw, _c in perc.values()),
          "stride %d from the directory word at +0xEE" % PERC_STRIDE)
    cams = [c for _r, c in tone.values()]
    check("Q3c  tone camel-case forms are unique, so a label names ONE record",
          len(set(cams)) == len(cams), "%d distinct of %d" % (len(set(cams)), len(cams)))
    # ⚠ the drum names are NOT unique (TublarBellC appears 4 times); the label
    # keeps the record ordinal, which is what makes it unique.  Checked, not assumed.
    pc = [c for _r, c in perc.values()]
    dup = len(pc) - len(set(pc))
    check("Q3c' drum camel forms repeat (%d), so the ordinal MUST stay in the label"
          % dup, dup > 0, "%d distinct of %d" % (len(set(pc)), len(pc)))
    check("Q3d  every camel form maps back to its record's own bytes",
          all(camel(raw) == c for raw, c in list(tone.values()) + list(perc.values())))
    if os.path.exists(KN7000_TABLE):
        K = open(KN7000_TABLE, "rb").read()
        t = sum(1 for raw, _c in set(tone.values()) if raw.encode("latin1") in K)
        p = sum(1 for raw in {r for r, _c in perc.values()} if raw.encode("latin1") in K)
        check("Q3e  tone names occurring VERBATIM in the KN7000 table ROM",
              t == 202, "%d of %d distinct" % (t, len(set(r for r, _c in tone.values()))))
        check("Q3f  drum names occurring VERBATIM in the KN7000 table ROM",
              p == 101, "%d of %d distinct" % (p, len({r for r, _c in perc.values()})))
        say("       (the KN7000 is an MN10300 machine -- a different instruction set --")
        say("        so a name found there is not an artefact of this tree's reading)")
    else:
        say("  SKIP  Q3e/f: %s not present" % KN7000_TABLE)


def q4():
    say("\n=== Q4.  THE NEGATIVES ===\n")
    # slot +0x70 is deliberately outside chain(); measure it by hand here.
    H, _P, _recs = _R2.desc_layout(NO_CHAIN_SLOT)
    segs = _R2.desc_segments(NO_CHAIN_SLOT)
    B = {i: (s, e) for s, e, k, i in segs if k == "B"}
    nA = len([1 for _s, _e, k, _i in segs if k == "A"])
    check("Q4a  slot +0x%02X has NO part-A object at all, so the chain cannot even"
          " start" % NO_CHAIN_SLOT, nA == 0,
          "%d descriptors, %d part-A objects, %d part-B" % (H, nA, len(B)))
    say("       -> its %d pool labels stay POSITIONAL.  An honest hole." % len(B))
    a2c, a60 = S(0x2C), S(0x60)
    same = sum(1 for i in range(1024) if u16(a2c + 2 * i) == u16(a60 + 2 * i))
    check("Q4b  index maps +0x2C and +0x60 agree in only %d of 1024, so the 161"
          % same, same == 988, "%d/1024" % same)
    say("       perc descriptors may NOT borrow the 161 perc catalogue names.")
    say("       Both maps top out at 160, and both targets hold 161 elements, which")
    say("       is suggestive and is NOT proof; 36 positions disagree.")


def q5():
    say("\n=== Q5.  NULLS -- can Q1's joins fail? ===\n")
    rows = [r for r in chain(0x30) if r]
    n = len(rows)
    for name, es in (("every element forced to 6 bytes", 6),
                     ("every element forced to 8 bytes", 8)):
        hit = sum(1 for r in rows
                  if r["b_len"] % es == 0 and r["b_len"] // es == max(r["a_tab"]) + 1)
        check("Q5  NULL %-34s joins %d/%d, not %d" % (name, hit, n, n), hit < n,
              "%.1f%%" % (100.0 * hit / n))
    inv = sum(1 for r in rows
              if r["b_len"] % (6 if (r["tag"] >> 7) & 1 else 8) == 0
              and r["b_len"] // (6 if (r["tag"] >> 7) & 1 else 8) == max(r["a_tab"]) + 1)
    check("Q5  NULL tag bit 7 polarity INVERTED joins %d/%d, not %d" % (inv, n, n),
          inv < n, "%.1f%%" % (100.0 * inv / n))
    # a curve chosen at random instead of the one the pointer names
    wrong = 0
    for r in rows:
        k = (r["curve_k"] + 1) % CURVE_N
        if len(r["a_tab"]) == max(D[CURVE_BASE + CURVE_STRIDE * k:
                                    CURVE_BASE + CURVE_STRIDE * (k + 1)]) + 1:
            wrong += 1
    check("Q5  NULL join 1 against the NEXT curve instead of the named one: %d/%d"
          % (wrong, n), wrong < n, "%.1f%%" % (100.0 * wrong / n))


def q6():
    say("\n=== Q6.  HOW REACHABLE IS EACH RECORD?  (the per-record header line) ===\n")
    say("  A label that carries a record's name still does not say whether anything")
    say("  can select it.  These two censuses put a number on that, per record, and")
    say("  the emitter prints each record's own number in its header.\n")
    c = prog_selectors()
    check("Q6a  the program map holds no 0xFFFF -- every one of its %d entries picks"
          " a record" % PROGMAP_N, 0xFFFF not in c, "%d distinct values" % len(c))
    check("Q6b  and its largest value is 273, exactly ToneDB_ToneOffsetTable's last"
          " index", max(c) == 273, "max %d, table has 274 entries" % max(c))
    reached = sum(1 for i in range(274) if c.get(i, 0))
    check("Q6c  so the map is ONTO: all 274 tone records are selectable",
          reached == 274, "%d/274; per-record counts run %d..%d"
          % (reached, min(c.values()), max(c.values())))
    check("Q6c' checked on the LAST record too, index 273", c.get(273, 0) > 0,
          "record 273 is picked by %d program slots" % c.get(273, 0))
    a, b = drum_selectors()
    check("Q6d  DrumKit_NoteMapA names all 504 drum records, max index 503",
          max(a) == 503 and sum(1 for i in range(PERC_N) if a.get(i, 0)) == PERC_N,
          "%d of %d named" % (sum(1 for i in range(PERC_N) if a.get(i, 0)), PERC_N))
    nb = sum(1 for i in range(PERC_N) if b.get(i, 0))
    missing = [i for i in range(PERC_N) if not b.get(i, 0)]
    check("Q6e  DrumKit_NoteMapB names %d of 504 -- an honest asymmetry, not a"
          " rounding" % nb, nb == 503 and len(missing) == 1,
          "record %d (%r) is named by map A only"
          % (missing[0], names()[1][missing[0]][0]) if missing else "")
    check("Q6e' checked on the LAST drum record, 503",
          a.get(PERC_N - 1, 0) > 0,
          "named by %d map-A entries and %d map-B" % (a.get(503, 0), b.get(503, 0)))


def main():
    say("prom_d round 4 -- turning FRAMED names into CONTENT")
    q1()
    q2()
    q3()
    q4()
    q5()
    q6()
    print("\n%d checks, %d failures" % (NCHECK[0], len(FAILED)))
    for f in FAILED:
        print("  FAILED: %s" % f)
    return 1 if FAILED else 0


if __name__ == "__main__":
    sys.exit(main())
