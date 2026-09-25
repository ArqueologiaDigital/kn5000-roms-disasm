# Lane `promcd`, semantic push 2026-09-25 -- the artefacts behind every quoted number

Files owned: `wsa1/prom_c/*`, `wsa1/prom_d/*`, `wsa1/kernel/*`, `wsa1/dsp/*`
(roster `notes/lanes/ROSTER-2026-09-25.json`).  Gate: `make gate-wsa1`.

| script | question it answers | run |
|---|---|---|
| `lane_measure.py` | per-file census bytes (CODE / KNOWN-A / KNOWN-B / UNKNOWN / FILLER / research targets) for this lane's files, before vs after, plus the data-as-code marker count | `python3 scripts/analysis/data_range_census.py --images prom_a,prom_c,prom_d --json X.json` then `python3 notes/lanes/promcd-2026-09-25/lane_measure.py --lane promcd BEFORE.json AFTER.json` |
| `preset_bank_readers.py` | who reads prom_c 0xF80000-0xF965BF (the preset bank) and what each record is; asserts every instruction byte of the six prom_a readers and the link thunks against `wsa1/original_ROMs`; `--apply` writes the evidence into `wsa1/prom_c/data_tables/preset_bank.s` (run from the parent commit it reproduces the committed edit byte for byte) | `python3 notes/lanes/promcd-2026-09-25/preset_bank_readers.py` -- PASS = `ALL ASSERTIONS HOLD` |
| `prom_d_index_maps.py` | what each of prom_d's twelve 1024-entry index maps selects; asserts the readers' encodings, value ranges, the exact catalogue inverses (307/307, 314/314, 208/208, 161/161) and the defaults test (213/451, controls 0); `--apply` rewrites the 12 banners | `python3 notes/lanes/promcd-2026-09-25/prom_d_index_maps.py` |
| `prom_d_tone_elements.py` | which wave each of the 451 melodic element blocks plays, and whether each wave-select record is its wave's default; `--apply` writes 902 object headers | same pattern |
| `prom_d_descriptors.py` | which catalogue waves reach each 14-byte descriptor at +0x30/+0x38 | same pattern |
| `prom_d_drumkits.py` | the drum-kit per-note map's reader chain and the instrument every note of the 18 kits plays | same pattern |
| `prom_d_reader_corrections.py` | the readers of +0x18/+0x20, the directory's former 13 reader-less slots, PercInst's two wave-select records | same pattern |
| `prom_d_small_objects.py` | readers of the octave-shift rows, default layer, Clear template, drawbar elements and descriptors; the drawbar arm | same pattern |
| `prom_c_curve_fe13d6.py` | the reader clamp that pins Curve_FE13D6 at 101 entries | same pattern |
| `label_constant_pools.py` | labels every element of the three prom_c literal pools by its own value/text (re-decoded from the ROM) | same pattern |
| `pool_element_readers.py` | each pool element's readers, from the symbolic operands | same pattern |
| `p7_effect_names.py` | effect name of every P7 directory record / field array / stream; the 24 unreferenced streams | same pattern |
| `p7_value_tables.py` | the P7 value tables' layout from P7Unit_SendValueTable | same pattern |
| `keybend_index_trace.py` | whether Voice_KeyBend_Curve_0's wrapped top rows are reached (yes, notes >= 115) | same pattern |
| `symbolize_shared_targets.py` | converts prom_c's numeric branches into existing labels of the shared kernel/dsp files | needs a `symbolize_numeric_branches.py --report` JSON |
| `symbolize_refused_branches.py` | converts the ten R3/R6-refused prom_c branches after review | `... [--apply]; make gate-wsa1` |
| `rename_param_appliers.py` + `param_appliers.rename-map` | evidence for five routine names; the rename is `scripts/renaming/rename_promcd_param_appliers.sed` | `... [--apply]` |
| `symbolize_rom_operands_prom_c.json` | the per-site record of the `scripts/converters/symbolize_rom_operands.py` run on prom_c (2,668 operands) | data, not a script |

Each `--apply` produced its script's committed edit when run on the file as it stood
before that commit; most refuse a second run (they look for their own marker text).

## Baseline (census of `main` @ 3958235e, toolchain tlcs900_backend@4d7fa4f6b37c)

| CODE | KNOWN-A | KNOWN-B | UNKNOWN | FILLER | research |
|---:|---:|---:|---:|---:|---:|
| 209,890 | 317,666 | 199,831 | 620 | 322,983 | 32,835 |

Data-as-code markers in the lane's files: 84.
