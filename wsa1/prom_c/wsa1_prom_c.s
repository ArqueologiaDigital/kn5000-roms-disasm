	.text

; ==============================================================================
; Technics SX-WSA1R -- wsa1_prom_c.ic28
; Target CPU: Toshiba TMP95C061 (TLCS-900/H), "CPU 2" / IC2
; ==============================================================================
;
; IC28, program EPROM of the SECOND processor, base 0xF80000.  Load address
; ESTABLISHED the same way as prom_a: 33 of 64 words at file offset 0x7FF00
; point into 0xF00000-0xFFFFFF, and the reset word 0x00FFF000 lands on a
; textbook TLCS-900 boot block.
;
; CPU 2 is a separate address space from CPU 1.  It owns the flash, the
; expansion-board connector and a cluster of address/data device ports; the two
; processors talk over a byte port with a two-wire handshake (0x100000 on this
; side, 0x7C0000 on CPU 1's).  See notes/FINDINGS-memory-map.md.
;
; STATUS: partially converted.  Converted so far, as real assembly:
;   0xFFF000-0xFFF0E4  RESET and the interrupt trampoline block
;   0xFFF0E5-0xFFFFFF  the RET padding, the vector table, the fc configuration
;                      byte and the build tag -- i.e. the whole 4 KiB tail
; Everything below 0xFFF000 is still .incbin, so it builds byte-exact by
; construction and asserts nothing.  The gate
; (scripts/analysis/assert_byte_identical.py) must print PASS after every edit.
;
; PROVENANCE: this is not a chip read.  It is the publicly redistributed v2
; firmware set (../technics_roms/roms/wsa1/PROVENANCE.md).

	.include "include/tmp95c061_sfr.inc"

; ==============================================================================
; 0xF80000-0xFFEFFF -- not yet converted
; ==============================================================================
wsa1_prom_c:
	.incbin "original_ROMs/wsa1_prom_c.ic28", 0x000000, 0x07F000

; ==============================================================================
; RESET -- 0xFFF000, the address in the reset vector at 0xFFFF00
; ==============================================================================
;
; Same shape as CPU 1's boot block but shorter, and in a different order: this
; one sets a stack up front, so it can and does call.
;
RESET:
	; --- watchdog off ------------------------------------------------------
	ldio WDMOD,0x00
	ldio WDCR,0xB1

	; --- stack, at the top of the 128 KiB CS3 DRAM block -------------------
	ld XSP,0x0000FFF0
	ldio IIMC,0x04
	ldio INTETC01,0x00

	; --- ports -------------------------------------------------------------
	ldio P2FC,0x7F
	ldio P7FC,0x00
	ldio P7CR,0xFF
	ldio P6FC,0x1F		; the same five port-6 alternate functions CPU 1
				; enables: RAS and REFOUT out (DRAM controller
				; live) and the CS3 pin as LCAS, so the CS3 area
				; is the DRAM area on this CPU too.
	ldio P5,0x1D
	ldio P5FC,0x04
	ldio P5CR,0x3C
	ldio PA,0xFF
	ldio PAFC,0x00
	ldio PACR,0x03		; PA bits 0 and 1 driven out -- MAME masks the
				; port write with PnCR (tmp95c061.cpp:107).
				; PA0 is the strobe and PA3 the busy input of the
				; link to CPU 1 (0xF99AE0 res 0,(PA) /
				; 0xF99AFF set 0,(PA); 0xF999D0 and 0xF99A06
				; bit 3,(PA)).
	ldio PB,0xFB
	ldio PBFC,0x00
	ldio PBCR,0x7E

	; --- memory controller -------------------------------------------------
	; MSARn = A23-A16 of the block start.  MSAR0 = 0x10 is the one place in
	; either image where the meaning of MSAR is PROVEN rather than assumed:
	; 0x2F bytes further down this same routine, `ld XIX,0x00100000` loads
	; the base of the device cluster that CS0 must be selecting.
	ldio MSAR0,0x10		; CS0 -> 0x100000: link port + three address/data
				; device ports (0x104000, 0x108000, 0x10C000)
	ldio MAMR0,0x07
	ldio MSAR1,0xC0		; CS1 -> 0xC00000: the expansion board.  Its
				; header carries the ASCII signature "WSA1 EXTBD",
				; which also appears twice in this ROM (file
				; 0x6129E and 0x61EC9) as the string it is
				; compared against.
	ldio MAMR1,0x7F
	ldio MSAR2,0xE0		; CS2 -> 0xE00000: an address/data register pair
				; at 0xE00000, the 512 KiB flash at 0xE80000, and
				; this EPROM at 0xF80000
	ldio MAMR2,0x3F
	ldio MSAR3,0x00		; CS3 -> 0x000000: work DRAM
	ldio MAMR3,0x03	; MAMR = window size, 32 KB per unit.  See the long note
			; in prom_a/wsa1_prom_a.s and
			; scripts/analysis/mamr_reading_elimination.py: eight
			; candidate decoders are tested against this firmware's
			; own facts and six die.  Unlike CPU 1, both survivors
			; give IDENTICAL windows here, so these four rows carry
			; no residual ambiguity:
			;   MAMR0 0x07 -> 256 KB   CS0 0x100000-0x13FFFF
			;   MAMR1 0x7F -> 4 MB     CS1 0xC00000-0xFFFFFF, of
			;                          which CS2 takes the top half
			;   MAMR2 0x3F -> 2 MB     CS2 0xE00000-0xFFFFFF
			;   MAMR3 0x03 -> 128 KB   CS3 0x000000-0x01FFFF
			; ⚠ Still NOT ESTABLISHED: the BnCS/BEXCS bit layout and
			; every DREFCR/DMEMCR field.

	ldio B0CS,0x10
	ldio B1CS,0x14
	ldio B2CS,0x1B
	ldio B3CS,0x1B
	ldio BEXCS,0x00
	ldio DREFCR,0x71	; refresh enabled, same value as CPU 1
	ldio DMEMCR,0x89	; CPU 1 uses 0x8D.  Neither is decoded anywhere.

	; --- first touch of the CS0 device cluster -----------------------------
	; This is the pair that proves MSAR0: the base just programmed as 0x10
	; is loaded here as a full 24-bit address.
	ldb E,0x01
	ld XIX,0x00100000

	; --- timers, ports, serial ---------------------------------------------
	ldio T01MOD,0x0D
	ldio P8CR,0x19
	ldio P8FC,0x01
	ldio TRUN,0x80		; prescaler run only (bit 7); no timer started here
	ldio BR0CR,0x13	; boot value: divide by 768, the 24 MHz constant.
			; ⚠ NOT the operative one.  0xF991A2, reached from the
			; init chain at 0xF98B7D, recomputes it from the
			; configuration byte at 0xFFFFEF (see CLOCK_CONFIG_MHZ
			; at the bottom of this file): BR0CR = (M >> 1) & 0x0F,
			; which for M = 0x1C gives 0x0E, i.e. divide by 896.
			; The firmware's own rule makes the bit rate come out
			; at 31250 for any M, so M is literally fc in MHz.
	ldio SC0CR,0x00
	ldio SC0MOD,0x09	; 8-bit UART, baud-rate generator; unlike CPU 1
				; the receiver is not enabled here
	call 0xF99125		; a counted delay (loops to 0x40)

	; --- clear work DRAM, 0x000080-0x01007F --------------------------------
	; 0x8000 stores of 2 bytes = 64 KiB starting just above the internal I/O
	; registers.  As on CPU 1, this is a lower bound on the DRAM, not its
	; size.
	ld XBC,0x00008000
	lda_dd8l XIX,0x80		; lda XIX,0x80
	xor WA,WA
RESET__clear_dram:
	stw_dpi WA,MEM_XIX_PI2		; ld (XIX+),WA
	sub XBC,0x00000001
	jr NZ,RESET__clear_dram

	call 0xF989EF		; copies a 0xD8-byte table from 0xFCB4EA to
				; 0x00E2DF
	jp 0xF9816B		; main entry: `ld XSP,0x0000FA00`, then the
				; main loop.  Note it moves the stack down from
				; the 0xFFF0 the boot block used.

; ==============================================================================
; 0xFFF0A2 -- interrupt trampolines
; ==============================================================================
; Every entry in the vector table at 0xFFFF00 points either into this block or
; straight at a handler elsewhere in the ROM.  The labels below are named after
; the vector that reaches them; where two vectors share an entry the name says
; so.
;
IRQ_WATCHDOG_REBOOT:			; vector 0x24 (INTWD)
	jrl RESET
IRQ_SWI1_REBOOT:			; vector 0x04
	jrl RESET
IRQ_UNUSED:				; vectors 0x08-0x1C, 0x30-0x40,
					; 0x50-0x5C, 0x68-0x78
	jp 0xF9816B		; back to the main entry, exactly as the end
				; of RESET does
IRQ_NMI:				; vector 0x20
	ei 0x07
	call 0xF99125
IRQ_NMI__hang:
	jr IRQ_NMI__hang	; spin forever
IRQ_INT0:				; vector 0x28
	jp 0xF99BBE
IRQ_INTT2:				; vector 0x48
	jp 0xF99E5E
IRQ_INTT1:				; vector 0x44
	jp 0xF99063
IRQ_INTTC2:				; vector 0x7C
	jp 0xF99CFE
IRQ_INTTC3:				; vector 0x80
	jp 0xF99D20

; ------------------------------------------------------------------------------
; 0xFFF0C8-0xFFF0E4 -- six more entries in the same style that NOTHING reaches.
; A byte scan of all four images for a 24-bit reference to any of these six
; addresses finds none, and no vector points here.  What calls them is NOT
; ESTABLISHED; they may simply be dead.
; ------------------------------------------------------------------------------
UNREFERENCED_TRAMPOLINES:
	ei 0x07
	call 0xF98610
	jrl RESET
	jp 0xF98EFE
	jp 0xF99133
	jp 0xF9854E
	jp 0xF99016
	jp 0xF99038

; ==============================================================================
; 0xFFF0E5-0xFFFEFF -- padding
; ==============================================================================
; 3611 bytes of 0x0E, the one-byte RET opcode.  Verified to contain no other
; byte value.
	.fill 0x0E1B, 1, 0x0E

; ==============================================================================
; 0xFFFF00 -- interrupt vector table
; ==============================================================================
;
; Fetched as a 32-bit little-endian word from 0xFFFF00 + offset
; (tmp95c061.cpp:560).  What is CITED and what is CONVENTION:
;   0x00        cited -- the reset PC is fetched from 0xFFFF00
;               (tlcs900.cpp:215-217)
;   0x20        cited -- NMI, tmp95c061.cpp:505
;   0x28-0x80   cited -- names and offsets from tmp95c061_irq_vector_map[] at
;               tmp95c061.cpp:322-346
;   0x04-0x1C,  CONVENTION.  MAME does not name these slots and no databook is
;   0x24        available in these trees.  This ROM corroborates the shape --
;               0x24 and 0x04 both reboot, which is what INTWD and an
;               undefined-instruction trap would do -- but that is
;               corroboration, not a citation.
;
VECTORS:
	.long 0x00FFF000	; 0x00  RESET
	.long 0x00FFF0A5	; 0x04  SWI1        -> IRQ_SWI1_REBOOT
	.long 0x00FFF0A8	; 0x08  SWI2 / INTUNDEF -> IRQ_UNUSED
	.long 0x00FFF0A8	; 0x0C  SWI3
	.long 0x00FFF0A8	; 0x10  SWI4
	.long 0x00FFF0A8	; 0x14  SWI5
	.long 0x00FFF0A8	; 0x18  SWI6
	.long 0x00FFF0A8	; 0x1C  SWI7
	.long 0x00FFF0AC	; 0x20  NMI         -> IRQ_NMI
	.long 0x00FFF0A2	; 0x24  INTWD       -> IRQ_WATCHDOG_REBOOT
	.long 0x00FFF0B4	; 0x28  INT0        -> IRQ_INT0
	.long 0x00F995C2	; 0x2C  INT4
	.long 0x00FFF0A8	; 0x30  INT5
	.long 0x00FFF0A8	; 0x34  INT6
	.long 0x00FFF0A8	; 0x38  INT7
	.long 0x00FFF0A8	; 0x3C  (reserved; MAME skips this slot)
	.long 0x00FFF0A8	; 0x40  INTT0
	.long 0x00FFF0BC	; 0x44  INTT1       -> IRQ_INTT1
	.long 0x00FFF0B8	; 0x48  INTT2       -> IRQ_INTT2.  This is the
				;                      interrupt CPU 2's micro-DMA
				;                      channel 2 is armed on at
				;                      0xF99A2A (DMA2V = 0x12,
				;                      0x12<<2 = 0x48).
	.long 0x00F98165	; 0x4C  INTT3
	.long 0x00FFF0A8	; 0x50  INTTR4
	.long 0x00FFF0A8	; 0x54  INTTR5
	.long 0x00FFF0A8	; 0x58  INTTR6
	.long 0x00FFF0A8	; 0x5C  INTTR7
	.long 0x00F991FF	; 0x60  INTRX0
	.long 0x00F99265	; 0x64  INTTX0
	.long 0x00FFF0A8	; 0x68  INTRX1
	.long 0x00FFF0A8	; 0x6C  INTTX1
	.long 0x00FFF0A8	; 0x70  INTAD
	.long 0x00FFF0A8	; 0x74  INTTC0
	.long 0x00FFF0A8	; 0x78  INTTC1
	.long 0x00FFF0C0	; 0x7C  INTTC2      -> IRQ_INTTC2
	.long 0x00FFF0C4	; 0x80  INTTC3      -> IRQ_INTTC3

; ==============================================================================
; 0xFFFF84-0xFFFFEE -- padding
; ==============================================================================
	.fill 0x6B, 1, 0x0E

; ==============================================================================
; 0xFFFFEF -- fc in MHz, as a byte
; ==============================================================================
; The UART init at 0xF991A2 reads this byte and computes
;   BR0CR = (M >> 1) & 0x0F
; With the baud-rate generator's fc/4 tap and the UART's own divide by 16 that
; makes the bit rate fc / (32*M), so a bit rate of 31250 comes out for ANY M
; provided fc = 1,000,000 * M.  M = 0x1C = 28 therefore asserts fc = 28 MHz in
; the ROM itself, without anyone having to decide which of several BR0CR writes
; is the operative one.  This byte is the ONLY value in the 0x6C-byte RET run
; that is not 0x0E.  See notes/FINDINGS-system-clock.md.
CLOCK_CONFIG_MHZ:
	.byte 0x1C

; ==============================================================================
; 0xFFFFF0 -- build tag
; ==============================================================================
BUILD_TAG:
	.ascii "wsac_230"
	.byte 0x02
	.ascii "ssf"
	.byte 0x00, 0x00, 0x00, 0x00
end:
