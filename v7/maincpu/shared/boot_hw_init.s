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
	ld (0x3c:8), 0x00:io
	ld (0x3f:8), 0x73:io	; Control panel enabled / MIDI disabled
	ld (0x3e:8), 0x15:io
	and	(0x2c:8), 0xf0
	res	3, (0x20:8)
	res	2, (0x3c:8)

	; === Data Bus Ports Setup (P2, P3, P7) ===
	ld (0x0b:8), 0xff:io
	ld (0x0f:8), 0xff:io
	ld (0x1c:8), 0xff:io
	ld (0x1f:8), 0x1f:io
	ld (0x1e:8), 0x00:io

	; === Address Bus Ports Setup (PA, PB, PC, PD, PE, PH, PZ) ===
	ld (0x28:8), 0xfe:io
	ld (0x2b:8), 0x08:io
	ld (0x2c:8), 0xff:io
	ld (0x2f:8), 0x1f:io
	ld (0x30:8), 0x03:io
	ld (0x33:8), 0x00:io
	ld (0x32:8), 0x02:io
	ld (0x34:8), 0x00:io
	ld (0x37:8), 0x06:io
	ld (0x36:8), 0x11:io
	ld (0x38:8), 0x00:io
	ld (0x3b:8), 0x42:io
	ld (0x3a:8), 0x20:io
	ld (0x44:8), 0x00:io
	ld (0x47:8), 0x1e:io
	ld (0x46:8), 0x09:io
	ld (0x68:8), 0xff:io
	ld (0x6a:8), 0x03:io

	; === 8-bit Timer Setup ===
	ld (0x84:8), 0x1d:io
	ld (0x85:8), 0x1d:io
	ld (0x82:8), 0x00:io
	ld (0x88:8), 0x0a:io
	ld (0x89:8), 0x10:io
	ld (0x81:8), 0x00:io
	set	1, (0x80:8)

	; === 16-bit Timer 4/5 Setup ===
	ld (0x98:8), 0x05:io
	ld (0x99:8), 0x00:io
	ld (0x9f:8), 0x00:io
	ldw (0x90:8), 0x0001:io	; LDW (TREG4L:24), 0001h (ASL unsupported)
	ldw (0x92:8), 0x3d09:io	; LDW (TREG5L:24), 3d09h (ASL unsupported)
	set	7, (0x9e:8)
	set	0, (0x9e:8)

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
	ld (0x20:8), 0x3b:io
	ld (0x23:8), 0x7f:io
	ld (0x22:8), 0x3f:io

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
	ld (0xf6:8), 0x00:io
	; End of shared boot hardware initialization (315 bytes)
	; ROM-specific code follows in each file
