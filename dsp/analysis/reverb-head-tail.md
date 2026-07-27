# THE HEAD AND THE TAIL OF THE REVERB — the output section is a stereo early-reflection mixer, and it confirms the pipeline from a site no search had used

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Date: **2026-07-27**.
No hardware. Static analysis of the Sub CPU ROM, the 100 canned parameter
streams, the 38 distinct body images and `bounds.py`'s descriptor
classification only.

Labels: **MEASURED** / **PROVEN BY CONSTRUCTION** / **FORCED** / **CONSISTENT** /
**INFERRED** / **FALSIFIED** / **OPEN**.

Answers **TARGET 4** of round 7 — tasks A (the reverb head and tail), B (the 48
trapping C-format cells), C (ACTION 0x0B), D (the rotation `G`). Builds on
[`dram-datapath.md`](dram-datapath.md), [`dram-bounds.md`](dram-bounds.md),
[`dram-unit-cursor.md`](dram-unit-cursor.md),
[`dram-matching.md`](dram-matching.md) and
[`adjudication-round5.md`](adjudication-round5.md); adjudicates published claims
in three of them.

Tool: [`../tools/target4.py`](../tools/target4.py). **Every number below comes
out of it.**

```
python3 dsp/tools/target4.py tail       #  1 ★★★ TASK A -- the two output tails
python3 dsp/tools/target4.py head       #  2 ★★  TASK A -- the input section
python3 dsp/tools/target4.py ertaps     #  3 ★★★ TASK A/B -- the six ER taps, L/R
python3 dsp/tools/target4.py align      #  4 ★★★ TASK B -- the consumer predicate
python3 dsp/tools/target4.py anchor     #  5 ★★★ TASK B -- the host-anchor forcing
python3 dsp/tools/target4.py shift      #  6 ★★  TASK B -- the off-by-one, enumerated
python3 dsp/tools/target4.py direction  #  7 ★★★ TASK B -- READ versus WRITE
python3 dsp/tools/target4.py act0b      #  8 ★★★ TASK C -- the decidability census
python3 dsp/tools/target4.py rotation   #  9 ★★  TASK D -- the ceiling, G, the wrap
python3 dsp/tools/target4.py rivals     # 10     RULE 7, scored on disagreement
python3 dsp/tools/target4.py control    # 11 ★★★ every control, saying NO *and* YES
python3 dsp/tools/target4.py predict    # 12     PREDICT-THEN-CHECK, hits AND misses
python3 dsp/tools/target4.py all        # ~40 s

python3 dsp/verify.py                   # BYTE-MATCH OK
```

**NOTHING IS APPLIED.** Neither disassembler mirror is edited, no MAME source is
touched, `dsp/verify.py` reports **BYTE-MATCH OK**, and the 42 delay-DRAM frame
slots — the four C-format words among them — still trap. Method rule 6: the
direction result below is CONSISTENT, not FORCED, so it does not ship.

---

## 0. Result in one page

**POPULATIONS (rule 9), stated once.** 91 IC311 algorithms ship descriptor
cells; 83 are aligned under the incumbent predicate and carry 829 cells; 40
distinct body images (38 IC311 + 2 DSP2-misparsed); ROOM REVERB 1 is **one**
133-word image serving algos 16..27 byte for byte, so the twelve reverbs give
**twelve independent descriptor value sets against one word sequence**, and every
"of 12" below means that.

| # | statement | label |
|---|---|---|
| **A** | ★★★ **THE REVERB'S TAIL IS TWO MIRRORED OUTPUT TAILS, AND EACH MIXES THREE EARLY REFLECTIONS.** `w111..w121` and `w122..w132` are the same eleven-word template — **11 of 11 positions agree in `lo12`, the operand routing** — consuming C-RAM `0xA9..0xAC` and `0xAD..0xB0`, which the committed listing already names LEFT and RIGHT output tail and the host names **op-0x66 / ER.LEVEL**. Each block owns three delay-DRAM port slots (`w111 w112 w114` and `w122 w123 w125`) and four coefficients: three early reflections plus the tank. | **MEASURED** (§1) |
| **B** | ★★★ **AND THE TAIL CONFIRMS THE ONE-DEEP PIPELINE FROM A SITE NO SEARCH HAD USED — WITHOUT A SOLVER, A DELAY LINE OR A SINGLE COEFFICIENT VALUE.** Under `dram-datapath.md` item A the datum standing in the read register at each of those six slots is `0x18 0x19 0x1A | 0x1B 0x1C 0x1D`; under a BLOCKING read it is `0x19 0x1A 0x1B | 0x1C 0x1D 0x1E`. Scored **only on the sites where the two disagree**: the pipelined grouping gives **24 of 24** rising tap triples and **72 of 72** cells inside the pre-delay buffer; the blocking grouping gives **0 of 24** and **60 of 72**, because the RIGHT channel's third "early reflection" would be the out-of-region flush address `32767`. | **MEASURED**; `land = −1` **FALSIFIED at this site** (§1) |
| **C** | ★★★ **THE CONSUMER PREDICATE IS NOT EXCEPTIONLESS, AND THE TWO C-FORMAT FORMS BEHAVE OPPOSITELY.** With the C format counted: **83 of 91** aligned, and the four COMPRESSOR-bearing algorithms are misaligned by *exactly* their two `C40.1.E0.451` words. Without it: **75 of 91**, and the twelve reverbs are misaligned by *exactly* their four `C40.1.80.000` words. The form split — `C40.1.80.000` consumes, `C40.1.E0.451` does not — is the **only** assignment that aligns all sixteen, gives **87 of 91**, and leaves a residue of exactly four algorithms that are all one family (FLANGER, ENSEMBLE, S.DELAY+FLANGER, PEQ+FLANGER). | **MEASURED**; the split **FORCED for `C40.1.80.000`** (item D), **OPEN for `C40.1.E0.451`** (§4) |
| **D** | ★★★ **`C40.1.80.000` DOES CONSUME A DESCRIPTOR CELL — FORCED, within the printed enumeration, and by a route that uses no instruction semantics at all.** If it does not, the reverb's last three class-1 words shift back four cells and **the CEILING cell `0x1E` is never walked, in 12 of 12** — so `CEILING = the LAST READ of its program`, exceptionless at **83 of 83**, would fail for 12 of 83. The end-anchored alternative loses cell `0x00`, the one cell a T2 record writes every time the player turns PRE DELAY, in **12 of 12**. Enumeration E1..E5 printed in §5. | **FORCED** within the enumeration (§5) |
| **E** | ★★ **THE HOST ANCHOR LEG IS WEAKER THAN IT LOOKS AND IS REPORTED AS SUCH.** Under the "does not consume" reading the pre-delay tap still pairs with its host-anchored base in **7 of 12** presets, not 0 — the tail write lands below the pre-delay reads only in five of the twelve canned parameter sets. **The anchor argument alone is not a forcing**, and item D does not rest on it. | **MEASURED**, a leg deliberately downgraded (§5) |
| **F** | ★★★ **THE FOUR TRAPPING CELLS ARE EARLY-REFLECTION TAPS 2 AND 3 OF THE LEFT AND RIGHT OUTPUT CHANNELS.** The six cells `0x18..0x1D` split `{0x18,0x19,0x1A}` / `{0x1B,0x1C,0x1D}` exactly as the two output tails consume them, and the split is visible in the *values*: `cell 0x18 / cell 0x1B = 1.2006 ± 0.0032` across **twelve independently canned presets** — the L/R decorrelation ratio, one design quantity, not two. All **84 of 84** pre-delay taps (12 presets × 7) lie strictly inside the pre-delay buffer. | **MEASURED** (§3) |
| **G** | ★★★ **DIRECTION = READ. Three legs, no direct measurement of the word, and therefore NOT applied.** (1) The residue rule: under READ the reverbs join the other 61 aligned algorithms at `{CEILING 1, LIMIT 1}` (**81 of 83**); under WRITE they take a residue of **five bound cells** that occurs **nowhere else in the corpus** (11 of 12 at five, 1 at four). (2) Under WRITE, **47 of the 48** cells open a delay line that is never read — four canned, differently-sized, permanently-unread buffers per preset. (3) The tail (item A/B). (4) The host reservation, shift-corrected (item H). **H_W FALSIFIED; H_R CONSISTENT, STRONGLY; the four words keep trapping.** | **H_W FALSIFIED**; **H_R CONSISTENT** (§7) |
| **H** | ★★ **THE T1 OFF-BY-ONE IS NOW AN ENUMERATION, NOT AN INFERENCE — AND THE RESERVATION IS PROVABLY WRONG UNDER EVERY PHASE.** Over shifts `[−4, +4]` applied identically to entries 1..6 of `T1[0x67] = [0x00, 0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E]`, a uniform **−1** makes all six valid pre-delay taps in all twelve presets — **72 of 72**, the unique maximum (60, 60 at ±0 and the neighbours). And no phase `δ` can rescue the reservation, because entry `0x1E` holds the *value* `32767` in 12 of 12 and a phase moves which word touches a cell, never the cell's value. **PREDICT-THEN-CHECK HIT:** the 37 live op-0x67 reservations outside the reverbs' dead branch land on a non-ADDRESS cell **0 times**. | the shift **FORCED** within `[−4,+4]`; the reservation's error **FORCED** (§6) |
| **I** | ★★★ **TASK C: ACTION 0x0B IS NOT DECIDABLE FROM ANY OF THE THREE PROGRAMS THE BRIEF NAMES — AND IT *IS* DECIDABLE, AT FOUR SITES THE BRIEF DID NOT EXPECT.** PARAMETRIC EQ contains **zero** ACTION 0x0B words; SINGLE DELAY's three and the kernel's three are all delay-DRAM port words; AUTO PAN has none. Of the **85** ACTION 0x0B words corpus-wide, **50** are DRAM port words (blocked by the port, not by the ACTION) and **35** are not. Ranked by decoded downstream context, the top four are MULTI TAP DELAY `w025` and `02A.2.4B.00B` at the head of PEQ+DIST+DELAY, PEQ+OVERDR+DELAY and PEQ+COMPRESSOR. | **MEASURED** (§8) |
| **J** | ★★★ **AND THE TOP TWO GIVE THE FIRST MINIMAL PAIR ANYONE HAS FOUND FOR ACTION 0x0B.** The eight words after PEQ+DIST+DELAY `w001` are **byte-identical** to a window occurring **ten times inside PARAMETRIC EQ** — the SOLVED biquad. Censusing the slot immediately before that window over the whole corpus (**27** occurrences): `02A.2.4B.00B` (ACTION `0x0B`) ×2 and `02A.2.4B.000` (ACTION `0x00`) ×1 — **identical in `hi12`, `class4`, `addr8` and `SRC`, differing in the ACTION field alone**, in the same structural slot, in front of the same decoded arithmetic. That bounds ACTION 0x0B (it cannot disturb the biquad's `mem[ptr]` input path) and poses the experiment. | **MEASURED** (§8) |
| **K** | ★★ **TASK D: `dram-unit-cursor.md` §5(b) READING (2) IS FALSIFIED BY `dram-datapath.md` §2.1, AND NEITHER NOTE NOTICED.** Both surviving limit-register readings die on the same one-line argument the datapath note already made against its own E2: *a limit must be loaded before the accesses it bounds, and this cell is the LAST READ of its program in 83 of 83.* **Reading (3), the sentinel, stands alone.** | **FALSIFIED / FORCED** within the printed 3-member enumeration (§9) |
| **L** | ★★ **AND THAT SEVERS THE CEILING CELLS FROM THE `G` QUESTION ENTIRELY — a constraint withdrawn before it was used.** If the ceiling is the address of a *discarded* read, `(cell + G) mod 2^N` is thrown away whatever `G` is, so the ceiling cells carry no information about the rotation and must come out of any future constraint set for it. What §9 *does* add: unit 0's address cells stop **118** words short of its region top and unit 1's stop **636** short — so a single free-running `G` modulo `2^16` would corrupt the other unit after **118 frames = 2.68 ms**. Three options enumerated, none decided. | **MEASURED**; `G` **OPEN** (§9) |
| **M** | ★ **A CONTROL OF MINE THAT COULD NOT PASS, PRINTED RATHER THAN REWRITTEN.** My first TASK B instrument was a FLUSH-ADJACENCY test (*"the flush read must sit right after the last real tap, so the word before the CEILING must be a READ"*). The corpus says the word before the CEILING is a **WRITE in 60 of the 71** unambiguous algorithms. The test has no power at all and is used nowhere above. | **PREDICT-THEN-CHECK MISS** (P2, §11 C4) |
| **N** | ★ **NOTHING BECOMES EXECUTABLE. 0 of 42 delay-DRAM frame slots.** The four C-format words still trap and this note keeps them trapping on purpose. `dsp/verify.py`: **BYTE-MATCH OK**. | **MEASURED** |

**Predictions: 10 made, 3 hits, 6 misses, 1 partial. Two of the misses (P9, P10)
are the round's biggest results.**

---

## 1. ★★★ TASK A — the tail

`python3 dsp/tools/target4.py tail`

**POPULATION:** one image, 133 words, 32 cells; ×12 presets for every value.

The tail splits into three blocks, and the last two are the same eleven-word
template with two C-format words glued on the front:

```
   w101..w110   separator #3 + damping triple #3  (C-RAM 0xA5..0xA8), DRAM w105 -> cell 0x18
   w111,w112    C-format,  cells 0x19 and 0x1A
   w113..w121   LEFT  OUTPUT TAIL (C-RAM 0xA9..0xAC = op-0x66 ER.LEVEL), DRAM w114 -> cell 0x1B
   w122,w123    C-format,  cells 0x1C and 0x1D
   w124..w132   RIGHT OUTPUT TAIL (C-RAM 0xAD..0xB0 = op-0x66),          DRAM w125 -> cell 0x1E
```

```
      w111  C40.1.80.000       w122  C40.1.80.000       IDENTICAL
      w112  C40.1.80.000       w123  C40.1.80.000       IDENTICAL
      w113  000.2.FE.407       w124  000.2.FB.407       same lo12
      w114  880.1.20.2D5       w125  880.1.20.2D5       IDENTICAL
      w115  282.A.00.000       w126  282.A.00.000       IDENTICAL
      w116  000.A.0C.452       w127  000.A.FF.452       same lo12
      w117  212.A.F5.1D5       w128  212.A.04.1D5       same lo12
      w118  202.A.FC.1D5       w129  202.A.FA.1D5       same lo12
      w119  202.2.08.1CD       w130  202.2.7B.1CD       same lo12
      w120  090.2.FB.40E       w131  880.1.60.40E       same lo12
      w121  212.2.05.000       w132  612.1.0F.000       same lo12
   -> 11 of 11 word positions agree in lo12.
```

Only `addr8` — the pointer displacement — differs, which is exactly what two
copies of one circuit operating on two I-RAM regions look like. The last two
positions carry the extra jobs the program can only do once: the RIGHT block's
`0x40E` word is *also* the delay-DRAM write of line 11's base, and its `0x000`
word is *also* the END-OF-BLOCK.

### 1.1 ★★★ The pipeline, arrived at from the output section

The seven tail port slots in issue order and the datum standing in the read
register when each subsequent slot executes:

```
   cell 0x18 (+650 ) issued w105 -> standing at w111   LEFT
   cell 0x19 (+1084) issued w111 -> standing at w112   LEFT
   cell 0x1A (+1625) issued w112 -> standing at w114   LEFT
   cell 0x1B (+540 ) issued w114 -> standing at w122   RIGHT
   cell 0x1C (+975 ) issued w122 -> standing at w123   RIGHT
   cell 0x1D (+1082) issued w123 -> standing at w125   RIGHT
   cell 0x1E (32767) issued w125 -> discarded          the flush
```

**THE TEST, SCORED ONLY ON DISAGREEMENT SITES (rule 7).** The two readings
differ only in which triple `0x1B` and `0x1E` fall into. Population 12 presets ×
2 channels = 24 triples, 72 cells:

| grouping | triples RISING in consumption order | cells inside the pre-delay buffer |
|---|---|---|
| **PIPELINED** | **24 of 24** | **72 of 72** |
| **BLOCKING** | **0 of 24** | **60 of 72** |

Under the blocking read the RIGHT channel's third early reflection is `32767`,
which the region test puts **outside unit 1's own DRAM**. This is an independent
leg for `dram-datapath.md` item A that uses no ALU search, no coefficient value
and no part of the descriptor bank except the region test — and it is the second
time `land = −1` has been refuted, the first being the re-attribution in
`dram-datapath.md` §3.1.

**AND THE ENCODING SAYS IT TOO.** Both tail read words are `880.1.20.2D5`, whose
`lo12` carries `SRC 0x0B` — the anchored delay-RAM **read register**. A word that
*sources the read register while issuing a fetch* is a one-deep pipeline written
down. 24 such words over the 91 algorithms; every one is a READ.

### 1.2 What is still open in the tail

Four coefficients per channel, three early reflections per channel; the fourth
coefficient is the tank. Which coefficient multiplies which tap is **INFERRED,
not measured** — only `w117/w118` and `w128/w129` are decoded (`mac (p),c+`), and
they name `mem[ptr]`, not `SRC 0x0B`, so the route from the read register into
the mixer is still the open question. `w115/w126` (`282.A.00.000`) and
`w116/w127` (`000.A.xx.452`) are the two undecoded coefficient consumers and are
the next words to attack.

---

## 2. ★★ TASK A — the head

`python3 dsp/tools/target4.py head`

```
   w000  880.1.30.00B  READ cell 0x00 -- the PRE-DELAY tap, the ONLY cell any T2
                       record writes; op-0x67 operand 0, BASE24 = 32770 = cell 0x03 + 2
   w001  ld acc,(p)-119
   w002  mac (p),c+  C-RAM[0x90]  \
   w003  mac (p),c+  C-RAM[0x91]   >  THE INPUT MIX -- three input gains
   w004  mac (p),c+  C-RAM[0x92]  /
   w005  202.2.4B.1CD
   w006  000.2.00.40E
   w007  mac (p),c+  C-RAM[0x93]  \
   w008  mac acc,c+  C-RAM[0x94]   >  DAMPING FILTER #1
   w009  mac (p),c+  C-RAM[0x95]  /
   w010  mac.st acc,(p)+0
   w011  880.1.60.2DA  WRITE cell 0x01 = 45464 -- the PRIME (below unit 1's floor)
   w012  ld tb,c+  C-RAM[0x96] = DRAM tap gain 0.500
   w015  880.1.20.64B  READ cell 0x02 -- the first ladder tap
```

So the reverb's **first word reads the user's pre-delay** and its input mix is
three gains followed by damping filter #1 — the whole signal path in, decoded to
the level the coefficient map already supports.

**THE ONE NEW OBSERVATION.** The pair `[lo12 0x1CD, lo12 0x40E]` occurs three
times in this image, and those are **all three** of its `0x1CD` words:

```
   w005 202.2.4B.1CD  +  w006 000.2.00.40E   HEAD
   w119 202.2.08.1CD  +  w120 090.2.FB.40E   LEFT  output tail
   w130 202.2.7B.1CD  +  w131 880.1.60.40E   RIGHT output tail  <- and THIS 0x40E word IS the DRAM WRITE
```

In the RIGHT tail the second member of the pair *is* the delay-DRAM write, so
`lo12 0x40E`'s operation is independent of whether the word also drives the port
— what a horizontal microword predicts, and one line for the next pass's
enumeration. Corpus-wide `0x1CD` is followed by `0x40E` in **79 of 152**
occurrences over the 40 distinct images, so this is a strong local idiom and a
weak global one; both numbers are printed. **CONSISTENT, NOT FORCED.**

---

## 3. ★★★ TASK A/B — the six early reflections

`python3 dsp/tools/target4.py ertaps`

Offsets in samples off cell `0x03`, the host-anchored pre-delay base:

```
   algo name               0x00    | LEFT  0x18  0x19  0x1A  | RIGHT 0x1B  0x1C  0x1D
   16   ROOM REVERB 1      800     |   650  1084  1625       |   540   975  1082
   17   ROOM REVERB 2       20     |   934  1560  2340       |   780  1403  1558
   18   PLATE REVERB 1     2000    |  1866  2418  3479       |  1558  2205  3014
   19   PLATE REVERB 2     2000    |  1866  3118  4079       |  1558  2805  3114
   20   CONCERT REVERB 1    500    |  1866  3118  4079       |  1558  2805  3114
   21   CONCERT REVERB 2   1000    |  2487  4148  4827       |  2077  3738  4148
   22   DARK REVERB 1      2000    |  1245  2080  3121       |  1039  1871  2077
   23   DARK REVERB 2      2000    |  1866  2918  3879       |  1558  2405  2814
   24   BRIGHT REVERB 1    1000    |  1245  2080  3121       |  1039  1871  2077
   25   BRIGHT REVERB 2    1000    |  1866  3118  4679       |  1558  2805  3114
   26   WAVE REVERB 1      2000    |  2487  4149  6227       |  2077  3738  4149
   27   WAVE REVERB 2      2000    |  3109  5186  7784       |  2596  4673  5186
```

```
   LEFT   0x19 / 0x18 : min 1.2958  max 1.6710  median 1.6702   (n=12)
   LEFT   0x1A / 0x18 : min 1.8644  max 2.5075  median 2.5037   (n=12)
   RIGHT  0x1C / 0x1B : min 1.4153  max 1.8056  median 1.8004   (n=12)
   RIGHT  0x1D / 0x1B : min 1.8062  max 2.0037  median 1.9987   (n=12)
   CROSS  0x18 / 0x1B : min 1.1974  max 1.2037  median 1.1977   (n=12)
```

The within-channel ratios are near-constant with named exceptions (PLATE REVERB 1
and DARK REVERB 2 are the two presets that break them, and they break *both*
channels together, which is what a per-preset design change looks like). The
**cross-channel** ratio is `1.2006 ± 0.0032` — **0.3 % across twelve
independently canned parameter sets**. Two numbers that track that closely across
twelve presets are one design quantity: the L/R decorrelation of the early
reflection cluster. **MEASURED.**

And `84 of 84` (12 presets × 7 taps) lie strictly inside the pre-delay buffer —
the four trapping cells included, in every preset.

---

## 4. ★★★ TASK B — the consumer predicate is part of the model (rule 11)

`python3 dsp/tools/target4.py align`

`dram_cursor.is_consumer` — *class4 == 1 with the `hi12` format-escape bit* — is
a **hypothesis** about which words drive the descriptor cursor, and every
descriptor result in this project rests on it. Its own source comment says the
reverbs' counting identity *requires* the C format to consume. Nobody had asked
what that costs elsewhere.

**POPULATION: all 91 IC311 algorithms that ship descriptor cells.**

| variant | aligned | misaligned |
|---|---|---|
| **V1** C-format CONSUMES (the incumbent) | **83 of 91** | 4, 6, **36**, 66, 73, **75**, **96**, **97** |
| **V2** C-format does NOT consume | **75 of 91** | 4, 6, **16..27**, 66, 73 |
| **V3** SPLIT: `C40.1.80.000` consumes, `C40.1.E0.451` does not | **87 of 91** | 4, 6, 66, 73 |
| **V4** TWIN (the deliberately-wrong mirror image) | **71 of 91** | all twenty |

There are exactly two C-format consumer forms and each lives in exactly one
family:

```
   C40.1.80.000  x48   the twelve reverbs, four each
   C40.1.E0.451  x8    COMPRESSOR, PEQ+COMPRESSOR, PEQ+COMPR+DIST, PEQ+COMPR+OVERDR, two each
```

V1 leaves the four compressor algorithms misaligned by *exactly* their two
`C40.1.E0.451` words; V2 leaves the twelve reverbs misaligned by *exactly* their
four `C40.1.80.000` words. **The split is the only assignment of the two forms
that aligns all sixteen**, and the residue it leaves is four algorithms that are
all one family — FLANGER, ENSEMBLE, S.DELAY+FLANGER, PEQ+FLANGER — **none of
which contains a C-format consumer at all**, so this pass neither touches nor
claims them.

**WHAT IS AND IS NOT CLAIMED.** §5 forces the `C40.1.80.000` half. The
`C40.1.E0.451` half is **OPEN**: four algorithms aligning is suggestive, the
compressor has no delay line at all (algo 36's block is the two-cell
`[128, 32768]` shape), and `isa-adjudication.md` §1's reading — that the C format
is a 13-bit immediate load whose `addr8` is *data* — predicts that **neither**
form should consume, which the reverbs refute. **Two immediate loads that differ
in `lo12` and behave oppositely towards the descriptor cursor is a fact this pass
measures and does not explain.**

---

## 5. ★★★ TASK B — the forcing

`python3 dsp/tools/target4.py anchor`

**POPULATION: the 12 reverbs.**

```
   consumer / cursor model                             pre-delay tap pairs with cell 0x03
   E1  C-format CONSUMES (the incumbent)                12 of 12
       cell 0x03 = {LINE_BASE: 12};  CEILING 0x1E walked 12 of 12, last read 12 of 12
   E2/E4  C-format does NOT consume, cursor stops at 28   7 of 12
       cell 0x03 = {LIMIT: 5, LINE_BASE: 7};  CEILING 0x1E walked 0 of 12
   E3  C-format does NOT consume, cursor STARTS at cell 4  0 of 12
       cell 0x03 = NOT WALKED 12 of 12;  CEILING walked 12 of 12
```

⚠ **THE MIDDLE ROW IS 7 OF 12, NOT 0, AND THAT MATTERS.** Dropping the C-format
words puts the program's final WRITE on cell `0x1B`, inside the pre-delay buffer
and below the pre-delay reads — but only in the five presets whose `0x1B` happens
to sit below their `0x00`. In the other seven the host anchor survives by luck of
the canned numbers. **The anchor leg alone is not a forcing and is not presented
as one.**

What forces it is the second line of each block:

* under **E2** the CEILING cell `0x1E` is never walked, so
  `CEILING = the LAST READ of its program` — **exceptionless at 83 of 83** in
  `dram-datapath.md` item A, and 71 of 71 among algorithms with no C-format cell —
  fails for **12 of 83**;
* under **E3** cell `0x00`, the one cell a T2 record writes every time the player
  turns the PRE DELAY knob, is never read by anything, **12 of 12**.

**THE ENUMERATION, PRINTED BESIDE THE CLAIM (rule 3):**

| # | reading | verdict |
|---|---|---|
| **E1** | the four cells are consumed by the C-format words | **ADMITTED** |
| **E2** | consumed by nothing, sitting at the END of the block | **REFUTED** — the CEILING is never walked, 12 of 12 |
| **E3** | consumed by nothing, sitting at the START | **REFUTED** — the host-written cell `0x00` is never read, 12 of 12 |
| **E4** | the block is really 28 cells and the allocator over-reserved by 4 (the dead T1 entries) | **= E2/E3** — the over-reservation still has to be somewhere |
| **E5** | a second, phase-shifted cursor | **REFUTED independently** — `dram-unit-cursor.md` item D (model M5, three routes) |

⇒ **`C40.1.80.000` CONSUMES A DESCRIPTOR CELL. FORCED within E1..E5.** This says
nothing about the direction (§7) and nothing about `C40.1.E0.451`.

---

## 6. ★★ TASK B — the off-by-one, enumerated

`python3 dsp/tools/target4.py shift`

`T1[0x67]` is `[0x00, 0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E]`, **identical in 12 of
12**. Predicate, applied identically to every candidate: *a cell is a valid
pre-delay tap iff its value lies strictly between the pre-delay line base and the
next line base above it*. Entry 0 is the live one and is not shifted.

**POPULATION: 12 reverbs × 6 shifted entries = 72.**

```
   shift -4 : 36 of 72      shift  0 : 60 of 72
   shift -3 : 48 of 72      shift +1 : 48 of 72
   shift -2 : 60 of 72      shift +2 : 36 of 72   (12 entries off the end)
   shift -1 : 72 of 72  <== shift +3 : 24 of 72   (24 off the end)
                            shift +4 : 12 of 72   (36 off the end)
```

A uniform **−1** on entries 1..6 is the unique maximum, and the score decays
symmetrically either side of it — no degeneracy (rule 4). The slip is the classic
one: `T1[j] = ER_BASE + j` written for a **1-based** operand index over a
**0-based** cell block, `ER_BASE = 0x18`.

★ **AND THE RESERVATION IS PROVABLY WRONG UNDER *EVERY* PHASE, WHICH IS WHY IT
CANNOT BE USED ENTRY BY ENTRY AS AN ORACLE.** Entry `0x1E` holds the **value**
`32767` in 12 of 12. The cell↔word phase `δ` moves which *word* touches a cell;
it does not move the cell's *value*. `32767` is outside unit 1's region
`[32768, 65535]` whatever `δ` is. **FORCED.**

★ **PREDICT-THEN-CHECK (P5), and it is a HIT.** If this is one coding slip in a
dead branch, the live reservations elsewhere should not be off by one: **37 live
op-0x67 reservations outside the reverbs' dead branch, 0 of them on a non-ADDRESS
cell.**

---

## 7. ★★★ TASK B — READ or WRITE

`python3 dsp/tools/target4.py direction`

**THE ENUMERATION (rule 3), given §5:** `H_R` all four READ · `H_W` all four
WRITE · `H_M` mixed.

**LEG 1 — the residue rule.** Population: the 83 aligned algorithms.

```
   H_R  C-format = READ    (CEILING, LIMIT+FLOOR, TRAP): (1,1,0) x81  (1,0,0) x1  (1,2,0) x1
   H_W  C-format = WRITE   (1,1,0) x69  (1,5,0) x11  (1,4,0) x1  (1,0,0) x1  (1,2,0) x1
   --   incumbent (traps)  (1,1,0) x69  (1,1,4) x12  (1,0,0) x1  (1,2,0) x1
```

`H_R` puts the twelve reverbs on the residue the other 61 aligned algorithms
already have. `H_W` gives them **five bound cells in one algorithm**, a residue
that occurs **nowhere else in the corpus**.

**LEG 2 — what would the writes open?** Under `H_W`, over the 12 reverbs the four
cells open **1** delay line in total and **47 of 48** open none. The firmware
would be canning four extra buffer bases per preset, at four different sizes per
preset, that nothing ever reads, in 12 of 12 presets.

**LEG 3 — the tail (§1).** Under `H_W` the LEFT and RIGHT tails — which agree in
`lo12` at **11 of 11** positions — would be doing different things, one tap each,
with four port slots writing to unread buffers. Under `H_R` they are the same
circuit twice.

**LEG 4 — the host.** The shift-corrected reservation names all six cells
`0x18..0x1D` as op-0x67 operands, and op-0x67's evaluator produces
`base + delay` — a **tap**, i.e. a read end. `bounds.py` item G: **36 of 36**
host-named taps classify as read ends; **0 of 36** land on a bound.

**VERDICT.** `H_W` **FALSIFIED** on legs 1 and 2. `H_M` is worse on both. `H_R`
stands on four legs — **and not one of them reads the word**: the reservation is
provably wrong about one entry (§6), the residue rule is a property of the
allocation model, and the tail argument assumes the two tails are a stereo pair.

⇒ **LABEL: CONSISTENT, STRONGLY. NOT FORCED. NOT APPLIED** (method rule 6). The
four words keep trapping.

**WHAT WOULD FORCE IT**, named so the next pass does not re-derive it: a site
where the C-format word's 13-bit immediate, or its `lo12 = 0x000`, can be
separated from an `addr8` bit-6 direction field. The corpus has none — the
identical 36-bit word sits on *both sides* of three equal-value descriptor pairs
(`dram-direction.md` item B), which is exactly why that pass excluded it.

---

## 8. ★★★ TASK C — the ACTION 0x0B decidability census

`python3 dsp/tools/target4.py act0b`

**POPULATION: every ACTION 0x0B word in the 40 distinct body images plus the
60-word kernel and the 23-word epilogue — 85 words** (82 in bodies, 3 in the
kernel, 0 in the epilogue).

**(D1)** **50 of 85** are class-1 delay-DRAM port words. Their address, their
write-data source and their latency are all still open, so no ACTION semantics
can be separated there whatever else is known. *This is why "ACTION 0x0B sits on
48 of the 83 CEILING words" is a clue that cannot be cashed from inside the
reverb.* **35 of 85** are not DRAM words.

**(D2)** **CRITERION, fixed before it was applied and identical for every word:**
of the eight words that follow, how many does the disassembler's own `decoded()`
accept? (That is the predicate `upd6383d.cpp` uses, so this census cannot drift
from the shipped core.)

```
   dec  algo   name                   word   form             following 8
   8    98     PEQ+DIST+DELAY         w001   02A.2.4B.00B     DDDDDDDD
   8    99     PEQ+OVERDR+DELAY       w001   02A.2.4B.00B     DDDDDDDD
   7    74     PEQ+VIBRATO            w011   212.2.47.00B     .DDDDDDD
   7    75     PEQ+COMPRESSOR         w000   02A.2.4B.00B     .DDDDDDD
   6    8      GATED REVERB           w034   102.A.00.64B     DDDD..DD
   6    8      GATED REVERB           w068   102.A.F7.64B     DDDDD.D.
   6    16     ROOM REVERB 1          w056   102.A.00.64B     DD.DDD.D
   6    16     ROOM REVERB 1          w098   102.A.00.64B     DD.DDD.D
   5    10     MULTI TAP DELAY        w025   000.2.09.40B     .DDDD.D.
   ... 26 more, tailing off to 0
```

**THE ANSWER TO THE QUESTION AS ASKED — and it is not the one expected.**

* **PARAMETRIC EQ**, the one program decoded to the bit, contains **zero**
  ACTION 0x0B words. So do DISTORTION, OVERDRIVE, FUZZ, EXCITER, COMPRESSOR,
  AUTO PAN, AUTO WAH, PHASER, RING MODULATOR, PEQ+COMPR+DIST and
  PEQ+COMPR+OVERDR — **12 of the 40** distinct images are free of it.
* **SINGLE DELAY**'s three are all DRAM port words: it contributes nothing.
* **The LFO** contributes nothing: all 3 kernel ACTION 0x0B words are DRAM port
  words, AUTO PAN has none, CHORUS's one is a DRAM word.
* ★★★ **BUT THE ANSWER IS NOT "NONE".** **MULTI TAP DELAY** — the host ground
  truth, four named taps at 6000/12000/18000/24000 samples — has exactly one
  non-DRAM site, `w025`, sitting between the four tap deposits and the four
  anchored multiplies. And three PEQ composites carry `02A.2.4B.00B` at the head.

### 8.1 ★★★ The minimal pair

The eight words after PEQ+DIST+DELAY `w001` are **byte-identical to a window that
occurs ten times inside PARAMETRIC EQ** — the SOLVED Direct-Form-I biquad, five
bands × two channels. That makes "the slot immediately before a biquad copy" a
fixed structural position, censusable over the whole corpus.

**POPULATION: 27 occurrences of the biquad window over the 40 distinct images.**

```
   000.2.03.647   x8   ACT=07 SRC=19  decoded  PARAMETRIC EQ w013, w022, w031, ...
   02A.2.00.000   x8   ACT=00 SRC=00           PEQ+CHORUS w059, PEQ+FLANGER w061, PEQ+VIBRATO w012
   02A.2.4B.00B   x2   ACT=0B SRC=00           PEQ+DIST+DELAY w001, PEQ+OVERDR+DELAY w001
   000.2.40.407   x1   ACT=07 SRC=10  decoded  PARAMETRIC EQ w004
   801.0.00.021   x1   ACT=01 SRC=00  decoded  PARAMETRIC EQ w058
   000.2.48.447   x1   ACT=07 SRC=11           PEQ+CHORUS w008
   022.2.00.000   x1   ACT=00 SRC=00           PEQ+S.DELAY w029
   000.2.47.447   x1   ACT=07 SRC=11           PEQ+FLANGER w012
   880.1.30.000   x1   ACT=00 SRC=00           PEQ+COMPRESSOR w001
   02A.2.4B.000   x1   ACT=00 SRC=00           PEQ+COMPR+DIST w001     <== !!
   000.2.4B.000   x1   ACT=00 SRC=00           PEQ+COMPR+OVERDR w001
   012.2.48.1C0   x1   ACT=00 SRC=07  decoded  PEQ+COMPR+OVERDR w050
```

★★★ **`02A.2.4B.00B` and `02A.2.4B.000` are identical in `hi12`, `class4`,
`addr8` and `SRC`, and differ in the ACTION field alone**, in the same structural
slot, in front of the same byte-identical decoded arithmetic. **That is the first
minimal pair anyone has found for ACTION 0x0B.**

**WHAT IT ALREADY BOUNDS (MEASURED):** whatever ACTION 0x0B does at that slot,
the identical biquad runs after it *and* after ACTION 0x00, so it cannot disturb
the biquad's `mem[ptr]` input path. **WHAT IT DOES NOT SETTLE:** what ACTION 0x0B
*writes* — nothing downstream in either program has been shown to read a register
the two versions would differ in. That is a bounded, well-posed next experiment,
and it is the first ACTION 0x0B has had outside the reverb.

**AND THE REVERB IS NOT WHERE IT WILL BE SETTLED.** ROOM REVERB 1 owns 9 of the
35 non-DRAM sites, all `lo12 0x64B` class-A multiplies in the all-pass core. Their
*coefficients* are known (the ladder gains `0x98..0x9C`, `0xA1..0xA4`); what is
missing is the multiplicand route — the same blocker as the reverb topology, not
a separate one.

---

## 9. ★★ TASK D — the ceiling, the rotation `G`, and the wrap

`python3 dsp/tools/target4.py rotation`

`dram-unit-cursor.md` §5(b) enumerates three readings of the per-unit CEILING
pair and reports (2) and (3) surviving. **Rule 10: the two notes already decide
this and neither noticed.** `dram-datapath.md` §2.1 enumerates the *same cell*
from the other side and refutes its own **E2** — *"loading a per-unit WRAP/limit
register"* — with one line: **a limit must be loaded before the accesses it
bounds, and this cell is the LAST READ of its program in 83 of 83**. Readings (1)
and (2) are both limit-register readings.

⇒ **Reading (2) FALSIFIED. Reading (3), the sentinel, stands alone** within the
printed three-member enumeration.

★★ **AND THAT SEVERS THE CEILING CELLS FROM THE `G` QUESTION.** If the ceiling is
the address of a *discarded* read, `(cell + G) mod 2^N` is thrown away whatever
`G` is, so the ceiling carries no information about the rotation.
`dram-unit-cursor.md` item K's link between TARGET 1's ceiling cells and `G` is
cut, and those cells must come out of any future constraint set for it. **A
constraint withdrawn before it was used.**

What the flush address actually is:

```
   unit 0 programs flush at 32768 = the FIRST word of unit 1's region
   unit 1 programs flush at 32767 = the LAST  word of unit 0's region
```

Each unit's flush lands one word over the partition, in the other unit's
territory; it is a READ, so it is inert.

**AND ONE THING ABOUT `G` THAT CAN BE DECIDED WITHOUT ITS WORD — THE MODULUS.**

```
   unit 0 ADDRESS cells: min 0      max 32649   headroom to the region top = 118
   unit 1 ADDRESS cells: min 32768  max 64899   headroom to the region top = 636
```

A single free-running `G` rotating modulo `2^16` would walk unit 0's topmost
buffer into unit 1's region after **118 frames = 2.68 ms**. So either the
rotation is modulo each unit's own region, or `G` is per-unit, or it is not a
free counter. **ENUMERATED, NOT DECIDED**; the numbers are the contribution.

---

## 10. Rule 7 — rivals, scored where they disagree

`python3 dsp/tools/target4.py rivals`

| # | claim | rival | separation |
|---|---|---|---|
| **R7.1** | the two tail blocks are a stereo pair | two unrelated adjacent blocks (instruction-blind) | 11 of 11 `lo12` agree; **null: two 11-word windows of the same image agree at ≥11 of 11 in 437 of 20 000 draws, p = 0.022.** ★ The `lo12` evidence alone is only p ≈ 0.02 and is reported as such; the C-RAM roles carry the rest |
| **R7.2** | `C40.1.80.000` consumes | V2 (none consume) · V4 (the twin) · V1 (incumbent) | on the 16-algorithm disagreement set: **V3 16/16, V1 12/16, V2 4/16, V4 0/16** |
| **R7.3** | the four cells are READS | WRITES · and *"whatever the block's majority is"* (instruction-blind) | READ/WRITE separated decisively (§7). ⚠ **The instruction-blind rival is NOT separated by anything in this pass** — the reverb's block is 15 READ : 13 WRITE, so a majority rule predicts READ with no reasoning at all. Reported, not hidden |
| **R7.4** | the CEILING is a sentinel | a limit-register load | position: 83 of 83 last; `P(last | uniform)` = 1.3 × 10⁻⁷² |

---

## 11. Controls — each shown saying NO, and each shown saying YES

`python3 dsp/tools/target4.py control`

```
   C1  THE ALIGNMENT INSTRUMENT
       says YES to the split predicate             : 87 of 91
       says NO  to the mirror-image twin (V4)      : 71 of 91
       says NO  to `every mac is a consumer too'   :  2 of 91
       says NO  to `nothing consumes'              :  0 of 91

   C2  THE HOST-ANCHOR INSTRUMENT
       says YES to the real block, C-format consuming :  12 of 12
       says PARTLY NO to E2                           :   7 of 12
       says NO to E3                                  :   0 of 12
       says NO to SHUFFLED cell values (wrong twin)   :   0 of 12

   C3  THE SHIFT INSTRUMENT
       says YES to the 36 host-NAMED op-0x67 taps     :  36 of 36
       says NO  to the two BOUND cells (0x01, 0x1E)   :   0 of 24 accepted
```

### C4 ★ A control of mine that could not pass, printed rather than rewritten

My first TASK B instrument was a **FLUSH-ADJACENCY** test: *if the trailing flush
read exists to give the last real tap one more port slot, the port access
immediately before the CEILING must be a READ — and in the reverbs it is a
C-format word, which would then have to be a read.*

```
   direction of the port access before the CEILING (83 aligned algorithms):
      WRITE 60   READ 11   TRAP 12
```

**WRITE in 60 of the 71 unambiguous algorithms.** A write between the last real
read and the flush is normal, so the flush cannot be argued to be adjacent to
anything. The argument is **REFUTED by the corpus**, the test has no power, and
it is used nowhere in this note. It is the eighth control caught on this chip and
the second caught by the agent that built it.

---

## 12. PREDICT-THEN-CHECK — 10 made, 3 hits, 6 misses, 1 partial

| # | prediction | outcome |
|---|---|---|
| **P1** | the reverb tail is two mirrored blocks | **HIT** — 11 of 11 `lo12` agree |
| **P2** | a flush-adjacency test will force the C-format direction | ★ **MISS** — WRITE in 60 of 71; no power (§11 C4) |
| **P3** | the consumer predicate is exceptionless | ★ **MISS** — 83 / 75 / 87 / 71, residue four FLANGER-family |
| **P4** | the four trapping cells will be FORCED this round | ★ **MISS** — three legs agree on READ, none reads the word |
| **P5** | the T1 off-by-one is a uniform −1 | **HIT** — 72 of 72, unique max over [−4, +4]; and 37 live reservations, 0 wrong |
| **P6** | ACTION 0x0B decidable from PARAMETRIC EQ / SINGLE DELAY / the LFO | ★ **MISS on all three** |
| **P9** | and therefore ACTION 0x0B is not decidable anywhere | ★★★ **MISS, and this one is the result** — four decidable sites, and a minimal pair |
| **P10** | the C-format consumer family is homogeneous | ★★ **MISS** — two forms, opposite behaviour |
| **P7** | the CEILING/`G` question can be closed without the consuming word | **HALF-HIT** — reading (2) falls; `G`'s mechanism stays OPEN and the ceiling turns out to carry no information about it |
| **P8** | the tail would need round 7's new delay harness | **HIT (as a non-need)** — built deliberately not to depend on it |

---

## 13. What the other agents need

1. **`dram-datapath.md` item A gains an independent leg** (§1.1) and `land = −1`
   is refuted a second time, at a site with no ALU search in it.
2. **`dram-bounds.md` item M's "CONSISTENT direction (READ) for 48 of 48"
   survives and is strengthened to three legs — and is still not applied.**
3. ★★ **`dram-unit-cursor.md` §5(b) reading (2) is FALSIFIED** and item K's
   ceiling↔`G` link is **cut**. Any `G` search must drop the ceiling cells.
4. ★★ **`dram_cursor.is_consumer` is wrong for `C40.1.E0.451`** in four
   compressor algorithms. Nothing published depends on those four (they were
   already excluded as unaligned), but a pass that fixes the predicate gains four
   algorithms and should re-run `bounds.py`, `datapath.py` and `cursor_units.py`
   with **87** as the denominator instead of 83.
5. ★★★ **ACTION 0x0B now has an experiment**: the `02A.2.4B.00B` / `02A.2.4B.000`
   minimal pair in front of a byte-identical PARAMETRIC EQ biquad (§8.1), plus
   MULTI TAP DELAY `w025` between four host-named deposits and four anchored
   multiplies. **Nobody should look for it in the reverb.**
6. The reverb's open words are now named and small: `282.A.00.000` and
   `000.A.xx.452` (the two undecoded coefficient consumers of each output tail),
   and the route from `SRC 0x0B` into the tail mixer.
