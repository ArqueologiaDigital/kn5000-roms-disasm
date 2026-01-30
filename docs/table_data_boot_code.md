# Table Data ROM Boot Code Analysis

## Discovery

The table_data ROM contains a **first-stage bootloader** that runs before the main program ROM. This explains the previously mysterious memory map reconfiguration during boot.

## Evidence

### 1. Interrupt Vectors in Table Data ROM

At offset 0x1FFF00 (would map to 0xFFFF00 if ROM is at 0xE00000):

```
Vector 0 (Reset): 0x00FFFEE0  → Table data boot entry
Vector 1-43:      0x00FFB705  → Common handler in table data
```

### 2. Reset Entry Point (0xFFFEE0)

At table_data offset 0x1FFEE0:
```
1B E8 B4 FF 0E    ; JP 0x0EFFB4E8 (jump to boot code)
```

### 3. Boot Code at 0xFFB4E8

The boot code configures the TMP94C241's memory controller:

```asm
; Memory Start Address Registers
LD (MSAR0), 0x1E    ; Block 0 at 0x1E0000
LD (MSAR1), 0x10    ; Block 1 at 0x100000
LD (MSAR2), 0xC0    ; Block 2 at 0xC00000
LD (MSAR3), 0x00    ; Block 3 at 0x000000
LD (MSAR4), 0x80    ; Block 4 at 0x800000 (table_data)
LD (MSAR5), 0x00    ; Block 5 at 0x000000

; Memory Address Mask Registers
LD (MAMR0), 0x0F    ; Block 0 mask
LD (MAMR1), 0x3F    ; Block 1 mask
LD (MAMR2), 0x7F    ; Block 2 mask
LD (MAMR3), 0x1F    ; Block 3 mask
LD (MAMR4), 0xFF    ; Block 4 mask
LD (MAMR5), 0xFF    ; Block 5 mask

; DRAM Controller
LD (DRAM1REF), 0x81
LD (DRAM1REF), 0x71
LD (DRAM1CRL), 0x8B
LD (DRAM1CRH), 0x58
LD (PMEMCR), 0xF1
```

### 4. Values Match Main Program ROM

The main program ROM at lines 134224-134235 sets the EXACT SAME values for MSAR/MAMR registers. This is redundant - the table_data boot code already configured them.

## Boot Sequence

```
┌─────────────────────────────────────────────────────────────┐
│                      CPU RESET                               │
│  Default mapping: Table data at 0xE00000-0xFFFFFF           │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              RESET VECTOR (0xFFFF00)                         │
│  Table data offset 0x1FFF00                                  │
│  Points to 0xFFFEE0 (table data offset 0x1FFEE0)            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│           TABLE DATA BOOT CODE (0xFFB4E8)                    │
│  1. Initialize CPU hardware                                  │
│  2. Configure MSAR/MAMR registers                            │
│  3. Set up DRAM controller                                   │
│  4. REMAP: Program ROM → 0xE00000, Table data → 0x800000    │
│  5. Jump to program ROM entry (0xEF03C6)                    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│           PROGRAM ROM RESET HANDLER (0xEF03C6)               │
│  Normal boot continues with program ROM at 0xE00000          │
└─────────────────────────────────────────────────────────────┘
```

## Implications for MAME Driver

### Current (Incorrect) Mapping

```cpp
map(0x800000, 0x9fffff).rom().region("table_data", 0);
map(0xe00000, 0xffffff).rom().region("program", 0);
```

This assumes program ROM is always at 0xE00000, which is only true AFTER the memory controller is configured.

### Required Fix

The MAME driver needs to:

1. **On reset**: Map table_data ROM at 0xE00000-0xFFFFFF
2. **Emulate MSAR/MAMR writes**: When the boot code writes to memory controller registers, update the address mapping
3. **After reconfiguration**: Program ROM becomes visible at 0xE00000, table_data at 0x800000

### Alternative Workaround

If implementing dynamic remapping is complex, a simpler workaround:

1. Start execution at the table_data reset vector
2. Let it configure memory controller
3. Have the memory controller writes trigger the address map reconfiguration

## Subprogram Location Mystery Solved

This also explains why the subprogram is NOT at table_data offset 0x30000:

- Offset 0x30000 in table_data = address 0x830000 (AFTER remap)
- But during boot, table_data is at 0xE00000, so offset 0x30000 = 0xE30000
- The code at 0x830000+ is table_data's own data, not the subprogram

The subprogram must be stored in:
- Custom data flash (IC19) - possibly LZSS compressed
- Or loaded from floppy disk during system updates
- Or in a different region of the table_data ROM

## Further Research Needed

1. Trace the exact jump from table_data boot code to program ROM
2. Identify where the subprogram is actually stored
3. Implement proper memory controller emulation in MAME
4. Verify the default reset memory mapping on real hardware
