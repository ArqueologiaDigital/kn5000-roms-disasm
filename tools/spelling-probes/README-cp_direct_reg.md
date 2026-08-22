# Probe: llvm-mc spelling for the unidasm form `cp (imm),r`

One printed text, `cp (0x0d57),A`, is **nine** different TLCS-900 encodings:
three operand sizes (byte / word / long) times three address widths (8 / 16 /
24 bit) — plus a **tenth** that is not a direct address at all (see below).
A converter turning `.byte` blobs into instructions must choose between them
from the RAW BYTES.

This is the store-direction compare, sub-opcode `0xF8+r`. Its sibling
`cp r,(imm)` is `0xF0+r` and is covered by `README-cp_reg_direct.md`. The two
print in different operand order and are **different instructions**; nothing
else distinguishes them in the text.

| script | question it answers | command |
|---|---|---|
| `verify_cp_direct_reg.py` | Does the proposed spelling rule assemble byte-exactly at **every** `cp (imm),r` site in v7, v9, v10 and the table-data ROM, and does each result print back as the original text? | `python3 tools/spelling-probes/verify_cp_direct_reg.py` |
| `verify_cp_direct_reg.py --negative` | Can this check fail? Runs the plausible-but-wrong rule a reader of the printed text would write (address width from the VALUE). | `python3 tools/spelling-probes/verify_cp_direct_reg.py --negative` |
| `verify_cp_direct_reg.py --dangerous` | Which near-miss spellings assemble and emit the WRONG bytes? Assembles each one live. | `python3 tools/spelling-probes/verify_cp_direct_reg.py --dangerous` |
| `code_or_data_cp_direct_reg.py` | Of the whole-ROM sweep hits, which are real instructions — and does the unspellable 8-bit-direct form occur in real code at all? | `python3 tools/spelling-probes/code_or_data_cp_direct_reg.py` |
| `blocked_cp_direct_reg.py` | Exactly which sites block `convert_reachable_ranges.py`, and does the rule spell each of them? | `python3 tools/spelling-probes/blocked_cp_direct_reg.py` |

Signal read: the raw ROM bytes at each address (`original_ROMs/kn5000_<v>_program.rom`
at load base 0xE00000, `kn5000_table_data.rom` at 0x800000). PASS =
`llvm-mc -triple=tlcs900 --show-encoding` output equals those bytes.
"Assembled without error" is NOT a pass.

## The rule

    c1 al ah    F8+r   (4B)  ->  cpdm8     (0x<ah><al>),     <GR8[r]>
    d1 al ah    F8+r   (4B)  ->  cpdm16    (0x<ah><al>),     <GPR[r]>
    e1 al ah    F8+r   (4B)  ->  cpdm32    (0x<ah><al>),     <GPR[r]>
    c2 a0 a1 a2 F8+r   (5B)  ->  cpdm8_24  (0x<a2><a1><a0>), <GR8[r]>
    d2 a0 a1 a2 F8+r   (5B)  ->  cpdm16_24 (0x<a2><a1><a0>), <GPR[r]>
    e2 a0 a1 a2 F8+r   (5B)  ->  cpdm32_24 (0x<a2><a1><a0>), <GPR[r]>
    c0 aa       F8+r   (3B)  ->  no spelling exists (and no real instance: below)
    d0 aa       F8+r   (3B)  ->  no spelling exists
    e0 aa       F8+r   (3B)  ->  no spelling exists

    r      = last byte & 7
    GR8[r] = w a b c d e h l
    GPR[r] = xwa xbc xde xhl xix xiy xiz xsp

Byte 0's **high** nibble picks the OPERAND SIZE (`c` = byte, `d` = word,
`e` = long) and its **low** nibble picks the ADDRESS WIDTH (`0` = 8-bit direct,
`1` = 16-bit, `2` = 24-bit). The last byte is `0xF8+r`.

Traps in the operand shape:

* `cpdm*` puts the **address first**: `cpdm8 (0x0d57), a`. `cpdm8 a, (0x0d57)`
  is rejected — that operand order belongs to `cpda*`, which is the F0 family.
* `cpdm16`/`cpdm32` want the **X-names even for word operands**:
  `cpdm16 (a), xwa` *is* `cp (a),WA`; `cpdm16 (a), wa` and `cpdm16 (a), sp` are
  both rejected (GR16 has no SP, and this overload is GPR-only). `cpdm16_24`
  accepts **both** `wa` and `xwa` — the 24-bit form has a GR16 overload the
  16-bit form does not.
* `cpdm8`/`cpdm8_24` want the GR8 names. `cpdm8` also **accepts** the X-names
  and then silently means that register's low byte — `cpdm8 (a), xwa` → `f9` =
  A, not `f8` = W; `cpdm8 (a), xbc` → `fb` = C, not `fa` = B — with
  `xde`/`xiy` and `xhl`/`xsp` colliding on the same encoding.
* The address may be written with or without parentheses (`cpdm8 0xd57, a` and
  `cpdm8 (0xd57), a` are the same instruction); this tree's v9 sources use both.

All 48 spellable (prefix, register) combinations were enumerated and assembled:
every sub-opcode `f8`..`ff` is reachable for all six prefixes.

Reading the width back from unidasm TEXT alone also works, because unidasm
zero-pads the address to the encoded width: 2 hex digits ⇔ prefix `?0`, 4 ⇔
`?1`, 6 ⇔ `?2`. Do NOT derive the width from the address VALUE — that is what
`--negative` measures, and it is wrong 77 times.

## Results, 2026-08-22, llvm tlcs900_backend@cb165c5cdc4b

    v7     535 /  535 byte-exact  (317 c1 +  55 d1 + 120 e1 + 13 c2 + 21 d2 +  9 e2)
    v9     537 /  537 byte-exact  (317 c1 +  55 d1 + 122 e1 + 12 c2 + 21 d2 + 10 e2)
    v10    537 /  537 byte-exact  (identical to v9)
    table   89 /   89 byte-exact  ( 14 c1 +  24 d1 +  12 e1 +  8 c2 + 21 d2 + 10 e2)
    GRAND TOTAL 1698 / 1698 spellable sites, 0 failures
    round-trip back through unidasm: 1698 / 1698 print the original listing text

    --negative (address width from the VALUE):  1621 / 1698, 77 failures

    1030 further sweep hits have no spelling: 1029 use c0/d0/e0, and 1 is the
    PC-relative encoding described below.

Real instructions, source-anchored in the byte-exact v9 build (`cmp
rebuilt_ROMs/kn5000_v9_program.llvm.rom original_ROMs/kn5000_v9_program.rom` is
silent), one per encoding class:

| address | ROM bytes | unidasm | v9 source line |
|---|---|---|---|
| 0xEF0F4A | `c1 16 04 f9` | `cp (0x0416),A` | `cpdm8 1046, a` (boot/system_handlers.s:759) |
| 0xEF1ACF | `d1 87 04 f8` | `cp (0x0487),WA` | `cpdm16 1159, xwa` (:2140) |
| 0xE16BAE | `e1 00 00 ff` | `cp (0x0000),XSP` | `cpdm32 0, xsp` (ui_widgets/naka_property_descriptors.s:175) |
| 0xFE9F8A | `c2 e0 ce 00 f9` | `cp (0x00cee0),A` | `cpdm8_24 (0xcee0), a` (audio/note_voice_mapping.s:16412) |
| 0xF7BA61 | `d2 9e e9 03 fa` | `cp (0x03e99e),DE` | `cpdm16_24 (0x3e99e), xde` (ui/drawbar_panel_ui.s:4494) |
| 0xFF0F75 | `e2 28 d5 03 f8` | `cp (0x03d528),XWA` | `cpdm32_24 (0x3d528), xwa` (audio/note_voice_mapping.s:29285) |

End-to-end check that the assembler emits the same bytes through a real object
file, not only in `--show-encoding`:

    printf '\t.text\n\tcpdm8 (0x0416), a\n\tcpdm16 (0x0487), xwa\n\tcpdm32 (0x0000), xsp\n\tcpdm8_24 (0x00cee0), a\n\tcpdm16_24 (0x03e99e), xde\n\tcpdm32_24 (0x03d528), xwa\n' > /tmp/six.s
    llvm-mc -triple=tlcs900 -filetype=obj /tmp/six.s -o /tmp/six.o
    llvm-objcopy -O binary --only-section=.text /tmp/six.o /tmp/six.bin && xxd /tmp/six.bin
    # c116 04f9  d187 04f8  e100 00ff
    # c2e0 ce00 f9  d29e e903 fa  e228 d503 f8

## What this unblocks

`convert_reachable_ranges.py --forms` lists `cp (imm),r` (example
`cp (0x0d57),A`) among the forms its spelling layer cannot reproduce: **8** on
2026-08-22, **9** before commit `ca61032` taught it the F0 sibling. That census
counts blocked *ranges*, because it breaks at the first unspellable
instruction. `blocked_cp_direct_reg.py` names the *sites*:

    18 `cp (imm),r` sites inside the converter's reachable v7 ranges
       (16 distinct addresses; 0xF44C79 and 0xF44D9F each fall in two ranges)
    converter spells   0 / 18
    cpdm rule spells  18 / 18 byte-exactly
    prefixes: c1 x13, d1 x4, d2 x1 -- none is c0/d0/e0

## Negative result: the 8-bit-direct form is not a gap worth filling

`TLCS900InstrFormats.td` gives `AddrWidth` a single bit — 16- or 24-bit direct
addressing only — and `emitDirectAddrPrefix()` in `TLCS900MCCodeEmitter.cpp`
computes the prefix as `0xC1 + OpSize*0x10` or `0xC2 + OpSize*0x10`, so
`c0`/`d0`/`e0` is not reachable by any spelling. That is a real hole in the
backend, and it does not matter:

`code_or_data_cp_direct_reg.py` re-assembles the v9 sources with `llvm-mc -g`,
proves the result is still byte-identical to the original ROM, and reads the
DWARF line table, which carries one row per emitting source statement. An
instruction the sources really contain must start a row.

    c0/d0/e0   8-bit direct     0 / 275 sweep hits are real code
    c1/d1/e1  16-bit direct   120 / 494
    c2/d2/e2  24-bit direct    16 /  43

The check can come out positive — it does, 136 times. It comes out zero for the
8-bit-direct class. `blob_cp_direct_reg`-style scans of the remaining `.byte`
blobs agree from the other side: v7 holds 49 such sites, of which exactly one
`c0` and one `d0`, both inside `factory_test/test_data.s`; v9 and v10 hold five
each, of which two `c0`, in `extensions/extension_data.s` and
`ui_widgets/widget_dispatch.s`. Leave `c0`/`d0`/`e0` runs as `.byte`.

## The TENTH encoding: the printed address is not always in the instruction

`table_data` 0x9D4D29 is `d3 13 14 b0 ff` and unidasm prints
`cp (0x9cfd41),SP`. Prefix `d3` is the *extended* addressing prefix and mode
byte `0x13` is **(PC + d16)**: 0x9D4D29 + 4 − 0x4FEC = 0x9CFD41. The absolute
address never appears in the bytes. Spelling it as a direct address assembles
cleanly and is completely wrong — `cpdm16_24 (0x9cfd41), xsp` → `d2 41 fd 9c ff`.
The rule above refuses it because it keys on the prefix byte rather than on the
printed text.

That site is data: it lies in a `d3`-led table with a descending index column
(`… d3 5d 21, d3 5f 20, … d3 06 1d, d3 08 1c, d3 0a 1b …`) and unidasm emits
eight undecodable `db` lines within the 0x40 bytes around it.

## Spellings that ASSEMBLE and emit the WRONG bytes

Run `--dangerous` to reproduce this table live.

    cp (0x1234), a            rejected: no plain `cp (mem),reg` mnemonic -- and
                              llvm-mc STILL prints `encoding: [0xf9]` after the
                              error, so trust the exit status, not the listing
    cpdm8 a, (0x0d57)         rejected: cpdm* take (addr), reg
    cpda8 a, (0x0d57)         c1 57 0d f1 -- the F0 LOAD-direction compare
                              `cp A,(0x0d57)`. Same prefix, same length,
                              DIFFERENT INSTRUCTION
    cpdm16 (0x1234), wa       rejected: cpdm16/cpdm32 want the X-names
    cpdm16 (0x1234), sp       rejected: GR16 excludes SP; only `xsp` reaches ff
    cpdm8 (0x1234), xwa       c1 34 12 f9 -- low byte of XWA is A(1), not W(0)
    cpdm8 (0x1234), xbc       c1 34 12 fb -- low byte of XBC is C(3), not B(2)
    cpdm8 (0x1234), xde       c1 34 12 fd -- collides with `cpdm8 xiy` and `e`
    cpdm8 (0x1234), xhl       c1 34 12 ff -- collides with `cpdm8 xsp` and `l`
    cpdm8 (0x00ce44), a       c1 44 ce f9 -- 24-bit address SILENTLY TRUNCATED,
                              4 bytes where the ROM has 5
    cpdm16 (0x0274e0), xde    d1 e0 74 fa -- ditto
    cpdm32 (0xffff00), xsp    e1 00 ff ff -- ditto
    cpdm8_24 (0x0d57), a      c2 57 0d 00 f9 -- 5 bytes where the 16-bit form is 4
    cpdm16_24 (0xe2c6), xwa   d2 c6 e2 00 f8 -- ditto
    cpdm32_24 (0xe921), xiz   e2 21 e9 00 fe -- ditto
    cpdm8 (0xac), e           c1 ac 00 fd -- the 8-bit-direct c0 form is
                              unreachable; this silently WIDENS the address,
                              4 bytes where the ROM has 3
    cpdm16_24 (0x9cfd41), xsp d2 41 fd 9c ff -- the PC-relative site above.
                              Worst trap of the set: the printed address is a
                              resolved target, not an operand
