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

## Third pass, the same day: numeric instruction operands (`lda xbc, (0x29559e:24)`)

The splitter and the line labeller took one more target source, numeric own-ROM INSTRUCTION
operands with no symbol at the address; symbolize_kn5000_rom_operands.py learned the
HD-AE5000 image (own ROM 0x280000..0x2FFFFF).  Reports in `operands/`:

    split_blobs_at_far_pointers.py --image v10 --apply  (v9/v7 with --names-from)   ~30 labels each
    label_far_pointer_lines.py --image <i> --apply        HD-AE5000 83, v10 11, v9 10, v7 12
    symbolize_kn5000_rom_operands.py --image <i> --apply  HD-AE5000 22 + 83, v10 30, v9 30, v7 157
    symbolize_far_pointer_pushes.py --image <i> --apply   (macro arguments made exact)

numaddr: HD-AE5000 116 -> 11, v10 109 -> 79, v9 118 -> 88, v7 346 -> 189; numfar 607 -> 534.
Gate 13/13.  (v7's 157 includes 115 exact matches that had never been applied.)

## Fourth pass, 2026-10-03: format strings and data the first passes left `inside` objects

`round3/FAR_<v>.json` are the reports this pass ran from
(`symbolize_far_pointer_pushes.py --image <v> --report ...` on the tree before it).  It placed
labels (`label_far_pointer_targets.py --apply`), rebuilt, and symbolized (`--apply`): 32 pushes in
v10, 32 in v9, 30 in v7.  Most targets are the `sprintf` format strings of compiled C ("%1d",
"%2d", "%3d", "%4d", "%2d%%"...), four bytes each, one small pool per routine inside the generated
StyleUI / SepaOut binaries -- now `<Reader>_Str_Fmt1d` ...; four are MidiSysEx_* data.

**Two false-positive classes found on the way, and fixed in the tools before applying:**
* a DrawString colour pair whose `call` is reached through a JUMP (`jr AcFileSfx_CallDrawString`)
  is outside COLOUR_CALL's six-line window: `symbolize_far_pointer_pushes.py` and the dashboard's
  `numfar` now also recognise the colour VALUES (0xFF00F5, 0xFB00F5, ... -- the list
  `unsymbolize_color_pairs.py` established);
* a push pair that lands on an UNLABELLED CODE LINE is word arguments, not a pointer (SeMenu's
  `pushw 121 / 254 / 73 / 48` made 0xFE0049): `label_far_pointer_targets.py` no longer places a
  `<Reader>_Code` label for a push-pair row.  The first dry run would have put three such labels
  on code (SeMenu_ApplyPartEdit_AltStore_Code, NoteEditBox_EventDispatch2_Code_2,
  AcFileSfx_DrawLoop_Code); they were reverted before anything was committed.

**prom_a's numfar residue (23 on 2026-10-03) is not pointers.**  `round3/FAR_prom_a.json`: every row
is a pair `pushw 0xff / pushw n` (n = 1, 3, 4, 0x0b) before a call such as `calr sub_FA0264` -- two
word arguments whose concatenation 0xFF000n lands MID-INSTRUCTION in the code at 0xFF0000
(Dev7E_IdentifyDevice_Code+1/+2/+6, sub_FC5D87_Code+1).  Nothing is labelled; the dashboard's
numfar column, which reads text only, cannot tell and still counts them.

## Correction, 2026-10-06: two SeMenu_ClearRect pairs were rectangle words

`scripts/tools/unsymbolize_semenu_clearrect_pairs.py` undoes two pushes this work had symbolized
in SeMenu_ApplyPartEdit (`audio/semenu_routines.s`, v10/v9/v7):
`pushw 171 / 232 / 118 / 67` and `pushw 130 / 232 / 77 / 67` before `call SeMenu_ClearRect`.  The
middle pairs were read as 0xE80076 and 0xE8004D and labelled SeMenu_ApplyPartEdit_AltStore_Data_2 /
_Data.  The targets were +6 of NakaInst_GM[8] and +3 of ComSetGridCheck_JumpTable_Str[6], the middle
of C-typed objects, so the code-line guard above could not catch them.  The labels are gone and
their bytes are back in the slices they were cut from.  A check of the other far-pointer targets
whose names end in `_Data` found strings or Mem_Copy sources at every one.

The same day, `scripts/analysis/semantic_debt_dashboard.py`'s VALUE_ARG_CALL list was found stale.
The naming waves had renamed two of its callees: sub_FC5CDA is now NoteRouting_QueueChange, and
SeMenu_ApplyPartEdit_AltStore_Helper/_Helper3 are now SeGfx_DrawLine / SeMenu_ClearRect.  So the
value pairs before those calls counted as numfar again: 15 at dc61d174d (v10/v9/v7 2 each, prom_a 9),
against 0 with the list updated.  The list now keeps every name a callee has had, and the dashboard
warns when no name of a callee is defined in its tree.
