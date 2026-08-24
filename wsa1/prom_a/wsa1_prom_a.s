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
; STATUS: partially converted -- 4278 of 524288 bytes.  Converted so far, as
; real assembly (everything else is still .incbin, so it builds byte-exact by
; construction and asserts nothing):
;
;   0xF826A9-0xF827C7   287  RESET, the whole boot path to its jump into prom_b
;   0xF82CFF-0xF830C5   967  INTWD, the unused-vector trap, INTT1 and INTTR4 with
;                            their dispatch tables, the event-buffer append, NMI
;                            (power-fail) and its checksum helper
;   0xF856EC-0xF857D5   234  the kernel: idle loop, task switch, software timers,
;                            and IRQ_Epilogue, where every handler exits
;   0xF85F59-0xF85FF8   160  the DSP / tone-generator register writers at 0x7F0000
;   0xF8E47F-0xF8E54E   208  INT0, the inter-processor link receiver, and INTTC2
;   0xF8E6A2-0xF8E6F9    88  micro-DMA channel setup helpers, and a block copy
;   0xF8E800-0xF8EAC6   711  the SED1330-family LCD controller: entry thunks, the
;                            power-on setup, the SWI7 gateway and its 64-slot table
;   0xF8ECB5-0xF8EDB3   255  SWI7 service 0x0B, plot a pixel, and its mask table
;   0xF8F7B8-0xF8F84F   152  SWI7 services 0x0C and 0x0D, layer visibility
;   0xFA5418-0xFA570B   756  the MIDI port: both interrupt handlers, the System
;                            Real Time receiver and the tempo tracker
;   0xFE68F3-0xFE69BE   204  the 64-bit integer divide runtime.  170 of these bytes
;                            (0xFE68F2-0xFE699B) are shared with the KN5000 sub-CPU;
;                            the tail DIVERGES from 0xFE699C onward.  Corrected
;                            2026-08-24: this banner said "byte for byte", which the
;                            body of the file (see 0xFE68F3's header) never claimed.
;   0xFFFF00-0xFFFFFF   256  interrupt vector table, RET padding, build tag
;
; The gate (scripts/analysis/assert_byte_identical.py) must print PASS after
; every edit.  It compares BYTES; it is blind to whether a name or a comment is
; right, so every header below says what its name is evidenced by.
;
; TOOLS THAT PRODUCED THE CONVERTED TEXT, all in prom_a/ and all documented in
; their own docstrings:
;   roundtrip.py           bytes -> llvm-mc source, re-assembled and byte-compared
;                          before anything is printed; --block also resolves
;                          branch targets to labels and verifies the whole block
;   insert_region.py       splices a converted region in and fixes the .incbin math
;   kn5000_run_offsets.py  proves the KN5000 payload offset->address mapping that
;                          the transplanted names depend on (--proposals re-runs
;                          the whole transplant with it)
;
; SUBSYSTEM NOTES written from this file:
;   notes/FINDINGS-display-controller.md      the SED1330-family LCD controller
;   notes/FINDINGS-midi-port.md               serial channel 0 and (0xA0)
;   notes/FINDINGS-interprocessor-link.md     INT0 and the micro-DMA hand-off
;   notes/FINDINGS-kn5000-transplant-offset.md  the corrected KN5000 name mapping
;
; PROVENANCE: this is not a chip read.  It is the publicly redistributed v2
; firmware set (../technics_roms/roms/wsa1/PROVENANCE.md).

	.include "include/tmp95c061_sfr.inc"

; MACRO-PRELUDE-BEGIN
; ==============================================================================
; Memory-operand macros -- the TLCS-900 forms llvm-mc's tlcs900 backend has no
; encoding for
; ==============================================================================
;
; WHY THIS EXISTS.  The TMP95C061 puts its I/O registers at 0x00-0x7F and the
; start of static RAM at 0x80, so this firmware reaches almost all of its state
; through the TLCS-900 "(n)" 8-bit-direct memory operand.  llvm-mc's tlcs900
; backend implements only a handful of the resulting instructions (ld_sd8b,
; st_dd8b, and_sd8b_im, or_sd8b_im, bit_dd8, set_dd8, res_dd8, call_dd8); the
; rest -- `inc 1,(0x9c)`, `cp (0x9c),0xa5`, `incw 1,(0x8e)` and so on -- have no
; spelling at all.  Without these macros they would have to stay as raw .byte.
;
; WHAT THEY EMIT, AND WHERE THAT COMES FROM.  A TLCS-900 memory-operand
; instruction is <prefix byte> <address bytes> <operation byte> [<immediate>].
; Both halves are read straight off MAME's disassembler tables, which is the
; same authority unidasm prints from:
;
;   prefix   src/devices/cpu/tlcs900/dasm900.cpp
;     0xC0-0xC2  byte-size operand  -> mnemonic_c0[] (dasm900.cpp:679, :1600)
;     0xD0-0xD2  word-size operand  -> mnemonic_d0[] (dasm900.cpp:846, :1693)
;     0xE0-0xE2  long-size operand  -> mnemonic_e0[] (dasm900.cpp:1012, :1787)
;     0xF0-0xF2  "destination" ops  -> mnemonic_f0[] (dasm900.cpp:1178, :1880)
;   the low two bits of the prefix pick the address width:
;     0 -> one address byte, 1 -> two, 2 -> three (dasm900.cpp:1521-1560)
;
; ⚠ The width is NOT implied by the address value -- this firmware really does
; write `set 7,(0x00008a)` as F2 8A 00 00 BF, the 24-bit form, for an address
; that fits in eight bits.  So every macro takes the prefix explicitly and none
; of them tries to pick a shorter encoding.
;
; ⚠ These macros are byte emitters.  The gate proves they emit the right bytes.
; It cannot prove the NAME on the macro is the right mnemonic -- that comes from
; the tables cited above and from unidasm, and every use below carries unidasm's
; own text in the trailing comment so the two can be compared by eye.

; --- operand prefixes: <size><address width> ---------------------------------
.equ MB8,  0xC0		; byte operand, 8-bit direct address	(n)
.equ MB16, 0xC1		; byte operand, 16-bit direct address	(nn)
.equ MB24, 0xC2		; byte operand, 24-bit direct address	(nnn)
.equ MW8,  0xD0		; word operand, 8-bit direct address
.equ MW16, 0xD1		; word operand, 16-bit direct address
.equ MW24, 0xD2		; word operand, 24-bit direct address
.equ ML8,  0xE0		; long operand, 8-bit direct address
.equ ML16, 0xE1		; long operand, 16-bit direct address
.equ ML24, 0xE2		; long operand, 24-bit direct address
.equ MD8,  0xF0		; "dst"-table op, 8-bit direct address
.equ MD16, 0xF1		; "dst"-table op, 16-bit direct address
.equ MD24, 0xF2		; "dst"-table op, 24-bit direct address

; --- the same operations, but with a REGISTER-relative operand ---------------
; dasm900.cpp:1473-1521.  Add the register index (r0-r7 below) to the constant:
; `MWD+r7` is "word-size operand at (XSP+d8)".  The forms with a displacement
; take exactly one displacement byte; the forms without take none.
.equ MBI, 0x80		; byte operand at (Rn)		-> mnemonic_80[]
.equ MBD, 0x88		; byte operand at (Rn+d8)	-> mnemonic_88[]
.equ MWI, 0x90		; word operand at (Rn)		-> mnemonic_90[]
.equ MWD, 0x98		; word operand at (Rn+d8)	-> mnemonic_98[]
.equ MLI, 0xA0		; long operand at (Rn)		-> mnemonic_a0[]
.equ MLD, 0xA8		; long operand at (Rn+d8)	-> mnemonic_a0[]
.equ MDI, 0xB0		; "dst"-table op at (Rn)	-> mnemonic_b0[]
.equ MDD, 0xB8		; "dst"-table op at (Rn+d8)	-> mnemonic_b8[]

; --- register index inside an operation byte ---------------------------------
; dasm900.cpp:1345-1347.  The same index selects W/A/B/C/D/E/H/L,
; WA/BC/DE/HL/IX/IY/IZ/SP or XWA/XBC/XDE/XHL/XIX/XIY/XIZ/XSP according to the
; size the prefix already chose.
.equ r0, 0	; W   / WA / XWA
.equ r1, 1	; A   / BC / XBC
.equ r2, 2	; B   / DE / XDE
.equ r3, 3	; C   / HL / XHL
.equ r4, 4	; D   / IX / XIX
.equ r5, 5	; E   / IY / XIY
.equ r6, 6	; H   / IZ / XIZ
.equ r7, 7	; L   / SP / XSP

; --- prefix + address bytes --------------------------------------------------
; \addr is the direct address for the MB*/MW*/ML*/MD* prefixes and the 8-bit
; displacement for the MBD/MWD/MLD/MDD ones; the MBI/MWI/MLI/MDI prefixes take
; no address bytes at all and ignore it (pass 0).
.macro _mem pfx, addr
	.byte \pfx
	.if ((\pfx) & 0xC0) == 0xC0
	.byte (\addr) & 0xFF
	.if ((\pfx) & 3) >= 1
	.byte ((\addr) >> 8) & 0xFF
	.endif
	.if ((\pfx) & 3) >= 2
	.byte ((\addr) >> 16) & 0xFF
	.endif
	.else
	.if ((\pfx) & 0x08) != 0
	.byte (\addr) & 0xFF
	.endif
	.endif
.endm

; --- mnemonic_c0/d0/e0 operations (dasm900.cpp:679/846/1012) -----------------
.macro m_push pfx, addr			; push (addr)			op 0x04
	_mem \pfx, \addr
	.byte 0x04
.endm
.macro m_ld_rm pfx, addr, r		; ld  R,(addr)			op 0x20+r
	_mem \pfx, \addr
	.byte 0x20 + (\r)
.endm
.macro m_ex_mr pfx, addr, r		; ex  (addr),R			op 0x30+r
	_mem \pfx, \addr
	.byte 0x30 + (\r)
.endm
.macro m_add_mi8 pfx, addr, imm		; add (addr),#imm8		op 0x38
	_mem \pfx, \addr
	.byte 0x38, \imm
.endm
.macro m_and_mi8 pfx, addr, imm		; and (addr),#imm8		op 0x3C
	_mem \pfx, \addr
	.byte 0x3C, \imm
.endm
.macro m_xor_mi8 pfx, addr, imm		; xor (addr),#imm8		op 0x3D
	_mem \pfx, \addr
	.byte 0x3D, \imm
.endm
.macro m_or_mi8 pfx, addr, imm		; or  (addr),#imm8		op 0x3E
	_mem \pfx, \addr
	.byte 0x3E, \imm
.endm
.macro m_cp_mi8 pfx, addr, imm		; cp  (addr),#imm8		op 0x3F
	_mem \pfx, \addr
	.byte 0x3F, \imm
.endm
.macro m_cp_mi16 pfx, addr, imm		; cp  (addr),#imm16		op 0x3F
	_mem \pfx, \addr
	.byte 0x3F, (\imm) & 0xFF, ((\imm) >> 8) & 0xFF
.endm
.macro m_mul pfx, addr, r		; mul  RR,(addr)		op 0x40+r
	_mem \pfx, \addr
	.byte 0x40 + (\r)
.endm
.macro m_muls pfx, addr, r		; muls RR,(addr)		op 0x48+r
	_mem \pfx, \addr
	.byte 0x48 + (\r)
.endm
.macro m_inc n, pfx, addr		; inc n,(addr)			op 0x60+n
	_mem \pfx, \addr
	.byte 0x60 + ((\n) & 7)
.endm
.macro m_dec n, pfx, addr		; dec n,(addr)			op 0x68+n
	_mem \pfx, \addr
	.byte 0x68 + ((\n) & 7)
.endm
.macro m_add_rm pfx, addr, r		; add R,(addr)			op 0x80+r
	_mem \pfx, \addr
	.byte 0x80 + (\r)
.endm
.macro m_add_mr pfx, addr, r		; add (addr),R			op 0x88+r
	_mem \pfx, \addr
	.byte 0x88 + (\r)
.endm
.macro m_sub_rm pfx, addr, r		; sub R,(addr)			op 0xA0+r
	_mem \pfx, \addr
	.byte 0xA0 + (\r)
.endm
.macro m_sub_mr pfx, addr, r		; sub (addr),R			op 0xA8+r
	_mem \pfx, \addr
	.byte 0xA8 + (\r)
.endm
.macro m_sbc_rm pfx, addr, r		; sbc R,(addr)			op 0xB0+r
	_mem \pfx, \addr
	.byte 0xB0 + (\r)
.endm
.macro m_and_rm pfx, addr, r		; and R,(addr)			op 0xC0+r
	_mem \pfx, \addr
	.byte 0xC0 + (\r)
.endm
.macro m_xor_rm pfx, addr, r		; xor R,(addr)			op 0xD0+r
	_mem \pfx, \addr
	.byte 0xD0 + (\r)
.endm
.macro m_or_rm pfx, addr, r		; or  R,(addr)			op 0xE0+r
	_mem \pfx, \addr
	.byte 0xE0 + (\r)
.endm
.macro m_cp_rm pfx, addr, r		; cp  R,(addr)			op 0xF0+r
	_mem \pfx, \addr
	.byte 0xF0 + (\r)
.endm
.macro m_cp_mr pfx, addr, r		; cp  (addr),R			op 0xF8+r
	_mem \pfx, \addr
	.byte 0xF8 + (\r)
.endm

; --- mnemonic_f0 operations (dasm900.cpp:1178) -------------------------------
.macro m_ld_mi8 pfx, addr, imm		; ld  (addr),#imm8		op 0x00
	_mem \pfx, \addr
	.byte 0x00, \imm
.endm
.macro m_ld_mi16 pfx, addr, imm		; ldw (addr),#imm16		op 0x02
	_mem \pfx, \addr
	.byte 0x02, (\imm) & 0xFF, ((\imm) >> 8) & 0xFF
.endm
.macro m_lda16 pfx, addr, r		; lda R16,(addr)		op 0x20+r
	_mem \pfx, \addr
	.byte 0x20 + (\r)
.endm
.macro m_lda32 pfx, addr, r		; lda R32,(addr)		op 0x30+r
	_mem \pfx, \addr
	.byte 0x30 + (\r)
.endm
.macro m_st_mr8 pfx, addr, r		; ld (addr),R8			op 0x40+r
	_mem \pfx, \addr
	.byte 0x40 + (\r)
.endm
.macro m_st_mr16 pfx, addr, r		; ld (addr),R16			op 0x50+r
	_mem \pfx, \addr
	.byte 0x50 + (\r)
.endm
.macro m_st_mr32 pfx, addr, r		; ld (addr),R32			op 0x60+r
	_mem \pfx, \addr
	.byte 0x60 + (\r)
.endm
.macro m_stcf n, pfx, addr		; stcf n,(addr)			op 0xA0+n
	_mem \pfx, \addr
	.byte 0xA0 + ((\n) & 7)
.endm
.macro m_res n, pfx, addr		; res n,(addr)			op 0xB0+n
	_mem \pfx, \addr
	.byte 0xB0 + ((\n) & 7)
.endm
.macro m_set n, pfx, addr		; set n,(addr)			op 0xB8+n
	_mem \pfx, \addr
	.byte 0xB8 + ((\n) & 7)
.endm
.macro m_chg n, pfx, addr		; chg n,(addr)			op 0xC0+n
	_mem \pfx, \addr
	.byte 0xC0 + ((\n) & 7)
.endm
.macro m_bit n, pfx, addr		; bit n,(addr)			op 0xC8+n
	_mem \pfx, \addr
	.byte 0xC8 + ((\n) & 7)
.endm
.macro m_pop pfx, addr			; pop  (addr)			op 0x04
	_mem \pfx, \addr
	.byte 0x04
.endm
.macro m_ld_mm16 pfx, addr, src		; ld  (addr),(src16)		op 0x14
	_mem \pfx, \addr
	.byte 0x14, (\src) & 0xFF, ((\src) >> 8) & 0xFF
.endm
.macro m_ldw_mm16 pfx, addr, src	; ldw (addr),(src16)		op 0x16
	_mem \pfx, \addr
	.byte 0x16, (\src) & 0xFF, ((\src) >> 8) & 0xFF
.endm

; --- LDC: the control registers (dasm900.cpp:779, mnemonic_c8[0x2E]/[0x2F]) ---
; The operand is a REGISTER-DIRECT prefix -- RB/RW/RL plus the register index
; r0-r7 above -- and a control-register NUMBER.  unidasm prints that number as
; "unknown": MAME does not name the TLCS-900 control registers and no databook is
; in these trees, so it stays a number here too.
.equ RB, 0xC8		; + index -> W  A  B  C  D  E  H  L
.equ RW, 0xD8		; + index -> WA BC DE HL IX IY IZ SP
.equ RL, 0xE8		; + index -> XWA XBC XDE XHL XIX XIY XIZ XSP
.macro m_ldc_cr_reg rp, cr		; ldc <cr>,R			op 0x2E
	.byte \rp, 0x2E, \cr
.endm
.macro m_ldc_reg_cr rp, cr		; ldc R,<cr>			op 0x2F
	.byte \rp, 0x2F, \cr
.endm

; Control-register NUMBERS.  These four groups are the only ones MAME decodes
; for this part -- 900tbl.hxx:3931-4030, where the `// TMP96C141/TMP95C061/
; TMP95C063` cases map them onto m_dmas/m_dmad/m_dmac/m_dmam.  Anything outside
; them (0x3C, used as the kernel's depth counter at 0xF856EC) lands on MAME's
; m_dummy, so MAME neither names nor decodes it, and neither does this file.
.equ CR_DMAS0, 0x00	; 32-bit source
.equ CR_DMAS1, 0x04
.equ CR_DMAS2, 0x08
.equ CR_DMAS3, 0x0C
.equ CR_DMAD0, 0x10	; 32-bit destination
.equ CR_DMAD1, 0x14
.equ CR_DMAD2, 0x18
.equ CR_DMAD3, 0x1C
.equ CR_DMAC0, 0x20	; 16-bit transfer count
.equ CR_DMAC1, 0x24
.equ CR_DMAC2, 0x28
.equ CR_DMAC3, 0x2C
.equ CR_DMAM0, 0x22	; 8-bit mode
.equ CR_DMAM1, 0x26
.equ CR_DMAM2, 0x2A
.equ CR_DMAM3, 0x2E
; MACRO-PRELUDE-END

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
	.incbin "original_ROMs/wsa1_prom_a.ic12", 0x0027C8, 0x000537

; ==============================================================================
; 0xF82CFF-0xF82EA1 -- the interrupt entry points that live in prom_a's low half
; ==============================================================================
; Reached from the vector table at 0xFFFF00 (end of this file).  Everything here
; was converted with prom_a/roundtrip.py, which re-assembles each instruction and
; compares bytes before printing it; the trailing "; ADDR bytes" comment on every
; line is that comparison, kept so a reader can check the decode against unidasm.

; ---------------------------------------------------------------------
; INTWD_Reboot -- watchdog interrupt: restart the machine
;
; Called from: vector slot 0x24 (0xFFFF24 holds 0x00F82CFF)
; Inputs:  none
; Outputs: never returns -- control resumes at RESET, which re-programs every
;          SFR from scratch.  The stack pointer is NOT reset here; RESET does not
;          set one either, so the first stack user is `ld XSP,0x0060EB80` on the
;          far side of the jump into prom_b.
; Notes:   the slot name "INTWD" is the conventional TLCS-900/H order, not a
;          citation (MAME does not name slots below 0x28).  prom_c's 0x24 slot
;          does the same thing, which is corroboration, not proof.
; ---------------------------------------------------------------------
INTWD_Reboot:
	jrl T,RESET                                       ; F82CFF  78 a7 f9

; ---------------------------------------------------------------------
; IRQ_UnusedVector_Hang -- deliberate dead end for every vector not used
;
; Called from: vector slots 0x04-0x18 (SWI1-SWI6) and 0x2C (INT4) land on the
;          seven NOPs at 0xF82D02-0xF82D08 and fall through into the loop;
;          slots 0x38, 0x3C, 0x40, 0x54, 0x58, 0x5C, 0x70 and 0x78 point at
;          0xF82D09 directly.
; Inputs:  none
; Outputs: none -- it never returns and never executes RETI, so the interrupt
;          stays acknowledged and the machine stops.  This is a trap, not a
;          "do nothing" stub, and it is worth knowing when reading a hang.
; Notes:   the seven NOPs are one byte apart because each SWI slot points one
;          byte further along; that is the whole reason they exist.
; ---------------------------------------------------------------------
	nop                                           ; F82D02  00
	nop                                           ; F82D03  00
	nop                                           ; F82D04  00
	nop                                           ; F82D05  00
	nop                                           ; F82D06  00
	nop                                           ; F82D07  00
	nop                                           ; F82D08  00
IRQ_UnusedVector_Hang:
	jr T,IRQ_UnusedVector_Hang                                 ; F82D09  68 fe

; ---------------------------------------------------------------------
; INTT1_Tick -- 8-bit timer 1 interrupt: the firmware's periodic time base
;
; Called from: vector slot 0x44 (0xFFFF44 holds 0x00F82D0B)
; Inputs:  the RAM state below
; Outputs: (0x80) long ++, (0x605A00) word ++, (0xA1) saturating counter,
;          transport state bytes (0x94)/(0x95)/(0x96), MIDI real-time transmit
;          requests in (0xA0), and whichever bit of (0x88) the rota clears this
;          tick.  Registers WA and XHL are preserved.
; Notes:   RESET programs T01MOD/TREG1 and starts timer 1 (TRUN bit 1); the
;          rate that comes out of those two values is worked out in
;          notes/FINDINGS-system-clock.md, not restated here.
;
;          RAM the handler touches, and what can be said about each WITHOUT
;          guessing (all of it is CS1 static RAM -- the 16-bit-direct operands
;          like (0x7F32) are RAM addresses 0x007F32, not the 0x7F0000 port):
;            (0x80)     32-bit, incremented every tick.  A free-running tick
;                       count; nothing here reads it.
;            (0x605A00) 16-bit work-DRAM counter, incremented every tick.
;            (0x9D)/(0x9E) a 0..0x86 counter and a flag byte carried together.
;                       When the counter passes 0x86 it wraps to 0 and requests
;                       (0xA0) bit 4.  135 ticks per wrap -- see below.
;            (0x9C)     counted up while bit 7 of (0x9E) is set, and at 0xA5
;                       rewrites (0x9E) as (0x9E & 0x7F) | 0x20.
;            (0xA1)     saturating counter, stops at 0xF2.
;            (0x88)     bitmap the rota below clears one bit of at a time.
;            (0x94)(0x95)(0x96) three state bytes taking the values 0x01, 0x06,
;                       0x10, 0x86 -- three copies of one small state machine.
;                       Which three things they belong to is NOT established.
;            (0x2078)   compared against 0x0D before any request is posted.
;            (0x7F32)/(0x7F34) bit 2 of each gates the whole transport section.
;
;          ★ THREE OF THOSE ARE NAMED BY THE MIDI HANDLERS, not by this routine
;          -- MIDI_TX_Ready (0xFA542F) and MIDI_RX_Byte (0xFA5496), both
;          converted further down this file:
;            (0xA0) is the MIDI System Real Time TRANSMIT REQUEST bitmap.  The
;                   transmit interrupt turns bit 0 into 0xF8 TIMING CLOCK, bit 1
;                   into 0xFA START, bit 2 into 0xFB CONTINUE, bit 3 into 0xFC
;                   STOP and bit 4 into 0xFE ACTIVE SENSING.  So the two `or
;                   (0xA0),0x08` / `or (0xA0),0x01` sites below are STOP and
;                   TIMING CLOCK, and the 135-tick wrap requests ACTIVE SENSING.
;            (0x9E) bit 7 is set when a 0xFE ACTIVE SENSING is RECEIVED
;                   (0xFA5509), and (0x9C) -- which the receive interrupt zeroes
;                   on every incoming byte (0xFA54AE) -- is therefore the
;                   receive-inactivity timer.  Giving up at 0xA5 = 166 ticks.
;            (0xA1) is the gap between incoming 0xF8 TIMING CLOCK bytes, in
;                   ticks; 0xFA553E turns it into TREG5, the tempo.  That
;                   conversion is lever B of notes/FINDINGS-system-clock.md.
;          At the 488.28 Hz that note derives, 135 ticks is 277 ms and 166 ticks
;          is 340 ms -- one either side of MIDI 1.0's 300 ms active-sensing
;          rule, which is what a correct implementation looks like.
;
;          0xF40724 is a prom_b thunk holding `jp 0xFA590F`; that routine is the
;          work poster -- it either sets (0x77) to 0xDD or, when (0x89) is 0xFF,
;          calls into prom_b and clears (0xA0).  So "or (0xA0),n; call 0xF40724"
;          is "queue this MIDI real-time byte and wake the sender".
; ---------------------------------------------------------------------
INTT1_Tick:
	pushw wa                                      ; F82D0B  28
	push XHL                                      ; F82D0C  3b
	xor XHL,XHL                                   ; F82D0D  eb d3
	inc 1,XHL                                     ; F82D0F  eb 61
	m_add_mr ML8, 0x80, r3                        ; F82D11  e0 80 8b
	incdi16_24 0x01, (0x605a00)                   ; F82D14  d2 00 5a 60 61
	push SR                                       ; F82D19  02
	ei 0x06                                       ; F82D1A  06 06
	ld_sd8b a, 0x9e                               ; F82D1C  c0 9e 21
	ld_sd8b w, 0x9d                               ; F82D1F  c0 9d 20
	bit 0x07,A                                    ; F82D22  c9 33 07
	jr Z,.LF82D36                                 ; F82D25  66 0f
	m_inc 1, MB8, 0x9c                            ; F82D27  c0 9c 61
	m_cp_mi8 MB8, 0x9c, 0xa5                      ; F82D2A  c0 9c 3f a5
	jr ULE,.LF82D36                               ; F82D2E  63 06
	and A,0x7f                                    ; F82D30  c9 cc 7f
	or A,0x20                                     ; F82D33  c9 ce 20
.LF82D36:
	inc 1,W                                       ; F82D36  c8 61
	cp W,0x86                                     ; F82D38  c8 cf 86
	jr ULE,.LF82D47                               ; F82D3B  63 0a
	ldb w, 0x00                                   ; F82D3D  20 00
	m_or_mi8 MB8, 0xa0, 0x10                      ; F82D3F  c0 a0 3e 10
	call 0xf40724                                 ; F82D43  1d 24 07 f4
.LF82D47:
	st_dd8b w, 0x9d                               ; F82D47  f0 9d 40
	st_dd8b a, 0x9e                               ; F82D4A  f0 9e 41
	pop SR                                        ; F82D4D  03
	ld_sd8b a, 0xa1                               ; F82D4E  c0 a1 21
	cp A,0xf1                                     ; F82D51  c9 cf f1
	jr UGT,.LF82D58                               ; F82D54  6b 02
	inc 1,A                                       ; F82D56  c9 61
.LF82D58:
	st_dd8b a, 0xa1                               ; F82D58  f0 a1 41
	m_bit 2, MD16, 0x7f32                         ; F82D5B  f1 32 7f ca
	jr NZ,.LF82DCB                                ; F82D5F  6e 6a
	m_inc 1, MB8, 0x90                            ; F82D61  c0 90 61
	bit_dd8 0x00, 0x95                            ; F82D64  f0 95 c8
	jr NZ,.LF82D9D                                ; F82D67  6e 34
	bit_dd8 0x05, 0x95                            ; F82D69  f0 95 cd
	jr NZ,.LF82D73                                ; F82D6C  6e 05
	ldio 0x90, 0x00                               ; F82D6E  08 90 00
	jr T,.LF82DE5                                 ; F82D71  68 72
.LF82D73:
	m_cp_mi8 MB8, 0x90, 0x01                      ; F82D73  c0 90 3f 01
	jr NC,.LF82DE5                                ; F82D77  6f 6c
	ldio 0x95, 0x10                               ; F82D79  08 95 10
.LF82D7C:
	m_cp_mi8 MB16, 0x2078, 0x0d                   ; F82D7C  c1 78 20 3f 0d
	jr Z,.LF82D9B                                 ; F82D81  66 18
	m_bit 2, MD16, 0x7f34                         ; F82D83  f1 34 7f ca
	jr Z,.LF82D9B                                 ; F82D87  66 12
	m_bit 2, MD16, 0x7f32                         ; F82D89  f1 32 7f ca
	jr NZ,.LF82D9B                                ; F82D8D  6e 0c
	push SR                                       ; F82D8F  02
	ei 0x06                                       ; F82D90  06 06
	m_or_mi8 MB8, 0xa0, 0x08                      ; F82D92  c0 a0 3e 08
	call 0xf40724                                 ; F82D96  1d 24 07 f4
	pop SR                                        ; F82D9A  03
.LF82D9B:
	jr T,.LF82DE5                                 ; F82D9B  68 48
.LF82D9D:
	m_cp_mi8 MB8, 0x90, 0x01                      ; F82D9D  c0 90 3f 01
	jr ULE,.LF82DE5                               ; F82DA1  63 42
	ldio 0x95, 0x06                               ; F82DA3  08 95 06
	bit_dd8 0x00, 0x94                            ; F82DA6  f0 94 c8
	jr Z,.LF82DAE                                 ; F82DA9  66 03
	ldio 0x94, 0x06                               ; F82DAB  08 94 06
.LF82DAE:
	bit_dd8 0x00, 0x96                            ; F82DAE  f0 96 c8
	jr Z,.LF82DB6                                 ; F82DB1  66 03
	ldio 0x96, 0x06                               ; F82DB3  08 96 06
.LF82DB6:
	m_cp_mi8 MB16, 0x2078, 0x0d                   ; F82DB6  c1 78 20 3f 0d
	jr Z,.LF82DC9                                 ; F82DBB  66 0c
	push SR                                       ; F82DBD  02
	ei 0x06                                       ; F82DBE  06 06
	m_or_mi8 MB8, 0xa0, 0x01                      ; F82DC0  c0 a0 3e 01
	call 0xf40724                                 ; F82DC4  1d 24 07 f4
	pop SR                                        ; F82DC8  03
.LF82DC9:
	jr T,.LF82DE5                                 ; F82DC9  68 1a
.LF82DCB:
	bit_dd8 0x03, 0x94                            ; F82DCB  f0 94 cb
	jr Z,.LF82DD3                                 ; F82DCE  66 03
	ldio 0x94, 0x10                               ; F82DD0  08 94 10
.LF82DD3:
	bit_dd8 0x03, 0x96                            ; F82DD3  f0 96 cb
	jr Z,.LF82DDB                                 ; F82DD6  66 03
	ldio 0x96, 0x10                               ; F82DD8  08 96 10
.LF82DDB:
	bit_dd8 0x03, 0x95                            ; F82DDB  f0 95 cb
	jr Z,.LF82DE5                                 ; F82DDE  66 05
	ldio 0x95, 0x10                               ; F82DE0  08 95 10
	jr T,.LF82D7C                                 ; F82DE3  68 97
.LF82DE5:
	ld_sd8b a, 0x86                               ; F82DE5  c0 86 21
	inc 1,A                                       ; F82DE8  c9 61
	cps a, 0x02                                   ; F82DEA  c9 da
	jr ULE,.LF82DF3                               ; F82DEC  63 05
	sub A,A                                       ; F82DEE  c9 a1
	m_inc 1, MB8, 0x87                            ; F82DF0  c0 87 61
.LF82DF3:
	st_dd8b a, 0x86                               ; F82DF3  f0 86 41
	sll a, 0x02                                   ; F82DF6  c9 ee 02
	ld XHL,INTT1_Phase_Table                             ; F82DF9  43 05 2e f8 00
	.byte 0xe3, 0x03, 0xec, 0xe0, 0x23            ; F82DFE  e3 03 ec e0 23   ld XHL,(XHL+A) -- the table fetch; llvm-mc has no (R+R) form
	jp (xhl)                                      ; F82E03  b3 d8

; ---------------------------------------------------------------------
; INTT1_Phase_Table -- 3-entry dispatch table for INTT1's tail
;
; Read by:  0xF82DF9 (`ld XHL,INTT1_Phase_Table`), indexed by (0x86)*4.
; Layout:   3 x LE32 code pointer.  (0x86) counts 0,1,2 and (0x87) is
;           incremented on every wrap, so each phase runs once in three ticks.
; ---------------------------------------------------------------------
INTT1_Phase_Table:
	.long INTT1_Phase0_Idle		; F82E05  11 2e f8 00
	.long INTT1_Phase1_ClearFlags	; F82E09  14 2e f8 00
	.long INTT1_Phase2_Rota		; F82E0D  23 2e f8 00

INTT1_Phase0_Idle:
	jrl T,INTT1_Return                                      ; F82E11  78 88 00
INTT1_Phase1_ClearFlags:
	m_and_mi8 MB8, 0x98, 0x6e                     ; F82E14  c0 98 3c 6e
	bit_dd8 0x00, 0x87                            ; F82E18  f0 87 c8
	jr NZ,.LF82E20                                ; F82E1B  6e 03
	jrl T,INTT1_Return                                      ; F82E1D  78 7c 00
.LF82E20:
	jrl T,INTT1_Return                                      ; F82E20  78 79 00
INTT1_Phase2_Rota:
	ld_sd8b a, 0x87                               ; F82E23  c0 87 21
	and A,0x0f                                    ; F82E26  c9 cc 0f
	sll a, 0x02                                   ; F82E29  c9 ee 02
	ld XHL,INTT1_Rota_Table                             ; F82E2C  43 38 2e f8 00
	.byte 0xe3, 0x03, 0xec, 0xe0, 0x23            ; F82E31  e3 03 ec e0 23   ld XHL,(XHL+A) -- the table fetch; llvm-mc has no (R+R) form
	jp (xhl)                                      ; F82E36  b3 d8

; ---------------------------------------------------------------------
; INTT1_Rota_Table -- 16-entry dispatch table for the (0x88) bit rota
;
; Read by:  0xF82E2C (`ld XHL,INTT1_Rota_Table`), indexed by ((0x87) & 0x0F)*4.
; Layout:   16 x LE32 code pointer.  Only seven distinct targets appear; the
;           repetition is the schedule:
;             bit 0 and bit 1 of (0x88) are cleared at slots 0,4,8,12 / 1,5,9,13
;             bit 3 of (0x88) (with bit 6 of (0x98)) at slots 3,7,11,15
;             bits 4,5,6,7 of (0x88) once each, at slots 2,6,10,14
;           i.e. four fast bits and four slow ones, all off the same counter.
; Notes:    what the bits GATE is not established here -- only that the rota
;           clears them and nothing in this handler sets them, so they must be
;           set by whatever consumes them.
; ---------------------------------------------------------------------
INTT1_Rota_Table:
	.long INTT1_Rota_Clear_88_b0		; F82E38  78 2e f8 00
	.long INTT1_Rota_Clear_88_b1		; F82E3C  7d 2e f8 00
	.long INTT1_Rota_Clear_88_b4		; F82E40  8a 2e f8 00
	.long INTT1_Rota_Clear_98_b6_88_b3	; F82E44  82 2e f8 00
	.long INTT1_Rota_Clear_88_b0		; F82E48  78 2e f8 00
	.long INTT1_Rota_Clear_88_b1		; F82E4C  7d 2e f8 00
	.long INTT1_Rota_Clear_88_b5		; F82E50  8f 2e f8 00
	.long INTT1_Rota_Clear_98_b6_88_b3	; F82E54  82 2e f8 00
	.long INTT1_Rota_Clear_88_b0		; F82E58  78 2e f8 00
	.long INTT1_Rota_Clear_88_b1		; F82E5C  7d 2e f8 00
	.long INTT1_Rota_Clear_88_b6		; F82E60  94 2e f8 00
	.long INTT1_Rota_Clear_98_b6_88_b3	; F82E64  82 2e f8 00
	.long INTT1_Rota_Clear_88_b0		; F82E68  78 2e f8 00
	.long INTT1_Rota_Clear_88_b1		; F82E6C  7d 2e f8 00
	.long INTT1_Rota_Clear_88_b7		; F82E70  99 2e f8 00
	.long INTT1_Rota_Clear_98_b6_88_b3	; F82E74  82 2e f8 00


; ---------------------------------------------------------------------
; INTT1_Rota_Clear_* / INTT1_Return -- the rota's seven leaves and the exit
;
; Called from: INTT1_Rota_Table only.
; Inputs:  none
; Outputs: clears one bit of (0x88) -- and, on the 0x98 leaf, bit 6 of (0x98)
;          as well.
; Notes:   INTT1_Return pops the two registers the handler saved and jumps to
;          0xF42D68, a prom_b thunk holding `jp 0xF857B7` = IRQ_Epilogue, the
;          one place this firmware decides whether an interrupt return should
;          also reschedule.  See the kernel block at 0xF856EC.
; ---------------------------------------------------------------------
INTT1_Rota_Clear_88_b0:
	res_dd8 0x00, 0x88                            ; F82E78  f0 88 b0
	jr T,INTT1_Return                                 ; F82E7B  68 1f
INTT1_Rota_Clear_88_b1:
	res_dd8 0x01, 0x88                            ; F82E7D  f0 88 b1
	jr T,INTT1_Return                                 ; F82E80  68 1a
INTT1_Rota_Clear_98_b6_88_b3:
	res_dd8 0x06, 0x98                            ; F82E82  f0 98 b6
	res_dd8 0x03, 0x88                            ; F82E85  f0 88 b3
	jr T,INTT1_Return                                 ; F82E88  68 12
INTT1_Rota_Clear_88_b4:
	res_dd8 0x04, 0x88                            ; F82E8A  f0 88 b4
	jr T,INTT1_Return                                 ; F82E8D  68 0d
INTT1_Rota_Clear_88_b5:
	res_dd8 0x05, 0x88                            ; F82E8F  f0 88 b5
	jr T,INTT1_Return                                 ; F82E92  68 08
INTT1_Rota_Clear_88_b6:
	res_dd8 0x06, 0x88                            ; F82E94  f0 88 b6
	jr T,INTT1_Return                                 ; F82E97  68 03
INTT1_Rota_Clear_88_b7:
	res_dd8 0x07, 0x88                            ; F82E99  f0 88 b7
INTT1_Return:
	pop XHL                                       ; F82E9C  5b
	popw wa                                       ; F82E9D  48
	jp 0xf42d68                                   ; F82E9E  1b 68 2d f4

; ==============================================================================
; 0xF82EA2-0xF8306D -- INTTR4: the sequencer tick, and the event-buffer append
; ==============================================================================

; ---------------------------------------------------------------------
; INTTR4_SequencerTick -- 16-bit timer 4 interrupt: the musical time base
;
; Called from: vector slot 0x50 (0xFFFF50 holds 0x00F82EA2)
; Inputs:  the transport state bytes (0x94)/(0x95)/(0x96), each of which the
;          MIDI receive path and INTT1_Tick also write; TREG5, which the tempo
;          setter at 0xFAA373 and the MIDI-clock tracker at 0xFA553E both write.
; Outputs: three tick/beat/bar counters advanced, MIDI real-time bytes queued in
;          (0xA0), the countdown at (0xC2) decremented, and -- when transport B
;          wraps a beat and (0x3004) is non-zero -- a byte appended to the event
;          ring buffer.  WA, XHL and XIY are preserved; it exits through the
;          shared epilogue at 0xF42D68 rather than RETI.
;
; ★ 96 TICKS PER BEAT, and it is cross-checked twice:
;     * every one of the four counters here wraps at 0x60 = 96;
;     * the MIDI clock is emitted when (0x8D) mod 4 == 0 (0xF82FDF), and
;       96 / 4 = 24, which is exactly MIDI 1.0's 24 Timing Clocks per quarter
;       note.  Two unrelated constants agreeing on the same beat length.
;     * the runtime tempo setter computes TREG5 = 140,000,000 / (64 * BPM)
;       (notes/FINDINGS-system-clock.md); with timer 4 on phiT1 = fc/8 and
;       fc = 28 MHz that is 2,187,500 / BPM, i.e. 96 ticks per beat.  Third
;       agreement, from a completely different routine.
;
; THREE TRANSPORTS, NOT ONE.  (0x94), (0x95) and (0x96) are three copies of the
; same state byte, each with its own tick/beat pair:
;     (0x94)  ticks (0x8B), beats (0x8C), bars (0x605002), bar length (0x605000)
;     (0x95)  ticks (0x8D), beats (0x8E)          -- also the MIDI clock source
;     (0x96)  ticks (0x93), beats (0x91)          -- also drives the event buffer
; ⚠ WHICH THREE THINGS they are (song / pattern / metronome? recorder / player /
; external sync?) is NOT established.  What IS established is that all three obey
; the same bit layout: bit 2 = running, bit 3 and bit 0 appear as edge triggers,
; and the values written are 0x01, 0x06, 0x08, 0x10 and 0x86.
;
; (0xA6)/(0xA7) with (0xA8) bits 0 and 3 are a pair of SCHEDULED TICKS: when
; transport B's tick reaches one of them and the matching arm bit is set, (0x94)
; is forced to 0x01 or 0x08 and the arm bit is cleared.  That is a one-shot
; "change state at tick N" mechanism.
;
; (0x7F32) bit 2 replaces the whole handler with the one at 0xF83120 -- the two
; are alternates, not a fast path.  The same bit gates INTT1_Tick's transport
; section, so it is a mode selector for the machine as a whole.  Not identified.
; ---------------------------------------------------------------------
INTTR4_SequencerTick:
	pushw wa                                      ; F82EA2  28
	push XHL                                      ; F82EA3  3b
	push XIY                                      ; F82EA4  3d
	ld XIY,0x00600a14                             ; F82EA5  45 14 0a 60 00   XIY = the event ring buffer's body; its header is at XIY-4
	ld XHL,0x00000084                             ; F82EAA  43 84 00 00 00
	incm8 0x01, (xhl)                             ; F82EAF  83 61   (0x84) = the free-running 96-per-beat tick
	cp (XHL),0x60                                 ; F82EB1  83 3f 60   0x60 = 96
	jr c, .LF82EB9                                ; F82EB4  67 03
	ld (XHL),0x00                                 ; F82EB6  b3 00 00
.LF82EB9:
	m_bit 2, MD16, 0x7f32                         ; F82EB9  f1 32 7f ca   whatever (0x7F32) bit 2 selects, it swaps the whole handler out
	jr z, .LF82EC3                                ; F82EBD  66 04
	jp 0xf83120                                   ; F82EBF  1b 20 31 f8
.LF82EC3:
	bit_dd8 0x02, 0x95                            ; F82EC3  f0 95 ca   transport C running?
	jr z, .LF82EDA                                ; F82EC6  66 12
	ld_sd8b a, 0x8d                               ; F82EC8  c0 8d 21
	inc 1,A                                       ; F82ECB  c9 61   (0x8D) = its tick, 0..95
	cp A,0x60                                     ; F82ECD  c9 cf 60
	jr lt, .LF82ED7                               ; F82ED0  61 05
	xor A,A                                       ; F82ED2  c9 d1
	m_inc 1, MW8, 0x8e                            ; F82ED4  d0 8e 61   (0x8E) = its beat, 16-bit
.LF82ED7:
	st_dd8b a, 0x8d                               ; F82ED7  f0 8d 41
.LF82EDA:
	bit_dd8 0x02, 0x94                            ; F82EDA  f0 94 ca   transport A running?
	jr z, .LF82F05                                ; F82EDD  66 26
	m_inc 1, MB8, 0x8b                            ; F82EDF  c0 8b 61   (0x8B) = its tick, 0..95
	m_cp_mi8 MB8, 0x8b, 0x60                      ; F82EE2  c0 8b 3f 60
	jr c, .LF82F05                                ; F82EE6  67 1d
	ldio 0x8b, 0x00                               ; F82EE8  08 8b 00
	m_inc 1, MB8, 0x8c                            ; F82EEB  c0 8c 61   (0x8C) = its beat
	ld_sd8b a, 0x8c                               ; F82EEE  c0 8c 21
	ldb_da w, (0x605000)                          ; F82EF1  c2 00 50 60 20   (0x605000) = beats per bar
	m_ex_mr MB8, 0xc3, r0                         ; F82EF6  c0 c3 30
	cp A,W                                        ; F82EF9  c8 f1
	jr c, .LF82F05                                ; F82EFB  67 08
	ldio 0x8c, 0x00                               ; F82EFD  08 8c 00
	incdi8_24 0x01, (0x605002)                    ; F82F00  c2 02 50 60 61   (0x605002) = the bar counter, 16-bit
.LF82F05:
	bit_dd8 0x02, 0x96                            ; F82F05  f0 96 ca   transport B running?
	jr z, .LF82F24                                ; F82F08  66 1a
	m_inc 1, MB8, 0x93                            ; F82F0A  c0 93 61   (0x93) = its tick
	m_cp_mi8 MB8, 0x93, 0x60                      ; F82F0D  c0 93 3f 60
	jr lt, .LF82F24                               ; F82F11  61 11
	ldio 0x93, 0x00                               ; F82F13  08 93 00
	m_inc 1, MW8, 0x91                            ; F82F16  d0 91 61
	xor XHL,XHL                                   ; F82F19  eb d3
	cpdm32 (0x3004), xhl                          ; F82F1B  e1 04 30 fb
	jr z, .LF82F24                                ; F82F1F  66 03
	calr SeqBuf_AppendMarker                                 ; F82F21  1e 10 01
.LF82F24:
	bit_dd8 0x02, 0x95                            ; F82F24  f0 95 ca
	jr z, .LF82F3B                                ; F82F27  66 12
	bit_dd8 0x00, 0x94                            ; F82F29  f0 94 c8
	jr z, .LF82F31                                ; F82F2C  66 03
	ldio 0x94, 0x06                               ; F82F2E  08 94 06
.LF82F31:
	bit_dd8 0x00, 0x96                            ; F82F31  f0 96 c8
	jr z, .LF82F39                                ; F82F34  66 03
	ldio 0x96, 0x06                               ; F82F36  08 96 06
.LF82F39:
	jr .LF82F8B                                   ; F82F39  68 50
.LF82F3B:
	bit_dd8 0x07, 0x94                            ; F82F3B  f0 94 cf
	jr z, .LF82F8B                                ; F82F3E  66 4b
	bit_dd8 0x02, 0x94                            ; F82F40  f0 94 ca
	jr z, .LF82F88                                ; F82F43  66 43
	m_cp_mi8 MB8, 0x8b, 0x5f                      ; F82F45  c0 8b 3f 5f
	jr c, .LF82F86                                ; F82F49  67 3b
	m_cp_mi8 MB24, 0x605002, 0x01                 ; F82F4B  c2 02 50 60 3f 01
	jr c, .LF82F86                                ; F82F51  67 33
	ldb_da a, (0x605000)                          ; F82F53  c2 00 50 60 21
	dec 1,A                                       ; F82F58  c9 69
	m_cp_mr MB8, 0x8c, r1                         ; F82F5A  c0 8c f9
	jr c, .LF82F86                                ; F82F5D  67 27
	ldb a, 0x01                                   ; F82F5F  21 01
	st_dd8b a, 0x95                               ; F82F61  f0 95 41
	st_dd8b a, 0x96                               ; F82F64  f0 96 41
	m_cp_mi8 MB16, 0x2078, 0x0d                   ; F82F67  c1 78 20 3f 0d
	jr z, .LF82F86                                ; F82F6C  66 18
	m_bit 2, MD16, 0x7f34                         ; F82F6E  f1 34 7f ca
	jr z, .LF82F86                                ; F82F72  66 12
	m_bit 2, MD16, 0x7f32                         ; F82F74  f1 32 7f ca
	jr nz, .LF82F86                               ; F82F78  6e 0c
	push SR                                       ; F82F7A  02
	ei 0x06                                       ; F82F7B  06 06
	m_or_mi8 MB8, 0xa0, 0x02                      ; F82F7D  c0 a0 3e 02
	call 0xf40724                                 ; F82F81  1d 24 07 f4
	pop SR                                        ; F82F85  03
.LF82F86:
	jr .LF82F8B                                   ; F82F86  68 03
.LF82F88:
	ldio 0x94, 0x86                               ; F82F88  08 94 86
.LF82F8B:
	bit_dd8 0x03, 0x95                            ; F82F8B  f0 95 cb
	jr z, .LF82FCA                                ; F82F8E  66 3a
	ld_sd8b a, 0x8d                               ; F82F90  c0 8d 21
	cps a, 0x00                                   ; F82F93  c9 d8
	jr z, .LF82FA8                                ; F82F95  66 11
	cp A,0x18                                     ; F82F97  c9 cf 18
	jr z, .LF82FA8                                ; F82F9A  66 0c
	cp A,0x30                                     ; F82F9C  c9 cf 30
	jr z, .LF82FA8                                ; F82F9F  66 07
	cp A,0x48                                     ; F82FA1  c9 cf 48
	jr z, .LF82FA8                                ; F82FA4  66 02
	jr .LF82FDA                                   ; F82FA6  68 32
.LF82FA8:
	ldio 0x95, 0x10                               ; F82FA8  08 95 10
	m_cp_mi8 MB16, 0x2078, 0x0d                   ; F82FAB  c1 78 20 3f 0d
	jr z, .LF82FCA                                ; F82FB0  66 18
	m_bit 2, MD16, 0x7f34                         ; F82FB2  f1 34 7f ca
	jr z, .LF82FCA                                ; F82FB6  66 12
	m_bit 2, MD16, 0x7f32                         ; F82FB8  f1 32 7f ca
	jr nz, .LF82FCA                               ; F82FBC  6e 0c
	push SR                                       ; F82FBE  02
	ei 0x06                                       ; F82FBF  06 06
	m_or_mi8 MB8, 0xa0, 0x08                      ; F82FC1  c0 a0 3e 08   queue 0xFC STOP
	call 0xf40724                                 ; F82FC5  1d 24 07 f4
	pop SR                                        ; F82FC9  03
.LF82FCA:
	bit_dd8 0x03, 0x94                            ; F82FCA  f0 94 cb
	jr z, .LF82FD2                                ; F82FCD  66 03
	ldio 0x94, 0x10                               ; F82FCF  08 94 10
.LF82FD2:
	bit_dd8 0x03, 0x96                            ; F82FD2  f0 96 cb
	jr z, .LF82FDA                                ; F82FD5  66 03
	ldio 0x96, 0x10                               ; F82FD7  08 96 10
.LF82FDA:
	bit_dd8 0x02, 0x95                            ; F82FDA  f0 95 ca
	jr z, .LF82FFA                                ; F82FDD  66 1b
	ld_sd8b a, 0x8d                               ; F82FDF  c0 8d 21   (0x8D) mod 4 -- 96 ticks/beat / 4 = 24, the MIDI clock rate
	and A,0x03                                    ; F82FE2  c9 cc 03
	jr nz, .LF82FFA                               ; F82FE5  6e 13
	m_cp_mi8 MB16, 0x2078, 0x0d                   ; F82FE7  c1 78 20 3f 0d
	jr z, .LF82FFA                                ; F82FEC  66 0c
	push SR                                       ; F82FEE  02
	ei 0x06                                       ; F82FEF  06 06
	m_or_mi8 MB8, 0xa0, 0x01                      ; F82FF1  c0 a0 3e 01   queue 0xF8 TIMING CLOCK
	call 0xf40724                                 ; F82FF5  1d 24 07 f4
	pop SR                                        ; F82FF9  03
.LF82FFA:
	bit_dd8 0x02, 0x96                            ; F82FFA  f0 96 ca
	jr z, .LF83024                                ; F82FFD  66 25
	ld_sd8b a, 0x93                               ; F82FFF  c0 93 21
	bit_dd8 0x03, 0xa8                            ; F83002  f0 a8 cb
	jr z, .LF83013                                ; F83005  66 0c
	m_cp_mr MB8, 0xa7, r1                         ; F83007  c0 a7 f9   a scheduled tick for transport A, armed by (0xA8) bit 3
	jr nz, .LF83013                               ; F8300A  6e 07
	ldio 0x94, 0x08                               ; F8300C  08 94 08
	m_and_mi8 MB8, 0xa8, 0xf7                     ; F8300F  c0 a8 3c f7
.LF83013:
	bit_dd8 0x00, 0xa8                            ; F83013  f0 a8 c8
	jr z, .LF83024                                ; F83016  66 0c
	m_cp_mr MB8, 0xa6, r1                         ; F83018  c0 a6 f9   a scheduled tick for transport A, armed by (0xA8) bit 0
	jr nz, .LF83024                               ; F8301B  6e 07
	ldio 0x94, 0x01                               ; F8301D  08 94 01
	m_and_mi8 MB8, 0xa8, 0xfe                     ; F83020  c0 a8 3c fe
.LF83024:
	m_cp_mi8 MB8, 0xc2, 0x00                      ; F83024  c0 c2 3f 00   (0xC2) is a plain countdown, decremented once per tick
	jr z, INTTR4_Return                                ; F83028  66 03
	m_dec 1, MB8, 0xc2                            ; F8302A  c0 c2 69
INTTR4_Return:
	pop XIY                                       ; F8302D  5d
	pop XHL                                       ; F8302E  5b
	popw wa                                       ; F8302F  48
	jp 0xf42d68                                   ; F83030  1b 68 2d f4

; ---------------------------------------------------------------------
; SeqBuf_AppendMarker -- push one 0x81 byte into the event ring buffer
;
; Called from: INTTR4_SequencerTick (0xF82F21), on a transport-B beat wrap when
;          (0x3004) is non-zero.  0xFA56CB is a second, byte-for-byte identical
;          copy of this routine that uses XIX instead of XIY.
; Inputs:  XIY = 0x600A14, the buffer body.  The header sits just below it:
;              (XIY-4) = (0x600A10)  the 16-bit write index
;              (XIY-2) = (0x600A12)  the 16-bit REMAINING SPACE
; Outputs: one byte 0x81 stored, the index advanced modulo 0x200 and the
;          remaining-space count decremented.  When the count is already zero
;          nothing is written -- the buffer drops, it does not wrap over live
;          data.  (0xAC) is reset to 0.
; Notes:   `minc1_16 hl, 0x01ff` is the modular increment, and it is what fixes
;          the ring at 512 bytes.
;
;          ⚠ THE SECOND PATH IS A DIFFERENT BUFFER.  If bit 0 of (0xAA) is set,
;          the byte goes to (0x00AE + (0xAC)) instead -- a plain linear array in
;          static RAM indexed by a counter that never wraps, and the ring is left
;          untouched.  A capture/trace mode is the obvious reading, and it is
;          only a reading: nothing here says what consumes either buffer.
;
;          The value stored is the constant 0x81.  What that marker means is NOT
;          established; the neighbouring routine at 0xF830C6 appends a caller-
;          supplied byte followed by the current tick (0x93), so this buffer
;          holds tagged, time-stamped events of some kind.
; ---------------------------------------------------------------------
SeqBuf_AppendMarker:
	bit_dd8 0x00, 0xaa                            ; F83034  f0 aa c8
	jr nz, SeqBuf_AppendMarker__trace                               ; F83037  6e 24
	pushw wa                                      ; F83039  28
	ld wa, (xiy-2)                                ; F8303A  9d fe 20
	and WA,WA                                     ; F8303D  d8 c0
	jr z, SeqBuf_AppendMarker__full                                ; F8303F  66 15
	ld hl, (xiy-4)                                ; F83041  9d fc 23
	.byte 0xf3, 0x07, 0xf4, 0xec, 0x00, 0x81      ; F83044  f3 07 f4 ec 00 81   ld (XIY+HL),0x81 -- llvm-mc has no spelling for the (R+R) form
	minc1_16 hl, 0x01ff                           ; F8304A  db 38 ff 01   wrap HL modulo 0x200: the ring is 512 bytes
	dec 1,WA                                      ; F8304E  d8 69
	ld (xiy-4), hl                                ; F83050  bd fc 53
	ld (xiy-2), wa                                ; F83053  bd fe 50
SeqBuf_AppendMarker__full:
	popw wa                                       ; F83056  48
	ldwio 0xac, 0x00                              ; F83057  0a ac 00 00
	jr SeqBuf_AppendMarker__done                                   ; F8305B  68 10
SeqBuf_AppendMarker__trace:
	m_ld_rm MW8, 0xac, r3                         ; F8305D  d0 ac 23
	extz XHL                                      ; F83060  eb 12
	ld (XHL+0x00ae),0x81                          ; F83062  f3 ed ae 00 00 81
	inc 1,HL                                      ; F83068  db 61
	st_dd8w hl, 0xac                              ; F8306A  f0 ac 53
SeqBuf_AppendMarker__done:
	ret                                           ; F8306D  0e

; ==============================================================================
; 0xF8306E-0xF830C5 -- NMI: the power-fail handler, and its checksum helper
; ==============================================================================

; ---------------------------------------------------------------------
; NMI_PowerFail_SaveAndHalt -- last rites when the supply starts to fall
;
; Called from: vector slot 0x20 (0xFFFF20 holds 0x00F8306E).  0x20 is the one
;          slot MAME does name for this part -- NMI, tmp95c061.cpp:505.
; Inputs:  bit 1 of (0x97) -- when clear, the save is skipped entirely and the
;          machine goes straight to the halt below.
; Outputs: two checksums written to (0x7FD2) and (0x7FD4); (0x7FC7) and
;          (0x7FCA) zeroed; DMEMCR rewritten; P6 bit 5 and P7 bits 4-5 driven;
;          the CPU halted.  It never returns.
; Notes:   the shape of this routine is what identifies it, not a string:
;            * it drives two port pins, then makes a service call and two
;              cross-ROM calls -- the orderly-shutdown notifications;
;            * it check-sums two blocks and stores the results;
;            * it rewrites DMEMCR (0x5B) from the 0x8D that RESET programmed to
;              0x2D and sets bit 5 of P6, then HALTs in a loop that re-halts
;              if anything wakes it.  P6 is the port carrying RAS/REFOUT
;              (tmp95c061.h:19), so this is putting the work DRAM into a
;              self-sustaining refresh and stopping the core.  The exact DMEMCR
;              field that changes is NOT established -- MAME stores the register
;              and decodes nothing (tmp95c061.cpp:1353).
;
;          THE TWO CHECKSUMMED BLOCKS, and why they matter:
;            0x007620 for 512 bytes -> checksum word at 0x007FD2
;            0x617800 for 512 bytes -> checksum word at 0x007FD4
;          The first is CS1 static RAM, the second is work DRAM inside the
;          0x617800 record array that the memory-map note already records.  A
;          checksum taken at power-down over exactly these two blocks is how a
;          machine decides at the next power-up whether its retained settings
;          survived; the KN5000 does the same thing with its own power-fail
;          area (see the sibling project's notes).  ⚠ That is the SHAPE of the
;          mechanism.  This routine only writes the checksums -- the code that
;          verifies them at boot has not been traced yet, so "battery-backed"
;          is NOT established here.
;
;          `swi 7` with A = 0x0C, C = 0 is a service call: the SWI7 vector
;          reaches SWI7_ServiceCall_Dispatch (0xF8E9A5, converted below), which
;          indexes SWI7_ServiceTable with A & 0x3F.  Slot 0x0C is 0xF8F7B8.
;          0xF4030C and 0xF40A28 are prom_b thunks, holding `jp 0xFE8005` and
;          `jp 0xF45D09`.
; ---------------------------------------------------------------------
NMI_PowerFail_SaveAndHalt:
	set_dd8 0x05, 0x13                            ; F8306E  f0 13 bd
	set_dd8 0x04, 0x13                            ; F83071  f0 13 bc
	xor C,C                                       ; F83074  cb d3
	ldb a, 0x0c                                   ; F83076  21 0c
	swi 7                                         ; F83078  ff
	bit_dd8 0x01, 0x97                            ; F83079  f0 97 c9
	jr z, NMI_PowerFail__stop                                ; F8307C  66 22
	call 0xf4030c                                 ; F8307E  1d 0c 03 f4
	call 0xf40a28                                 ; F83082  1d 28 0a f4
	ld XIY,0x00007620                             ; F83086  45 20 76 00 00
	ld XIX,0x00007fd2                             ; F8308B  44 d2 7f 00 00
	calr PowerFail_Checksum512                                 ; F83090  1e 23 00
	ld XIY,0x00617800                             ; F83093  45 00 78 61 00
	ld XIX,0x00007fd4                             ; F83098  44 d4 7f 00 00
	calr PowerFail_Checksum512                                 ; F8309D  1e 16 00
NMI_PowerFail__stop:
	xor WA,WA                                     ; F830A0  d8 d0
	stb_d8 (0x7fc7), a                            ; F830A2  f1 c7 7f 41
	stda16 (0x7fca), wa                           ; F830A6  f1 ca 7f 50
	ei 0x07                                       ; F830AA  06 07
	ldio 0x5b, 0x2d                               ; F830AC  08 5b 2d
	nop                                           ; F830AF  00
	set_dd8 0x05, 0x12                            ; F830B0  f0 12 bd
NMI_PowerFail__halt:
	halt                                          ; F830B3  05
	jr NMI_PowerFail__halt                                   ; F830B4  68 fd

; ---------------------------------------------------------------------
; PowerFail_Checksum512 -- 16-bit ones-complement sum of 512 bytes
;
; NAME NOTE: called NVRAM_Checksum512 until 2026-08-24. Renamed because the header
; below states the boot-time verification has NOT been traced, so "NVRAM" asserted
; non-volatility this tree has not established. Labels get grepped and propagate;
; headers do not. This project has already had to retract a persisted-RAM claim once.
;
; Called from: NMI_PowerFail_SaveAndHalt, twice (0xF83090, 0xF8309D)
; Inputs:  XIY = first byte of the block; XIX = where to put the result
; Outputs: (XIX) = NOT (sum of the 256 little-endian words at XIY).  XIY is left
;          past the end of the block; WA and BC are clobbered.
; Notes:   `add_spiw wa, 0xf5` is `add WA,(XIY+)` -- 0xF5 is the register-address
;          byte for XIY with a post-increment of 2 (the same encoding the RESET
;          block documents as MEM_XIX_PI4 for XIX/+4; see
;          include/tmp95c061_sfr.inc).  256 words x 2 = 512 bytes.
; ---------------------------------------------------------------------
PowerFail_Checksum512:
	ldw bc, 0x0100                                ; F830B6  31 00 01
	xor WA,WA                                     ; F830B9  d8 d0
PowerFail_Checksum512__loop:
	add_spiw wa, 0xf5                             ; F830BB  d5 f5 80
	djnz16 bc, PowerFail_Checksum512__loop                           ; F830BE  d9 1c fa
	cpl WA                                        ; F830C1  d8 06
	ld (XIX),WA                                   ; F830C3  b4 50
	ret                                           ; F830C5  0e
	.incbin "original_ROMs/wsa1_prom_a.ic12", 0x0030C6, 0x002626

; ==============================================================================
; 0xF856EC-0xF857D5 -- the kernel: idle loop, task switch, software timers, and
;                      the interrupt epilogue every handler exits through
; ==============================================================================
;
; ★ prom_a CONTAINS A SMALL MULTITASKING KERNEL.  That is the structural finding
;   here, and it is read off the data structures, not assumed:
;
;     0x0330  three TASK CONTROL BLOCKS, 8 bytes each.  +0 is a ready word --
;             Kernel_Dispatch__scan walks the three and takes the first whose +0
;             is NOT equal to its own address, so a self-referential TCB means
;             "not ready".  +4 is the task's saved XSP.
;     0x03C8  two SOFTWARE TIMER slots, 8 bytes each.  +0 countdown, +2 reload,
;             +4 callback address, with 0xFFFFFFFF meaning "empty".
;     (0xBE)  pending kernel ticks, produced elsewhere and drained here
;     (0xBF)  the task currently running, 0 = "we are on the kernel's own stack"
;     cr 0x3C the critical-section DEPTH.  Incremented on entry to the timer
;             service and decremented on exit; the epilogue below runs the kernel
;             only when it reads exactly 1, and SWI7_ServiceCall_Dispatch writes 0
;             to it so a service call never triggers a switch.
;
;   ⚠ Control register 0x3C is left as a number.  unidasm prints control-register
;   numbers as "unknown", MAME does not name them, and no databook is in these
;   trees.  What it DOES here is established by the code; what Toshiba calls it
;   is not established by anything available.
;
;   ⚠ Kernel_Idle is an interrupts-enabled spin, not a HALT.  Reached when no
;   task is ready.
;
; The stack layout the two halves agree on is the identification: the epilogue
; pushes XHL, XWA, XBC, XDE, XIX, XIY, XIZ and falls into the dispatcher;
; Kernel_ResumeTask pops XIZ, XIY, XIX, XDE, XBC, XWA, XHL, then SR, then RETs.
; Same seven registers in the opposite order, plus the SR and PC the interrupt
; itself pushed -- so "resume a task" and "return from an interrupt" are the same
; frame, which is what makes the switch work at all.
;
; ---------------------------------------------------------------------
; Kernel_Start -- programme timer 3, arm two software timers, enter the kernel
;
; Called from: falls in from 0xF856E9's `jrl 0xF84F49` neighbourhood -- the boot
;          path; not yet traced precisely.
; Inputs:  none
; Outputs: timer 3 stopped and re-programmed (T23MOD = 0x0E, TREG3 = 0x36,
;          INTET32 = 0x20), two callbacks registered through 0xF857D9, the depth
;          counter cleared, and control passed to Kernel_Dispatch.  Never returns.
; Notes:   0xF857D9 takes a slot number in A; it is the "register a software
;          timer" entry and is just past the end of this region.
; ---------------------------------------------------------------------
Kernel_Start:
	res_dd8 0x03, 0x20                            ; F856EC  f0 20 b3   TRUN bit 3 = timer 3 off
	ldio 0x28, 0x0e                               ; F856EF  08 28 0e   T23MOD
	ldio 0x27, 0x36                               ; F856F2  08 27 36   TREG3
	ldio 0x74, 0x20                               ; F856F5  08 74 20   INTET32
	ldb a, 0x01                                   ; F856F8  21 01
	call 0xf857d9                                 ; F856FA  1d d9 57 f8
	ldb a, 0x03                                   ; F856FE  21 03
	call 0xf857d9                                 ; F85700  1d d9 57 f8
	ei 0x06                                       ; F85704  06 06
	ldio 0xbe, 0x00                               ; F85706  08 be 00
	xor WA,WA                                     ; F85709  d8 d0
	m_ldc_cr_reg RW+r0, 0x3c                      ; F8570B  d8 2e 3c   the depth counter starts at 0
	jrl Kernel_Dispatch                                  ; F8570E  78 04 00
Kernel_Idle:
	ei 0x00                                       ; F85711  06 00
Kernel_Idle__loop:
	jr Kernel_Idle__loop                                   ; F85713  68 fe

; ---------------------------------------------------------------------
; Kernel_Dispatch -- drain the tick queue, then pick a task and resume it
;
; Called from: Kernel_Start, and from IRQ_Epilogue (0xF857D3) on every interrupt
;          that was not nested
; Inputs:  cr 0x3C (must be 0 to proceed), (0xBE), (0xBF), the TCBs at 0x0330
; Outputs: control transferred into a task, or into Kernel_Idle when none is
;          ready.  Does not return to its caller.
; Notes:   if the current task's XSP is still live it is saved into that task's
;          TCB first and the kernel switches to the boot stack 0x0060EB80 -- the
;          same address RESET's continuation sets, which is the second sign that
;          this is the top of the system rather than a subroutine.
; ---------------------------------------------------------------------
Kernel_Dispatch:
	m_ldc_reg_cr RW+r0, 0x3c                      ; F85715  d8 2f 3c   outermost only: a non-zero depth means resume, not dispatch
	or WA,WA                                      ; F85718  d8 e0
	jr nz, Kernel_ResumeTask                               ; F8571A  6e 47
	xor WA,WA                                     ; F8571C  d8 d0
	m_cp_mr MW8, 0xbf, r0                         ; F8571E  d0 bf f8   (0xBF) = the task whose stack we are on, 0 = none
	jr z, Kernel_Dispatch__drain_ticks                                ; F85721  66 12
	m_ld_rm MW8, 0xbf, r5                         ; F85723  d0 bf 25
	extz XIY                                      ; F85726  ed 12
	ld (XIY+0x04),XSP                             ; F85728  bd 04 67   save its XSP into the TCB
	ld XSP,0x0060eb80                             ; F8572B  47 80 eb 60 00   and run the kernel on the boot stack
	xor WA,WA                                     ; F85730  d8 d0
	st_dd8w wa, 0xbf                              ; F85732  f0 bf 50
Kernel_Dispatch__drain_ticks:
	ld_sd8b a, 0xbe                               ; F85735  c0 be 21   (0xBE) = pending timer ticks
	or A,A                                        ; F85738  c9 e1
	jr z, Kernel_Dispatch__pick_task                                ; F8573A  66 0a
	dec 1,A                                       ; F8573C  c9 69
	st_dd8b a, 0xbe                               ; F8573E  f0 be 41
	calr Kernel_ServiceSoftTimers                                 ; F85741  1e 28 00
	jr Kernel_Dispatch__drain_ticks                                   ; F85744  68 ef
Kernel_Dispatch__pick_task:
	ldb b, 0x03                                   ; F85746  22 03
	ldw ix, 0x0330                                ; F85748  34 30 03   the task control blocks: 3 x 8 bytes at 0x0330
	extz XIX                                      ; F8574B  ec 12
Kernel_Dispatch__scan:
	m_ld_rm MWD+r4, 0x00, r3                      ; F8574D  9c 00 23   TCB+0 = the ready flag; a TCB is ready when it is not self-referential
	cp HL,IX                                      ; F85750  dc f3
	jr nz, Kernel_Dispatch__switch_to                               ; F85752  6e 07
	inc 4,IX                                      ; F85754  dc 64
	djnz8 b, Kernel_Dispatch__scan                             ; F85756  ca 1c f4
	jr Kernel_Idle                                   ; F85759  68 b6
Kernel_Dispatch__switch_to:
	st_dd8w hl, 0xbf                              ; F8575B  f0 bf 53
	extz XHL                                      ; F8575E  eb 12
	ld XSP,(XHL+0x04)                             ; F85760  ab 04 27   TCB+4 = the saved XSP
Kernel_ResumeTask:
	pop XIZ                                       ; F85763  5e   restore the task's registers and return into it
	pop XIY                                       ; F85764  5d
	pop XIX                                       ; F85765  5c
	pop XDE                                       ; F85766  5a
	pop XBC                                       ; F85767  59
	pop XWA                                       ; F85768  58
	pop XHL                                       ; F85769  5b
	pop SR                                        ; F8576A  03
	ret                                           ; F8576B  0e

; ---------------------------------------------------------------------
; Kernel_ServiceSoftTimers -- one tick of the two software timers
;
; Called from: Kernel_Dispatch__drain_ticks, once per pending tick in (0xBE)
; Inputs:  the two slots at 0x03C8
; Outputs: each live slot's countdown decremented; on reaching zero the slot is
;          reloaded from +2 and its callback at +4 is entered.
; Notes:   the callback is entered by pushing the loop's own continuation
;          (0xF85794) and jumping -- so a callback returns straight back into the
;          scan, and the kernel never has to know how long it took.
;          It brackets the whole thing with depth++/depth-- on cr 0x3C, which is
;          what stops a timer callback from re-entering the dispatcher.
; ---------------------------------------------------------------------
Kernel_ServiceSoftTimers:
	m_ldc_reg_cr RW+r0, 0x3c                      ; F8576C  d8 2f 3c   enter a critical section: depth++
	inc 1,WA                                      ; F8576F  d8 61
	m_ldc_cr_reg RW+r0, 0x3c                      ; F85771  d8 2e 3c
	ei 0x00                                       ; F85774  06 00
	ldw ix, 0x03c8                                ; F85776  34 c8 03   the software timers: 2 x 8 bytes at 0x03C8
	extz XIX                                      ; F85779  ec 12
	ldb b, 0x02                                   ; F8577B  22 02
Kernel_ServiceSoftTimers__next:
	ld XWA,(XIX+0x04)                             ; F8577D  ac 04 20
	cp XWA,0xffffffff                             ; F85780  e8 cf ff ff ff ff   +4 = the callback, 0xFFFFFFFF = the slot is empty
	jr z, Kernel_ServiceSoftTimers__step                                ; F85786  66 0c
	m_ld_rm MWD+r4, 0x00, r0                      ; F85788  9c 00 20
	dec 1,WA                                      ; F8578B  d8 69   +0 = the countdown
	m_st_mr16 MDD+r4, 0x00, r0                    ; F8578D  bc 00 50
	or WA,WA                                      ; F85790  d8 e0
	jr z, Kernel_ServiceSoftTimers__fire                                ; F85792  66 12
Kernel_ServiceSoftTimers__step:
	add IX,0x0008                                 ; F85794  dc c8 08 00
	djnz8 b, Kernel_ServiceSoftTimers__next                             ; F85798  ca 1c e2
	ei 0x06                                       ; F8579B  06 06
	m_ldc_reg_cr RW+r0, 0x3c                      ; F8579D  d8 2f 3c
	dec 1,WA                                      ; F857A0  d8 69
	m_ldc_cr_reg RW+r0, 0x3c                      ; F857A2  d8 2e 3c
	ret                                           ; F857A5  0e
Kernel_ServiceSoftTimers__fire:
	ld WA,(XIX+0x02)                              ; F857A6  9c 02 20   +2 = the reload value
	m_st_mr16 MDD+r4, 0x00, r0                    ; F857A9  bc 00 50
	ld XWA,0x00f85794                             ; F857AC  40 94 57 f8 00   push the loop's continuation, then jump to the callback
	push XWA                                      ; F857B1  38
	ld XWA,(XIX+0x04)                             ; F857B2  ac 04 20
	jp (xwa)                                      ; F857B5  b0 d8

; ---------------------------------------------------------------------
; IRQ_Epilogue -- where every interrupt handler in this firmware exits
;
; Called from: reached as `jp 0xF42D68`, a prom_b thunk holding `jp 0xF857B7`.
;          INTT1_Tick and INTTR4_SequencerTick both end that way, and so does
;          the INTT3 handler at 0xF85600.
; Inputs:  cr 0x3C, the critical-section depth
; Outputs: either a plain RETI (nested case) or a full register push followed by
;          a jump into Kernel_Dispatch, which will not come back.
; Notes:   this is the whole reason interrupt handlers here `jp` to a thunk
;          instead of executing RETI themselves: the decision about whether to
;          reschedule is taken in one place.
; ---------------------------------------------------------------------
IRQ_Epilogue:
	pushw wa                                      ; F857B7  28   THE SHARED INTERRUPT EPILOGUE
	m_ldc_reg_cr RW+r0, 0x3c                      ; F857B8  d8 2f 3c
	cps wa, 0x01                                  ; F857BB  d8 d9   depth == 1 means this interrupt was the outermost one
	jr z, IRQ_Epilogue__enter_kernel                                ; F857BD  66 02
	popw wa                                       ; F857BF  48
	reti                                          ; F857C0  07   nested: plain RETI, do not run the kernel
IRQ_Epilogue__enter_kernel:
	xor WA,WA                                     ; F857C1  d8 d0
	m_ldc_cr_reg RW+r0, 0x3c                      ; F857C3  d8 2e 3c
	popw wa                                       ; F857C6  48
	ei 0x00                                       ; F857C7  06 00
	nop                                           ; F857C9  00
	ei 0x06                                       ; F857CA  06 06
	push XHL                                      ; F857CC  3b
	push XWA                                      ; F857CD  38
	push XBC                                      ; F857CE  39
	push XDE                                      ; F857CF  3a
	push XIX                                      ; F857D0  3c
	push XIY                                      ; F857D1  3d
	push XIZ                                      ; F857D2  3e
	jrl Kernel_Dispatch                                  ; F857D3  78 3f ff   into the kernel, on the interrupted task's stack
	.incbin "original_ROMs/wsa1_prom_a.ic12", 0x0057D6, 0x000783

; ==============================================================================
; 0xF85F59-0xF85FF8 -- the DSP / tone-generator register file at 0x7F0000
; ==============================================================================
;
; ★ WHAT 0x7F0000 IS.  notes/FINDINGS-memory-map.md already lists
;   "0x7F0000/0x7F0002 address/data register pair, slot (n<<5)|0x10" as a shape
;   without saying what it drives.  These three routines say: it is the DSP /
;   tone-generator register file, and the WSA1 talks to it with the SAME CODE
;   the KN5000 sub-CPU uses for its own tone generator.
;
;   The transplant is byte-backed.  prom_a 0xF85F73-0xF85FB6 is a 68-byte run
;   identical to the KN5000 sub-CPU payload at 0x1FCF2, where the sibling names
;   it DSP_WriteAllChannelRegs / DSP_WriteChannelRegs_Inner and documents it as
;   "write register data to all 4 DSP channels ... each call writes 8 sequential
;   DSP registers"
;   (../kn5000-roms-disasm/v142/subcpu/kn5000_subprogram_v142.s:456-462).
;   ⚠ Use the CORRECTED payload mapping when checking that address --
;   notes/FINDINGS-kn5000-transplant-offset.md.  The same run also appears in
;   WSA1 prom_c at 0xF9806D, so both WSA1 processors carry it.
;
;   ★ THE ONE THING THAT DIFFERS IS THE BASE ADDRESS, and the run ends ON that
;   byte: the shared bytes stop at 0xF85FB6, and 0xF85FB7 is 0x7F here against
;   0x13 in the KN5000 -- `ld XIY,0x007F0000` versus `ld XIY,0x00130000`, the
;   third byte of the same instruction.  So the routine is shared source
;   recompiled for a different bus, not a copied binary, and the register LAYOUT
;   (index = (channel << 5) | 0x10, then eight consecutive indices) is common to
;   both machines.  A 68-byte match that terminates exactly at the one operand
;   the two machines must disagree about is a much stronger identification than
;   its length alone suggests.
;
; THE PORT PAIR:
;   0x7F0000  write = the register index
;   0x7F0002  write = that register's value
;   The index is bumped with `inc 1,A` and re-written before every value, so the
;   file does NOT auto-increment.

; ---------------------------------------------------------------------
; DSP_WriteChannelRegs_FromTable -- write 8 bytes into one channel's registers
;
; Called from: 0xF85F30 and 0xF85F37 (a caller that pushes a channel number and
;          a pointer; not yet converted)
; Inputs:  on the stack -- (XSP+4) = channel number, (XSP+6) = pointer to 8 bytes
; Outputs: registers (channel<<5)|0x10 .. +7 written from that array.  A, XBC,
;          XIY advanced; DE preserved.
; Notes:   `ldb_spi e, 0xf4` is `ld E,(XIY+)`; 0xF4 is the register-address byte
;          for XIY with a post-increment of 1 (same convention as MEM_XIX_PI4 in
;          include/tmp95c061_sfr.inc).
; ---------------------------------------------------------------------
DSP_WriteChannelRegs_FromTable:
	ld A,(XSP+0x04)                               ; F85F59  8f 04 21   argument 1: the channel number
	ld XIY,(XSP+0x06)                             ; F85F5C  af 06 25   argument 2: a pointer to 8 bytes
	pushw de                                      ; F85F5F  2a
	sll a, 0x05                                   ; F85F60  c9 ee 05   channel << 5
	set 0x04,A                                    ; F85F63  c9 31 04   | 0x10 -> the register index for this channel's first slot
	ld XBC,0x007f0000                             ; F85F66  41 00 00 7f 00   the DSP register file
	ldb d, 0x08                                   ; F85F6B  24 08
DSP_WriteChannelRegs_FromTable__loop:
	ld (XBC),A                                    ; F85F6D  b1 41   select the register
	ldb_spi e, 0xf4                               ; F85F6F  c5 f4 25   ld E,(XIY+)
	ld (XBC+0x02),E                               ; F85F72  b9 02 45   write its value
	inc 1,A                                       ; F85F75  c9 61
	djnz8 d, DSP_WriteChannelRegs_FromTable__loop                             ; F85F77  cc 1c f3
	popw de                                       ; F85F7A  4a
	ret                                           ; F85F7B  0e

; ---------------------------------------------------------------------
; DSP_WriteAllChannelRegs -- push the same parameter block to all four channels
;
; Called from: not yet traced
; Inputs:  XBC/XDE hold the data for channel 1; XIZ, XWA/XHL and XIX/XIY carry
;          the data for channels 0, 2 and 3 respectively -- the routine shuffles
;          them into XBC/XDE before each call.
; Outputs: 8 registers written in each of channels 1, 0, 2, 3, in that order.
; Notes:   the order really is 1, 0, 2, 3; the sibling's comments say the same.
;          Byte-identical to the KN5000 sub-CPU's routine of this name.
; ---------------------------------------------------------------------
DSP_WriteAllChannelRegs:
	push XBC                                      ; F85F7C  39
	push XDE                                      ; F85F7D  3a
	pushw 0x01                                    ; F85F7E  0b 01 00   channel 1 first -- not 0
	calr DSP_WriteChannelRegs_Inner                                 ; F85F81  1e 24 00
	ld XBC,(XSP+0x0a)                             ; F85F84  af 0a 21
	ld XDE,XIZ                                    ; F85F87  ee 8a
	pushw 0x00                                    ; F85F89  0b 00 00
	calr DSP_WriteChannelRegs_Inner                                 ; F85F8C  1e 19 00
	ld XBC,XWA                                    ; F85F8F  e8 89
	ld XDE,XHL                                    ; F85F91  eb 8a
	pushw 0x02                                    ; F85F93  0b 02 00
	calr DSP_WriteChannelRegs_Inner                                 ; F85F96  1e 0f 00
	ld XBC,XIX                                    ; F85F99  ec 89
	ld XDE,XIY                                    ; F85F9B  ed 8a
	pushw 0x03                                    ; F85F9D  0b 03 00
	calr DSP_WriteChannelRegs_Inner                                 ; F85FA0  1e 05 00
	inc 0,XSP                                     ; F85FA3  ef 60   drop the four pushed channel numbers
	pop XDE                                       ; F85FA5  5a
	pop XBC                                       ; F85FA6  59
	ret                                           ; F85FA7  0e

; ---------------------------------------------------------------------
; DSP_WriteChannelRegs_Inner -- write one channel's 8 registers from XBC/XDE
;
; Called from: DSP_WriteAllChannelRegs, four times
; Inputs:  channel number pushed by the caller, read back at (XSP+0x0C);
;          XBC = the first four bytes (C, B, then QBC's C and B),
;          XDE = the rest (E, D, then QDE's C and B)
; Outputs: registers (channel<<5)|0x10 .. +7 written.  XIY, WA, BC preserved.
; Notes:   the seventh write is `ld (XIY+0x00),0x00`, i.e. a zero to the INDEX
;          port rather than to the data port at +2.  That is in the KN5000's
;          copy too, byte for byte, so it is either a deliberate "index 0" park
;          or a bug both machines inherit from the same source.  Not resolved.
; ---------------------------------------------------------------------
DSP_WriteChannelRegs_Inner:
	push XIY                                      ; F85FA8  3d
	pushw wa                                      ; F85FA9  28
	pushw bc                                      ; F85FAA  29
	ld A,(XSP+0x0c)                               ; F85FAB  8f 0c 21   the pushed channel number
	sll a, 0x05                                   ; F85FAE  c9 ee 05
	set 0x04,A                                    ; F85FB1  c9 31 04
	ld XIY,0x007f0000                             ; F85FB4  45 00 00 7f 00   the DSP register file
	ld (XIY),A                                    ; F85FB9  b5 41
	ld (XIY+0x02),C                               ; F85FBB  bd 02 43
	inc 1,A                                       ; F85FBE  c9 61
	ld (XIY),A                                    ; F85FC0  b5 41
	ld (XIY+0x02),B                               ; F85FC2  bd 02 42
	inc 1,A                                       ; F85FC5  c9 61
	ld (XIY),A                                    ; F85FC7  b5 41
	ld BC,QBC                                     ; F85FC9  d7 e6 89
	ld (XIY+0x02),C                               ; F85FCC  bd 02 43
	inc 1,A                                       ; F85FCF  c9 61
	ld (XIY),A                                    ; F85FD1  b5 41
	ld (XIY+0x02),B                               ; F85FD3  bd 02 42
	inc 1,A                                       ; F85FD6  c9 61
	ld (XIY),A                                    ; F85FD8  b5 41
	ld (XIY+0x02),E                               ; F85FDA  bd 02 45
	inc 1,A                                       ; F85FDD  c9 61
	ld (XIY),A                                    ; F85FDF  b5 41
	ld (XIY+0x02),D                               ; F85FE1  bd 02 44   0x00 written to the INDEX port, not the data port
	inc 1,A                                       ; F85FE4  c9 61
	ld (XIY),A                                    ; F85FE6  b5 41
	ld BC,QDE                                     ; F85FE8  d7 ea 89
	ld (XIY+0x02),C                               ; F85FEB  bd 02 43
	inc 1,A                                       ; F85FEE  c9 61
	ld (XIY),A                                    ; F85FF0  b5 41
	ld (XIY+0x02),B                               ; F85FF2  bd 02 42
	popw bc                                       ; F85FF5  49
	popw wa                                       ; F85FF6  48
	pop XIY                                       ; F85FF7  5d
	ret                                           ; F85FF8  0e
	.incbin "original_ROMs/wsa1_prom_a.ic12", 0x005FF9, 0x008486

; ==============================================================================
; 0xF8E47F-0xF8E54E -- INT0: the inter-processor link, and INTTC2
; ==============================================================================
;
; ★ HOW A MESSAGE ARRIVES FROM THE OTHER PROCESSOR.  notes/FINDINGS-memory-map.md
;   lists 0x7C0000 as "inter-processor link port (strobe P7.0, busy P7.3)"
;   without saying what the protocol is.  This handler is the protocol's
;   receiving half, and the mechanism is worth stating plainly because it is
;   unusual:
;
;     1. the first byte of a message raises INT0.  This handler reads it from
;        0x7C0000, keeps a copy at (0x600780), and uses it as a COMMAND;
;     2. from the command it works out how many more bytes will follow and
;        where they should go, and programmes micro-DMA channel 3 with that
;        destination and count;
;     3. it then writes DMA3V = 0x0A.  0x0A << 2 = 0x28, which is INT0's own
;        vector -- `tlcs900_process_hdma` computes the trigger as
;        (DMAnV & 0x1F) << 2 (tmp95c061.cpp:353).  So every FURTHER byte of the
;        message is absorbed by the DMA engine without the CPU seeing it, and
;        the CPU next hears about the message when the transfer completes and
;        raises INTTC3;
;     4. (0x6007DA) is set on the way in to tell INTTC3 (0xF8E54F, not yet
;        converted) which message it is finishing.
;
;   COMMAND BYTE -> DESTINATION AND LENGTH, exactly as the code has it:
;     0xE1        6 bytes  -> 0x6007D3   (0x6007DA) = 2
;     0xE2       10 bytes  -> 0x600788   (0x6007DA) = 3
;     0xE6        no payload            (0x6007DA) = 0, and bit 6 of (0x8A)
;                                        is cleared
;     anything   (byte & 0x1F) + 1 bytes -> 0x6007B3   (0x6007DA) = 1
;     else
;   ⚠ What the commands MEAN is not established -- only their payload sizes and
;   where the payload lands.  Do not name them.
;
;   P7 (SFR 0x13) carries the handshake: bit 2 is tested on entry and, when set,
;   the interrupt is taken and dropped without touching the port at all; bit 1 is
;   cleared after the DMA is armed, on all three paths that arm one.
;
; ---------------------------------------------------------------------
; INT0_LinkByte -- a byte arrived on the inter-processor link at 0x7C0000
;
; Called from: vector slot 0x28 (0xFFFF28 holds 0x00F40EDC, a prom_b thunk whose
;          body is `jp 0xF8E47F`).  ⚠ Only while DMA3V is not pointing at 0x28 --
;          once this handler arms the DMA, the same interrupt goes to the DMA
;          engine instead, and does not reach here again until INTTC3 re-points
;          it.  That is the whole design.
; Inputs:  the byte at 0x7C0000; P7 bit 2
; Outputs: (0x600780) = the command byte; micro-DMA channel 3 armed; DMA3V =
;          0x0A; (0x6007DA) = the completion selector; P7 bit 1 cleared.
;          All five saved registers restored; exits with RETI.
; Notes:   the four arming sites all reach uDMA3_SetDest (0xF8E6C9) by loading
;          its address into XIX and jumping, having pushed count, destination and
;          a return address -- a stack-argument call written as a tail jump so
;          the helper's `ret` lands back in this handler.
; ---------------------------------------------------------------------
INT0_LinkByte:
	push XBC                                      ; F8E47F  39
	pushw wa                                      ; F8E480  28
	push XIY                                      ; F8E481  3d
	pushw hl                                      ; F8E482  2b
	push XIX                                      ; F8E483  3c
	lda_24 xix, (uDMA3_SetDest)                   ; F8E484  f2 c9 e6 f8 34   XIX = uDMA3_SetDest, called four different ways below
	bit_dd8 0x02, 0x13                            ; F8E489  f0 13 ca   P7 bit 2 -- when set, take the interrupt and do nothing
	jrl nz, INT0_Link__return                              ; F8E48C  7e 98 00
	ld XBC,0x007c0000                             ; F8E48F  41 00 00 7c 00   the inter-processor link port
	ld H,(XBC)                                    ; F8E494  81 26   read the command byte
	stb_da (0x600780), h                          ; F8E496  f2 80 07 60 46   and keep it
	ld C,H                                        ; F8E49B  ce 8b
	extz BC                                       ; F8E49D  d9 12
	cp BC,0x00e1                                  ; F8E49F  d9 cf e1 00
	jr z, INT0_Cmd_E1                                ; F8E4A3  66 0e
	cp BC,0x00e2                                  ; F8E4A5  d9 cf e2 00
	jr z, INT0_Cmd_E2                                ; F8E4A9  66 27
	cp BC,0x00e6                                  ; F8E4AB  d9 cf e6 00
	jr z, INT0_Cmd_E6                                ; F8E4AF  66 40
	jr INT0_Cmd_Other                                   ; F8E4B1  68 4b
INT0_Cmd_E1:
	stib_da (0x6007da), 0x02                      ; F8E4B3  f2 da 07 60 00 02   (0x6007DA) = which completion path INTTC3 should take
	pushw 0x06                                    ; F8E4B9  0b 06 00   count = 6
	lda_24 xbc, (0x6007d3)                        ; F8E4BC  f2 d3 07 60 31   destination = 0x6007D3
	push XBC                                      ; F8E4C1  39
	lda_24 xiy, (0xf8e4ca)                        ; F8E4C2  f2 ca e4 f8 35   the return address for the stack-argument call
	push XIY                                      ; F8E4C7  3d
	jp (xix)                                      ; F8E4C8  b4 d8
	ldio 0x7f, 0x0a                               ; F8E4CA  08 7f 0a   DMA3V = 0x0A; 0x0A << 2 = 0x28 = INT0, so the DMA engine now
	res_dd8 0x01, 0x13                            ; F8E4CD  f0 13 b1   absorbs the rest of the message.  P7 bit 1 = the acknowledge line
	jr INT0_Link__drop_args                                   ; F8E4D0  68 53
INT0_Cmd_E2:
	stib_da (0x6007da), 0x03                      ; F8E4D2  f2 da 07 60 00 03
	pushw 0x0a                                    ; F8E4D8  0b 0a 00   count = 10
	lda_24 xbc, (0x600788)                        ; F8E4DB  f2 88 07 60 31   destination = 0x600788
	push XBC                                      ; F8E4E0  39
	lda_24 xiy, (0xf8e4e9)                        ; F8E4E1  f2 e9 e4 f8 35
	push XIY                                      ; F8E4E6  3d
	jp (xix)                                      ; F8E4E7  b4 d8
	ldio 0x7f, 0x0a                               ; F8E4E9  08 7f 0a
	res_dd8 0x01, 0x13                            ; F8E4EC  f0 13 b1
	jr INT0_Link__drop_args                                   ; F8E4EF  68 34
INT0_Cmd_E6:
	stib_da (0x6007da), 0x00                      ; F8E4F1  f2 da 07 60 00 00
	m_res 6, MD24, 0x00008a                       ; F8E4F7  f2 8a 00 00 b6   0xE6 takes no payload at all
	jr INT0_Link__return                                   ; F8E4FC  68 29
INT0_Cmd_Other:
	stib_da (0x6007da), 0x01                      ; F8E4FE  f2 da 07 60 00 01
	ldb_da c, (0x600780)                          ; F8E504  c2 80 07 60 23   any other command: the low 5 bits are the payload LENGTH - 1
	and C,0x1f                                    ; F8E509  cb cc 1f
	extz BC                                       ; F8E50C  d9 12
	inc 1,BC                                      ; F8E50E  d9 61
	pushw bc                                      ; F8E510  29
	lda_24 xbc, (0x6007b3)                        ; F8E511  f2 b3 07 60 31   destination = 0x6007B3
	push XBC                                      ; F8E516  39
	lda_24 xiy, (0xf8e51f)                        ; F8E517  f2 1f e5 f8 35
	push XIY                                      ; F8E51C  3d
	jp (xix)                                      ; F8E51D  b4 d8
	ldio 0x7f, 0x0a                               ; F8E51F  08 7f 0a
	res_dd8 0x01, 0x13                            ; F8E522  f0 13 b1
INT0_Link__drop_args:
	inc 6,XSP                                     ; F8E525  ef 66   drop the three pushed arguments
INT0_Link__return:
	pop XIX                                       ; F8E527  5c
	popw hl                                       ; F8E528  4b
	pop XIY                                       ; F8E529  5d
	popw wa                                       ; F8E52A  48
	pop XBC                                       ; F8E52B  59
	reti                                          ; F8E52C  07

; ---------------------------------------------------------------------
; INTTC2_uDMA2Done -- micro-DMA channel 2 finished its transfer
;
; Called from: vector slot 0x7C (0xFFFF7C holds 0x00F40EE4, a prom_b thunk whose
;          body is `jp 0xF8E52D`)
; Inputs:  (0x6007D9)
; Outputs: timer 2 stopped (TRUN bit 2), and (0x6007D9) stepped 2 -> 1 -> 0.
;          Returns with RETI having touched no registers at all.
; Notes:   channel 2 is the one RESET's comment points at: 0xF8E166 writes
;          DMA2V = 0x12 (0x12 << 2 = 0x48 = INTT2) and starts timer 2, so the
;          timer paces the transfer and this handler stops it again.  The
;          (0x6007D9) countdown is what the arming code at 0xF8E173 spins on.
; ---------------------------------------------------------------------
INTTC2_uDMA2Done:
	res_dd8 0x02, 0x20                            ; F8E52D  f0 20 b2   TRUN bit 2 = stop timer 2, which is what triggers channel 2
	m_cp_mi8 MB24, 0x6007d9, 0x01                 ; F8E530  c2 d9 07 60 3f 01
	jr nz, INTTC2_uDMA2Done__try2                               ; F8E536  6e 08
	stib_da (0x6007d9), 0x00                      ; F8E538  f2 d9 07 60 00 00
	jr INTTC2_uDMA2Done__ret                                   ; F8E53E  68 0e
INTTC2_uDMA2Done__try2:
	m_cp_mi8 MB24, 0x6007d9, 0x02                 ; F8E540  c2 d9 07 60 3f 02
	jr nz, INTTC2_uDMA2Done__ret                               ; F8E546  6e 06
	stib_da (0x6007d9), 0x01                      ; F8E548  f2 d9 07 60 00 01
INTTC2_uDMA2Done__ret:
	reti                                          ; F8E54E  07
	.incbin "original_ROMs/wsa1_prom_a.ic12", 0x00E54F, 0x000153

; ==============================================================================
; 0xF8E6A2-0xF8E6F9 -- micro-DMA channel setup, and a word-at-a-time block copy
; ==============================================================================
;
; Eight one-line leaf routines around the TLCS-900 micro-DMA control registers.
; Their arguments come off the STACK, not in registers -- (XSP+4) is a 32-bit
; address or a 16-bit count and (XSP+8) is the second argument -- so they are
; compiler-called helpers, and the caller has to clean up (0xF8E171's
; `inc 6,XSP` is one such site).
;
; ⚠ WHICH CONTROL REGISTER IS WHICH is MAME's decode, not a databook:
; 900tbl.hxx:3931-4030 maps 0x00/0x04/0x08/0x0C to DMAS0-3, 0x10-0x1C to
; DMAD0-3, 0x20-0x2C to DMAC0-3 and 0x22-0x2E to DMAM0-3 for exactly this part
; family (the `// TMP96C141/TMP95C061/TMP95C063` cases).  The equates are in the
; macro prelude at the top of this file.
;
; CHANNEL 2 is the one RESET's comment already points at: 0xF8E166 arms it with
; `ldio DMA2V,0x12`, and 0x12 << 2 = 0x48 = INTT2, so timer 2 drives it.  Both
; channel 2 and channel 3 are set up from here.
;
; ---------------------------------------------------------------------
; uDMA2_SetDest / uDMA2_SetSource / uDMA3_SetSource / uDMA3_SetDest
; uDMA2_GetCount / uDMA3_GetCount / uDMA3_GetDest
;
; Called from: 0xF8E162 calls uDMA2_SetSource; the rest not yet traced
; Inputs:  (XSP+4) = a 32-bit address, or the count; (XSP+8) = the second
;          argument -- the transfer count for the "source" pair and the DMAM
;          mode byte for the "dest" pair
; Outputs: the named control register.  BC/XBC clobbered.
; Notes:   the names are mechanical: each routine writes one named control
;          register and nothing else.
; ---------------------------------------------------------------------
uDMA2_SetDest:
	ld XBC,(XSP+0x04)                             ; F8E6A2  af 04 21
	m_ldc_cr_reg RL+r1, CR_DMAD2                  ; F8E6A5  e9 2e 18
	ld C,(XSP+0x08)                               ; F8E6A8  8f 08 23
	m_ldc_cr_reg RB+r3, CR_DMAM2                  ; F8E6AB  cb 2e 2a
	ret                                           ; F8E6AE  0e
uDMA2_SetSource:
	ld XBC,(XSP+0x04)                             ; F8E6AF  af 04 21
	m_ldc_cr_reg RL+r1, CR_DMAS2                  ; F8E6B2  e9 2e 08
	ld BC,(XSP+0x08)                              ; F8E6B5  9f 08 21
	m_ldc_cr_reg RW+r1, CR_DMAC2                  ; F8E6B8  d9 2e 28
	ret                                           ; F8E6BB  0e
uDMA3_SetSource:
	ld XBC,(XSP+0x04)                             ; F8E6BC  af 04 21
	m_ldc_cr_reg RL+r1, CR_DMAS3                  ; F8E6BF  e9 2e 0c
	ld C,(XSP+0x08)                               ; F8E6C2  8f 08 23
	m_ldc_cr_reg RB+r3, CR_DMAM3                  ; F8E6C5  cb 2e 2e
	ret                                           ; F8E6C8  0e
uDMA3_SetDest:
	ld XBC,(XSP+0x04)                             ; F8E6C9  af 04 21
	m_ldc_cr_reg RL+r1, CR_DMAD3                  ; F8E6CC  e9 2e 1c
	ld BC,(XSP+0x08)                              ; F8E6CF  9f 08 21
	m_ldc_cr_reg RW+r1, CR_DMAC3                  ; F8E6D2  d9 2e 2c
	ret                                           ; F8E6D5  0e
uDMA2_GetCount:
	m_ldc_reg_cr RW+r0, CR_DMAC2                  ; F8E6D6  d8 2f 28
	ret                                           ; F8E6D9  0e
uDMA3_GetCount:
	m_ldc_reg_cr RW+r0, CR_DMAC3                  ; F8E6DA  d8 2f 2c
	ret                                           ; F8E6DD  0e
uDMA3_GetDest:
	m_ldc_reg_cr RL+r5, CR_DMAD3                  ; F8E6DE  ed 2f 1c
	ret                                           ; F8E6E1  0e

; ---------------------------------------------------------------------
; MemCopyWords -- copy (XSP+0x10) BYTES from (XSP+0x0C) to (XSP+0x08)
;
; Called from: not yet traced
; Inputs:  all three arguments on the stack; XIY = destination, XIX = source,
;          BC = byte count (the routine loads them itself)
; Outputs: the block copied.  XIX is preserved; XIY, BC clobbered.
; Notes:   it is a word copy with a one-byte lead-in: if the count is odd it
;          does a single LDI first, then halves the count and runs LDIRW.  Not
;          micro-DMA at all despite the company it keeps -- LDIR/LDIRW are
;          ordinary block-transfer instructions.
; ---------------------------------------------------------------------
MemCopyWords:
	push XIX                                      ; F8E6E2  3c
	ld BC,(XSP+0x10)                              ; F8E6E3  9f 10 21
	ld XIY,(XSP+0x08)                             ; F8E6E6  af 08 25
	ld XIX,(XSP+0x0c)                             ; F8E6E9  af 0c 24
	bit 0x00,BC                                   ; F8E6EC  d9 33 00
	jr z, .LF8E6F3                                ; F8E6EF  66 02
	ldi85                                         ; F8E6F1  85 10
.LF8E6F3:
	srl bc, 0x01                                  ; F8E6F3  d9 ef 01
	ldirw                                         ; F8E6F6  95 11
	pop XIX                                       ; F8E6F8  5c
	ret                                           ; F8E6F9  0e
	.incbin "original_ROMs/wsa1_prom_a.ic12", 0x00E6FA, 0x000106

; ==============================================================================
; 0xF8E800-0xF8E9A4 -- the LCD controller: entry thunks and the power-on setup
; ==============================================================================
;
; ★ THE CONTROLLER IS AN SED1330-FAMILY LCD CONTROLLER, and this is citable
;   rather than guessed.  Two independent checks:
;
;   1. COMMAND SET.  Every command byte this firmware ever writes to 0x790001 is
;      in MAME's SED1330 instruction table (src/devices/video/sed1330.cpp:23-39),
;      and no byte outside that table is ever written:
;        0x40 SYSTEM SET   0x42 MWRITE   0x43 MREAD   0x44 SCROLL
;        0x46 CSRW         0x47 CSRR     0x4C CSRDIR RIGHT
;        0x58 DISP OFF     0x59 DISP ON  0x5A HDOT SCR
;        0x5B OVLAY        0x5D CSRFORM
;      (a byte census of prom_a and prom_b finds exactly these and nothing else).
;
;   2. PORT SHAPE.  MAME's own drivers wire this part up as
;        even address: read = status_r, write = data_w
;        odd  address: read = data_r,   write = command_w
;      (mame/skeleton/textelcomp.cpp:147-148, and the commented-out map in
;      mame/epson/px8.cpp:534-535).  That is exactly how this firmware uses
;      0x790000/0x790001, including the busy poll: `bit 6,(0x790000)`, and
;      sed1330_device::status_r returns `m_bf << 6` (sed1330.cpp:245-251).
;
;   The parameter bytes below then decode into a consistent panel, which is the
;   third check: 320 x 240 pixels, 40 bytes per line, three graphics layers
;   OR-composited, at display-RAM 0x0000 / 0x2600 / 0x4C00.
;
;   ⚠ What is NOT established: the exact part number.  SED1330, SED1335,
;   S1D13305 and the second-source clones share this command set, and nothing
;   in the firmware distinguishes them.  Say "SED1330-family", not "SED1330".
;
; RAM the driver keeps alongside the controller (all CS1 static RAM):
;   (0x2541) (0x2543) (0x2545)  the three layer base addresses, as sent to SCROLL
;   (0x2554)  the OVLAY byte             (0x2557)/(0x2558)  AP = bytes per line
;   (0x2559)  the last DISP ON/OFF byte  (0x255A)  the last cursor address
;   (0xC6) bit 0  "do not wait for BUSY" -- set when the display is turned off
;
.equ LCDC_DATA, 0x790000	; write = data.  read = status, bit 6 = busy
.equ LCDC_CMD,  0x790001	; write = command.  read = data

; ---------------------------------------------------------------------
; LCD_EntryThunks -- six `jp` slots, the module's public entry points
;
; Called from: not yet traced (the callers are in prom_b)
; Inputs:  none
; Outputs: none
; Notes:   four of the six are `jp 0xF8E818`, i.e. a bare RET, so only two of
;          the six services exist: slot 0 is the power-on setup and slot 2 is
;          the (0x97) bit-4 test at 0xF8E99F.  A table of `jp`s rather than of
;          pointers is the usual way a fixed entry-point ABI is kept stable
;          across firmware revisions.
; ---------------------------------------------------------------------
LCD_EntryThunks:
	jp LCD_Init_SED1330                           ; F8E800  1b 19 e8 f8
	jp LCD_Thunk_Unused                           ; F8E804  1b 18 e8 f8
	jp LCD_Thunk2_Test97b4                        ; F8E808  1b 9f e9 f8
	jp LCD_Thunk_Unused                           ; F8E80C  1b 18 e8 f8
	jp LCD_Thunk_Unused                           ; F8E810  1b 18 e8 f8
	jp LCD_Thunk_Unused                           ; F8E814  1b 18 e8 f8
LCD_Thunk_Unused:
	ret                                           ; F8E818  0e

; ---------------------------------------------------------------------
; LCD_Init_SED1330 -- power-on setup of the LCD controller, then clear the screen
;
; Called from: LCD_EntryThunks slot 0 (0xF8E800)
; Inputs:  none
; Outputs: the controller fully programmed and every one of its 32768 display
;          bytes zeroed, display then enabled.  (0x2541)-(0x2559) hold copies of
;          the values sent.  XIY, WA and BC are clobbered.
; Notes:   this routine never reads the BUSY flag.  It separates accesses with
;          runs of four NOPs instead -- a fixed delay, which is the usual way to
;          drive this part before the display is on and the busy flag means
;          anything.  Every one of those NOPs is a real instruction in the ROM,
;          which is why they are written out rather than folded into a .fill.
; ---------------------------------------------------------------------
LCD_Init_SED1330:
	ld XIY,0x00790000                             ; F8E819  45 00 00 79 00   XIY = the controller's two ports
	ld (XIY+0x01),0x40                            ; F8E81E  bd 01 00 40   SYSTEM SET
	nop                                           ; F8E822  00
	nop                                           ; F8E823  00
	nop                                           ; F8E824  00
	nop                                           ; F8E825  00
	ld (XIY),0x30                                 ; F8E826  b5 00 30   P1 0x30: internal CG ROM, 8-line chars, single-panel drive
	nop                                           ; F8E829  00
	nop                                           ; F8E82A  00
	nop                                           ; F8E82B  00
	nop                                           ; F8E82C  00
	ld (XIY),0x07                                 ; F8E82D  b5 00 07   P2 FX   = 7  -> 8 pixels per character cell
	nop                                           ; F8E830  00
	nop                                           ; F8E831  00
	nop                                           ; F8E832  00
	nop                                           ; F8E833  00
	ld (XIY),0x00                                 ; F8E834  b5 00 00   P3 FY   = 0  -> 1 line per cell (this is a graphics-only panel)
	nop                                           ; F8E837  00
	nop                                           ; F8E838  00
	nop                                           ; F8E839  00
	nop                                           ; F8E83A  00
	ld (XIY),0x27                                 ; F8E83B  b5 00 27   P4 C/R  = 39 -> 40 bytes displayed per line = 320 pixels
	nop                                           ; F8E83E  00
	nop                                           ; F8E83F  00
	nop                                           ; F8E840  00
	nop                                           ; F8E841  00
	ld (XIY),0x35                                 ; F8E842  b5 00 35   P5 TC/R = 53 -> 54 byte-times per line total
	nop                                           ; F8E845  00
	nop                                           ; F8E846  00
	nop                                           ; F8E847  00
	nop                                           ; F8E848  00
	ld (XIY),0xef                                 ; F8E849  b5 00 ef   P6 L/F  = 239 -> 240 lines
	nop                                           ; F8E84C  00
	nop                                           ; F8E84D  00
	nop                                           ; F8E84E  00
	nop                                           ; F8E84F  00
	ldb a, 0x28                                   ; F8E850  21 28   P7 APL = 0x28 -- virtual screen width, low byte
	ld (XIY),A                                    ; F8E852  b5 41
	stb_d8 (0x2557), a                            ; F8E854  f1 57 25 41
	nop                                           ; F8E858  00
	nop                                           ; F8E859  00
	nop                                           ; F8E85A  00
	ldb a, 0x00                                   ; F8E85B  21 00   P8 APH = 0x00 -> AP = 40 bytes per line
	ld (XIY),A                                    ; F8E85D  b5 41
	stb_d8 (0x2558), a                            ; F8E85F  f1 58 25 41
	nop                                           ; F8E863  00
	nop                                           ; F8E864  00
	nop                                           ; F8E865  00
	ld (XIY+0x01),0x44                            ; F8E866  bd 01 00 44   SCROLL
	nop                                           ; F8E86A  00
	nop                                           ; F8E86B  00
	nop                                           ; F8E86C  00
	nop                                           ; F8E86D  00
	ld (XIY),0x00                                 ; F8E86E  b5 00 00   SAD1 low
	nop                                           ; F8E871  00
	nop                                           ; F8E872  00
	nop                                           ; F8E873  00
	nop                                           ; F8E874  00
	ld (XIY),0x00                                 ; F8E875  b5 00 00   SAD1 high  -> layer 1 at display-RAM 0x0000
	nop                                           ; F8E878  00
	nop                                           ; F8E879  00
	nop                                           ; F8E87A  00
	nop                                           ; F8E87B  00
	ld (XIY),0xf0                                 ; F8E87C  b5 00 f0   SL1  = 240 lines
	nop                                           ; F8E87F  00
	nop                                           ; F8E880  00
	nop                                           ; F8E881  00
	nop                                           ; F8E882  00
	ld (XIY),0x00                                 ; F8E883  b5 00 00   SAD2 low
	nop                                           ; F8E886  00
	nop                                           ; F8E887  00
	nop                                           ; F8E888  00
	nop                                           ; F8E889  00
	ld (XIY),0x26                                 ; F8E88A  b5 00 26   SAD2 high  -> layer 2 at 0x2600
	nop                                           ; F8E88D  00
	nop                                           ; F8E88E  00
	nop                                           ; F8E88F  00
	nop                                           ; F8E890  00
	ld (XIY),0xf0                                 ; F8E891  b5 00 f0   SL2  = 240 lines
	nop                                           ; F8E894  00
	nop                                           ; F8E895  00
	nop                                           ; F8E896  00
	nop                                           ; F8E897  00
	ld (XIY),0x00                                 ; F8E898  b5 00 00   SAD3 low
	nop                                           ; F8E89B  00
	nop                                           ; F8E89C  00
	nop                                           ; F8E89D  00
	nop                                           ; F8E89E  00
	ld (XIY),0x4c                                 ; F8E89F  b5 00 4c   SAD3 high  -> layer 3 at 0x4C00.  SAD4 is not sent
	ldb a, 0x00                                   ; F8E8A2  21 00
	ldb w, 0x00                                   ; F8E8A4  20 00
	stda16 (0x2541), wa                           ; F8E8A6  f1 41 25 50
	ldb a, 0x00                                   ; F8E8AA  21 00
	ldb w, 0x26                                   ; F8E8AC  20 26
	stda16 (0x2543), wa                           ; F8E8AE  f1 43 25 50
	ldb a, 0x00                                   ; F8E8B2  21 00
	ldb w, 0x4c                                   ; F8E8B4  20 4c
	stda16 (0x2545), wa                           ; F8E8B6  f1 45 25 50
	ld (XIY+0x01),0x5a                            ; F8E8BA  bd 01 00 5a   HDOT SCR
	nop                                           ; F8E8BE  00
	nop                                           ; F8E8BF  00
	nop                                           ; F8E8C0  00
	nop                                           ; F8E8C1  00
	ld (XIY),0x00                                 ; F8E8C2  b5 00 00   0 -- no horizontal dot scroll
	nop                                           ; F8E8C5  00
	nop                                           ; F8E8C6  00
	nop                                           ; F8E8C7  00
	nop                                           ; F8E8C8  00
	ld (XIY+0x01),0x5b                            ; F8E8C9  bd 01 00 5b   OVLAY
	nop                                           ; F8E8CD  00
	nop                                           ; F8E8CE  00
	nop                                           ; F8E8CF  00
	nop                                           ; F8E8D0  00
	ld (XIY),0x1c                                 ; F8E8D1  b5 00 1c   0x1C: MX=0 (OR), layers 1 and 3 in GRAPHICS mode, 3 layers
	stdi8 (0x2554), 0x1c                          ; F8E8D4  f1 54 25 00 1c
	nop                                           ; F8E8D9  00
	nop                                           ; F8E8DA  00
	nop                                           ; F8E8DB  00
	nop                                           ; F8E8DC  00
	nop                                           ; F8E8DD  00
	ld (XIY+0x01),0x5d                            ; F8E8DE  bd 01 00 5d   CSRFORM
	nop                                           ; F8E8E2  00
	nop                                           ; F8E8E3  00
	nop                                           ; F8E8E4  00
	nop                                           ; F8E8E5  00
	nop                                           ; F8E8E6  00
	ld (XIY),0x07                                 ; F8E8E7  b5 00 07   cursor width
	nop                                           ; F8E8EA  00
	nop                                           ; F8E8EB  00
	nop                                           ; F8E8EC  00
	nop                                           ; F8E8ED  00
	nop                                           ; F8E8EE  00
	ld (XIY),0x87                                 ; F8E8EF  b5 00 87   cursor height / block cursor
	nop                                           ; F8E8F2  00
	nop                                           ; F8E8F3  00
	nop                                           ; F8E8F4  00
	nop                                           ; F8E8F5  00
	ld (XIY+0x01),0x58                            ; F8E8F6  bd 01 00 58   DISP OFF -- draw the screen blank before it is shown
	nop                                           ; F8E8FA  00
	nop                                           ; F8E8FB  00
	nop                                           ; F8E8FC  00
	nop                                           ; F8E8FD  00
	ld (XIY),0x54                                 ; F8E8FE  b5 00 54   0x54: cursor off, all three layers on, none flashing
	ldb a, 0x54                                   ; F8E901  21 54
	stb_d8 (0x2559), a                            ; F8E903  f1 59 25 41
	nop                                           ; F8E907  00
	nop                                           ; F8E908  00
	nop                                           ; F8E909  00
	nop                                           ; F8E90A  00
	ld (XIY+0x01),0x4c                            ; F8E90B  bd 01 00 4c   CSRDIR RIGHT -- the cursor auto-increments after every MWRITE
	nop                                           ; F8E90F  00
	nop                                           ; F8E910  00
	nop                                           ; F8E911  00
	nop                                           ; F8E912  00
	nop                                           ; F8E913  00
	nop                                           ; F8E914  00
	ld (XIY+0x01),0x46                            ; F8E915  bd 01 00 46   CSRW -- set the cursor (= the memory pointer)
	nop                                           ; F8E919  00
	nop                                           ; F8E91A  00
	nop                                           ; F8E91B  00
	nop                                           ; F8E91C  00
	xor WA,WA                                     ; F8E91D  d8 d0
	ld (XIY),A                                    ; F8E91F  b5 41
	nop                                           ; F8E921  00
	nop                                           ; F8E922  00
	nop                                           ; F8E923  00
	nop                                           ; F8E924  00
	ld (XIY),A                                    ; F8E925  b5 41
	nop                                           ; F8E927  00
	nop                                           ; F8E928  00
	nop                                           ; F8E929  00
	nop                                           ; F8E92A  00
	ld (XIY+0x01),0x42                            ; F8E92B  bd 01 00 42   MWRITE -- and now 0x800 x 16 = 32768 zero bytes follow
	ldw bc, 0x0800                                ; F8E92F  31 00 08   0x800 iterations of a 16-store unrolled loop
	ldb a, 0x00                                   ; F8E932  21 00
LCD_Init__clear_loop:
	nop                                           ; F8E934  00
	nop                                           ; F8E935  00
	nop                                           ; F8E936  00
	ld (XIY),A                                    ; F8E937  b5 41
	nop                                           ; F8E939  00
	nop                                           ; F8E93A  00
	nop                                           ; F8E93B  00
	nop                                           ; F8E93C  00
	ld (XIY),A                                    ; F8E93D  b5 41
	nop                                           ; F8E93F  00
	nop                                           ; F8E940  00
	nop                                           ; F8E941  00
	nop                                           ; F8E942  00
	ld (XIY),A                                    ; F8E943  b5 41
	nop                                           ; F8E945  00
	nop                                           ; F8E946  00
	nop                                           ; F8E947  00
	nop                                           ; F8E948  00
	ld (XIY),A                                    ; F8E949  b5 41
	nop                                           ; F8E94B  00
	nop                                           ; F8E94C  00
	nop                                           ; F8E94D  00
	nop                                           ; F8E94E  00
	ld (XIY),A                                    ; F8E94F  b5 41
	nop                                           ; F8E951  00
	nop                                           ; F8E952  00
	nop                                           ; F8E953  00
	nop                                           ; F8E954  00
	ld (XIY),A                                    ; F8E955  b5 41
	nop                                           ; F8E957  00
	nop                                           ; F8E958  00
	nop                                           ; F8E959  00
	nop                                           ; F8E95A  00
	ld (XIY),A                                    ; F8E95B  b5 41
	nop                                           ; F8E95D  00
	nop                                           ; F8E95E  00
	nop                                           ; F8E95F  00
	nop                                           ; F8E960  00
	ld (XIY),A                                    ; F8E961  b5 41
	nop                                           ; F8E963  00
	nop                                           ; F8E964  00
	nop                                           ; F8E965  00
	nop                                           ; F8E966  00
	ld (XIY),A                                    ; F8E967  b5 41
	nop                                           ; F8E969  00
	nop                                           ; F8E96A  00
	nop                                           ; F8E96B  00
	nop                                           ; F8E96C  00
	ld (XIY),A                                    ; F8E96D  b5 41
	nop                                           ; F8E96F  00
	nop                                           ; F8E970  00
	nop                                           ; F8E971  00
	nop                                           ; F8E972  00
	ld (XIY),A                                    ; F8E973  b5 41
	nop                                           ; F8E975  00
	nop                                           ; F8E976  00
	nop                                           ; F8E977  00
	nop                                           ; F8E978  00
	ld (XIY),A                                    ; F8E979  b5 41
	nop                                           ; F8E97B  00
	nop                                           ; F8E97C  00
	nop                                           ; F8E97D  00
	nop                                           ; F8E97E  00
	ld (XIY),A                                    ; F8E97F  b5 41
	nop                                           ; F8E981  00
	nop                                           ; F8E982  00
	nop                                           ; F8E983  00
	nop                                           ; F8E984  00
	ld (XIY),A                                    ; F8E985  b5 41
	nop                                           ; F8E987  00
	nop                                           ; F8E988  00
	nop                                           ; F8E989  00
	nop                                           ; F8E98A  00
	ld (XIY),A                                    ; F8E98B  b5 41
	nop                                           ; F8E98D  00
	nop                                           ; F8E98E  00
	nop                                           ; F8E98F  00
	nop                                           ; F8E990  00
	ld (XIY),A                                    ; F8E991  b5 41
	djnz16 bc, LCD_Init__clear_loop                           ; F8E993  d9 1c 9e
	nop                                           ; F8E996  00
	nop                                           ; F8E997  00
	nop                                           ; F8E998  00
	nop                                           ; F8E999  00
	ld (XIY+0x01),0x59                            ; F8E99A  bd 01 00 59   DISP ON, with no parameter byte: keeps the 0x54 above
	ret                                           ; F8E99E  0e

; ---------------------------------------------------------------------
; LCD_Thunk2_Test97b4 -- what LCD_EntryThunks slot 2 reaches
;
; Called from: LCD_EntryThunks slot 2 (0xF8E808)
; Inputs:  bit 4 of (0x97)
; Outputs: NONE.  Both arms of the branch land on the same RET, so this routine
;          has no effect at all; it only leaves the Z flag set from the bit test.
; Notes:   named for what it tests, because what the caller does with the flag
;          has not been traced.  A conditional jump whose two arms coincide is
;          usually a compiler artefact of an `if` whose body was optimised away.
; ---------------------------------------------------------------------
LCD_Thunk2_Test97b4:
	bit_dd8 0x04, 0x97                            ; F8E99F  f0 97 cc
	jr nz, .LF8E9A4                               ; F8E9A2  6e 00
.LF8E9A4:
	ret                                           ; F8E9A4  0e

; ==============================================================================
; 0xF8E9A5-0xF8EAC6 -- SWI7: the service-call gateway and its 64-slot table
; ==============================================================================

; ---------------------------------------------------------------------
; SWI7_ServiceCall_Dispatch -- `swi 7` is this firmware's system call
;
; Called from: vector slot 0x1C (0xFFFF1C holds 0x00F400A4, a prom_b thunk whose
;          body is `jp 0xF8E9A5`).  Every `swi 7` in either ROM lands here.
; Inputs:  A = service number.  Only A & 0x3F is used, so the number space is
;          exactly 64 wide -- which is also exactly the size of the table below,
;          and that agreement is what proves the table's length.
;          Every other register is passed straight through to the service; C is
;          the usual argument (LCD_Svc_0C_SetLayersOn reads C bits 0-2).
; Outputs: whatever the service returns.  HL is preserved across the dispatch
;          itself (pushed, restored before the call).
; Notes:   it writes 0 to control register 0x3C before re-enabling interrupts.
;          That register is the kernel's CRITICAL-SECTION DEPTH (see the kernel
;          block at 0xF856EC): IRQ_Epilogue reschedules only when it reads 1, and
;          Kernel_ServiceSoftTimers brackets its callbacks with depth++/depth--.
;          Zeroing it here means a service call can never itself cause a task
;          switch on the way out.
;          ⚠ unidasm prints control-register numbers as "unknown"; MAME does not
;          name the TLCS-900 control registers and no databook is in these
;          trees, so 0x3C stays a number here.
;
;          The final `pop SR` / `ret` pair is how a TLCS-900 SWI returns without
;          RETI: the SWI pushed SR, the service returned normally, and this
;          discards the saved SR before returning to the instruction after the
;          `swi`.
; ---------------------------------------------------------------------
SWI7_ServiceCall_Dispatch:
	pushw hl                                      ; F8E9A5  2b
	xor HL,HL                                     ; F8E9A6  db d3
	m_ldc_cr_reg RW+r3, 0x3c                      ; F8E9A8  db 2e 3c   control register 0x3C := 0 -- see the kernel at 0xF856EC
	ei 0x00                                       ; F8E9AB  06 00
	xor H,H                                       ; F8E9AD  ce d6
	and A,0x3f                                    ; F8E9AF  c9 cc 3f   only 6 bits of A select the service
	ld L,A                                        ; F8E9B2  c9 8f
	sla hl, 0x02                                  ; F8E9B4  db ec 02   index * 4
	ld XWA,0x00f8e9c6                             ; F8E9B7  40 c6 e9 f8 00   the table below
	.byte 0xe3, 0x07, 0xe0, 0xec, 0x20            ; F8E9BC  e3 07 e0 ec 20   ld XWA,(XWA+HL) -- fetch the entry.  llvm-mc has no spelling
	popw hl                                       ; F8E9C1  4b
	call (xwa)                                    ; F8E9C2  b0 e8   call it with the caller's own registers still live
	pop SR                                        ; F8E9C4  03   pop the SR the SWI pushed, then RET past it
	ret                                           ; F8E9C5  0e

; ---------------------------------------------------------------------
; SWI7_ServiceTable -- 64 x LE32, the service numbers
;
; Read by:  SWI7_ServiceCall_Dispatch (0xF8E9B7), indexed by (A & 0x3F) * 4.
; Layout:   64 entries, 256 bytes, 0xF8E9C6-0xF8EAC5.  35 of them are real; slot
;           0x18 and every slot from 0x23 up point at the bare RET that follows
;           the table, which is what makes the used range 0x00-0x22.
; Notes:    every implemented service is in prom_a's 0xF8E-0xF90 block and every
;           one of them talks to the LCD controller at 0x790000/0x790001 --
;           directly, or through the shared setup at 0xF8EE93 that most of them
;           open with.  So SWI7 is, in this firmware, the GRAPHICS API.
;           ⚠ The one-line notes below are what each entry's FIRST FEW
;           INSTRUCTIONS do, nothing more.  They are a reading aid, not names;
;           slots that are still `.long <address>` have not been traced.
;           Only 0x0B, 0x0C and 0x0D are converted and named so far, and those
;           three are real symbols, so the gate checks their addresses.
; ---------------------------------------------------------------------
SWI7_ServiceTable:
	.long 0x00F8EAC7			; F8E9C6  c7 ea f8 00   svc 0x00 -- four setup calls (0xF8EE93/0xF8EB6B/0xF8EB19/0xF8EC0A)
	.long 0x00F8F528			; F8E9CA  28 f5 f8 00   svc 0x01 -- reads Y and AP -- a whole-row address computation
	.long 0x00F8F739			; F8E9CE  39 f7 f8 00   svc 0x02 -- BC = (0x2536)-(0x2532)+1, a Y span
	.long 0x00F8EDB4			; F8E9D2  b4 ed f8 00   svc 0x03 -- drives the controller through XIZ
	.long 0x00F8EE23			; F8E9D6  23 ee f8 00   svc 0x04 -- drives the controller through XIZ
	.long 0x00F8EEBD			; F8E9DA  bd ee f8 00   svc 0x05 -- sets (0x2540) = 1 first, then drives XIX
	.long 0x00F8F039			; F8E9DE  39 f0 f8 00   svc 0x06 -- BC = count, IX += (0x2555): a block op on the current layer
	.long 0x00F8F130			; F8E9E2  30 f1 f8 00   svc 0x07 -- BC = count, IX += (0x2555)
	.long 0x00F8F1C3			; F8E9E6  c3 f1 f8 00   svc 0x08 -- BC = count, IX += (0x2555)
	.long 0x00F8F3A4			; F8E9EA  a4 f3 f8 00   svc 0x09 -- calls slot 0x01 with (0x2532)/(0x2536) swapped
	.long 0x00F8F3E1			; F8E9EE  e1 f3 f8 00   svc 0x0A -- calls slot 0x09, then saves X/Y into (0x255C)
	.long LCD_Svc_0B_PlotPoint	; F8E9F2  b5 ec f8 00   svc 0x0B
	.long LCD_Svc_0C_SetLayersOn	; F8E9F6  b8 f7 f8 00   svc 0x0C
	.long LCD_Svc_0D_SetLayersFlashing	; F8E9FA  01 f8 f8 00   svc 0x0D
	.long 0x00F8F850			; F8E9FE  50 f8 f8 00   svc 0x0E -- drives XIX
	.long 0x00F8FA60			; F8EA02  60 fa f8 00   svc 0x0F -- issues its own SYSTEM SET -- a re-configuration service
	.long 0x00F8FB7E			; F8EA06  7e fb f8 00   svc 0x10 -- issues its own SYSTEM SET -- a re-configuration service
	.long 0x00F8FCB2			; F8EA0A  b2 fc f8 00   svc 0x11 -- drives XIX, reads Y
	.long 0x00F8FE80			; F8EA0E  80 fe f8 00   svc 0x12 -- BC = (0x2536)-(0x2532)+1, a Y span
	.long 0x00F8F475			; F8EA12  75 f4 f8 00   svc 0x13 -- calls slot 0x11 with (0x2532)/(0x2536) swapped
	.long 0x00F8FEBC			; F8EA16  bc fe f8 00   svc 0x14 -- drives XIX, IY = 0
	.long 0x00F900B0			; F8EA1A  b0 00 f9 00   svc 0x15 -- same four setup calls as slot 0x00
	.long 0x00F8F0A3			; F8EA1E  a3 f0 f8 00   svc 0x16 -- BC = count, IX += (0x2555)
	.long 0x00F90118			; F8EA22  18 01 f9 00   svc 0x17 -- BC = count, WA = 8
	.long LCD_Svc_Unimplemented		; F8EA26  c6 ea f8 00   svc 0x18
	.long 0x00F8F28D			; F8EA2A  8d f2 f8 00   svc 0x19 -- BC = count, IX += (0x2555)
	.long 0x00F8F229			; F8EA2E  29 f2 f8 00   svc 0x1A -- BC = count, IX += (0x2555)
	.long 0x00F8F8BD			; F8EA32  bd f8 f8 00   svc 0x1B -- drives XIX, compares (0x2532) with (0x2536)
	.long 0x00F9025E			; F8EA36  5e 02 f9 00   svc 0x1C -- BC = count, WA = 16
	.long 0x00F8F2BF			; F8EA3A  bf f2 f8 00   svc 0x1D -- BC = count, IX += (0x2555)
	.long 0x00F908FF			; F8EA3E  ff 08 f9 00   svc 0x1E -- A = C & 0x0F -- takes a 4-bit argument
	.long 0x00F8F25B			; F8EA42  5b f2 f8 00   svc 0x1F -- BC = count, IX += (0x2555)
	.long 0x00F8F06E			; F8EA46  6e f0 f8 00   svc 0x20 -- BC = count, IX += (0x2555)
	.long 0x00F8F1F7			; F8EA4A  f7 f1 f8 00   svc 0x21 -- BC = count, IX += (0x2555)
	.long 0x00F8F4B2			; F8EA4E  b2 f4 f8 00   svc 0x22 -- same entry shape as slot 0x0A
	.long LCD_Svc_Unimplemented		; F8EA52  c6 ea f8 00   svc 0x23
	.long LCD_Svc_Unimplemented		; F8EA56  c6 ea f8 00   svc 0x24
	.long LCD_Svc_Unimplemented		; F8EA5A  c6 ea f8 00   svc 0x25
	.long LCD_Svc_Unimplemented		; F8EA5E  c6 ea f8 00   svc 0x26
	.long LCD_Svc_Unimplemented		; F8EA62  c6 ea f8 00   svc 0x27
	.long LCD_Svc_Unimplemented		; F8EA66  c6 ea f8 00   svc 0x28
	.long LCD_Svc_Unimplemented		; F8EA6A  c6 ea f8 00   svc 0x29
	.long LCD_Svc_Unimplemented		; F8EA6E  c6 ea f8 00   svc 0x2A
	.long LCD_Svc_Unimplemented		; F8EA72  c6 ea f8 00   svc 0x2B
	.long LCD_Svc_Unimplemented		; F8EA76  c6 ea f8 00   svc 0x2C
	.long LCD_Svc_Unimplemented		; F8EA7A  c6 ea f8 00   svc 0x2D
	.long LCD_Svc_Unimplemented		; F8EA7E  c6 ea f8 00   svc 0x2E
	.long LCD_Svc_Unimplemented		; F8EA82  c6 ea f8 00   svc 0x2F
	.long LCD_Svc_Unimplemented		; F8EA86  c6 ea f8 00   svc 0x30
	.long LCD_Svc_Unimplemented		; F8EA8A  c6 ea f8 00   svc 0x31
	.long LCD_Svc_Unimplemented		; F8EA8E  c6 ea f8 00   svc 0x32
	.long LCD_Svc_Unimplemented		; F8EA92  c6 ea f8 00   svc 0x33
	.long LCD_Svc_Unimplemented		; F8EA96  c6 ea f8 00   svc 0x34
	.long LCD_Svc_Unimplemented		; F8EA9A  c6 ea f8 00   svc 0x35
	.long LCD_Svc_Unimplemented		; F8EA9E  c6 ea f8 00   svc 0x36
	.long LCD_Svc_Unimplemented		; F8EAA2  c6 ea f8 00   svc 0x37
	.long LCD_Svc_Unimplemented		; F8EAA6  c6 ea f8 00   svc 0x38
	.long LCD_Svc_Unimplemented		; F8EAAA  c6 ea f8 00   svc 0x39
	.long LCD_Svc_Unimplemented		; F8EAAE  c6 ea f8 00   svc 0x3A
	.long LCD_Svc_Unimplemented		; F8EAB2  c6 ea f8 00   svc 0x3B
	.long LCD_Svc_Unimplemented		; F8EAB6  c6 ea f8 00   svc 0x3C
	.long LCD_Svc_Unimplemented		; F8EABA  c6 ea f8 00   svc 0x3D
	.long LCD_Svc_Unimplemented		; F8EABE  c6 ea f8 00   svc 0x3E
	.long LCD_Svc_Unimplemented		; F8EAC2  c6 ea f8 00   svc 0x3F

; ---------------------------------------------------------------------
; LCD_Svc_Unimplemented -- the do-nothing service
;
; Called from: SWI7_ServiceTable slots 0x18 and 0x23-0x3F (29 slots)
; Inputs:  none
; Outputs: none
; Notes:   a single RET.  Its address is what identifies the unused slots, and
;          the fact that the table's tail is entirely filled with it is what
;          shows the table really is 64 entries long rather than 35.
; ---------------------------------------------------------------------
LCD_Svc_Unimplemented:
	ret					; F8EAC6  0e
	.incbin "original_ROMs/wsa1_prom_a.ic12", 0x00EAC7, 0x0001EE

; ==============================================================================
; 0xF8ECB5-0xF8EDB3 -- SWI7 service 0x0B: set one pixel
; ==============================================================================

; ---------------------------------------------------------------------
; LCD_Svc_0B_PlotPoint -- SWI7 service 0x0B: set the pixel at (0x2530),(0x2532)
;
; Called from: SWI7_ServiceTable slot 0x0B
; Inputs:  (0x2530) = X, (0x2532) = Y, both 16-bit; (0x2555) = the base address
;          of the layer being drawn into; (0x2557) = AP, bytes per line.
; Outputs: the pixel is set (OR, never cleared).  (0x2550)/(0x2552) are left
;          holding the X and Y that were used.  WA, BC, DE, HL, XHL clobbered.
; Notes:   the address arithmetic is the identification, and it is arithmetic
;          rather than a guess: display address = Y*AP + X/8 + base, and the bit
;          within that byte is X mod 8 used as an index into an eight-entry mask
;          table that holds exactly 80 40 20 10 08 04 02 01.  A 1-bit-per-pixel,
;          MSB-leftmost framebuffer -- which is what the SED1330 SYSTEM SET at
;          LCD_Init_SED1330 programmes (FX = 8 pixels per cell, AP = 40 bytes per
;          line, 240 lines: 320 x 240).
; ---------------------------------------------------------------------
LCD_Svc_0B_PlotPoint:
	calr 0x01db                                   ; F8ECB5  1e db 01   -> 0xF8EE93, the setup every graphics service starts with
	calr 0xfeb0                                   ; F8ECB8  1e b0 fe   -> 0xF8EB6B
	ldw_d16 wa, (0x2530)                          ; F8ECBB  d1 30 25 20   (0x2530) = the caller's X
	stda16 (0x2550), wa                           ; F8ECBF  f1 50 25 50
	ldw_d16 wa, (0x2532)                          ; F8ECC3  d1 32 25 20   (0x2532) = the caller's Y
	stda16 (0x2552), wa                           ; F8ECC7  f1 52 25 50
	calr LCD_PlotPointAt                                 ; F8ECCB  1e 01 00
	ret                                           ; F8ECCE  0e
LCD_PlotPointAt:

; ---------------------------------------------------------------------
; LCD_PlotPointAt -- the read-modify-write that actually sets the bit
;
; Called from: LCD_Svc_0B_PlotPoint (0xF8ECCB).  Others may reach it too --
;          not yet traced.
; Inputs:  (0x2550) = X, (0x2552) = Y, (0x2555) = layer base, (0x2557) = AP
; Outputs: one display byte updated
; Notes:   the controller has no read-modify-write, so this is CSRW / MREAD /
;          CSRW / MWRITE -- the second CSRW exists only because MREAD advances
;          the cursor.  Every access is preceded by the BUSY poll unless bit 0 of
;          (0xC6) says the display is off; see LCD_Svc_0C_DisplayOnOff, which is
;          what sets that bit.
; ---------------------------------------------------------------------
	ldw_d16 wa, (0x2552)                          ; F8ECCF  d1 52 25 20   WA = Y
	ldw_d16 bc, (0x2557)                          ; F8ECD3  d1 57 25 21   BC = AP, the bytes per line the SYSTEM SET programmed (40)
	mul xwa, xbc                                  ; F8ECD7  d9 40   XWA = Y * AP
	ld HL,WA                                      ; F8ECD9  d8 8b
	ldw_d16 wa, (0x2550)                          ; F8ECDB  d1 50 25 20   WA = X
	extz XWA                                      ; F8ECDF  e8 12
	ldw bc, 0x08                                  ; F8ECE1  31 08 00
	div xwa, xbc                                  ; F8ECE4  d9 50   XWA = X/8, QWA = X mod 8
	ld DE,QWA                                     ; F8ECE6  d7 e2 8a   DE = X mod 8 -- which bit inside the byte
	add WA,HL                                     ; F8ECE9  db 80   WA = Y*AP + X/8
	m_add_rm MW16, 0x2555, r0                     ; F8ECEB  d1 55 25 80   + (0x2555), the layer's base address -> the display-RAM address
	bit_dd8 0x00, 0xc6                            ; F8ECEF  f0 c6 c8   (0xC6) bit 0 set = the display is off, do not wait for BUSY
	jr nz, .LF8ECFB                               ; F8ECF2  6e 07
.LF8ECF4:
	m_bit 6, MD24, 0x790000                       ; F8ECF4  f2 00 00 79 ce
	jr nz, .LF8ECF4                               ; F8ECF9  6e f9
.LF8ECFB:
	stib_da (0x790001), 0x46                      ; F8ECFB  f2 01 00 79 00 46   CSRW
	bit_dd8 0x00, 0xc6                            ; F8ED01  f0 c6 c8
	jr nz, .LF8ED0D                               ; F8ED04  6e 07
.LF8ED06:
	m_bit 6, MD24, 0x790000                       ; F8ED06  f2 00 00 79 ce
	jr nz, .LF8ED06                               ; F8ED0B  6e f9
.LF8ED0D:
	stb_da (0x790000), a                          ; F8ED0D  f2 00 00 79 41   address low
	bit_dd8 0x00, 0xc6                            ; F8ED12  f0 c6 c8
	jr nz, .LF8ED1E                               ; F8ED15  6e 07
.LF8ED17:
	m_bit 6, MD24, 0x790000                       ; F8ED17  f2 00 00 79 ce
	jr nz, .LF8ED17                               ; F8ED1C  6e f9
.LF8ED1E:
	stb_da (0x790000), w                          ; F8ED1E  f2 00 00 79 40   address high
	bit_dd8 0x00, 0xc6                            ; F8ED23  f0 c6 c8
	jr nz, .LF8ED2F                               ; F8ED26  6e 07
.LF8ED28:
	m_bit 6, MD24, 0x790000                       ; F8ED28  f2 00 00 79 ce
	jr nz, .LF8ED28                               ; F8ED2D  6e f9
.LF8ED2F:
	stib_da (0x790001), 0x43                      ; F8ED2F  f2 01 00 79 00 43   MREAD -- and it auto-increments the cursor, which is why
	bit_dd8 0x00, 0xc6                            ; F8ED35  f0 c6 c8
	jr nz, .LF8ED41                               ; F8ED38  6e 07
.LF8ED3A:
	m_bit 6, MD24, 0x790000                       ; F8ED3A  f2 00 00 79 ce
	jr nz, .LF8ED3A                               ; F8ED3F  6e f9
.LF8ED41:
	ldb_da c, (0x790001)                          ; F8ED41  c2 01 00 79 23   C = the byte that is already there
	bit_dd8 0x00, 0xc6                            ; F8ED46  f0 c6 c8
	jr nz, .LF8ED52                               ; F8ED49  6e 07
.LF8ED4B:
	m_bit 6, MD24, 0x790000                       ; F8ED4B  f2 00 00 79 ce
	jr nz, .LF8ED4B                               ; F8ED50  6e f9
.LF8ED52:
	stib_da (0x790001), 0x46                      ; F8ED52  f2 01 00 79 00 46   CSRW again, to undo the MREAD auto-increment
	bit_dd8 0x00, 0xc6                            ; F8ED58  f0 c6 c8
	jr nz, .LF8ED64                               ; F8ED5B  6e 07
.LF8ED5D:
	m_bit 6, MD24, 0x790000                       ; F8ED5D  f2 00 00 79 ce
	jr nz, .LF8ED5D                               ; F8ED62  6e f9
.LF8ED64:
	stb_da (0x790000), a                          ; F8ED64  f2 00 00 79 41
	bit_dd8 0x00, 0xc6                            ; F8ED69  f0 c6 c8
	jr nz, .LF8ED75                               ; F8ED6C  6e 07
.LF8ED6E:
	m_bit 6, MD24, 0x790000                       ; F8ED6E  f2 00 00 79 ce
	jr nz, .LF8ED6E                               ; F8ED73  6e f9
.LF8ED75:
	stb_da (0x790000), w                          ; F8ED75  f2 00 00 79 40
	ld XHL,0x00f8edac                             ; F8ED7A  43 ac ed f8 00   the single-bit mask table below
	.byte 0xc3, 0x07, 0xec, 0xe8, 0xe3            ; F8ED7F  c3 07 ec e8 e3   or C,(XHL+DE) -- set the one bit.  llvm-mc has no spelling for the
	nop                                           ; F8ED84  00
	nop                                           ; F8ED85  00
	nop                                           ; F8ED86  00
	nop                                           ; F8ED87  00
	bit_dd8 0x00, 0xc6                            ; F8ED88  f0 c6 c8
	jr nz, .LF8ED94                               ; F8ED8B  6e 07
.LF8ED8D:
	m_bit 6, MD24, 0x790000                       ; F8ED8D  f2 00 00 79 ce
	jr nz, .LF8ED8D                               ; F8ED92  6e f9
.LF8ED94:
	stib_da (0x790001), 0x42                      ; F8ED94  f2 01 00 79 00 42   MWRITE
	bit_dd8 0x00, 0xc6                            ; F8ED9A  f0 c6 c8
	jr nz, .LF8EDA6                               ; F8ED9D  6e 07
.LF8ED9F:
	m_bit 6, MD24, 0x790000                       ; F8ED9F  f2 00 00 79 ce
	jr nz, .LF8ED9F                               ; F8EDA4  6e f9
.LF8EDA6:
	stb_da (0x790000), c                          ; F8EDA6  f2 00 00 79 43   the modified byte goes back
	ret                                           ; F8EDAB  0e

; ---------------------------------------------------------------------
; LCD_BitMaskTable -- 8 x byte, the single-bit masks
;
; Read by:  0xF8ED7A/0xF8ED7F, indexed by DE = X mod 8.
; Layout:   index 0 -> 0x80 ... index 7 -> 0x01, i.e. the leftmost pixel of a
;           byte is its most significant bit.
; ---------------------------------------------------------------------
LCD_BitMaskTable:
	.byte 0x80, 0x40, 0x20, 0x10, 0x08, 0x04, 0x02, 0x01	; F8EDAC
	.incbin "original_ROMs/wsa1_prom_a.ic12", 0x00EDB4, 0x000A04

; ==============================================================================
; 0xF8F7B8-0xF8F84F -- SWI7 services 0x0C and 0x0D: which layers are visible
; ==============================================================================
;
; Both write the SED1330 DISP ON parameter byte, whose four 2-bit fields are
; FC (cursor), FP1, FP2/4, FP3, with 00 = off, 01 = on, 10 = flash at fFR/32,
; 11 = flash at fFR/4 (MAME, src/devices/video/sed1330.cpp:410-448).  0x0C
; writes 01 into the selected layers, 0x0D writes 10 -- on, versus blinking.

; ---------------------------------------------------------------------
; LCD_Svc_0C_SetLayersOn -- SWI7 service 0x0C: exactly these layers, steady on
;
; Called from: SWI7_ServiceTable slot 0x0C, and directly by
;          NMI_PowerFail_SaveAndHalt with A = 0x0C, C = 0
; Inputs:  C bits 0/1/2 select display layers 1/2/3
; Outputs: the DISP ON byte is rebuilt from scratch -- a layer whose bit is
;          clear in C is turned OFF -- and remembered in (0x2559).  If the whole
;          byte comes out zero, bit 0 of (0xC6) is SET, which is what makes the
;          rest of the driver stop waiting for BUSY; any non-zero value clears it
;          again.
; Notes:   the NMI calls this with C = 0, so the power-fail path's first act is
;          to blank the panel and put the driver into its no-wait mode.  That is
;          also the evidence for what bit 0 of (0xC6) means.
; ---------------------------------------------------------------------
LCD_Svc_0C_SetLayersOn:
	ldb_d8 a, (0x2559)                            ; F8F7B8  c1 59 25 21   the last DISP byte sent
	and A,0x03                                    ; F8F7BC  c9 cc 03   keep bits[1:0], the cursor field; every layer field starts OFF
	bit 0x00,C                                    ; F8F7BF  cb 33 00
	jr z, .LF8F7C7                                ; F8F7C2  66 03
	or A,0x04                                     ; F8F7C4  c9 ce 04   layer 1 field = 01 SOLID
.LF8F7C7:
	bit 0x01,C                                    ; F8F7C7  cb 33 01
	jr z, .LF8F7CF                                ; F8F7CA  66 03
	or A,0x10                                     ; F8F7CC  c9 ce 10   layer 2 field = 01 SOLID
.LF8F7CF:
	bit 0x02,C                                    ; F8F7CF  cb 33 02
	jr z, .LF8F7D7                                ; F8F7D2  66 03
	or A,0x40                                     ; F8F7D4  c9 ce 40   layer 3 field = 01 SOLID
.LF8F7D7:
	stib_da (0x790001), 0x59                      ; F8F7D7  f2 01 00 79 00 59   DISP ON
	bit_dd8 0x00, 0xc6                            ; F8F7DD  f0 c6 c8
	jr nz, .LF8F7E9                               ; F8F7E0  6e 07
.LF8F7E2:
	m_bit 6, MD24, 0x790000                       ; F8F7E2  f2 00 00 79 ce
	jr nz, .LF8F7E2                               ; F8F7E7  6e f9
.LF8F7E9:
	stb_da (0x790000), a                          ; F8F7E9  f2 00 00 79 41
	stb_d8 (0x2559), a                            ; F8F7EE  f1 59 25 41
	and A,A                                       ; F8F7F2  c9 c1   nothing on at all?
	jr nz, .LF8F7FC                               ; F8F7F4  6e 06
	m_or_mi8 MB8, 0xc6, 0x01                      ; F8F7F6  c0 c6 3e 01   then stop polling BUSY -- the panel is dark
	jr .LF8F800                                   ; F8F7FA  68 04
.LF8F7FC:
	m_and_mi8 MB8, 0xc6, 0xfe                     ; F8F7FC  c0 c6 3c fe   otherwise resume polling
.LF8F800:
	ret                                           ; F8F800  0e

; ---------------------------------------------------------------------
; LCD_Svc_0D_SetLayersFlashing -- SWI7 service 0x0D: make these layers blink
;
; Called from: SWI7_ServiceTable slot 0x0D
; Inputs:  C bits 0/1/2 select display layers 1/2/3
; Outputs: each selected layer's field becomes 10 (flash at fFR/32); layers not
;          selected keep whatever they had, so unlike service 0x0C this is a
;          modify, not a rebuild.  (0x2559) updated.
; Notes:   it does NOT touch (0xC6): a blinking layer is still a live panel.
; ---------------------------------------------------------------------
LCD_Svc_0D_SetLayersFlashing:
	ldb_d8 a, (0x2559)                            ; F8F801  c1 59 25 21
	bit 0x00,C                                    ; F8F805  cb 33 00
	jr z, .LF8F810                                ; F8F808  66 06
	and A,0xf3                                    ; F8F80A  c9 cc f3   layer 1 field = 10 FLASH fFR/32
	or A,0x08                                     ; F8F80D  c9 ce 08
.LF8F810:
	bit 0x01,C                                    ; F8F810  cb 33 01
	jr z, .LF8F81B                                ; F8F813  66 06
	and A,0xcf                                    ; F8F815  c9 cc cf   layer 2 field = 10 FLASH fFR/32
	or A,0x20                                     ; F8F818  c9 ce 20
.LF8F81B:
	bit 0x02,C                                    ; F8F81B  cb 33 02
	jr z, .LF8F826                                ; F8F81E  66 06
	and A,0x3f                                    ; F8F820  c9 cc 3f   layer 3 field = 10 FLASH fFR/32
	or A,0x80                                     ; F8F823  c9 ce 80
.LF8F826:
	bit_dd8 0x00, 0xc6                            ; F8F826  f0 c6 c8
	jr nz, .LF8F832                               ; F8F829  6e 07
.LF8F82B:
	m_bit 6, MD24, 0x790000                       ; F8F82B  f2 00 00 79 ce
	jr nz, .LF8F82B                               ; F8F830  6e f9
.LF8F832:
	stib_da (0x790001), 0x59                      ; F8F832  f2 01 00 79 00 59   DISP ON
	nop                                           ; F8F838  00
	nop                                           ; F8F839  00
	bit_dd8 0x00, 0xc6                            ; F8F83A  f0 c6 c8
	jr nz, .LF8F846                               ; F8F83D  6e 07
.LF8F83F:
	m_bit 6, MD24, 0x790000                       ; F8F83F  f2 00 00 79 ce
	jr nz, .LF8F83F                               ; F8F844  6e f9
.LF8F846:
	stb_da (0x790000), a                          ; F8F846  f2 00 00 79 41
	stb_d8 (0x2559), a                            ; F8F84B  f1 59 25 41
	ret                                           ; F8F84F  0e
	.incbin "original_ROMs/wsa1_prom_a.ic12", 0x00F850, 0x015BC8

; ==============================================================================
; 0xFA5418-0xFA5503 -- serial channel 0 = the MIDI port: the two interrupts
; ==============================================================================
;
; That SC0 is MIDI is settled by traffic rather than by a register setting: the
; transmit handler below writes 0xFC, 0xF8, 0xFE, 0xFA and 0xFB into SC0BUF and
; nothing else in any of the four images writes those bytes to a UART.  They are
; the five MIDI System Real Time messages -- STOP, TIMING CLOCK, ACTIVE SENSING,
; START, CONTINUE -- and the receive handler splits incoming bytes on exactly
; the MIDI boundaries (bit 7 = status, 0xF8 and above = real time, 0xF7 = end of
; exclusive).
;
; ★ (0xA0) IS THE REAL-TIME TRANSMIT REQUEST BITMAP, and this routine is what
;   assigns its bits their meaning:
;       bit 0 -> 0xF8 TIMING CLOCK      bit 1 -> 0xFA START
;       bit 2 -> 0xFB CONTINUE          bit 3 -> 0xFC STOP
;       bit 4 -> 0xFE ACTIVE SENSING
;   INTT1_Tick sets bit 4 (0xF82D3F) and bit 3 (0xF82D92) and bit 0 (0xF82DC0);
;   the sequencer tick at 0xF82F7D sets bit 1.  The `or (0xA0),n; call 0xF40724`
;   idiom noted there is therefore "queue this MIDI real-time byte".
;
; ★ ACTIVE SENSING, both directions, and what it says about the tick rate:
;     SEND    INTT1_Tick wraps a 0..0x86 counter, so bit 4 is requested every
;             135 timer-1 ticks.
;     TIMEOUT bit 7 of (0x9E) is set when a 0xFE arrives (0xFA5509); while it is
;             set INTT1_Tick counts (0x9C) up and gives up at 0xA5, i.e. after
;             166 ticks.  (0x9C) is zeroed at 0xFA54AE on EVERY received byte.
;   At the 488.28 Hz that notes/FINDINGS-system-clock.md derives, that is send
;   every 277 ms and give up after 340 ms -- one either side of MIDI 1.0's
;   300 ms rule, which is what a correct implementation looks like.  ⚠ This is a
;   CONSISTENCY CHECK, not a fourth lever on fc: the window is wide enough that
;   24 MHz would also put the timeout on the right side of 300 ms (though not
;   the send interval).  The levers are in that note; do not re-derive fc here.
;
; ---------------------------------------------------------------------
; MIDI_RX_ErrorReset -- the receive-error path
;
; Called from: MIDI_RX_Byte (0xFA549E), when SC0CR bits 2-4 are not all clear
; Inputs:  SC0CR error flags
; Outputs: SC0BUF read (which is how the error is cleared), running status
;          (0x9A) dropped, (0x9E) masked with 0xBD and bit 3 set, (0xA9) zeroed,
;          the 16-bit counter at (0x0931) incremented.  Returns with RETI.
; Notes:   the parser is deliberately NOT run, so a byte received with a framing
;          or overrun error cannot enter the MIDI state machine.
; ---------------------------------------------------------------------
MIDI_RX_ErrorReset:
	pushw wa                                      ; FA5418  28
	ld_sd8b a, SC0BUF                               ; FA5419  c0 50 21   read SC0BUF to clear the error
	ldio 0x9a, 0x00                               ; FA541C  08 9a 00
	m_and_mi8 MB8, 0x9e, 0xbd                     ; FA541F  c0 9e 3c bd
	set_dd8 0x03, 0x9e                            ; FA5423  f0 9e bb   (0x9E) bit 3 = 'the link had an error'
	ldio 0xa9, 0x00                               ; FA5426  08 a9 00
	incdi8 0x01, (0x0931)                         ; FA5429  c1 31 09 61   (0x0931) = an error counter, 16-bit
	popw wa                                       ; FA542D  48
	reti                                          ; FA542E  07

; ---------------------------------------------------------------------
; MIDI_TX_Ready -- INTTX0: SC0BUF has room, send the next MIDI byte
;
; Called from: vector slot 0x64 (0xFFFF64 holds 0x00F40718, a prom_b thunk whose
;          body is `jp 0xFA542F`)
; Inputs:  (0xA0), the real-time request bitmap described above
; Outputs: one byte written to SC0BUF and its request bit cleared; or, if no
;          request bit is set, one byte pulled from the output queue by the
;          prom_b routine at 0xF41DF0 (which returns 0xFFFF for "empty").
; Notes:   the priority order is fixed and is NOT the bit order: clock, active
;          sensing, start, continue, stop.  Timing clock first is the right
;          choice for a sequencer -- it is the one message whose jitter is
;          audible.
;
;          The tail is the "nothing left to send" hand-off: when no request bit
;          is set AND 0xF41DFC reports the queue empty, (0x77) is set to 0xFD.
;          (0x77) also takes 0xDD from the work poster at 0xFA590F, so it is a
;          one-byte mailbox to the foreground, not a UART register.
; ---------------------------------------------------------------------
MIDI_TX_Ready:
	pushw wa                                      ; FA542F  28
	ld_sd8b a, 0xa0                               ; FA5430  c0 a0 21   the pending-transmit bitmap; INTT1 and INTTR4 set its bits
	bit 0x00,A                                    ; FA5433  c9 33 00
	jr nz, .LFA5454                               ; FA5436  6e 1c
	bit 0x04,A                                    ; FA5438  c9 33 04
	jr nz, .LFA545C                               ; FA543B  6e 1f
	bit 0x01,A                                    ; FA543D  c9 33 01
	jr nz, .LFA5464                               ; FA5440  6e 22
	bit 0x02,A                                    ; FA5442  c9 33 02
	jr nz, .LFA546C                               ; FA5445  6e 25
	bit 0x03,A                                    ; FA5447  c9 33 03
	jr z, .LFA5474                                ; FA544A  66 28
	res_dd8 0x03, 0xa0                            ; FA544C  f0 a0 b3
	ldio SC0BUF, 0xfc                               ; FA544F  08 50 fc   bit 3 -> 0xFC  MIDI System Real Time STOP
	jr .LFA5481                                   ; FA5452  68 2d
.LFA5454:
	res_dd8 0x00, 0xa0                            ; FA5454  f0 a0 b0
	ldio SC0BUF, 0xf8                               ; FA5457  08 50 f8   bit 0 -> 0xF8  MIDI System Real Time TIMING CLOCK
	jr .LFA5481                                   ; FA545A  68 25
.LFA545C:
	res_dd8 0x04, 0xa0                            ; FA545C  f0 a0 b4
	ldio SC0BUF, 0xfe                               ; FA545F  08 50 fe   bit 4 -> 0xFE  MIDI System Real Time ACTIVE SENSING
	jr .LFA5481                                   ; FA5462  68 1d
.LFA5464:
	res_dd8 0x01, 0xa0                            ; FA5464  f0 a0 b1
	ldio SC0BUF, 0xfa                               ; FA5467  08 50 fa   bit 1 -> 0xFA  MIDI System Real Time START
	jr .LFA5481                                   ; FA546A  68 15
.LFA546C:
	res_dd8 0x02, 0xa0                            ; FA546C  f0 a0 b2
	ldio SC0BUF, 0xfb                               ; FA546F  08 50 fb   bit 2 -> 0xFB  MIDI System Real Time CONTINUE
	jr .LFA5481                                   ; FA5472  68 0d
.LFA5474:
	call 0xf41df0                                 ; FA5474  1d f0 1d f4   no real-time byte pending: pull one from the output queue
	cp WA,0xffff                                  ; FA5478  d8 cf ff ff   0xFFFF = the queue is empty
	jr z, .LFA5481                                ; FA547C  66 03
	st_dd8b a, SC0BUF                               ; FA547E  f0 50 41
.LFA5481:
	ld_sd8b a, 0xa0                               ; FA5481  c0 a0 21
	and A,0x1f                                    ; FA5484  c9 cc 1f   any of the five real-time bits still set?
	jr nz, .LFA5494                               ; FA5487  6e 0b
	call 0xf41dfc                                 ; FA5489  1d fc 1d f4
	and WA,WA                                     ; FA548D  d8 c0
	jr nz, .LFA5494                               ; FA548F  6e 03
	ldio 0x77, 0xfd                               ; FA5491  08 77 fd   queue empty and nothing pending -> (0x77) = 0xFD
.LFA5494:
	popw wa                                       ; FA5494  48
	reti                                          ; FA5495  07

; ---------------------------------------------------------------------
; MIDI_RX_Byte -- INTRX0: a byte arrived on the MIDI input
;
; Called from: vector slot 0x60 (0xFFFF60 holds 0x00F40714, a prom_b thunk whose
;          body is `jp 0xFA5496`)
; Inputs:  SC0CR (error flags), SC0BUF (the byte)
; Outputs: the byte is dispatched into one of three paths and the receive
;          inactivity counter (0x9C) is restarted.  All seven 32-bit registers
;          are saved, so the parser it calls may use any of them.
; Notes:   the three paths, and what picks them:
;            bit 7 clear          -> a DATA byte      -> 0xFA5763
;            0x80-0xF7            -> a STATUS byte    -> handled inline:
;                                    it becomes the running status in (0x9A),
;                                    and 0xF7 (END OF EXCLUSIVE) closes an
;                                    in-progress SysEx through 0xF41E3C
;            0xF8-0xFF            -> SYSTEM REAL TIME -> 0xFA5504
;          (0xA9) is the SysEx state: bit 0 armed, bit 1 in-message, bit 5 seen.
;          ⚠ those three bit meanings are read off this routine's branches only
;          and are not corroborated elsewhere yet.
; ---------------------------------------------------------------------
MIDI_RX_Byte:
	pushw wa                                      ; FA5496  28
	ld_sd8b a, SC0CR                               ; FA5497  c0 51 21   SC0CR bits 2-4 are the receive error flags
	and A,0x1c                                    ; FA549A  c9 cc 1c
	popw wa                                       ; FA549D  48
	jrl nz, MIDI_RX_ErrorReset                              ; FA549E  7e 77 ff   any error -> the error path above, which does not run the parser
	push XWA                                      ; FA54A1  38
	push XBC                                      ; FA54A2  39
	push XDE                                      ; FA54A3  3a
	push XHL                                      ; FA54A4  3b
	push XIX                                      ; FA54A5  3c
	push XIY                                      ; FA54A6  3d
	push XIZ                                      ; FA54A7  3e
	calr 0x03d9                                   ; FA54A8  1e d9 03   -> 0xFA5884
	ld_sd8b a, SC0BUF                               ; FA54AB  c0 50 21   the received byte
	ldio 0x9c, 0x00                               ; FA54AE  08 9c 00   restart the receive-inactivity timer INTT1 counts
	bit 0x07,A                                    ; FA54B1  c9 33 07   bit 7 set = a status byte
	jr z, .LFA54F6                                ; FA54B4  66 40
	cp A,0xf7                                     ; FA54B6  c9 cf f7   0xF8-0xFF are System Real Time
	jr ule, .LFA54C0                              ; FA54B9  63 05
	calr 0x46                                     ; FA54BB  1e 46 00   -> 0xFA5504, the real-time handler
	jr .LFA54F9                                   ; FA54BE  68 39
.LFA54C0:
	st_dd8b a, 0x9a                               ; FA54C0  f0 9a 41   (0x9A) = running status
	m_and_mi8 MB8, 0x9e, 0xbd                     ; FA54C3  c0 9e 3c bd
	bit_dd8 0x00, 0xa9                            ; FA54C7  f0 a9 c8
	jr z, .LFA54F9                                ; FA54CA  66 2d
	bit_dd8 0x01, 0xa9                            ; FA54CC  f0 a9 c9
	jr z, .LFA54E5                                ; FA54CF  66 14
	cp A,0xf7                                     ; FA54D1  c9 cf f7
	jr nz, .LFA54EE                               ; FA54D4  6e 18
	bit_dd8 0x05, 0xa9                            ; FA54D6  f0 a9 cd
	jr nz, .LFA54E5                               ; FA54D9  6e 0a
	pushw wa                                      ; FA54DB  28
	call 0xf41e3c                                 ; FA54DC  1d 3c 1e f4
	inc 2,XSP                                     ; FA54E0  ef 62
	ldio 0xa9, 0x04                               ; FA54E2  08 a9 04
.LFA54E5:
	ldio 0x9a, 0x00                               ; FA54E5  08 9a 00
	m_and_mi8 MB8, 0xa9, 0xcc                     ; FA54E8  c0 a9 3c cc
	jr .LFA54F9                                   ; FA54EC  68 0b
.LFA54EE:
	ldio 0xa9, 0x10                               ; FA54EE  08 a9 10
	ldio 0x9a, 0x00                               ; FA54F1  08 9a 00
	jr .LFA54F9                                   ; FA54F4  68 03
.LFA54F6:
	calr 0x026a                                   ; FA54F6  1e 6a 02   -> 0xFA5763, the data-byte path
.LFA54F9:
	calr 0x03a5                                   ; FA54F9  1e a5 03   -> 0xFA58A1
	pop XIZ                                       ; FA54FC  5e
	pop XIY                                       ; FA54FD  5d
	pop XIX                                       ; FA54FE  5c
	pop XHL                                       ; FA54FF  5b
	pop XDE                                       ; FA5500  5a
	pop XBC                                       ; FA5501  59
	pop XWA                                       ; FA5502  58
	reti                                          ; FA5503  07

; ==============================================================================
; 0xFA5504-0xFA570B -- the MIDI System Real Time receive handler
; ==============================================================================
;
; ★ THIS ROUTINE DEFINES THE TRANSPORT STATE BYTES.  (0x94), (0x95) and (0x96)
;   are written here and in INTTR4_SequencerTick and INTT1_Tick, and putting the
;   three together gives the bit layout -- from the code, not from a guess:
;       bit 0  0x01  START pending / just started
;       bit 2  0x04  RUNNING          (every "is it going?" test is `bit 2`)
;       bit 3  0x08  STOP pending
;       bit 4  0x10  STOPPED
;   and the values actually written are 0x01 (start), 0x06 (running: bits 1+2),
;   0x0C, 0x10 (stopped), 0x08 and 0x86.  Bits 1, 5 and 7 are read in
;   INTT1_Tick but never assigned a meaning by anything traced so far.
;
; ★ FOUR TICKS PER MIDI CLOCK, again.  0xFA55A1 does `and (0x93),0xFC` then
;   `inc 4,(0x93)`: each incoming 0xF8 advances a transport by exactly 4 of the
;   96-per-beat ticks, and 96 / 24 = 4.  INTTR4_SequencerTick derives the same
;   constant from the other direction, by emitting a clock every 4th tick.
;
; ★ THE TEMPO TRACKER at MIDI_Clock_SetTempo is lever B of
;   notes/FINDINGS-system-clock.md.  Do not re-derive fc here; that note owns the
;   argument, including why the firmware's 1750 differs from the predicted 1792
;   by 2.3%.  What this conversion adds is the two clamps' meaning:
;       (0xA1) > 0x70   -> TREG5 = 0x4735.  With TREG5 = 140e6/(64*BPM) that is
;                          120.0 BPM exactly -- the "no clock has arrived for a
;                          long time" fallback tempo.
;       (0xA1) <= 4     -> TREG5 = 0x1C7B = 300.0 BPM exactly -- the fastest
;                          tempo the machine will follow.
;   Two round numbers falling out of two hex constants is a good sign the
;   TREG5-to-BPM formula in that note is right.
;
; ---------------------------------------------------------------------
; MIDI_RT_Received -- dispatch one System Real Time byte (0xF8-0xFF)
;
; Called from: MIDI_RX_Byte (0xFA54BB)
; Inputs:  A = the byte
; Outputs: depends on the byte -- see below.  D is used as a scratch copy of A.
; Notes:   the gates it applies before doing anything, in order:
;            A == 0xFE            -> set (0x9E) bit 7 and return
;            (0x0925) bit 0 set   -> ignore
;            A >= 0xFD            -> ignore (0xFD is undefined; 0xFF is RESET)
;            (0x2094) bit 6 set   -> ignore
;            (0xA9) & 3 non-zero  -> ignore (a SysEx is in progress)
;            (0x7F32) bit 2 clear -> MIDI_RT_ExternalOff, the reduced handler
;          then 0xF8 drives the tempo tracker and advances the transports, 0xFA
;          rewinds and starts them, 0xFB resumes them and 0xFC stops them.
; ---------------------------------------------------------------------
MIDI_RT_Received:
	cp A,0xfe                                     ; FA5504  c9 cf fe   0xFE ACTIVE SENSING: arm the receive-inactivity timeout
	jr nz, MIDI_RT_NotSensing                               ; FA5507  6e 04
	set_dd8 0x07, 0x9e                            ; FA5509  f0 9e bf   (0x9E) bit 7 -- INTT1_Tick counts (0x9C) while this is set
MIDI_RT_Ignore:
	ret                                           ; FA550C  0e
MIDI_RT_NotSensing:
	m_bit 0, MD16, 0x0925                         ; FA550D  f1 25 09 c8
	jr nz, MIDI_RT_Ignore                               ; FA5511  6e f9
	cp A,0xfd                                     ; FA5513  c9 cf fd   0xFD is undefined in MIDI 1.0; 0xFE/0xFF handled elsewhere
	jr nc, MIDI_RT_Ignore                               ; FA5516  6f f4
	m_bit 6, MD16, 0x2094                         ; FA5518  f1 94 20 ce
	jr nz, MIDI_RT_Ignore                               ; FA551C  6e ee
	ld D,A                                        ; FA551E  c9 8c   D = the real-time byte
	ld_sd8b a, 0xa9                               ; FA5520  c0 a9 21
	and A,0x03                                    ; FA5523  c9 cc 03
	jr nz, MIDI_RT_Ignore                               ; FA5526  6e e4
	m_bit 2, MD16, 0x7f32                         ; FA5528  f1 32 7f ca   the same mode bit INTTR4_SequencerTick branches on
	jrl z, MIDI_RT_ExternalOff                               ; FA552C  76 45 01
	cp D,0xf8                                     ; FA552F  cc cf f8   0xF8 TIMING CLOCK
	jr nz, MIDI_RT_NotClock                               ; FA5532  6e 2e
	m_bit 5, MD16, 0x34d0                         ; FA5534  f1 d0 34 cd
	jr z, MIDI_Clock_SetTempo                                ; FA5538  66 04
	incdi8 0x01, (0x091e)                         ; FA553A  c1 1e 09 61
MIDI_Clock_SetTempo:
	ld_sd8b a, 0xa1                               ; FA553E  c0 a1 21   (0xA1) = timer-1 ticks since the previous clock
	cp A,0x70                                     ; FA5541  c9 cf 70   more than 0x70 ticks -> the clock has stopped: fall back
	jr ugt, .LFA5559                              ; FA5544  6b 13
	cps a, 0x04                                   ; FA5546  c9 dc   4 or fewer -> faster than the tempo range allows: clamp
	jr ugt, .LFA554F                              ; FA5548  6b 05
	ldw wa, 0x1c7b                                ; FA554A  30 7b 1c
	jr .LFA555C                                   ; FA554D  68 0d
.LFA554F:
	extz XWA                                      ; FA554F  e8 12
	xor W,W                                       ; FA5551  c8 d0
	muls WA,0x06d6                                ; FA5553  d8 09 d6 06
	jr .LFA555C                                   ; FA5557  68 03
.LFA5559:
	ldw wa, 0x4735                                ; FA5559  30 35 47
.LFA555C:
	st_dd8w wa, 0x32                              ; FA555C  f0 32 50
	ldio 0xa1, 0x00                               ; FA555F  08 a1 00
MIDI_RT_NotClock:
	ld_sd8b a, 0x95                               ; FA5562  c0 95 21
	pushw wa                                      ; FA5565  28
	and A,0x15                                    ; FA5566  c9 cc 15
	popw wa                                       ; FA5569  48
	jrl z, .LFA55DC                               ; FA556A  76 6f 00
	cp D,0xf8                                     ; FA556D  cc cf f8
	jr nz, .LFA55C1                               ; FA5570  6e 4f
	bit 0x00,A                                    ; FA5572  c9 33 00
	jr z, .LFA5584                                ; FA5575  66 0d
	ldio 0x95, 0x06                               ; FA5577  08 95 06
	bit_dd8 0x00, 0x96                            ; FA557A  f0 96 c8
	jr z, .LFA5582                                ; FA557D  66 03
	ldio 0x96, 0x06                               ; FA557F  08 96 06
.LFA5582:
	jr .LFA55C1                                   ; FA5582  68 3d
.LFA5584:
	bit 0x02,A                                    ; FA5584  c9 33 02
	jr z, .LFA559C                                ; FA5587  66 13
	m_and_mi8 MB8, 0x8d, 0xfc                     ; FA5589  c0 8d 3c fc
	m_inc 4, MB8, 0x8d                            ; FA558D  c0 8d 64
	m_cp_mi8 MB8, 0x8d, 0x60                      ; FA5590  c0 8d 3f 60
	jr nz, .LFA559C                               ; FA5594  6e 06
	ldio 0x8d, 0x00                               ; FA5596  08 8d 00
	m_inc 1, MW8, 0x8e                            ; FA5599  d0 8e 61
.LFA559C:
	bit_dd8 0x02, 0x96                            ; FA559C  f0 96 ca
	jr z, .LFA55C1                                ; FA559F  66 20
	m_and_mi8 MB8, 0x93, 0xfc                     ; FA55A1  c0 93 3c fc
	m_inc 4, MB8, 0x93                            ; FA55A5  c0 93 64   +4 ticks per MIDI clock, and 96/24 = 4
	m_cp_mi8 MB8, 0x93, 0x60                      ; FA55A8  c0 93 3f 60
	jr nz, .LFA55DB                               ; FA55AC  6e 2d
	ldio 0x93, 0x00                               ; FA55AE  08 93 00
	m_inc 1, MW8, 0x91                            ; FA55B1  d0 91 61
	push XWA                                      ; FA55B4  38
	xor XWA,XWA                                   ; FA55B5  e8 d0
	cpdm32 (0x3004), xwa                          ; FA55B7  e1 04 30 f8
	pop XWA                                       ; FA55BB  58
	jr z, .LFA55C1                                ; FA55BC  66 03
	calr SeqBuf_AppendMarker_XIX                                 ; FA55BE  1e 0a 01
.LFA55C1:
	m_bit 2, MD16, 0x7f34                         ; FA55C1  f1 34 7f ca
	jr z, .LFA55DB                                ; FA55C5  66 14
	cp D,0xfc                                     ; FA55C7  cc cf fc
	jr nz, .LFA55DB                               ; FA55CA  6e 0f
	m_set 7, MD16, 0x34bb                         ; FA55CC  f1 bb 34 bf   (0x34BB) bit 7 -- 'stopped by an external 0xFC'
	ldio 0x95, 0x10                               ; FA55D0  08 95 10
.LFA55D3:
	bit_dd8 0x02, 0x96                            ; FA55D3  f0 96 ca
	jr z, .LFA55DB                                ; FA55D6  66 03
	ldio 0x96, 0x10                               ; FA55D8  08 96 10
.LFA55DB:
	ret                                           ; FA55DB  0e
.LFA55DC:
	m_bit 2, MD16, 0x7f34                         ; FA55DC  f1 34 7f ca
	jr z, .LFA55D3                                ; FA55E0  66 f1
	m_bit 2, MD16, 0x34bb                         ; FA55E2  f1 bb 34 ca
	jr nz, .LFA55F3                               ; FA55E6  6e 0b
	cp D,0xfa                                     ; FA55E8  cc cf fa
	jr z, MIDI_RT_Start                                ; FA55EB  66 1d
	cp D,0xfb                                     ; FA55ED  cc cf fb
	jrl z, MIDI_RT_Continue                               ; FA55F0  76 74 00
.LFA55F3:
	ret                                           ; FA55F3  0e
	push XWA                                      ; FA55F4  38
	xor XWA,XWA                                   ; FA55F5  e8 d0
	cpdm32_24 (0x60341e), xwa                     ; FA55F7  e2 1e 34 60 f8
	pop XWA                                       ; FA55FC  58
	jr z, .LFA5609                                ; FA55FD  66 0a
	push SR                                       ; FA55FF  02
	ei 0x06                                       ; FA5600  06 06
	calr MIDI_RT_Start_ResetCounters                                 ; FA5602  1e 19 00
	calr MIDI_Clock_CatchUp                                 ; FA5605  1e 33 00
	pop SR                                        ; FA5608  03
.LFA5609:
	ret                                           ; FA5609  0e
MIDI_RT_Start:
	m_set 5, MD16, 0x34d0                         ; FA560A  f1 d0 34 bd
	stdi8 (0x091e), 0x00                          ; FA560E  f1 1e 09 00 00
	push XWA                                      ; FA5613  38
	xor XWA,XWA                                   ; FA5614  e8 d0
	cpdm32_24 (0x60341e), xwa                     ; FA5616  e2 1e 34 60 f8
	pop XWA                                       ; FA561B  58
	jr nz, .LFA563A                               ; FA561C  6e 1c
MIDI_RT_Start_ResetCounters:
	xor WA,WA                                     ; FA561E  d8 d0
	st_dd8b a, 0x8d                               ; FA5620  f0 8d 41   START rewinds transport C to bar 0 beat 0 tick 0
	st_dd8w wa, 0x8e                              ; FA5623  f0 8e 50
	ldio 0x95, 0x01                               ; FA5626  08 95 01   and puts it in state 0x01
	m_bit 0, MD16, 0x34bb                         ; FA5629  f1 bb 34 c8
	jr z, .LFA563A                                ; FA562D  66 0b
	xor WA,WA                                     ; FA562F  d8 d0
	st_dd8b a, 0x93                               ; FA5631  f0 93 41
	st_dd8w wa, 0x91                              ; FA5634  f0 91 50
	ldio 0x96, 0x01                               ; FA5637  08 96 01
.LFA563A:
	ret                                           ; FA563A  0e
MIDI_Clock_CatchUp:
	m_cp_mi8 MB16, 0x091e, 0x00                   ; FA563B  c1 1e 09 3f 00
	jr z, MIDI_Clock_CatchUp_Done                                ; FA5640  66 1f
	bit_dd8 0x00, 0x95                            ; FA5642  f0 95 c8
	jr z, MIDI_Clock_CatchUp_Done                                ; FA5645  66 1a
	ldio 0x95, 0x06                               ; FA5647  08 95 06
	ldb_d8 a, (0x091e)                            ; FA564A  c1 1e 09 21
	dec 1,A                                       ; FA564E  c9 69
	sll a, 0x02                                   ; FA5650  c9 ee 02
	m_add_mr MB8, 0x8d, r1                        ; FA5653  c0 8d 89
	bit_dd8 0x00, 0x96                            ; FA5656  f0 96 c8
	jr z, MIDI_Clock_CatchUp_Done                                ; FA5659  66 06
	ldio 0x96, 0x06                               ; FA565B  08 96 06
	m_add_mr MB8, 0x93, r1                        ; FA565E  c0 93 89
MIDI_Clock_CatchUp_Done:
	stdi8 (0x091e), 0x00                          ; FA5661  f1 1e 09 00 00
	ret                                           ; FA5666  0e
MIDI_RT_Continue:
	ldio 0x95, 0x06                               ; FA5667  08 95 06
	m_bit 0, MD16, 0x34bb                         ; FA566A  f1 bb 34 c8
	jr z, .LFA5673                                ; FA566E  66 03
	ldio 0x96, 0x06                               ; FA5670  08 96 06
.LFA5673:
	ret                                           ; FA5673  0e

; ---------------------------------------------------------------------
; MIDI_RT_ExternalOff -- the same dispatch when (0x7F32) bit 2 is clear
;
; Called from: MIDI_RT_Received (0xFA552C)
; Inputs:  D = the real-time byte
; Outputs: (0xA1) is zeroed -- so the tempo tracker's counter is kept reset even
;          when the tempo is not being followed -- and 0xFC still stops the
;          transports, but into state 0x0C rather than 0x10.
; Notes:   the pair of handlers is what makes (0x7F32) bit 2 a "follow external
;          MIDI clock" switch rather than a mode bit of unknown purpose.  That
;          is inference from the two arms' contents; the bit's producer has not
;          been traced.
; ---------------------------------------------------------------------
MIDI_RT_ExternalOff:
	ldio 0xa1, 0x00                               ; FA5674  08 a1 00
	pushw wa                                      ; FA5677  28
	ld_sd8b a, 0x95                               ; FA5678  c0 95 21
	and A,0x05                                    ; FA567B  c9 cc 05
	popw wa                                       ; FA567E  48
	jr z, .LFA569C                                ; FA567F  66 1b
	m_bit 2, MD16, 0x7f34                         ; FA5681  f1 34 7f ca
	jr z, .LFA569B                                ; FA5685  66 14
	cp D,0xfc                                     ; FA5687  cc cf fc
	jr nz, .LFA569B                               ; FA568A  6e 0f
	m_set 7, MD16, 0x34bb                         ; FA568C  f1 bb 34 bf
	ldio 0x95, 0x0c                               ; FA5690  08 95 0c
	bit_dd8 0x02, 0x96                            ; FA5693  f0 96 ca
	jr z, .LFA569B                                ; FA5696  66 03
	ldio 0x96, 0x0c                               ; FA5698  08 96 0c
.LFA569B:
	ret                                           ; FA569B  0e
.LFA569C:
	m_bit 2, MD16, 0x7f34                         ; FA569C  f1 34 7f ca
	jr z, .LFA56B2                                ; FA56A0  66 10
	m_bit 2, MD16, 0x34bb                         ; FA56A2  f1 bb 34 ca
	jr nz, .LFA56B2                               ; FA56A6  6e 0a
	cp D,0xfa                                     ; FA56A8  cc cf fa
	jr z, .LFA56B3                                ; FA56AB  66 06
	cp D,0xfb                                     ; FA56AD  cc cf fb
	jr z, .LFA56BC                                ; FA56B0  66 0a
.LFA56B2:
	ret                                           ; FA56B2  0e
.LFA56B3:
	set_dd8 0x01, 0xa0                            ; FA56B3  f0 a0 b9
	ldio 0x77, 0xdd                               ; FA56B6  08 77 dd
	jrl MIDI_RT_Start                                  ; FA56B9  78 4e ff
.LFA56BC:
	m_bit 0, MD16, 0x34bb                         ; FA56BC  f1 bb 34 c8
	jr z, .LFA56CA                                ; FA56C0  66 08
	set_dd8 0x02, 0xa0                            ; FA56C2  f0 a0 ba
	ldio 0x77, 0xdd                               ; FA56C5  08 77 dd
	jr MIDI_RT_Continue                                   ; FA56C8  68 9d
.LFA56CA:
	ret                                           ; FA56CA  0e

; ---------------------------------------------------------------------
; SeqBuf_AppendMarker_XIX -- a second copy of SeqBuf_AppendMarker
;
; Called from: 0xFA55BE
; Inputs:  as SeqBuf_AppendMarker, but the buffer pointer is built here rather
;          than inherited: XIX = 0x600A14
; Outputs: as SeqBuf_AppendMarker
; Notes:   instruction for instruction the same routine as the one at 0xF83034,
;          with XIX substituted for XIY throughout -- two compilations of one
;          source, reached from the sequencer tick and from the MIDI clock.
; ---------------------------------------------------------------------
SeqBuf_AppendMarker_XIX:
	bit_dd8 0x00, 0xaa                            ; FA56CB  f0 aa c8
	jr nz, .LFA56F8                               ; FA56CE  6e 28
	pushw wa                                      ; FA56D0  28
	ld XIX,0x00600a14                             ; FA56D1  44 14 0a 60 00
	ld wa, (xix-2)                                ; FA56D6  9c fe 20
	and WA,WA                                     ; FA56D9  d8 c0
	jr z, .LFA56F2                                ; FA56DB  66 15
	ld hl, (xix-4)                                ; FA56DD  9c fc 23
	.byte 0xf3, 0x07, 0xf0, 0xec, 0x00, 0x81      ; FA56E0  f3 07 f0 ec 00 81   ld (XIX+HL),0x81
	minc1_16 hl, 0x01ff                           ; FA56E6  db 38 ff 01
	dec 1,WA                                      ; FA56EA  d8 69
	ld (xix-4), hl                                ; FA56EC  bc fc 53
	ld (xix-2), wa                                ; FA56EF  bc fe 50
.LFA56F2:
	popw wa                                       ; FA56F2  48
	ldwio 0xac, 0x00                              ; FA56F3  0a ac 00 00
	ret                                           ; FA56F7  0e
.LFA56F8:
	ld XIX,0x000000ae                             ; FA56F8  44 ae 00 00 00
	m_ld_rm MW8, 0xac, r3                         ; FA56FD  d0 ac 23
	.byte 0xf3, 0x07, 0xf0, 0xec, 0x00, 0x81      ; FA5700  f3 07 f0 ec 00 81   ld (XIX+HL),0x81
	inc 1,HL                                      ; FA5706  db 61
	st_dd8w hl, 0xac                              ; FA5708  f0 ac 53
	ret                                           ; FA570B  0e
	.incbin "original_ROMs/wsa1_prom_a.ic12", 0x02570C, 0x0411E7

; ==============================================================================
; 0xFE68F3-0xFE69BE -- the 64-bit integer divide runtime
; ==============================================================================
;
; ★ TRANSPLANTED FROM THE KN5000, and this time with the offset arithmetic
;   checked.  prom_a 0xFE68F2-0xFE699B is 170 bytes byte-identical to the KN5000
;   sub-CPU payload, and the sibling project already has the whole routine named
;   and commented: ../kn5000-roms-disasm/v142/subcpu/subcpu_fp_math.s:1007-1080
;   (`Int_SignedDiv` at :1014, `FP_UnsignedDiv` at :1069).
;
;   THE MAPPING THAT MAKES THAT CITATION VALID.  notes/kn5000-label-transplant.md
;   maps a run at payload FILE OFFSET p to KN5000 ADDRESS 0x400+p.  That is wrong
;   by 0xEB00: the payload .rom is a SPLICE of the first 0x100 bytes of the image
;   and everything from image offset 0xEC00 on (../kn5000-roms-disasm/Makefile:
;   635-640), so above the first 256 bytes the address is 0xEF00 + offset.  The
;   check is in prom_a/kn5000_run_offsets.py.  The prom_c lane found the same
;   0xEB00 error independently and first -- their retraction and proof are at the
;   top of notes/kn5000-label-transplant.md; the corrected 105-proposal table and
;   the runnable check are in notes/FINDINGS-kn5000-transplant-offset.md.  Every
;   proposal in the old table names the WRONG routine, this one included: it was
;   offered as "DSP_EffParam_Copy_V4", and it is a divide.
;
;   WHY THE CORRECTED NAMES ARE BELIEVABLE AND THE OLD ONE WAS NOT.  Under the
;   0xEF00 mapping the run covers KN5000 0x3DC13-0x3DCBC, and the FOURTEEN
;   labels the sibling defines in that window --
;     3DC14 3DC25 3DC35 3DC47 3DC4B 3DC5B 3DC5F 3DC69 3DC8C 3DCA2 3DCA7 3DCAE
;     3DCB9 3DCBB
;   -- land on 0xFE68F3 0xFE6904 0xFE6914 0xFE6926 0xFE692A 0xFE693A 0xFE693E
;   0xFE6948 0xFE696B 0xFE6981 0xFE6986 0xFE698D 0xFE6998 0xFE699A, and every one
;   of those is an instruction boundary AND a branch target in the WSA1
;   disassembly below.  Fourteen for fourteen is not something a wrong alignment
;   produces.  Under the old mapping the first "matching" routine began mid
;   instruction.
;
;   ⚠ The two images DIVERGE at 0xFE699B (KN5000 0x3DCBC): same algorithm, a
;   different register in the scaling loop.  So the four labels from
;   FP_UnsignedDiv_ScaleDone on are DESCRIPTIVE, named from this code, not
;   transplanted.
;
; WHAT IT COMPUTES (from the sibling's header, which the code here matches):
;   64-bit divide/modulo for the C runtime.  Dividend XWA:QWA, divisor XBC:QBC,
;   quotient in XHL, remainder in XDE.  D selects quotient (0) or remainder (1)
;   and is set by the alternate entry points; E carries the two operand signs.

; ---------------------------------------------------------------------
; Int_SignedDiv -- signed 64-bit divide/modulo
;
; Called from: Int_SignedDiv_Quotient and Int_SignedDiv_Remainder just below;
;          their own callers are not yet traced.
; Inputs:  XWA:QWA = dividend, XBC:QBC = divisor, D = 0 quotient / 1 remainder
; Outputs: XHL = result.  XDE, WA, BC, E clobbered.
; Notes:   records both signs in E, takes absolute values, calls the unsigned
;          kernel, then re-applies sign(a) XOR sign(b) to a quotient or sign(a)
;          to a remainder.  Name and structure: sibling subcpu_fp_math.s:1014.
; ---------------------------------------------------------------------
Int_SignedDiv:
	ldb e, 0x00                                   ; FE68F3  25 00
	bit 0x0f,QWA                                  ; FE68F5  d7 e2 33 0f
	jr z, Int_SignedDiv_AfterSignA                                ; FE68F9  66 09
	ldb e, 0x01                                   ; FE68FB  25 01
	cpl QWA                                       ; FE68FD  d7 e2 06
	cpl WA                                        ; FE6900  d8 06
	inc 1,XWA                                     ; FE6902  e8 61
Int_SignedDiv_AfterSignA:
	bit 0x0f,QBC                                  ; FE6904  d7 e6 33 0f
	jr z, Int_SignedDiv_CallUnsigned                                ; FE6908  66 0a
	or E,0x02                                     ; FE690A  cd ce 02
	cpl QBC                                       ; FE690D  d7 e6 06
	cpl BC                                        ; FE6910  d9 06
	inc 1,XBC                                     ; FE6912  e9 61
Int_SignedDiv_CallUnsigned:
	pushw de                                      ; FE6914  2a
	calr FP_UnsignedDiv                                 ; FE6915  1e 30 00
	popw wa                                       ; FE6918  48
	cps w, 0x01                                   ; FE6919  c8 d9
	jr z, Int_SignedDiv_ResultCorr                                ; FE691B  66 09
	ld XHL,XDE                                    ; FE691D  ea 8b
	bit 0x00,A                                    ; FE691F  c9 33 00
	scc NZ,A                                      ; FE6922  c9 7e
	jr Int_SignedDiv_NegResult                                   ; FE6924  68 04
Int_SignedDiv_ResultCorr:
	cps a, 0x03                                   ; FE6926  c9 db
	ret Z                                         ; FE6928  b0 f6
Int_SignedDiv_NegResult:
	or XHL,XHL                                    ; FE692A  eb e3
	ret Z                                         ; FE692C  b0 f6
	cps a, 0x00                                   ; FE692E  c9 d8
	ret Z                                         ; FE6930  b0 f6
	cpl QHL                                       ; FE6932  d7 ee 06
	cpl HL                                        ; FE6935  db 06
	inc 1,XHL                                     ; FE6937  eb 61
	ret                                           ; FE6939  0e

; ---------------------------------------------------------------------
; Int_SignedDiv_Quotient / _Remainder / Int_UnsignedDiv_Remainder -- entries
;
; Called from: not yet traced
; Inputs:  as Int_SignedDiv
; Outputs: as Int_SignedDiv
; Notes:   three one-line entry points that only set D and fall into the body.
;          The sibling calls the first of them `Int_SignedDiv_ConstData` and
;          spells it as four raw bytes with a comment saying it is really code
;          (subcpu_fp_math.s:1057-1059); here it is written as the two
;          instructions it is, which the byte gate confirms.
; ---------------------------------------------------------------------
Int_SignedDiv_Quotient:
	ldb d, 0x00                                   ; FE693A  24 00
	jr Int_SignedDiv                                   ; FE693C  68 b5
Int_SignedDiv_Remainder:
	ldb d, 0x01                                   ; FE693E  24 01
	jr Int_SignedDiv                                   ; FE6940  68 b1
Int_UnsignedDiv_Remainder:
	calr FP_UnsignedDiv                                 ; FE6942  1e 03 00
	ld XHL,XDE                                    ; FE6945  ea 8b
	ret                                           ; FE6947  0e

; ---------------------------------------------------------------------
; FP_UnsignedDiv -- unsigned 64-bit divide, the kernel
;
; Called from: Int_SignedDiv_CallUnsigned (0xFE6915) and
;          Int_UnsignedDiv_Remainder (0xFE6942)
; Inputs:  XWA:QWA = dividend, XBC:QBC = divisor
; Outputs: XHL = quotient, XDE = remainder
; Notes:   special cases first -- divisor 1, divisor 0 (quotient = all ones),
;          dividend <= divisor -- then the hardware `div` when the divisor fits
;          in 32 bits, with a two-step path when that overflows, and finally the
;          restoring shift-and-subtract loop.  Sibling: subcpu_fp_math.s:1069.
; ---------------------------------------------------------------------
FP_UnsignedDiv:
	cp XBC,0x00000001                             ; FE6948  e9 cf 01 00 00 00
	jr z, FP_UnsignedDiv_ByOne                                ; FE694E  66 31
	jr c, FP_UnsignedDiv_Zero                                ; FE6950  67 34
	cp XWA,XBC                                    ; FE6952  e9 f0
	jr ule, FP_UnsignedDiv_SmallDividend                              ; FE6954  63 37
	cp QBC,0                                      ; FE6956  d7 e6 d8
	jr nz, FP_UnsignedDiv_General                               ; FE6959  6e 3d
	ld XDE,XWA                                    ; FE695B  e8 8a
	div xwa, xbc                                  ; FE695D  d9 50
	jr ov, FP_UnsignedDiv_Overflow                               ; FE695F  64 0a
	lds32 xhl, 0x00                               ; FE6961  eb a8
	ld XDE,XHL                                    ; FE6963  eb 8a
	ld HL,WA                                      ; FE6965  d8 8b
	ld DE,QWA                                     ; FE6967  d7 e2 8a
	ret                                           ; FE696A  0e
FP_UnsignedDiv_Overflow:
	ld WA,QDE                                     ; FE696B  d7 ea 88
	extz XWA                                      ; FE696E  e8 12
	div xwa, xbc                                  ; FE6970  d9 50
	ld QHL,WA                                     ; FE6972  d7 ee 98
	ld WA,DE                                      ; FE6975  da 88
	div xwa, xbc                                  ; FE6977  d9 50
	ld HL,WA                                      ; FE6979  d8 8b
	ld DE,QWA                                     ; FE697B  d7 e2 8a
	extz XDE                                      ; FE697E  ea 12
	ret                                           ; FE6980  0e
FP_UnsignedDiv_ByOne:
	ld XHL,XWA                                    ; FE6981  e8 8b
	lds32 xde, 0x00                               ; FE6983  ea a8
	ret                                           ; FE6985  0e
FP_UnsignedDiv_Zero:
	lds32 xhl, 0x00                               ; FE6986  eb a8
	ld XDE,XHL                                    ; FE6988  eb 8a
	dec 1,XHL                                     ; FE698A  eb 69
	ret                                           ; FE698C  0e
FP_UnsignedDiv_SmallDividend:
	lds32 xhl, 0x01                               ; FE698D  eb a9
	lds32 xde, 0x00                               ; FE698F  ea a8
	ret Z                                         ; FE6991  b0 f6
	dec 1,XHL                                     ; FE6993  eb 69
	ld XDE,XWA                                    ; FE6995  e8 8a
	ret                                           ; FE6997  0e
FP_UnsignedDiv_General:
	ldb d, 0x00                                   ; FE6998  24 00
FP_UnsignedDiv_ScaleLoop:
	cp XWA,XBC                                    ; FE699A  e9 f0
	jr z, FP_UnsignedDiv_ShiftInit                                ; FE699C  66 0b
	jr c, FP_UnsignedDiv_ScaleDone                                ; FE699E  67 06
	inc 1,D                                       ; FE69A0  cc 61
	add XBC,XBC                                   ; FE69A2  e9 81
	jr nc, FP_UnsignedDiv_ScaleLoop                               ; FE69A4  6f f4
FP_UnsignedDiv_ScaleDone:
	sra xbc, 0x01                                 ; FE69A6  e9 ed 01
FP_UnsignedDiv_ShiftInit:
	lds32 xhl, 0x00                               ; FE69A9  eb a8
FP_UnsignedDiv_ShiftLoop:
	add XHL,XHL                                   ; FE69AB  eb 83
	cp XWA,XBC                                    ; FE69AD  e9 f0
	jr c, FP_UnsignedDiv_ShiftNext                                ; FE69AF  67 05
	set 0x00,L                                    ; FE69B1  cf 31 00
	sub XWA,XBC                                   ; FE69B4  e9 a0
FP_UnsignedDiv_ShiftNext:
	srl xbc, 0x01                                 ; FE69B6  e9 ef 01
	djnz8 d, FP_UnsignedDiv_ShiftLoop                             ; FE69B9  cc 1c ef
	ld XDE,XWA                                    ; FE69BC  e8 8a
	ret                                           ; FE69BE  0e
	.incbin "original_ROMs/wsa1_prom_a.ic12", 0x0669BF, 0x019541

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
	.long RESET			; 0x00  RESET
	.long 0x00F82D02	; 0x04  SWI1
	.long 0x00F82D03	; 0x08  SWI2 / INTUNDEF
	.long 0x00F82D04	; 0x0C  SWI3
	.long 0x00F82D05	; 0x10  SWI4
	.long 0x00F82D06	; 0x14  SWI5
	.long 0x00F82D07	; 0x18  SWI6
	.long 0x00F400A4	; 0x1C  SWI7 -> prom_b thunk `jp 0xF8E9A5` =
				;       SWI7_ServiceCall_Dispatch, the 64-slot
				;       graphics service call
	.long NMI_PowerFail_SaveAndHalt	; 0x20  NMI -- the power-fail handler
	.long INTWD_Reboot		; 0x24  INTWD -- jumps back to RESET
	.long 0x00F40EDC	; 0x28  INT0       -> prom_b thunk (file 0x40EDC:
				;                     `jp 0xF8E47F`)
	.long 0x00F82D08	; 0x2C  INT4
	.long 0x00F42D28	; 0x30  INT5
	.long 0x00F40F0C	; 0x34  INT6
	.long IRQ_UnusedVector_Hang	; 0x38  INT7   ⚠ not a stub -- it HANGS
	.long IRQ_UnusedVector_Hang	; 0x3C  (reserved; MAME skips this slot)
	.long IRQ_UnusedVector_Hang	; 0x40  INTT0
	.long INTT1_Tick		; 0x44  INTT1 -- the periodic time base: MIDI
				;       active sensing, the (0xA1) tempo counter, the
				;       transport state machine and the (0x88) rota
	.long 0x00F40EE0	; 0x48  INTT2      -> the micro-DMA 2 trigger armed
				;                     at 0xF8E166 (DMA2V = 0x12,
				;                     0x12<<2 = 0x48)
	.long 0x00F42D64	; 0x4C  INTT3
	.long INTTR4_SequencerTick	; 0x50  INTTR4 -- the musical time base:
				;       96 ticks per beat, three transports, and the
				;       24-per-beat MIDI clock
	.long IRQ_UnusedVector_Hang	; 0x54  INTTR5 -- worth knowing: the tempo
				;       code writes TREG5, so a reader expects this
				;       slot to matter.  It hangs.
	.long IRQ_UnusedVector_Hang	; 0x58  INTTR6
	.long IRQ_UnusedVector_Hang	; 0x5C  INTTR7
	.long 0x00F40714	; 0x60  INTRX0 -> prom_b thunk `jp 0xFA5496` =
				;       MIDI_RX_Byte
	.long 0x00F40718	; 0x64  INTTX0 -> prom_b thunk `jp 0xFA542F` =
				;       MIDI_TX_Ready
	.long 0x00F40F10	; 0x68  INTRX1
	.long 0x00F40F14	; 0x6C  INTTX1
	.long IRQ_UnusedVector_Hang	; 0x70  INTAD
	.long 0x00F42D30	; 0x74  INTTC0
	.long IRQ_UnusedVector_Hang	; 0x78  INTTC1
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
