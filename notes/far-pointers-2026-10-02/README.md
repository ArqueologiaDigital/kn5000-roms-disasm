# Far pointers: `pushw Sym@hi16 / pushw Sym@lo16` (2026-10-02)

The firmware's C compiler passes a 32-bit far pointer argument as two word pushes, high half
first: `pushw 0xe4` / `pushw 0x5126` is the pointer 0xe45126 (a string literal of
`PathInfo_BuildAndOpen`).  The NAKA registration macros took the same pointer as two numbers
(`RegTitle 0x3, 0xe5, 0xac98, ...`) or as one number (`RegObjTabl ..., 0xe55210, ...`).
Each half is below the ROM range, so every earlier numeric-address audit missed them:
4,074 such references at 745e6b2c (`semantic_debt_dashboard.py`, new column `numfar`).

The assembler could not spell either half symbolically (`pushw (Str >> 16)` is "expected
relocatable expression").  llvm-project `b2487ca69ec7` adds `sym@hi16` / `sym@lo16`
(R_TLCS900_HI16 / LO16) -- TOOLCHAIN_VERSION UPDATE 20, which also records the pin.

## What was done, and how to redo it

From the repo root, on a tree whose sources still hold the numbers:

    OUT=$TMPDIR/fpp scripts/converters/far_pointer_pipeline.sh      # the three steps below
    python3 notes/far-pointers-2026-10-02/hand_edits.py             # two prose fixes
    python3 notes/far-pointers-2026-10-02/c_comment_sync.py $OUT    # NAKA C comments
    make gate-all                                                   # must be 13/13

| step | script | question it answers |
|---|---|---|
| 1 | `scripts/converters/symbolize_far_pointer_pushes.py` | which `pushw HI / pushw LO` pairs and `Reg*` macro address arguments point EXACTLY at a symbol of the image's own ELF?  Those become `Sym@hi16 / Sym@lo16` / the label; RegTitle/RegMode are respelled to take one address |
| 2 | `scripts/converters/split_blobs_at_far_pointers.py` | which pointers land INSIDE an `.incbin` slice on a string, a pointer table or a registered table?  The slice is cut there and the piece named after the routine that reaches it; positional aliases on a piece retire, named aliases become labels |
| 3 | step 1 again | the pairs step 2 made exact |
| 4 | `scripts/converters/label_far_pointer_lines.py` (added in a second commit the same day) | which remaining pointers land at the START of a data line outside any slice (`.include`d format strings, NAKA title strings, `.long` tables)?  That line gets the label, named the same way |
| 5 | step 1 again | |
| - | `hand_edits.py` | two comments the pipeline made false (the DSP naming-zone `.equ` block, DbMemDump_StepTable) |
| - | `c_comment_sync.py` | the NAKA C member comments: retired alias names, and "no code reference reaches them" where the `.s` header now names readers |

The JSON files here are the reports of the committed run (`--report`):

* `pass1_<image>.json`, `pass2_<image>.json` -- step 1 / step 3: one row per pair or macro
  argument: `result` is the symbol written, `inside Parent+0xN` (no symbol at the pointer) or
  `macro arg, no symbol`.
* `split_<image>.json` -- step 2: `rows` (one per target: how it was reached -- `push`,
  `macro`, `alias` -- and why it was or was not labelled), `labels` (address -> new name),
  `pieces` (anchor+offset -> name, what `--names-from` reads), `aliases_retired`
  (alias -> the label that replaced it; an alias mapped to itself was promoted under its own
  name).  v9's reports equal v10's and are not kept.

## Results (745e6b2c -> the commit that adds this directory)

`dashboard-before-745e6b2c.txt`, `dashboard-after.txt`: `numfar` 4,074 -> 1,227, `posalias`
9,511 -> 7,097; numbr, numaddr, numevt, addrlbl, bytecmt, field and todo unchanged.

* push pairs now `Sym@hi16 / Sym@lo16`: 340 v10, 340 v9, 401 v7, 375 HD-AE5000, 2 prom_a;
* new labels from slice cuts: 1,092 v10 and v9, 976 v7 (strings `<Reader>_Str_<Text>`,
  pointer tables `<Reader>_PtrTable`, registration tables `<Module>_<Class>Table_<id>` /
  `..._<Class>Count_<id>`, 109 named aliases promoted);
* positional aliases retired: 838 v10 and v9, 741 v7 (every use, code and comments, renamed);
* RegTitle/RegMode take one address; 32 v10/v9 calls keep two numbers through
  `RegTitleHiLo`/`RegModeHiLo` (their strings sit in `.include`d text, not in a slice).

Proof: `make gate-all` 13/13 with llvm-mc 54f7d5fd; two foils (one `@hi16` flipped to `@lo16`,
one RegTitle string argument swapped for its neighbour) each change the v10 ROM.

## What the checks rejected -- read before trusting a name

* Every string candidate holding a byte >= 0x80 was a 24-bit pointer read as text
  (`B_` + 0xe9 is 42 5f e9 00 = 0xe95f42); `c_string_at` now takes printable ASCII only.
* A single own-ROM 32-bit value at the target is a pointer FIELD (Resource_Region3_Start_0x12
  is a handler pointer the code calls through), not a string: left alone.
* `RegObjTable`'s third argument is the address of a 16-bit object COUNT; the string test read
  a count of 0x006d as "m".  Macro targets are named by argument role, not by content.
* The pair window steps by one line: the compiler often pushes `3, hi, lo`, and stepping by two
  put every later pair of a run out of phase.
* Pairs with HI = 0xff or 0xfb that land inside code (`SendPartDataBlock_Data4+N`,
  `DrawLineWithMode_Impl_Skip7+N`) are two 16-bit arguments, not pointers: never touched (they
  still count in `numfar`, an upper bound).

## Second pass, the same day (steps 4-5)

`label_far_pointer_lines.py` labelled 201 lines in v10, 196 in v9, 178 in v7 and 43 in
HD-AE5000 (reports `lines_<image>.json`); step 5 then named 85 / 80 / 106 / 45 more push
pairs and 116 / 116 / 72 macro arguments, and every RegTitle/RegMode call of v10/v9 now has a
label, so the RegTitleHiLo/RegModeHiLo copies are gone.  `numfar` 1,227 -> 607 (v10 189,
v9 194, v7 187, prom_a 35, prom_c 2, HD-AE5000 0).  Gate 13/13.

## Still open

* 607 `numfar`: targets inside a line (a multi-string `.ascii`, mid-table), on code lines,
  data that is neither text nor a pointer table, and the non-pointer pairs above.
* The C side still types each split run as one member (`char East_ResNames_3EC_Strings[252]`);
  the `.s` names the strings.  Splitting the C members to match is a C-retyping job.
