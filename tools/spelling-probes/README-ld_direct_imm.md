# Probe: llvm-mc spelling for the unidasm form `ld (imm),imm`

One printed text, `ld (0xADDR),0xIMM`, is **eight** different TLCS-900 encodings.
A converter turning `.byte` blobs into instructions must choose between them from
the RAW BYTES; the printed text carries neither the address width nor the data
width.

| script | question it answers | command |
|---|---|---|
| `verify_ld_direct_imm.py` | Does the proposed spelling rule assemble byte-exactly at **every** `ld (imm),imm` site in v7, v9 and v10? | `python3 tools/spelling-probes/verify_ld_direct_imm.py` |
| `verify_ld_direct_imm.py --negative` | Can this check fail? Runs the plausible-but-wrong rule a reader of the printed text would write. | `python3 tools/spelling-probes/verify_ld_direct_imm.py --negative` |
| `blob_ld_direct_imm.py` | How many such sites still sit inside un-converted `.byte` blobs, and in which file? | `python3 tools/spelling-probes/blob_ld_direct_imm.py v7` |

Signal read: the raw ROM bytes at each address (`original_ROMs/kn5000_<v>_program.rom`,
load base 0xE00000). PASS = `llvm-mc -triple=tlcs900 --show-encoding` output equals
those bytes. "Assembled without error" is NOT a pass.

## The rule

    08 aa ii              (3B)  ->  ldio     0xaa, 0xii
    0a aa ll hh           (4B)  ->  ldwio    0xaa, 0x<hh><ll>
    f0 aa 00 ii           (4B)  ->  stib_d8  0xaa, 0xii
    f0 aa 02 ll hh        (5B)  ->  stiw_d8  0xaa, 0xll, 0xhh     <- raw byte PAIR
    f1 al ah 00 ii        (5B)  ->  stdi8    (0x<ah><al>), 0xii
    f1 al ah 02 ll hh     (6B)  ->  stdi16   (0x<ah><al>), 0x<hh><ll>
    f2 a0 a1 a2 00 ii     (6B)  ->  stib_da  (0x<a2><a1><a0>), 0xii
    f2 a0 a1 a2 02 ll hh  (7B)  ->  stiw_da  (0x<a2><a1><a0>), 0x<hh><ll>

Byte 0 is the destination-memory prefix and fixes the ADDRESS width
(`f0` = 8-bit direct, `f1` = 16-bit, `f2` = 24-bit; `08`/`0a` are the standalone
8-bit-direct opcodes). The sub-opcode that follows the address fixes the DATA
width (`0x00` = byte, `0x02` = word). Note the operand shapes differ: the `st*`
mnemonics parenthesise the address, `ldio`/`ldwio` do not (they accept either),
and `stiw_d8` alone wants its 16-bit immediate as **two raw bytes**.

## Results, 2026-08-22, llvm tlcs900_backend@cb165c5cdc4b

    v7  14067 / 14067 byte-exact      (5501 + 4062 + 141 + 3 + 2995 + 730 + 418 + 217)
    v9  14040 / 14040 byte-exact
    v10 14041 / 14041 byte-exact
    GRAND TOTAL 42148 / 42148, 0 failures

    --negative:  0 / 42148 byte-exact, 42148 failures

Inside the remaining v7 `.byte` blobs (`blob_ld_direct_imm.py v7`): 2644 sites,
12126 bytes -- 553 `08`, 413 `0a`, 11 `f0`/4, 1255 `f1`/5, 250 `f1`/6, 138 `f2`/6,
24 `f2`/7. That is an UPPER BOUND: a linear scan of a data table also produces
these decodes, and `note_voice_mapping.s` (966 of the 2644) is a table.

End-to-end check that the assembler emits the same bytes through a real object
file, not only in `--show-encoding`:

    printf '\t.text\n\tldio 0x00, 0x09\n\tldwio 0x00, 0x000b\n\tstib_d8 0x3e, 0x00\n\tstiw_d8 0x00, 0x3d, 0xf0\n\tstdi8 (0x00e0), 0x00\n\tstdi16 (0x8500), 0x0140\n\tstib_da (0x00e0eb), 0x00\n\tstiw_da (0x007600), 0x0100\n' > /tmp/eight.s
    llvm-mc -triple=tlcs900 -filetype=obj /tmp/eight.s -o /tmp/eight.o
    llvm-objcopy -O binary --only-section=.text /tmp/eight.o /tmp/eight.bin && xxd /tmp/eight.bin
    # 08 00 09  0a 00 0b 00  f0 3e 00 00  f0 00 02 3d f0
    # f1 e0 00 00 00  f1 00 85 02 40 01  f2 eb e0 00 00 00  f2 00 76 00 02 00 01

## Spellings that ASSEMBLE and emit the WRONG bytes

None of these errors out. All of them are wrong.

| tried | emits | why it is wrong |
|---|---|---|
| `ld (0x00), 0x09` | `f2 A A A 00 09` | the literal is parsed as a MEMri base *expression*: address becomes a 24-bit **relocation** and the prefix is forced to F2. 6 bytes where the ROM has 3. |
| `ldw (0x00), 0x0002` / `ldmi16 …` / `ldmw2 …` | `f2 A A A …` | same MEMri path. |
| `ldio 0x00, 0x0002` | `08 00 02` | truncates the word immediate: 3 bytes where the ROM has 4 (`0a 00 02 00`). The printed text `ld (0x00),0x0002` invites exactly this. |
| `ldwio 0x00, 0x09` | `0a 00 09 00` | widens a byte store into a word store. |
| `stdi8 (0x3e), 0x00` | `f1 3e 00 00 00` | F1, not F0: 5 bytes where the ROM has 4. |
| `stib_da (0x3e), 0x00` | `f2 3e 00 00 00 00` | F2, not F0. |
| `stdi8 (0x00e0), 0x0140` | `f1 e0 00 00 40` | immediate silently truncated to one byte. |
| `stib_d8 0x1234, 0x00` | `f0 34 00 00` | address silently truncated to one byte. |

Only `stiw_d8 0x00, 0xf03d` refuses (`invalid operand for instruction`) -- it
insists on the two raw bytes. Everywhere else the backend will happily assemble
a different instruction, which is why the check compares against ROM bytes.

## Backend status

**No backend change was needed.** All eight already had mnemonics; two of them --
`stib_d8` / `stiw_d8`, the F0 (8-bit direct address) pair defined as `STIB_DD8` /
`STIW_DD8` in `TLCS900InstrInfo.td` -- appear in **zero** source files in this
tree, which is presumably why they had not been found.
