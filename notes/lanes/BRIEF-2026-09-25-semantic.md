# Lane brief — SEMANTIC push, 2026-09-25

Standing rules for every lane of the push toward **fully semantic disassembly of all
ROMs of all models** (KN5000 maincpu v7/v9/v10, subcpu v142 + boot, table data,
custom data, HD-AE5000; SX-WSA1R prom_a..d).  It supersedes the GOAL section of
`BRIEF-2026-09-01.md` (which deferred naming); every REPO-DISCIPLINE, ENCODING and
TOOLING warning in that brief still applies and is not repeated here — read it.

## What changed since the territorial push

Territorial coverage is essentially done: 13/13 images byte-identical, zero verbatim
debt outside v7 (120,666 B of romslices) and table data's six shipped BMPs.  What is
missing now is UNDERSTANDING, measured by these instruments (baseline 2026-09-25):

| instrument | what it counts | baseline |
|---|---|---|
| `scripts/analysis/data_range_census.py` | every byte as CODE / KNOWN-A (header says what the data IS and cites evidence) / KNOWN-B (descriptive name only) / UNKNOWN / FILLER | strict (CODE+A+FILLER) 64.15 %; KNOWN-B 4,428,351 B; UNKNOWN 12,050 B |
| same, `RESEARCH TARGETS` block | ranges whose purpose is not established: self-admitted, embedded-in-code, no explanation | 398,720 B |
| numeric branch operands | `jr z, 17`, `calr 2716`, `call 16569399` -- policy says all cross-refs symbolic | ~75,000 sites; converted by `scripts/converters/symbolize_numeric_branches.py` |
| data-as-code markers | halt / incf / decf / ldf / normal / max / min / `swi` (0xFF decodes as `swi 7`) / `jr cc,0` / nop-nop / stray `reti` inside "code" | v10 4,924, v9 15,938, v7 12,568 |
| `scripts/analysis/kn5000_source_coverage.py` | verbatim `.incbin` debt | v7 120,666 B |

## The semantic standard (what "done" means for a region)

1. **Code** is instructions, every cross-reference symbolic, every routine labelled
   with a name that says what it does, with a header when the name alone is not
   enough (inputs, outputs, side effects, callers).
2. **Data** is typed (`.long <symbol>` for pointers, `.ascii`/`.asciz` for text,
   `.short`/`.long` for words, `.byte` only for genuine bytes) and every object has
   a label naming WHAT IT IS plus a header that says **what it represents and how
   we know**: the reader routine by NAME and ADDRESS, the record layout
   (stride, fields at `+0xNN`), the entry count and how it was pinned.  That is what
   KNOWN-A means; the census recognises it, but the census is a heuristic -- the
   real test is the project owner's: *can a reader say what these bytes represent?*
3. **Assets** (bitmaps, fonts, compressed streams) are built from a readable form
   with a round-trip, or are the shipped artefact in its best form (a real BMP).
4. **Nothing is invented.**  An honest "purpose not established: <what was tried>"
   is a correct result.  A plausible-sounding header without a cited reader is a
   defect, and it is worse than the gap it hides, because the census will then
   stop pointing at it.  Keep admissions that are still true.

## Work types, in the order a lane should prefer them

* **Data-as-code retirement.** A region whose "instructions" are absurd (see the
  markers above) and/or whose branch targets land mid-instruction is data.  Find
  its reader (who loads its address), derive the record layout from the reader,
  and re-express it as typed data.  Byte gate + the absurd-marker count dropping
  are the evidence.  ⚠ Check that nothing CALLS or JUMPS into it before retyping.
* **Code-as-data conversion.** A `.byte` run that something branches into (the
  symboliser reports these as `boundary-data` "Entry" targets and the census as
  `embedded-in-code` / `code-suspect`) is code.  Decode it (`../tools/unidasm`,
  llvm-mc round trip), write instructions with symbolic operands, byte gate.
  Evidence standard: clean decode at the claimed start, branch targets on
  instruction boundaries, ≥1 call target that is an independently known label, and
  the same bytes NOT decoding cleanly at start+1.
* **Research targets** in your files: establish purpose with evidence or record
  precisely what was tried.
* **Evidence headers** for KNOWN-B objects in your files: find the reader, write
  the header.  Big objects first (bytes are the unit).
* **Naming**: labels the symboliser created are STRUCTURAL (`_Skip`, `_Join`,
  `_Loop`, `_Sub`, `_Return`, `_Epilogue`, `_Entry`).  Rename them to semantic
  names where you understand the code -- especially `_Sub` (an unnamed subroutine)
  and code sitting under data-shaped names (`*_Data`, `*_ByteBlock*`,
  `*_DataBlock*`), which are routines nobody has named.

## Multi-version rule (CLAUDE.md policy 9)

A lane owns a FILE SET across **all versions** (`v10/`, `v9/`, `v7/` copies of the
same path).  Whatever you establish in one version, apply to the others where the
same code/data exists.  v10 is usually the best-understood; port its typed forms
to v9/v7 (symbolic assembly absorbs address deltas).  Never touch a file outside
your set; if your work needs a change elsewhere, say so in your report.

## Mechanics

* Work ONLY in your worktree (`/home/fsanches/compartilhado/disasm-lanes/<lane>`,
  branch `<lane>`), created for you from `main`.  Prefix every shell command with
  `cd <worktree> &&` -- your shell does not start there.
* Do NOT touch: `symbols/*`, `.beads/issues.jsonl`, `CHANGELOG.md`, the Makefile,
  shared scripts other lanes use (add new scripts instead), `../technics-docs`.
  Symbol files are regenerated centrally after integration.
* Edit `.s` files with explicit latin-1 I/O (Python `encoding='latin-1'` or
  bytes).  The Edit tool is acceptable only if you verify the diff size is what
  you intended.  Use `command grep` (or `grep -a`) for searches.
* Re-run the branch symboliser on your own files after converting code:
  `python3 scripts/converters/symbolize_numeric_branches.py --image v10 --only <file>[,<file>] --apply --verify`
* Gate: `make gate` (KN5000) or `make gate-wsa1` (WSA1-only lanes) in your
  worktree must be green before every commit.  Show the gate can fail on your
  edit once (perturb one byte, see red, restore).
* Measure your files before and after: `python3 scripts/analysis/data_range_census.py
  --images <keys> --json <scratch>/<lane>/x.json` and report UNKNOWN / research
  target / KNOWN-A / KNOWN-B bytes for YOUR files, plus the absurd-marker and
  numeric-branch counts.
* Commit early and often on your branch with the `LLVM:` trailer
  (`cd ~/compartilhado/llvm-project && git log -1 --format="%D @ %h (%H)"`,
  written as `LLVM: tlcs900_backend@<short> (<full>)`).  Never push.  Never
  `git add -A` or a directory; name files.
* If a finding deserves prose, write it to `notes/FINDINGS-<lane>-<topic>.md` in
  your worktree (a new file, so lanes never collide), and commit any script that
  produced a number you quote next to it.

## Report

Return: commits (hash + one line), per-file before/after figures, what you could
NOT do and why, and leads for the next wave.  Figures you did not measure are not
figures.
