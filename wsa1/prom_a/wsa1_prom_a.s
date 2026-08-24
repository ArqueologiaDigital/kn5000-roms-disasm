	.text

; ==============================================================================
; Technics SX-WSA1R -- wsa1_prom_a.ic12
; Target CPU: Toshiba TMP95C061 (TLCS-900/H), "CPU 1" / IC1
; ==============================================================================
;
; IC12, program EPROM, base 0xF80000.  Load address ESTABLISHED: 33 of 64 words
; at file offset 0x7FF00 point into 0xF00000-0xFFFFFF, which is where a
; TMP95C061 fetches its reset PC (0xFFFF00).  The reset word itself is
; 0x00F826A9 and the code there is a textbook TLCS-900 boot block, which settles
; it.
;
; prom_a and prom_b (base 0xF00000) are one contiguous 1 MiB program image on the
; same bus; see prom_b/wsa1_prom_b.s for the four proofs of B's base.
;
; STATUS: partially converted.  Converted so far, as real assembly:
;   0xF826A9-0xF827C7  RESET, the whole boot path down to its jump into prom_b
;   0xFFFF00-0xFFFFFF  interrupt vector table, RET padding, build tag
; Everything else is still .incbin, so it builds byte-exact by construction and
; asserts nothing.  The gate (scripts/analysis/assert_byte_identical.py) must
; print PASS after every edit.
;
; PROVENANCE: this is not a chip read.  It is the publicly redistributed v2
; firmware set (../technics_roms/roms/wsa1/PROVENANCE.md).

	.include "include/tmp95c061_sfr.inc"

; ==============================================================================
; 0xF80000-0xF826A8 -- not yet converted
; ==============================================================================
wsa1_prom_a:
	.incbin "original_ROMs/wsa1_prom_a.ic12", 0x000000, 0x0026A9

; ==============================================================================
; RESET -- 0xF826A9, the address in the reset vector at 0xFFFF00
; ==============================================================================
;
; Structure: disarm the watchdog, program every port, program the timers, start
; them, program the memory controller, program the two UARTs, clear internal RAM
; and work DRAM, then jump into prom_b.  There is no stack yet -- the first
; instruction that needs one is on the far side of the jump (`ld XSP,0x0060EB80`
; at 0xF85606, reached through the prom_b thunk table), so nothing here may
; call.
;
; The memory-controller block below is the primary evidence for the CPU 1 memory
; map; notes/FINDINGS-memory-map.md gives the resulting map together with the
; parts of it that are NOT established.
;
RESET:
	; --- watchdog off ------------------------------------------------------
	ldio WDMOD,0x04
	ldio WDCR,0xB1		; 0xB1 is conventionally the watchdog DISABLE code.
				; NOT citable here: MAME stubs wdcr_w entirely
				; (tmp95c061.cpp:1126-1128) and no databook is in
				; these trees.  prom_c writes the same value.

	; --- ports -------------------------------------------------------------
	ldio P6,0x1B
	ldio P6FC,0x1F		; five alternate functions on port 6.  P6 is
				; "shared with CS0, CS1, CS3/LCAS, RAS, REFOUT"
				; (tmp95c061.h:19), so this turns on RAS and
				; REFOUT -- the DRAM controller is live -- and
				; makes the CS3 pin LCAS.  CS2 is NOT on port 6,
				; which is why the boot ROM's own chip select
				; needs no enabling here.
	ldio P2,0xFF
	ldio P2FC,0xFF		; port 2 entirely A16-A23
	ldio P5,0xFF
	ldio P5FC,0x24
	ldio P5CR,0x2C
	ldio P7,0xFF
	ldio P7FC,0x00
	ldio P7CR,0x33
	ldio P8,0xFF
	ldio P8FC,0x29		; port 8 is "shared with TXD0, TXD1, RXD0, RXD1,
				; CTS0, SCLK0, SCLK1" (tmp95c061.h:21); which
				; of bits 0/3/5 is which pin is NOT established
	ldio P8CR,0x09
	ldio PA,0xF9
	ldio PAFC,0x00
	ldio PACR,0x0E
	ldio PB,0xF3
	ldio PBFC,0x00
	ldio PBCR,0x0C

	; --- 8-bit timers 0-3 --------------------------------------------------
	ldio TRUN,0x00		; everything stopped while it is programmed
	ldio T01MOD,0x0D	; timer1 clock select = 3 -> phiT256 = fc/2048
				; (tap numbering per tmp94c241.cpp:1400/1528;
				; see notes/FINDINGS-system-clock.md section 6)
	ldio TFFCR,0x00
	ldio TREG0,0x0F
	ldio TREG1,0x1C		; 28 counts of phiT256 -> 488.28 Hz at 28 MHz
	ldio T23MOD,0x01
	ldio TREG2,0x00
	ldio TREG3,0x00
	ldio TRDC,0x00

	; --- 16-bit timers 4-7 -------------------------------------------------
	ldio T4MOD,0x05		; bits[1:0]=01 -> phiT1 = fc/8
	ldio T4FFCR,0x00
	ldio T45CR,0x00
	ldio TREG4L,0x01	; TREG4 = 0x0001
	ldio TREG4H,0x00
	ldio TREG5L,0x09	; TREG5 = 0x3D09 = 15625 -> 140.0 BPM.
	ldio TREG5H,0x3D	; INTTR4 (vector 0xFFFF50) is the sequencer tick;
				; the runtime tempo setter at 0xFAA373 computes
				; TREG5 = 140000000/(64*BPM), and 140,000,000 is
				; 5*fc.  That is the primary clock lever --
				; notes/FINDINGS-system-clock.md.
	ldio T5MOD,0x02
	ldio T5FFCR,0x00
	ldio TREG6L,0x98	; TREG6 = 0x3A98 = 15000
	ldio TREG6H,0x3A
	ldio TREG7L,0x98	; TREG7 = 0x3A98 = 15000
	ldio TREG7H,0x3A
	ldio TRUN,0xB7		; bit 7 = prescaler run (tmp95c061.cpp:672).  Bits 0-2
				; start 8-bit timers 0-2, bit 3 (timer 3) stays
				; off, bits 4-5 start 16-bit timers 4 and 5 --
				; timer 4 is the sequencer tick.

	; --- memory controller: block starts, then window masks ----------------
	; MSARn = A23-A16 of the block start.
	ldio MSAR0,0x78		; CS0 -> 0x780000.  ⚠ every CS0 device this
				; firmware actually touches lies at or above
				; 0x790000, and a byte census of prom_a+prom_b
				; finds nothing at all in 0x680000-0x78FFFF.
				; Of the two decoders that survive the
				; elimination, only the literal-base one puts
				; the window at 0x780000; the truncated-base one
				; puts it at 0x600000 and leaves the low 1.5 MB
				; of it empty.  See the MAMR note below.
	ldio MSAR1,0x00		; CS1 -> 0x000000, the static RAM
	ldio MSAR2,0xE0		; CS2 -> 0xE00000, the program EPROM area:
				; prom_b at 0xF00000, prom_a at 0xF80000
	ldio MSAR3,0x60		; CS3 -> 0x600000, the work DRAM (P6FC above
				; makes this pin LCAS)
	ldio MAMR0,0x3F
	ldio MAMR1,0x7F
	ldio MAMR2,0x3F
	ldio MAMR3,0x0F	; MAMR = window size.  MAME stores it and never decodes
			; it, and no databook is in these trees, so this is
			; ELIMINATION rather than decode:
			; scripts/analysis/mamr_reading_elimination.py feeds
			; eight candidate decoders {32 KB, 64 KB per MAMR unit}
			; x {base truncated to the window, base literal} x
			; {higher-numbered CS wins, lower wins} the values above
			; and checks each against facts from this firmware --
			; the DRAM must be on CS3, 0x7E0000 must be on CS0, the
			; EPROMs on CS2, and so on.  TWO of the eight survive,
			; and they differ only in the base convention:
			;   MAMR0 0x3F -> 2 MB     CS0 0x600000-0x7FFFFF
			;                       OR CS0 0x780000-0x97FFFF  ⚠
			;   MAMR1 0x7F -> 4 MB     CS1 0x000000-0x3FFFFF
			;   MAMR2 0x3F -> 2 MB     CS2 0xE00000-0xFFFFFF
			;   MAMR3 0x0F -> 512 KB   CS3 0x600000-0x67FFFF
			; So 32 KB per unit and higher-CS-wins are established
			; against the alternatives on the table; CS0's own
			; window is NOT ESTABLISHED, and that is the only row
			; the two survivors disagree on.

	; --- pattern generators off --------------------------------------------
	ldio PG0REG,0x00
	ldio PG1REG,0x00
	ldio PG01CR,0x00

	; --- serial channel 0 = the MIDI port ----------------------------------
	; Proven by traffic, not by inference: 0xFA544F onwards writes the MIDI
	; System Real-Time status bytes FC/F8/FE/FA/FB and 0xFA7D76 writes F6
	; straight into SC0BUF, and nothing else in any of the four images does.
	ldio SC0CR,0x00
	ldio SC0MOD,0x29	; bits[3:2] = 2 -> 8-bit UART, bits[1:0] = 1 ->
				; baud-rate generator as the clock source; both
				; decoded in tmp94c241_serial.cpp:271-285.
				; Bit 5 is the receive enable -- prom_c writes
				; 0x09 for the same port with that bit clear.
				; The name "RXE" is recalled, not cited: it
				; appears nowhere in src/devices/cpu/tlcs900/.
	ldio BR0CR,0x0C	; boot value: divide by 768.  ⚠ NOT the operative
			; one.  The runtime init at 0xFA58F2 overwrites it with
			; 0x0E (divide by 896) unless (0xFFFFF8) == 0x24, and
			; prom_a[0xFFFFF8] is 0x02 -- it is the separator byte
			; inside the build tag at the very end of this file.
			; 896 * 31250 = 28,000,000; 768 * 31250 = 24,000,000.
			; The parts list contains a 24 MHz oscillator too, so
			; this branch is a real variant, and lever 1 alone
			; cannot pick between them.  See the notes.
	ldio SC1CR,0x00
	ldio SC1MOD,0x01
	ldio BR1CR,0x36
	ldio ODE,0x03		; open-drain enable, bits 0 and 1.  Which outputs
				; those are is NOT established.

	; --- DRAM controller ---------------------------------------------------
	ldio DREFCR,0x71	; refresh enabled.  Field layout NOT established.
	ldio DMEMCR,0x8D	; access control.  Field layout NOT established.
				; 0xF830AC rewrites this as 0x2D immediately
				; before `set 5,(P6)` and `halt`, i.e. self
				; refresh for power-down.

	; --- chip-select enable + per-area access timing -----------------------
	; Bit layout NOT established -- see include/tmp95c061_sfr.inc.  Bit 3 is
	; set exactly on CS2 and CS3, which on this machine are exactly the two
	; 16-bit-wide areas (the flash unlock addresses on CPU 2 prove the width
	; for that CS2; here it is inference from the identical B2CS value).
	ldio B0CS,0x14
	ldio B1CS,0x17
	ldio B2CS,0x1B
	ldio B3CS,0x19
	ldio BEXCS,0x03		; everything outside the four areas
	ldio ADMOD,0x3F

	; --- interrupt controller ----------------------------------------------
	ldio IIMC,0x05
	ldio DMA0V,0x00		; no micro-DMA channel armed yet.  DMA2V is
	ldio DMA1V,0x00		; armed later, at 0xF8E166, with 0x12 -> vector
	ldio DMA2V,0x00		; 0x48 = INTT2: that is the engine that pushes
	ldio DMA3V,0x00		; packets at the other CPU through 0x7C0000.

	; --- clear internal RAM, 0x000080-0x0051FF -----------------------------
	; 0x1460 stores of 4 bytes = 0x5180 bytes from 0x80.  This is the only
	; thing that puts a size on the CS1 static RAM, and it is a lower bound,
	; not the chip size.
	ldw BC,0x1460
	ld XIX,0x00000080
	xor XWA,XWA
RESET__clear_iram:
	stl_dpi XWA,MEM_XIX_PI4		; ld (XIX+),XWA
	djnz16 BC,RESET__clear_iram

	; --- clear work DRAM, 0x600000-0x6033FF --------------------------------
	ld XBC,0x00000D00
	ld XIX,0x00600000
RESET__clear_dram_lo:
	stl_dpi XWA,MEM_XIX_PI4		; ld (XIX+),XWA
	sub XBC,0x00000001
	jr NZ,RESET__clear_dram_lo

	; --- clear work DRAM, 0x604000-0x60FFFF --------------------------------
	; ⚠ Note the hole: 0x603400-0x603FFF is deliberately NOT cleared, and it
	; is live -- prom_b reads it at 0xF440A5 (`ld XHL,0x00603400`).  That is
	; a preserved region across a warm restart, in the same spirit as the
	; KN5000's power-fail area.
	ld XBC,0x00003000
	ld XIX,0x00604000
RESET__clear_dram_hi:
	stl_dpi XWA,MEM_XIX_PI4		; ld (XIX+),XWA
	sub XBC,0x00000001
	jr NZ,RESET__clear_dram_hi

	; --- into prom_b -------------------------------------------------------
	; 0xF42D60 is a slot in prom_b's linker thunk table; it holds
	; `jp 0xF85606`, and 0xF85606 is `ld XSP,0x0060EB80`.  This single
	; instruction is one of the four things that fix prom_b's base.
	jp 0xF42D60

; ==============================================================================
; 0xF827C8-0xFFFEFF -- not yet converted
; ==============================================================================
	.incbin "original_ROMs/wsa1_prom_a.ic12", 0x0027C8, 0x07D738

; ==============================================================================
; 0xFFFF00 -- interrupt vector table
; ==============================================================================
;
; The TMP95C061 fetches every vector as a 32-bit little-endian word from
; 0xFFFF00 + offset (tmp95c061.cpp:560, `m_pc.d = RDMEML(0xffff00 + vector)`).
;
; What is CITED and what is CONVENTION:
;   0x00        cited -- the reset PC is fetched from 0xFFFF00
;               (tlcs900.cpp:215-217)
;   0x20        cited -- NMI, tmp95c061.cpp:505
;   0x28-0x80   cited -- names and offsets from tmp95c061_irq_vector_map[] at
;               tmp95c061.cpp:322-346
;   0x04-0x1C,  CONVENTION.  The names SWI1-SWI7 and INTWD are the usual
;   0x24        TLCS-900/H order; MAME does not name these slots and no
;               databook is available in these trees.  prom_c corroborates the
;               shape -- its 0x24 slot jumps back to its own reset entry (a
;               watchdog reboot) and its 0x04 slot does the same -- but that is
;               corroboration, not a citation.
;
VECTORS:
	.long 0x00F826A9	; 0x00  RESET      -> RESET, above
	.long 0x00F82D02	; 0x04  SWI1
	.long 0x00F82D03	; 0x08  SWI2 / INTUNDEF
	.long 0x00F82D04	; 0x0C  SWI3
	.long 0x00F82D05	; 0x10  SWI4
	.long 0x00F82D06	; 0x14  SWI5
	.long 0x00F82D07	; 0x18  SWI6
	.long 0x00F400A4	; 0x1C  SWI7       -> prom_b thunk (file 0x400A4:
				;                     `jp 0xF8E9A5`)
	.long 0x00F8306E	; 0x20  NMI
	.long 0x00F82CFF	; 0x24  INTWD
	.long 0x00F40EDC	; 0x28  INT0       -> prom_b thunk (file 0x40EDC:
				;                     `jp 0xF8E47F`)
	.long 0x00F82D08	; 0x2C  INT4
	.long 0x00F42D28	; 0x30  INT5
	.long 0x00F40F0C	; 0x34  INT6
	.long 0x00F82D09	; 0x38  INT7       -> the shared do-nothing stub
	.long 0x00F82D09	; 0x3C  (reserved; MAME skips this slot)
	.long 0x00F82D09	; 0x40  INTT0
	.long 0x00F82D0B	; 0x44  INTT1      -> increments the (0xA1) counter
				;                     used by the tempo cross-check
	.long 0x00F40EE0	; 0x48  INTT2      -> the micro-DMA 2 trigger armed
				;                     at 0xF8E166 (DMA2V = 0x12,
				;                     0x12<<2 = 0x48)
	.long 0x00F42D64	; 0x4C  INTT3
	.long 0x00F82EA2	; 0x50  INTTR4     -> the sequencer tick: 96 ticks
				;                     per beat, wraps at 0x60
	.long 0x00F82D09	; 0x54  INTTR5     -> stub.  Worth knowing, because
				;                     the tempo code writes TREG5
				;                     and a reader expects INTTR5.
	.long 0x00F82D09	; 0x58  INTTR6
	.long 0x00F82D09	; 0x5C  INTTR7
	.long 0x00F40714	; 0x60  INTRX0     -> MIDI in
	.long 0x00F40718	; 0x64  INTTX0     -> MIDI out
	.long 0x00F40F10	; 0x68  INTRX1
	.long 0x00F40F14	; 0x6C  INTTX1
	.long 0x00F82D09	; 0x70  INTAD
	.long 0x00F42D30	; 0x74  INTTC0
	.long 0x00F82D09	; 0x78  INTTC1
	.long 0x00F40EE4	; 0x7C  INTTC2     -> micro-DMA 2 completion
	.long 0x00F40EE8	; 0x80  INTTC3

; ==============================================================================
; 0xFFFF84-0xFFFFEF -- padding
; ==============================================================================
; 0x0E is the one-byte RET opcode, which is what this toolchain's images pad
; with.  In prom_c the byte at 0xFFFFEF is NOT padding -- it is a configuration
; byte holding fc in MHz.  Here it really is 0x0E, so CPU 1 does not use that
; mechanism; it takes the (0xFFFFF8) == 0x24 branch at 0xFA58FB instead.
	.fill 0x6C, 1, 0x0E

; ==============================================================================
; 0xFFFFF0 -- build tag
; ==============================================================================
; The byte at 0xFFFFF8 is the 0x02 separator inside this tag, and it is what the
; runtime UART init at 0xFA58FB compares against 0x24 to choose the baud divisor.
; prom_c and prom_d carry the same shape of tag; prom_b does not, which is one
; of the signs that prom_b is the low half of a contiguous image rather than an
; image in its own right.
BUILD_TAG:
	.ascii "wsaa_822"
	.byte 0x02
	.ascii "ssf"
	.byte 0x00, 0x00, 0x00, 0x00
end:
