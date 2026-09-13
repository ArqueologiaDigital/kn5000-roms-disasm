# PRE-REGISTRATION — the VOLUME cell as a criterion for the store gate

Written **before** reading the ten-program `GATECLR` captures (they are still being taken as this
is committed; only the CHORUS pair has been seen, and it is what suggested the test).

## The known answer, and it comes from the firmware rather than from the emulator
`register-space.md` item A1, **PROVEN BY CONSTRUCTION**: every effect's parameter bytecode ends
with a record whose opcode is `0x63`, whose T1 address is `0x06` (37 unit-0 algorithms) or `0x86`
(12 unit-1 reverbs), and whose evaluator is a dB curve-table lookup — binding opcode `0x63` to the
name **VOLUME in 49 of 49** algorithms. The host writes that cell **once**, after linking
(`EFF_VolumeLoop`), and `dsp_disasm.py` already records the consequence of anything else writing
it: the user's depth would survive *"exactly ONE frame"*.

⇒ **a correct machine writes `0x06`/`0x86` once per program load and never from the microcode.**
That is a criterion the ROM and the firmware supply jointly, and no DSP decode has ever been graded
on it.

## What the shipped reading does, on the one program already seen
```
   chorus, arm OFF :  06 (8388607, 0..8388607, chg 1389)      ← RAILED and rewritten
   chorus, GATECLR :  06 (2260027, 0..2260027, chg    1)      ← written once, ~0.27 FS
```

## Predictions, over the ten-program catalogue at the TRUE DEVICE DEFAULT

| | prediction |
|---|---|
| **V1** ★ | with `GATECLR` on, `0x06` has `chg ≤ 2` in **at least 9 of 10** programs |
| **V2** | with `GATECLR` on, `0x06` is **not railed** in any of the 10 |
| **V3** | CONTROL THAT CAN FAIL: with the arm OFF, at least **3** of the 10 must show `0x06` railed or `chg > 100`. If the shipped machine already writes it once everywhere, the instrument is blind and V1/V2 mean nothing |
| **V4** | the hand-off regression (`src0b2_regression.py`) must report **0 BROKEN** |
| **V5** | ⚠ `0x86` is the UNIT-1 cell and only the 12 reverbs use it; it is reported but **not graded**, because the sample contains one reverb |

## What a pass would and would not settle
★ A pass would be the first time the store gate has been graded against a criterion the FIRMWARE
supplies, on a cell whose role is proven by construction rather than inferred — and it would say
the gate's clear is taken BEFORE the ALU.

⛔ It would still not distinguish `-` from `ST(acc→else)` (unreadable by construction), nor settle
`LD`, and it would not move the coverage number: `alu_decoded()` refuses these words because the
MEMORY ACCESS is three-way open, which the clear does not touch.

⚠ And the LFO criterion this replaces MISSED — see `PREDICT_GATECLR_2026-09-13.md`. This one is
offered as the better-posed successor, not as a second bite at the same claim; it is graded on a
different quantity, with its own control that can fail.
