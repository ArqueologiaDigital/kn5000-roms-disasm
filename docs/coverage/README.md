# docs/coverage -- the code-coverage evidence ledger

This directory holds the evidence for "every entry point is known": `DISASSEMBLY-COMPLETENESS-SPEC.md` L2,
"including those reached only through jump tables or computed jumps". The policy that governs it is
CLAUDE.md "Code-Coverage Evidence Ledger", and the instrument is `scripts/analysis/dispatch_table_census/`.

| file | what it is |
|---|---|
| `dispatch-census-YYYY-MM-DD.txt` | the census on that date: per image, tables found / used / NOT used, distinct unused targets, unframed runs, and the ten worst tables. Its first line names the commit it measured. |
| `dispatch-census-YYYY-MM-DD.json` | the same as numbers, plus every not-used table with its blockers, so two dates can be diffed (`census.py --compare`) |

Snapshots are never edited after they are committed. A new date is a new file.

## Reading a snapshot

- **used**: every code-pointing entry lands on a labelled, disassembled instruction and is spelled
  symbolically.
- **newT**: distinct targets in the same image that block a table:
  - `nolabel` / `midinsn` (a "hidden" routine, or an entry into the middle of an instruction);
  - `incbin*` / `databyte` / `text` / `dataother` (not disassembled).
- **newT(x)**: the same, for targets in another image.
- **spellT**: the target is labelled code but the entry is a number.
- **U**: unframed pointer runs found in `.incbin` / `.byte` / code bytes. **null** is the false-positive
  control for them.

## When full coverage may be claimed

Only on a committed snapshot whose every image shows NOT = 0, newT = newT(x) = spellT = 0 and U-NOT = 0,
together with the spec's other L1 / L2 measurements. The claim names the snapshot file and its commit.
A zero means "none that the census detects". The census's stated limits are part of the claim.
