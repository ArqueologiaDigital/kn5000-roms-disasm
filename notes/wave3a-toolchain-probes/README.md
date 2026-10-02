# Wave 3a toolchain-lane probes (2026-09-25)

Evidence behind TOOLCHAIN_VERSION UPDATE 17: the semantic bugs of the TLCS-900
backend -- byte-exact code whose TEXT said something false -- and the source
respells that followed each fix.  Run from the tree root.

| script | the question it answers | command |
|---|---|---|
| `two_decoder_sweep.py` | For every addressing prefix x every sub-opcode (and the primary map), where does this backend's disassembler print a DIFFERENT operation or a DIFFERENT register than MAME's unidasm reads from the same bytes?  Classes: AGREE, REG_DIFF, MNEM_DIFF, LEN_DIFF, LLVM_ONLY (unidasm says `db`), MAME_ONLY (llvm refuses), plus ASYM (llvm's text does not re-encode). | `python3 notes/wave3a-toolchain-probes/two_decoder_sweep.py [--out DIR] [--limit N]`; `--selftest` exercises the verdict rule on synthetic text; `MC=` / `OBJDUMP=` pick a build |
| `update_disasm_test_expectations.py` | When a decoder change alters what an llvm-project lit test expects the disassembler to print, which expectations moved, to what, and does unidasm agree?  It rewrites a line ONLY on two-decoder AGREE. | `python3 notes/wave3a-toolchain-probes/update_disasm_test_expectations.py [--apply] <llvm test file>...` |

The source respells themselves are `scripts/converters/wave3a_respell.py`
(families `muldiv`, `autoinc`, `disp256`, `erp`; every site is assembled old-line-by-
old-binary and new-line-by-new-binary and must match before anything is written)
and, for the direct-address pseudo mnemonics, the existing
`scripts/converters/convert_direct_address_family.py --only-misnamed`, and
for `.byte` post-increment instructions `scripts/converters/wave3a_byte_autoinc.py`.

## What the signal means

* The sweep's probes are SYNTHETIC (prefix + sub-opcode + `34 12 78 56`, padded
  with NOPs to a 16-byte slot so a mis-length decode cannot desynchronise the
  next probe).  It measures the DECODER, not the ROMs: a REG_DIFF row is "this
  byte pattern prints the wrong register", whether or not firmware uses it.
* Registers are compared as a multiset of NAMES; a register written as a raw
  number (the pseudo forms' `224` for XWA) counts as a difference on purpose.
* MAME prints an invalid byte-multiply pair as `??` and the backend now refuses
  those bytes; that shows as MAME_ONLY, not as a defect.

## out/

| file | what it is |
|---|---|
| `two_decoder_sweep_disagreements_<llvm commit>.tsv` | every non-AGREE, non-refusal probe (plus ASYM) at that build; the first line carries the class counts.  `da00420dba8d` is the pin before UPDATE 17 (llvm-mc a7ee33d5, llvm-objdump 65b8d2e4), `910b50efab49` and `8e188b215251` are two stages of it. |
| `gate_null_<commit>.txt` | summary of the NULL RUN at that build: the unconverted tree under the new assembler, expected 13/13 byte-identical; the assembler invocations show every image was rebuilt by the binary under test. |
| `gate_muldiv_respell_8e188b215251.txt`, `gate_muldiv_foil_8e188b215251.txt` | the MUL/DIV lockstep respell gated green, and its foil: one converted line reverted to the old spelling assembles silently and the gate reports `2 BYTES DIFFER`. |
| `gate_di_respell_da00420dba8d.txt` | the 13 reintroduced `di` lines respelled `ei 0`, gated with the PINNED binary before the `di` fix landed. |
| `respell_muldiv_8e188b215251.txt` | the respell tool's report (sites, refusals, verification). |
| `test_expectations_910b50efab49.txt` | every lit expectation the direct-address decode change moved, with MAME's reading beside it (83/83 AGREE). |
| `gate_<family>_respell_<commit>.txt`, `gate_<family>_foil_<commit>.txt` | each source respell (autoinc, stidsp, disp256, direct_misnamed, byte_autoinc, erp) gated green, and its foil: one converted line changed back or to the other spelling, and the gate going red. |
| `respell_<family>_<commit>.txt` | the respell tool's report per family: sites, refusals with reasons, old-vs-new verification counts. |
| `byte_autoinc_decisions_8e188b215251.txt` | every `.byte` line that starts with a post-increment prefix, CONVERT or keep, with the reason. |
| `gate_L6a_*_wip.txt`, `gate_L6b_*_wip.txt` | the converted tree gated under each phase-B backend change BEFORE it was committed (256 as a real displacement; the lying pseudos deleted). |
| `gate_final_4867e03232a6.txt` | the final pin (llvm-mc c949d618, built from scratch twice) on the final tree: 13/13. |
| `two_decoder_sweep_disagreements_4867e03232a6.tsv` | the sweep at the final pin: what is still false or unspellable (TOOLCHAIN_VERSION UPDATE 17 lists the classes). |

### T1 fix round (2026-10-02, TOOLCHAIN_VERSION UPDATE 18; tools in `fixround/`)

| file | what it is |
|---|---|
| `respell_fixround_4867e03232a6.txt` | `wave3a_respell.py` djnz16 / inc8 / muldiv2 in report mode on the tree BEFORE the respell (cdce5139), old = new = the T1 pin: 304 / 1,700 / 21 sites, all byte-identical. |
| `erratum_09b760eb_trailer.txt` | the 09b760eb tree gated with the binary its trailer names (fails) and with the one its TOOLCHAIN_VERSION names (13/13). |
| `erratum_sweep_baseline_da00420dba8d.txt` | the sweep's da00420dba8d baseline under the committed classifier (REG 1,263 / MNEM 304) and under 09b760eb's (1,247 / 320). |
| `v1a_sweep_counts_d7752a16b6ee.txt` | `fixround/v1a_sweep.py` class counts per family, T1 pin beside fix-round pin: every ASYM to 0. |
| `two_decoder_sweep_disagreements_d7752a16b6ee.tsv`, `two_decoder_sweep_allfields_disagreements_d7752a16b6ee.tsv` | the sweep at the fix-round pin, register field 1 and `--all-reg-fields`. |
| `assembler_checks_d7752a16b6ee.txt` | asm_sweep counts (beside the T1 pin's), `lying_pseudo_check.py` (pass), the SP twin comparison (0 SP-only defects), the CLAUDE.md examples check (25/25). |
| `size_lies_baseline.txt`, `pseudo_ops_baseline.txt` | the baselines `fixround/lying_pseudo_check.py` compares against: empty, and 99 known false positives each tagged with why. |
| `gate_clean_final_d7752a16b6ee.txt` | the pin from nothing: 13/13, every image rebuilt by the binary, 286 C bins identical to the April clang's. |
| `gate_foil_d7752a16b6ee.txt` | two respelled lines put back: the build fails on each. |

