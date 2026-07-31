# `iw205` and the cell it reads — why it is zero, and why `0xD0` is the wrong address

**Written 2026-07-31. STATIC + EXISTING LOGS ONLY.** No emulator was run, no source was
edited, nothing was built. Every number is read out of a log already in
`dsp/analysis/data/`, out of the ROM corpus via `dsp/tools/pat_corpus.py`, or out of
`kn7000_mame/src/devices/cpu/upd6383/upd6383.{cpp,h}`.

This note answers the three questions put to it, and the answer to the third one
**changes the answer to the first two**, so it is taken first.

| tag | file | arm |
|---|---|---|
| **A** | `data/drpub_A_off_217.log.gz` | shipped default, `mask 0xB910E446A39B440F` |
| **B** | `data/drpub_B_on_217.log.gz` | `UPD6383_DRPUB=1` |
| **C** | `data/drpub_C_on_src0b2_217.log.gz` | `DRPUB=1` + `SRC0B2=1` |
| — | `data/src0b2_{A_off,B_on}_215.log.gz` | corroboration |

Scripts written for this pass (scratch, not committed):
`d0_walk.py`, `sel0d.py`, `pickup.py`, `writers85.py` — all of them load the corpus
through `dsp/tools/pat_corpus.py`, and the destination census is
`dsp/tools/act0d.py` re-run unmodified.

---

## 0. THE ANSWER IN ONE PARAGRAPH

**`iw205` does not read `D-RAM[0xD0]`. It reads `D-RAM[0x85]`** — the unit-1 *base*
cell, `DRAM_UNIT_BASE | DRAM_UNIT_STRIDE`. `0xD0` is the pointer the word *parks for
`iw206`*, and `OUTPUT-STAGE-NULL_findings.md` §1.2/§3(c) read it off the frame trace's
post-increment `dp` column. With the address corrected, everything inverts:
**`0xD0` HAS producers** (`iw207`, `iw208`, `iw210`, all inside body 1, two slots later
— a closed read/modify/write loop whose zero is *caused by* the selector-1 reading and
is therefore not independent evidence for it); and **`0x85` has NO producer at all** —
zero I-RAM words write it, the one candidate (`iw70`) is a mode-1 word whose store the
shipped mask routes into `m_rf[0x85]`, and the host writes it once with zero
(`§186 85:1(z)`). Meanwhile **`m_bx_sel0d = 1` is not a guess and not a decode gap: it
is MEASURED EXACT on the unit-0 twin.** `iw85 = 000.2.0E.1CD` is the same word form
reading the *unit-0* base cell, and in arm C `§104` row 85 shows `ACCA` after the slot
equal to `L × 65536` **to the unit** (`−8 034 877 × 65536 = −526 573 699 072`;
`7 192 534 × 65536 = 471 369 908 224`) — which is `bx_acc_w(L,false)` and nothing else.
Arms A and B, where the same cell is empty, give `0..0` at the same slot. Same word,
same decode, different cell content.

**Classification: NO PRODUCER, on a CORRECTLY DECODED and CORRECTLY ADDRESSED word.**
`iw205` is body 1's **input pickup**, structurally identical to body 0's `iw85`
(38 of 38 corpus images put their first `lo12 0x1CD` word at base+0, against a 2.1 %
null). It reads zero because the reverb's input cell is never filled — which is the
unit-1 deposit question, owned by another lane, and **not** an `ACT 0x0D` question.

★ **NEW STANDING CONSTRAINT (the most useful thing in this note):** `m_bx_sel0d` must
be **FROZEN at 1** and treated as a regression control. Any change to it to "rescue"
`ACCB` at `iw205` simultaneously destroys body 0's only demonstrably working audio
pickup at `iw85`. The `79 438 ± 90` DC that `OUTPUT-STAGE-NULL_findings.md` §6.5(ii)
names as the counter-example is *exactly* what breaking that pickup produces.

---

## 1. Q3 FIRST — IS `0xD0` THE RIGHT ADDRESS? **NO. It is `0x85`.**

### 1.1 The derivation from the word's own fields

`iw205 = 202.2.4B.1CD` (`a16 ROOM REVERB 1` w5, `dsp/disasm/prog16_room_reverb_1.dsm`
line `w5    020224B1CD`).

* `class4 = 2` ⇒ `ptr_postinc(w)` is true (`upd6383d.h:900`:
  `!c_format(w) && (class4(w) & 7) == 2`).
* `addr8 = 0x4B` = **+75** signed — a *displacement*, not an address. The word carries
  **no address of its own**.
* `lo12 = 0x1CD` ⇒ `SRC = lo12[10:6] = 0x07` (`mem[ptr]`), `ACT = lo12[4:0] = 0x0D`
  (RULE 18).

So the operand address comes entirely from the pointer. The pointer at body-1 entry is
`m_dp = base` with `base = DRAM_UNIT_BASE | (unit1 ? DRAM_UNIT_STRIDE : 0)`
= `0x05 | 0x80` = **`0x85`** (`upd6383.cpp:4803`, `upd6383.cpp:4824`;
`upd6383.h:280-281`, both labelled FORCED).

The ROM then walks it — and walks it **back to exactly where it started**:

```
  iw200  880.1.30.00B   class 1  -> no displacement
  iw201  000.2.89.415   -119
  iw202  212.A.81.1D5   -127
  iw203  202.A.FD.1D5     -3
  iw204  202.A.F9.1D5     -7
                        ------
                          -256   == exactly one full wrap of the 256-cell D-RAM
  iw205  202.2.4B.1CD   reads at the pointer  = base + 0 = 0x85,
                        then parks it at base+75 = 0xD0 for iw206
```

Grade: **PROVEN BY CONSTRUCTION** (the four deltas are in the ROM; their sum is
`−256` exactly, `pickup.py` §Q3c). The wrap makes the pickup address independent of the
value of `DRAM_UNIT_BASE`, which is a design signature, not a coincidence.

### 1.2 The read happens BEFORE the word's own post-increment — three independent proofs

1. **BY CONSTRUCTION.** In `exec_alu()` the operand is fetched at
   `const u8 rdsrc = regfile ? … : m_dp;` (`upd6383.cpp` ~:2806, quoted in
   `OUTPUT-STAGE-NULL_findings.md` §3(d)), and the post-increment
   `if ((cl & 7) == 2) m_dp = u8(m_dp + dd);` is the **last** statement of the same
   function (`upd6383.cpp:3949`). The fetch cannot see it.
2. **BY THE FILE'S OWN COMMENT.** `upd6383.cpp` §35 (~:2934):
   *"They are the latches **because the walk is built so the post-increment parks the
   pointer on the cell the NEXT word reads**."*
3. **MEASURED, on a slot where the two cells differ.** `§104` (arm C) row 202:
   `iw202 = 0212A811D5`, `dp` column `0E`, `mem` column `−78..69`, `L` column
   `−78..69` — `L` is *identical to* `mem[dp-before]`. `dp-after` for that word is
   `0x8F`, whose content is `0` (`D-RAM WRITES 8F:0/1188302`). If the read were
   post-increment, `L` would be `0`. It is not.

Grade: **FORCED** (three independent routes, one of them a live measurement on a slot
where the two candidate answers differ).

### 1.3 The walk model, calibrated 29 of 29 against the shipped log

`d0_walk.py` CAL-1 + `writers85.py` reproduce `§104`'s `dp` column ("mem UNDER the
pointer BEFORE it") from the ROM alone:

```
  body 1 iw200..219                     20 of 20 agree
  kernel  iw9, iw11, iw35, iw37, iw45    5 of  5 agree (all 0x05)
  body 0  iw111 -> 05 ; iw130 -> 03      2 of  2 agree
  body 1  iw319 -> 85 ; iw330 -> 85      2 of  2 agree
  ---------------------------------------------------
  29 of 29, zero disagreements
```

A single disagreement would void the model; there are none. Grade: **MEASURED**.

### 1.4 What would change the address

Only three things, all outside this word: (a) `DRAM_UNIT_STRIDE`, currently `0x80`
(`upd6383.h:281`, labelled FORCED as "E1 − E0, = R2's unit bit"); (b) the *site* of the
per-unit rebase, which `upd6383.h:264-271` explicitly says is **NOT** forced — though it
also states that *"every admissible siting gives the SAME pointer at body entry"*;
(c) any un-modelled `m_dp` load — and `upd6383.cpp:4004` records that **no decoded word
loads `m_dp`**. The frame closure is exact under the shipped values
(`0x85 + net(reverb −133) + delta(60..82 −1) = 0xFF`, `0xFF + delta(0..44 +6) = 0x05`),
which is a non-trivial consistency check the model passes. Grade: **INFERRED** that the
address is right; **FORCED** that it is `0x85` *given* the shipped base.

---

## 2. Q1 — WHO IS SUPPOSED TO WRITE IT?

### 2.1 The cell `iw205` actually reads: `D-RAM[0x85]` — **NO PRODUCER**

`writers85.py` enumerates every store in the resident frame
(kernel `iw0..59`, `a01 CHORUS` `iw84..153`, kernel B `iw50..59`,
`a16 ROOM REVERB 1` `iw200..332`, `EPILOGUE` `iw60..81`), applying the emulator's own
target rules — bit-4 store to `m_dram[pre-increment m_dp]`, mode-1 store to
`addr8 | (unit1 ? 0x80 : 0)`, and `store_mode()`'s regfile route
(`upd6383.cpp:626-630`, live because shipped mask bit 23 = 1):

```
  D-RAM[0x05]  (unit-0 pickup)   6 writers that reach D-RAM:
      kernelA iw9    012.2.FF.1D5  bit-4  mode 2
      kernelA iw11   400.2.01.447  ACT07  mode 2
      kernelA iw35   012.A.00.1C0  bit-4  mode 2
      kernelA iw37   092.A.01.1C0  bit-4  mode 2
      kernelA iw45   010.A.00.20C  bit-4  mode 2
      body0   iw111  092.2.00.700  bit-4  mode 2

  D-RAM[0x85]  (unit-1 pickup)   0 writers that reach D-RAM:
      epilogue iw70  2A6.1.85.0C7  ACT07  mode 1 -> m_rf[85]   <-- NOT D-RAM
```

Corroboration: `§96` (arm C, log line 2588) reports *"cell 85 written by iw70 word
2A61850C7"* — `§96` prints the **destination index**, not the array (`kwatch(stdest,…)`,
`upd6383.cpp:2971`), so it does not contradict the routing above. `§186 HOST tag-0x15
WRITE TARGETS` (log line 2748) shows `85:1(z)` — the host writes the cell **once, with
zero**, in the same sweep that zeroes `D0:1(z) D1:1(z) D2:1(z) 87:1(z) 8A:1(z) 8B:1(z)
94:1(z)`, i.e. the per-effect state reset.

Direct content measurement: `§104` row 205, all three arms —
`mem quiet 0..0 / loud 0..0 '='`, over `706 040 / 313 960` profiled frames.

> ⚠ **DO NOT quote `D-RAM WRITES 85:0/1204622` as "the cell was never non-zero".**
> That instrument is heterogeneous: at `upd6383.cpp:1503` the counter block sits
> **outside** the `if ((hi & HI_ST) && !st_suppressed_live(word))` guard (a *visit*
> counter); at `:2976` it is inside the guard but outside the inner store; and at
> `:3671-3672` `m_dwr_nz` tests `u32(L) & 0xffffff`, i.e. **the datum, not the cell**.
> The `1 204 622` on `0x85` is `iw70`'s once-per-frame ACT-07 visit with `L = 0`, and it
> says nothing about `D-RAM[0x85]`. The cell's content is measured by `§104`'s `mem`
> column and by nothing else in these logs.

Grade: **MEASURED** for the content (`§104` row 205, three arms);
**PROVEN BY CONSTRUCTION** for the writer map (`writers85.py` over the corpus, using the
device's own target predicates); **INFERRED** that no un-modelled route fills it — that
is the one thing §6 asks a run to close.

### 2.2 The cell the previous note named, `D-RAM[0xD0]` — **producers exist, and the zero is CIRCULAR**

```
  iw205  202.2.4B.1CD   ACT 0x0D  reads [85], parks the pointer at [D0]
  iw206  000.2.00.40E   SRC 0x10 (acc)                        dp = D0
  iw207  212.A.00.1D5   BIT-4 STORE acc -> [D0]   and SRC 0x07 read <- [D0]
  iw208  212.A.00.415   BIT-4 STORE acc -> [D0]
  iw209  202.A.00.1D5   SRC 0x07 read <- [D0]
  iw210  202.2.00.407   ACT 0x07 store  -> [D0]
```

So `0xD0` is a genuine read/modify/write **state cell** with three writers, all inside
body 1, all storing the accumulator. Under `m_bx_sel0d = 1` the accumulator at
`iw207/208` is the one `iw205` has just loaded with `0`, and the loop has **no other
input** — `iw202/203/204` read `D-RAM[0x0E]/[0x8F]/[0x8C]` (`§104` rows 202-204: `L`
`0..0` at 203 and 204), and every coefficient multiplies zero. `0` is an absorbing
state.

★ **Therefore `D-RAM[0xD0] = 0` is an OUTPUT of the selector-1 model, not an input to
it.** `OUTPUT-STAGE-NULL_findings.md` §1.2 uses it as the *cause* of `ACCB ← 0`; it is
the *consequence*. Even if the address had been right, the argument would have been
circular. Grade: **PROVEN BY CONSTRUCTION** (the five words are in the ROM; the loop is
closed) + **MEASURED** (`§104` rows 205-213 all `0..0`).

### 2.3 The classification, stated plainly

| cell | role | producers | verdict |
|---|---|---|---|
| `0x05` | unit-0 input pickup | 6 I-RAM words + host | filled in arm C, empty in arms A/B |
| **`0x85`** | **unit-1 input pickup — what `iw205` reads** | **none; host once, with zero** | ⛔ **NO PRODUCER** |
| `0xD0` | body-1 filter state, `base+75` | `iw207`, `iw208`, `iw210` | producers exist; zero is circular |

The unit-1 deposit is the **send** question and belongs to whichever lane owns it. What
this note establishes is only that it is *not* an `ACT 0x0D` question and *not* a decode
gap: nothing about `iw205` needs to change for the reverb to receive audio.

---

## 3. Q2 — IS `m_bx_sel0d`'s SELECTOR 1 THE RIGHT READING?

### 3.1 The field and its eight values

`m_bx_sel0d = u32((m_specmask >> 42) & 7)` (`upd6383.cpp:304`); shipped mask
`0xB910E446A39B440F` ⇒ **`sel0d = 1`**. Companion: `m_bx_sel0e = (mask >> 45) & 7 = 7`
(`upd6383.cpp:305`); `m_bx_supp_ta = bit 52 = 1` (`upd6383.cpp:308`).

| value | what `iw205` would do | source |
|---|---|---|
| **0** | the second switch is skipped, so the **blanket capture** at `upd6383.cpp:3242-3257` runs and `ACT 0x0D` becomes `m_ta = L` — i.e. **value 0 ≡ tempA** | `:3251` excuses the blanket capture only when `m_bx_sel0d != 0` |
| **1** | `bx_acc_w(L,false)` ⇒ `acc = u64(L) << ACC_SHIFT` (unit-aware: `m_accb` when bits 56 and 14 are set and `m_cur_unit1`) | `:3318`, `upd6383.h:1369-1375` |
| 2 | `m_ta = L` (tempA) | `:3319` |
| 3 | `m_tb = L` (tempB) | `:3320` |
| 4 | `m_dram.write_dword(m_dp, L)` — a **memory WRITE at the pre-increment pointer**, i.e. `[0x85] ← [0x85]`, a no-op at this site | `:3321` |
| 5 | `m_p = L` (raw scale) | `:3322` |
| 6 | `bx_acc_w(L,true)` ⇒ `acc += L << 16` | `:3323` |
| 7 | `m_p = L << ACC_SHIFT` | `:3324` |

### 3.2 Values 0, 2 and 3 are EXCLUDED by the corpus, with a working calibration

`dsp/tools/act0d.py`, re-run unmodified (window 4, its own null):

```
  ACT   n     ->tempA        ->tempB       verdict
  0D   203   6/203    3%    5/203    2%    NO SEPARATION
  13    40   0/ 40    0%    1/ 40    2%    (anchored tempA)
  14    58  20/ 58   34%   58/ 58  100%    -> tempB
  19    89  74/ 89   83%   16/ 89   18%    -> tempA
  null over an arbitrary ALU word: tempA 16.7 %, tempB 10.2 %
```

`sel0d.py`, window 2, **PLAIN words only** (LEDGER dead end 16 / RULE 18 — `act0d.py`'s
`n = 203` includes bit-11 words; the plain count is 200):

```
  consumer sources tempA (SRC 0x19):  null 3.6 %   ACT 0x0D   0/200 = 0.0 %   DEPLETED
  consumer sources tempB (SRC 0x1A):  null 5.4 %   ACT 0x0D   4/200 = 2.0 %   DEPLETED
        calibration: ACT 0x14 (anchored tempB) scores 42/42 = 100 % on tempB
  consumer sources acc   (SRC 0x10):  null 42.3 %  ACT 0x0D 136/200 = 68.0 %  ENRICHED
  consumer sources mem   (SRC 0x07):  null 49.5 %  ACT 0x0D 112/200 = 56.0 %  at null
```

The anchored codes separate cleanly (`0x14` → 100 % tempB, `0x19` → 83 % tempA), so the
test is not blind. `ACT 0x0D` scores **0 of 200** on tempA against an expected ~7
(`P ≈ 7 × 10⁻⁴`) and **below null** on tempB while the anchored tempB writer scores
100 %. Grade: **MEASURED counts**, **FORCED exclusion** of selectors 0, 2 and 3.

Value 4 is a self-write no-op at this site and cannot be the intended semantics of a
word whose SRC is `mem[ptr]`; values 5 and 7 write `P`, which `§135` already measured
railing unit 1 at `−0x800000` on 98.9 % of presentations when applied corpus-wide
(`upd6383.cpp:3334-3345`). Grade: **INFERRED** for 4/5/7 — neither supported nor
excluded by this instrument alone.

### 3.3 Value 1 is MEASURED EXACT — on the unit-0 twin, in the shipped logs

`iw85 = 000.2.0E.1CD` is body 0's `0x1CD` word. Identical `lo12`, identical `SRC 0x07 /
ACT 0x0D`, and its operand is `D-RAM[0x05]` — the unit-0 base cell (`§104` `dp` column
`05`, reproduced by the static walk). `§104` row 85, quiet‖loud:

```
  arm A  (D-RAM[0x05] empty)   mem  0..0 / 0..0  '='    acc after   0..0 / 0..0  '='
  arm B  (D-RAM[0x05] empty)   mem  0..0 / 0..0  '='    acc after   0..0 / 0..0  '='
  arm C  (D-RAM[0x05] LIVE)    mem  0..0 / -8034877..7192534  '*'
                               L    0..0 / -8034877..7192534  '*'
                               acc  0..0 / -526573699072..471369908224  '*'
```

and

```
  -8034877 x 65536 = -526573699072      EXACT
   7192534 x 65536 =  471369908224      EXACT
```

`65536 = 2^ACC_SHIFT`. That is `dst = u64(L) << ACC_SHIFT` (`upd6383.h:1374`) and
nothing else in the menu produces it:

* **selector 6 (ADD) is EXCLUDED**: `§104` row 84 leaves `acc` at
  `−864 633 992 785..773 989 370 423`; an ADD would put row 85's minimum at
  **`−1 391 207 691 857`**. It is `−526 573 699 072`, with **no pedestal at all**.
* **selectors 0/2/3/4/5/7 are EXCLUDED at this site**: they leave `ACCA` to the word's
  own `f31`, and row 85's `acc` would then not track `L` at a fixed ratio, let alone at
  exactly `2^16`.

★ Same word form, same decode, three arms, and the accumulator is input-dependent
exactly when the cell is filled and zero exactly when it is not.
**This is a controlled contrast that is already on disk and needs no run.**
Grade: **MEASURED**, and the strongest single result in this note.

### 3.4 The consequence for anyone tempted to "fix" `iw205`

`m_bx_sel0d` is **global**. Changing it away from 1 to make `ACCB` survive `iw205`
changes `iw85`, `iw130`, `iw319` and `iw330` at the same time — including the one word
in the whole machine that is measured turning a live D-RAM cell into a live accumulator.
`OUTPUT-STAGE-NULL_findings.md` §6.5(ii)'s `79 438 ± 90` pedestal at `w78` is precisely
the shape of that mistake: kernel B's constant `5 206 020 096` surviving into the
presentation because the LOAD that would have replaced it was removed. It is a DC
(mean 79 438, AC amplitude ±90, −59 dB) *and* it is a regression.

---

## 4. THE `lo12 0x1CD → lo12 0x40E` LEAD — REPLICATED, and UPGRADED from SPECULATIVE

`CORPUS-PATTERNS-SPECULATIVE.md` S-2 is reproduced exactly by an independent
implementation (`sel0d.py`):

```
  0x1CD words: 152 in 38 images      0x40E words: 81 in 37 images
  0x40E immediately preceded by 0x1CD : 79 of 81  (97.5 %)   <- S-2 says 79 of 81
  predecessors of every 0x40E : {1CD: 79, 1D5: 2}            <- the 2 are a48 AUTO PAN
```

**Extension, and it is the part that matters here.** S-2 counts the *pair*; the decisive
statistic is what the successor **sources**:

```
  successors of every 0x1CD:  40E x79, 412 x38, 1CE x30, 687 x4, 6CE x1
       0x40E -> SRC 0x10 (acc)     0x412 -> SRC 0x10 (acc)
       0x1CE -> SRC 0x07 (mem)     0x687 -> SRC 0x1A (tempB)   0x6CE -> SRC 0x1B

  a lo12 0x1CD word is IMMEDIATELY followed by a word SOURCING THE ACCUMULATOR
      116 of 152 = 76.3 %      null (arbitrary plain word) = 558/2528 = 22.1 %
      one-sided binomial P(>=116 of 152 | p = 0.2207) = 1.1e-45
```

**And the pair is confirmed DYNAMICALLY at a resident site**, in arm C, `§104`:

```
  iw85  000.2.0E.1CD   L (mem[0x05])  loud -8034877..7192534   ->  ACCA = L<<16
  iw86  000.2.DE.40E   SRC 0x10       L    loud -8034877..7192534
```

`iw86`'s `L` is `acc_to_datum(ACCA)` and equals `iw85`'s operand **to the unit**. S-2's
arm 1 ("the output is a function of both") therefore **holds**, and S-2 moves from
SPECULATIVE to MEASURED for this site — with one correction to its proposed reading:

> S-2 guessed *"`ACT 0x0D` deposits `mem[ptr]` into a latch that `ACT 0x0E` then
> consumes together with the accumulator."* **The latch is the accumulator itself**
> (`bx_acc_w`), and `ACT 0x0E`'s consumer reaches it through `SRC 0x10`, not through a
> separate register. S-2's own control, `a48 AUTO PAN`, is **not resident** in this
> vehicle and remains untested.

**Bearing on Q1:** the lead does **not** name a producer for `0x85`. What it does is
confirm the *destination* half of `ACT 0x0D` (accumulator ⇒ selector 1 or 6), which §3.3
then narrows to 1. Grade: **MEASURED** counts, **MEASURED** dynamic confirmation at one
site, **SPECULATIVE** for the other 78.

### 4.1 One S-2-adjacent hypothesis that FAILED, reported because it failed

"`0x1CD` reads a *filter state* cell, so its own program writes that cell back" —
tested in `d0_walk.py` Q1b over the FORCED walk:

```
  152 0x1CD sites; read cell later written by the same program: 120 (78.9 %)
  NULL, all other SRC 0x07 memory reads:                        622 of 765 (81.3 %)
```

**At the null.** The state-cell reading is *not* supported corpus-wide; it is only true
locally at `iw205` (where the writer is `iw207`, two slots later) and that local fact is
the circularity of §2.2, not evidence. Grade: **MEASURED negative.**

### 4.2 The statistic that DOES separate: `0x1CD` is the body's INPUT PICKUP

`pickup.py`, over the FORCED walk with each body entered at its base:

```
  the FIRST lo12 0x1CD word of each body image reads at base+0 :  38 of 38 images
  NULL: an arbitrary SRC 0x07 read lands on base+0             :  15 of 726 = 2.1 %
  P(38/38 | p = 0.021)  ~  1e-64
```

Every image, including the four whose first `0x1CD` sits deep in the program
(`a06 ENSEMBLE` w36, `a97` w45, `a96` w41, `a99` w35). Body 1's *three* `0x1CD` words —
`iw205`, `iw319`, `iw330` — all read `0x85` (`§104` `dp` column `85`, `85`, `85`,
matching the static walk). Grade: **MEASURED corpus statistic**; the reading
("`0x1CD` = the per-unit input pickup") is **FORCED** given §3.3's measured behaviour at
`iw85`.

---

## 5. VERDICT TABLE

| claim | classification | grade |
|---|---|---|
| `iw205`'s operand is `D-RAM[0x85]`, not `[0xD0]` | **ADDRESS ERROR in the previous note** | **FORCED** (source ordering + the file's own §35 comment + `§104` row 202 where the two candidates differ) |
| `D-RAM[0x85]` has no I-RAM producer | **NO PRODUCER** | **PROVEN BY CONSTRUCTION** (`writers85.py`) + **MEASURED** (`§104` row 205, three arms) |
| `D-RAM[0xD0]` has producers and its zero is circular | **not evidence for anything** | **PROVEN BY CONSTRUCTION** |
| `m_bx_sel0d = 1` (`acc ← L << 16`) | **CORRECT** | **MEASURED EXACT** (`§104` row 85 arm C, to the unit; A/B/C contrast) |
| selectors 0, 2, 3 | **EXCLUDED** | **MEASURED** (`act0d.py` + `sel0d.py`, calibration passes) |
| selectors 4, 5, 6, 7 | 6 **EXCLUDED** by row 85's absent pedestal; 4/5/7 unsupported | **MEASURED** (6) / **INFERRED** (4, 5, 7) |
| `iw205` is a "DECODE GAP with a routing consequence" (`OUTPUT-STAGE-NULL_findings.md` §5.2) | ⛔ **RETRACT** | this note |
| "`iw205` kills 128 of body 1's 133 slots" | **true, but it is a MESSENGER** — it faithfully loads an empty cell | **MEASURED** |
| `lo12 0x1CD` = the body's input pickup at base+0 | 38 of 38 vs a 2.1 % null | **MEASURED** |
| `D-RAM WRITES (nonzero/total)` is a per-cell content census | ⛔ **NO** — heterogeneous; `:3671` tests `L`, `:1503` counts visits | **PROVEN BY CONSTRUCTION** |

---

## 6. THE PRE-REGISTERED EXPERIMENT

Most of the question is decided statically, so the run below is deliberately small: it
exists to close the one thing static analysis cannot — *is there an un-modelled route
that writes `D-RAM[0x85]`* — and to make the address ordering a machine-reported fact
rather than my reading of it.

### 6.1 What it is

**§E-D0 — THE PICKUP ADDRESS-AND-PROVENANCE AUDIT. READ-ONLY. NO GATE, NO DECODE
CHANGE, NO MASK BIT.** New env counter `UPD6383_PICKUP=1`, default 0, fired count
printed (rule 8).

On settled frames (`m_frames_run > 900 000`, RULE 16), for every executing word with
`lo12 == 0x1CD`, record: `m_cur_iw`; **the pointer BEFORE and AFTER the post-increment,
as two separate columns**; which array was indexed (`m_dram` / `m_rf`) and at which
index; the value, split quiet/loud; `ACCA`/`ACCB` before and after. Separately, for the
two pickup cells `0x05` and `0x85` **only**, a full writer census: every write, its site
(1 = `exec_addressing_only` bit-4, 2 = `exec_alu` bit-4, 3 = ACT-07), its `iw`, its
mode, and whether it landed in `m_dram` or `m_rf`.

Vehicle: the CLEAN one (standing rule 2), notes 21.0 s → 27.5 s, `-seconds_to_run 30`,
`-log`, visible video (RULE 12: a DSP test with no notes playing is not a test).
Arms: **A (shipped) and C** — C is required, because A's `0x05` is empty and the
calibration F3 cannot fire there.

### 6.2 THE NULL — computed from the logs on disk BEFORE the run

| # | quantity | predicted |
|---|---|---|
| **N1** | resident `lo12 0x1CD` executions per frame | **exactly 5**: `iw85`, `iw130` (body 0), `iw205`, `iw319`, `iw330` (body 1) |
| **N2** | their operand addresses (pointer BEFORE) | **`0x05`, `0x03`, `0x85`, `0x85`, `0x85`** — constant on 100 % of settled frames |
| **N3** | their pointers AFTER | **`0x13`, `0x0D`, `0xD0`, `0x8D`, `0x00`** (`= addr8` added: `+14, +10, +75, +8, +123`) |
| **N4** | writers of `D-RAM[0x85]` from any I-RAM word | **ZERO.** Provenance HOST, one write, value 0, age = whole run |
| **N5** | writers of `D-RAM[0x05]` from I-RAM | **exactly 6 sites**: `iw9`, `iw11`, `iw35`, `iw37`, `iw45`, `iw111` |
| **N6** | arm C, `ACCA` after `iw85`, loud | **exactly `L × 65536`**: min `−526 573 699 072`, max `471 369 908 224` |
| **N7** | `ACCB` after `iw205`, every arm | **`0..0`**, quiet and loud |
| **cal** | vehicle | `§54` loud ≈ **313 960** frames; `§104` `nq/nl` = **706 040 / 313 960**. A loud count of 0 **VOIDS** the run |

### 6.3 THE FALSIFIERS — each names a specific wrong number

> **F1 — the decisive address check.** *The audit reports `iw205`'s operand address as
> `0x85`.*
> **F1 FAILS if it reports `0xD0`.** That is the exact off-by-one this note corrects, it
> means the instrument samples `m_dp` after the post-increment, and **no address in the
> run may be quoted**. `0xD0` is the named wrong number.

> **F2 — the one that can actually teach us something.** *No I-RAM word writes
> `D-RAM[0x85]`; its provenance is HOST for the whole run.*
> **F2 FAILS if any `iw` appears** — and that outcome is *better* than the prediction
> holding: it names the word that is supposed to fill the reverb's input. The most
> likely candidate is a **mode-1 store whose routing into `m_rf` is wrong**
> (shipped mask bit 23 = 1, `upd6383.cpp:626-630`) — `iw70 = 2A6.1.85.0C7` is the only
> word in the resident frame that addresses index `0x85` at all.

> **F3 — the calibration that can fail.** *In arm C, `ACCA` after `iw85` equals
> `L × 65536` exactly on ≥ 99 % of loud frames, and `L` equals `mem[0x05]`.*
> **F3 FAILS ⇒ the instrument is mis-wired and the run is VOID** — no other number in
> it may be quoted (the `§46` unguarded-sample trap). This is the only line in the run
> whose answer is already known from a *different* mechanism, which is what makes it a
> calibration rather than a restatement.

### 6.4 THE DECISION RULE, WRITTEN BEFORE THE DATA

* **F1, F2, F3 all hold** (the predicted outcome): `iw205` is **exonerated** exactly as
  `w73` was by `§211`. `ACT 0x0D` and `m_bx_sel0d` come **off** the decoding worklist
  and go **onto** the regression-control list. The unit-1 null is an empty input cell,
  and the next pass belongs to whoever owns the unit-1 deposit — not to this note and
  not to the epilogue.
* **F2 fails**: name the word, the mode and the array. That is a routing error, it is
  one line, and it is the whole result.
* **F1 fails**: void, fix the sample point, re-run. Nothing else is salvageable.

### 6.5 ★★★ FAILURE MODES, WITH THEIR WRONG NUMBERS STATED IN ADVANCE (RULE 19)

**(i) The `w78` DC, and why it is now also a REGRESSION.** If anyone changes
`m_bx_sel0d` away from 1, `w78` presents

```
  mean            79 438          AC amplitude   +/- 90        (-59 dB signal-to-DC)
  no-stimulus window already wobbles +/- 40 around the SAME pedestal
```

exactly as `OUTPUT-STAGE-NULL_findings.md` §6.5(ii) records. **Report the mean and the
AC amplitude separately; this is not audio.** New, and specific to this note: the *same*
change makes `§104` row 85 lose its `*` marker and collapse from
`−526 573 699 072..471 369 908 224` to a constant. **Any run whose `w78` mean is 79 438,
or whose row-85 `acc` is not exactly `L × 65536`, has broken the only pickup in the
machine that demonstrably works.**

**(ii) The ADD arm's number.** If `m_bx_sel0d = 6` is tried, `§104` row 85's `acc`
minimum becomes **`−1 391 207 691 857`** (`= −864 633 992 785 + −526 573 699 072`)
instead of `−526 573 699 072`. One line of the *existing* table distinguishes ADD from
LOAD; no new run is needed to reject 6.

**(iii) The constant-fill trap.** If `D-RAM[0x85]` is filled with a **constant** — by a
host poke, by a mirror of a parameter cell, or by any `m_rf`→`m_dram` aliasing — unit 1
*will* produce a non-zero `w78` with a long tail, and it will pass standing rule 1, pass
`§211`'s translation rule, and be a **DC with AC amplitude 0**. A reverb fed a constant
is a constant. Under RULE 19 the mean and the AC amplitude must be reported separately
**before** the word "audible" is used, and the loud/quiet AC ratio must exceed the
`2.2×` that the §6.5(ii) counter-example already achieves without being audio.

---

## 7. HONEST LIMITS

* **What a run cannot change.** §1 (the address), §2.2 (the circularity), §3.2/§3.3
  (the selector) and §4.2 (base+0, 38 of 38) are decided by the ROM, by the C++ control
  flow, and by measurements already on disk. §6 is not asked to re-decide them; F3 only
  re-checks the instrument against one of them.
* **What is genuinely open, and only a run decides:** whether some path outside the
  resident-frame model writes `D-RAM[0x85]`. The static map covers bit-4 stores,
  ACT-07 stores, `store_mode()`'s two routes and the host packet census. It does **not**
  cover the `§78` delay-publish path, the K6 input-latch deposit, or any bit-11 word
  whose `m_dp` wanders (`§191` reports `m_dp 0..255 chg 25920` on three bit-11 words —
  those pointers do sweep the whole space, and a store from one of them is exactly the
  kind of thing this map would miss). **That is F2, and it is the reason to run at all.**
* **Scope.** *Why* `D-RAM[0x85]` is empty is the unit-1 deposit question. This note
  deliberately stops at "it is empty and nothing in the program writes it" and makes no
  proposal about the deposit; another lane owns that.
* **`DRAM_UNIT_STRIDE = 0x80` is taken as given.** It is labelled FORCED
  (`upd6383.h:281`) and the frame closure is exact under it, but this pass did not
  re-derive it. If the stride were wrong, `iw205`'s pickup would be `0x05` and the whole
  unit-1 body would already be running on unit 0's audio — which it visibly is not, so
  the stride is at least *consistent*. That is weaker than FORCED and is labelled
  **INFERRED** here.
* **The three unit-1 pickups are not distinguished.** `iw205`, `iw319` and `iw330` all
  read `0x85`; nothing in this pass explains why the reverb picks its input up three
  times per frame from one cell. Body 0's two `0x1CD` words read *different* cells
  (`0x05`, `0x03`). Open, and not load-bearing for this question.
* `§175`'s per-site `m_dp` columns show a spurious low minimum (`0212A811D5 m_dp 14..142`
  where the settled value is `14`). Those aggregates are **not frame-gated** and include
  boot frames with other programs resident (RULE 16). Only the maxima were used above,
  and only as corroboration.

---

## 8. TEN-LINE SUMMARY

1. **`iw205` does not read `D-RAM[0xD0]`. It reads `D-RAM[0x85]`.** The operand is
   fetched at the pointer *before* the word's own post-increment (`upd6383.cpp` fetch
   ~:2806 vs post-increment :3949; the file's own §35 comment; and `§104` row 202 where
   the two candidates hold different values). `0xD0` is the pointer parked for `iw206`.
2. `0x85 = DRAM_UNIT_BASE | DRAM_UNIT_STRIDE`, and `iw201..iw204`'s displacements sum to
   **exactly −256**, so the ROM deliberately returns the pointer to base+0 for `iw205`.
   The static walk reproduces `§104`'s `dp` column **29 of 29**, zero disagreements.
3. **Why it is zero: `D-RAM[0x85]` has NO PRODUCER.** Zero I-RAM words write it; the one
   word that addresses index `0x85` (`iw70 = 2A6.1.85.0C7`) is mode-1 and the shipped
   mask routes its store into `m_rf[0x85]`; the host writes the cell once, with zero
   (`§186 85:1(z)`). By contrast the unit-0 twin cell `0x05` has **six** I-RAM writers.
4. `0xD0` — the address the previous note named — *does* have producers (`iw207`,
   `iw208`, `iw210`), and its zero is **circular**: selector 1 zeroes the accumulator
   that those three words then store back into it. It was never independent evidence.
5. **Selector 1 is CORRECT, and MEASURED EXACT.** On the unit-0 twin `iw85`
   (same `lo12 0x1CD`, same `ACT 0x0D`), arm C `§104` row 85 gives
   `acc = L × 65536` **to the unit** — `bx_acc_w(L,false)` and nothing else.
   Arms A/B, where the cell is empty, give `0..0`. Selector 6 (ADD) is excluded by the
   absent pedestal; 0/2/3 are excluded by `act0d.py`/`sel0d.py` against a calibration
   that passes (anchored `ACT 0x14` scores 42/42).
6. **The S-2 lead replicates** (79 of 81) and is **upgraded**: 116 of 152 `0x1CD` words
   are immediately followed by a word **sourcing the accumulator** (null 22.1 %,
   `P = 1.1e-45`), and the pair is confirmed *dynamically* at `iw85→iw86`. Its proposed
   "latch" is the accumulator itself. It does **not** name a producer for `0x85`.
7. **What `lo12 0x1CD` really is: the body's INPUT PICKUP at base+0 — 38 of 38 images,
   against a 2.1 % null.** `iw205` is body 1's pickup exactly as `iw85` is body 0's.
8. **Classification: NO PRODUCER, on a correctly decoded and correctly addressed word.**
   Not a decode gap, not a routing error, not a wrong address (for `0x85`) — a wrong
   address *in the previous note*, and an empty cell.
   `OUTPUT-STAGE-NULL_findings.md` §5.2's `iw205` row should be retracted.
9. ★ **New standing constraint: FREEZE `m_bx_sel0d` at 1 and use `§104` row 85 as a
   regression control.** It is global; changing it breaks body 0's working pickup and
   produces the `79 438 ± 90` DC (−59 dB) that §6.5(ii) already names.
   Named wrong numbers: `w78` mean **79 438**; `§104` row-85 acc min **−1 391 207 691 857**
   under an ADD; operand address **0xD0** under a mis-sampled instrument.
10. **The one experiment I recommend: §E-D0**, a read-only pickup address-and-provenance
    audit (no gate, no decode change), arms A and C. Its whole point is **F2**: *does any
    I-RAM word write `D-RAM[0x85]`?* Predicted **none** — and a failure names the word,
    which is the better outcome. F1's named wrong number is `0xD0`; F3 (arm C, `ACCA`
    after `iw85` = `L × 65536`) voids the run if it fails.
