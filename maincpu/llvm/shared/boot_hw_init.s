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
	ld (WDMOD), 0x0
	ld (WDCR), 0xb1

	; === System Clock Setup ===
	ld (CLKMOD), 0x4

	; === Port F Setup (Control Panel / MIDI) ===
	ld (PF), 0x0
	ld (PFFC), 0x73	; Control panel enabled / MIDI disabled
	ld (PFCR), 0x15
	and (PB), 0xf0
	res 3, (P8)
	res 2, (PF)

	; === Data Bus Ports Setup (P2, P3, P7) ===
	ld (P2FC), 0xff
	ld (P3FC), 0xff
	ld (P7), 0xff
	ld (P7FC), 0x1f
	ld (P7CR), 0x0

	; === Address Bus Ports Setup (PA, PB, PC, PD, PE, PH, PZ) ===
	ld (PA), 0xfe
	ld (PAFC), 0x8
	ld (PB), 0xff
	ld (PBFC), 0x1f
	ld (PC), 0x3
	ld (PCFC), 0x0
	ld (PCCR), 0x2
	ld (PD), 0x0
	ld (PDFC), 0x6
	ld (PDCR), 0x11
	ld (PE), 0x0
	ld (PEFC), 0x42
	ld (PECR), 0x20
	ld (PH), 0x0
	ld (PHFC), 0x1e
	ld (PHCR), 0x9
	ld (PZ), 0xff
	ld (PZCR), 0x3

	; === 8-bit Timer Setup ===
	ld (T01MOD), 0x1d
	ld (T23MOD), 0x1d
	ld (T02FFCR), 0x0
	ld (TREG0), 0xa
	ld (TREG1), 0x10
	ld (TRDC), 0x0
	set 1, (T8RUN)

	; === 16-bit Timer 4/5 Setup ===
	ld (T4MOD), 0x5
	ld (T4FFCR), 0x0
	ld (T16CR), 0x0
	.byte 0xA, 0x90, 0x1, 0x0	; LDW (TREG4L:24), 0001h (ASL unsupported)
	.byte 0xA, 0x92, 0x9, 0x3d	; LDW (TREG5L:24), 3d09h (ASL unsupported)
	set 7, (T16RUN)
	set 0, (T16RUN)

	; === Memory Controller: Start Address Registers ===
	ld (MSAR0), 0x1e	; Block 0 @ 0x1E0000
	ld (MSAR1), 0x10	; Block 1 @ 0x100000
	ld (MSAR2), 0xc0	; Block 2 @ 0xC00000
	ld (MSAR3), 0x0	; Block 3 @ 0x000000
	ld (MSAR4), 0x80	; Block 4 @ 0x800000 (Table Data)
	ld (MSAR5), 0x0	; Block 5 @ 0x000000

	; === Memory Controller: Address Mask Registers ===
	ld (MAMR0), 0xf
	ld (MAMR1), 0x3f
	ld (MAMR2), 0x7f
	ld (MAMR3), 0x1f
	ld (MAMR4), 0xff
	ld (MAMR5), 0xff

	; === Port 8 Setup (Chip Select) ===
	ld (P8), 0x3b
	ld (P8FC), 0x7f
	ld (P8CR), 0x3f

	; === DRAM Initialization Delay 1 ===
	ld BC, 0x400
	.pause1:
	djnz BC, .pause1
	ld (DRAM1REF), 0x81	; Enable DRAM refresh

	; === DRAM Initialization Delay 2 ===
	ld BC, 0x2000
	.pause2:
	djnz BC, .pause2
	ld (DRAM1REF), 0x71
	ld (DRAM1CRL), 0x8b
	ld (DRAM1CRH), 0x58
	res 4, (PMEMCR)

	; === Block Chip Select Low Configuration ===
	ld (B0CSL), 0x11
	ld (B1CSL), 0x33
	ld (B2CSL), 0x11
	ld (B3CSL), 0x22
	ld (B4CSL), 0x11
	ld (B5CSL), 0x22

	; === Block Chip Select High Configuration ===
	ld (B0CSH), 0x80
	ld (B1CSH), 0x81
	ld (B2CSH), 0xc2
	ld (B3CSH), 0x8a
	ld (B4CSH), 0x82
	ld (B5CSH), 0x81

	; === Interrupt Mode Control ===
	ld (IIMC), 0x0
	; End of shared boot hardware initialization (315 bytes)
	; ROM-specific code follows in each file
