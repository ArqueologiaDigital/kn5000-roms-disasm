; HDAE5000 Hard Disk Expansion ROM Disassembly
; Original file: hd-ae5000_v2_06i.ic4
; Size: 512KB (0x80000 bytes)
; Base address: 0x280000 (mapped in main CPU address space)
;
; This ROM is part of the optional HD-AE5000 hard disk expansion for the
; Technics KN5000 music keyboard. It provides:
;   - Hard disk file management
;   - PC parallel port communication (PPORT)
;   - Additional UI elements for HD operations
;
; Version: 2.33J (as stated in ROM strings)
; Date: Juli-Oktober 1996
; Author: M. Kitajima (Technics Software section)
;
; Entry Points (called by main CPU via validation at boot):
;   0x280008 - JP to HDAE5000_Boot_Init (0x28F576)
;   0x280010 - JP to HDAE5000_Frame_Handler (0x28F662)
;
; Hardware accessed:
;   0x160000-0x160006 - HDAE5000 PPI (8255) ports
;   0x23xxxx - RAM workspace (shared with main CPU)
;
; ROM Layout (file offsets):
;   0x00000-0x0001F  Header with "XAPR4" magic and entry vectors (32 bytes)
;   0x00020-0x0F575  Code section 1 - setup routines (62806 bytes)
;   0x0F576-0x0F661  HDAE5000_Boot_Init routine (236 bytes)
;   0x0F662-0x1541D  Code section 2 - frame handler and helpers (24252 bytes)
;   0x1541E-0x1562A  PPORT menu command strings (~524 bytes)
;   0x1562A-0x199B1  More code and data tables (17543 bytes)
;   0x199B2-0x1BAxx  Version info and Windows DLL callback names
;   0x1C1E1-0x7FFFF  Padding zeros

	cpu 900/H2
	org 280000h

; ============================================================================
; ROM HEADER
; ============================================================================

HDAE5000_ROM_HEADER:
	db "XAPR4"			; Magic identifier ("XAPR" checked by main CPU)
	db 0A1h				; Version byte
	db 02Fh, 000h			; Unknown (possibly size/flags)

; Entry point 1 - Jump to boot initialization
HDAE5000_ENTRY_1:			; 280008h
	jp HDAE5000_Boot_Init		; Called when main CPU validates HDAE5000 presence

; Padding after vector
	ret
	nop
	nop
	nop

; Entry point 2 - Jump to frame handler (called periodically)
HDAE5000_ENTRY_2:			; 280010h
	jp HDAE5000_Frame_Handler	; Called from main loop for HD status updates

; Unused entry vectors (return immediately)
HDAE5000_ENTRY_3:			; 280018h
	ret
	nop
	nop
	nop

HDAE5000_ENTRY_4:			; 28001Ch
	ret
	nop
	nop
	nop

; ============================================================================
; CODE SECTION 1 (0x280020 - 0x28F575)
; Setup routines, resource registration, callback handlers
; ~62KB of TMP94C241 code
; ============================================================================

HDAE5000_Code_Section_1:		; 280020h
	; Contains resource registration, PPI communication,
	; file system operations, and various handler routines
	binclude "includes/code_280020_28f575.bin"

; ============================================================================
; BOOT INITIALIZATION ROUTINE
; Called once at startup when HDAE5000 is detected via header validation
; ============================================================================

HDAE5000_Boot_Init:			; 28F576h
	; Entry point called by main CPU during boot
	; - Stores context pointer at 0x23A1A2
	; - Calls resource registration at 0x280020
	; - Sets up memory transfers for HD resources
	; - Registers callbacks with main CPU
	binclude "includes/boot_init_28f576_28f661.bin"

; ============================================================================
; CODE SECTION 2 (0x28F662 - 0x29541D)
; Frame handler and additional support routines
; ============================================================================

HDAE5000_Frame_Handler:			; 28F662h
	; Called periodically from main loop
	; - Monitors disk activity status
	; - Updates UI elements for HD operations
	; - Handles state machine for HD commands
	binclude "includes/code_28f662_29541d.bin"

; ============================================================================
; PPORT MENU COMMAND STRINGS
; Displayed on KN5000 screen during PC parallel port communication
; ============================================================================

PPORT_CMD_STRINGS:			; 29541Eh
PPORT_CMD_01:	db "01>Send Infos About HD", 0
PPORT_CMD_02:	db "02>Exit PPORT         ", 0
PPORT_CMD_03:	db "03>Read FSB from HD   ", 0
PPORT_CMD_04:	db "04>Sending FSB to PC  ", 0
PPORT_CMD_05:	db "05>Rcv FSB from PC    ", 0
PPORT_CMD_06:	db "06>Writing FSB to HD  ", 0
PPORT_CMD_07:	db "07>Load HD to Memory  ", 0
PPORT_CMD_08:	db "08>Send data to PC    ", 0
PPORT_CMD_09:	db "09>Sending files to PC", 0
PPORT_CMD_10:	db "10>Rcv data from PC   ", 0
PPORT_CMD_11:	db "11>Save memory to HD  ", 0
PPORT_CMD_12:	db "12>nothing            ", 0
PPORT_CMD_13:	db "13>Rcv data from PC   ", 0
PPORT_CMD_14:	db "14>Sending infos to PC", 0
PPORT_CMD_15:	db "15>nothing            ", 0
PPORT_CMD_16:	db "16>Delete files       ", 0
PPORT_CMD_17:	db "17>Formating HD       ", 0
PPORT_CMD_18:	db "18>Switch HD-motor off", 0
PPORT_CMD_19:	db "19>nothing            ", 0
PPORT_CMD_20:	db "20>Send XapFile flash ", 0
PPORT_CMD_20_OK:	db "20>End flash right", 09h, "  ", 0
PPORT_CMD_20_ERR:	db "20>End flash false", 09h, "  ", 0
PPORT_DLL_ERROR:	db "Error : Wrong Dll Ver ", 0

; ============================================================================
; CODE/DATA SECTION 3 (after PPORT strings)
; More code routines and data tables
; ============================================================================

HDAE5000_Code_Section_3:		; ~29562Ah
	; Additional routines and lookup tables
	binclude "includes/code_29562a_2999b1.bin"

; ============================================================================
; VERSION INFORMATION
; ============================================================================

HDAE5000_VERSION_INFO:			; 2999B2h
	db "Technics Software section    M. Kitajima"
	db "2.33J                   "
	db "2.21                    "
	db "TECHNICS KN5000                                 "
	db "Juli-Oktober 1996"
	db "XXXXXXXX", 0

; ============================================================================
; DATA SECTION (after version info, before Windows callbacks)
; ============================================================================

HDAE5000_Data_Section:			; ~299A56h
	binclude "includes/data_299a56_29bafe.bin"

; ============================================================================
; WINDOWS DLL CALLBACK NAMES
; Function names for PC-side PPORT communication software
; These are exported symbols that the Windows DLL uses for callbacks
; ============================================================================

WIN_CALLBACK_NAMES:			; 29BAFEh
	db "LyricBackColorCheck", 0
	db "LyricForeColorCheck", 0
	db "LyricJumpEditCheck", 0
	db "BitmapButt01", 0
	db "LanguageTextReturn", 0
	db "ErrMsgTimerCatchLBN", 0
	db "ErrMsgTimerCatch", 0
	db "SeparateBassPartCheck", 0
	db "SeparateDrumPartCheck", 0
	db "FlsOverWrSwCatch", 0
	db "FlsDel2SwCatch", 0
	db "FlsDel1SwCatch", 0
	db "AttenCpToMarkSwCatch", 0
	db "AttenCpToHDSwCatch", 0
	db "AttenHDFormatSwCatch", 0
	db "AttenDelFileSwCatch", 0
	db "AttenDelDirSwCatch", 0
	db "FlsFileLoadSwCatch", 0
	; ... more callback names
	binclude "includes/win_callbacks_rest.bin"

; ============================================================================
; PADDING TO END OF ROM
; ============================================================================

HDAE5000_PADDING:			; ~29C1E1h
	; Zeros to end of 512KB ROM
	binclude "includes/padding.bin"

; ============================================================================
; END OF ROM
; ============================================================================

	end
