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
```

The ASL assembler path is configured in the Makefile at `ASL_PATH`.

## Architecture

### ROM Components

| Component | Source | Status |
|-----------|--------|--------|
| maincpu | `maincpu/kn5000_v10_program.asm` (461K lines) | ~99.94% |
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
