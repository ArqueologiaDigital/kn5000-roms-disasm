# Lane BMP -- table_data's six FTBMP files are already in their best form
(2026-09-02)

LLVM: tlcs900_backend@dbb72df07371 (dbb72df073711ef98be1e41f003e04a7022bf120)

## Question this answers

`notes/lanes/BRIEF-2026-09-01.md` assigned lane BMP the single largest remaining
verbatim-debt block: `table_data`'s six FTBMP files, 318,468 B, checked in as
`.incbin`. `notes/DEBT-INVENTORY-2026-09-02.md` frames the fix as "a round-trip
generator, not disassembly", on the pattern of `scripts/build/indexed_images.py`
and `scripts/build/mono_images.py` (headerless raw-pixel `.bin` -> PNG -> `.bin`,
verified byte-exact).

**Conclusion: do not build that generator here. The six files are already the
best representation this data can have, and building a PNG round trip would be a
regression, not progress** -- the wallpaper `.byte` reversion this push's brief
warns against, in a different disguise: adding machinery that produces no
improvement in viewability while adding risk of drift.

## What the six actually are

`table_data/images/FTBMP0[1-6].BMP`, `.incbin`'d directly (no offset/length args --
whole file) by `table_data/kn5000_table_data.s:173-188`. Verified this session
with `scripts/analysis/verbatim_bmp_header_audit.py`:

| file | size | dims | content (viewed directly) |
|---|---:|---|---|
| FTBMP01.BMP | 77,878 B | 320x240 | Technics logo + world globe |
| FTBMP02.BMP | 42,678 B | 320x130 | Upside-down, showcasing subwoofers |
| FTBMP03.BMP | 39,478 B | 320x120 | Some floppy disks |
| FTBMP04.BMP | 39,478 B | 320x120 | Inserting disks into the floppy drive |
| FTBMP05.BMP | 41,078 B | 320x125 | Arrows representing 360 surround sound |
| FTBMP06.BMP | 77,878 B | 320x240 | KN5000 name + rainbow comet |

Total 318,468 B, matching `table_data_debt.py`'s `verbatim-bmp` figure exactly.
Each is a genuine, standard, uncompressed **BITMAPFILEHEADER + BITMAPINFOHEADER**
(40-byte DIB header) 8bpp palette BMP: magic `BM`, `compression=0` (BI_RGB),
`planes=1`, `bpp=8`, 256-colour palette immediately following the header at the
declared offset, pixel rows exactly `width` bytes wide (320 is already a multiple
of 4, so no row padding), and the header's own file-size field matches the file
on disk. `FTBMP01.BMP`, opened directly with PIL/any viewer with **zero**
project-specific tooling, renders as a correct, undistorted world map under the
"Technics" wordmark -- confirming `extract_include_binaries.py`'s comment.

These are shown during a firmware/floppy update, the same UI moment as the eight
1bpp banners `mono_images.py` already handles ("Now Erasing", "Please Wait", ...),
just full-colour illustration screens rather than text banners.

## Why no generator

The PNG-round-trip pattern (`indexed_images.py`, `mono_images.py`) earns its keep
because its *inputs* are headerless raw pixel dumps: a `.bin` with no self-
describing header is opaque to every generic tool, so converting it to PNG is a
real gain in viewability, and the generator is the (non-trivial) bridge back to
the ROM's exact raw layout.

Table_data's FTBMPs have no such gap. They are **already** complete, standard,
self-describing files that any image viewer or editor (GIMP, `xdg-open`, a
browser) opens correctly today, with the exact bytes the ROM needs, because the
`.incbin` reads the very same committed file -- there is no separate raw-pixel
form upstream of it to convert. `docs/COMPLETENESS-STATUS.md`'s L4 section
already says this, independently of this lane: "Only three asset classes can put
their human-readable form back into the build -- **FTBMP (the ROM stores real
BMPs)**, UI strings ... and screen layouts." Converting the BMP into a PNG would:

* gain nothing in viewability -- both formats are opened by the same generic
  tools;
* require a generator to reproduce the BMP's own header/palette exactly (an
  indirection that doesn't exist today, invented purely to reinvert itself);
* discard the fact that the committed file **is** the genuine artefact the
  original Technics toolchain produced, byte for byte, which matters for a
  preservation project.

So `table_data_debt.py`'s `verbatim-bmp` class is correctly *distinguished* from
`UNCLASSIFIED` (0 B, unchanged) -- but the debt-inventory prose that reads it as
"the single largest remaining win" pending a generator overstates it. The honest
finding is the opposite: this is the one class of the six FTBMP already needs no
further work, on the tree's own L4 standard.

## A real bug found while auditing, and fixed

`scripts/analysis/extract_include_binaries.py`'s `table_data` dict recorded
FTBMP04's length as `0x09A53` (39,507 B). The committed file is 39,478 B
(`0x09A36`), and `0xA753A + 0x09A36 == 0xB0F70`, exactly FTBMP05's recorded start
offset -- so `0x09A53` was 29 B too many and would have overrun into FTBMP05 had
anyone rerun that script's `dd` recipe against a fresh ROM dump. This never
affected the actual build (the committed `.BMP` file was always right; the byte
gate proves it below) -- it was a stale annotation in a one-shot archaeology
script. Fixed alongside this note.

## Reproducing every number here

    python3 scripts/analysis/verbatim_bmp_header_audit.py     # per-file header audit, this doc's table
    python3 scripts/analysis/table_data_debt.py                # classification, unchanged: verbatim-bmp 318,468 B, UNCLASSIFIED 0 B
    python3 scripts/analysis/table_data_debt.py --selftest      # BM magic + declared-size check on all six, plus the other five round trips

## Gate (narrow, this lane only)

Per the coordinator's instruction, ran only the table_data target in this
worktree, not the full 13-image `gate-all`:

    rm -f rebuilt_ROMs/kn5000_table_data.llvm.*
    make rebuilt_ROMs/kn5000_table_data.llvm.rom
    cmp rebuilt_ROMs/kn5000_table_data.llvm.rom original_ROMs/kn5000_table_data.rom
    # -> BYTE-IDENTICAL (no output from cmp, files match)

No source under `table_data/` was changed by this lane (the only edits are the
one-line fix in `extract_include_binaries.py`, a new audit script, and this
note), so this result should be a no-op re-confirmation of the tree's existing
green state, not new evidence of a fix. The full 13-image `gate-all` is the
coordinator's job to re-run centrally after merge.
