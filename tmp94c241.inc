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

LDC_DMAC0_A MACRO
	db 0c9h, 2eh, 42h	; LDC DMAC0, A
	ENDM

LDC_DMAC0_WA MACRO
	db 0d8h, 2eh, 40h	; LDC DMAC0, WA
	ENDM

LDC_DMAC2_XWA MACRO
	db 0c9h, 2eh, 4ah	; LDC DMAC2, WA
	ENDM

LDC_DMAC2_A MACRO
	db 0c9h, 2eh, 4ah	; LDC DMAC2, A
	ENDM

LDC_DMAC3_A MACRO
	db 0c9h, 2eh, 4eh	; LDC DMAC3, A
	ENDM

LDC_DMAM0_WA MACRO
	db 0d8h, 2eh, 40h	; LDC DMAM0, WA
	ENDM

LDC_WA_DMAM0 MACRO
	db 0d8h, 2fh, 40h	; LDC WA, DMAM0
	ENDM

LDC_DMAM2_WA MACRO
	db 0d8h, 2eh, 48h	; LDC DMAM2, WA
	ENDM

LDC_DMAM2_BC MACRO
	db 0d9h, 2eh, 48h	; LDC DMAM2, BC
	ENDM

LDC_DMAM3_BC MACRO
	db 0d9h, 2eh, 4ch	; LDC DMAM3, BC
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

LDA_XDE_XBC_plus MACRO
	db 0f5h, 0e5h, 032h	; LDA XDE, XBC+
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
