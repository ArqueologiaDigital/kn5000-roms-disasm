# Probe: `ld SP,#imm16` — a real backend gap, worth **zero** bytes

`convert_reachable_ranges.py --forms` lists `ld r,imm` as a blocker with the
example `ld SP,0x0000`. Two questions, and the answers point in opposite
directions.

| script | question it answers | command |
|---|---|---|
| `verify_ld_sp_imm16.py` | Does ANY spelling emit `37 lo hi`? Includes a brute force over all 664 mnemonics in `TLCS900InstrInfo.td`. | `python3 tools/spelling-probes/verify_ld_sp_imm16.py original_ROMs/kn5000_v{7,9,10}_program.rom` |
| `blocking_ldmm_and_ldsp.py` | Which sites block the converter, and what would the spelling release? | `python3 tools/spelling-probes/blocking_ldmm_and_ldsp.py --marginal` |

## 1. The gap is real

`0x30+r, imm16` is the 3-byte short form of `LD r16,#nn`. `r=7` is SP, so
`37 00 00` is `LD SP,#0x0000`; every other register in the family spells today
(`ldw iz, 0x0000` → `[0x36,0x00,0x00]`).

    TLCS900InstrInfo.td:1778
      def LD16ri_short : SingleByteRegImmInst<0x30, 3, (outs GR16:$rd),
                                              (ins i16imm:$imm), "ldw", ...>

`GR16` (`TLCS900RegisterInfo.td:95`) is `WA BC DE HL IX IY IZ` — **seven**
registers. SP lives only in `GR16SP` (line 99). So `r=7` has no operand to name.

Measured: **0 of 1092 v7 sites, 0 of 1073 v9, 0 of 1073 v10** are spellable, and
a brute force over 664 mnemonics × {`sp`,`xsp`} × {`imm`,`imm16`} produces
**0 spellings whose first byte is `0x37`**. This is not a naming trap: the
parser does know the register (`pushw sp` → `[0x2f]`), and `LD16ri_short` is the
only def in the backend that can emit a leading `0x30..0x37` in three bytes.

**The two directions of the backend disagree.**
`TLCS900Disassembler.cpp:2198` builds `LD16ri_short` with `decodeGR16(7) =
TLCS900::SP`, so `llvm-mc -disassemble` happily prints `ldw sp, 0` — text that
`llvm-mc` then refuses with *invalid operand for instruction*. The probe
demonstrates the round trip rather than asserting it.

### Shape of the fix (proposed, not applied — the backend was not rebuilt)

    -  def LD16ri_short : SingleByteRegImmInst<0x30, 3, (outs GR16:$rd),
    +  def LD16ri_short : SingleByteRegImmInst<0x30, 3, (outs GR16SP:$rd),

Sibling to mirror: `POP16_short` (`TLCS900InstrInfo.td:796`), `(outs
GR16SP:$rd)` on the same single-byte-plus-register shape. Safe for codegen —
`LD16ri_short` carries an empty pattern and is referenced only by the
disassembler and `TLCS900SchedInstRW.td`, so no ISel rule can allocate SP here.

⚠ `extpfx3 0x37, 0x00, 0x00` assembles to exactly `[0x37,0x00,0x00]`. That is
not a spelling — `extpfx<N>` is a raw-byte emitter used nowhere in the tree.

## 2. And it is worth nothing

Both v7 blocking sites are **data**, and both ranges are refused for reasons the
spelling does not touch:

| site | range | what is really there |
|---|---|---|
| 0xEE5115 `37 00 00` | 0xEE50E7 | a nop/`jr ULE`/`normal`/`pop SR` carpet over a zero-heavy blob; the kept prefix already contains `normal`, so the plausibility screen refuses the range |
| 0xF027A5 `37 0e f3` | 0xF027A4 | the entry is **3 bytes before the real prologue**. The function starts at 0xF027A7 with `f3 fd f2 fe 37` = `lda XSP,XSP+0xfef2` and ends at 0xF02863 `lda XSP,XSP+0x010e` / `ret`; the `0x37` at 0xF027A5 is the last byte of the *preceding* `lda`. Decoding from 0xF027A4 yields `normal / ld SP,0xf30e / swi 5 / …` and fewer than 3 instructions survive |

**Marginal bytes: 0.** ⚠ `v7_blocking_forms_census.py`'s `converted_bytes()`
credits this form with **62 B**, because it replays truncation and the
label-orphan check but **not** the plausibility screen the converter actually
runs. With the screen, the figure is zero. Fix the backend asymmetry on its own
merits if at all; do not do it for these two sites.
