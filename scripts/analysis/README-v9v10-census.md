# Do v9 and v10 also carry undisassembled code?

## `v9_v10_undisassembled_census.py`

**Question:** all of the conversion effort has gone into v7, because the L1
territory map made it the visible outlier (27.26% CODE against v9/v10's
47.83%). Do the other two images hide the same kind of undisassembled code?

**Answer (measured 2026-08-22):** yes, but roughly 12x less, and in a
different shape.

| | v7 | v9 | v10 |
|---|---|---|---|
| CODE | 27.26% | 47.83% | 47.83% |
| literal `.byte` | 407,788 B | 84,484 B | 84,481 B |
| `.incbin` (C structs, fonts, images) | 968,006 B | 848,809 B | 848,809 B |
| judged convertible | -- | ~22,552 B | ~22,449 B |

**Run:**

    python3 scripts/analysis/v9_v10_undisassembled_census.py --prepare
    python3 scripts/analysis/v9_v10_undisassembled_census.py --census v9

⚠ **The obvious method is a dead end, and this script does not use it.**
Diffing v9's territory against v10's finds only **581 differing bytes** in
2,097,152. They were disassembled in lockstep, so they hide the *same* residue
and cannot corroborate each other -- unlike v7-vs-v9, where the difference was
real. Recorded so nobody tries it again.

**How the addresses are made trustworthy:** the script copies each tree, injects
a `.globl` label pair around every literal `.byte` run and every `.incbin`, then
assembles, links, and **asserts the rebuilt ROM is byte-identical to the
original before believing any address**. Labels emit no bytes, so that check is
what licenses the measurement. It also gives every blob its source file:line,
which the flattened `-show-encoding` stream cannot, because llvm-mc expands
`.incbin` into `.ascii`.

**Why `.incbin` is counted separately:** those bytes are data by construction
(compiled C structs, fonts, indexed images) and are separately audited by
`audit_incbin_legitimacy.py`. Mixing them into a "DATA" total would overstate
the conversion opportunity by roughly 850 KB per image.
