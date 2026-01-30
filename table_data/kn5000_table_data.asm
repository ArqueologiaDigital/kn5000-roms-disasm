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

; -----------------------------------------------------------------------------
; TMP94C241F Special Function Register Definitions (for boot code)
; -----------------------------------------------------------------------------
; Port Data Registers
SFR_P0		EQU	000h		; Port 0 Data
SFR_P1		EQU	008h		; Port 1 Data
SFR_P2		EQU	010h		; Port 2 Data
SFR_P3		EQU	018h		; Port 3 Data
SFR_P4		EQU	020h		; Port 4 Data
SFR_P5		EQU	028h		; Port 5 Data
SFR_P6		EQU	030h		; Port 6 Data
SFR_P7		EQU	038h		; Port 7 Data
SFR_P8		EQU	040h		; Port 8 Data
SFR_PE		EQU	068h		; Port E Data
SFR_PH		EQU	080h		; Port H Data

; Port Control Registers (CR = direction, FC = function)
SFR_P0FC	EQU	004h		; Port 0 Function
SFR_P1FC	EQU	00Ch		; Port 1 Function
SFR_P2FC	EQU	014h		; Port 2 Function
SFR_P3FC	EQU	01Ch		; Port 3 Function
SFR_P4CR	EQU	022h		; Port 4 Control
SFR_P4FC	EQU	024h		; Port 4 Function
SFR_P5CR	EQU	02Ah		; Port 5 Control
SFR_P5FC	EQU	02Ch		; Port 5 Function
SFR_P6CR	EQU	032h		; Port 6 Control
SFR_P6FC	EQU	034h		; Port 6 Function
SFR_P7CR	EQU	03Ah		; Port 7 Control
SFR_P7FC	EQU	03Ch		; Port 7 Function
SFR_P8CR	EQU	042h		; Port 8 Control
SFR_P8FC	EQU	044h		; Port 8 Function
SFR_PECR	EQU	06Ah		; Port E Control
SFR_PHCR	EQU	082h		; Port H Control
SFR_PHFC	EQU	084h		; Port H Function

; 8-bit Timer Registers
SFR_T01MOD	EQU	080h		; Timer 0/1 Mode (note: same address as PH)
SFR_TFFCR	EQU	081h		; Timer Flip-Flop Control
SFR_T8RUN	EQU	082h		; 8-bit Timer Run Control
SFR_T23MOD	EQU	088h		; Timer 2/3 Mode
SFR_TREG0	EQU	084h		; Timer 0 Register
SFR_TREG1	EQU	085h		; Timer 1 Register

; 16-bit Timer Registers
SFR_T16RUN	EQU	090h		; 16-bit Timer Run Control
SFR_T4MOD	EQU	098h		; Timer 4 Mode
SFR_T4FFCR	EQU	099h		; Timer 4 Flip-Flop Control
SFR_TREG4	EQU	09Ah		; Timer 4 Register (16-bit)

; Watchdog Timer
SFR_WDMOD	EQU	110h		; Watchdog Mode
SFR_WDCR	EQU	111h		; Watchdog Control

; Memory Controller Registers
SFR_B0CSL	EQU	140h		; Block 0 Control Low
SFR_B0CSH	EQU	141h		; Block 0 Control High
SFR_MAMR0	EQU	142h		; Block 0 Address Mask
SFR_MSAR0	EQU	143h		; Block 0 Start Address
SFR_B1CSL	EQU	144h		; Block 1 Control Low
SFR_B1CSH	EQU	145h		; Block 1 Control High
SFR_MAMR1	EQU	146h		; Block 1 Address Mask
SFR_MSAR1	EQU	147h		; Block 1 Start Address
SFR_B2CSL	EQU	148h		; Block 2 Control Low
SFR_B2CSH	EQU	149h		; Block 2 Control High
SFR_MAMR2	EQU	14Ah		; Block 2 Address Mask
SFR_MSAR2	EQU	14Bh		; Block 2 Start Address
SFR_B3CSL	EQU	14Ch		; Block 3 Control Low
SFR_B3CSH	EQU	14Dh		; Block 3 Control High
SFR_MAMR3	EQU	14Eh		; Block 3 Address Mask
SFR_MSAR3	EQU	14Fh		; Block 3 Start Address
SFR_B4CSL	EQU	150h		; Block 4 Control Low
SFR_B4CSH	EQU	151h		; Block 4 Control High
SFR_MAMR4	EQU	152h		; Block 4 Address Mask
SFR_MSAR4	EQU	153h		; Block 4 Start Address
SFR_B5CSL	EQU	154h		; Block 5 Control Low
SFR_B5CSH	EQU	155h		; Block 5 Control High
SFR_MAMR5	EQU	156h		; Block 5 Address Mask
SFR_MSAR5	EQU	157h		; Block 5 Start Address

; DRAM Controller Registers
SFR_DRAM0CRL	EQU	160h		; DRAM 0 Control Low
SFR_DRAM0CRH	EQU	161h		; DRAM 0 Control High
SFR_DRAM1CRL	EQU	162h		; DRAM 1 Control Low
SFR_DRAM1CRH	EQU	163h		; DRAM 1 Control High
SFR_DRAM0REF	EQU	164h		; DRAM 0 Refresh
SFR_DRAM1REF	EQU	165h		; DRAM 1 Refresh
SFR_PMEMCR	EQU	166h		; Page ROM Control


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
	; === Watchdog Timer Disable ===
	db	0F1h, 010h, 001h, 000h, 000h	; LD (WDMOD), 0x00
	db	0F1h, 011h, 001h, 000h, 0B1h	; LD (WDCR), 0xB1 - disable watchdog

	; === System Clock Setup ===
	db	0F1h, 00Ah, 001h, 000h, 004h	; LD (0x010A), 0x04 - clock config

	; === Port 7 Setup (Control Signals: RD/WR/BUSRQ/BUSAK) ===
	db	008h, 03Ch, 000h		; LD (P7FC), 0x00 - GPIO mode
	db	008h, 03Fh, 073h		; LD (0x3F), 0x73 - extended config
	db	008h, 03Eh, 015h		; LD (P7CR), 0x15 - direction
	db	0C0h, 02Ch, 03Ch, 0F0h		; AND (P5FC), 0xF0 - mask lower nibble
	db	0F0h, 020h, 0B3h		; RES 3, (P4) - clear bit 3
	db	0F0h, 03Ch, 0B2h		; RES 2, (P7FC) - clear bit 2

	; === Port 0-3 Setup (Data Bus D0-D31) ===
	db	008h, 00Bh, 0FFh		; LD (P0FC+7?), 0xFF - Port 0 to data bus
	db	008h, 00Fh, 0FFh		; LD (P1FC+3?), 0xFF - Port 1 to data bus
	db	008h, 01Ch, 0FFh		; LD (P3FC), 0xFF - Port 3 to data bus
	db	008h, 01Fh, 01Fh		; LD (0x1F), 0x1F - extended config
	db	008h, 01Eh, 000h		; LD (0x1E), 0x00 - extended config

	; === Port 5 Setup (Address Bus A8-A15) ===
	db	008h, 028h, 0FEh		; LD (P5), 0xFE - data
	db	008h, 02Bh, 008h		; LD (P5CR+1?), 0x08
	db	008h, 02Ch, 0FFh		; LD (P5FC), 0xFF - address bus
	db	008h, 02Fh, 01Fh		; LD (0x2F), 0x1F

	; === Port 6 Setup (Address Bus A16-A23) ===
	db	008h, 030h, 003h		; LD (P6), 0x03
	db	008h, 033h, 000h		; LD (P6CR+1?), 0x00
	db	008h, 032h, 002h		; LD (P6CR), 0x02
	db	008h, 034h, 000h		; LD (P6FC), 0x00
	db	008h, 037h, 006h		; LD (0x37), 0x06
	db	008h, 036h, 011h		; LD (0x36), 0x11
	db	008h, 038h, 000h		; LD (P7), 0x00
	db	008h, 03Bh, 042h		; LD (P7CR+1?), 0x42
	db	008h, 03Ah, 020h		; LD (P7CR), 0x20

	; === Port 8 Setup (Chip Select CS0-CS5) ===
	db	008h, 044h, 000h		; LD (P8FC), 0x00
	db	008h, 047h, 01Eh		; LD (P8FC+3?), 0x1E
	db	008h, 046h, 009h		; LD (P8FC+2?), 0x09

	; === Port E Setup (GPIO) ===
	db	008h, 068h, 0FFh		; LD (PE), 0xFF - all high
	db	008h, 06Ah, 003h		; LD (PECR), 0x03

	; === Port H / 8-bit Timer Setup ===
	db	008h, 084h, 01Dh		; LD (PHFC), 0x1D
	db	008h, 085h, 01Dh		; LD (PHFC+1), 0x1D
	db	008h, 082h, 000h		; LD (PHCR), 0x00
	db	008h, 088h, 00Ah		; LD (T23MOD), 0x0A
	db	008h, 089h, 010h		; LD (T23MOD+1), 0x10
	db	008h, 081h, 000h		; LD (T01MOD/TFFCR), 0x00
	db	0F0h, 080h, 0B9h		; SET 1, (PH) - set bit 1

	; === 16-bit Timer 4 Setup ===
	db	008h, 098h, 005h		; LD (T4MOD), 0x05
	db	008h, 099h, 000h		; LD (T4FFCR), 0x00
	db	008h, 09Fh, 000h		; LD (0x9F), 0x00
	db	00Ah, 090h, 001h, 000h		; LD (T16RUN), 0x0001 - 16-bit word
	db	00Ah, 092h, 009h, 03Dh		; LD (0x92), 0x3D09 - timer value
	db	0F0h, 09Eh, 0BFh		; SET 7, (0x9E)
	db	0F0h, 09Eh, 0B8h		; SET 0, (0x9E)

	; === Memory Controller: Start Address Registers ===
	db	0F1h, 043h, 001h, 000h, 01Eh	; LD (MSAR0), 0x1E - Block 0 @ 0x1E0000
	db	0F1h, 047h, 001h, 000h, 010h	; LD (MSAR1), 0x10 - Block 1 @ 0x100000
	db	0F1h, 04Bh, 001h, 000h, 0C0h	; LD (MSAR2), 0xC0 - Block 2 @ 0xC00000
	db	0F1h, 04Fh, 001h, 000h, 000h	; LD (MSAR3), 0x00 - Block 3 @ 0x000000
	db	0F1h, 053h, 001h, 000h, 080h	; LD (MSAR4), 0x80 - Block 4 @ 0x800000 (TABLE DATA!)
	db	0F1h, 057h, 001h, 000h, 000h	; LD (MSAR5), 0x00 - Block 5 @ 0x000000

	; === Memory Controller: Address Mask Registers ===
	db	0F1h, 042h, 001h, 000h, 00Fh	; LD (MAMR0), 0x0F
	db	0F1h, 046h, 001h, 000h, 03Fh	; LD (MAMR1), 0x3F
	db	0F1h, 04Ah, 001h, 000h, 07Fh	; LD (MAMR2), 0x7F
	db	0F1h, 04Eh, 001h, 000h, 01Fh	; LD (MAMR3), 0x1F
	db	0F1h, 052h, 001h, 000h, 0FFh	; LD (MAMR4), 0xFF
	db	0F1h, 056h, 001h, 000h, 0FFh	; LD (MAMR5), 0xFF

	; === Port 4 GPIO Setup ===
	db	008h, 020h, 03Bh		; LD (P4), 0x3B
	db	008h, 023h, 07Fh		; LD (P4CR+1?), 0x7F
	db	008h, 022h, 03Fh		; LD (P4CR), 0x3F

	; === Delay Loop 1 (short) ===
	db	031h, 000h, 004h		; LD BC, 0x0400
Boot_Delay1:
	db	0D9h, 01Ch, 0FDh		; DJNZ BC, Boot_Delay1 (offset -3)

	; === DRAM Controller Init ===
	db	0F1h, 065h, 001h, 000h, 081h	; LD (DRAM1REF), 0x81 - enable refresh

	; === Delay Loop 2 (longer) ===
	db	031h, 000h, 020h		; LD BC, 0x2000
Boot_Delay2:
	db	0D9h, 01Ch, 0FDh		; DJNZ BC, Boot_Delay2

	; === DRAM Controller Final Config ===
	db	0F1h, 065h, 001h, 000h, 071h	; LD (DRAM1REF), 0x71
	db	0F1h, 062h, 001h, 000h, 08Bh	; LD (DRAM1CRL), 0x8B
	db	0F1h, 063h, 001h, 000h, 058h	; LD (DRAM1CRH), 0x58
	db	0F1h, 066h, 001h, 0B4h		; RES 4, (PMEMCR)

	; === Memory Controller: Wait States (BxCSL) ===
	db	0F1h, 040h, 001h, 000h, 011h	; LD (B0CSL), 0x11 - 2R/2W waits
	db	0F1h, 044h, 001h, 000h, 033h	; LD (B1CSL), 0x33 - 3R/3W waits
	db	0F1h, 048h, 001h, 000h, 011h	; LD (B2CSL), 0x11
	db	0F1h, 04Ch, 001h, 000h, 022h	; LD (B3CSL), 0x22
	db	0F1h, 050h, 001h, 000h, 011h	; LD (B4CSL), 0x11
	db	0F1h, 054h, 001h, 000h, 022h	; LD (B5CSL), 0x22

	; === Memory Controller: Bus Width (BxCSH) ===
	db	0F1h, 041h, 001h, 000h, 080h	; LD (B0CSH), 0x80 - 8-bit bus
	db	0F1h, 045h, 001h, 000h, 081h	; LD (B1CSH), 0x81 - 16-bit bus
	db	0F1h, 049h, 001h, 000h, 0C2h	; LD (B2CSH), 0xC2 - 32-bit bus
	db	0F1h, 04Dh, 001h, 000h, 08Ah	; LD (B3CSH), 0x8A - 16-bit, DRAM mode
	db	0F1h, 051h, 001h, 000h, 082h	; LD (B4CSH), 0x82 - 32-bit bus
	db	0F1h, 055h, 001h, 000h, 081h	; LD (B5CSH), 0x81 - 16-bit bus

	; === Interrupt Setup ===
	db	008h, 0F6h, 000h		; LD (0xF6), 0x00

	; === Stack Pointer Setup ===
	db	0F2h, 07Eh, 098h, 000h, 030h	; LDA XWA, 0x00987E
	db	0E8h, 08Fh			; LD XSP, XWA

	; === Clear RAM Variable ===
	db	0E8h, 0A8h			; LD XWA, 0
	db	0F1h, 000h, 00Ch, 060h		; LD (0x0C00), XWA

	; === Call Boot_ClearRAM ===
	db	01Eh, 00Dh, 001h		; CALR Boot_ClearRAM (at 0xFFB740)

	; === Reload Stack Pointer ===
	db	0F2h, 07Eh, 098h, 000h, 030h	; LDA XWA, 0x00987E
	db	0E8h, 08Fh			; LD XSP, XWA

	; === Enable Interrupts ===
	db	006h, 000h			; EI 0

	; === Detect Boot Mode ===
	db	01Eh, 09Ah, 000h		; CALR Boot_DetectMode (at 0xFFB6D9)

	; === Call Main Hardware Init ===
	db	01Dh, 0F3h, 0BBh, 0FFh		; CALL 0xFFBBF3 (Boot_InitHardware)

	; === Configure Interrupt Enable Register ===
	db	0F0h, 0E4h, 031h		; LDA XBC, 0xE4
	db	081h, 021h			; LD A, (XBC)
	db	0C9h, 0CCh, 08Fh		; AND A, 0x8F
	db	0C9h, 0CEh, 030h		; OR A, 0x30
	db	0B1h, 041h			; LD (XBC), A

	; === Check Boot Source ===
	db	068h, 000h			; JR T, +0 (nop-like branch)
	db	0F0h, 038h, 0C8h		; BIT 0, (P7)
	db	06Eh, 00Ah			; JR NZ, Boot_SkipFDCCheck

	; === Get Boot Mode and Check FDC ===
	db	01Eh, 0A6h, 000h		; CALR Boot_GetBootMode (at 0xFFB700)
	db	0CFh, 0DCh			; CP L, 4
	db	0F2h, 0B2h, 0C6h, 0FFh, 0EEh	; CALL NZ, 0xFFC6B2 (Boot_FDCRoutine)

Boot_SkipFDCCheck:
	db	01Dh, 063h, 0ECh, 0FFh		; CALL 0xFFEC63 (Boot_CheckFlash)
	db	0CFh, 0D8h			; CP L, 0
	db	066h, 044h			; JR Z, Boot_PrepareJump

	; === Load and Call Function Pointer ===
	db	0E2h, 06Eh, 0ECh, 0FFh, 023h	; LD XHL, (0xFFEC6E)
	db	0B3h, 0E8h			; CALL T, XHL

	; === Validate Boot Image ===
	db	01Dh, 00Eh, 0EDh, 0FFh		; CALL 0xFFED0E (Boot_ValidateImage)
	db	0CFh, 0DCh			; CP L, 4
	db	06Eh, 035h			; JR NZ, Boot_PrepareJump

	; === Flash Update Sequence ===
	db	01Dh, 007h, 0BFh, 0FFh		; CALL 0xFFBF07 (Boot_InitDisplay)
	db	01Dh, 062h, 0D2h, 0FFh		; CALL 0xFFD262 (Boot_ShowMessage)
	db	00Bh, 008h, 000h		; PUSH 0x0008
	db	00Bh, 003h, 000h		; PUSH 0x0003
	db	040h, 0F6h, 0AAh, 0FFh, 000h	; LD XWA, 0x00FFAAF6 (message addr)
	db	031h, 030h, 000h		; LD BC, 0x0030 (width)
	db	032h, 050h, 000h		; LD DE, 0x0050 (height)
	db	01Dh, 0FBh, 0CCh, 0FFh		; CALL 0xFFCCFB (Boot_DrawBitmap)
	db	01Dh, 0C4h, 0BFh, 0FFh		; CALL 0xFFBFC4 (Boot_WaitForInput)
	db	0CFh, 0DBh			; CP L, 3
	db	066h, 010h			; JR Z, Boot_PrepareJump
	db	0CFh, 0CFh, 008h		; CP L, 0x08
	db	066h, 00Bh			; JR Z, Boot_PrepareJump
	db	0CFh, 0CFh, 0FFh		; CP L, 0xFF
	db	066h, 006h			; JR Z, Boot_PrepareJump
	db	01Dh, 02Ah, 0CCh, 0FFh		; CALL 0xFFCC2A (Boot_PerformUpdate)

Boot_HaltLoop:
	db	068h, 0FEh			; JR T, Boot_HaltLoop (-2)

Boot_PrepareJump:
	; === Prepare to Jump to Main Program ROM ===
	db	006h, 007h			; EI 7 (disable maskable interrupts)

	; === Clear Interrupt Flags ===
	db	008h, 0E4h, 000h		; LD (0xE4), 0x00
	db	008h, 0E0h, 000h		; LD (0xE0), 0x00
	db	008h, 0EDh, 000h		; LD (0xED), 0x00
	db	008h, 0E3h, 000h		; LD (0xE3), 0x00
	db	008h, 0EBh, 000h		; LD (0xEB), 0x00

	; === Setup for Jump to Main Program ===
	db	047h, 000h, 00Ch, 000h, 000h	; LD XSP, 0x00000C00
	db	040h, 0DCh, 0FEh, 0FFh, 000h	; LD XWA, 0x00FFFEDC (target address)
	db	034h, 04Bh, 001h		; LD IX, 0x014B (CS2 register)
	db	0ECh, 012h			; EXTZ XIX
	db	0E9h, 0EEh, 000h		; SLL 0, XBC (alignment/padding)
	db	0E9h, 0EEh, 000h		; SLL 0, XBC
	db	0B4h, 000h, 080h		; LD (XIX), 0x80 (CS2 config)
	db	0B0h, 0D8h			; JP T, XWA - jump to main program!

Boot_Ret:
	db	00Eh				; RET

; -----------------------------------------------------------------------------
; Boot_DetectMode - Detect boot mode from hardware switches
; Address: 0xFFB6D9
; Returns: (0x0C06) = boot mode (1-4)
; -----------------------------------------------------------------------------
Boot_DetectMode:
	db	0F0h, 044h, 0CAh		; BIT 2, (P8FC)
	db	066h, 011h			; JR Z, .check_bit1_only
	db	0F0h, 044h, 0C9h		; BIT 1, (P8FC)
	db	066h, 006h			; JR Z, .mode2
	db	0F1h, 006h, 00Ch, 000h, 001h	; LD (0x0C06), 0x01 - Mode 1
	db	00Eh				; RET
.mode2:
	db	0F1h, 006h, 00Ch, 000h, 002h	; LD (0x0C06), 0x02 - Mode 2
	db	00Eh				; RET
.check_bit1_only:
	db	0F0h, 044h, 0C9h		; BIT 1, (P8FC)
	db	066h, 006h			; JR Z, .mode4
	db	0F1h, 006h, 00Ch, 000h, 003h	; LD (0x0C06), 0x03 - Mode 3
	db	00Eh				; RET
.mode4:
	db	0F1h, 006h, 00Ch, 000h, 004h	; LD (0x0C06), 0x04 - Mode 4
	db	00Eh				; RET

; -----------------------------------------------------------------------------
; Boot_GetBootMode - Get stored boot mode value
; Address: 0xFFB700
; Returns: L = boot mode
; -----------------------------------------------------------------------------
Boot_GetBootMode:
	db	0C1h, 006h, 00Ch, 027h		; LD L, (0x0C06)
	db	00Eh				; RET

	ORG 09FB705h
EMPTY_HANDLER:
	RETI

; After RETI, there's JRL back to Boot_Init for watchdog reset scenarios
	JRL	T, Boot_Init		; Jump relative long back to boot entry

; -----------------------------------------------------------------------------
; Various boot handlers and routines before Boot_ClearRAM
; TODO: Disassemble this section (contains handlers at 0x9FB709-0x9FB73F)
; -----------------------------------------------------------------------------
	binclude "includes/bootcode_pre_clearram.bin"

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
	db	042h, 04Eh, 010h, 000h, 000h	; LD XDE, 0x0000104E (destination)
	db	041h, 04Ah, 089h, 000h, 000h	; LD XBC, 0x0000894A (count = 35146 bytes)
	db	0D9h, 08Ch			; LD IX, BC (save original count)
	db	0E9h, 0EFh, 001h		; SRL 1, XBC (divide by 2 for word count)
	db	066h, 01Ch			; JR Z, .clear1_done (skip if zero)
	db	0EAh, 08Bh			; LD XHL, XDE (source = dest for fill)
	db	0F5h, 0E9h, 002h, 000h, 000h	; LD (XDE+), 0x0000 (store first zero word)
	db	0E9h, 069h			; DEC 1, XBC
	db	0E9h, 0E1h			; OR XBC, XBC (test if zero)
	db	066h, 00Fh			; JR Z, .clear1_done
	db	093h, 011h			; LDIRW (word block copy - fills with zeros)
	db	0D7h, 0E6h, 0D8h		; CP QBC, 0 (check high dword)
	db	066h, 008h			; JR Z, .clear1_done
	db	0D7h, 0E6h, 088h		; LD WA, QBC
	db	093h, 011h			; LDIRW
	db	0D8h, 01Ch, 0FBh		; DJNZ WA, -5
.clear1_done:
	db	0DCh, 033h, 000h		; BIT 0, IX (check if odd byte)
	db	066h, 003h			; JR Z, .clear1_aligned
	db	0B2h, 000h, 000h		; LD (XDE), 0x00 (clear last odd byte)
.clear1_aligned:

	; === Clear RAM block 2: 0x0C00 for 0x0443 bytes ===
	db	042h, 000h, 00Ch, 000h, 000h	; LD XDE, 0x00000C00 (destination)
	db	041h, 043h, 004h, 000h, 000h	; LD XBC, 0x00000443 (count = 1091 bytes)
	db	0D9h, 08Ch			; LD IX, BC
	db	0E9h, 0EFh, 001h		; SRL 1, XBC
	db	066h, 01Ch			; JR Z, .clear2_done
	db	0EAh, 08Bh			; LD XHL, XDE
	db	0F5h, 0E9h, 002h, 000h, 000h	; LD (XDE+), 0x0000
	db	0E9h, 069h			; DEC 1, XBC
	db	0E9h, 0E1h			; OR XBC, XBC
	db	066h, 00Fh			; JR Z, .clear2_done
	db	093h, 011h			; LDIRW
	db	0D7h, 0E6h, 0D8h		; CP QBC, 0
	db	066h, 008h			; JR Z, .clear2_done
	db	0D7h, 0E6h, 088h		; LD WA, QBC
	db	093h, 011h			; LDIRW
	db	0D8h, 01Ch, 0FBh		; DJNZ WA, -5
.clear2_done:
	db	0DCh, 033h, 000h		; BIT 0, IX
	db	066h, 003h			; JR Z, .clear2_aligned
	db	0B2h, 000h, 000h		; LD (XDE), 0x00
.clear2_aligned:

	; === Copy ROM data 1: 12 bytes from 0xFFB4DC to RAM 0x9998 ===
	db	042h, 098h, 099h, 000h, 000h	; LD XDE, 0x00009998 (destination)
	db	043h, 0DCh, 0B4h, 0FFh, 000h	; LD XHL, 0x00FFB4DC (source in boot ROM)
	db	041h, 00Ch, 000h, 000h, 000h	; LD XBC, 0x0000000C (count = 12 bytes)
	db	0E9h, 0E1h			; OR XBC, XBC
	db	066h, 00Fh			; JR Z, .copy1_done
	db	083h, 011h			; LDIR (byte block copy)
	db	0D7h, 0E6h, 0D8h		; CP QBC, 0
	db	066h, 008h			; JR Z, .copy1_done
	db	0D7h, 0E6h, 088h		; LD WA, QBC
	db	083h, 011h			; LDIR
	db	0D8h, 01Ch, 0FBh		; DJNZ WA, -5
.copy1_done:

	; === Copy ROM data 2: 10 bytes from 0xFFB4D2 to RAM 0x1044 ===
	db	042h, 044h, 010h, 000h, 000h	; LD XDE, 0x00001044 (destination)
	db	043h, 0D2h, 0B4h, 0FFh, 000h	; LD XHL, 0x00FFB4D2 (source in boot ROM)
	db	041h, 00Ah, 000h, 000h, 000h	; LD XBC, 0x0000000A (count = 10 bytes)
	db	0E9h, 0E1h			; OR XBC, XBC
	db	066h, 00Fh			; JR Z, .copy2_done
	db	083h, 011h			; LDIR
	db	0D7h, 0E6h, 0D8h		; CP QBC, 0
	db	066h, 008h			; JR Z, .copy2_done
	db	0D7h, 0E6h, 088h		; LD WA, QBC
	db	083h, 011h			; LDIR
	db	0D8h, 01Ch, 0FBh		; DJNZ WA, -5
.copy2_done:
	db	078h, 042h, 0FEh		; JRL T, Boot_Init+0x14B (return to caller at 0xFFB633)
	db	00Eh				; RET (never reached)

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
	db	01Dh, 000h, 0B7h, 0FFh	; CALL Boot_Get_Region_Code (at 0xFFB700)
	CP	L, 4			; cf dc
	JR	NZ, .done		; 6e 2e
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
	; Binary include for the remaining complex sector handling
	binclude "includes/flash_sector_erase_cont_part1.bin"


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
; Remaining 32-bit flash utility routines
; Address: 0x9FBD7D onwards (boot-time: 0xFFBD7D)
;
; Contains:
;   - Flash_SectorErase_32bit: Multi-sector erase routine
;   - Flash_WaitReady: Check flash status
;   - Higher-level flash update routines
; -----------------------------------------------------------------------------
	binclude "includes/flash_sector_erase_cont_part3.bin"


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
	binclude "includes/bootcode_post_lzss.bin"

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
