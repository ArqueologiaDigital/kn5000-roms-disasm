# Audio Subsystem Symbol Renaming Proposal

This document proposes semantic names for LABEL_* symbols related to the KN5000 audio subsystem.
Review before applying changes.

---

## Summary

| Category | Count |
|----------|-------|
| Main CPU Audio/DMA Routines | 8 |
| Sub CPU Command Dispatch Handlers | 6 |
| Sub CPU MIDI Message Handlers | 16 |
| Sub CPU Voice Parameter Handlers | 12 |
| Sub CPU Ring Buffer Operations | 4 |
| Sub CPU DSP Control Routines | 8 |
| Sub CPU Audio Processing | 6 |
| **Total** | **60** |

---

## 1. Main CPU Audio/DMA Routines

Located in `maincpu/kn5000_v10_program.asm`

| Current Symbol | Proposed Name | Address | Description |
|----------------|---------------|---------|-------------|
| `LABEL_EF1F0F` | `Audio_Lock_Release` | 0xEF1F0F | Release inter-CPU communication lock after audio command transmission |
| `LABEL_EF1FEE` | `Audio_Lock_Acquire` | 0xEF1FEE | Acquire inter-CPU communication lock before sending audio commands |
| `LABEL_EF341B` | `Audio_DMA_Transfer` | 0xEF341B | Core DMA transfer routine for inter-CPU audio data communication |
| `LABEL_EF3D0E` | `HDAE5000_Detect` | 0xEF3D0E | Detect presence of HDAE5000 expansion board |
| `LABEL_EF3DBB` | `HDAE5000_Flash_Verify` | 0xEF3DBB | Flash verification sequence on Table Data ROM |
| `LABEL_EF3F29` | `HDAE5000_Status_Check` | 0xEF3F29 | Check HDAE5000 status register for ready state |
| `LABEL_EF48AE` | `TableData_ROM_Verify` | 0xEF48AE | Verify Table Data ROM integrity via checksum |
| `LABEL_EF48CF` | `HDAE5000_ROM_Transfer` | 0xEF48CF | Transfer HDAE5000 ROM data to working memory |

### Documentation Header Template for Main CPU:

```asm
; ===========================================================================
; Audio_Lock_Acquire - Acquire inter-CPU communication lock
; ===========================================================================
; Entry: None
; Exit:  Lock acquired, safe to send audio commands
; Notes: Uses linked list of waiting commands with counter at offset +0x0532h
;        Must be paired with Audio_Lock_Release after sending commands
; ===========================================================================
```

---

## 2. Sub CPU Command Dispatch Handlers

Located in `subcpu/kn5000_subprogram_v142.asm`

These are referenced from `CMD_DISPATCH_TABLE` at line 576.

| Current Symbol | Proposed Name | Address | Cmd Range | Description |
|----------------|---------------|---------|-----------|-------------|
| `LABEL_034D5F` | `Audio_CmdHandler_00_1F` | 0x034D5F | 0x00-0x1F | DSP/audio control commands - writes to ring buffer at 0x2B0D |
| `LABEL_01FC7C` | `Audio_CmdHandler_20_3F` | 0x01FC7C | 0x20-0x3F | Extended audio control commands |
| `LABEL_01FC7F` | `Audio_CmdHandler_40_5F` | 0x01FC7F | 0x40-0x5F | Audio parameter commands |
| `LABEL_035893` | `Audio_CmdHandler_60_7F` | 0x035893 | 0x60-0x7F | Voice/DSP configuration commands |
| `LABEL_03CFEE` | `Audio_CmdHandler_A0_BF` | 0x03CFEE | 0xA0-0xBF | System audio commands |
| `LABEL_020C12` | `Audio_CmdHandler_C0_FF` | 0x020C12 | 0xC0-0xFF | Extended system commands (shared for C0-DF and E0-FF) |

### Sub-labels within Audio_CmdHandler_00_1F:

| Current Symbol | Proposed Name | Address | Description |
|----------------|---------------|---------|-------------|
| `LABEL_034D66` | `Audio_CmdHandler_00_1F_Loop` | 0x034D66 | Loop body: writes bytes to ring buffer |
| `LABEL_034D90` | `Audio_CmdHandler_00_1F_Done` | 0x034D90 | Exit point, returns HL=0 |
| `LABEL_034D47` | `Audio_CmdHandler_ConstData` | 0x034D47 | 24 bytes of constant data for command processing |

### Documentation Header:

```asm
; ===========================================================================
; Audio_CmdHandler_00_1F - Audio command handler for DSP/audio control
; ===========================================================================
; Entry: Stack contains:
;        XSP+004h = count of bytes to process (DE)
;        XSP+006h = pointer to command data (XWA)
; Exit:  HL = 0 (success)
; Notes: Writes incoming audio data to circular ring buffer at 0x2B0D
;        Buffer uses 12-bit index (0xFFF mask = 4KB buffer)
;        Base address stored at 0x2B13, count at 0x2B11
; ===========================================================================
```

---

## 3. Sub CPU MIDI Message Dispatcher

Located in `subcpu/kn5000_subprogram_v142.asm`

| Current Symbol | Proposed Name | Address | Description |
|----------------|---------------|---------|-------------|
| `LABEL_034D93` | `MIDI_Dispatch` | 0x034D93 | Main MIDI message dispatcher - parses status byte and routes |
| `LABEL_034DA2` | `MIDI_Dispatch_ParseStatus` | 0x034DA2 | Parse MIDI status byte (masks with 0xF0) |

### MIDI Status Handlers (0x80-0xF0):

| Current Symbol | Proposed Name | Address | MIDI Status | Description |
|----------------|---------------|---------|-------------|-------------|
| `LABEL_034E65` | `MIDI_Status_NoteOn` | 0x034E65 | 0x90 | Note On handler (3 data bytes) |
| `LABEL_034E9F` | `MIDI_Status_NoteOn_Poly` | 0x034E9F | 0x90 | Polyphonic note-on (calls LABEL_0356C9) |
| `LABEL_034EAA` | `MIDI_Status_NoteOn_Skip` | 0x034EAA | 0x90 | Skip incomplete Note On message |
| `LABEL_034EB2` | `MIDI_Status_CtrlChange` | 0x034EB2 | 0xB0 | Control Change handler (3 data bytes) |
| `LABEL_034EE3` | `MIDI_Status_CtrlChange_Skip` | 0x034EE3 | 0xB0 | Skip incomplete Control Change |
| `LABEL_034EEB` | `MIDI_Status_ProgChange` | 0x034EEB | 0xC0 | Program Change handler (4 data bytes) |
| `LABEL_034F25` | `MIDI_Status_ProgChange_Skip` | 0x034F25 | 0xC0 | Skip incomplete Program Change |
| `LABEL_034F2D` | `MIDI_Status_ChanPressure` | 0x034F2D | 0xD0 | Channel Pressure/Aftertouch (3 data bytes) |
| `LABEL_034F5E` | `MIDI_Status_ChanPressure_Skip` | 0x034F5E | 0xD0 | Skip incomplete Channel Pressure |
| `LABEL_034F65` | `MIDI_Status_PitchBend` | 0x034F65 | 0xE0 | Pitch Bend handler (3 data bytes) |
| `LABEL_034F95` | `MIDI_Status_PitchBend_Skip` | 0x034F95 | 0xE0 | Skip incomplete Pitch Bend |
| `LABEL_034F9C` | `MIDI_Status_System` | 0x034F9C | 0xF0 | System message handler (3 data bytes) |
| `LABEL_034FCC` | `MIDI_Status_System_Skip` | 0x034FCC | 0xF0 | Skip incomplete System message |
| `LABEL_034FD3` | `MIDI_Status_Unknown` | 0x034FD3 | - | Unknown/invalid status byte handler |
| `LABEL_034FD8` | `MIDI_Dispatch_NextByte` | 0x034FD8 | - | Read next byte from buffer, loop or exit |
| `LABEL_034FE4` | `MIDI_Dispatch_Exit` | 0x034FE4 | - | Pop XIZ and return from dispatcher |

### Extended Note handlers (within 0x80 status range):

| Current Symbol | Proposed Name | Address | Description |
|----------------|---------------|---------|-------------|
| `LABEL_034E21` | `MIDI_Status_NoteOn_Extended` | 0x034E21 | Extended note-on with additional parameters (6 bytes) |
| `LABEL_034E5D` | `MIDI_Status_Incomplete` | 0x034E5D | Handle incomplete MIDI message - skip to end |

### Documentation Header:

```asm
; ===========================================================================
; MIDI_Dispatch - MIDI message dispatcher
; ===========================================================================
; Entry: Ring buffer at 0x2B0D contains MIDI data
; Exit:  Messages dispatched to appropriate voice parameter handlers
; Notes: Parses MIDI status byte (0x80-0xF0) and routes to handlers:
;        0x80 = Note Off (handled as Note On with velocity 0)
;        0x90 = Note On -> MIDI_Status_NoteOn
;        0xB0 = Control Change -> MIDI_Status_CtrlChange
;        0xC0 = Program Change -> MIDI_Status_ProgChange
;        0xD0 = Channel Pressure -> MIDI_Status_ChanPressure
;        0xE0 = Pitch Bend -> MIDI_Status_PitchBend
;        0xF0 = System Message -> MIDI_Status_System
;        Each handler reads expected byte count, calls voice param handler
; ===========================================================================
```

---

## 4. Sub CPU Voice Parameter Handlers

These process the parsed MIDI data and update voice state.

| Current Symbol | Proposed Name | Address | Called By | Description |
|----------------|---------------|---------|-----------|-------------|
| `LABEL_02CF97` | `Voice_NoteOn` | 0x02CF97 | MIDI_Status_NoteOn | Process Note On - allocates voice, sets pitch/velocity |
| `LABEL_02A282` | `Voice_CtrlChange` | 0x02A282 | MIDI_Status_CtrlChange | Process Control Change (CC) messages |
| `LABEL_034A4A` | `Voice_ProgChange` | 0x034A4A | MIDI_Status_ProgChange | Process Program Change - updates voice program/patch |
| `LABEL_02A4EA` | `Voice_ChanPressure` | 0x02A4EA | MIDI_Status_ChanPressure | Process Channel Pressure/Aftertouch |
| `LABEL_02A5E6` | `Voice_PitchBend` | 0x02A5E6 | MIDI_Status_PitchBend | Process Pitch Bend - updates bend value |
| `LABEL_0356C9` | `Voice_Poly_NoteOn` | 0x0356C9 | MIDI_Status_NoteOn_Poly | Polyphonic note-on for high note range (>=0xF0) |
| `LABEL_02A7AF` | `Voice_SystemMsg` | 0x02A7AF | MIDI_Status_System | Process system messages |
| `LABEL_031A72` | `Voice_ParamFinalize` | 0x031A72 | Multiple | Finalize voice parameters after update |

### Control Change Sub-handlers (within Voice_CtrlChange):

| Current Symbol | Proposed Name | Address | CC# | Description |
|----------------|---------------|---------|-----|-------------|
| `LABEL_02A306` | `Voice_CC_ModWheel` | 0x02A306 | 0x01 | Modulation wheel |
| `LABEL_02A31C` | `Voice_CC_Volume` | 0x02A31C | 0x07 | Volume controller |
| `LABEL_02A340` | `Voice_CC_Pan` | 0x02A340 | 0x0A | Pan/balance |
| `LABEL_02A35F` | `Voice_CC_Expression` | 0x02A35F | 0x0B | Expression controller |
| `LABEL_02A383` | `Voice_CC_Sustain` | 0x02A383 | 0x40 | Sustain pedal |
| `LABEL_02A3A9` | `Voice_CC_Sostenuto` | 0x02A3A9 | 0x5B | Sostenuto pedal |
| `LABEL_02A3BF` | `Voice_CC_Soft` | 0x02A3BF | 0x5D | Soft pedal |
| `LABEL_02A3D5` | `Voice_CC_Portamento` | 0x02A3D5 | 0x5E | Portamento control |
| `LABEL_02A46C` | `Voice_CC_91` | 0x02A46C | 0x91 | Reverb depth |
| `LABEL_02A481` | `Voice_CC_95` | 0x02A481 | 0x95 | Chorus depth |
| `LABEL_02A496` | `Voice_CC_97` | 0x02A496 | 0x97 | Unknown CC |
| `LABEL_02A4AB` | `Voice_CC_9B` | 0x02A4AB | 0x9B | Unknown CC |
| `LABEL_02A4C0` | `Voice_CC_9C` | 0x02A4C0 | 0x9C | Unknown CC |
| `LABEL_02A4D5` | `Voice_CC_9D` | 0x02A4D5 | 0x9D | Unknown CC |
| `LABEL_02A4E8` | `Voice_CC_Exit` | 0x02A4E8 | - | Exit from CC handler |

### Documentation Header:

```asm
; ===========================================================================
; Voice_CtrlChange - Process MIDI Control Change messages
; ===========================================================================
; Entry: XIZ = pointer to 4-byte CC data:
;        XIZ+0 = status byte (0xBn where n=channel)
;        XIZ+1 = controller number
;        XIZ+2 = controller value
;        XIZ+3 = additional data
; Exit:  Voice parameters updated based on CC number
; Notes: Handles standard MIDI CCs: Mod Wheel(1), Volume(7), Pan(10),
;        Expression(11), Sustain(64), Sostenuto(91), Soft(93), Portamento(94)
;        Plus proprietary CCs in 0x91-0x9D range (effects depth, etc.)
; ===========================================================================
```

---

## 5. Sub CPU Ring Buffer Operations

| Current Symbol | Proposed Name | Address | Description |
|----------------|---------------|---------|-------------|
| `LABEL_034CFC` | `RingBuf_ReadByte` | 0x034CFC | Read single byte from audio ring buffer |
| `LABEL_034D2B` | `RingBuf_SkipToEnd` | 0x034D2B | Skip remaining bytes to end of current message |
| `LABEL_021031` | `RingBuf_SetOffsetHi` | 0x021031 | Set high word of buffer read offset |
| `LABEL_021036` | `RingBuf_SetOffsetLo` | 0x021036 | Set low byte of buffer read offset |

### Buffer Variables:
- `0x2B0D` - Write pointer (12-bit circular index)
- `0x2B0F` - Read pointer
- `0x2B11` - Byte count
- `0x2B13` - Buffer base address

### Documentation Header:

```asm
; ===========================================================================
; RingBuf_ReadByte - Read byte from audio ring buffer
; ===========================================================================
; Entry: XWA = pointer to buffer control structure
; Exit:  HL = byte read (0x0000-0x00FF) or 0xFFFF if empty
; Notes: Buffer control structure:
;        +0x00 = read pointer (16-bit)
;        +0x02 = write pointer (16-bit)
;        +0x04 = byte count (16-bit)
; ===========================================================================
```

---

## 6. Sub CPU DSP Control Routines

| Current Symbol | Proposed Name | Address | Description |
|----------------|---------------|---------|-------------|
| `LABEL_03581D` | `DSP2_Init` | 0x03581D | Initialize second DSP chip (clears 3B60-3B64) |
| `LABEL_035830` | `DSP_RingBuf_Read` | 0x035830 | Read from DSP ring buffer (11-bit index, 2KB) |
| `LABEL_03585F` | `DSP_RingBuf_Skip` | 0x03585F | Skip bytes in DSP ring buffer |
| `LABEL_035893` | `DSP_CmdHandler` | 0x035893 | DSP command handler (0x60-0x7F range) |
| `LABEL_0360A7` | `DSP_Reset` | 0x0360A7 | Reset DSP hardware (called from DSP_System_Init) |
| `LABEL_02DFA8` | `DSP_Config_Init` | 0x02DFA8 | Initialize DSP configuration (called from DSP_System_Init) |

### DSP State Variables:
- `0x041342` - DSP state buffer 1 (38 bytes)
- `0x041368` - DSP state buffer 2 (7462 bytes)
- `0x045310-045318` - DSP configuration parameters

---

## 7. Sub CPU Audio Processing Loop

| Current Symbol | Proposed Name | Address | Description |
|----------------|---------------|---------|-------------|
| `LABEL_035AC8` | `Audio_Process_DSP` | 0x035AC8 | Additional DSP audio processing |
| `LABEL_01F8D5` | `Audio_Process_Final` | 0x01F8D5 | Final audio update stage |
| `LABEL_034CDB` | `Audio_Process_Init` | 0x034CDB | Initialize audio processing loop |
| `LABEL_020C15` | `InterCPU_Latch_Setup` | 0x020C15 | Setup inter-CPU communication via latches |
| `LABEL_020C6B` | `InterCPU_DMA_Send` | 0x020C6B | Send data via DMA to main CPU |

---

## 8. Additional Voice/Note Helpers

| Current Symbol | Proposed Name | Address | Description |
|----------------|---------------|---------|-------------|
| `LABEL_02C6CD` | `Voice_SetPitch` | 0x02C6CD | Set voice pitch from note number |
| `LABEL_02C7D7` | `Voice_NoteOff` | 0x02C7D7 | Process note-off for voice |
| `LABEL_02C8E4` | `Voice_SetVelocity` | 0x02C8E4 | Set voice velocity |
| `LABEL_02CCAD` | `Voice_Allocate` | 0x02CCAD | Allocate voice slot for new note |
| `LABEL_02CF07` | `Voice_ParamInit` | 0x02CF07 | Initialize voice parameters |
| `LABEL_029F73` | `Voice_ModWheel_Apply` | 0x029F73 | Apply mod wheel to voice |

---

## Implementation Checklist

1. [ ] Rename Main CPU symbols (8 symbols)
2. [ ] Rename Sub CPU command handlers (6 symbols)
3. [ ] Rename MIDI dispatcher and handlers (16 symbols)
4. [ ] Rename voice parameter handlers (12+ symbols)
5. [ ] Rename ring buffer operations (4 symbols)
6. [ ] Rename DSP control routines (6+ symbols)
7. [ ] Rename audio processing loop symbols (5 symbols)
8. [ ] Update CMD_DISPATCH_TABLE comments with new names
9. [ ] Add documentation headers to all renamed routines
10. [ ] Verify build: `make all && python compare_roms.py`

---

## Notes

### Naming Conventions Used:
- `Audio_*` - General audio subsystem routines
- `MIDI_*` - MIDI message parsing/dispatch
- `Voice_*` - Voice parameter manipulation
- `DSP_*` / `DSP2_*` - DSP hardware control
- `RingBuf_*` - Ring buffer operations
- `InterCPU_*` - Inter-CPU communication
- `ToneGen_*` - Tone generator (keyboard input)
- `HDAE5000_*` - HDAE5000 expansion board routines
- `TableData_*` - Table Data ROM operations

### Verification After Changes:
```bash
make clean && make all
python compare_roms.py
```

Expected: 100% match for all rebuilt ROMs.
