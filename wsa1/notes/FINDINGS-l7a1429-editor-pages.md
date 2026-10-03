# The tone editor's PAGES, and what each of the L7A1429's registers is called

Lane `w21/cpu1-hop`, 2026-09-03.  This closes the hop
`FINDINGS-l7a1429-parameter-names.md` section 7 item 1 asked for -- "correlate the
parameter index at a call site with the screen identity that reaches it" -- and it
did not need the screen identity in `(0x207C)`, because the firmware states the
correspondence twice over in a much narrower place.

Everything below is re-derived from `original_ROMs/wsa1_prom_{a.ic12,b.ic13}` by one
committed script:

```
cd <tree>/wsa1
python3 notes/wsa1_toneedit_pages.py            # sections 1-7, printed
python3 notes/wsa1_toneedit_pages.py --nulls    # nulls 1-3
python3 notes/wsa1_toneedit_pages.py --selftest # FAILURES: 0   (25 checks)
```

No `.s` file is an input to it.  Where a claim is quoted from another lane's
converted source it is cited at the address and was re-read there.

This lane made ONE source edit, to `prom_a/wsa1_prom_a.s`: the five page ENTER
routines are renamed from `sub_XXXXXX` and given a header apiece.  The map is
`notes/w21-lsi-editor-page-renames.map`:

```
sub_FDD7F9 = ToneEditPage_A3_PositionParameter
sub_FDD958 = ToneEditPage_A4_PositionMovement
sub_FDDA1C = ToneEditPage_A5_FittingMutingTuning
sub_FDDC3A = ToneEditPage_A6_TouchDepth
sub_FDDDAA = ToneEditPage_A7_ResoModeKeyFollow
```

Each is reached only through the panel-screen vtable, so the rename touches one
line each; the screen code in each name is the literal the routine's own messages
carry.  Both gates were run: `make gate-all` byte-identical, and
`assert_comments_preserved.py --base main --rename-map` PASS with +134 comments
and none altered.

---

## 0. THE ANSWER, IN ONE PARAGRAPH

[Named in the source 2026-10-03: `((u8 *)0x27A6)` is `ModelingPage_Fields` in `wsa1/include/wsa1_ram.inc`,
its bytes `ModelingPage_Fields+n` to 0x27B7 (extent from FINDINGS-prom_b-ui-variable-index.md) -- in the
code's operands, in `ld (XBC+ModelingPage_Fields),A`, and in the display-list records' `+0x02` source-variable
fields (`scripts/tools/name_wsa1_ram.py`).]

**The MAIN/SUB direction is CORROBORATED, by evidence that never mentions
`SUB GAIN`.**  The seven MODELING pages each read their fields back from CPU 2 in
a fixed order and store reply *n* at `((u8 *)0x27A6)[n]`, so the request order IS
the map from tone-edit parameter to the RAM byte the page draws; and every value
a page draws carries its **display-RAM byte address**, which the SED1330's own
`C/R = 40` turns into a screen row and column.  On `PAGE1/3` the ten values land
on display rows **156** and **187**, four rows under the `MAIN RESONATOR` and
`SUB RESONATOR` labels the *same paint routine* draws, and the read-back order puts
`p21 p22 p29 p30` on the MAIN row and `p31 p32 p41 p42` on the SUB row.  Eight
independent (index, parameter) pairs named by the per-field editors agree with that
order, 8 of 8.  **All four WEAK registers are resolved**: `0x0300` is
`INTERACTION GAIN` (p19), `0x0240` is what `DEPTH` (p14 bits 0-6) scales, and the
remaining pair `0x03C0`/`0x0480` is **shown to have no editor name at all**,
because its only input `p15` is set by the RESONATOR TYPE preset and is not an
editor parameter -- so two are named and two are refused, with a reason.  **`SCALE` is found**: it is the `RESO SCALE` column, `OFF`/`ON`, and it
is **bit 7 of p22 / p32**.  The `FITTING`/`MUTING` split is corroborated by a
second, positional route.  Two claims are overturned; see section 1.

---

## 1. TWO CORRECTIONS OWED TO FILES THIS LANE DOES NOT OWN

### 1a. `+0x0B` bits 7:6 are the layer **GROUP**, not `RESO MODE` -- the old call was WRONG

`FINDINGS-l7a1429-parameter-names.md` section 2d ends:

> prom_a `0xFD434D` sends the same parameter `0x0B` with mask `0xC0` -- the top two
> bits, which is the field `sub_FC7481` reads and which PAGE3/3 draws as two bit-7
> flags.  `+0x0B` bits 7:6 = **`RESO MODE`**, grade STRONG.

The two bit-7 flags PAGE3/3 draws are `(0x27A7)` and `(0x27A8)`, and on that page
those two bytes hold **p21 and p31**, not p11.  The `0xFD434D` writer is a different
screen entirely:

* `0xFD422B` repaints with `pushw 0x06 / pushw 0xc0` (`0xFD43B8`), i.e. dispatch
  code `0xC0` = screen `0xA0`, the **MODELING top** page, field 6;
* it edits `((u8 *)0x27A6)[6]` over the range **0..4** (`0xFD4259`-`0xFD4286`) and
  then, for all four layers, ORs bits into p11: value 1 or 3 sets `0x40` on layers
  1 and 2 (`0xFD42D9`, `0xFD42DD`), 2 or 3 sets `0x40` on layers 3 and 4
  (`0xFD42ED`, `0xFD42F1`), 4 sets `0x80` on all four (`0xFD4305`);
* prom_b's partial repaint for that field, `sub_F5CBD9` (`0xF5CBD9`), reads
  `(0x27AC)` -- which is `0x27A6[6]` -- and switches between four different bracket
  graphics (`0xF5CBEC`-`0xF5CC2E`);
* the MODELING top's own bottom legend is `ON/OFF  GROUP  DRIVER  RESONATOR
  INTERACTION` (`0xF020CF`-`0xF02101`), and `GROUP` is the second column.

So p11 bits 7:6 encode which layers are **grouped together**, drawn as a bracket.
The factory data agrees: over the 392 melodic wave-select records of section 4b,
p11 takes only `{0x00, 0x40, 0x80}` and never `0xC0` -- exactly the three values
that encoder can emit.  GRADE **STRONG** (a drawn caption, a measured five-state
control, a graphic that changes with it, and a factory-data signature).

⚠ **This field is what the sibling lane calls `RESO MODE`** when it reports that
register `0x0300` is a part-level enable gated by "a non-zero mode".  Its
measurement stands; the name it used is the one being corrected here, and once the
field is read as `GROUP` its result and this one fit together -- see section 4c.
`RESO MODE` is a real caption, but it belongs to p21/p31 bit 7 -- see section 4e.

### 1b. The `LinCoef_*_KeyRamp_Q5_128` tables are **TOUCH** (velocity), not key ramps

`prom_c/devices/dev10c_dev104_drivers.s` names five coefficient tables
`LinCoef_Position_KeyRamp_Q5_128`, `LinCoef_Fitting_KeyRamp_Q5_128`,
`LinCoef_Muting_KeyRamp_Q5_128`, `LinCoef_SubGain_KeyRamp_Q5_128`.  Their
coefficient inputs are `Q[+0x10] +0x17 +0x18 +0x22 +0x23 +0x24` -- and those six
bytes are **exactly** the six fields of the page captioned `TOUCH DEPTH`
(`0xF02D13`), plus `TOUCH` on `P0SITI0N M0VEMENT` (`0xF02983`).  Six for six.
The variable the tables are indexed by is `(0x00E088)`, which
`Pack104_SetInputs_E088_E089_E08A` writes **with bit 7 cleared**
(`res 0x07,C` at `0xFC4D6A`) -- a 0..127 quantity -- while the separate
`(0x00E08C)` is written only by the four `KeyZone_Stage_Reg0040_Stride*` routines.
GRADE **STRONG**: the UI captions six for six, and the two RAM slots are told apart
by their writers.  Reported, not edited -- it is another lane's file.

---

## 2. THE INSTRUMENT, AND WHY IT IS NOT A GUESS

### 2a. Every drawn value carries its display-RAM ADDRESS -- PROVEN, from the hardware

`notes/FINDINGS-display-controller.md` already decodes `LCD_Init_SED1330`'s own
SYSTEM SET bytes: **`FX+1 = 8` pixels per byte, `C/R+1 = 40` bytes per line,
`L/F+1 = 240` lines**, and `LCD_Svc_0B_PlotPoint` computes
`address = Y*(0x2557) + X/8`.  Interpreter A's fixed-pitch text opcodes (handler
`0xF31A3A`) and **all** of interpreter B's value opcodes put a 16-bit
display-RAM byte address in `IX`; interpreter A's *proportional* text opcodes
(handler `0xF31A52`) instead carry x and y in pixels.  So

```
    row = word / 40        x = 8 * (word % 40)
```

turns every value record into a screen coordinate in the same space as the
captions.  ⚠ **NULL 1** shows the structure alone does not pick the stride: sweeping
4..256, the strides that make `PAGE1/3`'s ten values fall into two rows of five
with identical column sets are `{40, 124, 155, 248}` -- all the divisors of the row
gap 1240.  What picks 40 is the SED1330 SYSTEM SET, outside this script; the other
three imply a panel 992, 1240 or 1984 pixels wide, and the widest pixel x any
proportional-text record in the MODELING block carries is **310**.

### 2b. Request order IS the RAM index -- PROVEN, and independently controlled

Each page's ENTER routine in prom_a fires a run of read-back requests
(`sub_FD61CF`, message class `0x80 | arm`, i.e. bit 3 clear).  Its reply handler is

```
    Var27DB_Get(&n);  sub_FD7744(&v);  Arr27A6_Set(n, v);  if (++count > N) redraw
```

-- so reply *n* lands at `((u8 *)0x27A6)[n]`.  Two of the five pages call
`sub_FD7719` once **before** the reply run (`0xFDDB87`, `0xFDDD2C`, `0xFDDEB3`),
which starts the counter at 1; the other two do not, and start at 0.  That is not
an assumption: the completion tests are `cp A,0x02` for a three-request page and
`cp A,0x08` / `cp A,0x06` / `cp A,0x0A` for eight-, six- and ten-request pages,
and only the stated bases make each threshold the last reply.  **And the RAM bytes
each page draws confirm it independently**: the base-0 pages draw `0x27A6`-`0x27A8`,
the base-1 pages draw `0x27A7` upward.

★ **THE CONTROL.**  Four per-field EDIT routines name an (index, parameter) pair
directly, in two immediates a few bytes apart.  All eight pairs agree with the
order-derived map:

| screen | editor | index | parameter | order says |
|---|---|---:|---|---|
| PAGE1/3 | `0xFD4BA4` | 2 | p22 | p22 |
| PAGE1/3 | `0xFD4BA4` | 6 | p32 | p32 |
| PAGE3/3 | `0xFD5732` | 4 | p26 | p26 |
| PAGE3/3 | `0xFD5732` | 8 | p38 | p38 |
| PAGE3/3 | `0xFD5883` | 3 | p25 | p25 |
| PAGE3/3 | `0xFD5883` | 7 | p37 | p37 |
| PAGE3/3 | `0xFD5A0E` | 5 | p27 | p27 |
| PAGE3/3 | `0xFD5A0E` | 9 | p39 | p39 |

Eight of eight.  Ten indices are in play per page, so an unrelated map would agree
on all eight with probability about `1e-8`; and a *permuted* map would have to
preserve both rows' column geometry as well (section 3c).

### 2c. Which page a routine belongs to is a NUMBER, not an inference

prom_a repaints through `T_Dispatch_Code80` (`0xF41ED4` -> prom_b `0xF5B9B8`) with
a screen code in `(XIZ+8)`.  `Dispatch_Code80` indexes `(0xF5BA78)[code-0xC0]` for
codes >= 0xC0 and `(0xF5B9F8)[code-0x80]` otherwise, and `0xF5BA78 = 0xF5B9F8 +
0x80`, so **code `0xC0+k` reaches the same entry as `0xA0+k`** -- checked entry for
entry, all 16.  The seven MODELING screens:

| code | full repaint | partial repaint | page |
|---|---|---|---|
| `0xA0` | `0xF5BFC7` | `0xF5CB1E` | MODELING top |
| `0xA2` | `0xF5C06C` | `0xF5CC3D` | DRIVER WAVEFORM |
| `0xA3` | `0xF5C09E` | `0xF5CCF6` | `PAGE1/2 P0SITI0N PARAMETER` |
| `0xA4` | `0xF5C0D4` | `0xF5CD1E` | `PAGE2/2 P0SITI0N M0VEMENT` |
| `0xA5` | `0xF5C10A` | `0xF5CD46` | `PAGE1/3` |
| `0xA6` | `0xF5C172` | `0xF5CDA8` | `PAGE2/3 TOUCH DEPTH` |
| `0xA7` | `0xF5C1AC` | `0xF5CDD4` | `PAGE3/3` |

Each ENTER routine also tags its read-back requests with its own code -- `0xC3` at
`0xFDD835`, `0xC4` at `0xFDD98F`, `0xC5` at `0xFDDA59`, `0xC6` at `0xFDDC7F`,
`0xC7` at `0xFDDDEA` -- so a page's request run is bound to its screen by a literal
the message carries, not by adjacency.

---

## 3. THE PAGE-BY-PAGE MAP

Positions are `(display row, pixel x)`.  `p<N>` is arm-4 tone-edit parameter N =
wave-select byte `+0x0N` in hex.

### 3a. `PAGE1/2  P0SITI0N PARAMETER` (screen `0xA3`, enter `ToneEditPage_A3_PositionParameter` `0xFDD7F9`)

Reads **p13, p14, p19** into indices 0, 1, 2.  Caption and value share a row, five
times out of five:

| caption | at | value | at | field |
|---|---|---|---|---|
| `P0SITI0N  :` | row 116 | `(0x27AA)&0x3F` `.` `(0x27AB)&0x0F` | row 116 | **`P0SITI0N`** = p13, drawn as `p13/5 . 2*(p13%5)` |
| `DEPTH     :` | row 131 | `(0x27A7)&0x7F` | row 131 | **`DEPTH`** = p14 bits 0-6 |
| `FORMANT   :` | row 146 | `(0x27A7)&0x80` -> `FIX `/`MOVE` | row 146 | **`FORMANT`** = p14 bit 7 |
| `INTERACTION` / `GAIN      :` | rows 164/179 | `(0x27A8)&0x7F` | row 179 | **`INTERACTION GAIN`** = p19 |

⚠ **NULL 3**: five of five values sit on a caption's row; over 100,000 random draws
from the same address range the mean is **0.19 of 5**.

★ The `P0SITI0N` row is PROVEN twice: the dedicated editor `0xFD44C7` sends
parameter `0x0D` and writes the same `/5` split into indices 4 and 5
(`div C,0x05` at `0xFD4564`, `Arr27A6_Set(4,..)` at `0xFD457E`,
`Arr27A6_Set(5,..)` at `0xFD4586`), and the ENTER routine's reply path does the
identical split from index 0 (`0xFDD8EE`-`0xFDD929`).

### 3b. `PAGE2/2  P0SITI0N M0VEMENT` (screen `0xA4`, enter `ToneEditPage_A4_PositionMovement` `0xFDD958`)

One request, parameter `0x10` with **count 3** (`pushw 0x03` at `0xFDD992`), and a
reply loop that copies the three returned bytes to indices 0, 1, 2 in order
(`0xFDD9D8`-`0xFDD9F4`).  So p16, p17, p18:

| caption | row | value | field |
|---|---|---|---|
| `WIDTH :` | 112 | `(0x27A7)&0x7F` | **`WIDTH`** = p17 |
| `SPEED :` | 125 | `(0x27A8)&0x7F` | **`SPEED`** = p18 bits 0-6 |
| `S/H   :` | 139 | `(0x27A8)&0x80` -> `OFF`/` ON` | **`S/H`** = p18 bit 7 |
| `TOUCH :` | 157 | `(0x27A6)` signed | **`TOUCH`** = p16 |

Four for four on the row test.

### 3c. `PAGE1/3` (screen `0xA5`, enter `ToneEditPage_A5_FittingMutingTuning` `0xFDDA1C`) -- the page that settles MAIN/SUB

Reads `0x15 0x16 0x1D 0x1E 0x1F 0x20 0x29 0x2A` into indices 1..8.  Its ten value
records land on exactly two rows with **identical** column sets:

```
    column x      48        88       128       160       208
    header      FIT/TING  MUT/ING  KEY/SHIFT  DE/TUNE  RESO/SCALE
                (x 49)    (x 86)    (x 129)   (x 168)   (x 210)
    row 156    (0x27A7)  (0x27B0)  (0x27A9)  (0x27AA)  (0x27A8)&0x80
                 p21     <- p22      p29       p30       p22 bit 7
    row 187    (0x27AB)  (0x27B1)  (0x27AD)  (0x27AE)  (0x27AC)&0x80
                 p31     <- p32      p41       p42       p32 bit 7
```

`(0x27B0)`/`(0x27B1)` are not read back; both the ENTER routine (`0xFDDBD0`-
`0xFDDC0B`) and the editor (`0xFD4C7E`, `0xFD4D06`) compute them as
`(p22 & 0x7F) - 0x7F` and `(p32 & 0x7F) - 0x7F`.  So one byte carries two fields:
the `MUTING` number and the `RESO SCALE` flag.

★★ **THE ROW LABELS.**  The same paint routine `0xF5C10A` calls `0xF5C388`, which
runs caption list `0xF02B47`.  That list puts, in the bottom table:

```
    'MAIN'      pixel y 152        'SUB'        pixel y 183
    'RESONATOR' pixel y 164        'RESONATOR'  pixel y 195
```

⚠ **NULL 2**: value row 156 is `+4` from the `MAIN` label and value row 187 is
`+4` from the `SUB` label -- the **same** offset.  Swapped, the offsets are `+35`
and `-27`: unequal, and one puts a value above its own label.

**Therefore `{p21, p22, p29, p30}` is the MAIN resonator and `{p31, p32, p41,
p42}` the SUB.**  `SUB GAIN`, p33 and p36 appear nowhere in that argument.

### 3d. `PAGE2/3  TOUCH DEPTH` (screen `0xA6`, enter `ToneEditPage_A6_TouchDepth` `0xFDDC3A`)

Two loops -- `ld HL,0x17 / ldb D,0x02` and `ld HL,0x21 / ldb D,0x04` -- read
`0x17 0x18 0x21 0x22 0x23 0x24` into indices 1..6.

```
    header      FITTING   MUTING              SUB / GAIN  (x 208)
                (x 46, in the legend `FITTING MUTING SUB-GAIN`)
    row 156     x 48      x 96      x 160      x 216
               (0x27A7)  (0x27A8)    '--'       '--'
                 p23       p24
    row 187     x 48      x 96      x 152      x 200
               (0x27AA)  (0x27AB)  (0x27AC)   (0x27A9)
                 p34       p35       p36        p33
```

The MAIN row shows `--` in the two columns that belong to the sub side, and the
SUB row's rightmost field, the only one under the `SUB` / `GAIN` header at x 208,
is **p33**.  That is the old note's section 5b fact, now positional: it does not
add to the direction argument, but it is no longer an inference from an asymmetry.

### 3e. `PAGE3/3` (screen `0xA7`, enter `ToneEditPage_A7_ResoModeKeyFollow` `0xFDDDAA`)

Reads `0x15 0x1F` then two loops `0x19..0x1C` and `0x25..0x28`, into indices 1..10.

```
    column x       56        88       128       168       208
    header      RESO/MODE  MUTING/  <---- KEY FOLLOW / RANGE ---->
                            SLOPE
    row 156    (0x27A7)   (0x27AC)  (0x27AA)  (0x27A9)  (0x27AB)
               p21 bit 7    p28       p26       p25       p27
    row 187    (0x27A8)   (0x27B0)  (0x27AE)  (0x27AD)  (0x27AF)
               p31 bit 7    p40       p38       p37       p39
```

The three note-name fields are drawn through the note table `0xF05B60`; `SLOPE`'s
caption is at pixel x **88** and its field at x **88**.  ★ The two rows put
`lo / break / hi / slope` in the *same* columns -- `p26 p25 p27 p28` above,
`p38 p37 p39 p40` below -- which is what `ks(Q, 0x19)` and `ks(Q, 0x25)` are in
prom_c.  A wrong reply order would scramble one row against the other.

★ In the drum-kit mode `(0x27F5) == 1` prom_b draws only the `RESO MODE` half of
this page (`0xF5C1B4` branches to `0xF5C1DE`), which is why an earlier pass saw
`PAGE3/3` as a two-flag page.

### 3f. MODELING top (screen `0xA0`, enter `0xFDD437`)

`(0x2808)..(0x280B)` -- one byte per layer -- are drawn through the 64-name
resonator table `0xF03241` with mask `0x3F`: the **`RESONATOR TYPE`** already
PROVEN in the old note's section 2d, written by `0xFD414E` with parameter `0x0B`
mask `0x3F`.  Field 6 is the **`GROUP`** control of section 1a.

---

## 4. THE REGISTER TABLE, RE-GRADED

⚠ **`CROSSCHECK-NAME-TABLE`.**  `notes/l7a1429_crosscheck.py` reads the name column of the
table below as this artefact's answer, and fails if it disagrees with `HLE-GUIDE-l7a1429.md`
§5.3, the docs site's `wsa1-modeling-lsi.md` register table, or the MAME driver's
`block_name()` in `src/mame/matsushita/acoustic_modeling.{h,cpp}`.  Two rows are declared
exceptions there and the script prints the reason for each rather than skipping them
silently: `0x0000`, whose FIELDS are named but whose word is not, and the global `0x0800`,
which has no channel and no editor page and so has no row here.

The arithmetic column is prom_c's, unchanged.  The name column is what the machine
draws; **it is not a claim about the physical quantity**.

| reg | its inputs (prom_c) | the machine's name for them | grade |
|---|---|---|---|
| `0x0000` | bit 15 <- p21 bit 7, bit 14 <- p31 bit 7, bit 7 <- sign(p33); bits 6:4 from elsewhere | bits 15/14 = MAIN / SUB **`RESO MODE`** | **STRONG** |
| `0x0040` | p29, p30 (+p26/p27 when p25 bit 7) | MAIN `KEY SHIFT` + `DETUNE` | **PROVEN** |
| `0x0080` | p41, p42 (+p38/p39) | SUB `KEY SHIFT` + `DETUNE` | **PROVEN** |
| `0x00C0` | p13, p16, p17, p18; key-follow gated by p14 bit 7 | `P0SITI0N`, its `TOUCH`, and `P0SITI0N M0VEMENT` `WIDTH`/`SPEED`/`S/H`; the gate is `FORMANT` (section 4d) | **PROVEN** |
| `0x0100` | -- | a constant | (constant) |
| `0x0140` | p21, p23 | MAIN `FITTING` + its `TOUCH DEPTH` | **PROVEN** |
| `0x0180` | p31, p34 | SUB `FITTING` + its `TOUCH DEPTH` | **PROVEN** |
| `0x01C0` | p21, p23 | MAIN `FITTING`, rise form | **PROVEN** |
| `0x0200` | p31, p34 | SUB `FITTING`, rise form | **PROVEN** |
| `0x0240` | value from p15; index from p14 bits 0-6 + p33 + movement | the register **`DEPTH`** acts on | **STRONG** |
| `0x0280` | p33, p36 | **`SUB GAIN`** + its `TOUCH DEPTH` | **PROVEN** |
| `0x02C0` | -- | the literal `0xFF00` | (constant) |
| `0x0300` | p19, gated by word 0 bits 6:4 | **`INTERACTION GAIN`** | **STRONG** |
| `0x0340` | p22 bits 0-6, p24, p25-p28 | MAIN `MUTING` + `TOUCH DEPTH` + `KEY FOLLOW` | **PROVEN** |
| `0x0380` | p32 bits 0-6, p35, p37-p40 | SUB `MUTING` + `TOUCH DEPTH` + `KEY FOLLOW` | **PROVEN** |
| `0x03C0` | p15 only | ⚠ **NO EDITOR NAME EXISTS** | **RESOLVED, negatively** |
| `0x0400` | as `0x0340` | MAIN `MUTING`, second curve | **PROVEN** |
| `0x0440` | as `0x0380` | SUB `MUTING`, second curve | **PROVEN** |
| `0x0480` | p15 only | ⚠ **NO EDITOR NAME EXISTS** | **RESOLVED, negatively** |

**Before this pass: 12 STRONG, 4 WEAK, 1 UNIDENTIFIED, 2 constants.  After:
12 PROVEN, 3 STRONG, 2 resolved-negatively, 2 constants.**  Nothing is left at
WEAK, and nothing is left UNIDENTIFIED except register `0x0000`'s bits 6:4.

⚠ **HOW THE GRADES ARE ASSIGNED, so a reader can disagree with them.**  A row is
**PROVEN** when its parameters come from `PAGE1/3` or `PAGE3/3`, whose read-back
order is fixed by a counter the code increments once per reply AND pinned at eight
separate points by the field editors (section 2b); or from a control with its own
dedicated editor (`p13`, `p11`).  A row is **STRONG** when the parameter comes from
`PAGE1/2` or `PAGE2/2`, where the same counter mechanism applies but no editor
binding was found to pin it -- with two mitigations: `PAGE2/2` is a SINGLE request
with count 3 whose three reply bytes are copied to indices 0,1,2 in buffer order,
and `PAGE1/2`'s index 0 is pinned independently, because the code that consumes it
performs exactly the `/5` split the `P0SITI0N` editor performs.  So the STRONG rows
are `0x0000` (`RESO MODE`, from `PAGE3/3` but naming a bit whose consumer is a
different register), `0x0240` (`DEPTH`, from `PAGE1/2`) and `0x0300`
(`INTERACTION GAIN`, from `PAGE1/2`).  ⚠ Inside `0x00C0`, `P0SITI0N` is PROVEN and
the `WIDTH`/`SPEED`/`S/H`/`TOUCH` and `FORMANT` parts of the cell are STRONG; the
row is graded by its principal name.

### 4a. Why `0x03C0` / `0x0480` cannot be named, and why that is an answer

`p15` = `Q[+0x0F]` is clamped to 44..96 and indexes both curve tables
(`0xFC4964`-`0xFC49A4`).  **No sender in prom_a ever passes parameter `0x0F` with
an arm-4 selector.**  prom_a has twenty tone-message builders (the twenty callers
of `sub_FD6132`, `0xFD616A` through `0xFD686B`); across every call site of all
twenty, exactly ONE pushes `0x0F` in the parameter slot -- `0xFD5F12`, with
selector `0x00`, which is the 300-byte part record on a different screen.

`p15` sits inside the block `ToneStage_ApplyWaveSelTailPreset` overwrites when the
RESONATOR TYPE changes (bytes 13..42).  ⚠ The old note said "84 in 123 of 133
records"; that denominator is `dev104_topology_probe.py`'s **filtered** 133-record
set, which the sibling lane has since shown selects on a property of ELEMENT
BLOCKS.  Over the corpus of section 4b, p15 takes **six** values,
`{51, 53, 65, 67, 70, 84}`, and its bit 7 is clear in all 392 -- i.e. it always
lies inside the 44..96 clamp the packer applies, and it is not a constant.  The
argument does not need it to be: what makes `0x03C0`/`0x0480` unnameable is that
no editor writes p15, not what its values are.  So it is **a preset constant, not a control**, and the three
unassigned captions `DEPTH`, `FORMANT` and `INTERACTION GAIN` were never candidates
for it.  The old note's 3! six-way choice was a false dilemma: the three captions
belong to p14, p14 bit 7 and p19, and `0x03C0`/`0x0480` belong to none of them.

### 4b. ⚠ THE FACTORY DATA, WITH ITS DENOMINATOR STATED

Every rate below is over **one** population, and the definition is part of the
number: the **392 wave-select records** `notes/wsa1_tone_record_probe.py --wavesel`
reaches from the **223 melodic tone records** prom_d's 17-byte-name chain yields on
a `217 + 124*N` stride.  ⚠ That is a FILTERED population too -- it is melodic
tones only, and it is not the sibling lane's loose 459-tone set.  A rate quoted
through it is a rate about melodic factory tones and nothing wider.

| parameter | field | over 392 melodic wave-select records |
|---|---|---|
| p11 whole byte | `RESONATOR TYPE` + `GROUP` | only `{0x00, 0x40, 0x80}` -- bit 7 set in 13.  Never `0xC0`, which is exactly the three values the MODELING top's `GROUP` encoder can emit (section 1a) |
| p14 bit 7 | `FORMANT` | set in **293** of 392 -- `MOVE` in 293, `FIX` in 99 |
| p14 bits 0-6 | `DEPTH` | 12 distinct values |
| p15 | (no editor field) | `{51, 53, 65, 67, 70, 84}`, bit 7 clear in all 392 |
| p19 | `INTERACTION GAIN` | `{0, 50, 70, 80, 90, 100, 127}` |
| p21 / p31 bit 7 | `RESO MODE` | ⚠ set in **0** of 392 |
| p22 / p32 bit 7 | `RESO SCALE` | set in **346** of 392 |
| p33 | `SUB GAIN` | `{0, 70, 80, 100}` |
| p36 | `SUB GAIN` touch | 0 in all 392 |

⚠ **The `RESO MODE` row is a limitation of this population, NOT a finding.**  Zero
of 392 does not say the control is unused; it says this corpus contains no tone
that uses it, and the sibling lane's wider census finds tones outside it.  Nothing
in this note rests on that row.  ★ The `GROUP` row, by contrast, is a real check:
the encoder at `0xFD422B` can produce `0x00`, `0x40` and `0x80` and never `0xC0`,
and the factory data contains exactly those three and never `0xC0`.

### 4c. ★ `INTERACTION GAIN` and the `0x0300` gate -- the sibling lane's result, reconciled

The sibling lane reports that register `0x0300` is a **part-level mode enable**,
zero unless some element has a non-zero mode, and that the eight factory tones
which open it are all pads.  ⚠ The "mode" it means is **bits 7:6 of `Q[+0x0B]`** --
the field section 1a shows is the MODELING top's **`GROUP`**, not `RESO MODE`.  The
two readings then fit together exactly:

* `0x0300`'s VALUE is `Curve_Exp2Gain_U8_128[p19]`, and p19's caption is
  **`INTERACTION GAIN`** (section 3a, five-of-five row alignment);
* `0x0300` is zero unless word 0's bits 6:4 are set, i.e. unless something is
  enabled at part level;
* the control that is a part-level, multi-element enable is `GROUP`, and the
  MODELING top's own bottom legend names its five columns
  `ON/OFF  GROUP  DRIVER  RESONATOR  INTERACTION`.

**A gain that only exists once layers are grouped, on a screen whose grouping
control decides which layers interact, captioned `INTERACTION GAIN`.**  That gives
the name a mechanism as well as a caption, which is why section 4 grades `0x0300`
STRONG rather than WEAK.  ⚠ What is NOT traced here is the path from p11 bits 7:6
to word 0's bits 6:4 -- section 6 still lists that as open, and this paragraph is a
reconciliation of two measurements, not a third one.

### 4d. `FORMANT` = `FIX`/`MOVE`, and the packer uses that exact bit -- PROVEN

`Pack104_StageRegs_00C0_0100_0240` reads the tone record's byte `+0x0E` and tests
**bit 7**:

```
    0xFC4A03  ld XWA,(XBC+0x01)          the tone record
    0xFC4A06  ld C,(XWA+0x0e)            p14
    0xFC4A09  and C,0x80                 bit 7
    0xFC4A0C  jr NZ,0xfc4a1f             set  -> SKIP the key-follow term
    0xFC4A15  ld WA,(XBC+0x0e)
    0xFC4A18  ld IY,0x4280               note 66, the pivot
    0xFC4A1B  sub IY,WA / add HL,IY      clear -> ADD it
```

and `PartRec_SetPositionOffset_0003` takes the **other** half of the same byte,
explicitly masked, to register `0x0240`:

```
    0xFC5B20  ld C,(XIX+0x0d)  ...  -> P[+0x20]   p13, register 0x00C0
    0xFC5B2F  ld C,(XIX+0x0e)
    0xFC5B32  res 0x07,C                          p14 bits 0-6
    0xFC5B3E  ld (XWA+0x22),BC  ...  -> P[+0x22]  register 0x0240
```

★★ Two consumers, split at exactly the bit the UI splits it at, and the behaviour
matches the caption: `FIX` means the resonator position does **not** follow the
key, `MOVE` means it does.  A formant that is fixed or moves with the note is what
that control is for.

### 4e. `RESO MODE` = an octave, and register `0x0000`'s top two bits

`Pack104_UnpackWaveSelRec_ToSubRecord` tests p21 bit 7 and p31 bit 7 and does two
things with each:

```
    0xFC4873  ld A,(XBC+0x15) / and A,0x80        p21 bit 7
    0xFC4884  set 0x0f,HL  -> R[+0x07]            register 0x0000 bit 15
    0xFC4897  add HL,0x0c00 -> R[+0x0E]           the MAIN tuning delta
    0xFC48A5  ld A,(XBC+0x1f) / and A,0x80        p31 bit 7
    0xFC48B6  set 0x0e,HL  -> R[+0x07]            register 0x0000 bit 14
    0xFC48C9  add HL,0x0c00 -> R[+0x10]           the SUB tuning delta
```

The pitch word's LSB is 1/256 semitone
(`FINDINGS-prom_c-dev10c-register-meanings.md` section 2), so `0x0C00` = 3072/256
= **12 semitones, exactly one octave**.  So `RESO MODE` ON both raises a mode bit
in register `0x0000` and transposes that resonator up an octave.  GRADE **STRONG**
for the name (a drawn caption on the same row as the value, plus the two
consumers); **PROVEN** for the arithmetic.

---

## 5. THE FOUR QUESTIONS, ANSWERED PLAINLY

1. **MAIN/SUB: CORROBORATED, and the evidence is independent of `SUB GAIN`.**
   Section 3c.  The chain is: the paint routine for screen `0xA5` draws both the
   value list and the `MAIN RESONATOR` / `SUB RESONATOR` row labels; the SED1330's
   own line stride puts the two value rows 4 display rows under those two labels,
   with equal offsets; and the ENTER routine's request order -- controlled by two
   of the eight editor bindings, and by six more on `PAGE3/3` -- puts p21/p22/p29/p30
   on the MAIN row.  p33 and p36 play no part.  **The old direction stands; nothing
   in the three artefacts needs swapping.**
2. **`DEPTH` / `FORMANT` / `INTERACTION GAIN`: RESOLVED, but not onto the blocks the
   question expected.**  `DEPTH` = p14 bits 0-6 -> `0x0240`; `FORMANT` = p14 bit 7
   -> the key-follow gate of `0x00C0`; `INTERACTION GAIN` = p19 -> `0x0300`.
   `0x03C0` and `0x0480` are **not** any of the three: their only input, p15, is a
   preset byte with no editor field, and the ROM therefore cannot name them.
3. **`SCALE`: FOUND.**  The fifth column of `PAGE1/3`, headed `RESO` over `SCALE`
   at pixel x 210, value at x 208, drawn `OFF`/`ON ` from the 2x3 table `0xF034D8`:
   **bit 7 of p22 (MAIN) and bit 7 of p32 (SUB)**.  ⚠ The old note read that page's
   header as five words `FITTING MUTING KEY SHIFT TUNE SCALE`; the stacking is
   `FIT`/`TING`, `MUT`/`ING`, `KEY`/`SHIFT`, `DE`/`TUNE`, `RESO`/`SCALE`, so column
   4 is **`DETUNE`** and column 5 is **`RESO SCALE`**.  ⚠ What the packer does with
   p22 bit 7 is **NOT** established here: the `0x0340`/`0x0400` index chain reads
   p22 only through `R[+0x1A]`, and this lane did not find that field's writer.
4. **`FITTING`/`MUTING`: CORROBORATED, by a second route.**  `PAGE1/3`'s own column
   headers put `FITTING` at pixel x 49 over the field at x 48 -- p21/p31 -- and
   `MUTING` at x 86 over the field at x 88 -- the byte derived from p22/p32.  And
   `PAGE2/3`'s legend `FITTING MUTING SUB-GAIN` puts p23 in the first column and
   p24 in the second, which prom_c routes to `depth_v1` (the `0x0140`/`0x01C0`
   chain) and `depth_i3` (the `0x0340`/`0x0400` chain) respectively.  Neither uses
   the `0xF02DFB` caption block the old argument rested on.

---

## 6. WHAT REMAINS OPEN

* **Register `0x0000` bits 6:4**, which gate `0x0300` (`INTERACTION GAIN`).  The old
  note's section 7 already retracted `0xFC4D27`/`0xFC7DE9` as their writers.  The
  MODELING top's `GROUP` column is now the named lead (section 4c): the sibling
  lane measured that `0x0300` opens only when some element's `Q[+0x0B]` bits 7:6
  are non-zero, and `0xFC5B48` reads `P[+0x01]` bits 7:6 and branches three ways.
  What is still missing is the instruction that carries those bits into word 0
  bits 6:4.
* **What p22 bit 7 (`RESO SCALE`) does to the coefficients.**  It reaches
  `R[+0x1A]` (`index_bias_A`), whose writer this lane did not locate.  Until that is
  found, `RESO SCALE` is a named control with no traced effect.
* **Where the DATA-dial edit for `DEPTH`, `FORMANT`, `INTERACTION GAIN`, `WIDTH`,
  `SPEED`, `S/H`, `TOUCH`, `FITTING`, `KEY SHIFT`, `DETUNE`, `RESO SCALE` and
  `RESO MODE` lives.**  The two `MUTING` editors clamp their value to 0..0x7F
  (`ld (XIX+0x06),0x7f` at `0xFD4C15`), so they cannot be the thing that toggles
  `RESO SCALE`; something else sets bit 7 of p22/p32.  The whole
  region `0xFD40B6-0xFD5B5E` contains editors for only `RESONATOR TYPE`, `GROUP`,
  `P0SITI0N`, the two `MUTING` values and the six key-follow notes; the other
  fields must be written from somewhere this pass did not find.  ⚠ This does not
  weaken anything above -- the read-back order is the map, and it is controlled
  eight times -- but it is a hole in the coverage and is stated rather than papered
  over.
* **`sub_FD61CF`'s byte 3 is a COUNT** (3 on `PAGE2/2`, 1 elsewhere, 2 and 3 on the
  MODELING top).  That reading is what makes `PAGE2/2`'s single request return
  p16/p17/p18; the reply's own layout on the CPU 2 side was not read, so
  `PAGE2/2`'s three-way split is graded **STRONG**, not PROVEN.
* **The eight remaining 43-byte-record parameters** -- p0, p1, p2 (read by the
  MODELING top with count 3), p12 and p20 -- still do nothing this image reads.

---

## ★ CORRECTIONS AND CLOSURES CARRIED IN, 2026-09-04 (lane `w23/reso-scale`)

⚠ Nothing above this heading is edited.  Both items §6 left open are now answered,
and one sentence of §5 item 3 is RETRACTED.  Full argument, censuses and nulls:
`notes/FINDINGS-l7a1429-reso-scale.md`; probe
`notes/w23_reso_scale_and_group_chain.py` (`--selftest`: FAILURES: 0).

| this note says | where | what is true now |
|---|---|---|
| "the `0x0340`/`0x0400` index chain reads p22 only through `R[+0x1A]`, and this lane did not find that field's writer" | §5 item 3, §6 | ⚠ **RETRACTED.**  Two different records have a `+0x1A`: `index_bias_A` is **`P[+0x1A]`**, not `R[+0x1A]`.  Its writers are nine sites in three routines, and **all nine apply `res 0x07` to p22 before using it** — so `RESO SCALE` never reaches the muting index at all.  A struct field name is not an address |
| "`RESO SCALE` is a named control with no traced effect" | §6 | **TRACED.**  Bit 7 of `Q[+0x16]`/`Q[+0x20]` is read at exactly two instructions in the whole of prom_c, `0xFC4E2B` and `0xFC4EDA`, and it selects the delta term of registers **`chan+0x0040`** and **`chan+0x0080`** — the MAIN/SUB resonator TUNING words.  `ON` adds back `voice[+0x08] − voice[+0x06]`, the last stage of `Voice_ComputePitch`, so the resonator tracks the RAW key; `OFF` leaves it on the pitch the wave is played at.  PROVEN for the arithmetic, STRONG for that reading |
| "what is still missing is the instruction that carries [p11 bits 7:6] into word 0 bits 6:4" | §6 | **CLOSED**, eight hops, every one an asserted instruction: `ToneMsg_Dispatch` write arm 4 → `ToneMsg_WriteWaveSelectParam` stores the byte at `0x0087D2+0x21D+43*elem+param` → `Part_GetWaveSelectRecord`'s staged arm returns that same address → `Pack104_LoadElementWaveSelRec` binds it as `P[+0x03]` → `Pack104_DispatchByResoMode_ForPart` folds `Q[+0x0B] & 0xC0` → `P[+0x07]` bits 6:4 → staging word 0 → the `and WA,0x0070` gate |
| §4b quotes `346 of 392` for `RESO SCALE` | §4b | still correct **for that population**.  Over the loose 459-record set it is **403 / 459 = 87.8 %**, and over the strict 133 it is 128 / 133.  ★ MAIN and SUB disagree in only **3 of 459**, so in the factory bank the control is almost a per-tone switch even though the register path is per-resonator |

★ **The register NAME table in §4 is unchanged**, and `notes/l7a1429_crosscheck.py`
PASSes: this lane adds a mechanism to `0x0040`/`0x0080` and a producer chain to
`0x0000` bits 6:4, and renames nothing.

★ **The third §6 item — where the DATA-dial editors live — was closed in parallel
by the sibling lane `w23/dial-editors`** (`notes/FINDINGS-l7a1429-field-editors.md`).
`RESO SCALE`'s is `ToneEditField_A5_ResoScale` at `0xFD4EFB`, parameter `0x16`/`0x20`
with MASK `0x01` and SHIFT 7, limits 0..1 — so this note's identification of the
field is now confirmed by the editor's own descriptor as well as by the caption and
the column geometry.  ⚠ That lane also corrects §6's *reason*: `ld (XIX+0x06),0x7f`
at `0xFD4C15` is the descriptor's MASK, not a clamp; the bounds are at `+0x08`/`+0x09`.
