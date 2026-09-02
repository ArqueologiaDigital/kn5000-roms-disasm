#!/usr/bin/env python3
"""fill_verified_islands.py -- batch-convert the "island" .byte runs that
v9_v10_undisassembled_census.py's --islands mode identifies as ONE_INSN or
a fully-tiling MULTI: a literal `.byte` run flanked by real CODE on both
sides, where decoding forward from a point *earlier in that same CODE*
naturally produces an instruction (or a clean chain of them) that starts
exactly at the run's first byte and ends exactly at its last -- so filling
it touches ONLY that run, nothing outside it.

QUESTION ANSWERED
  Of the census's "islands" (28,105 B / 15,877 runs in v9, mostly single
  misplaced instructions -- see README-v9v10-census.md), which ones can be
  filled with NO reframing of neighboring lines, and does llvm-mc have a
  spelling for the result?

WHY THIS IS SAFER THAN A NAIVE ISOLATED DECODE
  Feeding just the run's own bytes to convert_code_bytes, with no context,
  cannot tell a genuine short instruction from a coincidental short decode
  that happens to tile to the run's exact length -- exactly the trap this
  lane's brief warns about (a wrong frame reproduces the same bytes). This
  tool instead reproduces v9_v10_undisassembled_census.py's own islands()
  method: walk backward up to 48 bytes through bytes ALREADY established as
  CODE (by the existing, gate-verified source), decode forward from there,
  and only accept the run if that decode -- driven by real preceding
  code, not the run in isolation -- lands an instruction boundary exactly
  at the run's start and tiles it exactly to its end with no overrun. A
  SPANS result (the boundary lands past the run's end) means the true
  instruction reaches into what is currently a separate, already-existing
  line -- that is a reframe, out of scope for this tool (its whole point is
  "touch nothing outside the run"); UNSYNCED means the backward walk never
  resyncs at all. Both are left alone.

  Once a run is accepted, decoding it AGAIN in isolation (base_pc at its own
  address) reproduces the identical instructions -- TLCS-900 decode does not
  depend on anything before an instruction's own first byte -- so the actual
  replacement text still comes from convert_code_bytes/convert_region's
  usual isolated path; the context walk is purely a corroboration step, not
  the source of the emitted mnemonics.

RUN
    python3 scripts/converters/fill_verified_islands.py v9 --work WORKDIR [--apply] [--limit N]

  Dry run by default. --apply writes to both v9 and v10 (after asserting
  their ROM bytes at each address match, same discipline as
  convert_region.py) and re-derives each blob's own file/line straight from
  the census's marker data (each island blob's line is ITS OWN precise
  start, unlike judge()'s coarser "nearest .byte-kind blob in this region"
  display heuristic -- no rewind-to-true-start needed here). Files are
  patched one at a time, highest line number first, so an earlier edit in a
  file never invalidates a not-yet-applied blob's line number in the same
  file.

PROVENANCE
  Lane ISLANDS of the 2026-09-01 full-disassembly push, worktree
  ~/compartilhado/disasm-lanes/islands (branch w2/islands).
"""
import argparse
import os
import pickle
import re
import subprocess
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / 'scripts' / 'converters'))
import convert_code_bytes as cb
from convert_interrupted_region import build_replacement

UNI = os.path.expanduser("~/compartilhado/tools/unidasm")
BASE, SIZE = 0xE00000, 2097152
DASM = re.compile(r'^([0-9a-f]+):\s+((?:[0-9a-f]{2} )+)\s*(.*)$')
BYTE_RE = re.compile(r'^\s*\.byte\s+((?:0x[0-9a-fA-F]{2}\s*,?\s*)+)\s*$')


def load(tag, work):
    d = pickle.load(open(os.path.join(work, f"{tag}.map.pkl"), "rb"))
    rom = open(os.path.join(REPO, "original_ROMs", f"kn5000_{tag}_program.rom"), "rb").read()
    return d["terr"], d["blobs"], rom


def bounds_from_context(rom, terr, start, end, tmp):
    """Reproduces islands()'s own context decode. Returns (fr, tiling) where
    fr in ONE_INSN/MULTI/SPANS/UNSYNCED and, for MULTI, `tiling` is True only
    if the whole [start,end) is covered by complete instructions with no
    overrun (islands() itself does not check this for MULTI -- it only looks
    at the FIRST instruction's length -- so this tool is stricter)."""
    a, back = start, 0
    while a > 0 and terr[a - 1] == 1 and back < 48:
        a -= 1
        back += 1
    open(tmp, "wb").write(rom[a:end + 24])
    out = subprocess.run([UNI, tmp, "-arch", "tlcs900", "-basepc", hex(BASE + a)],
                         capture_output=True, text=True).stdout
    bnd = {}
    for line in out.split("\n"):
        m = DASM.match(line.strip())
        if m:
            addr = int(m.group(1), 16) - BASE
            bnd[addr] = len(m.group(2).split())
    if start not in bnd:
        return "UNSYNCED", False
    L = bnd[start]
    if L == end - start:
        return "ONE_INSN", True
    if L < end - start:
        # walk the chain and require it to land EXACTLY on end, no overrun
        pos = start
        while pos < end:
            if pos not in bnd:
                return "MULTI", False
            pos += bnd[pos]
            if pos > end:
                return "MULTI", False
        return "MULTI", (pos == end)
    return "SPANS", False


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('tag', choices=['v9', 'v10'])
    ap.add_argument('--work', required=True)
    ap.add_argument('--apply', action='store_true')
    ap.add_argument('--limit', type=int, default=None)
    a = ap.parse_args()

    terr, blobs, rom = load(a.tag, a.work)
    tmp = tempfile.NamedTemporaryFile(suffix=".bin", delete=False).name

    isl = [b for b in blobs if b["kind"] == "byteblob" and 0 < b["start"]
           and b["end"] < SIZE and terr[b["start"] - 1] == 1 and terr[b["end"]] == 1]
    print(f"{a.tag}: {len(isl):,} code-flanked byteblobs to classify")

    accepted = []
    counts = {}
    for b in isl:
        fr, ok = bounds_from_context(rom, terr, b["start"], b["end"], tmp)
        key = (fr, ok)
        counts[key] = counts.get(key, 0) + 1
        if fr == "ONE_INSN" or (fr == "MULTI" and ok):
            accepted.append(b)
    for k, v in sorted(counts.items(), key=lambda kv: -kv[1]):
        print(f"   {k}: {v}")
    print(f"=> {len(accepted):,} context-verified candidates (no reframing needed)")

    if a.limit:
        accepted = accepted[:a.limit]

    # try the actual spelling for each; keep only ones llvm-mc can fully
    # spell (remaining == 0) -- a PARTIAL fill of a run this short would
    # leave an orphaned .byte fragment with no clear boundary meaning, so
    # this tool only ever does all-or-nothing on a given run.
    ready = []
    for b in accepted:
        raw = rom[b["start"]:b["end"]]
        try:
            new_lines, remaining = build_replacement(list(raw), BASE + b["start"])
        except Exception as e:
            continue
        if remaining == 0:
            ready.append((b, new_lines))
    print(f"=> {len(ready):,} fully spellable by llvm-mc "
          f"({sum(b['size'] for b, _ in ready):,} B)")

    if not a.apply:
        for b, nl in ready[:20]:
            print(f"   {BASE+b['start']:#08x} {b['size']}B {b['file']}:{b['line']} "
                  f"-> {'; '.join(l.strip() for l in nl)}")
        print("(dry run -- pass --apply to write)")
        return

    rom_v9 = open(REPO / "original_ROMs" / "kn5000_v9_program.rom", "rb").read()
    rom_v10 = open(REPO / "original_ROMs" / "kn5000_v10_program.rom", "rb").read()
    by_file = {}
    for b, nl in ready:
        by_file.setdefault(b["file"], []).append((b, nl))

    total_applied = 0
    for relpath, items in by_file.items():
        items.sort(key=lambda t: -t[0]["line"])  # highest line first
        p9 = REPO / a.tag / relpath
        other_tag = 'v10' if a.tag == 'v9' else 'v9'
        p_other = REPO / other_tag / relpath
        lines_self = p9.read_text(encoding='latin-1').split('\n')
        lines_other = p_other.read_text(encoding='latin-1').split('\n')
        for b, nl in items:
            addr, size = b["start"], b["size"]
            if rom_v9[addr:addr + size] != rom_v10[addr:addr + size]:
                print(f"SKIP {relpath}:{b['line']} {BASE+addr:#x} -- v9/v10 ROM differ here")
                continue
            start_idx = b["line"] - 1
            # collect exactly the maximal .byte run starting here, verify size
            i = start_idx
            collected = 0
            n_lines = 0
            while i < len(lines_self):
                m = BYTE_RE.match(lines_self[i])
                if not m:
                    break
                vals = re.findall(r'0x([0-9a-fA-F]{2})', m.group(1))
                collected += len(vals)
                n_lines += 1
                i += 1
                if collected == size:
                    break
            if collected != size:
                print(f"SKIP {relpath}:{b['line']} -- collected {collected}B, expected {size}B")
                continue
            end_idx = start_idx + n_lines
            # same span in the other tag's file, by matching line number
            # (both trees are lockstep at this point in the file for a
            # not-yet-touched region -- verified by the raw ROM equality
            # check above, which is the authority; line-count is a guard)
            oi = start_idx
            ocollected = 0
            on_lines = 0
            while oi < len(lines_other):
                m = BYTE_RE.match(lines_other[oi])
                if not m:
                    break
                vals = re.findall(r'0x([0-9a-fA-F]{2})', m.group(1))
                ocollected += len(vals)
                on_lines += 1
                oi += 1
                if ocollected == size:
                    break
            if ocollected != size or on_lines != n_lines:
                print(f"SKIP {relpath}:{b['line']} -- {other_tag} span mismatch "
                      f"({ocollected}B/{on_lines}L vs {size}B/{n_lines}L)")
                continue
            lines_self[start_idx:end_idx] = nl
            lines_other[start_idx:end_idx] = nl
            total_applied += size
        p9.write_text('\n'.join(lines_self), encoding='latin-1')
        p_other.write_text('\n'.join(lines_other), encoding='latin-1')
        print(f"applied {relpath}: {len(items)} run(s)")

    print(f"TOTAL applied: {total_applied:,} B")


if __name__ == '__main__':
    main()
