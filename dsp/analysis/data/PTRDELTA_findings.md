# PTRDELTA — enumerative search for the uPD6383GF pointer-DELTA rule

NEC uPD6383GF (Technics SX-KN5000 IC311). Offline, read-only, static: ROM corpus only, no emulator.
Task set by §177 §3. Owning note: `kn7000_mame/notes/kn5000-dsp-pointer.md` (read in full first — §6
constraints, §7 corrections, §8 blind spots, §10 next steps).

Tools: `dsp/tools/ptrd_search.py` (tiers 1–4 + localisation), `dsp/tools/ptrd_perform.py` (tier 5).
Reproduce with

```
python3 dsp/tools/ptrd_search.py       # ~6 s, stdlib only
python3 dsp/tools/ptrd_perform.py      # ~20 min, node-capped
```

⚠ **The origin is NOT a variable here.** Every constraint below is a *difference* of two pointer
values inside one program image, so the per-unit origin cancels identically. "Reach for the anchor"
is a named standing bias (LEDGER rule 9); this file never touches `0x70` / `0x50`.

---

## ★ HEADLINE

1. **★★★ THE SEARCH IS EXHAUSTIVE AND THE ANSWER IS NEGATIVE. Over 21 364 736 rules
   (class-subset × field-level gate, both sign conventions), plus 26 896 per-class-gate rules and
   13 366 gate conjunctions, **NOT ONE non-degenerate rule satisfies C1, C2 or C3 — not jointly,
   not even individually. Zero of 6 088 704.** MEASURED, exact counts, no sampling.
2. **★★★ AND C3 HAS A TWO-LINE IMPOSSIBILITY PROOF THAT NEEDS NO SEARCH AT ALL.** a03's second
   bank runs from its last chain read to its modulator write over five words, of which exactly two
   have a non-zero `addr8`: `102.2.4D.1CD` (+77) and `212.A.B0.412` (−80). C3 demands
   `77x − 80y = 0` with `x, y ∈ {0,1}`; `gcd(77,80)=1`, so the only solution is `x = y = 0` — both
   forms inert, i.e. the phaser chain does not walk. The first bank gives `67x − 70y = 0`, same
   conclusion. **FORCED.** The difference between the banks lives in the `addr8` *values*, which no
   field-based rule can see.
3. **★★★ P1's "8 chain-terminal exceptions" AND C1–C3's misses ARE THE SAME EIGHT WORDS.** The
   owning note records "30 sections net-zero with the 8 chain-terminal exceptions" as a
   *reproduction* and the +5/+1/−3 misses as a *failure*. They are one defect: in every one of the
   three images the non-zero P1 sections are exactly the `102.2.**.1CD` / `212.A.**.412` pairs that
   terminate a bank, and in a03 that pair *is* the whole −3 miss. **MEASURED** (§5 below).
4. **★★ THE ONLY RULE IN THE WHOLE SPACE THAT BEATS THE CONTROL NON-DEGENERATELY SCORES 4/7** —
   `class4 ∈ {2,0xA}` with the gate `lo12 ≠ 0x1C0`, i.e. **the form `012.2.**.1C0` does not
   post-increment**. It fixes C4 exactly and keeps P1/P2/P3 intact. Its null is **0.77 %** of
   non-degenerate rules that keep P1&P2&P3, so it is a ~130× enrichment, not a proof — and it has a
   stated cost (§6.2): it scatters a03's chain reads over four cells spanning −132…+15.
5. **★★ THE FIRST RUN'S "7/7" WERE ALL VACUOUS, AND I REPORT THAT FIRST.** Four Tier-3 rules score
   7/7 — and all four freeze the pointer in the four constraint images, so C1–C4 read `0 == 0`.
   30.9 % of the whole Tier-1+2 space scores 6/7 the same way. LEDGER rule 8 ("a criterion that
   cannot fail is not a test") is what caught it; the non-degeneracy filter N was added *after* the
   first run and every number below is reported with and without it.
6. **★ THE KNOWN-ANSWER CONTROL PASSED**, exactly, before anything else ran: C1 +5, C2 +1, C3 −3,
   C4 −2; P1 30/38; P1s true; P2 8/8; P3 8/9. So the constraints as stated in §177 are right and
   nothing downstream is void on that account.

---

## 0. PRE-REGISTRATION (written and committed before the search was run — commit `c89ebef`)

### 0.1 What is being searched

`addr8` is a signed post-increment on the data pointer (MEASURED, owning note §8 item 2). **Which
words carry one is not established.** The rule in force is *"class4 ∈ {2, 0xA} carries it"*. Since
`mode = class4 & 7` (`pat_corpus.F.mode`), `{2, 0xA}` is exactly **mode 2**, and the note's
established exclusions — classes 1/3/5/6/8 — are modes 1/3/5/6/0. So at *mode* granularity only
modes 4 (`class4 ∈ {4, 0xC}`) and 7 (`{7, 0xF}`) are still free, and the existing tool has already
tried `{2,4,A}`. **A rule expressible purely as a set of classes is therefore nearly exhausted
before the search starts** — which is the first thing the enumeration must confirm or refute.

### 0.2 Predictions, each with its falsifier — and how each turned out

| # | prediction | falsifier | verdict |
|---|---|---|---|
| **R1** | **No pure class-subset rule satisfies C4.** Hand arithmetic on CHORUS's span w5..w27 gives per-class sums `{0:0, 1:+256, 2:+6, 3:+64, A:−8}`; no 0/1 combination of those is 0 except the empty one. | any non-empty subset scoring C4 | **CONFIRMED.** Tier 1 ∧ N: C4 satisfied by **0** of 65 536 |
| **R2** | The empty / near-empty rules satisfy C1–C4 **and** P1, P3 **and fail P2**. P2 is what makes this test able to fail. | P2 passing for a rule whose deltas are identically zero | **CONFIRMED, and it was worse than predicted** — P2 *can* be passed vacuously too, by a rule that moves the pointer *only* in the PEQ image. Hence N (§3.3) |
| **R3** | The current rule `{2,A}` reproduces exactly: C1 +5, C2 +1, C3 −3, C4 −2; P1 30/38; P2 8/8; P3 8/9. | any of those numbers differing → **the task is void** | **CONFIRMED exactly** (§1) |
| **R4** | If any rule scores 7/7 it will need a **gate**, not just a class set. | a 7/7 pure class subset | **VACUOUSLY CONFIRMED** — no 7/7 anywhere except the four degenerate Tier-3 rules |
| **R5** | The null is not negligible; a claimed winner must beat its score level's null by orders of magnitude. | measured null far below expectation | **CONFIRMED, dramatically.** 30.9 % of Tier 1+2 scores 6/7 by chance. The 6/7 bucket is worthless |

### 0.3 The constraints, stated so a program can decide them

`ptr(i)` = the pointer value *at* word *i* (before its own post-increment), origin-relative.

```
  READ(prog)  = { i : hi12==0x102 && class4==2   && lo12==0x1CD }
  WRITE(prog) = { i : hi12==0x212 && class4==0xA && lo12==0x1D5 }

  C1  a05 PHASER            { ptr(i) : i in READ } == { ptr(j) : j in WRITE }
  C2  a68 S.DELAY+PHASER    same
  C3  a03 ENHANCER          same
  C4  a01 CHORUS            ptr(28) == ptr(5)
      ★ w5/w6/w7 all have addr8 == 0x00, so ptr(5)==ptr(6)==ptr(7) under EVERY candidate rule --
        C4's target is rule-independent, which is what makes it a clean equation.

  P1  net delta over each 3-word all-pass section == 0.  38 sections over a03/a05/a68.  >= 30.
  P1s all 20 of a05's chain reads land on ONE cell (owning note §6's HIT).
  P2  a39 PEQ: consecutive band markers 102.2.FF.687, 9 words apart, ptr(m+9) - ptr(m) == +4.  8/8.
  P3  a16 ROOM REVERB 1: 9 all-pass markers (word == 0x104200000); net over the 5 words from the
      marker == 0 in >= 8 of 9.
```

⚠ Population: algorithms 79/88/89/90/91 are IC310/MN19413 programs and are excluded by
`pat_corpus` (`MALFORMED`). **No statistic here mixes the two chips.** Corpus = 38 distinct body
images + the 60-word KERNEL + the 23-word EPILOGUE, matching every note in this series.

---

## 1. THE CONTROL — the current rule reproduces EXACTLY (**MEASURED**)

```
  C1  a05 PHASER           READS [6]        WRITES [11]       miss +5   [abs, origin 0x70: 76 vs 7B]
  C2  a68 S.DELAY+PHASER   READS [6]        WRITES [7]        miss +1   [abs: 76 vs 77]
  C3  a03 ENHANCER         READS [14, 15]   WRITES [11, 12]   miss -3   [abs: 7E,7F vs 7B,7C]
  C4  a01 CHORUS           consumer w28 at +0   producer w5/6/7 at +2   miss -2

  P1  3-word all-pass sections net-zero : 30 of 38
  P1s a05's 20 chain reads on ONE cell  : True
  P2  a39 bands advancing exactly +4    : True  (8 gaps)
  P3  a16 diffusers stationary          : 8 of 9
  N   distinct pointer cells a03/a05/a68: [31, 32, 25]  (need >= 8/20/10)  -> non-degenerate

  CONTROL SCORE 3/7      R3: PASS
```

Every number in §177's constraint list is reproduced to the digit, including the absolute cells
`0x76` / `0x7B` / `0x7E,0x7F` under the note's own origin. **The constraints as stated are right;
nothing downstream is void on that account.**

---

## 2. THE SEARCH SPACE, AND ITS SIZE (stated before searching)

A candidate is `(sign, S, g)`:

* `sign ∈ {signed, unsigned}` — `addr8` read as `s8()` or as `0..255`.
* `S ⊆ {0..15}` — the `class4` values that carry a delta. 2¹⁶ = 65 536.
* `g` — one **gate**: an extra necessary condition on the word, built mechanically from the decoded
  fields: `ALL`; `cfmt`/`b11`/`b10`/`b7`/`b4` and their negations; `f98 == k` / `!= k` (k=0..3);
  `f31 == k` / `!= k` (k=0..7); and `== v` / `!= v` for **every** `ACT`, `SRC` and `lo12` value
  occurring in the six probe images. **|G| = 163.**

| tier | what | size |
|---|---|---|
| **1** | `sign × S`, gate = `ALL` | **131 072** |
| **2** | `sign × S × g` (tier 1 is the `g = ALL` slice) | **21 364 736** |
| **3** | independent gates for class 2 and class 0xA, other classes off | **26 896** |
| **4** | classes `{2,A}` with a **conjunction** of two gates | **13 366** |
| **5** | one free bit per distinct `(hi12, class4, lo12)` **form** | **2⁷⁶ ≈ 7.6 × 10²²** |

**Tier 5 strictly contains tiers 1–4**, because every gate predicate is a function of `hi12`,
`class4` and `lo12`. It is the *maximal* rule space that decides from the word's fields without
reading `addr8` itself. It is searched by DFS in `ptrd_perform.py` (node-capped — see §4.3).

*Exactness*: a class whose gated delta is zero at every word of every probe image cannot move any
pointer, so all subsets differing only in such classes behave identically. The tool enumerates the
active classes and multiplies the counts back up. **The distributions below are exact counts over
the full space, not samples.**

---

## 3. THE SCORE DISTRIBUTION, AND THE NULL

### 3.1 Raw (**and this is the part that must not be read on its own**)

```
    score |  TIER 1 = 131 072 rules   |  TIER 1+2 = 21 364 736 rules
    ------+---------------------------+------------------------------
      0   |     16 384   12.5000 %    |     1 429 504    6.6910 %
      1   |     61 440   46.8750 %    |     5 611 520   26.2653 %
      2   |     32 768   25.0000 %    |     3 561 472   16.6699 %
      3   |     10 240    7.8125 %    |     1 173 504    5.4927 %
      4   |      6 144    4.6875 %    |     1 552 384    7.2661 %
      5   |      2 048    1.5625 %    |     1 435 648    6.7197 %
      6   |      2 048    1.5625 %    |     6 600 704   30.8953 %   <-- 30.9 % BY CHANCE
      7   |          0    0.0000 %    |             0    0.0000 %
```

> **A rule scoring 6 of 7 is worth nothing: 30.9 % of the space does it.** That is R5 confirmed and
> it is the reason the raw table is useless without §3.3.

### 3.2 Per-criterion hit rate — the per-criterion null

```
          | all rules                      | non-degenerate only
    C1    | t1  3.125 %   t1+2  39.379 %   | t1  0.000 %   t1+2  0.0000 %
    C2    | t1  3.125 %   t1+2  38.133 %   | t1  0.000 %   t1+2  0.0000 %
    C3    | t1 12.500 %   t1+2  45.399 %   | t1  0.000 %   t1+2  0.0000 %
    C4    | t1  6.250 %   t1+2  42.312 %   | t1  0.000 %   t1+2  4.9109 %
    P1    | t1 75.000 %   t1+2  81.442 %   | t1 50.000 %   t1+2 37.168 %
    P2    | t1  6.250 %   t1+2   2.607 %   | t1 12.500 %   t1+2  9.149 %
    P3    | t1 50.000 %   t1+2  74.847 %   | t1 50.000 %   t1+2 59.065 %
```

The left column is the whole story of why the raw table lies: **C1–C4 are each satisfied by
38–45 % of the space** — because 71.5 % of the space freezes the pointer somewhere and `0 == 0`.

### 3.3 ★ THE SAME DISTRIBUTION, NON-DEGENERATE ONLY

**N (non-degeneracy)** — *not pre-registered; added after the first run, and this is the honest
record of that.* The first run returned four 7/7 rules and 6.6 million 6/7 rules, all of which
**freeze the pointer** in the four constraint images. `0 == 0` is a criterion that cannot fail.

> **N**: each phaser image must get at least as many **distinct pointer cells** as it has all-pass
> sections — a03 ≥ 8, a05 ≥ 20, a68 ≥ 10 (that is exactly P1's 38-section population). An
> *n*-section all-pass chain needs *n* distinct one-sample state cells; a rule that gives it fewer
> is not describing the machine. The control passes with [31, 32, 25].

```
    non-degenerate rules:  tier 1  65 536 of 131 072 (50.00 %)
                           tier 1+2  6 088 704 of 21 364 736 (28.50 %)

    score |  TIER 1 & N               |  TIER 1+2 & N
    ------+---------------------------+------------------------------
      0   |     16 384   25.0000 %    |     1 429 504   23.4780 %
      1   |     28 672   43.7500 %    |     2 881 536   47.3259 %
      2   |     16 384   25.0000 %    |     1 501 184   24.6552 %
      3   |      4 096    6.2500 %    |       274 432    4.5072 %   <-- the CONTROL lives here
      4   |          0    0.0000 %    |         2 048    0.0336 %   <-- the entire non-vacuous yield
      5   |          0    0.0000 %    |             0    0.0000 %
      6   |          0    0.0000 %    |             0    0.0000 %
      7   |          0    0.0000 %    |             0    0.0000 %
```

Tier 3 and Tier 4 add nothing: Tier 3 & N tops out at 4/7 (126 rules of 15 264), Tier 4 & N at
4/7 (50 of 4 354). **The ceiling of the entire searched space, non-degenerately, is 4 of 7.**

### 3.4 Which subsets of {C1,C2,C3,C4} are jointly reachable at all

```
    {C4}   reachable -- best example: classes {2,A}, gate lo12!=1C0, signed  (score 4/7)
    {}     reachable -- the control

    largest jointly-reachable subset of C1..C4 under N:  1 of 4
```

**C1, C2 and C3 are individually unreachable.** Not "not jointly" — *individually*, by any rule in
21 364 736, in either sign convention, that lets the phaser have as many state cells as it has
sections.

---

## 4. THE BEST CANDIDATE, AND THE NULL THAT ACTUALLY APPLIES TO IT

### 4.1 The rule

```
  RULE PTRD-A :  delta applies iff  class4 ∈ {2, 0xA}   AND   lo12 ≠ 0x1C0
                 lo12 0x1C0 = SRC 0x07 (mem[ptr]) + ACT 0x00 (no action), so the reading is
                 "a word that fetches an operand but performs NO ACTION does not post-increment".
                 Census of lo12 == 0x1C0 over the whole corpus (MEASURED):
                    082.2.**.1C0   64 words, addr8 == 0 in ALL of them   -> gate is a no-op here
                    012.2.**.1C0   33 words in 20 images, addr8 -14 .. +78  <- the gate's content
                    002.2.05.1C0    1 word,  +5
                    kernel: 012.A.00.1C0 (+0), 084.2.01.1C0 (+1), 092.A.01.1C0 (+1)   <- see §7

  C1 a05 PHASER          READS [6]                   WRITES [11]        MISS  (unchanged, +5)
  C2 a68 S.DELAY+PHASER  READS [6]                   WRITES [7]         MISS  (unchanged, +1)
  C3 a03 ENHANCER        READS [-132,-54,-53,15]     WRITES [-135,-56]  MISS  (WORSE, see 4.2)
  C4 a01 CHORUS          consumer +2   producer +2   ★ OK
  P1 30/38   P1s TRUE   P2 8/8 TRUE   P3 8/9   N cells [31, 32, 25]  NON-DEGENERATE
```

The per-image arithmetic for C4: CHORUS's span w5…w27 sums, per class, to
`{0:0, 1:+256, 2:+6, 3:+64, A:−8}` → `{2,A}` gives **−2**, which is the measured miss. The single
word `w17 = 012.2.FE.1C0` contributes **−2** of the class-2 total; removing it makes the span
exactly **0** and the consumer lands on the producer's cell. **That is the whole mechanism.**

Supersets `{2,4,A}`, `{2,6,A}`, `{2,4,6,A}` with the same gate also score 4/7 but **break P1s**
(a05's reads split into two cells), so PTRD-A is the unique best member of the family.

### 4.2 The null that actually applies

The control already has P1 & P2 & P3; the *only* thing PTRD-A adds is C4. So the right null is:
**among non-degenerate rules that keep P1 & P2 & P3, how many also satisfy C4?**

```
    tier 1   :   4 096 keep P1&P2&P3 & N ;      0 of them satisfy C4  =  0.000 %
    tier 1+2 : 266 240 keep P1&P2&P3 & N ;  2 048 of them satisfy C4  =  0.769 %
```

**PTRD-A beats its own null by ~130× — enrichment, not proof.** And it carries three stated costs
that should be weighed against it:

1. **a03 ENHANCER's chain reads go from two adjacent cells `[14,15]` to four cells spanning
   `[-132 … +15]`**, because the same form `012.2.**.1C0` carries `+68` and `+78` in a03 where it
   carries `−2` in CHORUS. A pointer excursion of −132 is outside any 256-cell window that also
   holds +15.
2. **The gate is not local to CHORUS.** `012.2.**.1C0` occurs 33 times across **20 of the 38 body
   images**, with `addr8` from −14 to +78. Turning it inert moves the pointer in every one of them.
3. **It silences two kernel words** (I-RAM 8 and 37) — harmless *if* the dispatch model is right,
   which is INFERRED and not measured. See §7.1.

**INFERRED (weak): PTRD-A is a local repair for CHORUS with global collateral.** It is the best
thing in 21 million rules and it is still not good.

### 4.3 Tier 5 — the maximal field-based space

```
  distinct forms with a non-zero addr8 over the six probe images : 76      (space = 2^76)

  C1  a05 PHASER          27 free forms   >= 1 896 form-rules satisfy C1
  C2  a68 S.DELAY+PHASER  28 free forms   >=   496 form-rules satisfy C2
  C3  a03 ENHANCER        30 free forms   >= 8 240 form-rules satisfy C3
      forms appearing in more than one of the three images : 21
      rules satisfying C1 AND C2 AND C3 simultaneously     : 0
```

⚠ **The DFS hit its 3 000 000-node cap on all three images**, so the per-image solution sets are
**lower bounds** and the joint zero is *evidence*, not proof. What *is* proof is §5's arithmetic,
which reaches the same conclusion for C3 without any search at all — and every C3 solution the DFS
did find has `102.2.**.1CD`, `104.2.**.1D5` and `212.2.**.412` all **OFF**, i.e. the a03 all-pass
idiom inert, exactly as §5 forces.

---

## 5. ★ LOCALISATION — where each miss is MADE (**MEASURED**), and the proof for C3

```
  C1  a05 PHASER          reads [6]       writes [11]
      P1: 20 sections, 2 NON-ZERO, at w39 and w98, nets [-2, +9]
         w39  102.2.4E.1CD  +78      w98  102.2.58.1CD  +88
         w40  212.A.B0.412  -80      w99  212.A.B1.412  -79
      write w52 at +11 ; last preceding read w39 at +6 ; span +5
         w39 102.2.4E.1CD +78   w40 212.A.B0.412 -80   w43 092.2.0A.700 +10
         w44 104.A.FB.1D5  -5   w49 104.2.02.1CE  +2

  C2  a68 S.DELAY+PHASER  reads [6]       writes [7]
      P1: 10 sections, 2 NON-ZERO, at w38 and w98, nets [-2, +9]
      write w53 at +7 ; last preceding read w38 at +6 ; span +1
         w38 102.2.49.1CD +73   w39 212.A.B5.412 -75   w41 000.2.09.407  +9
         w43 202.A.01.415  +1   w45 204.A.FB.1D5  -5   w50 104.2.FE.1CE  -2

  C3  a03 ENHANCER        reads [14,15]   writes [11,12]
      P1: 8 sections, 4 NON-ZERO, at w15/w32/w63/w79, nets [-3, -3, -3, -3]
      write w38 at +12 ; last preceding read w32 at +15 ; span -3
         w32 102.2.43.1CD +67   w33 212.A.BA.412 -70
      write w84 at +11 ; last preceding read w79 at +14 ; span -3
         w79 102.2.4D.1CD +77   w80 212.A.B0.412 -80
```

### 5.1 The unification (**MEASURED**)

**P1's eight "chain-terminal exceptions" and C1–C3's three misses are the same eight words.** In
every image the non-zero P1 sections are exactly the `102.2.**.1CD` / `212.A.**.412` pairs that
terminate a bank, and in a03 that pair *is* the entire miss. The owning note §6 reports the 30/38
as a *reproduction* and the +5/+1/−3 as a *failure*; they are one defect with one location. That is
new, and it is the most transferable thing in this file.

### 5.2 ★ THE TWO-LINE IMPOSSIBILITY PROOF FOR C3 (**FORCED**)

a03's second bank runs from its last chain read (w79) to its modulator write (w84) over five words,
of which exactly **two** carry a non-zero `addr8`:

```
    w79  102.2.4D.1CD   +77      x = does this FORM carry a delta?
    w80  212.A.B0.412   -80      y = does this FORM carry a delta?
    w81  104.2.00.000     0
    w82  026.2.00.000     0
    w83  000.A.00.415     0
```

C3 requires `77x − 80y = 0` with `x, y ∈ {0,1}`. `gcd(77,80) = 1`, so **the only solution is
x = y = 0**. The first bank independently gives `67x − 70y = 0`, same conclusion. With `x = y = 0`
the phaser's chain-read form and its bank-exit form are both inert, and the exhaustive search
confirms that no such rule satisfies C3 non-degenerately either.

**Why this generalises to every rule in tiers 1–5:** any rule that decides from the word's *fields*
must treat all four occurrences of a form alike, and the four occurrences differ **only in
`addr8`** (67/70, 77/80, 73/76, 63/66). The information that would distinguish them is exactly the
field the rule is deciding *about*. **A field-based delta rule is structurally incapable of
satisfying C3.**

---

## 6. WHAT THIS IMPLIES — which assumption to drop

The task's own escape clause applies: *"if no rule in the space can satisfy C1–C3 simultaneously,
the space is wrong and you should say which assumption to drop."* Ranked, most likely first.

### 6.1 ★ A4 — the producer/consumer identification for C1–C3 is the weakest link. **DROP THIS ONE FIRST.**

C1–C3 come from `-axes.md` §2.4, which the owning note grades **INFERRED**, and §6 flags the
mismatch itself. Four independent things now point at the premise rather than the arithmetic:

* **C4 is reachable and C1–C3 are not.** C4's consumer is pinned *independently of any addressing
  claim* — §176 measured its coefficient as `0..24`, the index scale `lfo-ramp.md` designed. C1–C3
  have no such anchor. When the anchored constraint is satisfiable and the unanchored ones are
  provably not, the unanchored ones are the suspects.
* **Under the current rule both of a05's modulator writes land on the SAME cell (+11)** — two LFO
  blocks writing one gain cell, the second clobbering the first every sample. a03 by contrast has
  two writes on two cells. A shared all-pass gain written twice per sample is not a phaser.
* **`212.A.**.1D5` has `b4 = 1` (store) and `lo12 = 0x1D5` = `SRC 0x07 / ACT 0x15`** — the same
  `ACT 0x15` family the register already reads as the **delay-tap modulation register** path
  (§153/§156). A *register* target is not a D-RAM cell and would not have to equal any read
  pointer, which would make C1–C3 not constraints at all.
* The 8 words that make the misses are the *chain-terminal* ones — the bank exits — which is where
  a second addressing mechanism (bank base, cursor reload) would naturally live.

### 6.2 A2 — one pointer. **Live, and it explains the residue's shape.**

Owning note §8 item 4: *"The chip has six (CP/DP/BP1/BP2/PR1/PR2)."* If the `102.2.**.1CD` chain
reads and the `212.A.**.1D5` modulator writes address **different** pointer registers, then
"their addresses must be equal" is not a statement about one Σ and the whole comparison is
ill-posed. This is the assumption that most economically explains a residue that is *systematic*
(always at the bank exit) yet *per-image variable* (−2/−2/−3).

### 6.3 A1 — `addr8` is the delta. **Weakened but not dropped.**

P2 (+4 per band, 8/8) and P1 (30/38) both survive across the whole search and both are pure `addr8`
arithmetic. `addr8` really is a signed post-increment for the mode-2 words; the question is only
*which* words and *onto which register*.

### 6.4 What is NOT the problem

* **Not the origin.** Every constraint is a difference; the origin cancels. Confirmed by
  construction in every tier.
* **Not the class set.** Tier 1 ∧ N satisfies *none* of C1–C4 in 65 536 rules; adding modes 4 and 7
  (`{2,4,A}`, `{2,6,A}`, `{2,4,6,A}`) only breaks P1s.
* **Not the sign convention.** `unsigned` is enumerated throughout and contributes nothing.
* **Not the header/body split.** §7 below.

---

## 7. HEADER VALIDATION (the owning note §5 warning, discharged)

*"bit 10 with bit 11 clear = END OF PROGRAM" was measured 38/38 on the bodies and falsified as a bit
meaning — the header carries it 14 times in 60 words.* Every `hi12`-conditioned gate is therefore
reported over KERNEL (I-RAM 0..59) and EPILOGUE (60..82) as well:

```
    gate ALL       KERNEL 60/60 pass, 39 with non-zero addr8 | EPILOGUE 23/23 pass, 20 non-zero
    gate cfmt      KERNEL  8/60,  8 non-zero                 | EPILOGUE  3/23,  3 non-zero
    gate b11       KERNEL 20/60, 19 non-zero                 | EPILOGUE 10/23,  9 non-zero
    gate b10       KERNEL 22/60, 12 non-zero                 | EPILOGUE  4/23,  3 non-zero
    gate f98==3    KERNEL  0/60                              | EPILOGUE  0/23
```

### 7.1 ★ AND THE HEADER CHECK CAUGHT SOMETHING — on the winner itself

My first draft of this section said *"PTRD-A's gate is not `hi12`-conditioned and the header
contains no `0x1C0` word at all, so it is header-neutral by construction."* **That was wrong, and
running the census is what caught it** (thirteenth instance of trap #3, caught before it shipped):

```
    KERNEL   (I-RAM 0..59):  3 words carry lo12 == 0x1C0
                 I-RAM  8   084.2.01.1C0   addr8 +1   -> class 2, SILENCED by PTRD-A
                 I-RAM 35   012.A.00.1C0   addr8 +0   -> the gate changes nothing
                 I-RAM 37   092.A.01.1C0   addr8 +1   -> class A, SILENCED by PTRD-A
    EPILOGUE (I-RAM 60..82):  0 words

    the per-unit pointer loads sit at I-RAM 42/43/44 (unit 0) and 50/51/52 (unit 1)
```

**PTRD-A removes two `+1` post-increments from the common header — and BOTH of them (I-RAM 8 and
37) sit BEFORE the per-unit pointer loads at 42 and 50.** Under the dispatch model (owning note §2)
the pointer is reloaded from `801.0.70.821` / `801.0.50.821` after them, so their contribution is
discarded before either body runs and PTRD-A is header-neutral *in effect*.

> ⚠ **But that neutrality is inherited from the dispatch model, which is INFERRED, not measured**
> (owning note §8 item 6: *"the dispatch model has no falsifier yet"*). If the pointer is not
> reloaded per unit — closure-pointer.md §4.1's package A — the header's `−2` reaches both bodies
> and PTRD-A's absolute prediction changes from "consumer moves 5 → 7" to "consumer and producer
> meet at 5". **Both arms are still two-sided, but §8.2 must log which one it is.**

My first draft of this section said *"the header contains no `0x1C0` word at all, so PTRD-A is
header-neutral by construction."* **That was wrong on the census and right by accident on the
conclusion, and running the census is what caught it** — thirteenth instance of trap #3, caught
before it shipped. The general lesson is the owning note's own §5, discharged again: **a rule
validated on the 38 body images has not been validated until it has been run over the 83
header/stub words that every body-scoped corpus statistic excludes by construction.**

---

## 8. ⇒ THE EMULATOR EXPERIMENT, WITH A TWO-SIDED CRITERION

Two experiments, in the order they should be run. Both are cheap and both can fail.

### 8.1 ★ PTRD-E1 — **decide §6.1 first.** Does anything ever READ the cell the modulator writes?

This is the experiment that decides whether C1–C3 are constraints at all, and it costs one traced
run of the *already shipped* build — no gate, no new decode.

* **Vehicle**: clean cold boot (`scratchpad/coldnotes2.lua`), CHORUS, notes after ~19 s, mask
  `0x1910E446A39B440F`. LEDGER rule 2 and rule 12 (a DSP test with no notes playing is not a test).
* **Instrument**: in `upd6383_device`, for each frame record (a) the D-RAM cell index written by
  the `212.A.**.1D5` words, and (b) for every word in the frame, the cell index it *reads*. Count
  frames in which some word reads a cell that a `212.A.**.1D5` word wrote in the same frame.
* **Arm A (premise alive)**: the written cell has ≥ 1 reader in the same frame, in ≥ 99 % of frames.
  ⇒ the modulator really does fill a D-RAM cell that is consumed; C1–C3 are real constraints and the
  defect is in §6.2 (which pointer) rather than §6.1.
* **Arm B (premise dead)**: the written cell is read by **no** word, in ≥ 99 % of frames.
  ⇒ `212.A.**.1D5` is not feeding a D-RAM consumer; **C1–C3 are void as constraints**, the owning
  note §6's "MISS" is a mis-specified comparison, and the pointer-delta rule is no longer the
  binding unknown. This is a *retraction-grade* outcome and it is the one this file predicts.
* **The control that can fail**: the same instrument must show that the *CHORUS delay-tap* writes
  (the `ACT 0x15` path §156 shipped) DO have readers. If neither has readers the instrument is
  broken and the run is void.
* ⚠ Pre-register the *relation between two counters*, never the literal frame total (LEDGER rule 5).

### 8.2 PTRD-E2 — the C4 fix, A/B, only if E1 comes back Arm A

* **Change**: gate the delta on `lo12 != 0x1C0` behind one new `m_specmask` bit (rule PTRD-A).
* **Vehicle**: same clean cold boot, CHORUS.
* **PASS arm (pre-registered)**: at §176's per-site row `0202A071D5`, `m_dp` moves from **5** to
  **7**; `L` stops being identically 0 at that site; and the class-6 lookup's index
  (`000.6.18.4CD`) stops being constant — which is precisely the K2 unblock §176 §3 predicted, and
  makes the reverb discriminator **226, not 240**.
* **FAIL arm**: `m_dp` stays 5, or lands anywhere other than 7.
* **The control that can fail**: PEQ (algo 39) must be **bit-identical** — P2 says the biquad's +4
  walk is untouched by this gate, so any change to the a39 band cursor means collateral damage and
  the run is void. Select PARAMETRIC EQ (§127's vehicle) and compare the coefficient-cursor trace.
* **The falsifiers this file already knows about, and they must be pre-registered with the run**:
  (a) a03 ENHANCER's chain reads scatter to `[-132,-54,-53,15]` under this gate — if ENHANCER's
  pointer leaves D-RAM in the trace, PTRD-A is refuted even if the CHORUS arm passes;
  (b) §7.1 — the gate silences two `+1` kernel words at I-RAM 8 and 37. Both precede the pointer
  loads at 42/50, so under the dispatch model their effect is discarded; **log the pointer at the
  two unit terminators (I-RAM 49 and 59) in both arms to confirm it.** If they differ between arms
  the reload is not happening, the header's `−2` reaches the body, and the expected landing cell is
  **5, not 7** — score the run against that instead of calling it a FAIL. (This log is also the
  dispatch model's first falsifier, which the owning note §8 item 6 has been owed since it was
  written.)

---

## 9. GRADES

| claim | grade |
|---|---|
| The control reproduces §177's C1–C4 and P1–P3 exactly | **MEASURED** |
| No non-degenerate rule in 21 364 736 satisfies C1, C2 or C3, individually or jointly | **MEASURED** (exhaustive, exact counts) |
| C3 is unreachable by *any* field-based rule (`77x − 80y = 0`, `gcd = 1`) | **FORCED** |
| P1's 8 exceptions and C1–C3's misses are the same 8 words | **MEASURED** |
| The four 7/7 rules found are vacuous (frozen pointer) | **MEASURED** |
| PTRD-A (`{2,A}` ∧ `lo12 ≠ 0x1C0`) is the unique best non-degenerate rule, 4/7 | **MEASURED** |
| PTRD-A beats its own null (0.769 %) by ~130× | **MEASURED**, and explicitly *not* a proof |
| PTRD-A damages a03 (reads scatter to 4 cells, −132…+15) | **MEASURED** |
| Tier 5 finds no joint C1∧C2∧C3 rule | **MEASURED but INCOMPLETE** (node cap; a lower bound) |
| §6.1 — the C1–C3 producer/consumer premise is the assumption to drop | **INFERRED (strong)** |
| §6.2 — the six-pointer alternative | **SPECULATIVE**, and named as such |

### 9.1 SPECULATION, kept separate

Nothing in §1–§5 or §7 is speculative. §6.1 and §6.2 are readings, offered because §8.1 decides
between them with one traced run. The reading I would bet on — and it is only a bet — is that
`212.A.**.1D5` writes a **register**, not a D-RAM cell, in which case the owning note §6's headline
"the phaser's shared cell now has an address, and its partner misses" is comparing a D-RAM address
against a register selector, and the pointer-delta rule was never the thing that was wrong.
