# The 13 STRONG-with-evidence runs in the v10 maincpu are all DATA. All 13 refused.

**Date:** 2026-08-30
**Question:** `notes/reachability_kn5000.py --targets` ends with a work list -- every
run of reachable-but-unconverted `.incbin` bytes that the STRONG-seeded walk reached
*and* whose start something positively names. That list is **13 runs / 176 bytes**.
Convert them, or refuse them in writing.

**Answer: 0 bytes converted, 176 bytes refused, 13 of 13 runs.** Not one of them is
code. Every one is named by an instruction that **this tree has already framed over
data**, and that is the finding worth more than the 176 bytes.

**Evidence, reproducible:**

```
python3 scripts/analysis/reachability_refusal_evidence.py            # the full case
python3 scripts/analysis/reachability_refusal_evidence.py --quiet    # gate only
python3 scripts/analysis/reachability_refusal_evidence.py --survey   # the weak column
```

That script is also a **gate**: it asserts the tool's work list is still exactly
these 13 runs *and* re-checks every structural claim made below -- each pointer
landing on its string, each stride matching the cells it points at, each fill run's
extent. It exits non-zero if any of them moves, so this note cannot go quietly
stale. As of this commit: `work list MATCHES the adjudication (13 runs, 176 bytes);
0 structural claim(s) failed`.

## The numbers, before and after

| | before | after |
|---|---|---|
| STRONG seeds **and** start evidence | **176 bytes**, 13 runs | **176 bytes**, 13 runs -- all formally refused |
| STRONG seeds, evidence ignored | 4,275 bytes | 4,275 bytes |
| any seed | 128,097 bytes | 128,097 bytes |
| runs *without* start evidence | 4,099 bytes | 4,099 bytes |

Nothing was converted, so nothing moved, and **the fixpoint was reached in round 1:
converting zero bytes reveals zero new reachable bytes.** (On the WSA1 tree round 1
revealed 499 new bytes and round 2 revealed 38; here the first round is already the
last one, because the whole work list is phantom.)

The byte-identity gate is green -- `scripts/analysis/assert_byte_identical.py`,
all six ROMs IDENTICAL -- which is expected: **no `.s` file was touched.**

## Why "refuse" and not "convert"

Framing data as code still passes the byte gate. `.byte 0x4f,0x4e,0x54,0x52` and
`ld xhl,0x52544e4f` emit the same four bytes. The byte gate proves the ROM was not
*changed*; it does not prove it was *disassembled correctly*. So each refusal below
cites a structure a random byte string does not have.

## The root cause: two demonstrable misframes already in the tree

### 1. A pointer table at 0xED1BAA, read one byte late

`0xED1BAA` is an 11-entry table of 32-bit pointers. They descend by exactly 2 and
name the eleven 2-byte NUL-terminated strings `"0" "0" "0" "1" "2" ... "8"` that sit
immediately after the table -- the last entry, `0x00ED1BD6`, is precisely the first
byte past its own end:

```
[ 0] 0xED1BAA  ea 1b ed 00 -> 0x00ED1BEA  cell '0'   | tree frames it as  jp 0xE800ED
[ 1] 0xED1BAE  e8 1b ed 00 -> 0x00ED1BE8  cell '0'   |                    jp 0xE600ED
[ 2] 0xED1BB2  e6 1b ed 00 -> 0x00ED1BE6  cell '0'   |                    jp 0xE400ED
[ 3] 0xED1BB6  e4 1b ed 00 -> 0x00ED1BE4  cell '1'   |                    jp 0xE200ED
[ 4] 0xED1BBA  e2 1b ed 00 -> 0x00ED1BE2  cell '2'   |                    jp 0xE000ED
 ...                                                  ...   (down to jp 0xD600ED)
```

The tree reads this table from **0xED1BAB**, one byte late, which turns each 4-byte
pointer into a `jp` whose high byte is the *low byte of the next entry*. So the
"entry points" march downward in steps of exactly `0x020000`. **An arithmetic
progression of entry points 128 KiB apart is not a jump table.** Five of them land
inside the ROM, and four are runs 1-4 of the work list.

The tree even has *names* for those phantom targets -- `jp NakaData_PartConfig`,
`jp Bitmap_SplitPoint_Gb_0x2B`, `jp Bitmap_Dredt0d_0xA8D`,
`jp SepaOut_FormatData_Tail` -- positional labels generated at addresses that exist
only because of the misframe.

### 2. An ASCII table at 0xF6ACA0, framed as `ld xhl` immediates

`0xF6ACA0` is six 20-byte strings, `"CONTROL PITCH BEND ="` through
`"CONTROL AFTER TOUCH="`. The tree frames it as `ld xhl,0x52544e4f` (= `"ONTR"`)
and friends. The 15-byte `.incbin` immediately *before* it is the **descriptor**
that names the table.

There are five more of the same shape, and the shape is unmistakable -- a tag byte,
a 32-bit pointer, then a 16-bit field that equals the exact cell width of the ASCII
the pointer lands on:

| descriptor | pointer | stride | cells it lands on |
|---|---|---|---|
| 0xF6AC91 | 0x00F6ACA0 | 20 | `'CONTROL PITCH BEND ='  'CONTROL MODULATION ='  ...` |
| 0xF6AD18 | 0x00F6AD27 | 3 | `'OFF'  ' ON'` |
| 0xF6AD37 | 0x00F6AD9E | 2 | `' C'  'C#'  ' D'  'D#'  ' E'  ' F'  ...` (note names) |
| 0xF6AD46 | 0x00F6ADB6 | 2 | `'-2'  '-1'  '0 '  '1 '  '2 '  '3 '  ...` (octaves) |
| 0xF6AD8F | 0x00F6AE4C | 4 | ASCII; cell boundary not settled, so nothing is claimed |
| 0xF12B86 | 0x00F12CCF | 2 | `'A:'  'B:'  'C:'  ...` (in `audio/sound_editor_ui.s`) |

A 32-bit field that lands exactly on ASCII followed by a 16-bit field equal to that
ASCII's cell width is a data descriptor. No instruction encoding produces that pair
by accident.

The single most compact demonstration is the namer of run 13: the tree's
`ld xiz,1313808454` at `0xF6AD28` **is the ASCII `"F ON"`**, the tail of the `"OFF"`
`" ON"` table the descriptor before it points at.

### 3. Two smaller ones

* `0xEED642`: the repeated 16-bit constant `1e 00 1e 00 1e 00 1e 00` is framed as
  two `calr` -- both, inevitably, targeting the same address, 0xEEF445 (run 8).
* `0xF12B85`: the `nop` that names run 9 is the `0x00` **high byte** of the 32-bit
  pointer `0x00F12D0B` at 0xF12B82.

## The 13 refusals

| # | run | B | named by | verdict |
|---|---|---|---|---|
| 1 | 0xE200ED-0xE2013F | 82 | `jp 0xe200ed` @0xED1BB7 | 16-bit table into printf strings `"%2d : %s"`, `"FILE%02d:%s"`, `"%03d:%s"`, `"%02d:%s"` |
| 2 | 0xE400ED-0xE400EE | 1 | `jp 0xe400ed` @0xED1BB3 | one byte inside a **measured** 215-byte solid `0xff` run (0xE400C9-0xE401A0) |
| 3 | 0xE600ED-0xE600FE | 17 | `jp 0xe600ed` @0xED1BAF | tail of a **measured** 119-byte `0x00` run, then the bitmap rows `fe fe fe fe 00 fc fc fc fc 00 ...` |
| 4 | 0xE800ED-0xE800EF | 2 | `jp 0xe800ed` @0xED1BAB | 16-bit table into `" LEFT  \0RIGHT 2\0RIGHT 1\0"` at 0xE800F6 |
| 5 | 0xED3C96-0xED3C9B | 5 | fall-through from `ldb b,1` @0xED3C94 | a naka widget header: `34 00` length word, `60 01` = type 0x0160 **text widget** -- the format `control_menu_screens.s` documents in its own header comment. Its pointer at 0xED3CB8 lands exactly on the inline `"CONTROL MENU"` |
| 6 | 0xED40A7-0xED40C6 | 31 | `calr 0xed40a7` @0xED38A4 | pointer 0x00ED40B8 at 0xED40B0 lands exactly on the inline `"INITIAL\0"`; 0xED40C0 is the next header `33 00 60 01 ff ff` |
| 7 | 0xED5465-0xED5466 | 1 | `calr 0xed5465` @0xED3862 | second byte of the `ff ff` flags field of the record at 0xED545E (`48 00 60 01 00 00 ff ff`); the preceding record's pointer lands on `"STYLE EXPLORER\0"` |
| 8 | 0xEEF445-0xEEF451 | 12 | `calr 0xeef445` @0xEED642 | **measured** 85-byte `0x00` run inside a mask bitmap; namer is the `1e 00 1e 00 1e 00 1e 00` constant |
| 9 | 0xF12B86-0xF12B8A | 4 | fall-through from `nop` @0xF12B85 | head of a descriptor: pointer 0x00F12CCF, stride 2, cells `'A:' 'B:' 'C:' ...`. The `nop` is the pointer's own high byte |
| 10 | 0xF6AC91-0xF6AC95 | 4 | fall-through from `nop` @0xF6AC90 | head of the descriptor for the 6x20 `"CONTROL ..."` table |
| 11 | 0xF6AC9F-0xF6ACA0 | 1 | `jr lt,0xf6ac9f` @0xF6AC85 | the last byte before that ASCII table |
| 12 | 0xF6AD18-0xF6AD1C | 4 | fall-through from `push xiy` @0xF6AD17 | head of the descriptor for `"OFF"` / `" ON"` |
| 13 | 0xF6AD2D-0xF6AD39 | 12 | fall-through from `ld xiz,1313808454` (= `"F ON"`) @0xF6AD28 | that table's NUL plus the next descriptor (ptr 0x00F6AD9E, stride 2, note names) |

## Did refusing everything leave real code unconverted?

No -- checked, not assumed. `--survey 25` lists the largest runs of the **weak**
(`any`-seed) walk that also have start evidence: 2,014 runs, 67,247 bytes -- the
column the tool explicitly warns against converting. Every one of the 25 largest
is data, and it is obvious from the ASCII: `0xf7`/`0xf2` palette fill, `0x06`
fill, zero fill, tables of 32-bit pointers (`10 48 e1 00` = 0x00E14810, ...),
3-byte-plus-NUL triples in `debug_naming_panel_sim.s`, decimal-number strings
(`"  40   50   63   80  100 ..."`, `"0.10 0.12 0.14 ..."`), bitmap filenames
(`"i70.bmp"`), style names (`"Modern Vibes"`, `"Jamaican Swing"`) and widget
names (`"MainPanic"`, `"EtmenuTitleFunc"`). Not one is a routine.

## What the next lane should consider

**Nothing here was changed.** Correcting the misframes above means re-framing bytes
the tree currently holds as CODE territory into `.word` / `.ascii` -- the opposite
direction from this lane's mandate, touching code that other lanes' labels point
into, and cascading backwards to wherever each misframe begins (for 0xED1BAB it
starts at least as early as the `ld xhl,3942580256` at 0xED1BA6). It should be its
own lane, with its own gate. Doing it would:

* remove 4 of the 13 phantom runs outright (runs 1-4, 102 of the 176 bytes) by
  deleting the five phantom `jp 0x??00ED` seeds at their source;
* remove the `fallthrough` seeds behind runs 5, 9, 10, 12 and 13, which exist only
  because a pointer's high byte assembles as `nop`;
* and -- the part that matters beyond this lane -- **stop `branch` and `fallthrough`,
  the tool's two strongest seed classes, from being fed by the tree's own misreads.**
  A seed class whose members are produced by mistakes in the thing it is measuring
  cannot grade evidence, and that is what "STRONG" currently means for these 13.
