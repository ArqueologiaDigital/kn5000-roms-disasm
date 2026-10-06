# dispatch_table_census -- the instrument behind docs/coverage/

The disassembly-completeness spec (`docs/DISASSEMBLY-COMPLETENESS-SPEC.md`, L2) says every entry point
must be known, including the ones reached only through jump tables or computed jumps. These two scripts
measure how far the jump and call tables are from that, in every image of both models. The policy is
CLAUDE.md "Code-Coverage Evidence Ledger".

| script | what question it answers | how to run (repository root) |
|---|---|---|
| `build_maps.py` | For every byte of each image, which source line emits it, what kind of line it is, and which ELF symbols sit where? It reuses `scripts/analysis/data_range_census.py`'s marked-mirror instrument unchanged, and refuses an image whose mirror does not rebuild byte-identical. | `python3 scripts/analysis/dispatch_table_census/build_maps.py` (~2 min, 11 images) |
| `census.py` | For each jump/call table, does every entry that points into code land on a labelled, disassembled instruction, spelled symbolically? Which tables do not, and what blocks their targets? Which tables are stale, i.e. not this build's entry points? The table detectors, target classes, blocker rules and the STALE rule are in its docstring. | `python3 scripts/analysis/dispatch_table_census/census.py --report` (also `--top`, `--list KEY`, `--stale KEY`, `--unresolved KEY`, `--snapshot DIR`, `--compare FILE.json`, `--selftest`) |

`make dispatch-census` runs all three steps: build the maps, compare with the newest committed snapshot
(exit 1 if anything rose), and write today's snapshot into `docs/coverage/`.

Scratch (maps, mirrors, ELFs, about 0.5 GB) goes to `$DISPATCH_CENSUS_DIR`, or else
`$TMPDIR/dispatch-table-census`. Nothing is written inside the repository except by `--snapshot`. The
scratch can be regenerated, so delete it when you are done.

Known limits. These are stated so that a zero is never over-read:
- the counts are a lower bound;
- `addr24` bytecode, and tables whose every target is undecoded, are not detected;
- 16-bit offset tables are found two ways: O by their `.short Sym - Base` spelling, and D (since
  2026-10-06) from the `jp t, (xR+rr)` code that reads them, whatever the spelling. D sees only that
  compiled-switch shape (base, table and bound within 10 instruction lines). The sites it cannot read
  are counted in the `D-unres` column and listed by `--unresolved KEY`. Offsets are sign-extended, as the
  CPU does. A two-level switch is bounded by its byte map's largest entry. In v10, 99.8% of D's 2,642
  entries land on instruction starts. The other 4 are code spelled as text or bytes;
- unframed runs carry about 10% false positives, which the null-control column measures. Since 2026-10-06
  U also runs at stride 8, outside the stride-4 runs: one code pointer per 8-byte record. The KN5000
  control-panel action lists (`PanelButton_ActionListPool`) were found by hand first and were invisible at
  stride 4. Its first run found them, `SeqStep_TimerDispatch_ProcTables` in v10/v9/v7 and v7's
  `TimeSig_ProcTable`, and nothing in the stride-8 null control. Records with other strides (6, 10, 12,
  ...) are still not searched;
- the code-table test leaves out record tables whose pointers are mostly data.
- STALE (2026-10-06). A dead table cannot be made used, and labelling its targets would plant entry points
  inside instructions. Examples: an older build's table left in the image, or linker thunks whose targets
  moved. Such a table leaves NOT only when three things hold:
  1. its source carries a `; census: stale -- <why>` line, in the comment block nearest above the entry;
  2. at least one entry lands where no live pointer can, mid-instruction or in data;
  3. its distinct targets hit instruction starts no more often than chance (binomial, P >= 0.001
     against the local start density).
  It is then counted in the `stale` / `staleT` columns and listed group by group in every snapshot, so it
  never disappears. `--selftest` shows the third check rejecting a live-shaped group. It cannot catch a
  live table whose only problem is a misframed target in another image: the declaration's why text is the
  safeguard there, and the listing is how a reviewer reads it. The first WSA1 declarations are written by
  `wsa1/notes/census_stale_markers.py`.
