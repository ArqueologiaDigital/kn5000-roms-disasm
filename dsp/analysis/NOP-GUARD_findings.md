# NOP-GUARD — is `exec_decoded()`'s `hi12 == 0x000` interception correct?

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Date **2026-07-31**.
**Static pass only** — nothing built, nothing run, no MAME source written, no commit.
Read-only over `kn5000-roms-disasm` + `kn7000_mame` + the eleven `.log.gz` files already
on disk (decompressed to scratch, never in place).

Grades: **MEASURED** (a number computed this pass) · **FORCED** (follows by construction
from something measured) · **INFERRED** · **SPECULATIVE**.

⚠ **THIS IS NOT AN AUDIO TEST AND CANNOT BECOME ONE.** §216/§220 guarantee the output
stage is a null independent of anything upstream — the bodies already run live on the rig
and `w73`/`w78` still read exactly zero. Everything below is graded on the corpus, on
`§104` and on the trace. Nothing is graded by listening. **RULE 19**: no level number is
quoted anywhere in this note; if one ever is, MEAN and AC AMPLITUDE go in separate columns.

---

## 0. HEADLINE — the guard is **TOO BROAD, by exactly 41 words**, and it is **NOT LOAD-BEARING** on anything measured

Five results, in the order the next lane-holder needs them:

1. **The guard's predicate matches no hypothesis anyone in this tree has stated.** The
   evidence for the `nop` reading is, in every note that carries it, evidence about the
   single word **`000.2.00.000`** — `addr8 = 0x00`. The core's guard omits `addr8`
   entirely and therefore also swallows **41** words carrying a live signed pointer field
   (`+72`, `−70`, `−75`, `+75` …). **MEASURED.**
2. **The same codebase already contains the correct, narrower predicate — twice.**
   `upd6383d.cpp:728`'s `decoded()` requires `ad == 0x00`; and the shipped `.dsm`
   listings render the 62 as `nop` and the 41 as **`?word`** (undecoded). The core is the
   only one of the three that swallows the 41. **MEASURED**, quoted in §1.3.
3. **Position kills the padding/alignment/tail reading outright: 103 of 103 are
   MID-LADDER.** Zero are the last word of their image, zero carry the END bit, zero sit
   in a trailing run, and 90 of 103 are ≥ 10 words from the end. **MEASURED**, §2.2.
4. **The 62 and the 41 are structurally different, and only the 62 look like nops.**
   The 62 form pairs (21 of their 38 maximal runs have length ≥ 2 — the reverb motif's
   `nop nop`); the 41 are **0 of 41 runs of length ≥ 2**, i.e. 100 % isolated, and 46 %
   of them are immediately followed by a bit-4 STORE. **MEASURED**, §3.
5. ★ **But it does not matter for any measurement now on disk.** **21** of the 103
   execute in the archived logs (KERNEL `iw57` plus 20 in the unit-1 body). All 21 read
   `mem 0..0` in both buckets over **1 020 000** frames, and at the one site where `P` is
   also measured the executed result is an **exact identity** (`acc ← 0 + P`, and
   `P = acc = 2 603 010 048`). The other **82** sit in body images no archived log ever
   loads. **Same verdict shape as the epilogue decode gap: too broad, NOT load-bearing.**
   **MEASURED**, §4.

**Verdict: TOO BROAD — and not load-bearing.** Grade in §6. The change it warrants is
**static and needs no run**; the run in §7 exists only for someone who wants to claim the
change *does* something, and its most likely outcome is "no difference", which is
pre-registered as *not* a vindication of the guard.

---

## 1. ITEM 1 — THE EXACT GUARD

### 1.1 ⚠ Line numbers drift: `upd6383.cpp` is being edited right now

`src/devices/cpu/upd6383/upd6383.cpp` moved **twice while this note was being written**:
it was modified-in-worktree at `3d95aae`, and §221 committed it as **`b03e9d6`** mid-pass.
The brief's citation `:4059` is from a still older revision. All three positions of the
same code, stated so nothing is ambiguous:

| what | at `3d95aae` | at `b03e9d6` (§221's commit, = current) |
|---|--:|--:|
| the nop guard | `upd6383.cpp:4075` | `upd6383.cpp:4538` |
| the acc-adder comment citing `000.2.48.000` | `upd6383.cpp:3066` | `upd6383.cpp:3513` |
| `decoded()`'s narrower nop | `upd6383d.cpp:728` | unmodified, same line |

**Quote everything below by content, not by line.** **MEASURED.**

### 1.2 The guard, verbatim

```c
	else if (upd6383_disassembler::hi12(word) == 0x000
			&& upd6383_disassembler::class4(word) == 2
			&& upd6383_disassembler::lo12(word) == 0x000)
	{
		// nop -- INFERRED.  (The old "PROVEN BY CONSTRUCTION, writer
		// LABEL_038922" citation was WITHDRAWN: that routine emits
		// 801.0.NN.825 plus a tag-0x4C packet and never emits this word.  What
		// supports it now is that the host injects this exact pattern three
		// times in the PARAMETRIC EQ stream as the only word matching no known
		// form.)
		//
		//  ★★★★ §90: "NOP" MUST NOT MEAN "NO ADDRESSING".
		//  This word has class4 == 2, and `class4 & 7 == 2 -> p += (s8)addr8' is
		//  MEASURED (ptr_postinc, and this file's own header says "THE ADDRESS
		//  GENERATOR IS DECODED EVEN WHERE THE ALU IS NOT ... EXECUTE WHAT
		//  ADDRESSES, NEVER WHAT COMPUTES").  Swallowing the pointer move as well
		//  lets an INFERRED reading override a MEASURED one.
		//  MEASURED CONSEQUENCE: body 1's word iw213 = `000.2.BA.000' carries
		//  delta -70 and lost it, so body 1 walked -63 where the ROM sums to
		//  exactly -133 -- and that single omission displaced the whole input
		//  window by 0x46, put the kernel's audio deposit at 0x4C where no body
		//  word can address it, and left the reverb unexcited and silent.
		if (upd6383_disassembler::ptr_postinc(word) && !ptrd_a_suppressed(word))
			m_dp = u8(m_dp + s8(upd6383_disassembler::addr8(word)));
	}
	else
	{
		exec_alu(word);     // the lo12 routing / hi12[3:1] operation decode
	}
```

**What it tests:** an **exact equality on all twelve `hi12` bits**, plus `class4 == 2`,
plus an **exact equality on all twelve `lo12` bits**. `addr8` is not tested.
**What it skips:** `exec_alu()` in full — the source select, the ACTION, the accumulator
adder, `m_last_l`, and the `§40`/`§29` tails.
**What it still performs:** the signed pointer post-increment (`ptrd_a_suppressed()`
requires `lo12 == 0x1C0`, so it can never fire here — `upd6383.cpp`, function
`ptrd_a_suppressed`). ★ **This matters for any narrowing:** `exec_alu()` ends with
`if ((cl & 7) == 2) m_dp = u8(m_dp + dd);`, so removing or narrowing the guard **moves the
pointer move, it does not lose it**. The pointer trajectory is invariant either way.
**FORCED**, from both sites in the source.

★ **The §90 comment is itself the precedent for this finding.** It records that the guard
was *already* caught being too broad once — it ate `iw213`'s `−70` and that omission was
traced to a silent reverb — and the fix narrowed the guard's **effect** (restore the
pointer move) while leaving its **scope** untouched. This pass is the same defect one
level up: the ALU is still swallowed on the same 41 words.

### 1.3 The contradicting comment, verbatim, and the three-way predicate split

`upd6383.cpp` (HEAD `:3066`), in the accumulator-adder block:

```c
	//      LFO   082.2.00.1C0   hi12[3:1] = 1, ACTION 0x00, bus = phase
	//      SD    000.2.48.000   hi12[3:1] = 0, ACTION 0x00, bus = x
	//
	// both have to produce `bus + P'.  No ORDER does that -- act-first gives
	// `P' at hi12[3:1] == 0 and act-last gives `acc + P + bus' at 1 -- but a
	// single adder whose accumulator-feedback input is OVERRIDDEN by the bus
	// gives it at both.
```

`000.2.48.000` is `a09 SINGLE DELAY` **w7** (I-RAM **91**), and it is one of the 103. The
file therefore asserts, four thousand lines apart, that this word **must** produce
`bus + P` and that it produces **nothing**. **FORCED** from the dispatch order.

⚠ **RULE 13 — the owning notes were checked before this was written up, and they change
the weight of the comment, not the contradiction.** `acc-adder.md` §1/§2 is the source of
that quote; `adjudication-round6.md` **VOIDED** its SINGLE DELAY leg; `adjudication-round7.md`
item **E** then downgraded `order = adder` from **FORCED to CONSISTENT** ("the SINGLE DELAY
leg is the void one"); `adjudication-round8.md` item **C** partly corrects round 6 again
("it was a POLARITY artefact … the same 108 machines, set-identical"). ⇒ **The comment's
claim is contested and currently CONSISTENT, not FORCED.** It is still a claim the code
cannot execute, and the sentence in the source does not carry any of that history.

**Other comments bearing on `hi12 == 0`, all three of which the guard contradicts:**

* `upd6383d.cpp`, `hi_text()`: *"`hi12 == 0x000`: every enable clear. 27.2 % of the
  corpus, and the NOP is one of them — which is what a horizontal microword predicts and
  an enumerated opcode does not."* ⇒ if that reading were implemented, **all** `hi12 == 0`
  words would be nops. **It is implemented for 103 of 818.** (My denominator: 818 of 3057
  distinct-image words = **26.8 %**; the file says 27.2 %, a denominator difference, not a
  disagreement worth acting on.) **MEASURED.**
* `upd6383.cpp`, the §66 comment: *"body 1's ladder … died at `iw306 = 000.2.49.407` —
  SRC = ACC, **f31 = 0 => LOAD acc <- P**"*. That is a `hi12 == 0x000` word whose LOAD
  semantics the file treats as load-bearing. **715 of the 818** `hi12 == 0` words run the
  full ALU exactly like it. **MEASURED.**
* `upd6383d.cpp:728`, `decoded()`:
  `if (hi == 0x000 && cl == 2 && ad == 0x00 && lo == 0x000) return true;  // nop`
  — **the narrow predicate**, `addr8` included.

**The three predicates in this one codebase:**

| site | predicate | admits | verdict on `000.2.48.000` |
|---|---|--:|---|
| `upd6383d.cpp:728` `decoded()` | `hi12 == 0 ∧ cl == 2 ∧ **addr8 == 0** ∧ lo12 == 0` | **62** | not a nop (falls through to `alu_decoded()`, which refuses it) |
| the `.dsm` listings (`text()`, gated by `decoded()`) | same | **62** | prints **`?word   0x0000248000 ; 000.2.48.000  hi12{-}`** |
| `exec_decoded()`'s guard | `hi12 == 0 ∧ cl == 2 ∧ lo12 == 0` | **103** | **executes it as a nop** |

Verbatim from `dsp/disasm/prog09_single_delay.dsm` — the project's own listing of the very
word the comment cites, beside the form it *does* call a nop
(`dsp/disasm/prog16_room_reverb_1.dsm`):

```
  w7    0000248000   ?word   0x0000248000   ; 000.2.48.000  hi12{-}
  w16   0000200000   nop
```

**MEASURED.** The disassembly and the core disagree about 41 words.

### 1.4 ⚠ How these words reach the guard at all — and why "the 350 run the full ALU" needs one correction

`alu_decoded()` requires an **anchored** SRC (`0x07 / 0x10 / 0x19 / 0x1A`). `SRC 0x00` is
not anchored, so **`alu_decoded()` is FALSE for all 103 and for all 350** — the whole
`class 2 / lo12 0x000` family is refused by the strict predicate. Both sets reach
`exec_decoded()` only through `run_frame()`'s speculative gate
(`word_ok = decoded(word) || (m_speculative && alu_decoded_speculative(word))`), which
is on in the shipped build. **MEASURED** (0/350 and 0/103 `alu_decoded`), **FORCED** (the
gate). So the contradiction lives entirely **inside the speculative arm**: it is
speculative-vs-speculative, not speculative-vs-decoded. The prior note's "350 siblings run
the full ALU" is right about the shipped build and should carry that qualifier.

With `m_speculative` **off**, the 62 execute as nops via `decoded()` and everything else —
the 41 and the 350 — traps to `exec_addressing_only()`, which performs the same pointer
move. ⇒ **The guard's only effect on the 41 is to keep them at their non-speculative
behaviour inside the speculative build.** **FORCED.**

---

## 2. ITEM 2 — THE CENSUS OF THE 103, AND WHERE THEY SIT

Computed with `dsp/tools/pat_corpus.py` (the shared loader; no rival loader written), which
already excludes the IC310/MN19413 streams **{79, 88, 89, 90, 91}**.
**Population: 40 streams / 3057 words** = KERNEL (60) + EPILOGUE (23) + **38 distinct body
images**. **RULE 18** honoured (`SRC = lo12[10:6]`, `ACT = lo12[4:0]`, taken from the
loader's own fields). **Dead end 16** cannot arise: every word here has `lo12 = 0x000`, so
bit 11 is clear and no `ACT 0x03/0x04/0x1C` or `SRC 0x02/0x04` artefact is possible.

### 2.1 The sets, with denominators

| set | words | streams |
|---|--:|--:|
| swallowed by the guard | **103** | **28 of 40** |
| ...of which `addr8 == 0x00` — the form every note's evidence is about | **62** | 15 |
| ...of which `addr8 != 0x00` — a live pointer move | **41** | 25 |
| siblings: `class 2 ∧ lo12 = 0x000 ∧ hi12 != 0`, C-format excluded | **350** | 38 |

Both the brief's headline numbers (103 / 28 / 62 / 41 / 350) **reproduce exactly**.
**MEASURED.**

The 17 distinct swallowed words, and the `addr8` payloads the guard collapses:

```
   000.2.00.000 x62 (15 streams)   000.2.01.000 x11 (8)   000.2.FF.000 x10 (9)
   000.2.F7.000 x5 (4)             000.2.4B.000 x2 (2)    000.2.F5.000 x2 (2)
   000.2.04.000  000.2.0B.000  000.2.0F.000  000.2.48.000  000.2.B5.000
   000.2.B6.000  000.2.BA.000  000.2.BF.000  000.2.F4.000  000.2.F6.000  000.2.F8.000   (x1 each)

   addr8 values among the 41:  +1 x11  −1 x10  −9 x5  +75 x2  −11 x2
                               +4 +11 +15 +72 −75 −74 −70 −65 −12 −10 −8   (x1 each)
```

### 2.2 ★★★ POSITION — the padding / alignment / tail reading is dead

| question | 103 swallowed | 350 siblings (control) |
|---|--:|--:|
| last word of its image | **0** | 0 |
| carries the END bit | **0** | — |
| inside a trailing run of nops | **0** | — |
| **strictly interior, with an executing word before AND after** | **103 (100 %)** | 349 of 350 (99.7 %) |

Distance-from-end histogram (0 = last word): `2:3 3:2 4:3 5:1 7:1 8:1 9:2 ≥10:90`.
**90 of 103 sit ten or more words from the end of their image.**

Every image's terminator is a `class 1 / addr8 0x0E/0x0F` END word (`428.1.0E.000` ×12,
`400.1.0E.000` ×7, `612.1.0E.000` ×4, …) — **none of the 103 is one, and none is adjacent
to one**. **MEASURED.**

⇒ **A nop is plausible as padding, alignment or tail. These are none of those.** They are
mid-ladder, in exactly the same positional distribution as the 350 words that execute.

### 2.3 The full listing of the 41 that carry a live pointer move

`iram` = I-RAM slot (KERNEL 0, EPILOGUE 60, body unit 0 → 84, body unit 1 → 200).

```
stream                      idx   /n  iram  word            prev            next
KERNEL                       57   60    57  000.2.01.000    C64.6.A2.007    000.1.8A.007
a00 NO OPERATION              1   49    85  000.2.04.000    880.1.30.00B    000.2.FC.407
a00 NO OPERATION             28   49   112  000.2.F7.000    000.A.09.655    212.2.00.419
a00 NO OPERATION             34   49   118  000.2.F7.000    212.2.00.000    02C.2.0A.1CD
a00 NO OPERATION             41   49   125  000.2.F8.000    000.A.08.655    212.2.00.419
a03 ENHANCER                 20   99   104  000.2.FF.000    880.1.30.407    012.2.44.1C0
a03 ENHANCER                 48   99   132  000.2.F7.000    102.A.B5.4C8    028.2.0A.1CD
a09 SINGLE DELAY              7   48    91  000.2.48.000    202.A.B8.655    212.2.00.419   ← the acc-adder's word
a09 SINGLE DELAY             14   48    98  000.2.01.000    202.2.00.407    000.A.00.1D5
a09 SINGLE DELAY             19   48   103  000.2.B6.000    202.2.00.407    000.2.FE.407
a09 SINGLE DELAY             30   48   114  000.2.4B.000    202.A.B5.655    212.2.00.419
a09 SINGLE DELAY             37   48   121  000.2.01.000    202.2.00.407    000.A.00.1D5
a09 SINGLE DELAY             42   48   126  000.2.B5.000    202.2.00.407    000.2.FD.407
a10 MULTI TAP DELAY           1   68    85  000.2.0F.000    880.1.30.00B    000.2.FB.407
a10 MULTI TAP DELAY          13   68    97  000.2.01.000    880.1.20.2C7    000.2.00.000
a10 MULTI TAP DELAY          17   68   101  000.2.01.000    880.1.20.2C7    000.2.00.000
a10 MULTI TAP DELAY          21   68   105  000.2.F5.000    880.1.20.2C7    000.2.00.000
a10 MULTI TAP DELAY          51   68   135  000.2.01.000    202.2.00.407    000.A.00.1D5
a10 MULTI TAP DELAY          56   68   140  000.2.BF.000    202.2.00.407    000.2.03.407
a16 ROOM REVERB 1            13  133   213  000.2.BA.000    000.A.00.695    212.2.00.419   ⚠ BODY 1 — see §5
a32 DISTORTION               20   42   104  000.2.01.000    880.1.30.407    012.2.F6.1C0
a33 OVERDRIVE                 1   63    85  000.2.0B.000    040.0.00.8BC    02E.2.40.407
a33 OVERDRIVE                31   63   115  000.2.01.000    880.1.30.407    012.2.45.1C0
a34 FUZZ                     20   42   104  000.2.01.000    880.1.30.407    012.2.F6.1C0
a35 EXCITER                  35   69   119  000.2.F7.000    880.1.30.407    000.2.0A.1CD
a36 COMPRESSOR               20   40   104  000.2.01.000    880.1.30.407    012.2.00.1C0
a39 PARAMETRIC EQ            52  105   136  000.2.F7.000    880.1.30.407    000.2.0A.1CD
a52 AUTO WAH                 53   72   137  000.2.F5.000    880.1.30.407    000.2.0A.1CD
a54 RING MODULATOR           36   46   120  000.2.F4.000    880.1.30.407    000.2.0A.1CD
a64 S.DELAY+CHORUS           60   95   144  000.2.FF.000    000.2.00.000    000.A.00.1D5
a65 S.DELAY+S.DELAY          10   68    94  000.2.FF.000    202.A.01.655    212.2.00.419
a65 S.DELAY+S.DELAY          22   68   106  000.2.FF.000    202.A.01.655    212.2.00.419
a66 S.DELAY+FLANGER          18  100   102  000.2.FF.000    202.A.01.655    212.2.00.419
a67 S.DELAY+VIBRATO          18   86   102  000.2.FF.000    202.A.01.655    212.2.00.419
a68 S.DELAY+PHASER          105  110   189  000.2.F6.000    880.1.60.447    000.2.08.407
a70 AUTO WAH+S.DELAY         27  105   111  000.2.FF.000    202.A.01.655    212.2.00.419
a72 PEQ+S.DELAY              18   54   102  000.2.FF.000    202.A.01.655    212.2.00.419
a75 PEQ+COMPRESSOR           29   59   113  000.2.01.000    880.1.30.407    012.2.46.1C0
a97 PEQ+COMPR+OVERDR          1   97    85  000.2.4B.000    880.1.30.8BC    000.A.00.1D3
a98 PEQ+DIST+DELAY           35   92   119  000.2.FF.000    202.A.01.655    212.2.00.419
a99 PEQ+OVERDR+DELAY         43  104   127  000.2.FF.000    202.A.01.655    212.2.00.419
```

The 62 with `addr8 = 0`, per stream (index within the image):

```
a03 ENHANCER          n= 99  3 sites  [94, 95, 96]
a08 GATED REVERB      n=102 11 sites  [10, 19, 20, 27, 28, 45, 46, 53, 54, 61, 62]
a10 MULTI TAP DELAY   n= 68  8 sites  [10, 11, 14, 15, 18, 19, 22, 23]
a15 ROCK ROTARY       n= 86  2 sites  [40, 48]
a16 ROOM REVERB 1     n=133 19 sites  [16,25,26,33,34,41,42,49,50,57,58,75,76,83,84,91,92,99,100]  ⚠ BODY 1
a48 AUTO PAN          n= 50  3 sites  [6, 7, 8]
a64 S.DELAY+CHORUS    n= 95  3 sites  [9, 59, 64]
a65 S.DELAY+S.DELAY   n= 68  5 sites  [41, 53, 63, 64, 65]
a66 S.DELAY+FLANGER   n=100  1 site   [72]        a67 S.DELAY+VIBRATO  n= 86  1 site  [65]
a68 S.DELAY+PHASER    n=110  2 sites  [9, 73]     a70 AUTO WAH+S.DELAY n=105  1 site  [94]
a72 PEQ+S.DELAY       n= 54  1 site   [44]        a98 PEQ+DIST+DELAY   n= 92  1 site  [81]
a99 PEQ+OVERDR+DELAY  n=104  1 site   [95]
```

⚠ **Flagged per the brief: `a00 NO OPERATION` carries 4 of the 41, and its image is shared
by 42 algorithm slots** — the twelve named stub effects ship it byte-identically. Any
"how many effects are affected" statistic must state whether those 42 are in it. With them:
**80 of the 95 non-IC310 algorithm slots** load a body carrying ≥ 1 swallowed word; without
them, **38 of 53**. **MEASURED.**

---

## 3. ITEM 3 — ARE THE 103 STRUCTURALLY DISTINGUISHABLE FROM THE 350?

**No — but the 62 and the 41 are distinguishable from each other, and that is the answer.**

| feature | 62 (`addr8 = 0`) | 41 (`addr8 ≠ 0`) | 350 siblings |
|---|--:|--:|--:|
| maximal runs of the same family | 38 | 41 | 296 |
| ...of length ≥ 2 (the `nop nop` signature) | **21 (55 %)** | **0 (0 %)** | 48 (16 %) |
| strictly interior (mid-ladder) | 62/62 | 41/41 | 349/350 |
| preceded by a class-A MULTIPLY (writes `P`) | 29 (46.8 %) | 14 (34.1 %) | 98 (28.0 %) |
| **followed by a bit-4 STORE** | 12 (19.4 %) | **19 (46.3 %)** | 38 (10.9 %) |
| `f31` values present | 0 only | 0 only | 0,1,2,3,4,5,7 |

Readings, each with its grade:

* ★ **The 62 have an independent structural signature and the 41 have none.** 55 % of the
  62's runs are pairs — `r1-allpass-motif.md` §1's reverb core is
  `880.1.60.2D4 | 104.2.00.000 | 000.2.00.419 | 012.2.00.680 | 880.1.20.655 | 102.A.00.64B`
  **+ two trailing `000.2.00.000`**, in **113 of 114** cores across 13 programs. The 41 are
  **100 % singletons**. **MEASURED.**
* ★ **The 41 sit where an accumulate belongs.** 46 % are immediately followed by a word
  carrying the bit-4 STORE — 4.2× the sibling base rate — i.e. the very next slot commits
  the accumulator to D-RAM. 34 % are immediately preceded by a class-A coefficient
  consumer, the word that **writes `P`**. `a09 SINGLE DELAY` w7 is the textbook case:
  `… 880.1.60.2D9 | 202.A.B8.655 | **000.2.48.000** | 212.2.00.419 | 880.1.20.64B …` —
  delay write, multiply by `fb`, **the swallowed word**, store-and-latch, delay read.
  **MEASURED** (census) + **INFERRED** (the reading of the idiom).
* **`hi12` is the only field that separates the 103 from the 350, and it separates them
  from nothing structural.** `020.2.00.000` — the swallowed word's Hamming-1 sibling on
  bit 5, a bit with **no reading at all** — occurs twice and neither site looks like a nop
  slot: `a15 ROCK ROTARY` w4 (after a class-A multiply) and `a70` w36 (before
  `000.2.02.407`). `020.2.F9.000` exists too. So `f31 = 0` is *not* the discriminator
  either. **MEASURED.**
* **The corpus-wide consistency check.** `hi12 == 0x000` holds **818 of 3057** words
  (26.8 %; class4 histogram `{1:3, 2:567, 6:53, A:195}`). The guard intercepts **103**
  and the other **715 run the full ALU as `f31 = 0` LOAD**, including the `000.2.49.407`
  the §66 comment calls load-bearing. Within class 2 alone, `lo12 = 0x000` (103) is only
  the second most common `lo12`, behind `0x407` (132) which executes. ⇒ **"every enable
  clear ⇒ nop" is not the model the build implements.** **MEASURED / FORCED.**

⇒ **Structurally the swallowed set spans classes of context and sits mid-program: by the
brief's own criterion, the guard is too broad.** But the split is not 103-vs-350; it is
**62-vs-41**, and it lands exactly on the field the guard forgot.

---

## 4. ITEM 4 — WHAT WOULD THEY DO, AND ARE THEIR OPERANDS ALIVE?

### 4.1 The closed form, under the shipped default mask `0xB910E446A39B440F`

`SRC = lo12[10:6] = 0x00`, `ACT = lo12[4:0] = 0x00`, `f31 = hi12[3:1] = 0`, `b4 = b7 = 0`.
Bits 57/58 clear and 59 set ⇒ `SRC 0x00` takes `coef` **only** on a coefficient consumer,
and class 2 is not one. Bit 4 clear ⇒ no multiply is issued on a non-class-A word.

```
   SRC 0x00 →  L = mem[m_dp]                  (the cell the pointer is on, BEFORE the move)
   ACT 0x00 →  SRC_TERM = bus                 (acc-adder: ACTION 0x00 wins over f31 == 0)
   f31 = 0  →  P_TERM   = P                   (not recomputed; MUL is '.' at these slots)
   class 2  →  m_dp += (s8)addr8              — performed EITHER WAY (guard body ↔ exec_alu tail)

   executed :  acc  ←  (L << 16)  +  P        and  m_last_l = L
   swallowed:  acc  unchanged                  and  m_last_l  keeps the PREVIOUS word's bus
```

⇒ the difference between the two is **`acc_new − acc_old = (mem[dp] << 16) + P − acc`**.
It is zero **iff `mem[dp] << 16 + P == acc`**. Note the `f31 = 0` LOAD **discards the
accumulator**, so `mem[dp] == 0` is *not* by itself enough to make the word inert.
**FORCED**, from the source.

### 4.2 ⚠ INSTRUMENT CAVEAT — `§104`'s `L` column is meaningless at a swallowed slot

`m_last_l` is written **only inside `exec_alu()`**, and `§104` samples it *after* the slot.
At any of the 103, the printed `L` is therefore the **previous executing word's** bus, not
this word's. **Only the `mem` column measures the operand of a swallowed word** (it is
`mem[m_dp]` sampled BEFORE the slot, which is exactly what `SRC 0x00` would read). Add this
to the standing "broken instrument" list beside `D-RAM WRITES`. **FORCED**, from the
sampler at `upd6383.cpp` §104 (`const s32 lv = m_last_l;`).

### 4.3 ★ THE MEASUREMENT — 21 of 103 execute in the archived logs, and all 21 are dead

The archived vehicle is the cold-boot pair **`a01 CHORUS` in unit 0** (body iw84..199,
70-word prefix match) **and `a16 ROOM REVERB 1` in unit 1** (body iw200..332 — the §104
rows at iw213/216/225/… carry `00002BA000` / `0000200000`, `a16`'s own words).
`a01 CHORUS` carries **0** of the 103. So the measurable set is **KERNEL iw57 + a16's 20**
= **21 of 103**; the remaining **82** sit in body images no archived log ever loads.

`§104`, over **706 040 quiet + 313 960 loud = 1 020 000 frames**, **identical in all seven
logs** (`drpub_{A_off,B_on,C_on_src0b2}_217`, `{A_off,B_mirror06,C_noz05,D_noz05_drpub}_220`;
RULE 16 satisfied — the sampler arms at frame 420 000 and these runs never change program,
so there is no pooling):

```
   iw  word        dp   nq/nl            acc quiet/loud        mem quiet/loud     L quiet/loud
   57  0000201000  FD   706040/313960    2603010048..2603010048  =   0..0 / 0..0  =   0..0 / 0..0  =
  213  00002BA000  D0   706040/313960             0..0          =   0..0 / 0..0  =   0..0 / 0..0  =    ⚠ BODY 1
  216  0000200000  8A   ...  and 225 226 233 234 241 242 249 250 (dp 94) 257 258
  275  0000200000  8B   ...  and 276 283 284 291 292 299 300 (dp 8B)     — all `0..0` in all three columns
```

* **`mem` — the operand `SRC 0x00` would read — is `0..0` at 21 of 21 sites, in both
  buckets, over 1 020 000 frames.** **MEASURED.**
* ★ **At the one site where `P` is also measured, executing is an EXACT IDENTITY.** The
  `§213` KERNEL-A per-slot table gives `P = 2 603 010 048..2 603 010 048` at `iw57`, and
  `§104` gives `acc = 2 603 010 048..2 603 010 048` there. With `mem = 0`, the executed
  result is `acc ← 0 + P = 2 603 010 048` — **the value it already holds**.
  **MEASURED.** ⇒ at the only fully-instrumented site, the guard is behaviourally a no-op.
* The base rate that makes this unsurprising, and the number the null is built on: on this
  vehicle **`mem` is non-zero at only 51 of 285 executed slots (17.9 %)** and `L` at
  50 of 285 (17.5 %). **The corpus's pointers mostly sit on dead cells** — RULE 15 in its
  mirror image, exactly as `PREDICT_S1_hi12_bench.md` §3.4 found. **MEASURED.**

### 4.4 What is NOT measured, stated as such

**82 of 103** — including **`a09 SINGLE DELAY` w7 (`000.2.48.000`, I-RAM 91)**, the word
the acc-adder comment names — have **no runtime measurement of any kind**, because no
archived log loads their image. For them the only statements available are static:
their pointer deltas (§2.3), their neighbours (§3), and the fact that 19 of the 41 are
immediately followed by a bit-4 STORE, so a discarded accumulator update would reach
D-RAM at the very next slot. **INFERRED**, and deliberately not upgraded.

---

## 5. ITEM 5 — EPILOGUE AND BODY 1 ⚠ NOT MINE

* **EPILOGUE (I-RAM 60..82): 0 of 103.** The guard does not touch §221's region.
  **MEASURED.**
* **BODY 1: 20 of 103**, all in **`a16 ROOM REVERB 1`** — the corpus's **only** unit-1 body
  image (I-RAM 200..332), shared by algorithm slots 16..27. They are I-RAM
  **213, 216, 225, 226, 233, 234, 241, 242, 249, 250, 257, 258, 275, 276, 283, 284, 291,
  292, 299, 300**, of which **iw213 = `000.2.BA.000`** is the word the guard's own §90
  comment is about. Their `§104` rows are reproduced verbatim in §4.3.
  **⚠ Reported as a fact and NOT analysed: body 1 belongs to the other lane, as does any
  inference from those rows, including the ACCA/ACCB question raised by `§104`'s `acc`
  column selecting `m_accb` when `m_cur_unit1`.** Handing it over, untouched.
* **KERNEL: 1 of 103** (`iw57`) — resident in every program, every frame, and the only one
  of the 103 with a measured `P`.

---

## 6. VERDICT

> ### ⛔ **TOO BROAD — and NOT LOAD-BEARING on any measurement now on disk.**

| claim | grade |
|---|---|
| The guard swallows **41** words that carry a live signed pointer field, which **no note's `nop` evidence covers** — every such note is about `000.2.00.000` | **MEASURED** (census) |
| The same repo already holds the narrower, correct predicate at `upd6383d.cpp:728` and in the `.dsm` listings, which render those 41 as **`?word`** | **MEASURED** (quoted) |
| **103 of 103 are mid-ladder**; 0 terminal, 0 END, 0 in a trailing run — padding/alignment/tail is refuted | **MEASURED** |
| The 62 have the `nop nop` pair signature (21 of 38 runs ≥ 2); the 41 have **0 of 41** | **MEASURED** |
| The file asserts both readings of `000.2.48.000` at once, and the dispatch order makes the comment unexecutable | **FORCED** |
| ...but that comment's SINGLE DELAY leg is **VOID** (round 6) / **CONSISTENT, not FORCED** (round 7 item E), so it is a **stale citation**, not a live constraint | **MEASURED**, from the owning notes |
| At **21 of 21** measurable sites the operand `mem` is `0..0` over 1 020 000 frames, and at the one site with a measured `P` the executed result is an **exact identity** | **MEASURED** |
| ⇒ **narrowing the guard to `addr8 == 0x00` changes nothing observable on any vehicle any archived log runs** | **FORCED** from the two rows above |
| The remaining 82 sites are **unmeasured**, not measured-zero | **stated as a limit** |

**"The guard is correct and the comment is stale" is NOT what the evidence shows** — the
comment is stale *and* the guard is broader than every predicate its own repo writes down.
**"Too broad but NOT load-bearing" is what the evidence shows**, and that is the verdict.

**The change this warrants is static, one line, and needs no run:** add `&& addr8 == 0x00`
to the guard so the core agrees with `decoded()` and with the shipped listings. Its safety
is **FORCED**, not hoped for: `exec_alu()`'s tail performs the identical pointer
post-increment, so the address generator is bit-identical either way, and the 41 stop being
the one place in the build where a word is executed as a form the disassembler calls
undecoded.
⚠ **`upd6383.cpp` is §221's file. This is a recommendation to that lane, not an edit.**
Whether even the **62** are nops is a *separate*, still-open question: `r1-allpass-motif.md`'s
inductive closure (113 of 114 cores) is real positive evidence for them, and the
null-routing reading of `lo12 == 0x000` (`SRC 0x00 + ACT 0x00` = no operand, no action) is
**back on the table** now that round 6 voided the SINGLE DELAY block that falsified it
(`action00-discriminator.md` M3). **Do not touch the 62 in the same change.**

---

## 7. PRE-REGISTERED EXPERIMENT — only if someone wants to claim the change DOES something

⚠ **Pre-registered before any run, with the null and the calibration computed FIRST**
(the standing rule, and the exact thing §107/§193 paid for). ⚠ **Not an audio test**:
graded on the trace and on counters only.

### 7.1 The arm

Env gate **`UPD6383_NOPZ`**, default **0 = shipped behaviour bit-for-bit**; `=1` adds
`&& addr8 == 0x00` to the guard. ⚠ **No spec-mask bit is proposed and the reason is
measured, not asserted: 61 of 64 bits are referenced and the only three that are not
(1, 2, 3) are SET in the default `0xB910E446A39B440F` — the u64 mask is exhausted.**
Two counters, **printed unconditionally in `device_stop()` whatever their value** (rule 8
as §220 sharpened it — printing under `if (count)` makes "fired zero times" and "never ran"
the same log line): `nopguard_hits` (guard intercepted) and `nopguard_passed` (narrowing
let a word through).

### 7.2 The vehicle — `a99 PEQ+OVERDR+DELAY`, **TYPE 36, the TOP RAIL**

Not `a09 SINGLE DELAY`. `a09` is walk index **7** ⇒ **29 DOWN presses**, squarely in the
28–30-step regime that dropped steps and voided a previous run. `a99` is walk index **36**
⇒ **`TYPEIDX=36 TYPELAST=36`, ZERO DOWN presses** — the one landing that cannot lose a
press, reached by the UP saturation the script already performs (45 UP for 36 steps).
And it carries the **same ladder shape** as the acc-adder's word:

```
   a99 w43 (I-RAM 127)   202.A.01.655 | **000.2.FF.000** | 212.2.00.419      ← multiply → swallowed → STORE
   a99 w95 (I-RAM 179)   the addr8 == 0 form, as an in-run control
   a09 w7  (I-RAM  91)   202.A.B8.655 | **000.2.48.000** | 212.2.00.419      ← the word the comment names
```

**F0 — fingerprint, named:** the last `I-RAM[84..*]` transfer before the note window must
read **522 bytes / `I-RAM[84..187]`** (104 words × 5 + 2).
⛔ **FAIL, named: `487 bytes / I-RAM[84..180]`** ⇒ landed 35 = `a97 PEQ+COMPR+OVERDR` ⇒
**the run is VOID**; do not adjust the index to fit.

### 7.3 The instrument — the TRACE, **not** `§104`

`§104`'s sampler arms at `m_frames_run > 420000` and **never resets**, so a
`type_select` run pools ≈ 1.76 M cold-boot CHORUS frames with ≈ 0.4 M `a99` frames at the
same slot numbers while `m_sp_word[]` prints `a99`'s word beside CHORUS's numbers — the
§174/§195 confound. Use the time-ordered trace, armed by `UPD6383_TRACE_FRAME` inside the
note window. Read `word`, `dp`, `acc`, `L` at I-RAM **127** and **179**, both arms.
(Real columns: `n iw u1 word dp acc accb p cur coef MUL L` — the header string is stale.)

### 7.4 The controls, whose answers are ALREADY KNOWN from logs on disk

| # | control | **PASS — the number already measured** | ⛔ **FAIL, named** |
|---|---|---|---|
| **C1** | KERNEL `iw57` `000.2.01.000` newly executes under the narrowing, and must be an identity | `acc` at iw57 = **2 603 010 048** (unchanged), because `mem = 0` and `P = 2 603 010 048 = acc` in all seven archived logs | `acc` at iw57 reads **0** ⇒ the arm is loading something other than `P` |
| **C2** | the address generator is invariant | `dp` at iw58 = **0xFE** (and iw57's own `dp` = **0xFD**) in both arms | any other value ⇒ the §90 regression has been re-introduced ⇒ **VOID** |
| **C3** | the gate is consulted at all | on the **cold-boot** vehicle the intercept counter = **21 per frame exactly** (1 KERNEL + 20 `a16` body-1 sites, from the census) | **0** (never consulted) or any count that is not 21 × frames ⇒ the census and the build disagree ⇒ **VOID before interpreting anything** |

**C1–C3 are read BEFORE anything else in the log.** A run whose calibration scores less
than 3 of 3 is void by this project's own rule.

### 7.5 The NULL, computed from the logs already on disk — and pre-registered as the LIKELY outcome

On the archived vehicle **`mem` is non-zero at 51 of 285 executed slots (17.9 %)**, and at
**21 of 21** swallowed sites it is `0..0` over 1 020 000 frames. Under that base rate the
prior probability that **both** `a99` sites also sit on dead cells is ≈ **0.67**.

> ★ **PRE-REGISTERED: "no difference at 2 of 2 sites" does NOT vindicate the guard.** It
> reproduces the standing null and means only that the guard is not load-bearing on this
> vehicle either — which is already this note's verdict. It must be reported as
> *"the null held"*, never as *"the nop reading is confirmed"*.

**What would falsify "not load-bearing", named:** in the narrowed arm, `L` at I-RAM **127**
becomes non-zero **and** `acc` at I-RAM **128** differs between the arms.
⛔ **The failure mode, named: `acc` at I-RAM 128 identical to the control arm to the last
bit** ⇒ the guard is not load-bearing on `a99` either, and the static change in §6 stands
on consistency alone, with no runtime claim attached to it.

---

## 8. SUMMARY — ten lines

1. **VERDICT: TOO BROAD, and NOT LOAD-BEARING.** The guard tests `hi12`, `class4` and
   `lo12` but **not `addr8`**, so it swallows 41 words carrying live pointer deltas
   (`+72`, `−70`, `−75`, …) that no `nop` evidence in this tree covers. **MEASURED.**
2. **103 of 103 sit MID-LADDER.** Zero terminal, zero carrying the END bit, zero in a
   trailing run, 90 of 103 ≥ 10 words from the end — padding / alignment / tail is refuted
   outright, and the 350 siblings have the same positional profile (349/350 interior).
3. **The correct predicate is already written twice in the same repo:** `decoded()`
   (`upd6383d.cpp:728`) requires `ad == 0x00`, and the shipped `.dsm` listings print the 62
   as `nop` and the 41 as **`?word`**. The core is the odd one out.
4. **62 vs 41 is the real split.** The 62 pair up (21 of 38 runs ≥ 2 — the reverb motif's
   `nop nop`, 113 of 114 cores in `r1-allpass-motif.md`); the 41 are **0 of 41** paired and
   **46 %** are immediately followed by a bit-4 STORE.
5. **`hi12 == 0x000` is not "nop" anywhere else in the build:** 818 of 3057 words carry it
   and **715 run the full ALU** as `f31 = 0` LOAD, including the `000.2.49.407` the §66
   comment calls load-bearing.
6. **The contradiction is real but its citation is stale.** `000.2.48.000` (= `a09 SINGLE
   DELAY` w7) is intercepted, while the comment says it "has to produce `bus + P`" — and
   round 6 **VOIDED** that leg, round 7 item E downgraded `order = adder` to **CONSISTENT**.
7. **NO OPERAND IS NON-ZERO ANYWHERE IT CAN BE MEASURED.** 21 of the 103 execute in the
   archived logs (KERNEL `iw57` + 20 body-1 sites); all 21 read `mem 0..0` in both buckets
   over **1 020 000** frames, and at `iw57` the executed result is an **exact identity**
   (`P = acc = 2 603 010 048`). The other **82** are **unmeasured**, not measured-zero.
8. ⚠ **Instrument caveat added:** `§104`'s `L` column is **stale at a swallowed slot**
   (`m_last_l` is written only inside `exec_alu()`), so **only the `mem` column** measures
   these words' operand.
9. ⚠ **Territory:** **0 of 103 in the EPILOGUE**; **20 of 103 in body 1**, all in
   `a16 ROOM REVERB 1` (I-RAM 213…300, including the §90 `iw213`) — reported, **not
   analysed**, and handed to that lane.
10. **The one experiment recommended** — and only if a runtime claim is wanted, because
    the static fix needs none: gate the narrowing behind `UPD6383_NOPZ` (default OFF, two
    unconditional counters), load **`a99 PEQ+OVERDR+DELAY` at TYPE 36 — the top rail, zero
    DOWN presses** — fingerprint **522 bytes / `I-RAM[84..187]`** (FAIL: 487 / `[84..180]`),
    trace I-RAM 127 and 179, and read the three already-known controls first
    (`acc@iw57 = 2 603 010 048`, `dp@iw58 = 0xFE`, intercepts = **21 per frame**).
    **The null — "no difference" — is the likely outcome and is pre-registered as NOT a
    vindication.**
