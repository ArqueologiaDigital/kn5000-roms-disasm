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
| maincpu v10 / v9 | 2,097,152 | **99.77% honest** (tool says 59.0%) | 860,028, of which 855,100 is C recompiled | **L0 CLEAN**, poison-verified |
| maincpu v7 | 2,097,152 | **93.2% real source** (0 copied -- de-circularised 2026-08-21) | 141,893 documented no-source | **L0 CLEAN** |
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
| table data | ~~395,150~~ **0 -- DONE** | ~~65,536~~ **0** | 652,435 | **0** |
| custom data | ~~663,552~~ **0 -- DONE 2026-08-21** | ~~4,096~~ **0** | 0 | **0** |
| HD-AE5000 | ~~313,076~~ **0 -- DONE 2026-08-21** | 0 | 0 | **0** |
| **total** | **0** | **0** | 652,435 | **0** |

**ZERO bytes are blobs that should not be blobs.** Every ROM's column is zero.

The 652,435 B that remain binary are legitimate under §3: six genuine Windows BMPs stored
verbatim, and the SLIDE4K/SLIDE8K compressed streams, whose codec has a committed decoder AND
encoder and rebuilds byte-exactly. That is the work queue, and it is the number
to report instead of any percentage.

**HD-AE5000 is closed.** Its 313,076 B of graphics -- four 320x240 8bpp screens, five 256-entry
palettes and the 27x27 icon -- now build FROM committed palette-indexed PNGs and palette text files,
via `scripts/build/hdae5000_images.py`. The PNGs store palette INDICES, not colours, because these
palettes contain duplicate colours and an RGB round trip would be ambiguous; the icon's 28th padding
byte per row is preserved in a sidecar because it is not always zero. `hdae5000_images.py verify`
asserts all ten rebuild the ROM bytes exactly, and the gate passes 9/9 with the images as the
build's actual input. That is L4 satisfied for this ROM: readable form committed, round-trip proven,
blob no longer the source.

The same pattern then closed table_data's two wallpapers (153,600 B) via
`scripts/build/indexed_images.py`, which is the manifest-driven generalisation: add a row, run
`export`, run `verify`. If verify fails the geometry is wrong, which is how the HD-AE5000 icon's
27x27-in-a-28-byte-row would have been caught years earlier.

Then the 87 UI bitmaps (53,062 B): transport buttons, faders, the Technics wordmark, the note and
drum edit grids -- previously 87 offset/length slices of one opaque blob, with their dimensions
written only in end-of-line comments that nothing checked against the bytes. Every one turns out to
have an INTEGRAL row stride (length / height is always whole and never below the width; padding is
0 or 1 byte, for 44 and 43 of them respectively). That rule is what made them convertible, and it is
the same rule the HD-AE5000 icon broke unnoticed.

Then the 177 UI icons (50,976 B), which are 4 BITS per pixel -- 24x24 in 12-byte rows, high nibble
first. The PNGs store the nibble as the pixel value, so the palette used for display is irrelevant
to the round trip.

Then nine of the ten glyph banks (39,872 B) as PNG sheets, 16 glyphs across and 14 down. This is
the first artefact covering the FULL 224-glyph range: the committed BDFs stop at 95 ASCII
characters, leaving the UI's arrows and markers and the Latin-1 accents -- the part the
multilingual UI actually needs -- in no readable form at all. The sheets render at the full byte
width, ceil(w/8)*8, because the padding bits past the glyph are not always zero. Font 5 is
proportional and tiled per its kern table; it remains a blob (3,696 B) and is the one font item
left.

The good news in that table is the last column. **Nothing is UNKNOWN.** Every blob has been
identified; none of this is blocked on understanding. It is blocked on conversion.

The genuinely opaque 652,435 B is legitimate under §3: six real Windows BMPs stored verbatim, 19
SLIDE4K demo songs and 5 SLIDE8K help databases -- all of which have a documented codec with a
committed decoder AND encoder, and rebuild byte-exactly.

## L0: the integrity problem, now measured

**The gate is demonstrably foolable.** `compare_roms.py` is a byte-for-byte comparison with no
provenance awareness: a two-line `.s` containing one `.incbin` of the original ROM assembles, links
and scores 100.00%. So the gate proves the build is REPRODUCIBLE, never that anything was
UNDERSTOOD.

Measured with `scripts/analysis/rom_provenance_poison.py`, which XORs every 8th byte of an original
ROM, rebuilds from the poisoned copy, and compares against the real one. Bytes derived from source
are unaffected; bytes copied at build time carry the poison:

| target | differing bytes | verdict |
|---|---|---|
| v9 | **0** | CLEAN -- the build reads nothing from this ROM |
| v10 | **0** | CLEAN |
| v7 | ~~122,387~~ **0** | **CLEAN as of 2026-08-21** -- extraction removed, slices committed |

`extract_v7_bins.py` writes raw v7 ROM slices into `v7/maincpu/includes/generated/`, which is
untracked and regenerated by every `make clean-all && make all`. 288 of those bins have no C source
at all (136,775 B).

Two corrections to the coverage tool, in OPPOSITE directions -- both found by this check:

- **It overstates v7's damage by ~137x.** Its "23 files / 703,693 B reproduced by no source" is a
  WHOLE-FILE count; byte-for-byte those files diverge from clang output in about 5,100 B. (An
  earlier version of this document repeated the 703,693 figure. It was wrong.)
- **It misses the larger mechanism**, modelling only stage 1 and not the 288 pure-slice bins.
- **It understates v9/v10 badly.** Their `source%` column subtracts ALL `.incbin` including the
  855,100 B of legitimate, genuinely-recompiled C. Their real-source share is **99.77%**.

**And it is worse than "partly circular".** Removing the copy step was attempted (see
`analysis/v7-provenance-audit/README.md`). Every referenced bin was verified byte-identical to what a
successful build leaves behind -- 353 of 353 -- and the sources changed only in `.incbin` paths.
Rebuilding still gave **46.33%**, deterministically, with every pointer at ROM 0xE00012 shifted 208
bytes: a layout shift, not corrupt data.

So the accurate statement is not that 93.00% "would be reconstructible". It is:

> **v7 cannot currently be rebuilt from committed inputs at all.** No set of committed files
> assembles to the v7 ROM. The 100.00% is manufactured per-run by a two-pass extraction that reads
> the ROM twice and seeds its addresses from the *v9* ELF, and no fixed point of that process has
> ever been committed.

The 5,118 bytes where the committed C genuinely fails to reproduce the ROM are mapped by file and
offset in `analysis/v7-provenance-audit/v7_c_divergence.json` -- a precise work list, and the one
part of the attempt worth keeping.

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

1. **Settle L0 first.** Commit the 288 used slice bins and delete their build-time regeneration:
   that converts them from "injected at build time" to "committed blob" at a stroke -- same bytes,
   but the ROM stops being an input to its own reconstruction. Same for `split_custom_data.py`.
   Then wire `rom_provenance_poison.py` into CI with a per-target copied-byte BUDGET that must not
   grow, so this cannot silently come back.
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
    python3 scripts/analysis/rom_provenance_poison.py all   # which targets read their own ROM
    make clean-all && make all          # 9/9 at 100.00% -- necessary, not sufficient

## What closing table_data took

Font 5 was the last hard one because it is proportional: 224 widths of 3 to 10, each glyph
`ceil(width/8)*16` bytes at its own offset. Its widths are read from the kern table already typed
out in `fonts.s` rather than duplicated, and the rebuild asserts glyph by glyph that the offsets
tile -- they are monotonic, gapless, and sum to exactly 0xE70.

The eight 1bpp banners are the screens shown while the instrument reflashes itself, failure cases
included: "Now Erasing", "Please Wait", "Turn On AGAIN", "Illegal Disk".

The selection rule for the 34-image batch is worth keeping: an image qualified when its DECLARED
geometry multiplied out to exactly its file size. That is a check, not a convenience -- it is the
same check the HD-AE5000 icon failed silently for months, and running it over the whole tree found
every convertible image without anyone deciding case by case.

## ⚠ SUPERSEDED: "the one thing left"

This section used to say `custom_data`'s 639,296 B could not be converted because "what 0x90's
five arguments mean" was unknown and cells framed 725/725. **All three claims were wrong or became
wrong later the same day**, and it is kept only as a marker:

* `0x90`'s five arguments were never unknown -- they are documented in
  `scripts/build/demo_preset_to_midi.py` as pos, note, velocity, dur_ticks, dur_beats. I wrote
  that they were unknown without checking.
* 725/725 was a miscount: the probe searched for `80 FF FF FF FF 87`, which matches only cells
  whose next pointer is 0xFFFF. There are 1564 cells, and 1050 chains.
* The data IS converted. `custom_data/styles/*.styles` are the build's source and the four blobs
  are deleted.

The genuine remainder is smaller and different: NOTE2's two trailing fields, CTL1 (which carries a
contradiction between the style data and the playback code), CTL2, and CTL3 -- see
`accompaniment-style-format.md`.

## custom_data closed, 2026-08-21

The last 659,456 B. The style banks now build from committed event listings -- `custom_data/styles/
*.styles`, 1.8 MB of text -- and the four `.bin` blobs are DELETED, with the gate still at 9/9.
`style_events.py verify` checks the rebuild against `original_ROMs/kn5000_custom_data.ic19`
directly, so the check does not depend on the artefact it is checking.

A style now reads as music:

    CHAIN 014 cells=5
      NOTE 0 105 92 19 0
      NOTE 0 49 100 19 0
      NOTE 45 105 89 8 0
      BEAT

What made this possible was solving the container, which took four wrong readings first -- two of
them mine, in this session. See `docs/accompaniment-style-format.md`.

**What is still NOT claimed**: NOTE2's two trailing bytes and the three controller values are
NAMED, not understood. Their argument counts are confirmed across all 50,245 events; what they
select is not established, so they are emitted as numbers and never as invented labels. Under the
spec that leaves this format at L3-partial: the container is fully specified and round-trips, the
event semantics are not complete.

## Composer_FactoryMemoryImage: the last partially-understood blob

64 KB inside `table_data`, recorded until today as "30 slot records with names, 52 cell headers,
no field spec, no parser". It is the SAME cell/chain container as the IC19 styles, and once that
was solved the identical rules decode it with no adjustment: 234 cells, **168/168 pointers
resolving, 84/84 back-links, 7,457 events, none malformed**. Its section nibble is 0 rather than 1;
nothing else differs.

It now builds from `custom_data/styles/Composer_FactoryMemoryImage.styles` like the rest.

That empties the "partially understood" column too. What remains binary -- 652,435 B -- is
legitimate under §3: six genuine Windows BMPs stored verbatim by the firmware, and the
SLIDE4K/SLIDE8K compressed streams, whose codec has a committed decoder AND encoder and rebuilds
byte-exactly.

## v7's L0 failure is fixed, and my proof that it could not be was wrong

`rom_provenance_poison.py v7` now reports **0 differing bytes**: the build reads nothing from the
v7 ROM. The 288 bins with no source (136,775 B) are committed; the 23 C bins that diverge do so by
only 5,118 bytes, kept as a committed patch rather than 703 KB of blob. Gate 9/9 with
`extract_v7_bins.py` and both its invocations gone.

Honest v7 figure: **1,955,259 B (93.2%) real source**, 141,893 B (6.8%) committed and documented as
having no source. Those are honest under §3 but they are the remaining v7 work: emptying
`v7_c_divergence.json` by fixing the C is what would make v7 genuinely reconstructed.

**⚠ The earlier entry here said v7 "cannot currently be rebuilt from committed inputs at all". That
was wrong, and the cause was mine.** The script that repointed `.incbin` paths read each source with
`read_text(errors='replace')` and wrote it back -- replacing every non-UTF-8 byte in the `.ascii`
literals with U+FFFD, changing their assembled length, and shifting everything after. The 208-byte
pointer shift I published as evidence was string data I had destroyed. See
`analysis/v7-provenance-audit/README.md`.

Two lessons, both cheap: never round-trip a disassembly source through text decoding, and when a
measurement yields a strong surprising claim, check the apparatus before publishing. Assembling
directly with the same inputs gave an EXACT match and would have contradicted the claim in one
command.

## v7's divergence is pointer relocation, not mystery bytes

The 5,118 bytes where the shared C fails to reproduce v7 are now explained rather than recorded.
**2,365 of them are 32-bit pointers** the C emits with its v9/v10 target where v7's is lower by a
fixed amount, and the deltas are piecewise over disjoint address ranges:

    0x00F01C29..0x00F35DE9  -0x2A   986 sites   (the known v7 code offset)
    0x00F8784D..0x00FB3062  -0x40D  715
    0x00F4E778..0x00F87614  -0x404  333
    0x00FB8B0B..0x00FC6DEE  -0x7CB  309
    0x00F42DF8..0x00F477DA  -0x0E    69
    0x00003991..0x00003A3C  -0x9C    15   (a RAM-space table)
    0x00F3ECB3              -0x1C     8
    0x00FCF11B..0x00FCF13C  -0x7D1    4

**Zero of the 2,464 relocation sites were left unexplained** by that map. 1,334 bytes remain raw,
and two files fall back to a whole-file diff -- one because v7's version is a different LENGTH
(naka_sequencer_channels: 7,894 B against v9's 7,936).

A blind scan-and-relocate was tried and does NOT work: applying the map to every 32-bit value in
range corrupts data that merely looks like an address, reproducing 8 of 23 files. So the sites are
recorded explicitly, each saying "this offset holds a pointer, move it by D" -- which is what makes
this a specification of the difference rather than a byte blob.

Remaining v7 work is now precisely scoped: make the C v7-aware at those 2,365 sites and the patch
empties. Total unreconstructed: 0.51% of the ROM.

## The blob claim is self-checking now

`scripts/analysis/audit_incbin_legitimacy.py` classifies every active `.incbin` in the tree against
§3 and EXITS NONZERO if one is unclassified. Current output: 873 directives, all justified.

    790  generated or committed no-source slice
     40  rebuilt from a committed PNG or palette text
     24  compressed, codec has a committed encoder
     11  style bank rebuilt from committed .styles
      6  genuine Windows BMP stored verbatim
      2  SLIDE8K remnant, compressed and documented

Two methodology traps were hit while writing it, and both are in its docstring because either one
silently corrupts the count:

* `.incbin` appears inside COMMENTS -- this tree keeps `; Was: .incbin ...` lines on purpose --
  so counting raw matches invents ten hdae5000 includes that do not exist. I reported those ten as
  unaccounted before checking.
* a directive usually sits on a LABEL line (`Font0_Glyphs:\t.incbin "..."`), so a regex anchored
  at line start misses 382 of the 873, which made a first pass report 491.

A headline that nobody can re-check is the thing this project keeps getting caught by. This one
re-checks itself.

## ⚠ I overstated what the control-panel link needs hardware for

Repeatedly this session I recorded that the control-panel wire layer "cannot be closed from the
ROMs at all" and "needs a logic analyser on the real instrument". **That is too broad, and testing
my own blocking claim is how it should have been checked the first time.**

The boot-time CP-serial driver is fully disassembled and annotated across three files --
`table_data/boot_cpserial.s` (polling/setup, ROM 0x9FEC6E-0x9FF228), `boot_cpserial_isr.s`
(the three interrupt handlers, 0x9FF229-0x9FF2F1) and `boot_cpserial_states.s` (state handlers,
packet codecs, ring helpers, 0x9FF2F2+). The WIRE PARAMETERS are literals in that code:

    SC1MOD = 0x00        serial channel 1 mode          (ldio 0xd6, 0x00)
    BR1CR  = 0x14        baud rate control              (ldio 0xd7, 0x14)
    SC1CR  = 0x01        serial control                 (ldio 0xd5, 0x01)
    baud source = timer A (TAMOD |= 0x10, &= ~0x08)
    INTA enabled via INTEAB = 0x07; INTES1 = 0xFF (RX+TX, max priority)

and the link opens with a two-byte frame `0x1F 0xDA` followed by a four-frame handshake
(`BootSerial_FullInit` -> `BootSerial_HandshakeSequence`). The panel pulls INTA both to open a
receive transfer and to pace one during RX.

So an L5 specification of this protocol IS writable from the disassembly: register programming,
interrupt roles, the state machine, the handshake and the packet codecs are all present. Whoever
writes it should decode the three register values against the TMP94C241 datasheet rather than
trusting a curated comment.

**What genuinely needs the instrument** is narrower than "the protocol": VALIDATING behaviour
against a real panel. That is where this project's open defect lives -- the data-wheel steady state
is unresolved and the shipped `kn5000-30` fix for it was falsified -- and no amount of reading the
ROM settles what the panel actually puts on the wire.

Correcting the scope of a blocker matters as much as closing one: "needs hardware" was being used
to excuse a document that could have been written from material already in the repository.
