#!/usr/bin/env python3
r"""HOW MANY `.byte` OPERANDS ARE IN THE SOUND-EDITOR CORNER, AND IN WHAT SHAPE?

QUESTION ANSWERED
-----------------
`sound_editor_ui.s` and `semenu_routines.s` are reported as carrying 7,754 and
857 `.byte` operands.  A raw operand count says nothing about whether that is
DEBT.  This tool splits the operands into contiguous RUNS -- maximal blocks of
consecutive source lines that emit only `.byte` -- and reports the run-length
distribution, because the two failure modes have very different shapes:

  * a 1-2 byte run wedged between two decoded instructions is almost always an
    OPCODE the disassembler could not spell  -> category (a), real code;
  * a run of tens or hundreds of bytes under its own label is a TABLE
    -> category (b) untyped structured data, or (c) a genuine byte table.

It deliberately does NOT decide which; it only measures the shape so the
classifier (se_classify_byte_runs.py) has something to be checked against.

RUN
    python3 scripts/lanes/v10se/se_byte_run_census.py
    python3 scripts/lanes/v10se/se_byte_run_census.py --json runs.json
"""
import argparse
import json
import os
import re
import sys

TARGETS = [
    "v10/maincpu/audio/sound_editor_ui.s",
    "v10/maincpu/audio/semenu_routines.s",
]

BYTE_RE = re.compile(r"^\s*\.byte\s+(.*)$")
LABEL_RE = re.compile(r"^([A-Za-z_.$][\w.$]*):")


def count_operands(operand_text):
    # strip a trailing comment
    t = operand_text.split(";")[0].split("//")[0].strip()
    if not t:
        return 0
    return len([x for x in t.split(",") if x.strip()])


def scan(path):
    """Return list of runs: dict(start_line, end_line, nbytes, label, prev_code, next_code)."""
    with open(path, encoding="latin-1") as fh:
        lines = fh.read().split("\n")
    runs = []
    i = 0
    n = len(lines)
    last_label = None
    last_code = None

    def is_blank(s):
        s = s.strip()
        return (not s) or s.startswith(";")

    while i < n:
        line = lines[i]
        m = LABEL_RE.match(line)
        if m:
            last_label = m.group(1)
            # a label line may also carry an instruction after the colon
            rest = line[m.end():].strip()
            if rest and not rest.startswith(";"):
                if not BYTE_RE.match("\t" + rest):
                    last_code = rest
            i += 1
            continue
        bm = BYTE_RE.match(line)
        if bm:
            start = i
            nb = 0
            label_at_start = last_label
            while i < n:
                bm2 = BYTE_RE.match(lines[i])
                if bm2:
                    nb += count_operands(bm2.group(1))
                    i += 1
                    continue
                if is_blank(lines[i]):
                    # a blank/comment does not break a run only if more .byte follows
                    j = i
                    while j < n and is_blank(lines[j]):
                        j += 1
                    if j < n and BYTE_RE.match(lines[j]):
                        i = j
                        continue
                break
            # what follows the run
            j = i
            while j < n and is_blank(lines[j]):
                j += 1
            nxt = lines[j].strip() if j < n else ""
            runs.append(dict(
                file=path, start_line=start + 1, end_line=i, nbytes=nb,
                label=label_at_start, prev_code=last_code, next_line=nxt,
            ))
            last_code = None
            continue
        if not is_blank(line):
            last_code = line.strip()
        i += 1
    return runs


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--json")
    ap.add_argument("--root", default=os.path.dirname(
        os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))))
    args = ap.parse_args()

    allruns = []
    for t in TARGETS:
        p = os.path.join(args.root, t)
        rs = scan(p)
        for r in rs:
            r["file"] = t
        allruns += rs
        total = sum(r["nbytes"] for r in rs)
        print(f"{t}: {len(rs)} runs, {total} .byte operands")

    buckets = [(1, 1), (2, 2), (3, 4), (5, 8), (9, 16), (17, 32), (33, 64),
               (65, 128), (129, 256), (257, 10 ** 9)]
    print("\nrun-length distribution (both files):")
    print(f"  {'len':>12}  {'runs':>6}  {'bytes':>7}")
    for lo, hi in buckets:
        sel = [r for r in allruns if lo <= r["nbytes"] <= hi]
        if not sel:
            continue
        hs = "inf" if hi > 10 ** 8 else str(hi)
        print(f"  {lo:>5}-{hs:>6}  {len(sel):>6}  {sum(r['nbytes'] for r in sel):>7}")
    print(f"  {'TOTAL':>12}  {len(allruns):>6}  {sum(r['nbytes'] for r in allruns):>7}")

    if args.json:
        with open(args.json, "w") as fh:
            json.dump(allruns, fh, indent=1)
        print(f"\nwrote {args.json}")


if __name__ == "__main__":
    main()
