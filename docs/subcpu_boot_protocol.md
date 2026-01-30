# Sub CPU Boot ROM Protocol Analysis

## Overview

The Sub CPU boot ROM implements a DMA-based protocol for receiving payload from the Main CPU via inter-CPU latches. This document describes the exact hardware behavior required for accurate MAME emulation.

## Hardware Components

### Inter-CPU Latches
| Direction | Main CPU Address | Sub CPU Address | IC |
|-----------|------------------|-----------------|-----|
| Main→Sub | 0x140000 (write) | 0x120000 (read) | IC22 |
| Sub→Main | 0x140000 (read) | 0x120000 (write) | IC23 |

### Status Signals
| Signal | Main CPU | Sub CPU | Purpose |
|--------|----------|---------|---------|
| MSTAT0 | Port Z bit 0 (out) | Port D bit 2 (in) | Handshake signal 0 |
| MSTAT1 | Port Z bit 1 (out) | Port D bit 4 (in) | Handshake signal 1 |
| SSTAT0 | Port Z bit 2 (in) | Port D bit 0 (out) | Handshake signal 0 |
| SSTAT1 | Port Z bit 3 (in) | Port D bit 1 (out) | Handshake signal 1 |

### Interrupts
- **INT0**: Fires when data arrives in the latch (data pending callback)
- Connected via `generic_latch_8_device::data_pending_callback`

## Boot ROM Code Regions

| Address Range | Purpose |
|---------------|---------|
| 0xFF8290-0xFF83F8 | Hardware initialization |
| 0xFF83F9-0xFF8430 | Main polling loop |
| 0xFF846D-0xFF848F | Initial stub copy to RAM |
| 0xFF85AE-0xFF8603 | DMA channel configuration |
| 0xFF8604-0xFF86AB | E2/E3 command handlers |
| 0xFF874C-0xFF881E | E1 bulk transfer handler |
| 0xFF881F-0xFF8899 | INT0 handler (latch receive) |
| 0xFF8F6C-0xFF904C | Interrupt vector stubs (copied to 0x000400) |

## Boot Sequence

### 1. Reset Vector (0xFFFF00 → 0xFFFEE0 → 0xFF8290)
CPU starts at reset vector which jumps to boot code at 0xFF8290.

### 2. Hardware Initialization (0xFF8290-0xFF83F8)
- Configure interrupt priorities
- Initialize timers
- Set up port directions
- Configure serial interfaces

### 3. Initial Stub Copy (0xFF846D-0xFF848F)
```asm
ff846d: ld XDE,0x00000400   ; Destination: RAM at 0x000400
ff8472: ld XHL,0x00ff8f6c   ; Source: Boot ROM stub code
ff8477: ld XBC,0x000000e1   ; Count: 225 bytes
ff8480: ldir                 ; Block copy
```
Copies placeholder interrupt handlers to RAM. These stubs just jump back to boot ROM until real payload arrives.

### 4. DMA Channel Configuration (0xFF85AE-0xFF8603)
```asm
ff85df: lda XWA,0x120000     ; Latch address
ff85f1: ldc DMAS0,XWA        ; Set DMA channel 0 source to latch
ff85f4: ld A,0x00
ff85f6: ldc unknown,A        ; Configure DMA mode
```
Configures MicroDMA channels 0 and 2 to read from the latch address.

### 5. Main Polling Loop (0xFF8410-0xFF8430)
```asm
ff840c: res 6,(0x04fe)       ; Clear PAYLOAD_LOADED_FLAG bit 6
ff8410: bit 6,(0x04fe)       ; Poll bit 6
ff8414: jr Z,0xff841c        ; If not set, skip call
ff8416: ei 0x06              ; Enable interrupts level 6
ff8418: call 0x000400        ; CALL PAYLOAD ENTRY POINT
ff841c: ...                   ; Status signal processing
ff8430: jr T,0xff8410        ; Loop back
```

## INT0 Handler Protocol (0xFF881F-0xFF8899)

When data arrives in the latch, INT0 fires and the handler processes the command:

```asm
ff881f: push XWA
ff8820: bit 2,(0x34)         ; Check if busy (Port Z bit 2)
ff8823: jr NZ,0xff8898       ; If busy, skip processing
ff8825: ld A,(0x120000)      ; Read command byte from latch
ff882a: ld (0x051a),A        ; Store for later processing
ff882e: cp A,0xe1            ; E1 command?
ff8831: jr NZ,0xff884a
        ; E1: Set up DMA for 6-byte header
        ...
ff884a: cp A,0xe2            ; E2 command?
ff884d: jr NZ,0xff8867
        ; E2: Set up DMA for 10-byte header
        ...
ff8867: cp A,0xe3            ; E3 command? (CRITICAL!)
ff886a: jr NZ,0xff8872
ff886c: set 6,(0x04fe)       ; **SET PAYLOAD_LOADED_FLAG BIT 6**
ff8870: jr T,0xff8895        ; Cleanup and return
ff8872: ; Default: data packet
        ...
ff8895: res 1,(0x34)         ; Clear handshake flag
ff8898: pop XWA
ff8899: reti
```

### Command Protocol

| Command | Byte | Action |
|---------|------|--------|
| E1 | 0xE1 | Bulk data transfer header (6 bytes: dest addr + count) |
| E2 | 0xE2 | Extended transfer header (10 bytes) |
| E3 | 0xE3 | **Payload complete - sets bit 6 of 0x04FE** |
| Other | 0x00-0xDF | Data packet (size encoded in lower 5 bits) |

### Key Variables

| Address | Purpose |
|---------|---------|
| 0x04FE | PAYLOAD_LOADED_FLAG (bit 6 = payload ready, bit 7 = transfer active) |
| 0x0512 | DMA source pointer |
| 0x0516 | Transfer state (0=idle, 1=waiting, 2=active) |
| 0x0518 | Command state (1=data, 2=E1 phase1, 3=E2, 4=E1 phase2) |
| 0x051A | Last received command byte |

## MAME Implementation Requirements

### What Must Work Correctly

1. **Latch data pending → INT0**: When main CPU writes to 0x140000, INT0 must fire on Sub CPU

2. **Latch read at 0x120000**: Sub CPU must be able to read the byte that main CPU wrote

3. **E3 command sets flag**: When 0xE3 is received, bit 6 of 0x04FE must be set

4. **Main loop polls flag**: The boot ROM main loop must see bit 6 and call payload

### Verification Steps

1. Put breakpoint at Sub CPU 0xFF881F (INT0 handler)
2. Verify it fires when main CPU writes to latch
3. Verify 0xE3 command eventually arrives
4. Verify bit 6 of 0x04FE gets set
5. Verify `call 0x000400` executes

### Current MAME Driver Status

The driver has correct hardware connections:
- `generic_latch_8_device` for latches with data_pending → INT0
- Port D correctly maps MSTAT signals
- Port Z outputs SSTAT signals

Potential issues:
1. Main CPU may not complete payload transfer protocol
2. DMA transfers from latch may not work with `generic_latch_8_device`
3. Timing issues between CPUs

### Debug Strategy

1. Enable MAME debugger
2. Set breakpoint at Sub CPU 0xFF881F
3. Observe if INT0 ever fires
4. If not: problem is in latch or interrupt connection
5. If yes: trace which command bytes are received

## Timeout Values

The boot ROM uses 0xEA60 (60000) as timeout counter in wait loops:
```asm
ff8697: cp HL,0xea60          ; Timeout check
ff869b: jr ULE,0xff864f       ; Continue waiting if not timed out
```

This appears throughout all handshaking wait loops.

## Main CPU Payload Transfer Code

### Boot Sequence Location

The main CPU boot sequence is at `RESET_HANDLER` (0xEF03C6):

1. `LD (PA), 0feh` - Holds Sub CPU in reset (bit 0 = 0)
2. ... hardware init ...
3. `SET 0, (PA)` at 0xEF05F3 - **Releases Sub CPU from reset**
4. `CALL SubCPU_Init_DMA_Channels` - Sets up DMA channels
5. `CALR SubCPU_Send_Payload` - **Sends payload data to Sub CPU**

### Payload Data Location

The subprogram payload is embedded in the **Table Data ROM** at offsets:
- 0x030000-0x070000 (addresses 0x830000-0x870000)
- Additional data at 0x800100+

### E1 Bulk Transfer Function (InterCPU_E1_Bulk_Transfer)

Located at 0xEF3457, this function:
```asm
InterCPU_E1_Bulk_Transfer:
    BIT 3, (PZ)              ; Wait for SSTAT1 high
    RES 0, (PZ)              ; Clear MSTAT0
    LD (05E0h), 001h
    LD (INTER_CPU_COMM_LATCHES), 0e1h  ; Send E1 command!
    ...
    SET 0, (PZ)              ; Set MSTAT0
    LD (05DAh), XDE          ; Set source address
    LD (05DEh), BC           ; Set byte count
    CALR Audio_DMA_Transfer  ; Send 6-byte header
    ...                       ; Send actual data
```

### E2 Command Function

Located at 0xEF33C4:
```asm
    LD (INTER_CPU_COMM_LATCHES), 0e2h  ; Send E2 command
```

### Main CPU INT0 Handler (0xEF3525)

Receives responses from Sub CPU:
```asm
INT0_HANDLER:
    LD A, (INTER_CPU_COMM_LATCHES)  ; Read response
    CP A, 0e1h              ; E1 response?
    CP A, 0e2h              ; E2 response?
```

## MAME Driver Analysis

### Current Hardware Setup (Correct)

1. **Latches**: `generic_latch_8_device` at IC22/IC23
2. **INT0 Connection**: `data_pending_callback().set_inputline(TLCS900_INT0)`
3. **Port Signals**: MSTAT/SSTAT correctly mapped

### Potential Issues to Investigate

1. **Table Data ROM Access**: Main CPU reads payload from 0x830000-0x870000
   - Verify Table Data ROM is correctly mapped at 0x800000
   - Verify data is present at offset 0x30000 in table_data ROMs

2. **DMA Channels**: Main CPU uses MicroDMA for transfers
   - TMP94C241 DMA must be emulated correctly
   - DMA source/dest/count registers must work

3. **Handshake Signals**: The protocol uses MSTAT/SSTAT for handshaking
   - Port Z bits 0-3 for main CPU
   - Port D bits 0-4 for sub CPU
   - `BIT 3, (PZ)` checks SSTAT1 on main CPU
   - `BIT 4, (0x34)` checks status on sub CPU

4. **INT0 Timing**: Both CPUs depend on INT0 firing at the right time
   - Latch write must trigger INT0 on receiver
   - INT0 must be enabled (EI instruction)

### Debug Steps for MAME

1. **Set breakpoint at main CPU 0xEF05F3** (`SET 0, (PA)`)
   - Verify execution reaches this point

2. **Set breakpoint at main CPU 0xEF068A** (payload transfer start)
   - Verify transfer routine is called

3. **Set breakpoint at main CPU 0xEF3398** (E1 send)
   - Verify E1 commands are being sent

4. **Set breakpoint at sub CPU 0xFF881F** (INT0 handler)
   - Verify INT0 fires on sub CPU

5. **Watch address 0x04FE on sub CPU**
   - Check if bit 6 ever gets set

6. **Set breakpoint at sub CPU 0xFF8418** (`call 0x000400`)
   - Verify payload entry is called

## Conclusion

The boot ROM protocol is straightforward once the E3 command mechanism is understood. The critical path is:

1. Main CPU reads subprogram from Table Data ROM (0x830000+)
2. Main CPU sends payload data via E1 commands to Sub CPU
3. Sub CPU INT0 handler receives data and stores in RAM
4. Eventually E3 command is received (method unclear - may be implicit)
5. E3 handler sets bit 6 of 0x04FE
6. Main polling loop sees bit 6, calls payload at 0x000400

For accurate emulation, ensure:
- Table Data ROM is correctly mapped and contains subprogram data
- Inter-CPU latches and INT0 work correctly
- MicroDMA channels function properly
- Handshake signals (MSTAT/SSTAT) are correctly connected

The rest follows from proper execution of both CPUs' code.
