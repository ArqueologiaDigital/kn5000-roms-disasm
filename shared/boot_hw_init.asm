; =============================================================================
; boot_hw_init.asm - Hardware Initialization Code (Shared)
; =============================================================================
; This file contains the hardware initialization sequence that is byte-identical
; between the Main CPU ROM (maincpu) and Table Data ROM (table_data).
;
; In maincpu: Located at 0xEF03C6-0xEF04FF (315 bytes)
; In table_data: Located at 0x9FB4E8-0x9FB621 (315 bytes)
;
; This code initializes:
;   - Watchdog timer (disable)
;   - Clock configuration
;   - I/O ports
;   - Timers
;   - Memory controller (chip select, DRAM)
;   - Serial channel 0
;
; Requirements:
;   - Must include sfr_tmp94c241.asm before this file
;   - Entry label should be defined before including (RESET_HANDLER or Boot_Init)
;   - Uses local labels (.pause1, .pause2) for internal loops
; =============================================================================

	; === Watchdog Timer Disable ===
	LD (WDMOD), 000h
	LD (WDCR), 0b1h

	; === System Clock Setup ===
	LD (CLKMOD), 004h

	; === Port F Setup (Control Panel / MIDI) ===
	LD (PF), 000h
	LD (PFFC), 073h			; Control panel enabled / MIDI disabled
	LD (PFCR), 015h
	AND (PB), 0f0h
	RES 3, (P8)
	RES 2, (PF)

	; === Data Bus Ports Setup (P2, P3, P7) ===
	LD (P2FC), 0ffh
	LD (P3FC), 0ffh
	LD (P7), 0ffh
	LD (P7FC), 01fh
	LD (P7CR), 000h

	; === Address Bus Ports Setup (PA, PB, PC, PD, PE, PH, PZ) ===
	LD (PA), 0feh
	LD (PAFC), 008h
	LD (PB), 0ffh
	LD (PBFC), 01fh
	LD (PC), 003h
	LD (PCFC), 000h
	LD (PCCR), 002h
	LD (PD), 000h
	LD (PDFC), 006h
	LD (PDCR), 011h
	LD (PE), 000h
	LD (PEFC), 042h
	LD (PECR), 020h
	LD (PH), 000h
	LD (PHFC), 01eh
	LD (PHCR), 009h
	LD (PZ), 0ffh
	LD (PZCR), 003h

	; === 8-bit Timer Setup ===
	LD (T01MOD), 01dh
	LD (T23MOD), 01dh
	LD (T02FFCR), 000h
	LD (TREG0), 00ah
	LD (TREG1), 010h
	LD (TRDC), 000h
	SET 1, (T8RUN)

	; === 16-bit Timer 4/5 Setup ===
	LD (T4MOD), 005h
	LD (T4FFCR), 000h
	LD (T16CR), 000h
	db 0Ah, 90h, 01h, 00h		; LDW (TREG4L:24), 0001h (ASL unsupported)
	db 0Ah, 92h, 09h, 3dh		; LDW (TREG5L:24), 3d09h (ASL unsupported)
	SET 7, (T16RUN)
	SET 0, (T16RUN)

	; === Memory Controller: Start Address Registers ===
	LD (MSAR0), 01eh			; Block 0 @ 0x1E0000
	LD (MSAR1), 010h			; Block 1 @ 0x100000
	LD (MSAR2), 0c0h			; Block 2 @ 0xC00000
	LD (MSAR3), 000h			; Block 3 @ 0x000000
	LD (MSAR4), 080h			; Block 4 @ 0x800000 (Table Data)
	LD (MSAR5), 000h			; Block 5 @ 0x000000

	; === Memory Controller: Address Mask Registers ===
	LD (MAMR0), 00fh
	LD (MAMR1), 03fh
	LD (MAMR2), 07fh
	LD (MAMR3), 01fh
	LD (MAMR4), 0ffh
	LD (MAMR5), 0ffh

	; === Port 8 Setup (Chip Select) ===
	LD (P8), 03bh
	LD (P8FC), 07fh
	LD (P8CR), 03fh

	; === DRAM Initialization Delay 1 ===
	LD BC, 0400h
.pause1:
	DJNZ BC, .pause1
	LD (DRAM1REF), 081h			; Enable DRAM refresh

	; === DRAM Initialization Delay 2 ===
	LD BC, 2000h
.pause2:
	DJNZ BC, .pause2
	LD (DRAM1REF), 071h
	LD (DRAM1CRL), 08bh
	LD (DRAM1CRH), 058h
	RES 4, (PMEMCR)

	; === Block Chip Select Low Configuration ===
	LD (B0CSL), 011h
	LD (B1CSL), 033h
	LD (B2CSL), 011h
	LD (B3CSL), 022h
	LD (B4CSL), 011h
	LD (B5CSL), 022h

	; === Block Chip Select High Configuration ===
	LD (B0CSH), 080h
	LD (B1CSH), 081h
	LD (B2CSH), 0c2h
	LD (B3CSH), 08ah
	LD (B4CSH), 082h
	LD (B5CSH), 081h

	; === Interrupt Mode Control ===
	LD (IIMC), 000h
	; End of shared boot hardware initialization (315 bytes)
	; ROM-specific code follows in each file
