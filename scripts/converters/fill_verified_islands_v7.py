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
        [--exclude-file NAME.s ...] [--start N] [--count N] [--apply] [--limit N]

  Dry run by default. --apply writes ONLY v7/<relpath>.

  --start/--count slice the CANDIDATE LIST (sorted by ROM address) BEFORE
  the expensive per-candidate unidasm classification loop runs, not after
  it like --limit does. 2026-09-02: v7's current island population is
  6,874 code-flanked byteblobs (up from the 2,268 measured before this
  session's confirmed-region conversions widened the island set -- see
  notes/lanes/ISLANDS-V7-2026-09-02.md), and classifying the whole list in
  one process before converting or committing anything already cost one
  budget its entire run with zero commits to show for it. Slice into
  batches of ~150-300, convert+gate+commit each slice, and resume with the
  next --start. The address sort makes slices stable across runs (nothing
  else in this tool's candidate selection is randomised).

PROVENANCE
  Lane V7CODE2 of the 2026-09-01 full-disassembly push, worktree
  ~/compartilhado/disasm-lanes/v7code2 (branch w6/v7code2).

  Sliced batching + the near-uniform-run guard added by lane V7ISLANDS,
  worktree ~/compartilhado/disasm-lanes/v7islands (branch w7/v7islands),
  2026-09-02, after a coordinator review of the first (unsliced) run: (1)
  classifying all ~6,874 candidates before converting or committing any of
  them risks losing the whole computation if the session ends mid-run, and
  (2) no converter in this tree previously defended against a uniform or
  near-uniform byte run decoding cleanly (e.g. a run of 0xFF as repeated
  `swi 7`) -- context tiling, looks_like_a_table_tail and call-target
  corroboration all aim at OTHER failure shapes and none of them grips
  this one, because a uniform run re-encodes byte-exact and a short run
  can sit inside looks_like_a_table_tail's 150 B window dominated by real
  preceding code, diluting the periodicity signal below its threshold.
"""
import argparse
import os
import re
import sys
import tempfile
from collections import Counter
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / 'scripts' / 'converters'))
sys.path.insert(0, str(REPO / 'scripts' / 'analysis'))
from convert_interrupted_region import build_replacement  # noqa: E402
from fill_verified_islands import bounds_from_context, looks_like_a_table_tail, load  # noqa: E402

BASE, SIZE = 0xE00000, 2097152
BYTE_RE = re.compile(r'^\s*\.byte\s+((?:0x[0-9a-fA-F]{2}\s*,?\s*)+)\s*$')
# 2026-09-02: 192 `.byte` runs across this tree carry a trailing
# `; call SomeName (v7 addr)` comment -- a PRIOR pass already decoded these
# as absolute `call` instructions and resolved the target by name, but left
# the bytes as `.byte` (this exact regex, anchored with no trailing content
# allowed, is why: BYTE_RE alone always failed to match the line and
# collect_span silently reported "0 B collected", the same SKIP every other
# stale-line-hint case produces, with no way to tell the two apart without
# reading the line). Recognised narrowly -- ONLY the `(v7 addr)` suffix,
# never the unrelated and unexplained `(v7 patched)` annotation (380
# instances elsewhere in this tree, left alone: no note anywhere records
# why those were kept as .byte, so this tool does not guess).
#
# ⚠ 2026-09-02 FINDING: the `(v7 addr)` comment's NAME is frequently WRONG.
# Three checked by hand against symbols/maincpu_v7_symbols_reference.txt --
# `; call ApplyProgramChangeAs_Prologue2 (v7 addr)` on bytes 1d 43 df fe
# (absolute target 0xFEDF43) actually names MidiRingBuf_WriteByte
# (ApplyProgramChangeAs_Prologue2 is really at 0xFEE35D); `; call
# Audio_CheckSubsystemReady (v7 addr)` on 1d 9e d6 fd (target 0xFDD69E) --
# the real Audio_CheckSubsystemReady is at 0xFDDAB8, and 0xFDD69E has no
# symbol at all; `; call AddswbWr (v7 addr)` on 1d 53 aa fd (target
# 0xFDAA53) -- the real AddswbWr is at 0xFDAE6D. None of the three
# comments name the routine actually at the encoded address. This does NOT
# make the CONVERSION unsafe -- build_replacement decodes the raw ROM
# bytes only, never reads the comment text, and the byte gate + call-target
# corroboration both check the real thing -- but it does mean this tool
# throws the wrong comment away rather than preserving it, which is the
# right call: keeping a verified-wrong label would be worse than dropping
# it. Left as a finding for whoever generated `(v7 addr)` originally to
# investigate; not this lane's tool to fix retroactively everywhere it
# still stands unconverted.
BYTE_RE_CALL_ADDR_COMMENT = re.compile(
    r'^\s*\.byte\s+((?:0x[0-9a-fA-F]{2}\s*,?\s*)+);\s*call\s+\S+\s*\(v7 addr\)\s*$')


def is_near_uniform_run(raw, byte_frac=0.4, min_len=3):
    """2026-09-02: a run of a single repeated byte (or dominated by one
    byte value) can decode as a chain of identical, perfectly-spellable,
    byte-round-tripping instructions -- 0xFF repeated is `swi 7` repeated,
    and a lane elsewhere in this push found a converter about to turn 55 of
    64 B of pure padding into a fake program this exact way. Context
    tiling and looks_like_a_table_tail() do not catch it: the run re-
    encodes byte-exact (so tiling "succeeds" the same way real code does),
    and looks_like_a_table_tail's periodicity window reaches back up to
    150 B into whatever precedes the run, which for a short island is
    mostly real established CODE -- diluting a short uniform run's own
    repetition below the window-level threshold. This checks the
    candidate's OWN bytes directly, no window, no context: any run at
    least `min_len` bytes long where a single byte value accounts for
    `byte_frac` or more of it is treated as data regardless of how cleanly
    it decodes. Runs shorter than min_len are left to the other checks --
    at that length "one byte value repeats" is not yet a meaningful signal
    (e.g. a single legitimate 2-byte instruction with equal operand
    bytes)."""
    if len(raw) < min_len:
        return False
    common = Counter(raw).most_common(1)[0][1]
    return (common / len(raw)) >= byte_frac


def collect_span(lines, start_idx, size):
    i = start_idx
    collected = 0
    n_lines = 0
    while i < len(lines):
        m = BYTE_RE.match(lines[i]) or BYTE_RE_CALL_ADDR_COMMENT.match(lines[i])
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
    ap.add_argument('--start', type=int, default=0,
                     help='slice the candidate list (sorted by ROM address) '
                          'starting at this index, BEFORE the expensive '
                          'per-candidate unidasm classification loop -- '
                          'unlike --limit, which only trims the ALREADY-'
                          'classified accepted list.')
    ap.add_argument('--count', type=int, default=None,
                     help='classify at most this many candidates from '
                          '--start onward (default: all remaining).')
    ap.add_argument('--max-size', type=int, default=63,
                     help='exclude any candidate run LARGER than this '
                          '(default 63 = the <64 B "island" shape this '
                          'lane owns, per the 2026-09-01 brief -- v7\'s '
                          '>=64 B code-flanked runs are the CONFIRMED-'
                          'REGION shape owned by a sibling lane\'s '
                          'judge()/worklist pipeline, w7/v7regions2. '
                          'Without this cap the unbounded byteblob scan '
                          'below picks up ~876 of those too, which would '
                          'double-count / collide with that lane\'s '
                          'territory -- the same trap the census tool\'s '
                          'own --max-island flag exists to avoid.')
    a = ap.parse_args()

    terr, blobs, rom = load('v7', a.work)
    tmp = tempfile.NamedTemporaryFile(suffix=".bin", delete=False).name

    isl_all = sorted(
        (b for b in blobs if b["kind"] == "byteblob" and 0 < b["start"]
         and b["end"] < SIZE and terr[b["start"] - 1] == 1 and terr[b["end"]] == 1
         and b["size"] <= a.max_size),
        key=lambda b: b["start"])
    isl = isl_all[a.start:a.start + a.count] if a.count else isl_all[a.start:]
    print(f"v7: {len(isl_all):,} code-flanked byteblobs total (<= {a.max_size} B, "
          f"this lane's island territory); classifying slice "
          f"[{a.start}:{a.start + len(isl)}) = {len(isl):,}")

    excluded_names = set(a.exclude_file)
    excluded_count = excluded_bytes = 0
    accepted = []
    counts = {}
    table_tail_rejects = 0
    uniform_rejects = 0
    for b in isl:
        if os.path.basename(b["file"]) in excluded_names:
            excluded_count += 1
            excluded_bytes += b["size"]
            continue
        raw = rom[b["start"]:b["end"]]
        if is_near_uniform_run(raw):
            uniform_rejects += 1
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
    print(f"   ({uniform_rejects} rejected outright as a near-uniform byte "
          f"run -- see is_near_uniform_run, never reaches unidasm)")
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
