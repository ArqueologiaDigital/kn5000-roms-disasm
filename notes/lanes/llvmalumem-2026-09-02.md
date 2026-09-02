# Lane `w15/llvm-alumem` — the decoder could not read what the encoder writes

2026-09-02. Toolchain at close: `tlcs900_backend@7e541b8ddb07`.

## The problem, as handed over

`scripts/analysis/decoder_gap_ranking.py` measured **171 of 655 sampled v10
statements refused or mis-sized by `llvm-objdump`, while `llvm-mc` encoded every
one of them back to the ROM's exact bytes.** So the tree's source was right and
only the *reading* of it was missing — which matters because the conversion
tools gate candidate regions on "does this decode and round-trip", and those
gates were scoring correct source against a decoder that could not read it.

## ⚠ The leading byte is not the unit of the gap

`9f 06 81` was refused while `9f 08 23` read fine. Both start 0x9f. What the
decoder actually dispatches on is the pair

    (which prefix TABLE the leading byte selects, SUB-OPCODE byte)

and there are four register-indirect tables (byte/word/long source, and
destination, each with and without a d8) plus twelve direct-address ones. So the
first thing this lane built was `scripts/analysis/mem_subopcode_gap_census.py`,
which groups every memory-prefix statement in v7/v9/v10 that way. That census is
what the fixes were written from, and re-running it is what shows they landed.

## ⚠ A REFUSAL COUNT CANNOT SEE THE WORST FAILURES

This is the finding worth carrying forward. Three of the bugs fixed here were
not gaps at all — the decoder returned an instruction, confidently, that
**re-assembles to different bytes**:

| bytes | is | decoded as | which re-assembles to |
|---|---|---|---|
| `b3 c8` | `bit 0, (xhl)` | `and (xhl), xwa` | `a3 c8` |
| `f1 13 04 b0` | `res 0, (1043)` | `setda 0, (1043)` | `f1 13 04 b8` |
| `92 04` | `pushm (xde)` | `push xde` | `3a` — three bytes to one |

157 distinct v10 samples were affected by the direct-address one alone. Nothing
in the tree could see it: `llvm-mc` was happy, `llvm-objdump` was happy, the byte
gate never assembles disassembler output, and a census that counts refusals
counts these as successes.

**So the census has a `--roundtrip` mode**: every decode is re-assembled and
required to give the ROM's bytes back. And because a round-trip cannot tell an
ADD called SUB from an ADD, it has an `--oracle` mode as well, comparing against
MAME's independently written `unidasm` on instruction LENGTH and on the
operation, through an explicit naming table.

★ The general shape: **three instruments, because each is blind to what the
others catch.** Refusal count sees missing decodes. Round-trip sees wrong ones.
The oracle sees wrongly-named ones. A lane with only the first would have
reported this work as finished after the first commit.

## What was wrong, by family

Register-indirect prefixes (0x80/0x90/0xA0 source, 0xB0/0xB8 destination):

* the whole ALU family — `add r,(mem)` and `add (mem),r` in all eight
  operations and three widths, `ALU (mem),#imm`, and ADC/SBC in the
  memory-destination direction — had no decode;
* the destination table's bit operations (LDCF/STCF/TSET/RES/SET/CHG/BIT) had
  none, and destination sub-opcodes fell through into the *source* table's ALU
  rows, which is the `b3 c8` bug above;
* `jp cc,(mem)` / `call cc,(mem)` were refused outright after an earlier lane
  found the branch crashing the process;
* EX, MUL/MULS/DIV/DIVS and the shift/rotate group on memory had none;
* PUSH (mem) decoded to the one-byte register push;
* RETcc and the block transfers dropped the prefix's base-register field, which
  those encodings carry even though the hardware ignores it.

Direct-address prefixes (C0-C2/D0-D2/E0-E2/F0-F2):

* the bit table was mapped one whole group out of step (0xA0→BIT, 0xA8→RES,
  0xB0→SET), which is the `f1 13 04 b0` bug above; the real assignment is
  identical to the register-indirect one, 0x98 LDCF, 0xA0 STCF, 0xA8 TSET,
  0xB0 RES, 0xB8 SET, 0xC0 CHG, 0xC8 BIT;
* `ALU (addr),#imm`, the 0x19 memory-to-memory load, `jp/call cc,(addr)`,
  `PUSH (addr)`, 32-bit AND/OR through a 24-bit address, and the 8-bit-direct
  ALU immediates had no decode;
* RETcc after a direct-address prefix decoded to the ordinary two-byte `B0
  F0+cc`, four bytes shorter than what was there.

Register prefix: `link` and `unlk` (sub-opcodes 0x0C and 0x0D) had no decode.

## Results

| measurement | before | after |
|---|---|---|
| `decoder_gap_ranking.py`, v10 statements refused or mis-sized | **171 / 655** (`6f456a19f05b`) | **21 / 655** (`7e541b8ddb07`) |
| distinct v10 memory-prefix samples refused | 2,665 / 20,976 (`1f75e04f774a`) | **294 / 20,976** |
| (table, sub-opcode) shapes with at least one refusal | 88 of 978 (`1f75e04f774a`) | **20 of 978** |
| decoded samples that do NOT re-assemble to the ROM's bytes, v7+v9+v10 | 157 | **0** |
| vs MAME unidasm, v10: LENGTH disagreements | 0 | **0** |
| vs MAME unidasm, v10: operation disagreements outside the naming table | — | **0** |
| our names mapping to more than one unidasm operation | — | **0** |

⚠ Every one of these is a property of the DECODER as much as of the bytes, so
each names its toolchain commit. The `2,665` row is not a pre-lane baseline: the
census only learned to classify direct-address prefixes after the first decoder
commit, and rebuilding the shared toolchain backwards to take one would have
invalidated other lanes' in-flight measurements.

**No encoding was changed.** Every commit is decode-side, or adds a new
definition beside an existing one. `make gate-all` is green: 9/9 KN5000 images
assemble, 13/13 ROMs byte-identical.

## What resisted, and why

**294 samples in 20 shapes still refuse.** They are not scattered; they are
three families, and each needs a NEW INSTRUCTION DEFINITION rather than a
decoder branch. The counts are v10 distinct samples:

1. **`ld (mem),(nn)` and `ld (nn),(mem)`** — 274 of the 294, the whole
   remaining story. Source sub-opcode 0x19 with a register-indirect prefix, destination
   0x14/0x16. The tree spells these as raw-byte escapes (`mrib4 129, 25, 172,
   6`; `ldmi16 (xwa), 36152`). ⚠ `ldmi16` is also semantically WRONG: unidasm
   reads `b0 14 38 8d` as `ld (XWA),(0x8d38)`, a memory-to-memory load, not a
   store-immediate. Decoding to the escape spellings would round-trip and convey
   nothing — it would pass the conversion gate by echoing bytes — so it was
   refused. What is needed is an instruction with one register-indirect and one
   direct-address operand, which is an operand shape the parser has never seen.
2. **POP (addr) and STCF A,(addr) on a direct address** — 15 samples.
   Needs a "destination direct + fixed opcode, no operand" format; the four
   existing direct-address formats all append a register, an immediate or a bit
   number.
3. **EX / MUL / MULS / shift on a direct address** — 5 samples, no
   definitions. (`da16_8` sub-opcodes 0x30, 0x41, 0x43, 0x7c and `da16_16`
   0x48.)

Outside this census, and still open, is the fourth:

4. **SRI register+register ALU** — `e3 07 ec e8 84` is `add xix, (xhl+de)`. The
   R+R decoder handles LD/ST/LDA/JP/CALL but not the ALU sub-opcodes, and the
   only spellings are raw-byte escapes (`add_sril_rm xix, 7, 236, 232`). A whole
   addressing family needs typed definitions.

★ And one finding handed back to whoever owns the `.td`: **`TSET_da16` and
`TSET_da24` are declared with opcode 0xA0, which is STCF.** Their encoding is
deliberately left alone here because committed source spells those bytes
`tsetda`; correctly-named siblings were added beside them and are what the
disassembler prints. The same misnomer should be checked for wherever `tsetda`
appears in source.

## Reproducing

    python3 scripts/analysis/mem_subopcode_gap_census.py --selftest
    python3 scripts/analysis/mem_subopcode_gap_census.py             # by (table, sub-opcode)
    python3 scripts/analysis/mem_subopcode_gap_census.py --roundtrip # decode -> re-assemble
    python3 scripts/analysis/mem_subopcode_gap_census.py --oracle    # vs MAME unidasm
    python3 scripts/analysis/mem_prefix_test_sites.py --check        # the lit test's 125 ROM sites
    python3 scripts/analysis/mem_prefix_test_sites.py --foil         # ...and that --check can fail
    python3 scripts/analysis/decoder_gap_ranking.py

`--foil` exists because a checker that has only ever passed is not evidence: it
flips one bit of one site's expected bytes, requires exactly one failure, then
restores it and requires none.
