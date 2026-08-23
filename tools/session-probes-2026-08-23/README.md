# Session probe archive — 2026-08-23

**These are session scratch, preserved wholesale. They are not curated tools.**

The curated, README'd, reproducible probes live in `tools/spelling-probes/`,
`tools/byte-run-placement/` and `scripts/analysis/`. **Prefer those.** If a probe here
turned out to matter, the right move is to rewrite it properly over there and delete it
from this directory — not to grow this one.

## Why this exists

The global rule is that a number worth writing down is worth committing the thing that
produced it. These 40 scripts ran during the 2026-08-23 disassembly session — the pass
that closed v7 from 136,782 divergent bytes to 0 — and I could not establish, script by
script, which of them fed a figure that ended up in a commit message or a notes file.

Rather than assert coverage I had not checked (I did exactly that earlier in the session
and was wrong: I claimed 53 of 54 scratch scripts had committed counterparts; a proper
sequence-similarity sweep against all 1,221 committed scripts, calibrated against a null
of 328 unrelated pairs, found **8**), everything unmatched is preserved here as-is.

Method, for the record: `difflib.SequenceMatcher.ratio() >= 0.80`. The null matters —
`quick_ratio()`, which I reached for first, scores 11.3% of *unrelated* committed script
pairs above that same threshold (max 0.89), so it cannot discriminate and its results were
discarded. Real `ratio()` scored 0 of 328 unrelated pairs above 0.80 (median 0.02).

## Caveats — read before trusting anything here

- **No pass criteria.** Most print numbers without saying which value means pass.
- **Hard-coded paths** to `technics_roms`, the v7/v9/v10 trees and the LLVM build.
- **Some are wrong.** These include probes whose bookkeeping defects produced clean but
  false disqualifications during the session (duplicated globs, scoring one revision's
  blobs against another's symbol table, a `DATA = 0` constant against a 1/2/3 territory
  encoding). They are kept as history, not as evidence.
- **Not run at archive time.** Unlike `tools/rom-record-review/`, nothing here was
  re-executed before committing.

## Reproducing the sweep

    python3 match_scratch_to_committed.py <scratch-dir>          # the census
    python3 match_scratch_to_committed.py <scratch-dir> --null   # the calibration

## Contents

| script | first docstring / comment line |
|---|---|
| `align.py` | Content-align each refused v7 range onto v9/v10 and read off THEIR framing. |
| `align2.py` | Content-align each refused v7 range onto v9/v10 and read off THEIR framing. |
| `bound.py` | — |
| `census.py` | — |
| `census313.py` | Reproduce v7_label_guard_subjects.py's 313-label census, then apply the same drift / provenance tests to the WHOLE population, and separate it from the 33 ranges that actually reach rewrite(). |
| `check_sites.py` | Which sites of the two assigned forms does the converter FAIL to spell? |
| `collect.py` | Collect, per range, everything rewrite() saw when it declined for a label. |
| `control.py` | CONTROL: is "v7 gap == v9 gap" special to the blocking labels, or universal? |
| `dbg.py` | — |
| `decide.py` | Per range: is the DECODE mis-framed, or is the LABEL wrong? |
| `dump.py` | — |
| `dump_all.py` | EVERY site of `push r` / `or (imm),r` in the reachable-range decodes, whether or not an earlier unspellable instruction currently masks it, plus the proposed spelling's encoding from llvm-mc. |
| `dump_sites.py` | Dump every BLOCKING site of the forms `push r` and `or (imm),r`. |
| `dump_sites2.py` | Blocking-site dump for chosen forms, mirroring convert_reachable_ranges.main() exactly (branch resolution included, same acceptance gates). |
| `evidence.py` | Per-range evidence for the label-guard bucket. |
| `ex2.py` | bucket1 breakdown by n_insns and stop |
| `ex3.py` | stop reasons |
| `ex4.py` | For overhang cases: does dropping the last insn give span==runfull? |
| `ex5.py` | db byte census + retry with 64 ROM bytes ignoring territory |
| `explore.py` | sample a few bucket-1 members |
| `final.py` | Union of independent corroborations, per range, and the residue. |
| `find_sites.py` | Locate every site of `djnz r,imm` and `ld (r+),r` in the v7 reachable ranges. |
| `fixlc.py` | Define the .Lc_ labels that are referenced but never emitted. |
| `flatten.py` | Instruction-start map for a whole source tree, by flattening it through llvm-mc. |
| `frame.py` | A self-check a MIS-FRAMED decode cannot fake: does the stack frame balance? |
| `measure.py` | Measure what the two proposed spellings are worth, WITHOUT editing any source. |
| `mydjnz.py` | assemble to object, extract .text bytes |
| `null.py` | NULL for the drift figure. |
| `place3.py` | Place three badly-misplaced labels by anchoring on a NEARBY named symbol. |
| `replace_lc.py` | Move my mis-placed .Lc_ labels to the addresses their names encode. |
| `replay.py` | INDEPENDENT patched replay. Monkey-patches in memory only; touches no file. |
| `run_census.py` | — |
| `run_census_seed.py` | force the SEED target list (687) by hiding the closure file from os.path.exists |
| `site.py` | — |
| `spacing.py` | Where do the v7 label OFFSETS come from? Compare them to v9/v10 spacing. |
| `tried.py` | — |
| `unnamed.py` | How many of the 170 'a branch target cannot be named' skips would be named if the blocking labels sat on the instruction boundary they drifted off? |
| `v9cross.py` | Cross-check every blocking label against v9/v10, where the same name IS code. |
| `verify.py` | For every site of `push r` / `or (imm),r`: does the CURRENT converter spell it? If not, does the PROPOSED spelling assemble to the ROM bytes exactly? |
| `verify_ldmm.py` | PROPOSED RULE for `ldw (imm),(imm)` / `ld (imm),(imm)`: offer the ldmm family and let the ROM bytes choose. Verifies each candidate against the ROM bytes dumped at the site, exactly as convert_reachable_ranges.py would. |
