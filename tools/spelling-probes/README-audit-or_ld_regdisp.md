# Audit probe: independent re-derivation of the `or (r+imm),imm` / `ld r,(r+imm)` result

`README-or_mem_imm-and-ld_r_regdisp.md` reports 1355 sites, 1337 spellable
today, 18 closed by three proposed rules, 0 left, and no backend gap. This
probe re-derives all four numbers **without reusing that probe's candidate
generator**, so the two are independent witnesses of the same claim.

| script | question it answers | command |
|---|---|---|
| `audit_or_ld_regdisp.py` | Enumerated from scratch, do the same 15 addresses block, and does an independently written candidate generator reproduce their ROM bytes? | `TMPDIR=<dir with free space> python3 tools/spelling-probes/audit_or_ld_regdisp.py` |

Signal read: raw bytes of `original_ROMs/kn5000_v7_program.rom` at load base
`0xE00000` versus `llvm-mc -triple=tlcs900 --show-encoding`. PASS = identical
bytes; "assembled without error" is NOT a pass. Exit 0 = every site byte-exact.

⚠ `convert_reachable_ranges.decode_range()` writes a scratch file per range; on
a full `/tmp` it dies with `FileNotFoundError`. Point `TMPDIR` at a filesystem
with space.

## Result, 2026-08-23, repo `28bbfe1`, llvm `tlcs900_backend@bcf152d1fe00`

```
1. ENUMERATE  1201 distinct (addr,text) sites, 1355 site-visits
              ld r,(r+imm) 1193/1344 · or (r+imm),imm 8/11
2. TODAY      1337 visits spellable, 18 blocked at 15 distinct addresses
3. PROPOSED   15 sites closed, 0 with no matching candidate
```

Confirms the audited report exactly, including the visit multiplicities that
make 15 addresses into 18 visits (`0xF0558C` is reached from `0xF0551E`,
`0xF05533`, `0xF0557A`; `0xFE7CE2` from `0xFE7C04`, `0xFE7C0E`).

## One correction to the audited report

Its rule OR-1 says "width is invisible in the printed text, so offer both"
`ormi8` and `ormi16`. The width **is** visible: unidasm formats an immediate as
`0x%0*x` with `size/4` digits (`dasm900.cpp:1418`, reached from `O_I8` / `O_I16`
at lines 2131/2136), so an 8-bit immediate always prints 2 hex digits and a
16-bit one always 4. All eight v7 sites obey it. Offering both candidates stays
**safe** — the byte comparison selects, and 0 of 1216 candidates mis-selected
in pass 3 — so the rule is unchanged; only its stated justification is wrong.
