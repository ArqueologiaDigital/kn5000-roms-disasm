# Main CPU ROM String Analysis

**ROM File:** `original_ROMs/kn5000_v10_program.rom` (2 MB)
**Extraction Method:** `strings -n 8 -t x`
**Address Mapping:** CPU Address = File Offset + `0xE00000`
**Analysis Date:** 2026-01-27

## Key Findings

### Product Identification
- **Model:** KN5000 ~95 VOCALIST WORKSTATION
- **Manufacturer:** Technics
- **Total Strings Extracted:** 9,446 (8+ characters minimum)

### Firmware Capabilities Revealed

| Category | Count | Description |
|----------|-------|-------------|
| Instrument Banks | 14 | PIANO, GUITAR, STRINGS, BRASS, etc. |
| Menu Strings | 40+ | Sound edit menus (TT_* prefix) |
| Sequencer Functions | 20+ | Song/track management |
| Rhythm Patterns | 100+ | Diverse musical genres |
| Performance Modes | 8 | APC, Normal, Control |
| Panel Memory Presets | 8 | Memory 1-8 |
| Digital Effects | 10+ | Delay, Reverb, Chorus |

### Notable Observations

1. **No Error Messages Found** - Unusual for firmware; error handling may be dynamic
2. **No File Format Headers** - MIDI/WAVE signatures likely use binary patterns
3. **No Debug Strings** - Clean production ROM without development artifacts
4. **English Only** - No multi-language variants detected

## Critical String Locations

| Offset | CPU Address | Content |
|--------|-------------|---------|
| `0x00038` | `0xE00038` | File format headers (8 variants) |
| `0x023F0` | `0xE023F0` | Instrument bank catalog |
| `0x0C3BE` | `0xE0C3BE` | Chord type database |
| `0xCFDFE` | `0xECFDFE` | Keyboard layout & MIDI parts (32 parts) |
| `0x0D57A` | `0xE0D57A` | Sound edit menu system |
| `0x115B01` | `0xF15B01` | Digital effect types |
| `0x0FFEA1` | `0xEFFEA1` | APC mode configuration |

## Further Reading

- **[Quick Reference](quick-reference.md)** - Fast offset lookup for disassembly work
- **[Detailed Analysis](detailed-analysis.md)** - Complete categorized string listing

## How to Use

| Task | Document |
|------|----------|
| Get overview of ROM functionality | This file |
| Find specific string location | [Quick Reference](quick-reference.md) |
| Detailed analysis of ROM section | [Detailed Analysis](detailed-analysis.md) |
| Analyze menu system structure | Section 8 in Detailed Analysis |
| Map MIDI parts and channels | Section 7 in Detailed Analysis |

## Rhythm Pattern Genres

The ROM contains 100+ rhythm patterns spanning:

- **Latin/Cuban:** Guarania, Vaneirao, Rancheira, Frevo, Baiao
- **Ballroom/Dance:** Fox walk, Dance Band, Jive, Tango, Vienna Dance
- **Pop/Rock:** 8 Beat Pop, 70's Rock, 60's R&Roll, Twist
- **Jazz/Swing:** Simple Swing, Show Band, BigBand Slow, Accordion Jazz
- **Brazilian:** Samba, Bossanova, Modern Samba
- **Other:** Bolero, Mambo, Rhumba, Techno, Country Blues
