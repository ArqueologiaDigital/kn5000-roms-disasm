# The EQ band, read from the BYTECODE — and what my flatness model left out (2026-09-12)

`N-INPUT-GATE-OPENED §6` refuted a prediction of mine and left one instruction: stop assuming the
EQ's topology from the cell names and **read it from the program**. This note does that, from
`dsp/disasm/prog39_parametric_eq.dsm` (grade **SOLVED**, 105 words, 60 named multiplies). No
emulator run is involved.

## 1. The band, word by word (from the listing's own annotations)
```
w5   ld.ta  (p),c+,(p)+0     P = b1·S0        ; latch A ← S0          [C-RAM 0x00 = b1]
w6   mac    acc,c+,(p)+1     S0 ← x ; acc = P ; P = b0·x              [0x01 = b0]
w7   mac    (p),c+,(p)+1     acc += P         ; P = b2·S1             [0x02 = b2]
w8   mac.tb (p),c+,(p)+1     acc += P         ; P = −a1·S2 ; latch B ← S2   [0x03 = −a1]
w9   mac    (p),c+,(p)+0     acc += P         ; P = −a2·S3            [0x04 = −a2]
w10  mac.st tb,(p)-1         acc += P         ; S3 ← latch B
w11  post   acc,c            ★ class-8 post-sum step — OPERATION UNKNOWN
w12  mac.st acc,c+,(p)-1     S2 ← acc         ; P = makeup·acc        [0x05 = makeup]
w13  ld.st  ta,(p)+3         acc ← P          ; S1 ← latch A
```
State cells per band: `S0 = x`, `S1 = x1`, `S2 = y1`, `S3 = y2`. The five multiplies are
`b1·x1 + b0·x + b2·x2 + (−a1)·y1 + (−a2)·y2` — **so the DF-I reading is CORRECT**, and my
assumption in `N-SINGLE-DELAY-RECURRENCE §10` was right about that much. The latches do the
delay-line shuffle: A carries the old `S0` into `S1`, B carries the old `S2` into `S3`.

## 2. What §10's model LEFT OUT — and it is not a scale, it is two whole words
The flatness solve computed `|H| = |b(z)/a(z)|` from five cells. The program has **two more steps
between the sum and the band's output**, and both are outside that model:

* **`w12` — the makeup multiply.** The value handed to the next band is **`makeup · acc`**, while
  the value stored as `y1` is the **pre-makeup** sum. So the band's transfer function is
  `makeup · H(z)`, and its recursion uses the un-scaled sum — a structure `|b/a|` cannot express.
  The makeup cell is `0x800000`: **−1.0 read as Q0.23, −2.0 read as Q1.22** — so it is a candidate
  for the measured per-band gain of ±2. ⚠ **Checked in the trace, and it is NOT the carrier in
  these captures.** At `w12` (trace `iw96`, band 0) the product is `−549 755 748 352`, which is
  exactly `−(L << 16)` for `L = 8 388 607`: the makeup multiply is measured at **−1.0**, not −2.
  (All the clean captures run `UPD6383_PSHIFT=2`, where `0x800000 × L >> 7` is exactly `−L`.)
  So the makeup explains the **sign alternation** the trace shows — band 0's `y` is the exact
  negation of band 1's `x` — and explains none of the magnitude. The ±2 must come from `w11` or
  from the coefficient scales, and `w11` is the only unmodelled step of the two.
* **`w11` — a class-8 word whose OPERATION IS UNKNOWN**, sitting exactly where a fixed-point
  biquad puts its output scaling. The device currently models class 8 as doing no multiply (the
  handoff notes the biquad "reproduces to 0.094 dB with class 8 doing no multiply at all" — a
  statement about a *ratio*, which is blind to a uniform gain). Corpus: **44 class-8 words in 17
  programs**, 35 of them the single encoding `0804816415` — the one in this band. Ten occurrences
  in prog39 alone: one per band per channel.

## 3. Consequence for the scale thread (corrects §10 in place)
§10's three ratios (`b0/1 = 0.2500`, `b1/a1 = 0.5000`, `b2/a2 = 0.2500`, spread 0.00000 over five
bands) are still exactly what the ROM cells say — that arithmetic used no trace and no model of
the program. What is now clear is that **"scale b0,b2 ×4 and b1 ×2" was the wrong conclusion to
draw from them**: it assumed the only things between the coefficients and the output were the
coefficients. With `w11` unknown and `w12` a makeup multiply on the output path but not the
recursion, the same cell values can be consistent with a flat band through a different route
entirely. §10's ratios are a **constraint to be explained**, not a correction to be applied — and
`EQSCALE`'s failure is exactly what a wrong application looks like.

## 4. What to do next, in order
1. **Decode `w11` (`0804816415`).** It is the single open operation inside the project's *reference*
   program, it occurs 35 times corpus-wide in one encoding, and it sits in the one place where a
   uniform output gain would live. Everything about the EQ's level is downstream of it.
2. ~~Settle the makeup cell's format~~ — **done here, negatively**: it is measured at −1.0 in the
   captures, so it is not the source of the ×2 (it is the source of the per-band sign flip).
3. Only then revisit the b-path ratios — with `w11` and `w12` in the model, not outside it.

## Honest grade
§1 is a READ of a SOLVED listing (the disassembler's annotations, not my inference) and it
CONFIRMS the DF-I structure. §2 is a READ plus a MEASUREMENT: the makeup multiply is −1.0 in the trace, which
KILLS the tidy "it's the makeup format" account I wrote first and leaves `w11` as the only
unmodelled step that can carry the ×2. §3 corrects §10's
conclusion while leaving its measurement intact. Nothing here changes the device.
