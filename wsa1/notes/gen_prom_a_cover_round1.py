#!/usr/bin/env python3
"""Convert the REACHABLE code inside prom_a's remaining `.incbin` spans, and
leave everything else exactly where it is.

QUESTION IT ANSWERS
    "Which bytes of a still-`.incbin` prom_a span does execution actually reach,
     what is the assembly text for those bytes, and what has to stay `.incbin`
     because nothing reaches it?"

    This is the emitter for the WSA1R COVERAGE GOAL, round 1, lane COVERAGE-A.
    It is deliberately NOT a naming pass: every label it writes is `sub_XXXXXX`
    plus the class of entry point that justifies it.  Semantics are a later goal.

★ WHY IT CONVERTS ONLY PART OF A SPAN
    notes/reachability.py measures the goal, and it measures REACHABLE bytes
    still inside `.incbin`, not `.incbin` bytes.  prom_a 0xF96018 is 12,297 bytes
    of which 7,097 are reachable; converting the other 5,200 would add territory
    and ZERO coverage.  So each span is cut into

        reachable run  -> assembled instructions, labelled at every entry point
        everything else -> the SAME `.incbin` it already was, narrowed

    and the `.incbin` accounting stays honest: bytes nobody has shown execution
    reaching are still declared unconverted.

WHERE THE BOUNDARIES COME FROM
    notes/reachability.py's own walk, re-run on EVERY invocation -- the CPU
    vector table, prom_b's 1,910-slot routine directory, the framed pointer
    tables, branch targets and 32-bit immediates in already-converted code, and
    linear descent from each.  A maximal run of reachable bytes begins at an
    instruction start and ends at an instruction end BY CONSTRUCTION, because the
    walk only ever marks whole instructions.  `emit_span()` then re-decodes each
    run from its first byte; where that decode does not land exactly on the run's
    last byte -- which means two seeds framed the tail differently -- the tail is
    trimmed back into `.incbin` rather than framed on one seed's word.  It
    happened once, and cost 2 bytes.

★ AND THE WALK OVER-APPROXIMATES, SO A PRIOR AUDIT OUTRANKS IT
    Its `immediate` seed class treats every 32-bit immediate landing in an image
    as an entry point, and most such immediates are POINTERS -- as likely to name
    a table as a routine.  In 0xFA1404 that produced 18 "reachable runs" that are
    really the descriptor bytes between handler pointer tables, and framing them
    would have written `ld XWA,0x04034241` for the byte sequence 40 41 42 03 04.
    audited_code() holds them back, on the authority of a previous wave's
    notes/prom_a_fa1404_identify.py.  A byte gate cannot tell the difference; the
    difference is still real.

⚠ THE RE-DERIVATION MUST NOT READ ITS OWN OUTPUT
    freeze() masks every address in ROUND_SPANS out of the proven set and merges
    those spans back into the `.incbin` list, so after the splice the walk still
    answers exactly what it answered before it.  Without this the emitter would
    stop reproducing its own output the moment it succeeded: its own converted
    lines become new seeds, the reachable set grows, and the run table moves.
    ROUND_SPANS therefore lists ALL FIVE spans this round touches, not just the
    one being emitted -- freezing only its own span would still let a sibling
    span's output move it.  `--selftest` proves the invariance.

⚠ WHAT IT NEVER TOUCHES
    Only `.incbin` ranges are ever spliced, and prom_a/insert_region.py rewrites
    nothing but the `.incbin` arithmetic around the inserted text.  No existing
    comment, header or semantic label can be reached by this program.

NOTHING HERE CAN BREAK THE GATE
    Code comes from prom_a/roundtrip.py's emit_block(), which assembles and
    byte-compares every candidate spelling and then the whole block.  Then
    verify_region() assembles the ENTIRE emitted text -- instructions, labels and
    the narrowed `.incbin` lines together -- with llvm-mc from the repo root and
    compares every byte of [lo,hi) with the ROM.  main() exits non-zero WITHOUT
    PRINTING if it differs.  Run the byte gate afterwards anyway; --splice does
    not run it.

WHAT ROUND 1 PRODUCED (2026-08-30; every figure here is printed by --selftest,
--reach or --untouched, none of it is typed)

    span                 size   reachable   framed   left `.incbin`
    0xF96018-0xF99021  12,297      7,097    7,095            5,202   (its own file)
    0xF8C000-0xF8DA00   6,656      1,244    1,244            5,412
    0xF85B0D-0xF85C89     380        373      373                7
    0xF85D1C-0xF85E8A     366        366      366                0
    0xFA1404-0xFA5400  16,380      1,060      359           16,021
    TOTAL              36,079     10,140    9,437           26,642

    60 labels, all `sub_XXXXXX`; 29 `.byte` fall-backs inside otherwise framed
    code; 0 runs the round-trip could not prove.  The 703-byte gap between
    reachable and framed is stated, not rounded away: 701 bytes an audit calls
    data (see audited_code()) and 2 bytes at the tail of one run whose fresh
    decode disagrees with the walk.

    0xFDE70F-0xFE0000 was NOT converted.  It is 6,385 bytes carrying 29
    reachable, and converting it would buy 29 bytes of coverage for 6,356 bytes
    of territory.  That trade is the thing this goal exists to refuse.

★★ AND THE SPLICE REVEALED 499 MORE REACHABLE BYTES -- THE WORK LIST FOR ROUND 2
    `--after` re-runs notes/reachability.py's walk on the spliced tree with NO
    freeze, i.e. it lets this round's own converted lines act as seeds.  prom_a
    moves from

        reached 361,094 | .incbin 56,125 | REACHABLE AND UNCONVERTED 10,169
    to  reached 361,593 | .incbin 46,688 | REACHABLE AND UNCONVERTED  1,231

    -- `.incbin` down by exactly the 9,437 framed, and 499 bytes of NEW territory
    reached that no walk could see before, because the edges that lead to them
    were themselves inside an `.incbin`.  What is left in prom_a, and why:

        0xFA15CC-0xFA5400   701   the runs audited_code() holds back as data
        0xFDE70F-0xFE0000    29   deliberately not converted, see above
        --- newly revealed, and round 2's work list: ----------------------
        0xF96432-0xF97418   259   inside the F96018 module's largest gap
        0xFA146F-0xFA14C6    87   ★ the 7-entry jump table at 0xFA146F (28 B)
                                  PLUS CODE_HEAD_B at 0xFA148B (59 B) -- the
                                  arms of the table this round converted the
                                  dispatcher for.  The 28 table bytes are the
                                  `immediate` artefact again; the 59 are real.
        0xF961BD-0xF961F1    52   includes this round's 2 trimmed bytes
        0xF8C05B-0xF8C071    17   ) the bodies between the F8C000 module's
        0xF8C086-0xF8C095    15   ) directory-slot stubs, reached now that the
        0xF8C0A4-0xF8C0B3    15   ) stubs themselves are framed
        0xF8C0C1-0xF8C0D0    15   )
        0xF8C2B2-0xF8C2EC    15   )
        0xF8C930-0xF8DA00    11   ⚠ starts with a 9-entry pointer table
        0xF8C046-0xF8C04E     8
        0xF96151-0xF96172     6
        0xF8C428-0xF8C42A     1

    ⚠ ROUND 2 CANNOT JUST RE-RUN THIS FILE.  freeze() deliberately hides those
    edges so this round reproduces its own output; a round 2 needs its OWN frozen
    snapshot, taken here.  And it needs the same scepticism: 0xFA146F is a table,
    not a routine, and 0xF8C930 begins with one.

RUN
    python3 notes/gen_prom_a_cover_round1.py --reach     # the reachable-run table
    python3 notes/gen_prom_a_cover_round1.py --layout    # per-span segment table
    python3 notes/gen_prom_a_cover_round1.py --emit 0xF85B0D      # one span
    python3 notes/gen_prom_a_cover_round1.py --splice    # its own spans, spliced
    python3 notes/gen_prom_a_cover_round1.py --selftest  # the checks
    python3 notes/gen_prom_a_cover_round1.py --reproduce # a re-run emits the
                                                        # same text (the freeze)
    python3 notes/gen_prom_a_cover_round1.py --after     # the goal metric now,
                                                        # unfrozen
    python3 notes/gen_prom_a_cover_round1.py --untouched # nothing already
                                                        # converted moved
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

# ---------------------------------------------------------------------------
# THE ROUND'S SPANS.  Every prom_a `.incbin` that notes/reachability.py --targets
# reported with a non-zero reachable count on 2026-08-30, EXCEPT 0xFDE70F-
# 0xFE0000: that one is 6,385 bytes carrying 29 reachable, and converting it
# would buy 29 bytes of coverage for 6,356 bytes of territory.  It is left alone
# ON PURPOSE and this list is the record of that decision.
#
#   span                 size    reachable
#   0xF96018-0xF99021  12,297      7,097
#   0xF8C000-0xF8DA00   6,656      1,244
#   0xFA1404-0xFA5400  16,380      1,060
#   0xF85B0D-0xF85C89     380        373
#   0xF85D1C-0xF85E8A     366        366
ROUND_SPANS = [
    (0xF96018, 0xF99021),
    (0xF8C000, 0xF8DA00),
    (0xFA1404, 0xFA5400),
    (0xF85B0D, 0xF85C89),
    (0xF85D1C, 0xF85E8A),
]
# The spans THIS file emits; notes/gen_prom_a_f96018_module.py owns the big one.
MY_SPANS = [(0xF85B0D, 0xF85C89), (0xF85D1C, 0xF85E8A),
            (0xF8C000, 0xF8DA00), (0xFA1404, 0xFA5400)]

# Reachable bytes per span as measured BEFORE this round, from
# `python3 notes/reachability.py --targets` (cache: notes/reachability-cache.json).
# reach_table() must reproduce these or the emitters refuse: the walk moved.
# What the emitters actually produced on 2026-08-30, and therefore what a
# re-run has to reproduce.  The three residues are all stated rather than
# rounded away:
#   TRIMMED   -- runs whose fresh linear decode stops short of the run's last
#                byte, so the walk framed that tail from two seeds that
#                disagree; the tail stays `.incbin` rather than pick a side.
#                3 such runs among the 42 the walk reports; 1 of them survives
#                the audit mask and costs 2 bytes.
#   AUDIT_DROPPED -- reachable bytes a prior audit identified as DATA.  See
#                audited_code().
#   CONVERTED -- reachable - trimmed - audit_dropped, framed as instructions.
TRIMMED_RUNS = 3
TRIMMED_BYTES = 6
EMITTED_TRIMMED_BYTES = 2
AUDIT_DROPPED_RUNS = 18
AUDIT_DROPPED_BYTES = 701
CONVERTED = 9437
LABELS = 60

EXPECTED_REACHABLE = {
    0xF96018: 7097,
    0xF8C000: 1244,
    0xFA1404: 1060,
    0xF85B0D: 373,
    0xF85D1C: 366,
}


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
    return any(lo <= a < hi for lo, hi in ROUND_SPANS)


class _NoStore(dict):
    """A window cache that stores nothing.

    reachability.py keeps every decoded window in `_WIN` AND every instruction
    boundary in `_BOUND`; the second makes the first redundant and the first
    costs ~7 GB on a three-image run.  Dropping it changes no result -- a repeat
    call is served from the boundary index instead -- and `--selftest` checks
    that the reachable total is identical either way."""

    def __setitem__(self, key, value):
        pass


def lowmem():
    """Drop reachability.py's redundant window cache.  Applied to EVERY walk this
    file runs, frozen or not, so the two are comparable."""
    if not isinstance(R._WIN, _NoStore):
        R._WIN = _NoStore()


def freeze():
    """Make the walk answer as it did BEFORE this round spliced anything.

    Two things have to be undone: the converted lines this round adds (they
    would become new `branch` and `immediate` seeds) and the narrowed `.incbin`
    lines it leaves behind (the span must still read as unconverted)."""
    lowmem()
    if getattr(R, "_wsa1_frozen", False):
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
                if not any(lo <= a and e <= hi for lo, hi in ROUND_SPANS)]
        return proven, sorted(keep + list(ROUND_SPANS))

    R.source_lines = source_lines
    R.proven_and_incbin = proven_and_incbin
    R._wsa1_frozen = True


# -------------------------------------------------------- the reachable set
def _fingerprint():
    """Everything the walk reads, hashed.  Stable across this round's own
    splices precisely because freeze() removes their effect."""
    freeze()
    proven, spans = R.proven_and_incbin("prom_a")
    sd = R.seeds("prom_a", R.CPU1)
    h = hashlib.md5()
    h.update(hashlib.md5(rom()).hexdigest().encode())
    h.update(repr(sorted(proven)).encode())
    h.update(repr(sorted(spans)).encode())
    for k in sorted(sd):
        h.update((k + repr(sorted(sd[k]))).encode())
    return h.hexdigest()


_reach = {}


def reach_set():
    """The set of prom_a addresses execution reaches, as sorted (lo,hi) runs.

    Cached in /tmp under the fingerprint of the walk's inputs, because the walk
    itself costs about five minutes.  A stale cache is impossible: any change to
    the ROM, the proven set, the `.incbin` list or the seed sets changes the
    fingerprint and the walk re-runs."""
    if "runs" in _reach:
        return _reach["runs"]
    fp = _fingerprint()
    cache = os.path.join(tempfile.gettempdir(), "wsa1-prom_a-reach-%s.json" % fp[:16])
    if os.path.exists(cache):
        runs = [tuple(x) for x in json.load(open(cache))]
        _reach["runs"] = runs
        return runs
    freeze()
    res = R.analyse("prom_a", R.CPU1)
    seen = res["seen"]
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
    json.dump(runs, open(cache, "w"))
    _reach["runs"] = runs
    return runs


def runs_in(lo, hi):
    """The maximal reachable runs clipped to [lo,hi)."""
    out = []
    for a, b in reach_set():
        if b <= lo or a >= hi:
            continue
        out.append((max(a, lo), min(b, hi)))
    return out


def audited_code(lo, hi):
    """The parts of a span a PRIOR AUDIT has already shown to be code, or None
    when no audit covers it.

    ★ WHY THIS EXISTS -- THE WALK OVER-APPROXIMATES.  reachability.py's
    `immediate` seed class treats every 32-bit immediate landing in an image as
    an entry point.  Most such immediates are POINTERS, and a pointer is as
    likely to name a table as a routine, so the walk happily decodes a pointer
    table as instructions and calls the result reachable.  0xFA1404 is where
    that shows: 15 of its 21 "reachable runs" start at an immediate-only seed,
    and `python3 notes/prom_a_span_survey.py 0xFA1404 0xFA5400` prints a
    pointer-shaped run ending at almost every one of them --

        0xFA1690  23 entries ends 0xFA16EC        0xFA1B94  46 entries ends 0xFA1C4C
        0xFA1712  46 entries ends 0xFA17CA        0xFA1CAB  23 entries ends 0xFA1D07
        0xFA17CF  23 entries ends 0xFA182B        0xFA1D10  46 entries ends 0xFA1DC8
        0xFA182F  23 entries ends 0xFA188B        0xFA1DE1  26 entries ends 0xFA1E49
        0xFA1892 115 entries ends 0xFA1A5E

    -- i.e. those "runs" are the descriptor bytes BETWEEN handler pointer
    tables, and framing them as instructions produces text like
    `ld XWA,0x04034241` from the byte sequence 40 41 42 03 04.  A byte gate
    cannot see the difference; a reader can, and so can the audit.

    ★ A SECOND, INDEPENDENT WITNESS, from the tree's own converted code: at
    0xFA1041 (converted long before this round) prom_a does
    `add XBC,0x00fa1dc8 / ld A,(XBC)` -- it reads 0xFA1DC8 as a BYTE TABLE.  The
    walk framed 0xFA1DC8 as the start of a 28-byte routine.

    notes/prom_a_fa1404_identify.py settled this span in a previous wave and
    publishes the answer as CODE_BLOCKS.  It is imported, never retyped.

    ⚠ NO SUCH AUDIT COVERS THE OTHER FOUR SPANS, and none is invented here.
    They are left to the walk, with two independent reasons to trust it there:
    `python3 notes/prom_a_span_survey.py` finds their reachable runs stopping
    exactly at the pointer tables it detects (0xF97533's run ends at 0xF98DE5,
    the 134-entry table; 0xF8C842's ends at 0xF8C930, the 9-entry table), and
    NOT ONE of the 24 runs this file emits starts at an immediate-only seed:
    11 are prom_b directory slots, 2 are calls from already-converted code, and
    11 are branch targets the walk found inside code it had decoded.  --selftest
    checks that, so the claim cannot rot."""
    if (lo, hi) != (0xFA1404, 0xFA5400):
        return None
    M = _load(os.path.join(ROOT, "notes", "prom_a_fa1404_identify.py"),
              "wsa1_fa1404_identify")
    return [(a, e) for a, e, *_ in [tuple(b) for b in M.CODE_BLOCKS]]


def code_runs(lo, hi):
    """The reachable runs this file will actually frame: runs_in(), clipped to
    whatever a prior audit says is code, plus the runs the clip threw away.

    Where no audit covers the span, every reachable run is emitted -- the walk is
    the only evidence there is.

    ⚠ A run is kept only when the audit's code blocks contain it WHOLE.  A
    partial overlap would hand emit_span() a start address that is an audit
    boundary rather than an instruction boundary, and a decode from the middle of
    an instruction can still round-trip byte-identically while being nonsense.
    On this round's data the question is academic -- all three kept runs sit
    entirely inside a code block and all eighteen dropped ones entirely outside
    -- but the conservative rule is the one that stays true when the data
    changes."""
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


def reach_table():
    rows = []
    for lo, hi in sorted(ROUND_SPANS):
        rs = runs_in(lo, hi)
        rows.append((lo, hi, sum(b - a for a, b in rs), len(rs)))
    return rows


# ------------------------------------------------------------ entry points
_ev = {}


def entry_evidence():
    """addr -> the classes of entry point that name it.  This is the ONLY thing
    a label comment is allowed to say this round: which kind of edge arrives
    here, never what the routine does."""
    if _ev:
        return _ev
    freeze()
    sd = R.seeds("prom_a", R.CPU1)
    names = {"vector": "CPU vector table", "directory": "prom_b routine directory",
             "branch": "branch/call in converted code", "immediate": "32-bit immediate",
             "pointer_table": "framed pointer table"}
    for k, addrs in sd.items():
        for a in addrs:
            if BASE <= a < BASE + 0x80000:
                _ev.setdefault(a, []).append(names.get(k, k))
    return _ev


# --------------------------------------------------------------- emission
def incbin_line(lo, hi):
    return ('\t.incbin "original_ROMs/wsa1_prom_a.ic12", 0x%06X, 0x%06X'
            % (lo - BASE, hi - lo))


def existing_labels():
    return set(re.findall(r'^([A-Za-z_.$][\w.$]*):', open(SRC).read(), re.M))


def emit_span(lo, hi):
    """(lines, stats).  Reachable runs become instructions; everything else stays
    the `.incbin` it already was."""
    d = rom()
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
            # A fresh decode of the run did not land on the run's last byte, so
            # the walk framed these bytes from two seeds that disagree.  Keep the
            # part both agree on; the tail goes back into `.incbin`.
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
    head = ["; ==== 0x%06X-0x%06X -- REACHABLE CODE ONLY, emitted by "
            "notes/%s ====" % (lo, hi, os.path.basename(__file__)),
            "; %d reachable run(s), %d bytes framed as code.  %d bytes that "
            "nothing reaches stay" % (st["runs"], st["code_bytes"], st["incbin_bytes"]),
            "; `.incbin` -- this round converts REACHABLE CODE, not territory.",
            "; Boundaries: notes/reachability.py's walk, frozen against this "
            "file's own output.",
            "; Labels are sub_XXXXXX by design: this round is COVERAGE, naming "
            "is a later goal.",
            "; This text was assembled and byte-compared with the ROM before "
            "printing."]
    if st["audit_refused_bytes"]:
        head[3:3] = [
            "; ⚠ A FURTHER %d bytes in %d runs ARE marked reachable by "
            "notes/reachability.py and" % (st["audit_refused_bytes"],
                                           st["audit_refused_runs"]),
            "; are left `.incbin` anyway.  They fall outside the CODE_BLOCKS of",
            "; notes/prom_a_fa1404_identify.py, which identified them as handler "
            "pointer tables",
            "; and parameter descriptors; notes/prom_a_span_survey.py prints a "
            "pointer-shaped run",
            "; ending at almost every one of their start addresses.  The walk "
            "reached them through",
            "; its `immediate` seed class, which cannot tell a pointer to code "
            "from a pointer to a",
            "; table.  Framing data as instructions passes the byte gate and is "
            "still wrong.",
        ]
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
    for k, v in EXPECTED_REACHABLE.items():
        got = sum(b - a for a, b in runs_in(k, dict(ROUND_SPANS)[k]))
        if got != v:
            sys.exit("REFUSING TO EMIT: 0x%06X now has %d reachable bytes, audited "
                     "at %d.  The walk moved; re-audit before emitting." % (k, got, v))
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
    it, WITHOUT the freeze -- i.e. the real state of the tree right now.

    Run it before and after a splice and the difference is what this round
    bought, plus anything the round REVEALED: converted code is a seed source, so
    a span that had no framed entry point before can acquire one."""
    lowmem()
    r = R.analyse("prom_a", R.CPU1)
    rows = []
    for lo, hi in sorted(r["spans"]):
        n = sum(1 for x in range(lo, hi) if x in r["seen"])
        if n:
            rows.append((lo, hi, hi - lo, n))
    return r, rows



# ------------------------------------------ proof that a re-run reproduces
def reproduce(spans=None):
    """Re-emit every span from scratch and check the text matches what is in the
    .s, line for line.

    ★ THIS IS THE FREEZE'S PROOF.  An emitter that reads its own output stops
    reproducing it the moment it succeeds: its converted lines become new seeds,
    the reachable set grows and the run table moves.  freeze() is supposed to
    make that impossible; this is the check that says it did.  Run it on the
    already-spliced tree -- it should pass as often as you care to run it.

    ⚠ Label LINES are excluded from BOTH sides.  The tree now defines every
    `sub_XXXXXX` this round added and emit_span() will not define a name twice,
    so a re-run legitimately emits fewer of them.  What freeze() is responsible
    for is the run table and the framing, and that is what the body lines --
    instructions, `.L` labels and the narrowed `.incbin` lines, in order -- say.
    """
    src = open(SRC).read().split("\n")
    out = []
    for lo, hi in (spans or sorted(ROUND_SPANS)):
        lines, _st = emit_span(lo, hi)
        body = [l for l in lines if l.startswith("\t") or l.startswith(".L")]
        head = "; ==== 0x%06X-0x%06X -- REACHABLE CODE ONLY" % (lo, hi)
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
    round is not allowed to disturb a byte of it.  The emitters only ever splice
    into `.incbin` ranges, which is what makes that structurally true; this is
    the check that says so out loud.  Prints the number of pre-existing non-
    `.incbin` lines that were removed or rewritten -- it must be 0."""
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


# --------------------------------------------------------------- selftest
def check(msg, cond, extra=""):
    print(("  ok   " if cond else "  FAIL ") + msg + (("   " + extra) if extra else ""))
    return 0 if cond else 1


def selftest():
    bad = 0
    tbl = reach_table()
    for lo, hi, n, nr in tbl:
        bad += check("0x%06X-0x%06X: %d reachable bytes in %d runs, audit says %d"
                     % (lo, hi, n, nr, EXPECTED_REACHABLE[lo]), n == EXPECTED_REACHABLE[lo])
    tot = sum(n for _l, _h, n, _r in tbl)
    bad += check("the round's five spans hold 10,140 reachable bytes", tot == 10140,
                 str(tot))
    # EVERY run, not a sample: does a fresh linear decode from the run's first
    # byte land exactly on its last?  Where it does not, the walk framed those
    # bytes from two seeds that disagree, and emit_span() trims the tail back
    # into `.incbin` rather than emit a framing only one of them supports.  The
    # trim is pinned, so a new disagreement cannot appear unnoticed.
    checked = off = offbytes = 0
    for lo, hi in sorted(ROUND_SPANS):
        for a, b in runs_in(lo, hi):
            rows = RT.unidasm_range(a, b)
            checked += 1
            end = rows[-1][0] + len(rows[-1][1]) if rows else a
            if end != b:
                off += 1
                offbytes += b - end
    bad += check("all %d reachable runs re-decode cleanly except the %d the audit "
                 "records" % (checked, TRIMMED_RUNS), off == TRIMMED_RUNS, "%d off" % off)
    bad += check("the trimmed tails are the %d bytes the audit records"
                 % TRIMMED_BYTES, offbytes == TRIMMED_BYTES, "%d bytes" % offbytes)
    # ★ the check the FA1404 mistake earned: an `immediate`-only entry point is
    # a bare pointer, and a pointer names a table as readily as a routine.
    ev = entry_evidence()
    imm_only = [a for lo, hi in ROUND_SPANS for a, _b in code_runs(lo, hi)[0]
                if set(ev.get(a, [])) == {"32-bit immediate"}]
    bad += check("no run this file frames starts at an immediate-only seed",
                 not imm_only, "%d do" % len(imm_only))
    dropped = sum(n for lo, hi in ROUND_SPANS for _a, _b, n in code_runs(lo, hi)[1])
    bad += check("the audit mask holds back %d reachable bytes it calls data"
                 % AUDIT_DROPPED_BYTES, dropped == AUDIT_DROPPED_BYTES, "%d" % dropped)
    bad += check("converted = reachable - audit-dropped - trimmed = %d" % CONVERTED,
                 tot - dropped - EMITTED_TRIMMED_BYTES == CONVERTED,
                 "%d" % (tot - dropped - EMITTED_TRIMMED_BYTES))
    # freeze really removes this round's spans from the proven set
    freeze()
    proven, spans = R.proven_and_incbin("prom_a")
    bad += check("freeze: no address in ROUND_SPANS is counted as proven",
                 not any(_in_round(a) for a in proven))
    bad += check("freeze: every span of the round is back in the .incbin list",
                 all(s in spans for s in ROUND_SPANS))
    # ★ THE GUARD ITSELF IS TESTED, not just present: move one audited number
    # and build() must stop rather than emit something the audit never saw.
    saved = EXPECTED_REACHABLE[0xF8C000]
    EXPECTED_REACHABLE[0xF8C000] = saved - 1
    try:
        build(0xF85D1C, 0xF85E8A)
        fired = False
    except SystemExit:
        fired = True
    finally:
        EXPECTED_REACHABLE[0xF8C000] = saved
    bad += check("build() refuses to emit when an audited reachable total moves",
                 fired)

    # the label namespace is clear.  ⚠ NOT "no label of mine already exists" --
    # after the splice they all do, and that check would fail by growth.  What
    # matters is that no symbol is DEFINED TWICE, which is what llvm-mc rejects.
    defs = re.findall(r'^([A-Za-z_.$][\w.$]*):', open(SRC).read(), re.M)
    dup = sorted(set(n for n in defs if defs.count(n) > 1))
    bad += check("no symbol in prom_a/wsa1_prom_a.s is defined twice", not dup,
                 "%d duplicated" % len(dup))
    # and every span of the round really did lose its reachable bytes to code
    src = open(SRC).read()
    still = 0
    for lo, hi in ROUND_SPANS:
        for ln in src.split("\n"):
            mm = R.INCBIN.match(ln)
            if mm:
                a = BASE + int(mm.group(2), 16)
                e = a + int(mm.group(3), 16)
                if lo <= a and e <= hi:
                    still += e - a
    bad += check("the round's spans keep exactly the %d bytes no run covers "
                 "as `.incbin`" % (sum(hi - lo for lo, hi in ROUND_SPANS) - CONVERTED),
                 still == sum(hi - lo for lo, hi in ROUND_SPANS) - CONVERTED,
                 "%d" % still)
    print("\n%d checks, %d failures" % (len(tbl) + 11, bad))
    return 1 if bad else 0


def main():
    if "--after" in ARGV:
        r, rows = after()
        print("prom_a reached %s bytes | still .incbin %s | REACHABLE AND "
              "UNCONVERTED %s" % (format(r["reached"], ","), format(r["incbin"], ","),
                                  format(r["reach_in_incbin"], ",")))
        for lo, hi, size, n in rows:
            print("   0x%06X-0x%06X %8s bytes, %6s reachable" % (lo, hi,
                  format(size, ","), format(n, ",")))
        return 0
    if "--reproduce" in ARGV:
        bad = 0
        for lo, hi, ok, n, why in reproduce():
            print("  %s 0x%06X-0x%06X  %d body lines re-emitted %s"
                  % ("ok  " if ok else "FAIL", lo, hi, n,
                     "exactly as spliced" if ok else "DIFFERENTLY -- " + why))
            bad += 0 if ok else 1
        print("\n%d spans, %d differ" % (len(ROUND_SPANS), bad))
        return 1 if bad else 0
    if "--untouched" in ARGV:
        n, lost = untouched()
        print("%d non-.incbin lines existed at HEAD; %d of them were removed or "
              "rewritten by this round." % (n, len(lost)))
        for l in lost[:20]:
            print("   LOST: %r" % l)
        return 1 if lost else 0
    if "--selftest" in ARGV:
        return selftest()
    if "--reach" in ARGV:
        print("%-21s %8s %10s %6s" % ("span", "size", "reachable", "runs"))
        for lo, hi, n, nr in reach_table():
            print("0x%06X-0x%06X %8s %10s %6d   %s"
                  % (lo, hi, format(hi - lo, ","), format(n, ","), nr,
                     "(gen_prom_a_f96018_module.py)" if lo == 0xF96018 else ""))
        print("\nTOTAL reachable in this round's spans: %s bytes"
              % format(sum(n for _l, _h, n, _r in reach_table()), ","))
        return 0
    if "--layout" in ARGV:
        for lo, hi in sorted(ROUND_SPANS):
            keep, drop = code_runs(lo, hi)
            print("; ---- 0x%06X-0x%06X ----" % (lo, hi))
            for a, b in keep:
                print("   CODE    0x%06X-0x%06X  %6d" % (a, b, b - a))
            for a, b, n in drop:
                print("   DROPPED 0x%06X-0x%06X  %6d   reachable, but a prior "
                      "audit calls it data" % (a, b, n))
        return 0
    if "--emit" in ARGV:
        want = int(ARGV[ARGV.index("--emit") + 1], 16)
        lo, hi = [s for s in MY_SPANS if s[0] == want][0]
        lines, _st = build(lo, hi)
        print("\n".join(lines))
        return 0
    if "--splice" in ARGV:
        for lo, hi in MY_SPANS:
            splice(lo, hi)
        return 0
    print(__doc__)
    return 0


if __name__ == "__main__":
    sys.exit(main())
