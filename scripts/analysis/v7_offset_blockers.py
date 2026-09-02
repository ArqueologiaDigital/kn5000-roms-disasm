#!/usr/bin/env python3
"""v7_offset_blockers.py -- WHICH tlcs900-backend spelling gap blocks each of
v7_slice_split_plan.py's 94 NO_OFFSET_FOUND slices (46,570 B), and how much of
that total each distinct gap accounts for.

QUESTION THIS ANSWERS
----------------------
v7_slice_split_plan.py already proved *that* no offset in its +/-32 B search
window round-trips clean for these 94 slices. It does not say *why* -- it
throws away the disassembly the moment a candidate fails. This script re-walks
each slice's tail, ONE INSTRUCTION AT A TIME, using the exact verified method
`convert_taskevent_fifo_family.py` established for the sub-CPU payload (never
trust a summed `--show-encoding` length; verify every accepted instruction by
reassembling ITS OWN text alone and checking it reproduces the true byte slice
at its true position) -- and reports the FIRST byte offset that resists,
classified as one of:

  HARD_DECODE          llvm-mc's disassembler emits "invalid instruction
                        encoding" for this byte outright -- a genuine decoder
                        gap (a byte pattern with no TableGen match at all).
  SILENT_MISCOMPILE     llvm-mc decodes SOMETHING, but that text does not
                        reassemble back to the same bytes -- a print/encode
                        ambiguity collapse (the already-documented "LD
                        explicit-zero-displacement" shape is exactly this;
                        this script's `special()` reuse means only NEW
                        instances of this shape are reported here).
  UNPARSEABLE_PRINT     llvm-mc decodes something whose printed text is not
                        even valid input to llvm-mc's OWN assembler (a
                        disassembler/assembler syntax mismatch, distinct from
                        a wrong-bytes miscompile).

WHY THE ANCHOR OFFSET, NOT THE FULL +/-32 WINDOW
--------------------------------------------------
The split-plan search tries the v9/v10-derived header run length first (its
own `run_length_v9v10` field), then walks outward. Reporting the blocker AT
THAT ANCHOR is the single most meaningful data point per slice: it is the
split point the evidence (the v9/v10 same-named header) actually supports, and
it is deterministic -- unlike scanning the whole window, which can land on an
accidentally-decodable but semantically wrong offset (the false-positive shape
`v7_slice_split_plan.py`'s trivial-opcode guard already exists to catch).

WHAT "BYTES BLOCKED" MEANS HERE, AND WHAT IT DOES NOT
-------------------------------------------------------
Each slice's tail length (size - run_length_v9v10) is attributed to whichever
form blocks it FIRST. This is a LOWER BOUND, not a promise: fixing the first
blocker in a slice is NECESSARY for that slice to round-trip but may not be
SUFFICIENT if a second, different gap sits deeper in the same tail -- exactly
the pattern the sub-CPU lane hit (RESm/SETm/BITm found only after the
explicit-zero-displacement LD fix stopped hiding it). Re-run this script after
any fix; a form's count dropping to 0 does not mean the bytes it used to gate
are now converted, only that they cleared THIS gate.

RUN
    python3 scripts/analysis/v7_offset_blockers.py
    reads scripts/analysis/v7_slice_split_plan.json
    writes scripts/analysis/v7_offset_blockers.json
"""
import importlib.util
import json
import os
import re
import sys
from collections import defaultdict

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.chdir(REPO)

_spec = importlib.util.spec_from_file_location(
    "taskevent_family",
    os.path.join(REPO, "scripts/converters/convert_taskevent_fifo_family.py"))
tef = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(tef)

HARD_RE = re.compile(
    r"^HARD DECODE FAILURE at offset (\d+): byte (0x[0-9a-f]+), context (.+)$")
MISCOMPILE_RE = re.compile(
    r"^SILENT MISCOMPILE / unresolved ambiguity at offset (\d+): decoded '(.+?)' "
    r"claims ([0-9a-f ]*) but the stream has ([0-9a-f ]+)$")
UNPARSE_RE = re.compile(
    r"^cannot reassemble decoded text '(.+?)' at offset (\d+)$")
SPECIAL_RE = re.compile(
    r"^special-case '(.+?)' at offset (\d+) did not verify: got (.*), want (.+)$")


def classify(raw):
    """Walk `raw` with tef.decode_stream; return a dict describing the
    outcome. status='CLEAN' if the whole tail round-trips (decode_stream
    raises nothing -- it verifies every step against the real bytes as it
    goes, so a normal return already IS the round-trip proof)."""
    try:
        tef.decode_stream(raw)
        return {'status': 'CLEAN'}
    except ValueError as ex:
        msg = str(ex)
        m = HARD_RE.match(msg)
        if m:
            off, byte, ctx = m.groups()
            return {'status': 'HARD_DECODE', 'offset': int(off), 'byte': byte,
                     'context': ctx}
        m = MISCOMPILE_RE.match(msg)
        if m:
            off, text, claims, stream = m.groups()
            return {'status': 'SILENT_MISCOMPILE', 'offset': int(off), 'text': text,
                     'claims': claims, 'stream': stream}
        m = UNPARSE_RE.match(msg)
        if m:
            text, off = m.groups()
            return {'status': 'UNPARSEABLE_PRINT', 'offset': int(off), 'text': text}
        m = SPECIAL_RE.match(msg)
        if m:
            text, off, got, want = m.groups()
            return {'status': 'SPECIAL_CASE_MISFIRE', 'offset': int(off), 'text': text,
                     'got': got, 'want': want}
        return {'status': 'UNRECOGNISED_ERROR', 'message': msg}


def mnemonic_of(text):
    return text.strip().split()[0] if text.strip() else '<empty>'


def form_key(c):
    """A grouping key coarse enough to rank by, fine enough to act on."""
    if c['status'] == 'HARD_DECODE':
        return f"HARD_DECODE byte={c['byte']}"
    if c['status'] == 'SILENT_MISCOMPILE':
        return f"SILENT_MISCOMPILE {mnemonic_of(c['text'])}"
    if c['status'] == 'UNPARSEABLE_PRINT':
        return f"UNPARSEABLE_PRINT {mnemonic_of(c['text'])}"
    if c['status'] == 'SPECIAL_CASE_MISFIRE':
        return f"SPECIAL_CASE_MISFIRE {mnemonic_of(c['text'])}"
    return c['status']


def main():
    rows = json.load(open('scripts/analysis/v7_slice_split_plan.json'))
    noof = [r for r in rows if r['verdict'] == 'NO_OFFSET_FOUND']

    results = []
    for r in noof:
        binpath = r['bin']
        data = open(binpath, 'rb').read()
        offset = r['run_length_v9v10']
        tail = data[offset:]
        c = classify(tail)
        results.append({**r, 'anchor_offset': offset, 'tail_len': len(tail),
                         'blocker': c, 'form': form_key(c) if c['status'] != 'CLEAN' else 'CLEAN'})

    out = 'scripts/analysis/v7_offset_blockers.json'
    json.dump(results, open(out, 'w'), indent=1)

    by_form = defaultdict(lambda: {'slices': 0, 'bytes': 0, 'examples': []})
    for r in results:
        f = r['form']
        by_form[f]['slices'] += 1
        by_form[f]['bytes'] += r['tail_len']
        if len(by_form[f]['examples']) < 3:
            by_form[f]['examples'].append((r['label'], r['tail_len'], r['blocker']))

    clean_at_anchor = [r for r in results if r['form'] == 'CLEAN']
    print(f"{len(noof)} NO_OFFSET_FOUND slices, {sum(r['size'] for r in noof):,} B total\n")
    if clean_at_anchor:
        print(f"** {len(clean_at_anchor)} slices ({sum(r['tail_len'] for r in clean_at_anchor):,} B) "
              f"round-trip CLEAN at the exact v9/v10 anchor offset via decode_stream, "
              f"despite failing the +/-32 window search -- re-check these first, likely a "
              f"header-similarity-gate rejection, not a spelling gap. **\n")

    print(f"{'form':45s} {'slices':>7s} {'bytes':>8s}")
    ranked = sorted(by_form.items(), key=lambda kv: -kv[1]['bytes'])
    for form, d in ranked:
        if form == 'CLEAN':
            continue
        print(f"{form:45s} {d['slices']:7d} {d['bytes']:8,d}")

    print("\nTop examples per form:")
    for form, d in ranked:
        if form == 'CLEAN':
            continue
        print(f"\n{form}  ({d['bytes']:,} B across {d['slices']} slices)")
        for label, tlen, blocker in d['examples']:
            print(f"    {label:40s} {tlen:6d} B  {blocker}")

    print(f"\nwrote {out}")


if __name__ == '__main__':
    sys.exit(main())
