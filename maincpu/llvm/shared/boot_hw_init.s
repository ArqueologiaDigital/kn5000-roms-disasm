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
	; (no addr) LD (WDMOD), 000h
	; (no addr) LD (WDCR), 0b1h

	; === System Clock Setup ===
	; (no addr) LD (CLKMOD), 004h

	; === Port F Setup (Control Panel / MIDI) ===
	; (no addr) LD (PF), 000h
	; (no addr) LD (PFFC), 073h	; Control panel enabled / MIDI disabled
	; (no addr) LD (PFCR), 015h
	; (no addr) AND (PB), 0f0h
	; (no addr) RES 3, (P8)
	; (no addr) RES 2, (PF)

	; === Data Bus Ports Setup (P2, P3, P7) ===
	; (no addr) LD (P2FC), 0ffh
	; (no addr) LD (P3FC), 0ffh
	; (no addr) LD (P7), 0ffh
	; (no addr) LD (P7FC), 01fh
	; (no addr) LD (P7CR), 000h

	; === Address Bus Ports Setup (PA, PB, PC, PD, PE, PH, PZ) ===
	; (no addr) LD (PA), 0feh
	; (no addr) LD (PAFC), 008h
	; (no addr) LD (PB), 0ffh
	; (no addr) LD (PBFC), 01fh
	; (no addr) LD (PC), 003h
	; (no addr) LD (PCFC), 000h
	; (no addr) LD (PCCR), 002h
	; (no addr) LD (PD), 000h
	; (no addr) LD (PDFC), 006h
	; (no addr) LD (PDCR), 011h
	; (no addr) LD (PE), 000h
	; (no addr) LD (PEFC), 042h
	; (no addr) LD (PECR), 020h
	; (no addr) LD (PH), 000h
	; (no addr) LD (PHFC), 01eh
	; (no addr) LD (PHCR), 009h
	; (no addr) LD (PZ), 0ffh
	; (no addr) LD (PZCR), 003h

	; === 8-bit Timer Setup ===
	; (no addr) LD (T01MOD), 01dh
	; (no addr) LD (T23MOD), 01dh
	; (no addr) LD (T02FFCR), 000h
	; (no addr) LD (TREG0), 00ah
	; (no addr) LD (TREG1), 010h
	; (no addr) LD (TRDC), 000h
	; (no addr) SET 1, (T8RUN)

	; === 16-bit Timer 4/5 Setup ===
	; (no addr) LD (T4MOD), 005h
	; (no addr) LD (T4FFCR), 000h
	; (no addr) LD (T16CR), 000h
	.byte 0xA, 0x90, 0x1, 0x0	; LDW (TREG4L:24), 0001h (ASL unsupported)
	.byte 0xA, 0x92, 0x9, 0x3d	; LDW (TREG5L:24), 3d09h (ASL unsupported)
	; (no addr) SET 7, (T16RUN)
	; (no addr) SET 0, (T16RUN)

	; === Memory Controller: Start Address Registers ===
	; (no addr) LD (MSAR0), 01eh	; Block 0 @ 0x1E0000
	; (no addr) LD (MSAR1), 010h	; Block 1 @ 0x100000
	; (no addr) LD (MSAR2), 0c0h	; Block 2 @ 0xC00000
	; (no addr) LD (MSAR3), 000h	; Block 3 @ 0x000000
	; (no addr) LD (MSAR4), 080h	; Block 4 @ 0x800000 (Table Data)
	; (no addr) LD (MSAR5), 000h	; Block 5 @ 0x000000

	; === Memory Controller: Address Mask Registers ===
	; (no addr) LD (MAMR0), 00fh
	; (no addr) LD (MAMR1), 03fh
	; (no addr) LD (MAMR2), 07fh
	; (no addr) LD (MAMR3), 01fh
	; (no addr) LD (MAMR4), 0ffh
	; (no addr) LD (MAMR5), 0ffh

	; === Port 8 Setup (Chip Select) ===
	; (no addr) LD (P8), 03bh
	; (no addr) LD (P8FC), 07fh
	; (no addr) LD (P8CR), 03fh

	; === DRAM Initialization Delay 1 ===
	; (no addr) LD BC, 0400h
	.pause1:
	; (no addr) DJNZ BC, .pause1
	; (no addr) LD (DRAM1REF), 081h	; Enable DRAM refresh

	; === DRAM Initialization Delay 2 ===
	; (no addr) LD BC, 2000h
	.pause2:
	; (no addr) DJNZ BC, .pause2
	; (no addr) LD (DRAM1REF), 071h
	; (no addr) LD (DRAM1CRL), 08bh
	; (no addr) LD (DRAM1CRH), 058h
	; (no addr) RES 4, (PMEMCR)

	; === Block Chip Select Low Configuration ===
	; (no addr) LD (B0CSL), 011h
	; (no addr) LD (B1CSL), 033h
	; (no addr) LD (B2CSL), 011h
	; (no addr) LD (B3CSL), 022h
	; (no addr) LD (B4CSL), 011h
	; (no addr) LD (B5CSL), 022h

	; === Block Chip Select High Configuration ===
	; (no addr) LD (B0CSH), 080h
	; (no addr) LD (B1CSH), 081h
	; (no addr) LD (B2CSH), 0c2h
	; (no addr) LD (B3CSH), 08ah
	; (no addr) LD (B4CSH), 082h
	; (no addr) LD (B5CSH), 081h

	; === Interrupt Mode Control ===
	; (no addr) LD (IIMC), 000h
	; End of shared boot hardware initialization (315 bytes)
	; ROM-specific code follows in each file
