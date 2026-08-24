# The three tools in `prom_a/`

They live in `prom_a/` rather than `scripts/analysis/` only because this pass was
scoped to `prom_a/` and `notes/`; `scripts/analysis/` belongs to another lane.
Whoever owns that directory next should move them and fold their entries into
`scripts/analysis/README.md`.

Each answers one question, and each says so in its own docstring too.

## `prom_a/roundtrip.py`

**"What source text, fed to `llvm-mc -triple=tlcs900`, assembles back to exactly
the bytes at 0xF8xxxx..0xF8yyyy?"**

```
python3 prom_a/roundtrip.py 0xF82CFF 0xF82E05           # per-instruction
python3 prom_a/roundtrip.py 0xF82CFF 0xF82E05 --stats   # + strategy counts
python3 prom_a/roundtrip.py 0xF82CFF 0xF82E05 --survey  # only what failed
python3 prom_a/roundtrip.py 0xF82CFF 0xF82E05 --block   # labelled, whole-block
                                                        # verified -- paste this
```

unidasm supplies the instruction boundaries and is the decode authority; four
candidate spellings are tried per instruction (unidasm's own text, llvm-mc's
disassembler text, a macro from the prelude in `prom_a/wsa1_prom_a.s`, and
`.byte`), and **every candidate is assembled and byte-compared before it is
printed**. `--block` additionally turns in-range branch targets into labels and
re-assembles the whole region to prove the labelled form still produces the
original bytes; it prints a loud refusal if it does not.

So nothing it emits can break the gate. It says nothing about what the code
*means* — names and headers are written by hand afterwards.

Typical outcome on real code: ~85% of instructions take unidasm's or llvm-mc's
own spelling, ~13% need a prelude macro, and 0-2% stay `.byte` with unidasm's
text in a trailing comment.

## `prom_a/insert_region.py`

**"I have assembly for 0xF8xxxx..0xF8yyyy — what do the surrounding `.incbin`
lines have to become so the image is still complete?"**

```
python3 prom_a/insert_region.py 0xF82CFF 0xF82EA2 region.s
```

The source is one 512 KiB image described by a chain of `.incbin` lines
interleaved with converted assembly. Getting that arithmetic wrong is the easiest
way to break the byte gate, so it is done here rather than by hand. Run the gate
afterwards; this script does not.

## `prom_a/kn5000_run_offsets.py`

**"Does a KN5000 payload file offset equal its sub-CPU address minus 0x400?"**
(No. It is `+0xEF00` above the first 256 bytes.)

```
python3 prom_a/kn5000_run_offsets.py              # the check; exits non-zero on failure
python3 prom_a/kn5000_run_offsets.py --proposals  # the corrected transplant table
```

Full argument, and what it invalidates, in
`notes/FINDINGS-kn5000-transplant-offset.md`.

## The macro prelude

Not a script, but the same kind of artefact: the block between
`; MACRO-PRELUDE-BEGIN` and `; MACRO-PRELUDE-END` in `prom_a/wsa1_prom_a.s`
defines the TLCS-900 memory-operand and LDC forms that llvm-mc's tlcs900 backend
has no encoding for. Every operation byte it emits is cited to the MAME
disassembler table it came from (`../mame/src/devices/cpu/tlcs900/dasm900.cpp`),
and `roundtrip.py` reads the prelude out of the ROM source itself, so the tool
and the image can never disagree about what a macro expands to.

⚠ The macros are byte emitters. The gate proves they emit the right bytes; it
cannot prove the NAME on a macro is the right mnemonic. That comes from the cited
tables, and every use in the ROM source carries unidasm's own text in a trailing
comment so the two can be compared by eye.

## Cross-reference: two of the prom_b lane's "cannot encode" cases are covered

`notes/llvm-mc-tlcs900-spellings.md` lists five shapes that `llvm-mc` cannot
encode and that the prom_b lane therefore emits as `.byte`. The macro prelude
handles two of them:

| bytes | MAME | with the prelude |
|---|---|---|
| `85 3F 07` | `cp (XIY),0x07` | `m_cp_mi8 MBI+r5, 0, 0x07` |
| `85 27` | `ld L,(XIY)` | `m_ld_rm MBI+r5, 0, r7` |

(checked with `prom_a/roundtrip.py`'s own assembler path; both produce exactly
those bytes). The other three — the register-indexed `(rr+r)` operand and the
shift-by-a-register forms — are still `.byte` here too; they need a second macro
family keyed on the register-address bytes, which nobody has written yet.

The prelude is not tied to prom_a: it is a block of `.macro`/`.equ` in
`prom_a/wsa1_prom_a.s` and could be lifted into `include/` for all four images.
It was not put there in this pass because `include/tmp95c061_sfr.inc` is shared
and another lane may be editing it.
