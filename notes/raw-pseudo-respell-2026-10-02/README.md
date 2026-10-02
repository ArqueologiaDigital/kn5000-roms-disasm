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

## Round 2, the same day: `(xrr+rr)` on every memory operation (TOOLCHAIN_VERSION UPDATE 21)

llvm-project a3a81863f87d defines the register-indexed operand for the ALU operations (both
directions and with an immediate), `ld`/`ldw (m), #`, bit/set/res/chg/tset/ldcf/stcf,
inc/dec, push/pushw and ex -- the forms round 1 left.  The same command, re-run (reports in
`round2/`):

| tree | respelled | left |
|---|---:|---:|
| v10/maincpu | 656 | 25 |
| v9/maincpu | 657 | 25 |
| v7/maincpu | 612 | 19 |
| v142/subcpu | 181 | 0 |
| hdae5000 | 96 | 6 |
| table_data | 5 | 0 |

What is left: previous-bank index registers (`cp (xwa+qiz), n`), the 8-bit index on these
operations, a couple of odd `bit 0` / `ld (R+N),R` readings, and pseudos whose operands are
symbolic (never traded for unidasm's numbers).  Totals over both rounds: 13,136 lines.

## `--bytes`: one-instruction `.byte` lines (same day)

`respell_raw_pseudos.py --tree <tree> --bytes --apply`: a `.byte` line of numbers whose
comment starts with a mnemonic, with an instruction on both sides, whose bytes unidasm reads as
one instruction of that mnemonic, gets the spelling that re-assembles to the same bytes.
73 v10, 73 v9, 73 v7, 8 v142 (reports in `bytes/`).  A comment that only restated the
instruction, or said "[not in LLVM]" (no longer true), is dropped; any other text stays.
Left: `sll A,E`-style shifts by a register, `ldcf A,RH3`-style bank-register forms, LDC to
DMA control registers -- spellings the backend still lacks -- and bytes whose comment names
something unidasm does not read.
