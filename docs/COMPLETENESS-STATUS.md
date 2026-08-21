# Where this disassembly actually stands, against the spec

Measured 2026-08-21, against `DISASSEMBLY-COMPLETENESS-SPEC.md`. Every number here was produced by
a committed script, named at the end of each section.

## The headline that was wrong

"The disassembly is done" was claimed on the strength of `Similarity: 100.00%` on 9 build targets.
That claim does not survive the project's own coverage tool, whose docstring already said so:

> Byte-match is 100.00% on all 15 sections and always will be -- it says nothing about
> understanding. This does.

## Per-ROM status

| ROM | bytes | source | blob | verdict |
|---|---|---|---|---|
| subcpu payload v142 | 196,608 | **100.0%** | 0 | closest to done |
| subcpu boot (IC30) | 131,072 | **100.0%** | 0 | closest to done |
| maincpu v10 / v9 | 2,097,152 | 59.0% | 860,028 (855,100 C-recompiled) | L0 clean, L3/L4 open |
| maincpu v7 | 2,097,152 | 52.5% claimed | 995,213 | **L0 SUSPECT -- see below** |
| table data | 2,097,152 | 46.9% claimed / **62.0% honest** | 1,113,121 | L1 done, L4 open |
| HD-AE5000 | 524,288 | 40.3% | 313,076 | L1 done, L4 entirely open |
| custom data (IC19) | 1,048,576 | 36.3% claimed / **0.0% honest** | 667,648 | **worst; L0 circular** |

Two corrections to the coverage tool itself, both found this session:

1. **It is too harsh on table_data.** 316,397 B of what it counts as "raw blob" is a gitignored
   BUILD PRODUCT regenerated from committed human-readable source (the demo presets and help
   databases are real Makefile prerequisites). The honest table_data source figure is
   **1,300,428 B = 62.0%**.
2. **It is too kind everywhere.** Of table_data's 984,031 "source" bytes, 580,448 are bare `.byte`
   lists and 138,536 are 0xFF/0x00 fill. `style_records.s` alone emits 115,000 B of parameter block
   its own header calls "MIDI-range values, undecoded". **Typed is not understood**, and the tool
   cannot tell the difference.

## The single honest metric: illegitimate blob bytes

Per spec §3, a `.incbin` is legitimate only if the bytes have no better human-readable form.
Classifying every blob byte in the three worst ROMs:

| ROM | SHOULD NOT BE A BLOB | partially understood | genuinely opaque | unknown |
|---|---|---|---|---|
| table data | 395,150 (35.5%) | 65,536 | 652,435 | **0** |
| custom data | 663,552 (99.4%) | 4,096 | 0 | **0** |
| HD-AE5000 | 313,076 (100%) | 0 | 0 | **0** |
| **total** | **1,371,778** | 69,632 | 652,435 | **0** |

**1,371,778 bytes are blobs that should not be blobs.** That is the work queue, and it is the number
to report instead of any percentage.

The good news in that table is the last column. **Nothing is UNKNOWN.** Every blob has been
identified; none of this is blocked on understanding. It is blocked on conversion.

The genuinely opaque 652,435 B is legitimate under §3: six real Windows BMPs stored verbatim, 19
SLIDE4K demo songs and 5 SLIDE8K help databases -- all of which have a documented codec with a
committed decoder AND encoder, and rebuild byte-exactly.

## L0: the integrity problem

`scripts/analysis/kn5000_source_coverage.py` reports that `extract_v7_bins.py` overwrites 63
C-compiled bins with raw v7 ROM slices, and that 23 files / 703,693 B genuinely differ from what the
C compiles to. If that holds, those bytes are ECHOED, not reproduced, and v7's 100.00% cannot fail
for them. A separate check of this is in progress; until it reports, **v7's coverage figure should
not be quoted**.

`custom data` has the same disease in a purer form: `split_custom_data.py` is a pure ROM slicer and
all 380,928 non-`.incbin` bytes are `.space 0xFF` filler. There is not one typed or disassembled
byte in that target. Its honest L0 coverage is **0.0%**.

## L4: assets

Only **three** asset classes can put their human-readable form back into the build -- FTBMP (the ROM
stores real BMPs), UI strings (assembler source) and screen layouts (C compiled to `.bin`). Help
databases round-trip too, verified live this session.

**No reverse converter exists for any pixel or glyph asset.** Every font and image artefact is a
*view* of a blob that remains the build input. Concretely:

- fonts: format fully established, but every committed BDF is ASCII-95; the 25,074 B of upper code
  page -- the arrows, markers and Latin-1 accents the multilingual UI depends on -- is in no
  readable artefact;
- icons: 191 PNGs committed, regenerate byte-identically, but one-way;
- UI bitmaps, factory images, wallpapers: ~800 KB of viewable pixels with **no committed viewable
  form at all**.

Two extractor bugs found and fixed this session: `extract_fonts.py` resolved the repo root as
`scripts/` and could not run at all (it now reproduces all ten BDFs byte-identically), and
`convert_images.py` decoded HDAE5000_Icon as 28x28 with no stride concept, rendering 28 bytes of a
neighbouring string as a row of pixels.

## L5: protocols

Graded against "could an outsider reimplement this from the committed docs alone?":

| subsystem | grade |
|---|---|
| SLIDE4K / SLIDE8K compression | **SPECIFIED** -- the only one that passes cleanly |
| wave / multisample model | SPECIFIED, but only inside `tone_database_aux.s`; the published page is six months stale and teaches a superseded model |
| inter-CPU latch, control panel, IC303 registers, DSP, FDC, tone records | DESCRIBED |
| MIDI / SMF / sequencer, style / rhythm format | **SKETCHED** |

The largest single gap: **the machine's own musical payloads are undocumented.** There are 446
`SeqStep_*`, 653 `SMF_*` and 1007 `StyleRec_*` symbols in the sources, and no record layout, no
delta-time encoding, no distinction between the native format and real SMF. Nobody can read or
write a KN5000 song, or play one factory rhythm, from the documentation.

Also: several live contradictions between the published docs and the sources (SLIDE4K size field BE
vs LE, two different `CMD_DISPATCH_TABLE` addresses, two different EG laws, "hardware envelopes" vs
"no hardware EG" on two pages of the same site).

## What to do next, in order

1. **Settle L0 first.** Make the v7 figure honest and stop `split_custom_data.py` from slicing. A
   coverage number computed over a circular build is not a coverage number. Add a gate that fails
   when a build input is derived from the ROM.
2. **custom data, 663,552 B.** Its content is decodable *today* with `demo_preset_to_midi.py`, whose
   grammar it already satisfies (725/725 cells frame cleanly). It was scoped out, not defeated.
3. **HD-AE5000, 313,076 B.** Pure conversion: 4 x 320x240 images, 5 palettes, 1 icon. ~1 day.
4. **table_data's 395,150 B** of wallpapers, UI screens, bitmaps, icons, fonts and banners: needs
   PNG->raw and BDF->glyph-bank compilers, then wire them into the Makefile so the readable form
   becomes the build input. ~3 days.
5. **Write the sequencer/style formats down.** This is the biggest documentation gap and the one
   that most affects anyone else who wants to use this work.
6. **Reconcile the published docs with the sources**, and retire the stale wave-format page.

## Reproducing every number here

    python3 scripts/analysis/kn5000_source_coverage.py
    python3 scripts/analysis/verify_stale_band.py original_ROMs/kn5000_table_data.rom
    python3 scripts/analysis/ic19_cell_grammar_probe.py original_ROMs/kn5000_custom_data.ic19
    python3 scripts/analysis/audit_icons_blob_coverage.py
    python3 scripts/analysis/extract_fonts.py /tmp/fonts && diff -r /tmp/fonts extracted_fonts
    make clean-all && make all          # 9/9 at 100.00% -- necessary, not sufficient
