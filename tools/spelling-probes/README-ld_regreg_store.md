# Probe: llvm-mc spelling for the unidasm form `ld (r32+r),r`

Example the search started from: `ld (XIX+HL),WA` at v7 `0xEFBD06`,
ROM bytes `f3 07 f0 ec 50`.

| script | question it answers | command |
|---|---|---|
| `verify_ld_regreg_store.py` | Which llvm-mc spelling encodes to the ROM bytes of *every* `ld (r32+r),<register>` site in the KN5000 / HD-AE5000 ROMs? | `python3 tools/spelling-probes/verify_ld_regreg_store.py` |

**Signal read:** the raw bytes of each instruction, taken from the unidasm
listing and cross-checked against the ROM images themselves
(`xxd -s $((addr-base)) -l 5`). PASS = `llvm-mc -triple=tlcs900
--show-encoding` emits exactly those bytes. "Assembled without error" is NOT
a pass — see the negative controls below.

## The spelling (a function of the raw bytes, not of the printed text)

```
f3 <m> <base> <index> <sub>          m = 0x03 -> 8-bit index register
                                     m = 0x07 -> 16-bit index register
sub = 0x40|r   ->  lda_dri  GPR[r],  m, base, index    ; stores an  8-bit reg
sub = 0x50|r   ->  stw_dri  GR16[r], m, base, index    ; stores a  16-bit reg
sub = 0x60|r   ->  stl_dri  GPR[r],  m, base, index    ; stores a  32-bit reg

GPR[r]  = xwa xbc xde xhl xix xiy xiz xsp
GR16[r] = wa  bc  de  hl  ix  iy  iz   (GR16 has no SP)
```

The three addressing bytes pass through verbatim. The mnemonic is picked by the
**sub-opcode high nibble**; the register operand only supplies the low nibble `r`.
So a *byte* store is written with a **32-bit** register name of the same
encoding: `ld (XIY+HL),A` (`f3 07 f4 ec 41`) is `lda_dri xbc, 0x07, 0xf4, 0xec`,
because A and XBC are both register 1.

## Dangerous candidates — these ASSEMBLE and are WRONG

| spelling | emits | ROM has |
|---|---|---|
| `ld (XIX+HL),WA` (unidasm's own text) | `f3 f1 A A 50` — the `(XIX+d16)` mode, `HL` parsed as an undefined **symbol** with a 2-byte relocation | `f3 07 f0 ec 50` |
| `stb_dri a, 0x07,0xf0,0xec` | `f3 07 f0 ec 31` | `f3 07 f0 ec 41` |
| `ldb_dri a, 0x07,0xf0,0xec` | `c3 07 f0 ec 21` (the load direction) | `f3 07 f0 ec 41` |
| `ldw_dri wa, 0x07,0xf0,0xec` | `d3 07 f0 ec 20` (the load direction) | `f3 07 f0 ec 50` |

## Two backend mnemonics are misnamed

Verified against unidasm and against real code, not against the `.td` comments:

* sub-opcode `0x30|r` is `lda XRR,mem` — the backend calls it **`stb_dri`**.
  `f3 07 e0 e4 30` occurs 111x in v7 and disassembles as `lda XWA,XWA+BC`.
* sub-opcode `0x40|r` is `ld (mem),r8` — the backend calls it **`lda_dri`**.

`CLAUDE.md` lists this family as `lda_dri3` / `ld_srib3`; neither mnemonic
exists in the current backend. The working names are `lda_dri`, `stw_dri`,
`stl_dri` (no `3`), while the *load* side really is `ld_sril3`.

## Known gap

Sub-opcode `0x57` = `ld (mem),SP` cannot be spelled: `GR16` excludes `SP`.
It occurs **zero** times across all seven images, so nothing needs it today;
use `.byte` if it ever appears.

## Numbers (2026-08-22, LLVM `tlcs900_backend@cb165c5cdc4b`)

Images scanned: `kn5000_v7_program.rom`, `kn5000_v9_program.rom`,
`kn5000_v10_program.rom`, `kn5000_table_data.rom`,
`kn5000_subprogram_v142.rom`, `kn5000_subcpu_boot.ic30`,
`hd-ae5000_v2_06i.ic4`.

* 2218 printed `ld (r+r),...` instances; 1648 are the register-source form
  (the other 570 are sub-opcode `0x00`/`0x02` immediates and `0x14`
  memory-to-memory — different instructions that share the printed prefix).
* TEST 1 assembled bytes == ROM bytes: **1648 / 1648**
* TEST 2 assembled bytes re-disassemble to the identical text: **1648 / 1648**
* TEST 3 negative controls produced different bytes: **4 / 4**
* 26 distinct (mode, sub-opcode) pairs; 133 distinct full byte strings.
  Sub-opcodes exercised by real code: `0x40`–`0x47` (all eight),
  `0x50`–`0x56`, `0x60`, `0x62`, `0x63`, `0x66`.
  `0x61`, `0x64`, `0x65`, `0x67` were verified by direct assembly instead.

**What would falsify this:** any site where `llvm-mc` emits bytes other than
the ROM's. TEST 1 prints and counts every such mismatch; it reported none.
