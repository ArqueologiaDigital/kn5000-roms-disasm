# PREDICT — S-1, the `xxx.2.00.000` `hi12` bench: everything that must be true BEFORE the run

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Date **2026-07-31**.
**Static pass only** — nothing was built, nothing was run, no MAME source was written, no
commit. Read-only over `kn5000-roms-disasm` + `kn7000_mame` + the four `.log.gz` files
already on disk (decompressed to scratch, never in place).

Grades used throughout: **MEASURED** (a number this pass computed) · **FORCED** (follows by
construction from something measured) · **INFERRED** · **SPECULATIVE**.

---

## 0. HEADLINE — the vehicle is fine; the experiment is not

Three separate results, in the order the next lane-holder needs them:

1. **`a70 AUTO WAH+S.DELAY` IS reachable.** Its TYPE index is **28**, confirmed by three
   independent routes including a direct measurement of the machine's own upload stream.
   The `TYPELAST=36` instruction is right, and setting `TYPEIDX=28 TYPELAST=36` makes the
   asked-for index equal the real index. **MEASURED.** Item 2 does **not** kill the run.
2. **The word list is wrong in the source note.** `a70` carries **20** `xxx.2.00.000` sites,
   not nine; nine is the count of *distinct forms*. And the "17 forms / 354 words"
   population **pools the KERNEL and the EPILOGUE**, which `CORPUS-PATTERNS-SPECULATIVE.md`
   §0.1 forbids. Body-only it is **16 forms / 352 words**. **MEASURED.** (The pooling is
   *good* news — see §1.3.)
3. **⛔ THE EXPERIMENT IS NOT VIABLE AS DESIGNED, and two independent reasons kill it.**
   * **(a) The emulator's answer is already known without running it.** A bench word's
     entire effect in the shipped build is one closed-form expression (§3.1), so the nine
     forms collapse into **five** behaviour classes *by construction*. Seven of the 36
     pairwise comparisons are **FORCED IDENTICAL** before a single frame executes. A run
     cannot tell us anything about the *chip*; it can only re-read our own dispatch table.
   * **(b) The null is DEGENERATE and it is already measured.** In the logs on disk, **36
     of the 37** class-2/`lo12 0x000` words executed in the traced frame sit at
     `L = 0, P = 0, acc = 0`, where **every one of the 17 forms is the identity**. The
     `§104` table says the same over **1 020 000 frames**: CHORUS's three bench sites read
     `acc 0..0 / mem 0..0 / L 0..0 =` in both buckets. **MEASURED.**
   * ★ And the two *decoded* bits that were going to serve as known-answer controls —
     bit 4 (STORE) and bit 7 (store gate) — produce **no accumulator difference at all**
     in the shipped build (the store-and-clear is off under mask bit 16), only a D-RAM
     write that the trace **does not print**. So the run's calibration would score
     **0 of 2**: the exact failure mode §107 hit and §193 paid for. **FORCED**, §3.3.

**⚠ AND THIS IS NOT AN AUDIO TEST.** §216 guarantees the output stage is a null independent
of anything upstream. Nothing in this note may be graded on `w73`/`w78`, on §70/§211, or on
any waveform. Register and counter deltas only. **RULE 19**: if any level number is ever
quoted from this line of work, MEAN and AC AMPLITUDE go in separate columns.

What to do instead is §7.

---

## 1. ITEM 1 — THE EXACT WORD LIST

Computed with `dsp/tools/pat_corpus.py` (the shared loader; no rival loader was written).
**RULE 18** honoured: `SRC = lo12[10:6]`, `ACT = lo12[4:0]`, taken from the loader's own
`F.src` / `F.act`. **Dead end 16** honoured: every word here is PLAIN — `lo12 = 0x000`, so
bit 11 is clear and no `ACT 0x03/0x04/0x1C` or `SRC 0x02/0x04` artefact can arise.

### 1.1 Population and denominator — restated correctly

| set | forms | words | note |
|---|--:|--:|---|
| S-1's stated population | 17 | 354 | ⛔ **pools KERNEL + EPILOGUE** |
| **38 body images only** | **16** | **352** | the population §0.1 of the source note mandates |
| KERNEL contribution | +1 | +1 | `282.2.00.000` at **KERNEL w13** — the 17th form, and it exists **nowhere in any body** |
| EPILOGUE contribution | 0 | +1 | `102.2.00.000` at **EPILOGUE w21** (`102` also has 34 body words in 19 images) |

**MEASURED.** Denominator for the family: `class4 = 2 ∧ addr8 = 0x00 ∧ lo12 = 0x000` holds
`class4`, all eight `addr8` bits and all twelve `lo12` bits fixed — there is genuinely no
confound to control for. That part of S-1 stands.

### 1.2 `a70 AUTO WAH+S.DELAY` — all 20 sites

`a70` = corpus algorithm **70**, one algorithm slot, family `combi`, **unit 0**, **105 words**,
loaded at **I-RAM 84..188**. Body word `wN` ⇒ I-RAM slot `84+N`.

| body | I-RAM | 36-bit word | `hi12` | `f98` | `f31` | b4 | **b5** | b7 |
|---|--:|---|---|--:|--:|--:|--:|--:|
| w4   | 88  | `002A200000` | `02A` | 0 | 5 | 0 | 1 | 0 |
| w5   | 89  | `0022200000` | `022` | 0 | 1 | 0 | 1 | 0 |
| w21  | 105 | `0204200000` | `204` | 2 | 2 | 0 | 0 | 0 |
| w35  | 119 | `0212200000` | `212` | 2 | 1 | **1** | 0 | 0 |
| w36  | 120 | `0020200000` | `020` | 0 | 0 | 0 | **1** | 0 |
| w40  | 124 | `0202200000` | `202` | 2 | 1 | 0 | 0 | 0 |
| w41  | 125 | `002A200000` | `02A` | 0 | 5 | 0 | 1 | 0 |
| w42  | 126 | `0026200000` | `026` | 0 | 3 | 0 | 1 | 0 |
| w50  | 134 | `0212200000` | `212` | 2 | 1 | **1** | 0 | 0 |
| w54  | 138 | `0212200000` | `212` | 2 | 1 | **1** | 0 | 0 |
| w55  | 139 | `002A200000` | `02A` | 0 | 5 | 0 | 1 | 0 |
| w57  | 141 | `0212200000` | `212` | 2 | 1 | **1** | 0 | 0 |
| w59  | 143 | `0212200000` | `212` | 2 | 1 | **1** | 0 | 0 |
| w62  | 146 | `0202200000` | `202` | 2 | 1 | 0 | 0 | 0 |
| w65  | 149 | `0292200000` | `292` | 2 | 1 | **1** | 0 | **1** |
| w71  | 155 | `002A200000` | `02A` | 0 | 5 | 0 | 1 | 0 |
| w72  | 156 | `0022200000` | `022` | 0 | 1 | 0 | 1 | 0 |
| w88  | 172 | `0204200000` | `204` | 2 | 2 | 0 | 0 | 0 |
| w94  | 178 | `0000200000` | `000` | 0 | 0 | 0 | 0 | 0 |
| w102 | 186 | `0212200000` | `212` | 2 | 1 | **1** | 0 | 0 |

**20 sites, 9 distinct forms** (`000 020 022 026 02A 202 204 212 292`), multiplicities
`212`×6, `02A`×4, `022`×2, `202`×2, `204`×2, `000`/`020`/`026`/`292`×1. **MEASURED.**

### 1.3 Which bits differ from which sibling — the one-bit pairs **inside** `a70`

Exhaustive over the 36 unordered pairs; these six are Hamming-1 in `hi12` and identical in
all 24 other bits:

```
   000 ^ 020 = 020   bit 5   ← the §2.3(2) pair, w94 vs w36            [NO READING]
   020 ^ 022 = 002   bit 1   f31 lsb                                    w36 vs w5/w72
   022 ^ 026 = 004   bit 2   f31 bit 1                                  w5/w72 vs w42
   022 ^ 02A = 008   bit 3   f31 msb                                    w5/w72 vs w4/w41/w55/w71
   202 ^ 212 = 010   bit 4   STORE          [DECODED — control]         w40/w62 vs six sites
   212 ^ 292 = 080   bit 7   store gate     [DECODED — control]         six sites vs w65
```

★ **New, and it matters for design:** the KERNEL's `282` and the EPILOGUE's `102` are
resident in **every** run of **every** program. So a run of `a70` actually exercises
**11 of the 17 forms**, not nine — and `282 ^ 202 = 0x080` is a **bit-7 pair that is
co-resident in every run of the 11 body images carrying `202`**, a co-residency §2.3's
table cannot see because it excluded the kernel. **MEASURED.** (It is still confounded by
state — different slots, different `acc`/`L` — so it is a corpus fact, not an experiment.)

---

## 2. ★★ ITEM 2 — CAN THE VEHICLE LOAD `a70`? **YES. TYPE 28.**

### 2.1 The off-by-one is now located exactly, and `TYPE_MAP.md`'s stated reason is wrong

`data/typewalk/kn5000_dsp1_upload.txt` is the walk's own upload capture and it settles this
with no run. Parsing every `cmd 0x01` transfer whose start address is **84** (the unit-0
body region) and matching each payload against the corpus:

```
   37 body uploads, in walk order:
    0 a01 CHORUS          9 a32 DISTORTION      18 a52 AUTO WAH        27 a68 S.DELAY+PHASER
    1 a02 MOD CHORUS     10 a33 OVERDRIVE       19 a15 ROCK ROTARY  ◄  28 a70 AUTO WAH+S.DELAY ◄◄
    2 a03 ENHANCER       11 a34 FUZZ            20 a15 ROCK ROTARY  ◄  29 a71 PEQ+CHORUS
    3 a04 FLANGER        12 a35 EXCITER         21 a54 RING MOD        30 a72 PEQ+S.DELAY
    4 a05 PHASER         13 a36 COMPRESSOR      22 a56 MIX UP          31 a73 PEQ+FLANGER
    5 a06 ENSEMBLE       14 a00 NO OPERATION    23 a64 S.DELAY+CHORUS  32 a74 PEQ+VIBRATO
    6 a08 GATED REVERB   15 a39 PARAMETRIC EQ   24 a65 S.DELAY+S.DELAY 33 a75 PEQ+COMPRESSOR
    7 a09 SINGLE DELAY   16 a48 AUTO PAN        25 a66 S.DELAY+FLANGER 34 a96 PEQ+COMPR+DIST
    8 a10 MULTI TAP DLY  17 a50 VIBRATO         26 a67 S.DELAY+VIBRATO 35 a97 PEQ+COMPR+OVERDR
                                                                       36 a99 PEQ+OVERDR+DELAY
```

**MEASURED.** The duplicate is at **19/20**, and it is `a15 ROCK ROTARY`, which
`pat_corpus` independently reports as `algos = [15, 53]` — **two algorithm slots with a
byte-identical image**, exactly the mechanism `TYPE_MAP.md` describes. So:

* real TYPE = map index for map ≤ 19; **real TYPE = map index + 1 for map ≥ 20.** **FORCED.**
* ⚠ `TYPE_MAP.md`'s "**add 1 to any index above 8**" **over-corrects map rows 9..19.**
  Those eleven rows are correct as they stand. For `a70` the two rules happen to agree
  (map 27 → 28), so no action is needed for this run — but the note's rule should not be
  applied to `a32`..`a15` without this correction. **MEASURED, recorded here, not edited
  into the owner's file.**
* Two **known-answer controls pass on this reconstruction**: upload 8 = `a10 MULTI TAP
  DELAY` (§193 verified `TYPEIDX 8` live as `prog10_multi_tap_delay`) and upload 15 =
  `a39 PARAMETRIC EQ` (`peq_select.lua` measured 15). **2 of 2.**
* The list has **37 entries, 0..36** ⇒ **`TYPELAST=36` is correct.** Corroborated by the
  walk itself: `type_enum.lua` issued 40 UP presses and produced 36 changes, so four
  presses hit the top rail. And the host does **not** suppress a redundant upload — it
  re-uploaded `a15` for slot 20 — so no stop can have been silently missed. **FORCED.**
* ⚠ `type_enum.lua`'s display readout is **garbage** (`/tmp/.../runs164/typeenum/out.log`:
  `type=0x0B` at every stop, titles unreadable). The map was therefore built from the
  upload stream, which is why it deduplicated. Do not cite the display log.

### 2.2 The transport, and the exact command

`type_select.lua` saturates **UP** to the true top (real 36) and then steps **DOWN**
`(LAST − TYPEIDX)` times. With `TYPELAST=36`:

```
   landing = 36 − (36 − TYPEIDX) = TYPEIDX
```

⇒ **`TYPEIDX=28 TYPELAST=36`** lands on real 28 = `a70`, in **8** DOWN presses at 0.20 s —
inside the regime §193 verified (8 steps) and far from the 28–30-step regime that dropped
steps and voided a run. **FORCED** (arithmetic) + **MEASURED** (§193's verified distance).

**Confidence: HIGH.** Three independent routes agree on 28 (upload-stream position;
`TYPE_MAP` row 27 + 1; and the corpus's `a15` double-slot explaining the collapse), and two
known-answer controls pass. The residual risk is not the index — it is a dropped press,
which is what §2.3 exists for.

### 2.3 ★ The in-run fingerprint — and its **named wrong numbers**

Standing requirement (§193): fingerprint the loaded program from `kn5000_dsp1_upload.txt`
**in the same run**, and copy that file into the run directory **before the next launch
overwrites it**. The three candidates are trivially separable because their lengths differ:

| landing | program | words | the capture line to look for |
|---|---|--:|---|
| **27** (one low) | `a68 S.DELAY+PHASER` | 110 | `cmd 0x01  552 bytes  I-RAM[84..193]` |
| **28** (target) | **`a70 AUTO WAH+S.DELAY`** | **105** | **`cmd 0x01  527 bytes  I-RAM[84..188]`** |
| **29** (one high) | `a71 PEQ+CHORUS` | 93 | `cmd 0x01  467 bytes  I-RAM[84..176]` |

⚠ **A 2-word prefix is NOT enough** — all three begin `880.1.30.8BC | 000.2.0D/03.1CD`
(S-11's shared entry word). The discriminating word is index **2**:

```
   a68  000.2.00.40E        a70  000.2.4F.40E        a71  000.2.81.40E
   a70's first 4 words:  08801308BC 000020D1CD 000024F40E 02122B100B
```

**PASS** = the last `I-RAM[84..*]` transfer before the note window reads **527 bytes /
`I-RAM[84..188]`** and its third word is `000024F40E`.
**FAIL, named:** `552 bytes / I-RAM[84..193]` (⇒ landed 27, `a68`) or `467 bytes /
I-RAM[84..176]` (⇒ landed 29, `a71`). Either ⇒ **the run is VOID**; do not "adjust" the
index to fit.

---

## 3. ITEM 3 — THE NULL, computed from logs already on disk

Sources: `data/drpub_{A_off,B_on,C_on_src0b2}_217.log.gz`,
`data/src0b2_{A_off,B_on}_215.log.gz`, decompressed to scratch. All five carry the
cold-boot vehicle, identified from the trace: **body(iw84..199) = `a01 CHORUS`, exact
70-word prefix match**.

⚠ **THE TRACE'S COLUMN HEADER IS STALE.** It advertises
`n iw word dp mem[dp] acc P tA tB cur coef MUL L`; the `printf` at `upd6383.cpp:822-826`
emits **`n iw u1 word dp acc accb p cur coef MUL L`**. `t.mem`, `t.ta`, `t.tb` are
*recorded* (`upd6383.cpp:4636-4643`) and then **dropped by the format string**. Verified by
reading both lines, not by eye on the log. **MEASURED.**

### 3.1 What a bench word does in the CURRENT build — the closed form

Traced through `exec_decoded()` → `exec_alu()` with the shipped default mask
**`0xB910E446A39B440F`** (bit 0 = 1 ⇒ `op = f31 & 3`; bit 16 = 1 ⇒ **the store-and-clear is
SUPPRESSED**; bit 29 = 1 ⇒ the store gate is `b7 ∧ f31 ≠ 2`; bits 57/58 = 0, bit 59 = 1 ⇒
`SRC 0x00` takes `coef` only on a coefficient consumer, and **class 2 is not one**):

```
   SRC 0x00  →  L   = mem[m_dp]                       (uniform over all 17 forms)
   ACT 0x00  →  bus term contributes  (L << 16)
   f31       →  op = f31 & 3 :  0 LOAD, 1 ADD, 2/3 no-product
   b4 ∧ ¬(b7 ∧ f31≠2) → mem[m_dp] ← acc_to_datum(acc)   BEFORE the accumulator update
   class 2   →  m_dp += (s8)addr8  =  +0   (addr8 is 0x00 — no pointer move)

   acc  ←  (op==0 ? 0 : acc)  +  (L << 16)  +  (op∈{2,3} ? 0 : P)
```

`P` is **not** recomputed (mask bit 4 clear ⇒ no multiply on a non-coefficient word; every
trace row at these slots shows `MUL = '.'`). **FORCED** from the source.

⇒ `a70`'s nine forms collapse into **five** classes, and the collapse is by construction,
not by measurement:

| class | forms | behaviour |
|---|---|---|
| **N** | `000` | ⛔ **never reaches `exec_alu`** — see §3.2 |
| **LOAD** | `020` | `acc ← 0 + (L<<16) + P` |
| **ADD** | `022`, `202`, `292`, **`02A`** | `acc ← acc + (L<<16) + P` |
| **ADD-no-P** | `026`, `204` | `acc ← acc + (L<<16)` |
| **STORE+ADD** | `212` | `mem[dp] ← acc_to_datum(acc)`, then ADD |

**Seven of the 36 pairwise comparisons are FORCED IDENTICAL** (six inside the ADD class, one
inside ADD-no-P). Notably the bit-3 pair `022 ↔ 02A` — one of the six one-bit pairs — is
**bit-identical in machine state**; the only thing that separates them is the existing
counter `m_bx_f5_n`.

### 3.2 ★★★ The `000` result is PRE-DETERMINED — and it is an emulator artefact

`exec_decoded()` (`upd6383.cpp:4059-4062`) carries an **exact-match** guard:

```c
else if (hi12(word) == 0x000 && class4(word) == 2 && lo12(word) == 0x000)
        // nop -- INFERRED
        if (ptr_postinc(word) && !ptrd_a_suppressed(word)) m_dp += (s8)addr8;
```

`hi12 == 0x000` is an **equality on all twelve bits**. So `000.2.00.000` is intercepted as a
nop while its one-bit sibling `020.2.00.000` falls through to the full ALU. **A run of `a70`
would therefore observe a bit-5 difference, and 100 % of it would be this guard.** The
§2.3(2) question ("does bit 5 do anything?") is *unanswerable* on this vehicle: our model is
not the chip, and here the model reads bit 5 in exactly one place, for a reason that is an
implementation shortcut rather than a decode. **FORCED.**

★ **And the guard is a real, free, static finding in its own right.** Corpus-wide it catches
**103 words in 28 of 40 streams** — 62 with `addr8 = 0` (which then do *literally nothing*)
and **41 carrying a non-zero pointer move** — while **350** sibling words of the same
`class 2 / lo12 = 0x000` family go to `exec_alu`. Among the intercepted 103 is
**`000.2.48.000`**, which `upd6383.cpp`'s own acc-adder comment (`:3040`) cites as
*"SD `000.2.48.000` … both have to produce `bus + P`"* — **a behaviour the code cannot
execute, because the word never reaches that adder.** **MEASURED** (census) +
**FORCED** (the dispatch order). This is the single most useful thing this pass found and it
needed no run at all.

### 3.3 ⛔ The known-answer controls are INVISIBLE to the proposed instrument

Because mask bit 16 suppresses the store-and-clear, `212` leaves `acc` **identical** to
`202`; the whole difference is a write to `mem[m_dp]`. Same for `292` vs `212`. The trace's
printed columns contain **no `mem`**. ⇒ on the trace alone, the bit-4 and bit-7 controls
**cannot fire**, and a run whose calibration scores 0 of 2 is void by this project's own
rule. **FORCED.** The write *is* visible in `D-RAM WRITES (nonzero/total)`
(`upd6383.cpp:817`) and in `kwatch`/`watch_store`/`store_probe` — but those are keyed by
**cell**, or by a fixed `sprobe_idx()` SLOT list that contains **none** of `a70`'s body
slots. So the controls are recoverable only in aggregate, not per site.

### 3.4 ★★ THE MEASURED NULL — and it is degenerate

`class 2 ∧ lo12 = 0x000` words executed in the traced frame of `drpub_A_off_217`
(and identically in `drpub_B_on_217`, `src0b2_A_off_215`, `src0b2_B_on_215`): **37**.

```
    n  iw  u1  word         hi12  dp   d(acc)            acc              P          L
   13   13  0  0282200000   282   06   +788 981 014 570  1 028 206 280 788  239 225 266 218  8388607   ← KERNEL, the ONLY live one
   88  122  0  0102200000   102   0F                  0                  0                0        0
   90  124  0  0212200000   212   0F                  0                  0                0        0
   93  127  0  0202200000   202   0E                  0                  0                0        0
  127   57  0  0000201000   000   FE                  0      2 603 010 048    2 603 010 048        0
  ... 32 further sites, iw213..321, all  d(acc) = 0, P = 0, L = 0 ...
```

**36 of 37 sites have `L = 0` and produce `d(acc) = 0`.** With `L = 0` and `P = 0` the closed
form of §3.1 is the identity for **every one of the 17 forms** — LOAD, ADD, no-product and
store alike. **The bench is structurally blind wherever the pointer sits on a dead cell.**
**MEASURED.**

★ RULE 15, in its mirror image. The memory's rule says a pointer on a **live** cell makes any
operand score 4/4. Here the pointer sits on a **dead** cell and *nothing* scores — a
criterion that cannot fail, in the other direction.

**The exact table that would show a difference** (asked for explicitly): the
**`★ §104 PER-SLOT QUIET/LOUD SPLIT`** table, `upd6383.cpp:5544-5548`. It prints, per I-RAM
slot, `word`, `dp`, `nq/nl`, and quiet-vs-loud min..max for **`acc`**, **`mem` (under the
pointer, BEFORE the slot)** and **`L` (the selected bus)**, with a `*`/`=` verdict per column.
It is the only existing instrument with all three quantities per site. Its verdict on
CHORUS's three bench sites, over **706 040 quiet + 313 960 loud = 1 020 000 frames**:

```
   122 0102200000 0F  706040/313960   acc 0..0 / 0..0  =  |  mem 0..0 / 0..0  =  |  L 0..0 / 0..0  =
   124 0212200000 0F  706040/313960   acc 0..0 / 0..0  =  |  mem 0..0 / 0..0  =  |  L 0..0 / 0..0  =
   127 0202200000 0E  706040/313960   acc 0..0 / 0..0  =  |  mem 0..0 / 0..0  =  |  L 0..0 / 0..0  =
```

Three different `hi12` forms, one program, a million frames, **nine columns of zero**.
That is the null, and it is already on disk. **MEASURED.**

### 3.5 The prior on `a70`'s own sites

Body-0 liveness in the same logs (identical in all three arms): **31 of 70 slots** are
non-degenerate (`acc ∨ P ∨ L ≠ 0`), and they are **iw84..iw101** — the ladder is dead from
iw102 on. `a70`'s 20 sites sit at **iw88, 89, 105, 119, 120, 124, 125, 126, 134, 138, 139,
141, 143, 146, 149, 155, 156, 172, 178, 186**. Only **two** (w4/`02A`, w5/`022`) fall inside
the window that is live for CHORUS — and `02A` and `022` are **in the same behaviour class**
(both `op = 1`). `a70` is a different program with a different death point, so this is a
**prior, not a proof** — but it is the wrong direction, and it is **INFERRED** from
**MEASURED** numbers. If it holds, `a70` returns "no difference" at all 20 sites for reasons
that have nothing to do with `hi12`.

---

## 4. ITEM 4 — THE FALSIFIER, with named wrong numbers

**RULE 17** — graded by PROVENANCE, each with the specific `iw`/slot/counter value that
refutes.

| # | claim under test | **PASS** | ⛔ **FAIL — the named wrong number** |
|---|---|---|---|
| **F0** | the right program loaded | last `I-RAM[84..*]` transfer = **527 bytes / `I-RAM[84..188]`**, word 2 = `000024F40E` | **552 / `I-RAM[84..193]`** (⇒ `a68`, landed 27) or **467 / `I-RAM[84..176]`** (⇒ `a71`, landed 29) ⇒ **VOID** |
| **F1** | the instrument can see a bit-4 store at all | `D-RAM WRITES` total at the cell under `m_dp` at iw119 rises vs the control arm | trace `acc` at **iw119 == acc at iw124** *and* `D-RAM WRITES` unchanged ⇒ control scores **0 of 2** ⇒ **VOID** |
| **F2** | the bench sites are live enough to bear a difference | ≥ 2 of the 20 sites show `L ≠ 0` **in two different behaviour classes** of §3.1 | **`L: 0..0 / 0..0 =` at 20 of 20** (the measured CHORUS outcome, §3.4) ⇒ the run is a criterion that cannot fail |
| **F3** | the bit-5 observation is about the chip | — | **it never can be.** `acc` at **iw178** (`000`) differing from `acc` at **iw120** (`020`) is produced by `upd6383.cpp:4059`'s exact-match guard, §3.2. **Pre-registered as an ARTEFACT; it must not be reported as a bit-5 reading under any outcome.** |
| **F4** | `022` vs `02A` (bit 3) is decidable here | — | **FORCED IDENTICAL** (§3.1). The only observable is `m_bx_f5_n` > 0, which counts `f31 = 5` *evaluations*, not a semantic. Not a test. |

★ **F1 and F2 are the calibration and they must be read BEFORE anything else in the log.**
Compute the null and the calibration first, then interpret — never the other way round.

★ **The §193-shaped trap, pre-registered.** `§104`'s sampler arms at
`m_frames_run > 420000` (`upd6383.cpp:4706`) — **t = 8.75 s** — and never resets. With
`type_select.lua` the program only becomes `a70` at **t ≈ 45.4 s**. A 60-second run therefore
pools **≈ 1.76 M cold-boot CHORUS frames with ≈ 0.4 M `a70` frames at the same slot numbers**,
while `m_sp_word[]` is overwritten each visit and so *prints `a70`'s word beside CHORUS's
numbers*. **Any `§104` reading taken from a `type_select` run is confounded** — the exact
shape of §174's pooling error and §195's confound. `UPD6383_TRACE_FRAME` moves only the
**trace** arm, not this one. **MEASURED** (the threshold is in the source; the timeline is
computed in §5.2).

---

## 5. ITEM 5 — THE VEHICLE RECIPE, complete

### 5.1 The command

```sh
cd ~/compartilhado/kn7000-emulator
ISO=/tmp/claude-1000/.../scratchpad/s1run          # fresh, isolated
mkdir -p "$ISO/nvram" "$ISO/cfg" "$ISO/out"
cp cfg/kn5000.cfg "$ISO/cfg/"                      # ⚠ MUST carry  :DSPCFG value="3"
grep -c 'DSPCFG' "$ISO/cfg/kn5000.cfg"             # verify it is there BEFORE launching

TYPEIDX=28 TYPELAST=36 UPD6383_TRACE_FRAME=2300000 \
timeout 900 ./kn7000 kn5000 -rompath ./roms \
    -skip_gameinfo -log \
    -nvram_directory "$ISO/nvram" -cfg_directory "$ISO/cfg" \
    -pluginspath ./plugins \
    -autoboot_script ../kn5000-roms-disasm/dsp/tools/type_select.lua \
    -seconds_to_run 70 -window -resolution 640x480

# error.log AND kn5000_dsp1_upload.txt are written into the CWD.
cp error.log kn5000_dsp1_upload.txt kn5000_dsp1_upload.bin "$ISO/out/"   # BEFORE the next launch
```

* ⚠ **`-cfg_directory` must carry `:DSPCFG value="3"`.** `DSPCFG` is a `PORT_CONFNAME`
  defaulting to Off; a fresh cfg runs **zero DSP frames** and `device_stop()`'s
  `if (m_frames_run != 0)` prints **no report at all**. (`type_select.lua` also sets
  `user_value = 3` at startup, but that is belt-and-braces — §213 lost a run to this.)
* ⚠ **`-log` is REQUIRED.** The entire `upd6383:` report goes through `logerror`, which MAME
  discards without it. Silent stderr + `exit 0` + a normal trace is *this*, not a crash.
* ⚠ **visible video** (`-window -resolution 640x480`). **Never `-video none`.**
* ⚠ `timeout`-wrapped; **one run at a time**; isolated `-nvram_directory`.
* No rebuild is needed for the run as specified. **If** anything is rebuilt:
  `build.sh` **exits 0 on compile failure** — grep the log for `error:` **and** check the
  binary's mtime and that its size is > 70 MB; then run `tools/publish-binary.sh`.

### 5.2 Timing — derived, because two parameters depend on it

`type_select.lua` starts its schedule at `t = 19.0 s`, then:
`5.3 s` navigation → `45 × 0.32 = 14.4 s` UP-saturation → `1.5 s` → `(36−28) × 0.40 = 3.2 s`
DOWN → `2.0 s` (LANDED + snapshot) → `0.5 s` → **notes ON at t ≈ 45.9 s** → OFF at
`t ≈ 51.9 s` → exit at `t ≈ 53.9 s`.

* ⇒ **`-seconds_to_run 70`**, not 30. At 30 s the script has not even finished saturating.
* ⇒ the emulated frame rate is **48 000** (the tone generator's stream rate, not 44 100), so
  the note window is frames **2 203 200 .. 2 491 200**. **`UPD6383_TRACE_FRAME=2300000`**
  (t = 47.9 s) lands the trace comfortably inside it. **RULE 12**: arm by frame count, never
  on input — IC311's input latch rails at `0x800000`, which is exactly the `L = 8388607`
  visible at kernel iw13 in every log.
* ⇒ the trace's 400-slot cap is sufficient: with `a70` (105 words) at unit 0 the frame is
  `60 + 105 + 133 + 22 = 320` slots, against CHORUS's measured 285. **MEASURED + FORCED.**

---

## 6. ITEM 6 — INSTRUMENTATION: what exists, and what is actually needed

**RULE 13, third occurrence — aim the instrument that exists.** Checked before proposing
anything: `kwatch()` (`upd6383.cpp:639`), `store_probe()`/`sprobe_idx()` (`:506`),
`watch_store()` (`:465`), `src0b_census.py`, `s104_score.py`, `f31_probe()` (`:5269`),
`b11_probe()` (`:5325`), the `§104` table (`:5544`), `D-RAM WRITES` (`:817`), the
`ACCUMULATOR PROFILE` (`:828`), the time-ordered trace (`:816`).

| need | already exists? | verdict |
|---|---|---|
| per-slot `word`, `dp`, `acc`, `accb`, `P`, `cur`, `coef`, `MUL`, `L`, one frame, aimable | **YES** — the time-ordered trace, armed by `UPD6383_TRACE_FRAME` | **use it. Nothing to add.** |
| per-slot `acc` / `mem` / `L` quiet-vs-loud over millions of frames | **YES** — the `§104` table + `dsp/tools/s104_score.py` | exists, but **CANNOT be aimed at `a70`** (§4's pooling trap) |
| `mem[dp]`, `tempA`, `tempB` per trace row | **CAPTURED, NOT PRINTED** — `t.mem`/`t.ta`/`t.tb` are filled at `:4636-4643` and dropped by the format string at `:822-826` | a **format-string** change; changes no machine state and needs no gate |
| a bit-4 / bit-7 store at a *named body slot* | **NO** — `sprobe_idx()`'s SLOT list contains none of `a70`'s body slots; `D-RAM WRITES` is per-cell | would need a new probe — **and §3.3 says it would still not settle anything** |
| `f31 = 5` firing | **YES** — `m_bx_f5_n`, already counted and reported | free |
| `204.2.00.000` at `a70` w21 (I-RAM 105) | **YES, by accident** — `f31_probe()`'s `WIN[]` contains `0x0204200000` and its gate is `100 ≤ m_cur_iw ≤ 140` | fires at iw105 only (w88 at iw172 is outside), so its `slot min == max` self-check passes; a free cross-check that `a70` really loaded |

**⇒ NO new instrumentation is required, because the experiment should not be run.** If the
lane-holder nonetheless wants the two changes above, both are minimal and neither is a
semantic gate:

* **(i) Print the three captured columns.** One `logerror` format string + header at
  `upd6383.cpp:819-826`. No new state, no gate, no fired count — it changes only the log.
  It also fixes the **stale header**, which is a standing defect.
* **(ii) Make `§104`'s 420 000-frame threshold an env var** — `UPD6383_S104_FRAME`,
  **default 420000** so the shipped behaviour is bit-identical, announced unconditionally,
  reporting the number of frames actually sampled (**rule 8**: env var, default OFF/unchanged,
  with a fired count). This is what would let `§104` be aimed past a panel selection at all,
  and it is generally useful — every future `type_select` run has the same confound.

⚠ **NO mask bit is proposed, and the reason is measured, not asserted.** A programmatic scan
of every `m_specmask & 0xNNN`, `m_specmask & (1ull << N)` and `(m_specmask >> N) & M` in
`upd6383.cpp` + `upd6383.h` gives: **61 of 64 bits are referenced**; the only three never
referenced are **bits 1, 2 and 3** — and all three are **SET** in the default
`0xB910E446A39B440F`. **There is no bit that is both clear in the default and unallocated.**
The u64 mask is exhausted. **MEASURED.**

---

## 7. WHAT TO RUN INSTEAD

**Ranked substitutes, by forms carried** (asked for in the brief; `a70` remains the best
vehicle *if* a vehicle is ever wanted — and by a wider margin than S-1 says, once the two
always-resident forms are counted):

```
   a70 AUTO WAH+S.DELAY   11 forms (9 body + KERNEL 282 + EPILOGUE 102), 20 sites   TYPE 28
   a52 AUTO WAH           10 forms (8 body),                             18 sites   TYPE 18
   a48 AUTO PAN            9 forms (8 body),                             14 sites   TYPE 16
   a96 PEQ+COMPR+DIST      8 forms (7 body),                             14 sites   TYPE 34
   a98 PEQ+DIST+DELAY      7 forms (6 body),                             15 sites   ⚠ NOT IN THE TYPE LIST
   a97 PEQ+COMPR+OVERDR    7 forms (6 body),                             15 sites   TYPE 35
```

⚠ `a98 PEQ+DIST+DELAY` is **absent from the 37-entry front-panel list** (the walk goes
…`a97`, `a99`) — it is corpus-reachable but **not front-panel reachable**. Recorded so nobody
tries.

But the useful work is not a vehicle. In descending order of value:

1. **★★★ SHIP NOTHING; FIX THE MODEL DEFECT.** `exec_decoded()`'s exact-match `hi12 == 0x000`
   nop guard makes **103 corpus words in 28 of 40 streams** behave unlike their **350**
   siblings on the strength of bits the ALU otherwise never reads, and it silently
   contradicts this same file's acc-adder comment about `000.2.48.000`. That is a **decode
   question with a static answer**, and it belongs in the ISA notes, not in an experiment.
   Two-sided and both sides are worth the same: either `SRC 0x00 / ACT 0x00` means "add
   `mem[ptr]` to the accumulator" — in which case `000.2.dd.000` must do it too and the guard
   must go — or it is a genuine `nop`, in which case **`020`, `022`, `026`, `02A`, `202`,
   `204`, `212`, `292` on the same carrier are all nops too** and the ALU should not be
   running on any of them. The current build asserts *both*. **No run decides this; a
   decoding does.**
2. **★★ Give the `f31` pass its runtime blindness bound.** `S-12` asks for the high-`f31`
   words to be cross-tabulated against `action00-discriminator.md`'s static blindness census.
   §3.4/§3.5 here supply the *runtime* half for free from logs already on disk: over
   1 020 000 frames, CHORUS's bench sites are `0..0` in all three columns. Extending that
   count over all 384 slots with `s104_score.py` costs **zero runs** and yields a
   **completeness bound** — worth more than another experiment, exactly as S-12 argues.
3. **★ Take the free static tests** S-1's own note lists (S-5's `−99..−61` band vs the host
   zero-fill; S-7's `704`/`384`; S-8's SRC→ACT filter; §3.1's splice-marker census). They
   need no emulator and no vehicle.
4. **⛔ Do NOT propose an `f98` experiment of this shape** — 5 minimal pairs, **0
   co-resident**; no single loaded program can ever show it. And do not reopen `f31 = 4/5`
   (`f31 = 4` fires zero times on the clean vehicle), the bit-11 ALU route (no SRC, no ACTION
   field), or `ACT 0x15` (the multiply's condition is `class4(w)==0xA && !c_format(w)`).

---

## 8. SUMMARY — ten lines

1. **`a70 AUTO WAH+S.DELAY` IS reachable. TYPE index = 28, confidence HIGH** — three
   independent routes agree and two known-answer controls (`a10` at 8, `a39` at 15) pass.
2. `TYPELAST=36` is right; with it, `TYPEIDX` *equals* the real index and the walk is **8**
   DOWN steps. The map's collapse is at rows **19/20** (`a15 ROCK ROTARY`, `algos [15, 53]`),
   **not** "above 8" — so `TYPE_MAP.md`'s rule over-corrects rows 9..19, harmlessly for `a70`.
3. Fingerprint: **527 bytes / `I-RAM[84..188]`, word 2 = `000024F40E`**. Named wrong numbers:
   **552/`[84..193]`** = `a68` (landed 27) or **467/`[84..176]`** = `a71` (landed 29) ⇒ VOID.
4. **The word list in the source note is wrong twice:** `a70` has **20 sites / 9 forms**, not
   nine sites; and "17 forms / 354 words" **pools KERNEL + EPILOGUE** — body-only is
   **16 / 352**. The pooled two are always resident, so a run sees **11 of 17**.
5. **THE NULL, measured over 1 020 000 frames on logs already on disk:** CHORUS's three bench
   sites read `acc 0..0 / mem 0..0 / L 0..0`, `=` in all three columns. 36 of the 37 bench
   words executed in the traced frame have `L = 0` and `d(acc) = 0`. The table that would
   show a difference is **`★ §104 PER-SLOT QUIET/LOUD SPLIT`**; the trace's header is stale
   (real columns `n iw u1 word dp acc accb p cur coef MUL L`).
6. **The nine forms collapse into five behaviour classes BY CONSTRUCTION**; seven of the 36
   pairs are FORCED IDENTICAL, including the bit-3 pair `022 ↔ 02A`.
7. **The falsifier's named wrong number:** `L: 0..0 / 0..0 =` at **20 of 20** sites (F2), and
   `acc` at **iw119 == acc at iw124** with `D-RAM WRITES` unchanged (F1) — the calibration
   scoring **0 of 2**, which is what the shipped mask bit 16 guarantees.
8. **⛔ The experiment is NOT viable as designed.** Any bit-5 difference it produces is
   manufactured by `exec_decoded()`'s exact-match `hi12 == 0x000` guard
   (`upd6383.cpp:4059`) — pre-registered here as an artefact, not a reading.
9. **No new instrumentation is required.** The time-ordered trace is aimable today via
   `UPD6383_TRACE_FRAME=2300000`; `mem`/`tA`/`tB` are already captured and merely unprinted;
   **no spec-mask bit is proposed — 61 of 64 bits are referenced and the only three that are
   not (1, 2, 3) are SET in the default, so the mask is exhausted (MEASURED).**
10. **This is not an audio test and cannot become one (§216).** The real deliverable is
    static: **103 words in 28 of 40 streams are intercepted as `nop` while 350 siblings run
    the ALU**, and one of them, `000.2.48.000`, is the very word `upd6383.cpp`'s own
    acc-adder comment says must produce `bus + P`.
