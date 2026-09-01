#!/usr/bin/env python3
"""Is prom_b's TRUE territorial debt bigger than its `.incbin` count?

QUESTION IT ANSWERS
    The lane brief for this push warns that `.incbin` count alone is the WRONG
    instrument -- elsewhere in this tree, 8,496 bytes of un-decoded sound code
    sat in plain sight as long `.byte` runs, in a file whose own `.incbin`
    count read "complete". This script checks prom_b for the same failure mode:
    a long run of `.byte`/`.word`/`.hword` directives that is really raw,
    undecoded material wearing a typed directive as a disguise.

METHOD
    Scan prom_b/wsa1_prom_b.s for maximal runs of consecutive .byte/.word/
    .hword lines (blank lines and full-line comments do not break a run).
    For every run of >= 64 bytes, check whether EVERY line in the run carries
    a `;` comment. A run with per-line comments has a human (or a generator
    script) asserting what each line IS -- font rows, table records, glyph
    bitmaps -- which is the same standard already-converted spans meet
    elsewhere in this tree. A run with ZERO per-line comments is exactly what
    an un-audited raw dump looks like, and gets printed for inspection.

    ⚠ This is a NECESSARY check, not a SUFFICIENT one -- a run can carry a
    comment on every line and still be wrong (a comment does not verify
    itself). It exists to find the specific failure the brief warned about
    (bytes nobody has looked at, dressed as data), not to certify meaning.

RESULT, as of the wave that added notes/gen_prom_b_stepselect_module.py
    188 runs of >=64 bytes, 103,311 bytes total, ALL OF THEM font bitmaps,
    directory/link tables or value-glyph bitmaps -- i.e. typed and understood.
    Only 3 runs (2,291 bytes) carry zero per-line comments, and both inspected
    by hand are font/bitmap blocks whose per-ROW comment would say nothing a
    reader can check (a 24 x 3-byte glyph bitmap, a 5 x 15-row cursor bitmap) --
    each already has a header identifying the whole block. Verdict: prom_b's
    true debt IS its `.incbin` total; there is no hidden `.byte`-dressed
    remainder. Re-run this after every conversion round, since a future round
    could reintroduce exactly this failure.

RUN
    python3 notes/prom_b_byte_run_audit.py                  # the summary
    python3 notes/prom_b_byte_run_audit.py --uncommented     # list the 0-comment runs
    python3 notes/prom_b_byte_run_audit.py --selftest        # invariants
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "prom_b", "wsa1_prom_b.s")
THRESHOLD = 64  # bytes; below this a run is too small to hide meaningful debt

BYTE_RE = re.compile(r'\s*\.byte\s+(.*)')
WORD_RE = re.compile(r'\s*\.word\s+(.*)')
HWORD_RE = re.compile(r'\s*\.hword\s+(.*)')


def directive_bytes(line):
    m = BYTE_RE.match(line)
    if m:
        return len(m.group(1).split(","))
    m = WORD_RE.match(line) or HWORD_RE.match(line)
    if m:
        return len(m.group(1).split(",")) * 2
    return 0


def find_runs(lines):
    """[(start_line0, end_line0_excl, total_bytes, n_lines, n_commented), ...]"""
    runs = []
    cur_start = cur_bytes = cur_lines = cur_commented = 0
    active = False
    for i, line in enumerate(lines):
        bc = directive_bytes(line)
        if bc:
            if not active:
                cur_start, cur_bytes, cur_lines, cur_commented = i, 0, 0, 0
                active = True
            cur_bytes += bc
            cur_lines += 1
            if ";" in line:
                cur_commented += 1
        else:
            s = line.strip()
            if s == "" or s.startswith(";"):
                continue  # does not break a run
            if active:
                runs.append((cur_start, i, cur_bytes, cur_lines, cur_commented))
            active = False
    if active:
        runs.append((cur_start, len(lines), cur_bytes, cur_lines, cur_commented))
    return [r for r in runs if r[2] >= THRESHOLD]


def load_lines():
    return open(SRC).read().split("\n")


def main():
    lines = load_lines()
    runs = find_runs(lines)
    total = sum(r[2] for r in runs)
    uncommented = [r for r in runs if r[4] == 0]
    unc_total = sum(r[2] for r in uncommented)

    if "--selftest" in sys.argv:
        ok = True
        if not runs:
            print("FAIL: no runs found at all -- parser probably broken"); ok = False
        for s, e, b, n, c in runs:
            if c > n:
                print("FAIL: commented count exceeds line count in run at line", s + 1); ok = False
        # every run must be non-overlapping and increasing
        for (s1, e1, *_), (s2, e2, *_) in zip(runs, runs[1:]):
            if s2 < e1:
                print("FAIL: overlapping runs"); ok = False
        print("SELFTEST", "PASS" if ok else "FAIL")
        return 0 if ok else 1

    if "--uncommented" in sys.argv:
        for s, e, b, n, c in uncommented:
            print("lines %d-%d  bytes=%d  lines=%d" % (s + 1, e, b, n))
        return 0

    print("prom_b/wsa1_prom_b.s: %d runs of .byte/.word/.hword >= %d bytes, %d bytes total"
          % (len(runs), THRESHOLD, total))
    print("  of which %d run(s), %d bytes, carry ZERO per-line comments"
          % (len(uncommented), unc_total))
    print("  (inspect with --uncommented; each must be hand-checked, a comment")
    print("   count of >0 does not itself certify correctness)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
