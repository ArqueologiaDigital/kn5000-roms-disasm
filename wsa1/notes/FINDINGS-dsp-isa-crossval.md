# The WSA1R DSP microcode is a third corpus of the KN5000 uPD6383GF ISA

The SX-WSA1R carries **three uPD6383GF-3BA** effects DSPs — the *same* chip as
the KN5000's IC311 — and its ROMs are dumped. Running the KN5000 uPD6383 ISA
model over the WSA1R's DSP upload streams cross-validates that ISA against a
corpus the KN5000 tooling had never seen, and supplies real occurrences of the
word forms the KN5000's own 40 effect programs never exercise.

**Reproducer (committed beside this note):**

- `dsp/analysis/wsa1_dsp_isa_crossval.py` — extractor + analysis, stdlib-only,
  read-only, self-testing. `--selftest` reproduces the KN5000 baseline
  (3057 words / 1178 decoded) from the ROM as a gate before analysing the WSA1R.
- `dsp/analysis/data/wsa1_dsp_isa_crossval.log` — archived deterministic report
  (fixed RNG seeds; re-runs byte-identical).

Run: `python3 wsa1/dsp/analysis/wsa1_dsp_isa_crossval.py [--selftest]`

## Where the streams are (MEASURED)

The WSA1R DSP microcode is the relocatable byte-stream pool at prom_c
**0xFCD0F7–0xFDD2AA** (`original_ROMs/wsa1_prom_c.ic28`, BASE 0xF80000). Its
framing is byte-identical to the KN5000 Sub-CPU bytecode: opcode-3 records carry
the 5-byte program instruction words (after a cmd byte + 16-bit I-RAM address),
opcode-2 records carry 3-byte Q0.23 coefficients — the exact split the KN5000
tools use. Tiling is taken from the authoritative
`notes/gen_prom_c_p7stream_pool.py` (its `--verify` gates the framing). From the
297 STREAM objects: **70 opcode-3 records → 5,777 program words** (918 distinct)
and 99 opcode-2 records → 2,562 coefficients.

Structural pre-check (STRONG): all 70 opcode-3 payloads are an exact multiple of
5 bytes (70/70), and all 5,777 words have bits[36:39]==0 — the KN5000 container
invariant holds on a ROM the KN5000 tools had never seen.

## Decode rate vs NULL (MEASURED)

Predicate = `dsp_disasm.alu_decoded` (mirrors the C++ `alu_decoded()`).

| corpus | words | decoded | rate |
|---|---:|---:|---:|
| KN5000 (reference) | 3,057 | 1,178 | **38.53 %** |
| WSA1R | 5,777 | 1,992 | **34.48 %** |

Nulls (WSA1R-sized, 20 trials): uniform-random 0.03 %, byte-shuffle 0.40 %,
field-shuffle 22.43 % (KN5000 field-shuffle 28.49 % for symmetry). WSA1R decodes
~1,285× over uniform random and ~87× over byte-shuffle, within ~4 points of the
KN5000. Honest caveat: field-shuffle (keeps each field's marginal, destroys
correlation) already reaches ~22–28 %, so much of the raw rate is the shared
marginal distribution; the real corpus sits ~1.5× (WSA1R) / ~1.35× (KN5000)
above its own field-shuffle. The decisive point is that **both corpora sit in
the same regime on every null** — exactly what "same ISA, same field layout"
predicts.

## Field histograms agree in shape (MEASURED)

Dominant forms match and rank the same in both: hi12 000/212/202/880/102/104/
092/182/082/804; class4 mode 2 then A (WSA1R uses mode 1 more, 11 %→22 %); SRC
07/10/00; ACTION 00/15/07/0E/0D; f31 0/1 (~90 %).

## WSA1R exercises the KN5000's undecidable residue (MEASURED — the payoff)

`dsp/analysis/STRATEGIC-REVIEW-2026-07-31.md` says the only route to the six SRC
hapaxes / kernel-only classes 8/9/C/D / bit-11 drought is a foreign corpus of
the same chip. WSA1R is that corpus and promotes several single-shot forms to
real populations:

| form | KN5000 | WSA1R |
|---|---:|---:|
| SRC 0x03 / 0x05 / 0x06 | 1 (hapax) each | **6** each |
| SRC 0x1B | 2 | **24** |
| class4 9 | 6 | **72** |
| class4 8 | 44 | **114** |
| class4 C / D | 1 / 1 | **12 / 6** |
| class4 B | **0 (never)** | **8** |
| C-FORMAT (hi12[11:8]==C) | 68 | **444** |
| hi12 bit-11 | 438 | **1,333** |

Not helped: SRC 0x0A (1→0), 0x0D (1→1); f31=4/5 are **not** enriched (48→27,
60→29). **441 of 918** distinct WSA1R encodings never occur in KN5000; **338 of
those are still-dark novel words.**

## Conclusion (graded)

- **STRONG — confirms the ISA.** Two firmwares from two products cross-validate
  one model: same 5-byte / 36-bit top-nibble-zero container, same
  `hi12.class4.addr8.lo12` layout, same dominant field values, near-identical
  decode rate crushing every null. (A format/ISA identity, matching the
  p7-effects finding's scope — not a claim the silicon is identical.)
- **STRONG — extends the reach.** WSA1R gives real sample sizes to KN5000
  hapax/absent forms (SRC 0x03/0x05/0x06/0x1B; class4 8/9/B/C/D; C-FORMAT),
  removing the "un-analysable hapax" blocker.
- **UNKNOWN — it does not decode them.** A richer corpus supplies occurrences,
  not the consumer that gives a code meaning; decoding still needs a WSA1R DSP
  instrument or the consumer-lag/harness methods used for the anchored KN5000
  codes — now feasible because the occurrences exist. f31=4/5 gains nothing here.
- **INFERRED.** That the 338 dark WSA1R-only encodings are instructions (not
  misframed data) rests on the pool framing (`gen_prom_c_p7stream_pool.py
  --verify`) plus the corpus-wide top-nibble-zero invariant (5,777/5,777).

## Next steps this unblocks

1. Re-run the KN5000 consumer-lag / minimal-pair harnesses on the WSA1R
   occurrences of the newly-populated codes (SRC 0x03/0x05/0x06/0x1B, class4
   8/9/B/C/D, C-FORMAT) to try to *decode* them, not just observe them.
2. A WSA1R DSP MAME device could reuse the existing `upd6383` core against this
   corpus — the cheapest new sound device in either project, per the DSP survey.

*(Committed alongside the reproducer; the script docstring and the archived log
carry the in-tree numbers.)*
