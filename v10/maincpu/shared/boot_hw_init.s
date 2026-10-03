; =============================================================================
; boot_hw_init.asm - Hardware Initialization Code (Shared)
; =============================================================================
; This file contains the hardware initialization sequence that is byte-identical
; between the Main CPU ROM (maincpu) and Table Data ROM (table_data).
;
; In maincpu: Located at 0xef03c6-0xef04ff (315 bytes)
; In table_data: Located at 0x9fb4e8-0x9fb621 (315 bytes)
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
	ld (272:16), 0
	ld (273:16), 177

	; === System Clock Setup ===
	ld (266:16), 4

	; === Port F Setup (Control Panel / MIDI) ===
	ld (PF:8), 0x00:io
	ld (PFFC:8), 0x73:io	; Control panel enabled / MIDI disabled
	ld (PFCR:8), 0x15:io
	and	(PB:8), 0xf0
	res	3, (P8:8)
	res	2, (PF:8)

	; === Data Bus Ports Setup (P2, P3, P7) ===
	ld (P2FC:8), 0xff:io
	ld (P3FC:8), 0xff:io
	ld (P7:8), 0xff:io
	ld (P7FC:8), 0x1f:io
	ld (P7CR:8), 0x00:io

	; === Address Bus Ports Setup (PA, PB, PC, PD, PE, PH, PZ) ===
	ld (PA:8), 0xfe:io
	ld (PAFC:8), 0x08:io
	ld (PB:8), 0xff:io
	ld (PBFC:8), 0x1f:io
	ld (0x30:8), 0x03:io
	ld (PCFC:8), 0x00:io
	ld (PCCR:8), 0x02:io
	ld (PD:8), 0x00:io
	ld (PDFC:8), 0x06:io
	ld (PDCR:8), 0x11:io
	ld (PE:8), 0x00:io
	ld (PEFC:8), 0x42:io
	ld (PECR:8), 0x20:io
	ld (PH:8), 0x00:io
	ld (PHFC:8), 0x1e:io
	ld (PHCR:8), 0x09:io
	ld (PZ:8), 0xff:io
	ld (PZCR:8), 0x03:io

	; === 8-bit Timer Setup ===
	ld (T01MOD:8), 0x1d:io
	ld (T23MOD:8), 0x1d:io
	ld (T02FFCR:8), 0x00:io
	ld (TREG0:8), 0x0a:io
	ld (TREG1:8), 0x10:io
	ld (TRDC:8), 0x00:io
	set	1, (T8RUN:8)

	; === 16-bit Timer 4/5 Setup ===
	ld (T4MOD:8), 0x05:io
	ld (T4FFCR:8), 0x00:io
	ld (T16CR:8), 0x00:io
	ldw (TREG4L:8), 0x0001:io	; LDW (TREG4L:24), 0001h (ASL unsupported)
	ldw (TREG5L:8), 0x3d09:io	; LDW (TREG5L:24), 3d09h (ASL unsupported)
	set	7, (T16RUN:8)
	set	0, (T16RUN:8)

	; === Memory Controller: Start Address Registers ===
	ld (323:16), 30; Block 0 @ 0x1e0000
	ld (327:16), 16; Block 1 @ 0x100000
	ld (331:16), 192; Block 2 @ 0xc00000
	ld (335:16), 0; Block 3 @ 0x000000
	ld (339:16), 128; Block 4 @ 0x800000 (Table Data)
	ld (343:16), 0; Block 5 @ 0x000000

	; === Memory Controller: Address Mask Registers ===
	ld (322:16), 15
	ld (326:16), 63
	ld (330:16), 127
	ld (334:16), 31
	ld (338:16), 255
	ld (342:16), 255

	; === Port 8 Setup (Chip Select) ===
	ld (P8:8), 0x3b:io
	ld (P8FC:8), 0x7f:io
	ld (P8CR:8), 0x3f:io

	; === DRAM Initialization Delay 1 ===
	ldw bc, 0x400
RESET_HANDLER__pause1:
	djnz16 bc, RESET_HANDLER__pause1
	ld (357:16), 129; Enable DRAM refresh

	; === DRAM Initialization Delay 2 ===
	ldw bc, 0x2000
RESET_HANDLER__pause2:
	djnz16 bc, RESET_HANDLER__pause2
	ld (357:16), 113
	ld (354:16), 139
	ld (355:16), 88
	res 4, (358:16)

	; === Block Chip Select Low Configuration ===
	ld (320:16), 17
	ld (324:16), 51
	ld (328:16), 17
	ld (332:16), 34
	ld (336:16), 17
	ld (340:16), 34

	; === Block Chip Select High Configuration ===
	ld (321:16), 128
	ld (325:16), 129
	ld (329:16), 194
	ld (333:16), 138
	ld (337:16), 130
	ld (341:16), 129

	; === Interrupt Mode Control ===
	ld (IIMC:8), 0x00:io
	; End of shared boot hardware initialization (315 bytes)
	; ROM-specific code follows in each file
