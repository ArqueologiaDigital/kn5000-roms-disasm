# PREDICT_221 — `§E1`, the epilogue/handover OPERAND-PROVENANCE census, run ON THE `NOZ05` RIG

**Committed BEFORE `build.sh` was run and before any arm was launched.**
Scored against `dsp/analysis/OUTPUT-STAGE-NULL_findings.md` §6 (`§E1`), whose falsifiers `F1`/`F2`/`F3`
are reproduced here with their numbers, and against `SPECULATIVE-APPLIED-REGISTER.md` §220.

★ **`§216`/`§220` GUARANTEE THIS TASK CANNOT PRODUCE AUDIO.** Grade it on **provenance** and on
`§104`. Never by listening, never on `§70`/`§211` moving. `§70`/`§211` appear here only as a
**standing-rule-1 control that must stay at `min == max == 0`** (`R1`).

⚠ **`UPD6383_NOZ05` is a RIG, NOT A FIX.** It deletes two stores the corpus says are there and its
cell `0x05` **rails** in the quiet window (`§86 [8 388 607 .. 8 388 607]`). Nothing it rails on is
evidence, and nothing here proposes shipping it.

---

## 0. WHY RUN `§E1` NOW, AND WHY THE RIG CHANGES WHAT IT MEANS

`§E1` was designed by `OUTPUT-STAGE-NULL_findings.md` when body 0 was **dead** (`0/0/0`
input-dependent `§104` slots). `§220` measured that `UPD6383_NOZ05=1` makes body 0 run its whole
ladder on live audio (`28/32/28`, slot-for-slot identical to the §215 calibration arm), fills the
delay line (`§46` non-zero reads `0 → 3 494 021`), and **still** leaves `§70`/`§211` at
`min == max == 0`.

⇒ this is the **first** time `§E1`'s falsifier `F1` is meaningful: with live signal demonstrably
reaching the bodies, "no epilogue operand traces to a body word" stops being a statement about a
starved machine and becomes a statement about **routing**.

---

## 1. THE NULL, COMPUTED FIRST, FROM LOGS THAT ALREADY EXIST

`data/A_off_220.log.gz` (shipped default) and `data/C_noz05_220.log.gz` (the rig) — `§104` rows
`54`, `60..81`, `152`, `153`, `200` are **byte-identical between the two arms**, extracted and
diffed before this document was written:

```
   every row 60..81 :  L quiet 0..0   loud 0..0   '='
   except w72 (000.1.06.087) : L quiet 4194304..4194304   loud 4194304..4194304   '='
   handover 54 / 152 / 153 / 200 : L 0..0 in both buckets, both arms
   §70  ACCA at w73 : quiet 726040 min 0 max 0 | loud 313960 min 0 max 0   (both arms)
   §211 ACCB at w78 : quiet 726040 min 0 max 0 | loud 313960 min 0 max 0   (both arms)
   §61  unit0/DO1 1203840 exec, 0 non-zero, peak 0 | unit1/DO2 1203840 exec, 0 non-zero, peak 0
   SRC CODES STILL READING ZERO: 0x01:1204800 0x05:1205760 0x06:1204800 0x0A:1203840
```

### 1.1 ⚠ `§104`'s `L` COLUMN IS **STICKY** — `§E1` MEASURES A SMALLER SET, AND THAT IS CORRECT

`§104` records `m_last_l`, a member that **retains the previous word's operand** when a word never
reaches the bus. So "21 of 22" counts 22 `§104` rows, not 22 operand fetches.
`§E1` hooks the **fetch itself** (`upd6383.cpp`, the statement `m_last_l = L;`), so it sees only the
slots that actually evaluate a source.

Derived statically from `upd6383d.h`'s own predicates (`dsp/tools/e1_pred.py`, committed with this
file) over `exec_alu()`'s early-return ladder:

```
  iw   word        hi12 cl ad8 lo12 SRC ACT f31  fetch?  why
  60   009218D15B  092  1  8D 15B   05  1B   1     Y     speculative fallthrough
  61   001218D05B  012  1  8D 05B   01  1B   1     Y
  62   0801026825  801  0  26 825   -   -    -     n     lo12 bit 11: alternate encoding
  63   02A79051C3  2A7  9  05 1C3   07  03   3     Y
  64   0C40A80445  C40  -  -  445   -   -    -     n     C-FORMAT
  65   020018F1C1  200  1  8F 1C1   07  01   0     Y
  66   000018C107  000  1  8C 107   04  07   0     Y
  67   0980520402  980  5  20 402   -   -    -     n     class 5 -> "NOP / no modelled side effect"
  68   009218C19B  092  1  8C 19B   06  1B   1     Y
  69   0801090821  801  0  90 821   -   -    -     n     lo12 bit 11
  70   02A61850C7  2A6  1  85 0C7   03  07   3     Y
  71   0C41900446  C41  -  -  446   -   -    -     n     C-FORMAT
  72   0000106087  000  1  06 087   02  07   0     Y     <- THE CALIBRATION
  73   0E30C00404  E30  C  00 404   10  04   0     Y     <- F2, unit-0 PRESENTATION
  74   0C169AB000  C16  -  -  000   -   -    -     n     C-FORMAT
  75   082E80F000  82E  8  0F 000   00  00   7     Y
  76   0C00984000  C00  -  -  000   -   -    -     n     C-FORMAT
  77   0859086822  859  0  86 822   -   -    -     n     lo12 bit 11
  78   0A3CD9F287  A3C  D  9F 287   0A  07   6     Y     <- unit-1 PRESENTATION
  79   00122FF1CE  012  2  FF 1CE   07  0E   1     Y
  80   01042001CE  104  2  00 1CE   07  0E   2     Y
  81   0102200000  102  2  00 000   00  00   1     Y
  ---- handover ----
  54   080016000B  800  1  60 00B   00  0B   0     Y     delay WRITE -> recursive exec_alu (bits 19+20)
  152  0880160000  880  1  60 000   00  00   0     Y     delay WRITE -> recursive exec_alu
  153  060210E000  602  1  0E 000   00  00   1     Y
  200  088013000B  880  1  30 00B   00  0B   0     Y     delay READ  -> recursive exec_alu
```

> **N0 (the shape of the instrument's own output).**
> **14 of the 22** slots `iw 60..81` reach the operand fetch. The **8** that do not are
> `w62 w64 w67 w69 w71 w74 w76 w77` — four C-format, three `lo12` bit-11, one class-5.
> Plus **4 of 4** handover slots (`54`, `152`, `153`, `200`) fetch.
> **⇒ 18 census rows.** A different count is a **recorded miss**, not a void: `F1` is a statement
> about the operands that exist, whatever their number.

> **N1 (restated for the fetch, not for `§104`).** Of the **14** fetching epilogue slots,
> **13 fetch `L` identically `0`** in both buckets and the 14th is `w72` at **`4 194 304`**.
> All **4** handover slots fetch `L = 0`.

> **N3.** Exactly **4** epilogue slots take the literal `default: m_src_unread[src & 0x1f]++;`
> route with **no reading at all** — `w60` (`SRC 0x05`), `w61` (`0x01`), `w68` (`0x06`),
> `w78` (`0x0A`) — at **one per frame each**, matching `SRC CODES STILL READING ZERO`.

### 1.2 THE ROUTE EACH FETCHING SLOT IS PREDICTED TO TAKE

Derived by walking the C++ with the **shipped** mask `0xb910e446a39b440f` (bits 23, 24, 25 set;
bit 0x20 = 5 **clear**, so `lvl_hit` never fires):

| iw | SRC | predicted route | predicted resolved index |
|---|---|---|---|
| 60 | 0x05 | `DEFAULT (no reading)` | — |
| 61 | 0x01 | `DEFAULT (no reading)` | — |
| 63 | 0x07 | `m_rf[idx]` (mode 1, bit 23) | `0x05` |
| 65 | 0x07 | `m_rf[idx]` (mode 1, bit 23) | `0x8F` |
| 66 | 0x04 | `tempA` | — |
| 68 | 0x06 | `DEFAULT (no reading)` | — |
| 70 | 0x03 | `ACCA` (mask bit 25) | — |
| 72 | 0x02 | `m_rf[idx]` (mask bit 24 + 23) | `0x06` |
| 73 | 0x10 | `ACCA` | — |
| 75 | 0x00 | `m_dram[m_dp]` (bit 59 arm: not a `coeff_consumer`) | `0x00` |
| 78 | 0x0A | `DEFAULT (no reading)` | — |
| 79 | 0x07 | `m_dram[m_dp]` (mode 2) | **`0x00`** |
| 80 | 0x07 | `m_dram[m_dp]` (mode 2) | `0xFF` |
| 81 | 0x00 | `m_dram[m_dp]` | `0xFF` |
| 54 | 0x00 | `m_dram[m_dp]` | `0xFC` |
| 152 | 0x00 | `m_dram[m_dp]` | `0xFC` |
| 153 | 0x00 | `m_dram[m_dp]` | `0xFC` |
| 200 | 0x00 | `m_dram[m_dp]` | **`0x85`** |

⚠ **Two of these disagree with `OUTPUT-STAGE-NULL_findings.md` §2's table, on purpose, and both
disagreements are the `iw205` correction (`e49da4b`) applied a second time:**

* §2 lists **`w79` and `w80` both reading `m_dram[0xFF]`**. The operand is fetched **before** the
  word's own post-increment, and `§104`'s `dp` column — sampled *before* the word runs — reads
  `iw79 → 00`, `iw80 → FF`, `iw81 → FF`. `w79`'s `addr8` is `0xFF` (`−1`), which is what *parks*
  the pointer at `0xFF` for `w80`. **Predicted: `w79` reads cell `0x00`, not `0xFF`.**
* `iw200`'s operand is **`D-RAM[0x85]`** — the cell `e49da4b` proved has **ZERO I-RAM writers**.
  Predicted provenance: **NONE**, i.e. never written by any word in a settled frame.

---

## 2. WHAT `§E1` MEASURES (`UPD6383_EPIBUS=1`, env, DEFAULT OFF, unconditional fired count)

**READ-ONLY. No decode change, no mask bit, no behavioural gate.** For every fetch at a watched
slot, on **settled frames only** (`m_frames_run > 900000`, standing rule 16):

1. the `SRC` code and **which route the C++ actually took** (the route is recorded *inside* the
   `switch` case that ran, not re-derived afterwards);
2. the **resolved index**;
3. the value `L`, split quiet / loud (`m_in_val[] != 0`, the same predicate `§104` uses);
4. ★ the **PROVENANCE** — the `iw` and frame of the **last write** to that (array, index) pair, and
   separately the **last write that left it NON-ZERO**. Standing **RULE 17**: provenance, not
   liveness. Sentinels: `HOST` for the tag-0x15 upload path, `IN` for the input latch deposit,
   `BOOT` for reset clears, `NONE` for never-written.

Shadow provenance tables are maintained for `m_dram[256]`, `m_rf[256]`, `tempA`, `tempB`, `ACCA`,
`ACCB` and the delay register `m_dr` (reusing `§217`'s existing `m_dr_prov_iw`). They are written
**only when the gate is on**, so the shipped build is untouched.

### 2.1 `§E1b` — THE COUNTERFACTUAL CENSUS FOR THE FOUR DECODE GAPS

For `w60`/`w61`/`w68`/`w78` the machine reads nothing, so there is no provenance to report — which
is exactly the situation `OUTPUT-STAGE-NULL_findings.md` §5.1 reasons about **statically**. `§E1b`
measures it instead: at each of the four gap slots record the value **and the provenance** of all
three candidate operands the note enumerates — `m_rf[addr8|unit]`, `m_dram[addr8|unit]`,
`m_dram[m_dp]`.

> **N5.** All twelve counterfactual operands are **constant across both buckets** and **none**
> carries a body-0 provenance. §5.1 says decoding these four sources cannot make the output stage
> input-dependent; `§E1b` is the first measurement that could contradict it.

### 2.2 RULE 19, MECHANISED IN THE INSTRUMENT

`§70`/`§211` currently print `min`/`max` only, and `OUTPUT-STAGE-NULL_findings.md` §6.5(ii)
constructs a **DC that passes both standing rule 1 and §211's translation rule**
(`w78 = 79 438 ± 90`, −59 dB). This pass adds **`mean`** and the **AC span (`max − min`)** to both
lines, so the counter-example is caught by the printout rather than by a reader remembering the
note. Read-only, always on, no behavioural change.

---

## 3. THE FALSIFIERS — two-sided, each naming a number

> ### `F1` — THE DECISIVE ONE
> **No epilogue operand (`iw 60..81`) has a provenance naming an I-RAM word inside BODY 0
> (`iw 84..153`). Predicted: 0 of 14.**
> **`F1` FAILS if ≥ 1 does** — and then `OUTPUT-STAGE-NULL_findings.md` §5.1 is **overturned**, the
> routing error is named by the instrument (word + array + cell), and **that is the better
> outcome.**
>
> ★ **`F1b`, split out so a pass is not mistaken for a fail:** provenance naming **BODY 1**
> (`iw 200..332`) is **PREDICTED to occur, at exactly one slot — `w65`, via `m_rf[0x8F]`**
> (`§99 MODE-1 STORES` reports `8F:1176000` ≈ one per frame, and `§160` reports `m_rf[0x8F]`
> absent from the non-zero list, i.e. **0**). This is the epilogue reading body 1's output register
> and finding it empty. If `w65`'s provenance is **not** a body-1 `iw`, that is a **miss** and the
> "`0x8F` links body 1 to the epilogue" reading (row 28's motivation) loses its only support.

> ### `F2` — THE PRESENTATION'S OWN OPERAND
> **`ACCA` at `w73`: the last NON-ZERO writer is a KERNEL-B word (`w53`/`w54`), on ≥ 99 % of
> settled frames, and a body-0 `iw` on 0 of them.**
> `F2` FAILS if any body-0 `iw` appears, or if the dominant non-zero producer is not in `iw 50..59`.
> A wrong `iw` number is something liveness cannot fake (RULE 17).

> ### `F3` — THE CALIBRATION THAT CAN FAIL
> **`w72` must resolve to index `0x06` with `L = 4 194 304` in both buckets.**
> **If it resolves anywhere else, or to any other value, the instrument is mis-wired and the run is
> VOID** — no other number in it may be quoted (the `§46` unguarded-sample trap, fourth occurrence).
>
> ⚠ **AND ONE HALF OF `§6.2 N2` IS PRE-REGISTERED AS A MISS.** The findings predict `w72`'s
> provenance is **HOST**. `§99 MODE-1 STORES` reports `06:1203840` — **exactly the presentation
> count, i.e. once per frame** — and `w72`'s own `ACT 0x07` stores back to `0x06` (§100's identity
> reading). **Predicted provenance: `iw72` itself, age 0, with `HOST` only as the boot-time
> initialiser (`§186 06:3`).** The *value* is the calibration; the provenance is an observation.

> ### `R1` — THE STANDING CONTROL
> `§70 ACCA at w73` and `§211 ACCB at w78` stay **`min == max == 0`**, quiet **and** loud, on the
> rig. New this pass: **`mean = 0` and `AC span = 0`** on both. Any non-zero here is reported as a
> **DC unless the mean is small relative to the AC span** (RULE 19) — and would not be an audio
> claim in any case.

> ### `cal` — THE VEHICLE
> `§54` loud ≈ **313 960** frames; `§104` `s104_score.py` body-0 columns **`28/32/28`** on the rig
> arm and **`0/0/0`** on the control. **A loud count of 0, or a rig arm that is not `28/32/28`,
> VOIDS the run.**

---

## 4. THE ARMS

| arm | environment | purpose |
|---|---|---|
| **A** | `UPD6383_EPIBUS=1` | the census on the **shipped** build — the control, and the arm the NULL above was computed for |
| **B** | `UPD6383_EPIBUS=1 UPD6383_NOZ05=1` | **the rig** — the same census with body 0 running on live audio |

One variable between them. Everything else identical.

> **N6 — the secondary question.** Does the epilogue's picture change **at all** between A and B?
> **Predicted: NO.** Every route, every resolved index, every `L` range and every provenance `iw`
> is predicted **identical**, because `§104` rows 54/60..81/152/153/200 are already byte-identical
> across `A_off_220` and `C_noz05_220`. If 13/14 stay zero while the bodies run live, the epilogue's
> null is **structural**, not starvation. If anything moves, name it.

---

## 5. THE DECISION RULE, WRITTEN BEFORE THE DATA

* **`F1` holds and `F2` holds** (the predicted outcome): the epilogue is **exonerated as a
  localisation**, exactly as `w73` was by §211. The decode gap at `SRC 0x01/0x05/0x06/0x0A` is
  **confirmed not load-bearing** and the next decode pass belongs at **body-1 `iw205`**
  (`ACT 0x0D`'s destination, mask bits 42-44, currently selector 1) and at **body-0's coefficient
  cursor at `iw112`** (`coef 0..24`, §52 / register row 25) — in that order.
* **`F1` fails**: name the word, the array and the cell. That is a routing error, it is small, and
  it is fixable — and it is the better outcome.
* **`F2` fails**: §216's null has a route after all and the whole localisation re-opens.
* **`N5` fails** (a counterfactual operand is body-0-derived and input-dependent): §5.1 is
  overturned and decoding that one source becomes the next pass.

## 6. WHAT WOULD SHIP, AND WHAT WOULD NOT

**SHIPS regardless of outcome:** the `UPD6383_EPIBUS` census (env, DEFAULT OFF, unconditional fired
count), the RULE 19 `mean` + `AC span` columns on `§70`/`§211`, `dsp/tools/e1_pred.py`, both logs,
this file, and the register section.

**DOES NOT SHIP:** any default flip, any mask bit, any decode change. `UPD6383_NOZ05` stays
**DEFAULT OFF** — §220 §6's three reasons are unchanged by anything measured here.
`dsp/verify.py` must stay **BYTE-MATCH OK**.

## 7. VEHICLE (identical to §217/§220)

`kn7000-emulator`, `-rompath ./roms -skip_gameinfo -log`, isolated `-nvram_directory`, isolated
`-cfg_directory` **carrying `:DSPCFG value="3"`**, `-pluginspath ./plugins`,
`-autoboot_script ../kn7000_mame/scratchpad/coldnotes2.lua`, `-seconds_to_run 30`,
`-window -resolution 640x480` (**never `-video none`**), `timeout`-wrapped, **one run at a time**.
