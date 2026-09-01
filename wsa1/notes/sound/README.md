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
| `wsa1_dsp_join_probe.py` | prom_a 0xF85F0F and prom_c 0xF98000 are ONE source now — did the merge MOVE the text, or change it? And is the 231-of-234 byte identity real? | `python3 notes/sound/wsa1_dsp_join_probe.py --verify` |

Selftests:

```
python3 notes/sound/wsa1_sound_boundary.py --selftest
python3 notes/sound/wsa1_unspellable_forms.py --selftest
python3 notes/sound/wsa1_dsp_join_probe.py --selftest
```

## `wsa1_dsp_join_probe.py` — the DSP driver merge

Since 2026-09-01 the four DSP channel-register routines are **one source**,
`dsp/dsp_channel_regs.s`, assembled into prom_a at 0xF85F0F **and** prom_c at
0xF98000 — 234 bytes each, 231 of them the same byte, the three that differ
being A23..A16 of the base literal (`DSP_REGS_BASE`, named once in each
`dsp/dsp_channel_regs_*.inc`). The same arrangement `kernel/kernel.s` has.

| mode | the question it answers |
|---|---|
| (no flag) / `--rom` | 231 of 234, computed **from the two EPROM images alone** with a misalignment null — checkable without reading the disassembly at all |
| `--pairs` | the 97 instruction pairs at `BASE_REV`, the 12 house-style ADOPTIONS with the side kept and why, and the 3 per-CPU sites |
| `--verify` | ★ the preservation proof: every comment line, label, instruction and prose fragment of **both** pre-merge blocks, verbatim |
| `--images` | what each image's text gained, with the delta accounted for arithmetically; prom_b is the control |
| `--emit` | regenerate the merged source and the two `.inc` (the record of the merge, not a build step) |
| `--selftest` | invariants and two controls, including "`--verify` must REJECT a merged file with one comment deleted" |

⚠ The byte gate is still the only certificate: `python3
scripts/analysis/assert_byte_identical.py`. What makes the merge trustworthy is
that **one source rebuilds both images** — flip the subcpu equate to
`0x00E10000` and prom_c fails at exactly three bytes while prom_a stays green.

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

## `prom_d_debt_probe.py`

**Question:** of prom_d's 524,288 bytes, how many are accounted for by the
tone-database sources, by directive class — and is an unstructured dump
hiding inside what looks like per-record source?

    python3 wsa1/notes/sound/prom_d_debt_probe.py

Label density is the discriminating measure, not the byte total: a raw blob
spelled in `.byte` accounts for its bytes just as well as a real record table
does, but only the record table carries labels at record boundaries. Spans
longer than 512 bytes are reported as leads, not verdicts.
