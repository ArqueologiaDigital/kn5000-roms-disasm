	cpu	96c141	; Actual CPU is 94c241f
	page	0
	maxmode	on
	include "../tmp94c241.inc"
	include "../shared/sfr_tmp94c241.asm"

; =============================================================================
; Constants for shared boot routines
; =============================================================================
REGION_CODE_VAR		EQU	00C06h		; RAM address for region code
BOOT_ENTRY_POINT	EQU	Boot_Init	; Entry point for watchdog reset

	ORG 0800000h
LABEL_800000:
	db 0 ;	TODO: figure out what's here.


	ORG 87FFF0h

hkst_55:
	db "hkst_55.ssf", 0
	dd 00000000h
	dd LABEL_88000C
	dd Feature_Demo_XML
	dd FeatureDemo_FileEntry1

LABEL_88000C:
	dw 0000h

Feature_Demo_XML:	; 88000E
	binclude "includes/hkst_55.ssf"
	db 00h

	ORG 880418h
Feature_Bitmap_1:	; 880418
	binclude "images/FTBMP01.BMP"

	ORG 89344Eh
Feature_Bitmap_2:	; 89344E
	binclude "images/FTBMP02.BMP"

	ORG 89DB04h
Feature_Bitmap_3:	; 89DB04
	binclude "images/FTBMP03.BMP"

	ORG 8A753Ah
Feature_Bitmap_4:	; 8A753A
	binclude "images/FTBMP04.BMP"

	ORG 8B0F70h
Feature_Bitmap_5:	; 8B0F70
	binclude "images/FTBMP05.BMP"

	ORG 8BAFE6h
Feature_Bitmap_6:	; 8BAFE6
	binclude "images/FTBMP06.BMP"


	ORG 08CE01Ch

FeatureDemo_FileEntry1:
	db "FTBMP01.BMP", 0
	dd 00000000h
	dd Feature_Bitmap_1
	dd 436 + (320 * 240)

FeatureDemo_FileEntry2:
	db "FTBMP02.BMP", 0
	dd 00000000h
	dd Feature_Bitmap_2
	dd 436 + (320 * 130)

FeatureDemo_FileEntry3:
	db "FTBMP03.BMP", 0
	dd 00000000h
	dd Feature_Bitmap_3
	dd 436 + (320 * 120)

FeatureDemo_FileEntry4:
	db "FTBMP04.BMP", 0
	dd 00000000h
	dd Feature_Bitmap_4
	dd 436 + (320 * 120)

FeatureDemo_FileEntry5:
	db "FTBMP05.BMP", 0
	dd 00000000h
	dd Feature_Bitmap_5
	dd 436 + (320 * 125)

FeatureDemo_FileEntry6:
	db "FTBMP06.BMP", 0
	dd 00000000h
	dd Feature_Bitmap_6
	dd 436 + (320 * 240)

	db 30 dup (000h)

	; Unused ROM space:
	db 08000h dup (0ffh)
	db 08000h dup (0ffh)
	db 01F36h dup (0ffh)


	ORG 08E0000h

Compressed_data:
	; I think this is probably the subprogram rom compressed using
	; the LZSS algorithm, as described at
	; https://github.com/felipesanches/kn5000_homebrew/blob/main/kn5000_extract.py
	db "SLIDE4K", 000h, 000h, 095h, 000h, "}Z", 0EEh, 0F0h
	; etc...



	ORG 9FA000h
LABEL_9FA000:
	db "SLIDE", 000h
	db "Technics KN5000 Program  DATA FILE 1/2", 000h, 0ffh		; 9FA007
	db "Technics KN5000 Program  DATA FILE 2/2", 000h, 0ffh		; 9FA02F
	db "Technics KN5000 Program  DATA FILE PCK", 000h, 0ffh		; 9FA057
	db "Technics KN5000 Table    DATA FILE 1/2", 000h, 0ffh		; 9FA07F
	db "Technics KN5000 Table    DATA FILE 2/2", 000h, 0ffh		; 9FA0A7
	db "Technics KN5000 Table    DATA FILE PCK", 000h, 0ffh		; 9FA1CF
	db "Technics KN5000 CMPCUSTOMDATA FILE    ", 000h, 0ffh		; 9FA0F7
	db "Technics KN5000 HD-AEPRG DATA FILE    ", 000h, 0ffh		; 9FA11F

;HANDLE_UPDATE_BASE_ADDR		EQU HANDLE_UPDATE_FILE_TYPE_ID_001h
;
;HANDLE_UPDATE_OFFSETS:			; E00178
;	dw (HANDLE_UPDATE_FILE_TYPE_ID_001h - HANDLE_UPDATE_BASE_ADDR)	; "Technics KN5000 ;Program DATA FILE 1/2"
;	dw (SHOW_ILLEGAL_DISK_MESSAGE - HANDLE_UPDATE_BASE_ADDR)	; "Technics KN5000 Program DATA FILE 2/2"
;	dw (HANDLE_UPDATE_FILE_TYPE_ID_003h - HANDLE_UPDATE_BASE_ADDR)	; "Technics KN5000 Table DATA FILE 1/2"
;	dw (SHOW_ILLEGAL_DISK_MESSAGE - HANDLE_UPDATE_BASE_ADDR)	; "Technics KN5000 Table DATA FILE 2/2"
;	dw (HANDLE_UPDATE_FILE_TYPE_ID_005h - HANDLE_UPDATE_BASE_ADDR)	; "Technics KN5000 CMPCUSTOMDATA FILE"
;	dw (HANDLE_UPDATE_FILE_TYPE_ID_006h - HANDLE_UPDATE_BASE_ADDR)	; "Technics KN5000 HD-AEPRG DATA FILE"
;	dw (HANDLE_UPDATE_FILE_TYPE_ID_007h - HANDLE_UPDATE_BASE_ADDR)	; "Technics KN5000 Program DATA FILE PCK"
;	dw (HANDLE_UPDATE_FILE_TYPE_ID_008h - HANDLE_UPDATE_BASE_ADDR)	; "Technics KN5000 Table DATA FILE PCK"


	ORG 9FA150h

LABEL_9FA150:
	db "SLIDE", 000h

Bitmap_1bit_Flash_Memory_Update:	; 9FA156
	binclude "../maincpu/images/Bitmap_1bit_Flash_Memory_Update.bin"

Bitmap_1bit_Now_Erasing:		; 9FA3BE
	binclude "../maincpu/images/Bitmap_1bit_Now_Erasing.bin"

Bitmap_1bit_FD_to_Flash_Memory:		; 9FA626
	binclude "../maincpu/images/Bitmap_1bit_FD_to_Flash_Memory.bin"

Bitmap_1bit_Completed:			; 9FA88E
	binclude "../maincpu/images/Bitmap_1bit_Completed.bin"

Bitmap_1bit_Please_Wait:		; 9FAAF6
	binclude "../maincpu/images/Bitmap_1bit_Please_Wait.bin"

Bitmap_1bit_Change_FD_2_of_2:		; 9FAD5E
	binclude "../maincpu/images/Bitmap_1bit_Change_FD_2_of_2.bin"

Bitmap_1bit_Illegal_Disk:		; 9FAFC6
	binclude "../maincpu/images/Bitmap_1bit_Illegal_Disk.bin"

Bitmap_1bit_Turn_On_AGAIN:		; 9FB22E
	binclude "../maincpu/images/Bitmap_1bit_Turn_On_AGAIN.bin"


; =============================================================================
; FIRST-STAGE BOOTLOADER CODE
; =============================================================================
; This code runs when the CPU boots, before memory remapping.
; At boot time, this ROM is mapped at 0xE00000-0xFFFFFF.
; After remapping, it's at 0x800000-0x9FFFFF.
;
; The interrupt vectors contain boot-time addresses (0xFFxxxx), so we define
; them as constants here.
; =============================================================================

; Boot-time addresses (CPU sees ROM at 0xE00000-0xFFFFFF at boot)
BOOT_EMPTY_HANDLER	EQU	0FFB705h
BOOT_RESET_HANDLER	EQU	0FFFEE0h
BOOT_NMI_HANDLER	EQU	0FFB7FBh
BOOT_INT4_HANDLER	EQU	0FFEAB2h
BOOT_INTA_HANDLER	EQU	0FFF229h
BOOT_INTT1_HANDLER	EQU	0FFB7F2h
BOOT_INTRX1_HANDLER	EQU	0FFF2D0h
BOOT_INTTX1_HANDLER	EQU	0FFF2AEh
BOOT_INTTC3_HANDLER	EQU	0FFEA9Dh
BOOT_ENTRY		EQU	0FFB4E8h

; -----------------------------------------------------------------------------
; Boot Data Section - Constants copied to RAM during initialization
; These are referenced by Boot_ClearRAM routine
; -----------------------------------------------------------------------------
	ORG 09FB4D2h
Boot_BitMaskTable:	; Copied to RAM 0x1044 by Boot_ClearRAM (10 bytes)
	; Bit mask pattern for bit manipulation operations (bits 7..0, plus 2 zeros)
	db	080h, 040h, 020h, 010h, 008h, 004h, 002h, 001h, 000h, 000h

Boot_InitParams:	; Copied to RAM 0x9998 by Boot_ClearRAM (12 bytes)
	; Stack/display initialization parameters
	db	07Eh, 010h	; Values at 0x9998-9999
	db	000h, 000h	; Values at 0x999A-999B
	db	000h, 080h	; Values at 0x999C-999D
	db	000h, 000h	; Values at 0x999E-999F
	db	000h, 000h	; Values at 0x99A0-99A1
	db	000h, 000h	; Values at 0x99A2-99A3


	ORG 09FB4E8h
; -----------------------------------------------------------------------------
; Boot_Init - First-stage bootloader entry point
; Initializes CPU, memory controller, and hands off to main program ROM
; -----------------------------------------------------------------------------
Boot_Init:
	; Hardware initialization code shared with maincpu ROM
	include "../shared/boot_hw_init.asm"
	; End of shared boot code (315 bytes)

	; === Stack Pointer Setup ===
	LDA_XWA_IMM24	00987Eh
	LD	XSP, XWA

	; === Clear RAM Variable ===
	LD	XWA, 0
	db	0F1h, 000h, 00Ch, 060h		; LD (0x0C00), XWA

	; === Call Boot_ClearRAM ===
	CALR	Boot_ClearRAM

	; === Reload Stack Pointer ===
	LDA_XWA_IMM24	00987Eh
	LD	XSP, XWA

	; === Enable Interrupts ===
	EI	0

	; === Detect Boot Mode ===
	CALR	Detect_Region_Code

	; === Call Main Hardware Init ===
	CALL	0FFBBF3h			; Flash_Init_Custom_And_Table (boot-time address)

	; === Configure Interrupt Enable Register ===
	LDA	XBC, 0E4h
	LD	A, (XBC)
	AND	A, 08Fh
	OR	A, 030h
	LD	(XBC), A

	; === Check Boot Source ===
	JR	T, $+2				; nop-like branch
	BIT	0, (PE)				; Check Port E bit 0
	JR	NZ, Boot_SkipFDCCheck

	; === Get Boot Mode and Check FDC ===
	CALR	Get_Region_Code
	CP	L, 4
	db	0F2h, 0B2h, 0C6h, 0FFh, 0EEh	; CALL NZ, 0xFFC6B2 (Boot_FDCRoutine)

Boot_SkipFDCCheck:
	CALL	0FFEC63h			; Boot_CheckFlash
	CP	L, 0
	JR	Z, Boot_PrepareJump

	; === Load and Call Function Pointer ===
	LD	XHL, (0FFEC6Eh)
	CALL	T, XHL

	; === Validate Boot Image ===
	CALL	0FFED0Eh			; Boot_ValidateImage
	CP	L, 4
	JR	NZ, Boot_PrepareJump

	; === Flash Update Sequence ===
	CALL	0FFBF07h			; Boot_InitDisplay
	CALL	0FFD262h			; Boot_ShowMessage
	PUSHW	0008h
	PUSHW	0003h
	LD	XWA, 00FFAAF6h			; message addr
	LD	BC, 0030h			; width
	LD	DE, 0050h			; height
	CALL	0FFCCFBh			; Boot_DrawBitmap
	CALL	0FFBFC4h			; Boot_WaitForInput
	CP	L, 3
	JR	Z, Boot_PrepareJump
	CP	L, 008h
	JR	Z, Boot_PrepareJump
	CP	L, 0FFh
	JR	Z, Boot_PrepareJump
	CALL	0FFCC2Ah			; Boot_PerformUpdate

Boot_HaltLoop:
	JR	T, Boot_HaltLoop

Boot_PrepareJump:
	; === Prepare to Jump to Main Program ROM ===
	EI	7				; disable maskable interrupts

	; === Clear Interrupt Flags ===
	LD	(0E4h), 000h
	LD	(0E0h), 000h
	LD	(0EDh), 000h
	LD	(0E3h), 000h
	LD	(0EBh), 000h

	; === Setup for Jump to Main Program ===
	LD	XSP, 000000C00h
	LD	XWA, 000FFFEDCh			; target address
	LD	IX, 014Bh			; CS2 register
	EXTZ	XIX
	SLL_0_XBC				; alignment/padding
	SLL_0_XBC
	LD	(XIX), 080h			; CS2 config
	JP	T, XWA				; jump to main program!

Boot_Ret:
	RET

; =============================================================================
; Shared boot routines (Detect_Region_Code, Get_Region_Code, handlers)
; Uses REGION_CODE_VAR and BOOT_ENTRY_POINT defined at top of file
; =============================================================================
	include "../shared/boot_routines.asm"

; Alias labels for backward compatibility with existing code

; -----------------------------------------------------------------------------
; Boot_Handler_End - End of boot exception handlers
; Address: 0x9FB709 (boot-time: 0xFFB709)
; This is the RETI at the end of Watchdog_Reset_Handler in shared file
; -----------------------------------------------------------------------------
Boot_Handler_End	EQU	Watchdog_Reset_Handler + 4

; -----------------------------------------------------------------------------
; Boot_CallInitHandlers - Call initialization handlers from table
; Address: 0x9FB70A (boot-time: 0xFFB70A)
;
; Purpose: If (0xFFFEEE) != 0xFFFF, calls up to 4 init handlers from a table
;          at 0xFFFEF0. Each table entry is a 32-bit address.
;
; Table at 0xFFFEF0:
;   [0] = Handler 0 address (32-bit)
;   [1] = Handler 1 address (32-bit)
;   [2] = Handler 2 address (32-bit)
;   [3] = Handler 3 address (32-bit)
;
; Entry: None
; Exit: All handlers called if (0xFFFEEE) was not 0xFFFF
; -----------------------------------------------------------------------------
Boot_CallInitHandlers:
	PUSH	QIZ				; save register
	CP_MEM24_IMM16	0FFFEEEh, 0FFFFh	; CP (0xFFFEEE), 0xFFFF
	JR	NZ, .done			; skip if flag not set
	LD_QIZH_0				; init counter

.handler_loop:
	LD_A_QIZH				; get counter
	EXTZ_WA					; extend to 16-bit
	LD_C_QIZH				; copy counter to C
	EXTZ_BC					; extend to 16-bit
	SLA_2_BC				; BC *= 4 (32-bit table entries)
	LDA_XDE_IMM24	0FFFEF0h		; table base
	LD_XBC_pXDE_BC				; LD XBC, (XDE+BC) - load handler address
	CALL	0FFFA75h			; indirect call helper
	INC_1_QIZH				; counter++
	CP_QIZH_4				; check if done
	JR	C, .handler_loop		; loop if counter < 4

.done:
	POP	QIZ				; restore register
	RET

; -----------------------------------------------------------------------------
; Boot_ClearRAM - Initialize RAM and copy ROM data to RAM
; Address: 0xFFB740 (boot-time), 0x9FB740 (ROM)
;
; Operations performed:
;   1. Clear 0x894A bytes (35,146) at RAM 0x104E
;   2. Clear 0x0443 bytes (1,091) at RAM 0x0C00
;   3. Copy 12 bytes from ROM 0xFFB4DC to RAM 0x9998
;   4. Copy 10 bytes from ROM 0xFFB4D2 to RAM 0x1044
;
; Uses LDIRW for efficient word-mode block operations
; -----------------------------------------------------------------------------
	ORG 09FB740h
Boot_ClearRAM:
	; === Clear RAM block 1: 0x104E for 0x894A bytes ===
	LD	XDE, 00000104Eh			; destination
	LD	XBC, 0000894Ah			; count = 35146 bytes
	LD	IX, BC				; save original count
	db	0E9h, 0EFh, 001h		; SRL 1, XBC (divide by 2 for word count)
	JR	Z, .clear1_done			; skip if zero
	LD	XHL, XDE			; source = dest for fill
	db	0F5h, 0E9h, 002h, 000h, 000h	; LD (XDE+), 0x0000 (store first zero word)
	db	0E9h, 069h			; DEC 1, XBC
	OR	XBC, XBC			; test if zero
	JR	Z, .clear1_done
	LDIRW_93				; word block copy - fills with zeros
	db	0D7h, 0E6h, 0D8h		; CP QBC, 0 (check high dword)
	JR	Z, .clear1_done
	db	0D7h, 0E6h, 088h		; LD WA, QBC
	LDIRW_93
	db	0D8h, 01Ch, 0FBh		; DJNZ WA, -5
.clear1_done:
	db	0DCh, 033h, 000h		; BIT 0, IX (check if odd byte)
	JR	Z, .clear1_aligned
	LD	(XDE), 000h			; clear last odd byte
.clear1_aligned:

	; === Clear RAM block 2: 0x0C00 for 0x0443 bytes ===
	LD	XDE, 000000C00h			; destination
	LD	XBC, 000000443h			; count = 1091 bytes
	LD	IX, BC
	db	0E9h, 0EFh, 001h		; SRL 1, XBC
	JR	Z, .clear2_done
	LD	XHL, XDE
	db	0F5h, 0E9h, 002h, 000h, 000h	; LD (XDE+), 0x0000
	db	0E9h, 069h			; DEC 1, XBC
	OR	XBC, XBC
	JR	Z, .clear2_done
	LDIRW_93
	db	0D7h, 0E6h, 0D8h		; CP QBC, 0
	JR	Z, .clear2_done
	db	0D7h, 0E6h, 088h		; LD WA, QBC
	LDIRW_93
	db	0D8h, 01Ch, 0FBh		; DJNZ WA, -5
.clear2_done:
	db	0DCh, 033h, 000h		; BIT 0, IX
	JR	Z, .clear2_aligned
	LD	(XDE), 000h
.clear2_aligned:

	; === Copy ROM data 1: 12 bytes from 0xFFB4DC to RAM 0x9998 ===
	LD	XDE, 000009998h			; destination
	LD	XHL, 000FFB4DCh			; source in boot ROM
	LD	XBC, 00000000Ch			; count = 12 bytes
	OR	XBC, XBC
	JR	Z, .copy1_done
	LDIR_83					; byte block copy
	db	0D7h, 0E6h, 0D8h		; CP QBC, 0
	JR	Z, .copy1_done
	db	0D7h, 0E6h, 088h		; LD WA, QBC
	LDIR_83
	db	0D8h, 01Ch, 0FBh		; DJNZ WA, -5
.copy1_done:

	; === Copy ROM data 2: 10 bytes from 0xFFB4D2 to RAM 0x1044 ===
	LD	XDE, 000001044h			; destination
	LD	XHL, 000FFB4D2h			; source in boot ROM
	LD	XBC, 00000000Ah			; count = 10 bytes
	OR	XBC, XBC
	JR	Z, .copy2_done
	LDIR_83
	db	0D7h, 0E6h, 0D8h		; CP QBC, 0
	JR	Z, .copy2_done
	db	0D7h, 0E6h, 088h		; LD WA, QBC
	LDIR_83
	db	0D8h, 01Ch, 0FBh		; DJNZ WA, -5
.copy2_done:
	JRL_T	Boot_Init+014Bh			; return to caller at 0xFFB633
	RET					; never reached

; =============================================================================
; BOOT INTERRUPT HANDLERS
; Addresses 0x9FB7F2-0x9FB811
; =============================================================================

	ORG 09FB7F2h

; -----------------------------------------------------------------------------
; BootCode_INTT1_Handler - Timer 1 interrupt handler
; Address: 0x9FB7F2
; Increments 32-bit tick counter at RAM 0x0C00
; -----------------------------------------------------------------------------
BootCode_INTT1_Handler:
	PUSH	XWA			; 38
	LD	XWA, 1			; e8 a9
	ADD	(00C00h), XWA		; e1 00 0c 88
	POP	XWA			; 58
	RETI				; 07

; -----------------------------------------------------------------------------
; BootCode_NMI_Handler - Non-maskable interrupt handler
; Address: 0x9FB7FB
; Fatal error - disables DRAM refresh and halts
; -----------------------------------------------------------------------------
BootCode_NMI_Handler:
	RES	7, (0162h)		; f1 62 01 b7 - Disable DRAM refresh
.halt_loop:
	HALT				; 05
	JR	T, .halt_loop		; 68 fd

; -----------------------------------------------------------------------------
; Boot stub routines - return 0 in HL
; Addresses: 0x9FB802-0x9FB80D
; -----------------------------------------------------------------------------
Boot_Stub_Return0_1:
	LD	HL, 0			; db a8
	RET				; 0e

Boot_Stub_Return0_2:
	LD	HL, 0			; db a8
	RET				; 0e

Boot_Stub_Return0_3:
	LD	HL, 0			; db a8
	RET				; 0e

Boot_Stub_Return0_4:
	LD	HL, 0			; db a8
	RET				; 0e

; -----------------------------------------------------------------------------
; Boot stub - return 0xFFFF in HL (error/not found)
; Address: 0x9FB80E
; -----------------------------------------------------------------------------
Boot_Stub_ReturnFFFF:
	LD	HL, 0FFFFh		; 33 ff ff
	RET				; 0e

; =============================================================================
; 16-BIT FLASH PROGRAMMING ROUTINES
; For HDAE5000 expansion ROM (0x280000) and Custom Data Flash (0x300000)
; These use 16-bit bus width access
; =============================================================================

; -----------------------------------------------------------------------------
; Flash_Reset_16bit - Send software reset command to flash chip
; Address: 0x9FB812
;
; Entry: A = target (0=HDAE5000 at 0x280000, 1=Custom Data at 0x300000)
; Uses AMD/Atmel flash protocol: AA-55-F0 sequence
; For region code 4, also resets high bank at base+0x80000
; -----------------------------------------------------------------------------
Flash_Reset_16bit:
	PUSH	XIZ			; 3e
	LD	XBC, 00280000h		; 41 00 00 28 00 - HDAE5000 base
	CP	A, 1			; c9 d9
	JR	NZ, .got_base		; 6e 05
	LD	XBC, 00300000h		; 41 00 00 30 00 - Custom Data base
.got_base:
	LD	XIZ, XBC		; e9 8e
.wait_ready:
	BIT	5, (01Ch)		; f0 1c cd - Wait for P3 bit 5 (flash ready)
	JR	Z, .wait_ready		; 66 fb
	EI	6			; 06 06 - Disable lower interrupts
	; Send unlock sequence: base+AAAA = AA
	LD	XWA, XIZ		; ee 88
	ADD	XWA, 0000AAAAh		; e8 c8 aa aa 00 00
	db	0B0h, 002h, 0AAh, 000h	; LD (XWA), 00AAh (word store)
	; Send unlock sequence: base+5554 = 55
	db	0F3h, 0F9h, 054h, 055h, 002h, 055h, 000h	; LD (XIZ+5554h), 0055h
	; Send reset command: base+AAAA = F0
	LD	XWA, XIZ		; ee 88
	ADD	XWA, 0000AAAAh		; e8 c8 aa aa 00 00
	db	0B0h, 002h, 0F0h, 000h	; LD (XWA), 00F0h (word store)
	; Read to complete cycle
	db	0D3h, 0F9h, 032h, 032h, 020h	; LD WA, (XIZ+3232h)
	EI	0			; 06 00 - Re-enable interrupts
	; Check if region code = 4 (high bank exists)
	CALL	0FFB700h			; Get_Region_Code - returns region code in L
	CP	L, 4
	JR	NZ, .done
	; Reset high bank at base+0x80000
	ADD	XIZ, 00080000h		; ee c8 00 00 08 00
	EI	6			; 06 06
	LD	XWA, XIZ		; ee 88
	ADD	XWA, 0000AAAAh		; e8 c8 aa aa 00 00
	db	0B0h, 002h, 0AAh, 000h	; LD (XWA), 00AAh (word store)
	db	0F3h, 0F9h, 054h, 055h, 002h, 055h, 000h	; LD (XIZ+5554h), 0055h
	LD	XWA, XIZ		; ee 88
	ADD	XWA, 0000AAAAh		; e8 c8 aa aa 00 00
	db	0B0h, 002h, 0F0h, 000h	; LD (XWA), 00F0h (word store)
	db	0D3h, 0F9h, 032h, 032h, 020h	; LD WA, (XIZ+3232h)
	EI	0			; 06 00
.done:
	POP	XIZ			; 5e
	RET				; 0e

; -----------------------------------------------------------------------------
; Flash_ReadID_16bit - Read flash manufacturer and device ID
; Address: 0x9FB888
;
; Entry: A = target (0=HDAE5000, 1=Custom Data)
; Exit:  HL = device ID (or 0xFFFF if not recognized)
;
; Validated device IDs: 0x2223 (AM29F040), 0x22AB (AM29F400B),
;                       0x22D6 (AM29F800B), 0x2258 (AM29LV800B)
; Manufacturer IDs: 0x01 (AMD), 0x04 (Fujitsu)
; -----------------------------------------------------------------------------
Flash_ReadID_16bit:
	db	0EFh, 068h		; DEC 0, XSP - allocate 1 byte on stack
	PUSH	XIZ			; 3e
	db	0BFh, 00Ah, 041h	; LD (XSP+0Ah), A - save target
	db	0BFh, 008h, 002h, 0FFh, 0FFh	; LD (XSP+08h), 0FFFFh - default return
	LD	XWA, 00280000h		; 40 00 00 28 00 - HDAE5000 base
	db	08Fh, 00Ah, 03Fh, 001h	; CP (XSP+0Ah), 01h
	JR	NZ, .got_base		; 6e 05
	LD	XWA, 00300000h		; 40 00 00 30 00 - Custom Data base
.got_base:
	db	0BFh, 004h, 060h	; LD (XSP+04h), XWA - save base address
	EI	6			; 06 06
	; Send unlock and ID command
	db	0AFh, 004h, 021h	; LD XBC, (XSP+04h)
	ADD	XBC, 0000AAAAh		; e9 c8 aa aa 00 00
	db	0B1h, 002h, 0AAh, 000h	; LD (XBC), 00AAh (word store)
	db	0AFh, 004h, 022h	; LD XDE, (XSP+04h)
	db	0F3h, 0E9h, 054h, 055h, 002h, 055h, 000h	; LD (XDE+5554h), 0055h
	db	0B1h, 002h, 090h, 000h	; LD (XBC), 0090h - ID command (word store)
	; Read manufacturer ID
	LD	WA, (XDE)		; 92 20
	db	0D7h, 0FAh, 098h	; LD QIZ, WA - store manufacturer ID
	; Read device ID at base+2
	LD	XBC, XDE		; ea 89
	db	099h, 002h, 026h	; LD IZ, (XBC+02h)
	EI	0			; 06 00
	; Validate manufacturer (01=AMD, 04=Fujitsu)
	db	0D7h, 0FAh, 0D9h	; CP QIZ, 1
	JR	Z, .valid_mfr		; 66 05
	db	0D7h, 0FAh, 0DCh	; CP QIZ, 4
	JR	NZ, .reset_exit		; 6e 23
.valid_mfr:
	; Validate device ID
	db	0DEh, 0CFh, 023h, 022h	; CP IZ, 2223h (AM29F040)
	JR	Z, .valid_id		; 66 12
	db	0DEh, 0CFh, 0ABh, 022h	; CP IZ, 22ABh (AM29F400B)
	JR	Z, .valid_id		; 66 0c
	db	0DEh, 0CFh, 0D6h, 022h	; CP IZ, 22D6h (AM29F800B)
	JR	Z, .valid_id		; 66 06
	db	0DEh, 0CFh, 058h, 022h	; CP IZ, 2258h (AM29LV800B)
	JR	NZ, .store_return	; 6e 03
.valid_id:
	db	0BFh, 008h, 056h	; LD (XSP+08h), IZ - store valid device ID
.store_return:
	db	08Fh, 00Ah, 021h	; LD A, (XSP+0Ah) - restore target
	EXTZ_WA				; d8 12
	db	01Eh, 016h, 0FFh	; CALR Flash_Reset_16bit (relative call back)
.reset_exit:
	db	09Fh, 008h, 023h	; LD HL, (XSP+08h) - return device ID
	POP	XIZ			; 5e
	INC_0_XSP			; ef 60 - deallocate stack
	RET				; 0e

; -----------------------------------------------------------------------------
; Flash_ProgramWord_16bit - Program a word to flash memory
; Address: 0x9FB903
;
; Entry: A = target (0=HDAE5000, 1=Custom Data)
;        XBC = destination address
;        DE = data word to program
;
; Skips programming if data = 0xFFFF (erased state)
; Handles high bank (0x380000+) for Custom Data when region code = 4
; -----------------------------------------------------------------------------
Flash_ProgramWord_16bit:
	DEC_6_XSP			; ef 6e - allocate 6 bytes stack frame
	PUSH	XIZ			; 3e
	db	0BFh, 004h, 052h	; LD (XSP+04h), DE - save data
	db	0BFh, 006h, 061h	; LD (XSP+06h), XBC - save destination
	db	09Fh, 004h, 03Fh, 0FFh, 0FFh	; CP (XSP+04h), 0FFFFh
	JR	Z, .exit		; 66 51 - skip if already erased
	; Wait for flash ready
.wait_ready:
	BIT	5, (01Ch)		; f0 1c cd
	JR	Z, .wait_ready		; 66 fb
	; Check target
	CP	A, 1			; c9 d9
	JR	NZ, .hdae_target	; 6e 20
	; Custom Data target - check for high bank
	LDA	XIZ, 300000h		; f2 00 00 30 36
	db	01Dh, 000h, 0B7h, 0FFh	; CALL Boot_Get_Region_Code (at 0xFFB700)
	CP	L, 4			; cf dc
	JR	NZ, .do_program		; 6e 18
	; Check if address is in high bank (>= 0x380000)
	db	0AFh, 006h, 020h	; LD XWA, (XSP+06h)
	CP	XWA, 00380000h		; e8 cf 00 00 38 00
	JR	C, .do_program		; 67 0d
	ADD	XIZ, 00080000h		; ee c8 00 00 08 00
	JR	T, .do_program		; 68 05
.hdae_target:
	LDA	XIZ, 280000h		; f2 00 00 28 36
.do_program:
	EI	6			; 06 06
	; Send program command sequence
	LD	XWA, XIZ		; ee 88
	ADD	XWA, 0000AAAAh		; e8 c8 aa aa 00 00
	db	0B0h, 002h, 0AAh, 000h	; LD (XWA), 00AAh (word store)
	db	0F3h, 0F9h, 054h, 055h, 002h, 055h, 000h	; LD (XIZ+5554h), 0055h
	db	0B0h, 002h, 0A0h, 000h	; LD (XWA), 00A0h - Program command (word store)
	; Write data to destination
	db	0AFh, 006h, 020h	; LD XWA, (XSP+06h) - destination
	db	09Fh, 004h, 021h	; LD BC, (XSP+04h) - data
	LD	(XWA), BC		; b0 51
	EI	0			; 06 00
.exit:
	POP	XIZ			; 5e
	INC_6_XSP			; ef 66 - deallocate stack
	RET				; 0e

; -----------------------------------------------------------------------------
; Flash_ChipErase_16bit - Erase entire flash chip
; Address: 0x9FB968
;
; Entry: A = target (0=HDAE5000, 1=Custom Data)
;
; Uses 6-byte chip erase sequence: AA-55-80-AA-55-10
; For Custom Data with region code = 4, also erases high bank
; -----------------------------------------------------------------------------
Flash_ChipErase_16bit:
	db	0EFh, 06Ah		; DEC 2, XSP - allocate 2 bytes
	PUSH	XIZ			; 3e
	db	0BFh, 004h, 041h	; LD (XSP+04h), A - save target
	LD	XWA, 00280000h		; 40 00 00 28 00
	db	08Fh, 004h, 03Fh, 001h	; CP (XSP+04h), 01h
	JR	NZ, .got_base		; 6e 05
	LD	XWA, 00300000h		; 40 00 00 30 00
.got_base:
	LD	XIZ, XWA		; e8 8e
	EI	6			; 06 06
	; Send chip erase sequence (6 bytes)
	; Byte 1: base+AAAA = AA
	LD	XWA, XIZ		; ee 88
	ADD	XWA, 0000AAAAh		; e8 c8 aa aa 00 00
	db	0B0h, 002h, 0AAh, 000h	; LD (XWA), 00AAh (word store)
	; Byte 2: base+5554 = 55
	db	0F3h, 0F9h, 054h, 055h, 002h, 055h, 000h	; LD (XIZ+5554h), 0055h
	; Byte 3: base+AAAA = 80
	LD	XWA, XIZ		; ee 88
	ADD	XWA, 0000AAAAh		; e8 c8 aa aa 00 00
	db	0B0h, 002h, 080h, 000h	; LD (XWA), 0080h (word store)
	; Byte 4: base+AAAA = AA
	LD	XWA, XIZ		; ee 88
	ADD	XWA, 0000AAAAh		; e8 c8 aa aa 00 00
	db	0B0h, 002h, 0AAh, 000h	; LD (XWA), 00AAh (word store)
	; Byte 5: base+5554 = 55
	db	0F3h, 0F9h, 054h, 055h, 002h, 055h, 000h	; LD (XIZ+5554h), 0055h
	; Byte 6: base+AAAA = 10 (chip erase command)
	LD	XWA, XIZ		; ee 88
	ADD	XWA, 0000AAAAh		; e8 c8 aa aa 00 00
	db	0B0h, 002h, 010h, 000h	; LD (XWA), 0010h (word store)
	; Check region code for high bank
	db	01Dh, 000h, 0B7h, 0FFh	; CALL Boot_Get_Region_Code (at 0xFFB700)
	CP	L, 4			; cf dc
	JR	NZ, .done		; 6e 49
	db	08Fh, 004h, 03Fh, 001h	; CP (XSP+04h), 01h
	JR	NZ, .done		; 6e 43
	; Also erase high bank at 0x380000
	LDA	XIZ, 380000h		; f2 00 00 38 36
	LD	XWA, XIZ		; ee 88
	ADD	XWA, 0000AAAAh		; e8 c8 aa aa 00 00
	db	0B0h, 002h, 0AAh, 000h	; LD (XWA), 00AAh (word store)
	db	0F3h, 0F9h, 054h, 055h, 002h, 055h, 000h	; LD (XIZ+5554h), 0055h
	LD	XWA, XIZ		; ee 88
	ADD	XWA, 0000AAAAh		; e8 c8 aa aa 00 00
	db	0B0h, 002h, 080h, 000h	; LD (XWA), 0080h (word store)
	LD	XWA, XIZ		; ee 88
	ADD	XWA, 0000AAAAh		; e8 c8 aa aa 00 00
	db	0B0h, 002h, 0AAh, 000h	; LD (XWA), 00AAh (word store)
	db	0F3h, 0F9h, 054h, 055h, 002h, 055h, 000h	; LD (XIZ+5554h), 0055h
	LD	XWA, XIZ		; ee 88
	ADD	XWA, 0000AAAAh		; e8 c8 aa aa 00 00
	db	0B0h, 002h, 010h, 000h	; LD (XWA), 0010h (word store)
.done:
	EI	0			; 06 00
	POP	XIZ			; 5e
	db	0EFh, 062h		; INC 2, XSP - deallocate stack
	RET				; 0e

; -----------------------------------------------------------------------------
; Flash_SectorErase_16bit - Erase a single sector
; Address: 0x9FBA17
;
; Entry: A = target (0=HDAE5000, 1=Custom Data)
;        XBC = sector address
;
; Complex sector handling for boot block chips (AM29F400/800)
; Handles different sector layouts for bottom boot devices
; -----------------------------------------------------------------------------
Flash_SectorErase_16bit:
	db	0BFh, 0F6h, 037h	; LDA XSP, XSP+0F6h - allocate 10 bytes
	PUSH	XIZ			; 3e
	db	0BFh, 008h, 061h	; LD (XSP+08h), XBC - save sector address
	db	0BFh, 00Ch, 041h	; LD (XSP+0Ch), A - save target
	LD	XWA, 00280000h		; 40 00 00 28 00
	db	08Fh, 00Ch, 03Fh, 001h	; CP (XSP+0Ch), 01h
	JR	NZ, .got_base		; 6e 05
	LD	XWA, 00300000h		; 40 00 00 30 00
.got_base:
	LD	XIZ, XWA		; e8 8e
	; Mask sector address to get bank offset
	db	0AFh, 008h, 020h	; LD XWA, (XSP+08h)
	db	0BFh, 004h, 060h	; LD (XSP+04h), XWA
	LD	XWA, 00FF0000h		; 40 00 00 ff 00
	db	0AFh, 004h, 0C8h	; AND (XSP+04h), XWA
	; Check region and bank for Custom Data
	db	01Dh, 000h, 0B7h, 0FFh	; CALL Boot_Get_Region_Code (at 0xFFB700)
	CP	L, 4			; cf dc
	JR	NZ, .do_erase		; 6e 11
	db	0AFh, 004h, 020h	; LD XWA, (XSP+04h)
	CP	XWA, 00380000h		; e8 cf 00 00 38 00
	JR	C, .do_erase		; 67 06
	ADD	XIZ, 00080000h		; ee c8 00 00 08 00
.do_erase:
	EI	6			; 06 06
	; Send sector erase sequence
	LD	XWA, XIZ		; ee 88
	ADD	XWA, 0000AAAAh		; e8 c8 aa aa 00 00
	db	0B0h, 002h, 0AAh, 000h	; LD (XWA), 00AAh (word store)
	db	0F3h, 0F9h, 054h, 055h, 002h, 055h, 000h	; LD (XIZ+5554h), 0055h
	LD	XWA, XIZ		; ee 88
	ADD	XWA, 0000AAAAh		; e8 c8 aa aa 00 00
	db	0B0h, 002h, 080h, 000h	; LD (XWA), 0080h (word store)
	LD	XWA, XIZ		; ee 88
	ADD	XWA, 0000AAAAh		; e8 c8 aa aa 00 00
	db	0B0h, 002h, 0AAh, 000h	; LD (XWA), 00AAh (word store)
	db	0F3h, 0F9h, 054h, 055h, 002h, 055h, 000h	; LD (XIZ+5554h), 0055h
	; Send 0x30 to sector address
	db	0AFh, 004h, 020h	; LD XWA, (XSP+04h)
	db	0B0h, 002h, 030h, 000h	; LD (XWA), 0030h - Sector erase command (word store)

	; The rest of this routine handles special boot block sectors
	; This is complex sector layout handling for AM29F400B/AM29F800B

	; Check if Custom Data flash (target 1) with region code 4
	db	01Dh, 000h, 0B7h, 0FFh	; CALL Boot_Get_Region_Code (0xFFB700)
	CP	L, 4			; cf dc
	JR	NZ, .check_non_region4	; 6e 5f - skip if not region 4

	; Region 4: Check if Custom Data flash (target 1)
	db	08Fh, 00Ch, 03Fh, 001h	; CP (XSP+0Ch), 01h - check target
	db	07Eh, 024h, 001h	; JRL NZ, .sector_done - skip if HDAE

	; Custom Data region 4: Check 0x070000 and 0x0F0000 sectors
	LDA	XWA, 00300000h		; f2 00 00 30 30
	LD	XBC, XWA		; e8 89
	ADD	XBC, 00070000h		; e9 c8 00 00 07 00
	db	0AFh, 004h, 0F1h	; CP XBC, (XSP+04h)
	JR	Z, .erase_region4_boot	; 66 0e

	LD	XBC, XWA		; e8 89
	ADD	XBC, 000F0000h		; e9 c8 00 00 0f 00
	db	0AFh, 004h, 0F1h	; CP XBC, (XSP+04h)
	db	07Eh, 004h, 001h	; JRL NZ, .sector_done

.erase_region4_boot:
	; Erase 8KB boot block sectors at 0x78000, 0x7A000, 0x7C000
	LD	XBC, XIZ		; ee 89
	ADD	XBC, 00078000h		; e9 c8 00 80 07 00
	db	0B1h, 002h, 030h, 000h	; LD (XBC), 0030h (word store)
	LD	XBC, XIZ		; ee 89
	ADD	XBC, 0007A000h		; e9 c8 00 a0 07 00
	db	0B1h, 002h, 030h, 000h	; LD (XBC), 0030h (word store)
	LD	XBC, XIZ		; ee 89
	ADD	XBC, 0007C000h		; e9 c8 00 c0 07 00
	db	0B1h, 002h, 030h, 000h	; LD (XBC), 0030h (word store)

	; Check if sector address is at top of 1MB
	ADD	XWA, 000FFFFFh		; e8 c8 ff ff 0f 00
	db	0AFh, 008h, 0F8h	; CP (XSP+08h), XWA
	db	07Eh, 0D4h, 000h	; JRL NZ, .sector_done
	LD	XWA, 00060000h		; 40 00 00 06 00
	db	078h, 0C4h, 000h	; JRL T, .erase_last_sector

.check_non_region4:
	; Check target 1 (Custom Data) for non-region-4
	db	08Fh, 00Ch, 03Fh, 001h	; CP (XSP+0Ch), 01h
	JR	NZ, .check_hdae		; 6e 6e - skip to HDAE handling

	; Custom Data (target 1) - check if AM29LV800B (0x2258)
	LDA	XWA, 00300000h		; f2 00 00 30 30
	db	0D2h, 094h, 099h, 000h, 03Fh, 058h, 022h	; CP (009994h), 2258h
	JR	NZ, .custom_check_f0000	; 6e 1c

	; AM29LV800B: Check if base sector needs boot block erase
	db	0AFh, 004h, 0F0h	; CP XWA, (XSP+04h)
	db	07Eh, 0B2h, 000h	; JRL NZ, .sector_done

	; Erase 8KB sectors at 0x4000 and 0x6000
	db	0F3h, 0F9h, 000h, 040h, 002h, 030h, 000h	; LD (XIZ+4000h), 0030h
	db	0F3h, 0F9h, 000h, 060h, 002h, 030h, 000h	; LD (XIZ+6000h), 0030h
	LD	XWA, 00008000h		; 40 00 80 00 00
	db	078h, 094h, 000h	; JRL T, .erase_last_sector

.custom_check_f0000:
	; Custom Data: Check 0x0F0000 sector
	LD	XBC, XWA		; e8 89
	ADD	XWA, 000F0000h		; e8 c8 00 00 0f 00
	db	0AFh, 004h, 0F0h	; CP XWA, (XSP+04h)
	db	07Eh, 08Eh, 000h	; JRL NZ, .sector_done

	; Erase boot block sectors at 0xF8000, 0xFA000, 0xFC000
	LD	XWA, XIZ		; ee 88
	ADD	XWA, 000F8000h		; e8 c8 00 80 0f 00
	db	0B0h, 002h, 030h, 000h	; LD (XWA), 0030h (word store)
	LD	XWA, XIZ		; ee 88
	ADD	XWA, 000FA000h		; e8 c8 00 a0 0f 00
	db	0B0h, 002h, 030h, 000h	; LD (XWA), 0030h (word store)
	LD	XWA, XIZ		; ee 88
	ADD	XWA, 000FC000h		; e8 c8 00 c0 0f 00
	db	0B0h, 002h, 030h, 000h	; LD (XWA), 0030h (word store)

	; Check if top sector
	ADD	XBC, 000FFFFFh		; e9 c8 ff ff 0f 00
	db	0AFh, 008h, 0F9h	; CP (XSP+08h), XBC
	JR	NZ, .sector_done	; 6e 5f
	LD	XWA, 000E0000h		; 40 00 00 0e 00
	JR	T, .erase_last_sector	; 68 50

.check_hdae:
	; HDAE5000 (target 0) - check if AM29F400B (0x22AB)
	LDA	XWA, 00280000h		; f2 00 00 28 30
	db	0D2h, 096h, 099h, 000h, 03Fh, 0ABh, 022h	; CP (009996h), 22ABh
	JR	NZ, .hdae_check_top	; 6e 1a

	; AM29F400B on HDAE: Check base sector
	db	0AFh, 004h, 0F0h	; CP XWA, (XSP+04h)
	JR	NZ, .sector_done	; 6e 45

	; Erase 8KB boot block sectors at 0x4000 and 0x6000
	db	0F3h, 0F9h, 000h, 040h, 002h, 030h, 000h	; LD (XIZ+4000h), 0030h
	db	0F3h, 0F9h, 000h, 060h, 002h, 030h, 000h	; LD (XIZ+6000h), 0030h
	LD	XWA, 00008000h		; 40 00 80 00 00
	JR	T, .erase_last_sector	; 68 28

.hdae_check_top:
	; HDAE: Check 0x070000 sector (XWA already = 0x280000)
	ADD	XWA, 00070000h		; e8 c8 00 00 07 00
	db	0AFh, 004h, 0F0h	; CP XWA, (XSP+04h)
	JR	NZ, .sector_done	; 6e 25

	; Erase boot block sectors at 0x78000, 0x7A000
	LD	XWA, XIZ		; ee 88
	ADD	XWA, 00078000h		; e8 c8 00 80 07 00
	db	0B0h, 002h, 030h, 000h	; LD (XWA), 0030h (word store)
	LD	XWA, XIZ		; ee 88
	ADD	XWA, 0007A000h		; e8 c8 00 a0 07 00
	db	0B0h, 002h, 030h, 000h	; LD (XWA), 0030h (word store)
	LD	XWA, 0007C000h		; 40 00 c0 07 00

.erase_last_sector:
	; Common code to erase the last 8KB sector
	; XWA = sector offset within bank
	LD	XBC, XIZ		; ee 89
	ADD	XBC, XWA		; e8 81
	db	0B1h, 002h, 030h, 000h	; LD (XBC), 0030h (word store)

.sector_done:
	EI	0			; 06 00
	POP	XIZ			; 5e
	db	0BFh, 00Ah, 037h	; LDA XSP, XSP+0Ah - deallocate stack
	RET				; 0e

; -----------------------------------------------------------------------------
; Flash_WaitComplete - Wait for flash operation to complete
; Address: 0x9FBBCF
;
; Purpose: Poll bit 5 of port 0x1C until flash operation completes
;
; Entry: None
; Exit: HL = 0 if success, 0xFFFF if still busy
; -----------------------------------------------------------------------------
Flash_WaitComplete:
	BIT	5, (01Ch)		; f0 1c cd
	JR	Z, .not_ready		; 66 03
	LD	HL, 0			; db a8
	RET				; 0e
.not_ready:
	LD	HL, 0FFFFh		; 33 ff ff
	RET				; 0e

; -----------------------------------------------------------------------------
; Flash_ChipErase_16bit_Wait - Erase chip and wait for completion
; Address: 0x9FBBDB
;
; Purpose: Call Flash_ChipErase_16bit and poll until complete
;
; Entry: A = target (0=HDAE5000, 1=Custom Data)
; Exit: None
; -----------------------------------------------------------------------------
Flash_ChipErase_16bit_Wait:
	EXTZ	WA			; d8 12
	db	01Eh, 088h, 0FDh	; CALR Flash_ChipErase_16bit (0x9FB968)
.wait_loop:
	db	01Eh, 0ECh, 0FFh	; CALR Flash_WaitComplete (0x9FBBCF)
	CP	HL, 0FFFFh		; db cf ff ff
	RET	NZ			; b0 fe
	db	01Eh, 0E3h, 0FFh	; CALR Flash_WaitComplete (0x9FBBCF)
	CP	HL, 0FFFFh		; db cf ff ff
	db	066h, 0F7h		; JR Z, .wait_loop (offset -9)
	RET				; 0e

; -----------------------------------------------------------------------------
; Flash_Init_Custom_And_Table - Initialize Custom Data and Table Data flash
; Address: 0x9FBBF3
;
; Purpose: Send reset to Custom Data flash and read IDs for both flashes
;
; Entry: None
; Exit: (0x9994) = Custom Data device ID
;       (0x9996) = HDAE5000 device ID
; -----------------------------------------------------------------------------
Flash_Init_Custom_And_Table:
	LD	WA, 1			; d8 a9 - Custom Data low bank
	db	01Eh, 01Ah, 0FCh	; CALR Flash_Reset_16bit (0x9FB812)
	LD	WA, 2			; d8 aa - Custom Data high bank
	db	01Eh, 015h, 0FCh	; CALR Flash_Reset_16bit (0x9FB812)

	; Check region and reset Table Data ROM if not region 4
	db	01Dh, 000h, 0B7h, 0FFh	; CALL Boot_Get_Region_Code (0xFFB700)
	CP	L, 4			; cf dc
	db	0F2h, 02Dh, 0BCh, 0FFh, 0EEh	; CALL NZ, Flash_Reset_32bit (0xFFBC2D)

	; Read Custom Data device ID
	LD	WA, 1			; d8 a9
	db	01Eh, 07Bh, 0FCh	; CALR Flash_ReadID_16bit (0x9FB888)
	db	0F2h, 094h, 099h, 000h, 053h	; LD (009994h), HL

	; Read HDAE5000 device ID
	LD	WA, 2			; d8 aa
	db	01Eh, 071h, 0FCh	; CALR Flash_ReadID_16bit (0x9FB888)
	db	0F2h, 096h, 099h, 000h, 053h	; LD (009996h), HL
	RET				; 0e

; -----------------------------------------------------------------------------
; ClearMemoryBlockWith0 - Clear a memory block with zeros
; Address: 0x9FBC1D
;
; Purpose: Fill memory from XWA for BC dwords with zeros
;
; Entry: XWA = destination address
;        BC = count (dwords)
; Exit: XWA = address after filled region
;       DE = BC (loop counter)
; -----------------------------------------------------------------------------
ClearMemoryBlockWith0:
	LD	DE, 0			; da a8
	CP	BC, 0			; d9 d8
	RET	ULE			; b0 f3 - return if count <= 0
.fill_loop:
	db	0F5h, 0E1h, 052h	; LD (XWA+), DE - store 0 and advance
	INC	1, DE			; da 61
	CP	DE, BC			; d9 f2
	JR	C, .fill_loop		; 67 f7
	RET				; 0e


; =============================================================================
; 32-BIT FLASH PROGRAMMING ROUTINES
; =============================================================================
; These routines operate on the interleaved Table Data ROM using 32-bit bus access.
; The ROM uses two interleaved 16-bit flash chips:
;   - IC1 (odd bytes) and IC3 (even bytes)
;
; Address Translation (16-bit -> 32-bit):
;   16-bit 0x5555 -> 32-bit 0x15554 (bit 16 set due to A16 routing)
;   16-bit 0x2AAA -> 32-bit 0x0AAA8
;
; Data values use 32-bit interleaved format:
;   16-bit 0xAA   -> 32-bit 0x00AA00AA (same byte to both chips)
;   16-bit 0x55   -> 32-bit 0x00550055
;   16-bit 0xF0   -> 32-bit 0x00F000F0
; =============================================================================

; -----------------------------------------------------------------------------
; Flash_Reset_32bit - Reset Table Data ROM flash chips
; Address: 0x9FBC2D (boot-time: 0xFFBC2D)
;
; Purpose: Send software reset command to both interleaved flash chips
;
; Entry: None
; Exit: XWA = data read from base+0x6464 (completion cycle)
;
; Sequence:
;   Write 0x00AA00AA to base+0x15554 (unlock 1)
;   Write 0x00550055 to base+0x0AAA8 (unlock 2)
;   Write 0x00F000F0 to base+0x15554 (reset command)
;   Read any address to complete cycle
; -----------------------------------------------------------------------------
Flash_Reset_32bit:
	LD	XDE, 00800000h			; Table Data ROM base address
.wait_ready:
	BIT	5, (01Ch)			; Wait for P3 bit 5 (flash ready)
	JR	Z, .wait_ready

	LD	XBC, XDE			; XBC = base
	ADD	XBC, 00015554h			; XBC = base + unlock addr 1
	LD	XWA, 00AA00AAh			; Unlock value 1 (both chips)
	LD	(XBC), XWA			; Write unlock

	LD	XBC, XDE			; Reset XBC
	ADD	XBC, 0000AAA8h			; XBC = base + unlock addr 2
	LD	XWA, 00550055h			; Unlock value 2 (both chips)
	LD	(XBC), XWA			; Write unlock

	LD	XBC, XDE			; Reset XBC
	ADD	XBC, 00015554h			; XBC = base + command addr
	LD	XWA, 00F000F0h			; Software reset command (both chips)
	LD	(XBC), XWA			; Send reset

	db	0E3h, 0E9h, 064h, 064h, 020h	; LD XWA, (XDE+6464h) - completion read
	RET

; -----------------------------------------------------------------------------
; Flash_ReadID_32bit - Read Table Data ROM flash IDs
; Address: 0x9FBC6A (boot-time: 0xFFBC6A)
;
; Purpose: Read manufacturer and device IDs from both flash chips
;
; Entry: None
; Exit: XHL = device ID if valid, 0xFFFFFFFF if not recognized
;
; Validated Device IDs:
;   0x22D622D6 - AM29F800B (both chips)
;   0x22582258 - AM29LV800B (both chips)
;
; Manufacturer IDs:
;   0x00010001 - AMD/Spansion (both chips)
;   0x00040004 - Fujitsu (both chips)
; -----------------------------------------------------------------------------
Flash_ReadID_32bit:
	db	0EFh, 068h			; DEC 0, XSP - allocate 8 bytes
	PUSH	XIZ				; Save XIZ

	LD	XWA, 0FFFFFFFFh			; Default: invalid
	db	0BFh, 008h, 060h		; LD (XSP+08h), XWA - save default

	EI	6				; Disable lower-priority interrupts

	; Send ID read command sequence
	LD	XWA, 00AA00AAh			; Unlock 1
	db	0F2h, 054h, 055h, 081h, 060h	; LD (815554h), XWA

	LD	XWA, 00550055h			; Unlock 2
	db	0F2h, 0A8h, 0AAh, 080h, 060h	; LD (80AAA8h), XWA

	LD	XWA, 00900090h			; ID read command
	db	0F2h, 054h, 055h, 081h, 060h	; LD (815554h), XWA

	; Read manufacturer ID from base address
	db	0E2h, 000h, 000h, 080h, 020h	; LD XWA, (800000h)
	db	0BFh, 004h, 060h		; LD (XSP+04h), XWA - save mfr ID

	; Read device ID from base+4
	LD	XWA, 00800000h
	db	0A8h, 004h, 026h		; LD XIZ, (XWA+04h)

	EI	0				; Re-enable interrupts

	; Validate manufacturer ID
	db	0AFh, 004h, 020h		; LD XWA, (XSP+04h) - get mfr ID
	CP	XWA, 00010001h			; AMD?
	JR	Z, .check_device
	CP	XWA, 00040004h			; Fujitsu?
	JR	NZ, .done

.check_device:
	CP	XIZ, 22D622D6h			; AM29F800B?
	JR	Z, .valid_device
	CP	XIZ, 22582258h			; AM29LV800B?
	JR	NZ, .call_reset

.valid_device:
	db	0BFh, 008h, 066h		; LD (XSP+08h), XIZ - store device ID

.call_reset:
	CALR	Flash_Reset_32bit		; Exit ID mode

.done:
	db	0AFh, 008h, 023h		; LD XHL, (XSP+08h) - return device ID
	POP	XIZ
	db	0EFh, 060h			; INC 0, XSP - deallocate 8 bytes
	RET

; -----------------------------------------------------------------------------
; Flash_ProgramWord_32bit - Program 32-bit word to Table Data ROM
; Address: 0x9FBCD7 (boot-time: 0xFFBCD7)
;
; Entry: XWA = destination address
;        XBC = data (32 bits, interleaved for both chips)
; Exit: None
;
; Notes:
;   - Skips programming if data = 0xFFFFFFFF (erased state)
;   - Writes unlock sequence, then 0xA0 program command
;   - Data is written directly to destination address
; -----------------------------------------------------------------------------
Flash_ProgramWord_32bit:
	db	0EFh, 06Ch			; DEC 4, XSP - allocate 4 bytes
	PUSH	XIZ				; Save XIZ

	LD	XIZ, XBC			; XIZ = data
	db	0BFh, 004h, 060h		; LD (XSP+04h), XWA - save dest addr

	CP	XIZ, 0FFFFFFFFh			; Is data erased state?
	JR	Z, .skip_program		; Yes, skip

.wait_ready:
	BIT	5, (01Ch)			; Wait for flash ready
	JR	Z, .wait_ready

	EI	6				; Disable lower-priority interrupts

	; Send program command sequence
	LD	XWA, 00AA00AAh			; Unlock 1
	db	0F2h, 054h, 055h, 081h, 060h	; LD (815554h), XWA

	LD	XWA, 00550055h			; Unlock 2
	db	0F2h, 0A8h, 0AAh, 080h, 060h	; LD (80AAA8h), XWA

	LD	XWA, 00A000A0h			; Program command
	db	0F2h, 054h, 055h, 081h, 060h	; LD (815554h), XWA

	; Write data to destination
	db	0AFh, 004h, 020h		; LD XWA, (XSP+04h) - get dest addr
	db	0B0h, 066h			; LD (XWA), XIZ - write data

	EI	0				; Re-enable interrupts

.skip_program:
	POP	XIZ
	db	0EFh, 064h			; INC 4, XSP - deallocate 4 bytes
	RET

; -----------------------------------------------------------------------------
; Flash_ChipErase_32bit - Erase Table Data ROM
; Address: 0x9FBD17 (boot-time: 0xFFBD17)
;
; Purpose: Erase entire Table Data ROM (both flash chips)
;
; Entry: None
; Exit: None
;
; Uses standard 6-byte chip erase sequence:
;   1. base+0x15554 = 0x00AA00AA (unlock 1)
;   2. base+0x0AAA8 = 0x00550055 (unlock 2)
;   3. base+0x15554 = 0x00800080 (erase setup)
;   4. base+0x15554 = 0x00AA00AA (unlock 1)
;   5. base+0x0AAA8 = 0x00550055 (unlock 2)
;   6. base+0x15554 = 0x00100010 (chip erase command)
; -----------------------------------------------------------------------------
Flash_ChipErase_32bit:
	PUSH	XIZ
	LD	XIZ, 00800000h			; Table Data ROM base

	EI	6				; Disable lower-priority interrupts

	; Unlock sequence 1
	LD	XBC, XIZ
	ADD	XBC, 00015554h
	LD	XWA, 00AA00AAh
	LD	(XBC), XWA

	; Unlock sequence 2
	LD	XBC, XIZ
	ADD	XBC, 0000AAA8h
	LD	XWA, 00550055h
	LD	(XBC), XWA

	; Erase setup command
	LD	XBC, XIZ
	ADD	XBC, 00015554h
	LD	XWA, 00800080h
	LD	(XBC), XWA

	; Unlock sequence 1 (again)
	LD	XBC, XIZ
	ADD	XBC, 00015554h
	LD	XWA, 00AA00AAh
	LD	(XBC), XWA

	; Unlock sequence 2 (again)
	LD	XBC, XIZ
	ADD	XBC, 0000AAA8h
	LD	XWA, 00550055h
	LD	(XBC), XWA

	; Chip erase command
	LD	XBC, XIZ
	ADD	XBC, 00015554h
	LD	XWA, 00100010h
	LD	(XBC), XWA

	EI	0				; Re-enable interrupts

	POP	XIZ
	RET

; -----------------------------------------------------------------------------
; Flash_SectorErase_32bit - Erase all Table Data ROM sectors
; Address: 0x9FBD7D (boot-time: 0xFFBD7D)
;
; Purpose: Erase all 18 sectors in the 2MB Table Data ROM
;          Uses sector erase (0x30) instead of chip erase (0x10)
;
; Entry: None
; Exit: None
;
; Sector layout (2MB = 32 x 64KB sectors in each interleaved chip):
;   0x00000, 0x20000, 0x40000, 0x60000, 0x80000, 0xA0000, 0xC0000, 0xE0000,
;   0x100000, 0x120000, 0x140000, 0x160000, 0x180000, 0x1A0000, 0x1C0000,
;   0x1E0000, 0x1F0000, 0x1F4000 (boot sectors at top)
; -----------------------------------------------------------------------------
Flash_SectorErase_32bit:
	PUSH	XIZ				; 3e
	LD	XIZ, 00800000h			; 46 00 00 80 00 - Table Data base
	EI	6				; 06 06 - disable lower-priority IRQs

	; Send erase setup sequence
	LD	XBC, XIZ			; ee 89
	ADD	XBC, 00015554h			; e9 c8 54 55 01 00
	LD	XWA, 00AA00AAh			; 40 aa 00 aa 00 - Unlock 1
	LD	(XBC), XWA			; b1 60

	LD	XBC, XIZ			; ee 89
	ADD	XBC, 0000AAA8h			; e9 c8 a8 aa 00 00
	LD	XWA, 00550055h			; 40 55 00 55 00 - Unlock 2
	LD	(XBC), XWA			; b1 60

	LD	XBC, XIZ			; ee 89
	ADD	XBC, 00015554h			; e9 c8 54 55 01 00
	LD	XWA, 00800080h			; 40 80 00 80 00 - Erase setup
	LD	(XBC), XWA			; b1 60

	LD	XBC, XIZ			; ee 89
	ADD	XBC, 00015554h			; e9 c8 54 55 01 00
	LD	XWA, 00AA00AAh			; 40 aa 00 aa 00 - Unlock 1
	LD	(XBC), XWA			; b1 60

	LD	XBC, XIZ			; ee 89
	ADD	XBC, 0000AAA8h			; e9 c8 a8 aa 00 00
	LD	XWA, 00550055h			; 40 55 00 55 00 - Unlock 2
	LD	(XBC), XWA			; b1 60

	; Now send 0x30 sector erase command to each sector
	LD	XWA, 00300030h			; 40 30 00 30 00 - Sector erase cmd
	LD	(XIZ), XWA			; b6 60 - Sector 0

	LD	XBC, XIZ			; ee 89
	ADD	XBC, 00020000h			; e9 c8 00 00 02 00
	LD	(XBC), XWA			; b1 60 - Sector 0x20000

	LD	XBC, XIZ			; ee 89
	ADD	XBC, 00040000h			; e9 c8 00 00 04 00
	LD	(XBC), XWA			; b1 60 - Sector 0x40000

	LD	XBC, XIZ			; ee 89
	ADD	XBC, 00060000h			; e9 c8 00 00 06 00
	LD	(XBC), XWA			; b1 60 - Sector 0x60000

	LD	XBC, XIZ			; ee 89
	ADD	XBC, 00080000h			; e9 c8 00 00 08 00
	LD	(XBC), XWA			; b1 60 - Sector 0x80000

	LD	XBC, XIZ			; ee 89
	ADD	XBC, 000A0000h			; e9 c8 00 00 0a 00
	LD	(XBC), XWA			; b1 60 - Sector 0xA0000

	LD	XBC, XIZ			; ee 89
	ADD	XBC, 000C0000h			; e9 c8 00 00 0c 00
	LD	(XBC), XWA			; b1 60 - Sector 0xC0000

	LD	XBC, XIZ			; ee 89
	ADD	XBC, 000E0000h			; e9 c8 00 00 0e 00
	LD	(XBC), XWA			; b1 60 - Sector 0xE0000

	LD	XBC, XIZ			; ee 89
	ADD	XBC, 00100000h			; e9 c8 00 00 10 00
	LD	(XBC), XWA			; b1 60 - Sector 0x100000

	LD	XBC, XIZ			; ee 89
	ADD	XBC, 00120000h			; e9 c8 00 00 12 00
	LD	(XBC), XWA			; b1 60 - Sector 0x120000

	LD	XBC, XIZ			; ee 89
	ADD	XBC, 00140000h			; e9 c8 00 00 14 00
	LD	(XBC), XWA			; b1 60 - Sector 0x140000

	LD	XBC, XIZ			; ee 89
	ADD	XBC, 00160000h			; e9 c8 00 00 16 00
	LD	(XBC), XWA			; b1 60 - Sector 0x160000

	LD	XBC, XIZ			; ee 89
	ADD	XBC, 00180000h			; e9 c8 00 00 18 00
	LD	(XBC), XWA			; b1 60 - Sector 0x180000

	LD	XBC, XIZ			; ee 89
	ADD	XBC, 001A0000h			; e9 c8 00 00 1a 00
	LD	(XBC), XWA			; b1 60 - Sector 0x1A0000

	LD	XBC, XIZ			; ee 89
	ADD	XBC, 001C0000h			; e9 c8 00 00 1c 00
	LD	(XBC), XWA			; b1 60 - Sector 0x1C0000

	LD	XBC, XIZ			; ee 89
	ADD	XBC, 001E0000h			; e9 c8 00 00 1e 00
	LD	(XBC), XWA			; b1 60 - Sector 0x1E0000

	LD	XBC, XIZ			; ee 89
	ADD	XBC, 001F0000h			; e9 c8 00 00 1f 00
	LD	(XBC), XWA			; b1 60 - Sector 0x1F0000 (boot area)

	LD	XBC, XIZ			; ee 89
	ADD	XBC, 001F4000h			; e9 c8 00 40 1f 00
	LD	(XBC), XWA			; b1 60 - Sector 0x1F4000 (boot area)

	EI	0				; 06 00 - re-enable interrupts
	POP	XIZ				; 5e
	RET					; 0e

; -----------------------------------------------------------------------------
; Flash_WaitComplete_32bit - Wait for flash operation to complete
; Address: 0x9FBE85 (boot-time: 0xFFBE85)
;
; Purpose: Poll bit 5 of port 0x1C until flash operation completes
;
; Entry: None
; Exit: HL = 0 if success, 0xFFFF if still busy
; -----------------------------------------------------------------------------
Flash_WaitComplete_32bit:
	BIT	5, (01Ch)			; f0 1c cd
	JR	Z, .not_ready			; 66 03
	LD	HL, 0				; db a8
	RET					; 0e
.not_ready:
	LD	HL, 0FFFFh			; 33 ff ff
	RET					; 0e

; -----------------------------------------------------------------------------
; Flash_ChipErase_32bit_Wait - Erase chip and wait for completion
; Address: 0x9FBE91 (boot-time: 0xFFBE91)
;
; Purpose: Call Flash_ChipErase_32bit and poll until complete
;
; Entry: None
; Exit: None
; -----------------------------------------------------------------------------
Flash_ChipErase_32bit_Wait:
	db	01Eh, 083h, 0FEh		; CALR Flash_ChipErase_32bit (0x9FBD17)
.wait_loop:
	db	01Eh, 0EEh, 0FFh		; CALR Flash_WaitComplete_32bit (0x9FBE85)
	CP	HL, 0FFFFh			; db cf ff ff
	RET	NZ				; b0 fe
	db	01Eh, 0E5h, 0FFh		; CALR Flash_WaitComplete_32bit (0x9FBE85)
	CP	HL, 0FFFFh			; db cf ff ff
	db	066h, 0F7h			; JR Z, .wait_loop (offset -9)
	RET					; 0e

; -----------------------------------------------------------------------------
; Flash_Update_TableData - Update Table Data ROM from RAM buffer
; Address: 0x9FBEA7 (boot-time: 0xFFBEA7)
;
; Purpose: High-level routine to update entire Table Data ROM
;
; Entry: Source data at RAM 0x080000 (8000 dwords = 32KB)
; Exit: HL = 0 if success, 0xFFFF if flash not detected
;
; Process:
;   1. Read flash device ID to verify hardware
;   2. Erase entire Table Data ROM
;   3. Copy 8000 dwords from RAM 0x080000 to flash 0x800000
;   4. Wait for completion
; -----------------------------------------------------------------------------
Flash_Update_TableData:
	db	0EFh, 06Ch			; DEC 4, XSP - allocate 4 bytes
	PUSH	XIZ				; 3e

	LD	XWA, 00080000h			; 40 00 00 08 00 - source RAM addr
	db	0BFh, 004h, 060h		; LD (XSP+04h), XWA - save src ptr

	; Verify flash is present by reading device ID
	db	01Eh, 0B5h, 0FDh		; CALR Flash_ReadID_32bit (0x9FBC6A)
	CP	XHL, 0FFFFFFFFh			; eb cf ff ff ff ff
	JR	NZ, .flash_detected		; 6e 05

	LD	HL, 0FFFFh			; 33 ff ff - error: no flash
	JR	T, .done			; 68 41

.flash_detected:
	; Erase Table Data ROM
	db	01Eh, 052h, 0FEh		; CALR Flash_ChipErase_32bit (0x9FBD17)

	; Initialize destination and count
	LD	XWA, 00080000h			; 40 00 00 08 00 - reinit src ptr
	LD	XBC, 00010000h			; 41 00 00 01 00 - count = 64K dwords
	db	01Dh, 01Dh, 0BCh, 0FFh		; CALL ClearMemoryBlockWith0 (0xFFBC1D)

	; Wait for erase to complete
.wait_erase:
	db	01Eh, 0AFh, 0FFh		; CALR Flash_WaitComplete_32bit (0x9FBE85)
	CP	HL, 0FFFFh			; db cf ff ff
	JR	NZ, .program_loop_start		; 6e 09
.wait_erase_loop:
	db	01Eh, 0A6h, 0FFh		; CALR Flash_WaitComplete_32bit (0x9FBE85)
	CP	HL, 0FFFFh			; db cf ff ff
	db	066h, 0F7h			; JR Z, .wait_erase_loop

.program_loop_start:
	LD	XIZ, 0				; ee a8 - dest offset counter

.program_loop:
	db	0AFh, 004h, 020h		; LD XWA, (XSP+04h) - get src ptr
	db	0F5h, 0E2h, 031h		; LDA XBC, XWA+ - load data, advance ptr
	db	0BFh, 004h, 060h		; LD (XSP+04h), XWA - save updated ptr

	LD	XWA, XBC			; e9 88 - XWA = data
	LD	XBC, XIZ			; ee 89 - XBC = dest offset
	db	01Eh, 0E0h, 0FDh		; CALR Flash_ProgramWord_32bit (0x9FBCD7)

	INC	1, XIZ				; ee 61 - next dword
	CP	XIZ, 00001F40h			; ee cf 40 1f 00 00 - 8000 dwords
	JR	C, .program_loop		; 67 e6

	LD	HL, 0				; db a8 - success
.done:
	POP	XIZ				; 5e
	db	0EFh, 064h			; INC 4, XSP - deallocate 4 bytes
	RET					; 0e

; =============================================================================
; BOOT ROM FDC ROUTINES
; =============================================================================
; FDC routines for reading firmware update data from floppy disk during
; boot-time recovery mode.
; =============================================================================

; -----------------------------------------------------------------------------
; FDC_Reset - Initialize FDC controller for update mode
; Address: 0x9FBF07 (boot-time: 0xFFBF07)
;
; Purpose: Set up FDC parameters for reading update disks
;
; Stack frame (16 bytes at XSP):
;   +0x00: Drive number (0)
;   +0x02: Reserved (0)
;   +0x04: Reserved (0)
;   +0x06: Data rate (0x00D3 = 500kbps HD)
;   +0x08: Sectors per track (1)
;   +0x0A: Heads (1)
;   +0x0C: Reserved (0)
;
; Entry: None
; Exit: FDC initialized
; -----------------------------------------------------------------------------
FDC_Reset:
	db	0BFh, 0F0h, 037h		; LDA XSP, XSP+F0h - allocate 16 bytes
	db	0B7h, 031h			; LDA XBC, XSP - XBC points to params
	db	0B1h, 002h, 000h, 000h		; LD (XBC), 0000h - drive 0
	db	0B9h, 002h, 002h, 000h, 000h	; LD (XBC+02h), 0000h
	db	0B9h, 004h, 002h, 000h, 000h	; LD (XBC+04h), 0000h
	db	0B9h, 006h, 002h, 0D3h, 000h	; LD (XBC+06h), 00D3h - data rate
	db	0B9h, 008h, 002h, 001h, 000h	; LD (XBC+08h), 0001h - sectors/track
	db	0B9h, 00Ah, 002h, 001h, 000h	; LD (XBC+0Ah), 0001h - heads
	LD	XWA, 0				; e8 a8
	db	0B9h, 00Ch, 060h		; LD (XBC+0Ch), XWA
	PUSH	XBC				; 39
	db	01Dh, 044h, 0E9h, 0FFh		; CALL 0xFFE944 (FDC_Init)
	db	0BFh, 014h, 037h		; LDA XSP, XSP+14h - deallocate 20 bytes
	RET					; 0e

; -----------------------------------------------------------------------------
; FDC_ReadSector - Read a single sector from floppy
; Address: 0x9FBF37 (boot-time: 0xFFBF37)
;
; Entry: XWA = sector info (passed to FDC driver)
;        BC = sector number
;        XDE = destination buffer
;
; Exit: HL = result (0 = success)
;
; Calculates head/track from linear sector number:
;   Track = sector_number >> 1
;   Head = sector_number & 1
;
; Uses FDC parameters at RAM 0x0C10
; -----------------------------------------------------------------------------
FDC_ReadSector:
	db	0BFh, 0F2h, 037h		; LDA XSP, XSP+F2h - allocate 14 bytes
	PUSH	XIZ				; 3e
	db	0BFh, 008h, 062h		; LD (XSP+08h), XDE - save dest buffer
	db	0BFh, 00Ch, 051h		; LD (XSP+0Ch), BC - save sector num
	db	0BFh, 00Eh, 060h		; LD (XSP+0Eh), XWA - save sector info
	db	0AFh, 00Eh, 020h		; LD XWA, (XSP+0Eh)
	LD	XBC, 000000012h			; 41 12 00 00 00 - param size
	db	01Dh, 063h, 0FCh, 0FFh		; CALL 0xFFFC63
	db	0F1h, 010h, 00Ch, 036h		; LDA XIZ, 0x0C10 - FDC params in RAM
	db	0BEh, 002h, 002h, 000h, 000h	; LD (XIZ+02h), 0000h
	db	0DBh, 088h			; LD WA, HL
	db	0D8h, 0EFh, 001h		; SRL 1, WA - track = sector >> 1
	db	0BEh, 006h, 050h		; LD (XIZ+06h), WA - store track
	db	0DBh, 0CCh, 001h, 000h		; AND HL, 0001h - head = sector & 1
	db	0BEh, 004h, 053h		; LD (XIZ+04h), HL - store head
	db	0BEh, 008h, 030h		; LDA XWA, (XIZ+08h)
	db	0BFh, 004h, 060h		; LD (XSP+04h), XWA
	db	0AFh, 00Eh, 020h		; LD XWA, (XSP+0Eh)
	LD	XBC, 000000012h			; 41 12 00 00 00
	db	01Dh, 05Dh, 0FCh, 0FFh		; CALL 0xFFFC5D
	db	0EBh, 061h			; INC 1, XHL
	db	0AFh, 004h, 020h		; LD XWA, (XSP+04h)
	db	0B0h, 053h			; LD (XWA), HL
	db	09Fh, 00Ch, 020h		; LD WA, (XSP+0Ch) - sector num
	db	0BEh, 00Ah, 050h		; LD (XIZ+0Ah), WA
	db	0AFh, 008h, 020h		; LD XWA, (XSP+08h) - dest buffer
	db	0BEh, 00Ch, 060h		; LD (XIZ+0Ch), XWA
	POP	XIZ				; 5e
	db	0BFh, 00Eh, 037h		; LDA XSP, XSP+0Eh - deallocate
	RET					; 0e

; -----------------------------------------------------------------------------
; FDC_ReadSectorWrapper - Wrapper for sector read with retry
; Address: 0x9FBF92 (boot-time: 0xFFBF92)
;
; Entry: XWA = sector info
;        BC = sector number
;        XDE = destination buffer
;
; Exit: HL = result
; -----------------------------------------------------------------------------
FDC_ReadSectorWrapper:
	db	0EFh, 06Eh			; DEC 6, XSP - allocate 6 bytes
	PUSH	XIZ				; 3e
	db	0BFh, 004h, 062h		; LD (XSP+04h), XDE
	db	0BFh, 008h, 051h		; LD (XSP+08h), BC
	LD	XIZ, XWA			; e8 8e - save sector info
	LD	XWA, XIZ			; ee 88
	db	09Fh, 008h, 021h		; LD BC, (XSP+08h)
	db	0AFh, 004h, 022h		; LD XDE, (XSP+04h)
	db	01Eh, 08Fh, 0FFh		; CALR FDC_ReadSector
	db	0F1h, 010h, 00Ch, 030h		; LDA XWA, 0x0C10
	db	0B0h, 002h, 003h, 000h		; LD (XWA), 0003h
	PUSH	XWA				; 38
	db	01Dh, 044h, 0E9h, 0FFh		; CALL 0xFFE944
	db	0EFh, 064h			; INC 4, XSP - deallocate
	db	0DBh, 0D8h			; CP HL, 0
	JR	Z, .read_ok			; 66 05 - skip retry if success

	; Read failed, try FDC reset and retry
	db	01Eh, 049h, 0FFh		; CALR FDC_Reset (0x9FBF07)
	db	068h, 0DDh			; JR T, .-35 - retry from start

.read_ok:
	POP	XIZ				; 5e
	db	0EFh, 066h			; INC 6, XSP - deallocate
	RET					; 0e

; -----------------------------------------------------------------------------
; Boot_DetectDiskType - Detect firmware update disk type
; Address: 0x9FBFC4 (boot-time: 0xFFBFC4)
;
; Purpose: Read boot sector and check for known disk signatures at various
;          offsets to determine the disk type (1-8) or unknown (0xFF)
;
; Signature offsets checked:
;   0xA000 -> type 1    0xA0A0 -> type 4    0xA118 -> type 6
;   0xA028 -> type 2    0xA0F0 -> type 5    0xA050 -> type 7
;   0xA078 -> type 3    0xA0C8 -> type 8
;
; Entry: None
; Exit: L = disk type (1-8) or 0xFF if unknown
; -----------------------------------------------------------------------------
Boot_DetectDiskType:
	db	0EFh, 06Ah			; DEC 2, XSP - allocate 2 bytes
	PUSH	XIZ				; 3e
	db	0BFh, 004h, 000h, 0FFh		; LD (XSP+04h), 0xFF - default type
	db	00Bh, 000h, 002h		; PUSH 0200h - sector size
	db	01Dh, 056h, 0FBh, 0FFh		; CALL 0xFFFB56 - allocate buffer
	db	0EFh, 062h			; INC 2, XSP - pop arg
	db	0EBh, 08Eh			; LD XIZ, XHL - save buffer ptr
	LD	XWA, 000000021h			; 40 21 00 00 00 - sector 33 (boot sector)
	db	0D9h, 0A9h			; LD BC, 1 - read 1 sector
	LD	XDE, XIZ			; ee 8a - dest buffer
	db	01Eh, 0B0h, 0FFh		; CALR FDC_ReadSectorWrapper

	; Check signature at offset 0xA000 -> type 1
	db	00Bh, 026h, 000h		; PUSH 0026h - signature length
	db	00Bh, 0FFh, 000h		; PUSH 00FFh - ???
	db	00Bh, 000h, 0A0h		; PUSH 0A000h - offset
	PUSH	XIZ				; 3e - buffer ptr
	db	01Dh, 0DCh, 0FBh, 0FFh		; CALL 0xFFFBDC - check signature
	db	0EFh, 0C8h, 00Ah, 000h, 000h, 000h	; ADD XSP, 0Ah - pop 10 bytes
	db	0DBh, 0D8h			; CP HL, 0
	JR	NZ, .check_type2		; 6e 07
	db	0BFh, 004h, 000h, 001h		; LD (XSP+04h), 01h - type 1
	db	078h, 0D2h, 000h		; JRL T, .done

.check_type2:
	db	00Bh, 026h, 000h		; PUSH 0026h
	db	00Bh, 0FFh, 000h		; PUSH 00FFh
	db	00Bh, 028h, 0A0h		; PUSH 0A028h - offset
	PUSH	XIZ				; 3e
	db	01Dh, 0DCh, 0FBh, 0FFh		; CALL 0xFFFBDC
	db	0EFh, 0C8h, 00Ah, 000h, 000h, 000h	; ADD XSP, 0Ah
	db	0DBh, 0D8h			; CP HL, 0
	JR	NZ, .check_type3		; 6e 07
	db	0BFh, 004h, 000h, 002h		; LD (XSP+04h), 02h - type 2
	db	078h, 0B3h, 000h		; JRL T, .done

.check_type3:
	db	00Bh, 026h, 000h		; PUSH 0026h
	db	00Bh, 0FFh, 000h		; PUSH 00FFh
	db	00Bh, 078h, 0A0h		; PUSH 0A078h - offset
	PUSH	XIZ				; 3e
	db	01Dh, 0DCh, 0FBh, 0FFh		; CALL 0xFFFBDC
	db	0EFh, 0C8h, 00Ah, 000h, 000h, 000h	; ADD XSP, 0Ah
	db	0DBh, 0D8h			; CP HL, 0
	JR	NZ, .check_type4		; 6e 07
	db	0BFh, 004h, 000h, 003h		; LD (XSP+04h), 03h - type 3
	db	078h, 094h, 000h		; JRL T, .done

.check_type4:
	db	00Bh, 026h, 000h		; PUSH 0026h
	db	00Bh, 0FFh, 000h		; PUSH 00FFh
	db	00Bh, 0A0h, 0A0h		; PUSH 0A0A0h - offset
	PUSH	XIZ				; 3e
	db	01Dh, 0DCh, 0FBh, 0FFh		; CALL 0xFFFBDC
	db	0EFh, 0C8h, 00Ah, 000h, 000h, 000h	; ADD XSP, 0Ah
	db	0DBh, 0D8h			; CP HL, 0
	JR	NZ, .check_type5		; 6e 06
	db	0BFh, 004h, 000h, 004h		; LD (XSP+04h), 04h - type 4
	db	068h, 076h			; JR T, .done

.check_type5:
	db	00Bh, 026h, 000h		; PUSH 0026h
	db	00Bh, 0FFh, 000h		; PUSH 00FFh
	db	00Bh, 0F0h, 0A0h		; PUSH 0A0F0h - offset
	PUSH	XIZ				; 3e
	db	01Dh, 0DCh, 0FBh, 0FFh		; CALL 0xFFFBDC
	db	0EFh, 0C8h, 00Ah, 000h, 000h, 000h	; ADD XSP, 0Ah
	db	0DBh, 0D8h			; CP HL, 0
	JR	NZ, .check_type6		; 6e 06
	db	0BFh, 004h, 000h, 005h		; LD (XSP+04h), 05h - type 5
	db	068h, 058h			; JR T, .done

.check_type6:
	db	00Bh, 026h, 000h		; PUSH 0026h
	db	00Bh, 0FFh, 000h		; PUSH 00FFh
	db	00Bh, 018h, 0A1h		; PUSH 0A118h - offset
	PUSH	XIZ				; 3e
	db	01Dh, 0DCh, 0FBh, 0FFh		; CALL 0xFFFBDC
	db	0EFh, 0C8h, 00Ah, 000h, 000h, 000h	; ADD XSP, 0Ah
	db	0DBh, 0D8h			; CP HL, 0
	JR	NZ, .check_type7		; 6e 06
	db	0BFh, 004h, 000h, 006h		; LD (XSP+04h), 06h - type 6
	db	068h, 03Ah			; JR T, .done

.check_type7:
	db	00Bh, 026h, 000h		; PUSH 0026h
	db	00Bh, 0FFh, 000h		; PUSH 00FFh
	db	00Bh, 050h, 0A0h		; PUSH 0A050h - offset
	PUSH	XIZ				; 3e
	db	01Dh, 0DCh, 0FBh, 0FFh		; CALL 0xFFFBDC
	db	0EFh, 0C8h, 00Ah, 000h, 000h, 000h	; ADD XSP, 0Ah
	db	0DBh, 0D8h			; CP HL, 0
	JR	NZ, .check_type8		; 6e 06
	db	0BFh, 004h, 000h, 007h		; LD (XSP+04h), 07h - type 7
	db	068h, 01Ch			; JR T, .done

.check_type8:
	db	00Bh, 026h, 000h		; PUSH 0026h
	db	00Bh, 0FFh, 000h		; PUSH 00FFh
	db	00Bh, 0C8h, 0A0h		; PUSH 0A0C8h - offset
	PUSH	XIZ				; 3e
	db	01Dh, 0DCh, 0FBh, 0FFh		; CALL 0xFFFBDC
	db	0EFh, 0C8h, 00Ah, 000h, 000h, 000h	; ADD XSP, 0Ah
	db	0DBh, 0D8h			; CP HL, 0
	JR	NZ, .done			; 6e 04
	db	0BFh, 004h, 000h, 008h		; LD (XSP+04h), 08h - type 8

.done:
	PUSH	XIZ				; 3e - free buffer
	db	01Dh, 0DDh, 0FCh, 0FFh		; CALL 0xFFFCDD - free memory
	db	0EFh, 064h			; INC 4, XSP
	db	08Fh, 004h, 027h		; LD L, (XSP+04h) - return type
	POP	XIZ				; 5e
	db	0EFh, 062h			; INC 2, XSP - deallocate
	RET					; 0e

; =============================================================================
; BOOT SECTOR COPY ROUTINES (0x9FC0E1-0x9FC212)
; =============================================================================
; Boot_CopySectors - Copy sectors from disk to RAM with callback
; Parameters:
;   XBC = destination address pointer (address table)
;   WA  = starting sector number
; Calls 0xFFBF92 to read sector, 0xFFBCD7 to write with callback
; =============================================================================

Boot_CopySectors:
	db	0BFh, 0F0h, 037h		; LDA XSP, XSP+0xF0 - allocate 16 bytes
	PUSH	XIZ				; 3e
	db	0BFh, 00Eh, 061h		; LD (XSP+0x0E), XBC - save dest ptr
	db	0BFh, 012h, 050h		; LD (XSP+0x12), WA - save start sector
	db	09Fh, 012h, 020h		; LD WA, (XSP+0x12)
	db	0BFh, 006h, 050h		; LD (XSP+0x06), WA - current sector
	db	09Fh, 006h, 020h		; LD WA, (XSP+0x06)
	db	0E8h, 012h			; EXTZ XWA
	db	0D8h, 00Ah, 012h, 000h		; DIV WA, 0x0012 - sectors per track
	db	0D7h, 0E2h, 088h		; LD WA, QWA - get remainder
	db	0DEh, 0A8h			; LD IZ, 0 - offset = 0
	db	0D8h, 0D8h			; CP WA, 0
	JR	Z, .cs_skip_partial		; 66 48

	; Handle partial first track
	db	036h, 012h, 000h		; LD IZ, 0x0012 - sectors per track
	db	0D8h, 0A6h			; SUB IZ, WA - IZ = 18 - remainder
	db	09Fh, 006h, 020h		; LD WA, (XSP+0x06)
	db	0E8h, 012h			; EXTZ XWA
	db	0DEh, 089h			; LD BC, IZ - sectors to read
	db	042h, 0A4h, 099h, 000h, 000h	; LD XDE, 0x000099A4 - buffer
	db	01Eh, 07Bh, 0FEh		; CALR 0x9FBF92 (FDC_ReadSectorRange)
	db	0F2h, 0A4h, 099h, 000h, 030h	; LDA XWA, 0x0099A4
	db	0BFh, 00Ah, 060h		; LD (XSP+0x0A), XWA - source ptr
	db	0D7h, 0FAh, 0A8h		; LD QIZ, 0 - counter

	; Loop: write partial track bytes
	JR	T, .cs_partial_check		; 68 1b
.cs_partial_loop:
	db	0AFh, 00Eh, 020h		; LD XWA, (XSP+0x0E) - dest table ptr
	db	0F5h, 0E2h, 031h		; LDA XBC, XWA+ - get dest addr
	db	0BFh, 00Eh, 060h		; LD (XSP+0x0E), XWA
	db	0E9h, 088h			; LD XWA, XBC
	db	0AFh, 00Ah, 022h		; LD XDE, (XSP+0x0A) - source ptr
	db	0E5h, 0EAh, 021h		; LD XBC, (XDE+) - get callback addr
	db	0BFh, 00Ah, 062h		; LD (XSP+0x0A), XDE
	db	01Dh, 0D7h, 0BCh, 0FFh		; CALL 0xFFBCD7 - write with callback
	db	0D7h, 0FAh, 061h		; INC 1, QIZ
.cs_partial_check:
	db	0DEh, 089h			; LD BC, IZ
	db	0D9h, 0ECh, 007h		; SLA 7, BC - BC = IZ * 128
	db	0D7h, 0FAh, 088h		; LD WA, QIZ
	db	0D9h, 0F0h			; CP WA, BC
	JR	C, .cs_partial_loop		; 67 d9

.cs_skip_partial:
	db	09Fh, 006h, 08Eh		; ADD (XSP+0x06), IZ - advance sector
	db	0BFh, 008h, 002h, 000h, 008h	; LD (XSP+0x08), 0x0800 - total size
	db	09Fh, 008h, 0AEh		; SUB (XSP+0x08), IZ
	db	09Fh, 008h, 020h		; LD WA, (XSP+0x08)
	db	0E8h, 013h			; EXTS XWA
	db	0D8h, 00Bh, 012h, 000h		; DIVS WA, 0x0012 - full tracks
	db	0BFh, 008h, 050h		; LD (XSP+0x08), WA - track count
	db	0BFh, 004h, 002h, 000h, 000h	; LD (XSP+0x04), 0x0000 - counter
	db	09Fh, 008h, 020h		; LD WA, (XSP+0x08)
	db	0D8h, 0D8h			; CP WA, 0
	JR	ULE, .cs_check_remainder	; 63 4d

.cs_track_loop:
	db	09Fh, 006h, 020h		; LD WA, (XSP+0x06)
	db	0E8h, 012h			; EXTZ XWA
	db	031h, 012h, 000h		; LD BC, 0x0012 - full track
	db	042h, 0A4h, 099h, 000h, 000h	; LD XDE, 0x000099A4
	db	01Eh, 014h, 0FEh		; CALR 0x9FBF92
	db	09Fh, 006h, 038h, 012h, 000h	; ADD (XSP+0x06), 0x0012
	db	0F2h, 0A4h, 099h, 000h, 030h	; LDA XWA, 0x0099A4
	db	0BFh, 00Ah, 060h		; LD (XSP+0x0A), XWA
	db	0D7h, 0FAh, 0A8h		; LD QIZ, 0

.cs_full_loop:
	db	0AFh, 00Eh, 020h		; LD XWA, (XSP+0x0E)
	db	0F5h, 0E2h, 031h		; LDA XBC, XWA+
	db	0BFh, 00Eh, 060h		; LD (XSP+0x0E), XWA
	db	0E9h, 088h			; LD XWA, XBC
	db	0AFh, 00Ah, 022h		; LD XDE, (XSP+0x0A)
	db	0E5h, 0EAh, 021h		; LD XBC, (XDE+)
	db	0BFh, 00Ah, 062h		; LD (XSP+0x0A), XDE
	db	01Dh, 0D7h, 0BCh, 0FFh		; CALL 0xFFBCD7
	db	0D7h, 0FAh, 061h		; INC 1, QIZ
	db	0D7h, 0FAh, 0CFh, 000h, 009h	; CP QIZ, 0x0900 (18*128)
	JR	C, .cs_full_loop		; 67 de
	db	09Fh, 004h, 061h		; INCW 1, (XSP+0x04)
	db	09Fh, 008h, 020h		; LD WA, (XSP+0x08)
	db	09Fh, 004h, 0F8h		; CP (XSP+0x04), WA
	JR	C, .cs_track_loop		; 67 b3

.cs_check_remainder:
	db	09Fh, 012h, 020h		; LD WA, (XSP+0x12)
	db	0D8h, 0C8h, 000h, 008h		; ADD WA, 0x0800
	db	09Fh, 006h, 0A0h		; SUB WA, (XSP+0x06)
	db	0D8h, 08Eh			; LD IZ, WA
	db	0DEh, 0D8h			; CP IZ, 0
	JR	Z, .cs_done			; 66 43

	; Read remainder
	db	09Fh, 006h, 020h		; LD WA, (XSP+0x06)
	db	0E8h, 012h			; EXTZ XWA
	db	0DEh, 089h			; LD BC, IZ
	db	042h, 0A4h, 099h, 000h, 000h	; LD XDE, 0x000099A4
	db	01Eh, 0B8h, 0FDh		; CALR 0x9FBF92
	db	0F2h, 0A4h, 099h, 000h, 030h	; LDA XWA, 0x0099A4
	db	0BFh, 00Ah, 060h		; LD (XSP+0x0A), XWA
	db	0D7h, 0FAh, 0A8h		; LD QIZ, 0
	JR	T, .cs_rem_check		; 68 1b

.cs_rem_loop:
	db	0AFh, 00Eh, 020h		; LD XWA, (XSP+0x0E)
	db	0F5h, 0E2h, 031h		; LDA XBC, XWA+
	db	0BFh, 00Eh, 060h		; LD (XSP+0x0E), XWA
	db	0E9h, 088h			; LD XWA, XBC
	db	0AFh, 00Ah, 022h		; LD XDE, (XSP+0x0A)
	db	0E5h, 0EAh, 021h		; LD XBC, (XDE+)
	db	0BFh, 00Ah, 062h		; LD (XSP+0x0A), XDE
	db	01Dh, 0D7h, 0BCh, 0FFh		; CALL 0xFFBCD7
	db	0D7h, 0FAh, 061h		; INC 1, QIZ
.cs_rem_check:
	db	0DEh, 089h			; LD BC, IZ
	db	0D9h, 0ECh, 007h		; SLA 7, BC
	db	0D7h, 0FAh, 088h		; LD WA, QIZ
	db	0D9h, 0F0h			; CP WA, BC
	JR	C, .cs_rem_loop			; 67 d9

.cs_done:
	POP	XIZ				; 5e
	db	0BFh, 010h, 037h		; LDA XSP, XSP+0x10
	RET					; 0e

; =============================================================================
; Boot_CopySectorsEx - Extended sector copy with byte write
; Address: 0x9FC213
; Parameters: XDE=dest table, BC=start sector, A=bank number
; Calls 0xFFB903 (Flash_ProgramWord_16bit) instead of 0xFFBCD7
; =============================================================================
Boot_CopySectorsEx:
	db	0BFh, 0EEh, 037h		; LDA XSP, XSP+0xEE - allocate 18 bytes
	PUSH	XIZ				; 3e
	db	0BFh, 00Eh, 062h		; LD (XSP+0x0E), XDE - dest table
	db	0BFh, 012h, 051h		; LD (XSP+0x12), BC - start sector
	db	0BFh, 014h, 041h		; LD (XSP+0x14), A - bank number
	db	09Fh, 012h, 020h		; LD WA, (XSP+0x12)
	db	0BFh, 006h, 050h		; LD (XSP+0x06), WA
	db	09Fh, 006h, 020h		; LD WA, (XSP+0x06)
	db	0E8h, 012h			; EXTZ XWA
	db	0D8h, 00Ah, 012h, 000h		; DIV WA, 0x0012
	db	0D7h, 0E2h, 088h		; LD WA, QWA
	db	0DEh, 0A8h			; LD IZ, 0
	db	0D8h, 0D8h			; CP WA, 0
	JR	Z, .cse_skip_partial		; 66 4d

	db	036h, 012h, 000h		; LD IZ, 0x0012
	db	0D8h, 0A6h			; SUB IZ, WA
	db	09Fh, 006h, 020h		; LD WA, (XSP+0x06)
	db	0E8h, 012h			; EXTZ XWA
	db	0DEh, 089h			; LD BC, IZ
	db	042h, 0A4h, 099h, 000h, 000h	; LD XDE, 0x000099A4
	db	01Eh, 046h, 0FDh		; CALR 0x9FBF92
	db	0F2h, 0A4h, 099h, 000h, 030h	; LDA XWA, 0x0099A4
	db	0BFh, 00Ah, 060h		; LD (XSP+0x0A), XWA
	db	0D7h, 0FAh, 0A8h		; LD QIZ, 0
	JR	T, .cse_partial_check		; 68 20

.cse_partial_loop:
	db	08Fh, 014h, 021h		; LD A, (XSP+0x14) - bank
	db	0D8h, 012h			; EXTZ WA
	db	0AFh, 00Eh, 021h		; LD XBC, (XSP+0x0E)
	db	0F5h, 0E5h, 032h		; LDA XDE, XBC+
	db	0BFh, 00Eh, 061h		; LD (XSP+0x0E), XBC
	db	0EAh, 089h			; LD XBC, XDE
	db	0AFh, 00Ah, 023h		; LD XHL, (XSP+0x0A)
	db	0D5h, 0EDh, 022h		; LD DE, (XHL+)
	db	0BFh, 00Ah, 063h		; LD (XSP+0x0A), XHL
	db	01Dh, 003h, 0B9h, 0FFh		; CALL 0xFFB903 (Flash_ProgramWord_16bit)
	db	0D7h, 0FAh, 061h		; INC 1, QIZ
.cse_partial_check:
	db	0DEh, 089h			; LD BC, IZ
	db	0D9h, 0ECh, 008h		; SLA 8, BC - BC = IZ * 256
	db	0D7h, 0FAh, 088h		; LD WA, QIZ
	db	0D9h, 0F0h			; CP WA, BC
	JR	C, .cse_partial_loop		; 67 d4

.cse_skip_partial:
	db	09Fh, 006h, 08Eh		; ADD (XSP+0x06), IZ
	db	0DEh, 088h			; LD WA, IZ
	db	09Fh, 01Ah, 021h		; LD BC, (XSP+0x1A) - total size
	db	0D8h, 0A1h			; SUB BC, WA
	db	0E9h, 012h			; EXTZ XBC
	db	0D9h, 00Ah, 012h, 000h		; DIV BC, 0x0012
	db	0BFh, 008h, 051h		; LD (XSP+0x08), BC
	db	0BFh, 004h, 002h, 000h, 000h	; LD (XSP+0x04), 0x0000
	db	09Fh, 008h, 020h		; LD WA, (XSP+0x08)
	db	0D8h, 0D8h			; CP WA, 0
	JR	ULE, .cse_check_rem		; 63 52

.cse_track_loop:
	db	09Fh, 006h, 020h		; LD WA, (XSP+0x06)
	db	0E8h, 012h			; EXTZ XWA
	db	031h, 012h, 000h		; LD BC, 0x0012
	db	042h, 0A4h, 099h, 000h, 000h	; LD XDE, 0x000099A4
	db	01Eh, 0DEh, 0FCh		; CALR 0x9FBF92
	db	09Fh, 006h, 038h, 012h, 000h	; ADD (XSP+0x06), 0x0012
	db	0F2h, 0A4h, 099h, 000h, 030h	; LDA XWA, 0x0099A4
	db	0BFh, 00Ah, 060h		; LD (XSP+0x0A), XWA
	db	0D7h, 0FAh, 0A8h		; LD QIZ, 0

.cse_full_loop:
	db	08Fh, 014h, 021h		; LD A, (XSP+0x14)
	db	0D8h, 012h			; EXTZ WA
	db	0AFh, 00Eh, 021h		; LD XBC, (XSP+0x0E)
	db	0F5h, 0E5h, 032h		; LDA XDE, XBC+
	db	0BFh, 00Eh, 061h		; LD (XSP+0x0E), XBC
	db	0EAh, 089h			; LD XBC, XDE
	db	0AFh, 00Ah, 023h		; LD XHL, (XSP+0x0A)
	db	0D5h, 0EDh, 022h		; LD DE, (XHL+)
	db	0BFh, 00Ah, 063h		; LD (XSP+0x0A), XHL
	db	01Dh, 003h, 0B9h, 0FFh		; CALL 0xFFB903
	db	0D7h, 0FAh, 061h		; INC 1, QIZ
	db	0D7h, 0FAh, 0CFh, 000h, 012h	; CP QIZ, 0x1200 (18*256)
	JR	C, .cse_full_loop		; 67 d9
	db	09Fh, 004h, 061h		; INCW 1, (XSP+0x04)
	db	09Fh, 008h, 020h		; LD WA, (XSP+0x08)
	db	09Fh, 004h, 0F8h		; CP (XSP+0x04), WA
	JR	C, .cse_track_loop		; 67 ae

.cse_check_rem:
	db	09Fh, 012h, 020h		; LD WA, (XSP+0x12)
	db	09Fh, 01Ah, 080h		; ADD WA, (XSP+0x1A)
	db	09Fh, 006h, 0A0h		; SUB WA, (XSP+0x06)
	db	0D8h, 08Eh			; LD IZ, WA
	db	0DEh, 0D8h			; CP IZ, 0
	JR	Z, .cse_done			; 66 48

	db	09Fh, 006h, 020h		; LD WA, (XSP+0x06)
	db	0E8h, 012h			; EXTZ XWA
	db	0DEh, 089h			; LD BC, IZ
	db	042h, 0A4h, 099h, 000h, 000h	; LD XDE, 0x000099A4
	db	01Eh, 07Eh, 0FCh		; CALR 0x9FBF92
	db	0F2h, 0A4h, 099h, 000h, 030h	; LDA XWA, 0x0099A4
	db	0BFh, 00Ah, 060h		; LD (XSP+0x0A), XWA
	db	0D7h, 0FAh, 0A8h		; LD QIZ, 0
	JR	T, .cse_rem_check		; 68 20

.cse_rem_loop:
	db	08Fh, 014h, 021h		; LD A, (XSP+0x14)
	db	0D8h, 012h			; EXTZ WA
	db	0AFh, 00Eh, 021h		; LD XBC, (XSP+0x0E)
	db	0F5h, 0E5h, 032h		; LDA XDE, XBC+
	db	0BFh, 00Eh, 061h		; LD (XSP+0x0E), XBC
	db	0EAh, 089h			; LD XBC, XDE
	db	0AFh, 00Ah, 023h		; LD XHL, (XSP+0x0A)
	db	0D5h, 0EDh, 022h		; LD DE, (XHL+)
	db	0BFh, 00Ah, 063h		; LD (XSP+0x0A), XHL
	db	01Dh, 003h, 0B9h, 0FFh		; CALL 0xFFB903
	db	0D7h, 0FAh, 061h		; INC 1, QIZ
.cse_rem_check:
	db	0DEh, 089h			; LD BC, IZ
	db	0D9h, 0ECh, 008h		; SLA 8, BC
	db	0D7h, 0FAh, 088h		; LD WA, QIZ
	db	0D9h, 0F0h			; CP WA, BC
	JR	C, .cse_rem_loop		; 67 d4

.cse_done:
	POP	XIZ				; 5e
	db	0BFh, 012h, 037h		; LDA XSP, XSP+0x12
	db	00Fh, 002h, 000h		; RETD 0x0002

; =============================================================================
; Boot_ClearScreen - Clear screen display
; Address: 0x9FC354
; =============================================================================
Boot_ClearScreen:
	db	00Bh, 008h, 000h		; PUSH 0x0008 - color
	db	00Bh, 002h, 000h		; PUSH 0x0002 - mode
	db	040h, 026h, 0A6h, 0FFh, 000h	; LD XWA, 0x00FFA626 - bitmap addr
	db	031h, 030h, 000h		; LD BC, 0x0030 - X pos
	db	032h, 0A0h, 000h		; LD DE, 0x00A0 - Y pos
	db	01Dh, 0FBh, 0CCh, 0FFh		; CALL 0xFFCCFB (Draw_Bitmap)
	RET					; 0e

; =============================================================================
; Boot_WaitDiskInsert - Wait for disk insert and verify type
; Address: 0x9FC36A
; Waits for FDC ready, checks disk type matches expected
; =============================================================================
Boot_WaitDiskInsert:
	db	0EFh, 06Ah			; DEC 2, XSP - allocate 2 bytes
	db	0B7h, 041h			; LD (XSP), A - save expected type
	db	00Bh, 008h, 000h		; PUSH 0x0008
	db	00Bh, 002h, 000h		; PUSH 0x0002
	db	040h, 05Eh, 0ADh, 0FFh, 000h	; LD XWA, 0x00FFAD5E - insert disk msg
	db	031h, 030h, 000h		; LD BC, 0x0030
	db	032h, 0A0h, 000h		; LD DE, 0x00A0
	db	01Dh, 0FBh, 0CCh, 0FFh		; CALL 0xFFCCFB

.wdi_wait_remove:
	db	01Dh, 063h, 0ECh, 0FFh		; CALL 0xFFEC63 - check disk present
	db	0CFh, 0D8h			; CP L, 0
	JR	Z, .wdi_check_insert		; 66 08
	db	01Dh, 063h, 0ECh, 0FFh		; CALL 0xFFEC63
	db	0CFh, 0D8h			; CP L, 0
	JR	NZ, .wdi_wait_remove		; 6e f8

.wdi_check_insert:
	db	0E8h, 0A8h			; LD XWA, 0
.wdi_delay1:
	db	0E8h, 061h			; INC 1, XWA
	db	0E8h, 0CFh, 000h, 000h, 004h, 000h	; CP XWA, 0x00040000
	JR	C, .wdi_delay1			; 67 f6

.wdi_wait_insert:
	db	01Dh, 063h, 0ECh, 0FFh		; CALL 0xFFEC63
	db	0CFh, 0D8h			; CP L, 0
	JR	NZ, .wdi_delay2			; 6e 08
	db	01Dh, 063h, 0ECh, 0FFh		; CALL 0xFFEC63
	db	0CFh, 0D8h			; CP L, 0
	JR	Z, .wdi_wait_insert		; 66 f8

.wdi_delay2:
	db	0E8h, 0A8h			; LD XWA, 0
.wdi_delay2_loop:
	db	0E8h, 061h			; INC 1, XWA
	db	0E8h, 0CFh, 000h, 000h, 020h, 000h	; CP XWA, 0x00200000
	JR	C, .wdi_delay2_loop		; 67 f6

	; Check disk type
	db	01Eh, 006h, 0FCh		; CALR Boot_DetectDiskType
	db	087h, 0F7h			; CP L, (XSP) - compare with expected
	JR	NZ, Boot_WaitDiskInsert		; 6e ac

	; Type matches - clear screen and return
	db	01Eh, 08Fh, 0FFh		; CALR Boot_ClearScreen
	db	0EFh, 062h			; INC 2, XSP
	RET					; 0e

; =============================================================================
; Boot_WaitFDCReady - Wait for FDC to become ready
; Address: 0x9FC3C8
; Polls FDC status with timeout display
; =============================================================================
Boot_WaitFDCReady:
	PUSH	IZ				; 2e
	db	036h, 032h, 000h		; LD IZ, 0x0032 - timeout counter
.wfdc_poll:
	db	0E8h, 0A8h			; LD XWA, 0
	db	0F1h, 000h, 00Ch, 060h		; LD (0x0C00), XWA
	db	01Dh, 017h, 0BDh, 0FFh		; CALL 0xFFBD17 - reset FDC
	db	01Dh, 085h, 0BEh, 0FFh		; CALL 0xFFBE85 - check FDC ready
	db	0DBh, 0CFh, 0FFh, 0FFh		; CP HL, 0xFFFF - error?
	JR	NZ, .wfdc_done			; 6e 29

	; Timeout handling
	db	0E1h, 000h, 00Ch, 020h		; LD XWA, (0x0C00)
	db	0E8h, 0CFh, 0F4h, 001h, 000h, 000h	; CP XWA, 0x000001F4 (500)
	JR	ULE, .wfdc_continue		; 63 13

	; Update display
	db	0DEh, 060h			; INC 0, IZ - increment progress
	db	0DEh, 088h			; LD WA, IZ
	db	031h, 0B4h, 000h		; LD BC, 0x00B4 - X pos
	db	0DAh, 0AEh			; LD DE, 5 - mode
	db	01Dh, 09Ah, 0CDh, 0FFh		; CALL 0xFFCD9A (display progress)
	db	0E8h, 0A8h			; LD XWA, 0
	db	0F1h, 000h, 00Ch, 060h		; LD (0x0C00), XWA

.wfdc_continue:
	db	01Dh, 085h, 0BEh, 0FFh		; CALL 0xFFBE85
	db	0DBh, 0CFh, 0FFh, 0FFh		; CP HL, 0xFFFF
	JR	Z, .wfdc_poll			; 66 d7

.wfdc_done:
	POP	IZ				; 4e
	RET					; 0e

; =============================================================================
; Boot_LoadDiskData - Main disk data loading dispatcher
; Address: 0x9FC40B
; Dispatches based on disk type (1-8) to appropriate handler
; =============================================================================
Boot_LoadDiskData:
	db	0EFh, 06Ah			; DEC 2, XSP
	db	0B7h, 041h			; LD (XSP), A - save disk type
	db	00Bh, 008h, 000h		; PUSH 0x0008
	db	00Bh, 002h, 000h		; PUSH 0x0002
	db	040h, 0BEh, 0A3h, 0FFh, 000h	; LD XWA, 0x00FFA3BE - loading msg
	db	031h, 030h, 000h		; LD BC, 0x0030
	db	032h, 0A0h, 000h		; LD DE, 0x00A0
	db	01Dh, 0FBh, 0CCh, 0FFh		; CALL 0xFFCCFB

	; Validate disk type 1-8
	db	087h, 021h			; LD A, (XSP)
	db	0D8h, 012h			; EXTZ WA
	db	0D8h, 069h			; DEC 1, WA
	db	0D8h, 0D8h			; CP WA, 0
	db	071h, 0B6h, 000h		; JRL LT, .ldd_error (type < 1)
	db	0D8h, 0DFh			; CP WA, 7
	db	07Ah, 0B1h, 000h		; JRL GT, .ldd_error (type > 8)

	; Dispatch via jump table
	db	0D8h, 080h			; ADD WA, WA - WA *= 2
	db	0F2h, 040h, 0A1h, 0FFh, 034h	; LDA XIX, 0xFFA140 - jump table
	db	0D3h, 007h, 0F0h, 0E0h, 020h	; LD WA, (XIX+WA)
	db	0F2h, 04Ah, 0C4h, 0FFh, 034h	; LDA XIX, 0xFFC44A - base addr
	db	0F3h, 007h, 0F0h, 0E0h, 0D8h	; JP T, XIX+WA - dispatch

; Type 1 handler (0x9FC44A): Table data disk 1
.ldd_type1:
	db	01Eh, 07Bh, 0FFh		; CALR Boot_WaitFDCReady
	db	01Eh, 004h, 0FFh		; CALR Boot_ClearScreen
	db	030h, 024h, 000h		; LD WA, 0x0024 - start sector
	db	041h, 000h, 000h, 080h, 000h	; LD XBC, 0x00800000 - dest
	db	01Eh, 086h, 0FCh		; CALR Boot_CopySectors
	db	0D8h, 0AAh			; LD WA, 2 - disk 2
	db	01Eh, 00Ah, 0FFh		; CALR Boot_WaitDiskInsert
	db	030h, 024h, 000h		; LD WA, 0x0024
	db	041h, 000h, 000h, 090h, 000h	; LD XBC, 0x00900000
	JR	T, .ldd_copy2			; 68 1e

; Type 2 handler (0x9FC46A): Table data disk 2 (start from disk 2)
.ldd_type2:
	db	01Eh, 05Bh, 0FFh		; CALR Boot_WaitFDCReady
	db	01Eh, 0E4h, 0FEh		; CALR Boot_ClearScreen
	db	030h, 024h, 000h		; LD WA, 0x0024
	db	041h, 000h, 000h, 080h, 000h	; LD XBC, 0x00800000
	db	01Eh, 066h, 0FCh		; CALR Boot_CopySectors
	db	0D8h, 0ACh			; LD WA, 4 - next is disk 4
	db	01Eh, 0EAh, 0FEh		; CALR Boot_WaitDiskInsert
	db	030h, 024h, 000h		; LD WA, 0x0024
	db	041h, 000h, 000h, 090h, 000h	; LD XBC, 0x00900000

.ldd_copy2:
	db	01Eh, 056h, 0FCh		; CALR Boot_CopySectors
	JR	T, .ldd_done			; 68 55

; Type 3 handler (0x9FC48D): Custom data flash
.ldd_type3:
	db	0D8h, 0A9h			; LD WA, 1
	db	01Dh, 0DBh, 0BBh, 0FFh		; CALL 0xFFBBDB
	db	01Eh, 0BEh, 0FEh		; CALR Boot_ClearScreen
	db	00Bh, 000h, 008h		; PUSH 0x0800 - size
	db	0D8h, 0A9h			; LD WA, 1 - bank 1
	db	031h, 024h, 000h		; LD BC, 0x0024 - start sector
	db	042h, 000h, 000h, 030h, 000h	; LD XDE, 0x00300000 - dest
	JR	T, .ldd_copy_ext		; 68 16

; Type 4 handler (0x9FC4A5): HDAE5000 firmware
.ldd_type4:
	db	0D8h, 0AAh			; LD WA, 2
	db	01Dh, 0DBh, 0BBh, 0FFh		; CALL 0xFFBBDB
	db	01Eh, 0A6h, 0FEh		; CALR Boot_ClearScreen
	db	00Bh, 000h, 004h		; PUSH 0x0400 - size
	db	0D8h, 0AAh			; LD WA, 2 - bank 2
	db	031h, 024h, 000h		; LD BC, 0x0024
	db	042h, 000h, 000h, 028h, 000h	; LD XDE, 0x00280000

.ldd_copy_ext:
	db	01Eh, 055h, 0FDh		; CALR Boot_CopySectorsEx
	JR	T, .ldd_done			; 68 22

; Type 5 handler (0x9FC4C0): Erase and reprogram
.ldd_type5:
	db	0D8h, 0A9h			; LD WA, 1
	db	041h, 0FFh, 0FFh, 03Fh, 000h	; LD XBC, 0x003FFFFF - end addr
	db	01Dh, 017h, 0BAh, 0FFh		; CALL 0xFFBA17 (Flash_SectorErase)
	db	01Eh, 0FAh, 0FEh		; CALR Boot_WaitFDCReady
	db	01Eh, 083h, 0FEh		; CALR Boot_ClearScreen
	db	01Eh, 07Ch, 005h		; CALR Boot_ProgramHDAE_Part1
	db	01Eh, 0DCh, 004h		; CALR Boot_ProgramCustomFlash
	JR	T, .ldd_done			; 68 09

; Type 6/7/8 handlers continue
.ldd_type678:
	db	01Eh, 0ECh, 0FEh		; CALR Boot_WaitFDCReady
	db	01Eh, 075h, 0FEh		; CALR Boot_ClearScreen
	db	01Eh, 06Eh, 005h		; CALR Boot_ProgramHDAE_Part1

.ldd_done:
	db	0EFh, 062h			; INC 2, XSP
	RET					; 0e

.ldd_error:
	db	00Bh, 008h, 000h		; PUSH 0x0008
	db	00Bh, 002h, 000h		; PUSH 0x0002
	db	040h, 0C6h, 0AFh, 0FFh, 000h	; LD XWA, 0x00FFAFC6 - error msg
	db	031h, 030h, 000h		; LD BC, 0x0030
	db	032h, 0A0h, 000h		; LD DE, 0x00A0
	db	01Dh, 0FBh, 0CCh, 0FFh		; CALL 0xFFCCFB
	db	0EFh, 062h			; INC 2, XSP
.ldd_halt:
	JR	T, .ldd_halt			; 68 fe - infinite loop

; =============================================================================
; Boot_DelayLoop - Simple delay routine
; Address: 0x9FC4FE
; =============================================================================
Boot_DelayLoop:
	db	0E9h, 0A8h			; LD XBC, 0
	db	0E8h, 0F1h			; CP XBC, XWA
	db	0B0h, 0FFh			; RET NC
.delay_loop:
	db	0E9h, 061h			; INC 1, XBC
	db	0E8h, 0F1h			; CP XBC, XWA
	JR	C, .delay_loop			; 67 fa
	RET					; 0e

; =============================================================================
; Boot_BlinkLED - Cycle through LED pattern
; Address: 0x9FC50B
; Controls LED at 0x160004 (HDAE5000 PPI port)
; =============================================================================
Boot_BlinkLED:
	db	0C1h, 008h, 00Ch, 061h		; INC 1, (0x0C08) - LED counter
	db	0C1h, 008h, 00Ch, 021h		; LD A, (0x0C08)
	db	0C9h, 0CCh, 003h		; AND A, 0x03 - mask to 0-3
	db	0C9h, 0DBh			; CP A, 3
	JR	Z, .led_pattern3		; 66 24
	db	0C9h, 0DAh			; CP A, 2
	JR	Z, .led_pattern2		; 66 18
	db	0C9h, 0D9h			; CP A, 1
	JR	Z, .led_pattern1		; 66 0c
	db	0C9h, 0D8h			; CP A, 0
	JR	NZ, .led_delay			; 6e 1e

	; Pattern 0: bit 0
	db	0F2h, 004h, 000h, 016h, 000h, 001h	; LD (0x160004), 0x01
	JR	T, .led_delay			; 68 16

.led_pattern1:
	db	0F2h, 004h, 000h, 016h, 000h, 002h	; LD (0x160004), 0x02
	JR	T, .led_delay			; 68 0e

.led_pattern2:
	db	0F2h, 004h, 000h, 016h, 000h, 004h	; LD (0x160004), 0x04
	JR	T, .led_delay			; 68 06

.led_pattern3:
	db	0F2h, 004h, 000h, 016h, 000h, 008h	; LD (0x160004), 0x08

.led_delay:
	db	040h, 0A0h, 086h, 001h, 000h	; LD XWA, 0x000186A0 (100000)
	JR	T, Boot_DelayLoop		; 68 b3 -> tail call

; =============================================================================
; LED_ToggleBit2 - Toggle LED bit 2 animation loop
; Address: 0x9FC54B
; =============================================================================
LED_ToggleBit2:
	db	0F2h, 004h, 000h, 016h, 0C2h	; CHG 2, (0x160004) - toggle bit 2
	db	040h, 0F0h, 049h, 002h, 000h	; LD XWA, 0x000249F0 (150000)
	db	01Eh, 0A6h, 0FFh		; CALR Boot_DelayLoop
	JR	T, LED_ToggleBit2		; 68 f1

; =============================================================================
; LED_ToggleBit3 - Toggle LED bit 3 animation loop
; Address: 0x9FC55A
; =============================================================================
LED_ToggleBit3:
	db	0F2h, 004h, 000h, 016h, 0C3h	; CHG 3, (0x160004) - toggle bit 3
	db	040h, 0F0h, 049h, 002h, 000h	; LD XWA, 0x000249F0
	db	01Eh, 097h, 0FFh		; CALR Boot_DelayLoop
	JR	T, LED_ToggleBit3		; 68 f1

; =============================================================================
; Boot_FindValidBlock - Find first valid (non-empty) 64-byte block
; Address: 0x9FC569
; Input: XWA = start address, XBC = end address
; Returns: XHL = block address or 0 if not found
; =============================================================================
Boot_FindValidBlock:
	db	0E8h, 08Bh			; LD XHL, XWA
.fvb_check:
	db	0A3h, 022h			; LD XDE, (XHL)
	db	0EAh, 0CFh, 0FFh, 0FFh, 0FFh, 0FFh	; CP XDE, 0xFFFFFFFF
	db	0B0h, 0FEh			; RET NZ - found valid data
.fvb_next:
	db	0BBh, 040h, 033h		; LDA XHL, XHL+0x40 - next 64-byte block
	db	0E9h, 0F3h			; CP XHL, XBC
	JR	NZ, .fvb_not_end		; 6e 03
	db	0EBh, 0A8h			; LD XHL, 0 - not found
	RET					; 0e
.fvb_not_end:
	db	0A3h, 022h			; LD XDE, (XHL)
	db	0EAh, 0CFh, 0FFh, 0FFh, 0FFh, 0FFh	; CP XDE, 0xFFFFFFFF
	JR	Z, .fvb_next			; 66 ec
	RET					; 0e - found valid

; =============================================================================
; Boot_VerifyFlash - Verify flash programming against source
; Address: 0x9FC58A
; Input: XWA = flash addr, XBC = source addr, (XSP+4) = bank count
; Returns: XHL = 0 if match, non-zero if mismatch
; =============================================================================
Boot_VerifyFlash:
	db	0E8h, 08Bh			; LD XHL, XWA - flash addr
	db	0CDh, 088h			; LD W, E - bank number
	db	08Fh, 004h, 021h		; LD A, (XSP+0x04) - max bank
	db	0C9h, 0F0h			; CP W, A
	JR	UGT, .vf_success		; 6b 22

.vf_bank_loop:
	db	0F2h, 000h, 000h, 016h, 040h	; LD (0x160000), W - set bank
	db	0E9h, 08Ch			; LD XIX, XBC - source addr
	db	045h, 0FFh, 0FFh, 003h, 000h	; LD XIY, 0x0003FFFF - 256KB-1

.vf_compare:
	db	0D5h, 0F1h, 022h		; LD DE, (XIX+) - read source
	db	0D5h, 0EDh, 0F2h		; CP DE, (XHL+) - compare with flash
	JR	NZ, .vf_mismatch		; 6e 10
	db	0EDh, 08Ah			; LD XDE, XIY
	db	0EDh, 069h			; DEC 1, XIY
	db	0EAh, 0E2h			; OR XDE, XDE
	JR	NZ, .vf_compare			; 6e f0
	db	0C8h, 061h			; INC 1, W - next bank
	db	0C9h, 0F0h			; CP W, A
	JR	ULE, .vf_bank_loop		; 63 de

.vf_success:
	db	0EBh, 0A8h			; LD XHL, 0 - success
.vf_mismatch:
	db	00Fh, 002h, 000h		; RETD 0x0002

; =============================================================================
; Boot_ProgramCustomFlash - Program custom data flash (0x300000)
; Address: 0x9FC5BC
; Copies 256KB from table_data ROM (0x800000) to custom data (0x300000)
; Uses 2 banks
; =============================================================================
Boot_ProgramCustomFlash:
	db	0BFh, 0F6h, 037h		; LDA XSP, XSP+0xF6 - allocate 10 bytes
	PUSH	XIZ				; 3e
	db	0F2h, 000h, 000h, 030h, 030h	; LDA XWA, 0x300000 - dest
	db	0BFh, 008h, 060h		; LD (XSP+0x08), XWA
	db	0BFh, 00Ch, 000h, 000h		; LD (XSP+0x0C), 0x00 - bank

.pcf_bank_loop:
	db	08Fh, 00Ch, 021h		; LD A, (XSP+0x0C)
	db	0F2h, 000h, 000h, 016h, 041h	; LD (0x160000), A - set bank
	db	0F2h, 000h, 000h, 020h, 030h	; LDA XWA, 0x200000 - source
	db	0BFh, 004h, 060h		; LD (XSP+0x04), XWA
	db	0EEh, 0A8h			; LD XIZ, 0 - counter

.pcf_copy_loop:
	db	0AFh, 008h, 020h		; LD XWA, (XSP+0x08) - dest ptr
	db	0F5h, 0E1h, 031h		; LDA XBC, XWA+
	db	0BFh, 008h, 060h		; LD (XSP+0x08), XWA
	db	0AFh, 004h, 020h		; LD XWA, (XSP+0x04) - source ptr
	db	0D5h, 0E1h, 022h		; LD DE, (XWA+)
	db	0BFh, 004h, 060h		; LD (XSP+0x04), XWA
	db	0D8h, 0A9h			; LD WA, 1 - bank 1
	db	01Dh, 003h, 0B9h, 0FFh		; CALL 0xFFB903 (Flash_ProgramWord_16bit)
	db	0EEh, 061h			; INC 1, XIZ
	db	0EEh, 0CFh, 000h, 000h, 004h, 000h	; CP XIZ, 0x00040000 (256K)
	JR	C, .pcf_copy_loop		; 67 de

	db	08Fh, 00Ch, 061h		; INC 1, (XSP+0x0C)
	db	08Fh, 00Ch, 03Fh, 002h		; CP (XSP+0x0C), 0x02
	JR	C, .pcf_bank_loop		; 67 c3

	POP	XIZ				; 5e
	db	0BFh, 00Ah, 037h		; LDA XSP, XSP+0x0A
	RET					; 0e

; =============================================================================
; Boot_ProgramHDAE_Part1 - Program HDAE5000 ROM banks 0-3
; Address: 0x9FC60E
; Copies from table_data (0x800000) to HDAE5000 (0x280000)
; =============================================================================
Boot_ProgramHDAE_Part1:
	db	0BFh, 0F6h, 037h		; LDA XSP, XSP+0xF6
	PUSH	XIZ				; 3e
	db	040h, 000h, 000h, 080h, 000h	; LD XWA, 0x00800000 - source
	db	0BFh, 008h, 060h		; LD (XSP+0x08), XWA
	db	0BFh, 00Ch, 000h, 000h		; LD (XSP+0x0C), 0x00 - bank

.phd1_bank_loop:
	db	08Fh, 00Ch, 021h		; LD A, (XSP+0x0C)
	db	0F2h, 000h, 000h, 016h, 041h	; LD (0x160000), A - set bank
	db	0F2h, 000h, 000h, 028h, 030h	; LDA XWA, 0x280000 - dest
	db	0BFh, 004h, 060h		; LD (XSP+0x04), XWA
	db	0EEh, 0A8h			; LD XIZ, 0

.phd1_copy_loop:
	db	0AFh, 008h, 020h		; LD XWA, (XSP+0x08)
	db	0F5h, 0E2h, 031h		; LDA XBC, XWA+
	db	0BFh, 008h, 060h		; LD (XSP+0x08), XWA
	db	0E9h, 088h			; LD XWA, XBC
	db	0AFh, 004h, 022h		; LD XDE, (XSP+0x04)
	db	0E5h, 0EAh, 021h		; LD XBC, (XDE+)
	db	0BFh, 004h, 062h		; LD (XSP+0x04), XDE
	db	01Dh, 0D7h, 0BCh, 0FFh		; CALL 0xFFBCD7 (write with callback)
	db	0EEh, 061h			; INC 1, XIZ
	db	0EEh, 0CFh, 000h, 000h, 002h, 000h	; CP XIZ, 0x00020000 (128K)
	JR	C, .phd1_copy_loop		; 67 de

	db	08Fh, 00Ch, 061h		; INC 1, (XSP+0x0C)
	db	08Fh, 00Ch, 03Fh, 004h		; CP (XSP+0x0C), 0x04
	JR	C, .phd1_bank_loop		; 67 c3

	POP	XIZ				; 5e
	db	0BFh, 00Ah, 037h		; LDA XSP, XSP+0x0A
	RET					; 0e

; =============================================================================
; Boot_ProgramHDAE_Part2 - Program HDAE5000 ROM banks 4-7
; Address: 0x9FC660
; =============================================================================
Boot_ProgramHDAE_Part2:
	db	0BFh, 0F6h, 037h		; LDA XSP, XSP+0xF6
	PUSH	XIZ				; 3e
	db	040h, 000h, 000h, 080h, 000h	; LD XWA, 0x00800000
	db	0BFh, 008h, 060h		; LD (XSP+0x08), XWA
	db	0BFh, 00Ch, 000h, 004h		; LD (XSP+0x0C), 0x04 - start at bank 4

.phd2_bank_loop:
	db	08Fh, 00Ch, 021h		; LD A, (XSP+0x0C)
	db	0F2h, 000h, 000h, 016h, 041h	; LD (0x160000), A
	db	0F2h, 000h, 000h, 028h, 030h	; LDA XWA, 0x280000
	db	0BFh, 004h, 060h		; LD (XSP+0x04), XWA
	db	0EEh, 0A8h			; LD XIZ, 0

.phd2_copy_loop:
	db	0AFh, 008h, 020h		; LD XWA, (XSP+0x08)
	db	0F5h, 0E2h, 031h		; LDA XBC, XWA+
	db	0BFh, 008h, 060h		; LD (XSP+0x08), XWA
	db	0E9h, 088h			; LD XWA, XBC
	db	0AFh, 004h, 022h		; LD XDE, (XSP+0x04)
	db	0E5h, 0EAh, 021h		; LD XBC, (XDE+)
	db	0BFh, 004h, 062h		; LD (XSP+0x04), XDE
	db	01Dh, 0D7h, 0BCh, 0FFh		; CALL 0xFFBCD7
	db	0EEh, 061h			; INC 1, XIZ
	db	0EEh, 0CFh, 000h, 000h, 002h, 000h	; CP XIZ, 0x00020000
	JR	C, .phd2_copy_loop		; 67 de

	db	08Fh, 00Ch, 061h		; INC 1, (XSP+0x0C)
	db	08Fh, 00Ch, 03Fh, 008h		; CP (XSP+0x0C), 0x08 - end at bank 8
	JR	C, .phd2_bank_loop		; 67 c3

	POP	XIZ				; 5e
	db	0BFh, 00Ah, 037h		; LDA XSP, XSP+0x0A
	RET					; 0e

; =============================================================================
; Boot_InitHDAE_PPI - Initialize HDAE5000 PPI interface
; Address: 0x9FC6B2
; Sets up 8255 PPI at 0x160000-0x160006
; =============================================================================
Boot_InitHDAE_PPI:
	db	0D7h, 0FAh, 004h		; PUSH QIZ
	db	0C7h, 0FBh, 0A8h		; LD QIZH, 0
	db	008h, 0E4h, 000h		; LD (0xE4), 0x00 - TMP94C241 SFR init
	db	008h, 0E0h, 000h		; LD (0xE0), 0x00
	db	008h, 0EDh, 000h		; LD (0xED), 0x00
	db	008h, 0E3h, 000h		; LD (0xE3), 0x00
	db	008h, 0EBh, 000h		; LD (0xEB), 0x00
	db	0F1h, 054h, 001h, 000h, 066h	; LD (0x0154), 0x66
	db	0F2h, 006h, 000h, 016h, 000h, 082h	; LD (0x160006), 0x82 - PPI mode
	db	0F2h, 000h, 000h, 016h, 000h, 000h	; LD (0x160000), 0x00 - Port A
	db	0F2h, 004h, 000h, 016h, 000h, 000h	; LD (0x160004), 0x00 - Port C
	db	0F2h, 004h, 000h, 016h, 000h, 00Fh	; LD (0x160004), 0x0F - LED bits on
	db	040h, 0A0h, 0BBh, 00Dh, 000h	; LD XWA, 0x000DBBA0 (900000)
	db	01Eh, 012h, 0FEh		; CALR Boot_DelayLoop
	db	0F2h, 004h, 000h, 016h, 000h, 000h	; LD (0x160004), 0x00 - LEDs off
	db	0C2h, 002h, 000h, 016h		; LD (0x160002), A - Port B (4 bytes)


; =============================================================================
; LZSS DECOMPRESSOR (SLIDE4K FORMAT)
; =============================================================================
; The KN5000 bootloader includes an LZSS decompressor for handling compressed
; firmware data. This implementation uses the standard SLIDE4K format:
;   - 4KB sliding window (0x1000 bytes)
;   - 12-bit window offset (masked with 0x0FFF)
;   - 4-bit match length (stored in high nibble of second byte)
;   - Flag byte determines literal (bit=1) vs back-reference (bit=0)
;   - Window pre-filled with zeros for first 4078 (0xFEE) bytes
;
; RAM Variables Used:
;   0x0C20: Expected output size
;   0x0C24: Current output position
;   0x0C28: Source ROM address pointer
;   0x0C2C: Sector read buffer pointer
;   0x0C30: Current sector X position
;   0x0C32: Current sector Y position
;   0x0C34: Sector offset for display
;   0x0C36: Output byte counter (0-3 for 32-bit writes)
;
; Stack Frame (XSP+offset):
;   +0x04: Flag byte (shifted right each iteration)
;   +0x06: Copy counter for back-reference
;   +0x08: Match length
;   +0x0A: Window write position
;   +0x0C: Window base address (copy of +0x10)
;   +0x10: Window buffer pointer (from malloc)
; =============================================================================

	ORG 09FC8C2h
; -----------------------------------------------------------------------------
; LZSS_ReadByte - Read next byte from compressed input stream
; Address: 0xFFC8C2
; Returns: HL = byte read (or 0xFFFF if end of data)
;
; Handles sector buffering - reads 0x2400 bytes per sector from table_data ROM
; -----------------------------------------------------------------------------
LZSS_ReadByte:
	db	02Eh				; PUSH IZ
	db	0E1h, 024h, 00Ch, 020h		; LD XWA, (0x0C24) - current position
	db	0E1h, 020h, 00Ch, 0F0h		; CP XWA, (0x0C20) - compare with expected size
	db	067h, 005h			; JR C, .not_eof
	db	033h, 0FFh, 0FFh		; LD HL, 0xFFFF - return EOF
	db	068h, 061h			; JR T, .exit
.not_eof:
	; Check if need to read next sector
	db	0F2h, 0A4h, 099h, 000h, 030h	; LDA XWA, 0x0099A4
	db	0E8h, 0C8h, 000h, 090h, 000h, 000h	; ADD XWA, 0x00009000
	db	0E1h, 02Ch, 00Ch, 0F0h		; CP XWA, (0x0C2C) - buffer limit
	db	06Eh, 041h			; JR NZ, .read_byte
	; Need to read next sector
	db	0D1h, 030h, 00Ch, 060h		; INCW 0, (0x0C30) - next sector X
	db	0D1h, 030h, 00Ch, 020h		; LD WA, (0x0C30)
	db	0D1h, 032h, 00Ch, 021h		; LD BC, (0x0C32)
	db	0DAh, 0AEh			; LD DE, 6 - sector size index
	db	01Dh, 09Ah, 0CDh, 0FFh		; CALL 0xFFCD9A (display progress)
	db	0DEh, 0A8h			; LD IZ, 0
.read_sectors:
	db	0D1h, 034h, 00Ch, 020h		; LD WA, (0x0C34)
	db	0E8h, 012h			; EXTZ XWA
	db	031h, 000h, 024h		; LD BC, 0x2400 - sector size
	db	0DEh, 041h			; MUL XBC, IZ
	db	042h, 0A4h, 099h, 000h, 000h	; LD XDE, 0x000099A4 - buffer base
	db	0E9h, 082h			; ADD XDE, XBC
	db	031h, 012h, 000h		; LD BC, 0x0012
	db	01Eh, 083h, 0F6h		; CALR 0xFFBF92 (read sector data)
	db	0D1h, 034h, 00Ch, 038h, 012h, 000h	; ADD (0x0C34), 0x0012
	db	0DEh, 061h			; INC 1, IZ
	db	0DEh, 0DCh			; CP IZ, 4
	db	067h, 0DCh			; JR C, .read_sectors
	db	0F2h, 0A4h, 099h, 000h, 030h	; LDA XWA, 0x0099A4
	db	0F1h, 02Ch, 00Ch, 060h		; LD (0x0C2C), XWA - reset buffer pointer
.read_byte:
	db	0E1h, 02Ch, 00Ch, 020h		; LD XWA, (0x0C2C) - get buffer pointer
	db	0F5h, 0E0h, 031h		; LDA XBC, XWA+ (post-increment read)
	db	0F1h, 02Ch, 00Ch, 060h		; LD (0x0C2C), XWA - save updated pointer
	db	081h, 027h			; LD L, (XBC) - read byte into L
	db	0DBh, 012h			; EXTZ HL - zero-extend to HL
.exit:
	db	04Eh				; POP IZ
	db	00Eh				; RET

; -----------------------------------------------------------------------------
; LZSS_OutputByte - Write decompressed byte to output buffer
; Address: 0xFFC935
; Input: A = byte to output
;
; Buffers 4 bytes and writes as 32-bit word to destination
; -----------------------------------------------------------------------------
	ORG 09FC935h
LZSS_OutputByte:
	db	0C1h, 036h, 00Ch, 025h		; LD E, (0x0C36) - output index
	db	0DAh, 012h			; EXTZ DE
	db	0F1h, 00Ah, 00Ch, 031h		; LDA XBC, 0x0C0A - temp buffer
	db	0EAh, 012h			; EXTZ XDE
	db	0E9h, 082h			; ADD XDE, XBC
	db	0B2h, 041h			; LD (XDE), A - store byte
	db	0C1h, 036h, 00Ch, 021h		; LD A, (0x0C36)
	db	0C9h, 08Dh			; LD E, A
	db	0C9h, 061h			; INC 1, A
	db	0F1h, 036h, 00Ch, 041h		; LD (0x0C36), A
	db	0CDh, 0DBh			; CP E, 3 - check if 4 bytes buffered
	db	06Eh, 018h			; JR NZ, .not_full
	; Flush 4-byte buffer to destination
	db	0E1h, 028h, 00Ch, 020h		; LD XWA, (0x0C28) - dest ptr
	db	0F5h, 0E2h, 032h		; LDA XDE, XWA+ (post-increment)
	db	0F1h, 028h, 00Ch, 060h		; LD (0x0C28), XWA
	db	0A1h, 021h			; LD XBC, (XBC) - load 4 bytes from buffer
	db	0EAh, 088h			; LD XWA, XDE
	db	01Dh, 0D7h, 0BCh, 0FFh		; CALL 0xFFBCD7 (write to dest)
	db	0F1h, 036h, 00Ch, 000h, 000h	; LD (0x0C36), 0x00 - reset index
.not_full:
	db	0E8h, 0A9h			; LD XWA, 1
	db	0E1h, 024h, 00Ch, 088h		; ADD (0x0C24), XWA - increment output pos
	db	00Eh				; RET

; -----------------------------------------------------------------------------
; Routine at 0xFFC974 - alternate output handler
; Used when writing to a different buffer (0x0C0E instead of 0x0C0A)
; -----------------------------------------------------------------------------
	ORG 09FC974h
LZSS_OutputByte_Alt:
	db	0C1h, 036h, 00Ch, 023h		; LD C, (0x0C36)
	db	0D9h, 012h			; EXTZ BC
	db	0F1h, 00Eh, 00Ch, 032h		; LDA XDE, 0x0C0E
	db	0E9h, 012h			; EXTZ XBC
	db	0EAh, 081h			; ADD XBC, XDE
	db	0B1h, 041h			; LD (XBC), A
	db	0C1h, 036h, 00Ch, 021h		; LD A, (0x0C36)
	db	0C9h, 08Bh			; LD C, A
	db	0C9h, 061h			; INC 1, A
	db	0F1h, 036h, 00Ch, 041h		; LD (0x0C36), A
	db	0CBh, 0D9h			; CP C, 1
	db	06Eh, 018h			; JR NZ, .not_full
	db	0E1h, 038h, 00Ch, 020h		; LD XWA, (0x0C38)
	db	0F5h, 0E1h, 031h		; LDA XBC, XWA+
	db	0F1h, 038h, 00Ch, 060h		; LD (0x0C38), XWA
	db	092h, 022h			; LD DE, (XDE)
	db	0D8h, 0A9h			; LD WA, 1
	db	01Dh, 003h, 0B9h, 0FFh		; CALL 0xFFB903
	db	0F1h, 036h, 00Ch, 000h, 000h	; LD (0x0C36), 0x00
.not_full:
	db	0E8h, 0A9h			; LD XWA, 1
	db	0E1h, 024h, 00Ch, 088h		; ADD (0x0C24), XWA
	db	00Eh				; RET

; -----------------------------------------------------------------------------
; Routine at 0xFFC9B3 - LZSS header parsing helper for flash update
; Sets up source address (0x3E0000 = Table Data ROM) and validates header
; -----------------------------------------------------------------------------
	ORG 09FC9B3h
LZSS_ParseHeader:
	db	0EFh, 06Eh			; DEC 6, XSP (allocate 6 bytes)
	db	02Eh				; PUSH IZ
	db	0F1h, 036h, 00Ch, 000h, 000h	; LD (0x0C36), 0x00
	db	0F2h, 000h, 000h, 030h, 030h	; LDA XWA, 0x300000
	db	0E8h, 0C8h, 000h, 000h, 00Eh, 000h  ; ADD XWA, 0x000E0000 (XWA = 0x3E0000)
	db	0F1h, 038h, 00Ch, 060h		; LD (0x0C38), XWA - store source ptr
	db	040h, 000h, 000h, 002h, 000h	; LD XWA, 0x00020000
	db	0E1h, 020h, 00Ch, 088h		; ADD (0x0C20), XWA
	db	0DEh, 0A8h			; LD IZ, 0
.read_header:
	db	01Eh, 0EAh, 0FEh		; CALR LZSS_ReadByte
	db	0DEh, 089h			; LD BC, IZ
	db	0E9h, 012h			; EXTZ XBC
	db	0BFh, 002h, 030h		; LDA XWA, XSP+0x02
	db	0E8h, 08Ah			; LD XDE, XWA
	db	0E9h, 082h			; ADD XDE, XBC
	db	0B2h, 047h			; LD (XDE), L
	db	0DEh, 061h			; INC 1, IZ
	db	0DEh, 0DEh			; CP IZ, 6
	db	067h, 0EAh			; JR C, .read_header
	; Validate header against expected signature
	db	00Bh, 005h, 000h		; PUSH 0x0005
	db	00Bh, 0FFh, 000h		; PUSH 0x00FF
	db	00Bh, 050h, 0A1h		; PUSH 0xA150 (expected signature addr)
	db	038h				; PUSH XWA
	db	01Dh, 0DCh, 0FBh, 0FFh		; CALL 0xFFFBDC (memcmp)
	db	0EFh, 0C8h, 00Ah, 000h, 000h, 000h	; ADD XSP, 0x0A
	db	0DBh, 0D8h			; CP HL, 0
	db	066h, 005h			; JR Z, .valid
	db	033h, 0FFh, 0FFh		; LD HL, 0xFFFF
	db	068h, 044h			; JR T, .exit
.valid:
	; Output the 6 header bytes via OutputByte_Alt
	db	0DEh, 0A8h			; LD IZ, 0
.read_more:
	db	0DEh, 089h			; LD BC, IZ
	db	0E9h, 012h			; EXTZ XBC
	db	0BFh, 002h, 030h		; LDA XWA, XSP+0x02
	db	0E9h, 080h			; ADD XWA, XBC
	db	080h, 021h			; LD A, (XWA)
	db	0D8h, 012h			; EXTZ WA
	db	01Eh, 05Ah, 0FFh		; CALR LZSS_OutputByte_Alt
	db	0DEh, 061h			; INC 1, IZ
	db	0DEh, 0DEh			; CP IZ, 6
	db	067h, 0EAh			; JR C, .read_more
	; Set display coordinates for progress indicator
	db	0F1h, 030h, 00Ch, 002h, 02Ah, 000h  ; LD (0x0C30), 0x002A
	db	0F1h, 032h, 00Ch, 002h, 0C8h, 000h  ; LD (0x0C32), 0x00C8
	; Check if already at target size
	db	0E1h, 024h, 00Ch, 020h		; LD XWA, (0x0C24)
	db	0E1h, 020h, 00Ch, 0F0h		; CP XWA, (0x0C20)
	db	06Fh, 014h			; JR NC, .exit (already done)
	; Copy remaining raw bytes
.decompress_loop:
	db	01Eh, 089h, 0FEh		; CALR LZSS_ReadByte
	db	0DBh, 012h			; EXTZ HL
	db	0DBh, 088h			; LD WA, HL
	db	01Eh, 034h, 0FFh		; CALR LZSS_OutputByte_Alt
	db	0E1h, 024h, 00Ch, 020h		; LD XWA, (0x0C24)
	db	0E1h, 020h, 00Ch, 0F0h		; CP XWA, (0x0C20)
	db	067h, 0ECh			; JR C, .decompress_loop
.done:
	db	0DBh, 0A8h			; LD HL, 0 (success)
.exit:
	db	04Eh				; POP IZ
	db	0EFh, 066h			; INC 6, XSP
	db	00Eh				; RET

; -----------------------------------------------------------------------------
; LZSS_Decompress - Main SLIDE4K decompression routine
; Address: 0xFFCA50
;
; Decompresses LZSS-encoded data from table_data ROM to RAM.
; Uses standard SLIDE4K format with 4KB window.
; -----------------------------------------------------------------------------
	ORG 09FCA50h
LZSS_Decompress:
	; === Prologue: Allocate stack frame ===
	db	0BFh, 0F0h, 037h		; LDA XSP, XSP+0xF0 (allocate 16 bytes)
	db	03Eh				; PUSH XIZ

	; === Allocate 4KB sliding window buffer ===
	db	00Bh, 000h, 010h		; PUSH 0x1000 (4KB)
	db	01Dh, 056h, 0FBh, 0FFh		; CALL 0xFFFB56 (malloc)
	db	0EFh, 062h			; INC 2, XSP (pop arg)
	db	0BFh, 010h, 063h		; LD (XSP+0x10), XHL - save window ptr
	db	0AFh, 010h, 020h		; LD XWA, (XSP+0x10)
	db	0BFh, 00Ch, 060h		; LD (XSP+0x0C), XWA - copy to working ptr

	; === Pre-fill window with zeros (positions 0 to 0x0FED) ===
	db	0E8h, 0A8h			; LD XWA, 0
	db	0F1h, 024h, 00Ch, 060h		; LD (0x0C24), XWA - window fill index
.prefill_loop:
	db	0E1h, 024h, 00Ch, 020h		; LD XWA, (0x0C24)
	db	0AFh, 010h, 021h		; LD XBC, (XSP+0x10) - window base
	db	0E8h, 081h			; ADD XBC, XWA
	db	0B1h, 000h, 000h		; LD (XBC), 0x00
	db	0E1h, 024h, 00Ch, 020h		; LD XWA, (0x0C24)
	db	0E8h, 061h			; INC 1, XWA
	db	0F1h, 024h, 00Ch, 060h		; LD (0x0C24), XWA
	db	0E8h, 0CFh, 0EEh, 00Fh, 000h, 000h	; CP XWA, 0x00000FEE
	db	067h, 0E2h			; JR C, .prefill_loop

	; === Initialize decompression state ===
	db	0BFh, 00Ah, 002h, 0EEh, 00Fh	; LD (XSP+0x0A), 0x0FEE - window write pos
	db	0BFh, 004h, 002h, 000h, 000h	; LD (XSP+0x04), 0x0000 - flag byte
	db	0F1h, 036h, 00Ch, 000h, 000h	; LD (0x0C36), 0x00 - output counter
	db	0E8h, 0A8h			; LD XWA, 0
	db	0F1h, 024h, 00Ch, 060h		; LD (0x0C24), XWA - output position

	; === Setup source and display parameters ===
	db	0F2h, 0A4h, 099h, 000h, 030h	; LDA XWA, 0x0099A4 - sector buffer
	db	0F1h, 02Ch, 00Ch, 060h		; LD (0x0C2C), XWA
	db	040h, 000h, 000h, 080h, 000h	; LD XWA, 0x00800000 - source ROM base
	db	0F1h, 028h, 00Ch, 060h		; LD (0x0C28), XWA
	db	0F1h, 030h, 00Ch, 002h, 032h, 000h	; LD (0x0C30), 0x0032 - display X
	db	0F1h, 032h, 00Ch, 002h, 0B4h, 000h	; LD (0x0C32), 0x00B4 - display Y
	db	030h, 032h, 000h		; LD WA, 0x0032
	db	031h, 0B4h, 000h		; LD BC, 0x00B4
	db	0DAh, 0AEh			; LD DE, 6
	db	01Dh, 09Ah, 0CDh, 0FFh		; CALL 0xFFCD9A (init display)

	; === Read expected decompressed size (3 bytes, little-endian) ===
	db	040h, 0E8h, 003h, 000h, 000h	; LD XWA, 0x000003E8 - initial guess
	db	0F1h, 020h, 00Ch, 060h		; LD (0x0C20), XWA
	db	0F1h, 034h, 00Ch, 002h, 024h, 000h	; LD (0x0C34), 0x0024

	; === Pre-read 4 sectors for initial buffer fill ===
	db	0D7h, 0FAh, 0A8h		; LD QIZ, 0
.preread_loop:
	db	0D1h, 034h, 00Ch, 020h		; LD WA, (0x0C34)
	db	0E8h, 012h			; EXTZ XWA
	db	031h, 000h, 024h		; LD BC, 0x2400
	db	0D7h, 0FAh, 041h		; MUL XBC, QIZ
	db	042h, 0A4h, 099h, 000h, 000h	; LD XDE, 0x000099A4
	db	0E9h, 082h			; ADD XDE, XBC
	db	031h, 012h, 000h		; LD BC, 0x0012
	db	01Eh, 09Eh, 0F4h		; CALR 0xFFBF92
	db	0D1h, 034h, 00Ch, 038h, 012h, 000h	; ADD (0x0C34), 0x0012
	db	0D7h, 0FAh, 061h		; INC 1, QIZ
	db	0D7h, 0FAh, 0DCh		; CP QIZ, 4
	db	067h, 0D9h			; JR C, .preread_loop

	; === Read 8 header bytes ===
	db	0D7h, 0FAh, 0A8h		; LD QIZ, 0
.read_header_loop:
	db	01Eh, 0BAh, 0FDh		; CALR LZSS_ReadByte
	db	0D7h, 0FAh, 061h		; INC 1, QIZ
	db	0D7h, 0FAh, 0CFh, 008h, 000h	; CP QIZ, 0x0008
	db	067h, 0F3h			; JR C, .read_header_loop

	; === Parse decompressed size (3 bytes) ===
	db	01Eh, 0ADh, 0FDh		; CALR LZSS_ReadByte
	db	0EBh, 012h			; EXTZ XHL
	db	0EBh, 0ECh, 000h		; SLA 0, XHL (shift left for alignment)
	db	0F1h, 020h, 00Ch, 063h		; LD (0x0C20), XHL
	db	01Eh, 0A1h, 0FDh		; CALR LZSS_ReadByte
	db	0DBh, 0EEh, 008h		; SLL 8, HL
	db	0EBh, 012h			; EXTZ XHL
	db	0E1h, 020h, 00Ch, 08Bh		; ADD (0x0C20), XHL
	db	01Eh, 095h, 0FDh		; CALR LZSS_ReadByte
	db	0EBh, 012h			; EXTZ XHL
	db	0E1h, 020h, 00Ch, 020h		; LD XWA, (0x0C20)
	db	0EBh, 080h			; ADD XWA, XHL
	db	0F1h, 020h, 00Ch, 060h		; LD (0x0C20), XWA
	db	0E1h, 024h, 00Ch, 0F8h		; CP (0x0C24), XWA
	db	07Fh, 0DBh, 000h		; JRL NC, .done - already past size

; -----------------------------------------------------------------------------
; Main decompression loop
; Processes flag bytes and handles literal/back-reference encoding
; -----------------------------------------------------------------------------
.decompress_loop:
	; === Shift flag byte and check if need new flags ===
	db	09Fh, 004h, 07Fh		; SRLW (XSP+0x04) - shift flags right
	db	09Fh, 004h, 020h		; LD WA, (XSP+0x04)
	db	0D8h, 033h, 008h		; BIT 8, WA - check sentinel bit
	db	06Eh, 014h			; JR NZ, .flags_valid

	; === Read new flag byte ===
	db	01Eh, 074h, 0FDh		; CALR LZSS_ReadByte
	db	0DBh, 08Eh			; LD IZ, HL
	db	0DEh, 0CFh, 0FFh, 0FFh		; CP IZ, 0xFFFF - check for EOF
	db	076h, 0C4h, 000h		; JRL Z, .done
	db	0BFh, 004h, 056h		; LD (XSP+0x04), IZ - store flags
	db	09Fh, 004h, 03Eh, 000h, 0FFh	; OR (XSP+0x04), 0xFF00 - set sentinel

.flags_valid:
	; === Check bit 0: 1=literal, 0=back-reference ===
	db	09Fh, 004h, 020h		; LD WA, (XSP+0x04)
	db	0D8h, 033h, 000h		; BIT 0, WA
	db	066h, 02Bh			; JR Z, .back_reference

	; === LITERAL BYTE: Read and output directly ===
	db	01Eh, 058h, 0FDh		; CALR LZSS_ReadByte
	db	0DBh, 08Eh			; LD IZ, HL
	db	0DEh, 0CFh, 0FFh, 0FFh		; CP IZ, 0xFFFF
	db	076h, 0A8h, 000h		; JRL Z, .done
	db	0C7h, 0F8h, 089h		; LD A, IZL - get byte value
	db	0D8h, 012h			; EXTZ WA
	db	01Eh, 0BAh, 0FDh		; CALR LZSS_OutputByte
	; Store byte in sliding window
	db	09Fh, 00Ah, 021h		; LD BC, (XSP+0x0A) - window position
	db	09Fh, 00Ah, 061h		; INCW 1, (XSP+0x0A)
	db	0E9h, 012h			; EXTZ XBC
	db	0AFh, 010h, 081h		; ADD XBC, (XSP+0x10) - add window base
	db	0C7h, 0F8h, 089h		; LD A, IZL
	db	0B1h, 041h			; LD (XBC), A - store in window
	db	09Fh, 00Ah, 03Ch, 0FFh, 00Fh	; AND (XSP+0x0A), 0x0FFF - wrap window pos
	db	068h, 07Eh			; JR T, .check_done

.back_reference:
	; === BACK-REFERENCE: Read offset and length ===
	; First byte: low 8 bits of offset
	db	01Eh, 02Dh, 0FDh		; CALR LZSS_ReadByte
	db	0D7h, 0FAh, 09Bh		; LD QIZ, HL - save low offset
	db	0D7h, 0FAh, 0CFh, 0FFh, 0FFh	; CP QIZ, 0xFFFF
	db	066h, 07Ch			; JR Z, .done

	; Second byte: high 4 bits of offset + 4-bit length
	db	01Eh, 020h, 0FDh		; CALR LZSS_ReadByte
	db	0BFh, 008h, 053h		; LD (XSP+0x08), HL
	db	09Fh, 008h, 03Fh, 0FFh, 0FFh	; CP (XSP+0x08), 0xFFFF
	db	066h, 06Fh			; JR Z, .done

	; Combine offset: (high_nibble << 8) | low_byte
	db	09Fh, 008h, 021h		; LD BC, (XSP+0x08)
	db	0D9h, 0CCh, 0F0h, 000h		; AND BC, 0x00F0 - extract high nibble
	db	0D9h, 0EEh, 004h		; SLL 4, BC - shift to bits 11-8
	db	0D7h, 0FAh, 088h		; LD WA, QIZ
	db	0D9h, 0E0h			; OR WA, BC - combine with low byte
	db	0D7h, 0FAh, 098h		; LD QIZ, WA - QIZ = 12-bit offset

	; Extract length: (byte & 0x0F) + 2
	db	09Fh, 008h, 03Ch, 00Fh, 000h	; AND (XSP+0x08), 0x000F - extract length
	db	09Fh, 008h, 062h		; INCW 2, (XSP+0x08) - length + 2

	; === Copy from sliding window ===
	db	0BFh, 006h, 002h, 000h, 000h	; LD (XSP+0x06), 0x0000 - copy counter
	db	09Fh, 008h, 03Fh, 000h, 000h	; CP (XSP+0x08), 0x0000 - check length
	db	067h, 03Eh			; JR C, .check_done

.copy_loop:
	; Calculate source position in window
	db	0D7h, 0FAh, 088h		; LD WA, QIZ - get offset
	db	09Fh, 006h, 080h		; ADD WA, (XSP+0x06) - add counter
	db	0D8h, 0CCh, 0FFh, 00Fh		; AND WA, 0x0FFF - wrap to window
	db	0E8h, 012h			; EXTZ XWA
	db	0AFh, 00Ch, 080h		; ADD XWA, (XSP+0x0C) - add window base
	db	080h, 021h			; LD A, (XWA) - read from window
	db	0C7h, 0F8h, 099h		; LD IZL, A
	db	0DEh, 012h			; EXTZ IZ
	db	0C7h, 0F8h, 089h		; LD A, IZL
	db	0D8h, 012h			; EXTZ WA
	db	01Eh, 045h, 0FDh		; CALR LZSS_OutputByte

	; Store byte in sliding window at write position
	db	09Fh, 00Ah, 021h		; LD BC, (XSP+0x0A)
	db	09Fh, 00Ah, 061h		; INCW 1, (XSP+0x0A)
	db	0E9h, 012h			; EXTZ XBC
	db	0AFh, 00Ch, 081h		; ADD XBC, (XSP+0x0C)
	db	0C7h, 0F8h, 089h		; LD A, IZL
	db	0B1h, 041h			; LD (XBC), A
	db	09Fh, 00Ah, 03Ch, 0FFh, 00Fh	; AND (XSP+0x0A), 0x0FFF - wrap position

	; Increment counter and check if done
	db	09Fh, 006h, 061h		; INCW 1, (XSP+0x06)
	db	09Fh, 006h, 020h		; LD WA, (XSP+0x06)
	db	09Fh, 008h, 0F0h		; CP WA, (XSP+0x08) - compare with length
	db	063h, 0C2h			; JR ULE, .copy_loop

.check_done:
	; === Check if decompression complete ===
	db	0E1h, 024h, 00Ch, 020h		; LD XWA, (0x0C24)
	db	0E1h, 020h, 00Ch, 0F0h		; CP XWA, (0x0C20)
	db	077h, 025h, 0FFh		; JRL C, .decompress_loop

.done:
	; === Epilogue: Free window buffer and return ===
	db	0AFh, 010h, 020h		; LD XWA, (XSP+0x10)
	db	038h				; PUSH XWA
	db	01Dh, 0DDh, 0FCh, 0FFh		; CALL 0xFFFCDD (free)
	db	0EFh, 064h			; INC 4, XSP
	db	05Eh				; POP XIZ
	db	0BFh, 010h, 037h		; LDA XSP, XSP+0x10 (deallocate frame)
	db	00Eh				; RET

; =============================================================================
; BOOT UPDATE AND DISPLAY ROUTINES
; Addresses 0x9FCC2A to 0x9FFEE0 (12982 bytes)
;
; This section contains the main firmware update dispatcher and UI routines:
;
; FLASH UPDATE DISPATCHER (0x9FCC2A-0x9FCCFA):
;   0x9FCC2A: Boot_FlashUpdate_Main - Main update entry point
;             - Calls 0xFFEC63 to check update conditions
;             - Calls Detect_Disk_Type (0x9FBFC4)
;             - Calls Boot_Get_Region_Code (0xFFB700)
;             - Dispatches to appropriate handler based on disk type
;             - Displays UI bitmaps during erase/write
;
; DISPLAY ROUTINES (0x9FCCFB-0x9FD7FF):
;   0x9FCCFB: Draw_Bitmap - Render bitmap to screen
;   0x9FCD9A: Init_Display_Progress - Initialize progress indicator
;   0x9FCDFC: VGA_WritePort - Write to VGA I/O port
;   0x9FCE12: VGA_ReadPort - Read from VGA I/O port
;   0x9FCE1E-0x9FD7BD: VGA_Init - Complete VGA initialization sequence
;
; FLASH UPDATE HANDLERS (0x9FD800-0x9FEA9C):
;   Handlers for different update file types (1-8):
;   - Program ROM disk 1/2
;   - Table Data ROM disk 1/2
;   - Compressed custom data
;   - HDAE5000 firmware
;   - Compressed Program/Table ROM
;
; INTERRUPT HANDLERS:
;   0x9FEA9D: INTTC3_HANDLER - Timer counter 3
;   0x9FEAB2: INT4_HANDLER - External interrupt 4
;   0x9FF229: INTA_HANDLER - External interrupt A
;   0x9FF2AE: INTTX1_HANDLER - Serial TX 1
;   0x9FF2D0: INTRX1_HANDLER - Serial RX 1
;
; MEMORY ALLOCATION (0x9FFB00-0x9FFCFF):
;   0x9FFB56: malloc - Allocate memory from heap
;   0x9FFCDD: free - Free allocated memory
;
; See also: ../kn5000-docs/boot-sequence.md for boot flow documentation
; =============================================================================

; =============================================================================
; Boot_FlashUpdate_Main - Main flash update entry point
; Address: 0x9FCC2A
; Called from boot sequence to check for and perform flash updates
; =============================================================================
Boot_FlashUpdate_Main:
	db	0D7h, 0FAh, 004h		; PUSH QIZ
	db	01Dh, 063h, 0ECh, 0FFh		; CALL 0xFFEC63 - check disk present
	db	0CFh, 0D8h			; CP L, 0
	db	076h, 0C1h, 000h		; JRL Z, .update_done - no disk

	; Initialize FDC and detect disk type
	db	01Eh, 0CEh, 0F2h		; CALR 0x9FBF07 (FDC_Init)
	db	01Eh, 088h, 0F3h		; CALR Boot_DetectDiskType
	db	0C7h, 0FBh, 09Fh		; LD QIZH, L - save disk type

	; Check region code
	db	01Dh, 000h, 0B7h, 0FFh		; CALL 0xFFB700 (Boot_Get_Region_Code)
	db	0CFh, 0DCh			; CP L, 4
	JR	Z, .update_check_flash		; 66 58

	; Check flash ID
	db	01Dh, 06Ah, 0BCh, 0FFh		; CALL 0xFFBC6A
	db	0EBh, 0CFh, 0FFh, 0FFh, 0FFh, 0FFh	; CP XHL, 0xFFFFFFFF
	JR	Z, .update_check_flash		; 66 4c

	; Check disk type 6 (skip for type 6)
	db	0C7h, 0FBh, 0DEh		; CP QIZH, 6
	JR	Z, .update_check_flash		; 66 47

	; Display "Flash Memory Update" message
	db	00Bh, 008h, 000h		; PUSH 0x0008 - color
	db	00Bh, 002h, 000h		; PUSH 0x0002 - mode
	db	040h, 056h, 0A1h, 0FFh, 000h	; LD XWA, 0x00FFA156 - bitmap addr
	db	031h, 030h, 000h		; LD BC, 0x0030 - X
	db	032h, 050h, 000h		; LD DE, 0x0050 - Y
	db	01Dh, 0FBh, 0CCh, 0FFh		; CALL Draw_Bitmap

	; Execute disk type handler
	db	0C7h, 0FBh, 089h		; LD A, QIZH
	db	0D8h, 012h			; EXTZ WA
	db	01Eh, 096h, 0F7h		; CALR Boot_LoadDiskData

	; Display "Completed" message
	db	00Bh, 008h, 000h		; PUSH 0x0008
	db	00Bh, 001h, 000h		; PUSH 0x0001
	db	040h, 08Eh, 0A8h, 0FFh, 000h	; LD XWA, 0x00FFA88E
	db	031h, 030h, 000h		; LD BC, 0x0030
	db	032h, 0A0h, 000h		; LD DE, 0x00A0
	db	01Dh, 0FBh, 0CCh, 0FFh		; CALL Draw_Bitmap

	; Display "Turn On Again" message
	db	00Bh, 008h, 000h		; PUSH 0x0008
	db	00Bh, 001h, 000h		; PUSH 0x0001
	db	040h, 02Eh, 0B2h, 0FFh, 000h	; LD XWA, 0x00FFB22E
	db	031h, 030h, 000h		; LD BC, 0x0030
	db	032h, 0C8h, 000h		; LD DE, 0x00C8
	db	01Dh, 0FBh, 0CCh, 0FFh		; CALL Draw_Bitmap

.update_check_flash:
	; Read flash ID with bank 2
	db	0D8h, 0AAh			; LD WA, 2
	db	01Dh, 088h, 0B8h, 0FFh		; CALL 0xFFB888 (Flash_ReadID_16bit)
	db	0DBh, 0CFh, 0FFh, 0FFh		; CP HL, 0xFFFF
	JR	Z, .update_done			; 66 4c

	; Only proceed if disk type 6
	db	0C7h, 0FBh, 0DEh		; CP QIZH, 6
	JR	NZ, .update_done		; 6e 47

	; Display update messages and perform update
	db	00Bh, 008h, 000h		; PUSH 0x0008
	db	00Bh, 002h, 000h		; PUSH 0x0002
	db	040h, 056h, 0A1h, 0FFh, 000h	; LD XWA, 0x00FFA156
	db	031h, 030h, 000h		; LD BC, 0x0030
	db	032h, 050h, 000h		; LD DE, 0x0050
	db	01Dh, 0FBh, 0CCh, 0FFh		; CALL Draw_Bitmap

	db	0C7h, 0FBh, 089h		; LD A, QIZH
	db	0D8h, 012h			; EXTZ WA
	db	01Eh, 03Eh, 0F7h		; CALR Boot_LoadDiskData

	db	00Bh, 008h, 000h		; PUSH 0x0008
	db	00Bh, 001h, 000h		; PUSH 0x0001
	db	040h, 08Eh, 0A8h, 0FFh, 000h	; LD XWA, 0x00FFA88E
	db	031h, 030h, 000h		; LD BC, 0x0030
	db	032h, 0A0h, 000h		; LD DE, 0x00A0
	db	01Dh, 0FBh, 0CCh, 0FFh		; CALL Draw_Bitmap

	db	00Bh, 008h, 000h		; PUSH 0x0008
	db	00Bh, 001h, 000h		; PUSH 0x0001
	db	040h, 02Eh, 0B2h, 0FFh, 000h	; LD XWA, 0x00FFB22E
	db	031h, 030h, 000h		; LD BC, 0x0030
	db	032h, 0C8h, 000h		; LD DE, 0x00C8
	db	01Dh, 0FBh, 0CCh, 0FFh		; CALL Draw_Bitmap

.update_done:
	db	0D7h, 0FAh, 005h		; POP QIZ
	RET					; 0e

; =============================================================================
; Draw_Bitmap - Render 1-bit bitmap to VGA framebuffer
; Address: 0x9FCCFB
; Stack params: XWA=bitmap addr, BC=X pos, DE=Y pos, +4=mode, +6=color
; VGA framebuffer at 0x1A0000
; =============================================================================
Draw_Bitmap:
	db	0EFh, 06Ch			; DEC 4, XSP - allocate 4 bytes
	PUSH	IZ				; 2e
	db	0D9h, 08Bh			; LD HL, BC - save X
	db	0BFh, 002h, 060h		; LD (XSP+0x02), XWA - bitmap addr
	db	0DBh, 08Dh			; LD IY, HL - IY = X position
	db	0DAh, 08Ch			; LD IX, DE - IX = Y position
	db	0DCh, 061h			; INC 1, IX - Y + 1
	db	0DEh, 0A8h			; LD IZ, 0 - row counter

.db_row_loop:
	db	0DEh, 088h			; LD WA, IZ
	db	0E8h, 012h			; EXTZ XWA
	db	0D8h, 00Ah, 01Ch, 000h		; DIV WA, 0x001C - 28 bytes per row
	db	0D7h, 0E2h, 088h		; LD WA, QWA - get remainder
	db	0D8h, 0D8h			; CP WA, 0
	JR	NZ, .db_not_row_start		; 6e 04
	db	0DBh, 08Dh			; LD IY, HL - reset X to start
	db	0DCh, 069h			; DEC 1, IX - decrement Y

.db_not_row_start:
	db	0D7h, 0EEh, 0A8h		; LD QHL, 0 - bit counter
	db	0DEh, 08Ah			; LD DE, IZ
	db	0EAh, 012h			; EXTZ XDE
	db	0AFh, 002h, 082h		; ADD XDE, (XSP+0x02) - bitmap offset
	db	0F1h, 044h, 010h, 030h		; LDA XWA, 0x1044
	db	0D7h, 0EEh, 089h		; LD BC, QHL
	db	0E9h, 012h			; EXTZ XBC
	db	0E8h, 081h			; ADD XBC, XWA
	db	081h, 021h			; LD A, (XBC) - get bitmask byte
	db	082h, 0C1h			; AND A, (XDE) - mask with bitmap data
	db	0C7h, 0F2h, 099h		; LD QIXL, A

.db_calc_addr:
	db	0DCh, 08Ah			; LD DE, IX - Y position
	db	0EAh, 012h			; EXTZ XDE
	db	0F2h, 000h, 03Ch, 004h, 031h	; LDA XBC, 0x043C00 - VGA base
	db	0EAh, 088h			; LD XWA, XDE
	db	0E8h, 0EEh, 002h		; SLL 2, XWA - Y * 4
	db	0EAh, 080h			; ADD XWA, XDE - Y * 5
	db	0E8h, 0EEh, 006h		; SLL 6, XWA - Y * 320

	; Check if bit set (foreground or background)
	db	0C7h, 0F2h, 0D8h		; CP QIXL, 0
	JR	Z, .db_background		; 66 13

	; Foreground pixel
	db	0DDh, 08Ah			; LD DE, IY
	db	0DDh, 061h			; INC 1, IY
	db	0EAh, 012h			; EXTZ XDE
	db	0EAh, 080h			; ADD XWA, XDE - add X offset
	db	0E9h, 08Ah			; LD XDE, XBC
	db	0E8h, 082h			; ADD XDE, XWA - final framebuffer addr
	db	08Fh, 00Ah, 021h		; LD A, (XSP+0x0A) - foreground color
	db	0B2h, 041h			; LD (XDE), A
	JR	T, .db_next_bit			; 68 11

.db_background:
	db	0DDh, 08Ah			; LD DE, IY
	db	0DDh, 061h			; INC 1, IY
	db	0EAh, 012h			; EXTZ XDE
	db	0EAh, 080h			; ADD XWA, XDE
	db	0E9h, 08Ah			; LD XDE, XBC
	db	0E8h, 082h			; ADD XDE, XWA
	db	08Fh, 00Ch, 021h		; LD A, (XSP+0x0C) - background color
	db	0B2h, 041h			; LD (XDE), A

.db_next_bit:
	db	0D7h, 0EEh, 061h		; INC 1, QHL
	db	0D7h, 0EEh, 0CFh, 008h, 000h	; CP QHL, 0x0008 - 8 bits per byte
	JR	C, .db_calc_addr		; 67 a1

	; Next row byte
	db	0DEh, 061h			; INC 1, IZ
	db	0DEh, 0CFh, 068h, 002h		; CP IZ, 0x0268 - 616 bytes total
	JR	C, .db_row_loop			; 67 83

	; Flush VGA display
	db	0F2h, 000h, 000h, 01Ah, 030h	; LDA XWA, 0x1A0000
	db	032h, 000h, 096h		; LD DE, 0x9600 - framebuffer size
	db	01Dh, 00Fh, 0FBh, 0FFh		; CALL 0xFFFB0F

	POP	IZ				; 4e
	db	0EFh, 064h			; INC 4, XSP
	db	00Fh, 004h, 000h		; RETD 0x0004

; =============================================================================
; Init_Display_Progress - Initialize progress display bar
; Address: 0x9FCD9A
; Stack params: WA=start value, BC=X pos, DE=mode, E=bar width
; Writes to VGA framebuffer at 0x1A0000
; =============================================================================
Init_Display_Progress:
	db	0EFh, 06Eh			; DEC 6, XSP
	PUSH	XIZ				; 3e
	db	0BFh, 006h, 045h		; LD (XSP+0x06), E
	db	0BFh, 008h, 050h		; LD (XSP+0x08), WA
	db	0D9h, 08Ch			; LD IX, BC
	db	0BFh, 004h, 051h		; LD (XSP+0x04), BC
	db	09Fh, 004h, 038h, 00Ch, 000h	; ADD (XSP+0x04), 0x000C - X + 12
	db	09Fh, 004h, 0F4h		; CP IX, (XSP+0x04)
	JR	NC, .idp_done			; 6f 46

.idp_x_loop:
	db	09Fh, 008h, 025h		; LD IY, (XSP+0x08)
	db	0DDh, 089h			; LD BC, IY
	db	0D9h, 066h			; INC 6, BC - IY + 6
	db	0D9h, 0F5h			; CP IY, BC
	JR	NC, .idp_next_x			; 6f 34

.idp_y_loop:
	db	0DDh, 08Ah			; LD DE, IY
	db	0EAh, 012h			; EXTZ XDE
	db	0DCh, 088h			; LD WA, IX
	db	0E8h, 012h			; EXTZ XWA
	db	0E8h, 08Bh			; LD XHL, XWA
	db	0EBh, 0EEh, 002h		; SLL 2, XHL
	db	0E8h, 083h			; ADD XHL, XWA
	db	0EBh, 0EEh, 006h		; SLL 6, XHL - Y * 320
	db	0EAh, 083h			; ADD XHL, XDE
	db	0EBh, 0EFh, 001h		; SRL 1, XHL - word align
	db	0EBh, 083h			; ADD XHL, XHL
	db	046h, 000h, 000h, 01Ah, 000h	; LD XIZ, 0x001A0000
	db	0EBh, 086h			; ADD XIZ, XHL
	db	08Fh, 006h, 021h		; LD A, (XSP+0x06)
	db	0D8h, 012h			; EXTZ WA
	db	0D8h, 08Ah			; LD DE, WA
	db	0DAh, 0EEh, 008h		; SLL 8, DE
	db	0DAh, 0E0h			; OR WA, DE - duplicate byte
	db	0B6h, 050h			; LD (XIZ), WA

	db	0DDh, 062h			; INC 2, IY
	db	0D9h, 0F5h			; CP IY, BC
	JR	C, .idp_y_loop			; 67 cc

.idp_next_x:
	db	0DCh, 061h			; INC 1, IX
	db	09Fh, 004h, 0F4h		; CP IX, (XSP+0x04)
	JR	C, .idp_x_loop			; 67 ba

.idp_done:
	POP	XIZ				; 5e
	db	0EFh, 066h			; INC 6, XSP
	RET					; 0e

; =============================================================================
; VGA Helper Routines and Constants
; =============================================================================

; VGA Constants (shared with maincpu)
	include "../shared/vga_constants.asm"

; Additional constants for VGA init
OFFSCREEN_BUFFER_1	EQU 043c00h	; Offscreen video buffer

; Memory routines in high RAM (boot code is copied there during update)
BootRAM_MemoryFill	EQU 0FFFB18h	; Fill memory with pattern
BootRAM_MemoryCopy	EQU 0FFFB0Fh	; Copy memory block

; =============================================================================
; VGA Register I/O Routines - Shared with maincpu ROM
; Address: 0x9FCDFC-0x9FCE1D (34 bytes)
; =============================================================================
	include "../shared/vga_io.asm"

; =============================================================================
; VGA_Init - VGA Register Initialization (Shared with maincpu)
; Address: 0x9FCE1E-0x9FD7E7 (2506 bytes)
;
; Extensive initialization of VGA hardware registers using shared code.
; The VGA controller is memory-mapped at 0x170000 for I/O ports.
; Framebuffer is at 0x1A0000 (320x240, 8bpp).
; =============================================================================
	include "../shared/vga_init.asm"

	; === ROM-specific ending: initialize video buffers ===
	; (Boot code runs from high RAM, so these are absolute calls)
	CALL BootRAM_MemoryFill
	LDA XWA, VIDEO_RAM_BASE
	LD XBC, OFFSCREEN_BUFFER_1
	LD DE, 320 * 240 / 2
	CALL BootRAM_MemoryCopy

	; Turn screen on (RET_VGA_SEQUENCER 01h, 001h with JRL optimization)
	VGA_WRITE VGA_SEQ_ADDR, 01h
	LDW WA, VGA_SEQ_DATA
	LDW BC, 001h
	JRL T, Write_VGA_Register

; Small utility routine at 0x9FD7E2 (table_data specific, not in maincpu)
; Purpose unknown - possibly initialization/cleanup
VGA_Init_Epilogue:
	LD (XWA), 000h
	LDW HL, 0
	RET

; =============================================================================
; FDC HELPER ROUTINES (0x9FD7E8-0x9FD8A4)
; Low-level FDC register access at 0x110000
; =============================================================================

; -----------------------------------------------------------------------------
; FDC_ReadStatus - Read FDC main status register
; Address: 0x9FD7E8
; Returns: L = status byte from 0x110008
; -----------------------------------------------------------------------------
FDC_ReadStatus:
	db	0C2h, 008h, 000h, 011h, 027h	; LD L, (0x110008)
	RET					; 0e

; -----------------------------------------------------------------------------
; FDC_ReadData - Read FDC data register
; Address: 0x9FD7EE
; Returns: L = data byte from 0x11000A
; -----------------------------------------------------------------------------
FDC_ReadData:
	db	0C2h, 00Ah, 000h, 011h, 027h	; LD L, (0x11000A)
	RET					; 0e

; -----------------------------------------------------------------------------
; FDC_WriteStatus - Write to FDC status register
; Address: 0x9FD7F4
; Input: A = value to write
; -----------------------------------------------------------------------------
FDC_WriteStatus:
	db	0F2h, 008h, 000h, 011h, 041h	; LD (0x110008), A
	RET					; 0e

; -----------------------------------------------------------------------------
; FDC_SaveCommand - Save command to history buffer
; Address: 0x9FD7FA
; Saves current command at 0x0D50 to 0x0D4E, stores new command
; -----------------------------------------------------------------------------
FDC_SaveCommand:
	db	0C1h, 050h, 00Dh, 019h, 04Eh, 00Dh	; LD (0x0D4E), (0x0D50)
	db	0F1h, 050h, 00Dh, 041h		; LD (0x0D50), A
	RET					; 0e

; -----------------------------------------------------------------------------
; FDC_WriteData - Write to FDC data register
; Address: 0x9FD805
; Input: A = value to write
; -----------------------------------------------------------------------------
FDC_WriteData:
	db	0F2h, 00Ah, 000h, 011h, 041h	; LD (0x11000A), A
	RET					; 0e

; -----------------------------------------------------------------------------
; FDC_WaitReady - Wait for FDC ready (RQM bit)
; Address: 0x9FD80B
; Polls status register until ready or timeout
; Returns via FDC_Error (0x9FE231) on timeout
; -----------------------------------------------------------------------------
FDC_WaitReady:
	PUSH	XIZ				; 3e
	db	0D1h, 000h, 00Ch, 026h		; LD IZ, (0x0C00) - get timer
	db	0D7h, 0FAh, 003h, 080h, 000h	; LD QIZ, 0x0080 - flag = pending

.fwr_check:
	db	0D7h, 0FAh, 0CFh, 080h, 000h	; CP QIZ, 0x0080
	JR	NZ, .fwr_check_result		; 6e 29
.fwr_loop:
	db	01Eh, 0C9h, 0FFh		; CALR FDC_ReadStatus
	db	0CFh, 0CCh, 01Fh		; AND L, 0x1F - mask status bits
	db	0CFh, 089h			; LD A, L
	db	0D8h, 012h			; EXTZ WA
	db	0D8h, 0D8h			; CP WA, 0 - check if ready
	JR	NZ, .fwr_not_ready		; 6e 03
	db	0D7h, 0FAh, 0A8h		; LD QIZ, 0 - flag = success

.fwr_not_ready:
	db	0D1h, 000h, 00Ch, 020h		; LD WA, (0x0C00)
	db	0DEh, 0A0h			; SUB WA, IZ
	db	0D8h, 0CFh, 0F4h, 001h		; CP WA, 0x01F4 (500) - timeout
	JR	ULE, .fwr_continue		; 63 05
	db	0D7h, 0FAh, 003h, 0FFh, 0FFh	; LD QIZ, 0xFFFF - flag = timeout

.fwr_continue:
	db	0D7h, 0FAh, 0CFh, 080h, 000h	; CP QIZ, 0x0080
	JR	Z, .fwr_loop			; 66 d7

.fwr_check_result:
	db	0D7h, 0FAh, 0D8h		; CP QIZ, 0
	JR	Z, .fwr_done			; 66 05
	db	0D8h, 0A9h			; LD WA, 1 - error code
	db	01Eh, 0E2h, 009h		; CALR 0x9FE231 (FDC_Error)

.fwr_done:
	POP	XIZ				; 5e
	RET					; 0e

; -----------------------------------------------------------------------------
; FDC_WaitComplete - Wait for FDC command complete
; Address: 0x9FD851
; Polls for DIO and RQM bits set (0x90)
; -----------------------------------------------------------------------------
FDC_WaitComplete:
	PUSH	XIZ				; 3e
	db	0D1h, 000h, 00Ch, 026h		; LD IZ, (0x0C00)
	db	0D7h, 0FAh, 003h, 080h, 000h	; LD QIZ, 0x0080

.fwc_check:
	db	0D7h, 0FAh, 0CFh, 080h, 000h	; CP QIZ, 0x0080
	JR	NZ, .fwc_check_result		; 6e 26
.fwc_loop:
	db	01Eh, 083h, 0FFh		; CALR FDC_ReadStatus
	db	0CFh, 0CCh, 090h		; AND L, 0x90 - mask DIO+RQM
	db	0CFh, 0CFh, 090h		; CP L, 0x90 - both set?
	JR	NZ, .fwc_not_done		; 6e 03
	db	0D7h, 0FAh, 0A8h		; LD QIZ, 0 - success

.fwc_not_done:
	db	0D1h, 000h, 00Ch, 020h		; LD WA, (0x0C00)
	db	0DEh, 0A0h			; SUB WA, IZ
	db	0D8h, 0CFh, 0F4h, 001h		; CP WA, 0x01F4 - timeout
	JR	ULE, .fwc_continue		; 63 05
	db	0D7h, 0FAh, 003h, 0FFh, 0FFh	; LD QIZ, 0xFFFF

.fwc_continue:
	db	0D7h, 0FAh, 0CFh, 080h, 000h	; CP QIZ, 0x0080
	JR	Z, .fwc_loop			; 66 da

.fwc_check_result:
	db	0D7h, 0FAh, 0D8h		; CP QIZ, 0
	JR	Z, .fwc_done			; 66 05
	db	0D8h, 0A9h			; LD WA, 1
	db	01Eh, 09Fh, 009h		; CALR 0x9FE231

.fwc_done:
	POP	XIZ				; 5e
	RET					; 0e

; -----------------------------------------------------------------------------
; FDC_Seek - Send seek command
; Address: 0x9FD894
; Sends seek command 0x36 to FDC, delays for motor spinup
; -----------------------------------------------------------------------------
FDC_Seek:
	db	030h, 036h, 000h		; LD WA, 0x0036 - SEEK command
	db	01Eh, 05Ah, 0FFh		; CALR FDC_WriteStatus
	db	0D8h, 0AAh			; LD WA, 2 - delay parameter
	db	01Eh, 0F7h, 009h		; CALR 0x9FE296 (delay routine)
	db	0F1h, 032h, 00Dh, 000h, 0FFh	; LD (0x0D32), 0xFF - set flag
	RET					; 0e

; =============================================================================
; Flash Update Type Handlers
; Address: 0x9FD8A5-0x9FEA9C (4600 bytes)
;
; These handlers process different firmware update disk types:
;   Type 1: Table Data disk 1 of 2
;   Type 2: Table Data disk 2 of 2
;   Type 3: Custom Data flash update
;   Type 4: HDAE5000 expansion ROM
;   Type 5: Compressed program ROM
;   Type 6: Compressed table data ROM
;   Type 7: Combined update disk 1
;   Type 8: Combined update disk 2
;
; Each handler:
;   - Validates disk format and checksums
;   - Erases appropriate flash sectors
;   - Programs new firmware data
;   - Updates progress display
; =============================================================================
	binclude "includes/bootcode_flash_handlers.bin"

; =============================================================================
; Handler_INTTC3 - Timer Counter 3 Interrupt Handler
; Address: 0x9FEA9D (boot-time: 0xFFEA9D)
;
; Simple system tick handler:
;   - Saves all registers
;   - Calls Boot_TimerTick (0x9FDD17) to increment system timer
;   - Calls Boot_UpdateDisplay (0x9FDD26) to refresh VGA display
;   - Restores registers and returns from interrupt
; =============================================================================
Handler_INTTC3:
	PUSH	XIZ				; 3e - save all registers
	PUSH	XIY				; 3d
	PUSH	XIX				; 3c
	PUSH	XHL				; 3b
	PUSH	XDE				; 3a
	PUSH	XBC				; 39
	PUSH	XWA				; 38
	db	01Eh, 070h, 0F2h		; CALR Boot_TimerTick (0x9FDD17)
	db	01Eh, 07Ch, 0F2h		; CALR Boot_UpdateDisplay (0x9FDD26)
	POP	XWA				; 58 - restore all registers
	POP	XBC				; 59
	POP	XDE				; 5a
	POP	XHL				; 5b
	POP	XIX				; 5c
	POP	XIY				; 5d
	POP	XIZ				; 5e
	RETI					; 07

; =============================================================================
; Handler_INT4 - FDC (Floppy Disk Controller) Interrupt Handler
; Address: 0x9FEAB2 (boot-time: 0xFFEAB2)
;
; Handles FDC interrupt during firmware update:
;   - Timeout counter (100 iterations max)
;   - Polls FDC status for RQM (bit 7) and DIO (bit 6)
;   - Reads result bytes from FDC data register
;   - Stores results at 0x0C8E buffer
;   - Calls FDC_ProcessResults (0x9FDF17) when complete
; =============================================================================
Handler_INT4:
	PUSH	XIZ				; 3e
	PUSH	XIY				; 3d
	PUSH	XIX				; 3c
	PUSH	XHL				; 3b
	PUSH	XDE				; 3a
	PUSH	XBC				; 39
	PUSH	XWA				; 38
	db	0DEh, 0A8h			; LD IZ, 0 - timeout counter

.int4_check_timeout:
	db	0DEh, 088h			; LD WA, IZ - get current count
	db	0DEh, 061h			; INC 1, IZ
	db	0D8h, 0CFh, 064h, 000h		; CP WA, 0x0064 (100)
	JR	GT, .int4_done			; 6a 59 - timeout exceeded

	db	01Eh, 020h, 0EDh		; CALR FDC_ReadStatus (0x9FD7E8)
	db	0CFh, 033h, 007h		; BIT 7, L - check RQM (request for master)
	JR	Z, .int4_check_timeout		; 66 ee - not ready, keep polling

.int4_wait_rqm:
	db	01Eh, 018h, 0EDh		; CALR FDC_ReadStatus
	db	0CFh, 033h, 007h		; BIT 7, L
	JR	Z, .int4_wait_rqm		; 66 f8

	db	01Eh, 010h, 0EDh		; CALR FDC_ReadStatus
	db	0CFh, 033h, 006h		; BIT 6, L - check DIO (data direction)
	JR	NZ, .int4_setup_buffer		; 6e 18 - FDC has data for us

	; FDC needs data from us - send sense interrupt command
	db	027h, 000h			; LD L, 0x00
	db	0CFh, 0CFh, 080h		; CP L, 0x80
	JR	Z, .int4_send_cmd		; 66 0b

.int4_poll_ready:
	db	01Eh, 001h, 0EDh		; CALR FDC_ReadStatus
	db	0CFh, 0CCh, 0F0h		; AND L, 0xF0 - mask status bits
	db	0CFh, 0CFh, 080h		; CP L, 0x80 - RQM set, DIO clear?
	JR	NZ, .int4_poll_ready		; 6e f5

.int4_send_cmd:
	db	030h, 008h, 000h		; LD WA, 0x0008 - sense interrupt command
	db	01Eh, 010h, 0EDh		; CALR FDC_WriteData (0x9FD805)

.int4_setup_buffer:
	db	0F1h, 08Eh, 00Ch, 036h		; LDA XIZ, 0x0C8E - result buffer
	db	0EEh, 061h			; INC 1, XIZ

.int4_read_loop:
	db	01Eh, 0EFh, 0F2h		; CALR Boot_ClearWatchdog (0x9FDDED)
	db	01Eh, 0EDh, 0ECh		; CALR FDC_ReadData (0x9FD7EE)
	db	0F5h, 0F8h, 047h		; LD (XIZ+), L - store result byte

.int4_check_more:
	db	01Eh, 0E1h, 0ECh		; CALR FDC_ReadStatus
	db	0CFh, 033h, 007h		; BIT 7, L - RQM set?
	JR	Z, .int4_check_more		; 66 f8 - wait for ready

	db	01Eh, 0D9h, 0ECh		; CALR FDC_ReadStatus
	db	0CFh, 033h, 006h		; BIT 6, L - DIO set?
	JR	NZ, .int4_read_loop		; 6e e7 - more data to read

	db	01Eh, 000h, 0F4h		; CALR FDC_ProcessResults (0x9FDF17)
	db	0C1h, 08Fh, 00Ch, 03Fh, 080h	; CP (0x0C8F), 0x80 - check status
	JR	NZ, .int4_wait_rqm		; 6e af - not done, continue

.int4_done:
	db	0F1h, 08Eh, 00Ch, 000h, 000h	; LD (0x0C8E), 0x0000 - clear buffer
	POP	XWA				; 58
	POP	XBC				; 59
	POP	XDE				; 5a
	POP	XHL				; 5b
	POP	XIX				; 5c
	POP	XIY				; 5d
	POP	XIZ				; 5e
	RETI					; 07

; =============================================================================
; Boot ROM Utility Routines
; Address: 0x9FEB2B-0x9FF228 (1790 bytes)
;
; Contains various utility routines:
;   - Motor control timing
;   - VGA display routines for update UI
;   - Disk format detection helpers
;   - Progress bar updates
; =============================================================================
	binclude "includes/bootcode_utils.bin"

; =============================================================================
; Serial Port Interrupt Handlers
; Address: 0x9FF229-0x9FF2F1 (201 bytes)
;
; Handler_INTA (0x9FF229): External interrupt A - Serial handshake
;   - Checks serial state at (0x0F63)
;   - Initializes receive mode or updates buffer pointer
;
; Handler_INTTX1 (0x9FF2AE): Serial TX complete
;   - Dispatches to state handler via table at 0xFFF282
;
; Handler_INTRX1 (0x9FF2D0): Serial RX received
;   - Dispatches to state handler via same table
; =============================================================================
	ORG 09FF229h
Handler_INTA:
	binclude "includes/bootcode_serial_handlers.bin"

; =============================================================================
; Serial Communication State Machine
; Address: 0x9FF2F2-0x9FFB55 (2148 bytes)
;
; State machine for handling serial protocol:
;   - Baud rate configuration
;   - Packet framing and checksums
;   - Error recovery
; =============================================================================
	binclude "includes/bootcode_serial_state.bin"

; =============================================================================
; Memory Allocation, Division, and Debug Routines
; Address: 0x9FFB56-0x9FFEE0 (906 bytes)
;
; MEMORY ALLOCATION (linked-list heap):
;   0x9FFB56: Boot_malloc - Allocate memory block
;             - Free list head at 0x0099A0
;             - Block header: +0x00=next ptr, +0x04=size
;             - Returns pointer to data area (+0x06)
;   0x9FFCDD: Boot_free - Free allocated block
;             - Merges adjacent free blocks
;   0x9FFD7D: Secondary heap routines (pool at 0x009998)
;
; UTILITY FUNCTIONS:
;   0x9FFBDC: Boot_memcmp - Compare memory blocks
;   0x9FFC0E: Division/modulo routines (32-bit and 64-bit)
;
; DEBUG OUTPUT:
;   0x9FFE80: Debug_OutputChar - Output single character
;   0x9FFE86: Debug_OutputHexByte - Output byte as 2-digit hex
;   0x9FFEA1: Debug_OutputString - Output null-terminated string
;   0x9FFEB4: Debug_NibbleToHex - Convert nibble to ASCII hex
;   0x9FFEC1: Debug_SendChar - Send char to debug port (0xFE00)
; =============================================================================
	binclude "includes/bootcode_malloc_and_after.bin"

	ORG 09FFEE0h
RESET_HANDLER:
	JP BOOT_ENTRY
	RET			; Dead code (never reached, but present in ROM)

; Reserved area between RESET_HANDLER and interrupt vector table
	db 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh	; Padding
	db 000h, 000h, 000h, 004h, 000h, 000h, 000h		; Reserved entry 1?
	db 004h, 000h, 000h, 000h				; Reserved entry 2?
	db 004h, 000h, 000h, 000h				; Reserved entry 3?
	db 004h, 000h, 000h					; Partial entry



	ORG 09FFF00h

; TMP94C241F Interrupt Vector Table
; These addresses are what the CPU sees at boot time (ROM at 0xE00000)

	dd BOOT_RESET_HANDLER	; RESET

	dd BOOT_EMPTY_HANDLER	; SWI 1
	dd BOOT_EMPTY_HANDLER	; SWI 2
	dd BOOT_EMPTY_HANDLER	; SWI 3
	dd BOOT_EMPTY_HANDLER	; SWI 4
	dd BOOT_EMPTY_HANDLER	; SWI 5
	dd BOOT_EMPTY_HANDLER	; SWI 6
	dd BOOT_EMPTY_HANDLER	; SWI 7

	dd BOOT_NMI_HANDLER	; NMI

	dd BOOT_EMPTY_HANDLER	; INTWD (watchdog)
	dd BOOT_EMPTY_HANDLER	; INT0 Pin

	dd BOOT_INT4_HANDLER	; INT4 Pin

	dd BOOT_EMPTY_HANDLER	; INT5 Pin
	dd BOOT_EMPTY_HANDLER	; INT6 Pin
	dd BOOT_EMPTY_HANDLER	; INT7 Pin
	dd BOOT_EMPTY_HANDLER	; (RESERVED)
	dd BOOT_EMPTY_HANDLER	; INT8 Pin
	dd BOOT_EMPTY_HANDLER	; INT9 Pin

	dd BOOT_INTA_HANDLER	; INTA Pin

	dd BOOT_EMPTY_HANDLER	; INTB Pin
	dd BOOT_EMPTY_HANDLER	; INTT0

	dd BOOT_INTT1_HANDLER	; INTT1

	dd BOOT_EMPTY_HANDLER	; INTT2
	dd BOOT_EMPTY_HANDLER	; INTT3
	dd BOOT_EMPTY_HANDLER	; INTTR4
	dd BOOT_EMPTY_HANDLER	; INTTR5
	dd BOOT_EMPTY_HANDLER	; INTTR6
	dd BOOT_EMPTY_HANDLER	; INTTR7
	dd BOOT_EMPTY_HANDLER	; INTTR8
	dd BOOT_EMPTY_HANDLER	; INTTR9
	dd BOOT_EMPTY_HANDLER	; INTTRA
	dd BOOT_EMPTY_HANDLER	; INTTRB
	dd BOOT_EMPTY_HANDLER	; INTRX0
	dd BOOT_EMPTY_HANDLER	; INTTX0

	dd BOOT_INTRX1_HANDLER	; INTRX1
	dd BOOT_INTTX1_HANDLER	; INTTX1

	dd BOOT_EMPTY_HANDLER	; INTAD
	dd BOOT_EMPTY_HANDLER	; INTTC0
	dd BOOT_EMPTY_HANDLER	; INTTC1
	dd BOOT_EMPTY_HANDLER	; INTTC2

	dd BOOT_INTTC3_HANDLER	; INTTC3

	dd BOOT_EMPTY_HANDLER	; INTTC4
	dd BOOT_EMPTY_HANDLER	; INTTC5
	dd BOOT_EMPTY_HANDLER	; INTTC6
	dd BOOT_EMPTY_HANDLER	; INTTC7

; RESERVED:
	db 12 dup (0FFh)
	db "hkt_87.ssf", 0
	db 5 dup (0)
; RESERVED:
	db 030h dup (0FFh)
