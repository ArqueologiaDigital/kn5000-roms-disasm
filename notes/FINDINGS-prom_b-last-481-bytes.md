# prom_b's last 481 bytes: all sixteen spans are DATA, and all can be source

**Question asked:** the SX-WSA1R's `prom_b` is the one image of thirteen not at
zero verbatim debt — 481 bytes in 16 `.incbin` spans. Can those be described as
source as well, or are they actually data?

> ## ⚠ STATUS: the answer holds, the COUNT is moving
>
> This document was written when the residue was **16 spans / 481 bytes**. Lanes
> are now converting it, so **re-derive the count before quoting it**:
>
>     grep -ac '\.incbin' wsa1/prom_b/wsa1_prom_b.s
>
> **2026-09-02, after lane `res3xx`: 11 spans / 375 bytes.** That lane closed all
> five of its spans as typed data — which is the answer below, demonstrated
> rather than argued. Three further lanes are working the rest.
>
> Two specifics below are now superseded and are kept because the reasoning
> around them is still the point: `0xF286CC` and `0xF3B656` are converted, and
> the `0xF286CC` bullet under "sharp enough to hand to a lane" understated the
> error — see the correction at the end.

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
| `0xF0540B` | 58 | 31% | four 15-byte records, pointer field + incrementing counter |
| `0xF03F81` | 46 | 58% | text records — `AMPLITUDE`, `SOUND EDIT`, `ENV `, `AMP ` |
| `0xF05792` | 46 | 13% | 8-byte records, 6 of 8 columns constant, first byte stepping +0x20 |
| `0xF286CC` | 45 | 37% | two records, each naming the string right after it — `ON OFF`, `OFFON ` |
| `0xF02FFE` | 44 | 27% | pointer + LE16 coordinate quads |
| `0xF13D34` | 44 | 11% | glyph/bitmap — only **seven distinct byte values** in 44 bytes |
| `0xF3A443` | 30 | 23% | pointer + LE16 coordinate pairs |
| `0xF03ADE` | 21 | 0% | same 12-byte record family as `0xF03AF8` |
| `0xF34350` | 17 | 52% | pointer + the strings ` -1 -2` |
| `0xF04D14` | 15 | 40% | pointer + the string `LPF+` |
| `0xF05CEC` | 12 | 33% | 12 small values — a curve or coefficient row |
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
