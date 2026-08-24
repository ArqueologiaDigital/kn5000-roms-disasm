# The WSA1's UI is a display-list VM, and its text lives inside it

**Short version.** There is no string table. Every string the machine shows —
`SOUND EDIT`, `TONE LAYER`, `DSP EFFECT`, `CONTROLLER`, `AMPLITUDE`, `PITCH`,
`FILTER`, `MODELING`, `EFFECT SEND & OUTPUT`, `KIT PARAMETER` and ~4,000 other
records — is embedded in a byte-coded **display list**, executed by a small
interpreter at `0xF31A09` in prom_b.

**Converted in `prom_b/wsa1_prom_b.s`:**

| range | bytes | what |
|---|---:|---|
| `0xF31800-0xF32708` | 3,849 | the interpreter, its two handler tables, its quantiser, 29 value glyphs and 3 fixed bitmaps |
| 129 spans in `0xF01800-0xF3E15B` | 39,329 | the display lists themselves, as records |

**Reproduce:**
`python3 scripts/analysis/prom_b_display_lists.py --summary`

---

## The record format

```
+0   opcode   — bounds-checked against 0x24
+1   length   — of the WHOLE record, in bytes; the loop advances by it
+2   operands, and for the text opcodes a run of characters
```

## The interpreter

```
DisplayList_Run:                      ; 0xF31A09, reached through thunk T_F417F0
    while (XIY < XIX):
        op = (XIY)
        if op >= 0x24:  PrintHex32_XIY(XIY); break     ; hex-dumps the bad pointer
        call [0xF31D21 + op*4]                         ; handler, XIY = the record
        XIY += (XIY+1)                                 ; the length byte
```

Call sites pass both ends:

```
    ld  (0x2540), 0x00
    ld  XIY, 0x00F01800        ; list start
    ld  XIX, 0x00F01873        ; list end
    call 0xF417F0              ; -> DisplayList_Run
```

`T_F417F0` is the most-referenced slot in the whole thunk table (upper bound 392
references); `T_F417F4`, the second interpreter, is second (269).

## Four independent checks, all of which pass

1. **Framing.** Walking the length bytes from a call site's start address must
   land *exactly* on that call site's end address. It does for the large majority (⚠ the figure **243 of 244** quoted here until 2026-08-24
   is reproduced by no committed artefact: `prom_b_display_lists.py --summary` prints
   129 framed / 5 not framed over 134 merged spans, and un-merged distinct (start,end)
   pairs give 401/406. The conclusion survives; the number was not derived by the script
   that is cited for it.) It lands exactly for
   prom_b lists.
2. **Operand counts.** The handler table at `0xF31D21` has 36 entries — exactly
   the `0x24` bound. Each handler reads a fixed number of operand bytes. Every
   opcode whose handler implies a fixed record length has exactly that length
   byte in the great majority of records -- but **NOT without exception**.
   ⚠ CORRECTED 2026-08-24: an audit re-ran the check and found **341 of 4,011 walked
   records violate it**, across 7 opcodes (op02 x175, op03 x63, op05 x62, op09 x27,
   op0B x8, op0A x3, op04 x3). The sharpest class is 66 records where the handler reads
   PAST the declared length: handler 0xF31ABE reads (XIY+0x02)..(XIY+0x0B), 12 bytes,
   yet 63 op-03 and 3 op-04 records declare length 11. op 0x0B always declares 13
   against an implied 6. The record framing still walks correctly, so the DECODE stands;
   what does not stand is 'zero exceptions', and the committed script never implemented
   this check at all -- main() only runs walk().
3. **The opcode is the system-call number.** Handler `0xF31A3A` does
   `ld A,(XIY)` then `swi 7`. prom_a's SWI7 vector (`0xFFFF1C`) is `0x00F400A4`
   = thunk `T_F400A4` in this image → prom_a `0xF8E9A5`, which masks `A` with
   `0x3F`, scales by 4 and indexes a 64-entry table at prom_a `0xF8E9C6`.
   Entries `0x00-0x22` span 35 slots but slot **0x18 also points at the shared `ret` stub
   0xF8EAC6**, so there are **34 live services and the first dead slot is 0x18**, not
   0x23 (corrected 2026-08-24; `prom_a/wsa1_prom_a.s` had this right all along). Entries `0x23-0x3F` are all
   `0xF8EAC6`, and prom_a`[0xEAC6]` is a single `0x0E` = `ret`. So the service
   has 35 live functions `0x00-0x22`, and the display-list bound `0x24` is
   exactly one past the last of them.
4. **Sizes of the glyph data.** `DrawValueGlyph_24x24` masks a value to 7 bits,
   quantises it through the 128-entry table at `0xF31DED` (max value `0x1C`), and
   indexes the pointer table at `0xF31E6D`. Max `0x1C` ⇒ 29 entries ⇒ 116 bytes
   ⇒ `0xF31E6D + 116 = 0xF31EE1`, exactly where the first bitmap starts; and
   29 bitmaps × 72 bytes ends at `0xF32709`, exactly where the block ends.

## Handlers and the record layouts they imply

| handler | opcodes | record layout |
|---|---|---|
| `0xF31A3A` | 06 07 08 16 18 19 1A 1D 1E 1F 20 21 | `+2` word → `IX`; `+4..` characters, `BC = len-4` |
| `0xF31A52` | 17 1C | `+2`,`+4` words → `(0x2530)`,`(0x2532)`; `+6..` characters, `BC = len-6` |
| `0xF31A75` | 00 01 02 05 09 0A 11 12 13 15 1B 22 | four words `+2..+9` → `(0x2530..0x2536)`; len 10 |
| `0xF31A9F` | 0E | `+2`→`IY`, `+4`→`BC`, `+6`→`HL`; len 8 |
| `0xF31AAC` | 0B | `+2`,`+4` → `(0x2530)`,`(0x2532)`; len 6 |
| `0xF31ABE` | 03 04 | `+2` 32-bit pointer → `XIY`, `+6`→`IX`, `+8`→`BC`, `+0x0A`→`HL`; len 12 |
| `0xF31ACE` | 23 | `+2` glyph index, `+3` position; len 5; issues service 3 itself |
| `0xF31AEB` | 0C 0D 0F 10 14 | bare `ret` — record skipped, only the length matters |

## System-call functions identified

| fn | what | evidence |
|---|---|---|
| `0x03` | draw bitmap: `IX` = position, `BC` = width in **bytes**, `HL` = height in rows, `XIY` = bitmap | three call sites where `BC × HL` is *exactly* the size of the contiguous data at `XIY` (1×16 at `0xF318EE`, 1×16 at `0xF318FE`, 5×15 = 75 at `0xF31952`) and the blocks abut with no slack |
| `0x06` | draw characters: `XIY` = character table, `HL` = index, `BC` = count | `PrintHex32_XIY` passes the literal ASCII table `"0123456789ABCDEF"` at `0xF319E9` with `HL` = a nibble and `BC` = 1 |
| `0x05` | consumes the four words `(0x2530)`,`(0x2532)`,`(0x2534)`,`(0x2536)` set immediately before | callers only; a rectangle is the obvious reading and is **not** asserted |
| `0x0C`, `0x10` | exist, take `C` (0 or 7 seen) | `sub_F31852`, `sub_F31863` |

## The character set

Payload bytes `>= 0x20` are ASCII. Bytes `< 0x20` also appear inside payloads —
`0x10`, `0x11`, `0x12` are common, e.g. the record at `0xF01810` is
`0x10` followed by `" WRITE"`. They are almost certainly custom glyphs in the
same font, but that is **not established**; only that the text handler passes
them to the character service alongside the ASCII.

Of 1,759 text payloads in the framing-OK spans, 1,133 (64%) are entirely
printable ASCII; the rest are these short control/glyph codes.

## Worked example — the SOUND EDIT screen

`0xF01800-0xF01872` and `0xF01873-0xF01919`, run back to back by the code at
`0xF5BF27`:

```
1C 10  6E 00 05 00  "SOUND EDIT"       op 1C, 16 bytes  (4+6+10)
06 0B  A0 05  10    " WRITE"           op 06, 11 bytes  (2+2+1+6)
06 05  08 0C  10                       op 06,  5 bytes
20 08  C2 05  "COPY"                   op 20,  8 bytes
09 0A  0C 00 1F 00 3C 00 32 00         op 09, 10 bytes  (four words)
23 05  10 32 00                        op 23,  5 bytes  (glyph 0x10)
06 0E  E6 0C  "TONE LAYER"             op 06, 14 bytes
06 0E  76 18  "DSP EFFECT"
06 09  67 18  "PITCH"
06 0B  96 11  "DIGITAL"
06 0A  A3 13  "EFFECT"
06 0A  7F 1E  "FILTER"
06 0E  8E 1E  "CONTROLLER"
06 0D  77 12  "AMPLITUDE"
06 0C  D7 0C  "MODELING"
```

## The second interpreter — the same VM, bound to live variables

`DisplayListB_Run` at `0xF31AF0` (thunk `T_F417F4`) has the same loop but bound
`0x0F` and handler table `0xF31DB1` — again exactly 15 entries for a `0x0F`
bound, with opcodes `0x0C-0x0E` mapping to the bare `ret` at `0xF31D20`.

**What makes it different:** every one of its handlers opens with
`calr 0xF31CC5` (`DisplayListB_ExtractField`), which is six instructions long:

```
IX = (XIY+2)          ; a 16-bit address carried IN THE RECORD
A  = (IX)             ; read that variable
A &= (XIY+4)          ; mask
C  = (XIY+5) & 7
if C: A >>= C         ; shift
```

So interpreter A draws what the record says; **interpreter B draws what a
variable says**. Its lists are the live parameter readouts; A's are the static
furniture.

Record layout, each field named by the instruction that consumes it:

| offset | field | instruction |
|---|---|---|
| `+0` | opcode, bound `0x0F` | `cp L,0x0f` |
| `+1` | length of the record | the loop's `ld A,(XIY+1)` |
| `+2` | 16-bit address of the source variable | `ld IX,(XIY+2)` / `ld A,(IX)` |
| `+4` | AND mask, one byte | `ld W,(XIY+4)` / `and A,W` |
| `+5` | right-shift count, low 3 bits | `and C,0x07` / `srl A,C` |
| `+6` | the `swi 7` function number | `ld A,(XIY+6)` — in 8 of the handlers. Interpreter A puts this at `+0`. |
| `+7` | 32-bit pointer: a bitmap, or the base of an array the extracted value indexes | `ld XIY,(XIY+7)` |
| `+11` | → `BC` | `ld BC,(XIY+0x0b)` |
| `+13` | → `IX`, or → `(0x2530)` | |
| `+15` | → `(0x2532)` | |

Two handlers show the array case outright: `0xF31B57` does `sla 3,HL` and adds
the result to the `+7` pointer, then reads four 16-bit words from it into
`(0x2530..0x2536)` — an array of 8-byte records indexed by the extracted field.
`0xF31B86` does `mul HL,6` on the same pointer — an array of 6-byte records.

⚠ **Not established:** what the individual opcodes mean, which variables the
`+2` addresses are, and whether every record uses every field. Interpreter B's
lists are therefore still `.incbin`; this layout is what the next pass should
test them against.

## What was left alone, and why

Five prom_b spans fail the framing check and stay `.incbin`:
`0xF286B8-0xF286E4`, `0xF286F9-0xF28750`, `0xF287C1-0xF287CB`,
`0xF29710-0xF2972E`, `0xF3B3DA-0xF3B6D3`. Four of the five are entered only
through `T_F417F4`, i.e. they belong to the second interpreter. `0xF287C1` is
ten bytes reading `2F 00 84 00 99 00 8F 00 36 00` — five 16-bit words, out of
range for either opcode space; the call site that names it may be a false
positive of the byte-level scan.

The display lists in **prom_a** (54 merged spans, 5,140 bytes, from `0xFC40B4` to `0xFF17E2`) are
in another agent's image and were not touched. They use the same interpreter and
the same format.
