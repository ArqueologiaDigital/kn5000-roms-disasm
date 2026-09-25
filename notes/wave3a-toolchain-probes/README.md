# Wave 3a toolchain-lane probes (2026-09-25)

Evidence behind TOOLCHAIN_VERSION UPDATE 17: the semantic bugs of the TLCS-900
backend -- byte-exact code whose TEXT said something false -- and the source
respells that followed each fix.  Run from the tree root.

| script | the question it answers | command |
|---|---|---|
| `two_decoder_sweep.py` | For every addressing prefix x every sub-opcode (and the primary map), where does this backend's disassembler print a DIFFERENT operation or a DIFFERENT register than MAME's unidasm reads from the same bytes?  Classes: AGREE, REG_DIFF, MNEM_DIFF, LEN_DIFF, LLVM_ONLY (unidasm says `db`), MAME_ONLY (llvm refuses), plus ASYM (llvm's text does not re-encode). | `python3 notes/wave3a-toolchain-probes/two_decoder_sweep.py [--out DIR] [--limit N]`; `--selftest` exercises the verdict rule on synthetic text; `MC=` / `OBJDUMP=` pick a build |
| `update_disasm_test_expectations.py` | When a decoder change alters what an llvm-project lit test expects the disassembler to print, which expectations moved, to what, and does unidasm agree?  It rewrites a line ONLY on two-decoder AGREE. | `python3 notes/wave3a-toolchain-probes/update_disasm_test_expectations.py [--apply] <llvm test file>...` |

The source respells themselves are `scripts/converters/wave3a_respell.py`
(families `muldiv`, `autoinc`, `disp256`; every site is assembled old-line-by-
old-binary and new-line-by-new-binary and must match before anything is written)
and, for the direct-address pseudo mnemonics, the existing
`scripts/converters/convert_direct_address_family.py --only-misnamed`.

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
