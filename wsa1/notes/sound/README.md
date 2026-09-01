# `wsa1/notes/sound/` — the SX-WSA1R sound-subsystem measurements

Each script answers one question and each has a `--selftest` of invariants.
Run them **from `wsa1/`**, not from the repository root.

| script | the question it answers | command |
|---|---|---|
| `wsa1_sound_boundary.py` | Which routines touch a sound device, which register of which device, how often, and is the window list complete? | `python3 notes/sound/wsa1_sound_boundary.py --windows --routines --p7` |
| `wsa1_unspellable_forms.py` | Which instruction FORMS does this tree still carry as `.byte`, what are their bytes, can the assembler spell them — and how many of those sites are inside a SOUND routine? | `python3 notes/sound/wsa1_unspellable_forms.py --sites` |
| `wsa1_sound_in_unconverted.py` | How much sound code is still inside an unconverted `.incbin` region? | `python3 notes/sound/wsa1_sound_in_unconverted.py` |
| `wsa1_dev104_vs_kn5000.py` | Is the WSA1's 0x104000 device the KN5000's tone generator? | `python3 notes/sound/wsa1_dev104_vs_kn5000.py` |
| `wsa1_dsp_driver_shared.py` | Are the WSA1's and the KN5000's DSP register-file drivers the same code? | `python3 notes/sound/wsa1_dsp_driver_shared.py` |

Selftests:

```
python3 notes/sound/wsa1_sound_boundary.py --selftest
python3 notes/sound/wsa1_unspellable_forms.py --selftest
```

## The converter these drive

It lives in `scripts/converters/` because it WRITES sources; the scripts here
only report.

| script | the question it answers | command |
|---|---|---|
| `../../scripts/converters/convert_certified_forms.py` | Can this `.byte` LINE, certified by the census, be spelt natively without moving a byte? | `python3 scripts/converters/convert_certified_forms.py` (dry run; `--apply` writes) |

⚠ **Do not point the sibling tree's
`../../../scripts/converters/convert_unspellable_forms.py` at this tree.** It
converts every `.byte` line whose bytes happen to decode, which is safe there
because every such line was already framed as one instruction by an earlier
round. It is not safe here: prom_a alone carries 5,143 `.byte` lines that are
data tables, three bytes of a font decode as readily as three bytes of code, and
the byte gate cannot tell the difference — the bytes would be identical either
way.

## Reading `wsa1_unspellable_forms.py`'s output

The headline is the last line: **sites with no spelling, and how many of them
are inside a sound routine.** The second number is the one the
sound-disassembly goal is about, and on 2026-09-01 it reached **0** in all three
code images. What remains is 286 sites / 1,268 bytes / 94 forms, all in prom_a.

⚠ **Those 286 are not 286 backend gaps.** A site is listed when neither spelling
route produced its bytes, and the per-form line says which failed and how:

| what the line says | what it means | who fixes it |
|---|---|---|
| `did not assemble` | the syntax is not what llvm-mc wants (`ex bc,qbc`, `srl a,c`) | mostly a translation job; sometimes a real gap |
| `assembles to <other bytes>` | llvm-mc has an encoding and picks a different one — the big class is the 16-bit-address memory operand, 26 sites of `or (0x2134),0x0002`, which `f29a4827693f` made writable as `or (0x2134:16), 0x0002` | a conversion job, not a backend one |
| `PC-relative, so its rendering cannot be typed verbatim` | 12 `jr` / `calr` / `djnz` sites that need a LABEL, not an address literal | a converter that resolves targets |

Three classes are rejected before being counted, each named with its count in
the report: bare-address comments (5,143 prom_a lines — data tables), bytes
unidasm itself renders `db` (24 — `80 0f` is an opcode the CPU does not have,
not one the assembler cannot write), and comments that copy that `db` marker
where a byte echo belongs (7 in prom_b).

## What makes these measurements rather than greps

* **The framing authority is the committed MAME unidasm listing**
  (`original_ROMs/*.unidasm`, see `original_ROMs/README-unidasm.md`), never the
  LLVM backend's own `--disassemble`.
* **The encoding authority is a round-trip through the assembler.** A form
  counts as spellable only when llvm-mc reproduces the exact bytes it came from.
  "llvm-mc accepted it" has been wrong before, in both directions: this backend
  has been caught accepting `push (0x1234)` while truncating the address, and
  eight of the nine forms a previous lane called unspellable in this tree turned
  out to have a spelling nobody had tried.
* **A comment is not evidence.** In this tree every `.byte` comment begins with
  a letter, because addresses here start with `F`, so "the comment looks like a
  disassembly" matches every data table in the image.
* **The certificate is the byte gate**, `scripts/analysis/assert_byte_identical.py`.
  Nothing here certifies anything.
