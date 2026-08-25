# Getting llvm-mc to emit the bytes: TLCS-900 spellings discovered in this pass

Converting prom_c code needs the exact spelling llvm-mc's TLCS-900 assembler wants, and that
spelling is **not guessable**. This note records what was learned so the next pass does not
rediscover it.

> **Companion note.** `notes/llvm-mc-tlcs900-spellings.md`, written from the prom_b conversion,
> covers the *directives* (in particular that `.word` is **32 bits** on this target) and the
> general absolute-vs-relative branch rule. The two agree where they overlap — both found that
> PC-relative forms take a raw displacement. Read that one first; this one adds the prom_c
> instruction table, the oracle, and the two traps below.

## The two traps

**1. The llvm-mc DISASSEMBLER is not a usable inverse of its assembler.** Round-tripping ROM
bytes through `llvm-mc -disassemble` looks like it should work and does not. On the routine at
`0xF99125` it renders `link XIZ,0xffff` (`EE 0C FF FF`) as `incf` + `swi 7` + `swi 7`, and
emits "invalid instruction encoding" warnings mid-stream while still printing plausible-looking
output. **Use `unidasm` for the semantics** (`scripts/analysis/dis.sh`), never the llvm
disassembler.

**2. The backend spells complex addressing modes as raw operand bytes.** `link32 238, 12, 254,
255` *is* the encoding, written out. So is `pushw_erp 0xE2` and `extpfx3 0x8E, 0xFF, 0x04`.
Anything the instruction tables do not model gets expressed this way, and there is no way to
guess which.

## The oracle

`notes/prom_c_enc_oracle.py` inverts the problem. The sibling project's
`kn5000_subprogram_v142.s` is **40,101 instructions of already-byte-verified assembly for the
same CPU emitted by the same compiler**; assembling it with `--show-encoding` gives
(source line → bytes) for every one, and the script indexes that map backwards.

```
python3 notes/prom_c_enc_oracle.py --build
python3 notes/prom_c_enc_oracle.py --exact "be fe 14"     # lines starting with these bytes
python3 notes/prom_c_enc_oracle.py --first 0xBE           # mnemonics using this prefix
python3 notes/prom_c_enc_oracle.py --like  st_dd8w        # shapes of one mnemonic
```

For anything the oracle does not cover, `llvm-mc --show-encoding` on a candidate line is a
one-shot check.

## Spellings confirmed by round-trip against real prom_c bytes

| bytes | unidasm says | llvm-mc spelling |
|---|---|---|
| `39` / `59` | push/pop XBC | `push xbc` / `pop xbc` |
| `28` / `48` | push/pop WA | `pushw wa` / `popw wa` — **not** `push wa`, which is `D8 04` |
| `2b` / `4b` | push/pop HL | `pushw hl` / `popw hl` |
| `38` / `58` | push/pop XWA | `push xwa` / `pop xwa` |
| `09 00` | push 0x00 | `push 0x00` |
| `ee 0c fe ff` | link XIZ,0xfffe | `link32 0xEE, 0x0C, 0xFE, 0xFF` |
| `ee 0d` | unlk XIZ | `unlk32 xiz` |
| `07` | reti | `reti` |
| `be fe 50` | ld (XIZ+0xfe),WA | `ld (xiz-2), wa` — signed decimal displacement |
| `8e fe 23` | ld C,(XIZ+0xfe) | `ld c, (xiz-2)` |
| `8e ff 3f fe` | cp (XIZ+0xff),0xfe | `cp (xiz-1), 0xfe` |
| `b1 41` | ld (XBC),A | `ld (xbc), a` |
| `81 21` | ld A,(XBC) | `ld a, (xbc)` |
| `a1 21` | ld XBC,(XBC) | `ld xbc, (xbc)` |
| `b1 d8` | jp T,XBC | `jp (xbc)` |
| `e2 f3 f2 00 21` | ld XBC,(0x00f2f3) | `ldl_da xbc, 0x00F2F3` |
| `f2 d2 7e 00 61` | ld (0x007ed2),XBC | `stl_da 0x007ED2, xbc` |
| `f2 27 f3 00 43` | ld (0x00f327),C | `stb_da 0x00F327, c` |
| `f2 f8 f2 00 00 01` | ld (0x00f2f8),0x01 | `stib_da 0x00F2F8, 0x01` |
| `f2 f9 f2 00 02 02 00` | ld (0x00f2f9),0x0002 | `stiw_da 0x00F2F9, 0x0002` |
| `c2 2c f3 00 3f 01` | cp (0x00f32c),0x01 | `cpib_da 0x00F32C, 0x01` |
| `d2 2d f3 00 21` | ld BC,(0x00f32d) | `ldw_da bc, 0x00F32D` |
| `f2 11 f3 00 31` | lda XBC,0x00f311 | `lda_24 xbc, 0x00F311` |
| `f0 20 b2` | res 2,(0x20) | `res_dd8 2, TRUN` |
| `f0 1e ca` | bit 2,(0x1e) | `bit_dd8 2, PA` |
| `31 50 00` | ld BC,0x0050 | `ldw bc, SC0BUF` |
| `d9 12` / `e9 12` | extz BC / XBC | `extz bc` / `extz xbc` |
| `d9 69` | dec 1,BC | `dec 1, bc` — count first |
| `d9 ee 02` | sll 0x02,BC | `sll bc, 2` — **register first**, the opposite order from `dec` |
| `ef 66` | inc 6,XSP | `inc 6, xsp` |
| `d9 de` | cp BC,6 | `cps bc, 6` — the 3-bit immediate form is `cps`, not `cp` |
| `d7 e2 04` | push QWA | `pushw_erp 0xE2` |
| `be fe 14 51 00` | ld (XIZ+0xfe),(0x0051) | `ldmi16 (xiz-2), SC0CR` — see below |
| `8e ff 04` | push (XIZ+0xff) | `extpfx3 0x8E, 0xFF, 0x04` — no byte-sized `pushm` exists |

## Spellings added 2026-08-24 (the interrupt-handler / main-loop pass)

| bytes | unidasm says | llvm-mc spelling |
|---|---|---|
| `f2 d1 7e 00 bf` | set 7,(0x007ed1) | `setda_24 7, 0x007ED1` |
| `f2 d1 7e 00 b4` | res 4,(0x007ed1) | `resda_24 4, 0x007ED1` |
| `e2 f3 f2 00 89` | add (0x00f2f3),XBC | `addl_da 0x00F2F3, xbc` |
| `d2 e3 e2 00 20` | ld WA,(0x00e2e3) | `ldw_da wa, 0x00E2E3` |
| `f2 df e2 00 51` | ld (0x00e2df),BC | `stw_da 0x00E2DF, bc` |
| `d2 f1 f2 00 3f 00 00` | cp (0x00f2f1),0x0000 | `cpw_da 0x00F2F1, 0x0000` |
| `d2 f1 f2 00 69` | decw 1,(0x00f2f1) | `decdi16_24 1, 0x00F2F1` |
| `c2 e4 e2 00 69` | dec 1,(0x00e2e4) | `decdi8_24 1, 0x00E2E4` |
| `c2 e3 e2 00 61` | inc 1,(0x00e2e3) | `incdi8_24 1, 0x00E2E3` |
| `d2 c5 c5 fc a2` | sub DE,(0xfcc5c5) | `subda16_24 de, 0x00FCC5C5` |
| `8e 08 3f 09` | cp (XIZ+0x08),0x09 | `cp (xiz+8), 0x09` |
| `9e fe 3f 20 00` | cp (XIZ+0xfe),0x0020 | `cpw (xiz-2), 0x0020` |
| `be fe 02 00 00` | ld (XIZ+0xfe),0x0000 | `ldw (xiz-2), 0x0000` |
| `9e fe 61` | incw 1,(XIZ+0xfe) | `incm 1, (xiz-2)` — **not** `incm16` |
| `b9 d6 41` | ld (XBC+0xd6),A | `ld (xbc-42), a` |
| `f0 20 bb` / `f0 20 b3` | set/res 3,(0x20) | `set_dd8 3, TRUN` / `res_dd8 3, TRUN` |
| `08 28 0e` | ld (0x28),0x0e | `ldio T23MOD, 0x0E` |
| `f0 53 43` | ld (0x53),C | `st_dd8b c, BR0CR` |
| `c7 f4 98` | ld IYL,W | `ldb_erp w, 0xF4` |
| `06 00` | ei 0x00 | `di` |
| `ef 60` | inc 0,XSP | `inc 8, xsp` — 8 encodes as 0 |
| `85 11` | ldir | `extpfx2 0x85, 0x11` — see below |

### ⚠ `ldir` assembles to the WRONG PREFIX

`ldir` on its own emits `80 11`, not `85 11`. The prefix byte selects the pointer pair, and
MAME decodes `0x85` as destination `XIX`, source `XIY`
(`mame/src/devices/cpu/tlcs900/900tbl.hxx:5435-5437`), which is the pair the WSA1's boot copy
uses. `80` would be a different pair entirely. The byte gate catches it, but only if you look
at *which* byte differs — the listing still says `ldir` either way.

### `extpfxN` is the general escape hatch, and it beats `.byte`

`llvm/lib/Target/TLCS900/TLCS900InstrInfo.td:5255-5305` defines `extpfx2` … `extpfx10`, which
emit their operands as raw bytes. Anything the backend cannot model should use these rather
than `.byte`, because they keep ONE source line per ONE instruction — a `.byte` run silently
loses the instruction boundary, and boundaries are what make a listing checkable. Used in this
pass for:

| bytes | unidasm says | spelling |
|---|---|---|
| `c2 2a f3 00 41` | mul WA,(0x00f32a) | `extpfx5 0xC2, 0x2A, 0xF3, 0x00, 0x41` |
| `d2 c7 c5 fc 59` | divs XBC,(0xfcc5c7) | `extpfx5 0xD2, 0xC7, 0xC5, 0xFC, 0x59` |
| `ae fa 81` | add XBC,(XIZ+0xfa) | `extpfx3 0xAE, 0xFA, 0x81` |
| `9e fe 04` | push (XIZ+0xfe) | `extpfx3 0x9E, 0xFE, 0x04` |
| `81 3c fd` / `81 3e 02` | and/or (XBC),imm | `extpfx3 0x81, 0x3C, 0xFD` / `0x81, 0x3E, 0x02` |
| `b1 02 00 80` | ld (XBC),0x8000 | `extpfx4 0xB1, 0x02, 0x00, 0x80` |
| `c0 90 61` | inc 1,(0x90) | `extpfx3 0xC0, 0x90, 0x61` |

### ⚠ `scripts/analysis/llvm_roundtrip.py` cannot converge on some ranges

It prints `cannot converge at byte 0` and exits 4 for `0xF98B20+0x199` and
`0xF98BED+0x40`. The cause is an instruction whose LLVM spelling assembles to a **different
length**: the script's demote-and-retry picks the victim by cumulative byte offset, which
only works when the lengths agree, so on a length change it blames instruction 0 for ever.
`9e fe 04` (`push (XIZ+0xfe)`) is one such.

**Another lane hit the same defect and fixed it**: `notes/llvm_roundtrip_force.py` reuses the
committed script's own functions and adds a fallback that demotes every instruction whose own
bytes do not round-trip individually, so it converges where the original gives up. Use that
first. (The 0xF98B20 range in this pass was transcribed by hand against
`scripts/analysis/dis.sh` before that wrapper existed; the byte gate certifies it either
way.)

### ⚠⚠ `di` is misnamed in the backend, and it inverts the meaning of a listing

`di` assembles to the byte pair `06 00`, which the TLCS-900 decodes as **`EI 0`**, and `EI 0`
**enables** every maskable interrupt.

* `op_EI` writes the immediate into SR bits 6..4 —
  `m_sr.b.h = (m_sr.b.h & 0x8f) | ((imm & 0x07) << 4)`
  (`mame/src/devices/cpu/tlcs900/900tbl.hxx:2073-2078`).
* `tlcs900_check_irqs` then scans interrupt priorities from
  `std::max(1, (m_sr.b.h & 0x70) >> 4)` up to 6
  (`mame/src/devices/cpu/tlcs900/tmp95c061.cpp:536-545`). A level of **0** therefore accepts
  every maskable interrupt; a level of **7** accepts none, because the loop body never runs.
* Reset leaves the field at 7 — `m_sr.d = 0xf800`, commented "iff set to 111"
  (`tlcs900.cpp:213-220`) — so the CPU boots with interrupts off and the firmware's first
  `di` is what turns them **on**.

The real disable is `ei 0x07`, which is what `IRQ_NMI` executes immediately before its
infinite spin.

⚠ **Two headers in `prom_c/wsa1_prom_c.s` had this backwards** (`DSP_ChannelRefresh_Loop`
"starts by disabling interrupts (`di`, MAME's `ei 0x00`) and never re-enables them", and
`Serial0_Init` "runs with interrupts off around the register writes: `ei 6` before and `di`
… at the end"). Both were corrected on 2026-08-25 and now carry the citations. The bytes were
never wrong; only the reading — the byte gate cannot see a mistake of this kind. The pattern
`ei 6` … `di` that appears throughout the link code is a GUARD, not a release: `ei 6` blocks
almost everything and `di` (= `EI 0`) lets it back in.

### ⚠ `ldmi16` is misnamed in the backend

`TLCS900InstrInfo.td:192` defines sub-opcode `0x14` as `MemStoreImmInst … i16imm:$val` and
names it `ldmi16`, and the comment at line 185 calls it `LD (mem), #imm8`. The comment at line
4786 in the same file says `0x14: LD (dst), (src)` — memory to memory — and **that one is
right**. In `INTRX0_HANDLER` the instruction is `be fe 14 51 00`; if `0x0051` were an immediate
the frame slot would hold the constant 81 and the very next thing the handler does — masking it
with `0x1C` and branching — would test a constant. Read as a memory load of `SC0CR` (0x51) it
tests the three serial receive-error flags, and the instruction two later reads `SC0BUF` (0x50),
the adjacent register. The mnemonic assembles to the right bytes either way; only the reading
is affected.

## PC-relative branches

`jr` and `jrl` take **labels** and relocate correctly, so local labels are the right way to
write intra-routine branches. (A bare *integer* operand is taken as the raw displacement
instead — which is what `notes/llvm-mc-tlcs900-spellings.md` observed from the disassembly
side. Both behaviours are real; prefer labels, they cannot drift.)

`calr` does **not** relocate. Given a plain integer it emits that integer as the raw 16-bit
displacement; given a relocatable expression it treats the value as an absolute target and then
subtracts PC again, producing "fixup value out of range". The working idiom — used throughout
`prom_c/wsa1_prom_c.s` — is a **constant-folded difference**, which is byte-exact and documents
both ends:

```
	calr (0xF9942F - 0xF99277)      ; target - address of the next instruction
```

## Harness

Assembling a fragment at its real address needs `SUBALIGN(1)` in the linker script; without it
lld pads `.text` up to 4-byte alignment and every byte shifts. The throwaway harness used here
lived in the session scratchpad and is **disposable** — everything it established is either in
this table or in the committed source, and the byte gate re-proves all of it on every build.
