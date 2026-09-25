# Lane `promcd`, semantic push 2026-09-25 -- the artefacts behind every quoted number

Files owned: `wsa1/prom_c/*`, `wsa1/prom_d/*`, `wsa1/kernel/*`, `wsa1/dsp/*`
(roster `notes/lanes/ROSTER-2026-09-25.json`).  Gate: `make gate-wsa1`.

| script | question it answers | run |
|---|---|---|
| `lane_measure.py` | per-file census bytes (CODE / KNOWN-A / KNOWN-B / UNKNOWN / FILLER / research targets) for this lane's files, before vs after, plus the data-as-code marker count | `python3 scripts/analysis/data_range_census.py --images prom_a,prom_c,prom_d --json X.json` then `python3 notes/lanes/promcd-2026-09-25/lane_measure.py --lane promcd BEFORE.json AFTER.json` |
| `preset_bank_readers.py` | who reads prom_c 0xF80000-0xF965BF (the preset bank) and what each record is; asserts every instruction byte of the six prom_a readers and the link thunks against `wsa1/original_ROMs`; `--apply` writes the evidence into `wsa1/prom_c/data_tables/preset_bank.s` (run from the parent commit it reproduces the committed edit byte for byte) | `python3 notes/lanes/promcd-2026-09-25/preset_bank_readers.py` -- PASS = `ALL ASSERTIONS HOLD` |

## Baseline (census of `main` @ 3958235e, toolchain tlcs900_backend@4d7fa4f6b37c)

| CODE | KNOWN-A | KNOWN-B | UNKNOWN | FILLER | research |
|---:|---:|---:|---:|---:|---:|
| 209,890 | 317,666 | 199,831 | 620 | 322,983 | 32,835 |

Data-as-code markers in the lane's files: 84.
