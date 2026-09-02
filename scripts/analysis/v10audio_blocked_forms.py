#!/usr/bin/env python3
"""v10audio_blocked_forms.py -- WHY can this lane's code-as-`.byte` residue not
be converted?  Which instruction forms is the assembler missing?

QUESTION ANSWERED
  v10audio_byte_triage.py classifies part of v10/maincpu/audio/'s `.byte`
  residue as CODE on cross-reference and context-tiling evidence.  Knowing a run
  is code does not make it convertible: the conversion path
  (convert_code_bytes.convert_block -> llvm-mc round trip) can only emit a
  mnemonic tlcs900_backend can assemble back to the same bytes.  This script
  runs that path over every CODE-verdict run and reports what is left raw,
  keyed by the form MAME's unidasm says the bytes are -- i.e. the work list for
  whoever is adding encodings to the backend.

  It deliberately reports the UNIDASM reading of the blocked bytes.  That is a
  second opinion, not proof: unidasm and the backend are independent decoders,
  and a form appearing here is a candidate for the backend, not a fact about
  the silicon.

RUN
    python3 scripts/analysis/v10audio_byte_triage.py --work W --csv T.csv
    python3 scripts/analysis/v10audio_blocked_forms.py --work W --csv T.csv

PROVENANCE
  Lane V10AUDIO of the 2026-09-01 full-disassembly push.
"""
import argparse
import collections
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


def unidasm_head(raw, pc):
    tmp = tempfile.NamedTemporaryFile(suffix=".bin", delete=False).name
    open(tmp, "wb").write(raw)
    out = subprocess.run([UNI, tmp, "-arch", "tlcs900", "-basepc", hex(pc)],
                         capture_output=True, text=True).stdout
    os.unlink(tmp)
    for line in out.split("\n"):
        m = DASM.match(line.strip())
        if m:
            return m.group(3).strip()
    return "?"


def main():
    import csv
    ap = argparse.ArgumentParser()
    ap.add_argument("--work", required=True)
    ap.add_argument("--csv", required=True)
    ap.add_argument("--verdict", default="CODE")
    a = ap.parse_args()

    rows = [r for r in csv.DictReader(open(a.csv)) if r["verdict"] == a.verdict]
    terr, blobs, rom = fvi.load("v10", a.work)

    full = fullb = part = partb = leftb = 0
    forms = collections.Counter()
    formb = collections.Counter()
    lead = collections.Counter()
    for r in rows:
        off = int(r["addr"], 16) - BASE
        n = int(r["size"])
        res = cb.convert_block(list(rom[off:off + n]), base_pc=BASE + off, verbose=False)
        und = [(o, nb) for m, o, nb in res if m is None]
        if not und:
            full += 1
            fullb += n
            continue
        part += 1
        partb += n
        for o, nb in und:
            leftb += nb
            raw = rom[off + o:off + o + nb]
            f = unidasm_head(raw, BASE + off + o)
            key = f.split()[0] if f else "?"
            forms[key] += 1
            formb[key] += nb
            lead["0x%02x" % raw[0]] += nb

    print(f"{a.verdict}-verdict runs: {len(rows)}")
    print(f"  fully spellable by the current backend: {full} runs, {fullb} B")
    print(f"  partly/not spellable:                   {part} runs, {partb} B "
          f"({leftb} B still raw after conversion)")
    print("\n  blocked bytes by unidasm mnemonic:")
    for k, v in formb.most_common(30):
        print(f"    {k:16s} {v:6,} B  ({forms[k]} sites)")
    print("\n  blocked bytes by leading opcode byte:")
    for k, v in lead.most_common(20):
        print(f"    {k}  {v:6,} B")


if __name__ == "__main__":
    main()
