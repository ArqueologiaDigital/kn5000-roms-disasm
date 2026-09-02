# The WSA1's SECOND display-list interpreter, and what it settles

**Short version.** The UI display lists are run by **two** interpreters, not one.
Interpreter A (`0xF31A09`) draws what the record says. Interpreter B (`0xF31AF0`)
draws what a **variable** says. They share the `(opcode, length)` record header
and nothing else: different opcode space, different handler table, different
field layout.

Recognising that resolves, in one step, the biggest open item in
`FINDINGS-ui-display-list.md`:

> ⚠ CORRECTED 2026-08-24: an audit re-ran the check and found **341 of 4,011
> walked records violate it**

**They do not violate anything.** All 341 are interpreter-B records that the
audit measured against interpreter A's field layout. Judged by the interpreter
that actually runs them, the exception count is **zero on both sides**.

```
$ python3 notes/prom_b_dl_length_audit.py --edges
  sites in prom_b that FRAME: A 243 of 244, B 158 of 162      that do NOT frame: 5
  distinct records reached: 4097
  A only   3603 records      0 disagree
  B only    494 records      0 disagree
  both        0 records      0 disagree
  cross-check -- B-only records judged by interpreter A's layout: 353 of 494 disagree
```

The two figures differ (341 vs 353) only because the committed summary merges
overlapping call sites into spans before walking, and merging destroys one good
span; see "What merging costs" below.

---

## How a record is attributed to an interpreter

Call sites pass both ends and name the interpreter in the same three
instructions:

```
    ld  XIY, <list start>
    ld  XIX, <list end>
    call 0xF417F0            ; thunk -> 0xF31A09, interpreter A
    call 0xF417F4            ; thunk -> 0xF31AF0, interpreter B
```

Walk each site **separately**. A record is "A only" if every site that reaches it
calls `0xF417F0`, "B only" if every site calls `0xF417F4`. Measured: 3,603 A-only
records, 494 B-only, and **0 records reached by both** — the two interpreters'
lists are disjoint.

## Interpreter B's record layout, and where every field comes from

Two field extractors sit in front of every handler:

| routine | what it reads | highest record byte |
|---|---|---|
| `DisplayListB_ExtractField` `0xF31CC5` | `IX=(XIY+2)` (a 16-bit RAM address), `A=(IX)`, `A &= (XIY+4)`, `C=(XIY+5)&7`, `A >>= C` | `+5` |
| `DisplayListB_ExtractFieldSigned` `0xF31CE4` | the same, then a flag byte at `(XIY+0x0A)` — or `(XIY+0x0C)` when the opcode is `0x0B` — whose bit 7 selects unsigned (`xor W,W`) or signed (`exts WA`) | `+0x0A` / `+0x0C` |

The implied length of a record is the highest byte its handler touches, plus one.
That is a reading of the handler's instructions, not a guess:

| opcode | handler | length | what `+7` is |
|---|---|---:|---|
| 00 06 | `0xF31BA1` | 10 | word → IX; `+9` digit count |
| 01 | `0xF31C9E` | 12 | no pointer; `+6`,`+8`,`+0x0A` are three words; function hard-coded `0x0A` |
| 02 | `0xF31B21` | 15 | **long → string table**, `+0x0B` = entry width, `+0x0D` → IX |
| 03 08 | `0xF31B57` | 11 | **long → array of 8-byte entries** (`sla 3,HL`) |
| 04 | `0xF31B86` | 11 | **long → array of 6-byte entries** (`mul HL,6`) |
| 05 | `0xF31BD7` | 11 | word → IX; `+9` digit count; `+0x0A` sign flag |
| 07 | `0xF31B39` | 17 | as 02, plus `+0x0F` → `(0x2532)` |
| 09 0A | `0xF31C14` | 12 | word → `(0x2530)`; `+9` → `(0x2532)`; `+0x0B` digit count |
| 0B | `0xF31C56` | 13 | as 09, plus `+0x0C` sign flag |
| 0C 0D 0E | `0xF31D20` | ≥2 | bare `ret` |

Every one of the 341 records the old audit flagged has **exactly** the length this
table gives:

```
op 02 len 15 (x175)  op 03 len 11 (x63)  op 04 len 11 (x3)   op 05 len 11 (x62)
op 09 len 12 (x27)   op 0A len 12 (x3)   op 0B len 13 (x8)
```

Sharper still, and the strongest form of the result: across the whole image
**each of interpreter B's eleven live opcodes has exactly one record length**, and
it is the one its handler implies.

```
op 00 x74   len 10      op 02 x183  len 15      op 03 x67  len 11
op 04 x3    len 11      op 05 x62   len 11      op 06 x32  len 10
op 07 x30   len 17      op 08 x5    len 11      op 09 x27  len 12
op 0A x3    len 12      op 0B x8    len 13
                                          494 records, no opcode with two lengths
```

Note especially `op 0B len 13`: 13 rather than 11 **because** the sign flag moves
from `+0x0A` to `+0x0C` for that one opcode, which is a two-instruction detail
inside `ExtractFieldSigned` (`cp (XIY),0x0B` at `0xF31D02`). A layout invented to
fit the data would not have predicted that.

## The three things interpreter B can draw

1. **A decimal number.** Handlers `0xF31BA1`, `0xF31BD7`, `0xF31C14`, `0xF31C56`
   call thunk `T_F41AF0` → prom_a `0xF8BCAF` or `T_F41AF8` → prom_a `0xF8BCC9`.
   `0xF8BCD7` is a decimal converter: it subtracts 100 then 10 repeatedly and
   leaves three digits at `0x2661`, `0x2662`, `0x2663`; `0xF8BCAF` blanks the
   leading ones with `0x20`. The record's digit-count byte then picks the first
   digit drawn (3 → `0x2661`, 2 → `0x2662`, else `0x2663`). The signed forms use
   `0x2660` and one more character — the sign.
2. **The n-th entry of a string table** (`0xF31B21`, `0xF31B39`): `XIY` is
   re-pointed at the `+7` table, `BC` is the entry width from `+0x0B`, and `HL`
   is the extracted field — the index.
3. **The n-th entry of a parameter array** (`0xF31B57` → 8-byte entries,
   `0xF31B86` → 6-byte entries), loaded into `(0x2530..0x2536)` or `IY/BC/HL`.

Of the 213 string-table pointers B records carry, **182 land in prom_b ROM** and
31 in RAM (a live text buffer).

## Operand tables recovered from the gaps

`notes/prom_b_dl_operand_tables.py` follows every `+7` (interpreter B) and `+2`
(interpreter A opcode 03/04) pointer, computes the size its handler implies, and
reports which of the 60 `.incbin` gaps between the display lists are **exactly
tiled** by the objects that point into them. Thirteen are, for 999 bytes, and
they are now assembly rather than `.incbin`.

Exact tiling matters because the entry count a record implies —
`(mask >> shift) + 1` — is an **upper bound on the index**, not a measurement of
the array. Where tiling confirms it, the count is real; where it does not, the
gap stays `.incbin`. Example of the difference: the record at `0xF030E6` has mask
`0x0F`, which would allow 16 entries, but its array's extent is 40 bytes = 5.

The largest is the gap `0xF031C9-0xF03440`, 632 bytes, which partitions with no
slack at all into three 5×8-byte parameter arrays and then

**`DLTable_F03241` — 64 names of 8 characters, the WSA1's resonator list:**

```
ORIGINAL  STRING  CYLINDER   CONE     FLARE   PLATE L  PLATE H   MEMB L
 MEMB H  THROUGH   MELLOW    MUTE     BRIGHT    MOVE    RANDOM   OCTAVE
HARMONIC  METAL    BOTTLE    MELLOW    MUTE     BRIGHT    MOVE    RANDOM
 OCTAVE    SOFT     MELLOW    MUTE     BRIGHT    MOVE    RANDOM   OCTAVE
 MELLOW    MUTE     BRIGHT    MOVE    RANDOM   OCTAVE   WOOD L   WOOD H
METAL L  METAL H   MUTE L   MUTE H  BRIGHT L BRIGHT H  MOVE L   MOVE H
RANDOM L RANDOM H SMALL L  SMALL H  LARGE L  LARGE H   MUTE L   MUTE H
 SLAP L   SLAP H   MOVE L   MOVE H  RANDOM L RANDOM H SPECIAL1 SPECIAL2
```

`0xF03241 + 64 × 8 = 0xF03441`, exactly where the next display list starts. The
record that reads it (`0xF0302A`, opcode 07) carries mask `0x3F`, i.e. exactly 64
indices. Two independent numbers, same answer.

The other gap that tiles with text in it is `0xF04CBD-0xF04CDD`, 33 bytes:
`DLTable_F04CBD` is 25 one-character entries and `DLTable_F04CD6` is two
four-character entries, `"LOW "` and `"HIGH"`. The 25 characters are

    A B C D E F G H I J K L M N O P Q R S U V W X Y Z

— the alphabet **with `T` missing**, which is in the ROM, not a transcription
slip (`python3 -c "print(open('original_ROMs/wsa1_prom_b.ic13','rb').read()[0x4CBD:0x4CD6])"`).
Why is not established.

More UI text is visible in gaps that do NOT tile exactly, so it is described here
but left as `.incbin`: `"FIX MOVE"` at `0xF03478`, `"OFF ON"` at `0xF034D2`,
`"OFFON "` at `0xF034D8`, and in the neighbourhood of the non-framing sites
`"PT1".."PT8"`, `"ON OFF"`, `"OFFON "`, `"...PART3PART4PART5PART6PART7PART8"`,
`"TR13".."TR16"`, `"...R53R54R55R56R57R58R59R60R61R62R63"`.

## The five call sites whose lists do not frame

Un-merged, 243 of 244 interpreter-A sites and 158 of 162 interpreter-B sites walk
their length bytes exactly onto the end address the caller passes. The five that
do not are listed here with what was actually checked.

**All five are genuine instructions.** Each was disassembled in context and each
is a real `ld XIY,imm32 / ld XIX,imm32 / call` triple at an instruction boundary,
not a false positive of the byte-level scan:

| list | interpreter | the call site | first byte | what the interpreter would do |
|---|---|---|---|---|
| `0xF286B8-0xF286E4` | B | prom_a `0xF90BAA` | `0x32` | `0x32 >= 0x0F` → `calr 0xF3199D` (`PrintHex32_XIY`) and return |
| `0xF28724-0xF28750` | B | prom_a `0xF90BBF` | `0x00`, length `0xA7` | one garbage record, then `XIY` passes `XIX` and the loop ends |
| `0xF287C1-0xF287CB` | A | prom_a `0xF90BDE` | `0x2F` | `0x2F >= 0x24` → `calr 0xF3199D` and return |
| `0xF29710-0xF2972E` | B | prom_a `0xF90A90` | `0x0B`, length `0x7E` | one garbage record, then the loop ends |
| `0xF3B651-0xF3B65B` | B | prom_b `0xF7E799` | `0x00`, length `0x0B` | **runs correctly** — see below |

The last one is not a defect at all. `0xF3B651` is a well-formed interpreter-B
opcode-00 record: `00 0B 40 26 FF 00 06 C4 00 02` — variable `0x2640`, mask
`0xFF`, shift 0, function `0x06`, `IX = 0x00C4`, 2 digits. The handler touches 10
bytes; the length byte says 11. The interpreter advances `XIY` to `0xF3B65C`,
which is past `XIX = 0xF3B65B`, and the loop test `cp XIX,XIY / jr ULE` stops.
So the machine draws the record and stops; only a walker that insists on landing
*exactly* on the end address calls this a failure. It is the only record in the
image whose length byte over-declares.

The other four start inside data that a **neighbouring, correctly framing record
points at**:

* `0xF286B8` is the sixth byte of the 3-character-per-entry string table at
  `0xF286B3`, which the correctly-formed opcode-07 record at `0xF286A2` points at
  with `BC = 3` and mask `0x07` — 8 entries × 3 = 24 bytes, ending exactly on the
  next record at `0xF286CB`. The whole neighbourhood is `record, its table,
  record, its table`: `0xF286A2` → `"PT1..PT8"`, `0xF286CB` → `"ON OFF"`,
  `0xF286E2` → `"OFFON "`.
* `0xF28724` is the last byte of the opcode-03 record at `0xF2871A`, and
  `0xF287C1` is inside the 16-bit word array at `0xF28725` that four opcode-03
  records at `0xF286F9`, `0xF28704`, `0xF2870F`, `0xF2871A` index with strides of
  16 bytes.
* `0xF29710` is one byte past the start of the opcode-03 record at `0xF2970F`;
  that record and the one at `0xF2971A` run to `0xF29725`, where their word array
  begins.

⚠ **What is NOT established:** why those four immediates are what they are. A
stale pointer left behind when the data was edited is the obvious reading and is
*not* asserted here. What is asserted is that the bytes at those four addresses
cannot be display-list records, that the interpreter's own out-of-range guard or
loop test would contain the damage, and that no constant shift in ±72 bytes makes
all of them frame.

## What merging costs

`scripts/analysis/prom_b_display_lists.py` merges overlapping call sites into
spans before walking. Where a good site and a bad one overlap, the merged span
fails and the good records go with it. That happens once: sites
`0xF286F9-0xF28725` (frames, 4 records) and `0xF28724-0xF28750` (does not) merge
into `0xF286F9-0xF28750`, which does not, so **four good records at `0xF286F9`
are still `.incbin`**. That, plus the un-merged walk seeing both members of
partially overlapping pairs, is the whole gap between 4,011 merged records and
4,097 un-merged.

## The records are also a RAM-variable index

Every interpreter-B record carries a 16-bit RAM address at `+2`, so the 494 of
them are a reverse index from a firmware variable to the screen that prints it.
`notes/prom_b_var_screens.py` builds it: 92 distinct variables in five
neighbourhoods, 55 distinct tables, and an eight-element array of 0x40-byte
records at `0x0076A0` found by nothing but the spacing of four displayed fields.
Write-up: `FINDINGS-prom_b-ui-variable-index.md`.

## Reproduce everything above

```
python3 notes/prom_b_dl_length_audit.py --edges      # the two-interpreter result
python3 notes/prom_b_dl_length_audit.py --records    # every record, both classes
python3 notes/prom_b_dl_operand_tables.py --exact    # the 13 proven gaps
python3 notes/gen_prom_b_dl_operand_tables.py        # their assembly
python3 notes/gen_prom_b_display_lists_v2.py --lo 0x00000 --hi 0x31800
```

The last one is the emitter that produced the record listings now in
`prom_b/wsa1_prom_b.s`; it renders A records with text identical to the committed
emitter's, so a diff against the old output is exactly the B records.

## UPDATE 2026-09-02 — the four "data the failing site points into" neighbourhoods are now source

Lane promB5 converted the six `.incbin` spans of prom_b it owned (1,115 bytes:
`0xF283A7`, `0xF2843D`, `0xF28725`, `0xF296D6`, `0xF2B2E3`, `0xF34CB8`), and three
of them are exactly the neighbourhoods this document dissected above. The
structure it emitted was derived independently — from the referring records'
pointers and the entry size each handler fixes — and it agrees with the reading
above in every detail:

* `0xF28725`, `0xF28735`, `0xF28745`, `0xF28755` and `0xF28791`, `0xF287A1`,
  `0xF287B1`, `0xF287C1` are eight arrays of **2 entries × 8 bytes**, the second
  four named by a further four opcode-03 records at `0xF28765`. `0xF287C1` — the
  failing A site's start — is the eighth array's first byte, so "inside data a
  neighbouring record points at" is now literally what the source says.
* `0xF2970F` and `0xF2971A` are two opcode-03 records running to `0xF29725`,
  where their 8 × 8-byte array begins and runs to `DL_F29765`. `0xF29710`, the
  failing B site's start, is the second byte of the first of them.
* `0xF283A7` and `0xF2843D` are not records at all: they are the 5×30 and 2×9
  **bitmaps** that 32 and 17 interpreter-A opcode-03 records draw.

⚠ One sentence in "What merging costs" above is now stale: the four good records
at `0xF286F9` are **no longer `.incbin`** — `notes/gen_prom_b_dl_shape1_gap_f286f9.py`
spliced them earlier. The cost merging *had* is described correctly; the
consequence has since been paid off.

Reproduce: `python3 notes/gen_promB5_spans.py --selftest`.
