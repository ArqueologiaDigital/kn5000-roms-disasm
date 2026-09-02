# prom_b's small `.incbin` spans -- the long tail, classified and adjudicated

Lane promB6, 2026-09-02.  Target: every `.incbin` in `prom_b/wsa1_prom_b.s` of
**128 bytes or less**.  Enumerated from the file itself, not from a handed-down
list: **55 spans, 1,362 bytes** (the next size up is 143 B, which belongs to
another lane).

## The question this lane actually asked

Not "how do I decode 30 bytes".  A one- or two-byte `.incbin` between two
converted regions is almost never a mystery instruction.  It is far more often
an **artefact of how the surrounding conversion was framed**.  So the first step
was to classify all 55 spans by what sits immediately before and after them,
before converting anything.

Tool: `scripts/analysis/prom_b_small_span_classify.py`.

    PREV kinds: {'LABEL': 1, 'AFTER-TERM': 10, 'AFTER-DATA': 44}
    NEXT kinds: {'LABEL': 48, 'AFTER-DATA': 7}
    byte shape: {'mixed': 48, 'FILL-00': 6, 'FILL-0E': 1}
    bytes by PREV kind: {'LABEL': 26, 'AFTER-TERM': 115, 'AFTER-DATA': 1221}

**44 of the 55 spans follow a data directive and 48 are followed by a label.**
That single line is the finding: these are not gaps *between* objects, they are
the **REST OF THE OBJECT ABOVE THEM**.  Coverage round 1 sized each object with
a reachability walk, and the walk's extent is not the object's extent -- so it
cut fixed-stride arrays in the middle of an entry, and the leftover became an
`.incbin` that looks like an independent mystery and is not one.

The remaining 11: 10 sit after a flow terminator (`ret`), and one is the very
first object in the image.

## The classification table, as it stood before this lane touched the file

Reproduce with `git show 3f0009c0:wsa1/prom_b/wsa1_prom_b.s` into a tree and
`python3 scripts/analysis/prom_b_small_span_classify.py`.

```
prom_b .incbin spans: 71 total, 10664 bytes
selected (<= 128 bytes): 55 spans, 1362 bytes

LINE   ROMADDR   LEN   PREV          NEXT          FILL?       BYTES
--------------------------------------------------------------------
197    F00000    26    LABEL         LABEL                     1B 14 00 F0 1B 14 00 F0 1B 14 00 F0 1B 15 00 F0 ..
224    F0003A    2     AFTER-TERM    LABEL         FILL-00     00 00
275    F00097    2     AFTER-TERM    LABEL         FILL-00     00 00
319    F000E3    2     AFTER-TERM    LABEL         FILL-00     00 00
335    F000E6    34    AFTER-DATA    LABEL                     01 F0 00 8D 02 F0 00 C9 02 F0 00 EB 02 F0 00 B9 ..
384    F0017B    2     AFTER-TERM    LABEL         FILL-00     00 00
414    F001AE    2     AFTER-TERM    LABEL         FILL-00     00 00
431    F001B4    1     AFTER-TERM    LABEL         FILL-0E     0E
454    F001C7    2     AFTER-TERM    LABEL         FILL-00     00 00
530    F00280    19    AFTER-TERM    LABEL                     F0 95 CB 6E 08 F0 95 CA 66 03 08 95 0C 08 94 0C ..
549    F0029D    44    AFTER-TERM    LABEL                     F0 95 C8 6E 0E F0 95 CA 6E 09 08 95 01 1E 47 00 ..
566    F002CD    39    AFTER-TERM    LABEL                     00 00 08 94 01 1E 2C 00 F0 95 C8 6E 0E F0 95 CA ..
3443   F02FFE    44    AFTER-DATA    LABEL                     02 30 F0 00 08 00 49 00 22 00 56 00 08 00 49 00 ..
4286   F03620    19    AFTER-DATA    LABEL                     35 F0 00 E0 35 F0 00 EB 35 F0 00 F6 35 F0 00 01 ..
4828   F03A26    7     AFTER-DATA    DATA                      00 5A 0C 03 00 0A 00
4881   F03ADE    21    AFTER-DATA    LABEL                     00 D4 0C 03 00 0A 00 03 0C AA 19 F0 00 D2 11 02 ..
4900   F03AF8    77    AFTER-DATA    DATA                      11 03 00 0A 00 03 0C AA 19 F0 00 D2 16 02 00 0C ..
4957   F03BE6    5     AFTER-DATA    DATA                      16 02 00 0C 00
5000   F03C12    11    AFTER-DATA    DATA                      3B F0 00 F2 3B F0 00 05 3C F0 00
5483   F03F81    46    AFTER-DATA    LABEL                     00 41 4D 50 4C 49 54 55 44 45 17 10 06 00 07 00 ..
7178   F04D14    15    AFTER-DATA    LABEL                     07 00 20 1F 4D F0 00 06 00 08 18 4C 50 46 2B
7364   F04E33    15    AFTER-DATA    LABEL                     4D F0 00 0A 4E F0 00 14 4E F0 00 23 4E F0 00
7606   F04F57    27    AFTER-DATA    LABEL                     4E F0 00 E1 4E F0 00 EB 4E F0 00 F6 4E F0 00 00 ..
7741   F05026    11    AFTER-DATA    LABEL                     4F F0 00 DC 4F F0 00 E7 4F F0 00
7927   F05102    11    AFTER-DATA    LABEL                     50 F0 00 DD 50 F0 00 E7 50 F0 00
8207   F0534B    19    AFTER-DATA    LABEL                     00 50 00 B5 00 93 00 F9 00 A0 00 B5 00 BB 00 F9 ..
8253   F0537F    55    AFTER-DATA    LABEL                     51 F0 00 E7 51 F0 00 F2 51 F0 00 FD 51 F0 00 0C ..
8339   F0540B    58    AFTER-DATA    LABEL                     10 04 20 43 54 F0 00 01 00 32 0A 02 0F AC 27 10 ..
8357   F05446    19    AFTER-DATA    LABEL                     53 F0 00 D9 53 F0 00 CF 53 F0 00 E3 53 F0 00 B6 ..
8374   F0545A    15    AFTER-DATA    LABEL                     54 F0 00 16 54 F0 00 25 54 F0 00 34 54 F0 00
8466   F054EA    3     AFTER-DATA    LABEL                     54 F0 00
8732   F05792    46    AFTER-DATA    LABEL                     4D 00 00 01 C9 00 0E 00 4D 00 00 01 69 00 0E 00 ..
9144   F05CEC    12    AFTER-DATA    LABEL                     80 60 30 50 88 0F 08 08 10 10 60 80
19906  F0D9A4    62    AFTER-DATA    LABEL                     03 0B 20 27 07 00 05 AF D9 F0 00 0C 00 1E 00 E8 ..
30895  F13D34    44    AFTER-DATA    DATA                      70 F0 70 00 00 00 00 00 1C 70 80 00 1C 1F 1C 00 ..
45675  F286CC    45    AFTER-DATA    LABEL                     11 44 26 20 05 17 DC 86 F2 00 03 00 FA 00 E2 00 ..
45804  F28877    31    AFTER-DATA    LABEL                     00 B2 00 E5 00 BA 00 EB 00 B2 00 F3 00 BA 00 F9 ..
45845  F288BE    19    AFTER-DATA    LABEL                     00 A6 00 FE 00 9E 00 06 01 A6 00 0C 01 9E 00 14 ..
57672  F32A00    9     AFTER-DATA    DATA                      20 6F 2A F3 00 07 00 4F 0D
57726  F32A37    23    AFTER-DATA    LABEL                     29 F3 00 FA 29 F3 00 FA 29 F3 00 09 2A F3 00 18 ..
57857  F32B27    11    AFTER-DATA    LABEL                     2A F3 00 F5 2A F3 00 04 2B F3 00
57897  F32B41    35    AFTER-DATA    LABEL                     00 67 00 08 00 49 00 FA 00 67 00 08 00 68 00 FA ..
58057  F32C0F    22    AFTER-DATA    LABEL                     2B F3 00 DB 2B F3 00 E6 2B F3 00 F1 2B F3 00 F1 ..
58725  F33401    27    AFTER-DATA    LABEL                     00 A0 00 FF 00 97 00 09 01 A0 00 0F 01 97 00 19 ..
59437  F338BE    11    AFTER-DATA    LABEL                     38 F3 00 8F 38 F3 00 9A 38 F3 00
59706  F33A5E    19    AFTER-DATA    LABEL                     00 94 00 3D 00 96 00 FC 00 A4 00 3D 00 A6 00 FC ..
59920  F33BB5    35    AFTER-DATA    LABEL                     3A F3 00 E3 3A F3 00 EF 3A F3 00 FC 3A F3 00 09 ..
60785  F34350    17    AFTER-DATA    LABEL                     FF 00 07 5B 43 F3 00 03 00 3E 05 20 2D 31 20 2D ..
62117  F34C9B    7     AFTER-DATA    DATA                      08 20 17 28 00 4B 00
62530  F3503C    31    AFTER-DATA    LABEL                     00 42 00 94 00 5E 00 0E 00 68 00 E3 00 84 00 0E ..
66888  F396E7    70    AFTER-DATA    LABEL                     00 05 ED 96 F3 00 38 00 3E 00 17 01 4C 00 38 00 ..
68080  F3A0C6    11    AFTER-DATA    LABEL                     1E FF 1E 04 1F 09 1F 0E 1F 13 1F
68489  F3A443    30    AFTER-DATA    LABEL                     00 1B 49 A4 F3 00 13 00 21 00 EF 00 37 00 13 00 ..
70671  F3B656    5     AFTER-DATA    LABEL                     00 06 C4 00 02
72274  F3C47E    87    AFTER-DATA    LABEL                     00 83 00 00 01 8E 00 38 00 93 00 40 00 9E 00 48 ..

PREV kinds: {'LABEL': 1, 'AFTER-TERM': 10, 'AFTER-DATA': 44}
NEXT kinds: {'LABEL': 48, 'AFTER-DATA': 7}
byte shape: {'mixed': 48, 'FILL-00': 6, 'FILL-0E': 1}
bytes by PREV kind: {'LABEL': 26, 'AFTER-TERM': 115, 'AFTER-DATA': 1221}
```

## What was converted, and on what evidence

`scripts/analysis/prom_b_small_span_convert.py` holds one verdict per span with
its reason and its check.  `--check` is 95 assertions and must print 0 failures.

| kind | spans | bytes | the evidence |
|---|---:|---:|---|
| `PTRTAB4` | 16 | 322 | the enclosing object is an array of 4-byte entries `lo mid hi 00` whose value addresses this image; every entry from the array base through the span end satisfies it |
| `SHORTARR8` | 8 | 268 | a display-list record elsewhere in the source declares the array's base with `-> XIX: array of 8-byte entries`, and the span ends on an 8-byte boundary from it |
| `CODE` | 4 | 128 | the linear decode consumes the span exactly, and the pointer array at 0xF000E5 lands on instruction boundaries inside it |
| `DLMIX` | 1 | 62 | a unique record/array decomposition (see below) |
| `TRAILER` | 7 | 13 | the 1-3 byte gap between a routine's `ret` and the next object |
| `SHORTPROG` | 1 | 11 | a 16-bit table in strict +5 progression across the cut |
| `DLTAIL` | 1 | 7 | one interpreter record whose leading byte the previous row absorbed |
| **converted** | **38** | **811** | |
| `REFUSE` | 17 | 551 | see below |

### The strongest check in the set is mutual

`sub_F00099` ends

    ld XWA,0x00F000E5 / add XHL,XWA / ld XWA,(XHL) / call XWA

so `Data_F000E5` is a **call-dispatch table**, not a blob.  Its eight entries are
0x00F00105 0x00F0028D 0x00F002C9 0x00F002EB 0x00F002B9 0x00F00280 0x00F002B6
0x00F002B3 -- and **all eight land on an instruction boundary** inside the three
code spans this lane converted at 0xF00280 / 0xF0029D / 0xF002CD.  The table
proves that code is code, and the code proves the table is a table.  Neither
claim rests on "it disassembles plausibly", which is the trap the byte gate
cannot see.

### Why the trailers are `.byte` and not `nop`

`00 00` after a `ret` is equally two `nop` instructions and a two-byte gap, and
nothing in the image distinguishes them.  Typing them is byte-exact and honest;
spelling them `nop` would be a claim with no evidence behind it.  The one-byte
0x0E trailer is the `ret` pad this build already uses in eight asserted `.fill`
runs elsewhere in this same file.

## The 17 refusals

`--probe-refusals` searches every way of covering a span with interpreter
records (op < 0x24, length at +1) and 8-byte-entry arrays whose base something
NAMES -- either the +0x07 pointer of the record just before it, or a declaration
elsewhere in the source -- and also tries a start up to 4 bytes earlier, for the
case where the previous object absorbed the record's leading bytes.

**It finds a decomposition for 1 of the 18 candidates and none at all for the
other 17.**  That one, 0xF0D9A4, is converted; the rest keep their `.incbin`.
Run `python3 scripts/analysis/prom_b_small_span_convert.py --probe-refusals`.

Refusal reasons, one line each, are in the tool's verdict table
(`--verdicts`).  Most are display-list record streams whose record boundary is
not anchored by any converted line, or 8-byte-looking arrays whose base is
declared nowhere.

### One refusal worth someone else's time

**0xF3B656.**  `Data_F3B651` starts `00 0B`.  Read as op 0x00 with length 11 the
record would end at 0xF3B65C -- but the next record demonstrably starts at
0xF3B65B (`02 0F 41 26 ...`, op 0x02 length 15, and the chain from there is
clean and reaches the end of `DL_F3B65B`'s documented extent).  So **either op
0x00 does not carry its length at +1 in this interpreter, or `DL_F3B65B`'s start
is off by one.**  This lane cannot tell which, and guessing would put a wrong
record boundary into the tree that the byte gate would happily certify.

## Result

| | spans <= 128 B | bytes |
|---|---:|---:|
| before | 55 | 1,362 |
| after | 17 | 551 |

prom_b's whole `.incbin` debt went from 71 spans / 10,664 B to 33 / 9,853 B.
Measured by `scripts/analysis/prom_b_small_span_classify.py` (`--all` for the
whole-image figure).  The byte gate is green in this worktree, and was shown to
go RED on a deliberate one-byte poison of a converted `.long`.
