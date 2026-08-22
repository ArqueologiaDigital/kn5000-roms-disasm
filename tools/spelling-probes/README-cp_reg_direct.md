# Probe: llvm-mc spelling for the unidasm form `cp r,(imm)`

One printed text, `cp WA,(0x0ee8)`, is **nine** different TLCS-900 encodings:
three operand sizes (byte / word / long) times three address widths (8 / 16 / 24
bit). A converter turning `.byte` blobs into instructions must choose between
them from the RAW BYTES.

| script | question it answers | command |
|---|---|---|
| `verify_cp_reg_direct.py` | Does the proposed spelling rule assemble byte-exactly at **every** `cp r,(imm)` site in v7, v9, v10 and the table-data ROM? | `python3 tools/spelling-probes/verify_cp_reg_direct.py` |
| `verify_cp_reg_direct.py --negative` | Can this check fail? Runs the plausible-but-wrong rule a reader of the printed text would write (address width from the VALUE). | `python3 tools/spelling-probes/verify_cp_reg_direct.py --negative` |
| `verify_cp_reg_direct.py --dangerous` | Which near-miss spellings assemble and emit the WRONG bytes? Assembles each one live. | `python3 tools/spelling-probes/verify_cp_reg_direct.py --dangerous` |
| `code_or_data_cp_reg_direct.py` | Of the whole-ROM sweep hits, which are real instructions — and does the unspellable 8-bit-direct form occur in real code at all? | `python3 tools/spelling-probes/code_or_data_cp_reg_direct.py` |
| `blob_cp_reg_direct.py` | How many such sites still sit inside un-converted `.byte` blobs, and in which file? | `python3 tools/spelling-probes/blob_cp_reg_direct.py v7` |

Signal read: the raw ROM bytes at each address (`original_ROMs/kn5000_<v>_program.rom`
at load base 0xE00000, `kn5000_table_data.rom` at 0x200000). PASS =
`llvm-mc -triple=tlcs900 --show-encoding` output equals those bytes.
"Assembled without error" is NOT a pass.

## The rule

    c1 al ah    F0+r   (4B)  ->  cpda8     <GR8[r]>, (0x<ah><al>)
    d1 al ah    F0+r   (4B)  ->  cpda16    <GPR[r]>, (0x<ah><al>)
    e1 al ah    F0+r   (4B)  ->  cpda32    <GPR[r]>, (0x<ah><al>)
    c2 a0 a1 a2 F0+r   (5B)  ->  cpda8_24  <GR8[r]>, (0x<a2><a1><a0>)
    d2 a0 a1 a2 F0+r   (5B)  ->  cpda16_24 <GPR[r]>, (0x<a2><a1><a0>)
    e2 a0 a1 a2 F0+r   (5B)  ->  cpda32_24 <GPR[r]>, (0x<a2><a1><a0>)
    c0 aa       F0+r   (3B)  ->  no spelling exists (and no real instance: see below)
    d0 aa       F0+r   (3B)  ->  no spelling exists
    e0 aa       F0+r   (3B)  ->  no spelling exists

    r      = last byte & 7
    GR8[r] = w a b c d e h l
    GPR[r] = xwa xbc xde xhl xix xiy xiz xsp

Byte 0's **high** nibble picks the OPERAND SIZE (`c` = byte, `d` = word,
`e` = long) and its **low** nibble picks the ADDRESS WIDTH (`0` = 8-bit direct,
`1` = 16-bit, `2` = 24-bit). The last byte is `0xF0+r`.

Two traps in the operand shape:

* `cpda16`/`cpda32` want the **X-names even for word operands**: `cpda16 xwa`
  *is* `cp WA,(...)`; `cpda16 wa` is rejected. The mnemonic's number is the
  operand size, the register name is just an index into the register file.
* `cpda8` wants the GR8 names. It also **accepts** the X-names and then silently
  means that register's low byte — `cpda8 xbc` → `f3` = C, not `f1` = B — with
  `xde`/`xiy` and `xhl`/`xsp` colliding on the same encoding.

The address may be written with or without parentheses (`cpda8 a, 0x34d7` and
`cpda8 a, (0x34d7)` are the same instruction); this tree's v9 sources use both.

Reading it back from unidasm TEXT alone also works, because unidasm zero-pads
the address to the encoded width: 2 hex digits ⇔ prefix `?0`, 4 ⇔ `?1`,
6 ⇔ `?2`. Verified: prefix low nibble and printed digit count agree on
**2881 / 2881** sites across v7, v9, v10 and table_data. Do NOT derive the width
from the address VALUE — that is what `--negative` measures, and it is wrong 191
times.

## Results, 2026-08-22, llvm tlcs900_backend@cb165c5cdc4b

    v7     864 /  864 byte-exact   (325 c1 + 258 d1 + 96 e1 + 62 c2 + 84 d2 + 39 e2)
    v9     865 /  865 byte-exact   (325 + 257 + 96 + 62 + 85 + 40)
    v10    865 /  865 byte-exact
    table   99 /   99 byte-exact   (14 + 15 + 14 + 13 + 19 + 24)
    GRAND TOTAL 2693 / 2693 spellable sites, 0 failures

    --negative (address width from the VALUE):  2502 / 2693, 191 failures

    188 further sweep hits use c0/d0/e0, for which no spelling exists.

Real instructions, source-anchored in the byte-exact v9 build (`cmp
rebuilt_ROMs/kn5000_v9_program.llvm.rom original_ROMs/kn5000_v9_program.rom` is
silent), one per encoding class:

| address | ROM bytes | unidasm | v9 source line |
|---|---|---|---|
| 0xEF0ED4 | `c1 d7 34 f1` | `cp A,(0x34d7)` | `cpda8 a, 0x34d7` (boot/system_handlers.s:715) |
| 0xEF1723 | `d1 72 33 f0` | `cp WA,(0x3372)` | `cpda16 xwa, 0x3372` (:1735) |
| 0xEF4C0C | `e1 3e 06 f0` | `cp XWA,(0x063e)` | `cpda32 xwa, 1598` (:8366) |
| 0xF26FE5 | `c2 e3 ff 00 f1` | `cp A,(0x00ffe3)` | `cpda8_24 a, (0xffe3)` |
| 0xEF093C | `d2 d4 ff 00 f3` | `cp HL,(0x00ffd4)` | `cpda16_24 xhl, (0xffd4)` (:103) |
| 0xFF0B3A | `e2 2c d5 03 f4` | `cp XIX,(0x03d52c)` | `cpda32_24 xix, (0x3d52c)` (audio/note_voice_mapping.s:28617) |

End-to-end check that the assembler emits the same bytes through a real object
file, not only in `--show-encoding`:

    printf '\t.text\n\tcpda8 a, (0x34d7)\n\tcpda16 xwa, (0x3372)\n\tcpda32 xwa, (0x063e)\n\tcpda8_24 a, (0xffe3)\n\tcpda16_24 xhl, (0xffd4)\n\tcpda32_24 xix, (0x03d52c)\n' > /tmp/six.s
    llvm-mc -triple=tlcs900 -filetype=obj /tmp/six.s -o /tmp/six.o
    llvm-objcopy -O binary --only-section=.text /tmp/six.o /tmp/six.bin && xxd /tmp/six.bin
    # c1 d7 34 f1  d1 72 33 f0  e1 3e 06 f0
    # c2 e3 ff 00 f1  d2 d4 ff 00 f3  e2 2c d5 03 f4

## Negative result: the 8-bit-direct form is not a gap worth filling

`TLCS900InstrFormats.td` gives `AddrWidth` a single bit — 16- or 24-bit direct
addressing only — so `c0`/`d0`/`e0` + `F0+r` has no mnemonic in any spelling.
That is a real hole in the backend, and it does not matter:

`code_or_data_cp_reg_direct.py` re-assembles the v9 sources with `llvm-mc -g`,
proves the result is still byte-identical to the original ROM, and reads the
DWARF line table, which carries one row per emitting source statement (13 rows
for the 13 instructions in 0xEF0EB3..0xEF0EDF; none inside an `.incbin` bitmap).
An instruction the sources really contain must start a row.

    c0/d0/e0   8-bit direct     0 /  33 sweep hits are real code
    c1/d1/e1  16-bit direct   450 / 678
    c2/d2/e2  24-bit direct   101 / 187

The check can come out positive — it does, 551 times. It comes out zero for the
8-bit-direct class. Every one of those 33 is a linear sweep reading a pointer
table, a widget descriptor or an `.incbin` bitmap as code; e.g. `f0ee9f: d0 00
f1` sits inside the jump table that `SeMenu_ShowPopupDialog` loads with
`ld XIY,0x00f0ee9b` / `ld XIY,(XIY+HL)`.

`blob_cp_reg_direct.py v7` agrees from the other side: of the 346 `cp r,(imm)`
sites (1426 bytes) still inside v7 `.byte` blobs — 167 `c1`, 136 `d1`, 1 `e1`,
18 `c2`, 21 `d2`, 3 `e2` — **none** is `c0`/`d0`/`e0`.

So: do not add a TLCS900 `.td` definition for the 8-bit-direct compare on the
strength of a linear-sweep census. Leave `c0`/`d0`/`e0` runs as `.byte`; they
are data.

## Spellings that ASSEMBLE and emit the WRONG bytes

Run `--dangerous` to reproduce this table live.

    cp a, (0x1234)          rejected: "byte/word direct memory load not encodable"
                            -- and llvm-mc STILL prints `encoding: [0xf1]` after
                            the error, so trust the exit status, not the listing
    cp wa, (0x1234)         rejected: same
    cp xwa, (0x1234)        e2 + a 24-bit RELOCATION: always the _24 form, 5
                            bytes. It is a valid alternative spelling of
                            cpda32_24, and never of cpda32.
    cpda16 wa, (0x0ee8)     rejected: cpda16/cpda32 want the X-names
    cpda8 xbc, (0x03ce)     c1 ce 03 f3 -- the LOW BYTE of XBC is C(3), not B(2)
    cpda8 xde, (0x03ce)     c1 ce 03 f5 -- collides with `cpda8 xiy`
    cpda8 xhl, (0x03ce)     c1 ce 03 f7 -- collides with `cpda8 xsp`
    cpda8 a, (0x00ffe3)     c1 e3 ff f1 -- 24-bit address SILENTLY TRUNCATED,
                            4 bytes where the ROM has 5
    cpda16 xhl, (0x00ffd4)  d1 d4 ff f3 -- ditto
    cpda32 xwa, (0x030444)  e1 44 04 f0 -- ditto
    cpda8_24 a, (0x03ce)    c2 ce 03 00 f1 -- 5 bytes where the 16-bit form is 4
    cpda16_24 xwa, (0x0ee8) d2 e8 0e 00 f0 -- ditto
