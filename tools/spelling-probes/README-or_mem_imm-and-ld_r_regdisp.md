# `or (r+imm),imm` and `ld r,(r+imm)` — both spellable, neither a backend gap

Two forms `convert_reachable_ranges.py --forms` reports as unspellable.  Both
are cause (a) of the four causes: **a spelling not tried**.  Nothing is missing
from the TLCS-900 LLVM backend for either of them.

Toolchain used: `llvm-project` @ `bcf152d1fe00` (branch `tlcs900_backend`),
`~/compartilhado/tools/unidasm`, ROM `original_ROMs/kn5000_v7_program.rom`
(load base 0xE00000).

## What the encodings are

The first byte of a TLCS-900 memory operand selects **both** the addressing mode
and the operand width:

| first byte | meaning |
|---|---|
| `0x80+r` / `0x88+r` | `(XRR)` / `(XRR+d8)`, **byte** width |
| `0x90+r` / `0x98+r` | `(XRR)` / `(XRR+d8)`, **word** width |
| `0xA0+r` / `0xA8+r` | `(XRR)` / `(XRR+d8)`, **long** width |

`r` = 0..7 = XWA, XBC, XDE, XHL, XIX, XIY, XIZ, XSP.

* `ld <reg>,(mem)` is sub-opcode `0x20 + regnum`.
* memory-immediate ALU is sub-opcodes `0x38..0x3F`
  (ADD, ADC, SUB, SBC, AND, XOR, **OR = 0x3E**, CP), with an 8-bit immediate
  under the byte prefix and a 16-bit one under the word prefix.

## Rule OR-1 — `or (mem),imm` is spelled `ormi8` / `ormi16`

`OR8mi` and `OR16mi` exist in `TLCS900InstrInfo.td`, but unlike `AND8mi` and
`CP8mi` they were never renamed to their real mnemonic, so they answer **only**
to the invented names.  `or (xsp+0x02), 0x03` therefore fails with
"invalid operand for instruction" and reads exactly like a missing instruction.

Whole family, all confirmed against `llvm-mc --show-encoding`:

| unidasm | spelling that matches | 8-bit | 16-bit |
|---|---|---|---|
| `add` | `addmi8` / `addiw_da` | 0x38 | 0x38 |
| `adc` | `adcmi8` / `adcmi16` | 0x39 | 0x39 |
| `sub` | `submi8` / `submi16` | 0x3A | 0x3A |
| `sbc` | `sbcmi8` / `sbcmi16` | 0x3B | 0x3B |
| `and` | `and` / `andw` (aliases `andmi8`/`andmi16`) | 0x3C | 0x3C |
| `xor` | `xormi8` / `xormi16` | 0x3D | 0x3D |
| `or`  | **`ormi8` / `ormi16`** | 0x3E | 0x3E |
| `cp`  | `cp` / `cpw` | 0x3F | 0x3F |

Only `and` and `cp` carry the real mnemonic; every other member needs the
invented one.  `add (xsp+0x02), 0x03` is rejected for the same reason `or` is.

## Rules LD-1 / LD-2 — the displacement text is not the displacement

unidasm prints the `d8` field as a **raw byte**, which loses two things:

* **LD-1, the zero-displacement sentinel.**  `+0x00` written literally folds to
  the two-byte no-displacement form `0x80+r`, a different instruction.  The
  emitter (`TLCS900MCCodeEmitter.cpp`) reserves displacement **256** to mean
  "wide form, displacement 0", so `ld C,(XSP+0x00)` is `ld c, (xsp+0x100)`.
* **LD-2, the sign.**  `+0xff` written literally selects the five-byte
  16-bit-displacement form (prefix `0xC3`/`0xD3`/`0xE3`).  `ld A,(XBC+0xff)` is
  `ld a, (xbc - 0x01)`.

Both apply to the `MEMri` operand class generally, so they hold for `ormi8` /
`ormi16` too (`ormi8 (xwa+0x100), 0x03` = `88 00 3e 03`).

## The scripts

| script | question it answers | how to run |
|---|---|---|
| `blocking_or_ld_regdisp.py` | which v7 reachable-range sites of the two forms can the converter spell today, and do the proposed rules close the rest? | `python3 tools/spelling-probes/blocking_or_ld_regdisp.py` |
| `verify_or_mem_imm.py` | is `ormi8`/`ormi16` byte-exact across the whole addressing space, and does the plain `or` spelling ever leak the same bytes? | `python3 tools/spelling-probes/verify_or_mem_imm.py` |
| `verify_ld_r_regdisp.py` | are LD-1 and LD-2 byte-exact for every (width, base, destination, displacement)? | `python3 tools/spelling-probes/verify_ld_r_regdisp.py` |

Each exits 0 on success and prints its counts.

## Results as measured 2026-08-23

```
blocking_or_ld_regdisp.py   1355 sites; 1337 already spellable,
                            18 closed by the proposed rules, 0 left
verify_or_mem_imm.py        792 byte-exact / 0 wrong / 0 rejected,
                            0 negative-control leaks
verify_ld_r_regdisp.py      920 byte-exact / 0 wrong / 40 rejected,
                            0 negative-control leaks
```

The 40 rejections are all `ld SP,(XRR+d)` — the 16-bit stack pointer.  That is a
**separate, genuine gap**, and of cause (d), an operand class too narrow:
`GR16` in `TLCS900RegisterInfo.td` is `(add WA, BC, DE, HL, IX, IY, IZ)` and
omits `SP`; `GR16SP` right beside it includes it and is already used by the
push/pop short forms.  The encoding `0x98+r, d8, 0x27` is perfectly valid.  It
does **not** occur at any site of these two forms in v7's reachable ranges
(destination histogram: XWA 381, WA 339, A 239, C 93, XBC 76, DE 47, BC 34,
XDE 29, E 18, HL 15, XIX 13, XHL 13, L 12, XIY 10, IZ 8, W 6, IY 6, XIZ 3,
IX 2, **SP 0**), so it is recorded here rather than acted on.
