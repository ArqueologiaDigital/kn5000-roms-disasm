# The undecoded corpus is 133 families, and HALF of it is 18 of them (2026-09-13)

**Tools:** `dsp/tools/dsp_coverage.py`, `class2_solve.py` — **Artefacts:**
`data/undecoded_families_2026-09-13.txt`, `data/family_evidence_2026-09-13.txt`.

Instruction coverage is the long pole toward a full LLE: **41.5 % executable** (1 234 of 2 974
words in the 38 body images), **443 distinct undecoded words in 133 families**. That number is
undifferentiated and reads as an open-ended search. It is not.

## 1. The undecoded mass is CONCENTRATED
Counting **occurrences** (what coverage actually buys) rather than distinct words, across the
effect bodies: **1 740 undecoded occurrences in 133 families**, and

> ★ **the 18 largest families are 49.9 % of all of them.**

| family `hi12/cls/lo12` | occurrences | fields |
|---|---|---|
| `212/2/000` | 103 | cls2 ACT00 SRC00 f31=1 |
| `000/2/40E` | 77 | cls2 ACT0E SRC10 f31=0 |
| `104/2/1CE` | 57 | cls2 ACT0E SRC07 f31=2 |
| `012/4/1CE` | 53 | cls4 ACT0E SRC07 f31=1 |
| `000/2/1CD` | 49 | cls2 ACT0D SRC07 f31=0 |
| `092/2/700`, `040/0/C63`, `000/6/4CD`, `104/2/1D5` | 46 each | |
| `102/2/1CD` 43, `102/2/000` 42, `102/A/4C8` 41, `000/2/000` 40, `880/1/2C7` 40, `880/1/000` 38, `A00/0/041` 35, `000/2/447` 34, `182/2/000` 32 | | |

## 2. ★★ 15 of those 18 ALREADY HAVE A MEASURED CANDIDATE
Cross-referencing against `class2_solve.py`'s extracted algebra: **15 of 18 families have a
uniquely-determined accumulator operation**, several on 48–53 programs with full discrimination —
covering **704 of the top-18's 868 occurrences (81 %)**, i.e. **~40 % of the entire undecoded
mass**.

| family | accumulator op | evidence |
|---|---|---|
| `212/2/000`, `102/2/000`, `182/2/000` | `acc + P + L<<16` | 136 rows / **48 programs** |
| `000/2/1CD` | `L<<16` | 63 rows / **53 programs** |
| `102/2/1CD` | `L<<16` | 29 rows / 29 programs |
| `000/2/000` | `P + L<<16` | 54 rows / 29 programs |
| `880/1/2C7` | `P` | 88 rows / 24 programs |
| `A00/0/041` | `hold` | 88 rows / 24 programs |
| `104/2/1CE`, `104/2/1D5`, `040/0/C63`, `000/6/4CD` | `hold` | 8–30 rows / 4–5 programs |
| `012/4/1CE` | `acc + P` | 13 rows / 5 programs |
| `880/1/000` | `P + L<<16` | 11 rows / 8 programs |
| `000/2/447` | `P` | 8 rows / 6 programs |
| **still tied** | `000/2/40E`, `092/2/700`, `102/A/4C8` | the extractor's VACUOUS rows |

## 3. ⛔⛔ WHY THIS IS NOT 40 % OF A DECODE — READ BEFORE USING THE TABLE
Two hard limits, both of which make "promote these and coverage jumps" **wrong**:

1. **The extractor measures the DEVICE, not the chip.** `class2_solve.py` reads `upd6383.cpp`'s own
   `acc` column. Promoting its output into the disassembler would encode **our emulator's
   speculative behaviour as decoded truth** — precisely the circularity the project's rules exist
   to prevent. The **bytecode is the source of truth and the HLE is the oracle**; the extractor is
   neither. Every row above needs **oracle confirmation** before it is a decode.
2. **An accumulator op is only PART of a word's semantics.** `decoded()` requires the store, the
   pointer walk, the source and the destination too. A family with a settled accumulator op may
   still be undecoded on every other axis.

## 4. What this DOES change
It converts *"443 undecoded words in 133 families"* — which reads as open-ended — into a **ranked
work list where the top half already carries measured candidates and a named confirmation step**.
The next unit of work is not a search: it is *"take family `212/2/000` (103 occurrences, candidate
`acc + P + L<<16` on 48 programs), run the programs that use it through the HLE, and confirm or
refute the candidate against what the HLE computes."* That is the oracle comparison the project's
goal asks for, and it is repeatable family by family.

⚠ Grade: the concentration and the cross-reference are MEASURED. **No family is promoted here**,
and none should be until the oracle has spoken.

## 5. ★★ THE FIRST FAMILY TAKEN DOWN THE LIST: `212/2/000`, and only ONE axis was open
Following §4's own instruction — *take the largest family and work it* — applied to `212/2/000`
(**103 occurrences, 32 programs**, the biggest undecoded family in the corpus).

★ **88 of its 103 occurrences are a single word**, `0212200000`, and its fields are almost all
already settled:

| axis | value | status |
|---|---|---|
| `hi12` bit 4 | set | **bit-4 STORE** — decoded, and its target/timing FORCED over 2 160 models |
| `f31` | 1 | **ACCUMULATE** — decoded |
| `ACT` | 0x00 | **adds the bus on top of the `f31` op** — 442 rows, `N-DEVICE-ALGEBRA` §3 |
| `addr8` | 0 | pointer delta **zero** — no walk |
| **`SRC`** | **0x00** | ⛔ **the only open axis** |

⇒ the family is not an unknown instruction. It is **one open source code on an otherwise
specified word.**

### What `SRC 0x00` puts on the bus, measured
Over every occurrence in the 16-program live corpus (`data/src00_bus_2026-09-13.txt`), comparing
the operand latch `L` against each candidate:

| `L` equals | occurrences |
|---|---|
| **the PREVIOUS row's `mem[ptr]`** | **51 of 51** ✅ |
| `mem[ptr]` (same row) | 22 (a subset, where the two coincide) |
| the coefficient, `tempA`, zero | subsets only |

★★ **`mem[N−1]` is the ONLY candidate that matches every occurrence** — and it is not a new rule:
it is the project's already-MEASURED **one-slot operand** (`operand L = mem[N−1]`, the same pipeline
depth that makes `P[N] = coef[N−1] × L[N] >> shift` bit-exact on the biquad). ⇒ **`SRC 0x00` on
this family is the ordinary memory operand, not a special source.**

⚠ **What is still needed before this family can be called decoded**, stated so the next pass does
not over-read it:
1. this is the **device's** `L` column against the **device's** `mem` column — it shows the family
   obeys an *already-established* rule rather than inventing one, which is weaker than an oracle
   confirmation and stronger than a guess;
2. `alu_decoded()` refuses `SRC 0x00` on purpose (§145/§148 carry rival readings of it, one of them
   *"SRC 0x00 = coefficient"* behind mask bits 57–59). **This measurement is evidence against the
   coefficient reading for this family** — `L` equals the coefficient only on the subset where the
   coefficient and `mem[N−1]` coincide — but §148's population is `f98 = 1` class-A words, which
   this is not, so the two need not conflict;
3. the **values** still need the HLE: routing being right does not make the arithmetic right.

⇒ **Next: run the programs that use `212/2/000` through the HLE and check the values**, then take
`000/2/40E` (77 occurrences, still tied in the extractor between `P` and `acc+P−L<<16`).

## 6. ★★★★ THE COVERAGE NUMBER IS NOT A COUNT OF UNKNOWN INSTRUCTIONS — it is a count of OPEN AXES
§5 found the largest family one axis short. That generalises, and it is the most useful thing in
this note (`data/why_refused_2026-09-13.txt`, `data/decode_leverage_2026-09-13.txt`).

`alu_decoded()` requires **every** axis of a word: format, class, the bit-11 modifier, an
**anchored SRC**, an **anchored ACT**, the store's mode and `f31`. A word with six settled axes and
one open one is counted exactly like a word nobody understands at all. Asking the predicate *why*
it refuses each of the 1 740 undecoded occurrences:

| refused for … | occurrences | share |
|---|---|---|
| **exactly 1 reason** | **902** | **52 %** |
| 2 reasons | 515 | 30 % |
| 3 | 189 | 11 % |
| 4–5 | 117 | 7 % |
| 0 (would decode; blocked elsewhere) | 17 | 1 % |

★★ **More than half the undecoded corpus is ONE axis short.**

### ★★★ The leverage table: what a single code buys, on its own
Counting only occurrences where a given axis is the **sole** reason for refusal:

| anchor this one thing | unblocks **by itself** | appears in |
|---|---|---|
| **`SRC 0x00`** | **310** | 552 |
| `ACT 0x0D` | 123 | 200 |
| `ACT 0x0E` | 110 | 222 |
| `f31 = 2` off class 8 | 72 | 236 |
| class 1 admitted | 69 | 322 |
| `SRC 0x11` (accb) | 48 | 160 |
| `SRC 0x1C` | 46 | 46 |
| `SRC 0x08` | 37 | 76 |
| `ACT 0x0B` | 19 | 79 |
| `f31 = 4` | 16 | 46 |
| `ACT 0x1A`, `ACT 0x08` | 19 | 69 |

⇒ ★★★ **twelve single decisions would unblock 869 of 1 740 undecoded occurrences — 50 % — by
themselves**, and the top one (`SRC 0x00`) is worth **310 occurrences alone**.

### Why this is a roadmap and not a shortcut
⚠ "Unblock" means *the predicate would stop refusing it*, **not** *we know what it does*. Anchoring
a code is a claim about the chip and needs the oracle, exactly as §3 says. But it changes the unit
of work from *"decode 443 words"* to **"answer ~12 well-posed questions, each of the form: what
does this one code name?"** — and §5 has already answered the first one's *routing*
(`SRC 0x00` = the ordinary one-slot memory operand, 51 of 51).

⚠ And several of these codes already have committed **speculative** readings the device ships
behind mask bits (`SRC 0x00` = coefficient under §145/§148; `ACT 0x0D`/`0x0E` as the mixing pair).
Anchoring means **deciding between those and the measurements**, which is a smaller and better-posed
job than decoding from nothing.

⇒ **The ranked queue for the remaining coverage work is: `SRC 0x00`, `ACT 0x0D`, `ACT 0x0E`,
`f31 = 2` off class 8, class 1.** Each against the HLE, top down.

## 7. ⛔ THE TOP QUEUE ITEM IS NOT A SIMPLE ANCHOR: `SRC 0x00` HAS AT LEAST THREE POPULATIONS
§6 put `SRC 0x00` first (310 occurrences unblocked alone). §5 measured it as `mem[N−1]` **51 of
51** — but that was **one family**. Taking the code across *every* population it appears in, over
the 16-program live corpus (`data/src00_populations_2026-09-13.txt`), it is **not uniform**:

| population | rows | `L == mem[N−1]` | `L == coef[N−1]` |
|---|---|---|---|
| **class A, `f98 = 1`** | 20 | **0** | **20 — 100 %** |
| every other class | 1 413 | 1 005 (71 %) | 2 |

★ **The `clsA f98 = 1` population is EXACTLY §148's stated population** (*"`SRC 0x00` on `f98 = 1`
class-A words"*), and there the coefficient reading holds **20 of 20** while the memory reading
holds **0 of 20**. ⚠ **That is circular** — the device *ships* §148 (mask bit 59 is set in the
default `SPEC`), so this measures the arm, not the chip. What it does establish is that **§148's
population restriction is exactly right**: the two rival readings do not compete, they partition.

⛔ **But the majority population does not close either.** Excluding §148's population *and*
C-format words (which carry an immediate, not an operand):

| | rows |
|---|---|
| `L == mem[N−1]` | 874 (74 %) — of which **356 are trivially zero==zero** |
| **informative** matches | **518** |
| **residue** | **307 (26 %)**, concentrated: **232 in `hi12 = 000, class 2`** |

⇒ ★★ **`SRC 0x00` cannot be anchored to one source on this evidence.** It has **at least three
populations**: §148's class-A `f98 = 1` (the coefficient), a large `mem[N−1]` majority, and a
**232-row `000/cls2` residue** that is neither.

### What that changes about the queue
⚠ **This corrects an over-read I was one step from making.** *"51 of 51 for family `212/2/000`"*
is true and says nothing about `SRC 0x00` as a **code** — the family is one narrow slice of it. A
per-family measurement must not be promoted to a per-code anchor, which is the same error class as
§43–§46 and §50 in this note's sibling.
⇒ The top queue item is therefore **not** *"anchor `SRC 0x00`"* but **"separate `SRC 0x00`'s
populations, then anchor each"** — and the `000/cls2` residue (232 rows) is the first sub-question.
The 310-occurrence leverage figure is unchanged; the **work** behind it is one level finer than §6
implied.

⚠ Grade: MEASURED, 1 433 `SRC 0x00` rows over 16 programs. No code anchored.

## 8. THE FIRST SUB-QUESTION WORKED: the `000/cls2` residue is a HELD OPERAND LATCH (95.6 %)
§7 named the `hi12 = 000, class 2` residue (232 rows) as the first sub-question. Working it
(`data/residue_000cls2_2026-09-13.txt`):

★ **Every one of the 232 residue rows has `L == L[N−1]`** — the operand latch is **HELD**, not
reloaded. And **all 232 carry `ACT 0x00`**. So on those words `SRC 0x00` is not sourcing anything:
the latch simply keeps what the previous word put there, and `ACT 0x00`'s bus term re-uses it.
That also explains why they looked like a residue at all — they were being tested against
`mem[N−1]`, a value they never load.

Widening to **every** `hi12 = 000, class 2, SRC 0x00, ACT 0x00` row (not just the residue), with
adjacency verified in execution order (same unit, consecutive `n` — **0 rows skipped**):

| | rows | share |
|---|---|---|
| `L == L[N−1]` (latch **held**) | **347** | **95.6 %** |
| the 16 exceptions: `L == mem[N−1]` (latch **loaded**) | 16 | 4.4 % |

⇒ the shape is **dominantly a held latch**, with a **16-row exception set that loads instead**,
concentrated at two instruction addresses (`iw119`, and `iw213` in unit 1).

### ⛔ And the obvious discriminator is refuted
`addr8` does **not** separate them: values `0x01`, `0xBA` and `0xFF` each appear in **both**
columns — the same pointer delta both holds and loads. (`0xBA`: 3 held, 13 loaded.) So whatever
decides it is **not** the pointer field.

⇒ **Well-posed and bounded:** *what makes 16 of 363 otherwise-identical words load the operand
latch when the other 347 hold it?* Not `addr8`. The candidates left are the **unit**, the
**preceding word**, and a field the trace does not print. That is the next measurement, and it is
much smaller than the question §7 handed it.

⚠ Grade: MEASURED, 363 rows, adjacency verified. **Nothing anchored** — a 95.6 % rule is not a
decode, and the 4.4 % is exactly the part that would make it one.

## 9. BOTH NAMED CANDIDATES REFUTED — but the 16 loads are CONCENTRATED, and that is a real constraint
§8 left one question: what makes 16 of 363 otherwise-identical words LOAD the operand latch when
347 HOLD it? It named three candidates. Two are now measured
(`data/hold_vs_load_2026-09-13.txt`):

⛔ **The UNIT does not discriminate.** Unit 0: 40 held / 3 loaded. Unit 1: 307 held / 13 loaded.
Both units do both.

⛔ **The preceding word's `(class, ACT)` does not FULLY discriminate** — two shapes appear in both
columns. But it is very far from random:

| preceding word | held | loaded |
|---|---|---|
| `cls2 ACT00` | 148 | **0** |
| `clsA ACT0B` | 144 | **0** |
| `cls1 ACT0B` | 16 | **0** |
| `cls6 ACT07` | 16 | **0** |
| `cls1 ACT00`, `cls1 ACT1C` | 3 | **0** |
| **`clsA ACT15`** (the MULTIPLY) | 18 | **14** |
| **`cls1 ACT07`** | 2 | **2** |

★★ **327 of the 347 holds follow a word that NEVER precedes a load.** Every one of the 16 loads
follows either the **class-A multiply** (`ACT 0x15`, 14 of 16) or a **`cls1 ACT 0x07`** (2 of 16).

⇒ **A NECESSARY CONDITION, measured:** *the latch is only ever reloaded on this shape when the
**previous word was a multiply or an `ACT 0x07`**.* It is **not sufficient** — those two shapes
hold 20 times and load 16 — but it eliminates five of the seven preceding contexts outright and
cuts the open question from 363 rows to the **36** that follow those two shapes.

⇒ The third candidate §8 named — **a field the trace does not print** — is now the live one, and it
has a natural reading: a multiply's own operand fetch plausibly drives the latch, so whether the
next word sees a *held* or a *reloaded* latch may depend on **the multiply's pipeline state**, which
the trace's `L` column shows only after the fact. Testing that needs a **new trace column**, not a
new arm.

⚠ Grade: MEASURED, 363 rows. Nothing anchored. Two candidates eliminated, the open set cut 10×.
