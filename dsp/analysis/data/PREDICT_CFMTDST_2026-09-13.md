# PRE-REGISTRATION — the C-format immediate's DESTINATION, enumerated and swept

Written **before** the run. 2026-09-13.

## The target
C-format is now the largest entry in the queue: **68 words, every one trapping**, and `status()`
has called the operation MEASURED with the destination OPEN since it was written. 57 of the 68
obey the payload rule (`is_c40`, opcode `0x620`) and reduce to **five distinct shapes**, whose
`lo12` — the field `is_setvec` uses to pick the call-vector destination — takes four values the
vector predicate does not recognise: `0x44C` ×29, `0x000` ×16, `0x451` ×8, `0x1DA` ×2.

The destination was always *"1 of 6 enumerated"* and nobody ever ran the six.
`UPD6383_CFMTDST` = 0 latch (shipped) | 1 acc | 2 P | 3 tempA | 4 tempB | 5 mem[ptr] | 6 reg[addr8].

## Predictions

| | prediction | what it would mean |
|---|---|---|
| **H1** | the arm fires (`§109` count > 0) in every program that carries a C-format word | otherwise that program says nothing |
| **H2** | ⚠ **the sweep HAS POWER before it runs**: `acc` is known not to be inert — the site's own comment records a stuck presentation value of **4 988 928 = 2436 << 11**, exactly this line's shape. At least `mode 1` must move a census, or the instrument is blind | a blind instrument invalidates every row |
| **H3** ★ | **outcome A** — every destination leaves the censuses bit-identical ⇒ the immediate is never read and the 57 words are EXECUTABLE whatever it lands on (§96's lemma in the §108 empirical form) |
| **H4** ★ | **outcome B** — exactly one destination leaves the machine healthy while the others break a firmware/ROM criterion (the VOLUME cell, the LFO) ⇒ that one is the destination, by the §106 elimination |
| **H5** | outcome C — several differ and none is singled out ⇒ the criteria cannot separate them; the axis stays open and that is the result |

⛔ Whatever happens, this does not decode the 11 non-`is_c40` words: their payload rule is
explicitly family-local (`k3-pointers.md` §8 item 3 warns against extending it) and they are not
in the sweep's scope.


---

## RESULT — **outcome C (H5), with a 3-of-6 refutation and one large lead**
Data: [`cfmtdst_2026-09-13.txt`](cfmtdst_2026-09-13.txt). Chorus, per-program census, true default.

```
   m  dest        fired       cens md5   HAND-OFF 0x05                        LFO 07 mean step
   0  latch       0           e81a960c   177684(-2869494..3486228/chg175660)  15543.93
   1  acc         28 577 436  d6d14c1c   177684(-2869494..3486228/chg175660)  15543.93
   2  P           28 577 436  9dfca228   14(0..14/chg1)        ⛔             ★  128.30
   3  tempA       28 577 436  61de52aa   53(0..53/chg1)        ⛔                167.40
   4  tempB       28 577 436  2632d526   177684(-2869494..3486228/chg175660)  15543.93
   5  mem[ptr]    28 577 436  049052fe   45(0..45/chg1)        ⛔             LFO DEAD
   6  reg[addr8]  28 577 436  e81a960c   177684(-2869494..3486228/chg175660)  15543.93
```

**H1 ✔** (28 577 436 firings). **H2 ✔** — five of six destinations move a census, so the sweep has
power. **H3 ✗** — they are not all identical. **H4 ✗** — no single healthy survivor.
⇒ **H5, outcome C**, which the pre-registration named in advance as a result rather than a failure.

### What it settles: 6 → 4, on an anchored criterion
**`P`, `tempA` and `mem[ptr]` are REFUTED.** Each collapses the per-unit hand-off cell `0x05` from
a live ±2.9 M audio signal to a frozen 14 / 53 / 45 — and that cell is the one §76 promoted
`UPD6383_SRC0B2` on, across 8 programs. A destination that kills the input hand-off is not the
destination.

★ And **`latch` ≡ `reg[addr8]` are BIT-IDENTICAL** (one md5, `e81a960c`): writing the immediate
into the register file at `addr8` cannot be told apart from writing it to a latch nobody reads.
`acc` and `tempB` keep the hand-off but move other censuses, so the four survivors are **not** the
same machine. ⇒ **the words stay undecoded and coverage is unchanged at 77.6 %.**

### ★★ And the lead, which is bigger than the result
**`P` takes the chorus LFO from 153 Hz to 0.674 Hz** — `mean step 128.30` against the ROM's
**114**, i.e. within **12.5 %** of `floor(0.5993 × 2²³/44100)`, where the shipped model is out by
**255×**. That is the first thing all session to put the LFO in the right order of magnitude, and
§102 left exactly this open: *"the gate is not the only cause of the rate error."*

⛔ It cannot be the answer as it stands — it destroys the hand-off — but it names the path: **the
C-format immediate is implicated in the LFO rate defect.** The next pass has a specific thing to
pull on rather than a symptom.

---

## §114 — the enumeration was missing its best-motivated member, and the corpus says which

⚠ Mode 6 indexed the register file by **`addr8`**. That is the wrong half of the word:
`is_setvec(w) = is_c40(w) && is_vector_lo12(lo12(w))` — **`lo12` is what selects the destination**
on a C40 word, PROVEN (K5) for `lo12 = 0x445` / `0x446`, the per-unit CALL VECTOR registers — while
`addr8` is where the PAYLOAD lives under the same family's payload rule. Mode 7 is
`reg[lo12 & 0xFF]`, the member the enumeration should have had from the start.

★ It is not a new hypothesis: it is the sub-case the project already proved, applied to the other
four `lo12` values the corpus uses (`0x44C` ×29, `0x000` ×16, `0x451` ×8, `0x1DA` ×2).

**N1** the arm fires. **N2 ★** if mode 7 is BIT-IDENTICAL to the latch, the C40 words write a
register nothing reads ⇒ the 57 are EXECUTABLE whatever the destination is, by §96's lemma.
**N3** if it differs, it is a live destination and must then be graded against the anchored cells.
**N4** ⚠ §111's boundary: one program's null does not generalise — a pass needs several.
