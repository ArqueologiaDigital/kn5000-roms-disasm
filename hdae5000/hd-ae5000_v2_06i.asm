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
;   0x1541E-0x15642  PPORT menu command strings (~548 bytes)
;   0x15643-0x199B1  More code and data tables
;   0x199B2-0x1BAxx  Version info and Windows DLL callback names
;   0x1C1E1-0x7FFFF  Padding zeros

	cpu	96c141	; Actual CPU is TMP94C241F (ASL only supports TMP96C141)
	page	0
	maxmode	on
	include "../tmp94c241.inc"

	org	280000h

; ============================================================================
; ROM HEADER
; ============================================================================

HDAE5000_ROM_HEADER:
	db	"XAPR4"			; Magic identifier ("XAPR" checked by main CPU)
	db	0A1h			; Version byte
	db	02Fh, 000h		; Unknown (possibly size/flags)

; Entry point 1 - Jump to boot initialization
HDAE5000_ENTRY_1:			; 280008h
	jp	HDAE5000_Boot_Init	; Called when main CPU validates HDAE5000 presence

; Padding after vector
	ret
	nop
	nop
	nop

; Entry point 2 - Jump to frame handler (called periodically)
HDAE5000_ENTRY_2:			; 280010h
	jp	HDAE5000_Frame_Handler	; Called from main loop for HD status updates

; Padding after vector
	ret
	nop
	nop
	nop

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
; CODE AND DATA SECTION (0x280020 - 0x28F575)
; ============================================================================

HDAE5000_Code_Section_1:		; 280020h
	binclude "includes/code_280020_28f575.bin"

; ============================================================================
; BOOT INITIALIZATION ROUTINE (0x28F576 - 0x28F661)
; Called once at startup when HDAE5000 is detected via header validation
; ============================================================================

HDAE5000_Boot_Init:			; 28F576h
	binclude "includes/boot_init_28f576_28f661.bin"

; ============================================================================
; CODE SECTION 2 (0x28F662 - 0x2FFFFF)
; Frame handler and all remaining code/data to end of ROM
; ============================================================================

HDAE5000_Frame_Handler:			; 28F662h
	binclude "includes/code_28f662_2fffff.bin"

; ============================================================================
; END OF ROM
; ============================================================================

	end
