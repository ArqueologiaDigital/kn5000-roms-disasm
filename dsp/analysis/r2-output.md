# R2 — RESULT ROUTING: where a unit result goes, and how it reaches the DO ports

**NEC uPD6383GF-3BA (Technics SX-KN5000 IC311).** Roadmap items **R2** (the terminator
store `612.1.0F.000`) and **THE DO WRITE** (`w73` / `w78`, the machine's only class-C and
class-D words, left OPEN by K5). Date 2026-07-26.

No hardware was used and none is needed for anything claimed here. Every statement is
tagged **MEASURED** (counted over the ROM corpus / the cold-boot capture), **PROVEN BY
CONSTRUCTION** (read out of the bytes that produce it), **FORCED** (the only assignment a
stated rule admits), **INFERRED**, or explicitly **OPEN**. Where a constraint system admits
several assignments they are **enumerated**, not chosen.

Scope: this pass owns ADDRESSING and ROUTING. It does **not** touch `lo12`'s arithmetic
meaning (a concurrent pass owns that) and it edited no file under `src/devices/cpu/upd6383/`.
§10 lists what it constrains for that pass.

---

## 0. Executive summary

| # | finding | status |
|---|---|---|
| 1 | **`hi12` bit 11 (FORMAT ESCAPE) is the MEMORY-SPACE selector.** It is set on **0 of 2399** mode-2 words (the D-RAM pointer mode) and **0 of 53** mode-6 words, and on 370 words of modes 0/1/4/5. Exceptionless over the whole 3057-word corpus. | **MEASURED (3057/3057)** |
| 2 | **`class4 & 7` is an ADDRESSING MODE** (`class4` bit 3 stays the cursor-fetch enable). **Mode 1 without escape = an internal REGISTER FILE indexed by `addr8`; mode 1 with escape = the external delay DRAM** (`addr8` = sub-op `0x20/0x30/0x60`). 324/324 class-1 words split cleanly on the escape bit. | **MEASURED** |
| 3 | **K6's lead "class-1 `addr8` splits on bit 7" is FALSIFIED.** `0x06`, `0x0E`, `0x0F` are all `< 0x80` yet are *not* DRAM sub-ops. The escape bit gets all 324 right; bit 7 of `addr8` gets 3 wrong. | **FALSIFICATION** |
| 4 | The mode-1 register index space is the **same space the host addresses with `000.1.NN.000`** — 3 of the 6 in-program indices (`0x06`, `0x85`, `0x8A`) are literally poked by the host at cold boot. The host space is proven **auto-incrementing** by a 9-select run `0x1D,0x21,…,0x3D` (step 4, four values each). | **MEASURED** |
| 5 | **Bit 7 of a mode-1 register index is the EFFECT-UNIT selector** (0 = unit 0, 1 = unit 1). Five independent positional confirmations, zero counter-examples. | **MEASURED / INFERRED (strong)** |
| 6 | **Registers `0x06` (unit 0) and `0x86` (unit 1) are the per-unit OUTPUT LEVELS.** The last four host actions of cold boot are `setvec unit1,#200`, `setvec unit0,#84`, `reg 0x06 ← +0.500000`, `reg 0x86 ← +0.183992`. | **PROVEN BY CONSTRUCTION** |
| 7 | **`w73` and `w78` are the two OUTPUT PRESENTATIONS, one per unit.** Only **3 of the 370** escape words in the machine carry `hi12` bit 4, and only **1 of the 68** C-format words does — and all four are `w73, w74, w77, w78`. They form two pairs either side of the wait word `w76`; `w72` reads unit 0's level register and `w77` carries unit 1's. | **MEASURED + INFERRED (strong)** |
| 8 | **The epilogue writes TWO outputs, not three.** `DO1 → SDIA` = unit 0, `DO2 → SDIB` = unit 1, and **`DO3` is never written by this microcode**. Falsifiable hardware prediction: DO3 carries nothing. | **INFERRED (strong)** |
| 9 | **FORCED: there is a per-unit RESULT REGISTER, and the unit result never passes through D-RAM.** The output stage performs **zero D-RAM reads before `w73`** — its only three D-RAM accesses (`w79/w80/w81`) all come after both presentations and are K6's FORCED one-frame loop. Unit 0's result must survive 156 intervening words, so it is not in the accumulator either. | **FORCED** |
| 10 | **The terminator's bit-4 store is NOT the result-routing mechanism.** Only 5 of 38 bodies set it; the other 33 deliver a result anyway. Two readings of what it *is* are enumerated; neither carries the result. | **MEASURED + enumerated** |
| 11 | **K6's unit-1 "2-cell discrepancy" rests on a mis-modelled word and dissolves.** `w53` is class **9** = mode 1 = a *register* access, not a `mem[ptr]` store; K5's DETERMINED result on `w64`/`w71` (class 9, bit 4, destination = the call vector) proves a mode-1 bit-4 word does not write `mem[ptr]`. K6 resolution **1 is eliminated**, resolution **2 is confirmed**, and `w55`/`w57` are ordinary pointer movers after all. | **FORCED** |
| 12 | Calibration against over-reading: **write-never-read D-RAM cells are common** — 21 of 38 bodies contain at least one (32 cells). "Written and never read" is therefore **not** by itself evidence of a hardware latch, which weakens K6 §10's reading of `X+3`. | **MEASURED** |
| 13 | **The C-RAM cursor base cannot be loaded by microcode.** `rstcur` occurs **once in 3057 words** (inside `b39`, mid-program), and none of the eight kernel pointer-load words carries `0x00`/`0x90`. The per-unit bases must be chip state only the host writes. | **PROVEN BY ELIMINATION** |
| 14 | The output stage is **lexically disjoint** from the rest of the machine: **20 of its 23 words**, **14 of its `lo12` values** and **13 of its `hi12` values** occur nowhere else in 3057 words. Any `lo12` model fitted to body statistics is structurally blind to it. | **MEASURED** |

---

## 1. The escape bit is the memory-space selector (**MEASURED**)

Every non-C-format word was classified by `mode = class4 & 7` and by `hi12` bit 11:

```
   mode  cursor  ESC     n          mode 2 = the D-RAM data-pointer mode
    0     no     no     62          mode 1 = "not D-RAM"
    0     no     yes    47          mode 4 = the table-lookup mode
    0     yes    yes    44          mode 6 = the table-selector mode
    1     no     no     48
    1     no     yes   276   <- the 880/800/900 external delay-DRAM family
    1     yes    no      4   <- class 9: w53, w63, w64, w71
    2     no     no   1556
    2     yes    no    843
    4     no     no     53   <- 012.4.01.1CE, the table-lookup writer
    4     yes    yes     1   <- w73
    5     no     yes     1   <- w67
    5     yes    yes     1   <- w78
    6     no     no     53
```

**Mode 2 — the only mode that moves the data pointer — is NEVER escape: 0 of 2399.**
Mode 6 is never escape either. Escape appears only in modes 0, 1, 4 and 5. Reading bit 11 as
*"this word does not address D-RAM through the data pointer"* costs nothing anywhere in the
corpus and immediately explains why `addr8` means a **sub-op** on the `880`/`800`/`900`
family: it cannot be a pointer delta, because the pointer is not what is being addressed.

Note also: **class 3 and class B do not exist.** All 31 words with `class4 & 7 == 3` are
C-format words whose `class4` field is immediate data. Same for classes 7/E/F: absent.

### 1.1 Class 1 splits perfectly, and K6's bit-7 lead is FALSIFIED

```
   ESC = 1 : addr8 ∈ {20, 30, 60}                          n = 276, hi12 ∈ {800, 880, 900}
             hi12 bit 4 (store) set on 0 of 276
   ESC = 0 : addr8 ∈ {06, 0E, 0F, 85, 8A, 8C, 8D, 8F}      n =  48, hi12 = 14 distinct values
             hi12 bit 4 set on 8 of 48
```

K6 §10 item 7 offered *"bit 7 of a class-1 `addr8` selects address-vs-sub-op"* as a lead. It
is **wrong**: `0x06`, `0x0E` and `0x0F` are below `0x80` and are **not** DRAM sub-ops — they
are register indices and unit tags. The escape bit classifies all 324 correctly; `addr8`
bit 7 misclassifies 3. **The lead is replaced, not refined.**

### 1.2 Mode 1 without escape is a REGISTER FILE — and the host uses the same space

Decoding the `01 60` windows of `notes/data/kn5000_dsp1_upload_coldboot.txt` (K6's rule:
5-byte packets, `0A aa bb cc dd` = a 24-bit value with tag `dd & 0x7F`), the host issues
**twenty-one `000.1.NN.000` words**, each followed by a run of tag-`0x15` values:

```
   reg  0x05(2)  0x06(1,1)  0x07(1)  0x0E(1)  0x10(2)  0x50(0)
        0x1D(4)  0x21(4)  0x25(4)  0x29(4)  0x2D(4)  0x31(4)  0x35(4)  0x39(4)  0x3D(4)
        0x85(2)  0x86(1,1)  0x87(1)  0x8A(2)  0x94(1)  0xD0(3)
```

The run `0x1D, 0x21, 0x25, 0x29, 0x2D, 0x31, 0x35, 0x39, 0x3D` — **nine selects, stride 4,
four values after each** — tiles `0x1D..0x40` without gap or overlap. That is an
auto-incrementing, byte-indexed register file, **MEASURED**, and it is a 9-fold internal
consistency check on the decode. (At cold boot every value is 0; transfers 40-48 later fill
`0x1D..0x40` with real Q0.23 coefficients, so this block is coefficient/parameter storage,
not audio.)

**The overlap with the microcode is exact.** The in-program mode-1 indices are
`{0x05, 0x06, 0x0E, 0x0F, 0x85, 0x8A, 0x8C, 0x8D, 0x8F, 0xD0}`; the host writes
`0x05, 0x06, 0x0E, 0x85, 0x8A, 0xD0` of them. **⇒ the epilogue's class-1 words address chip
registers, not D-RAM.** `0x8C`, `0x8D`, `0x8F` are the three the host never touches.

### 1.3 Bit 7 of a register index is the UNIT selector

| word | reg | bit 7 | position in the frame | reading |
|---|---|---|---|---|
| header `w58` `000.1.8A.007` | `0x8A` | 1 | **inside the unit-1 setup block** (50..59) | unit 1 |
| header `w53` `010.9.D0.20C` | `0xD0` | 1 | **inside the unit-1 setup block** | unit 1 |
| epi `w63` `2A7.9.05.1C3` | `0x05` | 0 | **immediately before the unit-0 vector `w64`** | unit 0 |
| epi `w70` `2A6.1.85.0C7` | `0x85` | 1 | **immediately before the unit-1 vector `w71`** | unit 1 |
| epi `w72` `000.1.06.087` | `0x06` | 0 | immediately before `w73` | unit 0 |
| epi `w77` `859.0.86.822` | `0x86` | 1 | immediately before `w78` | unit 1 |
| epi `w60/61/65/66/68` | `0x8D,0x8F,0x8C` | 1 | run right after the unit-1 body returned | unit 1 |

Five independent positional confirmations, **no counter-example** among the twelve
in-program mode-1 register accesses. The host corroborates it by clearing the indices in
**bit-7-matched pairs**: `0x05/0x85`, `0x06/0x86`, `0x07/0x87`, `0x50/0xD0`.

The one place the rule does **not** apply is `addr8 ∈ {0x0E, 0x0F}`, where `hi12` bit 10
(END OF BLOCK) is also set — there `addr8` is the **unit tag** (0x0E = unit 0, 0x0F = unit 1),
40/40. Bit 10 changes `addr8`'s role; that is exactly the horizontal-microword behaviour
`instruction-set.md` already documents for bit 11.

---

## 2. Registers `0x06` / `0x86` are the per-unit OUTPUT LEVELS (**PROVEN BY CONSTRUCTION**)

The **last four host actions of the cold boot**, in order, are:

```
  transfer 50   I-RAM 71 <- 0C41900446 = C41.9.00.446   imm13 = 0x1900 = 200*32   setvec unit1,#200
  transfer 51   I-RAM 64 <- 0C40A80445 = C40.A.80.445   imm13 = 0x0A80 =  84*32   setvec unit0,#84
  transfer 52   000.1.06.000  then  0A 20 00 00 15  ->  reg 0x06 <- 0x400000 = +0.500000
  transfer 53   000.1.86.000  then  0A 0B C6 85 95  ->  reg 0x86 <- 0x178D0B = +0.183992
```

Two `EFF_Link` patches, then one register write per unit, in bit-7 order, and nothing after.
Both registers were cleared to 0 at the very start of the same boot (transfer 4, the only
other time they are touched). **Mute at reset, then set the two effect levels once each unit
is linked** — and this independently re-confirms K5's `setvec` decode from the *live* stream
(K5 proved it from the Sub CPU ROM; here the chip actually receives `A = 84` and `A = 200`).

Values: unit 0 `+0.5` exactly, unit 1 `+0.183992`. Two different, independently-computed
scalars — consistent with per-unit wet levels and **inconsistent** with an L/R pair of one
port, which would normally be equal.

This is what `dsp-audiopath-wiring.md` §2.4 was reaching for when it guessed *"I-RAM 64 and
71 are the wet-level words for DO1 and DO2"*. That guess was **falsified** by K5 (64/71 are
call vectors). The wet-level mechanism is real, but it lives **one layer down**, in registers
`0x06`/`0x86`, and it is not an I-RAM word at all.

---

## 3. THE DO WRITE — `w73` and `w78` (**MEASURED + INFERRED (strong)**)

### 3.1 The measurement that isolates them

`hi12` bit 4 is the store/output enable. Across the whole 3057-word corpus:

```
   ESC words          370   with bit 4:  3    -> epi w73, epi w77, epi w78     (and nothing else)
   C-format words      68   with bit 4:  1    -> epi w74                        (and nothing else)
```

**Four words in the entire machine carry `hi12` bit 4 outside the ordinary D-RAM/register
modes, and all four are consecutive-ish in the output stage.** They bracket the wait word:

```
  w72  000.1.06.087   mode 1, no ESC, no bit4   READ reg 0x06  = UNIT-0 LEVEL
  w73  E30.C.00.404   ESC, mode 4, cursor+, BIT 4     <-- the machine's only mode-4 escape word
  w74  C16.9.AB.000   C-format, BIT 4, A = 77, B = 11 <-- the only C-format word with bit 4
  w75  82E.8.0F.000   ESC, mode 0, cursor+, addr8 = 0x0F = the UNIT-1 TAG
  w76  C00.9.84.000   C-format WAIT/SYNC, A = 76 (its own address), event B = 4
  w77  859.0.86.822   ESC, mode 0, BIT 4, addr8 = 0x86 = UNIT-1 LEVEL -> pointer register 0x822
  w78  A3C.D.9F.287   ESC, mode 5, cursor+, BIT 4     <-- the machine's only mode-5+cursor word
```

Three further facts lock the reading in:

* **`w74`'s C-format immediate is `A = 77`, and I-RAM 77 is `w77`** — the unit-1 level word.
  The unit-0 group explicitly names the start of the unit-1 group.
* **`w75` carries `addr8 = 0x0F`, the unit-1 tag**, and sits exactly on the boundary.
* **Both `w73` and `w78` fetch a coefficient** (`class4` bit 3), which is what an output-level
  multiply needs; `w67`, the only other mode-5 word in the machine, does not fetch and does
  not store.

⇒ **`w72/w73(/w74)` present the UNIT-0 result and `w77/w78` present the UNIT-1 result.**
Board (MEASURED, `dsp-audiopath-wiring.md` §2): `DO1 → IC303.SDIA`, `DO2 → IC303.SDIB`,
one return per effect unit. So **`w73` drives DO1 and `w78` drives DO2**.

### 3.2 Two outputs, not three — the count the brief asked for

Full bit-4 inventory of the output stage **in the linked configuration** (I-RAM 64/71
overwritten by `setvec`, which clears their bit 4):

| word | what it is | status |
|---|---|---|
| `w60` `092.1.8D.15B` | mode-1 register write, reg `0x8D` (unit 1) | internal |
| `w61` `012.1.8D.05B` | mode-1 register write, reg `0x8D` (unit 1) | internal |
| `w68` `092.1.8C.19B` | mode-1 register write, reg `0x8C` — **read at `w66` first** ⇒ a state register | internal |
| **`w73`** | **unit-0 output presentation** | **DO1** |
| **`w74`** | unit-0 companion (C-format, points at `w77`) | **DO1** |
| **`w77`** | unit-1 level + bit 4 | **DO2** |
| **`w78`** | **unit-1 output presentation** | **DO2** |
| `w79` `012.2.FF.1CE` | the FORCED one-frame D-RAM feedback store at `X+1` (K6 §5) | internal |

**Two groups, two units, two ports. `DO3` is never written.** That answers the brief's
question and it explains why DO3's destination has never been identifiable from the
microcode: it is a *wired-but-undriven* pin. **Falsifiable hardware prediction: with a scope
on IC311 pin 25, DO3 carries no audio in any effect configuration.**

### 3.3 Honest limits

* The **L/R split within a port is not settled.** Each DO is a pair of latches
  (`DO1L-R`/`DO1R-R` on the CDJ block diagram, MEASURED). Two readings, both consistent with
  §3.1, are enumerated:
  * **(D-1)** each group is a stereo pair — `w73` = DO1 L, `w74` = DO1 R; `w77` = DO2 L,
    `w78` = DO2 R. Explains why exactly two words per group carry bit 4.
  * **(D-2)** `w73` and `w78` are the presentations (one 24-bit write each, the hardware
    demultiplexing on LRCKI), and `w74`/`w77` are their level/scale companions. Favoured by
    `w77` being unambiguously a *level* word (it aims a pointer at reg `0x86`), and by `w74`
    pointing at `w77` — a cross-link between the two companions, not between the two ports.
  Nothing in the corpus separates them.
* `addr8` on `w73` (`0x00`) and `w78` (`0x9F`) is a **sub-op or port selector**, not a memory
  address (§1: these are escape words). Which value means which port is **OPEN**; the unit
  assignment above comes from the *neighbouring level registers*, not from `addr8`.
* Registers `0x8C`/`0x8D` (`w60`, `w61`, `w68`) are unit-1-tagged and are **not** the audio
  return: `0x8C` is read before it is written, and `0x8D` is written before either output
  presentation and is never read. Their role is **OPEN**.

---

## 4. R2 — where a unit result actually goes

### 4.1 It never passes through D-RAM (**FORCED**)

The output stage has exactly **three** mode-2 words in its 23: `w79`, `w80`, `w81`, at
I-RAM positions 19, 20, 21. Both output presentations are at positions 13 and 18.

⇒ **the output stage performs zero D-RAM reads before either presentation.** It cannot fetch
a unit result out of D-RAM, because it does not read D-RAM until after it has already
presented both. And K6 §5 FORCED what those three words are: `w79` stores `X+1`, `w80`/`w81`
read `X+0` — the dry/one-frame-feedback loop, origin-free. There is no spare D-RAM access.

### 4.2 It cannot be in the accumulator either (**FORCED**)

Unit 0's body returns at header `w49`. Its result is presented at epilogue `w73`. Between
them the machine executes

```
   header w50..w59 (10 words)  +  the whole unit-1 body (133 for ROOM REVERB)  +  epilogue w60..w72 (13)
   = 156 words                                   ... and 31 words even with unit 1 disconnected
```

all of which use the accumulator (they include mode-2/A multiply-accumulates). **A single
accumulator cannot carry unit 0's result across that.**

### 4.3 ⇒ There is a per-unit RESULT REGISTER, loaded at the terminator (**FORCED / INFERRED**)

Combining 4.1 and 4.2: **the per-unit result is held in dedicated chip state between the
body's return and the output stage.** The only word every body executes at exactly the moment
its result must be captured is its **terminator**, and the terminator names a **per-unit
index** in `addr8` (`0x0E` unit 0, `0x0F` unit 1, 40/40). Nothing else in the frame is
positioned to do it — header `w50..w52`, which run immediately after unit 0 returns, are
three pointer loads.

⇒ **the terminator is the result deposit, for all 38 bodies** — and therefore the deposit is
part of the terminator's *ordinary* action, not of its optional bit-4 store.

### 4.4 The terminator's bit-4 store is NOT the routing mechanism (**MEASURED**)

Only **5 of 38** bodies set bit 4 on their terminator:

```
  612.1.0E.000  x4   GATED REVERB, SINGLE DELAY, MULTI TAP DELAY, PEQ+S.DELAY   (unit 0)
  612.1.0F.000  x1   ROOM REVERB                                                (unit 1)
```

The other 33 deliver a result without it, so bit 4 cannot be how a result is routed. It is
also a **clean minimal pair**: `602.1.0E.000` (×3: CHORUS, MODULATED CHORUS, ROCK ROTARY)
differs from `612.1.0E.000` in exactly bit 4, same `addr8`, same `lo12`.

What the store *is* remains **ENUMERATED, not settled**:

* **(T-1) it writes the register space** (uniform with every other mode-1 bit-4 word).
  Supported by K5's DETERMINED result on `w64`/`w71` — class-9 (mode 1) bit-4 words whose
  destination is the call-vector register, *not* `mem[ptr]` — and by `w60`/`w61`, which are
  adjacent mode-1 stores with **no pointer-moving word between them**: under a `mem[ptr]`
  target the first would be provably dead. Coherent for all 5 bodies.
* **(T-2) it falls back to `mem[ptr]`** (the mode-2 default). Then in 4 of the 5 bodies it is
  a tidy read-modify-write: their last mode-2 word is `000.2.00.40E` (a read at `entry−5`
  with `addr8 = 0`, so the pointer stays), and the store lands on the cell just read. But in
  the fifth — ROOM REVERB — the target is `entry+123`, which **nothing in the reverb ever
  reads**. (T-2) is coherent 4/5, (T-1) 5/5.

Either way §4.1-4.3 stand: the store is not how the result travels.

### 4.5 Reconciliation with K6 — the unit-1 ambiguity CLOSES

K6 §6 left three unresolved resolutions for a "2-cell discrepancy": `w53` stores the unit-1
send, but `w55`/`w57` each advance the pointer by +1 before the CALL, so the reverb's entry
would be `w53`'s cell + 2.

**The premise is false.** `w45` (unit 0) is class **A** — mode 2, a genuine `mem[ptr]` store,
so K6's unit-0 result is untouched. `w53` (unit 1) is class **9** — *mode 1*, the register
space, which does not address `mem[ptr]` at all. That is not a hypothesis: K5 **DETERMINED**
that `w64` and `w71`, which are also class-9 bit-4 words, write the **call-vector register**,
and it proved this from the host's C-format replacement, whose *only* shared field with the
canned form is `lo12`. A class-9 bit-4 word demonstrably writes a register.

⇒ **K6 resolution 1 (`w55`/`w57` do not move the pointer) is ELIMINATED** — they are
ordinary mode-2 pointer movers and always were. **Resolution 2 is CONFIRMED**: `w53` is not a
D-RAM store. There is no discrepancy left to resolve; the reverb's entry pointer is simply
`w50`'s value + 2, and the unit-1 send never went through that cell.

And the register `w53` names has a name: **`0xD0`, the unit-1 half of the host-cleared
bit-7 pair `{0x50, 0xD0}`** (§1.2, §1.3). `w45`'s `lo12 = 0x20C` and `w53`'s `lo12 = 0x20C`
are identical, so under the standing "`lo12` names the destination" rule the two words write
the *same* destination from *different* sources — unit 0 from `mem[ptr]`, unit 1 from
register `0xD0`. That is the symmetry K6 was looking for; it is INFERRED, and `lo12`'s
identity belongs to the concurrent ALU pass.

### 4.6 By-product: what the CALL/RETURN mechanism must be

`setvec` writes I-RAM 64/71, which execute **after both CALLs**, every frame. Two readings:

* **(C-1) EXCHANGE.** `4xx.1.0E.yyy` does `swap(PC, LINK[unit])`. Header `w49`: PC→84,
  LINK0→50; the body's terminator swaps back: PC→50, LINK0→(body end). The vector is
  *destroyed by use*, so the kernel must reload it once per frame — which is exactly what
  I-RAM 64/71 do and exactly where they sit. It also makes the DISCONNECT targets **42/50**
  necessary rather than arbitrary: with LINK0 = 42, `w49` jumps to 42, re-runs the (idempotent)
  setup block, and `w49`'s second execution swaps PC→50 and falls through. **A self-returning
  null body.** Both cases work out exactly.
* **(C-2) a plain vector register** that the calls do not disturb; then the two reload words
  are redundant-but-harmless and their placement after both calls is a coincidence.

(C-1) explains three otherwise unexplained facts and costs nothing. **INFERRED (strong)**;
(C-2) is not excluded. Independent support for the "2-level stack" in
`kn5000-dsp-headerdecode.md` being **two independent per-unit link registers**, not a stack.

---

## 5. FALSIFICATIONS and corrections

| earlier claim | where | status |
|---|---|---|
| "class-1 `addr8` splits on bit 7 — DRAM sub-ops `0x20/0x30/0x60` versus the epilogue `0x85/0x8A/0x8C/0x8D/0x8F`" | K6 §10 item 7 (offered as a lead) | **FALSIFIED.** `0x06/0x0E/0x0F` are `< 0x80` and are not sub-ops. Replaced by `hi12` bit 11, 324/324 |
| "`w53` stores at the pointer … the reverb's entry pointer is `w53`'s cell + 2 … three resolutions" | K6 §6, §10 item 4 | **premise FALSIFIED, item CLOSED.** `w53` is mode 1 (register), so it never stored to `mem[ptr]`; resolution 1 is eliminated and the discrepancy dissolves (§4.5) |
| "`X+3` is written and never read ⇒ a hardware register (a DO/side-chain latch) or a dead store" | K6 §0 item 10 / §10 item 3 | **the rarity argument does not hold.** 21 of 38 bodies contain at least one write-never-read D-RAM cell (32 cells). Write-only is common; it is not evidence of a latch |
| "I-RAM 64 and 71 are the wet-level / output-stage words for DO1 and DO2" | `dsp-audiopath-wiring.md` §2.4 | already falsified by K5 (they are call vectors). **The wet levels are real but are registers `0x06`/`0x86`**, not I-RAM words (§2) |
| "the terminator store `612.1.0F.000` — where does the unit result get deposited?" | the R2 brief's framing | **the framing presupposes a memory deposit; there is none.** The output stage never reads D-RAM before presenting either result (§4.1), and 33 of 38 bodies have no terminator store at all (§4.4) |
| "`!! bit 4 = store, yet addr8 is the unit index — UNEXPLAINED`" | `tools/gen_dsp_disasm.py`, emitted on 5 listings | **resolved as a non-conflict:** the terminator is a mode-1 word, so bit 4's target is not `mem[ptr]`, and `addr8` is free to be the unit tag. The annotation should say so |

Two numbers in earlier notes are also corrected here: `k5-output-stage.md` and the
disassembler treat `class4` as meaningful on `C0A`/`C16`/`C64` words — it is immediate data,
so **there are no class-3 or class-B words in the machine** (all 31 apparent ones are
C-format). And the MEASURED live frame length **286 slots** is reproduced exactly by
`60 + 70 (CHORUS) + 133 (ROOM REVERB) + 23 = 286`, confirming that both units were linked in
that capture and that the disconnect path costs 8/10 extra slots when taken.

---

## 6. The result-routing model, stated for an implementer

```
   per frame:
     I-RAM  0..11   input stage        two samples enter at D-RAM X+2, X+5        [K6, FORCED]
     I-RAM 12..41   mix block          leaves the send in the accumulator          [K6]
     I-RAM 42..48   unit-0 setup       w45 (mode 2, bit 4) stores the send at mem[ptr]
                                       = the unit-0 body's entry cell              [K6, FORCED]
     I-RAM    49    CALL unit 0        swap(PC, LINK0);  LINK0 was set by I-RAM 64
     I-RAM    84..  unit-0 body        first access is entry+0 in 38/38 images     [K6]
                    terminator         returns AND deposits the result in the
                                       per-unit result register (addr8 = 0x0E)     [FORCED that
                                       a per-unit register exists; the field is enumerated]
     I-RAM 50..58   unit-1 setup       w53 (mode 1, bit 4) writes register 0xD0    [FORCED: not D-RAM]
     I-RAM    59    CALL unit 1
     I-RAM   200..  unit-1 body        terminator, addr8 = 0x0F
     I-RAM 60..72   output stage, part 1
                                       register traffic on the unit-1 bank (0x8C/0x8D/0x8F);
                                       I-RAM 64 / 71 reload the two call vectors   [K5 DETERMINED]
     I-RAM    72    read reg 0x06      = unit-0 output LEVEL                        [PROVEN]
     I-RAM 73,74    PRESENT unit 0  -> DO1 -> IC303.SDIA
     I-RAM    76    WAIT (event 4)
     I-RAM    77    reg 0x86           = unit-1 output LEVEL                        [PROVEN]
     I-RAM    78    PRESENT unit 1  -> DO2 -> IC303.SDIB
     I-RAM 79..81   the one-frame dry/feedback D-RAM loop at X+0 / X+1              [K6, FORCED]
     I-RAM    82    WAIT (event 7)     = end of frame
                    DO3 is never written.
```

**What a core must do that it does not do today:** treat `class4 & 7` as an addressing mode
(mode 1 non-escape = register file indexed by `addr8`, mode 1 escape = delay DRAM), and stop
routing `hi12` bit 4 to `mem[ptr]` outside mode 2. Today's model produces four provably dead
stores in the 23-word output stage; the corrected one produces none.

---

## 7. Still OPEN

1. **Which physical DO latch each of `w73`/`w74`/`w77`/`w78` drives** (the L/R split, §3.3).
   Needs the register-to-latch map: a datasheet, or a scope on DO1/DO2.
2. **The `addr8` sub-op values `0x00` (w73) and `0x9F` (w78)** — a port/sub-op selector whose
   encoding is unknown. Note `w67`'s `0x20` is the same value the delay-DRAM **write** uses.
3. **Registers `0x8C`, `0x8D`, `0x8F`** — the three the host never touches. `0x8D` is written
   twice and never read; `0x8C` is read then written; `0x8F` is read only.
4. **Which field of the terminator carries the result deposit** — `addr8` (the unit tag),
   `lo12` (0x000 in 36/38, 0x407 in 2), or an implicit per-unit register. §4.3/§4.4.
5. **The per-unit C-RAM cursor base.** §0 item 13 proves the microcode cannot load it. Two
   candidates: (i) the host's `801.0.NN.821` C-RAM write pointer is latched per unit at
   algorithm-change time; (ii) the CALL loads it from a per-unit register. Deciding this is
   a pure static read of the `EFF_*` routines and the `op 0..5` uC-IF handlers.
6. **CALL/RETURN: exchange vs plain vector** (§4.6, C-1 vs C-2).
7. The 36-register host block at `0x1D..0x40` — real Q0.23 coefficients written in 9 groups
   of 4. What consumes them is unknown; **no in-program word addresses that range**.

---

## 8. Reproduction

```
# corpus:  original_ROMs/kn5000_subprogram_v142.rom   (file offset = cpu addr - 0xEF00)
#          header   0x01E496 -> I-RAM 0..59  |  output stage 0x01E63C -> I-RAM 60..82
#          bodies   ALGO_TABLE 0x0001ED7C, 100 x u32; 38 canonical images (79/88/89/90/91 malformed)
#          host     notes/data/kn5000_dsp1_upload_coldboot.txt

# fields:  hi12 = w>>24 & 0xFFF ; class4 = w>>20 & 0xF ; addr8 = w>>12 & 0xFF ; lo12 = w & 0xFFF
#          C-format iff (hi12 & 0xF00) == 0xC00      -> class4/addr8 are immediate data
#          ESC   = hi12 & 0x800 ; STORE = hi12 & 0x10 ; END = (hi12 & 0xC00) == 0x400
#          mode  = class4 & 7   ; cursor fetch = class4 & 8

# §1   classify every non-C-format word by (mode, cursor, ESC)  -> mode 2 never escapes, 0/2399
# §1.1 class-1 words by ESC                                     -> {20,30,60} vs {06,0E,0F,85,8A,8C,8D,8F}
# §1.2 decode host `01 60` windows: 5-byte packets; `0A aa bb cc dd` = value+tag,
#      anything else = a DSP word. Collect every 000.1.NN.000 and the run length after it.
# §2   transfers 50..53 are the last four of the capture, in that order.
# §3.1 count hi12 bit 4 among ESC words (3) and among C-format words (1).
# §4.1 positions of the epilogue's mode-2 words: 19, 20, 21 (of 23); presentations at 13, 18.
# §4.4 last word of each of the 38 body images; minimal pair 602 vs 612.
# §5   per-body mode-2-only walk from entry offset 0 -> write-never-read cells: 21/38 bodies, 32 cells.
```
