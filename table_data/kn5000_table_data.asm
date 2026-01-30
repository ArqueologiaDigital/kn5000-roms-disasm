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
	; Bit mask pattern for bit manipulation operations
	db	000h, 040h, 020h, 008h, 010h, 004h, 002h, 000h, 001h, 000h

Boot_InitParams:	; Copied to RAM 0x9998 by Boot_ClearRAM (12 bytes)
	; Stack/display initialization parameters
	db	07Eh, 000h	; 0x007E (126)
	db	010h, 000h	; 0x0010 (16)
	db	000h, 000h	; 0x0000
	db	080h, 000h	; 0x0080 (128)
	db	000h, 000h	; 0x0000
	db	000h, 000h	; 0x0000


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

; -----------------------------------------------------------------------------
; Boot routines: flash update, hardware init, display, FDC, LZSS decoder, etc.
; Addresses 0x9FB7F2 to 0x9FFEE0 (includes all interrupt handlers)
;
; Interrupt handler addresses within this range:
;   INTT1_HANDLER  = 0x9FB7F2 (timer 1 interrupt)
;   NMI_HANDLER    = 0x9FB7FB
;   INTTC3_HANDLER = 0x9FEA9D
;   INT4_HANDLER   = 0x9FEAB2
;   INTA_HANDLER   = 0x9FF229
;   INTTX1_HANDLER = 0x9FF2AE
;   INTRX1_HANDLER = 0x9FF2D0
;
; Notable routines:
;   LZSS_Decompress = 0x9FCA50 (SLIDE4K decompressor, 4KB window)
; -----------------------------------------------------------------------------
	binclude "includes/bootcode_post_clearram.bin"

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
