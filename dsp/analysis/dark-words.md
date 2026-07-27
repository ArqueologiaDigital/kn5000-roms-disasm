# THE 86 WORDS THAT EXECUTE NOTHING — the dark set of the uPD6383GF frame

KN5000 IC311, NEC uPD6383GF-3BA. Date: 2026-07-27.
Tool: `dsp/tools/dark_words.py` (stdlib only) — every number below comes out of it.

```
python3 dsp/tools/dark_words.py            # everything
python3 dsp/tools/dark_words.py frame      # the 108/91/86 split and its structure
python3 dsp/tools/dark_words.py enumerate  # the 86, in execution order
python3 dsp/tools/dark_words.py groups     # the blocker-set partition
python3 dsp/tools/dark_words.py leverage   # ★ the ranking, three metrics
python3 dsp/tools/dark_words.py critical   # ★ aborts the frame vs merely unexecuted
python3 dsp/tools/dark_words.py cformat   # the C-format immediate, and a withdrawn control
python3 dsp/tools/dark_words.py dirtest    # ★ H-DIR, and the control that rejects
python3 dsp/tools/dark_words.py robust     # the dark set over all 37 unit-0 bodies
python3 dsp/tools/dark_words.py control    # the controls, each shown saying NO
python3 dsp/tools/dark_words.py neighbours # nearest decoded word either side
```

**No MAME source was touched** (`git status -- src/` in `kn7000_mame` is empty), so
the DSPCFG-OFF audio is bit-identical to the published build *by construction* —
there is no edit for a capture to detect. `dsp/verify.py` **BYTE-MATCH OK**;
`dsp_coverage.py` unchanged to the digit (frame floor 38.4 % / 61.1 %). Neither
disassembler was edited, so the mirror diff is unaffected.

---

## Headline

| # | Claim | Status |
|---|---|---|
| **A** | ★★★ **THE DARK SET IS NOT A RESIDUE — IT IS A REGION, AND THE BOUNDARY IS A THEOREM.** A word traps *iff* it has no modelled addressing, so **every dark word is exactly a word with `class4 ∈ {0,1,3,4,5,6,7}` or the C format** (plus not being one of the 12 K6 words). No dark word can post-increment the data pointer, fetch a coefficient or advance the coefficient cursor — **not by measurement, by construction**. The dark set is the part of the chip that talks to something *other than* the D-RAM/C-RAM datapath: the external delay DRAM, the register/port space, and the immediate format. | **PROVEN BY CONSTRUCTION** |
| **B** | ★★★ **ONE UNKNOWN FAMILY IS HALF THE DARK SET: 42 of 86 slots are the external delay-DRAM.** 13 distinct words, 28 of them inside the reverb. Resolving it alone takes the frame from **108 to 133 decoded of 285** (37.9 % → 46.7 %) and the reverb image from **69 to 89 of 133** (51.9 % → 66.9 %). It is rank 1 on *all three* ranking metrics — raw reach, slots-per-unknown, and slots-per-discovery — and rank 1 for **37 of 37** unit-0 bodies in the ROM. | **MEASURED** |
| **C** | ★★ **THE DARK SET IS NOT WHAT MAKES THE ARITHMETIC WRONG — THE PARTIAL SET IS.** Marginal taint walk: the 91 PARTIAL slots alone contaminate **100 of 108** decoded slots starting at slot 6; the 86 dark slots alone contaminate **93** starting at slot **39**. Decoding *all* 86 would still leave 100 of 108 decoded slots computing on stale state. The dark set's exclusive contribution is elsewhere — see D. | **MEASURED** (lower bound: the walk enters the frame clean) |
| **D** | ★★★ **WHAT THE DARK SET EXCLUSIVELY OWNS IS I/O.** (a) All 42 delay-DRAM accesses are dark, so **the external delay line is never read and never written** — a failure no amount of ALU decoding can repair. (b) Both per-unit **OUTPUT LEVEL** words (`w72` register `0x06`, `w77` register `0x86`) are dark, and they are the two words immediately preceding the two presentations. The presentations themselves (`w73`/`w78`) are PARTIAL. So the last gate on the audio path is dark. | **MEASURED** + **INFERRED** (the roles are R2/K5's) |
| **E** | ★★ **THE PUBLISHED RANKED BLOCKER LIST IS NOT A PARTITION AND OVERCOUNTS.** `dsp-closure-applied.md` §5's twelve buckets sum to **179** against its own stated **177**, and its "external delay-DRAM 41 slots" is **42** here (`880.1.30.8BC` also carries the `lo12` bit-11 modifier and was counted in the other bucket). The grouping in §3 below is a strict partition of the 86 by *blocker set*, which is what makes a per-unknown metric computable at all. | **MEASURED** (a predict-then-check MISS, §8) |
| **F** | ★ **A DIRECTION RULE FOR THE DELAY-DRAM FAMILY, AND IT SCORES 4/4 WHERE THE FALSIFIED ONE SCORES 2/4.** `H-DIR`: SRC `0x0B` ⇔ the word is a delay-line READ. It reproduces both R1-FORCED assignments *and* both R3 §6.3 assignments — including the two that falsified the `addr8` rule — and neither established assignment was derived from `lo12`, so the agreement is not circular. | **CONSISTENT, 4 of 4** — *not* forced (§6) |
| **G** | ★★ **NOTHING IN THE MODEL ADVANCES THE DELAY-DESCRIPTOR CURSOR, BECAUSE ITS ONLY CONSUMERS ARE THE 42 DARK WORDS.** The "+0 residue / the frame closes" result is about the **D-RAM operand pointer**. The descriptor cursor R3 proved the DRAM address comes from has **never had a closure test**, and it cannot have one until this group executes. | **PROVEN BY CONSTRUCTION** (`upd6383.cpp:1019`, `m_dsc` is a pointer with no cursor) |
| **H** | ★ **THE 86 ARE ONLY 47 DISTINCT WORDS AND 46 DISTINCT FAMILIES**, and the top three groups are **82.6 %** of the set. Across all 37 unit-0 bodies the dark count spans **64..91 slots (20.0 %..30.2 % of the frame)** — it is a property of the machine, not of the cold-boot pair. | **MEASURED** |

---

## 0. Provenance and the positive control

The frame is reconstructed statically: header (ROM `0x01E496`, 60 words),
epilogue (ROM `0x01E63C`, 23 words) with I-RAM 64/71 replaced by the two
host-patched `setvec` words, unit-0 = ROM algo 1 (CHORUS) at I-RAM 84, unit-1 =
ROM algo 16 (ROOM REVERB) at I-RAM 200, walked through the call/return sequencer
of `upd6383_device::run_frame()`.

**C1 — the reconstruction against the live measurement.** It must reproduce the
MEASURED live split exactly:

```
   cold-boot frame: 285 slots = 108 DECODED + 91 PARTIAL + 86 TRAP     <- static
   last frame:      285 slots = 108 DECODED + 91 PARTIAL + 86 TRAP     <- live
                    (kn7000_mame/notes/dsp-closure-applied.md item C)
```

**PASS, exact.** ★ **And it is shown capable of failing**: rebuilt with unit-0 =
algo 0 / 2 / 3 it gives `(96,97,71)` / `(114,97,89)` / `(120,120,74)` over
264 / 300 / 314 slots — three different answers, none of them the live one. A
control that returns the same triple for every input would be worthless.

The other three controls are in §7.

---

## 1. ★ THE BOUNDARY IS A THEOREM, NOT A TALLY

MAME's `run_frame()` sorts a slot by two predicates only:

```
   DECODED   decoded(w)
   PARTIAL   !decoded(w) && ( addressing_only(w) || has_addressing(w) )
   TRAP      everything else
```

and `has_addressing(w) = ptr_postinc(w) || coeff_consumer(w) || cursor_fetch(w)`
with

```
   ptr_postinc     !c_format && (class4 & 7) == 2        ->  class4 in {2, A}
   coeff_consumer  !c_format && class4 == 0xA            ->  class4 == A
   cursor_fetch    !c_format && bit 23                   ->  class4 >= 8
```

Therefore, **exactly**:

> a word is dark ⟺ it is not decoded, it is not one of the twelve whitelisted K6
> input-stage words, and it is either **C-format** or has **`class4 ∈ {0,1,3,4,5,6,7}`**.

MEASURED confirmation over the frame (`dark_words.py frame`):

```
   class4 of the 86 dark slots : {0:10, 1:59, 2:1, 3:5, 4:4, 5:2, 6:3, 9:2}
   ...of which C-format        : 17          (the 2 and 9 above are C-format:
                                              in that format class4 is immediate data)
   has_addressing() on a dark word : 0 of 86  <- the theorem, checked
   PARTIAL slots by class4     : {0:1, 2:45, 8:2, 9:2, A:39, C:1, D:1}
   DECODED slots by class4     : {0:6, 2:66, 9:1, A:35}
```

Six of the seven admissible dark classes occur; class 7 does not occur in this
frame. **This is the finding the previous passes did not have**: the dark set is
not "the words we have not got to yet", it is *the complement of the on-chip
datapath*. Everything in it addresses something the datapath model does not
contain — external DRAM, the register/port space, or an immediate.

**AND THE CONVERSE MATTERS TOO.** Because no dark word has modelled addressing,
the dark set cannot desynchronise the data pointer or the coefficient cursor —
which is why the closure work could reach a `+0` residue while 86 slots did
nothing. **But that guarantee is only as good as the model**: R3 PROVED the
delay-DRAM address comes from an *implicit auto-incrementing descriptor cursor*,
and 42 dark words consume it. The device has `m_dsc` (the descriptor **pointer**,
loaded by `ldptr.d`) and **no descriptor cursor at all** — `upd6383.cpp:1019`
says so in as many words: *"the words that would consume the descriptor cells are
not decoded"*. So **item G**: the closure result covers one of the two pointers
this machine walks per frame, and the other one has never been testable.

---

## 2. THE ENUMERATION, IN EXECUTION ORDER

`dark_words.py enumerate`. Execution order is header 0..49 → unit-0 body 84..153
→ header 50..59 → unit-1 body 200..332 → epilogue 60..81 (the frame-wait word at
I-RAM 82 ends the frame before it counts as a slot: 285 executed of 286 fetched).

| region | slots | DECODED | PARTIAL | **TRAP** |
|---|---:|---:|---:|---:|
| header 0..49 (pre unit-0 call) | 50 | 10 | 28 | **12** |
| unit-0 body — CHORUS @84 | 70 | 23 | 22 | **25** |
| header 50..59 (pre unit-1 call) | 10 | 2 | 3 | **5** |
| unit-1 body — ROOM REVERB @200 | 133 | 69 | 31 | **33** |
| epilogue 60..81 (output stage) | 22 | 4 | 7 | **11** |
| **total** | **285** | **108** | **91** | **86** |

86 slots, **47 distinct words**, **46 distinct families**. The full ordered table
with fields, region and blocker set is what `enumerate` prints; the structurally
interesting stretches are:

**Header 0..49 — 12 dark.** Three delay-DRAM (`880.1.20.2D5` @12,
`880.1.20.40B` @26, `800.1.60.00B` @46), five C-format `lo12 = 0x820`
immediates (@15, 22, 29, 31, 40 — imm13 = 658, 786, 1111, 1201, 448),
`809.0.00.839` @38, `801.0.6C.827` @43, `C64.5.A2.000` @48, and the unit-0 CALL
word `400.1.0E.000` @49.

**The two per-unit pointer triples are 2/3 decoded and 1/3 dark**, and it is the
*same* third both times:

```
   I-RAM 42  801.0.70.821  ldptr   #$70      DECODED
   I-RAM 43  801.0.6C.827  <reg 0x27> #$6C   ★ DARK
   I-RAM 44  801.0.25.825  ldptr.d #$25      DECODED
   ...
   I-RAM 50  801.0.50.821  ldptr   #$50      DECODED
   I-RAM 51  801.0.64.827  <reg 0x27> #$64   ★ DARK
   I-RAM 52  801.0.25.825  ldptr.d #$25      DECODED
```

Two dark slots, but they are a **third per-unit pointer register** whose role is
OPEN (K3 §5.1; its D-RAM-origin candidacy was **RETRACTED**, 0 of 85 streams,
`retraction-sweep.md` P14). They are loaded *once per unit per frame*, between
the C-RAM pointer and the delay-descriptor pointer. See §4.5.

**Unit-0 body (CHORUS) — 25 dark**, and they are a repeating idiom: four
instances of `900.1.60.1D5 … C40.3.20.44C, A00.0.00.041, 880.1.20.2C7`, plus the
class-4/6 pair `000.6.18.4CD / 012.4.01.1CE` twice, plus the line write
`880.1.60.000` @152 and the body terminator `602.1.0E.000` @153.

**Unit-1 body (ROOM REVERB) — 33 dark, 28 of them delay-DRAM.** The 6-word
all-pass motif contributes 2 dark slots per instance, and they are precisely the
two the R1 search FORCED:

```
   slot 0  880.1.60.2D4   ★ DARK   the DRAM READ   (FORCED)
   slot 1  104.2.00.000            DECODED
   slot 2  000.2.00.419            DECODED
   slot 3  012.2.00.680            DECODED
   slot 4  880.1.20.655   ★ DARK   the DRAM WRITE  (FORCED)
   slot 5  102.A.00.64B            PARTIAL  (ACTION 0x0B unanchored)
   slot 6,7  nop nop               DECODED
```

Nine instances → 18 dark slots. **The one thing about the motif that is FORCED is
the one thing that does not execute.**

**Epilogue 60..81 — 11 dark**, and this is where they matter most (§5).

---

## 3. ★ THE GROUPS, AND THE RANKING

### 3.1 The partition

Each dark word gets a **blocker set** — every unknown that must be resolved
before it could execute. Family blockers ("we cannot read this format at all")
and field blockers ("the format is readable, this code in it is not") are counted
together, because a word needs all of them. `dark_words.py groups` prints the
full 32-row partition; rolled up:

| group | slots | distinct | % of dark | where |
|---|---:|---:|---:|---|
| **A — external delay-DRAM** (mode 1 + format escape) | **42** | 13 | 48.8 % | hdr 3, u0 10, hdr' 1, **rev 28** |
| **B — C-format immediate**, destination open | **17** | 11 | 19.8 % | hdr 6, u0 4, hdr' 1, rev 4, epi 2 |
| **C — mode-1 space** (no escape: register/port/D-RAM window) | **12** | 12 | 14.0 % | hdr 1, u0 1, hdr' 2, rev 1, **epi 7** |
| **E — unknown class** (0 non-regload ×7, 4 ×2, 5 ×1, 6 ×2) | **12** | 8 | 14.0 % | hdr 1, u0 10, epi 1 |
| **D — class-0 register load**, selector `0x27` ×2 / `0x22`+store ×1 | **3** | 3 | 3.5 % | hdr 1, hdr' 1, epi 1 |

A + B + C = **71 of 86 = 82.6 %**. The partition sums to 86 exactly; the
published list it replaces sums to 179 against a stated 177 (item E).

### 3.2 Three metrics, and why raw frequency is the wrong one

`dark_words.py leverage`.

**RANK 1 — sole-blocker leverage** (resolve U *alone*; count what unblocks). This
is the number that says what a single result buys you today:

```
   C-DEST-000   7      C-DEST-820   5      C-DEST-44C   4
   REGSEL-27    2      C-DEST-007   1
   everything else: 0 -- 35 of the 40 unknowns are NEVER the sole blocker
```

★ **35 of 40 unknowns unblock nothing on their own.** That is the whole argument
against ranking by frequency: `DRAM-ADDR` has reach 42 and sole-leverage 0,
because every delay-DRAM word also needs its direction. **CONTROL C3**: the
order by reach and the order by sole-leverage share **no** element in their top
six. The metric is not a relabelling of frequency.

**RANK 2 — best bundles** (slots ÷ number of unknowns in the bundle):

```
    8.33   25 slots / 3   DRAM-ADDR, DRAM-DIR, SRC-0B
    8.00   32 slots / 4   + C-DEST-000
    7.00    7 slots / 1   C-DEST-000
    6.50   13 slots / 2   DRAM-ADDR, DRAM-DIR          <- the 9 reverb WRITES + 4
```

**RANK 3 — effort-graded** (slots ÷ *discoveries*, where a `MODEL` unknown — a
code with a named role the executor simply lacks, like the delay-RAM read
register — is work, not a discovery):

```
   12.50   25 slots / 2 discoveries + 1 modelling job   DRAM-ADDR, DRAM-DIR, SRC-0B
   10.67   32 slots / 3 + 1                             + C-DEST-000
```

**The delay-DRAM group is rank 1 on all three.** It is also rank 1 on reach for
**37 of 37** unit-0 bodies (`robust`).

**SENSITIVITY, stated rather than hidden.** `C-DEST-xxx` keys the C-format
destination on `lo12`. `hi12[7:0]` also varies over those words and *might* be
part of the destination; if it is, the four keys become ten and the best C-format
leverage falls from 7 slots to 4. That does not change the ranking (A still
leads), but it is the one place where the metric depends on a judgement call.

---

## 4. WHAT WOULD SETTLE EACH — precisely enough to execute

### 4.1 Group A — the external delay-DRAM — **42 slots, 2 unknowns**

Two unknowns, both needed:

* **`DRAM-ADDR` — the descriptor cursor's PHASE.** The *mechanism* is **PROVEN BY
  CONSTRUCTION** (R3 §1: `LABEL_038922` emits `801.0.PP.825` + a tag-`0x4C`
  packet; address = `DESCRIPTOR_CELL[cursor] + G`). What is open is which cell
  the cursor starts on, and R3 §6.3 enumerates **exactly three** candidates
  (i)/(ii)/(iii) — a three-way choice, not an open field.
  **THE EXPERIMENT, and it is a closure test nobody has been able to run:** model
  a descriptor cursor, advance it on every mode-1-escape word, and check it
  **returns to its entry value at the end of a frame**, per unit and globally.
  That is the exact test that produced the `+0` result for the D-RAM operand
  pointer; it has never been applied here because the consumers do not execute
  (item G). Candidate (iii) predicts the highest cell index in use is `< 0x40`
  and the MEASURED maximum is `0x39` — so (iii) already survives one test and
  the closure test can kill it.
* **`DRAM-DIR` — the direction encoding.** `addr8` is FALSIFIED (R3 §6.3).
  **H-DIR (§6) is a candidate that scores 4/4 on the four established
  assignments.** Confirming or killing it is cheap and it removes one of the two
  unknowns on 42 slots.

**Firmware-side lever, unused so far:** there is **no continuation writer for tag
`0x4C`** (K3): every descriptor value is preceded by its own `801.0.PP.825`. So
the host stream *is* an ordered list of (cell, value) pairs, and the order the
Sub CPU writes them in is a second, independent witness of the cursor's intended
walk. `LABEL_038922` is the routine; the pairing is one pass over the capture.

### 4.2 Group B — the C-format immediate — **17 slots, 4 destination codes**

The format is settled (`imm13 = A·32 + B`, `A` an I-RAM word address in the two
known cases: `setvec unit0,#84` and `setvec unit1,#200`). What is open is the
**destination**, keyed on `lo12`:

| dest | slots | words | what the frame says about it |
|---|---:|---|---|
| `0x000` | 7 | `C40.1.80.000` ×4 (rev, A=12), `C64.5.A2.000` (A=45), `C16.9.AB.000` (A=**77**), `C00.9.84.000` (A=**76**) | ★ the two epilogue members are **self/near-addressing**: `C00.9.84.000` sits at I-RAM **76** and encodes A = **76**; `C16.9.AB.000` sits at 74 and encodes A = **77** = `w77`. R2 already reads `w76` as a wait and `w74` as "points at `w77`". Both C00 words in the machine encode their own address (2/2). |
| `0x820` | 5 | header @15,22,29,31,40 | imm13 = 658, 786, 1111, 1201, 448. §6.5 of the per-frame note retired the loop-count reading on the cycle budget; as delay offsets they are 10.2–27.2 ms. `closure-pointer.md` **falsified** them as the frame-closing pointer load *on siting*. |
| `0x44C` | 4 | `C40.3.20.44C` (CHORUS, A=25) | one per CHORUS voice-idiom instance |
| `0x007` | 1 | `C64.6.A2.007` (A=53) | |

**THE EVIDENCE THAT SETTLES IT is already in the machine and is a
known-mathematics block**: `lo12 = 0x445` and `0x446` are the *same field* with a
settled meaning (per-unit call vector), reached by K5 from the firmware side —
`EFF_Link` writes exactly those two I-RAM words and the payloads decode to the
body entry addresses 84/200 (91/91 streams). **So the destination map is a
firmware-observable table**: enumerate every C-format word the Sub CPU ever
constructs or patches, and the destination code is whatever register that routine
is known to be setting. K5 found three DSP-word writers; K3 found **seven**. The
four `0x____` families above are the ones no writer has been matched to yet —
that matching is the experiment, and it needs no numerics at all.

**Second lever for `0x000` — and it caught one of my own bad controls.** I first
wrote down the test *"if `A` is an I-RAM address then `A < 384` for every
C-format word"*. **That control cannot fail**: `imm13` is 13 bits, so
`A = imm13 >> 5` is 8 bits and can never reach 384. Withdrawn before it was
quoted as evidence (P9 below). The test that *can* fail is the one against the
I-RAM range actually in use, 0..332, and it was run:

```
   68 ROM C-format words:   A = imm13>>5  spans  0..82,   >= 84:  0 of 68
   A histogram: {0:2, 7:1, 12:4, 14:1, 15:8, 20:1, 22:12, 24:1, 25:29, 29:1,
                 34:1, 37:1, 40:1, 45:1, 53:1, 76:1, 77:1, 82:1}
```

★ **Every C-format word the ROM contains has `A ≤ 82` — exactly the resident
kernel's I-RAM range — and the ONLY two C-format words in the machine with
`A ≥ 84` are the two the HOST writes at run time, whose `A` is the one thing
about this format that is settled (84 and 200, the body entry addresses).** Zero
ROM C-format word ever names a body address, although the bodies occupy I-RAM
84..332.

The replacement control **can** fail: `A` is 8 bits, so it expresses 0..255 and
any of the 68 could have named a body word in 84..255. None does.

That is a real constraint and it cuts **both** ways, so both readings are stated:

* **(I) `A` is an I-RAM address.** Supported 2/2 by the host's own `setvec`
  words, and by `hi12 == 0xC00` being **self-addressing 2 of 2** (`C00.A.47.407`
  at I-RAM 82 encodes A = 82; `C00.9.84.000` at I-RAM 76 encodes A = 76), plus
  `C16.9.AB.000` at 74 encoding A = 77 = `w77`, which is R2's independent reading
  of that word. Against: 62 of 68 would then be kernel references made from
  inside bodies that never otherwise touch the kernel.
* **(II) `imm13` is a count, not an address.** ★ `C40.3.20.44C` has
  `imm13 = 800`, and **800 samples is the ROOM REVERB pre-delay R3 derived
  independently** from the descriptor cells (`33,568 − 32,768 = 800 = 18.1 ms`).
  The other common values are equally round: 384, 480, 704. The five `0x820`
  immediates (448, 658, 786, 1111, 1201) were already read as delay offsets in
  the per-frame note §6.5 on the cycle budget.
* **(III) — and this is the reading that makes both true.** `lo12` is the
  DESTINATION, so **the destination decides the units**: `0x445`/`0x446` take an
  I-RAM address, `0x000`/`0x44C`/`0x820` may take a sample count. Under (III) the
  A ≤ 82 observation is not about addresses at all, it is just the statement that
  every ROM immediate is ≤ 2631.

**This strengthens the group-B experiment rather than replacing it**: match each
destination code to the Sub CPU routine that constructs or patches it, and the
units follow. It also argues for the finer `hi12[7:0] + lo12` key (§3.2
sensitivity), because `hi12 == 0xC00` is doing work that `lo12` is not.

### 4.3 Group C — the mode-1 space — **12 slots, 12 distinct words, 7 in the epilogue**

`class4 == 1` without the format escape. **The firmware names this space**: K3's
`LABEL_03846C` / `038539` / `038CF9` all emit the word `000.1.PP.000` followed by
a tag-**`0x15`** packet, and `LABEL_038CF9` shows the transport literally —
`DSP_DispatchCommand 1`, I-RAM address `0x0160` = 352, five word bytes, five
packet bytes. **PROVEN BY CONSTRUCTION: `000.1.PP.000` writes the tag-0x15 space
at cell `PP`.** Three of the twelve dark words are exactly that shape with hi12
bits added:

```
   I-RAM  49  400.1.0E.000   the unit-0 CALL word       PP = 0x0E
   I-RAM 153  602.1.0E.000   the unit-0 body terminator PP = 0x0E
   I-RAM 332  612.1.0F.000   the unit-1 body terminator PP = 0x0F
   I-RAM  59  400.1.0F.007   the unit-1 CALL word       PP = 0x0F,  lo12 0x007
```

★ **AN ENUMERATED ALTERNATIVE THE SEQUENCER GUESS SHOULD BE TESTED AGAINST.**
`run_frame()`'s call/return sequencer is EDUCATED GUESS G-5 and its own comment
concedes that "the MECHANISM by which the target is chosen" is unknown, because
84 and 200 are not in the word. But under the firmware's own reading `addr8` on
these words is a **cell address**, `0x0E`/`0x0F`, not a unit tag — and the host
separately loads the entry addresses through the C-format `setvec` words. So:

* **(α)** `addr8 ∈ {0x0E,0x0F}` is a hard-wired unit tag (what ships);
* **(β)** the transfer is **indirect through cell `0x0E` / `0x0F`** of the
  tag-0x15 space, which the host primes — this explains why the entries are not
  in the word *and* why they had to be host-patched into I-RAM 64/71;
* **(γ)** the unit is in `lo12` (`0x000` vs `0x007`) and `addr8` is something
  else entirely.

Note the `setvec` pair is `SRC 0x11` with ACTION `0x05` (unit 0) / `0x06`
(unit 1) — i.e. the *unit* is in the ACTION field there, which is evidence for
(γ)'s shape and against reading the unit off `addr8` twice in two encodings.
**THE TEST**: an effect whose body the host loads somewhere other than 84/200 (the
device comment already names this test), *or* — cheaper and available now — check
whether the tag-0x15 host traffic ever writes cells `0x0E`/`0x0F`, and with what.
Under (β) it must; under (α) it need not.

The remaining eight are the **output stage**, and they are the highest-value dark
words in the frame despite being few (§5): registers `0x8A, 0x8D ×2, 0x8F, 0x8C
×2, 0x85, 0x06`, carrying **seven different SRC codes `0x01..0x07`, six of which
occur exactly once in the whole 3057-word machine** (R2). A one-off source code is
not decodable by corpus statistics — it has to come from the firmware (which
register the host writes and what the user parameter is) or from hardware.
**One of them is already numerically pinned and is the cheapest live experiment
in the project**: register `0x06`/`0x86` are the unit output levels, MEASURED as
`+0.500000` (unit 0) and `+0.183992` (unit 1) at cold boot, rewritten on every
effect edit — "does the output scale by exactly those factors" is a repeatable
test with a known answer.

### 4.4 Group E — the unknown classes — **12 slots**

* `A00.0.00.041` ×4 (CHORUS) — class 0, not a register load, `SRC 0x01 / ACT 0x01`.
* `040.0.00.C63` / `142.0.00.C63` — class 0 with `lo12` bit 11 **and** the
  pointer-mode bit and `lo_mid = 4`, so three modifiers at once; `SRC 0x11`.
* `809.0.00.839` @38 — `ACT 0x19` = **capture tempA**, an anchored action, on a
  class-0 word. K3 item K measured that `0x839` is one of only two body words in
  the whole `0x_2x` selector block, so this is a rare form.
* `000.6.18.4CD` / `000.6.20.407` (class 6) and `012.4.01.1CE` ×2 (class 4) —
  ★ **a known-mathematics lever**: `012.4.01.1CE` differs from the K6 input-stage
  word `012.2.FF.1CE` in **nothing but `class4` (4 vs 2) and `addr8`**. K6 forced
  the class-2 member's addressing. A minimal pair across the class field, with one
  side forced, is the cleanest possible probe of what class 4 changes.
  `000.6.18.4CD` carries `SRC 0x13`, the INFERRED **table** source, and the
  disassembler already annotates a "table-lookup idiom, class-6 `addr8` = table
  selector".
* `980.5.20.402` @67 (class 5, epilogue) — `SRC 0x10` = the accumulator.

### 4.5 Group D — the class-0 register loads — **3 slots**

`801.0.6C.827` @43 and `801.0.64.827` @51 (selector `0x27`, per-unit payloads
`0x6C` / `0x64`) and `859.0.86.822` @77 (selector `0x22`, payload `0x86` = the
unit-1 output level register, **and it carries the bit-4 store**, which is why it
is not decoded as a register load).

Three slots is nothing; **the leverage is indirect and possibly large**. `0x827`
is a *pointer register* loaded once per unit per frame, immediately between the
C-RAM pointer and the delay-descriptor pointer, and its role is OPEN with the
D-RAM-origin candidacy retracted. **If `0x827` turns out to be the delay-DESCRIPTOR
CURSOR's base, it settles `DRAM-ADDR` — 42 slots — from 2 dark slots.** That is
the highest possible payoff per unit of work in the dark set, and it is testable:
under R3 candidate (iii) the per-unit descriptor bases differ (unit-0 bodies start
at cell `0x26`, unit-1 at `0x00`) while the *decoded* `ldptr.d` payload is `0x25`
in **both** setup blocks — R3 explicitly flags that "the same `0x25` in both
cannot produce two different bases". `0x827` is the only per-unit-parameterised
pointer in the triple that is not already spoken for. **THE TEST**: does any
affine map of `{0x6C, 0x64}` land on `{0x26, 0x00}` — and does the host's tag-0x4C
cell allocation per unit agree? Both are static, both are one pass over data
already extracted.

---

## 5. ★ CRITICAL PATH — aborts the frame vs merely unexecuted

`dark_words.py critical`. The distinction the brief asks for has not been made
before, and it needs to be made carefully, because the *obvious* version of the
question has a useless answer.

**The useless answer, stated so it can be set aside.** The shipping `clean` test
is `traps == 0 && partials == 0 && hit_wait && !overrun`. Every one of the 177
undecoded slots discards the frame, equally. The first non-decoded slot is slot
**0** and it is a PARTIAL, so **no dark word is ever the thing that first spoils a
frame**. "Which trap aborts the frame" does not discriminate.

Three questions do.

### 5.1 Does anything reach the pins? — **NO, and the dark set is why**

```
   I-RAM 72  000.1.06.087   ★ DARK      unit-0 OUTPUT LEVEL, register 0x06
   I-RAM 73  E30.C.00.404     PARTIAL   PRESENT unit 0 -> DO1 -> IC303.SDIA  (SRC 0x10 = acc)
   I-RAM 74  C16.9.AB.000   ★ DARK      C-format companion, A = 77
   I-RAM 75  82E.8.0F.000     PARTIAL
   I-RAM 76  C00.9.84.000   ★ DARK      self-addressing (A = 76 = its own address)
   I-RAM 77  859.0.86.822   ★ DARK      unit-1 OUTPUT LEVEL, register 0x86
   I-RAM 78  A3C.D.9F.287     PARTIAL   PRESENT unit 1 -> DO2 -> IC303.SDIB
```

**Both presentations are PARTIAL; both output-LEVEL words immediately preceding
them are DARK; the companion and the wait between them are DARK.** Seven of the
eleven dark epilogue slots are in this seven-word window. Two dark slots out of
86 — `w72` and `w77` — are the last gate on the audio path, and they are the only
words in the frame that apply the user's effect depth.

### 5.2 Whose fault is the wrong arithmetic? — **NOT the dark set**

A taint walk over one frame, entered clean (so every count is a LOWER bound).
A skipped word leaves stale everything it would have written; for dark words the
only writes we can name without guessing are the **anchored ACTION codes**
(`0x13`/`0x19` → tempA, `0x14` → tempB, `0x07` → the mode's destination,
`0x00` → the accumulator's adder input), applied only where `lo12` is a route —
never on a C-format word, where `lo12` is a destination, and never on a register
load, where it is a selector. (Reading an ACTION off a C-format word is exactly
the category error that made `C00.A.47.407` execute as a class-A multiply for
months.)

```
   contaminating set               DECODED slots reading stale state   first at slot
   neither                                   0 of 108                      -
   dark only  (anchored ACTION)             93 of 108                     39
   dark only  (upper bound: taint all)      98 of 108                     18
   partial only                            100 of 108                      6
   both                                    100 of 108                      6
```

★ **Decoding all 86 dark words would still leave 100 of 108 decoded slots
computing on stale state**, because the PARTIAL set contaminates them on its own,
earlier and more completely. The converse also holds. **Neither set is the
bottleneck for arithmetic correctness; both are.** This is a result that argues
*against* prioritising the dark set for its arithmetic — and *for* prioritising it
for §5.1 and §5.3, which nothing else can supply.

The six dark words that taint on their own: `809.0.00.839` (ACT 0x19 → tempA),
`880.1.60.2D4` (ACT 0x14 → **tempB**, and it is the FORCED DRAM read — so the
delay-line sample is supposed to land in tempB), and `400.1.0E.000` /
`602.1.0E.000` / `612.1.0F.000` / `880.1.60.000` (ACT 0x00 → the accumulator).

### 5.3 What can the frame never recover from? — **the delay line**

All **42** delay-DRAM accesses are dark, so the external DRAM (IC309) is **never
read and never written** in any frame. A reverb whose line is never written cannot
produce a tail no matter how correct the ALU becomes. This is the one failure in
the frame that is *structurally* out of reach of ALU decoding, and it is 48.8 % of
the dark set.

**So the honest critical-path ranking of the dark set is:**

1. the 42 delay-DRAM words — nothing else can write the delay line;
2. `w72` / `w77` — nothing else applies the output level, and they gate the pins;
3. everything else — real, but downstream of contamination the PARTIAL set
   already causes.

---

## 6. H-DIR — a direction rule for the delay-DRAM family

`dark_words.py dirtest`. Offered because `DRAM-DIR` is one of the two unknowns on
the rank-1 group.

> **H-DIR.** `SRC == 0x0B` (the delay-RAM read register) ⟺ the word is a
> delay-line **READ**. Every other SRC code is a WRITE source.

| word | SRC | H-DIR | `addr8` rule | established | source of the established value |
|---|---|---|---|---|---|
| `880.1.60.2D4` | `0B` | READ ✔ | READ ✔ | READ | R1 F1 — `read_slot` enumerated over {0,4}, slot 0 in 36/36 machines, the swap has ZERO |
| `880.1.20.655` | `19` | WRITE ✔ | WRITE ✔ | WRITE | R1 F1, same search |
| `880.1.20.2C7` | `0B` | READ ✔ | WRITE ✘ | READ | R3 §6.3 — MULTI TAP's descriptor cells `0x26/0x28/0x29/0x2A` align three tap reads here |
| `880.1.60.000` | `00` | WRITE ✔ | READ ✘ | WRITE | R3 §6.3 — the word landing on line base cell `0x2C = 0` |
| | | **4/4** | **2/4** | | |

**NON-CIRCULAR.** Neither established assignment consulted `lo12`. R1 enumerated
the read *slot* (`r1_allpass_solve.py:250`, `for read_slot in (0, 4)`) and forced
it numerically; R3 §6.3 aligned descriptor *cells* against program order. So the
SRC field's agreement is an independent check, not a restatement.

**★ THE CONTROL THAT SAYS NO.** `H-ADDR8` is scored on the same four rows and
**fails two of them**. A discriminator both rules passed would have tested
nothing; this one separates them 4–2, and the two rows where they differ are
exactly the two R3 used to falsify `addr8`.

**Status: CONSISTENT, 4 of 4 — NOT FORCED.** Four data points, and the rule is
close to a tautology *given* that SRC `0x0B` is the delay-RAM read register
(which is INFERRED, not proven: the `0x0B`-vs-`0x07` separation is 0-of-106
clean). What it really claims is stronger and more useful than a tautology:
**`DRAM-DIR` may not be a separate unknown at all — the direction may already be
readable off a field we have named.** Under it, 99 of 276 corpus delay-DRAM words
(35.9 %) are reads.

**★ AND IT COSTS THE OTHER TARGETS SOMETHING — this is the part to relay.** Four
delay-DRAM word forms carry `SRC 0x00`, the **DISPUTED** code:
`880.1.60.000` ×26, `880.1.30.000` ×12, `880.1.30.00B` ×11, `880.1.60.00B` ×3 —
**52 corpus words**. So:

* if **`SRC 0x00 = mem[ptr]`** (what SINGLE DELAY forces, 0 of 5635 for the
  alternative), H-DIR calls all 52 **writes** and **agrees with R3 §6.3** that
  `880.1.60.000` is the line write;
* if **`SRC 0x00 = the delay-RAM read`** (what the reverb requires,
  52 696/52 696), H-DIR calls all 52 **reads**, and R3 §6.3's line-write
  identification of `880.1.60.000` becomes **untenable unless that word is a
  read-modify-write**;
* or the direction is **not one bit** and some words do both.

★ **This is a THIRD context on the `SRC 0x00` contradiction, and it is not a
numeric one** — it is a *structural* consistency test between the reverb's demand
and R3's independently-derived descriptor-cell alignment. The brief asks for a
third block to separate the two readings; this is a third *constraint* on the same
question, and it is available now, with no search.

---

## 7. The remaining controls

**C2 — the blocker attribution must be total and exclusive, and must reject.**
Over the frame: dark words with no blocker **0**, decoded words with a blocker
**0**, `UNATTRIBUTED` **0**. Planted probes, each with a known answer, all five as
expected:

```
   202.A.00.1D5  DECODED  -                          the canonical mac
   202.A.00.1D0  PARTIAL  ACT-10                     ★ has a blocker and is NOT dark
   880.1.60.2D4  TRAP     DRAM-ADDR,DRAM-DIR,SRC-0B  the real DRAM read
   C40.A.80.445  DECODED  -                          setvec
   C40.A.80.444  TRAP     C-DEST-444                 ★ one destination code away, and
                                                       NOT charged a SRC/ACTION it has not got
```

The second probe is the one that earns the control: a word can carry an unknown
and still not be dark. The fifth shows the C-format guard doing work.

**C3 — leverage vs frequency** (§3.2): the top-six orders share no element;
35 of 40 unknowns have reach > 0 and sole-leverage 0.

**C4 — robustness** (`robust`): re-walked with every distinct unit-0 body in the
ROM (37 of them). Dark count **64..91 slots**, **20.0 %..30.2 %** of the frame;
group A is rank 1 by reach in **37 of 37**. The dark set is a property of the
machine.

---

## 8. Predict-then-check — including the misses

| # | prediction | result |
|---|---|---|
| P1 | the static reconstruction reproduces the live `108/91/86` | **HIT, exact** |
| P2 | the delay-DRAM group is 41 slots, matching `dsp-closure-applied.md` §5 | ★ **MISS. 42.** The published bucket loses `880.1.30.8BC`, which also carries the `lo12` bit-11 modifier and was counted in the bit-11 bucket instead. Checking further, that list's twelve buckets **sum to 179 against its own stated 177** — it is not a partition. Item E. |
| P3 | dark words are a random residue spread over all classes | ★ **MISS, and the good kind.** They are exactly `class4 ∈ {0,1,3,4,5,6,7}` plus the C format, and that is a theorem (§1). |
| P4 | the dark set is the main cause of the decoded words computing wrong values | ★ **MISS.** The PARTIAL set contaminates 100 of 108 on its own, from slot 6; the dark set 93 from slot 39. Neither is redundant. §5.2 |
| P5 | the two output presentations `w73`/`w78` are dark | ★ **MISS.** They are **PARTIAL** (class C and class D set bit 23, so the cursor fetch executes). What is dark is the pair of output-LEVEL words that immediately precede them. The corrected statement is stronger, not weaker. §5.1 |
| P6 | `SRC 0x0B` is anchored, so DRAM words carrying it need no SRC unknown | ★ **MISS.** `_ANCHORED_SRC` in both mirrors is only `{0x07,0x10,0x19,0x1A}`; `0x0B`/`0x13`/`0x1C`/`0x08` are **named** (INFERRED) but not executable. The tool now grades them `MODEL` rather than `OPEN`, which is what RANK 3 is for. |
| P7 | H-ADDR8 and H-DIR would agree on the four established rows (making the control useless) | **HIT that the control is useful**: they differ on two of four. §6 |
| P8 | some dark word moves the data pointer or coefficient cursor | **HIT, negative, and by construction**: 0 of 86. §1 |
| P9 | *(a control of my own, caught before publication)* "if the C-format `A` field is an I-RAM address then `A < 384` for every word" | ★ **THE TEST CANNOT FAIL.** `imm13` is 13 bits, so `A` is 8 bits and cannot reach 384 whatever the truth is. **Withdrawn.** Replaced by the test against the I-RAM range actually in use (0..332), which *can* fail and which returned `A ≤ 82` for 68 of 68 ROM words — see §4.2. |

---

## 9. What this pass leaves

**FORCED / PROVEN BY CONSTRUCTION**

* The dark set's boundary: `class4 ∈ {0,1,3,4,5,6,7}` or C-format, minus the 12
  K6 words (§1).
* No dark word has any modelled addressing effect — 0 of 86.
* The delay-descriptor cursor has no consumer in the model, so its per-frame
  closure has never been tested (item G).
* The mode-1 `000.1.PP.000` form is the host's own tag-`0x15` word writer
  (K3, re-used here).

**MEASURED**

* 285 = 108 + 91 + 86, reproduced statically; the per-region split; 47 distinct
  words / 46 families; the group partition summing to 86; the marginal taint
  numbers; the 37-body robustness span 64..91.
* Decoding group A alone: frame 108 → **133** decoded of 285; reverb 69 → **89**
  of 133.

**CONSISTENT, not forced**

* **H-DIR** — 4 of 4 established assignments, against 2 of 4 for the falsified
  `addr8` rule (§6).
* **`hi12 == 0xC00` is self-addressing, 2 of 2** (`C00.A.47.407` at I-RAM 82
  encodes A = 82; `C00.9.84.000` at I-RAM 76 encodes A = 76), and `w74`'s A = 77
  names `w77`, which is R2's independent reading of that word.
* **No ROM C-format word names a body address**: A ≤ 82 for 68 of 68, while the
  bodies occupy I-RAM 84..332 and the only two words with A ≥ 84 are the two the
  host writes (§4.2). Whether that is about addresses or about magnitudes depends
  on which of the three readings (I)/(II)/(III) is right.
* **`C40.3.20.44C` carries `imm13 = 800`, and 800 samples is the ROOM REVERB
  pre-delay R3 derived independently** from the descriptor cells. One
  coincidence, not a decode.

**OPEN**

* Everything in §4 that is not marked otherwise: the descriptor cursor phase; the
  four C-format destination codes; the mode-1 space and its seven one-off SRC
  codes; classes 4, 5, 6 and the class-0 non-regload forms; the role of pointer
  register `0x827`.
* Whether `addr8 ∈ {0x0E,0x0F}` on the transfer words is a unit tag (α), a cell
  address for an indirect call (β), or neither (γ) — §4.3.
* Whether the C-format `imm13` is an address (I), a count (II), or
  destination-dependent (III) — §4.2. (III) is the only one that accommodates
  both the `setvec` pair and the 800-sample coincidence.

**FALSIFIED / CORRECTED here**

* `dsp-closure-applied.md` §5's delay-DRAM bucket (41 → **42**) and its implicit
  claim to be a partition (buckets sum to 179 vs 177). The *ranking* it produced
  is not overturned — group A stays rank 1 — but the counts are not a partition
  and should not be arithmetic-ed with.
* Any expectation that `w73`/`w78` are dark (they are PARTIAL) — P5.
* Any expectation that decoding the dark set fixes the arithmetic — P4.
* **One of this note's own proposed tests**, withdrawn before it was used as
  evidence: `A < 384` cannot fail on an 8-bit field — P9.

---

## 10. What this constrains for the other two targets

1. **`SRC 0x00` (contradiction #2) gets a third constraint that needs no search.**
   Under H-DIR, `SRC 0x00` appears on 52 corpus delay-DRAM words. Reading it as
   the delay-RAM register (what the reverb demands) forces `880.1.60.000` to be a
   *read*, contradicting R3 §6.3's independently derived line-write — unless that
   word is a read-modify-write. Reading it as `mem[ptr]` (what SINGLE DELAY
   forces) makes H-DIR and R3 §6.3 agree exactly. **The delay-DRAM family is a
   context in which the two readings have different, checkable consequences, and
   it is not one of the two contexts that are already deadlocked.** §6.
2. **`ACTION 0x00` (contradiction #1) has a fourth context available in the dark
   set**: four dark words carry `ACT 0x00` — `880.1.60.000` (26 corpus copies),
   `400.1.0E.000`, `602.1.0E.000`, `612.1.0F.000`. Three of the four are the
   *transfer* words, whose control half is already modelled; if their datapath
   half is `acc ← bus`, the accumulator is written at every call and return, which
   is a strong constraint on any frame-wide accumulator model and is testable
   against the closure work.
3. **The Schroeder / nested-comb test (`sec_schroeder`) should be run with the
   delay-DRAM words as first-class participants, not as brackets.** Both of the
   motif's dark slots are the two the R1 search FORCED, and the read word's
   ACTION is `0x14` = **tempB**, so the line sample is supposed to arrive in
   tempB while the write word sources **tempA** — the shared-tempA observation the
   brief builds on has a matching, anchored destination on the read side. Any
   nested-comb model has to be consistent with *both* halves of that pair.
4. **The reverb payoff is concentrated exactly where the brief says the value
   is.** 28 of the reverb's 33 dark slots are group A. Resolving group A alone
   moves the reverb image — the 133 words in every frame of every preset — from
   51.9 % to **66.9 %** decoded, which is the largest single move available to
   anyone on this chip.
5. **A closure test exists that has never been run**: the delay-descriptor
   cursor's per-frame return. It is the same test that produced `+0` for the D-RAM
   operand pointer, it is blocked only by group A, and it can kill R3's candidate
   (iii).

---

## 11. Files

* `dsp/tools/dark_words.py` — this pass's tool; stdlib only; nine subcommands,
  four controls, each demonstrated rejecting.
* `dsp/analysis/dark-words.md` — this note.
