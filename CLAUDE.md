# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a ROM disassembly project for the Technics KN5000 music keyboard. The goal is to achieve 100% byte-matching reconstruction of the original firmware ROMs, enabling MAME emulation and homebrew development.

**Target CPU:** TMP94C241F (TLCS900 variant)
**Assembler:** Alfred Arnold's ASL Macro Assembler 1.42 Beta (Build 298)

### Documentation Website

Detailed documentation is at `../kn5000-docs/`. Key pages:
- **Hardware**: `hardware-architecture.md`, `memory-map.md`, `cpu-subsystem.md`
- **Protocols**: `control-panel-protocol.md`, `inter-cpu-protocol.md`, `boot-sequence.md`
- **Progress**: `rom-reconstruction.md`, `issues.md`, `reverse-engineering.md`
- **Subsystems**: `audio-subsystem.md`, `fdc-subsystem.md`, `hdae5000.md`
- **Data Formats**: `lzss-compression.md` (0x3E0000 address resolved - see [Firmware Update System](../kn5000-docs/lzss-compression.md#firmware-update-system-and-0x3e0000))

### Analysis Documents

In-repo analysis notes are in `analysis/`. Key documents:
- **[String Analysis](analysis/strings/)** - Extracted strings from ROMs with categorization
  - [Overview](analysis/strings/README.md) - Executive summary (start here)
  - [Quick Reference](analysis/strings/quick-reference.md) - Fast offset lookup
  - [Detailed Analysis](analysis/strings/detailed-analysis.md) - Complete categorized listing

### Issue Tracker

Issues are tracked with Beads in `.beads/issues.jsonl`. Use `../tools/bd` commands (see Issue Tracking section below).

## Build Commands

```bash
# Build all ROMs and run byte comparison
make all

# Build specific components
make rebuilt_ROMs/kn5000_v10_program.rebuilt.rom      # Main CPU
make rebuilt_ROMs/kn5000_subprogram_v142.rebuilt.rom  # Sub CPU
make rebuilt_ROMs/kn5000_table_data.rebuilt.rom       # Table data

# Clean build artifacts
make clean              # All
make clean_maincpu      # Main CPU only
make clean_subcpu       # Sub CPU only
make clean_table_data   # Table data only
make clean_preset_data  # Preset data intermediate files

# Rebuild preset data (assemble + LZSS compress)
make rebuild-preset-data

# Verify rebuilt ROMs against originals (runs automatically after make all)
python scripts/compare_roms.py

# Update documentation website
make gallery            # Convert images to PNG for gallery
make issues             # Export issue tracker to website
make rom-status         # Generate ROM status diagram
make website            # All of the above (gallery + issues + rom-status)
```

The ASL assembler path is configured in the Makefile at `ASL_PATH`.

## Project Policies

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

**All helper scripts must be placed in the `scripts/` directory and committed to the repo.**

This ensures:
- Scripts are version-controlled and available to all contributors
- Consistent location for automation tools
- Easy discovery of available utilities

When creating new scripts, place them in `scripts/` and add them to git immediately.

### Symbol Reference Files (STRICT POLICY)

**The symbol reference files MUST be kept in sync with the source code at all times.**

Symbol reference files in `symbols/` provide address-to-name mappings for external tools:

| File | ROM | Symbols | Address Range |
|------|-----|---------|---------------|
| `symbols/maincpu_symbols_reference.txt` | Main CPU | 39,125 | 0xE00000 - 0xFFFFFF |
| `symbols/subcpu_symbols_reference.txt` | Sub CPU payload | 3,309 | 0x000400 - 0x03EE75 |
| `symbols/subcpu_boot_symbols_reference.txt` | Sub CPU boot | 53 | 0xFF8000 - 0xFFFFF0 |
| `symbols/table_data_symbols_reference.txt` | Table data | 113 | 0x800000 - 0x9FFEE0 |
| `symbols/hdae5000_symbols_reference.txt` | HDAE5000 expansion | 34 | 0x280000 - 0x29AF2D |

**Format:**
```
# Symbol Reference File
# Format: SYMBOL_NAME ADDRESS
SYMBOL_NAME 0xADDRESS
```

**Update procedure - directly edit the reference files when modifying assembly:**

Because regenerating from scratch takes ~70 minutes for maincpu, **always edit the symbol reference files directly** instead of regenerating:

- **Adding a label:** Insert a new line in the appropriate reference file, maintaining address sort order
- **Renaming a label:** Find and replace the old name with the new name
- **Removing a label:** Delete the corresponding line

**Example:** When adding `FDC_INIT_ROUTINE` at address `0xE12345` to maincpu:
```
# Find the correct position (after 0xE12344, before 0xE12346) and insert:
FDC_INIT_ROUTINE 0xE12345
```

**Full regeneration** (only if files become corrupted or majorly out of sync):
```bash
# Generate map files with ASL (maincpu takes ~70 minutes, others are fast)
ASL=../tools/asl/asl

$ASL -w -g map maincpu/kn5000_v10_program.asm -o /tmp/maincpu.p
$ASL -w -g map subcpu/kn5000_subprogram_v142.asm -o /tmp/subcpu.p
$ASL -w -g map subcpu/boot/kn5000_subcpu_boot.asm -o /tmp/subcpu_boot.p
$ASL -w -g map table_data/kn5000_table_data.asm -o /tmp/table_data.p
$ASL -w -g map hdae5000/hd-ae5000_v2_06i.asm -o /tmp/hdae5000.p

# Extract symbols from map files
python scripts/extract_symbols_from_map.py maincpu/kn5000_v10_program.map symbols/maincpu_symbols_reference.txt
python scripts/extract_symbols_from_map.py subcpu/kn5000_subprogram_v142.map symbols/subcpu_symbols_reference.txt
python scripts/extract_symbols_from_map.py subcpu/boot/kn5000_subcpu_boot.map symbols/subcpu_boot_symbols_reference.txt
python scripts/extract_symbols_from_map.py table_data/kn5000_table_data.map symbols/table_data_symbols_reference.txt
python scripts/extract_symbols_from_map.py hdae5000/hd-ae5000_v2_06i.map symbols/hdae5000_symbols_reference.txt

# Clean up intermediate files
rm /tmp/*.p maincpu/*.map subcpu/*.map subcpu/boot/*.map table_data/*.map hdae5000/*.map
```

**This policy exists because** external tools (debuggers, analysis scripts, MAME integration) depend on accurate symbol mappings. Stale symbol files cause confusion and break tooling.

### Image Extraction and Gallery Updates

When new images are discovered and extracted as `.bin` files in `maincpu/images/` or `table_data/images/`:

1. **Add metadata** to `scripts/convert_images.py` in the `IMAGE_METADATA` dictionary:
   - Filename
   - Dimensions (width, height)
   - Bit depth (1, 4, or 8)
   - Description

2. **Run the gallery conversion**:
   ```bash
   make gallery
   ```

3. **Update the image gallery** page at `../kn5000-docs/image-gallery.md` with the new images

4. **Commit both repositories** (roms-disasm and docs) together

This ensures the documentation website always reflects the latest extracted images.

### Event Code Freshness (STRICT POLICY)

**When new firmware event codes are discovered or existing codes are better understood, ALL of the following must be updated:**

1. **Assembly source** -- Add/update `EVT_*` EQU constants in `hdae5000/hd-ae5000_v2_06i.asm` and `maincpu/kn5000_v10_program.asm`; replace raw hex values (e.g., `01C0000Fh`) with symbolic names (e.g., `EVT_INIT_HOOK`)
2. **Event codes reference page** -- Update `../kn5000-docs/event-codes.md` with new codes, dispatch paths, and descriptions
3. **HDAE5000 homebrew page** -- Update `../kn5000-docs/hdae5000-homebrew.md` if the discovery affects handler registration or activation flow
4. **Mines project** -- Update `../../Mines/CLAUDE.md` if applicable

**This policy exists because** event codes are the primary interface between the firmware and extension ROMs. Inconsistent documentation across the disassembly, website, and homebrew project causes confusion. The canonical event code reference is `../kn5000-docs/event-codes.md`.

### Website Synchronization

The documentation website at `../kn5000-docs/` must be kept in sync with project progress. **Run these commands regularly:**

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

The file `scripts/generate_rom_status_diagram.py` generates an SVG visualization showing the disassembly status of each ROM component. This diagram provides an at-a-glance view of project progress.

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

The diagram is displayed on the documentation website at `/rom-reconstruction/`. See `../kn5000-docs/rom-reconstruction.md` for detailed progress tracking.

### Symbol Name Synchronization (STRICT POLICY)

**When updating documentation, ALL symbol names must match the current assembly source.**

This is a strict policy to prevent documentation from becoming outdated as symbols are renamed during reverse engineering:

1. **Before committing documentation changes**, verify that all symbol names mentioned exist in the assembly:
   ```bash
   # Search for a symbol in the assembly
   grep -n "SYMBOL_NAME" maincpu/kn5000_v10_program.asm
   ```

2. **When renaming symbols in assembly**, search documentation for the old name:
   ```bash
   # Find all references in documentation
   grep -rn "OLD_SYMBOL_NAME" ../kn5000-docs/
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
   grep "FC4489\|0xFC4489" maincpu/*.asm  # Find label at address 0xFC4489
   ```

**This policy exists because stale symbol names in documentation cause confusion and make it harder for contributors to navigate between docs and source code.**

### Issue Tracking (STRICT POLICY)

Project issues are tracked using [Beads](https://github.com/beads-ai/beads) in `.beads/issues.jsonl`.

**CRITICAL: NEVER edit `.beads/issues.jsonl` directly!** Always use the `bd` command:

### Issue Closure Requirements (MANDATORY)

**Before closing ANY issue, you MUST complete ALL of the following steps:**

1. **Website Documentation Update**: Update the relevant pages in `../kn5000-docs/` with detailed findings:
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
# The bd command is located at:
../tools/bd

# Common operations:
../tools/bd list                              # List all issues
../tools/bd show <issue-id>                   # Show issue details
../tools/bd close <issue-id>                  # Close an issue
../tools/bd reopen <issue-id>                 # Reopen a closed issue
../tools/bd comments add <issue-id> "text"   # Add a comment to an issue
../tools/bd create "title"                    # Create new issue
../tools/bd update <issue-id> --notes "text" # Update issue notes
../tools/bd ready                             # Find available work (unblocked, unassigned)
../tools/bd sync                              # Sync issues with git
```

The issue tracker is:
- Synced to git for persistence
- Exported to the website via `make issues`
- Visible at `/issues/` on the documentation site

**Quick access:** Run `../tools/bd list` for current issues, or see `../kn5000-docs/issues.md` for the web version.

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

6. **Benefits of symbolic references:**
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

1. **Procedure:** Write a `scripts/rename_<topic>.sed` file with all `s/OLD_NAME/NEW_NAME/g` rules, then run: `sed -i -f scripts/rename_<topic>.sed <assembly_file>`
2. **Scope:** Apply the sed script to all files that reference the symbols (assembly, symbol reference files, etc.)
3. **Verification:** After running, follow Assembly Edit Verification policy (build + compare_roms.py)
4. **Cleanup:** The sed script may be deleted after successful commit, or kept for reference

### Inter-ROM Cross-References (STRICT POLICY)

**When code references an address outside its own ROM's memory range, the target ROM's assembly file must be inspected for cross-reference labels.**

This is a strict policy to maintain consistency across all ROM components and ensure complete understanding of inter-component communication:

1. **Memory ranges for each ROM component:** See `../kn5000-docs/memory-map.md` for complete address ranges.

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
   python scripts/compare_roms.py
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

### LZSS Compressed Regions

The KN5000 firmware uses LZSS compression (SLIDE4K format) for embedded data. When working with compressed regions, reference `../kn5000-docs/lzss-compression.md` for full details.

**Compressed Data Inventory:**

| ROM | Label | Address Range | Compressed | Decompressed | Content |
|-----|-------|---------------|------------|--------------|---------|
| table_data | `Compressed_Preset_Data_LZSS` | `0x08E0000` - `0x08E6D40` | 27,967 bytes | ~32,910 bytes | Parameter-like data |

**✅ RESOLVED:** The 0x3E0000 address mystery is now understood:
- Address `0x3E0000` = **Custom Data Flash** (firmware update staging area)
- Address `0x8E0000` = **Table Data ROM** (factory preset data)
- Firmware updates (File Type 007) write compressed payload to 0x3E0000
- On boot, `SubCPU_Send_Payload` tries to decompress from 0x3E0000; factory units fall back to Table Data ROM

See `../kn5000-docs/lzss-compression.md` for full details.

**Note:** The compressed data at 0x8E0000 decompresses to ~33KB of parameter data, NOT the ~192KB Sub CPU executable. The Sub CPU executable is stored uncompressed at Table Data ROM offset 0x30000 (address 0x830000).

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
- Length bits: 4 (length + 2, so 2-17 bytes)
- Window pre-fill: First 0xFEE bytes set to 0x00

### MAME Driver Development

The `mame_driver/` directory contains reference copies of MAME source files (`kn5000.cpp`, `kn5000_cpanel.cpp/.h`) for sketching driver improvements. These are **reference copies** - always sync with upstream MAME before submitting changes.

**Driver architecture documentation:** [`docs/mame-driver/`](docs/mame-driver/README.md) — summarizes the MAME source code (memory maps, SFR registers, serial protocol, timer quirks, wiring). Start with the README for quick reference, then drill into per-component docs.

**Related documentation:**
- Control panel protocol: `../kn5000-docs/control-panel-protocol.md`
- Memory-mapped I/O: `../kn5000-docs/memory-map.md`
- Inter-CPU communication: `../kn5000-docs/inter-cpu-protocol.md`

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
   - See `../kn5000-docs/boot-sequence.md` for boot ROM details
   - See `../kn5000-docs/inter-cpu-protocol.md` for payload transfer protocol
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
| **Preset Data Destination** | 🟡 PARTIALLY RESOLVED | LZSS preset data (~33KB) goes to Sub CPU 0xF000+ | Transfer sizes don't match, fallback produces invalid data | `table_data/preset_data.asm`, `../kn5000-docs/lzss-compression.md` |

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

| Component | Source | Status |
|-----------|--------|--------|
| maincpu | `maincpu/kn5000_v10_program.asm` | 100% |
| subcpu payload | `subcpu/kn5000_subprogram_v142.asm` | 100% |
| table_data | `table_data/kn5000_table_data.asm` | ~33% |
| hdae5000 | `hdae5000/hd-ae5000_v2_06i.asm` | ~5% |

Run `python scripts/compare_roms.py` for current status. See `../kn5000-docs/rom-reconstruction.md` for detailed breakdown.

### Key Files

- **tmp94c241.inc**: Macros for TMP94C241F instructions not natively supported by ASL (which only supports TMP96C141). These encode raw byte sequences for unsupported opcodes like LDI, LDIR, MUL/DIV variants, and shift operations.

- **scripts/compare_roms.py**: Post-build verification that compares rebuilt ROMs byte-by-byte against originals in `original_ROMs/` and reports match percentage.

- **scripts/extract_include_binaries.py**: Extracts embedded binary data (images, assets) from disassembled code for inclusion via assembly `include()` directives.

### Directory Structure

- `original_ROMs/`: Original firmware dumps and reference disassembly (`.unidasm` files)
- `rebuilt_ROMs/`: Build output (created by make)
- `maincpu/images/`, `maincpu/includes/`: Binary image data included in main CPU ROM
- `table_data/images/`: BMP assets for feature demo
- `hdae5000/`: HDAE5000 hard disk expansion ROM disassembly
- `docs/`: Protocol analysis notes (control panel serial communication)

### Original ROM Files

ROM dumps are stored in `original_ROMs/`. Reference disassembly files (`.unidasm`) are pre-generated.

See `../kn5000-docs/rom-reconstruction.md` for the complete ROM inventory and chip locations.

### Memory Map

See `../kn5000-docs/memory-map.md` for the complete memory layout including all I/O ports, ROM regions, and RAM areas.

## Technical Constraints

The main blocking issue is that ASL only supports TMP96C141, not TMP94C241F. Unsupported instructions are emitted as raw bytes via macros in `tmp94c241.inc`.

See `../kn5000-docs/reverse-engineering.md` for detailed toolchain notes and workarounds.
