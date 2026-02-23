; =============================================================================
; sfr_tmp94c241.asm - TMP94C241 Special Function Register Definitions
; =============================================================================
; This file contains SFR address definitions for the Toshiba TMP94C241
; microcontroller used in the Technics KN5000 keyboard.
;
; These definitions are shared between maincpu and table_data ROMs.
; =============================================================================

; -----------------------------------------------------------------------------
; I/O Ports (P0-PH, PZ)
; Each port has: Data register, Control register (CR), Function register (FC)
; -----------------------------------------------------------------------------
P0		EQU 000h
P0CR		EQU 002h
P0FC		EQU 003h
P1		EQU 004h
P1CR		EQU 006h
P1FC		EQU 007h
P2		EQU 008h
P2CR		EQU 00Ah
P2FC		EQU 00Bh
P3		EQU 00Ch
P3CR		EQU 00Eh
P3FC		EQU 00Fh
P4		EQU 010h
P4CR		EQU 012h
P4FC		EQU 013h
P5		EQU 014h
P5CR		EQU 016h
P5FC		EQU 017h
P6		EQU 018h
P6CR		EQU 01Ah
P6FC		EQU 01Bh
P7		EQU 01Ch
P7CR		EQU 01Eh
P7FC		EQU 01Fh
P8		EQU 020h
P8CR		EQU 022h
P8FC		EQU 023h
PA		EQU 028h
PAFC		EQU 02Bh
PB		EQU 02Ch
PBFC		EQU 02Fh
PC		EQU 030h
PCCR		EQU 032h
PCFC		EQU 033h
PD		EQU 034h
PDCR		EQU 036h
PDFC		EQU 037h
PE		EQU 038h
PECR		EQU 03Ah
PEFC		EQU 03Bh
PF		EQU 03Ch
PFCR		EQU 03Eh
PFFC		EQU 03Fh
PG		EQU 040h
PH		EQU 044h
PHCR		EQU 046h
PHFC		EQU 047h
PZ		EQU 068h
PZCR		EQU 06Ah

; -----------------------------------------------------------------------------
; 8-bit Timers (T0-T3)
; -----------------------------------------------------------------------------
T8RUN		EQU 080h	; 8-bit Timer Run register
TRDC		EQU 081h	; Timer RD Control
T02FFCR		EQU 082h	; Timer 0/2 Flip-Flop Control
T01MOD		EQU 084h	; Timer 0/1 Mode
T23MOD		EQU 085h	; Timer 2/3 Mode
TREG0		EQU 088h	; Timer 0 Register
TREG1		EQU 089h	; Timer 1 Register
TREG2		EQU 08Ah	; Timer 2 Register
TREG3		EQU 08Bh	; Timer 3 Register

; -----------------------------------------------------------------------------
; 16-bit Timers (T4-TA)
; -----------------------------------------------------------------------------
TREG4L		EQU 090h
TREG4H		EQU 091h
TREG5L		EQU 092h
TREG5H		EQU 093h
CAP4L		EQU 094h
CAP4H		EQU 095h
CAP5L		EQU 096h
CAP5H		EQU 097h
T4MOD		EQU 098h
T4FFCR		EQU 099h
T16RUN		EQU 09Eh	; 16-bit Timer Run
T16CR		EQU 09Fh	; 16-bit Timer Control

TREG6L		EQU 0A0h
TREG6H		EQU 0A1h
TREG7L		EQU 0A2h
TREG7H		EQU 0A3h
CAP6L		EQU 0A4h
CAP6H		EQU 0A5h
CAP7L		EQU 0A6h
CAP7H		EQU 0A7h
T6MOD		EQU 0A8h
T6FFCR		EQU 0A9h

TREG8L		EQU 0B0h
TREG8H		EQU 0B1h
TREG9L		EQU 0B2h
TREG9H		EQU 0B3h
CAP8L		EQU 0B4h
CAP8H		EQU 0B5h
CAP9L		EQU 0B6h
CAP9H		EQU 0B7h
T8MOD		EQU 0B8h
T8FFCR		EQU 0B9h

TREGAL		EQU 0C0h
TREGAH		EQU 0C1h
TREGBL		EQU 0C2h
TREGBH		EQU 0C3h
CAPAL		EQU 0C4h
CAPAH		EQU 0C5h
CAPBL		EQU 0C6h
CAPBH		EQU 0C7h
TAMOD		EQU 0C8h
TAFFCR		EQU 0C9h

; -----------------------------------------------------------------------------
; Serial Channels (SC0, SC1)
; -----------------------------------------------------------------------------
SC0BUF		EQU 0D0h	; Serial Channel 0 Buffer
SC0CR		EQU 0D1h	; Serial Channel 0 Control
SC0MOD		EQU 0D2h	; Serial Channel 0 Mode
BR0CR		EQU 0D3h	; Baud Rate 0 Control
SC1BUF		EQU 0D4h	; Serial Channel 1 Buffer
SC1CR		EQU 0D5h	; Serial Channel 1 Control
SC1MOD		EQU 0D6h	; Serial Channel 1 Mode
BR1CR		EQU 0D7h	; Baud Rate 1 Control

; -----------------------------------------------------------------------------
; Interrupt Control
; -----------------------------------------------------------------------------
INTE45		EQU 0E0h
INTE67		EQU 0E1h
INTE89		EQU 0E2h
INTEAB		EQU 0E3h
INTET01		EQU 0E4h
INTET23		EQU 0E5h
INTET45		EQU 0E6h
INTET67		EQU 0E7h
INTET89		EQU 0E8h
INTETAB		EQU 0E9h
INTES0		EQU 0EAh
INTES1		EQU 0EBh
INTETC01	EQU 0ECh
INTETC23	EQU 0EDh
INTETC45	EQU 0EEh
INTETC67	EQU 0EFh
INTE0AD		EQU 0F0h
IIMC		EQU 0F6h	; Interrupt I/O Mode Control
INTNMWDT	EQU 0F7h	; NMI/Watchdog Timer
INTCLR		EQU 0F8h	; Interrupt Clear

; -----------------------------------------------------------------------------
; DMA Controller
; -----------------------------------------------------------------------------
DMA0V		EQU 0100h
DMA1V		EQU 0101h
DMA2V		EQU 0102h
DMA3V		EQU 0103h
DMA4V		EQU 0104h
DMA5V		EQU 0105h
DMA6V		EQU 0106h
DMA7V		EQU 0107h
DMAB		EQU 0108h
DMAR		EQU 0109h

; -----------------------------------------------------------------------------
; System Control
; -----------------------------------------------------------------------------
CLKMOD		EQU 010Ah	; Clock Mode
WDMOD		EQU 0110h	; Watchdog Mode
WDCR		EQU 0111h	; Watchdog Control

; -----------------------------------------------------------------------------
; A/D Converter
; -----------------------------------------------------------------------------
ADREG04L	EQU 0120h
ADREG04H	EQU 0121h
ADREG15L	EQU 0122h
ADREG15H	EQU 0123h
ADREG26L	EQU 0124h
ADREG26H	EQU 0125h
ADREG37L	EQU 0126h
ADREG37H	EQU 0127h
ADMOD1		EQU 0128h
ADMOD2		EQU 0129h

; -----------------------------------------------------------------------------
; D/A Converter
; -----------------------------------------------------------------------------
DAREG0		EQU 0130h
DAREG1		EQU 0131h
DADRV		EQU 0132h

; -----------------------------------------------------------------------------
; Memory Controller - Block Chip Select
; -----------------------------------------------------------------------------
B0CSL		EQU 0140h
B0CSH		EQU 0141h
MAMR0		EQU 0142h	; Address Mask Register 0
MSAR0		EQU 0143h	; Start Address Register 0
B1CSL		EQU 0144h
B1CSH		EQU 0145h
MAMR1		EQU 0146h
MSAR1		EQU 0147h
B2CSL		EQU 0148h
B2CSH		EQU 0149h
MAMR2		EQU 014Ah
MSAR2		EQU 014Bh
B3CSL		EQU 014Ch
B3CSH		EQU 014Dh
MAMR3		EQU 014Eh
MSAR3		EQU 014Fh
B4CSL		EQU 0150h
B4CSH		EQU 0151h
MAMR4		EQU 0152h
MSAR4		EQU 0153h
B5CSL		EQU 0154h
B5CSH		EQU 0155h
MAMR5		EQU 0156h
MSAR5		EQU 0157h

; -----------------------------------------------------------------------------
; DRAM Controller
; -----------------------------------------------------------------------------
DRAM0CRL	EQU 0160h
DRAM0CRH	EQU 0161h
DRAM1CRL	EQU 0162h
DRAM1CRH	EQU 0163h
DRAM0REF	EQU 0164h
DRAM1REF	EQU 0165h
PMEMCR		EQU 0166h	; Page ROM Control
