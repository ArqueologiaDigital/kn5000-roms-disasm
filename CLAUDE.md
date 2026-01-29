# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a ROM disassembly project for the Technics KN5000 music keyboard. The goal is to achieve 100% byte-matching reconstruction of the original firmware ROMs, enabling MAME emulation and homebrew development.

**Target CPU:** TMP94C241F (TLCS900 variant)
**Assembler:** Alfred Arnold's ASL Macro Assembler 1.42 Beta (Build 298)

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

# Verify rebuilt ROMs against originals (runs automatically after make all)
python compare_roms.py

# Update documentation website
make gallery            # Convert images to PNG for gallery
make issues             # Export issue tracker to website
make website            # Both gallery + issues
```

The ASL assembler path is configured in the Makefile at `ASL_PATH`.

## Project Policies

### Image Extraction and Gallery Updates

When new images are discovered and extracted as `.bin` files in `maincpu/images/` or `table_data/images/`:

1. **Add metadata** to `convert_images.py` in the `IMAGE_METADATA` dictionary:
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

### Website Synchronization

The documentation website at `../kn5000-docs/` must be kept in sync with project progress. **Run these commands regularly:**

```bash
make website   # Updates both gallery and issues
```

This runs:
1. `make gallery` - Converts extracted images to PNG
2. `make issues` - Exports Beads issue tracker to `issues.md`

**When to update the website:**
- After extracting new images
- After closing or creating issues
- After significant reverse engineering discoveries
- Before committing major changes

Always commit both repositories together when making website updates.

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
~/claude_jail/bd

# Common operations:
~/claude_jail/bd list                              # List all issues
~/claude_jail/bd show <issue-id>                   # Show issue details
~/claude_jail/bd close <issue-id>                  # Close an issue
~/claude_jail/bd reopen <issue-id>                 # Reopen a closed issue
~/claude_jail/bd comments add <issue-id> "text"   # Add a comment to an issue
~/claude_jail/bd create "title"                    # Create new issue
~/claude_jail/bd update <issue-id> --notes "text" # Update issue notes
~/claude_jail/bd ready                             # Find available work (unblocked, unassigned)
~/claude_jail/bd sync                              # Sync issues with git
```

The issue tracker is:
- Synced to git for persistence
- Exported to the website via `make issues`
- Visible at `/issues/` on the documentation site

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

### Inter-ROM Cross-References (STRICT POLICY)

**When code references an address outside its own ROM's memory range, the target ROM's assembly file must be inspected for cross-reference labels.**

This is a strict policy to maintain consistency across all ROM components and ensure complete understanding of inter-component communication:

1. **Memory ranges for each ROM component:**
   | Component | Code Range | RAM Range |
   |-----------|------------|-----------|
   | maincpu | 0xE00000-0xFFFFFF | 0x000000-0x001FFF, 0x200000-0x23FFFF |
   | subcpu | 0x000000-0x02FFFF | Internal RAM |
   | hdae5000 | 0x280000-0x2FFFFF | Shared with maincpu |
   | table_data | 0x800000-0x9FFFFF | N/A (data only) |

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
   python compare_roms.py
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
~/claude_jail/unidasm
```

**Usage:**
```bash
# Generate reference disassembly for a ROM
~/claude_jail/unidasm <rom_file> -arch tlcs900 -basepc <base_address> > <output.unidasm>

# Example for Sub CPU boot ROM (base at 0xFE0000):
~/claude_jail/unidasm original_ROMs/kn5000_subcpu_boot.ic30 -arch tlcs900 -basepc 0xFE0000 > original_ROMs/kn5000_subcpu_boot.ic30.unidasm

# Decode raw bytes:
echo "XX XX XX XX" | xxd -r -p > /tmp/bytes.bin
~/claude_jail/unidasm /tmp/bytes.bin -arch tlcs900 -basepc 0
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

### MAME Driver Development Workflow

**The `mame_driver/` directory contains reference copies of MAME source files for HLE development.**

This is NOT the complete MAME codebase - only the files needed for sketching driver improvements, particularly control panel High Level Emulation (HLE).

**Files included:**

| File | Purpose |
|------|---------|
| `mame_driver/src/mame/matsushita/kn5000.cpp` | Main driver (machine config, address maps) |
| `mame_driver/src/mame/matsushita/kn5000_cpanel.cpp` | Control panel HLE device |
| `mame_driver/src/mame/matsushita/kn5000_cpanel.h` | Control panel HLE header |

**Workflow for driver improvements:**

1. **Study reverse engineering findings** - Analyze protocol details from disassembly
2. **Understand current HLE** - Read the existing MAME driver files
3. **Design improvements** - Plan changes based on protocol understanding
4. **Draft changes** - Update the reference files with proposed code
5. **Document the rationale** - Explain why changes are needed
6. **Submit to MAME** - Create pull request to upstream MAME repository

**Connection to disassembly:**

- Control panel protocol details: See `CPanel_*` routines in `maincpu/kn5000_v10_program.asm`
- Memory-mapped I/O: Latch at `0x120000`, documented in `../kn5000-docs/memory-map.md`
- Protocol state machine: See `../kn5000-docs/control-panel-protocol.md`

**Important notes:**

- These are **reference copies** - always sync with upstream MAME before submitting changes
- The HLE uses protocol analysis from the disassembly to emulate the MCU's behavior
- MCU ROM dumps are not available - HLE is the only emulation approach
- Additional reference files may be added as needed

## Architecture

### ROM Components

| Component | Source | Status |
|-----------|--------|--------|
| maincpu | `maincpu/kn5000_v10_program.asm` (461K lines) | 99.99% |
| subcpu payload | `subcpu/kn5000_subprogram_v142.asm` | 100% |
| table_data | `table_data/kn5000_table_data.asm` | ~32% |
| hdae5000 | `hdae5000/hd-ae5000_v2_06i.asm` | ~5% (skeleton) |

### Key Files

- **tmp94c241.inc**: Macros for TMP94C241F instructions not natively supported by ASL (which only supports TMP96C141). These encode raw byte sequences for unsupported opcodes like LDI, LDIR, MUL/DIV variants, and shift operations.

- **compare_roms.py**: Post-build verification that compares rebuilt ROMs byte-by-byte against originals in `original_ROMs/` and reports match percentage.

- **extract_include_binaries.py**: Extracts embedded binary data (images, assets) from disassembled code for inclusion via assembly `include()` directives.

### Directory Structure

- `original_ROMs/`: Original firmware dumps and reference disassembly (`.unidasm` files)
- `rebuilt_ROMs/`: Build output (created by make)
- `maincpu/images/`, `maincpu/includes/`: Binary image data included in main CPU ROM
- `table_data/images/`: BMP assets for feature demo
- `hdae5000/`: HDAE5000 hard disk expansion ROM disassembly
- `docs/`: Protocol analysis notes (control panel serial communication)

### Original ROM Files

| File | Size | Description |
|------|------|-------------|
| `original_ROMs/kn5000_v10_program.rom` | 2MB | Main CPU program ROM |
| `original_ROMs/kn5000_subprogram_v142.rom` | 192KB | Sub CPU payload (sent by main CPU) |
| `original_ROMs/kn5000_subcpu_boot.ic30` | 128KB | Sub CPU boot ROM |
| `original_ROMs/kn5000_table_data_rom_odd.ic1` | 1MB | Table data ROM (odd bytes) |
| `original_ROMs/kn5000_table_data_rom_even.ic3` | 1MB | Table data ROM (even bytes) |
| `original_ROMs/kn5000_custom_data.ic19` | 1MB | Custom data flash (user storage) |
| `original_ROMs/hd-ae5000_v2_06i.ic4` | 512KB | HDAE5000 hard disk expansion ROM |

Reference disassembly files (`.unidasm`) are generated with MAME's unidasm tool.

### Main CPU Memory Map (key addresses)

```
0x110000 - Floppy Disk Controller
0x120000 - Inter-CPU Communication Latches
0x160000 - HDAE5000 PPI (audio processor interface)
0x280000 - HDAE5000 ROM
0x300000 - Custom Data Flash (user storage)
0x400000 - Rhythm Data ROM
0x800000 - Table Data ROM
0xE00000 - Program Flash (main ROM)
```

## Technical Constraints

The main blocking issue is that ASL only supports TMP96C141, not TMP94C241F. Unsupported instructions are currently emitted as raw bytes via macros in `tmp94c241.inc`, with some placeholder zeros where exact encodings are uncertain.

The sub-CPU ROM build involves splitting output with `dd` to produce the correct binary layout (256 bytes + 60KB segment).
