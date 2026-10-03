# prom_b's three dispatch layers

CPU 1's firmware does almost nothing by direct call. Between a caller and a
routine there are, in this image, three separate indirection mechanisms, and this
round converted one instance of each. They are worth telling apart, because their
sizes are established by different arguments.

Everything below is re-derivable:

```
python3 scripts/analysis/prom_b_thunk_table.py --census   # layer 1, the census
python3 notes/prom_b_dispatch_tables.py                   # layer 2, the 48-entry tables
python3 notes/prom_b_f7d_tables.py                        # layer 3, the 32x32 tables
```

## Layer 1 — the thunk table, `0xF40000-0xF44017`

Already documented in `FINDINGS-prom_b-thunk-table.md`: 4,102 four-byte slots,
1,976 of them `jp nnn`, naming 1,910 distinct entry points. A *link-time*
directory: the caller writes `call 0xF4xxxx` and the linker fills in the slot.

## Layer 2 — the selector dispatchers, `0xF5B8B6` and `0xF5B9B8`

Two nearly identical routines, both in the thunk table's top ten for prom_b
targets (`T_F41ED0` x39, `T_F41ED4` x109):

```
    code = (XIZ+8)                      ; 16-bit, >= 0x80
    if code >= 0xC0:  entry = (0xF5BA78)[code - 0xC0]
    else:             entry = (0xF5B9F8)[code - 0x80]
    call entry
```

`Dispatch_Code80_Bracketed` (`0xF5B8B6`) wraps the call in `swi 7` function `0x0C`
with `C = 0` plus function `0x10` before, and function `0x0C` with `C = 7` after —
the same two services `sub_F31852`/`LCD_ShowAllLayers_StackFrame_Copy` issue inside the display-list
block. `Dispatch_Code80` (`0xF5B9B8`) takes an extra byte argument in `A` and
sets bit 3 of `(0x2075)` afterwards instead.

**48 entries each, and 48 is measured.** The `0xC0` bound would allow 64. What
fixes it at 48 is abutment: `0xF5B8F8 + 48*4 = 0xF5B9B8`, the `push XIZ` that
starts the second dispatcher; `0xF5B9F8 + 48*4 = 0xF5BAB8`, a
`push XWA/XBC/XDE/XHL/XIX/XIY/XIZ` prologue. All 96 words are ROM pointers and
the first word past each table is not (`0x388EEF3E`, `0x3B3A3938`).

A consequence of the arithmetic, stated but not asserted as intent: because
`table_hi = table_lo + 0x80`, selector `0xC0+n` reaches the same entry as
`0xA0+n` for `n < 16`, and selectors above that run off the end of the table.

The default entry is `0xF5BF17`, a bare `ret`: 6 of the first table's slots and 7
of the second's.

## Layer 3 — the stub block and 32 tables of 32, `0xF7D000-0xF7E2D7`

`T_F431B0` (x53) and `T_F431B4` (x57) land on entries 0 and 2 of an eight-entry
`jrl` long-branch veneer table at `0xF7D000`, which jumps into prom_a
`0xF81ACB-0xF81E7E`. So the routine directory reaches those prom_a routines
through *two* levels of veneer.

The rest of the 728-byte stub block is one-line forwarders and, 32 times,

```
    ld  XIX, <a table>
    [ cp (0x207E),0x00 / jr Z / ld XIX,<another table> ]
    call 0xF41B08                 ; -> prom_a 0xF8BDC5
    ret
```

prom_a `0xF8BDC5` is the consumer, and it is what fixes the table shape:

```
    cp HL,0x1F / jr UGT,<ret> ... and L,0x1F / sla 2,L / ld XIX,(XIX+L) / call XIX
```

32 slots of 4 bytes = 128 bytes per table.

**32 tables, and three counts agree on it:**

1. scanning 128-byte blocks upward from `0xF7D2D8`, the first 32 are entirely
   `0x00F00000-0x00FFFFFF` words and the 33rd (`0xF7E2D8`) is not — its first word
   is `0x2100230E`, and the bytes there disassemble as code;
2. the stub block holds exactly 32 `ld XIX,imm32` instructions, whose 32
   immediates are exactly the 32 table bases, each named once;
3. the highest of those is `0xF7E258 = 0xF7D2D8 + 31*0x80`, and
   `0xF7E258 + 0x80 = 0xF7E2D8`.

### ★ ESTABLISHED IN ROUND 7: the tables enumerate PANEL BUTTONS

The paragraph that used to stand here said "⚠ Not established: what the 32 tables
enumerate, what the index in `HL` is". Two of the three are now answered, by
`python3 notes/prom_b_entrypoints_round7.py --selftest` (17 checks):

* **The 0xF7D000 stubs are the METHODS OF 25 PANEL-SCREEN OBJECTS.** prom_a's
  `PanelScreen_VtableTable` (0xF86EC1, 256 LE32 pointers, documented in prom_a
  since wave 6) holds **25** pointers that land inside this directory, in
  **four-word runs** at 0xF43040-0xF431AF. Its readers take +0 Enter, +4 Leave,
  +8 Button. Each run's four stubs occupy one contiguous byte extent of the
  0xF7D000 block.
* **Every `ld XIX,<table>` stub is a screen object's +8 Button word** — 18 of
  them, and check R5 asserts the set inclusion. So a table is *a screen's button
  map*.
* **The index in `HL` is the panel button number.** prom_a's `PanelButton_Route`
  is the only reader of +8 and masks it with `and L,0x1f` (0xF861AE); the stub's
  callee `T_F41B08` → prom_a 0xF8BDC5 masks the *same* five bits. Two
  independent 5-bit masks and a 128-byte table: 32 buttons.
* **The runs have a fourth word, and it does nothing.** 23 runs have one; all 23
  stubs are no-ops (18 a bare `ret`, 5 a `calr` to an address holding one `ret`,
  then `ret`) and prom_a's four vtable readers apply only +0, +4 and +8 (check
  R7 re-derives the offset set from prom_a's bytes). ⚠ 16 `ld BC,0x000C` /
  `add XBC,0x0000000C` sites exist across the four images; none is a vtable
  reader, which is why the check is scoped to the readers' extent.
* **21 of the 25 screens are now NAMED from their own title text** — the leading
  op-0x1C records of the display list the Enter method draws: `MEASURE C0PY`,
  `TRACK MERGE`, `TRANSP0SE`, `AFTER T0UCH SETTING`, … The rule is calibrated,
  not asserted: seven of those Enter methods call a routine prom_a named
  independently from the same screens' text, and the derived title is a prefix of
  all seven and exact on six (check R8/R8b).

⚠ **Still not established:** what `(0x0C10)` MEANS — which of a screen's two
button maps it picks, and when. **`(0x207E)` is answered (2026-10-03):** it is
`UI_ScreenStage`, the page of the current screen. On the job screens 0 is the
parameter page and 1 the "Are You Sure ?" page, which a first press of the execute
key opens -- see `FINDINGS-prom_ab-screen-stage-and-flags.md`. Four of the 25 screens have no titled list and keep `sub_XXXXXX`
(0xF43040, 0xF43048, 0xF43160, 0xF431D0).

## And a fourth thing that is not a dispatch layer

`0xF55018` — the target of `T_F42C70`, whose slot address `70 2C F4 00` occurs
**397 times** as data in prom_a+prom_b (222 in prom_a, 175 in prom_b) — is a
single byte `0x0E`. A bare `ret`. Whatever those pointer tables are, their
default entry does nothing. `0xF55018` sits at the tail of a run of `0E 00 00 00`
four-byte slots at `0xF55000`, the same fill convention the thunk table uses.

⚠ **CORRECTED 2026-08-25.** This paragraph used to add "222 of them in one run at
prom_a `0x216B4`", copied verbatim from `FINDINGS-prom_b-thunk-table.md` without
being re-derived. 222 is prom_a's **total**; `0x216B4` is only its first
occurrence. `python3 notes/prom_b_default_slot_census.py` reports the longest
stride-4 run as **10** entries in prom_a (at file `0x21DED`) and **17** in prom_b
(at file `0x1B331`); the run beginning at `0x216B4` is **6**. See that findings
file for the full correction.
