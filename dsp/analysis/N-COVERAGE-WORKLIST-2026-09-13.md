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
