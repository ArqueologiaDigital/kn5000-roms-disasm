#!/usr/bin/env python3
"""v10audio_spans_reframe_feasibility.py -- how much of this lane's residue is a
MIS-FRAMED instruction, and could a reframe close it today?

QUESTION ANSWERED
  The largest single shape in v10/maincpu/audio/'s `.byte` residue is not a
  whole undecoded routine and not a data table: it is a 1-4 byte run flanked by
  CODE on both sides where the real instruction STARTS at the run's first byte
  and RUNS PAST its last -- fill_verified_islands.py's "SPANS" verdict, which
  that tool deliberately refuses because closing it means editing the following
  source line too.  This script measures, for every SPANS run in this lane's
  files: what the real instruction is, and whether the current backend can spell
  it.  That separates "we do not know what this is" from "we know exactly what
  it is and cannot write it down".

METHOD
  Reuses fill_verified_islands.bounds_from_context's own context walk: step back
  up to 48 bytes through bytes the ASSEMBLER emitted as instructions, decode
  forward with MAME unidasm, and take the instruction that begins at the run's
  first byte.  Then ask convert_code_bytes (llvm-mc round trip) whether that
  instruction, and only it, is spellable.

⚠ WHAT THIS IS NOT.  A SPANS verdict is not proof the bytes are code: the run
  can be the tail of a fixed-width DATA record whose successor happens to be
  real code, which is the incident documented in fill_verified_islands.py's
  header.  looks_like_a_table_tail() is applied here for the same reason, and a
  run it flags is excluded from the feasible count.  Nothing here is applied;
  this script only measures.

⚠ TOOLCHAIN-SENSITIVE.  The spellable/blocked split moves whenever
  tlcs900_backend gains an encoding.  Print the llvm-project revision alongside
  any number taken from this script.

RUN
    python3 scripts/analysis/v10audio_byte_triage.py --work W --csv T.csv
    python3 scripts/analysis/v10audio_spans_reframe_feasibility.py --work W --csv T.csv

PROVENANCE
  Lane V10AUDIO of the 2026-09-01 full-disassembly push.
"""
import argparse
import collections
import csv
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / 'scripts' / 'converters'))
import fill_verified_islands as fvi
import convert_code_bytes as cb

UNI = os.path.expanduser("~/compartilhado/tools/unidasm")
BASE = 0xE00000
DASM = re.compile(r'^([0-9a-f]+):\s+((?:[0-9a-f]{2} )+)\s*(.*)$')


def true_instruction(rom, terr, start, end, tmp):
    """Length of the instruction that begins at `start`, decoded from context."""
    a, back = start, 0
    while a > 0 and terr[a - 1] == 1 and back < 48:
        a -= 1
        back += 1
    open(tmp, "wb").write(rom[a:end + 24])
    out = subprocess.run([UNI, tmp, "-arch", "tlcs900", "-basepc", hex(BASE + a)],
                         capture_output=True, text=True).stdout
    for line in out.split("\n"):
        m = DASM.match(line.strip())
        if m and int(m.group(1), 16) - BASE == start:
            return len(m.group(2).split()), m.group(3).strip()
    return None, None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--work", required=True)
    ap.add_argument("--csv", required=True)
    a = ap.parse_args()

    rows = [r for r in csv.DictReader(open(a.csv)) if r["tile"] == "SPANS"]
    terr, blobs, rom = fvi.load("v10", a.work)
    tmp = tempfile.NamedTemporaryFile(suffix=".bin", delete=False).name

    n_ok = b_ok = n_no = b_no = n_tail = b_tail = n_lost = 0
    forms = collections.Counter()
    formb = collections.Counter()
    for r in rows:
        start = int(r["addr"], 16) - BASE
        size = int(r["size"])
        end = start + size
        L, text = true_instruction(rom, terr, start, end, tmp)
        if L is None:
            n_lost += 1
            continue
        if fvi.looks_like_a_table_tail(rom, end, tmp):
            n_tail += 1
            b_tail += size
            continue
        res = cb.convert_block(list(rom[start:start + L]), base_pc=BASE + start,
                               verbose=False)
        und = sum(nb for m, o, nb in res if m is None)
        if und == 0:
            n_ok += 1
            b_ok += size
        else:
            n_no += 1
            b_no += size
            key = (text or "?").split()[0]
            forms[key] += 1
            formb[key] += size

    print(f"SPANS runs in this lane's files: {len(rows)}")
    print(f"  reframe SPELLABLE today : {n_ok:5d} runs, {b_ok:6,} B of `.byte`")
    print(f"  reframe BLOCKED         : {n_no:5d} runs, {b_no:6,} B "
          f"(backend has no encoding for the merged instruction)")
    print(f"  refused, table-tail     : {n_tail:5d} runs, {b_tail:6,} B")
    print(f"  context walk desynced   : {n_lost:5d} runs")
    print("\n  blocked by unidasm mnemonic of the real instruction:")
    for k, v in formb.most_common(20):
        print(f"    {k:16s} {v:6,} B  ({forms[k]} sites)")


if __name__ == "__main__":
    main()
