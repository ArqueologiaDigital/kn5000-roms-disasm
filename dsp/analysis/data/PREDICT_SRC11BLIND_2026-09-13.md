# PRE-REGISTRATION — `SRC 0x11`'s operand is NEVER CONSUMED, and what that licenses

Written **before** the multi-program run. 2026-09-13.

## What §110 already measured, and what it implies
Sweeping `SRC 0x11`'s three readings (cur-unit accumulator / `ACCB` / `mem[ptr]`) on the CHORUS —
whose frame includes the **5 `SRC 0x11` words in the resident kernel**, so the code runs every
frame — gave:

* `§175` PER-SITE **DIFFERS**: the operand `L` genuinely moves (`0..8388607` vs `0..7474246`) and
  the product `P` with it. The readings are not aliases of each other.
* `§176` D-RAM census **IDENTICAL — 0 of 12 cells differ**, and `§228` / `§162` identical too.

⇒ **the operand these words select is fed to the multiplier and never reaches memory.** That is
§96's blindness lemma in the §108 empirical form, on the SOURCE field instead of the accumulator:
if the value is not consumed, then what the code NAMES cannot matter to execution.

⚠ And there is a structural reason to expect it. `lo12 = 0x445` / `0x446` are **PROVEN** (K5) to be
the per-unit CALL-VECTOR selectors, and both lie inside the `SRC 0x11` encoding
(`lo12 & 0x7C0 == 0x440`). The project's own annotation for them reads *"DETERMINED destination;
this SOURCE form is the canned boot default, its source field is OPEN"* — i.e. at least two members
of this family are known to be a word whose `lo12` selects a destination and whose source is inert.

## The test
TYPES **2** (enhancer, 4 sites), **3** (flanger, 4), **5** (ensemble, 7), **14** (no operation, 2),
**16** (auto pan, 4) — each under the three readings, `UPD6383_CENSUS_PERPROG=1`, true default
otherwise.

| | prediction |
|---|---|
| **K1** | `§175` must DIFFER between readings in every program — the operand really changes, so the test is not vacuous |
| **K2** ★ | `§176` D-RAM census **bit-identical** across the three readings, in every program |
| **K3** | ⚠ the NEGATIVE control this session already supplies: these same censuses DO move when a model is wrong — `clr:after` killed the LFO, `LD@before` broke its rate, the C-format `P` destination collapsed the hand-off cell. They are not insensitive instruments |

## What a pass licenses, and what it does not
★ For a program where K1 and K2 hold, that program's `SRC 0x11` words are **EXECUTABLE as far as
the SOURCE field goes**: the operand is not consumed, so every reading of the code executes them
identically. Combined with the existing anchorings, the **54 words refused for `SRC 0x11` ALONE**
would become decodable.

⛔ It does not decode `SRC 0x11`. ⛔ It licenses only the programs actually run. ⛔ And it says
nothing about the other 23 words in the population, which are refused on other axes too.


---

## RESULT — **K2 FAILS 5 of 5. The extrapolation is refuted; the measurement it came from stands.**
Data: [`src11blind_2026-09-13.txt`](src11blind_2026-09-13.txt).

```
   TYPE  program        sites   §175 (K1)     §176 (K2)      verdict
   2     enhancer         4     differ(3)     DIFFER(3)      OPERAND IS CONSUMED
   3     flanger          4     differ(3)     DIFFER(3)      OPERAND IS CONSUMED
   5     ensemble         7     differ(3)     DIFFER(3)      OPERAND IS CONSUMED
   14    no operation     2     differ(3)     DIFFER(3)      OPERAND IS CONSUMED
   16    auto pan         4     differ(3)     DIFFER(3)      OPERAND IS CONSUMED
   ---   chorus (§110)    -     differ(3)     IDENTICAL      <- the exception, not the rule
```

**K1 holds everywhere** (the operand really moves), and **K2 fails everywhere**: the D-RAM census
differs between the three readings in all five programs. ⇒ **`SRC 0x11`'s operand IS consumed**, and
no word is admitted. **Coverage unchanged at 77.6 %.**

### ⚠ This refutes my extrapolation, not §110's measurement
§110 measured, on the CHORUS, that the operand moves while the D-RAM comes out bit-identical. That
stands. What does not stand is the sentence I built on it in this file's header — *"the operand
these words select is fed to the multiplier and never reaches memory"*. Five programs say it does.
**The chorus's D-RAM being insensitive is a property of the chorus, not of the code.**

★ That is the sixth over-read of this session, and like the others it was stopped by a criterion
written before the run rather than by the result. K1 and K2 exist precisely so that "the censuses
agree" cannot be quoted without "and they were able to disagree" — here they disagreed, five times
out of five.

⚠ It also puts a boundary on §108's method: **one program's null does not generalise.** §108's
conclusion was drawn over five programs with three of them showing the opposite; §110's was drawn
over one. The instrument is sound; the sample size was mine.
