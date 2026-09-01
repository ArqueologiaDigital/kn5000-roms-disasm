# `notes/sound/` — the KN5000 sound-subsystem measurements

Every number in `FINDINGS-kn5000-sound-coverage-2026-09-01.md` comes from one of the
scripts below. Each answers one question and each has a `--selftest` of invariants.
Run them from the repository root.

| script | the question it answers | command |
|---|---|---|
| `kn5000_sound_boundary.py` | Which routines touch a sound chip, where do the chip boundaries lie, and does any of that code's control flow leave disassembled text? | `python3 notes/sound/kn5000_sound_boundary.py --calibrate --windows --tgregs --misframes --coverage --unspellable` |
| `kn5000_unspellable_forms.py` | Which instruction FORMS does the tree still carry as `.byte`, what are their bytes, and can the assembler spell them at all? | `python3 notes/sound/kn5000_unspellable_forms.py --sites` |
| `sound_coverage.py` | (superseded — the first, territorial census; see §1 of the findings for why its conclusion did not follow) | `python3 notes/sound/sound_coverage.py` |

Selftests:

```
python3 notes/sound/kn5000_sound_boundary.py --selftest      # 11 invariants
python3 notes/sound/kn5000_unspellable_forms.py --selftest   # the work list is the test
```

## The two converters these drive

They live in `scripts/converters/` because they WRITE sources; the scripts here only report.

| script | the question it answers | command |
|---|---|---|
| `convert_sound_byte_blocks.py` | Can this `.byte` RUN, which converted code branches into, be reframed as instructions without moving a byte? | `python3 scripts/converters/convert_sound_byte_blocks.py --list` then `... LABEL [LABEL ...]` |
| `convert_unspellable_forms.py` | Can this single `.byte` LINE, already framed as one instruction by unidasm, be spelt natively? | `python3 scripts/converters/convert_unspellable_forms.py --dry-run` |

## What makes these measurements rather than greps

* **The framing authority is the committed MAME unidasm listing**
  (`original_ROMs/*.unidasm`), never the LLVM backend's own `--disassemble`, which
  refuses most extended forms and mis-decodes some of the rest.
* **The encoding authority is a round-trip through the assembler.** A form counts as
  spellable only when llvm-mc reproduces the exact bytes it came from. "llvm-mc accepted
  it" has been wrong before.
* **A comment is not evidence.** A data table's per-row annotation looks exactly like a
  disassembly comment; `--unspellable` once counted 562 bytes of the boot ROM's velocity
  curves as unspelt instructions on that basis.

## To reproduce a historical figure

These walk the tree as it stands, so check the tree out first:

```
git checkout <commit> -- v142/subcpu subcpu/boot
python3 notes/sound/kn5000_unspellable_forms.py
git checkout HEAD -- v142/subcpu subcpu/boot
```

At `59805bee` that prints the findings' 211 sites / 833 bytes / 59 forms.
