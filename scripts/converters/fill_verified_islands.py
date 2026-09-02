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

⚠ 2026-09-02: CONTEXT-TILING + FILE-LEVEL EXCLUSION WAS STILL NOT ENOUGH.
  A first pass excluded 7 files independently identified as DATA tables by
  their header comments, then applied 283 "context-verified, fully
  spellable" runs (1,136 B) across the other 60+ files. A post-hoc audit of
  the diff -- listing every hunk's ENCLOSING LABEL and eyeballing the
  surrounding bytes -- found at least two confirmed wrong conversions that
  slipped through, in files that were NOT data-table files overall and
  were NOT on the exclude list:
    - `TuningSystem_Handler_Table` (sound_editor_ui.s): a genuine tuning
      table, `ldwio 10, N` / `ordm16_24 (M), xde` records with N stepping
      by 40 and M by 10240 -- an arithmetic progression across SEVERAL
      neighbouring "instructions", not real code.
    - `SeBitmap_EnvCurve5` (sound_editor_ui.s): a 5-record envelope-curve
      table shaped `{byte, 0x17, 0xf1}` with the first byte stepping by 12;
      only the LAST record happened to sit next to genuine code, so it
      alone (not its four identical-shaped siblings, which weren't even
      CODE-flanked) passed the context-tiling check.
  Both were reverted (see the git history around 2026-09-02 on this
  branch). The common shape: a repeating fixed-width DATA record whose
  LAST instance happens to abut real code -- the run "tiles from context"
  correctly by construction (a real instruction genuinely does start
  where the code resumes), but the run itself is still a data record, not
  an instruction. Neither the context-tiling check nor grepping the
  mnemonic family's existing usage elsewhere in the tree (which both of
  these also passed -- `ldwio`/`ordm16_24`/`ldf` are all real, pre-existing
  mnemonics) can catch this; it needs a check that looks WIDER than the run
  itself. `looks_like_a_table_tail()` below is that check, added after this
  incident: it reuses v9_v10_undisassembled_census.py's own calibrated
  CODE/DATA rule (the `per%` term specifically -- "fixed-width records
  score high" -- catches exactly this shape) over a window that spans the
  run AND back into whatever precedes it. It is a NEW, UNTESTED mitigation
  as of this writing -- treat its "false" (not-a-table) verdict as raising
  confidence, not as proof, and still spot-check the diff by enclosing
  label and byte pattern before trusting a large batch.

RUN
    python3 scripts/converters/fill_verified_islands.py v10 --work WORKDIR \
        [--exclude-file NAME.s ...] [--only-tag] [--apply] [--limit N]

  Dry run by default. --apply writes to both v9 and v10 (after asserting
  their ROM bytes at each address match, same discipline as
  convert_region.py) and re-derives each blob's own file/line straight from
  the census's marker data (each island blob's line is ITS OWN precise
  start, unlike judge()'s coarser "nearest .byte-kind blob in this region"
  display heuristic -- no rewind-to-true-start needed here). Files are
  patched one at a time, highest line number first, so an earlier edit in a
  file never invalidates a not-yet-applied blob's line number in the same
  file. --only-tag applies to just --tag (v10 is the priority image per the
  project owner as of 2026-09-02); v9 and v10 name their top-level file
  differently (kn5000_v9_program.s vs kn5000_v10_program.s), handled
  explicitly rather than assuming an identical relpath.

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
sys.path.insert(0, str(REPO / 'scripts' / 'analysis'))
import convert_code_bytes as cb
from convert_interrupted_region import build_replacement
from v9_v10_undisassembled_census import metrics as census_metrics, rule as census_rule

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


def looks_like_a_table_tail(rom, end, tmp, window=150):
    """2026-09-02: bounds_from_context() alone was fooled twice in the same
    session -- a 5-record envelope-curve table (SeBitmap_EnvCurve5, records
    shaped {byte, 0x17, 0xf1} with the first byte stepping by 12) and a
    tuning table (TuningSystem_Handler_Table, `ldwio 10, N` / `ordm16_24
    (M), xde` with N stepping by 40 and M by 10240) BOTH had their LAST
    record sit right next to genuine code, so the run "tiled cleanly from
    context" even though it was really the tail of a repeating DATA record,
    not an instruction. bounds_from_context() only looks at whether the
    boundary lands correctly; it has no opinion on whether the bytes are
    plausible code at all.

    This reuses v9_v10_undisassembled_census.py's OWN calibrated CODE/DATA
    rule (db% / per% / ramp% / dist, calibrated there against 300 real CODE
    and 300 real .incbin DATA windows) over a window ending at this run's
    end and reaching back up to `window` bytes -- deliberately spanning
    BOTH the run and whatever precedes it, regardless of that precedent's
    own terr classification, because a repeating record's periodicity only
    shows up once several records are in view. `per% <= 20` is the specific
    term that catches fixed-width records (the rule's own calibration note:
    "fixed-width records score high" on this metric). Returns True (i.e.
    REJECT the candidate) when the window fails the rule.
    """
    off = max(0, end - window)
    m = census_metrics(rom, off, end - off, tmp)
    return not census_rule(m)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('tag', choices=['v9', 'v10'])
    ap.add_argument('--work', required=True)
    ap.add_argument('--apply', action='store_true')
    ap.add_argument('--limit', type=int, default=None)
    ap.add_argument('--exclude-file', action='append', default=[],
                     help='basename (repeatable) to skip entirely -- for a '
                          'file independently identified as a DATA table '
                          '(patch/preset/dispatch records). Even with that, '
                          'looks_like_a_table_tail() and manual review of '
                          'every hunk remain necessary -- see the 2026-09-02 '
                          'note in this file\'s docstring: exclude-by-file '
                          'and the context-tiling check TOGETHER still let '
                          'two real data tables through in files that were '
                          'NOT on any exclude list.')
    ap.add_argument('--only-tag', action='store_true',
                     help='apply ONLY to --tag, skip mirroring to the other '
                          'image even when its bytes match (v10 is the '
                          'priority image; use this to finish v10 without '
                          'spending time/risk verifying v9 too).')
    a = ap.parse_args()

    terr, blobs, rom = load(a.tag, a.work)
    tmp = tempfile.NamedTemporaryFile(suffix=".bin", delete=False).name

    isl = [b for b in blobs if b["kind"] == "byteblob" and 0 < b["start"]
           and b["end"] < SIZE and terr[b["start"] - 1] == 1 and terr[b["end"]] == 1]
    print(f"{a.tag}: {len(isl):,} code-flanked byteblobs to classify")

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

    total_applied = 0
    for relpath, items in by_file.items():
        items.sort(key=lambda t: -t[0]["line"])  # highest line first
        p9 = REPO / a.tag / relpath
        other_tag = None if a.only_tag else ('v10' if a.tag == 'v9' else 'v9')
        # the top-level program file is named kn5000_<tag>_program.s -- the
        # basename itself differs between v9 and v10, not just its content
        other_relpath = relpath.replace(f'kn5000_{a.tag}_program.s',
                                        f'kn5000_{other_tag}_program.s') if other_tag else relpath
        p_other = (REPO / other_tag / other_relpath) if other_tag else None
        if other_tag and not p_other.exists():
            print(f"SKIP {relpath} entirely -- no {other_tag} counterpart at "
                  f"{other_relpath} (unexpected path divergence)")
            continue
        lines_self = p9.read_text(encoding='latin-1').split('\n')
        lines_other = p_other.read_text(encoding='latin-1').split('\n') if p_other else None
        applied_here = 0
        for b, nl in items:
            addr, size = b["start"], b["size"]
            if other_tag and rom_v9[addr:addr + size] != rom_v10[addr:addr + size]:
                print(f"SKIP {relpath}:{b['line']} {BASE+addr:#x} -- v9/v10 ROM differ here")
                continue
            start_idx = b["line"] - 1
            collected, n_lines = collect_span(lines_self, start_idx, size)
            if collected != size:
                print(f"SKIP {relpath}:{b['line']} -- collected {collected}B, expected {size}B")
                continue
            end_idx = start_idx + n_lines
            if other_tag:
                # same span in the other tag's file, by matching line number
                # (both trees are lockstep at this point in the file for a
                # not-yet-touched region -- verified by the raw ROM equality
                # check above, which is the authority; line-count is a guard)
                ocollected, on_lines = collect_span(lines_other, start_idx, size)
                if ocollected != size or on_lines != n_lines:
                    print(f"SKIP {relpath}:{b['line']} -- {other_tag} span mismatch "
                          f"({ocollected}B/{on_lines}L vs {size}B/{n_lines}L)")
                    continue
                lines_other[start_idx:end_idx] = nl
            lines_self[start_idx:end_idx] = nl
            total_applied += size
            applied_here += 1
        p9.write_text('\n'.join(lines_self), encoding='latin-1')
        if p_other:
            p_other.write_text('\n'.join(lines_other), encoding='latin-1')
        print(f"applied {relpath}: {applied_here}/{len(items)} run(s)"
              + ("" if other_tag else f" ({a.tag} only)"))

    print(f"TOTAL applied: {total_applied:,} B")


if __name__ == '__main__':
    main()
