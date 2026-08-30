#!/usr/bin/env python3
"""Convert the STRONG-reachable code left in prom_a's `.incbin` spans after
round 1, and leave everything else exactly where it is.

QUESTION IT ANSWERS
    "Round 1 framed 9,437 bytes of prom_a and that act turned its own output into
     new seeds.  Which bytes does execution reach NOW that no walk could see
     before, and which of them are worth framing?"

    This is the emitter for the WSA1R COVERAGE GOAL, round 2, lane COVERAGE-A.
    It is deliberately NOT a naming pass: every label it writes is `sub_XXXXXX`
    plus the class of entry point that justifies it.  Semantics are a later goal.

★★ IT WALKS THE **STRONG** SEED CLASSES ONLY -- AND THAT IS THE WHOLE DIFFERENCE
    notes/reachability.py grades its seeds, because round 1 proved the grade
    matters:

        STRONG  a prom_b routine-directory slot (`jp imm24`), a branch or call in
                already-decoded code, a hardware vector.  Those are ENTRY POINTS.
        WEAK    a 32-bit immediate that happens to land in an image, or an entry
                of a framed `.long` table.  Those are POINTERS, and a pointer is
                as likely to name a TABLE as a routine.

    Round 1's first splice of 0xFA1404 walked from weak seeds and framed 701
    bytes of handler pointer tables as instructions -- `ld XWA,0x04034241` out of
    the bytes 40 41 42 03 04 -- AND THE BYTE GATE PASSED.  Three independent
    witnesses caught it.  So this round's reach_set() calls reachability.py's
    `_walk_from(..., R.STRONG, proven)`: the weak classes are never queued at all,
    and that artefact cannot be reproduced by construction.

    The two figures for this round's four spans, from
    `python3 notes/reachability.py --targets`:
        STRONG  357 bytes      any  1,026 bytes
    --survey re-derives the STRONG column independently and gets the same 357.
    The 669-byte gap IS that class of error, and this file declines all of it.

★★ BUT A GRADED SEED IS NOT ENOUGH, AND THIS ROUND FOUND THE PROOF
    reachability.py's `walk()` queues every branch target it decodes, not only the
    ones a graded seed named -- so a walk that ENTERS at a strong seed can still
    decode its way into data and queue an address inside it.  That is exactly what
    happened at 0xFA369A: no seed class of any grade names it, yet the STRONG walk
    marks 17 bytes there.  The bytes are

        53 4f 55 4e 44 20 47 52 4f 55 50 20 4e 41 4d 49 4e 47   "SOUND GROUP NAMING"

    -- a UI string.  Framing it would have written `ld XIX,0x4f524720` and the
    byte gate would have passed, for the second round running.  audited_code()
    refuses it, and `--dropped` prints the evidence.

    So a run START that no seed names is the thing to look at, and there are two
    opposite kinds.  Compare 0xF961BD, which no seed names either: the converted
    instruction at 0xF961B8 is five bytes long and ENDS at 0xF961BD, i.e. the
    already-framed routine falls straight through into it, and the 52 bytes run to
    a `jr` at 0xF961EF that lands on the next converted instruction.  A
    fall-through from proven code is evidence; a target queued out of a decode of
    data is not.  --selftest checks both, on every run, in both directions.

★ WHY IT CONVERTS ONLY PART OF A SPAN
    0xFDE70F-0xFE0000 is 6,385 bytes carrying 29 STRONG-reachable ones.  Framing
    the span would buy 29 bytes of coverage for 6,356 bytes of territory, and
    territory is not coverage.  So each span is cut into

        maximal STRONG run -> assembled instructions, labelled at every entry point
        everything else    -> the SAME `.incbin` it already was, narrowed

    and the `.incbin` accounting stays honest: bytes nobody has shown execution
    reaching are still declared unconverted.

★ AND A PRIOR AUDIT STILL OUTRANKS THE WALK IN 0xFA1404-0xFA5400
    audited_code() clips every span inside that region to the CODE_BLOCKS of
    notes/prom_a_fa1404_identify.py, exactly as round 1 did.  A run has to be
    contained WHOLE in a code block to survive.  See audited_code() for why.

⚠ THE RE-DERIVATION MUST NOT READ ITS OWN OUTPUT
    freeze() masks every address in ROUND2_SPANS out of the proven set and merges
    those spans back into the `.incbin` list, so after the splice the walk still
    answers exactly what it answered before it.  Without this the emitter would
    stop reproducing its own output the moment it succeeded.  ROUND 1's freeze
    CANNOT BE REUSED: it hides round 1's own spans, which are now converted and
    are legitimately seeds -- hiding them would hide the very edges that revealed
    this round's work.  This file's ROUND2_SPANS is its own snapshot, taken from
    the tree as round 1 left it.  `--reproduce` is the proof it holds.

⚠ WHAT IT NEVER TOUCHES
    Only `.incbin` ranges are ever spliced, and prom_a/insert_region.py rewrites
    nothing but the `.incbin` arithmetic around the inserted text.  No existing
    comment, header or semantic label can be reached by this program.
    `--untouched` says so out loud, against git HEAD.

NOTHING HERE CAN BREAK THE GATE
    Code comes from prom_a/roundtrip.py's emit_block(), which assembles and
    byte-compares every candidate spelling and then the whole block.  Then
    verify_region() assembles the ENTIRE emitted text -- instructions, labels and
    the narrowed `.incbin` lines together -- with llvm-mc from the repo root and
    compares every byte of [lo,hi) with the ROM.  main() exits non-zero WITHOUT
    PRINTING if it differs.  Run scripts/analysis/assert_byte_identical.py
    afterwards anyway; --splice does not run it.

WHAT ROUND 2 PRODUCED (2026-08-30; every figure here is printed by --selftest,
--reach, --dropped, --layout or --untouched, none of it is typed)

    span                 size   STRONG   framed   left `.incbin`
    0xF96432-0xF97418   4,070      259      259            3,811
    0xF961BD-0xF961F1      52       52       52                0
    0xFDE70F-0xFE0000   6,385       29       26            6,359
    0xFA15CC-0xFA5400  15,924       17        0           15,924
    TOTAL              26,431      357      337           26,094

    7 labels, all `sub_XXXXXX`; 0 `.byte` fall-backs; 0 runs the round-trip could
    not prove.  The 20-byte gap between STRONG and framed is stated, not rounded
    away: 17 bytes the audit calls data (the string "SOUND GROUP NAMING", see
    --dropped) and 3 bytes at the tail of the 0xFDE70F run, where a fresh decode
    of the run stops at 0xFDE729 because the next instruction runs one byte past
    the walk's own run end.

    0xFA15CC's splice adds NO code -- only the header recording why its 17 bytes
    were refused.  The span is byte-for-byte the `.incbin` it already was.

    ★ AND THE SHAPE OF WHAT IS LEFT.  0xFDE70F still holds 6,359 `.incbin` bytes
    with 29 STRONG-reachable ones, i.e. converting the span would buy 29 bytes of
    coverage for 6,356 bytes of territory.  Round 1 refused that trade and so does
    this one; the 26 bytes taken here are the reachable RUN, not the span.

★★ THE GOAL METRIC, MEASURED BY notes/reachability.py --targets EITHER SIDE

        prom_a  STRONG reachable-and-unconverted   357  ->  55
        whole goal (all three images)            1,270  -> 968

    357 - 337 converted = 20 that should be left (17 declined, 3 trimmed).  55 are
    left, so THE SPLICE REVEALED 35 BYTES no walk could see before -- the same
    effect that handed round 1's work to round 2, and for the same reason: the
    converted lines at 0xFDE70F became `branch` seeds.  `--revealed` prints them:

        0xFDE729-0xFDE74C   35   ★ NEW.  Decodes cleanly.  Begins with this
                                 round's own 3 trimmed bytes, so round 3 gets the
                                 trim back as part of a longer run.
        0xFDE75D-0xFDE760    3   ★ NEW.  Decodes cleanly.
        0xFA369A-0xFA36AB   17   ⚠ NOT new and NOT code -- "SOUND GROUP NAMING".
                                 Round 3 must decline it, as this round did.

    ⚠ ROUND 3 CANNOT JUST RE-RUN THIS FILE.  freeze() hides this round's output on
    purpose, so every mode here except `--revealed` is blind to those 38 bytes.  A
    round 3 needs its OWN frozen snapshot, taken from the tree as this round left
    it -- exactly the constraint round 1 put on round 2.

RUN
    python3 notes/gen_prom_a_cover_round2.py --survey     # every prom_a .incbin
                                                          # span, STRONG vs any
    python3 notes/gen_prom_a_cover_round2.py --reach      # the round's run table
    python3 notes/gen_prom_a_cover_round2.py --layout     # per-span segments
    python3 notes/gen_prom_a_cover_round2.py --dropped    # ★ why the declined
                                                          #   runs are declined
    python3 notes/gen_prom_a_cover_round2.py --revealed   # ★ what this round
                                                          #   revealed for round 3
    python3 notes/gen_prom_a_cover_round2.py --emit 0xF96432
    python3 notes/gen_prom_a_cover_round2.py --splice     # all of them
    python3 notes/gen_prom_a_cover_round2.py --selftest
    python3 notes/gen_prom_a_cover_round2.py --reproduce  # the freeze's proof
    python3 notes/gen_prom_a_cover_round2.py --after      # the goal metric now
    python3 notes/gen_prom_a_cover_round2.py --untouched  # 0 prose lines moved
"""
import hashlib
import importlib.util
import json
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "notes"))
from asm_source import image_path  # noqa: E402  (the image, not the master)
ARGV = list(sys.argv)
LLVM_MC = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-mc")
OBJCOPY = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-objcopy")
IMG = os.path.join(ROOT, "original_ROMs", "wsa1_prom_a.ic12")
SRC = image_path(ROOT, "prom_a/wsa1_prom_a.s")
BASE = 0xF80000

# The region a prior wave audited instruction-by-instruction.  Any span inside it
# is clipped to that audit's CODE_BLOCKS; see audited_code().
AUDIT_REGION = (0xFA1404, 0xFA5400)

# ---------------------------------------------------------------------------
# THE ROUND'S SPANS.  Every prom_a `.incbin` that carries a non-zero STRONG count
# on the tree as round 1 left it.  --survey prints the table this was taken from
# and --selftest re-derives every number in it; the emitters refuse to run if one
# has moved.
#
# Taken from `python3 notes/reachability.py --targets` on the tree round 1 left
# (2026-08-30), prom_a rows only:
#
#   span                 size   STRONG   any
#   0xF96432-0xF97418   4,070      259   244   <- revealed by round 1's F96018 work
#   0xF961BD-0xF961F1      52       52    52   <- 100% code
#   0xFDE70F-0xFE0000   6,385       29    29   <- 29 of coverage for 6,356 of territory
#   0xFA15CC-0xFA5400  15,924       17   701   <- ⚠ THE ARTEFACT SPAN: take the 17
#
# Every other prom_a `.incbin` scores STRONG 0 and is NOT in this list, however
# large its `any` count.  0xFA146F-0xFA14C6 (any 87) is the clearest case: it
# opens with the 7-entry jump table notes/prom_a_span_survey.py prints at
# 0xFA146F, and the only thing that "reaches" its arms is that table read as
# immediates.  0xF8C930-0xF8DA00 (any 11) opens with a 9-entry pointer table and
# is otherwise 4,196 bytes of 0x0E padding.  Neither is converted here.
ROUND2_SPANS = [
    (0xF961BD, 0xF961F1),
    (0xF96432, 0xF97418),
    (0xFA15CC, 0xFA5400),
    (0xFDE70F, 0xFE0000),
]

# STRONG-reachable bytes per span, measured on the pre-splice tree.  --selftest
# re-derives every one and build() refuses to emit if one has moved.
EXPECTED_STRONG = {
    0xF961BD: 52,
    0xF96432: 259,
    0xFA15CC: 17,
    0xFDE70F: 29,
}

# What the emitters actually produce.  Residues are stated, never rounded away:
#   TRIMMED  -- a run whose fresh linear decode stops short of its last byte, so
#               two seeds framed that tail differently; the tail goes back into
#               `.incbin` rather than pick a side.
#   AUDIT_DROPPED -- STRONG-reachable bytes the 0xFA1404 audit calls data.
TRIMMED_RUNS = 1
TRIMMED_BYTES = 3
AUDIT_DROPPED_RUNS = 1
AUDIT_DROPPED_BYTES = 17
CONVERTED = 337
# 7 `sub_XXXXXX` labels in all: one per framed run start (5) plus two more at
# addresses inside a run that a strong seed also names.
LABELS = 7


def _load(path, name):
    spec = importlib.util.spec_from_file_location(name, path)
    m = importlib.util.module_from_spec(spec)
    saved = sys.argv
    sys.argv = [name]
    try:
        spec.loader.exec_module(m)
    finally:
        sys.argv = saved
    return m


RT = _load(os.path.join(ROOT, "prom_a", "roundtrip.py"), "wsa1_rt")
R = _load(os.path.join(ROOT, "notes", "reachability.py"), "wsa1_reach")


def rom():
    return open(IMG, "rb").read()


# ------------------------------------------------------------------ freeze
def _in_round(a):
    return any(lo <= a < hi for lo, hi in ROUND2_SPANS)


class _NoStore(dict):
    """A window cache that stores nothing.  reachability.py keeps every decoded
    window in `_WIN` AND every instruction boundary in `_BOUND`; the second makes
    the first redundant and the first costs gigabytes.  Dropping it changes no
    result -- a repeat call is served from the boundary index instead."""

    def __setitem__(self, key, value):
        pass


def lowmem():
    if not isinstance(R._WIN, _NoStore):
        R._WIN = _NoStore()


def freeze():
    """Make the walk answer as it did BEFORE this round spliced anything.

    Two things have to be undone: the converted lines this round adds (they would
    become new `branch` seeds) and the narrowed `.incbin` lines it leaves behind
    (the span must still read as unconverted).

    ⚠ IT HIDES ROUND 2's SPANS ONLY.  Round 1's conversions stay visible, because
    they are what revealed this round's work: 499 bytes of prom_a became reachable
    the moment round 1's directory-slot stubs stopped being `.incbin`.  A freeze
    that also hid those would be measuring a tree that no longer exists."""
    lowmem()
    if getattr(R, "_wsa1_r2_frozen", False):
        return
    raw_sl = R.source_lines
    raw_pi = R.proven_and_incbin

    def source_lines(tag):
        lines = raw_sl(tag)
        if tag != "prom_a":
            return lines
        out = []
        for ln in lines:
            m = R.SRC_LINE.match(ln)
            if m and _in_round(int(m.group(2), 16)):
                continue
            out.append(ln)
        return out

    def proven_and_incbin(tag):
        proven, spans = raw_pi(tag)
        if tag != "prom_a":
            return proven, spans
        keep = [(a, e) for a, e in spans
                if not any(lo <= a and e <= hi for lo, hi in ROUND2_SPANS)]
        return proven, sorted(keep + list(ROUND2_SPANS))

    R.source_lines = source_lines
    R.proven_and_incbin = proven_and_incbin
    R._wsa1_r2_frozen = True


# -------------------------------------------------------- the reachable set
def _fingerprint(strong):
    freeze()
    proven, spans = R.proven_and_incbin("prom_a")
    sd = R.seeds("prom_a", R.CPU1)
    h = hashlib.md5()
    h.update(b"strong" if strong else b"any")
    h.update(hashlib.md5(rom()).hexdigest().encode())
    h.update(repr(sorted(proven)).encode())
    h.update(repr(sorted(spans)).encode())
    for k in sorted(sd):
        h.update((k + repr(sorted(sd[k]))).encode())
    return h.hexdigest()


def _to_runs(seen):
    runs, start, prev = [], None, None
    for a in sorted(seen):
        if start is None:
            start, prev = a, a
        elif a == prev + 1:
            prev = a
        else:
            runs.append((start, prev + 1))
            start, prev = a, a
    if start is not None:
        runs.append((start, prev + 1))
    return runs


_reach = {}


def reach_set(strong=True):
    """The prom_a addresses execution reaches, as sorted (lo,hi) runs.

    `strong=True` queues ONLY reachability.py's STRONG seed classes -- vectors,
    prom_b directory slots and branch/call targets in decoded code -- plus every
    address the tree has already proven to be an instruction.  The WEAK classes
    (bare 32-bit immediates, entries of framed `.long` tables) are never queued,
    which is what keeps this round from repainting pointer tables as code.

    Cached in /tmp under the fingerprint of the walk's inputs, because the walk
    costs minutes.  A stale cache is impossible: any change to the ROM, the proven
    set, the `.incbin` list or the seed sets changes the fingerprint."""
    key = "strong" if strong else "any"
    if key in _reach:
        return _reach[key]
    fp = _fingerprint(strong)
    cache = os.path.join(tempfile.gettempdir(), "wsa1-prom_a-r2-%s-%s.json" % (key, fp[:16]))
    if os.path.exists(cache):
        runs = [tuple(x) for x in json.load(open(cache))]
        _reach[key] = runs
        return runs
    freeze()
    proven, _spans = R.proven_and_incbin("prom_a")
    sd = R.seeds("prom_a", R.CPU1)
    classes = list(R.STRONG) if strong else list(sd)
    seen = R._walk_from("prom_a", R.CPU1, sd, classes, proven)
    runs = _to_runs(seen)
    json.dump(runs, open(cache, "w"))
    _reach[key] = runs
    return runs


def runs_in(lo, hi, strong=True):
    """The maximal reachable runs clipped to [lo,hi)."""
    out = []
    for a, b in reach_set(strong):
        if b <= lo or a >= hi:
            continue
        out.append((max(a, lo), min(b, hi)))
    return out


def audited_code(lo, hi):
    """The parts of a span a PRIOR AUDIT has already shown to be code, or None
    when no audit covers it.

    ★ WHY THIS SURVIVES INTO ROUND 2.  Walking the strong classes removes the
    seed that painted 0xFA1404's pointer tables, but it does not make the audit
    wrong, and the audit is finer-grained than any seed grade: it says which
    BYTES of that region are instructions.  Keeping the clip costs nothing where
    the walk already agrees and refuses the one thing round 1 got wrong.  Its
    second witness is still in the tree's own converted code: at 0xFA1041 prom_a
    does `add XBC,0x00fa1dc8 / ld A,(XBC)` -- it reads 0xFA1DC8 as a BYTE TABLE,
    where a walk had framed a 28-byte routine.

    notes/prom_a_fa1404_identify.py settled this region in a previous wave and
    publishes the answer as CODE_BLOCKS.  It is imported, never retyped.

    ⚠ NO SUCH AUDIT COVERS ANY OTHER PART OF prom_a, and none is invented here."""
    if not (AUDIT_REGION[0] <= lo and hi <= AUDIT_REGION[1]):
        return None
    M = _load(os.path.join(ROOT, "notes", "prom_a_fa1404_identify.py"),
              "wsa1_fa1404_identify")
    return [(a, e) for a, e, *_ in [tuple(b) for b in M.CODE_BLOCKS]]


def code_runs(lo, hi):
    """The runs this file will actually frame: runs_in(), clipped to whatever a
    prior audit says is code, plus the runs the clip threw away.

    ⚠ A run is kept only when the audit's code blocks contain it WHOLE.  A partial
    overlap would hand emit_span() a start address that is an audit boundary
    rather than an instruction boundary, and a decode from the middle of an
    instruction can still round-trip byte-identically while being nonsense."""
    rs = runs_in(lo, hi)
    blocks = audited_code(lo, hi)
    if blocks is None:
        return rs, []
    keep, drop = [], []
    for a, b in rs:
        if any(x <= a and b <= y for x, y in blocks):
            keep.append((a, b))
        else:
            drop.append((a, b, b - a))
    return sorted(keep), drop


def survey():
    """Every prom_a `.incbin` span, with its STRONG and its `any` reachable count.
    This is the table ROUND2_SPANS was taken from."""
    lowmem()
    _p, spans = R.proven_and_incbin("prom_a")
    strong = set()
    for a, b in reach_set(True):
        strong.update(range(a, b))
    anyset = set()
    for a, b in reach_set(False):
        anyset.update(range(a, b))
    rows = []
    for lo, hi in sorted(spans):
        s = sum(1 for x in range(lo, hi) if x in strong)
        n = sum(1 for x in range(lo, hi) if x in anyset)
        if s or n:
            rows.append((s, n, lo, hi, hi - lo))
    rows.sort(reverse=True)
    return rows


def reach_table():
    rows = []
    for lo, hi in sorted(ROUND2_SPANS):
        rs = runs_in(lo, hi)
        rows.append((lo, hi, sum(b - a for a, b in rs), len(rs)))
    return rows


# ------------------------------------------------------------ entry points
_ev = {}


def entry_evidence(strong_only=True):
    """addr -> the classes of entry point that name it.  This is the ONLY thing a
    label comment is allowed to say this round: which kind of edge arrives here,
    never what the routine does."""
    key = "s" if strong_only else "a"
    if key in _ev:
        return _ev[key]
    freeze()
    sd = R.seeds("prom_a", R.CPU1)
    names = {"vector": "CPU vector table", "directory": "prom_b routine directory",
             "branch": "branch/call in converted code", "immediate": "32-bit immediate",
             "pointer_table": "framed pointer table"}
    ev = {}
    for k, addrs in sd.items():
        if strong_only and k not in R.STRONG:
            continue
        for a in addrs:
            if BASE <= a < BASE + 0x80000:
                ev.setdefault(a, []).append(names.get(k, k))
    _ev[key] = ev
    return ev


# ------------------------------------------------- is a run start EVIDENCE?
_ft = {}


def fallthrough_starts():
    """Every address at which an ALREADY-CONVERTED prom_a instruction ends.

    ★ WHY IT IS EVIDENCE.  reachability.py's walk queues branch targets it finds
    while decoding, so a run start need not be a seed of any grade -- and this
    round found both kinds of non-seed start.  0xF961BD is the byte after the
    5-byte instruction the tree already frames at 0xF961B8: the converted routine
    falls straight through into it, which is the strongest evidence there is short
    of a directory slot.  0xFA369A is not the end of any converted instruction; it
    is an address a decode of DATA queued, and the data is the string
    "SOUND GROUP NAMING".

    Read from the FROZEN source, so this round's own output cannot vouch for
    itself.  Lengths come from the raw-byte comment each converted line carries."""
    if _ft:
        return _ft["s"]
    freeze()
    out = set()
    for ln in R.source_lines("prom_a"):
        m = R.SRC_LINE.match(ln)
        if not m:
            continue
        a = int(m.group(2), 16)
        n = len(re.findall(r'\b[0-9a-f]{2}\b', m.group(3)))
        if n:
            out.add(a + n)
    _ft["s"] = out
    return out


def start_evidence(a):
    """Why this file believes a run start is an entry point: the seed classes that
    name it, plus 'fall-through from converted code' when one applies.  Empty
    means NOTHING vouches for it -- which is the 0xFA369A case."""
    freeze()
    sd = R.seeds("prom_a", R.CPU1)
    why = [k for k in R.STRONG if a in sd.get(k, ())]
    if a in fallthrough_starts():
        why.append("fall-through from converted code")
    return why


def dropped_evidence():
    """[(lo, hi, n, why, ascii)] for every run the audit mask holds back.  This is
    the committed evidence behind the decision to decline them."""
    d = rom()
    out = []
    for lo, hi in sorted(ROUND2_SPANS):
        for a, b, n in code_runs(lo, hi)[1]:
            bs = d[a - BASE:b - BASE]
            txt = "".join(chr(c) if 32 <= c < 127 else "." for c in bs)
            out.append((a, b, n, start_evidence(a), txt))
    return out


# ---------------------------------------------------------------- emission
def incbin_line(lo, hi):
    return ('\t.incbin "original_ROMs/wsa1_prom_a.ic12", 0x%06X, 0x%06X'
            % (lo - BASE, hi - lo))


def existing_labels():
    return set(re.findall(r'^([A-Za-z_.$][\w.$]*):', open(SRC).read(), re.M))


def emit_span(lo, hi):
    """(lines, stats).  STRONG-reachable runs become instructions; everything else
    stays the `.incbin` it already was."""
    have = existing_labels()
    ev = entry_evidence()
    lines = []
    st = {"runs": 0, "code_bytes": 0, "incbin_bytes": 0, "labels": 0,
          "refused_runs": 0, "refused_bytes": 0, "byte_fallbacks": 0,
          "trimmed_runs": 0, "trimmed_bytes": 0,
          "audit_refused_runs": 0, "audit_refused_bytes": 0}
    keep, dropped = code_runs(lo, hi)
    st["audit_refused_runs"] = len(dropped)
    st["audit_refused_bytes"] = sum(n for _a, _b, n in dropped)
    cursor = lo
    for a, b in keep:
        block, ok, cs = RT.emit_block(a, b)
        covered = a
        for _t, addr, bs, _w in block:
            if addr is not None:
                covered = max(covered, addr + len(bs))
        if not ok or covered <= a:
            st["refused_runs"] += 1
            st["refused_bytes"] += b - a
            continue
        if covered != b:
            st["trimmed_runs"] += 1
            st["trimmed_bytes"] += b - covered
        if cursor < a:
            lines.append(incbin_line(cursor, a))
            st["incbin_bytes"] += a - cursor
        st["runs"] += 1
        st["byte_fallbacks"] += cs.get("byte", 0)
        for text, addr, bs, why in block:
            if addr is None:
                lines.append(text)
                continue
            if addr == a or addr in ev:
                name = "sub_%06X" % addr
                if name not in have:
                    why_ev = ev.get(addr) or ["reachable-run entry"]
                    lines.append("%s:   ; entry: %s" % (name, ", ".join(sorted(set(why_ev)))))
                    have.add(name)
                    st["labels"] += 1
            raw = " ".join("%02x" % x for x in bs)
            lines.append("\t%-52s ; %06X  %s" % (text.lstrip("\t"), addr, raw))
        st["code_bytes"] += covered - a
        cursor = covered
    if cursor < hi:
        lines.append(incbin_line(cursor, hi))
        st["incbin_bytes"] += hi - cursor
    head = ["; ==== 0x%06X-0x%06X -- STRONG-REACHABLE CODE ONLY, emitted by "
            "notes/%s ====" % (lo, hi, os.path.basename(__file__)),
            "; %d run(s), %d bytes framed as code.  %d bytes that nothing "
            "STRONGLY reaches stay" % (st["runs"], st["code_bytes"], st["incbin_bytes"]),
            "; `.incbin` -- this round converts REACHABLE CODE, not territory.",
            "; Boundaries: notes/reachability.py's walk over its STRONG seed "
            "classes only (CPU",
            "; vectors, prom_b routine-directory slots, branches in decoded "
            "code), frozen against",
            "; this file's own output.  A bare 32-bit immediate is NOT a seed "
            "here: round 1 proved",
            "; it paints pointer tables as instructions and passes the byte gate "
            "doing it.",
            "; Labels are sub_XXXXXX by design: this round is COVERAGE, naming "
            "is a later goal.",
            "; This text was assembled and byte-compared with the ROM before "
            "printing."]
    if st["audit_refused_bytes"]:
        note = [
            "; ⚠ A FURTHER %d byte(s) in %d run(s) ARE marked STRONG-reachable "
            "and are left" % (st["audit_refused_bytes"], st["audit_refused_runs"]),
            "; `.incbin` anyway: they fall outside the CODE_BLOCKS of "
            "notes/prom_a_fa1404_identify.py,",
            "; which identified this region's handler pointer tables, parameter "
            "descriptors and text.",
            "; NOTHING vouches for their start addresses -- no seed of any grade "
            "names them, and no",
            "; converted instruction falls through into them; reachability.py's "
            "walk queued them",
            "; while DECODING data.  `--dropped` prints this list:",
        ]
        d2 = rom()
        for a, b, cnt in dropped:
            bs = d2[a - BASE:b - BASE]
            txt = "".join(chr(c) if 32 <= c < 127 else "." for c in bs)
            note.append(";     0x%06X-0x%06X  %4d bytes, as text: %r" % (a, b, cnt, txt))
        note.append("; Framing that as instructions passes the byte gate and is "
                    "still wrong.")
        head[7:7] = note
    return head + lines, st


def verify_region(lines, lo, hi):
    """Assemble the WHOLE emitted region from the repo root (so `.incbin`
    resolves) and compare all of [lo,hi) with the ROM."""
    src = RT.macro_prelude() + "\n\t.text\n" + "\n".join(lines) + "\n"
    d = tempfile.mkdtemp()
    a_s, a_o, a_b = d + "/r.s", d + "/r.o", d + "/r.bin"
    open(a_s, "w").write(src)
    r = subprocess.run([LLVM_MC, "--triple=tlcs900", "-filetype=obj",
                        "-I", ROOT, "-I", os.path.join(ROOT, "prom_a"),
                        "-o", a_o, a_s], capture_output=True, text=True, cwd=ROOT)
    if r.returncode != 0:
        return None, r.stderr[-2000:]
    r = subprocess.run([OBJCOPY, "-O", "binary", "--only-section=.text", a_o, a_b],
                       capture_output=True, text=True, cwd=ROOT)
    if r.returncode != 0:
        return None, r.stderr[-2000:]
    got = open(a_b, "rb").read()
    want = rom()[lo - BASE:hi - BASE]
    return (got == want), ("len %d vs %d" % (len(got), len(want)) if got != want else "")


def build(lo, hi):
    """Emit and self-prove one span, or die without printing."""
    for k, v in EXPECTED_STRONG.items():
        khi = dict(ROUND2_SPANS)[k]
        got = sum(b - a for a, b in runs_in(k, khi))
        if got != v:
            sys.exit("REFUSING TO EMIT: 0x%06X now has %d STRONG-reachable bytes, "
                     "audited at %d.  The walk moved; re-audit before emitting."
                     % (k, got, v))
    lines, st = emit_span(lo, hi)
    ok, why = verify_region(lines, lo, hi)
    if not ok:
        sys.exit("REFUSING TO PRINT: emitted text for 0x%06X-0x%06X does not rebuild "
                 "the span (%s)" % (lo, hi, why))
    return lines, st


def splice(lo, hi):
    lines, st = build(lo, hi)
    tmp = tempfile.mktemp(suffix=".s")
    open(tmp, "w").write("\n".join(lines) + "\n")
    r = subprocess.run([sys.executable, os.path.join(ROOT, "prom_a", "insert_region.py"),
                        hex(lo), hex(hi), tmp], capture_output=True, text=True, cwd=ROOT)
    os.unlink(tmp)
    if r.returncode != 0:
        sys.exit("splice failed for 0x%06X: %s%s" % (lo, r.stdout, r.stderr))
    print("%s  -> %d code bytes in %d runs, %d labels, %d bytes left .incbin"
          % (r.stdout.strip(), st["code_bytes"], st["runs"], st["labels"],
             st["incbin_bytes"]))
    return st


# ------------------------------------------------ the goal metric, after
def after():
    """prom_a's reachable-and-unconverted count as notes/reachability.py measures
    it, WITHOUT the freeze -- i.e. the real state of the tree right now."""
    lowmem()
    r = R.analyse("prom_a", R.CPU1)
    rows = []
    for lo, hi in sorted(r["spans"]):
        s = r["per_span_strong"].get((lo, hi), 0)
        n = r["per_span"].get((lo, hi), 0)
        if n or s:
            rows.append((lo, hi, hi - lo, s, n))
    return r, rows


# --------------------------------- what THIS round revealed, for the next one
def revealed():
    """The STRONG-reachable runs that exist NOW and did not exist before this
    round -- i.e. the ones this round's own converted lines act as seeds for.

    ★ WHY IT CANNOT BE CONVERTED HERE.  freeze() hides this round's output on
    purpose, so the walk that chose ROUND2_SPANS answers the same question
    forever and --reproduce keeps passing.  Anything the splice revealed is
    therefore invisible to every mode of this file except this one, which runs
    UNFROZEN.  Round 1 handed its 499 revealed bytes to round 2 the same way;
    this is round 3's work list, and it needs its own frozen snapshot.

    Reported as (lo, hi, bytes, decodes_cleanly) per run, where decodes_cleanly
    means a fresh unidasm from the run's first byte lands exactly on its last."""
    if getattr(R, "_wsa1_r2_frozen", False):
        sys.exit("revealed() must run in a process that has NEVER frozen; "
                 "run it as `--revealed` on its own.")
    lowmem()
    proven, spans = R.proven_and_incbin("prom_a")
    sd = R.seeds("prom_a", R.CPU1)
    seen = R._walk_from("prom_a", R.CPU1, sd, list(R.STRONG), proven)
    runs = _to_runs(seen)
    out = []
    for lo, hi in sorted(spans):
        for a, b in runs:
            if b <= lo or a >= hi:
                continue
            a, b = max(a, lo), min(b, hi)
            rows = RT.unidasm_range(a, b)
            end = rows[-1][0] + len(rows[-1][1]) if rows else a
            out.append((lo, hi, a, b, b - a, end == b))
    return out


# ------------------------------------------ proof that a re-run reproduces
def reproduce(spans=None):
    """Re-emit every span from scratch and check the text matches what is in the
    .s, line for line.

    ★ THIS IS THE FREEZE'S PROOF.  An emitter that reads its own output stops
    reproducing it the moment it succeeds: its converted lines become new seeds,
    the reachable set grows and the run table moves.

    ⚠ Label LINES are excluded from BOTH sides: the tree now defines every
    `sub_XXXXXX` this round added and emit_span() will not define a name twice, so
    a re-run legitimately emits fewer of them.  What freeze() is responsible for
    is the run table and the framing, and that is what the body lines say."""
    src = open(SRC).read().split("\n")
    out = []
    for lo, hi in (spans or sorted(ROUND2_SPANS)):
        lines, _st = emit_span(lo, hi)
        body = [l for l in lines if l.startswith("\t") or l.startswith(".L")]
        head = "; ==== 0x%06X-0x%06X -- STRONG-REACHABLE CODE ONLY" % (lo, hi)
        i = next((k for k, l in enumerate(src) if l.startswith(head)), None)
        if i is None:
            out.append((lo, hi, False, len(body), "no spliced region in the .s"))
            continue
        got = []
        for l in src[i:]:
            if l.startswith("\t") or l.startswith(".L"):
                got.append(l)
                if len(got) == len(body):
                    break
        out.append((lo, hi, got == body, len(body),
                    "" if got == body else "%d of %d lines differ"
                    % (sum(1 for a, b in zip(got, body) if a != b), len(body))))
    return out


# ------------------------------------------- proof that nothing else moved
def untouched(rev="HEAD"):
    """Every line of prom_a/wsa1_prom_a.s that was NOT an `.incbin` at `rev` must
    still be present, in the same order, in the file on disk.

    THE POINT: twelve waves of naming and header work sit in this file and this
    round is not allowed to disturb a byte of it."""
    old = subprocess.run(["git", "show", "%s:prom_a/wsa1_prom_a.s" % rev],
                         capture_output=True, text=True, cwd=ROOT).stdout.split("\n")
    new = open(SRC).read().split("\n")
    keep = [l for l in old if not R.INCBIN.match(l)]
    ni = iter(new)
    lost = []
    for l in keep:
        for cand in ni:
            if cand == l:
                break
        else:
            lost.append(l)
    return len(keep), lost


# ----------------------------------------------------------------- selftest
def check(msg, cond, extra=""):
    print(("  ok   " if cond else "  FAIL ") + msg + (("   " + extra) if extra else ""))
    return 0 if cond else 1


def selftest():
    bad = n = 0
    tbl = reach_table()
    for lo, hi, cnt, nr in tbl:
        n += 1
        bad += check("0x%06X-0x%06X: %d STRONG bytes in %d run(s), audit says %d"
                     % (lo, hi, cnt, nr, EXPECTED_STRONG[lo]), cnt == EXPECTED_STRONG[lo])
    tot = sum(c for _l, _h, c, _r in tbl)
    n += 1
    bad += check("the round's %d spans hold %d STRONG-reachable bytes"
                 % (len(ROUND2_SPANS), sum(EXPECTED_STRONG.values())),
                 tot == sum(EXPECTED_STRONG.values()), str(tot))
    # EVERY run, not a sample: does a fresh linear decode from the run's first
    # byte land exactly on its last?
    off = offbytes = checked = 0
    for lo, hi in sorted(ROUND2_SPANS):
        for a, b in runs_in(lo, hi):
            rows = RT.unidasm_range(a, b)
            checked += 1
            end = rows[-1][0] + len(rows[-1][1]) if rows else a
            if end != b:
                off += 1
                offbytes += b - end
    n += 2
    bad += check("all %d runs re-decode cleanly except the %d the audit records"
                 % (checked, TRIMMED_RUNS), off == TRIMMED_RUNS, "%d off" % off)
    bad += check("the trimmed tails are the %d bytes the audit records" % TRIMMED_BYTES,
                 offbytes == TRIMMED_BYTES, "%d bytes" % offbytes)
    # ★★ THE CHECK ROUND 1's MISTAKE EARNED, restated for a graded walk: not one
    # emitted run may start at an address a WEAK seed names and nothing else.
    # ⚠ "STRONG seed" alone is TOO STRONG a bar and the first draft of this check
    # failed on honest code: 0xF961BD is named by no seed at all, because it is
    # simply the byte after the instruction the tree already frames at 0xF961B8.
    # The bar is therefore STRONG SEED OR FALL-THROUGH, counted both ways so the
    # split stays visible.
    sd = R.seeds("prom_a", R.CPU1)
    strong_addrs = set()
    for k in R.STRONG:
        strong_addrs |= set(sd.get(k, ()))
    starts = [a for lo, hi in ROUND2_SPANS for a, _b in code_runs(lo, hi)[0]]
    seeded = [a for a in starts if a in strong_addrs]
    fell = [a for a in starts if a not in strong_addrs and a in fallthrough_starts()]
    weak_only = [a for a in starts if a not in strong_addrs and a not in fallthrough_starts()]
    n += 1
    bad += check("of %d framed run starts, %d are STRONG seeds and %d are "
                 "fall-throughs from converted code -- and none is neither"
                 % (len(starts), len(seeded), len(fell)),
                 not weak_only and len(seeded) + len(fell) == len(starts),
                 "%d are neither" % len(weak_only))
    # ★★ AND THE CHECK THIS ROUND EARNED.  A graded seed is not enough: walk()
    # queues branch targets it finds while DECODING, so a strong walk can still
    # reach into data.  Every run this file frames must therefore have positive
    # evidence for its start -- a strong seed, or a fall-through from an
    # instruction the tree already framed -- and every run it declines must have
    # NONE.  0xFA369A has none, and it is the string "SOUND GROUP NAMING".
    unvouched = [a for lo, hi in ROUND2_SPANS for a, _b in code_runs(lo, hi)[0]
                 if not start_evidence(a)]
    n += 1
    bad += check("every framed run start has positive evidence (seed or "
                 "fall-through)", not unvouched,
                 "%d have none" % len(unvouched))
    vouched_drop = [a for a, _b, _n, why, _t in dropped_evidence() if why]
    n += 1
    bad += check("no run the audit mask declines has any such evidence",
                 not vouched_drop, "%d do" % len(vouched_drop))
    dropped = sum(x for lo, hi in ROUND2_SPANS for _a, _b, x in code_runs(lo, hi)[1])
    n += 1
    bad += check("the audit mask holds back %d STRONG bytes it calls data"
                 % AUDIT_DROPPED_BYTES, dropped == AUDIT_DROPPED_BYTES, "%d" % dropped)
    n += 1
    bad += check("converted = strong - audit-dropped - trimmed = %d" % CONVERTED,
                 tot - dropped - TRIMMED_BYTES == CONVERTED,
                 "%d" % (tot - dropped - TRIMMED_BYTES))
    freeze()
    proven, spans = R.proven_and_incbin("prom_a")
    n += 2
    bad += check("freeze: no address in ROUND2_SPANS is counted as proven",
                 not any(_in_round(a) for a in proven))
    bad += check("freeze: every span of the round is back in the .incbin list",
                 all(s in spans for s in ROUND2_SPANS))
    # ★ THE GUARD ITSELF IS TESTED, not just present.
    k0 = sorted(EXPECTED_STRONG)[0]
    saved = EXPECTED_STRONG[k0]
    EXPECTED_STRONG[k0] = saved - 1
    try:
        build(*sorted(ROUND2_SPANS)[-1])
        fired = False
    except SystemExit:
        fired = True
    finally:
        EXPECTED_STRONG[k0] = saved
    n += 1
    bad += check("build() refuses to emit when an audited STRONG total moves", fired)
    # no symbol defined twice -- what llvm-mc actually rejects
    defs = re.findall(r'^([A-Za-z_.$][\w.$]*):', open(SRC).read(), re.M)
    dup = sorted(set(x for x in defs if defs.count(x) > 1))
    n += 1
    bad += check("no symbol in prom_a/wsa1_prom_a.s is defined twice", not dup,
                 "%d duplicated" % len(dup))
    # every span of the round keeps exactly the bytes no run covers as .incbin
    src = open(SRC).read()
    still = 0
    for lo, hi in ROUND2_SPANS:
        for ln in src.split("\n"):
            mm = R.INCBIN.match(ln)
            if mm:
                a = BASE + int(mm.group(2), 16)
                e = a + int(mm.group(3), 16)
                if lo <= a and e <= hi:
                    still += e - a
    want = sum(hi - lo for lo, hi in ROUND2_SPANS) - CONVERTED
    n += 1
    bad += check("the round's spans keep exactly the %d bytes no run covers as "
                 "`.incbin`" % want, still == want, "%d" % still)
    # the label count, so a re-run that silently stopped naming entry points is
    # caught.  ⚠ counted from the SPLICED file, not from a re-emission: emit_span()
    # will not define a name the tree already has, so a re-run emits none of them.
    text = open(SRC).read()
    starts2 = [a for lo, hi in ROUND2_SPANS for a, _b in code_runs(lo, hi)[0]]
    lbl = sum(1 for a in starts2 if ("sub_%06X:" % a) in text)
    n += 1
    bad += check("all %d framed run starts carry a sub_XXXXXX label in the .s, and "
                 "the round wrote %d labels in total" % (len(starts2), LABELS),
                 lbl == len(starts2) == 5 and text.count("sub_") >= LABELS,
                 "%d labelled" % lbl)
    print("\n%d checks, %d failures" % (n, bad))
    return 1 if bad else 0


def main():
    if "--survey" in ARGV:
        print("%-21s %8s %8s %8s" % ("span", "size", "STRONG", "any"))
        ts = ta = 0
        for s, a, lo, hi, size in survey():
            ts += s
            ta += a
            print("0x%06X-0x%06X %8s %8s %8s%s"
                  % (lo, hi, format(size, ","), format(s, ","), format(a, ","),
                     "   <- audit region" if AUDIT_REGION[0] <= lo and hi <= AUDIT_REGION[1] else ""))
        print("\nTOTAL STRONG %s, any %s" % (format(ts, ","), format(ta, ",")))
        return 0
    if "--after" in ARGV:
        r, rows = after()
        print("prom_a reached %s bytes | still .incbin %s | REACHABLE AND UNCONVERTED "
              "strong %s / any %s"
              % (format(r["reached"], ","), format(r["incbin"], ","),
                 format(r["reach_strong"], ","), format(r["reach_in_incbin"], ",")))
        for lo, hi, size, s, nn in rows:
            print("   0x%06X-0x%06X %8s bytes, STRONG %5s, any %5s"
                  % (lo, hi, format(size, ","), format(s, ","), format(nn, ",")))
        return 0
    if "--reproduce" in ARGV:
        bad = 0
        for lo, hi, ok, cnt, why in reproduce():
            print("  %s 0x%06X-0x%06X  %d body lines re-emitted %s"
                  % ("ok  " if ok else "FAIL", lo, hi, cnt,
                     "exactly as spliced" if ok else "DIFFERENTLY -- " + why))
            bad += 0 if ok else 1
        print("\n%d spans, %d differ" % (len(ROUND2_SPANS), bad))
        return 1 if bad else 0
    if "--untouched" in ARGV:
        cnt, lost = untouched()
        print("%d non-.incbin lines existed at HEAD; %d of them were removed or "
              "rewritten by this round." % (cnt, len(lost)))
        for l in lost[:20]:
            print("   LOST: %r" % l)
        return 1 if lost else 0
    if "--selftest" in ARGV:
        return selftest()
    if "--reach" in ARGV:
        print("%-21s %8s %10s %6s" % ("span", "size", "STRONG", "runs"))
        for lo, hi, cnt, nr in reach_table():
            print("0x%06X-0x%06X %8s %10s %6d"
                  % (lo, hi, format(hi - lo, ","), format(cnt, ","), nr))
        print("\nTOTAL STRONG-reachable in this round's spans: %s bytes"
              % format(sum(c for _l, _h, c, _r in reach_table()), ","))
        return 0
    if "--revealed" in ARGV:
        rows = revealed()
        print("STRONG-reachable runs still `.incbin` in prom_a, on the UNFROZEN "
              "tree -- round 3's work list:")
        print("%-21s %-21s %7s  %s" % ("span", "run", "bytes", "fresh decode lands on the run end?"))
        for lo, hi, a, b, cnt, clean in rows:
            print("0x%06X-0x%06X 0x%06X-0x%06X %7d  %s"
                  % (lo, hi, a, b, cnt, "yes" if clean else "NO -- the walk and a "
                     "fresh decode disagree about the tail"))
        print("\nTOTAL %d bytes in %d run(s)" % (sum(r[4] for r in rows), len(rows)))
        return 0
    if "--dropped" in ARGV:
        rows = dropped_evidence()
        if not rows:
            print("no run is held back by the audit mask.")
        for a, b, cnt, why, txt in rows:
            print("0x%06X-0x%06X  %4d bytes  evidence for the start: %s"
                  % (a, b, cnt, ", ".join(why) if why else "NONE"))
            print("    as text: %r" % txt)
        return 0
    if "--layout" in ARGV:
        for lo, hi in sorted(ROUND2_SPANS):
            keep, drop = code_runs(lo, hi)
            print("; ---- 0x%06X-0x%06X ----" % (lo, hi))
            for a, b in keep:
                print("   CODE    0x%06X-0x%06X  %6d" % (a, b, b - a))
            for a, b, cnt in drop:
                print("   DROPPED 0x%06X-0x%06X  %6d   STRONG-reachable, but a "
                      "prior audit calls it data" % (a, b, cnt))
        return 0
    if "--emit" in ARGV:
        want = int(ARGV[ARGV.index("--emit") + 1], 16)
        lo, hi = [s for s in ROUND2_SPANS if s[0] == want][0]
        lines, _st = build(lo, hi)
        print("\n".join(lines))
        return 0
    if "--splice" in ARGV:
        for lo, hi in sorted(ROUND2_SPANS):
            splice(lo, hi)
        return 0
    print(__doc__)
    return 0


if __name__ == "__main__":
    sys.exit(main())
