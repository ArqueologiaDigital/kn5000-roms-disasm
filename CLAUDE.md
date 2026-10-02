# CLAUDE.md

> ⚠️ **Beads was decommissioned on 2026-07-27** at the owner's request. `bd` and
> `beads-lite` were removed from the machine — do not run them and do not reinstall
> them. `.beads/issues.jsonl` **stays** and remains this project's task list: read
> it with `jq`/`grep`, write it by editing it directly, publish it with
> `make issues` (which reads the file itself and never invoked `bd`).

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a ROM disassembly project for the Technics KN5000 music keyboard. The goal is to achieve 100% byte-matching reconstruction of the original firmware ROMs, enabling MAME emulation and homebrew development.

**Target CPU:** TMP94C241F (TLCS900 variant)
**Assembler:** Custom LLVM backend (`llvm-mc -triple=tlcs900`) — LLVM assembly is the authoritative source
**Legacy assembler:** Alfred Arnold's ASL Macro Assembler 1.42 Beta (archived in `archive/asl/`)

### Documentation Website

Detailed documentation is at `../technics-docs/`. Key pages:
- **Hardware**: `hardware-architecture.md`, `memory-map.md`, `cpu-subsystem.md`
- **Protocols**: `control-panel-protocol.md`, `inter-cpu-protocol.md`, `boot-sequence.md`
- **Progress**: `rom-reconstruction.md`, `issues.md`, `reverse-engineering.md`
- **Subsystems**: `audio-subsystem.md`, `fdc-subsystem.md`, `hdae5000.md`
- **Data Formats**: `lzss-compression.md` (0x3E0000 address resolved - see [Firmware Update System](../technics-docs/lzss-compression.md#firmware-update-system-and-0x3e0000))

### Analysis Documents

In-repo analysis notes are in `analysis/`. Key documents:
- **[String Analysis](analysis/strings/)** - Extracted strings from ROMs with categorization
  - [Overview](analysis/strings/README.md) - Executive summary (start here)
  - [Quick Reference](analysis/strings/quick-reference.md) - Fast offset lookup
  - [Detailed Analysis](analysis/strings/detailed-analysis.md) - Complete categorized listing

### Issue Tracker

Issues live in `.beads/issues.jsonl` as plain JSON lines, edited by hand (see Issue Tracking section below).

## Build Commands

```bash
# Build all ROMs (LLVM, primary) and run byte comparison
make all

# Full build: both ASL and LLVM (for cross-verification)
make all-full

# Build specific ROM targets
make rebuilt_ROMs/kn5000_v10_program.llvm.rom         # Main CPU
make rebuilt_ROMs/kn5000_subprogram_v142.llvm.rom     # Sub CPU payload
make rebuilt_ROMs/kn5000_subcpu_boot.llvm.rom         # Sub CPU boot
make rebuilt_ROMs/kn5000_table_data.llvm.rom          # Table data
make rebuilt_ROMs/kn5000_custom_data.llvm.rom         # Custom data
make rebuilt_ROMs/hd-ae5000_v2_06i.llvm.rom           # HDAE5000

# Reconvert from archived ASL sources (regenerates .s files from archive/asl/)
make llvm-convert-all

# Clean build artifacts
make clean              # LLVM build artifacts
make clean-all          # All (LLVM + legacy ASL)

# Rebuild preset data (assemble + LZSS compress)
make rebuild-preset-data

# Verify rebuilt ROMs against originals (runs automatically after make all)
python scripts/build/compare_roms.py

# Update documentation website
make gallery            # Convert images to PNG for gallery
make issues             # Export issue tracker to website
make rom-status         # Generate ROM status diagram
make website            # All of the above (gallery + issues + rom-status)
```

### Assembly Source Organization
- **LLVM assembly** (authoritative, in `*/` directories): `.s` files using LLVM/GNU syntax for TLCS-900
  - `maincpu/kn5000_v10_program.s` + 30 modular includes (shared/, file_io/)
  - `subcpu/kn5000_subprogram_v142.s`, `subcpu/boot/kn5000_subcpu_boot.s`
  - `hdae5000/hd-ae5000_v2_06i.s`, `table_data/kn5000_table_data.s` + shared includes
  - `custom_data/kn5000_custom_data.s`
- **ASL sources** (archived in `archive/asl/`): Original ASL syntax, used by `scripts/converters/asl_to_llvm.py`
- **Build pipeline**: `llvm-mc -triple=tlcs900` → `ld.lld` → `llvm-objcopy` → raw binary
- **Binary data files**: `*/includes/*.bin`, `*/images/*.bin` — referenced via `.incbin`

## Project Policies

### LLVM Toolchain Provenance Tracking (STRICT POLICY)

Every commit to this repository must include in its commit message:
`LLVM: <branch>@<short-hash> (<full-hash>)`

This records the exact LLVM source (`llvm-mc`, `ld.lld`, `clang`, `llvm-objcopy`) used for the build. Obtain via:
`cd /home/fsanches/compartilhado/llvm-project && git log -1 --format="%D @ %h (%H)"`

The `TOOLCHAIN_VERSION` file records the current build. Update it when the toolchain is rebuilt from a different commit.

**LLVM history is immutable after use.** Once an LLVM commit has produced verified ROM artifacts, no `--amend`, `rebase`, or `--force` push may destroy it. Further changes must be new commits.

### Clean Working Directory (STRICT POLICY)

**Keep the working directory as clean as possible at all times.**

All files must be either:
1. **Committed** to version control, or
2. **Listed in `.gitignore`**

After any work session, `git status` should show a clean working tree. This ensures:
- No accidental loss of work
- Clear visibility of actual changes
- Consistent state across sessions

**When creating new files:**
- Commit valuable files immediately
- Add build artifacts/temp files to `.gitignore`
- Delete files that serve no ongoing purpose

### Helper Scripts (STRICT POLICY)

**All helper scripts must be placed in the `scripts/` directory (in the appropriate subdirectory) and committed to the repo.**

The `scripts/` directory is organized into subdirectories:
- `scripts/build/` — Build utilities (compare_roms.py, compress_lzss.py, convert_images.py, etc.)
- `scripts/converters/` — Format converters (asl_to_llvm.py, convert_*.py, naka_to_c.py, transform_*.py)
- `scripts/generators/` — Code generators (generate_*.py, gen_*.py, create_*.py)
- `scripts/renaming/` — Label renaming scripts (rename_*.py)
- `scripts/analysis/` — Analysis & extraction (extract_*.py, audit_*.py, disassemble_*.py, sync_docs_labels.py)
- `scripts/tools/` — Standalone utilities (cleanup, formatting, fixups, splitting, annotation)

This ensures:
- Scripts are version-controlled and available to all contributors
- Consistent location for automation tools
- Easy discovery of available utilities

When creating new scripts, place them in the appropriate `scripts/` subdirectory and add them to git immediately.

### Symbol Reference Files (STRICT POLICY)

**The symbol reference files MUST be kept in sync with the source code at all times.**

Symbol reference files in `symbols/` provide address-to-name mappings for external tools:

| File | ROM | Symbols | Address Range |
|------|-----|---------|---------------|
| `symbols/maincpu_symbols_reference.txt` | Main CPU **v10** (identical to `maincpu_v10_...`) | 47,836 | 0xE00000 - 0xFFFFE8 |
| `symbols/maincpu_v9_symbols_reference.txt` | Main CPU v9 | 47,830 | 0xE00000 - 0xFFFFE8 |
| `symbols/maincpu_v7_symbols_reference.txt` | Main CPU v7 | 47,920 | 0xE00000 - 0xFFFFE8 |
| `symbols/subcpu_symbols_reference.txt` | Sub CPU payload v1.42 | 5,560 | 0x000400 - 0x03EE75 |
| `symbols/subcpu_boot_symbols_reference.txt` | Sub CPU boot | 201 | 0xFF8000 - 0x1000000 (last row is the linker `end` marker) |
| `symbols/table_data_symbols_reference.txt` | Table data | 4,759 | 0x800000 - 0x9FFEF0 |
| `symbols/hdae5000_symbols_reference.txt` | HDAE5000 expansion | 3,932 | 0x280000 - 0x300000 |

**In sync as of 2026-09-25** (after the Wave 2 merges): regenerated from each
image's linked ELF by `python3 scripts/analysis/l2_symbol_reference.py --regen`,
and `python3 scripts/analysis/l2_symbol_reference.py --check` reports 100 %
NAME+ADDRESS agreement for all eight files. **Use that script to regenerate** --
it knows the per-version maincpu split (v7/v9/v10 are separate links; a v7
address looked up in the v10 file is wrong) and writes the header block itself.
The hand recipe below is kept for reference. Rows are `NAME 00ADDRESS` (8 hex
digits, no `0x`). Before regenerating, grep the prose that quotes names
(listed at the end of this section) -- on 2026-09-25 one name had moved
(`OFFSETS_F460` -> `AudioTick_CaseOffsets`, kn7000_mame notes fixed in 3707804).

**Format:**
```
# Symbol Reference File
# Format: SYMBOL_NAME ADDRESS
SYMBOL_NAME 0xADDRESS
```

**Update procedure - regenerate from the linked ELF:**

The authoritative names live in the LLVM sources (`v10/maincpu/*.s` and friends,
see commit `38e7d9f` "Promote LLVM assembly to authoritative source, archive
ASL") and reach the linked ELF with their exact case. Regenerating from that ELF
takes about a second on an already-built tree, so there is no reason to hand-edit
these files:

```bash
make rebuilt_ROMs/kn5000_v10_program.llvm.elf
NM="$HOME/compartilhado/llvm-project/build/bin/llvm-nm"
{  echo "# Symbol Reference File"
   echo "# Format: SYMBOL_NAME ADDRESS"
   "$NM" --defined-only rebuilt_ROMs/kn5000_v10_program.llvm.elf \
     | awk '$2=="t"{print $1, $3}'                               \
     | LC_ALL=C sort -k1,1 -k2,2                                 \
     | awk '{printf "%s 0x%s\n", $2, toupper(substr($1,3))}'
} > symbols/maincpu_symbols_reference.txt
```

Verified 2026-08-21 against `rebuilt_ROMs/kn5000_v10_program.llvm.elf`, whose
`.llvm.rom` is byte-identical to `original_ROMs/kn5000_v10_program.rom`:

- `llvm-nm` splits the table cleanly into 39,393 `t` (`.text`, the ROM symbols)
  and 1,153 `a` (absolute `.equ` constants defined in the LLVM sources - SFR
  addresses, VGA and event codes and the like, largest single source
  `v10/maincpu/shared/sfr_tmp94c241.s`). Those are values, not ROM `.text`
  addresses, so filtering on `t` is what drops them.
- `substr($1,3)` strips the leading `00` of llvm-nm's 8-digit address. **This is
  only safe once you have checked the address range.** Every maincpu `.text`
  address is in `0x00E00000-0x00FFFFFF`, so it is lossless there; but
  `kn5000_subcpu_boot.llvm.elf` also defines a linker `end` marker at
  `0x01000000`, which the same truncation would silently rewrite as `0x000000`.
  Filter that out before reusing this recipe for subcpu_boot.
- addresses are fixed-width hex, so `LC_ALL=C` lexicographic sort *is* numeric
  sort; the output was checked strictly non-decreasing over all 39,393 rows, and
  every row matches `^NAME 0x[0-9A-F]{6}$`.
- `rebuilt_ROMs/` is `.gitignore`d, so the ELF must be built first.
- the redirect **overwrites the whole file**, including the "STALE AS OF" header
  block now at the top of `symbols/maincpu_symbols_reference.txt`. Re-apply that
  block by hand after regenerating, or drop it deliberately.

The same shape works for the other four files against their own ELFs
(`kn5000_subprogram_v142`, `kn5000_subcpu_boot`, `kn5000_table_data`,
`hd-ae5000_v2_06i`; all eight `.llvm.elf` artifacts are produced by a build),
subject to the `substr` caveat above.

**Do NOT regenerate from an ASL map.** The old recipe assembled
`archive/asl/maincpu/kn5000_v10_program.asm` with `-g map` and ran
`scripts/analysis/extract_symbols_from_map.py`. Two things make that wrong now:

1. That `.asm` is the **archived pre-rename tree**: 35,786 of its 37,402
   column-0 label definitions are still `LABEL_*` (a floor - that count does not
   follow the file's 31 `include` directives). Regenerating from it reintroduces
   the staleness it is meant to cure.
2. `[INFERENCE]` ASL appears to be case-insensitive here - no `CASESENSITIVE`
   directive exists anywhere under `archive/asl/` - so its map should uppercase
   every symbol. Nobody has re-run ASL to confirm that, but the symbols file
   does carry 2,062 same-address case twins, e.g. `ACACCORDIONTABPROC` where
   both the LLVM source and the ELF say `AcAccordionTabProc`.

The old recipe's cleanup line also removed `maincpu/*.map`, a directory deleted
by `3d87c95` (2026-03-23) when the tree moved to `v10/maincpu/`.

**Nothing in the build reads these files** - `symbols/` appears 0 times in the
Makefile and `extract_symbols_from_map.py` is unreferenced by it - so
regenerating cannot change a ROM byte. It *will* invalidate names quoted in
prose: `docs/accompaniment-style-reader.md` (13 such names) and, in the
`kn7000_mame` repo, `notes/kn5000-envelope-engine.md` (6),
`notes/FINDINGS-sound-name-error.md` (2) and
`notes/HANDOFF-kn5000-demo-playback.md` (addresses only). Fix those in the same
commit.

**This policy exists because** external tools (debuggers, analysis scripts, MAME integration) depend on accurate symbol mappings. Stale symbol files cause confusion and break tooling.

### Image Extraction and Gallery Updates

When new images are discovered and extracted as `.bin` files in `maincpu/images/` or `table_data/images/`:

1. **Add metadata** to `scripts/build/convert_images.py` in the `IMAGE_METADATA` dictionary:
   - Filename
   - Dimensions (width, height)
   - Bit depth (1, 4, or 8)
   - Description

2. **Run the gallery conversion**:
   ```bash
   make gallery
   ```

3. **Update the image gallery** page at `../technics-docs/image-gallery.md` with the new images

4. **Commit both repositories** (roms-disasm and docs) together

This ensures the documentation website always reflects the latest extracted images.

### Event Code Freshness (STRICT POLICY)

**When new firmware event codes are discovered or existing codes are better understood, ALL of the following must be updated:**

1. **Assembly source** -- Add/update `EVT_*` `.equ` constants in each tree's `shared/event_codes.s` (`v10/maincpu`, `v9/maincpu`, `v7/maincpu`, `hdae5000`), named after the firmware's own `EV_*`/`MT_*` name tables (catalog: `notes/event-codes-2026-10-02/`; apply with `scripts/tools/apply_event_constants.py`); replace raw hex values with symbolic names (e.g., `EVT_PARA_DRAW`)
2. **Event codes reference page** -- Update `../technics-docs/event-codes.md` with new codes, dispatch paths, and descriptions
3. **HDAE5000 homebrew page** -- Update `../technics-docs/hdae5000-homebrew.md` if the discovery affects handler registration or activation flow
4. **Mines project** -- Update `../../Mines/CLAUDE.md` if applicable

**This policy exists because** event codes are the primary interface between the firmware and extension ROMs. Inconsistent documentation across the disassembly, website, and homebrew project causes confusion. The canonical event code reference is `../technics-docs/event-codes.md`.

### Website Synchronization

The documentation website at `../technics-docs/` must be kept in sync with project progress. **Run these commands regularly:**

```bash
make website   # Updates gallery, issues, and ROM status diagram
```

This runs:
1. `make gallery` - Converts extracted images to PNG
2. `make issues` - Exports Beads issue tracker to `issues.md`
3. `make rom-status` - Regenerates the ROM status visualization diagram

**When to update the website:**
- After extracting new images
- After closing or creating issues
- After significant reverse engineering discoveries
- Before committing major changes

Always commit both repositories together when making website updates.

### ROM Status Diagram (STRICT POLICY)

**The ROM status diagram must be kept in sync with disassembly progress.**

The file `scripts/build/generate_rom_status_diagram.py` generates an SVG visualization showing the disassembly status of each ROM component. This diagram provides an at-a-glance view of project progress.

**Status categories:**
| Color | Category | Description |
|-------|----------|-------------|
| Green | Disassembled Code | Properly disassembled with symbolic instructions |
| Blue | Known Data | Documented data structures |
| Cyan | String Data | Text strings |
| Light Green | Pointer/Jump Tables | Tables of addresses |
| Purple | Binary Includes | External binary files not yet analyzed |
| Red | Raw Bytes (unknown) | Hex bytes with unknown purpose |
| Orange | Raw Bytes (known code) | Code not yet disassembled |
| Gray | Padding/Unused | Fill bytes (0x00 or 0xFF) |
| Yellow | Undetermined | Not yet categorized |

**Regeneration triggers:**
- After disassembling new code sections
- After documenting data structures
- After splitting binary includes
- Before any major commit

**Commands:**
```bash
make rom-status  # Regenerate the diagram
make website     # Regenerate all website content
```

The diagram is displayed on the documentation website at `/rom-reconstruction/`. See `../technics-docs/rom-reconstruction.md` for detailed progress tracking.

### Symbol Name Synchronization (STRICT POLICY)

**When updating documentation, ALL symbol names must match the current assembly source.**

This is a strict policy to prevent documentation from becoming outdated as symbols are renamed during reverse engineering:

1. **Before committing documentation changes**, verify that all symbol names mentioned exist in the assembly:
   ```bash
   # Search for a symbol in the assembly
   grep -n "SYMBOL_NAME" maincpu/kn5000_v10_program.s
   ```

2. **When renaming symbols in assembly**, search documentation for the old name:
   ```bash
   # Find all references in documentation
   grep -rn "OLD_SYMBOL_NAME" ../technics-docs/ maincpu/ subcpu/ table_data/ hdae5000/
   ```

3. **Common symbol categories to check:**
   - Jump tables: `*_TABLE`, `*_HANDLERS`
   - Routines: `CPanel_*`, `FDC_*`, `MIDI_*`, etc.
   - Variables: `CPANEL_*`, `ENCODER_*`, `MIDI_CC_*`
   - Addresses referenced in Code Reference sections

4. **Symbol name format consistency:**
   - Assembly uses: `CPanel_RX_PacketHandlers`, `CPANEL_STATE_MACHINE_TABLE`
   - Documentation must use exact same names in backticks: `` `CPanel_RX_PacketHandlers` ``

5. **When in doubt**, grep the assembly for the address to find the current label:
   ```bash
   grep "FC4489\|0xFC4489" maincpu/*.s  # Find label at address 0xFC4489
   ```

**This policy exists because stale symbol names in documentation cause confusion and make it harder for contributors to navigate between docs and source code.**

### Issue Tracking (STRICT POLICY)

Project issues live in `.beads/issues.jsonl` — one JSON object per line, no tracker
tool. Beads was decommissioned on 2026-07-27; edit the file directly.

### Issue Closure Requirements (MANDATORY)

**Before closing ANY issue, you MUST complete ALL of the following steps:**

1. **Website Documentation Update**: Update the relevant pages in `../technics-docs/` with detailed findings:
   - Add new sections with specific technical details discovered
   - Include code addresses, register values, and protocol specifics
   - Document data structures with byte-level precision
   - Add diagrams or tables where helpful

2. **Exhaustive Investigation**: Make every effort to extract ALL available information:
   - Search the codebase thoroughly for related routines
   - Cross-reference with other documentation (service manual, datasheets)
   - Document related findings even if not strictly required by the issue title
   - Look for patterns that connect to other open issues

3. **Closure Comment Quality**: The closing comment must include:
   - Summary of what was discovered
   - Links to website pages that were updated
   - Any caveats or limitations of the findings
   - References to related issues that may benefit

4. **Re-opening Policy**: If ANY of the following are true, do NOT close the issue:
   - Website documentation was not updated with findings
   - More details could potentially be discovered with additional effort
   - Related questions remain unanswered
   - The investigation was incomplete due to time or context constraints

**When in doubt, add a detailed comment and leave the issue OPEN for future work.**

This policy exists because the primary goal is building comprehensive documentation for MAME emulation and homebrew development. Closing issues prematurely loses institutional knowledge and creates incomplete documentation.

```bash
# Read (plain JSON lines — no tool required):
jq -r 'select(.status!="closed") | "\(.id)  p\(.priority)  \(.title)"' .beads/issues.jsonl
jq 'select(.id=="<issue-id>")' .beads/issues.jsonl   # one issue, with comments
grep -i '<term>' .beads/issues.jsonl                  # text search

# Writes (create / close / reopen / comments / notes): edit .beads/issues.jsonl
# by hand, then:
git add .beads/issues.jsonl
git commit -m "issues: <what changed>"
```

**Do NOT run `bd` or `beads-lite`** — both were removed on 2026-07-27 when beads was
decommissioned. Do not reinstall them or introduce a replacement tracker without
asking. The archived issues are at
`/home/fsanches/compartilhado/beads-decommission-2026-07-27/`.

The task list is:
- Versioned via `.beads/issues.jsonl` in git (single source of truth)
- Exported to the website via `make issues` (reads JSONL directly)
- Visible at `/issues/` on the documentation site

**Quick access:** read `.beads/issues.jsonl`, or see `../technics-docs/issues.md` for the web version.

### Disassembly Quality Standards (MANDATORY)

**Always prefer disassembled code over raw bytes.** This is a strict policy:

1. **Disassembled code is always preferred** - Named labels, proper instructions, and comments provide understanding and maintainability. Raw `db` byte sequences should only be used as a last resort for truly undeciphered data.

2. **When fixing ROM divergences:**
   - Keep existing disassembled routines intact
   - Use raw bytes ONLY to fill gaps between known routines
   - Never replace disassembled code with raw bytes just to achieve byte-matching
   - If raw bytes are needed, clearly document the address range and mark as "TODO: disassemble"

3. **Address boundaries must be calculated precisely:**
   - Raw byte segments should end exactly where disassembled routines begin
   - Use `org` directives for disassembled routines at known addresses
   - Document any gaps that need raw bytes to maintain alignment

4. **Goal hierarchy:**
   - First priority: Correct, understandable disassembly
   - Second priority: Byte-accurate ROM reconstruction
   - Never sacrifice readability for byte-matching

This policy ensures the disassembly remains useful for understanding the firmware, not just rebuilding it.

### Label+Include Compaction & Visual Alignment (STRICT POLICY)

**When a label's only content is a single `.include` or `.incbin` directive, the label and directive MUST be on the same line.** Consecutive such entries MUST have no blank lines between them and MUST be tab-aligned to a common column.

```asm
; WRONG - separate lines, blank-line spacing, ragged alignment
Bitmap_1bit_Flash_Memory_Update:	; e0018e
	.incbin "images/Bitmap_1bit_Flash_Memory_Update.bin"

Bitmap_1bit_Now_Erasing:	; e003f6
	.incbin "images/Bitmap_1bit_Now_Erasing.bin"

; CORRECT - same line, no spacing, aligned columns
Bitmap_1bit_Flash_Memory_Update:	.incbin "images/Bitmap_1bit_Flash_Memory_Update.bin"
Bitmap_1bit_Now_Erasing:		.incbin "images/Bitmap_1bit_Now_Erasing.bin"
```

This same visual alignment rule applies to all table-like blocks:

- **Include/incbin blocks:** Labels and directives aligned to the same column
- **Pointer tables:** Labels and `.long` targets aligned
- **Data tables:** Parallel `.byte`/`.short`/`.ascii` entries with comments aligned
- **Dispatch tables:** Handler labels and jump targets aligned

Use tabs (not spaces) to reach the alignment column. The column should be the next tab stop after the longest label in the block.

Apply this whenever editing or creating table-like blocks of assembly. When touching existing unaligned blocks, align them as part of the change.

### No Inline Address Comments (STRICT POLICY)

**Do NOT add address comments like `; e0018e` or `; E023F0` to labels or lines.** These are redundant — addresses are available from the ELF output (`llvm-objdump -d`) and the linker map. Inline address comments add noise and become stale when code moves.

### Comment Quality (STRICT POLICY)

**Do NOT write comments that merely restate the label name.** Comments must add information beyond what the label already conveys. If a label is self-explanatory, omit the comment entirely.

```asm
; WRONG - restates the label
MSP_Default_ReverbLevel:	.byte 128	; reverb send level

; CORRECT - no comment needed, label is clear
MSP_Default_ReverbLevel:	.byte 128

; CORRECT - adds info not in the label
MSP_Default_PanPosition1:	.byte 96, 0	; slightly right of center
```

### Best Notation for Values (STRICT POLICY)

**Use the most readable numeric notation for each value's domain:**

- **Decimal** for counts, levels, indices, offsets, and human-meaningful ranges (volume 0-99, MIDI 0-127, part counts, tempo).
- **Hexadecimal** for bitmasks, flags, hardware registers, signatures, and bit-pattern data (0x80, 0xff, 0x48).

```asm
; WRONG - hex for a count
MSP_Default_NumParts:		.byte 0x14, 0x00

; CORRECT - decimal for a count
MSP_Default_NumParts:		.byte 20, 0
```

### String Literals in Disassembly (STRICT POLICY)

**When data is clearly readable text, it MUST be represented as a string literal, not raw bytes.**

This is a strict policy to maximize readability and facilitate understanding of the firmware:

1. **Always use string literals for text:**
   ```asm
   ; WRONG - raw bytes for ASCII text
   db 058h, 041h, 050h, 052h, 034h  ; "XAPR4"

   ; CORRECT - string literal
   db "XAPR4"
   ```

2. **Detection criteria for strings:**
   - Sequences of printable ASCII characters (0x20-0x7E)
   - Null-terminated sequences
   - Known header signatures (e.g., "XAPR", "MIDI", "WAVE")
   - Error messages, menu text, file names, version strings

3. **Mixed data handling:**
   ```asm
   ; When string is followed by non-printable data:
   db "ERROR", 0x00, 0x01, 0x02

   ; When string contains special characters, escape or split:
   db "Line1", 0x0D, 0x0A, "Line2"  ; CR+LF between strings
   ```

4. **Documentation requirement:**
   - Add comments explaining the purpose of the string when known
   - Note encoding if non-ASCII (e.g., Shift-JIS for Japanese text)

5. **Benefits:**
   - Immediately reveals firmware functionality
   - Error messages help identify code purpose
   - Version strings aid in ROM identification
   - Menu text maps UI to code routines

**This policy applies to all ROM components:** maincpu, subcpu, table_data, and expansion ROMs like HDAE5000.

### String Alignment Padding (IMPORTANT)

**Null-terminated strings sometimes have an additional 0xFF padding byte for 16-bit alignment.**

This is an observed pattern in the KN5000 firmware:

1. **Alignment requirement:** When strings are part of pointer tables, they may need to start at even addresses for 16-bit memory access efficiency.

2. **Padding byte format:**
   ```asm
   ; String with 0xFF padding for alignment
   db "ATTENTION!", 000h, 0FFh    ; 12 bytes total (11 + padding)

   ; String without padding (already aligned)
   db "ACHTUNG !", 000h           ; 10 bytes total
   ```

3. **When to use padding:**
   - Check the original ROM bytes to determine if padding exists
   - Labels like `LABEL_E1E4D0` imply the data must be at address 0xE1E4D0
   - Calculate byte distances between consecutive labels to determine required padding
   - If `next_label_addr - current_label_addr` doesn't match your string length, add 0xFF padding

4. **Verification method:**
   ```bash
   # Extract original ROM bytes at a label's address
   xxd -s $((0xE1E4D0 - 0xE00000)) -l 64 original_ROMs/kn5000_v10_program.rom
   ```

5. **Common pattern:** Multilingual string tables often have this structure where some strings need padding and others don't, depending on the natural length of each translation.

### Symbolic Cross-Referencing (STRICT POLICY)

**All cross-references must be symbolic (using labels), never numeric addresses.**

This is a strict policy to ensure the disassembly is maintainable and understandable:

1. **Never use hardcoded addresses in code references:**
   ```asm
   ; WRONG - numeric address
   CALL 0F97544h
   LDA XIX, 0E46312h
   LD XWA, (0FC3E65h)

   ; CORRECT - symbolic label
   CALL FDC_DRIVE_DETECT
   LDA XIX, FONT_METRICS_TABLE
   LD XWA, (DYNAMIC_HANDLER_PTR)
   ```

2. **Meaningful names are STRONGLY preferred:**
   - Labels should describe the purpose of the code or data
   - Use descriptive names based on analysis: `FDC_SEND_COMMAND`, `LED_CONTROL_DISPATCH`, `MIDI_EVENT_HANDLER`
   - Use domain-specific prefixes: `FDC_`, `UI_`, `MIDI_`, `HDAE_`, `DMA_`, etc.

3. **Address-based labels (LABEL_XXXXXX) are a LAST RESORT:**
   - Only use `LABEL_E04FB9` style names when there is **absolutely no understanding** of the semantic purpose
   - These labels indicate "needs analysis" - they are placeholders, not final names
   - When you discover what a `LABEL_*` does, rename it immediately

4. **When encountering numeric addresses in existing code:**
   - Create a label at that address (even if just `LABEL_XXXXXX` initially)
   - Update the reference to use the label
   - Add a TODO comment if the purpose is unknown: `; TODO: identify purpose`

5. **Label naming conventions:**
   ```
   Routines:     VerbNoun format - SendCommand, InitHardware, HandleEvent
   Data tables:  NOUN_TABLE format - FONT_METRICS_TABLE, JUMP_HANDLER_TABLE
   Constants:    NOUN format - SYSTEM_TIMESTAMP, FDC_STATUS_PORT
   Flags:        NOUN_FLAG format - PAYLOAD_LOADED_FLAG, DMA_XFER_STATE
   Buffers:      NOUN_BUFFER format - CMD_DATA_BUFFER, DMA_SETUP_PARAMS
   ```

6. **Subsystem prefix conventions:**

   These prefixes are established in the codebase. Use them when naming new symbols:

   **Main CPU (maincpu/):**

   | Prefix | Subsystem | Example |
   |--------|-----------|---------|
   | `Audio_` | Audio subsystem (locks, DMA, commands) | `Audio_Lock_Acquire`, `Audio_DMA_Transfer` |
   | `AudioCmd_` | Audio command formatting | `AudioCmd_NoteOn`, `AudioCmd_ProgramChange` |
   | `AudioInit_` | Audio initialization | `AudioInit_ResetChannels` |
   | `Acc_` / `AccPedal_` / `AccVoice_` | Auto-accompaniment | `AccPedal_SustainHandler` |
   | `BitMapOut_` | Bitmap rendering | `BitMapOut_DrawRegion` |
   | `CPanel_` | Control panel protocol | `CPanel_ReadButtons` |
   | `Display_` | Display/video routines | `Display_ClearScreen` |
   | `DSPCfg_` | DSP configuration | `DSPCfg_SetReverb` |
   | `Encoder_` | Rotary encoder handling | `Encoder_ReadDelta` |
   | `FDC_` | Floppy disk controller | `FDC_ReadSectors`, `FDC_HANDLER_OFFSETS` |
   | `FileIO_` | File I/O operations | `FileIO_OpenFile` |
   | `InterCPU_` | Inter-CPU communication | `InterCPU_Send_Data_Block` |
   | `MIDI_` | MIDI processing | `MIDI_SendSysExCmd`, `MIDI_RX_BYTE_DISPATCHER` |
   | `MidiPkt_` | MIDI packet handling | `MidiPkt_Nop` |
   | `MT_` | MIDI transport | `MT_StartPlay` |
   | `Rhythm_` | Rhythm/style patterns | `Rhythm_LoadPattern` |
   | `Scoop_` | Scoop event system | `Scoop_EventLoop` |
   | `SeMenu_` | Sound editor menu | `SeMenu_DrawPage` |
   | `Seq_` / `SeqStep_` / `SeqPart_` / `SeqPlay_` | Sequencer | `Seq_WriteMidi90` |
   | `SMF_` | Standard MIDI File | `SMF_ParseHeader` |
   | `SndParam_` | Sound parameters | `SndParam_SetVolume` |
   | `SubCPU_` | Sub CPU management | `SubCPU_Send_Payload` |
   | `SysEx_` | SysEx message handling | `SysEx_ValidateRolandHeader` |
   | `TaskSched_` | Task scheduler | `TaskSched_Dispatch` |
   | `ToneGen_` | Tone generator (keyboard input) | `ToneGen_KeyEvent` |
   | `UI_` / `Widget_` | UI framework | `UI_STATE_MACHINE_TABLE` |

   **Sub CPU (subcpu/):**

   | Prefix | Subsystem | Example |
   |--------|-----------|---------|
   | `Voice_` | Voice parameter manipulation | `Voice_NoteOn`, `Voice_CtrlChange` |
   | `DSP_` / `DSP2_` | DSP hardware control | `DSP_WriteRegister` |
   | `EFF_` | Effects processing | `EFF_SetReverbDepth` |
   | `FP_` | Fixed-point math | `FP_Multiply` |
   | `InterCPU_` | Inter-CPU communication | `InterCPU_Latch_Setup` |
   | `MIDI_` | MIDI dispatch | `MIDI_Dispatch` |
   | `RingBuf_` | Ring buffer operations | `RingBuf_Write` |
   | `Serial1_` | Serial port 1 (MIDI TX) | `Serial1_DataTransmit_Loop` |
   | `ToneGen_` | Tone generator | `ToneGen_Init` |
   | `VoiceSlot_` / `VoiceParam_` | Voice slot management | `VoiceSlot_Allocate` |

   **Data labels:**

   | Prefix | Type | Example |
   |--------|------|---------|
   | `Bitmap_` / `BitmapOut_` | Image data | `Bitmap_Technics_Logo` |
   | `Str_` / `FuncName_` | String constants | `Str_Mixer_ON` |
   | `IconName_` / `IconBitmapName_` | Icon metadata | `IconName_Piano` |
   | `SOUND_DATA_` / `SOUND_CATEGORY_` | Sound category data | `SOUND_DATA_PIANO` |
   | `Brass_PatchEntry_` / `WorldPerc_PatchEntry_` | Patch entries | `Brass_PatchEntry_084` |
   | `WidgetPropStr_` | Widget property strings | `WidgetPropStr_Volume` |
   | `HANDLE_UPDATE_` | Firmware update handlers | `HANDLE_UPDATE_OFFSETS` |
   | `FILETYPE_SIG_` | File type signatures | `FILETYPE_SIG_PROGRAM_1` |

7. **Benefits of symbolic references:**
   - Code is self-documenting
   - Renaming propagates automatically
   - Cross-reference analysis tools work correctly
   - Easier to understand control flow and data dependencies
   - Facilitates collaborative reverse engineering

**This policy applies to ALL references:** CALL, JP, JR, LD, LDA, and any other instruction that references a memory address.

### Proactive Semantic Renaming (STRICT POLICY)

**Whenever Claude discusses a routine, data structure, or label using an address-based placeholder name (e.g., `LABEL_037D6E`), Claude MUST rename it to a meaningful semantic label in the disassembly source code.**

1. **Trigger:** Any time Claude identifies the purpose of a routine or data structure during investigation or discussion, it must immediately rename the label in the assembly source.
2. **No address-based names in conversation:** If Claude can explain what something does, it can name it. `LABEL_037D6E` described as "DSP state dispatcher" should become `DSP_State_Dispatcher` in the source.
3. **Batch renaming is acceptable:** When investigating a subsystem, collect all discovered names and rename them together, then verify the build.
4. **Verification required:** After renaming, follow the Assembly Edit Verification policy (build + compare_roms.py).
5. **Symbol reference files:** Update the corresponding symbol reference file when renaming labels (see Symbol Reference Files policy).

### Sed-Based Assembly Symbol Renaming (STRICT POLICY)

**When renaming symbols in assembly source files, ALWAYS write a sed script first and then run it.** Never use interactive editing tools (Edit tool) for batch symbol renames, as large files can hang the system.

1. **Procedure:** Write a `scripts/renaming/rename_<topic>.sed` file with all `s/OLD_NAME/NEW_NAME/g` rules, then run: `sed -i -f scripts/renaming/rename_<topic>.sed <assembly_file>`
2. **Scope:** Apply the sed script to all files that reference the symbols (assembly, symbol reference files, etc.)
3. **Verification:** After running, follow Assembly Edit Verification policy (build + compare_roms.py)
4. **Cleanup:** The sed script may be deleted after successful commit, or kept for reference

### Inter-ROM Cross-References (STRICT POLICY)

**When code references an address outside its own ROM's memory range, the target ROM's assembly file must be inspected for cross-reference labels.**

This is a strict policy to maintain consistency across all ROM components and ensure complete understanding of inter-component communication:

1. **Memory ranges for each ROM component:** See `../technics-docs/memory-map.md` for complete address ranges.

2. **When an address falls outside the current ROM's range:**
   - Identify which ROM component owns that address
   - Search that component's assembly file for existing labels at that address
   - If a label exists, reference it (may require `EXTERN` declaration or cross-file include)
   - If no label exists, create one in the target file and document the cross-reference

3. **Common cross-reference scenarios:**
   ```asm
   ; HDAE5000 calling maincpu routine:
   CALL 0xE12345        ; -> Should reference maincpu label

   ; Maincpu loading HDAE5000 data:
   LDA XIX, 0x2A898E    ; -> Should reference HDAE5000 label (e.g., HDAE5000_Logo)

   ; Any ROM accessing shared RAM:
   LD XWA, (0x23A1A2)   ; -> Should have consistent label across all ROMs
   ```

4. **Documentation requirement:**
   - Add comments noting cross-ROM references: `; Cross-ref: maincpu/kn5000_v10_program.asm`
   - Document the purpose of the call/reference if known
   - Update both assembly files to maintain bidirectional awareness

5. **Benefits:**
   - Complete picture of inter-component communication
   - Easier to trace execution flow across ROM boundaries
   - Identifies shared data structures and protocols
   - Essential for accurate MAME emulation

**This policy applies to all assembly files:** maincpu, subcpu, hdae5000, table_data, and any future ROM components.

### Exploratory Disassembly (MANDATORY)

**Goal: Eliminate all undocumented raw bytes from ROM source files.**

All ROM files must undergo thorough exploratory disassembly until every byte is either:
1. **Disassembled code** with meaningful labels and comments
2. **Documented data** (images, lookup tables, sound data, etc.) with clear descriptions
3. **Known padding/alignment** bytes explicitly marked as such

**Systematic exploration procedure:**

1. **Find jump tables** by searching for:
   - Indirect calls: `CALL T, XHL`, `CALL T, XIX`, etc.
   - Indexed jumps: `JP T, XIX + WA`, `JP T, XIX + BC`, `JP T, XIX + DE`
   - Tables of addresses (`dd LABEL_*`) or offsets (`dw offset`)
   - Raw address loads before indirect jumps (`LDA XIX, 0E*h` / `LDA XHL, 0F*h`)

2. **Trace all jump table targets** to ensure referenced routines are disassembled

3. **Document binary includes** - all `binclude` files must have:
   - Clear description of data type (image, lookup table, sound, etc.)
   - Dimensions/format if applicable
   - Purpose in the firmware

4. **Create issues** for each undocumented block found:
   - Address range
   - How it was discovered (which jump table references it, etc.)
   - Priority based on importance for emulation

5. **Repeat on all ROM components** (maincpu, subcpu, subcpu_boot, table_data)

This procedure should be run periodically until 100% documentation is achieved.

### Systematic Jump/Call Table Documentation (STRICT POLICY)

**All call-tables and jump-tables must be systematically detected, documented, and their targets fully disassembled. This process must iterate until no undocumented tables or undisassembled referenced code remains.**

This is a strict, iterative policy:

1. **Detection phase:** Find all jump tables and call tables in the ROM:
   - Search for `.long LABEL_*` clusters (address tables)
   - Search for indirect calls/jumps: `CALL T, XHL`, `JP T, XIX + WA`, etc.
   - Search for offset tables used with base addresses
   - Search for switch-case dispatch patterns

2. **Documentation phase:** For each table found:
   - Give the table a meaningful semantic name (not `LABEL_XXXXXX`)
   - Add a header comment explaining what the table dispatches
   - Document the number of entries and what triggers each entry

3. **Target disassembly phase:** For each entry in each table:
   - Verify the target routine is fully disassembled (not raw bytes)
   - Give each target routine a meaningful semantic label
   - Add header comments documenting the routine's purpose
   - Analyze register usage, control flow, and called functions

4. **Iteration phase:** After disassembling all targets:
   - Check if newly disassembled code contains MORE jump/call tables
   - If yes, repeat from step 1 for the newly discovered tables
   - Continue until no new tables are found and all referenced code is documented

5. **Completion criteria:** The process is complete when:
   - Every jump/call table has a semantic name and header comment
   - Every target routine referenced by any table is fully disassembled
   - Every target routine has a semantic label and header comment
   - No newly disassembled code reveals additional undocumented tables

**This policy exists because** jump tables are the primary dispatch mechanism in the firmware. Undocumented tables and their targets represent significant gaps in firmware understanding. Systematic coverage ensures complete reverse engineering.

### Binary Include Splitting (MANDATORY)

**When disassembled code references an address inside a binary include, the binary must be split.**

This ensures:
- Cross-references are symbolic (label-based) rather than numeric (hardcoded addresses)
- Binary files become smaller and easier to analyze
- Data structure boundaries are explicitly marked

**When to split:**

If code references an address that lies **inside** a `binclude` file's address range (but NOT the first address), the binary must be split at that reference point.

**Example:** If `data.bin` covers addresses 0xE02510-0xE06BAF and code references 0xE04000:
- The reference is inside the range but not at the start
- Split required at 0xE04000

**Splitting procedure:**

1. **Identify the split point** from the code reference address

2. **Calculate byte offsets:**
   - Part 1: From original start to (split_address - 1)
   - Part 2: From split_address to original end

3. **Extract the two parts:**
   ```bash
   # Calculate sizes
   SPLIT_OFFSET=$((split_address - original_start))
   PART1_SIZE=$SPLIT_OFFSET
   PART2_SIZE=$((original_size - SPLIT_OFFSET))

   # Extract parts
   dd if=original.bin of=part1.bin bs=1 count=$PART1_SIZE
   dd if=original.bin of=part2.bin bs=1 skip=$SPLIT_OFFSET
   ```

4. **Update the assembly source:**
   ```asm
   ; Before:
   LABEL_E02510:
       binclude "includes/e02510_e06baf.bin"

   ; After:
   LABEL_E02510:
       binclude "includes/e02510_e03fff.bin"

   LABEL_E04000:  ; Now the cross-reference target has a proper label
       binclude "includes/e04000_e06baf.bin"
   ```

5. **Remove the old binary and add the new ones:**
   ```bash
   git rm includes/original.bin
   git add includes/part1.bin includes/part2.bin
   ```

6. **Verify the build** still produces identical ROM output:
   ```bash
   make all
   python scripts/build/compare_roms.py
   ```

**Naming convention for split binaries:**
- Use address ranges in filenames: `e02510_e03fff.bin`, `e04000_e06baf.bin`
- This makes it clear what address range each file covers

**Benefits:**
- Code references become `LABEL_E04000` instead of hardcoded `0E04000h`
- Smaller files are easier to analyze and document
- Clear data structure boundaries emerge naturally
- Future splits at the same location are already handled

### Reference Disassembly with MAME's unidasm

**MAME's `unidasm` tool is available for generating reference disassembly listings.** Pre-generated `.unidasm` files are stored in `original_ROMs/` for each ROM.

**Tool location:**
```bash
../tools/unidasm
```

**Usage:**
```bash
# Generate reference disassembly for a ROM
../tools/unidasm <rom_file> -arch tlcs900 -basepc <base_address> > <output.unidasm>

# Example for Sub CPU boot ROM (base at 0xFE0000):
../tools/unidasm original_ROMs/kn5000_subcpu_boot.ic30 -arch tlcs900 -basepc 0xFE0000 > original_ROMs/kn5000_subcpu_boot.ic30.unidasm

# Decode raw bytes:
echo "XX XX XX XX" | xxd -r -p > /tmp/bytes.bin
../tools/unidasm /tmp/bytes.bin -arch tlcs900 -basepc 0
```

**When to use unidasm:**
- To get initial instruction decoding for undisassembled regions
- To verify instruction encodings when debugging divergences
- To understand control flow in new routines

**Reference files available:**
- `original_ROMs/kn5000_subcpu_boot.ic30.unidasm` - Sub CPU boot ROM
- `original_ROMs/kn5000_v10_program.ic9.unidasm` - Main CPU ROM (if available)
- `original_ROMs/hd-ae5000_v2_06i.ic4.unidasm` - HDAE5000 expansion ROM

**Note:** unidasm provides a linear disassembly without distinguishing code from data. Manual analysis is still required to identify routine boundaries, data tables, and add meaningful labels/comments.

### LLVM TLCS-900 Assembler Encoding Quirks (MUST READ)

**The LLVM TLCS-900 backend sometimes generates different (longer) encodings than the original ROM firmware uses.** When converting `.incbin` blocks to instruction-level assembly, these mismatches cause byte comparison failures. This reference documents all known quirks and their workarounds.

**Workflow for HDAE5000 disassembly:**
1. Use `unidasm` to disassemble the `.incbin` region: `../tools/unidasm original_ROMs/hd-ae5000_v2_06i.ic4 -arch tlcs900 -basepc <addr> -skip <offset> -count <N>`
2. Test uncertain instruction encodings: `echo '<instruction>' | /home/fsanches/compartilhado/llvm-project/build/bin/llvm-mc -triple=tlcs900 -show-encoding`
3. Write the conversion, replacing the `.incbin` with instructions
4. Build and verify: `make all` — must show 100% match for all ROMs

**Encodings that need a spelling choice (no `.byte` workaround is needed any more).**
These rows used to say "write `.byte`"; every spelling below assembles to the ROM's
bytes with the pinned llvm-mc (checked with c949d618 and with the T1 fix round's
binary, wave 3a, 2026-10-02):

| ROM Pattern | Spelling | Why |
|-------------|----------|-----|
| `bf d8 37` (3 bytes) — LDA through (XSP+d8) with the byte d >= 0x80 | `lda xsp, (xsp-40)` → `bf d8 37` | (Xrr+d8) is SIGNED: write the signed value (0xd8 = -40), or `(xsp-40:8)`.  `(xsp+216)` is a different address (+216, the 5-byte d16 form `f3 fd d8 00 37`) and the assembler warns |
| `2E` / `4E` (1 byte) — compact push / pop of a 16-bit register | `pushw iz` → `2e`, `popw iz` → `4e` | `push iz` / `pop iz` select the 2-byte register-prefix form (`de 04` / `de 05`) |
| `8f 00 21` (3 bytes) — `ld a, (xsp + 0x00)` in the d8 form | `ld a, (xsp+0:8)` → `8f 00 21` | a plain `(xsp)` / `(xsp+0)` takes the 1-byte-shorter `87 21` |

**Same pattern for ALL compact push/pop of 16-bit registers:** `pushw wa` (0x28),
`pushw bc` (0x29) ... `pushw sp` (0x2F), `popw wa` (0x48) ... `popw sp` (0x4F); `push r16` /
`pop r16` are the 2-byte D8+r forms.  The 32-bit `push xwa` (0x38, etc.) is 1 byte either way.

**Mnemonic reference for common operations:**

| Operation | Mnemonic | Example Encoding |
|-----------|----------|-----------------|
| Push 16-bit immediate | `pushw imm16` (NOT `push imm16`) | `pushw 0x007f` → `0b 7f 00` |
| Far pointer as two word pushes (C argument, high half first) | `pushw Sym@hi16` / `pushw Sym@lo16` (TOOLCHAIN_VERSION UPDATE 20; R_TLCS900_HI16/LO16, an absolute `.equ` is folded; only in a 16-bit immediate) | `pushw Str@hi16` → `0b e4 00` for Str = 0xe45126.  Never leave `pushw 0xe4 / pushw 0x5126`: `scripts/converters/far_pointer_pipeline.sh` |
| Post-increment / pre-decrement operand (UPDATE 17) | `(xde+)`, `(-xwa)`, step `(xwa+:N)`, N = 1, 2 or 4 -- default = the data size; LDA/JP/CALL must write it; bank regs `(xbc3+)` | `ld (xde+), a` → `f5 e8 41`; `lda xbc, (xwa+:1)` → `f5 e0 31`.  `(+r)` / `(r-)` are errors; the `*_spi`/`*_dpi` pseudos are deleted |
| Register-indirect displacement width (UPDATE 17) | `(xrr+D:8)` forces (Xrr+d8), `(xrr+D:16)` forces (Xrr+d16) | `lda xwa, (xsp+0:8)` → `bf 00 30`; `ld a, (xiz+5:16)` → `c3 f9 05 00 21`.  A plain `(xsp+256)` is +256 (`f3 fd 00 01 30`) -- it used to mean d8+0 |
| Compare register with D2 memory | `cp wa, (addr:24)` (sub-opcode 0xF0+r; the old `cpda16_24 xwa, ...` named XWA for WA and is deleted, TOOLCHAIN_VERSION UPDATE 17) | `cp wa, (0x230e72:24)` → `d2 72 0e 23 f0` |
| Compare D2 memory with register | `cp (addr:24), wa` (sub-opcode 0xF8+r; was `cpdm16_24 ..., xwa`, deleted) | `cp (0x230e72:24), wa` → `d2 72 0e 23 f8` |
| F2 LDA 24-bit address | `lda xreg, (addr:24)` (the old `ldada_24` spelling no longer exists) | `lda xwa, (0x2e2458:24)` → `f2 58 24 2e 30` |
| E2 32-bit load from 24-bit addr | `ld xreg, (addr:24)` (was `ldda32_24`, no longer exists) | `ld xbc, (0x23a1a2:24)` → `e2 a2 a1 23 21` |
| D2 16-bit load from 24-bit addr | `ld reg16, (addr:24)` (was `ldda16_24 xiz, ...`, which named XIZ for IZ; no longer exists) | `ld iz, (0x230e72:24)` → `d2 72 0e 23 26` |
| E3 (Xrr+d16) 32-bit load | `ld xbc, (xbc+3594)` (the raw pseudo `ld_sril3 xbc, 0xe5, 0x0a, 0x0e` is retired from the trees: `scripts/converters/respell_raw_pseudos.py`) | `e3 e5 0a 0e 21` (MAME `ld XBC,(XBC+0x0e0a)`) |
| C3 register-indexed 8-bit load | `ld r, (xrr+rr)` (the old `ld_srib3` raw form no longer exists) | `ld a, (xwa+ix)` → `c3 07 e0 f0 21` (MAME `ld A,(XWA+IX)`) |
| F3 register-indexed byte STORE | `ld (xrr+rr), r` | `ld (xde+hl), a` → `f3 07 e8 ec 41` (MAME `ld (XDE+HL),A`).  This row used to say `lda_dri3 xbc, ...` -- a spelling that no longer exists and named an LDA of XBC for what is a store of A |
| Bit test on a register-indexed operand | `bit 7, (xde+ix)` (TOOLCHAIN_VERSION UPDATE 21; was `bit_dri 7, 0x07, 0xe8, 0xf0`) | `f3 07 e8 f0 cf` |
| Set/reset/chg/tset on a register-indexed operand | `set 6, (xbc+wa)` / `res` / `chg` / `tset` (UPDATE 21) | `f3 07 e4 e0 be` |
| Any ALU / inc / dec / push / ex / ld-immediate on `(xrr+rr)` | `cp (xhl+iy), 0x7b`, `cpw (xwa+bc), 0xffff`, `add xde, (xwa+bc)`, `incw 1, (xwa+bc)`, `ld (xiy+hl), 0x81`, `pushw (xbc+wa)` (UPDATE 21; MUL/DIV, the 8-bit-index `(xrr+r8)` and previous-bank `(xrr+qrr)` variants of these are still missing) | `c3 07 ec f4 3f 7b` |
| D7 word ERP load imm | `ldi_werp bank, N` | raw bytes per D7 prefix |
| D7 word ERP reg copy | `ldto_werp reg, bank` (reg <- bank reg, 0x88+r) / `ldfr_werp reg, bank` (bank reg <- reg, 0x98+r); byte forms `ldto_berp` / `ldfr_berp`.  The old `stw_erp`/`ldw_erp`/`stb_erp`/`ldb_erp` read BACKWARDS and are deleted (UPDATE 17) | `ldto_werp wa, 0x30` → `d7 30 88` (ld WA,RWA3) |
| D7 word ERP compare | `cp_werp reg, bank` | raw bytes per D7 prefix |
| D2 memory inc/dec | `incdi16_24 N, addr` / `decdi16_24 N, addr` | raw bytes per D2 prefix |
| D2 compare with immediate | `cpdi16_24 addr, imm16` | raw bytes per D2 prefix |
| Stack store immediate | `ldmw (xsp+d), imm` | raw bytes |
| Stack compare immediate | `cpmi16 (xsp+d), imm` | raw bytes |
| Stack word inc/dec | `incm N, (xsp+d)` / `decm N, (xsp+d)` | raw bytes |
| Shift / rotate by a count (UPDATE 19) | `srl xhl, 16`, `rlc a, 3` -- the count is 1..16 and 16 is ENCODED as 0 (the CPU reads `count & 0x0F`, 0 = 16).  `srl xhl, 0` (MAME's raw field) and counts above 16 are errors; the `rlc_i_8`-style pseudos are deleted; `rlc a` alone is count 1 | `srl xhl, 16` → `eb ef 00`; `rrc h, 2` → `ce e9 02` |
| Compact compare small | `cp reg, N:i3` (the `cps` alias was deleted, TOOLCHAIN_VERSION UPDATE 16) | `cp hl, 0:i3` → `db d8`, `cp l, 3:i3` → `cf db` |
| Return + deallocate | `retd imm16` | `retd 2` → `0f 02 00` |
| Indirect call | `call (xhl)` | → `b3 e8` (2 bytes) |
| Compact 8-bit load | `ld reg, imm:opc` (was `ldb`, deleted in UPDATE 16) | `ld w, 0:opc` → `20 00` |
| Compact 16-bit load | `ldw reg, imm` | `ldw wa, 0x1234` → raw bytes |
| Compact 32-bit small imm | `ld xreg, N:i3` (was `lds32`, deleted in UPDATE 16) | `ld xhl, 0:i3` → `eb a8` |

**Critical gotchas:**
- `cp wa, (mem)` vs `cp (mem), wa` — opposite compare directions (register-memory vs memory-register). Wrong choice flips the carry flag behavior. Check the sub-opcode: 0xF0+r = register, mem; 0xF8+r = mem, register.  (These were the pseudos `cpda16_24` / `cpdm16_24`, deleted in TOOLCHAIN_VERSION UPDATE 17 because their 32-bit register name was encoded by index: `cpda16_24 xwa` meant WA.)
- Stack-relative LDA with a d8 byte >= 0x80: the d8 field is SIGNED, so write the signed displacement (`lda xsp, (xsp-40)` → `bf d8 37`) or force it, `(xsp-40:8)`.  `(xsp+216)` is a different address; the assembler takes the 5-byte d16 form and warns.
- DRI/SRI raw bytes (b0, b1, b2): Copy exactly from unidasm output. Even small errors (e.g., 0xE8 vs 0xE0) cause mismatches.
- Loop label placement: Verify jump targets against unidasm addresses. Off-by-one label positions cause displacement mismatches.

### LZSS Compressed Regions

The KN5000 firmware uses LZSS compression (SLIDE4K format) for embedded data. When working with compressed regions, reference `../technics-docs/lzss-compression.md` for full details.

**Compressed Data Inventory:**

| ROM | Label | Address Range | Compressed | Decompressed | Content |
|-----|-------|---------------|------------|--------------|---------|
| table_data | `Compressed_Preset_Data_LZSS` | `0x08E0000` - `0x08E6D3E` | 27,967 bytes (11B header + 27,956B payload) | 38,144 bytes (0x9500) | Parameter-like data (Feature Demo preset, `DemoSongPreset18`) |

**✅ RESOLVED:** The 0x3E0000 address mystery is now understood:
- Address `0x3E0000` = **Custom Data Flash** (firmware update staging area)
- Address `0x8E0000` = **Table Data ROM** (factory preset data)
- Firmware updates (File Type 007) write compressed payload to 0x3E0000
- On boot, `SubCPU_Send_Payload` tries to decompress from 0x3E0000; factory units fall back to Table Data ROM

See `../technics-docs/lzss-compression.md` for full details.

**Note:** The compressed data at 0x8E0000 decompresses to 38,144 bytes of parameter data (the Feature Demo preset), NOT the ~192KB Sub CPU executable.

**The Sub CPU executable is NOT at 0x830000 either.** The region at Table Data ROM offset 0x30000 (address 0x830000) is the tone database: `SubCPU_Send_Payload` bulk-copies 0x830000-0x87FFFF to Sub-CPU RAM 0x50000-0x9FFFF as five 64KB E1 transfers (`v10/maincpu/kn5000_v10_program.s:326-345`) — that is data space, not the code area at Sub-CPU 0x400+. No byte of the Sub CPU executable (`kn5000_subprogram_v142.rom`) appears anywhere in the table_data or custom_data images we hold (verified by substring search). How the Sub CPU code payload reaches the Sub CPU at runtime is still unresolved; the executable is known only from its own ROM dump and from the compressed update-disc image (which lands at Custom Data Flash 0x3E0000 only after a File Type 007 update).

**Decompression Routines (all in table_data ROM):**

| Label | Address | Purpose |
|-------|---------|---------|
| `LZSS_Decompress` | `0xFFCA50` | Main SLIDE4K decompressor |
| `LZSS_ReadByte` | `0xFFC8C2` | Read byte from compressed stream |
| `LZSS_OutputByte` | `0xFFC935` | Write decompressed byte to output |
| `LZSS_OutputByte_Alt` | `0xFFC974` | Alternate output (flash updates) |
| `LZSS_ParseHeader` | `0xFFC9B3` | Validate SLIDE4K header |

**SLIDE4K Format Parameters:**
- Window size: 4KB (4,096 bytes)
- Offset bits: 12 (0x000 - 0xFFF)
- Length bits: 4 (length + 3, so 3-18 bytes)
- Window pre-fill: First 0xFEE bytes set to 0x00

### MAME Driver Development

The `mame_driver/` directory contains reference copies of MAME source files (`kn5000.cpp`, `kn5000_cpanel.cpp/.h`) for sketching driver improvements. These are **reference copies** - always sync with upstream MAME before submitting changes.

**Driver architecture documentation:** [`docs/mame-driver/`](docs/mame-driver/README.md) — summarizes the MAME source code (memory maps, SFR registers, serial protocol, timer quirks, wiring). Start with the README for quick reference, then drill into per-component docs.

**Related documentation:**
- Control panel protocol: `../technics-docs/control-panel-protocol.md`
- Memory-mapped I/O: `../technics-docs/memory-map.md`
- Inter-CPU communication: `../technics-docs/inter-cpu-protocol.md`

### Accurate Hardware Emulation (STRICT POLICY)

**All emulator code MUST describe what actually happens on real hardware. No emulation shortcuts or HLE bypasses are acceptable when ROM dumps are available.**

This is a strict policy to ensure the MAME driver accurately represents the actual KN5000 hardware:

1. **When ROM dumps ARE available:**
   - The emulator MUST execute the actual ROM code
   - All hardware behavior must be accurately emulated
   - No preloading RAM with data that would normally be transferred by ROM code
   - No bypassing boot sequences or initialization routines
   - No "fast startup" hacks that skip real hardware behavior

2. **The ONLY exception is when ROM dumps are MISSING:**
   - Control panel MCU: ROM not dumped → HLE is acceptable
   - LED controller MCU: ROM not dumped → HLE is acceptable
   - Any other MCU without ROM dump → HLE is acceptable

3. **Sub CPU Boot ROM and Payload Transfer:**
   - The Sub CPU boot ROM IS dumped and MUST be accurately emulated
   - See `../technics-docs/boot-sequence.md` for boot ROM details
   - See `../technics-docs/inter-cpu-protocol.md` for payload transfer protocol
   - HLE shortcuts (preloading payload, skipping boot) are NOT acceptable

4. **Rationale:**
   - Accurate emulation ensures the driver works correctly if new ROM versions are discovered
   - Documents actual hardware behavior for preservation purposes
   - Helps identify emulation bugs by matching real hardware timing
   - Supports homebrew development that relies on accurate hardware behavior

5. **When debugging emulation issues:**
   - First understand what the real hardware does (via disassembly analysis)
   - Then fix the emulator to match that behavior
   - Never fix emulation by adding shortcuts that bypass real behavior

**This policy exists because the goal of this project is hardware preservation and documentation, not just "making it boot."**

### Known Disputed Interpretations

**This section indexes areas where Claude Code's analysis disagrees with human judgment.** These require additional investigation before being considered resolved.

When encountering disputed interpretations:
1. **Do not present disputed conclusions as fact** - always note the disagreement
2. **Preserve alternative interpretations** - do not delete competing theories
3. **Add investigation items** - document what research would resolve the dispute
4. **Update when resolved** - move to confirmed findings once agreement is reached

| Topic | Status | Claude's View | Human's Concern | Details |
|-------|--------|---------------|-----------------|---------|
| **Preset Data Destination** | 🟡 PARTIALLY RESOLVED | LZSS preset data (~33KB) goes to Sub CPU 0xF000+ | Transfer sizes don't match, fallback produces invalid data | `table_data/preset_data.asm`, `../technics-docs/lzss-compression.md` |

**Resolved: Address 0x3E0000 Mapping**
- [x] ~~Trace what `0x3E0000` actually maps to during boot~~ → **Custom Data Flash** (not Table Data ROM)
- [x] ~~Understand when 0x3E0000 contains valid LZSS data~~ → **After firmware update** (File Type 007 writes here)

**Still investigating for Preset Data Destination:**
- [ ] Explain why 64KB bulk transfers are used for ~33KB of data
- [ ] Determine why fallback to `0x800000` produces `0xF7` padding bytes
- [ ] Verify the exact Sub CPU address where preset data is written

**Adding new disputes:** When Claude Code and a human contributor disagree on an interpretation, add it to this table with:
- Brief summary of both positions
- Links to detailed documentation
- Specific investigation items that would resolve the dispute

## Architecture

### ROM Components

| Component | Authoritative source | Byte-match | Not `.incbin` |
|---|---|---|---|
| maincpu v10 | `v10/maincpu/kn5000_v10_program.s` | 100.00% | 59.0% |
| maincpu v9 | `v9/maincpu/kn5000_v9_program.s` | 100.00% | 59.0% |
| maincpu v7 | `v7/maincpu/kn5000_v7_program.s` | 100.00% | 52.5% |
| subcpu payload v142 | `v142/subcpu/kn5000_subprogram_v142.s` | 100.00% | 100.0% |
| subcpu boot (IC30) | `subcpu/boot/kn5000_subcpu_boot.s` | 100.00% | 100.0% |
| table_data | `table_data/kn5000_table_data.s` | 100.00% | 46.9% |
| custom_data (IC19) | `custom_data/kn5000_custom_data.s` | 100.00% | 36.3% |
| hdae5000 | `hdae5000/hd-ae5000_v2_06i.s` | 100.00% | 40.3% |

The two columns answer different questions and must not be conflated. **Byte-match** is
`python scripts/build/compare_roms.py`; measured 2026-08-21 it printed `romset bytematch:
100.00%` with all nine LLVM sections at 100.00%. (The ninth, `subcpu v142 update image`,
has no source row of its own. `DISASSEMBLY_PLAN.md`'s standing invariant counts **15**
sections; the extra six are the legacy ASL mirror builds, which only run when their
`.rebuilt.rom` artefacts are present in `rebuilt_ROMs/`.)

**Not `.incbin`** is `python3 scripts/analysis/kn5000_source_coverage.py`, measured
2026-08-21: the share of ROM bytes that do *not* enter the build through an `.incbin`.
Read it with the script's own `of which C` column, because compiled C counts on the
`.incbin` side, not the source side: of maincpu v10's 860,028 `.incbin` bytes, 855,100 are
byte-exact recompiled C and only 4,928 (0.23% of the ROM) are a raw blob. So a low figure
here does not mean "unexplained". Two further caveats: the v7 row is flattered by
`scripts/build/extract_v7_bins.py`, which copies 842,796 B of the v7 ROM into its own
"source" at build time (703,693 B of that is reproduced by no source at all -- the script
prints this itself); and IC30's 100.0% is over a `BAD_DUMP`, flagged as such in
`mame_driver/src/mame/matsushita/kn5000.cpp`, of which only 4,352 of 131,072 bytes are
non-0xFF.

The ASL mirror (`.asm`) sources are archived under `archive/asl/` and are not
authoritative.

See `../technics-docs/rom-reconstruction.md` for the narrative breakdown.

### Key Files

- **tmp94c241.inc**: Macros for TMP94C241F instructions not natively supported by ASL (which only supports TMP96C141). These encode raw byte sequences for unsupported opcodes like LDI, LDIR, MUL/DIV variants, and shift operations.

- **scripts/build/compare_roms.py**: Post-build verification that compares rebuilt ROMs byte-by-byte against originals in `original_ROMs/` and reports match percentage.

- **scripts/analysis/extract_include_binaries.py**: Extracts embedded binary data (images, assets) from disassembled code for inclusion via assembly `include()` directives.

### Directory Structure

- `original_ROMs/`: Original firmware dumps and reference disassembly (`.unidasm` files)
- `rebuilt_ROMs/`: Build output (created by make)
- `maincpu/images/`, `maincpu/includes/`: Binary image data included in main CPU ROM
- `table_data/images/`: BMP assets for feature demo
- `hdae5000/`: HDAE5000 hard disk expansion ROM disassembly
- `docs/`: Protocol analysis notes (control panel serial communication)

### Original ROM Files

ROM dumps are stored in `original_ROMs/`. Reference disassembly files (`.unidasm`) are pre-generated.

See `../technics-docs/rom-reconstruction.md` for the complete ROM inventory and chip locations.

### Memory Map

See `../technics-docs/memory-map.md` for the complete memory layout including all I/O ports, ROM regions, and RAM areas.

## Technical Constraints

The main blocking issue is that ASL only supports TMP96C141, not TMP94C241F. Unsupported instructions are emitted as raw bytes via macros in `tmp94c241.inc`.

See `../technics-docs/reverse-engineering.md` for detailed toolchain notes and workarounds.

## Cross-Version Diff Minimization Policies (STRICT)

These policies govern how multi-version source trees are maintained to ensure that cross-version diffs show ONLY genuine firmware differences, with zero formatting noise.

### 1. Symbolic References (STRICT)
All code and data references must use symbolic labels, never raw numeric addresses:
- **Instructions:** `call`, `jp`, `calr`, `jr`, `jrl`, `lda_24`, `ld` with ROM addresses must use label names.
- **Data pointers:** `.long` pointer tables must use `.long LABEL`, not `.long 0x00NNNNNN`.
- **Embedded 24-bit addresses in bytecode/data tables:** Use the `addr24` macro with a `.set` constant:
  ```asm
  .set _addr24_Mem_Copy, 0xff0d99  ; version-specific address
  addr24 _addr24_Mem_Copy          ; emits 3-byte LE address
  ```
- **Missing symbols:** When a target address has no symbol, create one with a semantic name derived from code analysis.
- **Mid-instruction addresses:** When a pointer targets a byte inside a multi-byte instruction (not an entry point), define it as `.set LABEL, ParentLabel + N` with a comment explaining the mid-structure offset.

### 2. Lowercase Hex (STRICT)
All hex values must use lowercase `a-f`. Applies to `.byte`, `.long`, instruction immediates, and hex in comments. Does NOT apply to hex digits in symbol names (e.g., `NAKA_TYPE_0x5D` keeps its case).

### 3. Tab-After-Mnemonic Formatting (STRICT)
All instruction lines must use tab between mnemonic and operand: `	call	LABEL`, not `	call LABEL`. This ensures cross-version diffs show only semantic differences, not whitespace noise.

### 4. No Faux-Instructions in Data (STRICT)
Data bytes must NOT be represented as TLCS-900 instructions. If a region contains bytecode, data tables, or non-CPU-code binary data, it must be represented as:
- **C structs with semantically named fields** compiled via the clang pipeline (preferred). Field names must derive from actual code analysis showing how the firmware uses each field.
- **`.byte` directives with explanatory comments** (acceptable as an intermediate step before struct definition is understood).
- Raw `.byte` without annotation is never acceptable for structured data.

### 5. Canonical Label Names (STRICT)
Each address must have exactly one label name. No aliases (`__jrt_nop_XXXXXX`, redundant `_Entry` suffixes, etc.) unless they serve a documented purpose. When multiple names exist for the same address, pick the most semantically descriptive one and remove the aliases. Original Matsushita debug symbol names (e.g., `assswb_op`, `sendCOMM`) must be preserved in comments, not as live labels.

### 6. Label Placement (STRICT)
Labels must be placed at instruction/data boundaries, never in the middle of a multi-byte instruction encoding. When disassembling, verify that labels don't split instructions by checking that the bytes after the label form a valid instruction.

### 7. Decimal-to-Hex Immediates (STRICT)
Large numeric immediates (addresses, bitmasks, buffer sizes) must use hex notation. Small values used as counts, indices, or arithmetic (0-255) may remain decimal. Rule of thumb: if the value represents an address or hardware/memory constant, use hex.

### 8. Consistent Signed/Unsigned Displacements (STRICT)
`calr` and `jrl` displacements must use the same sign convention across all versions. Prefer unsigned 16-bit representation (matching assembler output) unless the displacement is small and clearly negative (within -128..+127).

### 9. Multi-Version Sync (STRICT)
Every edit must be applied to ALL versions where the same code exists. After any change to one version, check all other versions for the same code and apply the equivalent fix. Always rebuild and verify byte-match on ALL versions after edits.

### 10. Diff and Documentation Regeneration (STRICT)
After any codebase change affecting cross-version comparisons:
- Regenerate diff files in `diffs/`.
- Update the website report if numbers changed.
- Update the website report if the cleaner diff reveals new insights about what actually changed between versions (e.g., discovering that a "code change" was actually a data table pointer adjustment).

### 11. Native Instructions Over .byte (STRICT)
Executable code must be represented as native TLCS-900 instructions, not raw `.byte` directives. When creating a new version's source from ROM bytes, disassemble all code regions to native instructions. `.byte` fallbacks are acceptable ONLY for: (a) genuinely unknown instruction encodings not supported by the LLVM backend, (b) data bytes that are not executable code.

### 12. All Content Reachable via Website Sidebar (STRICT)
Every documentation page added to the website (`/home/fsanches/compartilhado/technics-docs/`) must have a corresponding entry in `_data/navigation.yml`. No orphan pages.

## ⚠⚠ RECURSIVE `grep` SILENTLY SKIPS 47% OF THIS TREE ⚠⚠

Established 2026-08-21, after it produced a false "I searched everywhere" claim that reached a
committed document.

In the Claude Code environment `grep` is a shell function wrapping **ugrep** with `-I`
(skip binary files). ugrep calls a file BINARY if it contains ANY byte above 127 — and 65 of this
repo's 506 `.s` files do, because `.ascii` directives hold raw non-UTF-8 bytes from the ROM. Those
65 files are **47% of the disassembly by volume**, and they are the data-heavy ones:

    v142/subcpu/kn5000_subprogram_v142.s   1,426,915 B    306 high bytes
    table_data/tone_database_aux.s           944,636 B      3
    hdae5000/hdae5000_data_tables.s          801,311 B  7,532
    v7/v9/v10 .../accompaniment_engine.s     ~690,000 B    15
    v9/v10 .../sequencer_engine.s            ~619,000 B    15

THE RULE, measured both ways:

    grep -c PATTERN path/to/file.s      # NAMED file: searched correctly
    grep -rn PATTERN some/dir/          # RECURSIVE: high-byte files SILENTLY OMITTED

A recursive search reports no error and a plausible number. Searching `v10/maincpu` for
`0x8[56]` returns 250 matches in 37 files through the wrapper and **598 in 51 files** through
real grep — the difference includes `sequencer_engine.s` and `scoop_display.s`, which is where the
answer to a question I had recorded as "searched and eliminated" actually lived.

**ALWAYS USE `command grep` FOR RECURSIVE SEARCHES IN THIS REPO**, or `python3` with `read_bytes()`.
Never write "I searched all of X" on the strength of a bare recursive `grep`.

This is the same root cause as the other tooling trap recorded here: non-UTF-8 bytes inside
`.ascii` literals. They also break `Path.read_text()`, which corrupts the file on write-back. Treat
every `.s` in this tree as binary, for reading, writing and searching alike.
