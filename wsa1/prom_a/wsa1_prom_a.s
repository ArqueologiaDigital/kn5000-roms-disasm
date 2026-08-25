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
; here, because a hand-maintained one in README.md was wrong for a commit.
;
; ⚠ THAT TOOL COUNTS `.fill` AS CONVERTED (round-1 audit, F1), which can inflate
; an image's figure by tens of points.  For prom_a it does not: this file's only
; `.fill` is the 108-byte RET padding at 0xFFFF84, so of the bytes the tool
; calls converted, 108 are padding and the rest is real assembly.  Quote the
; figure for OTHER images only with that split stated.
;
; Converted so far, as real assembly (everything else is still .incbin, so it
; builds byte-exact by construction and asserts nothing):
;
;   0xF826A9-0xF827C7   287  RESET, the whole boot path to its jump into prom_b
;   0xF82CFF-0xF830C5   967  INTWD, the unused-vector trap, INTT1 and INTTR4 with
;                            their dispatch tables, the event-buffer append, NMI
;                            (power-fail) and its checksum helper
;   0xF85600-0xF85605     6  INTT3_KernelTick, the kernel's timer-3 handler
;   0xF85606-0xF856EB   230  Kernel_InitRam -- the kernel's WHOLE RAM MAP written
;                            out in one pass: 4 task control blocks, 3 ready
;                            queues, 8+4+4 more list heads, 8 free nodes on the
;                            free list, 2 software timers, and the 8 ROM bytes
;                            at 0xF85EBA copied to 0x035C
;                            (notes/FINDINGS-prom_a-kernel-lifecycle.md)
;   0xF856EC-0xF857D5   234  the kernel: idle loop, task switch, software timers,
;                            and IRQ_Epilogue, where every handler exits
;   0xF857D6-0xF85876   161  the task LIFECYCLE -- Kernel_StartTask, which builds
;                            a task's initial stack frame from EntryPoint_Records
;                            and queues it, and Kernel_ExitTask, which unlinks
;                            the running task and gives up the CPU.  ★ This is
;                            also where the kernel's TWO PUBLISHED ABIs become
;                            visible: prom_b 0xF42D6C and 0xF42DAC are the same
;                            API with register and stack arguments
;   0xF85877-0xF85903   141  the scheduler's two queue-rotate primitives, which
;                            are what identify 0x0330 as three READY QUEUES
;   0xF85904-0xF8596C   105  Kernel_BlockSelf and Kernel_ReadyTask -- the pair
;                            that shows QUEUE MEMBERSHIP is what the dispatcher
;                            reads, and the +9 state byte is bookkeeping
;   0xF8596D-0xF85B0C   416  ★ the EIGHT COUNTING SEMAPHORES -- wait, signal,
;                            signal-without-rescheduling and a non-blocking
;                            try-wait, plus a no-reschedule Kernel_ReadyTask.
;                            These identify the eight heads at 0x033C and the
;                            eight count bytes at 0x035C that Kernel_InitRam
;                            creates, and the ROM image at 0xF85EBA turns out to
;                            be their INITIAL COUNTS
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
;   0xF8F850-0xF90117  2248  SWI7 services 0x0E 0x1B (erase), 0x0F 0x10 (the TWO
;                            PANEL MODES), 0x11 0x12 0x14 0x15 (the patterned
;                            primitives) and their four mask/dither tables
;   0xF90118-0xF90988  2161  SWI7's two PACKED text services 0x17 and 0x1C -- the
;                            only ones that can start at any pixel column -- their
;                            bit-shift engine and four mask tables, and 0x1E, the
;                            panel SCROLL.  ★ With these, ALL 34 live SWI7
;                            services are converted (notes/swi7_service_table.py)
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
; bytes", "172 of 172", "13 bytes reordered", every font base and every ASCII
; verdict -- is one of the named checks in notes/prom_a_byte_checks.py, which
; reads them back out of the ROM and exits non-zero if any has drifted.  Run it
; WITH the byte gate; neither catches what the other does.
;
; ⚠ THE COUNT IS NOT WRITTEN HERE ANY MORE.  This line said "232 named checks"
; and the tooling note said "133"; the number that actually ran on 2026-08-25
; was 231.  The script now PRINTS its own count as its first output line, so
; the number a reader quotes is the one that ran.
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
;   notes/FINDINGS-prom_a-kernel-lifecycle.md  the kernel's RAM map, the task
;                                             lifecycle, and the two ABIs
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
; Evidence: the body is one instruction and it settles the "Reboot" half --
;          `jrl T,RESET` at 0xF82CFF (78 a7 f9), whose displacement resolves
;          to 0xF826A9, which is RESET. The slot binding is emitted as `.long
;          INTWD_Reboot` in the vector table at the end of this file, so the
;          BYTE GATE proves 0xFFFF24 holds this address.
;          ⚠ the "INTWD" half is convention, not a citation -- Notes.
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
; Evidence: the slot is emitted as `.long INTT1_Tick`, so the byte gate proves
;          0xFFFF44 holds 0xF82D0B. "Periodic time base" is not read off the
;          slot name: the first two memory operations after the pushes are
;          `(0x80) += 1` (0xF82D11) and `(0x605A00) += 1` (0xF82D14), both
;          unconditional and before any branch, so something is counted on
;          every single entry. The second is pinned by
;          notes/prom_a_byte_checks.py ("INTT1_Tick increments (0x605A00) at
;          0xF82D14").
;          ⚠ "INTT1" is the TLCS-900/H slot convention, as for INTWD above.
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
; Evidence: all three entries are emitted as symbols, so the byte gate checks
;          their addresses. THREE is fixed by the reader, not by inspection:
;          0xF82DE5-0xF82DF6 is `ld A,(0x86) / inc 1,A / cps A,0x02 / jr ULE /
;          sub A,A` and then `sll a,0x02`, so the index can only be 0, 1 or 2
;          and a fourth slot can never be addressed.
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
; Evidence: SIXTEEN is fixed by the reader: 0xF82E23 is `ld A,(0x87) / and
;          A,0x0F / sll a,0x02`, so the byte offset formed is 0..60 and a
;          seventeenth slot cannot be addressed. All 16 entries are emitted as
;          symbols, so the byte gate checks every target. "Seven distinct
;          targets" is the count of distinct symbols in the list below, with
;          multiplicities 4 + 4 + 4 + 1 + 1 + 1 + 1 = 16.
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
; Evidence: the slot is emitted as `.long INTTR4_SequencerTick`, so the byte
;          gate proves 0xFFFF50 holds 0xF82EA2. "Musical time base" is
;          arithmetic in the body: FOUR separate wrap tests against 0x60 = 96
;          (0xF82EB1, 0xF82ECD, 0xF82EE2, 0xF82F0D) and the MIDI-clock gate
;          `ld A,(0x8D) / and A,0x03` at 0xF82FDF, with 96 / 4 = 24 = MIDI
;          1.0's Timing Clocks per quarter note. The third, independent
;          agreement (the tempo setter) is spelled out above.
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
; Evidence: "Marker" is LITERAL -- the value stored is the immediate 0x81 in
;          both arms, `ld (XIY+HL),0x81` at 0xF83044 and `ld
;          (XHL+0x00AE),0x81` at 0xF83062; nothing computes it. "Ring" is
;          `minc1_16 hl,0x01ff` at 0xF8304A, a modular increment by 0x200,
;          together with the `ld WA,(XIY-2) / and WA,WA / jr z` guard at
;          0xF8303A-0xF8303F that DROPS when the space count is zero instead
;          of wrapping over live data.
;          ⚠ what the 0x81 means is not established -- Notes.
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
; Evidence: the slot is emitted as `.long NMI_PowerFail_SaveAndHalt`, so the
;          byte gate proves 0xFFFF20 -- and unlike INTWD the slot NAME is a
;          citation too: 0x20 is NMI in MAME's own table (tmp95c061.cpp:505).
;          "SaveAndHalt" is the body: two 512-byte blocks check-summed and
;          stored (0xF83086-0xF8309F), DMEMCR (SFR 0x5B) rewritten to 0x2D at
;          0xF830AC, and `halt` at 0xF830B3 inside a `jr` back to itself -- a
;          stop that re-stops if anything wakes it.
;          ⚠ "PowerFail" is the READING of that shape, not a citation. See
;          Notes.
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
; Evidence: "512" is literal: `ldw bc,0x0100` at 0xF830B6 is 256 iterations and
;          `add_spiw wa,0xf5` is `add WA,(XIY+)`, a WORD post-increment, so
;          256 x 2 = 512 bytes. "Ones-complement" is `cpl WA` at 0xF830C1,
;          immediately before the `ld (XIX),WA` store. Both callers hand it a
;          512-byte block -- 0x007620 and 0x617800, set up at 0xF83086 and
;          0xF83093.
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

; ==============================================================================
; 0xF85606-0xF856EB -- Kernel_InitRam: the kernel's whole RAM map, written out
; ==============================================================================
;
; ★ THIS ROUTINE IS THE KERNEL'S DATA-STRUCTURE DECLARATION.  Every list head,
;   every node array and every array stride the kernel uses is created here, in
;   one pass, with literal addresses -- so the layout below is read off
;   immediates rather than inferred from the routines that later use it.  Each
;   row names the instruction that writes it and, where one exists, the already-
;   converted routine that independently confirms the same address:
;
;     0x0300 + (A-1)*12   4 task control blocks, +9 (state) := 0    0xF8562A
;                         -- Kernel_StartTask computes 0x02F4 + A*12
;     0x0330 + (n-1)*4    3 READY QUEUE heads, self-linked          0xF85615
;                         -- Kernel_Dispatch scans three heads from 0x0330
;     0x033C + (i-1)*4    8 more list heads, self-linked            0xF85662
;                         -- ⚠ what they queue is NOT established here
;     0x035C              8 bytes copied from ROM 0xF85EBA          0xF85653
;     0x0364 + (A-1)*4    4 heads, self-linked                      0xF856B5
;                         -- MsgQueue_ReceiveBlocking's WAIT queue, 0x0360+A*4
;     0x0374 + (A-1)*4    4 heads, self-linked                      0xF856C7
;                         -- MsgQueue_ReceiveBlocking's MESSAGE queue, 0x0370+A*4
;     0x0384 + i*8        8 nodes of 8 bytes, +4 := 0xFFFFFFFF      0xF85674
;     0x03C4              1 head, self-linked, then all 8 of those
;                         nodes appended to it                      0xF8568A
;                         -- MsgQueue_ReceiveBlocking's FREE LIST at 0x03C4
;     0x03C8 + (n-1)*8    2 software timers, +4 := 0xFFFFFFFF       0xF8563D
;                         -- Kernel_ServiceSoftTimers walks two 8-byte slots
;                            at 0x03C8 and treats +4 = 0xFFFFFFFF as "empty"
;
; ★ AND IT SETTLES THE 1-BASED CONVENTION.  The four TCBs are written from
;   0x0300 with stride 12 and B = 4, so they occupy 0x0300-0x032F and the first
;   ready-queue head at 0x0330 begins immediately after them.  There is no
;   8-byte hole: Kernel_StartTask's `0x02F4 + A*12` and the queue primitives'
;   `0x032C + n*4` are the same layout written with a one-element bias, and
;   MsgQueue_ReceiveBlocking's `0x0360 + A*4` / `0x0370 + A*4` are two more
;   instances of it.  A = 1..4 and level n = 1..3 throughout.
;
; ★ IT ALSO IDENTIFIES 0xF85EBA.  Those eight bytes sit immediately after
;   EntryPoint_Records and this file has carried them as "UNIDENTIFIED.  Not a
;   fifth record".  They are a ROM IMAGE OF RAM 0x035C-0x0363: `ldir` copies
;   exactly 8 bytes from 0xF85EBA to 0x035C at 0xF85653-0xF85661.  What the
;   eight bytes MEAN is still not established -- only where they go.
;
; Everything quantified above is re-derived from the ROM by
; notes/prom_a_byte_checks.py.
;
; ---------------------------------------------------------------------
; Kernel_InitRam -- build every kernel list and block, then fall into Kernel_Start
;
; Called from: prom_b thunk 0xF42D60 (`jp 0xF85606`), and nothing else -- that
;          is the only site in either ROM naming this address
;          (notes/prom_a_byte_checks.py).
; Inputs:  none
; Outputs: the RAM map in the banner above; XSP = the boot stack 0x0060EB80;
;          (0xBF) = 0, no task running; control register 0x3C = 1, so the
;          kernel starts inside one level of critical section.  It does not
;          return -- its last instruction is a `call` and it then falls into
;          Kernel_Start.
; Evidence: every address in the banner is an IMMEDIATE in this routine and
;          every count is a `ldb b,imm` loop bound; nothing is inferred from a
;          consumer.  The self-linking idiom is `ld IX,HL` followed by two
;          `ld (XHL+),IX` -- head->next = head, head->prev = head, four bytes,
;          which is the empty-list state Kernel_Dispatch tests with `cp HL,IX`
;          and Kernel_YieldRotate with head->next == head->prev.
;          The eight-node append at 0xF8569A-0xF856B4 is the tree's
;          insert-at-tail idiom verbatim, the same four stores as
;          0xF858AF-0xF858BC and 0xF85839-0xF85846.
; Unknown:  what the eight heads at 0x033C queue, and what the eight bytes
;          copied to 0x035C are for.  ⚠ `ld DE,0x0004` at 0xF8561A is DEAD
;          WITHIN THIS REGION -- DE is reloaded at 0xF85658 before anything
;          reads it.  That is a statement about these 230 bytes only.
; ---------------------------------------------------------------------
Kernel_InitRam:
	ld XSP,0x0060eb80                             ; F85606  47 80 eb 60 00   the boot stack
	xor WA,WA                                     ; F8560B  d8 d0
	st_dd8w wa, 0xbf                              ; F8560D  f0 bf 50   (0xBF) = 0: no task is running
	inc 1,WA                                      ; F85610  d8 61
	m_ldc_cr_reg RW+r0, 0x3c                      ; F85612  d8 2e 3c   critical-section depth := 1
	ldw hl, 0x0330                                ; F85615  33 30 03   the THREE READY QUEUE heads
	extz XHL                                      ; F85618  eb 12
	ldw de, 0x04                                  ; F8561A  32 04 00   dead here -- DE is reloaded at 0xF85658
	ldb b, 0x03                                   ; F8561D  22 03
Kernel_InitRam__ready_queues:
	ld IX,HL                                      ; F8561F  db 8c
	stw_dpi ix, 0xed                              ; F85621  f5 ed 54   head->next = head
	stw_dpi ix, 0xed                              ; F85624  f5 ed 54   head->prev = head
	djnz8 b, Kernel_InitRam__ready_queues         ; F85627  ca 1c f5
	ldw ix, 0x0300                                ; F8562A  34 00 03   the FOUR task control blocks
	extz XIX                                      ; F8562D  ec 12
	ldb b, 0x04                                   ; F8562F  22 04
	ldb a, 0x00                                   ; F85631  21 00
Kernel_InitRam__tcbs:
	ld (XIX+0x09),A                               ; F85633  bc 09 41   +9 = state 0, which is what Kernel_StartTask requires
	add IX,0x000c                                 ; F85636  dc c8 0c 00   stride 12: 0x0300 0x030C 0x0318 0x0324
	djnz8 b, Kernel_InitRam__tcbs                 ; F8563A  ca 1c f6
	ldw ix, 0x03c8                                ; F8563D  34 c8 03   the TWO software timers
	extz XIX                                      ; F85640  ec 12
	ldb b, 0x02                                   ; F85642  22 02
	ld XWA,0xffffffff                             ; F85644  40 ff ff ff ff
Kernel_InitRam__soft_timers:
	ld (XIX+0x04),XWA                             ; F85649  bc 04 60   +4 = no callback; Kernel_ServiceSoftTimers skips on this
	add IX,0x0008                                 ; F8564C  dc c8 08 00
	djnz8 b, Kernel_InitRam__soft_timers          ; F85650  ca 1c f6
	ld XHL,0x00f85eba                             ; F85653  43 ba 5e f8 00   the 8 ROM bytes after EntryPoint_Records
	ldw de, 0x035c                                ; F85658  32 5c 03
	extz XDE                                      ; F8565B  ea 12
	ldw bc, 0x08                                  ; F8565D  31 08 00
	ldir83                                        ; F85660  83 11   (XDE+) <- (XHL+), 8 bytes: RAM 0x035C-0x0363
	ldw hl, 0x033c                                ; F85662  33 3c 03   EIGHT more list heads
	extz XHL                                      ; F85665  eb 12
	ldb b, 0x08                                   ; F85667  22 08
Kernel_InitRam__heads_033C:
	ld IX,HL                                      ; F85669  db 8c
	stw_dpi ix, 0xed                              ; F8566B  f5 ed 54
	stw_dpi ix, 0xed                              ; F8566E  f5 ed 54
	djnz8 b, Kernel_InitRam__heads_033C           ; F85671  ca 1c f5
	ldw hl, 0x0384                                ; F85674  33 84 03   EIGHT 8-byte nodes
	extz XHL                                      ; F85677  eb 12
	ldb b, 0x08                                   ; F85679  22 08
	ld XWA,0xffffffff                             ; F8567B  40 ff ff ff ff
Kernel_InitRam__free_nodes:
	ld (XHL+0x04),XWA                             ; F85680  bb 04 60   +4 = the payload, cleared to all-ones
	add HL,0x0008                                 ; F85683  db c8 08 00
	djnz8 b, Kernel_InitRam__free_nodes           ; F85687  ca 1c f6
	ldw iy, 0x03c4                                ; F8568A  35 c4 03   the FREE LIST head
	extz XIY                                      ; F8568D  ed 12
	m_st_mr16 MDD+r5, 0x00, r5                    ; F8568F  bd 00 55   ld (XIY+0x00),IY -- head->next = head
	ld (XIY+0x02),IY                              ; F85692  bd 02 55   head->prev = head
	ldw ix, 0x0384                                ; F85695  34 84 03
	ldb b, 0x08                                   ; F85698  22 08
Kernel_InitRam__free_append:
	extz XIX                                      ; F8569A  ec 12
	extz XIY                                      ; F8569C  ed 12
	extz XWA                                      ; F8569E  e8 12
	m_st_mr16 MDD+r4, 0x00, r5                    ; F856A0  bc 00 55   ld (XIX+0x00),IY -- n->next = head
	ld WA,(XIY+0x02)                              ; F856A3  9d 02 20
	ld (XIX+0x02),WA                              ; F856A6  bc 02 50   n->prev = head->prev
	ld (XWA),IX                                   ; F856A9  b0 54   head->prev->next = n
	ld (XIY+0x02),IX                              ; F856AB  bd 02 54   head->prev = n
	add IX,0x0008                                 ; F856AE  dc c8 08 00
	djnz8 b, Kernel_InitRam__free_append          ; F856B2  ca 1c e5
	ldw hl, 0x0364                                ; F856B5  33 64 03   FOUR heads -- the wait queues
	extz XHL                                      ; F856B8  eb 12
	ldb b, 0x04                                   ; F856BA  22 04
Kernel_InitRam__wait_queues:
	ld IX,HL                                      ; F856BC  db 8c
	stw_dpi ix, 0xed                              ; F856BE  f5 ed 54
	stw_dpi ix, 0xed                              ; F856C1  f5 ed 54
	djnz8 b, Kernel_InitRam__wait_queues          ; F856C4  ca 1c f5
	ldw hl, 0x0374                                ; F856C7  33 74 03   FOUR heads -- the message queues
	extz XHL                                      ; F856CA  eb 12
	ldb b, 0x04                                   ; F856CC  22 04
Kernel_InitRam__msg_queues:
	ld IX,HL                                      ; F856CE  db 8c
	stw_dpi ix, 0xed                              ; F856D0  f5 ed 54
	stw_dpi ix, 0xed                              ; F856D3  f5 ed 54
	djnz8 b, Kernel_InitRam__msg_queues           ; F856D6  ca 1c f5
	ld XIX,SoftTimer_Request_Boot                 ; F856D9  44 e0 56 f8 00   the argument for the call below
	jr Kernel_InitRam__install                    ; F856DE  68 08   step over the argument block

; ---------------------------------------------------------------------
; SoftTimer_Request_Boot -- 8 bytes of argument, INLINE in the code stream
;
; Read by:  the routine at 0xF85D78, through XIX, which the instruction above
;          loads with this address.  Nothing else in either ROM names it
;          (notes/prom_a_byte_checks.py).
; Layout:  the fields are read off the CALLEE, so only two of the three are
;          established:
;            +0  LE16  0x0001  0xF85D82 reads it as a BYTE (`ld A,(XIX+0x00)`)
;                              and forms 0x03C0 + A*8 (0xF85D85-0xF85D88).
;                              0x03C0 + 1*8 = 0x03C8, software timer slot 1 --
;                              the array this very routine initialised, and the
;                              same one-element bias as everywhere else here.
;            +2  LE16  0x0001  ⚠ NOT established.  Do not assume it is the
;                              reload value: the software-timer SLOT layout is
;                              (+0 countdown, +2 reload, +4 callback), and this
;                              block is a REQUEST with a different +0, so the
;                              two layouts must not be conflated.
;            +4  LE32  0x00F85EC2  a code address in this file -- sub_F85EC2,
;                              which notes/prom_a_byte_checks.py records as
;                              calling Kernel_YieldRotate with A = 3.
; Evidence: it is DATA and not code, and that is settled by the branch, not by
;          taste: the `jr` at 0xF856DE targets 0xF856E8, which steps over
;          exactly these eight bytes, and 0xF856E8 is where the next
;          instruction starts.  Reading 0xF856E4 as code is what produced this
;          file's old (and wrong) "0xF856E9 `jrl 0xF84F49`".
; ---------------------------------------------------------------------
SoftTimer_Request_Boot:
	.short 0x0001				; F856E0  slot index, read as a byte by 0xF85D78
	.short 0x0001				; F856E2  ⚠ role not established
	.long 0x00F85EC2			; F856E4  sub_F85EC2

Kernel_InitRam__install:
	call 0xf85d78                                 ; F856E8  1d 78 5d f8   install that request, then FALL INTO Kernel_Start

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
; Kernel_Start -- programme timer 3, start TASKS 1 and 3, enter the kernel
;
; Called from: FALLEN INTO from Kernel_InitRam, whose last instruction is
;          `call 0xF85D78` at 0xF856E8 -- four bytes ending exactly at this
;          label.  Nothing branches or calls here.
; Inputs:  none
; Outputs: timer 3 stopped and re-programmed (T23MOD = 0x0E, TREG3 = 0x36,
;          INTET32 = 0x20), TASKS 1 and 3 started through Kernel_StartTask, the
;          depth counter cleared, and control passed to Kernel_Dispatch.
;          Never returns.
; Evidence: the three `ldio`s name their registers by SFR ADDRESS out of
;          include/tmp95c061_sfr.inc -- 0x28 T23MOD, 0x27 TREG3, 0x74 INTET32
;          -- and 0xF856EC clears TRUN bit 3 first, which is "stop timer 3
;          before reprogramming it".  The two `ld A,imm / call 0xF857D9` pairs
;          with A = 1 and A = 3 (0xF856F8, 0xF856FE) reach Kernel_StartTask,
;          converted below, and A there is a TASK number: A = 1 is
;          EntryPoint_Records[0] (entry 0xF4005C, level 3) and A = 3 is
;          EntryPoint_Records[2] (entry 0xF85EC8 = DSP_RefreshTask, level 1).
;          "Enter the kernel" is the tail: 0xF8570E is `jrl Kernel_Dispatch`, a
;          JUMP, so this routine never resumes.
;
; ★ CORRECTED 2026-08-25, twice over.
;   (1) This header said "arm two software timers" and "0xF857D9 takes a slot
;       number in A; it is the 'register a software timer' entry".  0xF857D9 is
;       Kernel_StartTask -- it indexes EntryPoint_Records and the task control
;       blocks and appends to a READY QUEUE.  The software-timer registration is
;       a different routine, 0xF85D78, and this routine does not call it.
;   (2) "falls in from 0xF856E9's `jrl 0xF84F49`" cited an instruction that does
;       not exist: 0xF856E8 is `call 0xF85D78` (opcode 0x1D at 0xF856E8, its
;       operand at 0xF856E9), which is why a disassembly starting mid-region
;       decoded 0xF856E9 as a `jrl`.  The `jr` at 0xF856DE targets 0xF856E8 and
;       fixes the boundary.  Nothing in either ROM names 0xF84F49 at all --
;       notes/prom_a_byte_checks.py re-derives that.
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
; Evidence: the structural reading below is what names it, and its two
;          keystones are re-derived from the ROM by
;          notes/prom_a_byte_checks.py -- "Kernel_Dispatch: scans 3 heads from
;          0x0330 with stride 4" and "Kernel_Dispatch: reads the saved XSP
;          from node+4". The same script pins that the queue primitives
;          address exactly those three heads ("0x032C + n*4 for n=1,2,3 is
;          exactly Kernel_Dispatch's three heads") and that the boot stack
;          this routine switches to lies inside the entry records' stack run.
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
; Evidence: the slot array is literal -- `ldw ix,0x03c8` at 0xF85776, `ldb
;          b,0x02` at 0xF8577B and `add IX,0x0008` at 0xF85794: TWO slots,
;          EIGHT bytes apart. The field roles are read off the loop: +4 is
;          tested against 0xFFFFFFFF for "empty" (0xF8577D), +0 is loaded,
;          decremented and stored back (0xF85788-0xF8578D), and on reaching
;          zero +2 is copied into +0 (0xF857A6) before the callback is
;          entered. The `cr 0x3C` bracket at either end is the same register
;          Kernel_Dispatch tests and IRQ_Epilogue compares against 1.
;          ⚠ "software timers" is that SHAPE (countdown / reload / callback),
;          not a name taken from the firmware.
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
;          INTT1_Tick (0xF82E9E) and INTTR4_SequencerTick (0xF83030) both end
;          that way, and those are the ONLY two sites in either ROM that spell
;          `jp 0xF42D68`.  The INTT3 handler at 0xF85600 also ends here but by
;          a DIFFERENT route -- `jrl T,0xF857B7` at 0xF85603, straight to this
;          label without the thunk.  ⚠ CORRECTED 2026-08-25: this line said all
;          three "end that way", which reads as three thunk sites; there are
;          two.  All of it is re-derived by notes/prom_a_byte_checks.py.
; Inputs:  cr 0x3C, the critical-section depth
; Outputs: either a plain RETI (nested case) or a full register push followed by
;          a jump into Kernel_Dispatch, which will not come back.
; Evidence: prom_b 0xF42D68 really is `jp 0xF857B7` -- its four bytes are 1B B7
;          57 F8 -- so the handlers that end `jp 0xF42D68` do land on this
;          label, and notes/prom_a_byte_checks.py re-derives that plus the
;          fact that exactly two sites in either ROM spell that jump.
;          "Epilogue" is the body: control register 0x3C is read and compared
;          against 1 (0xF857B8-0xF857BB) and the two arms are a bare RETI
;          (0xF857C0) or seven pushes followed by `jrl Kernel_Dispatch`
;          (0xF857CC-0xF857D3).
;          ⚠ it is not the ONLY exit in this file -- the MIDI handlers execute
;          RETI themselves; it is the exit of the handlers listed above.
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

; ==============================================================================
; 0xF857D6-0xF85876 -- the kernel's task LIFECYCLE: start one, and exit one
; ==============================================================================
;
; ★ THE KERNEL IS PUBLISHED TWICE, WITH TWO CALLING CONVENTIONS.  prom_b holds
;   a block of 34 `jp` thunks at 0xF42D60-0xF42DE7 -- bounded by 0x0E padding at
;   both ends, so the block's extent is a fact and not a choice.  Three slots at
;   the front are not part of either argument run (0xF85606 Kernel_InitRam,
;   0xF85600 INTT3_KernelTick, 0xF857B7 IRQ_Epilogue) and two at the back
;   publish the DSP register writers (0xF85F59, 0xF85F7C).  Between them are two
;   runs of the SAME API:
;
;     0xF42D6C-0xF42DA8   16 slots  ->  0xF857D9 0xF8584A 0xF85877 0xF858C0
;                                       0xF85904 0xF8592D 0xF8596D 0xF859AE
;                                       0xF85A22 0xF85A96 0xF85B1F 0xF85BD4
;                                       0xF85C8C 0xF85DA8 0xF85E02 0xF85E5E
;     0xF42DAC-0xF42DD4   11 slots  ->  0xF857D6 0xF8584A 0xF85874 0xF85904
;                                       0xF8592A 0xF859AB 0xF85A93 0xF85B0D
;                                       0xF85C89 0xF85DA2 0xF85E5B
;
;   Pair each slot of the second run with the nearest target of the first at or
;   above it and the whole run resolves, with nothing left over:
;
;     2 of the 11   the SAME address in both runs (0xF8584A, 0xF85904)
;                   -- what a routine that takes NO argument looks like;
;     9 of the 11   begin with `ld A,(XSP+0x04)`, the three bytes 8F 04 21 --
;                   7 of those are exactly that one instruction and fall
;                   straight through into the register entry three bytes on;
;                   0xF85DA2 adds `ld W,(XSP+0x06)` for a SECOND argument
;                   (6 bytes to 0xF85DA8), and 0xF85B0D fetches its second
;                   argument as `ld XIZ,(XSP+0x24)` only AFTER the register
;                   pushes -- 0x24 = 0x06 + 2 + 7*4, the same stack slot seen
;                   through 30 bytes of pushes -- then `jr` into the body.
;
;   So the second run is the STACK-ARGUMENT face of the same kernel: a
;   C-callable entry that lifts its arguments off the frame and joins the
;   register-argument entry.  ALL NINE differing slots start with the same
;   three bytes; there is no residue and no slot that does not fit.
;   ⚠ TWO MORE STACK FACES SIT OUTSIDE THAT RUN, at 0xF42DD8 -> 0xF85AEF
;   (Kernel_SemaTryWait) and 0xF42DDC -> 0xF85D1C.  Both open with the same
;   8F 04 21, and neither has a register-argument twin in the first run -- so
;   "two runs" describes the alignment, not the whole block, and those two are
;   published only with a stack argument.
;   The whole table, the nine 8F 04 21 prologues, the two no-argument
;   coincidences and both second-argument shapes are re-derived from the ROM by
;   notes/prom_a_byte_checks.py.
;
; ★ AND THE KERNEL IS 1-BASED THROUGHOUT.  The task selector A indexes three
;   arrays, and all three are addressed with a one-element negative bias:
;
;     EntryPoint_Records   0xF85E7E + A*12   = 0xF85E8A + (A-1)*12   (this file)
;     task control blocks  0x02F4   + A*12   = 0x0300   + (A-1)*12
;     ready-queue heads    0x032C   + n*4    = 0x0330   + (n-1)*4
;
;   The first is computed at 0xF857E9 below, the second at 0xF857F3 below, the
;   third at 0xF8582D below and in both queue primitives at 0xF85877/0xF858C0.
;   So A = 1..4 and level n = 1..3, and there is no 8-byte hole between the TCBs
;   and the queue heads: the four TCBs occupy 0x0300-0x032F and 0x0330 is the
;   first head.  The kernel's own boot code agrees -- 0xF8562A is
;   `ld IX,0x0300 / ld B,0x04 / ld (XIX+0x09),0 / add IX,0x000C`, four blocks of
;   twelve starting at 0x0300.
;   ⚠ This refines, and does not contradict, the check "the 4x12+8 arithmetic
;   lines up in RAM and in ROM": 0x02F4 + 4*12 + 8 = 0x032C is true, but the
;   +8 is not a gap in the layout, it is 12 - 4 seen through the bias.
;
; ---------------------------------------------------------------------
; Kernel_StartTask_StackArg -- the stack-argument face of Kernel_StartTask
;
; Called from: prom_b thunk 0xF42DAC (`jp 0xF857D6`).  No prom_a site reaches
;          it: notes/prom_a_byte_checks.py resolves every PC-relative branch in
;          prom_a and every 3-byte LE address in prom_a + prom_b and finds this
;          one reference and no other.
; Inputs:  (XSP+0x04) = the task number, 1..4
; Outputs: as Kernel_StartTask, which it falls into
; Evidence: it is one instruction, `ld A,(XSP+0x04)`, immediately above
;          Kernel_StartTask's first instruction -- the same three bytes
;          (8F 04 21) that open every one of the nine second-run entries that
;          differ from their first-run twin.  See the region banner.
; ---------------------------------------------------------------------
Kernel_StartTask_StackArg:
	ld A,(XSP+0x04)                               ; F857D6  8f 04 21   the task number, off the stack

; ---------------------------------------------------------------------
; Kernel_StartTask -- make statically-declared task A runnable, then dispatch
;
; Called from: Kernel_Start, twice, with A = 1 and A = 3 (0xF856FA, 0xF85700);
;          prom_b thunk 0xF42D6C; and by falling in from the entry above.
; Inputs:  A = the task number, 1..4.  EntryPoint_Records[A-1] supplies the
;          entry address (+0), the top of that task's stack (+4), the initial
;          SR (+8, always 0x8800) and the priority level (+10, 1..3).
; Outputs: NEVER RETURNS on success -- it jumps into Kernel_Dispatch.  On the
;          way it writes the task's initial stack frame, fills in the task
;          control block at 0x0300 + (A-1)*12 and appends that block to the tail
;          of ready queue 0x0330 + (level-1)*4.  If the task is ALREADY live it
;          returns to its caller instead, through Kernel_ResumeTask's pops.
; Evidence: ★ the initial STACK FRAME is the identification, and it is exact
;          arithmetic against a routine already converted in this file.  The
;          frame is built at record.stack - 0x22 (`sub XIY,0x00000022`,
;          0xF85806); SR goes to frame+0x1C (0xF8580F) and the entry address to
;          frame+0x1E (0xF85815).  Kernel_ResumeTask (0xF85763) resumes a task
;          with SEVEN 32-bit pops, then `pop SR`, then `ret`: 7 x 4 = 0x1C, the
;          SR sits at 0x1C and is 2 bytes, and the return address at 0x1E is 4
;          bytes -- 0x22 in total.  The frame this routine writes is precisely
;          the frame that epilogue consumes, with the seven register slots left
;          uninitialised because a task has no previous register state.
;          The record fields are the ones EntryPoint_Records' own header gives,
;          and +8 = 0x8800 in all four records is checked by
;          notes/prom_a_byte_checks.py.
;          The queue insert at 0xF85839-0xF85846 is the tree's established
;          insert-at-tail idiom verbatim -- `n->next = head; n->prev =
;          head->prev; head->prev->next = n; head->prev = n` -- the same four
;          stores as 0xF858AF-0xF858BC (see the block header at 0xF85877).
;          The state byte written at +9 is 4; MsgQueue_ReceiveBlocking writes 3
;          there for "blocked", and the kernel's boot code writes 0.
; Unknown:  what state values other than 0, 3 and 4 mean, and whether "4" is
;          READY or RUNNABLE in the firmware's own vocabulary.  Nothing here
;          names them; the numbers are what is established.
; ---------------------------------------------------------------------
Kernel_StartTask:
	push SR                                       ; F857D9  02
	ei 0x06                                       ; F857DA  06 06
	push XHL                                      ; F857DC  3b
	push XWA                                      ; F857DD  38
	push XBC                                      ; F857DE  39
	push XDE                                      ; F857DF  3a
	push XIX                                      ; F857E0  3c
	push XIY                                      ; F857E1  3d
	push XIZ                                      ; F857E2  3e   seven pushes: the same set Kernel_ResumeTask pops
	ldb l, 0x0c                                   ; F857E3  27 0c
	mul8rr l, a                                   ; F857E5  c9 47   HL = 12 * A
	extz XHL                                      ; F857E7  eb 12
	add XHL,0xfff85e7e                            ; F857E9  eb c8 7e 5e f8 ff   XHL = EntryPoint_Records + (A-1)*12; only the low 24 bits reach the bus
	ldb c, 0x0c                                   ; F857EF  23 0c
	mul8rr c, a                                   ; F857F1  c9 43   BC = 12 * A
	add BC,0x02f4                                 ; F857F3  d9 c8 f4 02   XBC = 0x0300 + (A-1)*12, the task control block
	extz XBC                                      ; F857F7  e9 12
	ld XIX,XBC                                    ; F857F9  e9 8c
	ld A,(XIX+0x09)                               ; F857FB  8c 09 21   +9 = the state byte
	cps a, 0x00                                   ; F857FE  c9 d8
	jrl nz, Kernel_ResumeTask                     ; F85800  7e 60 ff   already live: undo the pushes and return
	ld XIY,(XHL+0x04)                             ; F85803  ab 04 25   record+4 = the top of this task's stack
	sub XIY,0x00000022                            ; F85806  ed ca 22 00 00 00   room for 7 registers (0x1C) + SR (2) + PC (4)
	ld WA,(XHL+0x08)                              ; F8580C  9b 08 20   record+8 = the initial SR, 0x8800 in every record
	ld (XIY+0x1c),WA                              ; F8580F  bd 1c 50   ...lands where `pop SR` will read it
	m_ld_rm MLD+r3, 0x00, r0                      ; F85812  ab 00 20   ld XWA,(XHL+0x00) -- record+0 = the entry address
	ld (XIY+0x1e),XWA                             ; F85815  bd 1e 60   ...lands where the final `ret` will read it
	ld (XIX+0x04),XIY                             ; F85818  bc 04 65   TCB+4 = the saved XSP, which is what Kernel_Dispatch loads
	ld A,(XHL+0x0a)                               ; F8581B  8b 0a 21   record+10 = the priority level, 1..3
	ld (XIX+0x08),A                               ; F8581E  bc 08 41   TCB+8 = that level
	ld (XIX+0x09),0x04                            ; F85821  bc 09 00 04   TCB+9 = state 4
	ld A,(XHL+0x0a)                               ; F85825  8b 0a 21
	sll a, 0x02                                   ; F85828  c9 ee 02
	extz WA                                       ; F8582B  d8 12
	add WA,0x032c                                 ; F8582D  d8 c8 2c 03   the ready-queue head, 0x0330 + (level-1)*4
	ld IY,WA                                      ; F85831  d8 8d
	extz XIX                                      ; F85833  ec 12
	extz XIY                                      ; F85835  ed 12
	extz XWA                                      ; F85837  e8 12
	m_st_mr16 MDD+r4, 0x00, r5                    ; F85839  bc 00 55   ld (XIX+0x00),IY -- n->next = head
	ld WA,(XIY+0x02)                              ; F8583C  9d 02 20   head->prev
	ld (XIX+0x02),WA                              ; F8583F  bc 02 50   n->prev = head->prev
	ld (XWA),IX                                   ; F85842  b0 54   head->prev->next = n
	ld (XIY+0x02),IX                              ; F85844  bd 02 54   head->prev = n
	jrl Kernel_Dispatch                           ; F85847  78 cb fe   and straight into the scheduler; this never returns

; ---------------------------------------------------------------------
; Kernel_ExitTask -- the running task removes itself and gives up the CPU
;
; Called from: prom_b thunks 0xF42D70 AND 0xF42DB0 -- the same address in both
;          runs, which is what a no-argument entry looks like.  No prom_a site
;          reaches it (same search as above).
; Inputs:  (0xBF) = the running task's control block, as Kernel_Dispatch left it
; Outputs: never returns.  The task's state byte goes to 0, (0xBF) is cleared,
;          the control block is unlinked from whatever queue it was on, and
;          control passes to Kernel_Dispatch on the BOOT stack.
; Evidence: three facts, each an instruction: it switches to 0x0060EB80
;          (0xF8584C), which is the same boot stack RESET's continuation and
;          Kernel_Dispatch use and therefore NOT any task's stack -- so the
;          stack it was running on is abandoned; it writes 0 to TCB+9
;          (0xF85856), the value the kernel's boot code writes into all four
;          blocks and the value Kernel_StartTask above refuses to start over;
;          and 0xF85865-0xF85870 is the tree's established UNLINK idiom
;          verbatim -- `prev->next = next; next->prev = prev`, the same two
;          stores as 0xF8589D-0xF858A8.  Nothing is saved on the way out, which
;          is what distinguishes an exit from a yield.
; Unknown:  who calls it.  Both references are prom_b thunks; the callers are in
;          prom_b and are another lane's territory.
; ---------------------------------------------------------------------
Kernel_ExitTask:
	ei 0x06                                       ; F8584A  06 06
	ld XSP,0x0060eb80                             ; F8584C  47 80 eb 60 00   the BOOT stack -- the task's own stack is abandoned
	m_ld_rm MW8, 0xbf, r4                         ; F85851  d0 bf 24   ld IX,(0xBF) -- the running task's control block
	extz XIX                                      ; F85854  ec 12
	ld (XIX+0x09),0x00                            ; F85856  bc 09 00 00   state 0 = not live
	xor WA,WA                                     ; F8585A  d8 d0
	st_dd8w wa, 0xbf                              ; F8585C  f0 bf 50   (0xBF) = 0: no task is running
	extz XIX                                      ; F8585F  ec 12
	extz XWA                                      ; F85861  e8 12
	extz XHL                                      ; F85863  eb 12
	m_ld_rm MWD+r4, 0x00, r0                      ; F85865  9c 00 20   ld WA,(XIX+0x00) -- next
	ld HL,(XIX+0x02)                              ; F85868  9c 02 23   prev
	m_st_mr16 MDD+r3, 0x00, r0                    ; F8586B  bb 00 50   ld (XHL+0x00),WA -- prev->next = next
	ld (XWA+0x02),HL                              ; F8586E  b8 02 53   next->prev = prev
	jrl Kernel_Dispatch                           ; F85871  78 a1 fe

; ---------------------------------------------------------------------
; Kernel_YieldRotate_StackArg -- the stack-argument face of Kernel_YieldRotate
;
; Called from: prom_b thunk 0xF42DB4 (`jp 0xF85874`), and nothing else
; Inputs:  (XSP+0x04) = the queue level
; Outputs: as Kernel_YieldRotate (0xF85877), which it falls into
; Evidence: the same three bytes 8F 04 21 as the other stack-argument entries,
;          sitting immediately above the register-argument entry that the FIRST
;          thunk run names.  See the region banner for the whole pairing.
; ---------------------------------------------------------------------
Kernel_YieldRotate_StackArg:
	ld A,(XSP+0x04)                               ; F85874  8f 04 21   the queue level, off the stack

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

; ==============================================================================
; 0xF85904-0xF8596C -- block the running task, and put a blocked one back
; ==============================================================================
;
; ★ QUEUE MEMBERSHIP IS RUNNABILITY; THE +9 STATE BYTE IS BOOKKEEPING.  These
;   two routines are what settle that, and it matters because it is the opposite
;   of what a reader expects.  Kernel_ReadyTask below puts a task back on its
;   ready queue and NEVER WRITES +9 -- it leaves the byte at 3.  That is not an
;   omission: Kernel_Dispatch__scan (0xF85746, converted above) picks a task by
;   walking the three heads and taking the first whose +0 differs from the head
;   address; it never reads +9.  So a task is runnable exactly while it is
;   linked into a ready queue, and +9 records WHY it is where it is.
;   ⚠ What the values mean in the firmware's own vocabulary is still not
;   established.  What IS established is who writes each one:
;     0  Kernel_InitRam, Kernel_ExitTask, 0xF85E5B
;     3  Kernel_BlockSelf (here) and MsgQueue_ReceiveBlocking
;     4  Kernel_StartTask
;
; ---------------------------------------------------------------------
; Kernel_BlockSelf -- take the running task off its queue and mark it blocked
;
; Called from: prom_b thunks 0xF42D7C AND 0xF42DB8 -- the same address in both
;          runs, so it takes no argument.  No prom_a site reaches it
;          (notes/prom_a_byte_checks.py).
; Inputs:  (0xBF) = the running task's control block, as Kernel_Dispatch left it
; Outputs: never returns to its caller.  The block is unlinked from whatever
;          queue it was on, its +9 becomes 3, and control passes to
;          Kernel_Dispatch -- which, because (0xBF) is still set, saves this
;          task's XSP into node+4 on the way.  That is what makes the task
;          RESUMABLE, and it is the whole difference from Kernel_ExitTask.
; Evidence: three instructions carry the name.  `ld IX,(0xBF)` at 0xF8590E takes
;          the RUNNING task rather than an argument -- (0xBF) is the byte
;          Kernel_Dispatch writes at 0xF8575B when it switches in.  0xF85917-
;          0xF85922 is the tree's unlink idiom verbatim, `prev->next = next;
;          next->prev = prev`, the same two stores as 0xF8589D-0xF858A8 and
;          0xF85865-0xF85870.  And `ld (XIX+0x09),0x03` at 0xF85923 writes the
;          same value MsgQueue_ReceiveBlocking writes when a receive finds the
;          queue empty -- which is the one place in this file where a task is
;          known to be waiting for something.
;          ⚠ Contrast with Kernel_ExitTask (0xF8584A), which is the same shape
;          but ALSO clears (0xBF) and switches to the boot stack.  This one does
;          neither, so its stack survives and Kernel_Dispatch records it.
; Unknown:  who calls it -- both references are prom_b thunks.
; ---------------------------------------------------------------------
Kernel_BlockSelf:
	push SR                                       ; F85904  02
	ei 0x06                                       ; F85905  06 06
	push XHL                                      ; F85907  3b
	push XWA                                      ; F85908  38
	push XBC                                      ; F85909  39
	push XDE                                      ; F8590A  3a
	push XIX                                      ; F8590B  3c
	push XIY                                      ; F8590C  3d
	push XIZ                                      ; F8590D  3e   the seven Kernel_ResumeTask will pop
	m_ld_rm MW8, 0xbf, r4                         ; F8590E  d0 bf 24   ld IX,(0xBF) -- the RUNNING task
	extz XIX                                      ; F85911  ec 12
	extz XWA                                      ; F85913  e8 12
	extz XHL                                      ; F85915  eb 12
	m_ld_rm MWD+r4, 0x00, r0                      ; F85917  9c 00 20   ld WA,(XIX+0x00) -- next
	ld HL,(XIX+0x02)                              ; F8591A  9c 02 23   prev
	m_st_mr16 MDD+r3, 0x00, r0                    ; F8591D  bb 00 50   ld (XHL+0x00),WA -- prev->next = next
	ld (XWA+0x02),HL                              ; F85920  b8 02 53   next->prev = prev
	ld (XIX+0x09),0x03                            ; F85923  bc 09 00 03   state 3 -- the value a blocking receive writes
	jrl Kernel_Dispatch                           ; F85927  78 eb fd   (0xBF) is left set, so the dispatcher saves XSP into node+4

; ---------------------------------------------------------------------
; Kernel_ReadyTask_StackArg -- the stack-argument face of Kernel_ReadyTask
;
; Called from: prom_b thunk 0xF42DBC (`jp 0xF8592A`), and nothing else
; Inputs:  (XSP+0x04) = the task number
; Outputs: as Kernel_ReadyTask, which it falls into
; Evidence: the same three bytes 8F 04 21 as the other stack-argument entries,
;          three bytes above the register entry the FIRST thunk run names.  See
;          the region banner at 0xF857D6.
; ---------------------------------------------------------------------
Kernel_ReadyTask_StackArg:
	ld A,(XSP+0x04)                               ; F8592A  8f 04 21   the task number, off the stack

; ---------------------------------------------------------------------
; Kernel_ReadyTask -- put blocked task A back on its ready queue
;
; Called from: prom_b thunk 0xF42D80; and by falling in from the entry above.
;          No prom_a site reaches either.
; Inputs:  A = the task number, 1..4
; Outputs: never returns to its caller -- it ends in Kernel_Dispatch either way.
;          If the task's +9 is 3 it is appended to the TAIL of ready queue
;          0x0330 + (level-1)*4, where level is its own +8.  If +9 is anything
;          else the routine does nothing at all.
; Evidence: the guard is literal -- `cp (XIX+0x09),0x03` at 0xF85942 tests for
;          exactly the value Kernel_BlockSelf above and MsgQueue_ReceiveBlocking
;          write, so this routine is the inverse of those two and of nothing
;          else.  The queue it chooses is not an argument: it comes from the
;          task's own +8 (0xF85948), which Kernel_StartTask filled from
;          EntryPoint_Records+10.  The four stores at 0xF8595C-0xF85969 are the
;          insert-at-tail idiom verbatim, the same as 0xF858AF-0xF858BC.
;          The TCB address 0x02F4 + A*12 is the same 1-based form as
;          Kernel_StartTask's.
; Notes:   ★ IT DOES NOT WRITE +9.  The state byte stays 3 while the task is
;          back on a ready queue and running.  See the region banner: queue
;          membership is what the dispatcher reads.
; Unknown:  who calls it, and therefore what "blocked" is blocked ON in the
;          cases that do not go through MsgQueue_ReceiveBlocking.
; ---------------------------------------------------------------------
Kernel_ReadyTask:
	push SR                                       ; F8592D  02
	ei 0x06                                       ; F8592E  06 06
	push XHL                                      ; F85930  3b
	push XWA                                      ; F85931  38
	push XBC                                      ; F85932  39
	push XDE                                      ; F85933  3a
	push XIX                                      ; F85934  3c
	push XIY                                      ; F85935  3d
	push XIZ                                      ; F85936  3e
	mul A,0x0c                                    ; F85937  c9 08 0c
	add WA,0x02f4                                 ; F8593A  d8 c8 f4 02   XIX = 0x0300 + (A-1)*12, the task control block
	ld IX,WA                                      ; F8593E  d8 8c
	extz XIX                                      ; F85940  ec 12
	cp (XIX+0x09),0x03                            ; F85942  8c 09 3f 03   only a BLOCKED task is re-queued
	jr nz, Kernel_ReadyTask__done                 ; F85946  6e 22
	ld A,(XIX+0x08)                               ; F85948  8c 08 21   +8 = the task's own priority level
	sll a, 0x02                                   ; F8594B  c9 ee 02
	extz WA                                       ; F8594E  d8 12
	add WA,0x032c                                 ; F85950  d8 c8 2c 03   the head, 0x0330 + (level-1)*4
	ld IY,WA                                      ; F85954  d8 8d
	extz XIX                                      ; F85956  ec 12
	extz XIY                                      ; F85958  ed 12
	extz XWA                                      ; F8595A  e8 12
	m_st_mr16 MDD+r4, 0x00, r5                    ; F8595C  bc 00 55   ld (XIX+0x00),IY -- n->next = head
	ld WA,(XIY+0x02)                              ; F8595F  9d 02 20
	ld (XIX+0x02),WA                              ; F85962  bc 02 50   n->prev = head->prev
	ld (XWA),IX                                   ; F85965  b0 54   head->prev->next = n
	ld (XIY+0x02),IX                              ; F85967  bd 02 54   head->prev = n
Kernel_ReadyTask__done:
	jrl Kernel_Dispatch                           ; F8596A  78 a8 fd

; ==============================================================================
; 0xF8596D-0xF85AEE -- the kernel's COUNTING SEMAPHORES, and a no-reschedule
;                      variant of Kernel_ReadyTask
; ==============================================================================
;
; ★ THIS REGION IDENTIFIES THE TWO STRUCTURES Kernel_InitRam LEFT UNEXPLAINED.
;   That routine creates eight self-linked list heads at 0x033C and copies eight
;   bytes from ROM 0xF85EBA to 0x035C, and this file could say no more about
;   either.  They are the two halves of EIGHT COUNTING SEMAPHORES:
;
;     0x033C + (s-1)*4   the wait queue for semaphore s, s = 1..8
;     0x035C + (s-1)     its count, ONE BYTE, saturating at 0xFF
;
;   The arrays are adjacent and both are exactly eight long: the last head is at
;   0x0358 and 0x0358 + 4 = 0x035C, where the counts begin, and 0x035C + 8 =
;   0x0364, which is the wait-queue array Kernel_InitRam creates next.  Both are
;   addressed with the same one-element bias as everything else in this kernel --
;   `0x0338 + s*4` and `0x035B + s`.
;
;   ★ AND THE ROM IMAGE IS THE INITIAL COUNTS.  The eight bytes at 0xF85EBA are
;     00 01 00 01 00 00 00 00, so semaphores 2 and 4 start at 1 and the other six
;     start at 0 -- two binary semaphores taken by the first waiter, and six that
;     block until something signals.  This is what those "UNIDENTIFIED" bytes
;     after EntryPoint_Records are for.
;
; ★ THE PAIR IS A TEXTBOOK P/V, and that is what carries the name -- not the
;   shape of one routine but the fact that two routines are exact inverses over
;   the same two arrays:
;
;     WAIT   (0xF85A96)  count non-zero -> decrement it and RETURN;
;                        count zero     -> unlink the running task, state := 3,
;                                          append it to queue s, dispatch
;     SIGNAL (0xF859AE)  queue non-empty -> unlink its FIRST node, state := 4,
;                                           append to that task's ready queue
;                        queue empty     -> increment the count, saturating
;
;   Nothing else in this kernel touches 0x033C or 0x035C.
;
; ★ EVERY PRIMITIVE COMES IN TWO FORMS.  Signal exists twice: 0xF859AE ends in
;   `jrl Kernel_Dispatch` and 0xF85A22 ends in `ret`.  The same split is already
;   visible one region up -- Kernel_ReadyTask (0xF8592D) dispatches and
;   Kernel_ReadyTask_NoDispatch (0xF8596D) returns.  A caller that must not lose
;   the CPU (an interrupt handler, or kernel code mid-sequence) uses the second.
;   The two members of a pair are byte-for-byte the same logic with a different
;   epilogue; the differences are measured, not asserted -- see each header.
;
; Everything quantified here is re-derived by notes/prom_a_byte_checks.py.
;
; ---------------------------------------------------------------------
; Kernel_ReadyTask_NoDispatch -- Kernel_ReadyTask, but it returns to its caller
;
; Called from: prom_b thunk 0xF42D84, and nothing else.  It has no
;          stack-argument face: the second thunk run has no slot for it.
; Inputs:  A = the task number, 1..4
; Outputs: if the task's +9 is 3 it is appended to the tail of ready queue
;          0x0330 + (level-1)*4.  Then it RETURNS -- no reschedule.  Only XWA,
;          XIX, XIY and SR are saved, because the caller keeps running.
; Evidence: the body is Kernel_ReadyTask's (0xF8592D, converted above) with a
;          different prologue and epilogue: the same `cp (XIX+0x09),0x03` guard,
;          the same 0x02F4 + A*12, the same 0x032C + level*4 and the same four
;          insert-at-tail stores.  ⚠ MEASURED, not asserted: 0xF85937 and
;          0xF85973 are IDENTICAL for exactly 51 bytes -- the identity extends
;          0 bytes backwards and stops at byte 51, which is each routine's
;          epilogue.  notes/prom_a_byte_checks.py does that diff and checks both
;          ends of the run, not just its start.
; Unknown:  who calls it -- the one reference is a prom_b thunk.
; ---------------------------------------------------------------------
Kernel_ReadyTask_NoDispatch:
	push XWA                                      ; F8596D  38
	push XIX                                      ; F8596E  3c
	push XIY                                      ; F8596F  3d
	push SR                                       ; F85970  02
	ei 0x06                                       ; F85971  06 06
	mul A,0x0c                                    ; F85973  c9 08 0c
	add WA,0x02f4                                 ; F85976  d8 c8 f4 02
	ld IX,WA                                      ; F8597A  d8 8c
	extz XIX                                      ; F8597C  ec 12
	cp (XIX+0x09),0x03                            ; F8597E  8c 09 3f 03
	jr nz, Kernel_ReadyTask_NoDispatch__done                               ; F85982  6e 22
	ld A,(XIX+0x08)                               ; F85984  8c 08 21
	sll a, 0x02                                   ; F85987  c9 ee 02
	extz WA                                       ; F8598A  d8 12
	add WA,0x032c                                 ; F8598C  d8 c8 2c 03
	ld IY,WA                                      ; F85990  d8 8d
	extz XIX                                      ; F85992  ec 12
	extz XIY                                      ; F85994  ed 12
	extz XWA                                      ; F85996  e8 12
	m_st_mr16 MDD+r4, 0x00, r5                    ; F85998  bc 00 55
	ld WA,(XIY+0x02)                              ; F8599B  9d 02 20
	ld (XIX+0x02),WA                              ; F8599E  bc 02 50
	ld (XWA),IX                                   ; F859A1  b0 54
	ld (XIY+0x02),IX                              ; F859A3  bd 02 54
Kernel_ReadyTask_NoDispatch__done:
	pop SR                                        ; F859A6  03
	pop XIY                                       ; F859A7  5d
	pop XIX                                       ; F859A8  5c
	pop XWA                                       ; F859A9  58
	ret                                           ; F859AA  0e

; ---------------------------------------------------------------------
; Kernel_SemaSignal_StackArg -- the stack-argument face of Kernel_SemaSignal
;
; Called from: prom_b thunk 0xF42DC0 (`jp 0xF859AB`), and nothing else
; Inputs:  (XSP+0x04) = the semaphore number, 1..8
; Outputs: as Kernel_SemaSignal, which it falls into
; Evidence: the same three bytes 8F 04 21 as every other stack face, three bytes
;          above the register entry the first thunk run names (0xF42D88 ->
;          0xF859AE).  See the region banner at 0xF857D6.
; ---------------------------------------------------------------------
Kernel_SemaSignal_StackArg:
	ld A,(XSP+0x04)                               ; F859AB  8f 04 21

; ---------------------------------------------------------------------
; Kernel_SemaSignal -- V(s): wake the first waiter, or bump the count
;
; Called from: prom_b thunk 0xF42D88; and by falling in from the stack face
;          above.  No prom_a site reaches either.
; Inputs:  A = the semaphore number, 1..8
; Outputs: never returns to its caller.  If a task is waiting on semaphore A it
;          is unlinked from that wait queue, its +9 becomes 4, it is appended to
;          the tail of its OWN ready queue (from its +8), and control passes to
;          Kernel_Dispatch.  If nobody is waiting, the count byte is incremented
;          -- unless it is already 0xFF -- and control returns through
;          Kernel_ResumeTask's pops.
; Evidence: the two arrays are literal and adjacent: `add WA,0x0338` at 0xF859BF
;          with A*4 is the head 0x033C + (A-1)*4, and `add HL,0x035b` at 0xF859D0
;          with A (not A*4) is the count 0x035C + (A-1).  The emptiness test is
;          the tree's own `head->next == head` -- `ld IX,(XIY+0x00) / cp IX,IY`
;          at 0xF859C7 -- the same test Kernel_Dispatch__scan uses.
;          ★ THE SATURATION IS THE INSTRUCTION, not a reading: `ld A,(XHL) /
;          inc 1,A / jr Z,+2 / ld (XHL),A` at 0xF859D6-0xF859DD skips the store
;          exactly when the increment wrapped 0xFF to 0x00, so 0xFF is a ceiling
;          rather than a wrap.
;          The woken task's state is set to 4 (0xF859F3), the value
;          Kernel_StartTask writes for a runnable task, and its queue comes from
;          its own +8 (0xF859F7) -- not from the semaphore.
; Unknown:  who signals which semaphore.  All eight are anonymous here; the
;          callers are in prom_b.
; ---------------------------------------------------------------------
Kernel_SemaSignal:
	push SR                                       ; F859AE  02
	ei 0x06                                       ; F859AF  06 06
	push XHL                                      ; F859B1  3b
	push XWA                                      ; F859B2  38
	push XBC                                      ; F859B3  39
	push XDE                                      ; F859B4  3a
	push XIX                                      ; F859B5  3c
	push XIY                                      ; F859B6  3d
	push XIZ                                      ; F859B7  3e
	ld L,A                                        ; F859B8  c9 8f
	sll a, 0x02                                   ; F859BA  c9 ee 02
	extz WA                                       ; F859BD  d8 12
	add WA,0x0338                                 ; F859BF  d8 c8 38 03
	ld IY,WA                                      ; F859C3  d8 8d
	extz XIY                                      ; F859C5  ed 12
	m_ld_rm MWD+r5, 0x00, r4                      ; F859C7  9d 00 24
	cp IX,IY                                      ; F859CA  dd f4
	jr nz, Kernel_SemaSignal__wake                               ; F859CC  6e 13
	extz HL                                       ; F859CE  db 12
	add HL,0x035b                                 ; F859D0  db c8 5b 03
	extz XHL                                      ; F859D4  eb 12
	ld A,(XHL)                                    ; F859D6  83 21
	inc 1,A                                       ; F859D8  c9 61
	jr z, Kernel_SemaSignal__return                                ; F859DA  66 02
	ld (XHL),A                                    ; F859DC  b3 41
Kernel_SemaSignal__return:
	jrl Kernel_ResumeTask                                      ; F859DE  78 82 fd
Kernel_SemaSignal__wake:
	extz XIX                                      ; F859E1  ec 12
	extz XWA                                      ; F859E3  e8 12
	extz XHL                                      ; F859E5  eb 12
	m_ld_rm MWD+r4, 0x00, r0                      ; F859E7  9c 00 20
	ld HL,(XIX+0x02)                              ; F859EA  9c 02 23
	m_st_mr16 MDD+r3, 0x00, r0                    ; F859ED  bb 00 50
	ld (XWA+0x02),HL                              ; F859F0  b8 02 53
	ld (XIX+0x09),0x04                            ; F859F3  bc 09 00 04
	ld A,(XIX+0x08)                               ; F859F7  8c 08 21
	sll a, 0x02                                   ; F859FA  c9 ee 02
	extz WA                                       ; F859FD  d8 12
	add WA,0x032c                                 ; F859FF  d8 c8 2c 03
	ld IY,WA                                      ; F85A03  d8 8d
	extz XIX                                      ; F85A05  ec 12
	extz XIY                                      ; F85A07  ed 12
	extz XWA                                      ; F85A09  e8 12
	m_st_mr16 MDD+r4, 0x00, r5                    ; F85A0B  bc 00 55
	ld WA,(XIY+0x02)                              ; F85A0E  9d 02 20
	ld (XIX+0x02),WA                              ; F85A11  bc 02 50
	ld (XWA),IX                                   ; F85A14  b0 54
	ld (XIY+0x02),IX                              ; F85A16  bd 02 54
	jrl Kernel_Dispatch                                      ; F85A19  78 f9 fc

; ---------------------------------------------------------------------
; Kernel_SemaSignal_NoDispatch_StackArg -- stack face, and it is NOT `8F 04 21`
;
; Called from: nothing in either ROM names 0xF85A1C -- it is not in the thunk
;          block and no prom_a site reaches it (notes/prom_a_byte_checks.py).
;          It is reachable only as the entry ABOVE Kernel_SemaSignal_NoDispatch,
;          which is how every other stack face in this kernel is reached.
; Inputs:  (XSP+0x04) = the semaphore number, before its own push
; Outputs: as Kernel_SemaSignal_NoDispatch
; Evidence: ⚠ this one breaks the `ld A,(XSP+0x04)` pattern and the reason is
;          visible in the bytes: it pushes XWA FIRST (0xF85A1C) and therefore
;          reads its argument at (XSP+0x08), four bytes deeper, then `jr` over
;          the register entry's own `push XWA`.  The two paths converge at
;          0xF85A23 with XWA pushed exactly once either way.  That is the same
;          trick 0xF85B0D uses with (XSP+0x24) after seven pushes.
; ---------------------------------------------------------------------
Kernel_SemaSignal_NoDispatch_StackArg:
	push XWA                                      ; F85A1C  38
	ld A,(XSP+0x08)                               ; F85A1D  8f 08 21
	jr Kernel_SemaSignal_NoDispatch__common                                   ; F85A20  68 01

; ---------------------------------------------------------------------
; Kernel_SemaSignal_NoDispatch -- V(s), returning to the caller
;
; Called from: prom_b thunk 0xF42D8C, and nothing else
; Inputs:  A = the semaphore number, 1..8
; Outputs: as Kernel_SemaSignal, except that it RETURNS instead of entering the
;          scheduler, so a woken task does not run until the next reschedule.
;          Saves XWA, XIX, XIY, XHL and SR only.
; Evidence: same two arrays, same emptiness test, same saturating increment and
;          same insert-at-tail as Kernel_SemaSignal above -- and the sameness is
;          MEASURED rather than asserted, run by run, by
;          notes/prom_a_byte_checks.py:
;            the WAKE arm      0xF859E1 / 0xF85A55   56 bytes identical
;            the COUNT arm     0xF859CE / 0xF85A3F   16 bytes identical
;            the emptiness test 0xF859C7 / 0xF85A38   6 bytes identical
;            the index arithmetic 0xF859B8 / 0xF85A26 15 bytes identical
;          and each run stops at the FIRST byte of its epilogue -- 0xF85A19 is
;          `jrl Kernel_Dispatch` where 0xF85A8D is `pop SR`, and 0xF859DE is
;          `jrl Kernel_ResumeTask` where 0xF85A4F is `pop SR`.
;          ⚠ THE WHOLE ROUTINES ARE NOT IDENTICAL and this header does not say
;          they are: the arithmetic run breaks at 0xF859C7 / 0xF85A35 because
;          this variant defers `push SR / ei 0x06` until AFTER it has computed
;          the queue head, while Kernel_SemaSignal does it in its prologue.  A
;          first draft of this header claimed "74 bytes, 0 differ"; the real
;          figure over that span is 51 differing bytes of 74, which is why the
;          runs are quoted individually.
; ---------------------------------------------------------------------
Kernel_SemaSignal_NoDispatch:
	push XWA                                      ; F85A22  38
Kernel_SemaSignal_NoDispatch__common:
	push XIX                                      ; F85A23  3c
	push XIY                                      ; F85A24  3d
	push XHL                                      ; F85A25  3b
	ld L,A                                        ; F85A26  c9 8f
	sll a, 0x02                                   ; F85A28  c9 ee 02
	extz WA                                       ; F85A2B  d8 12
	add WA,0x0338                                 ; F85A2D  d8 c8 38 03
	ld IY,WA                                      ; F85A31  d8 8d
	extz XIY                                      ; F85A33  ed 12
	push SR                                       ; F85A35  02
	ei 0x06                                       ; F85A36  06 06
	m_ld_rm MWD+r5, 0x00, r4                      ; F85A38  9d 00 24
	cp IX,IY                                      ; F85A3B  dd f4
	jr nz, Kernel_SemaSignal_NoDispatch__wake                               ; F85A3D  6e 16
	extz HL                                       ; F85A3F  db 12
	add HL,0x035b                                 ; F85A41  db c8 5b 03
	extz XHL                                      ; F85A45  eb 12
	ld A,(XHL)                                    ; F85A47  83 21
	inc 1,A                                       ; F85A49  c9 61
	jr z, Kernel_SemaSignal_NoDispatch__return                                ; F85A4B  66 02
	ld (XHL),A                                    ; F85A4D  b3 41
Kernel_SemaSignal_NoDispatch__return:
	pop SR                                        ; F85A4F  03
	pop XHL                                       ; F85A50  5b
	pop XIY                                       ; F85A51  5d
	pop XIX                                       ; F85A52  5c
	pop XWA                                       ; F85A53  58
	ret                                           ; F85A54  0e
Kernel_SemaSignal_NoDispatch__wake:
	extz XIX                                      ; F85A55  ec 12
	extz XWA                                      ; F85A57  e8 12
	extz XHL                                      ; F85A59  eb 12
	m_ld_rm MWD+r4, 0x00, r0                      ; F85A5B  9c 00 20
	ld HL,(XIX+0x02)                              ; F85A5E  9c 02 23
	m_st_mr16 MDD+r3, 0x00, r0                    ; F85A61  bb 00 50
	ld (XWA+0x02),HL                              ; F85A64  b8 02 53
	ld (XIX+0x09),0x04                            ; F85A67  bc 09 00 04
	ld A,(XIX+0x08)                               ; F85A6B  8c 08 21
	sll a, 0x02                                   ; F85A6E  c9 ee 02
	extz WA                                       ; F85A71  d8 12
	add WA,0x032c                                 ; F85A73  d8 c8 2c 03
	ld IY,WA                                      ; F85A77  d8 8d
	extz XIX                                      ; F85A79  ec 12
	extz XIY                                      ; F85A7B  ed 12
	extz XWA                                      ; F85A7D  e8 12
	m_st_mr16 MDD+r4, 0x00, r5                    ; F85A7F  bc 00 55
	ld WA,(XIY+0x02)                              ; F85A82  9d 02 20
	ld (XIX+0x02),WA                              ; F85A85  bc 02 50
	ld (XWA),IX                                   ; F85A88  b0 54
	ld (XIY+0x02),IX                              ; F85A8A  bd 02 54
	pop SR                                        ; F85A8D  03
	pop XHL                                       ; F85A8E  5b
	pop XIY                                       ; F85A8F  5d
	pop XIX                                       ; F85A90  5c
	pop XWA                                       ; F85A91  58
	ret                                           ; F85A92  0e

; ---------------------------------------------------------------------
; Kernel_SemaWait_StackArg -- the stack-argument face of Kernel_SemaWait
;
; Called from: prom_b thunk 0xF42DC4 (`jp 0xF85A93`), and nothing else
; Inputs:  (XSP+0x04) = the semaphore number, 1..8
; Outputs: as Kernel_SemaWait, which it falls into
; Evidence: the `8F 04 21` prologue again, three bytes above the register entry
;          the first thunk run names (0xF42D90 -> 0xF85A96).
; ---------------------------------------------------------------------
Kernel_SemaWait_StackArg:
	ld A,(XSP+0x04)                               ; F85A93  8f 04 21

; ---------------------------------------------------------------------
; Kernel_SemaWait -- P(s): take the count, or block on the semaphore's queue
;
; Called from: prom_b thunk 0xF42D90; and by falling in from the stack face.
; Inputs:  A = the semaphore number, 1..8
; Outputs: if the count byte is non-zero it is DECREMENTED and the routine
;          returns to its caller through Kernel_ResumeTask's pops -- the caller
;          keeps the CPU.  If it is zero, the RUNNING task (from (0xBF)) is
;          unlinked from its ready queue, its +9 becomes 3, it is appended to
;          the tail of semaphore A's wait queue, and control passes to
;          Kernel_Dispatch, which -- because (0xBF) is still set -- saves its
;          XSP into node+4 first.  So the task resumes exactly here when
;          Kernel_SemaSignal wakes it.
; Evidence: ★ it is the EXACT INVERSE of Kernel_SemaSignal over the same two
;          arrays, and that is what makes "semaphore" a name rather than a
;          guess: `add WA,0x035b` at 0xF85AA4 is the same count byte
;          0x035C + (A-1); `cp (XWA),0x00 / jr z` at 0xF85AAA is the test
;          Signal's "queue empty" arm complements; `dec 1,(XWA)` at 0xF85AAF
;          undoes Signal's `inc 1,A`; and `add DE,0x0338` at 0xF85AD2 with A*4
;          is the same wait queue 0x033C + (A-1)*4 that Signal pops from.
;          The blocking arm is Kernel_BlockSelf's body verbatim -- (0xBF), the
;          unlink idiom, +9 := 3 -- followed by the insert-at-tail idiom onto
;          the semaphore's queue instead of a ready queue.
;          ⚠ Note it keeps the semaphore number in E across the unlink
;          (`ld E,A` at 0xF85AA0), because A is destroyed by the count
;          arithmetic; the queue index is recomputed from E at 0xF85ACD.
; Unknown:  which semaphore is which.  Nothing here names them, and the two that
;          start at 1 (numbers 2 and 4, from the ROM image at 0xF85EBA) are the
;          only asymmetry the firmware itself shows.
; ---------------------------------------------------------------------
Kernel_SemaWait:
	push SR                                       ; F85A96  02
	ei 0x06                                       ; F85A97  06 06
	push XHL                                      ; F85A99  3b
	push XWA                                      ; F85A9A  38
	push XBC                                      ; F85A9B  39
	push XDE                                      ; F85A9C  3a
	push XIX                                      ; F85A9D  3c
	push XIY                                      ; F85A9E  3d
	push XIZ                                      ; F85A9F  3e
	ld E,A                                        ; F85AA0  c9 8d
	extz WA                                       ; F85AA2  d8 12
	add WA,0x035b                                 ; F85AA4  d8 c8 5b 03
	extz XWA                                      ; F85AA8  e8 12
	cp (XWA),0x00                                 ; F85AAA  80 3f 00
	jr z, Kernel_SemaWait__block                                ; F85AAD  66 05
	decm8 0x01, (xwa)                             ; F85AAF  80 69
	jrl Kernel_ResumeTask                                      ; F85AB1  78 af fc
Kernel_SemaWait__block:
	m_ld_rm MW8, 0xbf, r4                         ; F85AB4  d0 bf 24
	extz XIX                                      ; F85AB7  ec 12
	extz XWA                                      ; F85AB9  e8 12
	extz XHL                                      ; F85ABB  eb 12
	m_ld_rm MWD+r4, 0x00, r0                      ; F85ABD  9c 00 20
	ld HL,(XIX+0x02)                              ; F85AC0  9c 02 23
	m_st_mr16 MDD+r3, 0x00, r0                    ; F85AC3  bb 00 50
	ld (XWA+0x02),HL                              ; F85AC6  b8 02 53
	ld (XIX+0x09),0x03                            ; F85AC9  bc 09 00 03
	sll e, 0x02                                   ; F85ACD  cd ee 02
	extz DE                                       ; F85AD0  da 12
	add DE,0x0338                                 ; F85AD2  da c8 38 03
	ld IY,DE                                      ; F85AD6  da 8d
	extz XIX                                      ; F85AD8  ec 12
	extz XIY                                      ; F85ADA  ed 12
	extz XWA                                      ; F85ADC  e8 12
	m_st_mr16 MDD+r4, 0x00, r5                    ; F85ADE  bc 00 55
	ld WA,(XIY+0x02)                              ; F85AE1  9d 02 20
	ld (XIX+0x02),WA                              ; F85AE4  bc 02 50
	ld (XWA),IX                                   ; F85AE7  b0 54
	ld (XIY+0x02),IX                              ; F85AE9  bd 02 54
	jrl Kernel_Dispatch                                      ; F85AEC  78 26 fc

; ---------------------------------------------------------------------
; Kernel_SemaTryWait -- P(s) that never blocks: take the count or say no
;
; Called from: prom_b thunk 0xF42DD8 (`jp 0xF85AEF`), and nothing else.  ⚠ It is
;          the ONLY semaphore entry with no register-argument twin in the first
;          thunk run -- it is published once, and only with a stack argument.
; Inputs:  (XSP+0x04) = the semaphore number, 1..8
; Outputs: WA = 0 if the count was non-zero, in which case it was DECREMENTED;
;          WA = 0xFFFF if it was zero, in which case nothing was touched.  It
;          always returns to its caller and can never block, so it is safe from
;          code that must not lose the CPU.  Only SR is saved.
; Evidence: it is Kernel_SemaWait's first arm and nothing else.  The count byte
;          is the same 0x035B + s (0xF85AF4) that Wait, Signal and
;          Signal_NoDispatch use -- notes/prom_a_byte_checks.py enumerates all
;          seven sites in prom_a that form that base and there are no others --
;          and `cp (XWA),0x00 / jr z` at 0xF85AFD is Wait's test verbatim
;          (0xF85AAA), followed by Wait's `dec 1,(XWA)` (0xF85B02 against
;          0xF85AAF).  Where Wait then blocks the running task, this one loads a
;          RESULT: `xor WA,WA` on the success path (0xF85B04) and
;          `ld WA,0xFFFF` on the failure path (0xF85B08).
;          ⚠ It never touches the semaphore's WAIT QUEUE at 0x033C -- the byte
;          pair that forms that base (C8 38 03) does not occur in these 30
;          bytes, which is the check named above seen from the other side.
; Unknown:  who calls it.  The single reference is a prom_b thunk.
; ---------------------------------------------------------------------
Kernel_SemaTryWait:
	ld A,(XSP+0x04)                               ; F85AEF  8f 04 21   the semaphore number, off the stack
	extz WA                                       ; F85AF2  d8 12
	add WA,0x035b                                 ; F85AF4  d8 c8 5b 03   the count byte, 0x035C + (s-1)
	extz XWA                                      ; F85AF8  e8 12
	push SR                                       ; F85AFA  02
	ei 0x06                                       ; F85AFB  06 06
	cp (XWA),0x00                                 ; F85AFD  80 3f 00
	jr z, Kernel_SemaTryWait__fail                ; F85B00  66 06
	decm8 0x01, (xwa)                             ; F85B02  80 69   take one
	xor WA,WA                                     ; F85B04  d8 d0   0 = taken
	jr Kernel_SemaTryWait__ret                    ; F85B06  68 03
Kernel_SemaTryWait__fail:
	ldw wa, 0xffff                                ; F85B08  30 ff ff   0xFFFF = not taken; the count is untouched
Kernel_SemaTryWait__ret:
	pop SR                                        ; F85B0B  03
	ret                                           ; F85B0C  0e
	.incbin "original_ROMs/wsa1_prom_a.ic12", 0x005B0D, 0x00017C

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
	; 0xF85EBA-0xF85EC1: IDENTIFIED 2026-08-25 -- it is a ROM IMAGE OF RAM.
	; Kernel_InitRam (0xF85653-0xF85661, converted above) does
	; `ld XHL,0x00F85EBA / ld DE,0x035C / ld BC,0x0008 / ldir`, copying exactly
	; these eight bytes to 0x035C-0x0363.  Still NOT a fifth record --
	; 0x01000100 is not an address -- and what the eight bytes MEAN once they
	; are in RAM is still open; only their destination is established.
	; prom_c has 01 00 01 01 in the same position.
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
; Evidence: the register index is computed in the open -- `ld A,(XSP+0x04)`
;          then `sll a,0x05` and `set 4,A` (0xF85F60, 0xF85F63) give
;          (channel<<5)|0x10, which notes/prom_a_byte_checks.py re-reads --
;          and the loop count is the literal `ldb d,0x08` at 0xF85F6B: eight
;          (select, write) pairs, `ld (XBC),A` to the index port at +0 and `ld
;          (XBC+0x02),E` to the data port at +2. "FromTable" is `ldb_spi
;          e,0xf4` = `ld E,(XIY+)` at 0xF85F6F: the values walk the caller's
;          array. The four callers are pinned by the same script.
;          ⚠ "DSP" is the DEVICE reading -- this window is 0x007F0000 and the
;          KN5000 sub-CPU has the same routines against ITS OWN base -- not a
;          part number.
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
; Called from: prom_b thunk 0xF42DE4 (`jp 0xF85F7C`), the LAST slot of the
;          kernel thunk block at 0xF42D60-0xF42DE7.  No prom_a site reaches it.
;          Its neighbour 0xF42DE0 publishes DSP_WriteChannelRegs_FromTable the
;          same way, so both DSP writers are exported next to the kernel API.
; Inputs:  XBC/XDE hold the data for channel 1; XIZ, XWA/XHL and XIX/XIY carry
;          the data for channels 0, 2 and 3 respectively -- the routine shuffles
;          them into XBC/XDE before each call.
; Outputs: 8 registers written in each of channels 1, 0, 2, 3, in that order.
; Evidence: "all four channels" is the four `pushw <imm> / calr` pairs and the
;          immediates are LITERAL -- 1 at 0xF85F7E, 0 at 0xF85F89, 2 at
;          0xF85F93, 3 at 0xF85F9D -- so the order 1, 0, 2, 3 is read off the
;          bytes and is not the natural one a reader would assume.  The tail
;          `inc 0,XSP` (0xF85FA3) drops 8 bytes, which is exactly those four
;          16-bit pushes.
; Sibling: byte-identical to the KN5000 sub-CPU's DSP_WriteAllChannelRegs, and
;          that is now a MEASUREMENT: over the sibling symbol's whole 44-byte
;          extent (kn5000 0x1FCFB) ZERO bytes differ.  Re-derived from the
;          sibling ELF by notes/prom_a_byte_checks.py.  ⚠ Its callee
;          DSP_WriteChannelRegs_Inner is NOT byte-identical -- see that header.
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
; Evidence: the eight (index, data) pairs are literal and alternate strictly --
;          `ld (XIY),A` to the index port at +0, then one `ld (XIY+0x02),<reg>`
;          to the data port at +2, `inc 1,A` between pairs -- eight of each,
;          0xF85FB9 to 0xF85FF4.  The starting index is computed, not assumed:
;          `sll a,0x05` then `set 4,A` (0xF85FAE, 0xF85FB1) is (channel<<5)|0x10.
;
; ★ CORRECTED 2026-08-25.  This header used to say "the seventh write is
;   `ld (XIY+0x00),0x00`, i.e. a zero to the INDEX port rather than to the data
;   port at +2 ... in the KN5000's copy too, byte for byte".  THERE IS NO SUCH
;   INSTRUCTION.  No `ld (XIY+0x00),0x00` appears anywhere in this routine, and
;   none appears in the sibling either (kn5000-roms-disasm
;   v142/subcpu/kn5000_subprogram_v142.s:492-525).  The seventh DATA write is
;   `ld (XIY+0x02),C` at 0xF85FEB, an ordinary write of QDE's low byte.  A
;   trailing comment on 0xF85FE1 repeated the same invention and is gone too.
;
; ★ THE KN5000 DIFF, MEASURED, NOT ASSERTED.  Over the sibling symbol's whole
;   81-byte extent (kn5000 0x1FD27), 80 bytes are identical and EXACTLY ONE
;   differs: offset 15 = 0xF85FB7, the third byte of `ld XIY,0x007F0000`.  The
;   KN5000 holds 0x13 there, i.e. its DSP register file is at 0x00130000 and
;   this machine's is at 0x007F0000.  So the routine is shared and THE
;   PERIPHERAL BASE IS NOT -- copying the sibling's comment verbatim would have
;   written a non-existent address into this tree.  Both numbers are re-derived
;   by notes/prom_a_byte_checks.py from the sibling ELF.
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
	ld (XIY+0x02),D                               ; F85FE1  bd 02 44   data write 6 of 8
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
; Evidence: the port is literal -- `ld XBC,0x007C0000` at 0xF8E48F then `ld
;          H,(XBC)` at 0xF8E494 -- and the byte read is stored at (0x600780)
;          immediately (0xF8E496) and then compared against 0xE1, 0xE2 and
;          0xE6 (0xF8E49F, 0xF8E4A5, 0xF8E4AB), which is what makes it a
;          COMMAND and not data. notes/prom_a_byte_checks.py pins that vector
;          slot 0x28 does not point at the hang, and that each of the four
;          arming sites really is `ldio DMA3V,0x0A`.
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
; Evidence: the first instruction is the identification -- `res 2,(0x20)` at
;          0xF8E52D clears TRUN bit 2, i.e. stops the timer that PACES micro-
;          DMA channel 2, and no other peripheral is touched anywhere in the
;          handler. The channel number comes from the arming code rather than
;          from the slot name: 0xF8E166 is 08 7E 12 = `ldio DMA2V,0x12`, and
;          0x12 << 2 = 0x48 = the INTT2 vector, with `set 2,(0x20)` starting
;          the timer on the next instruction.
;          ⚠ the slot NAME "INTTC2" is the TLCS-900/H convention.
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
; Evidence: every one of the seven names is mechanical AND machine-checked:
;          notes/prom_a_byte_checks.py reads the CONTROL-REGISTER NUMBER out
;          of the third byte of each `ldc` and asserts the pair each setter
;          writes ("uDMA2_SetDest: writes CR 0x18 then CR 0x2A", and so for
;          all four), plus that the two MODE setters take an 8-bit operand and
;          the two COUNT setters a 16-bit one -- which is what distinguishes
;          them from each other. The control-register numbers come from MAME
;          (900tbl.hxx:3931-4030), not from a databook this tree does not
;          have.
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
; MemCopyWords -- copy (XSP+0x10) BYTES from (XSP+0x08) to (XSP+0x0C)
;
; Called from: not yet traced
; Inputs:  all three arguments on the stack; XIX = destination, XIY = source,
;          BC = byte count (the routine loads them itself)
; Outputs: the block copied.  XIX is preserved (pushed/popped); XIY, BC
;          clobbered.
; Evidence: the direction is fixed by the INSTRUCTION, not by the argument
;          order.  On the TLCS-900 the block moves take their destination from
;          XIX and their source from XIY: MAME decodes the 0x90-0x97 prefix
;          group with `m_p1_reg32 = get_reg32_current(m_op - 1)` and
;          `m_p2_reg32 = get_reg32_current(m_op)` (900tbl.hxx:5472-5473, and
;          `reg & 7` at :198), and `op_LDIRW` is `WRMEMW(*p1, RDMEMW(*p2))`
;          (:2514).  Prefix 0x95 therefore means p1 = XIX, p2 = XIY.  So
;          `ld XIY,(XSP+0x08)` at 0xF8E6E6 loads the SOURCE and
;          `ld XIX,(XSP+0x0C)` at 0xF8E6E9 the DESTINATION.
;          Cross-check inside this same file: TextShift_CopyAtoC (0xF904D5)
;          loads XIY = 0x256A (buffer A) and XIX = 0x258A (buffer C) and its
;          header reads "(0x258A..) = (0x256A..)" -- the same direction.
;
; ★ CORRECTED 2026-08-25.  Both the title line and the Inputs line had source
;   and destination THE WRONG WAY ROUND ("XIY = destination, XIX = source").
;   The byte gate cannot see this: the bytes are right, the sentence was not.
; Notes:   it is a word copy with a one-byte lead-in: if the count is odd it
;          does a single LDI first (`ldi85`, 0xF8E6F1, the byte-size form of the
;          same operand group), then halves the count and runs LDIRW.  Not
;          micro-DMA at all despite the company it keeps -- LDI/LDIRW are
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
; Evidence: all six slots are `jp nnn` and are emitted as symbols, so the byte
;          gate checks each target; notes/prom_a_byte_checks.py additionally
;          re-reads the six targets and the fact that the four "unused" ones
;          point at 0xF8E818, whose body is the single byte 0x0E = RET.
;          ⚠ "the module's public entry points" is the SHAPE (a jump table at a
;          fixed address at the start of the module), not a citation -- the
;          callers are in prom_b and have not been traced.
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
; Evidence: the controller FAMILY is established for the whole block by the
;          banner above -- every command byte written to 0x790001 is in MAME's
;          SED1330 table and no byte outside it is ever written
;          (notes/lcd_command_census.py). "Power-on setup" is this routine's
;          own content: it is slot 0 of the entry table, opens `ld
;          XIY,0x00790000` + SYSTEM SET (0xF8E819, 0xF8E81E), and ends by
;          clearing all 32768 display bytes -- notes/prom_a_byte_checks.py
;          checks that arithmetic ("setup: 0x0800 * 16 = 32768 = the whole
;          display RAM") and this routine's length ("svc 0x10 is 308 bytes and
;          LCD_Init_SED1330 is 390").
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
; Evidence: the whole routine is three instructions -- `bit 4,(0x97)` at
;          0xF8E99F, `jr nz,0xF8E9A4`, and `ret` at 0xF8E9A4 -- and the branch
;          target IS the fall-through, so the name states exactly what the
;          code does and nothing more. Its only caller is slot 2 of
;          LCD_EntryThunks, which is emitted as a symbol and re-read from the
;          ROM by notes/prom_a_byte_checks.py.
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
; Evidence: `and A,0x3f` at 0xF8E9AF is the whole argument for "64 services" --
;          six bits of A -- and `sla hl,0x02` at 0xF8E9B4 scales by 4 before
;          0xF8E9B7 loads the table base 0xF8E9C6. 64 x 4 = 256 bytes is
;          exactly the table's extent. What makes it a SERVICE CALL rather
;          than a jump table is `call (XWA)` at 0xF8E9C2 with the caller's own
;          registers still live, and the `pop SR / ret` pair at 0xF8E9C4
;          discarding the SR the SWI pushed.
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
; Evidence: the counts are a script's output, not a reader's -- `python3
;          notes/swi7_service_table.py` reads all 64 slots out of the ROM and
;          prints 34 live / 30 dead / 34 distinct, checks every live target
;          lands inside prom_a, and checks that the byte after slot 0x3F is
;          the 0x0E RET the dead slots point at. The 64 itself comes from the
;          dispatcher's `and A,0x3f` (0xF8E9AF), so the table's length and the
;          service-number space are one fact, not two. Every converted slot is
;          emitted as a SYMBOL, so the byte gate checks its address.
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
;           ★ ALL 34 live services are converted and named as of 2026-08-25, and
;           every one of their entries below is a real SYMBOL, so the byte gate
;           checks the address of each.  Do not retype the list: `python3
;           notes/swi7_service_table.py` prints it, and prints anything still
;           `.incbin` -- as of 2026-08-25 that list is EMPTY.
;           ⚠ CORRECTED 2026-08-25: this paragraph said "23 of the 34 ... as of
;           2026-08-24" and named eleven slots as still `.incbin`.  The eleven
;           (0x0E 0x0F 0x10 0x11 0x12 0x14 0x15 0x17 0x1B 0x1C 0x1E) were
;           converted in the round that landed 0xF8F850-0xF90988, and this text
;           was not updated with them.  The script was right; the header rotted.
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
	.long LCD_Svc_16_DrawKatakanaHalfWidth	; F8EA1E  a3 f0 f8 00   svc 0x16
	.long 0x00F90118			; F8EA22  18 01 f9 00   svc 0x17 -- BC = count, WA = 8
	.long LCD_Svc_Unimplemented		; F8EA26  c6 ea f8 00   svc 0x18
	.long LCD_Svc_19_DrawKatakana16x16	; F8EA2A  8d f2 f8 00   svc 0x19
	.long LCD_Svc_1A_DrawKanjiSetA16x16	; F8EA2E  29 f2 f8 00   svc 0x1A
	.long 0x00F8F8BD			; F8EA32  bd f8 f8 00   svc 0x1B -- drives XIX, compares (0x2532) with (0x2536)
	.long 0x00F9025E			; F8EA36  5e 02 f9 00   svc 0x1C -- BC = count, WA = 16
	.long LCD_Svc_1D_DrawHiragana16x16	; F8EA3A  bf f2 f8 00   svc 0x1D
	.long 0x00F908FF			; F8EA3E  ff 08 f9 00   svc 0x1E -- A = C & 0x0F -- takes a 4-bit argument
	.long LCD_Svc_1F_DrawKanjiSetB16x16	; F8EA42  5b f2 f8 00   svc 0x1F
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
; Evidence: the body is one byte -- 0x0E = RET at 0xF8EAC6, immediately after
;          the table's last slot -- so "do-nothing" is the instruction itself.
;          The 30 slots that point here are counted by
;          notes/swi7_service_table.py, not by hand.
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
; Evidence: the ADDRESS ARITHMETIC is the identification and it is arithmetic,
;          not a guess: display address = Y*AP + X/8 + base, and the bit
;          within the byte is X mod 8 used to index LCD_BitMaskTable, which
;          really holds 80 40 20 10 08 04 02 01 (notes/prom_a_byte_checks.py
;          re-reads all eight). That is a 1-bit-per- pixel, MSB-leftmost
;          framebuffer, which is what the SYSTEM SET in LCD_Init_SED1330
;          programmes. The slot binding is emitted as a symbol in
;          SWI7_ServiceTable, so the byte gate proves slot 0x0B points here.
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
; Evidence: the eight bytes are re-read out of the ROM by
;          notes/prom_a_byte_checks.py ("LCD_BitMaskTable is 80 40 20 10 08 04
;          02 01"). "Leftmost pixel = most significant bit" is a fact about
;          the table TOGETHER with its reader at 0xF8ED7A/0xF8ED7F, which
;          indexes it by X mod 8 -- neither half states it alone.
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
;
;          ★ AND THE LAYER COUNT IS NOW INDEPENDENT OF THE TABLE.  The three
;          entries used to rest on one argument -- that a fourth would overlap
;          service 0x05's first instruction.  `python3 notes/lcd_layer_census.py`
;          censuses every access to (0x2540) in BOTH images and finds 764 sites
;          writing it with an immediate, whose value is 0 at 499 of them, 1 at
;          180 and 2 at 85.  **Never 3, never anything else.**  That is a
;          byte-pattern census and cannot tell code from data, but it does not
;          need to: coincidental matches would spread the immediate over
;          0..255, and this one never exceeds 2.
; Notes:   exactly one of those 764 sites lies inside source this tree has
;          converted -- 0xF8EEBD, the first instruction of LCD_Svc_05_FillRect,
;          written out below as `stdi8 (0x2540), 0x01`.  So at least one hit is
;          confirmed a real instruction at a real boundary, by the byte gate.
;          ★ That site is also a finding in itself: service 0x05 FORCES layer 1
;          before doing anything, so a filled rectangle always lands in SAD2 =
;          0x2600 whatever the caller had selected.
; Unknown:  ⚠ the layers are still not NAMED.  Knowing that 0, 1 and 2 are the
;          only values, and that layer 0 is selected three times as often as
;          layer 2, does not say which is menu, which is keyboard graphics and
;          which is an overlay.  Naming them needs a converted caller, and the
;          callers are in prom_b.
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
; LCD_Svc_16_DrawKatakanaHalfWidth -- SWI7 service 0x16: a string in the
; half-width KATAKANA face, 8 x 14
;
; Called from: SWI7_ServiceTable slot 0x16 (0xF8EA1E)
; Inputs/Outputs: as LCD_Svc_06_DrawText8x14
; Evidence: font base 0xF212B0 (the immediate at 0xF8F0C2), 14 bytes per glyph
;          (`ldw de,0x0e` at 0xF8F0C9), 8 wide (it calls LCD_BlitGlyph8).
;          The table holds exactly 120 cells, and that is arithmetic rather
;          than inspection: the next face begins at 0xF21940 and
;          0xF21940 - 0xF212B0 = 1680 = 120 x 14 exactly, so the tables abut
;          with no padding.  Two blocks of those 120 are defined:
;            0x0F-0x16  eight marks and punctuation.  0x0F is two ticks and
;                       0x10 a small ring at the TOP of the cell -- the voiced
;                       and semi-voiced sound marks, which a half-width face
;                       must carry as separate characters because it has no
;                       room to compose them.  0x11 is the same ring at the
;                       BOTTOM (the full stop) and 0x12 a tick there (the
;                       comma); 0x13 and 0x14 are the two corner brackets;
;                       0x16 is the middle dot.  0x15 is not identified.
;            0x21-0x58  fifty-six kana: the 46 gojuon in dictionary order from
;                       0x21, then the 9 small kana, then the prolonged sound
;                       mark.  46 + 9 + 1 = 56.
;          ★ The LAST cell of that block is the check worth quoting.  Code
;          0x58 is `00 00 00 00 00 7f 00 00 00 00 00 00 00 00` -- one
;          horizontal bar and nothing else, which is the prolonged sound mark,
;          exactly what the reading predicts at the END of the range.
;          Re-derive every number here with
;          `python3 notes/font_layout_check.py`, and look at the glyphs with
;          `python3 notes/font_sheet.py 0xF212B0 14 --range 0x21-0x30`.
;          Written up in notes/FINDINGS-fonts.md.
; Unknown:  ⚠ the ENCODING is private.  The repertoire is JIS X 0201's
;          half-width katakana, but the code points are NOT: JIS puts the wo
;          and the nine small kana BEFORE the gojuon, at 0xA6-0xAF, whereas
;          this face puts the wo inside the gojuon at 0x4D and the small kana
;          after it.  Nothing found so far says what maps a text byte onto
;          these codes.  ⚠ And no caller is traced.
; ---------------------------------------------------------------------
LCD_Svc_16_DrawKatakanaHalfWidth:
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
; LCD_Svc_1A_DrawKanjiSetA16x16 -- SWI7 service 0x1A: a string in the LARGE
; KANJI face, 16 x 16
;
; Called from: SWI7_ServiceTable slot 0x1A (0xF8EA2E)
; Inputs/Outputs: as LCD_Svc_08_DrawText16x16
; Evidence: font base 0xF22840 (immediate at 0xF8F245), 32 bytes per glyph,
;          16 wide.  ★ This table's length is PROVED, not padded-into:
;          0xF22840 + 0xF0 * 32 = 0xF24640, which is the base of the next face
;          exactly, so the table is 240 cells and there is no room for a 241st.
;          Of those, codes 0x10-0xEF -- all 224 -- are defined, with no blank
;          cell anywhere in the run.  The glyphs are multi-stroke CJK
;          ideographs: see them with
;          `python3 notes/font_sheet.py 0xF22840 32 --width 16 --range 0x10-0x17`
;          (code 0x12 is a triangular roof over a bar over a box, i.e. the
;          character read GOU/AU).  That reading is corroborated structurally:
;          the same firmware carries a hiragana face (service 0x1D) and a
;          katakana face (service 0x19) at these same 16x16 metrics, so the two
;          remaining 16x16 faces are the ideographs those two scripts need.
;          Counts re-derived by `python3 notes/font_layout_check.py`.
; Unknown:  ⚠ the ENCODING.  224 contiguous codes from 0x10 match no
;          standard Japanese encoding -- not JIS X 0208, which is two bytes,
;          and not Shift-JIS.  This is a PRIVATE SUBSET: the kanji the UI
;          happens to need, numbered in whatever order they were collected.
;          Nothing in prom_a says which ideograph a given code is, and prom_a
;          cannot say -- the mapping lives in whatever built the strings.
;          "Set A" is this disassembly's label for it, not a name the firmware
;          uses.  ⚠ No caller is traced.
; ---------------------------------------------------------------------
LCD_Svc_1A_DrawKanjiSetA16x16:
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
; LCD_Svc_1F_DrawKanjiSetB16x16 -- SWI7 service 0x1F: a string in the SMALL
; KANJI face, 16 x 16
;
; Called from: SWI7_ServiceTable slot 0x1F (0xF8EA42)
; Inputs/Outputs: as LCD_Svc_08_DrawText16x16
; Evidence: font base 0xF24640 (immediate at 0xF8F277), 32 bytes per glyph,
;          16 wide.  ★ The length is proved by abutment, as for service 0x1A:
;          0xF24640 + 0x3C * 32 = 0xF24DC0, the next face's base exactly, so
;          the table is 60 cells.  43 of them are defined, contiguously,
;          0x10 to 0x3A -- and cell 0x3B, the one blank cell before the next
;          table starts, is the end test.  The glyphs are multi-stroke CJK
;          ideographs at both ends of the range:
;          `python3 notes/font_sheet.py 0xF24640 32 --width 16 --range 0x33-0x3a`
;          shows the last eight, and 0x33 is a box inside a box.
;          Counts re-derived by `python3 notes/font_layout_check.py`.
; Notes:   this face and service 0x1A's share no glyph bitmap at all -- 0 in
;          common out of 43 and 224 -- so they are two DISJOINT ideograph sets,
;          not one set drawn twice.  The same comparison finds 0 shared
;          bitmaps between either of them and any Latin or kana face.
; Unknown:  ⚠ the ENCODING, for the same reason as service 0x1A: 43 contiguous
;          codes from 0x10 are a private subset, and prom_a cannot say which
;          ideograph a code is.  ⚠ Why the firmware keeps TWO disjoint kanji
;          sets rather than one is not established.  "Set B" is this
;          disassembly's label.  ⚠ No caller is traced.
; ---------------------------------------------------------------------
LCD_Svc_1F_DrawKanjiSetB16x16:
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
; LCD_Svc_19_DrawKatakana16x16 -- SWI7 service 0x19: a string in the KATAKANA
; face, 16 x 16
;
; Called from: SWI7_ServiceTable slot 0x19 (0xF8EA2A)
; Inputs/Outputs: as LCD_Svc_08_DrawText16x16
; Evidence: font base 0xF21940 (immediate at 0xF8F2A9), 32 bytes per glyph,
;          16 wide.  The table is exactly 120 cells (0xF22840 - 0xF21940 =
;          3840 = 120 x 32, abutting the next face), of which 87 are defined,
;          contiguously, 0x10 to 0x66.  It is service 0x1D's HIRAGANA face in
;          the same code space and the same order -- 46 gojuon at 0x10-0x3D,
;          9 small kana, the prolonged sound mark at 0x47, 20 voiced and 5
;          semi-voiced forms, then punctuation -- with ONE extra cell at 0x66,
;          a small filled diamond, which the hiragana face leaves blank.
;          86 + 1 = 87.
;          See LCD_Svc_1D_DrawHiragana16x16's header for the six-code
;          cross-check that ties the two faces together, and look at the
;          glyphs with
;          `python3 notes/font_sheet.py 0xF21940 32 --width 16 --range 0x10-0x17`.
;          Counts re-derived by `python3 notes/font_layout_check.py`.
; Unknown:  ⚠ the ENCODING is private.  ⚠ Why the katakana face alone carries
;          the 0x66 diamond is not established.  ⚠ No caller is traced.
; ---------------------------------------------------------------------
LCD_Svc_19_DrawKatakana16x16:
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
; LCD_Svc_1D_DrawHiragana16x16 -- SWI7 service 0x1D: a string in the HIRAGANA
; face, 16 x 16
;
; Called from: SWI7_ServiceTable slot 0x1D (0xF8EA3A)
; Inputs/Outputs: as LCD_Svc_08_DrawText16x16
; Evidence: font base 0xF203B0 (immediate at 0xF8F2DB), 32 bytes per glyph,
;          16 wide.  The table is exactly 120 cells -- 0xF212B0 - 0xF203B0 =
;          3840 = 120 x 32, abutting the next face -- of which 86 are defined,
;          contiguously, 0x10 to 0x65.  ★ That 86 is not a bare count: it is
;          the hiragana repertoire added up, and every term lands where the
;          reading says it should.
;            0x10-0x3D   46  the gojuon, A I U E O KA KI ... WA WO N
;            0x3E-0x46    9  the small kana
;            0x47         1  the prolonged sound mark
;            0x48-0x5B   20  the voiced (dakuten) forms, GA GI GU ... BO
;            0x5C-0x60    5  the semi-voiced (handakuten) forms, PA ... PO
;            0x61-0x65    5  full stop, comma, the two corner brackets, wave
;                            dash
;          46 + 9 + 1 + 20 + 5 + 5 = 86.
;          ★ THE CROSS-CHECK.  Service 0x19's katakana face uses the SAME code
;          space, and six of its cells hold bitmaps byte-identical to this
;          one's: 0x47 and 0x61-0x65 -- precisely the six characters in the
;          table above that belong to neither script.  Every other code the two
;          faces both define differs.  notes/font_layout_check.py finds those
;          six by comparing bitmaps, knowing nothing about kana, and asserts it
;          got exactly that set; the layout above predicts them from the
;          repertoire alone.  Two independent routes, same six codes.
;          Look at the glyphs with
;          `python3 notes/font_sheet.py 0xF203B0 32 --width 16 --range 0x10-0x17`.
; Unknown:  ⚠ the ENCODING is private: the order is the Japanese dictionary
;          order but the code points are nobody's standard.  ⚠ No caller is
;          traced, so nothing here says which script the UI uses when.
; ---------------------------------------------------------------------
LCD_Svc_1D_DrawHiragana16x16:
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
; Evidence: notes/prom_a_byte_checks.py re-reads these nine bytes from the ROM
;          twice over, once as the literal sequence ("left mask table: 00 7f
;          3f 1f 0f 07 03 01 00") and once as the RULE ("left mask table:
;          entries 1..7 are 0xFF >> k") -- two independent statements of the
;          same nine bytes, so a typo in either fails. The COUNT argument is
;          in the Count: field above and rests on two addresses the byte gate
;          holds.
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
; Evidence: same shape as the other table and checked the same way --
;          notes/prom_a_byte_checks.py asserts both the literal ("right mask
;          table: 00 80 c0 e0 f0 f8 fc fe 00") and the rule ("entries 1..7 are
;          0xFF << (8-k)"). The same script also finds where this table is
;          DUPLICATED elsewhere in the image ("0xF8F7AF, 0xF8FE77 are byte-
;          identical (9 of 9)").
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
; Evidence: "flashing" is the FIELD VALUE, read off the code -- each selected
;          layer's two-bit field in (0x2559) is forced to 10 by `and A,0xF3 /
;          or A,0x08` at 0xF8F80A/0xF8F80D for layer 1, and by the same pair
;          of instructions with the other field's masks for layers 2 and 3 --
;          and 10 is "flash at fFR/32" in the SED1330 DISP ON parameter that
;          (0x2559) shadows (notes/FINDINGS-display-controller.md). "Modify,
;          not rebuild" is that each arm is guarded by its own `bit n,C` and
;          leaves the other fields untouched.
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

; ==============================================================================
; 0xF8F850-0xF90117 -- SWI7 services 0x0E 0x1B 0x0F 0x10 0x11 0x12 0x14 0x15:
; the ERASE family, the two PANEL MODES, and the three PATTERNED primitives
; ==============================================================================
;
; Everything here is a variant of a service that is already converted above, and
; each header below says which one and what the variation is.  Three groups:
;
;  * ERASE.  Services 0x0E and 0x1B write ZERO where 0x03 and 0x05 write the
;    caller's data and 0xFF.  0x1B does it as a read-modify-write with the
;    COMPLEMENT of the same two edge masks the fill uses, so the pixels outside
;    the box survive.
;
;  * PANEL MODE.  ★ Services 0x0F and 0x10 re-run the whole power-on sequence of
;    LCD_Init_SED1330 -- SYSTEM SET, SCROLL, OVLAY, clear, DISP ON -- with
;    DIFFERENT layer geometry.  0x10 restores the three-layer arrangement the
;    power-on setup programmes; 0x0F switches the panel to a TWO-layer one whose
;    second layer is at display-RAM 0x4000.  So the WSA1's display has two
;    modes, and the firmware can switch between them at runtime.
;
;  * PATTERN.  Services 0x11, 0x12 and 0x15 draw with a fixed 2-on-2-off dither
;    (0xCC horizontally, a modulo-4 counter vertically); service 0x14 fills a
;    box with an EIGHT-BYTE pattern the caller leaves in RAM at (0x2538).
;
; ⚠ NEW RAM ESTABLISHED BY THIS BLOCK, beyond the map in the display-controller
;   note:
;     (0x2538)-(0x253F)  the caller's 8 x 8 fill pattern, one byte per row,
;                        read by service 0x14 only
;     (0x2558)           APH, the high byte of AP -- services 0x0F and 0x10
;                        write 0x28 to (0x2557) and 0x00 to (0x2558), so the
;                        16-bit word at (0x2557) that the plotter multiplies Y
;                        by is AP = 40, spelled out one byte at a time
;     (0x255E)           the current pattern byte, in services 0x11 and 0x14.
;                        ⚠ THE SAME WORD IS SERVICES 0x0A/0x22's SAVED Y0.  Two
;                        unrelated uses of one address; they do not overlap in
;                        time because 0x0A/0x22 call only the SOLID line pair.

; ---------------------------------------------------------------------
; LCD_Svc_0E_ClearColumns -- SWI7 service 0x0E: zero a rectangle, column-major
;
; Called from: SWI7_ServiceTable slot 0x0E (0xF8E9FE)
; Inputs:  IY = byte offset of the top-left corner WITHIN the current layer;
;          BC = number of columns; HL = bytes down each column.  (0x2540)
;          selects the layer.  ⚠ The offset is in IY, not IX as in service
;          0x03 -- `dd 88 ld WA,IY` here against `dc 88 ld WA,IX` at 0xF8EDD1.
; Outputs: BC*HL display bytes set to 0x00.  WA, BC, E clobbered.  Returns
;          immediately if BC or HL is zero.
; Evidence: it is service 0x03 with the source pointer removed.  109 bytes here
;           against 0x03's 111; the two differences are that 0x03's inner body
;           is `ld E,(XIY)` + `inc 1,XIY` (4 bytes) reading the caller's buffer,
;           where this one hoists a single `ld E,0x00` (2 bytes) out of the loop
;           and writes that constant every time -- 111 - 4 + 2 = 109.  Same
;           CSRDIR DOWN (0x4F), same CSRW/MWRITE per column, same
;           `add WA,(0x2555)` to turn the offset into a display address.
;           The arithmetic and the two byte counts are checked by
;           notes/prom_a_byte_checks.py.
; Unknown:  callers.  Nothing in prom_a or prom_b is known to invoke it other
;           than through the SWI7 table.
; ---------------------------------------------------------------------
LCD_Svc_0E_ClearColumns:
	calr (0xF8EE93 - 0xF8F853)                                   ; F8F850  1e 40 f6
	ld XIX,0x00790000                             ; F8F853  44 00 00 79 00
	bit_dd8 0x00, 0xc6                            ; F8F858  f0 c6 c8
	jr nz, .LF8F861                               ; F8F85B  6e 04
.LF8F85D:
	bit 6,(XIX)                                   ; F8F85D  b4 ce
	jr nz, .LF8F85D                               ; F8F85F  6e fc
.LF8F861:
	ld (XIX+0x01),0x4f                            ; F8F861  bc 01 00 4f
	and BC,BC                                     ; F8F865  d9 c1
	jr z, .LF8F8BC                                ; F8F867  66 53
	and HL,HL                                     ; F8F869  db c3
	jr z, .LF8F8BC                                ; F8F86B  66 4f
	ld WA,IY                                      ; F8F86D  dd 88
	m_add_rm MW16, 0x2555, r0                     ; F8F86F  d1 55 25 80
	ldb e, 0x00                                   ; F8F873  25 00
.LF8F875:
	bit_dd8 0x00, 0xc6                            ; F8F875  f0 c6 c8
	jr nz, .LF8F87E                               ; F8F878  6e 04
.LF8F87A:
	bit 6,(XIX)                                   ; F8F87A  b4 ce
	jr nz, .LF8F87A                               ; F8F87C  6e fc
.LF8F87E:
	ld (XIX+0x01),0x46                            ; F8F87E  bc 01 00 46
	bit_dd8 0x00, 0xc6                            ; F8F882  f0 c6 c8
	jr nz, .LF8F88B                               ; F8F885  6e 04
.LF8F887:
	bit 6,(XIX)                                   ; F8F887  b4 ce
	jr nz, .LF8F887                               ; F8F889  6e fc
.LF8F88B:
	ld (XIX),A                                    ; F8F88B  b4 41
	bit_dd8 0x00, 0xc6                            ; F8F88D  f0 c6 c8
	jr nz, .LF8F896                               ; F8F890  6e 04
.LF8F892:
	bit 6,(XIX)                                   ; F8F892  b4 ce
	jr nz, .LF8F892                               ; F8F894  6e fc
.LF8F896:
	ld (XIX),W                                    ; F8F896  b4 40
	bit_dd8 0x00, 0xc6                            ; F8F898  f0 c6 c8
	jr nz, .LF8F8A1                               ; F8F89B  6e 04
.LF8F89D:
	bit 6,(XIX)                                   ; F8F89D  b4 ce
	jr nz, .LF8F89D                               ; F8F89F  6e fc
.LF8F8A1:
	ld (XIX+0x01),0x42                            ; F8F8A1  bc 01 00 42
	pushw bc                                      ; F8F8A5  29
	ld BC,HL                                      ; F8F8A6  db 89
.LF8F8A8:
	bit_dd8 0x00, 0xc6                            ; F8F8A8  f0 c6 c8
	jr nz, .LF8F8B1                               ; F8F8AB  6e 04
.LF8F8AD:
	bit 6,(XIX)                                   ; F8F8AD  b4 ce
	jr nz, .LF8F8AD                               ; F8F8AF  6e fc
.LF8F8B1:
	ld (XIX),E                                    ; F8F8B1  b4 45
	djnz16 bc, .LF8F8A8                           ; F8F8B3  d9 1c f2
	popw bc                                       ; F8F8B6  49
	inc 1,WA                                      ; F8F8B7  d8 61
	djnz16 bc, .LF8F875                           ; F8F8B9  d9 1c b9
.LF8F8BC:
	ret                                           ; F8F8BC  0e

; ---------------------------------------------------------------------
; LCD_Svc_1B_EraseRect -- SWI7 service 0x1B: clear the box between (X0,Y0) and (X1,Y1)
;
; Called from: SWI7_ServiceTable slot 0x1B (0xF8EA32)
; Inputs:  the same four coordinate words as the fill and the line draw --
;          (0x2530),(0x2532) = (X0,Y0), (0x2534),(0x2536) = (X1,Y1); (0x2540)
;          selects the layer.
; Outputs: every pixel of the box CLEARED in the current layer, and nothing
;          outside it touched.  (0x2532) is left one past Y1 -- the routine
;          walks Y by incrementing that word in place -- and (0x255A) holds the
;          last cursor address written.  WA, BC, DE, HL, XIX clobbered.
; Evidence: it is the erase counterpart of LCD_Svc_05_FillRect and of
;          LCD_Svc_01_DrawHLine, and three things say so rather than one:
;          1. it calls the SAME two edge-mask helpers, LCD_Rect_LeftEdgeMask
;             (0xF8F767, from 0xF8F926) and LCD_Rect_RightEdgeMask (0xF8F7A4,
;             from 0xF8FA0F), and follows each with `xor A,0xff` before ANDing
;             the mask into the byte it just MREAD -- fill ORs the mask in, this
;             ANDs the complement, which clears exactly those pixels;
;          2. the whole byte-columns between the two ragged ends are written as
;             0x00, where the fill writes 0xFF;
;          3. the address arithmetic is LCD_PlotPointAt's, Y*(0x2557) + X/8 +
;             (0x2555), recomputed for every row, and the cursor advances with
;             CSRDIR RIGHT (0x4C), so it erases one scan line per pass and loops
;             on `incw 1,(0x2532)` until (0x2532) > (0x2536).
; ⚠ Differences from service 0x05 that are NOT cosmetic: this one does NOT call
;          LCD_ClampCoordsToPanel, does NOT force (0x2540), and does NOT touch
;          the OVLAY register.  It erases in whatever layer the caller selected,
;          with whatever composition mode is already programmed, and an
;          out-of-range coordinate is the caller's problem.
; Unknown:  callers.
; ---------------------------------------------------------------------
LCD_Svc_1B_EraseRect:
	calr (0xF8EE93 - 0xF8F8C0)                                   ; F8F8BD  1e d3 f5
	ld XIX,0x00790000                             ; F8F8C0  44 00 00 79 00
.LF8F8C5:
	ldw_d16 wa, (0x2536)                          ; F8F8C5  d1 36 25 20
	m_cp_mr MW16, 0x2532, r0                      ; F8F8C9  d1 32 25 f8
	jrl ugt, .LF8FA5F                             ; F8F8CD  7b 8f 01
	ldw_d16 wa, (0x2532)                          ; F8F8D0  d1 32 25 20
	ldw_d16 bc, (0x2557)                          ; F8F8D4  d1 57 25 21
	mul xwa, xbc                                  ; F8F8D8  d9 40
	ld HL,WA                                      ; F8F8DA  d8 8b
	ldw_d16 wa, (0x2530)                          ; F8F8DC  d1 30 25 20
	ldw bc, 0x08                                  ; F8F8E0  31 08 00
	extz XWA                                      ; F8F8E3  e8 12
	div xwa, xbc                                  ; F8F8E5  d9 50
	ld DE,QWA                                     ; F8F8E7  d7 e2 8a
	add HL,WA                                     ; F8F8EA  d8 83
	ldw_d16 wa, (0x2555)                          ; F8F8EC  d1 55 25 20
	add WA,HL                                     ; F8F8F0  db 80
	bit_dd8 0x00, 0xc6                            ; F8F8F2  f0 c6 c8
	jr nz, .LF8F8FB                               ; F8F8F5  6e 04
.LF8F8F7:
	bit 6,(XIX)                                   ; F8F8F7  b4 ce
	jr nz, .LF8F8F7                               ; F8F8F9  6e fc
.LF8F8FB:
	ld (XIX+0x01),0x4c                            ; F8F8FB  bc 01 00 4c
	bit_dd8 0x00, 0xc6                            ; F8F8FF  f0 c6 c8
	jr nz, .LF8F908                               ; F8F902  6e 04
.LF8F904:
	bit 6,(XIX)                                   ; F8F904  b4 ce
	jr nz, .LF8F904                               ; F8F906  6e fc
.LF8F908:
	ld (XIX+0x01),0x46                            ; F8F908  bc 01 00 46
	stda16 (0x255a), wa                           ; F8F90C  f1 5a 25 50
	bit_dd8 0x00, 0xc6                            ; F8F910  f0 c6 c8
	jr nz, .LF8F919                               ; F8F913  6e 04
.LF8F915:
	bit 6,(XIX)                                   ; F8F915  b4 ce
	jr nz, .LF8F915                               ; F8F917  6e fc
.LF8F919:
	ld (XIX),A                                    ; F8F919  b4 41
	bit_dd8 0x00, 0xc6                            ; F8F91B  f0 c6 c8
	jr nz, .LF8F924                               ; F8F91E  6e 04
.LF8F920:
	bit 6,(XIX)                                   ; F8F920  b4 ce
	jr nz, .LF8F920                               ; F8F922  6e fc
.LF8F924:
	ld (XIX),W                                    ; F8F924  b4 40
	calr (0xF8F767 - 0xF8F929)                                   ; F8F926  1e 3e fe
	xor A,0xff                                    ; F8F929  c9 cd ff
	and DE,DE                                     ; F8F92C  da c2
	jr z, .LF8F98A                                ; F8F92E  66 5a
	ld (XIX+0x01),0x43                            ; F8F930  bc 01 00 43
	bit_dd8 0x00, 0xc6                            ; F8F934  f0 c6 c8
	jr nz, .LF8F93D                               ; F8F937  6e 04
.LF8F939:
	bit 6,(XIX)                                   ; F8F939  b4 ce
	jr nz, .LF8F939                               ; F8F93B  6e fc
.LF8F93D:
	ld W,(XIX+0x01)                               ; F8F93D  8c 01 20
	and W,A                                       ; F8F940  c9 c0
	ld C,W                                        ; F8F942  c8 8b
	bit_dd8 0x00, 0xc6                            ; F8F944  f0 c6 c8
	jr nz, .LF8F94D                               ; F8F947  6e 04
.LF8F949:
	bit 6,(XIX)                                   ; F8F949  b4 ce
	jr nz, .LF8F949                               ; F8F94B  6e fc
.LF8F94D:
	ld (XIX+0x01),0x46                            ; F8F94D  bc 01 00 46
	ldw_d16 wa, (0x255a)                          ; F8F951  d1 5a 25 20
	bit_dd8 0x00, 0xc6                            ; F8F955  f0 c6 c8
	jr nz, .LF8F95E                               ; F8F958  6e 04
.LF8F95A:
	bit 6,(XIX)                                   ; F8F95A  b4 ce
	jr nz, .LF8F95A                               ; F8F95C  6e fc
.LF8F95E:
	ld (XIX),A                                    ; F8F95E  b4 41
	bit_dd8 0x00, 0xc6                            ; F8F960  f0 c6 c8
	jr nz, .LF8F969                               ; F8F963  6e 04
.LF8F965:
	bit 6,(XIX)                                   ; F8F965  b4 ce
	jr nz, .LF8F965                               ; F8F967  6e fc
.LF8F969:
	ld (XIX),W                                    ; F8F969  b4 40
	bit_dd8 0x00, 0xc6                            ; F8F96B  f0 c6 c8
	jr nz, .LF8F974                               ; F8F96E  6e 04
.LF8F970:
	bit 6,(XIX)                                   ; F8F970  b4 ce
	jr nz, .LF8F970                               ; F8F972  6e fc
.LF8F974:
	ld (XIX+0x01),0x42                            ; F8F974  bc 01 00 42
	bit_dd8 0x00, 0xc6                            ; F8F978  f0 c6 c8
	jr nz, .LF8F981                               ; F8F97B  6e 04
.LF8F97D:
	bit 6,(XIX)                                   ; F8F97D  b4 ce
	jr nz, .LF8F97D                               ; F8F97F  6e fc
.LF8F981:
	ld (XIX),C                                    ; F8F981  b4 43
	ldw hl, 0x08                                  ; F8F983  33 08 00
	sub HL,DE                                     ; F8F986  da a3
	ex16 hl, de                                   ; F8F988  da bb
.LF8F98A:
	ldw_d16 wa, (0x2534)                          ; F8F98A  d1 34 25 20
	m_sub_rm MW16, 0x2530, r0                     ; F8F98E  d1 30 25 a0
	inc 1,WA                                      ; F8F992  d8 61
	cp WA,DE                                      ; F8F994  da f0
	jrl ule, .LF8FA58                             ; F8F996  73 bf 00
	sub WA,DE                                     ; F8F999  da a0
	ldw bc, 0x08                                  ; F8F99B  31 08 00
	extz XWA                                      ; F8F99E  e8 12
	div xwa, xbc                                  ; F8F9A0  d9 50
	ld DE,QWA                                     ; F8F9A2  d7 e2 8a
	and WA,WA                                     ; F8F9A5  d8 c0
	jr z, .LF8F9C8                                ; F8F9A7  66 1f
	ld BC,WA                                      ; F8F9A9  d8 89
	bit_dd8 0x00, 0xc6                            ; F8F9AB  f0 c6 c8
	jr nz, .LF8F9B4                               ; F8F9AE  6e 04
.LF8F9B0:
	bit 6,(XIX)                                   ; F8F9B0  b4 ce
	jr nz, .LF8F9B0                               ; F8F9B2  6e fc
.LF8F9B4:
	ld (XIX+0x01),0x42                            ; F8F9B4  bc 01 00 42
	ldb a, 0x00                                   ; F8F9B8  21 00
.LF8F9BA:
	bit_dd8 0x00, 0xc6                            ; F8F9BA  f0 c6 c8
	jr nz, .LF8F9C3                               ; F8F9BD  6e 04
.LF8F9BF:
	bit 6,(XIX)                                   ; F8F9BF  b4 ce
	jr nz, .LF8F9BF                               ; F8F9C1  6e fc
.LF8F9C3:
	ld (XIX),A                                    ; F8F9C3  b4 41
	djnz16 bc, .LF8F9BA                           ; F8F9C5  d9 1c f2
.LF8F9C8:
	and DE,DE                                     ; F8F9C8  da c2
	jrl z, .LF8FA58                               ; F8F9CA  76 8b 00
	bit_dd8 0x00, 0xc6                            ; F8F9CD  f0 c6 c8
	jr nz, .LF8F9D6                               ; F8F9D0  6e 04
.LF8F9D2:
	bit 6,(XIX)                                   ; F8F9D2  b4 ce
	jr nz, .LF8F9D2                               ; F8F9D4  6e fc
.LF8F9D6:
	ld (XIX+0x01),0x47                            ; F8F9D6  bc 01 00 47
	bit_dd8 0x00, 0xc6                            ; F8F9DA  f0 c6 c8
	jr nz, .LF8F9E3                               ; F8F9DD  6e 04
.LF8F9DF:
	bit 6,(XIX)                                   ; F8F9DF  b4 ce
	jr nz, .LF8F9DF                               ; F8F9E1  6e fc
.LF8F9E3:
	ld A,(XIX+0x01)                               ; F8F9E3  8c 01 21
	bit_dd8 0x00, 0xc6                            ; F8F9E6  f0 c6 c8
	jr nz, .LF8F9EF                               ; F8F9E9  6e 04
.LF8F9EB:
	bit 6,(XIX)                                   ; F8F9EB  b4 ce
	jr nz, .LF8F9EB                               ; F8F9ED  6e fc
.LF8F9EF:
	ld W,(XIX+0x01)                               ; F8F9EF  8c 01 20
	stda16 (0x255a), wa                           ; F8F9F2  f1 5a 25 50
	bit_dd8 0x00, 0xc6                            ; F8F9F6  f0 c6 c8
	jr nz, .LF8F9FF                               ; F8F9F9  6e 04
.LF8F9FB:
	bit 6,(XIX)                                   ; F8F9FB  b4 ce
	jr nz, .LF8F9FB                               ; F8F9FD  6e fc
.LF8F9FF:
	ld (XIX+0x01),0x43                            ; F8F9FF  bc 01 00 43
	bit_dd8 0x00, 0xc6                            ; F8FA03  f0 c6 c8
	jr nz, .LF8FA0C                               ; F8FA06  6e 04
.LF8FA08:
	bit 6,(XIX)                                   ; F8FA08  b4 ce
	jr nz, .LF8FA08                               ; F8FA0A  6e fc
.LF8FA0C:
	ld W,(XIX+0x01)                               ; F8FA0C  8c 01 20
	calr (0xF8F7A4 - 0xF8FA12)                                   ; F8FA0F  1e 92 fd
	xor A,0xff                                    ; F8FA12  c9 cd ff
	and W,A                                       ; F8FA15  c9 c0
	ld C,W                                        ; F8FA17  c8 8b
	bit_dd8 0x00, 0xc6                            ; F8FA19  f0 c6 c8
	jr nz, .LF8FA22                               ; F8FA1C  6e 04
.LF8FA1E:
	bit 6,(XIX)                                   ; F8FA1E  b4 ce
	jr nz, .LF8FA1E                               ; F8FA20  6e fc
.LF8FA22:
	ld (XIX+0x01),0x46                            ; F8FA22  bc 01 00 46
	ldw_d16 wa, (0x255a)                          ; F8FA26  d1 5a 25 20
	bit_dd8 0x00, 0xc6                            ; F8FA2A  f0 c6 c8
	jr nz, .LF8FA33                               ; F8FA2D  6e 04
.LF8FA2F:
	bit 6,(XIX)                                   ; F8FA2F  b4 ce
	jr nz, .LF8FA2F                               ; F8FA31  6e fc
.LF8FA33:
	ld (XIX),A                                    ; F8FA33  b4 41
	bit_dd8 0x00, 0xc6                            ; F8FA35  f0 c6 c8
	jr nz, .LF8FA3E                               ; F8FA38  6e 04
.LF8FA3A:
	bit 6,(XIX)                                   ; F8FA3A  b4 ce
	jr nz, .LF8FA3A                               ; F8FA3C  6e fc
.LF8FA3E:
	ld (XIX),W                                    ; F8FA3E  b4 40
	bit_dd8 0x00, 0xc6                            ; F8FA40  f0 c6 c8
	jr nz, .LF8FA49                               ; F8FA43  6e 04
.LF8FA45:
	bit 6,(XIX)                                   ; F8FA45  b4 ce
	jr nz, .LF8FA45                               ; F8FA47  6e fc
.LF8FA49:
	ld (XIX+0x01),0x42                            ; F8FA49  bc 01 00 42
	bit_dd8 0x00, 0xc6                            ; F8FA4D  f0 c6 c8
	jr nz, .LF8FA56                               ; F8FA50  6e 04
.LF8FA52:
	bit 6,(XIX)                                   ; F8FA52  b4 ce
	jr nz, .LF8FA52                               ; F8FA54  6e fc
.LF8FA56:
	ld (XIX),C                                    ; F8FA56  b4 43
.LF8FA58:
	incdi16 0x01, (0x2532)                        ; F8FA58  d1 32 25 61
	jrl .LF8F8C5                                  ; F8FA5C  78 66 fe
.LF8FA5F:
	ret                                           ; F8FA5F  0e

; ---------------------------------------------------------------------
; LCD_Svc_0F_SetPanel2Layer -- SWI7 service 0x0F: reprogramme the panel with
; TWO composed layers
;
; Called from: SWI7_ServiceTable slot 0x0F (0xF8EA02)
; Inputs:  none
; Outputs: the controller re-initialised: SYSTEM SET with the same geometry as
;          the power-on setup, SCROLL with only SIX parameter bytes (SAD1 =
;          0x0000, SL1 = 240, SAD2 = 0x4000, SL2 = 240 -- no SAD3), OVLAY 0x0C,
;          DISP OFF, CSRDIR RIGHT, CSRW 0x0000, MWRITE and 0x0658 * 16 = 25984
;          zero bytes, then DISP ON.  (0x2557)/(0x2558) = AP = 0x0028;
;          (0x2541) = 0x0000; (0x2543) = 0x4000; (0x2554) = 0x0C.
;          WA, BC and XIY clobbered.
; Evidence: OVLAY 0x0C is what makes this the TWO-layer mode, and it is decoded
;          rather than guessed: MAME's sed1330_device splits the OVLAY byte as
;          MX = bits[1:0], DM1 = bit 2, DM2 = bit 3, OV = bit 4
;          (../mame/src/devices/video/sed1330.cpp:546-561, which logs bit 4 as
;          "Display Composition Layers: 3 or 2").  0x0C = MX 0 (OR), DM1 and DM2
;          both GRAPHICS, **OV = 0 -> two layers**, against the 0x1C that
;          LCD_Init_SED1330 and service 0x10 send, whose OV = 1 -> three.
;          The SCROLL parameter count agrees independently: six bytes here,
;          eight there, and six is exactly SAD1/SL1/SAD2/SL2 with SAD3 omitted.
;          So does the clear count: 240 lines * 40 bytes = 0x2580 per layer, the
;          higher layer is based at 0x4000, and 0x4000 + 0x2580 = 0x6580 = the
;          25984 bytes this routine zeroes -- it clears display RAM up to the
;          end of the LAST layer and no further.  (Service 0x10's count is
;          0x7180 = 0x4C00 + 0x2580 by the same arithmetic; the power-on setup,
;          which cannot assume either layout, zeroes all 32768.)
; Notes:   like LCD_Init_SED1330 it never polls BUSY -- runs of NOPs separate the
;          accesses instead.  Unlike the power-on setup it sends no HDOT SCR and
;          no CSRFORM, and its DISP OFF and DISP ON carry NO parameter byte, so
;          the controller keeps whatever layer-visibility byte services 0x0C and
;          0x0D last programmed and (0x2559) stays valid.
; ⚠ Unknown, and it matters: (0x2545) -- firmware layer 2's base -- is NOT
;          updated here, because the two-layer arrangement has no third layer.
;          A drawing service called with (0x2540) = 2 after this one runs will
;          therefore aim at whatever base was left over from the three-layer
;          mode.  Whether the UI ever does that is not traced.
; ⚠ Also unknown: which of the two modes the instrument actually runs in, and
;          what switches it.  No caller of either service is traced.
; ---------------------------------------------------------------------
LCD_Svc_0F_SetPanel2Layer:
	ld XIY,0x00790000                             ; F8FA60  45 00 00 79 00
	ld (XIY+0x01),0x40                            ; F8FA65  bd 01 00 40
	nop                                           ; F8FA69  00
	nop                                           ; F8FA6A  00
	nop                                           ; F8FA6B  00
	nop                                           ; F8FA6C  00
	ld (XIY),0x30                                 ; F8FA6D  b5 00 30
	nop                                           ; F8FA70  00
	nop                                           ; F8FA71  00
	nop                                           ; F8FA72  00
	nop                                           ; F8FA73  00
	ld (XIY),0x07                                 ; F8FA74  b5 00 07
	nop                                           ; F8FA77  00
	nop                                           ; F8FA78  00
	nop                                           ; F8FA79  00
	nop                                           ; F8FA7A  00
	ld (XIY),0x00                                 ; F8FA7B  b5 00 00
	nop                                           ; F8FA7E  00
	nop                                           ; F8FA7F  00
	nop                                           ; F8FA80  00
	nop                                           ; F8FA81  00
	ld (XIY),0x27                                 ; F8FA82  b5 00 27
	nop                                           ; F8FA85  00
	nop                                           ; F8FA86  00
	nop                                           ; F8FA87  00
	nop                                           ; F8FA88  00
	ld (XIY),0x35                                 ; F8FA89  b5 00 35
	nop                                           ; F8FA8C  00
	nop                                           ; F8FA8D  00
	nop                                           ; F8FA8E  00
	nop                                           ; F8FA8F  00
	ld (XIY),0xef                                 ; F8FA90  b5 00 ef
	ldb a, 0x28                                   ; F8FA93  21 28
	ld (XIY),A                                    ; F8FA95  b5 41
	stb_d8 (0x2557), a                            ; F8FA97  f1 57 25 41
	nop                                           ; F8FA9B  00
	nop                                           ; F8FA9C  00
	ldb a, 0x00                                   ; F8FA9D  21 00
	ld (XIY),A                                    ; F8FA9F  b5 41
	stb_d8 (0x2558), a                            ; F8FAA1  f1 58 25 41
	nop                                           ; F8FAA5  00
	nop                                           ; F8FAA6  00
	ld (XIY+0x01),0x44                            ; F8FAA7  bd 01 00 44
	nop                                           ; F8FAAB  00
	nop                                           ; F8FAAC  00
	nop                                           ; F8FAAD  00
	nop                                           ; F8FAAE  00
	ld (XIY),0x00                                 ; F8FAAF  b5 00 00
	nop                                           ; F8FAB2  00
	nop                                           ; F8FAB3  00
	nop                                           ; F8FAB4  00
	nop                                           ; F8FAB5  00
	ld (XIY),0x00                                 ; F8FAB6  b5 00 00
	nop                                           ; F8FAB9  00
	nop                                           ; F8FABA  00
	nop                                           ; F8FABB  00
	nop                                           ; F8FABC  00
	ld (XIY),0xf0                                 ; F8FABD  b5 00 f0
	nop                                           ; F8FAC0  00
	nop                                           ; F8FAC1  00
	nop                                           ; F8FAC2  00
	nop                                           ; F8FAC3  00
	ld (XIY),0x00                                 ; F8FAC4  b5 00 00
	nop                                           ; F8FAC7  00
	nop                                           ; F8FAC8  00
	nop                                           ; F8FAC9  00
	nop                                           ; F8FACA  00
	ld (XIY),0x40                                 ; F8FACB  b5 00 40
	nop                                           ; F8FACE  00
	nop                                           ; F8FACF  00
	nop                                           ; F8FAD0  00
	nop                                           ; F8FAD1  00
	ld (XIY),0xf0                                 ; F8FAD2  b5 00 f0
	ldb a, 0x00                                   ; F8FAD5  21 00
	ldb w, 0x00                                   ; F8FAD7  20 00
	stda16 (0x2541), wa                           ; F8FAD9  f1 41 25 50
	ldb a, 0x00                                   ; F8FADD  21 00
	ldb w, 0x40                                   ; F8FADF  20 40
	stda16 (0x2543), wa                           ; F8FAE1  f1 43 25 50
	ld (XIY+0x01),0x5b                            ; F8FAE5  bd 01 00 5b
	nop                                           ; F8FAE9  00
	nop                                           ; F8FAEA  00
	nop                                           ; F8FAEB  00
	ld (XIY),0x0c                                 ; F8FAEC  b5 00 0c
	stdi8 (0x2554), 0x0c                          ; F8FAEF  f1 54 25 00 0c
	nop                                           ; F8FAF4  00
	nop                                           ; F8FAF5  00
	nop                                           ; F8FAF6  00
	ld (XIY+0x01),0x58                            ; F8FAF7  bd 01 00 58
	nop                                           ; F8FAFB  00
	nop                                           ; F8FAFC  00
	nop                                           ; F8FAFD  00
	nop                                           ; F8FAFE  00
	ld (XIY+0x01),0x4c                            ; F8FAFF  bd 01 00 4c
	nop                                           ; F8FB03  00
	nop                                           ; F8FB04  00
	nop                                           ; F8FB05  00
	nop                                           ; F8FB06  00
	ld (XIY+0x01),0x46                            ; F8FB07  bd 01 00 46
	xor WA,WA                                     ; F8FB0B  d8 d0
	nop                                           ; F8FB0D  00
	nop                                           ; F8FB0E  00
	nop                                           ; F8FB0F  00
	nop                                           ; F8FB10  00
	ld (XIY),W                                    ; F8FB11  b5 40
	nop                                           ; F8FB13  00
	nop                                           ; F8FB14  00
	nop                                           ; F8FB15  00
	nop                                           ; F8FB16  00
	ld (XIY),A                                    ; F8FB17  b5 41
	nop                                           ; F8FB19  00
	nop                                           ; F8FB1A  00
	nop                                           ; F8FB1B  00
	ld (XIY+0x01),0x42                            ; F8FB1C  bd 01 00 42
	ldw bc, 0x0658                                ; F8FB20  31 58 06
.LF8FB23:
	nop                                           ; F8FB23  00
	nop                                           ; F8FB24  00
	nop                                           ; F8FB25  00
	ld (XIY),A                                    ; F8FB26  b5 41
	nop                                           ; F8FB28  00
	nop                                           ; F8FB29  00
	nop                                           ; F8FB2A  00
	ld (XIY),A                                    ; F8FB2B  b5 41
	nop                                           ; F8FB2D  00
	nop                                           ; F8FB2E  00
	nop                                           ; F8FB2F  00
	ld (XIY),A                                    ; F8FB30  b5 41
	nop                                           ; F8FB32  00
	nop                                           ; F8FB33  00
	nop                                           ; F8FB34  00
	ld (XIY),A                                    ; F8FB35  b5 41
	nop                                           ; F8FB37  00
	nop                                           ; F8FB38  00
	nop                                           ; F8FB39  00
	ld (XIY),A                                    ; F8FB3A  b5 41
	nop                                           ; F8FB3C  00
	nop                                           ; F8FB3D  00
	nop                                           ; F8FB3E  00
	ld (XIY),A                                    ; F8FB3F  b5 41
	nop                                           ; F8FB41  00
	nop                                           ; F8FB42  00
	nop                                           ; F8FB43  00
	ld (XIY),A                                    ; F8FB44  b5 41
	nop                                           ; F8FB46  00
	nop                                           ; F8FB47  00
	nop                                           ; F8FB48  00
	ld (XIY),A                                    ; F8FB49  b5 41
	nop                                           ; F8FB4B  00
	nop                                           ; F8FB4C  00
	nop                                           ; F8FB4D  00
	ld (XIY),A                                    ; F8FB4E  b5 41
	nop                                           ; F8FB50  00
	nop                                           ; F8FB51  00
	nop                                           ; F8FB52  00
	ld (XIY),A                                    ; F8FB53  b5 41
	nop                                           ; F8FB55  00
	nop                                           ; F8FB56  00
	nop                                           ; F8FB57  00
	ld (XIY),A                                    ; F8FB58  b5 41
	nop                                           ; F8FB5A  00
	nop                                           ; F8FB5B  00
	nop                                           ; F8FB5C  00
	ld (XIY),A                                    ; F8FB5D  b5 41
	nop                                           ; F8FB5F  00
	nop                                           ; F8FB60  00
	nop                                           ; F8FB61  00
	ld (XIY),A                                    ; F8FB62  b5 41
	nop                                           ; F8FB64  00
	nop                                           ; F8FB65  00
	nop                                           ; F8FB66  00
	ld (XIY),A                                    ; F8FB67  b5 41
	nop                                           ; F8FB69  00
	nop                                           ; F8FB6A  00
	nop                                           ; F8FB6B  00
	ld (XIY),A                                    ; F8FB6C  b5 41
	nop                                           ; F8FB6E  00
	nop                                           ; F8FB6F  00
	nop                                           ; F8FB70  00
	ld (XIY),A                                    ; F8FB71  b5 41
	djnz16 bc, .LF8FB23                           ; F8FB73  d9 1c ad
	nop                                           ; F8FB76  00
	nop                                           ; F8FB77  00
	nop                                           ; F8FB78  00
	ld (XIY+0x01),0x59                            ; F8FB79  bd 01 00 59
	ret                                           ; F8FB7D  0e

; ---------------------------------------------------------------------
; LCD_Svc_10_SetPanel3Layer -- SWI7 service 0x10: reprogramme the panel with
; THREE composed layers -- the arrangement the power-on setup leaves
;
; Called from: SWI7_ServiceTable slot 0x10 (0xF8EA06)
; Inputs:  none
; Outputs: as service 0x0F but with the three-layer geometry: SCROLL with EIGHT
;          parameter bytes (SAD1 = 0x0000, SL1 = 240, SAD2 = 0x2600, SL2 = 240,
;          SAD3 = 0x4C00), OVLAY 0x1C, and 0x0718 * 16 = 29056 zero bytes.
;          (0x2541) = 0x0000, (0x2543) = 0x2600, (0x2545) = 0x4C00,
;          (0x2554) = 0x1C, (0x2557)/(0x2558) = AP = 0x0028.
; Evidence: the SYSTEM SET and SCROLL parameter bytes are the SAME eight and
;          eight that LCD_Init_SED1330 sends -- 30 07 00 27 35 EF 28 00 and
;          00 00 F0 00 26 F0 00 4C -- and the three RAM words it writes are the
;          three the layer table points at.  The clear count is 0x4C00 + 240*40
;          = 0x7180 = 29056, the end of the highest layer.  All of that is
;          re-read from the ROM by notes/prom_a_byte_checks.py.
; Notes:   this service is NOT a copy of LCD_Init_SED1330: 308 bytes against the
;          setup's 390, because it omits HDOT SCR, CSRFORM and the parametered
;          DISP OFF, and because its clear loop stops at the end of layer 2
;          instead of at the end of display RAM.  The pair 0x0F / 0x10 is a
;          MODE SWITCH; the power-on setup is a superset of 0x10.
; Unknown:  callers, as for 0x0F.
; ---------------------------------------------------------------------
LCD_Svc_10_SetPanel3Layer:
	ld XIY,0x00790000                             ; F8FB7E  45 00 00 79 00
	ld (XIY+0x01),0x40                            ; F8FB83  bd 01 00 40
	nop                                           ; F8FB87  00
	nop                                           ; F8FB88  00
	nop                                           ; F8FB89  00
	nop                                           ; F8FB8A  00
	ld (XIY),0x30                                 ; F8FB8B  b5 00 30
	nop                                           ; F8FB8E  00
	nop                                           ; F8FB8F  00
	nop                                           ; F8FB90  00
	nop                                           ; F8FB91  00
	ld (XIY),0x07                                 ; F8FB92  b5 00 07
	nop                                           ; F8FB95  00
	nop                                           ; F8FB96  00
	nop                                           ; F8FB97  00
	nop                                           ; F8FB98  00
	ld (XIY),0x00                                 ; F8FB99  b5 00 00
	nop                                           ; F8FB9C  00
	nop                                           ; F8FB9D  00
	nop                                           ; F8FB9E  00
	nop                                           ; F8FB9F  00
	ld (XIY),0x27                                 ; F8FBA0  b5 00 27
	nop                                           ; F8FBA3  00
	nop                                           ; F8FBA4  00
	nop                                           ; F8FBA5  00
	nop                                           ; F8FBA6  00
	ld (XIY),0x35                                 ; F8FBA7  b5 00 35
	nop                                           ; F8FBAA  00
	nop                                           ; F8FBAB  00
	nop                                           ; F8FBAC  00
	nop                                           ; F8FBAD  00
	ld (XIY),0xef                                 ; F8FBAE  b5 00 ef
	ldb a, 0x28                                   ; F8FBB1  21 28
	ld (XIY),A                                    ; F8FBB3  b5 41
	stb_d8 (0x2557), a                            ; F8FBB5  f1 57 25 41
	nop                                           ; F8FBB9  00
	nop                                           ; F8FBBA  00
	ldb a, 0x00                                   ; F8FBBB  21 00
	ld (XIY),A                                    ; F8FBBD  b5 41
	stb_d8 (0x2558), a                            ; F8FBBF  f1 58 25 41
	nop                                           ; F8FBC3  00
	nop                                           ; F8FBC4  00
	ld (XIY+0x01),0x44                            ; F8FBC5  bd 01 00 44
	nop                                           ; F8FBC9  00
	nop                                           ; F8FBCA  00
	nop                                           ; F8FBCB  00
	ld (XIY),0x00                                 ; F8FBCC  b5 00 00
	nop                                           ; F8FBCF  00
	nop                                           ; F8FBD0  00
	nop                                           ; F8FBD1  00
	ld (XIY),0x00                                 ; F8FBD2  b5 00 00
	nop                                           ; F8FBD5  00
	nop                                           ; F8FBD6  00
	nop                                           ; F8FBD7  00
	ld (XIY),0xf0                                 ; F8FBD8  b5 00 f0
	nop                                           ; F8FBDB  00
	nop                                           ; F8FBDC  00
	nop                                           ; F8FBDD  00
	ld (XIY),0x00                                 ; F8FBDE  b5 00 00
	nop                                           ; F8FBE1  00
	nop                                           ; F8FBE2  00
	nop                                           ; F8FBE3  00
	ld (XIY),0x26                                 ; F8FBE4  b5 00 26
	nop                                           ; F8FBE7  00
	nop                                           ; F8FBE8  00
	nop                                           ; F8FBE9  00
	ld (XIY),0xf0                                 ; F8FBEA  b5 00 f0
	nop                                           ; F8FBED  00
	nop                                           ; F8FBEE  00
	nop                                           ; F8FBEF  00
	ld (XIY),0x00                                 ; F8FBF0  b5 00 00
	nop                                           ; F8FBF3  00
	nop                                           ; F8FBF4  00
	nop                                           ; F8FBF5  00
	ld (XIY),0x4c                                 ; F8FBF6  b5 00 4c
	ldb a, 0x00                                   ; F8FBF9  21 00
	ldb w, 0x00                                   ; F8FBFB  20 00
	stda16 (0x2541), wa                           ; F8FBFD  f1 41 25 50
	ldb a, 0x00                                   ; F8FC01  21 00
	ldb w, 0x26                                   ; F8FC03  20 26
	stda16 (0x2543), wa                           ; F8FC05  f1 43 25 50
	ldb a, 0x00                                   ; F8FC09  21 00
	ldb w, 0x4c                                   ; F8FC0B  20 4c
	stda16 (0x2545), wa                           ; F8FC0D  f1 45 25 50
	ld (XIY+0x01),0x5b                            ; F8FC11  bd 01 00 5b
	nop                                           ; F8FC15  00
	nop                                           ; F8FC16  00
	nop                                           ; F8FC17  00
	ld (XIY),0x1c                                 ; F8FC18  b5 00 1c
	stdi8 (0x2554), 0x1c                          ; F8FC1B  f1 54 25 00 1c
	nop                                           ; F8FC20  00
	nop                                           ; F8FC21  00
	ld (XIY+0x01),0x58                            ; F8FC22  bd 01 00 58
	nop                                           ; F8FC26  00
	nop                                           ; F8FC27  00
	nop                                           ; F8FC28  00
	nop                                           ; F8FC29  00
	ld (XIY+0x01),0x4c                            ; F8FC2A  bd 01 00 4c
	nop                                           ; F8FC2E  00
	nop                                           ; F8FC2F  00
	nop                                           ; F8FC30  00
	nop                                           ; F8FC31  00
	nop                                           ; F8FC32  00
	ld (XIY+0x01),0x46                            ; F8FC33  bd 01 00 46
	xor WA,WA                                     ; F8FC37  d8 d0
	nop                                           ; F8FC39  00
	nop                                           ; F8FC3A  00
	nop                                           ; F8FC3B  00
	nop                                           ; F8FC3C  00
	nop                                           ; F8FC3D  00
	nop                                           ; F8FC3E  00
	nop                                           ; F8FC3F  00
	ld (XIY),W                                    ; F8FC40  b5 40
	nop                                           ; F8FC42  00
	nop                                           ; F8FC43  00
	nop                                           ; F8FC44  00
	nop                                           ; F8FC45  00
	nop                                           ; F8FC46  00
	nop                                           ; F8FC47  00
	nop                                           ; F8FC48  00
	nop                                           ; F8FC49  00
	ld (XIY),A                                    ; F8FC4A  b5 41
	nop                                           ; F8FC4C  00
	nop                                           ; F8FC4D  00
	nop                                           ; F8FC4E  00
	nop                                           ; F8FC4F  00
	ld (XIY+0x01),0x42                            ; F8FC50  bd 01 00 42
	ldw bc, 0x0718                                ; F8FC54  31 18 07
.LF8FC57:
	nop                                           ; F8FC57  00
	nop                                           ; F8FC58  00
	nop                                           ; F8FC59  00
	ld (XIY),A                                    ; F8FC5A  b5 41
	nop                                           ; F8FC5C  00
	nop                                           ; F8FC5D  00
	nop                                           ; F8FC5E  00
	ld (XIY),A                                    ; F8FC5F  b5 41
	nop                                           ; F8FC61  00
	nop                                           ; F8FC62  00
	nop                                           ; F8FC63  00
	ld (XIY),A                                    ; F8FC64  b5 41
	nop                                           ; F8FC66  00
	nop                                           ; F8FC67  00
	nop                                           ; F8FC68  00
	ld (XIY),A                                    ; F8FC69  b5 41
	nop                                           ; F8FC6B  00
	nop                                           ; F8FC6C  00
	nop                                           ; F8FC6D  00
	ld (XIY),A                                    ; F8FC6E  b5 41
	nop                                           ; F8FC70  00
	nop                                           ; F8FC71  00
	nop                                           ; F8FC72  00
	ld (XIY),A                                    ; F8FC73  b5 41
	nop                                           ; F8FC75  00
	nop                                           ; F8FC76  00
	nop                                           ; F8FC77  00
	ld (XIY),A                                    ; F8FC78  b5 41
	nop                                           ; F8FC7A  00
	nop                                           ; F8FC7B  00
	nop                                           ; F8FC7C  00
	ld (XIY),A                                    ; F8FC7D  b5 41
	nop                                           ; F8FC7F  00
	nop                                           ; F8FC80  00
	nop                                           ; F8FC81  00
	ld (XIY),A                                    ; F8FC82  b5 41
	nop                                           ; F8FC84  00
	nop                                           ; F8FC85  00
	nop                                           ; F8FC86  00
	ld (XIY),A                                    ; F8FC87  b5 41
	nop                                           ; F8FC89  00
	nop                                           ; F8FC8A  00
	nop                                           ; F8FC8B  00
	ld (XIY),A                                    ; F8FC8C  b5 41
	nop                                           ; F8FC8E  00
	nop                                           ; F8FC8F  00
	nop                                           ; F8FC90  00
	ld (XIY),A                                    ; F8FC91  b5 41
	nop                                           ; F8FC93  00
	nop                                           ; F8FC94  00
	nop                                           ; F8FC95  00
	ld (XIY),A                                    ; F8FC96  b5 41
	nop                                           ; F8FC98  00
	nop                                           ; F8FC99  00
	nop                                           ; F8FC9A  00
	ld (XIY),A                                    ; F8FC9B  b5 41
	nop                                           ; F8FC9D  00
	nop                                           ; F8FC9E  00
	nop                                           ; F8FC9F  00
	ld (XIY),A                                    ; F8FCA0  b5 41
	nop                                           ; F8FCA2  00
	nop                                           ; F8FCA3  00
	nop                                           ; F8FCA4  00
	ld (XIY),A                                    ; F8FCA5  b5 41
	djnz16 bc, .LF8FC57                           ; F8FCA7  d9 1c ad
	nop                                           ; F8FCAA  00
	nop                                           ; F8FCAB  00
	nop                                           ; F8FCAC  00
	ld (XIY+0x01),0x59                            ; F8FCAD  bd 01 00 59
	ret                                           ; F8FCB1  0e

; ---------------------------------------------------------------------
; LCD_Svc_11_DrawHLineDither -- SWI7 service 0x11: a horizontal run drawn with
; the 0xCC dither instead of solid pixels
;
; Called from: SWI7_ServiceTable slot 0x11 (0xF8EA0A), and from
;          LCD_Svc_13_DrawBoxPatterned (0xF8F475 and 0xF8F484, both converted)
; Inputs:  (0x2530) = X0, (0x2534) = X1, (0x2532) = Y; (0x2540) the layer
; Outputs: the pattern OR'd into the run; (0x255A) = the first byte's display
;          address; (0x255E) = the pattern byte used for the whole bytes; the
;          four coordinate words clamped in place.
; Evidence: it is LCD_Svc_01_DrawHLine with the two constants replaced.  The
;          solid version ORs LCD_Rect_LeftEdgeMask's mask into the ragged first
;          byte, then whole 0xFF bytes, then LCD_Rect_RightEdgeMask's mask; this
;          one calls LCD_Dither_FetchMasks instead of the left-edge helper,
;          writes (0x255E) instead of 0xFF for the whole bytes, and
;          LCD_Dither_RightEdgeMask instead of the right-edge helper.  Same
;          CSRDIR RIGHT, same address arithmetic, same three-phase byte walk.
;          ⚠ It also uses `divs` where service 0x01 uses `div` for X0/8 -- a
;          SIGNED divide of a coordinate that has just been clamped to 0..319,
;          so the two agree on every reachable input.
; Unknown:  callers other than service 0x13.
; ---------------------------------------------------------------------
LCD_Svc_11_DrawHLineDither:
	calr (0xF8EE93 - 0xF8FCB5)                                   ; F8FCB2  1e de f1
	calr (0xF8EB6B - 0xF8FCB8)                                   ; F8FCB5  1e b3 ee
	ld XIX,0x00790000                             ; F8FCB8  44 00 00 79 00
	ldw_d16 wa, (0x2532)                          ; F8FCBD  d1 32 25 20
	ldw_d16 bc, (0x2557)                          ; F8FCC1  d1 57 25 21
	mul xwa, xbc                                  ; F8FCC5  d9 40
	ld HL,WA                                      ; F8FCC7  d8 8b
	ldw_d16 wa, (0x2530)                          ; F8FCC9  d1 30 25 20
	extz XWA                                      ; F8FCCD  e8 12
	ldw bc, 0x08                                  ; F8FCCF  31 08 00
	divs xwa, xbc                                 ; F8FCD2  d9 58
	ld DE,QWA                                     ; F8FCD4  d7 e2 8a
	add HL,WA                                     ; F8FCD7  d8 83
	ldw_d16 wa, (0x2555)                          ; F8FCD9  d1 55 25 20
	add WA,HL                                     ; F8FCDD  db 80
	bit_dd8 0x00, 0xc6                            ; F8FCDF  f0 c6 c8
	jr nz, .LF8FCE8                               ; F8FCE2  6e 04
.LF8FCE4:
	bit 6,(XIX)                                   ; F8FCE4  b4 ce
	jr nz, .LF8FCE4                               ; F8FCE6  6e fc
.LF8FCE8:
	ld (XIX+0x01),0x4c                            ; F8FCE8  bc 01 00 4c
	bit_dd8 0x00, 0xc6                            ; F8FCEC  f0 c6 c8
	jr nz, .LF8FCF5                               ; F8FCEF  6e 04
.LF8FCF1:
	bit 6,(XIX)                                   ; F8FCF1  b4 ce
	jr nz, .LF8FCF1                               ; F8FCF3  6e fc
.LF8FCF5:
	ld (XIX+0x01),0x46                            ; F8FCF5  bc 01 00 46
	stda16 (0x255a), wa                           ; F8FCF9  f1 5a 25 50
	bit_dd8 0x00, 0xc6                            ; F8FCFD  f0 c6 c8
	jr nz, .LF8FD06                               ; F8FD00  6e 04
.LF8FD02:
	bit 6,(XIX)                                   ; F8FD02  b4 ce
	jr nz, .LF8FD02                               ; F8FD04  6e fc
.LF8FD06:
	ld (XIX),A                                    ; F8FD06  b4 41
	bit_dd8 0x00, 0xc6                            ; F8FD08  f0 c6 c8
	jr nz, .LF8FD11                               ; F8FD0B  6e 04
.LF8FD0D:
	bit 6,(XIX)                                   ; F8FD0D  b4 ce
	jr nz, .LF8FD0D                               ; F8FD0F  6e fc
.LF8FD11:
	ld (XIX),W                                    ; F8FD11  b4 40
	calr LCD_Dither_FetchMasks                                 ; F8FD13  1e 23 01
	and DE,DE                                     ; F8FD16  da c2
	jr z, .LF8FD74                                ; F8FD18  66 5a
	ld (XIX+0x01),0x43                            ; F8FD1A  bc 01 00 43
	bit_dd8 0x00, 0xc6                            ; F8FD1E  f0 c6 c8
	jr nz, .LF8FD27                               ; F8FD21  6e 04
.LF8FD23:
	bit 6,(XIX)                                   ; F8FD23  b4 ce
	jr nz, .LF8FD23                               ; F8FD25  6e fc
.LF8FD27:
	ld W,(XIX+0x01)                               ; F8FD27  8c 01 20
	or A,W                                        ; F8FD2A  c8 e1
	ld C,A                                        ; F8FD2C  c9 8b
	bit_dd8 0x00, 0xc6                            ; F8FD2E  f0 c6 c8
	jr nz, .LF8FD37                               ; F8FD31  6e 04
.LF8FD33:
	bit 6,(XIX)                                   ; F8FD33  b4 ce
	jr nz, .LF8FD33                               ; F8FD35  6e fc
.LF8FD37:
	ld (XIX+0x01),0x46                            ; F8FD37  bc 01 00 46
	ldw_d16 wa, (0x255a)                          ; F8FD3B  d1 5a 25 20
	bit_dd8 0x00, 0xc6                            ; F8FD3F  f0 c6 c8
	jr nz, .LF8FD48                               ; F8FD42  6e 04
.LF8FD44:
	bit 6,(XIX)                                   ; F8FD44  b4 ce
	jr nz, .LF8FD44                               ; F8FD46  6e fc
.LF8FD48:
	ld (XIX),A                                    ; F8FD48  b4 41
	bit_dd8 0x00, 0xc6                            ; F8FD4A  f0 c6 c8
	jr nz, .LF8FD53                               ; F8FD4D  6e 04
.LF8FD4F:
	bit 6,(XIX)                                   ; F8FD4F  b4 ce
	jr nz, .LF8FD4F                               ; F8FD51  6e fc
.LF8FD53:
	ld (XIX),W                                    ; F8FD53  b4 40
	bit_dd8 0x00, 0xc6                            ; F8FD55  f0 c6 c8
	jr nz, .LF8FD5E                               ; F8FD58  6e 04
.LF8FD5A:
	bit 6,(XIX)                                   ; F8FD5A  b4 ce
	jr nz, .LF8FD5A                               ; F8FD5C  6e fc
.LF8FD5E:
	ld (XIX+0x01),0x42                            ; F8FD5E  bc 01 00 42
	ldw hl, 0x08                                  ; F8FD62  33 08 00
	sub HL,DE                                     ; F8FD65  da a3
	ex16 hl, de                                   ; F8FD67  da bb
	bit_dd8 0x00, 0xc6                            ; F8FD69  f0 c6 c8
	jr nz, .LF8FD72                               ; F8FD6C  6e 04
.LF8FD6E:
	bit 6,(XIX)                                   ; F8FD6E  b4 ce
	jr nz, .LF8FD6E                               ; F8FD70  6e fc
.LF8FD72:
	ld (XIX),C                                    ; F8FD72  b4 43
.LF8FD74:
	ldw_d16 wa, (0x2534)                          ; F8FD74  d1 34 25 20
	m_sub_rm MW16, 0x2530, r0                     ; F8FD78  d1 30 25 a0
	inc 1,WA                                      ; F8FD7C  d8 61
	cp WA,DE                                      ; F8FD7E  da f0
	jrl ule, .LF8FE38                             ; F8FD80  73 b5 00
	sub WA,DE                                     ; F8FD83  da a0
	extz XWA                                      ; F8FD85  e8 12
	ldw bc, 0x08                                  ; F8FD87  31 08 00
	divs xwa, xbc                                 ; F8FD8A  d9 58
	ld DE,QWA                                     ; F8FD8C  d7 e2 8a
	and WA,WA                                     ; F8FD8F  d8 c0
	jr z, .LF8FDAB                                ; F8FD91  66 18
	ld BC,WA                                      ; F8FD93  d8 89
	ld (XIX+0x01),0x42                            ; F8FD95  bc 01 00 42
	ldb_d8 a, (0x255e)                            ; F8FD99  c1 5e 25 21
.LF8FD9D:
	bit_dd8 0x00, 0xc6                            ; F8FD9D  f0 c6 c8
	jr nz, .LF8FDA6                               ; F8FDA0  6e 04
.LF8FDA2:
	bit 6,(XIX)                                   ; F8FDA2  b4 ce
	jr nz, .LF8FDA2                               ; F8FDA4  6e fc
.LF8FDA6:
	ld (XIX),A                                    ; F8FDA6  b4 41
	djnz16 bc, .LF8FD9D                           ; F8FDA8  d9 1c f2
.LF8FDAB:
	and DE,DE                                     ; F8FDAB  da c2
	jrl z, .LF8FE38                               ; F8FDAD  76 88 00
	bit_dd8 0x00, 0xc6                            ; F8FDB0  f0 c6 c8
	jr nz, .LF8FDB9                               ; F8FDB3  6e 04
.LF8FDB5:
	bit 6,(XIX)                                   ; F8FDB5  b4 ce
	jr nz, .LF8FDB5                               ; F8FDB7  6e fc
.LF8FDB9:
	ld (XIX+0x01),0x47                            ; F8FDB9  bc 01 00 47
	bit_dd8 0x00, 0xc6                            ; F8FDBD  f0 c6 c8
	jr nz, .LF8FDC6                               ; F8FDC0  6e 04
.LF8FDC2:
	bit 6,(XIX)                                   ; F8FDC2  b4 ce
	jr nz, .LF8FDC2                               ; F8FDC4  6e fc
.LF8FDC6:
	ld A,(XIX+0x01)                               ; F8FDC6  8c 01 21
	bit_dd8 0x00, 0xc6                            ; F8FDC9  f0 c6 c8
	jr nz, .LF8FDD2                               ; F8FDCC  6e 04
.LF8FDCE:
	bit 6,(XIX)                                   ; F8FDCE  b4 ce
	jr nz, .LF8FDCE                               ; F8FDD0  6e fc
.LF8FDD2:
	ld W,(XIX+0x01)                               ; F8FDD2  8c 01 20
	stda16 (0x255a), wa                           ; F8FDD5  f1 5a 25 50
	bit_dd8 0x00, 0xc6                            ; F8FDD9  f0 c6 c8
	jr nz, .LF8FDE2                               ; F8FDDC  6e 04
.LF8FDDE:
	bit 6,(XIX)                                   ; F8FDDE  b4 ce
	jr nz, .LF8FDDE                               ; F8FDE0  6e fc
.LF8FDE2:
	ld (XIX+0x01),0x43                            ; F8FDE2  bc 01 00 43
	bit_dd8 0x00, 0xc6                            ; F8FDE6  f0 c6 c8
	jr nz, .LF8FDEF                               ; F8FDE9  6e 04
.LF8FDEB:
	bit 6,(XIX)                                   ; F8FDEB  b4 ce
	jr nz, .LF8FDEB                               ; F8FDED  6e fc
.LF8FDEF:
	ld W,(XIX+0x01)                               ; F8FDEF  8c 01 20
	calr (0xF8FE64 - 0xF8FDF5)                                   ; F8FDF2  1e 6f 00
	or A,W                                        ; F8FDF5  c8 e1
	ld C,A                                        ; F8FDF7  c9 8b
	bit_dd8 0x00, 0xc6                            ; F8FDF9  f0 c6 c8
	jr nz, .LF8FE02                               ; F8FDFC  6e 04
.LF8FDFE:
	bit 6,(XIX)                                   ; F8FDFE  b4 ce
	jr nz, .LF8FDFE                               ; F8FE00  6e fc
.LF8FE02:
	ld (XIX+0x01),0x46                            ; F8FE02  bc 01 00 46
	ldw_d16 wa, (0x255a)                          ; F8FE06  d1 5a 25 20
	bit_dd8 0x00, 0xc6                            ; F8FE0A  f0 c6 c8
	jr nz, .LF8FE13                               ; F8FE0D  6e 04
.LF8FE0F:
	bit 6,(XIX)                                   ; F8FE0F  b4 ce
	jr nz, .LF8FE0F                               ; F8FE11  6e fc
.LF8FE13:
	ld (XIX),A                                    ; F8FE13  b4 41
	bit_dd8 0x00, 0xc6                            ; F8FE15  f0 c6 c8
	jr nz, .LF8FE1E                               ; F8FE18  6e 04
.LF8FE1A:
	bit 6,(XIX)                                   ; F8FE1A  b4 ce
	jr nz, .LF8FE1A                               ; F8FE1C  6e fc
.LF8FE1E:
	ld (XIX),W                                    ; F8FE1E  b4 40
	bit_dd8 0x00, 0xc6                            ; F8FE20  f0 c6 c8
	jr nz, .LF8FE29                               ; F8FE23  6e 04
.LF8FE25:
	bit 6,(XIX)                                   ; F8FE25  b4 ce
	jr nz, .LF8FE25                               ; F8FE27  6e fc
.LF8FE29:
	ld (XIX+0x01),0x42                            ; F8FE29  bc 01 00 42
	bit_dd8 0x00, 0xc6                            ; F8FE2D  f0 c6 c8
	jr nz, .LF8FE36                               ; F8FE30  6e 04
.LF8FE32:
	bit 6,(XIX)                                   ; F8FE32  b4 ce
	jr nz, .LF8FE32                               ; F8FE34  6e fc
.LF8FE36:
	ld (XIX),C                                    ; F8FE36  b4 43
.LF8FE38:
	ret                                           ; F8FE38  0e

; ---------------------------------------------------------------------
; LCD_Dither_FetchMasks -- pick this run's two dither bytes out of the tables
;
; Called from: LCD_Svc_11_DrawHLineDither (0xF8FD13)
; Inputs:  DE = X0 mod 8, 0..7
; Outputs: (0x255E) = the pattern byte for the WHOLE bytes of the run;
;          A = the pattern byte for the RAGGED FIRST byte.  XHL clobbered.
; Evidence: two five-byte table reads and nothing else, and the two tables are
;          what name it -- see their headers below.  The whole-byte value comes
;          from the ROTATE table, the first-byte value from the SHIFT table,
;          both indexed by the same X0 mod 8.
; ---------------------------------------------------------------------
LCD_Dither_FetchMasks:
	ld XHL,0x00f8fe5b                             ; F8FE39  43 5b fe f8 00
	.byte 0xc3, 0x07, 0xec, 0xe8, 0x21            ; F8FE3E  c3 07 ec e8 21
	stb_d8 (0x255e), a                            ; F8FE43  f1 5e 25 41
	ld XHL,0x00f8fe52                             ; F8FE47  43 52 fe f8 00
	.byte 0xc3, 0x07, 0xec, 0xe8, 0x21            ; F8FE4C  c3 07 ec e8 21
	ret                                           ; F8FE51  0e

; ---------------------------------------------------------------------
; LCD_DitherShift_Table -- 9 bytes: 0xCC logically SHIFTED right by k
; LCD_DitherRotate_Table -- 9 bytes: 0xCC ROTATED right by k
;
; Read by:  LCD_Dither_FetchMasks (0xF8FE47 and 0xF8FE39), indexed by X0 mod 8.
; Layout:   two consecutive 9-byte tables, 0xF8FE52-0xF8FE5A and
;           0xF8FE5B-0xF8FE63.
; Count:    9 and 9, fixed by the two immediates and by what follows: the second
;           table starts at 0xF8FE5B because that is the address the first table
;           read loads, and 0xF8FE64 is LCD_Dither_RightEdgeMask's first
;           instruction, so there is room for nine bytes and no more.
;           ⚠ Index 8 is unreachable in both: `div`/`divs` by 8 cannot produce
;           it.  Index 0 IS reachable -- unlike LCD_LeftEdgeMask_Table's, this
;           helper is called before the caller tests DE for zero.
; Evidence: 0xCC = 11001100, and with the MSB-leftmost bit order the plotter's
;           mask table fixes, that is two pixels on, two off, repeating with
;           period 4.  Rotating it right by k moves the pattern to the pixel
;           column the byte starts at, which is what keeps the phase constant
;           across a run; because the period divides 8, ONE rotated byte serves
;           every whole byte of the run, and the code does exactly that -- it
;           loads (0x255E) once, outside the loop.  The SHIFT table is the same
;           rotated byte ANDed with 0xFF >> k, i.e. the rotate value with the
;           pixels left of X0 removed; that identity holds for all eight
;           reachable indices and is checked by notes/prom_a_byte_checks.py.
; ---------------------------------------------------------------------
LCD_DitherShift_Table:
	.byte 0xCC			; F8FE52  index 0 -- 0xCC >> 0
	.byte 0x66			; F8FE53  index 1
	.byte 0x33			; F8FE54  index 2
	.byte 0x19			; F8FE55  index 3
	.byte 0x0C			; F8FE56  index 4
	.byte 0x06			; F8FE57  index 5
	.byte 0x03			; F8FE58  index 6
	.byte 0x01			; F8FE59  index 7
	.byte 0x00			; F8FE5A  index 8 -- unreachable
LCD_DitherRotate_Table:
	.byte 0xCC			; F8FE5B  index 0 -- ror(0xCC,0)
	.byte 0x66			; F8FE5C  index 1
	.byte 0x33			; F8FE5D  index 2
	.byte 0x99			; F8FE5E  index 3
	.byte 0xCC			; F8FE5F  index 4 -- the pattern's period is 4
	.byte 0x66			; F8FE60  index 5
	.byte 0x33			; F8FE61  index 6
	.byte 0x99			; F8FE62  index 7
	.byte 0xCC			; F8FE63  index 8 -- unreachable

; ---------------------------------------------------------------------
; LCD_Dither_RightEdgeMask -- trim the run's LAST byte to the pixels inside it
;
; Called from: LCD_Svc_11_DrawHLineDither (0xF8FDF2)
; Inputs:  DE = how many pixels of the last byte are inside the run, 0..7;
;          (0x255E) = the whole-byte pattern LCD_Dither_FetchMasks stored.
; Outputs: (0x255E) masked down to those pixels, and A = the result.
;          XHL clobbered.
; Evidence: `and (0x255e),A` is a MEMORY-destination AND -- MAME's byte-operand
;          table has 0xC8-0xCF as `AND (mem),r8` against 0xC0-0xC7's
;          `AND r8,(mem)` (../mame/src/devices/cpu/tlcs900/dasm900.cpp:161-164, the mnemonic_80 table),
;          and the very next instruction reloads A from (0x255E), which would be
;          pointless the other way round.  So the pattern byte is narrowed in
;          place and handed back.
; ---------------------------------------------------------------------
LCD_Dither_RightEdgeMask:
	ld XHL,0x00f8fe77                             ; F8FE64  43 77 fe f8 00
	.byte 0xc3, 0x07, 0xec, 0xe8, 0x21            ; F8FE69  c3 07 ec e8 21
	anddm8 (0x255e), a                            ; F8FE6E  c1 5e 25 c9
	ldb_d8 a, (0x255e)                            ; F8FE72  c1 5e 25 21
	ret                                           ; F8FE76  0e

; ---------------------------------------------------------------------
; LCD_Dither_RightEdge_Table -- 9 bytes: keep pixels 0..k-1 of a byte
;
; Read by:  LCD_Dither_RightEdgeMask (0xF8FE64).
; Layout:   9 bytes, 0xF8FE77-0xF8FE7F, entry k = 0xFF << (8-k).
; Count:    fixed by the load at 0xF8FE64 and by 0xF8FE80 being
;           LCD_Svc_12_DrawVLineDashed's first instruction.
; ⚠ Evidence about the DUPLICATE: this table is byte-for-byte the same as
;           LCD_RightEdgeMask_Table at 0xF8F7AF -- ALL NINE bytes equal,
;           00 80 C0 E0 F0 F8 FC FE 00 -- so the ROM carries the same nine bytes
;           twice.  The pattern services do not share the solid services'
;           helper because the helper they need also has to mask (0x255E); they
;           got their own copy of the table with it.  The nine-of-nine
;           comparison is one of the checks in notes/prom_a_byte_checks.py, not
;           an eyeball.
; ---------------------------------------------------------------------
LCD_Dither_RightEdge_Table:
	.byte 0x00			; F8FE77  index 0 -- unreachable
	.byte 0x80			; F8FE78  index 1 -- pixel 0 only
	.byte 0xC0			; F8FE79  index 2
	.byte 0xE0			; F8FE7A  index 3
	.byte 0xF0			; F8FE7B  index 4
	.byte 0xF8			; F8FE7C  index 5
	.byte 0xFC			; F8FE7D  index 6
	.byte 0xFE			; F8FE7E  index 7 -- pixels 0..6
	.byte 0x00			; F8FE7F  index 8 -- unreachable

; ---------------------------------------------------------------------
; LCD_Svc_12_DrawVLineDashed -- SWI7 service 0x12: a vertical run, two pixels
; on and two off
;
; Called from: SWI7_ServiceTable slot 0x12 (0xF8EA0E), and from
;          LCD_Svc_13_DrawBoxPatterned (0xF8F493 and 0xF8F4A2, both converted)
; Inputs:  (0x2530) = X, (0x2532) = Y0, (0x2536) = Y1; (0x2540) the layer
; Outputs: pixels set at (X, Y0), (X, Y0+1), skipped at Y0+2 and Y0+3, and so on
;          for (0x2536)-(0x2532)+1 rows.  (0x2532) is left one past Y1;
;          (0x2550)/(0x2552) hold the last point plotted.
; Evidence: the loop is a modulo-4 counter in WA -- plot when it is 0 or 1, skip
;          on 2, and on 3 reset it to 0 and skip -- wrapped around the same
;          LCD_PlotPointAt (0xF8ECCF) the solid vertical line uses.  Two on,
;          two off is the same duty cycle as the 0xCC byte the horizontal
;          patterned service uses, which is what makes 0x11 and 0x12 a pair and
;          service 0x13 a box drawn in one consistent dither.
; ⚠ Unlike service 0x11 the phase is NOT tied to the coordinate: the counter
;          starts at 0 on every call, so the dash always begins with two set
;          pixels at Y0 whatever Y0 is.  Service 0x11's phase, by contrast,
;          follows X0 mod 8.
; ⚠ Like the solid vertical line it does NOT clamp -- neither service calls
;          LCD_ClampCoordsToPanel -- but unlike it, it has NO zero-height guard.
;          Service 0x02 tests `and BC,BC` and returns; this one goes straight
;          into a `djnz`, so a call with (0x2536) one BELOW (0x2532) plots 65536
;          points instead of none.
; Unknown:  callers other than service 0x13.
; ---------------------------------------------------------------------
LCD_Svc_12_DrawVLineDashed:
	calr (0xF8EE93 - 0xF8FE83)                                   ; F8FE80  1e 10 f0
	ldw_d16 bc, (0x2536)                          ; F8FE83  d1 36 25 21
	m_sub_rm MW16, 0x2532, r1                     ; F8FE87  d1 32 25 a1
	inc 1,BC                                      ; F8FE8B  d9 61
	ldw_d16 wa, (0x2530)                          ; F8FE8D  d1 30 25 20
	stda16 (0x2550), wa                           ; F8FE91  f1 50 25 50
	ldw_d16 wa, (0x2532)                          ; F8FE95  d1 32 25 20
	stda16 (0x2552), wa                           ; F8FE99  f1 52 25 50
	xor WA,WA                                     ; F8FE9D  d8 d0
.LF8FE9F:
	cps wa, 0x02                                  ; F8FE9F  d8 da
	jr z, .LF8FEB2                                ; F8FEA1  66 0f
	cps wa, 0x03                                  ; F8FEA3  d8 db
	jr nz, .LF8FEAB                               ; F8FEA5  6e 04
	xor WA,WA                                     ; F8FEA7  d8 d0
	jr .LF8FEB4                                   ; F8FEA9  68 09
.LF8FEAB:
	pushw wa                                      ; F8FEAB  28
	pushw bc                                      ; F8FEAC  29
	calr (0xF8ECCF - 0xF8FEB0)                                   ; F8FEAD  1e 1f ee
	popw bc                                       ; F8FEB0  49
	popw wa                                       ; F8FEB1  48
.LF8FEB2:
	inc 1,WA                                      ; F8FEB2  d8 61
.LF8FEB4:
	incdi16 0x01, (0x2552)                        ; F8FEB4  d1 52 25 61
	djnz16 bc, .LF8FE9F                           ; F8FEB8  d9 1c e4
	ret                                           ; F8FEBB  0e

; ---------------------------------------------------------------------
; LCD_Svc_14_FillRectPattern -- SWI7 service 0x14: fill the box with the
; caller's 8-byte pattern
;
; Called from: SWI7_ServiceTable slot 0x14 (0xF8EA16)
; Inputs:  (0x2530),(0x2532),(0x2534),(0x2536) = the box, as for the fill;
;          (0x2540) the layer; ★ (0x2538)-(0x253F) = EIGHT pattern bytes, one
;          per screen row, supplied by the caller.
; Outputs: the pattern OR'd over the box, row by row, repeating every 8 rows.
;          (0x2532) left one past Y1; (0x255E) = the last pattern byte used;
;          IY left holding the row index.
; Evidence: ★ THIS IS WHAT (0x2538) IS.  LCD_Pattern_NextRow loads
;          `ld XHL,0x00002538` and indexes it with IY, having just wrapped IY to
;          zero when it reached 8 -- an eight-entry byte table in RAM, stepped
;          once per row of the box, and its address is an immediate in the code,
;          not an inference.  The rest of the routine is LCD_Svc_1B_EraseRect's
;          skeleton with the sense flipped back to OR: same per-row address
;          arithmetic, same CSRDIR RIGHT, same three-phase byte walk, same
;          `incw 1,(0x2532)` loop.
; ⚠ The pattern is tiled on BYTE boundaries in X, not on the coordinate: the one
;          byte fetched for a row is written into every whole byte of that row
;          and is never rotated by X mod 8.  Service 0x11's dither IS rotated.
;          So this service's pattern has period 8 in X anchored at display-byte
;          boundaries, and period 8 in Y anchored at Y0.
; ⚠ IY is not initialised by the row loop but by the routine's second
;          instruction (`xor IY,IY`), so the vertical phase restarts at the top
;          of every call.
; Unknown:  who fills (0x2538)-(0x253F).  No writer of those bytes is converted.
; ---------------------------------------------------------------------
LCD_Svc_14_FillRectPattern:
	calr (0xF8EE93 - 0xF8FEBF)                                   ; F8FEBC  1e d4 ef
	ld XIX,0x00790000                             ; F8FEBF  44 00 00 79 00
	xor IY,IY                                     ; F8FEC4  dd d5
.LF8FEC6:
	ldw_d16 wa, (0x2536)                          ; F8FEC6  d1 36 25 20
	m_cp_mr MW16, 0x2532, r0                      ; F8FECA  d1 32 25 f8
	jrl ugt, .LF90067                             ; F8FECE  7b 96 01
	ldw_d16 wa, (0x2532)                          ; F8FED1  d1 32 25 20
	ldw_d16 bc, (0x2557)                          ; F8FED5  d1 57 25 21
	mul xwa, xbc                                  ; F8FED9  d9 40
	ld HL,WA                                      ; F8FEDB  d8 8b
	ldw_d16 wa, (0x2530)                          ; F8FEDD  d1 30 25 20
	extz XWA                                      ; F8FEE1  e8 12
	ldw bc, 0x08                                  ; F8FEE3  31 08 00
	divs xwa, xbc                                 ; F8FEE6  d9 58
	ld DE,QWA                                     ; F8FEE8  d7 e2 8a
	add HL,WA                                     ; F8FEEB  d8 83
	ldw_d16 wa, (0x2555)                          ; F8FEED  d1 55 25 20
	add WA,HL                                     ; F8FEF1  db 80
	bit_dd8 0x00, 0xc6                            ; F8FEF3  f0 c6 c8
	jr nz, .LF8FEFC                               ; F8FEF6  6e 04
.LF8FEF8:
	bit 6,(XIX)                                   ; F8FEF8  b4 ce
	jr nz, .LF8FEF8                               ; F8FEFA  6e fc
.LF8FEFC:
	ld (XIX+0x01),0x4c                            ; F8FEFC  bc 01 00 4c
	bit_dd8 0x00, 0xc6                            ; F8FF00  f0 c6 c8
	jr nz, .LF8FF09                               ; F8FF03  6e 04
.LF8FF05:
	bit 6,(XIX)                                   ; F8FF05  b4 ce
	jr nz, .LF8FF05                               ; F8FF07  6e fc
.LF8FF09:
	ld (XIX+0x01),0x46                            ; F8FF09  bc 01 00 46
	stda16 (0x255a), wa                           ; F8FF0D  f1 5a 25 50
	bit_dd8 0x00, 0xc6                            ; F8FF11  f0 c6 c8
	jr nz, .LF8FF1A                               ; F8FF14  6e 04
.LF8FF16:
	bit 6,(XIX)                                   ; F8FF16  b4 ce
	jr nz, .LF8FF16                               ; F8FF18  6e fc
.LF8FF1A:
	ld (XIX),A                                    ; F8FF1A  b4 41
	bit_dd8 0x00, 0xc6                            ; F8FF1C  f0 c6 c8
	jr nz, .LF8FF25                               ; F8FF1F  6e 04
.LF8FF21:
	bit 6,(XIX)                                   ; F8FF21  b4 ce
	jr nz, .LF8FF21                               ; F8FF23  6e fc
.LF8FF25:
	ld (XIX),W                                    ; F8FF25  b4 40
	calr LCD_Pattern_NextRow                                 ; F8FF27  1e 3e 01
	and DE,DE                                     ; F8FF2A  da c2
	jr z, .LF8FF91                                ; F8FF2C  66 63
	bit_dd8 0x00, 0xc6                            ; F8FF2E  f0 c6 c8
	jr nz, .LF8FF37                               ; F8FF31  6e 04
.LF8FF33:
	bit 6,(XIX)                                   ; F8FF33  b4 ce
	jr nz, .LF8FF33                               ; F8FF35  6e fc
.LF8FF37:
	ld (XIX+0x01),0x43                            ; F8FF37  bc 01 00 43
	bit_dd8 0x00, 0xc6                            ; F8FF3B  f0 c6 c8
	jr nz, .LF8FF44                               ; F8FF3E  6e 04
.LF8FF40:
	bit 6,(XIX)                                   ; F8FF40  b4 ce
	jr nz, .LF8FF40                               ; F8FF42  6e fc
.LF8FF44:
	ld W,(XIX+0x01)                               ; F8FF44  8c 01 20
	or A,W                                        ; F8FF47  c8 e1
	ld C,A                                        ; F8FF49  c9 8b
	bit_dd8 0x00, 0xc6                            ; F8FF4B  f0 c6 c8
	jr nz, .LF8FF54                               ; F8FF4E  6e 04
.LF8FF50:
	bit 6,(XIX)                                   ; F8FF50  b4 ce
	jr nz, .LF8FF50                               ; F8FF52  6e fc
.LF8FF54:
	ld (XIX+0x01),0x46                            ; F8FF54  bc 01 00 46
	ldw_d16 wa, (0x255a)                          ; F8FF58  d1 5a 25 20
	bit_dd8 0x00, 0xc6                            ; F8FF5C  f0 c6 c8
	jr nz, .LF8FF65                               ; F8FF5F  6e 04
.LF8FF61:
	bit 6,(XIX)                                   ; F8FF61  b4 ce
	jr nz, .LF8FF61                               ; F8FF63  6e fc
.LF8FF65:
	ld (XIX),A                                    ; F8FF65  b4 41
	bit_dd8 0x00, 0xc6                            ; F8FF67  f0 c6 c8
	jr nz, .LF8FF70                               ; F8FF6A  6e 04
.LF8FF6C:
	bit 6,(XIX)                                   ; F8FF6C  b4 ce
	jr nz, .LF8FF6C                               ; F8FF6E  6e fc
.LF8FF70:
	ld (XIX),W                                    ; F8FF70  b4 40
	bit_dd8 0x00, 0xc6                            ; F8FF72  f0 c6 c8
	jr nz, .LF8FF7B                               ; F8FF75  6e 04
.LF8FF77:
	bit 6,(XIX)                                   ; F8FF77  b4 ce
	jr nz, .LF8FF77                               ; F8FF79  6e fc
.LF8FF7B:
	ld (XIX+0x01),0x42                            ; F8FF7B  bc 01 00 42
	bit_dd8 0x00, 0xc6                            ; F8FF7F  f0 c6 c8
	jr nz, .LF8FF88                               ; F8FF82  6e 04
.LF8FF84:
	bit 6,(XIX)                                   ; F8FF84  b4 ce
	jr nz, .LF8FF84                               ; F8FF86  6e fc
.LF8FF88:
	ld (XIX),C                                    ; F8FF88  b4 43
	ldw hl, 0x08                                  ; F8FF8A  33 08 00
	sub HL,DE                                     ; F8FF8D  da a3
	ex16 hl, de                                   ; F8FF8F  da bb
.LF8FF91:
	ldw_d16 wa, (0x2534)                          ; F8FF91  d1 34 25 20
	m_sub_rm MW16, 0x2530, r0                     ; F8FF95  d1 30 25 a0
	inc 1,WA                                      ; F8FF99  d8 61
	cp WA,DE                                      ; F8FF9B  da f0
	jrl ule, .LF90060                             ; F8FF9D  73 c0 00
	sub WA,DE                                     ; F8FFA0  da a0
	extz XWA                                      ; F8FFA2  e8 12
	ldw bc, 0x08                                  ; F8FFA4  31 08 00
	divs xwa, xbc                                 ; F8FFA7  d9 58
	ld DE,QWA                                     ; F8FFA9  d7 e2 8a
	and WA,WA                                     ; F8FFAC  d8 c0
	jr z, .LF8FFD3                                ; F8FFAE  66 23
	ld BC,WA                                      ; F8FFB0  d8 89
	bit_dd8 0x00, 0xc6                            ; F8FFB2  f0 c6 c8
	jr nz, .LF8FFBB                               ; F8FFB5  6e 04
.LF8FFB7:
	bit 6,(XIX)                                   ; F8FFB7  b4 ce
	jr nz, .LF8FFB7                               ; F8FFB9  6e fc
.LF8FFBB:
	ld (XIX+0x01),0x42                            ; F8FFBB  bc 01 00 42
	ldb_d8 a, (0x255e)                            ; F8FFBF  c1 5e 25 21
.LF8FFC3:
	nop                                           ; F8FFC3  00
	nop                                           ; F8FFC4  00
	bit_dd8 0x00, 0xc6                            ; F8FFC5  f0 c6 c8
	jr nz, .LF8FFCE                               ; F8FFC8  6e 04
.LF8FFCA:
	bit 6,(XIX)                                   ; F8FFCA  b4 ce
	jr nz, .LF8FFCA                               ; F8FFCC  6e fc
.LF8FFCE:
	ld (XIX),A                                    ; F8FFCE  b4 41
	djnz16 bc, .LF8FFC3                           ; F8FFD0  d9 1c f0
.LF8FFD3:
	and DE,DE                                     ; F8FFD3  da c2
	jrl z, .LF90060                               ; F8FFD5  76 88 00
	bit_dd8 0x00, 0xc6                            ; F8FFD8  f0 c6 c8
	jr nz, .LF8FFE1                               ; F8FFDB  6e 04
.LF8FFDD:
	bit 6,(XIX)                                   ; F8FFDD  b4 ce
	jr nz, .LF8FFDD                               ; F8FFDF  6e fc
.LF8FFE1:
	ld (XIX+0x01),0x47                            ; F8FFE1  bc 01 00 47
	bit_dd8 0x00, 0xc6                            ; F8FFE5  f0 c6 c8
	jr nz, .LF8FFEE                               ; F8FFE8  6e 04
.LF8FFEA:
	bit 6,(XIX)                                   ; F8FFEA  b4 ce
	jr nz, .LF8FFEA                               ; F8FFEC  6e fc
.LF8FFEE:
	ld A,(XIX+0x01)                               ; F8FFEE  8c 01 21
	bit_dd8 0x00, 0xc6                            ; F8FFF1  f0 c6 c8
	jr nz, .LF8FFFA                               ; F8FFF4  6e 04
.LF8FFF6:
	bit 6,(XIX)                                   ; F8FFF6  b4 ce
	jr nz, .LF8FFF6                               ; F8FFF8  6e fc
.LF8FFFA:
	ld W,(XIX+0x01)                               ; F8FFFA  8c 01 20
	stda16 (0x255a), wa                           ; F8FFFD  f1 5a 25 50
	bit_dd8 0x00, 0xc6                            ; F90001  f0 c6 c8
	jr nz, .LF9000A                               ; F90004  6e 04
.LF90006:
	bit 6,(XIX)                                   ; F90006  b4 ce
	jr nz, .LF90006                               ; F90008  6e fc
.LF9000A:
	ld (XIX+0x01),0x43                            ; F9000A  bc 01 00 43
	bit_dd8 0x00, 0xc6                            ; F9000E  f0 c6 c8
	jr nz, .LF90017                               ; F90011  6e 04
.LF90013:
	bit 6,(XIX)                                   ; F90013  b4 ce
	jr nz, .LF90013                               ; F90015  6e fc
.LF90017:
	ld W,(XIX+0x01)                               ; F90017  8c 01 20
	calr (0xF90094 - 0xF9001D)                                   ; F9001A  1e 77 00
	or A,W                                        ; F9001D  c8 e1
	ld C,A                                        ; F9001F  c9 8b
	bit_dd8 0x00, 0xc6                            ; F90021  f0 c6 c8
	jr nz, .LF9002A                               ; F90024  6e 04
.LF90026:
	bit 6,(XIX)                                   ; F90026  b4 ce
	jr nz, .LF90026                               ; F90028  6e fc
.LF9002A:
	ld (XIX+0x01),0x46                            ; F9002A  bc 01 00 46
	ldw_d16 wa, (0x255a)                          ; F9002E  d1 5a 25 20
	bit_dd8 0x00, 0xc6                            ; F90032  f0 c6 c8
	jr nz, .LF9003B                               ; F90035  6e 04
.LF90037:
	bit 6,(XIX)                                   ; F90037  b4 ce
	jr nz, .LF90037                               ; F90039  6e fc
.LF9003B:
	ld (XIX),A                                    ; F9003B  b4 41
	bit_dd8 0x00, 0xc6                            ; F9003D  f0 c6 c8
	jr nz, .LF90046                               ; F90040  6e 04
.LF90042:
	bit 6,(XIX)                                   ; F90042  b4 ce
	jr nz, .LF90042                               ; F90044  6e fc
.LF90046:
	ld (XIX),W                                    ; F90046  b4 40
	bit_dd8 0x00, 0xc6                            ; F90048  f0 c6 c8
	jr nz, .LF90051                               ; F9004B  6e 04
.LF9004D:
	bit 6,(XIX)                                   ; F9004D  b4 ce
	jr nz, .LF9004D                               ; F9004F  6e fc
.LF90051:
	ld (XIX+0x01),0x42                            ; F90051  bc 01 00 42
	bit_dd8 0x00, 0xc6                            ; F90055  f0 c6 c8
	jr nz, .LF9005E                               ; F90058  6e 04
.LF9005A:
	bit 6,(XIX)                                   ; F9005A  b4 ce
	jr nz, .LF9005A                               ; F9005C  6e fc
.LF9005E:
	ld (XIX),C                                    ; F9005E  b4 43
.LF90060:
	incdi16 0x01, (0x2532)                        ; F90060  d1 32 25 61
	jrl .LF8FEC6                                  ; F90064  78 5f fe
.LF90067:
	ret                                           ; F90067  0e

; ---------------------------------------------------------------------
; LCD_Pattern_NextRow -- fetch the next row's pattern byte and trim its LEFT edge
;
; Called from: LCD_Svc_14_FillRectPattern (0xF8FF27)
; Inputs:  IY = the row index, 0..8; DE = X0 mod 8, 0..7
; Outputs: IY advanced (and wrapped to 0 first if it had reached 8);
;          (0x255E) = the row's pattern byte; A = that byte with the pixels left
;          of X0 removed.  XHL clobbered.
; Evidence: `cp IY,0x0008` then `xor IY,IY` is the wrap, and the AND against
;          LCD_PatternLeftMask_Table is the same left-edge trim
;          LCD_Rect_LeftEdgeMask performs for the solid fill -- here folded into
;          the fetch because the pattern byte, unlike 0xFF, has to be kept.
; ---------------------------------------------------------------------
LCD_Pattern_NextRow:
	cp IY,0x0008                                  ; F90068  dd cf 08 00
	jr nz, .LF90070                               ; F9006C  6e 02
	xor IY,IY                                     ; F9006E  dd d5
.LF90070:
	ld XHL,0x00002538                             ; F90070  43 38 25 00 00
	.byte 0xc3, 0x07, 0xec, 0xf4, 0x21            ; F90075  c3 07 ec f4 21
	inc 1,IY                                      ; F9007A  dd 61
	stb_d8 (0x255e), a                            ; F9007C  f1 5e 25 41
	ld XHL,0x00f9008b                             ; F90080  43 8b 00 f9 00
	.byte 0xc3, 0x07, 0xec, 0xe8, 0xc1            ; F90085  c3 07 ec e8 c1
	ret                                           ; F9008A  0e

; ---------------------------------------------------------------------
; LCD_PatternLeftMask_Table -- 9 bytes: keep pixels k..7 of a byte
;
; Read by:  LCD_Pattern_NextRow (0xF90080), indexed by X0 mod 8.
; Layout:   9 bytes, 0xF9008B-0xF90093, entry k = 0xFF >> k for k = 0..8.
; Count:    fixed by the load at 0xF90080 and by 0xF90094 being
;           LCD_Pattern_RightEdgeMask's first instruction.
; ⚠ Evidence about the near-duplicate: this is LCD_LeftEdgeMask_Table
;           (0xF8F79B) with ONE of its nine bytes different -- index 0 is 0xFF
;           here and 0x00 there; the other eight are equal.  The difference is
;           required, not accidental: the solid fill calls its helper only after
;           testing X0 mod 8 for zero, so its index 0 is dead, while this helper
;           is called BEFORE that test and must return "keep all eight pixels".
;           The one-of-nine count is a check in notes/prom_a_byte_checks.py.
; ---------------------------------------------------------------------
LCD_PatternLeftMask_Table:
	.byte 0xFF			; F9008B  index 0 -- keep the whole byte
	.byte 0x7F			; F9008C  index 1
	.byte 0x3F			; F9008D  index 2
	.byte 0x1F			; F9008E  index 3
	.byte 0x0F			; F9008F  index 4
	.byte 0x07			; F90090  index 5
	.byte 0x03			; F90091  index 6
	.byte 0x01			; F90092  index 7 -- pixel 7 only
	.byte 0x00			; F90093  index 8 -- unreachable

; ---------------------------------------------------------------------
; LCD_Pattern_RightEdgeMask -- trim the box's LAST byte-column
;
; Called from: LCD_Svc_14_FillRectPattern (0xF9001A)
; Inputs:  DE = how many pixels of the last byte are inside the box, 0..7;
;          (0x255E) = the row's pattern byte.
; Outputs: (0x255E) masked down to those pixels, and A = the result.
; Evidence: instruction for instruction LCD_Dither_RightEdgeMask (0xF8FE64),
;           with a different table address -- 19 bytes each, and the ONLY
;           differing bytes are three of the four in the `ld XHL,imm` operand
;           (0xF8FE77 against 0xF900A7).  16 of 19 equal; the count is a check
;           in notes/prom_a_byte_checks.py.
; ---------------------------------------------------------------------
LCD_Pattern_RightEdgeMask:
	ld XHL,0x00f900a7                             ; F90094  43 a7 00 f9 00
	.byte 0xc3, 0x07, 0xec, 0xe8, 0x21            ; F90099  c3 07 ec e8 21
	anddm8 (0x255e), a                            ; F9009E  c1 5e 25 c9
	ldb_d8 a, (0x255e)                            ; F900A2  c1 5e 25 21
	ret                                           ; F900A6  0e

; ---------------------------------------------------------------------
; LCD_PatternRightMask_Table -- 9 bytes: keep pixels 0..k-1 of a byte
;
; Read by:  LCD_Pattern_RightEdgeMask (0xF90094).
; Layout:   9 bytes, 0xF900A7-0xF900AF, entry k = 0xFF << (8-k) for k = 0..8.
; Count:    fixed by the load at 0xF90094 and by 0xF900B0 being
;           LCD_Svc_15_DrawLineDashed's first instruction.
; ⚠ Evidence about the near-duplicate: this is LCD_RightEdgeMask_Table
;           (0xF8F7AF) and LCD_Dither_RightEdge_Table (0xF8FE77) with ONE of the
;           nine bytes different -- index 8 is 0xFF here and 0x00 in both of
;           those; the other eight are equal.  So the ROM carries this nine-byte
;           shape THREE times, in two variants.  Index 8 is unreachable in all
;           three (`div` by 8 cannot produce it), so the difference has no
;           behavioural consequence; it is recorded because the byte gate cannot
;           see it and a reader who assumed "same table" would be wrong.
; ---------------------------------------------------------------------
LCD_PatternRightMask_Table:
	.byte 0x00			; F900A7  index 0 -- unreachable
	.byte 0x80			; F900A8  index 1 -- pixel 0 only
	.byte 0xC0			; F900A9  index 2
	.byte 0xE0			; F900AA  index 3
	.byte 0xF0			; F900AB  index 4
	.byte 0xF8			; F900AC  index 5
	.byte 0xFC			; F900AD  index 6
	.byte 0xFE			; F900AE  index 7 -- pixels 0..6
	.byte 0xFF			; F900AF  index 8 -- unreachable

; ---------------------------------------------------------------------
; LCD_Svc_15_DrawLineDashed -- SWI7 service 0x15: the line draw, two pixels on
; and two off
;
; Called from: SWI7_ServiceTable slot 0x15 (0xF8EA1A)
; Inputs/Outputs: exactly LCD_Svc_00_DrawLine's -- the same four coordinate
;          words, the same clamp, the same major-axis choice, the same
;          hundredths fixed-point interpolation, the same two endpoint plots.
; Evidence: it calls the SAME five helpers in the same order --
;          LCD_ClampCoordsToPanel, LCD_Line_ChooseMajorAxis,
;          LCD_Line_ComputeIntercept, LCD_Line_PlotLowXEnd and, at the end,
;          LCD_Line_PlotHighXEnd -- and its step loop is byte-for-byte the
;          arithmetic of LCD_Svc_00__step.  What is added is a counter in IZ
;          with the same modulo-4 shape service 0x12 keeps in WA: plot when it
;          is 0 or 1, skip on 2, reset and skip on 3.
; ⚠ TWO differences from service 0x00 that are NOT the dash, both read off the
;          opcodes rather than assumed:
;          1. the loop test is `jr UGT` (0x6B) here against `jr NC` (0x6F)
;             there, so this one runs one more iteration -- it includes the
;             major coordinate that equals IY, service 0x00 stops before it;
;          2. it keeps its counter in IZ, which service 0x00 never touches.
; Unknown:  callers.  Nothing yet calls it, and no box service is built from it
;          the way 0x13 is built from 0x11 and 0x12.
; ---------------------------------------------------------------------
LCD_Svc_15_DrawLineDashed:
	calr (0xF8EE93 - 0xF900B3)                                   ; F900B0  1e e0 ed
	calr (0xF8EB6B - 0xF900B6)                                   ; F900B3  1e b5 ea
	calr (0xF8EB19 - 0xF900B9)                                   ; F900B6  1e 60 ea
	calr (0xF8EC0A - 0xF900BC)                                   ; F900B9  1e 4e eb
	calr (0xF8EC4B - 0xF900BF)                                   ; F900BC  1e 8c eb
	xor IZ,IZ                                     ; F900BF  de d6
.LF900C1:
	ld WA,IX                                      ; F900C1  dc 88
	cp WA,IY                                      ; F900C3  dd f0
	jr ugt, .LF90114                              ; F900C5  6b 4d
	cps iz, 0x02                                  ; F900C7  de da
	jr z, .LF9010E                                ; F900C9  66 43
	cps iz, 0x03                                  ; F900CB  de db
	jr nz, .LF900D3                               ; F900CD  6e 04
	xor IZ,IZ                                     ; F900CF  de d6
	jr .LF90110                                   ; F900D1  68 3d
.LF900D3:
	.byte 0xd1, 0x48, 0x25, 0x48                  ; F900D3  d1 48 25 48
	ld DE,QWA                                     ; F900D7  d7 e2 8a
	m_add_rm MW16, 0x254a, r0                     ; F900DA  d1 4a 25 80
	bit 0x0f,WA                                   ; F900DE  d8 33 0f
	jr z, .LF900E5                                ; F900E1  66 02
	neg WA                                        ; F900E3  d8 07
.LF900E5:
	add WA,0x0032                                 ; F900E5  d8 c8 32 00
	ldw bc, 0x64                                  ; F900E9  31 64 00
	exts XWA                                      ; F900EC  e8 13
	divs xwa, xbc                                 ; F900EE  d9 58
	ld DE,QWA                                     ; F900F0  d7 e2 8a
	m_bit 0, MD16, 0x2547                         ; F900F3  f1 47 25 c8
	jr nz, .LF90103                               ; F900F7  6e 0a
	stda16 (0x2552), wa                           ; F900F9  f1 52 25 50
	stda16 (0x2550), ix                           ; F900FD  f1 50 25 54
	jr .LF9010B                                   ; F90101  68 08
.LF90103:
	stda16 (0x2550), wa                           ; F90103  f1 50 25 50
	stda16 (0x2552), ix                           ; F90107  f1 52 25 54
.LF9010B:
	calr (0xF8ECCF - 0xF9010E)                                   ; F9010B  1e c1 eb
.LF9010E:
	inc 1,IZ                                      ; F9010E  de 61
.LF90110:
	inc 1,IX                                      ; F90110  dc 61
	jr .LF900C1                                   ; F90112  68 ad
.LF90114:
	calr (0xF8EC83 - 0xF90117)                                   ; F90114  1e 6c eb
	ret                                           ; F90117  0e

; ==============================================================================
; 0xF90118-0xF90988 -- SWI7 services 0x17, 0x1C and 0x1E: the two PACKED text
; services, their bit-shifting engine, and the panel SCROLL
; ==============================================================================
;
; ★ TWO MORE CHARACTER GENERATORS, AND THEY ARE ASCII.  Services 0x17 and 0x1C
;   load glyphs from bases that appear nowhere in the ten-font inventory of
;   notes/FINDINGS-fonts.md:
;
;     svc 0x17  0xF1E470   8 bytes/glyph    8 x 8   advance  6 pixels
;     svc 0x1C  0xF1EAB0  32 bytes/glyph   16 x 16  advance 11 pixels
;
;   Both pass `python3 notes/render_font.py <base> <n> --ascii-check`: one blank
;   glyph (0x20) and 94 drawn ones, with 0x41 rendering as an A and 0x39 as a 9.
;   So the machine carries SEVEN ASCII faces, not five.  The inventory in that
;   note is updated.
;
; ★ AND THESE TWO ARE THE ONLY TEXT SERVICES THAT CAN START AT ANY PIXEL.  The
;   ten services in the 0xF8F039 block blit whole bytes: a string can only begin
;   on an 8-pixel boundary and every glyph is 8 or 16 wide.  These two run every
;   glyph through TextShift_ShiftRight first, so the string starts at
;   (0x2530) exactly, and they advance by the face's real width -- 6 and 11 --
;   rather than by 8 or 16.  That is what "packed" means in the names below, and
;   it is read off two constants that agree: the advance the service adds to
;   (0x259E), and the `and W,0xe0` in TextShift_LoadGlyph16 that keeps three
;   bits of the second byte, making a row 8 + 3 = 11 wide.
;
; THE ENGINE.  Three 16-byte staging buffers in CS1 RAM, and their SIZE is fixed
; by their own addresses -- 0x257A - 0x256A = 16 and 0x258A - 0x257A = 16, and
; 0x259A is the character counter:
;
;   TextShift_BufA  (0x256A)  the byte column the glyph's left 8 pixels land in
;   TextShift_BufB  (0x257A)  the byte column its overflow lands in
;   TextShift_BufC  (0x258A)  where the previous character's overflow is parked
;
; and four 16-bit/8-bit variables:
;
;   (0x259A)  characters left to draw
;   (0x259C)  the display-RAM address of the byte column being written
;   (0x259E)  the bit offset within that byte, 0..8 -- the string's X position
;             modulo 8, advanced by the glyph width per character
;   (0x259F)  a 32-bit pointer to the current glyph's bitmap
;
; ⚠ (0x259E) IS ALLOWED TO BE 8.  The advance is `add 6` (or 11) then
;   `if > 8 subtract 8`, not `mod 8`, so a glyph that ends exactly on a byte
;   boundary leaves 8 rather than 0.  Every mask table below is 9 entries for
;   that reason, and both services special-case the index where the glyph ends
;   flush -- 2 for the 6-wide face, 5 for the 11-wide one.
;
; ⚠ WHAT IS NOT ESTABLISHED HERE: nothing calls either service in any code this
;   tree has converted, so the meaning of the HL argument (multiplied by BC once
;   into IZ, exactly as in the ten byte-aligned text services) is still open,
;   and so is which face the UI uses for what.

; ---------------------------------------------------------------------
; LCD_Svc_17_DrawText8x8Packed -- SWI7 service 0x17: a string in the 8x8 face,
; six pixels apart, starting at any pixel column
;
; Called from: SWI7_ServiceTable slot 0x17 (0xF8EA22)
; Inputs:  BC = number of characters; XIY = the string; HL = the same stride the
;          byte-aligned text services take (IZ := HL*BC, then the character code
;          is read as (XIY+IZ)); (0x2530),(0x2532) = the top-left corner in
;          PIXELS; (0x2540) selects the layer.
; Outputs: the string drawn, OR'd into the layer.  (0x259A)-(0x25A2) and all
;          three staging buffers clobbered; returns at once if BC is zero.
; Evidence: the font base 0xF1E470 and the 8-byte glyph pitch are immediates
;          (`ld W,0x08` then `mul WA,W`, then `add XIX,XHL`); the 6-pixel
;          advance is the `add (0x259e),0x06` at 0xF901F5; and
;          notes/render_font.py says the table at that base is an ASCII 8x8
;          face.  The address arithmetic is the driver's usual
;          Y*(0x2557) + X/8 + (0x2555), kept in (0x259C).
; Structure: load and shift the first glyph, then for the first character
;          either merge it into the panel directly (offset > 2, i.e. the glyph
;          spills into the next byte) or first READ the panel column into buffer
;          A and merge that (offset <= 2 -- and when this is also the LAST
;          character that whole head write is skipped); then per character, advance the
;          offset, shift, OR in the previous character's overflow, and write
;          one or two columns; finally flush whichever buffer still holds
;          pixels.  Every step is a call to one of the helpers below.
; Unknown:  callers; and the exact pixel meaning of the two tail mask tables --
;          see LCD_TextColMask_Tail8's header.
; ---------------------------------------------------------------------
LCD_Svc_17_DrawText8x8Packed:
	and BC,BC                                     ; F90118  d9 c1
	jrl z, .LF9025D                               ; F9011A  76 40 01
	ldw wa, 0x08                                  ; F9011D  30 08 00
	calr (0xF9040A - 0xF90123)                                   ; F90120  1e e7 02
	stda16 (0x259a), bc                           ; F90123  f1 9a 25 51
	calr (0xF8EE93 - 0xF9012A)                                   ; F90127  1e 69 ed
	ld WA,HL                                      ; F9012A  db 88
	mul xwa, xbc                                  ; F9012C  d9 40
	ld IZ,WA                                      ; F9012E  d8 8e
	ldw_d16 wa, (0x2532)                          ; F90130  d1 32 25 20
	ldw_d16 bc, (0x2557)                          ; F90134  d1 57 25 21
	mul xwa, xbc                                  ; F90138  d9 40
	stda16 (0x259c), wa                           ; F9013A  f1 9c 25 50
	ldw_d16 wa, (0x2530)                          ; F9013E  d1 30 25 20
	extz XWA                                      ; F90142  e8 12
	ldw bc, 0x08                                  ; F90144  31 08 00
	divs xwa, xbc                                 ; F90147  d9 58
	ld DE,QWA                                     ; F90149  d7 e2 8a
	stb_d8 (0x259e), e                            ; F9014C  f1 9e 25 45
	m_add_mr MW16, 0x259c, r0                     ; F90150  d1 9c 25 88
	ldw_d16 wa, (0x2555)                          ; F90154  d1 55 25 20
	m_add_mr MW16, 0x259c, r0                     ; F90158  d1 9c 25 88
	.byte 0xc3, 0x07, 0xf4, 0xf8, 0x21            ; F9015C  c3 07 f4 f8 21
	ldb w, 0x08                                   ; F90161  20 08
	mul8rr a, w                                   ; F90163  c8 41
	xor XHL,XHL                                   ; F90165  eb d3
	ld HL,WA                                      ; F90167  d8 8b
	ld XIX,0x00f1e470                             ; F90169  44 70 e4 f1 00
	add XIX,XHL                                   ; F9016E  eb 84
	stda32 (0x259f), xix                          ; F90170  f1 9f 25 64
	ldw bc, 0x08                                  ; F90174  31 08 00
	calr (0xF9042E - 0xF9017A)                                   ; F90177  1e b4 02
	decdi16 0x01, (0x259a)                        ; F9017A  d1 9a 25 69
	ldb d, 0x08                                   ; F9017E  24 08
	calr (0xF90477 - 0xF90183)                                   ; F90180  1e f4 02
	m_cp_mi8 MB16, 0x259e, 0x02                   ; F90183  c1 9e 25 3f 02
	jr ule, .LF901A4                              ; F90188  63 1a
	ldw bc, 0x04                                  ; F9018A  31 04 00
	calr (0xF904E4 - 0xF90190)                                   ; F9018D  1e 54 03
	calr (0xF9087E - 0xF90193)                                   ; F90190  1e eb 06
	ld XIX,0x0000256a                             ; F90193  44 6a 25 00 00
	ldw bc, 0x08                                  ; F90198  31 08 00
	calr (0xF906AA - 0xF9019E)                                   ; F9019B  1e 0c 05
	incdi16 0x01, (0x259c)                        ; F9019E  d1 9c 25 61
	jr .LF901C9                                   ; F901A2  68 25
.LF901A4:
	m_cp_mi16 MW16, 0x259a, 0x0000                ; F901A4  d1 9a 25 3f 00 00
	jr z, .LF901C9                                ; F901AA  66 1d
	calr (0xF9087E - 0xF901AF)                                   ; F901AC  1e cf 06
	ldw bc, 0x08                                  ; F901AF  31 08 00
	calr (0xF908B8 - 0xF901B5)                                   ; F901B2  1e 03 07
	ldw bc, 0x04                                  ; F901B5  31 04 00
	calr (0xF904D5 - 0xF901BB)                                   ; F901B8  1e 1a 03
	calr (0xF9087E - 0xF901BE)                                   ; F901BB  1e c0 06
	ld XIX,0x0000256a                             ; F901BE  44 6a 25 00 00
	ldw bc, 0x08                                  ; F901C3  31 08 00
	calr (0xF906AA - 0xF901C9)                                   ; F901C6  1e e1 04
.LF901C9:
	m_cp_mi16 MW16, 0x259a, 0x0000                ; F901C9  d1 9a 25 3f 00 00
	jr z, .LF9023B                                ; F901CF  66 6a
	inc 1,XIY                                     ; F901D1  ed 61
	.byte 0xc3, 0x07, 0xf4, 0xf8, 0x21            ; F901D3  c3 07 f4 f8 21
	ldb w, 0x08                                   ; F901D8  20 08
	mul8rr a, w                                   ; F901DA  c8 41
	xor XHL,XHL                                   ; F901DC  eb d3
	ld HL,WA                                      ; F901DE  d8 8b
	ld XIX,0x00f1e470                             ; F901E0  44 70 e4 f1 00
	add XIX,XHL                                   ; F901E5  eb 84
	stda32 (0x259f), xix                          ; F901E7  f1 9f 25 64
	ldw bc, 0x08                                  ; F901EB  31 08 00
	calr (0xF9042E - 0xF901F1)                                   ; F901EE  1e 3d 02
	decdi16 0x01, (0x259a)                        ; F901F1  d1 9a 25 69
	m_add_mi8 MB16, 0x259e, 0x06                  ; F901F5  c1 9e 25 38 06
	m_cp_mi8 MB16, 0x259e, 0x08                   ; F901FA  c1 9e 25 3f 08
	jr ule, .LF90206                              ; F901FF  63 05
	.byte 0xc1, 0x9e, 0x25, 0x3a, 0x08            ; F90201  c1 9e 25 3a 08
.LF90206:
	ldb d, 0x08                                   ; F90206  24 08
	calr (0xF90477 - 0xF9020B)                                   ; F90208  1e 6c 02
	ldb d, 0x08                                   ; F9020B  24 08
	calr (0xF904F3 - 0xF90210)                                   ; F9020D  1e e3 02
	m_cp_mi8 MB16, 0x259e, 0x02                   ; F90210  c1 9e 25 3f 02
	jr ule, .LF90233                              ; F90215  63 1c
	ldw bc, 0x04                                  ; F90217  31 04 00
	calr (0xF904E4 - 0xF9021D)                                   ; F9021A  1e c7 02
	ldb d, 0x08                                   ; F9021D  24 08
	calr (0xF9087E - 0xF90222)                                   ; F9021F  1e 5c 06
	ld XIX,0x0000256a                             ; F90222  44 6a 25 00 00
	ldw bc, 0x08                                  ; F90227  31 08 00
	calr (0xF90842 - 0xF9022D)                                   ; F9022A  1e 15 06
	incdi16 0x01, (0x259c)                        ; F9022D  d1 9c 25 61
	jr .LF901C9                                   ; F90231  68 96
.LF90233:
	ldw bc, 0x04                                  ; F90233  31 04 00
	calr (0xF904D5 - 0xF90239)                                   ; F90236  1e 9c 02
	jr .LF901C9                                   ; F90239  68 8e
.LF9023B:
	calr (0xF9087E - 0xF9023E)                                   ; F9023B  1e 40 06
	m_cp_mi8 MB16, 0x259e, 0x02                   ; F9023E  c1 9e 25 3f 02
	jr ule, .LF90252                              ; F90243  63 0d
	ld XIX,0x0000257a                             ; F90245  44 7a 25 00 00
	ldw bc, 0x08                                  ; F9024A  31 08 00
	calr (0xF90776 - 0xF90250)                                   ; F9024D  1e 26 05
	jr .LF9025D                                   ; F90250  68 0b
.LF90252:
	ld XIX,0x0000256a                             ; F90252  44 6a 25 00 00
	ldw bc, 0x08                                  ; F90257  31 08 00
	calr (0xF90776 - 0xF9025D)                                   ; F9025A  1e 19 05
.LF9025D:
	ret                                           ; F9025D  0e

; ---------------------------------------------------------------------
; LCD_Svc_1C_DrawText16x16Packed -- SWI7 service 0x1C: a string in the 16x16
; face, eleven pixels apart, starting at any pixel column
;
; Called from: SWI7_ServiceTable slot 0x1C (0xF8EA36)
; Inputs/Outputs: as service 0x17
; Evidence: font base 0xF1EAB0, glyph pitch `ld W,0x10` + `mul WA,W` then
;          `sla 0x01,HL` -- 16*2 = 32 bytes per glyph -- and the 11-pixel
;          advance at 0xF90367.  TextShift_LoadGlyph16's `and W,0xe0` keeps
;          exactly three bits of each row's second byte, so the face is 11
;          pixels wide, which is the same 11.  notes/render_font.py says the
;          table is ASCII 16x16.
; Notes:   it is service 0x17's shape with the 8-wide loader replaced by the
;          16-wide one, an extra left-shift pass (TextShift_ShiftLeft, with the
;          count computed as 8 - (0x259E) at the call site) and a third buffer
;          clear.  The special offset is 5 rather than 2 -- 8 - 11 modulo 8 --
;          and unlike service 0x17 the tail flush RETURNS at that offset instead
;          of writing a column.
; Unknown:  callers.
; ---------------------------------------------------------------------
LCD_Svc_1C_DrawText16x16Packed:
	and BC,BC                                     ; F9025E  d9 c1
	jrl z, .LF90409                               ; F90260  76 a6 01
	ldw wa, 0x10                                  ; F90263  30 10 00
	calr (0xF9040A - 0xF90269)                                   ; F90266  1e a1 01
	stda16 (0x259a), bc                           ; F90269  f1 9a 25 51
	calr (0xF8EE93 - 0xF90270)                                   ; F9026D  1e 23 ec
	ld WA,HL                                      ; F90270  db 88
	mul xwa, xbc                                  ; F90272  d9 40
	ld IZ,WA                                      ; F90274  d8 8e
	ldw_d16 wa, (0x2532)                          ; F90276  d1 32 25 20
	ldw_d16 bc, (0x2557)                          ; F9027A  d1 57 25 21
	mul xwa, xbc                                  ; F9027E  d9 40
	stda16 (0x259c), wa                           ; F90280  f1 9c 25 50
	ldw_d16 wa, (0x2530)                          ; F90284  d1 30 25 20
	extz XWA                                      ; F90288  e8 12
	ldw bc, 0x08                                  ; F9028A  31 08 00
	divs xwa, xbc                                 ; F9028D  d9 58
	ld DE,QWA                                     ; F9028F  d7 e2 8a
	stb_d8 (0x259e), e                            ; F90292  f1 9e 25 45
	m_add_mr MW16, 0x259c, r0                     ; F90296  d1 9c 25 88
	ldw_d16 wa, (0x2555)                          ; F9029A  d1 55 25 20
	m_add_mr MW16, 0x259c, r0                     ; F9029E  d1 9c 25 88
	.byte 0xc3, 0x07, 0xf4, 0xf8, 0x21            ; F902A2  c3 07 f4 f8 21
	ldb w, 0x10                                   ; F902A7  20 10
	mul8rr a, w                                   ; F902A9  c8 41
	xor XHL,XHL                                   ; F902AB  eb d3
	ld HL,WA                                      ; F902AD  d8 8b
	sla hl, 0x01                                  ; F902AF  db ec 01
	ld XIX,0x00f1eab0                             ; F902B2  44 b0 ea f1 00
	add XIX,XHL                                   ; F902B7  eb 84
	stda32 (0x259f), xix                          ; F902B9  f1 9f 25 64
	ldw bc, 0x10                                  ; F902BD  31 10 00
	calr (0xF90452 - 0xF902C3)                                   ; F902C0  1e 8f 01
	decdi16 0x01, (0x259a)                        ; F902C3  d1 9a 25 69
	ldb d, 0x10                                   ; F902C7  24 10
	calr (0xF90477 - 0xF902CC)                                   ; F902C9  1e ab 01
	calr (0xF9087E - 0xF902CF)                                   ; F902CC  1e af 05
	ld XIX,0x0000256a                             ; F902CF  44 6a 25 00 00
	ldw bc, 0x10                                  ; F902D4  31 10 00
	calr (0xF90512 - 0xF902DA)                                   ; F902D7  1e 38 02
	incdi16 0x01, (0x259c)                        ; F902DA  d1 9c 25 61
	m_cp_mi8 MB16, 0x259e, 0x05                   ; F902DE  c1 9e 25 3f 05
	jr ule, .LF90310                              ; F902E3  63 2b
	calr (0xF9087E - 0xF902E8)                                   ; F902E5  1e 96 05
	ld XIX,0x0000257a                             ; F902E8  44 7a 25 00 00
	ldw bc, 0x10                                  ; F902ED  31 10 00
	calr (0xF90842 - 0xF902F3)                                   ; F902F0  1e 4f 05
	incdi16 0x01, (0x259c)                        ; F902F3  d1 9c 25 61
	ldw bc, 0x10                                  ; F902F7  31 10 00
	calr (0xF90452 - 0xF902FD)                                   ; F902FA  1e 55 01
	ldb c, 0x08                                   ; F902FD  23 08
	subda8 c, (0x259e)                            ; F902FF  c1 9e 25 a3
	ldb d, 0x10                                   ; F90303  24 10
	calr (0xF904A8 - 0xF90308)                                   ; F90305  1e a0 01
	ldw bc, 0x08                                  ; F90308  31 08 00
	calr (0xF904E4 - 0xF9030E)                                   ; F9030B  1e d6 01
	jr .LF90337                                   ; F9030E  68 27
.LF90310:
	m_cp_mi8 MB16, 0x259e, 0x05                   ; F90310  c1 9e 25 3f 05
	jr nz, .LF90331                               ; F90315  6e 1a
	calr (0xF9087E - 0xF9031A)                                   ; F90317  1e 64 05
	ld XIX,0x0000257a                             ; F9031A  44 7a 25 00 00
	ldw bc, 0x10                                  ; F9031F  31 10 00
	calr (0xF90842 - 0xF90325)                                   ; F90322  1e 1d 05
	incdi16 0x01, (0x259c)                        ; F90325  d1 9c 25 61
	ldw wa, 0x08                                  ; F90329  30 08 00
	calr (0xF9041C - 0xF9032F)                                     ; F9032C  1e ed 00
	jr .LF90337                                   ; F9032F  68 06
.LF90331:
	ldw bc, 0x08                                  ; F90331  31 08 00
	calr (0xF904E4 - 0xF90337)                                   ; F90334  1e ad 01
.LF90337:
	m_cp_mi16 MW16, 0x259a, 0x0000                ; F90337  d1 9a 25 3f 00 00
	jrl z, .LF903F4                               ; F9033D  76 b4 00
	inc 1,XIY                                     ; F90340  ed 61
	.byte 0xc3, 0x07, 0xf4, 0xf8, 0x21            ; F90342  c3 07 f4 f8 21
	ldb w, 0x10                                   ; F90347  20 10
	mul8rr a, w                                   ; F90349  c8 41
	xor XHL,XHL                                   ; F9034B  eb d3
	ld HL,WA                                      ; F9034D  d8 8b
	sla hl, 0x01                                  ; F9034F  db ec 01
	ld XIX,0x00f1eab0                             ; F90352  44 b0 ea f1 00
	add XIX,XHL                                   ; F90357  eb 84
	stda32 (0x259f), xix                          ; F90359  f1 9f 25 64
	ldw bc, 0x10                                  ; F9035D  31 10 00
	calr (0xF90452 - 0xF90363)                                     ; F90360  1e ef 00
	decdi16 0x01, (0x259a)                        ; F90363  d1 9a 25 69
	m_add_mi8 MB16, 0x259e, 0x0b                  ; F90367  c1 9e 25 38 0b
.LF9036C:
	m_cp_mi8 MB16, 0x259e, 0x08                   ; F9036C  c1 9e 25 3f 08
	jr c, .LF9037A                                ; F90371  67 07
	.byte 0xc1, 0x9e, 0x25, 0x3a, 0x08            ; F90373  c1 9e 25 3a 08
	jr .LF9036C                                   ; F90378  68 f2
.LF9037A:
	ldb d, 0x10                                   ; F9037A  24 10
	calr (0xF90477 - 0xF9037F)                                     ; F9037C  1e f8 00
	ldb d, 0x10                                   ; F9037F  24 10
	calr (0xF904F3 - 0xF90384)                                   ; F90381  1e 6f 01
	calr (0xF9087E - 0xF90387)                                   ; F90384  1e f7 04
	ld XIX,0x0000256a                             ; F90387  44 6a 25 00 00
	ldw bc, 0x10                                  ; F9038C  31 10 00
	calr (0xF90842 - 0xF90392)                                   ; F9038F  1e b0 04
	incdi16 0x01, (0x259c)                        ; F90392  d1 9c 25 61
	m_cp_mi8 MB16, 0x259e, 0x05                   ; F90396  c1 9e 25 3f 05
	jr ule, .LF903C9                              ; F9039B  63 2c
	calr (0xF9087E - 0xF903A0)                                   ; F9039D  1e de 04
	ld XIX,0x0000257a                             ; F903A0  44 7a 25 00 00
	ldw bc, 0x10                                  ; F903A5  31 10 00
	calr (0xF90842 - 0xF903AB)                                   ; F903A8  1e 97 04
	incdi16 0x01, (0x259c)                        ; F903AB  d1 9c 25 61
	ldw bc, 0x10                                  ; F903AF  31 10 00
	calr (0xF90452 - 0xF903B5)                                     ; F903B2  1e 9d 00
	ldb c, 0x08                                   ; F903B5  23 08
	subda8 c, (0x259e)                            ; F903B7  c1 9e 25 a3
	ldb d, 0x10                                   ; F903BB  24 10
	calr (0xF904A8 - 0xF903C0)                                     ; F903BD  1e e8 00
	ldw bc, 0x08                                  ; F903C0  31 08 00
	calr (0xF904E4 - 0xF903C6)                                   ; F903C3  1e 1e 01
	jrl .LF90337                                  ; F903C6  78 6e ff
.LF903C9:
	m_cp_mi8 MB16, 0x259e, 0x05                   ; F903C9  c1 9e 25 3f 05
	jr nz, .LF903EB                               ; F903CE  6e 1b
	calr (0xF9087E - 0xF903D3)                                   ; F903D0  1e ab 04
	ld XIX,0x0000257a                             ; F903D3  44 7a 25 00 00
	ldw bc, 0x10                                  ; F903D8  31 10 00
	calr (0xF90842 - 0xF903DE)                                   ; F903DB  1e 64 04
	incdi16 0x01, (0x259c)                        ; F903DE  d1 9c 25 61
	ldw wa, 0x08                                  ; F903E2  30 08 00
	calr (0xF9041C - 0xF903E8)                                     ; F903E5  1e 34 00
	jrl .LF90337                                  ; F903E8  78 4c ff
.LF903EB:
	ldw bc, 0x08                                  ; F903EB  31 08 00
	calr (0xF904E4 - 0xF903F1)                                     ; F903EE  1e f3 00
	jrl .LF90337                                  ; F903F1  78 43 ff
.LF903F4:
	m_cp_mi8 MB16, 0x259e, 0x05                   ; F903F4  c1 9e 25 3f 05
	jr z, .LF90409                                ; F903F9  66 0e
	calr (0xF9087E - 0xF903FE)                                   ; F903FB  1e 80 04
	ld XIX,0x0000258a                             ; F903FE  44 8a 25 00 00
	ldw bc, 0x10                                  ; F90403  31 10 00
	calr (0xF905DE - 0xF90409)                                   ; F90406  1e d5 01
.LF90409:
	ret                                           ; F90409  0e

; ---------------------------------------------------------------------
; TextShift_ClearBufA -- zero WA words of the first staging buffer
;
; Called from: svc 0x17 at 0xF90120 (WA = 8, so 16 bytes = buffer A) and
;          svc 0x1C at 0xF90266 (WA = 16, so 32 bytes = buffers A AND B)
; Inputs:  WA = the number of 16-bit words to zero
; Outputs: (0x256A) onward zeroed; BC preserved, WA = 0
; Evidence: `ld XIX,0x0000256a` then `ld (XIX+),WA` -- a WORD store with
;          post-increment, so WA words is 2*WA bytes.  Service 0x1C asking for
;          32 bytes is not a mistake: its 16-wide glyphs use A and B together
;          and the two buffers are adjacent.
; Notes:   TextShift_ClearBufC (below) is the same 18 bytes with ONE byte
;          different, the low byte of that immediate.
; ---------------------------------------------------------------------
TextShift_ClearBufA:
	pushw bc                                      ; F9040A  29
	ld BC,WA                                      ; F9040B  d8 89
	xor WA,WA                                     ; F9040D  d8 d0
	ld XIX,0x0000256a                             ; F9040F  44 6a 25 00 00
.LF90414:
	stw_dpi wa, 0xf1                              ; F90414  f5 f1 50
	djnz16 bc, .LF90414                           ; F90417  d9 1c fa
	popw bc                                       ; F9041A  49
	ret                                           ; F9041B  0e

; ---------------------------------------------------------------------
; TextShift_ClearBufC -- zero WA words of the third staging buffer
;
; Called from: svc 0x1C at 0xF9032C and 0xF903E5, both with WA = 8 (16 bytes)
; Inputs:  WA = the number of 16-bit words to zero
; Outputs: (0x258A) onward zeroed; BC preserved (pushed), WA = 0
; Evidence: `ld XIX,0x0000258a` and a `ld (XIX+),WA` post-increment store loop.
; ---------------------------------------------------------------------
TextShift_ClearBufC:
	pushw bc                                      ; F9041C  29
	ld BC,WA                                      ; F9041D  d8 89
	xor WA,WA                                     ; F9041F  d8 d0
	ld XIX,0x0000258a                             ; F90421  44 8a 25 00 00
.LF90426:
	stw_dpi wa, 0xf1                              ; F90426  f5 f1 50
	djnz16 bc, .LF90426                           ; F90429  d9 1c fa
	popw bc                                       ; F9042C  49
	ret                                           ; F9042D  0e

; ---------------------------------------------------------------------
; TextShift_LoadGlyph8 -- copy BC one-byte glyph rows into buffer A, zero B
;
; Called from: LCD_Svc_17_DrawText8x8Packed (0xF90177, 0xF901EE), BC = 8
; Inputs:  BC = rows; (0x259F) = a 32-bit pointer to the glyph's first byte
; Outputs: TextShift_BufA[i] = glyph[i] and TextShift_BufB[i] = 0 for i < BC.
;          XHL and XIY saved and restored.
; Evidence: one byte read per row (`ld A,(XIY)` + `inc 1,XIY`) against
;          TextShift_LoadGlyph16's word read -- this is the 8-wide loader.
; ---------------------------------------------------------------------
TextShift_LoadGlyph8:
	push XHL                                      ; F9042E  3b
	push XIY                                      ; F9042F  3d
	xor WA,WA                                     ; F90430  d8 d0
	ld XHL,0x0000257a                             ; F90432  43 7a 25 00 00
	ld XIX,0x0000256a                             ; F90437  44 6a 25 00 00
	ldda32 xiy, (0x259f)                          ; F9043C  e1 9f 25 25
.LF90440:
	ld A,(XIY)                                    ; F90440  85 21
	ld (XIX),A                                    ; F90442  b4 41
	ld (XHL),W                                    ; F90444  b3 40
	inc 1,XIY                                     ; F90446  ed 61
	inc 1,XIX                                     ; F90448  ec 61
	inc 1,XHL                                     ; F9044A  eb 61
	djnz16 bc, .LF90440                           ; F9044C  d9 1c f1
	pop XIY                                       ; F9044F  5d
	pop XHL                                       ; F90450  5b
	ret                                           ; F90451  0e

; ---------------------------------------------------------------------
; TextShift_LoadGlyph16 -- copy BC two-byte glyph rows into buffers A and B
;
; Called from: LCD_Svc_1C_DrawText16x16Packed (four sites), BC = 16
; Inputs:  BC = rows; (0x259F) = a 32-bit pointer to the glyph
; Outputs: TextShift_BufA[i] = the row's FIRST byte, TextShift_BufB[i] = its
;          SECOND byte ANDed with 0xE0, for i < BC.
; Evidence: ★ THE 0xE0 IS WHAT FIXES THE GLYPH WIDTH AT 11.  It keeps three
;          bits of the second byte and throws the other five away, so a row is
;          8 + 3 = 11 pixels wide -- and 11 is exactly the advance
;          LCD_Svc_1C_DrawText16x16Packed adds to (0x259E) per character
;          (`add (0x259e),0x0b`).  Two independent constants agreeing.
; ---------------------------------------------------------------------
TextShift_LoadGlyph16:
	push XHL                                      ; F90452  3b
	push XIY                                      ; F90453  3d
	ld XHL,0x0000257a                             ; F90454  43 7a 25 00 00
	ld XIX,0x0000256a                             ; F90459  44 6a 25 00 00
	ldda32 xiy, (0x259f)                          ; F9045E  e1 9f 25 25
.LF90462:
	ld WA,(XIY)                                   ; F90462  95 20
	ld (XIX),A                                    ; F90464  b4 41
	and W,0xe0                                    ; F90466  c8 cc e0
	ld (XHL),W                                    ; F90469  b3 40
	inc 2,XIY                                     ; F9046B  ed 62
	inc 1,XIX                                     ; F9046D  ec 61
	inc 1,XHL                                     ; F9046F  eb 61
	djnz16 bc, .LF90462                           ; F90471  d9 1c ee
	pop XIY                                       ; F90474  5d
	pop XHL                                       ; F90475  5b
	ret                                           ; F90476  0e

; ---------------------------------------------------------------------
; TextShift_ShiftRight -- shift the (A,B) row pairs right by (0x259E) bits
;
; Called from: both packed-text services, four sites, with D = 8 or 16
; Inputs:  D = rows; (0x259E) = the shift count, 0..8
; Outputs: for each row, the 16-bit value (BufA[i] << 8 | BufB[i]) shifted right
;          by that count and stored back.  XIY saved and restored.
; Evidence: ★ THIS IS WHAT MAKES THE PACKED TEXT SERVICES SUB-BYTE.  The pair of
;          buffers is loaded into BC as (B = BufA[i], C = BufB[i]) -- the high
;          byte from A -- and shifted with the register-count `srl A,BC` form,
;          then written back the same way round.  A glyph can therefore start at
;          ANY pixel column, which is what services 0x06/0x07/0x08 and the rest
;          of the text family cannot do: they blit whole bytes.
; Notes:   the shift is skipped when the count is zero, because the TLCS-900
;          shift-by-a-register forms shift by 16 when the count byte is 0
;          (the `cp A,0` / `jr Z` before it) -- MAME's core computes
;          `count = (s & 0x0f) ? (s & 0x0f) : 16`
;          (../mame/src/devices/cpu/tlcs900/900tbl.hxx:1104-1106).
;          Both shift instructions are the
;          `cb ff` / `cb fc` register-count encodings llvm-mc cannot spell, so
;          they stay as .byte with unidasm's text beside them.
; ---------------------------------------------------------------------
TextShift_ShiftRight:
	push XIY                                      ; F90477  3d
	ld XIY,0x0000256a                             ; F90478  45 6a 25 00 00
	ld XIX,0x0000257a                             ; F9047D  44 7a 25 00 00
	xor E,E                                       ; F90482  cd d5
	ldb_d8 c, (0x259e)                            ; F90484  c1 9e 25 23
.LF90488:
	cp E,D                                        ; F90488  cc f5
	jr nc, .LF904A6                               ; F9048A  6f 1a
	ld W,(XIY)                                    ; F9048C  85 20
	ld A,(XIX)                                    ; F9048E  84 21
	ex16 wa, bc                                   ; F90490  d9 b8
	cps a, 0x00                                   ; F90492  c9 d8
	jr z, .LF90498                                ; F90494  66 02
	.byte 0xd9, 0xff                              ; F90496  d9 ff
.LF90498:
	ex16 wa, bc                                   ; F90498  d9 b8
	ld (XIY),W                                    ; F9049A  b5 40
	ld (XIX),A                                    ; F9049C  b4 41
	inc 1,XIY                                     ; F9049E  ed 61
	inc 1,XIX                                     ; F904A0  ec 61
	inc 1,E                                       ; F904A2  cd 61
	jr .LF90488                                   ; F904A4  68 e2
.LF904A6:
	pop XIY                                       ; F904A6  5d
	ret                                           ; F904A7  0e

; ---------------------------------------------------------------------
; TextShift_ShiftLeft -- shift the (A,B) row pairs LEFT by C bits
;
; Called from: LCD_Svc_1C_DrawText16x16Packed (0xF90305, 0xF903BD), both times
;          with C = 8 - (0x259E), computed at the call site
; Inputs:  D = rows; C = the shift count
; Outputs: as TextShift_ShiftRight but leftward.
; Evidence: instruction for instruction TextShift_ShiftRight with `sla A,BC`
;          (0xcb 0xfc) instead of `srl A,BC` (0xcb 0xff) and without the
;          `ld C,(0x259e)` that fetches the count -- 45 bytes against 49, the
;          four being that load.  The count comes from the caller instead.
; ---------------------------------------------------------------------
TextShift_ShiftLeft:
	push XIY                                      ; F904A8  3d
	ld XIY,0x0000256a                             ; F904A9  45 6a 25 00 00
	ld XIX,0x0000257a                             ; F904AE  44 7a 25 00 00
	xor E,E                                       ; F904B3  cd d5
.LF904B5:
	cp E,D                                        ; F904B5  cc f5
	jr nc, .LF904D3                               ; F904B7  6f 1a
	ld W,(XIY)                                    ; F904B9  85 20
	ld A,(XIX)                                    ; F904BB  84 21
	ex16 wa, bc                                   ; F904BD  d9 b8
	cps a, 0x00                                   ; F904BF  c9 d8
	jr z, .LF904C5                                ; F904C1  66 02
	.byte 0xd9, 0xfc                              ; F904C3  d9 fc
.LF904C5:
	ex16 wa, bc                                   ; F904C5  d9 b8
	ld (XIY),W                                    ; F904C7  b5 40
	ld (XIX),A                                    ; F904C9  b4 41
	inc 1,XIY                                     ; F904CB  ed 61
	inc 1,XIX                                     ; F904CD  ec 61
	inc 1,E                                       ; F904CF  cd 61
	jr .LF904B5                                   ; F904D1  68 e2
.LF904D3:
	pop XIY                                       ; F904D3  5d
	ret                                           ; F904D4  0e

; ---------------------------------------------------------------------
; TextShift_CopyAtoC -- copy BC words of buffer A into buffer C
;
; Called from: svc 0x17 (0xF901B8) and svc 0x1C (0xF90236), BC = 4 and 8
; Inputs:  BC = words (so 8 or 16 bytes)
; Outputs: (0x258A..) = (0x256A..)
; Evidence: a single `ldirw` between the two immediates.
; ---------------------------------------------------------------------
TextShift_CopyAtoC:
	push XIY                                      ; F904D5  3d
	ld XIY,0x0000256a                             ; F904D6  45 6a 25 00 00
	ld XIX,0x0000258a                             ; F904DB  44 8a 25 00 00
	ldirw                                         ; F904E0  95 11
	pop XIY                                       ; F904E2  5d
	ret                                           ; F904E3  0e

; ---------------------------------------------------------------------
; TextShift_CopyBtoC -- copy BC words of buffer B into buffer C
;
; Called from: six sites across both services, BC = 4 or 8
; Inputs:  BC = words
; Outputs: (0x258A..) = (0x257A..)
; Evidence: TextShift_CopyAtoC with 0x256A replaced by 0x257A -- 15 bytes each
;          and exactly one differing byte, the low byte of that immediate.
; ---------------------------------------------------------------------
TextShift_CopyBtoC:
	push XIY                                      ; F904E4  3d
	ld XIY,0x0000257a                             ; F904E5  45 7a 25 00 00
	ld XIX,0x0000258a                             ; F904EA  44 8a 25 00 00
	ldirw                                         ; F904EF  95 11
	pop XIY                                       ; F904F1  5d
	ret                                           ; F904F2  0e

; ---------------------------------------------------------------------
; TextShift_OrCintoA -- OR buffer C into buffer A, D rows
;
; Called from: svc 0x17 (0xF9020D) and svc 0x1C (0xF90381), D = 8 and 16
; Inputs:  D = rows
; Outputs: TextShift_BufA[i] |= TextShift_BufC[i]
; Evidence: the two buffer bases are literal -- `ld XIY,0x0000256A` (buffer A)
;          at 0xF904F4 and `ld XIX,0x0000258A` (buffer C) at 0xF904F9 -- and
;          the loop body is `ld A,(XIX) / or (XIY),A` at 0xF90504/0xF90506, a
;          memory-DESTINATION or, so the result lands in A and C is only read.
;          That is the name. The buffer identities come from
;          notes/prom_a_byte_checks.py ("TextShift buffers: 0x256A, 0x257A,
;          0x258A, then 0x259A -- 16 bytes each"), and the same script now
;          pins that this routine has exactly the two callers named above.
;          ⚠ what the merge MEANS is the reading in Notes, taken from the call
;          order.
; Notes:   this is how the PREVIOUS character's overflow -- parked in C by
;          TextShift_CopyBtoC -- is merged into the byte column the NEXT
;          character starts in.  That reading comes from the call order in the
;          two services, not from this routine alone.
; ---------------------------------------------------------------------
TextShift_OrCintoA:
	push XIY                                      ; F904F3  3d
	ld XIY,0x0000256a                             ; F904F4  45 6a 25 00 00
	ld XIX,0x0000258a                             ; F904F9  44 8a 25 00 00
	xor E,E                                       ; F904FE  cd d5
.LF90500:
	cp E,D                                        ; F90500  cc f5
	jr nc, .LF90510                               ; F90502  6f 0c
	ld A,(XIX)                                    ; F90504  84 21
	or (XIY),A                                    ; F90506  85 e9
	inc 1,XIY                                     ; F90508  ed 61
	inc 1,XIX                                     ; F9050A  ec 61
	inc 1,E                                       ; F9050C  cd 61
	jr .LF90500                                   ; F9050E  68 f0
.LF90510:
	pop XIY                                       ; F90510  5d
	ret                                           ; F90511  0e

; ---------------------------------------------------------------------
; LCD_TextCol_MergeHead16 -- write a buffer down one byte-column, merging each
; byte with what is already on the panel
;
; Called from: LCD_Svc_1C_DrawText16x16Packed (0xF902D7) and nowhere else.
;          ⚠ That negative is a SEARCH: notes/prom_a_byte_checks.py re-derives
;          it from every 24-bit little-endian address in prom_a + prom_b and
;          every PC-relative displacement in prom_a.
; Inputs:  BC = rows; XIX = the source buffer; (0x259E) = the bit offset, used
;          by the mask fetcher below; (0x255A) is scratch.
; Outputs: BC display bytes written, each one
;              (what was there AND LCD_TextColMask_Head16[(0x259E)])
;              OR (the buffer byte)
;          IZ saved and restored.
; Evidence: the controller has no read-modify-write, so per row this issues
;          CSRR (0x47) and reads the cursor address back into (0x255A), MREAD
;          (0x43) and reads the byte, masks it, CSRW (0x46) to put the cursor
;          back where the read left it, CSRDIR DOWN (0x4F), MWRITE (0x42), and
;          writes the merged byte.  Six commands per byte -- the same dance
;          LCD_PlotPointAt does for one pixel.
;
; ★ THIS ROUTINE EXISTS FOUR TIMES, AND THREE OF THE FOUR COPIES ARE THE SAME
;   172 BYTES.  LCD_TextCol_MergeTail16 (0xF905DE) and LCD_TextCol_MergeTail8
;   (0xF90776) are byte-for-byte IDENTICAL to this one -- 172 of 172, checked by
;   notes/prom_a_byte_checks.py, not by eye.  They behave differently only
;   because each one's `calr` to its mask fetcher has the same displacement
;   (0x005A) and each fetcher sits immediately after its own copy, so identical
;   code reaches four different tables.  LCD_TextCol_MergeHead8 (0xF906AA) is
;   the fourth copy and differs in exactly THIRTEEN bytes, offsets 154-166: the
;   same thirteen bytes -- `inc 1,IZ`, the nine-byte BUSY poll and `ld (XHL),A`
;   -- in a different order, the increment after the write instead of before.
; ---------------------------------------------------------------------
LCD_TextCol_MergeHead16:
	pushw iz                                      ; F90512  2e
	ld XHL,0x00790000                             ; F90513  43 00 00 79 00
	xor IZ,IZ                                     ; F90518  de d6
.LF9051A:
	cp IZ,BC                                      ; F9051A  d9 f6
	jrl nc, .LF905BC                              ; F9051C  7f 9d 00
	bit_dd8 0x00, 0xc6                            ; F9051F  f0 c6 c8
	jr nz, .LF90528                               ; F90522  6e 04
.LF90524:
	bit 6,(XHL)                                   ; F90524  b3 ce
	jr nz, .LF90524                               ; F90526  6e fc
.LF90528:
	ld (XHL+0x01),0x47                            ; F90528  bb 01 00 47
	bit_dd8 0x00, 0xc6                            ; F9052C  f0 c6 c8
	jr nz, .LF90535                               ; F9052F  6e 04
.LF90531:
	bit 6,(XHL)                                   ; F90531  b3 ce
	jr nz, .LF90531                               ; F90533  6e fc
.LF90535:
	ld A,(XHL+0x01)                               ; F90535  8b 01 21
	bit_dd8 0x00, 0xc6                            ; F90538  f0 c6 c8
	jr nz, .LF90541                               ; F9053B  6e 04
.LF9053D:
	bit 6,(XHL)                                   ; F9053D  b3 ce
	jr nz, .LF9053D                               ; F9053F  6e fc
.LF90541:
	ld W,(XHL+0x01)                               ; F90541  8b 01 20
	stda16 (0x255a), wa                           ; F90544  f1 5a 25 50
	bit_dd8 0x00, 0xc6                            ; F90548  f0 c6 c8
	jr nz, .LF90551                               ; F9054B  6e 04
.LF9054D:
	bit 6,(XHL)                                   ; F9054D  b3 ce
	jr nz, .LF9054D                               ; F9054F  6e fc
.LF90551:
	ld (XHL+0x01),0x43                            ; F90551  bb 01 00 43
	bit_dd8 0x00, 0xc6                            ; F90555  f0 c6 c8
	jr nz, .LF9055E                               ; F90558  6e 04
.LF9055A:
	bit 6,(XHL)                                   ; F9055A  b3 ce
	jr nz, .LF9055A                               ; F9055C  6e fc
.LF9055E:
	ld E,(XHL+0x01)                               ; F9055E  8b 01 25
	calr .LF905BE                                 ; F90561  1e 5a 00
	bit_dd8 0x00, 0xc6                            ; F90564  f0 c6 c8
	jr nz, .LF9056D                               ; F90567  6e 04
.LF90569:
	bit 6,(XHL)                                   ; F90569  b3 ce
	jr nz, .LF90569                               ; F9056B  6e fc
.LF9056D:
	ld (XHL+0x01),0x46                            ; F9056D  bb 01 00 46
	ldw_d16 wa, (0x255a)                          ; F90571  d1 5a 25 20
	bit_dd8 0x00, 0xc6                            ; F90575  f0 c6 c8
	jr nz, .LF9057E                               ; F90578  6e 04
.LF9057A:
	bit 6,(XHL)                                   ; F9057A  b3 ce
	jr nz, .LF9057A                               ; F9057C  6e fc
.LF9057E:
	ld (XHL),A                                    ; F9057E  b3 41
	bit_dd8 0x00, 0xc6                            ; F90580  f0 c6 c8
	jr nz, .LF90589                               ; F90583  6e 04
.LF90585:
	bit 6,(XHL)                                   ; F90585  b3 ce
	jr nz, .LF90585                               ; F90587  6e fc
.LF90589:
	ld (XHL),W                                    ; F90589  b3 40
	bit_dd8 0x00, 0xc6                            ; F9058B  f0 c6 c8
	jr nz, .LF90594                               ; F9058E  6e 04
.LF90590:
	bit 6,(XHL)                                   ; F90590  b3 ce
	jr nz, .LF90590                               ; F90592  6e fc
.LF90594:
	ld (XHL+0x01),0x4f                            ; F90594  bb 01 00 4f
	bit_dd8 0x00, 0xc6                            ; F90598  f0 c6 c8
	jr nz, .LF905A1                               ; F9059B  6e 04
.LF9059D:
	bit 6,(XHL)                                   ; F9059D  b3 ce
	jr nz, .LF9059D                               ; F9059F  6e fc
.LF905A1:
	ld (XHL+0x01),0x42                            ; F905A1  bb 01 00 42
	.byte 0xc3, 0x07, 0xf0, 0xf8, 0x21            ; F905A5  c3 07 f0 f8 21
	or A,E                                        ; F905AA  cd e1
	inc 1,IZ                                      ; F905AC  de 61
	bit_dd8 0x00, 0xc6                            ; F905AE  f0 c6 c8
	jr nz, .LF905B7                               ; F905B1  6e 04
.LF905B3:
	bit 6,(XHL)                                   ; F905B3  b3 ce
	jr nz, .LF905B3                               ; F905B5  6e fc
.LF905B7:
	ld (XHL),A                                    ; F905B7  b3 41
	jrl .LF9051A                                  ; F905B9  78 5e ff
.LF905BC:
	popw iz                                       ; F905BC  4e
	ret                                           ; F905BD  0e
.LF905BE:

; ---------------------------------------------------------------------
; LCD_TextColMask_Head16_Fetch -- E &= LCD_TextColMask_Head16[(0x259E)]
;
; Called from: LCD_TextCol_MergeHead16 (0xF90561)
; Inputs:  E = the byte just MREAD off the panel; (0x259E) = the bit offset, 0..8
; Outputs: E masked; A = the mask.  XHL and XIX saved and restored.
; Evidence: the table address is the literal in `ld XIX,0x00F905D5` at 0xF905C6
;          and the index is `ld L,(0x259E)` at 0xF905C0, so "E &=
;          Head16[(0x259E)]" is those two instructions plus the AND that
;          follows them. The four-copies claim is a MEASUREMENT, not an
;          impression: notes/prom_a_byte_checks.py asserts each fetcher is 23
;          bytes and that each differs from this one in exactly two bytes,
;          offsets 9 and 10. The same script pins this copy's single caller.
; Notes:   this routine also exists four times.  All four are 23 bytes and any
;          two of them differ in exactly TWO bytes -- offsets 9 and 10, the low
;          and middle bytes of the `ld XIX,imm32` that names the table.  Checked
;          by notes/prom_a_byte_checks.py.
; ---------------------------------------------------------------------
LCD_TextColMask_Head16_Fetch:
	push XHL                                      ; F905BE  3b
	push XIX                                      ; F905BF  3c
	ldb_d8 l, (0x259e)                            ; F905C0  c1 9e 25 27
	xor H,H                                       ; F905C4  ce d6
	ld XIX,0x00f905d5                             ; F905C6  44 d5 05 f9 00
	.byte 0xc3, 0x07, 0xf0, 0xec, 0x21            ; F905CB  c3 07 f0 ec 21
	and E,A                                       ; F905D0  c9 c5
	pop XIX                                       ; F905D2  5c
	pop XHL                                       ; F905D3  5b
	ret                                           ; F905D4  0e

; ---------------------------------------------------------------------
; LCD_TextColMask_Head16 -- 9 bytes: keep pixels 0..k-1, i.e. 0xFF << (8-k)
;
; Read by:  LCD_TextColMask_Head16_Fetch (0xF905C6), indexed by (0x259E), 0..8.
; Layout:   9 bytes, 0xF905D5-0xF905DD; 0xF905DE is LCD_TextCol_MergeTail16's
;           first instruction, which is what fixes the length.
; Evidence: entry k = 0xFF << (8-k) for every k = 0..8, so the mask preserves
;           the pixels to the LEFT of where the string starts -- which is
;           exactly what the FIRST byte-column of a string needs.  The same nine
;           bytes appear at 0xF9076D (LCD_TextColMask_Head8) and at 0xF900A7
;           (LCD_PatternRightMask_Table): three byte-identical copies, and two
;           more nine-byte tables at 0xF8F7AF and 0xF8FE77 that differ from them
;           in one entry (index 8).  All five comparisons are checks in
;           notes/prom_a_byte_checks.py.
; ---------------------------------------------------------------------
LCD_TextColMask_Head16:
	.byte 0x00			; F905D5  index 0
	.byte 0x80			; F905D6  index 1
	.byte 0xC0			; F905D7  index 2
	.byte 0xE0			; F905D8  index 3
	.byte 0xF0			; F905D9  index 4
	.byte 0xF8			; F905DA  index 5
	.byte 0xFC			; F905DB  index 6
	.byte 0xFE			; F905DC  index 7
	.byte 0xFF			; F905DD  index 8

; ---------------------------------------------------------------------
; LCD_TextCol_MergeTail16 -- byte-for-byte LCD_TextCol_MergeHead16, reaching
; LCD_TextColMask_Tail16 instead
;
; Called from: LCD_Svc_1C_DrawText16x16Packed (0xF90406) and nowhere else
; Evidence: all 172 bytes equal to the copy at 0xF90512 -- the two differ only
;          in WHERE they sit, because each one's mask fetcher follows it at the
;          same displacement.  Checked by notes/prom_a_byte_checks.py.
; ---------------------------------------------------------------------
LCD_TextCol_MergeTail16:
	pushw iz                                      ; F905DE  2e
	ld XHL,0x00790000                             ; F905DF  43 00 00 79 00
	xor IZ,IZ                                     ; F905E4  de d6
.LF905E6:
	cp IZ,BC                                      ; F905E6  d9 f6
	jrl nc, .LF90688                              ; F905E8  7f 9d 00
	bit_dd8 0x00, 0xc6                            ; F905EB  f0 c6 c8
	jr nz, .LF905F4                               ; F905EE  6e 04
.LF905F0:
	bit 6,(XHL)                                   ; F905F0  b3 ce
	jr nz, .LF905F0                               ; F905F2  6e fc
.LF905F4:
	ld (XHL+0x01),0x47                            ; F905F4  bb 01 00 47
	bit_dd8 0x00, 0xc6                            ; F905F8  f0 c6 c8
	jr nz, .LF90601                               ; F905FB  6e 04
.LF905FD:
	bit 6,(XHL)                                   ; F905FD  b3 ce
	jr nz, .LF905FD                               ; F905FF  6e fc
.LF90601:
	ld A,(XHL+0x01)                               ; F90601  8b 01 21
	bit_dd8 0x00, 0xc6                            ; F90604  f0 c6 c8
	jr nz, .LF9060D                               ; F90607  6e 04
.LF90609:
	bit 6,(XHL)                                   ; F90609  b3 ce
	jr nz, .LF90609                               ; F9060B  6e fc
.LF9060D:
	ld W,(XHL+0x01)                               ; F9060D  8b 01 20
	stda16 (0x255a), wa                           ; F90610  f1 5a 25 50
	bit_dd8 0x00, 0xc6                            ; F90614  f0 c6 c8
	jr nz, .LF9061D                               ; F90617  6e 04
.LF90619:
	bit 6,(XHL)                                   ; F90619  b3 ce
	jr nz, .LF90619                               ; F9061B  6e fc
.LF9061D:
	ld (XHL+0x01),0x43                            ; F9061D  bb 01 00 43
	bit_dd8 0x00, 0xc6                            ; F90621  f0 c6 c8
	jr nz, .LF9062A                               ; F90624  6e 04
.LF90626:
	bit 6,(XHL)                                   ; F90626  b3 ce
	jr nz, .LF90626                               ; F90628  6e fc
.LF9062A:
	ld E,(XHL+0x01)                               ; F9062A  8b 01 25
	calr .LF9068A                                 ; F9062D  1e 5a 00
	bit_dd8 0x00, 0xc6                            ; F90630  f0 c6 c8
	jr nz, .LF90639                               ; F90633  6e 04
.LF90635:
	bit 6,(XHL)                                   ; F90635  b3 ce
	jr nz, .LF90635                               ; F90637  6e fc
.LF90639:
	ld (XHL+0x01),0x46                            ; F90639  bb 01 00 46
	ldw_d16 wa, (0x255a)                          ; F9063D  d1 5a 25 20
	bit_dd8 0x00, 0xc6                            ; F90641  f0 c6 c8
	jr nz, .LF9064A                               ; F90644  6e 04
.LF90646:
	bit 6,(XHL)                                   ; F90646  b3 ce
	jr nz, .LF90646                               ; F90648  6e fc
.LF9064A:
	ld (XHL),A                                    ; F9064A  b3 41
	bit_dd8 0x00, 0xc6                            ; F9064C  f0 c6 c8
	jr nz, .LF90655                               ; F9064F  6e 04
.LF90651:
	bit 6,(XHL)                                   ; F90651  b3 ce
	jr nz, .LF90651                               ; F90653  6e fc
.LF90655:
	ld (XHL),W                                    ; F90655  b3 40
	bit_dd8 0x00, 0xc6                            ; F90657  f0 c6 c8
	jr nz, .LF90660                               ; F9065A  6e 04
.LF9065C:
	bit 6,(XHL)                                   ; F9065C  b3 ce
	jr nz, .LF9065C                               ; F9065E  6e fc
.LF90660:
	ld (XHL+0x01),0x4f                            ; F90660  bb 01 00 4f
	bit_dd8 0x00, 0xc6                            ; F90664  f0 c6 c8
	jr nz, .LF9066D                               ; F90667  6e 04
.LF90669:
	bit 6,(XHL)                                   ; F90669  b3 ce
	jr nz, .LF90669                               ; F9066B  6e fc
.LF9066D:
	ld (XHL+0x01),0x42                            ; F9066D  bb 01 00 42
	.byte 0xc3, 0x07, 0xf0, 0xf8, 0x21            ; F90671  c3 07 f0 f8 21
	or A,E                                        ; F90676  cd e1
	inc 1,IZ                                      ; F90678  de 61
	bit_dd8 0x00, 0xc6                            ; F9067A  f0 c6 c8
	jr nz, .LF90683                               ; F9067D  6e 04
.LF9067F:
	bit 6,(XHL)                                   ; F9067F  b3 ce
	jr nz, .LF9067F                               ; F90681  6e fc
.LF90683:
	ld (XHL),A                                    ; F90683  b3 41
	jrl .LF905E6                                  ; F90685  78 5e ff
.LF90688:
	popw iz                                       ; F90688  4e
	ret                                           ; F90689  0e
.LF9068A:

; ---------------------------------------------------------------------
; LCD_TextColMask_Tail16_Fetch -- E &= LCD_TextColMask_Tail16[(0x259E)]
;
; Called from: LCD_TextCol_MergeTail16 (0xF9062D)
; Evidence: 23 bytes, two of them different from
;          LCD_TextColMask_Head16_Fetch's -- the table address.
; ---------------------------------------------------------------------
LCD_TextColMask_Tail16_Fetch:
	push XHL                                      ; F9068A  3b
	push XIX                                      ; F9068B  3c
	ldb_d8 l, (0x259e)                            ; F9068C  c1 9e 25 27
	xor H,H                                       ; F90690  ce d6
	ld XIX,0x00f906a1                             ; F90692  44 a1 06 f9 00
	.byte 0xc3, 0x07, 0xf0, 0xec, 0x21            ; F90697  c3 07 f0 ec 21
	and E,A                                       ; F9069C  c9 c5
	pop XIX                                       ; F9069E  5c
	pop XHL                                       ; F9069F  5b
	ret                                           ; F906A0  0e

; ---------------------------------------------------------------------
; LCD_TextColMask_Tail16 -- 9 bytes, the mask the 16x16 service's FINAL column
; write uses
;
; Read by:  LCD_TextColMask_Tail16_Fetch (0xF90692), indexed by (0x259E), 0..8.
; Evidence: the arithmetic rule is built and diffed against the ROM by
;          notes/prom_a_byte_checks.py ("LCD_TextColMask_Tail16 ==
;          0xFF>>((k+11)%8), 0 at the boundary: 9 of 9"), so "all nine fit" is
;          a script's output. Where the table starts and stops is held by the
;          byte gate: 0xF906A1 is the immediate its fetcher loads and 0xF906AA
;          is the next routine's first instruction.
;          ⚠ what the rule means IN PIXELS is explicitly not established -- see
;          below.
; Layout:   9 bytes, 0xF906A1-0xF906A9; 0xF906AA is LCD_TextCol_MergeHead8's
;           first instruction.
; ★ THE ARITHMETIC, WHICH IS A FACT ABOUT THE BYTES:  entry k is
;       0xFF >> ((k + 11) mod 8),  except that where (k + 11) mod 8 is zero the
;       entry is 0x00 rather than 0xFF.
;   11 is this service's glyph advance.  ALL NINE entries fit that rule --
;   verified by notes/prom_a_byte_checks.py, which builds the table from the
;   rule and compares.  The k = 5 entry is the zero-substituted one, and 5 is
;   precisely the offset at which LCD_Svc_1C_DrawText16x16Packed's tail returns
;   without writing anything, so that entry is never read.
; ⚠ WHAT THE RULE MEANS IN PIXELS IS **NOT** ESTABLISHED.  Which byte-column the
;   tail flush lands in depends on the loop's (0x259C) bookkeeping, and no
;   reading of that has been checked against hardware or against a trace.  The
;   rule above is offered as arithmetic that reproduces the bytes, not as a
;   statement about what survives on the panel.
; ---------------------------------------------------------------------
LCD_TextColMask_Tail16:
	.byte 0x1F			; F906A1  index 0
	.byte 0x0F			; F906A2  index 1
	.byte 0x07			; F906A3  index 2
	.byte 0x03			; F906A4  index 3
	.byte 0x01			; F906A5  index 4
	.byte 0x00			; F906A6  index 5
	.byte 0x7F			; F906A7  index 6
	.byte 0x3F			; F906A8  index 7
	.byte 0x1F			; F906A9  index 8

; ---------------------------------------------------------------------
; LCD_TextCol_MergeHead8 -- the fourth copy of the column merger, and the only
; one whose bytes differ
;
; Called from: LCD_Svc_17_DrawText8x8Packed (0xF9019B and 0xF901C6)
; Evidence: 159 of its 172 bytes equal LCD_TextCol_MergeHead16's; the thirteen
;          at offsets 154-166 are the SAME thirteen bytes reordered -- `inc
;          1,IZ`, the nine-byte BUSY poll and `ld (XHL),A` -- with the increment
;          after the write here and before it there.  Same effect, different
;          instruction order; both counts are checked by
;          notes/prom_a_byte_checks.py.
; ---------------------------------------------------------------------
LCD_TextCol_MergeHead8:
	pushw iz                                      ; F906AA  2e
	ld XHL,0x00790000                             ; F906AB  43 00 00 79 00
	xor IZ,IZ                                     ; F906B0  de d6
.LF906B2:
	cp IZ,BC                                      ; F906B2  d9 f6
	jrl nc, .LF90754                              ; F906B4  7f 9d 00
	bit_dd8 0x00, 0xc6                            ; F906B7  f0 c6 c8
	jr nz, .LF906C0                               ; F906BA  6e 04
.LF906BC:
	bit 6,(XHL)                                   ; F906BC  b3 ce
	jr nz, .LF906BC                               ; F906BE  6e fc
.LF906C0:
	ld (XHL+0x01),0x47                            ; F906C0  bb 01 00 47
	bit_dd8 0x00, 0xc6                            ; F906C4  f0 c6 c8
	jr nz, .LF906CD                               ; F906C7  6e 04
.LF906C9:
	bit 6,(XHL)                                   ; F906C9  b3 ce
	jr nz, .LF906C9                               ; F906CB  6e fc
.LF906CD:
	ld A,(XHL+0x01)                               ; F906CD  8b 01 21
	bit_dd8 0x00, 0xc6                            ; F906D0  f0 c6 c8
	jr nz, .LF906D9                               ; F906D3  6e 04
.LF906D5:
	bit 6,(XHL)                                   ; F906D5  b3 ce
	jr nz, .LF906D5                               ; F906D7  6e fc
.LF906D9:
	ld W,(XHL+0x01)                               ; F906D9  8b 01 20
	stda16 (0x255a), wa                           ; F906DC  f1 5a 25 50
	bit_dd8 0x00, 0xc6                            ; F906E0  f0 c6 c8
	jr nz, .LF906E9                               ; F906E3  6e 04
.LF906E5:
	bit 6,(XHL)                                   ; F906E5  b3 ce
	jr nz, .LF906E5                               ; F906E7  6e fc
.LF906E9:
	ld (XHL+0x01),0x43                            ; F906E9  bb 01 00 43
	bit_dd8 0x00, 0xc6                            ; F906ED  f0 c6 c8
	jr nz, .LF906F6                               ; F906F0  6e 04
.LF906F2:
	bit 6,(XHL)                                   ; F906F2  b3 ce
	jr nz, .LF906F2                               ; F906F4  6e fc
.LF906F6:
	ld E,(XHL+0x01)                               ; F906F6  8b 01 25
	calr .LF90756                                 ; F906F9  1e 5a 00
	bit_dd8 0x00, 0xc6                            ; F906FC  f0 c6 c8
	jr nz, .LF90705                               ; F906FF  6e 04
.LF90701:
	bit 6,(XHL)                                   ; F90701  b3 ce
	jr nz, .LF90701                               ; F90703  6e fc
.LF90705:
	ld (XHL+0x01),0x46                            ; F90705  bb 01 00 46
	ldw_d16 wa, (0x255a)                          ; F90709  d1 5a 25 20
	bit_dd8 0x00, 0xc6                            ; F9070D  f0 c6 c8
	jr nz, .LF90716                               ; F90710  6e 04
.LF90712:
	bit 6,(XHL)                                   ; F90712  b3 ce
	jr nz, .LF90712                               ; F90714  6e fc
.LF90716:
	ld (XHL),A                                    ; F90716  b3 41
	bit_dd8 0x00, 0xc6                            ; F90718  f0 c6 c8
	jr nz, .LF90721                               ; F9071B  6e 04
.LF9071D:
	bit 6,(XHL)                                   ; F9071D  b3 ce
	jr nz, .LF9071D                               ; F9071F  6e fc
.LF90721:
	ld (XHL),W                                    ; F90721  b3 40
	bit_dd8 0x00, 0xc6                            ; F90723  f0 c6 c8
	jr nz, .LF9072C                               ; F90726  6e 04
.LF90728:
	bit 6,(XHL)                                   ; F90728  b3 ce
	jr nz, .LF90728                               ; F9072A  6e fc
.LF9072C:
	ld (XHL+0x01),0x4f                            ; F9072C  bb 01 00 4f
	bit_dd8 0x00, 0xc6                            ; F90730  f0 c6 c8
	jr nz, .LF90739                               ; F90733  6e 04
.LF90735:
	bit 6,(XHL)                                   ; F90735  b3 ce
	jr nz, .LF90735                               ; F90737  6e fc
.LF90739:
	ld (XHL+0x01),0x42                            ; F90739  bb 01 00 42
	.byte 0xc3, 0x07, 0xf0, 0xf8, 0x21            ; F9073D  c3 07 f0 f8 21
	or A,E                                        ; F90742  cd e1
	bit_dd8 0x00, 0xc6                            ; F90744  f0 c6 c8
	jr nz, .LF9074D                               ; F90747  6e 04
.LF90749:
	bit 6,(XHL)                                   ; F90749  b3 ce
	jr nz, .LF90749                               ; F9074B  6e fc
.LF9074D:
	ld (XHL),A                                    ; F9074D  b3 41
	inc 1,IZ                                      ; F9074F  de 61
	jrl .LF906B2                                  ; F90751  78 5e ff
.LF90754:
	popw iz                                       ; F90754  4e
	ret                                           ; F90755  0e
.LF90756:

; ---------------------------------------------------------------------
; LCD_TextColMask_Head8_Fetch -- E &= LCD_TextColMask_Head8[(0x259E)]
;
; Called from: LCD_TextCol_MergeHead8 (0xF906F9) and
;          LCD_TextCol_ReadIntoBufA (0xF908EB)
; Evidence: the same shape as the 16x16 fetcher, and the same measurement backs
;          it -- `ld L,(0x259E)` at 0xF90758 and `ld XIX,0x00F9076D` at
;          0xF9075E, with notes/prom_a_byte_checks.py asserting 23 bytes and
;          exactly two differing bytes (offsets 9 and 10) against 0xF905BE.
;          The same script pins that this copy has exactly the two callers
;          named above and no other.
; ---------------------------------------------------------------------
LCD_TextColMask_Head8_Fetch:
	push XHL                                      ; F90756  3b
	push XIX                                      ; F90757  3c
	ldb_d8 l, (0x259e)                            ; F90758  c1 9e 25 27
	xor H,H                                       ; F9075C  ce d6
	ld XIX,0x00f9076d                             ; F9075E  44 6d 07 f9 00
	.byte 0xc3, 0x07, 0xf0, 0xec, 0x21            ; F90763  c3 07 f0 ec 21
	and E,A                                       ; F90768  c9 c5
	pop XIX                                       ; F9076A  5c
	pop XHL                                       ; F9076B  5b
	ret                                           ; F9076C  0e

; ---------------------------------------------------------------------
; LCD_TextColMask_Head8 -- 9 bytes: keep pixels 0..k-1, i.e. 0xFF << (8-k)
;
; Read by:  LCD_TextColMask_Head8_Fetch (0xF9075E), indexed by (0x259E), 0..8.
; Layout:   9 bytes, 0xF9076D-0xF90775; 0xF90776 is LCD_TextCol_MergeTail8's
;           first instruction.
; Evidence: byte for byte LCD_TextColMask_Head16 -- 9 of 9 equal.
; ---------------------------------------------------------------------
LCD_TextColMask_Head8:
	.byte 0x00			; F9076D  index 0
	.byte 0x80			; F9076E  index 1
	.byte 0xC0			; F9076F  index 2
	.byte 0xE0			; F90770  index 3
	.byte 0xF0			; F90771  index 4
	.byte 0xF8			; F90772  index 5
	.byte 0xFC			; F90773  index 6
	.byte 0xFE			; F90774  index 7
	.byte 0xFF			; F90775  index 8

; ---------------------------------------------------------------------
; LCD_TextCol_MergeTail8 -- the third byte-identical copy of the column merger
;
; Called from: LCD_Svc_17_DrawText8x8Packed (0xF9024D and 0xF9025A)
; Evidence: all 172 bytes equal LCD_TextCol_MergeHead16's and
;          LCD_TextCol_MergeTail16's.
; ---------------------------------------------------------------------
LCD_TextCol_MergeTail8:
	pushw iz                                      ; F90776  2e
	ld XHL,0x00790000                             ; F90777  43 00 00 79 00
	xor IZ,IZ                                     ; F9077C  de d6
.LF9077E:
	cp IZ,BC                                      ; F9077E  d9 f6
	jrl nc, .LF90820                              ; F90780  7f 9d 00
	bit_dd8 0x00, 0xc6                            ; F90783  f0 c6 c8
	jr nz, .LF9078C                               ; F90786  6e 04
.LF90788:
	bit 6,(XHL)                                   ; F90788  b3 ce
	jr nz, .LF90788                               ; F9078A  6e fc
.LF9078C:
	ld (XHL+0x01),0x47                            ; F9078C  bb 01 00 47
	bit_dd8 0x00, 0xc6                            ; F90790  f0 c6 c8
	jr nz, .LF90799                               ; F90793  6e 04
.LF90795:
	bit 6,(XHL)                                   ; F90795  b3 ce
	jr nz, .LF90795                               ; F90797  6e fc
.LF90799:
	ld A,(XHL+0x01)                               ; F90799  8b 01 21
	bit_dd8 0x00, 0xc6                            ; F9079C  f0 c6 c8
	jr nz, .LF907A5                               ; F9079F  6e 04
.LF907A1:
	bit 6,(XHL)                                   ; F907A1  b3 ce
	jr nz, .LF907A1                               ; F907A3  6e fc
.LF907A5:
	ld W,(XHL+0x01)                               ; F907A5  8b 01 20
	stda16 (0x255a), wa                           ; F907A8  f1 5a 25 50
	bit_dd8 0x00, 0xc6                            ; F907AC  f0 c6 c8
	jr nz, .LF907B5                               ; F907AF  6e 04
.LF907B1:
	bit 6,(XHL)                                   ; F907B1  b3 ce
	jr nz, .LF907B1                               ; F907B3  6e fc
.LF907B5:
	ld (XHL+0x01),0x43                            ; F907B5  bb 01 00 43
	bit_dd8 0x00, 0xc6                            ; F907B9  f0 c6 c8
	jr nz, .LF907C2                               ; F907BC  6e 04
.LF907BE:
	bit 6,(XHL)                                   ; F907BE  b3 ce
	jr nz, .LF907BE                               ; F907C0  6e fc
.LF907C2:
	ld E,(XHL+0x01)                               ; F907C2  8b 01 25
	calr .LF90822                                 ; F907C5  1e 5a 00
	bit_dd8 0x00, 0xc6                            ; F907C8  f0 c6 c8
	jr nz, .LF907D1                               ; F907CB  6e 04
.LF907CD:
	bit 6,(XHL)                                   ; F907CD  b3 ce
	jr nz, .LF907CD                               ; F907CF  6e fc
.LF907D1:
	ld (XHL+0x01),0x46                            ; F907D1  bb 01 00 46
	ldw_d16 wa, (0x255a)                          ; F907D5  d1 5a 25 20
	bit_dd8 0x00, 0xc6                            ; F907D9  f0 c6 c8
	jr nz, .LF907E2                               ; F907DC  6e 04
.LF907DE:
	bit 6,(XHL)                                   ; F907DE  b3 ce
	jr nz, .LF907DE                               ; F907E0  6e fc
.LF907E2:
	ld (XHL),A                                    ; F907E2  b3 41
	bit_dd8 0x00, 0xc6                            ; F907E4  f0 c6 c8
	jr nz, .LF907ED                               ; F907E7  6e 04
.LF907E9:
	bit 6,(XHL)                                   ; F907E9  b3 ce
	jr nz, .LF907E9                               ; F907EB  6e fc
.LF907ED:
	ld (XHL),W                                    ; F907ED  b3 40
	bit_dd8 0x00, 0xc6                            ; F907EF  f0 c6 c8
	jr nz, .LF907F8                               ; F907F2  6e 04
.LF907F4:
	bit 6,(XHL)                                   ; F907F4  b3 ce
	jr nz, .LF907F4                               ; F907F6  6e fc
.LF907F8:
	ld (XHL+0x01),0x4f                            ; F907F8  bb 01 00 4f
	bit_dd8 0x00, 0xc6                            ; F907FC  f0 c6 c8
	jr nz, .LF90805                               ; F907FF  6e 04
.LF90801:
	bit 6,(XHL)                                   ; F90801  b3 ce
	jr nz, .LF90801                               ; F90803  6e fc
.LF90805:
	ld (XHL+0x01),0x42                            ; F90805  bb 01 00 42
	.byte 0xc3, 0x07, 0xf0, 0xf8, 0x21            ; F90809  c3 07 f0 f8 21
	or A,E                                        ; F9080E  cd e1
	inc 1,IZ                                      ; F90810  de 61
	bit_dd8 0x00, 0xc6                            ; F90812  f0 c6 c8
	jr nz, .LF9081B                               ; F90815  6e 04
.LF90817:
	bit 6,(XHL)                                   ; F90817  b3 ce
	jr nz, .LF90817                               ; F90819  6e fc
.LF9081B:
	ld (XHL),A                                    ; F9081B  b3 41
	jrl .LF9077E                                  ; F9081D  78 5e ff
.LF90820:
	popw iz                                       ; F90820  4e
	ret                                           ; F90821  0e
.LF90822:

; ---------------------------------------------------------------------
; LCD_TextColMask_Tail8_Fetch -- E &= LCD_TextColMask_Tail8[(0x259E)]
;
; Called from: LCD_TextCol_MergeTail8 (0xF907C5)
; Evidence: `ld L,(0x259E)` at 0xF90824 and `ld XIX,0x00F90839` at 0xF9082A
;          name the index and the table; notes/prom_a_byte_checks.py asserts
;          this fetcher is 23 bytes and differs from 0xF905BE in exactly two
;          bytes (offsets 9 and 10), and that its only caller is the one named
;          above.
; ---------------------------------------------------------------------
LCD_TextColMask_Tail8_Fetch:
	push XHL                                      ; F90822  3b
	push XIX                                      ; F90823  3c
	ldb_d8 l, (0x259e)                            ; F90824  c1 9e 25 27
	xor H,H                                       ; F90828  ce d6
	ld XIX,0x00f90839                             ; F9082A  44 39 08 f9 00
	.byte 0xc3, 0x07, 0xf0, 0xec, 0x21            ; F9082F  c3 07 f0 ec 21
	and E,A                                       ; F90834  c9 c5
	pop XIX                                       ; F90836  5c
	pop XHL                                       ; F90837  5b
	ret                                           ; F90838  0e

; ---------------------------------------------------------------------
; LCD_TextColMask_Tail8 -- 9 bytes, the mask the 8x8 service's FINAL column
; write uses
;
; Read by:  LCD_TextColMask_Tail8_Fetch (0xF9082A), indexed by (0x259E), 0..8.
; Evidence: the rule and its ONE exception are both a script's output --
;          notes/prom_a_byte_checks.py ("LCD_TextColMask_Tail8 fits the same
;          rule with W=6 in 8 of 9, index 1 apart"), which builds the table
;          from the rule and diffs it rather than asserting a sentence. The
;          extent is held by the byte gate: 0xF90839 is the immediate its
;          fetcher loads and 0xF90842 is the next routine.
;          ⚠ index 1's 0x00 has no explanation in the rule; that is stated, not
;          smoothed.
; Layout:   9 bytes, 0xF90839-0xF90841; 0xF90842 is LCD_TextCol_WriteRaw's
;           first instruction.
; ★ THE ARITHMETIC:  entry k is 0xFF >> ((k + 6) mod 8), with 0x00 where that
;   comes out zero -- the same rule as LCD_TextColMask_Tail16 with this
;   service's advance, 6, in place of 11.  EIGHT of the nine entries fit it;
;   index 1 holds 0x00 where the rule gives 0x01.  Both the eight and the one
;   are produced by notes/prom_a_byte_checks.py, which builds the rule's table
;   and diffs it.
; ⚠ The k = 2 entry is the zero-substituted one -- 2 is where a 6-wide glyph
;   ends flush with a byte boundary -- but unlike the 16x16 service, this one
;   does NOT return early at that offset; it flushes buffer A with a mask of
;   0x00.  And index 1's 0x00 has no explanation in the rule at all.  Whether
;   either is deliberate is NOT established, and no claim is made here that the
;   firmware is right or wrong; the bytes are recorded so that whoever traces a
;   caller can settle it.
; ---------------------------------------------------------------------
LCD_TextColMask_Tail8:
	.byte 0x03			; F90839  index 0
	.byte 0x00			; F9083A  index 1
	.byte 0x00			; F9083B  index 2
	.byte 0x7F			; F9083C  index 3
	.byte 0x3F			; F9083D  index 4
	.byte 0x1F			; F9083E  index 5
	.byte 0x0F			; F9083F  index 6
	.byte 0x07			; F90840  index 7
	.byte 0x03			; F90841  index 8

; ---------------------------------------------------------------------
; LCD_TextCol_WriteRaw -- write BC buffer bytes straight down a column
;
; Called from: six sites across the two packed-text services (0xF9022A,
;          0xF902F0, 0xF90322, 0xF9038F, 0xF903A8, 0xF903DB)
; Inputs:  BC = rows; XIX = the buffer; the cursor already positioned by
;          LCD_TextCol_SetCursor
; Outputs: BC display bytes overwritten -- NO read, NO mask, NO merge.  XIZ
;          saved and restored.
; Evidence: CSRDIR DOWN (0x4F) then MWRITE (0x42) once, then a plain loop of
;          `ld A,(XIX+IZ)` / `ld (XHL),A`.  It is used for the byte columns that
;          lie wholly inside the string, where nothing of the panel needs
;          keeping; the merging copies are used at the two ends.
; ---------------------------------------------------------------------
LCD_TextCol_WriteRaw:
	push XIZ                                      ; F90842  3e
	ld XHL,0x00790000                             ; F90843  43 00 00 79 00
	bit_dd8 0x00, 0xc6                            ; F90848  f0 c6 c8
	jr nz, .LF90851                               ; F9084B  6e 04
.LF9084D:
	bit 6,(XHL)                                   ; F9084D  b3 ce
	jr nz, .LF9084D                               ; F9084F  6e fc
.LF90851:
	ld (XHL+0x01),0x4f                            ; F90851  bb 01 00 4f
	bit_dd8 0x00, 0xc6                            ; F90855  f0 c6 c8
	jr nz, .LF9085E                               ; F90858  6e 04
.LF9085A:
	bit 6,(XHL)                                   ; F9085A  b3 ce
	jr nz, .LF9085A                               ; F9085C  6e fc
.LF9085E:
	ld (XHL+0x01),0x42                            ; F9085E  bb 01 00 42
	xor IZ,IZ                                     ; F90862  de d6
.LF90864:
	cp IZ,BC                                      ; F90864  d9 f6
	jr nc, .LF9087C                               ; F90866  6f 14
	.byte 0xc3, 0x07, 0xf0, 0xf8, 0x21            ; F90868  c3 07 f0 f8 21
	inc 1,IZ                                      ; F9086D  de 61
	bit_dd8 0x00, 0xc6                            ; F9086F  f0 c6 c8
	jr nz, .LF90878                               ; F90872  6e 04
.LF90874:
	bit 6,(XHL)                                   ; F90874  b3 ce
	jr nz, .LF90874                               ; F90876  6e fc
.LF90878:
	ld (XHL),A                                    ; F90878  b3 41
	jr .LF90864                                   ; F9087A  68 e8
.LF9087C:
	pop XIZ                                       ; F9087C  5e
	ret                                           ; F9087D  0e

; ---------------------------------------------------------------------
; LCD_TextCol_SetCursor -- CSRDIR DOWN, then CSRW with (0x259C)
;
; Called from: twelve sites across the two packed-text services (0xF90190,
;          0xF901AC, 0xF901BB, 0xF9021F, 0xF9023B, 0xF902CC, 0xF902E5,
;          0xF90317, 0xF90384, 0xF9039D, 0xF903D0, 0xF903FB)
; Inputs:  (0x259C) = the display-RAM address of the byte column to write
; Outputs: the cursor set there and its direction set to DOWN, so the next
;          MWRITE run walks a column.  WA and XHL clobbered.
; Evidence: the routine sends CSRDIR DOWN and then CSRW with (0x259C), which is
;          what the name says, and the twelve call sites are no longer a hand
;          count -- notes/prom_a_byte_checks.py re-derives them from every PC-
;          relative branch in prom_a and asserts the exact list
;          ("LCD_TextCol_SetCursor: exactly 12 caller(s), and they are the
;          listed ones").
; ---------------------------------------------------------------------
LCD_TextCol_SetCursor:
	ld XHL,0x00790000                             ; F9087E  43 00 00 79 00
	bit_dd8 0x00, 0xc6                            ; F90883  f0 c6 c8
	jr nz, .LF9088C                               ; F90886  6e 04
.LF90888:
	bit 6,(XHL)                                   ; F90888  b3 ce
	jr nz, .LF90888                               ; F9088A  6e fc
.LF9088C:
	ld (XHL+0x01),0x4f                            ; F9088C  bb 01 00 4f
	bit_dd8 0x00, 0xc6                            ; F90890  f0 c6 c8
	jr nz, .LF90899                               ; F90893  6e 04
.LF90895:
	bit 6,(XHL)                                   ; F90895  b3 ce
	jr nz, .LF90895                               ; F90897  6e fc
.LF90899:
	ld (XHL+0x01),0x46                            ; F90899  bb 01 00 46
	ldw_d16 wa, (0x259c)                          ; F9089D  d1 9c 25 20
	bit_dd8 0x00, 0xc6                            ; F908A1  f0 c6 c8
	jr nz, .LF908AA                               ; F908A4  6e 04
.LF908A6:
	bit 6,(XHL)                                   ; F908A6  b3 ce
	jr nz, .LF908A6                               ; F908A8  6e fc
.LF908AA:
	ld (XHL),A                                    ; F908AA  b3 41
	bit_dd8 0x00, 0xc6                            ; F908AC  f0 c6 c8
	jr nz, .LF908B5                               ; F908AF  6e 04
.LF908B1:
	bit 6,(XHL)                                   ; F908B1  b3 ce
	jr nz, .LF908B1                               ; F908B3  6e fc
.LF908B5:
	ld (XHL),W                                    ; F908B5  b3 40
	ret                                           ; F908B7  0e

; ---------------------------------------------------------------------
; LCD_TextCol_ReadIntoBufA -- read a column off the panel and OR it into buffer A
;
; Called from: LCD_Svc_17_DrawText8x8Packed (0xF901B2) and nowhere else
; Inputs:  BC = rows; the cursor already set by LCD_TextCol_SetCursor
; Outputs: TextShift_BufA[i] |= (the panel byte at row i, masked by
;          LCD_TextColMask_Head8)
; Evidence: "and nowhere else" is a SEARCH, and it is now runnable --
;          notes/prom_a_byte_checks.py resolves every PC-relative branch in
;          prom_a and every 3-byte LE address in prom_a + prom_b, and finds
;          exactly one caller, 0xF901B2, and no site naming this address as
;          data. The read half is the body: the panel byte comes back through
;          the 0x790000 window and is ORed into buffer A after
;          LCD_TextColMask_Head8_Fetch masks it.
; Notes:   the read half of a read-modify-write, done once for the FIRST
;          character of a string when its start offset is small enough that the
;          glyph shares its first byte with whatever was already there.
; ---------------------------------------------------------------------
LCD_TextCol_ReadIntoBufA:
	push XIZ                                      ; F908B8  3e
	push XIX                                      ; F908B9  3c
	ld XHL,0x00790000                             ; F908BA  43 00 00 79 00
	bit_dd8 0x00, 0xc6                            ; F908BF  f0 c6 c8
	jr nz, .LF908C8                               ; F908C2  6e 04
.LF908C4:
	bit 6,(XHL)                                   ; F908C4  b3 ce
	jr nz, .LF908C4                               ; F908C6  6e fc
.LF908C8:
	ld (XHL+0x01),0x4f                            ; F908C8  bb 01 00 4f
	bit_dd8 0x00, 0xc6                            ; F908CC  f0 c6 c8
	jr nz, .LF908D5                               ; F908CF  6e 04
.LF908D1:
	bit 6,(XHL)                                   ; F908D1  b3 ce
	jr nz, .LF908D1                               ; F908D3  6e fc
.LF908D5:
	ld (XHL+0x01),0x43                            ; F908D5  bb 01 00 43
	xor IZ,IZ                                     ; F908D9  de d6
.LF908DB:
	cp IZ,BC                                      ; F908DB  d9 f6
	jr nc, .LF908FC                               ; F908DD  6f 1d
	bit_dd8 0x00, 0xc6                            ; F908DF  f0 c6 c8
	jr nz, .LF908E8                               ; F908E2  6e 04
.LF908E4:
	bit 6,(XHL)                                   ; F908E4  b3 ce
	jr nz, .LF908E4                               ; F908E6  6e fc
.LF908E8:
	ld E,(XHL+0x01)                               ; F908E8  8b 01 25
	calr (0xF90756 - 0xF908EE)                                   ; F908EB  1e 68 fe
	ld XIX,0x0000256a                             ; F908EE  44 6a 25 00 00
	.byte 0xc3, 0x07, 0xf0, 0xf8, 0xed            ; F908F3  c3 07 f0 f8 ed
	inc 1,IZ                                      ; F908F8  de 61
	jr .LF908DB                                   ; F908FA  68 df
.LF908FC:
	pop XIX                                       ; F908FC  5c
	pop XIZ                                       ; F908FD  5e
	ret                                           ; F908FE  0e

; ---------------------------------------------------------------------
; LCD_Svc_1E_ScrollCurrentLayer -- SWI7 service 0x1E: move the current layer's
; window in display RAM and re-send SCROLL
;
; Called from: SWI7_ServiceTable slot 0x1E (0xF8EA3E)
; Inputs:  C -- bits 7:6 a direction, bits 3:0 an amount of 0..15.
;          (0x2540) selects the layer.
; Outputs: that layer's base address changed by the amount, written back into
;          whichever of (0x2541)/(0x2543)/(0x2545) the layer table points at,
;          and the controller's SCROLL command re-sent with all three SADs and
;          both SLs.  (0x2555) holds the new base.  WA, HL, XHL, XIY clobbered.
; Evidence: ★ THIS IS THE PANEL'S HARDWARE SCROLL, and the four arms are read
;          straight off the arithmetic.  With n = C and 0x0F:
;
;            C and 0xC0 = 0x00   base := base + n*0x28
;            C and 0xC0 = 0x40   base := base - n*0x28
;            C and 0xC0 = 0x80   base := base - n
;            C and 0xC0 = 0xC0   base := base + n
;
;          0x28 is AP, the 40 bytes SYSTEM SET gives a scan line, so the first
;          two arms move the window by n LINES and the last two by n BYTE
;          COLUMNS -- eight pixels each.  The multiply is a literal
;          `ld DE,0x0028` + `mul XWA,DE` in both line arms.  It then walks
;          LCD_LayerBasePtr_Table exactly as LCD_SelectCurrentLayer does --
;          `(0x2540)` zero-extended, times 4, indexed into 0xF8EEB1 -- and
;          stores the new value through the pointer it finds, so the change
;          survives the next LCD_SelectCurrentLayer.
;          The SCROLL it then issues is the same eight parameter bytes
;          LCD_Init_SED1330 sends, except that SAD1/SAD2/SAD3 come from the
;          three RAM words instead of from constants, and the two SLs are the
;          same 0xF0 = 240.  Like the setup and like services 0x0F/0x10 it does
;          not poll BUSY -- single NOPs separate the accesses.
;
; ⚠ THE WRITE-BACK IS 32 BITS WIDE AND THE FIELD IS 16.  `ld XWA,(0x2555)` reads
;   FOUR bytes -- the layer base at (0x2555)/(0x2556) and AP at
;   (0x2557)/(0x2558) -- and `ld (XHL),XWA` writes four bytes through the layer
;   pointer.  Every reader of those words is 16-bit (LCD_SelectCurrentLayer's
;   `ld WA,(XHL)`, and this routine's own SCROLL), so the extra two bytes are
;   pure collateral, and where they land depends on the layer:
;       layer 0 -> (0x2543), i.e. SAD2, becomes 0x0028
;       layer 1 -> (0x2545), i.e. SAD3, becomes 0x0028
;       layer 2 -> (0x2547)/(0x2548), the line draw's swap flag and the low half
;                  of its slope -- both recomputed by LCD_Line_ChooseMajorAxis
;                  on every line, so nothing is lost
;   Only the layer-2 case is harmless.  That is a READING of the addresses, not
;   a measurement, and it is recorded rather than acted on: no caller of this
;   service is traced, so which layer it is used on is unknown.  Anyone
;   modelling this controller should reproduce the 32-bit store as it is.
; Unknown:  callers; and whether "base + n*AP" scrolls the image up or down on
;   the glass, which depends on the panel's scan order and is not determined by
;   anything in this firmware.
; ---------------------------------------------------------------------
LCD_Svc_1E_ScrollCurrentLayer:
	calr (0xF8EE93 - 0xF90902)                                   ; F908FF  1e 91 e5
	ld A,C                                        ; F90902  cb 89
	and A,0x0f                                    ; F90904  c9 cc 0f
	xor W,W                                       ; F90907  c8 d0
	and C,0xc0                                    ; F90909  cb cc c0
	cps c, 0x00                                   ; F9090C  cb d8
	jr z, .LF90926                                ; F9090E  66 16
	cp C,0x40                                     ; F90910  cb cf 40
	jr z, .LF90931                                ; F90913  66 1c
	cp C,0x80                                     ; F90915  cb cf 80
	jr z, .LF90920                                ; F90918  66 06
	m_add_mr MW16, 0x2555, r0                     ; F9091A  d1 55 25 88
	jr .LF9093A                                   ; F9091E  68 1a
.LF90920:
	m_sub_mr MW16, 0x2555, r0                     ; F90920  d1 55 25 a8
	jr .LF9093A                                   ; F90924  68 14
.LF90926:
	ldw de, 0x28                                  ; F90926  32 28 00
	mul xwa, xde                                  ; F90929  da 40
	m_add_mr MW16, 0x2555, r0                     ; F9092B  d1 55 25 88
	jr .LF9093A                                   ; F9092F  68 09
.LF90931:
	ldw de, 0x28                                  ; F90931  32 28 00
	mul xwa, xde                                  ; F90934  da 40
	m_sub_mr MW16, 0x2555, r0                     ; F90936  d1 55 25 a8
.LF9093A:
	xor H,H                                       ; F9093A  ce d6
	ldb_d8 l, (0x2540)                            ; F9093C  c1 40 25 27
	sla hl, 0x02                                  ; F90940  db ec 02
	ld XIY,0x00f8eeb1                             ; F90943  45 b1 ee f8 00
	.byte 0xe3, 0x07, 0xf4, 0xec, 0x23            ; F90948  e3 07 f4 ec 23
	ldda32 xwa, (0x2555)                          ; F9094D  e1 55 25 20
	ld (XHL),XWA                                  ; F90951  b3 60
	ld XIY,0x00790000                             ; F90953  45 00 00 79 00
	nop                                           ; F90958  00
	ld (XIY+0x01),0x44                            ; F90959  bd 01 00 44
	nop                                           ; F9095D  00
	ldw_d16 wa, (0x2541)                          ; F9095E  d1 41 25 20
	ld (XIY),A                                    ; F90962  b5 41
	nop                                           ; F90964  00
	nop                                           ; F90965  00
	ld (XIY),W                                    ; F90966  b5 40
	nop                                           ; F90968  00
	nop                                           ; F90969  00
	ld (XIY),0xf0                                 ; F9096A  b5 00 f0
	nop                                           ; F9096D  00
	ldw_d16 wa, (0x2543)                          ; F9096E  d1 43 25 20
	ld (XIY),A                                    ; F90972  b5 41
	nop                                           ; F90974  00
	nop                                           ; F90975  00
	ld (XIY),W                                    ; F90976  b5 40
	nop                                           ; F90978  00
	nop                                           ; F90979  00
	ld (XIY),0xf0                                 ; F9097A  b5 00 f0
	nop                                           ; F9097D  00
	ldw_d16 wa, (0x2545)                          ; F9097E  d1 45 25 20
	ld (XIY),A                                    ; F90982  b5 41
	nop                                           ; F90984  00
	nop                                           ; F90985  00
	ld (XIY),W                                    ; F90986  b5 40
	ret                                           ; F90988  0e
	.incbin "original_ROMs/wsa1_prom_a.ic12", 0x010989, 0x014A77

; ==============================================================================
; 0xFA5400-0xFA5417 -- the MIDI module's entry-thunk table
; ==============================================================================
;
; ---------------------------------------------------------------------
; MIDI_EntryThunks -- six 4-byte slots, the module's public entry points
;
; Called from: not yet traced.  ⚠ notes/prom_a_xref.py finds no `call`, `jp`,
;          `lda` or bare pointer naming 0xFA5400 in either image, so whatever
;          reaches this table computes the address.
; Inputs:  none
; Outputs: none
; Evidence: the same idiom as LCD_EntryThunks at 0xF8E800 -- a fixed-stride
;          table of entry points rather than of pointers, which is how a
;          firmware keeps a module ABI stable across revisions.  The stride is
;          4 and is fixed by the ONE live slot: slot 3 holds `1b be 58 fa`, a
;          4-byte `jp`, and it starts at 0xFA540C = 0xFA5400 + 3*4.  The other
;          five slots are `ret` followed by three `nop`s -- an empty slot
;          padded to the same stride, which is what makes the stride readable
;          at all.
; Notes:   the table's LOWER edge is a 152-byte run of 0x0E at
;          0xFA5368-0xFA53FF, and its upper edge is MIDI_RX_ErrorReset at
;          0xFA5418, already converted.  So six slots is the whole table, not a
;          window on a longer one.
;          ⚠ 0x0E -- RET -- is this build's inter-module pad byte throughout;
;          prom_a alone has 35 runs of 64 or more of them.  That means the pad
;          and slot 0's own `ret` are the SAME BYTE, so a scan for the run
;          measures 153 and stops one byte inside the table.  The boundary here
;          comes from the 4-byte stride, not from where the 0x0E stops.
; Unknown:  ⚠ what the five empty slots were for.  Their presence says the
;          module's interface was designed for six entry points and only one
;          survives, exactly as four of the LCD module's six are `ret`.
; ---------------------------------------------------------------------
MIDI_EntryThunks:
	ret                                           ; FA5400  0e   slot 0 -- unused
	nop                                           ; FA5401  00
	nop                                           ; FA5402  00
	nop                                           ; FA5403  00
	ret                                           ; FA5404  0e   slot 1 -- unused
	nop                                           ; FA5405  00
	nop                                           ; FA5406  00
	nop                                           ; FA5407  00
	ret                                           ; FA5408  0e   slot 2 -- unused
	nop                                           ; FA5409  00
	nop                                           ; FA540A  00
	nop                                           ; FA540B  00
	jp MIDI_Reset                                 ; FA540C  1b be 58 fa   slot 3 -- the only live entry
	ret                                           ; FA5410  0e   slot 4 -- unused
	nop                                           ; FA5411  00
	nop                                           ; FA5412  00
	nop                                           ; FA5413  00
	ret                                           ; FA5414  0e   slot 5 -- unused
	nop                                           ; FA5415  00
	nop                                           ; FA5416  00
	nop                                           ; FA5417  00

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
;          the 8-BIT counter at (0x0931) incremented.  Returns with RETI.
;          ⚠ CORRECTED 2026-08-25: this line said 16-bit while its own body
;          two lines below said 8-bit.  `incdi8 0x01,(0x0931)` at 0xFA5429
;          is C1 31 09 61 -- prefix 0xC1 is the BYTE operand with a 16-bit
;          address, so the increment is one byte wide.  The fix was already
;          in notes/FINDINGS-midi-port.md:219 and had not reached the source.
; Evidence: "receive error" is the caller's test, not this routine's --
;          MIDI_RX_Byte reads SC0CR and does `and A,0x1c` (0xFA549A), i.e.
;          bits 2-4, and branches here when any is set. "Reset" is the body:
;          SC0BUF is read at 0xFA5419 purely to clear the condition, running
;          status (0x9A) is zeroed, and (0xA9) is zeroed -- after which it
;          RETIs without ever entering the parser.
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
	incdi8 0x01, (0x0931)                         ; FA5429  c1 31 09 61   (0x0931) = an 8-BIT receive-error counter
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
; Evidence: the slot is emitted as `.long 0x00F40718` with the thunk's body
;          given above, and the five real-time bytes are LITERAL immediates
;          written to SC0BUF -- so the mapping from (0xA0) bit to MIDI byte is
;          read out of the ROM, not assumed. The priority order is likewise
;          read off the branch chain: 0xFA5433 tests bit 0, then 0xFA5438 bit
;          4, 0xFA543D bit 1, 0xFA5442 bit 2, 0xFA5447 bit 3 -- clock, active
;          sensing, start, continue, stop, which is NOT the bit order.
;          0xFA544F is `ldio SC0BUF,0xfc`, the STOP byte, on the bit-3 arm.
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
; Evidence: the slot is emitted as `.long 0x00F40714` and the thunk body is
;          given above, so this is INTRX0's handler. The three-way split is
;          read straight off the code -- the SC0CR error mask `and A,0x1c` at
;          0xFA549A, then bit 7 of the byte, then the 0xF8 boundary -- and the
;          register context that makes the parser stateful is the pair of
;          block moves at 0xFA5884 and 0xFA58A1 that load and store all seven
;          32-bit registers from RAM at 0x0900. What makes the whole block
;          MIDI rather than "a UART" is MIDI_StatusDispatch_Table below.
; Notes:   the three paths, and what picks them:
;            bit 7 clear          -> a DATA byte      -> 0xFA5763
;            0x80-0xF7            -> a STATUS byte    -> handled inline:
;                                    it becomes the running status in (0x9A),
;                                    and 0xF7 (END OF EXCLUSIVE) closes an
;                                    in-progress SysEx through 0xF41E3C
;            0xF8-0xFF            -> SYSTEM REAL TIME -> 0xFA5504
;          (0xA9) is the SysEx state: bit 0 armed, bit 1 in-message, bit 5 seen.
;          ⚠ bit 5 is still uncorroborated; bits 0 and 1 now are -- converting
;          MIDI_RX_SysExStart and MIDI_RX_SysExData (0xFA584D, 0xFA586E) shows
;          bit 0 being set the moment 0xF0 arrives and bit 1 only when the
;          identifier byte is one this machine accepts.
;
;          ★ The three `calr`s here are not ordinary calls.  The pushes above
;          save the INTERRUPTED code's registers; 0xFA5884 then loads the
;          PARSER's own seven registers out of RAM at 0x0900, and 0xFA58A1
;          writes them back before the pops.  The parser therefore keeps state
;          in registers from one incoming byte to the next -- see the block
;          header at 0xFA5763.
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
	calr 0x03d9                                   ; FA54A8  1e d9 03   -> MIDI_Parser_LoadContext (0xFA5884)
	ld_sd8b a, SC0BUF                               ; FA54AB  c0 50 21   the received byte
	ldio 0x9c, 0x00                               ; FA54AE  08 9c 00   restart the receive-inactivity timer INTT1 counts
	bit 0x07,A                                    ; FA54B1  c9 33 07   bit 7 set = a status byte
	jr z, .LFA54F6                                ; FA54B4  66 40
	cp A,0xf7                                     ; FA54B6  c9 cf f7   0xF8-0xFF are System Real Time
	jr ule, .LFA54C0                              ; FA54B9  63 05
	calr 0x46                                     ; FA54BB  1e 46 00   -> MIDI_RT_Received (0xFA5504)
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
	calr 0x026a                                   ; FA54F6  1e 6a 02   -> MIDI_RX_DataByte (0xFA5763)
.LFA54F9:
	calr 0x03a5                                   ; FA54F9  1e a5 03   -> MIDI_Parser_SaveContext (0xFA58A1)
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
; Evidence: every gate in the list below is a literal compare or bit test in
;          the body, in that order, and the four bytes it acts on -- 0xFE,
;          0xFD, 0xF8, 0xFA, 0xFB, 0xFC -- are immediates, not derived values:
;          0xFA5504 is `cp A,0xfe` and 0xFA5509 sets (0x9E) bit 7, the same
;          bit INTT1_Tick counts (0x9C) against. That pairing across two
;          routines is what identifies the byte as ACTIVE SENSING rather than
;          merely "the value 0xFE".
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
; Evidence: it is the `jr` target taken when (0x7F32) bit 2 is clear at
;          0xFA552C, and its first instruction is `ldio 0xa1,0x00` (0xFA5674)
;          -- the tempo counter INTT1_Tick increments and 0xFA553E turns into
;          TREG5. So the two arms differ in exactly the way the name says: one
;          follows the incoming clock, this one holds its counter at zero.
;          ⚠ "External" is the READING of that difference; the bit's producer
;          is not traced, which is why the header says so in Notes.
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
; Evidence: "a second copy" is a byte-level statement and it can be checked by
;          eye against the first: the two bodies below are the same
;          instructions in the same order with XIX substituted for XIY, and
;          both write the same immediate 0x81 into the same buffer at 0x600A14
;          with the same `minc1_16 ...,0x01ff` wrap. Both listings are in this
;          file, side by side, and the byte gate holds both.
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
	.incbin "original_ROMs/wsa1_prom_a.ic12", 0x02570C, 0x000057

; ==============================================================================
; 0xFA5763-0xFA5941 -- the MIDI input parser, its register context, and the
;                      UART setup
; ==============================================================================
;
; ★ THE PARSER IS A RESUMED ROUTINE, NOT A CALLED ONE.  MIDI_RX_Byte pushes all
;   seven 32-bit registers on the STACK (they belong to whatever was
;   interrupted), then calls MIDI_Parser_LoadContext, which loads all seven from
;   a fixed RAM block at 0x0900; at the end it calls MIDI_Parser_SaveContext,
;   which writes them back, and only then pops the interrupted code's registers.
;
;   So the parser has its OWN persistent register set that survives between
;   incoming bytes, and code below may leave state in any register across a
;   whole MIDI message.  It does: C holds the first data byte of a two-data-byte
;   message from one interrupt to the next (0xFA57DB), and D/E are reloaded from
;   RAM each time.  Reading any of this as ordinary subroutine code -- where
;   registers die at the `ret` -- gets it wrong.
;
; The RAM the parser owns:
;   (0x0900)-(0x091B)  the seven saved 32-bit registers, in the order
;                      XWA XBC XDE XHL XIX XIY XIZ.  Cleared by
;                      MIDI_Parser_ClearContext.
;   (0x9A)   running status, 0 = none.  Written by MIDI_RX_Byte on every status
;            byte, cleared here on System Common, cleared by MIDI_RX_ErrorReset
;   (0x9E)   receive state flags -- see the table below
;   (0xA9)   SysEx state: bit 0 armed, bit 1 accepted/in-message, bit 5 seen
;   (0x0932) an 8-bit counter, bumped on every input-queue overflow
;   (0x216F) bit 0  set on every byte actually delivered -- a MIDI-activity flag
;
; (0x9E), as far as this block and the two already-converted handlers show:
;   bit 1  the pending two-data-byte message is a SONG POSITION POINTER
;   bit 2  the input queue overflowed
;   bit 3  the UART reported a receive error       (MIDI_RX_ErrorReset)
;   bit 5  active sensing timed out                (INTT1_Tick)
;   bit 6  a first data byte is pending in C
;   bit 7  active sensing has been seen            (MIDI_RT_Received)
;   MIDI_RX_Byte clears bits 6 and 1 (`and (0x9e),0xbd`) on every status byte,
;   which is what makes a new status cancel a half-received message.
;
; The queue this parser feeds is in prom_b: 0xF41DAC appends one byte and
; 0xF41E3C appends one SysEx byte.  ⚠ Their bodies are another lane's territory.
; The free-space count it tests is the 16-bit field at 0x00600C1E + 0xFE =
; (0x600D1C); "free" rather than "used" is not a guess -- every test is
; `cp (XIX+0xfe),n` / `jr c` -> OVERFLOW with n one greater than the number of
; bytes about to be written (3 before writing 2, 4 before writing 3).
;
; ---------------------------------------------------------------------
; MIDI_RX_DataByte -- the data-byte path of the MIDI receive interrupt
;
; Called from: MIDI_RX_Byte 0xFA54F6 (`calr`), when bit 7 of the received byte
;          is clear
; Inputs:  A = the data byte; (0x9A) = running status; (0x9E) and (0xA9) as above
; Outputs: zero, one or three bytes appended to the prom_b input queue; the
;          parser's flags updated.  D, E, C and XIX are used and their values
;          persist into the next interrupt through the saved context.
; Evidence: the three-way head is read straight off the branches -- SysEx armed
;          ((0xA9) bit 0) wins, then "a first data byte is pending" ((0x9E)
;          bit 6), then "no running status" (A == 0) drops the byte.  What is
;          left is dispatched through MIDI_StatusDispatch_Table, and that table
;          IS the identification: see its header.
; Unknown:  what reads (0x0932), and the exact meaning of (0xA9) bit 5.
; ---------------------------------------------------------------------
MIDI_RX_DataByte:
	ld E,A                                        ; FA5763  c9 8d   E = the data byte
	ld_sd8b a, 0x9a                               ; FA5765  c0 9a 21   A = running status
	ld D,A                                        ; FA5768  c9 8c   D = running status
	bit_dd8 0x00, 0xa9                            ; FA576A  f0 a9 c8   a SysEx is armed?
	jrl nz, MIDI_RX_SysExData                     ; FA576D  7e fe 00
	bit_dd8 0x06, 0x9e                            ; FA5770  f0 9e ce   a first data byte is already pending?
	jr nz, MIDI_RX_SecondDataByte                 ; FA5773  6e 69
	cps a, 0x00                                   ; FA5775  c9 d8   no running status at all?
	jr z, MIDI_RX_Drop                            ; FA5777  66 35   then the byte has nowhere to go
	and A,0x70                                    ; FA5779  c9 cc 70   the status nibble, minus its top bit
	srl a, 0x02                                   ; FA577C  c9 ef 02   * 4: eight 32-bit table slots
	xor W,W                                       ; FA577F  c8 d0
	ld XIX,0x00fa578e                             ; FA5781  44 8e 57 fa 00
	.byte 0xe3, 0x07, 0xf0, 0xe0, 0x24            ; FA5786  e3 07 f0 e0 24   ld XIX,(XIX+WA) -- llvm-mc has no spelling for (rr+r)
	jp (xix)                                      ; FA578B  b4 d8
	nop                                           ; FA578D  00

; ---------------------------------------------------------------------
; MIDI_StatusDispatch_Table -- eight LE32 handlers, indexed by the status nibble
;
; Called from: MIDI_RX_DataByte 0xFA578B, as `jp (XIX)` after
;          XIX = (0xFA578E + ((status & 0x70) >> 2))
; Layout:  8 entries x 4 bytes = 32 bytes, 0xFA578E-0xFA57AD.  The COUNT is
;          fixed by the addressing, not by inspection: `and A,0x70` leaves three
;          significant bits and `srl 2` turns them into a 0..28 byte offset, so
;          index 7 is the last slot the code can form -- and slot 7 ends at
;          0xFA57AE, which is the RET slot 2 points at.  A ninth entry would
;          overlap it.
; Evidence: ★ this table is what identifies the whole block as a MIDI parser.
;          The index is (status & 0x70) >> 4, and bit 7 is always set on a
;          status byte, so index n means status 0x80 + 16n:
;
;            index  status  MIDI message           target
;              0     0x8n   Note Off               MIDI_RX_AwaitSecondByte
;              1     0x9n   Note On                MIDI_RX_AwaitSecondByte
;              2     0xAn   Poly Key Pressure      MIDI_RX_Drop  <-- a bare RET
;              3     0xBn   Control Change         MIDI_RX_AwaitSecondByte
;              4     0xCn   Program Change         MIDI_RX_DeliverTwo
;              5     0xDn   Channel Pressure       MIDI_RX_DeliverTwo
;              6     0xEn   Pitch Bend             MIDI_RX_AwaitSecondByte
;              7     0xFn   System                 MIDI_RX_SystemCommon
;
;          That is EXACTLY the MIDI 1.0 data-byte count for each status: two
;          data bytes for 0x8n 0x9n 0xBn 0xEn, one for 0xCn and 0xDn.  Nothing
;          was assumed to produce it -- the four addresses are read out of the
;          ROM and the grouping falls out.
; Naming:  called MIDI_MessageLength_Table until 2026-08-25.  Renamed after the
;          round-1 audit: every entry is a 32-bit CODE POINTER, not a length,
;          so a reader who greps the old name expects `.long 2,2,2,...` and
;          finds handlers.  The data-byte count is only IMPLIED, by which
;          handler each status is grouped onto; the object itself is a dispatch
;          table.  The grouping argument below is unchanged and still stands.
; Notes:   ★ index 2 is the finding.  Polyphonic Key Pressure is the one
;          channel-voice message this instrument DISCARDS: its slot points at
;          0xFA57AE, a bare `ret`, and the two data bytes that follow are then
;          dropped as well because bit 6 of (0x9E) was never set.  Every other
;          channel-voice message is delivered.
; Unknown:  nothing outstanding.
; ---------------------------------------------------------------------
MIDI_StatusDispatch_Table:
	.long MIDI_RX_AwaitSecondByte	; FA578E  d8 57 fa 00   0x8n Note Off
	.long MIDI_RX_AwaitSecondByte	; FA5792  d8 57 fa 00   0x9n Note On
	.long MIDI_RX_Drop	; FA5796  ae 57 fa 00   0xAn Poly Key Pressure -- DISCARDED
	.long MIDI_RX_AwaitSecondByte	; FA579A  d8 57 fa 00   0xBn Control Change
	.long MIDI_RX_DeliverTwo	; FA579E  af 57 fa 00   0xCn Program Change
	.long MIDI_RX_DeliverTwo	; FA57A2  af 57 fa 00   0xDn Channel Pressure
	.long MIDI_RX_AwaitSecondByte	; FA57A6  d8 57 fa 00   0xEn Pitch Bend
	.long MIDI_RX_SystemCommon	; FA57AA  30 58 fa 00   0xFn System Common

; ---------------------------------------------------------------------
; MIDI_RX_Drop -- the "this message is not wanted" target: one RET
;
; Called from: MIDI_StatusDispatch_Table slot 2 (Poly Key Pressure), and
;          MIDI_RX_DataByte 0xFA5777 (no running status)
; Evidence: the body is one byte, 0x0E = RET at 0xFA57AE. Both routes in are
;          re-derived from the ROM by notes/prom_a_byte_checks.py -- the
;          branch at 0xFA5777 and the single data reference at 0xFA5796, which
;          is MIDI_StatusDispatch_Table + 2*4, i.e. slot 2. There is no third
;          route.
; ---------------------------------------------------------------------
MIDI_RX_Drop:
	ret                                           ; FA57AE  0e

; ---------------------------------------------------------------------
; MIDI_RX_DeliverTwo -- append <status, data> to the input queue
;
; Called from: MIDI_StatusDispatch_Table slots 4 and 5 (Program Change, Channel
;          Pressure); MIDI_RX_SongSelect 0xFA584A (`jrl`)
; Inputs:  D = status, E = the single data byte
; Outputs: two bytes appended through prom_b 0xF41DAC, or the overflow flag set
; Evidence: the free-space test is `cp (XIX+0xfe),0x0003` before appending TWO
;          bytes -- one more than it is about to write, which is what makes
;          (0x600D1C) a FREE count and not a used one.
; ---------------------------------------------------------------------
MIDI_RX_DeliverTwo:
	m_set 0, MD16, 0x216f                         ; FA57AF  f1 6f 21 b8   MIDI activity
	ld XIX,0x00600c1e                             ; FA57B3  44 1e 0c 60 00
	m_cp_mi16 MWD+r4, 0xfe, 0x0003                ; FA57B8  9c fe 3f 03 00   free space >= 3?
	jr c, MIDI_RX_QueueFull2                      ; FA57BD  67 11
	ld A,D                                        ; FA57BF  cc 89
	pushw wa                                      ; FA57C1  28
	call 0xf41dac                                 ; FA57C2  1d ac 1d f4   append the status byte
	inc 2,XSP                                     ; FA57C6  ef 62
	pushw de                                      ; FA57C8  2a
	call 0xf41dac                                 ; FA57C9  1d ac 1d f4   append the data byte
	inc 2,XSP                                     ; FA57CD  ef 62
	ret                                           ; FA57CF  0e
MIDI_RX_QueueFull2:
	set_dd8 0x02, 0x9e                            ; FA57D0  f0 9e ba   (0x9E) bit 2 = the input queue overflowed
	incdi8 0x01, (0x0932)                         ; FA57D3  c1 32 09 61   8-bit overflow counter
	ret                                           ; FA57D7  0e

; ---------------------------------------------------------------------
; MIDI_RX_AwaitSecondByte -- stash the first of two data bytes and return
;
; Called from: MIDI_StatusDispatch_Table slots 0, 1, 3, 6
; Inputs:  E = the first data byte
; Outputs: C = E, and (0x9E) bit 6 set so the NEXT byte takes
;          MIDI_RX_SecondDataByte.  C survives to that interrupt through the
;          saved register context -- see this block's header.
; Evidence: the body is three instructions -- `set 6,(0x9E)` at 0xFA57D8, `ld
;          C,E` at 0xFA57DB, `ret` -- and bit 6 of (0x9E) is exactly the bit
;          MIDI_RX_DataByte tests at 0xFA5770 to send the NEXT byte to
;          MIDI_RX_SecondDataByte. The two halves of the name are those two
;          facts.
; ---------------------------------------------------------------------
MIDI_RX_AwaitSecondByte:
	set_dd8 0x06, 0x9e                            ; FA57D8  f0 9e be
	ld C,E                                        ; FA57DB  cd 8b
	ret                                           ; FA57DD  0e

; ---------------------------------------------------------------------
; MIDI_RX_SecondDataByte -- the second data byte of a three-byte message
;
; Called from: MIDI_RX_DataByte 0xFA5773, when (0x9E) bit 6 is set
; Inputs:  C = the first data byte, E = the second, D = running status
; Outputs: three bytes appended, and (0x9E) bits 6 and 1 cleared
; Evidence: ★ THE CONGESTION RULE.  Before the ordinary "is there room for 3"
;          test there is a SECOND, much larger one: if free space is 0x40 or
;          less, and the message is a Note On (`and D,0xf0` / `cp D,0x90`) whose
;          velocity is NOT zero (`cp E,0` / `jr nz`), the message is thrown
;          away.  A Note On with velocity zero -- which is how MIDI spells a
;          release under running status -- falls through and IS delivered.
;          So under overload the parser sheds NOTE STARTS and always keeps NOTE
;          ENDS, which is exactly the behaviour that stops an overloaded input
;          leaving notes stuck on.  The sense of the velocity test is worth
;          reading twice: `jr nz` after `cp E,0` jumps to the RET, so it is the
;          non-zero velocity that is dropped.
; Notes:   the `ld D,0xf2` at 0xFA57E7 restores the status for a Song Position
;          Pointer.  It is needed because MIDI_RX_SystemCommon zeroed the
;          running status when the 0xF2 arrived, so D would otherwise be 0 by
;          the time the second data byte turns up; (0x9E) bit 1 is the marker
;          that says which message this is.
; ---------------------------------------------------------------------
MIDI_RX_SecondDataByte:
	m_set 0, MD16, 0x216f                         ; FA57DE  f1 6f 21 b8   MIDI activity
	bit_dd8 0x01, 0x9e                            ; FA57E2  f0 9e c9   a Song Position Pointer?
	jr z, .LFA57E9                                ; FA57E5  66 02
	ldb d, 0xf2                                   ; FA57E7  24 f2   restore the status the F2 handler cleared
.LFA57E9:
	ld XIX,0x00600c1e                             ; FA57E9  44 1e 0c 60 00
	m_cp_mi16 MWD+r4, 0xfe, 0x0040                ; FA57EE  9c fe 3f 40 00   plenty of room?
	jr ugt, MIDI_RX_DeliverThree                  ; FA57F3  6b 0e
	pushw de                                      ; FA57F5  2a
	and D,0xf0                                    ; FA57F6  cc cc f0
	cp D,0x90                                     ; FA57F9  cc cf 90   a Note On?
	popw de                                       ; FA57FC  4a
	jr nz, MIDI_RX_DeliverThree                   ; FA57FD  6e 04
	cps e, 0x00                                   ; FA57FF  cd d8   velocity zero = a note END, keep it
	jr nz, MIDI_RX_Return                         ; FA5801  6e 24   a real note START, drop it
MIDI_RX_DeliverThree:
	m_cp_mi16 MWD+r4, 0xfe, 0x0004                ; FA5803  9c fe 3f 04 00   free space >= 4?
	jr c, MIDI_RX_QueueFull3                      ; FA5808  67 1e
	ld A,D                                        ; FA580A  cc 89
	pushw wa                                      ; FA580C  28
	call 0xf41dac                                 ; FA580D  1d ac 1d f4   status
	inc 2,XSP                                     ; FA5811  ef 62
	ld A,C                                        ; FA5813  cb 89
	pushw wa                                      ; FA5815  28
	call 0xf41dac                                 ; FA5816  1d ac 1d f4   first data byte
	inc 2,XSP                                     ; FA581A  ef 62
	pushw de                                      ; FA581C  2a
	call 0xf41dac                                 ; FA581D  1d ac 1d f4   second data byte
	inc 2,XSP                                     ; FA5821  ef 62
	m_and_mi8 MB8, 0x9e, 0xbd                     ; FA5823  c0 9e 3c bd   clear bits 6 and 1
MIDI_RX_Return:
	ret                                           ; FA5827  0e
MIDI_RX_QueueFull3:
	set_dd8 0x02, 0x9e                            ; FA5828  f0 9e ba
	incdi8 0x01, (0x0932)                         ; FA582B  c1 32 09 61
	ret                                           ; FA582F  0e

; ---------------------------------------------------------------------
; MIDI_RX_SystemCommon -- the 0xFn arm of MIDI_StatusDispatch_Table
;
; Called from: MIDI_StatusDispatch_Table slot 7
; Inputs:  D = the status byte (0xF0-0xF7), E = the first data byte
; Outputs: running status cleared; then per message
; Evidence: three explicit compares and a fall-through:
;            0xF0 SYSTEM EXCLUSIVE   -> MIDI_RX_SysExStart
;            0xF2 SONG POSITION      -> MIDI_RX_SongPosition, two data bytes
;            0xF3 SONG SELECT        -> MIDI_RX_DeliverTwo, one data byte
;            anything else           -> RET, i.e. 0xF1 MIDI Time Code Quarter
;                                       Frame and 0xF6 Tune Request are IGNORED
;          Clearing (0x9A) first is the MIDI 1.0 rule that a System Common
;          message cancels running status, and it is done unconditionally --
;          before the dispatch, so it applies to the ignored ones too.
; ---------------------------------------------------------------------
MIDI_RX_SystemCommon:
	ldio 0x9a, 0x00                               ; FA5830  08 9a 00   System Common cancels running status
	cp D,0xf0                                     ; FA5833  cc cf f0
	jr z, MIDI_RX_SysExStart                      ; FA5836  66 15
	cp D,0xf2                                     ; FA5838  cc cf f2
	jr z, MIDI_RX_SongPosition                    ; FA583B  66 06
	cp D,0xf3                                     ; FA583D  cc cf f3
	jr z, MIDI_RX_SongSelect                      ; FA5840  66 08
	ret                                           ; FA5842  0e
MIDI_RX_SongPosition:
	m_or_mi8 MB8, 0x9e, 0x42                      ; FA5843  c0 9e 3e 42   bit 6 = a byte is pending, bit 1 = it is an SPP
	ld C,E                                        ; FA5847  cd 8b
	ret                                           ; FA5849  0e
MIDI_RX_SongSelect:
	jrl MIDI_RX_DeliverTwo                        ; FA584A  78 62 ff

; ---------------------------------------------------------------------
; MIDI_RX_SysExStart -- 0xF0 arrived and this is its first data byte, the ID
;
; Called from: MIDI_RX_SystemCommon 0xFA5836
; Inputs:  D = 0xF0, E = the identifier byte
; Outputs: (0xA9) = 1 (armed).  If the identifier is accepted, bit 1 is set as
;          well and BOTH bytes are forwarded through prom_b 0xF41E3C.
; Evidence: exactly two identifiers are accepted, 0x50 and 0x7E, and every
;          other value leaves (0xA9) armed but NOT in-message -- so the rest of
;          that message reaches MIDI_RX_SysExData and is discarded there,
;          which is how a device ignores another maker's SysEx without losing
;          track of where it ends.
;          0x7E is MIDI's Universal Non-Real Time identifier.  0x50 is a
;          manufacturer identifier, and by the shape of the test it must be
;          this machine's own.  ⚠ Which company holds 0x50 is NOT established
;          here -- it needs the MMA's assignment list, which is not in this
;          tree.  Do not write a company name into this file on the strength
;          of the byte alone.
; Unknown:  (0xA9) bit 5, tested by MIDI_RX_SysExData and set nowhere in the
;          converted code.
; ---------------------------------------------------------------------
MIDI_RX_SysExStart:
	ldio 0xa9, 0x01                               ; FA584D  08 a9 01   armed
	cp E,0x50                                     ; FA5850  cd cf 50
	jr z, MIDI_SysEx_Accept                       ; FA5853  66 05
	cp E,0x7e                                     ; FA5855  cd cf 7e   Universal Non-Real Time
	jr nz, MIDI_SysEx_Ignore                      ; FA5858  6e 13
MIDI_SysEx_Accept:
	set_dd8 0x01, 0xa9                            ; FA585A  f0 a9 b9   in-message
	ld A,D                                        ; FA585D  cc 89
	pushw wa                                      ; FA585F  28
	call 0xf41e3c                                 ; FA5860  1d 3c 1e f4   forward the 0xF0
	inc 2,XSP                                     ; FA5864  ef 62
	pushw de                                      ; FA5866  2a
	call 0xf41e3c                                 ; FA5867  1d 3c 1e f4   forward the identifier
	inc 2,XSP                                     ; FA586B  ef 62
MIDI_SysEx_Ignore:
	ret                                           ; FA586D  0e

; ---------------------------------------------------------------------
; MIDI_RX_SysExData -- a data byte inside a System Exclusive message
;
; Called from: MIDI_RX_DataByte 0xFA576D, whenever (0xA9) bit 0 is set
; Inputs:  E = the byte, (0xA9) the SysEx state
; Outputs: the byte forwarded through prom_b 0xF41E3C, or dropped
; Evidence: it forwards only when bit 1 is set AND bit 5 is clear.  Bit 1 is
;          MIDI_RX_SysExStart's "the identifier was accepted", so a message
;          from an unrecognised maker is armed but never forwarded.
; ---------------------------------------------------------------------
MIDI_RX_SysExData:
	bit_dd8 0x01, 0xa9                            ; FA586E  f0 a9 c9   was the identifier accepted?
	jr z, MIDI_SysEx_DataDone                     ; FA5871  66 10
	bit_dd8 0x05, 0xa9                            ; FA5873  f0 a9 cd
	jr nz, MIDI_SysEx_DataDone                    ; FA5876  6e 0b
	m_set 0, MD16, 0x216f                         ; FA5878  f1 6f 21 b8   MIDI activity
	pushw de                                      ; FA587C  2a
	call 0xf41e3c                                 ; FA587D  1d 3c 1e f4
	inc 2,XSP                                     ; FA5881  ef 62
MIDI_SysEx_DataDone:
	ret                                           ; FA5883  0e

; ---------------------------------------------------------------------
; MIDI_Parser_LoadContext / MIDI_Parser_SaveContext -- the parser's own
; register set, in RAM at 0x0900
;
; Called from: MIDI_RX_Byte 0xFA54A8 (load) and 0xFA54F9 (save)
; Inputs/Outputs: all seven 32-bit registers, moved between the CPU and
;          0x0900-0x091B in the order XWA XBC XDE XHL XIX XIY XIZ
; Evidence: seven `ld XRR,(nn)` against seven `ld (nn),XRR` over the same seven
;          addresses four bytes apart, and MIDI_RX_Byte brackets its whole body
;          with one call to each -- INSIDE the push/pop of the interrupted
;          code's registers.  That nesting is the whole point: see this block's
;          header.
; Notes:   the block is 28 bytes, 0x0900-0x091B.  MIDI_Parser_ClearContext
;          zeroes exactly those seven longs, which is the independent check
;          that the block is seven entries and not eight.
; ---------------------------------------------------------------------
MIDI_Parser_LoadContext:
	ldda32 xwa, (0x0900)                          ; FA5884  e1 00 09 20
	ldda32 xbc, (0x0904)                          ; FA5888  e1 04 09 21
	ldda32 xde, (0x0908)                          ; FA588C  e1 08 09 22
	ldda32 xhl, (0x090c)                          ; FA5890  e1 0c 09 23
	ldda32 xix, (0x0910)                          ; FA5894  e1 10 09 24
	ldda32 xiy, (0x0914)                          ; FA5898  e1 14 09 25
	ldda32 xiz, (0x0918)                          ; FA589C  e1 18 09 26
	ret                                           ; FA58A0  0e
MIDI_Parser_SaveContext:
	stda32 (0x0900), xwa                          ; FA58A1  f1 00 09 60
	stda32 (0x0904), xbc                          ; FA58A5  f1 04 09 61
	stda32 (0x0908), xde                          ; FA58A9  f1 08 09 62
	stda32 (0x090c), xhl                          ; FA58AD  f1 0c 09 63
	stda32 (0x0910), xix                          ; FA58B1  f1 10 09 64
	stda32 (0x0914), xiy                          ; FA58B5  f1 14 09 65
	stda32 (0x0918), xiz                          ; FA58B9  f1 18 09 66
	ret                                           ; FA58BD  0e

; ---------------------------------------------------------------------
; MIDI_Reset -- bring the MIDI subsystem up
;
; Called from: MIDI_EntryThunks slot 3 (0xFA540C), converted above -- the
;          module's only live public entry point, built exactly like
;          LCD_EntryThunks at 0xF8E800.  ⚠ Nothing that reaches that table has
;          been found, so nothing here says WHEN the MIDI subsystem is reset.
; Inputs:  none
; Outputs: the parser context zeroed, the UART programmed, and two further
;          routines run
; Evidence: four calls and a return, nothing else.
; Unknown:  ⚠ 0xFA5BF7 is not converted, so what the third call does is open.
; ---------------------------------------------------------------------
MIDI_Reset:
	calr MIDI_Parser_ClearContext                 ; FA58BE  1e 0b 00
	calr MIDI_UART_Configure                      ; FA58C1  1e 2c 00
	call 0xfa5bf7                                 ; FA58C4  1d f7 5b fa
	calr sub_FA5926                               ; FA58C8  1e 5b 00
	ret                                           ; FA58CB  0e

; ---------------------------------------------------------------------
; MIDI_Parser_ClearContext -- zero the parser's seven saved registers
;
; Called from: MIDI_Reset 0xFA58BE
; Evidence: seven 32-bit stores of 0 to 0x0900, 0x0904 ... 0x0918 -- the same
;          seven addresses MIDI_Parser_LoadContext reads.
; ---------------------------------------------------------------------
MIDI_Parser_ClearContext:
	stdi8 (0x0900), 0x00                          ; FA58CC  f1 00 09 00 00
	stdi8 (0x0904), 0x00                          ; FA58D1  f1 04 09 00 00
	stdi8 (0x0908), 0x00                          ; FA58D6  f1 08 09 00 00
	stdi8 (0x090c), 0x00                          ; FA58DB  f1 0c 09 00 00
	stdi8 (0x0910), 0x00                          ; FA58E0  f1 10 09 00 00
	stdi8 (0x0914), 0x00                          ; FA58E5  f1 14 09 00 00
	stdi8 (0x0918), 0x00                          ; FA58EA  f1 18 09 00 00
	ret                                           ; FA58EF  0e

; ---------------------------------------------------------------------
; MIDI_UART_Configure -- program serial channel 0 for the MIDI current loop
;
; Called from: MIDI_Reset 0xFA58C1
; Inputs:  the byte at 0xFFFFF8
; Outputs: SC0MOD, SC0CR, BR0CR and SC0BUF written; (0x77) = 0x5D; the
;          interrupt mask raised to 6 for the duration and released to 0
; Evidence: the SFR numbers are the TMP95C061's -- 0x50 SC0BUF, 0x51 SC0CR,
;          0x52 SC0MOD, 0x53 BR0CR.  SC0MOD = 0x29 is 8-bit UART clocked from
;          the baud-rate generator, and BR0CR = 0x0E divides by 896:
;          31250 x 896 = 28,000,000, which is where
;          notes/FINDINGS-system-clock.md gets fc = 28 MHz.
; Notes:   ★ THE 0x0C BRANCH IS DEAD, and that is checkable rather than
;          assumed.  0xFFFFF8 is inside this ROM's BUILD_TAG and holds 0x02,
;          not 0x24, so the compare at 0xFA58FB always fails and BR0CR stays
;          0x0E.  See the BUILD_TAG block at the end of this file, and
;          notes/FINDINGS-system-clock.md, which enumerates every BR0CR writer
;          in both images.
;          `ei 0x06` RAISES the interrupt mask and `ei 0x00` releases it, so
;          the pair brackets a critical section -- the reverse of what the
;          mnemonic suggests.  See notes/llvm-mc-tlcs900-spellings.md.
; Unknown:  why SC0BUF is written 0xFE at the end.  (0x77) is the one-byte
;          mailbox MIDI_TX_Ready also writes.
; ---------------------------------------------------------------------
MIDI_UART_Configure:
	ei 0x06                                       ; FA58F0  06 06   RAISE the mask: critical section
	ldio 0x52, 0x29                               ; FA58F2  08 52 29   SC0MOD = 8-bit UART, baud-rate generator
	ldio 0x51, 0x00                               ; FA58F5  08 51 00   SC0CR cleared
	ldio 0x53, 0x0e                               ; FA58F8  08 53 0e   BR0CR: divide by 896 -> 31250 baud at fc = 28 MHz
	m_cp_mi8 MB24, 0xfffff8, 0x24                 ; FA58FB  c2 f8 ff ff 3f 24   the byte here is 0x02 -- never equal
	jr nz, .LFA5906                               ; FA5901  6e 03
	ldio 0x53, 0x0c                               ; FA5903  08 53 0c   divide by 768 -- NOT REACHED
.LFA5906:
	ldio 0x77, 0x5d                               ; FA5906  08 77 5d
	ldio 0x50, 0xfe                               ; FA5909  08 50 fe   SC0BUF
	ei 0x00                                       ; FA590C  06 00   release the mask
	ret                                           ; FA590E  0e

; ---------------------------------------------------------------------
; MIDI_PostSendWork -- wake the transmitter
;
; Called from: prom_b thunk 0xF40724 (`jp 0xFA590F`), and 0xFA5BD1, 0xFA5C81
; Inputs:  (0x89)
; Outputs: either (0x77) = 0xDD, or prom_b 0xF41E00 is called and (0xA0)
;          cleared
; Evidence: this is the routine FINDINGS-midi-port.md already names as the
;          other writer of the (0x77) mailbox; MIDI_TX_Ready writes 0xFD there
;          when it runs dry.  (0xA0) is the System Real Time request bitmap
;          that same note decodes, and clearing it abandons every pending
;          real-time byte.
; Notes:   `push SR` / `ei 0x06` / ... / `pop SR` is the save-and-raise form of
;          the critical section: the old mask is restored rather than forced
;          to 0.
; Unknown:  ⚠ what (0x89) == 0xFF means.  It selects the whole second arm, so
;          it is not a detail.
; ---------------------------------------------------------------------
MIDI_PostSendWork:
	push SR                                       ; FA590F  02
	ei 0x06                                       ; FA5910  06 06
	m_cp_mi8 MB8, 0x89, 0xff                      ; FA5912  c0 89 3f ff
	jr z, .LFA591D                                ; FA5916  66 05
	ldio 0x77, 0xdd                               ; FA5918  08 77 dd   the mailbox MIDI_TX_Ready also writes
	pop SR                                        ; FA591B  03
	ret                                           ; FA591C  0e
.LFA591D:
	call 0xf41e00                                 ; FA591D  1d 00 1e f4
	ldio 0xa0, 0x00                               ; FA5921  08 a0 00   drop every pending real-time request
	pop SR                                        ; FA5924  03
	ret                                           ; FA5925  0e

; ---------------------------------------------------------------------
; sub_FA5926 -- mirror "(0xC4) == 2" into bit 0 of (0x0925)
;
; Called from: MIDI_Reset 0xFA58C8
; Inputs:  (0xC4)
; Outputs: bit 0 of (0x0925) set if (0xC4) == 2, cleared otherwise
; Evidence: that is the whole routine -- clear the bit, compare, set it back.
; Unknown:  ⚠ deliberately NOT named.  Neither (0xC4) nor (0x0925) is
;          identified anywhere in this tree, so any name would be a guess about
;          what the two mean.  It is called only from MIDI_Reset, which is a
;          hint that (0xC4) is a MIDI-related mode byte and nothing more.
; ---------------------------------------------------------------------
sub_FA5926:
	m_res 0, MD16, 0x0925                         ; FA5926  f1 25 09 b0
	m_cp_mi8 MB8, 0xc4, 0x02                      ; FA592A  c0 c4 3f 02
	jr nz, .LFA5934                               ; FA592E  6e 04
	m_set 0, MD16, 0x0925                         ; FA5930  f1 25 09 b8
.LFA5934:
	ret                                           ; FA5934  0e

; ---------------------------------------------------------------------
; sub_FA5935 -- call prom_b 0xF406A0 with four registers preserved
;
; Called from: MIDI_Fg_Deliver2 (0xFA5A93) and MIDI_Fg_Deliver3 (0xFA5AC6),
;          both `calr`.  ⚠ An earlier version of this header said no caller had
;          been found, citing notes/prom_a_xref.py -- which is an ABSOLUTE
;          reference search and cannot see a `calr`.  The two callers turned up
;          as soon as their neighbourhood was converted.  Recorded because it is
;          the same trap that produced "Dev7A_StartDma has no callers" earlier
;          in this tree: "prom_a_xref found nothing" is not "nothing calls it".
; Inputs:  XIX = a buffer on the caller's frame (2 bytes at 0xFA5A93, 4 at
;          0xFA5AC6); whatever else 0xF406A0 takes
; Outputs: whatever it returns; XDE, XHL, XIX and XIZ are preserved
; Notes:   both callers do the same thing straight afterwards -- fill that
;          buffer with a MIDI message and hand it to prom_b 0xF41DD4 -- so this
;          is very likely the buffer's initialiser.
; Unknown:  ⚠ still NOT named.  "Very likely the initialiser" is a reading of
;          two call sites, not a fact about 0xF406A0, which is a prom_b thunk
;          this tree has not resolved.
; ---------------------------------------------------------------------
sub_FA5935:
	push XDE                                      ; FA5935  3a
	push XHL                                      ; FA5936  3b
	push XIX                                      ; FA5937  3c
	push XIZ                                      ; FA5938  3e
	call 0xf406a0                                 ; FA5939  1d a0 06 f4
	pop XIZ                                       ; FA593D  5e
	pop XIX                                       ; FA593E  5c
	pop XHL                                       ; FA593F  5b
	pop XDE                                       ; FA5940  5a
	ret                                           ; FA5941  0e

; ==============================================================================
; 0xFA5942-0xFA5AEA -- the FOREGROUND MIDI consumer
; ==============================================================================
;
; ★ THERE ARE TWO MIDI STATE MACHINES IN THIS FIRMWARE, NOT ONE, AND THEY HAVE
;   THE SAME SHAPE.  The interrupt-time parser at 0xFA5763 keeps
;
;       (0x9A)   running status      (0x9E)   receive flags      (0xA9)  SysEx
;
;   and this block, which runs in the foreground, keeps its own private trio
;
;       (0x0960) running status      (0x0963) flags              (0x0964) SysEx
;
;   used the same way, bit for bit: bit 6 of the flag byte is "a first data
;   byte is pending", bit 1 goes with it, and both are cleared with the same
;   `and ...,0xbd` mask that MIDI_RX_Byte uses on (0x9E).  Each machine even has
;   its own eight-entry status-nibble jump table.  The division of labour is
;   that the interrupt side takes bytes off the UART and packs them into a
;   queue; this side takes them out again and turns each complete message into
;   an application event.
;
;   ⚠ ONE DELIBERATE DIFFERENCE, and it is worth knowing before trusting either
;   table: the interrupt side's table sends Polyphonic Key Pressure to a bare
;   RET (see MIDI_StatusDispatch_Table), while THIS table treats it like every
;   other two-data-byte message.  The foreground code is willing to handle it;
;   the interrupt code never lets it through.  So "the WSA1 ignores Poly Key
;   Pressure" is a statement about the interrupt parser, which is where it is
;   decided, and this table is not evidence against it.
;
; ⚠ WHICH QUEUE.  This block drains through prom_b 0xF41D18 and posts through
; prom_b 0xF41DD4 and 0xF41B18.  MIDI_TX_Ready drains the OUTPUT queue through
; a different routine, 0xF41DF0, and the interrupt parser fills through
; 0xF41DAC.  Nothing converted here proves 0xF41D18 and 0xF41DAC are the two
; ends of one queue -- they are in prom_b, another lane -- so this block is
; named for what it demonstrably does (drain a queue and dispatch) and not for
; the direction.
;
; ---------------------------------------------------------------------
; MIDI_DrainQueue -- take messages out of the queue until it is empty
;
; Called from: not traced.  ⚠ notes/prom_a_xref.py finds no absolute reference
;          to 0xFA5942 in either image; a `calr` would be invisible to it.
; Inputs:  the queue behind prom_b 0xF41D18, which returns 0xFFFF when empty
; Outputs: every byte dispatched; HL and DE preserved
; Evidence: the same three-way split on the byte as MIDI_RX_Byte --
;            bit 7 clear   -> MIDI_Fg_DataByte
;            0x80-0xF7     -> handled inline: it becomes (0x0960), the
;                             foreground running status
;            0xF8-0xFF     -> MIDI_Fg_RealTime
;          and the loop only ends on 0xFFFF.
; Notes:   the 0x80-0xF7 arm is guarded by BOTH bits 0 and 1 of (0x0964): a
;          status byte is only acted on further while a SysEx is open.  0xF7
;          (END OF EXCLUSIVE) then closes it through prom_b 0xF41EA8 and leaves
;          (0x0964) = 4; any other status abandons it with (0x0964) = 0.  Either
;          way (0x0960) is cleared, so a status byte never becomes running
;          status for the SysEx path.
; Unknown:  ⚠ what (0x0964) = 4 means to whoever reads it.
; ---------------------------------------------------------------------
MIDI_DrainQueue:
	pushw hl                                      ; FA5942  2b
	pushw de                                      ; FA5943  2a
MIDI_DrainQueue__next:
	call 0xf41d18                                 ; FA5944  1d 18 1d f4   take one byte; 0xFFFF = empty
	ld DE,WA                                      ; FA5948  d8 8a
	cp WA,0xffff                                  ; FA594A  d8 cf ff ff
	jr z, MIDI_DrainQueue__done                   ; FA594E  66 58
	ld H,A                                        ; FA5950  c9 8e
	and A,0x80                                    ; FA5952  c9 cc 80
	jr z, MIDI_DrainQueue__data                   ; FA5955  66 46   bit 7 clear = a data byte
	cp H,0xf7                                     ; FA5957  ce cf f7
	jr ule, MIDI_DrainQueue__status               ; FA595A  63 0a   0x80-0xF7
	ld C,H                                        ; FA595C  ce 8b   0xF8-0xFF = System Real Time
	extz BC                                       ; FA595E  d9 12
	pushw bc                                      ; FA5960  29
	calr MIDI_Fg_RealTime                         ; FA5961  1e 47 00
	jr MIDI_DrainQueue__pop                       ; FA5964  68 3f
MIDI_DrainQueue__status:
	stb_d8 (0x0960), h                            ; FA5966  f1 60 09 46   the foreground running status
	m_and_mi8 MB16, 0x0963, 0xbd                  ; FA596A  c1 63 09 3c bd   clear bits 6 and 1
	m_bit 0, MD16, 0x0964                         ; FA596F  f1 64 09 c8   a SysEx armed?
	jr z, MIDI_DrainQueue__next                   ; FA5973  66 cf
	m_bit 1, MD16, 0x0964                         ; FA5975  f1 64 09 c9   and accepted?
	jr z, MIDI_DrainQueue__next                   ; FA5979  66 c9
	cp H,0xf7                                     ; FA597B  ce cf f7   END OF EXCLUSIVE?
	jr nz, MIDI_DrainQueue__abandon               ; FA597E  6e 11
	ld C,H                                        ; FA5980  ce 8b
	extz BC                                       ; FA5982  d9 12
	pushw bc                                      ; FA5984  29
	call 0xf41ea8                                 ; FA5985  1d a8 1e f4   close the SysEx
	stdi8 (0x0964), 0x04                          ; FA5989  f1 64 09 00 04
	popw bc                                       ; FA598E  49
	jr MIDI_DrainQueue__clearstatus               ; FA598F  68 05
MIDI_DrainQueue__abandon:
	stdi8 (0x0964), 0x00                          ; FA5991  f1 64 09 00 00   any other status abandons it
MIDI_DrainQueue__clearstatus:
	stdi8 (0x0960), 0x00                          ; FA5996  f1 60 09 00 00
	jr MIDI_DrainQueue__next                      ; FA599B  68 a7
MIDI_DrainQueue__data:
	ld C,H                                        ; FA599D  ce 8b
	extz BC                                       ; FA599F  d9 12
	pushw bc                                      ; FA59A1  29
	calr MIDI_Fg_DataByte                         ; FA59A2  1e 55 00
MIDI_DrainQueue__pop:
	popw bc                                       ; FA59A5  49
	jr MIDI_DrainQueue__next                      ; FA59A6  68 9c
MIDI_DrainQueue__done:
	popw de                                       ; FA59A8  4a
	popw hl                                       ; FA59A9  4b
	ret                                           ; FA59AA  0e

; ---------------------------------------------------------------------
; MIDI_Fg_RealTime -- a System Real Time byte reached the foreground
;
; Called from: MIDI_DrainQueue 0xFA5961, with the byte as a 16-bit stack argument
; Inputs:  the byte at (XIZ+0x08); (0x0922), a transport flag byte
; Outputs: for 0xFA / 0xFB, bit 1 of (0x0922) is updated and a four-argument
;          message is posted through prom_b 0xF41B18; for 0xFF, bit 5 of (0x9E)
;          is set; every other real-time byte is ignored here.
; Evidence: three explicit compares -- 0xFA, 0xFB, 0xFF -- and a fall-through
;          that does nothing.  0xFA is MIDI START and 0xFB is CONTINUE, and the
;          two arms differ ONLY in `res 1,H` versus `set 1,H`, so bit 1 of
;          (0x0922) is "this transport run was resumed rather than started".
;          0xFC STOP, 0xF8 TIMING CLOCK and 0xFE ACTIVE SENSING are NOT handled
;          here -- the interrupt-side handler at 0xFA5504 already deals with
;          them.
; Notes:   ★ AND A CORRECTION THAT CROSSES ROUTINES.  0xFF is SYSTEM RESET, and
;          this arm sets bit 5 of (0x9E).  That is the SAME bit INTT1_Tick sets
;          when the active-sensing timeout expires -- at 0xF82D30 it does
;          `and A,0x7f` then `or A,0x20` and writes A back to (0x9E) at
;          0xF82D4A, a read-modify-write rather than a `set` instruction, which
;          is why a census of `set 5,(0x9e)` finds only THIS site.
;          Two independent events set it, so bit 5 is not "active sensing timed
;          out": it is the condition both of them mean, i.e. "the link has gone
;          away, treat everything as reset".  Neither writer alone shows that.
;          The posted message is `(0xA8, 0x10, flags, 2)` pushed in that order
;          --  ⚠ two of those four are bare constants whose meaning is not
;          established, and 0xF41B18 is in prom_b.
; Unknown:  (0x0922) beyond bit 1; the two constants; who reads the message.
; ---------------------------------------------------------------------
MIDI_Fg_RealTime:
	link XIZ,0x0000                               ; FA59AB  ee 0c 00 00
	pushw hl                                      ; FA59AF  2b
	push XIX                                      ; FA59B0  3c
	lda_d16 xix, (0x0922)                         ; FA59B1  f1 22 09 34   XIX = &(0x0922)
	ld BC,(XIZ+0x08)                              ; FA59B5  9e 08 21   the byte
	extz BC                                       ; FA59B8  d9 12
	cp BC,0x00fa                                  ; FA59BA  d9 cf fa 00   START
	jr z, MIDI_Fg_RealTime__start                 ; FA59BE  66 0e
	cp BC,0x00fb                                  ; FA59C0  d9 cf fb 00   CONTINUE
	jr z, MIDI_Fg_RealTime__continue              ; FA59C4  66 0f
	cp BC,0x00ff                                  ; FA59C6  d9 cf ff 00   SYSTEM RESET
	jr z, MIDI_Fg_RealTime__reset                 ; FA59CA  66 26
	jr MIDI_Fg_RealTime__ret                      ; FA59CC  68 27   anything else: ignored here
MIDI_Fg_RealTime__start:
	ld H,(XIX)                                    ; FA59CE  84 26
	res 0x01,H                                    ; FA59D0  ce 30 01   started, not resumed
	jr MIDI_Fg_RealTime__post                     ; FA59D3  68 05
MIDI_Fg_RealTime__continue:
	ld H,(XIX)                                    ; FA59D5  84 26
	set 0x01,H                                    ; FA59D7  ce 31 01   resumed
MIDI_Fg_RealTime__post:
	ld (XIX),H                                    ; FA59DA  b4 46
	pushw 0x02                                    ; FA59DC  0b 02 00
	ld C,H                                        ; FA59DF  ce 8b
	extz BC                                       ; FA59E1  d9 12
	pushw bc                                      ; FA59E3  29
	pushw 0x10                                    ; FA59E4  0b 10 00
	pushw 0xa8                                    ; FA59E7  0b a8 00
	call 0xf41b18                                 ; FA59EA  1d 18 1b f4
	inc 0,XSP                                     ; FA59EE  ef 60
	jr MIDI_Fg_RealTime__ret                      ; FA59F0  68 03
MIDI_Fg_RealTime__reset:
	set_dd8 0x05, 0x9e                            ; FA59F2  f0 9e bd   see the ★ note above
MIDI_Fg_RealTime__ret:
	pop XIX                                       ; FA59F5  5c
	popw hl                                       ; FA59F6  4b
	unlk XIZ                                      ; FA59F7  ee 0d
	ret                                           ; FA59F9  0e

; ---------------------------------------------------------------------
; MIDI_Fg_DataByte -- a data byte reached the foreground
;
; Called from: MIDI_DrainQueue 0xFA59A2, with the byte as a stack argument
; Inputs:  (0x0964) SysEx state, (0x0963) flags, (0x0960) running status
; Outputs: the byte routed to one of four places
; Evidence: the priority order is the interrupt parser's, one for one:
;            (0x0964) bit 0 -- a SysEx is open   -> 0xFA5B3D
;            (0x0963) bit 6 -- a byte is pending -> MIDI_Fg_Deliver3
;            (0x0960) == 0  -- no running status -> return
;            otherwise indexed through MIDI_Fg_LengthTable
; Notes:   the index is built differently from the interrupt side's and is
;          bounds-checked rather than masked: `and C,0x70` then `srl 4` gives
;          0..7 directly, `cp BC,7` / `jr ugt` rejects anything above 7, and
;          only then is it scaled by 4.  Same eight slots, belt and braces.
; ---------------------------------------------------------------------
MIDI_Fg_DataByte:
	link XIZ,0x0000                               ; FA59FA  ee 0c 00 00
	pushw hl                                      ; FA59FE  2b
	ld H,(XIZ+0x08)                               ; FA59FF  8e 08 26
	m_bit 0, MD16, 0x0964                         ; FA5A02  f1 64 09 c8   inside a SysEx?
	jr z, .LFA5A12                                ; FA5A06  66 0a
	ld C,H                                        ; FA5A08  ce 8b
	extz BC                                       ; FA5A0A  d9 12
	pushw bc                                      ; FA5A0C  29
	calr (0xFA5B3D - 0xFA5A10)                    ; FA5A0D  1e 2d 01   the SysEx data sink, not converted
	jr MIDI_Fg_DataByte__pop                      ; FA5A10  68 5e
.LFA5A12:
	m_bit 6, MD16, 0x0963                         ; FA5A12  f1 63 09 ce   a first data byte pending?
	jr z, .LFA5A22                                ; FA5A16  66 0a
	ld C,H                                        ; FA5A18  ce 8b
	extz BC                                       ; FA5A1A  d9 12
	pushw bc                                      ; FA5A1C  29
	calr MIDI_Fg_Deliver3                         ; FA5A1D  1e 9e 00
	jr MIDI_Fg_DataByte__pop                      ; FA5A20  68 4e
.LFA5A22:
	m_cp_mi8 MB16, 0x0960, 0x00                   ; FA5A22  c1 60 09 3f 00   no running status?
	jr z, MIDI_Fg_DataByte__ret                   ; FA5A27  66 5e
	ldb_d8 c, (0x0960)                            ; FA5A29  c1 60 09 23
	and C,0x70                                    ; FA5A2D  cb cc 70
	srl c, 0x04                                   ; FA5A30  cb ef 04   the status nibble, 0..7
	extz BC                                       ; FA5A33  d9 12
	extz XBC                                      ; FA5A35  e9 12
	cps bc, 0x07                                  ; FA5A37  d9 df
	jr ugt, MIDI_Fg_DataByte__ret                 ; FA5A39  6b 4c   an explicit bound on the table
	sll bc, 0x02                                  ; FA5A3B  d9 ee 02   * 4
	add XBC,0x00fa5a48                            ; FA5A3E  e9 c8 48 5a fa 00
	ld XBC,(XBC)                                  ; FA5A44  a1 21
	jp (xbc)                                      ; FA5A46  b1 d8

; ---------------------------------------------------------------------
; MIDI_Fg_LengthTable -- eight LE32 handlers, the foreground's copy
;
; Called from: MIDI_Fg_DataByte 0xFA5A46
; Layout:  8 entries x 4 bytes = 32 bytes, 0xFA5A48-0xFA5A67.  The count is not
;          inferred: 0xFA5A37 compares the index against 7 and rejects anything
;          greater BEFORE the scale by 4, so eight is the table's declared size.
; Evidence: the grouping is the MIDI data-byte count again --
;            0 0x8n Note Off          -> MIDI_Fg_Await   (two data bytes)
;            1 0x9n Note On           -> MIDI_Fg_Await
;            2 0xAn Poly Key Pressure -> MIDI_Fg_Await   <-- handled here!
;            3 0xBn Control Change    -> MIDI_Fg_Await
;            4 0xCn Program Change    -> MIDI_Fg_Emit2   (one data byte)
;            5 0xDn Channel Pressure  -> MIDI_Fg_Emit2
;            6 0xEn Pitch Bend        -> MIDI_Fg_Await
;            7 0xFn System            -> 0xFA5AEB, not converted
;          ⚠ slot 2 differs from the interrupt side's table, which sends Poly
;          Key Pressure to a bare RET.  See this block's header: the discard
;          happens in the interrupt parser, so nothing ever reaches slot 2.
; ---------------------------------------------------------------------
MIDI_Fg_LengthTable:
	.long MIDI_Fg_Await	; FA5A48  73 5a fa 00   0x8n Note Off
	.long MIDI_Fg_Await	; FA5A4C  73 5a fa 00   0x9n Note On
	.long MIDI_Fg_Await	; FA5A50  73 5a fa 00   0xAn Poly Key Pressure
	.long MIDI_Fg_Await	; FA5A54  73 5a fa 00   0xBn Control Change
	.long MIDI_Fg_Emit2	; FA5A58  68 5a fa 00   0xCn Program Change
	.long MIDI_Fg_Emit2	; FA5A5C  68 5a fa 00   0xDn Channel Pressure
	.long MIDI_Fg_Await	; FA5A60  73 5a fa 00   0xEn Pitch Bend
	.long MIDI_Fg_System	; FA5A64  7d 5a fa 00   0xFn System

MIDI_Fg_Emit2:
	ld C,H                                        ; FA5A68  ce 8b
	extz BC                                       ; FA5A6A  d9 12
	pushw bc                                      ; FA5A6C  29
	calr MIDI_Fg_Deliver2                         ; FA5A6D  1e 1b 00
MIDI_Fg_DataByte__pop:
	popw bc                                       ; FA5A70  49
	jr MIDI_Fg_DataByte__ret                      ; FA5A71  68 14
MIDI_Fg_Await:
	ld C,H                                        ; FA5A73  ce 8b
	extz BC                                       ; FA5A75  d9 12
	pushw bc                                      ; FA5A77  29
	calr MIDI_Fg_StashFirstData                   ; FA5A78  1e 33 00
	jr MIDI_Fg_DataByte__pop                      ; FA5A7B  68 f3
MIDI_Fg_System:
	ld C,H                                        ; FA5A7D  ce 8b
	extz BC                                       ; FA5A7F  d9 12
	pushw bc                                      ; FA5A81  29
	calr (0xFA5AEB - 0xFA5A85)                    ; FA5A82  1e 66 00   the System Common handler, not converted
	jr MIDI_Fg_DataByte__pop                      ; FA5A85  68 e9
MIDI_Fg_DataByte__ret:
	popw hl                                       ; FA5A87  4b
	unlk XIZ                                      ; FA5A88  ee 0d
	ret                                           ; FA5A8A  0e

; ---------------------------------------------------------------------
; MIDI_Fg_Deliver2 -- post a two-byte message: {running status, data}
;
; Called from: MIDI_Fg_Emit2 0xFA5A6D
; Inputs:  the data byte as a stack argument; (0x0960) the running status
; Outputs: a 2-byte buffer on this frame is filled and handed to prom_b
;          0xF41DD4 with a length of 2
; Evidence: `link XIZ,0xfffe` reserves exactly TWO bytes and `push 0x0002` is
;          the length passed -- the frame size and the length argument agree,
;          which is what makes this a message builder rather than a copy.
; Notes:   ★ it calls sub_FA5935 (0xFA5935) on the buffer address before filling
;          it.  That routine's header used to say no caller had been found; this
;          site and 0xFA5AC6 are its two callers, both `calr`, which is why
;          notes/prom_a_xref.py could not see them.
; ---------------------------------------------------------------------
MIDI_Fg_Deliver2:
	link XIZ,0xfffe                               ; FA5A8B  ee 0c fe ff   two bytes of frame
	push XIX                                      ; FA5A8F  3c
	lda xix, (xiz-2)                              ; FA5A90  be fe 34
	calr (0xFA5935 - 0xFA5A96)                    ; FA5A93  1e 9f fe   sub_FA5935
	m_ld_mm16 MDI+r4, 0, 0x0960                   ; FA5A96  b4 14 60 09   buffer[0] = running status
	ld C,(XIZ+0x08)                               ; FA5A9A  8e 08 23
	ld (XIX+0x01),C                               ; FA5A9D  bc 01 43   buffer[1] = the data byte
	push XIX                                      ; FA5AA0  3c
	pushw 0x02                                    ; FA5AA1  0b 02 00   length 2
	call 0xf41dd4                                 ; FA5AA4  1d d4 1d f4
	inc 6,XSP                                     ; FA5AA8  ef 66
	pop XIX                                       ; FA5AAA  5c
	unlk XIZ                                      ; FA5AAB  ee 0d
	ret                                           ; FA5AAD  0e

; ---------------------------------------------------------------------
; MIDI_Fg_StashFirstData -- remember the first of two data bytes
;
; Called from: MIDI_Fg_Await 0xFA5A78
; Outputs: (0x0961) = the byte, and bit 6 of (0x0963) set so the NEXT data byte
;          takes MIDI_Fg_Deliver3
; Evidence: the two stores ARE the name -- `set 6,(0x0963)` at 0xFA5AB2 and the
;          mem-to-mem `ld (0x0961),(XIZ+0x08)` at 0xFA5AB6 -- and bit 6 of
;          (0x0963) is the flag the foreground parser tests to route the next
;          data byte, exactly as bit 6 of (0x9E) does in the interrupt parser.
;          The parallel with MIDI_RX_AwaitSecondByte is the reading in Notes,
;          not part of the evidence.
; Notes:   the foreground counterpart of MIDI_RX_AwaitSecondByte, which stashes
;          in C and sets bit 6 of (0x9E).  This one has to use RAM instead of a
;          register because, unlike the interrupt parser, it has no persistent
;          register context.
; ---------------------------------------------------------------------
MIDI_Fg_StashFirstData:
	link XIZ,0x0000                               ; FA5AAE  ee 0c 00 00
	m_set 6, MD16, 0x0963                         ; FA5AB2  f1 63 09 be
	.byte 0x8e, 0x08, 0x19, 0x61, 0x09            ; FA5AB6  8e 08 19 61 09   ld (0x0961),(XIZ+0x08) -- llvm-mc has no spelling for mem-to-mem
	unlk XIZ                                      ; FA5ABB  ee 0d
	ret                                           ; FA5ABD  0e

; ---------------------------------------------------------------------
; MIDI_Fg_Deliver3 -- post a three-byte message: {status, data1, data2}
;
; Called from: MIDI_Fg_DataByte 0xFA5A1D
; Inputs:  the second data byte as a stack argument; (0x0960) status,
;          (0x0961) the first data byte
; Outputs: a 3-byte buffer handed to prom_b 0xF41DD4 with a length of 3, and
;          bits 6 and 1 of (0x0963) cleared
; Evidence: `link XIZ,0xfffc` reserves four bytes for a three-byte message and
;          `push 0x0003` is the length -- the same builder as MIDI_Fg_Deliver2
;          with one more field.  The trailing `and (0x0963),0xbd` is the same
;          mask MIDI_DrainQueue and MIDI_RX_Byte use.
; ---------------------------------------------------------------------
MIDI_Fg_Deliver3:
	link XIZ,0xfffc                               ; FA5ABE  ee 0c fc ff
	push XIX                                      ; FA5AC2  3c
	lda xix, (xiz-4)                              ; FA5AC3  be fc 34
	calr (0xFA5935 - 0xFA5AC9)                    ; FA5AC6  1e 6c fe   sub_FA5935
	m_ld_mm16 MDI+r4, 0, 0x0960                   ; FA5AC9  b4 14 60 09   buffer[0] = status
	m_ld_mm16 MDD+r4, 0x01, 0x0961                ; FA5ACD  bc 01 14 61 09   buffer[1] = first data byte
	ld C,(XIZ+0x08)                               ; FA5AD2  8e 08 23
	ld (XIX+0x02),C                               ; FA5AD5  bc 02 43   buffer[2] = second data byte
	push XIX                                      ; FA5AD8  3c
	pushw 0x03                                    ; FA5AD9  0b 03 00   length 3
	call 0xf41dd4                                 ; FA5ADC  1d d4 1d f4
	m_and_mi8 MB16, 0x0963, 0xbd                  ; FA5AE0  c1 63 09 3c bd
	inc 6,XSP                                     ; FA5AE5  ef 66
	pop XIX                                       ; FA5AE7  5c
	unlk XIZ                                      ; FA5AE8  ee 0d
	ret                                           ; FA5AEA  0e
	.incbin "original_ROMs/wsa1_prom_a.ic12", 0x025AEB, 0x03F9CB

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
; Evidence: the sign handling is literal and is what the name rests on -- E is
;          zeroed, bit 15 of QWA is tested at 0xFE68F5 and the dividend
;          complemented, and the same is done for the divisor, before the
;          unsigned kernel is called and the sign re-applied.
;          ⚠ "SignedDiv" also comes from the KN5000 sibling
;          (subcpu_fp_math.s:1014); per this tree's rule that is a BORROWED
;          name, so it is the structure above, not the sibling, that carries it
;          here.
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
; Evidence: each entry is two instructions -- `ldb d,imm` then `jr
;          Int_SignedDiv` -- and D is precisely the quotient/remainder
;          selector Int_SignedDiv reads, so the names follow from the
;          immediate: 0 at 0xFE693A, 1 at 0xFE693E. The sibling's own text is
;          cited in Notes for contrast, not as the evidence.
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
; Evidence: "unsigned" is the absence of any sign test -- the routine opens `cp
;          XBC,0x00000001` at 0xFE6948 and goes straight into magnitude
;          comparisons (`cp XWA,XBC` / `jr ule` at 0xFE6952) with no
;          bit-15/bit-31 test anywhere, which is exactly why Int_SignedDiv has
;          to take absolute values before calling it. Its two callers are
;          named above and both are inside this file.
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
