# Lane `promb`, 2026-09-25 semantic push — instruments

Every number this lane quotes in a commit message or in its report comes
from one of these.  Each
re-derives its claims from the ROM dumps (`wsa1/original_ROMs/`) or the current
source; none writes a `.s` unless it says `--apply`.

| script | question it answers | run |
|---|---|---|
| `measure_promb.py` | before/after figures for the lane's files: census buckets (CODE / KNOWN-A / KNOWN-B / UNKNOWN / FILLER / research-target bytes, the `lane_worklists.py` rule), data-as-code markers, numeric ROM-address operands by mnemonic and target image, label population; optional split of symboliser refusals by target image | `python3 scripts/analysis/data_range_census.py --images prom_b --json X.json` then `python3 notes/promb-2026-09-25/measure_promb.py --census X.json [--symbr R.json]` |
| `midline_artefact_probe.py` | are the "mid-instruction branch targets" real misframes?  Splits `mid-line-*` sites by whether the target is inside prom_b or past it (prom_a), and prints the open-ended last span that causes the second kind | `python3 notes/promb-2026-09-25/midline_artefact_probe.py` |
| `stage_values_probe.py` | the five routines at 0xF57453 (ex-`Unclaimed_F57453`): their `calr` callers, the RAM cells each writes, and the source variables of the display list its caller runs next -- must be equal | `python3 notes/promb-2026-09-25/stage_values_probe.py --selftest` |
| `note_name_tables_probe.py` | MsgLine_FormatNoteAndVelocity (0xF6DD17) and its two tables: callers, `divs WA,L` by 12, the 12 + 11 entries, the flat/sharp glyphs of Font_Svc06 | `python3 notes/promb-2026-09-25/note_name_tables_probe.py` |
| `smf_param_sysex_probe.py` | the 74 x 19 SMF SysEx templates at 0xF74FCF: reader shape, constant fields, extent, the parallel RAM pointer table, and the stale `calr`s that land inside records | `python3 notes/promb-2026-09-25/smf_param_sysex_probe.py` |
| `sysex_decode_tree_probe.py` | `LinkTable_F4FF61` as the SysEx decode tree prom_a sub_FB63D1 walks: reader shape and per-level failure codes, list/leaf census, terminator codes, and that all 74 exported SysEx bodies are complete paths | `python3 notes/promb-2026-09-25/sysex_decode_tree_probe.py` |
| `annotate_kanji_cells.py` | do the kanji cell lines carry the transcription's characters, and are the ROM's defined cells exactly the transcribed codes? (`--apply` writes the annotations) | `python3 notes/promb-2026-09-25/annotate_kanji_cells.py` |
| `effect_descriptor_pool.py` | what 0xF124A6-0xF12F23 is: the 70-byte EQ-graph display-list template EqGraph_Draw (0xF0FF3F) copies and patches (with the captions, box, 0 dB line and BYPASS branch that make it an EQ), and the 57 DSP-effect parameter descriptors that tile 0xF124EC-0xF12F23 exactly -- group layout, padding, terminator, W = highest slot + 1 (`--emit` prints the asm, `--apply` writes it) | `python3 notes/promb-2026-09-25/effect_descriptor_pool.py` |
| `dsp_effect_tables.py` | what 0xF13124-0xF13D33 is: the 32 value-type ranges (min, max, coarse step), the per-block algorithm maps and inverse lists for IndexedTable entries 97/98/99, the page -> block byte table, three IndexedParam_AdjustField descriptors, the 128 -> 57 per-algorithm DEFAULT records, the 73-entry SysEx parameter-number map, and two 16x12 bitmaps -- each checked against its reader's instruction bytes (`--apply` writes the source and renames DspEffect_StepAlgorithm / SetAlgorithm, DspParam_Read/WriteByNumber) | `python3 notes/promb-2026-09-25/dsp_effect_tables.py` |
| `reader24_sweep.py` | which objects whose headers say "read by nothing (32-bit search)" DO have a reader that spells their address as a 24-bit operand (`lda XRR,(nnn:24)` etc.) in prom_a or prom_b -- the operand must also SPELL the address in the line's text (guard against byte-adjacency coincidences) | `python3 notes/promb-2026-09-25/reader24_sweep.py` |
| `effect_paint_jobs.py` | are `Data_F10D62` / `Data_F10E0F` / `Data_F1173A` code (a posted callback entry and two hand-made-call return points), where does the misframe at 0xF10EFF resync, and are the eight routines that clear bit n of (0x2799) and are posted to T_CallbackQueue_Post by a routine that sets it the effect editor's paint jobs 0..7 (`--apply` / `--post`: the conversion and names; its docstring gives the exact sequence, which reproduces the committed file byte for byte) | `python3 notes/promb-2026-09-25/effect_paint_jobs.py` |
| `code_islands.py` | are eleven small `Data_*`/`.byte` objects in the 0xF65000-0xF77FFF layers code -- reached by fallthrough from a conditional jr, or a `calr` target the source misframed, or unreached but decoding to code that fits its neighbours (stated as such) -- each decode checked to end exactly on the source's next instruction line (`--apply` converts them and re-parents their `_Code_` labels) | `python3 notes/promb-2026-09-25/code_islands.py` |
| `symbolize_prom_b_r3.py` | which numeric branches the shared symboliser refuses on prom_b only because of R3 "absurd" shapes that are ordinary code here (`jr cc,0` inside an instruction run; nop runs after a routine end, before `ret`/`djnz`, or between two instructions; a `reti` reached only by branches) or because its LINEAR unidasm sweep lost sync (R5 -- re-decoded from the site's routine entry), and converts them with every other rule of the shared tool intact (the tool's source is patched in memory, never on disk; its docstring lists each widened test and why) | `python3 notes/promb-2026-09-25/symbolize_prom_b_r3.py --apply --verify` |
| `reparent_code_labels.map` | the 811 `old=new` renames of `scripts/renaming/reparent_code_labels_prom_b.py` (input for `assert_comments_preserved.py --rename-map`) | — |

Converters this lane added (under `scripts/`, not here):

* `scripts/converters/symbolize_wsa1_rom_addresses.py` — numeric ROM-address
  operands -> labels (`--arms`, `--offsets`, `--check-equates`; its docstring is
  the spec).
* `scripts/renaming/reparent_code_labels_prom_b.py` — `<Table>_Code_<Role>`
  branch labels re-parented onto their routine.

Baselines: the session-start figures were measured on commit `3958235e` (this
branch's base).  To re-derive them, check that commit out in a scratch worktree
and run `measure_promb.py` / `midline_artefact_probe.py` there; the scratch
JSONs themselves were not kept (regenerable in ~20 s and ~40 s).
