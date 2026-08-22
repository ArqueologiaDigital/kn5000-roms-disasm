# Probe: llvm-mc spelling for the unidasm form `res N,(imm)`

One printed text, `res 0,(0x26e2)`, is **three** different TLCS-900 encodings —
one per direct-address width (8 / 16 / 24 bit). The printed text does not say
which. A converter turning `.byte` blobs into instructions must choose between
them from the RAW BYTES.

Good news for this form: **all three are already spellable.** Nothing has to be
added to the backend.

| script | question it answers | command |
|---|---|---|
| `verify_res_bit_direct.py` | Does the proposed spelling rule assemble byte-exactly at **every** `res N,(imm)` site in v7, v9, v10 and the table-data ROM? | `python3 tools/spelling-probes/verify_res_bit_direct.py` |
| `verify_res_bit_direct.py --negative` | Can this check fail? Runs the plausible-but-wrong rule a reader of the printed text would write (address width from the VALUE). | `python3 tools/spelling-probes/verify_res_bit_direct.py --negative` |
| `verify_res_bit_direct.py --dangerous` | Which near-miss spellings assemble and emit the WRONG bytes? Assembles each one live. | `python3 tools/spelling-probes/verify_res_bit_direct.py --dangerous` |
| `code_or_data_res_bit_direct.py` | Of the whole-ROM sweep hits, which are real instructions — per address width? | `python3 tools/spelling-probes/code_or_data_res_bit_direct.py` |
| `blob_res_bit_direct.py` | How many such sites still sit inside un-converted `.byte` blobs, and in which file? | `python3 tools/spelling-probes/blob_res_bit_direct.py v7` |

Signal read: the raw ROM bytes at each address (`original_ROMs/kn5000_<v>_program.rom`
at load base 0xE00000, `kn5000_table_data.rom` at 0x200000). PASS =
`llvm-mc -triple=tlcs900 --show-encoding` output equals those bytes.
"Assembled without error" is NOT a pass.

## The rule

    f0 aa        0xB0+bit   (3B)  ->  res_dd8  <bit>, 0x<aa>
    f1 al ah     0xB0+bit   (4B)  ->  resda    <bit>, (0x<ah><al>)
    f2 a0 a1 a2  0xB0+bit   (5B)  ->  resda_24 <bit>, (0x<a2><a1><a0>)

    bit = last byte & 7, and (last byte & 0xF8) must be 0xB0.

Byte 0 is the **destination-direct prefix** and it alone gives the address
width: `f0` = 8-bit, `f1` = 16-bit, `f2` = 24-bit. The last byte is the bit-op
sub-opcode `0xB0+bit`; `0xB8+bit` would be SET, `0xC8+bit` BIT, `0xA0+bit` TSET.
No other prefix prints as `res N,(0xADDR)`: the `b0`..`bf` and `f3`/`f4`/`f5`
sites print the register-indirect forms (`res 0,(XWA)`, `res 3,(XSP+0x12)`).

Note the **operand-shape asymmetry**, which is easy to get wrong:
`res_dd8` wants a **bare** immediate address, `resda` and `resda_24` want a
`directaddr` operand and therefore parentheses. `resda 0, 9954` (decimal, no
parens) is also accepted and is what most of the v9 sources actually use;
`res_dd8 0, (0x20)` is likewise accepted.

Reading the width back from unidasm TEXT alone also works, because unidasm
zero-pads the address to the encoded width: 2 hex digits ⇔ `f0`, 4 ⇔ `f1`,
6 ⇔ `f2`. Verified: printed digit count and prefix agree on **1395 / 1395**
sites. Do NOT derive the width from the address VALUE — that is what
`--negative` measures, and it is wrong 13 times.

## Results, 2026-08-22, llvm tlcs900_backend@cb165c5cdc4b

    v7      444 / 444 byte-exact   ( 21 f0 + 414 f1 +  9 f2)
    v9      446 / 446 byte-exact   ( 22 f0 + 415 f1 +  9 f2)
    v10     446 / 446 byte-exact   ( 22 f0 + 415 f1 +  9 f2)
    table    59 /  59 byte-exact   ( 30 f0 +  14 f1 + 15 f2)
    GRAND TOTAL 1395 / 1395 sites byte-exact, 0 failures, 0 unspellable

    --negative (address width from the VALUE):  1382 / 1395, 13 failures

Real instructions, source-anchored in the byte-exact v9 build (`cmp` of the
rebuild against `original_ROMs/kn5000_v9_program.rom` is silent), one per
encoding class:

| address | ROM bytes | unidasm | v9 source line |
|---|---|---|---|
| 0xEF35C4 | `f0 68 b1` | `res 1,(0x68)` | `res_dd8 1, 0x68` (boot/system_handlers.s:5950 — MSTAT1 ack) |
| 0xEF04BE | `f1 66 01 b4` | `res 4,(0x0166)` | `resda 4, 358` (shared/boot_hw_init.s:118) |
| 0xEF4BA7 | `f2 04 00 16 b0` | `res 0,(0x160004)` | `resda_24 0, (0x160004)` (boot/system_handlers.s:8332 — HD-AE5000 PPI port C) |

and the form named in the task, from v7 (`f1 e2 26 b0` at 0xF37122,
0xF37133, 0xF3891A, 0xF3E036, 0xF3EC2D, 0xF46B4D → `resda 0, (0x26e2)`).

End-to-end check that the assembler emits the same bytes through a real object
file, not only in `--show-encoding`:

    printf '\t.text\n\tres_dd8 1, 0x68\n\tresda 0, (0x26e2)\n\tresda_24 0, (0x160004)\n' > /tmp/three.s
    llvm-mc -triple=tlcs900 -filetype=obj /tmp/three.s -o /tmp/three.o
    llvm-objcopy -O binary --only-section=.text /tmp/three.o /tmp/three.bin && xxd /tmp/three.bin
    # f0 68 b1  f1 e2 26 b0  f2 04 00 16 b0

## Code or data? All three widths are real — unlike `cp r,(imm)`

`code_or_data_res_bit_direct.py` re-assembles the v9 sources with `llvm-mc -g`,
proves the result is still byte-identical to the original ROM, and reads the
DWARF line table, which carries one row per emitting source statement.

    f0  8-bit direct  (res_dd8)     12 /  22 sweep hits are real code
    f1 16-bit direct  (resda)      322 / 415
    f2 24-bit direct  (resda_24)     6 /   9
    TOTAL                          340 / 446

Two cross-checks, both clean:

* every one of the 340 rows lands on a line number that some source file spells
  as `res_dd8`/`resda`/`resda_24`; **0** land on anything else;
* a plain grep of the v9 sources counts exactly **12 / 322 / 6** such
  statements — the same three numbers, arrived at independently.

  ⚠ that grep must be `grep -a`. Several `.s` files carry 8-bit bytes in string
  tables, so plain grep calls them binary and prints one line for the whole
  file: that mistake first reported `resda` as 112 instead of 322.

This differs from `cp r,(imm)`, where the 8-bit-direct class was 100% data and
unspellable. Here it is neither: `res_dd8` exists, and its 12 real sites are
**SFR writes** — addresses 0x20, 0x30, 0x34, 0x3c, 0x44, 0x68 (MSTAT) and 0x80,
all inside the TMP94C241's own 256-byte I/O page, which is exactly what 8-bit
direct addressing is for. A converter must not dismiss `f0` runs as data.

The other 106 sweep hits are the linear scan reading data (or a still-`.byte`
region) as code.

## Where the un-converted sites are

`blob_res_bit_direct.py`:

    v7   8184 runs / 429841 blob bytes; 2751 placed
         183 sites (733 bytes): 182 f1 + 1 f2, NO f0.  54 are bit 0.
         top files: sequencer_engine.s 47, midi_dispatch_handlers.s 33,
                    dsp_config_sysex.s 20
    v9  17541 runs / 108057 blob bytes;  837 placed
         30 sites: 5 f0 + 25 f1.  8 are bit 0.
    v10  identical to v9.

Two-sided bound: upper, because a linear scan of a table also decodes this way;
lower, because the locator only places runs ≥ 8 bytes whose bytes are unique in
the ROM. The five v9/v10 `f0` blob hits all sit in
`includes/gui_display_struct_data.s` — a widget table, not code.

## Spellings that ASSEMBLE and emit the WRONG bytes

Run `--dangerous` to reproduce this table live.

    res 0, (0x26e2)         f2 + a 24-bit RELOCATION. The literal unidasm text
                            DOES assemble -- it matches the `resm` InstAlias --
                            and always emits the 24-bit form, 5 bytes. It is a
                            valid alternative spelling of resda_24 and NEVER of
                            resda or res_dd8.
    res 0, (0x00)           f2 + reloc, 5 bytes where the f0 form is 3
    resm 0, (0x26e2)        same alias, same wrong width
    res 0, 0x26e2           rejected -- the alias needs the parentheses
    resda 0, (0x00ffc2)     f1 c2 ff b0 -- 24-bit address SILENTLY TRUNCATED,
                            4 bytes where the ROM has 5
    resda 0, (0x1ffc2)      f1 c2 ff b0 -- ditto, no diagnostic at all
    res_dd8 0, 0x26e2       f0 e2 b0 -- 16-bit address SILENTLY TRUNCATED to
                            its LOW BYTE, 3 bytes where the ROM has 4
    resda_24 0, (0x26e2)    f2 e2 26 00 b0 -- 5 bytes where the 16-bit form is 4
    resda 8, (0x1234)       f1 34 12 b8 = `set 0,(0x1234)`. The bit number is
                            NOT masked to 3 bits: 8 carries into the sub-opcode
                            and turns RES into SET. Same for `res_dd8 8, 0x20`.
    resda (0x26e2), 0       f1 00 00 b2 = `res 2,(0x0000)` -- operands swapped
                            assembles happily and means something else

The `resda 8` case is the nastiest: it is the only one that changes the
*operation* rather than the operand width, and nothing warns.
