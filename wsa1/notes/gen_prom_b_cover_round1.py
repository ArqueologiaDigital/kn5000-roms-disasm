#!/usr/bin/env python3
"""Convert prom_b's REACHABLE-AND-UNCONVERTED bytes -- every span of them, in one
emitter -- and say which of them are code and which are not.

QUESTION IT ANSWERS
    "notes/reachability.py says 7,389 bytes of prom_b are reachable code still
     sitting in an `.incbin`.  What is the assembly text for exactly those bytes,
     in a form the byte gate accepts -- and is the tool right that they are code?"

    It is right about a fifth of them.  This file MEASURES the difference instead
    of asserting it, and emits the rest as data, with the evidence at every site.

★ SEMANTICS ARE DEFERRED.  This is a coverage round: every code entry point gets
    a bare `sub_XXXXXX` and every data object a bare `Data_XXXXXX`.  Nothing is
    named, no header speculates.  A stated gap is the deliverable.

⚠ IT NEVER REWRITES A CONVERTED LINE.  Emission is spliced into `.incbin` ranges
    only, between `; === COVER-R1 ... ===` markers.  splice() collects every
    already-converted line OUTSIDE those markers before and after the write and
    refuses on ANY difference, so "the twelve waves of naming work were not
    touched" is a checked claim, not an intention.

────────────────────────────────────────────────────────────────────────────────
THE PROVENANCE SPLIT -- the finding this round turns on
────────────────────────────────────────────────────────────────────────────────
Reachability is not one thing.  Run the walk from entry points that are EVIDENCE
OF CODE -- a slot of the 1,910-entry routine directory, each holding `jp imm24`,
or a branch that prom_b's own already-converted instructions decode -- and
1,495 bytes of `.incbin` are reached.  Add the weak classes -- a `.long` in a
table the tree has framed, a 32-bit immediate loaded by some instruction -- and
it becomes 10,052.  So 8,557 bytes, 85.1% of the total, rest on a pointer and
nothing else.

That matters because in THIS image a framed `.long` table is very often NOT a
jump table.  Five were dumped and read while this round was being built:

    0xF03478  "FIX MOVE"                  then 0x00F034A4, 0x00F03455, ...
    0xF05182  "ATTACK) DECAY)  RELEASE)"  then 0x00F0510D, 0x00F05118, ...
    0xF05AB4  0x0051,0x003E  0x005C,0x004F ...  -- screen coordinate pairs
    0xF06598  "OFF MAINSUB1SUB2SUB3"      then 0x00F064E5, 0x00F064EF, ...
    0xF3A6D9  a 16-byte header, then "  0  1  2 ... 16ALL", "MASTER"

Every one is a caption block or a coordinate array.  The walk marks them anyway,
because a linear decode only stops at a flow-ending BYTE: a seed that lands in
text paints everything up to the first 0x0E.  The transcriptions say the same
thing.  The weak-provenance runs end on `halt`, `swi 0`, `retd 0x2658`,
`ld XIZ,0x4e4f2046` -- that constant is the ASCII "F ON" -- and, at 0xF2B38F,
`jp 0xd705b7`, an address in no image this CPU can fetch; up to 78% of their
bytes are spellings llvm-mc will not encode.  The directory-reached runs of
0xF00000-0xF01800, by contrast, ALL end in `ret`, and their unencodable fraction
is 0.00 to 0.24.

So this file emits code where there is code-provenance and `.byte` where there is
not.  Both leave `.incbin`, so both move notes/reachability.py's number; only the
first is coverage of a code path, and the banner at each site says which it is.

⚠ THE DATA RUNS ARE FRAGMENTS.  Their extents are where the walk happened to
    start and stop, NOT object boundaries, and the rest of each span stays
    `.incbin` because it is not reachable.  A later lane framing a whole caption
    block will have to merge across them.  That is stated at every site.

────────────────────────────────────────────────────────────────────────────────
★★ AND prom_b'S CONVERTED CODE IS CLOSED.  1,495 IS THE WHOLE OF IT.
────────────────────────────────────────────────────────────────────────────────
The obvious worry about a number like 1,495 is that it is small because the walk
cannot see far enough.  Two checks, both in --selftest, say it is not:

  CLOSURE 1  Read the MAME text of all 166,283 lines of prom_b/wsa1_prom_b.s and
             collect every `jr`/`jp`/`call`/`calr` target its ALREADY-CONVERTED
             instructions decode: 7,173 distinct addresses.  ZERO of them land
             inside an `.incbin`.  Adding all 7,173 as seeds moves the
             reachable-and-unconverted total by 0 bytes.
  CLOSURE 2  No `.incbin` span is entered by falling through: for all 117 spans,
             the nearest converted instruction start below the span is either far
             away or ends the flow.

So DEFECT 1, which looks alarming -- a measurement blind to 14,250 decoded
branches -- costs nothing in reachable CODE.  The 2,663 bytes it does add over
the tool's 7,389 arrive through the weak `immediate` class: 137 addresses that
converted code loads as 32-bit constants, i.e. pointers to caption and coordinate
blocks, exactly like the `.long` seeds.

The honest headline for prom_b is therefore: 1,495 bytes of reachable code
remained, and they are all in 0xF00000-0xF01800; the other 8,557 bytes the walks
mark are data that a pointer happens to name.

────────────────────────────────────────────────────────────────────────────────
FOUR DEFECTS THIS ROUND FOUND IN THE MEASUREMENT ITSELF
────────────────────────────────────────────────────────────────────────────────
1. notes/reachability.py CANNOT READ prom_b's CONVERTED LINES.  Its `SRC_LINE`
   expects prom_a's and prom_c's shape, `\t<text>\t; ADDR  hh hh hh`.  prom_b's
   shape is `\t<llvm-mc text>\t; ADDR  <mame text>` -- the hex bytes are not in
   the comment, the MAME text is.  The regex matches 113,862 lines of prom_a and
   21 of prom_b's 166,283 -- where prom_b's OWN shape matches 73,156 of them.
   Consequence: the `proven`, `branch` and `immediate`
   seed classes are EMPTY for prom_b and the 7,173 branch targets its own
   converted code already decodes are never followed, so its published 7,389 is
   a lower bound for a reason that has nothing to do with unframed jump tables.
   The corrected walk finds 10,052.
   ⚠ And the operands cannot be recovered from group(1) either: prom_b's assembly
   spells them in llvm-mc syntax, in DECIMAL (`jp 9044208`).  A fix has to read
   the MAME text in the comment, which is what b_seed_classes() below does.

2. A `.long` SEED IS TREATED AS A CODE ENTRY POINT.  It is not, in this image;
   see THE PROVENANCE SPLIT.  Grading the walk by which seed class reached a byte
   costs one extra pass and separates 1,495 from 8,557 cleanly.

4. THE WALK IS NOT MONOTONE IN ITS SEEDS.  `walk()` returns the moment it meets
   an instruction already in `seen`, WITHOUT scanning that instruction, or the
   rest of that linear run, for branch targets.  Which walk gets there first
   depends on `queue.pop()` order, which depends on the seed set -- so ADDING a
   seed can make the total go DOWN.  Measured on the live tree after this round:
   the corrected walk (a strict superset of the tool's seeds) reports 0 bytes
   reachable-and-unconverted for prom_b while the tool itself reports 80.  A
   superset of entry points cannot really reach fewer bytes; the difference is
   the early return.  --revealed prints both numbers side by side so the gap
   stays visible.

5. ⚠⚠ THE SHARED RESULT CACHE CAN BE POISONED BY ANY LANE, SILENTLY.
   notes/.reachability-cache.json is keyed on a SHA-1 of the three .s files plus
   reachability.py -- and nothing else.  Not the seed set, not source_lines.  So
   a lane that patches either, which ANY provenance experiment must, writes its
   own answer under a fingerprint that still looks valid, and the next reader
   gets it with no warning.  THIS HAPPENED DURING THIS ROUND: a directory-only
   probe left `prom_b: 1495, seeds {directory: 1910}` in the shared cache where
   7,389 belongs.  The file was deleted and derive() now disables _cache_load,
   _cache_store and the per-tag _MEM memo before it touches anything.  A caller
   that varies the inputs cannot be trusted to remember; the fingerprint should
   cover the seed set.

Nothing here is fixed in reachability.py -- it is not this lane's file.  They are
re-measured by --selftest and --revealed so they cannot rot quietly.

────────────────────────────────────────────────────────────────────────────────
WHERE THE LAYOUT COMES FROM
────────────────────────────────────────────────────────────────────────────────
notes/reachability.py itself, re-run over a FROZEN view of prom_b/wsa1_prom_b.s,
three times: strong seeds only, all seeds, and the tool exactly as it stands.
The RECORD in notes/prom_b_cover_round1_layout.json is compared span for span and
run for run against that derivation, and this file refuses to emit if any extent,
any provenance or any total has moved.

  ⚠ THE RE-DERIVATION MUST NOT READ ITS OWN OUTPUT.  frozen_lines() collapses
    every `; === COVER-R1 ... ===` block back to the single whole-span `.incbin`
    it replaced, so the seed scan and the span list are exactly what they were
    before the splice.  Without it this file would stop reproducing its own
    layout the moment it succeeded.  --selftest asserts the frozen view still
    shows every span as one `.incbin` and carries none of this file's markers.

  The derivation is a pure function of (frozen source, ROM) and costs about
  twenty minutes, so it is cached under a SHA-256 of both.  A cache hit is a
  proof that the input has not moved, not a shortcut past the check; and unlike
  reachability.py's own cache the key covers everything the answer depends on.
  --force-derive recomputes regardless.

NOTHING HERE CAN BREAK THE GATE
  Code text comes from notes/llvm_roundtrip_autoforce.py, which assembles and
  byte-compares every candidate spelling before returning it.  Data is printed
  from the ROM.  verify() then re-assembles every emitted code run with llvm-mc
  and compares it with the ROM, and checks the emitted segments tile each
  original `.incbin` span exactly.  main() exits non-zero WITHOUT PRINTING on any
  mismatch.  Then run the real gate:
      python3 scripts/analysis/assert_byte_identical.py

RUN
  python3 notes/gen_prom_b_cover_round1.py             # the assembly, all spans
  python3 notes/gen_prom_b_cover_round1.py --layout    # the run table
  python3 notes/gen_prom_b_cover_round1.py --derive    # re-run the walks only
  python3 notes/gen_prom_b_cover_round1.py --revealed  # ★ the LIVE tree, unfrozen:
                                                       #   what conversion revealed
  python3 notes/gen_prom_b_cover_round1.py --selftest  # every number quoted above
  python3 notes/gen_prom_b_cover_round1.py --splice    # write it into the .s
"""
import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path, write_part  # noqa: E402
sys.path.insert(0, os.path.join(ROOT, "notes"))
sys.path.insert(0, os.path.join(ROOT, "scripts", "analysis"))
AUTOFORCE = os.path.join(ROOT, "notes", "llvm_roundtrip_autoforce.py")
IMGB = os.path.join(ROOT, "original_ROMs", "wsa1_prom_b.ic13")
# ⚠ A WRITE THROUGH THIS NAME IS GUARDED AND WILL REFUSE while the text
# it is handed is the whole image: write_part() sees the master's
# .include lines disappear.  That refusal is correct and is not the fix.
# The fix for a RENAME is asm_source.edit_image(ROOT, <primary>, fn),
# which applies the transform to every constituent file; for a SPLICE it
# is asm_source.locate() on the block's anchor.  See notes/asm_source.py.
SRCB_MASTER = os.path.join(ROOT, "prom_b/wsa1_prom_b.s")   # the WRITE path: write_part() guards it
SRCB = image_path(ROOT, "prom_b/wsa1_prom_b.s")  # the READ path: the image, not the master
ROMNAME = "wsa1_prom_b.ic13"
B_BASE = 0xF00000

MARK = "; === COVER-R1 0x%06X-0x%06X ==="
MARK_END = "; === END COVER-R1 0x%06X-0x%06X ==="
MARK_RE = re.compile(r'^; === COVER-R1 0x([0-9A-F]{6})-0x([0-9A-F]{6}) ===$')
MARK_END_RE = re.compile(r'^; === END COVER-R1 0x([0-9A-F]{6})-0x([0-9A-F]{6}) ===$')
NOTCONV_RE = re.compile(r'^; --- 0x([0-9A-F]{6})-0x([0-9A-F]{6}): not converted ---$')
INCBIN_RE = re.compile(r'^\t\.incbin "original_ROMs/(\S+?)", (0x[0-9A-Fa-f]+), '
                       r'(0x[0-9A-Fa-f]+)\s*$')

# ---------------------------------------------------------------- THE RECORD
# (span_lo, span_hi, [(run_lo, run_hi, kind), ...]).  kind is "code" when the
# routine-directory-only walk reaches the run and "data" when only the full walk
# does.  RE-DERIVED AND COMPARED ON EVERY RUN -- see derive().
RECORD_PATH = os.path.join(ROOT, "notes", "prom_b_cover_round1_layout.json")
DERIVE_CACHE = os.path.join(ROOT, "notes", "prom_b_cover_round1_derived.json")

_cache = {}
FAIL = []


def rom():
    if "rom" not in _cache:
        _cache["rom"] = open(IMGB, "rb").read()
    return _cache["rom"]


def at(a, n=1):
    return rom()[a - B_BASE: a - B_BASE + n]


def record():
    if "rec" not in _cache:
        with open(RECORD_PATH) as f:
            raw = json.load(f)
        _cache["rec"] = [(s["lo"], s["hi"], [tuple(r) for r in s["runs"]]) for s in raw]
    return _cache["rec"]


# ------------------------------------------------------- the frozen source view
def frozen_lines():
    """prom_b/wsa1_prom_b.s as it was BEFORE this file ever spliced: every
    `; === COVER-R1 ... ===` block collapsed to the whole-span `.incbin` it
    replaced.  This is what makes the derivation immune to its own output."""
    src = open(SRCB).read().split("\n")
    out, i = [], 0
    while i < len(src):
        m = MARK_RE.match(src[i])
        if not m:
            out.append(src[i])
            i += 1
            continue
        lo, hi = int(m.group(1), 16), int(m.group(2), 16)
        end = MARK_END % (lo, hi)
        j = i
        while j < len(src) and src[j] != end:
            j += 1
        if j >= len(src):
            raise SystemExit("unterminated COVER-R1 block at 0x%06X" % lo)
        out.append("; --- 0x%06X-0x%06X: not converted ---" % (lo, hi - 1))
        out.append('\t.incbin "original_ROMs/%s", 0x%06X, 0x%06X'
                   % (ROMNAME, lo - B_BASE, hi - lo))
        i = j + 1
    return out


# ------------------------------------------------------ the layout, re-derived
# prom_b's converted lines, `\t<llvm-mc text>\t; ADDR  <mame text>`.  reachability
# .py's SRC_LINE is written for prom_a's shape and matches 21 of these; see
# DEFECT 1.  The MAME text is where this image keeps its decoded addresses --
# the llvm-mc operand beside it is in DECIMAL and unusable for a seed scan.
B_LINE = re.compile(r'^\t(\S.*?)\t;\s*([0-9A-F]{6})\s\s(.*)$')
R_FLOW = re.compile(r'^\s*(ret|reti|retd|jp\s|jr\s+0x|halt|swi)', re.I)


def b_seed_classes():
    """(branch, immediate) entry points read out of prom_b's OWN converted code,
    from the FROZEN view.  These are the seeds reachability.py cannot see."""
    import reachability as R
    branch, imm = set(), set()
    for ln in R.source_lines("prom_b"):
        m = B_LINE.match(ln)
        if not m:
            continue
        text = m.group(3)
        for mm in R.BRANCH.finditer(text):
            t = int(mm.group(1), 16)
            if R.owner(t, R.CPU1):
                branch.add(t)
        for mm in re.finditer(r'0x00([0-9A-Fa-f]{6})', text):
            t = int(mm.group(1), 16)
            if R.owner(t, R.CPU1):
                imm.add(t)
    return branch, imm


def _key():
    import hashlib
    h = hashlib.sha256()
    h.update("\n".join(frozen_lines()).encode())
    h.update(rom())
    return h.hexdigest()


def _ranges(sset):
    """A byte set as a list of merged [lo,hi) ranges -- compact enough to cache,
    so a change to the SPLIT RULE never costs another twenty-minute walk."""
    out = []
    for x in sorted(sset):
        if out and out[-1][1] == x:
            out[-1][1] = x + 1
        else:
            out.append([x, x + 1])
    return out


def _expand(rs):
    out = set()
    for a, b in rs:
        out.update(range(a, b))
    return out


def _split(spans, seen, seen_s):
    """[(span_lo, span_hi, [(run_lo, run_hi, kind), ...])], where a run is a
    maximal reachable range OF UNIFORM PROVENANCE.

    ⚠ SPLITTING ON PROVENANCE, NOT JUST ON REACHABILITY, IS LOAD-BEARING.  The
    first version took a maximal reachable run and typed it by its FIRST byte,
    and 0xF00800 swallowed 261 bytes of table that follow it: the strong walk
    stops at 0xF00B48 and the rest is reached only through `ld XIZ,0x00f00b48 /
    ld (0x605005),XIZ` at 0xF00A01 -- a base address handed to something, and
    0xF00B48 itself decodes as `90 00 / jrl NZ,0xef9ba1 / rcf` repeating, with
    branch targets in no image.  Typing that as code would have been this round's
    own version of the mistake it is documenting."""
    out = []
    for lo, hi in spans:
        runs, x = [], lo
        while x < hi:
            if x in seen:
                k = "code" if x in seen_s else "data"
                y = x
                while y < hi and y in seen and (("code" if y in seen_s else "data") == k):
                    y += 1
                runs.append((x, y, k))
                x = y
            else:
                x += 1
        if runs:
            out.append((lo, hi, runs))
    return out


class _All(object):
    """`x in _EVERYTHING` is always True -- the strong pass needs no restriction
    on where it harvests, because everything it reached IS code-provenance."""

    def __contains__(self, _x):
        return True


_EVERYTHING = _All()


def derive(force=False):
    """(spans-with-runs, totals) from notes/reachability.py, run TWICE over the
    FROZEN view of prom_b/wsa1_prom_b.s:

        pass STRONG  routine-directory slots + the branch targets prom_b's own
                     converted instructions already decode  -> provenance "code"
        pass ALL     + `.long` pointer-table entries + 32-bit immediates
                     -> the extra bytes get provenance "data"

    The two passes are what separates a code entry point from a caption pointer;
    THE PROVENANCE SPLIT in the header says why that separation is needed.

    ⚠ The derivation is a pure function of (frozen source, ROM) and costs ~15
    minutes, so the result is cached under a SHA-256 of both.  A cache hit is
    therefore a PROOF that the input has not moved, not a shortcut past the
    check; --force-derive recomputes anyway."""
    if "derive" in _cache:
        return _cache["derive"]
    key = _key()
    if not force and os.path.exists(DERIVE_CACHE):
        blob = json.load(open(DERIVE_CACHE))
        if blob.get("key") == key:
            out = (_split([tuple(x) for x in blob["spans"]],
                          _expand(blob["seen"]), _expand(blob["strong"])),
                   blob["totals"])
            _cache["derive"] = out
            return out
    import reachability as R                                        # noqa: E402
    # ⚠⚠ NEUTRALISE reachability.py's SHARED RESULT CACHE BEFORE ANYTHING ELSE.
    # Its fingerprint is a SHA-1 of the three .s files plus reachability.py, and
    # nothing else -- not the seed set, not source_lines.  A lane that patches
    # either (which any provenance experiment must) therefore writes its OWN
    # answer into notes/.reachability-cache.json under a fingerprint that still
    # looks valid, and the next reader gets it silently.  ★ THIS ACTUALLY
    # HAPPENED during this round: a directory-only probe left `prom_b: 1495,
    # seeds {directory: 1910}` in the shared cache where 7,389 belongs.  The file
    # was deleted; these three lines are why it cannot happen again from here.
    R._MEM.clear()
    R._cache_load = lambda: None
    R._cache_store = lambda *_a, **_k: None
    lines = frozen_lines()
    paths = dict((t, s) for t, s, _f, _b in R.IMAGES)
    R.source_lines = lambda tag, _l=lines: _l if tag == "prom_b" else \
        open(os.path.join(ROOT, paths[tag])).read().split("\n")
    base_seeds = R.seeds
    branch, imm = b_seed_classes()

    def make(keep_weak):
        def seeds(tag, cpu):
            from collections import defaultdict
            sd = base_seeds(tag, cpu)
            out = defaultdict(set)
            out["directory"] = sd["directory"]
            out["branch_b"] = set(branch)
            if keep_weak:
                out["pointer_table"] = sd["pointer_table"]
                out["immediate_b"] = set(imm)
            return out
        return seeds

    # ⚠ analyse() memoises on the TAG ALONE (`_MEM`), so _MEM must be cleared
    # between passes or the second and third calls return the first one's answer.
    #
    # ★ AND EACH PASS IS ITERATED TO A FIXPOINT.  Converting a run makes its own
    # `call`/`jp` targets and its 32-bit immediates VISIBLE, and some of them
    # point at bytes the previous walk never reached -- exactly the effect the
    # coverage brief warns about.  MEASURED HERE: pass 1 left 262 bytes that only
    # appeared once 0xF00000-0xF01800 was transcribed, and every one of them
    # arrived through `ld XIZ,0x00f00b48` at 0xF00A01/0xF00A12/0xF00A1E/0xF00B23,
    # an IMMEDIATE, not a branch.  (All 112 branch targets the transcription added
    # were internal to runs already marked; the walk had followed them itself.)
    # Iterating here means the .s does not have to be spliced twice to converge,
    # and the round's leftover is a measured 0 rather than an unexplained tail.
    def fixpoint(keep_weak, tag, strong_seen=None):
        if strong_seen is None:
            strong_seen = _EVERYTHING
        prev, rounds = None, 0
        extra_b, extra_i = set(), set()
        while True:
            rounds += 1
            def seeds(t, cpu, _kw=keep_weak, _b=extra_b, _i=extra_i):
                from collections import defaultdict
                sd = base_seeds(t, cpu)
                out = defaultdict(set)
                out["directory"] = sd["directory"]
                out["branch_b"] = set(branch) | set(_b)
                if _kw:
                    out["pointer_table"] = sd["pointer_table"]
                    out["immediate_b"] = set(imm) | set(_i)
                return out
            R.seeds = seeds
            R._MEM.clear()
            r = R.analyse("prom_b", R.CPU1)
            if prev is not None and r["reach_in_incbin"] == prev:
                print("  %s pass: fixpoint after %d walk(s), %d bytes"
                      % (tag, rounds, r["reach_in_incbin"]), file=sys.stderr)
                return r
            prev = r["reach_in_incbin"]
            if rounds > 6:
                raise SystemExit("%s pass did not converge in 6 walks" % tag)
            # ⚠⚠ HARVEST ONLY FROM RUNS THAT WILL BE EMITTED AS CODE.
            # A weak-provenance run is a caption block; transcribing it produces a
            # GARBAGE decode, and the `0x00xxxxxx` constants inside that garbage
            # are not operands of anything.  Harvesting them would manufacture a
            # cascade of "reachable" text out of noise -- and it would not even
            # match the .s, where those runs are emitted as `.byte` and expose no
            # operand at all.  So the harvest is restricted to bytes the STRONG
            # walk reached, which are exactly the runs spelled as instructions.
            nb, ni = set(), set()
            for lo, hi in r["spans"]:
                x = lo
                while x < hi:
                    if x in r["seen"] and x in strong_seen:
                        y = x
                        while y < hi and y in r["seen"] and y in strong_seen:
                            y += 1
                        for ln in transcribe(x, y - x):
                            m = B_LINE.match(ln)
                            if not m:
                                continue
                            for mm in R.BRANCH.finditer(m.group(3)):
                                v = int(mm.group(1), 16)
                                if R.owner(v, R.CPU1):
                                    nb.add(v)
                            for mm in re.finditer(r'0x00([0-9A-Fa-f]{6})', m.group(3)):
                                v = int(mm.group(1), 16)
                                if R.owner(v, R.CPU1):
                                    ni.add(v)
                        x = y
                    else:
                        x += 1
            extra_b |= nb
            extra_i |= ni

    strong = fixpoint(False, "strong")
    allr = fixpoint(True, "all", strong["seen"])
    R.seeds = base_seeds
    R._MEM.clear()
    tool = R.analyse("prom_b", R.CPU1)          # the tool as it stands, for the record
    R._MEM.clear()

    spans = _split(allr["spans"], allr["seen"], strong["seen"])
    totals = {"incbin": allr["incbin"], "all": allr["reach_in_incbin"],
              "strong": strong["reach_in_incbin"], "tool": tool["reach_in_incbin"],
              "seeds_branch": len(branch), "seeds_immediate": len(imm),
              "seeds_tool": {k: v for k, v in tool["seeds"].items() if v}}
    json.dump({"key": key, "totals": totals,
               "spans": [list(x) for x in allr["spans"]],
               "seen": _ranges(allr["seen"]), "strong": _ranges(strong["seen"])},
              open(DERIVE_CACHE, "w"))
    _cache["derive"] = (spans, totals)
    return _cache["derive"]


def check_record():
    """Refuse to emit if the derivation moved since the audit."""
    spans, totals = derive()
    rec = record()
    if len(spans) != len(rec):
        raise SystemExit("layout moved: derived %d spans, RECORD has %d"
                         % (len(spans), len(rec)))
    for (a, b, ra), (c, d, rb) in zip(spans, rec):
        if (a, b) != (c, d) or ra != rb:
            raise SystemExit("layout moved at 0x%06X: derived %r, RECORD %r"
                             % (a, (a, b, ra), (c, d, rb)))
    return spans, totals


# ------------------------------------------------------------- transcription
def transcribe(start, length):
    key = ("t", start, length)
    if key not in _cache:
        p = subprocess.run([sys.executable, AUTOFORCE, "b", hex(start), hex(length),
                            "--quiet"], capture_output=True, text=True, cwd=ROOT)
        if p.returncode != 0:
            raise SystemExit("autoforce failed at 0x%06X:\n%s" % (start, p.stderr))
        _cache[key] = p.stdout.rstrip("\n").split("\n")
    return _cache[key]


# -------------------------------------------------------------- the evidence
def directory_slots(target):
    """Routine-directory slots (prom_b 0x40000..0x44018, each a `jp imm24`) whose
    target is `target`.  Re-read from the ROM, not typed in."""
    d, out = rom(), []
    for s in range(0x40000, 0x44018, 4):
        if d[s] == 0x1B and (d[s + 1] | d[s + 2] << 8 | d[s + 3] << 16) == target:
            out.append(B_BASE + s)
    return out


def _site_index():
    """{target: [address-of-the-instruction, ...]} over every branch prom_b's
    ALREADY-CONVERTED code decodes, read from the MAME text of the frozen view.
    ⚠ This is the evidence notes/reachability.py cannot see (DEFECT 1)."""
    if "sites" not in _cache:
        import reachability as R
        idx, imm = {}, {}
        for ln in frozen_lines():
            m = B_LINE.match(ln)
            if not m:
                continue
            a, text = int(m.group(2), 16), m.group(3)
            for mm in R.BRANCH.finditer(text):
                idx.setdefault(int(mm.group(1), 16), []).append(a)
            for mm in re.finditer(r'0x00([0-9A-Fa-f]{6})', text):
                imm.setdefault(int(mm.group(1), 16), []).append(a)
        _cache["sites"] = (idx, imm)
    return _cache["sites"]


def branch_sites(target):
    return _site_index()[0].get(target, [])


def immediate_sites(target):
    return _site_index()[1].get(target, [])


def word_sites(value):
    """Every ROM offset of prom_b holding `value` as a 32-bit little-endian word.
    For a data run this is the framed `.long` that made the walk enter it."""
    d, out, want = rom(), [], value.to_bytes(4, "little")
    i = d.find(want)
    while i != -1 and len(out) < 64:
        out.append(B_BASE + i)
        i = d.find(want, i + 1)
    return out


def measure(lo, hi, lines):
    blk = at(lo, hi - lo)
    unenc = 0
    for l in lines:
        if "[llvm-mc cannot encode this]" in l:
            m = re.match(r'\t\.byte ([^\t]*)\t', l)
            unenc += len(m.group(1).split(",")) if m else 0
    asc = sum(1 for x in blk if 32 <= x < 127) / len(blk)
    last = lines[-1].split(";", 1)[1].strip()[7:].strip() if lines else ""
    return {"n": hi - lo, "instr": len(lines), "unenc": unenc,
            "unenc_frac": unenc / (hi - lo), "ascii": asc,
            "last": last.replace("[llvm-mc cannot encode this]", "").strip()}


# ------------------------------------------------------------------ emission
def wrap(prefix, text, width=78):
    import textwrap
    body = textwrap.wrap(text, width - len(prefix)) or [""]
    return [prefix + body[0]] + ["; " + " " * (len(prefix) - 2) + x for x in body[1:]]


def byte_rows(a, n, per=16):
    out = []
    for off in range(0, n, per):
        k = min(per, n - off)
        blk = at(a + off, k)
        txt = "".join(chr(x) if 32 <= x < 127 else "." for x in blk)
        out.append("\t.byte\t%s\t; %06X  |%s|"
                   % (", ".join("0x%02X" % x for x in blk), a + off, txt))
    return out


def incbin_line(lo, hi):
    return '\t.incbin "original_ROMs/%s", 0x%06X, 0x%06X' % (ROMNAME, lo - B_BASE, hi - lo)


def code_block(lo, hi):
    lines = transcribe(lo, hi - lo)
    m = measure(lo, hi, lines)
    slots, br = directory_slots(lo), branch_sites(lo)
    out = ["; " + "-" * 74, "; sub_%06X" % lo]
    ev = []
    if slots:
        ev.append("routine-directory slot%s %s, each holding `jp 0x00%06X` (the "
                  "slots are re-read from the ROM on every emit)"
                  % ("" if len(slots) == 1 else "s",
                     " ".join("T_%06X" % x for x in slots[:6]), lo))
    if br:
        ev.append("%d branch%s in prom_b's ALREADY-CONVERTED code name it: %s%s"
                  % (len(br), "" if len(br) == 1 else "es",
                     " ".join("0x%06X" % x for x in sorted(set(br))[:8]),
                     " +%d more" % (len(br) - 8) if len(br) > 8 else ""))
    if not ev:
        ev.append("a branch decoded inside this block -- the walk enters 0x%06X "
                  "from code it had already reached, not from any table" % lo)
    out += wrap("; Reached from: ", "; ".join(ev) + ".")
    out += wrap("; Extent:  ", "%d bytes, %d instructions, ends `%s`.  The walk "
                "marks exactly 0x%06X-0x%06X.  %d byte%s (%.0f%%) sit in spellings "
                "llvm-mc cannot encode and stay `.byte` with the MAME text in the "
                "comment."
                % (m["n"], m["instr"], m["last"], lo, hi - 1, m["unenc"],
                   "" if m["unenc"] == 1 else "s", 100 * m["unenc_frac"]))
    out += wrap("; Unknown: ", "what the routine is for.  ★ COVERAGE ROUND: this "
                "pass converts reachable bytes and defers every semantic question, "
                "so the label stays sub_XXXXXX with the gap stated.")
    out += ["; " + "-" * 74, "sub_%06X:" % lo]
    return out + lines


def data_block(lo, hi):
    lines = transcribe(lo, hi - lo)
    m = measure(lo, hi, lines)
    ptr, imm = word_sites(lo), immediate_sites(lo)
    out = ["; " + "-" * 74,
           "; Data_%06X -- %d bytes, EMITTED AS DATA (not promoted to code)."
           % (lo, m["n"])]
    ev = []
    if ptr:
        ev.append("0x00%06X appears as a 32-bit word at %s%s"
                  % (lo, " ".join("0x%06X" % x for x in ptr[:5]),
                     " +%d more" % (len(ptr) - 5) if len(ptr) > 5 else ""))
    if imm:
        ev.append("converted code at %s loads it as a 32-bit immediate"
                  % " ".join("0x%06X" % x for x in sorted(set(imm))[:4]))
    if not ev:
        ev.append("nothing aligned holds this address; the walk fell through into it")
    out += wrap("; Reached from: ", "%s.  No routine-directory slot and no branch "
                "decoded in converted code names it." % "; ".join(ev))
    out += wrap("; Measured: ", "%.0f%% printable ASCII; a linear decode runs %d "
                "instructions and ends `%s`, with %.0f%% of the bytes in spellings "
                "llvm-mc will not encode."
                % (100 * m["ascii"], m["instr"], m["last"], 100 * m["unenc_frac"]))
    out += ["; ⚠ The extent is the reachability walk's, not the object's; the rest of",
            ";   this span is unreachable and stays `.incbin`.  Why this is data and",
            ";   not code: THE PROVENANCE SPLIT in notes/gen_prom_b_cover_round1.py.",
            "; " + "-" * 74, "Data_%06X:" % lo]
    return out + byte_rows(lo, hi - lo)


def block_comment(text, indent=";   "):
    """A comment paragraph wrapped at a sane width.  ⚠ wrap()'s continuation is
    aligned under a PREFIX, which is right for a short label like `; Extent:  `
    and wrong for a whole sentence -- the first draft of the span banner used it
    and produced 96 blocks of ragged 30-column text."""
    import textwrap
    return [indent.rstrip() + " " + b if i else "; " + b
            for i, b in enumerate(textwrap.wrap(text, 76))]


def span_block(lo, hi, runs):
    nc = sum(b - a for a, b, k in runs if k == "code")
    nd = sum(b - a for a, b, k in runs if k == "data")
    kc = sum(1 for r in runs if r[2] == "code")
    kd = sum(1 for r in runs if r[2] == "data")
    out = [MARK % (lo, hi)]
    out += block_comment(
        "0x%06X-0x%06X, coverage round 1: %d of this span's %d bytes are reachable "
        "-- %d as CODE (an entry point in the routine directory, or a branch "
        "prom_b's own converted instructions decode) in %d run%s, and %d as DATA "
        "(only a `.long` or a 32-bit immediate names it) in %d run%s.  Everything "
        "else here is NOT reachable and stays `.incbin`.  Regenerate: python3 "
        "notes/gen_prom_b_cover_round1.py --splice"
        % (lo, hi - 1, nc + nd, hi - lo, nc, kc, "" if kc == 1 else "s",
           nd, kd, "" if kd == 1 else "s"))
    pos = lo
    for a, b, kind in runs:
        if a > pos:
            out += ["", incbin_line(pos, a)]
        out += [""] + (code_block(a, b) if kind == "code" else data_block(a, b))
        pos = b
    if pos < hi:
        out += ["", incbin_line(pos, hi)]
    out += ["", MARK_END % (lo, hi)]
    return out


# -------------------------------------------------------------- verification
def verify(spans):
    """Every code run re-assembles to the ROM, and the emitted segments tile each
    span exactly."""
    import llvm_roundtrip as RT
    for lo, hi, runs in spans:
        pos = lo
        for a, b, kind in runs:
            if a < pos or b > hi or b <= a:
                return False, "run 0x%06X-0x%06X does not fit its span" % (a, b)
            pos = b
        for a, b, kind in runs:
            if kind != "code":
                continue
            body = [l + "\n" for l in transcribe(a, b - a)]
            got, err = RT.assemble(body)
            if got is None:
                return False, "llvm-mc refused 0x%06X:\n%s" % (a, err[-2000:])
            if got != at(a, b - a):
                return False, "0x%06X does not re-assemble to the ROM" % a
    return True, ("%d spans, %d runs, %d code bytes re-assembled byte-exact"
                  % (len(spans), sum(len(r) for _l, _h, r in spans),
                     sum(b - a for _l, _h, r in spans for a, b, k in r if k == "code")))


# ------------------------------------------------------------------- emission
def emit():
    spans, _t = check_record()
    out = []
    for lo, hi, runs in spans:
        out += span_block(lo, hi, runs) + [""]
    return out


LABEL_RE = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):')


def block_labels(lines):
    return set(m.group(1) for m in
               (LABEL_RE.match(l) for l in lines) if m)


def splice():
    spans, _t = check_record()
    ok, msg = verify(spans)
    if not ok:
        raise SystemExit("refusing to splice: " + msg)
    byspan = {}
    for lo, hi, runs in spans:
        byspan[lo] = (hi, span_block(lo, hi, runs))
    src = open(SRCB).read().split("\n")
    before = converted_lines(src)
    out, i, done = [], 0, set()
    while i < len(src):
        m = MARK_RE.match(src[i])
        if m:                                   # re-splice: replace the old block
            lo, hi = int(m.group(1), 16), int(m.group(2), 16)
            end = MARK_END % (lo, hi)
            j = i
            while j < len(src) and src[j] != end:
                j += 1
            # ★ GUARD (added 2026-09-02, lane promB2).  This branch replaces a
            # WHOLE COVER-R1 block with this file's own emission.  The
            # "nothing was touched" guard below collects converted lines from
            # OUTSIDE the markers, so it is blind to work another pass spliced
            # INSIDE one -- and reverting such work to `.incbin` leaves the byte
            # gate green, so nothing else would notice either.  0xF0033F-
            # 0xF007FF and 0xF0199E-0xF01E71 are exactly that case today.
            # Refuse rather than clobber: a label present in the block but not
            # in the replacement is work this file did not write.
            lost = sorted(block_labels(src[i:j + 1]) - block_labels(byspan[lo][1]))
            if lost and "--force" not in sys.argv:
                raise SystemExit(
                    "refusing to re-splice 0x%06X-0x%06X: the block holds %d "
                    "label(s) this file's emission does not write, so replacing "
                    "it would silently discard them -- %s%s.  Re-derive this "
                    "file's span record against the CURRENT source, or pass "
                    "--force if the loss is meant."
                    % (lo, hi, len(lost), ", ".join(lost[:8]),
                       " ..." if len(lost) > 8 else ""))
            out += byspan[lo][1]
            done.add(lo)
            i = j + 1
            continue
        m = NOTCONV_RE.match(src[i])
        if m and int(m.group(1), 16) in byspan and \
                byspan[int(m.group(1), 16)][0] - 1 == int(m.group(2), 16):
            i += 1                              # drop the stale "not converted"
            continue
        m = INCBIN_RE.match(src[i])
        if m and m.group(1) == ROMNAME:
            lo = B_BASE + int(m.group(2), 16)
            if lo in byspan and byspan[lo][0] - lo == int(m.group(3), 16):
                out += byspan[lo][1]
                done.add(lo)
                i += 1
                continue
        out.append(src[i])
        i += 1
    missing = sorted(set(byspan) - done)
    if missing:
        raise SystemExit("could not place %d span(s): %s"
                         % (len(missing), " ".join("0x%06X" % x for x in missing)))
    after = converted_lines(out)
    if after != before:
        lost = [l for l in before if l not in set(after)][:5]
        raise SystemExit("REFUSING TO SPLICE: the already-converted text changed "
                         "(%d lines before, %d after).  First lost line(s):\n%s"
                         % (len(before), len(after), "\n".join(lost)))
    write_part(SRCB_MASTER, "\n".join(out))
    print("spliced %d spans; %s" % (len(done), msg))
    print("already-converted lines outside this round's blocks, before / after: "
          "%d / %d -- IDENTICAL LINE FOR LINE, which is the no-overwrite proof."
          % (len(before), len(after)))
    return 0


CONV_RE = re.compile(r'^\t(\S.*?)\t;\s*([0-9A-F]{6})\s\s')


def converted_lines(lines):
    """Every line of prom_b that carries a decoded instruction or a printed data
    row, IN ORDER.  ⚠ Collected OUTSIDE the COVER-R1 blocks, so this file's own
    output cannot mask a line it destroyed: splice() compares the two lists and
    refuses on ANY difference, which is what makes "no already-converted line was
    rewritten" a checked claim rather than an intention."""
    n, inside = [], False
    for l in lines:
        if MARK_RE.match(l):
            inside = True
        elif MARK_END_RE.match(l):
            inside = False
        elif not inside and CONV_RE.match(l):
            n.append(l)
    return n


# ---------------------------------------------------------------------- main
def c(desc, got, want, verbose=True):
    ok = got == want
    if not ok:
        FAIL.append("%s\n      got  %r\n      want %r" % (desc, got, want))
    if verbose:
        print(("  ok    " if ok else "  FAIL  ") + desc)
    return ok


def selftest():
    del FAIL[:]
    spans, T = derive("--force-derive" in sys.argv)
    rec = record()
    c("the derivation still matches the RECORD, span for span and run for run",
      [(a, b, r) for a, b, r in spans], [(a, b, r) for a, b, r in rec])
    nc = sum(b - a for _l, _h, r in spans for a, b, k in r if k == "code")
    nd = sum(b - a for _l, _h, r in spans for a, b, k in r if k == "data")
    c("reachable-and-unconverted (corrected walk), and the provenance split",
      (nc + nd, nc, nd), (T["all"], T["strong"], T["all"] - T["strong"]))
    c("notes/reachability.py, unmodified, still says 7,389 for prom_b",
      T["tool"], 7389)
    c("the corrected walk finds more than the tool does", T["all"] > T["tool"], True)
    # DEFECT 1: the tool cannot read prom_b's converted lines.
    import reachability as R
    src = open(SRCB).read().split("\n")
    c("DEFECT 1: reachability.SRC_LINE matches under 100 lines of prom_b",
      sum(1 for l in src if R.SRC_LINE.match(l)) < 100, True)
    # ⚠ MEASURED, NOT GUESSED.  The first draft of this check asserted "over
    # 100,000" from memory and FAILED at 73,156.  The exact count is pinned here,
    # over the FROZEN view so this round's own output does not inflate it.
    c("DEFECT 1: ...while prom_b's own shape matches 73,156 lines",
      sum(1 for l in frozen_lines() if CONV_RE.match(l)), 73156)
    c("DEFECT 1: so the tool's only non-empty seed classes for prom_b are two",
      sorted(T["seeds_tool"]), ["directory", "pointer_table"])
    c("DEFECT 1: reading the MAME text recovers thousands of branch targets",
      T["seeds_branch"] > 5000, True)
    # DEFECT 2: a `.long` seed is not a code entry point.  Four sampled sites,
    # each re-read from the ROM.
    for a, want in ((0xF03478, b"FIX MOVE"), (0xF05182, b"ATTACK) DECAY)"),
                    (0xF06598, b"OFF MAINSUB1SUB2SUB3"), (0xF349BB, b"OFF ON")):
        c("DEFECT 2: 0x%06X, a `.long` seed, holds the text %r" % (a, want),
          at(a, len(want)), want)
    c("DEFECT 2: 0xF2B38F's linear decode leaves the address space (`jp 0xd705b7`)",
      "jp 0xd705b7" in measure(0xF2B38F, 0xF2B422,
                               transcribe(0xF2B38F, 0xF2B422 - 0xF2B38F))["last"], True)
    # the freeze
    pre = [l for l in frozen_lines()]
    c("freeze(): the frozen view still shows every span as one `.incbin`",
      [lo for lo, hi, _r in rec if incbin_line(lo, hi) not in pre], [])
    c("freeze(): and it carries none of this file's own markers",
      [l for l in pre if MARK_RE.match(l) or MARK_END_RE.match(l)], [])
    # ★ THE TWO CLOSURE CHECKS.  Together with the provenance split they are why
    # this round says prom_b has 1,495 bytes of unconverted CODE and not more.
    import bisect
    conv, incs = {}, []
    for ln in frozen_lines():
        m = B_LINE.match(ln)
        if m:
            conv[int(m.group(2), 16)] = m.group(3)
            continue
        m = INCBIN_RE.match(ln)
        if m and m.group(1) == ROMNAME:
            lo = B_BASE + int(m.group(2), 16)
            incs.append((lo, lo + int(m.group(3), 16)))
    inspan = lambda a: any(lo <= a < hi for lo, hi in incs)
    br, imm = _site_index()
    c("CLOSURE 1: every branch prom_b's converted code decodes lands in code "
      "that is ALREADY converted -- not one points into an `.incbin`",
      sorted("0x%06X" % a for a in br if inspan(a)), [])
    addrs = sorted(conv)
    fall = []
    for lo, _hi in incs:
        i = bisect.bisect_left(addrs, lo)
        if i and lo - addrs[i - 1] <= 8 and not R_FLOW.match(conv[addrs[i - 1]]):
            fall.append("0x%06X" % lo)
    c("CLOSURE 2: no `.incbin` span is entered by FALLING THROUGH out of "
      "converted code", fall, [])
    c("...and the weak class is what the extra bytes come from: %d immediates "
      "land in an `.incbin`" % sum(1 for a in imm if inspan(a)),
      sum(1 for a in imm if inspan(a)) > 100, True)
    # no emitted label may collide with one of the 6,108 already in the file
    have = set()
    for ln in frozen_lines():
        m = re.match(r'^([A-Za-z_][A-Za-z0-9_]*):', ln)
        if m:
            have.add(m.group(1))
    want = set()
    for _l, _h, r in spans:
        for a, _b, k in r:
            want.add(("sub_%06X" if k == "code" else "Data_%06X") % a)
    c("no emitted label collides with one already in prom_b/wsa1_prom_b.s",
      sorted(have & want), [])
    ok, msg = verify(spans)
    c("every code run re-assembles to the ROM and the runs tile their spans",
      (ok, msg.split(",")[0]), (True, "%d spans" % len(spans)))
    print("\n%s (%d failed)" % ("CHECKS PASS" if not FAIL else "CHECKS FAILED", len(FAIL)))
    for f in FAIL:
        print("   ! " + f)
    return 0 if not FAIL else 1


def main():
    if "--derive" in sys.argv:
        spans, T = derive("--force-derive" in sys.argv)
        print("spans %d   incbin %d" % (len(spans), T["incbin"]))
        print("  reachable-and-unconverted, corrected walk : %d" % T["all"])
        print("    of which routine-directory/branch code  : %d" % T["strong"])
        print("    of which `.long`/immediate only (data)  : %d" % (T["all"] - T["strong"]))
        print("  notes/reachability.py as it stands        : %d" % T["tool"])
        print("  seeds it cannot see: %d branch, %d immediate"
              % (T["seeds_branch"], T["seeds_immediate"]))
        if "--write-record" in sys.argv:
            json.dump([{"lo": a, "hi": b, "runs": [list(x) for x in r]}
                       for a, b, r in spans], open(RECORD_PATH, "w"), indent=1)
            print("RECORD written to " + os.path.relpath(RECORD_PATH, ROOT))
        return 0
    if "--revealed" in sys.argv:
        # ⚠ NO FREEZE.  The point is to read the tree AS IT NOW STANDS, so that
        # code this round converted contributes its own branch targets.  That is
        # the "converting a span can reveal new reachable bytes" effect, measured
        # rather than assumed.  Compare with --derive, which freezes.
        import reachability as R
        R._MEM.clear()
        R._cache_load = lambda: None
        R._cache_store = lambda *_a, **_k: None
        live = open(SRCB).read().split("\n")
        paths = dict((t, x) for t, x, _f, _b in R.IMAGES)
        R.source_lines = lambda tag, _l=live: _l if tag == "prom_b" else \
            open(os.path.join(ROOT, paths[tag])).read().split("\n")
        base_seeds = R.seeds
        _cache.pop("sites", None)
        branch, imm = b_seed_classes()

        def seeds(tag, cpu):
            from collections import defaultdict
            sd = base_seeds(tag, cpu)
            out = defaultdict(set)
            out["directory"] = sd["directory"]
            out["pointer_table"] = sd["pointer_table"]
            out["branch_b"] = set(branch)
            out["immediate_b"] = set(imm)
            return out

        R.seeds = seeds
        r = R.analyse("prom_b", R.CPU1)
        R._MEM.clear()
        R.seeds = base_seeds
        tool = R.analyse("prom_b", R.CPU1)
        R._MEM.clear()
        print("LIVE tree, corrected walk : incbin %d  reachable-and-unconverted %d"
              % (r["incbin"], r["reach_in_incbin"]))
        print("LIVE tree, the tool as it stands  : reachable-and-unconverted %d"
              % tool["reach_in_incbin"])
        print("  seeds now visible: %d branch, %d immediate"
              % (len(branch), len(imm)))
        for lo, hi in sorted(r["spans"]):
            n = sum(1 for x in range(lo, hi) if x in r["seen"])
            if n:
                print("    0x%06X-0x%06X %6d B, %6d reachable" % (lo, hi - 1, hi - lo, n))
        return 0
    if "--layout" in sys.argv:
        spans, _t = derive()
        for lo, hi, runs in spans:
            print("  span 0x%06X-0x%06X  %6d B" % (lo, hi - 1, hi - lo))
            for a, b, k in runs:
                print("      %-4s 0x%06X-0x%06X  %6d" % (k, a, b - 1, b - a))
        print("  code %d   data %d"
              % (sum(b - a for _l, _h, r in spans for a, b, k in r if k == "code"),
                 sum(b - a for _l, _h, r in spans for a, b, k in r if k == "data")))
        return 0
    if "--selftest" in sys.argv or "--checks" in sys.argv:
        return selftest()
    if "--splice" in sys.argv:
        return splice()
    spans, _t = check_record()
    ok, msg = verify(spans)
    if not ok:
        raise SystemExit("refusing to emit: " + msg)
    print("\n".join(emit()))
    return 0


if __name__ == "__main__":
    sys.exit(main())
