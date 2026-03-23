; =============================================================================
; KN5000 Main CPU Program ROM (2MB: E00000-FFFFFF)
; =============================================================================

; --- Constants, Macros & SFR Definitions ---
	.text

	.include "shared/macros.s"
	.include "shared/sfr_tmp94c241.s"
	.include "shared/vga_constants.s"
	.include "shared/event_codes.s"
	.include "fdc_constants.s"
	.include "gui_constants.s"
	.include "cpanel_constants.s"
	.include "midi_encoder_constants.s"

; --- Boot Dispatch Tables, LED Patterns & Dialog Bitmaps ---
; =============================================================================
; Constants for shared boot routines
; =============================================================================
.equ REGION_CODE_VAR, 0x408	; RAM address for region code
.equ BOOT_ENTRY_POINT, RESET_HANDLER	; Entry point for watchdog reset

.equ INTER_CPU_COMM_LATCHES, 0x140000	; This is a pair of 8-bit latches
                                            ; used for bidirectional
                                            ; communication between
                                            ; maincpu and subcpu
.equ HDAE5000_PPI__PORT_A, 0x160000
.equ HDAE5000_PPI__PORT_B, 0x160002
.equ HDAE5000_PPI__PORT_C, 0x160004
.equ HDAE5000_PPI__CONTROL_REG, 0x160006
.equ HDAE5000_ROM__BASE_ADDR, 0x280000
.equ CUSTOM_DATA_FLASH__BASE_ADDR, 0x300000
.equ RHYTHM_DATA_ROM__BASE_ADDR, 0x400000
.equ TABLE_DATA_ROM__BASE_ADDR, 0x800000
.equ PROGRAM_FLASH__BASE_ADDR, 0xe00000

.equ SYSTEM_TIMESTAMP, 0x409

.equ MSP_SETTINGS, 0xc9a	; 1500h = 5376 bytes
					; next free address: 0219Ah

.equ COM_SELECT, 0xb7e0	; (byte)

.equ SEQ_ALT3_RINGBUF_BASE, 0x201c1

.equ MSP_SETTINGS__BASE_ADDR, 0x1e8800

	.org PROGRAM_FLASH__BASE_ADDR - 0xe00000, 0xff

	.include "boot/boot_data_tables.s"

; --- SSF (Style Synthesis Format) Gate State Data ---
	.include "sequencer/ssf_gate_states.s"

; --- Instrument Sound Data & Category Metadata ---
	.include "audio/sound_data.s"

; --- Style UI Parameter Blocks & Screen Data ---
	.include "ui_widgets/style_ui_params.s"

GUI_FormatStrings:		.include "includes/gui_format_strings.s"
GUI_DisplayStructData:
	.incbin "includes/generated/gui_display_struct_data.bin"
ToneGen_ParamTable:
	.incbin "includes/generated/tonegen_param_table.bin"

; =============================================================================
; NAKA UI Descriptor Blocks (ROM E0E974-EEF587)
; Screen layouts, style selection, sequencer UI, effect editors,
; chord recognition, MIDI control, language dialogs, style bitmaps
; =============================================================================
	.include "ui_widgets/performance_style_screens.s"
	.include "ui_widgets/naka_property_descriptors.s"
	.include "ui_widgets/composer_style_convert_screens.s"
	.include "ui_widgets/naka_accomp7_widgets.s"
	.include "ui_widgets/msp_recording_screens.s"
	.include "ui_widgets/naka_screen_dispatch.s"
	.include "factory_test/test_data.s"
	.include "factory_test/fd_test_data.s"
	.include "ui/sepaout_config.s"
	.include "ui_widgets/naka_debug_proc_names.s"
	.include "ui_widgets/naka_direct_play_property_tables.s"
	.include "ui_widgets/naka_direct_play_dispatch.s"
	.include "ui_widgets/direct_play_medley_screens.s"
	.include "ui_widgets/naka_widget_tables_1.s"
	.include "ui_widgets/sequencer_exit_widgets.s"
	.include "ui_widgets/naka_effects_eq_dispatch.s"
	.include "ui_widgets/effects_sequencer_screens.s"
	.include "ui_widgets/widget_descriptors.s"
	.include "ui_widgets/naka_widget_desc_dispatch.s"
	.include "ui_widgets/midi_reverb_presets_screens.s"
	.include "ui_widgets/naka_widget_tables_2.s"
	.include "ui_widgets/sound_menu_drawbar_screens.s"
	.include "ui_widgets/naka_sound_technichord_dispatch.s"
	.include "ui_widgets/technichord_part_settings.s"
	.include "ui_widgets/technichord_string_data.s"
	.include "ui_widgets/disk_menu_file_io_screens.s"
	.include "ui_widgets/disk_warning_strings.s"
	.include "ui_widgets/block_012.s"
	.include "ui_widgets/widget_names_charmap.s"
	.include "ui_widgets/debug_naming_panel_sim.s"

; =============================================================================
; UI Widget Style Bitmaps & Dispatch (end of NAKA widget section)
; =============================================================================
	.include "ui_widgets/style_bitmaps.s"
	.include "ui_widgets/widget_dispatch.s"

; =============================================================================
; Character Encoding Tables & System Core (ROM EEF588-FC3113)
; =============================================================================
	.include "ui/char_encoding_naka_state.s"
	.include "ui/charmap_dispatch_table.s"

Boot_HaltInstruction:
	halt

Boot_PostHaltData:
	.byte 0x0e, 0x68, 0x01, 0x0e


; --- RESET Handler & Boot Sequence ---
RESET_HANDLER:
	; Hardware initialization code shared with table_data ROM
	.include "shared/boot_hw_init.s"
	; End of shared boot code (315 bytes)
	ldio 0xd2, 0x29
	ldio 0xd1, 0x00
	and_sd8b_im 0xd3, 0xcf
	and_sd8b_im 0xd3, 0xf0

Boot_InitIOPorts:
	stdi8 304, 255
	stdi8 305, 255
	stdi8 306, 3
	ldio 0x3a, 0x20
	ld xsp, 0xc00
	calr Boot_InitWorkRAM

Boot_RunSelfTest:
	call MainCPU_self_test_routines
	call Get_Firmware_Version
	cp l, 0xff
	jr nz, Boot_PostSelfTest

We_seem_to_be_running_boot_ROM_code:
	call VGA_Setup
	pushw 0x8
	pushw 0x3
	ld xwa, Bitmap_1bit_Please_Wait	; "Please Wait !!"
	ldw bc, 0x30
	ldw de, 0x50
	call Draw_FlashMemUpdate_message_bitmap

Boot_PostSelfTest:
	lds32 xwa, 0
	stda32 1033, xwa
	stdi8 1024, 2
	call TaskSched_Init
	stdi8 1024, 3
Boot_InitPeripherals:
	calr Boot_ClearConfigFlag7
	lda_dd8l XBC, 0xe4
	ld a, (xbc)
	and a, 0x8f
	or a, 0x30
	ld (xbc), a
	lda_dd8l XBC, 0xe6
	ld a, (xbc)
	and a, 0xf8
	or a, 0x3
	ld (xbc), a
	calr Detect_Region_Code
	cpdi16_24 65482, 23205
	jr z, Boot_FlashAndExtensions
	lda_24 xde, 0x00066e
	srl xde, 1
	ld xwa, 0xf980
	ld xbc, 0x1e8000
	call Copy_DE_words_from_XBC_to_XWA

Boot_FlashAndExtensions:
	call Flash_InitAllBanks
	bit_dd8 0, 0x38	;  Is the optional HD-AE5000 board present?
	jr nz, BootInit_SeqAndPanel
	calr Get_Region_Code
	cps l, 4
	call_24 nz, 0xef4bcc	; if it is present (and this unit was sold in
					; a specific market region), then call the
					; HDAE5000 PPI init code

; Boot initialization handler (SeqInit + CPanel scan)
BootInit_SeqAndPanel:
	call Seq_FullInit
	ei 0
	ld32_24 xhl, 0xfc3e65
	call (xhl)
	call CPanel_ScanButtons
	stda8 1026, l
	call Get_Firmware_Version
	cp l, 0xff
	jr nz, User_didnt_request_flash_mem_update
	call Check_for_Floppy_Disk_Change
	cps hl, 0
	jr z, User_didnt_request_flash_mem_update
	cpdi8 1026, 4
	jr nz, User_didnt_request_flash_mem_update
	call FLASH_MEM_UPDATE

Boot_MainSequence_Trampoline:
	jr Boot_MainSequence_Trampoline

; ===========================================================================
; User_didnt_request_flash_mem_update - Main Boot Sequence
; ===========================================================================
; This is the main boot path after power-on self-test and flash update check.
; Initializes Sub-CPU communication, transfers firmware payload, and verifies
; the transfer succeeded. On failure, displays the "ERROR in CPU data
; transmission" dialog (Screen Group 7).
;
; Boot flow:
;   1. Initialize DMA channels for inter-CPU communication
;   2. Send 192KB Sub-CPU firmware payload
;   3. Verify payload integrity (checksum validation)
;   4. Check error flag - if set, display error dialog
;   5. Continue to main UI initialization
;
; Error handling:
;   - If SubCPU_Payload_Verify returns non-zero in HL, boot with error state
;   - Error state (WA=2) displays error dialog via ScreenGroup_Dispatch
;   - Eventually Screen Group 7 "CPU data transmission" error is shown
;
; See also:
;   - SubCPU_Send_Payload - Payload transfer routine
;   - SubCPU_Payload_Verify - Checksum verification
;   - ErrorDialog_CPUTransmissionError - Error dialog widget
; ===========================================================================
User_didnt_request_flash_mem_update:
	ldda8 a, 1026		; Load boot combo code
	extz wa
	calr Boot_HandleFactoryReset	; Reset if combo 1 + invalid checksums
	sti16_24 0x00ffca, 0x0000
	set_dd8 0, 0x28	; Release Sub-CPU from reset
	call SubCPU_Init_DMA_Channels	; Initialize DMA for inter-CPU comm
	ei 0
	calr SubCPU_Send_Payload	; Transfer 192KB Sub-CPU firmware
	calr SubCPU_Payload_Verify	; Verify payload checksum
	lds wa, 0
	call ScreenGroup_Dispatch	; Display initial boot screen (group 0)
	ei 0
	call SelfTest_FirmwareVersionCheck
	calr SubCPU_Payload_GetErrorFlag	; Check if payload transfer failed
	cps hl, 0	; HL=0: success, HL!=0: error
	jr nz, Boot_PayloadError	; Branch if error occurred
	lds wa, 1	; Success: use screen group 1
	jr Boot_DisplayScreen

; Sub-CPU payload transfer or verification failed
Boot_PayloadError:
	lds wa, 2	; Error: use screen group 2

Boot_DisplayScreen:
	call ScreenGroup_Dispatch	; Display appropriate screen group
	stdi8 1024, 6
	lds wa, 3
	call ScreenGroup_Dispatch
	stdi8 1024, 128
	sti16_24 0x00ffd4, 0x0000
	ldda8 a, 1026		; Load boot combo code
	extz wa
	calr Boot_HandleComboDisplay	; Handle combo 2 (LEDs) or combo 3 (version screen)
	lds wa, 4
	call Show_ScreenGroup	; Show screen group 4 (main UI initialization)
	calr Boot_SetConfigFlag7
	jp MainLoop

Boot_GetButtonComboCode:
	ldda8 l, 1026
	ret

Boot_ClearAllInterruptEnables:
	ldio 0xf0, 0x00
	ldio 0xe0, 0x00
	ldio 0xe1, 0x00
	ldio 0xe2, 0x00
	ldio 0xe3, 0x00
	ldio 0xe4, 0x00
	ldio 0xe5, 0x00
	ldio 0xe6, 0x00
	ldio 0xe7, 0x00
	ldio 0xe8, 0x00
	ldio 0xe9, 0x00
	ldio 0xea, 0x00
	ldio 0xeb, 0x00
	ldio 0xec, 0x00
	ldio 0xed, 0x00
	ldio 0xee, 0x00
	ldio 0xef, 0x00
	ret

; ===========================================================================
; SubCPU_Send_Payload - Transfer 192KB Sub-CPU payload from Table Data ROM
; ===========================================================================
; Entry: None (reads from 0xfffeef to check if transfer should proceed)
; Exit:  XIZ restored, payload transferred to Sub-CPU RAM
; Notes: Sends the Sub-CPU firmware payload in multiple 64KB chunks:
;        - 0x830000-0x870000 (5 x 64KB) -> Sub-CPU 0x050000-0x090000
;        - Additional data from Table Data ROM -> Sub-CPU 0x00f000-0x02f000
;        - Final 256 bytes -> Sub-CPU 0x000400 (entry point area)
;        Uses E1 bulk transfer protocol via InterCPU_E1_Bulk_Transfer
;        Includes 0x2000 and 0x100000 iteration delay loops for timing
;        Called during boot sequence after SubCPU_Init_DMA_Channels
; ===========================================================================
SubCPU_Send_Payload:
	push xiz
	cpi8_24 0xfffeef, 0xff
	jrl nz, SubCPU_Payload_Done
	lds32 xiz, 0

SubCPU_Payload_DelayLoop_Short:
	inc 1, xiz
	cp xiz, 0x2000
	jr c, SubCPU_Payload_DelayLoop_Short
	ld xwa, 0x830000
	ld xbc, 0x10000
	ld xde, 0x50000
	call InterCPU_E1_Bulk_Transfer
	ld xwa, 0x840000
	ld xbc, 0x10000
	ld xde, 0x60000
	call InterCPU_E1_Bulk_Transfer
	ld xwa, 0x850000
	ld xbc, 0x10000
	ld xde, 0x70000
	call InterCPU_E1_Bulk_Transfer
	ld xwa, 0x860000
	ld xbc, 0x10000
	ld xde, 0x80000
	call InterCPU_E1_Bulk_Transfer
	ld xwa, 0x870000
	ld xbc, 0x10000
	ld xde, 0x90000
	call InterCPU_E1_Bulk_Transfer
	ld xiz, 0x800000
	cpi8_24 0xfffeed, 0xff
	jr nz, SubCPU_Payload_TransferPart2
	ld xiz, 0x50000
	ld xwa, 0x3e0000
	ld xbc, 0x50000
	call SLIDE_Parse_Header
	cp hl, 0xffff
	jr nz, SubCPU_Payload_TransferPart2
	ld xiz, 0x800000

SubCPU_Payload_TransferPart2:
	ldmm_sriw 0xf9, 0x00, 0x01, 0x04, 0x04
	ld xwa, xiz
	add xwa, 0x100
	ld xbc, 0x10000
	ld xde, 0xf000
	call InterCPU_E1_Bulk_Transfer
	ld xwa, xiz
	add xwa, 0x10100
	ld xbc, 0x10000
	ld xde, 0x1f000
	call InterCPU_E1_Bulk_Transfer
	ld xwa, xiz
	add xwa, 0x20100
	ldw bc, 0xff00
	ld xde, 0x2f000
	call InterCPU_E1_Bulk_Transfer
	ld xwa, xiz
	ldw bc, 0x100
	ld xde, 0x400
	call InterCPU_E1_Bulk_Transfer
	lds32 xiz, 0

SubCPU_Payload_DelayLoop_Long:
	inc 1, xiz
	cp xiz, 0x100000
	jr c, SubCPU_Payload_DelayLoop_Long

SubCPU_Payload_Done:
	pop xiz
	ret

Boot_ClearConfigFlag7:
	resda 7, 1030
	ret

Boot_SetConfigFlag7:
	setda 7, 1030
	ret

Boot_CheckConfigFlag7:
	ldcf_dd16 7, 0x06, 0x04
	scc8 c, a
	cps a, 1
	scc16 z, hl
	ret

; ===========================================================================
; Boot_HandleComboDisplay - Handle boot-time combo display modes
; ===========================================================================
; Entry: A = combo code from CPanel_CheckSpecialCombos (0-4)
; Called from Boot_DisplayScreen after subsystems are initialized.
;   Combo 2: Show firmware version on control panel LEDs
;   Combo 3: Show software version / internal build numbers screen
;   Others: return (no special display)
; ===========================================================================
Boot_HandleComboDisplay:
	cps a, 2
	jr nz, Boot_HandleComboDisplay_Check3
	; --- Combo 2: Firmware version on LEDs ---
	call Get_Firmware_Version	; Returns version byte in L (0x0a = v10)
	and l, 0xf
	extz hl
	lda_24 xbc, LED_patterns_indicating_firmware_version		; LED_patterns_indicating_firmware_version table
	ld_srib3 C, 0x07, 0xe4, 0xec	; Read LED pattern from table
	extz bc
	lds wa, 7
	call Set_LEDs			; Display version on control panel LEDs
	push xiz
	call CPanel_Poll		; Poll control panel (keep LEDs updated)
	pop xiz
	ret

Boot_HandleComboDisplay_Check3:
	cps a, 3
	ret nz
	; --- Combo 3: Software version screen ---
	ldw wa, 0xf0
	call SoundCtrl_SendCommand		; Display SOFT VERSION screen
	ret

Boot_ParseTableDataTimestamp:
	ld xwa, 0x9fffc4
	push xwa
	call ParseInt16
	inc 4, xsp
	ret

Boot_GetSystemPointer:
	ldda16 xhl, 1028
	ret

Boot_ParseSubCPUTimestamp:
	ld xwa, 0x87fff5
	push xwa
	call ParseInt16
	inc 4, xsp
	ret

; ===========================================================================
; Boot_HandleFactoryReset - Factory reset if combo 1 AND checksums invalid
; ===========================================================================
; Entry: A = combo code from CPanel_CheckSpecialCombos
; If combo code == 1 (Initial Setting) AND DRAM[0xFFCA] != 0x5aa5
; (payload checksums invalid, e.g. after Flash ROM replacement),
; zero-fills all work DRAM and SRAM, then restarts the boot sequence.
; Otherwise returns immediately (normal boot continues).
; ===========================================================================
Boot_HandleFactoryReset:
	cpdi16_24 65482, 23205	; DRAM[0xFFCA] == 0x5aa5 (valid checksums)?
	ret z			; Yes -> checksums valid, skip reset
	cps a, 1		; Combo code == 1 (Initial Setting)?
	ret nz			; No -> not requesting reset, return
	; --- Factory Reset: clear all DRAM and SRAM ---
	call ToneGen_FlashReadAndRestore
	ei 7
	calr Boot_ClearAllInterruptEnables	; Clear all interrupt enables
	ld xbc, 0x400

FactoryReset_ClearDRAM:
	lds32 xwa, 0
	st_dpil XWA, 0xe6
	cp xbc, 0x100000
	jr c, FactoryReset_ClearDRAM
	ld xbc, 0x1e0000

FactoryReset_ClearSRAM:
	lds32 xwa, 0
	st_dpil XWA, 0xe6
	cp xbc, 0x200000
	jr c, FactoryReset_ClearSRAM
	sti16_24 0x00ffca, 0x5aa5
	jp Boot_InitIOPorts
FactoryReset_TrailingByte:
	ret

Boot_ReadFDCStatus:
	ldda8 l, 36458
	ret

; =============================================================================
; Shared boot routines (Detect_Region_Code, Get_Region_Code, handlers)
; Uses REGION_CODE_VAR and BOOT_ENTRY_POINT defined at top of file
; =============================================================================
	.include "shared/boot_routines.s"

; =============================================================================
; Boot_CallInitHandlers - Call initialization handlers from table (Shared)
; Configuration for maincpu: byte comparison, local indirect call helper
; =============================================================================
.equ INIT_FLAG_COMPARE_WORD, 0	; maincpu uses byte comparison
.equ INDIRECT_CALL_HELPER, AudioMix_WriteChannelGroup	; indirect call helper in maincpu

	.include "shared/boot_call_init_handlers.s"

; --- System Handlers (interrupts, NMI, UI state machine, task scheduler) ---
	.include "boot/system_handlers.s"

; =============================================================================
; VGA Initialization Code - Shared with table_data ROM
; Uses macros and code from ../shared/vga_init.asm
; =============================================================================

; --- VGA Initialization & Display Subsystem ---
	.include "shared/vga_init.s"
	.include "display/scoop_display.s"
	.include "display/scoop_editor_data.s"
	.include "audio/semenu_routines.s"
	.include "audio/sound_editor_ui.s"

; VoiceSynth command handler case 0
VoiceSynth_CmdCase0:
	.byte 0xc2, 0x04, 0xdd, 0x03, 0x3f, 0x00, 0xb0, 0xf6
	.byte 0x43, 0x14, 0x00, 0x28, 0x00, 0xb3, 0xe8, 0x0e
; VoiceSynth command handler case 1
VoiceSynth_CmdCase1:
; Get resource info based on resource type (WA 0-9)
; Uses offset table at RESOURCE_INFO_HANDLER_OFFSETS (10 entries)
GetResouceInfo:
	cp wa, 0x9
	ret ugt
	add wa, wa
	lda_24 xix, RESOURCE_INFO_HANDLER_OFFSETS
	ld_sriw3 WA, 0x07, 0xf0, 0xe0
	lda_24 xix, RESOURCE_INFO_HANDLERS
	jp_dri 8, 0x07, 0xf0, 0xe0
; Resource info handlers - 10 handlers for different resource types
RESOURCE_INFO_HANDLERS:
	ldada xwa, 63872
	ld (xbc), xwa
	ldada xwa, 65470
	ld xde, xwa
	inc 2, xde
	ldada xwa, 63872
	sub xde, xwa
	ld (xbc + 4), xde
	ret

ResInfo_GetSRAMBankRange:
	lda_24 xwa, 0x1e7800
	ld (xbc), xwa
	lda_24 xwa, 0x1e7800
	ld xde, xwa
	lda_24 xwa, 0x1e8000
	sub xwa, xde
	ld (xbc + 4), xwa
	ret

ResInfo_GetUserAreaRange:
	lda_24 xwa, 0x1ed350
	ld (xbc), xwa
	lda_24 xwa, 0x1ed350
	ld xde, xwa
	lda_24 xwa, 0x200000
	sub xwa, xde
	ld (xbc + 4), xwa
	ret

ResInfo_GetFlashBankRange:
	lda_24 xwa, 0x1e0000
	ld (xbc), xwa
	lda_24 xwa, 0x1e0000
	ld xde, xwa
	lda_24 xwa, 0x1e7800
	sub xwa, xde
	ld (xbc + 4), xwa
	ret

ResInfo_GetTableDataInfo:
	ld xwa, 0x3d3000
	ld (xbc), xwa
	ld xwa, 0x400
	ld (xbc + 4), xwa
	ret

ResInfo_GetSndParamRange:
	lda_24 xwa, 0x0ab000
	ld (xbc), xwa
	ld xwa, 0x5000
	ld (xbc + 4), xwa
	ret

ResInfo_GetVoiceBankRange:
	lda_24 xwa, 0x0b0000
	ld (xbc), xwa
	lda_24 xwa, 0x0b0000
	ld xde, xwa
	lda_24 xwa, 0x0fd800
	sub xwa, xde
	ld (xbc + 4), xwa
	ret

ResInfo_GetToneGenRange:
	lda_24 xwa, 0x094800
	ld (xbc), xwa
	lda_24 xwa, 0x094800
	ld xde, xwa
	lda_24 xwa, 0x0ab000
	sub xwa, xde
	ld (xbc + 4), xwa
	ret

ResInfo_GetMspSettingsRange:
	lda_24 xwa, 0x1e8800
	ld (xbc), xwa
	lda_24 xwa, 0x1e8800
	ld xde, xwa
	lda_24 xwa, 0x1ec400
	sub xwa, xde
	ld (xbc + 4), xwa
	ret

ResInfo_GetResourceListPtr:
	lda_24 xwa, 0xe1ffcc
	ld (xbc), xwa
	lds32 xwa, 0
	ld (xbc + 4), xwa
	ret

ResInfo_NullHandler:
	ret

rcm_ld_XAPR_j:
	jp FloppyDisk_LoadNoteEvents

rcm_sv_XAPR_j:
	jp FloppyDisk_ComputeToneParams

SetSepaOutMode:
	lda xsp, (xsp - 20)
	ld xiy, SepaOut_Config_0
	lda xix, (xsp + 16)
	ldiw
	ldiw
	ld xiy, 0xe1ffea
	lda xix, (xsp + 12)
	ldiw
	ldiw
	ld xiy, 0xe1ffee
	lda xix, (xsp + 8)
	ldiw
	ldiw
	ld xiy, 0xe1fff2
	lda xix, (xsp + 4)
	ldiw
	ldiw
	ld xiy, 0xe1fff6
	ld xix, xsp
	ldiw
	ldiw
	cps wa, 3
	jrl z, SetSepaOut_Mode3
	cps wa, 2
	jrl z, SetSepaOut_Mode2
	cps wa, 1
	jr z, SetSepaOut_Mode1
	cps wa, 0
	jrl nz, FileIO_SendCommand_Return
	ld (xsp + 17), 0x14
	lda xwa, (xsp + 16)
	ld xde, xwa
	lds wa, 0
	lds bc, 4
	call sendCOMM
	ld (xsp + 9), 0x14
	lda xwa, (xsp + 8)
	ld xde, xwa
	lds wa, 0
	lds bc, 4
	call sendCOMM
	ld (xsp + 17), 0x13
	lda xwa, (xsp + 16)
	ld xde, xwa
	lds wa, 0
	lds bc, 4
	call sendCOMM
	ld (xsp + 9), 0x13
	lda xwa, (xsp + 8)
	ld xde, xwa
	lds wa, 0
	lds bc, 4
	call sendCOMM
	ld (xsp + 17), 0x16
	lda xwa, (xsp + 16)
	ld xde, xwa
	lds wa, 0
	lds bc, 4
	call sendCOMM
	ld (xsp + 9), 0x16
	lda xwa, (xsp + 8)
	ld xde, xwa
	lds wa, 0
	lds bc, 4
	call sendCOMM
	jrl FileIO_SendCommand_Return

SetSepaOut_Mode1:
	ld (xsp + 13), 0x14
	lda xwa, (xsp + 12)
	ld xde, xwa
	lds wa, 0
	lds bc, 4
	call sendCOMM
	ld (xsp + 9), 0x14
	lda xwa, (xsp + 8)
	ld xde, xwa
	lds wa, 0
	lds bc, 4
	call sendCOMM
	ld (xsp + 17), 0x13
	lda xwa, (xsp + 16)
	ld xde, xwa
	lds wa, 0
	lds bc, 4
	call sendCOMM
	ld (xsp + 9), 0x13
	lda xwa, (xsp + 8)
	ld xde, xwa
	lds wa, 0
	lds bc, 4
	call sendCOMM
	ld (xsp + 17), 0x16
	lda xwa, (xsp + 16)
	ld xde, xwa
	lds wa, 0
	lds bc, 4
	call sendCOMM
	ld (xsp + 9), 0x16
	lda xwa, (xsp + 8)
	ld xde, xwa
	lds wa, 0
	lds bc, 4
	call sendCOMM
	jrl FileIO_SendCommand_Return

SetSepaOut_Mode2:
	ld (xsp + 13), 0x14
	lda xwa, (xsp + 12)
	ld xde, xwa
	lds wa, 0
	lds bc, 4
	call sendCOMM
	ld (xsp + 9), 0x14
	lda xwa, (xsp + 8)
	ld xde, xwa
	lds wa, 0
	lds bc, 4
	call sendCOMM
	ld (xsp + 13), 0x13
	lda xwa, (xsp + 12)
	ld xde, xwa
	lds wa, 0
	lds bc, 4
	call sendCOMM
	ld (xsp + 9), 0x13
	lda xwa, (xsp + 8)
	ld xde, xwa
	lds wa, 0
	lds bc, 4
	call sendCOMM
	ld (xsp + 13), 0x16
	lda xwa, (xsp + 12)
	ld xde, xwa
	lds wa, 0
	lds bc, 4
	call sendCOMM
	ld (xsp + 9), 0x16
	lda xwa, (xsp + 8)
	ld xde, xwa
	lds wa, 0
	lds bc, 4
	call sendCOMM
	jr FileIO_SendCommand_Return

SetSepaOut_Mode3:
	ld (xsp + 13), 0x14
	lda xwa, (xsp + 12)
	ld xde, xwa
	lds wa, 0
	lds bc, 4
	call sendCOMM
	ld (xsp + 1), 0x14
	lda xwa, (xsp)
	ld xde, xwa
	lds wa, 0
	lds bc, 4
	call sendCOMM
	ld (xsp + 13), 0x13
	lda xwa, (xsp + 12)
	ld xde, xwa
	lds wa, 0
	lds bc, 4
	call sendCOMM
	ld (xsp + 5), 0x13
	lda xwa, (xsp + 4)
	ld xde, xwa
	lds wa, 0
	lds bc, 4
	call sendCOMM
	ld (xsp + 13), 0x16
	lda xwa, (xsp + 12)
	ld xde, xwa
	lds wa, 0
	lds bc, 4
	call sendCOMM
	ld (xsp + 5), 0x16
	lda xwa, (xsp + 4)
	ld xde, xwa
	lds wa, 0
	lds bc, 4
	call sendCOMM

FileIO_SendCommand_Return:
	lda xsp, (xsp + 20)
	ret

fopen_ext:
	jp FileIO_OpenWithMode

fwrite_ext:
	jp FileIO_WriteByte_Impl

fread_ext:
	jp FileIO_ReadBlock

fclose_ext:
	jp FileIO_CloseHandle

ferror_ext:
	jp FileIO_ReturnError

rot_rdq_X:
	jp TaskSched_YieldToQueue

set_flg_X:
	jp TaskSched_SignalEvent

wai_flg_X:
	jp TaskSched_WaitForEvent

sig_sem_X:
	jp Audio_Lock_Release

preq_sem_X:
	jp AudioLock_TryAcquire

wai_sem_X:
	jp Audio_Lock_Acquire

ref_sem_X:
	jp AudioLock_GetCount

snd_msg_X:
	jp TaskMsg_Send

rcv_msg_X:
	jp TaskMsg_Receive

prcv_msg_X:
	jp TaskMsg_TryReceive

get_tid_X:
	jp TaskSched_GetCurrentGroup

pdly_tim_X:
	jp TaskSched_DelayTicks

PlayHalt:
	dec 2, xsp
	ld (xsp), a
	call SeqBuf_Init
	call NoteMap_SendAllNotesOff
	call Part_ReinitAllActive
	call AccWrap_PlayModeDispatch
	cp (xsp), 0x0
	jr z, PlayHalt_SkipSetFlag
	setda 2, 10407

PlayHalt_SkipSetFlag:
	call AccompSeq_StopSequence
	call AudioInit_RefreshToneBank
	call NoteMap_ProcessAndMerge
	call Voice_InitializeAll
	call Voice_InitTablePair
	call Voice_InitTableGroup
	call MIDI_SendAllSoundOff
	call MidiThru_Enable
	inc 2, xsp
	ret

PlayStandBy:
	bitda 2, 10407
	jr z, PlayStandBy_SkipClearFlag
	resda 2, 10407

PlayStandBy_SkipClearFlag:
	resda 3, 10407
	call SeqAcc_InitPlaybackState
	jp MidiThru_Disable

EditSwRefresh:
	call CPanel_InitButtonState_SaveRegs
	call RefreshSwEvent
	jp RefreshApTask

putc_mtx_bf_X:
	extz wa
	pushw wa
	call SeqBuf_MidiOut_WriteByte
	inc 2, xsp
	ret

putc_mrx_bf_X:
	extz wa
	pushw wa
	call SeqMain_WriteByte
	inc 2, xsp
	ret

midi_out_en_X:
	jp MIDI_SC0_TX_DISPATCH

GetAdr_sqbtof:
	ldada xhl, 1052
	ret

GetAdr_sq_beadt:
	ldada xhl, 1051
	ret

GetAdr_sqsrtc:
	ldada xhl, 1057
	ret

GetAdr_rtmcfg:
	ldada xhl, 10407
	ret

SetGlobalError:
	stda8 32578, a
	ret

malloc_X:
	pushw wa
	call Malloc
	inc 2, xsp
	ret

free_X:
	push xwa
	call Free
	inc 4, xsp
	ret


; --- Wallpaper & Demo Routines ---
	.include "ui/setwall_routines.s"
	.include "ui/ui_playback_modes.s"
	.include "demo/demo_routines.s"
	.include "demo/demo_seq_bridge.s"
	.include "sequencer/smf_playback.s"
	.include "sequencer/smf_tonegen_core.s"
; --- SMF Event Processing, Sequencer UI & Engine ---
	.include "sequencer/smf_event_processor.s"
	.include "sequencer/seq_audio_mode.s"
	.include "sequencer/rhythm_routines.s"
	.include "sequencer/accompaniment_engine.s"
Voice_InitBankDataSafe:
	push xiz
	call Voice_InitBankData
	pop xiz
	ret

Voice_InitBankDataSafe_Alt1:
	push	xiz
	call	Voice_BankLookupCode
	pop	xiz
	ret
	push	xiz
	call	Voice_RefreshBankData
	pop	xiz
	ret
	push	xiz
	call	Voice_InitBankTables
	pop	xiz
	ret

Voice_InitBankTables:
	ld xiy, Voice_BankHeaderDefaults
	ld xix, 0x1e8800
	ldw bc, 0x10
	ldirw
	ldb a, 0xc

Voice_InitBankTables_Loop:
	ld xiy, Voice_BankSlotZeroInit
	ldw bc, 0x8
	ldirw
	dec 1, a
	jr nz, Voice_InitBankTables_Loop
	ld xiy, BLOCK_OF_64_ZEROES
	ld xix, 0x1e8a00
	ldw bc, 0x20
	ldirw
	ld xiy, HEADER__COMPILE_BANKS
	ld xix, 0x1e8a40
	ldw bc, 0x20
	ldirw
	ld xiy, HEADER__USER_BANKS
	ld xix, 0x1e8a80
	ldw bc, 0x20
	ldirw
	ld xix, 0x1e8b00
	ldb a, 0x39

Voice_InitBankTables_SlotLoop:
	ld xiy, Voice_SlotTemplate
	ldw bc, 0x80
	ldirw
	dec 1, a
	jr nz, Voice_InitBankTables_SlotLoop
	stdi16 32280, 57
	ret

	.include "audio/voice_bank_defaults.s"
Voice_InitBankData:
	calr Voice_InitBankTables
	ld xiy, Voice_FactoryPresetData
	ld xix, 0x1e8820
	ldw bc, 0xf0
	ldirw
	ld xix, 0x1e8a00
	ld xiy, BLOCK_OF_64_ZEROES
	ldw bc, 0x60
	ldirw
	ld xix, 0x1e8b00
	ld xiy, MSP_FACTORY_DEFAULTS
	ldw bc, 0xa80
	ldirw
	calr CountAvailableVoiceSlots
	ret

Voice_BankLookupCode:
	.byte 0x45, 0x00, 0x88, 0x1e, 0x00, 0xb5, 0x00, 0x48
	.byte 0xbd, 0x01, 0x00, 0x00, 0xbd, 0x02, 0x00, 0x4b
	ret

Voice_RefreshBankData:
	calr Voice_ComputeAllocSize
	ret

Voice_ResetToFactoryBanks:
	ldw wa, 0xa
	ld xhl, 0x7aec
	ldw bc, 0xff
	ldw de, 0xf6
	calr Voice_SetBankParams
	ld xhl, 0x7bec
	calr Voice_SetBankParams
	calr Voice_ReinitIfBankCountNonzero
	calr Voice_ReinitIfBitFlagSet
	calr CountAvailableVoiceSlots
	ret

Voice_SetBankParams:
	ld (xhl + 256), wa
	ld (xhl + 2), bc
	ld (xhl + 4), wa
	ld (xhl + 6), wa
	ld (xhl + 8), de
	ret

Voice_ReinitIfBankCountNonzero:
	ld xiy, 0x1e8800
	add xiy, 0xe
	ld wa, (xiy)
	cps wa, 0
	jr z, Voice_ReinitIfBankCount_Done
	calr Voice_InitBankData

Voice_ReinitIfBankCount_Done:
	ret

Voice_ReinitIfBitFlagSet:
	ld xiy, 0x1e8800
	add xiy, 0xa
	ld a, (xiy)
	bit 0, a
	jr z, Voice_ReinitIfBitFlag_Done
	calr Voice_InitBankData

Voice_ReinitIfBitFlag_Done:
	ret

CountAvailableVoiceSlots:
	ldw wa, 0x39
	ldw de, 0x38

CountVoiceSlots_Loop:
	ld hl, de
	calr Voice_GetSlotAddress
	bitm 7, (xhl)
	jr z, CountVoiceSlots_NotUsed
	dec 1, wa

CountVoiceSlots_NotUsed:
	dec 1, de
	cp de, 0xffff
	jr z, CountVoiceSlots_Done
	jr CountVoiceSlots_Loop

CountVoiceSlots_Done:
	stda16 32280, xwa
	ret

Voice_GetSlotAddress:
	and xhl, 0xffff
	sla xhl, 8
	add xhl, 0x1e8b00
	ret

Voice_ComputeAllocSize:
	ld xhl, 0x3c00
	ld xiy, 0x1e8800
	add xiy, 0x200
	add xiy, 0x3800
	ldb c, 0x39

Voice_AllocSize_Loop:
	cps c, 0
	jr z, Voice_AllocSize_Done
	ld a, (xiy)
	bit 7, a
	jr nz, Voice_AllocSize_Done
	sub xhl, 0x100
	sub xiy, 0x100
	dec 1, c
	jr Voice_AllocSize_Loop

Voice_AllocSize_Done:
	ld xwa, xhl
	add xwa, 0x3ff
	and xwa, 0xfffffc00
	srl xwa, 4
	ld xiy, 0x1e881c
	ld (xiy), wa
	calr CountAvailableVoiceSlots
	ret

Voice_FactoryPresetData:
	.incbin "includes/generated/voice_factory_presets.bin"

; F6F60F:
	.zero 32

; MSP_FACTORY_DEFAULTS:	
	.include "msp_factory_defaults.s"
	.include "sequencer/seq_event_playback.s"
	.include "midi/computer_interface_config.s"
	.include "midi/ac_listener_handlers.s"
	.include "midi/sysex_routines.s"
	.include "midi/param_load_routines.s"
	.include "ui/ui_control_panel.s"
	.include "audio/presentation_sound_nav.s"
	.include "ui/ui_window_procs.s"
	exts	xwa
	add	xwa, xhl
	add	xde, xwa
	bitm	7, (xde)
	jr	z, 4
	resm	6, (xde)
	jr	2
	setm	6, (xde)
	incm8	1, (xsp+24)
	ld	xwa, (xsp+12)
	add	(xsp+4), xwa
	ld	xwa, (xsp+4)
	sra	xwa, 0
	ld	(xbc), wa
	ld	xwa, (xsp+16)
	add	(xbc+2), wa
	lds32	xwa, 1
	add	(xsp+20), xwa
	ld	xwa, (xsp+20)
	cp	xwa, (xsp+8)
	jrl	le, -249
	jrl	330
	ld	xwa, (xsp+8)
	sla	xwa, 0
	ld	xbc, (xsp+4)
	call	Math_DivideSigned32
	ld	xiz, xhl
	ld	xwa, (xsp+16)
	ld	xbc, xiz
	call	Math_MultiplyAccumulate
	ld	(xsp+16), xhl
	ld	xbc, (xsp+34)
	ld	xwa, xbc
	inc	2, xwa
	ld	(xsp+34), xwa
	ld	wa, (xwa)
	exts	xwa
	ld	(xsp+8), xwa
	sla	xwa, 0
	ld	(xsp+8), xwa
	ld	xwa, 32768
	add	(xsp+8), xwa
	lds32	xwa, 0
	ld	(xsp+20), xwa
	ld	xwa, (xsp+4)
	cp	xwa, 0
	jrl	lt, 255
	cp	(xsp+24), 3
	jr	ule, 7
	ld	(xsp+24), 0
	jrl	206
	cp	(xsp+24), 1
	jrl	ugt, 196
	ld8_24	l, 257962
	ld	xwa, (xsp+34)
	ld	wa, (xwa)
	exts	xwa
	ld	xde, xwa
	sll	xde, 2
	add	xde, xwa
	sll	xde, 6
	cps	l, 2
	jrl	z, 146
	cps	l, 1
	jr	z, 117
	cps	l, 0
	jrl	nz, 160
	ld	xhl, xbc
	ld	iy, (xsp+50)
	ld	wa, (xbc)
	exts	xwa
	add	xwa, xde
	lda_24	xix, 277504
	add	xix, xwa
	cpw	(xsp+50), 245
	jr	z, 30
	andmi8	(xix), 96
	ld	wa, iy
	and	wa, 159
	add	(xix), a
	ld	de, iy
	and	de, 128
	ld	a, (xix)
	and	a, 128
	extz	wa
	cp	wa, de
	jr	nz, 54
	jr	105
	ld32_24	xiy, 197714
	ld	de, (xhl)
	exts	xde
	ld	wa, (xhl+2)
	exts	xwa
	ld	xhl, xwa
	sll	xhl, 2
	add	xhl, xwa
	sll	xhl, 6
	add	xhl, xde
	add	xiy, xhl
	andmi8	(xix), 96
	ld	a, (xiy)
	and	a, 159
	add	(xix), a
	ld	e, (xiy)
	and	e, 128
	ld	a, (xix)
	and	a, 128
	cp	a, e
	jr	z, 53
	xormi8	(xix), 96
	jr	48
	ld	wa, (xbc)
	exts	xwa
	add	xwa, xde
	lda_24	xde, 277504
	add	xde, xwa
	bitm	7, (xde)
	jr	z, 4
	resm	5, (xde)
	jr	27
	setm	5, (xde)
	jr	23
	ld	wa, (xbc)
	exts	xwa
	add	xwa, xde
	lda_24	xde, 277504
	add	xde, xwa
	bitm	7, (xde)
	jr	z, 4
	resm	6, (xde)
	jr	2
	setm	6, (xde)
	incm8	1, (xsp+24)
	ld	xwa, (xsp+16)
	add	(xsp+8), xwa
	ld	xde, (xsp+8)
	sra	xde, 0
	ld	xwa, (xsp+34)
	ld	(xwa), de
	ld	xwa, (xsp+12)
	add	(xbc), wa
	lds32	xwa, 1
	add	(xsp+20), xwa
	ld	xwa, (xsp+20)
	cp	xwa, (xsp+4)
	jrl	le, -255
	lda	xwa, (xsp+38)
	ld	xbc, (xsp+30)
	ld	bc, (xbc)
	ld	(xwa+2), bc
	ld	xbc, (xsp+56)
	ld	bc, (xbc)
	ld	(xwa), bc
	ld	xbc, (xsp+52)
	ld	bc, (xbc)
	ld	(xwa+4), bc
	ld	xbc, (xsp+26)
	ld	bc, (xbc)
	ld	(xwa+6), bc
	calr	-26029
	pop	xiz
	lda	xsp, (xsp+56)
	ret
	dec	2, xsp
	push	xiz
	ld	(xsp+4), bc
	ld	xiz, xwa
	calr	-26605
	cps	hl, 0
	jr	z, 29
	ld8_24	a, 257960
	st8_24	257962, a
	cpdi16_24	197710, 0
	jr	z, 51
	ld	xwa, xiz
	ld	bc, (xsp+4)
	calr	78
	jr	41
	ldw	wa, 16
	calr	-26882
	ld	xwa, xhl
	lda_24	xbc, 16452973
	ld	(xwa), xbc
	ld	xiy, xiz
	lda	xix, (xwa+4)
	lds	bc, 4
	ldirw
	ld	bc, (xsp+4)
	ld	(xwa+12), bc
	ld8_24	c, 257960
	ld	(xwa+14), c
	calr	-27133
	pop	xiz
	inc	2, xsp
	ret
	ld	xbc, xwa
	lda	xwa, (xbc+4)
	ld	de, (xbc+12)
	ld	c, (xbc+14)
	st8_24	257962, c
	cpdi16_24	197710, 0
	ret	z
	ld	bc, de
	calr	1
	ret
	lda	xsp, (xsp-18)
	pushw	iz
	ld	(xsp+14), bc
	ld	(xsp+16), xwa
	ld	xwa, (xsp+16)
	inc	2, xwa
	ld	(xsp+2), xwa
	cpw	(xwa), 0
	jr	ge, 7
	ld	xwa, (xsp+2)
	ldw	(xwa), 0
	ld	xwa, (xsp+16)
	cpw	(xwa), 0
	jr	ge, 4
	ldw	(xwa), 0
	ld	xwa, (xsp+16)
	lda	xhl, (xwa+4)
	cpw	(xhl), 320
	jr	lt, 4
	ldw	(xhl), 319
	ld	xwa, (xsp+16)
	lda	xix, (xwa+6)
	cpw	(xix), 240
	jr	lt, 4
	ldw	(xix), 239
	ld	de, (xix)
	ld	xwa, (xsp+2)
	ld	iz, (xwa)
	lda	xwa, (xsp+10)
	lda	xbc, (xsp+6)
	lda	xiy, (xbc+2)
	ld	(xwa+2), iz
	cp	de, iz
	jr	nz, 20
	ld	xde, (xsp+16)
	ld	de, (xde)
	ld	(xwa), de
	ld	de, (xhl)
	ld	(xbc), de
	ld	de, (xix)
	ld	(xiy), de
	ld	de, (xsp+14)
	jr	110
	ld	xde, (xsp+16)
	ld	de, (xde)
	ld	(xwa), de
	ld	de, (xhl)
	ld	(xbc), de
	ld	xde, (xsp+2)
	ld	de, (xde)
	ld	(xiy), de
	ld	de, (xsp+14)
	calr	-3777
	lda	xwa, (xsp+10)
	ld	xbc, (xsp+16)
	lda	xde, (xbc+6)
	ld	bc, (xde)
	ld	(xwa+2), bc
	lda	xbc, (xsp+6)
	ld	de, (xde)
	ld	(xbc+2), de
	ld	de, (xsp+14)
	calr	-3805
	lda	xwa, (xsp+10)
	ld	xhl, (xsp+16)
	ld	bc, (xhl+2)
	ld	(xwa+2), bc
	ld	bc, (xhl)
	ld	(xwa), bc
	lda	xbc, (xsp+6)
	ld	de, (xhl)
	ld	(xbc), de
	ld	de, (xhl+6)
	ld	(xbc+2), de
	ld	de, (xsp+14)
	calr	-3840
	lda	xwa, (xsp+10)
	ld	xbc, (xsp+16)
	lda	xde, (xbc+4)
	ld	bc, (xde)
	ld	(xwa), bc
	lda	xbc, (xsp+6)
	ld	de, (xde)
	ld	(xbc), de
	ld	de, (xsp+14)
	calr	-3866
	ld	xwa, (xsp+16)
	calr	-26392
	popw	iz
	lda	xsp, (xsp+18)
	ret

DrawText_QueueOrDirect:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 8), xde
	ld (xsp + 12), xbc
	ld (xsp + 16), xwa
	calr IS_XSP_INSIDE_4K_REGION_AT_1C032
	cps hl, 0
	jr z, DrawText_QueueDeferred
	ld8_24 a, 0x03efa8
	st8_24 0x03efaa, a
	cpdi16_24 197710, 0
	jrl z, DrawText_PopAndReturn
	ld xwa, (xsp + 28)
	push xwa
	pushm (xsp + 30)
	pushm (xsp + 30)
	ld xwa, (xsp + 24)
	ld xbc, (xsp + 20)
	ld xde, (xsp + 16)
	calr TextRender_BeginDraw
	jr DrawText_PopAndReturn

DrawText_QueueDeferred:
	ld xwa, (xsp + 8)
	push xwa
	call Strlen
	inc 4, xsp
	inc 1, hl
	ld wa, hl
	calr DrawQueue_Alloc
	ld (xsp + 4), xhl
	ldw wa, 0x1e
	calr DrawQueue_Alloc
	ld xiz, xhl
	lda_24 xwa, 0xfb0f31
	ld (xhl), xwa
	ld xwa, (xsp + 16)
	ld xiy, xwa
	lda xix, (xhl + 4)
	lds bc, 4
	ldirw
	ld xwa, (xsp + 12)
	ld xiy, xwa
	lda xix, (xhl + 12)
	ldiw
	ldiw
	ld xbc, (xsp + 4)
	ld (xhl + 16), xbc
	ld xwa, (xsp + 8)
	push xwa
	push xbc
	call Strcpy
	inc 8, xsp
	ld xwa, (xsp + 28)
	ld (xiz + 20), xwa
	ld wa, (xsp + 26)
	ld (xiz + 24), wa
	ld wa, (xsp + 24)
	ld (xiz + 26), wa
	ld8_24 a, 0x03efa8
	ld (xiz + 28), a
	ld xwa, xiz
	calr DisplayCmd_DequeueAndExecute

DrawText_PopAndReturn:
	pop xiz
	lda xsp, (xsp + 16)
	retd 0x8
	push xiz
	ld xiz, xwa
	lda xhl, (xiz + 4)
	lda xbc, (xiz + 12)
	ld xiy, (xiz + 20)
	ld ix, (xiz + 24)
	ld de, (xiz + 26)
	ld a, (xiz + 28)
	st8_24 0x03efaa, a
	cpdi16_24 197710, 0
	jr z, DrawText_DeferredFreeAndReturn
	push xiy
	pushw ix
	pushw de
	ld xde, (xiz + 16)
	ld xwa, xhl
	calr TextRender_BeginDraw

DrawText_DeferredFreeAndReturn:
	ld xwa, (xiz + 16)
	calr DrawFunc_Return
	pop xiz
	ret

TextRender_BeginDraw:
	st_dri3b L, 0xfd, 0xc6, 0xfe
	push xiz
	st_dri3l XDE, 0xfd, 0x36, 0x01
	st_dri3l XWA, 0xfd, 0x3a, 0x01
	ld_sril XWA, (xsp + 0x0136)
	cp (xwa), 0x0
	jrl z, TextRender_PopAndReturn
	ld_sril XWA, (xsp + 0x013a)
	inc 2, xwa
	ld (xsp + 34), xwa
	cpw (xwa), 0x0
	jr ge, TextRender_ClampYOrigin
	ld xwa, (xsp + 34)
	ldw (xwa), 0x0

TextRender_ClampYOrigin:
	ld_sril XWA, (xsp + 0x013a)
	cpw (xwa), 0x0
	jr ge, TextRender_ClampXOrigin
	ldw (xwa), 0x0

TextRender_ClampXOrigin:
	ld_sril XWA, (xsp + 0x013a)
	inc 4, xwa
	cpw (xwa), 0x140
	jr lt, TextRender_ClampXRight
	ldw (xwa), 0x13f

TextRender_ClampXRight:
	ld_sril XWA, (xsp + 0x013a)
	lda xde, (xwa + 6)
	cpw (xde), 0xf0
	jr lt, TextRender_SetupColorAndFont
	ldw (xde), 0xef

TextRender_SetupColorAndFont:
	ld xiy, xbc
	st_dri3b D, 0xfd, 0x2a, 0x01
	ldiw
	ldiw
	ld_sril XIX, (xsp + 0x0146)
	or xix, xix
	jr nz, TextRender_ClampNullXStart
	dec_sriw 2, 0xfd, 0x2c, 0x01

TextRender_ClampNullXStart:
	st_dri3b C, 0xfd, 0x2a, 0x01
	cpw (xhl), 0x0
	jr ge, TextRender_ClampNullYStart
	ldw (xhl), 0x0

TextRender_ClampNullYStart:
	lda xbc, (xhl + 2)
	cpw (xbc), 0x0
	jr ge, TextRender_LoadFontData
	ldw (xbc), 0x0

TextRender_LoadFontData:
	ld xwa, 0x945c00
	ld (xsp + 4), xwa
	ld xwa, xix
	sll xwa, 4
	add (xsp + 4), xwa
	ld xwa, (xsp + 4)
	ld xiz, (xwa + 12)
	ld xiy, (xwa + 8)
	or xiz, xiz
	jr nz, TextRender_StoreGlyphPos
	ld wa, (xwa)
	ld (xsp + 20), wa
	ld xwa, (xsp + 4)
	ld wa, (xwa + 6)
	ld (xsp + 22), wa
	jr TextRender_SetupGlyph

TextRender_StoreGlyphPos:
	ld (xsp + 8), xiz

TextRender_SetupGlyph:
	ld (xsp + 12), xiy
	st_dri3b H, 0xfd, 0x2e, 0x01
	lda xiy, (xiz + 2)
	ld wa, (xbc)
	ld (xiy), wa
	ld wa, (xhl)
	ld (xiz), wa
	ld wa, (xhl)
	dec 1, wa
	ld (xiz + 4), wa
	ld xwa, (xsp + 4)
	ld hl, (xwa + 2)
	add hl, (xbc)
	lda xbc, (xiz + 6)
	ld wa, hl
	ld (xbc), hl
	or xix, xix
	jr nz, TextRender_HasCustomFont
	dec 1, wa
	ld (xbc), wa

TextRender_HasCustomFont:
	ld xwa, (xsp + 34)
	ld wa, (xwa)
	cp (xiy), wa
	jr ge, TextRender_DefaultFontWidth
	ld (xiy), wa

TextRender_DefaultFontWidth:
	ld wa, (xde)
	cp (xbc), wa
	jr le, TextRender_CustomFontWidth
	ld (xbc), wa

TextRender_CustomFontWidth:
	ld_sril XWA, (xsp + 0x0136)
	push xwa
	lda xwa, (xsp + 42)
	push xwa
	call Strcpy
	inc 8, xsp
	lda xwa, (xsp + 38)
	ld (xsp + 30), xwa
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 12)
	or xwa, xwa
	jr nz, TextRender_ProcessStringLoop
	ld xwa, (xsp + 30)
	push xwa
	call Strlen
	inc 4, xsp
	ld wa, (xsp + 20)
	mul xwa, xhl
	jr TextRender_AddToDrawPos

TextRender_ProcessStringLoop:
	ld xwa, (xsp + 30)
	cp (xwa), 0x0
	jr z, TextRender_MaxWidthReached

TextRender_CharWidthAccum:
	ld xwa, (xsp + 30)
	ld_spib C, 0xe0
	ld (xsp + 30), xwa
	sub c, 0x20
	extz bc
	sla bc, 2
	ld xwa, (xsp + 8)
	exts xbc
	add xbc, xwa
	ld a, (xbc)
	extz wa
	ld (xsp + 20), wa
	ld xwa, (xsp + 30)
	cp (xwa), 0x0
	jr nz, TextRender_CharWidthAccum

TextRender_MaxWidthReached:
	ld wa, (xsp + 20)

TextRender_AddToDrawPos:
	add_sriw_mr WA, 0xfd, 0x32, 0x01
	st_dri3b W, 0xfd, 0x2e, 0x01
	lda xde, (xwa + 2)
	ld_sril XBC, (xsp + 0x013a)
	ld bc, (xbc + 2)
	cp (xde), bc
	jr ge, TextRender_ClampGlyphTop
	ld (xde), bc

TextRender_ClampGlyphTop:
	ld de, (xwa)
	ld_sril XBC, (xsp + 0x013a)
	cp de, (xbc)
	jr ge, TextRender_ClampGlyphLeft
	ld bc, (xbc)
	ld (xwa), bc

TextRender_ClampGlyphLeft:
	lda xde, (xwa + 4)
	ld_sril XBC, (xsp + 0x013a)
	ld bc, (xbc + 4)
	cp (xde), bc
	jr le, TextRender_ClampGlyphRight
	ld (xde), bc

TextRender_ClampGlyphRight:
	lda xde, (xwa + 6)
	ld_sril XBC, (xsp + 0x013a)
	ld bc, (xbc + 6)
	cp (xde), bc
	jr le, TextRender_ClampGlyphBottom
	ld (xde), bc

TextRender_ClampGlyphBottom:
	ld_sriw BC, (xsp + 0x0142)
	cp bc, 0xf7
	call_24 nz, 0xfaf938
	lda xwa, (xsp + 38)
	ld (xsp + 30), xwa
	cp (xwa), 0x0
	jrl z, TextRender_Finalize

TextRender_CharEncodeAndDraw:
	ld xhl, (xsp + 30)
	ld c, (xhl)
	extz bc
	lda_24 xde, 0xeab1b4
	ld_srib3 C, 0x07, 0xe8, 0xe4
	ld (xhl), c
	ld xbc, (xsp + 4)
	ld xwa, (xbc + 12)
	or xwa, xwa
	jr nz, TextRender_CustomFontCharDraw
	ld bc, (xbc + 2)
	ld a, (xhl)
	sub a, 0x20
	extz wa
	mrdw3 0x9f, 0x16, 0x40
	mul xwa, xbc
	ld (xsp + 16), xwa
	ld xwa, (xsp + 12)
	add (xsp + 16), xwa
	jr TextRender_BeginScanLines

TextRender_CustomFontCharDraw:
	ld xwa, (xsp + 30)
	ld c, (xwa)
	sub c, 0x20
	extz bc
	sla bc, 2
	ld xwa, (xsp + 8)
	exts xbc
	add xbc, xwa
	ld a, (xbc)
	extz wa
	ld (xsp + 20), wa
	ld (xsp + 22), wa
	srl wa, 3
	inc 1, wa
	ld (xsp + 22), wa
	ld wa, (xbc + 2)
	extz xwa
	ld (xsp + 16), xwa
	ld xwa, (xsp + 12)
	add (xsp + 16), xwa

TextRender_BeginScanLines:
	ldw (xsp + 26), 0x0
	cpw (xsp + 22), 0x0
	jrl ule, TextRender_AdvanceStringPointer

TextRender_ScanLineLoop:
	ld bc, (xsp + 26)
	sll bc, 3
	ld wa, (xsp + 20)
	sub wa, bc
	ld (xsp + 24), wa
	cpw (xsp + 24), 0x8
	jr c, TextRender_SelectDrawMode
	ldw (xsp + 24), 0x8

TextRender_SelectDrawMode:
	ld8_24 a, 0x03efaa
	cps a, 2
	jrl z, TextRender_XorMode_Init
	cps a, 1
	jrl z, TextRender_BitMask5_Init
	cps a, 0
	jrl nz, TextRender_AdvanceToNextLine
	ldw (xsp + 28), 0x0
	jrl TextRender_BitMask4_CheckColumnEnd

TextRender_BitMask4_DrawPixel:
	ld xwa, (xsp + 16)
	cp (xwa), 0x0
	jrl z, TextRender_BitMask5_ProcessCharacter
	st_dri3b A, 0xfd, 0x26, 0x01
	st_dri3b W, 0xfd, 0x2a, 0x01
	ld (xsp + 34), xwa
	ld hl, (xwa + 2)
	add hl, (xsp + 28)
	ld de, hl
	ld (xbc + 2), hl
	ld_sril XWA, (xsp + 0x013a)
	cp hl, (xwa + 2)
	jrl lt, TextRender_BitMask5_ProcessCharacter
	cp de, (xwa + 6)
	jrl gt, TextRender_AdvanceToNextLine
	ld wa, de
	exts xwa
	ld xde, xwa
	sll xde, 2
	add xde, xwa
	sll xde, 6
	ld xwa, (xsp + 34)
	ld wa, (xwa)
	exts xwa
	add xwa, xde
	lda_24 xix, 0x043c00
	add xix, xwa
	lds hl, 0
	cpw (xsp + 24), 0x0
	jr ule, TextRender_BitMask5_ProcessCharacter

TextRender_BitMask4_PixelLoop:
	ld xwa, (xsp + 34)
	ld de, (xwa)
	add de, hl
	ld (xbc), de
	ld_sril XWA, (xsp + 0x013a)
	cp de, (xwa)
	jr lt, TextRender_BitMask4_Return
	ld de, (xbc)
	cp de, (xwa + 4)
	jr gt, TextRender_BitMask5_ProcessCharacter
	lds wa, 7
	sub wa, hl
	lds iy, 1
	and a, 0xf
	jr z, TextRender_BitMask4_ShiftAndTest
	slaa iy

TextRender_BitMask4_ShiftAndTest:
	ld xwa, (xsp + 16)
	ld a, (xwa)
	extz wa
	and wa, iy
	jr z, TextRender_BitMask4_Return
	andmi8 (xix), 0x60
	ld_sriw DE, (xsp + 0x0144)
	ld wa, de
	and wa, 0x9f
	add (xix), a
	and de, 0x80
	ld a, (xix)
	and a, 0x80
	extz wa
	cp wa, de
	jr z, TextRender_BitMask4_Return
	xormi8 (xix), 0x60

TextRender_BitMask4_Return:
	inc 1, hl
	inc 1, xix
	cp hl, (xsp + 24)
	jr c, TextRender_BitMask4_PixelLoop

TextRender_BitMask5_ProcessCharacter:
	lds32 xwa, 1
	add (xsp + 16), xwa
	incm 1, (xsp + 28)

TextRender_BitMask4_CheckColumnEnd:
	ld xwa, (xsp + 4)
	ld wa, (xwa + 2)
	cp (xsp + 28), wa
	jrl c, TextRender_BitMask4_DrawPixel
	jrl TextRender_AdvanceToNextLine

TextRender_BitMask5_Init:
	ldw (xsp + 28), 0x0
	jrl TextRender_BitMask5_CheckColumnEnd

TextRender_BitMask5_DrawPixel:
	ld xwa, (xsp + 16)
	cp (xwa), 0x0
	jrl z, TextRender_BitMask5_AdvancePointer
	st_dri3b D, 0xfd, 0x26, 0x01
	st_dri3b B, 0xfd, 0x2a, 0x01
	ld hl, (xde + 2)
	add hl, (xsp + 28)
	ld bc, hl
	ld (xix + 2), hl
	ld_sril XWA, (xsp + 0x013a)
	cp hl, (xwa + 2)
	jr lt, TextRender_BitMask5_AdvancePointer
	cp bc, (xwa + 6)
	jrl gt, TextRender_AdvanceToNextLine
	ld wa, bc
	exts xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	sll xbc, 6
	ld wa, (xde)
	exts xwa
	add xwa, xbc
	lda_24 xiz, 0x043c00
	add xiz, xwa
	lds hl, 0
	cpw (xsp + 24), 0x0
	jr ule, TextRender_BitMask5_AdvancePointer

TextRender_BitMask5_PixelLoop:
	ld bc, (xde)
	add bc, hl
	ld (xix), bc
	ld_sril XIY, (xsp + 0x013a)
	cp bc, (xiy)
	jr lt, TextRender_BitMask5_Return
	ld wa, (xix)
	cp wa, (xiy + 4)
	jr gt, TextRender_BitMask5_AdvancePointer
	lds wa, 7
	sub wa, hl
	lds iy, 1
	and a, 0xf
	jr z, TextRender_BitMask5_ShiftAndTest
	slaa iy

TextRender_BitMask5_ShiftAndTest:
	ld xwa, (xsp + 16)
	ld a, (xwa)
	extz wa
	and wa, iy
	jr z, TextRender_BitMask5_Return
	bitm 7, (xiz)
	jr z, TextRender_BitMask5_SetBit
	resm 5, (xiz)
	jr TextRender_BitMask5_Return

TextRender_BitMask5_SetBit:
	setm 5, (xiz)

TextRender_BitMask5_Return:
	inc 1, hl
	inc 1, xiz
	cp hl, (xsp + 24)
	jr c, TextRender_BitMask5_PixelLoop

TextRender_BitMask5_AdvancePointer:
	lds32 xwa, 1
	add (xsp + 16), xwa
	incm 1, (xsp + 28)

TextRender_BitMask5_CheckColumnEnd:
	ld xwa, (xsp + 4)
	ld wa, (xwa + 2)
	cp (xsp + 28), wa
	jrl c, TextRender_BitMask5_DrawPixel
	jrl TextRender_AdvanceToNextLine

TextRender_XorMode_Init:
	ldw (xsp + 28), 0x0
	jrl TextRender_CheckColumnEnd

TextRender_XorMode_DrawPixel:
	ld xwa, (xsp + 16)
	cp (xwa), 0x0
	jrl z, TextRender_AdvancePointerAndUpdateLine
	st_dri3b D, 0xfd, 0x26, 0x01
	st_dri3b B, 0xfd, 0x2a, 0x01
	ld hl, (xde + 2)
	add hl, (xsp + 28)
	ld bc, hl
	ld (xix + 2), hl
	ld_sril XWA, (xsp + 0x013a)
	cp hl, (xwa + 2)
	jr lt, TextRender_AdvancePointerAndUpdateLine
	cp bc, (xwa + 6)
	jr gt, TextRender_AdvanceToNextLine
	ld wa, bc
	exts xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	sll xbc, 6
	ld wa, (xde)
	exts xwa
	.include "display/graphics_text_vga.s"
	call Sprintf_Locked
	lda xsp, (xsp + 12)

ChordProc_SendRefreshEvent:
	lda xde, (xsp + 4)
	ld_sril XWA, (xsp + 0x0104)
	ld xbc, 0x1c0000f
	call SendEvent

UI_EventHandler_InitReturnZero:
	lds32 xhl, 0

UI_EventHandler_PopAndReturn:
	pop xiz
	st_dri3b L, 0xfd, 0x04, 0x01
	ret

ChordProc_TrailingData:
	.byte 0x43, 0x03, 0x00, 0x02, 0x01, 0x0e
AcChordBoxProc_Entry:

AcChordBoxProc:
	st_dri3b L, 0xfd, 0xfc, 0xfe
	push xiz
	ld xiz, xde
	st_dri3l XWA, 0xfd, 0x04, 0x01
	cp xbc, 0x1c20001
	jr z, AcChordBox_HandleChordUpdate
	cp xbc, 0x1c00001
	jr z, AcChordBox_HandleInitOrSelect
	cp xbc, 0x1c20000
	jr z, AcChordBox_HandleInitOrSelect
	ld_sril XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	jr AcChordBox_PopAndReturn

AcChordBox_HandleInitOrSelect:
	ld_sril XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	ld xwa, 0x1420007
	ld xbc, 0x1e2000d
	lds32 xde, 0
	call MainFuncCall
	jr AcChordBox_ReturnZero

AcChordBox_HandleChordUpdate:
	ld_sril XWA, (xsp + 0x0104)
	ld xde, xiz
	call InheritedProc
	push xiz
	pushw 0xed
	pushw 0x1c92
	lda xwa, (xsp + 12)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp + 12)
	ld xwa, 0xc0
	call SndParam_LookupReadOnly
	cps hl, 0
	jr nz, AcChordBox_ReturnZero
	lda xde, (xsp + 4)
	ld_sril XWA, (xsp + 0x0104)
	ld xbc, 0x1c0000f
	call SendEvent

AcChordBox_ReturnZero:
	lds32 xhl, 0

AcChordBox_PopAndReturn:
	pop xiz
	st_dri3b L, 0xfd, 0x04, 0x01
	ret

MainChordPre:
	push xiz
	cp xbc, 0x1e2000d
	jrl nz, MainChordPre_ReturnZero
	pushw 0x15
	call Malloc
	ld xiz, xhl
	ld (xiz), 0x0
	ldda8 a, 36160
	extz wa
	sla wa, 2
	lda_24 xbc, 0xecfee0
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	push xiz
	call Strcat
	ldda8 a, 36162
	extz wa
	sla wa, 2
	lda_24 xbc, 0xecff6a
	ld_sril3 XWA, 0x07, 0xe4, 0xe0
	push xwa
	push xiz
	call Strcat
	lda xsp, (xsp + 18)
	cpdi8 36164, 0
	jr z, MainChordPre_EmptyChordStr
	bitda 1, 52958
	jr z, MainChordPre_EmptyChordStr
	ld xwa, 0xed1c96
	jr MainChordPre_AppendChordSuffix

MainChordPre_EmptyChordStr:
	ld xwa, 0xed1c9a

MainChordPre_AppendChordSuffix:
	push xwa
	push xiz
	call Strcat
	ldda8 a, 36162
	extz wa
	sla wa, 2
	lda_24 xbc, 0x03f2f8
	ld_sril3 XBC, 0x07, 0xe4, 0xe0
	ldda8 a, 36160
	extz wa
	sla wa, 2
	ld_sril3 XBC, 0x07, 0xe4, 0xe0
	ldda8 a, 36164
	extz wa
	sla wa, 2
	ld_sril3 XBC, 0x07, 0xe4, 0xe0
	push xbc
	push xiz
	call Strcat
	lda xsp, (xsp + 16)
	ld xwa, 0xffffffff
	ld xbc, 0x1c20001
	ld xde, xiz
	call ApPostEvent
	ld xwa, 0xffffffff
	ld xbc, 0x1e00023
	ld xde, xiz
	call ApPostEvent

MainChordPre_ReturnZero:
	lds32 xhl, 0
	pop xiz
	ret

MainChordPre_ReturnDefaultResult:
	ld xhl, 0x1020005
	ret


; =============================================================================
; Extension Device Initialization (TOSHI) & Control Panel (ROM FC3114-FFFFFF)
; =============================================================================
	.include "extensions/extension_init.s"

InitializeKSS:
	ret

InitializeUser12:
	ret

InitializeUser13:
	ret

InitializeUser14:
	ret

InitializeUser15:
	ret

InitializeUser16:
	ret

InitializeUser17:
	ret

InitializeUser18:
	ret

InitializeUser19:
	ret

InitializeUser20:
	ret

InitializeUser21:
	ret

InitializeUser22:
	ret

InitializeUser23:
	ret

InitializeUser24:
	ret

InitializeUser25:
	ret

InitializeUser26:
	ret

InitializeUser27:
	ret

InitializeUser28:
	ret

InitializeUser29:
	ret

InitializeUser30:
	ret

InitializeUser31:
	ret

EmptyRoutine_01:
	ret

CPanel_InitDispatchTable:
	.long CPanel_InitSequence
	.long EmptyRoutine_03
	.long EmptyRoutine_03
	.long EmptyRoutine_02

CPanel_InitSequence:
	ei 0
	calr DELAY_51_TICKS
	calr DELAY_51_TICKS
	calr DELAY_51_TICKS
	calr CPanel_InitHardware
	calr DELAY_6_TICKS
	calr DELAY_6_TICKS
	calr DELAY_6_TICKS
	calr DELAY_6_TICKS
	calr CPanel_PollStartup
	ret


EmptyRoutine_02:
	ret


CPanel_RX_ProcessOrInit:
	ldda8 a, 36236
	and a, 0xc0
	jr z, CPanel_RX_SkipToProcess
				; if CP_Flags_A.76 != 0:
	ld xhl, 0x200ad
	ldw (xhl - 4), 0x0
	ldw (xhl - 8), 0x0
	ldw (xhl - 2), 0x80
	ei 6
	stdi16 36253, 0
	stdi16 36255, 0
	ordi8 36242, 1	; CP_Flags_B.0 = 1
	ei 0
	jr CPanel_RX_Return
				; else:
CPanel_RX_SkipToProcess:
	calr CPanel_RX_Process

CPanel_RX_Return:
	ret

CPanel_Poll:
	calr CPanel_InterruptPoll_MainLoop
	ret

CPanel_InitButtonState_SaveRegs:
	push xix
	push xiz
	push xhl
	push xde
	calr CPanel_InitButtonState
	pop xde
	pop xhl
	pop xiz
	pop xix
	ret


CPanel_PanelDetection_Wrapper:
	calr CPanel_PanelDetection
	ret


CPanel_KeyProcessing_Wrapper:
	calr ToneGen_Config_AlignByte
	ret


EmptyRoutine_03:
	ret


	.include "ui/cpanel_routines.s"


	.include "audio/tonegen_fileio_handlers.s"
	.include "audio/audio_control_engine.s"
	.include "boot/interrupt_vector_trampolines.s"

; =============================================================================
; SoundParam_NotifyChange -- Notify UI of sound parameter change
; =============================================================================
; Hashes parameter ID and triggers UI refresh for affected widgets.
; Called after preset loads: 0x4002 for reverb, 0x4006 for EQ.
; Args: xwa = parameter ID
SoundParam_NotifyChange:
	lda xsp, (xsp - 10)
	push xiz
	ld (xsp + 10), de
	ld (xsp + 12), bc
	ldw (xsp + 4), 0x0
	ld xiz, xwa
	lds32 xwa, 0
	ld (xsp + 6), xwa
	ld xhl, xiz
	and xhl, 0xff
	ld xwa, xhl
	sll xwa, 9
	add xwa, xhl
	ld xhl, xiz
	srl xhl, 8
	and xhl, 0xff
	add xhl, xwa
	ld xwa, xhl
	sll xwa, 9
	add xwa, xhl
	ld xhl, xiz
	srl xhl, 0
	and xhl, 0x1f
	add xhl, xwa
	ld xwa, xhl
	ld xbc, 0x7ff
	call DivMod32
	ld ix, hl
	jr SndParam_ProbeEntry


; --- Sound Parameters, MIDI Serial, DSP & Voice Mapping ---
	.include "audio/sndparam_routines.s"

; MIDI Serial Communication routines (SC0)
	.include "midi/midi_serial_routines.s"
	.include "midi/midi_dispatch_handlers.s"
	.include "audio/dsp_config_sysex.s"
	.include "audio/note_voice_mapping.s"

Debug_PrintHexByte:
	push	xiz
	calr	61
	pop	xiz
	ret
	push	xiz
	ld	w, a
	srl	a, 4
	calr	37
	pushw	wa
	calr	46
	popw	wa
	ld	a, w
	and	a, 15
	calr	24
	calr	34
	pop	xiz
	ret

Debug_PrintString:
	push xiz
	ld xix, xwa

Debug_PrintString_Loop:
	ld_spib A, 0xf0
	cps a, 0
	jr z, Debug_PrintString_Done
	push xix
	calr Debug_UartDelay
	pop xix
	jr Debug_PrintString_Loop

Debug_PrintString_Done:
	pop xiz
	ret

Debug_UartHelpers:
	.byte 0xc9, 0xcf, 0x0a, 0x6f, 0x04, 0xc9, 0xc8, 0x30, 0x0e, 0xc9, 0xc8, 0x57, 0x0e

Debug_UartDelay:
	ldw iz, 0xfe00
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	ret

Debug_SWI_JumpTable:
	swi	7
	swi	7
	jp	Boot_InitWorkRAM_Trailer
	jp	HDAE5000_Init_DetectAndVerify
	jp	Boot_InitIOPorts
	jp	BOOT_ENTRY_POINT
	ret

Get_Firmware_Version:
	ld8_24 l, 0xffffe8
	ret

ROM_PaddingFF:
	.byte 0xff, 0xff, 0xff, 0x00, 0xff

	.include "boot/rom_end_structure.s"

; Labels emitted as .set (exact addresses from ORG/name)
	.set SeqRingBuf_WriteDispatch_Table_0x11, 0xe00023
	.set SeqRingBuf_WriteDispatch_Table_0x16, 0xe00028
	.set LongStr_ics_KN5000_Program, 0xe00065
	.set Str_gramDATAFILE22, 0xe00073
	.set Str_AFILE22, 0xe0007c
	.set NakaStr_DataFile1of2, 0xe000c3
	.set Str_ableDATAFILEPCK, 0xe00111
	.set NakaStr_DataFilePck, 0xe00113
	.set NakaData_FileScreenConfig, 0xe0019e
	.set NakaData_FileScreenDispatch, 0xe00302
	.set Bitmap_1bit_FlashStatus_Icon, 0xe00800
	.set ScoopDisp_BitmapDataBlock, 0xe00b04
	.set ScoopDisp_EmptyBitmapData, 0xe00b28
	.set NakaUI_ObjectTable_End, 0xe14c32
	.set LongStr_Explore_1000_Musical, 0xe14c86
	.set StrFld_ParaList_Font_0x06, 0xe16bac
	.set Str_S2cGridBox, 0xe1708a
	.set AlignedStr_CmpNameMenuBox, 0xe17096
	.set NakaInst_AcApcToggle, 0xe17112
	.set NakaInst_AcApcToggle_0x0C, 0xe1711e
	.set Str_TEMPO, 0xe18d4c
	.set Str_FROM, 0xe1a224
	.set NumStr_11, 0xe1cde2
	.set NumStr_10, 0xe1cde6
	.set NumStr_9, 0xe1cdea
	.set NumStr_8, 0xe1cdee
	.set NumStr_7, 0xe1cdf2
	.set NumStr_6, 0xe1cdf6
	.set NumStr_5, 0xe1cdfa
	.set NumStr_4, 0xe1cdfe
	.set NumStr_3, 0xe1ce02
	.set NumStr_2, 0xe1ce06
	.set NumStr_1, 0xe1ce0a
	.set NumStr_0, 0xe1ce0e
	.set StrNotePos_FlatAlt, 0xe1dd4c
	.set StrNotePos_FlatAltB8, 0xe1dd52
	.set StrNotePos_AcNatural, 0xe1dd5a
	.set WidgetDispatch_FDTestPtrTable, 0xe1ffb6
	.set NakaDirectPlay_PropPtrTable, 0xe208a4
	.set NakaStr_LyricsBox, 0xe20b7c
	.set AlignedStr_AcMuteToggleBox, 0xe20b86
	.set Str_ORCH, 0xe21ad2
	.set NakaStr_PdMdlyOrcha, 0xe22322
	.set Str_AFTER_TOUCH_SETTING, 0xe2364a
	.set NakaStr_Gamelan, 0xe23c12
	.set NakaWidget_Perf2Flute, 0xe23c1a
	.set Str_SaxBrass, 0xe23cca
	.set NakaWidget_Perf2Piano, 0xe23cd4
	.set NakaStr_Organ, 0xe23d0a
	.set Str_HokieDance, 0xe23e62
	.set NakaWidget_Perf3JazzBand, 0xe23e6e
	.set Str_GospelRevival, 0xe23ea4
	.set NakaWidget_Perf3LatinOrch, 0xe23eb4
	.set Str_OrganCombo, 0xe23eea
	.set NakaWidget_Perf3BigBand, 0xe23ef6
	.set Str_BigBandMid, 0xe23f2c
	.set NakaWidget_Perf3SymphOrch, 0xe23f3a
	.set NakaStr_Rhythm, 0xe2405e
	.set NakaFld_TabIndexFunc, 0xe270ea
	.set NakaDesc_SeqExitWidgets, 0xe2713c
	.set NakaInst_SqedtVal, 0xe27564
	.set NakaInst_SqedtVal_B, 0xe27574
	.set NakaInst_EqualizerBox, 0xe27586
	.set Data_NakaPresetConfig, 0xe278a9
	.set NakaInst_FadeInOutSetting_Params, 0xe2df22
	.set Str_ENGLISH, 0xe2df54
	.set Str_ENGLISH_0x10, 0xe2df64
	.set Str_ENGLISH_0x52, 0xe2dfa6
	.set NakaData_EffectsBlock_Byte1, 0xe30001
	.set NakaData_EffectsBlock_Byte2, 0xe30002
	.set NakaData_EffectsBlock_Byte3, 0xe30003
	.set NakaData_EffectsBlock_Byte5, 0xe30005
	.set NakaData_EffectsStringPtrs, 0xe30006
	.set Str_20469e32473220, 0xe30b2a
	.set Str_42a03242322043, 0xe30b51
	.set TableData_NullDialogText, 0xe33824
	.set Str_ATTENTION, 0xe3382c
	.set Str_Apakahyakinakandihapus, 0xe338a6
	.set WarnStr_Featuresforcreatingas, 0xe338c2
	.set LongStr_Funktionen_zur_Erstellung, 0xe338e2
	.set LongStr_SongClear_Spanish, 0xe33ee4
	.set LongStr_Gunakan_SONG_CLEAR, 0xe33f22
	.set LongStr_TrackClear_Spanish, 0xe3405e
	.set LongStr_Gunakan_TRACK_CLEAR, 0xe340a6
	.set WarnStr_PresstheSTARTSTOPbutt, 0xe34104
	.set WarnStr_PresstheSTARTSTOPbutt_0x26, 0xe3412a
	.set FmtStr_pct3d, 0xe34614
	.set LongStr_1_2_3, 0xe34944
	.set FmtStr_pct3d_4B5E, 0xe34b5e
	.set FmtStr_pluspct3d, 0xe34bb6
	.set FmtStr_minuspct3d, 0xe34bbe
	.set Pad_AfterBitmap_Dredt0k, 0xe3def1
	.set Pad_AfterBitmap_Dredt0k_2, 0xe3e0f1
	.set Pad_BeforeBitmap_Dredt0d, 0xe3e2f2
	.set NakaData_ExternalBase, 0xe40000
	.set Pad_AfterNakaData_ExternalBase, 0xe40002
	.set Pad_NakaExternal_Block1, 0xe40005
	.set Pad_NakaExternal_Block2, 0xe40031
	.set Pad_NakaExternal_Block3, 0xe40046
	.set Pad_BeforeNakaData_ExternalBase_0x66, 0xe40059
	.set NakaData_ExternalBase_0x66, 0xe40066
	.set Pad_AfterNakaData_ExternalBase_0x66, 0xe4006e
	.set Pad_NakaExternal_Block4, 0xe40081
	.set NakaData_ExternalPadBlock_A, 0xe40096
	.set NakaData_ExternalPadBlock_B, 0xe400a9
	.set Pad_BeforeNakaData_UserMemoryConfig, 0xe400be
	.set NakaData_UserMemoryConfig, 0xe400d0
	.set Pad_AfterNakaData_UserMemoryConfig, 0xe40101
	.set Pad_BeforeNakaData_StyleBitmapPad, 0xe40116
	.set NakaData_ExternalBitmapBlock, 0xe40a09
	.set NakaData_StyleBitmapPad, 0xe41807
	.set RhythmTiming_OffsetTable, 0xe46312
	.set TechnichordParam_Block1, 0xe5002d
	.set TechnichordParam_Block2, 0xe5006e
	.set TechnichordParam_Block3, 0xe500be
	.set TechnichordParam_Block4, 0xe500ce
	.set TechnichordParam_Block5, 0xe500fe
	.set NakaData_TechnichordParams, 0xe50117
	.set NakaHandler_CtrlMessages, 0xe56acc
	.set NakaHandler_RealtimeMessages, 0xe56b14
	.set NakaHandler_CommonSetting, 0xe56b5c
	.set NakaHandler_ProgChangeMidiOut, 0xe56cbc
	.set NakaInst_InOutSettingGrid, 0xe57504
	.set NakaInst_MidiPresetConfig, 0xe578aa
	.set NakaInst_KN5000_MidiPresets, 0xe57982
	.set NakaInst_UserSettingSelector, 0xe57c8e
	.set NakaHandler_SplitPointDialog, 0xe57e6e
	.set NakaInst_SndModVocalistExtSeq, 0xe57f36
	.set NakaInst_KN5000_SysexBulkDump, 0xe57fa2
	.set NakaInst_WithAPC_Presets, 0xe5804e
	.set NakaInst_WithoutAPC_Presets, 0xe580a6
	.set NakaInst_Value_SysexPresets, 0xe580d2
	.set NakaInst_WithAPC_GM, 0xe5821e
	.set NakaInst_WithoutAPC_GM, 0xe58276
	.set NakaInst_Value_GM, 0xe582a2
	.set NakaInst_KN5000_GM, 0xe582e2
	.set NakaInst_BulkDumpCategorySelect, 0xe583a6
	.set NakaInst_Receiving_Sysex, 0xe58742
	.set NakaInst_ProgChangeLabel, 0xe58fda
	.set NakaInst_P_MEM_ON_OFF_PART, 0xe5904a
	.set NakaInst_PresetSettingsLabel, 0xe59532
	.set NakaInst_ItemLabel_RevEqPreset, 0xe5985a
	.set NakaData_DescriptorSection_Start, 0xe60000
	.set NakaData_DescriptorPad1, 0xe60008
	.set NakaData_DescriptorPad_ZeroA, 0xe6009a
	.set NakaData_DescriptorPad_ZeroB, 0xe600aa
	.set NakaData_DescriptorPad_ZeroC, 0xe600da
	.set NakaData_DescriptorZero, 0xe600df
	.set NakaData_DescriptorZero_PadA, 0xe600e4
	.set NakaData_DescriptorZero_PadB, 0xe600ec
	.set Pad_AfterBitmap_MIDIConnections_1, 0xe678ff
	.set NakaData_Tables2Pad1, 0xe70015
	.set NakaData_Tables2Pad2, 0xe7001e
	.set Pad_AfterNakaData_Tables2Pad2, 0xe70022
	.set NakaData_Tables2Pad3, 0xe700de
	.set Bitmap_MIDIConnections_Header, 0xe70b28
	.set DisplayMode_FormatStr1, 0xe7f91c
	.set DisplayMode_FormatStr2, 0xe7f922
	.set Data_AcGridParamTable, 0xe7f9ac
	.set Str_AL, 0xe8005f
	.set NakaInst_GM_0x5A, 0xe800ca
	.set NakaInst_GM_0x5E, 0xe800ce
	.set NakaInst_GM_0x6E, 0xe800de
	.set NakaInst_LEFT_0x04, 0xe800fa
	.set AlignedStr_ON, 0xe8013c
	.set NakaInst_ON_E80168_0x6C, 0xe801d4
	.set Transpose_String_Minus3, 0xe8068c
	.set Transpose_String_Error, 0xe80692
	.set Transpose_String_Plus1, 0xe806a4
	.set Transpose_String_Zero, 0xe806aa
	.set Str_ol, 0xe80b12
	.set Bitmap_AccompBitmapSpacer, 0xe878f9
	.set DrawbarSlider_ConfigData, 0xe8cfeb
	.set Bitmap_TechnichordBackground_1, 0xe90077
	.set NakaData_TechnichordBitmap1, 0xe900d8
	.set NakaData_TechnichordBitmap1_0x09, 0xe900e1
	.set NakaData_TechnichordBitmap1_0x14, 0xe900ec
	.set NakaInst_SequencerComboBox, 0xe90130
	.set NakaInst_SequencerComboBox_0x03, 0xe90133
	.set NakaData_TechnichordBitmap2, 0xe9013d
	.set Bitmap_TechnichordBackground_2, 0xe90b3b
	.set StrPtrTable_DiskErr03, 0xe96344
	.set Str_DiskErr12_French_0x5A, 0xe97114
	.set StrPtrTable_DiskErr16, 0xe971de
	.set StrPtrTable_DiskErr20_End, 0xe97bde
	.set StrPtrTable_DiskErr24_Start, 0xe97dc2
	.set Str_Err24APC_French_0x62, 0xe98676
	.set StrPtrTable_DiskErr24_French_End, 0xe9871a
	.set StrPtrTable_DiskErr28_Start, 0xe98aee
	.set StrPtrTable_DiskErr30_End, 0xe99a0e
	.set StrPtrTable_DiskErr41_Start, 0xe99cd4
	.set Str_BeimEmpfangderSys, 0xe99edc
	.set StrPtrTable_DiskErr43_Start, 0xe9a2c4
	.set StrPtrTable_Error55_End, 0xe9b92a
	.set StrPtrTable_Error55_Block2, 0xe9bf3a
	.set StrPtrTable_SpecialTracks_Start, 0xe9c524
	.set LongStr_RKB_und_LKB, 0xe9c6fc
	.set StrPtrTable_InitSettingWarning_Start, 0xe9cf14
	.set Str_DISKNAME, 0xea1d7a
	.set Str_LOAD, 0xea2442
	.set Str_COMP, 0xea263a
	.set Str_CUSTOM, 0xea26aa
	.set Str_MIDI, 0xea26d2
	.set Str_RHYTHM_CUSTOM, 0xea27a2
	.set Str_COMPOSER, 0xea2822
	.set Str_LOAD_2952, 0xea2952
	.set Str_SINGLE_LOAD, 0xea29a2
	.set NakaStr_Single, 0xea2d36
	.set NakaStr_Bank, 0xea2d3e
	.set Str_PREV, 0xea2e26
	.set Str_DISK, 0xea2f0e
	.set Str_LOAD_AS, 0xea2f3a
	.set Str_SOUND_MEMORY, 0xea3b5a
	.set Str_SEQUENCER, 0xea3bb2
	.set Str_PERFORM, 0xea3d2a
	.set Str_BACKUP, 0xea3d7a
	.set Str_PNL, 0xea3dca
	.set Str_COMP_3F6A, 0xea3f6a
	.set Str_CUSTOM_3FDA, 0xea3fda
	.set Str_MIDI_4002, 0xea4002
	.set Str_ALL_OFF, 0xea4082
	.set Str_SAVE, 0xea41d2
	.set Str_NEXT, 0xea435a
	.set Str_OFF, 0xea43bc
	.set Str_SAVE_44A2, 0xea44a2
	.set Str_PREV_471A, 0xea471a
	.set Str_DISKINSERTOPTION, 0xea66b6
	.set Str_FILETYPEPRIORITY, 0xea6706
	.set DiskWarning_GermanConfirm, 0xea8cbc
	.set Pad_AfterStr_No, 0xeaaef4
	.set FmtStr_pct2d, 0xeab18c
	.set WidgetPropStr_Max, 0xeac1ba
	.set WidgetPropStr_RangeFigures, 0xeac1be
	.set NakaData_CharaFontTable, 0xeada96
	.set NakaStr_Chara1pFnt, 0xeadb1a
	.set NakaStr_Chara5Fnt, 0xeadb26
	.set NakaStr_Chara4Fnt, 0xeadb32
	.set NakaStr_Chara3Fnt, 0xeadb3e
	.set NakaStr_Chara2Fnt, 0xeadb4a
	.set NakaStr_Chara1Fnt, 0xeadb56
	.set IconBitmapName_i96o, 0xeb2796
	.set BmpFile_i69_bmp, 0xeb287e
	.set BmpFile_i68_bmp, 0xeb2886
	.set BmpFile_i67_bmp, 0xeb288e
	.set BmpFile_i66_bmp, 0xeb2896
	.set BmpFile_i65_bmp, 0xeb289e
	.set BmpFile_i64_bmp, 0xeb28a6
	.set BmpFile_i63_bmp, 0xeb28ae
	.set BmpFile_i62_bmp, 0xeb28b6
	.set BmpFile_i61_bmp, 0xeb28be
	.set BmpFile_i60_bmp, 0xeb28c6
	.set BmpFile_i59_bmp, 0xeb28ce
	.set BmpFile_i58_bmp, 0xeb28d6
	.set BmpFile_i57_bmp, 0xeb28de
	.set BmpFile_i56_bmp, 0xeb28e6
	.set BmpFile_i55_bmp, 0xeb28ee
	.set BmpFile_i54_bmp, 0xeb28f6
	.set BmpFile_i53_bmp, 0xeb28fe
	.set BmpFile_i52_bmp, 0xeb2906
	.set BmpFile_i51_bmp, 0xeb290e
	.set BmpFile_i50_bmp, 0xeb2916
	.set BmpFile_i49_bmp, 0xeb291e
	.set BmpFile_i48_bmp, 0xeb2926
	.set BmpFile_i47_bmp, 0xeb292e
	.set BmpFile_i46_bmp, 0xeb2936
	.set BmpFile_i45_bmp, 0xeb293e
	.set BmpFile_i44_bmp, 0xeb2946
	.set BmpFile_i43_bmp, 0xeb294e
	.set BmpFile_i42_bmp, 0xeb2956
	.set BmpFile_i41_bmp, 0xeb295e
	.set BmpFile_i40_bmp, 0xeb2966
	.set BmpFile_i39_bmp, 0xeb296e
	.set BmpFile_i38_bmp, 0xeb2976
	.set BmpFile_i37_bmp, 0xeb297e
	.set BmpFile_i36_bmp, 0xeb2986
	.set BmpFile_i35_bmp, 0xeb298e
	.set BmpFile_i34_bmp, 0xeb2996
	.set BmpFile_i33_bmp, 0xeb299e
	.set BmpFile_i32_bmp, 0xeb29a6
	.set BmpFile_i31_bmp, 0xeb29ae
	.set BmpFile_i30_bmp, 0xeb29b6
	.set BmpFile_i29_bmp, 0xeb29be
	.set BmpFile_i28_bmp, 0xeb29c6
	.set BmpFile_i27_bmp, 0xeb29ce
	.set BmpFile_i26_bmp, 0xeb29d6
	.set BmpFile_i25_bmp, 0xeb29de
	.set BmpFile_i24_bmp, 0xeb29e6
	.set BmpFile_i23_bmp, 0xeb29ee
	.set BmpFile_i22_bmp, 0xeb29f6
	.set BmpFile_i21_bmp, 0xeb29fe
	.set BmpFile_i20_bmp, 0xeb2a06
	.set BmpFile_i19_bmp, 0xeb2a0e
	.set BmpFile_i18_bmp, 0xeb2a16
	.set BmpFile_i17_bmp, 0xeb2a1e
	.set BmpFile_i16_bmp, 0xeb2a26
	.set BmpFile_i15_bmp, 0xeb2a2e
	.set BmpFile_i14_bmp, 0xeb2a36
	.set BmpFile_i13_bmp, 0xeb2a3e
	.set BmpFile_i12_bmp, 0xeb2a46
	.set BmpFile_i11_bmp, 0xeb2a4e
	.set BmpFile_i10_bmp, 0xeb2a56
	.set BmpFile_i9_bmp, 0xeb2a5e
	.set BmpFile_i8_bmp, 0xeb2a66
	.set BmpFile_i7_bmp, 0xeb2a6e
	.set StyleBmp_i6obmp, 0xeb2a76
	.set BmpFile_i5_bmp, 0xeb2a7e
	.set StyleBmp_i4obmp, 0xeb2a86
	.set StyleBmp_i3obmp, 0xeb2a8e
	.set BmpFile_i2_bmp, 0xeb2a96
	.set BmpFile_i1_bmp, 0xeb2a9e
	.set BmpFile_i0_bmp, 0xeb2aa6
	.set StyleBmp_trashbmp, 0xeb2aae
	.set Palette_8bit_RGBA, 0xeb37de
	.set StyleBmp_ZachariasSwing, 0xebbc26
	.set StyleBmp_YeeHaFiddles, 0xebbcae
	.set StyleBmp_WunderPops, 0xebbd36
	.set StyleBmp_WildSideOrgan, 0xebbdbe
	.set StyleBmp_WheelsofLife, 0xebbe46
	.set StyleBmp_WeddingParty, 0xebbece
	.set StyleBmp_WandrinKeys, 0xebbf56
	.set StyleBmp_WaltzingConcert, 0xebbfde
	.set StyleBmp_WailersGuitar, 0xebc066
	.set StyleBmp_VocalBeats, 0xebc0ee
	.set StyleBmp_ViennaWoods, 0xebc176
	.set StyleBmp_VegasShowman, 0xebc1fe
	.set StyleBmp_UptownHorns, 0xebc286
	.set StyleBmp_TwoStepDuo, 0xebc30e
	.set StyleBmp_TwilightPiano, 0xebc396
	.set StyleBmp_TravoltaDance, 0xebc41e
	.set StyleBmp_TopBrassJive, 0xebc4a6
	.set StyleBmp_TirolerHarp, 0xebc52e
	.set StyleBmp_TheatreBand, 0xebc5b6
	.set StyleBmp_ThePartyBand, 0xebc63e
	.set StyleBmp_TheDukesPiano, 0xebc6c6
	.set StyleBmp_TennesseeGuitar, 0xebc74e
	.set StyleBmp_TechnoFiddle, 0xebc7d6
	.set StyleBmp_TangoMarcato, 0xebc85e
	.set StyleBmp_TakeItEasy, 0xebc8e6
	.set StyleBmp_SynthParty, 0xebc96e
	.set StyleBmp_SynthForSoul, 0xebc9f6
	.set StyleBmp_SymphonyBallad, 0xebca7e
	.set StyleBmp_SwingingKeys, 0xebcb06
	.set StyleBmp_SwingSerenade, 0xebcb8e
	.set StyleBmp_SwingB3Threes, 0xebcc16
	.set StyleBmp_SweetSoprano, 0xebcc9e
	.set StyleBmp_SweepingBridge, 0xebcd26
	.set StyleBmp_SunnySpainMood, 0xebcdae
	.set StyleBmp_StreetTalk, 0xebce36
	.set StyleBmp_StephaneDjango, 0xebcebe
	.set StyleBmp_SteelStrings, 0xebcf46
	.set StyleBmp_SpyraSteel, 0xebcfce
	.set StyleBmp_SpanishMoments, 0xebd056
	.set StyleBmp_SouthernStyle, 0xebd0de
	.set StyleBmp_SoulfulWhaWha, 0xebd166
	.set StyleBmp_SoulVocalDuo, 0xebd1ee
	.set StyleBmp_SoulHorn, 0xebd276
	.set StyleBmp_SopranoGroove, 0xebd2fe
	.set StyleBmp_SolidSixteen, 0xebd386
	.set StyleBmp_SolidDistortion, 0xebd40e
	.set StyleBmp_SoftRock, 0xebd496
	.set StyleBmp_SmoothLips, 0xebd51e
	.set StyleBmp_SlowSpinGroove, 0xebd5a6
	.set StyleBmp_SlapBackRock, 0xebd62e
	.set StyleBmp_SkeletonDance, 0xebd6b6
	.set StyleBmp_SingItPlayIt, 0xebd73e
	.set StyleBmp_SinatraStrings, 0xebd7c6
	.set StyleBmp_SimpleBand, 0xebd84e
	.set StyleBmp_ShuffleOrgan, 0xebd8d6
	.set StyleBmp_ShearingCombo, 0xebd95e
	.set StyleBmp_SevilleOctaves, 0xebd9e6
	.set StyleBmp_SentimentalSolo, 0xebda6e
	.set StyleBmp_SaxyMambo, 0xebdaf6
	.set StyleBmp_SaxDrumsRRoll, 0xebdb7e
	.set StyleBmp_SaxMamboist, 0xebdc06
	.set StyleBmp_SantasHelpers, 0xebdc8e
	.set StyleBmp_SambaUnion, 0xebdd16
	.set StyleBmp_SambaParty, 0xebdd9e
	.set StyleBmp_RossVocals, 0xebde26
	.set StyleBmp_RollingWheels, 0xebdeae
	.set StyleBmp_RockSymphony, 0xebdf36
	.set StyleBmp_RockFall, 0xebdfbe
	.set StyleBmp_RioHorns, 0xebe046
	.set StyleBmp_RickysStrat, 0xebe0ce
	.set StyleBmp_RetroGroove, 0xebe156
	.set StyleBmp_ReinhardtsSolo, 0xebe1de
	.set StyleBmp_ReggaeDanceHit, 0xebe266
	.set StyleBmp_ReedItSwing, 0xebe2ee
	.set StyleBmp_RastaJambo, 0xebe376
	.set StyleBmp_RadioOrchestra, 0xebe3fe
	.set StyleBmp_PuentesBigband, 0xebe486
	.set StyleBmp_PowerSaxSwing, 0xebe50e
	.set StyleBmp_PopLeader, 0xebe596
	.set StyleBmp_PopBridge, 0xebe61e
	.set StyleBmp_PolyDance, 0xebe6a6
	.set StyleBmp_PlateDance, 0xebe72e
	.set StyleBmp_PennyFolkSong, 0xebe7b6
	.set StyleBmp_PartyPopStack, 0xebe83e
	.set StyleBmp_PartyAccordion, 0xebe8c6
	.set StyleBmp_ParadiseKeys, 0xebe94e
	.set StyleBmp_OverTheTopWah, 0xebe9d6
	.set StyleBmp_OrganistsSwing, 0xebea5e
	.set StyleBmp_OrchestralEight, 0xebeae6
	.set StyleBmp_OneTwoThree, 0xebeb6e
	.set StyleBmp_OleGuitar, 0xebebf6
	.set StyleBmp_OldTimeSaloon, 0xebec7e
	.set StyleBmp_OldNewFunk, 0xebed06
	.set StyleBmp_OklahomaDance, 0xebed8e
	.set StyleBmp_OceanVocals, 0xebee16
	.set StyleBmp_NotRavels, 0xebee9e
	.set StyleBmp_NiceKeroncong, 0xebef26
	.set StyleBmp_NewSquareDance, 0xebefae
	.set StyleBmp_NewJazzBallad, 0xebf036
	.set StyleBmp_NashvilleDance, 0xebf0be
	.set StyleBmp_MuteSoloist, 0xebf146
	.set StyleBmp_MusetteBallad, 0xebf1ce
	.set StyleBmp_MovieBallad, 0xebf256
	.set StyleBmp_MoschsMilitary, 0xebf2de
	.set StyleBmp_MoiksMarchshow, 0xebf366
	.set StyleBmp_ModernBoogie, 0xebf3ee
	.set StyleBmp_MirandaMallets, 0xebf476
	.set StyleBmp_MidnightTunes, 0xebf4fe
	.set StyleBmp_MerengueParty, 0xebf586
	.set StyleBmp_MellowSection, 0xebf60e
	.set StyleBmp_MellowJazzTabs, 0xebf696
	.set StyleBmp_MellowShuffle, 0xebf71e
	.set StyleBmp_MaxsOrchestra, 0xebf7a6
	.set StyleBmp_MarchingPolka, 0xebf82e
	.set StyleBmp_MamboJambo, 0xebf8b6
	.set StyleBmp_MadTabs, 0xebf93e
	.set StyleBmp_LondonsBigbone, 0xebf9c6
	.set StyleBmp_LionelsJazz, 0xebfa4e
	.set StyleBmp_LikeSunday, 0xebfad6
	.set StyleBmp_LetItShine, 0xebfb5e
	.set StyleBmp_LatinoPiccolo, 0xebfbe6
	.set StyleBmp_LatinPassion, 0xebfc6e
	.set StyleBmp_LatinBallroom, 0xebfcf6
	.set StyleBmp_LastStarparade, 0xebfd7e
	.set StyleBmp_LAWarmth, 0xebfe06
	.set StyleBmp_KnopflerTribute, 0xebfe8e
	.set StyleBmp_KeyGrooves, 0xebff16
	.set StyleBmp_JustTheFlute, 0xebff9e
	.set NakaStr_SoundPreset176, 0xec00c7
	.set SoundName_160, 0xec00ec
	.set SoundName_160_0x27, 0xec0113
	.set SoundName_ToTheBone, 0xec013b
	.set NakaStr_SoundPresetBone, 0xec013f
	.set NakaInst_Hard_Analogue_148_0x65, 0xec0a1b
	.set SoundName_MournfulTenor, 0xec88ec
	.set StyleSound_BluesAlley_Data, 0xec8974
	.set SoundName_HymnBand, 0xec89b4
	.set SoundName_HymnBand_0x66, 0xec8a1a
	.set SoundName_PreachTheWord, 0xec8a7c
	.set SoundName_LushTango, 0xecb09c
	.set SoundName_LushTango_0x66, 0xecb102
	.set SoundName_AstorsTango, 0xecb164
	.set SoundName_SymphonicWaltz, 0xecb26c
	.set StyleSound_QuickWaltz_Data, 0xecb2f4
	.set SoundName_NotStrauss, 0xecb334
	.set SoundName_NotStrauss_0x66, 0xecb39a
	.set SoundName_BavarianFlutes, 0xecb3fc
	.set SoundName_BeachPartySong, 0xecdbec
	.set SoundName_CubanReeds, 0xecdcb4
	.set SoundName_LatinoPiccolo, 0xecdd7c
	.set SoundName_JamaicanBars, 0xecde44
	.set SoundName_SambaUnion, 0xecde84
	.set SoundName_NewOrganSamba, 0xecdf4c
	.set SoundName_NiceKeroncong, 0xece014
	.set SoundName_EasyDangdut, 0xece0dc
	.set SoundName_PadangBeat, 0xece11c
	.set SoundName_RastaVoice, 0xece1e4
	.set SoundName_MarleysDrums, 0xece2ac
	.set EffSeqScreen_ChordTypePtr_A, 0xed0072
	.set EffSeqScreen_ChordTypePtr_B, 0xed009c
	.set NakaInst_WITH_APC, 0xed00d5
	.set NakaStr_CtrlParam9e9, 0xed013b
	.set SeqChanContainer_ChordTypeRef_A, 0xed0212
	.set SeqChanContainer_ChordTypeRef_B, 0xed029c
	.set ParamStr08_varisupart, 0xed210e
	.set ParamStr08_page, 0xed2116
	.set ParamStr08_fontcolor, 0xed211c
	.set ParamStr08_font, 0xed2122
	.set ParamStr08_func, 0xed212c
	.set ParamStr19_fixedcol, 0xed250c
	.set ParamStr22_nowsongsubctgdtno, 0xed275c
	.set ParamStr22_func, 0xed276e
	.set ParamStr22_fixedrow, 0xed2774
	.set ParamStr22_fixedcol, 0xed277e
	.set NakaInst_AcMstSugAlpGridBox, 0xed2b9a
	.set NakaInst_AcFSWAssGridBox, 0xed2be2
	.set NakaDesc_AcTchSensGridBox, 0xed2bf4
	.set NakaInst_AcTchSensGridBox, 0xed2bf6
	.set NakaDesc_IvMstStyleWindowPgCtl, 0xed2c0c
	.set NakaInst_IvMstStyleWindowPgCtl, 0xed2c0e
	.set NakaDesc_IvPmemWindowPageCtl, 0xed2c22
	.set NakaInst_IvPmemWindowPageCtl, 0xed2c24
	.set NakaInst_MsaModeScreen, 0xed2c62
	.set Str_7f, 0xed46d2
	.set Str_RHYTHM, 0xed4722
	.set SoundName_SOUNDRHYTHM, 0xed474a
	.set Str_PANEL_MEMORY, 0xed477a
	.set Str_PANEL_MEMORY_4922, 0xed4922
	.set Str_7f_4A82, 0xed4a82
	.set Str_DISPLAY_TYPE, 0xed4de2
	.set Str_USER_INITIAL, 0xed5122
	.set Str_VALUE, 0xed517a
	.set ExtDevScreen_SndParamBank_Desc, 0xed690a
	.set ExtDevScreen_SndParamPage_Desc, 0xed69a2
	.set ExtDevScreen_VoiceParamBank_Desc, 0xed6a7a
	.set ExtDevScreen_VoiceParamRhythm_Desc, 0xed6b0a
	.set ExtDevScreen_VoiceParamDrums_Desc, 0xed6b52
	.set ExtDevScreen_VoiceSetup_Desc, 0xed6be2
	.set ExtDevScreen_VoiceMainPage_Desc, 0xed6c6e
	.set ExtDevScreen_MidiCtrl_Desc, 0xed6ff2
	.set ExtDevScreen_MidiCtrlPage_Desc, 0xed70a2
	.set ExtDevScreen_MidiCtrlDetail_Desc, 0xed71b2
	.set ExtDevScreen_MidiCtrlAdvanced_Desc, 0xed723a
	.set ExtDevScreen_DspEffect_Desc, 0xed729a
	.set ExtDevScreen_DspEffectPage_Desc, 0xed734a
	.set ExtDevScreen_ReverbSetup_Desc, 0xed745a
	.set ExtDevScreen_ReverbPage_Desc, 0xed74e2
	.set ExtDevScreen_Equalizer_Desc, 0xed7542
	.set ExtDevScreen_EqualizerPage_Desc, 0xed75f2
	.set ExtDevScreen_UserInitWallpaper_Flag, 0xed9f54
	.set ExtDevScreen_UserInitWallpaper_Data, 0xed9f5c
	.set ENCODER_LUT_VOLUME, 0xeda1bc
	.set ENCODER_LUT_BREATH_INDEX, 0xeda2bc
	.set ENCODER_LUT_BREATH_VALUE, 0xeda2d2
	.set ENCODER_LUT_BREATH_MULT, 0xeda3d2
	.set ENCODER_LUT_BREATH_OFFSET, 0xeda3ea
	.set ENCODER_LUT_FOOT, 0xeda402
	.set ENCODER_LUT_EXPRESSION, 0xeda482
	.set ToshiParam_Entry_01, 0xeda704
	.set ToshiParam_Entry_02, 0xeda71c
	.set ToshiParam_Entry_03, 0xeda734
	.set ToshiParam_Entry_04, 0xeda74c
	.set ToshiParam_Entry_05, 0xeda764
	.set ToshiParam_Entry_06, 0xeda77c
	.set ToshiParam_Entry_07, 0xeda794
	.set ToshiParam_Entry_08, 0xeda7ac
	.set ToshiParam_Entry_09, 0xeda7c4
	.set ToshiParam_Entry_10, 0xeda7dc
	.set ToshiParam_Entry_11, 0xeda7f4
	.set ToshiParam_Entry_12, 0xeda80c
	.set ToshiParam_Entry_13, 0xeda824
	.set ToshiParam_Entry_14, 0xeda83c
	.set ToshiParam_Entry_15, 0xeda854
	.set ToshiParam_Entry_16, 0xeda86c
	.set ToshiParam_Entry_17, 0xeda884
	.set ToshiParam_Entry_18, 0xeda89c
	.set ToshiParam_Entry_19, 0xeda8b4
	.set ToshiParam_Entry_20, 0xeda8e4
	.set ToshiParam_Entry_21, 0xeda914
	.set ToshiParam_Entry_22, 0xeda944
	.set ToshiParam_Entry_23, 0xeda974
	.set ToshiParam_Entry_24, 0xeda9a4
	.set ToshiParam_Entry_25, 0xeda9d4
	.set ToshiParam_Entry_26, 0xedaa04
	.set ToshiParam_Entry_27, 0xedaa34
	.set SoundProgram_ParamPtrTable, 0xedb2e4
	.set WidgetParam_TestMode_Entry, 0xedba44
	.set WidgetParam_SineWave_Entry, 0xedbaae
	.set Naka_SubDispatch_B_Table_0x6E, 0xee0206
	.set SeqData_SubDispatch_ParamA, 0xee3023
	.set SeqData_SubDispatch_ParamB, 0xee3025
	.set WidgetParam_Entry_002_0x18, 0xee45d2
	.set WidgetParam_Entry_002_0x30, 0xee45ea
	.set WidgetParam_Entry_006_0x18, 0xee4662
	.set WidgetParam_Entry_006_0x48, 0xee4692
	.set WidgetParam_Entry_008_0x18, 0xee46da
	.set WidgetParam_Entry_009_0x18, 0xee470a
	.set WidgetParam_Entry_011_0x18, 0xee4752
	.set WidgetParam_Entry_011_0x48, 0xee4782
	.set WidgetParam_Entry_011_0x60, 0xee479a
	.set CharMap_PermutationPtrTable_A, 0xeed3de
	.set CharMap_PermutationPtrTable_B, 0xeed52b
	.set Pad_AfterNaka_DrawbarOrgan_Screens, 0xeee812
	.set NakaData_NormalModeMap, 0xef001f
	.set NakaData_NormalModeMap_0x07, 0xef0026
	.set ScoopDisp_DispatchTable_Extended_0x20, 0xef7779
	.set PerfMode_Evt01_Handler, 0xef8b6d
	.set PerfMode_Evt02_Handler, 0xef8dfb
	.set UIState_Evt06_Handler, 0xef9554
	.set UIState_Evt05_Handler, 0xef955d
	.set MemConfig_Handler_2, 0xefacf7
	.set SubCPU_ToneDispatch_0x54, 0xefdb94
	.set StringData_PartModeNames, 0xeff827
	.set SeMenu_DataBlock_01, 0xf1039e
	.set SeMenu_DataBlock_02, 0xf1040d
	.set SeMenu_DataBlock_03, 0xf1041d
	.set SeMenu_DataBlock_04, 0xf10454
	.set SeMenu_DataBlock_05, 0xf10464
	.set SeMenu_DataBlock_06, 0xf1048e
	.set SeMenu_DataBlock_07, 0xf104b8
	.set SeMenu_DataBlock_08, 0xf104c8
	.set SeMenu_DataBlock_09, 0xf104d8
	.set SeMenu_DataBlock_10, 0xf104e8
	.set SeMenu_DataBlock_11, 0xf10512
	.set SeMenu_DataBlock_12, 0xf105c4
	.set SeMenu_DataBlock_13, 0xf10676
	.set SeMenu_DataBlock_14, 0xf10689
	.set FlashRead_BlockData_Field8, 0xf15891
	.set FlashRead_BlockData_Field7, 0xf1589c
	.set DrumDetailEdit_Entry_01, 0xf16006
	.set DrumDetailEdit_Entry_02, 0xf16028
	.set DrumDetailEdit_Entry_03, 0xf1604a
	.set DrumDetailEdit_Entry_04, 0xf16056
	.set DrumDetailEdit_Entry_05, 0xf16063
	.set DrumDetailEdit_Entry_06, 0xf16070
	.set DrumDetailEdit_Entry_07, 0xf16092
	.set DrumDetailEdit_Entry_08, 0xf1609e
	.set DrumDetailEdit_Entry_09, 0xf160ab
	.set Data_Dispatch_Entry, 0xf160b8
	.set Data_Dispatch_Entry_0x39, 0xf160f1
	.set Data_Dispatch_Entry_0x45, 0xf160fd
	.set EffectParamEdit_Entry_01, 0xf1649b
	.set EffectParamEdit_Entry_02, 0xf164a6
	.set EffectParamEdit_Entry_03, 0xf164b5
	.set EffectParamEdit_Entry_04, 0xf164c0
	.set EffectParamEdit_Entry_05, 0xf164cb
	.set EffectParamEdit_Entry_06, 0xf164d6
	.set EffectParamEdit_Entry_07, 0xf164e1
	.set EffectParamEdit_Entry_08, 0xf164ec
	.set SeqVoice_ValidateAndProcessState_0x13, 0xf400ec
	.set NakaData_PerfStyleCode, 0xf5001f
	.set NakaData_PerfStyleCode_0x10, 0xf5002f
	.set NakaData_PerfStyleCode_0x1A, 0xf50039
	.set NakaData_PerfStyleCode_0x33, 0xf50052
	.set NakaData_PerfStyleCode_0x59, 0xf50078
	.set MSP_FactoryPresetData_Continued, 0xf700bb
	.set SLDstBankList_FuncBody_0x44, 0xf900b9
	.set SLDstBankList_FuncBody_0x7C, 0xf900f1
	.set FDC_INIT, 0xf96bbf
	.set FDC_CONFIG_VERIFY, 0xf96bd0
	.set FDC_CMD_DISPATCH_SUB, 0xf96d95
	.set FDC_CMD_SEND, 0xf972f9
	.set FDC_DETECT_CHECK, 0xf974fe
	.set FDC_DRIVE_DETECT, 0xf97544
	.set FDC_DRIVE_STATUS, 0xf97592
	.set FDC_PRE_OP_CHECK, 0xf975ac
	.set FDC_TIMING_DELAY, 0xf975dc
	.set FDC_POST_OP, 0xf975e2
	.set FDC_STATUS_HANDLER, 0xf97696
	.set FDC_CE_DISPATCH, 0xf9782a
	.set FDC_CE_EXIT, 0xf97833
	.set FDC_SECTOR_XFER, 0xf97835
	.set FDC_SX_MAIN, 0xf9795e
	.set FDC_SX_EXIT, 0xf97967
	.set FDC_CMD_ENABLE, 0xf97c21
	.set FDC_CMD_DISABLE, 0xf97c4b
	.set FDC_OUTPUT_CTRL, 0xf97c5b
	.set RVari_SelectO_SecondItem_Draw_0x32, 0xfc0012
	.set NakaData_WidgetInit1, 0xfc645a
	.set NakaData_WidgetInit2, 0xfc647f
	.set NakaData_WidgetInit3, 0xfc64ea
	.set SeqChan_UnhandledCmd, 0xfd8261
	.set SeqChan_UnhandledCmd_0x01, 0xfd8262
	.set SeqChan_UnhandledCmd_0x02, 0xfd8263
	.set SeqChan_UnhandledCmd_0x03, 0xfd8264
	.set SeqChan_UnhandledCmd_0x12, 0xfd8273
	.set AudioInit_PartConfig_Loop_0x26, 0xfe0053
	.set HdaeRom_DataHandler_0x22, 0xff0270
	.set HdaeRom_DispatchOffsetTable, CharMap_PermutationPtrTable_B + 540
	.set HdaeRom_AltDispatchOffsetTable, CharMap_PermutationPtrTable_B + 552
	.set NakaData_RomEnd, 0xffffff
