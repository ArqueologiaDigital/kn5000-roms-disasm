# `§S2sq` adjudicated — the class-A multiply squaring its own coefficient

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Date **2026-07-31**. Register head **§224**.
**STRICTLY READ-ONLY pass**: no source edited, no build, no MAME run, no commit. Every number
below comes from the committed corpus (`dsp/disasm/*.dsm`, 41 listings / 3057 words), from
`upd6383.cpp` / `upd6383d.h` as they stand, and from logs already on disk
(`data/I_s2_224.log.gz`, `data/F_satcen_223.log.gz`). Scratch scripts:
`scratchpad/sqcensus.py`, `sq_gate_226.py`, `sq_ladder_226.py`, `sq_extra_226.py`.

Labels: **MEASURED** / **FORCED** / **INFERRED** / **SPECULATIVE**.

⚠ **RULE 19 / THE STANDING TRAP.** This pass makes **no audio claim of any kind**. `§70 ACCA@w73`
and `§211 ACCB@w78` are `mean 0.0 span 0` in **both** buckets in arm `I` (`I_s2_224.log:2162-2163`),
which is the arm every number here is quoted from, and nothing in this note moves them.

---

## 0. RESULT

| # | statement | grade |
|---|---|---|
| **A** | ★★★ **THE SQUARING IS FAITHFUL AS A MECHANISM AND IT IS NOT A MIS-BOUND OPERAND.** The multiply has exactly **two** ports: a coefficient port **hardwired** to `C-RAM[ccur]` (no instruction field selects it) and **one** operand bus `L` selected by `SRC`. There is no third, sample-only port for the rival to occupy. A word whose `SRC` routes `C-RAM[cursor]` onto that one bus *necessarily* multiplies the coefficient by itself — this is what a single-read-port coefficient RAM broadcast to a MAC does. | **FORCED** (source, §2) |
| **B** | ★★★ **THE RIVAL — "one operand should be a SAMPLE and we bind the coefficient to both ports" — IS REFUTED, and refuted from disk.** It requires `SRC 0x08` to be a sample source. `SRC 0x08 = C-RAM[cursor]` is anchored by the CHORUS LFO: at `iw89` the trace has `L = 114`, `acc = 7 471 104 = 114 << 16` **exactly**, and `114 = C-RAM[0x00] = floor(0.5993 · 2²³/44100)`, the constant `lfo_ramp.py` derives from the ROM. A sample there gives no ramp. (Also `LEDGER.md` dead end **#5**.) | **FORCED** |
| **C** | ★★★ **`§S2sq` UNDERCOUNTS: THERE ARE TWO ROUTES THAT PUT `C-RAM[cursor]` ON THE BUS, AND THE COUNTER SEES ONE.** Route (a) `SRC 0x08` (`upd6383.cpp:3262`) sets `m_s2_bus_cram`; route (b) `SRC 0x00 ∧ f98 == 1 ∧ class A` (`:3332`, **mask bit 59, SET in the default**) does the identical `C-RAM[m_cursor]` read and sets **nothing**. **Confirmed in §224's own log**: CHORUS `iw94` = `0192A40000`, trace `n=60` prints `L = 240`, cursor post `0x03` ⇒ pre `0x02`, `C-RAM[0x02] = 0000F0 = 240`, and `P = 900 = 240² >> 6`. | **MEASURED** (§3.1) |
| **D** | ★★ **CENSUS, against the gate the build actually uses.** `893` corpus words reach the multiply block; `804` issue it; **`123` square (13.77 % of gated, `94` of the `804` that issue)** — `82` by route (a), `41` by route (b). Slot-weighted over the 91 algorithm slots: **`203` of `1590` = 12.77 %**. **THE NULL: `P(SRC 0x08 | not gated) = 0.05 %` (1 of 2096)** — `SRC 0x08` is essentially *defined* by the gate (81 of its 83 corpus occurrences are class A, 97.6 %), which **supports** the decode rather than impeaching it. | **MEASURED** (§3) |
| **E** | ★★★ **THE THREE INDEPENDENTLY-VALIDATED PROGRAMS CONTAIN ZERO SQUARING WORDS.** PARAMETRIC EQ `0 of 70`, SINGLE DELAY `0 of 18`, ROOM REVERB 1 `0 of 33`. So no validated result has ever exercised the squaring — it cannot be defended *or* blamed by them, and any experiment on it is **inert on all three by construction**. | **MEASURED** |
| **F** | ★★★★ **THE `1.720 × FS` OVERFLOW IS NOT CAUSED BY THE SQUARING. IT IS CAUSED BY THE CURSOR BASE.** `iw30/32/33` consume `C-RAM[c..c+2]`. Shipped, `c = 0x9B`, which is **unit 1's reverb bank** — the header inherits it from the *previous frame's* unit-1 `CALL` rebase (`:5878`, mask bit 38, SET), because **nothing seeds the cursor at frame start**. Run the identical squaring ladder at `kernel.dsm`'s own annotated base `0x0B` and it lands at **`+0.125 FS`, no clip.** | **MEASURED** (§6) |
| **G** | ★★ **AND THE HEADER'S BANK IS A FILED OPEN QUESTION, NOT AN OVERSIGHT OF THIS PASS.** `notes/kn5000-dsp-headerdecode.md` §5: *"The header therefore reads a **separate, fixed coefficient bank**, loaded once at boot"*; §7 item 6: *"The 23 header cursor-fetch words have no coefficients to point at … I did not find the upload that fills it."* `k3-pointers.md` §4.2: *"whatever sets the cursor's per-unit base is still unidentified"*. `cram-unit-base.md` item A measured unit **bodies** (1546 class-A words); it says nothing about the header. | **MEASURED** (existing notes) |
| **H** | ★★ **THE COEFFICIENTS ARE NOT MIS-SCALED.** `C-RAM[0x9B/0x9C/0x9D] = 4CCCCC / 400000 / 400000 = +0.600000 / +0.500000 / +0.500000` in Q0.23. They arrive on the **command-0x02 coefficient stream**, not on tag `0x26` — `I_s2_224.log:2858` `C-RAM WRITE RUNS (3): [0x50..0x8B]=60 [0x90..0xB4]=37 [0x00..0x13]=20`, and that instrument counts **only** the cmd-0x02 path (`:1636` is its sole increment). `60+37+20 = 117` = the log's own *"117 coefficients routed"*, and `117 − 112 non-zero = 5` = exactly the five cells written with zero. | **MEASURED** |
| **I** | ★★ **AND THE SCALING IS FORCED, BOTH DIRECTIONS.** ×2 is **arithmetically impossible**: the bank's largest cell is `0x600000 = +0.750000`, which doubled is `+1.5`, unrepresentable in Q0.23. ÷2 contradicts `C-RAM[0x00] = 114`, written by the **same** cmd-0x02 path with the **same** (no) scaling and independently known from the ROM. Round-2-dp cells: **21 of 37 as shipped**, 13 at ×½, 13 at ×2. | **FORCED** |
| **J** | ★ **`>> 6` IS ONE BIT TOO FEW, AND FIXING IT DOES NOT FIX THE LADDER.** Q-consistency requires `P_SHIFT = 46 − (23 + ACC_SHIFT) = 7`; the code uses 6, so **every** product in the device is exactly 2× its Q-consistent value. With `P_SHIFT = 7` the ladder still reaches **`1.110 × FS`** — reproducing §224 §7.5 independently. ⛔ **NOT a recommendation to change it**; §41 and `m_rf[0x8D] = 0x009B26` calibrate the chain. | **FORCED** (arithmetic) |
| **K** | ★ **TWO SPLIT-PORT SITES EXIST AND ARE MEASURED.** The §72 relocation (`:4663-4665`, mask bit 17, SET) is applied to `ccur` **only**, not to the `SRC 0x08` bus read. At `kernel iw45` (cursor `0x70`) and `kernel iw53` (cursor `0x50`) the same word therefore reads **two different cells**: trace `n=45` shows `L = 0` (`C-RAM[0x70] = 000000`) while the coefficient is `C-RAM[0xB0] = 400000`. | **MEASURED** |
| **L** | ⚠ **§224's *"for the LFO the squared product is inert"* IS TRUE ONLY OF THE PUBLISHED DATUM.** The product **does** enter the accumulator: `iw90 acc = 7 471 104 + (1 006 784 << 16) + 203 = 65 988 067 531`, exact to the unit against trace `n=56`. It is inert because `203 < 2¹⁶`, i.e. **0.31 % of one datum LSB**, so it vanishes at `acc_to_datum()`. State it that way, not as "unused". | **MEASURED** |

**VERDICT — `FAITHFUL`, with the overflow re-attributed.** Not *mis-bound operand* (item A/B), not
*mis-scaled coefficient* (items H/I), not *undecidable statically* — it was decided statically. The
squaring is what this datapath does when a word routes a coefficient onto its single operand bus,
and it is numerically negligible everywhere the microcode puts a small constant there (LFO
increments, envelope time constants: measured products **203** and **900**). It is destructive at
exactly five kernel-header slots, and there it is destructive **because those slots are reading
somebody else's coefficients** (products **395 824 060 170** and **274 877 906 944** — a factor of
`10⁹`). ⇒ **`§S2sq` should be RE-LABELLED, not fixed: it is a correct measurement of a correct
mechanism pointed at a wrongly-addressed bank.**

---

## 1. RULE 20 — the detectors, validated against known answers BEFORE reporting

★★★ **Three of the first seventeen controls FAILED and all three were my statements, not the
detector.** They are reported because that is the point of the rule.

### 1.1 The static field detector (`scratchpad/sqcensus.py`)

```
  total corpus words (§215: 3057 over 41 listings)         3057 / 3057   PASS
  word-bearing listings (index.dsm carries no words)         40 / 40     PASS   <- restated
  c_format words (upd6383d.h: 68 of 3057)                    68 / 68     PASS
  is_c40 words (upd6383d.h: 57)                              57 / 57     PASS
  SRC 0x0B words (§215: 106)                                106 / 106    PASS
    ...class-1 / class-2 non-cfmt (§215, §218: 99 / 7)      99,7 / 99,7  PASS
  ACT 0x00 words, c_format-GUARDED (upd6383d.h: 820)        820 / 820    PASS   <- restated
  ACT 0x00 distinct, c_format-GUARDED (170)                 170 / 170    PASS   <- restated
  lo12 bit-5 ptrmode words (upd6383d.h: 96)                  96 / 96     PASS
  classes 3/7/B/E/F empty under the c_format guard            0 / 0      PASS
  SRC 0x00 class-A, SLOT-WEIGHTED over 91 slots (§146: 111)  111 / 111   PASS   <- restated
  SRC 0x00 all, slot-weighted non-cfmt (§146: 1610)         1653 / 1610  ** FAIL, residual **
  092.A.xx.200 LFO family (§145: 29)                          29 / 29    PASS
  192.A.xx.000 twin family (§145: 29)                         29 / 29    PASS
  182.A.00.000 envelope family (§147: 12)                     12 / 12    PASS
  frame terminator C00.A.47.407 present once, EXCLUDED       1, 0        PASS
  programs.tsv words+classA reproduced, all 38 images       38 / 38      PASS
```

The three restatements each taught something that is now load-bearing below:

* **`820` applies the `c_format` guard.** My first cut got `845`; the 25-word gap is exactly the
  `c_format` words whose bits `[4:0]` happen to read `0x00`. Published `lo12` counts in this
  project are guarded; quote them that way.
* **`§146`'s corpus is SLOT-EXPANDED, not the 41 listings.** `111` class-A `SRC 0x00` words is
  reproduced **exactly** by weighting each image by its `slots` column (91 slots); over the
  listings alone it is `47`. Any census that mixes the two conventions is wrong by ~2.4×.
* **Residual, named and not resolved:** `1610` is not reproduced by any weighting I tried
  (`1653` non-`c_format` slot-weighted is the nearest). The *sharp* control (`111`) passes exactly,
  so the detector is validated where it matters; the `1610` is flagged for whoever owns §146.

### 1.2 The runtime cross-check — the static predicate reproduces §224's own count

The static route-(a) predicate over the executed path (kernel + CHORUS body) yields **seven**
sites: `kernel iw30, iw32, iw33, iw41, iw45, iw53` and `chorus iw89`.
§224's `§S2sq` counted **five**: `iw30 iw32 iw33 iw41 iw89`, `1 020 000` each.

**The two missing ones are exactly the two the §72 relocation splits** (item K): `iw45` runs at
cursor `0x70` and `iw53` at `0x50`, both inside `[0x50,0x8B]`, so `ccur = m_cursor + 0x40` and
`m_s2_bus_cram != ccur`. `7 = 5 counted + 2 split`, and `I_s2_224.log` trace `n=45` shows the
split directly (`L = 0`, cursor post `0x71`, `C-RAM[0x70] = 000000`, `C-RAM[0xB0] = 400000`).
⇒ **the static predicate and §224's live counter agree, site for site, with the discrepancy
explained by a third mechanism that predicts which two.**

### 1.3 The arithmetic detector (`scratchpad/sq_ladder_226.py`)

Eight identities recomputed from the C-RAM dump (`I_s2_224.log:2140-2151`) against numbers §224's
`§S2` printed and the frame trace printed, all **exact to the unit**:

```
   iw30 bus = C-RAM[9B] << 16                     329 853 435 904   PASS
   iw30 P   = C-RAM[9B]^2 >> 6                    395 824 060 170   PASS
   iw33 bus = C-RAM[9D] << 16                     274 877 906 944   PASS
   iw33 P   = C-RAM[9C]^2 >> 6                    274 877 906 944   PASS
   iw33 result = carried + bus + P                945 579 874 058   PASS
   iw89 acc = C-RAM[00] << 16                           7 471 104   PASS
   iw89 P   = C-RAM[00]^2 >> 6                                203   PASS
   iw90 acc = iw89acc + (1 006 784 << 16) + 203    65 988 067 531   PASS   <- item L
```

⚠ **OFF-BY-ONE, honoured.** The trace's `cur`/`coef` are **post**-`exec_decoded()`; every cursor
quoted here is the **pre**-value (`printed − 1` on a class-A word). The trace header lists 13
names over 12 values (`upd6383.cpp:1490`): the real columns are
`n iw u1 word dp acc accb p cur coef mul l` — **there is no `mem[dp]` column**, and reading one
is how the same table has been misquoted before.

---

## 2. ITEM 1 — what the multiply's two operand ports actually are

`upd6383.cpp:4763` is the whole multiply:

```c
m_p = u64((s64(util::sext(coef, 24)) * s64(L)) >> P_SHIFT) & 0xfffffffffffULL;
```

**Two operands, and they are not symmetric.**

### 2.1 Port 1 — the coefficient. HARDWIRED. No instruction field reaches it.

| line | path | live in the shipped default? |
|---|---|---|
| `4661-4666` | `ccur = m_cursor; if (bit 17 && 0x50<=ccur<=0x8B) ccur += 0x40; coef = m_cram.read_dword(ccur)` | ★ **YES — the only one** |
| `4680` | `coef = (coef << 7)` — §53 Q0.16 on the ramp bank | mask bit 13 **clear** |
| `2225` | `if (cursor_fetch(word)) m_k = m_cram.read_dword(m_cursor)` — the **address generator's** latch | runs, but **nothing reads `m_k`** |
| `3931` | `m_k = m_cram.read_dword(addr8(word))` — §43 level-select | mask bit 7 **clear** |
| `4595` | `m_k = L` — §112/§136 | mask bit 54 **clear** |
| `4859` | `m_p = sext(m_k,24) * L >> P_SHIFT` — §40, the **sole consumer of `m_k`** | mask bit 4 **clear** |

⇒ On the shipped build the coefficient port reads `C-RAM[m_cursor]` (± the §72 relocation) and
**nothing else can ever appear there**. `m_k` is written at `4708` and never read. This file's own
comment at `4844-4849` calls that *"a latched-coefficient MAC with the latch bypassed"*.

### 2.2 Port 2 — the operand bus `L`. Field-selected, twelve routes, ONE memory each.

| `SRC` | line | operand |
|---|---|---|
| `0x0B` | `3258` / `3253` | `m_dr` (delay data register) / `D-RAM[m_dp]` under `m_src0b2` (**off**) |
| **`0x08`** | **`3262`** | **`C-RAM[m_cursor]`  ★ ROUTE (a) — the squaring binding** |
| **`0x00`** | **`3332`** / `3337` | **`C-RAM[m_cursor]` when `coeff_consumer ∧ f98==1` (bit 59, SET) ★ ROUTE (b)** / else `D-RAM[m_dp]` |
| `0x02` | `3382` / `3389` | `m_rf[addr8|unit]` (bits 24+23, both SET, class 1) / `D-RAM[m_dp]` |
| `0x03` | `3417` / `3424` / `3430` | `m_xb` crossbar latch / `acc` / `D-RAM[m_dp]` |
| `0x04` | `3354` | `m_ta` |
| `0x07` | `3592` | `m_rf[addr8|unit]` (mode 1, bit 23 SET) or `D-RAM[m_dp]` |
| `0x10` | `3458` | `acc_to_datum(m_acc / m_accb)` |
| `0x11` | `3495` / `3500` | `D-RAM[m_dp]` (bit 18, off) / `acc_to_datum(m_accb)` |
| `0x19` | `3510` | `m_ta` |
| `0x1A` | `3557` | `sext(m_tb) >> 1` |
| others | `3442` | `0`, counted in `m_src_unread[]` |

★★★ **THE ANSWER TO "could the second operand be a bus/sample port we bind to the coefficient?"**
**It IS the bus/sample port.** `SRC 0x07` (`mem[ptr]`, 372 class-A sites), `SRC 0x0B` (the delay
tap), `SRC 0x10` (the accumulator) and `SRC 0x19/0x1A` (the temporaries) are all sample routes and
all reach this same port. The multiply is a sample × coefficient MAC on 762 of 843 class-A words.
On the remaining 81, the microcode *chose* to put a coefficient there — and there is no second bus
for a sample to arrive on at the same time.

⚠ **Two other writers of `P` exist** (`4247`, `4282`: `m_p = L << ACC_SHIFT`, `m_pw = 2/4`, the
`ACT 0x07` latch arms). They are not multiplies and are outside this question.

⛔ **`ACT 0x15` is NOT in the gate** and is not revived here: the census confirms it — of the 472
class-A `ACT 0x15` words, **zero** square (§3.4).

---

## 3. ITEM 2 — the census, with denominators, and the null

⚠ **Corpus scope, stated up front.** `dsp/disasm/index.dsm` records *"38 distinct microprogram
images serve ~100 effect slots; **5 malformed streams excluded (algos 79,88,89,90,91)**"* — the
**IC310 / MN19413 streams are already absent** from every count below, by construction of the
corpus, not by a filter I applied. The **twelve named stub effects** are collapsed into
`prog00_no_operation.dsm` (`slots = 42`); it carries **2** squaring words, so each stub contributes
those same two and nothing individual.

### 3.1 ★★★ There are TWO squaring routes and `§S2sq` counts one

Route (b) is `upd6383.cpp:3324-3336`, mask bit **59**, **SET** in the default
`m_specmask = 0xb910e446a39b440f` (verified programmatically, not by spelling — standing rule 7):

```c
if (m_speculative && ((m_specmask & (1ull << 59))
        ? (coeff_consumer(word) && (((hi12(word) >> 8) & 3) == 1)) : …))
{   L = s32(util::sext(m_cram.read_dword(m_cursor) & 0xffffff, 24));   // ← same cell as `coef`
    e1route = E1_CRAM; …  break; }                                     // ← but no m_s2_bus_cram
```

**Measured, in §224's own arm-`I` log, no new run:** CHORUS body `w10` = `0192A40000`
(`192.A.40.000`, class A, `f98 = 1`, `SRC 0x00`) is `iw94`. Trace `n=60` prints `L = 240`,
`cur` post `0x03` ⇒ pre `0x02`, `C-RAM[0x02] = 0000F0 = 240`, and `P = 900 = (240 × 240) >> 6`.
The same shape repeats at trace `n=69`, `n=101`, `n=110` (`iw103`, `iw135`, `iw144`).
⇒ **`§S2sq: 5 100 000 over 5 slots` is a lower bound**, and its slot list is route-(a)-only.

### 3.2 The census against the gate the build actually uses

⚠ `upd6383.cpp:4647` selects the gate: `(m_speculative && (m_specmask & 4)) ? coeff_fetch(word) :
coeff_consumer(word)`. **Mask bit 2 is SET**, and `kn5000_tonegen.cpp:1813` turns
`m_speculative` on for `DSPCFG` bit 1 — which §217–§224's clean vehicle sets (`:DSPCFG value="3"`).
⇒ **the shipped gate is `coeff_fetch(w) = (class4(w) & 8) && !c_format(w)`, wider than
`coeff_consumer`.** The cursor still advances on class A only.

```
  words reaching the multiply block (class4 & 8, !c_format)  : 893      <- DENOMINATOR
  ...multiply ISSUES (f31 != HOLD)                           : 804
  ...SQUARE a coefficient                                    : 123   13.77 % of gated
       of those, the multiply issues                         :  94   11.69 % of the 804
       route (a)  SRC 0x08                                   :  82
       route (b)  SRC 0x00 & f98==1 & class A                :  41
  class4 of gated words   : {A: 843, 8: 44, 9: 4, C: 1, D: 1}
  class4 of squarers      : {A: 122, 9: 1}
  slot-weighted (91 slots): 203 squaring of 1590 gated = 12.77 %
```

Under the narrower `coeff_consumer` gate the same census is **`81` of `843` class-A words
(9.61 %)**, route (a) only — that is the number to quote if `coeff_consumer` is meant.

### 3.3 ★★ THE NULL — computed before the interpretation

```
  P(SRC 0x08 | any corpus word)              2.72 %   (83 / 3057)
  P(SRC 0x08 | NOT gated, non-c_format)      0.05 %   (1 / 2096)      <-- THE NULL
  P(SRC 0x08 | gated)                        9.18 %   (82 / 893)      <-- OBSERVED
  expected under the null 0.8, sd 0.9  =>  z = +90
  a uniform-over-18-observed-SRC-codes null would be 5.56 %
```

Class-confinement, all `SRC` codes with n ≥ 8, non-`c_format`:

```
   SRC   class-A  non-class-A  % class-A
   0x00      47        575        7.6 %
   0x07     372        557       40.0 %
   0x08      81          2       97.6 %   <== the squaring route
   0x10     242        459       34.5 %
   0x13      41         46       47.1 %
   0x19      43         96       30.9 %
```

★★★ **The interpretation, and it goes AGAINST the defect hypothesis.** `SRC 0x08` is the only
source code in the corpus that is *confined* to coefficient-fetching words — 97.6 % vs 30-47 % for
every genuine operand route. A field value that occurs **only** where a coefficient is being
fetched is exactly what *"this code routes the coefficient onto the operand bus"* predicts, and is
not what a mis-decoded sample source would look like: a sample source has no reason to avoid
class 2. **The enrichment is evidence FOR the decode, not against it.**

### 3.4 By family and by image (denominator = that image's gated count)

```
   family      slots  gated  squaring          image                       gated  sq
   dynamics      43     346    90  26.0 %      prog39_parametric_eq          70    0   0.0 %
   combi         14     405    55  13.6 %      prog09_single_delay           18    0   0.0 %
   reverb        13     418     1   0.2 %      prog16_room_reverb_1          33    0   0.0 %
   modulation     7     118    38  32.2 %      prog99_peq_overdr_delay       44    0   0.0 %
   delay          3      52     0   0.0 %      prog35_exciter                24    0   0.0 %
   distortion     3      32     0   0.0 %      prog33_overdrive              20    0   0.0 %
   am             2      14     8  57.1 %      prog54_ring_modulator          6    4  66.7 %
   rotary         2      70     8  11.4 %      prog50_vibrato                12    6  50.0 %
   filter         2      41     3   7.3 %      prog48_auto_pan                8    4  50.0 %
   eq             1      70     0   0.0 %      prog36_compressor             10    6  60.0 %
   exciter        1      24     0   0.0 %      prog56_mix_up                 15    8  53.3 %
   KERNEL       once     23     6  26.1 %      prog01_chorus                 19    6  31.6 %
```

★★★ **This is NOT scattered, and it is NOT universal.** The split is on whether the program has an
**LFO or an envelope**: every squaring family is `am` / `modulation` / `dynamics` / the `combi`
programs that embed one, and the six families with no such block (`eq`, `delay`, `distortion`,
`exciter`, `reverb`, and PEQ) are at or near **zero**. `52` of the `82` route-(a) words are the two
LFO words `092.A.00.200` (×24, the increment) and `094.A.00.200` (×28, the wrap); `41` of `41`
route-(b) words are `192.A.xx.000` (§145's twin family) and `182.A.00.000` (§147's envelope
smoothers, *"ATTACK SENS. / RELEASE SENS."*).

★★★ **AND THE CONTROL THAT MATTERS MOST:** the three programs whose behaviour is validated against
something outside this device — PARAMETRIC EQ (biquad decoded to the bit, 0.198 dB), SINGLE DELAY
(lag 1001, gain `+0.02149296`, matched to 0.001 %), ROOM REVERB 1 — carry **zero** squaring words
between them, out of `121` gated words. **No validated number in this project has ever depended on
the squaring, in either direction.**

`ACT` field of the squarers vs the rest (class A, route (a)):

```
   ACT     squaring   non-squaring class-A
   0x00        68            49            <- "the operand bus is the adder's term"
   0x15         0           472            <- the corpus's largest ACT; ZERO squarers
   0x12/13/14   0           133            <- the capture codes
   0x19         8             1
```

⇒ `68` of `81` squarers carry **`ACT 0x00`**, the code `upd6383d.h` documents as *"a SELECTOR ON
THE SAME ADDER … it substitutes the operand bus for the accumulator's own feedback term"*.
**The purpose of a squaring word is to put a C-RAM constant on the ADDER. The product is what the
hardware's MAC does with the same read on its way past.**

---

## 4. ITEM 3 — `C-RAM[0x9B]`, `[0x9C]`, `[0x9D]`: what they hold, and where they come from

**Contents**, `I_s2_224.log:2149-2150`:

```
   C-RAM 9B = 4CCCCC = +0.600000        C-RAM 9C = 400000 = +0.500000
   C-RAM 9D = 400000 = +0.500000        (Q0.23, exactly)
```

**Provenance — the cmd-0x02 coefficient stream, NOT tag `0x26`.** MEASURED:

* `I_s2_224.log:2858` `C-RAM WRITE RUNS (3): [0x50..0x8B]=60 [0x90..0xB4]=37 [0x00..0x13]=20`.
  `m_cwr_runlen` is incremented at **one** site, `upd6383.cpp:1636`, inside the `m_host_cmd ==
  0x02` branch. ⇒ these runs are cmd-0x02 writes and nothing else. `0x9B/9C/9D` are inside the
  37-cell run.
* Accounting closes exactly: `60 + 37 + 20 = 117` = the log's own `117 coefficients routed`
  (`:3182`), and `117 − 112 non-zero = 5` = the five cells whose written value is zero
  (`0x03 0x05 0x0E 0x10 0x70`, all visible in the dump). **No cell in C-RAM is unaccounted for.**
* The **13 tag-`0x26` poke packets** (`:2173` `C-RAM 13`; `tags: 26:8 A6:5` — the switch masks
  `tag & 0x7f`, so `0x26` and `0xA6` are one tag) share `m_cram_wp` with the cmd-0x02 stream
  (`:1780`) but land in cells already covered by the three runs. **Which 13 cells is UNRESOLVED**
  and is a gap in the instrument, not a result. ⚠ *(This is the one place I would add a counter.)*

★★★ **THE TWO PATHS APPLY DIFFERENT SCALING TO THE SAME MEMORY, AND THIS IS WORTH RECORDING:**
the tag-`0x26` path runs through §111's `v = (v << 1)` (mask bit 31, **SET**) and §188's LSB
restore (mask bit 63, **SET**); the cmd-0x02 path at `:1625` applies **neither**.

**But the mis-scaling rival is REFUTED for `9B/9C/9D`, both directions:**

1. **×2 is arithmetically impossible.** The bank's largest magnitude is `C-RAM[0x98] = 0x600000 =
   +0.750000`; doubled it is `+1.5`, which a Q0.23 datum cannot hold. **FORCED.**
2. **÷2 contradicts an independently-known constant on the same path.** `C-RAM[0x00] = 0x000072 =
   114` arrives in the `[0x00..0x13]` cmd-0x02 run with no scaling, and `114 = floor(0.5993 ×
   2²³/44100)` is what `dsp/tools/lfo_ramp.py` reads out of the ROM. `C-RAM[0x01] = 0x7FFFFF =
   2²³−1` is the wrap constant. **Two known-right values calibrate this path already.**
3. **Round-decimal count is maximal as shipped**: 21 of 37 cells are round to 2 dp at Q0.23; 13 at
   ×½ and 13 at ×2. The bank reads
   `+0.75 +0.73 +0.72 +0.70 +0.63 +0.62 +0.60 +0.50 +0.45 +0.303030 +0.606061 …` — reverb-gain
   decimals, with `0.303030 = 10/33` and `0.606061 = 20/33` as the two rational outliers.

⚠ **`§Z`, the space-twin store at `m_rf[0x50..0x53]`, does NOT bear on this.** `m_rf` is the
tag-`0x15` register file, a different array from `m_cram`; no path in `upd6383.cpp` writes C-RAM
from `m_rf`. Not audited here, as instructed.

---

## 5. ITEM 4 — is `>> 6` the right shift for a square?

Worked explicitly, no fitting:

```
   a datum is Q0.23                      full scale 2^23
   the accumulator holds datum<<ACC_SHIFT, ACC_SHIFT = 16    full scale 2^39 = 549 755 813 888
   coef x L is Q46                       value = a*b*2^46
   to land at a*b*2^39 the shift must be 46 - (23 + ACC_SHIFT) = 7
   THE CODE USES P_SHIFT = 6
   =>  EVERY product in this device is EXACTLY 2x its Q-consistent value
```

The ladder, and the counterfactual:

```
   iw30  carried            0 + bus 329 853 435 904 + P             0 = 329 853 435 904  0.600 FS
   iw32  carried            0 + bus             0   + P 395 824 060 170 = 395 824 060 170  0.720 FS
   iw33  carried 395 824 060 170 + bus 274 877 906 944 + P 274 877 906 944 = 945 579 874 058  1.720 FS
   with P_SHIFT = 7 :  197 912 030 085 + 274 877 906 944 + 137 438 953 472 = 610 228 890 501  1.110 FS
```

⇒ **`1.110 × FS` — still clips.** Independently reproduces §224 §7.5.

⛔ **THIS IS NOT A RECOMMENDATION TO CHANGE `P_SHIFT`.** It is an observation about internal
Q-consistency, and it cannot be acted on from here: `§41` (`0x400000` / `0x178D0B`),
`m_rf[0x8D] = 0x009B26` and SINGLE DELAY's three-factor `+0.02149296` calibrate `ACC_SHIFT` and the
chain end-to-end, `ACC_SHIFT = 22 − P_SHIFT` ties the two, and halving the products does **not**
cure the ladder anyway. Changing a shift because a number improves is the failure standing rule 9
names.

---

## 6. ITEM 5 — what the ladder computes, and the thing that actually breaks it

### 6.1 Under either reading, the ladder computes a CONSTANT

`iw30/32/33`'s three terms are `C-RAM[c] , C-RAM[c]² , C-RAM[c+2] , C-RAM[c+1]²`. **Not one is a
sample under any reading**, because `SRC 0x08` on all three binds the bus to C-RAM. `iw32` and
`iw34` then *store* (`ACT 0x07`, `mem[p] ← L`, `p−1`). ⇒ `iw29..iw34` is a **coefficient-to-D-RAM
precomputation block**: it derives working constants from the coefficient bank and parks them in
D-RAM for the frame. `§S2` confirms the downstream half — `iw35` and `iw37` take those cells back
off the bus (`busSRC 07`, `333 185 286 144 = 0x4D9364 << 16 = C-RAM[0x90] << 16`).

**Naming the idiom, SPECULATIVE:** a block that emits `g` and `g²` from one coefficient is the
standard precomputation for an all-pass / comb pair (`g`, `1−g²`) or for a one-pole
`y += g·(x−y)` pair. Under the Q-consistent shift and `kernel.dsm`'s own annotated base, `iw34`
would store exactly `g²` for `g = C-RAM[c]`. **If that is what it is, the squaring is not merely
faithful — it is the point of the block.**

### 6.2 ★★★★ The overflow is a function of the CURSOR BASE, not of the squaring

`iw30`'s cursor is `0x9B`. It got there by **carry-over**: `upd6383.cpp:5878` seeds
`m_cursor = unit1 ? 0x90 : 0x00` **at the two CALLs** (§73, mask bit 38, SET, `FIRED 2 390 400
times`), and **nothing seeds it at frame start**. The header therefore runs on whatever the
previous frame's *unit-1* CALL left — the reverb bank at `0x90+` — walking `0x90 → 0xA4` across
`iw0..iw41` (trace `n=0..41`) before `iw42`'s `ldptr #$70` moves it.

`kernel.dsm` annotates the very same words `C-RAM[0x0B] / [0x0C] / [0x0D]` (*"coeff, base 0x00
MEASURED"*). Run the identical squaring ladder there:

```
   base  C[c]    C[c+1]  C[c+2]    iw30 FS   iw32 FS   iw33 FS   clips?
   0x9B  4CCCCC  400000  400000     +0.600    +0.720    +1.720    YES     <- shipped
   0x0B  E00000  E00000  FFFF10     -0.250    +0.125    +0.250    no      <- kernel.dsm's own annotation
```

**THE NULL, computed before the claim** — sweep every base and ask how often the ladder clips:

```
   kernel/body bank 0x00..0x13     2 of  20   10.0 %
   ramp bank        0x50..0x8B     0 of  60    0.0 %
   coefficient bank 0x90..0xB4    28 of  37   75.7 %
   all non-zero bases             31 of 123   25.2 %
```

⚠ **Stated at its real strength.** "Base `0x0B` does not clip" is *not* impressive on its own —
74.8 % of bases do not. The load-bearing half is the other direction: **whenever the header runs
on the host's real coefficient bank it clips 75.7 % of the time, and it is running there for a
reason nobody chose.**

### 6.3 And the header's own bank is a FILED OPEN QUESTION

* `notes/kn5000-dsp-headerdecode.md` **§5**, MEASURED over 38 images: *"(coefficients uploaded) −
  (cursor-fetching words in its body)"* is centred on **+1**, never near +23. *"The header
  therefore reads a **separate, fixed coefficient bank**, loaded once at boot."*
* Same note **§7 item 6**: *"The 23 header cursor-fetch words have no coefficients to point at …
  I did not find the upload that fills it."*
* `k3-pointers.md` **§4.2**: *"whatever sets the cursor's per-unit base is still unidentified"*,
  with three enumerated candidates and none chosen; and *"a reset therefore happens, every frame,
  and it is carried by a word that is not a pointer-load word."*
* `cram-unit-base.md` item **A** measured **bodies** (1546 class-A words, 91 programs). Its
  `base 0x00 / 0x90` result is about unit bodies. It says nothing about the header, and
  `data/AUDIT_ISA_findings.md` **A21** records the CALL-seed as **IMPLEMENTED-BUT-SPECULATIVE**.

⇒ **The kernel header is multiplying by ROOM REVERB 1's coefficients.** That is the defect the
`1.720 × FS` exposes, and the squaring only makes it visible because squaring a `0.6` gain is a
`0.72 FS` event while squaring a `114/2²³` LFO increment is a `203`-unit event —
**a factor of 1.9 × 10⁹, both measured in the same frame** (item L).

---

## 7. THE PRE-REGISTERED EXPERIMENT — `§Q-NOSQ`, for the build lane

⚠ **This touches none of §225's three topics** (RULE 21 / free-running, `W4` + `UPD6383_LFOWRAP`,
kernel A's cell-`0x06` latch-up). It changes no shift, no `ACC_SHIFT`, no store datum, no anchor.

### 7.1 The arm

`UPD6383_NOSQ=1`, env, **DEFAULT OFF**, announced unconditionally, **fired count printed
unconditionally with a per-`iw` breakdown** (standing rule 8, §220's form). Gated **by predicate,
not by line**:

> on a word that reaches the multiply block, if the operand bus was bound to `C-RAM[cursor]`
> — i.e. route (a) `SRC 0x08`, or route (b) `SRC 0x00 ∧ f98 == 1 ∧ class A` — then **hold `P`**
> instead of writing it.

The reading under test: **a single-read-port C-RAM broadcast onto the operand bus presents no
multiplicand, so the MPLY output latch holds** — the same shape as the `f31 == HOLD` suppression
already in the file. The rival is the shipped one: the read is broadcast to *both* ports and `P`
becomes `C²`. **Two-sided; both outcomes are informative.**

★ Ship the counter widening with it (route (b) is invisible to `§S2sq` today), and add a
**SPLIT-PORT** counter for the `ccur != m_s2_bus_cram` case — `kernel iw45` and `iw53` predict it
must be non-zero with exactly two distinct slots.

### 7.2 THE NULL — every number below is from `data/I_s2_224.log.gz`, arm `I`, quoted with its arm

```
   N1  §S2  iw33  carried 395 824 060 170 + bus 274 877 906 944 + P 274 877 906 944
                       = 945 579 874 058   (1.720 xFS)   over q/l 706 040 / 313 960
   N2  §S2  iw32  P = 395 824 060 170                    §S2 iw30 bus = 329 853 435 904
   N3  §S1  TOTALS quiet 9 884 596 / 186 394 560 (5.303 %) | loud 4 391 682 / 82 885 440 (5.298 %)
   N4  §S1  iw34 = 14 428 403 both buckets, clips 706 040 / 313 960 ; iw39 loud min 1 991 044
   N5  §41  unit0 0x400000  unit1 0x178D0B  |  m_rf[8D] = 009B26  |  §160 06=400000
   N6  §54  quiet-in 826 040 -> 826 040 silent / 0 LOUD (peak 0) ; loud-in 313 960 -> 0 loud
            §70 ACCA@w73 mean 0.0 span 0 | §211 ACCB@w78 mean 0.0 span 0, BOTH buckets
   N7  §S2sq 5 100 000, 5 distinct slots | iw30 iw32 iw33 iw41 iw89, 1 020 000 each
   N8  §S2  adder runs recorded 230 520 000 | 44-bit overflows 6 048 301
```

### 7.3 Predictions, committed here

* **P1 — FIRED.** Non-zero, and its distinct slots on the CHORUS frame must be exactly
  `{iw30, iw32, iw33, iw41, iw45, iw53, iw89}` (route a) **∪** `{iw94, iw103, iw135, iw144, …}`
  (route b). **If it fires 0 times the arm is VOID**, not a refutation.
* **P2 — THE DECIDER, and it is sharp and binary.** With `iw30`'s product suppressed, `P` entering
  `iw32` is `0` (trace `n=23` shows `P = 0` at the last multiply before `iw30`), so `iw32`'s
  accumulator becomes `0`, `iw33`'s carried term becomes `0`, and
  **`iw33 = 0 + 274 877 906 944 + 0 = 274 877 906 944 = 0.500 FS`.**
  ⇒ **the `§S2` `iw33` row must LEAVE the overflow table** and **the `§S1` `iw34` row must LEAVE
  it too**, its pre-clamp value falling from **`14 428 403`** to **`4 194 304`**.
* **P3 — THE CONTROL WHOSE ANSWER IS ALREADY KNOWN.** PARAMETRIC EQ contains **0 squaring words of
  70 gated** and SINGLE DELAY **0 of 18** (§3.4, MEASURED). The arm is therefore **inert on both by
  construction**. Re-run the PEQ transfer-function check and SINGLE DELAY's `lag 1001 /
  +0.02149296`: they must be **bit-identical**. **If either moves, the gate is mis-implemented and
  the arm is VOID** — this control can fail, and it fails for exactly one reason.
* **P4 — MUST NOT MOVE:** `N5` and `N6` in full. ⚠ If `§70`/`§211` leave `mean 0 span 0`, report
  **mean and AC span separately** (RULE 19) and treat it as an unrelated event; **this experiment
  cannot produce audio and no audio claim may be built on it.**
* **P5 —** `dsp/verify.py` **BYTE-MATCH OK**.

### 7.4 ★★ THE NAMED SPECIFIC WRONG NUMBER — the failure mode

> **If `§S2`'s `iw33` row comes back `945 579 874 058`** — the shipped value, to the digit — **the
> arm did nothing**: the gate fired after the adder, or on the wrong predicate, or `L` was rebound
> without `P` being held. That is **VOID, not a refutation of the reading**, and the next pass must
> not record it as one. Second named wrong number: a **fired count of `0`** with `UPD6383_NOSQ=1`
> announced — same verdict, and the reason §220's rule exists.

### 7.5 Decision rule, committed before the run

Ship **nothing** on this alone. `P1 ∧ P2 ∧ P3 ∧ P4 ∧ P5` ⇒ the squaring is confirmed as the sole
source of the kernel-header clip, and the next question is **the header's coefficient bank**
(`headerdecode.md` §5 / §7.6, `k3-pointers.md` §4.2) — which is a *decode* question, not a gain
one. `P2` failing **with a non-zero fired count** ⇒ the shipped broadcast reading survives, the
squaring is load-bearing, and `UPD6383_NOSQ` is filed as a dead end with its refutation.

---

## 8. WHAT THIS RETIRES OR CORRECTS

| claim | status |
|---|---|
| *"the class-A multiply squares its own coefficient — 5 100 000 times, 5 slots"* (§224 §3) | ★ **A LOWER BOUND.** Route (b) (`SRC 0x00 ∧ f98==1`, mask bit 59, SET) does the identical `C-RAM[m_cursor]` read and sets no flag. `41` corpus words; CHORUS `iw94` measured squaring `240² >> 6 = 900` in §224's own trace |
| *"for the LFO the squared product is inert — the word uses its bus term, not `P`"* (§224 §3) | ⚠ **IMPRECISE.** It **does** enter the accumulator: `iw90 = 7 471 104 + (1 006 784 << 16) + 203`, exact. It is inert because `203 < 2¹⁶` = **0.31 % of one datum LSB** and vanishes at conversion |
| *"the multiply's gate is `coeff_consumer` = `class4 == 0xA && !c_format`"* | ⚠ **NOT ON THE SHIPPED BUILD.** Mask bit **2** is SET, so `upd6383.cpp:4647` selects `coeff_fetch` = `(class4 & 8) && !c_format`. Denominator `893`, not `843`; class 8 (44 words) and class 9 (4) multiply too |
| *"`iw33`'s 1.720 × FS overflow is the squaring"* | ★★★ **RE-ATTRIBUTED.** The same squaring ladder at `kernel.dsm`'s annotated base `0x0B` lands at `+0.125 FS`. The kernel **header** consumes `C-RAM[0x9B..]` — **unit 1's reverb bank** — because the cursor is *inherited* from the previous frame's unit-1 CALL and never seeded at frame start |
| *"the host writes C-RAM via tag `0x26`"* (the brief's framing) | ⚠ **13 packets do; `0x9B/9C/9D` do not.** All 117 populated cells are accounted for by three **cmd-0x02** runs (`[0x50..0x8B]=60 [0x90..0xB4]=37 [0x00..0x13]=20`), and `m_cwr_runlen` has exactly one increment site, inside the cmd-0x02 branch |
| *"a mis-scaled coefficient would explain the overflow"* | ⛔ **REFUTED both directions.** ×2 is impossible (`0x600000 → +1.5`, unrepresentable in Q0.23); ÷2 contradicts `C-RAM[0x00] = 114` on the same path with the same decode. Round-2dp count is maximal as shipped (21/37 vs 13/13) |
| *"`ACT 0x15` is in the multiply's gate"* (retracted at §174) | ⛔ **STAYS RETRACTED, and the census adds a positive:** of `472` class-A `ACT 0x15` words, **zero** square |
| *"the §72 relocation is a coefficient-bank fix"* | ⚠ **IT IS ASYMMETRIC.** Applied to `ccur` (`:4663`) and **not** to the `SRC 0x08` bus read (`:3262`), so at `kernel iw45` and `iw53` one word reads two different cells (`C-RAM[0x70] = 0` on the bus, `C-RAM[0xB0] = 400000` as the coefficient). Measured, trace `n=45` |

---

## 9. WHAT THIS PASS IS BLIND TO

* **Everything is static or from four archived logs.** No build, no run. The runtime claims are
  read out of `data/I_s2_224.log.gz` (arm `I`, the shipped default, `DSPCFG=3`, CHORUS on unit 0 /
  ROOM REVERB 1 on unit 1) and are **arm-conditional** — quote the arm with the number.
* **One frame, one effect pair.** The `iw45`/`iw53` split-port sites and the `0x9B` base are
  properties of *that* configuration. A body whose `ldptr` history differs will land elsewhere.
  The corpus census is configuration-independent; the ladder arithmetic is not.
* **The 13 tag-`0x26` C-RAM targets are unrecorded.** The accounting closes without them, which is
  evidence they overlap the cmd-0x02 runs, not proof. A `m_pk_cram_cell[]` histogram would settle
  it and does not exist.
* **`§146`'s `1610` is not reproduced** (§1.1). The sharp control (`111`) is, so the census stands,
  but that residual belongs to whoever owns §146.
* **The header's correct cursor base is NOT determined here.** This pass shows it is *inherited*
  and shows what the ladder does at two candidate values. It does not find the bank
  `headerdecode.md` §5 says exists, and it does not propose one.
* **`f31` code 5** appears on 10 squarers (`09A.A.00.200` ×9, `29A.A.B8.21A`) and its accumulator
  behaviour is `HOLD`'s no-product path only for code 2; code 5 is OPEN (`upd6383.cpp:3905-3915`),
  so those ten words' arithmetic carries that unknown.
* **No audio was measured and none may be inferred.** `§70`/`§211` are `mean 0.0 span 0` in both
  buckets in the arm every number here comes from.

---

## 10. SUMMARY — ten lines

1. **The squaring is CORRECT as a mechanism.** The multiply has one hardwired coefficient port
   (`C-RAM[ccur]`, no field selects it) and **one** operand bus; a word that routes the coefficient
   onto that bus has no second port for a sample, so `P = C²` is what the datapath must do.
2. **The rival is refuted from disk:** `SRC 0x08 = C-RAM[cursor]` is anchored by the CHORUS LFO —
   `acc = 114 << 16 = 7 471 104` exactly, `114` being the ROM-derived ramp constant.
3. **Fraction: `123` of `893` gated words square = `13.77 %`** (`94` of the `804` that issue;
   `81/843 = 9.61 %` under the narrower `coeff_consumer` gate; `203/1590 = 12.77 %` slot-weighted).
4. **The null is `0.05 %`** (`P(SRC 0x08 | not gated)`, 1 of 2096), `z = +90`: `SRC 0x08` is 97.6 %
   confined to coefficient-fetching words — **evidence FOR the decode**, not against it.
5. **`§S2sq` undercounts:** a second route (`SRC 0x00 ∧ f98==1`, mask bit 59, SET) squares
   identically and sets no flag — measured at CHORUS `iw94`, `240² >> 6 = 900`, in §224's own log.
6. **`C-RAM[0x9B/9C/9D] = +0.600000 / +0.500000 / +0.500000`**, written by the **command-0x02
   coefficient stream** (not tag `0x26`), and the scaling is **FORCED correct** — ×2 is impossible
   (`0x600000 → +1.5`), ÷2 contradicts `C-RAM[0x00] = 114` on the same path.
7. **`>> 6` is one bit too few for Q-consistency (`7` is), but halving still clips at `1.110 × FS`**
   — so the shift is not the cause and must not be changed on a moved number.
8. **★ The `1.720 × FS` overflow is NOT the squaring — it is the CURSOR BASE.** The kernel header
   runs at `0x9B`, inherited from the previous frame's unit-1 CALL, i.e. on **ROOM REVERB 1's
   coefficients**; at `kernel.dsm`'s own annotated base `0x0B` the identical ladder lands at
   `+0.125 FS` and does not clip. `headerdecode.md` §5 already says the header's bank is separate
   and §7.6 already says nobody has found it.
9. **The squaring has never touched a validated result**: PARAMETRIC EQ `0/70`, SINGLE DELAY
   `0/18`, ROOM REVERB 1 `0/33`.
10. **Recommended experiment: `§Q-NOSQ`** — hold `P` on words whose bus is bound to
    `C-RAM[cursor]`; default OFF, two-sided; null `§S2 iw33 = 945 579 874 058 (1.720 FS)`;
    prediction `iw33 → 274 877 906 944 (0.500 FS)` and `§S1 iw34 → 4 194 304`; control that is
    **inert by construction** on PEQ and SINGLE DELAY; failure mode **named**: `iw33` returning
    `945 579 874 058` or a fired count of `0` means **VOID, not refuted**.
