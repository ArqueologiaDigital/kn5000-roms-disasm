# Scripts Directory

Helper scripts for the KN5000 ROM disassembly project, organized by function.

## Directory Structure

| Directory | Count | Purpose |
|-----------|-------|---------|
| `build/` | 7 | Build utilities: ROM comparison, LZSS compression, image conversion, issue export, status diagrams |
| `converters/` | 32 | Format converters: ASL-to-LLVM, .byte-to-native, NAKA widget struct conversion, pointer tables |
| `generators/` | 12 | Code generators: screendata, SSF gate states, NAKA linker scripts, synthetic waveforms |
| `renaming/` | 115 | Label renaming scripts (historical, one per batch) |
| `analysis/` | 24 | Analysis and extraction: symbol extraction, font/icon extraction, DSP disassembly, docs sync |
| `tools/` | 27 | Standalone utilities: cleanup, formatting, annotation, string merging, file splitting |

## Key Scripts

### Build (referenced by Makefile)
- `build/compare_roms.py` — Post-build verification (byte-by-byte comparison against originals)
- `build/compress_lzss.py` — LZSS compression for preset data
- `build/convert_images.py` — Convert gallery images for documentation website
- `build/generate_rom_status_diagram.py` — SVG visualization of disassembly progress

### Converters
- `converters/asl_to_llvm.py` — ASL-to-LLVM assembly converter (~4550 lines)
- `converters/convert_byte_to_native.py` — Convert .byte fallbacks to native TLCS-900 instructions
- `converters/naka_struct_decode.py` — Decode NAKA widget binary data into C structs
- `converters/naka_to_c.py` — Convert NAKA widget assembly to C source files

### Analysis
- `analysis/sync_docs_labels.py` — Synchronize label names between disassembly and documentation website
- `analysis/extract_symbols_from_map.py` — Extract symbol reference files from ASL map files
- `analysis/audit_byte_code.py` — Audit remaining .byte code sequences
