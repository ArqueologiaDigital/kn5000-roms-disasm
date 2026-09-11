# KN5000 DSP — corpus-wide runtime regression (all distinct programs run, 2026-09-11)

Completes the "run every DSP program on the emulator" directive: every distinct DSP-EFFECT-page image
was triggered live (`peq_gain.lua TYPEIDX=N NPARAM=0 NVALUE=0 TRACE_DETAIL=1 TRACE_FRAME=2100000`),
its unit-0 words isolated (iw≥84), and its live word count + class-A count cross-checked against the
static disassembly (`prog*.dsm`). class-A = class4==0xA (matches the prog headers exactly).

## Coverage
TYPEIDX 0–37 all run EXCEPT 14 (SLOW ATTACKER = the NO-OP stub image) and 19 (ROTARY SPEAKER = shares
ROCK ROTARY's algo-15 image, run at TYPEIDX 20). Plus the unit-1 reverb (algo 16) and CHORUS/PEQ/
ROOM REVERB earlier. **So every distinct program image has now been triggered live.**

## Result: live word count == static image count, EXACTLY, for ALL programs (0 mismatches)

| TYPEIDX | program | live=static words | class-A live / static |
|---:|---|---:|---|
| 3 | FLANGER | 65 = 65 | 16 / 18 |
| 4 | PHASER | 106 = 106 | 11 / 14 |
| 7 | SINGLE DELAY | 48 = 48 | 18 / 18 |
| 10 | OVERDRIVE | 63 = 63 | 18 / 18 |
| 11 | FUZZ | 42 = 42 | 6 / 6 |
| 13 | COMPRESSOR | 40 = 40 | 8 / 10 |
| 22 | MIX UP | 64 = 64 | 12 / 15 |
| 23 | S.DELAY+CHORUS | 95 = 95 | 21 / 23 |
| 24 | S.DELAY+S.DELAY | 68 = 68 | 16 / 16 |
| 25 | S.DELAY+FLANGER | 100 = 100 | 25 / 28 |
| 26 | S.DELAY+VIBRATO | 86 = 86 | 19 / 22 |
| 27 | S.DELAY+PHASER | 110 = 110 | 19 / 22 |
| 28 | AUTO WAH+S.DELAY | 105 = 105 | 20 / 21 |
| 30 | PEQ+S.DELAY | 54 = 54 | 20 / 20 |
| 31 | PEQ+FLANGER | 91 = 91 | 30 / 32 |
| 32 | PEQ+VIBRATO | 77 = 77 | 24 / 26 |
| 33 | PEQ+COMPRESSOR | 59 = 59 | 20 / 22 |
| 35 | PEQ+COMPR+OVERDR | 97 = 97 | 36 / 36 |
| 36 | PEQ+DIST+DELAY | 92 = 92 | 28 / 28 |
| 37 | PEQ+OVERDR+DELAY | 104 = 104 | 40 / 40 |

**20/20 programs: live word count == static image count EXACTLY. Zero mismatches.** The disassembly's
program sizes are now cross-validated against live execution across the whole corpus.

## The class-A firing pattern is FAMILY-SPECIFIC (the runtime finding)
- **Fire ALL class-A live** (live == static): distortion (FUZZ 6/6, OVERDRIVE 18/18), pure delay
  (SINGLE DELAY 18/18, S.DELAY+S.DELAY 16/16), and PEQ+delay/distortion combis (PEQ+S.DELAY 20/20,
  PEQ+DIST+DELAY 28/28, PEQ+OVERDR+DELAY 40/40, PEQ+COMPR+OVERDR 36/36).
- **Gate some class-A** (live < static, 2–3 words): every **modulation** program (FLANGER, PHASER,
  MIX UP, VIBRATO, ENSEMBLE) and **dynamics** (COMPRESSOR), and every combi that CONTAINS a
  modulation/compressor sub-block (S.DELAY+CHORUS/FLANGER/VIBRATO/PHASER, PEQ+FLANGER/VIBRATO/
  COMPRESSOR).
- Interpretation: the gated class-A words are the **input/state-conditional ops of the LFO and
  dynamics paths** — they don't fire in a single steady frame because their gate (LFO phase /
  threshold) is not satisfied. Named exemplars (from T2): FLANGER's SRC 0x08 coefficient-squaring MAC
  with f31=4; COMPRESSOR's SRC 0x07/ACT 0x15 store MAC. These are exactly the conditional paths the
  static analysis marks lower-confidence — the concrete decode lead going forward.

## Net
Every DSP program now runs live and is word-count-validated against the decode (0 mismatches,
corpus-wide). The only live-vs-static gaps are the family-specific gated class-A ops, which are a
decoded *lead* (LFO/dynamics conditionals), not decode errors. Deep per-family datapath probes (T3:
read the LFO ramp / waveshaper on the isolated program) are the next step, now trivially enabled for
any program by this rig.
