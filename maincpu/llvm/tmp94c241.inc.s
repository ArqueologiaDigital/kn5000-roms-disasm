; The macros in this file describe the encoding of
; TOSHIBA TLCS900 TMP94C241 instructions
; that are not supported by Alfred Arnold's
; Macro assembler 1.42 Beta [Bld 298]


.macro LDC_DMAD0_XWA
	.byte 0xe8, 0x2e, 0x20	; LDC DMAD0, XWA
.endm


.macro LDC_DMAD0_XBC
	.byte 0xe9, 0x2e, 0x20	; LDC DMAD0, XBC
.endm


.macro LDC_DMAD2_XWA
	.byte 0xe8, 0x2e, 0x28	; LDC DMAD2, XWA
.endm


; DMA Count registers (DMAC) - 16-bit, CR offsets 0x40/0x44/0x48/0x4C
.macro LDC_DMAC0_WA
	.byte 0xd8, 0x2e, 0x40	; LDC DMAC0, WA (DMA channel 0 count)
.endm


.macro LDC_WA_DMAC0
	.byte 0xd8, 0x2f, 0x40	; LDC WA, DMAC0 (read DMA channel 0 count)
.endm


.macro LDC_DMAC2_BC
	.byte 0xd9, 0x2e, 0x48	; LDC DMAC2, BC (DMA channel 2 count)
.endm


.macro LDC_DMAC2_WA
	.byte 0xd8, 0x2e, 0x48	; LDC DMAC2, WA (DMA channel 2 count)
.endm


.macro LDC_DMAC3_BC
	.byte 0xd9, 0x2e, 0x4c	; LDC DMAC3, BC (DMA channel 3 count)
.endm


; DMA Mode registers (DMAM) - 8-bit, CR offsets 0x42/0x46/0x4A/0x4E
.macro LDC_DMAM0_A
	.byte 0xc9, 0x2e, 0x42	; LDC DMAM0, A (DMA channel 0 mode)
.endm


.macro LDC_DMAM2_A
	.byte 0xc9, 0x2e, 0x4a	; LDC DMAM2, A (DMA channel 2 mode)
.endm


.macro LDC_DMAM3_A
	.byte 0xc9, 0x2e, 0x4e	; LDC DMAM3, A (DMA channel 3 mode)
.endm


.macro LDC_DMAD3_XHL
	.byte 0xeb, 0x2e, 0x2c	; LDC DMAD3, XHL
.endm


.macro LDC_DMAS0_XWA
	.byte 0xe8, 0x2e, 0x0	; LDC DMAS0, XWA
.endm


.macro LDC_DMAS2_XWA
	.byte 0xe8, 0x2e, 0x8	; LDC DMAS2, XWA
.endm


.macro LDC_DMAS3_XHL
	.byte 0xeb, 0x2e, 0xc	; LDC DMAS3, XHL
.endm


.macro LDC_DMAS2_XBC
	.byte 0xe9, 0x2e, 0x8	; LDC DMAS2, XBC
.endm


.macro LDC_DMAS2_XDE
	.byte 0xea, 0x2e, 0x8	; LDC DMAS2, XDE
.endm


.macro LDC_DMAS2_XHL
	.byte 0xeb, 0x2e, 0x8	; LDC DMAS2, XHL
.endm


.macro LDC_INTNEST_WA
	.byte 0xd8, 0x2e, 0x7c	; LDC INTNEST, WA
.endm


.macro LD_W value
	.byte 0x20, \value	; LD W, byte
.endm


.macro LD_A value
	.byte 0x21, \value	; LD A, byte
.endm


.macro LD_B value
	.byte 0x22, \value	; LD B, byte
.endm


.macro LD_C value
	.byte 0x23, \value	; LD C, byte
.endm


.macro LD_D value
	.byte 0x24, \value	; LD D, byte
.endm


.macro LD_E value
	.byte 0x25, \value	; LD E, byte
.endm


.macro LD_H value
	.byte 0x26, \value	; LD H, byte
.endm


.macro LD_L value
	.byte 0x27, \value	; LD L, byte
.endm


.macro LDW_16_16 dst, src
	.byte 0xd1, \src & 0xff, (\src >> 8) & 0xff, 0x19, \dst & 0xff, (\dst >> 8) & 0xff	; LDW (word_dst), (word_src)
.endm


.macro LD_8_8 dst, src
	.byte 0xc1, \src & 0xff, (\src >> 8) & 0xff, 0x19, \dst & 0xff, (\dst >> 8) & 0xff	; LD (byte_dst), (byte_src)
.endm


.macro LDA_XBC_XWA_plus
	.byte 0xf5, 0xe2, 0x31	; LDA XBC, XWA+
.endm


.macro LDA_XBC_XWA_plus__e1__
	.byte 0xf5, 0xe1, 0x31	; LDA XBC, XWA+
.endm


.macro LDA_XBC_XWA_plus__e0__
	.byte 0xf5, 0xe0, 0x31	; LDA XBC, XWA+ (E0 variant)
.endm


.macro LDA_XDE_XWA_plus__e0__
	.byte 0xf5, 0xe0, 0x32	; LDA XDE, XWA+ (E0 variant)
.endm


.macro LDA_XHL_XWA_plus__e0__
	.byte 0xf5, 0xe0, 0x33	; LDA XHL, XWA+ (E0 variant)
.endm


.macro LDA_XWA_XWA_plus__e0__
	.byte 0xf5, 0xe0, 0x30	; LDA XWA, XWA+ (E0 variant)
.endm


.macro LDA_XIX_XWA_plus__e0__
	.byte 0xf5, 0xe0, 0x34	; LDA XIX, XWA+ (E0 variant)
.endm


.macro LDA_XIX_XIZ_plus__f9__
	.byte 0xf5, 0xf9, 0x34	; LDA XIX, XIZ+ (F9 variant)
.endm


.macro LDA_XIX_XIZ_plus__f8__
	.byte 0xf5, 0xf8, 0x34	; LDA XIX, XIZ+ (F8 variant)
.endm


.macro LDA_XDE_XBC_plus
	.byte 0xf5, 0xe5, 0x32	; LDA XDE, XBC+
.endm


.macro LDA_XHL_XBC_plus__e4__
	.byte 0xf5, 0xe4, 0x33	; LDA XHL, XBC+ (E4 variant)
.endm


.macro LDA_XIY_XDE_plus__e8__
	.byte 0xf5, 0xe8, 0x35	; LDA XIY, XDE+ (E8 variant)
.endm


.macro LDA_XBC_XHL__ec__
	.byte 0xf5, 0xec, 0x31	; LDA XBC, (XHL) (EC variant, no auto-increment)
.endm


.macro LD_XWA_XDE_plus
	.byte 0xf5, 0xe8, 0x30	; LDA XWA, XDE+
.endm



; Note: It is unclear to me why do we have 2 different encodings for some of
;       these LDI instructions and its variants.
;       Maybe these are actually different instructions?
;	I should take a look at the CPU datasheet to clarify this.
;
.macro LDIRW_95
	.byte 0x95, 0x11	; LDIRW
.endm


.macro LDIRW_93
	.byte 0x93, 0x11	; LDIRW
.endm



.macro LDI
	.byte 0x85, 0x10	; LDI
.endm


.macro LDIW
	.byte 0x95, 0x10	; LDIW
.endm


.macro LDIR_83
	.byte 0x83, 0x11	; LDIR
.endm


.macro LDIR
	.byte 0x85, 0x11	; LDIR
.endm


.macro LDDR_85
	.byte 0x85, 0x13	; LDDR (85 variant)
.endm


.macro MUL_A value
	.byte 0xc9, 0x8, \value	; MUL A, byte
.endm


.macro MUL_C value
	.byte 0xcb, 0x8, \value	; MUL C, byte
.endm


.macro MUL_E value
	.byte 0xcd, 0x8, \value	; MUL E, byte
.endm


.macro MUL_L value
	.byte 0xcf, 0x8, \value	; MUL L, byte
.endm


.macro MUL_WA value
	.byte 0xd8, 0x8, \value & 0xff, (\value >> 8) & 0xff	; MUL WA, word
.endm


.macro MUL_BC value
	.byte 0xd9, 0x8, \value & 0xff, (\value >> 8) & 0xff	; MUL BC, word
.endm


.macro MUL_DE value
	.byte 0xda, 0x8, \value & 0xff, (\value >> 8) & 0xff	; MUL DE, word
.endm


.macro MUL_HL value
	.byte 0xdb, 0x8, \value & 0xff, (\value >> 8) & 0xff	; MUL HL, word
.endm


.macro MUL_IX value
	.byte 0xdc, 0x8, \value & 0xff, (\value >> 8) & 0xff	; MUL IX, word
.endm


.macro MUL_IY value
	.byte 0xdd, 0x8, \value & 0xff, (\value >> 8) & 0xff	; MUL IY, word
.endm


.macro MUL_IZ value
	.byte 0xde, 0x8, \value & 0xff, (\value >> 8) & 0xff	; MUL IZ, word
.endm


.macro MULW_WA value
	.byte 0xd8, 0x8, \value & 0xff, (\value >> 8) & 0xff	; MULW WA, word
.endm


.macro MULS_A value
	.byte 0xc9, 0x9, \value	; MULS A, word
.endm


.macro MULS_C value
	.byte 0xcb, 0x9, \value	; MULS C, word
.endm


.macro MULS_L value
	.byte 0xcf, 0x9, \value	; MULS L, word
.endm


.macro MULS_WA value
	.byte 0xd8, 0x9, \value & 0xff, (\value >> 8) & 0xff	; MULS WA, word
.endm


.macro MULS_BC value
	.byte 0xd9, 0x9, \value & 0xff, (\value >> 8) & 0xff	; MULS BC, word
.endm


.macro MULS_DE value
	.byte 0xda, 0x9, \value & 0xff, (\value >> 8) & 0xff	; MULS DE, word
.endm


.macro MULS_HL value
	.byte 0xdb, 0x9, \value & 0xff, (\value >> 8) & 0xff	; MULS HL, word
.endm


.macro MULS_IX value
	.byte 0xdc, 0x9, \value & 0xff, (\value >> 8) & 0xff	; MULS IX, word
.endm


.macro MULS_IY value
	.byte 0xdd, 0x9, \value & 0xff, (\value >> 8) & 0xff	; MULS IY, word
.endm


.macro MULS_IZ value
	.byte 0xde, 0x9, \value & 0xff, (\value >> 8) & 0xff	; MULS IZ, word
.endm


; NOTE: I am not so sure about this one...
.macro MULS_IYL value
	.byte 0xc7, 0xf4, \value & 0xff, (\value >> 8) & 0xff	; MULS IYL, word
.endm


.macro MULS_XWA_IX
	.byte 0xdc, 0x48	; MULS XWA, IX
.endm


.macro MULS_XWA_DE
	.byte 0xda, 0x48	; MULS XWA, DE
.endm


.macro MULS_XDE_IY
	.byte 0xdd, 0x4a	; MULS XDE IY
.endm


.macro DIV_A value
	.byte 0xc9, 0xa, \value	; DIV A, byte
.endm


.macro DIV_C value
	.byte 0xcb, 0xa, \value	; DIV C, byte
.endm


.macro DIV_E value
	.byte 0xcd, 0xa, \value	; DIV E, byte
.endm


.macro DIV_L value
	.byte 0xcf, 0xa, \value	; DIV L, byte
.endm


.macro DIVW_WA value
	.byte 0xd8, 0xa, \value & 0xff, (\value >> 8) & 0xff	; DIVW WA, word
.endm


.macro DIVW_BC value
	.byte 0xd9, 0xa, \value & 0xff, (\value >> 8) & 0xff	; DIVW BC, word
.endm


.macro DIVW_DE value
	.byte 0xda, 0xa, \value & 0xff, (\value >> 8) & 0xff	; DIVW DE, word
.endm


.macro DIVW_HL value
	.byte 0xdb, 0xa, \value & 0xff, (\value >> 8) & 0xff	; DIVW HL, word
.endm


.macro DIVW_IX value
	.byte 0xdc, 0xa, \value & 0xff, (\value >> 8) & 0xff	; DIVW IX, word
.endm


.macro DIVW_IY value
	.byte 0xdd, 0xa, \value & 0xff, (\value >> 8) & 0xff	; DIVW IY, word
.endm


.macro DIVW_IZ value
	.byte 0xde, 0xa, \value & 0xff, (\value >> 8) & 0xff	; DIVW IZ, word
.endm


.macro DIVS_WA value
	.byte 0xd8, 0xb, \value & 0xff, (\value >> 8) & 0xff	; DIVS WA, word
.endm


.macro DIVS_BC value
	.byte 0xd9, 0xb, \value & 0xff, (\value >> 8) & 0xff	; DIVS BC, word
.endm


.macro DIVS_DE value
	.byte 0xda, 0xb, \value & 0xff, (\value >> 8) & 0xff	; DIVS DE, word
.endm


.macro DIVS_HL value
	.byte 0xdb, 0xb, \value & 0xff, (\value >> 8) & 0xff	; DIVS HL, word
.endm


.macro DIVS_IX value
	.byte 0xdc, 0xb, \value & 0xff, (\value >> 8) & 0xff	; DIVS IX, word
.endm


.macro DIVS_IY value
	.byte 0xdd, 0xb, \value & 0xff, (\value >> 8) & 0xff	; DIVS IY, word
.endm


.macro SRA_0_XWA
	.byte 0xe8, 0xed, 0x0	; SRA ?, XWA
.endm


.macro SRA_8_XWA
	.byte 0xe8, 0xed, 0x8	; SRA ?, XWA
.endm


.macro SLA_0_XBC
	.byte 0xe9, 0xec, 0x0	; SLA ?, XBC
.endm


.macro SLA_0_XHL
	.byte 0xeb, 0xec, 0x0	; SLA ?, XHL
.endm


.macro SLA_8_XDE
	.byte 0xea, 0xec, 0x8	; SLA ?, XDE
.endm


.macro SRL_0_XDE
	.byte 0xea, 0xef, 0x0	; SRL ?, XDE
.endm


.macro SLA_8_XWA
	.byte 0xe8, 0xec, 0x8	; SLA 8, XWA
.endm


.macro SLA_0_XIX
	.byte 0xec, 0xec, 0x0	; SLA ?, XIX
.endm


.macro SLL_0_XIX
	.byte 0xec, 0xee, 0x0	; SLL ?, XIX
.endm


.macro SRL_0_XHL
	.byte 0xeb, 0xef, 0x0	; SRL ?, XHL
.endm


.macro SRL_0_XWA
	.byte 0xe8, 0xef, 0x0	; SRL 0, XWA
.endm


.macro SRL_0_XBC
	.byte 0xe9, 0xef, 0x0	; SRL 0, XBC
.endm


.macro SLL_0_XWA
	.byte 0xe8, 0xee, 0x0	; SLL 0, XWA
.endm


.macro SLL_0_XBC
	.byte 0xe9, 0xee, 0x0	; SLL 0, XBC
.endm


.macro SLL_0_XDE
	.byte 0xea, 0xee, 0x0	; SLL 0, XDE
.endm


.macro SLL_0_XHL
	.byte 0xeb, 0xee, 0x0	; SLL 0, XHL
.endm


.macro SLL_8_XIX
	.byte 0xec, 0xee, 0x8	; SLL 8, XIX
.endm


.macro SLA_0_XWA
	.byte 0xe8, 0xec, 0x0	; SLA 0, XWA
.endm


.macro SRA_0_XBC
	.byte 0xe9, 0xed, 0x0	; SRA 0, XBC
.endm


.macro SRA_0_XDE
	.byte 0xea, 0xed, 0x0	; SRA 0, XDE
.endm


; ==============================================================================
; Additional macros for Sub CPU boot ROM assembly
; ==============================================================================

; INC 0, XBC - Increment XBC by 1 (0+1=1)
; Encoding: e9 60
.macro INC_0_XBC
	.byte 0xe9, 0x60	; INC 0, XBC
.endm


; PUSH word immediate
; Encoding: 0b LL HH (little-endian)
.macro PUSH_WORD value
	.byte 0xb, \value & 0xFF, (\value >> 8) & 0xFF	; PUSH word
.endm


; CP (XWA), word - Compare memory at XWA with 16-bit immediate
; Encoding: 90 3f LL HH
.macro CP_pXWA_WORD value
	.byte 0x90, 0x3f, \value & 0xFF, (\value >> 8) & 0xFF	; CP (XWA), word
.endm


; CP (XBC+d), word - Compare memory at XBC+d with 16-bit immediate
; Encoding: 99 dd 3f LL HH
.macro CP_pXBC_d_WORD disp, value
	.byte 0x99, \disp, 0x3f, \value & 0xFF, (\value >> 8) & 0xFF	; CP (XBC+d), word
.endm


; LDA XWA, 24-bit address - Load effective address into XWA
; Encoding: f2 LL MM HH (where address is 0xHHMMLLL)
.macro LDA_XWA_IMM24 value
	.byte 0xf2, \value & 0xFF, (\value >> 8) & 0xFF, (\value >> 16) & 0xFF, 0x30
.endm


; LD_MEM24_IMM16 - Store 16-bit immediate to 24-bit memory address
; Encoding: f2 LL MM HH 02 VV WW (7 bytes)
; where address is 0xHHMMLLL and value is 0xWWVV
; Use when ASL generates 6-byte encoding instead of 7-byte
.macro LD_MEM24_IMM16 addr, value
	.byte 0xf2
	.byte \addr & 0xFF, (\addr >> 8) & 0xFF, (\addr >> 16) & 0xFF
	.byte 0x2	; Size specifier for word (16-bit)
	.byte \value & 0xFF, (\value >> 8) & 0xFF
.endm


; LD_pXIX_IMM16 - Store 16-bit immediate to memory via XIX
; Encoding: b4 02 LL HH (4 bytes)
; Use when ASL generates 3-byte encoding instead of 4-byte
.macro LD_pXIX_IMM16 value
	.byte 0xb4, 0x2
	.byte \value & 0xFF, (\value >> 8) & 0xFF
.endm


; LD_pXHL_IMM16 - Store 16-bit immediate to memory via XHL
; Encoding: b3 02 LL HH (4 bytes)
; Use when ASL generates 3-byte encoding instead of 4-byte
.macro LD_pXHL_IMM16 value
	.byte 0xb3, 0x2
	.byte \value & 0xFF, (\value >> 8) & 0xFF
.endm


; CALR addr - Call relative (shorter encoding than CALL)
; Encoding: 1e LL HH (16-bit signed relative offset)
; Note: offset is calculated from the byte after the instruction
.macro CALR target
	.byte 0x1e
	.short \target - . - 2	; Relative offset ($ is already at byte 1)
.endm


; CALL_ABS24 addr - Call absolute with 24-bit address (4-byte encoding)
; Encoding: 1d LL MM HH
; Use when ASL generates wrong encoding for call instruction
.macro CALL_ABS24 target
	.byte 0x1d, \target & 0xFF, (\target >> 8) & 0xFF, (\target >> 16) & 0xFF
.endm


; JRL_T addr - Jump relative long (always true condition)
; Encoding: 78 LL HH (3-byte instruction)
; Use when ASL generates jp instead of jrl
.macro JRL_T target
	.byte 0x78
	.short \target - . - 2	; Relative offset from after instruction
.endm


; LDIR_94 - Load, Increment, Repeat (TMP94C241 encoding)
; Encoding: 83 11 (ASL generates 85 11 which is TMP96C141 encoding)
; Copies bytes from (XHL) to (XDE), count in XBC
.macro LDIR_94
	.byte 0x83, 0x11
.endm


; ==============================================================================
; QIZH register access macros
; QIZH is the high byte of the QIZ register (32-bit index register)
; Register code 0xFB in the extended register encoding
; ==============================================================================

; LD_QIZH_IMM - Load immediate value into QIZH
; Encoding: c7 fb a8+value (for value 0-7) or c7 fb 20 value
.macro LD_QIZH_0
	.byte 0xc7, 0xfb, 0xa8	; ld QIZH, 0
.endm


; LD_A_QIZH - Load A from QIZH
; Encoding: c7 fb 89
.macro LD_A_QIZH
	.byte 0xc7, 0xfb, 0x89	; ld A, QIZH
.endm


; LD_C_QIZH - Load C from QIZH
; Encoding: c7 fb 8b
.macro LD_C_QIZH
	.byte 0xc7, 0xfb, 0x8b	; ld C, QIZH
.endm


; INC_1_QIZH - Increment QIZH by 1
; Encoding: c7 fb 61
.macro INC_1_QIZH
	.byte 0xc7, 0xfb, 0x61	; inc 1, QIZH
.endm


; CP_QIZH_IMM - Compare QIZH with immediate value
; Encoding: c7 fb d8+value (for value 0-7) or c7 fb cf value
.macro CP_QIZH_4
	.byte 0xc7, 0xfb, 0xdc	; cp QIZH, 4
.endm


; ==============================================================================
; Memory comparison macro
; ==============================================================================

; CP_MEM24_IMM16 - Compare 16-bit value at 24-bit address with immediate
; Encoding: d2 LL MM HH 3f VV WW (7 bytes)
.macro CP_MEM24_IMM16 addr, value
	.byte 0xd2
	.byte \addr & 0xFF, (\addr >> 8) & 0xFF, (\addr >> 16) & 0xFF
	.byte 0x3f
	.byte \value & 0xFF, (\value >> 8) & 0xFF
.endm


; ==============================================================================
; Shift macros
; ==============================================================================

; SLA_2_BC - Shift BC left arithmetic by 2 (multiply by 4)
; Encoding: d9 ec 02
.macro SLA_2_BC
	.byte 0xd9, 0xec, 0x2	; sla 2, BC
.endm


; ==============================================================================
; Load effective address macros
; ==============================================================================

; LDA_XDE_IMM24 - Load 24-bit effective address into XDE
; Encoding: f2 LL MM HH 32 (5 bytes)
.macro LDA_XDE_IMM24 addr
	.byte 0xf2
	.byte \addr & 0xFF, (\addr >> 8) & 0xFF, (\addr >> 16) & 0xFF
	.byte 0x32
.endm


; ==============================================================================
; Indexed load macros
; ==============================================================================

; LD_XBC_pXDE_BC - Load XBC from memory at (XDE+BC)
; Encoding: e3 07 e8 e4 21 (5 bytes)
.macro LD_XBC_pXDE_BC
	.byte 0xe3, 0x7, 0xe8, 0xe4, 0x21	; ld XBC, (XDE+BC)
.endm


; ==============================================================================
; Stack-relative load macros
; ==============================================================================

; LD_XBC_pXSP_d - Load XBC from (XSP+disp)
; Encoding: af dd 21 (3 bytes)
.macro LD_XBC_pXSP_d disp
	.byte 0xaf, \disp, 0x21	; ld XBC, (XSP+disp)
.endm


; LD_A_pXSP_d - Load A from (XSP+disp)
; Encoding: 8f dd 21 (3 bytes)
.macro LD_A_pXSP_d disp
	.byte 0x8f, \disp, 0x21	; ld A, (XSP+disp)
.endm


; LD_XDE_pXSP_d - Load XDE from (XSP+disp)
; Encoding: af dd 22 (3 bytes)
.macro LD_XDE_pXSP_d disp
	.byte 0xaf, \disp, 0x22	; ld XDE, (XSP+disp)
.endm


; LD_pXSP_d_XDE - Store XDE to (XSP+disp)
; Encoding: bf dd 62 (3 bytes)
.macro LD_pXSP_d_XDE disp
	.byte 0xbf, \disp, 0x62	; ld (XSP+disp), XDE
.endm


; LD_pXSP_d_A - Store A to (XSP+disp)
; Encoding: bf dd 41 (3 bytes)
.macro LD_pXSP_d_A disp
	.byte 0xbf, \disp, 0x41	; ld (XSP+disp), A
.endm


; ADD_pXSP_d_XWA - Add XWA to memory at (XSP+disp)
; Encoding: af dd 88 (3 bytes)
.macro ADD_pXSP_d_XWA disp
	.byte 0xaf, \disp, 0x88	; add (XSP+disp), XWA
.endm


; ==============================================================================
; Register-to-register load macros
; ==============================================================================

; LD_XDE_XIZ - Load XDE from XIZ
; Encoding: ee 8a (2 bytes)
.macro LD_XDE_XIZ
	.byte 0xee, 0x8a	; ld XDE, XIZ
.endm


; LD_BC_QBC - Load BC from QBC (high word of XBC)
; Encoding: d7 e6 89 (3 bytes)
.macro LD_BC_QBC
	.byte 0xd7, 0xe6, 0x89	; ld BC, QBC
.endm


; LD_BC_QDE - Load BC from QDE (high word of XDE)
; Encoding: d7 ea 89 (3 bytes)
.macro LD_BC_QDE
	.byte 0xd7, 0xea, 0x89	; ld BC, QDE
.endm


; ==============================================================================
; Stack pointer increment macro
; ==============================================================================

; INC_0_XSP - Increment XSP by 1 (0+1=1) - adjust stack
; Encoding: ef 60 (2 bytes)
.macro INC_0_XSP
	.byte 0xef, 0x60	; inc 0, XSP
.endm


; ==============================================================================
; Memory store with auto-increment
; ==============================================================================

; LD_pXWA_plus_BC - Store BC to memory at XWA, then increment XWA
; Encoding: f5 e1 51 (3 bytes)
.macro LD_pXWA_plus_BC
	.byte 0xf5, 0xe1, 0x51	; ld (XWA+), BC
.endm


; ==============================================================================
; Decrement and jump if not zero macros
; ==============================================================================

; DJNZ_DE - Decrement DE and jump if not zero (relative)
; Encoding: da 1c dd (3 bytes, signed 8-bit displacement)
.macro DJNZ_DE target
	.byte 0xda, 0x1c
	.byte (\target - . - 1) & 0xFF	; Signed 8-bit displacement
.endm


; ==============================================================================
; Memory arithmetic with auto-increment
; ==============================================================================

; ADD_XHL_pXWA_plus - Add (XWA+) to XHL, post-increment XWA
; Encoding: e5 e2 83 (3 bytes)
.macro ADD_XHL_pXWA_plus
	.byte 0xe5, 0xe2, 0x83	; add XHL, (XWA+)
.endm


; ==============================================================================
; Stack frame macros (for DMA Transfer Routines)
; ==============================================================================

; DEC_6_XSP - Decrement XSP by 6 (allocate 6 bytes on stack)
; Encoding: ef 6e (2 bytes)
.macro DEC_6_XSP
	.byte 0xef, 0x6e	; dec 6, XSP
.endm


; INC_6_XSP - Increment XSP by 6 (deallocate 6 bytes from stack)
; Encoding: ef 66 (2 bytes)
.macro INC_6_XSP
	.byte 0xef, 0x66	; inc 6, XSP
.endm


; ==============================================================================
; IZ register operations
; ==============================================================================

; LD_IZ_BC - Load IZ from BC (16-bit transfer)
; Encoding: d9 8e (2 bytes)
.macro LD_IZ_BC
	.byte 0xd9, 0x8e	; ld IZ, BC
.endm


; CP_IZ_imm16 - Compare IZ with 16-bit immediate
; Encoding: de cf low high (4 bytes)
.macro CP_IZ_imm16 value
	.byte 0xde, 0xcf
	.byte (\value) & 0xFF	; low byte
	.byte ((\value) >> 8) & 0xFF	; high byte
.endm


; SUB_IZ_imm16 - Subtract 16-bit immediate from IZ
; Encoding: de ca low high (4 bytes)
.macro SUB_IZ_imm16 value
	.byte 0xde, 0xca
	.byte (\value) & 0xFF	; low byte
	.byte ((\value) >> 8) & 0xFF	; high byte
.endm


; LD_C_IZL - Load C from IZL (low byte of IZ)
; Encoding: c7 f8 8b (3 bytes)
.macro LD_C_IZL
	.byte 0xc7, 0xf8, 0x8b	; ld C, IZL
.endm


; ==============================================================================
; Zero-extend operations
; ==============================================================================

; EXTZ_WA - Zero-extend A to WA (clear W, keep A)
; Encoding: d8 12 (2 bytes)
.macro EXTZ_WA
	.byte 0xd8, 0x12	; extz WA
.endm


; EXTZ_BC - Zero-extend C to BC (clear B, keep C)
; Encoding: d9 12 (2 bytes)
.macro EXTZ_BC
	.byte 0xd9, 0x12	; extz BC
.endm

