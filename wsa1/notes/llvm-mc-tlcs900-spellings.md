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

## ⚠⚠ `di` IS A LIE ON THIS TARGET — it assembles to `EI 0`, which ENABLES everything

Found 2026-08-25 while converting prom_a `0xF85EC8`.

```
$ printf '.text\ndi\nei 0x00\nei 0x06\nei 0x07\n' > /tmp/ei.s
$ llvm-mc -triple=tlcs900 -filetype=obj -o /tmp/ei.o /tmp/ei.s
$ llvm-objcopy -O binary /tmp/ei.o /tmp/ei.bin && xxd /tmp/ei.bin
00000000: 0600 0600 0606 0607
           di  ei 0 ei 6 ei 7
```

`di` and `ei 0x00` are the **same two bytes**. On the TMP95C061 the `EI` operand
is the interrupt **mask level** written into SR bits 6-4 (MAME `op_EI`,
`../mame/src/devices/cpu/tlcs900/900tbl.hxx:2073-2078`), and dispatch is blocked
only while that field is 7 (`tmp95c061.cpp:481`), with `:538` scanning priority
levels upward from it. So:

* `EI 0` = accept **every** interrupt — this is EI;
* `EI 7` = accept none — **this** is DI, and it is what the part resets to
  ("iff set to 111", `tlcs900.cpp:218-219`).

llvm-mc's `di` therefore emits the *opposite* of what it says. It round-trips and
the byte gate is perfectly happy, which is what makes it dangerous: the bytes are
right and only the reader is wrong.

**The firmware itself is the independent check.** prom_a `Kernel_Idle`
(`0xF85711`) executes `06 00` and then spins for ever — an idle loop cannot run
with interrupts off — and `Kernel_ServiceSoftTimers` brackets its list walk with
`06 00` … `06 06`, i.e. the critical section is the one that *raises* the number.

Write `ei 0x00` and never `di`. One header in the tree
(`prom_c/wsa1_prom_c.s`, `DSP_ChannelRefresh_Loop`) reads `06 00` as "starts by
disabling interrupts … and never re-enables them"; that reading is backwards, and
it is flagged rather than edited only because prom_c is another lane's file.

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
