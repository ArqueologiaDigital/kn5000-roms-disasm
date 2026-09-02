#!/usr/bin/env python3
"""run_v7_worklist_batch.py -- apply convert_interrupted_region_v7.py across
a batch of v7_region_worklist.py's ranked regions in one pass, in the ORDER
that keeps line-number hints valid without a re-census between every single
region.

WHY THE ORDER MATTERS
  Each conversion rewrites a variable-length range of SOURCE LINES (a .byte
  run compresses into fewer -- or, when one 8-bytes-per-line run becomes one
  mnemonic per line, sometimes MORE -- lines than it started with), so every
  edit shifts the line numbers of everything AFTER it in that same file.
  convert_region_v7.py's own header already names the fix: process a file
  bottom-to-top (highest line/address first) so an edit never invalidates a
  not-yet-applied region's hint in the same file. This script sorts by
  (file, address DESCENDING) and simply walks that order -- regions in
  DIFFERENT files never interact, and within one file, converting the
  highest address first never shifts anything before it.

SAFETY (unchanged from convert_interrupted_region_v7.py, not duplicated
  here): every instruction is still verified through
  convert_code_bytes.convert_block's own llvm-mc round trip, and a region
  whose reported size overruns into an already-typed symbolic table
  auto-shrinks to the verified-safe prefix (or aborts if that prefix would
  be 0 B) -- see that module's 2026-09-02 fix. This driver adds no new
  decoding logic; it only sequences calls to process() and logs the result
  of each one (including a caught exception, which SKIPS that region rather
  than guessing) so a bad region cannot take an entire batch down.

RUN
    python3 scripts/converters/run_v7_worklist_batch.py WORKLIST.json \
        [--min-calls N] [--require-clean] [--exclude-table-tail] \
        [--limit N] [--apply]

  Dry run by default (still calls process() with apply=False, so you see
  the same per-region decode preview convert_interrupted_region_v7.py would
  print, just batched). --apply writes.
"""
import argparse
import importlib.util
import json
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / 'scripts' / 'converters'))
import convert_interrupted_region_v7 as civ7  # noqa: E402


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('worklist')
    ap.add_argument('--min-calls', type=int, default=1)
    ap.add_argument('--require-clean', action='store_true',
                     help='only regions where n_call_hits == n_calls')
    ap.add_argument('--exclude-table-tail', action='store_true')
    ap.add_argument('--limit', type=int, default=None)
    ap.add_argument('--apply', action='store_true')
    ap.add_argument('--log', default=None)
    a = ap.parse_args()

    worklist = json.load(open(a.worklist))
    sel = [w for w in worklist if w['n_calls'] >= a.min_calls]
    if a.require_clean:
        sel = [w for w in sel if w['n_call_hits'] == w['n_calls']]
    if a.exclude_table_tail:
        sel = [w for w in sel if not w['table_tail_reject']]
    if a.limit:
        sel = sel[:a.limit]

    # (file, address DESCENDING) -- see module docstring
    sel.sort(key=lambda w: (w['file'], -w['addr']))

    results = []
    total_addr = total_conv = 0
    n_ok = n_fail = 0
    for w in sel:
        try:
            actual_size, remaining = civ7.process(w['file'], w['src_line'], w['addr'],
                                                    w['size'], apply=a.apply)
            # Use the ACTUAL (possibly auto-shrunk) size process() reports,
            # not the worklist's original w['size'] -- see
            # convert_interrupted_region_v7.py's 2026-09-02 fix. Using the
            # original size here silently credited bytes that were never
            # touched (they sat outside the shrunk, verified-safe prefix).
            converted = actual_size - remaining
            results.append(dict(w, status='ok', converted=converted, remaining=remaining,
                                 actual_size=actual_size))
            total_addr += actual_size; total_conv += converted
            n_ok += 1
        except Exception as e:
            results.append(dict(w, status='fail', error=str(e)))
            n_fail += 1
            print(f"SKIP {w['file']}:{w['src_line']} {w['addr']:#x} ({w['size']}B) -- {e}")
        print("---")

    print(f"\n{n_ok} ok / {n_fail} failed, out of {len(sel)} selected")
    print(f"bytes addressed: {total_addr:,}   converted to instructions: {total_conv:,} "
          f"({100.0*total_conv/max(total_addr,1):.1f}%)")
    if a.log:
        json.dump(results, open(a.log, 'w'), indent=1)
        print(f"wrote {a.log}")
    if not a.apply:
        print("(dry run -- pass --apply to write)")


if __name__ == '__main__':
    main()
