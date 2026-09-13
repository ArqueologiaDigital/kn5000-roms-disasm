# PRE-REGISTRATION — `UPD6383_CLS46PTR`: do classes 4 and 6 post-increment the pointer?

Written **before** the run. 2026-09-13.

## The claim under test
`dsp/tools/class_twins.py`, over the **pooled** KN5000 + SX-WSA1R corpora (same uPD6383 ISA,
7558 occurrences of 1129 distinct non-C-format words):

* the minimal pair `dark-words.md` §4.4 asked for exists, and the KN5000 corpus does not contain
  it — **`012.2.01.1CE`** (WSA1R `eff54_pitch_shifter`, **DECODED**) against **`012.4.01.1CE`**
  (99 occurrences, 53 KN5000 + 46 WSA1R), identical in `hi12`, `addr8` **and** `lo12`;
* that same program is the only one in either product spelling the `C63` macro in class 2
  throughout (`142.0.00.C62 | 022.2.1B.4CD | 092.2.01.1CE | 184.2.FF.1CE`), and the two spellings
  agree on a net pointer displacement of **+27** only if classes 4 and 6 carry the delta. Under the
  shipped model they differ by **25 cells** and the class-2 spelling is an outlier three times
  beyond the whole class-4/6 range (−14..+9).

## The arm
`UPD6383_CLS46PTR=1`, default OFF. Classes 4 and 6 post-increment `m_dp` by `(s8)addr8`, exactly
as class 2 does. Nothing else changes.

**Blast radius, MEASURED before the run:** 106 KN5000 words (53 class 4, 53 class 6), **all of them
inside the one macro**, and **zero** in the resident kernel or the output stage — checked: `kernel`
and `epilogue` carry no class-4 or class-6 word. So every effect's shared input and output path is
untouched by construction.

## Predictions, in advance

| | prediction | what a miss means |
|---|---|---|
| **P1** | the gate FIRES: `§100 CLS46PTR (ON)` count > 0, and ≈ 4 per frame in the chorus (2 class-4 + 2 class-6 words) | the run says nothing; discard it |
| **P2** ★ | **the modulated tap starts reading audio.** §99 measured the chorus's two class-4 taps reading cells holding **0** and **39 718** while the live audio cells in the same census run to ±2.9 M. PASS = the operand `L` at BOTH `00124011CE` rows of the traced frame is audio-scale, `\|L\| > 100 000` | the arm moves the pointer somewhere no better; the macro is still not reading the delay line and the decode gains nothing observable |
| **P3** | ⚠ RULE 13: P2 is not "something changed". The cell each tap lands on must also be one the D-RAM census reports **MOVING** (`chg` ≫ 1), not a new constant | a large constant is not a signal |
| **P4** | CONTROL THAT CAN FAIL — **no regression**: over the 10-program catalogue sample at the TRUE DEVICE DEFAULT, the per-unit hand-off cell `0x05` must stay non-zero and un-railed wherever it already is. ONE broken program blocks promotion (§56 shipped a regression this way once) | the arm is a trade, not a decode |
| **P5** | UPSTREAM NULL: the input latches `0x01`/`0x04` and the kernel's own cells must be **unchanged**, since no kernel word carries class 4 or 6 | the arm is doing something other than what it claims; the measurement is void |
| **P6** | RULE 12: the traced frame has notes playing — input cells non-zero and moving | not a test |

## What a pass would and would not settle
★ A pass would make `addr8` on classes 4 and 6 the SAME pointer delta it is on class 2, which is a
DECODE of the addressing half of **106 KN5000 words** and retires `§98`'s "index-like, not
delta-like" inference (that inference was drawn before the WSA1R twin was in hand and the 0 %
zero-rate is explained by the macro never wanting a zero delta).

⛔ It would **not** decode the words. `012.4.01.1CE` would still owe its **store target** on a mode
the store rule never adjudicated (the rule separates mode 1 from mode 2; modes 4 and 6 were never
in its sample), and the 46 class-6 `4CD` words would still owe `SRC 0x13`. The 7 class-6 `407`
words would be the ones the addressing alone completes.

⛔ And it would not say what `class4` bit 2 is FOR. If `addr8` means the same and the store means
the same, bit 2 must do something else — the standing candidate is the indexed/table access the
`C63` head sets up, which is a separate question.

## Counter-evidence on file, stated before the run
`closure_pointer.py variants` row **V12** (classes 4 and 6 move, class 8 does not): residue **+179**,
unit-0 pool **15 distinct nets** against the baseline's 8, and it does not close the frame. That is
mild counter-evidence and it is recorded here rather than discovered afterwards. ⚠ Its force is
limited: `closure-pointer.md` item F **falsified the closure criterion's own premise**, item B
already measured that the pool is not constant (8 nets over 37 images), and item G's rejections
were at **29 and 31** distinct nets, not 15.


---

## Run 1 — **P1 MISS, and the run is discarded** (recorded, not hidden)

```
   §100 CLS46PTR (ON): class-4/6 pointer advances performed: 0
```

and the traced frame, the D-RAM census and the two tap rows were **bit-identical** to the control.
⛔ **The arm never fired**, so the run says nothing about the claim — which is exactly what P1 was
written for, and the second time this session that a gate has caught an arm that could not reach
its target (§97 was the first, on someone else's experiment; this one is mine).

**Cause:** the pointer post-increment is performed at the END of `exec_alu()`
(`if ((cl & 7) == 2) m_dp = u8(m_dp + dd);`), the one site that runs for every word. The two sites
a `grep` for the `m_dp = u8(m_dp + s8(addr8(word)))` spelling finds are
`exec_addressing_only()` — the twelve K6 whitelist words — and a copy inside `exec_decoded()`'s
**nop branch**. I patched those two and not the one that matters.

★ The general rule, and it is the same one §97 states from the other side: **a fired count is not
a formality.** Run 2 patches the real site; the predictions above are unchanged and were not
edited.


---

## Run 2 — **P1 HALF-hit: the arm reached class 4 and not class 6.** Also discarded.

```
   §100 CLS46PTR (ON): class-4/6 pointer advances performed: 3 150 504
```

**3 150 504 = exactly 2 per frame**, and the chorus carries **four** words of these classes (2
class-4, 2 class-6). P1 predicted ≈ 4 per frame. ⇒ only the class-4 half fired, and the trace
confirms it: with the arm on, `dp` at the two `00124011CE` rows advances `0C→0D` and `0F→10`,
while the class-6 rows (`00006184CD`, `0000620407`) leave it where it was.

**Cause:** `exec_alu()` has a dedicated `if (cl == 6) { ... }` branch — the §162 probe and the
class-6 table-lookup diagnostic — and it **returns** before the post-increment at the end of the
function.

★ **A non-zero fired count is still not the count you predicted.** P1 was written as "> 0, and ≈ 4
per frame in the chorus" precisely so half an arm would not read as a whole one; had it said only
"> 0" this run would have been graded, and it tests half the hypothesis.

For the record, what the half-arm did to P2: the operand `L` at the two class-4 taps went `0`/
`39 718` → `0`/`1`. That is not evidence against the claim — the pointer post-increments, so a
class-4 word's own read is unaffected by its own advance, and with class 6 frozen the two words
walk out of step. Run 3 adds the advance inside the class-6 branch.


---

## Run 3 — **P1 HIT, P5 HIT, P2 FAIL** ([`cls46ptr_run3_2026-09-13.txt`](cls46ptr_run3_2026-09-13.txt))

```
   §100 CLS46PTR (ON): class-4/6 pointer advances performed: 6 301 008      = exactly 4 per frame
```

**P1 HIT.** And the walk is exactly what the static argument predicts — the chorus's first macro
instance, with the arm on:

```
   n=80  0040000C63  dp 0C
   n=81  00006184CD  dp 24     0x0C + 0x18
   n=82  00124011CE  dp 25     +1
   n=83  01042021CE  dp 27     +2      ⇒ net +27 over the macro, the predicted value
```

**P5 HIT — the upstream null holds exactly.** The kernel's cells are bit-identical to the control:
`01`, `04`, `05`, `06`, `07` all unchanged, including the per-unit hand-off `05:177684
(-2869494..3486228/chg175660)`. The blast radius is what was measured before the run.

**⛔ P2 FAIL.** The operand `L` at the two class-4 taps is still `0` and `1`. The cells they read
moved (`0x0C`→`0x24`, `0x0E`→`0x47`) and the new cells carry the same tiny self-written values
(`24: -17..19`, `47: -33..39`). The tap is relocated, not aimed.

### ⚠ AND P2 WAS NOT A FAIR TEST — my error, and it was knowable in advance
§97, written two hours earlier, established that the macro's head (`C63`) carries `lo12` bit 11 and
**leaves `exec_alu()` before the SOURCE stage, 3 150 504 times a run**. So the index the macro is
built around **is never delivered**. The tap's address is `pointer + (index that never arrives)`;
moving the pointer alone can relocate it but cannot aim it. **P2 required the index to be present
and the arm does not supply one — a criterion that could not succeed**, which is the same defect
as a control that cannot fail, seen from the other side.

⇒ **P2's miss is not evidence against the claim.** It is evidence that the addressing half cannot
be graded on audio until the bit-11 head is decoded. What P2 *did* earn: it is now on record that
relocating the tap changes nothing audible, so nobody re-runs this expecting sound.

### Verdict
**NOT PROMOTED.** The static case (the cross-corpus twin; the two spellings agreeing at +27) is
strong and the arm reproduces the predicted walk to the cell; but one pre-registered criterion
failed, its failure is explained rather than excused, and the remaining criterion — P4, the
10-program regression at the true default — is what decides whether the arm may stay as a
default-off decode or must be reverted.
