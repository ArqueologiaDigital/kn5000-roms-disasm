# `cp r,(imm)` follow-up: four more binaries, all eight trees, and what is left

`README-cp_reg_direct.md` established the spelling rule on the three maincpu
revisions and the table-data ROM. This follow-up answers three questions it left
open, with three new scripts. **The rule itself is unchanged and is confirmed.**

| script | question it answers | command |
|---|---|---|
| `verify_cp_reg_direct_allbins.py` | Does the rule hold on the four dumped binaries nobody checked — the sub-CPU payload, the sub-CPU boot ROM, the HD-AE5000 ROM, the custom-data ROM? | `python3 tools/spelling-probes/verify_cp_reg_direct_allbins.py` |
| `… --negative` | Can the check fail? Runs the plausible-but-wrong rule (address width from the VALUE). | `python3 tools/spelling-probes/verify_cp_reg_direct_allbins.py --negative` |
| `… --dangerous` | Which near-miss spellings assemble and emit the WRONG bytes? Assembles each live. | `python3 tools/spelling-probes/verify_cp_reg_direct_allbins.py --dangerous` |
| `blob_cp_reg_direct_alltrees.py` | Where are the sites that still block conversion — in EVERY tree, not just v7? | `python3 tools/spelling-probes/blob_cp_reg_direct_alltrees.py` |
| `frame_cp_reg_direct_blobs.py` | Of those, which are real instructions and which are data? Prints the owning label and a reframe window per site. | `python3 tools/spelling-probes/frame_cp_reg_direct_blobs.py [tree]` |

Signal read: the raw bytes of the ROM **file** at `address - ORIGIN`; the
scripts assert file bytes == unidasm listing bytes at every site and die on the
first disagreement. PASS = `llvm-mc -triple=tlcs900 --show-encoding` emits
exactly those bytes. "Assembled without error" is NOT a pass.

## The rule (unchanged — restated so this file stands alone)

    c1 al ah    F0+r   (4B)  ->  cpda8     <GR8[r]>, (0x<ah><al>)
    d1 al ah    F0+r   (4B)  ->  cpda16    <GPR[r]>, (0x<ah><al>)
    e1 al ah    F0+r   (4B)  ->  cpda32    <GPR[r]>, (0x<ah><al>)
    c2 a0 a1 a2 F0+r   (5B)  ->  cpda8_24  <GR8[r]>, (0x<a2><a1><a0>)
    d2 a0 a1 a2 F0+r   (5B)  ->  cpda16_24 <GPR[r]>, (0x<a2><a1><a0>)
    e2 a0 a1 a2 F0+r   (5B)  ->  cpda32_24 <GPR[r]>, (0x<a2><a1><a0>)
    c0 aa       F0+r   (3B)  ->  no spelling exists
    d0 aa       F0+r   (3B)  ->  no spelling exists
    e0 aa       F0+r   (3B)  ->  no spelling exists

    r      = last byte & 7
    GR8[r] = w a b c d e h l
    GPR[r] = xwa xbc xde xhl xix xiy xiz xsp

Byte 0's **high** nibble is the OPERAND SIZE (`c` byte, `d` word, `e` long) and
its **low** nibble is the ADDRESS WIDTH (`0` 8-bit, `1` 16-bit, `2` 24-bit).
`cpda16`/`cpda32` take the X-names even for word operands.

## Result 1 — the rule is the encoding, not one compiler's habit

    binary                              spellable   no spelling (c0/d0/e0)
    kn5000_v7_program.rom      @E00000   864 / 864   28
    kn5000_v9_program.rom      @E00000   865 / 865   33
    kn5000_v10_program.rom     @E00000   865 / 865   33
    kn5000_table_data.rom      @800000    99 /  99   94
    kn5000_subprogram_v142.rom @00EF00     8 /   8   51    <- NEW
    kn5000_subcpu_boot.ic30    @FE0000     0 /   0    0    <- NEW
    hd-ae5000_v2_06i.ic4       @280000    38 /  38    5    <- NEW
    kn5000_custom_data.ic19    @300000     0 /   0    0    <- NEW
    GRAND TOTAL                          2739 / 2739 byte-exact, 0 failures

The four new binaries contribute 46/46. They are different code streams —
another CPU's payload and a third-party extension board's ROM — so the rule
derived on the maincpu is a property of the TLCS-900 encoding.

Negative control (address width taken from the address VALUE, which is what a
reader of the printed text would do): **2546 / 2739, 193 failures**. The check
can fail. Two of those failures are in hd-ae5000 and the old probe never saw
them: `2a49d8: e2 00 dd 00 f7` and `2a6280: c2 14 2a 00 f4`, both 24-bit
encodings of an address that fits in 16 bits.

### A load base the earlier probe got wrong

`verify_cp_reg_direct.py` disassembles `kn5000_table_data.rom` at **0x200000**;
`table_data/table_data.ld` says `ORIGIN = 0x800000` and 0x200000 is the region
LENGTH. Every table_data address in `README-cp_reg_direct.md` is therefore
0x600000 too low. The **rule is unaffected** — it reads only the raw bytes, and
no operand of this form is PC-relative — but the addresses are. The new scripts
use each linker script's ORIGIN.

## Result 2 — what is left, per tree

    tree          .byte runs   located   spellable   no spelling
    v7/maincpu          8184      2751         346          0
    v9/maincpu         17541       837          15          2
    v10/maincpu        17540       837          15          2
    v142/subcpu          301       111           5         49
    subcpu                 8         5           0          0
    table_data          5439      2277           6          2
    custom_data           10         9           0          0
    hdae5000            4922       411           1          1
    TOTAL                                       388         56

v9 and v10 report the same 17 sites at the same addresses — the revisions differ
by 3 bytes, so that is one set counted twice.

## Result 3 — none of the 56 unspellable sites is an instruction

`frame_cp_reg_direct_blobs.py` prints, per site, the nearest preceding label —
the project's own statement about what the bytes are — and a window decoded from
the run start.

| where | n | label | verdict |
|---|---|---|---|
| v142 subcpu | 44 | `DSP_Eff32_Algo_Bytecode` | DSP microprogram stream. The `0xF0` unidasm reads as the compare's register byte is the stream's END MARKER — the file's own comment reads "1 instruction: op3(215); 0xf0 end". |
| v142 subcpu | 5 | `DSP_EffA_Param_Values` | DSP parameter values. |
| v9 + v10 | 1 (×2) | `AccPlayMode_Dispatch_Table` | An 8-entry table of 4-byte little-endian pointers at `f5adf9..f5ae18`: `00f5ae19 00f5af4d 00f5afd0 00f5b004 00f5afb7 00f5af3c 00f5afb2 00f5af9d`. Every one is in range and the first is the address just past the table. `f5ae01: d0 af f5` is bytes 0-2 of entry #2. |
| table_data | 2 | `ToneDB_VelocityCurve_0` | 6-byte records whose first field counts `01 02 03 04 05`. |
| hdae5000 | 1 | `HDAE5000_UI_Page_Titles` | three bytes before the 4-byte pointer `0029f6f0`. |
| v9 + v10 | 1 (×2) | `MidiCh_ConfigVoiceAndParts` | **A MISFRAME, not data.** See below. |

So the conclusion of the earlier whole-ROM census — do not add a backend
definition for the 8-bit-direct compare — is reached again from the converter's
side, on five more objects it never looked at.

### The one misframe, and the real gap it hides

At `fc8e6f` the instruction stream is

    fc8e6f: c1 e4 8e 19 e0 8e   ld (0x8ee0),(0x8ee4)     <- memory-to-memory, 6 bytes
    fc8e75: f1 e4 8e bf         set 7,(0x8ee4)
    fc8e79: f1 e4 8e cf         bit 7,(0x8ee4)

`v9/maincpu/audio/audio_control_engine.s:4975` splits that 6-byte load, emitting
`pop_f` for its interior `0x19` byte. The `.byte` run therefore restarts at
`fc8e73`, mid-instruction, and the `cp XBC,(0x8e)` decoded there is an artefact
of the split. **The missing spelling at that address is `ld (nn),(nn)`, not the
8-bit-direct compare.** Whatever converter counts blockers should not count this
one against `cp r,(imm)`.

## Spellings that ASSEMBLE and emit the WRONG bytes

Run `--dangerous` to reproduce live. Newly recorded here, beyond the earlier
table:

    cpda32 xwa, (0x0ee8)   e1 e8 0e f0   ROM d1 e8 0e f0
        *** THE SIZE TRAP. The printed text says `cp WA,(0x0ee8)` -- WA, a word.
        But cpda16 rejects `wa` and wants the X-name, so a converter that reads
        the printed register name, sees it must write an X-name, and reaches for
        the "32" mnemonic lands on the LONG compare. Same length, same printed
        text after a round trip, different instruction.
    cpda8 a, (0x0ee8)      c1 e8 0e f1   ROM d1 e8 0e f0   the trap the other way
    cpda16 xiy, (0xaf)     d1 af 00 f5   ROM d0 af f5
        *** THE 8-BIT-DIRECT TRAP. There is no spelling for the 3-byte form, so
        the obvious move is to write the 16-bit one. It assembles, it prints the
        same text, it ZERO-EXTENDS the address, and it emits FOUR bytes where the
        ROM has three -- every following byte shifts.
    cpda8 e, (0x06)        c1 06 00 f5   ROM c0 06 f5      same trap (table_data)
    cpda32 xwa, (0x00)     e1 00 00 f0   ROM e0 00 f0      same trap (v142)
    cps xwa, 0             e8 d8         ROM e0 00 f0      a different instruction

Reconfirmed from the earlier table: `cp wa,(…)` / `cp a,(…)` are **rejected**
but llvm-mc still prints `encoding: [0xf0]` / `[0xf1]` afterwards — trust the
exit status, never the listing; `cp xwa,(…)` is always `e2` + a 24-bit
relocation (5 bytes); `cpda16 wa` is rejected; `cpda16/32` silently TRUNCATE a
24-bit address to 4 bytes; and in `cpda8` the X-names mean that register's low
byte, with `xde ≡ xiy` (`f5`) and `xhl ≡ xsp` (`f7`) colliding.

## Provenance

llvm `tlcs900_backend@cb165c5cdc4b`; unidasm `~/compartilhado/tools/unidasm`;
sources at `b081be6`. Every number above is printed by one of the three scripts.
