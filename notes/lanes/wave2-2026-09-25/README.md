# Wave 2 of the semantic push (2026-09-25)

Twenty file-disjoint lanes (roster: `notes/lanes/ROSTER-2026-09-25.json`, brief:
`notes/lanes/BRIEF-2026-09-25-semantic.md`) worked in worktrees on branches `s2/<lane>`;
a serialized integrator merged each behind `make gate-all`. All 20 are on main.

## What each file here answers

| file | question |
|---|---|
| `lane-reports/<lane>.json` | what the lane did, its before/after figures and the command that measured them, what it could NOT do and why, and its leads -- the lanes' own structured reports, verbatim |
| `integrator-refusals.txt` | why the integrator refused ext, uiproc, uimisc and sys (cross-lane breaks git cannot see) |
| `census-after-wave2.txt` | the census on main after all 20 merges (command below) |
| `WAVE3-LEADS.md` | every lead the lanes reported, grouped for the next wave |
| `WAVE3-PLAN.md` | the plan built from those leads, and the integration lessons |
| `di-alias.patch` | the ready backend fix for the `di` alias (applies to llvm-project tlcs900_backend) |
| `workflows/semantic-wave2.js` | the exact workflow script that ran the 20 lanes and the serialized integrator (prompts, roster use, merge gate) |
| `workflows/review-wave2.js` | an adversarial review of the merged lanes' semantic claims -- drafted, NEVER RUN (a candidate for Wave 3b) |

## Headline figures (re-derive with `python3 scripts/analysis/data_range_census.py`)

| | before (3958235e) | after Wave 2 (5fc8d5bd) |
|---|---:|---:|
| strict (CODE + KNOWN-A + FILLER) | 64.15 % | **95.04 %** |
| KNOWN-B (name only) | 4,428,721 B | 557,803 B |
| KNOWN-A (evidence header) | 2,778,685 B | 6,429,576 B |
| research targets | 395,986 B / 26,553 ranges | 328,853 B / 5,077 ranges |
| UNKNOWN | 12,357 B | 56,567 B (honest admissions replacing hiding names) |

Per image, strict: v10 94.01 %, v9 93.98 %, v7 93.54 %, v142 99.12 %, subcpu boot 99.97 %,
table data 95.46 %, custom data 100 %, HD-AE5000 98.52 %, prom_a 95.16 %, prom_b 83.65 %,
prom_c 98.01 %, prom_d 99.79 %. Toolchain for every figure: tlcs900_backend@4d7fa4f6b37c
(llvm-mc sha256 a7ee33d5...).

## Integration: four merges needed fix-ups

File-disjoint ownership prevents textual conflicts, not semantic ones. Four lanes merged
cleanly and still broke the build, because another lane (merged first) had renamed or moved a
label they referenced: an add/add clash of two different `lane_line_map.py` tools; a v7 label
dropped by a v10->v7 port; renames (`LcdOff_Epilogue` -> `UpdateScreen`,
`SubCPU_ToneParamRet_Code_Return2` -> `PerfMode_ParamHandler_11_Return5`); and the v7 +0x41A
label-drift correction moving labels under `.long L + N`, `call L` and `jp L`. Each fix
resolves the reference to the label main puts at the address the lane's own byte-identical
build resolved it to, so the byte gate checks every fix; `scripts/tools/reanchor_pointer_refs.py`
does it for `.long` operands from the ROM's own values. One fix also corrected a false header
("no code reference reaches them") on the ON/OFF cell strings the drawbar grid code loads. The
merge commits (7b69fe31, 8bcea5a7, ff079c6b, 6c16aad8) list every fix.
