#!/usr/bin/env python3
"""Rename LABEL_F97* to semantic names and add documentation comments in fdc_routines.s.

Based on analysis of the FDC (Floppy Disk Controller) routines at address range
0xF96D54-0xF98009 in the maincpu program ROM. Each rename was verified by
analyzing the routine's code, register usage, called functions, and callers.

Also adds documentation comments to .byte blocks describing the encoded instructions
and their purpose.

Uses binary I/O to handle encoding safely.
"""

import os
import re

# Renames: (old_label, new_label, brief_comment)
RENAMES = [
    # Wait-ready timeout labels (460-534)
    ('LABEL_F97107', 'FDC_WaitReady_TimedOut',
     'Exit: check prevbank timeout flag, set status=2 if timed out'),
    ('LABEL_F97137', 'FDC_WaitStatus_CheckTimeout',
     'Check elapsed time vs 500-tick limit in status wait loop'),
    ('LABEL_F9714F', 'FDC_WaitStatus_TimedOut',
     'Exit: check prevbank timeout flag, set status=2 if timed out'),
    ('LABEL_F97159', 'FDC_WaitStatus_Complete',
     'Pop xiz and return from status wait'),

    # FDC result phase reader (537)
    ('LABEL_F9715B', 'FDC_ResultPhase_Read',
     'Read FDC result phase bytes into buffer at 35424 with timeout'),

    # FDC status decoder labels (584-648)
    ('LABEL_F9725F', 'FDC_StatusDecode_DriveNotReady',
     'IC=11: set error flag 35584=255, return 0'),
    ('LABEL_F97267', 'FDC_StatusDecode_InvalidCommand',
     'IC=10: return 0 (command was rejected by controller)'),
    ('LABEL_F9726A', 'FDC_StatusDecode_AbnormalTerm',
     'IC=01: check status register bits for specific error type'),
    ('LABEL_F97272', 'FDC_StatusDecode_Overrun',
     'Status bit 4: overrun error, return 0x32'),
    ('LABEL_F9727A', 'FDC_StatusDecode_CheckST2',
     'Load next result byte (ST2), check individual error bits'),
    ('LABEL_F97288', 'FDC_StatusDecode_BadCylinder',
     'ST2 bit 1: bad cylinder, set status=0x2F'),
    ('LABEL_F97293', 'FDC_StatusDecode_WrongCylinder',
     'ST2 bit 2: wrong cylinder, set status=0x33'),
    ('LABEL_F9729E', 'FDC_StatusDecode_ScanEqual',
     'ST2 bit 4: scan equal hit, set status=0x34'),
    ('LABEL_F972A9', 'FDC_StatusDecode_DataFieldError',
     'ST2 bit 5: data error in data field, set status=0x36'),
    ('LABEL_F972B4', 'FDC_StatusDecode_ControlMark',
     'ST2 bit 7: control mark detected, set status=0x37'),
    ('LABEL_F972BF', 'FDC_StatusDecode_DefaultError',
     'No recognized error bit set, set status=8'),
    ('LABEL_F972C5', 'FDC_StatusDecode_UnknownIC',
     'Unrecognized interrupt code in status byte, return error 8'),

    # FDC hardware setup (654)
    ('LABEL_F972C8', 'FDC_HardwareSetup',
     'Configure FDC I/O ports, validate format params, check DMA settings'),

    # FDC_Set_Status branch labels (762-778)
    ('LABEL_F975CA', 'FDC_SetStatus_MissingAddrMark',
     'Status 0x35 (missing address mark): nop, fall through to return'),
    ('LABEL_F975CD', 'FDC_SetStatus_DataFieldErr',
     'Status 0x36 (data field error): nop, fall through to return'),
    ('LABEL_F975D0', 'FDC_SetStatus_AlreadySet',
     'Status byte already non-zero, skip store, fall through to return'),
    ('LABEL_F975D1', 'FDC_SetStatus_Return',
     'Load status byte from 35364 into L and return'),
    ('LABEL_F975D6', 'FDC_ClearStatus_InitTimer',
     'Clear status to 0, init result buffer to 0xFF, start timeout timer'),

    # Delay loop (796)
    ('LABEL_F97621', 'SOME_DELAY_Loop',
     'Inner loop: poll timer, check elapsed ticks vs target in WA'),

    # Init/seek labels (807-819)
    ('LABEL_F97634', 'FDC_InitSequence_Short',
     'Load constant 0x28, jump to DMA setup exit'),
    ('LABEL_F97639', 'FDC_InitSequence_Full',
     'Full init: pulse PH0, clear flags, setup hardware, verify config'),
    ('LABEL_F97652', 'FDC_SeekRecalibrate',
     'Save head via prevbank, send recalibrate command, retry with seek'),

    # FDC command entry and parameter copy (1034-1051)
    ('LABEL_F97CCA', 'FDC_CommandEntry',
     'Push xiz, load params from stack, validate guard byte, dispatch command'),
    ('LABEL_F97CD9', 'FDC_CommandEntry_EnableIRQ',
     'Enable IRQ 6, check timeout guard=165, set status=0xFB if timed out'),
    ('LABEL_F97CEF', 'FDC_CommandEntry_CopyParams',
     'Copy 16 bytes from (xiz) to FDC state at 35392-35420, then dispatch'),

    # Handler dispatch exit labels (1190-1204)
    ('LABEL_F97DDB', 'FDC_Handler_InvalidCommand',
     'Unknown command index: set status=0xFF'),
    ('LABEL_F97DE1', 'FDC_Handler_ExitStatus',
     'Common handler exit: set guard=90, load status byte, sign-extend'),
    ('LABEL_F97DEC', 'FDC_Handler_Return',
     'Pop xiz and return from FDC handler'),
    ('LABEL_F97DEE', 'FDC_ByteTransfer_PIO',
     'Byte-at-a-time PIO transfer via I/O port at 0x120000'),

    # INT4 (FDCINT) handler labels (1250-1300)
    ('LABEL_F97E59', 'INT4_PollStatusLoop',
     'Poll FDC MSR for busy (RQM) bit with 100-iteration timeout'),
    ('LABEL_F97E6B', 'INT4_WaitDataReady',
     'Wait for MSR bit 7 (RQM) = 1 before reading data'),
    ('LABEL_F97E82', 'INT4_WaitNonDMAMode',
     'Wait for MSR upper nibble = 0x80 (non-DMA execution mode)'),
    ('LABEL_F97E8D', 'INT4_SendSpecifyCmd',
     'Send Specify command byte (0x08) to FDC data register'),
    ('LABEL_F97E93', 'INT4_StoreResultBase',
     'Load result buffer base at 35424 into xiz, increment pointer'),
    ('LABEL_F97E99', 'INT4_ReadResultLoop',
     'Read result bytes: wait status timeout, read data, store via pointer'),
    ('LABEL_F97EA2', 'INT4_WaitResultReady',
     'Wait for MSR RQM bit before reading next result byte'),
    ('LABEL_F97EBC', 'INT4_ExitRestore',
     'Clear result buffer byte 0, restore all regs, reti'),

    # Reset_Floppy_Disk_Controller helper labels (1337-1340)
    ('LABEL_F97F03', 'FDC_Reset_SetDD_SectorCount',
     'DD format: set sector count = 211 (0xD3)'),
    ('LABEL_F97F09', 'FDC_Reset_BuildParams',
     'Build 5 FDC parameter blocks and call FDC_CommandEntry for each'),
]

# Documentation comments to insert before .byte block labels
BLOCK_DOCS = {
    'FDC_Send_Command': [
        '; --- FDC_Send_Command: Write command byte to FDC data register ---',
        '; Stores accumulator A to FDC data port (0x110008),',
        '; waits for FDC ready via status register polling,',
        '; then returns. Uses (R+d16) addressing for FDC port access.',
    ],
    'FDC_WaitReady': [
        '; --- FDC_WaitReady: Wait for FDC ready with timeout and DMA transfer ---',
        '; Two-phase wait loop (masks 0x1F and 0x90) checking FDC status register.',
        '; Uses prevbank (D7 FA) for timeout flag management.',
        '; Contains 7-entry command dispatch (commands 0-5 + default):',
        ';   Each entry: stdi8 35436, N; calr <handler>; stdi16 35362, 0',
        '; Handles DMA channel setup, result status checking, and retry logic.',
        '; Timeout limit: 500 timer ticks (checked against timer at address 1033).',
        '; Uses (R+d16) addressing extensively for FDC port and state variable access.',
    ],
    'FDC_ResultPhase_Read': [
        '; --- FDC_ResultPhase_Read: Read FDC result phase data into buffer ---',
        '; Reads FDC status register in a loop, checking top 2 bits:',
        ';   0xC0 = command complete, 0x80 = data ready for transfer.',
        '; When data ready, reads byte from FDC and stores to buffer at 35424[index].',
        '; Includes timeout checking against timer at address 1033.',
        '; Contains 6 parameter-passing wrapper stubs at the end, each:',
        ';   dec 2,xsp / ld (xsp),a / calr <func> / ld a,(xsp) / extz wa /',
        ';   calr <store> / inc 2,xsp / ret',
        '; Uses (R+d16) and dec/inc xsp addressing (not in LLVM).',
    ],
    'FDC_HardwareSetup': [
        '; --- FDC_HardwareSetup: Configure FDC I/O ports and validate parameters ---',
        '; Section 1: I/O register initialization (3x ldio/mask/set/store sequences)',
        ';   for FDC-related I/O port configuration.',
        '; Section 2: Format type validation - cascading cp/jr checks against',
        ';   format codes (0x33, 0x34, 0x35, 0x36, 0x47, 0x4F, etc.).',
        '; Section 3: Format parameter loading - sector size, head count,',
        ';   track count from memory locations 35369-35386.',
        '; Section 4: DMA parameter validation - checks that sector count,',
        ';   byte count, buffer pointers are non-zero before proceeding.',
        '; Returns: HL=0xFFFF on failure, 0 on success.',
        '; Uses ldio, (R+d16) addressing. 460 bytes.',
    ],
    'FDC_ClearStatus_InitTimer': [
        '; --- FDC_ClearStatus_InitTimer: Clear FDC status and start timeout ---',
        '; Clears FDC status byte (35364) to 0, initializes result buffer (35424)',
        '; to 0xFF, saves prevbank state, starts timer-based timeout loop.',
        '; Polls with cps bc, 0 for completion signal.',
        '; Uses prevbank (D7 FA) for timer state management.',
    ],
    'FDC_SeekRecalibrate': [
        '; --- FDC_SeekRecalibrate: Seek/recalibrate FDC head position ---',
        '; Saves current head number via prevbank register.',
        '; Sets head = 5 (recalibrate parameter), sends FDC command,',
        '; checks result status. If error, retries with seek command.',
        '; Second section loads command byte 0xC6 (Read ID) for verification.',
        '; Contains error checking and retry logic with FDC_Set_Status calls.',
        '; Restores head number from prevbank on exit.',
    ],
    'FDC_CMD_EXEC': [
        '; --- FDC_CMD_EXEC: Main FDC command execution engine ---',
        '; Two nearly identical halves: READ path (command type 1) and',
        '; WRITE path (command type 8), set in state variable 35432.',
        '; Each path:',
        ';   1. Clears status, waits for FDC ready',
        ';   2. Sets up DMA: clear byte counter (35356), compute sector size',
        ';      (1024 or 512 based on format), configure DMA direction',
        ';   3. Sector loop: decrement sector count, advance track/head,',
        ';      check against max sectors (35596)',
        ';   4. Accumulates transferred sector count at 35402',
        ';   5. Error handling: sets error flag (35588=255) on failure',
        '; Tail calls format-specific routines and status verification.',
        '; Uses (R+d16) addressing for all FDC state variable access. 672 bytes.',
    ],
    'FDC_MODE_CONFIG': [
        '; --- FDC_MODE_CONFIG: Configure FDC format parameters by disk type ---',
        '; Reads format type from state variable 35436.',
        '; Dispatch by type: 0=default, 2=MFM, 3/4/5 = other formats.',
        '; Sets per-format parameters:',
        ';   35374: sectors per track (2 or 3)',
        ';   35379: bytes per sector code (80/108/116 = 128/256/512 bytes)',
        ';   35382: head number, 35371: track number, 35380: gap length (0xE5)',
        ';   35372: side number, 35369: drive number',
        '; Then enters sector counting/validation loop.',
        '; Uses (R+d16) addressing for all state variables. 184 bytes.',
    ],
    'FDC_MC_EXIT': [
        '; --- FDC_MC_EXIT: FORMAT command execution and sector fill ---',
        '; Calls cleanup, sets up FORMAT command (command byte 0x4D).',
        '; Loads format buffer address from 35440, stores to DMA source (35404).',
        '; Main loop fills format buffer with [track, head, sector, size] tuples:',
        ';   For each sector: load index, compute buffer[index] address,',
        ';   store track/head/sector/size bytes, increment byte count (35356).',
        '; Handles odd sector counts separately.',
        '; Tail: DMA transfer initiation and multi-sector retry logic.',
        '; Uses (R+d16) addressing for buffer and state access. 536 bytes.',
    ],
    'FDC_STATUS_COPY': [
        '; --- FDC_STATUS_COPY: Copy FDC status and validate drive count ---',
        '; Copies status from source to destination via (R+d16) load/store.',
        '; Validates drive count (35396): 0 or 1 are valid, else error 0xFE.',
        '; Three exit paths with disk-changed flag (35434) management:',
        ';   Set flag (35434=255) or clear flag (35434=0).',
    ],
    'FDC_INTERRUPT_HANDLER': [
        '; --- FDC_INTERRUPT_HANDLER: FDC interrupt service routine ---',
        '; Enables interrupts via prevbank (D7 FA 04 = ei 4).',
        '; Checks FDC status register, reads result data.',
        '; Tests status bits to determine result type:',
        ';   bit 7 → status 0x32 (overrun), bit 5 → status 0x31 (no data),',
        ';   bit 6 → status 0x2F (bad cylinder).',
        '; Disables interrupts (D7 FA 05 = di 4) before return.',
    ],
    'FDC_ByteTransfer_PIO': [
        '; --- FDC_ByteTransfer_PIO: Byte-at-a-time PIO data transfer ---',
        '; Checks if byte count (35356) is zero; returns immediately if so.',
        '; Dispatches by command type (35392):',
        ';   Command 3 (READ):  read from I/O port 0x120000 → buffer at 35406',
        ';   Command 4 (WRITE): read from buffer at 35406 → I/O port 0x120000',
        '; Increments buffer pointer (35406) after each byte.',
        '; Falls through to transfer completion handlers.',
    ],
}


def main():
    base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    fdc_src = os.path.join(base, 'maincpu', 'fdc_routines.s')
    main_src = os.path.join(base, 'maincpu', 'kn5000_v10_program.s')

    # Read both files (fdc_routines.s is UTF-8, main program is Latin-1)
    with open(fdc_src, 'rb') as f:
        fdc_content = f.read().decode('utf-8')

    with open(main_src, 'rb') as f:
        main_content = f.read().decode('latin-1')

    # --- Phase 1: Rename labels ---
    fdc_renamed = 0
    main_renamed = 0

    for old_label, new_label, comment in RENAMES:
        if old_label + ':' not in fdc_content and old_label not in fdc_content:
            # Check if it's a reference-only label (defined elsewhere)
            if old_label in main_content:
                pass  # Will handle in maincpu pass
            else:
                print(f'  WARNING: {old_label} not found anywhere, skipping')
                continue

        # Count and replace in fdc_routines.s
        fdc_refs = len(re.findall(r'\b' + re.escape(old_label) + r'\b', fdc_content))
        if fdc_refs > 0:
            fdc_content = re.sub(r'\b' + re.escape(old_label) + r'\b', new_label, fdc_content)
            fdc_renamed += 1
            print(f'  {old_label:25s} -> {new_label:40s} ({fdc_refs} fdc refs)', end='')

        # Count and replace in kn5000_v10_program.s
        main_refs = len(re.findall(r'\b' + re.escape(old_label) + r'\b', main_content))
        if main_refs > 0:
            main_content = re.sub(r'\b' + re.escape(old_label) + r'\b', new_label, main_content)
            main_renamed += 1
            print(f' ({main_refs} main refs)', end='')

        if fdc_refs > 0 or main_refs > 0:
            print()

    # --- Phase 2: Add documentation comments ---
    lines = fdc_content.split('\n')
    docs_added = 0

    for label, comments in BLOCK_DOCS.items():
        # Find label definition
        label_idx = None
        for i, line in enumerate(lines):
            stripped = line.strip()
            if stripped == label + ':' or stripped.startswith(label + ':'):
                label_idx = i
                break

        if label_idx is None:
            print(f'  WARNING: label {label} not found for documentation')
            continue

        # Check if documentation already exists (avoid double-insertion)
        if label_idx > 0 and lines[label_idx - 1].strip().startswith('; ---'):
            print(f'  SKIP: {label} already has documentation')
            continue

        # Insert comments before label
        for j, comment in enumerate(comments):
            lines.insert(label_idx + j, comment)

        docs_added += 1
        print(f'  Added {len(comments)}-line doc comment before {label}')

    fdc_content = '\n'.join(lines)

    # --- Phase 3: Write files ---
    with open(fdc_src, 'wb') as f:
        f.write(fdc_content.encode('utf-8'))

    if main_renamed > 0:
        with open(main_src, 'wb') as f:
            f.write(main_content.encode('latin-1'))

    print(f'\nRenamed {fdc_renamed} labels in fdc_routines.s')
    print(f'Renamed {main_renamed} labels in kn5000_v10_program.s (cross-refs)')
    print(f'Added {docs_added} documentation blocks')


if __name__ == '__main__':
    main()
