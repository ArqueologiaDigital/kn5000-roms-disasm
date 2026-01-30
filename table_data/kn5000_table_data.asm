	cpu	96c141	; Actual CPU is 94c241f
	page	0
	maxmode	on
	include "../tmp94c241.inc"

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

Bitmap_1bit_Now_Erasing:		;
	binclude "../maincpu/images/Bitmap_1bit_Now_Erasing.bin"

Bitmap_1bit_FD_to_Flash_Memory:		;
	binclude "../maincpu/images/Bitmap_1bit_FD_to_Flash_Memory.bin"

Bitmap_1bit_Completed:			;
	binclude "../maincpu/images/Bitmap_1bit_Completed.bin"

Bitmap_1bit_Please_Wait:		;
	binclude "../maincpu/images/Bitmap_1bit_Please_Wait.bin"

Bitmap_1bit_Change_FD_2_of_2:		;
	binclude "../maincpu/images/Bitmap_1bit_Change_FD_2_of_2.bin"

Bitmap_1bit_Illegal_Disk:		;
	binclude "../maincpu/images/Bitmap_1bit_Illegal_Disk.bin"

Bitmap_1bit_Turn_On_AGAIN:		;
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


	ORG 09FB4E8h
; -----------------------------------------------------------------------------
; Boot_Init - First-stage bootloader entry point
; Initializes CPU, memory controller, and hands off to main program ROM
; See original_ROMs/table_data_bootcode.unidasm for detailed disassembly
; -----------------------------------------------------------------------------
Boot_Init:
	binclude "includes/bootcode_init.bin"

	ORG 09FB705h
EMPTY_HANDLER:
	RETI

; After RETI, there's JRL back to Boot_Init for watchdog reset scenarios
	JRL	T, Boot_Init		; Jump relative long back to boot entry

; -----------------------------------------------------------------------------
; Boot routines: flash update, hardware init, display, FDC, etc.
; Addresses 0x9FB709 to 0x9FFEE0 (includes all interrupt handlers)
;
; Interrupt handler addresses within this range:
;   NMI_HANDLER    = 0x9FB7FB (offset 0x0F2 in bootcode_routines.bin)
;   INTT1_HANDLER  = 0x9FB7F2 (offset 0x0E9)
;   INTTC3_HANDLER = 0x9FEA9D (offset 0x3394)
;   INT4_HANDLER   = 0x9FEAB2 (offset 0x33A9)
;   INTA_HANDLER   = 0x9FF229 (offset 0x3B20)
;   INTTX1_HANDLER = 0x9FF2AE (offset 0x3BA5)
;   INTRX1_HANDLER = 0x9FF2D0 (offset 0x3BC7)
; -----------------------------------------------------------------------------
	binclude "includes/bootcode_routines.bin"

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
