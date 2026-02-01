# KN5000 ROM Analysis

This directory contains analysis documents from reverse engineering the Technics KN5000 firmware.

## Contents

| Directory | Description |
|-----------|-------------|
| [strings/](strings/) | String extraction and categorization from ROMs |

## Quick Links

### String Analysis
- **[Overview](strings/README.md)** - Executive summary of ROM string analysis
- **[Quick Reference](strings/quick-reference.md)** - Fast lookup of key strings with offsets
- **[Detailed Analysis](strings/detailed-analysis.md)** - Complete categorized string listing

## Analysis Methodology

All analyses are performed on the original ROM dumps in `original_ROMs/`. Address mappings:

| ROM | File Offset | CPU Address |
|-----|-------------|-------------|
| Main CPU | `0x000000` | `0xE00000` |
| Table Data | `0x000000` | `0x800000` |
| Sub CPU Boot | `0x000000` | `0xFE0000` |
| HDAE5000 | `0x000000` | `0x280000` |

## Related Documentation

- Project documentation: `../kn5000-docs/`
- Symbol reference files: `../symbols/`
- Disassembly source: `../maincpu/`, `../subcpu/`, `../table_data/`
