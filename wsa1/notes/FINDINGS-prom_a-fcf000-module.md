# prom_a 0xFCF000-0xFDE70E — the module the frontier ranked first, and the
# 6,385 bytes at its end that were deliberately left alone

Written 2026-08-25, wave 5 round 2. Every number is re-derived from the ROM by
`python3 notes/prom_a_fcf000_checks.py` (add `--tail` for the slow sweep in §4).
The byte gate proves the source rebuilds the ROM and is blind to every sentence
here.

## 1. Why this span

`python3 notes/prom_a_module_frontier.py` ranks it **first** in prom_a: the thunk
run `T_F41F54-T_F421A8` publishes 150 slots, 145 of them unconverted, over 59,752
bytes of contiguous still-`.incbin` target range, and the second-ranked run
`T_F42320-T_F42380` lands in the same `.incbin`.

⚠ **This span answers no entry on the emulation gap list.** It was taken because
it is the largest clean run in the image and because leaving 65 KB inside an
`.incbin` keeps every tool in `notes/` blind to it — the call graph cannot see
its calls, the address census cannot separate its instructions from its data.
Almost every label in it is `sub_XXXXXX`, which is an address and not a claim.

## 2. The module's shape

| part | extent | bytes | what |
|---|---|---:|---|
| `DispatchTable_FCF000` | `0xFCF000-0xFCF043` | 68 | 17 LE32 code addresses |
| `ModuleTables_FCF044` | `0xFCF044-0xFCFDA6` | 3,427 | tables, 232 `.byte`/`.long` lines |
| code | `0xFCFDA7-0xFDE70E` | 59,752 | 23,585 instructions + 24 directive lines (two inline jump tables) |
| **module total** | `0xFCF000-0xFDE70E` | **63,247** | 68 + 3,427 + 59,752 |
| left `.incbin` | `0xFDE70F-0xFDFFFF` | 6,385 | see §4 |

> ⚠ **CORRECTED 2026-08-25, round-2 audit F3.** The code row used to read
> *"60,776 bytes, 23,622 instructions"*. `0xFDE70F − 0xFCFDA7 = 0xE968 = 59,752`,
> and the old rows summed to 64,271 against the module's own stated 63,247 — the
> table contradicted its own extents. The instruction count was wrong too. Both
> figures are now asserted by `prom_a_fcf000_checks.py` (checks S1–S7; the suite
> is 49 checks, 50 with `--tail`), which
> nothing did before.

`notes/prom_a_frontier_delta.py --rev HEAD --vs-worktree` reports **177 distinct
directory targets retired** by this range, not 178: the 178th is `0xFDE70F`
itself, which is the *exclusive* end of the converted span and therefore still
`.incbin`. Predicted and observed agree.

**The data and the code meet at `0xFCFDA6/0xFCFDA7`**, and that boundary is not a
guess: `0xFCFDA7` is the module's **first directory target**, and the byte before
it is the top byte of the last pointer in the table block.

## 3. What is certified, and by a check that can fail

`python3 notes/prom_a_linear_decode_check.py 0xFCFDA7 0xFDE70F --offenders`:

* the module's **179** directory slots name **178 distinct** targets (two slots
  share `0xFDE1DD`). The check tests the **177** inside `[0xFCFDA7, 0xFDE70F)`
  and **all 177** land exactly on an instruction boundary of ONE decode from
  `0xFCFDA7` — 0 off-boundary. The 178th is `0xFDE70F`, the span's end, verified
  separately as a boundary;
* **0** `call`/`calr` from an instruction inside the span to an address that is
  not a boundary;
* the only undecodable byte, `0xFD70E1`, is inside `JumpTable_FD70C5`, declared
  as data.

⚠ None of that establishes the START of a decode — a TLCS-900 decode
resynchronises within a couple of instructions. What pins `0xFCFDA7` is the
directory, not the decode.

## 4. ★★ Why the span stops at 0xFDE70F

`0xFDE70F` is the LAST directory target in the `.incbin`, and past it the decode
cannot be trusted:

* running the same check to `0xFE0000` **fails**: `0xFE0000` — the start of the
  already-converted `0xFE0000` module, so a known boundary — is not a boundary of
  a decode from `0xFCFDA7`, and eight `call` sites in `0xFDFEE9-0xFDFF7A` name
  addresses (`0xFD61E9`, `0xFD6FEE`, `0xFD763E`) that are 1–2 bytes past one;
* **exhaustively**: of the 128 possible decode starts in `0xFDFF80-0xFDFFFF`,
  only `0xFDFFFD` and `0xFDFFFF` produce a decode in which `0xFE0000` is a
  boundary (`notes/prom_a_fcf000_checks.py --tail`).

So the last bytes of that `.incbin` carry something a linear decode cannot frame.
Converting them would have put **invented instructions** in the file — which the
byte gate cannot see, because the bytes would still be the bytes. 6,385 bytes are
left `.incbin` for that reason, and the next round has an exact statement of what
to look for.

## 5. The tables

**`DispatchTable_FCF000`, 17 entries — and the count is NOT bound-derived.** The
only reader, at `0xFCFE1D`, is a computed CALL: `add XBC,0x00FCF000 /
ld XBC,(XBC) / lda XIY,(0xFCFE2D) / push XIY / jp (XBC)` — it pushes the return
address by hand. It computes its index with a multiply and **no compare**, so
unlike every other table in this image the ROM does not state the count. 17 comes
from the data: word 17, at `0xFCF044`, is `0x00000000` — not an address — and the
bytes after it are a monotone ramp, i.e. a different table. Three of the
seventeen entries hold the same address `0x00FD6C93` (the shape of a default arm)
and the other fourteen are distinct. **This is weaker evidence than a bound;
do not quote it as if the ROM checked it.**

**`ModuleTables_FCF044`** is `.byte`, and only these parts are framed:

* `0xFCF044` the ramp `00 00 00 00 00 02 04 06 08 0C 0E 10 12 14 16 18`;
* `0xFCF061` ★ **96 characters — the module's CHARACTER SET**:
  `' '`, `'A'..'Z'`, `'a'..'z'`, `'0'..'9'`, then
  ``!"#$%&'()+-*/=,.@:;?\^_`|~``, `0x7F`, `<>[]{}`. It is **not** in ASCII
  order, so it is an index-to-glyph map: character 0 is a space, 1 is `A`, 27 is
  `a`, 53 is `0`;
* `0xFCF0C1` 34 bytes of `0x00`;
* `0xFCF0E3` a byte table of values in the range of that set — the inverse map;
* `0xFCFD80` a run of 4-byte values whose low three bytes are `0x00FD____`
  addresses. ⚠ Its alignment is **not** established and nothing names its base.

**Two inline jump tables**, `0xFD70C5` and `0xFD710A`, 8 entries each, both bound
by `dec 2,BC / cps bc,0x07 / jr ugt`. Last-entry tests: `0xFD70C5 + 32 =
0xFD70E5`, which is **entry 3 of that same table**; `0xFD710A + 32 = 0xFD712A`,
which is entry 0. They share exactly six of their eight targets; nothing here
says one is a copy of the other.

## 6. What is NOT established

* What the module DOES. The character set says it formats text; the 17-entry
  dispatch table says it has 17 operations; neither is named.
* What reads `ModuleTables_FCF044`. No `add Xrr,imm32` in prom_a or prom_b names
  any address inside it other than the two tables that bracket it.
* The 6,385 bytes of §4.
