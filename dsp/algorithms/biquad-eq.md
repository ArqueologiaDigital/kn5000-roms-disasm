# PARAMETRIC EQ — the biquad, SOLVED to the bit

Program: **`PARAMETRIC EQ`**, image rep **algo 39**, unit 0 (I-RAM 84), 105 words,
60 class-A multiplies (all 60 named). Listing:
[`../disasm/prog39_parametric_eq.dsm`](../disasm/prog39_parametric_eq.dsm).
This is the **reference program**: the one whose dataflow is decoded exactly, and
the positive control for the whole named-coefficient join.

Deep note: `notes/kn5000-dsp-semantics.md` (the exhaustive constraint search) and
`notes/kn5000-dsp-biquad*.md`. This doc is the concise distillation; the note
carries the 19.7-million-assignment search and the impulse-response proof.

## Structure — MEASURED

The EQ is **5 bands × 2 channels**, each band a **second-order section in Direct
Form I**:

```
y[n] = b0·x[n] + b1·x[n-1] + b2·x[n-2] − a1·y[n-1] − a2·y[n-2]     (÷ a0)
```

A **9-word section** implements one band and is repeated **10 times, byte for
byte** (5 bands × 2 channels). The coefficient cursor supplies six coefficients
per band from consecutive C-RAM cells; the `rstcur` between the two channels
sends the cursor back to base so the second channel re-reads the same six-cell
layout with its own bank (`notes/kn5000-dsp-biquad-map.md` §2).

## The section, word for word — DETERMINED

Read off the listing (cursor base 0x00; the six coefficients are C-RAM[0x00..05]):

| word | disasm | operation | coefficient |
|---|---|---|---|
| `000.A.00.1D3` | `?word … [read into carry latch A]` | `P = b1·S0 ; latch A ← S0` | **C-RAM[0x00] = b1** |
| `212.A.01.412` | `?word … [writes mem[ptr]]` | `S0 ← x ; acc = P ; P = b0·x` | **C-RAM[0x01] = b0** |
| `202.A.01.1D5` | `mac (p)+1` | `acc += P ; P = b2·S1` | **C-RAM[0x02] = b2** |
| `202.A.01.1D4` | `mac.lb (p)+1` | `acc += P ; P = −a1·S2 ; latch B ← S2` | **C-RAM[0x03] = −a1** |
| `202.A.00.1D5` | `mac (p)+0` | `acc += P ; P = −a2·S3` | **C-RAM[0x04] = −a2** |
| `102.2.FF.687` | `?word … [P-consumer, stores latch B]` | `acc += P ; S3 ← latch B` (class 2) | — |
| `804.8.16.415` | `?word … [class 8: post-sum step]` | post-sum step on `acc` (operation UNKNOWN) | — |
| `212.A.FF.407` | `mulst (p)+FF` | `S2 ← acc ; P = makeup·acc` | **C-RAM[0x05] = make-up gain** |
| `000.2.03.647` | `?word … [P-consumer, stores latch A]` | `acc ← P ; S1 ← latch A` (class 2) | — |

Four state cells `S0..S3` are the Direct-Form-I delay line; **two of the four
state writes are folded into multiply instructions** (`212.A.01.412` writes `S0`,
`212.A.FF.407` writes `S2`), which is why only two explicit class-2 stores
appear. Word `[7]` — the make-up gain × accumulator — was determined **uniquely**
by the search.

## What is proven vs open

- **PROVEN:** the cell walk, the coefficient order `b1,b0,b2,−a1,−a2,makeup` at
  C-RAM[0x00..05], and exact impulse-response agreement on **9 real ROM
  coefficient banks** (max|err| = 0). This is the positive control that validates
  the whole C-RAM named-coefficient join across the corpus.
- **OPEN:** what the **class-8** word (`804.8.16.415`) actually computes — its
  *position* between "the sum is complete" and "the sum becomes stored state" is
  determined, its *operation* (rescale/round/saturate?) is not.

## Where the biquad reappears

The same section is the building block of the **combination** effects: every
`PEQ+…` program (algos 71–99) opens with one or more flat 50.1 Hz / Q 10.0181
biquad bands (`b ≡ a`, make-up −2.0) before its other blocks — the cleanest
demonstration that these programs are compiled from a common library. Algo 99
(`PEQ+OVERDRIVE+DELAY`) contains **four** biquad sections, two of them a
byte-for-byte copy of `OVERDRIVE`'s 4 kHz Butterworth tone stage.
