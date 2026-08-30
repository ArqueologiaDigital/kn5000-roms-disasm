; ==============================================================================
; include/tlcs900_mem_ops.inc -- the TLCS-900 byte-emitter macros, ONE COPY
; ==============================================================================
;
; ★ THIS FILE IS SHARED.  It is `.include`d by
;
;     prom_a/wsa1_prom_a.s   CPU 1, IC12, base 0xF80000
;     prom_b/wsa1_prom_b.s   CPU 1, IC13, base 0xF00000   -- the same program
;     kernel/kernel.s        the kernel prom_a and prom_c both run
;
; and it exists because it used to be TWO copies.  prom_a carried the full set
; between `; MACRO-PRELUDE-BEGIN` and `; MACRO-PRELUDE-END`; kernel/kernel.s
; carried a 17-name subset of the same text under `.ifndef
; KERNEL_MEM_OPS_PROVIDED`, because prom_a must not see the definitions twice --
; llvm-mc rejects a redefined macro.  Two copies of an encoder is two things to
; keep right; the guard is still here, so prom_a still sees exactly one set, but
; there is now only one text to be wrong.
;
; ⚠ THE GUARD IS STILL LOAD-BEARING.  prom_a includes this file directly AND
;   includes kernel/kernel.s, which includes it again.  kernel_maincpu.inc sets
;   KERNEL_MEM_OPS_PROVIDED so the second include is a no-op; kernel_subcpu.inc
;   does not, because prom_c reaches these macros only through the kernel.
;   prom_b sets it too, immediately after its own direct include, for the same
;   reason prom_a does not need to: prom_b does not include the kernel, so the
;   symbol simply records "already provided".
;
; ⚠ EVERY MACRO HERE EMITS BYTES.  The gate
;       python3 scripts/analysis/assert_byte_identical.py
;   proves the bytes.  It CANNOT prove the NAME on a macro is the right
;   mnemonic; that comes from MAME's dasm900.cpp tables cited below, and every
;   use carries the disassembler's own text in its trailing comment so the two
;   can be compared by eye.
;
; The text below this line is prom_a's original prelude, MOVED VERBATIM.
; ==============================================================================

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
.macro m_div pfx, addr, r		; div  RR,(addr)		op 0x50+r
	_mem \pfx, \addr
	.byte 0x50 + (\r)
.endm
.macro m_divs pfx, addr, r		; divs RR,(addr)		op 0x58+r
	_mem \pfx, \addr
	.byte 0x58 + (\r)
.endm
; ⚠ RENAMED 2026-08-30, and the old name was wrong.  This macro was called
; `m_pushw`, but mnemonic_c0[0x06] is `rld A,(mem)` -- `pushw (mem)` is
; mnemonic_d0[0x04], which is what `m_push MW16, ...` already emits, and that is
; how every `pushw` row in prom_b is spelled.  Nothing ever used the old name:
; prom_a has 0 instances and prom_b has 0.  Found by reading dasm900.cpp's tables
; while correcting the carry-flag group below.
.macro m_rld_am pfx, addr		; rld A,(addr)			op 0x06
	_mem \pfx, \addr
	.byte 0x06
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

; --- the REGISTER-INDEXED operand: (R32+R16) and (R32+R8) --------------------
; dasm900.cpp:1543-1584.  Prefix 0xC3/0xD3/0xE3/0xF3 -- the same four operand
; sizes as MB*/MW*/ML*/MD* above, with the low two bits set to 3 -- then a
; SUB-MODE byte (0x07 = 16-bit index register, 0x03 = 8-bit index register),
; then the base and index REGISTER-ADDRESS bytes, then the operation byte from
; the same mnemonic_c0/d0/e0/f0 tables the direct-address macros use.
;
; The register-address bytes are indices into s_allreg32 / s_allreg16 /
; s_allreg8 (dasm900.cpp:1349-1405).  Only the last two rows of those tables
; name the CURRENT register bank, which is why every constant below is >= 0xE0.
;
; notes/prom_a-tooling.md listed "the register-indexed (rr+r) operand" as one of
; three shapes still emitted as raw .byte in both this tree's lanes.  It is not
; one any more; the shift-by-a-register forms still are.
.equ MXB, 0xC3		; byte operand at (R32+Ri)	-> mnemonic_c0[]
.equ MXW, 0xD3		; word operand at (R32+Ri)	-> mnemonic_d0[]
.equ MXL, 0xE3		; long operand at (R32+Ri)	-> mnemonic_e0[]
.equ MXD, 0xF3		; "dst"-table op at (R32+Ri)	-> mnemonic_f0[]

; Base register-address byte (s_allreg32) and 16-bit index byte (s_allreg16):
; the two tables carry the SAME numbers at these positions, so one set of names
; serves both operand positions.
.equ ra_WA, 0xE0
.equ ra_BC, 0xE4
.equ ra_DE, 0xE8
.equ ra_HL, 0xEC
.equ ra_IX, 0xF0
.equ ra_IY, 0xF4
.equ ra_IZ, 0xF8
.equ ra_SP, 0xFC
; 8-bit index byte -- s_allreg8 is a DIFFERENT table, hence its own names.
.equ rb_A, 0xE0
.equ rb_W, 0xE1
.equ rb_C, 0xE4
.equ rb_B, 0xE5
.equ rb_E, 0xE8
.equ rb_D, 0xE9
.equ rb_L, 0xEC
.equ rb_H, 0xED

.macro _memx pfx, base, idx		; (base32 + index16)
	.byte \pfx, 0x07, \base, \idx
.endm
.macro _memxb pfx, base, idx		; (base32 + index8)
	.byte \pfx, 0x03, \base, \idx
.endm
.macro mx_ld_mi8 pfx, base, idx, imm	; ld  (base+idx16),#imm8	op 0x00
	_memx \pfx, \base, \idx
	.byte 0x00, \imm
.endm
.macro mx_ld_rm pfx, base, idx, r	; ld  R,(base+idx16)		op 0x20+r
	_memx \pfx, \base, \idx
	.byte 0x20 + (\r)
.endm
.macro mx_lda32 pfx, base, idx, r	; lda R32,(base+idx16)		op 0x30+r
	_memx \pfx, \base, \idx
	.byte 0x30 + (\r)
.endm
.macro mx_jp_cc pfx, base, idx, cc	; jp  cc,(base+idx16)		op 0xD0+cc
	_memx \pfx, \base, \idx
	.byte 0xD0 + ((\cc) & 15)
.endm
.macro mx8_ld_rm pfx, base, idx, r	; ld  R,(base+idx8)		op 0x20+r
	_memxb \pfx, \base, \idx
	.byte 0x20 + (\r)
.endm
.macro mx8_st_mr8 pfx, base, idx, r	; ld  (base+idx8),R8		op 0x40+r
	_memxb \pfx, \base, \idx
	.byte 0x40 + (\r)
.endm
.macro mx8_st_mr16 pfx, base, idx, r	; ld  (base+idx8),R16		op 0x50+r
	_memxb \pfx, \base, \idx
	.byte 0x50 + (\r)
.endm
.macro mx8_st_mr32 pfx, base, idx, r	; ld  (base+idx8),R32		op 0x60+r
	_memxb \pfx, \base, \idx
	.byte 0x60 + (\r)
.endm
.macro mx_and_rm pfx, base, idx, r	; and R,(base+idx16)		op 0xC0+r
	_memx \pfx, \base, \idx
	.byte 0xC0 + (\r)
.endm
.macro mx_or_rm pfx, base, idx, r	; or  R,(base+idx16)		op 0xE0+r
	_memx \pfx, \base, \idx
	.byte 0xE0 + (\r)
.endm
.macro mx_or_mr pfx, base, idx, r	; or  (base+idx16),R		op 0xE8+r
	_memx \pfx, \base, \idx
	.byte 0xE8 + (\r)
.endm
.macro mx_st_mr8 pfx, base, idx, r	; ld  (base+idx16),R8		op 0x40+r
	_memx \pfx, \base, \idx
	.byte 0x40 + (\r)
.endm
.macro mx_st_mr16 pfx, base, idx, r	; ld  (base+idx16),R16		op 0x50+r
	_memx \pfx, \base, \idx
	.byte 0x50 + (\r)
.endm
.macro mx_st_mr32 pfx, base, idx, r	; ld  (base+idx16),R32		op 0x60+r
	_memx \pfx, \base, \idx
	.byte 0x60 + (\r)
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
.macro m_popw pfx, addr			; popw (addr)			op 0x06
	_mem \pfx, \addr
	.byte 0x06
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
; "unknown", and it stays a number here too.
;
; ⚠ CORRECTED 2026-08-25 (round-2 audit, F7).  This paragraph used to say "MAME
; does not name the TLCS-900 control registers", and the next paragraph then said
; "these four groups are the only ones MAME decodes for this part" -- the file
; contradicting itself twelve lines apart.  What is actually true:
;   * unidasm builds the BARE `tlcs900_disassembler` (unidasm.cpp:649,
;     `new tlcs900_disassembler`), the constructor with NO symbol tables
;     (dasm900.h:23), so it prints "unknown" for every control register.  That is
;     a property of unidasm's arch table, not of MAME's knowledge;
;   * MAME's TMP95C061 DEVICE does supply a table: `tmp95c061_cr_syms[]`,
;     tmp95c061.cpp:1394-1399, SIXTEEN entries -- DMAM0-3 (8-bit), DMAC0-3
;     (16-bit), DMAS0-3 and DMAD0-3 (32-bit).  Sixteen registers in four groups;
;   * 0x3C, the kernel's depth counter at 0xF856EC, is in NEITHER: not in the
;     disassembler table, and its `case` is absent from 900tbl.hxx's p_CR8/CR16/
;     CR32 switches, so it falls to `default: ... m_dummy` (900tbl.hxx:3992-3993
;     and :4170-4171).  MAME neither names nor decodes it.
; So: sixteen named, one used here that is not among them, and no databook in
; these trees to name it from.
.equ RB, 0xC8		; + index -> W  A  B  C  D  E  H  L
.equ RW, 0xD8		; + index -> WA BC DE HL IX IY IZ SP
.equ RL, 0xE8		; + index -> XWA XBC XDE XHL XIX XIY XIZ XSP
.macro m_ldc_cr_reg rp, cr		; ldc <cr>,R			op 0x2E
	.byte \rp, 0x2E, \cr
.endm
.macro m_ldc_reg_cr rp, cr		; ldc R,<cr>			op 0x2F
	.byte \rp, 0x2F, \cr
.endm

; Control-register NUMBERS.  These four groups -- SIXTEEN registers, listed one
; per line below -- are the only ones MAME decodes for this part: 900tbl.hxx:
; 3931-4030, where the `// TMP96C141/TMP95C061/TMP95C063` cases map them onto
; m_dmas/m_dmad/m_dmac/m_dmam, and tmp95c061.cpp:1394-1399, where the same
; sixteen are the disassembler's symbol table.  Anything outside them (0x3C, used
; as the kernel's depth counter at 0xF856EC) lands on MAME's m_dummy, so MAME
; neither names nor decodes it, and neither does this file.
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
; ADDED 2026-08-30 -- the forms prom_b needed and prom_a had never met
; ==============================================================================
;
; prom_a grew this macro set one instruction at a time, as its own conversion
; found each form, so the set covers what prom_a contains and nothing else.
; prom_b holds 7,309 rows that llvm-mc has no spelling for, and 1,580 of them
; were operations prom_a simply never uses.  The macros below close that gap.
;
; ⚠ SAME RULE AS ABOVE: these emit BYTES, and the byte gate is what proves the
;   encoding.  The NAME on each comes from MAME's dasm900.cpp tables, and every
;   use in prom_b carries unidasm's own text in its trailing comment -- so for
;   each of these macros there are hundreds of lines where the two can be
;   compared by eye, and notes/promb_macro_rewrite.py compares them by machine
;   before it emits anything.
;
; The operation-byte numbers are the same four tables the block above cites:
; mnemonic_c0/d0/e0 for a size-carrying operand, mnemonic_f0/b0/b8 for a
; "destination" one, and mnemonic_c8/d8/e8 for a register-direct one.

; --- mnemonic_c0/d0/e0: operations prom_a has no instance of ------------------
.macro m_sub_mi8 pfx, addr, imm		; sub (addr),#imm8		op 0x3A
	_mem \pfx, \addr
	.byte 0x3A, \imm
.endm
.macro m_sub_mi16 pfx, addr, imm	; sub (addr),#imm16		op 0x3A
	_mem \pfx, \addr
	.byte 0x3A, (\imm) & 0xFF, ((\imm) >> 8) & 0xFF
.endm
.macro m_and_mi16 pfx, addr, imm	; and (addr),#imm16		op 0x3C
	_mem \pfx, \addr
	.byte 0x3C, (\imm) & 0xFF, ((\imm) >> 8) & 0xFF
.endm
.macro m_xor_mi16 pfx, addr, imm	; xor (addr),#imm16		op 0x3D
	_mem \pfx, \addr
	.byte 0x3D, (\imm) & 0xFF, ((\imm) >> 8) & 0xFF
.endm
.macro m_or_mi16 pfx, addr, imm		; or  (addr),#imm16		op 0x3E
	_mem \pfx, \addr
	.byte 0x3E, (\imm) & 0xFF, ((\imm) >> 8) & 0xFF
.endm
.macro m_and_mr pfx, addr, r		; and (addr),R			op 0xC8+r
	_mem \pfx, \addr
	.byte 0xC8 + (\r)
.endm
.macro m_xor_mr pfx, addr, r		; xor (addr),R			op 0xD8+r
	_mem \pfx, \addr
	.byte 0xD8 + (\r)
.endm
.macro m_or_mr pfx, addr, r		; or  (addr),R			op 0xE8+r
	_mem \pfx, \addr
	.byte 0xE8 + (\r)
.endm

; ⚠ THE OTHER MEMORY-TO-MEMORY MOVE.  m_ld_mm16 above is the "destination"
; table's 0x14: the PREFIX names the destination and the trailing 16-bit address
; the source.  0x19 in the size tables is the mirror image -- the prefix names
; the SOURCE and the trailing address the destination -- and unidasm prints it
; with the operands in that order, `ld (0x2540),(0x28c8)` for C1 C8 28 19 40 25.
; Two ops that both spell `ld (mem),(mem)` and disagree about which is which is
; exactly the kind of thing a byte-emitter macro must not guess at, so they have
; separate names.
.macro m_ld_m16m pfx, addr, dst		; ld  (dst16),(addr)		op 0x19
	_mem \pfx, \addr
	.byte 0x19, (\dst) & 0xFF, ((\dst) >> 8) & 0xFF
.endm
; ⚠ THERE IS NO SEPARATE `ldw` FORM HERE.  0x19 is `ld` under a byte-size prefix
; and `ldw` under a word-size one -- mnemonic_c0[0x19] against mnemonic_d0[0x19]
; -- so m_ld_m16m spells both.  A m_ldw_m16m on op 0x1B was drafted and removed:
; 0x1B is M_DB, an undefined byte, in every one of these tables.

; --- the CARRY-FLAG group, ops 0x28-0x2C ------------------------------------
; `andcf A,(addr)` and its four siblings take the bit number from A rather than
; from the operation byte, which is why they have no bit-number argument.
;
; ⚠ CORRECTED before any of them shipped.  This block first read
;   0x28 ldcf / 0x29 andcf / 0x2B orcf, which is WRONG.  mnemonic_f0 and
;   mnemonic_c8/d8/e8 (dasm900.cpp) both read
;       0x28 ANDCF   0x29 ORCF   0x2A XORCF   0x2B LDCF   0x2C STCF
;   -- so three of the five names were transposed.  Nothing was emitted under a
;   wrong name, because notes/promb_macro_rewrite.py refuses a row whose
;   mnemonic disagrees with the macro it picked, and it duly refused the two
;   `ldcf A,RH3` rows at 0xF6880E and 0xF68825 rather than calling them `orcf`.
;   That refusal is what sent this pass to MAME's tables.
;
; ⚠ These five exist ONLY in the destination and register-direct tables.
;   mnemonic_c0/d0/e0 hold M_DB at 0x28-0x2C -- an undefined byte -- so an
;   `MB*`/`MW*`/`ML*` prefix must never be used with them.
.macro m_andcf_a pfx, addr		; andcf A,(addr)		op 0x28
	_mem \pfx, \addr
	.byte 0x28
.endm
.macro m_orcf_a pfx, addr		; orcf  A,(addr)		op 0x29
	_mem \pfx, \addr
	.byte 0x29
.endm
.macro m_xorcf_a pfx, addr		; xorcf A,(addr)		op 0x2A
	_mem \pfx, \addr
	.byte 0x2A
.endm
.macro m_ldcf_a pfx, addr		; ldcf  A,(addr)		op 0x2B
	_mem \pfx, \addr
	.byte 0x2B
.endm
.macro m_stcf_a pfx, addr		; stcf  A,(addr)		op 0x2C
	_mem \pfx, \addr
	.byte 0x2C
.endm

; --- the eight SHIFT-A-MEMORY-OPERAND forms, ops 0x78-0x7F -------------------
; ⚠ THE ORDER MATTERS AND IT IS NOT ALPHABETICAL: rlc rrc rl rr sla sra sll srl.
;   This block was first written with sla and sll transposed; prom_b's own
;   disassembly text is what caught it, because notes/promb_macro_rewrite.py
;   refuses a row whose mnemonic disagrees with the macro it picked, and seven
;   rows said `sllw` where the table said `slaw`.
.macro m_rlc_m pfx, addr		; rlc (addr)			op 0x78
	_mem \pfx, \addr
	.byte 0x78
.endm
.macro m_rrc_m pfx, addr		; rrc (addr)			op 0x79
	_mem \pfx, \addr
	.byte 0x79
.endm
.macro m_rl_m pfx, addr			; rl  (addr)			op 0x7A
	_mem \pfx, \addr
	.byte 0x7A
.endm
.macro m_rr_m pfx, addr			; rr  (addr)			op 0x7B
	_mem \pfx, \addr
	.byte 0x7B
.endm
.macro m_sla_m pfx, addr		; sla (addr)			op 0x7C
	_mem \pfx, \addr
	.byte 0x7C
.endm
.macro m_sra_m pfx, addr		; sra (addr)			op 0x7D
	_mem \pfx, \addr
	.byte 0x7D
.endm
.macro m_sll_m pfx, addr		; sll (addr)			op 0x7E
	_mem \pfx, \addr
	.byte 0x7E
.endm
.macro m_srl_m pfx, addr		; srl (addr)			op 0x7F
	_mem \pfx, \addr
	.byte 0x7F
.endm

; --- the two BLOCK TRANSFERS, whose operand is a register the text hides ------
; ⚠ unidasm prints `ldir` with NO operand, but the instruction is two bytes and
;   the first is a memory-operand prefix that names the register pair the
;   transfer runs on: 85 11 is `ldir` at (XIY), 83 11 is `ldir` at (XHL).  This
;   image holds both.  llvm-mc's own `ldir` mnemonic exists but always emits
;   80 11 -- the (XWA) form -- so it cannot spell either of them, and a lane
;   that reached for the native spelling would have changed the bytes.
;   `ldirw` is the one case where llvm-mc's spelling happens to match (95 11),
;   and it is still written as a macro here so the two lines look alike.
.macro m_ldir pfx			; ldir  (prefix names the register)  op 0x11
	.byte \pfx, 0x11
.endm
.macro m_ldirw pfx			; ldirw (prefix names the register)  op 0x11
	.byte \pfx, 0x11
.endm

; --- mnemonic_f0: the conditional jump and call through a memory operand ------
; ⚠ unidasm prints the operand WITHOUT parentheses -- `jp C,0xf7c6e5` for
;   F2 E5 C6 F7 D7 -- because for these two operations the "operand address" IS
;   the branch target rather than a location to read.
.macro m_jp_cc pfx, addr, cc		; jp   cc,addr			op 0xD0+cc
	_mem \pfx, \addr
	.byte 0xD0 + ((\cc) & 15)
.endm
.macro m_call_cc pfx, addr, cc		; call cc,addr			op 0xE0+cc
	_mem \pfx, \addr
	.byte 0xE0 + ((\cc) & 15)
.endm

; --- more of the REGISTER-INDEXED (rr+r) operand ------------------------------
.macro mx_ld_mi16 pfx, base, idx, imm	; ldw (base+idx16),#imm16	op 0x02
	_memx \pfx, \base, \idx
	.byte 0x02, (\imm) & 0xFF, ((\imm) >> 8) & 0xFF
.endm
.macro mx_lda16 pfx, base, idx, r	; lda R16,(base+idx16)		op 0x20+r
	_memx \pfx, \base, \idx
	.byte 0x20 + (\r)
.endm
.macro mx_ld_mm16 pfx, base, idx, src	; ld  (base+idx16),(src16)	op 0x14
	_memx \pfx, \base, \idx
	.byte 0x14, (\src) & 0xFF, ((\src) >> 8) & 0xFF
.endm
.macro mx_cp_mi8 pfx, base, idx, imm	; cp  (base+idx16),#imm8	op 0x3F
	_memx \pfx, \base, \idx
	.byte 0x3F, \imm
.endm
.macro mx_and_mi8 pfx, base, idx, imm	; and (base+idx16),#imm8	op 0x3C
	_memx \pfx, \base, \idx
	.byte 0x3C, \imm
.endm
.macro mx_or_mi8 pfx, base, idx, imm	; or  (base+idx16),#imm8	op 0x3E
	_memx \pfx, \base, \idx
	.byte 0x3E, \imm
.endm
.macro mx_add_rm pfx, base, idx, r	; add R,(base+idx16)		op 0x80+r
	_memx \pfx, \base, \idx
	.byte 0x80 + (\r)
.endm
.macro mx_sub_rm pfx, base, idx, r	; sub R,(base+idx16)		op 0xA0+r
	_memx \pfx, \base, \idx
	.byte 0xA0 + (\r)
.endm
.macro mx_cp_rm pfx, base, idx, r	; cp  R,(base+idx16)		op 0xF0+r
	_memx \pfx, \base, \idx
	.byte 0xF0 + (\r)
.endm
.macro mx_cp_mr pfx, base, idx, r	; cp  (base+idx16),R		op 0xF8+r
	_memx \pfx, \base, \idx
	.byte 0xF8 + (\r)
.endm
.macro mx_res n, pfx, base, idx		; res n,(base+idx16)		op 0xB0+n
	_memx \pfx, \base, \idx
	.byte 0xB0 + ((\n) & 7)
.endm
.macro mx_set n, pfx, base, idx		; set n,(base+idx16)		op 0xB8+n
	_memx \pfx, \base, \idx
	.byte 0xB8 + ((\n) & 7)
.endm
.macro mx_bit n, pfx, base, idx		; bit n,(base+idx16)		op 0xC8+n
	_memx \pfx, \base, \idx
	.byte 0xC8 + ((\n) & 7)
.endm
.macro mx8_lda32 pfx, base, idx, r	; lda R32,(base+idx8)		op 0x30+r
	_memxb \pfx, \base, \idx
	.byte 0x30 + (\r)
.endm

; ==============================================================================
; THE REGISTER-DIRECT OPERAND -- mnemonic_c8/d8/e8 (dasm900.cpp:779 and on)
; ==============================================================================
;
; Not every unspellable row is a memory operand.  585 of prom_b's are a
; REGISTER-DIRECT one, which comes in two shapes:
;
;   RB/RW/RL + index      one prefix byte naming a register of the CURRENT bank
;                         -- 0xDE is IZ at word size, so DE 2A is `xorcf A,IZ`
;   RBX/RWX/RLX + byte    prefix 0xC7/0xD7/0xE7 followed by a REGISTER-ADDRESS
;                         byte, which can name any register in any bank --
;                         C7 3C 89 is `ld A,RL3`, E7 38 04 is `push XDE3`
;
; ⚠ THE REGISTER-ADDRESS BYTE IS LEFT AS A NUMBER.  MAME's s_allreg8/16/32 name
;   all 256 of those slots and this tree has no copy of the table; the eight
;   ra_*/rb_* names above are the current-bank rows only.  So `m_rd_ld_rrx RBX,
;   0x3C, r1` says what the bytes are and the trailing comment says the register
;   is RL3.  Naming it here would be a guess; the comment is unidasm's.
.equ RBX, 0xC7		; byte-size operand, register named by the next byte
.equ RWX, 0xD7		; word-size operand, ditto
.equ RLX, 0xE7		; long-size operand, ditto

.macro m_rd_push rp			; push r			op 0x04
	.byte \rp, 0x04
.endm
.macro m_rd_pop rp			; pop  r			op 0x05
	.byte \rp, 0x05
.endm
.macro m_rd_andcf_a rp			; andcf A,r			op 0x28
	.byte \rp, 0x28
.endm
.macro m_rd_orcf_a rp			; orcf  A,r			op 0x29
	.byte \rp, 0x29
.endm
.macro m_rd_xorcf_a rp			; xorcf A,r			op 0x2A
	.byte \rp, 0x2A
.endm
.macro m_rd_ldcf_a rp			; ldcf  A,r			op 0x2B
	.byte \rp, 0x2B
.endm
.macro m_rd_stcf_a rp			; stcf  A,r			op 0x2C
	.byte \rp, 0x2C
.endm
.macro m_rd_add_rr rp, r		; add R,r			op 0x80+r
	.byte \rp, 0x80 + (\r)
.endm
.macro m_rd_ld_rr rp, r			; ld  R,r			op 0x88+r
	.byte \rp, 0x88 + (\r)
.endm
.macro m_rd_ld_rr2 rp, r		; ld  r,R			op 0x98+r
	.byte \rp, 0x98 + (\r)
.endm

.macro m_rd_pushx rp, reg		; push <reg>			op 0x04
	.byte \rp, \reg, 0x04
.endm
.macro m_rd_popx rp, reg		; pop  <reg>			op 0x05
	.byte \rp, \reg, 0x05
.endm
.macro m_rd_andcf_ax rp, reg		; andcf A,<reg>			op 0x28
	.byte \rp, \reg, 0x28
.endm
.macro m_rd_orcf_ax rp, reg		; orcf  A,<reg>			op 0x29
	.byte \rp, \reg, 0x29
.endm
.macro m_rd_xorcf_ax rp, reg		; xorcf A,<reg>			op 0x2A
	.byte \rp, \reg, 0x2A
.endm
.macro m_rd_ldcf_ax rp, reg		; ldcf  A,<reg>			op 0x2B
	.byte \rp, \reg, 0x2B
.endm
.macro m_rd_stcf_ax rp, reg		; stcf  A,<reg>			op 0x2C
	.byte \rp, \reg, 0x2C
.endm
.macro m_rd_add_rrx rp, reg, r		; add R,<reg>			op 0x80+r
	.byte \rp, \reg, 0x80 + (\r)
.endm
.macro m_rd_ld_rrx rp, reg, r		; ld  R,<reg>			op 0x88+r
	.byte \rp, \reg, 0x88 + (\r)
.endm
.macro m_rd_ld_rr2x rp, reg, r		; ld  <reg>,R			op 0x98+r
	.byte \rp, \reg, 0x98 + (\r)
.endm
