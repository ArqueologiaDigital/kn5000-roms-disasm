# Raw-byte pseudo-instructions -> real spellings (2026-10-02)

`scripts/converters/respell_raw_pseudos.py --tree <tree> --apply --report <tree>.json`, per
tree, then `make gate-all` (13/13).  For each `*_sri*` / `*_dri*` / `*_ind` / `*_sril*` line
whose operands are registers and numbers only: assemble it, read the bytes with MAME unidasm,
translate the reading into candidate spellings, keep the first candidate that re-assembles to
the SAME bytes (so each replacement is proven before it is written).

| tree | respelled | left |
|---|---:|---:|
| v10/maincpu | 3,470 | 681 |
| v9/maincpu | 3,466 | 682 |
| v7/maincpu | 2,987 | 631 |
| v142/subcpu | 779 | 181 |
| hdae5000 | 171 | 102 |
| table_data | 50 | 5 |
| subcpu/boot | 6 | 0 |

`<tree>.json`: `respelled` (pseudo text -> spelling written) and `left_forms` (unidasm's
reading, registers as R and numbers as N, per unique line left).  What is left is almost all
REGISTER-INDEXED memory, `(xrr+rr)`, on an operation other than ld/lda: `cp (R+R),N`,
`ld (R+R),N` (immediate store), `cp R,(R+R)`, `add R,(R+R)`, `bit n,(R+R)`, `and/or ...`,
`inc/dec`, `pushw (R+R)`, `jp (R+R)` -- the backend models `(xrr+rr)` for ld/lda/stores only
(TOOLCHAIN_VERSION, "STILL OPEN": `bit n, (xrr+rr)` without a real spelling).
