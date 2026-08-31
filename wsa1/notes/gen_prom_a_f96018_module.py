#!/usr/bin/env python3
"""Emit the reachable code inside prom_a 0xF96018-0xF99021 -- the single biggest
item on the WSA1R coverage goal's work list.

QUESTION IT ANSWERS
    "Of the 12,297 bytes this `.incbin` still holds, which ones does execution
     reach, what is their assembly, and what has to stay `.incbin`?"

WHY THIS SPAN, AND WHY FIRST
    `python3 notes/reachability.py --targets` ranks the whole goal by REACHABLE
    bytes.  This span is the top row: 7,097 reachable bytes, 40.4% of the entire
    17,558-byte goal and more than prom_b's total remainder.  Ranking by span
    size would have sent this lane at 0xFA1404 (16,380 bytes, 1,060 reachable)
    or 0xFDE70F (6,385 bytes, 29 reachable) instead.

WHERE THE BOUNDARIES COME FROM, AND WHAT THIS FILE ADDS
    All of the machinery is notes/gen_prom_a_cover_round1.py -- the frozen
    reachability walk, the run table, the per-run re-decode check, the label
    rules and the whole-region byte proof.  This file exists because the span is
    the lane's headline item and deserves its own audit constants and its own
    refusal: it re-derives the run table on EVERY run and refuses to emit if the
    run count, the reachable total or the span's own boundaries have moved since
    the audit below.

    THE AUDIT (2026-08-30, before anything in this round was spliced):
        span              0xF96018-0xF99021, 12,297 bytes
        reachable         7,097 bytes in 8 runs  (57.7% of the span)
        framed as code    7,095 bytes, 27 labels, 3 `.byte` fall-backs
        still `.incbin`   5,202 bytes that nothing reaches, plus 2 bytes at the
                          tail of the 0xF96172 run: a fresh decode of that run
                          stops at 0xF961BD, so the last 2 bytes are bytes two
                          seeds disagree about and they stay unconverted.
    Both counts are pinned below; a later run that produces different numbers
    stops instead of silently emitting something else.

★ AN INDEPENDENT WITNESS THAT THE RUNS STOP IN THE RIGHT PLACES
    `python3 notes/prom_a_span_survey.py 0xF96018 0xF99021` detects two
    pointer-shaped runs in this span, at 0xF969A5 (8 entries) and 0xF98DE5 (134
    entries).  Neither is framed as code here: the 6,322-byte run ends at exactly
    0xF98DE5, and 0xF969A5 sits inside the `.incbin` that survives at
    0xF96432-0xF97418.  The walk and the table detector, which share no code,
    put the same boundary in the same place.

⚠ SEMANTICS ARE OUT OF SCOPE THIS ROUND
    Labels are `sub_XXXXXX` plus the class of edge that arrives -- a prom_b
    directory slot, a pointer-table entry, a branch from converted code.  No
    routine here is given a name and no header claims what one does.  A bare
    `sub_XXXXXX` is the correct output for a coverage pass.

RUN
    python3 notes/gen_prom_a_f96018_module.py             # the assembly
    python3 notes/gen_prom_a_f96018_module.py --audit     # the run table
    python3 notes/gen_prom_a_f96018_module.py --stats     # the census
    python3 notes/gen_prom_a_f96018_module.py --splice    # write it into the .s
"""
import importlib.util
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ARGV = list(sys.argv)
LO, HI = 0xF96018, 0xF99021


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


G = _load(os.path.join(ROOT, "notes", "gen_prom_a_cover_round1.py"), "wsa1_cover_r1")

# Pinned by the audit.  A mismatch means the walk moved and this file stops.
EXPECTED_REACHABLE = 7097
EXPECTED_RUNS = 8


def runs():
    rs = G.runs_in(LO, HI)
    n = sum(b - a for a, b in rs)
    if n != EXPECTED_REACHABLE:
        sys.exit("REFUSING TO EMIT: 0x%06X-0x%06X now has %d reachable bytes, "
                 "audited at %d.  Re-audit before emitting." % (LO, HI, n, EXPECTED_REACHABLE))
    if EXPECTED_RUNS is not None and len(rs) != EXPECTED_RUNS:
        sys.exit("REFUSING TO EMIT: %d reachable runs, audited at %d."
                 % (len(rs), EXPECTED_RUNS))
    if rs and (rs[0][0] < LO or rs[-1][1] > HI):
        sys.exit("REFUSING TO EMIT: a run escapes the span.")
    return rs


def main():
    rs = runs()
    if "--audit" in ARGV:
        print("0x%06X-0x%06X  %d bytes, %d reachable in %d runs"
              % (LO, HI, HI - LO, sum(b - a for a, b in rs), len(rs)))
        for a, b in rs:
            print("   code 0x%06X-0x%06X  %6d" % (a, b, b - a))
        return 0
    if "--splice" in ARGV:          # before build(): splice() builds it itself
        G.splice(LO, HI)
        return 0
    lines, st = G.build(LO, HI)
    if "--stats" in ARGV:
        for k in sorted(st):
            print("%-16s %d" % (k, st[k]))
        print("emitted lines:   %d" % len(lines))
        return 0
    print("\n".join(lines))
    return 0


if __name__ == "__main__":
    sys.exit(main())
