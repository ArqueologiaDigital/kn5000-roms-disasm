# PTRDELTA — enumerative search for the uPD6383GF pointer-DELTA rule

NEC uPD6383GF (Technics SX-KN5000 IC311). Offline, read-only, static: ROM corpus only, no emulator.
Task set by §177 §3. Owning note: `kn7000_mame/notes/kn5000-dsp-pointer.md` (read in full first — §6
constraints, §7 corrections, §8 blind spots, §10 next steps).

Tool: `dsp/tools/ptrd_search.py`. Reproduce with

```
python3 dsp/tools/ptrd_search.py            # control + full enumeration + null
```

⚠ **The origin is NOT a variable here.** Every constraint below is a *difference* of two pointer
values inside one program image, so the per-unit origin cancels identically. "Reach for the anchor"
is a named standing bias (LEDGER rule 9); this file never touches `0x70` / `0x50`.

---

## 0. PRE-REGISTRATION (written before the search was run)

### 0.1 What is being searched

`addr8` is a signed post-increment on the data pointer (MEASURED, owning note §8 item 2). **Which
words carry one is not established.** The rule in force is *"class4 ∈ {2, 0xA} carries it"*. Since
`mode = class4 & 7` (`pat_corpus.F.mode`), `{2, 0xA}` is exactly **mode 2**, and the note's
established exclusions — classes 1/3/5/6/8 — are modes 1/3/5/6/0. So at *mode* granularity only
modes 4 (`class4 ∈ {4, 0xC}`) and 7 (`{7, 0xF}`) are still free, and the existing tool has already
tried `{2,4,A}`. **A rule expressible purely as a set of classes is therefore nearly exhausted
before the search starts** — which is the first thing the enumeration must confirm or refute.

### 0.2 Predictions, each with its falsifier

| # | prediction | falsifier |
|---|---|---|
| **R1** | **No pure class-subset rule satisfies C4.** Hand arithmetic on CHORUS's span w5..w27 gives per-class sums `{0:0, 1:+256, 2:+6, 3:+64, A:−8}`; no 0/1 combination of those is 0 except the empty one. | any non-empty subset scoring C4 |
| **R2** | The empty / near-empty rules (nothing moves the pointer) satisfy C1–C4 **and** P1, P3 **and fail P2**. P2 is what makes this test able to fail. | P2 passing for a rule whose deltas are identically zero |
| **R3** | The current rule `{2,A}` reproduces exactly: C1 miss +5, C2 +1, C3 −3, C4 −2; P1 30/38 net-zero; P2 8/8 bands at +4; P3 8/9 diffusers stationary. | any of those numbers differing → **the constraints as stated are wrong and the whole task is void** |
| **R4** | If any rule scores 7/7 it will need a **gate** (a field-level condition), not just a class set. | a 7/7 pure class subset |
| **R5** | The null is **not** negligible: with 4 numeric equalities over a space of ~10⁶–10⁷ and small integer targets, a few-percent chance rate at k=1 and a non-zero rate at k=2 is expected. Any claimed winner must beat its own score level's null by orders of magnitude. | measured null far below expectation |

### 0.3 The constraints, stated so a program can decide them

`ptr(i)` = the pointer value *at* word *i* (before its own post-increment), origin-relative.

```
  READ(prog)  = { i : hi12==0x102 && class4==2   && lo12==0x1CD }
  WRITE(prog) = { i : hi12==0x212 && class4==0xA && lo12==0x1D5 }

  C1  a05 PHASER            { ptr(i) : i in READ } == { ptr(j) : j in WRITE }
  C2  a68 S.DELAY+PHASER    same
  C3  a03 ENHANCER          same
  C4  a01 CHORUS            ptr(28) == ptr(5)
      w28 = 202.A.07.1D5 (the LFO index multiply, coefficient measured 0..24, §176)
      w5/w6/w7 = 092.A.00.200 / 082.2.00.1C0 / 094.A.00.200, the phase accumulate+read block.
      ★ all three have addr8 == 0x00, so ptr(5)==ptr(6)==ptr(7) under EVERY candidate rule --
        the target of C4 is rule-independent, which is why C4 is a clean equation.

  P1  net delta over each 3-word all-pass section == 0.  Section = a READ word i with
      hi12(w[i+1])==0x212.  38 sections over a03/a05/a68.  Require >= 30 (the current count).
  P1s all 20 READs of a05 land on ONE cell (owning note §6's HIT).  Require: true.
  P2  a39 PARAMETRIC EQ: the band marker 102.2.FF.687 repeats every 9 words; consecutive
      markers inside a channel must satisfy ptr(m+9) - ptr(m) == +4.  8 gaps.  Require: 8/8.
  P3  a16 ROOM REVERB 1: 9 all-pass markers (word == 0x104200000); net delta over the 5 words
      from the marker == 0.  Require: >= 8 of 9.
```

A rule **scores** 0–7: C1, C2, C3, C4, P1(+P1s), P2, P3.

### 0.4 The search space, and its size — stated before searching

A candidate is `(sign, S, g)`:

* `sign ∈ {signed, unsigned}` — `addr8` read as `s8()` or as `0..255`. (2)
* `S ⊆ {0..15}` — the `class4` values that carry a delta. (2¹⁶ = 65 536)
* `g` — one **gate**: an extra necessary condition on the word, drawn from a list built
  mechanically from the decoded fields (`ALL`, `cfmt`/`¬cfmt`, `b11`, `b10`, `b4`, `b7` and their
  negations, `f98 == k` / `!= k`, `f31 == k` / `!= k`, and `== v` / `!= v` for every `ACT`, `SRC`
  and `lo12` value occurring in the six probe images). Size printed by the tool.

Plus a **Tier 3** with *independent* gates for class 2 and class 0xA (the two halves of mode 2),
all other classes off: `(|G|+1)²`.

⚠ Per the owning note §5 and §177: **`hi12`-conditioned rules must be checked on the common header
too**, not only on the 38 body images — "bit 10 = END" was 38/38 on the bodies and false as a bit
meaning. The tool reports every surviving gate's behaviour over KERNEL + EPILOGUE.

⚠ Population: algorithms 79/88/89/90/91 are IC310/MN19413 programs and are excluded by
`pat_corpus` (`MALFORMED`). No statistic here mixes the two chips.

---

*(results follow, appended after the run)*
