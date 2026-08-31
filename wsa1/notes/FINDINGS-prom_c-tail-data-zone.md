# prom_c's tail data zone: a Q11 math library, the four flash banks by name, and 44,100 Hz

**Image:** `prom_c` (IC28, CPU 2, base `0xF80000`).
**Region:** `0xFDF7E0-0xFE21E5` (the tail data zone) and `0xFCC81A-0xFCCA81` (the floating-point
constant pool).
**Round 3 of the conversion, 2026-08-25.** After it, `prom_c` contains **no `.incbin` at all**:
395,072 bytes of substantive source and 129,216 bytes of filler emitted as `.fill` (four runs
of `0x0E`, the one-byte `ret`, and one 480-byte run of `0x00`), 524,288 in total, and `scripts/analysis/assert_byte_identical.py` prints PASS.

Everything below is reproduced by three committed scripts:

```
python3 notes/prom_c_tail_census.py --selftest        # the citations, and the correction
python3 notes/gen_prom_c_tail_tables.py --verify      # 10,389 bytes: tiling, laws, copy B
python3 notes/gen_prom_c_fp_pool.py --verify          # 616 bytes: 76 doubles + 2 longs
```

---

## 0. The correction that made the round possible

Round 2 left 10,389 bytes as `.incbin` and said why, in the source:

> *"0xFDF7E0-0xFE11EF and 0xFE1280-0xFE12B4 and 0xFE1361-0xFE1697 have no established object
> boundaries: the reference census finds no address-operand citation into the first 1,787 bytes
> of copy A (0xFE0A6D-0xFE1167; the earliest is 0xFE1168)"*

The census was `notes/prom_c_dup_image.py --refs`, and its classifier knew three instruction
shapes: `ld <X..>,#imm32`, the four direct-address prefixes, and `call`/`jp`. It did **not** know

```
    e9 c8 c9 06 fe 00      add XBC,0x00FE06C9
```

which is the shape the compiler emits for *every* indexed table read in this image
(`ld BC,2 / muls XBC,HL / add XBC,<table> / ld HL,(XBC)`), nor `lda <X..>,addr24`. With those two
added there are **70 cited targets in the tail zone, from 133 sites** — eight of them inside the
1,787 bytes that were said to hold none:

```
0xFE0AC9  0xFE0CC9  0xFE0EC9  0xFE10C9  0xFE10E9  0xFE1129  0xFE1144  0xFE1156
```

`notes/prom_c_dup_image.py`'s classifier is now fixed (its `--refs` copy-A row moves from
`98 coincidences, 54 hits` to `55 coincidences, 97 hits`; **copy B's row does not move**, so
"nothing reaches copy B" survives the correction). `notes/prom_c_tail_census.py --corrections`
prints the difference between the two classifiers.

**And the first of the eight changes a boundary.** `0xFE0AC9` is cited by `add XIY,0x00FE0AC9`
at `0xFC4239`; it is also the exclusive end of a 256-entry cosine table that begins at
`0xFE08C9`. That table therefore runs *through* `0xFE0A6D` — the address round 2 called the
start of "copy A". `0xFE0A6D` is where the duplication begins, not where an object begins, and
copy B opens with 92 bytes of that cosine table's tail.

---

## 1. ★ Five 256-entry math tables, and the Q11 library that reads them

Five tables sit end to end, each `0x200` bytes after the last, each cited by its own
`add <X..>,#imm32`, and each matching a closed form over **all 256 entries** (the error column
is the maximum over the whole table, not a sample):

| address | table | closed form | error |
|---|---|---|---:|
| `0xFE06C9` | `MathTable_Sin_S16_256` | `round(32767·sin(2πk/256))` | −4 … +8 |
| `0xFE08C9` | `MathTable_Cos_S16_256` | `round(32768·cos(2πk/256)) mod 2¹⁶` | −3 … +6 |
| `0xFE0AC9` | `MathTable_Atan_256` | `round(16384·atan(k/16))` | −1 … 0 |
| `0xFE0CC9` | `MathTable_Log2_256` | `round(3072·(7−log₂k))`, `T[0] = 0xFFFF` | −1 … +1 |
| `0xFE0EC9` | `MathTable_Exp2_256` | `round(12868·2^(k/256))`, `12868 = round(2048·2π)` | −1 … 0 |

Their readers are four small routines, now named:

| routine | was | what it computes |
|---|---|---|
| `Math_Sin_Q11` | `sub_FC419D` (38 B) | `sin θ`, θ and result in **Q11** (2048 = 1.0; θ in 1/2048 rad) |
| `Math_Cos_Q11` | `sub_FC41C3` (38 B) | the same 38 bytes with the cosine table's address |
| `Math_Atan_Q11` | `sub_FC41E9` (62 B) | `atan x`, Q11 in and out, odd function |
| `Math_Exp2_Q11` | `sub_FC4227` (66 B) | `2π·1024·2^x`, x in Q11 |

**The Q11 scale is not an assumption.** `Math_Sin_Q11` forms
`index = (arg × 0x28BE) >> 19`, and `0x28BE / 2¹⁹ = 256 / (2π·2048)` to five digits; its caller
independently forms `0x1922 − 2·arg` at `0xFC445B`, and `0x1922 = 6434` is exactly the argument
that maps to index 128 — half the table, i.e. π radians. `Math_Atan_Q11` divides the index by
16 against a table of `16384·atan(k/16)`, which is the same 2048 = 1.0.

### ⚠ A defect in the ROM's own cosine table

`MathTable_Cos_S16_256[0]` is `0x8000`. `Math_Cos_Q11` reads entries with
`ld BC,(XIY) / sra 4,BC` — a **signed** shift — so `cos(0)` comes back as **−2048**, not +2048:
`+1.0` does not fit the s16 the reader assumes. That is what the ROM contains. Whether any
caller passes 0 is not established, and an emulator or a re-implementation that "fixes" it
would not be reproducing this firmware.

---

## 2. ★ The four flash banks are named in the ROM: "WSA SOUND RAM S0".."S3"

At `0xFE14CB` there are four 16-character NUL-terminated strings, `WSA SOUND RAM S0` …
`WSA SOUND RAM S3`. They are not reached by name: a pointer table at `0xFE150F` holds exactly
their four addresses, and beside it, at `0xFE151F`, is a table of four base addresses:

```
0x00E80000   0x00E90000   0x00EA0000   0x00EB0000
```

`SoundRam_ClearFourBanks` (was `sub_FC386C`, `0xFC386C-0xFC39F9`) walks the two tables together
**four times** (`ld D,0x04` at `0xFC3899`, `dec 1,D / jrl NZ` at `0xFC39EC`). Per pass it

* calls `Flash_ReadSectorToBuffer` (`0xFC89AF`) on the bank base,
* copies sixteen characters of that bank's name, and sixteen of `Str_ClearBanner`
  (`"  --(Clear)--   "`, `0xFE152F`), into the 64 KiB staging buffer at RAM `0x00010000`,
* block-copies `0x21D` bytes to buffer+`0x90` and three `0x51`-byte records from buffer+`0x169`,
* and calls `Flash_ReprogramSector` (`0xFC876C`) on the same base.

**What this is worth to the emulator.** `0xE80000-0xEBFFFF` on CPU 2 is 256 KiB of FLASH that
the firmware itself calls SOUND RAM, in four 64 KiB banks with names — and 256 KiB is exactly
the span prom_a's `Remote_E80000_Read32Blocks` fetches over the inter-processor link (32 blocks
of `0x2000`). That is a memory-map fact with ASCII behind it, and it bears on gap D
(`kn7000_mame/notes/WSA1-EMULATION-DISASM-GAPS.md`), which asks what `0xE80000` holds.

⚠ It does **not** say what the banks contain, nor tie `prom_d` to them. "SOUND RAM" for a flash
bank is the firmware's word, not a claim about the part.

---

## 3. ★ The floating-point constant pool decodes, and it contains 44,100

`fp_constant_pool_FCC81A` (616 bytes) was a deliberate `.incbin`: decoding it on a fixed 8-byte
grid produced denormals, and the source said so rather than guessing a stride. It is not on a
fixed grid — and it did not need a guess:

* all **154** four-byte slots in it are cited by literal-addressed loads, 4-byte aligned and
  consecutive, covering the 616 bytes exactly;
* a **double** is pushed high half first by two `ld XBC,(nnn) / push XBC` pairs six bytes apart,
  so "these eight bytes are one f64" is an instruction pair at a known address, not a stride:
  ```
  F9C2DE  ld XBC,(0xFCC9EE) / push XBC      <- high half
  F9C2E4  ld XBC,(0xFCC9EA) / push XBC      <- low half = the double's address
  ```
* 76 doubles pair that way and **two** elements do not, which is exactly what broke the grid:
  `0xFCC81A` is used as `add XBC,(0xFCC81A)` — an address, `0x0000FFF0` — and `0xFCC8FE` is
  pushed alone to a routine taking a float32 (`0.98039216` = 50/51).
* 76 × 8 + 2 × 4 = **616**, and **48 of the 76 doubles are exact integers**, which no wrong
  alignment produces.

**`44100` is in the pool, cited from eighteen sites, together with `1/44100`, `1/220500` and
`1/441000`.** Its heaviest user is `sub_F9BE3A` — 8,573 bytes, whose header lists **64 of the pool's 154
four-byte slots** among its absolute reads.

⚠ **And that routine has no located caller.** Its header said *"Called from: 1 site outside
this module: 0xF95B01"*; `0xF95B01` is inside the PRESET BANK, at offset `0x041` of 704-byte
record 125. Ten header citations in prom_c land inside the preset bank, at four repeating
in-record offsets, five of them at `0x041` in consecutive records — a data field, not a call.
All ten headers now say so. `notes/prom_c_phantom_callsites.py --selftest`. Other values in it:
`441`, `1100`, `2376`, `10800`, `0.0101010101` (= 1/99), `0.9999`, `2147483648`.

⚠ What any constant is FOR is not established. That the machine's sample rate is 44,100 Hz is a
reading of the constant plus its reciprocals, not a statement any instruction makes.

---

## 4. Two `0x00104000` registers, from the tables that feed them

`sub_FC49AD`, a helper of the `0x00104000` packer `sub_FC4DBD`
(`notes/FINDINGS-prom_c-dev10c-producers.md` §3), reads two parallel 251-entry tables with one
clamped index and stores both results into the staging struct:

```
HL = P[+0x21] + P[+0x16] + P[+0x12]
cp HL,0x00FA / else HL = 0xFA        ; 0xFC49CC -- upper clamp, 250
cp HL,0      / else HL = 0           ; 0xFC49D7 -- lower clamp
index = HL                            ; 0..250, and BOTH tables are 251 entries
```

| table | contents | goes to |
|---|---|---|
| `Curve_Log2_251` (`0xFDFAE0`) | `round(27543 − 3072·log₂k)`, `T[0] = 0x6C00` | struct +0x06 → register **`0x00C0 + chan`** |
| `Const_0100_251` (`0xFDFCD6`) | `0x0100` in **all 251 entries** | struct +0x08 → register **`0x0100 + chan`** |

So on this firmware, `0x00104000` register `0x0100 + chan` is fed a **constant** `0x0100` from
this path, and register `0x00C0 + chan` is fed a **logarithmic** quantity — 3072 counts per
halving of the index — offset by two per-part fields and then clamped to `0x0000` or `0x7F00`
(`0xFC4A2B`). `MathTable_Log2_256` uses the same 3072 slope, and entry for entry
`Curve_Log2_251[k] = MathTable_Log2_256[k] + 6039 ± 1`.

⚠ **These are `0x00104000` registers, not `0x0010C000` ones.** Both devices have a register
`0x0040 + chan`; the peripheral base is the only thing that tells them apart, and this tree has
already had to retract once over exactly that.

---

## 5. Four linear coefficient tables, and the idiom that reads them

`LinCoef_FE0096`, `LinCoef_FE0116`, `LinCoef_FE0196` and `LinCoef_FE0216` are 128 signed bytes
each, read by one idiom that appears four times in `sub_FC4DBD`:

```
lda XIX,<table> ; A = record[+0x10] (signed) ; if A == 0 -> result 0
D = (0x00E088)                      ; a 0..127 key
if A < 0:  D = 0x7F - D ; A = -A    ; the curve is MIRRORED for a negative depth
result = (T[D] * A) >> 5
```

`>> 5` makes the table a **Q5 coefficient** (32 = 1.0), and the four spans are
`−4.0 … +3.94`, `−1.0 … +1.0`, and `−2.0 … 0.0` twice — `LinCoef_FE0216` is byte-identical to
`LinCoef_FE0196`, all 128 entries. The count 128 is fixed by the index: `0x00E088` is
`voice_record[+0x0C]` **with bit 7 cleared** (`sub_FC4D63`), so `0..127`, and `0x7F − D` stays in
range.

★ **The last entry is what picks the law**, in two of the four. `LinCoef_FE0116` is
`(k·65)//128 − 32` and *not* `floor(k/2) − 32`, which the entries above k = 64 disprove;
`LinCoef_FE0196` is `k//2 − 64` for k = 0..126 **and then breaks its own rule**: `T[127]` is 0
where the ramp gives −1. Both were checked entry by entry, which is how the exception surfaced.

---

## 6. What the zone contains, in full

| range | objects | what |
|---|---:|---|
| `0xFDF7E0-0xFE11EF` | 26 | two exponential curves, a log curve and its constant twin, the four `LinCoef` tables, an 8-bit sine, the five math tables, and seven small tables |
| `0xFE11F0-0xFE1360` | 18 | the reset images and bit-mask tables round 2 converted |
| `0xFE1361-0xFE1697` | 24 | the flash-bank strings and tables, eight small curves, and a 183-byte repeat |
| `0xFE1698-0xFE21E5` | 51 | copy B, emitted as its twin's objects with `_B` appended |
| `0xFE21E6-0xFFEFFF` | — | 118,298 bytes of `0x0E`, checked byte by byte |

Copy B differs from copy A in exactly **41** bytes — 40 relocated pointer bytes and the one
`0x0010C000` global parameter at `0xFE12C9` (`0x0030` in A, `0x0020` in B) — and **nothing cites
it**: `notes/prom_c_tail_census.py --copyb` finds no literal in an address-operand position
anywhere in the image. Literals only; a pointer built at run time would be invisible.

---

## 7. What is NOT established

* What most of the small tables are FOR. Where only the shape and the reader are known, the
  name says so (`Table_XXXXXX`, `Curve_XXXXXX`) and the header gives the index, the reader and
  the closed form — never a role.
* `Curve_FE0296` is 51 bytes but its reader masks the index to `0..127` (`res 7,C` at
  `0xFC6263`). Nothing in the reader bounds it to 50; the object's end rests on the next cited
  base, `0xFE02C9`, whose own closed form (a full 512-entry sine period) is independent.
  Recorded as a tension rather than resolved.
* `Curve_FE04C9` and `Curve_FE13D6` have no located upper clamp; their counts rest on the next
  cited base alone.
* That the `0..127` key of the `LinCoef` tables is a NOTE NUMBER. It is `voice_record[+0x0C]`
  with bit 7 cleared, and nothing here says what that field is.
* Why the initialiser image exists twice, and which copy the machine uses.

---

## 8. Two defect classes the gate cannot see, found and fixed in the same round

**Eleven "callers" that are data.** The `Called from:` list in every prom_c routine header comes
from an image-wide byte scan for `1D <addr24>` / `1E <disp16>`, and prom_c is a quarter data by
area. Eleven citations land inside an established data region — ten in the preset bank, one in
the f64 coefficient pool. The preset-bank ten settle it between them: they fall at four
repeating offsets *inside a 704-byte preset record* (`0x021`, `0x02D`, `0x041`, `0x061`), five
of them at `0x041` in records 121 and 123–126. A call site does not repeat at a data
structure's stride. All eleven headers now read **NO LOCATED CALLER**.
`notes/prom_c_phantom_callsites.py --selftest` keeps the live scan empty and re-checks the
recorded ten, including that each really does spell `calr <that routine>` in the data.

**Fourteen citations one or two bytes past their instruction.** In the block round 2 converted
at `0xFE11F0-0xFE1360`, eleven distinct addresses (fourteen mentions) named the address of the
24-bit *literal* inside the instruction rather than the instruction — one byte late for
`lda <X..>,addr24` (`f2 <addr24> 3x`), two for `add <X..>,#imm32` (`e9 c8 <addr24> 00`).
All fourteen now name the instruction; `notes/FINDINGS-prom_c-duplicate-initialiser.md` had one
of them too. Neither the byte gate nor `prom_c_audit_callsites.py` can see this class — the
latter checks CALL sites only — which is why the round-3 emitter derives its own
`Cited by:` lines mechanically, from the census, with the instruction offset subtracted.
