# dispatch_table_census -- the instrument behind docs/coverage/

The disassembly-completeness spec (`docs/DISASSEMBLY-COMPLETENESS-SPEC.md`, L2) says every entry point
must be known, including the ones reached only through jump tables or computed jumps. These two scripts
measure how far the jump and call tables are from that, in every image of both models. The policy is
CLAUDE.md "Code-Coverage Evidence Ledger".

| script | what question it answers | how to run (repository root) |
|---|---|---|
| `build_maps.py` | For every byte of each image, which source line emits it, what kind of line it is, and which ELF symbols sit where? It reuses `scripts/analysis/data_range_census.py`'s marked-mirror instrument unchanged, and refuses an image whose mirror does not rebuild byte-identical. | `python3 scripts/analysis/dispatch_table_census/build_maps.py` (~2 min, 11 images) |
| `census.py` | For each jump/call table, does every entry that points into code land on a labelled, disassembled instruction, spelled symbolically? Which tables do not, and what blocks their targets? The table detectors, target classes and blocker rules are in its docstring. | `python3 scripts/analysis/dispatch_table_census/census.py --report` (also `--top`, `--list KEY`, `--snapshot DIR`, `--compare FILE.json`) |

`make dispatch-census` runs all three steps: build the maps, compare with the newest committed snapshot
(exit 1 if anything rose), and write today's snapshot into `docs/coverage/`.

Scratch (maps, mirrors, ELFs, about 0.5 GB) goes to `$DISPATCH_CENSUS_DIR`, or else
`$TMPDIR/dispatch-table-census`. Nothing is written inside the repository except by `--snapshot`. The
scratch can be regenerated, so delete it when you are done.

Known limits. These are stated so that a zero is never over-read:
- the counts are a lower bound;
- offset tables spelled as plain numbers, `addr24` bytecode, and tables whose every target is undecoded
  are not detected;
- unframed runs carry about 10% false positives, which the null-control column measures;
- the code-table test leaves out record tables whose pointers are mostly data.
