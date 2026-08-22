# Probe: llvm-mc spelling for the unidasm form `sub r,r` (e.g. `sub C,QIZH`)

Question: what does a `.byte`-blob converter write so that llvm-mc emits *exactly*
the ROM bytes for every site where unidasm prints `sub <REG>,<REG>`?

| script | question it answers | command |
|---|---|---|
| `verify_sub_rr.py` | Does the spelling rule assemble byte-exactly at **every** `sub REG,REG` site in all 8 KN5000 ROMs? | `python3 verify_sub_rr.py` |
| `sub_rr_gap_is_data.py` | The sites the rule *cannot* spell — are any of them real instructions? | `python3 verify_sub_rr.py && python3 sub_rr_gap_is_data.py` |
| `sub_rr_dangerous_spellings.py` | Which plausible spellings **assemble but produce the wrong bytes**? | `python3 sub_rr_dangerous_spellings.py` |

`sub_rr_unspellable.json` is written by `verify_sub_rr.py` and read by
`sub_rr_gap_is_data.py`; the committed copy is the 2026-08-22 record.

Signal read: the raw ROM bytes at each address, taken from the ROM **file**, not
from the listing text. PASS = `llvm-mc -triple=tlcs900 --show-encoding` output
equals those bytes, same length and same values. "llvm-mc accepted it" is NOT a
pass — one printed text covers two different encodings here.

## The rule (keyed on the RAW BYTES, never on the printed text)

Let the instruction's bytes be `b0 [b1] bN`, `bN` always in `0xA0..0xA7`, and let
`d = bN & 7` index `W A B C D E H L` / `WA BC DE HL IX IY IZ SP` /
`XWA XBC XDE XHL XIX XIY XIZ XSP` by size.

| ROM bytes | size | spelling |
|---|---|---|
| 2 bytes, `b0` in `0xC8..0xCF` | byte | `sub <R8[d]>, <R8[b0&7]>` |
| 2 bytes, `b0` in `0xD8..0xDF` | word | `sub <R16[d]>, <R16[b0&7]>` |
| 2 bytes, `b0` in `0xE8..0xEF` | long | `sub <R32[d]>, <R32[b0&7]>` |
| 3 bytes, `b0 == 0xC7` | byte | `subb_erp <R8[d]>, <b1>` |
| 3 bytes, `b0 == 0xD7` | word | `subw_erp <R16[d]>, <b1>` |
| 3 bytes, `b0 == 0xE7` | long | **no spelling exists** (see gaps) |

In every case the register llvm-mc wants FIRST is the one unidasm prints first
(the destination, carried in the sub-opcode); the second operand is the source —
a register name in the 2-byte form, the raw extended-register byte `b1` in the
3-byte form. `subb_erp` / `subw_erp` are **not new**: they have been in the
backend all along and the v9 sources already use them
(`v9/.../*.s: subw_erp WA, 0xfa`, `subb_erp C, 0xea`).

Verified examples (v7, load base 0xE00000):

```
E1A6C6  sub H,B      -> sub h, b            ca a6
E2E994  sub WA,WA    -> sub wa, wa          d8 a0
E5A514  sub XIZ,XWA  -> sub xiz, xwa        e8 a6
F0E7CF  sub A,QIZL   -> subb_erp a, 0xfa    c7 fa a1
E10736  sub IX,RWA0  -> subw_erp ix, 0x00   d7 00 a4
(task example) sub C,QIZH -> subb_erp c, 0xfb   c7 fb a3
```

`sub C,QIZH` itself occurs in none of the eight ROMs — a byte search for
`c7 fb a3` finds zero hits — so it is verified as a spelling, by encoding, not
by a ROM site.

## Numbers, 2026-08-22, llvm tlcs900_backend@cb165c5cdc4b

3599 sites across the 8 ROMs; **3558 byte-exact (98.86%)**:

```
1590 OK rr32     1403 OK rr16      489 OK rr8       61 OK erpw      15 OK erpb
  16 no spelling: 16-bit operand is SP          12 no spelling: E7 long ERP
  13 no spelling: 16-bit operand is SP (dest)
```

## The two gaps, and why neither blocks a converter

1. **SP as a 16-bit operand** (`df a4` = `sub IX,SP`, `d8 a7` = `sub SP,WA`):
   `GR16` is `WA BC DE HL IX IY IZ` — SP is excluded, so both directions are
   *rejected*, loudly. 29 sites.
2. **The E7 (long) extended-register form** (`e7 e7 a7`): the backend has
   `subb_erp` (C7) and `subw_erp` (D7) but no `subl_erp`. 12 sites. Adding it is
   one line mirroring its byte/word siblings — `ERPRegInst<0xA0, (outs),
   (ins GPR:$rs, i32imm:$bank), "subl_erp", "$rs, $bank">` inside the existing
   `let OpSize = OpSize32.Value` block that already holds `LDTO_LERP`/`LDFR_LERP`.

`sub_rr_gap_is_data.py` shows **41/41** of those sites are data, not code:
0xE0CBA0 falls inside the `SOUND_DATA_ORGAN_ACCORDION` `.incbin`; 0xEAA760,
0xEAA764 and 0xEDB394 fall inside symbolic 32-bit pointer tables (see
`archive/asl/maincpu/kn5000_v10_program.asm:95192`, `dd LABEL_EAA7xx`); the 25
table_data and 1 v142 sites fall inside `.byte` blobs. So neither gap costs a
single real instruction. Independent check that could have failed: no `sub`
instruction anywhere in `v7/ v9/ v10/ v142/ table_data/ subcpu/` has a bare
16-bit `sp` operand.

## Dangerous spellings — these ASSEMBLE and are WRONG

`sub_rr_dangerous_spellings.py` reproduces all of these.

| spelling | assembles to | ROM has | why |
|---|---|---|---|
| `sub c, qizh` | `cb ca 0a` | `c7 fb a3` | `qizh` is not an LLVM register, so it is parsed as an **undefined symbol** and matches `sub r,#imm` |
| `sub l, l` | `cf a7` | `c7 ec a7` | the 2-byte encoding of the same printed text |
| `subb_erp a, 0x1fa` | `c7 fa a1` | — | bank byte silently truncated mod 256 |
| `subb_erp a, -6` | `c7 fa a1` | — | negative bank byte silently wrapped |

The first one is the trap that matters: spelling the unidasm *text*
`sub A,QIZL` / `sub IX,RWA0` / `sub XSP,rE7L` silently yields a **`sub r,#imm`**
against an undefined symbol. Measured blast radius: **48 of the 88 three-byte
sites** are mis-encoded that way; the other 40 are rejected outright.

`sub wa, qiz` is *not* a trap — the `PrevGR16` registers `qwa..qsp` alias bank
bytes `0xE2,0xE6,…,0xFE` and `sub wa, qiz` gives the correct `d7 fa a0`. But
they can only name those eight bytes, so `subw_erp` remains the general form.

LLVM: tlcs900_backend@cb165c5cdc4b (cb165c5cdc4b)
