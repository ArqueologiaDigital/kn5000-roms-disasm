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

## Added 2026-09-01 (lane V10V9, full-disassembly push)

| script | question it answers |
|---|---|
| `v9_v10_true_debt.py` | How much of v9/v10 maincpu is still NOT reproduced by real source, in bytes, counting `.incbin` AND literal `.byte`/`.ascii`/`.word` runs (not `.incbin` alone)? Requires the ROM already built -- `kn5000_source_coverage.py` silently undercounts `.incbin` on a fresh tree because `generated/*.bin` don't exist until `make` runs. |
| `verify_converted_call_targets.py` | Does a region `convert_region.py` converted actually behave like code -- do its `call` targets land on routines ALREADY named in the tree, independent of the byte gate (which cannot tell real code from a coincidentally-decodable data table)? |

    python3 scripts/analysis/v9_v10_true_debt.py v9 v10
    python3 scripts/analysis/verify_converted_call_targets.py --git-diff 11a48aca 244bde7b

Findings: `README-v9v10-census.md`'s 2026-09-01 update.

## `v7_list_slices.py`

**Question:** which `.incbin` slices does v7's maincpu pull in — from which file,
at what offset/length, under which label? The work list for v7's 123,927 B of
verbatim debt, now the largest genuine block in the tree.

    python3 scripts/analysis/v7_list_slices.py

⚠ Reports what the SOURCE says, not what the ROM contains: the label above a
slice is a claim, not a measurement. ⚠ The mechanical pointer-table class here is
already exhausted and the remainder is ~89% opaque, so the productive route is
cross-version comparison against the better-disassembled v9/v10 — a lead, not
proof, since v7 genuinely differs and that is why the slices exist.

## Added 2026-09-02 (lane V7SLICES, full-disassembly push wave 2)

Takes `v7_list_slices.py`'s lead and follows it through: cross-reference every
live romslice against v9/v10 by its label, then require a byte-exact round
trip before converting anything.

| script | question it answers |
|---|---|
| `v7_slice_v9v10_correspondence.py` | For each live romslice, what does the SAME-NAMED label look like in v9/v10 -- real disassembled CODE, a `.byte`/`.ascii` run, a `.long` table, or NOTFOUND (name has drifted)? A literal lookup, not a fuzzy match, since v7 shares source layout and labels with v9/v10. Caught two of its own misclassifications by hand-checking hits: a label with its directive on the SAME line as the colon, and a macro invocation (`aligned_string "..."`) with no leading dot that looks like an instruction. Both fixed in the classifier. |
| `v7_slice_code_roundtrip.py` | Of the CODE-labelled slices, which ones does llvm-mc's own disassembler decode with zero "invalid instruction encoding" warnings AND reassemble back to the exact original bytes? Only 1 of 34 CODE-labelled slices does (47 B), and even that one is rejected by hand -- a clean decode is not proof of code (the HD-AE5000 version-string trap), and its content doesn't match v9/v10's real routine at that label. |

    python3 scripts/analysis/v7_slice_v9v10_correspondence.py
    python3 scripts/analysis/v7_slice_code_roundtrip.py

Result: 10 slices (167 B) converted to verified instructions, 1 slice (27 B,
all 0xff) retyped as `.fill` (erased flash, not code, despite a clean decode),
194 B total. v7's verbatim debt: 120,332 B -> 120,138 B
(`v7_no_source_bytes.py`). The 34 CODE-labelled, 25,425 B bucket is otherwise
blocked by the same tlcs900-backend spelling gap already known from v7's
general code-as-`.byte` debt.

## Added 2026-09-02 (lane V10DISPATCH, full-disassembly push wave 2)

`v10/maincpu/ui_widgets/widget_dispatch.s` holds 25,211 `.byte` operands --
roughly a quarter of v10's entire `.byte` total, and the largest single
concentration in the image. `kn5000_source_coverage.py` reports v10 as 0 bytes
of verbatim debt because it counts `.incbin`; it cannot see any of this. But a
`.byte` count is not automatically debt either: a run that really is a
byte-valued table is already correctly represented.

| script | question it answers |
|---|---|
| `v10_widget_dispatch_byte_triage.py` | Of those 25,211 operands, how many are (a) real code still spelled as `.byte`, (b) structured data that wants `.long`/`.word`/`.ascii`, (c) a genuine byte table that is already correct -- and (d), crossing all three, how many runs start with a byte the pinned backend cannot decode? Locates every run in the ROM via `address_line_map.py`, then decides on what REFERENCES it: a `call`/`jp`/`jr` naming the label means code; only the address being stored or loaded means data. |

    python3 scripts/analysis/v10_widget_dispatch_byte_triage.py
    python3 scripts/analysis/v10_widget_dispatch_byte_triage.py --control
    python3 scripts/analysis/v10_widget_dispatch_byte_triage.py --selfcheck
    python3 scripts/analysis/v10_widget_dispatch_byte_triage.py --list BLIND

`--control` is not optional before quoting a number. It scores the deciding rule
against two corpora the tree already labels: 3,834 labels spelled as
`.ascii`/`.asciz`/`.incbin` (0.08% false positives -- 3 offenders, named) and
29,915 spelled as instructions (81.9% recall, so 18.1% false negatives, and CODE
is therefore a LOWER bound). `--selfcheck` exists because the first version of
the run model silently dropped every label-only line, so no run carried a label
and the deciding rule could never fire at all.

Result: **0 bytes of code, 416 B of proposed-but-refused structured data, 24,110
B of genuine byte table.** Nothing in the file is a named call or jump target,
and `--codebound` puts a ceiling on it from the other side: at most 3,044 B of
the remaining 24,526 could be code at all, and only 359 B of that both decodes
and ends in a terminator (tlcs900_backend 58fb7f2afaed -- ⚠ the bound moves with
the DECODER: an earlier build the same day gave 1,445 B / 111 B, so regenerate
it and name the backend commit rather than quoting a remembered number). 688 B
of pointer-table entries were typed as `.long`
(`scripts/converters/v10_widget_dispatch_ptr_entries.py`) and one 3-byte code
misframe inside a character map was restored to `.byte`.

⚠ The blind-start signal from `byte_run_start_enrichment.py` does NOT reproduce
inside this file: 10.9% blind against 5.1% control is 2.1x, under that script's
own 3x threshold, against 46.5x for v10/maincpu as a whole. 65 of the 74
blind-start runs begin with 0x01, which is the low byte of a record tag in the
six-byte `{u16 tag, u32 pointer}` arrays -- a confound, not a residue.

## Added 2026-09-02 (lane v10seq, full-disassembly push)

Splits `v10/maincpu/sequencer`'s 11,096 `.byte` operands into what is actually
debt and what is already correct, then measures what the conversions retired.

| script | question it answers |
|---|---|
| `seq_byte_operand_triage.py` | Of a directory's `.byte` operands, how many are (a) real instructions spelled as data, (b) structured data written as an undifferentiated byte soup, (c) a genuine byte table already correct -- and, crossed with those, (d) blocked on one of the five leading bytes the pinned backend cannot decode? Addresses come from `address_line_map.py`, regions from `llvm-nm` on the real linked ELF, and the verdict from a whole-tree branch-vs-address reference test. `--control` scores that test against the 266 spans lanes V10DAC/V10DAC2 adjudicated by hand: **0 of 196 hand-judged DATA called CODE, but 33 of 70 hand-judged CODE called DATA**, so (a) is a LOWER bound and (b)/(c) certainly contain real code. |
| `seq_blind_start_confound.py` | Can a DATA-AS-CODE misframe inflate `byte_run_start_enrichment.py`'s signal? Yes: a misframed table breaks at every byte the decoder refuses, and a note/channel table's own values include 0x01 and 0x04 constantly. Typing two tables took `seq_event_playback.s` -- v10's highest-rate file -- from 40.9% to 1.7% blind, without converting anything into an instruction. |
| `seq_conversion_ledger.py` | For each region this lane re-typed, how many of its bytes were previously instruction mnemonics (data-as-code retired) versus already `.byte` (re-typed), with any real subroutine kept inside the block subtracted from both? |

    python3 scripts/analysis/address_line_map.py --dump /tmp/amap.json
    python3 scripts/analysis/seq_byte_operand_triage.py --amap /tmp/amap.json
    python3 scripts/analysis/seq_byte_operand_triage.py --amap /tmp/amap.json --control
    python3 scripts/analysis/seq_byte_operand_triage.py --amap /tmp/amap.json --blocked
    python3 scripts/analysis/seq_blind_start_confound.py --dir v10/maincpu/sequencer --before a99564a6
    python3 scripts/analysis/seq_conversion_ledger.py --before a99564a6

Result: 4,511 B re-typed across eight regions -- 1,135 B of data-as-code
retired, 2,311 B of `.byte` operands given a width, 67 B of real subroutine
found living inside two of the data blocks and deliberately left alone.
Full write-up in `notes/lanes/v10seq-2026-09-02.md`.

| script | question it answers |
|---|---|
| `grep_skips_latin1_probe.py` | Which sources will a `-I` grep silently skip? The discriminator is UTF-8 DECODABILITY, not "has bytes >= 0x80" -- which is why the brief's falsification of the claim did not reproduce: its control file's high bytes form valid UTF-8. 4 of `v10/maincpu/sequencer`'s 15 `.s` files do not decode as UTF-8, and in the agent shell (where `grep` execs ugrep with `-I`) they vanish from a tree-wide search with no diagnostic at all. |

    python3 scripts/analysis/grep_skips_latin1_probe.py v10/maincpu/sequencer
