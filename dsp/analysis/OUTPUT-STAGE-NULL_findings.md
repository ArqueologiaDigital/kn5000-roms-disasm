# OUTPUT-STAGE NULL — where the value dies between body 0 and `w73`/`w78`

**Written 2026-07-31, STATIC + EXISTING LOGS ONLY. No emulator was run, no source was edited.**
Every number below is read out of a log already in `dsp/analysis/data/`, out of
`dsp/disasm/*.dsm`, or out of `kn7000_mame/src/devices/cpu/upd6383/upd6383.cpp`.
**Cite the run, not the section** — the runs used are:

| tag | file | arm |
|---|---|---|
| **A** | `data/drpub_A_off_217.log.gz` | shipped default (`mask 0xB910E446A39B440F`) |
| **B** | `data/drpub_B_on_217.log.gz` | `UPD6383_DRPUB=1` |
| **C** | `data/drpub_C_on_src0b2_217.log.gz` | `DRPUB=1` + `SRC0B2=1` — **the arm where the send is open and body 0 runs on live audio** |
| — | `data/src0b2_{A_off,B_on}_215.log.gz`, `data/outstage_211.log.gz`, `data/kernelA_213.log.gz` | corroboration only |

All five logs: 1 440 001 frames, 313 960 loud / 726 040 quiet, clean vehicle.

---

## 0. THE ANSWER IN ONE PARAGRAPH

**The value is not lost between body 0 and `w73`. It is lost *inside body 0* (and, for unit 1,
inside body 1), and the epilogue is a null that is INCAPABLE of carrying audio no matter what is
handed to it.** In arm C the accumulator body 0 hands back is **exactly zero** (§104 `iw152`,
`iw153` = `0..0` in *both* buckets, identical in arms A and C), and the accumulator the epilogue
actually receives is a **kernel-B constant, 2 603 010 048**, whose producer is `w53`/`w54` and
**not any body word**. Independently of that, **21 of the epilogue's 22 executing slots fetch a bus
operand of exactly `0` in every frame of a 1.44 M-frame run, in both buckets**; the 22nd is `w72`,
which fetches the host's output-level constant `0x400000`. Four of those 21 zero fetches are
**literal decode gaps** — `SRC 0x05`, `0x01`, `0x06`, `0x0A` fall through
`upd6383.cpp` `default: m_src_unread[src & 0x1f]++;` and leave `L = 0` — and **three of the four
are the epilogue's only three accumulating (`f31 = 1`) words before the presentations.**
That is why §216 measured a null *independent of its input*: it must be.

**Classification: a DECODE GAP in the epilogue (which is real but NOT load-bearing — see §5), on
top of a genuine LOSS OF THE SIGNAL one region earlier, in the two bodies.** It is **not**
"correct-and-misread": `w73`/`w78` are the only output writers the model has (`§61` counts
1 203 840 executions each; `OUTPUT SLOT WRITES` is `0/0` on all six slots).

---

## 1. THE PATH, TRACED BY CONSTRUCTION, SLOT BY SLOT

Per-frame execution order (MEASURED, arm C `TIME-ORDERED FRAME TRACE`, 285 slots):

```
  n   0.. 49  kernel A   iw   0.. 49      ACCA
  n  50..119  body 0     iw  84..153      ACCA   (u1 = 0)
  n 120..129  kernel B   iw  50.. 59      ACCA
  n 130..262  body 1     iw 200..332      ACCB   (u1 = 1, mask bit 14)
  n 263..284  epilogue   iw  60.. 81      ACCA   (u1 = 0)   -> w73 at n=276, w78 at n=281
```

### 1.1 ACCA, from the kernel to the presentation (arm C, `ACCUMULATOR PROFILE` + §104)

| where | ACCA (quiet / loud) | grade |
|---|---|---|
| `iw49` kernel-A exit | `0..0` / `−864 633 992 785 .. 773 989 370 423` | **MEASURED**, input-dependent |
| `iw84..91` body-0 entry | same values, carried through unchanged | **MEASURED** |
| **`iw92`** `000.2.09.447` | **`203..203` both buckets** — ★ FIRST DEATH | **MEASURED** |
| `iw113..142` | live again but **≤ ±16 839 598** acc units = **±257 as a datum** | **MEASURED** |
| `iw143` `900.1.60.1D5` | `0..0` | **MEASURED** |
| `iw150..153` body-0 exit | **`0..0` both buckets, arms A and C** | **MEASURED** |
| `iw54..64` (kernel B + epilogue head) | **`2 603 010 048`, min == max, both buckets** | **MEASURED** |
| **`iw65`** `200.1.8F.1C1` | **`0..0`** — ★ SECOND DEATH | **MEASURED** |
| `iw66..73` | `0..0`; `w73` presents `0` | **MEASURED** |

★ **RULE 17 (provenance, not liveness):** the value `iw65` destroys is **not** body 0's. Its
producer is kernel-B `w53` = `010.9.D0.20C` (a coefficient × coefficient multiply, `L = 32768`,
`coef = 0x008000`) latched by `w54` = `800.1.60.00B` (`f31 = 0`, `acc ← P`). The corroboration is
exact and triple: `acc_to_datum(2 603 010 048) = 39 718`; body-1 `iw201` (`SRC 0x10`) reports
`L = 39 718` in **both** arms; and `§160 register file` shows `8D = 0x009B26 = 39 718`, written by
`w61`'s `hi12` bit-4 accumulator store. **`iw65` kills a constant.** Fixing `iw65` cannot produce
audio — see the named wrong number in §6.3.

### 1.2 ACCB, unit 1 (arm C)

| where | ACCB | grade |
|---|---|---|
| `iw202` `212.A.81.1D5` | `5 206 020 096` (= 2 × ACCA's constant) | **MEASURED** |
| `iw203`, `iw204` | arm A: `5 206 020 096..5 206 020 096` **both buckets** (pure constant). arm C: quiet `5 205 940 658..5 206 020 096`, loud `5 199 823 966..5 211 501 287` | **MEASURED** |
| **`iw205`** `202.2.4B.1CD` | **`0..0`** — ★ THIRD DEATH, and it kills 128 of body 1's 133 slots | **MEASURED** |
| `iw206..332` | `0..0` | **MEASURED** |
| `w78` | presents ACCB = `0` | **MEASURED** |

**Mechanism at `iw205`, traced by construction:** `lo12 = 0x1CD` ⇒ `SRC 0x07` (mem), `ACT 0x0D`.
`m_bx_sel0d = (m_specmask >> 42) & 7 = 1` in the shipped default (`upd6383.cpp:304`), so
`case 0x0d` selector 1 runs `bx_acc_w(L, false)` (`upd6383.cpp:3318`) = **accumulator LOAD**.
`m_dp = 0xD0` at that slot (trace row n=135), and `D-RAM WRITES` reports `D0: 0/4 727 824`
non-zero. ⇒ **`ACCB ← 0`.** Grade: **MEASURED** for the value and the pointer, **INFERRED** for
the causal attribution (the selector is an *enumerated* choice, not a decode — `ACT 0x0D` is
`three-codes.md` item E, undecidable by comparison).

---

## 2. THE EPILOGUE'S BUS IS STRUCTURALLY EMPTY — this is the load-bearing measurement

`§104` L column, epilogue rows `60..81`, **byte-identical in arm A and arm C**:

```
  every slot 60..81        L quiet 0..0   loud 0..0   '='
  except w72 (000.1.06.087) L quiet 4194304..4194304  loud 4194304..4194304  '='
```

⇒ **21 of 22 executing epilogue slots have an operand of exactly zero, in 1 440 001 frames, in
both buckets.** The 22nd is the host's unit-0 output level. Grade: **MEASURED**.

Why each one is zero, by construction from `upd6383.cpp`:

| slot | word | SRC | route the C++ takes | measured content | category |
|---|---|---|---|---|---|
| **w60** | `092.1.8D.15B` | **0x05** | `default:` → `m_src_unread[5]++`, `L` stays 0 | — | ⛔ **DECODE GAP** |
| **w61** | `012.1.8D.05B` | **0x01** | `default:` | — | ⛔ **DECODE GAP** |
| w63 | `2A7.9.05.1C3` | 0x07 | `regfile = true` → `m_rf[0x05]` | host wrote it **once, with zero** (`§186 05:1(z)`) | empty cell |
| w65 | `200.1.8F.1C1` | 0x07 | `regfile = true` → `m_rf[0x8F]` | body 1 writes it 1 176 000× with dead ACCB (`§99 8F:1176000`) | empty cell |
| w66 | `000.1.8C.107` | 0x04 | `m_ta` | last written by `w65` with `L = 0` | empty |
| **w68** | `092.1.8C.19B` | **0x06** | `default:` | — | ⛔ **DECODE GAP** |
| w67, w73 | `980.5.20.402`, `E30.C.00.404` | 0x10 | ACCA | 0 | consequence |
| w70 | `2A6.1.85.0C7` | 0x03 | ACCA-as-datum (bit 25) | 0 | consequence |
| w72 | `000.1.06.087` | 0x02 | `m_rf[0x06]` (bit 24) | **4 194 304 ✓** | the only live operand |
| **w78** | `A3C.D.9F.287` | **0x0A** | `default:` | — | ⛔ **DECODE GAP** |
| w75, w81 | `82E.8.0F.000`, `102.2.00.000` | 0x00 | `m_dram[m_dp]`, `m_dp = 0x00` | `00: 0/5 883 674` non-zero | dead cell |
| w79, w80 | `012.2.FF.1CE`, `104.2.00.1CE` | 0x07 | mode 2 → `m_dram[0xFF]` | `FF: 0/2 352 786` non-zero | dead cell |
| w62, w69, w77 | `801.0.26.825`, `801.0.90.821`, `859.0.86.822` | — | `is_ldptrd` / `is_ldptr`, never reach the ALU | — | correct |
| w64, w71, w74, w76 | `C40…`, `C41…`, `C16…`, `C00…` | — | **C-format** (`hi12[11:8]==0xC`) — `w64`/`w71` are `setvec` (imm13 = `84*32`, `200*32`) | — | correct, and they do **not** touch ACCA (trace confirms) |

### 2.1 The four decode gaps, confirmed statically AND dynamically

Runtime, **identical in all five logs** (`SRC CODES STILL READING ZERO`):

```
  0x01:1204800   0x05:1205760   0x06:1204800   0x0A:1203840   0x13:4705920   0x1C:1176960
```

`§61` reports **1 203 840** presentations per unit, i.e. one epilogue per frame ⇒ each of
`0x05/0x06/0x0A` fires **exactly once per frame**. Static census over the *resident* program set
(`kernel.dsm` + `epilogue.dsm` + `prog01_chorus.dsm` + `prog16_room_reverb_1.dsm`) confirms the
sites exactly:

```
  SRC 0x05 : 1 site  -> epilogue w60
  SRC 0x06 : 1 site  -> epilogue w68
  SRC 0x0A : 1 site  -> epilogue w78          (the unit-1 PRESENTATION word itself)
  SRC 0x01 : 5 sites -> epilogue w61 + 4 x chorus A00.0.00.041 (iw97/106/138/147)
```

Grade: **MEASURED** (runtime counts) + **PROVEN BY CONSTRUCTION** (the static census reproduces
the counts).

### 2.2 ★ The three gaps sit on the only three words that could accumulate

`f31 = hi12[3:1]` over the epilogue's ALU words, before the presentations:

```
  f31 = 1 (ADD)   : w60, w61, w68     <-- ALL THREE ARE UNDECODED SOURCES
  f31 = 0 (LOAD)  : w65, w66, w67, w72, w73
  f31 = 3/6/7     : w63, w70, w75, w78   (op > HOLD => no product, no bus term)
```

`f31 = 0` is `acc ← P`; the epilogue's four multiplies (`w63`, `w73`, `w75`, `w78` — the
`class & 8` words) all compute `coef × L` with `L = 0`, so `P = 0` at every epilogue slot (trace
`P` column = 0 on rows n=263..284, while `coef` is live at `0x291687` / `0x4D9364`).
⇒ **every LOAD loads zero and every ADD adds zero.** The output stage cannot be anything but a
null, *for any upstream input whatsoever*. That is §216, derived instead of measured.

⚠ **CORRECTION to §138's premise** (`upd6383.cpp`, mask bit 55, `FIRED 0 times` in the default):
its comment says *"the epilogue contains exactly ONE class-A word out of 23, so no multiply issues
there at all and P is stale/zero throughout"*. Four multiplies **do** issue (the gate is
`coeff_fetch = class4 & 8` under mask bit 2, not `class4 == 0xA`). `P` is zero because **`L` is
zero**, not because it is stale. §138 therefore treats a symptom.

---

## 3. THE EXACT SLOT AND THE EXACT C++ STATEMENT

Line numbers are from `kn7000_mame/src/devices/cpu/upd6383/upd6383.cpp` at commit `9c383ca` **with
the working tree modified by the build-lane agent** — quote the *statement*, not the number.

**(a) The four decode gaps — the value never enters the datapath**

```c++
// upd6383.cpp ~2676-2681, inside `if (m_speculative) switch (src)`
default:
    //  EVERY remaining source has no reading and silently returns 0.
    m_src_unread[src & 0x1f]++;
    break;
```
`L` is declared `s32 L = 0;` above and is never written for `SRC 0x01/0x05/0x06/0x0A`.
**This is the statement that zeroes `w60`, `w61`, `w68` and `w78`.**

**(b) The accumulator zeroing at `w65` (and `w67`, `w72`, `w73`)**

```c++
// upd6383.cpp ~3142-3145 and ~3219
u64 &accum = use_b ? m_accb : m_acc;
const u64 src_term = (op == upd6383_disassembler::HI_ACC_LOAD ? 0 : accum) + (...);
...
accum = (src_term + p_term) & 0xfffffffffffULL;
```
At `w65`: `op = HI_ACC_LOAD` (f31 = 0) ⇒ `src_term = 0`; `act = 0x01 ≠ LO_ACT_ACC_BUS` ⇒ no bus
term; `p_term = m_p = 0`. **`ACCA ← 0`.**

**(c) `ACCB ← 0` at body-1 `iw205`**

```c++
// upd6383.cpp ~3318, case 0x0d, selector 1
case 1: bx_acc_w(L, false); break;                 // -> accumulator (load)
```
with `L = m_dram.read_dword(m_dp)`, `m_dp = 0xD0`, and `D-RAM[0xD0]` measured `0/4 727 824`
non-zero.

**(d) The mode-1 / mode-2 memory split, for completeness (NOT the defect — see §5.1)**

```c++
// upd6383.cpp ~2804-2814
const u8 rdmode = c_format(word) ? 2 : u8(class4(word) & 7);
const bool regfile = (rdmode == 1) && !(hi & 0x800);
const u8 rdsrc = regfile ? u8(addr8(word) | (m_cur_unit1 ? 0x80 : 0x00)) : m_dp;
L = (regfile && m_speculative && (m_specmask & 0x800000))
        ? s32(util::sext(m_rf[rdsrc] & 0xffffff, 24))
        : s32(util::sext(m_dram.read_dword(rdsrc) & 0xffffff, 24));
```

---

## 4. WHY BODY 0 HAS NOTHING TO HAND OVER EITHER (arm C, send FORCED OPEN)

`s104_score.py` on arm C (§211's translation rule) gives 65 input-dependent `acc` slots:
kernel A **35**, body 0 **28**, body 1 **2**, kernel B **0**, **epilogue 0**.
So the brief's "body 0 ran its ENTIRE ladder on live audio" is confirmed — **and it still ends at
zero.** Three reasons, all MEASURED:

1. **Magnitude.** After `iw92` body 0's accumulator never exceeds `±16 839 598` acc units
   = **±257 as a 24-bit datum**, against the kernel's `±2 156 411 757 232` = railed. The
   "input-dependent" slots `iw113..142` are the CHORUS **tap-modulation** path (§157 `iw96/105/137/146`
   excursion `0..±240`; §153 tapmod ±240; cells `0x0C/0x0E/0x0F/0x10`), not audio.
2. **The one real audio pickup is attenuated by 3 × 10⁻⁶.** `iw112` = `202.A.07.1D5` reads
   `D-RAM[0x05]` in mode 2 — unit 0's live deposit — and `§175 PER-SITE 0202A071D5` in arm C
   reports `coef 0..24 | L −8 034 877..7 192 534`. `24 / 2^23` = **−111 dB**. The datum arriving
   at `iw113` is `±46`. Grade: **MEASURED** per-site; the *cause* (the cursor sitting in the
   `0x50..0x8B` ramp bank rather than `0x90..0xB4`) is **INFERRED**, and is §52 / register row 25.
3. **The exit words load from a zero product.** `iw150` = `000.A.00.415` (`f31 = 0`, `acc ← P`,
   `L = acc_to_datum(1800) = 0`), `iw151` = `212.A.EC.1D5` (`L = D-RAM[0xFC] = 0`),
   `iw152` = `880.1.60.000` (delay WRITE, `f31 = 0`, `acc ← P`). Body 0 returns `0`.

---

## 5. CLASSIFICATION — and one candidate I am pre-emptively closing

### 5.1 ⛔ "Collapse the `m_rf` / `m_dram` alias so `w63` sees the live cell `0x05`" — DO NOT RUN IT

This is the obvious-looking fix and it is wrong, for three reasons stacked:

* `w63` = `2A7.9.05.1C3` reads index `0x05` in the **mode-1** space, while unit-0's live audio is
  `D-RAM[0x05]` (mode 2). The numeric collision is tempting.
* **But §97 is FORCED** (via `output-stage-decode.md` item J's forcing: if mode-1 `ACT 0x07` wrote
  the addressed register, the user's effect depth at `0x06` would survive exactly one frame). Both
  routes index with 8 bits; collisions are expected either way (§97 §2 states this explicitly).
* And `§186 HOST tag-0x15 WRITE TARGETS` shows the host itself writes register `05` and `85`
  (`05:1(z) … 85:1(z)`), i.e. they are host-owned parameter cells that happen to be zero — the same
  class as `86:3` (the unit-1 level). `register-space.md` C2 already classifies `0x0F/0x8C/0x8D/0x8F`
  as host-uninitialised, register-like cells.

⇒ **The epilogue's addressable operand set contains no cell that any part of the machine fills
with input-dependent data.** Under **every** candidate addressing reading for the four undecoded
sources — `m_rf[addr8]`, `m_dram[addr8]`, `m_dram[m_dp]` — the cells they resolve to
(`0x8C`, `0x8D`, `0x9F`, `0x00`) are measured:

```
  m_rf[8C] = 0        m_dram 8C: 0/1 212 303 nz      m_dram 00: 0/5 883 674 nz
  m_rf[8D] = 39 718   m_dram 8D: 0/2 393 109 nz      m_dram 9F: 0/779 nz
  m_rf[8F] = 0        m_dram 8F: 0/1 188 302 nz      m_dram FF: 0/2 352 786 nz
```

and `m_rf[0x8D] = 39 718` is the **epilogue's own accumulator**, stored by `w61` — a self-loop.

★ **So the decode gap is REAL but NOT LOAD-BEARING: decoding `SRC 0x01/0x05/0x06/0x0A` cannot make
the output stage input-dependent, because there is nothing input-dependent for them to read.**
This is the single most useful negative result in this note, and it says where NOT to spend the
next pass.

### 5.2 The verdict

| component | classification | grade |
|---|---|---|
| `w60`/`w61`/`w68`/`w78` fetch `L = 0` | **DECODE GAP** (`default:` branch), real, **not load-bearing** | **MEASURED** + static census |
| `w65`/`w67`/`w72`/`w73` `acc ← P = 0` | **CORRECT-GIVEN-THE-INPUT** — a consequence of §5.1, and what it destroys is a constant | **MEASURED** |
| body-0 exit accumulator = 0 | **LOSS OF SIGNAL, upstream of the epilogue** — magnitude + `coef = 24` + `acc ← P` at `iw150/152` | **MEASURED** value, **INFERRED** cause |
| body-1 `ACCB ← D-RAM[0xD0] = 0` at `iw205` | **DECODE GAP with a routing consequence** — `ACT 0x0D`'s destination is *enumerated*, not decoded | **MEASURED** value, **INFERRED** attribution |
| "the presentation words are not the audio output" | **REJECTED** — `w73`/`w78` are the machine's only class-C and class-D words, the only two `m_do[]` writers, and `OUTPUT SLOT WRITES` is `0/0` on all six slots | **MEASURED** |

⚠ The report line `285 slots, 285 DECODED, 0 PARTIAL, 0 TRAP` is **counting words, not operand
fetches**. Four of those "decoded" words fetch through a source code with no reading. A coverage
statistic that cannot see a hole in the SOURCE field is not a coverage statistic for this question.

---

## 6. THE PRE-REGISTERED EXPERIMENT

### 6.1 What it is

**`§E1 — THE EPILOGUE / HANDOVER OPERAND-PROVENANCE CENSUS. READ-ONLY. NO GATE, NO DECODE CHANGE,
NO MASK BIT.** New env counter `UPD6383_EPIBUS=1`, default 0, fired count printed.

For every executing slot in `iw 60..81` **and** the four handover slots `iw 152, 153, 54, 200`, on
settled frames (`m_frames_run > 900 000`), record:

* the `SRC` code and **which route the C++ actually took** — one of
  `{m_rf[idx], m_dram[idx], m_dram[m_dp], m_cram[cursor], ACCA, ACCB, tA, tB, DEFAULT(no reading)}`;
* the **resolved index**;
* the value, split quiet/loud;
* ★ the **PROVENANCE**: the `iw` and the frame of the last write to that (array, index) pair, and
  for the accumulator, the `iw` of the last word that wrote it non-zero. Tag propagates exactly
  as §217's `m_dr_prov_iw` already does — **this is standing RULE 17, not liveness.**

Vehicle: the CLEAN one (standing rule 2), notes 21.0 s → 27.5 s, `-seconds_to_run 30`, `-log`
(rule 12: a DSP test with no notes playing is not a test).

### 6.2 THE NULL — computed from `data/drpub_A_off_217.log.gz` BEFORE the run

| # | quantity | predicted |
|---|---|---|
| **N1** | epilogue slots with `L` identically `0` in both buckets | **21 of 22** |
| **N2** | the one exception | `w72`, `L = 4 194 304`, provenance **HOST** (tag 0x15), on ≥ 1 172 160 presentations |
| **N3** | slots taking the `DEFAULT(no reading)` route | **exactly 4** — `w60`, `w61`, `w68`, `w78`, once per frame each |
| **N4** | `§70 ACCA at w73` and `§211 ACCB at w78` | `min == max == 0`, quiet **and** loud |
| **cal** | vehicle | `§54` loud ≈ 313 960 frames; kernel A ≥ 20 INPUT-DEPENDENT slots by §211's rule. **A loud count of 0, or a kernel with none, VOIDS the run.** |

### 6.3 THE FALSIFIERS — two-sided, and each names a specific number

> **F1 — the decisive one.** *No epilogue slot's operand provenance names an I-RAM word inside
> body 0 (`iw 84..153`).* **Predicted: 0 of 22.**
> **F1 FAILS if ≥ 1 does** — and then the loss IS a routing error inside the epilogue, the word
> and the cell are named by the instrument, and §5.1's negative result is overturned. That
> outcome is *better* than the prediction holding.

> **F2.** *The provenance of ACCA at `w73` traces to kernel-B `w54` (or its `w53` product), age 0
> frames, on ≥ 99 % of settled frames, and to a body-0 word on 0 of 540 000.*
> **F2 FAILS if any body-0 `iw` appears**, or if the dominant producer is not `w54`.
> A wrong `iw` number is something liveness cannot fake (RULE 17).

> **F3 — the calibration that can fail.** `w72` must resolve to `m_rf[0x06] = 4 194 304` with
> provenance HOST. **If it resolves anywhere else, the instrument is mis-wired and the run is
> VOID** — no other number in it may be quoted (standing rule: the §46 unguarded-sample trap,
> third occurrence).

### 6.4 THE DECISION RULE, WRITTEN BEFORE THE DATA

* **F1 and F2 both hold** (the predicted outcome): the epilogue is *exonerated as a localisation*
  in the same way `w73` was by §211. The epilogue decode is not the blocker; the next decode pass
  belongs at **body-1 `iw205` (`ACT 0x0D`'s destination, mask bits 42-44, currently selector 1)**
  and at **body-0's coefficient cursor at `iw112` (`coef 0..24`, §52 / row 25)** — in that order,
  because `iw205` kills 128 of body 1's 133 slots and the twelve reverbs are unit 1 (§98 §3).
* **F1 fails**: name the word and the cell; that is a routing error, it is small, and it is fixable.
* **F2 fails**: §216's null has a route after all and the whole localisation re-opens.

### 6.5 ★★★ THE FAILURE MODES, WITH THEIR WRONG NUMBERS STATED IN ADVANCE

**(i) The DC at `w73`, third incarnation.** If anyone instead "fixes" the output stage by stopping
`w65`/`w67` from zeroing ACCA — e.g. by setting mask bit 55 (§138), which is `0` in the shipped
default and `FIRED 0 times` — the result will be:

```
  §70  ACCA AT w73 : min == max == 2 603 010 048   (quiet AND loud)
  §61  unit0/DO1   : peak 19 859   (= 39 718 x 0x400000 >> 23)
```

**19 859 is a DC.** It is arithmetically the same object as the retracted row-16 claim
(`4 988 928 >> 8 = 19 488`). Any report of "IC311 is audible" whose `w73` datum is **19 859**, or
whose ACCA is **2 603 010 048**, is the DC again. (`39 718` is independently confirmed three ways:
`acc_to_datum(2 603 010 048)`, `iw201`'s `L` in both arms, and `§160 m_rf[8D] = 0x009B26`.)

**(ii) ★ The DC at `w78` that WOULD PASS STANDING RULE 1.** If `iw205` is "fixed" so ACCB
survives, `w78` will present:

```
  §211 ACCB AT w78 : quiet 5 205 940 658 .. 5 206 020 096
                     loud  5 199 823 966 .. 5 211 501 287      (arm C values)
  DO2 datum        : 79 438  +/- 90   ->  x 0x178D0B >> 23  =  14 616 +/- 16
```

**`min != max`, so standing rule 1 PASSES. `(loud_lo − quiet_lo) != (loud_hi − quiet_hi)`, so
§211's translation rule ALSO PASSES.** And it is still a DC: a pedestal of **79 438** with a
**±90** ripple — **−59 dB signal-to-DC** — and the *no-stimulus* window already wobbles ±40 around
the *same* pedestal, so notes change the ripple by **2.2×**, nothing more.

> ★ **PROPOSED STANDING RULE 19, earned here without a run:** rule 1 (min vs max) and §211's
> translation rule are **jointly insufficient**. Report the **mean** and the **AC amplitude
> separately**, and require the DC term to be small relative to the AC term, *before* any audio
> claim. `w78` under a naive `iw205` fix is a worked counter-example that defeats both existing
> rules. This is rule 13 ("compare against the INPUT, and always measure a no-stimulus window")
> upgraded from a qualitative instruction to a quantitative one.

---

## 7. HONEST LIMITS

* **This cannot be fully decided statically, and I am saying so plainly.** What *is* decided
  statically: the four decode gaps and their sites (corpus census reproduces the runtime counts
  exactly); the 21-of-22 zero-operand fact (already in the shipped logs, both arms); and the
  cell-content argument in §5.1. What is **not** decided statically is F1/F2 — the *provenance*
  of the epilogue's operands — because no existing log records which array/index a slot resolved
  to. §E1 is exactly the missing readout and it needs one run.
* `SRC 0x0A` (`w78`) is **undecidable by comparison** — one site on IC311, its only other corpus
  occurrence is an IC310 word (`output-stage-io.md` §9, §10). Nothing here changes that, and §E1
  does not attempt to decode it; it measures that it does not matter.
* The `coef 0..24` attenuation at `iw112` is read from `§175 PER-SITE 0202A071D5`. The frame
  trace's `coef` column at the same slot prints `0x1364D9`; the two are sampled at different
  points in the word and I have not reconciled them. The **L range** in the §175 line
  (`−8 034 877..7 192 534`) matches `D-RAM[0x05]` exactly, which is what identifies the site.
  Grade the ×24 as **MEASURED-per-site, unreconciled with the trace column**.
* Everything above is arm C unless stated. Arms A and B are **byte-identical to each other and to
  arm C** in the whole epilogue (`§104` rows 60..81, `§70`, `§211`, `§61`, `SRC CODES STILL
  READING ZERO`). The output-stage null does not depend on `DRPUB` or `SRC0B2`.
