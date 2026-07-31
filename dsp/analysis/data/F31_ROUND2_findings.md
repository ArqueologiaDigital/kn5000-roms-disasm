# `f31 = hi12[3:1] > 2` — ROUND 2: what the device does today, and the criterion that would grade a decode

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Date: **2026-07-31**.
No hardware. Offline, read-only: static analysis of the ROM corpus plus a
line-by-line reading of the **current** MAME device source. **Nothing was built
and nothing was run.**

Owning notes read first, per rule ★: [`data/F31_HIGH_findings.md`](F31_HIGH_findings.md),
[`../f31-high.md`](../f31-high.md), [`../SPECULATIVE-APPLIED-REGISTER.md`](../SPECULATIVE-APPLIED-REGISTER.md)
§139/§140/**§193/§194/§195**/§201/§202, [`../LEDGER.md`](../LEDGER.md),
[`../adjudication-round8.md`](../adjudication-round8.md), [`../lfo-ramp.md`](../lfo-ramp.md),
[`typewalk/TYPE_MAP.md`](typewalk/TYPE_MAP.md).

Tool (new, this pass): [`../../tools/f31r2_downstream.py`](../../tools/f31r2_downstream.py)
— `sites | walk | ctx | dram | coef | free | null`.

Grades: **MEASURED** / **FORCED** / **INFERRED** / **SPECULATIVE**.

> ⚠ **SOURCE SNAPSHOT.** Another worker holds the build/run lane and
> `src/devices/cpu/upd6383/` was **dirty and moving** while this was written
> (line numbers shifted by 15 between two reads in the same session). Everything
> in §2 was read from
> `kn7000_mame` @ **`62a658a`** + uncommitted changes,
> `upd6383.cpp` **md5 `6fc2c575d9f90361e5ac2adebcf45912`**,
> `upd6383.h` **md5 `377ad2a535d11491c6238952335e1a85`**.
> Re-verify before acting on §2.

---

## 0. What this pass may and may not conclude

The task named one route as **CLOSED** and it is not reopened here. §194 killed
the two-way PEQ+CHORUS / PEQ+FLANGER comparison on its own input control (the
programs diverge at `+2`, 1013 vs 50 changes, *upstream* of the bit). §195 killed
the three-way repair because the two `f31 = 4` programs agree at `+2` as well, so
bit identity is confounded with program similarity. The generalisation binds:

> **An instruction-stream minimal pair bounds what a field can ENCODE. It does
> not yield a controlled MEASUREMENT, because neither the machine state entering
> the window nor the overall similarity of the host programs is part of the pair.**

**No minimal-pair comparison between whole programs is proposed below.** The
substitute instrument class is named in §1 and it is *within-program*: hold the
program, the stimulus and the machine fixed and vary **the device's reading of
the field**. That design has neither confound by construction — the two arms are
the same program, so program similarity is identity, and the machines are
bit-identical up to the first `f31 = 4` retirement, so the entering state is
identity too.

---

## 1. ★★ THE GRADING CRITERION, NAMED BEFORE ANY CANDIDATE

Per the brief's rule: *name the criterion that would GRADE any proposed decode
before proposing it.*

**A reading `R` of `f31 = 4` is graded if and only if there exists a quantity `Q`
such that all three hold:**

| | requirement | why it is not automatic |
|---|---|---|
| **C-i** | `Q` is fixed **outside the emulator** — a ROM constant, a designed spec, a named UI parameter with units, or Felipe's hardware | otherwise the emulator is grading itself; §140 S5 is the project's own example of a circular grade |
| **C-ii** | `Q` **depends** on `f31 = 4`'s arithmetic — the difference reaches a consumer that is itself read back, with no `f31 = 0` barrier in between | `f31-high.md` items E/G: *observable* is necessary, not sufficient; a store nobody reads back observes nothing |
| **C-iii** | the machine **can compute `Q` today** — every datapath between the site and `Q` is implemented, and the stimulus can drive `Q` off its null | the failure mode §139 §5 / `F31_HIGH` E0 names: a strictly-positive stimulus makes a rectifier invisible, so its criterion cannot fail |

Two corollaries that are used as filters throughout:

* **A criterion that only *distinguishes* readings is not a grade.** A
  within-program A/B proves the site is *observable*; it says nothing about which
  reading is right. Observability is a **prerequisite** to be measured, not a
  result.
* **The NULL must be computed before the number.** Each experiment below states
  what the instrument returns if `f31 = 4` is inert, and each returns something
  different in that case.

**The verdict of applying C-i/C-ii/C-iii to all 98 corpus sites is §6: no `Q`
survives all three today.** §7 gives the one instrument that would change that.

---

## 2. WHAT THE DEVICE DOES WITH `f31` = 4 AND 5 **TODAY** (MEASURED from source)

Read from the snapshot named above, not from any note.

### 2.1 The decode gate refuses them; the speculative catch-all executes them

`upd6383d.h::alu_decoded()` ends:

```c++
    switch (hi_f31(hi12(w))) {
    case HI_ACC_LOAD: case HI_ACC_ADD: return true;
    case HI_ACC_HOLD: return cl == 8;
    default:          return false;         // 3,4,5,6,7 REFUSED
    }
```

so `f31 > 2` is **never** decoded. But `alu_decoded_speculative()` ends in a bare
`return true` ("ROUND 2 (2026-07-28): the grid is now filled COMPLETELY"), and
`m_speculative` is on in the shipped configuration, so every `f31 = 4/5` word
**executes**.

### 2.2 ★★★ The shipped default runs `f31 = 4` as **LOAD** and `f31 = 5` as **ADD**

`upd6383.cpp::exec_alu()`:

```c++
    const bool sel = m_speculative && (m_specmask & 1);
    u16 op = sel ? u16(f31 & 3) : f31;
    if (sel && f31 == 4) { m_bx_f4_n++; if (m_bx_f4) op = bx_f31_op(m_bx_f4); }
    if (sel && f31 == 5) { m_bx_f5_n++; if (m_bx_f5) op = bx_f31_op(m_bx_f5); }
```

with `m_bx_f4 = (m_specmask >> 48) & 3`, `m_bx_f5 = (m_specmask >> 50) & 3` and
`bx_f31_op(r) = r==1 ? LOAD : r==2 ? ADD : HOLD` (reading 0 = "keep the alias").

The shipped default is `upd6383.h:911` **`m_specmask = 0xb910e446a39b440f`**.
Nibble 12 (bits 48..51) is **`0`**, so `m_bx_f4 = m_bx_f5 = 0`; bit 0 is **set**,
so `sel` is true. Therefore, **today**:

```
   f31 = 4  ->  op = 4 & 3 = 0  =  LOAD,  acc <- P            (aliased to f31 = 0)
   f31 = 5  ->  op = 5 & 3 = 1  =  ADD,   acc <- acc + P      (aliased to f31 = 1)
   f31 = 3  ->  op = 3          -> p_term = 0, src = acc      (HOLD)
   f31 = 6  ->  op = 2          =  HOLD
   f31 = 7  ->  op = 3          -> HOLD
```

★ This is exactly the standing breach §133 flagged, and it is **still shipped**.
The alias is *silent*: any A/B about `f31 = 4` must be run against **LOAD**, not
against a trap. **MEASURED.**

### 2.3 ⛔ The fired-counts exist and are **DEAD**

`m_bx_f4_n` and `m_bx_f5_n` appear in exactly three places in the whole device:
the declaration (`upd6383.h:597`) and the two `++` above. **They are never
printed, never saved, never read.** The project's own rule — *"Every gate must log
one: it is what distinguishes a real null arm from a gate that silently never
ran"* (`upd6383.h`, §130) — is breached for precisely this field. **FORCED.**

⇒ Any experiment in §7 needs a one-line `logerror` in the other worker's lane
before it can be believed. §7.0 states it as a prerequisite, not a result.

### 2.4 The accumulator bus is latched **before** the ALU, so a `+1` capture is real

`LO_SRC_ACC` sets `L = acc_to_datum(...)` at ~line 2484; the accumulator update
block is at ~line 2794; the `ACT 0x07` (`mem[ptr] <- bus`) side effect is at
~3182. ⇒ a word at `+1` whose SRC is the accumulator captures the **pre-update**
value, i.e. **the `f31 = 4` result**. This is what makes §4.3's nine sites live.
**FORCED by statement order.**

### 2.5 ⛔ Two datapaths that the notes assume exist, and the source says do not

| assumed by | source says | consequence |
|---|---|---|
| `F31_HIGH` §8 **E1** — the 24-entry LFO table index | `upd6383.cpp` class-6 branch ends `// table-lookup idiom: no table is modelled, so execute the addressing and leave the ALU alone.` — it advances the cursor and `return`s | **E1's vehicle does not exist.** No index is ever used to read anything; the `[0,23]` validity constraint has nothing to bite on inside the emulator |
| the delay-domain hope (§201/§202) | the delay address is `(descriptor_cell + rot + tapmod) & 0xffff`; the accumulator enters only on `dir == 'W'` | see §4.4 — **no `f31 = 4/5` result ever reaches a delay WRITE** |

**MEASURED, both.**

### 2.6 The A/B arms that already exist, with no rebuild

Because bits 48..51 are already allocated to this exact question:

| arm | `UPD6383_SPEC` | `f31=4` | `f31=5` |
|---|---|---|---|
| **D** shipped default | `b910e446a39b440f` | LOAD | ADD |
| **D′** ★ identity twin | `b919e446a39b440f` | LOAD | ADD |
| f4 → ADD | `b912e446a39b440f` | ADD | ADD |
| **H** both → HOLD | `b91fe446a39b440f` | HOLD | HOLD |
| both → HOLD, other route | `b910e446a39b440e` (clear bit 0) | HOLD | HOLD |

★ **D′ must be bit-identical to D** (`bx_f31_op(1) = LOAD`, `bx_f31_op(2) = ADD`).
That is a free, pre-registered identity control that **can fail**. Note also that,
with mask bit 14 set (it is), `sel` no longer selects an accumulator — so bit 0 is
now *nothing but* the `f31 = 4/5` alias switch.

⚠ The reading space the gate can express is **{LOAD, ADD, HOLD} only**. It cannot
express rectify, saturate, shift or negate. See §5.

---

## 3. THE NULL, COMPUTED FIRST

**NULL:** `f31 = 4/5` is an inert alias of `0/1`; the designer's choice of which
code to emit is arbitrary and independent of what the program computes; therefore
every program carries its population share of `f31 ∈ {4,5}` words.

`python3 dsp/tools/f31r2_downstream.py null` — over the IC311 population (38 body
images, 2566 plain body words), 97 body words carry `f31 ∈ {4,5}`.

| partition | K/N | expected `k` | observed `k` | one-sided p |
|---|---|---|---|---|
| ⛔ **[A]** §140 S2's LINEAR list | 944 / 2566 = 36.8 % | 35.7 | **0** | `P[X ≤ 0] = 1.6e-20` |
| ★ **[B]** *needs a magnitude stage*, a-priori from the effect NAME | 964 / 2566 = 37.6 % | 36.4 | **69** | `P[X ≥ 69] = 8.4e-12` |

⛔ **[A] IS CIRCULAR AND IS NOT EVIDENCE.** §140 S2 *derived* that list as "the
images with zero `f31 ≥ 3`" and only then observed they are all linear. Scoring
`f31` against it is scoring a set against its own definition. `F31_HIGH` §6 quoted
S2's 14/14 without flagging this; **flagged here.**

★ **[B] is admissible.** The set is fourteen programs chosen from the effect
*name* alone, by what the named effect requires in audio engineering —
DISTORTION / OVERDRIVE / FUZZ (saturating shaper), EXCITER / ENHANCER (harmonic
generator), COMPRESSOR / AUTO WAH / GATED REVERB and the four PEQ+COMPR combis
and the two PEQ+dist+DELAY combis (envelope follower). No `f31` count entered the
choice. RING MODULATOR, PARAMETRIC EQ, PHASER, AUTO PAN and ROCK ROTARY are
deliberately **outside** it, and they are exactly the programs that make [A]'s
converse fail.

**Result: 69 of 97 against 36.4 expected, `p = 8.4e-12`. MEASURED.**

⇒ **The NULL is refuted.** `f31 = 4/5` is placed where a magnitude/limit stage is
needed, far beyond chance, on a partition fixed before the count. This does **not**
name the operation; it rules out "inert alias", independently of §4.3's
exchangeability argument in `F31_HIGH`, which reached the same conclusion by a
different route.

---

## 4. NEW MEASURED CORPUS FACTS

### 4.1 ★★★ 46 % of the `f31 = 4/5` population is **OPERAND-FREE**

`f31r2_downstream.py free`. A word with `class 2` (no cursor coefficient fetch),
`addr8 = 0x00` (pointer moves by zero), `lo12 = 0x000` (SRC `0x00`, ACT `0x00`, no
pointer mode) and `hi12` bits 4 and 7 clear has **no memory operand, no
destination, no store and no pointer movement**. The whole word is its opcode.

The entire operand-free family in the IC311 machine — 243 of 2619 plain words:

```
   hi12  f31  count            hi12  f31  count           hi12  f31  count
   000    0     62             026    3     18 ★          102    1     35
   020    0      2             028    4     17 ★          104    2     23
   022    1     14             02A    5     28 ★          202    1     18
   024    2      2             02E    7     11 ★          204    2     13
```

* `f31 ∈ {4,5}` words that are operand-free: **45 of 98 (45.9 %)**, against a
  9.3 % base rate over all plain words.
* Inside the family, `f31 > 2` occurs **only** at `hi12` bit 5 = 1 **and**
  `f98 = 0` — 74 of 74, exceptionless.
* `020 / 022 / 024 / 026 / 028 / 02A / 02E` is `F31_HIGH` §4.4's *seven-of-eight
  values* context. **This pass names what that context is**: it is the
  operand-free family.

★★ **The consequence, and it reframes the whole question.** For `f31 = 0/1/2`
these words are already decoded, and on an operand-free word their decoded
meanings are exactly **the three product-writeback modes of a MAC pipeline**:

```
   000/020.2.00.000  f31 = 0   acc <- P            commit the pending product
   022/102/202       f31 = 1   acc <- acc + P      accumulate it
   024/104/204       f31 = 2   acc <- acc          hold; discard it
```

⇒ **`hi12[3:1]` on an operand-free word is the PRODUCT-WRITEBACK MODE, and
`f31 = 3,4,5,7` are four more writeback modes in the same slot.** That is
**INFERRED** — forced for 0/1/2 (they are decoded), extended to 3/4/5/7 by the
byte-identity of the host word.

⇒ And it makes the existing gate **categorically wrong for 46 % of the
population**: `{LOAD, ADD, HOLD}` are three of the eight modes, so
`bx_f31_op()` can only ever map one undecoded mode onto another decoded one. It
cannot express a fourth mode at all.

### 4.2 The honest decidability census (supersedes `f31-high.md` item F for this field)

`f31r2_downstream.py walk`, over all 98 plain `f31 ∈ {4,5}` words, with the
accumulator model mirrored from the current device (including the class-5/6 and
`word == 0` early returns, and `is_dram`'s re-entrant ALU):

| outcome | count |
|---|---|
| **BLIND** — an `f31 = 0` barrier destroys the result before any consumer | **69** |
| reaches a delay word only, and that word has SRC `0x00` / ACT `0x00` (inert) | **6** |
| reaches a word that **reads the accumulator onto the bus** | **15** |
| reaches a **bit-4 store** first | **8** |

⇒ **75 of 98 are blind; 23 carry a difference to a consumer.** `f31 = 4` words
that terminate an image (`428.1.0E.000`, 12 of 38 images) are all blind — they are
the last word, there is nothing after them.

### 4.3 ★★ THE NINE-SITE CAPTURE — a `+1` observable in eleven programs

Nine sites put an operand-free `f31 = 4/5` word **immediately before**
`880.1.30.407`, whose SRC is `0x10` (the accumulator) and ACT is `0x07`
(`mem[ptr] <- bus`). Per §2.4 the bus is latched before the ALU, so that word
**writes the `f31` result to memory one word later**:

```
   DISTORTION w18   OVERDRIVE w29   FUZZ w18   EXCITER w33   COMPRESSOR w0
   COMPRESSOR w18   PARAMETRIC EQ w50   RING MODULATOR w8   PEQ+COMPRESSOR w27
```

and the idiom is the same at all of them:

```
     w-2  000.2.±N.40E   SRC 0x10 (acc)  ACT 0x0E        p -= N
     w-1  212.2.∓N.000   f31 = 1, bit-4 STORE            p += N
  ** w+0  028.2.00.000   f31 = 4  <-- operand-free
     w+1  880.1.30.407   SRC 0x10 (acc)  ACT 0x07        stores the result
```

★ The `±N` pairs are exact complements — DISTORTION `F0/10` (∓16), OVERDRIVE
`42/BE` (±66), FUZZ `7D/83` (±125), EXCITER `03/FD` (±3) — a net-zero pointer
excursion, i.e. a per-program state cell at a fixed offset. **MEASURED.**

⚠ This is *more* than `F31_HIGH` §5A's pair A had (nine sites vs two) and it is
**not** a program comparison — it is a single site inside a single program. It is
the natural vehicle for the within-program A/B of §7.1. It is **still not a
grade**: nothing outside the emulator says what that cell should contain.

### 4.4 ⛔ THE DELAY DOMAIN IS CLOSED — measured, not argued

The task asked whether any `f31 = 4/5` word sits in the domain §201/§202 just made
measurable. `f31r2_downstream.py dram`:

* **15 of 98** sites reach a delay word before a barrier — and **all 15 reach
  `addr8 = 0x30`, which `dram_dir()` FORCES to be a READ.**
* **0 of 98** reach a delay **WRITE** (`addr8 = 0x60`) before a barrier. The
  accumulator enters the delay line only in the `dir == 'W'` branch.
* The anchored quantity §201/§202 delivered is the **tap length**, computed as
  `(descriptor_cell + rot) & 0xffff`. The accumulator is not a term in it.

⇒ **FORCED: no reading of `f31 = 4` or `f31 = 5` can move any quantity that
§201/§202 anchored.** The recent delay work is real and it does not help here.
This closes the route the brief asked to consider, and it closes it by
measurement rather than by argument.

### 4.5 The one ROM constant attached to the field, re-verified

`f31r2_downstream.py coef`. Of the `f31 = 4/5` words that name a C-RAM cell
directly, the recurring constant is **`0x517CC1 = floor(2/π · 2²³)`** — at
`018.A.00.1D5` (`f31 = 4`, the 12-site level-detector idiom), at
`09A.A.00.200` (`f31 = 5`, the COMPRESSOR envelope step) and at one
`028.2.00.000`. `2/π` is the mean of `|sin|`, i.e. a **peak↔mean-rectified
calibration constant**. Already in the notes (§139 §3, `lfo-ramp.md`); re-verified
on the IC311 basis. **MEASURED.**

⇒ It says **the chain rectifies**. It does not say **which word** rectifies —
the ROM cannot distinguish `f31 = 4` from `ACT 0x15` from the multiplier's own
sign handling. **This is the ceiling of ROM-only evidence and it is why §6 says
what it says.**

---

## 5. CANDIDATE MEANINGS, GRADED AGAINST §1

`F31_HIGH` §7 ranked five candidates and marked all SPECULATIVE. The rankings are
not re-litigated; what is added is **the C-i/C-ii/C-iii verdict for each**, plus
one candidate the earlier list does not contain, admitted only because §4.1
changed the *shape* of the question (writeback mode, not modifier-over-a-base) —
not because it fits a datum.

| # | reading of `f31 = 4/5` | expressible by today's gate? | C-i anchor | verdict |
|---|---|---|---|---|
| 1 | **RECTIFY** `acc ← \|P\|` / `\|acc\|` (§140 S3) | ⛔ **no** | ★ the compressor's ATTACK/RELEASE seconds (§147) + `2/π` | **UNDECIDABLE today** — C-iii fails: the stimulus never changes sign (§7.0) |
| 2 | **SATURATE / limit** | ⛔ no | none | **UNDECIDABLE** — C-i fails outright; no ROM number, no spec, no UI parameter fixes a clip point |
| **1b** | ★ **PEAK-HOLD** `acc ← max(acc, P)` (new; see §8) | ⛔ no | same as 1 | **UNDECIDABLE today**, same reason |
| 3 | **SHIFT / rescale** ×2 or ÷2 | ⛔ no | was the 24-entry index; **gone** (§2.5) | **UNDECIDABLE** — C-iii fails: the table is not modelled |
| 4 | **NEGATE** `acc ← −P` | ⛔ no | none | **UNDECIDABLE**; and already weak (subtraction is reachable via ACT/SRC) |
| 5 | `acc ← bus`, product bypassed | partially (≈ HOLD) | none | **UNDECIDABLE** |
| L/A/H | **alias of LOAD / ADD / HOLD** | ✔ yes | — | ★ **the only family the existing instrument can A/B**, and refuted as a *family* by §3 (`p = 8.4e-12`) though not member-by-member |
| — | selects a second accumulator (ACCB) | — | — | ⛔ **REFUTED**, do not re-test (§27→§32→§139 §2; and mask bit 14 now selects the accumulator by *unit*) |

★★ **The table's diagonal is the finding.** The one family the shipped gate can
test is the one family the corpus statistics already argue against; every family
the corpus argues *for* is inexpressible. **That mismatch, not any single
candidate, is the execution blocker.**

---

## 6. ⛔⛔ THE EXPLICIT UNDECIDABILITY STATEMENT

Applying §1's three requirements to all 98 sites:

* **C-ii fails for 75 of 98** — blind, or the only consumer is inert (§4.2).
* **C-i fails for all 15 delay-adjacent sites** — the anchored delay quantity is
  address-derived and the accumulator is not a term in it (§4.4). **MEASURED.**
* **C-iii fails for the 2 LFO-index sites** (`PEQ+FLANGER w41`, `PEQ+VIBRATO w34`)
  — the class-6 lookup is explicitly not modelled, so no index exists to be out of
  `[0,23]` (§2.5). **This retires `F31_HIGH` §8 E1 as written.** MEASURED.
* **C-i fails for the 9-site `+1` capture** (§4.3) — nothing outside the emulator
  fixes what that cell should contain.
* **C-i holds for the COMPRESSOR envelope sites** — the ROM's one-pole
  coefficients `0.004812 = 4.712 ms` and `0.001927 = 11.764 ms` are consumed in
  the order the upload script at `0x84CD` writes them and are named
  **ATTACK SENS.(s) / RELEASE SENS.(s)** in the instrument's own UI (§147). **But
  C-iii fails**: the detector must be driven by a stimulus that changes sign, and
  `bx_stim()` returns `0x010000 + n·0x101` / `0x018000 + n·0x203` — strictly
  positive and monotone. A rectifier is invisible to it. *This is §139 §5 / E0,
  open since 2026-07-30 and still the binding constraint.*

> ### ⛔ **`f31 = 4` and `f31 = 5` are UNDECIDABLE with the instruments that exist today.**
>
> Not "hard". **Undecidable**: for every candidate reading there is a specific
> requirement of §1 that provably fails, and for four of the six candidates the
> failure is **C-i** — no quantity outside the emulator depends on them at all,
> so no amount of emulator work can decide them.
>
> ### ★ The single instrument that changes this
>
> **A sign-alternating stimulus delivered to the COMPRESSOR's level detector,
> plus a read-back of the detector cell.** It is the only site in the machine
> where an outside-the-emulator anchor (named seconds, ROM coefficients, the
> `2/π` calibration) meets a live consumer. Everything else is either blind,
> unanchored, or unimplemented.
>
> ### ★★ And the instrument that outranks it
>
> **Felipe.** Per the standing rule his testimony is ground truth. Two questions
> (§7.4) settle the *family* — rectifier present or absent — without any
> emulator run at all, and the family is what §5's table cannot reach.

---

## 7. THE RANKED EXPERIMENTS

Each is stated with its NULL, a **two-sided** criterion, and pre-registered
numbers. ⚠ **Every one requires §7.0 first.**

### 7.0 PREREQUISITES — three small changes, all in the other worker's lane

| # | change | why it is a prerequisite, not a nicety |
|---|---|---|
| **P1** | print `m_bx_f4_n` / `m_bx_f5_n` in the frame report | §2.3: the counters are dead. Without them an arm that never fires is indistinguishable from an arm that fires and does nothing — §193's exact failure |
| **P2** | make `sprobe_idx()`'s `static const u16 SLOTS[]` settable from the environment (`UPD6383_SPROBE="103,104,…"`) | the store probe is the only instrument that reports *which cell, which path, which value*; its slot list is hard-coded to kernel/CHORUS slots and cannot reach a selected effect's body |
| **P3** ★ | make `bx_stim()` alternate sign (or drive real audio with `note_spec.lua`) | **E0.** Without it every rectify-family criterion cannot fail, and a criterion that cannot fail is not a test |

⚠ The u64 mask is exhausted, so P2/P3 must be env gates with fired-counts —
**except** that the `f31` readings themselves need no new gate at all: bits 48..51
are already allocated to this question and are currently zero (§2.6).

### 7.1 ★ X0 — THE IDENTITY CONTROL (free, no rebuild, runs today)

* **Arms.** `UPD6383_SPEC=b910e446a39b440f` (D) vs `b919e446a39b440f` (D′).
* **Pre-registered.** D′ sets `m_bx_f4 = 1` → `bx_f31_op(1) = LOAD` and
  `m_bx_f5 = 2` → `bx_f31_op(2) = ADD`, which is what D already does. **Every
  reported statistic must be bit-identical.**
* **Falsifier.** Any difference ⇒ the gate is not what the source says and every
  arm below is void. **It can fail.**
* Cost: two runs. Run this before X1.

### 7.2 ★★ X1 — THE OBSERVABILITY MEASUREMENT (the best experiment runnable soon)

This is **not** a decode. It measures whether the 23 non-blind sites are
observable *at all* under a controlled substitution — the thing §194/§195 never
established, and the thing that decides whether any decoding experiment is worth
building.

* **Vehicle.** **DISTORTION**, `w18` = `028.2.00.000` (`f31 = 4`), body 0. Reached
  with `tools/type_select.lua`, `TYPELAST=36`; `TYPE_MAP.md` maps it to index 9,
  but the map is off by one above index 8 — so **sweep the ask index and accept
  only the run whose 16-word upload fingerprint is `prog32_distortion`**
  (§193's standing requirement; a 4-word prefix collides with FUZZ).
* **Arms.** D (`f31 = 4` → LOAD) vs **H** = `b91fe446a39b440f` (`f31 = 4/5` → HOLD).
* **Observable.** The value stored by I-RAM slot **103** (= 84 + 19), the
  `880.1.30.407` capture of §4.3, via the §109 store probe (needs **P2**).
* **NULL.** If the `f31 = 4` word is inert in this machine — e.g. because
  `028.2.00.000` fetches **no coefficient** (`coeff_fetch = class4 & 8`; class 2
  ⇒ false, so `P` is a **stale** product) and SRC `0x00` returns zero — then LOAD
  and HOLD write the same value and the two arms are byte-identical.
* **Pre-registered numbers.**
  * fired-counts, kernel + DISTORTION(body 0) + ROOM REVERB 1(body 1):
    **`m_bx_f4_n / frame = 2.000`** (DISTORTION `w18`, `w39`) and
    **`m_bx_f5_n / frame = 1.000`** (kernel `w30`). ★ Anything else means the
    program did not load or the counter is wrong — and note that at **cold boot**
    the correct answer is `f4 = 0.000`, `f5 = 1.000`, because CHORUS and ROOM
    REVERB 1 carry no `f31 = 4/5` word at all.
  * slot 103's `st_lo`/`st_hi` range: **differs** between D and H ⇒ site is
    OBSERVABLE; **identical** ⇒ site is INERT.
* **Two-sided, and both outcomes are worth having.** *Different* ⇒ build X2.
  *Identical* ⇒ the 9-site capture joins the blind set, **75 of 98 becomes 84 of
  98**, and §6's undecidability is promoted from argued to measured.
* ⛔ **What X1 does NOT do.** It cannot say which reading is right. Reporting it
  as a decode would repeat §194/§195's error in a new costume.

### 7.3 ★★★ X2 — THE DECIDING EXPERIMENT: the COMPRESSOR level detector

The only site where C-i, C-ii and C-iii can *all* be satisfied — once **P3** lands.

* **Vehicle.** **COMPRESSOR** (`TYPE_MAP` index 13; verify by 16-word fingerprint
  `prog36_compressor`). The idiom, verified byte-exact this pass:

```
     w2   026.2.F3.000   f31 = 3                        p -= 13
  ** w3   018.A.00.1D5   f31 = 4, bit-4 STORE   x C-RAM = 0x517CC1 = 2/pi
     w4   104.A.00.1D5   f31 = 2                x C-RAM = 0x400000 = 0.5
     w5   C40.2.C0.000   immediate
     w6   182.A.00.000   f31 = 1   <- the ONE-POLE SMOOTHER, ROM coefficients
     w7   0A6.2.0D.447   ACT 0x07: stores to mem[ptr]   p += 13
```

  `w3`'s difference reaches a store at `+6` with the barrier at `+7` (§4.2), i.e.
  **inside the window**, and `w6`'s coefficients are the named ATTACK/RELEASE
  seconds.
* **Stimulus.** A sustained note (`note_spec.lua`), or **P3**'s sign-alternating
  injection. Two runs: input, and input with **inverted polarity**.
* **★ THE CRITERION — EVEN vs ODD, model-free.** Let `E` be the cell `w7` writes,
  measured after ≥ 5 release time constants (11.764 ms ⇒ ~520 frames at 44.1 kHz;
  ⚠ the emulated frame rate is **48 000**, not 44 100 — §132):

  | reading family | `E` under polarity inversion | `mean(E)` over one input period |
  |---|---|---|
  | **rectifying** (rectify, peak-hold, saturate-of-magnitude) | **unchanged**, `\|ΔE\|/E < 1 %` | `> 0`, and `≈ (2/π)·0.5·A = 0.3183·A` |
  | **non-rectifying** (LOAD, ADD, HOLD, negate, shift) | **sign-flipped**, `ΔE ≈ −2E` | `≈ 0`, `\|mean\| < 5 %` of peak-to-peak |

  Even-vs-odd needs no absolute calibration, no gain model and no assumption about
  where the sample enters — which is why it is preferred over comparing `E`
  against `0.3183·A`.
* **NULL / VOID condition (rule 13, §137).** If `min(E) == max(E)` the detector is
  not being fed and **nothing may be concluded** — report the null and stop. A
  difference from silence is not a signal.
* **★ THE PRE-FLIGHT THAT CAN FAIL, run before building anything.** The cell `w7`
  writes must already appear in §86's list of cells whose *quiet* and *loud*
  ranges differ. §86 currently reports **only `0x06` and `0x07`**. If the
  compressor's envelope cell is not input-dependent, **X2 is dead before it
  starts** and P3 is wasted effort. This costs one existing report and no code.
* **Why not kernel `w30`.** `09A.A.00.200` is §140 S5's proposal; `F31_HIGH` §5B
  showed it is **circular** (its only channel is a store whose gate needs `f31 = 5`
  decoded first) and §4.2 measures it **BLIND** (barrier at `+2`). ⛔ Do not run.

### 7.4 ★★★ X3 — ASK FELIPE (highest value per unit of work; no emulator at all)

Felipe's hardware testimony is ground truth and outranks every inference here.
Two questions, both answerable in a minute on the real KN5000, both of which
decide the **family** that §5's table cannot reach:

1. **Select COMPRESSOR and play a sustained loud chord, then a quiet one. Does the
   level audibly duck and recover — and does it duck *smoothly*, or does it
   "pump"/buzz at the pitch of the note?**
   *Smooth ducking* ⇒ the detector rectifies ⇒ a magnitude operation exists in a
   machine whose ACT field has no code for one ⇒ `f31` is where it lives.
   *No ducking, or buzzing at the note's pitch* ⇒ the detector is not rectifying,
   and candidates 1/1b/2 lose their motivation together.
2. **Select AUTO WAH and play soft then hard. Does the filter sweep follow how
   hard you play?** Same logic, independent program — AUTO WAH carries four
   `f31 = 5` words and no `f31 = 4` in the detector idiom.

⚠ Pre-register the interpretation **before** asking, and record that a *negative*
answer is as informative as a positive one — otherwise this is not a test either.

### 7.5 ⛔ SAVED RUNS — do NOT build these

| | why |
|---|---|
| **`F31_HIGH` §8 E1**, the 24-entry index | §2.5: `// no table is modelled`. The vehicle does not exist. A saved run in the same spirit as §139's saving of AUTO PAN |
| **any delay-domain test** | §4.4: 0 of 98 sites reach a delay WRITE; the anchored quantity is address-derived |
| **kernel `w30`** (§140 S5) | circular (`F31_HIGH` §5B) **and** measured BLIND here |
| **PARAMETRIC EQ's biquad** | `f31-high.md` item E, PROVEN BY CONSTRUCTION blind |
| **any two-program minimal-pair comparison** | §194/§195, closed |

---

## 8. SPECULATION (kept out of the findings above)

⚠ Everything here is **SPECULATIVE**. It is written down because §4.1 changed the
*shape* of the question, not because it fits any datum — and `F31_HIGH` §7's own
falsifier ("do not add a sixth reading to fit the data") is respected: E1, the
experiment that falsifier governed, was never run and now cannot be, so no datum
is being fitted.

**S1. The reading space should be product-WRITEBACK modes, not
modifier-over-a-base.** §4.1 shows the operand-free family is exactly a MAC
writeback slot carrying `{acc←P, acc←acc+P, acc←acc}` at `f31 = 0/1/2`. The
natural remaining modes in a fixed-point DSP writeback are `acc ← acc − P`,
`acc ← |P|`, `acc ← max(acc, P)`, `acc ← sat(acc)`, `acc ← acc >> 1`. `F31_HIGH`
§7's frame — "bit 3 is a modifier applied to the base named by `hi12[2:1]`" — and
this frame make the same predictions for 4/5/6 and different ones for 3 and 7,
which is where `f31-high.md` item C's `chi2 = 150` anomaly lives.

**S2. `acc ← max(acc, P)` (peak-hold) is the candidate the earlier list is
missing.** It is the one writeback mode an envelope follower cannot be built
without; it is unary in the same sense as rectify; it explains why the codes
cluster in the fourteen magnitude-stage programs (§3, `p = 8.4e-12`); and it
coexists with `2/π` (peak-hold feeding a `2/π` peak→mean calibration is the
textbook detector). Against it: `f31 = 4` is `F31_HIGH` §4.3's *most exchangeable*
value, which suits a modifier better than a distinct mode.

**S3. The `026`/`02E` (`f31 = 3/7`) words that bracket the `f31 = 4/5` words might
be the other half of a two-word conditional.** `|x|` in a machine with no branch
is classically "compute `x`; compute `−x`; select on sign". Operand-free `f31 = 3`
and `f31 = 7` words sit immediately before and after the `f31 = 4/5` words in
COMPRESSOR (`w2`/`w3`) and in the waveshapers (`w18`/`w22`). **No evidence.
Recorded so it is not re-derived as if new.**

**S4. `2/π` says the CHAIN rectifies, and that may be all the ROM can ever say.**
§4.5. If Felipe's answer to X3 is "yes it compresses", the rectifier exists; the
ISA has no ACT code for one (`F31_HIGH` §7); `f31` is then the only field left —
an *elimination* argument, weaker than a measurement, but the only route that
reaches ground truth without P3.

---

## 9. EVIDENCE GRADES

| section | grade |
|---|---|
| §2.1–§2.4 what the device does today; the alias; the dead counters; bus-before-ALU | **MEASURED / FORCED** from the named source snapshot |
| §2.5 the class-6 table is not modelled; E1's vehicle does not exist | **MEASURED** |
| §3 the a-priori null, 69/97 vs 36.4, `p = 8.4e-12`; and [A] is circular | **MEASURED**; the circularity **FORCED** |
| §4.1 the 243-word operand-free family and its 12 `hi12` values | **MEASURED** |
| §4.1 "operand-free ⇒ product-writeback mode" | **INFERRED** (forced for 0/1/2, extended by byte identity) |
| §4.2 decidability census 75 blind / 23 live | **MEASURED** |
| §4.3 the nine-site `+1` capture and the `±N` pointer excursion | **MEASURED** |
| §4.4 no `f31 = 4/5` result reaches a delay WRITE; the delay anchor is address-derived | **FORCED** |
| §4.5 `0x517CC1 = 2/π` at the detector sites | **MEASURED** (already in the notes) |
| §5 which reading is right | **SPECULATIVE**, none forced |
| §6 undecidability with current instruments | **FORCED** by §1 + §2.5 + §4.2 + §4.4 |
| §7 the experiments | **not run** |
| §8 | **SPECULATIVE**, quarantined |

## 10. WHAT WAS ALREADY IN THE NOTES (rule ★)

* §133 already said `f31 = 4/5` execute silently as `f31 & 3` and demanded a
  reading and a counter. **The reading gate was built; the counter was built and
  never printed.** Recorded, not rediscovered.
* §139 §5 / `F31_HIGH` E0 — the stimulus cannot see a rectifier. **Still true,
  still the binding constraint, still unfixed.** It is P3.
* §140 S3 (bit 2 = rectify), S4 (`f98` and `f31` near-exclusive) — already there.
* `F31_HIGH` §4.3 (`f31` is a genuine field, not aliased), §5A/B/C (the three
  anchored pairs), §5B (S5 is circular) — already there and used as given.
* §147/§148 — the compressor's one-pole coefficients are the UI's
  **ATTACK SENS.(s) / RELEASE SENS.(s)**. Already in the device comments; this
  pass is the first to name them as the **C-i anchor**, which is the whole of §7.3.
* §170 / `TYPE_MAP.md` and §194's off-by-one — already there; used as the
  navigation rule for X1/X2.
* §201/§202 — already there; used to **close** the delay route rather than open it.

**New here:** the current-source audit of what `f31 = 4/5` actually do (the alias
is still shipped, the counters are dead, the class-6 table is not modelled); the
a-priori non-circular null and the circularity of S2's list; the operand-free
family and the writeback-mode reframing; the honest 75/98 blind census; the
nine-site `+1` capture; the measured closure of the delay route; and §1/§6 —
the grading criterion stated first, and the undecidability verdict that follows
from it.

---

## 11. THE SINGLE BEST EXPERIMENT, AND WHETHER ITS CRITERION CAN FAIL

> ### **X2 — the COMPRESSOR level detector, run with a sign-alternating stimulus, scored on whether the detector cell is EVEN or ODD in the input's polarity.**
>
> **Its criterion CAN fail, in three distinct ways, and every one of them is
> pre-registered:**
>
> 1. **The pre-flight fails.** The cell `w7` writes does not appear among the
>    input-dependent cells in §86's quiet/loud report ⇒ the detector is not fed
>    and X2 is abandoned **before** any code is written.
> 2. **The run is VOID.** `min(E) == max(E)` ⇒ no signal, nothing concluded
>    (rule 13: a difference from silence is not a signal).
> 3. **The result is ODD.** `E` flips sign with the input's polarity ⇒ the whole
>    rectifying family — candidates 1, 1b and 2, including §140 S3, the
>    best-supported reading in the project — is **refuted in one trace pair**.
>
> And it can also *succeed*: `E` even, positive, settling at `≈ 0.3183·A` with the
> ROM's own time constant would be the first outside-the-emulator quantity ever
> shown to depend on `hi12[3:1] > 2`.
>
> ⚠ **It cannot be run today.** Its prerequisite is **P3** — `bx_stim()` is
> strictly positive and monotone, so today the criterion cannot fail, and a
> criterion that cannot fail is not a test. That is the same blocker §139 §5
> named on 2026-07-30, and it is the one thing standing between this field and a
> decode.
>
> **Until P3 lands, the honest status of `f31 = 4` and `f31 = 5` is: undecidable
> with the instruments that exist — and the instrument that would change that is
> a stimulus that changes sign.**
