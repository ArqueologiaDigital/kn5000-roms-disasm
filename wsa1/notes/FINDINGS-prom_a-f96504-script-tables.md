# prom_a 0xF96504-0xF96C65 (1,889 B): CONVERTED 2026-09-02, all of it

**Status: converted in full.** This was the largest `.incbin` left in prom_a and
the biggest single item of verbatim debt in the image. 374 bytes are code
(8 routines); 1,515 bytes are typed data (three tables and a byte-script area).

Converter: `notes/gen_prom_a_f96504_module.py`. It re-derives every boundary on
each run and refuses to emit if one moves.

    python3 notes/gen_prom_a_f96504_module.py --audit    # the structure + 11 checks
    python3 notes/gen_prom_a_f96504_module.py --splice   # write it into the .s

Gate after the splice: `cd wsa1 && make all && python3
scripts/analysis/assert_byte_identical.py` -> PASS, all four WSA1R images.

## Why this span was tractable now when earlier passes left it

Earlier rounds worked from `notes/reachability.py`, whose seed classes are CPU
vectors, prom_b directory slots and branches in decoded code. None of those
reaches 0xF96504: the routines here are only ever called **through a pointer
table that was itself inside the same `.incbin`**. The round-2 header above the
span in `prom_a/wsa1_prom_a.s` says so in as many words -- "3811 bytes that
nothing STRONGLY reaches stay `.incbin`".

What breaks the deadlock is that the *reader* was already converted, one screen
above the span, and it contains three literal addresses that land inside it.

## The reader, and what it fixes

`.LF964B9` (0xF964B9-0xF96503, converted in an earlier round):

    .LF964B9:  xor BC,BC                        ; BC = byte cursor into the table
    .LF964BB:  ld HL,BC
               mx_ld_rm MXL,ra_IX,ra_HL,r6      ; XIZ = *(XIX + BC)
               cp XIZ,0xffffffff / jr z, done   ; 0xFFFFFFFF terminates the table
               add XIZ,XIY                      ; XIZ = struct base + this offset
               inc 4,BC / ld HL,BC
               push XIX
               mx_ld_rm MXL,ra_IX,ra_HL,r4      ; XIX = *(XIX + BC)  <- the script
               inc 4,BC
    .LF964D8:  xor H,H / ld L,(XIX)             ; L = opcode byte
               cp L,0xff / jr z, .LF96500       ; 0xFF ends the script
               sla hl,0x02 / extz XHL
               add XHL,0x00f969a1               ; <-- HANDLER TABLE BASE
               ld XDE,(XHL)
               inc 1,XIX
               xor XHL,XHL / ld L,(XIX)         ; L = field offset byte
               add XHL,XIZ                      ; XHL = &struct.field
               ld A,(XHL)                       ; A = the field's current value
               inc 1,XIX
               pushw bc / call (xde) / popw bc  ; the handler may consume more
               jr .LF964D8

Three literals in already-converted code fix the three tables:

| literal | where | what it is |
|---|---|---|
| `0x00F969A1` | `add XHL,0x00f969a1` at 0xF964E6 | handler table base |
| `0x00F969DD` | `ld XIX,0x00f969dd` at 0xF96455 and 0xF96484 | table A |
| `0x00F96AA1` | `ld XIX,0x00f96aa1` at 0xF96476 | table B |

## The five parts

| range | bytes | kind |
|---|---|---|
| 0xF96504-0xF9667A | 374 | CODE -- 8 handler routines |
| 0xF9667A-0xF969A1 | 807 | DATA -- 18 byte-scripts, 259 records |
| 0xF969A1-0xF969DD | 60 | DATA -- 15 LE32 handler slots, 8 non-zero |
| 0xF969DD-0xF96AA1 | 196 | DATA -- table A: 24 pairs + terminator |
| 0xF96AA1-0xF96C65 | 452 | DATA -- table B: 56 pairs + terminator |

374 + 807 + 60 + 196 + 452 = 1,889.

### The code: a decode and a table agree without being told about each other

The handler table's 8 non-zero slots hold 0xF96504, 0xF96512, 0xF9651E,
0xF96527, 0xF96574, 0xF965C1, 0xF9660E and 0xF9650B. A linear decode from
0xF96504 produces exactly 8 routines, and their `ret`s end on exactly those 8
addresses, with the last one landing on 0xF9667A. The table is data and the
decode is code; neither was derived from the other, and they agree. That is the
strongest boundary evidence available in this file short of an external dump.

Every instruction went through `prom_a/roundtrip.py`, so each was re-assembled
and byte-compared. 9 bytes (`cb ff` / `cb fc` pairs) stay `.byte` with unidasm's
rendering in a comment: llvm-mc's tlcs900 backend has no spelling for that
shift-by-C form. They are 9 bytes of a 374-byte block, not a refusal of the
block.

The routines are read/modify/write helpers on a byte field: mask, invert-and-
mask, or-in, mask-shift-clamp (0x04/0x05), and search-a-value-list (0x06/0x07).
That reading is offered as orientation, not as a claim -- the emitted labels are
`sub_XXXXXX` plus the dispatch slot number, which is a fact about the table.

### The scripts: typed, not disassembled

Per-opcode record widths come from where each handler leaves XIX:

| opcode | width | shape |
|---|---|---|
| 0x01 0x02 0x03 0x08 | 3 | op, field, immediate |
| 0x04 0x05 | 6 | op, field, mask, 3 more |
| 0x06 | 4+n | op, field, mask, n, n values |
| 0x07 | 5+n | op, field, mask, n, n values, 1 more |
| 0xFF | 1 | end of script |

For 0x06 the tail is `xor D,D / extz XDE / add XIX,XDE / inc 1,XIX`, with E
holding the un-consumed remainder of the value list -- so whichever value
matched, XIX lands on the byte after the list. 0x07 does the same and then
reads one further byte.

**★ The check that could have failed.** Walking every script named by the two
tables, with those widths, TILES 0xF9667A-0xF969A1 exactly: 807 bytes, 18
scripts, 259 records, no unvisited byte, no byte claimed by two scripts, no
script running past 0xF969A1, and no opcode outside the 8 the handler table
populates (only 0x01, 0x04, 0x06, 0x07 and 0x08 actually occur). A wrong width
for any opcode, or a wrong start for the script area, desynchronises the walk
and leaves a gap or an overrun. `--audit` re-runs it.

The scripts are emitted as `.byte`, one line per record. They are **not**
disassembled, and the reason is the hazard this push keeps hitting: every
reference to them LOADS AN ADDRESS out of a table; nothing calls or jumps into
the area. Framing them as instructions would re-assemble to the same bytes and
pass the byte gate while being wrong.

### The two pair tables

Both hold (u32 struct offset, u32 script pointer) pairs and end in 0xFFFFFFFF.
Table A's terminator ends exactly where table B begins; table B's ends exactly
on 0xF96C65, the end of the `.incbin` -- a boundary this pass did not choose and
could not have adjusted. Every one of the 80 script pointers lands inside
0xF9667A-0xF969A1.

Table B's offsets march in 0x20 steps from 0x02C0 to 0x08C0 alternating between
two scripts, which is the shape of an array of same-sized records; that is an
observation, not a conversion decision.

## What is still not established

What any field means, what the struct at `XIY` is (callers pass 0x00007620 and
0x00603620), and why there are two tables rather than one. None of that is
needed to type the bytes, and none of it is claimed.
