; =============================================================================
; Boot Data Tables - LED patterns, file type signatures, firmware update data
; =============================================================================
; Extracted from kn5000_v10_program.s
; Contains:
;   - LED patterns for firmware version display
;   - SeqRingBuf DMA dispatch table
;   - File type signature strings (firmware update)
;   - Firmware update handler offset table
;   - Firmware update bitmap includes

LED_patterns_indicating_firmware_version:
	.byte 0x10	; v0:  0001 0000
	.byte 0x18	; v1:  0001 1000
	.byte 0x14	; v2:  0001 0100
	.byte 0x1c	; v3:  0001 1100
	.byte 0x12	; v4:  0001 0010
	.byte 0x1a	; v5:  0001 1010
	.byte 0x16	; v6:  0001 0110
	.byte 0x1e	; v7:  0001 1110
LED_patterns_firmware_v8_plus:
	.byte 0x11	; v8:  0001 0001
	.byte 0x19	; v9:  0001 1001
	.byte 0x15	; v10: 0001 0101
	.byte 0x1d	; v11: 0001 1101
	.byte 0x13	; v12: 0001 0011
	.byte 0x1b	; v13: 0001 1011
	.byte 0x17	; v14: 0001 0111
	.byte 0x1f	; v15: 0001 1111

LED_pattern_test_data:
	.byte 0x10, 0xff

; DMA ISR event router: dispatches incoming sequencer data to ring buffers
; Index: DRAM[1508] bits [7:5] (top 3 bits of status byte), 8 entries
; Called from E1DMA_ISR handler (system_handlers.s)
;
; Each entry routes DMA event bytes to a specific ring buffer, consumed by:
;   NoteEvent  (0x0203d5) -> note_voice_mapping, sound_editor_ui
;   SoundEdit  (via EF2E39) -> sound_editor_ui
;   VoiceMap   (0x0201c1) -> note_voice_mapping
;   DspSysEx   (0x01fca3) -> dsp_config_sysex
;   MidiOut    (0x01f785) -> midi_serial_routines  (not in this table)
SeqRingBuf_WriteDispatch_Table:
	.long SeqDMA_MultiWrite_NoteEvent	; 0: -> NoteEvent buffer (block writes)
	.long SeqDMA_MultiWrite_SoundEdit	; 1: -> SoundEdit buffer
	.long SeqDMA_WriteMidi_NoteOn		; 2: -> NoteEvent buffer (MIDI 0x90 Note On)
	.long SeqDMA_MultiWrite_VoiceMap	; 3: -> VoiceMap buffer
	.long SeqDMA_MultiWrite_DspSysEx	; 4: -> DspSysEx buffer
	.long SeqDMA_Nop			; 5: unused
	.long SeqDMA_Nop			; 6: unused
	.long SeqDMA_Nop			; 7: unused

SLIDE_STRING:			aligned_string "SLIDE"
FILETYPE_SIG_PROGRAM_1:		aligned_string "Technics KN5000 Program  DATA FILE 1/2"
FILETYPE_SIG_PROGRAM_2:		aligned_string "Technics KN5000 Program  DATA FILE 2/2"
FILETYPE_SIG_PROGRAM_PCK:	aligned_string "Technics KN5000 Program  DATA FILE PCK"
FILETYPE_SIG_TABLE_1:		aligned_string "Technics KN5000 Table    DATA FILE 1/2"
FILETYPE_SIG_TABLE_2:		aligned_string "Technics KN5000 Table    DATA FILE 2/2"
FILETYPE_SIG_TABLE_PCK:		aligned_string "Technics KN5000 Table    DATA FILE PCK"
FILETYPE_SIG_CMPCUSTOM:		aligned_string "Technics KN5000 CMPCUSTOMDATA FILE    "
FILETYPE_SIG_HDAE_PRG:		aligned_string "Technics KN5000 HD-AEPRG DATA FILE    "

.equ HANDLE_UPDATE_BASE_ADDR, HANDLE_UPDATE_FILE_TYPE_ID_001h

HANDLE_UPDATE_OFFSETS:
	.short HANDLE_UPDATE_FILE_TYPE_ID_001h - HANDLE_UPDATE_BASE_ADDR	; "Technics KN5000 Program DATA FILE 1/2"
	.short SHOW_ILLEGAL_DISK_MESSAGE - HANDLE_UPDATE_BASE_ADDR	; "Technics KN5000 Program DATA FILE 2/2"
	.short HANDLE_UPDATE_FILE_TYPE_ID_003h - HANDLE_UPDATE_BASE_ADDR	; "Technics KN5000 Table DATA FILE 1/2"
	.short SHOW_ILLEGAL_DISK_MESSAGE - HANDLE_UPDATE_BASE_ADDR	; "Technics KN5000 Table DATA FILE 2/2"
	.short HANDLE_UPDATE_FILE_TYPE_ID_005h - HANDLE_UPDATE_BASE_ADDR	; "Technics KN5000 CMPCUSTOMDATA FILE"
	.short HANDLE_UPDATE_FILE_TYPE_ID_006h - HANDLE_UPDATE_BASE_ADDR	; "Technics KN5000 HD-AEPRG DATA FILE"
	.short HANDLE_UPDATE_FILE_TYPE_ID_007h - HANDLE_UPDATE_BASE_ADDR	; "Technics KN5000 Program DATA FILE PCK"
	.short HANDLE_UPDATE_FILE_TYPE_ID_008h - HANDLE_UPDATE_BASE_ADDR	; "Technics KN5000 Table DATA FILE PCK"

SLIDE_STRING_2:
	aligned_string "SLIDE"

Bitmap_1bit_Flash_Memory_Update:	.incbin "images/Bitmap_1bit_Flash_Memory_Update.bin"
Bitmap_1bit_Now_Erasing:		.incbin "images/Bitmap_1bit_Now_Erasing.bin"
Bitmap_1bit_FD_to_Flash_Memory:		.incbin "images/Bitmap_1bit_FD_to_Flash_Memory.bin"
Bitmap_1bit_Completed:			.incbin "images/Bitmap_1bit_Completed.bin"
Bitmap_1bit_Please_Wait:		.incbin "images/Bitmap_1bit_Please_Wait.bin"
Bitmap_1bit_Change_FD_2_of_2:		.incbin "images/Bitmap_1bit_Change_FD_2_of_2.bin"
Bitmap_1bit_Illegal_Disk:		.incbin "images/Bitmap_1bit_Illegal_Disk.bin"
Bitmap_1bit_Turn_On_AGAIN:		.incbin "images/Bitmap_1bit_Turn_On_AGAIN.bin"
