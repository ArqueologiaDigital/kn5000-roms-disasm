#!/usr/bin/env python3
"""fill_verified_islands_v7.py -- v7 single-tree adaptation of
fill_verified_islands.py, the same narrowing convert_region_v7.py already
applied to convert_region.py.

WHY A SEPARATE FILE
  fill_verified_islands.py's main() hard-codes `tag in {v9, v10}` and its
  --apply path always tries to mirror the edit into a v9/v10 sibling file
  (`other_tag`), asserting the sibling's ROM bytes match first. v7 has no
  such sibling. This variant reuses bounds_from_context(), which does its
  own context-decode purely from `rom`/`terr` passed in (a v7 pickle load
  is precisely their inputs) and needs no v9/v10 knowledge, and
  looks_like_a_table_tail() the SAME WAY, unmodified -- the fixed-width
  DATA-record-tail trap it guards against (see that function's docstring
  for the two confirmed incidents on v9/v10) is a property of the ROM
  bytes and the calibrated CODE/DATA rule, not of which image it runs on.
  Only main()'s tree-walking and the single-tree write path are new.

RUN
    python3 scripts/converters/fill_verified_islands_v7.py --work WORKDIR \
        [--exclude-file NAME.s ...] [--apply] [--limit N]

  Dry run by default. --apply writes ONLY v7/<relpath>.

PROVENANCE
  Lane V7CODE2 of the 2026-09-01 full-disassembly push, worktree
  ~/compartilhado/disasm-lanes/v7code2 (branch w6/v7code2).
"""
import argparse
import os
import re
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / 'scripts' / 'converters'))
sys.path.insert(0, str(REPO / 'scripts' / 'analysis'))
from convert_interrupted_region import build_replacement  # noqa: E402
from fill_verified_islands import bounds_from_context, looks_like_a_table_tail, load  # noqa: E402

BASE, SIZE = 0xE00000, 2097152
BYTE_RE = re.compile(r'^\s*\.byte\s+((?:0x[0-9a-fA-F]{2}\s*,?\s*)+)\s*$')


def collect_span(lines, start_idx, size):
    i = start_idx
    collected = 0
    n_lines = 0
    while i < len(lines):
        m = BYTE_RE.match(lines[i])
        if not m:
            break
        vals = re.findall(r'0x([0-9a-fA-F]{2})', m.group(1))
        collected += len(vals)
        n_lines += 1
        i += 1
        if collected == size:
            break
    return collected, n_lines


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--work', required=True)
    ap.add_argument('--apply', action='store_true')
    ap.add_argument('--limit', type=int, default=None)
    ap.add_argument('--exclude-file', action='append', default=[])
    a = ap.parse_args()

    terr, blobs, rom = load('v7', a.work)
    tmp = tempfile.NamedTemporaryFile(suffix=".bin", delete=False).name

    isl = [b for b in blobs if b["kind"] == "byteblob" and 0 < b["start"]
           and b["end"] < SIZE and terr[b["start"] - 1] == 1 and terr[b["end"]] == 1]
    print(f"v7: {len(isl):,} code-flanked byteblobs to classify")

    excluded_names = set(a.exclude_file)
    excluded_count = excluded_bytes = 0
    accepted = []
    counts = {}
    table_tail_rejects = 0
    for b in isl:
        if os.path.basename(b["file"]) in excluded_names:
            excluded_count += 1
            excluded_bytes += b["size"]
            continue
        fr, ok = bounds_from_context(rom, terr, b["start"], b["end"], tmp)
        key = (fr, ok)
        counts[key] = counts.get(key, 0) + 1
        if fr == "ONE_INSN" or (fr == "MULTI" and ok):
            if looks_like_a_table_tail(rom, b["end"], tmp):
                table_tail_rejects += 1
                continue
            accepted.append(b)
    for k, v in sorted(counts.items(), key=lambda kv: -kv[1]):
        print(f"   {k}: {v}")
    if excluded_names:
        print(f"   (skipped {excluded_count} runs / {excluded_bytes} B in "
              f"excluded files: {sorted(excluded_names)})")
    print(f"   (of the tiling ones, {table_tail_rejects} also rejected as a "
          f"likely DATA-record tail -- see looks_like_a_table_tail)")
    print(f"=> {len(accepted):,} context-verified candidates (no reframing needed)")

    if a.limit:
        accepted = accepted[:a.limit]

    ready = []
    for b in accepted:
        raw = rom[b["start"]:b["end"]]
        try:
            new_lines, remaining = build_replacement(list(raw), BASE + b["start"])
        except Exception:
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

    by_file = {}
    for b, nl in ready:
        by_file.setdefault(b["file"], []).append((b, nl))

    total_applied = 0
    for relpath, items in by_file.items():
        items.sort(key=lambda t: -t[0]["line"])  # highest line first
        p7 = REPO / 'v7' / relpath
        lines_self = p7.read_text(encoding='latin-1').split('\n')
        applied_here = 0
        for b, nl in items:
            addr, size = b["start"], b["size"]
            start_idx = b["line"] - 1
            collected, n_lines = collect_span(lines_self, start_idx, size)
            if collected != size:
                print(f"SKIP {relpath}:{b['line']} -- collected {collected}B, expected {size}B")
                continue
            end_idx = start_idx + n_lines
            lines_self[start_idx:end_idx] = nl
            total_applied += size
            applied_here += 1
        p7.write_text('\n'.join(lines_self), encoding='latin-1')
        print(f"applied {relpath}: {applied_here}/{len(items)} run(s) (v7 only)")

    print(f"TOTAL applied: {total_applied:,} B")


if __name__ == '__main__':
    main()
