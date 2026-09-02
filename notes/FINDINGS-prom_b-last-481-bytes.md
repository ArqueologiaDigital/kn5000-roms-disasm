# prom_b's last 481 bytes: all sixteen spans are DATA, and all can be source

**Question asked:** the SX-WSA1R's `prom_b` is the one image of thirteen not at
zero verbatim debt — 481 bytes in 16 `.incbin` spans. Can those be described as
source as well, or are they actually data?

> ## ⚠ STATUS: the answer is now DEMONSTRATED — 481 B → 88 B
>
> This document was written when the residue was **16 spans / 481 bytes**. Three
> lanes have since closed 14 of the 16, **entirely as typed data, with no
> instruction emitted anywhere** — which is the answer below, proved by doing it
> rather than argued.
>
> **2026-09-02: 2 spans / 88 bytes remain** — `0xF02FFE` (+44) and `0xF13D34`
> (+44). Re-derive before quoting:
>
>     grep -ac '\.incbin' wsa1/prom_b/wsa1_prom_b.s
>
> Lane `res03a` also typed 359 B of adjacent walk-extent `.byte` in the same
> pass. Specifics in this file about spans now closed are superseded; the
> reasoning around them is why they are kept, and the corrections are appended
> at the end.

**Answer: they are data — every one of the sixteen — and being data is exactly
what makes them writable as source.** Nothing here is undecoded program text.
The remaining work is a *typing* problem, not a *decoding* one.

Evidence script: `wsa1/notes/prom_b_residue_481.py` (`--selftest` asserts every
claim below; PASS as of 2026-09-02).

    python3 wsa1/notes/prom_b_residue_481.py --selftest

## The spans

| CPU address | bytes | ASCII | what the bytes are |
|---|---:|---:|---|
| `0xF03AF8` | 77 | 11% | 12-byte display-list records + a 5-entry LE32 pointer table, stride 0x18, pointing into itself |
| `0xF0540B` | 58 | 31% | ~~four 15-byte records~~ **CONVERTED** — the tail of four interpreter-B op-02 records at 0xF05407 (their starts are listed by the pointer array at 0xF0545A) plus the 2-entry table `+` `-` |
| `0xF03F81` | 46 | 58% | **CONVERTED** — the middle of one 18-record interpreter-A display list, 0xF03F77-0xF0402D, both ends named by `sub_F5C727` |
| `0xF05792` | 46 | 13% | **CONVERTED** (weakest) — a 5x8 rectangle array at 0xF05798 and the op-1B record before it; interior splits rest on tiling, not on a pointer |
| `0xF286CC` | 45 | 37% | two records, each naming the string right after it — `ON OFF`, `OFFON ` |
| `0xF02FFE` | 44 | 27% | pointer + LE16 coordinate quads |
| `0xF13D34` | 44 | 11% | glyph/bitmap — only **seven distinct byte values** in 44 bytes |
| `0xF3A443` | 30 | 23% | pointer + LE16 coordinate pairs |
| `0xF03ADE` | 21 | 0% | same 12-byte record family as `0xF03AF8` |
| `0xF34350` | 17 | 52% | pointer + the strings ` -1 -2` |
| `0xF04D14` | 15 | 40% | **CONVERTED** — the tail of the op-02 record at 0xF04D10 plus the head of the 6x6 filter-name table its +0x07 names |
| `0xF05CEC` | 12 | 33% | **CONVERTED** — not a curve: the second byte-column of the 2x12 bitmap at 0xF05CE0, whose size three op-03 records state |
| `0xF32A00` | 9 | 44% | pointer `0xF32A6F` + two fields |
| `0xF03A26` | 7 | 14% | mid-record: carries the tail of pointer `0x00F0191A` |
| `0xF03BE6` | 5 | 0% | mid-record in the same family; its neighbour holds `3rd` |
| `0xF3B656` | 5 | 0% | mid-record; `0xF3B7E8` sits just past it |

## Why "data" is a measurement here, not an impression

**22 embedded LE32 pointers into prom_b's own address range, across 481 bytes,
in 9 of the 16 spans.**

⚠ That number is worthless without a null, so the script computes one:
uniform-random bytes of the same lengths yield **0.003** in-range pointers per
span. prom_b occupies 1/512 of the 32-bit space, so a random 4-byte window
lands inside it about 0.2% of the time. Twenty-two is not chance.

And the pointers are not scattered — they land exactly where a record's operand
belongs:

```
0xF286CC  +6  -> 0xF286DC   (+16, immediately past the record)
0xF3A443  +2  -> 0xF3A449   (+6)
0xF34350  +3  -> 0xF3435B   (+11)
0xF04D14  +3  -> 0xF04D1F   (+11)
0xF02FFE  +0  -> 0xF03002   (+4)
0xF0540B  +3  -> 0xF05443   (+56, the same target from all four records)
```

The `0xF03Axx` family points *away*, repeatedly, at `0xF019AA` and `0xF0191A` —
the 12×16 icon grid that lane `promB2` identified **from the other side**, where
`0x00F019AA` appears as a 32-bit word ten times across the display-list region.
Two independent lanes, working different addresses, met at the same object.

★ The pointer-free spans are structured too, so the verdict does not rest on
pointers alone: `0xF05792` is stride-8 with 6 of 8 columns constant;
`0xF13D34` uses only `{00, 1C, 1F, 70, 80, F0, FF}` — pixel patterns, not
opcodes; `0xF03F81` is 58% printable and contains screen labels.

## Why they were left behind — and it is not what the refusal notes say

Each span carries a refusal reason of the form *"decodes as neither
interpreter's records"*. True, and beside the point. **The spans are cut
mid-record.** They are the part of an object that a reachability walk could not
account for, because a pointer gives an object's first byte and never its last.

`0xF0540B` shows it cleanly, and the script asserts it:

* record markers `10 04` at span offsets **0, 15, 30, 45** — stride 15;
* 58 bytes = 15×3 + 13, so the **fourth record is truncated by the span's end**;
* the six bytes immediately *before* the span are `f0 00 02 0f ab 27` — the same
  `02 0f XX 27` trailer the in-span records carry, with `ab` continuing into
  `ac`, `ad`, `ae` inside the span. An incrementing counter running straight
  through both edges of the `.incbin`.

So the span boundary is an artefact of the earlier framing, not a structural
edge. That is the same mechanism this push documented image-wide, and it is why
`prom_b` went 10,664 B → 481 B once lanes started sizing objects from the
*handler* that consumes a pointer rather than from the walk that found it.

## So: can they be source?

**Yes, and the barrier is per-span evidence, not capability.** Each is a small
typed-data conversion: `.long` for the pointer fields, `.short` for the
coordinate pairs, `.ascii` for the labels, `.byte` for the glyph rows — with the
record shape read off the code that *reads* the region.

⚠ **What must not happen is typing them from the strides above.** A stride
recovered from the bytes alone, on a span known to start mid-record, is the
"wrong start frames fake records" hazard with extra steps — and the byte gate
cannot object, because any framing of the right bytes reproduces the ROM. The
strides in this document are evidence that structure EXISTS; they are not a
layout to emit.

Three spans are already sharp enough to hand to a lane:

* **`0xF286CC` (45 B)** — lane `promB5` recorded that `Data_F28522` is declared
  one byte too long; shrinking it by one makes the gap tile exactly as
  record(17) + table(6) + record(17) + table(6) = 46 B. The two embedded
  pointers at +6 and +29 corroborate that split independently.
* **`0xF0540B` (58 B)** — the 15-byte stride and the counter are established
  above; what is needed is the reader, to name the fields.
* **`0xF3B656` (5 B)** — lane `promB6` left a precise open question: as op 0x00
  length 11 the record ends at `0xF3B65C`, but the next record demonstrably
  starts at `0xF3B65B`. Either op 0x00 does not carry its length at +1 in this
  interpreter, or `DL_F3B65B` is off by one. That is a one-answer question.

## The honest headline

`prom_b` is **99.9% source**, and the remaining 0.1% is not a hole in our
understanding of the program. It is sixteen small pieces of display-list data
whose record boundaries were cut in the wrong places by a tool that has since
been superseded. Calling the image "not fully disassembled" is accurate about
the `.incbin` count and misleading about what is unknown.

---

## ★ What the conversions established (appended 2026-09-02)

### ADVANCE and EXTENT are different numbers

Lane `promB6` left a precise open question on `0xF3B656`: `Data_F3B651` starts
`00 0B`, so as op 0x00 with length 11 the record ends at `0xF3B65C` — but the
next record demonstrably starts at `0xF3B65B`. Either op 0x00 does not carry its
length at `+1`, or `DL_F3B65B` is off by one. It refused to guess, correctly.

**Neither branch was right.** Op 0x00 *does* carry its advance at `+1` — the
interpreter reads `+1` for every opcode without inspecting the opcode
(`ld A,(XIY+0x01)` at `0xF31B15`, then `add XIY,XWA`). And `DL_B65B` is *not*
off by one — prom_b `0xF7E79E` passes `0xF3B65B` as XIX, the list's exclusive
end.

The resolution is that **a record's ADVANCE and its EXTENT are different
quantities**. Handler `0xF31BA1`'s highest read is `+9`, so the record *occupies*
10 bytes; its advance byte says 11, which lands XIY past XIX so the list
terminates. The machine draws the record and stops. It is the only
over-declaring record in the image — 83 other interpreter-B op-00 records
declare 10.

⚠ **Generalise this before framing any record by its length byte.** A length
field that disagrees with a handler's reads is not necessarily a misframe; it
may be a deliberate list terminator. The handler's highest offset read is the
extent; the byte at `+1` is only the step.

### The `0xF286CC` lead was right in direction, wrong by 41 bytes

Lane `promB5` recorded that `Data_F28522` was declared **one byte** too long. It
was **42** bytes too long: promB5 measured to the `.incbin` edge, while the
record that *names* the table measures to `0xF286A1` — it declares width 3 and
mask `0x7F`, so 128 × 3 = 384 bytes. The two embedded pointers at `+6` and `+29`
land exactly where that tiling predicts.

★ The lesson is the one this file already argues: **measure an object from the
thing that names it, never from the `.incbin` boundary**, which was cut by a
superseded walk and carries no structural information at all.

### `0xF039ED-0xF03C94` is eight instances of one object

Lane `res03a` closed all four `0xF03Axx` spans and found they are not four
things but part of one repeated structure:

```
<list 1>...<list N><selector table of N+2 LE32 entries>
table[0] == table[1] == list 1's first byte      (entry 0 is padding)
table[i] == list i's first byte                  (i = 1..N)
table[N+1] == the table's OWN address            (one past the last list)
```

★ **What fixes it is code outside every span** — a `djnz` loop at `0xF5C3E5`
and six sibling sites doing `ld XIZ,<table>` / `ld XIY,(XIZ+BC)` / `add BC,4`.
`djnz` counts `C` down from 4 (or 2) to 1, so entries 1..N+1 are read and
**entry 0 never is** — which is why entry 0 is duplicated, and why the C=2
blocks carry four entries where the C=4 blocks carry six. The layout is not
inferred from the bytes; it is read off the loop that walks it.

⚠ And it corrects this document: the "stride 0x18 LE32 run" described above **is
that selector table**, its stride being the list length. Two tables,
`0xF03AB5` and `0xF03B2D`, have **no reader anywhere in four images** — their
framing rests on the chain alone, and the lane's check prints them as NOTED
rather than OK so the entry count is never claimed as verified.

### ⚠ And this file's own script passed a stale selftest

`wsa1/notes/prom_b_residue_481.py` went on printing *"481 B in 16 spans"* and
**passing `--selftest`** after five of those spans had been converted. It read
only the ROM, so nothing it asserted could notice the tree moving underneath it.

It now reads the tree too, and refuses to pass if a span it calls closed still
carries an `.incbin` — or the reverse. The guard was shown to fail in both
directions before being trusted. It also died with `FileNotFoundError` when run
from the repo root instead of `wsa1/`; paths are now anchored to the file's own
location, because the same cwd assumption in a script that reads the tree would
silently examine the wrong tree and report a confident wrong answer.

### The five sharp spans were sharp because a CALL SITE named them (lane res05x)

This document said `0xF0540B` needed "the reader, to name the fields". It did,
and so did three of its four neighbours — and the reader was easier to find than
expected, because the display-list interpreters are entered by immediate:

    ld XIY,<start> ; ld XIX,<end> ; call 0xF417F0   (interpreter A)
    ld XIY,<start> ; ld XIX,<end> ; call 0xF417F4   (interpreter B)

so a list's first byte and its **exclusive end** are two 32-bit immediates
sitting in code this tree already decodes. `sub_F5C727` alone settles
`0xF03F81` outright: it loads `0x00F03F77` as the start and, on a branch,
`0x00F0402E` *or* `0x00F03FF3` as the end — and the op/len chain from
`0xF03F77` lands on **both**. Grepping the converted disassembly for
`ld XI[XY],0x00f0…` is the cheapest instrument this residue work has, and it
should be the first thing a later lane tries on `0xF02FFE`+44 and `0xF13D34`+44,
the two spans that remain.

Two spans were fixed by a pointer instead of a call site, and one by neither:

* `0xF0540B` — the four record starts are written down 79 bytes later, in the
  pointer array at `0xF0545A`. The 15-byte stride this document measured off
  the bytes was right, but it did not need to be guessed at all.
* `0xF05CEC` — **the "curve or coefficient row" guess in the table above was
  wrong.** It is the second byte-column of a 24-byte bitmap, and three op-03
  records state its width (2 bytes) and height (12 rows) explicitly. A guess
  from 12 small values, on a span cut in the wrong place, was exactly the
  hazard this document warns about — and it was the "weakest of the five" only
  until someone asked who points at `0xF05CE0`. It turned out to be the
  best-anchored of them all.
* `0xF05792` — nothing in any of the four ROMs points at its interior. Its ends
  are code; its three interior splits rest on the tiling closing with no slack,
  plus the `[0] == [1]` idiom shared by all three externally-sized rectangle
  arrays in the image. The competing 6-entry framing is recorded and rejected
  in place rather than left unsaid.

★ **A span's difficulty is not its size or its printable fraction.** Of these
five, the 12-byte one had the strongest external anchor and the 46-byte one with
an obvious stride had the weakest. Rank residue spans by *who names them*, never
by what they look like.

Evidence: `wsa1/notes/prom_b_res05x_spans.py --selftest`, and
`wsa1/notes/prom_b_res05x_gate_perturbation.py` for the gate's ability to see
the result. This lane removed 177 B; with lanes `res3xx` and `res03a` merged
alongside it, prom_b's verbatim residue is **88 B in 2 spans**, from the 481 B
in 16 this document was written about.

### ★ The cheapest instrument in this whole effort: the lists are entered BY IMMEDIATE

Lane `res05x` found the general key, and it is embarrassingly simple. A display
list is entered as

    ld XIY,<start> ; ld XIX,<end> ; call 0xF417F0   (interpreter A)
                                   call 0xF417F4   (interpreter B)

so **a list's first byte and its EXCLUSIVE end are two 32-bit constants sitting
in code this tree already disassembles.** They are not inferred from the data at
all:

    grep -an 'ld XI[XY],0x00f0' <converted sources>

Four of that lane's five spans were fixed from outside the bytes that way, and
`0xF0540B`'s four record starts turned out to be **written down 79 bytes later**
in the pointer array at `0xF0545A`. Anyone continuing this work should reach for
this before anything else.

### ⚠ My own span triage was wrong about which was weakest

This document's brief called `0xF05CEC` *"twelve small values, plausibly a curve
row — the weakest of the five, and a refusal there is fine."* It is the
**best-anchored of the five**: three op-03 records each carry
`.long 0x00F05CE0` with width 2 and height 12, so 24 bytes ending exactly at
`Data_F05CF8`.

★ The lesson is the one this file argues throughout, turned on its author: a
span's *appearance* — twelve small values — predicted nothing. What settled it
was finding the records that name it. I ranked the spans by how they looked and
got the ranking backwards.

The span that actually resisted was `0xF05792`, and it is documented in place:
no 32-bit word anywhere in the four ROMs holds its candidate interior splits, so
its ends are code but its three interior boundaries rest on a zero-slack tiling
plus an idiom shared by the image's other externally-sized rectangle arrays. The
competing framing is **recorded and rejected in the source**, not dropped.

### ⚠ A hazard that bit two lanes: `open(path, "w", encoding="latin-1")`

It truncates `wsa1_prom_b.s` to **zero bytes** the instant a character will not
encode — a stray `⚠` in a comment did it, twice, recovered from git both times.
These sources are latin-1 files *carrying UTF-8 text*. Encode the whole file
first, then `os.replace`. And one lane's perturbation checker compared the
gate's message against a **CPU address** while the gate speaks in **file
offsets**, so it reported "does not name it" for four of five perturbations that
had in fact been named: **a checker's own units are part of what has to be
checked.**
