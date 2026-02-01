# Label Rename Recommendations

This document summarizes the semantic label rename recommendations from comprehensive analysis of all assembly files.

## Summary

| File | Labels Analyzed | Recommended Renames |
|------|-----------------|---------------------|
| maincpu/kn5000_v10_program.asm | 35,897 | 30 |
| subcpu/kn5000_subprogram_v142.asm | ~500 | 20 |
| table_data/kn5000_table_data.asm | ~50 | 20 |
| hdae5000/hd-ae5000_v2_06i.asm | ~100 | 20 |
| subcpu/boot/kn5000_subcpu_boot.asm | ~50 | 15 |
| maincpu/fdc_routines.asm | ~47 | 15 |
| maincpu/cpanel_routines.asm | ~30 | 15 |
| maincpu/midi_encoder_routines.asm | ~20 | 15 |
| maincpu/sysex_routines.asm | ~20 | 15 |
| maincpu/demo_routines.asm | ~15 | 15 ✅ Applied |
| maincpu/midi_serial_routines.asm | ~30 | 15 |
| maincpu/sound_editor_routines.asm | ~25 | 15 |
| maincpu/file_io/*.asm | ~50 | 20 |
| maincpu/computer_interface_*.asm | ~25 | 15 |

## Applied Changes

### demo_routines.asm (Completed)

| Old Name | New Name |
|----------|----------|
| LABEL_F222FA | DemoModeFunc_Exit |
| LABEL_F222EE | DemoModeFunc_Initialize |
| LABEL_F22339 | DemoStyle_DispatchTable |
| LABEL_F22348 | DemoStyle_InputHandler |
| LABEL_F22390 | DemoStyle_EncoderHandler |
| LABEL_F223A4 | DemoStyle_DirectionHandler |
| LABEL_F223B6 | DemoStyle_PostEventCommon |
| LABEL_F223BC | DemoStyle_EnterHandler |
| LABEL_F223C8 | DemoStyleTtlFunc_Exit |
| LABEL_F22404 | DemoSound_DispatchTable |
| LABEL_F22412 | DemoSound_InputHandler |
| LABEL_F22456 | DemoSound_EncoderHandler |
| LABEL_F2246A | DemoSound_DirectionHandler |
| LABEL_F2247C | DemoSound_PostEventCommon |
| LABEL_F22482 | DemoSound_EnterHandler |
| LABEL_F2248E | DemoSoundTtlFunc_Exit |
| LABEL_F224CA | DemoRhythm_DispatchTable |
| LABEL_F224D8 | DemoRhythm_InputHandler |
| LABEL_F2251C | DemoRhythm_EncoderHandler |
| LABEL_F22530 | DemoRhythm_DirectionHandler |
| LABEL_F22542 | DemoRhythm_PostEventCommon |
| LABEL_F22548 | DemoRhythm_EnterHandler |
| LABEL_F22554 | DemoRhyTtlFunc_Exit |

## Pending Recommendations

### Main CPU (kn5000_v10_program.asm) - Top 10

| Old Name | New Name | Purpose |
|----------|----------|---------|
| LABEL_EF078D | Disable_SubCPU_Interrupt | Clears bit 7 of I/O register 0x0406 |
| LABEL_EF0792 | Enable_SubCPU_Interrupt | Sets bit 7 of I/O register 0x0406 |
| LABEL_EF07F3 | InitSystemRAM_ReleaseMemoryLock | Clears 4MB RAM, manages lock via 0xFFCA:24 |
| LABEL_FF0A72 | SendEvent_ToAudioSubsystem | Referenced 122 times, audio event dispatcher |
| LABEL_FF0F4D | AllocateMemory_AudioBuffer | Referenced 295 times, memory management |
| LABEL_FF1048 | FormatString_PrintfLike | Printf-like string formatter |
| LABEL_FCD437 | BCD_ToDigits_WithLookup | BCD conversion, 172 references |
| LABEL_F53DF1 | LimitValue_ToRange_0_29 | Value clamping, 149 references |
| LABEL_FDA06F | DispatchEvent_ViaJumpTable | Event dispatcher, 186 references |
| LABEL_F40052 | CoreEventProcessor_MainLoop | Central event processing, 108 refs |

### SubCPU Payload - Top 10

| Old Name | New Name | Purpose |
|----------|----------|---------|
| LABEL_01F809 | Serial1_BaudRate_Config_Table | Baud rate configuration values |
| LABEL_01F811 | Serial1_CommandHandler_RX_F4F5 | Processes 0xF4/0xF5 commands |
| LABEL_01F856 | Audio_DMA_RingBuffer_To_Maincpu | DMA transfer to main CPU |
| LABEL_00F48C | Voice_PolyphonyLimits_Table | Voice limits per command |
| LABEL_00F4AC | Voice_IndexMapping_Table | Voice routing table |
| LABEL_00F507 | Voice_AttackDecay_Widths | Envelope parameters |
| LABEL_00F519 | Voice_EnvelopeRate_Lookup | Envelope rate table |
| LABEL_00F52b | Voice_Frequency_Offset_Table | Frequency offsets |
| LABEL_00F603 | Voice_KeyTable_Remapping | MIDI key remapping |
| LABEL_01FB76 | Audio_PlayNote_Variant_1 | Note playing handler |

### FDC Routines - Top 10

| Old Name | New Name | Purpose |
|----------|----------|---------|
| LABEL_F9700A | FDC_Validate_Drive_Head | Drive/head parameter validation |
| LABEL_F9708F | FDC_Setup_DMA_Write_Mode | DMA setup for write commands |
| LABEL_F97091 | FDC_Setup_DMA_Read_Mode | DMA setup for read commands |
| LABEL_F970DA | FDC_WaitReady_StatusLoop | Status polling loop |
| LABEL_F970EF | FDC_WaitReady_TimeoutCheck | Timeout comparison |
| LABEL_F97100 | FDC_WaitReady_LoopContinue | Loop continuation |
| LABEL_F97111 | FDC_WaitReady_Complete | Wait completion |
| LABEL_F97124 | FDC_WaitStatus_StatusLoop | Status wait loop |
| LABEL_F97148 | FDC_WaitStatus_TimeoutCheck | Status timeout check |
| LABEL_F9723D | FDC_Exception_Status_Decoder | Error handler dispatcher |

### Control Panel Routines - Top 10

| Old Name | New Name | Purpose |
|----------|----------|---------|
| LABEL_FC480F | CPanel_InterruptPoll_MainLoop | Main control panel polling |
| LABEL_FC4194 | CPanel_PanelDetection | Left/right panel MCU detection |
| LABEL_FC4170 | CPanel_SpecialCombo_FirmwareVersion | Button combo handler |
| LABEL_FC4945 | CPanel_RX_PacketSizeCheck | Packet validation |
| LABEL_FC437A | CPanel_WaitTXReady_Poll | TX ready polling |
| LABEL_FC4394 | CPanel_WaitTXReady_Timeout | Timeout handler |
| LABEL_FC44CA | CPanel_INTTX1_Handler_Exit | TX interrupt exit |
| LABEL_FC44EC | CPanel_INTRX1_Handler_Exit | RX interrupt exit |
| LABEL_FC40DE | Delay_2_Loops | 2-iteration delay |
| LABEL_FC40E9 | Delay_6_Loops | 6-iteration delay |

### MIDI Serial Routines - Top 10

| Old Name | New Name | Purpose |
|----------|----------|---------|
| LABEL_FCF11B | MIDI_INIT_SEQUENCES | MIDI system initialization |
| LABEL_FCF13D | INTRX0_CLEAR_ERROR_STATE | RX error handler |
| LABEL_FCF224 | MIDI_RX_BYTE_DISPATCHER | Main MIDI dispatcher |
| LABEL_FCF297 | MIDI_SYSTEM_MESSAGE_HANDLER | System message handler |
| LABEL_FCF733 | MIDI_CHANNEL_MESSAGE_DISPATCHER | Channel message dispatcher |
| LABEL_FCF760 | MIDI_CHANNEL_HANDLER_JUMP_TABLE | Handler jump table |
| LABEL_FCF782 | MIDI_QUEUE_EVENT_TO_SEQUENCER | Event queueing |
| LABEL_FCF85D | MIDI_RX_CONTEXT_RESTORE | Register restore |
| LABEL_FCF87A | MIDI_RX_CONTEXT_SAVE | Register save |
| LABEL_FCF4F7 | MIDI_START_PLAYBACK_REQUEST | Playback start |

### SysEx Routines - Top 10

| Old Name | New Name | Purpose |
|----------|----------|---------|
| LABEL_F76647 | ExcSendFunc_InvalidParam_Exit | Parameter validation error |
| LABEL_F76669 | MainExcSend_UnexpectedMessageType_Exit | Message type error |
| LABEL_F766D0 | ExcDotFunc_InvalidIndex_Exit | Index range error |
| LABEL_F7672C | ExcPmemFunc_InvalidIndex_Exit | PMEM index error |
| LABEL_F7678A | ExcSmemFunc_InvalidIndex_Exit | SMEM index error |
| LABEL_F767E8 | ExcCompFunc_InvalidIndex_Exit | COMP index error |
| LABEL_F76846 | ExcSeqFunc_InvalidIndex_Exit | SEQ index error |
| LABEL_F768A4 | ExcMspFunc_InvalidIndex_Exit | MSP index error |
| LABEL_F7665C | MainExcSend_ClampIndexToRange | Index clamping |
| LABEL_F76696 | ExcDotFunc_HandlerJumpTable | DOT handler table |

## How to Apply Renames

Use sed for batch renaming to avoid editor freezing:

```bash
# Example: rename a label across all files
find . -name "*.asm" -exec sed -i 's/LABEL_F9700A/FDC_Validate_Drive_Head/g' {} \;
```

For safety, always verify the build after renames:
```bash
make clean && make all
```

## Cross-Reference Notes

When renaming labels that may be referenced across files:
1. Search for the label in all .asm files first
2. Apply the rename to all occurrences simultaneously
3. Verify the build

Labels in included files (like demo_routines.asm) are typically local and safe to rename within the file.
