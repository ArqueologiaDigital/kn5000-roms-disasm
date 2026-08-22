# v7 pointer tables: from `.incbin` to `.long`

`convert_v7_ptr_tables.py`

## The question it answers

`docs/DISASSEMBLY-COMPLETENESS-SPEC.md` §3 says a `.incbin` is legitimate only if the bytes have
**no better human-readable representation**. A table of ROM addresses stored as raw bytes fails
that test twice over: the better form is `.long <symbol>`, and the raw form hides the call graph.

`scripts/analysis/l3_slice_structure_triage.py` flags **61 files / 8,440 bytes** of no-source-slice
blob as `PTR_TABLE`. That is a triage — its own docstring says a hit means "worth a human look",
not "is a pointer table". This script does the look, and then does the conversion:

| question | mode |
|---|---|
| Is this blob really a table of code/data addresses, on evidence that could have come out "no"? | `--list`, `--near-misses` |
| What would replace it, and do those `.long` lines assemble back to exactly the original bytes? | `--show LABEL`, `--check` |
| Do the tests discriminate, or would they fire on anything? | `--controls` |
| How does this change the triage's 8,440-byte headline? | `--reconcile` |
| Which names mean a different routine in v7 than in v10? | `--name-conflicts` |

## Commands

    python3 scripts/converters/convert_v7_ptr_tables.py                  # summary + gain
    python3 scripts/converters/convert_v7_ptr_tables.py --check          # byte-identity gate (exit != 0 on failure)
    python3 scripts/converters/convert_v7_ptr_tables.py --controls       # the nulls behind every verdict
    python3 scripts/converters/convert_v7_ptr_tables.py --reconcile      # vs the triage headline
    python3 scripts/converters/convert_v7_ptr_tables.py --name-conflicts # L2 violations this exposes
    python3 scripts/converters/convert_v7_ptr_tables.py --list
    python3 scripts/converters/convert_v7_ptr_tables.py --near-misses
    python3 scripts/converters/convert_v7_ptr_tables.py --show UIState_HandlerTable_Basic_00
    python3 scripts/converters/convert_v7_ptr_tables.py --apply          # the only mode that writes

Inputs: `original_ROMs/kn5000_{v7,v10}_program.rom` and
`rebuilt_ROMs/kn5000_{v7,v10}_program.llvm.elf` (so run `make llvm-all` first — the script reads
build **output**, it never builds).

## Expected gain (measured 2026-08-22, `--reconcile`)

    triage PTR_TABLE headline        : 61 files, 8,440 bytes
      of those, PROVEN a table       : 56 files, 7,632 blob bytes
        -> convert to .long          : 6,344 bytes
        -> residue staying a blob    : 1,288 bytes
      NOT a pointer table            : 5 files,   808 bytes
      tables the triage did NOT flag : 15 files, 1,740 bytes convert

    CORRECTED FIGURE: 71 files, 8,084 bytes of .incbin become .long

50 blobs vanish entirely (1,888 B); 21 are a table only in part and keep the residue as a smaller
`.incbin` slice, so nothing is laundered from "blob" into `.byte` lines. `--apply` writes 22 new
slice files. Of the 2,021 emitted words: **1,374 `.long Sym`**, **546 `.long Sym + off`**,
**101 `.long 0x…`**.

## Two corrections to the 8,440 B figure

1. **768 B are not a pointer table at all.** The three copies of
   `includes/generated/sound_data_organ_accordion.bin` are a **16-bit** table of organ/accordion
   drawbar levels. Two u16 values of `0x00f0` read as the u32 `0x00f000f0`, which sits inside
   `0x00e00000..0x00ffffff`, so the triage scores 64/64 "words in a ROM range" for a blob holding
   no address whatsoever. `--reconcile` detects the signature (byte 1 and byte 3 of every in-range
   word are zero) and names it. These blobs are also compiler output from a committed `.c` file,
   so they already have the better form the spec asks for.
2. **40 B are unproven.** `FlashWrite_BlockRef_Type3` / `_Type4` are 5 words each with only 2 exact
   symbol hits; the remaining three point *into* a data block, and "points inside some symbol" is
   not evidence (see below). They stay `.incbin` until something better is found.

## How a blob is proven — and why the obvious method says "no"

Resolving a target through `symbols/maincpu_symbols_reference.txt` lands on a known symbol for only
~3% of in-range words. That file is generated from the **v10** ELF; v7 is a different link, and
across these blobs v7 addresses sit 0x0 to 0x7d1 below their v10 namesakes in ten piecewise-constant
blocks. Resolved against `rebuilt_ROMs/kn5000_v7_program.llvm.elf` instead, the same words give:

| | count | |
|---|---:|---|
| in-range words in the 58 v7 `PTR_TABLE` romslices | 1,536 | |
| land **exactly** on a v7 symbol | 1,252 | 81.5% |
| land **inside** one, at offset 1..835 | 284 | 18.5% |
| land outside every symbol | 0 | |

⚠ **"Inside a symbol" is not evidence.** 38,984 symbol addresses over a 2 MB ROM put **79.2% of
random in-range addresses** within 4 KB after some symbol (`--controls`). A rule that accepts a blob
on interior hits cannot fail. Interior hits are therefore used only to *spell* a target once the
table is already proven, never to prove it. Two tests do the proving, and either suffices:

* **Tier A — v7 symbols.** Of the run's *k* in-range words, *e7* land exactly on a v7 symbol.
  Null = symbol density in the ROM window (1.86% analytic, 1.78% measured). Accept when
  `P(Binom(k, p0) >= e7) < 1e-4`.
* **Tier B — v10 corroboration.** Some real tables point at code v7 has never labelled, so `e7 = 0`.
  For those, read the same label's table out of the **v10** ROM at its v10 ELF address and count how
  many of *its* words land exactly on a v10 symbol. Accept when that is significant, the induced
  v10→v7 address pairing is strictly order-preserving (zero inversions), **and** at least one pair
  is shifted — otherwise the two ROMs are simply identical there and the agreement means nothing.
  That last guard is what stops the drawbar table from passing.

43 tables clear Tier A, 28 clear Tier B.

## Negative controls (`--controls`)

| set | words in a ROM range | of those, exactly a symbol |
|---|---:|---:|
| converted blobs | 25.8% | 68.8% |
| every other v7 romslice | 2.9% | 18.9% |
| same blobs, bytes shuffled | 5.0% | 3.0% |
| random in-range address | — | 1.78% |

## Byte-identity

`.long` emits 4 bytes little-endian with **no alignment padding** — `PerfMode_ParamHandler_Table`
sits at the odd address `0x00ef6393` in v7 and `0x00ef63bd` in v10, and v10 already spells it as 19
`.long` lines in a ROM that rebuilds byte-identically.

`--check` proves the round trip without invoking the assembler: every emitted line is resolved in
Python — `.long Sym` to the address the v7 ELF gives `Sym` — and the result is compared with the
blob byte for byte. It exits non-zero on any mismatch. Currently **71/71 verified**.

⚠ **A name existing is not enough.** v7 carries names that sit on a *different* routine from the
v9/v10 name of the same spelling: `UIState_ProcessDisplayUpdate` is at `0x00fd009b` in v7, while the
routine v10 gives that name corresponds to v7 `0x00fcfc81` — 0x41a away. Emitting the name because
the name exists would have silently changed the ROM. Every symbol emitted here is read from the v7
ELF *at the address the word already holds*, so a name can only appear when it resolves to the value
it replaces.

## Scope

`includes/romslices/` only. `includes/generated/` blobs are compiler output from committed C
sources; 16 of them do contain pointer tables, but rewriting them as `.long` would fork the data
away from its source. `--include-generated` overrides and should not be used.

## What this leaves open

* **284 unlabelled entry points.** Every `.long Sym + off` line is a target the v7 disassembly has
  not named — 546 emitted words across the proven tables. They are reachable only through these
  tables, which is exactly the L2 requirement "every entry point is known, including those reached
  through jump tables".
* **`symbols/maincpu_symbols_reference.txt` describes only v10.** v7 and v9 are separate links; the
  file is silently wrong for both, and that is what made the earlier measurement read 3%.
* **153 v7 names sit on the wrong routine** relative to v9/v10 — see `--name-conflicts`. Of 1,309
  names cross-checked through the table correspondence, 153 resolve in the v7 ELF to an address
  that is not where the routine lives; 152 of them are off by exactly 1050 (0x41a), spanning
  `SndParam_*`, `MidiPkt_*`, `UIState_*`, `SoundFX_Handler_*`, `HdaeRom_*` and `CharMap_*`. The
  mode prints, per name, the byte agreement with the v10 routine at the address the *name* claims
  and at the address the *table* points to: **the table wins 153/153**, at ~1.00 against ~0.01.
  This violates the L2 rule that a name means the same thing everywhere, and it is why this
  converter refuses to take a name from the v10 side.
