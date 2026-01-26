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

### Reference Disassembly with MAME's unidasm

**MAME's `unidasm` tool is available for generating reference disassembly listings.** Pre-generated `.unidasm` files are stored in `original_ROMs/` for each ROM.

**Usage:**
```bash
# Generate reference disassembly for a ROM
unidasm <rom_file> -arch tlcs900 -basepc <base_address> > <output.unidasm>

# Example for Sub CPU boot ROM (base at 0xFE0000):
unidasm original_ROMs/kn5000_subcpu_boot.ic30 -arch tlcs900 -basepc 0xFE0000 > original_ROMs/kn5000_subcpu_boot.ic30.unidasm
```

**When to use unidasm:**
- To get initial instruction decoding for undisassembled regions
- To verify instruction encodings when debugging divergences
- To understand control flow in new routines

**Reference files available:**
- `original_ROMs/kn5000_subcpu_boot.ic30.unidasm` - Sub CPU boot ROM
- `original_ROMs/kn5000_v10_program.ic9.unidasm` - Main CPU ROM (if available)

**Note:** unidasm provides a linear disassembly without distinguishing code from data. Manual analysis is still required to identify routine boundaries, data tables, and add meaningful labels/comments.

## Architecture

### ROM Components

| Component | Source | Status |
|-----------|--------|--------|
| maincpu | `maincpu/kn5000_v10_program.asm` (461K lines) | 99.99% |
| subcpu payload | `subcpu/kn5000_subprogram_v142.asm` | 100% |
| table_data | `table_data/kn5000_table_data.asm` | ~32% |

### Key Files

- **tmp94c241.inc**: Macros for TMP94C241F instructions not natively supported by ASL (which only supports TMP96C141). These encode raw byte sequences for unsupported opcodes like LDI, LDIR, MUL/DIV variants, and shift operations.

- **compare_roms.py**: Post-build verification that compares rebuilt ROMs byte-by-byte against originals in `original_ROMs/` and reports match percentage.

- **extract_include_binaries.py**: Extracts embedded binary data (images, assets) from disassembled code for inclusion via assembly `include()` directives.

### Directory Structure

- `original_ROMs/`: Original firmware dumps and reference disassembly (`.unidasm` files)
- `rebuilt_ROMs/`: Build output (created by make)
- `maincpu/images/`, `maincpu/includes/`: Binary image data included in main CPU ROM
- `table_data/images/`: BMP assets for feature demo
- `docs/`: Protocol analysis notes (control panel serial communication)

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
