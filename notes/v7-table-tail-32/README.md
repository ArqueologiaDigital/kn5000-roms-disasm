# Lane V7TABLETAIL -- adjudicating the 32 table-tail-guard-excluded regions

QUESTION ANSWERED: of the 135 v7 code-shaped `.byte` regions that
`fill_verified_islands.looks_like_a_table_tail()` rejects even though their
whole-region CODE/DATA rule fires, which are genuine CODE the guard is wrong
about, and which are genuine DATA tables the guard is right to protect?

This lane's specific target is the 32-region, 14,311 B subset that ALSO has
100% call-target corroboration (every absolute `call` inside the region
resolves to a routine already named in `symbols/maincpu_v7_symbols_reference.txt`)
-- the shape most likely to be real code the guard's 150-byte tail window
was fooled by, per the lane brief.

## How the 32 were selected

    python3 scripts/analysis/v7_region_worklist.py --work WORKDIR
    # then filter: table_tail_reject == True and n_calls > 0 and n_call_hits == n_calls

`regions.json` is that filtered list (32 regions, 14,311 B), reconstructed
from a `v7_region_worklist_remaining2.json` produced earlier this session by
a sibling lane's `--prepare`/`--census`/`--judge` run (cached under this
session's scratchpad, not in this worktree).

## Files, in the order the adjudication pipeline used them

* `regions.json` -- the 32 target regions (addr, size, and the CACHED
  file/line hint, which the brief warned may have shifted).
* `v7tabletail_line_probe.py` (in `scripts/analysis/`) -- ground-truths
  every region's CURRENT source location by address, not by the cached
  line hint. Run: `python3 scripts/analysis/v7tabletail_line_probe.py --build`
  (writes the gitignored `line_probe_cache.json`, ~20s), then
  `--lookup-file lookup_ranges.txt` (one `lo hi` pair per region, hex).
* `lookup_ranges.txt` / `lookup_results.txt` -- the probe's input/output.
* `file_line_candidates.json` -- one (file, guess_line) candidate per
  region, disambiguated against the ORIGINAL cached hint when the probe
  found more than one file sharing a region's start address (this happens
  when a zero-byte-emitting file, e.g. a run of `.macro` definitions, is
  `.include`d right at that boundary).
* `verified_spans.json` -- confirms EVERY one of the 32 candidates two ways
  at once: the line-probe's ground-truth address, AND independently
  re-deriving the exact same span by counting `.byte`/`.word`/... directive
  sizes forward from the candidate line
  (`convert_interrupted_region.find_span`). All 32 agreed exactly (OK).
  This file also carries every pre-existing label found inside each span --
  the single most useful piece of evidence in this lane's report, since
  several of those labels' names (`_Table`, `_DataBlock`, `..._Data`) turned
  out to be auto-generated guesses from `shared/positional_labels.s`
  ("Auto-generated positional labels for intra-block references"), not
  authoritative, and had to be independently checked against how (or
  whether) anything in the tree actually references them.
* `v7_tabletail_adjudicate.py` (in `scripts/analysis/`) -- per-region
  report: full disassembly, the exact 150-byte tail-window metrics the
  guard computed (reproduced against the ORIGINAL ROM dump, which is ground
  truth regardless of the current conversion state of the source), a
  fixed-stride record-signature probe (does any byte-phase have a >=60%
  dominant value, the fingerprint of the two known real data tables that
  fooled the 283-conversion batch this guard was built to stop), and
  32 B of raw context on both sides. Run:
  `python3 scripts/analysis/v7_tabletail_adjudicate.py --regions-json regions.json`
* `batch30.json` / `dryrun30.json` / `apply30.json` -- the 30 regions judged
  as clean, whole-region CODE (excludes the two regions requiring a
  head/tail split, `0xF640FB` and `0xFD0588`, handled by hand -- see the
  lane's final report for the full per-region verdict table), run through
  `scripts/converters/run_v7_worklist_batch.py` in dry-run then `--apply`
  form.

## Reproducing the headline numbers

    python3 scripts/analysis/v7tabletail_line_probe.py --build
    python3 scripts/analysis/v7tabletail_line_probe.py --lookup-file notes/v7-table-tail-32/lookup_ranges.txt \
        > notes/v7-table-tail-32/lookup_results.txt
    python3 scripts/analysis/v7_tabletail_adjudicate.py --regions-json notes/v7-table-tail-32/regions.json

Then, for the narrow gate:

    LLVM_BIN=~/compartilhado/llvm-project/build/bin
    make rebuilt_ROMs/kn5000_v7_program.llvm.rom \
        LLVM_MC=$LLVM_BIN/llvm-mc LLVM_LLD=$LLVM_BIN/ld.lld LLVM_OBJCOPY=$LLVM_BIN/llvm-objcopy
    cmp rebuilt_ROMs/kn5000_v7_program.llvm.rom original_ROMs/kn5000_v7_program.rom
