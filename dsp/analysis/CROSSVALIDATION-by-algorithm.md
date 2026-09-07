# Cross-validating the decode by algorithm identity (KN5000 ↔ WSA1R)

**Date 2026-09-07.** The two products run the same uPD6383GF ISA, and — this note shows —
the same *programs*: for a shared effect, the disassembled **idiom sequence** (the order of
coefficient MACs, biquad state updates, delay accesses) is the same on both chips. When one
side's algorithm is already SOLVED, the structurally-identical other side is validated *by
construction* — the same instructions in the same order compute the same thing. This is a
promote-toward-measured that needs no hardware.

Instrument: `dsp/tools/dsp_idiom_sequence.py` (reads the committed `.dsm`).

## PARAMETRIC EQ — the clean result

The KN5000 PARAMETRIC EQ is SOLVED: a Direct-Form-I bilinear biquad chain, validated against
its designer to **0.198 dB**. Its idiom sequence is the biquad band `MMMMM aMMa` (five
coefficients b0/b1/b2/−a1/−a2, then the state combine) repeated:

```
  KN5000 PARAMETRIC EQ  105 words  ->  10 biquad sections  (5 bands x 2 channels)
  WSA1R  PARAMETRIC EQ  120 words  ->  12 biquad sections  (6 bands x 2 channels)
  coefficient-MAC run lengths, BOTH:  [5,2, 5,2, 5,2, ...]  -- identical pattern
```

The WSA1R EQ is the **same algorithm** — same DF-I biquad, same 5-coefficient band, same z⁻¹
state pair — with one more band per channel. So the WSA1R PARAMETRIC EQ decode (110 of 120
words strict-decoded) is **validated by construction against the KN5000's SOLVED biquad**:
there is no room for the extra words to mean anything other than a sixth band. This is the
highest-decode program on both chips and now cross-confirmed as biquad on two silicon
instances.

## It generalises across the shared effects

- **SINGLE DELAY** — both are the delay-tap-with-feedback pattern (`Dzz…MMDMas…` per tap)
  repeated for two taps, ending in the wet/dry combine. Same structure; the WSA1R tap body is
  a few MACs longer. (The KN5000 SINGLE DELAY is independently validated bit-exactly by its
  ROM-predicted echo, `sd_rerun.py`.)
- **ENHANCER** — **0 biquad sections on both**: it is *not* a biquad, consistent with its
  role ("phase/emphasis shaping"), and the two agree on that.
- **PEQ+… combinations** — the WSA1R consistently carries ~2× the biquad sections of the
  KN5000 combination (e.g. PEQ+COMPRESSOR: KN5000 2, WSA1R 4), i.e. the WSA1R runs the EQ
  stage of a combi in stereo where the KN5000's combi EQ is folded — a real, specific
  structural difference, visible in one number.

## Why this matters for the decode

The strict decoder needs measured evidence per field; the algorithm-identity argument is a
*different* kind of evidence — global rather than per-word. Where a program's whole idiom
sequence matches a SOLVED algorithm, every word's role is pinned by the structure even if a
field is individually OPEN. PARAMETRIC EQ is the strongest case (a textbook biquad, SOLVED on
one chip, byte-structurally identical on the other). It is exactly the "get the model in place
using what we know" the goal asked for, on the firmest possible footing: no speculation, just
two independent silicon instances of the same textbook filter.
