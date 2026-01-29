# KN5000 ROM Disassembly Priority Plan

This document outlines the prioritized plan for disassembling remaining raw byte blocks and undocumented binary includes. Priorities are based on knowledge gain potential for MAME emulation and homebrew development.

## Current Status Summary

| Component | File Size | Disassembled | Raw Bytes | LABEL_* Count |
|-----------|-----------|--------------|-----------|---------------|
| **HDAE5000** | 512 KB | ~5% | ~486 KB | 0 (skeleton + labels) |
| **Main CPU** | 2 MB | ~99.9% | 48 KB | 37,624 |
| **Sub CPU Payload** | 192 KB | 100% | 0 | 3,249 |
| **Sub CPU Boot** | 128 KB | ~99% | 0 | 0 |
| **Table Data** | 2 MB | ~32% | N/A (data) | 4 |

---

## Priority 1: HDAE5000 ROM (HIGHEST - ~486 KB undisassembled)

**Why highest priority:**
- Contains HD expansion audio processor communication protocol
- PPI (8255-compatible) programming for DSP interface
- File system operations (SMF loading, song storage)
- Understanding this enables HDAE5000 emulation

**Progress made:**
- ✅ ROM header and entry points documented
- ✅ Boot initialization routine analyzed and documented (0x28F576)
- ✅ Frame handler entry point documented (0x28F662)
- ✅ PPORT command jump table extracted (12 handlers at 0x2953E2)
- ✅ PPORT menu strings extracted (21 strings at 0x295412)
- ✅ Key routine addresses identified (~40 routines)
- ✅ RAM workspace variables documented
- ✅ Binary files split into logical sections

**Binary includes (current state):**

| File | Size | Address Range | Status |
|------|------|---------------|--------|
| `code_280020_28f575.bin` | 62.8 KB | 0x280020-0x28F575 | Documented (needs disasm) |
| `boot_init_28f576_28f661.bin` | 236 B | 0x28F576-0x28F661 | Fully documented |
| `code_28f662_2953e1.bin` | 23.4 KB | 0x28F662-0x2953E1 | Documented (needs disasm) |
| `pport_cmd_table_2953e2_295411.bin` | 48 B | 0x2953E2-0x295411 | ✅ Fully documented |
| `pport_strings_295412_295641.bin` | 560 B | 0x295412-0x295641 | ✅ Fully documented |
| `code_295642_2fffff.bin` | 427 KB | 0x295642-0x2FFFFF | Needs analysis |

**Next steps:**
- Disassemble `code_280020_28f575.bin` (code section 1)
- Disassemble `code_28f662_2953e1.bin` (frame handler routines)
- Analyze PPORT command handler implementations

**Expected knowledge gain:**
- DSP command protocol (via PPI at 0x160000)
- Waveform loading mechanism
- MIDI file playback engine
- Hard disk file system structure

---

## Priority 2: Sub CPU Payload 0x03XXXX Region (HIGH - 1,702 routines)

**Why high priority:**
- Largest concentration of undocumented routines
- Likely contains audio synthesis core
- Effects processing (reverb, chorus, etc.)
- Critical for accurate sound emulation

**Address range:** 0x030000 - 0x03FFFF

**Expected knowledge gain:**
- Tone generator control
- Real-time audio processing algorithms
- Effects parameter handling
- Voice allocation logic

---

## Priority 3: Sub CPU Payload 0x02XXXX Region (HIGH - 1,432 routines)

**Why high priority:**
- Contains command dispatch and processing
- Inter-CPU protocol handlers
- MIDI event processing

**Address range:** 0x020000 - 0x02FFFF

**Key routines already identified:**
- `MICRODMA_CH0_HANDLER` at 0x020F1F
- `MICRODMA_CH2_HANDLER` at 0x020F01
- `INT0_HANDLER` (command receiver)

**Expected knowledge gain:**
- Complete command protocol documentation
- State machine details
- Audio engine control interface

---

## Priority 4: Main CPU Data Tables (MEDIUM - 48 KB)

**Why medium priority:**
- Primarily data structures, not code
- Some may be instrument/patch definitions
- Useful for understanding keyboard configuration

**Key binary includes:**

| File | Size | Description |
|------|------|-------------|
| `e02510_e0458f.bin` | 8.3 KB | Instrument category data |
| `e04590_e04b2f.bin` | 1.4 KB | Unknown data structure |
| `e04b30_e06baf.bin` | 8.3 KB | Unknown data structure |
| `e09150_e0adcf.bin` | 7.3 KB | Unknown data structure |
| `e0bb90_e0c95a.bin` | 3.5 KB | Unknown data structure |

**Expected knowledge gain:**
- Instrument definitions
- Preset configurations
- UI string tables

---

## Priority 5: Main CPU LABEL_* Renaming (LOWER - 37,624 symbols)

**Why lower priority:**
- Code is already disassembled
- Symbol renaming improves readability but doesn't unlock new understanding
- Can be done incrementally as routines are analyzed

**Focus areas by subsystem:**

| Subsystem | Address Range | LABEL_* Count (est.) |
|-----------|---------------|----------------------|
| Boot/Init | 0xEF0000-0xEF1FFF | ~100 |
| VGA Display | 0xEF5000-0xEF6FFF | ~200 |
| Control Panel | 0xFC3E00-0xFC7FFF | ~500 |
| FDC | 0xF97000-0xF99FFF | ~300 |
| MIDI | 0xE80000-0xE8FFFF | ~1,000 |

---

## Priority 6: Sub CPU Payload LABEL_* Renaming (LOWER - 3,249 symbols)

**Address distribution:**

| Range | Count | Likely Purpose |
|-------|-------|----------------|
| 0x03XXXX | 1,702 | Audio processing |
| 0x02XXXX | 1,432 | Command handlers |
| 0x01XXXX | 87 | Initialization |
| 0x00XXXX | 27 | Interrupt vectors |

---

## Execution Plan

### Phase A: HDAE5000 Disassembly (Highest Impact)

1. **A1**: Analyze `code_280020_28f575.bin` - main code section
   - Use unidasm for initial disassembly
   - Identify entry points and jump tables
   - Document PPI communication routines

2. **A2**: Analyze `boot_init_28f576_28f661.bin` - boot initialization
   - Small section, quick win
   - Document hardware setup sequence

3. **A3**: Analyze `code_28f662_2fffff.bin` - bulk code
   - Largest section
   - Break into logical blocks based on control flow

### Phase B: Sub CPU Audio Engine (High Impact)

4. **B1**: Document tone generator routines in 0x03XXXX
5. **B2**: Map effects processing chain
6. **B3**: Document voice allocation

### Phase C: Sub CPU Command Protocol (High Impact)

7. **C1**: Complete INT0_HANDLER analysis
8. **C2**: Document E1/E2/E3 command handling
9. **C3**: Map state machine transitions

### Phase D: Data Structure Analysis (Medium Impact)

10. **D1**: Analyze instrument category data
11. **D2**: Document preset formats
12. **D3**: Map UI configuration tables

### Phase E: Symbol Cleanup (Ongoing)

- Rename LABEL_* as routines are understood
- Add header comments to documented routines
- Update documentation website

---

## Metrics for Tracking Progress

| Metric | Current | Target |
|--------|---------|--------|
| HDAE5000 disassembled | ~5% | 100% |
| HDAE5000 routines documented | ~45 | ~500 |
| Sub CPU LABEL_* renamed | ~110 | 3,249 |
| Main CPU LABEL_* renamed | ~500 | 37,624 |
| Binary includes documented | 8 | 97 |

---

## Notes

- Each disassembly phase should be followed by documentation website updates
- Use `make all` after each change to verify no regressions
- Cross-reference with service manual schematics for hardware understanding
- HDAE5000 block diagram in service manual shows PPI connections

