# UNWRITTEN CELLS — one shape in three subsystems, or three unrelated facts?

NEC **uPD6383GF-3BA** (Technics SX-KN5000, **IC311**). Written 2026-07-31.
**STATIC + EXISTING LOGS ONLY.** No emulator was run, no source was edited, nothing was
built, nothing was committed. Every number is read out of a log already in
`dsp/analysis/data/`, out of the ROM corpus via `dsp/tools/pat_corpus.py`, out of
`dsp/tools/register_space.py`, or out of
`kn7000_mame/src/devices/cpu/upd6383/upd6383.{cpp,h}` in the working tree.

> ★★★ **RULE 19 BY VACUITY: this pass produces NO audio quantity of any kind and makes
> no audio claim.** Every accumulator figure quoted below is quoted as a *constant*, with
> both endpoints printed, and is labelled as such.
>
> ★ **QUOTE THE ARM.** *"`w73`/`w78` are exactly zero"* is used below only for the
> **shipped default** (`F_satcen_223`), the **`NOZ05` rigs** (`G_noz05m1_223`,
> `H_noz05m2_223`, `C_noz05_220`) and **§221's arms A/B**. It is **NOT** true of §222's
> `XB85` arms C/D/E, where `§70`/`§211` reach means of `3.53e11` / `1.21e12` with **quiet
> span 0** — a rig rail, not audio.

---

## 0. THE ANSWER IN ONE PARAGRAPH

**THREE UNRELATED FACTS — and the disaggregation is measured, not asserted.** Instance 3
**dissolves**: T-1's *"the other 25 have NO PRODUCER"* is scoped to the **5-word macro**,
and **0 of 25** lack a producer once you look one line further out — 24 have one elsewhere
in the same image and the 25th reads the cell the shared **kernel** fills. Instance 2 is
**not about cells at all**: the epilogue performs **14** operand fetches (not 22 rows), and
**4 of the 14 take an UNDECODED SOURCE CODE that returns 0 by construction** with no memory
access; of the ten that remain, every cell touched **has** a producer, and the zeros come
from `iw65` clearing `ACCA`. Only instance 1 is what it says on the tin — and there
candidate **(a) is MOOT and candidate (b) is ANSWERED, both from logs on disk**: the host
*does* write index `0x85`, **once, at load, with the value ZERO**, into `m_rf`; so no
routing change and no alias collapse can put anything but zero in that cell. What survives
is **(c), our address model is wrong for producers specifically** — and this pass found a
**fourth, previously unreported instance of it with a live consequence and a two-sided
named number**: `880.1.20.2C7`, CHORUS's four delay-READ words, perform an `ACT 0x07`
store whose **index comes from POINTER space** (`m_dp`) while its **array comes from the
word's MODE** (`m_rf`), and they overwrite the host's own CHORUS delay-tap lengths **400**
and **1440** in `m_rf[0x50]` / `m_rf[0x52]` every frame. Two cells the pointer never
reaches — `m_rf[0x54] = 0x0009B0 = 2480`, `m_rf[0x56] = 0x000DC0 = 3520` — carry the
host's other two tap lengths **digit for digit**, which is the control that makes the
first pair a defect rather than a reading.

---

## 1. THE THREE INSTANCES ON ONE COMMON SET OF TERMS

Everything is stated as: **array · index · frames · instrument · arm**.

| | **instance 1** `D-RAM[0x85]` | **instance 2** the EPILOGUE | **instance 3** T-1's lookup macro |
|---|---|---|---|
| **space** | `m_dram` (the pointer-walked D-RAM) | 4 arrays: `m_dram`, `m_rf`, `ACCA`, `tempA` — **plus 4 fetches that reach NO array** | none — a **static** cell derived from a pointer walk |
| **index** | `0x85 = DRAM_UNIT_BASE│DRAM_UNIT_STRIDE` | `0x00`, `0xFF` (`m_dram`); `0x05`, `0x06`, `0x8F` (`m_rf`) | 46 sites over 25 images, cells `0x05`..`0x14` |
| **consumer** | `iw205`, `iw319`, `iw330` (`lo12 0x1CD`, the per-unit input pickup) | `iw60`, `61`, `63`, `65`, `66`, `68`, `70`, `72`, `73`, `75`, `78`, `79`, `80`, `81` | `104.2.**.1CE`, slot 4 of the macro |
| **frames** | settled, `m_frames_run > 900 000`; **540 000** profiled (`226 040` quiet / `313 960` loud) | settled, `> 900 000`; **540 000** (`226 040`/`313 960`) | **none — no frames exist**; 38 images / 2974 words |
| **instrument** | `§222 §E-D0` `UPD6383_PICKUP` writer census + `§104`'s `mem` column + `§96`/`§99` | `§221 §E1` `UPD6383_EPIBUS` operand-provenance census (fired 120 960 000) | a static pointer walk over the ROM |
| **arms** | `A/B/C_222`, `F/G/H_223` (shipped + both `NOZ05` modes) | `A_epibus_221` (shipped), `B_epibus_noz05_221` | n/a |
| **what is actually true** | **NO WRITER AT ALL in `m_dram`** on settled frames, every arm | operand identically **0** in 17 of 18 rows; `iw72` = `4 194 304` | write/read-back **cell-closed 21 of 21**; the other **25 are open** |
| **VERDICT (this note)** | genuinely unwritten **in `m_dram`**; its producer exists and sits in **`m_rf`** | **a DECODE GAP + a dead accumulator**, not unwritten cells | **DISSOLVED** — 0 of 25 are unproduced outside the macro |

⚠ **The three do not share a population, a space, an instrument, or a cause. They are
three facts.** §5 ranks the candidates; §6 reports the one shape that *does* recur, which
is a **fourth** index pair the brief did not name.

---

## 2. ★★★ THE CONTROLS — REPORTED FIRST, AND TWO OF THEM FAILED (RULE 20)

> **The brief's whole question is about absences, so every detector here was graded
> against an answer already on record BEFORE it was used. Two failed. Both failures
> named a real defect in my own code.**

| # | known answer | source of record | result |
|---|---|---|---|
| **C-1** | `lo12 0x1CD` = the body's INPUT PICKUP at **base+0, 38 of 38** | `IW205-DRAM-D0_findings.md` §4.2 | **PASS 38/38** first try (wrapped mod 256) |
| **C-2** | CHORUS's lookup macro closes on cell **`0x0C`** | `§168`, a **live** number | **PASS**, from ROM alone |
| **C-3** | the 46 lookup sites split **21 closed / 25 open** | `CORPUS-PATTERNS-SPECULATIVE-2.md` T-1 | **PASS 21/25** |
| **C-4** | `D-RAM[0x05]` has **4 live writers**: `iw9`, `iw11`, `iw35`, `iw45` | `§222 §E-D0`, MEASURED | ⚠ **FAILED — my walk reported ZERO** |
| **C-5** | `D-RAM[0x85]` has **no** resident-frame writer | `§222 §E-D0`, MEASURED | **PASS** |
| **C-A** | the mode-1 store targets in `m_rf` are exactly **13 cells** | `§99`, `F_satcen_223` line 2842 | **PASS — SET-IDENTICAL** |
| **C-B** | `m_rf` ends the run with exactly **41 non-zero cells** | `§160`, `F_satcen_223` line 2841 | ⚠ **FAILED at 40, then PASS at 41/41** |

### 2.1 ⚠ C-4's failure — and it is the SAME defect `§97 §3` records making

My first walk entered the kernel at `0x05`. `§97 §3` says, in as many words: *"the walk was
starting the kernel at `0x05`, six cells late — the forced per-unit base is applied **at the
body call**, not at kernel entry."* Reading the note would have prevented it (RULE 3,
eleventh occurrence). The fix was to stop guessing and **calibrate every region entry
against `§104`'s own `dp` column**, which `upd6383.cpp:5526` samples as `m_dp` **before**
`exec_decoded(word)` — unambiguously the pre-increment pointer:

```
   region     n    entry   rows reproduced   first mismatch
   kernelA   50    0xFF      50 / 50          none
   body0     70    0x05      70 / 70          none
   kernelB   10    0xFC      10 / 10          none
   body1    133    0x85     133 /133          none
   epilogue  22    0x00      22 / 22          none
   ------------------------------------------------------
   TOTAL    285             285 /285          ZERO disagreements
```

`IW205-DRAM-D0_findings.md` §1.3 reproduced 29 of 29; this is the same instrument
calibrated on **285**. Grade: **MEASURED**.

### 2.2 ⚠ C-B's failure — my rule ignored the DATUM

My first prediction of `m_rf`'s end-of-run contents said *"any mode-1 store zeroes the
cell"* and got **40** where `§160` measures **41**. The missing cell was `0x06`. Cause: a
**bit-4** store writes `acc_to_datum(acc)` while an **`ACT 0x07`** store writes `L` — and
`iw72 = 000.1.06.087` has `SRC 0x02`, whose operand **is `m_rf[0x06]`**, so its store is an
**IDENTITY** (§100's reading, and `§221 F3` measures it at `4 194 304`). With the datum
modelled the prediction is **41 of 41, set-identical**, and it names all five non-LFO cells:

```
   predicted non-zero:  06  54  56  86  8D  + 1D..40      41
   §160 LIVE         :  06  54  56  86  8D  + 1D..40      41      SET-IDENTICAL
```

⇒ ★ **The space model is now good enough to predict the entire register-file content
census from the ROM plus the host's canned streams.** That is what licenses §6.

---

## 3. INSTANCE 3 — T-1's "25 WITH NO PRODUCER" **DISSOLVES**

`CORPUS-PATTERNS-SPECULATIVE-2.md` T-1 is careful and correct as written: the 25 open
sites have *"no producer **in the macro**"*. The brief's framing —
*"the other 25 having NO PRODUCER for the cell their lookup reads back"* — is the
macro-scoped statement read as a program-scoped one. Measured, with the walk of §2.1:

```
   T-1 sites                                    21 CLOSED   25 OPEN
   producer ELSEWHERE in the same body image        21          24
   NO producer anywhere in the image                 0           1
   ... and that ONE is  a15 ROCK ROTARY slot 9, cell 0x05
       -- the UNIT-0 INPUT PICKUP, written by the shared KERNEL
          (iw9, iw11, iw35, iw45; §222 MEASURED)
   ⇒ with the kernel in scope:  0 of 25 have no producer.
```

★ **And the null says "no producer" is the ORDINARY case, not a signal:**

```
   over the 38 body images:  632 distinct (image, cell) D-RAM READS
        with no producer in that image        161 = 25.5 %
        with the shared kernel added          126 = 19.9 %
```

⇒ T-1's exceptionless 21/21 closure **stands** (it is an address identity, `P ≈ 10⁻²⁵`).
Its *complement* is not a finding: **a 25-site population sitting exactly on a 25.5 % base
rate, all of whose members are produced elsewhere.** Grade: **MEASURED**;
**the "must be fed from outside, or reading stale state" reading is REFUTED for 25 of 25.**

⚠ T-1's own proposed live test (instrument `a56 MIX UP`'s three closed cells) is
untouched by this and remains worth running for the *closure* half. What dies is only the
"the 25 are producerless" half.

★ **Free test T-2 asked for, and it is now run for the resident image.** T-2 proposed
checking its 11 voice-macro cells against the host's tag-0x15 fill. For `a01 CHORUS` the
host writes `50=400 51=0 52=1440 53=0 54=2480 55=0 56=3520 57=0`, and the macro's four
cells are `0x50..0x53` — **all four inside the fill, P1 HOLDS**. Corpus-wide the other
seven T-2 cells (`54 55 58 59 5A 5B 61`) all appear in the host's ever-written D-RAM set;
per-algorithm membership for the other nine images is **untested here**.

---

## 4. INSTANCE 2 — THE EPILOGUE IS A **DECODE GAP**, NOT A SET OF UNWRITTEN CELLS

`§221 §E1` hooks the fetch itself (`m_last_l = L`, `upd6383.cpp:3792`), so a slot absent
from its table performed **no operand fetch at all**. The 22 epilogue slots decompose:

```
   22 slots = 14 ALU fetches + 2 C-format immediates + 6 register-load / setvec words
              (iw62 ldptr.d, iw64/iw71 setvec, iw67, iw69 ldptr, iw77 -- all early-return)
```

and the 14 fetches, by ROUTE (arm A, shipped; **byte-identical in arm B, the `NOZ05` rig**):

| route | slots | n | operand |
|---|---|---|---|
| ⛔ **`DEFAULT(no reading)` — an UNDECODED SRC code** | `iw60` (SRC `0x05`), `iw61` (`0x01`), `iw68` (`0x06`), `iw78` (`0x0A`) | 4 | **0 by construction — no array is touched** |
| `ACCA` | `iw70` (SRC `0x03`), `iw73` (`0x10`) | 2 | 0 (`iw65` clears `ACCA`) |
| `tempA` | `iw66` | 1 | 0, prov `iw65` |
| `m_rf[addr8]` | `iw63`→`[05]`, `iw65`→`[8F]`, **`iw72`→`[06]`** | 3 | 0, 0, **`4 194 304`** |
| `m_dram[m_dp]` | `iw75`→`[00]`, `iw79`, `iw80`, `iw81` | 4 | 0 |

★★★ **4 of 14 fetches never reach memory at all.** `SRC 0x01/0x05/0x06/0x0A` have no
reading anywhere in this device and fall to `default:` at `upd6383.cpp:3368`, which
*"silently returns 0"* and increments `m_src_unread[]`. **A source code that is not
decoded is not an unwritten cell**, and three of those four sit on `ACT 0x1B` words.

★ **And every cell the epilogue does touch HAS a producer** — `§E1`'s own provenance
column names them: `m_rf[05]` ← **HOST**; `m_rf[8F]` ← `iw332`; `m_rf[06]` ← `iw72`
(identity, producer HOST); `m_dram[00]` ← `iw73`; `m_dram[FF]` ← `iw79`.
⇒ **Instance 2 is not an instance of the shape at all.** Grade: **MEASURED**.

### 4.1 ⚠ ONE INSTRUMENT DISCREPANCY IN `§221`, FILED HERE

`§E1` reports `iw79`'s operand index as **`0xFF`**. `§104`'s `dp` column and the
285/285-calibrated walk both give **`0x00`**, and `iw79 = 012.2.FF.1CE` is **the only row
in the whole `§E1` table where the pre- and post-increment pointers differ** (`addr8 = −1`;
`iw80`'s own pre-increment pointer is `0xFF`, which is `iw79`'s POST value). The device's
own comment at `upd6383.cpp:3803` already names *"§221's `w79`"* as one of the three
pre-increment casualties. ⇒ **Do not quote `§221`'s `w79` row for an address.** It moves
no verdict — both candidate cells read exactly `0` in both buckets in both arms — but it is
the **sixth** occurrence of the pre-increment trap. Grade: **MEASURED discrepancy,
mechanism UNRESOLVED** (nothing between `:3527` and `:3799` writes `m_dp` in the source I
read).

---

## 5. INSTANCE 1 — THE RANKED VERDICT ON (a)…(e)

### 5.0 What the host actually writes, and where — MEASURED, and it settles (a)

`§59 POKE PORT` (shipped, `F_satcen_223`): **42 pointer words**; data packets →
**D-RAM 63, DESCRIPTOR 43, C-RAM 13, unrecognised 0**; tags `15:46 26:8 4C:19 95:17 A6:5
CC:24` (the high bit is the packet's flag; `0x95`/`0xA6`/`0xCC` are the same three tags, so
`46+17 = 63`, `8+5 = 13`, `19+24 = 43`). Routing, `upd6383.cpp:1665-1705`:

```
   tag 0x15 -> m_rf[m_dram_wp]      (shipped mask bit 23 SET)      63 writes, 59 cells
   tag 0x4C -> m_dscbank[m_dsc_wp]                                 43
   tag 0x26 -> m_cram[m_cram_wp]                                   13
```

★★★ **THERE IS NO HOST PATH INTO `m_dram` AT ALL IN THE SHIPPED BUILD.** And for the two
cells at issue, `§186` prints the target census unambiguously:

```
   §186 HOST tag-0x15 WRITE TARGETS: 63 writes over 59 cells (42 ever non-zero)
        ... 05:1(z) ... 50:1 51:1(z) 52:1 53:1(z) 54:1 55:1(z) 56:1 57:1(z) 85:1(z) 86:3 ...
```

⇒ **the host writes index `0x85` exactly ONCE, with the value ZERO** (and index `0x05` the
same), in the per-effect state reset.

| candidate | grade | verdict |
|---|---|---|
| **(a) A WRITE PATH WE DO NOT MODEL — the host** | **MEASURED, REFUTED** | The host *does* write index `0x85`. It writes **zero**, once. ⇒ ★ **the `m_rf`/`m_dram` alias question is MOOT for this cell**: collapsing it deposits zero into zero. No dead end had to be re-opened to see that, and `PREDICT_D0_producer.md` §2 reached the same place from the store side. |
| **(b) A ONE-TIME INITIALISATION WE MISS** | **MEASURED, ANSWERED** | ★ **The logs CAN distinguish "written once at boot" from "never written", because two instruments have OPPOSITE gating**: `m_hostw_cell[]` (`§186`) is **UNGATED** and counts the boot write; `pk_write()` (`§E-D0`) returns unless `m_frames_run > 900 000` (`upd6383.cpp:1052`, *"RULE 16"*) and reports **no writer on settled frames**. Both are true and consistent. Answer: **written once at load, with ZERO.** This is RULE 16 satisfied, not violated — `§46`'s error was a *single unguarded sample*; here the ungated instrument is a *counter*. |
| **(c) THE ADDRESS MODEL IS WRONG FOR PRODUCERS SPECIFICALLY** | **INFERRED — RANKED FIRST of the surviving candidates** | `iw70 = 2A6.1.85.0C7` sits **one word before the unit-1 entry vector** `iw71`, exactly as `iw72` sits one word before the unit-0 presentation `iw73`, and it is the **only** word in the machine addressing index `0x85`. Its index is right and its array is right *by our rule*; what is unknown is `SRC 0x03` (corpus-unique, `n = 1`, undecidable by counting) and whether the mode-1 store space *is* the pointer space in this region. ⚠ And §6 exhibits a **fourth index pair where the address model demonstrably IS wrong for a producer** — same file, same function. |
| **(d) GENUINELY UNWRITTEN, THEREFORE FAITHFUL** | **MEASURED for the fact, REJECTED for the reading** | The fact is real and, on the null, **ordinary**: of the 35 D-RAM cells the resident frame reads, **13 (37 %) have no writer in the frame** — `01 03 04 0D 50 51 52 53 85 8C 8F FD FF`. So unproducedness alone carries no signal. But it is **not faithful for `0x85`**: the ROM puts a candidate producer one word before the unit-1 call, the host allocates the index, and the unit-0 twin `0x05` has four live writers. A reverb whose input cell is never filled is not a design. |
| **(e) THREE UNRELATED FACTS** | **MEASURED — THE HEADLINE** | §3 and §4 dissolve two of the three, on different evidence, with their own nulls. |

### 5.1 ⚠ The second chip — asked explicitly, and it is DECIDED

Could a **cross-chip interface** be the missing producer? **No, and the evidence decides
it** (`second-dsp-and-ready.md` **B4**, **B9**, from the service manual):

* IC310 (MN19413)'s link is **3-wire bit-banged serial** — `PF.0 DSP2DA`, `PF.2 DSP2SCK`,
  `PE.6 DSP2CS` — with **no data-in line on the board at all**. It cannot return a datum.
* The audio path is `IC303 SDO0` (the main mix) → **IC310 SDI**; IC311 is a **send/return
  insert on IC303**. **IC310 sits DOWNSTREAM of IC311.** There is no IC310 → IC311 wire.

⇒ **A cross-chip route cannot fill `D-RAM[0x85]`.** Grade: **MEASURED** (schematic) /
**FORCED** (a chip with no data-out to IC311 cannot write IC311's D-RAM).

⚠ **Denominators, stated:** the five IC310 streams `{79, 88, 89, 90, 91}` are excluded from
every count in this note (`pat_corpus.MALFORMED`), and algorithms **57–60 are IC310-only
too**, so the IC311 population is **91**, not 100. The **twelve stub effects** collapse into
`a00` before measurement and contribute **zero distinct images**. No statistic here mixes
the two chips.

---

## 6. ★★★ THE ONE SHAPE THAT DOES RECUR — AND IT IS A FOURTH INDEX PAIR, NOT ONE OF THE THREE

Not a unification of the brief's three. A **space-mismatch census** over the resident
frame, built from the routing rules transcribed at each source line and validated by
controls **C-A** (13/13 set-identical with `§99`) and **C-B** (41/41 with `§160`):

```
   indices with BOTH a producer and a consumer          29
      producer and consumer share an array              23
   ★ DISJOINT ARRAYS -- the datum cannot arrive           6 :  50  51  52  53  85  8C
```

| index | consumer | producer(s) | note |
|---|---|---|---|
| `0x50` | `m_dram` ← `iw95` `082.2.00.1C0` | `m_rf` ← **HOST, value 400** and `m_rf` ← `iw98` `880.1.20.2C7` | ★ the defect |
| `0x51` | `m_dram` ← `iw104` | `m_rf` ← HOST (0), `iw107` | host value is 0 — undiscriminating |
| `0x52` | `m_dram` ← `iw136` | `m_rf` ← **HOST, value 1440**, `iw139` | ★ the defect |
| `0x53` | `m_dram` ← `iw145` | `m_rf` ← HOST (0), `iw148` | undiscriminating |
| `0x85` | `m_dram` ← `iw205`, `iw319`, `iw330` | `m_rf` ← HOST (0), `iw70` | **instance 1** |
| `0x8C` | `m_dram` ← `iw204` | `m_rf` ← `iw66` | a **second** copy of instance 1's shape |

### 6.1 The mechanism, named at its line

`upd6383.cpp:4294`:

```cpp
const bool d07_ptr = !(mode07 == 1
        && !(m_speculative && (m_specmask & (1ull << 61)) && esc_dly));
...
u8 d07 = d07_ptr ? m_dp : d07_rebas;
store_mode(mode07, u8(d07), u32(L), 3, xb_wr);      // :4539
```

`esc_dly` = a **delay-DRAM word** (`hi12` bit 11 set, `class4 == 1`). Mask **bit 61 is SET**
in the shipped default. So for CHORUS's four `880.1.20.2C7` delay READs the `§161` fix
correctly takes the destination **off** `addr8 = 0x20` (a direction field, not an address) —
but it leaves `mode07 == 1`, and `store_mode()` sends **mode 1 to `m_rf`**. Result:

> ★★★ **the index comes from POINTER space (`m_dp`) and the array comes from the word's
> MODE (`m_rf`). The two halves of one addressing decision disagree, and the store lands in
> the host's parameter register file at a pointer-space index.**

The four sites and their measured pointers (from `§104`'s own `dp` column):
`iw98 → 0x50`, `iw107 → 0x51`, `iw139 → 0x52`, `iw148 → 0x53`.
`§99` counts them: `50:1176960 51:1176960 52:1176000 53:1176000` — once per frame each.

### 6.2 ★ The consequence, and the control that makes it a defect rather than a reading

The stored datum is `L`, and `880.1.20.2C7` has `SRC 0x0B` = the delay-read register.
`§48`: **`23 733 120` reads, `0` with a non-zero datum.** So the store deposits **zero**:

```
   host canned D-RAM (algo 1 CHORUS)  50=400   51=0   52=1440  53=0   54=2480  55=0  56=3520  57=0
   §160 register file, end of run     50=0     51=0   52=0     53=0   54=0009B0     56=000DC0
                                      ^^^^^^^^ the pointer reaches these four ^^^^   ^^^ it never reaches these ^^^
   0x0009B0 = 2480   0x000DC0 = 3520      <- the host's DELAY 3 / DELAY 4, digit for digit
```

★★★ **Two cells the pointer walk reaches lose the host's tap lengths; two cells it never
reaches keep theirs exactly.** That is a two-sided contrast, already on disk, that no
"reading" of `ACT 0x07` explains away. Grade: **MEASURED** (`§160` + `§99` + `§48` +
`register_space.py cells`) / **FORCED** for the mechanism (it follows from `:4294`'s
ternary and `store_mode()`'s mode test).

⚠ **AND `§161` MOVED THE WOUND RATHER THAN CLOSING IT.** Before bit 61 these four stores
landed on `m_rf[0x20]` = LFO WAVETABLE INDEX 3 (`§161`'s own measured symptom: index 3 read
`0` where the sine needs `+6 169 476`). `§160`'s window dump now shows `0x20 = 0x5E2382 =
6 169 474` — restored, 2 LSB from the ideal — so the fix works **for `0x20`** and the damage
simply relocated to `0x50..0x53`. Either the word does not store at all (the `ACT 0x07`
field on a delay word being part of the delay encoding), or it stores to `m_dram[m_dp]`
like every other pointer-indexed store. **Both readings agree it must not write `m_rf`.**

⚠ **AND FIXING IT DOES NOT FEED `iw95`.** `iw95` reads `m_dram[0x50]`, which is `0` and
would still be `0`. These are **two** defects at one index: a spurious store destroying a
host parameter, and a consumer reading the other array. Do not let one hide the other.

---

## 7. THE PRE-REGISTERED EXPERIMENT — `§Z`, THE SPACE-TWIN AUDIT

### 7.0 ⛔ WHAT IT IS NOT

**It is NOT clearing mask bit 23.** That is *"collapse the `m_rf`/`m_dram` alias"*, a filed
dead end: `PREDICT_D0_producer.md` §1 enumerates **five (now six) confounded sites**, three
of them load-bearing on the output path, and **four of which report nothing that
distinguishes the arms**; `§41`+`§176`+`§86` quantify the catastrophe (unit 0's output gain
becomes per-frame kernel scratch, unit 1's level becomes 0 and the level multiply is
skipped). **`§Z` changes no routing, no decode, no mask bit. It is a pure observer.**

### 7.1 What it is

**`§Z` — THE SPACE-TWIN AUDIT. READ-ONLY, env `UPD6383_TWIN=1`, DEFAULT 0, fired count
printed UNCONDITIONALLY with the arm's flag (rule 8).** On settled frames
(`m_frames_run > 420 000`, the `INSTRUMENT-AUDIT R6` unified window), for every `m_dram` or
`m_rf` access — read *or* store — record a row keyed by `(index, array, kind, iw)` with:
`n`, the value actually read or written, **and the content of the SAME INDEX in the OTHER
array at that instant**, split quiet/loud, plus the pointer **before** and **after** as two
separate columns.

⚠ **Copy `pk_write()`'s row table, NOT `store_probe()`'s.** `store_probe()` truncates at
`SPROBE_ST = 4` and **silently `return`s with no overflow counter** (`upd6383.cpp:585`);
`pk_write()` has `m_pkw_over` and prints `dropped 0`. A census that drops rows in silence is
the exact defect this brief warns about.

**Vehicle:** the CLEAN one (standing rule 2), notes 21.0 s → 27.5 s, `-seconds_to_run 30`,
`-log`, visible video, `-skip_gameinfo`, isolated `-cfg_directory` carrying
`:DSPCFG value="3"`. **Arms: A (shipped default) only.** No rig is needed — every quantity
below is rig-independent, and `§222`/`§223` already show the `NOZ05` and `XB85` rigs rail.

### 7.2 THE NULL — computed from logs already on disk, BEFORE the run

| # | quantity | predicted | source on disk |
|---|---|---|---|
| **N1** | mode-1 store targets in `m_rf` | **exactly 13**: `06 0E 0F 50 51 52 53 85 8A 8C 8D 8F D0` | `§99`, `F_satcen_223` L2842 — and the static model of §2 reproduces this **set-identical** |
| **N2** | `m_rf` cells non-zero at end of run | **exactly 41**: `06`, `1D..40`, `54`, `56`, `86`, `8D` | `§160`, L2841 |
| **N3** | indices whose producer and consumer are in disjoint arrays | **exactly 6**: `50 51 52 53 85 8C` | §6, static |
| **N4** | `m_dram` under the pointer at `iw95/104/136/145` | `0..0` quiet **and** loud, marker `=` | `§104` rows, `F_satcen_223` |
| **N5** | `m_dram[0x85]` at `iw205/319/330` | `0..0` both buckets; `§E-D0` `var 0/0/0` over 540 205 frames | `§104` row 205; `A_pickup_222` |
| **N6** | the datum `iw98` stores | **0** — `SRC 0x0B`, and `§48` reports 0 non-zero of 23 733 120 | `F_satcen_223` |
| **N7** | `m_rf[0x85]`'s only settled writer | `site 3 iw70 n 540000 val quiet 0..0 loud 0..0` | `§E-D0` writer census |
| **cal** | vehicle | `§54` loud ≈ **313 960** frames; `§104` `nq/nl` = **706 040 / 313 960**. **A loud count of 0 VOIDS the run** (RULE 12) | every 220–223 log |

### 7.3 ★ THE CONTROL WHOSE ANSWER IS ALREADY KNOWN — AND WHICH CAN FAIL

> **C1 (two cells, two independent sources, and it is UPSTREAM of the arm — §222's method
> lesson).** `§Z` must report `m_rf[0x54] = 0x0009B0` (**2480**) and `m_rf[0x56] =
> `0x000DC0` (**3520**). Those two numbers exist in **`§160`'s live dump** *and*,
> independently, in the **ROM's own canned parameter stream** for algo 1
> (`register_space.py cells`: `54=2480 56=3520`) — a device measurement and a firmware
> table that were never fitted to each other.
> **C1 FAILS ⇒ the audit is mis-wired and the run is VOID; no other number may be quoted.**
>
> **C2 (a second upstream control).** `§221 F3`: `iw72`'s operand is `m_rf[0x06] =
> 4 194 304`. It is upstream of every index `§Z` touches and passed in both §221 arms.

### 7.4 THE FALSIFIERS — EACH NAMES A SPECIFIC WRONG NUMBER

> **F1 — the decisive one.** *At `iw98` the audit reports a STORE into **`m_rf`** at index
> **`0x50`**, and its twin column reports `m_dram[0x50] = 0`.*
> **F1 FAILS if it reports index `0x20`.** ⇒ **`0x20` is the named wrong number.** It is
> the pre-`§161` destination (LFO WAVETABLE INDEX 3); a run reporting it is running a build
> without mask bit 61, `§160`'s window would show `0x20 = 0` instead of `0x5E2382`, and
> **nothing in the run may be quoted**.

> **F2 — the one that can teach us something.** *`m_rf[0x50]` holds **400** and
> `m_rf[0x52]` holds **1440** at the first settled frame, before `iw98`/`iw139` overwrite
> them.*
> **F2 FAILS if they are never 400 / 1440** — which relocates the defect from the store to
> the **poke port**, and that is the bigger result.
> ⚠ **Two further named wrong numbers on the same line:** **800 / 2880** means the payload
> doubling (mask bit 31) is applied **twice**; **200 / 720** means it is **not applied at
> all**. Either voids the value column while leaving F1 readable.

> **F3 — instance 1, restated so it can fail.** *`m_dram[0x85]` has no writer of any kind,
> and `m_rf[0x85]`'s provenance is **HOST** until `iw70`'s first store.*
> **F3 FAILS if any `iw` appears against `m_dram[0x85]`** — and that outcome is **better
> than the prediction holding**: it names the word that is supposed to fill the reverb's
> input. This is `§222 F2` re-armed with the twin column added.

### 7.5 THE DECISION RULE, WRITTEN BEFORE THE DATA

* **N1–N7, C1, C2 hold and F1/F2/F3 hold:** the six disjoint indices are confirmed live,
  and the build lane gets **one named one-word defect** — `880.1.20.2C7`'s `ACT 0x07` store
  writes `m_rf[m_dp]`. The fix is a **mode** question, not a decode question, and it is
  two-sided (no store, or `m_dram[m_dp]`); both candidates agree it must not write `m_rf`.
  `0x85` stays where `PREDICT_D0_producer.md` §2 left it: **`SRC 0x03`, not routing.**
* **F1 fails:** VOID. Fix the build, re-run. Nothing is salvageable.
* **F2 fails:** the defect is in the poke port. Re-aim at `upd6383.cpp:1616-1700`.
* **F3 fails:** name the word, its mode and its array. One line, and the whole result.

### 7.6 ★★★ WHAT THIS EXPERIMENT CANNOT DO, STATED IN ADVANCE

**It cannot produce audio and must make no audio claim.** Both defects sit **upstream of an
output stage `§221` proved is not connected** — the `§E1` census is **byte-identical**
between the shipped arm and the `NOZ05` rig (verified again here, 22 lines, `diff` empty)
while body 0 goes from `0/0/0` to `28/32/28` input-dependent slots. If a later pass repairs
`iw98` and then reports a non-zero `w78`: ⚠ **RULE 19 — report MEAN and AC SPAN
separately.** The named wrong numbers are already on record: `w78` mean **79 438 ± 90**
(−59 dB, and the no-stimulus window wobbles ±40 around the same pedestal), and `§104` row
205's `mem` reading **39 718** or **4 194 304** — the two constants the epilogue already
holds. **A reverb fed a constant is a constant.**

---

## 8. HONEST LIMITS

* **The `iw79` discrepancy (§4.1) is filed, not explained.** I could find no `m_dp` write
  between `:3527` and `:3799`. It touches one row of one census and no verdict.
* **`SRC 0x03` at `iw70` is still `n = 1`.** Nothing here decides it. `§222`'s `XB85` arms
  tested the crossbar and produced the rig rail; that remains the state of the art.
* **The space model is a transcription.** It reproduces `§99` (13/13) and `§160` (41/41),
  which is strong, but it is my reading of `upd6383.cpp`, not the machine. `§Z` exists to
  make it a machine-reported fact.
* **§6 is scoped to the RESIDENT frame** (`a01 CHORUS` + `a16 ROOM REVERB 1`). The
  corpus-wide count of delay words carrying `ACT 0x07` is not computed here; `§161`'s own
  note says the resident count is 4 and that *"the other 22 `addr8 == 0x20` words in the
  frame carry `ACT 0x15` or `0x0B` and never reach this line"*.
* **T-2's free test is run for `a01` only.** The other nine images are untested.
* **`DRAM_UNIT_STRIDE = 0x80` is taken as given**, as in `IW205-DRAM-D0_findings.md` §7.
* **No claim is made about IC310's own program set.** It is excluded from every count and
  the audio-path argument in §5.1 rests on the service manual as reported by
  `second-dsp-and-ready.md`, not on a schematic I read.

---

## 9. TEN-LINE SUMMARY

1. **THREE UNRELATED FACTS, and two of the three dissolve on measurement.** Do not unify
   them; they share no population, space, instrument, frame window or cause.
2. **Instance 3 is DISSOLVED.** T-1's "25 with NO PRODUCER" is **macro-scoped**: **0 of 25**
   lack a producer outside the 5-word macro — 24 elsewhere in the same image, and the 25th
   (`a15 ROCK ROTARY`, cell `0x05`) reads the cell the shared **kernel** fills. Null:
   **25.5 %** of all (image, cell) reads have no in-image producer, so unproducedness is the
   ordinary case. T-1's 21/21 *closure* stands untouched.
3. **Instance 2 is a DECODE GAP, not unwritten cells.** The epilogue performs **14** fetches
   (22 rows, 2 C-format, 6 early-return register loads); **4 of the 14 take an UNDECODED
   SRC (`0x01/0x05/0x06/0x0A`) and return 0 with no array touched**, and **every cell the
   other ten reach HAS a producer**. The zeros come from `iw65` clearing `ACCA`.
4. **RANKED VERDICT for instance 1:** **(e)** overall; within it **(c) address model wrong
   for producers — INFERRED** first, **(d) genuinely unwritten — MEASURED as a fact,
   REJECTED as "faithful"** second, **(b) one-time init — MEASURED and ANSWERED** third,
   **(a) host write path — MEASURED and REFUTED** last.
5. **WHAT THE HOST ACTUALLY WRITES, AND WHERE:** 63 tag-`0x15` packets over 59 indices, **all
   into `m_rf`**; 43 tag-`0x4C` → `m_dscbank`; 13 tag-`0x26` → `m_cram`. **There is NO host
   path into `m_dram` at all.** For the two cells at issue, `§186` reads `05:1(z)` and
   `85:1(z)` — **once each, value ZERO.** ⇒ the alias question is **MOOT** for `0x85`:
   collapsing it deposits **zero into zero**, and no dead end had to be re-opened to see it.
6. **RULE 16 is satisfiable here, and the logs already do it:** `m_hostw_cell[]` (`§186`) is
   **ungated** and counts the boot write; `pk_write()` is gated at `> 900 000` and reports no
   settled writer. Two instruments with **opposite gating** decide "written once at boot"
   (true) against "never written" (false).
7. ★★★ **THE ONE SHAPE THAT DOES RECUR IS A FOURTH INDEX PAIR THE BRIEF DID NOT NAME.**
   **6 of 29** resident indices have producer and consumer in **disjoint arrays**:
   `50 51 52 53 85 8C`. At `0x50..0x53`, CHORUS's four delay-READ words `880.1.20.2C7`
   store into **`m_rf[m_dp]`** — **pointer-space index, register-file array**
   (`upd6383.cpp:4294`, mask bit 61) — wiping the host's tap lengths **400** and **1440**
   1.18 M times each, while `m_rf[0x54] = 2480` and `m_rf[0x56] = 3520`, which the pointer
   never reaches, survive **digit for digit**. `§161` moved the wound off `m_rf[0x20]`; it
   did not close it.
8. **THE SECOND CHIP CANNOT BE THE PRODUCER, and the evidence decides it:** IC310's link has
   **no data-in line on the board**, and IC310 sits **downstream** of IC311 (`IC303 SDO0` →
   `IC310 SDI`; IC311 is a send/return insert). The five IC310 streams and the twelve stubs
   are excluded from every denominator here; the IC311 population is **91**.
9. ★ **RULE 20, SELF-REPORTED: two of my seven controls FAILED FIRST.** C-4 (kernel writers
   of `D-RAM[0x05]`) returned **0** against a known **4** — my walk entered the kernel at
   `0x05`, the identical defect `§97 §3` records making; fixed by calibrating all five region
   entries against `§104`'s own `dp` column, **285/285**. C-B returned **40** non-zero `m_rf`
   cells against a known **41** — my rule ignored the datum, and `iw72`'s `ACT 0x07` store is
   an **identity**; refined, **41/41 set-identical**. Also filed: **`§221`'s `w79` row reports
   the POST-increment index `0xFF`** where the operand address is `0x00` (the only `§E1` row
   where the two differ; `upd6383.cpp:3803` already names it) — and **`store_probe()`
   truncates at 4 with no overflow counter**, so no new instrument may copy it.
10. **THE ONE EXPERIMENT I RECOMMEND: `§Z`, the SPACE-TWIN AUDIT** — read-only, no gate, no
    decode change, no mask bit, arm A only, default OFF, fired count unconditional. NULL from
    disk: `§99`'s **13** mode-1 store targets, `§160`'s **41** non-zero `m_rf` cells, the
    **6** disjoint indices, `§48`'s **0 of 23 733 120**. Control that can fail: `m_rf[0x54] =
    0x0009B0 = 2480` and `m_rf[0x56] = 0x000DC0 = 3520`, known from **two independent
    sources**. Named wrong numbers: **`0x20`** for `iw98`'s store index (⇒ VOID), and
    **800/2880** or **200/720** for the tap lengths (⇒ the payload scaling, not the store).
    **This experiment cannot produce audio and must make no audio claim.**
