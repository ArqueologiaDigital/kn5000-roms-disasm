# The SPECULATIVE decode tier — prospective SRC/ACT readings, adopted

**Date 2026-09-06.** Goal: *"improve DSP decoding by temporarily accepting less
rigorously some prospective hypotheses so that things fit in place."* This is that
adoption. It is kept **entirely separate** from the rigorous baseline — the strict
`alu_decoded()` and `lo_*_anchored()` are untouched — so nothing here contaminates
a MEASURED grade and the whole tier is reversible by deleting the `*_spec` members.

Reproducer: `dsp/tools/spec_coverage.py` (self-test `3057` / `1178` PASS).

## What is accepted, and on what basis (all PROSPECTIVE, none MEASURED)

| code | prospective reading | basis | grade |
|---|---|---|---|
| SRC 0x00 | mem[ptr] / delay-RAM read | §233: SINGLE DELAY separated the 7 readings 1-of-7, this survived, null-MAC rival refuted | STRONG |
| ACT 0x0D + 0x0E | the biquad's two delay-stage actions (a pair) | §234: the pair confirmed 1-of-49 by PARAMETRIC EQ's entry window; only which-tap / lag is hardware Q4 | STRONG |
| SRC 0x0B | delay-read data register | §215: its consumer follows a delay READ 13/13 | med |
| SRC 0x11 | ACCB, the second accumulator | §27; adjacent to SRC 0x10, and the CDJ-500 block diagram gives this ALU two accumulators | med |
| SRC 0x13 | coef/wave table port | `CORPUS-PATTERNS-SPECULATIVE.md` S-6: `102.A.**.4C8` is the table-port multiply | med |
| SRC 0x08 | LFO / per-unit modulation source | class-A + ACT 0x00 in the LFO-publish idiom | weak |
| ACT 0x0C | delay READ | 12/12 sites are immediately followed by a delay read | med |
| ACT 0x08 | table-port multiply (pairs with SRC 0x13) | no named reading; adopted for the pairing | weak |
| class 1/9 | register-file addressing modes | rendered `internal register file [XX]` (R2 §1) | med |
| class 4/6 | the table-lookup idiom | rendered `table-lookup idiom` (INFERRED, MCC +1.000) | med |

⚠ Each of these was, under the rigorous gate, *refused* — the corpus supplies
occurrences but no discriminating consumer (`xcorpus-routing.md`). The speculative
tier accepts the most plausible reading anyway, clearly labelled, so the decode
fits together; it is not a claim any of them is proven.

## How much fits in place (MEASURED coverage of the relaxed predicate)

`spec_coverage.py`, over the 3057-word corpus:

```
STRICT      (alu_decoded):        1178 / 3057 =  38.53%  <- rigorous baseline, unchanged
SPECULATIVE (alu_decoded_spec):   2674 / 3057 =  87.47%  <- ALU ops, prospective readings
UNIFIED (has any meaning:         3057 / 3057 = 100.00%  <- + C-format + nop/ldptr/setvec
   spec ALU + C-format + idioms)                            + structural annotations
  ⇒ TRULY DARK (no annotation):      0 / 3057 =   0.00%  <- every word has a graded reading
```

⚠ **READ "100%" PRECISELY.** It means *no word is a complete mystery* — every one
of the 3057 corpus words now carries at least a graded reading: a MEASURED decode
(38.53%), a SPECULATIVE ALU decode (to 87.47%), a C-format immediate, a
nop/ldptr/setvec, or an established STRUCTURAL ROLE.  It does **not** mean 100%
proven: several words carry an honest "operation OPEN" (structural role known,
exact op not) — e.g. the last word resolved, `A3C.D.9F.287` (I-RAM 78, the only
class-D word), whose role is "output stage, unit 1 → DO2 → IC303.SDIB, a DO-write
candidate" but whose f31=6 operation is labelled OPEN, not invented.  The rule
held throughout: **structure/role may be adopted prospectively and labelled; an
operation that is genuinely unknown is written "OPEN", never fabricated.**

Tranche 4/5 detail: SRC 0x1C = LFO output (unproven), the S-5 template head, the
lo12 bit-11 modifier family, class-A multiply / class-2 MAC partial reads (the
multiply/MAC is what the class means; f31 combine / operands may be open), and a
known-f31 floor.  Everything remains graded SPECULATIVE and reversible.

```
```

The UNIFIED figure is above the strategic review's ~93.3% "has-a-meaning"
ceiling — because the speculative tier accepts the prospective readings the
strict method refused.  Tranche 3 (2026-09-06) added ACT 0x0B (delay access) and
relaxed the store / HI_ACC_HOLD guards in the speculative predicate (the store
OPERATION is known; only its mode-dependent target is open, which is a detail for
a decode metric and cannot cause a dead store since this predicate never
executes) → 68.50% → 85.97%.

Biggest contributions: SRC 0x00 = mem[ptr] (§233) and the ACT 0x0D/0x0E biquad
pair (§234) together carry the bulk; the register-file (class 1/9) and
table-lookup (class 4/6) addressing modes and the SRC 0x0B/0x11/0x13 routing
codes make up the rest. The device's execution gate remains the strict
`alu_decoded()`; this tier is the disassembler/measurement view only.

Adopted in tranches (2026-09-06): (1) SRC 0x0B/0x11/0x13 + ACT 0x0C/0x08 +
class 1/9 → 45.86%; (2) SRC 0x00 + ACT 0x0D/0x0E + SRC 0x08 + class 4/6 → 68.50%.

## Implemented into the core

- `kn7000_mame/src/devices/cpu/upd6383/upd6383d.h`: the prospective constants
  (`LO_SRC_DRD`/`LO_SRC_TABLE`/`LO_ACT_DELAY_RD`/`LO_ACT_TBL_MUL`; ACCB existed),
  `lo_src_anchored_spec()` / `lo_act_anchored_spec()`, and `alu_decoded_spec()` —
  a mirror of `alu_decoded()` that anchors the prospective codes. The strict
  predicate is untouched; the device's execution gate is still `alu_decoded()`.
- `upd6383d.cpp` and `dsp_disasm.py`: the disassembler now renders each
  prospective code with its reading, prefixed `SPECULATIVE (prospective, not
  measured)`, so a speculative-tier word is legible and never mistaken for a
  measured decode.

## To retract

Delete the `*_spec` members and the SPECULATIVE render block; the strict baseline
is exactly as before. Any of these five that later earns a discriminating context
(the WSA1R DSP device, `HANDOFF-wsa1-dsp-device-build.md`) graduates from here to
`alu_decoded()` with its own evidence — or is refuted and removed.
