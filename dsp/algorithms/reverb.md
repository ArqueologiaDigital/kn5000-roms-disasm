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
two blocks of 5 and 4. The motif is **byte-identical** at every repetition, and 5
of its 8 words occur in **exactly the 13 reverb programs and nowhere else** in the
96-program corpus — a strong structural fingerprint. The two blocks are the **two
ladders of five all-pass diffusers** predicted by the coefficient bank.

The coefficient bank (unit-1 base **0x90**), read off the named-coefficient
overlay in the listing:

```
C-RAM[0x90..92]  input scaling triple      0.250 0.500 0.500
C-RAM[0x93..95]  damping triple #1         0.384 0.198 −0.206   (op 0x76)
C-RAM[0x96]      DRAM tap gain             0.500
C-RAM[0x98..9C]  diffuser ladder-0         0.750 0.630 0.620 0.600 0.500   (REVERB TIME)
C-RAM[0x9D]      DRAM tap gain             0.500
C-RAM[0x9E..A0]  damping triple #2         0.438 0.363 −0.415   (op 0x76)
C-RAM[0xA1..A4]  diffuser ladder-1         0.520 …               (REVERB TIME)
C-RAM[0xA5]      DRAM tap gain             0.500
C-RAM[0xA6..A8]  damping triple #3
C-RAM[0xA9..B0]  LEFT / RIGHT output tails (op 0x66 / ER.LEVEL)
```

Both chains are **strictly descending gain ladders** — the textbook diffuser
signature — matching the two 5-gain ladders derived independently from the
coefficient bank. All 33 class-A multiplies of the image land on one of these
named slots, so the reverb is named **33/33**.

## Delay lengths — MEASURED, in the parameter stream

The delay-buffer lengths are **not** in the microcode. They are **external-DRAM
address pairs in the parameter (coefficient) stream**, in a contiguous-tiling form
that occurs in the 13 reverb slots and in **none** of the other 57 named effects —
two chains of five delay buffers each. The microcode reaches them only through the
`880.1.60/20` external-DRAM bracket (OPEN/CLOSE), never by naming a delay cell.

## Read against the priors

The shape is a Schroeder/Moorer/Dattorro-family reverb: input scaling → **series
all-pass diffuser ladders** (`w = x + g·d ; y = d − g·w`, the `+g`/`−g` giveaway),
**one-pole damping filters** embedded in the loop (poles near 0.99996 / 0.99906 /
0.96290 in the banks), long DRAM delays, and mirrored **stereo output tails**. The
all-pass write/partner pair is visible in the listing as the annotated
`012.2.00.680` (`d_in ← x + t`, the WRITE) / `000.2.00.419` (`y ← d_out − t`).

## Proven vs open

- **PROVEN/MEASURED:** the motif and its 9 repetitions, the two descending
  diffuser ladders, the three damping triples, the two output tails, the
  DRAM-tiling delay form, and every class-A coefficient's name.
- **OPEN:** the exact per-step semantics of the all-pass marker `104.2.00.000`
  (its *position* differs between reverb and phaser, so which step it performs is
  unidentified) and whether `880.1.20.*` latches the write *address* or the
  *data*. These are shared with the whole ISA worklist
  (`../instruction-set.md`).

## The other reverbs

`GATED REVERB` (algo 8, unit 0) is a **separate** structure — an all-pass ring
with a hold gate — at *medium* confidence, not part of this 12-preset tank. See
`../disasm/prog08_gated_reverb.dsm` and the effect-map note.
