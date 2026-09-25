# Lane `sequi`, semantic push 2026-09-25 -- artefacts

Files owned: `sequencer/{sequencer_ui,seq_audio_mode,smf_config_routines,
seq_step_routines,rhythm_routines,bmdredit_routines,composer_msp_defaults,
ssf_gate_states}.s` in `v10/`, `v9/` and `v7/` maincpu.

## Tools (committed under scripts/)

| script | question it answers / job | command |
|---|---|---|
| `scripts/analysis/sequi_lane_figures.py` | per-file CODE / KNOWN-A / KNOWN-B / UNKNOWN / FILLER / research-target bytes for this lane's files, plus data-as-code markers and numeric branch operands in the working tree | `python3 scripts/analysis/data_range_census.py --images v10,v9,v7 --json C.json && python3 scripts/analysis/sequi_lane_figures.py C.json` |
| `scripts/converters/sequi_regmode_macroize.py` | are v7 `InitializeKubo`'s trailing 1,289 `.byte` the RegMode/RegTitle records v10 spells as macros? rewrite them as those macros | see its docstring (dry by default) |
| `scripts/converters/sequi_reframe.py` | re-frame MISFRAMED code: framing from unidasm, text from the LLVM disassembler, every new instruction re-encoded and compared, whole image rebuilt and compared | `python3 scripts/converters/sequi_reframe.py --image v10 --file sequencer/sequencer_ui.s --auto [--apply]` |

## Logs

| file | what it records |
|---|---|
| `reframe-v10-sequencer_ui.log` | the `--auto --apply` run on v10 `sequencer/sequencer_ui.s` (toolchain `tlcs900_backend@4d7fa4f6b37c`): one header line per span (old lines, dirty lines, instructions replaced, dropped labels), then every replaced instruction as `ADDR  new-text  || unidasm: <second decoder's reading>`.  The second column is the operation check the lane brief asks for: 152 replaced instructions, and a mnemonic-root comparison of the two decoders found no disagreement other than spelling (`pushm`/`pushdi_w` = unidasm `pushw (mem)`, `cpib_erp 251` = unidasm `cp QIZH`). |

v9's `sequencer/sequencer_ui.s` was byte-identical to v10's before and after
(the two images are identical over this file's range); the v10 result was
copied and v9 rebuilt byte-identical.
