# ACTION 0x0B at the reverb's own sites — a discriminator at last, and it collapses six readings to three

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Date: **2026-07-27**.
No hardware. Static analysis, the ROM corpus and the two-address harness only.

**Why this note exists.** [`capture-signature.md`](capture-signature.md)
established that `ACTION 0x0B` is not a temporary-register capture and that the
statistic which would have named its destination cannot name anybody's.
[`target4.py act0b`](../tools/target4.py) had already found the first minimal
pair for the code, and said precisely what it could not do:

> **WHAT IT DOES NOT SETTLE:** what `ACTION 0x0B` writes, because nothing
> downstream in either program has been shown to read a register the two
> versions would differ in.

The reverb now supplies that reader. It became runnable this same day, when
[`cram-unit-base.md`](cram-unit-base.md) restored the per-unit C-RAM base and
the twelve 133-word images went from **0 of 33** resolved coefficients to
**33 of 33**.

Tool: [`../tools/act0b_reverb.py`](../tools/act0b_reverb.py).

```
python3 dsp/tools/act0b_reverb.py census      # the 82 sites, and the lemma
python3 dsp/tools/act0b_reverb.py wdata       # ★ the control that cannot fail
python3 dsp/tools/act0b_reverb.py partition   # six readings -> three
```

Labels: **MEASURED** / **PROVEN BY CONSTRUCTION** / **FORCED** / **CONSISTENT** /
**FALSIFIED** / **OPEN**.

---

## 0. Result

| # | statement | label |
|---|---|---|
| **A** | ★★★ **`ACTION 0x0B` WAS BEING EXECUTED AS A NO-OP, UNENUMERATED.** It has been in `action00_discriminate.step()`'s accepted-code list from the start, with **no branch in `capture()` and no parameter** — so every search that ran a word carrying it silently assumed *"no side effect"*, while `dsp_disasm._ANCHORED_ACT` **traps the same word**. Two models of one chip, disagreeing, with the disagreement written down nowhere. Method rule 3. Now `Machine.act0b`, six readings, defaulting to `"none"` — **the old behaviour exactly**, so no published number moves. | **MEASURED**, and a **FALSIFICATION** of an unstated premise |
| **B** | ★★★ **THE REVERB CAN SEE THE FIELD: 111 of 150 base machines.** Over ROOM REVERB 1's largest runnable window (`w012..w058`, 47 words, five BLOCK A instances, six `ACTION 0x0B` sites), varying only `act0b` changes the delay-port write stream in 111 of 150 machines. **This is the first discriminating site `ACTION 0x0B` has ever had.** | **MEASURED** |
| **C** | ★★★ **AND THE FIRST VERSION OF THAT EXPERIMENT WAS A CONTROL THAT COULD NOT FAIL — MINE.** At the harness **default** `wdata = "bus"` a delay write stores the operand bus, which at these sites is the delay-read register: an unmultiplied line copy the ALU never touches. The positive control (`act19`, known to change the machine) scores **0 of 150** there. My first run returned a clean-looking **0 of 200** and it was **void**. Only at `wdata = "acc"` does the control score **150 of 150**. Eleventh such catch on this chip; I had flagged this exact hazard one message before walking into it. | **MEASURED** |
| **D** | ★★★ **THE SIX READINGS COLLAPSE TO THREE.** `{none, tA<-bus, tB<-bus, tB<-acc}` are indistinguishable in **150 of 150** machines. Only **`mem<-bus`** (differs in 109/150) and **`tA<-acc`** (61/150) separate — from the group and from each other (111/150). The live question is three-way: **`none` / `mem<-bus` / `tA<-acc`**, and the shipped silent `none` is safe against three of its five rivals at these sites. | **MEASURED** |
| **E** | ★★★ **ONE OF THOSE COLLAPSES IS ARITHMETIC, NOT MEASUREMENT — AND IT GENERALISES.** All nine BLOCK A sites carry `lo12 = 0x64B`, i.e. **`SRC 0x19 = tempA`**. So the reading *"capture the bus into tempA"* writes tempA into itself: `bus = s24(st.ta)`, `st.ta = bus & MASK24 == st.ta`, the identity. `tA<-bus` and `no side effect` are **the same machine** there — not measured to be indistinguishable, **proven** to be. Corpus-wide **44 of 82** `ACTION 0x0B` words have `SRC = tempA` (16 of them non-port). | **PROVEN BY CONSTRUCTION** |
| **F** | ★★ **THE GENERAL LEMMA, worth carrying to every future ACTION search: A CAPTURE INTO THE REGISTER THE WORD IS ALREADY SOURCING IS INVISIBLE, EVERYWHERE.** Same shape as [`action00-discriminator.md`](action00-discriminator.md)'s census, where `load` and `add` coincide at `hi12[3:1] == 0`. It should be checked **before** a search, not discovered inside one. | **PROVEN BY CONSTRUCTION** |
| **G** | **THE SITE CENSUS.** 82 `ACTION 0x0B` words over the **40 distinct images**; **47 are delay-DRAM port words**, blocked by the port rather than by the ACTION, leaving **35** non-port. By source: `tempA` 44, `SRC 0x00` 25, `acc` 9, others 4. | **MEASURED** |
| **H** | **NOT APPLIED.** Three readings survive and picking between them needs known mathematics the reverb does not supply — the diffuser gains are known but there is **no reference response** to match against. Rule 6: the word keeps trapping in the disassembler. | **OPEN** |

---

## 1. What made this possible today

`ACTION 0x0B` gates **all three** reverb blocks (measured in
[`capture-signature.md`](capture-signature.md) item F): BLOCK A ×9, BLOCK B ×2.
Nothing in the reverb executes without it. But until this morning the reverb
could not be executed at all — not for want of a decode, but because
`delayline.coefs_of` never added the unit-1 C-RAM base, so all 33 coefficient
words of every reverb resolved to `None`.

The window `w012..w058` is the largest runnable one, and it exists because of
where the *other* unanchored codes fall: `ACT 0x0D`/`0x0E` at `w005`/`w006` and
`w119`/`w120`/`w130`/`w131`, and `ACT 0x1A` at `w011`, `w059` and `w101` — the
last of which is the **first word of each BLOCK B**, which is exactly why BLOCK B
still cannot run and why the runnable region splits in two.

## 2. The control, in full

```
wdata=bus   TARGET act0b seen by   0/150   |  CONTROL act19 seen by   0/150   <-- BLIND
wdata=acc   TARGET act0b seen by 111/150   |  CONTROL act19 seen by 150/150   (control OK)
```

The `bus` row is not a negative result about `ACTION 0x0B`. It is a measurement
of the instrument: with the write value taken from the operand bus, the write
stream is a copy of the delay line and **no ALU parameter whatsoever** is
observable — `act19`, whose effect is not in doubt, is equally invisible.
[`adjudication-round8.md`](adjudication-round8.md) flagged this and the default
was left at `bus`; anything that does not override it measures nothing.

## 3. Predict-then-check

- **P1 MISS, and it is item C.** I predicted the reverb sites would either
  discriminate or not, and treated the first `0 of 200` as informative. It was
  void. I had *written down* the `wdata` hazard in the previous message and
  still did not override the default until the control caught me.
- **P2 HIT.** I predicted the reverb would give `0x0B` its first discriminator.
  111 of 150.
- **P3 MISS.** I expected the six readings to separate broadly. Four of them are
  one machine, and the reason for one of the four is arithmetic I should have
  seen before running anything — the sites source the very register the reading
  writes.
- **P4 unforeseen.** I did not predict that the model already contained a
  silent, unenumerated reading of `0x0B`. That is item A, and it is the finding
  with the longest reach: it means every ALU search this project has run has
  been assuming an answer to a question it was not asking.

## 4. What the next pass needs

1. **The three-way question needs a reference, not a bigger search.** `none`,
   `mem<-bus`, `tA<-acc`. The reverb separates them; nothing yet says which is
   right. The minimal pair at algos 98/99 versus 96/97 sits immediately upstream
   of a *solved* biquad and is still the only site in the corpus with known
   mathematics on the downstream side.
2. **`ACT 0x1A` is what stands between BLOCK B and execution** — it is the first
   word of both BLOCK B instances, and BLOCK B's four multiplies now resolve.
   The same `act0b`-style enumeration applies directly.
3. **Sweep the model for other silent readings.** Item A was found by accident.
   Every ACTION and SRC code that `step()` accepts should be checked for whether
   it has an enumerated parameter or a hard-coded behaviour, and the two models
   (`step` and `_ANCHORED_ACT`) should be reconciled or their disagreement
   documented.
