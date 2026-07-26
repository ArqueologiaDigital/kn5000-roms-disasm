# The K3 / K4 / R2 / R3 adjudication, and what did not survive it

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Date: **2026-07-26**.
Tool: [`../tools/isa_adjudicate.py`](../tools/isa_adjudicate.py) — stdlib only,
re-runnable, prints every number quoted here.

Four decode workflows (K3 pointer registers, K4 cursor rebase, R2 result
routing, R3 delay-DRAM addressing) landed in this tree within hours of each
other. Each was right about its own subject and each asserted things the others
could not see. This pass re-derives, from the ROM, **every claim where two of
them can disagree**, and integrates only what survives into
[`../instruction-set.md`](../instruction-set.md).

Labels: **MEASURED** / **PROVEN BY CONSTRUCTION** / **FORCED** / **CONSISTENT** /
**INFERRED** / **OPEN**. Where a constraint system admits several assignments
they are enumerated, not picked. No hardware; nothing here is a recording.

**Result in one line:** R2's census is reproduced *exactly*, K4's class-8 claim
holds exactly, K3's C-format payload split holds exactly — and **two committed
claims are falsified**, one of them the freshest in the tree.

---

## 0. Verdict table

| # | claim | pass | verdict |
|---|---|---|---|
| 1 | `C40.1.80.000` / `C40.1.E0.451` are class-1 DRAM words and corroborate R2's `addr8` bit-7 withdrawal | R3 §6.1, §9.5 | **FALSIFIED** — they are C-format immediate loads; the corroboration is VOID |
| 2 | the descriptor-cursor counting model is "consistent with zero residual, 8 solutions in {0,1}" | R3 §6.1 | **DOWNGRADED** — that holds only *with* the contamination; guarded it has **0** {0,1} solutions and the naive identity falls 88/96 → 80/96 |
| 3 | the C-format family predicate is `(hi12 & 0xFFE) == 0xC40` | `instruction-set.md` | **CORRECTED** — that is the *payload rule*. The FORMAT is `hi12[11:8] == 0xC` (68 words), which is what `dsp_disasm.c_format()` has always implemented |
| 4 | `lo12 = 0x827` (payloads `0x6C`/`0x64`) inherits the D-RAM-origin slot | K3 | **WITHDRAWN to OPEN** — under the only positive test available it fails **85 of 85** streams |
| 5 | mode-2 is never ESCAPE (0/2399); classes 3,7,B,E,F do not exist; mode 1 = 324/324 | R2 §1 | **CONFIRMED**, reproduced row for row — but *only* under the wide C-format predicate (item 3) |
| 6 | bit 23 = FETCH, only `class4 == 0xA` ADVANCES | K4 | **CONFIRMED** and sharpened: body-scoped it is exact (class 8 = 42, class A = 822, nothing else); the **kernel** also has classes 9, C, D |
| 7 | imm13 is a multiple of 32 — 57/57 inside `0xC40`, 2/11 outside | K3 | **CONFIRMED** exactly |
| 8 | `801.0.NN.825` addresses the tag-`0x4C` space | K3 INFERRED → R3 PROVEN | **CONFIRMED**; promoted to a tier-1 mnemonic `ldptr.d` |
| 9 | `0x50` / `0xD0` are "two indices the host clears in bit-7 order" | R2 | **SHARPENED** — they are the per-unit **STATE-BLOCK BASE**, MEASURED over 87 of 91 streams |
| 10 | R3 §6.3: "the kernel loads `801.0.25.825` in *both* setups" | R3 | **INCOMPLETE** — there is a **third** load, output stage w62 = `801.0.26.825` |

---

## 1. ★ FALSIFICATION — R3's DRAM family is contaminated by C-format words

`isa_adjudicate.py cformat`.

R3 selects the delay-DRAM family with

```python
    if (fields(w)[0] & 0x800) and fields(w)[1] == 1        # r3_delaydram.py:368
```

— `hi12` bit 11 set and `class4 == 1`, **with no C-format guard**. But
`hi12[11:8] == 0xC` *always* has bit 11 set, and in that family `class4` is not
a field at all: bits [24:12] are one 13-bit immediate. Three words walk in:

```
   C40.1.80.000   4 sites (canonical corpus) / 48 (all slots)   imm13 = 384 -> A=12 B=0
   C40.1.E0.451   8 sites                    /  8               imm13 = 480 -> A=15 B=0
   C4A.1.C0.820   1 site  (header w40)                          imm13 = 448 -> A=14 B=0
```

The first two are **already catalogued** in `instruction-set.md`'s own MEASURED
C-format payload table — the rows `lo12 000 -> A=12 (reverb)` and
`lo12 451 -> A=15`. R3 solves for them as if they were DRAM opcodes.

### 1.1 The deciding argument is identity, not counting

`C40.1.80.000` (A=12, the 12 reverbs) and `C40.2.C0.000` (A=22, 8 other
algorithms) are **the same instruction**: same C-format family, same destination
register `lo12 = 0x000`, differing only in the 13-bit immediate. The first reads
`class4 == 1` and the second `class4 == 2` **purely because bit 8 of the
immediate differs**. R3's solve includes one and excludes the other.

No machine can make one of two words that differ only in immediate data touch the
delay DRAM and the other not. **FORCED.**

### 1.2 What R3 §9.5 offered as corroboration is exactly the artifact

> R3 §9.5: *"it puts `C40.1.80.000` (`addr8 = 0x80`) **in** the DRAM family and
> `C40.1.E0.451` (`addr8 = 0xE0`) **out** — independent support for R2's
> withdrawal of K6's `addr8` bit-7 split."*

Both words are C-format immediate loads. Their "`addr8`" values `0x80` and `0xE0`
are bits [19:12] of an immediate, not an address field. The comparison is between
**two immediates**, and it says nothing about `addr8` bit 7. **VOID.**

*(R2's withdrawal of the bit-7 split stands on its own evidence — `hi12` bit 11
classifies 324/324 while bit 7 misclassifies 3 of 324. It simply never needed
this corroboration.)*

---

## 2. What the falsification costs R3 — and what it does not

`isa_adjudicate.py cursor`. The re-solve delegates the cell count to **R3's own
parser**, so exactly one thing differs between the two runs.

```
   --- R3 as committed (NO guard) ---
      96 equations, 37 unknowns, rank 26, INCONSISTENT ROWS: 0
      solutions with every unknown in {0,1}: 8
      naive 'cells == consuming words': 88 of 96
   --- GUARDED (C-format excluded) ---
      96 equations, 35 unknowns, rank 25, INCONSISTENT ROWS: 0
      solutions with every unknown in {0,1}: 0
      naive 'cells == consuming words': 80 of 96
```

**The "exactly satisfiable" headline does not survive.** The rational system stays
consistent, but the {0,1} solution set collapses from 8 to **none**. The whole
residual was being absorbed by the contaminants:

```
   algo name                   cells  esc1  Cfmt    raw  guard
   16..27  the twelve reverbs     32    28     4     +0     +4
   36 COMPRESSOR                   2     2     2     -2     +0
   75 PEQ+COMPRESSOR               3     3     2     -2     +0
   96 PEQ+COMPR+DIST               2     2     2     -2     +0
   97 PEQ+COMPR+OVERDR             2     2     2     -2     +0
   4  FLANGER                      6     8     0     -2     -2
   6  ENSEMBLE                     9    15     0     -6     -6
   66 S.DELAY+FLANGER             11    13     0     -2     -2
   73 PEQ+FLANGER                  6     8     0     -2     -2
```

The 12 reverbs balance **only** if the four `C40.1.80.000` words consume; the
COMPRESSOR family balances **only** if its two `C40.1.E0.451` do not. The solve
duly assigned 1 to the first and 0 to the second — fitting a residual to
immediate data.

### 2.1 Every VALIDATED R3 number is untouched

This is the important half, and it is measured, not asserted:

```
   alignments that change: 14 of 96 algorithm slots
      the 12 reverbs   diverge only at word w114 (of 28 DRAM words)
      COMPRESSOR       diverges only at w19 (of 2)
      PEQ+COMPRESSOR   diverges only at w28 (of 3)
   the body's FIRST DRAM word is unchanged in every algorithm: YES
```

So **the entire ms→address chain survives**: `SINGLE DELAY`'s
`350 ms × 44100/1000 = 15,435` exactly, the four-base residue test, the reverb
`PRE DELAY`, both diffuser ladders, the region map, and — critically — R3's
**P2**, the falsification of R1's raw-payload reading (*every delay length in the
tree is double what R1 printed*). Those rest on the writer, the level-2 tables and
the first DRAM word of each body, none of which this touches.

### 2.2 The reverb's four surplus cells — ENUMERATED, not picked

Guarded, the twelve reverbs write **32** descriptor cells and contain **28**
consuming words. Resolutions:

* **(a)** the host writes more descriptor cells than the body reads. Direct
  support: under R3's reading a reverb DRAM word addresses cell `0x1E = 32767`,
  which is *one below unit 1's own floor* — the only reverb cell outside
  `[32768, 65536)`, and exactly the "top of unit 0's region" marker R3 §5 itself
  identifies. A marker is a natural thing to write and never consume.
* **(b)** some non-mode-1 word consumes cells (nothing in the corpus suggests one).
* **(c)** the kernel consumes cells — R3 §6.3 (iii) already needs this for unit 0
  and can only find 2–3 of the 6 it wants. §6 below adds a third `…825` load the
  enumeration missed, which changes that arithmetic.

FLANGER (−2), ENSEMBLE (−6), S.DELAY+FLANGER (−2) and PEQ+FLANGER (−2) fail in the
*other* direction under both readings; those are what R3's six "undecided" forms
are for.

---

## 3. The C-FORMAT predicate — two different questions, long conflated

`isa_adjudicate.py modes payload`.

`instruction-set.md` said: *"The family predicate must therefore be
`(hi12 & 0xFFE) == 0xC40`, never `hi12 == 0xC40`."* Meanwhile
`dsp_disasm.c_format()` has always read `(hi12 & 0xF00) == 0xC00`. They are not
the same set, and **the code was right**:

| | predicate | n | what it decides |
|---|---|---|---|
| **format** | `hi12[11:8] == 0xC` | **68** | whether `class4`/`addr8` exist at all |
| **payload rule** | `(hi12 & 0xFFE) == 0xC40` | **57** | whether imm13 is a multiple of 32 (`B == 0`) |

Three independent reasons the wide one is the format:

1. **R2's census is reproduced exactly — row for row — only by the wide
   predicate.** 68 C-format, 2989 non-C-format, `mode 2 with ESCAPE 0 of 2399`,
   `mode 6 with ESCAPE 0 of 53`, `mode 1 cursor-clear = 324`. Under the narrow
   one, **two mode-2 words carry the escape** and R2's exceptionless headline
   fails.
2. **Classes 3, 7, B, E, F are empty only under the wide predicate.** The single
   apparent class-3 word in the entire 3057-word corpus is `C04.3.12.820` — a
   header word of the *pointer-load* `lo12 = 0x820` family, which cannot be a
   "class 3". Wide, the class space is exactly `{0,1,2,4,5,6,8,9,A,C,D}`.
3. **The two `C00` words encode their own I-RAM address with a non-zero `B`** —
   `imm13 = 2436 = 76*32 + 4` at I-RAM 76, `2631 = 82*32 + 7` at I-RAM 82. A
   13-bit immediate field with a meaningful low part is present *outside* the
   `0xC40` mask, so the mask cannot be the format.

The 11 words between the predicates are **all kernel words** — 8 header, 3 output
stage, **0 of 2974 body words** — and exactly **2 of 11** are multiples of 32,
reproducing K3's number.

### 3.1 A new MEASURED constraint on the C-format payload

Every one of the 11 kernel C-format words carries `A ≤ 82`, and 82 is the last
word of the 83-word resident kernel. Under a uniform null over 8 bits that is
`(83/256)^11 ≈ 4×10⁻⁶`. Four are independently checkable and all four hit: header
w1 → `A=7` (the second input block, K5), epilogue w74 → `A=77` (the next pointer
load, R2), and the two `C00` self-addresses. In the **body** images the 57
payloads are all `A ≤ 40`.

**⇒ `A` is bounded by the size of the code block the word lives in.** That is
consistent with "`A` is a code address in whatever space `lo12`'s register
addresses" and inconsistent with a single flat I-RAM address space for all of
them. **MEASURED** (the bound); **INFERRED** (the reading).

---

## 4. CONFIRMED, exactly — R2's census and K4's class-8 result

Both reproduce with no discrepancy at all.

```
   3057 words, 68 C-format, 2989 non-C-format
   mode  cur  ESC      n           mode  cur  ESC      n
    0    no   no       62           2    no   no     1556
    0    no   yes      47           2    yes  no      843
    0    yes  yes      44           4    no   no       53
    1    no   no       48           4    yes  yes       1
    1    no   yes     276           5    no   yes       1
    1    yes  no        4           5    yes  yes       1
                                    6    no   no       53
```

K4, split by region — the split is new, and it matters for a core:

```
   BODIES (2974 words)  bit-23 by class:  8 -> 42,  A -> 822.  NOTHING ELSE.
   KERNEL   (83 words)  bit-23 by class:  8 -> 2, 9 -> 4, A -> 21, C -> 1, D -> 1
```

K4's claim is body-scoped and **exact**. But an emulator must not turn it into
"bit 23 ⇒ class 8 or A": the kernel's class-9 call-vector words and R2's two
class-C/class-D `DO`-write words all set it.

---

## 5. ★ NEW — `0x50` / `0xD0` is the per-unit STATE-BLOCK BASE

`isa_adjudicate.py state`. R2 found the pair only as "two indices the host clears
in bit-7 order" and left its job OPEN. K3 measured **one** algorithm's zero-fill.
Over all 91 well-formed parameter streams the fill has a **fixed shape**:

```
   { low unit-tagged registers }  u  { a CONTIGUOUS block based at 0x50 / 0xD0 }
   contiguous, at exactly that base: 87 of 91 streams
```

* the low set always begins `0x05, 0x06, …` (unit 0) or `0x85, 0x86, …` (unit 1)
  and always contains `0x0E` / `0x8B`;
* it confirms K4's bit-7 unit rule and **adds two pairs K4 did not have**:
  `0x06/0x86` and `0x0B/0x8B` (K4 had `85 87 8A 94 D0 ↔ 05 07 0A 14 50`);
* block lengths run 0…40 for unit 0 and are **3 in all twelve reverbs**;
* **PARAMETRIC EQ's is the 40-cell one** — K3's `0x50..0x77` = 5 bands × 2 ch × 4
  Direct-Form-I state words, now recovered as the extreme case of a general rule
  rather than a one-off.

**⇒ register `0x50` (unit 0) / `0xD0` (unit 1) is the base of the per-unit state
block. MEASURED.** That gives `w53` (`010.9.D0.20C`) a job, and its unit-0
partner `w45` (`010.A.00.20C`) shares its `lo12 = 0x20C` — R2 already flagged that
pair as "direct support for `lo12` = destination, `class4` = addressing".

### 5.1 ★ FALSIFICATION — K3's `0x827` is not the D-RAM origin

K3 withdrew `0x821` from the D-RAM-origin slot and put `lo12 = 0x827` (per-unit
payloads `0x6C` / `0x64`) there "**INFERRED by elimination**". Elimination gave it
no positive test. There is one: *the host's zero-fill must clear the state the
body reads.* Taking the body's mode-2 pointer walk and asking whether the
zero-filled block lies inside the body's reach:

```
   origin 0x50 / 0xD0  (this pass)      47 of 85 streams
   origin 0x6C / 0x64  (K3's 0x827)      0 of 85 streams
```

Zero of eighty-five. **K3's assignment is withdrawn; the slot is OPEN again.**

**Stated with its limit, because 47/85 is not a pin either.** The walk model is
naive — one continuous walk from a single origin, no mid-body pointer reload — and
the residual failures are *not* explained: the uncovered offsets split 94 odd /
69 even, so the tempting "stereo bodies walk their state twice" story is **not**
supported, and resetting the pointer at every pointer-load word does not help
(46 of 85). So:

* **MEASURED:** `0x50`/`0xD0` is the state-block base **in the mode-1 index
  space**.
* **OPEN:** whether the mode-1 register file and the mode-2 D-RAM are the same
  256-cell RAM reached two ways (a direct 8-bit index for the host, an
  auto-incrementing pointer for the body). If they are, the D-RAM origin
  `instruction-set.md` calls "still unpinned" is pinned at `0x50`/`0xD0`. The
  47-vs-0 comparison is the only evidence either way, and its weakness is the
  walk model, not the arithmetic.

---

## 6. R3 §6.3's pointer-load census is incomplete

R3 enumerates the cursor-phase resolutions from the premise that *"the shared
kernel loads `801.0.25.825` — the same `0x25` — in **both** per-unit setup blocks
(I-RAM 44 and 52), which cannot produce two different bases."*

There is a **third** load, and R3 did not have it:

```
   header  w44   801.0.25.825
   header  w52   801.0.25.825
   output  w62   801.0.26.825      <- the OUTPUT STAGE, missed by the enumeration
```

`0x26` is exactly the base of **unit 0's descriptor region** (R3 §5: unit-0 cells
are `0x26..0x39`). The frame therefore *ends* by aiming the descriptor pointer at
unit 0's first cell. That is direct support for R3's resolution **(i)**
("`…825` in-program *is* the cursor") and it changes the arithmetic of resolution
**(iii)**, which failed only because the header's consuming-word count could not
reach 6. **MEASURED**; the phase itself stays OPEN.

---

## 7. Also corrected in passing

* **`annotate()` violated its own stated precedence rule.** Its docstring says
  "the C-format rule must come BEFORE any rule keyed on lo12 or on the class4
  nibble"; the rule sat *below* the delay-DRAM rule and got away with it only
  because that rule tested `hi12 == 0x880` exactly. Widening the DRAM family to
  R2's real predicate made it a live bug — the reverb's `C40.1.80.000` matched
  it. Fixed: C-format is now first. This is the same trap R3 fell into.
* **`dsp_coverage.form_of()`** mapped every `hi12 == 0x801` word that was not
  `ldptr` to `rstcur`, so the new `ldptr.d` would have been mis-tallied.
* **the disassembler's `880.1.30.*` annotation** said "framing word, carries no
  DRAM information (MEASURED)". R3 §6.2 shows the opposite: `addr8 = 0x30` marks
  the **first DRAM access of a body**, 37 of 38 distinct images. Corrected.
* **`hi12 == 0x212` → "writes `mem[ptr]`, class-independent"** was still firing;
  R2 falsified it. It is now gated on mode 2, where `mem[ptr]` really is the
  target.

---

## 8. What was integrated

Into [`../instruction-set.md`](../instruction-set.md) and
[`../tools/dsp_disasm.py`](../tools/dsp_disasm.py):

* `801.0.NN.825` → **tier 1**, mnemonic **`ldptr.d #$NN`** (R3 PROVEN BY
  CONSTRUCTION for both the encoding and the space);
* the delay-DRAM family widened to R2's predicate (mode 1 + ESCAPE, C-format
  guarded) → **tier 2**, carrying R3's address model in the annotation;
* `cur+` → `cur` on every bit-23 word that is not class A (K4, FORCED);
* the register-file annotation with named cells `0x06`/`0x86` (output level,
  R2) and `0x50`/`0xD0` (state-block base, §5);
* the C-format predicate split (`c_format` vs `is_c40`);
* the falsified annotations removed.

`dsp/verify.py`: **BYTE-MATCH OK** after regenerating all 40 listings.

---

## 9. MAME sync list — for `src/devices/cpu/upd6383/upd6383d.cpp`

**Not applied here.** That file is owned by the concurrent ALU workflow; this is
the queue, newest first. Items 1–5 are K5's pending list, still unsynced.

| # | change | why / status |
|---|---|---|
| 1 | **demote the `hi12 == 0xC40` "envelope / level detector" label** | FALSIFIED — wrong on **all 61 sites**; it fired on the reverb tank, on CHORUS and on the frame terminator's neighbours |
| 2 | **add the C-format immediate load**, and use **two** predicates: `c_format = (hi12 & 0xF00) == 0xC00` for whether `class4`/`addr8` exist, `is_c40 = (hi12 & 0xFFE) == 0xC40` before reading `A = imm13 >> 5` | §3. Getting this wrong is what produced items 8 and 9 |
| 3 | **add the `C00` wait/sync rendering** — `A = imm13 >> 5` is the word's own I-RAM address (2/2), `B` the event | K5 |
| 4 | **add the call-vector rendering** `setvec unitN,#A` for `lo12 ∈ {0x445, 0x446}` | K5, DETERMINED |
| 5 | **use `(hi12 & 0xFFE)` family predicates**, never `hi12 ==`, and **stop firing the host-poke annotation on in-program words** — `0A aa bb cc dd` is a host-stream packet, not an instruction | K5 |
| 6 | **`cur+` → `cur` for every bit-23 word that is not `class4 == 0xA`** | K4, FORCED. `cur+` must mean "fetches AND advances"; only class A advances. Already done in `dsp_disasm.py`; the two files are now out of step **on purpose** until this lands |
| 7 | **add `ldptr.d #$NN` for `801.0.NN.825`** — the delay-descriptor pointer | R3, PROVEN BY CONSTRUCTION both halves. Tier 1 |
| 8 | **widen the delay-DRAM family to mode 1 + ESCAPE with a C-format guard**, and carry the address model `DESCRIPTOR_CELL[cursor] + G` in the annotation | R2 + R3. ⚠ the guard is not optional — see §1 |
| 9 | **move the C-format test to the TOP of `annotate()`** | §7. It is a live bug the moment item 8 lands |
| 10 | **remove `880.1.30.* = "framing word, carries no DRAM information"`** — it is the body's FIRST DRAM access, 37/38 | R3 §6.2 |
| 11 | **stop generalising `addr8 60 = read / 20 = write`** beyond `2D4`/`655`/`64B` | R3 §6.3, FALSIFIED |
| 12 | **gate `hi12 == 0x212 → writes mem[ptr]` on mode 2** | R2 — the universal form manufactures four dead stores in the output stage |
| 13 | **add the register-file annotation** for mode 1 without escape: bit 7 = the unit, `0x06`/`0x86` = OUTPUT LEVEL, `0x50`/`0xD0` = STATE-BLOCK BASE | R2 + §5 |

**Behavioural notes for the core (not the disassembler), in priority order:**

1. **`hi12` bit 4's target is mode-dependent** — `mem[ptr]` only in mode 2. Eight
   kernel words mis-execute otherwise.
2. **A body's C-RAM cursor base is an EXTERNAL INPUT** (`0x00` at I-RAM 84, `0x90`
   at 200), not derivable from its own words; and C-RAM must be **preloaded** with
   the 60-cell resident table at `0x50..0x8B` from Sub CPU ROM `0x01E6BE`, or every
   table lookup reads zeros.
3. **Address generation is fully separable from arithmetic** — the ALU never sees a
   delay address; the cell is fetched by the DRAM sub-unit from a host bank via an
   implicit cursor.
4. **Sign of the global rotation:** an all-pass stage's read cell sits *below* its
   write cell by exactly the delay, so `G` must **increment** if addresses are
   `cell + G`. Wrong sign ⇒ a silent tail, not merely a wrong one.
5. **Every delay length doubles** relative to anything quoting R1's numbers.

---

## 10. Reproducing

```
python3 dsp/tools/isa_adjudicate.py             # all six sections
python3 dsp/tools/isa_adjudicate.py cformat cursor    # the falsification
python3 dsp/tools/isa_adjudicate.py modes class8      # R2 and K4 re-derived
python3 dsp/tools/isa_adjudicate.py state             # the state-block result
python3 dsp/tools/dsp_coverage.py               # the coverage table
python3 dsp/verify.py                           # BYTE-MATCH
```
