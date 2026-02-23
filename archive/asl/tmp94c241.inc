; The macros in this file describe the encoding of
; TOSHIBA TLCS900 TMP94C241 instructions
; that are not supported by Alfred Arnold's
; Macro assembler 1.42 Beta [Bld 298]


LDC_DMAD0_XWA MACRO
	db 0e8h, 2eh, 20h	; LDC DMAD0, XWA
	ENDM

LDC_DMAD0_XBC MACRO
	db 0e9h, 2eh, 20h	; LDC DMAD0, XBC
	ENDM

LDC_DMAD2_XWA MACRO
	db 0e8h, 2eh, 28h	; LDC DMAD2, XWA
	ENDM

; DMA Count registers (DMAC) - 16-bit, CR offsets 0x40/0x44/0x48/0x4C
LDC_DMAC0_WA MACRO
	db 0d8h, 2eh, 40h	; LDC DMAC0, WA (DMA channel 0 count)
	ENDM

LDC_WA_DMAC0 MACRO
	db 0d8h, 2fh, 40h	; LDC WA, DMAC0 (read DMA channel 0 count)
	ENDM

LDC_DMAC2_BC MACRO
	db 0d9h, 2eh, 48h	; LDC DMAC2, BC (DMA channel 2 count)
	ENDM

LDC_DMAC2_WA MACRO
	db 0d8h, 2eh, 48h	; LDC DMAC2, WA (DMA channel 2 count)
	ENDM

LDC_DMAC3_BC MACRO
	db 0d9h, 2eh, 4ch	; LDC DMAC3, BC (DMA channel 3 count)
	ENDM

; DMA Mode registers (DMAM) - 8-bit, CR offsets 0x42/0x46/0x4A/0x4E
LDC_DMAM0_A MACRO
	db 0c9h, 2eh, 42h	; LDC DMAM0, A (DMA channel 0 mode)
	ENDM

LDC_DMAM2_A MACRO
	db 0c9h, 2eh, 4ah	; LDC DMAM2, A (DMA channel 2 mode)
	ENDM

LDC_DMAM3_A MACRO
	db 0c9h, 2eh, 4eh	; LDC DMAM3, A (DMA channel 3 mode)
	ENDM

LDC_DMAD3_XHL MACRO
	db 0ebh, 2eh, 2ch	; LDC DMAD3, XHL
	ENDM

LDC_DMAS0_XWA MACRO
	db 0e8h, 2eh, 00h	; LDC DMAS0, XWA
	ENDM

LDC_DMAS2_XWA MACRO
	db 0e8h, 2eh, 08h	; LDC DMAS2, XWA
	ENDM

LDC_DMAS3_XHL MACRO
	db 0ebh, 2eh, 0ch	; LDC DMAS3, XHL
	ENDM

LDC_DMAS2_XBC MACRO
	db 0e9h, 2eh, 08h	; LDC DMAS2, XBC
	ENDM

LDC_DMAS2_XDE MACRO
	db 0eah, 2eh, 08h	; LDC DMAS2, XDE
	ENDM

LDC_DMAS2_XHL MACRO
	db 0ebh, 2eh, 08h	; LDC DMAS2, XHL
	ENDM

LDC_INTNEST_WA MACRO
	db 0d8h, 2eh, 7ch	; LDC INTNEST, WA
	ENDM

LD_W MACRO value
	db 020h, value		; LD W, byte
	ENDM

LD_A MACRO value
	db 021h, value		; LD A, byte
	ENDM

LD_B MACRO value
	db 022h, value		; LD B, byte
	ENDM

LD_C MACRO value
	db 023h, value		; LD C, byte
	ENDM

LD_D MACRO value
	db 024h, value		; LD D, byte
	ENDM

LD_E MACRO value
	db 025h, value		; LD E, byte
	ENDM

LD_H MACRO value
	db 026h, value		; LD H, byte
	ENDM

LD_L MACRO value
	db 027h, value		; LD L, byte
	ENDM

LDW_16_16 MACRO dst, src
	db 0d1h, src & 0ffh, (src >> 8) & 0ffh, 019h, dst & 0ffh, (dst >> 8) & 0ffh	; LDW (word_dst), (word_src)
	ENDM

LD_8_8 MACRO dst, src
	db 0c1h, src & 0ffh, (src >> 8) & 0ffh, 019h, dst & 0ffh, (dst >> 8) & 0ffh	; LD (byte_dst), (byte_src)
	ENDM

LDA_XBC_XWA_plus MACRO
	db 0f5h, 0e2h, 031h	; LDA XBC, XWA+
	ENDM

LDA_XBC_XWA_plus__e1__ MACRO
	db 0f5h, 0e1h, 031h	; LDA XBC, XWA+
	ENDM

LDA_XBC_XWA_plus__e0__ MACRO
	db 0f5h, 0e0h, 031h	; LDA XBC, XWA+ (E0 variant)
	ENDM

LDA_XDE_XWA_plus__e0__ MACRO
	db 0f5h, 0e0h, 032h	; LDA XDE, XWA+ (E0 variant)
	ENDM

LDA_XHL_XWA_plus__e0__ MACRO
	db 0f5h, 0e0h, 033h	; LDA XHL, XWA+ (E0 variant)
	ENDM

LDA_XWA_XWA_plus__e0__ MACRO
	db 0f5h, 0e0h, 030h	; LDA XWA, XWA+ (E0 variant)
	ENDM

LDA_XIX_XWA_plus__e0__ MACRO
	db 0f5h, 0e0h, 034h	; LDA XIX, XWA+ (E0 variant)
	ENDM

LDA_XIX_XIZ_plus__f9__ MACRO
	db 0f5h, 0f9h, 034h	; LDA XIX, XIZ+ (F9 variant)
	ENDM

LDA_XIX_XIZ_plus__f8__ MACRO
	db 0f5h, 0f8h, 034h	; LDA XIX, XIZ+ (F8 variant)
	ENDM

LDA_XDE_XBC_plus MACRO
	db 0f5h, 0e5h, 032h	; LDA XDE, XBC+
	ENDM

LDA_XHL_XBC_plus__e4__ MACRO
	db 0f5h, 0e4h, 033h	; LDA XHL, XBC+ (E4 variant)
	ENDM

LDA_XIY_XDE_plus__e8__ MACRO
	db 0f5h, 0e8h, 035h	; LDA XIY, XDE+ (E8 variant)
	ENDM

LDA_XBC_XHL__ec__ MACRO
	db 0f5h, 0ech, 031h	; LDA XBC, (XHL) (EC variant, no auto-increment)
	ENDM

LD_XWA_XDE_plus MACRO
	db 0f5h, 0e8h, 030h	; LDA XWA, XDE+
	ENDM


; Note: It is unclear to me why do we have 2 different encodings for some of
;       these LDI instructions and its variants.
;       Maybe these are actually different instructions?
;	I should take a look at the CPU datasheet to clarify this.
;
LDIRW_95 MACRO
	db 095h, 011h		; LDIRW
	ENDM

LDIRW_93 MACRO
	db 093h, 011h		; LDIRW
	ENDM


LDI MACRO
	db 085h, 010h		; LDI
	ENDM

LDIW MACRO
	db 095h, 010h		; LDIW
	ENDM

LDIR_83 MACRO
	db 083h, 011h		; LDIR
	ENDM

LDIR MACRO
	db 085h, 011h		; LDIR
	ENDM

LDDR_85 MACRO
	db 085h, 013h		; LDDR (85 variant)
	ENDM

MUL_A MACRO value
	db 0c9h, 008h, value	; MUL A, byte
	ENDM

MUL_C MACRO value
	db 0cbh, 008h, value	; MUL C, byte
	ENDM

MUL_E MACRO value
	db 0cdh, 008h, value	; MUL E, byte
	ENDM

MUL_L MACRO value
	db 0cfh, 008h, value	; MUL L, byte
	ENDM

MUL_WA MACRO value
	db 0d8h, 008h, value & 0ffh, (value >> 8) & 0ffh	; MUL WA, word
	ENDM

MUL_BC MACRO value
	db 0d9h, 008h, value & 0ffh, (value >> 8) & 0ffh	; MUL BC, word
	ENDM

MUL_DE MACRO value
	db 0dah, 008h, value & 0ffh, (value >> 8) & 0ffh	; MUL DE, word
	ENDM

MUL_HL MACRO value
	db 0dbh, 008h, value & 0ffh, (value >> 8) & 0ffh	; MUL HL, word
	ENDM

MUL_IX MACRO value
	db 0dch, 008h, value & 0ffh, (value >> 8) & 0ffh	; MUL IX, word
	ENDM

MUL_IY MACRO value
	db 0ddh, 008h, value & 0ffh, (value >> 8) & 0ffh	; MUL IY, word
	ENDM

MUL_IZ MACRO value
	db 0deh, 008h, value & 0ffh, (value >> 8) & 0ffh	; MUL IZ, word
	ENDM

MULW_WA MACRO value
	db 0d8h, 008h, value & 0ffh, (value >> 8) & 0ffh	; MULW WA, word
	ENDM

MULS_A MACRO value
	db 0c9h, 009h, value	; MULS A, word
	ENDM

MULS_C MACRO value
	db 0cbh, 009h, value	; MULS C, word
	ENDM

MULS_L MACRO value
	db 0cfh, 009h, value	; MULS L, word
	ENDM

MULS_WA MACRO value
	db 0d8h, 009h, value & 0ffh, (value >> 8) & 0ffh	; MULS WA, word
	ENDM

MULS_BC MACRO value
	db 0d9h, 009h, value & 0ffh, (value >> 8) & 0ffh	; MULS BC, word
	ENDM

MULS_DE MACRO value
	db 0dah, 009h, value & 0ffh, (value >> 8) & 0ffh	; MULS DE, word
	ENDM

MULS_HL MACRO value
	db 0dbh, 009h, value & 0ffh, (value >> 8) & 0ffh	; MULS HL, word
	ENDM

MULS_IX MACRO value
	db 0dch, 009h, value & 0ffh, (value >> 8) & 0ffh	; MULS IX, word
	ENDM

MULS_IY MACRO value
	db 0ddh, 009h, value & 0ffh, (value >> 8) & 0ffh	; MULS IY, word
	ENDM

MULS_IZ MACRO value
	db 0deh, 009h, value & 0ffh, (value >> 8) & 0ffh	; MULS IZ, word
	ENDM

; NOTE: I am not so sure about this one...
MULS_IYL MACRO value
	db 0c7h, 0f4h, value & 0ffh, (value >> 8) & 0ffh	; MULS IYL, word
	ENDM

MULS_XWA_IX MACRO
	db 0dch, 48h	; MULS XWA, IX
	ENDM

MULS_XWA_DE MACRO
	db 0dah, 48h	; MULS XWA, DE
	ENDM

MULS_XDE_IY MACRO
	db 0ddh, 4ah	; MULS XDE IY
	ENDM

DIV_A MACRO value
	db 0c9h, 00ah, value	; DIV A, byte
	ENDM

DIV_C MACRO value
	db 0cbh, 00ah, value	; DIV C, byte
	ENDM

DIV_E MACRO value
	db 0cdh, 00ah, value	; DIV E, byte
	ENDM

DIV_L MACRO value
	db 0cfh, 00ah, value	; DIV L, byte
	ENDM

DIVW_WA MACRO value
	db 0d8h, 00ah, value & 0ffh, (value >> 8) & 0ffh	; DIVW WA, word
	ENDM

DIVW_BC MACRO value
	db 0d9h, 00ah, value & 0ffh, (value >> 8) & 0ffh	; DIVW BC, word
	ENDM

DIVW_DE MACRO value
	db 0dah, 00ah, value & 0ffh, (value >> 8) & 0ffh	; DIVW DE, word
	ENDM

DIVW_HL MACRO value
	db 0dbh, 00ah, value & 0ffh, (value >> 8) & 0ffh	; DIVW HL, word
	ENDM

DIVW_IX MACRO value
	db 0dch, 00ah, value & 0ffh, (value >> 8) & 0ffh	; DIVW IX, word
	ENDM

DIVW_IY MACRO value
	db 0ddh, 00ah, value & 0ffh, (value >> 8) & 0ffh	; DIVW IY, word
	ENDM

DIVW_IZ MACRO value
	db 0deh, 00ah, value & 0ffh, (value >> 8) & 0ffh	; DIVW IZ, word
	ENDM

DIVS_WA MACRO value
	db 0d8h, 00bh, value & 0ffh, (value >> 8) & 0ffh	; DIVS WA, word
	ENDM

DIVS_BC MACRO value
	db 0d9h, 00bh, value & 0ffh, (value >> 8) & 0ffh	; DIVS BC, word
	ENDM

DIVS_DE MACRO value
	db 0dah, 00bh, value & 0ffh, (value >> 8) & 0ffh	; DIVS DE, word
	ENDM

DIVS_HL MACRO value
	db 0dbh, 00bh, value & 0ffh, (value >> 8) & 0ffh	; DIVS HL, word
	ENDM

DIVS_IX MACRO value
	db 0dch, 00bh, value & 0ffh, (value >> 8) & 0ffh	; DIVS IX, word
	ENDM

DIVS_IY MACRO value
	db 0ddh, 00bh, value & 0ffh, (value >> 8) & 0ffh	; DIVS IY, word
	ENDM
	
SRA_0_XWA MACRO
	db 0e8h, 0edh, 000h	; SRA ?, XWA
	ENDM

SRA_8_XWA MACRO
	db 0e8h, 0edh, 008h	; SRA ?, XWA
	ENDM

SLA_0_XBC MACRO
	db 0e9h, 0ech, 000h	; SLA ?, XBC
	ENDM

SLA_0_XHL MACRO
	db 0ebh, 0ech, 000h	; SLA ?, XHL
	ENDM

SLA_8_XDE MACRO
	db 0eah, 0ech, 008h	; SLA ?, XDE
	ENDM

SRL_0_XDE MACRO
	db 0eah, 0efh, 000h	; SRL ?, XDE
	ENDM

SLA_8_XWA MACRO
	db 0e8h, 0ech, 008h	; SLA 8, XWA
	ENDM

SLA_0_XIX MACRO
	db 0ech, 0ech, 000h	; SLA ?, XIX
	ENDM

SLL_0_XIX MACRO
	db 0ech, 0eeh, 000h	; SLL ?, XIX
	ENDM

SRL_0_XHL MACRO
	db 0ebh, 0efh, 000h	; SRL ?, XHL
	ENDM

SRL_0_XWA MACRO
	db 0e8h, 0efh, 000h	; SRL 0, XWA
	ENDM

SRL_0_XBC MACRO
	db 0e9h, 0efh, 000h	; SRL 0, XBC
	ENDM

SLL_0_XWA MACRO
	db 0e8h, 0eeh, 000h	; SLL 0, XWA
	ENDM

SLL_0_XBC MACRO
	db 0e9h, 0eeh, 000h	; SLL 0, XBC
	ENDM

SLL_0_XDE MACRO
	db 0eah, 0eeh, 000h	; SLL 0, XDE
	ENDM

SLL_0_XHL MACRO
	db 0ebh, 0eeh, 000h	; SLL 0, XHL
	ENDM

SLL_8_XIX MACRO
	db 0ech, 0eeh, 008h	; SLL 8, XIX
	ENDM

SLA_0_XWA MACRO
	db 0e8h, 0ech, 000h	; SLA 0, XWA
	ENDM

SRA_0_XBC MACRO
	db 0e9h, 0edh, 000h	; SRA 0, XBC
	ENDM

SRA_0_XDE MACRO
	db 0eah, 0edh, 000h	; SRA 0, XDE
	ENDM

; ==============================================================================
; Additional macros for Sub CPU boot ROM assembly
; ==============================================================================

; INC 0, XBC - Increment XBC by 1 (0+1=1)
; Encoding: e9 60
INC_0_XBC MACRO
	db 0e9h, 060h		; INC 0, XBC
	ENDM

; PUSH word immediate
; Encoding: 0b LL HH (little-endian)
PUSH_WORD MACRO value
	db 00bh, value & 0FFh, (value >> 8) & 0FFh	; PUSH word
	ENDM

; CP (XWA), word - Compare memory at XWA with 16-bit immediate
; Encoding: 90 3f LL HH
CP_pXWA_WORD MACRO value
	db 090h, 03fh, value & 0FFh, (value >> 8) & 0FFh	; CP (XWA), word
	ENDM

; CP (XBC+d), word - Compare memory at XBC+d with 16-bit immediate
; Encoding: 99 dd 3f LL HH
CP_pXBC_d_WORD MACRO disp, value
	db 099h, disp, 03fh, value & 0FFh, (value >> 8) & 0FFh	; CP (XBC+d), word
	ENDM

; LDA XWA, 24-bit address - Load effective address into XWA
; Encoding: f2 LL MM HH (where address is 0xHHMMLLL)
LDA_XWA_IMM24 MACRO value
	db 0f2h, value & 0FFh, (value >> 8) & 0FFh, (value >> 16) & 0FFh, 030h
	ENDM

; LD_MEM24_IMM16 - Store 16-bit immediate to 24-bit memory address
; Encoding: f2 LL MM HH 02 VV WW (7 bytes)
; where address is 0xHHMMLLL and value is 0xWWVV
; Use when ASL generates 6-byte encoding instead of 7-byte
LD_MEM24_IMM16 MACRO addr, value
	db 0f2h
	db addr & 0FFh, (addr >> 8) & 0FFh, (addr >> 16) & 0FFh
	db 02h		; Size specifier for word (16-bit)
	db value & 0FFh, (value >> 8) & 0FFh
	ENDM

; LD_pXIX_IMM16 - Store 16-bit immediate to memory via XIX
; Encoding: b4 02 LL HH (4 bytes)
; Use when ASL generates 3-byte encoding instead of 4-byte
LD_pXIX_IMM16 MACRO value
	db 0b4h, 02h
	db value & 0FFh, (value >> 8) & 0FFh
	ENDM

; LD_pXHL_IMM16 - Store 16-bit immediate to memory via XHL
; Encoding: b3 02 LL HH (4 bytes)
; Use when ASL generates 3-byte encoding instead of 4-byte
LD_pXHL_IMM16 MACRO value
	db 0b3h, 02h
	db value & 0FFh, (value >> 8) & 0FFh
	ENDM

; CALR addr - Call relative (shorter encoding than CALL)
; Encoding: 1e LL HH (16-bit signed relative offset)
; Note: offset is calculated from the byte after the instruction
CALR MACRO target
	db 01eh
	dw target - $ - 2		; Relative offset ($ is already at byte 1)
	ENDM

; CALL_ABS24 addr - Call absolute with 24-bit address (4-byte encoding)
; Encoding: 1d LL MM HH
; Use when ASL generates wrong encoding for call instruction
CALL_ABS24 MACRO target
	db 01dh, target & 0FFh, (target >> 8) & 0FFh, (target >> 16) & 0FFh
	ENDM

; JRL_T addr - Jump relative long (always true condition)
; Encoding: 78 LL HH (3-byte instruction)
; Use when ASL generates jp instead of jrl
JRL_T MACRO target
	db 078h
	dw target - $ - 2		; Relative offset from after instruction
	ENDM

; LDIR_94 - Load, Increment, Repeat (TMP94C241 encoding)
; Encoding: 83 11 (ASL generates 85 11 which is TMP96C141 encoding)
; Copies bytes from (XHL) to (XDE), count in XBC
LDIR_94 MACRO
	db 083h, 011h
	ENDM

; ==============================================================================
; QIZH register access macros
; QIZH is the high byte of the QIZ register (32-bit index register)
; Register code 0xFB in the extended register encoding
; ==============================================================================

; LD_QIZH_IMM - Load immediate value into QIZH
; Encoding: c7 fb a8+value (for value 0-7) or c7 fb 20 value
LD_QIZH_0 MACRO
	db 0c7h, 0fbh, 0a8h		; ld QIZH, 0
	ENDM

; LD_A_QIZH - Load A from QIZH
; Encoding: c7 fb 89
LD_A_QIZH MACRO
	db 0c7h, 0fbh, 089h		; ld A, QIZH
	ENDM

; LD_C_QIZH - Load C from QIZH
; Encoding: c7 fb 8b
LD_C_QIZH MACRO
	db 0c7h, 0fbh, 08bh		; ld C, QIZH
	ENDM

; INC_1_QIZH - Increment QIZH by 1
; Encoding: c7 fb 61
INC_1_QIZH MACRO
	db 0c7h, 0fbh, 061h		; inc 1, QIZH
	ENDM

; CP_QIZH_IMM - Compare QIZH with immediate value
; Encoding: c7 fb d8+value (for value 0-7) or c7 fb cf value
CP_QIZH_4 MACRO
	db 0c7h, 0fbh, 0dch		; cp QIZH, 4
	ENDM

; ==============================================================================
; Memory comparison macro
; ==============================================================================

; CP_MEM24_IMM16 - Compare 16-bit value at 24-bit address with immediate
; Encoding: d2 LL MM HH 3f VV WW (7 bytes)
CP_MEM24_IMM16 MACRO addr, value
	db 0d2h
	db addr & 0FFh, (addr >> 8) & 0FFh, (addr >> 16) & 0FFh
	db 03fh
	db value & 0FFh, (value >> 8) & 0FFh
	ENDM

; ==============================================================================
; Shift macros
; ==============================================================================

; SLA_2_BC - Shift BC left arithmetic by 2 (multiply by 4)
; Encoding: d9 ec 02
SLA_2_BC MACRO
	db 0d9h, 0ech, 002h		; sla 2, BC
	ENDM

; ==============================================================================
; Load effective address macros
; ==============================================================================

; LDA_XDE_IMM24 - Load 24-bit effective address into XDE
; Encoding: f2 LL MM HH 32 (5 bytes)
LDA_XDE_IMM24 MACRO addr
	db 0f2h
	db addr & 0FFh, (addr >> 8) & 0FFh, (addr >> 16) & 0FFh
	db 032h
	ENDM

; ==============================================================================
; Indexed load macros
; ==============================================================================

; LD_XBC_pXDE_BC - Load XBC from memory at (XDE+BC)
; Encoding: e3 07 e8 e4 21 (5 bytes)
LD_XBC_pXDE_BC MACRO
	db 0e3h, 007h, 0e8h, 0e4h, 021h	; ld XBC, (XDE+BC)
	ENDM

; ==============================================================================
; Stack-relative load macros
; ==============================================================================

; LD_XBC_pXSP_d - Load XBC from (XSP+disp)
; Encoding: af dd 21 (3 bytes)
LD_XBC_pXSP_d MACRO disp
	db 0afh, disp, 021h		; ld XBC, (XSP+disp)
	ENDM

; LD_A_pXSP_d - Load A from (XSP+disp)
; Encoding: 8f dd 21 (3 bytes)
LD_A_pXSP_d MACRO disp
	db 08fh, disp, 021h		; ld A, (XSP+disp)
	ENDM

; LD_XDE_pXSP_d - Load XDE from (XSP+disp)
; Encoding: af dd 22 (3 bytes)
LD_XDE_pXSP_d MACRO disp
	db 0afh, disp, 022h		; ld XDE, (XSP+disp)
	ENDM

; LD_pXSP_d_XDE - Store XDE to (XSP+disp)
; Encoding: bf dd 62 (3 bytes)
LD_pXSP_d_XDE MACRO disp
	db 0bfh, disp, 062h		; ld (XSP+disp), XDE
	ENDM

; LD_pXSP_d_A - Store A to (XSP+disp)
; Encoding: bf dd 41 (3 bytes)
LD_pXSP_d_A MACRO disp
	db 0bfh, disp, 041h		; ld (XSP+disp), A
	ENDM

; ADD_pXSP_d_XWA - Add XWA to memory at (XSP+disp)
; Encoding: af dd 88 (3 bytes)
ADD_pXSP_d_XWA MACRO disp
	db 0afh, disp, 088h		; add (XSP+disp), XWA
	ENDM

; ==============================================================================
; Register-to-register load macros
; ==============================================================================

; LD_XDE_XIZ - Load XDE from XIZ
; Encoding: ee 8a (2 bytes)
LD_XDE_XIZ MACRO
	db 0eeh, 08ah			; ld XDE, XIZ
	ENDM

; LD_BC_QBC - Load BC from QBC (high word of XBC)
; Encoding: d7 e6 89 (3 bytes)
LD_BC_QBC MACRO
	db 0d7h, 0e6h, 089h		; ld BC, QBC
	ENDM

; LD_BC_QDE - Load BC from QDE (high word of XDE)
; Encoding: d7 ea 89 (3 bytes)
LD_BC_QDE MACRO
	db 0d7h, 0eah, 089h		; ld BC, QDE
	ENDM

; ==============================================================================
; Stack pointer increment macro
; ==============================================================================

; INC_0_XSP - Increment XSP by 1 (0+1=1) - adjust stack
; Encoding: ef 60 (2 bytes)
INC_0_XSP MACRO
	db 0efh, 060h			; inc 0, XSP
	ENDM

; ==============================================================================
; Memory store with auto-increment
; ==============================================================================

; LD_pXWA_plus_BC - Store BC to memory at XWA, then increment XWA
; Encoding: f5 e1 51 (3 bytes)
LD_pXWA_plus_BC MACRO
	db 0f5h, 0e1h, 051h		; ld (XWA+), BC
	ENDM

; ==============================================================================
; Decrement and jump if not zero macros
; ==============================================================================

; DJNZ_DE - Decrement DE and jump if not zero (relative)
; Encoding: da 1c dd (3 bytes, signed 8-bit displacement)
DJNZ_DE MACRO target
	db 0dah, 01ch
	db (target - $ - 1) & 0FFh	; Signed 8-bit displacement
	ENDM

; ==============================================================================
; Memory arithmetic with auto-increment
; ==============================================================================

; ADD_XHL_pXWA_plus - Add (XWA+) to XHL, post-increment XWA
; Encoding: e5 e2 83 (3 bytes)
ADD_XHL_pXWA_plus MACRO
	db 0e5h, 0e2h, 083h		; add XHL, (XWA+)
	ENDM

; ==============================================================================
; Stack frame macros (for DMA Transfer Routines)
; ==============================================================================

; DEC_6_XSP - Decrement XSP by 6 (allocate 6 bytes on stack)
; Encoding: ef 6e (2 bytes)
DEC_6_XSP MACRO
	db 0efh, 06eh			; dec 6, XSP
	ENDM

; INC_6_XSP - Increment XSP by 6 (deallocate 6 bytes from stack)
; Encoding: ef 66 (2 bytes)
INC_6_XSP MACRO
	db 0efh, 066h			; inc 6, XSP
	ENDM

; ==============================================================================
; IZ register operations
; ==============================================================================

; LD_IZ_BC - Load IZ from BC (16-bit transfer)
; Encoding: d9 8e (2 bytes)
LD_IZ_BC MACRO
	db 0d9h, 08eh			; ld IZ, BC
	ENDM

; CP_IZ_imm16 - Compare IZ with 16-bit immediate
; Encoding: de cf low high (4 bytes)
CP_IZ_imm16 MACRO value
	db 0deh, 0cfh
	db (value) & 0FFh		; low byte
	db ((value) >> 8) & 0FFh	; high byte
	ENDM

; SUB_IZ_imm16 - Subtract 16-bit immediate from IZ
; Encoding: de ca low high (4 bytes)
SUB_IZ_imm16 MACRO value
	db 0deh, 0cah
	db (value) & 0FFh		; low byte
	db ((value) >> 8) & 0FFh	; high byte
	ENDM

; LD_C_IZL - Load C from IZL (low byte of IZ)
; Encoding: c7 f8 8b (3 bytes)
LD_C_IZL MACRO
	db 0c7h, 0f8h, 08bh		; ld C, IZL
	ENDM

; ==============================================================================
; Zero-extend operations
; ==============================================================================

; EXTZ_WA - Zero-extend A to WA (clear W, keep A)
; Encoding: d8 12 (2 bytes)
EXTZ_WA MACRO
	db 0d8h, 012h			; extz WA
	ENDM

; EXTZ_BC - Zero-extend C to BC (clear B, keep C)
; Encoding: d9 12 (2 bytes)
EXTZ_BC MACRO
	db 0d9h, 012h			; extz BC
	ENDM
