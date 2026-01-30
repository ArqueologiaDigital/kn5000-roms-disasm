# Sub CPU Boot ROM Analysis

## ROM Dump Status

The Sub CPU boot ROM (IC30, 128KB) has the following dump status:

| Region | File Offset | ROM Address | Status | Content |
|--------|-------------|-------------|--------|---------|
| 0x0000-0x07FF | FE0000-FE07FF | DUMPED | All 0xFF (unused) |
| 0x0800-0x17800 | FE0800-FF7800 | NOT DUMPED | Filled with 0xFF (assumed) |
| 0x17800-0x19800 | FF7800-FF9800 | DUMPED | **Actual code and data** |
| 0x19800-0x1F000 | FF9800-FFF000 | NOT DUMPED | Filled with 0xFF (assumed) |
| 0x1F000-0x1FE80 | FFF000-FFFE80 | DUMPED | All 0xFF (unused) |
| 0x1FE80-0x20000 | FFFE80-FFFFFF | DUMPED | **Code + interrupt vectors** |

## Evidence Supporting "Undumped = 0xFF" Hypothesis

### 1. All Code References Stay Within Dumped Regions

Analysis of all JP, CALL, CALR, JRL instructions in the dumped code regions:

```
ff8418: call 0x000400    <- PAYLOAD ENTRY POINT (in RAM after transfer)
ff8433: jrl T,0xff8290   <- Within dumped region
ff83fe: call 0xff8956    <- Within dumped region
ff8402: call 0xff85ae    <- Within dumped region
ff8406: call 0xff84a8    <- Within dumped region
... (all other calls/jumps target addresses in FF7800-FF9800 range)
```

**No verified code jumps to addresses in the undumped regions.**

### 2. Self-Contained Boot Logic

The boot ROM's purpose is simple and fully implemented in the dumped regions:

1. **Hardware Initialization** (at 0xFF8290):
   - Configure SFRs (interrupt priorities, timers, ports)
   - Initialize communication latches

2. **Payload Wait Loop** (at 0xFF8410-0xFF8430):
   ```asm
   ff840c: res 6,(0x04fe)     ; Clear payload-ready flag
   ff8410: bit 6,(0x04fe)     ; Check if payload is ready
   ff8414: jr Z,0xff841c      ; If not ready, skip call
   ff8416: ei 0x06            ; Enable interrupts
   ff8418: call 0x000400      ; CALL PAYLOAD ENTRY POINT
   ff8430: jr T,0xff8410      ; Loop back
   ```

3. **Interrupt Vectors** (at 0xFFFEF0-0xFFFFB4):
   - Reset vector at 0xFFFF00: Points to 0xFFFEE0 (boot ROM code)
   - All other vectors: Point to payload addresses (0x000400-0x0004D7)

### 3. Consistent Memory Layout

The interrupt vector table at the end of the ROM shows:
- **Reset (0xFFFF00)**: `E0 FE FF 00` = 0x00FFFEE0 (→ JP 0xFF8290 in boot ROM)
- **INT0-INTx**: `00 04 00 00`, `05 04 00 00`, etc. = Payload addresses

This design makes sense: Reset goes to boot ROM, all other interrupts go directly to payload handlers once payload is loaded.

### 4. Data Regions Identified

The "code" at 0xFF8200-0xFF828F is actually data:
```
00018200: 3435 3637 3839 3a3b 3c3d 3e3f 4041 4243  456789:;<=>?@ABC
00018210: 4445 4647 4849 4a4b 4c4d 4e4f 5051 5253  DEFGHIJKLMNOPQRS
```
This is an ASCII character lookup table (characters 0x34-0x7F), not code.

### 5. One False Positive Explained

The only apparent reference to an undumped region:
```
ff824b: 7f 00 f0    jrl NC,0xff724e
```

This is **DATA being misinterpreted as code**. Address 0xFF824B is in the middle of the ASCII lookup table at 0xFF8200. The bytes `7F 00 F0` are data (ASCII 0x7F = DEL, followed by 0x00, 0xF0 from subsequent data).

## Boot Sequence Summary

1. CPU reset vector at 0xFFFF00 → JP 0xFFFEE0
2. JP 0xFFFEE0 → JP 0xFF8290 (main boot entry)
3. Initialize hardware (0xFF8290-0xFF83F8)
4. Poll PAYLOAD_LOADED_FLAG (0x04FE) bit 6
5. When main CPU sends E3 command, bit 6 gets set
6. Boot ROM calls payload at 0x000400
7. Payload takes over; all interrupts vector to payload handlers

## Conclusion

**The undumped regions (0xFE0800-0xFF7800 and 0xFF9800-0xFFF000) are almost certainly 0xFF-filled unused space.**

Evidence:
- All functional code is self-contained in dumped regions
- No code references target undumped addresses
- Boot logic is complete and makes sense
- Interrupt vector design is consistent with payload-based operation
- ROM size suggests significant unused space is expected

The BAD_DUMP tag in MAME is technically correct (partial dump), but the ROM is **functionally complete** for emulation purposes.

## Recommendation for MAME

The boot ROM should work correctly for HLE purposes. The key behaviors to emulate:

1. Sub CPU starts executing at 0xFFFEE0 (via reset vector)
2. Boot code initializes hardware, then polls 0x04FE bit 6
3. When main CPU completes payload transfer and sends E3 command, set bit 6
4. Boot ROM then calls 0x000400 (payload entry point)

Alternatively, for faster startup, MAME could:
1. Pre-load payload into Sub CPU RAM at 0x000400
2. Set initial PC to 0x000400 directly
3. Skip boot ROM entirely
