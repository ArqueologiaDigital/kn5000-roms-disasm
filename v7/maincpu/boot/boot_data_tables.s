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

; HANDLE_UPDATE_BASE_ADDR = HANDLE_UPDATE_FILE_TYPE_ID_001h (in code section)

HANDLE_UPDATE_OFFSETS:
	; Precomputed relative offsets (identical in v7 and v9)
	.byte 0x00, 0x00, 0xa6, 0x00, 0x20, 0x00, 0xa6, 0x00
	.byte 0x43, 0x00, 0x5b, 0x00, 0x76, 0x00, 0x9a, 0x00

SLIDE_STRING_2:
	aligned_string "SLIDE"

; -----------------------------------------------------------------------------
; Firmware-update banners: eight 224x22 monochrome bitmaps, 1 bpp
; -----------------------------------------------------------------------------
; Format, from the reader Draw_FlashMemUpdate_message_bitmap (0xEF5016,
; boot/system_handlers.s): 616 bytes each = 22 rows x 28 bytes, row-major,
; MSB = leftmost pixel.  The reader walks IZ = 0..0x267 (`cp iz, 0x268`),
; starts a new row every `div wa, 0x1c` (28 bytes = 224 pixels), tests each
; bit through a mask table and writes one 8-bpp pixel per bit into the
; 320-wide offscreen buffer at 0x43C00 (foreground / background palette
; index are its two stacked word arguments), then blits that buffer to VRAM
; 0x1A0000.  Every caller passes XWA = banner, BC = x = 48 (0x30), DE = y.
; In v9/v10 each .bin is built from the PNG beside it by
; scripts/build/mono_images.py (exact round trip, `mono_images.py verify`).
; v7's eight .bin files under v7/maincpu/images/ are byte-identical to v10's
; (cmp of all eight pairs, 2026-09-25), but unlike v9/v10 they are committed
; blobs: mono_images.py does not regenerate v7's copies.  They are NOT
; included from ../../v10/maincpu/images/ because address_line_map.py (and
; the converters built on it) assembles its mirror of v7/maincpu with only
; the mirror as -I, where that path does not resolve.
; drawn by FLASH_MEM_UPDATE (0xEF4F45) and Flash_CheckAndValidate (0xEF4FBA), at y=80
Bitmap_1bit_Flash_Memory_Update:	.incbin "images/Bitmap_1bit_Flash_Memory_Update.bin"
; drawn by Erase_and_Burn____when_disk_is_valid (0xEF471B), at y=160
Bitmap_1bit_Now_Erasing:		.incbin "images/Bitmap_1bit_Now_Erasing.bin"
; drawn by SHOW_FD_TO_FLASH_MEMORY_MESSAGE (0xEF4664), at y=160
Bitmap_1bit_FD_to_Flash_Memory:		.incbin "images/Bitmap_1bit_FD_to_Flash_Memory.bin"
; drawn by FLASH_MEM_UPDATE (0xEF4F45) and Flash_CheckAndValidate (0xEF4FBA), at y=160
Bitmap_1bit_Completed:			.incbin "images/Bitmap_1bit_Completed.bin"
; drawn by We_seem_to_be_running_boot_ROM_code (0xEF050C), at y=80
Bitmap_1bit_Please_Wait:		.incbin "images/Bitmap_1bit_Please_Wait.bin"
; drawn by SHOW_CHANGE_FLOPPY_2_OF_2_MESSAGE (0xEF467E), at y=160
Bitmap_1bit_Change_FD_2_of_2:		.incbin "images/Bitmap_1bit_Change_FD_2_of_2.bin"
; drawn by SHOW_ILLEGAL_DISK_MESSAGE (0xEF4800), at y=160
Bitmap_1bit_Illegal_Disk:		.incbin "images/Bitmap_1bit_Illegal_Disk.bin"
; drawn by FLASH_MEM_UPDATE (0xEF4F45) and Flash_CheckAndValidate (0xEF4FBA), at y=200
Bitmap_1bit_Turn_On_AGAIN:		.incbin "images/Bitmap_1bit_Turn_On_AGAIN.bin"
