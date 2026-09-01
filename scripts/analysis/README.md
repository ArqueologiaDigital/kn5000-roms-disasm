# Analysis scripts

## Added 2026-08-21 (completeness audit)

| script | question it answers |
|---|---|
| `verify_stale_band.py` | Is the "unreferenced residue" in style_records.s really a discarded predecessor? (No: it is the live help region copied 0x8000 lower, one byte different.) |
| `ic19_cell_grammar_probe.py` | Do the custom-data style banks parse under the documented demo-preset cell grammar? (Yes: 725/725 cells frame to 0x83.) |

    python3 scripts/analysis/verify_stale_band.py original_ROMs/kn5000_table_data.rom
    python3 scripts/analysis/ic19_cell_grammar_probe.py original_ROMs/kn5000_custom_data.ic19
| `rom_provenance_poison.py` | Does the build READ the ROM it claims to reconstruct? (v7: 46.69% copied. v9/v10: clean.) |

    python3 scripts/analysis/rom_provenance_poison.py all


## Added 2026-08-21 (completeness audit, second pass)

Written while re-testing "is the disassembly done?" against
`docs/DISASSEMBLY-COMPLETENESS-SPEC.md`. Each one is a check that CAN FAIL, and
each exits non-zero when it does — a criterion that cannot fail is not a pass.

| script | question it answers |
|---|---|
| `l1_territory_map.py` | Is every byte of the rebuilt ROMs classified CODE/DATA/PADDING? (Yes — and the classified total must equal the ROM size exactly, so a mis-sized directive or mis-decoded octal escape cannot pass silently.) |
| `l2_symbol_reference.py` | Do the committed symbol reference files agree with the build? (They did not: all five were stale, `table_data` matching on 1 row of 4,689. Regenerated from the ELFs, now 100%.) |
| `l2_name_vs_fopen_mode.py` | Does a routine's NAME agree with the file mode it opens? (57 sites, 3 flagged, 2 false positives on inspection, 1 genuine: `LoadFileVariant` passes `"wb"`.) |
| `v7_undisassembled_spans.py` | Where is v7's disassembly thinner than v9's? (258 spans, 158,902 bytes that v7 carries as data and v9 disassembles as code.) |
| `llvm_missing_instruction_forms.py` | Why is so much of v7 still `.byte`? (Because llvm-mc rejected the instructions — see below.) |
| `l2_positional_breakdown.py` | How many positional names are actually a problem? (3,285 of 3,627 are sub-labels of a NAMED parent and are fine; only 342 are unattached.) |
| `v7_reachable_from_code.py` | Which v7 `.byte` regions are CALLED by code the disassembly already expresses? (808 call targets; 69 open with a stack-frame prologue.) |
| `v7_unspellable_forms.py` | Which instruction forms block conversion, and how many instances each? (9,463 — led by `jr r,imm` at 2,106, which cannot be spelled numerically at all.) |
| `lsw_saveall_table.py` | Does the KN5000 firmware handle `.LSW`? (YES. It is file type 0, with a handler in every revision. An earlier doc claim that it never does was a string-search artefact and is retracted.) |

    python3 scripts/analysis/l1_territory_map.py v7 v9 v10
    python3 scripts/analysis/l2_symbol_reference.py              # add --regen to rewrite
    python3 scripts/analysis/l2_name_vs_fopen_mode.py            # add --all to list every site
    python3 scripts/analysis/v7_undisassembled_spans.py --top 15 --disasm 3
    python3 scripts/analysis/llvm_missing_instruction_forms.py v7/maincpu/midi/midi_dispatch_handlers.s
    python3 scripts/analysis/l2_positional_breakdown.py --list
    python3 scripts/analysis/v7_reachable_from_code.py --top 12
    python3 scripts/analysis/v7_unspellable_forms.py --top 16
    bash    scripts/analysis/v7_conversion_sweep.sh --reachable
    python3 scripts/analysis/lsw_saveall_table.py

⚠ `llvm_missing_instruction_forms.py` reported a cause that was **wrong**, and the
docstring now says so: the TLCS-900 backend never lacked those instruction forms,
it lacked their NAMES. They encoded correctly all along but were reachable only
as `andmi8`, `bitm`, `ldcfm`. Fixed in `tlcs900_backend@970c4a75312e`; the script
is still useful for finding forms a source cannot express, but read its caveats
before believing a ranking — it tries both operand orders precisely because
unidasm prints `sla 0x07,A` where llvm-mc wants `sla a, 7`.


## Added 2026-08-30 (misframe correction lane)

The byte gate proves the ROM was not CHANGED. It does not prove it was
DISASSEMBLED CORRECTLY -- `.byte 0x4f,0x4e,0x54,0x52` and `ld xhl,0x52544e4f`
emit the same four bytes. These are the tools for the other half.

| script | question it answers |
|---|---|
| `address_line_map.py` | Which SOURCE LINE emits the byte at address X? (The sources carry no address comments, so this builds the map by linking a marker-labelled mirror and reading `llvm-nm`. `--selftest` proves the mirror is inert against the original ROM.) |
| `emit_rom_data_lines.py` | What exactly do I write in the `.s` so that not one byte moves? (`.byte` with an ascii gutter, `.long` for pointer tables, `.ascii` for fixed-width cells. `--selftest` re-assembles what it printed and compares to the ROM slice.) |
| `misframe_reframe_evidence.py` | Is each span this lane re-framed really DATA, and does anything point INTO it? (Four sites; the falsification test FIRED on one and found two real 7-byte subroutines inside a documented data block. `--survey` shows the descriptor shape is ROM-wide: 208 of 261 `02 0f` windows, against a 0.024% null.) |
| `code_vs_data_delta.py` | How many bytes did a commit move between CODE and DATA territory? (Signed, so re-framing data AS code shows positive. `8b3d510 -> HEAD` is -1,753.) |

    python3 scripts/analysis/address_line_map.py 0xED1BA0 0xED1BF0
    python3 scripts/analysis/emit_rom_data_lines.py --bytes 0xF6A9D7 0xF6AC91
    python3 scripts/analysis/misframe_reframe_evidence.py --survey
    python3 scripts/analysis/code_vs_data_delta.py 8b3d510 HEAD

Findings: `notes/FINDINGS-misframe-corrections-2026-08-30.md`.

## Added 2026-09-01 (lane v7, parallel disasm push)

Lane v7's brief asked it to check whether the v7 build still "reads its own ROM" --
already fixed once, in 1528605e (2026-08-21) -- and to quantify precisely, in bytes,
how much of v7 has no source at all.

| script | question it answers |
|---|---|
| `v7_no_source_bytes.py` | How many v7 maincpu ROM bytes are reproduced by NO source, right now, measured directly from what `v7/maincpu/kn5000_v7_program.s` actually assembles? (120,332 B / 5.74%, 2026-09-01: 272 live-referenced `romslices/` transplants + 2 raw-byte patches in `v7_c_divergence.json`. Down from the 141,893 B documented on 2026-08-21 -- intervening lane work, e.g. `056a9a1d`'s 8,084 B of pointer tables, already closed part of the gap.) |

    python3 scripts/analysis/v7_no_source_bytes.py

`kn5000_source_coverage.py`'s "v7 circularity" section was also fixed in this pass: it
ignored `.incbin "path", off, len` and charged the WHOLE shared blob's size to every
labelled slice into it, so a file referenced 842 times (`technichord_string_data.s`)
counted 842x its own size -- 31,758,150 B of "differ" on a 2,097,152 B ROM, an
impossible number that should have been the tell. Fixed to slice by the actual off/len,
it reports a bounded 149,016 B -- but that is answering a DIFFERENT, looser question
("how wrong would naively reusing v9's committed bin be for v7") than
`v7_no_source_bytes.py`'s ("how much of v7's actual committed tree has no source").
Use `v7_no_source_bytes.py` for the headline number.


## Fixed 2026-09-01 (lane INSTR -- the coverage instrument itself was broken)

| script | question it answers |
|---|---|
| `kn5000_source_coverage.py` | For each of the 13 gated images (9 KN5000 + 4 WSA1R), how many bytes are real source -- assembly, typed/derived data, or C compiled byte-exact by clang -- and how many are still handed back verbatim from a committed blob with no decode path (the actual territorial debt)? Was reporting an impossible negative source figure for HD-AE5000 (a comment-blind `.incbin` regex was double-counting a dead "; Was:" fossil comment against its live replacement); fixed by stripping comments before matching and by classifying every `.incbin` target against the build machinery that actually produces it, instead of a `"generated/" in path` guess. |

    python3 scripts/analysis/kn5000_source_coverage.py         # run `make all` first
    python3 scripts/analysis/kn5000_source_coverage.py --selftest

Findings and the corrected 13-image table: `notes/coverage-instrument-fix-2026-09-01.md`.
