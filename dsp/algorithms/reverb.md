# REVERB — the tank, read as a reverb

Program: the **reverb**, image rep **algo 16** (`ROOM REVERB 1`), unit 1 (I-RAM
200), 133 words — the largest program in the corpus, and the **only** unit-1
image. It is shared byte-for-byte by the **12 reverb presets** (algos 16–27: Room
1/2, Plate 1/2, Concert 1/2, Dark 1/2, Bright 1/2, Wave/Stage…); the character of
each preset lives entirely in its **coefficient and DRAM-tap streams**, not its
code. Listing:
[`../disasm/prog16_room_reverb_1.dsm`](../disasm/prog16_room_reverb_1.dsm).

Deep note: `notes/kn5000-dsp-reverb.md` and `notes/kn5000-dsp-cursor-general.md`.
Every claim there is tagged MEASURED / INFERRED / SPECULATIVE; this is the concise
distillation.

## Structure — MEASURED

The 133-word program is built from an **8-instruction motif repeated 9 times**, in
two blocks of **5 and 4**, and 5 of its 8 words occur in **exactly the 13 reverb
programs and nowhere else** in the 96-program corpus — a strong structural
fingerprint. The two blocks are the two **all-pass diffuser ladders** predicted by
the coefficient bank.

> **Corrections, MEASURED, 2026-07-26** (`../analysis/r1-allpass-motif.md` §1.1,
> re-measured with `../tools/r1_allpass_solve.py census`):
> * the motif is **not** byte-identical at every repetition — `addr8` of its 6th
>   word (the class-A multiply) is `0xBA` at the head of ladder 1 in all twelve
>   presets, and `0xC4` once in GATED REVERB. Every other field of every other
>   word is constant, over all 114 core occurrences;
> * ladder 1 has **four** repetitions, not five ("two ladders of five" is wrong
>   for the code, though the *parameter stream* really does tile 5+5 buffers —
>   that off-by-one is still open);
> * GATED REVERB (algo 8) carries **6** cores, not 4;
> * the ladder gains are **not** strictly descending in PLATE REVERB 2 or
>   BRIGHT REVERB 1 (10 of 12 presets, not 12).
>
> The **per-repetition semantics** of the motif are worked out by constraint
> solving in [`../analysis/r1-allpass-motif.md`](../analysis/r1-allpass-motif.md):
> the core is a software-pipelined one-multiplier all-pass stage, the `880.1.60`
> word is the delay-DRAM **read** and `880.1.20` the **write**, and the write
> trails the read by exactly one stage. Two role assignments still survive.

The coefficient bank (unit-1 base **0x90**), read off the named-coefficient
overlay in the listing. The values shown are **ROOM REVERB 1**'s, i.e. algo 16,
the image this listing is generated from:

```
C-RAM[0x90..92]  input scaling triple      0.250 0.500 0.500
C-RAM[0x93..95]  damping triple #1         0.384 0.198 -0.206   (op 0x76)
C-RAM[0x96]      DRAM tap gain             0.500      <- consumed by separator w12
C-RAM[0x97]      op0x75 reverb decay       0.200
C-RAM[0x98..9C]  diffuser ladder-0         0.750 0.630 0.520 0.500 0.400   (REVERB TIME)
C-RAM[0x9D]      DRAM tap gain             0.500      <- consumed by separator w60
C-RAM[0x9E..A0]  damping triple #2         0.438 0.363 -0.415   (op 0x76)
C-RAM[0xA1..A4]  diffuser ladder-1         0.630 0.620 0.520 0.400         (REVERB TIME)
C-RAM[0xA5]      DRAM tap gain             0.500      <- consumed by separator w102
C-RAM[0xA6..A8]  damping triple #3         0.438 0.363 -0.415   (byte-identical
                                           to #2 -- the stereo mirror)
C-RAM[0xA9..B4]  LEFT / RIGHT output tails (op 0x66 / ER.LEVEL); 37 cells in all
```

> **Correction, MEASURED 2026-07-26.** An earlier revision of this table was a
> *mixture*: its damping triples were ROOM REVERB 1's (correct) but its ladder-0
> gains were **CONCERT REVERB 1**'s (`0.750 0.630 0.620 0.600 0.500`), under a
> heading that says the table was read off the *ROOM REVERB 1* listing, and its
> ladder-1 entry `"0.520 …"` was right for neither preset. All 37 cells above are
> now re-measured from algo 16; the per-preset table for all twelve presets is in
> [`../analysis/r1-allpass-motif.md`](../analysis/r1-allpass-motif.md) §2.
>
> **Second correction, and it resolves something.** `notes/kn5000-dsp-reverb.md`
> §3 reads the bank as "**two 5-gain ladders**" at bank indices 9–13 and 17–21.
> The cursor map says otherwise: the nine all-pass cores consume exactly
> **0x98–0x9C (five)** and **0xA1–0xA4 (four)**, while **0x96, 0x9D and 0xA5** —
> one of which the old reading counted as ladder B's fifth gain — are consumed by
> the three ladder **separators** (`000.A.00.695` at w12/w60/w102, all three
> valued 0.500). So the coefficient bank holds **5 + 4 diffuser gains and 3
> separator tap gains**, and **the coefficient side now agrees with the code at
> nine stages.** The remaining part of the "9 stages vs 10 buffers" puzzle is on
> the *delay-address* side alone.

Both chains are descending gain ladders in **10 of the 12 presets** — the textbook
diffuser signature (PLATE REVERB 2 and BRIGHT REVERB 1 permute the same values;
MEASURED, `../analysis/r1-allpass-motif.md` §2). All 33 class-A multiplies of the
image land on one of these named slots, so the reverb is named **33/33**.

The base **0x90** is now PROVEN BY CONSTRUCTION, not inferred: every type-2
coefficient block in the parameter stream is preceded by a literal
`08 01 09 08 21` packet — the instruction word `801.0.90.821` = `ldptr #$90`
(`../analysis/r1-allpass-motif.md` §2).

## Delay lengths — MEASURED, in the parameter stream

The delay-buffer lengths are **not** in the microcode. They are **external-DRAM
address pairs in the parameter (coefficient) stream**, in a contiguous-tiling form
that occurs in the 13 reverb slots and in **none** of the other 57 named effects —
two chains of five delay buffers each. The microcode reaches them only through the
`880.1.60` / `880.1.20` words — a **READ** and a **WRITE**, not a bracket
(the bracket reading is withdrawn; the direction is FORCED, `../analysis/r1-allpass-motif.md`
§5 F1) — never by naming a delay cell.

> ### ⚠ Every number this file's sources used to quote was HALF the real one
>
> R3 (`../analysis/r3-delaydram.md` §2) proved by construction that a descriptor
> payload is the **24-bit poke value** `2 × raw + tagbyte bit 7`, not the raw
> three bytes. Corrected ladders (samples at 44.1 kHz):
>
> | preset | ladder 0 | ladder 1 |
> |---|---|---|
> | ROOM REVERB 1 | 255 869 979 366 1044 | 528 1252 359 675 |
> | ROOM REVERB 2 | 510 1740 1878 734 2088 | 1057 2505 639 1351 |
> | PLATE REVERB 1 | 904 2181 3095 1382 2747 | 1676 3569 1112 1948 |
> | CONCERT REVERB 1 | 904 1957 2154 1382 1578 | 1276 2924 992 1548 |
> | WAVE REVERB 1 | 904 2981 8295 1382 4347 | 1676 4169 6512 2548 |
>
> (5.8 → 188 ms, the range a diffuser network wants; the raw reading gave
> 2.9 → 94 ms, short for the long stages.) `PRE DELAY` likewise: `ROOM REVERB 1`
> is **800 samples = 18.1 ms** above the region floor, and the twelve presets
> spread over 20 / 500 / 800 / 1000 / 2000 samples. The full table is in
> `../analysis/r3-delaydram.md` §7.3. R1's *solve* is unaffected — it never uses
> a delay value, and an all-pass ladder is exact for any positive integer delay.

## Where a delay address comes from — ANSWERED

```
   delay-DRAM address = ( DESCRIPTOR_CELL[cursor] + G )  mod 2^N
```

**PROVEN BY CONSTRUCTION** (`../analysis/r3-delaydram.md`). The cells are a
host-written bank behind pointer `…825` / tag `0x4C`; a cell holds
`LINE_BASE + DELAY_IN_SAMPLES`, so **a delay is an address and a line's delay is
the difference of two cells** — which is exactly the "contiguous-tiling address
pairs" shape this file already described, now explained. The reverbs are the
unit-1 programs and own delay memory `[0x8000, 0x10000)` — 32,768 words =
**743.0 ms**. Every reverb writes `32768` (its own floor) and `32767` (the top of
unit 0's region, one below).

The cell for each DRAM word comes from an implicit auto-incrementing cursor in
program order, which lands the alternating read/write pair of R1's forced core on
an alternating pair of cells whose successive differences **are** the diffuser
delays — a non-trivial cross-check between two passes that used entirely
different evidence. ⚠ The *tail* of that alignment is not settled: guarded of
R3's C-format contamination the reverb writes 32 cells and contains 28 consuming
words (`../analysis/isa-adjudication.md` §2.2).

## Read against the priors

The shape is a Schroeder/Moorer/Dattorro-family reverb: input scaling → **series
all-pass diffuser ladders**, **one-pole damping filters** embedded in the loop
(poles near 0.99996 / 0.99906 / 0.96290 in the banks), long DRAM delays, and
mirrored **stereo output tails**. The one-multiplier all-pass realisation the code
implements is

```
    w = delay_read(D) ;  s = x + w ;  t = g·s ;  d_in = x + t ;  y = w − t
```

and the six-word core computes it **software-pipelined**: repetition *r* finishes
the arithmetic and the delay-line write of stage *r−1* while starting the read and
the multiply of stage *r*. That is forced by the word order — the multiply is the
last of the six words and both delay-DRAM words precede it, so the core *cannot*
write its own stage's `d_in`.

> **Withdrawn.** This section used to say the all-pass write/partner pair "is
> visible in the listing as `012.2.00.680` (`d_in ← x + t`, the WRITE) /
> `000.2.00.419` (`y ← d_out − t`)". Those are **one of two** role assignments
> that survive the constraint search, and the corpus ranks the *other* one first.
> The per-word roles are not settled and the listing no longer prints them.

## Proven vs open

- **PROVEN/MEASURED:** the motif and its 9 repetitions (5 + 4), the two descending
  diffuser ladders (in 10 of 12 presets), the three damping triples, the three
  separator tap gains, the two output tails, the DRAM-tiling delay form, and every
  class-A coefficient's name. **PROVEN BY CONSTRUCTION:** the bank base 0x90.
- **DETERMINED:** `880.1.60.2D4` is the delay-line READ and `880.1.20.655` the
  WRITE; the read data lands 2–5 words later; the `hi12` bit-4 store takes the
  accumulator *before* its own word's ALU step; the write trails the read by one
  ladder stage.
- **PROVEN BY CONSTRUCTION (new):** where the delay-line **address** comes from —
  the descriptor bank behind `…825` / tag `0x4C` (see the section above). This has
  been removed from the OPEN list.
- **OPEN:** which of the two surviving role assignments is the real one (they are
  numerically indistinguishable — both reproduce the cascade at max|err| = 0 over
  all 12 banks); whether `880.1.20.*`'s `lo12` selects the write-data source
  (44/44 vs 0/56 says it does — and R3 **half-settled this in the direction R1
  hedged**: the cursor alignment reads `880.1.20.2C7` as a READ, which removes the
  0/56 arm and leaves family B ranked on the 44/44 arm alone); the separator's
  class-A word appearing to clobber `P` three words before its consumers; the
  9-repetition / 10-buffer off-by-one on the *address* side; and the four surplus
  descriptor cells. ⚠ **`addr8` does NOT select the DRAM direction** — falsified
  by R3 §6.3, so the `60`=read / `20`=write reading holds only for `2D4`/`655`.
  These are shared with the whole ISA worklist (`../instruction-set.md`).

## The other reverbs

`GATED REVERB` (algo 8, unit 0) is a **separate** structure — an all-pass ring
with a hold gate — at *medium* confidence, not part of this 12-preset tank. See
`../disasm/prog08_gated_reverb.dsm` and the effect-map note.
