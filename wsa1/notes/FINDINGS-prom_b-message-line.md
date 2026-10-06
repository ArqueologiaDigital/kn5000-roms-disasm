# prom_b's message line — 30 characters of RAM that the panel draws, and the 36 routines that fill it

*Wave 8, prom_b lane, 2026-08-31. The byte gate*
(`python3 scripts/analysis/assert_byte_identical.py`) *passes.*
*Regenerate every number below — do not retype one:*

```
python3 notes/prom_b_msgline.py              # the four lines and their writers
python3 notes/prom_b_msgline.py --selftest   # 45 checks, incl. 2 negative controls
python3 notes/prom_b_apply_msgline_names.py  # the rename table, re-derived from the ROM
```

## 1. The question

prom_b holds three dozen short routines with the same silhouette: check and set
a byte in RAM `(0x0EF5)`, copy an ASCII literal out of the ROM into a fixed low
address between `0x0FE4` and `0x1001`, copy three ASCII digits after it, and
`call 0xf431b4`. Every one of them was `sub_XXXXXX` and every header ended

> `Unknown: what the routine is FOR.  Left as sub_XXXXXX with the gap stated.`

That was the right call at the time: nothing **inside** any of these routines
says what `0x0FE4` is. The answer is outside them, and it is four links long.

## 2. `0x00000FE4` is one line of on-screen text, and the chain says so

| step | where | what it says |
|---|---|---|
| 1 | prom_b slot `T_F431B4` | `jp 0xF7D006`, the veneer `Veneer_F81C15`, `jrl` prom_a `0xF81C15` |
| 2 | prom_a `0xF81C15` | if `(0x207C) != 0x0E` return; else `ld XIY,0x00f3d38a / call 0xf417f8` |
| 3 | prom_b `T_F417F8` | `jp 0xF31B21` = `DLB_Handler_StringTable`, interpreter B's opcode-0x02 handler |
| 4 | prom_b `0xF3D38A` | the 15-byte record it runs |

The record is `02 0F 00 00 00 00 06 E4 0F 00 00 1E 00 21 1C`, and under the
field map `FINDINGS-ui-display-list-interpreter-b.md` already established for
this handler that reads

* `+6` = **`swi 7` function 6**
* `+7` long → `XIY` = **`0x00000FE4`**
* `+0x0B` word → `BC` = **30**
* `+0x0D` word → `IX` = `0x1C21`, the LCD cursor

prom_a's SWI7 service 6 is `LCD_Svc_06_DrawText8x14`: it draws `BC` glyphs of
the 14-byte-per-cell, 8-pixel-wide font at `0xF1B400`, reading them from
`XIY + HL*BC` and writing to cursor `IX + (0x2555)`.

So the record draws **thirty characters starting at RAM `0x00000FE4`**.

### 2.1 The length is stated twice, by two unrelated pieces of code

The record says `BC = 30`. `MsgLine_Control` (`0xF6D410`) blanks the line before
writing it:

```
	ld XIX,0x00000fe4	; F6D413
	ld WA,0x2020		; F6D418   two spaces
	ld BC,0x000f		; F6D41B   fifteen
	ld (XIX+),WA		; F6D41E
	djnz BC,0xf6d41e	; F6D421
```

Fifteen 16-bit stores = 30 bytes, `0x0FE4`–`0x1001` inclusive. Neither number
was derived from the other, and they agree. ★ That is why the extent below is a
measurement and not a convention.

### 2.2 Where the line is on the panel

`LCD_Init_SED1330` programs **AP = 40 bytes per display line** (prom_a
`0xF8E850` sends APL = 0x28, `0xF8E85B` sends APH = 0x00), so a cursor value
splits as `(row, col) = divmod(IX, 40)` and a column is 8 pixels wide. Three
sibling records sit immediately after `0xF3D38A` and have the identical shape:

| record | buffer | chars | cursor | x | y |
|---|---|---:|---|---:|---:|
| `0xF3D38A` | `0x000FE4` | 30 | `0x1C21` | 8 | **180** |
| `0xF3D3AD` | `0x001012` | 30 | `0x0821` | 8 | 52 |
| `0xF3D3CB` | `0x001030` | 30 | `0x0F29` | 8 | 97 |
| `0xF3D3E9` | `0x00104E` | 30 | `0x1631` | 8 | 142 |

Four 30-character lines down the left of a 320 x 240 panel. `0x0FE4` is the
**bottom** one.

[Named in the source 2026-10-03: `0x0FE4`-`0x1001` is `MsgLine_Text` (`MsgLine_Text+n` for its
characters) in `wsa1/include/wsa1_ram.inc` -- 66 operands, mostly `ld xix, MsgLine_Text+5`-style
pointers (`scripts/tools/name_wsa1_ram.py`).  The three sibling lines have no writers and stay numbers.]

⚠ The cursor in the record is LAYER-RELATIVE: `LCD_Svc_06_DrawText8x14` does
`add IX,(0x2555)` before using it, and `(0x2555)` is set by
`LCD_SelectCurrentLayer`. The panel has three OR-composited layers of
40 x 240 = 9,600 bytes, and all four cursors are below 9,600, so the `y` above is
the row **within whichever layer is selected**, not necessarily the row on the
composited image. Which layer these four lines are drawn into was not traced. ⚠ The other three have **no writers at all** in the converted
part of prom_b; they are listed because the records are real, not because
anything here reaches them.

### 2.3 The value after the caption

Every writer that shows a number ends by copying 2 or 3 bytes from RAM
`(0x2661)`. That is prom_a's `Value_ToAsciiDigits3` scratch: `WA` in, up to
three ASCII digits at `0x2661`–`0x2663`, with `(0x2665)` bits 0–1 recording
which digits were produced. `T_F41AF0` and `T_F41AF8` are its two
leading-zero-blanking variants (`0xF8BCAF`, `0xF8BCC9`).

### 2.4 What is still unknown, and is NOT named for

* **Which screen `0x207C == 0x0E` is.** prom_a `0xF81C15` and `0xF81ACB` both
  refuse to draw unless the screen id is `0x0E`. `0x0E` is a number; no table in
  this tree says what that screen is called, so nothing was named for it.
* **What `(0x0EF5)` selects.** Each writer compares it against its own constant
  and, on a change, calls the full-repaint entry `T_F431B0` (prom_a `0xF81ACB`,
  which dispatches on `(0x0EF5)`). The codes seen here are `0x01` and `0x0A`,
  so it is coarser than "which caption" — several routines share a code.
* **Which RAM variable supplies each value.**

## 3. The 36 names, and the evidence class of each

35 caption renames, two blank-out helpers, and **one label that did not exist**
— 38 in all. Every caption name is the CAPTION and claims nothing else.

| address | name | evidence |
|---|---|---|
| `0xF67D8C` | `MsgLine_Volume` | literal `0xF67DC6` `VOLUME = ` |
| `0xF6C9C7` | `MsgLine_PanKeyShiftTuningBendSens` | table `0xF6CA3B`, 4 x 10 |
| `0xF6D410` | `MsgLine_Control_Cleared` | literal `0xF6D464` `CONTROL`, after the blank-out |
| `0xF6D447` | `MsgLine_Control` | literal `0xF6D464` `CONTROL` |
| `0xF6D4C6` | `MsgLine_TransportState_Plus14` | table `0xF6D66D`, 13 x 8 |
| `0xF6D4E4` | `MsgLine_Rhythm` | literal `0xF6D46D` ` RHYTHM  ` |
| `0xF6D505` | `MsgLine_Tempo` | literal `0xF6D527` `  TEMPO  <0x15>=` |
| `0xF6D540` | `MsgLine_Tempo_Repaint` | same literal at `0xF6D561`, preceded by `T_F431B0` |
| `0xF6D57E` | `MsgLine_Blank` | literal `0xF6D59C`, 25 spaces |
| `0xF6D608` | `MsgLine_TransportState_Plus4` | table `0xF6D66D` |
| `0xF6D642` | `MsgLine_TransportState_Plus10` | table `0xF6D66D` |
| `0xF6D9CB` | `MsgLine_Tempo_F6D9CB` | literal `0xF6D9E2`, a third `TEMPO` variant |
| `0xF6DDB7` | `MsgLine_PartVolume` | literal `0xF6DE10` `VOLUME=` |
| `0xF6DEF7` | `MsgLine_PartPanpot` | literal `0xF6DF50` `PANPOT=` |
| `0xF6DF57` | `MsgLine_PartKeyShift` | literal `0xF6DFBA` `KEY SHIFT=` |
| `0xF6DFC4` | `MsgLine_PartTuning` | literal `0xF6E027` `TUNING=` |
| `0xF6E02E` | `MsgLine_PartBendSens` | literal `0xF6E087` `BEND SENS=` |
| `0xF6E091` | `MsgLine_PartSustain` | literal `0xF6E0EB` `SUSTAIN ` + `ON `/`OFF` |
| `0xF6E152` | `MsgLine_PartDspEffect` | literal `0xF6E1A6` `DSP EFFECT ` |
| `0xF6E1B1` | `MsgLine_PartEffect` | literal `0xF6E20B` `EFFECT ` |
| `0xF6E212` | `MsgLine_PartEffect1` | literal `0xF6E259` `EFFECT1=` |
| `0xF6E261` | `MsgLine_PartEffect2` | literal `0xF6E2AC` `EFFECT2 ` |
| `0xF6E2BA` | `MsgLine_PartReverb` | literal `0xF6E2FF` `REVERB=` |
| `0xF6E306` | `MsgLine_PanelMemory` | literal `0xF6E33F` `PANEL MEMORY=` |
| `0xF6E4F2` | `MsgLine_AccompVolume` | **label ADDED**; table `0xF6E542`, 6 x 16 |
| `0xF6E5A5` | `MsgLine_PartTremolo` | literal `0xF6E5FF` `TREMOLO ` |
| `0xF6E62A` | `MsgLine_TotalReverb` | literal `0xF6E66A` `TOTAL REVERB ` |
| `0xF6E678` | `MsgLine_PartMellowNormalBright` | table `0xF6E6D4`, 4 x 6 |
| `0xF6E706` | `MsgLine_TimeSignature` | literal `0xF6E728` `TIME SIGNATURE: /4` |
| `0xF6E73A` | `MsgLine_PartModulation2` | literal `0xF6E78B` `MODULATION2=` |
| `0xF6E797` | `MsgLine_PartCtrlPedal` | literal `0xF6E7E8` `CTRL.PEDAL=` |
| `0xF6E7F3` | `MsgLine_PartHold` | literal `0xF6E844` `HOLD=` |
| `0xF6E849` | `MsgLine_PartRtCreateX` | literal `0xF6E89A` `R.T.CREAT.X=` |
| `0xF6E8A6` | `MsgLine_PartRtCreateY` | literal `0xF6E8F7` `R.T.CREAT.Y=` |
| `0xF6E903` | `MsgLine_PartRtCtrlX` | literal `0xF6E954` `R.T.CTRL.X=` |
| `0xF6E95F` | `MsgLine_PartRtCtrlY` | literal `0xF6E9B0` `R.T.CTRL.Y=` |

Every one is evidence class **STRING** (an ASCII literal or an ASCII table the
routine's own instruction names, at an address the byte gate re-checks).

Two more are evidence class **INTERNAL** — the destination and the count are
immediates in the routine itself and the run ends exactly on the line's last
byte, `0x1001`, neither one short nor one over:

| address | name | what it does |
|---|---|---|
| `0xF6D9FB` | `MsgLine_Clear` | 15 stores of `0x2020` from `0x0FE4`; blanks all 30 |
| `0xF6D5F1` | `MsgLine_ClearTail` | 27 stores of `0x20` from `0x0FE7`; blanks +3 on |

### 3.1 Why "Part"

Twenty-one names carry `Part`. The routine that has it prefixes the line with
entry *n* of a table of `P 1`…`P32`, and that table's extent is exact rather
than guessed: `Text_VolumeP1P2P3P4P5P6P7P8P9P10P11P12P13P14P15` at `0xF6DE10`
is **231 bytes**, which is `7 + 32*4 + 32*3` — `VOLUME=`, then 32 four-character
entries at `0xF6DE17`, then 32 three-character entries at `0xF6DE97`. The two
index bases the code loads are exactly those two, and `0xF6DE97 + 32*3 =
0xF6DEF7`, the first instruction of `MsgLine_PartPanpot`. The object tiles with
no remainder at either end.

### 3.2 The label that did not exist

`0xF6E4F2` had **no label at all**: the 64-byte `.ascii` `Text_GAbABbBCDbDEbEFF`
above it ends at `0xF6E4F1` and the 80 bytes of code that follow were emitted
without one, so every tool that walks this file by label attributed them to the
data object. It is `MsgLine_AccompVolume` now, and both ends of its extent are
pinned by objects the file already frames — the `.ascii` before it, and the
caption table `Text_AccTotalVolBassVolumeDrumsVolumeAccmp1Volume` at `0xF6E542`,
one byte after its `ret`.

## 4. What was deliberately NOT named

* **`sub_F6D72F`** writes `P n ` into the line at +14 but does most of its work
  in work DRAM (`0x60A000`–`0x60A002`, `0x60F01D`) and its caption copy is not
  the routine's purpose. Left `sub_XXXXXX`.
* ⚠ **CORRECTED the same day:** `sub_F6E463` was listed here as unnamed. It is
  `MsgLine_NoteName` now — it copies four bytes of entry `(0x125A) & 15` of
  `Text_GAbABbBCDbDEbEFF` (`<G >`, `<Ab>` … `<F#>`) to `0x0FE9` and paints. It
  was missed by `prom_b_msgline.py`'s writer table only because it moves those
  four bytes with two `ld (XIX),WA` stores rather than an `ldir`; the script's
  `touches_buf` flag still listed it, which is why it got a second look.
  `sub_F6DBF9` is still refused: it writes three table-selected fields into the
  line and only the last, `TENU`/`NORM`/`STAC`/`CUTT`, is identifiable.
* **`sub_F6D482`, `sub_F6D5BA`, `MsgLine_SetTextDashes`, `MsgLine_MeasureNumber`,
  `sub_F6D710`, `sub_F6D86B`, `sub_F6D890`, `sub_F6D963`, `sub_F6D9AE`,
  `sub_F6DA12`, `sub_F6DA9A`, `sub_F6DAED`, `sub_F6DBF9`** all touch the line
  but copy no caption of their own. Three of them are close to nameable and were
  still refused, and it is worth saying why:
  * (2026-10-03, later) `MsgLine_SetTextDashes` (was `sub_F6D5E2`) was named from its body alone:
    it stores `---` at `MsgLine_Text` -- a filler, not a caption, so this list's point stands.
  * `sub_F6D9AE` renders the 16-bit word at `(0x100C)` into the line at +16,
    right after the `<0x15>=` of the `TEMPO` caption, and its callers are the
    `TEMPO` composers. "Tempo value" is a good guess and it is a guess about a
    RAM variable this round did not identify. Left `sub_XXXXXX`.
  * `sub_F6D890` copies entry `(0x12B8) & 7` of an eight-entry, eight-character
    table at `0xF6D915` (`        `, `P.BEND= `, `MOD.1 = `, `EXP.  = `,
    `P.MEM = `, `AFT.  = `) into the line at +14. The table is nameable; what
    `(0x12B8)` is, is not, and the routine's behaviour splits on it.
  * `MsgLine_MeasureNumber` renders `(0x12B2)` at the head of the line and takes a
    different path when it is >= 1000. Same reason.
* **The three sibling lines** at `0x1012`, `0x1030`, `0x104E`. Real records, no
  writers found, nothing named.

## 5. ⚠ One number in the record layout that does not close

`MsgLine_Tempo_F6D9CB` copies **26** characters from `0xF6D9E2` to `0x0FE9`:

```
	ld XIY,0x00f6d9e2	; F6D9CB
	ld XIX,0x00000fe9	; F6D9D0
	ld BC,0x001a		; F6D9D5   twenty-six
	ldir			; F6D9D8
```

`0x0FE9 + 26 = 0x1003`, so the last byte written is `0x1002` — **one past the
line's last byte at `0x1001`**. And on the source side the 26th byte is
`0xF6D9FB`, which is not part of `Data_F6D9E2` (framed as 25 bytes) at all: it
is `0x31`, the first opcode byte of `MsgLine_Clear`.

So this one routine reads one byte of code and writes it one byte past the line.
Three readings survive and this note picks none of them:

1. the line really is 31 characters and both the record's `BC = 30` and the two
   blank-out loops understate it;
2. `Data_F6D9E2` is 26 bytes and `MsgLine_Clear` starts at `0xF6D9FC` — which
   the byte gate cannot distinguish, because re-framing one `.byte` row changes
   no byte;
3. it is a firmware off-by-one that writes a stray `1` into `0x1002`.

⚠ Reading 1 would move the line's extent, so **nothing in this round rests on
the difference**: every name above is justified by the literal a routine copies,
not by where the line ends.
