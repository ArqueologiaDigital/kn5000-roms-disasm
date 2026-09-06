# The SPECULATIVE decode tier — prospective SRC/ACT readings, adopted

**Date 2026-09-06.** Goal: *"improve DSP decoding by temporarily accepting less
rigorously some prospective hypotheses so that things fit in place."* This is that
adoption. It is kept **entirely separate** from the rigorous baseline — the strict
`alu_decoded()` and `lo_*_anchored()` are untouched — so nothing here contaminates
a MEASURED grade and the whole tier is reversible by deleting the `*_spec` members.

Reproducer: `dsp/tools/spec_coverage.py` (self-test `3057` / `1178` PASS).

## What is accepted, and on what basis (all PROSPECTIVE, none MEASURED)

| code | prospective reading | basis |
|---|---|---|
| SRC 0x0B | delay-read data register | LEDGER §215: its consumer follows a delay READ 13/13 |
| SRC 0x11 | ACCB, the second accumulator | §27; adjacent to SRC 0x10, and the CDJ-500 block diagram gives this ALU two accumulators |
| SRC 0x13 | coef/wave table port | `CORPUS-PATTERNS-SPECULATIVE.md` S-6: `102.A.**.4C8` is the table-port multiply |
| ACT 0x0C | delay READ | 12/12 sites are immediately followed by a delay read |
| ACT 0x08 | table-port multiply (pairs with SRC 0x13) | weakest of the five; no named reading, adopted for the pairing |

⚠ Each of these was, under the rigorous gate, *refused* — the corpus supplies
occurrences but no discriminating consumer (`xcorpus-routing.md`). The speculative
tier accepts the most plausible reading anyway, clearly labelled, so the decode
fits together; it is not a claim any of them is proven.

## How much fits in place (MEASURED coverage of the relaxed predicate)

`spec_coverage.py`, over the 3057-word corpus:

```
STRICT      (alu_decoded):        1178 / 3057 = 38.53%   <- rigorous baseline, unchanged
SPECULATIVE (alu_decoded_spec):   1297 / 3057 = 42.43%
  ⇒ prospective readings fit:     +119 words (+3.89 pts)
```

Isolated per-code contribution (on top of strict):

```
SRC 0x11 ACCB           +49      <- the single largest OPEN routing code
ACT 0x08 table mul       +9
SRC 0x0B delay-read reg  +7
SRC 0x13 table port      +0      } decode only TOGETHER (the table-port pair),
ACT 0x0C delay READ      +0      } which is why the combined +119 > sum of isolated
```

(At the routing gate alone — before the class/bit-4/f31 guards — the same codes
route-anchor +224 words, 45.18% → 52.50%; the +119 is the honest full-predicate
number after the other guards refuse some of those.)

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
