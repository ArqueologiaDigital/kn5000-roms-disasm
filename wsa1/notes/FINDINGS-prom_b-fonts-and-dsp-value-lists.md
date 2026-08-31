# prom_b's largest `.incbin` span, closed at both ends

**Round 7, 2026-08-25.** `0xF157A8-0xF27BFF` was 74,840 bytes — the biggest
unconverted span in the tree, and the one `notes/prom_b_span_frontier.py` ranked
first with `proven 0`. It is now 58,801 bytes of assembly and one 16,039-byte
remainder that is named rather than guessed.

| range | bytes | what | substantive |
|---|---:|---|---:|
| `0xF157A8-0xF17558` | 7,601 | the DSP effect editor's value lists — 18 record arrays + 17 string tables | 7,601 |
| `0xF17559-0xF1B3FF` | 16,039 | **still `.incbin`** — same family, does not tile; see §5 | — |
| `0xF1B400-0xF26D8F` | 47,504 | the twelve character generators, cell by cell | 47,504 |
| `0xF26D90-0xF27BFF` | 3,696 | zero pad + `0x0E` pad | `.fill` |

prom_b substantive coverage: **236,982 → 292,087 bytes (45.2% → 55.7%)**.
Every number here is re-derived by a script named beside it; the byte gate
(`python3 scripts/analysis/assert_byte_identical.py`) passes on every step.

---

## 1. The twelve character generators are now source, and the twelfth's cell count is settled

`notes/FINDINGS-fonts.md` established the twelve tables from **prom_a's** side —
base, pitch and geometry, all as instruction operands — and closed by saying the
bytes belong to prom_b's lane. They are now in it:
`python3 notes/gen_prom_b_fonts.py --asm`, one `.byte` line per glyph cell,
addressed and code-numbered, blank cells marked so the defined ranges are visible
in the listing. Labels are `Font_SvcNN_WxH` — the service number, width and pitch
are what prom_a *proves*; the script identifications stay in the headers with the
grade that note gives them (byte-proved for the accented Latin block and the kana
cross-check, **visual** for the two ideograph sets).

`--selftest` runs 46 checks: each base is found as a literal in prom_a at a named
address, each table ends exactly on the next one's base, and the emitted bytes are
compared with the ROM.

### ★ The one number this adds: `0xF25590` has 128 cells

`FINDINGS-fonts.md` §8 listed it as open, because that table is last and
`next_base - base` cannot count it. It is **128**:

* the last non-zero byte in the entire font region is at `0xF26D7C`;
* `0xF25590 + 128 × 48 = 0xF26D90`, so that byte falls inside cell **127** — the
  last cell is non-blank, which is the test a cell count has to pass;
* the defined codes are exactly `0x21`-`0x7F`, contiguous: a 7-bit page with its
  printable half drawn;
* what follows is 2,496 bytes of `0x00` and then 1,200 of `0x0E`, i.e. padding.

⚠ **The rival reading, 180 cells, is rejected and here is why it is tempting.**
`(0xF27750 − 0xF25590) / 48 = 180` exactly, so the whole extent up to the `0x0E`
pad divides evenly. That proves nothing: the base and the pad start are *both*
multiples of 48, so the division is exact for arithmetic reasons. 180 would
append 52 blank cells; 128 puts a cell around the last non-zero byte.

⚠ Note also what the `0x0E` run is **not**. An early draft of `FINDINGS-fonts.md`
read it as glyph data and reported the table running to code `0x1FF`, because
`0x0E` is non-zero. That retraction is now recorded at the `.fill` itself, where
the next reader of the source will meet it.

---

## 2. `0xF157A8-0xF17558` is the DSP effect editor's VALUE column

18 arrays of interpreter-B display-list records; each array is followed
**immediately** by the string table its records index. The 35 objects tile
`0xF157A8-0xF17558` with **no gap and no overlap**, which is the check that makes
the decode more than a story: `python3 notes/gen_prom_b_dsp_value_lists.py
--selftest`, 87 checks.

What the tables hold is what the machine puts on screen next to a parameter name:

| table | entries × width | content |
|---|---|---|
| `0xF15A7C` | 27 × 5 | `   40` … `  16k` — third-octave centre frequencies |
| `0xF15B7B` | 32 × 5 | `  0.1` … ` 20.0` |
| `0xF15C93` | 49 × 5 | `-12.0` … `+12.0` in 0.5 steps |
| `0xF15E00` | 25 × 5 | `-24.0` … `  0.0` |
| `0xF15EF5` | 100 × 4 | ` 0.0` … `40.2` |
| `0xF160FD` | 4 × 6 | ` SINE `, `TRIANG`, `SQUARE`, blank |
| `0xF1618D` | 100 × 5 | `  0.0` … `34.95` |
| `0xF163F9` | 100 × 5 | `    0` … `19.6k` |
| `0xF16665` | 100 × 5 | `  1.0` … `61.00` |
| `0xF168D1` | 73 × 5 | `-1200` … `+1200` |
| `0xF16AB6` | 95 × 5 | `0.001` … `0.500` |
| `0xF16D09` | 100 × 5 | `  0.2` … ` 20.0` |
| `0xF16F75` | 100 × 5 | ` 0.01` … ` 1.00` |
| `0xF171E1` | 100 × 5 | `   10` … ` 2900` |
| `0xF1744D` | 2 × 5 | ` SLOW`, ` FAST` |
| `0xF174CF` | 3 × 6 | ` WIDE `, `MIDDLE`, `NARROW` |
| `0xF15898` | 4 × 1 | four single bytes |

⚠ The tables carry **no units**. Reading `-1200 … +1200` as cents, or
`40 … 16k` as hertz, is the reader's inference and is not asserted — although
§4 shows where the units actually live. The parameter NAMES those values pair
with are the neighbouring `EffectParamNames_F15024` (`EMPHASIS Fc`,
`LFO WAVEFORM`, `PITCH L`, `PRE DELAY`, `REVERB TIME`, …); which name goes with
which table is **not established**.

### ★ The 15-byte stride, and why it is not decoration

`0xF132E4` is a 32-entry array of pointers, one per editor screen. The consumer
at `0xF110FA` fetches the row's array, **adds a byte offset**, and calls
`T_F42E0C` → `DisplayListB_RunOne_Stack` (`0xF3183D`), which sets `XIX = XIY+1`
so interpreter B's `while XIY < XIX` loop draws **exactly one record**.

Records are therefore addressed *individually*, at `base + offset`, and every
line of a screen has to be reachable by the same arithmetic. So every record is
padded with `0xFF` out to a uniform **15 bytes**, whatever its own opcode
implies — op 00 (10 bytes) gets five pad bytes, op 05 (11) gets four, op 02 (15)
gets none. The walk asserts that padding byte for byte, and it is what turned
three "unexplained ~110-byte gaps" into the middle of a 32-record array.

All 176 records read the **same** RAM byte, `0x2640`, which the caller writes at
`0xF110AC` immediately before running the record.

★ **The unit is a group of eight, and the ROM says so.** A record's `+0x0D` is a
screen position. Within an array it steps by a constant `0x280`, and then RESETS
— and it resets after exactly eight records, every time. Sixteen of the eighteen
arrays are one group of 8; `0xF157A8` is **two** groups and `0xF1589C` is
**four**, which is why a naive "an array is 8 records" would have been wrong for
176 − 8×16 = 48 of them. `--selftest` asserts `sorted({len(g)}) == [8]` for every
array, so a nineteenth array with a group of 7 could not slip through.
⚠ Which effect parameter occupies which line is **not established**, nor what
selects between the groups of a multi-group array: the caller adds a byte offset,
so `15 × (8·group + line)` reaches any record, but nothing converted here computes
that offset.

### ⚠ Entry counts come from the EXTENT, never from the mask

A record's mask gives `(mask >> shift) + 1`, an **upper bound on the index**, not
a count. `0xF15A7C`'s record says `0x1F` → 32; the table is **27** entries,
because its extent to the next object is 135 bytes and 135 / 5 = 27. Every count
in the table above is an extent divided by the width the record itself passes as
`BC`, and every one of those divisions is asserted to be exact.

---

## 3. ⚠⚠ CORRECTION: `0xF131E4` is FOUR arrays of 32, not one table of 128

`prom_b/wsa1_prom_b.s` carried `0xF131E4-0xF133E3` as a single
`DispatchTable_F131E4` of 128 entries, headed:

> *"the code that indexes it fetches an entry and then TRANSFERS to it, so the
> entries are ENTRY POINTS and they seed this block's code walk"*

with the count justified by a chain rule that "stops at the first word that is
not an `0x00F0xxxx`-`0x00F7xxxx` address". **Entries 64..95 are not entry points.**
They are the display-list pointers of §2, and `0xF157A8` as instructions decodes
`push SR / retd 0x2640 / db`.

The truth is four parallel 32-entry arrays sharing one screen-row index:

| base | contents | its only reference |
|---|---|---|
| `0xF131E4` | 32 code pointers | `0xF10700` |
| `0xF13264` | 32 code pointers | `0xF110EA` |
| `0xF132E4` | 32 **display-list** pointers | `0xF110FA` |
| `0xF13364` | 32 code pointers | `0xF1172A` |

Re-derived by `python3 notes/prom_b_screen_arrays.py` (18 checks):

1. each base occurs **exactly once** as a 3-byte little-endian address across all
   three code images, at the address named above;
2. in every array, **rows 0 and 31 hold that array's own default** — `0x00F42C70`
   for the three code arrays, `0x00F157A8` for the data one;
3. the only indexer of `0xF131E4` (`0xF106FE`: `4*H + base`, then `jp (XBC)`)
   takes `H` from byte `[4i+1]` of the 654 four-byte records in
   *(⚠ this 654 counts records in prom_b; the 654 handler slots of prom_a's
   dispatch matrix at `0xFF3800` are a different structure of the same size)*
   `0xF124EC-0xF12F23`, whose highest live value is `0x1E`. It cannot reach index
   32, let alone 64.

★ **Why the chain rule ran through three boundaries:** six of the eight edge slots
hold the *same* constant, `0x00F42C70`. A rule that stops at "the first word that
is not a code address" cannot see a boundary marked by a code address. That is a
general warning about the chain rule, not a one-off.

---

## 4. ⚠⚠ CORRECTION: the "units strip" is a 32 × 7 table, and a record points at it

`EffectParamNames_F15024` was emitted as **113 rows of 17 bytes plus a 3-byte
remainder**, with a header that read "1,924 printable bytes … and, after them, a
units strip (`Hz`, `ms`, `s`)" and listed "where the units strip starts" as
unknown, adding "Rows 100..112 carry no colon; that is recorded, not explained".

Rows 100..112 are not 17-byte rows. `0xF156C8` is the `+7` pointer of the eight
opcode-02 records at `0xF157A8`, which pass **7** as the entry width and mask
`0x1F`; `0xF156C8 + 32 × 7 = 0xF157A8`, the first byte of the next block. Framed
at 7, the table is the editor's **units column**, right-aligned:

```
[ 0]        [ 2]      Hz  [10]      s   [16]      ms  [29]      s
[ 1]        [ 3]      Hz  [13]      s   [20]      ms  [30]      s
```

— 32 rows of `     Hz`, `     s `, `     ms` and blanks, each flush against the
right-hand edge of its field. The 17-byte framing scattered those two-character
units across three columns, which is exactly why nobody could say where the strip
started. The name table above it is therefore **100 rows**, not 113, and
`0xF15024 + 100 × 17 = 0xF156C8` exactly.

Both headers now carry the correction and the evidence. The bytes never changed;
only the framing was wrong, and the byte gate cannot see a mistake of that kind.

---

## 5. What is left, and why

`0xF17559-0xF1B3FF`, 16,039 bytes, stays `.incbin`. It is the same family — a
sweep of every 32-bit pointer in all three images finds **182 distinct targets**
inside it, from 279 sites in prom_b, 45 in prom_a and 2 in prom_c — but it does
**not** tile:

* a stride-15 walk from **every one of the 182 targets** yields fewer than two
  records — 0 of 182, measured, not sampled. Whatever is in there, it is not more
  of §2's structure;
* `0xF17A6C` holds a **29**-entry array of pointers whose targets are spaced
  exactly `0x48` — `0xF17AE0` to `0xF182C0`, every delta 72 — and nothing in the
  converted material says what a `0x48`-byte record is (the array itself ends at
  `0xF17AE0`, i.e. it abuts its own first target);
* `0xF1B04B` onwards is a pointer array with a 17-byte spacing, i.e. opcode-07
  records, whose readers are in **prom_a** (`0xFBB88C`, `0xFBC728`, `0xFBE094`,
  …), not here;
* **two** targets come from prom_c — `0xF17600` (from `0xFAFDE0`) and `0xF17860`
  (from `0xF9C543`) — which no reading of this region yet accounts for. (A third
  prom_c pointer, `0xF17100`, lands in the part already converted above.)

Every figure in this section comes from
`python3 notes/gen_prom_b_dsp_value_lists.py --leftover`.

Those are four concrete threads for the next round, in the order a walker would
find them cheapest. Guessing a framing for them would put 16,039 bytes of
plausible-looking rows into the source and the byte gate would applaud.

## 6. Does this move an emulation gap?

Not directly, and the honest answer is worth stating. `WSA1-EMULATION-DISASM-GAPS.md`
gap **O** asks which panel button is which bit, and suggests "a converted display
list that reacts to one group would name it". These lists react to **no** panel
group: all 176 records read one staging byte that the caller has already computed.
What the round does supply is the machinery gap O would need — the screen-row
array (§3), the one-record entry point, and the stride — plus the twelve fonts as
source, which any future screen-rendering work has to index.
