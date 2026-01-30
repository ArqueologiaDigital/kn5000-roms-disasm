# MAME KN5000 Driver - Known Issues and Fixes

## Overview

This document describes known issues with the MAME KN5000 driver and proposes fixes based on reverse engineering of the actual firmware.

## Issue 1: Sub CPU Payload Transfer Not Working

### Symptoms
- Sub CPU never receives payload
- Sub CPU stays in boot ROM polling loop forever
- Sound synthesis never starts

### Root Cause Analysis

The boot sequence should work as follows:

1. **Main CPU releases Sub CPU from reset** (`SET 0, (PA)` at 0xEF05F3)
2. **Main CPU sets up DMA channels** (`CALL SubCPU_Init_DMA_Channels`)
3. **Main CPU sends payload** (`CALR SubCPU_Send_Payload`)
4. **Sub CPU receives E3 command**, sets bit 6 of 0x04FE
5. **Sub CPU boot ROM calls payload** at 0x000400

### Problem: Subprogram Data Location

The main CPU code at `SubCPU_Send_Payload` reads subprogram data from:
- 0x830000-0x870000 (table_data ROM region)
- 0x800100+ (table_data ROM region)

However, the table_data ROMs (IC1, IC3) appear to contain data tables, not the subprogram code. The subprogram files were extracted from system update floppy disks (LZSS compressed), suggesting:

1. The subprogram may be stored in custom_data flash (IC19) in compressed form
2. Or the table_data region is meant to be programmed by the system update process
3. Or there's an alternate boot path we haven't found

### Investigation Needed

1. **Verify data at 0x830000**: Dump the actual bytes the main CPU reads during boot
2. **Check custom_data flash**: The 1MB flash at IC19 may contain compressed subprogram
3. **Find decompression code**: Look for LZSS decompression in the main CPU ROM

### Temporary Workaround (NOT RECOMMENDED - Violates Accuracy Policy)

Do NOT implement HLE shortcuts like preloading the payload into Sub CPU RAM. This violates the project's strict accuracy policy.

## Issue 2: Inter-CPU Communication

### Current Implementation (Correct)

```cpp
// Latches
GENERIC_LATCH_8(config, m_maincpu_latch);
m_maincpu_latch->data_pending_callback().set_inputline(m_maincpu, TLCS900_INT0);

GENERIC_LATCH_8(config, m_subcpu_latch);
m_subcpu_latch->data_pending_callback().set_inputline(m_subcpu, TLCS900_INT0);
```

### Verification Steps

1. Ensure `generic_latch_8_device::data_pending_callback` fires correctly
2. Verify INT0 is enabled on both CPUs (requires `EI` instruction execution)
3. Check that the latch read clears the pending flag appropriately

## Issue 3: MicroDMA Support

### Required Functionality

The TMP94C241 uses MicroDMA channels for inter-CPU transfers:

**Main CPU DMA Setup** (at 0xEF329E):
```asm
LDA XWA, INTER_CPU_COMM_LATCHES  ; 0x140000
LDC_DMAD2_XWA                     ; DMA dest 2 = latch
LDC_DMAS0_XWA                     ; DMA source 0 = latch
```

**Sub CPU DMA Setup** (at 0xFF85DF):
```asm
LDA XWA, 0x120000                 ; Latch address
LDC DMAS0, XWA                    ; DMA source 0 = latch
LDC DMAS2, XWA                    ; DMA source 2 = latch
```

### Verification

1. Verify `tmp94c241_device` implements MicroDMA correctly
2. Check DMA can read from latch addresses
3. Ensure DMA completion triggers appropriate interrupts

## Issue 4: Handshake Signals

### Port Connections

| Signal | Main CPU | Sub CPU |
|--------|----------|---------|
| MSTAT0 | Port Z bit 0 (out) | Port D bit 2 (in) |
| MSTAT1 | Port Z bit 1 (out) | Port D bit 4 (in) |
| SSTAT0 | Port Z bit 2 (in) | Port D bit 0 (out) |
| SSTAT1 | Port Z bit 3 (in) | Port D bit 1 (out) |

### Current Implementation (Correct)

```cpp
// Main CPU Port Z
m_maincpu->portz_read().set([this] {
    return m_com_select->read() | (m_sstat << 2);
});
m_maincpu->portz_write().set([this] (u8 data) {
    m_mstat = data & 3;
});

// Sub CPU Port D
m_subcpu->portd_read().set([this] {
    return (BIT(m_mstat, 0) << 2) | (BIT(m_mstat, 1) << 4);
});
m_subcpu->portd_write().set([this] (u8 data) {
    m_sstat = data & 3;
});
```

This appears correct.

## Debug Strategy

### Step 1: Verify Main CPU Boot Progress

Set breakpoints at:
- 0xEF03C6: RESET_HANDLER start
- 0xEF05F3: Sub CPU reset release (`SET 0, (PA)`)
- 0xEF068A: Payload transfer start
- 0xEF3398: E1 command send

If execution doesn't reach 0xEF068A, there's an earlier boot issue.

### Step 2: Verify Sub CPU Interrupt

Set breakpoints at:
- 0xFF8290: Boot ROM main entry
- 0xFF881F: INT0 handler
- 0xFF886C: E3 command handler (sets bit 6)
- 0xFF8418: Payload call

If INT0 handler is never called, the latch/interrupt connection is broken.

### Step 3: Watch Memory

- Sub CPU 0x04FE: PAYLOAD_LOADED_FLAG (bit 6 should be set)
- Main CPU latch writes at 0x140000
- Sub CPU latch reads at 0x120000

## References

- `docs/subcpu_boot_protocol.md`: Detailed protocol analysis
- `docs/subcpu_boot_rom_analysis.md`: Boot ROM code analysis
- `maincpu/kn5000_v10_program.asm`: Main CPU disassembly
- `CLAUDE.md`: Project policies including accuracy requirements
