# WSA1 prom_c: 5,442 raw-byte pseudo lines spelled natively (2026-10-03)

prom_c had been transcribed with the backend's bare byte pseudos: `extpfx<N> b1, .., bN`,
`link32 0xEE, 0x0C, lo, hi`, `unlk32 xiz`. scripts/converters/respell_raw_pseudos.py now matches
those too. It assembles each pseudo, reads the bytes with unidasm, and keeps the first native
candidate that assembles to the same bytes:

    python3 scripts/converters/respell_raw_pseudos.py --tree wsa1/prom_c [--apply]
    make gate-all

Result: 5,442 lines respelled. 129 remain in forms the backend cannot spell yet (`ld R,IYL`,
`ex R,QWA`, `sll R,R`, `stcf/ldcf N,R` ...).

## Do the checkers still say the same thing?

Many wsa1/notes scripts parse prom_c source text, and some special-case `extpfx` lines. So every
wsa1/notes/*.py that mentions prom_c (168 scripts) was run, with its default arguments, in two
throwaway worktrees: HEAD, and HEAD plus the respell. Output and exit status were compared:

    scripts/tools/wsa1_notes_compare.sh HEAD prom_c 240

`notes_compare_summary.txt` is that run's output: 162 SAME, 6 DIFF. Each DIFF was read:

| script | why it differs |
|---|---|
| kernel_structural_match | both sides hit the 240 s timeout (rc=124); everything both printed agrees |
| prom_cd_falsification_2026_09_02 | scans 5653 instruction literals instead of 4363, since native lines are readable now; findings unchanged |
| prom_c_finish_round12 | echoes source lines: `extpfx3 0x9E, 0xF2, 0x80` -> `add wa, (xiz-14)` |
| prom_c_understanding_round5 | echoes source lines: `extpfx7 0xD2, ...` -> `cpw (0x00f35a:24), 0x0000` |
| verify_a1_independent_check | FAILs on both sides (pinned to an old base); its deleted-line and hunk counts shift |
| wave7_round9_review_wb_prom_b | lists file sizes, which changed |
