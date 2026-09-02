#!/usr/bin/env python3
"""convert_v10audio_spans.py -- close the MIS-FRAMED instructions in this lane's
files: a `.byte` run that is the FIRST bytes of an instruction whose remaining
bytes were framed as a separate, wrong "instruction" on the next line.

QUESTION ANSWERED
  fill_verified_islands.py can fill a `.byte` island only when the real
  instruction begins and ends inside the run.  The commonest shape in
  v10/maincpu/audio/ is the other one -- the instruction starts at the run's
  first byte and RUNS PAST its last, so the source's next line is framed from
  the middle of an instruction.  MEASURED with
  scripts/analysis/v10audio_spans_reframe_feasibility.py: 1,088 such runs in
  this lane's files; 306 of them (379 B of `.byte`) have a merged instruction
  the current backend can spell.  This script converts exactly those.

  Fixing one costs an edit to the FOLLOWING line as well, which is why the
  island tool refuses them and why the refusal list below is long.

⚠ THE HAZARD THIS CLASS CARRIES, AND THE FOUR REFUSALS
  A sibling lane's reframe pass turned 14 `.ascii` lines into instructions,
  `"TEMPO   "` among them -- byte-exact, invisible to the byte gate.  So:
   1. ANY `.ascii`/`.asciz` line inside the span is a HARD REFUSAL.  A span that
      swallows a string literal has the wrong extent, always.
   2. Any label or comment inside the span is a refusal -- a label marks an
      address something else names, and a comment is a previous lane's finding.
   3. looks_like_a_table_tail() (the census's calibrated periodicity rule over a
      window reaching back BEFORE the run) must be silent.  This is the check
      added after two fixed-width DATA record tables were converted because
      their LAST record happened to abut real code.
   4. The span's byte extent, taken from address_line_map.py, must equal the
      merged instruction's extent EXACTLY, and the merged instruction must
      round-trip with ZERO bytes left over.

  What none of these can do is prove the bytes are code; the byte gate cannot
  either.  What makes the class as a whole defensible is that the run is flanked
  by CODE the assembler itself emitted on BOTH sides, and the decode that
  produces the merged instruction is driven from bytes established as code
  BEFORE the run, not from the run in isolation.

RUN
    python3 scripts/analysis/v10audio_byte_triage.py --work W --csv T.csv
    python3 scripts/analysis/address_line_map.py --dump amap.json
    python3 scripts/converters/convert_v10audio_spans.py --work W --csv T.csv \
        --amap amap.json [--limit N] [--apply]

PROVENANCE
  Lane V10AUDIO of the 2026-09-01 full-disassembly push.
"""
import argparse
import collections
import csv
import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / 'scripts' / 'converters'))
sys.path.insert(0, str(REPO / 'scripts' / 'analysis'))
import fill_verified_islands as fvi
import convert_code_bytes as cb
from v10audio_spans_reframe_feasibility import true_instruction

BASE = 0xE00000
LABEL_RE = re.compile(r'^\s*[A-Za-z_.$][\w.$]*\s*:')
STRING_RE = re.compile(r'\.ascii[z]?\b')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--work", required=True)
    ap.add_argument("--csv", required=True)
    ap.add_argument("--amap", required=True)
    ap.add_argument("--limit", type=int)
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()

    rows = [r for r in csv.DictReader(open(a.csv)) if r["tile"] == "SPANS"]
    terr, blobs, rom = fvi.load("v10", a.work)
    tmp = tempfile.NamedTemporaryFile(suffix=".bin", delete=False).name

    amap = json.load(open(a.amap))
    byfile = collections.defaultdict(dict)
    for e in amap:
        byfile[e["src"]].setdefault(e["line"], e["addr"])
    ordered = {f: sorted(d.items(), key=lambda kv: (kv[1], kv[0]))
               for f, d in byfile.items()}

    refused = collections.Counter()
    plans = collections.defaultdict(list)
    for r in rows:
        start = int(r["addr"], 16) - BASE
        size = int(r["size"])
        end = start + size
        L, _ = true_instruction(rom, terr, start, end, tmp)
        if L is None:
            refused["context walk desynced"] += 1
            continue
        if fvi.looks_like_a_table_tail(rom, end, tmp):
            refused["looks like a table tail"] += 1
            continue
        res = cb.convert_block(list(rom[start:start + L]), base_pc=BASE + start,
                               verbose=False)
        if any(m is None for m, _, _ in res):
            refused["merged instruction not spellable"] += 1
            continue
        # decode must be ONE instruction covering exactly [start, start+L)
        if len(res) != 1 or res[0][2] != L:
            refused["merged decode is not a single instruction"] += 1
            continue
        src = "v10/" + r["file"]
        od = ordered.get(src)
        if not od:
            refused["file not in the address map"] += 1
            continue
        first = byfile[src]
        # address_line_map.py works in ABSOLUTE addresses; `start` is a ROM
        # offset.  Mixing the two silently refuses every candidate.
        astart = BASE + start
        try:
            l0 = next(ln for ln, ad in reversed(od) if ad <= astart)
            l1 = next(ln for ln, ad in reversed(od) if ad < astart + L)
        except StopIteration:
            refused["line lookup failed"] += 1
            continue
        after = [ad for ln, ad in od if (ad, ln) > (first[l1], l1)]
        if not after or first[l0] != astart or min(after) != astart + L:
            refused["span extent != merged instruction extent"] += 1
            continue
        plans[src].append((l0, l1, start, L, "\t" + res[0][0]))

    for src in plans:
        path = REPO / src
        lines = open(path, encoding="latin-1").read().split("\n")
        keep = []
        for l0, l1, start, L, text in plans[src]:
            bad = None
            for t in lines[l0 - 1:l1]:
                if STRING_RE.search(t):
                    bad = "string literal in span"
                elif LABEL_RE.match(t):
                    bad = "label in span"
                elif ";" in t:
                    bad = "comment in span"
            if bad:
                refused[bad] += 1
                continue
            keep.append((l0, l1, start, L, text))
        plans[src] = keep

    # drop any pair of plans in the same file whose line ranges touch
    for src in plans:
        keep, last = [], None
        for p in sorted(plans[src]):
            if last is not None and p[0] <= last:
                refused["overlapping line ranges"] += 1
                continue
            keep.append(p)
            last = p[1]
        plans[src] = keep

    if a.limit:
        flat = [(s, p) for s in plans for p in plans[s]][:a.limit]
        plans = collections.defaultdict(list)
        for s, p in flat:
            plans[s].append(p)

    n = sum(len(v) for v in plans.values())
    nb = sum(int(r["size"]) for r in rows)
    print(f"{len(rows)} SPANS runs ({nb:,} B of .byte); {n} convertible")
    for k, v in refused.most_common():
        print(f"    refused {v:5d}  {k}")
    for src in sorted(plans):
        got = sum(1 for _ in plans[src])
        print(f"  {os.path.basename(src):34s} {got:4d} reframes")
        if not a.apply:
            for l0, l1, start, L, text in plans[src][:4]:
                print(f"      0x{BASE+start:06X} L={L} lines {l0}..{l1} -> {text.strip()}")

    if not a.apply:
        print("(dry run; pass --apply)")
        return
    for src in plans:
        path = REPO / src
        lines = open(path, encoding="latin-1").read().split("\n")
        for l0, l1, start, L, text in sorted(plans[src], reverse=True):
            lines[l0 - 1:l1] = [text]
        open(path, "w", encoding="latin-1").write("\n".join(lines))
        print(f"wrote {path}")


if __name__ == "__main__":
    main()
