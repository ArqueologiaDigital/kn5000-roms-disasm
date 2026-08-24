# llvm-mc's TLCS-900 assembler: spellings and gaps found while converting prom_b

Everything here was found by round-tripping real ROM bytes, and every claim is
re-checked on every build by the gate.

## Directives — one real trap

| directive | bytes emitted | note |
|---|---|---|
| `.byte 0x0E` | 1 | |
| `.short 0xABCD` | 2, little-endian | **use this for 16-bit data** |
| `.word 0x1234` | **4**, little-endian | ⚠ `.word` is 32-bit on this target. Writing `.word` where you meant 16 bits silently doubles the size of a table and the gate then fails a long way from the edit. |
| `.long 0x00F82010` | 4, little-endian | |
| `.ascii "A\"B\\C"` | as written | standard escapes work |
| `.fill n, 1, 0x0E` | n | used for the `ret` padding both prom_a and prom_c already use |
| `.incbin "f", skip, count` | count | |

## Instruction spellings

* Absolute jumps and calls take the **target address**:
  `jp 0xF83171` → `1B 71 31 F8`, `call 0xF42A78` → `1D 78 2A F4`.
* PC-relative forms take the **raw displacement**, not a target:
  `1E FA 01` disassembles as `calr 506`, `63 2C` as `jr ule, 44`,
  `68 D0` as `jr -48`. Listings are therefore position-independent, and no label
  needs to be invented for a branch. `scripts/analysis/llvm_roundtrip.py` keeps
  the absolute target in the comment.
* Mnemonics differ from MAME's: MAME `ld A,0x0c` is llvm-mc `ldb a, 12`,
  MAME `cp C,0` is `cps c, 0`, MAME `ex A,C` is `ex8 a, c`, and immediates print
  in decimal.

## Instruction forms this LLVM build cannot ENCODE

These decode fine in MAME's `unidasm` but `llvm-mc -disassemble` rejects them, so
they have to be emitted as `.byte` with the MAME mnemonic in the comment. All
eleven occurrences in the converted prom_b block are of these three shapes:

| bytes | MAME | shape |
|---|---|---|
| `C3 03 F4 EC 27` | `ld L,(XIY+L)` | register-indexed memory operand `(rr+r)` |
| `E3 07 F4 EC 25` | `ld XIY,(XIY+HL)` | same, 32-bit |
| `C3 07 F8 F0 21` | `ld A,(XIZ+IX)` | same |
| `ED FF` / `CB FF` | `srl A,XIY` / `srl A,C` | variable shift by a register |
| `85 3F 07` | `cp (XIY),0x07` | compare memory with an 8-bit immediate |

502 of the 513 instructions in `0xF31800-0xF31D1F` did encode, so the gap is
narrow but real. Anyone extending the TLCS-900 backend upstream has a ready-made
five-case test list here.

## The tool

`scripts/analysis/llvm_roundtrip.py <img> <addr> <len>` does the transcription
mechanically: `unidasm` for instruction boundaries, `llvm-mc -disassemble` for
LLVM's spelling, then it assembles the whole candidate listing and compares it
byte for byte with the input, demoting any instruction that does not reproduce
to `.byte` and repeating until it is exact. **A listing it printed is guaranteed
to rebuild the range it came from** — which is the only reason hand-editing the
result is safe.
