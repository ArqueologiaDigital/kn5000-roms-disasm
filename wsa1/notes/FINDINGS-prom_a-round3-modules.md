# prom_a round 3: three spans closed, the panel wire map decoded, and the map
# of the one that is left

Wave 6 round 3, 2026-08-25. Byte gate re-run after every edit; the last run is
in the round report. Nothing here is a claim the gate can check — the gate is
blind to names and comments — so every number below names the script that
produces it.

---

## 1. What was converted

| span | bytes | what it is | generator |
|---|---|---|---|
| 0xFE8000-0xFEB32F | 13,104 | CPU 1's screen/dispatch module | `notes/gen_prom_a_fe8000_module.py` |
| 0xF90989-0xF92C61 | 8,921 | UI field-redraw module | `notes/gen_prom_a_f90989_module.py` |
| 0xF8A000-0xF8BBFF | 7,168 | the PANEL WIRE-to-GROUP module | `notes/gen_prom_a_f8a000_module.py` |

**+29,117 substantive, +76 filler** (`scripts/analysis/source_coverage.py`:
prom_a 345,574 -> 374,691 substantive, 135,778 -> 106,585 `.incbin`). Sixteen
`.incbin` spans became thirteen.

Each generator has a `--check` mode that refuses if its framing test fails, and
each is listed with the exact `insert_region.py` command in its own docstring.

---

## 2. The one decode worth the name: the panel wire-to-group map (gap O)

`kn7000_mame/notes/WSA1-EMULATION-DISASM-GAPS.md` gap O names 0xF8A109 /
0xF8A189 as "the panel's wire-address to group map" and gives the counts. What
this pass adds is the **index function**, read off the reader rather than
inferred, and the per-wire table:

```
    A  = the wire byte, from the panel receive ring at RAM 0x2B40
    L  = A & 0x1F                      (0xF8A0A3  cf cc 1f)
    A  = (A & 0xC0) >> 1               (0xF8A0A6  c9 cc c0 ; 0xF8A0A9  c9 ef 01)
    L |= A                             (0xF8A0AC)
    XIY = 0xF8A109                     (0xF8A0AE)          -- variant 1
    if (0xC4) != 1: XIY = 0xF8A189     (0xF8A0B3-0xF8A0BE) -- variant 2
    group = (XIY + L)                  (0xF8A0BE)
```

**index = `(wire & 0x1F) | ((wire & 0xC0) >> 1)`.** Bit 5 of the wire is
DROPPED, so wire *W* and *W* | 0x20 read the same entry; each map is 128 bytes,
which is the whole index space; 0x20 in a slot means "no group".

| variant | wires it answers to | groups |
|---|---|---|
| 1 (`(0xC4) == 1`) | C0 C1 C2 C3 C4 C5 C6 C7 C8 C9 CA — D0 D1 D2 D3 — D7 | 0x00-0x0A, 0x0B-0x0E, 0x0F |
| 2 | C0 C1 C2 C3 C4 C5 · C7 C8 C9 — D3 — D7 | 0x00-0x05, 0x07-0x09, 0x0E, 0x0F |

Both rows are read out of the ROM by
`python3 notes/gen_prom_a_f8a000_module.py --check`, which refuses if variant 1
does not have 16 live wires and variant 2 exactly 11. They agree with the gaps
note's "eleven button segments and four pots against nine segments and one pot",
and they put a number on the two the note did not name: **0xD3 is the pot both
variants keep and 0xD7 is the dial** (gap Q's wire).

⚠ **What a group id then selects is still not established.** This gives the
driver the wire list per variant and the map from wire to group; it does not say
which legend is which bit. Gap O is advanced, not closed.

---

## 3. The structures decoded in the other two spans

**0xFE8000-0xFEB32F.** 35 display lists, every one named by BOTH ends in
`ld XIY`/`ld XIX` immediates, and **35 of 35 pass the record-length walk**. Six
pointer-dispatch tables read with one five-instruction idiom, four of them with
their entry count from the READER'S OWN BOUND (`cp HL,0x001F`) rather than an
extent. Two 37-entry byte tables — `PartLabels_FE84F5` ("P 1".."P32" then five
more "P 1") and `IndexMap_FE87B8` (0x00..0x1F then five 0x00) — whose 32 is
bounded by the drawing record's count field and whose last five slots alias slot
0 in both, independently.
⚠ Both 37s are extents and the header says so.

**0xF90989-0xF92C61.** Ten tables. The interesting part is what the tools got
wrong: `notes/prom_a_ptr_tables.py` reports four pointer runs, and **two of the
four are wrong as reported** — its 64-entry run at 0xF914FB is two 32-entry
tables (two arms of one `cp (0x2687),0x00`), and its 32-entry run at 0xF91865 is
**four 8-entry tables**, because `sub_F917F4` reads exactly eight slots, one per
bit of A. A run detector measures SHAPE; only a reader measures EXTENT. Both
corrections are asserted by the generator's `--check`.

---

## 4. The map of what is left: 0xFA1404-0xFA53FF

The biggest `.incbin` left in prom_a, 16,380 bytes, and the one that holds most
of the machine's menu text. `notes/gen_prom_a_screens.py`'s call-site scan finds
**zero** display lists in it — and that is the scan being blind, not the span
being empty.

★ **prom_a uses the STACK VENEERS too.** `notes/prom_b_dl_stack_sites.py`
established the mechanism for prom_b (two ends pushed on the stack, veneers
prom_b 0xF31800/0xF31814 and prom_a 0xFF75D3/0xFF75EF). Applying the strictest
form of the same test to prom_a — the exact 12-byte
`lda XBC,(end) / push / lda XWA,(start) / push` idiom, then the record walk —
gives **368 idioms in the two images and 368 that frame**, of which **67 name a
list inside this span, 10,516 bytes; 63 after merging four overlapping pairs,
9,403 bytes**. Every overlap is one consistent record sequence read two ways
(all four endpoints are record boundaries of the union), which is what the model
strap does to a screen.

The lists print their own text. A sample, straight out of
`python3 notes/prom_a_dl_stack_map.py`:

```
  FA1F21-FA2070   335  38 recs  TEST# SYSTEM TUNE SCALE INITIAL C0NTR0LLER ASSIGN RE-MAP
  FA2688-FA28D8   592  51 recs  CONTROLLER ASSIGN PAGE SYSTEM R.T.CREATOR R.T.CONTROLLER
  FA2DFF-FA2F57   344  27 recs  INITIAL SYSTEM Reset total individual sections original
  FA302F-FA30A6   119  11 recs  ATTENTI0N! Sure?
  FA30A6-FA3221   379  46 recs  RE-MAP EDIT SYSTEM BANK GROUP BANK GROUP
```

★ **And the records declare their own tables.** An op-0x02, length-0x0F record is
`02 0F <dest u32> <count u8> <src u32> <stride u16> <2 more>`, so a table drawn
from this span has its base, entry count and stride in the record that draws it
— the interpreter's own input, not an extent. **34 such sources land inside the
span.**

⚠ **And the trap, recorded so the next pass does not fall into it.** Several
declarations OVERLAP: 0xFA4B33 is declared (32 x 6) while 0xFA4B4B, 0xFA4B4D …
0xFA4B61 are twelve separate (32 x 2) declarations two bytes apart. That is ONE
row-structured table read column by column, not thirteen tables, and emitting it
as thirteen objects would ship thirteen wrong extents. The same shape appears at
0xFA2216/0xFA2220/0xFA22A0 and at 0xFA2BC3/0xFA2CC3/0xFA2D43.

⚠ **Why this span was NOT converted in this round.** The display lists are
framed 368/368 and the ten `jp` tables at 0xFA146F..0xFA1DE1 have readers, but
the 5,465 bytes that are neither are a mixture of code, 9-byte and 3-byte record
blocks named one entry at a time by `lda` immediates, and the column-structured
text tables above. Converting it half-framed would ship exactly the kind of
plausible extent this tree exists to catch. The map is in
`notes/prom_a_dl_stack_map.py` so the next pass starts with it made.

---

## 5. Tooling, and one tool that was lying

`notes/prom_a_span_survey.py` is new: pointer runs, in-span table bases, ASCII
and 0x0E runs, the call-target histogram, and a linear decode of the span with
the rows llvm-mc cannot spell clustered — a cluster locates a table.

⚠ **Its decode number needed two fixes and the second one matters.**
`roundtrip.assemble_batch` feeds a whole region's candidate lines to one
`llvm-mc` run and drops the ones llvm-mc rejects. Over a 17 KB span that
degrades: the first version of this tool reported **1,131** unspellable rows for
0xFA5AEB-0xFA9FFF by decoding each gap from its own (possibly mid-instruction)
start, and a single-call whole-span decode reported **3,066**. Hand-checking one
"failure" — 0xFA5AEF, byte `2b` — shows llvm-mc spells it `pushw hl` perfectly
well. Decoding in 2 KB chunks that continue from the previous chunk's last
instruction is what the tool does now. **The remaining number is still an upper
bound**, because a real table inside the span desynchronises the decode after
it; that is why the tool reports clusters and not just a count.
