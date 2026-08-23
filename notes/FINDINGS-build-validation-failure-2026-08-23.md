# The byte gate was not validating anything, and v7 does not rebuild

Written 2026-08-23 at the end of a long session, because the numbers reported
during it rest on a gate that was not running.

## What happened

`scripts/analysis/assert_byte_identical.py` compared `rebuilt_ROMs/` against
`original_ROMs/` and **did not rebuild**. Its docstring said
`make all && python3 ...` — the rebuild was the caller's job. It was called
alone, by hand and by `tools/closure-loop.sh`, which had no `make` step.

The rebuilt ROMs were **three hours stale**. Across **106 commits**, every
"PASS: every rebuilt ROM is byte-identical" compared artefacts that no longer
corresponded to the sources.

Two build-breaking defects survived that window:

1. **41 names per revision** defined BOTH as a label (from the `.equ`→label
   conversion) and via a `.set` in another file — `llvm-mc: redefinition`. The
   label POSITIONS were correct: `NakaDbg_PanelSimTitle` (0xEB2AFE) + 0xCE0 =
   0xEB37DE, exactly the `.set`. The label was redundant, and is removed.
2. **17 `.Lc_` branch targets** referenced but never defined — ranges truncated
   after emitting a branch but before the instruction carrying its label.

Both are fixed; the tree compiles.

## The state now, measured on a genuine two-pass build

| target | result |
|---|---|
| `kn5000_v9_program` | **IDENTICAL** |
| `kn5000_v10_program` | **IDENTICAL** |
| `kn5000_subprogram_v142` | **IDENTICAL** |
| `kn5000_subprogram_v142_compressed` | **IDENTICAL** |
| `kn5000_table_data` | **IDENTICAL** |
| `kn5000_v7_program` | **136,782 BYTES DIFFER** |

The v7 divergence is ~7,120 scattered 1–2 byte runs, and every differing 16-bit
value is **exactly 0xD2 (210) lower** than the ROM's — the signature of a base
that moved by 210 bytes, with every reference following it.

⚠ **NOT established: whether this predates the session.** A two-pass worktree
build of `041daaa` (11:03, before most source edits) reports v7 1,161 / v9 2,216 /
v10 2,216 / subprogram 531 differing, with one target missing — i.e. that tree is
not clean either, but the worktree build did not complete, so those figures are
not trustworthy. What IS clear is that v9, v10 and both subprogram targets are
byte-identical NOW and were not in that worktree, so the session's work did not
break them.

## What is affected

**Unverified** — every byte count from a v7 source conversion this session: the
`.long` pointer-table conversions, the 11,007 label repositionings, the region
trimming, and the closure-loop CODE figures (614,404 → 623,403).

**Unaffected** — everything derived by reading ROM bytes or source text directly:
the NAKA record format and its 16 handlers, the `.LSW` container confirmed on 19
real panel memories, the `0x9A` resolution, the L2 structural-claim class, the
`0x41A` displacement and its independent semantic confirmation, the `grep`
binary-file exclusion.

## The fix that matters

The gate now runs `make all` itself and exits 2 with the build tail if it fails.
`--no-build` remains for a caller that has just built, and prints a warning.

**A gate whose precondition is supplied by the caller is a gate that will be run
without it.** This is spec anti-pattern 18 — "a failure that does not propagate" —
written the same morning it was then committed at scale.

## Next

1. Find the 0xD2 base shift in v7. Every differing value is a 16-bit field that is
   210 low, so one symbol or one blob boundary moved by 210 bytes.
2. Re-gate every v7 conversion from this session once v7 rebuilds clean, and
   correct the byte counts in `IS-IT-DONE.md` to whatever survives.

---

## v7 recovery: 136,782 -> 42,329, and exactly what is left

### The technique that made the error measurable

`.Lc_` labels are TEMPORARY symbols: llvm-mc never puts them in the symbol table,
so nothing could see where they actually landed. Renaming `.Lc_` -> `LcX_` makes
them ordinary symbols, and then

* the ELF gives each label's **actual** address, and
* the label's own name gives its **intended** address.

The error becomes exact. 523 labels, 47 wrong, deltas from -12 to +6,892.
`tools/spelling-probes/reposition_lc_labels.py` does the rename/build/measure/
move cycle; it sizes instruction lines by assembling them rather than giving up
at the first one, which is how the earlier attempt mis-placed a label by 542
bytes.

### Why a handful of labels cost six figures

A mis-placed branch target forces llvm-mc to relax `jr` (2 bytes) to `jrl` (3),
the block grows, and **every symbol after it shifts**. One label moved took
70,848 -> 42,078. The divergence was never 136,782 independent wrong bytes; it
was a handful of length errors and their cascade.

### What remains

Six shift points, cumulative +5:

| address | shift | cause |
|---|---|---|
| `0xFD0A3A` -> `0xFD0A76` | -3, then back | localised to 60 bytes; sizing the romslice at 50 instead of 47 made it WORSE, so the obvious reading is wrong and it is unexplained |
| `0xFE7680` | +2 | `.Lc_fe7680` is 2,932 bytes late |
| `0xFE99C2` | +2 | `.Lc_fe99a2` is 4,199 bytes late |
| `0xFEB976` | +1 | `.Lc_feb9ef` is 5,595 bytes late |

Those three cascade from `0xFE7680` to the ROM end and are most of the 42,329.
They cannot be walked into place -- the path crosses instruction lines the walker
can size but which would put the label mid-instruction -- and anchoring on the
nearest named symbol also fails for the same reason.

**The right fix for those three is not to move the label but to REVERT the
converted range that contains the branch**, back to a romslice. A range whose
branch target cannot be placed should never have been converted; that is what
the converter should have done, and it removes both the branch and the label.

31 further labels are mis-placed by -12..-7 and contribute wrong displacement
BYTES but no length change, so they are cosmetic against the byte gate until the
shifts are gone.
