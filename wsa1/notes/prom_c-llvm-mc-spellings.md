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
