# PREDICT_217 — the `§78` publish schedule, and where `iw12`'s datum actually goes

**Committed BEFORE `build.sh` is run.** Scored in `SPECULATIVE-APPLIED-REGISTER.md` §217.

Brief: `§215/§216` measured `m_dr` non-zero at `iw25` on **0 of 1 211 520** evaluations in the
arm where `§80` published **181 521** non-zero data. The named suspect is the `§78` per-line
publish schedule, `line = descriptor_value & 0x3f`, with the note that "the kernel's delay words
all share line 0".

⚠ **This is NOT an audio experiment.** `§216` proved the output stage is a null *independently of
what the send carries* (send forced open, body 0 ran its whole ladder on live audio, `w73`/`w78`
still `min 0 max 0`). Nothing here is expected to make the chip sing, and no non-zero number will
be read as progress toward that.

---

## 0. ★★★ THE PREMISE IS ALREADY HALF-WRONG, AND THE CORRECTION IS THE FIRST RESULT

**"Every kernel delay word shares line 0" comes from `§46`'s descriptor dump, which is an
UNGUARDED BOOT-TIME SAMPLE.** `upd6383.cpp:1948` fills `m_dly_dsc[]/m_dly_val[]` with the **first
8 distinct descriptor cells ever seen**, with no `m_frames_run` guard — the exact defect `§204`'s
own comment warns about ("the first version recorded the first 16 consumers EVER — all from boot,
before the program is uploaded"). Before the host uploads the descriptor bank every cell reads
`0000`, so `§46` prints `[R dsc 27 = 0000] [R dsc 28 = 0000] …` **forever**.

`§204`'s census IS guarded (`m_frames_run > 900000`) and its numbers are in the same log
(`data/src0b2_B_on_215.log.gz`). In a settled frame:

```
   iw12  cell 0x1041 -> line 0x01     iw93  cell 0x0190 -> line 0x10
   iw26  cell 0x05A0 -> line 0x20     iw98  cell 0x1041 -> line 0x01   <- iw12's PAIR
   iw46  cell 0x0000 -> line 0x00     iw102 cell 0x05A0 -> line 0x20   <- iw26's pair
   iw54  cell 0x0C30 -> line 0x30     iw107 0x0000 / iw134 0x09B0 / iw139 0x0410 /
                                      iw143 0x0DC0 / iw148 0x0820 / iw152 0x8000
```

⇒ The kernel's four delay words carry **three distinct lines (0x01, 0x20, 0x00)**, not one, and
the pairing `iw12 ↔ iw98` is exactly `§79`'s stride-5 model working correctly.
**P0 (INFERRED, to be confirmed by the run): the line index is a RED HERRING.**

## 1. THE MECHANISM I CLAIM, DERIVED FROM THE SOURCE

`upd6383.cpp:2104-2140`. The publish lives **inside the `is_dram` branch**:

```
   publish   if (port_pipe && m_dr_line_v[line]) m_dr = m_dr_line[line];   // delay words ONLY
   ALU       exec_alu(word)                                               // SRC 0x0B reads m_dr
   latch     if (dir=='R') { m_dr_line[line] = datum; m_dr_line_v[line] = true; }
```

`iw25` is `000.2.00.2D9` — **class 2, no delay access**, so it never enters that branch and can
never trigger a publish. It reads whatever residue `m_dr` holds.

And `iw12` **latches after it publishes**, so `iw12`'s own datum cannot be on the bus at `iw25`
even in principle; it waits in `m_dr_line[0x01]` until the next line-0x01 delay word, which the
`§204` census names as **`iw98`** — 73 slots and one body-CALL later.

⇒ **The datum is not lost. It is DELIVERED TO THE WRONG WORD, on time, by a schedule that only
ever fires at delay words.** The fault is the *binding of the publish to delay-word execution*,
not the line index and not the single register.

## 2. THE NULL — computed from `data/src0b2_A_off_215.log.gz` BEFORE this build

| # | quantity | predicted |
|---|---|---|
| **N1** | publishes strictly between `iw12` and `iw25`, per run | **exactly 0** (structural: the kernel has no delay word in `iw13..iw24`) |
| **N2** | `§215 m_dr non-zero at iw25`, arm A | **0**, reproducing §215 |
| **N3** | settled (`> 900 000`) class-2 evaluations | **400 000 – 500 000** (0.836 body-0 executions/frame × 540 205 settled frames) |
| **N4** | `§80` latched / publish hits, arm B vs arm A | **identical to within 0.1 %** — `DRPUB` must not touch the pairing |
| **cal** | vehicle | `located=true`, `NOTE ON ≈ 21.0`, `NOTE OFF ≈ 27.5`, loud frames 250 000–380 000 |

## 3. ★★ THE CRITERION — provenance, NOT liveness (standing rule 15 / dead-end 22)

The four falsifiers of `HANDOFF-NEXT.md` §1.2 were retired because **any live operand passed
them**. The instrument here does not ask "did something arrive"; it asks **WHICH WORD READ IT**.

Every latch is tagged with `(the iw that performed the read, the frame)`. Every write to `m_dr`
carries the tag forward. At `iw25` the tag is histogrammed. A wrong source reports a **wrong `iw`
number**, which no amount of liveness can fake. Read-only, runs in **both** arms.

### P1 — the control's provenance, traced by hand, and it is falsifiable to the word

Per-frame delay-word order, from `§204` (settled) + `§209`'s `m_delay_ix` values, which place
`iw54` **between** body 0 and body 1 (it carries `ix9`, continuing body 0's `ix8`; had it run
after body 1 it would carry `ix16`):

```
   kernel  iw12 R L01 | iw26 R L20 | iw46 W L00
   body 0  iw93 W L10 | iw98 R L01 | iw102 W L20 | iw107 L00 | iw134 L30 | iw139 L10
           iw143 L00 | iw148 L20 | iw152 L00
   kernel  iw54 W L30
   body 1  iw200 L27 iw211 L00 iw215 L05 iw219 L00 iw223 L3E iw227 L36 iw231 L01 iw235 L05
           iw239 L23 iw243 L3E iw247 L2D iw251 L01 iw255 L0D iw259 L23 iw263 L0D iw269 L2D
   epilogue  NO DELAY WORDS AT ALL (measured: 0 in epilogue.dsm)
```

Line 0x01 in frame *N−1*: `iw12` latches → `iw98` publishes+relatches → `iw231` (ROOM REVERB 1
offset 31 = READ) publishes+relatches → `iw251` (offset 51 = WRITE) publishes and does **not**
relatch. So line 0x01 enters frame *N* **empty**, `iw12` publishes nothing, and `m_dr` at `iw25`
is the residue of the **last publish of frame *N−1***, which is the frame's last delay word
`iw269` (offset 69 = WRITE, line 0x2D) publishing `iw247`'s read (offset 47 = READ, line 0x2D).

> **P1 (arm A):** the dominant provenance at `iw25` is **`iw247`**, a **unit-1** delay read, with
> **age = 1 frame**. `iw12` holds **< 1 %** of the mass.
>
> **P1 fails** if the dominant producer is `iw12`, or if the age is 0, or if the dominant producer
> is a unit-0 word. Any of those means this trace is wrong and §217 must say so.

### P2 — where `iw12`'s datum is published

> **P2:** ≥ 95 % of the publishes carrying an `iw12` tag fire at **`iw98`**. Fails if any other
> `iw` dominates.

## 4. THE ARMS

| arm | gates | purpose |
|---|---|---|
| **A** | `UPD6383_DRPUB=0 UPD6383_SRC0B2=0` | control = the shipped build. Scores N1–N3, P1, P2 |
| **B** | `UPD6383_DRPUB=1 UPD6383_SRC0B2=0` | the mechanism test. Scores F1, N4 |
| **C** | `UPD6383_DRPUB=1 UPD6383_SRC0B2=1` | the **value** test, against §215 arm B which is the same but `DRPUB=0` |

`UPD6383_DRPUB` (**new, env, DEFAULT OFF, fired count**): a delay READ *also* writes the bus
register `m_dr` immediately, in addition to its per-line latch. It runs **after** `exec_alu`, so a
fused read+capture word still does **not** see its own datum — `dram-datapath.md` item A survives.
The per-line publish still overrides at every delay word, so the `§79` pairing is untouched.

### F1 — the falsifier for arm B, and the only one that grades identity

> **F1:** with `DRPUB=1`, the provenance at `iw25` becomes **`iw12`, age 0 frames**, on ≥ 99 % of
> settled evaluations. Fails if any other `iw` appears, or if the age is non-zero.

### ⚠ F2 is pre-declared UNINFORMATIVE, and that is the point

In the shipped arm the delay line is **empty** — `§215` arm A measured `§46` 24 922 560 reads with
**0** non-zero. So arm B will deliver the **correct** datum and it will be **zero**.

> **F2 (arm B):** `§215 m_dr non-zero at iw25` **stays 0**. This is NOT a failure of F1, and a
> non-zero here would need explaining, not celebrating.

> **F3 (arm C, vs `data/src0b2_B_on_215.log.gz` which is `DRPUB=0` + the same `SRC0B2=1`):** with
> the delay line forced full, `§215 m_dr non-zero at iw25` goes **from 0 to > 0**, and the
> provenance of the non-zero evaluations is **`iw12`**. If it stays 0 even with `DRPUB=1`, then
> `iw12`'s own reads are always zero and the loss is FURTHER UPSTREAM (its address, `cell 0x1041 +
> G`), which is a different and equally publishable answer.

## 5. STANDING RULE 1 — the trap, applied in advance

In **every** arm I will read `§70 ACCA AT w73` and `§211 ACCB AT w78`, compare **min against max**
in the loud bucket **and** in the no-stimulus (quiet) window.

> **Pre-registered expectation: `min == max == 0` in all three arms, both buckets.** `§216` proved
> the output stage is a null independent of the send; nothing in §217 touches the output stage.
> **No audio claim will be made, and any non-zero `w73`/`w78` would be a REGRESSION to explain,
> not a result.**

## 6. WHAT WOULD MAKE ME SHIP `DRPUB`, AND WHAT WOULD NOT

**NOT sufficient:** any counter becoming non-zero.
**Necessary:** F1 passes on provenance *and* N4 shows `§80` untouched *and* the corpus supports a
read putting its datum on the bus with a latency short enough to reach `iw25` (13 slots).

`dram-datapath.md` item A bounds the landing at **1–4 slots**, which is *shorter* than 13 — so an
immediate publish is not obviously the hardware's schedule either. **Default OFF is the expected
outcome; the deliverable is the located defect, not the gate.**
