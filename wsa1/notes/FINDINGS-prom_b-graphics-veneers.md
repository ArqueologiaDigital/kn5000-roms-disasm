# prom_b 0xF5B800-0xF5BBE6 — the graphics veneers and two screen painters

Converted in round 2, working outward by reachability from the SC1 module and
the selector dispatchers that sit between these two blocks. 485 bytes, seven
thunk entry points, plus 10 bytes of display-list data at `0xF02FD9`.

Every number below is re-derived by

    python3 notes/prom_b_f5b800_checks.py

which prints 69 PASS/FAIL rows and exits non-zero if any claim stops holding.

## 1. The SWI7 veneer, three times over

`0xF5B84C`, `0xF5B881` and `0xF5BBB2` are **the same 53-byte routine**. Diffed,
not eyeballed:

| pair | bytes | differing | at | values |
|---|---:|---:|---|---|
| `Gfx_DrawLine_Solid` vs `Gfx_DrawLine_Dashed` | 53 | **1** | offset 43 | 0x00 / 0x15 |
| `Gfx_DrawLine_Solid` vs `Gfx_EraseRect` | 53 | **1** | offset 43 | 0x00 / 0x1B |

Offset 43 is the operand of `ld A,<service>` immediately before `swi 7`. Each
copies four 16-bit stack arguments — `(XIZ+0x08)`, `(XIZ+0x0A)`, `(XIZ+0x0C)`,
`(XIZ+0x0E)` — into `(0x2530)`, `(0x2532)`, `(0x2534)`, `(0x2536)`, writes the
byte `(0x2540) = 0`, and traps.

prom_a converts and names all three services: slot 0x00 → `0xF8EAC7`, the line
draw; slot 0x15 → `0xF900B0` = `LCD_Svc_15_DrawLineDashed`; slot 0x1B →
`0xF8F8BD` = `LCD_Svc_1B_EraseRect`. **The names come from prom_a; nothing in
prom_b says "line", "dashed" or "erase".**

### ★ This answers a question prom_a records as open

`prom_a/wsa1_prom_a.s`'s header on SWI7 service 0x00 says verbatim:

> ⚠ NOT ESTABLISHED: who calls service 0x00 and how it sets (0x2530)-(0x2536);

`Gfx_DrawLine_Solid` at `0xF5B84C` is both halves of the answer, and it is the
**busiest** of the four routines in its block (23 opcode-anchored references,
all in prom_a). prom_a's argument assignment — `(0x2530)`/`(0x2534)` X,
`(0x2532)`/`(0x2536)` Y, derived there from the service's own dx/dy
subtraction — makes the veneer's argument order **X0, Y0, X1, Y1**.

⚠ prom_a is another lane's file and was **not edited from here**; its header
still carries the question. Someone should strike it.

## 2. `(0x2540)` is a layer selector — a second, prom_b-side reason

The three veneers only ever write **0** to `(0x2540)`, so nothing in that block
distinguishes "the layer field" from "a field this caller does not use", and
their headers say so. The two painters at `0xF5BAB8` and `0xF5BB00` write
**both** values:

```
ld (0x2540),0x00   at 0xF5BABF, 0xF5BB0E, 0xF5BB25
ld (0x2540),0x01   at 0xF5BAE5, 0xF5BB8E
```

and `UiPaint_Solo` switches the value **between two display lists that draw at
identical coordinates** (see §3). That is independent of prom_a's own reading.

⚠ Not established: how many layers exist, or which is on top. Only 0 and 1 are
ever written in this block. The store is the **8-bit** form (`F1 40 25 00 00`,
opcode 0x00) despite the two 0x00 bytes.

## 3. `0xF02FD9` is a display-list ENTRY, and half of a draw/erase pair

The display-list census had `0xF02FD9` only as an **end** ("ends used" for
`DL_F02FB2`) and its ten bytes sat in an `.incbin`. `UiPaint_Solo` loads
`ld XIY,0x00F02FD9 / ld XIX,0x00F02FE3` and calls `DisplayList_Run`, so it is
also a **start**. Those ten bytes are now converted as `DL_F02FD9`.

Its four operand words are **byte-for-byte** those of `DL_F02FE3` ten bytes
later:

```
DL_F02FD9   op 05  len 0x0A   0x0008 0x0021 0x0028 0x002C
DL_F02FE3   op 1B  len 0x0A   0x0008 0x0021 0x0028 0x002C
```

and `UiPaint_Solo` runs **exactly one of the two**: op 0x05 on layer 0 when
`(0x27A2)` is non-zero, op 0x1B on layer 1 when it is zero. Same rectangle, two
ops, two layers — a two-state indicator, not two unrelated drawings.

⚠ What `(0x27A2)` holds is not established; nothing in this block writes it.

## 4. Two self-terminating tables of display-list pointers

`UiPaint_Ordinals` picks, per row, between two 6-entry arrays of 32-bit
pointers:

```
0xF02F52:  F02F22  F02F36  F02F3D  F02F44  F02F4B  F02F52
0xF02F9A:  F02F6A  F02F6A  F02F76  F02F82  F02F8E  F02F9A
```

Each **last entry is the table's own base**, which is also the byte after the
final list — so entry *k* and entry *k+1* bracket list *k* and the sixth entry
closes the fifth without a count. Checked the hard way: the last list's own
length byte lands exactly on the base (`0xF02F4B + 7 = 0xF02F52`,
`0xF02F8E + 12 = 0xF02F9A`).

The loop uses indices 1..5 only (`BC = C*4` for `C = 1..4`, plus the `+4`), so
entry 0 is never a start — which is why `0xF02F9A`'s entries 0 and 1 can both
be `0xF02F6A` without ambiguity.

The `0xF02F52` rows are the literal strings **"1st" "2nd" "3rd" "4th"** (`20 07`
records: op 0x20, 7 bytes, one operand word, three ASCII characters). The
`0xF02F9A` rows are `03 0C` records each carrying a 32-bit pointer —
`0xF0191A`, `0xF01938`, `0xF01956`, `0xF01974` — an indirect form of the same
row. Both tables are still `.incbin`; the addresses above are read from the
image, not from labels.

### The row selector

```
ld W,(0x27A4) / ld A,C / sla 0x01,A / dec 1,A / srl A,W / jr C,<table 0xF02F52>
```

so the shift count is `2C-1`. In MAME's model `{ M_SRL, O_A, O_R }`
(`../mame/src/devices/cpu/tlcs900/dasm900.cpp:843`) makes **A the count and W
the value**, and `srl8` (`900tbl.hxx:1085-1090`) sets CF from bit 0 before each
of `count` shifts, so the surviving CF is bit `count-1` of the original W.
Rows `C = 1, 2, 3, 4` therefore test bits **0, 2, 4, 6** of `(0x27A4)`.

⚠ That is **MAME's model of the part, not a databook**. The odd bits of
`(0x27A4)` are never tested here, which is a consequence of the reading offered
as a check on it — not as separate evidence for it.

## 5. `T_F41EDC` has no caller anywhere

The byte scan for `1D`/`1B` + `0xF41EDC` finds **0** hits in prom_a and **0** in
prom_b. That scan runs at every byte offset and can only over-count, so zero is
a real zero. But the thunk table has 26 **pointer** slots whose consumers read
groups of slots by address rather than by name
(`FINDINGS-prom_b-thunk-table.md`), so this is **"no reference found"**, not
"dead". Do not upgrade that without evidence.

## 6. An independent bound on the 0xF33022 label table

`UiText_CopyLabel13_To_22F0` (`0xF5B800`) does
`and A,0x3F / mul A,0x0D / ld XIY,0x00F33022 / ... / ld BC,0x000D / ldir`.

`FINDINGS-prom_b-ui-variable-index.md` had that table at **64** entries of 13
bytes, established by **abutment** (`0xF33022 + 64*13 = 0xF33362`, where a
well-formed interpreter-A record starts). The mask here means the **code cannot
address a 65th entry** — a second, independent reason for 64, from a different
region of the image. The two agree. Last-entry test: entry 63 is the
right-aligned `'           63'`, entry 49 is `'REV DYNAMIC  '`, entry 0 is
`'-------------'`, all re-read from the ROM.

The destination, `0x000022F0`, is one of the **13 RAM tables** the variable
index found, and one of its three recorded entry widths is **w13** — the same
13. So this is the writer of a buffer display-list interpreter B reads back at
that width. Which record reads it is not traced.

## 7. Still open

* **`0xF86AC7`** (prom_a, unconverted): `sub_F5B81C`'s callee through thunk
  `T_F40F40`. Disassembled from the thunk target, so the instruction boundary is
  certain: it appends a 4-byte record `{DE, WA}` to a `0xFF`-terminated list of
  at most **fifteen** slots, `0x2030-0x206B`. ⚠ That is read out of another
  image's unconverted bytes — evidence for the shape of the call, not a
  conversion. Re-check it when prom_a's lane arrives.
* **`(0x27A2)`, `(0x27A4)`, `(0x27F5)`** — read here, written nowhere here.
* **`0xF0191A`, `0xF01938`, `0xF01956`, `0xF01974`** — the four pointers inside
  the `0xF02F9A` rows.
* **`T_DLB_Handler_Array8`** — called with `XIY = 0xF02FF7` after `UiPaint_Ordinals`'
  last paint.
* The two pointer tables and their four ordinal rows are still `.incbin`; only
  `0xF02FD9` was converted here.

## How the listings were produced

Nothing in this conversion exists only in a scratch directory. The two code
listings were transcribed by the committed round-trip tool, which assembles its
candidate output and compares it byte for byte with the ROM **before** printing,
so a listing it emits is guaranteed to rebuild the range it came from:

    python3 notes/llvm_roundtrip_autoforce.py b 0xF5B800 0xB6  --quiet
    python3 notes/llvm_roundtrip_autoforce.py b 0xF5BAB8 0x12F --quiet

The `DL_F02FD9` record was emitted by hand in the same `.byte`/`.short` style
the surrounding display-list blocks use; its ten bytes are covered by the byte
gate like everything else.

Re-verify the whole block with

    python3 scripts/analysis/assert_byte_identical.py   # THE GATE
    python3 notes/prom_b_f5b800_checks.py               # the 69 claim checks

## A trap worth recording: ranking thunk slots by their annotated counts

The banner on `0xF5BAB8` says `T_F417F0` carries the highest reference count of
any annotated thunk slot. Checking that sentence, a first pass reported it as
**false** — with a top-six of counts in the 76,000s. That was wrong, and the
bug is worth writing down because the same regex will be reached for again:

```
T_F417F0:  jp DisplayList_Run  ; -> prom_b 0x31A09   x392  THE UI ENGINE
                                              ^^^
```

`0x31A09` contains a literal `x31`. A `x(\d+)` scan matches it, stops at the
`A`, and reads the slot's count as **31**. Every slot whose target address
happens to contain `x<digits>` gets a fabricated count, and the ranking is
garbage. Take the **last** `x<digits>` token on the line.

Re-measured correctly: 818 slots carry a count, and `T_F417F0` is **rank 1 with
392**, ahead of `T_F417F4` (269) — the two display-list interpreters, which is
what the thunk table's own comment two lines above them already says.

The claim was right; the first check was broken. Both facts are in the banner.
