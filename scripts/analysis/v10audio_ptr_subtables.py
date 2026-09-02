#!/usr/bin/env python3
"""v10audio_ptr_subtables.py -- find 32-bit POINTER TABLES that sit INSIDE a
larger `.byte` run in the v10 maincpu audio sources.

QUESTION ANSWERED
  v10audio_byte_triage.py's R4 shape test asks whether a WHOLE `.byte` run is a
  pointer table.  Most of the audio engine's pointer tables are not whole runs:
  they are a stretch in the middle of one long `.byte` block that also carries
  4-byte parameter records before and after them, so the run-level test misses
  them.  This script asks the sub-run question: which 4-aligned stretches of a
  `.byte` run are >= MIN consecutive little-endian 32-bit words that ALL land on
  CODE territory inside this ROM?

WHY "ALL TARGETS ARE CODE" IS THE TEST, NOT "ALL TARGETS ARE IN RANGE
  Any byte quadruple whose top byte is 0x00 and whose third byte is 0xE0..0xFF
  is "in range" for a 2 MB ROM based at 0xE00000 -- for the audio engine's
  4-byte parameter records (`0xb1,0x17,0x7f,0x02`) that is not rare.  Requiring
  every target to be a byte the ASSEMBLER ITSELF emitted as an instruction
  (territory==CODE from the -show-encoding stream, not from a linear sweep) is
  what makes a run of k such words implausible by chance; --null below measures
  how implausible on this exact image.

  This is DATA being typed as DATA -- a pointer table becomes `.long TARGET`.
  It is not a claim that the bytes are code, so the data-as-code hazard does not
  apply to the table itself.  It does apply to the TARGETS: this script only
  reports them, and a target that is already a named label in the tree is much
  stronger evidence than a bare address.

RUN
    python3 scripts/analysis/v10audio_ptr_subtables.py --work <workdir> [--min 4]
    python3 scripts/analysis/v10audio_ptr_subtables.py --work <workdir> --null

  --null shuffles each candidate run's bytes 200 times (a permutation null: same
  byte histogram, no structure) and reports how often a table of the same
  minimum length appears.  That is the false-positive rate of the shape test.

PROVENANCE
  Lane V10AUDIO of the 2026-09-01 full-disassembly push.
"""
import argparse
import os
import pickle
import random
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / 'scripts' / 'analysis'))
from v10audio_byte_triage import in_scope

BASE, SIZE = 0xE00000, 2097152
NM = os.path.expanduser("~/compartilhado/llvm-project/build/bin/llvm-nm")
ELF = REPO / "rebuilt_ROMs" / "kn5000_v10_program.llvm.elf"


def symbols():
    out = subprocess.run([NM, "--defined-only", str(ELF)],
                         capture_output=True, text=True).stdout
    sym = {}
    for line in out.split("\n"):
        p = line.split()
        if len(p) == 3 and p[1] in "tTdDrRbB":
            a = int(p[0], 16)
            if BASE <= a < BASE + SIZE:
                sym.setdefault(a - BASE, p[2])
    return sym


def find_tables(rom, terr, start, end, minlen, code_required=True):
    """Maximal 4-aligned sub-ranges of >= minlen LE32 words landing on CODE."""
    a = start + ((-start) % 4)
    good = []
    off = a
    while off + 4 <= end:
        v = int.from_bytes(rom[off:off + 4], "little")
        ok = BASE <= v < BASE + SIZE and (not code_required or terr[v - BASE] == 1)
        good.append(ok)
        off += 4
    out, i = [], 0
    while i < len(good):
        if good[i]:
            j = i
            while j < len(good) and good[j]:
                j += 1
            if j - i >= minlen:
                out.append((a + 4 * i, j - i))
            i = j
        else:
            i += 1
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--work", required=True)
    ap.add_argument("--min", type=int, default=4)
    ap.add_argument("--null", action="store_true")
    a = ap.parse_args()

    d = pickle.load(open(os.path.join(a.work, "v10.map.pkl"), "rb"))
    terr = bytes(d["terr"])
    rom = open(REPO / "original_ROMs" / "kn5000_v10_program.rom", "rb").read()
    sym = symbols()
    scope = [b for b in d["blobs"] if b["kind"] == "byteblob" and in_scope(b["file"])]

    total = 0
    hits = []
    for b in scope:
        for off, k in find_tables(rom, terr, b["start"], b["end"], a.min):
            hits.append((b, off, k))
            total += 4 * k
    print(f"{len(hits)} pointer sub-tables, {total:,} B, in {len(scope)} scoped .byte runs "
          f"({sum(x['size'] for x in scope):,} B)")
    for b, off, k in hits:
        named = sum(1 for i in range(k)
                    if int.from_bytes(rom[off + 4 * i:off + 4 * i + 4], "little") - BASE in sym)
        print(f"  0x{BASE+off:06X} {k:3d} entries {4*k:4d} B  "
              f"{os.path.basename(b['file'])}  run 0x{BASE+b['start']:06X}+{b['size']}  "
              f"{named}/{k} targets already named")
        for i in range(k):
            t = int.from_bytes(rom[off + 4 * i:off + 4 * i + 4], "little") - BASE
            print(f"        [{i:2d}] 0x{BASE+t:06X}  {sym.get(t, '')}")

    if a.null:
        rnd = random.Random(20260902)
        fp = 0
        trials = 0
        for b in scope:
            if b["size"] < 4 * a.min:
                continue
            blob = bytearray(rom[b["start"]:b["end"]])
            for _ in range(200):
                rnd.shuffle(blob)
                fake = bytes(rom[:b["start"]]) + bytes(blob) + bytes(rom[b["end"]:])
                if find_tables(fake, terr, b["start"], b["end"], a.min):
                    fp += 1
                trials += 1
        print(f"\nNULL (byte-permutation, same histogram): {fp}/{trials} shuffles "
              f"produced a >= {a.min}-entry table = {100.0*fp/max(trials,1):.3f}%")


if __name__ == "__main__":
    main()
