# prom_b 0xF0033F-0xF007FF — the four orphan tables, taken together

Lane brief: *"they were disassembled and named, but no code has been found that
reads them… take all four together."*  This note does that.  It is a
**notes-only** pass: no `.s` file, Makefile or ROM directory was touched.

Everything below is re-derived by

```
python3 wsa1/notes/orphan_tables_f0033f.py            # the whole argument
python3 wsa1/notes/orphan_tables_f0033f.py --selftest # 16 checks, all green
```

which is committed beside this note and refuses if any number here moves.

---

## 0. The one-paragraph answer

The span is **not four unrelated tables**.  It is **one array type, instantiated
three times**, plus two small byte tables that separate the instances.  The
record is **18 four-byte slots = 72 bytes**, and that width is *proven by a
reader*: four dispatchers at `0xF00CCF / 0xF00D10 / 0xF00D51 / 0xF00D92` do
`add XBC,BASE / ld XBC,(XBC) / jp XBC` with `BASE` = `0xF002AC`, `0xF002F4`,
`0xF0033C`, `0xF00384` — **four bases at an exact stride of 72**.  In every one
of the 16 records across the three instances, column 13 and column 14 hold the
`0x00FDB10E` *absent* filler and column 17 holds `0x00000000`.  And in each
instance the live pointers, read in the order **c0…c12, c16, c15**, form a
**single strictly ascending chain** — so the things they point at were stored
*consecutively, in that order, in one pool*, and the deltas are the object
sizes.

What is *in* those pools today is not what the pointers describe.  That part
is unchanged from the earlier passes, and this pass adds two new refutations of
the obvious rescue (§7, §8).

---

## 1. Extents, derived from the bytes

`runs()` in the script walks `0xF0033F-0xF007FF` and takes maximal runs of
aligned 4-byte words that are `0x00000000`, the `0x00FDB10E` filler, or an
address in the CS2 window `0xF00000-0xFFFFFF`.  No label, no target and no
prior belief is used.  (Runs shorter than 32 B with no pointer in them are
dropped — otherwise the zero padding *inside* `Data_F003CC` is picked up as two
spurious 2-slot runs; those two are listed in the script output for honesty.)

| object | extent | bytes | slots | ptr / absent / empty | records of 18 |
|---|---|---:|---:|---|---:|
| pad | `0xF0033F` | 1 | — | — | — |
| **run 1** `PtrTable_F00340` | `0xF00340-0xF003CB` | 140 | 35 | 26 / 7 / 2 | 1.944 ★ |
| **`Data_F003CC`** | `0xF003CC-0xF003F8` | 45 | — | byte ids | — |
| **run 2** `PtrTable_F003F9` (+`_F006CD`) | `0xF003F9-0xF00758` | 864 | 216 | 145 / 59 / 12 | **12.000** |
| **`Data_F00759`** | `0xF00759-0xF00761` | 9 | — | bit masks | — |
| **run 3** `PtrTable_F00762` | `0xF00762-0xF007FD` | 156 | 39 | 21 / 16 / 2 | 2.167 |
| `Data_F007FE` | `0xF007FE-0xF007FF` | 2 | — | `0E 30` | — |

★ Run 1 is 1.944 records, not 2, because **its record 0 begins one slot
earlier, at `0xF0033C`** — which the linker gave to the tail of the `ret` at
`0xF0033E`.  That is not a guess: `0xF0033C` is literally one of the four
dispatcher bases.  With that phase, run 1 is exactly **two records**.

**What sets each boundary** — every one is an arithmetic identity, not a
judgement:

* `0xF0033C + 2*72 = 0xF003CC` — run 1 ends exactly where `Data_F003CC` starts.
* `0xF003F9 + 12*72 = 0xF00759` — run 2 ends exactly where `Data_F00759` starts.
* `0xF00762 + 156 = 0xF007FE` — run 3 ends 2 B before `sub_F00800`, which sits
  on the `0x800` module boundary.
* The two byte objects are what change the 4-byte *phase*: `Data_F003CC` is 45 B
  and `Data_F00759` is 9 B, both odd.  That is why no single alignment ever fit
  the span.
* `PtrTable_F006CD` is **not** a boundary.  It is a legacy cut inside run 2;
  run 2's record 10 starts one slot earlier, at `0xF006C9`.  The label may stay,
  but nothing structural is at `0xF006CD`.

`Data_F003CC`, exactly:

```
0xF003CC  00 01 02 03 04 05 | 00 * 10      group A: SIX ids, 16-byte zero-padded
0xF003DC  06 07 08 09 0A 0B 0C | 00 * 9    group B: SEVEN ids, 16-byte zero-padded
0xF003EC  00 01 02 03 04 05 10 11 12 13 14 15 16   group C: THIRTEEN, unpadded
```

`C = A, then each of B plus 0x0A`.  `Data_F00759` is `01 02 04 08 10 20 40 80`
then one `00` that restores the 4-byte phase — a `1 << n` mask lookup.

---

## 2. The 18-slot record, established WITHOUT looking at a single target

Score for a candidate period `p`: the fraction of residue classes that are
*pure*, i.e. every slot in the class carries the same one of the three labels
{pointer, absent, empty}.  Target addresses are never read.  Null: the same
label multiset, shuffled.

| p | 12 | 16 | 17 | **18** | 19 | 20 | 24 | 36 |
|---|---|---|---|---|---|---|---|---|
| observed | 0.0833 | 0.0000 | 0.0000 | **0.3889** | 0.0000 | 0.0000 | 0.1667 | 0.5000 |
| null (4 000 shuffles) | 0.0005 | 0.0039 | 0.0053 | **0.0076** | 0.0093 | 0.0119 | 0.0260 | 0.0897 |

**18 is the smallest period reaching 0.25.**  36 scores higher *because it is a
multiple of 18* — it splits each true column into two half-length classes, each
of which is easier to be accidentally pure, which is exactly why its null is
also 12× higher.  ⚠ `p = 12` beats its null too, but on **one** pure class out
of twelve; it is not a competing framing.

★ Independently: the 72-byte stride is a **reader-side** fact.  The four
dispatcher bases are `0xF002AC`, `0xF002F4`, `0xF0033C`, `0xF00384` — three
consecutive differences of exactly `0x48 = 72`.

And the same column signature appears in all three runs:

```
run 1 (phase 1)  c0..c17:  A P P P P . P P P P P P P A A P . E
run 2 (phase 0)  c0..c17:  . . . . . . . . . P P P . A A P . E
run 3 (phase 0)  c0..c17:  A . P . . . . A P P P P P A A P A E
                                                     ^ ^     ^
A = absent in every record   E = empty in every record   . = mixed
```

`c13 = c14 = absent` and `c17 = empty` in **all 16 records of all three runs**.
Null for one column being uniformly *absent* across `n` records, given the
observed 82/290 filler density: `(82/290)^n`, which for the 12 records of run 2
is 1.3e-7 per column.

Descending `c15 > c16` pairs where both are pointers: run 1 **1/1**, run 2
**11/11**, run 3 0 (never both present).  Null 0.5 each.

---

## 3. The reader search — stated as a method, so the negative can be falsified

Six forms were searched, over **all four WSA1R images** (`prom_a`, `prom_b`,
`prom_c`, `prom_d`) and the KN5000 tree.

**3a. The head address as a stored 32-bit or 24-bit little-endian word.**
TLCS-900 spells a 32-bit immediate as 4 bytes LE (`e9 c8 3c 03 f0 00` =
`add XBC,0x00F0033C`) and a 24-bit address operand as 3 bytes LE
(`f2 20 0d f0 35` = `lda XIY,0xF00D20`); a *stored pointer* is the same bytes,
so this one scan covers "an immediate" and "a pointer parked in another table"
at once.  Result over 2 MiB of image:

| head | raw byte hits | verdict |
|---|---:|---|
| `0xF00340` | 0 | — |
| `0xF003CC` | 0 | — |
| `0xF003F9` | **0** | — |
| `0xF006CD` | **0** | — |
| `0xF00759` | 2 | **both refuted** — `prom_a 0xF8E52B` and `prom_c 0xF99CFC` are the same shared-kernel interrupt epilogue, where `59 07 f0` decodes as `pop XBC / reti / res 2,(0x20)` |
| `0xF00762` | **0** | — |

**3b. ★ The base-minus-index sweep — the search the earlier passes did not run,
and the reason their negative was weaker than it looked.**  The proven idiom
here is `add XBC, TABLE - 4*k`, so an exact-head search *cannot* find a reader
that subtracts an index offset.  Every base `head - 4k`, `k` from
`-(slot count)` to `+64`, was searched in both immediate widths.  This finds the
four live dispatchers for run 1 — and nothing for runs 2 and 3.

**3c. Decoded-operand filter.**  The raw scan has a high false-positive rate
(a specific 3-byte pattern is expected 2 MiB / 2^24 = **0.125 times** per image
set by chance, and `f2`/`1e`/`1b` are opcode bytes, so `xx xx f0` triples are
common inside real instructions).  Filtering the sweep's hits through the
`unidasm` decode of all three code images leaves, in the whole span
`0xF00200-0xF008FF`:

* **`prom_b`: exactly four 32-bit immediates — `0x00F002AC`, `0x00F002F4`,
  `0x00F0033C`, `0x00F00384`.**  All four are the dispatchers; all four serve
  run 1.
* Every 3-byte operand naming an address *inside* the span is emitted from a
  line whose own address is *also* inside the span — i.e. it is unidasm
  linearly decoding the table bytes as code.  Two exceptions, `0xF005BB` from
  `0xF021B8` and `0xF00776` from `0xF04473`, are both inside data regions
  (`0xF044xx` is the `"…VELOPE…KEY…"` string table); neither is an instruction.
* **`prom_a`: ZERO** decoded operands anywhere in `0xF002xx-0xF008xx`.  prom_a
  shares CPU 1's address space with prom_b and never names one byte of the span.
* `prom_c`: `0x00F00303` × 59, all from one repeating `40 03 03 f0 00` data
  pattern; and prom_c is CPU 2, which does not map `0xF00000` at all.

**3d. The 16-bit low half, for a banked reader.**  Counts in 2 MiB, against a
null of **32.0** occurrences for any given 16-bit value: `0x0340` → 311,
`0x03F9` → 6, `0x0762` → 21.  All three are at or below the null; `0x0340` is
above it because 0x0340 is a common small constant, not because of this table.
This form cannot be pushed further: a base assembled at runtime from a bank
register and a small constant is not searchable, and I do not claim it is.

**3e. The KN5000 tree** (518 files: `v7`, `v9`, `v10`, `v142`, `subcpu` sources
plus `original_ROMs`).  One 32-bit hit, `0x00F00340` at
`kn5000_table_data.rom+0x70817` — **refuted on alignment**: `0x70817` is odd,
and it sits in sparse zero-filled data.  A real 32-bit pointer in these images
is 4-aligned.  The 3-byte hits in `kn5000_v7/v9/v10_program.rom` are at the
chance rate (5 patterns × ~8 MiB / 2^24 ≈ 2.5 expected, 5 observed) and the
KN5000's TMP94C241 map has nothing at `0xF003xx` anyway.

**3f. ⚠ And the readers that DO exist are themselves orphans.**  This weakens
the "control" earlier passes leaned on.  `sub_F00CA2`, `sub_F00CE3`,
`sub_F00D24` and `sub_F00D65` are named by **no** immediate in any of the four
images, in either width — searched the same way as the tables.  So run 1 has a
consumer, but that consumer has no caller that can be found.  ★ Two of the four
dispatchers, moreover, aim at records that **do not exist**: `0xF002AC` and
`0xF002F4` are records −2 and −1 relative to `0xF0033C`, and both land inside
live code (`sub_F002C9`, `sub_F002F4`).  Whatever happened to this span
happened to the code around it too.

---

## 4. What the data is

### 4.1 ★ The pool-order chain — the result that types all three runs

Read each run in the order **c0, c1, …, c12, c16, c15**, skipping absent and
empty.  (That order comes from the column structure alone: c13/c14 are the
filler, c17 the terminator, and c15 > c16 in every record where both are live.)

| run | strictly ascending | null: same targets shuffled over the same cells, 20 000 trials |
|---|---:|---:|
| run 1 `F00340` | **25 / 25** | **0** |
| run 2 `F003F9` | **144 / 144** | **0** |
| run 3 `F00762` | 19 / 20 | **0** |

Run 3's single inversion is record 1's c2/c3 (`0xFE2D92` before `0xFE2D14`).

So the targets are **objects laid out consecutively in one pool, in field
order**, and the deltas are **object sizes**.  Run 2's chain crosses ROMs:
records 0-9 index a prom_b pool starting `0xF7828A`, records 10-11 a prom_a
pool starting `0xFC4082`.

Sizes, one line per record, columns `c0..c12, c16, c15` (`.` = absent):

```
run 1  r0     .   95   21   21   21    .   21   21   17   44   44   36   36   24   32
       r1     .   21   21   21   21   21   21   21   30   36   24   24   24    .   26

run 2  r0   188  188  176  176    .  154  155  155   45   36   59   90   51   39   52
       r1    36   36   24   24    .   17   17   17   17   17   17   90   17   39   52
       r2     .    .   36   36   24   24    .    .   45   36   59   90   51   39   52
       r3     .    .   36   36   24   24    .    .   17   17   17   90   17   39   52
       r4     .  165   28  161  146   24   24    .   45   36   59   80   51   39   52
       r5     .    .    .    .    .    .    .    .   45   36   59   90   51   39   52
       r6     .    .  139  123  160  123    .    .   30   36   44   36   36   24   32
       r7    25   25   25   25   25   25   25    .   17   44   44   46   46   24   32
       r8     .   21   21   21   21    .   21   21   17   44   44   36   36   24   32
       r9     .   21   21   21   21   21   21   21   30   36   24   24   24    .  (pool end)
       r10    .   21    .   18   21   21   36   36    .   65   65  136    .   24   44
       r11    .   21    .   18   21   21   36   36   54   65   65   65   65   24    .

run 3  r0     .  149  116    .  136  110  114    .   17   41   41   41   28    .   24
       r1     .  431 -126  346    .    .    .    .   60   41   41   71   41    .   32
       r2     .    .   (3-slot tail: absent, absent, 0xFE2F8C)
```

★ Note run 1's r0/r1 against run 2's r8/r9: the **presence patterns are
identical** (r0/r8 absent at c0 and c5; r1/r9 absent at c0 and c16) and the
sizes agree in 13 of 14 and 13 of 13 respectively.  That is suggestive of a
shared per-screen field layout, but it is offered as **an observation, not a
claim** — 21 is the modal size on both sides for unrelated reasons (run 1's
handlers are all 21 B because they are generated identically), and I did not
compute a null strong enough to carry it.

### 4.2 The one table with a reader says what a record is

The 26 targets of run 1 are proven routines (25 of 26 begin `EE 0C` =
`link XIZ,0`, against a null of **0.98** at the `EE 0C` density of that block).
Disassembled, they are a per-field action set for **two parallel screens**:

```
r0c2..c7  push 0x15/0x16/0x13/0x11/0x12  ->  0xFDC87E/C921/C9C4/CA2A/CA88   six live fields
r1c1..c7  push 0x0001 (each)             ->  0xFDC0FD/C149/C1BC/C22F/C2A2/C313/C386   seven
r0c9..c12 and r1c9..c12  push 0x0002/3/4 -> 0xFDB8D1 + 0xFDA6FC / 0xFDB903
r0c15 and r1c15          IDENTICAL code: push 0,0,0x80 -> 0xFDAE6A, 0xFDA6FC
```

The dispatchers wrap it as: call `0xFDBD28(a, b, &value, &index)`; if it returns
`0xFFFF`, do nothing; else `jp record[index](value)`.  That is a **hit-test →
field index → field action** loop, i.e. a UI page's control table.

⚠ The identification of the *fields* stops there.  `0xFDBD28` is not decoded,
and naming the screens from the constants (`0x0087`-`0x008A` to `0xFDA6FC`)
would be inference on inference.

### 4.3 The two byte tables

`Data_F00759` is `1 << 0 .. 1 << 7`: a bit-mask-by-index lookup.  Its shape is
unambiguous; **what indexes it is not known** and no reader was found (§3a).

`Data_F003CC` is three ascending one-byte id lists of **6, 7 and 13** entries,
with `C = A ++ (B + 0x0A)`.  Run 1's record 0 has **six** live fields in
c1..c7 and record 1 has **seven**; and the ids record 0's setters push
(`0x11, 0x12, 0x13, 0x15, 0x16`) are members of group C's second half
`0x10-0x16`.  ⚠ **That is a WEAK observation and is graded as one.**  The
`c1..c7` window was chosen after seeing the answer, and 6 and 7 are small
numbers; the id-membership half is the only part that is not post-hoc.

---

## 5. What the run-2 and run-3 targets are NOT — three refutations with nulls

| test | observed | null | source |
|---|---:|---:|---|
| run 2's 121 prom_b targets on the proven 72-byte icon grid at `0xF78028` | **1** | 1.7 | earlier lane, `gen_prom_b_f78028_icon_sheet.py` |
| run 2's 24 prom_a targets on a `DisplayList_FC4000` record boundary | **3** | 1.8 | earlier lane |
| run 3's 21 targets on an instruction boundary in prom_a `0xFE28B2-0xFE2F8C` | **6** | 8.6 (35.7 % of all addresses) — **below chance** | earlier lane |
| ★ NEW — a **constant relocation** puts the prom_b targets back on the icon grid | max residue bucket **6** of 121 | mean 1.68, sd 1.29, 3σ = **5.5** — inside the null | §7 |
| ★ NEW — a constant relocation puts the prom_a targets back on record boundaries | best shift **7** of 24, and **5** different shifts reach 7 | 2.21 per shift; over 401 shifts, ~2.8 shifts reaching 7 is **expected** | §7 |
| ★ NEW — the objects parse as display lists: op/len walk from a target lands with **zero drift** on the next target | **0 / 143** | **0.0040** (80/20 000 random starts, same size multiset) | §8 |
| ★ NEW — first bytes at the targets look like DL opcodes | **77 distinct** values, max `0xFF` | the real op bound is `0x24` | §8 |

The relocation test is the one that mattered: "vestigial index, pool moved" is
the natural rescue, and a *constant shift* is its simplest form.  It does not
work in either pool, and the failure is not marginal — it is at the null.

---

## 6. Verdicts, graded

### `PtrTable_F00340` — `0xF00340-0xF003CB`, 35 slots, 4 B each, 2 records of 18
**PROVEN: a jump table indexed by a computed field number, 18 slots per record.**
Four readers do `add XBC,BASE / ld XBC,(XBC) / jp XBC`; the bases are 72 B
apart; 25 of 26 targets are function prologues against a null of 0.98.
**STRONG (not proven): it is the per-field action table of two UI screens** —
from the handlers' parallel structure, not from the name.
⚠ **Downgrade attached:** its four readers have no findable caller, and two of
them aim at records that do not exist.  It is a *live-shaped* table in a *dead*
subsystem, which is a weaker control than earlier notes assumed.

### `Data_F003CC` — `0xF003CC-0xF003F8`, 45 B
**PROVEN shape:** three ascending one-byte id arrays of 6, 7 and 13 entries,
the first two zero-padded to 16 B, with `C = A ++ (B + 0x0A)`.
**UNIDENTIFIED purpose.**  The 6/7/13 correspondence with run 1's two records
and the id overlap with `0x10-0x16` are **WEAK** — one of the two halves is
post-hoc.  No reader in any form (§3).

### `PtrTable_F003F9` (+ the legacy cut `PtrTable_F006CD`) — `0xF003F9-0xF00758`, 216 slots, **12 records of 18**
**STRONG: the same 18-field record type as `PtrTable_F00340`, holding pointers
to 145 variable-size objects stored consecutively in two pools in field order.**
Four independent facts, each with its null: the period test (0.3889 vs 0.0076);
the identical column signature (c13/c14 absent, c17 zero in all 12 records);
c15 > c16 in 11 of 11; and the pool-order chain, 144/144 ascending against 0 in
20 000 shuffles.
**UNIDENTIFIED: what the 145 objects are.**  They are not the icon sheet's
24×24 cells, not `DisplayList_FC4000`'s records, not display lists in their own
right, and not a constant relocation of any of those (§5).  The best-supported
reading is a **stale resource index left behind when the pools were relaid
out** — but that is a hypothesis with no in-image test, and it is not graded
above WEAK here.

### `PtrTable_F00762` — `0xF00762-0xF007FD`, 39 slots, 2 records of 18 + a 3-slot tail
**STRONG: the same record type again** (c13/c14 absent, c17 zero in both full
records; 19/20 ascending in pool order against a null of 0).
**UNIDENTIFIED: what its 21 targets in prom_a `0xFE28B2-0xFE2F8C` are.**  prom_a
currently frames that window as code and this table does not support that
framing (6/21 on an instruction boundary, *below* the 8.6 expected).  ⚠ The
3-slot tail (`absent, absent, 0xFE2F8C`) is **not explained**; a truncated
array is not a normal compiler output and I do not have a reading for it.

### `Data_F00759` — 9 B, and `Data_F007FE` — 2 B
`Data_F00759`: **PROVEN shape** (`1 << 0 .. 1 << 7` plus a phase pad),
**UNIDENTIFIED index**.  `Data_F007FE` (`0E 30`): unidentified; "pad to the
`0x800` module boundary" fits the position but only the first byte is the
image's `0x0E` filler, so it stays a guess.

---

## 7. The nulls, collected

Every claim above with its null in one place, because this project has been
burned by patterns that were what random bytes look like.

| claim | observed | null |
|---|---:|---:|
| a word in the span is empty/absent/CS2-pointer | 290/290 | **0.0900** measured over the rest of prom_b (not 2.4e-4 — the words here are not uniform) |
| period 18 pure-column fraction | 0.3889 | 0.0076 (20 000 label shuffles; max ever seen 0.1667) |
| a column is *absent* in all 12 records of run 2 | 2 columns | (82/290)^12 = 1.3e-7 per column |
| c15 > c16 | 11/11, 1/1 | 0.5 per pair |
| pool-order chain ascending | 144/144, 25/25, 19/20 | 0 / 20 000 shuffles, each run |
| run 1 targets begin `EE 0C` | 25/26 | 0.98 (measured `EE 0C` density of the target block) |
| run 2 / run 3 targets begin `EE 0C` | 0/145, 0/21 | 0.00, 0.06 |
| targets on the 72-byte icon grid | 1/121 | 1.7 |
| targets on a DL record boundary | 3/24 | 1.8 |
| a constant shift restores the grid | max bucket 6 | mean 1.68, 3σ = 5.5 |
| a constant shift restores DL boundaries | 7/24, 5 shifts tie | 2.21/shift; ~2.8 shifts reaching 7 expected over 401 |
| op/len walk, zero drift | 0/143 | 0.0040 |
| a specific 3-byte pattern in the 2 MiB image set | — | 0.125 occurrences |
| a specific 16-bit value in the 2 MiB image set | 311 / 6 / 21 | 32.0 |
| KN5000 3-byte hits, 5 patterns × ~8 MiB | 5 | ~2.5 |

⚠ **One coincidence explicitly declined.** The service manual lists **eighteen**
export AREAS for the SX-WSA1R (`FINDINGS-fonts.md` §, p.1), and the record here
is eighteen slots wide.  There is no evidence for a link and there is evidence
against: run 1's columns are *fields of one screen* with different handlers,
not eighteen variants of one thing, and a per-area table in a single-area build
would have one live column, not fifteen.  Small integers repeat; this one is
noted only so the next lane does not rediscover it and believe it.

---

## 8. What would settle each open question

1. **A second build.**  The vestigial-index reading is the only one that
   survives §5, and it is *untestable inside this image set*.  The domestic
   **SX-WSA1** (non-`R`) shares this source; so may an earlier WSA1R service
   ROM.  One more `prom_b` would settle run 2 and run 3 in an afternoon: if the
   same 12 records point at objects that *do* tile that build's pool, the
   tables are a live index here rendered stale by a relayout, and the object
   kinds fall out immediately.
2. **`0xFDBD28` in prom_a.**  It is the routine all four dispatchers call, and
   it returns the *record index* and the *value* handed to the handler.  Decode
   its two inputs and two outputs and the meaning of a "field" is settled — and
   with it the column semantics that run 2 and run 3 inherit.
3. **Who calls `sub_F00CA2/CE3/D24/D65`.**  No immediate names them.
   `sub_F00800` in the same file is documented as reached from *routine-directory*
   slots `T_F40970..T_F40980` holding `jp 0x00F00800`.  Enumerating that
   directory — and finding whether it is built at runtime from a table — is the
   one search form §3 could not run, and it is where a caller would be.
4. **prom_a `0xFE28B2-0xFE2F8C` needs framing.**  Run 3 says 21 pointers into a
   1 755-byte window, which is what an object index looks like, while prom_a
   calls it code and only 6/21 land on an instruction (below chance).  Someone
   should decide whether that window is code at all; run 3's 21 addresses and
   their deltas (§4.1) are a free framing hypothesis to test against.
5. **Run 3's 3-slot tail.**  Either the array is 39 slots for a reason, or
   `0xFE2F8C` at `0xF007FA` belongs to something else.  A second build settles
   this one too.

---

*Reproduce: `python3 wsa1/notes/orphan_tables_f0033f.py --selftest`
(16 checks).  Nothing in `prom_a`, `prom_b`, `prom_c`, `prom_d` or the KN5000
sources was modified by this lane.*
