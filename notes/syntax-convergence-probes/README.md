# Syntax-convergence probes

Everything behind `notes/ASSESSMENT-syntax-convergence-2026-09-02.md`. Four
scripts, each answering one question, plus the outputs they produced on
2026-09-02.

Run them from the **tree root**, in this order (the last three read the first
one's output). Total runtime about two minutes.

    python3 notes/syntax-convergence-probes/mnemonic_census.py      --out notes/syntax-convergence-probes/out
    python3 notes/syntax-convergence-probes/oracle_ab.py            --out notes/syntax-convergence-probes/out
    python3 notes/syntax-convergence-probes/diff_causes.py                notes/syntax-convergence-probes/out
    python3 notes/syntax-convergence-probes/native_convergence.py         notes/syntax-convergence-probes/out
    python3 notes/syntax-convergence-probes/decoder_disagreements.py      notes/syntax-convergence-probes/out

`out/RUN.log` is the transcript of exactly that sequence, and every figure in
the assessment is a line of it.

| script | the question it answers |
|---|---|
| `mnemonic_census.py` | How many call sites use a mnemonic unidasm does not have, in how many files, and how many of those are byte-emitter pseudo-instructions no rename can reach? |
| `oracle_ab.py` | On the same bytes, do the two decoders ever disagree about the *instruction*? And if the tree's source were rewritten in unidasm's own text, how much of it would still assemble to the ROM's bytes? |
| `diff_causes.py` | When re-assembling unidasm's text gives different bytes, what did unidasm's text fail to say? |
| `native_convergence.py` | How much of that is recovered by the one annotation UPDATE 7 already supports — the address width, `(0x2075:16)`? |
| `decoder_disagreements.py` | Where are the sites unidasm refuses, in the sources? |
| `direct_address_residue.py` | Which synthetic mnemonics still spell a direct address, and at how many sites? ⚠ Read off the backend's OPERAND LIST, not the name's shape -- the name-shape estimate undercounted this residue by 22%. |
| `xname_slot_convention.py` | When a 32-bit register NAME is written against a narrower form, which register does the assembler encode? ★ The answer is per instruction CLASS: `ldb_da xbc` is C (the pair's low byte), `cpda8 xbc` is A (the same index). Run it before trusting any x-name rename in a new family. |
| `size_family_convert.py` | For each size/form mnemonic: is the name a spelling the operand syntax can already express, or a selector between two legal encodings? And, for the spellings, rewrite every site — but only after assembling both spellings at all of them. |

## What the signals mean

* **`LEN_DIFFER`** — the two decoders consumed a different number of bytes.
  This is the only unambiguous "they disagree about the instruction" signal, and
  it is **zero** across 1,113,485 sites.
* **`UNIDASM_DB`** — unidasm has no decode for bytes this backend both
  assembles and disassembles. Eight sites, four distinct byte patterns; all
  listed in the assessment.
* **`UNI_ASSEMBLES_DIFF`** — the backend accepted unidasm's text and emitted
  *different bytes*. This is the class that matters: it is silent.

## ⚠ Controls, without which the numbers are worthless

* **`oracle_ab.py --foil N`** lengthens every Nth harvested encoding by one
  byte, so unidasm must read fewer bytes than the record claims and those sites
  must come back `LEN_DIFFER`. `out/FOIL-CONTROL.log` is that run: 5,763
  `LEN_DIFFER` on 40,330 sites at `--foil 7` (expected 5,761). Without it,
  "`LEN_DIFFER` = 0" is a criterion that cannot fail.
* **The ambiguity null.** `oracle_ab.py` measures how many *distinct byte
  strings* print as the same text, for BOTH syntaxes over the same corpus.
  unidasm: 134 texts / 3,172 sites. This tree's LLVM text: **0 of 89,917
  distinct texts**. The second number is the control that says the first is a
  property of unidasm's notation, not of the corpus.
* **`UNI_PCREL`** is a live control that must stay 0, and does. It was an
  attempt to detect PC-relative spellings by re-assembling at a shifted origin;
  it cannot work here because this backend's `jr`/`jrl`/`calr` take a
  *displacement*, not a target, when handed a bare number. Branches are
  classified by unidasm's own mnemonic instead (`UNI_BRANCH_TARGET`).

## ⚠ Traps these scripts hit, recorded so the next reader does not

* **llvm-mc prints an encoding for a line it rejected.** `calr 0x0185f8` is
  diagnosed *and* shows `encoding: [0x1e]`. Reading stdout alone scored
  rejected spellings as "assembles to different bytes": consulting stderr moved
  `UNI_REJECTS` from 11,240 spellings to 41,819. Errors must be taken from
  stderr by line number.
* **GNU grep -E reads `\t` inside a bracket expression as two literal
  characters**, so `[ \t]+` matches no tab and the search silently returns
  nothing — while the same pattern works when pasted into the interactive
  shell, whose `grep` is ugrep. Use `[[:blank:]]`.
* **Other lanes rebuild `~/compartilhado/llvm-project` while this runs.** A run
  that harvests with one binary and re-assembles with the next measures two
  backends. `oracle_ab.py` copies `llvm-mc` aside first and records its sha256
  with the results; the committed run used `c13a8a9a0100a38c`.
* **An unbuilt worktree cannot assemble every root source**, but the only
  errors are `Could not find incbin file` — those drop DATA, never an
  instruction encoding, so the harvest is complete either way. The run prints
  the error census so this stays checkable.

## `size_family_convert.py` — lane `w16/conv-size`

Added 2026-09-02 by the lane executing §8 of the assessment for the class-2
mnemonics. It writes to the sources, so it is the one script here that is not
read-only, and it refuses to write if a single site's bytes move.

    python3 notes/syntax-convergence-probes/size_family_convert.py --triage
    python3 notes/syntax-convergence-probes/size_family_convert.py --collisions
    python3 notes/syntax-convergence-probes/size_family_convert.py --sentinel
    python3 notes/syntax-convergence-probes/size_family_convert.py --family incm
    python3 notes/syntax-convergence-probes/size_family_convert.py --family incm --foil
    python3 notes/syntax-convergence-probes/size_family_convert.py --family incm --apply

| mode | the question it answers |
|---|---|
| `--triage` | Does the native spelling of each mnemonic emit the same bytes? |
| `--collisions` | Would "let the assembler pick the short form when the immediate fits" be safe? (No — 2,714 long-form sites already hold a short-fitting immediate.) |
| `--sentinel` | How many sites spell the explicit `d8 = 0` encoding as the magic displacement 256? |
| `--family X` | Assemble the old and new spelling of **every** site of X and report any whose bytes differ. Writes nothing. |
| `--family X --foil` | ⚠ The control: substitute a plausible but wrong native spelling; every site must come back a mismatch. Never writes. |
| `--family X --apply` | Same as `--family X`, then rewrite the sources — only if zero sites disagree. |

`out/SIZE-FAMILY-RUN.log` is the transcript, with the toolchain commit and the
`llvm-mc` sha256 the numbers were taken at. The verdicts are written up in
`notes/TRIAGE-size-form-mnemonics-2026-09-02.md`.
