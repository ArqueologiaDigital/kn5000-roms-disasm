# `§226` — the header's coefficient bank is **FOUND**, and the shipped build is **already reading it**

> ## ⛔⛔ CORRECTION BANNER — `§227`, 2026-07-31. **READ THIS BEFORE ANY LINE BELOW.**
>
> **§227 took the reverb-preset capture §8 of this document asked for, and it REFUTES ITEM D IN ITS
> STRONG FORM.** `C-RAM[0x90..0xB4]` is **NOT** a boot-fixed bank: it is **UNIT 1's (the reverb's)
> own per-algorithm parameter bank**. A preset change `CONCERT REVERB 1 → ROOM REVERB 1` rewrites
> **23 cells, every one inside `0x90..0xB4` and NOTHING else in the 256-cell C-RAM**; **13 of the
> header's 20 walk cells `0x90..0xA3` move**, and **2 of the 3 ladder cells — `0x9B` and `0x9C` —
> move with them**. The ladder is `+1.720 FS` on CONCERT 1 and `+1.320 FS` on ROOM 1.
>
> **The control that makes this proof-grade:** an independent 45 s panel run landing on CONCERT
> REVERB 1 reproduces the archived cold-boot capture on **all 256 cells, 0 differ** ⇒ ★ **the
> cold-boot default reverb is CONCERT REVERB 1, not ROOM REVERB 1** — so every "CHORUS + RR1"
> label in §3.1/§4 and item G's preset attribution below names the **wrong preset**.
>
> **WHAT SURVIVES UNCHANGED:** the *upload* half of item D (the boot-time `cmd 0x02` runs at
> `0x90` + `0xAE`, and `headerdecode.md` §7.6's answer that the destination comes from an `ldptr`
> in a scratch I-RAM slot); item B (base `0x00` is unit 0's per-effect bank); item C (⛔ **base
> `0x00` is still refuted and is still worse on every image**); item E (the base is seeded by
> `iw69`); item F; item H.
>
> **WHAT IS NOW THE BLOCKER:** *both* candidate bases are somebody's per-algorithm parameter bank.
> See `SPECULATIVE-APPLIED-REGISTER.md` **§227** §9.1 — three separable readings, and a falsifier
> that distinguishes them is required before any of them is tried.
> Reproduce: `python3 dsp/tools/hdrbase.py --score notes/data/kn5000_dsp1_upload_concertreverb1.txt notes/data/kn5000_dsp1_upload_roomreverb1.txt`

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Date **2026-07-31**. Register head **§226**.
**STRICTLY READ-ONLY pass**: no source edited, no build, no MAME run. Every number comes from the
committed corpus (`dsp/disasm/*.dsm`), from the **two archived host captures**
(`kn7000_mame/notes/data/kn5000_dsp1_upload_{coldboot,parametriceq}.txt`), from the Sub CPU ROM's
own per-algorithm parameter map, and from `data/K_lfowrap_default_225.log.gz` (arm **K**, the
shipped default). Instrument: `dsp/tools/hdrbase.py`; archived output `data/HDRBASE_226.txt`.

Labels: **MEASURED** / **FORCED** / **INFERRED** / **SPECULATIVE**.

⚠ **RULE 19 / THE STANDING TRAP.** This pass makes **no audio claim of any kind** and nothing in it
moves the output. `§54`, `§70 ACCA@w73` and `§211 ACCB@w78` are quoted from arm K in §6 and are
unchanged because **nothing was changed**.

---

## 0. RESULT — the task's own trap fired, in an unexpected direction

| # | statement | grade |
|---|---|---|
| **A** | ★★★ **`C-RAM[0x0B..0x0D]` IS FILLED** — `E00000 / E00000 / FFFF10` — by the **boot-time `cmd 0x02` run at base `0x00`, 20 values**. It is not empty, so the brief's *"seeding to `0x0B` may multiply by zero"* trap does **not** fire in its literal form. | **MEASURED** |
| **B** | ★★★★ **BUT `C-RAM[0x00..0x13]` IS THE UNIT-0 EFFECT'S OWN PARAMETER BANK AND IT IS EFFECT-DEPENDENT — MEASURED TWO INDEPENDENT WAYS.** (a) selecting **PARAMETRIC EQ** rewrites `0x00..0x1E` wholesale, in twelve `cmd 0x02` runs at base `0x00`, and changes **every one of `0x00..0x13`**; it writes **nothing at or above `0x50`**. (b) the Sub CPU ROM's per-algorithm parameter map writes **every one of `0x00..0x13`** for some algorithm — `0 of 20` are invariant. | **MEASURED** |
| **C** | ★★★★ **THEREFORE THE PROPOSED FIX IS REFUTED, AND IT IS REFUTED IN THE DIRECTION THAT MATTERS.** The header is a **literal canned image in Sub CPU ROM** (PROVEN BY CONSTRUCTION, `kernel.dsm` banner) — it cannot read a bank that changes with the effect selection. And the *number* goes the wrong way too: run the identical ladder at `0x0B` **with PARAMETRIC EQ loaded** and it is `iw30 −1.000 FS`, `iw32 **+2.000 FS**`, `iw33 **+2.733 FS**` — **worse than the shipped `1.720`**. The advertised *"+0.125 FS, no clip"* is a property of **CHORUS's parameter set**, not of the base. | **MEASURED** |
| **D** | ★★★★ **THE BANK `headerdecode.md` §5 PREDICTED IS FOUND, AND SO IS ITS UPLOAD — `§7.6` IS ANSWERED.** It is **`C-RAM[0x90..0xB4]`**, filled by the **boot-time `cmd 0x02` runs at base `0x90` (30 values) and `0xAE` (7 values) = 37 cells**, **byte-identical in both archived captures**. `22` of those 37 cells are written by **no algorithm at all**. The header consumes `0x90..0xA3`, of which **15 of 20 are invariant** — and **all three ladder cells `0x9B/0x9C/0x9D` are invariant across the effect change AND across every runtime poke in a 30-second run.** | **MEASURED** |
| **E** | ★★★ **THE BRIEF'S PREMISE — *"the cursor is never seeded at frame start, so the header runs on whatever the previous frame's unit-1 body left behind"* — IS FALSE, TWICE.** (i) The base is set by an **instruction**: the epilogue's own `iw69 = 801.0.90.821 ldptr #$90`, through register row 25 (the `is_ldptr` branch — `m_cursor = ad` under `!(m_specmask & 0x1000)`, and **mask bit 12 is CLEAR in the default `0xb910e446a39b440f`**, so the rule is LIVE). (ii) The epilogue contains **ZERO** cursor-advancing words, so nothing can perturb it: the next frame's `w0` starts at **exactly `0x90`, every frame**. `upd6383.cpp`'s frame-restart block says so in words and cites the measured position. `§S2`'s `0x9B` is `0x90 + 0x0B`, and `w30` is the header's **twelfth** cursor word. | **FORCED** (source + corpus) |
| **F** | ★★ **THE `20` IS A COINCIDENCE AND IT IS THE BEST EVIDENCE THE OTHER WAY, SO IT IS ANSWERED HEAD-ON.** The header block proper has exactly **20** cursor-advancing words and the boot run at base `0x00` is exactly **20** cells — which looks decisive for `0x00`. It is not: that run is sized by **CHORUS's body** (`classA 19`, `+1` — `headerdecode.md` §5's own centring), and the same run is **31 cells** when PARAMETRIC EQ is selected (`70` cursor words, `31` coefficients — §5's named outlier, reproduced here by an independent decoder). A bank whose length tracks the algorithm is the algorithm's. | **MEASURED** |
| **G** | ★ **BONUS — the 13 tag-`0x26` C-RAM targets, `SQUARING-MULTIPLY_findings.md` §9's named instrument gap, are now bounded.** The archived capture and the live 30-second run differ on exactly **10 cells** — `09 0A 90 97 9F A0 A7 A8 AC B2` — and **9 of the 10 are named by the ROM's own T1 parameter map** (`09/0A/90` = CHORUS's `op66`×2 + `op21`; `9F/A0/A7/A8/AC/B2` = ROOM REVERB 1's `op76` damping triples and their L/R twins). ⚠ This is the **net** difference, not the packet log: a poke that rewrote the same value is invisible, and `0x97` is unattributed. | **MEASURED** |
| **H** | ⚠ **A CORRECTION THE BRIEF ASKED FOR (RULE 20).** *"`kernel.dsm`'s own annotated base `0x0B`"* is **not a measurement of the header**. `gen_dsp_disasm.py`'s kernel `emit_listing` call passes the literal `0x00` for the kernel listing and `emit_listing` prints the words *"base 0x00 MEASURED"* unconditionally; the word MEASURED belongs to `cram-unit-base.md` item A, which measured **unit bodies** (1546 class-A words) and says nothing about the header. `SQUARING-MULTIPLY_findings.md` item G already flagged this; it is restated here because the brief promoted the annotation to an anchor. | **MEASURED** |

**VERDICT — `NO CHANGE SHIPS.` The addresses were already right.** The `1.720 × FS` overflow is
**not** a mis-addressed bank: `C-RAM[0x9B/0x9C/0x9D] = +0.600000 / +0.500000 / +0.500000` are
genuine boot constants that **no algorithm's parameter stream ever overwrites**, identical in the
cold-boot capture, in the PARAMETRIC-EQ capture and in the live run. ⇒ the overflow has to be
explained by the **ALU decode of `iw30/iw32/iw33`**, not by where they point.

---

## 1. RULE 20 — the self-test, printed BEFORE any interpretation, **10 of 10 PASS**

```
   kernel words 60                                              PASS
   epilogue words 23                                            PASS
   kernel cursor-advancing words 21                             PASS
   ...of which BEFORE w42's ldptr, 20                           PASS
   epilogue cursor-advancing words 0                            PASS
   w30/w32/w33 offsets 0x0B/0x0C/0x0D                           PASS
   coldboot cmd-0x02 run bases/lens                             PASS   <- (0x50,30)(0x6E,30)(0x90,30)(0xAE,7)(0x00,20)
   headerdecode §5: algo 39 ships 31 coefficients               PASS   <- EXTERNAL, another pass's number
   live C-RAM non-zero cells (log says 112)                     PASS   <- EXTERNAL, the log's own counter
   §224 §S2 iw33 at the shipped base 0x9B = 945 579 874 058     PASS   <- EXTERNAL, another instrument
```

★ **Three of the ten are external known answers reached by a wholly independent path** — a capture
replayer that has never seen the emulator, scoring `headerdecode.md` §5's PEQ coefficient count and
`§224`'s `§S2` ladder value. That is the only kind of control a pure observer can have.

⚠ **The capture replayer's own limits, stated.** The `cmd 0x02` packet carries **no write address**:
the host writes an `ldptr` word (`hi12 0x801`, `lo12 0x821`) into a scratch I-RAM slot with a
`cmd 0x01`, then streams 3-byte coefficients. The replayer follows that rule and reproduces the
emulator's C-RAM on **246 of 256 cells**; the 10 exceptions are item G's runtime pokes, which the
capture predates.

---

## 2. THE HEADER'S CURSOR MAP, AND WHY THE BASE IS `0x90` EVERY FRAME

```
   w5:+00  w6:+01  w7:+02  w10:+03  w14:+04  w16:+05  w17:+06  w18:+07  w20:+08  w21:+09
   w23:+0A  w30:+0B  w32:+0C  w33:+0D  w34:+0E  w35:+0F  w36:+10  w37:+11  w39:+12  w41:+13
   ---- w42  `ldptr #$70'  RE-AIMS THE CURSOR ----
   w45:+14 (reads 0x70, relocated to 0xB0 by §72)
```

**20 cursor-advancing words before `w42`** ⇒ the header block proper consumes `base+0x00 .. base+0x13`.
`w30/w32/w33` are `+0x0B/+0x0C/+0x0D`, so `§S2`'s measured `0x9B` forces `base = 0x90`. ✔

**Why `0x90`, and why it cannot drift:**

* the `is_ldptr` branch (register row 25 — `m_cursor = ad` under `!(m_specmask & 0x1000)`; **mask bit 12 CLEAR ⇒ LIVE**) makes every `ldptr` seed the
  cursor. The corpus contains exactly three: `iw42 -> 0x70`, `iw50 -> 0x50`, `iw69 -> 0x90`.
* `iw69` is in the **epilogue**, which runs last, and **the epilogue has ZERO cursor-advancing
  words** (MEASURED here, and it is the load-bearing half). ⇒ the cursor at the next `w0` is
  `0x90` **exactly**, not `0x90 + n`.
* The frame-restart block in `upd6383.cpp` says this deliberately: *"Words 0..41 … run on pointers
  left behind by the PREVIOUS frame's epilogue (its last loads are I-RAM 62 `825<-$26`, **69
  `821<-$90`**, 77 `822<-$86`) … Zeroing `m_dp` / `m_cursor` / `m_acc` here would break the
  machine's own state threading."*
* Corroborated live: the arm-K log's `KERNEL CURSOR` row reads `0:cur=0x90 … 5:cur=0x91 …
  23:cur=0x9B`.

⇒ *"never seeded at frame start"* is true only of a **frame-start assignment statement**. The base
is seeded, by an instruction, deterministically. **⚠ Do not re-file this as an unseeded carry-over.**

---

## 3. THE DISCRIMINATOR — a fixed program cannot read a per-effect bank

### 3.1 Capture vs capture (MEASURED, no model)

```
   CHORUS-boot  vs  PARAMETRIC-EQ capture:   31 cells differ,  0x00 .. 0x1E
   at or above 0x50:                          0 cells differ
```

The unit-0 effect change rewrote **base `0x00` and only base `0x00`**, in twelve `cmd 0x02` runs.

```
                    C[0x0B]   C[0x0C]   C[0x0D]
   coldboot          E00000    E00000    FFFF10
   parametriceq      800000    D445EF    400000     <- ALL THREE MOVED
   coldboot          C[0x9B] 4CCCCC  C[0x9C] 400000  C[0x9D] 400000
   parametriceq      C[0x9B] 4CCCCC  C[0x9C] 400000  C[0x9D] 400000   <- IDENTICAL
   LIVE arm K        C[0x9B] 4CCCCC  C[0x9C] 400000  C[0x9D] 400000   <- IDENTICAL
```

### 3.2 The ROM's own per-algorithm parameter map (MEASURED, second route)

```
   cells 0x00..0x13 written by NO algorithm :  0
   cells 0x90..0xB4 written by NO algorithm : 22
       91 92 93 94 95 96 97 98 99 9A 9B 9C 9D  A1 A2 A3 A4 A5  AD AE B3 B4
```

### 3.3 ⇒ scored, per candidate base

```
   base 0x90 (SHIPPED )  cells 0x90..0xA3 : 15 of 20 INVARIANT,  5 effect/poke-written (90 97 9E 9F A0)
        ladder cells 9B 9C 9D : ALL INVARIANT
   base 0x00 (PROPOSED)  cells 0x00..0x13 :  0 of 20 INVARIANT, 20 effect/poke-written
        ladder cells 0B 0C 0D : EFFECT-DEPENDENT, all three
```

⚠ **Stated at its real strength, both ways.** `15 of 20` is not `20 of 20`: `0x90` is written by
**every** unit-0 algorithm (opcode `0x21`, one cell — plausibly the effect-depth knob, and `w5` is
the input stage's first cursor word, which is a *sensible* thing for it to read), and `0x9E/0x9F/0xA0`
are ROOM REVERB 1's `op76` damping triple. So the header does read a handful of live parameters.
**That is a real, unexplained overlap and it is filed, not hidden.** It does not rescue `0x00`,
where the score is `0 of 20` and the three ladder cells move.

---

## 4. THE LADDER AT BOTH BASES, ON BOTH EFFECT SELECTIONS

```
   coldboot  (CHORUS + RR1)   base 0x9B   iw30 +0.600  iw32 +0.720  iw33 +1.720   CLIPS
   coldboot  (CHORUS + RR1)   base 0x0B   iw30 -0.250  iw32 +0.125  iw33 +0.250   no clip
   parameq   (PEQ + RR1)      base 0x9B   iw30 +0.600  iw32 +0.720  iw33 +1.720   CLIPS
   parameq   (PEQ + RR1)      base 0x0B   iw30 -1.000  iw32 +2.000  iw33 +2.733   CLIPS   ★
   LIVE armK                  base 0x9B   iw30 +0.600  iw32 +0.720  iw33 +1.720   CLIPS
   LIVE armK                  base 0x0B   iw30 -0.250  iw32 +0.125  iw33 +0.250   no clip
```

★★★ **THE SHIPPED BASE GIVES THE SAME THREE NUMBERS ON EVERY C-RAM IMAGE.** The proposed base
gives a different answer per effect, and on one of the two it is **1.6 × worse**. A canned header
whose arithmetic depends on which effect the user selected is not a reading, it is a bug.

**THE NULL, recomputed here and reconciled with `SQUARING-MULTIPLY_findings.md` §6.2:**

```
   LIVE 0x00..0x13     2 of  20 clip   10.0 %      <- §6.2 says 2 of 20, 10.0 %      MATCH
   LIVE 0x50..0x8B     0 of  60 clip    0.0 %      <- §6.2 says 0 of 60,  0.0 %      MATCH
   LIVE 0x90..0xB4    28 of  37 clip   75.7 %      <- §6.2 says 28 of 37, 75.7 %     MATCH
   LIVE all non-zero  30 of 112 clip   26.8 %      <- §6.2 says 31 of 123, 25.2 %    ⚠ denominator
```

⚠ The last row is the only discrepancy and it is a **denominator convention**: this pass sweeps the
`112` cells the log's own counter calls non-zero; §6.2 swept `123`. The three sharp rows match
exactly, so the detector is validated where it matters, and the load-bearing statement — *the
header's bank is the one region where the ladder overflows three times out of four* — is unchanged.
★ **And that statement is now the wrong way round from how §6.2 read it:** the header runs on
`0x90..` **because that is its bank**, and the `75.7 %` is a fact about the ladder's ALU decode,
not evidence of mis-addressing.

---

## 5. WHAT THIS RETIRES OR CORRECTS

| claim | status |
|---|---|
| *"the coefficient cursor is never seeded at frame start; the header runs on whatever the previous frame's unit-1 body left behind"* (the §226 brief) | ⛔ **FALSE, twice.** The base is set by the epilogue's own `iw69 ldptr #$90` through row 25 (mask bit 12 CLEAR = live), and the epilogue has **zero** cursor-advancing words, so `w0` starts at **exactly** `0x90` every frame |
| *"run the identical ladder at `kernel.dsm`'s own annotated base `0x0B` and it lands at +0.125 FS, no clip"* (`§224`/`SQUARING` item F) | ⛔ **REFUTED AS A FIX.** True for CHORUS only. With PARAMETRIC EQ loaded the same base gives `iw32 +2.000 FS`, `iw33 +2.733 FS` — worse than the shipped `1.720` |
| *"`kernel.dsm` annotates base `0x00` MEASURED"* | ⚠ **THE GENERATOR HARDCODES IT.** `gen_dsp_disasm.py`'s kernel `emit_listing` call passes the literal `0x00`; the word MEASURED comes from `cram-unit-base.md` item A, which measured **unit bodies** |
| **`headerdecode.md` §5** *"the header reads a separate, fixed coefficient bank, loaded once at boot"* | ★★★ **CONFIRMED AND LOCATED: `C-RAM[0x90..0xB4]`**, 22 of whose 37 cells no algorithm ever writes |
| **`headerdecode.md` §7.6** *"I did not find the upload that fills it"* | ★★★★ **ANSWERED.** The boot-time `cmd 0x02` runs at base `0x90` (30 values) and `0xAE` (7), byte-identical in both archived captures. The write address is not in the packet — the host writes an `ldptr` into a scratch I-RAM slot first, which is why nine months of looking at `cmd 0x0C` found nothing |
| **`k3-pointers.md` §4.2** *"whatever sets the cursor's per-unit base is still unidentified"* | ⚠ **PART-ANSWERED for the KERNEL only**: it is `ldptr` (row 25). ⛔ **STILL AGAINST K3**, which FORCED that selector `0x21` is *not* the implicit cursor. Row 25 remains SPECULATIVE — but it is now the rule that puts the header on the one effect-invariant bank, which is evidence *for* it |
| **`SQUARING-MULTIPLY_findings.md` §9** *"the 13 tag-`0x26` C-RAM targets are unrecorded"* | ★ **BOUNDED**: 10 cells move between the capture and a live 30 s run, 9 of 10 named by the ROM's T1 map. ⚠ Net difference, not the packet log; `0x97` unattributed |
| **`upd6383.cpp:5948`** *"the coefficient stream fills `[0x90..0xAD]` with 30 values, **unclaimed by either body**"* | ⚠ **STALE.** The run is `[0x90..0xB4] = 37` cells (30 + 7 in two packets), and with the mask-bit-38 CALL seed live, **unit 1's body claims `0x90..` too**. The overlap between the header's `0x90..0xA3` and the reverb's own bank is real and OPEN |
| *"the `1.720 × FS` overflow is the CURSOR BASE"* (`SQUARING` item F, the §226 brief's thesis) | ⛔ **RE-ATTRIBUTED AGAIN, and this time away from addressing entirely.** The addresses are right and the constants are boot-fixed. It is an **ALU decode** question at `iw30/iw32/iw33` |

---

## 6. THE ARM, QUOTED — arm **K**, `data/K_lfowrap_default_225.log.gz`, the shipped default

**Nothing shipped, so before = after on every line.**

```
   §S1  iw34   14 428 403  (1.720 x FS)  both buckets, clips 706 040 / 313 960   UNCHANGED
   §S2  iw33   carried 395 824 060 170 + bus 274 877 906 944 + P 274 877 906 944
                     = 945 579 874 058                                          UNCHANGED
   §S1  TOTALS quiet 9 178 556 / 186 394 560 = 4.924 %  |  loud 4 077 722 / 82 885 440 = 4.920 %
   §S1  iw39   loud min 1 991 044        §S2sq 5 100 000, 5 slots
   §41  unit0 0x400000  unit1 0x178D0B   |  m_rf[0x8D] = 0x009B26  |  §160 06 = 400000
   w72  L = 4 194 304 .. 4 194 304, both buckets
   §S3  TOTAL stores to cell 0x06 = 5 881 351  (= §220's mask-bit-26 count, external control)
   §54  quiet-in 826 040 -> 826 040 SILENT / 0 LOUD (peak 0)
        loud-in  313 960 -> 313 960 silent / 0 loud (peak 0)
   §70  ACCA@w73   quiet mean 0.0 span 0  |  loud mean 0.0 span 0
   §211 ACCB@w78   quiet mean 0.0 span 0  |  loud mean 0.0 span 0
   §104 body 0 D-I (rule21_all.py, re-run here)  0/0/0     kernel A D-I 27/21/18
```

★ **`26/28/27` over `0/0/0` STILL HOLDS.** `rule21_all.py` re-run on arm K gives body 0
`acc 2 = I 0 + FREE 2 | mem 9 = I 0 + FREE 9 | L 4 = I 0 + FREE 4` ⇒ **`D-I = 0/0/0`**, the null;
`26/28/27` is the `NOZ05` send-open arm's figure and is unaffected by this pass. Kernel A's
`D-I = 27/21/18` matches `§225`'s `W4′-c` exactly.

⚠ **`§54` graded FIRST, as instructed:** the quiet window is **not** full scale (peak `0`), and the
loud peak does **not** exceed the quiet peak (both `0`). **There is no output to claim and none is
claimed.**

---

## 7. WHY NOTHING WAS BUILT, AND THE GUARD THAT DECIDED IT

The brief's own guard: *"a clip rate that falls because a coefficient became zero is a REGRESSION,
not a fix — guard against it explicitly."* The generalisation that actually bit here is one step
wider:

> ★★★★ **A CLIP RATE THAT FALLS BECAUSE A COEFFICIENT BECAME *SOMEBODY ELSE'S* IS ALSO A
> REGRESSION.** Seeding the header to `0x00` would have dropped `§S1`'s `iw34` row and `§S2`'s
> `iw33` row on the archived vehicle and looked like a clean win in every statistic the project
> prints — while pointing a **fixed canned program** at a **per-effect parameter bank**, and while
> making the same ladder **worse** on the other effect selection we happen to have a capture of.
> **The falsifier that caught it cost one capture file and no run.**

⇒ ⛔ **`UPD6383_HDRBASE` was NOT written, NOT built and NOT run.** Building the refuted arm would
have produced an attractive number with no reading behind it, which is what §217–§225 exist to
avoid. `dsp/verify.py`: **BYTE-MATCH OK** (baseline re-confirmed; no source touched).

---

## 8. WHAT THIS PASS IS BLIND TO

* **Two effect selections, one board, one boot.** The invariance of `[0x90..]` is measured against
  **one** capture pair, in which unit 1 (ROOM REVERB 1) did **not** change. ⚠ **A reverb-preset
  change would rewrite `0x9E..0xB2`** by the ROM's own T1 map, and `0x9E/0x9F/0xA0` are inside the
  header's walk. **The right next capture is a reverb-preset change**, and it is cheap.
* **The `0x90 / 0x9E / 0x9F / 0xA0 / 0x97` overlap is unexplained.** Five of the header's twenty
  cells are effect- or poke-written. Either the header legitimately reads live parameters (an input
  level and a damping triple is not an absurd list), or the header/body overlap on `[0x90..]` is
  itself a decode error. **Not decided here.**
* **The T1 parameter map is a derived join, not a capture.** `kn5000_dsp_namedcoeff.host_coeff_map`
  names ~500 coefficients and its own coverage section admits gaps — `0x97` moved live and is in no
  algorithm's map. Where the two routes disagree, prefer the **capture**.
* **Row 25 is still SPECULATIVE and still contradicts K3.** This pass strengthens the *consequence*
  of row 25 without proving the *coupling*. If K3 is right, some other word aims the kernel's
  cursor, and it had better land on `0x90` too.
* **No audio, no run, no new log.** Every runtime number is arm K's.

---

## 9. THE NEXT EXPERIMENT, PRE-REGISTERED

1. ★★★★ **THE BLOCKER MOVES TO THE ALU DECODE OF `iw30 / iw32 / iw33`.** Their addresses are now
   established and their constants are boot-fixed, so `1.720 × FS` is produced by *what the three
   words do*, not by what they read. The terms are `C[0x9B] = +0.6`, `C[0x9B]² = +0.72`,
   `C[0x9D] = +0.5`, `C[0x9C]² = +0.5`. **The one reading nobody has tested is that `iw33`'s
   `f31 = 1` should NOT carry `iw32`'s accumulator** — drop the carried term and `iw33` is
   `0.500 + 0.500 = 1.000 FS`, still at the rail; drop the carried term **and** apply the
   Q-consistent `P_SHIFT = 7` and it is `0.500 + 0.250 = 0.750 FS`, in range. ⚠ Two changes at
   once is not an experiment — **bisect**, and ⛔ `P_SHIFT` still may not move on a number alone.
2. ★★★ **CAPTURE A REVERB-PRESET CHANGE.** One capture decides whether `0x9E..0xB2` really moves
   under the user's reverb knob, which is the only surviving threat to item D. `hdrbase.py` scores
   it in one line.
3. ★★ **RESOLVE THE HEADER/BODY OVERLAP ON `[0x90..]`.** With mask bit 38 live, the header reads
   `0x90..0xA3` and unit 1's body re-reads from `0x90`. Either the CALL seed for unit 1 is wrong
   (candidate: the body starts where the header stopped, `0xA4`, which the source comment at
   `upd6383.cpp:4971` already floats as `21 + 16 = 37`), or the overlap is real. ⚠ The reverb has
   **33** cursor words, not 16, so that comment's arithmetic does **not** close — do not adopt it
   without re-deriving.
4. ⛔ **NOT a frame-start cursor seed.** Refuted here; the base is already `0x90` and already
   deterministic. Adding an assignment that sets it to the value it already has is a cannot-fail
   change.
5. ⛔ **NOT `UPD6383_NOSQ`** as a *fix* — `SQUARING` §7 designed it as a two-sided **diagnostic**
   and item A/B of that pass established the squaring is faithful. It may still be run for its
   information, but its `P2` prediction (`iw33 -> 0.500 FS`) is now known to be a *suppression*,
   not a correction.
