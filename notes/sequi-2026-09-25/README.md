# Lane `sequi`, semantic push 2026-09-25 -- artefacts

Files owned: `sequencer/{sequencer_ui,seq_audio_mode,smf_config_routines,
seq_step_routines,rhythm_routines,bmdredit_routines,composer_msp_defaults,
ssf_gate_states}.s` in `v10/`, `v9/` and `v7/` maincpu.

## Tools (committed under scripts/)

| script | question it answers / job | command |
|---|---|---|
| `scripts/analysis/sequi_lane_figures.py` | per-file CODE / KNOWN-A / KNOWN-B / UNKNOWN / FILLER / research-target bytes for this lane's files, plus data-as-code markers and numeric branch operands in the working tree | `python3 scripts/analysis/data_range_census.py --images v10,v9,v7 --json C.json && python3 scripts/analysis/sequi_lane_figures.py C.json` |
| `scripts/converters/sequi_regmode_macroize.py` | are v7 `InitializeKubo`'s trailing 1,289 `.byte` the RegMode/RegTitle records v10 spells as macros? rewrite them as those macros | see its docstring (dry by default) |
| `scripts/analysis/sequi_header_evidence.py` | are the NUMBERS quoted in this lane's 2026-09-25 headers still true (byte-equality counts, table relations, call-site counts, registration records)? PASS/FAIL per claim, exit status = failures | `python3 scripts/analysis/sequi_header_evidence.py` |
| `scripts/analysis/sequi_misframe_scan.py` | is any misframed code left? every code line must start on a unidasm instruction boundary of its run. Result 2026-09-25 after this lane's commits: 0 suspect runs in all six code files, v10 and v7 (v9's files are v10's) | `python3 scripts/analysis/sequi_misframe_scan.py v10 sequencer/sequencer_ui.s` |
| `scripts/analysis/sequi_find_refs.py` | before writing "no caller / no reader found": which reference FORMS were searched (absolute 24-bit value in every KN5000 image, +-window for base-minus-index, calr/jr/jrl landing on it) and what they hit | `python3 scripts/analysis/sequi_find_refs.py v10 [--window 64] 0xADDR ...` |
| `scripts/converters/sequi_symbolize_labelled_targets.py` | which branch sites did the symboliser refuse on a neighbourhood heuristic (R1/R3) although the target already carries a label? write those symbolically, rebuild, compare | `--image v7 --report R.json --file sequencer/sequencer_ui.s --kinds R1,R3 [--apply]` |
| `scripts/renaming/sequi_reparent_structural_labels.py` | which symboliser-made `<Parent>_<Role>` labels name a parent that is demonstrably wrong (itself structural, or > 1000 lines away) and what the nearest descriptive label is; rename them | `python3 scripts/renaming/sequi_reparent_structural_labels.py [--apply] FILE...` |
| `scripts/renaming/sequi_rename_case_bases.py` + `rename-case-bases.map` | the one-off rename of nine code labels that had data-shaped names (seven `jp_ind` case bases -> `*_Cases`, TrAsGrid_StepListValue, SMF_AdvanceInPageChain) with their headers; the map is the `--rename-map` for the comment gate | see its docstring |
| `scripts/converters/sequi_regobjtab_macroize.py` | v7 only: replace the hand-expanded 11-line RegisterObjectTable records with the RegObjTable / RegObjTabl macros v10 uses (142 records); rebuild + compare | `python3 scripts/converters/sequi_regobjtab_macroize.py [--apply]` |
| `scripts/converters/sequi_symbolize_macro_args.py` | which ADDRESS arguments of RegObjTable / RegObjTabl calls (B, D, RegObjTable's C) does the ELF already name? substitute, rebuild, compare | `--image v10 FILE... [--apply]` |
| `scripts/converters/sequi_reframe.py` | re-frame MISFRAMED code: framing from unidasm, text from the LLVM disassembler, every new instruction re-encoded and compared, whole image rebuilt and compared | `python3 scripts/converters/sequi_reframe.py --image v10 --file sequencer/sequencer_ui.s --auto [--apply]` |

## Logs

| file | what it records |
|---|---|
| `reframe-v10-sequencer_ui.log` | the `--auto --apply` run on v10 `sequencer/sequencer_ui.s` (toolchain `tlcs900_backend@4d7fa4f6b37c`): one header line per span (old lines, dirty lines, instructions replaced, dropped labels), then every replaced instruction as `ADDR  new-text  || unidasm: <second decoder's reading>`.  The second column is the operation check the lane brief asks for: 152 replaced instructions, and a mnemonic-root comparison of the two decoders found no disagreement other than spelling (`pushm`/`pushdi_w` = unidasm `pushw (mem)`, `cpib_erp 251` = unidasm `cp QIZH`). |
| `reframe-v7-sequencer_ui.log` | the same for v7 `sequencer/sequencer_ui.s` (70 spans, 347 replaced instructions), run with `--drop-comment '^v10 does not spell this byte either$'`: those 73 inline comments sat on single `.byte` lines and claimed v10 could not spell the byte either; the v10 re-frame above spells every one of them, so the claim is false and was dropped rather than carried. |
| `reframe-v10-seq_audio_mode.log`, `reframe-v7-seq_audio_mode.log` | the same for `sequencer/seq_audio_mode.s` (explicit reviewed spans run with `--allow-after-terminator`: four unreferenced routines after a `ret`; then `--auto` for v7) |
| `reframe-v7-rhythm_routines.log` | `--auto` on v7 `sequencer/rhythm_routines.s`: 13 spans, the `.byte` code v10 already had as instructions (Rhythm_VoiceAssign_*, Rhythm_SaveState_*, RhythmEvt_* ...); the four tables in the same file were refused by the tool (terminator / undecodable) and typed by hand |
| `reframe-v10-bmdredit_routines.log`, `reframe-v7-bmdredit_routines.log` | `sequencer/bmdredit_routines.s`: explicit reviewed spans (unreferenced routines after `ret`; in v7 also the two verbatim ROM slices) then `--auto`; the v7 third pass resolved extended-register (`ld QIZL,L` = `ldb_erp l, 250`) forms the first pass left as `.byte` |
| `reframe-v10-seq_step_routines.log`, `reframe-v7-seq_step_routines.log` | `sequencer/seq_step_routines.s`: `--auto` (v10: four one-instruction islands such as `ld (0xf247:16), (0x00ffe3:24)`), v7 also the two verbatim ROM slices (SeqStep_ByteBlockEA5F by explicit span, SeqStep_VoiceReassignExit by `--auto`) |
| `reframe-v10-smf_config_routines.log`, `reframe-v7-smf_config_routines.log` | `sequencer/smf_config_routines.s`: the unreferenced handler SMF_SlotParam_PortamentoTime (explicit span, after a `ret`) and one `--auto` span (`.byte 0xb3, 0xcf` = `bitm 7, (xhl)`); the three data tables were refused by the tool (absurd `normal` / undecodable) and typed by hand |

v9's `sequencer/sequencer_ui.s` was byte-identical to v10's before and after
(the two images are identical over this file's range); the v10 result was
copied and v9 rebuilt byte-identical.

## Measured result (toolchain `tlcs900_backend@4d7fa4f6b37c`)

`python3 scripts/analysis/data_range_census.py --images v10,v9,v7 --json C.json`
then `python3 scripts/analysis/sequi_lane_figures.py C.json`, summed over the
24 owned files.  BEFORE = branch base `3958235e` (the v7 part measured on a
clean `git archive` export of that commit, because the first v7 run raced an
edit); AFTER = `558d1fbd`.  Bytes:

| | CODE | KNOWN-A | KNOWN-B | UNKNOWN | FILLER | research targets | data-as-code markers | numeric branches |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| before | 244,726 | 3,786 | 22,380 | 0 | 4,074 | 5,598 B in 445 regions | 258 | 218 |
| after | 250,573 | 8,283 | 12,084 | 0 | 4,026 | 270 B in 6 regions | 36 | 39 |

The 270 B left are two honest admissions per version: AccPedal_BankBaseTableCopy
(28 B, no reader found) and SMF_SlotParam_RPNReturn (62 B, the second
lookup's index is inconsistent with the table's extent).  The 36 markers are
the genuine 4-`nop` slots after six `call`s in seq_audio_mode.s (v10 and v9;
v7 has the same nops, but on lines separated by blank lines, which the
nop-nop rule does not pair).  The 39
numeric branches are all v7 `call`s into C-runtime routines that another
lane's v7 file frames as data (0xFF0516 = v10 Strncpy x30, 0xFDD69E = v10
Audio_CheckSubsystemReady x6, 0xFF081D = v10 Memset, 0xFF05BC, 0xFDD7C0).
