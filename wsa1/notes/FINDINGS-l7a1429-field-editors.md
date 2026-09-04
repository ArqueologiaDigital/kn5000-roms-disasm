# The tone editor's FIELD EDITORS -- all of them, with their limits and step

Lane `w23/dial-editors`, 2026-09-04.  This closes the hole
`FINDINGS-l7a1429-editor-pages.md` section 6 states in its own words:

> **Where the DATA-dial edit for `DEPTH`, `FORMANT`, `INTERACTION GAIN`,
> `WIDTH`, `SPEED`, `S/H`, `TOUCH`, `FITTING`, `KEY SHIFT`, `DETUNE`,
> `RESO SCALE` and `RESO MODE` lives.**  [...] The whole region
> `0xFD40B6-0xFD5B5E` contains editors for only `RESONATOR TYPE`, `GROUP`,
> `P0SITI0N`, the two `MUTING` values and the six key-follow notes; the other
> fields must be written from somewhere this pass did not find.

**All twelve are found, in that same region.**  So are five more the old note
did not list as missing: `MUTING SLOPE`, `SUB GAIN`, and the `FITTING`,
`MUTING` and `SUB GAIN` touch depths.  Twenty-four editor routines in total,
carrying **33 `(screen, RAM index, parameter)` bindings**, and every one of the
33 agrees with the read-back-order page map.  **Zero contradictions.**

Everything below is re-derived from `original_ROMs/wsa1_prom_a.ic12` by one
committed script (framing from the committed `*.unidasm`; no `.s` file is an
input):

```
cd <tree>/wsa1
python3 notes/wsa1_toneedit_field_editors.py            # sections 1-6, printed
python3 notes/wsa1_toneedit_field_editors.py --raw      # + every handler's call trace
python3 notes/wsa1_toneedit_field_editors.py --selftest # FAILURES: 0   (61 checks)
```

Tool README: `notes/README-w23-lsi-field-editors.md`.
Source edits: `notes/w23-lsi-field-editor-renames.map` plus 24 new labels; see
section 8.

---

## 0. WHY THE PREVIOUS PASS COULD NOT SEE THEM

Two shapes, both of which defeat a census keyed on the six that were found.

**No editor is called.**  Not one of the 24 is the target of a `call` or
`calr` anywhere in the image -- which is exactly why the converted source had
no label for any of them.  Each is an entry in a **table of handler pointers**
that a per-screen dispatcher indexes with the panel event code:

```
    ldb  C,0x04
    mul  (XIZ-4),C          ; the event index, times 4
    extz XBC
    add  XBC,0x00FCF974     ; a literal, one per screen
    ld   XBC,(XBC)
    lda  XIY,<return>
    push XIY
    jp   (XBC)              ; <-- the computed call
```

prom_a has **thirty** sites of that exact shape (the script finds them by byte
pattern, `find_dispatchers`).  Each owns a 17-entry table followed by a NULL
sentinel -- 30 of 30 sentinels present.  Seven consecutive tables,
`0xFCF974 + 0x48*k` for k = 0..6, belong to the tone editor's MODELING screens.

**And most editors do not write the tone message themselves.**  The six the old
pass found expand `ToneEdit_ApplyStep` + `sub_FD616A`/`sub_FD6704` inline.
Eighteen of the others hand the identical work to **one shared routine**,
`ToneEdit_CommitField` (`0xFD7435`), which takes the RAM index and the
parameter number as ARGUMENTS.  Three more use a second shared routine,
`ToneEdit_CommitNoteField` (`0xFDA3E2`).  An `ld`-pattern census of the inline
form finds none of them.

⚠ Three of the editors also reach `Arr27A6_Get` through a helper address parked
in a register -- `lda XIX,0xFD6C7B / lda XIY,<ret> / push XIY / jp T,XIX` --
which matches no `call` pattern either.  The script models that form; without
it, `0xFD5732`, `0xFD5883` and `0xFD5A0E` read as having no arguments at all.

---

## 1. THE EDIT DESCRIPTOR -- where a limit and a step come from.  PROVEN

Every editor builds the same 11-byte struct and hands it to
`ToneEdit_ApplyStep` (`0xFD6CE1`), directly or through one of the two commit
routines.  `ToneEdit_ApplyStep` and its two workers `ToneEdit_ApplyStep_Unsigned`
(`0xFD6D21`) and `ToneEdit_ApplyStep_Signed` (`0xFD6DD4`) read it as:

| byte | meaning |
|---|---|
| `D[0]` | the PACKED byte the field lives in, fetched from `((u8 *)0x27A6)[index]` |
| `D[3]` | OUT: the new packed byte |
| `D[6]` | **MASK** -- `ToneEdit_ApplyStep` returns 0 (refuses) if it is zero |
| `D[7]` | **SHIFT** -- refused if > 7 |
| `D[8]` | **MAX** |
| `D[9]` | **MIN** -- if bit 7 is set, the SIGNED worker is used |
| `D[10]` | **STEP** -- signed; refused if zero |

and the arithmetic is

```
    field  = (D[0] >> D[7]) & D[6]
    field += D[10], clamped to [D[9], D[8]]
    D[3]   = (D[0] & ~(D[6] << D[7])) | (field << D[7])
```

(`0xFD6D32`-`0xFD6DC9` unsigned, `0xFD6DE5`-`0xFD6E6x` signed; `sub_FD6C94` is
`v << n` by a doubling loop and `sub_FD6CBA` is `v >> n`.)

**So MASK, SHIFT, MIN and MAX are immediates inside each editor**, and they are
this note's answer for a field's limits.  GRADE **PROVEN**: they are read from
the ROM and consumed by code read from the ROM, with no interpretation between.

### 1a. ⚠ A CORRECTION owed to the old note

`FINDINGS-l7a1429-editor-pages.md` section 6 says:

> The two `MUTING` editors clamp their value to 0..0x7F
> (`ld (XIX+0x06),0x7f` at `0xFD4C15`), so they cannot be the thing that
> toggles `RESO SCALE`

The conclusion is right; the reading of the instruction is not.  `+0x06` is the
**MASK**, not the clamp -- the bounds are `+0x08`/`+0x09`.  For the `MUTING`
editor they happen to be `0x7F`/`0x00` as well, so nothing downstream moves.
The distinction matters because it is what makes a bit-field editor possible at
all: `ToneEditField_A5_ResoScale` (`0xFD4EFB`) is the *same* parameter `0x16`
with MASK `0x01` and SHIFT `7`.

### 1b. THE STEP.  PROVEN

`ToneEdit_StepFromEvent` (`0xFD7C2D`) writes `D[10]` from the one byte a
handler is passed:

```
    0xFD7C35  ld C,(XIZ+0x08) / res 7,C
    0xFD7C3D  jr NZ  ->  D[10] = 0xFF   (-1)
              else       D[10] = 0x01   (+1)
    0xFD7C4A  and C,0x80
    0xFD7C51  jr NZ  ->  muls C,0x03    (so -3 or +3)
```

That byte is built by `PanelEvent_ToFieldIndex` (`0xFD7905`): **bit 0** is set
from bit 15 of the event's 16-bit payload (clear = up, set = down), and **bit
7** is set for panel event codes `0x11`-`0x18`, which are the same eight field
slots reached again through a second key group.

**STEP is therefore +/-1, or +/-3 for the coarse group**, for every field on
every page.  GRADE **PROVEN** for the arithmetic.  ⚠ *Which physical control*
is the fine group and which the coarse is **UNIDENTIFIED** -- this pass did not
trace the panel scan that produces the event code.

### 1c. THE COMMIT.  PROVEN

`ToneEdit_CommitField(screen, ramIndex, layer, param, D)`:

```
    if (!ToneEdit_ApplyStep(D)) return 0;
    m = sub_FD6C94(D[6], D[7]);                    // mask << shift
    (0x27F5) ? sub_FD6704(layer, param, &D[3], m)  // drum kit
             : sub_FD616A(layer, param, &D[3], m); // melodic
    Arr27A6_Set(ramIndex, D[3]);
    T_Dispatch_Code80(screen, ramIndex);
    return 1;
```

The screen code it is handed is a literal in the editor -- which is what binds
an editor to a page.  **No adjacency argument is used anywhere in this note.**

---

## 2. THE TWENTY-FOUR EDITORS

`p<N>` is arm-4 tone-edit parameter N = wave-select byte `+0x0N`.  Screen code
`0xC0+k` is the same entry as `0xA0+k` (established in the old note's section
2c).  "key" is the slot in the screen's dispatch table.

### 2a. `MODELING top` (screen `0xA0`, table `0xFCF974`)

| key | editor | field | parameter | mask/shift | limits | step |
|---:|---|---|---|---|---|---|
| 5 | `ToneEditField_A0_ResonatorType` `0xFD414E` | `RESONATOR TYPE` | p11 bits 0-5 | `0x3F`/0 | **0..63** | 1 |
| 6 | `ToneEditField_A0_Group` `0xFD422B` | `GROUP` | p11 bits 7:6 | (bespoke) | **0..4** | 1 |

Both were already known.  `RESONATOR TYPE`'s `0..63` bound is new here, and it
matches the 64-name table at prom_b `0xF03241` exactly.

### 2b. `PAGE1/2  P0SITI0N PARAMETER` (screen `0xA3`, table `0xFCF9BC`)

| key | editor | field | index <- parameter | mask/shift | limits | step |
|---:|---|---|---|---|---|---|
| 1 | `ToneEditField_A3_Position` `0xFD44C7` | `P0SITI0N` | 0 <- p13 | `0xFF`/0 | **0..250** | 1 |
| 2 | `ToneEditField_A3_Depth` `0xFD45B0` | **`DEPTH`** | 1 <- p14 | `0x7F`/0 | **0..127** | 1 |
| 3 | `ToneEditField_A3_Formant` `0xFD4626` | **`FORMANT`** | 1 <- p14 | `0x01`/**7** | **0..1** | 1 |
| 5 | `ToneEditField_A3_InteractionGain` `0xFD469C` | **`INTERACTION GAIN`** | 2 <- p19 | `0x7F`/0 | **0..127** | 1 |

★ `0..250` in steps of 1, drawn as `p13/5 . 2*(p13%5)`, is `0.0` to `50.0` in
`0.2` -- the old note's `POSITION` scale, re-derived from the editor's own
`MAX = 0x00FA`.

### 2c. `PAGE2/2  P0SITI0N M0VEMENT` (screen `0xA4`, table `0xFCFA04`)

| key | editor | field | index <- parameter | mask/shift | limits | step |
|---:|---|---|---|---|---|---|
| 1 | `ToneEditField_A4_Width` `0xFD4800` | **`WIDTH`** | 1 <- p17 | `0x7F`/0 | **0..50** | 1 |
| 2 | `ToneEditField_A4_Speed` `0xFD4876` | **`SPEED`** | 2 <- p18 | `0x7F`/0 | **0..50** | 1 |
| 3 | `ToneEditField_A4_SampleHold` `0xFD48EC` | **`S/H`** | 2 <- p18 | `0x01`/**7** | **0..1** | 1 |
| 5 | `ToneEditField_A4_Touch` `0xFD4962` | **`TOUCH`** | 0 <- p16 | `0xFF`/0 | **-50..+50** | 1 |

★★ These four are the strongest new result after the editors themselves.  The
old note graded `PAGE2/2` **STRONG** rather than PROVEN for one stated reason:
its three fields arrive in a SINGLE read-back request with count 3, and "no
editor binding was found to pin it".  Four editors now pin all three, one field
at a time, with the index and the parameter as separate immediates.

### 2d. `PAGE1/3` (screen `0xA5`, table `0xFCFA4C`)

Each editor here handles MAIN and SUB in one body.

| key | editor | field | MAIN | SUB | mask/shift | limits | step |
|---:|---|---|---|---|---|---|---|
| 1 | `ToneEditField_A5_Fitting` `0xFD4AC6` | **`FITTING`** | 1 <- p21 | 5 <- p31 | `0x7F`/0 | **0..127** | 1 |
| 2 | `ToneEditField_A5_Muting` `0xFD4BA4` | `MUTING` | 2 <- p22 | 6 <- p32 | `0x7F`/0 | **0..127** | 1 |
| 3 | `ToneEditField_A5_KeyShift` `0xFD4D39` | **`KEY SHIFT`** | 3 <- p29 | 7 <- p41 | `0xFF`/0 | **-60..+60** | 1 |
| 4 | `ToneEditField_A5_Detune` `0xFD4E1A` | **`DETUNE`** | 4 <- p30 | 8 <- p42 | `0xFF`/0 | **-128..+127** | 1 |
| 5 | `ToneEditField_A5_ResoScale` `0xFD4EFB` | **`RESO SCALE`** | 2 <- p22 | 6 <- p32 | `0x01`/**7** | **0..1** | 1 |

★ `KEY SHIFT` at `-60..+60` is five octaves either way, which is what a
resonator key shift measured in semitones should be.  `DETUNE` takes the whole
signed byte.

★★ `RESO SCALE` is the field the old note found by caption and by column
geometry and then had to leave with "something else sets bit 7 of p22/p32".
That something else is `0xFD4EFB`: same parameter as `MUTING`, MASK `0x01`,
SHIFT `7`, `0..1`.  The old identification is **confirmed by the editor**.

### 2e. `PAGE2/3  TOUCH DEPTH` (screen `0xA6`, table `0xFCFA94`)

| key | editor | field | MAIN | SUB | mask/shift | limits | step |
|---:|---|---|---|---|---|---|---|
| 1 | `ToneEditField_A6_FittingTouchDepth` `0xFD5171` | `FITTING` touch | 1 <- p23 | 4 <- p34 | `0xFF`/0 | **-50..+50** | 1 |
| 2 | `ToneEditField_A6_MutingTouchDepth` `0xFD5252` | `MUTING` touch | 2 <- p24 | 5 <- p35 | `0xFF`/0 | **-50..+50** | 1 |
| 4 | `ToneEditField_A6_SubGainTouchDepth` `0xFD5333` | `SUB GAIN` touch | -- | 6 <- p36 | `0xFF`/0 | **-50..+50** | 1 |
| 5 | `ToneEditField_A6_SubGain` `0xFD53CF` | **`SUB GAIN`** | -- | 3 <- p33 | `0xFF`/0 | **-100..+100** | 1 |

★★ The old note's section 3d read `SUB GAIN` = p33 and its touch = p36 from
COLUMN POSITION, and said plainly that it "does not add to the direction
argument".  Two editors now say it directly, with the index and the parameter
as immediates: index 3 is p33, index 6 is p36, and neither has a MAIN
counterpart -- which is why the MAIN row draws `--` in those two columns.

★ `SUB GAIN` is **SIGNED**, `-100..+100`.  That makes prom_c's
`register 0x0000 bit 7 <- sign(p33)` (old note section 4) a state the user can
actually reach, which it would not be if the control were unsigned.

### 2f. `PAGE3/3` (screen `0xA7`, table `0xFCFADC`)

| key | editor | field | MAIN | SUB | mask/shift | limits | step |
|---:|---|---|---|---|---|---|---|
| 1 | `ToneEditField_A7_ResoMode` `0xFD5574` | **`RESO MODE`** | 1 <- p21 | 2 <- p31 | `0x01`/**7** | **0..1** | 1 |
| 2 | `ToneEditField_A7_MutingSlope` `0xFD5655` | `MUTING SLOPE` | 6 <- p28 | 10 <- p40 | `0xFF`/0 | **-50..+50** | 1 |
| 3 | `ToneEditField_A7_KeyFollowLow` `0xFD5732` | `KEY FOLLOW` low | 4 <- p26 | 8 <- p38 | `0x7F`/0 | **0 .. break** | 1 |
| 4 | `ToneEditField_A7_KeyFollowBreak` `0xFD5883` | `KEY FOLLOW` break | 3 <- p25 | 7 <- p37 | `0x7F`/0 | **low .. high** | 1 |
| 5 | `ToneEditField_A7_KeyFollowHigh` `0xFD5A0E` | `KEY FOLLOW` high | 5 <- p27 | 9 <- p39 | `0x7F`/0 | **break .. 127** | 1 |

★★ **THE THREE KEY-FOLLOW NOTES BOUND EACH OTHER.**
`ToneEdit_CommitNoteField` (`0xFDA3E2`) is `ToneEdit_CommitField` with `MAX`
and `MIN` taken from two of its ARGUMENTS instead of from immediates
(`0xFDA400`: `(XIX+0x08) <- (XIZ+0x0e)`, `0xFDA406`: `(XIX+0x09) <- (XIZ+0x0c)`),
and the three editors pass each other's RAM cells:

```
    low   (index 4) : MIN 0                MAX Arr27A6[3]  (the break note)
    break (index 3) : MIN Arr27A6[4] (low) MAX Arr27A6[5]  (the high note)
    high  (index 5) : MIN Arr27A6[3]       MAX 127
```

so the firmware itself enforces **low <= break <= high**.  The old note read
that row's columns as `lo / break / hi / slope` = `p26 p25 p27 p28` from screen
geometry; the ordering is now **PROVEN** by the clamps, independently of any
pixel coordinate.  ⚠ Note that the LEFTMOST of the three columns (x 128) is the
LOW note and the middle (x 168) is the BREAK -- the drawn order is not
monotonic in x, so a column-order argument alone could not have settled it.

### 2g. The row-focus toggle, and one oddity worth recording

Slot 6 of `PAGE1/3`, `PAGE2/3` and `PAGE3/3` is a two-byte
`calr ToneEditPage_ToggleRowFocus / ret` in all three cases.  That routine
(`0xFD4FE0`) flips `((u8 *)0x27A6)[15]` between 0 and 1; slots 11 and 12 set it
to 1 and put the row number in `((u8 *)0x27A6)[0]`.  **When index 15 is 0 no
row is focused, and every two-row editor above applies its step to BOTH rows**,
one commit after the other -- which is the second commit each of them contains.

⚠ `ToneEditPage_ToggleRowFocus` repaints with the literal `0xC5` at `0xFD5011`,
on all three pages.  GRADE: **PROVEN** that the immediate is `0xC5` and that
the three pages share the routine; what that does on `0xA6` and `0xA7` is
**UNIDENTIFIED** -- this pass did not read prom_b's partial repaint for `0xA5`
field 0, so it is not claiming a defect.

---

## 3. THE CROSS-CHECK, AND THE FACT THAT IT COULD HAVE FAILED

Section 4 of the script's output tests every `(screen, RAM index)` an editor
carries against the parameter the old note's read-back-order map assigns to it.
The two instruments are independent: the map comes from the ORDER in which a
page's ENTER routine fires its read-back requests, and this one from immediates
inside routines the ENTER routines never touch.

```
    AGREEMENTS 33   CONTRADICTIONS 0   UNMAPPED 5
```

★ **THE CONTROL.**  `--selftest` runs the same cross-check a second time
against a page map with `MAIN FITTING` and `SUB FITTING` deliberately swapped,
and requires exactly 2 clashes to appear.  A cross-check that cannot register a
disagreement is not evidence, and this one is checked to register one.

The five "unmapped" rows are declared exceptions and the script prints the
reason for each rather than skipping it:

* `0xFD414E` `RESONATOR TYPE` -- its value lives in `((u8 *)0x2808)[layer]`,
  not in the `0x27A6` field array, so it has no RAM index to test.
* `0xFD422B` `GROUP` -- a bespoke five-state encoder, not an edit descriptor.
* `0xFD44C7` `P0SITI0N` -- it edits index 0 but then writes the DISPLAYED `/5`
  split into indices 4 and 5, so the repaint that follows names index 4.  Its
  parameter `0x0D` does match the map's index 0.
* `0xFD5C63`, `0xFD5D01` -- table `0xFCFB24` is screen `0xA8`, and both pass
  **selector 0**, the 300-byte PART record.  Their `p10`/`p11` are different
  bytes from the MODELING pages'.  ⚠ Screen `0xA8` has its own paint routines
  in prom_b (`0xF5C210` full, `0xF5CE00` partial); it is a real screen, it is
  simply not one of the seven MODELING pages, and nothing about it is claimed
  here.

### 3a. What this changes in the old note's GRADES

The old note's section 4 states its own rule: a row is **PROVEN** when its
parameters come from a page whose read-back order is "pinned at eight separate
points by the field editors", and **STRONG** when the parameter comes from
`PAGE1/2` or `PAGE2/2`, "where the same counter mechanism applies but no editor
binding was found to pin it".  Bindings now exist for both pages.  By the
note's own rule:

| register | old grade | new | why |
|---|---|---|---|
| `0x0240` `DEPTH` | STRONG | **PROVEN** | `0xFD45B0` binds index 1 <- p14 |
| `0x0300` `INTERACTION GAIN` | STRONG | **PROVEN** | `0xFD469C` binds index 2 <- p19 |
| `0x00C0` `WIDTH`/`SPEED`/`S/H`/`TOUCH` | STRONG parts | **PROVEN** | `0xFD4800`/`0xFD4876`/`0xFD48EC`/`0xFD4962` bind indices 1, 2, 2, 0 |
| `0x0000` `RESO MODE` | STRONG | **PROVEN** for the field | `0xFD5574` binds index 1 <- p21 bit 7 and index 2 <- p31 bit 7 |

⚠ No register NAME changes, so `notes/l7a1429_crosscheck.py` is unaffected; it
was run and is green.  What changes is the confidence, not the answer.

---

## 4. THE NEGATIVE, AND WHAT WAS SEARCHED FOR IT

**No MODELING editor writes wave-select byte `+0x0F`.**  Over the six MODELING
dispatch tables, 24 editors and every path through them, the parameters that
appear are

```
    edited:      0B 0D 0E 10 11 12 13 15 16 17 18 19 1A 1B 1C 1D 1E 1F 20
                 21 22 23 24 25 26 27 28 29 2A          (29 distinct)
    NOT edited:  00 01 02 03 04 05 06 07 08 09 0A 0C 0F 14
```

This is an **independent** confirmation of the old note's section 4a, which
argued the same thing from the other end -- by censusing the twenty tone-message
builders' call sites.  So registers `0x03C0` and `0x0480`, whose only input is
p15, still have no editor name, and now for a second reason.

⚠ **The forms this pass searched, so that the negative can be checked.**  A
negative that does not say what it looked for cannot be disagreed with:

1. **A direct `call` / `calr` to the routine.**  Searched the whole image: none
   of the 24 editors is a call target, which is why none had a label.
2. **A table of handler pointers indexed by a computed offset.**  FOUND -- this
   is the mechanism.  Every `add XBC,imm32` (opcode `E9 C8`) in prom_a was
   enumerated and filtered by the surrounding `ldb C,4 / mul / extz XBC` and
   `ld XBC,(XBC) / lda XIY / push XIY / jp (XBC)`: 30 sites, 30 tables, 30 NULL
   sentinels.
3. **A shared routine parameterised by the field index.**  FOUND, twice:
   `ToneEdit_CommitField` (18 editors) and `ToneEdit_CommitNoteField` (3).
4. **A base spilled to a frame slot and indexed from there.**  Searched: all 30
   dispatch bases are `add XBC,<literal>`; none is loaded from memory.
5. **`TABLE - 4*k`, a negative index.**  Searched: all 30 sites add
   `index*4`, and `PanelEvent_ToFieldIndex` bounds the index to 0..16 by its
   own range tests (`cp DE,0x0010` / `0x0011`..`0x0018` / `0x0019`).
6. **A computed call through a register loaded elsewhere.**  FOUND, a second
   variety: `lda XIX,0xFD6C7B / lda XIY,<ret> / push XIY / jp T,XIX` inside
   `0xFD5732`, `0xFD5883` and `0xFD5A0E`.  The script models it; without that,
   those three read as taking no arguments.
7. **A raw-byte pseudo-instruction whose operands are unmodelled.**  The walk
   over all 24 editors steps only to addresses the committed unidasm listing
   frames, and asserts that (`walk` raises otherwise); no body contains an
   undecoded run.
8. **An editor for a MODELING field living in one of the OTHER 23 tables.**
   Searched: section 6 of the output is a negative control over all 30 tables,
   and no handler outside the seven MODELING tables repaints a MODELING screen
   code.

---

## 5. WHAT REMAINS OPEN

* **Which physical control is the fine key group and which the coarse.**  The
  `x3` step exists and is proven; the panel scan that produces event codes
  `0x11`-`0x18` was not read.
* **What `ToneEditPage_ToggleRowFocus` does on screens `0xA6`/`0xA7`**, given
  that it repaints with the literal `0xC5`.
* **Screen `0xA8`** (table `0xFCFB24`, 8 live slots, selector 0).  It is a real
  screen with its own paint routines, and this pass says nothing more about it.
* **What p22 bit 7 (`RESO SCALE`) does to the coefficients.**  Unchanged from
  the old note: the editor is now known, the consumer is still not.
* The `MODELING top`'s slots 0, 1, 2 and 12 (`0xFD3FE0`, `0xFD4039`,
  `0xFD40D4`, `0xFD4468`) are a per-layer ON/OFF toggle and two list selectors
  that are not edit-descriptor editors.  They are the `ON/OFF` and `DRIVER`
  columns of that page's legend; naming them is a separate hop.

---

## 6. SOURCE EDITS

`prom_a/wsa1_prom_a.s` only.

* **24 new labels**, one per editor, each with a header giving its dispatch
  table and slot, its `(RAM index, parameter)` bindings, its mask/shift/limits
  and its step.  These addresses had no label at all before, because nothing
  calls them.
* **15 renames**, listed in `notes/w23-lsi-field-editor-renames.map`: the seven
  MODELING key dispatchers, the row-focus toggle, and the seven shared edit
  helpers.

Both gates were run and are green:

* `make LLVM_MC=<pinned> gate-all` -- 13 of 13 images byte-identical (9 KN5000,
  4 SX-WSA1R), and the toolchain-prerequisite check 8/8 + 4/4.
* `assert_comments_preserved.py --base main --rename-map notes/w23-lsi-field-editor-renames.map`
  -- `167,359 -> 167,905 (+546)`, **every comment survives, in order,
  unaltered**.

`notes/l7a1429_crosscheck.py` was also run (no register NAME changes here) and
reports `PASS: the four documents agree`.
