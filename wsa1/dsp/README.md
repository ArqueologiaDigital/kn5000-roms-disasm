# SX-WSA1R effects-DSP disassembly

The Technics SX-WSA1R carries **three** NEC uPD6383GF effect DSPs (IC5, IC6, IC30) —
the **same chip** as the KN5000's IC311, so the same reverse-engineered instruction-set
model (`dsp/tools/dsp_disasm.py`) disassembles both. This directory is the WSA1R
counterpart of the KN5000 `dsp/` deliverable: every effect's DSP microcode, listed and
commented.

## What is here

- **`disasm/eff*.dsm`** — one listing per distinct effect program (48 of them). Each word
  is rendered by the shared ISA model: mnemonic + `hi12.class.addr8.lo12` field breakdown
  + the decoded/**SPECULATIVE** reading + C-RAM coefficient-cursor addresses. A reading
  marked `SPECULATIVE` is a *graded prospective hypothesis*, not measured.
- **`disasm/index.dsm`** — the program index with per-effect word/decode counts.
- **`programs.tsv`** — the machine-readable manifest (record, name, slots, words, class-A
  multiplies, strict/speculative decode counts, family, whether the name is shared with a
  KN5000 program).
- **`analysis/`** — the tools (`gen_wsa1_dsp_disasm.py` regenerates everything here; the
  de-framers, the record/field resolvers, the runtime-vs-corpus cross-checks).

## Where each program comes from (all MEASURED)

The WSA1R serialises its DSP microcode as a relocatable byte-stream **pool** in prom_c
(`0xFCD0F7-0xFDD2AA`). An **effect** is a PROGRAM number 0..127 selected on the panel:

```
  program 0..127  --PoolDir_RecordForUnitProgram (0xFDC551)-->  record 0..55
  record          --PoolDir_Records (0xFDBFD9, 25-byte stride), field +12 -->  I-RAM body
```

**Field +12 is the opcode-3 I-RAM program body** (op3 for 48 of 56 records;
`analysis/dsp_record_field_opcodes.py`). Fields +0/+4/+8 are the effect's **coefficient**
streams (they load C-RAM, not I-RAM). Effect **names** are prom_b `EffectNames_F147AC`
(0xF147AC, 128 × 16 ASCII; 56 real, 72 `----------` placeholders that all resolve to
record 53 = `NO OPERATION`).

⚠ **8 records have no distinct op3 body** (CHORUS, MODULATED CHORUS, AUTO PAN, AUTO WAH,
COMPRESSOR, BRIGHT REVERB 1/2, AUTO WAH+S.DELAY): their field +12 points to a non-op3
stream, so they are coefficient-only variants on a shared body — listed in the index, no
`.dsm`.

## Regenerate / drift-check

```
  python3 analysis/gen_wsa1_dsp_disasm.py            # rewrite disasm/ + programs.tsv
  python3 analysis/gen_wsa1_dsp_disasm.py --table    # just the manifest table
  git diff --exit-code disasm programs.tsv           # doubles as a drift check
```

Derived ROM bytes are never written to the repo — only the annotated listings + manifest,
matching the KN5000 tree's policy.

## Cross-product note (topology)

Many WSA1R effects share a name **and** an algorithm family with a KN5000 program (CHORUS,
FLANGER, PHASER, the reverbs, the delays, PARAMETRIC EQ, the distortions, EXCITER,
COMPRESSOR, ENHANCER, ENSEMBLE). Each shared listing carries the KN5000 role as a
cross-reference, and the word/class-A counts let the two be compared directly. The clearest
match is **PARAMETRIC EQ** — the highest-decode program on both chips (WSA1R 110/120 words
strict-decoded), a Direct-Form-I bilinear biquad chain — which is why it is the ISA
reference on both products. See `analysis/wsa1_dsp_isa_crossval.py` for the statistical
cross-validation of the whole ISA between the two.
