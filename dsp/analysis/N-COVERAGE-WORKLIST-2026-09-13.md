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
