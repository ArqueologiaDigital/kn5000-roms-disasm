# Code out of frame at a lone prefix byte, and the register-indexed pseudos (2026-10-02)

## Re-framing (`scripts/converters/reframe_prefix_bytes.py`)

Run: `make all; python3 scripts/converters/reframe_prefix_bytes.py --image v10 --apply --report OUT.json`.
`report_<tree>.json`: every candidate `.byte 0xPP` line, its span and the verdict.

| tree | candidates | applied | refused: no resync | new decode absurd | context not clean | old decode sane |
|---|---|---|---|---|---|---|
| v10 | 57 | 54 | 7 | 2 | 9 | 2 |
| v9 | 58 | 55 | 9 | 2 | 10 | 4 |
| v7 | 39 | 38 | 3 | 3 | 8 | 1 |

(Candidates count the spans that passed every guard; the refusal columns count the others.)
A first, unguarded v10 run applied 63 and was reverted: where the code BEFORE the prefix was
itself out of frame, a "resync" through it turned `ld a, (xhl+1) / res 7, a` into
`normal / max / decf`.  The guards (the docstring) refuse those.

Example, audio/sound_editor_ui.s at 0xF0E7C1: the source had `.byte 0xc3 / reti / or xwa, xwa /
push xsp / ld w, 110:opc / ldf 0xc7 / swi 1 / jr lt, -57 ...`; the bytes are
`cp (xde+wa), 0x20 / jr nz, 23 / inc1b_erp 249 / inc1b_erp 250 ...`.

Then `symbolize_numeric_branches.py --apply --verify` could take the re-framed blocks' branches:
v10 131, v9 139, v7 47 (v10's "R3 absurd block" refusals 509 -> 392).

## Register-indexed pseudos (`scripts/converters/respell_reg_indexed_pseudos.py`)

`ld_rrb c, xbc, wa` -> `ld c, (xbc+wa)` and the like, each unique form converted only when
llvm-mc gives the native spelling the pseudo's exact encoding.  Respelled: v10 925, v9 920,
v7 1,281 (incl. the forms the re-framing rendered), v142 253, wsa1 49; no form left.
