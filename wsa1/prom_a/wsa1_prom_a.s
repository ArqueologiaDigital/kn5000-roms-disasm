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
; STATUS: partially converted.  Regenerate the figure with
; `python3 scripts/analysis/source_coverage.py`; it is not maintained by hand
; here, because a hand-maintained one in README.md was wrong for a commit.  Converted so far, as
; real assembly (everything else is still .incbin, so it builds byte-exact by
; construction and asserts nothing):
;
;   0xF826A9-0xF827C7   287  RESET, the whole boot path to its jump into prom_b
;   0xF82CFF-0xF830C5   967  INTWD, the unused-vector trap, INTT1 and INTTR4 with
;                            their dispatch tables, the event-buffer append, NMI
;                            (power-fail) and its checksum helper
;   0xF856EC-0xF857D5   234  the kernel: idle loop, task switch, software timers,
;                            and IRQ_Epilogue, where every handler exits
;   0xF85877-0xF85903   141  the scheduler's two queue-rotate primitives, which
;                            are what identify 0x0330 as three READY QUEUES
;   0xF85C89-0xF85D1B   147  MsgQueue_ReceiveBlocking -- the blocking message
;                            receive, and with it the kernel's queue RAM map
;   0xF85E8A-0xF85F58   207  EntryPoint_Records (4 x 12 bytes), the endless DSP
;                            refresh task, and DSP_Init_Channels
;   0xF85F59-0xF85FF8   160  the DSP / tone-generator register writers at 0x7F0000
;   0xF8E47F-0xF8E6A1   547  INT0, the inter-processor link receiver, INTTC2,
;                            INTTC3 and the link's main-loop service task
;   0xF8E6A2-0xF8E6F9    88  micro-DMA channel setup helpers, and a block copy
;   0xF8E800-0xF8EAC6   711  the SED1330-family LCD controller: entry thunks, the
;                            power-on setup, the SWI7 gateway and its 64-slot table
;   0xF8EAC7-0xF8F038  1394  SWI7 service 0x00 (draw a line) with its six helpers,
;                            0x0B (plot a pixel), 0x03/0x04 (blit a rectangle
;                            column-major, and read one back), the layer selector
;                            and its pointer table, and 0x05 (fill a rectangle)
;   0xF8F039-0xF8F3A3   875  SWI7's TEN TEXT SERVICES, one per font, and their
;                            two glyph blitters (notes/FINDINGS-fonts.md)
;   0xF8F3A4-0xF8F7B7  1044  SWI7's line and box services 0x01 0x02 0x09 0x0A
;                            0x13 0x22, and the two edge-mask helpers and tables
;                            that services 0x01 and 0x05 share
;   0xF8F7B8-0xF8F84F   152  SWI7 services 0x0C and 0x0D, layer visibility
;   0xFA5418-0xFA570B   756  the MIDI port: both interrupt handlers, the System
;                            Real Time receiver and the tempo tracker
;   0xFE54B6-0xFE54EB    54  the five accessors of the CS0 device at 0x7B0004/5
;   0xFE594C-0xFE5A40   245  micro-DMA channel 0 and the 0x7A0000 DATA PORT: the
;                            two direction setups, the ten-code direction
;                            selector, and a 500-tick status wait
;   0xFE6851-0xFE68F2   162  INTTC0, INT5 (the 0x7B device's packet receiver) and
;                            Int_Mul32, the C runtime's 32x32->32 multiply
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
; ★ AND THE NUMBERS IN THOSE HEADERS ARE RE-CHECKED TOO.  Every quantified claim
; below -- "exactly five accessors", "82 of those bytes are equal", "eight
; entries", "three entries", "nine bytes", "ten command codes", "38 identical
; bytes", every font base and every ASCII verdict -- is one of the 133 named
; checks in notes/prom_a_byte_checks.py, which reads them back out of the ROM and
; exits non-zero if any has drifted.  Run it WITH the byte gate; neither catches
; what the other does.
;
; ⚠ AND THE GATE IS BLIND TO A SEARCHED NEGATIVE TOO.  Round 1 of this file put
; "these 22 bytes have NO counterpart in the KN5000 sub-CPU" in a header, on the
; strength of a tool whose MIN_RUN was 48 and whose silence was read as an
; answer.  The routine is 22 bytes long and the sibling has it.  Any sentence
; below that says something does NOT exist now names the search that failed to
; find it, and notes/prom_a_sibling_short_runs.py and notes/prom_a_addr_census.py
; exist so that those searches are runnable.
;
; TOOLS THAT PRODUCED THE CONVERTED TEXT, all in prom_a/ and all documented in
; their own docstrings:
;   (and in notes/: prom_a_byte_checks.py, prom_a_xref.py, prom_a_addr_census.py,
;    prom_a_sibling_short_runs.py -- see notes/prom_a-tooling.md)
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
;   notes/FINDINGS-interrupt-vectors.md       the 33 vectors and where each ends up
;   notes/FINDINGS-dev7b-and-int5.md          the CS0 device at 0x7A/0x7B
;   notes/FINDINGS-fonts.md                   the ten fonts and the ASCII test
;   notes/FINDINGS-prom_a-tasks-and-dsp-refresh.md  the entry records, the
;                                             scheduler queues, the DSP tasks
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
.macro m_add_mi16 pfx, addr, imm		; add (addr),#imm16		op 0x38
	_mem \pfx, \addr
	.byte 0x38, (\imm) & 0xFF, ((\imm) >> 8) & 0xFF
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
	.incbin "original_ROMs/wsa1_prom_a.ic12", 0x0030C6, 0x00253A

; ---------------------------------------------------------------------
; INTT3_KernelTick -- 8-bit timer 3: post one tick to the kernel's timer queue
;
; Called from: vector slot 0x4C (INTT3).  0xFFFF4C holds 0x00F42D64, a prom_b
;          thunk whose body is `jp 0xF85600`; reproduce with
;          `python3 notes/vector_map.py`, which follows both levels.
; Inputs:  none
; Outputs: (0xBE) incremented; control passed to IRQ_Epilogue, which decides
;          whether to reschedule.  No register is touched -- `inc 1,(mem)` and a
;          jump are the whole handler.
; Evidence: ★ (0xBE) IS THE KERNEL'S PENDING-TICK COUNT, and the kernel says so:
;          Kernel_Dispatch__drain_ticks (0xF85735, converted below) reads (0xBE),
;          and while it is non-zero decrements it by one and calls
;          Kernel_ServiceSoftTimers once per decrement.  A byte census of the
;          three memory-operand prefixes over prom_a and prom_b finds only three
;          real accesses to (0xBE): this increment, that read, and that write
;          back.  So this handler is the producer and the kernel is the sole
;          consumer.
;          It does not RETI: like INTT1_Tick and INTTR4_SequencerTick it exits
;          through IRQ_Epilogue (0xF857B7), whose own header already names this
;          address as one of its three entrants.
; Unknown:  ⚠ the tick RATE.  RESET programs timer 3 somewhere in the still
;          unconverted boot block; notes/FINDINGS-system-clock.md derives timer
;          1's rate, not timer 3's.
;          0xF85606, the byte after this handler, begins an unrelated routine
;          that sets XSP to the boot stack -- it is not part of the handler.
; ---------------------------------------------------------------------
INTT3_KernelTick:
	m_inc 1, MB8, 0xbe                            ; F85600  c0 be 61   unidasm: inc 1,(0xbe)
	jrl IRQ_Epilogue                              ; F85603  78 b1 01
	.incbin "original_ROMs/wsa1_prom_a.ic12", 0x005606, 0x0000E6

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
; Inputs:  cr 0x3C (must be 0 to proceed), (0xBE), (0xBF), the three ready-queue
;          heads at 0x0330/0x0334/0x0338
; Outputs: control transferred into a task, or into Kernel_Idle when none is
;          ready.  Does not return to its caller.
; Notes:   if the current task's XSP is still live it is saved into that task's
;          node first and the kernel switches to the boot stack 0x0060EB80 -- the
;          same address RESET's continuation sets, which is the second sign that
;          this is the top of the system rather than a subroutine.
;
; ★ CORRECTED 2026-08-25.  This header used to call 0x0330 "the task control
;   blocks: 3 x 8 bytes".  It is THREE FOUR-BYTE LIST HEADS -- the scan steps
;   `inc 4,IX` three times, and the emptiness test `cp HL,IX` is a circular
;   list's "head->next == &head".  The task control blocks are the NODES on those
;   lists: the very next instruction, `ld XSP,(XHL+0x04)`, reads the saved stack
;   out of the node HL and not out of 0x0330.  The queue primitives at 0xF85877
;   and 0xF85C89 (converted below) address the same three heads as
;   0x032C + n*4 for n = 1, 2, 3, and share the node layout
;   (+0 next, +2 prev, +4 saved XSP or payload, +9 state).  So 0x0330/0x0334/
;   0x0338 are three PRIORITY LEVELS, scanned in that order.
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
	ldw ix, 0x0330                                ; F85748  34 30 03   the THREE ready-queue heads, 4 bytes each
	extz XIX                                      ; F8574B  ec 12
Kernel_Dispatch__scan:
	m_ld_rm MWD+r4, 0x00, r3                      ; F8574D  9c 00 23   HL = head->next; a head that points at itself is an EMPTY queue
	cp HL,IX                                      ; F85750  dc f3
	jr nz, Kernel_Dispatch__switch_to                               ; F85752  6e 07
	inc 4,IX                                      ; F85754  dc 64
	djnz8 b, Kernel_Dispatch__scan                             ; F85756  ca 1c f4
	jr Kernel_Idle                                   ; F85759  68 b6
Kernel_Dispatch__switch_to:
	st_dd8w hl, 0xbf                              ; F8575B  f0 bf 53
	extz XHL                                      ; F8575E  eb 12
	ld XSP,(XHL+0x04)                             ; F85760  ab 04 27   node+4 = that task's saved XSP
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
	.incbin "original_ROMs/wsa1_prom_a.ic12", 0x0057D6, 0x0000A1

; ==============================================================================
; 0xF85877-0xF85903 -- the scheduler's two queue-rotate primitives
; ==============================================================================
;
; ★ WHAT 0x0330 REALLY IS.  Kernel_Dispatch__pick_task (0xF85746, converted
;   above) walks THREE list heads four bytes apart starting at 0x0330 -- `ldw
;   ix,0x0330`, `ld HL,(XIX+0)`, `cp HL,IX`, `inc 4,IX`, `djnz8 b` with B = 3 --
;   and a head whose `next` points at itself is skipped.  These two routines
;   compute their head as **0x032C + A*4**, so A = 1, 2, 3 lands on exactly
;   0x0330, 0x0334, 0x0338: the three heads the dispatcher scans, in the order it
;   scans them.  They are READY QUEUES, one per priority level, and 1 is the
;   level the dispatcher reaches first.
;
;   That also corrects a sentence in this file: Kernel_Dispatch's comment used to
;   call 0x0330 "the task control blocks: 3 x 8 bytes".  It is three FOUR-byte
;   list heads; the task control blocks are the NODES on them, and the
;   dispatcher's own next instruction proves it -- `ld XSP,(XHL+0x04)` reads the
;   saved stack out of the node HL, not out of 0x0330.
;
; THE LIST SHAPE, read off these two routines and used unchanged by every other
; queue in the kernel:
;   node+0  LE16  next        node+4  LE32  payload / saved XSP
;   node+2  LE16  prev        node+9  BYTE  state
; The heads are two-word sentinels of the same shape.  Unlink is
; `next->prev = prev; prev->next = next` (0xF8589D-0xF858A8) and insert-at-tail
; is `n->next = head; n->prev = head->prev; head->prev->next = n; head->prev = n`
; (0xF858AF-0xF858BC).  Both routines contain that pair verbatim.
;
; ⚠ The two differ ONLY in their save/restore and their exit, which is what makes
;   the naming safe: same address arithmetic, same test, same twelve list
;   instructions.

; ---------------------------------------------------------------------
; Kernel_YieldRotate -- move ready-queue A's head task to the back and reschedule
;
; Called from: sub_F85EC2 (0xF85EC4, converted below) with A = 3; and prom_b
;          thunk 0xF42D74 (notes/prom_a_xref.py 0xF85877), so it is a published
;          kernel entry, not a local helper.
; Inputs:  A = the queue number.  The list at 0x032C + A*4.
; Outputs: does not return normally.  On success the calling task's context is
;          left on its own stack in Kernel_ResumeTask's exact layout and control
;          goes to Kernel_Dispatch, which may pick someone else.  When the queue
;          holds at most one element it jumps to Kernel_ResumeTask instead, which
;          pops back exactly what was pushed -- so the caller simply returns.
; Evidence: 1. the seven `push` at 0xF8587A-0xF85880 are, in order, the seven
;             `pop` of Kernel_ResumeTask (0xF85763) read backwards, and the
;             `push SR` at 0xF85877 is its `pop SR`.  That is what makes both
;             exits legal from the same frame;
;          2. `ei 0x06` immediately after, i.e. the interrupt mask RAISED for the
;             list surgery -- the same critical-section idiom
;             Kernel_ServiceSoftTimers uses (`ei 0x00` ... `ei 0x06`);
;          3. the test is `cp IX,(XIY+0x02)`, head->next against head->prev:
;             equal means the queue holds zero or one element, and rotating it
;             would be a no-op.  Kernel_YieldRotate is the only place in this
;             pair that then RESCHEDULES.
; Unknown:  nothing here says which task is "current"; the rotation is by queue
;          position, so this is round-robin within a priority, not a yield to a
;          named task.
; ---------------------------------------------------------------------
Kernel_YieldRotate:
	push SR                                       ; F85877  02
	ei 0x06                                       ; F85878  06 06   raise the mask: list surgery
	push XHL                                      ; F8587A  3b
	push XWA                                      ; F8587B  38
	push XBC                                      ; F8587C  39
	push XDE                                      ; F8587D  3a
	push XIX                                      ; F8587E  3c
	push XIY                                      ; F8587F  3d
	push XIZ                                      ; F85880  3e   Kernel_ResumeTask's frame, exactly
	sll a, 0x02                                   ; F85881  c9 ee 02
	extz WA                                       ; F85884  d8 12
	add WA,0x032c                                 ; F85886  d8 c8 2c 03   head = 0x032C + A*4
	ld IY,WA                                      ; F8588A  d8 8d
	extz XIY                                      ; F8588C  ed 12
	m_ld_rm MWD+r5, 0x00, r4                      ; F8588E  9d 00 24   IX = head->next
	cp IX,(XIY+0x02)                              ; F85891  9d 02 f4   == head->prev? then 0 or 1 element
	jrl z, Kernel_ResumeTask                      ; F85894  76 cc fe   nothing to rotate: unwind and return
	extz XIX                                      ; F85897  ec 12
	extz XWA                                      ; F85899  e8 12
	extz XHL                                      ; F8589B  eb 12
	m_ld_rm MWD+r4, 0x00, r0                      ; F8589D  9c 00 20   WA = n->next
	ld HL,(XIX+0x02)                              ; F858A0  9c 02 23   HL = n->prev
	m_st_mr16 MDD+r3, 0x00, r0                    ; F858A3  bb 00 50   prev->next = next
	ld (XWA+0x02),HL                              ; F858A6  b8 02 53   next->prev = prev
	extz XIX                                      ; F858A9  ec 12
	extz XIY                                      ; F858AB  ed 12
	extz XWA                                      ; F858AD  e8 12
	m_st_mr16 MDD+r4, 0x00, r5                    ; F858AF  bc 00 55   n->next = head
	ld WA,(XIY+0x02)                              ; F858B2  9d 02 20
	ld (XIX+0x02),WA                              ; F858B5  bc 02 50   n->prev = head->prev
	ld (XWA),IX                                   ; F858B8  b0 54      head->prev->next = n
	ld (XIY+0x02),IX                              ; F858BA  bd 02 54   head->prev = n   -- n is now last
	jrl Kernel_Dispatch                           ; F858BD  78 55 fe   and re-pick

; ---------------------------------------------------------------------
; Kernel_RotateQueue -- the same rotation, without yielding
;
; Called from: prom_b thunk 0xF42D78 (`jp 0xF858C0`) -- the slot immediately
;          after Kernel_YieldRotate's own thunk at 0xF42D74.  That run of the
;          prom_b thunk table is a block of kernel entry points: 0xF42D70
;          0xF8584A, 0xF42D74 0xF85877, 0xF42D78 0xF858C0, 0xF42D7C 0xF85904,
;          0xF42D80 0xF8592D.  Who calls the THUNK is prom_b's business.
; Inputs:  A = the queue number.  Outputs: the list at 0x032C + A*4 rotated by
;          one; WA, XIX, XIY, XHL saved and restored, so it clobbers nothing.
; Evidence: the two bodies are BYTE-IDENTICAL over 38 bytes --
;          0xF85897-0xF858BC here matches 0xF858D9-0xF858FE there exactly, and
;          the run stops on the byte after in both directions (checked by
;          notes/prom_a_byte_checks.py, not by eye).  What differs is only the
;          wrapper: the four-register save of an ordinary leaf instead of the
;          scheduler frame, `jr` to the epilogue instead of Kernel_ResumeTask,
;          and `ret` instead of Kernel_Dispatch.  It also does NOT raise the
;          interrupt mask, which is worth noticing before calling it.
; Unknown:  who calls it, and why a version without the critical section exists.
; ---------------------------------------------------------------------
Kernel_RotateQueue:
	push XWA                                      ; F858C0  38
	push XIX                                      ; F858C1  3c
	push XIY                                      ; F858C2  3d
	push XHL                                      ; F858C3  3b
	sll a, 0x02                                   ; F858C4  c9 ee 02
	extz WA                                       ; F858C7  d8 12
	add WA,0x032c                                 ; F858C9  d8 c8 2c 03
	ld IY,WA                                      ; F858CD  d8 8d
	extz XIY                                      ; F858CF  ed 12
	m_ld_rm MWD+r5, 0x00, r4                      ; F858D1  9d 00 24
	cp IX,(XIY+0x02)                              ; F858D4  9d 02 f4
	jr z, Kernel_RotateQueue__ret                 ; F858D7  66 26
	extz XIX                                      ; F858D9  ec 12
	extz XWA                                      ; F858DB  e8 12
	extz XHL                                      ; F858DD  eb 12
	m_ld_rm MWD+r4, 0x00, r0                      ; F858DF  9c 00 20
	ld HL,(XIX+0x02)                              ; F858E2  9c 02 23
	m_st_mr16 MDD+r3, 0x00, r0                    ; F858E5  bb 00 50
	ld (XWA+0x02),HL                              ; F858E8  b8 02 53
	extz XIX                                      ; F858EB  ec 12
	extz XIY                                      ; F858ED  ed 12
	extz XWA                                      ; F858EF  e8 12
	m_st_mr16 MDD+r4, 0x00, r5                    ; F858F1  bc 00 55
	ld WA,(XIY+0x02)                              ; F858F4  9d 02 20
	ld (XIX+0x02),WA                              ; F858F7  bc 02 50
	ld (XWA),IX                                   ; F858FA  b0 54
	ld (XIY+0x02),IX                              ; F858FC  bd 02 54
Kernel_RotateQueue__ret:
	pop XHL                                       ; F858FF  5b
	pop XIY                                       ; F85900  5d
	pop XIX                                       ; F85901  5c
	pop XWA                                       ; F85902  58
	ret                                           ; F85903  0e

; ==============================================================================
; 0xF85904-0xF85C88 -- not yet converted
; ==============================================================================
	.incbin "original_ROMs/wsa1_prom_a.ic12", 0x005904, 0x000385

; ==============================================================================
; 0xF85C89-0xF85D1B -- the blocking message receive DSP_RefreshTask waits on
; ==============================================================================
;
; This is the routine DSP_RefreshTask (0xF85EC8, converted below) calls once per
; pass with the argument 1.  It is the first kernel IPC primitive in this file
; and it fixes three RAM layouts at once, so the whole map is set out here:
;
;   0x032C + n*4   ready queues; n = 1,2,3 are the three heads Kernel_Dispatch
;                  scans (see the 0xF85877 block above)
;   0x0360 + n*4   the WAIT queue of message queue n -- where a task parks when
;                  the queue is empty
;   0x0370 + n*4   the MESSAGE queue itself
;   0x03C4         the free-node list; a consumed node is returned here
;   0x03C8         the two software timers (Kernel_ServiceSoftTimers, converted)
;   (0xBF)         LE16 pointer to the current task's node.  Kernel_Dispatch
;                  writes it at 0xF8575B and clears it at 0xF85732; this routine
;                  reads it at 0xF85CE6 -- which is what says a node IS a task
;                  control block, since the same +0/+2 links serve both.
;
; NODE LAYOUT, as used here:  +0 next, +2 prev, +4 LE32 payload, +9 BYTE state.
; The payload slot is cleared to 0xFFFFFFFF as the node is recycled, the same
; "empty" marker Kernel_ServiceSoftTimers uses for an unused timer slot
; (0xF85780, converted above).

; ---------------------------------------------------------------------
; MsgQueue_ReceiveBlocking -- take the next message from queue A, or block
;
; Called from: DSP_RefreshTask (0xF85ED1) with A = 1; and prom_b thunk 0xF42DCC
;          (notes/prom_a_xref.py 0xF85C89).
; Inputs:  (XSP+0x04) = the queue number A.  Caller-cleaned (`inc 2,XSP`).
; Outputs: the 32-bit payload written back over the argument at (XSP+0x04), and
;          control returned through Kernel_ResumeTask.  If the queue is empty the
;          caller does not come back until someone posts: its node is taken off
;          whatever list it is on, marked state 3, put on 0x0360 + A*4, and
;          Kernel_Dispatch runs.
; Evidence: 1. the seven pushes plus `push SR` are again Kernel_ResumeTask's
;             frame, and BOTH exits are `jrl` -- to Kernel_ResumeTask on the
;             success path (0xF85CE3) and to Kernel_Dispatch on the empty path
;             (0xF85D19).  A routine whose two exits are "resume me" and "pick
;             someone else" is a blocking receive;
;          2. the emptiness test here is `cp IX,IY`, head->next against the head
;             itself -- the zero-element test, not the zero-or-one test the
;             rotate primitives use.  Two different tests for two different jobs,
;             in code that is otherwise identical, is why the readings are not
;             interchangeable;
;          3. the node is not freed to a heap: it is unlinked from the message
;             queue and linked onto 0x03C4 with the same twelve instructions, and
;             its payload word is set to 0xFFFFFFFF on the way past;
;          4. the result is returned by overwriting the incoming argument slot,
;             `ld (XSP+0x04),XIZ` -- which is why the caller's `inc 2,XSP` at
;             0xF85ED5 is followed by reading XIY rather than a register.
; Unknown:  ⚠ what state 3 means beyond "waiting on a message queue"; the only
;          other value seen is the 0 written at 0xF85E7F by an unconverted
;          routine, and nothing that READS +9 has been converted.  Who posts to
;          queue 1 is likewise not traced.
; ---------------------------------------------------------------------
MsgQueue_ReceiveBlocking:
	ld A,(XSP+0x04)                               ; F85C89  8f 04 21   A = the queue number
	push SR                                       ; F85C8C  02
	ei 0x06                                       ; F85C8D  06 06
	push XHL                                      ; F85C8F  3b
	push XWA                                      ; F85C90  38
	push XBC                                      ; F85C91  39
	push XDE                                      ; F85C92  3a
	push XIX                                      ; F85C93  3c
	push XIY                                      ; F85C94  3d
	push XIZ                                      ; F85C95  3e
	sll a, 0x02                                   ; F85C96  c9 ee 02
	extz WA                                       ; F85C99  d8 12
	ld DE,WA                                      ; F85C9B  d8 8a   keep A*4 for the wait queue below
	add WA,0x0370                                 ; F85C9D  d8 c8 70 03   the message queue
	ld IY,WA                                      ; F85CA1  d8 8d
	extz XIY                                      ; F85CA3  ed 12
	m_ld_rm MWD+r5, 0x00, r4                      ; F85CA5  9d 00 24   IX = head->next
	cp IX,IY                                      ; F85CA8  dd f4   == head? then the queue is EMPTY
	jr z, MsgQueue_ReceiveBlocking__block         ; F85CAA  66 3a
	extz XIX                                      ; F85CAC  ec 12
	extz XWA                                      ; F85CAE  e8 12
	extz XHL                                      ; F85CB0  eb 12
	m_ld_rm MWD+r4, 0x00, r0                      ; F85CB2  9c 00 20   unlink the node
	ld HL,(XIX+0x02)                              ; F85CB5  9c 02 23
	m_st_mr16 MDD+r3, 0x00, r0                    ; F85CB8  bb 00 50
	ld (XWA+0x02),HL                              ; F85CBB  b8 02 53
	ld XIZ,(XIX+0x04)                             ; F85CBE  ac 04 26   XIZ = the payload
	ld XBC,0xffffffff                             ; F85CC1  41 ff ff ff ff
	ld (XIX+0x04),XBC                             ; F85CC6  bc 04 61   mark the node empty
	ldw iy, 0x03c4                                ; F85CC9  35 c4 03   the free list
	extz XIX                                      ; F85CCC  ec 12
	extz XIY                                      ; F85CCE  ed 12
	extz XWA                                      ; F85CD0  e8 12
	m_st_mr16 MDD+r4, 0x00, r5                    ; F85CD2  bc 00 55   recycle it at the tail
	ld WA,(XIY+0x02)                              ; F85CD5  9d 02 20
	ld (XIX+0x02),WA                              ; F85CD8  bc 02 50
	ld (XWA),IX                                   ; F85CDB  b0 54
	ld (XIY+0x02),IX                              ; F85CDD  bd 02 54
	ld (XSP+0x04),XIZ                             ; F85CE0  bf 04 66   the payload IS the return value
	jrl Kernel_ResumeTask                         ; F85CE3  78 7d fa
MsgQueue_ReceiveBlocking__block:
	m_ld_rm MW8, 0xbf, r4                         ; F85CE6  d0 bf 24   IX = the CURRENT task's node
	extz XIX                                      ; F85CE9  ec 12
	extz XWA                                      ; F85CEB  e8 12
	extz XHL                                      ; F85CED  eb 12
	m_ld_rm MWD+r4, 0x00, r0                      ; F85CEF  9c 00 20   take it off its ready queue
	ld HL,(XIX+0x02)                              ; F85CF2  9c 02 23
	m_st_mr16 MDD+r3, 0x00, r0                    ; F85CF5  bb 00 50
	ld (XWA+0x02),HL                              ; F85CF8  b8 02 53
	ld (XIX+0x09),0x03                            ; F85CFB  bc 09 00 03   state 3 = waiting on a message queue
	add DE,0x0360                                 ; F85CFF  da c8 60 03   the wait queue of the SAME index
	ld IY,DE                                      ; F85D03  da 8d
	extz XIX                                      ; F85D05  ec 12
	extz XIY                                      ; F85D07  ed 12
	extz XWA                                      ; F85D09  e8 12
	m_st_mr16 MDD+r4, 0x00, r5                    ; F85D0B  bc 00 55   park it there, at the tail
	ld WA,(XIY+0x02)                              ; F85D0E  9d 02 20
	ld (XIX+0x02),WA                              ; F85D11  bc 02 50
	ld (XWA),IX                                   ; F85D14  b0 54
	ld (XIY+0x02),IX                              ; F85D16  bd 02 54
	jrl Kernel_Dispatch                           ; F85D19  78 f9 f9   run somebody else

; ==============================================================================
; 0xF85D1C-0xF85E89 -- not yet converted
; ==============================================================================
	.incbin "original_ROMs/wsa1_prom_a.ic12", 0x005D1C, 0x00016E

; ==============================================================================
; 0xF85E8A-0xF85F58 -- the task entry-point records, and the DSP refresh task
; ==============================================================================
;
; ★ THE SAME TABLE EXISTS IN BOTH PROCESSORS.  prom_c's lane already decoded a
;   run of 12-byte {entry, stack, ?} records at prom_c 0xF980EA and named it
;   EntryPoint_Records (prom_c/wsa1_prom_c.s, and the "three records" line of its
;   status header).  prom_a has the same structure at 0xF85E8A with FOUR records,
;   and the two tables agree field for field:
;
;     prom_c  7d 8b f9 00 | f0 ff 00 00 | 00 88 02 00     MAIN
;             db 54 fa 00 | 80 f9 00 00 | 00 88 02 00
;             18 81 f9 00 | 80 f4 00 00 | 00 88 01 00     DSP_ChannelRefresh_Loop
;     prom_a  5c 00 f4 00 | 00 e8 60 00 | 00 88 03 00
;             88 2e f4 00 | 80 e9 60 00 | 00 88 03 00
;             c8 5e f8 00 | 80 ec 60 00 | 00 88 01 00     DSP_RefreshTask (below)
;             c0 33 f4 00 | 00 eb 60 00 | 00 88 03 00
;
;   Seven records across the two images, and the halfword at +8 is 0x8800 in
;   every one of them.  Both tables give 0x0001 at +10 to the endless DSP
;   register-refresh entry and something larger to everything else.
;
; THE FIELDS, and how far each is established:
;   +0  LE32  ENTRY POINT.  All four of prom_a's decode as code; three of them
;             are prom_b thunk slots that `jp` straight back into prom_a --
;             0xF4005C -> 0xF827C8, 0xF42E88 -> 0xF8DA00, 0xF433C0 -> 0xFE02AB --
;             and the fourth, 0xF85EC8, is in prom_a directly, exactly as the
;             DSP entry is in prom_c.
;   +4  LE32  INITIAL STACK POINTER.  All four are in 0x0060E800-0x0060EC80, the
;             CS1 static RAM, and Kernel_Dispatch's own boot stack 0x0060EB80
;             (0xF8572B, converted above) sits inside the same run -- which is
;             what says this column is stacks and not data.
;   +8  LE16  0x8800 in all seven records.  READING, not a proof: a TLCS-900/H
;             status register with S=1 (system mode), MAX=1 and IFF=000 is
;             0x8800.  MAME resets this part to SR = 0xF800 and comments it
;             "system mode, iff set to 111, max mode, register bank 0"
;             (../mame/src/devices/cpu/tlcs900/tlcs900.cpp:218-219), and IFF is
;             the interrupt mask level -- tmp95c061.cpp:481 blocks every
;             interrupt while IFF == 7 and :538 scans levels from IFF upward.
;             So 0x8800 is the reset SR with the interrupt mask released, which
;             is exactly the SR a task should start with, and Kernel_ResumeTask
;             (0xF85763) does `pop SR` before its `ret` -- so a startable task
;             frame needs an SR word and a PC.  ⚠ WHAT IS MISSING: no site in
;             prom_a or prom_b writes the constant 0x8800 or pushes it, and no
;             code anywhere in either image names the address 0xF85E8A, so the
;             consumer of these records has not been found and the reading is
;             unconfirmed.
;   +10 LE16  ★ THE READY-QUEUE INDEX -- i.e. the task's PRIORITY.  0x0003 x3
;             and 0x0001 here; 0x0002 x2 and 0x0001 in prom_c.  The chain, added
;             after Kernel_YieldRotate was converted (0xF85877, above):
;               1. Kernel_Dispatch scans THREE list heads four bytes apart from
;                  0x0330 and takes the first non-empty one, so the heads are
;                  priority levels in scan order (0xF85746-0xF85759);
;               2. Kernel_YieldRotate and Kernel_RotateQueue address a head as
;                  0x032C + A*4, and A = 1, 2, 3 gives exactly 0x0330, 0x0334,
;                  0x0338 -- the same three;
;               3. sub_F85EC2 (0xF85EC2, below) calls Kernel_YieldRotate with
;                  A = 3, so the small integers really are used as that index;
;               4. all SEVEN +10 fields across prom_a and prom_c lie in 1..3 and
;                  never 0 or 4.
;             ⚠ Still a reading, for the same reason as +8: nothing that READS
;             this table has been found, so what is shown is that the values are
;             exactly the right shape for a queue index, not that they are used
;             as one.  1 is the level Kernel_Dispatch reaches FIRST, and 1 is
;             what both images give the endless DSP refresh task.
;
; COUNT = 4, and the last-entry test is what fixes it: a fifth record would
; start at 0xF85EBA, whose first word is 0x01000100 -- not in 0xF00000-0xFFFFFF
; and so not an entry point, while all four of the records above are.  The eight
; bytes from 0xF85EBA to 0xF85EC1 are emitted below as bytes and left
; unidentified; prom_c has a 4-byte trailer of the same flavour (0x01010001) in
; the same place.
;
; ⚠ NOTHING REFERENCES 0xF85E8A.  notes/prom_a_xref.py finds no `call`, `jp`,
;   `lda` or bare 32-bit pointer naming it in either image, and a scan of every
;   PC-relative `calr`/`jr`/`jrl` displacement finds none either.  Recorded as a
;   fact about the search, not as a claim that the table is dead.
; ---------------------------------------------------------------------
; EntryPoint_Records -- 4 x 12 bytes: {entry PC, initial XSP, SR?, ?}
;
; Read by:  nothing found -- see the block header.
; Layout:   +0 LE32 entry, +4 LE32 stack, +8 LE16 0x8800, +10 LE16 small int.
; Count:    4, 48 bytes, 0xF85E8A-0xF85EB9.  Verified by the last-entry test in
;           the block header and by notes/prom_a_byte_checks.py.
; Evidence: field-by-field above; the name is prom_c's, for the same structure
;           in the other processor's image.
; ---------------------------------------------------------------------
EntryPoint_Records:
	.long 0x00F4005C, 0x0060E800			; F85E8A  thunk -> 0xF827C8
	.short 0x8800, 0x0003
	.long 0x00F42E88, 0x0060E980			; F85E96  thunk -> 0xF8DA00
	.short 0x8800, 0x0003
	.long 0x00F85EC8, 0x0060EC80			; F85EA2  DSP_RefreshTask, in prom_a
	.short 0x8800, 0x0001
	.long 0x00F433C0, 0x0060EB00			; F85EAE  thunk -> 0xFE02AB
	.short 0x8800, 0x0003
	; 0xF85EBA-0xF85EC1: UNIDENTIFIED.  Not a fifth record -- 0x01000100 is not
	; an address.  prom_c has 01 00 01 01 in the same position.
	.byte 0x00, 0x01, 0x00, 0x01			; F85EBA
	.byte 0x00, 0x00, 0x00, 0x00			; F85EBE

; ---------------------------------------------------------------------
; sub_F85EC2 -- calls the 0xF85877 kernel primitive with A = 3
;
; Called from: not established.  The bytes 0xF856E4-0xF856E7 are the LE32
;          0x00F85EC2, but the disassembly around them does not frame those four
;          bytes as a pointer (0xF856DE is `jr T,0xF856E8`, which jumps over
;          them), so that is a coincidence candidate, not a caller.
; Inputs:  none.  Outputs: whatever 0xF85877 does for selector 3.
; Evidence: NONE for a semantic name -- hence sub_.  What is known: 0xF85877 is
;          reached through prom_b thunk 0xF42D74, takes a small selector in A,
;          walks a doubly-linked list at 0x032C + A*4, and when that list is
;          empty jumps to Kernel_ResumeTask (0xF85763, converted above) rather
;          than returning -- i.e. it is a blocking kernel primitive.  Naming it,
;          and therefore naming this wrapper, needs that routine converted.
; Unknown:  what selector 3 selects; who calls this.
;          It is written out rather than left inside the .incbin only because it
;          is the six bytes between the record table and the task below, and
;          hiding a boundary there would cost more than it saves.
; ---------------------------------------------------------------------
sub_F85EC2:
	ldb a, 0x03                                   ; F85EC2  21 03
	calr (0xF85877 - 0xF85EC7)                    ; F85EC4  1e b0 f9   the blocking primitive
	ret                                           ; F85EC7  0e

; ---------------------------------------------------------------------
; DSP_RefreshTask -- for ever: take a block off queue 1, push it to all four
;                    DSP channels
;
; Called from: NOTHING calls it.  Its address is the entry field of the THIRD
;          EntryPoint_Records record (0xF85EA2), paired with the stack
;          0x0060EC80.  That is the only reference to it in either image
;          (notes/prom_a_xref.py 0xF85EC8, plus the PC-relative scan).
; Inputs:  whatever 0xF85C89 hands back in XIY for selector 1; then four
;          consecutive 32-bit pointers read from that block with `ld XIY,(XDE+)`.
; Outputs: never returns.  Each pass writes 8 registers in each of channels
;          0, 1, 2, 3 of the DSP register file at 0x7F0000.
; Evidence: 1. the loop is closed by an unconditional `jr` back to 0xF85ECE,
;             which is INSIDE the frame the `link XIZ,0xFFFC` at 0xF85ECA opened
;             -- a frame built once with the loop below it is an entry point, not
;             a subroutine;
;          2. the four calls are DSP_WriteChannelRegs_FromTable (0xF85F59,
;             converted below), each `push XIY / pushw channel / call /
;             inc 6,XSP`, which is that routine's stack argument list exactly,
;             with the channel numbers 0,1,2,3 in order;
;          3. it opens with `ei 0x00`, releasing the interrupt mask -- see the
;             note on that below.
;          4. prom_c has the same task at 0xF98118 for its own DSP port, listed
;             in its own EntryPoint_Records with the same 0x0001 at +10
;             (prom_c/wsa1_prom_c.s, DSP_ChannelRefresh_Loop).
; Notes:   ⚠ `ei 0x00` ENABLES interrupts, it does not disable them.  EI sets the
;          IFF mask level (MAME op_EI, 900tbl.hxx:2073-2078: SR bits 6-4 :=
;          imm & 7); tmp95c061.cpp:481 skips interrupt dispatch only while
;          IFF == 7, and :538 scans priority levels from IFF upward, so IFF = 0
;          accepts everything and IFF = 7 is DI.  This file's own kernel agrees:
;          Kernel_Idle (0xF85711) does `ei 0x00` and then spins, and
;          Kernel_ServiceSoftTimers brackets its scan with `ei 0x00` ... `ei 0x06`
;          -- an idle loop does not run with interrupts off, and a critical
;          section is the one that RAISES the number.
;          ⚠ AND llvm-mc IS WHY THAT IS EASY TO GET WRONG: this assembler accepts
;          `di` on tlcs900 and emits `06 00`, byte for byte the same as
;          `ei 0x00`.  The alias says one thing and does the other, and the byte
;          gate cannot tell.  Probe and write-up in
;          notes/llvm-mc-tlcs900-spellings.md.  prom_c/wsa1_prom_c.s uses that
;          spelling and its DSP_ChannelRefresh_Loop header concludes the task
;          "starts by disabling interrupts ... and never re-enables them", which
;          is backwards; flagged here rather than edited, because prom_c is
;          another lane's file.
; Unknown:  what 0xF85C89 selector 1 dequeues, and hence what the four pointers
;          point at; whether anything ever selects this entry point.
; ---------------------------------------------------------------------
DSP_RefreshTask:
	ei 0x00                                       ; F85EC8  06 00   IFF := 0, i.e. accept every interrupt
	link XIZ,0xfffc                               ; F85ECA  ee 0c fc ff   4-byte frame, built ONCE
DSP_RefreshTask__pass:
	pushw 0x01                                    ; F85ECE  0b 01 00   selector 1
	call 0xf85c89                                 ; F85ED1  1d 89 5c f8   dequeue; returns a block in XIY
	inc 2,XSP                                     ; F85ED5  ef 62
	ld XDE,XIY                                    ; F85ED7  ed 8a   XDE walks the block
	ld_spil xiy, 0xea                             ; F85ED9  e5 ea 25   ld XIY,(XDE+) -- pointer for channel 0
	push XIY                                      ; F85EDC  3d
	pushw 0x00                                    ; F85EDD  0b 00 00
	call DSP_WriteChannelRegs_FromTable           ; F85EE0  1d 59 5f f8
	inc 6,XSP                                     ; F85EE4  ef 66
	ld_spil xiy, 0xea                             ; F85EE6  e5 ea 25   ld XIY,(XDE+) -- channel 1
	push XIY                                      ; F85EE9  3d
	pushw 0x01                                    ; F85EEA  0b 01 00
	call DSP_WriteChannelRegs_FromTable           ; F85EED  1d 59 5f f8
	inc 6,XSP                                     ; F85EF1  ef 66
	ld_spil xiy, 0xea                             ; F85EF3  e5 ea 25   ld XIY,(XDE+) -- channel 2
	push XIY                                      ; F85EF6  3d
	pushw 0x02                                    ; F85EF7  0b 02 00
	call DSP_WriteChannelRegs_FromTable           ; F85EFA  1d 59 5f f8
	inc 6,XSP                                     ; F85EFE  ef 66
	ld_spil xiy, 0xea                             ; F85F00  e5 ea 25   ld XIY,(XDE+) -- channel 3
	push XIY                                      ; F85F03  3d
	pushw 0x03                                    ; F85F04  0b 03 00
	call DSP_WriteChannelRegs_FromTable           ; F85F07  1d 59 5f f8
	inc 6,XSP                                     ; F85F0B  ef 66
	jr DSP_RefreshTask__pass                      ; F85F0D  68 bf   for ever

; ---------------------------------------------------------------------
; DSP_Init_Channels -- zero all 32 channel registers, then set register 0x1F of
;                      each channel to 1
;
; Called from: NO SITE FOUND.  notes/prom_a_xref.py 0xF85F0F reports no `call`,
;          `jp`, `lda` or bare pointer in prom_a or prom_b, and a scan of every
;          PC-relative `calr`/`jr`/`jrl` displacement in prom_a finds none.  It
;          is reachable only if something computes the address.
; Inputs:  none.  Outputs: for each channel 0..3, registers (ch<<5)|0x10 .. +7
;          set to 0, then register (ch<<5)|0x1F set to 1.  XIZ frame; XBC, XWA,
;          D clobbered.
; Evidence: ★ TRANSPLANTED NAME, byte-backed.  0xF85F4C-0xF85F58 is 13 bytes
;          identical to the KN5000 sub-CPU at 0x1FCD1, where llvm-nm names the
;          label DSP_Init_Channels_Loop and the enclosing routine (0x1FC95)
;          DSP_Init_Channels
;          (../kn5000-roms-disasm/v142/subcpu/kn5000_subprogram_v142.s:396-428).
;          Reproduce with `python3 notes/prom_a_sibling_short_runs.py`.
;          The two routines do the same thing with three differences, all
;          visible here: this one zeroes the 8-byte buffer where the KN5000
;          writes the test pattern 0x5A5A5A5A; the register file is at 0x7F0000
;          instead of 0x00130000; and the per-channel writer takes its arguments
;          on the stack rather than in XWA/BC.  prom_c has its own copy at
;          0xF98000, named DSP_ChannelRegs_Init by that lane, with the port at
;          0x00E00000 -- three processors, one routine, three buses.
; Notes:   the tail loop writes XWA (32 bits) at 0x7F0000, so the register index
;          goes to +0 and +1 and the value 0x0101 to +2 and +3; with A starting
;          at 0x1F and stepping 0x20 that is register 0x1F of channels 0..3 set
;          to 0x01.  0x0101001F is a single `ld XWA,imm32`, and `ld W,A` at the
;          top of the loop keeps the two index bytes equal.
; Unknown:  what register 0x1F is; why nothing calls this.
; ---------------------------------------------------------------------
DSP_Init_Channels:
	link XIZ,0xfff8                               ; F85F0F  ee 0c f8 ff   8-byte buffer
	xor XWA,XWA                                   ; F85F13  e8 d0
	ld (xiz-8), xwa                               ; F85F15  be f8 60   buffer[0..3] = 0
	ld (xiz-4), xwa                               ; F85F18  be fc 60   buffer[4..7] = 0
	lda xiy, (xiz-8)                              ; F85F1B  be f8 35   XIY = &buffer
	push XIY                                      ; F85F1E  3d
	pushw 0x00                                    ; F85F1F  0b 00 00
	calr DSP_WriteChannelRegs_FromTable           ; F85F22  1e 34 00
	push XIY                                      ; F85F25  3d
	pushw 0x01                                    ; F85F26  0b 01 00
	calr DSP_WriteChannelRegs_FromTable           ; F85F29  1e 2d 00
	push XIY                                      ; F85F2C  3d
	pushw 0x02                                    ; F85F2D  0b 02 00
	calr DSP_WriteChannelRegs_FromTable           ; F85F30  1e 26 00
	push XIY                                      ; F85F33  3d
	pushw 0x03                                    ; F85F34  0b 03 00
	calr DSP_WriteChannelRegs_FromTable           ; F85F37  1e 1f 00
	add XSP,0x00000018                            ; F85F3A  ef c8 18 00 00 00   drop 4 x (pointer + channel word)
	ld XBC,0x007f0000                             ; F85F40  41 00 00 7f 00   the DSP register file
	ld XWA,0x0101001f                             ; F85F45  40 1f 00 01 01   A = register 0x1F, +2 = 0x01
	ldb d, 0x04                                   ; F85F4A  24 04   four channels
DSP_Init_Channels_Loop:
	ld W,A                                        ; F85F4C  c9 88
	ld (XBC),XWA                                  ; F85F4E  b1 60
	add A,0x20                                    ; F85F50  c9 c8 20   next channel's window
	djnz8 d, DSP_Init_Channels_Loop               ; F85F53  cc 1c f6
	unlk XIZ                                      ; F85F56  ee 0d
	ret                                           ; F85F58  0e

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

; ==============================================================================
; 0xF8E54F-0xF8E6A1 -- the inter-processor link, receive side
; ==============================================================================
;
; Three routines that finish what INT0_LinkByte (0xF8E47F, converted above)
; starts.  Together with the transmit block at 0xF8E0FE-0xF8E31F (still
; .incbin) they decode the whole protocol on the link port at 0x7C0000; see
; notes/FINDINGS-interprocessor-link.md, which this block extends.
;
; ★ THE 0xE1 / 0xE2 PAIR IS A REMOTE BLOCK READ, and that is not a guess -- the
;   four routines agree field for field:
;
;     * INT0_LinkByte puts an 0xE2 message's TEN payload bytes at 0x600788
;       (0xF8E4D2-0xF8E4E8, converted above).
;     * Link_ServiceTask below reads exactly those ten bytes back as three
;       fields -- long (0x600788), word (0x600790), long (0x60078C) -- and
;       passes them to the 0xE1 transmitter at 0xF8E26F.
;     * That transmitter (0xF8E2BC-0xF8E2FE, disassembled, not converted) sends
;       a SIX-byte header built as long (0x6007A1) = its XIZ+0x0E argument and
;       word (0x6007A5) = its XIZ+0x0C argument, then a second micro-DMA burst
;       of (XIX+4) bytes read from (XIX) -- the XIZ+0x0C count and the XIZ+0x08
;       address.
;     * INTTC3_LinkDmaDone below, selector 2, takes the SIX bytes an 0xE1
;       message left at 0x6007D3 and feeds long (0x6007D3) to DMAD3 and word
;       (0x6007D7) to DMAC3 -- destination then count, the same two fields in
;       the same order.
;
;   So: 0xE2 = "send me <count> bytes from <src>, and put them at <dst> in your
;   memory"; 0xE1 = "here is a block: <dst>, <count>, then the bytes".
;   ⚠ What the blocks CONTAIN is not established.
;
; Three RAM bytes are error counters, one per failure mode, and nothing in this
; block ever reads them -- they only count:
;   (0x6007DB)  the 0xE5/0xE6 handshake at 0xF8E222 timed out (2500 ticks)
;   (0x6007DC)  Link_ServiceTask's stall watchdog aborted a receive
;   (0x6007E1)  Link_WaitBlockDone timed out (500 ticks)

; ---------------------------------------------------------------------
; INTTC3_LinkDmaDone -- micro-DMA channel 3 finished: a link message has landed
;
; Called from: vector slot 0x80 (0xFFFF80 holds 0x00F40EE8, a prom_b thunk whose
;          body is `jp 0xF8E54F`).  Byte-checked with notes/prom_a_xref.py, which
;          finds that thunk and no other site naming this address.
; Inputs:  (0x6007DA), the selector INT0_LinkByte set from the command byte;
;          (0x600780) the command byte itself; the payload the DMA just wrote.
; Outputs: depends on the selector, see the four arms below.  XBC, WA, XIY and
;          QWA are saved and restored; exits with RETI.
; Evidence: the vector slot is the name.  "Channel 3" rather than any other
;          channel: INT0_LinkByte arms channel 3 (it calls uDMA3_SetDest at
;          0xF8E6C9) and writes DMA3V, and INTTC3 is that channel's
;          transfer-complete interrupt.
; Unknown:  what the eight commands dispatched through the prom_b table mean;
;          the meaning of bit 7 of (0x600792) beyond "Link_ServiceTask acts on
;          it"; why selector 0 (set for command 0xE6) reaches none of these arms
;          and simply returns.
; ---------------------------------------------------------------------
INTTC3_LinkDmaDone:
	push XBC                                      ; F8E54F  39
	pushw wa                                      ; F8E550  28
	push XIY                                      ; F8E551  3d
	push QWA                                      ; F8E552  d7 e2 04
	ldw_da bc, (0x6007da)                         ; F8E555  d2 da 07 60 21   the selector INT0 left behind
	extz BC                                       ; F8E55A  d9 12
	cps bc, 0x01                                  ; F8E55C  d9 d9
	jr z, INTTC3_Sel1_GeneralCmd                  ; F8E55E  66 10
	cps bc, 0x02                                  ; F8E560  d9 da
	jr z, INTTC3_Sel2_ArmPayload                  ; F8E562  66 49
	cps bc, 0x03                                  ; F8E564  d9 db
	jr z, INTTC3_Sel3_ReadRequest                 ; F8E566  66 62
	cps bc, 0x04                                  ; F8E568  d9 dc
	jrl z, INTTC3_Sel4_BlockDone                  ; F8E56A  76 73 00
	jrl INTTC3__return                            ; F8E56D  78 7e 00

; --- selector 1: any command that was not 0xE1/0xE2/0xE6 -----------------
; The payload is at 0x6007B3 and is (cmd & 0x1F) + 1 bytes long -- the same
; length rule INT0_LinkByte used to arm the DMA.  The command's TOP THREE BITS
; pick a handler from an eight-entry LE32 table at prom_b 0xF57D4F; the two
; arguments (address, then length) are pushed and the handler is entered with a
; stack-argument TAIL JUMP whose return address is the `stib_da` below.
;   idx 0 0x00F57C3F   idx 1 0x00F57C2D   idx 2 0x00F8E000   idx 3 0x00F57C50
;   idx 4 0x00F57C61   idx 5 0x00F57C97   idx 6 0x00F57C72   idx 7 0x00F8E000
; All eight have a 0x00 high byte and land inside 0xF00000-0xFFFFFF, which is
; what says the table really is eight entries wide and not longer.
INTTC3_Sel1_GeneralCmd:
	lda_24 xbc, (0x6007b3)                        ; F8E570  f2 b3 07 60 31   arg 1: the payload buffer
	push XBC                                      ; F8E575  39
	ldb_da a, (0x600780)                          ; F8E576  c2 80 07 60 21
	and A,0x1f                                    ; F8E57B  c9 cc 1f
	extz WA                                       ; F8E57E  d8 12
	inc 1,WA                                      ; F8E580  d8 61   arg 2: (cmd & 0x1F) + 1 = the length
	pushw wa                                      ; F8E582  28
	ldb_da w, (0x600780)                          ; F8E583  c2 80 07 60 20
	srl w, 0x05                                   ; F8E588  c8 ef 05   the top three bits are the opcode
	ld C,W                                        ; F8E58B  c8 8b
	mul C,0x04                                    ; F8E58D  cb 08 04
	extz XBC                                      ; F8E590  e9 12
	add XBC,0x00f57d4f                            ; F8E592  e9 c8 4f 7d f5 00   prom_b, 8 x LE32
	ld XBC,(XBC)                                  ; F8E598  a1 21
	lda_24 xiy, (INTTC3_Sel1__resume)             ; F8E59A  f2 a2 e5 f8 35
	push XIY                                      ; F8E59F  3d   the handler's `ret` lands there
	jp (xbc)                                      ; F8E5A0  b1 d8
INTTC3_Sel1__resume:
	stib_da (0x6007da), 0x00                      ; F8E5A2  f2 da 07 60 00 00   the exchange is over
	set_dd8 0x01, 0x13                            ; F8E5A8  f0 13 b9   P7 bit 1 back to idle
	jr INTTC3__drop_args                          ; F8E5AB  68 19

; --- selector 2: an 0xE1 header arrived, so arm the DMA for its payload ---
; The six bytes at 0x6007D3 are {LE32 destination, LE16 count}; DMA3V = 0x0A
; re-points INT0's own vector at the DMA engine again so the block is absorbed
; without another interrupt, and selector 4 is what will see it finish.
INTTC3_Sel2_ArmPayload:
	ldw_da bc, (0x6007d7)                         ; F8E5AD  d2 d7 07 60 21   count
	pushw bc                                      ; F8E5B2  29
	ldl_da xbc, (0x6007d3)                        ; F8E5B3  e2 d3 07 60 21   destination
	push XBC                                      ; F8E5B8  39
	call uDMA3_SetDest                            ; F8E5B9  1d c9 e6 f8   DMAD3 := dest, DMAC3 := count
	ldio DMA3V, 0x0a                              ; F8E5BD  08 7f 0a   0x0A << 2 = 0x28 = INT0
	stib_da (0x6007da), 0x04                      ; F8E5C0  f2 da 07 60 00 04
INTTC3__drop_args:
	inc 6,XSP                                     ; F8E5C6  ef 66   drop the two pushed arguments
	jr INTTC3__return                             ; F8E5C8  68 24

; --- selector 3: an 0xE2 read request arrived --------------------------------
; The ten payload bytes are already at 0x600788.  This arm only flags them;
; Link_ServiceTask below is what answers, from the main-loop rota rather than
; from interrupt context.
INTTC3_Sel3_ReadRequest:
	stib_da (0x600781), 0xff                      ; F8E5CA  f2 81 07 60 00 ff
	stib_da (0x6007da), 0x00                      ; F8E5D0  f2 da 07 60 00 00
	set_dd8 0x01, 0x13                            ; F8E5D6  f0 13 b9   P7 bit 1 back to idle
	m_set 7, MD24, 0x600792                       ; F8E5D9  f2 92 07 60 bf   "an 0xE2 is pending"
	jr INTTC3__return                             ; F8E5DE  68 0e

; --- selector 4: the payload of an 0xE1 block finished arriving --------------
INTTC3_Sel4_BlockDone:
	stib_da (0x6007da), 0x00                      ; F8E5E0  f2 da 07 60 00 00
	m_res 7, MD24, 0x00008a                       ; F8E5E6  f2 8a 00 00 b7   release Link_WaitBlockDone
	set_dd8 0x01, 0x13                            ; F8E5EB  f0 13 b9   P7 bit 1 back to idle
INTTC3__return:
	pop QWA                                       ; F8E5EE  d7 e2 05
	pop XIY                                       ; F8E5F1  5d
	popw wa                                       ; F8E5F2  48
	pop XBC                                       ; F8E5F3  59
	reti                                          ; F8E5F4  07

; A lone 0x0E-style pad, except that this image pads interrupt code with the
; one-byte RETI (0x07) rather than the one-byte RET: nothing jumps to 0xF8E5F5
; -- notes/prom_a_xref.py finds no site naming it -- and the next routine starts
; on the following byte.
	reti                                          ; F8E5F5  07

; ---------------------------------------------------------------------
; Link_ServiceTask -- the link's main-loop half: answer 0xE2, watchdog the DMA
;
; Called from: prom_b thunk 0xF40ED8 (`jp 0xF8E5F6`), which prom_a calls at
;          0xF82165 -- inside a `tset 5,(0x88)` arm of the main-loop rota, so
;          this runs once per pass of that rota and not in interrupt context.
;          notes/prom_a_xref.py finds that one thunk and that one call site.
; Inputs:  bit 7 of (0x600792); P7 (0x13) bit 1; DMAC3; (0x6007DF)
; Outputs: an 0xE1 block transfer when an 0xE2 was pending; (0x6007DD) the
;          stall count; (0x6007DF) the previous DMAC3 sample; on abort, DMA3V=0,
;          (0x6007DA)=0, P7 bit 1 set and (0x6007DC) incremented.  XIX saved.
; Evidence: two halves, each named by what it reads.  The first reads the three
;          fields of the 0xE2 record at 0x600788/0x60078C/0x600790 -- exactly
;          the ten bytes INT0_LinkByte stores for command 0xE2 -- and hands them
;          to the 0xE1 transmitter.  The second samples the channel-3 transfer
;          counter through uDMA3_GetCount (0xF8E6DA, converted below, which
;          reads control register 0x2C = DMAC3) and gives up when eleven
;          consecutive samples are equal.
; Unknown:  what the three fields address; why the interrupt level is raised to
;          6 for the flag test and dropped to 0 afterwards.
; ---------------------------------------------------------------------
Link_ServiceTask:
	push XIX                                      ; F8E5F6  3c
	lda_24 xix, (0x6007dd)                        ; F8E5F7  f2 dd 07 60 34   XIX = &stall counter
	ei 0x06                                       ; F8E5FC  06 06
	m_bit 7, MD24, 0x600792                       ; F8E5FE  f2 92 07 60 cf   0xE2 pending?
	jr z, Link_ServiceTask__watchdog               ; F8E603  66 20
	m_res 7, MD24, 0x600792                       ; F8E605  f2 92 07 60 b7
	ei 0x00                                       ; F8E60A  06 00
	ldl_da xbc, (0x60078c)                        ; F8E60C  e2 8c 07 60 21   field 2: destination
	push XBC                                      ; F8E611  39
	ldw_da bc, (0x600790)                         ; F8E612  d2 90 07 60 21   field 3: count
	pushw bc                                      ; F8E617  29
	ldl_da xbc, (0x600788)                        ; F8E618  e2 88 07 60 21   field 1: source
	push XBC                                      ; F8E61D  39
	calr (0xF8E26F - 0xF8E621)                    ; F8E61E  1e 4e fc   the 0xE1 block transmitter
	inc 0,XSP                                     ; F8E621  ef 60   +8
	inc 2,XSP                                     ; F8E623  ef 62   +2 = the 10 argument bytes
Link_ServiceTask__watchdog:
	ei 0x00                                       ; F8E625  06 00
	bit_dd8 0x01, 0x13                            ; F8E627  f0 13 c9   P7 bit 1 set = nothing in flight
	jr nz, Link_ServiceTask__idle                 ; F8E62A  6e 1e
	call uDMA3_GetCount                           ; F8E62C  1d da e6 f8   WA := DMAC3
	cpdm16_24 (0x6007df), wa                      ; F8E630  d2 df 07 60 f8   same as last pass?
	jr nz, Link_ServiceTask__moved                ; F8E635  6e 04
	incm 0x01, (xix)                              ; F8E637  94 61   stalled: count it
	jr Link_ServiceTask__save                     ; F8E639  68 04
Link_ServiceTask__moved:
	m_ld_mi16 MDI+r4, 0, 0x0000                   ; F8E63B  b4 02 00 00   progress: reset the count
Link_ServiceTask__save:
	call uDMA3_GetCount                           ; F8E63F  1d da e6 f8
	stw_da (0x6007df), wa                         ; F8E643  f2 df 07 60 50
	jr Link_ServiceTask__check                    ; F8E648  68 04
Link_ServiceTask__idle:
	m_ld_mi16 MDI+r4, 0, 0x0000                   ; F8E64A  b4 02 00 00
Link_ServiceTask__check:
	ld BC,(XIX)                                   ; F8E64E  94 21
	cp BC,0x000a                                  ; F8E650  d9 cf 0a 00
	jr ule, Link_ServiceTask__done                ; F8E654  63 15
	m_ld_mi16 MDI+r4, 0, 0x0000                   ; F8E656  b4 02 00 00   eleven equal samples: abort
	ldio DMA3V, 0x00                              ; F8E65A  08 7f 00   un-point INT0 from the DMA engine
	stib_da (0x6007da), 0x00                      ; F8E65D  f2 da 07 60 00 00
	set_dd8 0x01, 0x13                            ; F8E663  f0 13 b9   P7 bit 1 back to idle
	incdi8_24 0x01, (0x6007dc)                    ; F8E666  c2 dc 07 60 61   error counter
Link_ServiceTask__done:
	pop XIX                                       ; F8E66B  5c
	ret                                           ; F8E66C  0e

; ---------------------------------------------------------------------
; Link_WaitBlockDone -- block until the pending link transfer finishes
;
; Called from: prom_b thunk 0xF4123C (`jp 0xF8E66D`).  notes/prom_a_xref.py
;          finds 22 candidate `call 0xF4123C` sites in prom_a; they are an
;          opcode-anchored upper bound, not verified instruction boundaries.
; Inputs:  bit 7 of (0x8A); the free-running tick counter (0x80), read 16-bit.
; Outputs: WA = 0 if the flag cleared in time, 0xFFFF if it did not.  On
;          timeout it also aborts the transfer: DMA3V = 0, (0x6007DA) = 0, P7
;          bit 1 set, bit 7 of (0x8A) cleared, (0x6007E1) incremented.  HL saved.
; Evidence: the flag is bit 7 of (0x8A), and a byte census of the five-byte
;          form `F2 8A 00 00 <op>` over prom_a and prom_b finds every site that
;          touches it: SET at 0xF8E16C and 0xF8E1EA -- both immediately after
;          micro-DMA channel 2 has been armed and timer 2 started, i.e. as an
;          outgoing transfer begins -- and CLEARED at 0xF8E25B, at
;          INTTC3_Sel4_BlockDone (0xF8E5E6) and here.  So the flag is "a link
;          transfer is outstanding" and this routine is the wait for it.
;          0x1F4 = 500 ticks of (0x80); INTT1_Tick (0xF82D0B) is what increments
;          (0x80), and notes/FINDINGS-system-clock.md derives its rate.
; Unknown:  which of the two SET sites the callers are actually waiting on --
;          this routine cannot tell them apart.
; ---------------------------------------------------------------------
Link_WaitBlockDone:
	pushw hl                                      ; F8E66D  2b
	m_ld_rm MW8, 0x80, r3                         ; F8E66E  d0 80 23   HL := the tick count at entry
Link_WaitBlockDone__poll:
	m_bit 7, MD24, 0x00008a                       ; F8E671  f2 8a 00 00 cf
	jr z, Link_WaitBlockDone__ok                  ; F8E676  66 26
	m_ld_rm MW8, 0x80, r1                         ; F8E678  d0 80 21
	sub BC,HL                                     ; F8E67B  db a1
	cp BC,0x01f4                                  ; F8E67D  d9 cf f4 01   500 ticks
	jr le, Link_WaitBlockDone__poll               ; F8E681  62 ee
	ldio DMA3V, 0x00                              ; F8E683  08 7f 00
	stib_da (0x6007da), 0x00                      ; F8E686  f2 da 07 60 00 00
	set_dd8 0x01, 0x13                            ; F8E68C  f0 13 b9
	m_res 7, MD24, 0x00008a                       ; F8E68F  f2 8a 00 00 b7
	incdi8_24 0x01, (0x6007e1)                    ; F8E694  c2 e1 07 60 61   error counter
	ldw wa, 0xffff                                ; F8E699  30 ff ff   timed out
	jr Link_WaitBlockDone__ret                    ; F8E69C  68 02
Link_WaitBlockDone__ok:
	sub WA,WA                                     ; F8E69E  d8 a0   WA = 0
Link_WaitBlockDone__ret:
	popw hl                                       ; F8E6A0  4b
	ret                                           ; F8E6A1  0e

; ==============================================================================
; 0xF8E6A2-0xF8E6F9 -- micro-DMA channel setup, and a word-at-a-time block copy
; ==============================================================================
;
; Eight one-line leaf routines around the TLCS-900 micro-DMA control registers.
; Their arguments come off the STACK, not in registers -- (XSP+4) is the first
; argument and (XSP+8) the second -- so they are compiler-called helpers, and the
; caller has to clean up (0xF8E171's `inc 6,XSP` is one such site).
;
; ⚠ THE SECOND ARGUMENT IS NOT THE SAME THING IN ALL FOUR SETTERS, and an
; earlier version of this block said it was ("the transfer count for the
; 'source' pair and the DMAM mode byte for the 'dest' pair" -- audit round 1,
; F8).  That holds for channel 2 and is exactly backwards for channel 3.  What
; each routine actually writes, read straight off the four bodies below:
;
;     routine            (XSP+4) ->        (XSP+8) ->
;     uDMA2_SetDest      DMAD2  0x18       DMAM2  0x2A   mode byte
;     uDMA2_SetSource    DMAS2  0x08       DMAC2  0x28   transfer count
;     uDMA3_SetSource    DMAS3  0x0C       DMAM3  0x2E   mode byte
;     uDMA3_SetDest      DMAD3  0x1C       DMAC3  0x2C   transfer count
;
; (control-register numbers as this file's own .equ block gives them, lines
; 367-382, and as they appear in the encoded third byte of every line below)
;
; So the mode byte rides with the SOURCE setter on channel 3 and with the
; DESTINATION setter on channel 2.  The names are taken from the first register
; each routine writes, which is the only part that is uniform.  Note also the
; operand widths agree with that table and not with the old sentence: the two
; mode writes load `C` (8-bit) and the two count writes load `BC` (16-bit).
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
; Called from: 0xF8E162 calls uDMA2_SetSource; INT0_LinkByte loads
;          `lda XIX,0xF8E6C9` at 0xF8E484 and reaches uDMA3_SetDest through
;          `jp (XIX)` -- see 0xF8E4C8/0xF8E4E7/0xF8E51D.  The rest not traced.
; Inputs:  (XSP+4) = a 32-bit address for the four setters, (XSP+8) = the second
;          argument.  ⚠ Which register that second argument lands in is
;          per-routine, not per-name -- see the table above the block.
; Outputs: the two named control registers per setter, the named one per getter.
;          BC/XBC clobbered.
; Notes:   the names are mechanical: each is named for the FIRST control register
;          it writes, and the four setters each write exactly two.
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
	ld (XIY),0x30                                 ; F8E826  b5 00 30   SYSTEM SET arg 1 = 0x30: internal CG ROM, 8-line chars, single-panel drive
	nop                                           ; F8E829  00
	nop                                           ; F8E82A  00
	nop                                           ; F8E82B  00
	nop                                           ; F8E82C  00
	ld (XIY),0x07                                 ; F8E82D  b5 00 07   SYSTEM SET arg 2, FX  = 7  -> 8 pixels per character cell
	nop                                           ; F8E830  00
	nop                                           ; F8E831  00
	nop                                           ; F8E832  00
	nop                                           ; F8E833  00
	ld (XIY),0x00                                 ; F8E834  b5 00 00   SYSTEM SET arg 3, FY  = 0  -> 1 line per cell (this is a graphics-only panel)
	nop                                           ; F8E837  00
	nop                                           ; F8E838  00
	nop                                           ; F8E839  00
	nop                                           ; F8E83A  00
	ld (XIY),0x27                                 ; F8E83B  b5 00 27   SYSTEM SET arg 4, C/R = 39 -> 40 bytes displayed per line = 320 pixels
	nop                                           ; F8E83E  00
	nop                                           ; F8E83F  00
	nop                                           ; F8E840  00
	nop                                           ; F8E841  00
	ld (XIY),0x35                                 ; F8E842  b5 00 35   SYSTEM SET arg 5, TC/R= 53 -> 54 byte-times per line total
	nop                                           ; F8E845  00
	nop                                           ; F8E846  00
	nop                                           ; F8E847  00
	nop                                           ; F8E848  00
	ld (XIY),0xef                                 ; F8E849  b5 00 ef   SYSTEM SET arg 6, L/F = 239 -> 240 lines
	nop                                           ; F8E84C  00
	nop                                           ; F8E84D  00
	nop                                           ; F8E84E  00
	nop                                           ; F8E84F  00
	ldb a, 0x28                                   ; F8E850  21 28   SYSTEM SET arg 7, APL = 0x28 -- virtual screen width, low byte
	ld (XIY),A                                    ; F8E852  b5 41
	stb_d8 (0x2557), a                            ; F8E854  f1 57 25 41
	nop                                           ; F8E858  00
	nop                                           ; F8E859  00
	nop                                           ; F8E85A  00
	ldb a, 0x00                                   ; F8E85B  21 00   SYSTEM SET arg 8, APH = 0x00 -> AP = 40 bytes per line
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
	ld (XIY),0x00                                 ; F8E875  b5 00 00   SAD1 high: display block 1 base = 0x0000 = firmware LAYER 0
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
	ld (XIY),0x26                                 ; F8E88A  b5 00 26   SAD2 high: display block 2 base = 0x2600 = firmware LAYER 1
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
	ld (XIY),0x4c                                 ; F8E89F  b5 00 4c   SAD3 high: display block 3 base = 0x4C00 = firmware LAYER 2.  SAD4 is not sent
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
; Layout:   64 entries, 256 bytes, 0xF8E9C6-0xF8EAC5.  34 of them are LIVE and
;           they name 34 DISTINCT routines; the other 30 -- slot 0x18 and every
;           slot from 0x23 up -- point at the bare RET that follows the table,
;           which is what makes the used range 0x00-0x22.
;           ⚠ CORRECTED 2026-08-24: this header said 35 live and 29 dead, and
;           notes/FINDINGS-display-controller.md said 35 too.  Both were counted
;           by hand and both were wrong.  Regenerate the numbers with
;           `python3 notes/swi7_service_table.py` (`--slots` for every slot);
;           it also checks that all 34 targets land inside prom_a and that the
;           byte after slot 0x3F is the 0x0E RET the dead slots point at.
; Notes:    every implemented service is in prom_a between 0xF8EAC7 and 0xF908FF
;           (the script prints that range) and every
;           one of them talks to the LCD controller at 0x790000/0x790001 --
;           directly, or through the shared setup at 0xF8EE93 that most of them
;           open with.  So SWI7 is, in this firmware, the GRAPHICS API.
;           ⚠ The one-line notes below are what each entry's FIRST FEW
;           INSTRUCTIONS do, nothing more.  They are a reading aid, not names;
;           slots that are still `.long <address>` have not been traced.
;           23 of the 34 live services are converted and named as of 2026-08-24
;           -- 0x00-0x0D, 0x13, 0x16, 0x19, 0x1A, 0x1D, 0x1F, 0x20, 0x21, 0x22.
;           Their entries below are real SYMBOLS, so the byte gate checks their
;           addresses.  Do not retype that list: `python3
;           notes/swi7_service_table.py` prints it, and prints the eleven still
;           `.incbin` (0x0E 0x0F 0x10 0x11 0x12 0x14 0x15 0x17 0x1B 0x1C 0x1E).
;           ★ TEN of the live slots -- 0x06 0x07 0x08 0x16 0x19 0x1A 0x1D 0x1F
;           0x20 0x21 -- are the TEXT services, one per font.  See the block
;           header at 0xF8F039 and notes/FINDINGS-fonts.md.
; ---------------------------------------------------------------------
SWI7_ServiceTable:
	.long LCD_Svc_00_DrawLine		; F8E9C6  c7 ea f8 00   svc 0x00
	.long LCD_Svc_01_DrawHLine		; F8E9CA  28 f5 f8 00   svc 0x01
	.long LCD_Svc_02_DrawVLine		; F8E9CE  39 f7 f8 00   svc 0x02
	.long LCD_Svc_03_BlitColumns	; F8E9D2  b4 ed f8 00   svc 0x03
	.long LCD_Svc_04_ReadColumns	; F8E9D6  23 ee f8 00   svc 0x04
	.long LCD_Svc_05_FillRect		; F8E9DA  bd ee f8 00   svc 0x05
	.long LCD_Svc_06_DrawText8x14	; F8E9DE  39 f0 f8 00   svc 0x06
	.long LCD_Svc_07_DrawText8x16	; F8E9E2  30 f1 f8 00   svc 0x07
	.long LCD_Svc_08_DrawText16x16	; F8E9E6  c3 f1 f8 00   svc 0x08
	.long LCD_Svc_09_DrawBox		; F8E9EA  a4 f3 f8 00   svc 0x09
	.long LCD_Svc_0A_DrawBoxShadow2	; F8E9EE  e1 f3 f8 00   svc 0x0A
	.long LCD_Svc_0B_PlotPoint	; F8E9F2  b5 ec f8 00   svc 0x0B
	.long LCD_Svc_0C_SetLayersOn	; F8E9F6  b8 f7 f8 00   svc 0x0C
	.long LCD_Svc_0D_SetLayersFlashing	; F8E9FA  01 f8 f8 00   svc 0x0D
	.long 0x00F8F850			; F8E9FE  50 f8 f8 00   svc 0x0E -- drives XIX
	.long 0x00F8FA60			; F8EA02  60 fa f8 00   svc 0x0F -- issues its own SYSTEM SET -- a re-configuration service
	.long 0x00F8FB7E			; F8EA06  7e fb f8 00   svc 0x10 -- issues its own SYSTEM SET -- a re-configuration service
	.long 0x00F8FCB2			; F8EA0A  b2 fc f8 00   svc 0x11 -- the PATTERNED horizontal run; opens exactly
				;       like svc 0x01 but fills from the 0xCC dither tables at
				;       0xF8FE52/0xF8FE5B via 0xF8FE39.  Not converted.
	.long 0x00F8FE80			; F8EA0E  80 fe f8 00   svc 0x12 -- the PATTERNED vertical run, the partner of
				;       svc 0x11.  Not converted.
	.long LCD_Svc_13_DrawBoxPatterned	; F8EA12  75 f4 f8 00   svc 0x13
	.long 0x00F8FEBC			; F8EA16  bc fe f8 00   svc 0x14 -- drives XIX, IY = 0
	.long 0x00F900B0			; F8EA1A  b0 00 f9 00   svc 0x15 -- same four setup calls as the line draw at slot 0x00
	.long LCD_Svc_16_DrawGlyphs8x14	; F8EA1E  a3 f0 f8 00   svc 0x16
	.long 0x00F90118			; F8EA22  18 01 f9 00   svc 0x17 -- BC = count, WA = 8
	.long LCD_Svc_Unimplemented		; F8EA26  c6 ea f8 00   svc 0x18
	.long LCD_Svc_19_DrawGlyphs16x16	; F8EA2A  8d f2 f8 00   svc 0x19
	.long LCD_Svc_1A_DrawGlyphs16x16	; F8EA2E  29 f2 f8 00   svc 0x1A
	.long 0x00F8F8BD			; F8EA32  bd f8 f8 00   svc 0x1B -- drives XIX, compares (0x2532) with (0x2536)
	.long 0x00F9025E			; F8EA36  5e 02 f9 00   svc 0x1C -- BC = count, WA = 16
	.long LCD_Svc_1D_DrawGlyphs16x16	; F8EA3A  bf f2 f8 00   svc 0x1D
	.long 0x00F908FF			; F8EA3E  ff 08 f9 00   svc 0x1E -- A = C & 0x0F -- takes a 4-bit argument
	.long LCD_Svc_1F_DrawGlyphs16x16	; F8EA42  5b f2 f8 00   svc 0x1F
	.long LCD_Svc_20_DrawText8x10	; F8EA46  6e f0 f8 00   svc 0x20
	.long LCD_Svc_21_DrawText16x24	; F8EA4A  f7 f1 f8 00   svc 0x21
	.long LCD_Svc_22_DrawBoxShadow1	; F8EA4E  b2 f4 f8 00   svc 0x22
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
; Called from: SWI7_ServiceTable slots 0x18 and 0x23-0x3F -- 30 slots, counted by
;          notes/swi7_service_table.py, not by hand
; Inputs:  none
; Outputs: none
; Notes:   a single RET.  Its address is what identifies the unused slots, and
;          the fact that the table's tail is entirely filled with it is what
;          shows the table really is 64 entries long rather than 35.
; ---------------------------------------------------------------------
LCD_Svc_Unimplemented:
	ret					; F8EAC6  0e

; ==============================================================================
; 0xF8EAC7-0xF8ECB4 -- SWI7 service 0x00: DRAW A LINE, and its six helpers
; ==============================================================================
;
; ★ SERVICE 0x00 IS A LINE DRAW, and the identification does not rest on any one
;   instruction:
;
;   1. THE CLAMP.  LCD_ClampCoordsToPanel (0xF8EB6B) limits two of its four
;      variables to 0x13F = 319 and the other two to 0xEF = 239 -- the exact
;      dimensions the SYSTEM SET parameters give (320 x 240, see
;      notes/FINDINGS-display-controller.md section 3, derived from completely
;      different bytes).  So (0x2530)/(0x2534) are X coordinates and
;      (0x2532)/(0x2536) are Y coordinates.
;   2. THE PAIRING.  Every helper reads them as two POINTS: 0xF8EB19 forms
;      (0x2534)-(0x2530) and (0x2536)-(0x2532), i.e. dx and dy; 0xF8EBF1 swaps
;      X with Y in both pairs at once; 0xF8EC4B and 0xF8EC83 each pick one whole
;      point by comparing the two X values.
;   3. THE PLOT.  The body's loop ends in `calr 0xF8ECCF`, which is
;      LCD_PlotPointAt -- already converted, already known to set one pixel from
;      (0x2550)/(0x2552) -- and the loop's only job is to fill in those two
;      words for each step.
;
;   So the two endpoints are (X0,Y0) = ((0x2530),(0x2532)) and (X1,Y1) =
;   ((0x2534),(0x2536)), and the service plots every pixel between them.
;
;   ⚠ NAMING.  An earlier version of these headers called the endpoints "P0" and
;   "P1" (audit round 1).  P1 and P7 are also TMP95C061 port SFRs named all over
;   this same file, and P1..P8 is also how the SED1330 datasheet numbers the
;   SYSTEM SET parameter bytes.  Endpoints are therefore always written
;   (X0,Y0)/(X1,Y1) here, port SFRs keep the bare Pn spelling, and the SED1330
;   command bytes are written "arg n".
;
; THE ARITHMETIC IS FIXED-POINT IN HUNDREDTHS.  The slope is kept as
; dy*100/dx in (0x2548) and the intercept as y*100 - m*x in (0x254A); a step
; recovers y as (m*x + b + 50)/100.  100 is the scale, 50 is the round-to-nearest
; half, and 0x64/0x32 appear nowhere else in the block.
;
; RAM this block establishes (all CS1 static RAM, 16-bit):
;   (0x2530) X0   (0x2532) Y0   (0x2534) X1   (0x2536) Y1  -- the caller's line
;   (0x2547) bit 0 = "X and Y have been swapped", the major-axis flag
;   (0x2548) slope * 100          (0x254A) intercept * 100
;   (0x2550)/(0x2552) the point being plotted -- LCD_PlotPointAt's input
;
; ⚠ NOT ESTABLISHED: who calls service 0x00 and how it sets (0x2530)-(0x2536);
;   no writer of those four words is converted yet.

; ---------------------------------------------------------------------
; LCD_Svc_00_DrawLine -- SWI7 service 0x00: draw a line between two points
;
; Called from: SWI7_ServiceTable slot 0x00 (0xF8E9C6)
; Inputs:  (0x2530),(0x2532) = (X0,Y0) and (0x2534),(0x2536) = (X1,Y1), in panel pixels;
;          (0x2540) selects the layer.
; Outputs: the pixels set (OR, never cleared -- LCD_PlotPointAt only ORs).
;          The four coordinate words are CLOBBERED: clamped, and swapped in place
;          when the line is steep.  IX, IY, WA, HL, DE clobbered.
; Evidence: see the block header above.
; Unknown:  whether the duplicate plot of the low-X endpoint (once by
;          LCD_Line_PlotLowXEnd before the loop, once by the loop's first
;          iteration) is deliberate.
; ---------------------------------------------------------------------
LCD_Svc_00_DrawLine:
	calr (0xF8EE93 - 0xF8EACA)                    ; F8EAC7  1e c9 03   LCD_SelectCurrentLayer
	calr (0xF8EB6B - 0xF8EACD)                    ; F8EACA  1e 9e 00   LCD_ClampCoordsToPanel
	calr (0xF8EB19 - 0xF8EAD0)                    ; F8EACD  1e 49 00   LCD_Line_ChooseMajorAxis
	calr (0xF8EC0A - 0xF8EAD3)                    ; F8EAD0  1e 37 01   LCD_Line_ComputeIntercept
	calr (0xF8EC4B - 0xF8EAD6)                    ; F8EAD3  1e 75 01   LCD_Line_PlotLowXEnd -- also sets IX/IY
LCD_Svc_00__step:
	ld WA,IX                                      ; F8EAD6  dc 88   IX = the current major coordinate
	cp WA,IY                                      ; F8EAD8  dd f0   IY = the last one
	jr nc, LCD_Svc_00__done                       ; F8EADA  6f 39
	m_muls MW16, 0x2548, r0                       ; F8EADC  d1 48 25 48   unidasm: muls XWA,(0x2548) -- x * slope
	m_add_rm MW16, 0x254a, r0                     ; F8EAE0  d1 4a 25 80   + the intercept
	bit 0x0f,WA                                   ; F8EAE4  d8 33 0f
	jr z, .LF8EAEB                                ; F8EAE7  66 02
	neg WA                                        ; F8EAE9  d8 07   ⚠ the sign is NOT restored below
.LF8EAEB:
	add WA,0x0032                                 ; F8EAEB  d8 c8 32 00   + 50, to round to nearest
	ldw bc, 0x64                                  ; F8EAEF  31 64 00
	exts XWA                                      ; F8EAF2  e8 13
	divs xwa, xbc                                 ; F8EAF4  d9 58   / 100 -- back to whole pixels
	m_bit 0, MD16, 0x2547                         ; F8EAF6  f1 47 25 c8   were X and Y swapped?
	jr nz, .LF8EB06                               ; F8EAFA  6e 0a
	stda16 (0x2552), wa                           ; F8EAFC  f1 52 25 50   no: the interpolant is Y
	stda16 (0x2550), ix                           ; F8EB00  f1 50 25 54       and the loop variable is X
	jr .LF8EB0E                                   ; F8EB04  68 08
.LF8EB06:
	stda16 (0x2550), wa                           ; F8EB06  f1 50 25 50   yes: the other way round
	stda16 (0x2552), ix                           ; F8EB0A  f1 52 25 54
.LF8EB0E:
	calr (0xF8ECCF - 0xF8EB11)                    ; F8EB0E  1e be 01   LCD_PlotPointAt
	inc 1,IX                                      ; F8EB11  dc 61
	jr LCD_Svc_00__step                           ; F8EB13  68 c1
LCD_Svc_00__done:
	calr (0xF8EC83 - 0xF8EB18)                    ; F8EB15  1e 6b 01   LCD_Line_PlotHighXEnd
	ret                                           ; F8EB18  0e

; ---------------------------------------------------------------------
; LCD_Line_ChooseMajorAxis -- pick the axis to step along, and set the slope
;
; Called from: LCD_Svc_00_DrawLine (0xF8EACD)
; Inputs:  the four coordinate words
; Outputs: (0x2548) = the slope; (0x2547) bit 0 = 1 when the coordinates have
;          been swapped; the four words themselves swapped in that case.
; Evidence: three arms, and each is the textbook case.  dx = 0 (a vertical line)
;          cannot have a slope, so it takes slope 0 and swaps the axes.  dy = 0
;          (horizontal) takes slope 0 and does not.  Otherwise the slope is
;          computed and, if |slope| > 100 -- steeper than 45 degrees, since the
;          scale is 100 -- the axes are swapped and the slope recomputed, which
;          is exactly the "step along the longer axis" rule.
; Unknown:  nothing outstanding.
; ---------------------------------------------------------------------
LCD_Line_ChooseMajorAxis:
	ldw_d16 wa, (0x2534)                          ; F8EB19  d1 34 25 20
	ldw_d16 hl, (0x2530)                          ; F8EB1D  d1 30 25 23
	sub WA,HL                                     ; F8EB21  db a0   dx = X1 - X0
	jr nz, .LF8EB33                               ; F8EB23  6e 0e
	stda16 (0x2548), wa                           ; F8EB25  f1 48 25 50   vertical: slope 0 ...
	m_or_mi8 MB16, 0x2547, 0x01                   ; F8EB29  c1 47 25 3e 01   ... and step along Y instead
	calr (0xF8EBF1 - 0xF8EB31)                    ; F8EB2E  1e c0 00   LCD_Line_SwapXY
	jr .LF8EB6A                                   ; F8EB31  68 37
.LF8EB33:
	ldw_d16 wa, (0x2536)                          ; F8EB33  d1 36 25 20
	ldw_d16 hl, (0x2532)                          ; F8EB37  d1 32 25 23
	sub WA,HL                                     ; F8EB3B  db a0   dy = Y1 - Y0
	jr nz, .LF8EB4A                               ; F8EB3D  6e 0b
	stda16 (0x2548), wa                           ; F8EB3F  f1 48 25 50   horizontal: slope 0
	m_and_mi8 MB16, 0x2547, 0xfe                  ; F8EB43  c1 47 25 3c fe
	jr .LF8EB6A                                   ; F8EB48  68 20
.LF8EB4A:
	m_and_mi8 MB16, 0x2547, 0xfe                  ; F8EB4A  c1 47 25 3c fe
	calr (0xF8EB9A - 0xF8EB52)                    ; F8EB4F  1e 48 00   LCD_Line_ComputeSlope
	bit 0x0f,WA                                   ; F8EB52  d8 33 0f
	jr z, .LF8EB59                                ; F8EB55  66 02
	neg WA                                        ; F8EB57  d8 07
.LF8EB59:
	cp WA,0x0064                                  ; F8EB59  d8 cf 64 00   |slope| > 1.00?
	jr ule, .LF8EB6A                              ; F8EB5D  63 0b
	m_or_mi8 MB16, 0x2547, 0x01                   ; F8EB5F  c1 47 25 3e 01   steep: step along Y
	calr (0xF8EBF1 - 0xF8EB67)                    ; F8EB64  1e 8a 00   LCD_Line_SwapXY
	calr (0xF8EB9A - 0xF8EB6A)                    ; F8EB67  1e 30 00   and redo the slope
.LF8EB6A:
	ret                                           ; F8EB6A  0e

; ---------------------------------------------------------------------
; LCD_ClampCoordsToPanel -- clip both endpoints to 320 x 240
;
; Called from: LCD_Svc_00_DrawLine (0xF8EACA) and LCD_Svc_0B_PlotPoint
;          (0xF8ECB8, converted below)
; Inputs:  (0x2530),(0x2534) X; (0x2532),(0x2536) Y
; Outputs: each clamped in place; WA clobbered.
; Evidence: ★ 0x13F = 319 and 0xEF = 239 are the panel's last column and last
;          row.  That is an INDEPENDENT confirmation of the geometry
;          notes/FINDINGS-display-controller.md derives from the SYSTEM SET
;          parameter bytes, and it is what identifies which two of the four
;          words are X and which are Y.
; Unknown:  ⚠ the comparison is UNSIGNED (`jr ule`), so a coordinate that is
;          negative as a 16-bit signed number is larger than the limit and comes
;          out clamped to 319 or 239 rather than to 0.  Whether callers can
;          produce a negative coordinate is not established.
; ---------------------------------------------------------------------
LCD_ClampCoordsToPanel:
	ldw wa, 0x013f                                ; F8EB6B  30 3f 01   319 = the last column
	m_cp_mr MW16, 0x2530, r0                      ; F8EB6E  d1 30 25 f8
	jr ule, .LF8EB78                              ; F8EB72  63 04
	stda16 (0x2530), wa                           ; F8EB74  f1 30 25 50
.LF8EB78:
	m_cp_mr MW16, 0x2534, r0                      ; F8EB78  d1 34 25 f8
	jr ule, .LF8EB82                              ; F8EB7C  63 04
	stda16 (0x2534), wa                           ; F8EB7E  f1 34 25 50
.LF8EB82:
	ldw wa, 0xef                                  ; F8EB82  30 ef 00   239 = the last row
	m_cp_mr MW16, 0x2532, r0                      ; F8EB85  d1 32 25 f8
	jr ule, .LF8EB8F                              ; F8EB89  63 04
	stda16 (0x2532), wa                           ; F8EB8B  f1 32 25 50
.LF8EB8F:
	m_cp_mr MW16, 0x2536, r0                      ; F8EB8F  d1 36 25 f8
	jr ule, .LF8EB99                              ; F8EB93  63 04
	stda16 (0x2536), wa                           ; F8EB95  f1 36 25 50
.LF8EB99:
	ret                                           ; F8EB99  0e

; ---------------------------------------------------------------------
; LCD_Line_ComputeSlope -- (0x2548) := round(dy * 100 / dx)
;
; Called from: LCD_Line_ChooseMajorAxis (0xF8EB4F and 0xF8EB67)
; Inputs:  the four coordinate words
; Outputs: (0x2548) = the slope in hundredths; WA = the same; IZ, HL, DE, XWA
;          clobbered.
; Evidence: the rounding is what makes it a slope rather than a difference: it
;          adds |dx|/2 to the numerator with the sign of dy before dividing,
;          which is round-half-away-from-zero, and then -- if the quotient came
;          out 0 with a non-zero remainder -- forces it to +1 or -1 so that a
;          shallow line still moves.  A firmware that only wanted dy/dx would do
;          none of that.
; Unknown:  nothing outstanding.
; ---------------------------------------------------------------------
LCD_Line_ComputeSlope:
	ldw_d16 wa, (0x2534)                          ; F8EB9A  d1 34 25 20
	ldw_d16 hl, (0x2530)                          ; F8EB9E  d1 30 25 23
	sub WA,HL                                     ; F8EBA2  db a0   dx
	pushw wa                                      ; F8EBA4  28
	bit 0x0f,WA                                   ; F8EBA5  d8 33 0f
	jr z, .LF8EBAC                                ; F8EBA8  66 02
	neg WA                                        ; F8EBAA  d8 07
.LF8EBAC:
	exts XWA                                      ; F8EBAC  e8 13
	ldw bc, 0x02                                  ; F8EBAE  31 02 00
	divs xwa, xbc                                 ; F8EBB1  d9 58   |dx| / 2 -- the rounding term
	ld IZ,WA                                      ; F8EBB3  d8 8e
	ldw_d16 wa, (0x2536)                          ; F8EBB5  d1 36 25 20
	ldw_d16 bc, (0x2532)                          ; F8EBB9  d1 32 25 21
	sub WA,BC                                     ; F8EBBD  d9 a0   dy
	exts XWA                                      ; F8EBBF  e8 13
	ldw bc, 0x64                                  ; F8EBC1  31 64 00
	muls xwa, xbc                                 ; F8EBC4  d9 48   dy * 100
	bit 0x0f,WA                                   ; F8EBC6  d8 33 0f
	jr nz, .LF8EBCF                               ; F8EBC9  6e 04
	add WA,IZ                                     ; F8EBCB  de 80   round away from zero ...
	jr .LF8EBD1                                   ; F8EBCD  68 02
.LF8EBCF:
	sub WA,IZ                                     ; F8EBCF  de a0   ... in whichever direction dy points
.LF8EBD1:
	popw hl                                       ; F8EBD1  4b   dx again
	exts XWA                                      ; F8EBD2  e8 13
	divs xwa, xhl                                 ; F8EBD4  db 58
	ld DE,QWA                                     ; F8EBD6  d7 e2 8a   DE = the remainder
	and WA,WA                                     ; F8EBD9  d8 c0
	jr nz, .LF8EBEC                               ; F8EBDB  6e 0f
	and DE,DE                                     ; F8EBDD  da c2
	jr z, .LF8EBEC                                ; F8EBDF  66 0b
	ldw wa, 0x01                                  ; F8EBE1  30 01 00   a slope that rounds to zero but is not
	bit 0x0f,DE                                   ; F8EBE4  da 33 0f   zero becomes +/- 1, so the line still moves
	jr z, .LF8EBEC                                ; F8EBE7  66 03
	ldw wa, 0xffff                                ; F8EBE9  30 ff ff
.LF8EBEC:
	stda16 (0x2548), wa                           ; F8EBEC  f1 48 25 50
	ret                                           ; F8EBF0  0e

; ---------------------------------------------------------------------
; LCD_Line_SwapXY -- exchange X with Y in BOTH endpoints
;
; Called from: LCD_Line_ChooseMajorAxis (0xF8EB2E and 0xF8EB64)
; Inputs/Outputs: (0x2530)<->(0x2532) and (0x2534)<->(0x2536); WA clobbered.
; Evidence: two `ex (addr),WA` pairs and nothing else.  It is always called
;          together with setting bit 0 of (0x2547), and every consumer of that
;          bit -- the step loop and both endpoint plotters -- reverses the
;          meaning of the two words it writes, which is what makes the flag and
;          this routine one mechanism.
; ---------------------------------------------------------------------
LCD_Line_SwapXY:
	ldw_d16 wa, (0x2530)                          ; F8EBF1  d1 30 25 20
	m_ex_mr MW16, 0x2532, r0                      ; F8EBF5  d1 32 25 30
	stda16 (0x2530), wa                           ; F8EBF9  f1 30 25 50
	ldw_d16 wa, (0x2534)                          ; F8EBFD  d1 34 25 20
	m_ex_mr MW16, 0x2536, r0                      ; F8EC01  d1 36 25 30
	stda16 (0x2534), wa                           ; F8EC05  f1 34 25 50
	ret                                           ; F8EC09  0e

; ---------------------------------------------------------------------
; LCD_Line_ComputeIntercept -- (0x254A) := the mean of the two endpoints' b
;
; Called from: LCD_Svc_00_DrawLine (0xF8EAD0)
; Inputs:  the four coordinate words and (0x2548), the slope
; Outputs: (0x254A) = intercept * 100; WA, HL, BC, XWA clobbered.
; Evidence: it computes (y*100 - m*x)/2 for (X0,Y0), stores it, the same for
;          (X1,Y1) and ADDS it -- i.e. the average of the value of b at the two ends.
;          b = y*100 - m*x is the line equation the step loop inverts
;          (`x*m + b + 50, /100`), so this is its intercept, and averaging both
;          ends is a way of halving the rounding error of the integer slope.
; Unknown:  nothing outstanding.
; ---------------------------------------------------------------------
LCD_Line_ComputeIntercept:
	ldw_d16 wa, (0x2530)                          ; F8EC0A  d1 30 25 20
	m_muls MW16, 0x2548, r0                       ; F8EC0E  d1 48 25 48   unidasm: muls XWA,(0x2548)
	ld HL,WA                                      ; F8EC12  d8 8b   m * X0
	ldw_d16 wa, (0x2532)                          ; F8EC14  d1 32 25 20
	ldw bc, 0x64                                  ; F8EC18  31 64 00
	muls xwa, xbc                                 ; F8EC1B  d9 48   Y0 * 100
	sub WA,HL                                     ; F8EC1D  db a0
	ldw bc, 0x02                                  ; F8EC1F  31 02 00
	exts XWA                                      ; F8EC22  e8 13
	divs xwa, xbc                                 ; F8EC24  d9 58   half of it
	stda16 (0x254a), wa                           ; F8EC26  f1 4a 25 50
	ldw_d16 wa, (0x2534)                          ; F8EC2A  d1 34 25 20
	m_muls MW16, 0x2548, r0                       ; F8EC2E  d1 48 25 48
	ld HL,WA                                      ; F8EC32  d8 8b   m * X1
	ldw_d16 wa, (0x2536)                          ; F8EC34  d1 36 25 20
	ldw bc, 0x64                                  ; F8EC38  31 64 00
	muls xwa, xbc                                 ; F8EC3B  d9 48   Y1 * 100
	sub WA,HL                                     ; F8EC3D  db a0
	ldw bc, 0x02                                  ; F8EC3F  31 02 00
	exts XWA                                      ; F8EC42  e8 13
	divs xwa, xbc                                 ; F8EC44  d9 58
	m_add_mr MW16, 0x254a, r0                     ; F8EC46  d1 4a 25 88   + the other half
	ret                                           ; F8EC4A  0e

; ---------------------------------------------------------------------
; LCD_Line_PlotLowXEnd -- plot the endpoint with the smaller X, and set IX/IY
;
; Called from: LCD_Svc_00_DrawLine (0xF8EAD3)
; Inputs:  the four coordinate words and (0x2547) bit 0
; Outputs: IX = the smaller X, IY = the larger -- which is what the step loop
;          then runs between; (0x2550)/(0x2552) = the plotted point; the pixel
;          set.  WA clobbered.
; Evidence: it compares (0x2530) with (0x2534) and keeps the smaller in IX
;          together with ITS OWN Y in WA, then writes the pair honouring the
;          swap flag and calls LCD_PlotPointAt.  The endpoints are plotted from
;          their exact coordinates rather than from the interpolation, so they
;          land where the caller asked even when the rounded slope would not put
;          them there.
; Unknown:  nothing outstanding.
; ---------------------------------------------------------------------
LCD_Line_PlotLowXEnd:
	ldw_d16 iy, (0x2530)                          ; F8EC4B  d1 30 25 25
	ldw_d16 ix, (0x2534)                          ; F8EC4F  d1 34 25 24
	ldw_d16 wa, (0x2536)                          ; F8EC53  d1 36 25 20
	cp IY,IX                                      ; F8EC57  dc f5
	jr ugt, .LF8EC67                              ; F8EC59  6b 0c
	ldw_d16 iy, (0x2534)                          ; F8EC5B  d1 34 25 25
	ldw_d16 ix, (0x2530)                          ; F8EC5F  d1 30 25 24
	ldw_d16 wa, (0x2532)                          ; F8EC63  d1 32 25 20
.LF8EC67:
	m_bit 0, MD16, 0x2547                         ; F8EC67  f1 47 25 c8
	jr nz, .LF8EC77                               ; F8EC6B  6e 0a
	stda16 (0x2552), wa                           ; F8EC6D  f1 52 25 50
	stda16 (0x2550), ix                           ; F8EC71  f1 50 25 54
	jr .LF8EC7F                                   ; F8EC75  68 08
.LF8EC77:
	stda16 (0x2550), wa                           ; F8EC77  f1 50 25 50
	stda16 (0x2552), ix                           ; F8EC7B  f1 52 25 54
.LF8EC7F:
	calr (0xF8ECCF - 0xF8EC82)                    ; F8EC7F  1e 4d 00   LCD_PlotPointAt
	ret                                           ; F8EC82  0e

; ---------------------------------------------------------------------
; LCD_Line_PlotHighXEnd -- plot the endpoint with the larger X
;
; Called from: LCD_Svc_00_DrawLine (0xF8EB15), after the step loop
; Inputs:  the four coordinate words and (0x2547) bit 0
; Outputs: (0x2550)/(0x2552) = that endpoint; the pixel set.  WA, HL clobbered.
; Evidence: the mirror of LCD_Line_PlotLowXEnd -- same comparison, opposite
;          arm kept -- and it is the last thing the service does, so the far end
;          of the line is drawn exactly rather than by interpolation.
; Unknown:  nothing outstanding.
; ---------------------------------------------------------------------
LCD_Line_PlotHighXEnd:
	ldw_d16 wa, (0x2530)                          ; F8EC83  d1 30 25 20
	ldw_d16 hl, (0x2532)                          ; F8EC87  d1 32 25 23
	m_cp_rm MW16, 0x2534, r0                      ; F8EC8B  d1 34 25 f0
	jr ugt, .LF8EC99                              ; F8EC8F  6b 08
	ldw_d16 wa, (0x2534)                          ; F8EC91  d1 34 25 20
	ldw_d16 hl, (0x2536)                          ; F8EC95  d1 36 25 23
.LF8EC99:
	m_bit 0, MD16, 0x2547                         ; F8EC99  f1 47 25 c8
	jr nz, .LF8ECA9                               ; F8EC9D  6e 0a
	stda16 (0x2552), hl                           ; F8EC9F  f1 52 25 53
	stda16 (0x2550), wa                           ; F8ECA3  f1 50 25 50
	jr .LF8ECB1                                   ; F8ECA7  68 08
.LF8ECA9:
	stda16 (0x2550), hl                           ; F8ECA9  f1 50 25 53
	stda16 (0x2552), wa                           ; F8ECAD  f1 52 25 50
.LF8ECB1:
	calr (0xF8ECCF - 0xF8ECB4)                    ; F8ECB1  1e 1b 00   LCD_PlotPointAt
	ret                                           ; F8ECB4  0e

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
	calr 0xfeb0                                   ; F8ECB8  1e b0 fe   -> LCD_ClampCoordsToPanel (0xF8EB6B)
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
; Called from: LCD_Svc_0B_PlotPoint (0xF8ECCB), and from all three plot sites of
;          the line draw -- LCD_Svc_00_DrawLine's step loop (0xF8EB0E),
;          LCD_Line_PlotLowXEnd (0xF8EC7F) and LCD_Line_PlotHighXEnd
;          (0xF8ECB1), all converted above.
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

; ==============================================================================
; 0xF8EDB4-0xF8EEBC -- SWI7 services 0x03 and 0x04, and the layer selector
; ==============================================================================
;
; ★ THE DRIVER'S BLOCK OPERATIONS ARE COLUMN-MAJOR.  Both services set CSRDIR
;   **DOWN** (0x4F) before the transfer and then, per iteration, run one CSRW +
;   MWRITE/MREAD burst of HL bytes and advance the starting address by ONE.
;   With the cursor auto-advancing downward, HL bytes with one burst is a
;   vertical COLUMN of HL bytes and "+1" is the next column to the right.
;   0x4F = CSRDIR DOWN is cited: ../mame/src/devices/video/sed1330.cpp:33, and
;   `sed1330_device::increment_csr` adds AP for that direction (sed1330.cpp:135).
;   This is also the correction described in notes/FINDINGS-display-controller.md
;   section 2 -- 0x4F was missing from the first command census.
;
; THE BUSY WAIT, which appears twenty-odd times below:
;       bit_dd8 0x00, 0xc6      ; (0xC6) bit 0 = "the panel is dark, do not poll"
;       jr nz, <past>
;   .w: bit 6,(XIZ)             ; 0x790000 bit 6 = BF, the controller's busy flag
;       jr nz, .w
;   MAME's `sed1330_device::status_r` returns `m_bf << 6` (sed1330.cpp:245-251).

; ---------------------------------------------------------------------
; LCD_Svc_03_BlitColumns -- SWI7 service 0x03: write a rectangle, column-major
;
; Called from: SWI7_ServiceTable slot 0x03 (0xF8E9D2)
; Inputs:  IX = byte offset of the top-left corner WITHIN the current layer;
;          BC = number of columns; HL = bytes down each column;
;          XIY = source data, read forwards.  (0x2540) selects the layer.
; Outputs: BC*HL bytes copied into display RAM; XIY advanced past the source;
;          WA, BC, E clobbered.  Returns immediately if BC or HL is zero.
; Evidence: the arithmetic and the command bytes.  `ld WA,IX` + `add WA,(0x2555)`
;          turns the caller's offset into an absolute display-RAM address by
;          adding the CURRENT LAYER'S BASE, which is exactly what
;          LCD_SelectCurrentLayer (called as the first instruction) has just put
;          in (0x2555).  The rest is CSRW (0x46) with that 16-bit address low
;          byte first, then MWRITE (0x42) and HL data bytes.
; Unknown:  nothing is checked against the panel's bounds, so the caller owns
;           clipping; which callers those are has not been traced.
; ---------------------------------------------------------------------
LCD_Svc_03_BlitColumns:
	calr (0xF8EE93 - 0xF8EDB7)                    ; F8EDB4  1e dc 00   LCD_SelectCurrentLayer
	ld XIZ,0x00790000                             ; F8EDB7  46 00 00 79 00
	bit_dd8 0x00, 0xc6                            ; F8EDBC  f0 c6 c8
	jr nz, .LF8EDC5                               ; F8EDBF  6e 04
.LF8EDC1:
	bit 6,(XIZ)                                   ; F8EDC1  b6 ce
	jr nz, .LF8EDC1                               ; F8EDC3  6e fc
.LF8EDC5:
	ld (XIZ+0x01),0x4f                            ; F8EDC5  be 01 00 4f   CSRDIR DOWN
	and BC,BC                                     ; F8EDC9  d9 c1
	jr z, LCD_Svc_03__ret                         ; F8EDCB  66 55   no columns
	and HL,HL                                     ; F8EDCD  db c3
	jr z, LCD_Svc_03__ret                         ; F8EDCF  66 51   no rows
	ld WA,IX                                      ; F8EDD1  dc 88
	m_add_rm MW16, 0x2555, r0                     ; F8EDD3  d1 55 25 80   + the layer base
LCD_Svc_03__column:
	bit_dd8 0x00, 0xc6                            ; F8EDD7  f0 c6 c8
	jr nz, .LF8EDE0                               ; F8EDDA  6e 04
.LF8EDDC:
	bit 6,(XIZ)                                   ; F8EDDC  b6 ce
	jr nz, .LF8EDDC                               ; F8EDDE  6e fc
.LF8EDE0:
	ld (XIZ+0x01),0x46                            ; F8EDE0  be 01 00 46   CSRW
	bit_dd8 0x00, 0xc6                            ; F8EDE4  f0 c6 c8
	jr nz, .LF8EDED                               ; F8EDE7  6e 04
.LF8EDE9:
	bit 6,(XIZ)                                   ; F8EDE9  b6 ce
	jr nz, .LF8EDE9                               ; F8EDEB  6e fc
.LF8EDED:
	ld (XIZ),A                                    ; F8EDED  b6 41   cursor address, low byte
	bit_dd8 0x00, 0xc6                            ; F8EDEF  f0 c6 c8
	jr nz, .LF8EDF8                               ; F8EDF2  6e 04
.LF8EDF4:
	bit 6,(XIZ)                                   ; F8EDF4  b6 ce
	jr nz, .LF8EDF4                               ; F8EDF6  6e fc
.LF8EDF8:
	ld (XIZ),W                                    ; F8EDF8  b6 40   cursor address, high byte
	bit_dd8 0x00, 0xc6                            ; F8EDFA  f0 c6 c8
	jr nz, .LF8EE03                               ; F8EDFD  6e 04
.LF8EDFF:
	bit 6,(XIZ)                                   ; F8EDFF  b6 ce
	jr nz, .LF8EDFF                               ; F8EE01  6e fc
.LF8EE03:
	ld (XIZ+0x01),0x42                            ; F8EE03  be 01 00 42   MWRITE
	pushw bc                                      ; F8EE07  29
	ld BC,HL                                      ; F8EE08  db 89   the inner count is HL
LCD_Svc_03__byte:
	ld E,(XIY)                                    ; F8EE0A  85 25
	inc 1,XIY                                     ; F8EE0C  ed 61
	bit_dd8 0x00, 0xc6                            ; F8EE0E  f0 c6 c8
	jr nz, .LF8EE17                               ; F8EE11  6e 04
.LF8EE13:
	bit 6,(XIZ)                                   ; F8EE13  b6 ce
	jr nz, .LF8EE13                               ; F8EE15  6e fc
.LF8EE17:
	ld (XIZ),E                                    ; F8EE17  b6 45   one byte of display RAM
	djnz16 bc, LCD_Svc_03__byte                   ; F8EE19  d9 1c ee
	popw bc                                       ; F8EE1C  49
	inc 1,WA                                      ; F8EE1D  d8 61   the next column starts one byte along
	djnz16 bc, LCD_Svc_03__column                 ; F8EE1F  d9 1c b5
LCD_Svc_03__ret:
	ret                                           ; F8EE22  0e

; ---------------------------------------------------------------------
; LCD_Svc_04_ReadColumns -- SWI7 service 0x04: read a rectangle back, column-major
;
; Called from: SWI7_ServiceTable slot 0x04 (0xF8E9D6)
; Inputs:  IX, BC, HL as for service 0x03; XIY = the DESTINATION buffer.
; Outputs: BC*HL bytes copied out of display RAM into (XIY); XIY advanced.
; Evidence: instruction for instruction the same routine as service 0x03 with
;          MWRITE (0x42) replaced by MREAD (0x43) and the inner body reversed --
;          `ld E,(XIZ+0x01)` (read the DATA port at 0x790001) then
;          `ld (XIY),E`, where 0x03 has `ld E,(XIY)` then `ld (XIZ),E`.
;          The read/write asymmetry of the port pair is the reason the register
;          offsets differ: reading data is 0x790001, writing data is 0x790000
;          (notes/FINDINGS-display-controller.md section 1).
; Unknown:  as service 0x03.
; ---------------------------------------------------------------------
LCD_Svc_04_ReadColumns:
	calr (0xF8EE93 - 0xF8EE26)                    ; F8EE23  1e 6d 00   LCD_SelectCurrentLayer
	ld XIZ,0x00790000                             ; F8EE26  46 00 00 79 00
	bit_dd8 0x00, 0xc6                            ; F8EE2B  f0 c6 c8
	jr nz, .LF8EE34                               ; F8EE2E  6e 04
.LF8EE30:
	bit 6,(XIZ)                                   ; F8EE30  b6 ce
	jr nz, .LF8EE30                               ; F8EE32  6e fc
.LF8EE34:
	ld (XIZ+0x01),0x4f                            ; F8EE34  be 01 00 4f   CSRDIR DOWN
	and BC,BC                                     ; F8EE38  d9 c1
	jr z, LCD_Svc_04__ret                         ; F8EE3A  66 56
	and HL,HL                                     ; F8EE3C  db c3
	jr z, LCD_Svc_04__ret                         ; F8EE3E  66 52
	ld WA,IX                                      ; F8EE40  dc 88
	m_add_rm MW16, 0x2555, r0                     ; F8EE42  d1 55 25 80   + the layer base
LCD_Svc_04__column:
	bit_dd8 0x00, 0xc6                            ; F8EE46  f0 c6 c8
	jr nz, .LF8EE4F                               ; F8EE49  6e 04
.LF8EE4B:
	bit 6,(XIZ)                                   ; F8EE4B  b6 ce
	jr nz, .LF8EE4B                               ; F8EE4D  6e fc
.LF8EE4F:
	ld (XIZ+0x01),0x46                            ; F8EE4F  be 01 00 46   CSRW
	bit_dd8 0x00, 0xc6                            ; F8EE53  f0 c6 c8
	jr nz, .LF8EE5C                               ; F8EE56  6e 04
.LF8EE58:
	bit 6,(XIZ)                                   ; F8EE58  b6 ce
	jr nz, .LF8EE58                               ; F8EE5A  6e fc
.LF8EE5C:
	ld (XIZ),A                                    ; F8EE5C  b6 41
	bit_dd8 0x00, 0xc6                            ; F8EE5E  f0 c6 c8
	jr nz, .LF8EE67                               ; F8EE61  6e 04
.LF8EE63:
	bit 6,(XIZ)                                   ; F8EE63  b6 ce
	jr nz, .LF8EE63                               ; F8EE65  6e fc
.LF8EE67:
	ld (XIZ),W                                    ; F8EE67  b6 40
	bit_dd8 0x00, 0xc6                            ; F8EE69  f0 c6 c8
	jr nz, .LF8EE72                               ; F8EE6C  6e 04
.LF8EE6E:
	bit 6,(XIZ)                                   ; F8EE6E  b6 ce
	jr nz, .LF8EE6E                               ; F8EE70  6e fc
.LF8EE72:
	ld (XIZ+0x01),0x43                            ; F8EE72  be 01 00 43   MREAD
	pushw bc                                      ; F8EE76  29
	ld BC,HL                                      ; F8EE77  db 89
LCD_Svc_04__byte:
	bit_dd8 0x00, 0xc6                            ; F8EE79  f0 c6 c8
	jr nz, .LF8EE82                               ; F8EE7C  6e 04
.LF8EE7E:
	bit 6,(XIZ)                                   ; F8EE7E  b6 ce
	jr nz, .LF8EE7E                               ; F8EE80  6e fc
.LF8EE82:
	ld E,(XIZ+0x01)                               ; F8EE82  8e 01 25   the DATA port when READING
	ld (XIY),E                                    ; F8EE85  b5 45
	inc 1,XIY                                     ; F8EE87  ed 61
	djnz16 bc, LCD_Svc_04__byte                   ; F8EE89  d9 1c ed
	popw bc                                       ; F8EE8C  49
	inc 1,WA                                      ; F8EE8D  d8 61
	djnz16 bc, LCD_Svc_04__column                 ; F8EE8F  d9 1c b4
LCD_Svc_04__ret:
	ret                                           ; F8EE92  0e

; ---------------------------------------------------------------------
; LCD_SelectCurrentLayer -- (0x2555) := the display-RAM base of layer (0x2540)
;
; Called from: nearly every SWI7 service opens with it -- 0xF8EDB4 and 0xF8EE23
;          here, and the display-controller note lists the rest.
; Inputs:  (0x2540), a layer number.
; Outputs: (0x2555) = the 16-bit display-RAM base address of that layer.
;          XHL and XIX are saved and restored, so it clobbers only WA.
; Evidence: ★ THIS IS WHAT (0x2555) IS, and the three-entry table below is what
;          proves it.  The table holds pointers to (0x2541), (0x2543) and
;          (0x2545) -- and those are exactly the three RAM words that
;          LCD_Init_SED1330 (0xF8E819, converted) writes the SCROLL command's
;          SAD1, SAD2 and SAD3 into, i.e. the base addresses of the three
;          OR-composited graphics layers.  So (0x2540) is the layer number and
;          this routine dereferences it into the base every drawing service then
;          adds to its caller's offset.
; Unknown:  what sets (0x2540); no writer of it is converted yet.
; ---------------------------------------------------------------------
LCD_SelectCurrentLayer:
	push XHL                                      ; F8EE93  3b
	push XIX                                      ; F8EE94  3c
	xor H,H                                       ; F8EE95  ce d6
	ldb_d8 l, (0x2540)                            ; F8EE97  c1 40 25 27   the layer number
	sla hl, 0x02                                  ; F8EE9B  db ec 02   * 4
	ld XIX,0x00f8eeb1                             ; F8EE9E  44 b1 ee f8 00   the table below
	.byte 0xe3, 0x07, 0xf0, 0xec, 0x23            ; F8EEA3  e3 07 f0 ec 23   ld XHL,(XIX+HL) -- llvm-mc has no spelling
	ld WA,(XHL)                                   ; F8EEA8  93 20   the SAD word it points at
	stda16 (0x2555), wa                           ; F8EEAA  f1 55 25 50
	pop XIX                                       ; F8EEAE  5c
	pop XHL                                       ; F8EEAF  5b
	ret                                           ; F8EEB0  0e

; ---------------------------------------------------------------------
; LCD_LayerBasePtr_Table -- 3 x LE32: where each layer's base address is kept
;
; Read by:  LCD_SelectCurrentLayer (0xF8EE9E), indexed by (0x2540)*4.
; Layout:   3 entries, 12 bytes, 0xF8EEB1-0xF8EEBC.  Each entry is a 32-bit
;           POINTER to a 16-bit RAM word, not a base address itself.
; Count:    exactly three, and the proof is arithmetic rather than a guess --
;           0xF8EEB1 + 3*4 = 0xF8EEBD, which is the address SWI7_ServiceTable
;           slot 0x05 holds (0xF8E9DA = 0x00F8EEBD).  A fourth entry would
;           overlap the next service's first instruction.
; Evidence: the three targets are (0x2541), (0x2543) and (0x2545), the three
;           words LCD_Init_SED1330 fills with SAD1/SAD2/SAD3 from the SCROLL
;           command -- see notes/FINDINGS-display-controller.md section 3.
;
; ★ TWO NUMBERINGS, AND THIS FILE USED TO MIX THEM (audit round 1, F7).  The
;   SED1330's own registers are 1-based -- SAD1..SAD4, which MAME logs as
;   "Display Page 1/2 Start Address" (../mame/src/devices/video/sed1330.cpp:459
;   and :473).  The FIRMWARE's layer selector (0x2540) is 0-based, because
;   LCD_SelectCurrentLayer indexes this table with (0x2540)*4 and the table has
;   three entries.  The rule adopted from here on, and applied to the
;   LCD_Init_SED1330 comments above and to LCD_Svc_05_FillRect below:
;
;       firmware layer 0  =  SAD1  =  display-RAM 0x0000
;       firmware layer 1  =  SAD2  =  display-RAM 0x2600
;       firmware layer 2  =  SAD3  =  display-RAM 0x4C00
;
;   Anything written as a bare "layer N" in this file means the FIRMWARE index.
;   SAD/display-block numbers are always spelled SADn.
; ---------------------------------------------------------------------
LCD_LayerBasePtr_Table:
	.long 0x00002541			; F8EEB1  41 25 00 00   layer 0 -> SAD1 = 0x0000
	.long 0x00002543			; F8EEB5  43 25 00 00   layer 1 -> SAD2 = 0x2600
	.long 0x00002545			; F8EEB9  45 25 00 00   layer 2 -> SAD3 = 0x4C00

; ==============================================================================
; 0xF8EEBD-0xF8F038 -- SWI7 service 0x05: fill a rectangle
; ==============================================================================

; ---------------------------------------------------------------------
; LCD_Svc_05_FillRect -- SWI7 service 0x05: fill the box between (X0,Y0) and (X1,Y1)
;
; Called from: SWI7_ServiceTable slot 0x05 (0xF8E9DA)
; Inputs:  (0x2530),(0x2532) = (X0,Y0) and (0x2534),(0x2536) = (X1,Y1), the same four
;          coordinate words the line draw uses -- it calls the same
;          LCD_ClampCoordsToPanel to clip them.  (0x2554) = the OVLAY shadow.
; Outputs: every pixel of the box set in firmware LAYER 1, i.e. the SED1330
;          display block 2 whose base SAD2 = 0x2600 (see the numbering note in
;          the LCD_LayerBasePtr_Table header); (0x2540) forced to 1;
;          (0x255A) left holding the last column's cursor address; the OVLAY
;          register reprogrammed.  WA, BC, DE, HL, XIX clobbered.
; Evidence: three things together, none of them a guess:
;          1. it walks the SAME four coordinate words as LCD_Svc_00_DrawLine and
;             clips them with the same routine, so the two are opposite corners;
;          2. the height it counts out for every column is (0x2536)-(0x2532)+1
;             and the width it divides by 8 is (0x2534)-(0x2530)+1 -- inclusive
;             spans in Y and X;
;          3. the middle of the box is written as whole 0xFF bytes and the two
;             ends through the masks at 0xF8F79B and 0xF8F7AF, which is what
;             filling a byte-addressed bitmap looks like when the edges do not
;             fall on byte boundaries.
;          ⚠ The first thing it does after selecting the layer is issue OVLAY
;          with the MX field forced to 1.  MAME names MX=1 "Exclusive-OR"
;          (../mame/src/devices/video/sed1330.cpp:49) and leaves it
;          unimplemented, so the NAME is cited but the BEHAVIOUR is not.  Filling
;          layer 1 with 0xFF while the composition is XOR would invert whatever
;          the other layers show there -- that is a READING of those two facts,
;          offered as such, not a measurement.
; Unknown:  why this service, alone among those converted, forces the layer
;          instead of using the caller's (0x2540); what (0x2554) is otherwise
;          for; who calls it.
; ---------------------------------------------------------------------
LCD_Svc_05_FillRect:
	stdi8 (0x2540), 0x01                          ; F8EEBD  f1 40 25 00 01   force firmware layer 1 = SAD2 = 0x2600
	calr (0xF8EE93 - 0xF8EEC5)                    ; F8EEC2  1e ce ff   LCD_SelectCurrentLayer
	calr (0xF8EB6B - 0xF8EEC8)                    ; F8EEC5  1e a3 fc   LCD_ClampCoordsToPanel
	ld XIX,0x00790000                             ; F8EEC8  44 00 00 79 00
	ld (XIX+0x01),0x5b                            ; F8EECD  bc 01 00 5b   OVLAY
	ldb_d8 a, (0x2554)                            ; F8EED1  c1 54 25 21
	and A,0xfc                                    ; F8EED5  c9 cc fc
	or A,0x01                                     ; F8EED8  c9 ce 01   MX = 1 = Exclusive-OR (sed1330.cpp:49)
	bit_dd8 0x00, 0xc6                            ; F8EEDB  f0 c6 c8
	jr nz, .LF8EEE4                               ; F8EEDE  6e 04
.LF8EEE0:
	bit 6,(XIX)                                   ; F8EEE0  b4 ce
	jr nz, .LF8EEE0                               ; F8EEE2  6e fc
.LF8EEE4:
	ld (XIX),A                                    ; F8EEE4  b4 41
	ldw_d16 wa, (0x2532)                          ; F8EEE6  d1 32 25 20
	ldw_d16 bc, (0x2557)                          ; F8EEEA  d1 57 25 21
	mul xwa, xbc                                  ; F8EEEE  d9 40   Y0 * AP
	ld HL,WA                                      ; F8EEF0  d8 8b
	ldw_d16 wa, (0x2530)                          ; F8EEF2  d1 30 25 20
	extz XWA                                      ; F8EEF6  e8 12
	ldw bc, 0x08                                  ; F8EEF8  31 08 00
	div xwa, xbc                                  ; F8EEFB  d9 50   XWA = X0/8, QWA = X0 mod 8
	ld DE,QWA                                     ; F8EEFD  d7 e2 8a   DE = the bit offset into the first byte
	add HL,WA                                     ; F8EF00  d8 83
	ldw_d16 wa, (0x2555)                          ; F8EF02  d1 55 25 20
	add WA,HL                                     ; F8EF06  db 80   + the layer base -> the display-RAM address
	stda16 (0x255a), wa                           ; F8EF08  f1 5a 25 50   (0x255A) = this column's cursor address
	bit_dd8 0x00, 0xc6                            ; F8EF0C  f0 c6 c8
	jr nz, .LF8EF15                               ; F8EF0F  6e 04
.LF8EF11:
	bit 6,(XIX)                                   ; F8EF11  b4 ce
	jr nz, .LF8EF11                               ; F8EF13  6e fc
.LF8EF15:
	ld (XIX+0x01),0x4f                            ; F8EF15  bc 01 00 4f   CSRDIR DOWN -- columns, not rows
	and DE,DE                                     ; F8EF19  da c2
	jr z, LCD_Svc_05__fullcols                                ; F8EF1B  66 58
	bit_dd8 0x00, 0xc6                            ; F8EF1D  f0 c6 c8
	jr nz, .LF8EF26                               ; F8EF20  6e 04
.LF8EF22:
	bit 6,(XIX)                                   ; F8EF22  b4 ce
	jr nz, .LF8EF22                               ; F8EF24  6e fc
.LF8EF26:
	ld (XIX+0x01),0x46                            ; F8EF26  bc 01 00 46
	bit_dd8 0x00, 0xc6                            ; F8EF2A  f0 c6 c8
	jr nz, .LF8EF33                               ; F8EF2D  6e 04
.LF8EF2F:
	bit 6,(XIX)                                   ; F8EF2F  b4 ce
	jr nz, .LF8EF2F                               ; F8EF31  6e fc
.LF8EF33:
	ld (XIX),A                                    ; F8EF33  b4 41
	bit_dd8 0x00, 0xc6                            ; F8EF35  f0 c6 c8
	jr nz, .LF8EF3E                               ; F8EF38  6e 04
.LF8EF3A:
	bit 6,(XIX)                                   ; F8EF3A  b4 ce
	jr nz, .LF8EF3A                               ; F8EF3C  6e fc
.LF8EF3E:
	ld (XIX),W                                    ; F8EF3E  b4 40
	inc 1,WA                                      ; F8EF40  d8 61
	stda16 (0x255a), wa                           ; F8EF42  f1 5a 25 50
	calr (0xF8F767 - 0xF8EF49)                    ; F8EF46  1e 1e 08   LCD_Rect_LeftEdgeMask -> A
	bit_dd8 0x00, 0xc6                            ; F8EF49  f0 c6 c8
	jr nz, .LF8EF52                               ; F8EF4C  6e 04
.LF8EF4E:
	bit 6,(XIX)                                   ; F8EF4E  b4 ce
	jr nz, .LF8EF4E                               ; F8EF50  6e fc
.LF8EF52:
	ld (XIX+0x01),0x42                            ; F8EF52  bc 01 00 42
	ldw_d16 bc, (0x2536)                          ; F8EF56  d1 36 25 21
	m_sub_rm MW16, 0x2532, r1                     ; F8EF5A  d1 32 25 a1
	inc 1,BC                                      ; F8EF5E  d9 61   BC = Y1 - Y0 + 1, the height in rows
LCD_Svc_05__leftrow:
	bit_dd8 0x00, 0xc6                            ; F8EF60  f0 c6 c8
	jr nz, .LF8EF69                               ; F8EF63  6e 04
.LF8EF65:
	bit 6,(XIX)                                   ; F8EF65  b4 ce
	jr nz, .LF8EF65                               ; F8EF67  6e fc
.LF8EF69:
	ld (XIX),A                                    ; F8EF69  b4 41
	djnz16 bc, LCD_Svc_05__leftrow                           ; F8EF6B  d9 1c f2
	ldw hl, 0x08                                  ; F8EF6E  33 08 00
	sub HL,DE                                     ; F8EF71  da a3
	ex16 hl, de                                   ; F8EF73  da bb
; --- the whole-byte middle, and how much of it there is ----------------------
; DE arrives holding 8 - (X0 mod 8): the number of pixels the partial first
; column already covered.  If the box is no wider than that it is finished.
LCD_Svc_05__fullcols:
	ldw_d16 wa, (0x2534)                          ; F8EF75  d1 34 25 20
	m_sub_rm MW16, 0x2530, r0                     ; F8EF79  d1 30 25 a0
	inc 1,WA                                      ; F8EF7D  d8 61
	cp WA,DE                                      ; F8EF7F  da f0
	jrl ule, LCD_Svc_05__ret                             ; F8EF81  73 b4 00
	sub WA,DE                                     ; F8EF84  da a0
	ldw bc, 0x08                                  ; F8EF86  31 08 00
	extz XWA                                      ; F8EF89  e8 12
	divs xwa, xbc                                 ; F8EF8B  d9 58
	ld DE,QWA                                     ; F8EF8D  d7 e2 8a
	and WA,WA                                     ; F8EF90  d8 c0
	jr z, LCD_Svc_05__rightedge                                ; F8EF92  66 5a
	ld BC,WA                                      ; F8EF94  d8 89

; --- one whole byte-column of the middle, repeated (0x2534)-(0x2530)+1 / 8 ---
LCD_Svc_05__fullcol:
	bit_dd8 0x00, 0xc6                            ; F8EF96  f0 c6 c8
	jr nz, .LF8EF9F                               ; F8EF99  6e 04
.LF8EF9B:
	bit 6,(XIX)                                   ; F8EF9B  b4 ce
	jr nz, .LF8EF9B                               ; F8EF9D  6e fc
.LF8EF9F:
	ld (XIX+0x01),0x46                            ; F8EF9F  bc 01 00 46
	ldw_d16 wa, (0x255a)                          ; F8EFA3  d1 5a 25 20
	bit_dd8 0x00, 0xc6                            ; F8EFA7  f0 c6 c8
	jr nz, .LF8EFB0                               ; F8EFAA  6e 04
.LF8EFAC:
	bit 6,(XIX)                                   ; F8EFAC  b4 ce
	jr nz, .LF8EFAC                               ; F8EFAE  6e fc
.LF8EFB0:
	ld (XIX),A                                    ; F8EFB0  b4 41
	bit_dd8 0x00, 0xc6                            ; F8EFB2  f0 c6 c8
	jr nz, .LF8EFBB                               ; F8EFB5  6e 04
.LF8EFB7:
	bit 6,(XIX)                                   ; F8EFB7  b4 ce
	jr nz, .LF8EFB7                               ; F8EFB9  6e fc
.LF8EFBB:
	ld (XIX),W                                    ; F8EFBB  b4 40
	inc 1,WA                                      ; F8EFBD  d8 61
	stda16 (0x255a), wa                           ; F8EFBF  f1 5a 25 50
	bit_dd8 0x00, 0xc6                            ; F8EFC3  f0 c6 c8
	jr nz, .LF8EFCC                               ; F8EFC6  6e 04
.LF8EFC8:
	bit 6,(XIX)                                   ; F8EFC8  b4 ce
	jr nz, .LF8EFC8                               ; F8EFCA  6e fc
.LF8EFCC:
	ld (XIX+0x01),0x42                            ; F8EFCC  bc 01 00 42
	pushw bc                                      ; F8EFD0  29
	ldw_d16 bc, (0x2536)                          ; F8EFD1  d1 36 25 21
	m_sub_rm MW16, 0x2532, r1                     ; F8EFD5  d1 32 25 a1
	inc 1,BC                                      ; F8EFD9  d9 61
LCD_Svc_05__fullrow:
	bit_dd8 0x00, 0xc6                            ; F8EFDB  f0 c6 c8
	jr nz, .LF8EFE4                               ; F8EFDE  6e 04
.LF8EFE0:
	bit 6,(XIX)                                   ; F8EFE0  b4 ce
	jr nz, .LF8EFE0                               ; F8EFE2  6e fc
.LF8EFE4:
	ld (XIX),0xff                                 ; F8EFE4  b4 00 ff   a whole byte of pixels
	djnz16 bc, LCD_Svc_05__fullrow                           ; F8EFE7  d9 1c f1
	popw bc                                       ; F8EFEA  49
	djnz16 bc, LCD_Svc_05__fullcol                           ; F8EFEB  d9 1c a8
; --- the partial LAST column, if the box does not end on a byte boundary -----
LCD_Svc_05__rightedge:
	and DE,DE                                     ; F8EFEE  da c2
	jr z, LCD_Svc_05__ret                                ; F8EFF0  66 46
	bit_dd8 0x00, 0xc6                            ; F8EFF2  f0 c6 c8
	jr nz, .LF8EFFB                               ; F8EFF5  6e 04
.LF8EFF7:
	bit 6,(XIX)                                   ; F8EFF7  b4 ce
	jr nz, .LF8EFF7                               ; F8EFF9  6e fc

.LF8EFFB:
	ld (XIX+0x01),0x46                            ; F8EFFB  bc 01 00 46
	ldw_d16 wa, (0x255a)                          ; F8EFFF  d1 5a 25 20
	bit_dd8 0x00, 0xc6                            ; F8F003  f0 c6 c8
	jr nz, .LF8F00C                               ; F8F006  6e 04
.LF8F008:
	bit 6,(XIX)                                   ; F8F008  b4 ce
	jr nz, .LF8F008                               ; F8F00A  6e fc
.LF8F00C:
	ld (XIX),A                                    ; F8F00C  b4 41
	bit_dd8 0x00, 0xc6                            ; F8F00E  f0 c6 c8
	jr nz, .LF8F017                               ; F8F011  6e 04
.LF8F013:
	bit 6,(XIX)                                   ; F8F013  b4 ce
	jr nz, .LF8F013                               ; F8F015  6e fc
.LF8F017:
	ld (XIX),W                                    ; F8F017  b4 40
	calr (0xF8F7A4 - 0xF8F01C)                    ; F8F019  1e 88 07   LCD_Rect_RightEdgeMask -> A
	ld (XIX+0x01),0x42                            ; F8F01C  bc 01 00 42
	ldw_d16 bc, (0x2536)                          ; F8F020  d1 36 25 21
	m_sub_rm MW16, 0x2532, r1                     ; F8F024  d1 32 25 a1
	inc 1,BC                                      ; F8F028  d9 61
LCD_Svc_05__rightrow:
	bit_dd8 0x00, 0xc6                            ; F8F02A  f0 c6 c8
	jr nz, .LF8F033                               ; F8F02D  6e 04
.LF8F02F:
	bit 6,(XIX)                                   ; F8F02F  b4 ce
	jr nz, .LF8F02F                               ; F8F031  6e fc
.LF8F033:
	ld (XIX),A                                    ; F8F033  b4 41
	djnz16 bc, LCD_Svc_05__rightrow                           ; F8F035  d9 1c f2
LCD_Svc_05__ret:
	ret                                           ; F8F038  0e

; ==============================================================================
; 0xF8F039-0xF8F3A3 -- SWI7's TEXT SERVICES: ten fonts and three glyph blitters
; ==============================================================================
;
; ★ TEN OF THE THIRTY-FOUR SWI7 SERVICES ARE THE SAME ROUTINE WITH A DIFFERENT
;   FONT.  Each one is 0x32-0x35 bytes long and does exactly this:
;
;       if BC == 0: return
;       LCD_SelectCurrentLayer                   ; (0x2555) := the layer base
;       IX += (0x2555)                           ; the caller's offset -> absolute
;       IZ = HL * BC                             ; the offset of the first code
;       repeat BC times:
;           A = (XIY + IZ)                       ; the character code
;           XIY' = <font base> + A * <bytes per glyph>
;           blit <bytes per glyph> bytes at IX
;           XIY++;  IX++                         ; next code, next byte-column
;
;   Only three things vary between the ten: the FONT BASE, the BYTES PER GLYPH,
;   and which of the two blitters is called.  That is what makes them one family
;   and what lets a single argument convention be stated once:
;
;       IX   byte offset of the top-left corner WITHIN the current layer
;       BC   number of characters
;       HL   a stride added to the source pointer as HL*BC before the first read
;       XIY  the string
;
; ★★ AND THEY REALLY ARE FONTS -- this is not inferred from the code shape, it
;   is visible.  `python3 notes/render_font.py <base> <bytes> [--width 16]
;   --art 0x41` draws the glyph, and five of the ten tables render legible
;   capital A at code 0x41.  The sharper test is `--ascii-check`, which asks
;   whether code 0x20 is blank and every code 0x21-0x7E is not:
;
;   | svc | font base | bytes | w x h | blitter | ASCII test |
;   |-----|-----------|------:|-------|---------|------------|
;   | 0x06 | 0xF1B400 | 14 |  8 x 14 | LCD_BlitGlyph8           | PASSES |
;   | 0x20 | 0xF24DC0 | 10 |  8 x 10 | LCD_BlitGlyph8           | PASSES |
;   | 0x16 | 0xF212B0 | 14 |  8 x 14 | LCD_BlitGlyph8           | fails  |
;   | 0x07 | 0xF1BEF0 | 16 |  8 x 16 | LCD_BlitGlyph8_ExtraWait | PASSES |
;   | 0x08 | 0xF1CB70 | 32 | 16 x 16 | LCD_BlitGlyph16          | PASSES |
;   | 0x21 | 0xF25590 | 48 | 16 x 24 | LCD_BlitGlyph16          | PASSES |
;   | 0x1A | 0xF22840 | 32 | 16 x 16 | LCD_BlitGlyph16          | fails  |
;   | 0x1F | 0xF24640 | 32 | 16 x 16 | LCD_BlitGlyph16          | fails  |
;   | 0x19 | 0xF21940 | 32 | 16 x 16 | LCD_BlitGlyph16          | fails  |
;   | 0x1D | 0xF203B0 | 32 | 16 x 16 | LCD_BlitGlyph16          | fails  |
;
;   The five that PASS are 8x10, 8x14, 8x16, 16x16 and 16x24 ASCII fonts: one
;   blank glyph (0x20, the space) and 94 drawn ones, at every printable code.
;   ⚠ The five that FAIL are NOT ASCII and are NOT named here.  Their glyphs are
;   stroke shapes -- 0xF22840's code 0x41 is a single horizontal bar, 0xF21940's
;   is a two-stroke figure -- which look Japanese, but nothing in this firmware
;   says what encoding indexes them.  "Symbols" below means "not ASCII", nothing
;   more.
;
;   Every font lives in PROM_B; the bases run from 0xF1B400 to 0xF25590 and six
;   of the ten are in bank 0xF2, which notes/FINDINGS-prom_b-thunk-table.md
;   records as having no thunk targets.  Both are true: nothing CALLS into that
;   bank, and these tables are read as DATA by an immediate load here.
;
; THE WIDTH IS READ OFF THE BLITTER, not guessed.  LCD_BlitGlyph8 writes the
; glyph's bytes consecutively down one byte-column with CSRDIR DOWN, so a glyph
; is 8 pixels wide and <bytes> rows tall.  LCD_BlitGlyph16 writes the EVEN bytes
; down one column (`inc 2,IZ`), steps the cursor one byte right, and writes the
; ODD bytes down the next -- 16 pixels wide, two bytes per row, <bytes>/2 rows.
; Rendering the 16-wide tables with that layout is what produces the legible A.

; ---------------------------------------------------------------------
; LCD_Svc_06_DrawText8x14 -- SWI7 service 0x06: draw a string in the 8x14 font
;
; Called from: SWI7_ServiceTable slot 0x06 (0xF8E9DE)
; Inputs:  IX, BC, HL, XIY as in the block header
; Outputs: BC glyphs drawn; XIY and IX advanced past them; WA, HL, IZ, A
;          clobbered.
; Evidence: font 0xF1B400, 14 bytes per glyph, 8 wide -- and that table passes
;          notes/render_font.py's ASCII test (blank only at 0x20).
; Unknown:  what HL is a stride THROUGH; it is multiplied by BC once, before the
;          loop, and never used again.
; ---------------------------------------------------------------------
LCD_Svc_06_DrawText8x14:
	and BC,BC                                     ; F8F039  d9 c1
	jr z, .LF8F06D                                ; F8F03B  66 30
	calr (0xF8EE93 - 0xF8F040)                   ; F8F03D  1e 53 fe   LCD_SelectCurrentLayer
	m_add_rm MW16, 0x2555, r4                     ; F8F040  d1 55 25 84
	ld WA,HL                                      ; F8F044  db 88
	mul xwa, xbc                                  ; F8F046  d9 40
	ld IZ,WA                                      ; F8F048  d8 8e
.LF8F04A:
	.byte 0xc3, 0x07, 0xf4, 0xf8, 0x21            ; F8F04A  c3 07 f4 f8 21   ld A,(XIY+IZ) -- llvm-mc has no spelling for (rr+r)
	ldb w, 0x0e                                   ; F8F04F  20 0e
	mul8rr a, w                                   ; F8F051  c8 41
	xor XHL,XHL                                   ; F8F053  eb d3
	ld HL,WA                                      ; F8F055  d8 8b
	push XIY                                      ; F8F057  3d
	ld XIY,0x00f1b400                             ; F8F058  45 00 b4 f1 00
	add XIY,XHL                                   ; F8F05D  eb 85
	ldw de, 0x0e                                  ; F8F05F  32 0e 00
	calr LCD_BlitGlyph8                                 ; F8F062  1e 73 00
	pop XIY                                       ; F8F065  5d
	inc 1,XIY                                     ; F8F066  ed 61
	inc 1,IX                                      ; F8F068  dc 61
	djnz16 bc, .LF8F04A                           ; F8F06A  d9 1c dd
.LF8F06D:
	ret                                           ; F8F06D  0e

; ---------------------------------------------------------------------
; LCD_Svc_20_DrawText8x10 -- SWI7 service 0x20: the 8x10 font
;
; Called from: SWI7_ServiceTable slot 0x20 (0xF8EA46)
; Inputs/Outputs: as LCD_Svc_06_DrawText8x14
; Evidence: font 0xF24DC0, 10 bytes per glyph, 8 wide; passes the ASCII test.
;          Apart from those two constants it is the same routine as service 0x06.
; Unknown:  as service 0x06.
; ---------------------------------------------------------------------
LCD_Svc_20_DrawText8x10:
	and BC,BC                                     ; F8F06E  d9 c1
	jr z, .LF8F0A2                                ; F8F070  66 30
	calr (0xF8EE93 - 0xF8F075)                   ; F8F072  1e 1e fe   LCD_SelectCurrentLayer
	m_add_rm MW16, 0x2555, r4                     ; F8F075  d1 55 25 84
	ld WA,HL                                      ; F8F079  db 88
	mul xwa, xbc                                  ; F8F07B  d9 40
	ld IZ,WA                                      ; F8F07D  d8 8e
.LF8F07F:
	.byte 0xc3, 0x07, 0xf4, 0xf8, 0x21            ; F8F07F  c3 07 f4 f8 21   ld A,(XIY+IZ) -- llvm-mc has no spelling for (rr+r)
	ldb w, 0x0a                                   ; F8F084  20 0a
	mul8rr a, w                                   ; F8F086  c8 41
	xor XHL,XHL                                   ; F8F088  eb d3
	ld HL,WA                                      ; F8F08A  d8 8b
	push XIY                                      ; F8F08C  3d
	ld XIY,0x00f24dc0                             ; F8F08D  45 c0 4d f2 00
	add XIY,XHL                                   ; F8F092  eb 85
	ldw de, 0x0a                                  ; F8F094  32 0a 00
	calr LCD_BlitGlyph8                                 ; F8F097  1e 3e 00
	pop XIY                                       ; F8F09A  5d
	inc 1,XIY                                     ; F8F09B  ed 61
	inc 1,IX                                      ; F8F09D  dc 61
	djnz16 bc, .LF8F07F                           ; F8F09F  d9 1c dd
.LF8F0A2:
	ret                                           ; F8F0A2  0e

; ---------------------------------------------------------------------
; LCD_Svc_16_DrawGlyphs8x14 -- SWI7 service 0x16: a second 8x14 set, NOT ASCII
;
; Called from: SWI7_ServiceTable slot 0x16 (0xF8EA1E)
; Inputs/Outputs: as LCD_Svc_06_DrawText8x14
; Evidence: font 0xF212B0, 14 bytes per glyph, 8 wide.  ⚠ It FAILS the ASCII
;          test -- everything from code 0x59 up is blank -- so 56 glyphs are
;          defined, at codes 0x21-0x58.
; Unknown:  ⚠ what those 56 glyphs ARE.  Do not call this a katakana or a kanji
;          service on this evidence.
; ---------------------------------------------------------------------
LCD_Svc_16_DrawGlyphs8x14:
	and BC,BC                                     ; F8F0A3  d9 c1
	jr z, .LF8F0D7                                ; F8F0A5  66 30
	calr (0xF8EE93 - 0xF8F0AA)                   ; F8F0A7  1e e9 fd   LCD_SelectCurrentLayer
	m_add_rm MW16, 0x2555, r4                     ; F8F0AA  d1 55 25 84
	ld WA,HL                                      ; F8F0AE  db 88
	mul xwa, xbc                                  ; F8F0B0  d9 40
	ld IZ,WA                                      ; F8F0B2  d8 8e
.LF8F0B4:
	.byte 0xc3, 0x07, 0xf4, 0xf8, 0x21            ; F8F0B4  c3 07 f4 f8 21   ld A,(XIY+IZ) -- llvm-mc has no spelling for (rr+r)
	ldb w, 0x0e                                   ; F8F0B9  20 0e
	mul8rr a, w                                   ; F8F0BB  c8 41
	xor XHL,XHL                                   ; F8F0BD  eb d3
	ld HL,WA                                      ; F8F0BF  d8 8b
	push XIY                                      ; F8F0C1  3d
	ld XIY,0x00f212b0                             ; F8F0C2  45 b0 12 f2 00
	add XIY,XHL                                   ; F8F0C7  eb 85
	ldw de, 0x0e                                  ; F8F0C9  32 0e 00
	calr LCD_BlitGlyph8                                 ; F8F0CC  1e 09 00
	pop XIY                                       ; F8F0CF  5d
	inc 1,XIY                                     ; F8F0D0  ed 61
	inc 1,IX                                      ; F8F0D2  dc 61
	djnz16 bc, .LF8F0B4                           ; F8F0D4  d9 1c dd
.LF8F0D7:
	ret                                           ; F8F0D7  0e
; ---------------------------------------------------------------------
; LCD_BlitGlyph8 -- write one 8-pixel-wide glyph down a byte-column
;
; Called from: services 0x06 (0xF8F062), 0x20 (0xF8F097) and 0x16 (0xF8F0CC)
; Inputs:  IX = the display-RAM address, DE = bytes in the glyph, XIY = the glyph
; Outputs: the glyph drawn; IZ saved and restored; WA, A clobbered.
; Evidence: CSRDIR DOWN (0x4F), CSRW with IX, MWRITE, then DE bytes read from
;          (XIY+IZ) with IZ stepping by ONE.  With the cursor advancing downward,
;          consecutive bytes are consecutive rows of the same 8-pixel column --
;          which is what "8 wide, one byte per row" means.
; Unknown:  nothing outstanding.
; ---------------------------------------------------------------------
LCD_BlitGlyph8:
	pushw iz                                      ; F8F0D8  2e
	ld XHL,0x00790000                             ; F8F0D9  43 00 00 79 00
	ld (XHL+0x01),0x4f                            ; F8F0DE  bb 01 00 4f
	bit_dd8 0x00, 0xc6                            ; F8F0E2  f0 c6 c8
	jr nz, .LF8F0EB                               ; F8F0E5  6e 04
.LF8F0E7:
	bit 6,(XHL)                                   ; F8F0E7  b3 ce
	jr nz, .LF8F0E7                               ; F8F0E9  6e fc
.LF8F0EB:
	ld (XHL+0x01),0x46                            ; F8F0EB  bb 01 00 46
	ld WA,IX                                      ; F8F0EF  dc 88
	bit_dd8 0x00, 0xc6                            ; F8F0F1  f0 c6 c8
	jr nz, .LF8F0FA                               ; F8F0F4  6e 04
.LF8F0F6:
	bit 6,(XHL)                                   ; F8F0F6  b3 ce
	jr nz, .LF8F0F6                               ; F8F0F8  6e fc
.LF8F0FA:
	ld (XHL),A                                    ; F8F0FA  b3 41
	bit_dd8 0x00, 0xc6                            ; F8F0FC  f0 c6 c8
	jr nz, .LF8F105                               ; F8F0FF  6e 04
.LF8F101:
	bit 6,(XHL)                                   ; F8F101  b3 ce
	jr nz, .LF8F101                               ; F8F103  6e fc
.LF8F105:
	ld (XHL),W                                    ; F8F105  b3 40
	bit_dd8 0x00, 0xc6                            ; F8F107  f0 c6 c8
	jr nz, .LF8F110                               ; F8F10A  6e 04
.LF8F10C:
	bit 6,(XHL)                                   ; F8F10C  b3 ce
	jr nz, .LF8F10C                               ; F8F10E  6e fc
.LF8F110:
	ld (XHL+0x01),0x42                            ; F8F110  bb 01 00 42
	xor IZ,IZ                                     ; F8F114  de d6
.LF8F116:
	cp IZ,DE                                      ; F8F116  da f6
	jr nc, .LF8F12E                               ; F8F118  6f 14
	.byte 0xc3, 0x07, 0xf4, 0xf8, 0x21            ; F8F11A  c3 07 f4 f8 21   ld A,(XIY+IZ) -- llvm-mc has no spelling for (rr+r)
	inc 1,IZ                                      ; F8F11F  de 61
	bit_dd8 0x00, 0xc6                            ; F8F121  f0 c6 c8
	jr nz, .LF8F12A                               ; F8F124  6e 04
.LF8F126:
	bit 6,(XHL)                                   ; F8F126  b3 ce
	jr nz, .LF8F126                               ; F8F128  6e fc
.LF8F12A:
	ld (XHL),A                                    ; F8F12A  b3 41
	jr .LF8F116                                   ; F8F12C  68 e8
.LF8F12E:
	popw iz                                       ; F8F12E  4e
	ret                                           ; F8F12F  0e

; ---------------------------------------------------------------------
; LCD_Svc_07_DrawText8x16 -- SWI7 service 0x07: the 8x16 font
;
; Called from: SWI7_ServiceTable slot 0x07 (0xF8E9E2)
; Inputs/Outputs: as LCD_Svc_06_DrawText8x14
; Evidence: font 0xF1BEF0, 16 bytes per glyph, 8 wide; passes the ASCII test.
;          It scales the code with `sla 0x04,HL` rather than `mul WA,W`, because
;          16 is a power of two -- the only structural difference.
; Unknown:  as service 0x06.
; ---------------------------------------------------------------------
LCD_Svc_07_DrawText8x16:
	and BC,BC                                     ; F8F130  d9 c1
	jr z, .LF8F161                                ; F8F132  66 2d
	calr (0xF8EE93 - 0xF8F137)                   ; F8F134  1e 5c fd   LCD_SelectCurrentLayer
	m_add_rm MW16, 0x2555, r4                     ; F8F137  d1 55 25 84
	ld WA,HL                                      ; F8F13B  db 88
	mul xwa, xbc                                  ; F8F13D  d9 40
	ld IZ,WA                                      ; F8F13F  d8 8e
.LF8F141:
	xor XHL,XHL                                   ; F8F141  eb d3
	.byte 0xc3, 0x07, 0xf4, 0xf8, 0x27            ; F8F143  c3 07 f4 f8 27   ld L,(XIY+IZ) -- llvm-mc has no spelling for (rr+r)
	sla hl, 0x04                                  ; F8F148  db ec 04
	push XIY                                      ; F8F14B  3d
	ld XIY,0x00f1bef0                             ; F8F14C  45 f0 be f1 00
	add XIY,XHL                                   ; F8F151  eb 85
	ldw de, 0x10                                  ; F8F153  32 10 00
	calr LCD_BlitGlyph8_ExtraWait                                 ; F8F156  1e 09 00
	pop XIY                                       ; F8F159  5d
	inc 1,XIY                                     ; F8F15A  ed 61
	inc 1,IX                                      ; F8F15C  dc 61
	djnz16 bc, .LF8F141                           ; F8F15E  d9 1c e0
.LF8F161:
	ret                                           ; F8F161  0e
; ---------------------------------------------------------------------
; LCD_BlitGlyph8_ExtraWait -- LCD_BlitGlyph8 with one more BUSY poll
;
; Called from: service 0x07 only (0xF8F156)
; Inputs/Outputs: identical to LCD_BlitGlyph8
; Evidence: ★ the two routines are BYTE-IDENTICAL apart from a single inserted
;          nine-byte busy poll.  Checked, not eyeballed: the first six bytes of
;          each are equal; bytes 6..14 of this one are exactly the poll sequence
;          `f0 c6 c8 6e 04 b3 ce 6e fc`; and bytes 6.. of LCD_BlitGlyph8 equal
;          bytes 15.. of this one, all 82 of them.  88 bytes versus 97.
; Unknown:  why service 0x07 needs the extra wait before CSRDIR and the other
;          three do not.  Nothing here says whether that is a fix or an accident.
; ---------------------------------------------------------------------
LCD_BlitGlyph8_ExtraWait:
	pushw iz                                      ; F8F162  2e
	ld XHL,0x00790000                             ; F8F163  43 00 00 79 00
	bit_dd8 0x00, 0xc6                            ; F8F168  f0 c6 c8
	jr nz, .LF8F171                               ; F8F16B  6e 04
.LF8F16D:
	bit 6,(XHL)                                   ; F8F16D  b3 ce
	jr nz, .LF8F16D                               ; F8F16F  6e fc
.LF8F171:
	ld (XHL+0x01),0x4f                            ; F8F171  bb 01 00 4f
	bit_dd8 0x00, 0xc6                            ; F8F175  f0 c6 c8
	jr nz, .LF8F17E                               ; F8F178  6e 04
.LF8F17A:
	bit 6,(XHL)                                   ; F8F17A  b3 ce
	jr nz, .LF8F17A                               ; F8F17C  6e fc
.LF8F17E:
	ld (XHL+0x01),0x46                            ; F8F17E  bb 01 00 46
	ld WA,IX                                      ; F8F182  dc 88
	bit_dd8 0x00, 0xc6                            ; F8F184  f0 c6 c8
	jr nz, .LF8F18D                               ; F8F187  6e 04
.LF8F189:
	bit 6,(XHL)                                   ; F8F189  b3 ce
	jr nz, .LF8F189                               ; F8F18B  6e fc
.LF8F18D:
	ld (XHL),A                                    ; F8F18D  b3 41
	bit_dd8 0x00, 0xc6                            ; F8F18F  f0 c6 c8
	jr nz, .LF8F198                               ; F8F192  6e 04
.LF8F194:
	bit 6,(XHL)                                   ; F8F194  b3 ce
	jr nz, .LF8F194                               ; F8F196  6e fc
.LF8F198:
	ld (XHL),W                                    ; F8F198  b3 40
	bit_dd8 0x00, 0xc6                            ; F8F19A  f0 c6 c8
	jr nz, .LF8F1A3                               ; F8F19D  6e 04
.LF8F19F:
	bit 6,(XHL)                                   ; F8F19F  b3 ce
	jr nz, .LF8F19F                               ; F8F1A1  6e fc
.LF8F1A3:
	ld (XHL+0x01),0x42                            ; F8F1A3  bb 01 00 42
	xor IZ,IZ                                     ; F8F1A7  de d6
.LF8F1A9:
	cp IZ,DE                                      ; F8F1A9  da f6
	jr nc, .LF8F1C1                               ; F8F1AB  6f 14
	.byte 0xc3, 0x07, 0xf4, 0xf8, 0x21            ; F8F1AD  c3 07 f4 f8 21   ld A,(XIY+IZ) -- llvm-mc has no spelling for (rr+r)
	inc 1,IZ                                      ; F8F1B2  de 61
	bit_dd8 0x00, 0xc6                            ; F8F1B4  f0 c6 c8
	jr nz, .LF8F1BD                               ; F8F1B7  6e 04
.LF8F1B9:
	bit 6,(XHL)                                   ; F8F1B9  b3 ce
	jr nz, .LF8F1B9                               ; F8F1BB  6e fc
.LF8F1BD:
	ld (XHL),A                                    ; F8F1BD  b3 41
	jr .LF8F1A9                                   ; F8F1BF  68 e8
.LF8F1C1:
	popw iz                                       ; F8F1C1  4e
	ret                                           ; F8F1C2  0e

; ---------------------------------------------------------------------
; LCD_Svc_08_DrawText16x16 -- SWI7 service 0x08: the 16x16 font
;
; Called from: SWI7_ServiceTable slot 0x08 (0xF8E9E6)
; Inputs/Outputs: as LCD_Svc_06_DrawText8x14, but each glyph occupies TWO
;          byte-columns, so IX advances by two per character -- once here and
;          once inside LCD_BlitGlyph16.
; Evidence: font 0xF1CB70, 32 bytes per glyph, 16 wide; passes the ASCII test
;          when rendered two bytes per row.
; Unknown:  as service 0x06.
; ---------------------------------------------------------------------
LCD_Svc_08_DrawText16x16:
	and BC,BC                                     ; F8F1C3  d9 c1
	jr z, .LF8F1F6                                ; F8F1C5  66 2f
	calr (0xF8EE93 - 0xF8F1CA)                   ; F8F1C7  1e c9 fc   LCD_SelectCurrentLayer
	m_add_rm MW16, 0x2555, r4                     ; F8F1CA  d1 55 25 84
	ld WA,HL                                      ; F8F1CE  db 88
	mul xwa, xbc                                  ; F8F1D0  d9 40
	ld IZ,WA                                      ; F8F1D2  d8 8e
.LF8F1D4:
	xor XHL,XHL                                   ; F8F1D4  eb d3
	.byte 0xc3, 0x07, 0xf4, 0xf8, 0x27            ; F8F1D6  c3 07 f4 f8 27   ld L,(XIY+IZ) -- llvm-mc has no spelling for (rr+r)
	sla hl, 0x05                                  ; F8F1DB  db ec 05
	push XIY                                      ; F8F1DE  3d
	ld XIY,0x00f1cb70                             ; F8F1DF  45 70 cb f1 00
	extz XHL                                      ; F8F1E4  eb 12
	add XIY,XHL                                   ; F8F1E6  eb 85
	ldw de, 0x20                                  ; F8F1E8  32 20 00
	calr LCD_BlitGlyph16                                 ; F8F1EB  1e 03 01
	pop XIY                                       ; F8F1EE  5d
	inc 1,XIY                                     ; F8F1EF  ed 61
	inc 1,IX                                      ; F8F1F1  dc 61
	djnz16 bc, .LF8F1D4                           ; F8F1F3  d9 1c de
.LF8F1F6:
	ret                                           ; F8F1F6  0e

; ---------------------------------------------------------------------
; LCD_Svc_21_DrawText16x24 -- SWI7 service 0x21: the 16x24 font, the largest
;
; Called from: SWI7_ServiceTable slot 0x21 (0xF8EA4A)
; Inputs/Outputs: as LCD_Svc_08_DrawText16x16
; Evidence: font 0xF25590, 48 bytes per glyph (`mul L,0x30`), 16 wide; passes
;          the ASCII test.  24 rows is the tallest glyph in the machine.
; Unknown:  as service 0x06.
; ---------------------------------------------------------------------
LCD_Svc_21_DrawText16x24:
	and BC,BC                                     ; F8F1F7  d9 c1
	jr z, .LF8F228                                ; F8F1F9  66 2d
	calr (0xF8EE93 - 0xF8F1FE)                   ; F8F1FB  1e 95 fc   LCD_SelectCurrentLayer
	m_add_rm MW16, 0x2555, r4                     ; F8F1FE  d1 55 25 84
	ld WA,HL                                      ; F8F202  db 88
	mul xwa, xbc                                  ; F8F204  d9 40
	ld IZ,WA                                      ; F8F206  d8 8e
.LF8F208:
	xor XHL,XHL                                   ; F8F208  eb d3
	.byte 0xc3, 0x07, 0xf4, 0xf8, 0x27            ; F8F20A  c3 07 f4 f8 27   ld L,(XIY+IZ) -- llvm-mc has no spelling for (rr+r)
	mul L,0x30                                    ; F8F20F  cf 08 30
	push XIY                                      ; F8F212  3d
	ld XIY,0x00f25590                             ; F8F213  45 90 55 f2 00
	add XIY,XHL                                   ; F8F218  eb 85
	ldw de, 0x30                                  ; F8F21A  32 30 00
	calr LCD_BlitGlyph16                                 ; F8F21D  1e d1 00
	pop XIY                                       ; F8F220  5d
	inc 1,XIY                                     ; F8F221  ed 61
	inc 1,IX                                      ; F8F223  dc 61
	djnz16 bc, .LF8F208                           ; F8F225  d9 1c e0
.LF8F228:
	ret                                           ; F8F228  0e

; ---------------------------------------------------------------------
; LCD_Svc_1A_DrawGlyphs16x16 -- SWI7 service 0x1A: a 16x16 set, NOT ASCII
;
; Called from: SWI7_ServiceTable slot 0x1A (0xF8EA2E)
; Inputs/Outputs: as LCD_Svc_08_DrawText16x16
; Evidence: font 0xF22840, 32 bytes per glyph, 16 wide.  ⚠ FAILS the ASCII test:
;          code 0x20 is not blank.  Its code 0x41 is a single horizontal bar.
; Unknown:  ⚠ the encoding.  Not named.
; ---------------------------------------------------------------------
LCD_Svc_1A_DrawGlyphs16x16:
	and BC,BC                                     ; F8F229  d9 c1
	jr z, .LF8F25A                                ; F8F22B  66 2d
	calr (0xF8EE93 - 0xF8F230)                   ; F8F22D  1e 63 fc   LCD_SelectCurrentLayer
	m_add_rm MW16, 0x2555, r4                     ; F8F230  d1 55 25 84
	ld WA,HL                                      ; F8F234  db 88
	mul xwa, xbc                                  ; F8F236  d9 40
	ld IZ,WA                                      ; F8F238  d8 8e
.LF8F23A:
	xor XHL,XHL                                   ; F8F23A  eb d3
	.byte 0xc3, 0x07, 0xf4, 0xf8, 0x27            ; F8F23C  c3 07 f4 f8 27   ld L,(XIY+IZ) -- llvm-mc has no spelling for (rr+r)
	sla hl, 0x05                                  ; F8F241  db ec 05
	push XIY                                      ; F8F244  3d
	ld XIY,0x00f22840                             ; F8F245  45 40 28 f2 00
	add XIY,XHL                                   ; F8F24A  eb 85
	ldw de, 0x20                                  ; F8F24C  32 20 00
	calr LCD_BlitGlyph16                                 ; F8F24F  1e 9f 00
	pop XIY                                       ; F8F252  5d
	inc 1,XIY                                     ; F8F253  ed 61
	inc 1,IX                                      ; F8F255  dc 61
	djnz16 bc, .LF8F23A                           ; F8F257  d9 1c e0
.LF8F25A:
	ret                                           ; F8F25A  0e

; ---------------------------------------------------------------------
; LCD_Svc_1F_DrawGlyphs16x16 -- SWI7 service 0x1F: a 16x16 set, NOT ASCII
;
; Called from: SWI7_ServiceTable slot 0x1F (0xF8EA42)
; Inputs/Outputs: as LCD_Svc_08_DrawText16x16
; Evidence: font 0xF24640, 32 bytes per glyph, 16 wide.  ⚠ FAILS the ASCII test:
;          63 of the 95 printable codes are drawn and code 0x41 is blank.
; Unknown:  ⚠ the encoding.  Not named.
; ---------------------------------------------------------------------
LCD_Svc_1F_DrawGlyphs16x16:
	and BC,BC                                     ; F8F25B  d9 c1
	jr z, .LF8F28C                                ; F8F25D  66 2d
	calr (0xF8EE93 - 0xF8F262)                   ; F8F25F  1e 31 fc   LCD_SelectCurrentLayer
	m_add_rm MW16, 0x2555, r4                     ; F8F262  d1 55 25 84
	ld WA,HL                                      ; F8F266  db 88
	mul xwa, xbc                                  ; F8F268  d9 40
	ld IZ,WA                                      ; F8F26A  d8 8e
.LF8F26C:
	xor XHL,XHL                                   ; F8F26C  eb d3
	.byte 0xc3, 0x07, 0xf4, 0xf8, 0x27            ; F8F26E  c3 07 f4 f8 27   ld L,(XIY+IZ) -- llvm-mc has no spelling for (rr+r)
	sla hl, 0x05                                  ; F8F273  db ec 05
	push XIY                                      ; F8F276  3d
	ld XIY,0x00f24640                             ; F8F277  45 40 46 f2 00
	add XIY,XHL                                   ; F8F27C  eb 85
	ldw de, 0x20                                  ; F8F27E  32 20 00
	calr LCD_BlitGlyph16                                 ; F8F281  1e 6d 00
	pop XIY                                       ; F8F284  5d
	inc 1,XIY                                     ; F8F285  ed 61
	inc 1,IX                                      ; F8F287  dc 61
	djnz16 bc, .LF8F26C                           ; F8F289  d9 1c e0
.LF8F28C:
	ret                                           ; F8F28C  0e

; ---------------------------------------------------------------------
; LCD_Svc_19_DrawGlyphs16x16 -- SWI7 service 0x19: a 16x16 set, NOT ASCII
;
; Called from: SWI7_ServiceTable slot 0x19 (0xF8EA2A)
; Inputs/Outputs: as LCD_Svc_08_DrawText16x16
; Evidence: font 0xF21940, 32 bytes per glyph, 16 wide.  ⚠ FAILS the ASCII test:
;          71 codes drawn and 0x20 is not blank.
; Unknown:  ⚠ the encoding.  Not named.
; ---------------------------------------------------------------------
LCD_Svc_19_DrawGlyphs16x16:
	and BC,BC                                     ; F8F28D  d9 c1
	jr z, .LF8F2BE                                ; F8F28F  66 2d
	calr (0xF8EE93 - 0xF8F294)                   ; F8F291  1e ff fb   LCD_SelectCurrentLayer
	m_add_rm MW16, 0x2555, r4                     ; F8F294  d1 55 25 84

	ld WA,HL                                      ; F8F298  db 88
	mul xwa, xbc                                  ; F8F29A  d9 40
	ld IZ,WA                                      ; F8F29C  d8 8e
.LF8F29E:
	xor XHL,XHL                                   ; F8F29E  eb d3
	.byte 0xc3, 0x07, 0xf4, 0xf8, 0x27            ; F8F2A0  c3 07 f4 f8 27   ld L,(XIY+IZ) -- llvm-mc has no spelling for (rr+r)
	sla hl, 0x05                                  ; F8F2A5  db ec 05
	push XIY                                      ; F8F2A8  3d
	ld XIY,0x00f21940                             ; F8F2A9  45 40 19 f2 00
	add XIY,XHL                                   ; F8F2AE  eb 85
	ldw de, 0x20                                  ; F8F2B0  32 20 00
	calr LCD_BlitGlyph16                                 ; F8F2B3  1e 3b 00
	pop XIY                                       ; F8F2B6  5d
	inc 1,XIY                                     ; F8F2B7  ed 61
	inc 1,IX                                      ; F8F2B9  dc 61
	djnz16 bc, .LF8F29E                           ; F8F2BB  d9 1c e0
.LF8F2BE:
	ret                                           ; F8F2BE  0e

; ---------------------------------------------------------------------
; LCD_Svc_1D_DrawGlyphs16x16 -- SWI7 service 0x1D: a 16x16 set, NOT ASCII
;
; Called from: SWI7_ServiceTable slot 0x1D (0xF8EA3A)
; Inputs/Outputs: as LCD_Svc_08_DrawText16x16
; Evidence: font 0xF203B0, 32 bytes per glyph, 16 wide.  ⚠ FAILS the ASCII test:
;          71 codes drawn.
; Unknown:  ⚠ the encoding.  Not named.
; ---------------------------------------------------------------------
LCD_Svc_1D_DrawGlyphs16x16:
	and BC,BC                                     ; F8F2BF  d9 c1
	jr z, .LF8F2F0                                ; F8F2C1  66 2d
	calr (0xF8EE93 - 0xF8F2C6)                   ; F8F2C3  1e cd fb   LCD_SelectCurrentLayer
	m_add_rm MW16, 0x2555, r4                     ; F8F2C6  d1 55 25 84
	ld WA,HL                                      ; F8F2CA  db 88
	mul xwa, xbc                                  ; F8F2CC  d9 40
	ld IZ,WA                                      ; F8F2CE  d8 8e
.LF8F2D0:
	xor XHL,XHL                                   ; F8F2D0  eb d3
	.byte 0xc3, 0x07, 0xf4, 0xf8, 0x27            ; F8F2D2  c3 07 f4 f8 27   ld L,(XIY+IZ) -- llvm-mc has no spelling for (rr+r)
	sla hl, 0x05                                  ; F8F2D7  db ec 05
	push XIY                                      ; F8F2DA  3d
	ld XIY,0x00f203b0                             ; F8F2DB  45 b0 03 f2 00
	add XIY,XHL                                   ; F8F2E0  eb 85
	ldw de, 0x20                                  ; F8F2E2  32 20 00
	calr LCD_BlitGlyph16                                 ; F8F2E5  1e 09 00
	pop XIY                                       ; F8F2E8  5d
	inc 1,XIY                                     ; F8F2E9  ed 61
	inc 1,IX                                      ; F8F2EB  dc 61
	djnz16 bc, .LF8F2D0                           ; F8F2ED  d9 1c e0
.LF8F2F0:
	ret                                           ; F8F2F0  0e
; ---------------------------------------------------------------------
; LCD_BlitGlyph16 -- write one 16-pixel-wide glyph as TWO byte-columns
;
; Called from: services 0x08 (0xF8F1EB), 0x21 (0xF8F21D), 0x1A (0xF8F24F),
;          0x1F (0xF8F281), 0x19 (0xF8F2B3) and 0x1D (0xF8F2E5)
; Inputs:  IX = the display-RAM address of the left column, DE = bytes in the
;          glyph, XIY = the glyph
; Outputs: the glyph drawn, IX left pointing at the RIGHT column (it is
;          incremented once, in the middle); IZ saved and restored.
; Evidence: ★ this is what fixes the 16-wide layout.  The first pass steps IZ by
;          TWO from 0, so it writes bytes 0, 2, 4 ... down one column; then
;          `inc 1,IX`, a fresh CSRW, and the second pass does the same from
;          XIY+1, writing bytes 1, 3, 5 ... down the next column.  Two bytes per
;          row, row-major, left byte first -- and rendering the six tables that
;          way is what makes their glyphs legible.
; Unknown:  nothing outstanding.
; ---------------------------------------------------------------------
LCD_BlitGlyph16:
	pushw iz                                      ; F8F2F1  2e
	ld XHL,0x00790000                             ; F8F2F2  43 00 00 79 00
	bit_dd8 0x00, 0xc6                            ; F8F2F7  f0 c6 c8
	jr nz, .LF8F300                               ; F8F2FA  6e 04
.LF8F2FC:
	bit 6,(XHL)                                   ; F8F2FC  b3 ce
	jr NZ,.LF8F2FC                                ; F8F2FE  6e fc
.LF8F300:
	ld (XHL+0x01),0x4f                            ; F8F300  bb 01 00 4f
	bit_dd8 0x00, 0xc6                            ; F8F304  f0 c6 c8
	jr nz, .LF8F30D                               ; F8F307  6e 04
.LF8F309:
	bit 6,(XHL)                                   ; F8F309  b3 ce
	jr nz, .LF8F309                               ; F8F30B  6e fc
.LF8F30D:
	ld (XHL+0x01),0x46                            ; F8F30D  bb 01 00 46
	ld WA,IX                                      ; F8F311  dc 88
	bit_dd8 0x00, 0xc6                            ; F8F313  f0 c6 c8
	jr nz, .LF8F31C                               ; F8F316  6e 04
.LF8F318:
	bit 6,(XHL)                                   ; F8F318  b3 ce
	jr nz, .LF8F318                               ; F8F31A  6e fc
.LF8F31C:
	ld (XHL),A                                    ; F8F31C  b3 41
	bit_dd8 0x00, 0xc6                            ; F8F31E  f0 c6 c8
	jr nz, .LF8F327                               ; F8F321  6e 04
.LF8F323:
	bit 6,(XHL)                                   ; F8F323  b3 ce
	jr nz, .LF8F323                               ; F8F325  6e fc
.LF8F327:
	ld (XHL),W                                    ; F8F327  b3 40
	bit_dd8 0x00, 0xc6                            ; F8F329  f0 c6 c8
	jr nz, .LF8F332                               ; F8F32C  6e 04
.LF8F32E:
	bit 6,(XHL)                                   ; F8F32E  b3 ce
	jr nz, .LF8F32E                               ; F8F330  6e fc
.LF8F332:
	ld (XHL+0x01),0x42                            ; F8F332  bb 01 00 42
	xor IZ,IZ                                     ; F8F336  de d6
.LF8F338:
	cp IZ,DE                                      ; F8F338  da f6
	jr nc, .LF8F350                               ; F8F33A  6f 14
	.byte 0xc3, 0x07, 0xf4, 0xf8, 0x21            ; F8F33C  c3 07 f4 f8 21   ld A,(XIY+IZ) -- llvm-mc has no spelling for (rr+r)
	inc 2,IZ                                      ; F8F341  de 62
	bit_dd8 0x00, 0xc6                            ; F8F343  f0 c6 c8
	jr nz, .LF8F34C                               ; F8F346  6e 04
.LF8F348:
	bit 6,(XHL)                                   ; F8F348  b3 ce
	jr nz, .LF8F348                               ; F8F34A  6e fc
.LF8F34C:
	ld (XHL),A                                    ; F8F34C  b3 41
	jr .LF8F338                                   ; F8F34E  68 e8
.LF8F350:
	inc 1,IX                                      ; F8F350  dc 61
	bit_dd8 0x00, 0xc6                            ; F8F352  f0 c6 c8
	jr nz, .LF8F35B                               ; F8F355  6e 04
.LF8F357:
	bit 6,(XHL)                                   ; F8F357  b3 ce
	jr nz, .LF8F357                               ; F8F359  6e fc
.LF8F35B:
	ld (XHL+0x01),0x46                            ; F8F35B  bb 01 00 46
	ld WA,IX                                      ; F8F35F  dc 88
	bit_dd8 0x00, 0xc6                            ; F8F361  f0 c6 c8
	jr nz, .LF8F36A                               ; F8F364  6e 04
.LF8F366:
	bit 6,(XHL)                                   ; F8F366  b3 ce
	jr nz, .LF8F366                               ; F8F368  6e fc
.LF8F36A:
	ld (XHL),A                                    ; F8F36A  b3 41
	bit_dd8 0x00, 0xc6                            ; F8F36C  f0 c6 c8
	jr nz, .LF8F375                               ; F8F36F  6e 04
.LF8F371:
	bit 6,(XHL)                                   ; F8F371  b3 ce
	jr nz, .LF8F371                               ; F8F373  6e fc
.LF8F375:
	ld (XHL),W                                    ; F8F375  b3 40
	bit_dd8 0x00, 0xc6                            ; F8F377  f0 c6 c8
	jr nz, .LF8F380                               ; F8F37A  6e 04
.LF8F37C:
	bit 6,(XHL)                                   ; F8F37C  b3 ce
	jr nz, .LF8F37C                               ; F8F37E  6e fc
.LF8F380:
	ld (XHL+0x01),0x42                            ; F8F380  bb 01 00 42
	xor IZ,IZ                                     ; F8F384  de d6
.LF8F386:
	cp IZ,DE                                      ; F8F386  da f6
	jr nc, .LF8F3A2                               ; F8F388  6f 18
	inc 1,XIY                                     ; F8F38A  ed 61
	.byte 0xc3, 0x07, 0xf4, 0xf8, 0x21            ; F8F38C  c3 07 f4 f8 21   ld A,(XIY+IZ) -- llvm-mc has no spelling for (rr+r)
	dec 1,XIY                                     ; F8F391  ed 69
	inc 2,IZ                                      ; F8F393  de 62
	bit_dd8 0x00, 0xc6                            ; F8F395  f0 c6 c8
	jr nz, .LF8F39E                               ; F8F398  6e 04
.LF8F39A:
	bit 6,(XHL)                                   ; F8F39A  b3 ce
	jr nz, .LF8F39A                               ; F8F39C  6e fc
.LF8F39E:
	ld (XHL),A                                    ; F8F39E  b3 41
	jr .LF8F386                                   ; F8F3A0  68 e4
.LF8F3A2:
	popw iz                                       ; F8F3A2  4e
	ret                                           ; F8F3A3  0e
; ==============================================================================
; 0xF8F3A4-0xF8F766 -- SWI7's LINE AND BOX SERVICES
; ==============================================================================
;
; Six services that share the same four coordinate words as LCD_Svc_00_DrawLine
; -- (0x2530),(0x2532) = (X0,Y0) and (0x2534),(0x2536) = (X1,Y1) -- and build on each
; other:
;
;   0x01  a HORIZONTAL run of pixels, solid           (0xF8F528)
;   0x02  a VERTICAL run of pixels, solid             (0xF8F739)
;   0x09  a rectangle OUTLINE = 0x01 twice + 0x02 twice          (0xF8F3A4)
;   0x0A  0x09 plus a TWO-pixel drop shadow           (0xF8F3E1)
;   0x22  0x09 plus a ONE-pixel drop shadow           (0xF8F4B2)
;   0x13  a rectangle outline built the same way as 0x09 but from services 0x11
;         and 0x12, the PATTERNED line pair            (0xF8F475)
;
; ★ WHY "OUTLINE" AND NOT "FILL".  Service 0x09's whole body is four calls and
;   eight coordinate exchanges: it calls 0x01 with Y0 and Y1 swapped around it,
;   so the horizontal run is drawn once at each Y; then 0x02 with X0 and X1
;   swapped, so the vertical run is drawn once at each X.  Four sides, nothing
;   in between.  (The FILLED rectangle is service 0x05, converted above, and it
;   is a completely different routine.)
;
; ★ WHY "DROP SHADOW".  Services 0x0A and 0x22 both begin by calling 0x09, then
;   save all four coordinates into (0x255C),(0x255E),(0x2560),(0x2562), draw
;   extra horizontal runs BELOW the bottom edge and extra vertical runs to the
;   RIGHT of the right edge, and restore.  0x0A draws two of each and 0x22 one
;   of each -- that is the entire difference between them, and it is visible in
;   the call counts below.  Bottom-and-right only is what a drop shadow is.
;
; ⚠ WHAT IS NOT ESTABLISHED: nothing here traces a CALLER, so which of the two
;   shadow depths the UI uses where is unknown, and "shadow" is a description of
;   the geometry, not of an intent stated anywhere in the ROM.

; ---------------------------------------------------------------------
; LCD_Svc_09_DrawBox -- SWI7 service 0x09: the outline of a rectangle
;
; Called from: SWI7_ServiceTable slot 0x09 (0xF8E9EA); also called directly by
;          services 0x0A (0xF8F3E1) and 0x22 (0xF8F4B2)
; Inputs:  (0x2530),(0x2532),(0x2534),(0x2536) = the two corners
; Outputs: four sides drawn.  ⚠ The four coordinate words are left EXCHANGED
;          BACK to their entry values -- each swap is done twice -- but service
;          0x01 clamps them on the way, so they can come back CHANGED if the
;          caller passed anything outside 320 x 240.  Service 0x02 does not
;          clamp.
; Evidence: `calr 0x01` / swap Y0<->Y1 / `calr 0x01` / swap back, then the same
;          with 0x02 and X0<->X1.  Two horizontal runs at two different Y values
;          and two vertical runs at two different X values is a box outline.
; Unknown:  callers.
; ---------------------------------------------------------------------
LCD_Svc_09_DrawBox:
	calr LCD_Svc_01_DrawHLine                                 ; F8F3A4  1e 81 01
	ldw_d16 wa, (0x2536)                          ; F8F3A7  d1 36 25 20
	m_ex_mr MW16, 0x2532, r0                      ; F8F3AB  d1 32 25 30
	stda16 (0x2536), wa                           ; F8F3AF  f1 36 25 50
	calr LCD_Svc_01_DrawHLine                                 ; F8F3B3  1e 72 01
	ldw_d16 wa, (0x2536)                          ; F8F3B6  d1 36 25 20
	m_ex_mr MW16, 0x2532, r0                      ; F8F3BA  d1 32 25 30
	stda16 (0x2536), wa                           ; F8F3BE  f1 36 25 50
	calr LCD_Svc_02_DrawVLine                                 ; F8F3C2  1e 74 03
	ldw_d16 wa, (0x2534)                          ; F8F3C5  d1 34 25 20
	m_ex_mr MW16, 0x2530, r0                      ; F8F3C9  d1 30 25 30
	stda16 (0x2534), wa                           ; F8F3CD  f1 34 25 50
	calr LCD_Svc_02_DrawVLine                                 ; F8F3D1  1e 65 03
	ldw_d16 wa, (0x2534)                          ; F8F3D4  d1 34 25 20
	m_ex_mr MW16, 0x2530, r0                      ; F8F3D8  d1 30 25 30
	stda16 (0x2534), wa                           ; F8F3DC  f1 34 25 50
	ret                                           ; F8F3E0  0e

; ---------------------------------------------------------------------
; LCD_Svc_0A_DrawBoxShadow2 -- SWI7 service 0x0A: a box with a 2-pixel shadow
;
; Called from: SWI7_ServiceTable slot 0x0A (0xF8E9EE)
; Inputs:  the four coordinate words
; Outputs: the outline, plus two horizontal runs below it and two vertical runs
;          to its right.  (0x255C),(0x255E),(0x2560),(0x2562) hold the entry
;          coordinates on exit; the four live words are restored from them
;          halfway through and then stepped again, so they are NOT restored at
;          the end.
; Evidence: it calls LCD_Svc_09_DrawBox once, then LCD_Svc_01_DrawHLine TWICE
;          and LCD_Svc_02_DrawVLine TWICE, each preceded by `incw 1,` on the
;          coordinates that move the run one pixel further down or right.  Two
;          extra runs per side = a two-pixel shadow.  Service 0x22 is the same
;          routine with one of each.
; Unknown:  callers; whether the four saved words at 0x255C are read by anything
;          outside these two services.
; ---------------------------------------------------------------------
LCD_Svc_0A_DrawBoxShadow2:
	calr LCD_Svc_09_DrawBox                                 ; F8F3E1  1e c0 ff
	ldw_d16 wa, (0x2530)                          ; F8F3E4  d1 30 25 20
	stda16 (0x255c), wa                           ; F8F3E8  f1 5c 25 50
	ldw_d16 wa, (0x2532)                          ; F8F3EC  d1 32 25 20
	stda16 (0x255e), wa                           ; F8F3F0  f1 5e 25 50
	ldw_d16 wa, (0x2534)                          ; F8F3F4  d1 34 25 20
	stda16 (0x2560), wa                           ; F8F3F8  f1 60 25 50
	ldw_d16 wa, (0x2536)                          ; F8F3FC  d1 36 25 20
	stda16 (0x2562), wa                           ; F8F400  f1 62 25 50
	incdi16 0x01, (0x2530)                        ; F8F404  d1 30 25 61
	incdi16 0x01, (0x2536)                        ; F8F408  d1 36 25 61
	ldw_d16 wa, (0x2536)                          ; F8F40C  d1 36 25 20
	stda16 (0x2532), wa                           ; F8F410  f1 32 25 50
	m_add_mi16 MW16, 0x2534, 0x0001               ; F8F414  d1 34 25 38 01 00
	calr LCD_Svc_01_DrawHLine                                 ; F8F41A  1e 0b 01
	incdi16 0x01, (0x2530)                        ; F8F41D  d1 30 25 61
	incdi16 0x01, (0x2532)                        ; F8F421  d1 32 25 61
	incdi16 0x01, (0x2536)                        ; F8F425  d1 36 25 61
	calr LCD_Svc_01_DrawHLine                                 ; F8F429  1e fc 00
	ldw_d16 wa, (0x255c)                          ; F8F42C  d1 5c 25 20
	stda16 (0x2530), wa                           ; F8F430  f1 30 25 50
	ldw_d16 wa, (0x255e)                          ; F8F434  d1 5e 25 20
	stda16 (0x2532), wa                           ; F8F438  f1 32 25 50
	ldw_d16 wa, (0x2560)                          ; F8F43C  d1 60 25 20
	stda16 (0x2534), wa                           ; F8F440  f1 34 25 50
	ldw_d16 wa, (0x2562)                          ; F8F444  d1 62 25 20
	stda16 (0x2536), wa                           ; F8F448  f1 36 25 50
	incdi16 0x01, (0x2532)                        ; F8F44C  d1 32 25 61
	incdi16 0x01, (0x2534)                        ; F8F450  d1 34 25 61
	ldw_d16 wa, (0x2534)                          ; F8F454  d1 34 25 20
	stda16 (0x2530), wa                           ; F8F458  f1 30 25 50
	m_add_mi16 MW16, 0x2536, 0x0002               ; F8F45C  d1 36 25 38 02 00
	calr LCD_Svc_02_DrawVLine                                 ; F8F462  1e d4 02
	incdi16 0x01, (0x2532)                        ; F8F465  d1 32 25 61
	incdi16 0x01, (0x2530)                        ; F8F469  d1 30 25 61
	incdi16 0x01, (0x2534)                        ; F8F46D  d1 34 25 61
	calr LCD_Svc_02_DrawVLine                                 ; F8F471  1e c5 02
	ret                                           ; F8F474  0e

; ---------------------------------------------------------------------
; LCD_Svc_13_DrawBoxPatterned -- SWI7 service 0x13: a box drawn with the
; patterned line pair instead of the solid one
;
; Called from: SWI7_ServiceTable slot 0x13 (0xF8EA12)
; Inputs/Outputs: as LCD_Svc_09_DrawBox
; Evidence: instruction for instruction the same routine as service 0x09 with
;          `calr 0x01` replaced by `calr 0xF8FCB2` (service 0x11) and
;          `calr 0x02` by `calr 0xF8FE80` (service 0x12).
;          ⚠ "Patterned" rather than "solid": services 0x11/0x12 are not
;          converted, but 0x11 opens exactly like 0x01 and then, instead of
;          filling with 0xFF, calls 0xF8FE39, which indexes TWO tables by
;          X mod 8 -- 0xF8FE52 holding `cc 66 33 19 0c 06 03 01 00` and
;          0xF8FE5B holding `cc 66 33 99 cc 66 33 99 cc`.  Those are 0xCC
;          logically SHIFTED right by k and 0xCC ROTATED right by k: one dither
;          pattern, phase-aligned to the pixel column, for the ragged first byte
;          and for the whole bytes respectively.  0xCC is two pixels on, two
;          off.  What that looks like on the panel is NOT measured here, and
;          neither table is converted yet -- they are inside the 0xF8F850
;          .incbin.
; Unknown:  callers.
; ---------------------------------------------------------------------
LCD_Svc_13_DrawBoxPatterned:
	calr (0xF8FCB2 - 0xF8F478)                   ; F8F475  1e 3a 08   svc 0x11, the patterned horizontal line
	ldw_d16 wa, (0x2536)                          ; F8F478  d1 36 25 20
	m_ex_mr MW16, 0x2532, r0                      ; F8F47C  d1 32 25 30
	stda16 (0x2536), wa                           ; F8F480  f1 36 25 50
	calr (0xF8FCB2 - 0xF8F487)                   ; F8F484  1e 2b 08   svc 0x11
	ldw_d16 wa, (0x2536)                          ; F8F487  d1 36 25 20
	m_ex_mr MW16, 0x2532, r0                      ; F8F48B  d1 32 25 30
	stda16 (0x2536), wa                           ; F8F48F  f1 36 25 50
	calr (0xF8FE80 - 0xF8F496)                   ; F8F493  1e ea 09   svc 0x12, the patterned vertical line
	ldw_d16 wa, (0x2534)                          ; F8F496  d1 34 25 20
	m_ex_mr MW16, 0x2530, r0                      ; F8F49A  d1 30 25 30
	stda16 (0x2534), wa                           ; F8F49E  f1 34 25 50
	calr (0xF8FE80 - 0xF8F4A5)                   ; F8F4A2  1e db 09   svc 0x12
	ldw_d16 wa, (0x2534)                          ; F8F4A5  d1 34 25 20
	m_ex_mr MW16, 0x2530, r0                      ; F8F4A9  d1 30 25 30
	stda16 (0x2534), wa                           ; F8F4AD  f1 34 25 50
	ret                                           ; F8F4B1  0e

; ---------------------------------------------------------------------
; LCD_Svc_22_DrawBoxShadow1 -- SWI7 service 0x22: a box with a 1-pixel shadow
;
; Called from: SWI7_ServiceTable slot 0x22 (0xF8EA4E)
; Inputs/Outputs: as LCD_Svc_0A_DrawBoxShadow2
; Evidence: the same routine as service 0x0A with ONE call to
;          LCD_Svc_01_DrawHLine and ONE to LCD_Svc_02_DrawVLine instead of two
;          each, and `add (0x2536),0x0001` where 0x0A has `0x0002`.  A one-pixel
;          shadow rather than a two-pixel one.
; Unknown:  callers, and which of the two the UI prefers.
; ---------------------------------------------------------------------
LCD_Svc_22_DrawBoxShadow1:
	calr LCD_Svc_09_DrawBox                                 ; F8F4B2  1e ef fe
	ldw_d16 wa, (0x2530)                          ; F8F4B5  d1 30 25 20
	stda16 (0x255c), wa                           ; F8F4B9  f1 5c 25 50
	ldw_d16 wa, (0x2532)                          ; F8F4BD  d1 32 25 20
	stda16 (0x255e), wa                           ; F8F4C1  f1 5e 25 50
	ldw_d16 wa, (0x2534)                          ; F8F4C5  d1 34 25 20
	stda16 (0x2560), wa                           ; F8F4C9  f1 60 25 50
	ldw_d16 wa, (0x2536)                          ; F8F4CD  d1 36 25 20
	stda16 (0x2562), wa                           ; F8F4D1  f1 62 25 50
	incdi16 0x01, (0x2530)                        ; F8F4D5  d1 30 25 61
	incdi16 0x01, (0x2536)                        ; F8F4D9  d1 36 25 61
	ldw_d16 wa, (0x2536)                          ; F8F4DD  d1 36 25 20
	stda16 (0x2532), wa                           ; F8F4E1  f1 32 25 50
	m_add_mi16 MW16, 0x2534, 0x0001               ; F8F4E5  d1 34 25 38 01 00
	calr LCD_Svc_01_DrawHLine                                 ; F8F4EB  1e 3a 00
	ldw_d16 wa, (0x255c)                          ; F8F4EE  d1 5c 25 20
	stda16 (0x2530), wa                           ; F8F4F2  f1 30 25 50
	ldw_d16 wa, (0x255e)                          ; F8F4F6  d1 5e 25 20
	stda16 (0x2532), wa                           ; F8F4FA  f1 32 25 50
	ldw_d16 wa, (0x2560)                          ; F8F4FE  d1 60 25 20
	stda16 (0x2534), wa                           ; F8F502  f1 34 25 50
	ldw_d16 wa, (0x2562)                          ; F8F506  d1 62 25 20
	stda16 (0x2536), wa                           ; F8F50A  f1 36 25 50
	incdi16 0x01, (0x2532)                        ; F8F50E  d1 32 25 61
	incdi16 0x01, (0x2534)                        ; F8F512  d1 34 25 61
	ldw_d16 wa, (0x2534)                          ; F8F516  d1 34 25 20
	stda16 (0x2530), wa                           ; F8F51A  f1 30 25 50
	m_add_mi16 MW16, 0x2536, 0x0001               ; F8F51E  d1 36 25 38 01 00
	calr LCD_Svc_02_DrawVLine                                 ; F8F524  1e 12 02
	ret                                           ; F8F527  0e

; ---------------------------------------------------------------------
; LCD_Svc_01_DrawHLine -- SWI7 service 0x01: a solid horizontal run of pixels
;
; Called from: SWI7_ServiceTable slot 0x01 (0xF8E9CA), and from services 0x09,
;          0x0A and 0x22 above
; Inputs:  (0x2530) = X0, (0x2534) = X1, (0x2532) = Y; (0x2540) the layer
; Outputs: the pixels from X0 to X1 at row Y set (OR, never cleared);
;          (0x255A) = the display address of the first byte; the four coordinate
;          words clamped in place.
; Evidence: the address arithmetic is LCD_PlotPointAt's, Y*(0x2557) + X/8 +
;          (0x2555); then CSRDIR **RIGHT** (0x4C) -- which is what makes it
;          horizontal, against the column services' CSRDIR DOWN -- and the
;          three-phase byte walk the rectangle fill also uses: MREAD the ragged
;          first byte, OR in LCD_Rect_LeftEdgeMask's mask, write it back, then
;          whole 0xFF bytes, then LCD_Rect_RightEdgeMask for the last one.  It
;          shares BOTH of those mask helpers with LCD_Svc_05_FillRect, which is
;          the cross-check.
;          0x4C = CSRDIR RIGHT is cited: ../mame/src/devices/video/sed1330.cpp:30.
; Unknown:  nothing outstanding beyond callers.
; ---------------------------------------------------------------------
LCD_Svc_01_DrawHLine:
	calr (0xF8EE93 - 0xF8F52B)                   ; F8F528  1e 68 f9   LCD_SelectCurrentLayer
	calr (0xF8EB6B - 0xF8F52E)                   ; F8F52B  1e 3d f6   LCD_ClampCoordsToPanel
	ldw_d16 wa, (0x2532)                          ; F8F52E  d1 32 25 20
	ldw_d16 bc, (0x2557)                          ; F8F532  d1 57 25 21
	mul xwa, xbc                                  ; F8F536  d9 40
	ld HL,WA                                      ; F8F538  d8 8b
	ldw_d16 wa, (0x2530)                          ; F8F53A  d1 30 25 20
	extz XWA                                      ; F8F53E  e8 12
	ldw bc, 0x08                                  ; F8F540  31 08 00
	divs xwa, xbc                                 ; F8F543  d9 58
	ld DE,QWA                                     ; F8F545  d7 e2 8a
	add HL,WA                                     ; F8F548  d8 83
	ldw_d16 wa, (0x2555)                          ; F8F54A  d1 55 25 20
	add WA,HL                                     ; F8F54E  db 80
	bit_dd8 0x00, 0xc6                            ; F8F550  f0 c6 c8
	jr nz, .LF8F55C                               ; F8F553  6e 07
.LF8F555:
	m_bit 6, MD24, 0x790000                       ; F8F555  f2 00 00 79 ce
	jr nz, .LF8F555                               ; F8F55A  6e f9
.LF8F55C:
	stib_da (0x790001), 0x4c                      ; F8F55C  f2 01 00 79 00 4c
	bit_dd8 0x00, 0xc6                            ; F8F562  f0 c6 c8
	jr nz, .LF8F56E                               ; F8F565  6e 07
.LF8F567:
	m_bit 6, MD24, 0x790000                       ; F8F567  f2 00 00 79 ce
	jr nz, .LF8F567                               ; F8F56C  6e f9
.LF8F56E:
	stib_da (0x790001), 0x46                      ; F8F56E  f2 01 00 79 00 46
	stda16 (0x255a), wa                           ; F8F574  f1 5a 25 50
	bit_dd8 0x00, 0xc6                            ; F8F578  f0 c6 c8
	jr nz, .LF8F584                               ; F8F57B  6e 07
.LF8F57D:
	m_bit 6, MD24, 0x790000                       ; F8F57D  f2 00 00 79 ce
	jr nz, .LF8F57D                               ; F8F582  6e f9
.LF8F584:
	stb_da (0x790000), a                          ; F8F584  f2 00 00 79 41
	bit_dd8 0x00, 0xc6                            ; F8F589  f0 c6 c8
	jr nz, .LF8F595                               ; F8F58C  6e 07
.LF8F58E:
	m_bit 6, MD24, 0x790000                       ; F8F58E  f2 00 00 79 ce
	jr nz, .LF8F58E                               ; F8F593  6e f9
.LF8F595:
	stb_da (0x790000), w                          ; F8F595  f2 00 00 79 40
	and DE,DE                                     ; F8F59A  da c2
	jrl z, .LF8F62B                               ; F8F59C  76 8c 00
	bit_dd8 0x00, 0xc6                            ; F8F59F  f0 c6 c8
	jr nz, .LF8F5AB                               ; F8F5A2  6e 07
.LF8F5A4:
	m_bit 6, MD24, 0x790000                       ; F8F5A4  f2 00 00 79 ce
	jr nz, .LF8F5A4                               ; F8F5A9  6e f9
.LF8F5AB:
	stib_da (0x790001), 0x43                      ; F8F5AB  f2 01 00 79 00 43
	bit_dd8 0x00, 0xc6                            ; F8F5B1  f0 c6 c8
	jr nz, .LF8F5BD                               ; F8F5B4  6e 07
.LF8F5B6:
	m_bit 6, MD24, 0x790000                       ; F8F5B6  f2 00 00 79 ce
	jr nz, .LF8F5B6                               ; F8F5BB  6e f9
.LF8F5BD:
	ldb_da w, (0x790001)                          ; F8F5BD  c2 01 00 79 20
	calr (0xF8F767 - 0xF8F5C5)                   ; F8F5C2  1e a2 01   LCD_Rect_LeftEdgeMask -> A
	or A,W                                        ; F8F5C5  c8 e1
	ld C,A                                        ; F8F5C7  c9 8b
	bit_dd8 0x00, 0xc6                            ; F8F5C9  f0 c6 c8
	jr nz, .LF8F5D5                               ; F8F5CC  6e 07
.LF8F5CE:
	m_bit 6, MD24, 0x790000                       ; F8F5CE  f2 00 00 79 ce
	jr nz, .LF8F5CE                               ; F8F5D3  6e f9
.LF8F5D5:
	stib_da (0x790001), 0x46                      ; F8F5D5  f2 01 00 79 00 46
	ldw_d16 wa, (0x255a)                          ; F8F5DB  d1 5a 25 20
	bit_dd8 0x00, 0xc6                            ; F8F5DF  f0 c6 c8
	jr nz, .LF8F5EB                               ; F8F5E2  6e 07
.LF8F5E4:
	m_bit 6, MD24, 0x790000                       ; F8F5E4  f2 00 00 79 ce
	jr nz, .LF8F5E4                               ; F8F5E9  6e f9
.LF8F5EB:
	stb_da (0x790000), a                          ; F8F5EB  f2 00 00 79 41
	bit_dd8 0x00, 0xc6                            ; F8F5F0  f0 c6 c8
	jr nz, .LF8F5FC                               ; F8F5F3  6e 07
.LF8F5F5:
	m_bit 6, MD24, 0x790000                       ; F8F5F5  f2 00 00 79 ce
	jr nz, .LF8F5F5                               ; F8F5FA  6e f9
.LF8F5FC:
	stb_da (0x790000), w                          ; F8F5FC  f2 00 00 79 40
	bit_dd8 0x00, 0xc6                            ; F8F601  f0 c6 c8
	jr nz, .LF8F60D                               ; F8F604  6e 07
.LF8F606:
	m_bit 6, MD24, 0x790000                       ; F8F606  f2 00 00 79 ce
	jr nz, .LF8F606                               ; F8F60B  6e f9
.LF8F60D:
	stib_da (0x790001), 0x42                      ; F8F60D  f2 01 00 79 00 42
	ldw hl, 0x08                                  ; F8F613  33 08 00
	sub HL,DE                                     ; F8F616  da a3
	ex16 hl, de                                   ; F8F618  da bb
	bit_dd8 0x00, 0xc6                            ; F8F61A  f0 c6 c8
	jr nz, .LF8F626                               ; F8F61D  6e 07
.LF8F61F:
	m_bit 6, MD24, 0x790000                       ; F8F61F  f2 00 00 79 ce
	jr nz, .LF8F61F                               ; F8F624  6e f9
.LF8F626:
	stb_da (0x790000), c                          ; F8F626  f2 00 00 79 43
.LF8F62B:
	ldw_d16 wa, (0x2534)                          ; F8F62B  d1 34 25 20
	m_sub_rm MW16, 0x2530, r0                     ; F8F62F  d1 30 25 a0
	inc 1,WA                                      ; F8F633  d8 61
	cp WA,DE                                      ; F8F635  da f0
	jrl ule, .LF8F738                             ; F8F637  73 fe 00
	sub WA,DE                                     ; F8F63A  da a0
	extz XWA                                      ; F8F63C  e8 12
	ldw bc, 0x08                                  ; F8F63E  31 08 00
	divs xwa, xbc                                 ; F8F641  d9 58
	ld DE,QWA                                     ; F8F643  d7 e2 8a
	and WA,WA                                     ; F8F646  d8 c0
	jr z, .LF8F676                                ; F8F648  66 2c
	ld BC,WA                                      ; F8F64A  d8 89
	bit_dd8 0x00, 0xc6                            ; F8F64C  f0 c6 c8
	jr nz, .LF8F658                               ; F8F64F  6e 07
.LF8F651:
	m_bit 6, MD24, 0x790000                       ; F8F651  f2 00 00 79 ce
	jr nz, .LF8F651                               ; F8F656  6e f9
.LF8F658:
	stib_da (0x790001), 0x42                      ; F8F658  f2 01 00 79 00 42
	ldb a, 0xff                                   ; F8F65E  21 ff
.LF8F660:
	nop                                           ; F8F660  00
	nop                                           ; F8F661  00
	bit_dd8 0x00, 0xc6                            ; F8F662  f0 c6 c8
	jr nz, .LF8F66E                               ; F8F665  6e 07
.LF8F667:
	m_bit 6, MD24, 0x790000                       ; F8F667  f2 00 00 79 ce
	jr nz, .LF8F667                               ; F8F66C  6e f9
.LF8F66E:
	stb_da (0x790000), a                          ; F8F66E  f2 00 00 79 41
	djnz16 bc, .LF8F660                           ; F8F673  d9 1c ea
.LF8F676:
	and DE,DE                                     ; F8F676  da c2
	jrl z, .LF8F738                               ; F8F678  76 bd 00
	bit_dd8 0x00, 0xc6                            ; F8F67B  f0 c6 c8
	jr nz, .LF8F687                               ; F8F67E  6e 07
.LF8F680:
	m_bit 6, MD24, 0x790000                       ; F8F680  f2 00 00 79 ce
	jr nz, .LF8F680                               ; F8F685  6e f9
.LF8F687:
	stib_da (0x790001), 0x47                      ; F8F687  f2 01 00 79 00 47
	bit_dd8 0x00, 0xc6                            ; F8F68D  f0 c6 c8
	jr nz, .LF8F699                               ; F8F690  6e 07
.LF8F692:
	m_bit 6, MD24, 0x790000                       ; F8F692  f2 00 00 79 ce
	jr nz, .LF8F692                               ; F8F697  6e f9
.LF8F699:
	ldb_da a, (0x790001)                          ; F8F699  c2 01 00 79 21
	bit_dd8 0x00, 0xc6                            ; F8F69E  f0 c6 c8
	jr nz, .LF8F6AA                               ; F8F6A1  6e 07
.LF8F6A3:
	m_bit 6, MD24, 0x790000                       ; F8F6A3  f2 00 00 79 ce
	jr nz, .LF8F6A3                               ; F8F6A8  6e f9
.LF8F6AA:
	ldb_da w, (0x790001)                          ; F8F6AA  c2 01 00 79 20
	stda16 (0x255a), wa                           ; F8F6AF  f1 5a 25 50
	bit_dd8 0x00, 0xc6                            ; F8F6B3  f0 c6 c8
	jr nz, .LF8F6BF                               ; F8F6B6  6e 07
.LF8F6B8:
	m_bit 6, MD24, 0x790000                       ; F8F6B8  f2 00 00 79 ce
	jr nz, .LF8F6B8                               ; F8F6BD  6e f9
.LF8F6BF:
	stib_da (0x790001), 0x43                      ; F8F6BF  f2 01 00 79 00 43
	bit_dd8 0x00, 0xc6                            ; F8F6C5  f0 c6 c8
	jr nz, .LF8F6D1                               ; F8F6C8  6e 07
.LF8F6CA:
	m_bit 6, MD24, 0x790000                       ; F8F6CA  f2 00 00 79 ce
	jr nz, .LF8F6CA                               ; F8F6CF  6e f9
.LF8F6D1:
	ldb_da w, (0x790001)                          ; F8F6D1  c2 01 00 79 20
	calr (0xF8F7A4 - 0xF8F6D9)                   ; F8F6D6  1e cb 00   LCD_Rect_RightEdgeMask -> A
	or A,W                                        ; F8F6D9  c8 e1

	ld C,A                                        ; F8F6DB  c9 8b
	bit_dd8 0x00, 0xc6                            ; F8F6DD  f0 c6 c8
	jr nz, .LF8F6E9                               ; F8F6E0  6e 07
.LF8F6E2:
	m_bit 6, MD24, 0x790000                       ; F8F6E2  f2 00 00 79 ce
	jr nz, .LF8F6E2                               ; F8F6E7  6e f9
.LF8F6E9:
	stib_da (0x790001), 0x46                      ; F8F6E9  f2 01 00 79 00 46
	ldw_d16 wa, (0x255a)                          ; F8F6EF  d1 5a 25 20
	bit_dd8 0x00, 0xc6                            ; F8F6F3  f0 c6 c8
	jr nz, .LF8F6FF                               ; F8F6F6  6e 07
.LF8F6F8:
	m_bit 6, MD24, 0x790000                       ; F8F6F8  f2 00 00 79 ce
	jr nz, .LF8F6F8                               ; F8F6FD  6e f9
.LF8F6FF:
	stb_da (0x790000), a                          ; F8F6FF  f2 00 00 79 41
	bit_dd8 0x00, 0xc6                            ; F8F704  f0 c6 c8
	jr nz, .LF8F710                               ; F8F707  6e 07
.LF8F709:
	m_bit 6, MD24, 0x790000                       ; F8F709  f2 00 00 79 ce
	jr nz, .LF8F709                               ; F8F70E  6e f9
.LF8F710:
	stb_da (0x790000), w                          ; F8F710  f2 00 00 79 40
	bit_dd8 0x00, 0xc6                            ; F8F715  f0 c6 c8
	jr nz, .LF8F721                               ; F8F718  6e 07
.LF8F71A:
	m_bit 6, MD24, 0x790000                       ; F8F71A  f2 00 00 79 ce
	jr nz, .LF8F71A                               ; F8F71F  6e f9
.LF8F721:
	stib_da (0x790001), 0x42                      ; F8F721  f2 01 00 79 00 42
	bit_dd8 0x00, 0xc6                            ; F8F727  f0 c6 c8
	jr nz, .LF8F733                               ; F8F72A  6e 07
.LF8F72C:
	m_bit 6, MD24, 0x790000                       ; F8F72C  f2 00 00 79 ce
	jr nz, .LF8F72C                               ; F8F731  6e f9
.LF8F733:
	stb_da (0x790000), c                          ; F8F733  f2 00 00 79 43
.LF8F738:
	ret                                           ; F8F738  0e

; ---------------------------------------------------------------------
; LCD_Svc_02_DrawVLine -- SWI7 service 0x02: a solid vertical run of pixels
;
; Called from: SWI7_ServiceTable slot 0x02 (0xF8E9CE), and from services 0x09,
;          0x0A and 0x22 above
; Inputs:  (0x2530) = X, (0x2532) = Y0, (0x2536) = Y1
; Outputs: the pixels from Y0 to Y1 in column X set.
; Evidence: it needs no masks at all -- a vertical run touches one BIT of each
;          of many bytes -- so the whole body is: count the rows as
;          (0x2536)-(0x2532)+1, return if that is zero, seed (0x2550)/(0x2552)
;          with X and Y0, then `calr LCD_PlotPointAt` / `incw 1,(0x2552)` in a
;          djnz loop.  That asymmetry with service 0x01 -- edge masks one way,
;          one plot per pixel the other -- is the shape of a 1-bit framebuffer
;          laid out in rows.
;          ⚠ It does NOT clamp: unlike service 0x01 it calls only
;          LCD_SelectCurrentLayer, so an out-of-range Y is the caller's problem.
; Unknown:  nothing outstanding beyond callers.
; ---------------------------------------------------------------------
LCD_Svc_02_DrawVLine:
	calr (0xF8EE93 - 0xF8F73C)                   ; F8F739  1e 57 f7   LCD_SelectCurrentLayer
	ldw_d16 bc, (0x2536)                          ; F8F73C  d1 36 25 21
	m_sub_rm MW16, 0x2532, r1                     ; F8F740  d1 32 25 a1
	inc 1,BC                                      ; F8F744  d9 61
	and BC,BC                                     ; F8F746  d9 c1
	jr z, .LF8F766                                ; F8F748  66 1c
	ldw_d16 wa, (0x2530)                          ; F8F74A  d1 30 25 20
	stda16 (0x2550), wa                           ; F8F74E  f1 50 25 50
	ldw_d16 wa, (0x2532)                          ; F8F752  d1 32 25 20
	stda16 (0x2552), wa                           ; F8F756  f1 52 25 50
.LF8F75A:
	pushw bc                                      ; F8F75A  29
	calr (0xF8ECCF - 0xF8F75E)                   ; F8F75B  1e 71 f5   LCD_PlotPointAt
	popw bc                                       ; F8F75E  49
	incdi16 0x01, (0x2552)                        ; F8F75F  d1 52 25 61
	djnz16 bc, .LF8F75A                           ; F8F763  d9 1c f4
.LF8F766:
	ret                                           ; F8F766  0e

; ==============================================================================
; 0xF8F767-0xF8F7B7 -- the two edge-mask helpers of the rectangle fill
; ==============================================================================
;
; ★ THE BIT ORDER IS MSB-LEFTMOST, and these tables re-prove it.  The pixel
;   plotter's table at 0xF8EDAC is `80 40 20 10 08 04 02 01` indexed by X mod 8,
;   so pixel k of a byte is bit 7-k.  A left edge that starts at pixel k must
;   therefore keep bits 7-k..0, i.e. 0xFF >> k -- and that is exactly what
;   LCD_LeftEdgeMask_Table holds for k = 1..7.  A right edge that ends before
;   pixel k must keep bits 7..8-k, i.e. 0xFF << (8-k) -- which is
;   LCD_RightEdgeMask_Table.  Two tables derived from one convention, and they
;   agree with a third table in another routine.

; ---------------------------------------------------------------------
; LCD_Rect_LeftEdgeMask -- A := the pixel mask of the box's first byte-column
;
; Called from: LCD_Svc_05_FillRect (0xF8EF46)
; Inputs:  DE = X0 mod 8, always 1..7 here (the caller skips this whole phase
;          when it is 0); (0x2530)/(0x2534) = the box's X range.
; Outputs: A = the mask; BC clobbered.
; Evidence: it indexes LCD_LeftEdgeMask_Table with DE and then, IF the box is
;          narrower than the 8-DE pixels that mask covers, shifts the mask right
;          and back left by the excess -- which clears exactly the low bits that
;          lie past the box's right edge.  Both shifts are the variable
;          shift-by-a-register form (`cb ff` / `cb fc`), which llvm-mc cannot
;          encode; they stay as .byte with unidasm's text beside them.
; Unknown:  nothing outstanding.
; ---------------------------------------------------------------------
LCD_Rect_LeftEdgeMask:
	ldw bc, 0x08                                  ; F8F767  31 08 00
	sub BC,DE                                     ; F8F76A  da a1   BC = pixels this mask covers
	ld XHL,0x00f8f79b                             ; F8F76C  43 9b f7 f8 00   LCD_LeftEdgeMask_Table
	.byte 0xc3, 0x07, 0xec, 0xe8, 0x21            ; F8F771  c3 07 ec e8 21   ld A,(XHL+DE) -- llvm-mc has no spelling
	ldw_d16 hl, (0x2534)                          ; F8F776  d1 34 25 23
	m_sub_rm MW16, 0x2530, r3                     ; F8F77A  d1 30 25 a3
	inc 1,HL                                      ; F8F77E  db 61   HL = the box width in pixels
	cp BC,HL                                      ; F8F780  db f1
	jr ule, .LF8F79A                              ; F8F782  63 16   the box is wider: keep the whole mask
	sub BC,HL                                     ; F8F784  db a1   C = how many low bits lie past the right edge
	cps c, 0x00                                   ; F8F786  cb d8
	jr z, .LF8F79A                                ; F8F788  66 10
	ex8 a, c                                      ; F8F78A  cb b9
	.byte 0xcb, 0xff                              ; F8F78C  cb ff   srl A,C -- shift the mask right by that count
	ex8 a, c                                      ; F8F78E  cb b9
	cps c, 0x00                                   ; F8F790  cb d8
	jr z, .LF8F79A                                ; F8F792  66 06
	ex8 a, c                                      ; F8F794  cb b9
	.byte 0xcb, 0xfc                              ; F8F796  cb fc   sla A,C -- and back, so those bits are now 0
	ex8 a, c                                      ; F8F798  cb b9
.LF8F79A:
	ret                                           ; F8F79A  0e

; ---------------------------------------------------------------------
; LCD_LeftEdgeMask_Table -- 9 bytes: keep pixels k..7 of a byte
;
; Read by:  LCD_Rect_LeftEdgeMask (0xF8F76C), indexed by X0 mod 8.
; Layout:   9 bytes, 0xF8F79B-0xF8F7A3, one per index 0..8; entry k is
;           0xFF >> k for k = 1..7 and 0x00 at both ends.
; Count:    9 is fixed by the addresses, not by inspection: the table starts at
;           0xF8F79B because that is the immediate LCD_Rect_LeftEdgeMask loads,
;           and 0xF8F7A4 is the first instruction of LCD_Rect_RightEdgeMask, so
;           nine bytes is all the room there is.
;           ⚠ Only indices 1..7 are reachable -- the one call site skips the
;           whole phase when X0 mod 8 is 0, and `div` by 8 cannot produce 8.
;           Whether index 0 and index 8 are entries or padding is NOT decided
;           here; both are 0x00, which is harmless either way.
; ---------------------------------------------------------------------
LCD_LeftEdgeMask_Table:
	.byte 0x00			; F8F79B  index 0 -- unreachable
	.byte 0x7F			; F8F79C  index 1 -- pixels 1..7
	.byte 0x3F			; F8F79D  index 2
	.byte 0x1F			; F8F79E  index 3
	.byte 0x0F			; F8F79F  index 4
	.byte 0x07			; F8F7A0  index 5
	.byte 0x03			; F8F7A1  index 6
	.byte 0x01			; F8F7A2  index 7 -- pixel 7 only
	.byte 0x00			; F8F7A3  index 8 -- unreachable

; ---------------------------------------------------------------------
; LCD_Rect_RightEdgeMask -- A := the pixel mask of the box's last byte-column
;
; Called from: LCD_Svc_05_FillRect (0xF8F019)
; Inputs:  DE = the pixels left over after the whole bytes, 1..7
; Outputs: A = the mask; XHL clobbered.
; Evidence: a table lookup and nothing else -- no clipping is needed at this end
;          because the leftover count came from the division and is already
;          inside one byte.
; ---------------------------------------------------------------------
LCD_Rect_RightEdgeMask:
	ld XHL,0x00f8f7af                             ; F8F7A4  43 af f7 f8 00   LCD_RightEdgeMask_Table
	.byte 0xc3, 0x07, 0xec, 0xe8, 0x21            ; F8F7A9  c3 07 ec e8 21   ld A,(XHL+DE)
	ret                                           ; F8F7AE  0e

; ---------------------------------------------------------------------
; LCD_RightEdgeMask_Table -- 9 bytes: keep pixels 0..k-1 of a byte
;
; Read by:  LCD_Rect_RightEdgeMask (0xF8F7A4), indexed by the leftover width.
; Layout:   9 bytes, 0xF8F7AF-0xF8F7B7, entry k = 0xFF << (8-k) for k = 1..7.
; Count:    same argument as the other table -- 0xF8F7B8 is
;           LCD_Svc_0C_SetLayersOn's first instruction (converted below), so the
;           table cannot be longer, and the load at 0xF8F7A4 fixes where it
;           starts.  Only indices 1..7 are reachable.
; ---------------------------------------------------------------------
LCD_RightEdgeMask_Table:
	.byte 0x00			; F8F7AF  index 0 -- unreachable
	.byte 0x80			; F8F7B0  index 1 -- pixel 0 only
	.byte 0xC0			; F8F7B1  index 2
	.byte 0xE0			; F8F7B2  index 3
	.byte 0xF0			; F8F7B3  index 4
	.byte 0xF8			; F8F7B4  index 5
	.byte 0xFC			; F8F7B5  index 6
	.byte 0xFE			; F8F7B6  index 7 -- pixels 0..6
	.byte 0x00			; F8F7B7  index 8 -- unreachable

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
	.incbin "original_ROMs/wsa1_prom_a.ic12", 0x02570C, 0x03FDAA

; ==============================================================================
; 0xFE54B6-0xFE54EB -- the five accessors of the CS0 device at 0x7B0004/0x7B0005
; ==============================================================================
;
; ★ THESE FIVE ROUTINES ARE THE ONLY CODE IN EITHER IMAGE THAT TOUCHES THE
;   DEVICE.  A byte census over prom_a and prom_b of the 24-bit memory-operand
;   form (`C2/D2/E2/F2 <lo> <mid> <hi> <op>`) for every address 0x7B0000-0x7B000F
;   finds five hits in total: 0xFE54B6, 0xFE54C5, 0xFE54DD (register 0x7B0004)
;   and 0xFE54BC, 0xFE54E6 (register 0x7B0005), all inside this block, and none
;   anywhere in prom_b.  So every use of the device goes through here, and the
;   argument convention below is the whole interface.
;
; WHICH REGISTER IS WHICH.  0x7B0004 is the CONTROL/STATUS register and 0x7B0005
; the DATA register, read off the caller rather than assumed: INT5_Dev7B_Receive
; (0xFE6866, below) spins on bit 7 and bit 6 of 0x7B0004 as flags and never
; stores that byte anywhere, and reads 0x7B0005 exactly once per byte received,
; storing each one into the packet buffer at 0x605A51.
;
; ⚠ WHAT THE DEVICE IS has not been established.  notes/FINDINGS-memory-map.md
; lists 0x7B0004/0x7B0005 as "byte registers" on CS0 and no further.  Do not
; name it.
;
; ---------------------------------------------------------------------
; Dev7B_ReadStatus / Dev7B_ReadData / Dev7B_WriteControl /
; Dev7B_WriteControl_Shadowed / Dev7B_WriteData
;
; Called from: INT5_Dev7B_Receive (0xFE6866) calls ReadStatus at 0xFE6879,
;          0xFE6881, 0xFE6889, 0xFE6891, 0xFE68B4 and 0xFE68BC, ReadData at
;          0xFE68AE and WriteData at 0xFE689F.  The two control writers are
;          called from routines not yet converted.
; Inputs:  the writers take their byte at (XSP+0x04) -- a stack argument, so
;          they are compiler-called and the caller cleans up (0xFE68A2's
;          `inc 2,XSP` is one such site).
; Outputs: the readers return the byte in L; the writers write the register.
;          A is clobbered by the writers.
; Evidence: each routine is one load or one store of one named register and a
;          RET, so the names are mechanical.  The "Shadowed" one additionally
;          keeps the previous control byte at (0x605B08) and the new one at
;          (0x605B09) -- a write-only register that software has to remember.
; Unknown:  the device, and the meaning of any control bit.
; ---------------------------------------------------------------------
Dev7B_ReadStatus:
	ldb_da l, (0x7b0004)                          ; FE54B6  c2 04 00 7b 27
	ret                                           ; FE54BB  0e
Dev7B_ReadData:
	ldb_da l, (0x7b0005)                          ; FE54BC  c2 05 00 7b 27
	ret                                           ; FE54C1  0e
Dev7B_WriteControl:
	ld A,(XSP+0x04)                               ; FE54C2  8f 04 21
	stb_da (0x7b0004), a                          ; FE54C5  f2 04 00 7b 41
	ret                                           ; FE54CA  0e
Dev7B_WriteControl_Shadowed:
	ldb_da a, (0x605b09)                          ; FE54CB  c2 09 5b 60 21   the current shadow ...
	stb_da (0x605b08), a                          ; FE54D0  f2 08 5b 60 41   ... becomes the previous one
	ld A,(XSP+0x04)                               ; FE54D5  8f 04 21
	stb_da (0x605b09), a                          ; FE54D8  f2 09 5b 60 41
	stb_da (0x7b0004), a                          ; FE54DD  f2 04 00 7b 41
	ret                                           ; FE54E2  0e
Dev7B_WriteData:
	ld A,(XSP+0x04)                               ; FE54E3  8f 04 21
	stb_da (0x7b0005), a                          ; FE54E6  f2 05 00 7b 41
	ret                                           ; FE54EB  0e
	.incbin "original_ROMs/wsa1_prom_a.ic12", 0x0654EC, 0x000460

; ==============================================================================
; 0xFE594C-0xFE5A40 -- micro-DMA channel 0 and the 0x7A0000 data port
; ==============================================================================
;
; ★ WHAT INT7 IS FOR, and what channel 0 moves.  INTTC0_uDMA0Done (0xFE6851,
;   converted below) calls two leaf routines and re-arms `DMA0V = 0x0E`, i.e.
;   trigger = INT7.  Both leaves are here, and so is the code that programmes the
;   rest of the channel -- and it programmes it to move BYTES between the CS0
;   window at 0x7A0000 and a RAM buffer whose address is held in (0x605A3C):
;
;     Dev7A_Dma_DeviceToRam  DMAS0 = 0x007A0000, DMAD0 = (0x605A3C), DMAM0 = 0x00
;     Dev7A_Dma_RamToDevice  DMAS0 = (0x605A3C), DMAD0 = 0x007A0000, DMAM0 = 0x08
;
;   MAME's micro-DMA decoder gives those two modes exactly the meaning the pairing
;   needs (../mame/src/devices/cpu/tlcs900/tmp95c061.cpp:366-402): mode 0x00 is
;   "byte, increment the DESTINATION" -- so the source 0x7A0000 stays put and the
;   RAM pointer walks -- and mode 0x08 is "byte, increment the SOURCE", the mirror
;   image.  A fixed address on one side and a walking address on the other is a
;   DATA PORT, and 0x7A0000 is on the CS0 window with 0x7B0000
;   (notes/FINDINGS-memory-map.md).
;
;   So the picture the 0x7B accessors left open closes here: 0x7B0004/0x7B0005 are
;   the COMMAND/STATUS registers of a device (notes/FINDINGS-dev7b-and-int5.md)
;   and 0x7A0000 is the same subsystem's BULK DATA port, moved by micro-DMA
;   channel 0 with INT7 as the per-byte request line.  `Dev7A_` is used below as
;   a positional name for that window, exactly as `Dev7B_` already is for the
;   other one; neither is a part name and no part is claimed.
;
; ⚠ THIS ALSO REMOVES THE LAST PROP FROM THE RETRACTED "INT7 IS UNREACHABLE"
;   ARGUMENT (audit round 1, F2, and see INTTC0_uDMA0Done's header).  INT7 now has
;   an identified requester -- a peripheral that raises it once per byte -- and the
;   firmware disarms channel 0 implicitly at end-of-count and explicitly nowhere.
;
; EVERY REFERENCE TO THE 0x7A WINDOW, and there are only four.  Censusing
; 0x7A0000-0x7A000F over prom_a and prom_b for the 24-bit memory-operand forms
; (`C2/D2/E2/F2 <lo> <mid> <hi>`) and for `ld XRR,imm32` finds four sites, all
; naming 0x7A0000 and none naming any other address in the window:
;
;   0xFE59BB  ld XHL,0x007A0000   this block: DMAS0, the device->RAM setup
;   0xFE59DA  ld XHL,0x007A0000   this block: DMAD0, the RAM->device setup
;   0xFE680F  ld C,(0x7A0000)     still .incbin -- a PROGRAMMED-I/O read, stored
;                                 through the pointer at (0x605A3E), which is then
;                                 incremented
;   0xFE682B  ld (0x7A0000),C     still .incbin -- the programmed-I/O write, same
;                                 pointer, same increment
;
; So the firmware has BOTH a micro-DMA path (here) and a byte-at-a-time path
; (0xFE680F/0xFE682B, in the INTTC0/INT5 neighbourhood) to the same single
; address -- which is the strongest single argument that 0x7A0000 is one data
; register and not a range.  ⚠ The two paths use different pointer variables,
; (0x605A3C) here and (0x605A3E) there, and those two 32-bit slots OVERLAP in
; RAM; recorded as observed, not explained.
;
; ⚠ NOT ESTABLISHED: what the device is; what (0x605A18)'s ten command codes
;   mean; when the firmware chooses DMA over programmed I/O.

; ---------------------------------------------------------------------
; PortB3_Pulse -- set bit 3 of PB, wait five NOPs, clear it again
;
; Called from: INTTC0_uDMA0Done (0xFE6858), the micro-DMA channel-0 completion
;          handler.  No other site.
; Inputs:  none.  Outputs: PB (SFR 0x1F) bit 3 pulsed high; A clobbered.
; Evidence: entirely mechanical -- read PB, OR 0x08, write, five NOPs, read PB,
;          AND 0xF7, write.  SFR 0x1F is PB in MAME's register table for this
;          part (../mame/src/devices/cpu/tlcs900/tmp95c061.cpp:1363) and in
;          include/tmp95c061_sfr.inc.  The name says what it does and nothing
;          more.
; Unknown:  ⚠ what PB bit 3 is wired to.  A pulse issued the instant a channel-0
;          transfer finishes is what an "acknowledge" or "next block" strobe to
;          the 0x7A/0x7B device looks like, but no schematic is in these trees
;          and the read-modify-write is not enough to claim it.
; ---------------------------------------------------------------------
PortB3_Pulse:
	ld_sd8b a, 0x1f                               ; FE594C  c0 1f 21   PB
	or A,0x08                                     ; FE594F  c9 ce 08
	st_dd8b a, 0x1f                               ; FE5952  f0 1f 41   bit 3 high
	nop                                           ; FE5955  00
	nop                                           ; FE5956  00
	nop                                           ; FE5957  00
	nop                                           ; FE5958  00
	nop                                           ; FE5959  00
	ld_sd8b a, 0x1f                               ; FE595A  c0 1f 21
	and A,0xf7                                    ; FE595D  c9 cc f7
	st_dd8b a, 0x1f                               ; FE5960  f0 1f 41   bit 3 low again
	ret                                           ; FE5963  0e

; ---------------------------------------------------------------------
; uDMA0_ArmOnINT7 -- DMA0V := 0x0E, so INT7 drives micro-DMA channel 0
;
; Called from: INTTC0_uDMA0Done (0xFE685B); and reached by falling out of
;          Dev7A_Dma_DeviceToRam (0xFE59D0 `jr`) and Dev7A_Dma_RamToDevice
;          (0xFE59E7 `jrl`), which is how a freshly programmed channel is armed.
; Inputs:  none.  Outputs: DMA0V (SFR 0x7C) = 0x0E.
; Evidence: `ldio 0x7C,0x0E`, and MAME computes a channel's trigger as
;          `(DMAnV & 0x1f) << 2` (tmp95c061.cpp:353); 0x0E << 2 = 0x38 = INT7.
; Notes:   the two bytes at 0xFE5964 are `jr +0`, an entry point that does
;          nothing but fall into the next instruction.  It is written out as a
;          separate label because something may enter there; nothing found does.
; ---------------------------------------------------------------------
uDMA0_ArmOnINT7__jrentry:
	jr uDMA0_ArmOnINT7                            ; FE5964  68 00
uDMA0_ArmOnINT7:
	ldio 0x7c, 0x0e                               ; FE5966  08 7c 0e   DMA0V; 0x0E << 2 = 0x38 = INT7
	ret                                           ; FE5969  0e

; ---------------------------------------------------------------------
; Dev7A_StartDma -- load the byte count, then arm channel 0 in the direction the
;                   pending command byte asks for
;
; Called from: FOUR PC-relative sites in prom_a -- 0xFE5FE5, 0xFE6300, 0xFE6427
;          and 0xFE65D6, every one of them `calr 0xFE596A` and every one of them
;          converging under backward disassembly (17-21 of 64 starts, the same
;          range as the known-good sites in notes/prom_a_addr_census.py).  All
;          four are still .incbin.  0xFE6427 shows the calling convention plainly:
;          `ld (0x605A3C),XWA` immediately before, so the caller writes the buffer
;          address and then asks for the transfer.
;          ⚠ An earlier draft of this header said "not yet traced -- no
;          PC-relative branch in prom_a targets it".  That was a searched negative
;          from a search that had only been run over four other addresses; the
;          check in notes/prom_a_byte_checks.py, which re-derives every such
;          sentence, is what caught it.
; Inputs:  (0x605A0E) 16-bit = the transfer count; (0x605A18) 8-bit = the command
;          code that selects the direction.
; Outputs: DMAC0 loaded; then either channel 0 armed for a device->RAM transfer,
;          or armed for a RAM->device transfer, or nothing at all.  WA, BC, A, XHL
;          clobbered.
; Evidence: the first two instructions are `ld BC,(0x605A0E)` / `ldc DMAC0,BC`,
;          and DMAC0 is the 16-bit transfer count (control-register numbers per
;          MAME 900tbl.hxx:3931-4030; the .equ block at the top of this file).
;          The rest is a flat compare chain on one byte, and the two arms are the
;          two direction setups below.
; Notes:   THE COMMAND CODES, read off the chain and grouped by where they jump:
;              RAM -> device : 0x4D 0xC9 0xC5
;              device -> RAM : 0xDD 0xD9 0xD1 0x4A 0x42 0xCC 0xC6
;              anything else : return, having still written DMAC0
;          Ten codes, three of them writes.  ⚠ WHAT THEY MEAN IS NOT KNOWN, and
;          nothing here says they are a standard command set.  They are recorded
;          as the ten literals the ROM compares against, in ROM order.
;          The write group is entered with `calr` + `ret` and the read group with
;          `jr`, so both paths end in uDMA0_ArmOnINT7.
; Unknown:  who calls this; what sets (0x605A18) and (0x605A0E).
; ---------------------------------------------------------------------
Dev7A_StartDma:
	ldw_da bc, (0x605a0e)                         ; FE596A  d2 0e 5a 60 21   the byte count
	m_ldc_cr_reg RW+r1, CR_DMAC0                  ; FE596F  d9 2e 20
	ldb_da a, (0x605a18)                          ; FE5972  c2 18 5a 60 21   the command code
	extz WA                                       ; FE5977  d8 12
	cp WA,0x004d                                  ; FE5979  d8 cf 4d 00
	jr z, Dev7A_StartDma__write                   ; FE597D  66 38
	cp WA,0x00c9                                  ; FE597F  d8 cf c9 00
	jr z, Dev7A_StartDma__write                   ; FE5983  66 32
	cp WA,0x00c5                                  ; FE5985  d8 cf c5 00
	jr z, Dev7A_StartDma__write                   ; FE5989  66 2c
	cp WA,0x00dd                                  ; FE598B  d8 cf dd 00
	jr z, Dev7A_StartDma__read                    ; FE598F  66 24
	cp WA,0x00d9                                  ; FE5991  d8 cf d9 00
	jr z, Dev7A_StartDma__read                    ; FE5995  66 1e
	cp WA,0x00d1                                  ; FE5997  d8 cf d1 00
	jr z, Dev7A_StartDma__read                    ; FE599B  66 18
	cp WA,0x004a                                  ; FE599D  d8 cf 4a 00
	jr z, Dev7A_StartDma__read                    ; FE59A1  66 12
	cp WA,0x0042                                  ; FE59A3  d8 cf 42 00
	jr z, Dev7A_StartDma__read                    ; FE59A7  66 0c
	cp WA,0x00cc                                  ; FE59A9  d8 cf cc 00
	jr z, Dev7A_StartDma__read                    ; FE59AD  66 06
	cp WA,0x00c6                                  ; FE59AF  d8 cf c6 00
	jr nz, Dev7A_StartDma__ret                    ; FE59B3  6e 05   an unlisted code does nothing
Dev7A_StartDma__read:
	jr Dev7A_Dma_DeviceToRam                      ; FE59B5  68 04
Dev7A_StartDma__write:
	calr Dev7A_Dma_RamToDevice                    ; FE59B7  1e 18 00
Dev7A_StartDma__ret:
	ret                                           ; FE59BA  0e

; ---------------------------------------------------------------------
; Dev7A_Dma_DeviceToRam -- programme channel 0 to read 0x7A0000 into (0x605A3C)
;
; Called from: Dev7A_StartDma__read (0xFE59B5), for seven of the ten codes.
; Inputs:  (0x605A3C) 32-bit = the destination address in RAM.  DMAC0 must
;          already hold the count -- Dev7A_StartDma sets it before branching here.
; Outputs: DMAS0 = 0x007A0000, DMAD0 = (0x605A3C), DMAM0 = 0x00, and then it
;          falls into uDMA0_ArmOnINT7, so the channel is live on return.  XHL, A
;          clobbered.  Does not return to its caller -- the `jr` is a tail call.
; Evidence: mode 0x00 is "transfer one byte, then increment the DESTINATION"
;          (tmp95c061.cpp:368-372), which with a fixed source at 0x7A0000 is a
;          read out of a data port into a walking RAM pointer.
; ---------------------------------------------------------------------
Dev7A_Dma_DeviceToRam:
	ld XHL,0x007a0000                             ; FE59BB  43 00 00 7a 00
	m_ldc_cr_reg RL+r3, CR_DMAS0                  ; FE59C0  eb 2e 00   source = the data port, FIXED
	ldl_da xhl, (0x605a3c)                        ; FE59C3  e2 3c 5a 60 23
	m_ldc_cr_reg RL+r3, CR_DMAD0                  ; FE59C8  eb 2e 10   destination = RAM, walking
	ldb a, 0x00                                   ; FE59CB  21 00
	m_ldc_cr_reg RB+r1, CR_DMAM0                  ; FE59CD  c9 2e 22   mode 0x00 = byte, DST++
	jr uDMA0_ArmOnINT7                            ; FE59D0  68 94

; ---------------------------------------------------------------------
; Dev7A_Dma_RamToDevice -- programme channel 0 to write (0x605A3C) into 0x7A0000
;
; Called from: Dev7A_StartDma__write (0xFE59B7), for codes 0x4D, 0xC9 and 0xC5.
; Inputs:  (0x605A3C) 32-bit = the source address in RAM; DMAC0 already loaded.
; Outputs: DMAS0 = (0x605A3C), DMAD0 = 0x007A0000, DMAM0 = 0x08, then it tails
;          into uDMA0_ArmOnINT7.  XHL, A clobbered.
; Evidence: mode 0x08 is "transfer one byte, then increment the SOURCE"
;          (tmp95c061.cpp:398-402) -- the exact mirror of the routine above, with
;          the two control registers exchanged.
; ---------------------------------------------------------------------
Dev7A_Dma_RamToDevice:
	ldl_da xhl, (0x605a3c)                        ; FE59D2  e2 3c 5a 60 23
	m_ldc_cr_reg RL+r3, CR_DMAS0                  ; FE59D7  eb 2e 00   source = RAM, walking
	ld XHL,0x007a0000                             ; FE59DA  43 00 00 7a 00
	m_ldc_cr_reg RL+r3, CR_DMAD0                  ; FE59DF  eb 2e 10   destination = the data port, FIXED
	ldb a, 0x08                                   ; FE59E2  21 08
	m_ldc_cr_reg RB+r1, CR_DMAM0                  ; FE59E4  c9 2e 22   mode 0x08 = byte, SRC++
	jrl uDMA0_ArmOnINT7                           ; FE59E7  78 7c ff

; ---------------------------------------------------------------------
; uDMA0_SetCount -- DMAC0 := (0x605A0E)
;
; Called from: not traced.  Inputs: (0x605A0E).  Outputs: DMAC0; BC clobbered.
; Evidence: the same two instructions Dev7A_StartDma opens with, on their own.
; ---------------------------------------------------------------------
uDMA0_SetCount:
	ldw_da bc, (0x605a0e)                         ; FE59EA  d2 0e 5a 60 21
	m_ldc_cr_reg RW+r1, CR_DMAC0                  ; FE59EF  d9 2e 20
	ret                                           ; FE59F2  0e

; ---------------------------------------------------------------------
; Dev7B_WaitStatus_8x_Cx -- poll the 0x7B status until it reads 0x8n or 0xCn,
;                           for at most 500 ticks
;
; Called from: not traced.  A near-twin starts at 0xFE5A41 (still .incbin) and
;          differs only in masking with 0xE0 instead of clearing bit 4.
; Inputs:  the 0x7B0004 status register, through Dev7B_ReadStatus (0xFE54B6);
;          (0x605A00), the 16-bit tick counter INTT1_Tick increments
;          (`inc 1,(0x605A00)` at 0xF82D14, converted above).
; Outputs: returns with QIZ = 0 on success and 0xFFFF on timeout, having called
;          0xFE5E84 with the argument 2 in the timeout case.  XIZ preserved.
; Evidence: the loop body is Dev7B_ReadStatus, `res 4,A`, and equality against
;          0x80 and 0xC0 -- i.e. the top three bits must be 100 or 110 and bit 4
;          is not looked at.  The exit test subtracts the entry snapshot of
;          (0x605A00) from its current value and compares against 0x1F4 = 500,
;          the same tick-count idiom Link_WaitBlockDone uses on (0x80)
;          (0xF8E67D, converted above).
; Notes:   QIZ, the upper half of XIZ, is used as the loop's state variable:
;          0x0080 = still waiting, 0x0000 = ready, 0xFFFF = timed out.
; Unknown:  what 0xFE5E84 does with the code 2 -- it is called the same way from
;          several sites in this region and looks like an error reporter, but it
;          is not converted and is not named here.
; ---------------------------------------------------------------------
Dev7B_WaitStatus_8x_Cx:
	push XIZ                                      ; FE59F3  3e
	ldw_da iz, (0x605a00)                         ; FE59F4  d2 00 5a 60 26   the tick at entry
	ldw qiz, 0x80                                 ; FE59F9  d7 fa 03 80 00   state = waiting
Dev7B_WaitStatus_8x_Cx__poll:
	calr Dev7B_ReadStatus                         ; FE59FE  1e b5 fa
	ld A,L                                        ; FE5A01  cf 89
	res 0x04,A                                    ; FE5A03  c9 30 04   bit 4 is don't-care
	extz WA                                       ; FE5A06  d8 12
	cp WA,0x0080                                  ; FE5A08  d8 cf 80 00
	jr z, Dev7B_WaitStatus_8x_Cx__timecheck       ; FE5A0C  66 09
	cp WA,0x00c0                                  ; FE5A0E  d8 cf c0 00
	jr nz, Dev7B_WaitStatus_8x_Cx__timecheck      ; FE5A12  6e 03
	ld QIZ,0                                      ; FE5A14  d7 fa a8   state = ready
Dev7B_WaitStatus_8x_Cx__timecheck:
	ldw_da wa, (0x605a00)                         ; FE5A17  d2 00 5a 60 20
	sub WA,IZ                                     ; FE5A1C  de a0
	cp WA,0x01f4                                  ; FE5A1E  d8 cf f4 01   500 ticks
	jr ule, Dev7B_WaitStatus_8x_Cx__again         ; FE5A22  63 07
	ldw qiz, 0xffff                               ; FE5A24  d7 fa 03 ff ff   state = timed out
	jr Dev7B_WaitStatus_8x_Cx__done               ; FE5A29  68 07
Dev7B_WaitStatus_8x_Cx__again:
	cpw qiz, 0x80                                 ; FE5A2B  d7 fa cf 80 00
	jr z, Dev7B_WaitStatus_8x_Cx__poll            ; FE5A30  66 cc
Dev7B_WaitStatus_8x_Cx__done:
	cp QIZ,0                                      ; FE5A32  d7 fa d8
	jr z, Dev7B_WaitStatus_8x_Cx__ret             ; FE5A35  66 08
	pushw 0x02                                    ; FE5A37  0b 02 00
	calr (0xFE5E84 - 0xFE5A3D)                    ; FE5A3A  1e 47 04   an error path, not converted
	inc 2,XSP                                     ; FE5A3D  ef 62
Dev7B_WaitStatus_8x_Cx__ret:
	pop XIZ                                       ; FE5A3F  5e
	ret                                           ; FE5A40  0e

; ==============================================================================
; 0xFE5A41-0xFE6850 -- not yet converted
; ==============================================================================
	.incbin "original_ROMs/wsa1_prom_a.ic12", 0x065A41, 0x000E10

; ==============================================================================
; 0xFE6851-0xFE68F2 -- INTTC0, INT5, and a wide integer multiply
; ==============================================================================
;
; ⚠ BOTH HANDLERS ARE REACHED THROUGH TWO LEVELS OF THUNK, not one.  The vector
; goes to a prom_b thunk-table slot, and that slot jumps to a slot of a SECOND,
; eight-entry `jp` table at prom_a 0xFE3000 which is the entry directory of
; whatever module lives in the 0xFE3000-0xFE68xx block:
;
;   0xFE3000 jp 0xFE3020   0xFE3004 jp 0xFE3032   0xFE3008 jp 0xFE6866
;   0xFE300C jp 0xFE30D8   0xFE3010 jp 0xFE6851   0xFE3014 jp 0xFE3042
;   0xFE3018 jp 0xFE308D   0xFE301C jp 0xFE6866
;
; All eight slots are `1B lo mid hi` (`jp nnn`), which is what makes it a table
; and fixes its length at eight; slot 0x1C repeats slot 0x08's target.
; The two vectors that arrive here are
;   0xFFFF30 INT5   -> prom_b 0xF42D28 `jp 0xFE3008` -> `jp 0xFE6866`
;   0xFFFF74 INTTC0 -> prom_b 0xF42D30 `jp 0xFE3010` -> `jp 0xFE6851`
; (slot names 0x30 = INT5 and 0x74 = INTTC0 are cited from MAME's
; tmp95c061_irq_vector_map[], ../mame/src/devices/cpu/tlcs900/tmp95c061.cpp:326
; and :338).

; ---------------------------------------------------------------------
; INTTC0_uDMA0Done -- micro-DMA channel 0 finished its transfer
;
; Called from: vector slot 0x74 (INTTC0) by the two-thunk route above;
;          notes/prom_a_xref.py finds 0xFE3010 as the only site naming it.
; Inputs:  none -- it takes no arguments and reads no RAM itself.
; Outputs: whatever the two leaf helpers do; all seven long registers are saved
;          and restored, so it clobbers nothing.  Exits with RETI.
; Evidence: the vector slot is the name.  What it does is two calls:
;          0xFE594C sets and then clears bit 3 of PB (SFR 0x1F) with five NOPs
;          in between -- a pulse on a port pin -- and 0xFE5966 is
;          `ldio DMA0V, 0x0E` and nothing else.  DMA0V is the channel-0 start
;          vector, and MAME computes a channel's trigger as
;          `(DMAnV & 0x1f) << 2` (tmp95c061.cpp:353), so 0x0E << 2 = 0x38 =
;          **INT7** -- the handler re-arms channel 0 to be driven by INT7.
;
;          ⚠ RETRACTED (audit round 1, F2).  This header used to conclude:
;          "that is also why vector slot 0x38 (INT7) points at
;          IRQ_UnusedVector_Hang -- INT7 is never meant to reach the CPU,
;          because the micro-DMA engine absorbs it; the hang is unreachable, not
;          a bug."  The arithmetic above survives; that conclusion does not, and
;          the very handler it was drawn from is what refutes it.  In the same
;          MAME routine the vector is CLEARED when the transfer count reaches
;          zero -- `m_dma_vector[channel] = 0;` at tmp95c061.cpp:450, inside the
;          `if ( m_dmac[channel].w.l == 0 )` at :448, immediately before the
;          INTTC0 flag is raised.  That is precisely why this handler exists and
;          why it must write DMA0V back.  Between a transfer completing and this
;          handler re-arming it, DMA0V is 0, `(0 & 0x1f) << 2 = 0` is not a
;          maskable vector, and an INT7 in that window is dispatched to the CPU
;          -- i.e. to 0xFFFF38, i.e. to the hang.
;          The note's own cited analogue points the same way: INT0_LinkByte does
;          the identical trick with `ld (0x7f),0x0a` (DMA3V := 0x0A, 0x0A << 2 =
;          0x28 = INT0) at 0xF8E4CA, 0xF8E4E9 and 0xF8E51F, and slot 0x28 holds
;          a LIVE handler -- INT0_LinkByte itself -- not the hang.  Absorption by
;          the DMA engine is therefore a normal-operation condition, never a
;          proof that a vector is unreachable.
;          What survives: channel 0 is re-armed to be triggered by INT7.
; Unknown:  which pin PB bit 3 is, what the DMA moves, and whether anything can
;          in fact assert INT7 during the re-arm window -- the source of INT7 is
;          not identified.
; ---------------------------------------------------------------------
INTTC0_uDMA0Done:
	push XIZ                                      ; FE6851  3e
	push XIY                                      ; FE6852  3d
	push XIX                                      ; FE6853  3c
	push XHL                                      ; FE6854  3b
	push XDE                                      ; FE6855  3a
	push XBC                                      ; FE6856  39
	push XWA                                      ; FE6857  38
	calr (0xFE594C - 0xFE685B)                    ; FE6858  1e f1 f0   pulse PB bit 3
	calr (0xFE5966 - 0xFE685E)                    ; FE685B  1e 08 f1   DMA0V := 0x0E (trigger = INT7)
	pop XWA                                       ; FE685E  58
	pop XBC                                       ; FE685F  59
	pop XDE                                       ; FE6860  5a
	pop XHL                                       ; FE6861  5b
	pop XIX                                       ; FE6862  5c
	pop XIY                                       ; FE6863  5d
	pop XIZ                                       ; FE6864  5e
	reti                                          ; FE6865  07

; ---------------------------------------------------------------------
; INT5_Dev7B_Receive -- INT5: read packets from the 0x7B0004/0x7B0005 device
;
; Called from: vector slot 0x30 (INT5) by the two-thunk route above.  Slot
;          0xFE301C jumps here too, so something else enters it as a plain call
;          as well; what, is not traced.
; Inputs:  the device's status register 0x7B0004 and data register 0x7B0005.
; Outputs: the packet bytes at 0x605A51 upward, and (0x605A50) = 0 on exit.
;          All seven long registers saved and restored; exits with RETI.
; Evidence: the vector slot names the handler; the body names the rest.  It uses
;          only the five accessors at 0xFE54B6-0xFE54EB (converted above), which
;          are the only code in either image that touches the device, so the
;          port semantics used here -- status bit 7 = "a byte is ready", status
;          bit 6 = "more bytes follow" -- are read directly off these loops:
;          every read of 0x7B0004 is immediately followed by a bit test and a
;          branch, and every read of 0x7B0005 is immediately followed by a store
;          into the buffer.
; Unknown:  ⚠ WHAT THE DEVICE IS.  Also: what the 0x08 written to the data
;          register at 0xFE689F means; what 0xFE5A41 (a status classifier that
;          masks with 0xE0 and compares against 0x80 and 0xC0) and 0xFE5B5E (it
;          re-reads the buffer at 0x605A50 and switches on the top two bits of
;          byte 1) do with the packet.  None of that is named here.
; ---------------------------------------------------------------------
INT5_Dev7B_Receive:
	push XIZ                                      ; FE6866  3e
	push XIY                                      ; FE6867  3d
	push XIX                                      ; FE6868  3c
	push XHL                                      ; FE6869  3b
	push XDE                                      ; FE686A  3a
	push XBC                                      ; FE686B  39
	push XWA                                      ; FE686C  38
	lds iz, 0x00                                  ; FE686D  de a8   IZ = the give-up counter
INT5_Dev7B__wait_first:
	ld WA,IZ                                      ; FE686F  de 88
	inc 1,IZ                                      ; FE6871  de 61
	cp WA,0x0064                                  ; FE6873  d8 cf 64 00   100 tries and no more
	jr gt, INT5_Dev7B__giveup                     ; FE6877  6a 56
	calr (0xFE54B6 - 0xFE687C)                    ; FE6879  1e 3a ec   L := status
	bit 0x07,L                                    ; FE687C  cf 33 07
	jr z, INT5_Dev7B__wait_first                  ; FE687F  66 ee   bit 7 = a byte is ready
INT5_Dev7B__packet:
	calr (0xFE54B6 - 0xFE6884)                    ; FE6881  1e 32 ec
	bit 0x07,L                                    ; FE6884  cf 33 07
	jr z, INT5_Dev7B__packet                      ; FE6887  66 f8
	calr (0xFE54B6 - 0xFE688C)                    ; FE6889  1e 2a ec
	bit 0x06,L                                    ; FE688C  cf 33 06
	jr nz, INT5_Dev7B__read_loop                  ; FE688F  6e 13   bit 6 = more bytes follow
INT5_Dev7B__wait_8x:
	calr (0xFE54B6 - 0xFE6894)                    ; FE6891  1e 22 ec
	and L,0xf0                                    ; FE6894  cf cc f0
	cp L,0x80                                     ; FE6897  cf cf 80
	jr nz, INT5_Dev7B__wait_8x                    ; FE689A  6e f5   spin until status is 0x8n
	pushw 0x08                                    ; FE689C  0b 08 00
	calr (0xFE54E3 - 0xFE68A2)                    ; FE689F  1e 41 ec   Dev7B_WriteData(0x08)
	inc 2,XSP                                     ; FE68A2  ef 62   the caller cleans up the argument
INT5_Dev7B__read_loop:
	lda_24 xiz, (0x605a50)                        ; FE68A4  f2 50 5a 60 36
	inc 1,XIZ                                     ; FE68A9  ee 61   the packet starts at 0x605A51
INT5_Dev7B__byte:
	calr (0xFE5A41 - 0xFE68AE)                    ; FE68AB  1e 93 f1   a status classifier, not converted
	calr (0xFE54BC - 0xFE68B1)                    ; FE68AE  1e 0b ec   L := data
	lda_dpi xsp, 0xf8                             ; FE68B1  f5 f8 47   unidasm: `ld (XIZ+),L` -- store and advance
INT5_Dev7B__wait_ready:
	calr (0xFE54B6 - 0xFE68B7)                    ; FE68B4  1e ff eb
	bit 0x07,L                                    ; FE68B7  cf 33 07
	jr z, INT5_Dev7B__wait_ready                  ; FE68BA  66 f8
	calr (0xFE54B6 - 0xFE68BF)                    ; FE68BC  1e f7 eb
	bit 0x06,L                                    ; FE68BF  cf 33 06
	jr nz, INT5_Dev7B__byte                       ; FE68C2  6e e7   more bytes in this packet
	calr (0xFE5B5E - 0xFE68C7)                    ; FE68C4  1e 97 f2   hand the packet on, not converted
	m_cp_mi8 MB24, 0x605a51, 0x80                 ; FE68C7  c2 51 5a 60 3f 80
	jr nz, INT5_Dev7B__packet                     ; FE68CD  6e b2   0x80 in byte 1 ends the exchange
INT5_Dev7B__giveup:
	stib_da (0x605a50), 0x00                      ; FE68CF  f2 50 5a 60 00 00
	pop XWA                                       ; FE68D5  58
	pop XBC                                       ; FE68D6  59
	pop XDE                                       ; FE68D7  5a
	pop XHL                                       ; FE68D8  5b
	pop XIX                                       ; FE68D9  5c
	pop XIY                                       ; FE68DA  5d
	pop XIZ                                       ; FE68DB  5e
	reti                                          ; FE68DC  07

; ---------------------------------------------------------------------
; Int_Mul32 -- XHL := the low 32 bits of XWA * XBC (the C runtime's long multiply)
;
; Called from: five `call 0xFE68DD` sites -- 0xFE3211, 0xFE321E, 0xFE3263,
;          0xFE3272 and 0xFE44AA (notes/prom_a_xref.py; opcode-anchored, so an
;          upper bound rather than verified instruction boundaries).
; Inputs:  XWA and XBC, two 32-bit values.
; Outputs: XHL = (XWA * XBC) mod 2^32.  XWA, XDE, HL clobbered.
; Evidence: TWO INDEPENDENT ONES.
;          (1) THE ARITHMETIC, from the disassembly alone.  `QWA` is the UPPER
;          half of XWA, not a separate register: MAME's dasm900.cpp:1385 names
;          register byte 0xE2 "QWA", and get_reg16() returns `&r->w.h` for any
;          register byte with bit 1 set (900tbl.hxx:298-303).  So with
;          A = ah:al = XWA and B = bh:bl = XBC the body is
;            XHL := ah*bl ; XDE := bh*al ; XHL += XDE   (the two cross terms)
;            QHL := HL ; HL := 0                        (<< 16, keeping low 16)
;            XWA := al*bl ; XHL += XWA                  (the low term)
;          which is exactly (A*B) mod 2^32.  The fourth partial product ah*bh is
;          not "never formed" for an unknown reason -- it weighs 2^32 and cannot
;          appear in a 32-bit result.  This retires the earlier header's
;          "⚠ WHICH HALF IS WHICH" as answered.
;          (2) THE SIBLING HAS IT.  All 22 bytes occur once in the KN5000
;          sub-CPU's linked image, at KN5000 address 0x3D8CA, where the maximal
;          identical run is exactly these 22 bytes and the next sibling label is
;          at 0x3D8E0 -- so it is a whole routine, not a fragment.  llvm-nm names
;          it `FP_MulAccum64` and it is written out at
;          ../kn5000-roms-disasm/v142/subcpu/subcpu_fp_math.s:635-639.
;          Reproduce with `python3 notes/prom_a_sibling_short_runs.py --selftest`.
;
;          ⚠ RETRACTION (audit round 1, F1).  The previous header stated as a
;          checked fact that "these 22 bytes have NO counterpart in the KN5000
;          sub-CPU ... the sibling not at all".  That was false, and it was false
;          because scripts/analysis/transplant_kn5000_labels.py has MIN_RUN = 48:
;          a 22-byte routine is below its floor, so the tool was SILENT and the
;          header read silence as a searched negative.  notes/prom_a_sibling_short_runs.py
;          exists to make that class of miss visible.  At a 12-byte floor it finds
;          nine complete sibling routines in prom_a; SEVEN of them sit inside runs
;          of 68 or 170 bytes that the 48-byte tool already reported, and TWO were
;          below its floor -- this one (22 bytes) and DSP_Init_Channels_Loop
;          (21 bytes, prom_a 0xF85F4C, converted above).  Two, not one: corrected
;          here after re-reading the scanner's own output.
;
;          ⚠ WHY THE SIBLING'S NAME IS NOT ADOPTED HERE.  subcpu_fp_math.s:635
;          reads it as "64x64 -> 64 ... Inputs XWA:QWA and XBC:QBC (each a 32-bit
;          value plus its high extension register)".  QWA is not an extension
;          register, it is the top half of XWA (citations above), so the operands
;          are 32 bits and the result is 32 bits.  The sibling's own call sites
;          agree with the disassembly rather than with its header: `EnvDepth_Cap`
;          (../kn5000-roms-disasm/v142/subcpu/kn5000_subprogram_v142.s:6379-6398)
;          builds each operand with `lds32 xwa, 0 / ld a, c` -- a zero-extended
;          BYTE in a 32-bit register -- and takes a 32-bit result in XHL.  The
;          name is recorded here so the two trees can be grepped across; the
;          width claim attached to it is not carried over.
; Unknown:  the sign convention.  `mul` is the unsigned form (`muls` is the
;          signed one), so this is an unsigned multiply, but a two's-complement
;          low-32 product is the same either way and nothing here says which the
;          callers mean.
; ---------------------------------------------------------------------
Int_Mul32:
	ld HL,QWA                                     ; FE68DD  d7 e2 8b
	mul xhl, xbc                                  ; FE68E0  d9 43   cross term 1
	ld DE,QBC                                     ; FE68E2  d7 e6 8a
	mul xde, xwa                                  ; FE68E5  d8 42   cross term 2
	add XHL,XDE                                   ; FE68E7  ea 83
	ld QHL,HL                                     ; FE68E9  d7 ee 9b
	lds hl, 0x00                                  ; FE68EC  db a8
	mul xwa, xbc                                  ; FE68EE  d9 40   low term
	add XHL,XWA                                   ; FE68F0  e8 83
	ret                                           ; FE68F2  0e

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
