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
	stdi8 272, 0
	stdi8 273, 177

	; === System Clock Setup ===
	stdi8 266, 4

	; === Port F Setup (Control Panel / MIDI) ===
	ldio 0x3C, 0x00
	ldio 0x3F, 0x73	; Control panel enabled / MIDI disabled
	ldio 0x3E, 0x15
	sd8b3 0x2C, 0x3C, 0xF0
	dd82 0x20, 0xB3
	dd82 0x3C, 0xB2

	; === Data Bus Ports Setup (P2, P3, P7) ===
	ldio 0x0B, 0xFF
	ldio 0x0F, 0xFF
	ldio 0x1C, 0xFF
	ldio 0x1F, 0x1F
	ldio 0x1E, 0x00

	; === Address Bus Ports Setup (PA, PB, PC, PD, PE, PH, PZ) ===
	ldio 0x28, 0xFE
	ldio 0x2B, 0x08
	ldio 0x2C, 0xFF
	ldio 0x2F, 0x1F
	ldio 0x30, 0x03
	ldio 0x33, 0x00
	ldio 0x32, 0x02
	ldio 0x34, 0x00
	ldio 0x37, 0x06
	ldio 0x36, 0x11
	ldio 0x38, 0x00
	ldio 0x3B, 0x42
	ldio 0x3A, 0x20
	ldio 0x44, 0x00
	ldio 0x47, 0x1E
	ldio 0x46, 0x09
	ldio 0x68, 0xFF
	ldio 0x6A, 0x03

	; === 8-bit Timer Setup ===
	ldio 0x84, 0x1D
	ldio 0x85, 0x1D
	ldio 0x82, 0x00
	ldio 0x88, 0x0A
	ldio 0x89, 0x10
	ldio 0x81, 0x00
	dd82 0x80, 0xB9

	; === 16-bit Timer 4/5 Setup ===
	ldio 0x98, 0x05
	ldio 0x99, 0x00
	ldio 0x9F, 0x00
	ldwio 0x90, 0x0001	; LDW (TREG4L:24), 0001h (ASL unsupported)
	ldwio 0x92, 0x3D09	; LDW (TREG5L:24), 3d09h (ASL unsupported)
	dd82 0x9E, 0xBF
	dd82 0x9E, 0xB8

	; === Memory Controller: Start Address Registers ===
	stdi8 323, 30	; Block 0 @ 0x1E0000
	stdi8 327, 16	; Block 1 @ 0x100000
	stdi8 331, 192	; Block 2 @ 0xC00000
	stdi8 335, 0	; Block 3 @ 0x000000
	stdi8 339, 128	; Block 4 @ 0x800000 (Table Data)
	stdi8 343, 0	; Block 5 @ 0x000000

	; === Memory Controller: Address Mask Registers ===
	stdi8 322, 15
	stdi8 326, 63
	stdi8 330, 127
	stdi8 334, 31
	stdi8 338, 255
	stdi8 342, 255

	; === Port 8 Setup (Chip Select) ===
	ldio 0x20, 0x3B
	ldio 0x23, 0x7F
	ldio 0x22, 0x3F

	; === DRAM Initialization Delay 1 ===
	ldw bc, 0x400
Boot_Init__pause1:
	djnz xbc, Boot_Init__pause1
	stdi8 357, 129	; Enable DRAM refresh

	; === DRAM Initialization Delay 2 ===
	ldw bc, 0x2000
Boot_Init__pause2:
	djnz xbc, Boot_Init__pause2
	stdi8 357, 113
	stdi8 354, 139
	stdi8 355, 88
	resda 4, 358

	; === Block Chip Select Low Configuration ===
	stdi8 320, 17
	stdi8 324, 51
	stdi8 328, 17
	stdi8 332, 34
	stdi8 336, 17
	stdi8 340, 34

	; === Block Chip Select High Configuration ===
	stdi8 321, 128
	stdi8 325, 129
	stdi8 329, 194
	stdi8 333, 138
	stdi8 337, 130
	stdi8 341, 129

	; === Interrupt Mode Control ===
	ldio 0xF6, 0x00
	; End of shared boot hardware initialization (315 bytes)
	; ROM-specific code follows in each file
