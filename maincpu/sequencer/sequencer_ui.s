; =============================================================================
; Sequencer UI (14K lines)
; =============================================================================
;
; Sequencer editing user interface: track display, step/event
; editing, and the bitmap drum editor integration.
; =============================================================================

InitializeYoko:
	lda xsp, (xsp - 14)

	RegObjTable 0x1600004, 0xFA44E2, 0xE20CAE, 0xE208EC, 0x167
	RegObjTable 0x160000c, 0xFA58FB, 0xE20E22, 0xE20CB0, 0x1c7
	RegObjTable 0x160000d, 0xFA5948, 0xE2106A, 0xE20E24, 0x1e7
	RegObjTabl 0x1600002, 0xFA496C, 0x2e, 0xE20260, 0x127
	RegObjTabl 0x1600002, 0xFA496C, 0x2e, 0xE2031C, 0x427
	RegObjTabl 0x1600001, 0xFA48A9, 0x1, 0xE2106C, 0x107
	RegObjTabl 0x1600001, 0xFA48A9, 0x1, 0xE21074, 0x407
	RegObjTabl 0x1600003, 0xFA4A18, 0x1f, 0xE25042, 0x147
	RegObjTabl 0x1600003, 0xFA4A18, 0x1f, 0xE250C2, 0x447
	RegObjTabl 0x1600010, 0xFA5995, 0x2b, 0xE240AC, 0x6f
	RegObjTabl 0x160000f, 0xFA62CB, 0x2b, 0xE24578, 0x36f
	RegObjTabl 0x1600010, 0xFA5995, 0xc, 0xE2415C, 0x70
	RegObjTabl 0x160000f, 0xFA62CB, 0xc, 0xE246C8, 0x370
	RegObjTabl 0x1600010, 0xFA5995, 0xb, 0xE24190, 0x71
	RegObjTabl 0x160000f, 0xFA62CB, 0xb, 0xE2472E, 0x371
	RegObjTabl 0x1600010, 0xFA5995, 0x7, 0xE241C0, 0x72
	RegObjTabl 0x160000f, 0xFA62CB, 0x7, 0xE24788, 0x372
	RegObjTabl 0x1600010, 0xFA5995, 0x10, 0xE241E0, 0x73
	RegObjTabl 0x160000f, 0xFA62CB, 0x10, 0xE247CA, 0x373
	RegObjTabl 0x1600010, 0xFA5995, 0xf, 0xE24224, 0x74
	RegObjTabl 0x160000f, 0xFA62CB, 0xf, 0xE24844, 0x374
	RegObjTabl 0x1600010, 0xFA5995, 0xd, 0xE24264, 0x75
	RegObjTabl 0x160000f, 0xFA62CB, 0xd, 0xE248CC, 0x375
	RegObjTabl 0x1600010, 0xFA5995, 0x8, 0xE2429C, 0x76
	RegObjTabl 0x160000f, 0xFA62CB, 0x8, 0xE2493A, 0x376
	RegObjTabl 0x1600010, 0xFA5995, 0x1e, 0xE242C0, 0x78
	RegObjTabl 0x160000f, 0xFA62CB, 0x1e, 0xE2497C, 0x378
	RegObjTabl 0x1600010, 0xFA5995, 0xc, 0xE2433C, 0x7a
	RegObjTabl 0x160000f, 0xFA62CB, 0xc, 0xE24A3E, 0x37a
	RegObjTabl 0x1600010, 0xFA5995, 0x5, 0xE24370, 0x89
	RegObjTabl 0x160000f, 0xFA62CB, 0x5, 0xE24A94, 0x389
	RegObjTabl 0x1600010, 0xFA5995, 0x1, 0xE24388, 0x8a
	RegObjTabl 0x160000f, 0xFA62CB, 0x1, 0xE24ABE, 0x38a
	RegObjTabl 0x1600010, 0xFA5995, 0x16, 0xE24390, 0x8b
	RegObjTabl 0x160000f, 0xFA62CB, 0x16, 0xE24ACA, 0x38b
	RegObjTabl 0x1600010, 0xFA5995, 0x1c, 0xE243EC, 0x8c
	RegObjTabl 0x160000f, 0xFA62CB, 0x1c, 0xE24B80, 0x38c
	RegObjTabl 0x1600010, 0xFA5995, 0x5, 0xE24460, 0x8e
	RegObjTabl 0x160000f, 0xFA62CB, 0x5, 0xE24C70, 0x38e
	RegObjTabl 0x1600010, 0xFA5995, 0x6, 0xE24478, 0x8f
	RegObjTabl 0x160000f, 0xFA62CB, 0x6, 0xE24C9C, 0x38f
	RegObjTabl 0x1600010, 0xFA5995, 0x4, 0xE24494, 0x92
	RegObjTabl 0x160000f, 0xFA62CB, 0x4, 0xE24CCE, 0x392
	RegObjTabl 0x1600010, 0xFA5995, 0x0, 0xE244A8, 0xa7
	RegObjTabl 0x160000f, 0xFA62CB, 0x0, 0xE24CF8, 0x3a7
	RegObjTabl 0x1600010, 0xFA5995, 0x6, 0xE244AC, 0xa9
	RegObjTabl 0x160000f, 0xFA62CB, 0x6, 0xE24CFE, 0x3a9
	RegObjTabl 0x1600010, 0xFA5995, 0x4, 0xE244C8, 0xe0
	RegObjTabl 0x160000f, 0xFA62CB, 0x4, 0xE24D32, 0x3e0
	RegObjTabl 0x1600010, 0xFA5995, 0xc, 0xE244DC, 0xe1
	RegObjTabl 0x160000f, 0xFA62CB, 0xc, 0xE24D58, 0x3e1
	RegObjTabl 0x1600010, 0xFA5995, 0xc, 0xE24510, 0xe2
	RegObjTabl 0x160000f, 0xFA62CB, 0xc, 0xE24DE6, 0x3e2
	RegObjTabl 0x1600010, 0xFA5995, 0xc, 0xE24544, 0xe3
	RegObjTabl 0x160000f, 0xFA62CB, 0xc, 0xE24E78, 0x3e3

	RegMode 0x7, 0xe2, 0x4f10, 0xd, 0x1470014, 0x1a00089
	RegMode 0x7, 0xe2, 0x4f1c, 0x13, 0x1470017, 0x1a000e0

	RegTitle 0x7, 0xe2, 0x4f24, 0x6f, 0x1470012, 0x6f0000
	RegTitle 0x7, 0xe2, 0x4f2e, 0x70, 0x1470010, 0x700000
	RegTitle 0x7, 0xe2, 0x4f38, 0x71, 0x1470011, 0x710000
	RegTitle 0x7, 0xe2, 0x4f40, 0x72, 0x1470013, 0x720000
	RegTitle 0x7, 0xe2, 0x4f4c, 0x73, 0x147000e, 0x730000
	RegTitle 0x7, 0xe2, 0x4f5a, 0x74, 0x147000c, 0x740001
	RegTitle 0x7, 0xe2, 0x4f68, 0x75, 0x147000d, 0x750000
	RegTitle 0x7, 0xe2, 0x4f74, 0x76, 0x147000f, 0x760000
	RegTitle 0x7, 0xe2, 0x4f84, 0x78, 0x147000b, 0x780000
	RegTitle 0x7, 0xe2, 0x4f92, 0x7a, 0x147000a, 0x7a0000
	RegTitle 0x7, 0xe2, 0x4fa0, 0x89, 0x1470015, 0x890000
	RegTitle 0x7, 0xe2, 0x4fac, 0x8a, 0x1470016, 0x8a0000
	RegTitle 0x7, 0xe2, 0x4fb6, 0x8b, 0x1470006, 0x8b0000
	RegTitle 0x7, 0xe2, 0x4fc0, 0x8c, 0x1470008, 0x8c0000
	RegTitle 0x7, 0xe2, 0x4fcc, 0x8e, 0x1470004, 0x8e0000
	RegTitle 0x7, 0xe2, 0x4fd8, 0x8f, 0x1470005, 0x8f0000
	RegTitle 0x7, 0xe2, 0x4fe6, 0x92, 0x1470003, 0x920000
	RegTitle 0x7, 0xe2, 0x4ff2, 0xa7, 0x1470005, 0x8f0000
	RegTitle 0x7, 0xe2, 0x5000, 0xa9, 0x1200000, 0xa90000
	RegTitle 0x7, 0xe2, 0x500e, 0xe0, 0x1470018, 0xe00000
	RegTitle 0x7, 0xe2, 0x501a, 0xe1, 0x1470019, 0xe10000
	RegTitle 0x7, 0xe2, 0x5028, 0xe2, 0x147001a, 0xe20000
	RegTitle 0x7, 0xe2, 0x5036, 0xe3, 0x147001b, 0xe30000

	lda xsp, (xsp + 14)
	ret

PartSelLangCheck:
	cp xbc, 0x1E0009F
	jr nz, PartSelLang_ReturnZero
	lda_24 xhl, 0xe26078
	ret

PartSelLang_ReturnZero:
	lds32 xhl, 0
	ret

AfterLangCheck:
	cp xbc, 0x1E0009F
	jr nz, AfterLang_ReturnZero
	lda_24 xhl, 0xe26090
	ret

AfterLang_ReturnZero:
	lds32 xhl, 0
	ret

TrAsPreLangCheck:
	cp xbc, 0x1E0009F
	jr nz, TrAsPreLang_ReturnZero
	lda_24 xhl, 0xe260a8
	ret

TrAsPreLang_ReturnZero:
	lds32 xhl, 0
	ret

AtentionLangCheck:
	cp xbc, 0x1E0009F
	jr nz, AtentionLang_ReturnZero
	lda_24 xhl, 0xe260c0
	ret

AtentionLang_ReturnZero:
	lds32 xhl, 0
	ret

AreYouSureLangCheck:
	cp xbc, 0x1E0009F
	jr nz, AreYouSureLang_ReturnZero
	lda_24 xhl, 0xe260d8
	ret

AreYouSureLang_ReturnZero:
	lds32 xhl, 0
	ret

GmOnSureLangCheck:
	cp xbc, 0x1E0009F
	jr nz, GmOnSureLang_ReturnZero
	lda_24 xhl, 0xe260f0
	ret

GmOnSureLang_ReturnZero:
	lds32 xhl, 0
	ret

GmOffSureLangCheck:
	cp xbc, 0x1E0009F
	jr nz, GmOffSureLang_ReturnZero
	lda_24 xhl, 0xe26108
	ret

GmOffSureLang_ReturnZero:
	lds32 xhl, 0
	ret

TrAsSureLangCheck:
	cp xbc, 0x1E0009F
	jr nz, TrAsSureLang_ReturnZero
	ldda8 a, 10355
	extz wa
	sla wa, 2
	lda_24 xbc, 0xe26120
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	push xwa
	ldda8 a, 4438
	extz wa
	sla wa, 2
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	push xwa
	ldda8 a, 3295
	inc 1, a
	extz wa
	pushw wa
	ld8_24 a, 0x0340e4
	extz wa
	sla wa, 2
	lda_24 xbc, 0xe25e50
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	push xwa
	pushw 0x2
	pushw 0xCB4
	call Audio_SendCommand
	lda xsp, (xsp + 18)
	lda_24 xhl, 0x03def8
	ret

TrAsSureLang_ReturnZero:
	lds32 xhl, 0
	ret

Audio_SendEventPostCmd:
	ld xwa, 0x720006
	ld xbc, 0x1C70011
	lds32 xde, 0
	jp ApPostEvent

Audio_ExternalCallback:
	ld xwa, 0x720006
	ld xbc, 0x1C70011
	lds32 xde, 0
	call ApPostEvent
	ld xwa, 0x720006
	ld xbc, 0x1C70013
	lds32 xde, 0
	jp ApPostEvent
Audio_ExternalCallback_End:

LyricsBoxProc:
	lda xsp, (xsp - 48)
	push xiz
	ld xiz, xde
	ld (xsp + 48), xwa
	cp xbc, 0x1C7000D
	jrl z, LyricsBox_HandleEventD
	cp xbc, 0x1C7000C
	jrl z, LyricsBox_HandleEventC
	cp xbc, 0x1C7000B
	jrl z, LyricsBox_HandleEventB
	cp xbc, 0x1C7000A
	jr z, LyricsBox_HandleEventA
	cp xbc, 0x1C70009
	jr z, LyricsBox_HandleEvent9
	ld xwa, (xsp + 48)
	ld xde, xiz
	call InheritedProc
	jrl LyricsBox_Epilogue

LyricsBox_HandleEvent9:
	call GetTitleNow
	cp xhl, 0x1A00072
	jr z, LyricsBox_MatchedTitle
	call GetTitleNow
	cp xhl, 0x1A00076
	jr nz, LyricsBox_ClearBuffers

LyricsBox_MatchedTitle:
	ld xwa, (xsp + 48)
	ld xbc, 0x1C0000D
	ld xde, xiz
	call SendEvent

LyricsBox_ClearBuffers:
	lda_24 xbc, 0x020cbe
	ld xwa, xbc
	st_dri3b A, 0xE5, 0x40, 0x01

LyricsBox_ClearOuterLoop:
	ld xde, xwa
	lda xhl, (xwa + 64)

LyricsBox_ClearInnerLoop:
	stib_dpi 0xE8, 0x00
	cp xde, xhl
	jr c, LyricsBox_ClearInnerLoop
	lda xwa, (xwa + 64)
	cp xwa, xbc
	jr c, LyricsBox_ClearOuterLoop
	jrl SongEdit_ReturnZero

LyricsBox_HandleEventA:
	ld xwa, (xsp + 48)
	ld xde, xiz
	call InheritedProc
	ld xwa, (xsp + 48)
	call GetViewInstance
	ld (xsp + 12), xhl
	ld xwa, (xsp + 12)
	ld (xsp + 4), xwa
	call GetTitleNow
	cp xhl, 0x1A00072
	jr z, LyricsBox_DrawClientArea
	call GetTitleNow
	cp xhl, 0x1A00076
	jrl nz, SongEdit_ReturnZero

LyricsBox_DrawClientArea:
	lda xbc, (xsp + 40)
	ld xwa, (xsp + 48)
	call GetClientBox
	lda xwa, (xsp + 40)
	incm 2, (xwa)
	incm 4, (xwa + 2)
	decm 1, (xwa + 4)
	decm 2, (xwa + 6)
	ldw (xsp + 8), 0x0
	ld xwa, (xsp + 12)
	cpw (xwa + 38), 0x0
	jrl ule, SongEdit_ReturnZero

LyricsBox_DrawLineLoop:
	lda_24 xix, 0x020e3e
	ld de, (xix + 2)
	ld bc, (xsp + 8)
	extz xbc
	sll xbc, 6
	ld xhl, 0x20CBE
	add xhl, xbc
	cp (xsp + 8), de
	jr nc, LyricsBox_CheckCurrentLine
	push xhl
	pushw 0x2
	pushw 0xDFE
	call Strcpy
	inc 8, xsp
	lda xbc, (xsp + 20)
	lda xwa, (xsp + 40)
	ld de, (xwa)
	ld (xbc), de
	ld de, (xsp + 8)
	mul de, 0x12
	ld hl, (xwa + 2)
	add hl, de
	ld (xbc + 2), hl
	ld xhl, (xsp + 12)
	ld xde, (xhl + 28)
	push xde
	pushm (xhl + 34)
	pushw 0x7
	ld xde, 0x20DFE
	jrl LyricsBox_DrawAndAdvance

LyricsBox_CheckCurrentLine:
	lda_24 xbc, 0x020dfe
	cp de, (xsp + 8)
	jrl nz, LyricsBox_CopyAndDraw
	ld wa, (xix)
	inc 1, wa
	ld (xsp + 10), wa
	pushm (xsp + 10)
	push xhl
	push xbc
	call Strncpy
	lda xsp, (xsp + 10)
	ld wa, (xsp + 10)
	extz xwa
	lda_24 xde, 0x020dfe
	ld xbc, xde
	add xbc, xwa
	ld (xbc), 0x0
	lda xbc, (xsp + 20)
	lda xwa, (xsp + 40)
	ld hl, (xwa)
	ld (xbc), hl
	ld hl, (xsp + 8)
	mul hl, 0x12
	ld ix, (xwa + 2)
	add ix, hl
	ld (xbc + 2), ix
	ld xhl, (xsp + 12)
	ld xhl, (xhl + 28)
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 34)
	pushw 0x7
	call DrawString
	ld bc, (xsp + 10)
	extz xbc
	ld wa, (xsp + 8)
	extz xwa
	sll xwa, 6
	add xwa, xbc
	ld xbc, 0x20CBE
	add xbc, xwa
	push xbc
	pushw 0x2
	pushw 0xDFE
	call Strcpy
	inc 8, xsp
	ld bc, (xsp + 10)
	sll bc, 3
	lda xwa, (xsp + 40)
	ld de, (xwa)
	add de, bc
	lda xbc, (xsp + 20)
	ld (xbc), de
	ld de, (xsp + 8)
	mul de, 0x12
	ld hl, (xwa + 2)
	add hl, de
	ld (xbc + 2), hl
	ld xde, (xsp + 12)
	ld xde, (xde + 28)
	push xde
	ld xde, (xsp + 8)
	pushm (xde + 32)
	pushw 0x7
	ld xde, 0x20DFE
	jr LyricsBox_DrawAndAdvance

LyricsBox_CopyAndDraw:
	push xhl
	push xbc
	call Strcpy
	inc 8, xsp
	lda xbc, (xsp + 20)
	lda xwa, (xsp + 40)
	ld de, (xwa)
	ld (xbc), de
	ld de, (xsp + 8)
	mul de, 0x12
	ld hl, (xwa + 2)
	add hl, de
	ld (xbc + 2), hl
	ld xhl, (xsp + 12)
	ld xde, (xhl + 28)
	push xde
	pushm (xhl + 32)
	pushw 0x7
	ld xde, 0x20DFE

LyricsBox_DrawAndAdvance:
	call DrawString
	incm 1, (xsp + 8)
	ld xwa, (xsp + 12)
	ld bc, (xsp + 8)
	cp bc, (xwa + 38)
	jrl c, LyricsBox_DrawLineLoop
	jrl SongEdit_ReturnZero

LyricsBox_HandleEventB:
	ld xwa, (xsp + 48)
	ld xde, xiz
	call InheritedProc
	ld xwa, (xsp + 48)
	call GetViewInstance
	ld (xsp + 12), xhl
	call GetTitleNow
	cp xhl, 0x1A00072
	jr z, LyricsBox_DrawCurrentLine
	call GetTitleNow
	cp xhl, 0x1A00076
	jrl nz, LyricsBox_UpdateCursors46

LyricsBox_DrawCurrentLine:
	lda xbc, (xsp + 40)
	ld xwa, (xsp + 48)
	call GetClientBox
	lda xwa, (xsp + 40)
	incm 2, (xwa)
	incm 4, (xwa + 2)
	decm 1, (xwa + 4)
	decm 2, (xwa + 6)
	lda_24 xwa, 0x020e46
	ld16_24 xbc, 0x020e4a
	sub bc, (xwa)
	inc 1, bc
	ld (xsp + 10), bc
	pushm (xsp + 10)
	ld bc, (xwa + 2)
	sla bc, 6
	add bc, (xwa)
	lda_24 xwa, 0x020cbe
	st_dri3b W, 0x07, 0xE0, 0xE4
	push xwa
	pushw 0x2
	pushw 0xDFE
	call Strncpy
	lda xsp, (xsp + 10)
	ld wa, (xsp + 10)
	extz xwa
	lda_24 xde, 0x020dfe
	ld xbc, xde
	add xbc, xwa
	ld (xbc), 0x0
	lda xwa, (xsp + 40)
	lda_24 xhl, 0x020e46
	ld bc, (xhl)
	sla bc, 3
	ld ix, bc
	add ix, (xwa)
	lda xbc, (xsp + 20)
	ld (xbc), ix
	ld hl, (xhl + 2)
	muls hl, 0x12
	add hl, (xwa + 2)
	ld (xbc + 2), hl
	ld xix, (xsp + 12)
	ld xhl, (xix + 28)
	push xhl
	pushm (xix + 32)
	pushw 0x7
	call DrawString

LyricsBox_UpdateCursors46:
	ld xbc, 0x20E46
	ld xwa, 0x20E4A
	jrl LyricsBox_StoreCursorPos

LyricsBox_HandleEventC:
	ld xwa, (xsp + 48)
	ld xde, xiz
	call InheritedProc
	ld xwa, (xsp + 48)
	call GetViewInstance
	ld (xsp + 12), xhl
	call GetTitleNow
	cp xhl, 0x1A00072
	jr z, LyricsBox_DrawSelLine
	call GetTitleNow
	cp xhl, 0x1A00076
	jrl nz, LyricsBox_UpdateCursors3E

LyricsBox_DrawSelLine:
	lda xbc, (xsp + 40)
	ld xwa, (xsp + 48)
	call GetClientBox
	lda xwa, (xsp + 40)
	incm 2, (xwa)
	incm 4, (xwa + 2)
	decm 1, (xwa + 4)
	decm 2, (xwa + 6)
	lda_24 xwa, 0x020e3e
	ld16_24 xbc, 0x020e42
	sub bc, (xwa)
	ld (xsp + 10), bc
	pushm (xsp + 10)
	ld bc, (xwa + 2)
	sla bc, 6
	add bc, (xwa)
	lda_24 xwa, 0x020cbe
	st_dri3b W, 0x07, 0xE0, 0xE4
	push xwa
	pushw 0x2
	pushw 0xDFE
	call Strncpy
	lda xsp, (xsp + 10)
	ld wa, (xsp + 10)
	extz xwa
	lda_24 xde, 0x020dfe
	ld xbc, xde
	add xbc, xwa
	ld (xbc), 0x0
	lda xwa, (xsp + 40)
	lda_24 xhl, 0x020e3e
	ld bc, (xhl)
	sla bc, 3
	ld ix, bc
	add ix, (xwa)
	lda xbc, (xsp + 20)
	ld (xbc), ix
	ld hl, (xhl + 2)
	muls hl, 0x12
	add hl, (xwa + 2)
	ld (xbc + 2), hl
	ld xix, (xsp + 12)
	ld xhl, (xix + 28)
	push xhl
	pushm (xix + 34)
	pushw 0x7
	call DrawString

LyricsBox_UpdateCursors3E:
	ld xbc, 0x20E3E
	ld xwa, 0x20E42

LyricsBox_StoreCursorPos:
	ld wa, (xwa)
	ld (xbc), wa
	jr SongEdit_ReturnZero

LyricsBox_HandleEventD:
	ld xwa, (xsp + 48)
	ld xde, xiz
	call InheritedProc
	call GetTitleNow
	cp xhl, 0x1A00072
	jr z, LyricsBox_ScrollAndDraw
	call GetTitleNow
	cp xhl, 0x1A00076
	jr nz, SongEdit_ReturnZero

LyricsBox_ScrollAndDraw:
	lda xbc, (xsp + 40)
	ld xwa, (xsp + 48)
	call GetClientBox
	lda xiz, (xsp + 40)
	incm 2, (xiz)
	lda xhl, (xiz + 2)
	incm 4, (xhl)
	decm 1, (xiz + 4)
	decm 2, (xiz + 6)
	lda xiy, (xsp + 40)
	lda xix, (xsp + 32)
	lds bc, 4
	ldirw
	lda xwa, (xsp + 32)
	addmi16 (xwa + 2), 0x12
	lda xde, (xsp + 16)
	ld bc, (xiz)
	ld (xde), bc
	ld bc, (xhl)
	ld (xde + 2), bc
	lda xiy, (xsp + 40)
	lda xix, (xsp + 24)
	lds bc, 4
	ldirw
	lda xhl, (xsp + 24)
	ld bc, (xhl + 6)
	sub bc, 0x12
	ld (xhl + 2), bc
	ld xbc, xde
	call MovePixels
	lda xwa, (xsp + 24)
	lds bc, 7
	call DrawBox

SongEdit_ReturnZero:
	lds32 xhl, 0

LyricsBox_Epilogue:
	pop xiz
	lda xsp, (xsp + 48)
	ret

SongEdit_CheckBounds:
	dec 2, xsp
	ld (xsp), a
	lda_24 xix, 0x020e4a
	ld a, (xsp)
	extz wa
	add wa, (xix)
	lda_24 xbc, 0x020cbe
	lda xde, (xix + 2)
	cp wa, 0x22
	jr ge, SongEdit_OverflowCheck
	ld a, (xsp)
	inc 1, a
	extz wa
	pushw wa
	pushw 0x2
	pushw 0xE4E
	ld wa, (xde)
	sla wa, 6
	add wa, (xix)
	exts xwa
	add xwa, xbc
	push xwa
	call Strncpy
	lda xsp, (xsp + 10)
	lda_24 xbc, 0x020e4a
	ld a, (xsp)
	extz wa
	add wa, (xbc)
	ld (xbc), wa
	sti8_24 0x020e4e, 0x00
	ld xwa, 0x6F0027
	ld xbc, 0x1C7000B
	lds32 xde, 0
	jrl SongEdit_SendAndReturnOK

SongEdit_OverflowCheck:
	ld xhl, xde
	ld wa, (xde)
	cps wa, 4
	jrl ge, SongEdit_ReturnOverflow
	sla wa, 6
	add wa, (xix)
	stib_dri 0x07, 0xE4, 0xE0, 0x0D
	ld wa, (xix)
	inc 1, wa
	ld (xix), wa
	ld wa, (xhl)
	sla wa, 6
	add wa, (xix)
	stib_dri 0x07, 0xE4, 0xE0, 0x00
	ld wa, (xix)
	inc 1, wa
	ld (xix), wa
	ld xwa, 0x6F0027
	ld xbc, 0x1C7000B
	lds32 xde, 0
	call SendEvent
	lda_24 xde, 0x020e46
	lda xbc, (xde + 2)
	ld wa, (xbc)
	inc 1, wa
	ld (xbc), wa
	ldw (xde), 0x0
	lda_24 xde, 0x020e4a
	lda xbc, (xde + 2)
	ld wa, (xbc)
	inc 1, wa
	ld (xbc), wa
	ldw (xde), 0x0
	ld a, (xsp)
	inc 1, a
	extz wa
	pushw wa
	pushw 0x2
	pushw 0xE4E
	ld bc, (xbc)
	sla bc, 6
	add bc, (xde)
	lda_24 xwa, 0x020cbe
	st_dri3b W, 0x07, 0xE0, 0xE4
	push xwa
	call Strncpy
	lda xsp, (xsp + 10)
	lda_24 xbc, 0x020e4a
	ld a, (xsp)
	extz wa
	add wa, (xbc)
	ld (xbc), wa
	sti8_24 0x020e4e, 0x00
	ld xwa, 0x6F0027
	ld xbc, 0x1C7000B
	lds32 xde, 0

SongEdit_SendAndReturnOK:
	call SendEvent
	ldb l, 0x0
	jr SongEdit_CheckBounds_Epilogue

SongEdit_ReturnOverflow:
	ldb l, 0xFF

SongEdit_CheckBounds_Epilogue:
	inc 2, xsp
	ret

LyricsTrack_ReadAndParse:
	lda_24 xwa, 0x020e4e
	call SeqFile_ReadTrackData
	pushw 0x2
	pushw 0xE4E
	call Strlen
	inc 4, xsp
	cp hl, 0x22
	jr c, LyricsTrack_CheckEmpty
	sti8_24 0x020e6f, 0x00

LyricsTrack_CheckEmpty:
	lda_24 xwa, 0x020e4e
	cp (xwa), 0x0
	ret z
	push xwa
	call Strlen
	inc 4, xsp
	dec 1, hl
	extz xhl
	lda_24 xwa, 0x020e4e
	ld xde, xwa
	add xde, xhl
	ld c, (xde)
	push xwa
	cp c, 0xA
	jr z, LyricsTrack_HandleNewline
	cp c, 0xD
	jrl nz, LyricsTrack_HandleNormalChar

LyricsTrack_HandleNewline:
	call Strlen
	inc 4, xsp
	cps l, 1
	jr z, LyricsTrack_HandleSingleChar
	pushw 0x2
	pushw 0xE4E
	call Strlen
	inc 4, xsp
	extz hl
	ld wa, hl
	jr LyricsTrack_JmpCheckBounds

LyricsTrack_HandleSingleChar:
	lda_24 xde, 0x020e4a
	lda xbc, (xde + 2)
	ld wa, (xbc)
	cps wa, 4
	ret ge
	sla wa, 6
	add wa, (xde)
	lda_24 xhl, 0x020cbe
	stib_dri 0x07, 0xEC, 0xE0, 0x0D
	ld wa, (xde)
	inc 1, wa
	ld (xde), wa
	ld wa, (xbc)
	sla wa, 6
	add wa, (xde)
	stib_dri 0x07, 0xEC, 0xE0, 0x00
	ld wa, (xde)
	inc 1, wa
	ld (xde), wa
	ld xwa, 0x6F0027
	ld xbc, 0x1C7000B
	lds32 xde, 0
	call SendEvent
	lda_24 xde, 0x020e46
	lda xbc, (xde + 2)
	ld wa, (xbc)
	inc 1, wa
	ld (xbc), wa
	ldw (xde), 0x0
	lda_24 xde, 0x020e4a
	lda xbc, (xde + 2)
	ld wa, (xbc)
	inc 1, wa
	ld (xbc), wa
	ldw (xde), 0x0
	sti8_24 0x020e4e, 0x00
	ret

LyricsTrack_HandleNormalChar:
	call Strlen
	inc 4, xsp
	extz hl
	ld wa, hl

LyricsTrack_JmpCheckBounds:
	jrl SongEdit_CheckBounds

LyricsTrack_ResetAllBuffers:
	pushw iz
	lds iz, 0

LyricsTrack_ResetBufferLoop:
	pushw 0x40
	ld bc, iz
	sla bc, 6
	ld de, bc
	add de, 0x40
	lda_24 xwa, 0x020cbe
	exts xde
	add xde, xwa
	push xde
	st_dri3b W, 0x07, 0xE0, 0xE4
	push xwa
	call Mem_Copy
	lda xsp, (xsp + 10)
	ld bc, iz
	sla bc, 6
	lda_24 xwa, 0x020cfe
	exts xbc
	add xbc, xwa
	ld xwa, xbc
	lda xbc, (xbc + 64)

LyricsTrack_ZeroFillLoop:
	stib_dpi 0xE0, 0x00
	cp xwa, xbc
	jr c, LyricsTrack_ZeroFillLoop
	inc 1, iz
	ld wa, iz
	inc 1, wa
	cps wa, 4
	jr le, LyricsTrack_ResetBufferLoop
	lda_24 xwa, 0x020e3e
	ldw (xwa + 2), 0x2
	ldw (xwa), 0x0
	lda_24 xwa, 0x020e42
	ldw (xwa + 2), 0x2
	ldw (xwa), 0x0
	lda_24 xbc, 0x020e48
	ld wa, (xbc)
	dec 1, wa
	ld (xbc), wa
	lda_24 xbc, 0x020e4c
	ld wa, (xbc)
	dec 1, wa
	ld (xbc), wa
	ld xwa, 0x6F0027
	ld xbc, 0x1C7000D
	lds32 xde, 0
	call SendEvent
	ld xwa, 0x147001C
	ld xbc, 0x1E70018
	lds32 xde, 0
	call MainFuncCall
	popw iz
	ret

LyricsFile_ValidateAndInsert:
	pushw iz
	ld xwa, 0x20F4E
	call SeqFile_ValidateAndStore
	pushw 0x2
	pushw 0xF4E
	call Strlen
	inc 4, xsp
	cp hl, 0x22
	jr c, LyricsFile_CheckFirstByte
	sti8_24 0x020f6f, 0x00

LyricsFile_CheckFirstByte:
	ld8_24 e, 0x020f4e
	cps e, 0
	jrl z, LyricsBox_PopIzRet
	lda_24 xhl, 0x020cbe
	cp e, 0xD
	jr nz, LyricsFile_CheckLinefeed
	lda_24 xbc, 0x020e42
	ld de, (xbc + 2)
	sla de, 6
	add de, (xbc)
	cp_srib_im 0x07, 0xEC, 0xE8, 0x0D
	jrl z, LyricsFile_ResetBuffers
	jrl LyricsBox_PopIzRet

LyricsFile_CheckLinefeed:
	lda_24 xbc, 0x020e42
	ld wa, (xbc + 2)
	sla wa, 6
	cp e, 0xA
	jr nz, LyricsFile_InsertNormalChar
	add wa, (xbc)
	cp_srib_im 0x07, 0xEC, 0xE0, 0x0D
	jr z, LyricsFile_ResetBuffers
	jr LyricsBox_PopIzRet

LyricsFile_InsertNormalChar:
	add wa, (xbc)
	cp_srib_im 0x07, 0xEC, 0xE0, 0x0D
	call_24 z, 0xF2B081
	pushw 0x2
	pushw 0xF4E
	call Strlen
	ld iz, hl
	pushw iz
	pushw 0x2
	pushw 0xF4E
	lda_24 xwa, 0x020e42
	ld bc, (xwa + 2)
	sla bc, 6
	add bc, (xwa)
	lda_24 xwa, 0x020cbe
	st_dri3b W, 0x07, 0xE0, 0xE4
	push xwa
	call Strncpy
	lda xsp, (xsp + 14)
	lda_24 xwa, 0x020e42
	ld bc, iz
	add bc, (xwa)
	ld (xwa), bc
	ld xwa, 0x6F0027
	ld xbc, 0x1C7000C
	lds32 xde, 0
	call SendEvent
	call UpdateScreen
	lda_24 xwa, 0x020e42
	ld bc, (xwa + 2)
	sla bc, 6
	add bc, (xwa)
	lda_24 xwa, 0x020cbe
	cp_srib_im 0x07, 0xE0, 0xE4, 0x0D
	jr nz, LyricsBox_PopIzRet

LyricsFile_ResetBuffers:
	calr LyricsTrack_ResetAllBuffers

LyricsBox_PopIzRet:
	popw iz
	ret
LyricsBoxFuncProc_Boundary:

LyricsBoxFuncProc:
	push xiz
	ld xiz, xwa
	cp xbc, 0x1C70013
	jrl z, LyricsBoxFunc_ValidateFile
	lda_24 xwa, 0x020e4e
	cp xbc, 0x1C70012
	jrl z, LyricsBoxFunc_HandleInput
	cp xbc, 0x1C70011
	jr z, LyricsBoxFunc_SendEvent12
	cp xbc, 0x1C70010
	jr z, LyricsBoxFunc_ResetCursors
	cp xbc, 0x1E0003A
	jr z, LyricsBoxFunc_CopyString
	cp xbc, 0x1C0000D
	jrl nz, LyricsBoxFunc_InheritedProc
	ld xwa, xiz
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1C0000F
	lds32 xde, 0
	jr LyricsBoxFunc_SendAndReturn

LyricsBoxFunc_CopyString:
	pushw 0xE2
	pushw 0x61FA
	push xde
	call Strcpy
	inc 8, xsp
	jrl SongName_ReturnZeroJmp

LyricsBoxFunc_ResetCursors:
	lda_24 xbc, 0x020e3e
	ldw (xbc), 0x0
	ldw (xbc + 2), 0x2
	lda_24 xbc, 0x020e42
	ldw (xbc), 0x0
	ldw (xbc + 2), 0x2
	lda_24 xbc, 0x020e46
	ldw (xbc), 0x0
	ldw (xbc + 2), 0x2
	lda_24 xbc, 0x020e4a
	ldw (xbc), 0x0
	ldw (xbc + 2), 0x2
	ld (xwa), 0x0
	sti8_24 0x020f4e, 0x00
	jrl SongName_ReturnZeroJmp

LyricsBoxFunc_SendEvent12:
	ld xwa, 0x720006
	ld xbc, 0x1C70012
	lds32 xde, 0

LyricsBoxFunc_SendAndReturn:
	call SendEvent
	jrl SongName_ReturnZeroJmp

LyricsBoxFunc_HandleInput:
	ld xbc, xwa
	cp (xwa), 0x0
	jrl z, LyricsBoxFunc_ReadTrack
	push xbc
	call Strlen
	inc 4, xsp
	dec 1, hl
	extz xhl
	lda_24 xwa, 0x020e4e
	ld xde, xwa
	add xde, xhl
	ld c, (xde)
	push xwa
	cp c, 0xA
	jr z, LyricsBoxFunc_HandleNewline
	cp c, 0xD
	jrl nz, LyricsBoxFunc_HandleNormalChar

LyricsBoxFunc_HandleNewline:
	call Strlen
	inc 4, xsp
	cps l, 1
	jr z, LyricsBoxFunc_HandleSingleChar
	pushw 0x2
	pushw 0xE4E
	call Strlen
	inc 4, xsp
	extz hl
	ld wa, hl
	calr SongEdit_CheckBounds
	cp l, 0xFF
	jrl z, SongName_ReturnZeroJmp
	ld xwa, 0x6F0027
	ld xbc, 0x1C7000B
	lds32 xde, 0
	jrl LyricsBoxFunc_SendEventB

LyricsBoxFunc_HandleSingleChar:
	lda_24 xde, 0x020e4a
	lda xbc, (xde + 2)
	ld wa, (xbc)
	cps wa, 4
	jrl ge, SongName_ReturnZeroJmp
	sla wa, 6
	add wa, (xde)
	lda_24 xhl, 0x020cbe
	stib_dri 0x07, 0xEC, 0xE0, 0x0D
	ld wa, (xde)
	inc 1, wa
	ld (xde), wa
	ld wa, (xbc)
	sla wa, 6
	add wa, (xde)
	stib_dri 0x07, 0xEC, 0xE0, 0x00
	ld wa, (xde)
	inc 1, wa
	ld (xde), wa
	ld xwa, 0x6F0027
	ld xbc, 0x1C7000B
	lds32 xde, 0
	call SendEvent
	lda_24 xde, 0x020e46
	lda xbc, (xde + 2)
	ld wa, (xbc)
	inc 1, wa
	ld (xbc), wa
	ldw (xde), 0x0
	lda_24 xde, 0x020e4a
	lda xbc, (xde + 2)
	ld wa, (xbc)
	inc 1, wa
	ld (xbc), wa
	ldw (xde), 0x0
	sti8_24 0x020e4e, 0x00
	jr LyricsBoxFunc_ReadTrack

LyricsBoxFunc_HandleNormalChar:
	call Strlen
	inc 4, xsp
	extz hl
	ld wa, hl
	calr SongEdit_CheckBounds
	cp l, 0xFF
	jr z, SongName_ReturnZeroJmp
	ld xwa, 0x6F0027
	ld xbc, 0x1C7000B
	lds32 xde, 0

LyricsBoxFunc_SendEventB:
	call SendEvent

LyricsBoxFunc_ReadTrack:
	lds wa, 0
	calr LyricsTrack_ReadAndParse
	jr SongName_ReturnZeroJmp

LyricsBoxFunc_ValidateFile:
	calr LyricsFile_ValidateAndInsert

SongName_ReturnZeroJmp:
	lds32 xhl, 0
	jr LyricsBoxFunc_Epilogue

LyricsBoxFunc_InheritedProc:
	ld xwa, xiz
	call InheritedProc

LyricsBoxFunc_Epilogue:
	pop xiz
	ret
LyricsBoxFunc_End:

SongNameBoxProc:
	lda xsp, (xsp - 24)
	push xiz
	ld (xsp + 20), xde
	ld xiz, xbc
	ld (xsp + 24), xwa
	cp xiz, 0x1C7000F
	jr z, SongNameBox_HandleEventF
	cp xiz, 0x1C70009
	jr z, SongNameBox_HandleEvent9
	cp xiz, 0x1C0000C
	jr z, SongNameBox_HandleFocusGained
	cp xiz, 0x1C0000B
	jr z, SongNameBox_HandleFocusGained
	cp xiz, 0x1C00002
	jr z, SongNameBox_HandleSize
	cp xiz, 0x1C00001
	jrl nz, SongNameBox_DefaultHandler
	ld xwa, (xsp + 24)
	ld xbc, xiz
	ld xde, (xsp + 20)
	jr SongNameBox_InheritAndDraw

SongNameBox_HandleSize:
	ld xwa, (xsp + 24)
	ld xbc, xiz
	ld xde, (xsp + 20)

SongNameBox_InheritAndDraw:
	call InheritedProc
	jrl DrawStringCenter_RetZero2

SongNameBox_HandleFocusGained:
	ld xwa, (xsp + 24)
	ld xbc, xiz
	ld xde, (xsp + 20)
	call InheritedProc
	ld xwa, 0x147001D
	ld xbc, 0x1E70019
	lds32 xde, 0
	call MainFuncCall
	jr DrawStringCenter_RetZero2

SongNameBox_HandleEvent9:
	ld xwa, (xsp + 24)
	ld xbc, 0x1C0000D
	ld xde, (xsp + 20)
	call SendEvent
	jr DrawStringCenter_RetZero2

SongNameBox_HandleEventF:
	ld xwa, (xsp + 24)
	ld xbc, 0x1C0000D
	ld xde, (xsp + 20)
	call SendEvent
	ld xwa, (xsp + 24)
	ld xbc, xiz
	ld xde, (xsp + 20)
	call InheritedProc
	ld xwa, (xsp + 24)
	call GetViewInstance
	ld (xsp + 4), xhl
	lda xbc, (xsp + 12)
	ld xwa, (xsp + 24)
	call GetClientBox
	lda xwa, (xsp + 12)
	lda xbc, (xsp + 8)
	call GetBoxCenter
	lda xwa, (xsp + 12)
	lda xbc, (xsp + 8)
	ld xhl, (xsp + 4)
	ld xde, (xhl + 28)
	push xde
	pushm (xhl + 32)
	pushw 0xF7
	ld xde, 0x2104E
	call DrawStringCentered

DrawStringCenter_RetZero2:
	lds32 xhl, 0
	jr SongNameBox_Epilogue

SongNameBox_DefaultHandler:
	ld xwa, (xsp + 24)
	ld xbc, xiz
	ld xde, (xsp + 20)
	call InheritedProc

SongNameBox_Epilogue:
	pop xiz
	lda xsp, (xsp + 24)
	ret
SongNameBox_End:

ComporserNameBoxProc:
	lda xsp, (xsp - 24)
	push xiz
	ld (xsp + 20), xde
	ld xiz, xbc
	ld (xsp + 24), xwa
	cp xiz, 0x1C7000E
	jr z, ComposerBox_HandleEventE
	cp xiz, 0x1C70009
	jr z, ComposerBox_HandleEvent9
	cp xiz, 0x1C0000C
	jr z, SongNameBox2_HandleFocusGained
	cp xiz, 0x1C0000B
	jr z, SongNameBox2_HandleFocusGained
	cp xiz, 0x1C00002
	jr z, ComposerBox_HandleSize
	cp xiz, 0x1C00001
	jrl nz, ComposerBox_DefaultHandler
	ld xwa, (xsp + 24)
	ld xbc, xiz
	ld xde, (xsp + 20)
	jr ComposerBox_InheritAndDraw

ComposerBox_HandleSize:
	ld xwa, (xsp + 24)
	ld xbc, xiz
	ld xde, (xsp + 20)

ComposerBox_InheritAndDraw:
	call InheritedProc
	jrl DrawStringCentered_RetZero

SongNameBox2_HandleFocusGained:
	ld xwa, (xsp + 24)
	ld xbc, xiz
	ld xde, (xsp + 20)
	call InheritedProc
	ld xwa, 0x147001D
	ld xbc, 0x1E7001A
	lds32 xde, 0
	call MainFuncCall
	jr DrawStringCentered_RetZero

ComposerBox_HandleEvent9:
	ld xwa, (xsp + 24)
	ld xbc, 0x1C0000D
	ld xde, (xsp + 20)
	call SendEvent
	jr DrawStringCentered_RetZero

ComposerBox_HandleEventE:
	ld xwa, (xsp + 24)
	ld xbc, 0x1C0000D
	ld xde, (xsp + 20)
	call SendEvent
	ld xwa, (xsp + 24)
	ld xbc, xiz
	ld xde, (xsp + 20)
	call InheritedProc
	ld xwa, (xsp + 24)
	call GetViewInstance
	ld (xsp + 4), xhl
	lda xbc, (xsp + 12)
	ld xwa, (xsp + 24)
	call GetClientBox
	lda xwa, (xsp + 12)
	lda xbc, (xsp + 8)
	call GetBoxCenter
	lda xwa, (xsp + 12)
	lda xbc, (xsp + 8)
	ld xhl, (xsp + 4)
	ld xde, (xhl + 28)
	push xde
	pushm (xhl + 32)
	pushw 0xF7
	ld xde, 0x21064
	call DrawStringCentered

DrawStringCentered_RetZero:
	lds32 xhl, 0
	jr ComposerBox_Epilogue

ComposerBox_DefaultHandler:
	ld xwa, (xsp + 24)
	ld xbc, xiz
	ld xde, (xsp + 20)
	call InheritedProc

ComposerBox_Epilogue:
	pop xiz
	lda xsp, (xsp + 24)
	ret
ComposerBox_End:

MeasureBoxProc:
	lda xsp, (xsp - 62)
	push xiz
	ld (xsp + 58), xde
	ld xiz, xbc
	ld (xsp + 62), xwa
	cp xiz, 0x1C0000F
	jr z, MeasureBox_HandleEventF
	cp xiz, 0x1C0000B
	jr z, MeasureBox_HandleFocusGained
	ld xwa, (xsp + 62)
	ld xbc, xiz
	ld xde, (xsp + 58)
	call InheritedProc
	jrl MeasureBox_Epilogue

MeasureBox_HandleFocusGained:
	ld xwa, (xsp + 62)
	ld xbc, xiz
	ld xde, (xsp + 58)
	call InheritedProc
	ld xde, (xsp + 62)
	ld xwa, 0x147001E
	ld xbc, xiz
	call MainPostEvent
	jrl MeasureBox_ReturnZero

MeasureBox_HandleEventF:
	ld xwa, (xsp + 62)
	ld xbc, xiz
	ld xde, (xsp + 58)
	call InheritedProc
	ld xwa, (xsp + 62)
	call GetViewInstance
	ld (xsp + 4), xhl
	lda xhl, (xsp + 50)
	ldw (xhl), 0x6C
	lda xbc, (xhl + 2)
	ldw (xbc), 0x56
	lda xwa, (xhl + 4)
	ldw (xwa), 0xD8
	lda xde, (xhl + 6)
	ldw (xde), 0x69
	ld wa, (xwa)
	sub wa, (xhl)
	exts xwa
	divs wa, 0x2
	ld ix, (xhl)
	add ix, wa
	lda xhl, (xsp + 46)
	ld (xhl), ix
	ld bc, (xbc)
	ld wa, (xde)
	sub wa, bc
	exts xwa
	divs wa, 0x2
	add bc, wa
	ld (xhl + 2), bc
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 26)
	ld xbc, 0x1E00045
	ld xde, (xsp + 58)
	call ApFuncCall
	lda xde, (xsp + 8)
	ld (xde), xhl
	lda xhl, (xsp + 30)
	ld xwa, xhl
	lda xbc, (xhl + 16)

MeasureBox_ZeroFillLoop:
	stib_dpi 0xE0, 0x00
	cp xwa, xbc
	jr c, MeasureBox_ZeroFillLoop
	ld (xde + 18), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 26)
	ld xbc, 0x1E70016
	call ApFuncCall
	lda xwa, (xsp + 50)
	lda xbc, (xsp + 46)
	lda xde, (xsp + 30)
	lds32 xhl, 0
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify

MeasureBox_ReturnZero:
	lds32 xhl, 0

MeasureBox_Epilogue:
	pop xiz
	lda xsp, (xsp + 62)
	ret

MeasureBoxFunc:
	push xiz
	ld xiz, xwa
	cp xbc, 0x1E00045
	jr z, MeasureBoxFunc_LoadAddr
	cp xbc, 0x1E70016
	jr z, MeasureBoxFunc_DrawMeasure
	lds32 xhl, 0
	jr MeasureBoxFunc_Epilogue

MeasureBoxFunc_DrawMeasure:
	push_sd16w 0x68, 0x26
	pushw 0xE2
	pushw 0x6200
	ld xwa, (xde + 18)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 10)
	ld xhl, xiz
	jr MeasureBoxFunc_Epilogue

MeasureBoxFunc_LoadAddr:
	ldada xhl, 9832

MeasureBoxFunc_Epilogue:
	pop xiz
	ret
MeasureBoxFunc_End:

AcDiskFileNameBoxProc:
	st_dri3b L, 0xFD, 0x00, 0xFF
	push xiz
	ld xiz, xwa
	cp xbc, 0x1C70001
	jr z, AcDiskFileName_HandleEventF
	cp xbc, 0x1C0000C
	jr z, AcDiskFileName_HandleFocusGained
	cp xbc, 0x1C0000B
	jr z, AcDiskFileName_HandleFocusGained
	cp xbc, 0x1C00002
	jr z, AcDiskFileName_HandleEvent1
	cp xbc, 0x1C00001
	jr z, AcDiskFileName_HandleEvent2
	ld xwa, xiz
	call InheritedProc
	jr AcDiskFileName_Epilogue

AcDiskFileName_HandleEvent2:
	ld xwa, xiz
	jr AcDiskFileName_CallInherited

AcDiskFileName_HandleEvent1:
	ld xwa, xiz

AcDiskFileName_CallInherited:
	call InheritedProc
	jr AcDiskFileName_ReturnZero

AcDiskFileName_HandleFocusGained:
	ld xwa, xiz
	call InheritedProc
	ld xwa, 0x147001D
	ld xbc, 0x1E7000E
	lds32 xde, 0
	call MainFuncCall
	jr AcDiskFileName_ReturnZero

AcDiskFileName_HandleEventF:
	ld xwa, xiz
	call InheritedProc
	pushw 0xE2
	pushw 0x620E
	lda xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	lda xde, (xsp + 4)
	ld xwa, xiz
	ld xbc, 0x1C0000F
	call SendEvent
	pushw 0x0
	pushw 0x1C66
	lda xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	lda xde, (xsp + 4)
	ld xwa, xiz
	ld xbc, 0x1C0000F
	call SendEvent

AcDiskFileName_ReturnZero:
	lds32 xhl, 0

AcDiskFileName_Epilogue:
	pop xiz
	st_dri3b L, 0xFD, 0x00, 0x01
	ret
AcDiskFileName_End:

AcSmfFileNameBoxProc:
	st_dri3b L, 0xFD, 0x00, 0xFF
	push xiz
	ld xiz, xwa
	cp xbc, 0x1C70002
	jr z, AcSmfFileName_HandleEventF
	cp xbc, 0x1C0000C
	jr z, AcSmfFileName_HandleFocusGained
	cp xbc, 0x1C0000B
	jr z, AcSmfFileName_HandleFocusGained
	cp xbc, 0x1C00002
	jr z, AcSmfFileName_HandleEvent1
	cp xbc, 0x1C00001
	jr z, AcSmfFileName_HandleEvent2
	ld xwa, xiz
	call InheritedProc
	jr AcSmfFileName_Epilogue

AcSmfFileName_HandleEvent2:
	ld xwa, xiz
	jr AcSmfFileName_CallInherited

AcSmfFileName_HandleEvent1:
	ld xwa, xiz

AcSmfFileName_CallInherited:
	call InheritedProc
	jr AcSmfFileName_ReturnZero

AcSmfFileName_HandleFocusGained:
	ld xwa, xiz
	call InheritedProc
	ld xwa, 0x147001D
	ld xbc, 0x1E7000F
	lds32 xde, 0
	call MainFuncCall
	jr AcSmfFileName_ReturnZero

AcSmfFileName_HandleEventF:
	ld xwa, xiz
	call InheritedProc
	pushw 0xE2
	pushw 0x6228
	lda xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	lda xde, (xsp + 4)
	ld xwa, xiz
	ld xbc, 0x1C0000F
	call SendEvent
	pushw 0x0
	pushw 0x1C74
	lda xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	lda xde, (xsp + 4)
	ld xwa, xiz
	ld xbc, 0x1C0000F
	call SendEvent

AcSmfFileName_ReturnZero:
	lds32 xhl, 0

AcSmfFileName_Epilogue:
	pop xiz
	st_dri3b L, 0xFD, 0x00, 0x01
	ret
AcSmfFileName_End:

AcSmfSongNameBoxProc:
	st_dri3b L, 0xFD, 0x00, 0xFF
	push xiz
	ld xiz, xwa
	cp xbc, 0x1C70003
	jr z, AcSmfSongName_HandleEventF
	cp xbc, 0x1C0000C
	jr z, AcSmfSongName_HandleFocusGained
	cp xbc, 0x1C0000B
	jr z, AcSmfSongName_HandleFocusGained
	cp xbc, 0x1C00002
	jr z, AcSmfSongName_HandleEvent1
	cp xbc, 0x1C00001
	jr z, AcSmfSongName_HandleEvent2
	ld xwa, xiz
	call InheritedProc
	jr AcSmfSongName_Epilogue

AcSmfSongName_HandleEvent2:
	ld xwa, xiz
	jr AcSmfSongName_CallInherited

AcSmfSongName_HandleEvent1:
	ld xwa, xiz

AcSmfSongName_CallInherited:
	call InheritedProc
	jr AcSmfSongName_ReturnZero

AcSmfSongName_HandleFocusGained:
	ld xwa, xiz
	call InheritedProc
	ld xwa, 0x147001D
	ld xbc, 0x1E70010
	lds32 xde, 0
	call MainFuncCall
	jr AcSmfSongName_ReturnZero

AcSmfSongName_HandleEventF:
	ld xwa, xiz
	call InheritedProc
	pushw 0xE2
	pushw 0x6242
	lda xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	lda xde, (xsp + 4)
	ld xwa, xiz
	ld xbc, 0x1C0000F
	call SendEvent
	pushw 0x0
	pushw 0x1C88
	lda xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	lda xde, (xsp + 4)
	ld xwa, xiz
	ld xbc, 0x1C0000F
	call SendEvent

AcSmfSongName_ReturnZero:
	lds32 xhl, 0

AcSmfSongName_Epilogue:
	pop xiz
	st_dri3b L, 0xFD, 0x00, 0x01
	ret
AcSmfSongName_End:

AcDocSongNameBoxProc:
	st_dri3b L, 0xFD, 0x00, 0xFF
	push xiz
	ld xiz, xwa
	cp xbc, 0x1C70005
	jr z, AcDocSongName_HandleEventF
	cp xbc, 0x1C0000C
	jr z, AcDocSongName_HandleFocusGained
	cp xbc, 0x1C0000B
	jr z, AcDocSongName_HandleFocusGained
	cp xbc, 0x1C00002
	jr z, AcDocSongName_HandleEvent1
	cp xbc, 0x1C00001
	jr z, AcDocSongName_HandleEvent2
	ld xwa, xiz
	call InheritedProc
	jr AcDocSongName_Epilogue

AcDocSongName_HandleEvent2:
	ld xwa, xiz
	jr AcDocSongName_CallInherited

AcDocSongName_HandleEvent1:
	ld xwa, xiz

AcDocSongName_CallInherited:
	call InheritedProc
	jr AcDocSongName_ReturnZero

AcDocSongName_HandleFocusGained:
	ld xwa, xiz
	call InheritedProc
	ld xwa, 0x147001D
	ld xbc, 0x1E70012
	lds32 xde, 0
	call MainFuncCall
	jr AcDocSongName_ReturnZero

AcDocSongName_HandleEventF:
	ld xwa, xiz
	call InheritedProc
	pushw 0xE2
	pushw 0x625C
	lda xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	lda xde, (xsp + 4)
	ld xwa, xiz
	ld xbc, 0x1C0000F
	call SendEvent
	pushw 0x0
	pushw 0x1C9E
	lda xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	lda xde, (xsp + 4)
	ld xwa, xiz
	ld xbc, 0x1C0000F
	call SendEvent

AcDocSongName_ReturnZero:
	lds32 xhl, 0

AcDocSongName_Epilogue:
	pop xiz
	st_dri3b L, 0xFD, 0x00, 0x01
	ret
AcDocSongName_End:

AcDocFileNoBoxProc:
	st_dri3b L, 0xFD, 0x00, 0xFF
	push xiz
	ld xiz, xwa
	cp xbc, 0x1C70006
	jr z, AcDocFileNo_HandleEventF
	cp xbc, 0x1C0000C
	jr z, AcDocFileNo_HandleFocusGained
	cp xbc, 0x1C0000B
	jr z, AcDocFileNo_HandleFocusGained
	cp xbc, 0x1C00002
	jr z, AcDocFileNo_HandleEvent1
	cp xbc, 0x1C00001
	jr z, AcDocFileNo_HandleEvent2
	ld xwa, xiz
	call InheritedProc
	jr AcDocFileNo_Epilogue

AcDocFileNo_HandleEvent2:
	ld xwa, xiz
	jr AcDocFileNo_CallInherited

AcDocFileNo_HandleEvent1:
	ld xwa, xiz

AcDocFileNo_CallInherited:
	call InheritedProc
	jr AcDocFileNo_ReturnZero

AcDocFileNo_HandleFocusGained:
	ld xwa, xiz
	call InheritedProc
	ld xwa, 0x147001D
	ld xbc, 0x1E70013
	lds32 xde, 0
	call MainFuncCall
	jr AcDocFileNo_ReturnZero

AcDocFileNo_HandleEventF:
	ld xwa, xiz
	call InheritedProc
	pushw 0xE2
	pushw 0x6276
	lda xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	lda xde, (xsp + 4)
	ld xwa, xiz
	ld xbc, 0x1C0000F
	call SendEvent
	pushw 0x0
	pushw 0x1CC2
	lda xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	lda xde, (xsp + 4)
	ld xwa, xiz
	ld xbc, 0x1C0000F
	call SendEvent

AcDocFileNo_ReturnZero:
	lds32 xhl, 0

AcDocFileNo_Epilogue:
	pop xiz
	st_dri3b L, 0xFD, 0x00, 0x01
	ret
AcDocFileNo_End:

AcPDSongNameBoxProc:
	st_dri3b L, 0xFD, 0x00, 0xFF
	push xiz
	ld xiz, xwa
	cp xbc, 0x1C70007
	jr z, AcPDSongName_HandleEventF
	cp xbc, 0x1C0000C
	jr z, AcPDSongName_HandleFocusGained
	cp xbc, 0x1C0000B
	jr z, AcPDSongName_HandleFocusGained
	cp xbc, 0x1C00002
	jr z, AcPDSongName_HandleEvent1
	cp xbc, 0x1C00001
	jr z, AcPDSongName_HandleEvent2
	ld xwa, xiz
	call InheritedProc
	jr AcPDSongName_Epilogue

AcPDSongName_HandleEvent2:
	ld xwa, xiz
	jr AcPDSongName_CallInherited

AcPDSongName_HandleEvent1:
	ld xwa, xiz

AcPDSongName_CallInherited:
	call InheritedProc
	jr AcPDSongName_ReturnZero

AcPDSongName_HandleFocusGained:
	ld xwa, xiz
	call InheritedProc
	ld xwa, 0x147001D
	ld xbc, 0x1E70014
	lds32 xde, 0
	call MainFuncCall
	jr AcPDSongName_ReturnZero

AcPDSongName_HandleEventF:
	ld xwa, xiz
	call InheritedProc
	pushw 0xE2
	pushw 0x6290
	lda xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	lda xde, (xsp + 4)
	ld xwa, xiz
	ld xbc, 0x1C0000F
	call SendEvent
	pushw 0x0
	pushw 0x1CAC
	lda xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	lda xde, (xsp + 4)
	ld xwa, xiz
	ld xbc, 0x1C0000F
	call SendEvent

AcPDSongName_ReturnZero:
	lds32 xhl, 0

AcPDSongName_Epilogue:
	pop xiz
	st_dri3b L, 0xFD, 0x00, 0x01
	ret
AcPDSongName_End:

AcPDFileNoBoxProc:
	st_dri3b L, 0xFD, 0x00, 0xFF
	push xiz
	ld xiz, xwa
	cp xbc, 0x1C70008
	jr z, AcPDFileNo_HandleEventF
	cp xbc, 0x1C0000C
	jr z, AcPDFileNo_HandleFocusGained
	cp xbc, 0x1C0000B
	jr z, AcPDFileNo_HandleFocusGained
	cp xbc, 0x1C00002
	jr z, AcPDFileNo_HandleEvent1
	cp xbc, 0x1C00001
	jr z, AcPDFileNo_HandleEvent2
	ld xwa, xiz
	call InheritedProc
	jr AcPDFileNo_Epilogue

AcPDFileNo_HandleEvent2:
	ld xwa, xiz
	jr AcPDFileNo_CallInherited

AcPDFileNo_HandleEvent1:
	ld xwa, xiz

AcPDFileNo_CallInherited:
	call InheritedProc
	jr AcPDFileNo_ReturnZero

AcPDFileNo_HandleFocusGained:
	ld xwa, xiz
	call InheritedProc
	ld xwa, 0x147001D
	ld xbc, 0x1E70015
	lds32 xde, 0
	call MainFuncCall
	jr AcPDFileNo_ReturnZero

AcPDFileNo_HandleEventF:
	ld xwa, xiz
	call InheritedProc
	pushw 0xE2
	pushw 0x62AA
	lda xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	lda xde, (xsp + 4)
	ld xwa, xiz
	ld xbc, 0x1C0000F
	call SendEvent
	pushw 0x0
	pushw 0x1CC6
	lda xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	lda xde, (xsp + 4)
	ld xwa, xiz
	ld xbc, 0x1C0000F
	call SendEvent

AcPDFileNo_ReturnZero:
	lds32 xhl, 0

AcPDFileNo_Epilogue:
	pop xiz
	st_dri3b L, 0xFD, 0x00, 0x01
	ret

IvNamingExitProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1C00007
	jr z, IvNamingExit_ReturnZero
	cp xiz, 0x1E0003A
	jr z, IvNamingExit_CopyString
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	jr IvNamingExit_CallInherited

IvNamingExit_CopyString:
	pushw 0xE2
	pushw 0x62C4
	ld xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	lds32 xhl, 0
	jr IvNamingExit_Epilogue

IvNamingExit_ReturnZero:
	ld xwa, (xsp + 8)
	ld xbc, 0x1E00053
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jr z, IvNamingExit_ForwardEvent
	call GetTitleNow
	cp xhl, 0x1A0008F
	jr nz, IvNamingExit_CheckTitleA7
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00015
	ld xde, 0x1A0008E
	jr IvNamingExit_PostTitleEvent

IvNamingExit_CheckTitleA7:
	call GetTitleNow
	cp xhl, 0x1A000A7
	jr nz, IvNamingExit_ForwardEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00015
	ld xde, 0x1A00083

IvNamingExit_PostTitleEvent:
	call PostEvent

IvNamingExit_ForwardEvent:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)

IvNamingExit_CallInherited:
	call InheritedProc

IvNamingExit_Epilogue:
	pop xiz
	inc 8, xsp
	ret

IvNamingExit_ScreenData:
	.byte 0xf3, 0xfd, 0x4e, 0xff, 0x37, 0x3e, 0xf3, 0xfd
	.byte 0xaa, 0x00, 0x62
	ld	(xsp+174), xbc
	ld	(xsp+178), xwa
	.byte 0xe3, 0xfd, 0xae
	.byte 0x00, 0x20, 0xe8, 0xcf, 0x18, 0x00, 0xc0, 0x01
	.byte 0x76, 0x8e, 0x02, 0xe8, 0xcf, 0x17, 0x00, 0xc0
	.byte 0x01, 0x76, 0x85, 0x02, 0xe8, 0xcf, 0x03, 0x00
	.byte 0xe7, 0x01, 0x76, 0x58, 0x02, 0xe8, 0xcf, 0x0f
	.byte 0x00, 0xc0, 0x01, 0x76, 0x23, 0x01, 0xe8, 0xcf
	.byte 0x0b, 0x00, 0xc0, 0x01, 0x66, 0x69, 0xe8, 0xcf
	.byte 0x01, 0x00, 0xc0, 0x01, 0x7e, 0xaf, 0x02, 0xe3
	.byte 0xfd, 0xb2, 0x00, 0x20, 0xe3, 0xfd, 0xae, 0x00
	.byte 0x21
	ld	xde, (xsp+170)
	.byte 0x1d, 0x09
	.byte 0x44, 0xfa
	ld	xwa, (xsp+178)
	.byte 0x1d
	.byte 0x66, 0x62, 0xfa, 0xeb, 0x8e, 0xe3, 0xfd, 0xb2
	.byte 0x00, 0x22, 0xae, 0x22, 0x20, 0x41, 0x02, 0x00
	.byte 0xe7, 0x01, 0x1d, 0x63, 0x4a, 0xfa, 0x9e, 0x2e
	.byte 0x3f, 0x00, 0x00, 0x76, 0x74, 0x02, 0xe3, 0xfd
	.byte 0xb2, 0x00, 0x20, 0x41, 0x18, 0x00, 0xc0, 0x01
	.byte 0xea, 0xa8, 0x1d, 0x79, 0xa5, 0xf9, 0xe3, 0xfd
	.byte 0xb2, 0x00, 0x20, 0x41, 0x17, 0x00, 0xc0, 0x01
	.byte 0xea, 0xa8, 0x1d, 0x8a, 0xa5, 0xf9, 0xd8, 0xa9
	.byte 0x1d, 0x3b, 0xa5, 0xf9, 0x78, 0x4b, 0x02, 0xe3
	.byte 0xfd, 0xb2, 0x00, 0x20, 0xe3, 0xfd, 0xae, 0x00
	.byte 0x21
	ld	xde, (xsp+170)
	.byte 0x1d, 0x09
	.byte 0x44, 0xfa
	ld	xwa, (xsp+178)
	.byte 0x1d
	.byte 0x66, 0x62, 0xfa, 0xbf, 0x16, 0x63, 0xaf, 0x16
	.byte 0x20, 0xa8, 0x22, 0x20, 0xe3, 0xfd, 0xae, 0x00
	.byte 0x21
	ld	xde, (xsp+170)
	.byte 0x1d, 0x63
	.byte 0x4a, 0xfa, 0xaf, 0x16, 0x20, 0x98, 0x26, 0x3f
	.byte 0x02, 0x00, 0x71, 0x0d, 0x02, 0xf3, 0xfd, 0x9a
	.byte 0x00, 0x31
	ld	xwa, (xsp+178)
	.byte 0x1d
	.byte 0xdd, 0x95, 0xf9
	lda	xde, (xsp+154)
	.byte 0x9a, 0x04, 0x21, 0x92, 0xa1, 0xe9, 0x13, 0xaf
	.byte 0x16, 0x20, 0x98, 0x26, 0x59, 0xbf, 0x08, 0x51
	.byte 0x9a, 0x02, 0x20, 0xd8, 0x61, 0xf3, 0xfd, 0xa8
	.byte 0x00, 0x50, 0x9a, 0x06, 0x20, 0xd8, 0x69, 0xf3
	.byte 0xfd, 0xa4, 0x00, 0x50, 0xbf, 0x14, 0x02, 0x01
	.byte 0x00, 0x68, 0x28, 0x9f, 0x08, 0x20, 0x9f, 0x14
	.byte 0x40
	ld	bc, (xsp+154)
	.byte 0xd8, 0x81
	.byte 0xd9, 0x69
	lda	xwa, (xsp+166)
	.byte 0xb0
	.byte 0x51
	lda	xbc, (xsp+162)
	.byte 0x90, 0x22
	.byte 0xb1, 0x52, 0xda, 0xaf, 0x1d, 0x8a, 0xa9, 0xfa
	.byte 0x9f, 0x14, 0x61, 0xaf, 0x16, 0x20, 0x98, 0x26
	.byte 0x20, 0x9f, 0x14, 0xf8, 0x67, 0xcd, 0x78, 0x99
	.byte 0x01
	ld	xwa, (xsp+178)
	.byte 0xe3, 0xfd
	.byte 0xae, 0x00, 0x21
	ld	xde, (xsp+170)
	.byte 0x1d, 0x09, 0x44, 0xfa, 0xe3, 0xfd, 0xb2, 0x00
	.byte 0x20, 0x1d, 0x66, 0x62, 0xfa, 0xbf, 0x0a, 0x63
	.byte 0xaf, 0x0a, 0x20, 0xbf, 0x04, 0x60, 0xe3, 0xfd
	.byte 0xaa, 0x00, 0x22, 0xea, 0xe2, 0x76, 0xfd, 0x00
	.byte 0x98, 0x26, 0x21, 0x98, 0x28, 0x49, 0x82, 0x21
	.byte 0xd8, 0x13, 0xd9, 0xf0, 0x79, 0xee, 0x00, 0xf3
	.byte 0xfd, 0x9a, 0x00, 0x31, 0xe3, 0xfd, 0xb2, 0x00
	.byte 0x20, 0x1d, 0xdd, 0x95, 0xf9, 0xf3, 0xfd, 0x9a
	.byte 0x00, 0x31, 0xb9, 0x04, 0x30, 0xbf, 0x12, 0x60
	.byte 0x90, 0x22, 0x91, 0xa2, 0xea, 0x13, 0xaf, 0x0a
	.byte 0x23, 0x9b, 0x26, 0x5a, 0xbf, 0x08, 0x52, 0xb9
	.byte 0x06, 0x30, 0xbf, 0x0e, 0x60, 0xb9, 0x02, 0x30
	.byte 0xbf, 0x16, 0x60, 0x90, 0x22, 0xaf, 0x0e, 0x20
	.byte 0x90, 0x24, 0xda, 0xa4, 0x9b, 0x28, 0x23, 0xec
	.byte 0x13, 0xdb, 0x5c
	ld	xwa, (xsp+170)
	.byte 0x80, 0x21, 0xd8, 0x13, 0xe8, 0x13, 0xdb, 0x58
	.byte 0xd7, 0xe2, 0x8d
	ld	xwa, (xsp+170)
	.byte 0x80, 0x21, 0xd8, 0x13, 0xe8, 0x13, 0xdb, 0x58
	.byte 0xd8, 0x8b, 0xdc, 0x88, 0xdd, 0x40, 0xd8, 0x62
	.byte 0xd8, 0x82, 0xaf, 0x16, 0x25, 0xb5, 0x52, 0xdc
	.byte 0x82, 0xaf, 0x0e, 0x20, 0xb0, 0x52, 0x9f, 0x08
	.byte 0x20, 0xdb, 0x40, 0xd8, 0x62, 0x91, 0x88, 0x91
	.byte 0x22, 0x9f, 0x08, 0x82, 0xaf, 0x12, 0x20, 0xb0
	.byte 0x52
	lda	xde, (xsp+166)
	.byte 0x91, 0x20
	.byte 0xb2, 0x50, 0x95, 0x20, 0xba, 0x02, 0x50, 0xe3
	.byte 0xfd, 0xaa, 0x00, 0x20, 0xe8, 0x61, 0x38, 0xbf
	.byte 0x1e, 0x30, 0x38, 0x1d, 0x4d, 0x0f, 0xff, 0xef
	.byte 0x60, 0xaf, 0x0a, 0x21, 0xa9, 0x2a, 0x24, 0xe3
	.byte 0xfd, 0xaa, 0x00, 0x20, 0x80, 0x21, 0xc7, 0xf4
	.byte 0x99, 0xdd, 0x13, 0xbf, 0x1a, 0x32, 0xb9, 0x1c
	.byte 0x33
	lda	xbc, (xsp+166)
	.byte 0xf3, 0xfd
	.byte 0x9a, 0x00, 0x30, 0x94, 0xf5, 0x6e, 0x0b, 0xa3
	.byte 0x23, 0x3b, 0x0b, 0x00, 0x00, 0x0b, 0xff, 0x00
	.byte 0x68, 0x0f, 0xa3, 0x23, 0x3b, 0xaf, 0x0e, 0x23
	.byte 0x9b, 0x20, 0x04, 0xaf, 0x0a, 0x23, 0x9b, 0x16
	.byte 0x04, 0x1d, 0xca, 0xca, 0xfa, 0xe3, 0xfd, 0xb2
	.byte 0x00, 0x20, 0x1d, 0x66, 0x62, 0xfa, 0x9b, 0x26
	.byte 0x20, 0x9b, 0x28, 0x48, 0xe8, 0x13, 0xe3, 0xfd
	.byte 0xaa, 0x00, 0xf8, 0x6f, 0x55, 0xab, 0x2a, 0x21
	ld	xwa, (xsp+170)
	.byte 0xb1, 0x50, 0x68
	.byte 0x49
	ld	xwa, (xsp+178)
	.byte 0xe3, 0xfd
	.byte 0xae, 0x00, 0x21
	ld	xde, (xsp+170)
	.byte 0x1d, 0x09, 0x44, 0xfa, 0xe3, 0xfd, 0xb2, 0x00
	.byte 0x20, 0x1d, 0x66, 0x62, 0xfa, 0xeb, 0x8e, 0xae
	.byte 0x22, 0x20
	ld	xbc, (xsp+174)
	.byte 0xe3
	.byte 0xfd, 0xaa, 0x00, 0x22, 0x1d, 0x63, 0x4a, 0xfa
	.byte 0x9e, 0x30, 0x3f, 0x00, 0x00, 0x66, 0x13, 0xe3
	.byte 0xfd, 0xb2, 0x00, 0x20, 0xe3, 0xfd, 0xae, 0x00
	.byte 0x21
	ld	xde, (xsp+170)
	.byte 0x1d, 0xbd
	.byte 0xa5, 0xf9, 0xeb, 0xa8, 0x68, 0x13, 0xe3, 0xfd
	.byte 0xb2, 0x00, 0x20
	ld	xbc, (xsp+174)
	ld	xde, (xsp+170)
	.byte 0x1d, 0x09, 0x44
	.byte 0xfa, 0x5e, 0xf3, 0xfd, 0xb2, 0x00, 0x37, 0x0e

TrAsGrid_LookupByteTable:
	extz wa
	ldada xbc, 61856
	extz xwa
	add xwa, xbc
	ld l, (xwa)
	ret
; AcTrAsGridBoxProc dispatch
TrAsGrid_BoxProc:
AcTrAsGridBoxProc:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 8), xde
	ld (xsp + 12), xbc
	ld (xsp + 16), xwa
	ld xbc, (xsp + 12)
	cp xbc, 0x1E0008D
	jrl z, TrAsGrid_HandleResizeEvent
	ld xwa, (xsp + 12)
	cp xwa, 0x1C00007
	jrl z, TrAsGrid_HandleSelectEvent
	cp xwa, 0x1E0008B
	jrl z, TrAsGrid_GetDirectionLabel
	cp xwa, 0x1E0008A
	jrl z, TrAsGrid_GetWidgetLabel
	cp xwa, 0x1C00001
	jr z, TrAsGrid_HandleInit
	sub xbc, 0x1C00017
	cp xbc, 0x0
	jrl lt, TrAsGrid_PassThrough
	cp xbc, 0x6
	jrl gt, TrAsGrid_PassThrough
	add xbc, xbc
	add xbc, 0xE2643A
	ld bc, (xbc)
	lda_24 xix, 0xf2bf89
	jp_dri 8, 0x07, 0xF0, 0xE4

TrAsGrid_HandleInit:
	ld xwa, 0xC0
	call SndParam_LookupReadOnly
	cps hl, 0
	jr z, TrAsGrid_InitStateZero
	ld xwa, 0x8B0009
	lds bc, 0
	jr TrAsGrid_InitDispatch

TrAsGrid_InitStateZero:
	ld xwa, 0x8B0009
	lds bc, 1

TrAsGrid_InitDispatch:
	call SetVisible
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 16)
	ld xbc, 0x1E0008F
	lds32 xde, 0
	call SendEvent
	ld xiz, xhl
	ld xwa, (xsp + 4)
	ld bc, (xwa + 26)
	ld xwa, xiz
	srl xwa, 0
	ldi_werp 0xE2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, (xsp + 16)
	ld xbc, 0x1C00017
	call SetDialUp
	ld xwa, (xsp + 4)
	ld bc, (xwa + 26)
	ld xwa, xiz
	srl xwa, 0
	ldi_werp 0xE2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, (xsp + 16)
	ld xbc, 0x1C00018
	call SetDialDown
	lds wa, 1
	jrl TrAsGrid_CallUpdateSorted
	ld xwa, (xsp + 16)
	ld xbc, 0x1E00050
	ld xde, (xsp + 8)
	call SendEvent
	or xhl, xhl
	jrl z, TrAsGrid_HandleOtherEvent
	bitda 0, 3296
	jr nz, TrAsGrid_ScrollDown
	call GetFocusObject
	ld xwa, xhl
	ld xbc, 0x1E0008F
	lds32 xde, 0
	call SendEvent
	dec 3, l
	extz hl
	ld wa, hl
	jr TrAsGrid_ApplyScrollOffset

TrAsGrid_ScrollDown:
	call GetFocusObject
	ld xwa, xhl
	ld xbc, 0x1E0008F
	lds32 xde, 0
	call SendEvent
	inc 5, l
	extz hl
	ld wa, hl

TrAsGrid_ApplyScrollOffset:
	calr TrAsGrid_LookupByteTable
	st8_24 0x021082, l
	ld xwa, (xsp + 16)
	ld xbc, 0x1E0008F
	lds32 xde, 0
	call SendEvent
	ld (xsp + 6), hl
	ldda8 c, 3296
	ld e, c
	and e, 0x1
	cps e, 0
	scc16 nz, ix
	ld wa, (xsp + 6)
	sub wa, 0x2
	cps wa, 0
	scc16 z, hl
	and hl, ix
	jr z, TrAsGrid_CheckScrollBoundary
	res 0, c
	stda8 3296, c
	ld xwa, (xsp + 16)
	ld xbc, 0x1E0008E
	ld xde, 0xFFFF0009
	call SendEvent
	ld xwa, (xsp + 16)
	ld xbc, 0x1C0000B
	lds32 xde, 0
	jr TrAsGrid_DispatchNavigate

TrAsGrid_CheckScrollBoundary:
	cps e, 0
	scc16 z, bc
	cps wa, 0
	scc16 z, wa
	and wa, bc
	jrl nz, TrAsGrid_ReturnZero
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call InheritedProc
	ld wa, (xsp + 6)
	dec 1, wa
	ld de, wa
	extz xde
	add xde, 0xFFFF0000
	ld xwa, (xsp + 16)
	ld xbc, 0x1C0000E

TrAsGrid_DispatchNavigate:
	call SendEvent
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call SetAutoInc
	call SleepMainTask
	ld xwa, 0x147001C
	ld xbc, 0x1E70005
	ld xde, (xsp + 8)
	call FuncCall
	call WakeUpMainTask
	jrl TrAsGrid_ReturnZero

TrAsGrid_HandleOtherEvent:
	ld xwa, (xsp + 16)
	ld xbc, 0x1E00091
	ld xde, (xsp + 8)
	call SendEvent
	or xhl, xhl
	jrl z, TrAsGrid_ReturnZero
	bitda 2, 1057
	jrl nz, TrAsGrid_ReturnZero
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call ApFuncCall
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call SetAutoInc
	ld xwa, (xsp + 16)
	ld xbc, 0x1C00017
	ld xde, (xsp + 8)
	call SetDialUp
	ld xwa, (xsp + 16)
	ld xbc, 0x1C00018
	ld xde, (xsp + 8)
	call SetDialDown
	lds wa, 1
	jrl TrAsGrid_CallUpdateSorted
	ld xwa, (xsp + 16)
	ld xbc, 0x1E00050
	ld xde, (xsp + 8)
	call SendEvent
	or xhl, xhl
	jrl z, TrAsGrid_HandleOtherEvent2
	bitda 0, 3296
	jr nz, TrAsGrid_ScrollDown2
	call GetFocusObject
	ld xwa, xhl
	ld xbc, 0x1E0008F
	lds32 xde, 0
	call SendEvent
	dec 1, l
	extz hl
	ld wa, hl
	jr TrAsGrid_ApplyScrollOffset2

TrAsGrid_ScrollDown2:
	call GetFocusObject
	ld xwa, xhl
	ld xbc, 0x1E0008F
	lds32 xde, 0
	call SendEvent
	inc 7, l
	extz hl
	ld wa, hl

TrAsGrid_ApplyScrollOffset2:
	calr TrAsGrid_LookupByteTable
	st8_24 0x021082, l
	ld xwa, (xsp + 16)
	ld xbc, 0x1E0008F
	lds32 xde, 0
	call SendEvent
	ld (xsp + 6), hl
	ldda8 c, 3296
	ld e, c
	and e, 0x1
	cps e, 0
	scc16 z, ix
	ld wa, (xsp + 6)
	dec 2, wa
	cps wa, 7
	scc16 z, hl
	and hl, ix
	jr z, TrAsGrid_CheckScrollBoundary2
	set 0, c
	stda8 3296, c
	ld xwa, (xsp + 16)
	ld xbc, 0x1E0008E
	ld xde, 0xFFFF0002
	call SendEvent
	ld xwa, (xsp + 16)
	ld xbc, 0x1C0000B
	lds32 xde, 0
	jr TrAsGrid_DispatchNavigate2

TrAsGrid_CheckScrollBoundary2:
	cps e, 0
	scc16 nz, bc
	cps wa, 7
	scc16 z, wa
	and wa, bc
	jrl nz, TrAsGrid_ReturnZero
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call InheritedProc
	ld wa, (xsp + 6)
	inc 1, wa
	ld de, wa
	extz xde
	add xde, 0xFFFF0000
	ld xwa, (xsp + 16)
	ld xbc, 0x1C0000E

TrAsGrid_DispatchNavigate2:
	call SendEvent
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call SetAutoInc
	call SleepMainTask
	ld xwa, 0x147001C
	ld xbc, 0x1E70004
	ld xde, (xsp + 8)
	call FuncCall
	call WakeUpMainTask
	jrl TrAsGrid_ReturnZero

TrAsGrid_HandleOtherEvent2:
	ld xwa, (xsp + 16)
	ld xbc, 0x1E00091
	ld xde, (xsp + 8)
	call SendEvent
	or xhl, xhl
	jrl z, TrAsGrid_ReturnZero
	bitda 2, 1057
	jrl nz, TrAsGrid_ReturnZero
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call ApFuncCall
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call SetAutoInc
	ld xwa, (xsp + 16)
	ld xbc, 0x1C00017
	ld xde, (xsp + 8)
	call SetDialUp
	ld xwa, (xsp + 16)
	ld xbc, 0x1C00018
	ld xde, (xsp + 8)
	call SetDialDown
	lds wa, 1

TrAsGrid_CallUpdateSorted:
	call SetDialEnable
	jrl TrAsGrid_ReturnZero

TrAsGrid_GetWidgetLabel:
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld xwa, (xhl + 62)
	push xwa
	jr TrAsGrid_CopyLabel

TrAsGrid_GetDirectionLabel:
	bitda 0, 3296
	jr nz, TrAsGrid_DirectionLabel2
	ld xwa, 0xE263E2
	jr TrAsGrid_PushLabelAddr

TrAsGrid_DirectionLabel2:
	ld xwa, 0xE2640E

TrAsGrid_PushLabelAddr:
	push xwa

TrAsGrid_CopyLabel:
	ld xwa, (xsp + 12)
	push xwa
	call Strcpy
	inc 8, xsp
	jrl TrAsGrid_ReturnZero

TrAsGrid_HandleSelectEvent:
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, (xsp + 8)
	cp xwa, 0x8F
	jrl nz, TrAsGrid_ReturnZero
	bitda 0, 3296
	jr nz, TrAsGrid_DeselectCell
	ldw wa, 0x8
	calr TrAsGrid_LookupByteTable
	st8_24 0x021082, l
	setda 0, 3296
	ld xwa, (xsp + 16)
	ld xbc, 0x1E0008E
	ld xde, 0xFFFF0002
	call SendEvent
	ld xwa, (xsp + 16)
	ld xbc, 0x1C0000B
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call SetAutoInc
	call SleepMainTask
	ld xwa, 0x147001C
	ld xbc, 0x1E70008
	ld xde, (xsp + 8)
	jr TrAsGrid_FinishCellUpdate

TrAsGrid_DeselectCell:
	lds wa, 0
	calr TrAsGrid_LookupByteTable
	st8_24 0x021082, l
	resda 0, 3296
	ld xwa, (xsp + 16)
	ld xbc, 0x1E0008E
	ld xde, 0xFFFF0002
	call SendEvent
	ld xwa, (xsp + 16)
	ld xbc, 0x1C0000B
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call SetAutoInc
	call SleepMainTask
	ld xwa, 0x147001C
	ld xbc, 0x1E70009
	ld xde, (xsp + 8)

TrAsGrid_FinishCellUpdate:
	call FuncCall
	call WakeUpMainTask
	jr TrAsGrid_ReturnZero

TrAsGrid_HandleResizeEvent:
	ld xwa, (xsp + 16)
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call ApFuncCall

TrAsGrid_ReturnZero:
	lds32 xhl, 0
	jr TrAsGrid_Epilogue

TrAsGrid_PassThrough:
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call InheritedProc

TrAsGrid_Epilogue:
	pop xiz
	lda xsp, (xsp + 16)
	ret

TrAsGrid_LookupTable:
	extz wa
	add wa, wa
	lda_24 xbc, 0xe26448
	ld_sriw3 HL, 0x07, 0xE4, 0xE0
	ret

TrAsGrid_ByteData1:
	.byte 0xd8, 0x12, 0xf2, 0x68, 0x64, 0xe2, 0x32, 0xc3
	.byte 0x07, 0xe8, 0xe0, 0x21, 0xcb, 0xd8, 0x6e, 0x09
	.byte 0xc9, 0xcf, 0x13, 0x6f, 0x0a, 0xc9, 0x61, 0x68
	.byte 0x06, 0xc9, 0xd8, 0x66, 0x02, 0xc9, 0x69, 0xd8
	.byte 0x12, 0x41, 0x7c, 0x64, 0xe2, 0x00, 0xc3, 0x07
	.byte 0xe4, 0xe0, 0x27, 0x0e

TrAsGrid_CheckTrackType:
	cps a, 0
	jr nz, TrAsGrid_CheckCurrentCell
	ld a, c
	extz wa
	ldada xbc, 61856
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp a, 0xE
	jr z, TrAsGrid_IsDrumType
	cp a, 0xD
	jr z, TrAsGrid_IsDrumType

TrAsGrid_NotDrumType:
	ldb l, 0x0
	ret

TrAsGrid_CheckCurrentCell:
	ld8_24 a, 0x021082
	cp a, 0xE
	jr z, TrAsGrid_IsDrumType
	cp a, 0xD
	jr nz, TrAsGrid_NotDrumType

TrAsGrid_IsDrumType:
	ldb l, 0x1
	ret

TrAsGridCheck:
	lda xsp, (xsp - 18)
	push xiz
	ld xiz, xde
	ld xwa, xbc
	cp xbc, 0x1E0008D
	jrl z, TrAsGridChk_HandleResizeEvent
	sub xwa, 0x1C00017
	cp xwa, 0x0
	jrl lt, TrAsGridChk_ReturnZero
	cp xwa, 0x6
	jrl gt, TrAsGridChk_ReturnZero
	add xwa, xwa
	add xwa, 0xE264D0
	ld wa, (xwa)
	lda_24 xix, 0xf2c4b4
	jp_dri 8, 0x07, 0xF0, 0xE0

TrAsGridChk_ByteData:
	.byte 0x1d, 0xd0, 0x44, 0xfa, 0xeb, 0x88, 0x41, 0x8f
	.byte 0x00, 0xe0, 0x01, 0xea, 0xa8, 0x1d, 0x60, 0x96
	.byte 0xfa, 0xeb, 0x8e, 0xbf, 0x0e, 0x30, 0xee, 0x89
	.byte 0xe9, 0xef, 0x00, 0xd7, 0xe6, 0xa8, 0xb0, 0x51
	.byte 0xde, 0x8a, 0xb8, 0x02, 0x52, 0x90, 0x21, 0xd9
	.byte 0xdb, 0x76, 0xb2, 0x00, 0xd9, 0xda, 0x66, 0x73
	.byte 0xd9, 0xd9, 0x7e, 0xad, 0x04, 0xc1, 0x73, 0x28
	.byte 0x21, 0xd8, 0x12, 0xd9, 0xa8, 0x1e, 0x26, 0xff
	.byte 0xf1, 0x73, 0x28, 0x47, 0xf2, 0x82, 0x10, 0x02
	.byte 0x14, 0x73, 0x28, 0x40, 0x1c, 0x00, 0x47, 0x01
	.byte 0x41, 0x06, 0x00, 0xe7, 0x01, 0xee, 0x8a, 0x1d
	.byte 0x63, 0x4a, 0xfa, 0x1d, 0xd0, 0x44, 0xfa, 0xeb
	.byte 0x88, 0x41, 0x8d, 0x00, 0xe0, 0x01, 0xee, 0x8a
	.byte 0x1d, 0x60, 0x96, 0xfa, 0x1d, 0xd0, 0x44, 0xfa
	.byte 0xeb, 0x88, 0x9f, 0x10, 0x22, 0xea, 0x12, 0xea
	.byte 0xc8, 0x00, 0x00, 0x02, 0x00, 0x41, 0x8d, 0x00
	.byte 0xe0, 0x01, 0x1d, 0x60, 0x96, 0xfa, 0x1d, 0xd0
	.byte 0x44, 0xfa, 0xeb, 0x88, 0x9f, 0x10, 0x22, 0xea
	.byte 0x12, 0xea, 0xc8, 0x00, 0x00, 0x03, 0x00, 0x41
	.byte 0x8d, 0x00, 0xe0, 0x01, 0x1d, 0x60, 0x96, 0xfa
	.byte 0x78, 0x3f, 0x04, 0xf1, 0xe0, 0x0c, 0xc8, 0x6e
	.byte 0x08, 0xcd, 0x6a, 0xda, 0x12, 0xda, 0x88, 0x68
	.byte 0x06, 0xcd, 0x66, 0xda, 0x12, 0xda, 0x88, 0x1e
	.byte 0x9d, 0xfe, 0xd1, 0xd0, 0xf1, 0xeb, 0x1d, 0xd0
	.byte 0x44, 0xfa, 0xeb, 0x88, 0x41, 0x8d, 0x00, 0xe0
	.byte 0x01, 0xee, 0x8a, 0x1d, 0x60, 0x96, 0xfa, 0x40
	.byte 0x1c, 0x00, 0x47, 0x01, 0x41, 0x0a, 0x00, 0xe7
	.byte 0x01, 0xee, 0x8a, 0x78, 0x9c, 0x01, 0xf1, 0xe0
	.byte 0x0c, 0xc8, 0x6e, 0x1b, 0xcd, 0x6a, 0xda, 0x12
	.byte 0xda, 0x88, 0x1e, 0x6a, 0xfe, 0xd1, 0x90, 0xf2
	.byte 0xeb, 0x40, 0x1c, 0x00, 0x47, 0x01, 0x41, 0x0c
	.byte 0x00, 0xe7, 0x01, 0xee, 0x8a, 0x68, 0x19, 0xcd
	.byte 0x66, 0xda, 0x12, 0xda, 0x88, 0x1e, 0x4f, 0xfe
	.byte 0xd1, 0x90, 0xf2, 0xeb, 0x40, 0x1c, 0x00, 0x47
	.byte 0x01, 0x41, 0x0c, 0x00, 0xe7, 0x01, 0xee, 0x8a
	.byte 0x1d, 0x63, 0x4a, 0xfa, 0x1d, 0xd0, 0x44, 0xfa
	.byte 0xeb, 0x88, 0x41, 0x8d, 0x00, 0xe0, 0x01, 0xee
	.byte 0x8a, 0x1d, 0x60, 0x96, 0xfa, 0x40, 0x1c, 0x00
	.byte 0x47, 0x01, 0x41, 0x0a, 0x00, 0xe7, 0x01, 0xee
	.byte 0x8a, 0x78, 0x3e, 0x01, 0x1d, 0xd0, 0x44, 0xfa
	.byte 0xeb, 0x88, 0x41, 0x8f, 0x00, 0xe0, 0x01, 0xea
	.byte 0xa8, 0x1d, 0x60, 0x96, 0xfa, 0xeb, 0x8e, 0xbf
	.byte 0x0e, 0x30, 0xee, 0x89, 0xe9, 0xef, 0x00, 0xd7
	.byte 0xe6, 0xa8, 0xb0, 0x51, 0xde, 0x8a, 0xb8, 0x02
	.byte 0x52, 0x90, 0x21, 0xd9, 0xdb, 0x76, 0xb3, 0x00
	.byte 0xd9, 0xda, 0x66, 0x73, 0xd9, 0xd9, 0x7e, 0x71
	.byte 0x03, 0xc1, 0x73, 0x28, 0x21, 0xd8, 0x12, 0xd9
	.byte 0xa9, 0x1e, 0xea, 0xfd, 0xf1, 0x73, 0x28, 0x47
	.byte 0xf2, 0x82, 0x10, 0x02, 0x14, 0x73, 0x28, 0x40
	.byte 0x1c, 0x00, 0x47, 0x01, 0x41, 0x07, 0x00, 0xe7
	.byte 0x01, 0xee, 0x8a, 0x1d, 0x63, 0x4a, 0xfa, 0x1d
	.byte 0xd0, 0x44, 0xfa, 0xeb, 0x88, 0x41, 0x8d, 0x00
	.byte 0xe0, 0x01, 0xee, 0x8a, 0x1d, 0x60, 0x96, 0xfa
	.byte 0x1d, 0xd0, 0x44, 0xfa, 0xeb, 0x88, 0x9f, 0x10
	.byte 0x22, 0xea, 0x12, 0xea, 0xc8, 0x00, 0x00, 0x02
	.byte 0x00, 0x41, 0x8d, 0x00, 0xe0, 0x01, 0x1d, 0x60
	.byte 0x96, 0xfa, 0x1d, 0xd0, 0x44, 0xfa, 0xeb, 0x88
	.byte 0x9f, 0x10, 0x22, 0xea, 0x12, 0xea, 0xc8, 0x00
	.byte 0x00, 0x03, 0x00, 0x41, 0x8d, 0x00, 0xe0, 0x01
	.byte 0x1d, 0x60, 0x96, 0xfa, 0x78, 0x03, 0x03, 0xf1
	.byte 0xe0, 0x0c, 0xc8, 0x6e, 0x08, 0xcd, 0x6a, 0xda
	.byte 0x12, 0xda, 0x88, 0x68, 0x06, 0xcd, 0x66, 0xda
	.byte 0x12, 0xda, 0x88, 0x1e, 0x61, 0xfd, 0xdb, 0x06
	.byte 0xd1, 0xd0, 0xf1, 0xcb, 0x1d, 0xd0, 0x44, 0xfa
	.byte 0xeb, 0x88, 0x41, 0x8d, 0x00, 0xe0, 0x01, 0xee
	.byte 0x8a, 0x1d, 0x60, 0x96, 0xfa, 0x40, 0x1c, 0x00
	.byte 0x47, 0x01, 0x41, 0x0a, 0x00, 0xe7, 0x01, 0xee
	.byte 0x8a, 0x68, 0x5f, 0xf1, 0xe0, 0x0c, 0xc8, 0x6e
	.byte 0x1d, 0xcd, 0x6a, 0xda, 0x12, 0xda, 0x88, 0x1e
	.byte 0x2d, 0xfd, 0xdb, 0x06, 0xd1, 0x90, 0xf2, 0xcb
	.byte 0x40, 0x1c, 0x00, 0x47, 0x01, 0x41, 0x0c, 0x00
	.byte 0xe7, 0x01, 0xee, 0x8a, 0x68, 0x1b, 0xcd, 0x66
	.byte 0xda, 0x12, 0xda, 0x88, 0x1e, 0x10, 0xfd, 0xdb
	.byte 0x06, 0xd1, 0x90, 0xf2, 0xcb, 0x40, 0x1c, 0x00
	.byte 0x47, 0x01, 0x41, 0x0c, 0x00, 0xe7, 0x01, 0xee
	.byte 0x8a, 0x1d, 0x63, 0x4a, 0xfa, 0x1d, 0xd0, 0x44
	.byte 0xfa, 0xeb, 0x88, 0x41, 0x8d, 0x00, 0xe0, 0x01
	.byte 0xee, 0x8a, 0x1d, 0x60, 0x96, 0xfa, 0x40, 0x1c
	.byte 0x00, 0x47, 0x01, 0x41, 0x0a, 0x00, 0xe7, 0x01
	.byte 0xee, 0x8a, 0x1d, 0x63, 0x4a, 0xfa, 0x78, 0x61
	.byte 0x02

TrAsGridChk_HandleResizeEvent:
	lda xbc, (xsp + 14)
	ld xwa, xiz
	srl xwa, 0
	ldi_werp 0xE2, 0
	ld (xbc), wa
	lda xwa, (xbc + 2)
	ld de, iz
	ld (xwa), de
	lda xde, (xsp + 4)
	ld (xbc + 4), xde
	ld bc, (xbc)
	ld wa, (xwa)
	cps bc, 3
	jrl z, TrAsGridChk_Part3_Start
	cps bc, 2
	jr z, TrAsGridChk_Part2_Start
	cps bc, 1
	jrl nz, TrAsGridChk_ReturnZero
	call GetFocusObject
	ld xwa, xhl
	ld xbc, 0x1E0008F
	lds32 xde, 0
	call SendEvent
	ld wa, (xsp + 16)
	ld bc, wa
	cp bc, hl
	jr nz, TrAsGridChk_Part1_AdjustDown
	ld8_24 l, 0x021082
	jr TrAsGridChk_Part1_SendAudio

TrAsGridChk_Part1_AdjustDown:
	bitda 0, 3296
	jr nz, TrAsGridChk_Part1_AdjustUp
	dec 2, a
	extz wa
	calr TrAsGrid_LookupByteTable
	jr TrAsGridChk_Part1_SendAudio

TrAsGridChk_Part1_AdjustUp:
	inc 6, a
	extz wa
	calr TrAsGrid_LookupByteTable

TrAsGridChk_Part1_SendAudio:
	extz hl
	sla hl, 2
	ld xbc, 0xE262CA
	ld_sril3 XWA, 0x07, 0xE4, 0xEC
	push xwa
	lda xwa, (xsp + 8)
	push xwa
	call Audio_SendCommand
	inc 8, xsp
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 14)
	ld xbc, 0x1E0008C
	jrl TrAsGridChk_DispatchAndReturn

TrAsGridChk_Part2_Start:
	bitda 0, 3296
	jr nz, TrAsGridChk_Part2_UpDir
	dec 2, a
	extz wa
	calr TrAsGrid_LookupTable
	andda16 xhl, 61904
	lda xbc, (xsp + 4)
	ld xwa, 0xE26494
	cps hl, 0
	jr z, TrAsGridChk_Part2_PushCmd
	ld xwa, 0xE26490

TrAsGridChk_Part2_PushCmd:
	push xwa
	push xbc
	call Audio_SendCommand
	inc 8, xsp
	call GetFocusObject
	ld xwa, xhl
	ld xbc, 0x1E0008F
	lds32 xde, 0
	call SendEvent
	ld wa, (xsp + 16)
	ld de, wa
	dec 2, a
	ld c, a
	extz bc
	cp de, hl
	jr nz, TrAsGridChk_Part2_CheckType0
	lds wa, 1
	calr TrAsGrid_CheckTrackType
	cps l, 1
	jrl nz, TrAsGridChk_Part2_Finish
	ld xwa, 0xE26498
	jr TrAsGridChk_SendExtraAudioCmd

TrAsGridChk_Part2_CheckType0:
	lds wa, 0
	calr TrAsGrid_CheckTrackType
	cps l, 1
	jr nz, TrAsGridChk_Part2_Finish
	ld xwa, 0xE2649C
	jr TrAsGridChk_SendExtraAudioCmd

TrAsGridChk_Part2_UpDir:
	inc 6, a
	extz wa
	calr TrAsGrid_LookupTable
	andda16 xhl, 61904
	lda xbc, (xsp + 4)
	ld xwa, 0xE264A4
	cps hl, 0
	jr z, TrAsGridChk_Part2_UpPushCmd
	ld xwa, 0xE264A0

TrAsGridChk_Part2_UpPushCmd:
	push xwa
	push xbc
	call Audio_SendCommand
	inc 8, xsp
	call GetFocusObject
	ld xwa, xhl
	ld xbc, 0x1E0008F
	lds32 xde, 0
	call SendEvent
	ld wa, (xsp + 16)
	ld de, wa
	inc 6, a
	ld c, a
	extz bc
	cp de, hl
	jr nz, TrAsGridChk_Part2_UpCheckType0
	lds wa, 1
	calr TrAsGrid_CheckTrackType
	cps l, 1
	jr nz, TrAsGridChk_Part2_Finish
	ld xwa, 0xE264A8
	jr TrAsGridChk_SendExtraAudioCmd

TrAsGridChk_Part2_UpCheckType0:
	lds wa, 0
	calr TrAsGrid_CheckTrackType
	cps l, 1
	jr nz, TrAsGridChk_Part2_Finish
	ld xwa, 0xE264AC

TrAsGridChk_SendExtraAudioCmd:
	push xwa
	lda xwa, (xsp + 8)
	push xwa
	call Audio_SendCommand
	inc 8, xsp

TrAsGridChk_Part2_Finish:
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 14)
	ld xbc, 0x1E0008C
	jrl TrAsGridChk_DispatchAndReturn

TrAsGridChk_Part3_Start:
	bitda 0, 3296
	jr nz, TrAsGridChk_Part3_UpDir
	dec 2, a
	extz wa
	calr TrAsGrid_LookupTable
	andda16 xhl, 62096
	ld xwa, 0xE264B4
	cps hl, 0
	jr z, TrAsGridChk_Part3_PushCmd
	ld xwa, 0xE264B0

TrAsGridChk_Part3_PushCmd:
	push xwa
	lda xwa, (xsp + 8)
	push xwa
	call Audio_SendCommand
	inc 8, xsp
	call GetFocusObject
	ld xwa, xhl
	ld xbc, 0x1E0008F
	lds32 xde, 0
	call SendEvent
	ld wa, (xsp + 16)
	ld de, wa
	dec 2, a
	ld c, a
	extz bc
	cp de, hl
	jr nz, TrAsGridChk_Part3_CheckType0
	lds wa, 1
	calr TrAsGrid_CheckTrackType
	cps l, 1
	jrl nz, TrAsGridChk_Part3_Finish
	ld xwa, 0xE264B8
	jr TrAsGridChk_SendExtraAudioCmd2

TrAsGridChk_Part3_CheckType0:
	lds wa, 0
	calr TrAsGrid_CheckTrackType
	cps l, 1
	jr nz, TrAsGridChk_Part3_Finish
	ld xwa, 0xE264BC
	jr TrAsGridChk_SendExtraAudioCmd2

TrAsGridChk_Part3_UpDir:
	inc 6, a
	extz wa
	calr TrAsGrid_LookupTable
	andda16 xhl, 62096
	ld xwa, 0xE264C4
	cps hl, 0
	jr z, TrAsGridChk_Part3_UpPushCmd
	ld xwa, 0xE264C0

TrAsGridChk_Part3_UpPushCmd:
	push xwa
	lda xwa, (xsp + 8)
	push xwa
	call Audio_SendCommand
	inc 8, xsp
	call GetFocusObject
	ld xwa, xhl
	ld xbc, 0x1E0008F
	lds32 xde, 0
	call SendEvent
	ld wa, (xsp + 16)
	ld de, wa
	inc 6, a
	ld c, a
	extz bc
	cp de, hl
	jr nz, TrAsGridChk_Part3_UpCheckType0
	lds wa, 1
	calr TrAsGrid_CheckTrackType
	cps l, 1
	jr nz, TrAsGridChk_Part3_Finish
	ld xwa, 0xE264C8
	jr TrAsGridChk_SendExtraAudioCmd2

TrAsGridChk_Part3_UpCheckType0:
	lds wa, 0
	calr TrAsGrid_CheckTrackType
	cps l, 1
	jr nz, TrAsGridChk_Part3_Finish
	ld xwa, 0xE264CC

TrAsGridChk_SendExtraAudioCmd2:
	push xwa
	lda xwa, (xsp + 8)
	push xwa
	call Audio_SendCommand
	inc 8, xsp

TrAsGridChk_Part3_Finish:
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 14)
	ld xbc, 0x1E0008C

TrAsGridChk_DispatchAndReturn:
	call SendEvent

TrAsGridChk_ReturnZero:
	lds32 xhl, 0
	pop xiz
	lda xsp, (xsp + 18)
	ret
TrAsGridChk_End:

AcModeSelBoxProc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xwa
	cp xbc, 0x1E0004D
	jr z, VoiceConfig_HandleInit
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	jr VoiceConfig_Epilogue

VoiceConfig_HandleInit:
	ld xwa, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 4)
	cp xwa, 0x1
	jr nz, VoiceConfig_ReturnZero
	ld xwa, xiz
	call GetViewInstance
	mrdb5 0x8B, 0x32, 0x19, 0x3E, 0x0D

VoiceConfig_ReturnZero:
	lds32 xhl, 0

VoiceConfig_Epilogue:
	pop xiz
	inc 4, xsp
	ret

VoiceConfig_ScreenTypeDispatch:
	push xiz
	ld xiz, xwa
	cp xiz, 0xB
	jr z, VoiceConfig_SetType5
	cp xiz, 0xA
	jr z, VoiceConfig_SetType4
	cp xiz, 0x9
	jr z, VoiceConfig_SetType3
	cp xiz, 0x8B
	jr z, VoiceConfig_SetType2
	cp xiz, 0x8A
	jr z, VoiceConfig_SetType1
	cp xiz, 0x89
	jr nz, VoiceConfig_ReturnZeroShort
	lds32 xiz, 0

VoiceConfig_LookupByScreenType:
	call GetTitleNow
	ldi_werp 0xEE, 0
	cp hl, 0xE3
	jr z, VoiceConfig_LoadTableB
	cp hl, 0xE2
	jr z, VoiceConfig_LoadTableA
	cp hl, 0xE1
	jr nz, VoiceConfig_ReturnZeroShort
	ld xwa, 0xE264DE

VoiceConfig_ReadFromTable:
	add xwa, xiz
	ld l, (xwa)
	jr VoiceConfig_PopIzRet

VoiceConfig_SetType1:
	lds32 xiz, 1
	jr VoiceConfig_LookupByScreenType

VoiceConfig_SetType2:
	lds32 xiz, 2
	jr VoiceConfig_LookupByScreenType

VoiceConfig_SetType3:
	lds32 xiz, 3
	jr VoiceConfig_LookupByScreenType

VoiceConfig_SetType4:
	lds32 xiz, 4
	jr VoiceConfig_LookupByScreenType

VoiceConfig_SetType5:
	lds32 xiz, 5
	jr VoiceConfig_LookupByScreenType

VoiceConfig_LoadTableA:
	ld xwa, 0xE264E4
	jr VoiceConfig_ReadFromTable

VoiceConfig_LoadTableB:
	ld xwa, 0xE264EA
	jr VoiceConfig_ReadFromTable

VoiceConfig_ReturnZeroShort:
	ldb l, 0x0

VoiceConfig_PopIzRet:
	pop xiz
	ret
VoiceConfig_End:

AcDemoSongBoxProc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 8), xde
	ld (xsp + 12), xbc
	ld xiz, xwa
	ld xwa, (xsp + 12)
	cp xwa, 0x1C00007
	jr z, AcDemoSong_HandleResize
	cp xwa, 0x1C00002
	jr z, AcDemoSong_HandleInit
	ld xwa, xiz
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call InheritedProc
	jr AcDemoSong_Epilogue

AcDemoSong_HandleInit:
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 46)
	ldw (xwa), 0x0
	ld xwa, xiz
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	jr AcDemoSong_CallInherited

AcDemoSong_HandleResize:
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	ld wa, (xwa + 42)
	extz xwa
	cp xwa, (xsp + 8)
	jr nz, AcDemoSong_DefaultHandler
	ld xwa, (xsp + 8)
	calr VoiceConfig_ScreenTypeDispatch
	cpdi8 3375, 0
	jr nz, AcCurrentSongBox_RetZero
	bitda 3, 10413
	jr z, AcDemoSong_SetupDisplay
	cpdm8 4439, l
	jr nz, AcCurrentSongBox_RetZero

AcDemoSong_SetupDisplay:
	ldb h, 0x0
	extz xhl
	ld (xsp + 8), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 50)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call ApFuncCall
	jr AcCurrentSongBox_RetZero

AcDemoSong_DefaultHandler:
	ld xwa, xiz
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)

AcDemoSong_CallInherited:
	call InheritedProc

AcCurrentSongBox_RetZero:
	lds32 xhl, 0

AcDemoSong_Epilogue:
	pop xiz
	lda xsp, (xsp + 12)
	ret
AcDemoSong_End:

AcCurrentSongBoxProc:
	st_dri3b L, 0xFD, 0x00, 0xFF
	push xiz
	ld xiz, xwa
	cp xbc, 0x1C0000C
	jr z, AcCurSongName_HandleFocusGained
	cp xbc, 0x1C0000B
	jr z, AcCurSongName_HandleFocusGained
	cp xbc, 0x1C00002
	jr z, AcCurSong_HandleEvent1
	cp xbc, 0x1C00001
	jr z, AcCurSong_HandleEvent2
	ld xwa, xiz
	call InheritedProc
	jr AcCurSong_Epilogue

AcCurSong_HandleEvent2:
	ld xwa, xiz
	jr AcCurSong_CallInherited

AcCurSong_HandleEvent1:
	ld xwa, xiz

AcCurSong_CallInherited:
	call InheritedProc
	jr AcCurSong_ReturnZero

AcCurSongName_HandleFocusGained:
	ld xwa, xiz
	call InheritedProc
	ld8_24 a, 0x00ffe3
	inc 1, a
	extz wa
	pushw wa
	pushw 0xE2
	pushw 0x64F0
	lda xwa, (xsp + 10)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 10)
	lda xde, (xsp + 4)
	ld xwa, xiz
	ld xbc, 0x1C0000F
	call SendEvent

AcCurSong_ReturnZero:
	lds32 xhl, 0

AcCurSong_Epilogue:
	pop xiz
	st_dri3b L, 0xFD, 0x00, 0x01
	ret
AcCurSong_End:

AcCurSongNameBoxProc:
	st_dri3b L, 0xFD, 0x00, 0xFF
	push xiz
	ld xiz, xwa
	cp xbc, 0x1C70000
	jr z, AcCurSongName_HandleEventF
	cp xbc, 0x1C0000C
	jr z, AcCurSongName_HandleFocusGained
	cp xbc, 0x1C0000B
	jr z, AcCurSongName_HandleFocusGained
	cp xbc, 0x1C00002
	jr z, AcCurSongName_HandleEvent1
	cp xbc, 0x1C00001
	jr z, AcCurSongName_HandleEvent2
	ld xwa, xiz
	call InheritedProc
	jr MuteChSel_TtlDefault

AcCurSongName_HandleEvent2:
	ld xwa, xiz
	jr AcCurSongName_CallInherited

AcCurSongName_HandleEvent1:
	ld xwa, xiz

AcCurSongName_CallInherited:
	call InheritedProc
	jr MuteChSel_TtlSetup

AcCurSongName_HandleFocusGained:
	ld xwa, xiz
	call InheritedProc
	ld xwa, 0x147001D
	ld xbc, 0x1E7000D
	lds32 xde, 0
	call MainFuncCall
	jr MuteChSel_TtlSetup

AcCurSongName_HandleEventF:
	ld xwa, xiz
	call InheritedProc
	pushw 0xE2
	pushw 0x64F8
	lda xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	lda xde, (xsp + 4)
	ld xwa, xiz
	ld xbc, 0x1C0000F
	call SendEvent
	pushw 0x0
	pushw 0x1C50
	lda xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	lda xde, (xsp + 4)
	ld xwa, xiz
	ld xbc, 0x1C0000F
	call SendEvent

; SmfMuteChSelFunc title setup
MuteChSel_TtlSetup:
	lds32 xhl, 0

; SmfMuteChSelFunc title default
MuteChSel_TtlDefault:
	pop xiz
	st_dri3b L, 0xFD, 0x00, 0x01
	ret

DemoSongSelFunc:
	ld xwa, 0x147001C
	ld xbc, 0x1E70000
	call MainFuncCall
	lds32 xhl, 0
	ret

SmfMuteChSelFunc:
	push xiz
	ld xiz, xwa
	sub xbc, 0x1E0003E
	cp xbc, 0x0
	jr lt, MuteChSel_ReturnZero
	cp xbc, 0x9
	jr gt, MuteChSel_ReturnZero
	add xbc, xbc
	add xbc, 0xE265B0
	ld bc, (xbc)
	lda_24 xix, 0xf2cc54
	jp_dri 8, 0x07, 0xF0, 0xE4
; SmfMuteChSelFunc dispatch
MuteChSel_Dispatch:
	.byte 0xaa, 0x0e, 0x20, 0xe8, 0xee, 0x02, 0x41, 0x10
	.byte 0x65, 0xe2, 0x00, 0xe8, 0x81, 0xa1, 0x20, 0x38
	.byte 0xaa, 0x12, 0x20, 0x38, 0x1d, 0x4d, 0x0f, 0xff
	.byte 0xef, 0x60, 0xee, 0x8b, 0x68, 0x14, 0xeb, 0xa9
	.byte 0x68, 0x10, 0x43, 0x0f, 0x00, 0x00, 0x00, 0x68
	.byte 0x09

; SmfMuteChSelFunc return zero
MuteChSel_ReturnZero:
	lds32 xhl, 0
	jr MuteChSel_Epilogue
	lda_24 xhl, 0x021084

; SmfMuteChSelFunc epilogue
MuteChSel_Epilogue:
	pop xiz
	ret

SqTrAsPsSongFunc:
	push xiz
	ld xiz, xwa
	sub xbc, 0x1E0003E
	cp xbc, 0x0
	jr lt, SqTrAsPsSong_ReturnZero
	cp xbc, 0x9
	jr gt, SqTrAsPsSong_ReturnZero
	add xbc, xbc
	add xbc, 0xE2665E
	ld bc, (xbc)
	lda_24 xix, 0xf2ccb5
	jp_dri 8, 0x07, 0xF0, 0xE4
; SqTrAsPsSongFunc dispatch
SqTrAsPsSong_Dispatch:
	.byte 0xaa, 0x0e, 0x20, 0xe8, 0xee, 0x02, 0x41, 0xc4
	.byte 0x65, 0xe2, 0x00, 0xe8, 0x81, 0xa1, 0x20, 0x38
	.byte 0xaa, 0x12, 0x20, 0x38, 0x1d, 0x4d, 0x0f, 0xff
	.byte 0xef, 0x60, 0xee, 0x8b, 0x68, 0x13, 0xeb, 0xa9
	.byte 0x68, 0x0f, 0x43, 0x0a, 0x00, 0x00, 0x00, 0x68
	.byte 0x08

; SqTrAsPsSongFunc return zero
SqTrAsPsSong_ReturnZero:
	lds32 xhl, 0
	jr MuteChSel_Epilogue
	ldada xhl, 3391

MuteChSel_Epilogue:
	pop xiz
	ret

SqAftSetFunc:
	push xiz
	ld xiz, xwa
	cp xbc, 0x1E00065
	jr z, SqAftSet_Case2
	cp xbc, 0x1E00064
	jr z, SqAftSet_Case1
	cp xbc, 0x1E00063
	jr z, SqAftSet_Case0
	cp xbc, 0x1E00062
	jr nz, SqAftSet_Case2
	ld wa, (xde + 8)
	sla wa, 2
	lda_24 xbc, 0xe26672
	ld_sril3 XWA, 0x07, 0xE4, 0xE0
	push xwa
	ld xwa, (xde + 10)
	push xwa
	call Strcpy
	inc 8, xsp
	ld xhl, xiz
	jr SqAftSet_LookupExit

; SqAftSetFunc case 0
SqAftSet_Case0:
	lda_24 xhl, 0x00ffc2
	jr SqAftSet_LookupExit

; SqAftSetFunc case 1
SqAftSet_Case1:
	lds32 xhl, 1
	jr SqAftSet_LookupExit

; SqAftSetFunc case 2
SqAftSet_Case2:
	lds32 xhl, 0

SqAftSet_LookupExit:
	pop xiz
	ret

SqAftSet_LookupTableEntry:
	extz wa
	add wa, wa
	lda_24 xbc, 0xe26686
	ld_sriw3 WA, 0x07, 0xE4, 0xE0
	st16_24 0x021086, xwa
	ret

MuteChSetFunc:
	push xiz
	ld xiz, xwa
	ld xwa, xbc
	cp xbc, 0x1E00082
	jr z, MuteChSet_ParamCheck
	sub xwa, 0x1E0003E
	cp xwa, 0x0
	jr lt, MuteChSetFunc_Exit
	cp xwa, 0x9
	jr gt, MuteChSetFunc_Exit
	add xwa, xwa
	add xwa, 0xE26766
	ld wa, (xwa)
	lda_24 xix, 0xf2cd84
	jp_dri 8, 0x07, 0xF0, 0xE0

; MuteChSetFunc dispatch
MuteChSet_Dispatch:
	ld	xwa, (xde+14)
	sll	xwa, 2
	ld	xbc, 14837414
	add	xbc, xwa
	ld	xwa, (xbc)
	push	xwa
	ld	xwa, (xde+18)
	push	xwa
	call	16715597
	inc	8, xsp
	ld	xhl, xiz
	jr	54
	lds32	xhl, 1
	jr	50
	ld	xhl, 15
	jr	43
	lda_24	xhl, 135306
	jr	36

; MuteChSetFunc parameter check
MuteChSet_ParamCheck:
	cpi8_24 0x021088, 0x01
	jr nz, MuteChSetFunc_Exit
	ld8_24 a, 0x02108a
	extz wa
	calr SqAftSet_LookupTableEntry
	ld xwa, 0x147001C
	ld xbc, 0x1E7000B
	lds32 xde, 0
	call MainFuncCall

MuteChSetFunc_Exit:
	lds32 xhl, 0
	pop xiz
	ret
SqAftSetFunc_End:

AcMuteToggleBoxProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld (xsp + 8), xbc
	ld xiz, xwa
	ld xwa, (xsp + 8)
	cp xwa, 0x1C00001
	jr z, AcMuteToggle_HandleInit
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call InheritedProc
	jr AcMuteToggle_Epilogue

AcMuteToggle_HandleInit:
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 40)
	ld xbc, 0x1E70017
	lds32 xde, 0
	call ApFuncCall
	ld xde, xhl
	st32_24 0x02108c, xde
	ld xwa, xiz
	ld xbc, 0x1E0003B
	call SendEvent
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call InheritedProc
	lds32 xhl, 0

AcMuteToggle_Epilogue:
	pop xiz
	inc 8, xsp
	ret

SMFMuteOnOffFunc:
	cp xbc, 0x1E70017
	jr nz, SMFMuteOnOff_Enable
	lds32 xhl, 0
	ld8_24 l, 0x021088
	ret

SMFMuteOnOff_Enable:
	cp xde, 0x1
	jr nz, SMFMuteOnOff_Disable
	sti8_24 0x021088, 0x01
	ld8_24 a, 0x02108a
	extz wa
	calr SqAftSet_LookupTableEntry
	ld xwa, 0x147001C
	ld xbc, 0x1E7000B
	lds32 xde, 0
	jr SMFMuteOnOff_PostCall

SMFMuteOnOff_Disable:
	sti8_24 0x021088, 0x00
	sti16_24 0x021086, 0x0000
	ld xwa, 0x147001C
	ld xbc, 0x1E7000B
	lds32 xde, 0

SMFMuteOnOff_PostCall:
	call MainFuncCall
	lds32 xhl, 0
	ret

SMFMute_GetBit0Status:
	ld16_24 xhl, 0x021086
	and hl, 0x1
	extz xhl
	ret

SMFMute_GetBit1Status:
	ld16_24 xhl, 0x021086
	and hl, 0x2
	extz xhl
	ret

SMFMute_GetUpperBits:
	ld16_24 xhl, 0x021086
	and hl, 0xFFFC
	extz xhl
	ret

SMFMute_ClearBit0:
	ld16_24 xhl, 0x021086
	res 0, hl
	extz xhl
	ret

Rt1MuteFunc:
	cp xbc, 0x1E70017
	jr z, SMFMute_GetBit0Status
	cp xde, 0x1
	jr nz, Rt1Mute_ClearAndPost
	ordi16_24 135302, 1
	ld xwa, 0x147001C
	ld xbc, 0x1E7000B
	lds32 xde, 0
	jr Rt1Mute_PostCall

Rt1Mute_ClearAndPost:
	anddi16_24 135302, 65534
	ld xwa, 0x147001C
	ld xbc, 0x1E7000B
	lds32 xde, 0

Rt1Mute_PostCall:
	call MainFuncCall
	lds32 xhl, 0
	ret

Rt2MuteFunc:
	cp xbc, 0x1E70017
	jr z, SMFMute_GetBit1Status
	cp xde, 0x1
	jr nz, Rt2Mute_ClearAndPost
	ordi16_24 135302, 2
	ld xwa, 0x147001C
	ld xbc, 0x1E7000B
	lds32 xde, 0
	jr Rt2Mute_PostCall

Rt2Mute_ClearAndPost:
	anddi16_24 135302, 65533
	ld xwa, 0x147001C
	ld xbc, 0x1E7000B
	lds32 xde, 0

Rt2Mute_PostCall:
	call MainFuncCall
	lds32 xhl, 0
	ret

DocOrchMuteFunc:
	cp xbc, 0x1E70017
	jrl z, SMFMute_GetUpperBits
	cp xde, 0x1
	jr nz, DocOrchMute_ClearAndPost
	ordi16_24 135302, 65532
	ld xwa, 0x147001C
	ld xbc, 0x1E7000B
	lds32 xde, 0
	jr DocOrchMute_PostCall

DocOrchMute_ClearAndPost:
	anddi16_24 135302, 3
	ld xwa, 0x147001C
	ld xbc, 0x1E7000B
	lds32 xde, 0

DocOrchMute_PostCall:
	call MainFuncCall
	lds32 xhl, 0
	ret

PdOrchMuteFunc:
	cp xbc, 0x1E70017
	jrl z, SMFMute_ClearBit0
	cp xde, 0x1
	jr nz, PdOrchMute_ClearAndPost
	ordi16_24 135302, 65534
	ld xwa, 0x147001C
	ld xbc, 0x1E7000B
	lds32 xde, 0
	jr PdOrchMute_PostCall

PdOrchMute_ClearAndPost:
	anddi16_24 135302, 1
	ld xwa, 0x147001C
	ld xbc, 0x1E7000B
	lds32 xde, 0

PdOrchMute_PostCall:
	call MainFuncCall
	lds32 xhl, 0
	ret

SeqNameOKFunc:
	call GetNamingWindowID
	ld xwa, xhl
	ld xbc, 0x1E0003A
	ld xde, 0x20C92
	call SendEvent
	ld xwa, 0x147001C
	ld xbc, 0x1E70001
	ld xde, 0x20C92
	call MainFuncCall
	lds32 xhl, 0
	ret

SeqNamingCheck:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xwa
	cp xbc, 0x1E0007C
	jr z, SeqNameOK_Return10
	cp xbc, 0x1E00084
	jr z, SeqNameOK_ReturnZero
	cp xbc, 0x1E0003A
	jr nz, SeqNameOK_ReturnZero
	pushw 0x10
	pushw 0x0
	pushw 0xF280
	pushw 0x2
	pushw 0xCA2
	call Strncpy
	lda_24 xwa, 0x020ca2
	ld (xwa + 16), 0x0
	push xwa
	ld xwa, (xsp + 18)
	push xwa
	call Strcpy
	lda xsp, (xsp + 18)
	ld xhl, xiz
	jr SeqNameOK_Epilogue

SeqNameOK_ReturnZero:
	lds32 xhl, 0
	jr SeqNameOK_Epilogue

SeqNameOK_Return10:
	ld xhl, 0x10

SeqNameOK_Epilogue:
	pop xiz
	inc 4, xsp
	ret
SeqNameOK_End:

AcDemoMedleyDispBoxProc:
	st_dri3b L, 0xFD, 0x00, 0xFF
	push xiz
	ld xiz, xwa
	cp xbc, 0x1C0000C
	jr z, AcDemoMedley_HandleScrollEvent
	cp xbc, 0x1C0000B
	jr z, AcDemoMedley_HandleScrollEvent
	cp xbc, 0x1C00002
	jr z, DemoMedDsp_LoadEntry
	cp xbc, 0x1C00001
	jr z, DemoMedDsp_HandleDefault
	ld xwa, xiz
	call InheritedProc
	jr DPPauseDsp_CheckEntry

DemoMedDsp_HandleDefault:
	ld xwa, xiz
	jr DemoMedDsp_LoadReturn

; DemoMedDspCheck load entry
DemoMedDsp_LoadEntry:
	ld xwa, xiz

; DemoMedDspCheck load return
DemoMedDsp_LoadReturn:
	call InheritedProc
	jr DPPlayDsp_ReturnPath

AcDemoMedley_HandleScrollEvent:
	ld xwa, xiz
	call InheritedProc
	lda xbc, (xsp + 4)
	ld xwa, 0xE26786
	cpi8_24 0x021090, 0x01
	jr nz, DPPlayDsp_CheckEntry
	ld xwa, 0xE2677A

; DPPlayDspCheck entry
DPPlayDsp_CheckEntry:
	push xwa
	push xbc
	call Audio_SendCommand
	inc 8, xsp
	lda xde, (xsp + 4)
	ld xwa, xiz
	ld xbc, 0x1C0000F
	call SendEvent

; DPPlayDspCheck return path
DPPlayDsp_ReturnPath:
	lds32 xhl, 0

; DPPauseDspCheck entry
DPPauseDsp_CheckEntry:
	pop xiz
	st_dri3b L, 0xFD, 0x00, 0x01
	ret

DemoMedDspCheck:
	push xiz
	ld xiz, xwa
	ld xwa, xbc
	cp xbc, 0x1E00082
	jr z, DPLoad_DspReturn
	sub xwa, 0x1E0003E
	cp xwa, 0x0
	jr lt, DPLoad_DspReturn
	cp xwa, 0x9
	jr gt, DPLoad_DspReturn
	add xwa, xwa
	add xwa, 0xE267AA
	ld wa, (xwa)
	lda_24 xix, 0xf2d0e9
	jp_dri 8, 0x07, 0xF0, 0xE0

; DemoMedDspCheck dispatch
DemoMedDsp_Dispatch:
	.byte 0xaa, 0x0e, 0x23, 0xaa, 0x12, 0x21, 0x40, 0x9e
	.byte 0x67, 0xe2, 0x00, 0xeb, 0xe3, 0x6e, 0x05, 0x40
	.long MedleyDisp_Blank
	push	xwa
	push	xbc
	call	16714354
	inc	8, xsp
	ld	xhl, xiz
	jr	31
	lds32	xhl, 4
	jr	27
	lds32	xhl, 1
	jr	23
	ld	xhl, 16
	jr	16
	ld	xhl, 4294967267
	jr	9
	lda_24	xhl, 135312
	jr	2

DPLoad_DspReturn:
	lds32 xhl, 0
	pop xiz
	ret

DPPlayDspCheck:
	push xiz
	ld xiz, xwa
	ld xwa, xbc
	cp xbc, 0x1E00082
	jr z, DPPlay_DspReturn
	sub xwa, 0x1E0003E
	cp xwa, 0x0
	jr lt, DPPlay_DspReturn
	cp xwa, 0x9
	jr gt, DPPlay_DspReturn
	add xwa, xwa
	add xwa, 0xE267CA
	ld wa, (xwa)
	lda_24 xix, 0xf2d161
	jp_dri 8, 0x07, 0xF0, 0xE0

; DPPlayDspCheck dispatch
DPPlayDsp_Dispatch:
	.byte 0xaa, 0x0e, 0x23, 0xaa, 0x12, 0x21, 0x40, 0xc4
	.byte 0x67, 0xe2, 0x00, 0xeb, 0xe3, 0x6e, 0x05, 0x40
	.long PlayModeStr_Play
	push	xwa
	push	xbc
	call	16714354
	inc	8, xsp
	ld	xhl, xiz
	jr	31
	lds32	xhl, 4
	jr	27
	lds32	xhl, 1
	jr	23
	ld	xhl, 16
	jr	16
	ld	xhl, 4294967267
	jr	9
	lda_24	xhl, 135314
	jr	2

DPPlay_DspReturn:
	lds32 xhl, 0
	pop xiz
	ret

DPPauseDspCheck:
	push xiz
	ld xiz, xwa
	ld xwa, xbc
	cp xbc, 0x1E00082
	jr z, DPPause_DspReturn
	sub xwa, 0x1E0003E
	cp xwa, 0x0
	jr lt, DPPause_DspReturn
	cp xwa, 0x9
	jr gt, DPPause_DspReturn
	add xwa, xwa
	add xwa, 0xE267EA
	ld wa, (xwa)
	lda_24 xix, 0xf2d1d9
	jp_dri 8, 0x07, 0xF0, 0xE0

; DPPauseDspCheck dispatch
DPPauseDsp_Dispatch:
	.byte 0xaa, 0x0e, 0x23, 0xaa, 0x12, 0x21, 0x40, 0xe4
	.byte 0x67, 0xe2, 0x00, 0xeb, 0xe3, 0x6e, 0x05, 0x40
	.long PlayModeStr_Pause
	push	xwa
	push	xbc
	call	16714354
	inc	8, xsp
	ld	xhl, xiz
	jr	31
	lds32	xhl, 4
	jr	27
	lds32	xhl, 1
	jr	23
	ld	xhl, 16
	jr	16
	ld	xhl, 4294967267
	jr	9
	lda_24	xhl, 135316
	jr	2

DPPause_DspReturn:
	lds32 xhl, 0
	pop xiz
	ret
DemoMedDsp_End:

IvExitModeTrSelProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld (xsp + 8), xbc
	ld xiz, xwa
	ld xwa, (xsp + 8)
	cp xwa, 0x1C00007
	jr z, IvExitTrSel_CheckSendEvent
	cp xwa, 0x1E0003A
	jr z, IvExitTrSel_CopyString
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	jr IvExitTrSel_CallInherited

IvExitTrSel_CopyString:
	pushw 0xE2
	pushw 0x67FE
	ld xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	lds32 xhl, 0
	jr IvExitTrSel_Epilogue

IvExitTrSel_CheckSendEvent:
	ld xwa, xiz
	call GetViewInstance
	ld xwa, xiz
	ld xbc, 0x1E00053
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jr z, IvExitTrSel_PrepareInherited
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 1
	call SendEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00014
	ld xde, 0x1800008
	call PostEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call PostEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00015
	ld xde, 0x1A00084
	call PostEvent

IvExitTrSel_PrepareInherited:
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)

IvExitTrSel_CallInherited:
	call InheritedProc

IvExitTrSel_Epilogue:
	pop xiz
	inc 8, xsp
	ret


InitializeKubo:
	lda xsp, (xsp - 14)

	RegObjTable 0x1600004, 0xFA44E2, 0xE27596, 0xE27180, 0x168
	RegObjTable 0x160000c, 0xFA58FB, 0xE275F8, 0xE27598, 0x1c8
	RegObjTable 0x160000d, 0xFA5948, 0xE27FA2, 0xE275FA, 0x1e8
	RegObjTabl 0x1600002, 0xFA496C, 0x49, 0xE26804, 0x128
	RegObjTabl 0x1600002, 0xFA496C, 0x49, 0xE2692C, 0x428
	RegObjTabl 0x1600001, 0xFA48A9, 0x0, 0x3DF10, 0x108
	RegObjTabl 0x1600001, 0xFA48A9, 0x0, 0x3DF14, 0x408
	RegObjTabl 0x1600003, 0xFA4A18, 0x2c, 0xE3051C, 0x148
	RegObjTabl 0x1600003, 0xFA4A18, 0x2c, 0xE305D0, 0x448
	RegObjTabl 0x1600010, 0xFA5995, 0xc, 0xE2E624, 0xa
	RegObjTabl 0x160000f, 0xFA62CB, 0xc, 0xE2F0AC, 0x30a
	RegObjTabl 0x1600010, 0xFA5995, 0xc, 0xE2E658, 0xb
	RegObjTabl 0x160000f, 0xFA62CB, 0xc, 0xE2F0FA, 0x30b
	RegObjTabl 0x1600010, 0xFA5995, 0x25, 0xE2E68C, 0xc
	RegObjTabl 0x160000f, 0xFA62CB, 0x25, 0xE2F148, 0x30c
	RegObjTabl 0x1600010, 0xFA5995, 0xc, 0xE2E724, 0xe
	RegObjTabl 0x160000f, 0xFA62CB, 0xc, 0xE2F232, 0x30e
	RegObjTabl 0x1600010, 0xFA5995, 0xc, 0xE2E758, 0x80
	RegObjTabl 0x160000f, 0xFA62CB, 0xc, 0xE2F280, 0x380
	RegObjTabl 0x1600010, 0xFA5995, 0x1c, 0xE2E78C, 0x81
	RegObjTabl 0x160000f, 0xFA62CB, 0x1c, 0xE2F2CE, 0x381
	RegObjTabl 0x1600010, 0xFA5995, 0x8, 0xE2E800, 0x82
	RegObjTabl 0x160000f, 0xFA62CB, 0x8, 0xE2F3AA, 0x382
	RegObjTabl 0x1600010, 0xFA5995, 0x10, 0xE2E824, 0x83
	RegObjTabl 0x160000f, 0xFA62CB, 0x10, 0xE2F3E0, 0x383
	RegObjTabl 0x1600010, 0xFA5995, 0xa, 0xE2E868, 0x84
	RegObjTabl 0x160000f, 0xFA62CB, 0xa, 0xE2F446, 0x384
	RegObjTabl 0x1600010, 0xFA5995, 0x19, 0xE2E894, 0x85
	RegObjTabl 0x160000f, 0xFA62CB, 0x19, 0xE2F488, 0x385
	RegObjTabl 0x1600010, 0xFA5995, 0xb, 0xE2E8FC, 0x86
	RegObjTabl 0x160000f, 0xFA62CB, 0xb, 0xE2F560, 0x386
	RegObjTabl 0x1600010, 0xFA5995, 0x18, 0xE2E92C, 0x87
	RegObjTabl 0x160000f, 0xFA62CB, 0x18, 0xE2F5B2, 0x387
	RegObjTabl 0x1600010, 0xFA5995, 0xc, 0xE2E990, 0x88
	RegObjTabl 0x160000f, 0xFA62CB, 0xc, 0xE2F66A, 0x388
	RegObjTabl 0x1600010, 0xFA5995, 0x4, 0xE2E9C4, 0x8d
	RegObjTabl 0x160000f, 0xFA62CB, 0x4, 0xE2F6C2, 0x38d
	RegObjTabl 0x1600010, 0xFA5995, 0x11, 0xE2E9D8, 0x90
	RegObjTabl 0x160000f, 0xFA62CB, 0x11, 0xE2F6E0, 0x390
	RegObjTabl 0x1600010, 0xFA5995, 0x13, 0xE2EA20, 0x91
	RegObjTabl 0x160000f, 0xFA62CB, 0x13, 0xE2F758, 0x391
	RegObjTabl 0x1600010, 0xFA5995, 0x1a, 0xE2EA70, 0x93
	RegObjTabl 0x160000f, 0xFA62CB, 0x1a, 0xE2F7DC, 0x393
	RegObjTabl 0x1600010, 0xFA5995, 0x4, 0xE2EADC, 0x94
	RegObjTabl 0x160000f, 0xFA62CB, 0x4, 0xE2F898, 0x394
	RegObjTabl 0x1600010, 0xFA5995, 0x1b, 0xE2EAF0, 0x95
	RegObjTabl 0x160000f, 0xFA62CB, 0x1b, 0xE2F8B6, 0x395
	RegObjTabl 0x1600010, 0xFA5995, 0x8, 0xE2EB60, 0x96
	RegObjTabl 0x160000f, 0xFA62CB, 0x8, 0xE2F966, 0x396
	RegObjTabl 0x1600010, 0xFA5995, 0x4, 0xE2EB84, 0x97
	RegObjTabl 0x160000f, 0xFA62CB, 0x4, 0xE2F99C, 0x397
	RegObjTabl 0x1600010, 0xFA5995, 0x1a, 0xE2EB98, 0x98
	RegObjTabl 0x160000f, 0xFA62CB, 0x1a, 0xE2F9BA, 0x398
	RegObjTabl 0x1600010, 0xFA5995, 0x8, 0xE2EC04, 0x99
	RegObjTabl 0x160000f, 0xFA62CB, 0x8, 0xE2FA64, 0x399
	RegObjTabl 0x1600010, 0xFA5995, 0xe, 0xE2EC28, 0x9a
	RegObjTabl 0x160000f, 0xFA62CB, 0xe, 0xE2FA9A, 0x39a
	RegObjTabl 0x1600010, 0xFA5995, 0x16, 0xE2EC64, 0x9b
	RegObjTabl 0x160000f, 0xFA62CB, 0x16, 0xE2FB02, 0x39b
	RegObjTabl 0x1600010, 0xFA5995, 0x15, 0xE2ECC0, 0x9c
	RegObjTabl 0x160000f, 0xFA62CB, 0x15, 0xE2FB9A, 0x39c
	RegObjTabl 0x1600010, 0xFA5995, 0x10, 0xE2ED18, 0x9d
	RegObjTabl 0x160000f, 0xFA62CB, 0x10, 0xE2FC28, 0x39d
	RegObjTabl 0x1600010, 0xFA5995, 0x10, 0xE2ED5C, 0x9e
	RegObjTabl 0x160000f, 0xFA62CB, 0x10, 0xE2FC9A, 0x39e
	RegObjTabl 0x1600010, 0xFA5995, 0x19, 0xE2EDA0, 0x9f
	RegObjTabl 0x160000f, 0xFA62CB, 0x19, 0xE2FD0C, 0x39f
	RegObjTabl 0x1600010, 0xFA5995, 0x10, 0xE2EE08, 0xa0
	RegObjTabl 0x160000f, 0xFA62CB, 0x10, 0xE2FDB4, 0x3a0
	RegObjTabl 0x1600010, 0xFA5995, 0x10, 0xE2EE4C, 0xa1
	RegObjTabl 0x160000f, 0xFA62CB, 0x10, 0xE2FE24, 0x3a1
	RegObjTabl 0x1600010, 0xFA5995, 0x11, 0xE2EE90, 0xa2
	RegObjTabl 0x160000f, 0xFA62CB, 0x11, 0xE2FE96, 0x3a2
	RegObjTabl 0x1600010, 0xFA5995, 0xf, 0xE2EED8, 0xa3
	RegObjTabl 0x160000f, 0xFA62CB, 0xf, 0xE2FF0C, 0x3a3
	RegObjTabl 0x1600010, 0xFA5995, 0x11, 0xE2EF18, 0xa4
	RegObjTabl 0x160000f, 0xFA62CB, 0x11, 0xE2FF78, 0x3a4
	RegObjTabl 0x1600010, 0xFA5995, 0x0, 0xE2EF60, 0xa8
	RegObjTabl 0x160000f, 0xFA62CB, 0x0, 0xE2FFF0, 0x3a8
	RegObjTabl 0x1600010, 0xFA5995, 0x0, 0xE2EF64, 0xaa
	RegObjTabl 0x160000f, 0xFA62CB, 0x0, 0xE2FFF6, 0x3aa
	RegObjTabl 0x1600010, 0xFA5995, 0x2, 0xE2EF68, 0xab
	RegObjTabl 0x160000f, 0xFA62CB, 0x2, 0xE2FFFC, 0x3ab
	RegObjTabl 0x1600010, 0xFA5995, 0xf, 0xE2EF74, 0xd6
	RegObjTabl 0x160000f, 0xFA62CB, 0xf, 0xE3000E, 0x3d6
	RegObjTabl 0x1600010, 0xFA5995, 0x3d, 0xE2EFB4, 0xe7
	RegObjTabl 0x160000f, 0xFA62CB, 0x3d, 0xE3009E, 0x3e7

	RegMode 0x8, 0xe3, 0x2f8, 0x7, 0x1200000, 0x1a000d6
	RegMode 0x8, 0xe3, 0x308, 0x8, 0x1480004, 0x1a00080
	RegMode 0x8, 0xe3, 0x310, 0x9, 0x1480007, 0x1a00083
	RegMode 0x8, 0xe3, 0x31c, 0xa, 0x1480006, 0x1a00081
	RegMode 0x8, 0xe3, 0x328, 0xb, 0x1480005, 0x1a00085
	RegMode 0x8, 0xe3, 0x334, 0xc, 0x1480008, 0x1a00093
	RegMode 0x8, 0xe3, 0x340, 0x14, 0x1480026, 0x1a000e7

	RegTitle 0x8, 0xe3, 0x348, 0xa, 0x1480020, 0xa0000
	RegTitle 0x8, 0xe3, 0x354, 0xb, 0x1480021, 0xb0000
	RegTitle 0x8, 0xe3, 0x360, 0xc, 0x1200000, 0xc0000
	RegTitle 0x8, 0xe3, 0x370, 0xe, 0x1480022, 0xe0000
	RegTitle 0x8, 0xe3, 0x37c, 0x80, 0x1200000, 0x800000
	RegTitle 0x8, 0xe3, 0x386, 0x81, 0x148000a, 0x810000
	RegTitle 0x8, 0xe3, 0x390, 0x82, 0x1200000, 0x820000
	RegTitle 0x8, 0xe3, 0x39c, 0x83, 0x1200000, 0x830000
	RegTitle 0x8, 0xe3, 0x3aa, 0x84, 0x1200000, 0x840000
	RegTitle 0x8, 0xe3, 0x3b6, 0x85, 0x1480009, 0x850000
	RegTitle 0x8, 0xe3, 0x3c4, 0x86, 0x1200000, 0x860000
	RegTitle 0x8, 0xe3, 0x3d0, 0x87, 0x148000b, 0x870000
	RegTitle 0x8, 0xe3, 0x3dc, 0x88, 0x148000c, 0x880000
	RegTitle 0x8, 0xe3, 0x3e8, 0x8d, 0x1200000, 0x8d0000
	RegTitle 0x8, 0xe3, 0x3f4, 0x90, 0x1480013, 0x900000
	RegTitle 0x8, 0xe3, 0x400, 0x91, 0x1480017, 0x910000
	RegTitle 0x8, 0xe3, 0x40c, 0x93, 0x1200000, 0x930000
	RegTitle 0x8, 0xe3, 0x418, 0x94, 0x148001d, 0x940000
	RegTitle 0x8, 0xe3, 0x426, 0x95, 0x148001c, 0x950000
	RegTitle 0x8, 0xe3, 0x434, 0x96, 0x1480024, 0x960000
	RegTitle 0x8, 0xe3, 0x442, 0x97, 0x148001b, 0x970000
	RegTitle 0x8, 0xe3, 0x44e, 0x98, 0x148001a, 0x980000
	RegTitle 0x8, 0xe3, 0x45a, 0x99, 0x1480025, 0x990000
	RegTitle 0x8, 0xe3, 0x468, 0x9a, 0x1480016, 0x9a0000
	RegTitle 0x8, 0xe3, 0x474, 0x9b, 0x1480018, 0x9b0000
	RegTitle 0x8, 0xe3, 0x480, 0x9c, 0x148000d, 0x9c0000
	RegTitle 0x8, 0xe3, 0x48a, 0x9d, 0x1480011, 0x9d0000
	RegTitle 0x8, 0xe3, 0x494, 0x9e, 0x1480010, 0x9e0000
	RegTitle 0x8, 0xe3, 0x4a2, 0x9f, 0x1480012, 0x9f0000
	RegTitle 0x8, 0xe3, 0x4b0, 0xa0, 0x1480019, 0xa00000
	RegTitle 0x8, 0xe3, 0x4bc, 0xa1, 0x148000f, 0xa10000
	RegTitle 0x8, 0xe3, 0x4c6, 0xa2, 0x1480014, 0xa20000
	RegTitle 0x8, 0xe3, 0x4d0, 0xa3, 0x148000e, 0xa30000
	RegTitle 0x8, 0xe3, 0x4da, 0xa4, 0x1480015, 0xa40000
	RegTitle 0x8, 0xe3, 0x4e4, 0xa8, 0x1480017, 0x910000
	RegTitle 0x8, 0xe3, 0x4f0, 0xaa, 0x1200000, 0x8d0000
	RegTitle 0x8, 0xe3, 0x4fc, 0xab, 0x1200000, 0xab0000
	RegTitle 0x8, 0xe3, 0x508, 0xd6, 0x148002a, 0xd60000
	RegTitle 0x8, 0xe3, 0x512, 0xe7, 0x1480027, 0xe70000

	lda xsp, (xsp + 14)
	ret

AutoPunchTtlRqFunc:
	cp xbc, 0x1C00007
	jr nz, IvRealRecCheck_ReturnZero
	bitda 2, 1057
	jr nz, IvRealRecCheck_ReturnZero
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00015
	ld xde, 0x1A00088
	call PostEvent

IvRealRecCheck_ReturnZero:
	lds32 xhl, 0
	ret

IvRealRecExitProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1C00007
	jr z, IvRealRecExit_CheckSendEvent
	cp xiz, 0x1E0003A
	jr z, IvRealRecExit_CopyString
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	jr IvRealRecExit_CallInherited

IvRealRecExit_CopyString:
	pushw 0xE3
	pushw 0x416A
	ld xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	lds32 xhl, 0
	jr IvRealRecExit_Epilogue

IvRealRecExit_CheckSendEvent:
	ld xwa, (xsp + 8)
	ld xbc, 0x1E00053
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jr z, IvRealRecExit_PrepareInherited
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 1
	call SendEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00014
	ld xde, 0x1800008
	call PostEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call PostEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00015
	ld xde, 0x1A00084
	call PostEvent

IvRealRecExit_PrepareInherited:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)

IvRealRecExit_CallInherited:
	call InheritedProc

IvRealRecExit_Epilogue:
	pop xiz
	inc 8, xsp
	ret

AcPanicEditSwProc:
	dec 8, xsp
	push xiz
	ld xiz, xde
	ld (xsp + 4), xbc
	ld (xsp + 8), xwa
	ld xwa, (xsp + 4)
	cp xwa, 0x1C00009
	jrl z, AcPanicEditSw_HandleLostInherited
	cp xwa, 0x1C00008
	jr z, AcPanicEditSw_HandleFocus
	cp xwa, 0x1C0000D
	jr z, AcPanicEditSw_HandleInit
	ld xwa, (xsp + 8)
	ld xbc, (xsp + 4)
	ld xde, xiz
	jrl AcPanicEditSw_CallInherited

AcPanicEditSw_HandleInit:
	ld xwa, (xsp + 8)
	ld xbc, (xsp + 4)
	ld xde, xiz
	call InheritedProc
	ld xwa, (xsp + 8)
	call GetViewInstance
	lds32 xde, 0
	ld e, (xhl + 40)
	ld xwa, (xsp + 8)
	ld xbc, 0x1C0000F
	call SendEvent
	jr AcPanicEditSw_ReturnZero

AcPanicEditSw_HandleFocus:
	ld xwa, (xsp + 8)
	ld xbc, (xsp + 4)
	ld xde, xiz
	call InheritedProc
	ld xwa, (xsp + 8)
	call GetViewInstance
	cp xiz, 0x1
	jr z, AcPanicEditSw_SetMode3
	cp xiz, 0x81
	jr z, AcPanicEditSw_SetMode2
	or xiz, xiz
	jr z, AcPanicEditSw_SetMode1
	cp xiz, 0x80
	jr nz, UI_CheckDisplayModeAndDispatch
	setda_24 0, 135326
	jr UI_CheckDisplayModeAndDispatch

AcPanicEditSw_SetMode1:
	setda_24 1, 135326
	jr UI_CheckDisplayModeAndDispatch

AcPanicEditSw_SetMode2:
	setda_24 2, 135326
	jr UI_CheckDisplayModeAndDispatch

AcPanicEditSw_SetMode3:
	setda_24 3, 135326

UI_CheckDisplayModeAndDispatch:
	ld8_24 c, 0x02109e
	ld a, c
	and a, 0x3
	jr z, AcPanicEditSw_HandleFocusLost
	and c, 0xC
	jr z, AcPanicEditSw_HandleFocusLost
	ld xwa, (xhl + 42)
	ld xbc, (xsp + 4)
	ld xde, xiz
	call ApFuncCall

AcPanicEditSw_ReturnZero:
	lds32 xhl, 0
	jr AcPanicEditSw_Epilogue

AcPanicEditSw_HandleFocusLost:
	ld xwa, (xsp + 8)
	ld xbc, (xsp + 4)
	ld xde, xiz
	jr AcPanicEditSw_CallInherited

AcPanicEditSw_HandleLostInherited:
	ld xwa, (xsp + 8)
	ld xbc, (xsp + 4)
	ld xde, xiz
	call InheritedProc
	cp xiz, 0x1
	jr z, AcPanicEditSw_ClearMode3
	cp xiz, 0x81
	jr z, AcPanicEditSw_ClearMode2
	or xiz, xiz
	jr z, AcPanicEditSw_ClearMode1
	cp xiz, 0x80
	jr nz, EventHandler_FinalizeAndReturn
	resda_24 0, 135326
	jr EventHandler_FinalizeAndReturn

AcPanicEditSw_ClearMode1:
	resda_24 1, 135326
	jr EventHandler_FinalizeAndReturn

AcPanicEditSw_ClearMode2:
	resda_24 2, 135326
	jr EventHandler_FinalizeAndReturn

AcPanicEditSw_ClearMode3:
	resda_24 3, 135326

EventHandler_FinalizeAndReturn:
	ld xwa, (xsp + 8)
	ld xbc, (xsp + 4)
	ld xde, xiz

AcPanicEditSw_CallInherited:
	call InheritedProc

AcPanicEditSw_Epilogue:
	pop xiz
	inc 8, xsp
	ret

PanicFunc:
	cp xbc, 0x1C00008
	jr nz, PanicFunc_ReturnZero
	ld xwa, 0x148002B
	ld xbc, 0x1E80076
	call MainFuncCall

PanicFunc_ReturnZero:
	lds32 xhl, 0
	ret

HelpStsCheck:
	cp xbc, 0x1E0009F
	jr nz, HelpStsCheck_ReturnZero
	lds32 xbc, 0
	ld8_24 c, 0x0340e4
	sll xbc, 2
	lds32 xwa, 0
	ldda8 a, 10606
	sll xwa, 2
	ld xhl, 0x69800
	add xhl, xwa
	sub xhl, xbc
	ret

HelpStsCheck_ReturnZero:
	lds32 xhl, 0
	ret

HelpStsP2Check:
	cp xbc, 0x1E0009F
	jr nz, HelpStsP2Check_ReturnZero
	lds32 xbc, 0
	ld8_24 c, 0x0340e4
	sll xbc, 2
	lds32 xwa, 0
	ldda8 a, 10606
	sll xwa, 2
	st_dri3b W, 0xE1, 0xC8, 0x00
	ld xhl, 0x69800
	add xhl, xwa
	sub xhl, xbc
	ret

HelpStsP2Check_ReturnZero:
	lds32 xhl, 0
	ret

HelpStsP3Check:
	cp xbc, 0x1E0009F
	jr nz, HelpStsP3Check_ReturnZero
	lds32 xbc, 0
	ld8_24 c, 0x0340e4
	sll xbc, 2
	lds32 xwa, 0
	ldda8 a, 10606
	sll xwa, 2
	st_dri3b W, 0xE1, 0x90, 0x01
	ld xhl, 0x69800
	add xhl, xwa
	sub xhl, xbc
	ret

HelpStsP3Check_ReturnZero:
	lds32 xhl, 0
	ret

HelpStsP4Check:
	cp xbc, 0x1E0009F
	jr nz, HelpStsP4Check_ReturnZero
	lds32 xbc, 0
	ld8_24 c, 0x0340e4
	sll xbc, 2
	lds32 xwa, 0
	ldda8 a, 10606
	sll xwa, 2
	st_dri3b W, 0xE1, 0x58, 0x02
	ld xhl, 0x69800
	add xhl, xwa
	sub xhl, xbc
	ret

HelpStsP4Check_ReturnZero:
	lds32 xhl, 0
	ret

HelpMenuCheck:
	cp xbc, 0x1E0009F
	jr nz, HelpMenuCheck_ReturnZero
	ld xhl, 0x988000
	ret

HelpMenuCheck_ReturnZero:
	lds32 xhl, 0
	ret

HelpLangChkFunc:
	push xiz
	ld xiz, xde
	cp xbc, 0x1C00002
	jr z, HelpLangChk_CheckIzZero
	cp xbc, 0x1C00001
	jr nz, HelpLang_ReturnZero
	ld xwa, 0x1480028
	ld xde, xiz
	call MainPostEvent
	jr HelpLang_ReturnZero

HelpLangChk_CheckIzZero:
	or xiz, xiz
	jr nz, HelpLang_ReturnZero
	call GetTitleNow
	cp xhl, 0x1A000E7
	jr z, HelpLang_ReturnZero
	lds wa, 4
	call PanelDisplay_DispatchByMode
	cps hl, 0
	jr z, HelpLang_ReturnZero
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 1
	call SendEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call PostEvent
	stdi8 32578, 72
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00016
	ld xde, 0x1A000EE
	call PostEvent
	ld xwa, 0x1480029
	ld xbc, 0x1E80075
	ld xde, xiz
	call MainFuncCall

HelpLang_ReturnZero:
	lds32 xhl, 0
	pop xiz
	ret

EdMenuPageFunc:
	cp xbc, 0x1C00001
	jr nz, HelpFuncCheck_Return
	or xde, xde
	jr nz, HelpFuncCheck_Return
	call GetTitleOld
	cp xhl, 0x1A00080
	jr nz, HelpFuncCheck_Return
	ld xwa, 0x930002
	ld xbc, 0x1E0007F
	lds32 xde, 1
	call SendEvent

HelpFuncCheck_Return:
	lds32 xhl, 0
	ret

HelpFuncChkFunc:
	push xiz
	ld xiz, xde
	cp xbc, 0x1C00002
	jr z, HelpFunc_CheckIzZero
	cp xbc, 0x1C00001
	jrl nz, HelpFunc_ReturnZero
	or xiz, xiz
	jrl nz, HelpFunc_ReturnZero
	ld xwa, 0xE7001C
	ld xbc, 0x1E0007F
	lds32 xde, 1
	call SendEvent
	ld xwa, 0xE70027
	ld xbc, 0x1E0007F
	lds32 xde, 1
	call SendEvent
	ld xwa, 0xE7002E
	ld xbc, 0x1E0007F
	lds32 xde, 1
	call SendEvent
	jr HelpFunc_ReturnZero

HelpFunc_CheckIzZero:
	or xiz, xiz
	jr nz, HelpFunc_ReturnZero
	call GetTitleNow
	cp xhl, 0x1A000E7
	jr z, HelpFunc_ReturnZero
	lds wa, 4
	call PanelDisplay_DispatchByMode
	cps hl, 0
	jr z, HelpFunc_ReturnZero
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 1
	call SendEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call PostEvent
	stdi8 32578, 72
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00016
	ld xde, 0x1A000EE
	call PostEvent
	ld xwa, 0x1480029
	ld xbc, 0x1E80075
	ld xde, xiz
	call MainFuncCall

HelpFunc_ReturnZero:
	lds32 xhl, 0
	pop xiz
	ret

HelpOkSwFunc:
	cp xbc, 0x1C00007
	jr nz, HelpFunc_ReturnZero2
	ld xwa, 0x1480029
	ld xbc, 0x1E80074
	call MainFuncCall

HelpFunc_ReturnZero2:
	lds32 xhl, 0
	ret

HelpTtlProc:
	lda xsp, (xsp - 74)
	push xiz
	ld xiz, xwa
	cp xbc, 0x1C0000D
	jr z, HelpTtlProc_HandleActivation
	cp xbc, 0x1C00001
	jr z, HelpTtlProc_HandleActivation
	ld xwa, xiz
	call InheritedProc
	jr HelpTtl_Epilogue

HelpTtlProc_HandleActivation:
	ld xwa, xiz
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld xiz, xhl
	ld (xsp + 4), xiz
	ld xwa, (xiz + 32)
	ld xbc, 0x1E00045
	lds32 xde, 0
	call ApFuncCall
	lda xde, (xsp + 56)
	ld (xde), xhl
	lda xwa, (xsp + 8)
	ld (xde + 18), xwa
	ld xwa, (xiz + 32)
	ld xbc, 0x1E00047
	call ApFuncCall
	lda xwa, (xsp + 48)
	ld bc, (xiz + 14)
	ld (xwa), bc
	ld bc, (xiz + 16)
	ld (xwa + 2), bc
	ld bc, (xiz + 18)
	ld (xwa + 4), bc
	ld xde, (xsp + 4)
	ld bc, (xde + 20)
	ld (xwa + 6), bc
	lda xbc, (xsp + 8)
	push xbc
	pushm (xde + 30)
	ld xbc, 0x5B
	lds de, 0
	call DrawTitleBar
	lds32 xhl, 0

HelpTtl_Epilogue:
	pop xiz
	lda xsp, (xsp + 74)
	ret

HelpTtlFunc:
	push xiz
	ld xiz, xwa
	cp xbc, 0x1E00047
	jr z, HelpTtlFunc_DecrementPage
	cp xbc, 0x1E00045
	jr z, HelpTtlFunc_LoadPageCount
	lds32 xhl, 0
	jr HelpTtlFunc_Epilogue

HelpTtlFunc_LoadPageCount:
	lds32 xhl, 0
	ldda8 l, 10606
	jr HelpTtlFunc_Epilogue

HelpTtlFunc_DecrementPage:
	ldda8 a, 10606
	extz wa
	dec 1, wa
	cps wa, 0
	jr lt, HelpTtlFunc_ClampMin
	cp wa, 0x30
	jr le, HelpTtlFunc_LookupSlide

HelpTtlFunc_ClampMin:
	ldw wa, 0x31

HelpTtlFunc_LookupSlide:
	sll wa, 2
	lda_24 xix, 0xe343ee
	ld_sril3 XWA, 0x07, 0xF0, 0xE0
	push xwa
	ld xwa, (xde + 18)
	push xwa
	call Strcpy
	inc 8, xsp
	ld xhl, xiz

HelpTtlFunc_Epilogue:
	pop xiz
	ret

IvSdrevProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1E0003A
	jr z, IvSdrev_CopyString
	cp xiz, 0x1C0000D
	jr z, IvSdrev_HandleFocus
	cp xiz, 0x1C00001
	jr z, IvSdrev_CheckParam
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	jr IvSdrev_Epilogue

IvSdrev_CheckParam:
	ld xwa, (xsp + 4)
	cp xwa, 0x4
	jr z, MasterParam_Return
	cp xwa, 0x3
	jr nz, MasterParam_Return
	ld xwa, 0x4002
	call SndParam_LookupReadOnly
	cps hl, 0
	jr nz, MasterParam_Return
	ld xwa, 0x4002
	ldw bc, 0x7F
	lds de, 3
	call MainLswPut

MasterParam_Return:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	jr IvSdrev_ReturnZero

IvSdrev_HandleFocus:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 8)
	ld xbc, 0x1C0000F
	lds32 xde, 0
	call SendEvent
	jr IvSdrev_ReturnZero

IvSdrev_CopyString:
	pushw 0xE3
	pushw 0x44B6
	ld xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp

IvSdrev_ReturnZero:
	lds32 xhl, 0

IvSdrev_Epilogue:
	pop xiz
	inc 8, xsp
	ret

IvSddspProc:
	lda xsp, (xsp - 12)
	pushw iz
	ld (xsp + 2), xde
	ld (xsp + 6), xbc
	ld (xsp + 10), xwa
	ld xwa, (xsp + 6)
	cp xwa, 0x1E0003A
	jrl z, IvSddsp_CopyString
	cp xwa, 0x1C0000D
	jr z, IvSddsp_HandleFocus
	cp xwa, 0x1C00001
	jr z, IvSddsp_CheckParam
	ld xwa, (xsp + 10)
	ld xbc, (xsp + 6)
	ld xde, (xsp + 2)
	call InheritedProc
	jr IvSddsp_Epilogue

IvSddsp_CheckParam:
	ld xwa, (xsp + 2)
	cp xwa, 0x4
	jr z, FilterParam_Return
	cp xwa, 0x3
	jr nz, FilterParam_Return
	call GetPartSelect
	ld iz, hl
	ld wa, iz
	ldw bc, 0x5D
	call SndParam_LookupViaEncode
	cps hl, 0
	jr nz, FilterParam_Return
	ldada xwa, 37261
	ld bc, iz
	extz xbc
	add xbc, xwa
	ld e, (xbc)
	extz de
	pushw 0x4
	ld wa, iz
	ldw bc, 0x5D
	call MainLswPartPut

FilterParam_Return:
	ld xwa, (xsp + 10)
	ld xbc, (xsp + 6)
	ld xde, (xsp + 2)
	call InheritedProc
	jr IvSddsp_ReturnZero

IvSddsp_HandleFocus:
	ld xwa, (xsp + 10)
	ld xbc, (xsp + 6)
	ld xde, (xsp + 2)
	call InheritedProc
	ld xwa, (xsp + 10)
	ld xbc, 0x1C0000F
	lds32 xde, 0
	call SendEvent
	jr IvSddsp_ReturnZero

IvSddsp_CopyString:
	pushw 0xE3
	pushw 0x44BA
	ld xwa, (xsp + 6)
	push xwa
	call Strcpy
	inc 8, xsp

IvSddsp_ReturnZero:
	lds32 xhl, 0

IvSddsp_Epilogue:
	popw iz
	lda xsp, (xsp + 12)
	ret

IvSdaccProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1E0003A
	jr z, IvSdacc_CopyString
	cp xiz, 0x1C0000D
	jr z, IvSdacc_HandleFocus
	cp xiz, 0x1C00001
	jr z, IvSdacc_CheckParam
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	jr IvSdacc_Epilogue

IvSdacc_CheckParam:
	ld xwa, (xsp + 4)
	cp xwa, 0x4
	jr z, OscillatorParam_Return
	cp xwa, 0x3
	jr nz, OscillatorParam_Return
	ld xwa, 0x4004
	call SndParam_LookupReadOnly
	cps hl, 0
	jr nz, OscillatorParam_Return
	ld xwa, 0x4004
	lds bc, 1
	lds de, 3
	call MainLswPut

OscillatorParam_Return:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	jr IvSdacc_ReturnZero

IvSdacc_HandleFocus:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, (xsp + 8)
	ld xbc, 0x1C0000F
	lds32 xde, 0
	call SendEvent
	jr IvSdacc_ReturnZero

IvSdacc_CopyString:
	pushw 0xE3
	pushw 0x44BE
	ld xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp

IvSdacc_ReturnZero:
	lds32 xhl, 0

IvSdacc_Epilogue:
	pop xiz
	inc 8, xsp
	ret

IvPlayExitProc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 8), xde
	ld (xsp + 12), xbc
	ld xiz, xwa
	ld xwa, (xsp + 12)
	cp xwa, 0x1C00007
	jr z, IvPlayExit_CheckSendEvent
	cp xwa, 0x1E0003A
	jr z, IvPlayExit_CopyString
	ld xwa, xiz
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	jr IvPlayExit_CallInherited

IvPlayExit_CopyString:
	pushw 0xE3
	pushw 0x44C2
	ld xwa, (xsp + 12)
	push xwa
	call Strcpy
	inc 8, xsp
	lds32 xhl, 0
	jr IvPlayExit_Epilogue

IvPlayExit_CheckSendEvent:
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, xiz
	ld xbc, 0x1E00053
	ld xde, (xsp + 8)
	call SendEvent
	or xhl, xhl
	jr z, IvPlayExit_PrepareInherited
	cpdi8 58254, 0
	jr nz, IvPlayExit_ClearFlag
	ld xwa, (xsp + 4)
	ld xde, (xwa + 22)
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00014
	call PostEvent

IvPlayExit_ClearFlag:
	stdi8 58254, 0

IvPlayExit_PrepareInherited:
	ld xwa, xiz
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)

IvPlayExit_CallInherited:
	call InheritedProc

IvPlayExit_Epilogue:
	pop xiz
	lda xsp, (xsp + 12)
	ret

IvPunchExitProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1C00007
	jr z, IvPunchExit_CheckSendEvent
	cp xiz, 0x1E0003A
	jr z, IvPunchExit_CopyString
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	jr IvPunchExit_CallInherited

IvPunchExit_CopyString:
	pushw 0xE3
	pushw 0x44C8
	ld xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	lds32 xhl, 0
	jr IvPunchExit_Epilogue

IvPunchExit_CheckSendEvent:
	ld xwa, (xsp + 8)
	ld xbc, 0x1E00053
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jr z, IvPunchExit_PrepareInherited
	bitda 2, 1057
	jr nz, IvPunchExit_PrepareInherited
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00015
	ld xde, 0x1A00084
	call PostEvent

IvPunchExit_PrepareInherited:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)

IvPunchExit_CallInherited:
	call InheritedProc

IvPunchExit_Epilogue:
	pop xiz
	inc 8, xsp
	ret

IvAutoPunchExitProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1C00007
	jr z, IvAutoPunchExit_CheckSendEvent
	cp xiz, 0x1E0003A
	jr z, IvAutoPunchExit_CopyString
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	jr IvAutoPunchExit_CallInherited

IvAutoPunchExit_CopyString:
	pushw 0xE3
	pushw 0x44CE
	ld xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	lds32 xhl, 0
	jr IvAutoPunchExit_Epilogue

IvAutoPunchExit_CheckSendEvent:
	ld xwa, (xsp + 8)
	ld xbc, 0x1E00053
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jr z, IvAutoPunchExit_PrepareInherited
	cpdi16 10408, 0
	jr z, IvAutoPunchExit_PostSceneEvent
	bitda 2, 1057
	jr nz, IvAutoPunchExit_PrepareInherited

IvAutoPunchExit_PostSceneEvent:
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00015
	ld xde, 0x1A00087
	call PostEvent

IvAutoPunchExit_PrepareInherited:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)

IvAutoPunchExit_CallInherited:
	call InheritedProc

IvAutoPunchExit_Epilogue:
	pop xiz
	inc 8, xsp
	ret

AcIndexWideToggleProc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 8), xde
	ld xiz, xbc
	ld (xsp + 12), xwa
	cp xiz, 0x1C0002A
	jrl z, AcIndexToggle_HandleDefault
	cp xiz, 0x1E8006E
	jrl z, AcIndexToggle_CheckNoteRange
	cp xiz, 0x1C0001B
	jrl z, AcIndexToggle_HandleFocusLost
	cp xiz, 0x1C00007
	jr z, AcIndexToggle_HandleSelectEvent
	cp xiz, 0x1C00001
	jr z, AcIndexToggle_HandleInit
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	jrl AcIndexToggle_CallInherited

AcIndexToggle_HandleInit:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 46)
	ld xbc, 0x1E8006F
	lds32 xde, 0
	call ApFuncCall
	extz xhl
	ld wa, (xiz + 42)
	extz xwa
	sll xwa, 0
	ld xde, xwa
	add xde, xhl
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0002A
	jrl SendNoteDeleteEvent

AcIndexToggle_HandleSelectEvent:
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 12)
	call GetVisible
	cps hl, 0
	jr z, AcIndexToggle_PrepareInherited
	ld xwa, (xsp + 12)
	ld xbc, 0x1E8006E
	ld xde, (xsp + 8)
	call SendEvent
	cps hl, 0
	jr z, AcIndexToggle_PrepareInherited
	ld xwa, (xsp + 4)
	ld de, (xwa + 44)
	exts xde
	ld xwa, (xwa + 46)
	ld xbc, 0x1E80071
	call ApFuncCall
	or xhl, xhl
	jrl nz, SqedtNote_ReturnZero
	ld xwa, (xsp + 4)
	ld de, (xwa + 42)
	cp de, 0xFFFF
	jr z, AcIndexToggle_SendVisibility
	exts xde
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0001B
	call SendEvent

AcIndexToggle_SendVisibility:
	ld xwa, (xsp + 12)
	ld xbc, 0x1E0003B
	lds32 xde, 1
	call SendEvent
	ld xwa, (xsp + 4)
	ld de, (xwa + 44)
	exts xde
	ld xwa, (xwa + 46)
	ld xbc, 0x1E80070
	call ApFuncCall
	ld xwa, 0xE70002
	ld xbc, 0x1C0000D
	lds32 xde, 0
	jrl SendNoteDeleteEvent

AcIndexToggle_PrepareInherited:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)

AcIndexToggle_CallInherited:
	call InheritedProc
	jrl AcIndexToggle_Epilogue

AcIndexToggle_HandleFocusLost:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld wa, (xhl + 42)
	exts xwa
	cp xwa, (xsp + 8)
	jrl nz, SqedtNote_ReturnZero
	ld xwa, (xhl + 34)
	cpw (xwa), 0x0
	jrl z, SqedtNote_ReturnZero
	ld xwa, (xsp + 12)
	ld xbc, 0x1E0003B
	lds32 xde, 0
	jrl SendNoteDeleteEvent

AcIndexToggle_CheckNoteRange:
	ld xwa, (xsp + 12)
	call GetViewInstance
	lda xwa, (xhl + 38)
	lda xhl, (xhl + 40)
	ld bc, (xhl)
	ld de, (xwa)
	ld wa, de
	cp wa, (xhl)
	jr nc, AcIndexToggle_SetFromDE
	ld iz, de
	ldfr_werp BC, 0xFA
	jr AcIndexToggle_SendNoteEvent

AcIndexToggle_SetFromDE:
	ld iz, bc
	ldfr_werp DE, 0xFA

AcIndexToggle_SendNoteEvent:
	ld xwa, 0x2600024
	ld xbc, 0x1E00029
	ld xde, (xsp + 8)
	call SendEvent
	cp hl, iz
	jr c, SqedtNote_ReturnZero
	cp_werp HL, 0xFA
	jr ugt, SqedtNote_ReturnZero
	lds32 xhl, 1
	jr AcIndexToggle_Epilogue

AcIndexToggle_HandleDefault:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, (xsp + 12)
	call GetViewInstance
	lda xwa, (xhl + 42)
	cpw (xwa), 0xFFFF
	jr z, SqedtNote_ReturnZero
	ld xbc, (xsp + 8)
	srl xbc, 0
	ldi_werp 0xE6, 0
	ld de, (xwa)
	ld wa, de
	cp wa, bc
	jr nz, SqedtNote_ReturnZero
	ld xwa, (xsp + 8)
	ld bc, (xhl + 44)
	cp bc, wa
	jr nz, SqedtNote_ReturnZero
	exts xde
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C0001B
	call SendEvent
	ld xwa, (xsp + 12)
	ld xbc, 0x1E0003B
	lds32 xde, 1

SendNoteDeleteEvent:
	call SendEvent

SqedtNote_ReturnZero:
	lds32 xhl, 0

AcIndexToggle_Epilogue:
	pop xiz
	lda xsp, (xsp + 12)
	ret

AcIndexWideToggleFunc:
	ld a, e
	cp xbc, 0x1E80071
	jr z, AcIndexToggleFunc_CheckMatch
	cp xbc, 0x1E80070
	jr z, AcIndexToggleFunc_StoreAndPost
	cp xbc, 0x1E8006F
	jr nz, AcIndexToggleFunc_ReturnZero
	lds32 xhl, 0
	ld8_24 l, 0x0340e4
	ret

AcIndexToggleFunc_StoreAndPost:
	st8_24 0x0340e4, a
	ld xwa, 0x1480028
	call MainPostEvent

AcIndexToggleFunc_ReturnZero:
	lds32 xhl, 0
	ret

AcIndexToggleFunc_CheckMatch:
	cpda8_24 a, 213220
	scc16 z, hl
	extz xhl
	ret

AttAreYouSureCheck:
	cp xbc, 0x1E0009F
	jr nz, AttModePreCheck_ReturnZero
	lda_24 xhl, 0xe344d4
	ret

AttModePreCheck_ReturnZero:
	lds32 xhl, 0
	ret

AttAttentionCheck:
	cp xbc, 0x1E0009F
	jr nz, AttAttentionCheck_ReturnZero
	lda_24 xhl, 0xe344ec
	ret

AttAttentionCheck_ReturnZero:
	lds32 xhl, 0
	ret

StsSeqMenu1Check:
	cp xbc, 0x1E0009F
	jr nz, StsSeqMenu1Check_ReturnZero
	lda_24 xhl, 0xe34504
	ret

StsSeqMenu1Check_ReturnZero:
	lds32 xhl, 0
	ret

StsSeqMenu2Check:
	cp xbc, 0x1E0009F
	jr nz, StsSeqMenu2Check_ReturnZero
	lda_24 xhl, 0xe3451c
	ret

StsSeqMenu2Check_ReturnZero:
	lds32 xhl, 0
	ret

StsEasyRec1Check:
	cp xbc, 0x1E0009F
	jr nz, StsEasyRec1Check_ReturnZero
	lda_24 xhl, 0xe34534
	ret

StsEasyRec1Check_ReturnZero:
	lds32 xhl, 0
	ret

StsEasyRec2Check:
	cp xbc, 0x1E0009F
	jr nz, StsEasyRec2Check_ReturnZero
	lda_24 xhl, 0xe3454c
	ret

StsEasyRec2Check_ReturnZero:
	lds32 xhl, 0
	ret

StsPnlWrtCheck:
	cp xbc, 0x1E0009F
	jr nz, StsPnlWrtCheck_ReturnZero
	lda_24 xhl, 0xe34564
	ret

StsPnlWrtCheck_ReturnZero:
	lds32 xhl, 0
	ret

StsTrkClr1Check:
	cp xbc, 0x1E0009F
	jr nz, StsTrkClr1Check_ReturnZero
	lda_24 xhl, 0xe3457c
	ret

StsTrkClr1Check_ReturnZero:
	lds32 xhl, 0
	ret

StsTrkClr2Check:
	cp xbc, 0x1E0009F
	jr nz, StsTrkClr2Check_ReturnZero
	lda_24 xhl, 0xe34594
	ret

StsTrkClr2Check_ReturnZero:
	lds32 xhl, 0
	ret

StsNtDrEditCheck:
	cp xbc, 0x1E0009F
	jr nz, StsNtDrEditCheck_ReturnZero
	lda_24 xhl, 0xe345ac
	ret

StsNtDrEditCheck_ReturnZero:
	lds32 xhl, 0
	ret

AttTrkClrCheck:
	cp xbc, 0x1E0009F
	jr nz, AttTrkClrCheck_ReturnZero
	lda_24 xhl, 0xe345c4
	ret

AttTrkClrCheck_ReturnZero:
	lds32 xhl, 0
	ret

AttSongClrCheck:
	cp xbc, 0x1E0009F
	jr nz, AttSongClrCheck_ReturnZero
	lda_24 xhl, 0xe345dc
	ret

AttSongClrCheck_ReturnZero:
	lds32 xhl, 0
	ret

StsAtPunchCheck:
	cp xbc, 0x1E0009F
	jr nz, StsAtPunchCheck_ReturnZero
	lda_24 xhl, 0xe345f4
	ret

StsAtPunchCheck_ReturnZero:
	lds32 xhl, 0
	ret

MsgToTtlProc:
	cp xbc, 0x1C00001
	jp_24 nz, 0xFA4409
	call InheritedProc
	call GetTitleOld
	cp xhl, 0x1A000EE
	jr nz, MsgToTtl_ReturnZero
	call CheckNotDrawFlag
	cps hl, 0
	jr z, MsgToTtl_ReturnZero
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 1
	call SendEvent
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1E0009E
	lds32 xde, 0
	call PostEvent
	call GetTitleNow
	cp l, 0x90
	jr nz, MsgToTtl_CheckTitleAndPost
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00015
	ld xde, 0x1A00084
	jr MsgToTtl_PostEvent

MsgToTtl_CheckTitleAndPost:
	call GetTitleNow
	add xhl, 0x1A00000
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00015
	ld xde, xhl

MsgToTtl_PostEvent:
	call PostEvent

MsgToTtl_ReturnZero:
	lds32 xhl, 0
	ret

NoteEditBoxProc:
	lda xsp, (xsp - 94)
	push xiz
	ld (xsp + 90), xde
	ld xiz, xbc
	ld (xsp + 94), xwa
	cp xiz, 0x1C00018
	jrl z, NoteEdit_FormatDispatch
	cp xiz, 0x1C00017
	jrl z, NoteEdit_FormatDispatch
	cp xiz, 0x1C80004
	jrl z, NoteEditBox_GridDispatch2
	cp xiz, 0x1C0000F
	jr z, NoteEditBox_HandleFocusLost
	cp xiz, 0x1C0000B
	jr z, NoteEditBox_HandleFocusGained
	ld xwa, (xsp + 94)
	ld xbc, xiz
	ld xde, (xsp + 90)
	call InheritedProc
	jrl NoteEdit_FormatReturn

NoteEditBox_HandleFocusGained:
	ld xwa, (xsp + 94)
	ld xbc, xiz
	ld xde, (xsp + 90)
	call InheritedProc
	ld xde, (xsp + 94)
	ld xwa, 0x148001F
	ld xbc, xiz
	call MainPostEvent
	ld xwa, (xsp + 94)
	ld xbc, 0x1C00017
	lds32 xde, 0
	call SetDialUp
	ld xwa, (xsp + 94)
	ld xbc, 0x1C00018
	lds32 xde, 0
	call SetDialDown
	lds wa, 1
	call SetDialEnable
	jrl NoteEdit_ReturnZero

NoteEditBox_HandleFocusLost:
	ld xwa, (xsp + 94)
	ld xbc, xiz
	ld xde, (xsp + 90)
	call InheritedProc
	ld xwa, (xsp + 94)
	call GetViewInstance
	ld (xsp + 12), xhl
	ld xwa, (xsp + 12)
	ld xwa, (xwa + 26)
	ld xbc, 0x1E80069
	lds32 xde, 0
	call ApFuncCall
	ld xiy, (xsp + 12)
	cp l, (xiy + 30)
	jrl nz, NoteEdit_ReturnZero
	lda xix, (xsp + 28)
	ld xwa, 0xE33758
	add xwa, (xsp + 90)
	ld a, (xwa)
	extz wa
	ld (xix), wa
	lda xbc, (xix + 2)
	ldw (xbc), 0xB9
	ld xwa, 0xE33764
	add xwa, (xsp + 90)
	ld a, (xwa)
	extz wa
	add wa, (xix)
	lda xde, (xix + 4)
	ld (xde), wa
	lda xhl, (xix + 6)
	ld wa, (xbc)
	add wa, 0x10
	ld (xhl), wa
	ld wa, (xde)
	sub wa, (xix)
	exts xwa
	divs wa, 0x2
	ld ix, (xix)
	add ix, wa
	lda xde, (xsp + 24)
	ld (xde), ix
	ld bc, (xbc)
	ld wa, (xhl)
	sub wa, bc
	exts xwa
	divs wa, 0x2
	add bc, wa
	ld (xde + 2), bc
	ld xwa, (xiy + 26)
	ld xbc, 0x1E00045
	ld xde, (xsp + 90)
	call ApFuncCall
	lda xde, (xsp + 68)
	ld (xde), xhl
	lda xbc, (xsp + 36)
	ld (xde + 18), xbc
	ld xwa, xbc
	lda xbc, (xbc + 32)

; NoteEditBox grid setup dispatch
NoteEditBox_SetupGrid:
	stib_dpi 0xE0, 0x00
	cp xwa, xbc
	jr c, NoteEditBox_SetupGrid
	ld xhl, (xsp + 90)
	ld xwa, (xsp + 12)
	lda xbc, (xwa + 26)
	dec 1, xhl
	cp xhl, 0x0
	jr c, NoteEditBoxProc_SetupGridDisplay
	cp xhl, 0x9
	jr ugt, NoteEditBoxProc_SetupGridDisplay
	add xhl, xhl
	add xhl, 0xE34654
	ld hl, (xhl)
	lda_24 xix, 0xf2f1d9
	jp_dri 8, 0x07, 0xF0, 0xEC
; NoteEditBoxProc event dispatch 1
NoteEditBox_EventDispatch1:
	ld	xwa, (xbc)
	ld	xbc, 31981652
	jr	82
	ld	xwa, (xbc)
	ld	xbc, 31981653
	jr	73
	ld	xwa, (xbc)
	ld	xbc, 31981655
	jr	64
	ld	xwa, (xbc)
	ld	xbc, 31981656
	jr	55
	ld	xwa, (xbc)
	ld	xbc, 31981658
	jr	46
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+26)
	ld	xbc, 31981654
	jr	33
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+26)
	ld	xbc, 31981659
	jr	20
	ld	xwa, (xbc)
	ld	xbc, 31981657
	jr	11

NoteEditBoxProc_SetupGridDisplay:
	ld xwa, (xsp + 12)
	ld xwa, (xwa + 26)
	ld xbc, 0x1E8003E
	call ApFuncCall
	lda xwa, (xsp + 28)
	lda xbc, (xsp + 24)
	lda xde, (xsp + 36)
	lds32 xhl, 0
	push xhl
	pushw 0xFF
	pushw 0xF5
	call DrawStringLeftJustify
	jrl NoteEdit_ReturnZero

; NoteEditBox grid dispatch 2
NoteEditBox_GridDispatch2:
	ld xwa, (xsp + 94)
	call GetViewInstance
	ld (xsp + 12), xhl
	ld xwa, (xsp + 12)
	ld xwa, (xwa + 26)
	ld xbc, 0x1E80069
	lds32 xde, 0
	call ApFuncCall
	ld xwa, (xsp + 12)
	cp l, (xwa + 30)
	jrl nz, NoteEdit_ReturnZero
	ld xwa, (xsp + 90)
	dec 3, xwa
	cp xwa, 0x0
	jrl c, NoteEditBoxProc_ClassifyGridPosition
	cp xwa, 0xB
	jrl ugt, NoteEditBoxProc_ClassifyGridPosition
	add xwa, xwa
	add xwa, 0xE3463C
	ld wa, (xwa)
	lda_24 xix, 0xf2f2a0
	jp_dri 8, 0x07, 0xF0, 0xE0

; NoteEditBoxProc event dispatch 2
NoteEditBox_EventDispatch2:
	.byte 0x1d, 0x67, 0x58, 0xfa, 0xbf, 0x0a, 0x00, 0x03
	.byte 0xeb, 0xcf, 0x95, 0x00, 0xa0, 0x01, 0x6e, 0x04
	.byte 0xbf, 0x0a, 0x00, 0x02, 0xbf, 0x1c, 0x30, 0x8f
	.byte 0x0a, 0x23, 0xd9, 0x12, 0xd9, 0xec, 0x03, 0xf2
	.byte 0x70, 0x37, 0xe3, 0x32, 0xf3, 0x07, 0xe8, 0xe4
	.byte 0x32, 0x92, 0x21, 0xb0, 0x51, 0xb8, 0x02, 0x33
	.byte 0x9a, 0x02, 0x21, 0xb3, 0x51, 0x90, 0x21, 0x9a
	.byte 0x04, 0x81, 0xb8, 0x04, 0x51, 0x93, 0x21, 0x9a
	.byte 0x06, 0x81, 0xb8, 0x06, 0x51, 0xd9, 0xa8, 0x32
	.byte 0xf5, 0x00, 0x1d, 0x59, 0xd5, 0xfa, 0x1d, 0x67
	.byte 0x58, 0xfa, 0xbf, 0x0a, 0x00, 0x07, 0xeb, 0xcf
	.byte 0x95, 0x00, 0xa0, 0x01, 0x6e, 0x04, 0xbf, 0x0a
	.byte 0x00, 0x06, 0xaf, 0x0c, 0x20, 0xa8, 0x1a, 0x20
	.byte 0x41, 0x51, 0x00, 0xe8, 0x01, 0xaf, 0x5a, 0x22
	.byte 0x1d, 0xb7, 0x49, 0xfa, 0xbf, 0x1c, 0x34, 0xb4
	.byte 0x53, 0x94, 0x3f, 0x00, 0x00, 0x66, 0x78, 0xbc
	.byte 0x02, 0x32, 0x8f, 0x0a, 0x21, 0xd8, 0x12, 0xd8
	.byte 0xec, 0x03, 0xf2, 0x70, 0x37, 0xe3, 0x31, 0xf3
	.byte 0x07, 0xe4, 0xe0, 0x31, 0x99, 0x02, 0x20, 0xb2
	.byte 0x50, 0x94, 0x23, 0x99, 0x04, 0x83, 0xbc, 0x04
	.byte 0x30, 0xb0, 0x53, 0x92, 0x25, 0x99, 0x06, 0x85
	.byte 0xbc, 0x06, 0x33, 0xb3, 0x55, 0x90, 0x20, 0x94
	.byte 0xa0, 0xe8, 0x13, 0xd8, 0x0b, 0x02, 0x00, 0x94
	.byte 0x21, 0xd8, 0x81, 0xbf, 0x18, 0x34, 0xb4, 0x51
	.byte 0x92, 0x21, 0x93, 0x20, 0xd9, 0xa0, 0xe8, 0x13
	.byte 0xd8, 0x0b, 0x02, 0x00, 0xd8, 0x81, 0xbc, 0x02
	.long LABEL_E30B51
	.byte 0x0b, 0x0c, 0x46, 0xbf
	.byte 0x28, 0x30, 0x38, 0x1d, 0x4d, 0x0f, 0xff, 0xef
	.byte 0x60, 0xbf, 0x1c, 0x30, 0xbf, 0x18, 0x31, 0xbf
	.byte 0x24, 0x32, 0xeb, 0xa8, 0x3b, 0x0b, 0xfb, 0x00
	.byte 0x0b, 0xf5, 0x00, 0x1d, 0x4a, 0xcf, 0xfa, 0xaf
	.byte 0x0c, 0x20, 0xa8, 0x1a, 0x20, 0x41, 0x52, 0x00
	.byte 0xe8, 0x01, 0xaf, 0x5a, 0x22, 0x1d, 0xb7, 0x49
	.byte 0xfa, 0xbf, 0x1c, 0x34, 0xb4, 0x53, 0xbc, 0x02
	.byte 0x32, 0x8f, 0x0a, 0x21, 0xd8, 0x12, 0xd8, 0xec
	.byte 0x03, 0xf2, 0x70, 0x37, 0xe3, 0x31, 0xf3, 0x07
	.byte 0xe4, 0xe0, 0x31, 0x99, 0x02, 0x20, 0xb2, 0x50
	.byte 0x94, 0x23, 0x99, 0x04, 0x83, 0xbc, 0x04, 0x30
	.byte 0xb0, 0x53, 0x92, 0x25, 0x99, 0x06, 0x85, 0xbc
	.byte 0x06, 0x33, 0xb3, 0x55, 0x90, 0x20, 0x94, 0xa0
	.byte 0xe8, 0x13, 0xd8, 0x0b, 0x02, 0x00, 0x94, 0x21
	.byte 0xd8, 0x81, 0xbf, 0x18, 0x34, 0xb4, 0x51, 0x92
	.byte 0x21, 0x93, 0x20, 0xd9, 0xa0, 0xe8, 0x13, 0xd8
	.byte 0x0b, 0x02, 0x00, 0xd8, 0x81, 0xbc, 0x02, 0x51
	.byte 0x0b, 0xe3, 0x00, 0x0b, 0x10, 0x46, 0xbf, 0x28
	.byte 0x30, 0x38, 0x1d, 0x4d, 0x0f, 0xff, 0xef, 0x60
	.byte 0xbf, 0x1c, 0x30, 0xbf, 0x18, 0x31, 0xbf, 0x24
	.byte 0x32, 0xeb, 0xa8, 0x3b, 0x0b, 0xfb, 0x00, 0x0b
	.byte 0xf5, 0x00, 0x78, 0xad, 0x03, 0xaf, 0x0c, 0x20
	.byte 0xa8, 0x1a, 0x20, 0x41, 0x53, 0x00, 0xe8, 0x01
	.byte 0xaf, 0x5a, 0x22, 0x1d, 0xb7, 0x49, 0xfa, 0xbf
	.byte 0x14, 0x30, 0xb0, 0x53, 0xb8, 0x02, 0x33, 0xf2
	.byte 0x70, 0x37, 0xe3, 0x34, 0x9c, 0x42, 0x21, 0xb3
	.byte 0x51, 0xbf, 0x10, 0x31, 0x90, 0x22, 0xb1, 0x52
	.byte 0x93, 0x22, 0x9c, 0x46, 0x82, 0xb9, 0x02, 0x52
	.byte 0x32, 0xf2, 0x00, 0x1d, 0x8a, 0xa9, 0xfa, 0x78
	.byte 0xf1, 0x05, 0x40, 0x14, 0x00, 0x95, 0x00, 0x41
	.byte 0x0d, 0x00, 0xc0, 0x01, 0xaf, 0x5a, 0x22, 0x68
	.byte 0x0d, 0x40, 0x11, 0x00, 0x98, 0x00, 0x41, 0x0d
	.byte 0x00, 0xc0, 0x01, 0xaf, 0x5a, 0x22, 0x1d, 0x60
	.byte 0x96, 0xfa, 0x78, 0xce, 0x05, 0xaf, 0x0c, 0x20
	.byte 0xa8, 0x1a, 0x20, 0x41, 0x5c, 0x00, 0xe8, 0x01
	.byte 0xea, 0xa8, 0x1d, 0xb7, 0x49, 0xfa, 0xbf, 0x08
	.byte 0x53, 0xbf, 0x0a, 0x02, 0x01, 0x00, 0xc7, 0xfb
	.byte 0xa8, 0xc7, 0xfb, 0x89, 0xd8, 0x12, 0xd8, 0x80
	.byte 0xf2, 0xb8, 0x37, 0xe3, 0x31, 0xd3, 0x07, 0xe4
	.byte 0xe0, 0x20, 0xbf, 0x1c, 0x50, 0xea, 0xa8, 0xc7
	.byte 0xfb, 0x8d, 0xaf, 0x0c, 0x20, 0xa8, 0x1a, 0x20
	.byte 0x41, 0x5d, 0x00, 0xe8, 0x01, 0x1d, 0xb7, 0x49
	.byte 0xfa, 0xeb, 0xe3, 0x66, 0x4c, 0xe8, 0xa8, 0xbf
	.byte 0x04, 0x60, 0xbf, 0x1c, 0x30, 0xb8, 0x02, 0x02
	.byte 0x20, 0x00, 0xb8, 0x06, 0x02, 0x2b, 0x00, 0xc7
	.byte 0xfb, 0xd8, 0x6e, 0x0a, 0x9f, 0x08, 0x04, 0x40
	.long LABEL_E34614
	.byte 0x68, 0x15, 0x9f, 0x08
	.byte 0x20, 0xe8, 0x12, 0xd8, 0x0a, 0x64, 0x00, 0xd7
	.byte 0xe2, 0x88, 0x28, 0xbf, 0x0a, 0x50, 0x40, 0x18
	.byte 0x46, 0xe3, 0x00, 0x38, 0xbf, 0x2a, 0x30, 0x38
	.byte 0x1d, 0x72, 0x0a, 0xff, 0xbf, 0x0a, 0x37, 0x9f
	.byte 0x08, 0x61, 0xbf, 0x0a, 0x02, 0x02, 0x00, 0x68
	.byte 0x29, 0xe8, 0xab, 0xbf, 0x04, 0x60, 0xbf, 0x1c
	.byte 0x30, 0xb8, 0x02, 0x02, 0x21, 0x00, 0xb8, 0x06
	.byte 0x02, 0x2a, 0x00, 0x9f, 0x0a, 0x04, 0x0b, 0xe3
	.byte 0x00, 0x0b, 0x1c, 0x46, 0xbf, 0x2a, 0x30, 0x38
	.byte 0x1d, 0x72, 0x0a, 0xff, 0xbf, 0x0a, 0x37, 0x9f
	.byte 0x0a, 0x61, 0xbf, 0x1c, 0x30, 0x90, 0x21, 0xd9
	.byte 0xc8, 0x20, 0x00, 0xb8, 0x04, 0x51, 0x90, 0xa1
	.byte 0xe9, 0x13, 0xd9, 0x0b, 0x02, 0x00, 0x90, 0x22
	.byte 0xd9, 0x82, 0xbf, 0x18, 0x31, 0xb1, 0x52, 0x98
	.byte 0x02, 0x23, 0x98, 0x06, 0x22, 0xdb, 0xa2, 0xea
	.byte 0x13, 0xda, 0x0b, 0x02, 0x00, 0xda, 0x83, 0xb9
	.byte 0x02, 0x53, 0xbf, 0x24, 0x32, 0xaf, 0x04, 0x23
	.byte 0x3b, 0x0b, 0xff, 0x00, 0x0b, 0xf5, 0x00, 0x1d
	.byte 0x4a, 0xcf, 0xfa, 0xc7, 0xfb, 0x61, 0xc7, 0xfb
	.byte 0xcf, 0x0b, 0x77, 0x14, 0xff, 0x78, 0xc3, 0x04
	.byte 0xaf, 0x0c, 0x20, 0xa8, 0x1a, 0x20, 0x41, 0x5c
	.byte 0x00, 0xe8, 0x01, 0xea, 0xa8, 0x1d, 0xb7, 0x49
	.byte 0xfa, 0xbf, 0x08, 0x53, 0xbf, 0x0a, 0x02, 0x01
	.byte 0x00, 0xc7, 0xfb, 0xa8, 0xc7, 0xfb, 0x89, 0xd8
	.byte 0x12, 0xd8, 0x80, 0xf2, 0xd0, 0x37, 0xe3, 0x31
	.byte 0xd3, 0x07, 0xe4, 0xe0, 0x20, 0xbf, 0x1c, 0x50
	.byte 0xea, 0xa8, 0xc7, 0xfb, 0x8d, 0xaf, 0x0c, 0x20
	.byte 0xa8, 0x1a, 0x20, 0x41, 0x5d, 0x00, 0xe8, 0x01
	.byte 0x1d, 0xb7, 0x49, 0xfa, 0xbf, 0x24, 0x32, 0xbf
	.byte 0x1c, 0x30, 0xb8, 0x02, 0x31, 0xb8, 0x06, 0x34
	.byte 0xeb, 0xe3, 0x66, 0x44, 0xe8, 0xa8, 0xbf, 0x04
	.byte 0x60, 0xb1, 0x02, 0x26, 0x00, 0xb4, 0x02, 0x31
	.byte 0x00, 0xc7, 0xfb, 0xd8, 0x6e, 0x0a, 0x9f, 0x08
	.byte 0x04, 0x40, 0x20, 0x46, 0xe3, 0x00, 0x68, 0x15
	.byte 0x9f, 0x08, 0x20, 0xe8, 0x12, 0xd8, 0x0a, 0x64
	.byte 0x00, 0xd7, 0xe2, 0x88, 0x28, 0xbf, 0x0a, 0x50
	.byte 0x40, 0x24, 0x46, 0xe3, 0x00, 0x38, 0x3a, 0x1d
	.byte 0x72, 0x0a, 0xff, 0xbf, 0x0a, 0x37, 0x9f, 0x08
	.byte 0x61, 0xbf, 0x0a, 0x02, 0x02, 0x00, 0x68, 0x21
	.byte 0xe8, 0xab, 0xbf, 0x04, 0x60, 0xb1, 0x02, 0x28
	.byte 0x00, 0xb4, 0x02, 0x31, 0x00, 0x9f, 0x0a, 0x04
	.byte 0x0b, 0xe3, 0x00, 0x0b, 0x28, 0x46, 0x3a, 0x1d
	.byte 0x72, 0x0a, 0xff, 0xbf, 0x0a, 0x37, 0x9f, 0x0a
	.byte 0x61, 0xbf, 0x1c, 0x30, 0x90, 0x21, 0xd9, 0xc8
	.byte 0x20, 0x00, 0xb8, 0x04, 0x51, 0x90, 0xa1, 0xe9
	.byte 0x13, 0xd9, 0x0b, 0x02, 0x00, 0x90, 0x22, 0xd9
	.byte 0x82, 0xbf, 0x18, 0x31, 0xb1, 0x52, 0x98, 0x02
	.byte 0x23, 0x98, 0x06, 0x22, 0xdb, 0xa2, 0xea, 0x13
	.byte 0xda, 0x0b, 0x02, 0x00, 0xda, 0x83, 0xb9, 0x02
	.byte 0x53, 0xbf, 0x24, 0x32, 0xaf, 0x04, 0x23, 0x3b
	.byte 0x0b, 0xff, 0x00, 0x0b, 0xf5, 0x00, 0x1d, 0x4a
	.byte 0xcf, 0xfa, 0xc7, 0xfb, 0x61, 0xc7, 0xfb, 0xcf
	.byte 0x08, 0x77, 0x18, 0xff, 0x78, 0xbc, 0x03, 0xaf
	.byte 0x0c, 0x20, 0xa8, 0x1a, 0x20, 0x41, 0x5e, 0x00
	.byte 0xe8, 0x01, 0xea, 0xa8, 0x68, 0x1c, 0xaf, 0x0c
	.byte 0x20, 0xa8, 0x1a, 0x20, 0x41, 0x5f, 0x00, 0xe8
	.byte 0x01, 0xea, 0xa8, 0x68, 0x0d, 0xaf, 0x0c, 0x20
	.byte 0xa8, 0x1a, 0x20, 0x41, 0x60, 0x00, 0xe8, 0x01
	.byte 0xea, 0xa8, 0x1d, 0xb7, 0x49, 0xfa, 0x78, 0x8a
	.byte 0x03, 0xbf, 0x1c, 0x34, 0xb4, 0x02, 0x05, 0x00
	.byte 0xbc, 0x02, 0x31, 0xb1, 0x02, 0x63, 0x00, 0xbc
	.byte 0x04, 0x32, 0x94, 0x20, 0xd8, 0xc8, 0x10, 0x00
	.byte 0xb2, 0x50, 0xbc, 0x06, 0x33, 0x91, 0x20, 0xd8
	.byte 0x66, 0xb3, 0x50, 0x92, 0x20, 0x94, 0xa0, 0xe8
	.byte 0x13, 0xd8, 0x0b, 0x02, 0x00, 0x94, 0x24, 0xd8
	.byte 0x84, 0xbf, 0x18, 0x32, 0xb2, 0x54, 0x91, 0x21
	.byte 0x93, 0x20, 0xd9, 0xa0, 0xe8, 0x13, 0xd8, 0x0b
	.byte 0x02, 0x00, 0xd8, 0x81, 0xba, 0x02, 0x51, 0xaf
	.byte 0x0c, 0x20, 0xa8, 0x1a, 0x20, 0x41, 0x45, 0x00
	.byte 0xe0, 0x01, 0xaf, 0x5a, 0x22, 0x1d, 0xb7, 0x49
	.byte 0xfa, 0xbf, 0x44, 0x32, 0xb2, 0x63, 0xbf, 0x24
	.byte 0x31, 0xba, 0x12, 0x61, 0xe9, 0x88, 0xb9, 0x20
	.byte 0x31, 0xf5, 0xe0, 0x00, 0x00, 0xe9, 0xf0, 0x67
	.byte 0xf8, 0xaf, 0x0c, 0x20, 0xa8, 0x1a, 0x20, 0x41
	.byte 0x6a, 0x00, 0xe8, 0x01, 0x1d, 0xb7, 0x49, 0xfa
	.byte 0xbf, 0x1c, 0x30, 0xbf, 0x18, 0x31, 0xbf, 0x24
	.byte 0x32, 0xeb, 0xab, 0x3b, 0x0b, 0x00, 0x00, 0x0b
	.byte 0xff, 0x00, 0x1d, 0x4a, 0xcf, 0xfa, 0xbf, 0x1c
	.byte 0x33, 0xbb, 0x02, 0x31, 0xb1, 0x02, 0x9b, 0x00
	.byte 0xbb, 0x06, 0x32, 0xb2, 0x02, 0xa1, 0x00, 0x9b
	.byte 0x04, 0x20, 0x93, 0xa0, 0xe8, 0x13, 0xd8, 0x0b
	.byte 0x02, 0x00, 0x93, 0x24, 0xd8, 0x84, 0xbf, 0x18
	.byte 0x33, 0xb3, 0x54, 0x91, 0x21, 0x92, 0x20, 0xd9
	.byte 0xa0, 0xe8, 0x13, 0xd8, 0x0b, 0x02, 0x00, 0xd8
	.byte 0x81, 0xbb, 0x02, 0x51, 0xaf, 0x0c, 0x20, 0xa8
	.byte 0x1a, 0x20, 0x41, 0x45, 0x00, 0xe0, 0x01, 0xaf
	.byte 0x5a, 0x22, 0x1d, 0xb7, 0x49, 0xfa, 0xbf, 0x44
	.byte 0x32, 0xb2, 0x63, 0xbf, 0x24, 0x30, 0xba, 0x12
	.byte 0x60, 0xaf, 0x0c, 0x20, 0xa8, 0x1a, 0x20, 0x41
	.byte 0x6b, 0x00, 0xe8, 0x01, 0x1d, 0xb7, 0x49, 0xfa
	.byte 0xbf, 0x1c, 0x30, 0xbf, 0x18, 0x31, 0xbf, 0x24
	.byte 0x32, 0xeb, 0xab, 0x3b, 0x0b, 0x00, 0x00, 0x0b
	.byte 0xff, 0x00, 0x1d, 0x4a, 0xcf, 0xfa, 0x78, 0x7a
	.byte 0x02, 0xaf, 0x0c, 0x20, 0xa8, 0x1a, 0x20, 0x41
	.byte 0x45, 0x00, 0xe0, 0x01, 0xaf, 0x5a, 0x22, 0x1d
	.byte 0xb7, 0x49, 0xfa, 0xbf, 0x44, 0x30, 0xb0, 0x63
	.byte 0xbf, 0x24, 0x31, 0xb8, 0x12, 0x61, 0xe9, 0x88
	.byte 0xb9, 0x20, 0x31, 0xf5, 0xe0, 0x00, 0x00, 0xe9
	.byte 0xf0, 0x67, 0xf8, 0xf2, 0x96, 0x10, 0x02, 0x00
	.byte 0x00, 0xbf, 0x1c, 0x34, 0xb4, 0x02, 0x02, 0x00
	.byte 0xbc, 0x04, 0x32, 0x94, 0x20, 0xd8, 0xc8, 0x18
	.byte 0x00, 0xb2, 0x50, 0xbc, 0x02, 0x31, 0xc2, 0x96
	.byte 0x10, 0x02, 0x21, 0xc9, 0x08, 0x0a, 0xc9, 0xc8
	.byte 0x39, 0xd8, 0x12, 0xb1, 0x50, 0xbc, 0x06, 0x33
	.byte 0xd8, 0x60, 0xb3, 0x50, 0x92, 0x20, 0x94, 0xa0
	.byte 0xe8, 0x13, 0xd8, 0x0b, 0x02, 0x00, 0x94, 0x24
	.byte 0xd8, 0x84, 0xbf, 0x18, 0x32, 0xb2, 0x54, 0x91
	.byte 0x21, 0x93, 0x20, 0xd9, 0xa0, 0xe8, 0x13, 0xd8
	.byte 0x0b, 0x02, 0x00, 0xd8, 0x81, 0xba, 0x02, 0x51
	.byte 0xbf, 0x44, 0x32, 0xaf, 0x0c, 0x20, 0xa8, 0x1a
	.byte 0x20, 0x41, 0x6c, 0x00, 0xe8, 0x01, 0x1d, 0xb7
	.byte 0x49, 0xfa, 0xbf, 0x18, 0x31, 0xc2, 0x96, 0x10
	.byte 0x02, 0x21, 0xc1, 0xa0, 0x27, 0xf1, 0x6e, 0x11
	.byte 0xbf, 0x1c, 0x30, 0xbf, 0x24, 0x32, 0xeb, 0xab
	.byte 0x3b, 0x0b, 0xff, 0x00, 0x0b, 0xf2, 0x00, 0x68
	.byte 0x0f, 0xbf, 0x1c, 0x30, 0xbf, 0x24, 0x32, 0xeb
	.byte 0xab, 0x3b, 0x0b, 0xf2, 0x00, 0x0b, 0xff, 0x00
	.byte 0x1d, 0x4a, 0xcf, 0xfa, 0xbf, 0x1c, 0x34, 0xb4
	.byte 0x02, 0x17, 0x00, 0xbc, 0x04, 0x32, 0x94, 0x20
	.byte 0xd8, 0xc8, 0x46, 0x00, 0xb2, 0x50, 0xbc, 0x02
	.byte 0x31, 0xc2, 0x96, 0x10, 0x02, 0x21, 0xc9, 0x08
	.byte 0x0a, 0xc9, 0xc8, 0x39, 0xd8, 0x12, 0xb1, 0x50
	.byte 0xbc, 0x06, 0x33, 0xd8, 0x60, 0xb3, 0x50, 0x92
	.byte 0x20, 0x94, 0xa0, 0xe8, 0x13, 0xd8, 0x0b, 0x02
	.byte 0x00, 0x94, 0x24, 0xd8, 0x84, 0xbf, 0x18, 0x32
	.byte 0xb2, 0x54, 0x91, 0x21, 0x93, 0x20, 0xd9, 0xa0
	.byte 0xe8, 0x13, 0xd8, 0x0b, 0x02, 0x00, 0xd8, 0x81
	.byte 0xba, 0x02, 0x51, 0xbf, 0x44, 0x32, 0xaf, 0x0c
	.byte 0x20, 0xa8, 0x1a, 0x20, 0x41, 0x6d, 0x00, 0xe8
	.byte 0x01, 0x1d, 0xb7, 0x49, 0xfa, 0xbf, 0x1c, 0x30
	.byte 0xbf, 0x18, 0x31, 0xbf, 0x24, 0x32, 0xeb, 0xab
	.byte 0x3b, 0x0b, 0xf2, 0x00, 0x0b, 0xff, 0x00, 0x1d
	.byte 0x4a, 0xcf, 0xfa, 0xc2, 0x96, 0x10, 0x02, 0x21
	.byte 0xc9, 0x61, 0xf2, 0x96, 0x10, 0x02, 0x41, 0xc9
	.byte 0xcf, 0x0b, 0x73, 0xe4, 0xfe, 0x78, 0x2b, 0x01

NoteEditBoxProc_ClassifyGridPosition:
	ld xwa, (xsp + 90)
	cp xwa, 0x2
	jr z, NoteEditGrid_CheckTitle95
	cp xwa, 0x1
	jr nz, NoteEditGrid_CheckTitle95Alt
	call GetTitleNow
	cp xhl, 0x1A00095
	jr nz, NoteEditGrid_SetCoord3
	ld (xsp + 10), 0x2
	jr NoteEditGrid_LoadCoordinates

NoteEditGrid_SetCoord3:
	ld (xsp + 10), 0x3
	jr NoteEditGrid_LoadCoordinates

NoteEditGrid_CheckTitle95:
	call GetTitleNow
	cp xhl, 0x1A00095
	jr nz, NoteEditGrid_SetCoord5
	ld (xsp + 10), 0x4
	jr NoteEditGrid_LoadCoordinates

NoteEditGrid_SetCoord5:
	ld (xsp + 10), 0x5
	jr NoteEditGrid_LoadCoordinates

NoteEditGrid_CheckTitle95Alt:
	call GetTitleNow
	ld (xsp + 10), 0x1
	cp xhl, 0x1A00095
	jr nz, NoteEditGrid_LoadCoordinates
	ld (xsp + 10), 0x0

NoteEditGrid_LoadCoordinates:
	lda xwa, (xsp + 28)
	ld c, (xsp + 10)
	extz bc
	sla bc, 3
	lda_24 xde, 0xe33770
	st_dri3b B, 0x07, 0xE8, 0xE4
	ld bc, (xde)
	ld (xwa), bc
	lda xhl, (xwa + 2)
	ld bc, (xde + 2)
	ld (xhl), bc
	ld bc, (xwa)
	add bc, (xde + 4)
	ld (xwa + 4), bc
	ld bc, (xhl)
	add bc, (xde + 6)
	ld (xwa + 6), bc
	lds bc, 0
	ldw de, 0xF5
	call DrawDesignBox
	jrl NoteEdit_ReturnZero

; NoteEdit format dispatch
NoteEdit_FormatDispatch:
	ld xwa, (xsp + 94)
	ld xbc, xiz
	ld xde, (xsp + 90)
	call InheritedProc
	ld xwa, (xsp + 90)
	cp xwa, 0xE
	jr ugt, NoteEdit_FormatEntry
	ld xwa, 0x148001F
	ld xbc, 0x1C00017
	call MainDeleteEvent
	ld xwa, 0x148001F
	ld xbc, 0x1C00018
	call MainDeleteEvent
	ld xwa, 0x148001F
	ld xbc, xiz
	ld xde, (xsp + 90)
	call MainPostEvent
	ld xwa, (xsp + 94)
	ld xbc, xiz
	ld xde, (xsp + 90)
	call SetAutoInc

; NoteEdit format entry
NoteEdit_FormatEntry:
	ld xwa, (xsp + 90)
	cp xwa, 0xB
	jr ugt, NoteEdit_ReturnZero
	add xwa, 0xE3462C
	ld wa, (xwa)
	extz wa
	sll wa, 1
	ld xix, 0xE34638
	ld_sriw3 WA, 0x07, 0xF0, 0xE0
	lda_24 xix, 0xf2fa35
	jp_dri 8, 0x07, 0xF0, 0xE0

; NoteEditBoxProc grid check dispatch
NoteEditBox_GridDispatch:
	ld	xwa, (xsp+94)
	ld	xbc, 29360151
	ld	xde, (xsp+90)
	call	16360825
	ld	xwa, (xsp+94)
	ld	xbc, 29360152
	ld	xde, (xsp+90)
	call	16360842

NoteEdit_ReturnZero:
	lds32 xhl, 0

; NoteEdit format return
NoteEdit_FormatReturn:
	pop xiz
	lda xsp, (xsp + 94)
	ret

NoteEditFunc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xwa
	ld xwa, xbc
	cp xbc, 0x1E80069
	jrl z, NoteEdit_GetScreenId
	lda_24 xhl, 0xe337e2
	cp xbc, 0x1E8006B
	jrl z, NoteEdit_FormatNoteNameLow
	cp xbc, 0x1E8006A
	jrl z, NoteEdit_FormatNoteNameHigh
	cp xbc, 0x1E00045
	jrl z, NoteEdit_GetParamValue
	cp xbc, 0x1E8006D
	jrl z, NoteEdit_FormatChordNotes
	cp xbc, 0x1E8006C
	jrl z, NoteEdit_FormatChordType
	cp xbc, 0x1E8003E
	jr z, NoteEdit_FormatTempo
	sub xwa, 0x1E80051
	cp xwa, 0x0
	jrl lt, NoteEdit_DefaultReturn
	cp xwa, 0xF
	jrl gt, NoteEdit_DefaultReturn
	add xwa, xwa
	add xwa, 0xE346F4
	ld wa, (xwa)
	lda_24 xix, 0xf2fad1
	jp_dri 8, 0x07, 0xF0, 0xE0

NoteEdit_FormatTempo:
	ld xiz, xde
	ldda16 xwa, 10052
	cp wa, 0x3E7
	jr ugt, NoteEdit_FormatTempoString
	pushw wa
	pushw 0xE3
	pushw 0x4668
	ld xwa, (xiz + 18)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 10)
	jrl NoteEdit_RestoreAndReturn

NoteEdit_FormatTempoString:
	pushw 0xE3
	pushw 0x466E
	ld xwa, (xiz + 18)
	push xwa
	call Strcpy
	inc 8, xsp
	jrl NoteEdit_RestoreAndReturn
	ld xiz, xde
	ldda16 xwa, 10114
	inc 1, wa
	pushw wa
	ld xwa, 0xE34674
	jrl NoteEdit_PushFormatAndCopy
	ld xiz, xde
	push_sd16w 0x84, 0x27
	ld xwa, 0xE3467A
	jrl NoteEdit_PushFormatAndCopy
	ld xiz, xde
	call GetTitleNow
	ldda8 a, 10118
	extz wa
	cp l, 0x95
	jr nz, NoteEdit_FormatNoteOther
	pushw 0x9
	muls wa, 0x9
	lda_24 xbc, 0xe30946
	exts xwa
	add xwa, xbc
	push xwa
	ld xwa, (xiz + 18)
	push xwa
	call Strncpy
	lda xsp, (xsp + 10)
	jrl NoteEdit_RestoreAndReturn

NoteEdit_FormatNoteOther:
	pushw wa
	ld xwa, 0xE34680
	jrl NoteEdit_PushFormatAndCopy
	ld xiz, xde
	ldda8 a, 10120
	extz wa
	pushw wa
	ld xwa, 0xE34684
	jrl NoteEdit_PushFormatAndCopy
	ld xiz, xde
	ldda8 a, 10122
	extz wa
	pushw wa
	ld xwa, 0xE3468A
	jrl NoteEdit_PushFormatAndCopy
	ld xiz, xde
	push_sd16w 0x8C, 0x27
	ld xwa, 0xE34690
	jrl NoteEdit_PushFormatAndCopy
	ld xiz, xde
	push_sd16w 0x8E, 0x27
	ld xwa, 0xE34694
	jrl NoteEdit_PushFormatAndCopy
	ld xiz, xde
	ldda16 xde, 10130
	cp de, 0x60
	jr z, NoteEdit_GateTime60
	cp de, 0x30
	jr z, NoteEdit_GateTime30
	cp de, 0x20
	jr z, NoteEdit_GateTime20
	cp de, 0x18
	jr z, NoteEdit_GateTime18
	lda xbc, (xiz + 18)
	cp de, 0x10
	jr z, NoteEdit_GateTime10
	cp de, 0xC
	jr z, NoteEdit_GateTime0C
	ld xwa, (xbc)
	cp de, 0x8
	jr nz, NoteEdit_GateTimeNumeric
	pushw 0xE3
	pushw 0x4698
	push xwa
	jr NoteEdit_GateTimeStrcpy

NoteEdit_GateTime0C:
	ld xwa, 0xE346A0
	jr NoteEdit_GateTimePushFormat

NoteEdit_GateTime10:
	ld xwa, 0xE346A8

NoteEdit_GateTimePushFormat:
	push xwa
	ld xwa, (xbc)
	push xwa
	jr NoteEdit_GateTimeStrcpy

NoteEdit_GateTime18:
	ld xwa, 0xE346B0
	jr NoteEdit_GateTimePushAndCopy

NoteEdit_GateTime20:
	ld xwa, 0xE346B8
	jr NoteEdit_GateTimePushAndCopy

NoteEdit_GateTime30:
	ld xwa, 0xE346C0
	jr NoteEdit_GateTimePushAndCopy

NoteEdit_GateTime60:
	ld xwa, 0xE346C8

NoteEdit_GateTimePushAndCopy:
	push xwa
	ld xwa, (xiz + 18)
	push xwa

NoteEdit_GateTimeStrcpy:
	call Strcpy
	inc 8, xsp
	jrl NoteEdit_RestoreAndReturn

NoteEdit_GateTimeNumeric:
	pushw de
	pushw 0xE3
	pushw 0x46D0
	push xwa
	jr NoteEdit_CallAudioSendCmd

NoteEdit_FormatChordType:
	ld xiz, xde
	ldda8 a, 10142
	addda8_24 a, 135318
	extz wa
	pushw wa
	ld xwa, 0xE346D4

NoteEdit_PushFormatAndCopy:
	push xwa
	ld xwa, (xiz + 18)
	push xwa

NoteEdit_CallAudioSendCmd:
	call Audio_SendCommand
	lda xsp, (xsp + 10)
	jrl NoteEdit_RestoreAndReturn

NoteEdit_FormatChordNotes:
	ld xiz, xde
	pushw 0xA
	lds32 xbc, 0
	ld8_24 c, 0x021096
	lds32 xwa, 0
	ldda8 a, 10142
	add xwa, xbc
	ld xbc, 0xD
	call Math_MultiplyAccumulate
	addda32 xhl, 7508
	push xhl
	jrl NoteEdit_DoStrncpy

NoteEdit_GetParamValue:
	dec 1, xde
	cp xde, 0x0
	jr c, NoteEdit_GetTempoValue
	cp xde, 0xD
	jr ugt, NoteEdit_GetTempoValue
	add xde, xde
	add xde, 0xE346D8
	ld de, (xde)
	lda_24 xix, 0xf2fc8a
	jp_dri 8, 0x07, 0xF0, 0xE8
NoteEdit_ParamJumpTable:
	ldda16	hl, 10114
	extz	xhl
	jrl	177
	ldda16	hl, 10116
	extz	xhl
	jrl	168
	lds32	xhl, 0
	ldda8	l, 10118
	jrl	159
	ldda16	hl, 10130
	extz	xhl
	jrl	150
	lds32	xhl, 0
	ldda8	l, 10136
	jrl	141
	lds32	xhl, 0
	ldda8	l, 10142
	jrl	132

NoteEdit_GetTempoValue:
	ldda16 xhl, 10052
	extz xhl
	jr NoteEdit_Epilogue
	ldda16 xhl, 10164
	extz xhl
	jr NoteEdit_Epilogue
	ldda16 xhl, 10166
	extz xhl
	jr NoteEdit_Epilogue
	ldda16 xhl, 10168
	extz xhl
	jr NoteEdit_Epilogue
	ldda16 xhl, 10162
	extz xhl
	jr NoteEdit_Epilogue
	extz de
	ldada xbc, 10148
	extz xde
	add xde, xbc
	lds32 xhl, 0
	ld l, (xde)
	jr NoteEdit_Epilogue
	calr BmDrEdit_ScanForwardInit
	jr NoteEdit_RestoreAndReturn
	calr BmDrEdit_ScanBackwardInit
	jr NoteEdit_RestoreAndReturn
	calr BmDrEdit_RenderSecondaryBlock
	jr NoteEdit_RestoreAndReturn

NoteEdit_FormatNoteNameHigh:
	ld xiz, xde
	pushw 0x6
	ldda8 a, 10136
	inc 1, a
	jr NoteEdit_CopyNoteName

NoteEdit_FormatNoteNameLow:
	ld xiz, xde
	pushw 0x6
	ldda8 a, 10136

NoteEdit_CopyNoteName:
	extz wa
	muls wa, 0x6
	exts xwa
	add xwa, xhl
	push xwa

NoteEdit_DoStrncpy:
	ld xwa, (xiz + 18)
	push xwa
	call Strncpy
	lda xsp, (xsp + 10)

NoteEdit_RestoreAndReturn:
	ld xhl, (xsp + 4)
	jr NoteEdit_Epilogue

NoteEdit_GetScreenId:
	call GetTitleNow
	ldb h, 0x0
	extz xhl
	jr NoteEdit_Epilogue

NoteEdit_DefaultReturn:
	lds32 xhl, 0

NoteEdit_Epilogue:
	pop xiz
	inc 4, xsp
	ret

SngSel2Proc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1C00018
	jr z, LABEL_F2FD71
	cp xiz, 0x1C00017
	jr z, LABEL_F2FD71
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	jr LABEL_F2FDA7

LABEL_F2FD71:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, 0x1C00002
	push xwa
	lds32 xwa, 0
	push xwa
	ld xwa, 0xC8
	ld xbc, (xsp + 16)
	ld xde, 0x810016
	call ResetApTimer
	ld xwa, 0x810011
	ld xbc, xiz
	ld xde, (xsp + 4)
	call SendEvent
	lds32 xhl, 0

LABEL_F2FDA7:
	pop xiz
	inc 8, xsp
	ret

SngSelProc:
	lda xsp, (xsp - 78)
	push xiz
	ld (xsp + 74), xde
	ld xiz, xbc
	ld (xsp + 78), xwa
	cp xiz, 0x1C00018
	jrl z, LABEL_F2FED2
	cp xiz, 0x1C00017
	jrl z, LABEL_F2FED2
	cp xiz, 0x1C0000F
	jr z, LABEL_F2FE05
	cp xiz, 0x1C0000B
	jr z, LABEL_F2FDE8
	ld xwa, (xsp + 78)
	ld xbc, xiz
	ld xde, (xsp + 74)
	call InheritedProc
	jrl LABEL_F2FF04

LABEL_F2FDE8:
	ld xwa, (xsp + 78)
	ld xbc, xiz
	ld xde, (xsp + 74)
	call InheritedProc
	ld xde, (xsp + 78)
	ld xwa, 0x148001E
	ld xbc, xiz
	call MainPostEvent
	jrl StringDraw_CleanupAndReturn

LABEL_F2FE05:
	ld xwa, (xsp + 78)
	ld xbc, xiz
	ld xde, (xsp + 74)
	call InheritedProc
	ld xwa, (xsp + 78)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 30)
	ld xbc, 0x1E80069
	lds32 xde, 0
	call ApFuncCall
	ld xwa, (xsp + 4)
	cp l, (xwa + 34)
	jrl nz, StringDraw_CleanupAndReturn
	ld xwa, (xwa + 30)
	ld xbc, 0x1E00045
	lds32 xde, 0
	call ApFuncCall
	lda xde, (xsp + 52)
	ld (xde), xhl
	lda xwa, (xsp + 20)
	ld (xde + 18), xwa
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 30)
	ld xbc, 0x1E00047
	call ApFuncCall
	lda xbc, (xsp + 12)
	ld xde, (xsp + 4)
	ld wa, (xde + 14)
	ld (xbc), wa
	ld wa, (xde + 16)
	ld (xbc + 2), wa
	lda xwa, (xsp + 20)
	ld xbc, (xde + 22)
	call CalcTotalWidth
	ld xiy, (xsp + 4)
	ld bc, (xiy + 14)
	add bc, hl
	inc 5, bc
	lda xwa, (xsp + 12)
	lda xde, (xwa + 4)
	ld (xde), bc
	lda xix, (xwa + 6)
	ld bc, (xiy + 16)
	add bc, 0x10
	ld (xix), bc
	ld bc, (xde)
	sub bc, (xwa)
	exts xbc
	divs bc, 0x2
	ld de, (xwa)
	add de, bc
	lda xbc, (xsp + 8)
	ld (xbc), de
	ld hl, (xwa + 2)
	ld de, (xix)
	sub de, hl
	exts xde
	divs de, 0x2
	add hl, de
	ld (xbc + 2), hl
	lda xde, (xsp + 20)
	ld xhl, (xiy + 22)
	push xhl
	ld xix, xiy
	pushm (xix + 26)
	ld xhl, xix
	pushm (xhl + 28)
	call DrawStringLeftJustify
	jr StringDraw_CleanupAndReturn

LABEL_F2FED2:
	ld xwa, (xsp + 78)
	ld xbc, xiz
	ld xde, (xsp + 74)
	call InheritedProc
	ld xwa, (xsp + 74)
	cp xwa, 0x3
	jr nz, StringDraw_CleanupAndReturn
	ld xwa, 0x148001E
	ld xbc, xiz
	lds32 xde, 0
	call MainPostEvent
	ld xwa, (xsp + 78)
	ld xbc, xiz
	ld xde, (xsp + 74)
	call SetAutoInc

StringDraw_CleanupAndReturn:
	lds32 xhl, 0

LABEL_F2FF04:
	pop xiz
	lda xsp, (xsp + 78)
	ret

SngSelFunc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xwa
	cp xbc, 0x1E80069
	jr z, LABEL_F2FF88
	cp xbc, 0x1E00045
	jr z, LABEL_F2FF7F
	cp xbc, 0x1E00047
	jr z, LABEL_F2FF2B
	lds32 xhl, 0
	jr ReturnTitleOrZero

LABEL_F2FF2B:
	ld xiz, xde
	pushw 0xE3
	pushw 0x4714
	ld xwa, (xiz + 18)
	push xwa
	call Strcpy
	ld8_24 a, 0x00ffe3
	inc 1, a
	extz wa
	pushw wa
	pushw 0xE3
	pushw 0x471A
	ld xwa, (xiz + 18)
	inc 4, xwa
	push xwa
	call Audio_SendCommand
	lda xbc, (xiz + 18)
	ld xwa, (xbc)
	ld (xwa + 6), 0x3A
	pushw 0x10
	pushw 0x0
	pushw 0xF280
	ld xwa, (xbc)
	inc 7, xwa
	push xwa
	call Strncpy
	lda xsp, (xsp + 28)
	ld xwa, (xiz + 18)
	ld (xwa + 23), 0x0
	ld xhl, (xsp + 4)
	jr ReturnTitleOrZero

LABEL_F2FF7F:
	lds32 xhl, 0
	ld8_24 l, 0x00ffe3
	jr ReturnTitleOrZero

LABEL_F2FF88:
	call GetTitleNow
	ldb h, 0x0
	extz xhl

ReturnTitleOrZero:
	pop xiz
	inc 4, xsp
	ret

PlySngSelFunc:
	ld xhl, xwa
	cp xbc, 0x1C00007
	jr z, LABEL_F2FFF1
	cp xbc, 0x1C00002
	jr z, LABEL_F2FFCE
	cp xbc, 0x1C00001
	jr nz, PlaySong_ReturnZero
	ld xwa, 0x1C00002
	push xwa
	lds32 xwa, 0
	push xwa
	ld xwa, 0xC8
	ld xbc, xhl
	ld xde, 0x810016
	call SetApTimer
	stdi8 58254, 1
	jr PlaySong_ReturnZero

LABEL_F2FFCE:
	call GetTitleNow
	cp xhl, 0x1A00081
	jr nz, LABEL_F2FFEA
	ld xwa, 0x810012
	ld xbc, 0x1C00001
	lds32 xde, 5
	call SendEvent

LABEL_F2FFEA:
	stdi8 58254, 0
	jr PlaySong_ReturnZero

LABEL_F2FFF1:
	ld xwa, 0xC8
	cp xde, 0xF
	jr nz, LABEL_F30000
	lds32 xwa, 0

LABEL_F30000:
	ld xbc, 0x1C00002
	push xbc
	lds32 xbc, 0
	push xbc
	ld xbc, xhl
	ld xde, 0x810016
	call ResetApTimer

PlaySong_ReturnZero:
	lds32 xhl, 0
	ret

PlySngSel2Func:
	cp xbc, 0x1C00007
	jr nz, EntGrid_InitDispatch
	bitda 2, 1057
	jr nz, EntGrid_InitDispatch
	ld xwa, 0x810012
	ld xbc, 0x1C00002
	lds32 xde, 5
	call SendEvent
	ld xwa, 0x810016
	ld xbc, 0x1C00001
	lds32 xde, 5
	call SendEvent

; AcEntertainerGridBoxProc init dispatch
EntGrid_InitDispatch:
	lds32 xhl, 0
	ret

AcEntertainerGridBoxProc:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 12), xde
	ld (xsp + 16), xbc
	ld xiz, xwa
	ld xbc, (xsp + 16)
	cp xbc, 0x1E8000F
	jrl z, EntGrid_CellAction2
	ld xwa, (xsp + 16)
	cp xwa, 0x1E8000E
	jrl z, EntGrid_CellAction1
	cp xwa, 0x1E0008D
	jrl z, EntGrid_CellSelect
	cp xwa, 0x1E0008B
	jrl z, EntGrid_PostReturn
	cp xwa, 0x1E0008A
	jrl z, EntGrid_PostEvent
	cp xwa, 0x1C00001
	jr z, AcEntertainer_EventDispatch
	sub xbc, 0x1C00017
	cp xbc, 0x0
	jrl lt, EntGrid_CellAction3
	cp xbc, 0x6
	jrl gt, EntGrid_CellAction3
	add xbc, xbc
	add xbc, 0xE34742
	ld bc, (xbc)
	lda_24 xix, 0xf300bb
	jp_dri 8, 0x07, 0xF0, 0xE4

; AcEntertainerGridBoxProc event dispatch
AcEntertainer_EventDispatch:
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 8), xhl
	ld xwa, xiz
	ld xbc, 0x1E0008F
	lds32 xde, 0
	call SendEvent
	ld (xsp + 4), xhl
	ld xde, xiz
	ld xwa, 0x1480002
	ld xbc, 0x1C0000B
LABEL_F300EC:
	call MainPostEvent
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldi_werp 0xE2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, xiz
	ld xbc, 0x1C00017
	call SetDialUp
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 0
	ldi_werp 0xE2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, xiz
	ld xbc, 0x1C00018
	call SetDialDown
	lds wa, 1
	call SetDialEnable
	sti8_24 0x02109e, 0x00
	jrl Entertainer_ReturnZeroJmp
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1E00050
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, LABEL_F3019E
	ld xwa, xiz
	ld xbc, 0x1E0008F
	lds32 xde, 0
	call SendEvent
	ld wa, hl
	add wa, wa
	lda_24 xbc, 0xe3471e
	ld_sriw3 WA, 0x07, 0xE4, 0xE0
	sub hl, wa
	extz xhl
	add xhl, 0xFFFF0000
	ld xwa, xiz
	ld xbc, 0x1C0000E
	ld xde, xhl
	call SendEvent
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	jrl Entertainer_ReturnZeroJmp

LABEL_F3019E:
	ld xwa, xiz
	ld xbc, 0x1E00091
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jrl z, Entertainer_ReturnZeroJmp
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call ApFuncCall
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	ld xwa, xiz
	ld xbc, 0x1C00017
	ld xde, (xsp + 12)
	call SetDialUp
	ld xwa, xiz
	ld xbc, 0x1C00018
	ld xde, (xsp + 12)
	call SetDialDown
	lds wa, 1
	jrl LABEL_F302A0
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	ld xbc, 0x1E00050
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, LABEL_F30250
	ld xwa, xiz
	ld xbc, 0x1E0008F
	lds32 xde, 0
	call SendEvent
	ld wa, hl
	add wa, wa
	lda_24 xbc, 0xe34730
	ld_sriw3 WA, 0x07, 0xE4, 0xE0
	add wa, hl
	ld de, wa
	extz xde
	add xde, 0xFFFF0000
	ld xwa, xiz
	ld xbc, 0x1C0000E
	call SendEvent
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	jrl Entertainer_ReturnZeroJmp

LABEL_F30250:
	ld xwa, xiz
	ld xbc, 0x1E00091
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jrl z, Entertainer_ReturnZeroJmp
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call ApFuncCall
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	ld xwa, xiz
	ld xbc, 0x1C00017
	ld xde, (xsp + 12)
	call SetDialUp
	ld xwa, xiz
	ld xbc, 0x1C00018
	ld xde, (xsp + 12)
	call SetDialDown
	lds wa, 1

LABEL_F302A0:
	call SetDialEnable
	jr Entertainer_ReturnZeroJmp

; Entertainer grid post event
EntGrid_PostEvent:
	ld xwa, xiz
	ld xiz, 0x3E
	jr LABEL_F302B6

; Entertainer grid post return
EntGrid_PostReturn:
	ld xwa, xiz
	ld xiz, 0x42

LABEL_F302B6:
	call GetViewInstance
	add xhl, xiz
	ld xwa, (xhl)
	push xwa
	ld xwa, (xsp + 16)
	push xwa
	call Strcpy
	inc 8, xsp
	jr Entertainer_ReturnZeroJmp
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	jr CallApFuncPath

; Entertainer grid cell select
EntGrid_CellSelect:
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	jr CallApFuncPath

; Entertainer grid cell action 1
EntGrid_CellAction1:
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	jr CallApFuncPath

; Entertainer grid cell action 2
EntGrid_CellAction2:
	ld xwa, xiz
	call GetViewInstance
	ld xwa, (xhl + 70)
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)

CallApFuncPath:
	call ApFuncCall

Entertainer_ReturnZeroJmp:
	lds32 xhl, 0
	jr LABEL_F30321

; Entertainer grid cell action 3
EntGrid_CellAction3:
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc

LABEL_F30321:
	pop xiz
	lda xsp, (xsp + 16)
	ret

EntertainerGridCheck:
	lda xsp, (xsp - 62)
	push xiz
	ld (xsp + 58), xde
	ld (xsp + 62), xbc
	ld xiy, 0xE34774
	lda xix, (xsp + 48)
	lds bc, 5
	ldirw
	ld xiy, 0xE3093E
	lda xix, (xsp + 40)
	lds bc, 4
	ldirw
	ld xde, (xsp + 62)
	ld (xsp + 20), xde
	lda_24 xwa, 0xe32390
	ld (xsp + 12), xwa
	lda_24 xwa, 0xe321fa
	ld (xsp + 8), xwa
	lda_24 xwa, 0xe30e60
	ld (xsp + 4), xwa
	lda xwa, (xsp + 48)
	ld (xsp + 28), xwa
	lda xbc, (xsp + 40)
	ldada xwa, 10616
	ld (xsp + 24), xwa
	lda xwa, (xbc + 2)
	ld (xsp + 36), xwa
	lda xwa, (xbc + 4)
	ld (xsp + 32), xwa
	cp xde, 0x1E8000F
	jrl z, EntGridCheck_Default
	lda_24 xwa, 0xe32a7a
	ld (xsp + 16), xwa
	cp xde, 0x1E8000E
	jrl z, EntGridCheck_Return
	ld xwa, xde
	cp xwa, 0x1E0008D
	jrl z, EntGridCheck_Handler
	ld xwa, (xsp + 20)
	sub xwa, 0x1C00017
	cp xwa, 0x0
	jrl lt, SndParam_ReturnZero
	cp xwa, 0x6
	jrl gt, SndParam_ReturnZero
	add xwa, xwa
	add xwa, 0xE347F2
	ld wa, (xwa)
	lda_24 xix, 0xf303d6
	jp_dri 8, 0x07, 0xF0, 0xE0

; SndParam_ReadThenWrite dispatch
SndParam_Dispatch:
	.byte 0x1d, 0xd0, 0x44, 0xfa, 0xeb, 0x88, 0x41, 0x8f
	.byte 0x00, 0xe0, 0x01, 0xea, 0xa8, 0x1d, 0x60, 0x96
	.byte 0xfa, 0xbf, 0x3a, 0x63, 0xbf, 0x28, 0x31, 0xaf
	.byte 0x3a, 0x20, 0xe8, 0xef, 0x00, 0xd7, 0xe2, 0xa8
	.byte 0xb1, 0x50, 0xaf, 0x3a, 0x22, 0xb9, 0x02, 0x52
	.byte 0x91, 0x3f, 0x01, 0x00, 0x7e, 0x33, 0x05, 0xda
	.byte 0x88, 0xd8, 0xd8, 0x75, 0x2c, 0x05, 0xd8, 0xcf
	.byte 0x08, 0x00, 0x7a, 0x25, 0x05, 0xd8, 0x80, 0xf2
	.byte 0xe0, 0x47, 0xe3, 0x34, 0xd3, 0x07, 0xf0, 0xe0
	.byte 0x20, 0xf2, 0x29, 0x04, 0xf3, 0x34, 0xf3, 0x07
	.byte 0xf0, 0xe0, 0xd8, 0xaf, 0x3e, 0x21, 0xda, 0xec
	.byte 0x02, 0xe9, 0xcf, 0x19, 0x00, 0xc0, 0x01, 0x6e
	.byte 0x10, 0xf2, 0x50, 0x47, 0xe3, 0x31, 0xe3, 0x07
	.byte 0xe4, 0xe8, 0x20, 0xd9, 0xac, 0xda, 0xac, 0x68
	.byte 0x0e, 0xf2, 0x50, 0x47, 0xe3, 0x31, 0xe3, 0x07
	.byte 0xe4, 0xe8, 0x20, 0xd9, 0xa9, 0xda, 0xac, 0x1d
	.byte 0x42, 0xf9, 0xf9, 0x78, 0xdc, 0x04, 0x40, 0x02
	.byte 0x00, 0x48, 0x01, 0x41, 0x11, 0x00, 0xe8, 0x01
	.byte 0xea, 0xa9, 0x78, 0xbc, 0x00, 0xda, 0x6d, 0xea
	.byte 0x13, 0xea, 0xc8, 0x00, 0x01, 0x00, 0x00, 0x40
	.byte 0x02, 0x00, 0x48, 0x01, 0x41, 0x12, 0x00, 0xe8
	.byte 0x01, 0x78, 0xa5, 0x00, 0x1d, 0xd0, 0x44, 0xfa
	.byte 0xeb, 0x88, 0x41, 0x8f, 0x00, 0xe0, 0x01, 0xea
	.byte 0xa8, 0x1d, 0x60, 0x96, 0xfa, 0xbf, 0x3a, 0x63
	.byte 0xbf, 0x28, 0x31, 0xaf, 0x3a, 0x20, 0xe8, 0xef
	.byte 0x00, 0xd7, 0xe2, 0xa8, 0xb1, 0x50, 0xaf, 0x3a
	.byte 0x23, 0xb9, 0x02, 0x53, 0x91, 0x3f, 0x01, 0x00
	.byte 0x7e, 0x87, 0x04, 0xdb, 0x88, 0xd8, 0xd8, 0x75
	.byte 0x80, 0x04, 0xd8, 0xcf, 0x08, 0x00, 0x7a, 0x79
	.byte 0x04, 0xd8, 0x80, 0xf2, 0xce, 0x47, 0xe3, 0x34
	.byte 0xd3, 0x07, 0xf0, 0xe0, 0x20, 0xf2, 0xd5, 0x04
	.byte 0xf3, 0x34, 0xf3, 0x07, 0xf0, 0xe0, 0xd8, 0xaf
	.byte 0x3e, 0x22, 0xdb, 0xec, 0x02, 0xf2, 0x50, 0x47
	.byte 0xe3, 0x30, 0xe3, 0x07, 0xe0, 0xec, 0x20, 0xea
	.byte 0xcf, 0x1a, 0x00, 0xc0, 0x01, 0x6e, 0x07, 0x31
	.byte 0xfc, 0xff, 0xda, 0xac, 0x68, 0x05, 0x31, 0xff
	.byte 0xff, 0xda, 0xac, 0x1d, 0x42, 0xf9, 0xf9, 0x78
	.byte 0x38, 0x04, 0x40, 0x02, 0x00, 0x48, 0x01, 0x41
	.byte 0x11, 0x00, 0xe8, 0x01, 0x42, 0xff, 0xff, 0xff
	.byte 0xff, 0x68, 0x16, 0xdb, 0x6d, 0xeb, 0x13, 0xeb
	.byte 0xc8, 0x00, 0xff, 0xff, 0xff, 0x40, 0x02, 0x00
	.byte 0x48, 0x01, 0x41, 0x12, 0x00, 0xe8, 0x01, 0xeb
	.byte 0x8a, 0x1d, 0x5d, 0x9b, 0xfa, 0x78, 0x0a, 0x04
	.byte 0xbf, 0x28, 0x33, 0xb3, 0x02, 0x01, 0x00, 0xbb
	.byte 0x02, 0x32, 0xb2, 0x02, 0x00, 0x00, 0xf2, 0x50
	.byte 0x47, 0xe3, 0x34, 0xaf, 0x3a, 0x26, 0x68, 0x12
	.byte 0xd9, 0x8d, 0xdd, 0xec, 0x02, 0xa6, 0x20, 0xe3
	.byte 0x07, 0xf0, 0xf4, 0xf0, 0x66, 0x0c, 0xd9, 0x61
	.byte 0xb2, 0x51, 0x92, 0x21, 0xd9, 0xcf, 0x09, 0x00
	.byte 0x61, 0xe6, 0xbf, 0x30, 0x31, 0xbb, 0x04, 0x61
	.byte 0xaf, 0x3a, 0x20, 0xa0, 0x23, 0xb8, 0x04, 0x32
	.byte 0xeb, 0xcf, 0x40, 0x41, 0x00, 0x00, 0x66, 0x2a
	.byte 0xeb, 0xcf, 0x41, 0x41, 0x00, 0x00, 0x7e, 0xb9
	.byte 0x03, 0x92, 0x04, 0x0b, 0xe3, 0x00, 0x0b, 0x7e
	.byte 0x47, 0x39, 0x1d, 0x72, 0x0a, 0xff, 0xbf, 0x0a
	.byte 0x37, 0x1d, 0xd0, 0x44, 0xfa, 0xeb, 0x88, 0xbf
	.byte 0x28, 0x32, 0x41, 0x8c, 0x00, 0xe0, 0x01, 0x78
	.byte 0x94, 0x03, 0x40, 0x92, 0x47, 0xe3, 0x00, 0x92
	.byte 0x3f, 0x00, 0x00, 0x66, 0x05, 0x40, 0x88, 0x47
	.byte 0xe3, 0x00, 0x38, 0x39, 0x1d, 0x4d, 0x0f, 0xff
	.byte 0xef, 0x60, 0x1d, 0xd0, 0x44, 0xfa, 0xeb, 0x88
	.byte 0xbf, 0x28, 0x32, 0x41, 0x8c, 0x00, 0xe0, 0x01
	jrl	t, 0x036b

; EntertainerGridCheck handler
EntGridCheck_Handler:
	ld xwa, (xsp + 58)
	srl xwa, 0
	ldi_werp 0xE2, 0
	ld (xbc), wa
	ld xhl, (xsp + 36)
	ld xde, (xsp + 58)
	ld xwa, (xsp + 36)
	ld (xwa), de
	ld xde, (xsp + 28)
	ld (xsp + 20), xde
	ld xwa, (xsp + 32)
	ld (xwa), xde
	cpw (xbc), 0x1
	jrl nz, SndParam_ReturnZero
	ld wa, (xhl)
	sla wa, 2
	lda_24 xbc, 0xe34750
	ld_sril3 XDE, 0x07, 0xE4, 0xE0
	ld xbc, (xsp + 24)
	cp xde, 0x4E13
	jrl z, LABEL_F307BD
	ld xhl, (xsp + 20)
	lda xwa, (xhl + 1)
	ld (xsp + 36), xwa
	lda xwa, (xhl + 2)
	ld (xsp + 32), xwa
	ld xwa, xde
	cp xde, 0x4E12
	jrl z, LABEL_F3076F
	cp xde, 0x4E11
	jrl z, LABEL_F30725
	cp xde, 0x4E10
	jrl z, LABEL_F306DA
	cp xde, 0x4E00
	jr z, LABEL_F306A6
	cp xde, 0x4140
	jr z, LABEL_F30678
	cp xde, 0x4141
	jrl nz, SndParam_ReturnZero
	call SndParam_LookupReadOnly
	pushw hl
	pushw 0xE3
	pushw 0x479C
	lda xwa, (xsp + 54)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 10)
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 40)
	ld xbc, 0x1E0008C
	jrl SndParam_SendEventReturnZero

LABEL_F30678:
	call SndParam_LookupReadOnly
	ld xwa, 0xE347B0
	cps hl, 0
	jr z, LABEL_F3068A
	ld xwa, 0xE347A6

LABEL_F3068A:
	push xwa
	lda xwa, (xsp + 52)
	push xwa
	call Strcpy
	inc 8, xsp
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 40)
	ld xbc, 0x1E0008C
	jrl SndParam_SendEventReturnZero

LABEL_F306A6:
	pushw 0x9
	ldda16 xwa, 10614
	extz xwa
	sll xwa, 2
	ld xbc, (xsp + 18)
	add xbc, xwa
	ld xwa, (xbc)
	push xwa
	ld xwa, (xsp + 26)
	push xwa
	call Strncpy
	lda xsp, (xsp + 10)
	ld (xsp + 57), 0x0
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 40)
	ld xbc, 0x1E0008C
	jrl SndParam_SendEventReturnZero

LABEL_F306DA:
	ld xwa, (xsp + 20)
	ld (xwa), 0x20
	ld xwa, (xsp + 36)
	ld (xwa), 0x20
	pushw 0x5
	ld wa, (xbc)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	ld xwa, (xsp + 6)
	add xwa, xbc
	push xwa
	ld xwa, (xsp + 38)
	push xwa
	call Strncpy
	lda xsp, (xsp + 10)
	lda xwa, (xsp + 48)
	ld (xwa + 7), 0x73
	ld (xwa + 8), 0x20
	ld (xwa + 9), 0x0
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 40)
	ld xbc, 0x1E0008C
	jrl SndParam_SendEventReturnZero

LABEL_F30725:
	ld xwa, (xsp + 20)
	ld (xwa), 0x20
	pushw 0x5
	ld wa, (xbc + 2)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	ld xwa, (xsp + 14)
	add xwa, xbc
	push xwa
	ld xwa, (xsp + 42)
	push xwa
	call Strncpy
	lda xsp, (xsp + 10)
	lda xwa, (xsp + 48)
	ld (xwa + 6), 0x48
	ld (xwa + 7), 0x7A
	ld (xwa + 8), 0x20
	ld (xwa + 9), 0x0
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 40)
	ld xbc, 0x1E0008C
	jrl SndParam_SendEventReturnZero

LABEL_F3076F:
	ld xde, (xsp + 20)
	ld (xde), 0x20
	ld xwa, (xsp + 36)
	ld (xwa), 0x20
	ld xwa, (xsp + 32)
	ld (xwa), 0x20
	pushw 0x5
	ld wa, (xbc + 4)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	ld xwa, (xsp + 10)
	add xwa, xbc
	push xwa
	lda xwa, (xde + 3)
	push xwa
	call Strncpy
	lda xsp, (xsp + 10)
	lda xwa, (xsp + 48)
	ld (xwa + 8), 0x20
	ld (xwa + 9), 0x0
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 40)
	ld xbc, 0x1E0008C
	jrl SndParam_SendEventReturnZero

LABEL_F307BD:
	pushm (xbc + 6)
	pushw 0xE3
	pushw 0x47BA
	ld xwa, (xsp + 26)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 10)
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 40)
	ld xbc, 0x1E0008C
	jrl SndParam_SendEventReturnZero

; EntertainerGridCheck return
EntGridCheck_Return:
	ldw (xbc), 0x1
	ld xwa, (xsp + 36)
	ldw (xwa), 0x4
	ld xwa, (xsp + 32)
	ld xde, (xsp + 28)
	ld (xwa), xde
	pushw 0x9
	ldda16 xwa, 10614
	extz xwa
	sll xwa, 2
	ld xbc, (xsp + 18)
	add xbc, xwa
	ld xwa, (xbc)
	push xwa
	push xde
	call Strncpy
	lda xsp, (xsp + 10)
	ld (xsp + 57), 0x0
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 40)
	ld xbc, 0x1E0008C
	jrl SndParam_SendEventReturnZero

; EntertainerGridCheck default
EntGridCheck_Default:
	ldw (xbc), 0x1
	ld xde, (xsp + 58)
	ld bc, de
	inc 5, bc
	ld xwa, (xsp + 36)
	ld (xwa), bc
	ld xbc, (xsp + 28)
	ld (xsp + 20), xbc
	ld xwa, (xsp + 32)
	ld (xwa), xbc
	ld (xbc), 0x20
	ld xwa, xbc
	inc 2, xwa
	ld (xsp + 36), xwa
	cp xde, 0x3
	jrl z, LABEL_F3090F
	ld xwa, (xsp + 20)
	lda xbc, (xwa + 1)
	cp xde, 0x2
	jr z, LABEL_F308D4
	ld xwa, xde
	cp xwa, 0x1
	jr z, LABEL_F308A3
	or xwa, xwa
	jrl nz, SndParam_BuildDisplayEvent
	ld (xbc), 0x20
	pushw 0x5
	ld xwa, (xsp + 26)
	ld wa, (xwa)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	ld xwa, (xsp + 6)
	add xwa, xbc
	push xwa
	ld xwa, (xsp + 42)
	push xwa
	call Strncpy
	lda xsp, (xsp + 10)
	lda xwa, (xsp + 48)
	ld (xwa + 7), 0x73
	ld (xwa + 8), 0x20
	jr LABEL_F30909

LABEL_F308A3:
	pushw 0x5
	ld xwa, (xsp + 26)
	ld wa, (xwa + 2)
	extz xwa
	ld xde, xwa
	sll xde, 2
	add xde, xwa
	ld xwa, (xsp + 14)
	add xwa, xde
	push xwa
	push xbc
	call Strncpy
	lda xsp, (xsp + 10)
	lda xwa, (xsp + 48)
	ld (xwa + 6), 0x48
	ld (xwa + 7), 0x7A
	ld (xwa + 8), 0x20
	jr LABEL_F30909

LABEL_F308D4:
	ld (xbc), 0x20
	ld xwa, (xsp + 36)
	ld (xwa), 0x20
	pushw 0x5
	ld xwa, (xsp + 26)
	ld wa, (xwa + 4)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	ld xwa, (xsp + 10)
	add xwa, xbc
	push xwa
	ld xwa, (xsp + 26)
	inc 3, xwa
	push xwa
	call Strncpy
	lda xsp, (xsp + 10)
	lda xwa, (xsp + 48)
	ld (xwa + 8), 0x20

LABEL_F30909:
	ld (xwa + 9), 0x0
	jr SndParam_BuildDisplayEvent

LABEL_F3090F:
	ld xwa, (xsp + 24)
	pushm (xwa + 6)
	pushw 0xE3
	pushw 0x47C4
	ld xwa, (xsp + 26)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 10)

SndParam_BuildDisplayEvent:
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 40)
	ld xbc, 0x1E0008C

SndParam_SendEventReturnZero:
	call SendEvent

SndParam_ReturnZero:
	lds32 xhl, 0
	pop xiz
	lda xsp, (xsp + 62)
	ret

IvSongCopyExitProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1C00007
	jr z, LABEL_F30978
	cp xiz, 0x1E0003A
	jr z, LABEL_F30964
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	jr LABEL_F309CF

LABEL_F30964:
	pushw 0xE3
	pushw 0x4800
	ld xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	lds32 xhl, 0
	jr LABEL_F309D3

LABEL_F30978:
	ld xwa, (xsp + 8)
	ld xbc, 0x1E00053
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jr z, LABEL_F309C7
	call GetTitleNow
	cp xhl, 0x1A00091
	jr nz, LABEL_F309A8
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00015
	ld xde, 0x1A00093
	jr LABEL_F309C3

LABEL_F309A8:
	call GetTitleNow
	cp xhl, 0x1A000A8
	jr nz, LABEL_F309C7
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00015
	ld xde, 0x1A00084

LABEL_F309C3:
	call PostEvent

LABEL_F309C7:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)

LABEL_F309CF:
	call InheritedProc

LABEL_F309D3:
	pop xiz
	inc 8, xsp
	ret

IvPnlWrExitProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, 0x1C00007
	jr z, LABEL_F30A10
	cp xiz, 0x1E0003A
	jr z, LABEL_F309FC
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	jr LABEL_F30A67

LABEL_F309FC:
	pushw 0xE3
	pushw 0x4806
	ld xwa, (xsp + 8)
	push xwa
	call Strcpy
	inc 8, xsp
	lds32 xhl, 0
	jr LABEL_F30A6B

LABEL_F30A10:
	ld xwa, (xsp + 8)
	ld xbc, 0x1E00053
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jr z, LABEL_F30A5F
	call GetTitleNow
	cp xhl, 0x1A0008D
	jr nz, LABEL_F30A40
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00015
	ld xde, 0x1A00084
	jr LABEL_F30A5B

LABEL_F30A40:
	call GetTitleNow
	cp xhl, 0x1A000AA
	jr nz, LABEL_F30A5F
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00015
	ld xde, 0x1A00080

LABEL_F30A5B:
	call PostEvent

LABEL_F30A5F:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)

LABEL_F30A67:
	call InheritedProc

LABEL_F30A6B:
	pop xiz
	inc 8, xsp
	ret

SqplyValProc:
	lda xsp, (xsp - 70)
	push_werp 0xFA
	ld (xsp + 60), xde
	ld (xsp + 64), xbc
	ld (xsp + 68), xwa
	ld xwa, (xsp + 64)
	cp xwa, 0x1C00007
	jrl z, SqplyVal_HandleSelectEvent
	cp xwa, 0x1C00018
	jrl z, SqplyVal_HandleDownScrollEvent
	cp xwa, 0x1C00017
	jrl z, SqplyVal_HandleUpScrollEvent
	cp xwa, 0x1C0000F
	jrl z, SqplyVal_HandleScrollEvent
	cp xwa, 0x1C0000B
	jr z, SqplyVal_HandleInitEvent
	ld xwa, (xsp + 68)
	ld xbc, (xsp + 64)
	ld xde, (xsp + 60)
	call InheritedProc
	jrl SqplyVal_Epilogue

SqplyVal_HandleInitEvent:
	ld xwa, (xsp + 68)
	ld xbc, (xsp + 64)
	ld xde, (xsp + 60)
	call InheritedProc
	ld xwa, (xsp + 68)
	call GetViewInstance
	ld (xsp + 6), xhl
	call GetTitleNow
	cp l, 0x82
	jr z, SqplyVal_InitScrollAndRefresh
	cp l, 0x86
	jr z, SqplyVal_InitScrollAndRefresh
	cp l, 0x88
	jr z, SqplyVal_InitScrollAndRefresh
	cp l, 0x96
	jr z, SqplyVal_InitScrollAndRefresh
	cp l, 0x99
	jr nz, SqplyVal_CheckMode81

SqplyVal_InitScrollAndRefresh:
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 26)
	ld xbc, 0x1E80035
	lds32 xde, 1
	call ApFuncCall
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00007
	ld xde, 0x89
	call SendEvent
	ld xwa, (xsp + 68)
	ld xbc, 0x1C00017
	lds32 xde, 1
	call SetDialUp
	ld xwa, (xsp + 68)
	ld xbc, 0x1C00018
	lds32 xde, 1
	call SetDialDown
	lds wa, 1
	call SetDialEnable
	jr SqplyVal_DispatchUpdate

SqplyVal_CheckMode81:
	cp l, 0x81
	jr nz, SqplyVal_DispatchUpdate
	ld xwa, 0x810016
	ld xbc, 0x1C00002
	lds32 xde, 5
	call SendEvent
	ld xwa, 0x810012
	ld xbc, 0x1C00001
	lds32 xde, 5
	call SendEvent
	stdi8 58254, 0

SqplyVal_DispatchUpdate:
	ld xde, (xsp + 68)
	ld xwa, 0x1480003
	ld xbc, (xsp + 64)
	call MainPostEvent
	jrl SqplyVal_ReturnZero

SqplyVal_HandleScrollEvent:
	ld xwa, (xsp + 68)
	ld xbc, (xsp + 64)
	ld xde, (xsp + 60)
	call InheritedProc
	ld xwa, (xsp + 68)
	call GetViewInstance
	ld (xsp + 6), xhl
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 26)
	ld xbc, 0x1E80069
	lds32 xde, 0
	call ApFuncCall
	ld xiy, (xsp + 6)
	cp l, (xiy + 30)
	jrl nz, SqplyVal_ReturnZero
	lda xhl, (xsp + 52)
	ld xwa, (xsp + 60)
	sll xwa, 3
	ld xde, 0xE3358A
	add xde, xwa
	ld wa, (xde)
	ld (xhl), wa
	lda xbc, (xhl + 2)
	ld wa, (xde + 2)
	ld (xbc), wa
	ld ix, (xhl)
	add ix, (xde + 4)
	lda xwa, (xhl + 4)
	ld (xwa), ix
	ld ix, (xbc)
	add ix, (xde + 6)
	lda xde, (xhl + 6)
	ld (xde), ix
	ld wa, (xwa)
	sub wa, (xhl)
	exts xwa
	divs wa, 0x2
	ld ix, (xhl)
	add ix, wa
	lda xhl, (xsp + 48)
	ld (xhl), ix
	ld bc, (xbc)
	ld wa, (xde)
	sub wa, bc
	exts xwa
	divs wa, 0x2
	add bc, wa
	ld (xhl + 2), bc
	ld xwa, (xiy + 26)
	ld xbc, 0x1E00045
	ld xde, (xsp + 60)
	call ApFuncCall
	lda xde, (xsp + 10)
	ld (xde), xhl
	lda xhl, (xsp + 32)
	ld xwa, xhl
	lda xbc, (xhl + 16)

SqplyVal_ClearDrawBuffer:
	stib_dpi 0xE0, 0x00
	cp xwa, xbc
	jr c, SqplyVal_ClearDrawBuffer
	ld (xde + 18), xhl
	ld xwa, (xsp + 60)
	cp xwa, 0x2
	jr z, SqplyVal_RenderNoteGrid2
	cp xwa, 0x1
	jr z, SqplyVal_RenderNoteGrid1
	cp xwa, 0x7
	jr z, SqplyVal_RenderNoteGrid0
	cp xwa, 0x3
	jr z, SqplyVal_RenderNoteGrid0
	or xwa, xwa
	jr nz, SqplyVal_HandleExtraParams

SqplyVal_RenderNoteGrid0:
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 26)
	ld xbc, 0x1E8003E
	call ApFuncCall
	lda xwa, (xsp + 52)
	lda xbc, (xsp + 48)
	lda xde, (xsp + 32)
	lds32 xhl, 0
	push xhl
	ld xhl, (xsp + 10)
	pushm (xhl + 22)
	pushm (xhl + 24)
	jr SqplyVal_CallDrawGrid

SqplyVal_RenderNoteGrid1:
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 26)
	ld xbc, 0x1E8003F
	call ApFuncCall
	lda xwa, (xsp + 52)
	lda xbc, (xsp + 48)
	lda xde, (xsp + 32)
	lds32 xhl, 0
	push xhl
	ld xhl, (xsp + 10)
	pushm (xhl + 22)
	pushm (xhl + 24)
	jr SqplyVal_CallDrawGrid

SqplyVal_RenderNoteGrid2:
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 26)
	ld xbc, 0x1E80040
	call ApFuncCall
	lda xwa, (xsp + 52)
	lda xbc, (xsp + 48)
	lda xde, (xsp + 32)
	lds32 xhl, 0
	push xhl
	ld xhl, (xsp + 10)
	pushm (xhl + 22)
	pushm (xhl + 24)

SqplyVal_CallDrawGrid:
	call DrawStringLeftJustify
	jrl SqplyVal_ReturnZero

SqplyVal_HandleExtraParams:
	ld xhl, (xsp + 60)
	ld xwa, (xsp + 6)
	lda xbc, (xwa + 26)
	dec 4, xhl
	cp xhl, 0x0
	jrl c, SqplyVal_ReturnZero
	cp xhl, 0x7
	jrl ugt, SqplyVal_ReturnZero
	add xhl, xhl
	add xhl, 0xE3480C
	ld hl, (xhl)
	lda_24 xix, 0xf30cf0
	jp_dri 8, 0x07, 0xF0, 0xEC
SqplyVal_ExtraParamsData:
	.byte 0xa1, 0x20, 0x41, 0x41, 0x00, 0xe8, 0x01, 0x1d
	.byte 0xb7, 0x49, 0xfa, 0xaf, 0x06, 0x20, 0xa8, 0x1a
	.byte 0x20, 0x41, 0x38, 0x00, 0xe8, 0x01, 0xaf, 0x3c
	.byte 0x22, 0x1d, 0xb7, 0x49, 0xfa, 0xbf, 0x34, 0x30
	.byte 0xbf, 0x30, 0x31, 0xbf, 0x20, 0x32, 0xeb, 0xe3
	.byte 0x66, 0x41, 0xeb, 0xa8, 0x3b, 0x0b, 0x00, 0x00
	.byte 0x0b, 0xff, 0x00, 0x68, 0x42, 0xa1, 0x20, 0x41
	.byte 0x42, 0x00, 0xe8, 0x01, 0x68, 0xc9, 0xa1, 0x20
	.byte 0x41, 0x43, 0x00, 0xe8, 0x01, 0x68, 0xc0, 0xa1
	.byte 0x20, 0x41, 0x4e, 0x00, 0xe8, 0x01, 0x68, 0xb7
	.byte 0xa1, 0x20, 0x41, 0x4f, 0x00, 0xe8, 0x01, 0x68
	.byte 0xae, 0xa1, 0x20, 0x41, 0x50, 0x00, 0xe8, 0x01
	.byte 0x68, 0xa5, 0xa1, 0x20, 0x41, 0x47, 0x00, 0xe8
	.byte 0x01, 0x68, 0x9c, 0xeb, 0xa8, 0x3b, 0xaf, 0x0a
	.byte 0x23, 0x9b, 0x16, 0x04, 0x9b, 0x18, 0x04, 0x1d
	.byte 0x4a, 0xcf, 0xfa, 0xaf, 0x44, 0x20, 0x41, 0x17
	.byte 0x00, 0xc0, 0x01, 0xea, 0xa9, 0x1d, 0x79, 0xa5
	.byte 0xf9, 0xaf, 0x44, 0x20, 0x41, 0x18, 0x00, 0xc0
	.byte 0x01, 0xea, 0xa9, 0x1d, 0x8a, 0xa5, 0xf9, 0xd8
	.byte 0xa9, 0x78, 0x87, 0x01

SqplyVal_HandleUpScrollEvent:
	ld xwa, (xsp + 68)
	ld xbc, (xsp + 64)
	ld xde, (xsp + 60)
	call InheritedProc
	ld xwa, (xsp + 68)
	call GetViewInstance
	ld (xsp + 6), xhl
	ld xwa, (xsp + 60)
	cp xwa, 0x1
	jr nz, SqplyVal_UpScroll_Mode2
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 26)
	ld xbc, 0x1E80036
	lds32 xde, 0
	call ApFuncCall
	ldfr_berp L, 0xFB
	ldto_berp E, 0xFB
	exts de
	exts xde
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 26)
	ld xbc, 0x1E80037
	call ApFuncCall
	ldfr_berp L, 0xFB
	ldto_berp E, 0xFB
	exts de
	exts xde
	ld xwa, 0x1480003
	ld xbc, 0x1E80014
	call MainPostEvent
	ld xwa, (xsp + 68)
	ld xbc, (xsp + 64)
	ld xde, (xsp + 60)
	call SetAutoInc
	jrl SqplyVal_ReturnZero

SqplyVal_UpScroll_Mode2:
	ld xwa, (xsp + 60)
	cp xwa, 0x2
	jrl nz, SqplyVal_ReturnZero
	bitda 2, 1057
	jrl nz, SqplyVal_ReturnZero
	ld xwa, 0x1480003
	ld xbc, 0x1E80014
	lds32 xde, 0
	call MainPostEvent
	ld xwa, (xsp + 68)
	ld xbc, (xsp + 64)
	ld xde, (xsp + 60)
	call SetAutoInc
	ld xwa, (xsp + 68)
	ld xbc, 0x1C00017
	lds32 xde, 2
	call SetDialUp
	ld xwa, (xsp + 68)
	ld xbc, 0x1C00018
	lds32 xde, 2
	call SetDialDown
	lds wa, 1
	jrl SqplyVal_CallSortedUpdate

SqplyVal_HandleDownScrollEvent:
	ld xwa, (xsp + 68)
	ld xbc, (xsp + 64)
	ld xde, (xsp + 60)
	call InheritedProc
	ld xwa, (xsp + 68)
	call GetViewInstance
	ld (xsp + 6), xhl
	ld xwa, (xsp + 60)
	cp xwa, 0x1
	jr nz, SqplyVal_DownScroll_Mode2
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 26)
	ld xbc, 0x1E80036
	lds32 xde, 0
	call ApFuncCall
	ldfr_berp L, 0xFB
	ldto_berp E, 0xFB
	exts de
	exts xde
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 26)
	ld xbc, 0x1E80037
	call ApFuncCall
	ldfr_berp L, 0xFB
	ldto_berp E, 0xFB
	exts de
	exts xde
	ld xwa, 0x1480003
	ld xbc, 0x1E80015
	call MainPostEvent
	ld xwa, (xsp + 68)
	ld xbc, (xsp + 64)
	ld xde, (xsp + 60)
	call SetAutoInc
	jrl SqplyVal_ReturnZero

SqplyVal_DownScroll_Mode2:
	ld xwa, (xsp + 60)
	cp xwa, 0x2
	jrl nz, SqplyVal_ReturnZero
	bitda 2, 1057
	jrl nz, SqplyVal_ReturnZero
	ld xwa, 0x1480003
	ld xbc, 0x1E80015
	lds32 xde, 0
	call MainPostEvent
	ld xwa, (xsp + 68)
	ld xbc, (xsp + 64)
	ld xde, (xsp + 60)
	call SetAutoInc
	ld xwa, (xsp + 68)
	ld xbc, 0x1C00017
	lds32 xde, 2
	call SetDialUp
	ld xwa, (xsp + 68)
	ld xbc, 0x1C00018
	lds32 xde, 2
	call SetDialDown
	lds wa, 1

SqplyVal_CallSortedUpdate:
	call SetDialEnable
	jrl SqplyVal_ReturnZero

SqplyVal_HandleSelectEvent:
	ld xwa, (xsp + 68)
	ld xbc, (xsp + 64)
	ld xde, (xsp + 60)
	call InheritedProc
	ld xwa, (xsp + 68)
	call GetViewInstance
	ld (xsp + 6), xhl
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 26)
	ld xbc, 0x1E80036
	lds32 xde, 0
	call ApFuncCall
	ld (xsp + 2), l
	ld xwa, (xsp + 60)
	cp xwa, 0xC
	jr z, SqplyVal_SelectTrack
	cp xwa, 0xB
	jr z, SqplyVal_SelectTrack
	cp xwa, 0xA
	jr z, SqplyVal_SelectTrack
	cp xwa, 0x9
	jr z, SqplyVal_SelectTrack
	cp xwa, 0x8
	jr z, SqplyVal_SelectTrack
	cp xwa, 0x8C
	jr z, SqplyVal_SelectTrack
	cp xwa, 0x8B
	jrl z, SqplyVal_SelectTrack_SetPart3
	cp xwa, 0x8A
	jrl z, SqplyVal_SelectTrack_SetPart2
	cp xwa, 0x89
	jrl z, SqplyVal_SelectTrack_SetPart1
	cp xwa, 0x88
	jrl nz, SqplyVal_ReturnZero

SqplyVal_SelectTrack:
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 26)
	ld xbc, 0x1E80036
	lds32 xde, 0
	call ApFuncCall
	ld (xsp + 4), l
	lds32 xde, 0
	ld e, (xsp + 2)
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 26)
	ld xbc, 0x1E80037
	call ApFuncCall
	ldfr_berp L, 0xFB
	ld xwa, (xsp + 6)
	lda xbc, (xwa + 26)
	cpi_berp 0xFB, 0
	jr lt, SqplyVal_SelectTrack_NegRange
	lds32 xde, 0
	ld e, (xsp + 2)
	ld xwa, (xbc)
	ld xbc, 0x1E80035
	call ApFuncCall
	ldto_berp E, 0xFB
	exts de
	exts xde
	ld xwa, (xsp + 68)
	ld xbc, 0x1C0000F
	call SendEvent
	ld a, (xsp + 2)
	cp a, (xsp + 4)
	jr z, SqplyVal_ReturnZero
	lds32 xde, 0
	ld e, (xsp + 4)
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 26)
	ld xbc, 0x1E80037
	call ApFuncCall
	ldfr_berp L, 0xFB
	cpi_berp 0xFB, 0
	jr lt, SqplyVal_ReturnZero
	ldto_berp E, 0xFB
	exts de
	exts xde
	ld xwa, (xsp + 68)
	ld xbc, 0x1C0000F
	jr SqplyVal_DispatchScrollCmd

SqplyVal_SelectTrack_SetPart1:
	ld (xsp + 2), 0x1
	jrl SqplyVal_SelectTrack

SqplyVal_SelectTrack_SetPart2:
	ld (xsp + 2), 0x2
	jrl SqplyVal_SelectTrack

SqplyVal_SelectTrack_SetPart3:
	ld (xsp + 2), 0x3
	jrl SqplyVal_SelectTrack

SqplyVal_SelectTrack_NegRange:
	lds32 xde, 0
	ld e, (xsp + 4)
	ld xwa, (xbc)
	ld xbc, 0x1E80037
	call ApFuncCall
	ldfr_berp L, 0xFB
	cpi_berp 0xFB, 0
	jr lt, SqplyVal_ReturnZero
	ldto_berp E, 0xFB
	exts de
	exts xde
	ld xwa, (xsp + 68)
	ld xbc, 0x1C0000F

SqplyVal_DispatchScrollCmd:
	call SendEvent

SqplyVal_ReturnZero:
	lds32 xhl, 0

SqplyVal_Epilogue:
	pop_werp 0xFA
	lda xsp, (xsp + 70)
	ret

SqedtValProc:
	lda xsp, (xsp - 76)
	push_werp 0xFA
	ld (xsp + 66), xde
	ld (xsp + 70), xbc
	ld (xsp + 74), xwa
	ld xwa, (xsp + 70)
	cp xwa, 0x1C00007
	jrl z, SqedtVal_HandleSelectEvent
	cp xwa, 0x1C00018
	jrl z, SqedtVal_HandleDownScrollEvent
	cp xwa, 0x1C00017
	jrl z, SqedtVal_HandleUpScrollEvent
	cp xwa, 0x1C0000F
	jr z, SqedtVal_HandleScrollEvent
	cp xwa, 0x1C0000B
	jr z, SqedtVal_HandleInitEvent
	ld xwa, (xsp + 74)
	ld xbc, (xsp + 70)
	ld xde, (xsp + 66)
	call InheritedProc
	jrl SqedtVal_Epilogue

SqedtVal_HandleInitEvent:
	ld xwa, (xsp + 74)
	ld xbc, (xsp + 70)
	ld xde, (xsp + 66)
	call InheritedProc
	ld xwa, (xsp + 74)
	call GetViewInstance
	ld xwa, (xhl + 26)
	ld xbc, 0x1E80035
	lds32 xde, 0
	call ApFuncCall
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00007
	ld xde, 0x88
	call SendEvent
	ld xde, (xsp + 74)
	ld xwa, 0x1480000
	ld xbc, (xsp + 70)
	call MainPostEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C00017
	lds32 xde, 1
	call SetDialUp
	ld xwa, (xsp + 74)
	ld xbc, 0x1C00018
	lds32 xde, 1
	call SetDialDown
	lds wa, 1
	jrl SqedtVal_DoSortedUpdate

SqedtVal_HandleScrollEvent:
	ld xwa, (xsp + 74)
	ld xbc, (xsp + 70)
	ld xde, (xsp + 66)
	call InheritedProc
	ld xwa, (xsp + 74)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 26)
	ld xbc, 0x1E80069
	lds32 xde, 0
	call ApFuncCall
	ld xiy, (xsp + 4)
	cp l, (xiy + 30)
	jrl nz, SqedtVal_ReturnZero
	lda xhl, (xsp + 58)
	ld xwa, (xsp + 66)
	sll xwa, 3
	ld xde, 0xE335EA
	add xde, xwa
	ld wa, (xde)
	ld (xhl), wa
	lda xbc, (xhl + 2)
	ld wa, (xde + 2)
	ld (xbc), wa
	ld ix, (xhl)
	add ix, (xde + 4)
	lda xwa, (xhl + 4)
	ld (xwa), ix
	ld ix, (xbc)
	add ix, (xde + 6)
	lda xde, (xhl + 6)
	ld (xde), ix
	ld wa, (xwa)
	sub wa, (xhl)
	exts xwa
	divs wa, 0x2
	ld ix, (xhl)
	add ix, wa
	lda xhl, (xsp + 54)
	ld (xhl), ix
	ld bc, (xbc)
	ld wa, (xde)
	sub wa, bc
	exts xwa
	divs wa, 0x2
	add bc, wa
	ld (xhl + 2), bc
	ld xwa, (xiy + 26)
	ld xbc, 0x1E00045
	ld xde, (xsp + 66)
	call ApFuncCall
	lda xde, (xsp + 8)
	ld (xde), xhl
	lda xhl, (xsp + 30)
	ld xwa, xhl
	lda xbc, (xhl + 24)

SqedtVal_ClearDrawBuffer:
	stib_dpi 0xE0, 0x00
	cp xwa, xbc
	jr c, SqedtVal_ClearDrawBuffer
	ld (xde + 18), xhl
	ld xwa, (xsp + 66)
	cp xwa, 0xE
	jrl ugt, SqedtVal_ReturnZero
	add xwa, xwa
	add xwa, 0xE3481C
	ld wa, (xwa)
	lda_24 xix, 0xf311f1
	jp_dri 8, 0x07, 0xF0, 0xE0

SqedtVal_DrawParamsData:
	.byte 0xaf, 0x04, 0x20, 0xa8, 0x1a, 0x20, 0x41, 0x16
	.byte 0x00, 0xe8, 0x01, 0x1d, 0xb7, 0x49, 0xfa, 0xaf
	.byte 0x04, 0x20, 0xa8, 0x1a, 0x20, 0x41, 0x38, 0x00
	.byte 0xe8, 0x01, 0xaf, 0x42, 0x22, 0x1d, 0xb7, 0x49
	.byte 0xfa, 0xbf, 0x3a, 0x30, 0xbf, 0x36, 0x31, 0xbf
	.byte 0x1e, 0x32, 0xeb, 0xe3, 0x76, 0xca, 0x00, 0xeb
	.byte 0xa8, 0x3b, 0x0b, 0x00, 0x00, 0x0b, 0xff, 0x00
	.byte 0x78, 0xca, 0x00, 0xaf, 0x04, 0x20, 0xa8, 0x1a
	.byte 0x20, 0x41, 0x17, 0x00, 0xe8, 0x01, 0x68, 0xc3
	.byte 0xaf, 0x04, 0x20, 0xa8, 0x1a, 0x20, 0x41, 0x18
	.byte 0x00, 0xe8, 0x01, 0x68, 0xb6, 0xaf, 0x04, 0x20
	.byte 0xa8, 0x1a, 0x20, 0x41, 0x19, 0x00, 0xe8, 0x01
	.byte 0x68, 0xa9, 0xaf, 0x04, 0x20, 0xa8, 0x1a, 0x20
	.byte 0x41, 0x1a, 0x00, 0xe8, 0x01, 0x68, 0x9c, 0xaf
	.byte 0x04, 0x20, 0xa8, 0x1a, 0x20, 0x41, 0x1b, 0x00
	.byte 0xe8, 0x01, 0x68, 0x8f, 0xaf, 0x04, 0x20, 0xa8
	.byte 0x1a, 0x20, 0x41, 0x1c, 0x00, 0xe8, 0x01, 0x68
	.byte 0x82, 0xaf, 0x04, 0x20, 0xa8, 0x1a, 0x20, 0x41
	.byte 0x1d, 0x00, 0xe8, 0x01, 0x78, 0x74, 0xff, 0xaf
	.byte 0x04, 0x20, 0xa8, 0x1a, 0x20, 0x41, 0x1e, 0x00
	.byte 0xe8, 0x01, 0x78, 0x66, 0xff, 0xaf, 0x04, 0x20
	.byte 0xa8, 0x1a, 0x20, 0x41, 0x1f, 0x00, 0xe8, 0x01
	.byte 0x78, 0x58, 0xff, 0xaf, 0x04, 0x20, 0xa8, 0x1a
	.byte 0x20, 0x41, 0x20, 0x00, 0xe8, 0x01, 0x78, 0x4a
	.byte 0xff, 0xaf, 0x04, 0x20, 0xa8, 0x1a, 0x20, 0x41
	.byte 0x21, 0x00, 0xe8, 0x01, 0x78, 0x3c, 0xff, 0xaf
	.byte 0x04, 0x20, 0xa8, 0x1a, 0x20, 0x41, 0x22, 0x00
	.byte 0xe8, 0x01, 0x78, 0x2e, 0xff, 0xaf, 0x04, 0x20
	.byte 0xa8, 0x1a, 0x20, 0x41, 0x23, 0x00, 0xe8, 0x01
	.byte 0x78, 0x20, 0xff, 0xaf, 0x04, 0x20, 0xa8, 0x1a
	.byte 0x20, 0x41, 0x24, 0x00, 0xe8, 0x01, 0x78, 0x12
	.byte 0xff, 0xeb, 0xa8, 0x3b, 0xaf, 0x08, 0x23, 0x9b
	.byte 0x16, 0x04, 0x9b, 0x18, 0x04, 0x1d, 0x4a, 0xcf
	.byte 0xfa, 0xaf, 0x4a, 0x20, 0x41, 0x17, 0x00, 0xc0
	.byte 0x01, 0xea, 0xa9, 0x1d, 0x79, 0xa5, 0xf9, 0xaf
	.byte 0x4a, 0x20, 0x41, 0x18, 0x00, 0xc0, 0x01, 0xea
	.byte 0xa9, 0x1d, 0x8a, 0xa5, 0xf9, 0xd8, 0xa9, 0x78
	.byte 0x57, 0x01

SqedtVal_HandleUpScrollEvent:
	ld xwa, (xsp + 74)
	ld xbc, (xsp + 70)
	ld xde, (xsp + 66)
	call InheritedProc
	ld xwa, (xsp + 74)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 66)
	cp xwa, 0x1
	jrl nz, SqedtVal_ReturnZero
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 26)
	ld xbc, 0x1E80036
	lds32 xde, 0
	call ApFuncCall
	ldfr_berp L, 0xFA
	ldto_berp E, 0xFA
	exts de
	exts xde
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 26)
	ld xbc, 0x1E80037
	call ApFuncCall
	ldfr_berp L, 0xFA
	ldto_berp E, 0xFA
	exts de
	exts xde
	ld xwa, 0x1480000
	ld xbc, 0x1E80014
	call MainPostEvent
	ld xwa, (xsp + 74)
	ld xbc, (xsp + 70)
	ld xde, (xsp + 66)
	jr SqedtVal_CallRedraw

SqedtVal_HandleDownScrollEvent:
	ld xwa, (xsp + 74)
	ld xbc, (xsp + 70)
	ld xde, (xsp + 66)
	call InheritedProc
	ld xwa, (xsp + 74)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 66)
	cp xwa, 0x1
	jrl nz, SqedtVal_ReturnZero
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 26)
	ld xbc, 0x1E80036
	lds32 xde, 0
	call ApFuncCall
	ldfr_berp L, 0xFA
	ldto_berp E, 0xFA
	exts de
	exts xde
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 26)
	ld xbc, 0x1E80037
	call ApFuncCall
	ldfr_berp L, 0xFA
	ldto_berp E, 0xFA
	exts de
	exts xde
	ld xwa, 0x1480000
	ld xbc, 0x1E80015
	call MainPostEvent
	ld xwa, (xsp + 74)
	ld xbc, (xsp + 70)
	ld xde, (xsp + 66)

SqedtVal_CallRedraw:
	call SetAutoInc
	jrl SqedtVal_ReturnZero

SqedtVal_HandleSelectEvent:
	ld xwa, (xsp + 74)
	ld xbc, (xsp + 70)
	ld xde, (xsp + 66)
	call InheritedProc
	ld xwa, (xsp + 74)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 66)
	cp xwa, 0xB
	jr z, SqedtVal_CallSortedUpdate
	cp xwa, 0x9
	jr z, SqedtVal_SetBerp6
	cp xwa, 0x8
	jr z, SqedtVal_SetBerp5
	cp xwa, 0x8B
	jr z, SqedtVal_SetBerp3
	cp xwa, 0x8A
	jr z, SqedtVal_SetBerp2
	cp xwa, 0x89
	jr z, SqedtVal_SetBerp1
	cp xwa, 0x88
	jr nz, SqedtVal_SelectDefault
	ldi_berp 0xFB, 0
	jr SqedtVal_SelectDispatch

SqedtVal_SetBerp1:
	ldi_berp 0xFB, 1
	jr SqedtVal_SelectDispatch

SqedtVal_SetBerp2:
	ldi_berp 0xFB, 2
	jr SqedtVal_SelectDispatch

SqedtVal_SetBerp3:
	ldi_berp 0xFB, 3
	jr SqedtVal_SelectDispatch

SqedtVal_SetBerp5:
	ldi_berp 0xFB, 5
	jr SqedtVal_SelectDispatch

SqedtVal_SetBerp6:
	ldi_berp 0xFB, 6
	jr SqedtVal_SelectDispatch

SqedtVal_CallSortedUpdate:
	lds wa, 0

SqedtVal_DoSortedUpdate:
	call SetDialEnable
	jrl SqedtVal_ReturnZero

SqedtVal_SelectDefault:
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 26)
	ld xbc, 0x1E80036
	lds32 xde, 0
	call ApFuncCall
	ldfr_berp L, 0xFB

SqedtVal_SelectDispatch:
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 26)
	ld xbc, 0x1E80036
	lds32 xde, 0
	call ApFuncCall
	ld (xsp + 2), l
	lds32 xde, 0
	ldto_berp E, 0xFB
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 26)
	ld xbc, 0x1E80037
	call ApFuncCall
	ldfr_berp L, 0xFA
	ld xwa, (xsp + 4)
	lda xbc, (xwa + 26)
	cpi_berp 0xFA, 0
	jr lt, SqedtVal_Select_NegRange
	lds32 xde, 0
	ldto_berp E, 0xFB
	ld xwa, (xbc)
	ld xbc, 0x1E80035
	call ApFuncCall
	ldto_berp E, 0xFA
	exts de
	exts xde
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	call SendEvent
	ldto_berp A, 0xFB
	cp a, (xsp + 2)
	jr z, SqedtVal_ReturnZero
	lds32 xde, 0
	ld e, (xsp + 2)
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 26)
	ld xbc, 0x1E80037
	call ApFuncCall
	ldfr_berp L, 0xFA
	cpi_berp 0xFA, 0
	jr lt, SqedtVal_ReturnZero
	ldto_berp E, 0xFA
	exts de
	exts xde
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	jr SqedtVal_DispatchScrollCmd

SqedtVal_Select_NegRange:
	lds32 xde, 0
	ld e, (xsp + 2)
	ld xwa, (xbc)
	ld xbc, 0x1E80037
	call ApFuncCall
	ldfr_berp L, 0xFA
	cpi_berp 0xFA, 0
	jr lt, SqedtVal_ReturnZero
	ldto_berp E, 0xFA
	exts de
	exts xde
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F

SqedtVal_DispatchScrollCmd:
	call SendEvent

SqedtVal_ReturnZero:
	lds32 xhl, 0

SqedtVal_Epilogue:
	pop_werp 0xFA
	lda xsp, (xsp + 76)
	ret

SqedtFixProc:
	st_dri3b L, 0xFD, 0x7E, 0xFF
	push xiz
	ld xhl, xbc
	ld xiz, xwa
	ld xiy, 0xE3488A
	lda xix, (xsp + 100)
	lds bc, 2
	ldirw
	ldi85
	ld xiy, 0xE34890
	lda xix, (xsp + 96)
	ldi85
	ldiw
	ld xiy, 0xE34894
	lda xix, (xsp + 90)
	lds bc, 2
	ldirw
	ldi85
	ld xiy, 0xE3489A
	lda xix, (xsp + 84)
	lds bc, 3
	ldirw
	ld xiy, 0xE348A0
	lda xix, (xsp + 78)
	lds bc, 3
	ldirw
	ld xiy, 0xE348A6
	lda xix, (xsp + 76)
	ldiw
	ld xiy, 0xE348A8
	lda xix, (xsp + 62)
	lds bc, 7
	ldirw
	ld xiy, 0xE348B6
	lda xix, (xsp + 48)
	lds bc, 6
	ldirw
	ldi85
	ld xiy, 0xE348C4
	lda xix, (xsp + 34)
	lds bc, 7
	ldirw
	ld xiy, 0xE348D2
	lda xix, (xsp + 26)
	lds bc, 3
	ldirw
	ldi85
	ld xiy, 0xE348DA
	lda xix, (xsp + 20)
	lds bc, 2
	ldirw
	ldi85
	cp xhl, 0x1C0000B
	jr z, LABEL_F315F8
	ld xwa, xiz
	ld xbc, xhl
	call InheritedProc
	jrl LABEL_F31E90

LABEL_F315F8:
	ld xwa, xiz
	ld xbc, xhl
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 4), xhl
	lda xwa, (xsp + 118)
	ldw (xwa), 0x2C
	lda xde, (xwa + 2)
	ldw (xde), 0x21
	lda xhl, (xwa + 4)
	ld bc, (xwa)
	add bc, 0x46
	ld (xhl), bc
	lda xix, (xwa + 6)
	ld bc, (xde)
	add bc, 0x14
	ld (xix), bc
	ld bc, (xhl)
	sub bc, (xwa)
	exts xbc
	divs bc, 0x2
	ld hl, (xwa)
	add hl, bc
	lda xbc, (xsp + 106)
	ld (xbc), hl
	ld hl, (xde)
	ld de, (xix)
	sub de, hl
	exts xde
	divs de, 0x2
	add hl, de
	ld (xbc + 2), hl
	lda xde, (xsp + 100)
	lds32 xhl, 2
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	lda xwa, (xsp + 118)
	ldw (xwa), 0xDA
	ldw bc, 0xDA
	add bc, 0x46
	ld (xwa + 4), bc
	sub bc, (xwa)
	exts xbc
	divs bc, 0x2
	ld de, (xwa)
	add de, bc
	lda xbc, (xsp + 106)
	ld (xbc), de
	lda xde, (xsp + 96)
	lds32 xhl, 2
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	lda xwa, (xsp + 118)
	ldw (xwa), 0x3D
	lda xde, (xwa + 2)
	ldw (xde), 0xB7
	lda xhl, (xwa + 4)
	ld bc, (xwa)
	add bc, 0x28
	ld (xhl), bc
	lda xix, (xwa + 6)
	ld bc, (xde)
	add bc, 0xF
	ld (xix), bc
	ld bc, (xhl)
	sub bc, (xwa)
	exts xbc
	divs bc, 0x2
	ld hl, (xwa)
	add hl, bc
	lda xbc, (xsp + 106)
	ld (xbc), hl
	ld hl, (xde)
	ld de, (xix)
	sub de, hl
	exts xde
	divs de, 0x2
	add hl, de
	ld (xbc + 2), hl
	lda xde, (xsp + 100)
	lds32 xhl, 0
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	lda xwa, (xsp + 118)
	ldw (xwa), 0xE4
	ldw bc, 0xE4
	add bc, 0x28
	ld (xwa + 4), bc
	sub bc, (xwa)
	exts xbc
	divs bc, 0x2
	ld de, (xwa)
	add de, bc
	lda xbc, (xsp + 106)
	ld (xbc), de
	lda xde, (xsp + 96)
	lds32 xhl, 0
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	lda xwa, (xsp + 118)
	ldw (xwa), 0x14
	lda xde, (xwa + 2)
	ldw (xde), 0xC8
	lda xhl, (xwa + 4)
	ld bc, (xwa)
	add bc, 0x2D
	ld (xhl), bc
	lda xix, (xwa + 6)
	ld bc, (xde)
	add bc, 0xF
	ld (xix), bc
	ld bc, (xhl)
	sub bc, (xwa)
	exts xbc
	divs bc, 0x2
	ld hl, (xwa)
	add hl, bc
	lda xbc, (xsp + 106)
	ld (xbc), hl
	ld hl, (xde)
	ld de, (xix)
	sub de, hl
	exts xde
	divs de, 0x2
	add hl, de
	ld (xbc + 2), hl
	lda xde, (xsp + 90)
	lds32 xhl, 0
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	lda xwa, (xsp + 118)
	ldw (xwa), 0x61
	ldw bc, 0x61
	add bc, 0x2D
	ld (xwa + 4), bc
	sub bc, (xwa)
	exts xbc
	divs bc, 0x2
	ld de, (xwa)
	add de, bc
	lda xbc, (xsp + 106)
	ld (xbc), de
	lda xde, (xsp + 84)
	lds32 xhl, 0
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	lda xwa, (xsp + 118)
	ldw (xwa), 0xB4
	ldw bc, 0xB4
	add bc, 0x2D
	ld (xwa + 4), bc
	sub bc, (xwa)
	exts xbc
	divs bc, 0x2
	ld de, (xwa)
	add de, bc
	lda xbc, (xsp + 106)
	ld (xbc), de
	lda xde, (xsp + 90)
	lds32 xhl, 0
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	lda xwa, (xsp + 118)
	ldw (xwa), 0x101
	ldw bc, 0x101
	add bc, 0x2D
	ld (xwa + 4), bc
	sub bc, (xwa)
	exts xbc
	divs bc, 0x2
	ld de, (xwa)
	add de, bc
	lda xbc, (xsp + 106)
	ld (xbc), de
	lda xde, (xsp + 84)
	lds32 xhl, 0
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	lda xwa, (xsp + 126)
	ldw (xwa), 0x4
	lda xde, (xwa + 2)
	ldw (xde), 0x36
	ld bc, (xwa)
	add bc, 0x95
	ld (xwa + 4), bc
	ld bc, (xde)
	add bc, 0x6A
	ld (xwa + 6), bc
	ld xde, (xsp + 4)
	ld bc, (xde + 26)
	ld de, (xde + 24)
	call DrawDesignBox
	lda xwa, (xsp + 126)
	ldw (xwa), 0xA4
	ldw bc, 0xA4
	add bc, 0x95
	ld (xwa + 4), bc
	ld bc, (xwa + 2)
	add bc, 0x6A
	ld (xwa + 6), bc
	ld xde, (xsp + 4)
	ld bc, (xde + 26)
	ld de, (xde + 24)
	call DrawDesignBox
	lda xwa, (xsp + 114)
	ldw (xwa), 0x4
	ldw (xwa + 2), 0xC8
	lda xbc, (xsp + 110)
	ld de, (xwa)
	ld (xbc), de
	ldw (xbc + 2), 0xD6
	ld xde, (xsp + 4)
	ld de, (xde + 22)
	call DrawLine
	lda xwa, (xsp + 114)
	ldw (xwa), 0x9B
	lda xbc, (xsp + 110)
	ld de, (xwa)
	ld (xbc), de
	ld xde, (xsp + 4)
	ld de, (xde + 22)
	call DrawLine
	lda xwa, (xsp + 114)
	ldw (xwa), 0xA4
	lda xbc, (xsp + 110)
	ld de, (xwa)
	ld (xbc), de
	ld xde, (xsp + 4)
	ld de, (xde + 22)
	call DrawLine
	lda xwa, (xsp + 114)
	ldw (xwa), 0x13B
	lda xbc, (xsp + 110)
	ld de, (xwa)
	ld (xbc), de
	ld xde, (xsp + 4)
	ld de, (xde + 22)
	call DrawLine
	lda xwa, (xsp + 114)
	ldw (xwa), 0x4
	lda xde, (xwa + 2)
	ldw (xde), 0xC8
	lda xbc, (xsp + 110)
	ldw (xbc), 0x9A
	ld de, (xde)
	ld (xbc + 2), de
	ld xde, (xsp + 4)
	ld de, (xde + 22)
	call DrawLine
	lda xwa, (xsp + 114)
	ldw (xwa), 0xA4
	lda xbc, (xsp + 110)
	ldw (xbc), 0x13A
	ld xde, (xsp + 4)
	ld de, (xde + 22)
	call DrawLine
	call GetTitleNow
	ld xbc, (xsp + 4)
	lda xwa, (xbc + 22)
	ld (xsp + 12), xwa
	lda xwa, (xbc + 24)
	ld (xsp + 8), xwa
	lda xwa, (xsp + 118)
	lda xbc, (xsp + 106)
	lda xde, (xbc + 2)
	ld (xsp + 16), xde
	lda xix, (xwa + 2)
	lda xiz, (xwa + 4)
	lda xiy, (xwa + 6)
	cp l, 0xA8
	jrl z, LABEL_F31C2C
	cp l, 0x91
	jrl z, LABEL_F31C2C
	cp l, 0xA4
	jr z, LABEL_F3195D
	cp l, 0xA2
	jrl nz, LABEL_F31E8E

LABEL_F3195D:
	ldw (xwa), 0xA
	ldw (xix), 0x3A
	ld de, (xwa)
	add de, 0x82
	ld (xiz), de
	ld de, (xix)
	add de, 0xF
	ld (xiy), de
	ld de, (xiz)
	sub de, (xwa)
	exts xde
	divs de, 0x2
	ld hl, (xwa)
	add hl, de
	ld (xbc), hl
	ld hl, (xix)
	ld de, (xiy)
	sub de, hl
	exts xde
	divs de, 0x2
	add hl, de
	ld xde, (xsp + 16)
	ld (xde), hl
	lda xde, (xsp + 78)
	lds32 xhl, 0
	push xhl
	ld xhl, (xsp + 16)
	pushm (xhl)
	ld xhl, (xsp + 14)
	pushm (xhl)
	call DrawStringLeftJustify
	lda xwa, (xsp + 118)
	lda xbc, (xwa + 2)
	ldw (xbc), 0x48
	ldw (xwa + 6), 0x57
	ld de, (xbc)
	ldw bc, 0x57
	sub bc, de
	exts xbc
	divs bc, 0x2
	add de, bc
	lda xbc, (xsp + 106)
	ld (xbc + 2), de
	lda xde, (xsp + 76)
	lds32 xhl, 0
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	lda xwa, (xsp + 118)
	lda xbc, (xwa + 2)
	ldw (xbc), 0x5C
	ldw (xwa + 6), 0x6B
	ld de, (xbc)
	ldw bc, 0x6B
	sub bc, de
	exts xbc
	divs bc, 0x2
	add de, bc
	lda xbc, (xsp + 106)
	ld (xbc + 2), de
	lda xde, (xsp + 62)
	lds32 xhl, 0
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	lda xwa, (xsp + 118)
	lda xbc, (xwa + 2)
	ldw (xbc), 0x6A
	ldw (xwa + 6), 0x79
	ld de, (xbc)
	ldw bc, 0x79
	sub bc, de
	exts xbc
	divs bc, 0x2
	add de, bc
	lda xbc, (xsp + 106)
	ld (xbc + 2), de
	lda xde, (xsp + 76)
	lds32 xhl, 0
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	lda xwa, (xsp + 118)
	lda xbc, (xwa + 2)
	ldw (xbc), 0x7E
	ldw (xwa + 6), 0x8D
	ld de, (xbc)
	ldw bc, 0x8D
	sub bc, de
	exts xbc
	divs bc, 0x2
	add de, bc
	lda xbc, (xsp + 106)
	ld (xbc + 2), de
	lda xde, (xsp + 48)
	lds32 xhl, 0
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	lda xwa, (xsp + 118)
	lda xbc, (xwa + 2)
	ldw (xbc), 0x8C
	ldw (xwa + 6), 0x9B
	ld de, (xbc)
	ldw bc, 0x9B
	sub bc, de
	exts xbc
	divs bc, 0x2
	add de, bc
	lda xbc, (xsp + 106)
	ld (xbc + 2), de
	lda xde, (xsp + 76)
	lds32 xhl, 0
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	lda xwa, (xsp + 118)
	ldw (xwa), 0xAA
	lda xde, (xwa + 2)
	ldw (xde), 0x3A
	lda xhl, (xwa + 4)
	ld bc, (xwa)
	add bc, 0x82
	ld (xhl), bc
	lda xix, (xwa + 6)
	ld bc, (xde)
	add bc, 0xF
	ld (xix), bc
	ld bc, (xhl)
	sub bc, (xwa)
	exts xbc
	divs bc, 0x2
	ld hl, (xwa)
	add hl, bc
	lda xbc, (xsp + 106)
	ld (xbc), hl
	ld hl, (xde)
	ld de, (xix)
	sub de, hl
	exts xde
	divs de, 0x2
	add hl, de
	ld (xbc + 2), hl
	lda xde, (xsp + 78)
	lds32 xhl, 0
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	lda xwa, (xsp + 118)
	lda xbc, (xwa + 2)
	ldw (xbc), 0x48
	ldw (xwa + 6), 0x57
	ld de, (xbc)
	ldw bc, 0x57
	sub bc, de
	exts xbc
	divs bc, 0x2
	add de, bc
	lda xbc, (xsp + 106)
	ld (xbc + 2), de
	lda xde, (xsp + 76)
	lds32 xhl, 0
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	lda xwa, (xsp + 118)
	lda xbc, (xwa + 2)
	ldw (xbc), 0x5C
	ldw (xwa + 6), 0x6B
	ld de, (xbc)
	ldw bc, 0x6B
	sub bc, de
	exts xbc
	divs bc, 0x2
	add de, bc
	lda xbc, (xsp + 106)
	ld (xbc + 2), de
	lda xde, (xsp + 34)
	lds32 xhl, 0
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	lda xwa, (xsp + 118)
	lda xbc, (xwa + 2)
	ldw (xbc), 0x6A
	ldw (xwa + 6), 0x79
	ld de, (xbc)
	ldw bc, 0x79
	sub bc, de
	exts xbc
	divs bc, 0x2
	add de, bc
	lda xbc, (xsp + 106)
	ld (xbc + 2), de
	lda xde, (xsp + 76)
	lds32 xhl, 0
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	lda xwa, (xsp + 118)
	lda xbc, (xwa + 2)
	ldw (xbc), 0x7E
	ldw (xwa + 6), 0x8D
	ld de, (xbc)
	ldw bc, 0x8D
	sub bc, de
	exts xbc
	divs bc, 0x2
	add de, bc
	lda xbc, (xsp + 106)
	ld (xbc + 2), de
	lda xde, (xsp + 26)
	lds32 xhl, 0
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	lda xwa, (xsp + 118)
	lda xbc, (xwa + 2)
	ldw (xbc), 0x8C
	ldw (xwa + 6), 0x9B
	ld de, (xbc)
	ldw bc, 0x9B
	sub bc, de
	exts xbc
	divs bc, 0x2
	add de, bc
	lda xbc, (xsp + 106)
	ld (xbc + 2), de
	lda xde, (xsp + 76)
	lds32 xhl, 0
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	jrl LABEL_F31E8A

LABEL_F31C2C:
	ldw (xwa), 0x6
	ldw (xix), 0x3E
	ld de, (xwa)
	add de, 0x82
	ld (xiz), de
	ld de, (xix)
	add de, 0xF
	ld (xiy), de
	ld de, (xiz)
	sub de, (xwa)
	exts xde
	divs de, 0x2
	ld hl, (xwa)
	add hl, de
	ld (xbc), hl
	ld hl, (xix)
	ld de, (xiy)
	sub de, hl
	exts xde
	divs de, 0x2
	add hl, de
	ld xde, (xsp + 16)
	ld (xde), hl
	lda xde, (xsp + 20)
	lds32 xhl, 0
	push xhl
	ld xhl, (xsp + 16)
	pushm (xhl)
	ld xhl, (xsp + 14)
	pushm (xhl)
	call DrawStringLeftJustify
	lda xwa, (xsp + 118)
	lda xbc, (xwa + 2)
	ldw (xbc), 0x4E
	ldw (xwa + 6), 0x5D
	ld de, (xbc)
	ldw bc, 0x5D
	sub bc, de
	exts xbc
	divs bc, 0x2
	add de, bc
	lda xbc, (xsp + 106)
	ld (xbc + 2), de
	lda xde, (xsp + 76)
	lds32 xhl, 0
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	lda xwa, (xsp + 118)
	lda xbc, (xwa + 2)
	ldw (xbc), 0x5F
	ldw (xwa + 6), 0x6E
	ld de, (xbc)
	ldw bc, 0x6E
	sub bc, de
	exts xbc
	divs bc, 0x2
	add de, bc
	lda xbc, (xsp + 106)
	ld (xbc + 2), de
	lda xde, (xsp + 76)
	lds32 xhl, 0
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	lda xwa, (xsp + 118)
	lda xbc, (xwa + 2)
	ldw (xbc), 0x73
	ldw (xwa + 6), 0x82
	ld de, (xbc)
	ldw bc, 0x82
	sub bc, de
	exts xbc
	divs bc, 0x2
	add de, bc
	lda xbc, (xsp + 106)
	ld (xbc + 2), de
	lda xde, (xsp + 78)
	lds32 xhl, 0
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	lda xwa, (xsp + 118)
	lda xbc, (xwa + 2)
	ldw (xbc), 0x83
	ldw (xwa + 6), 0x92
	ld de, (xbc)
	ldw bc, 0x92
	sub bc, de
	exts xbc
	divs bc, 0x2
	add de, bc
	lda xbc, (xsp + 106)
	ld (xbc + 2), de
	lda xde, (xsp + 76)
	lds32 xhl, 0
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	lda xwa, (xsp + 118)
	ldw (xwa), 0xA6
	lda xde, (xwa + 2)
	ldw (xde), 0x3E
	lda xhl, (xwa + 4)
	ld bc, (xwa)
	add bc, 0x82
	ld (xhl), bc
	lda xix, (xwa + 6)
	ld bc, (xde)
	add bc, 0xF
	ld (xix), bc
	ld bc, (xhl)
	sub bc, (xwa)
	exts xbc
	divs bc, 0x2
	ld hl, (xwa)
	add hl, bc
	lda xbc, (xsp + 106)
	ld (xbc), hl
	ld hl, (xde)
	ld de, (xix)
	sub de, hl
	exts xde
	divs de, 0x2
	add hl, de
	ld (xbc + 2), hl
	lda xde, (xsp + 20)
	lds32 xhl, 0
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	lda xwa, (xsp + 118)
	lda xbc, (xwa + 2)
	ldw (xbc), 0x4E
	ldw (xwa + 6), 0x5D
	ld de, (xbc)
	ldw bc, 0x5D
	sub bc, de
	exts xbc
	divs bc, 0x2
	add de, bc
	lda xbc, (xsp + 106)
	ld (xbc + 2), de
	lda xde, (xsp + 76)
	lds32 xhl, 0
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	lda xwa, (xsp + 118)
	lda xbc, (xwa + 2)
	ldw (xbc), 0x5F
	ldw (xwa + 6), 0x6E
	ld de, (xbc)
	ldw bc, 0x6E
	sub bc, de
	exts xbc
	divs bc, 0x2
	add de, bc
	lda xbc, (xsp + 106)
	ld (xbc + 2), de
	lda xde, (xsp + 76)
	lds32 xhl, 0
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	lda xwa, (xsp + 118)
	lda xbc, (xwa + 2)
	ldw (xbc), 0x73
	ldw (xwa + 6), 0x82
	ld de, (xbc)
	ldw bc, 0x82
	sub bc, de
	exts xbc
	divs bc, 0x2
	add de, bc
	lda xbc, (xsp + 106)
	ld (xbc + 2), de
	lda xde, (xsp + 78)
	lds32 xhl, 0
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	lda xwa, (xsp + 118)
	lda xbc, (xwa + 2)
	ldw (xbc), 0x83
	ldw (xwa + 6), 0x92
	ld de, (xbc)
	ldw bc, 0x92
	sub bc, de
	exts xbc
	divs bc, 0x2
	add de, bc
	lda xbc, (xsp + 106)
	ld (xbc + 2), de
	lda xde, (xsp + 76)
	lds32 xhl, 0
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)

LABEL_F31E8A:
	call DrawStringLeftJustify

LABEL_F31E8E:
	lds32 xhl, 0

LABEL_F31E90:
	pop xiz
	st_dri3b L, 0xFD, 0x82, 0x00
	ret

SqedtVal3Proc:
	lda xsp, (xsp - 66)
	push xiz
	ld (xsp + 62), xde
	ld xiz, xbc
	ld (xsp + 66), xwa
	cp xiz, 0x1C00018
	jrl z, LABEL_F32218
	cp xiz, 0x1C00017
	jrl z, LABEL_F321E4
	cp xiz, 0x1C0000F
	jr z, LABEL_F31F13
	cp xiz, 0x1C0000B
	jr z, LABEL_F31ED4
	ld xwa, (xsp + 66)
	ld xbc, xiz
	ld xde, (xsp + 62)
	call InheritedProc
	jrl LABEL_F32250

LABEL_F31ED4:
	ld xwa, (xsp + 66)
	ld xbc, xiz
	ld xde, (xsp + 62)
	call InheritedProc
	ld xde, (xsp + 66)
	ld xwa, 0x1480000
	ld xbc, xiz
	call MainPostEvent
	ld xwa, (xsp + 66)
	ld xbc, 0x1C00017
	lds32 xde, 1
	call SetDialUp
	ld xwa, (xsp + 66)
	ld xbc, 0x1C00018
	lds32 xde, 1
	call SetDialDown
	lds wa, 1
	call SetDialEnable
	jrl SqedtVal_ReturnZero2

LABEL_F31F13:
	ld xwa, (xsp + 66)
	ld xbc, xiz
	ld xde, (xsp + 62)
	call InheritedProc
	ld xwa, (xsp + 62)
	cp xwa, 0x1F
	jrl c, SqedtVal_ReturnZero2
	cp xwa, 0x22
	jrl ugt, SqedtVal_ReturnZero2
	ld xwa, (xsp + 66)
	call GetViewInstance
	ld (xsp + 4), xhl
	lda xhl, (xsp + 54)
	lda_24 xde, 0xe335ea
	ld_sriw WA, (xde + 0x00f8)
	ld (xhl), wa
	lda xbc, (xhl + 2)
	ld_sriw WA, (xde + 0x00fa)
	ld (xbc), wa
	ld ix, (xhl)
	add_sriw_rm IX, 0xE9, 0xFC, 0x00
	lda xwa, (xhl + 4)
	ld (xwa), ix
	ld ix, (xbc)
	add_sriw_rm IX, 0xE9, 0xFE, 0x00
	lda xde, (xhl + 6)
	ld (xde), ix
	ld wa, (xwa)
	sub wa, (xhl)
	exts xwa
	divs wa, 0x2
	ld ix, (xhl)
	add ix, wa
	lda xhl, (xsp + 50)
	ld (xhl), ix
	ld bc, (xbc)
	ld wa, (xde)
	sub wa, bc
	exts xwa
	divs wa, 0x2
	add bc, wa
	ld (xhl + 2), bc
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 26)
	ld xbc, 0x1E00045
	ld xde, 0x1F
	call ApFuncCall
	lda xde, (xsp + 8)
	ld (xde), xhl
	lda xhl, (xsp + 30)
	ld xwa, xhl
	lda xbc, (xhl + 20)

LABEL_F31FB4:
	stib_dpi 0xE0, 0x00
	cp xwa, xbc
	jr c, LABEL_F31FB4
	ld (xde + 18), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 26)
	ld xbc, 0x1E80048
	call ApFuncCall
	lda xwa, (xsp + 54)
	lda xbc, (xsp + 50)
	lda xde, (xsp + 30)
	lds32 xhl, 4
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	lda xhl, (xsp + 54)
	lda_24 xde, 0xe335ea
	ld_sriw WA, (xde + 0x0100)
	ld (xhl), wa
	lda xbc, (xhl + 2)
	ld_sriw WA, (xde + 0x0102)
	ld (xbc), wa
	ld ix, (xhl)
	add_sriw_rm IX, 0xE9, 0x04, 0x01
	lda xwa, (xhl + 4)
	ld (xwa), ix
	ld ix, (xbc)
	add_sriw_rm IX, 0xE9, 0x06, 0x01
	lda xde, (xhl + 6)
	ld (xde), ix
	ld wa, (xwa)
	sub wa, (xhl)
	exts xwa
	divs wa, 0x2
	ld ix, (xhl)
	add ix, wa
	lda xhl, (xsp + 50)
	ld (xhl), ix
	ld bc, (xbc)
	ld wa, (xde)
	sub wa, bc
	exts xwa
	divs wa, 0x2
	add bc, wa
	ld (xhl + 2), bc
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 26)
	ld xbc, 0x1E00045
	ld xde, 0x20
	call ApFuncCall
	lda xde, (xsp + 8)
	ld (xde), xhl
	lda xhl, (xsp + 30)
	ld xwa, xhl
	lda xbc, (xhl + 20)

LABEL_F3205D:
	stib_dpi 0xE0, 0x00
	cp xwa, xbc
	jr c, LABEL_F3205D
	ld (xde + 18), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 26)
	ld xbc, 0x1E80049
	call ApFuncCall
	lda xwa, (xsp + 54)
	lda xbc, (xsp + 50)
	lda xde, (xsp + 30)
	lds32 xhl, 4
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	lda xhl, (xsp + 54)
	lda_24 xde, 0xe335ea
	ld_sriw WA, (xde + 0x0108)
	ld (xhl), wa
	lda xbc, (xhl + 2)
	ld_sriw WA, (xde + 0x010a)
	ld (xbc), wa
	ld ix, (xhl)
	add_sriw_rm IX, 0xE9, 0x0C, 0x01
	lda xwa, (xhl + 4)
	ld (xwa), ix
	ld ix, (xbc)
	add_sriw_rm IX, 0xE9, 0x0E, 0x01
	lda xde, (xhl + 6)
	ld (xde), ix
	ld wa, (xwa)
	sub wa, (xhl)
	exts xwa
	divs wa, 0x2
	ld ix, (xhl)
	add ix, wa
	lda xhl, (xsp + 50)
	ld (xhl), ix
	ld bc, (xbc)
	ld wa, (xde)
	sub wa, bc
	exts xwa
	divs wa, 0x2
	add bc, wa
	ld (xhl + 2), bc
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 26)
	ld xbc, 0x1E00045
	ld xde, 0x21
	call ApFuncCall
	lda xde, (xsp + 8)
	ld (xde), xhl
	lda xhl, (xsp + 30)
	ld xwa, xhl
	lda xbc, (xhl + 20)

LABEL_F32106:
	stib_dpi 0xE0, 0x00
	cp xwa, xbc
	jr c, LABEL_F32106
	ld (xde + 18), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 26)
	ld xbc, 0x1E8004A
	call ApFuncCall
	lda xwa, (xsp + 54)
	lda xbc, (xsp + 50)
	lda xde, (xsp + 30)
	lds32 xhl, 3
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	lda xhl, (xsp + 54)
	lda_24 xde, 0xe335ea
	ld_sriw WA, (xde + 0x0110)
	ld (xhl), wa
	lda xbc, (xhl + 2)
	ld_sriw WA, (xde + 0x0112)
	ld (xbc), wa
	ld ix, (xhl)
	add_sriw_rm IX, 0xE9, 0x14, 0x01
	lda xwa, (xhl + 4)
	ld (xwa), ix
	ld ix, (xbc)
	add_sriw_rm IX, 0xE9, 0x16, 0x01
	lda xde, (xhl + 6)
	ld (xde), ix
	ld wa, (xwa)
	sub wa, (xhl)
	exts xwa
	divs wa, 0x2
	ld ix, (xhl)
	add ix, wa
	lda xhl, (xsp + 50)
	ld (xhl), ix
	ld bc, (xbc)
	ld wa, (xde)
	sub wa, bc
	exts xwa
	divs wa, 0x2
	add bc, wa
	ld (xhl + 2), bc
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 26)
	ld xbc, 0x1E00045
	ld xde, 0x22
	call ApFuncCall
	lda xde, (xsp + 8)
	ld (xde), xhl
	lda xhl, (xsp + 30)
	ld xwa, xhl
	lda xbc, (xhl + 20)

LABEL_F321AF:
	stib_dpi 0xE0, 0x00
	cp xwa, xbc
	jr c, LABEL_F321AF
	ld (xde + 18), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 26)
	ld xbc, 0x1E8004B
	call ApFuncCall
	lda xwa, (xsp + 54)
	lda xbc, (xsp + 50)
	lda xde, (xsp + 30)
	lds32 xhl, 4
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	jr SqedtVal_ReturnZero2

LABEL_F321E4:
	ld xwa, (xsp + 66)
	ld xbc, xiz
	ld xde, (xsp + 62)
	call InheritedProc
	ld xwa, (xsp + 62)
	cp xwa, 0x1
	jr nz, SqedtVal_ReturnZero2
	ld xwa, 0x1480000
	ld xbc, 0x1E80014
	ld xde, 0x1F
	call MainPostEvent
	ld xwa, (xsp + 66)
	ld xbc, xiz
	ld xde, (xsp + 62)
	jr LABEL_F3224A

LABEL_F32218:
	ld xwa, (xsp + 66)
	ld xbc, xiz
	ld xde, (xsp + 62)
	call InheritedProc
	ld xwa, (xsp + 62)
	cp xwa, 0x1
	jr nz, SqedtVal_ReturnZero2
	ld xwa, 0x1480000
	ld xbc, 0x1E80015
	ld xde, 0x1F
	call MainPostEvent
	ld xwa, (xsp + 66)
	ld xbc, xiz
	ld xde, (xsp + 62)

LABEL_F3224A:
	call SetAutoInc

SqedtVal_ReturnZero2:
	lds32 xhl, 0

LABEL_F32250:
	pop xiz
	lda xsp, (xsp + 66)
	ret

SqedtVal2Proc:
	lda xsp, (xsp - 74)
	push xiz
	ld (xsp + 66), xde
	ld (xsp + 70), xbc
	ld (xsp + 74), xwa
	ld xwa, (xsp + 70)
	cp xwa, 0x1C00018
	jrl z, LABEL_F32C09
	cp xwa, 0x1C00017
	jrl z, LABEL_F32773
	cp xwa, 0x1C0000E
	jrl z, LABEL_F32634
	cp xwa, 0x1C0000F
	jrl z, LABEL_F32380
	cp xwa, 0x1C0000B
	jr z, LABEL_F322A1
	ld xwa, (xsp + 74)
	ld xbc, (xsp + 70)
	ld xde, (xsp + 66)
	call InheritedProc
	jrl LABEL_F33132

LABEL_F322A1:
	ld xwa, (xsp + 74)
	ld xbc, (xsp + 70)
	ld xde, (xsp + 66)
	call InheritedProc
	ld xwa, (xsp + 74)
	call GetViewInstance
	ld xiz, xhl
	call GetTitleNow
	ld (xsp + 6), l
	ld xde, (xsp + 74)
	ld xwa, 0x1480000
	ld xbc, (xsp + 70)
	call MainPostEvent
	ld xwa, (xiz + 26)
	ld xbc, 0x1E8003B
	lds32 xde, 0
	call ApFuncCall
	ld xwa, (xiz + 26)
	ld xbc, 0x1E8003D
	lds32 xde, 0
	call ApFuncCall
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000E
	lds32 xde, 1
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000E
	ld xde, 0x10001
	call SendEvent
	cp (xsp + 6), 0xA2
	jr z, LABEL_F32314
	cp (xsp + 6), 0xA4
	jr nz, LABEL_F32333

LABEL_F32314:
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000E
	lds32 xde, 2
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000E
	ld xde, 0x10002
	call SendEvent

LABEL_F32333:
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000E
	ld xde, 0x100
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000E
	ld xde, 0x10100
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C00017
	lds32 xde, 2
	call SetDialUp
	ld xwa, (xsp + 74)
	ld xbc, 0x1C00018
	lds32 xde, 2
	call SetDialDown
	lds wa, 1
	call SetDialEnable
	sti8_24 0x03e2e0, 0x00
	jrl AccIll_ReturnZero2

LABEL_F32380:
	ld xwa, (xsp + 74)
	ld xbc, (xsp + 70)
	ld xde, (xsp + 66)
	call InheritedProc
	ld xwa, (xsp + 74)
	call GetViewInstance
	ld (xsp + 4), xhl
	lda xhl, (xsp + 58)
	ld xwa, (xsp + 66)
	sll xwa, 3
	ld xde, 0xE335EA
	add xde, xwa
	ld wa, (xde)
	ld (xhl), wa
	lda xbc, (xhl + 2)
	ld wa, (xde + 2)
	ld (xbc), wa
	ld ix, (xhl)
	add ix, (xde + 4)
	lda xwa, (xhl + 4)
	ld (xwa), ix
	ld ix, (xbc)
	add ix, (xde + 6)
	lda xde, (xhl + 6)
	ld (xde), ix
	ld wa, (xwa)
	sub wa, (xhl)
	exts xwa
	divs wa, 0x2
	ld ix, (xhl)
	add ix, wa
	lda xhl, (xsp + 54)
	ld (xhl), ix
	ld bc, (xbc)
	ld wa, (xde)
	sub wa, bc
	exts xwa
	divs wa, 0x2
	add bc, wa
	ld (xhl + 2), bc
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 26)
	ld xbc, 0x1E00045
	ld xde, (xsp + 66)
	call ApFuncCall
	lda xde, (xsp + 12)
	ld (xde), xhl
	lda xhl, (xsp + 34)
	ld xwa, xhl
	lda xbc, (xhl + 20)

; SqplyVal extra params dispatch
SqplyVal_ExtraParams:
	stib_dpi 0xE0, 0x00
	cp xwa, xbc
	jr c, SqplyVal_ExtraParams
	ld (xde + 18), xhl
	ld xhl, (xsp + 66)
	ld xwa, (xsp + 4)
	lda xbc, (xwa + 26)
	sub xhl, 0xF
	cp xhl, 0x0
	jrl c, AccIll_ReturnZero2
	cp xhl, 0xF
	jrl ugt, AccIll_ReturnZero2
	add xhl, xhl
	add xhl, 0xE348E0
	ld hl, (xhl)
	lda_24 xix, 0xf3244a
	jp_dri 8, 0x07, 0xF0, 0xEC
; AccIll_HandleEditorLoad dispatch
AccIll_Dispatch:
	.byte 0xa1, 0x20, 0x41, 0x25, 0x00, 0xe8, 0x01, 0x1d
	.byte 0xb7, 0x49, 0xfa, 0xaf, 0x04, 0x20, 0xa8, 0x1a
	.byte 0x20, 0x41, 0x39, 0x00, 0xe8, 0x01, 0xaf, 0x42
	.byte 0x22, 0x1d, 0xb7, 0x49, 0xfa, 0xeb, 0xe3, 0x76
	.byte 0xa3, 0x00, 0xbf, 0x3a, 0x30, 0xbf, 0x36, 0x31
	.byte 0xbf, 0x22, 0x32, 0xeb, 0xa8, 0x3b, 0x0b, 0x00
	.byte 0x00, 0x0b, 0xff, 0x00, 0x78, 0xa3, 0x00, 0xa1
	.byte 0x20, 0x41, 0x26, 0x00, 0xe8, 0x01, 0x68, 0xc7
	.byte 0xa1, 0x20, 0x41, 0x27, 0x00, 0xe8, 0x01, 0x68
	.byte 0xbe, 0xa1, 0x20, 0x41, 0x28, 0x00, 0xe8, 0x01
	.byte 0x68, 0xb5, 0xa1, 0x20, 0x41, 0x29, 0x00, 0xe8
	.byte 0x01, 0x68, 0xac, 0xa1, 0x20, 0x41, 0x2a, 0x00
	.byte 0xe8, 0x01, 0x68, 0xa3, 0xa1, 0x20, 0x41, 0x2b
	.byte 0x00, 0xe8, 0x01, 0x68, 0x9a, 0xa1, 0x20, 0x41
	.byte 0x2c, 0x00, 0xe8, 0x01, 0x68, 0x91, 0xa1, 0x20
	.byte 0x41, 0x2d, 0x00, 0xe8, 0x01, 0x68, 0x88, 0xa1
	.byte 0x20, 0x41, 0x2e, 0x00, 0xe8, 0x01, 0x78, 0x7e
	.byte 0xff, 0xa1, 0x20, 0x41, 0x2f, 0x00, 0xe8, 0x01
	.byte 0x78, 0x74, 0xff, 0xa1, 0x20, 0x41, 0x30, 0x00
	.byte 0xe8, 0x01, 0x78, 0x6a, 0xff, 0xa1, 0x20, 0x41
	.byte 0x31, 0x00, 0xe8, 0x01, 0x78, 0x60, 0xff, 0xa1
	.byte 0x20, 0x41, 0x32, 0x00, 0xe8, 0x01, 0x78, 0x56
	.byte 0xff, 0xa1, 0x20, 0x41, 0x33, 0x00, 0xe8, 0x01
	.byte 0x78, 0x4c, 0xff, 0xa1, 0x20, 0x41, 0x34, 0x00
	.byte 0xe8, 0x01, 0x78, 0x42, 0xff, 0xbf, 0x3a, 0x30
	.byte 0xbf, 0x36, 0x31, 0xbf, 0x22, 0x32, 0xeb, 0xa8
	.byte 0x3b, 0xaf, 0x08, 0x23, 0x9b, 0x16, 0x04, 0x9b
	.byte 0x18, 0x04, 0x1d, 0x4a, 0xcf, 0xfa, 0xaf, 0x04
	.byte 0x20, 0xb8, 0x1a, 0x31, 0xbf, 0x0c, 0x30, 0xbf
	.byte 0x08, 0x60, 0xaf, 0x42, 0x20, 0xe8, 0xcf, 0x1d
	.byte 0x00, 0x00, 0x00, 0x76, 0x89, 0x00, 0xe8, 0xcf
	.byte 0x1b, 0x00, 0x00, 0x00, 0x7e, 0xe7, 0x0b, 0xbf
	.byte 0x3a, 0x35, 0xb5, 0x02, 0x0e, 0x00, 0xbd, 0x02
	.byte 0x32, 0xb2, 0x02, 0x5f, 0x00, 0xbd, 0x04, 0x33
	.byte 0x95, 0x20, 0xd8, 0xc8, 0xa0, 0x00, 0xb3, 0x50
	.byte 0xbd, 0x06, 0x34, 0x92, 0x20, 0xd8, 0xc8, 0x0e
	.byte 0x00, 0xb4, 0x50, 0x93, 0x20, 0x95, 0xa0, 0xe8
	.byte 0x13, 0xd8, 0x0b, 0x02, 0x00, 0x95, 0x25, 0xd8
	.byte 0x85, 0xbf, 0x36, 0x33, 0xb3, 0x55, 0x92, 0x22
	.byte 0x94, 0x20, 0xda, 0xa0, 0xe8, 0x13, 0xd8, 0x0b
	.byte 0x02, 0x00, 0xd8, 0x82, 0xbb, 0x02, 0x52, 0xa1
	.byte 0x20, 0x41, 0x72, 0x00, 0xe8, 0x01, 0xaf, 0x08
	.byte 0x22, 0x1d, 0xb7, 0x49, 0xfa, 0xaf, 0x04, 0x20
	.byte 0xa8, 0x1a, 0x20, 0x41, 0x39, 0x00, 0xe8, 0x01
	.byte 0xaf, 0x42, 0x22, 0x1d, 0xb7, 0x49, 0xfa, 0xbf
	.byte 0x36, 0x31, 0xbf, 0x22, 0x32, 0xeb, 0xe3, 0x66
	.byte 0x63, 0xbf, 0x3a, 0x30, 0xeb, 0xa8, 0x3b, 0x0b
	.byte 0x00, 0x00, 0x0b, 0xff, 0x00, 0x68, 0x64, 0xbf
	.byte 0x3a, 0x35, 0xb5, 0x02, 0xae, 0x00, 0xbd, 0x02
	.byte 0x32, 0xb2, 0x02, 0x5f, 0x00, 0xbd, 0x04, 0x33
	.byte 0x95, 0x20, 0xd8, 0xc8, 0xa0, 0x00, 0xb3, 0x50
	.byte 0xbd, 0x06, 0x34, 0x92, 0x20, 0xd8, 0xc8, 0x0e
	.byte 0x00, 0xb4, 0x50, 0x93, 0x20, 0x95, 0xa0, 0xe8
	.byte 0x13, 0xd8, 0x0b, 0x02, 0x00, 0x95, 0x25, 0xd8
	.byte 0x85, 0xbf, 0x36, 0x33, 0xb3, 0x55, 0x92, 0x22
	.byte 0x94, 0x20, 0xda, 0xa0, 0xe8, 0x13, 0xd8, 0x0b
	.byte 0x02, 0x00, 0xd8, 0x82, 0xbb, 0x02, 0x52, 0xa1
	.byte 0x20, 0x41, 0x73, 0x00, 0xe8, 0x01, 0xaf, 0x08
	.byte 0x22, 0x78, 0x7d, 0xff, 0xbf, 0x3a, 0x30, 0xeb
	.byte 0xa8, 0x3b, 0xaf, 0x08, 0x23, 0x9b, 0x16, 0x04
	.byte 0x9b, 0x18, 0x04, 0x1d, 0x4a, 0xcf, 0xfa, 0x78
	.byte 0xfc, 0x0a

LABEL_F32634:
	ld xwa, (xsp + 74)
	ld xbc, (xsp + 70)
	ld xde, (xsp + 66)
	call InheritedProc
	ld xwa, (xsp + 74)
	call GetViewInstance
	ld (xsp + 8), xhl
	call GetTitleNow
	ld (xsp + 6), l
	ld xwa, (xsp + 66)
	srl xwa, 0
	and xwa, 0xFF
	ld c, a
	ld xwa, (xsp + 66)
	and xwa, 0xFF
	ldfr_berp A, 0xFB
	cps c, 0
	jr nz, LABEL_F326DB
	lda xix, (xsp + 58)
	lda xbc, (xix + 2)
	lda xde, (xix + 4)
	lda xhl, (xix + 6)
	cp (xsp + 6), 0x91
	jr z, LABEL_F32688
	cp (xsp + 6), 0xA8
	jr nz, LABEL_F326AE

LABEL_F32688:
	ldto_berp A, 0xFB
	extz wa
	sla wa, 3
	lda_24 xiy, 0xe34852
	st_dri3b E, 0x07, 0xF4, 0xE0
	ld wa, (xiy + 2)
	ld (xbc), wa
	ld wa, (xiy)
	ld (xix), wa
	ld wa, (xbc)
	add wa, (xiy + 6)
	ld (xhl), wa
	ld xwa, xiy
	jr LABEL_F326D2

LABEL_F326AE:
	ldto_berp A, 0xFB
	extz wa
	sla wa, 3
	lda_24 xiy, 0xe3483a
	st_dri3b E, 0x07, 0xF4, 0xE0
	ld wa, (xiy + 2)
	ld (xbc), wa
	ld wa, (xiy)
	ld (xix), wa
	ld wa, (xbc)
	add wa, (xiy + 6)
	ld (xhl), wa
	ld xwa, xiy

LABEL_F326D2:
	ld bc, (xix)
	add bc, (xwa + 4)
	ld (xde), bc
	jr LABEL_F32743

LABEL_F326DB:
	ldto_berp A, 0xFB
	extz wa
	sla wa, 3
	cp (xsp + 6), 0x91
	jr z, LABEL_F326EF
	cp (xsp + 6), 0xA8
	jr nz, LABEL_F32716

LABEL_F326EF:
	lda xhl, (xsp + 58)
	lda xde, (xhl + 2)
	lda_24 xbc, 0xe3487a
	st_dri3b A, 0x07, 0xE4, 0xE0
	ld wa, (xbc + 2)
	ld (xde), wa
	ld wa, (xbc)
	ld (xhl), wa
	ld wa, (xde)
	add wa, (xbc + 6)
	ld (xhl + 6), wa
	ld xwa, xbc
	ld xbc, xhl
	jr LABEL_F3273B

LABEL_F32716:
	lda xhl, (xsp + 58)
	lda xde, (xhl + 2)
	lda_24 xbc, 0xe34862
	st_dri3b A, 0x07, 0xE4, 0xE0
	ld wa, (xbc + 2)
	ld (xde), wa
	ld wa, (xbc)
	ld (xhl), wa
	ld wa, (xde)
	add wa, (xbc + 6)
	ld (xhl + 6), wa
	ld xwa, xbc
	ld xbc, xhl

LABEL_F3273B:
	ld bc, (xbc)
	add bc, (xwa + 4)
	ld (xhl + 4), bc

LABEL_F32743:
	ld xwa, (xsp + 66)
	srl xwa, 8
	and xwa, 0xFF
	cps a, 1
	jr nz, LABEL_F3275F
	lda xwa, (xsp + 58)
	pushw 0xF2
	lds bc, 1
	lds de, 2
	jr LABEL_F3276C

LABEL_F3275F:
	lda xwa, (xsp + 58)
	ld xbc, (xsp + 8)
	pushm (xbc + 24)
	lds bc, 1
	lds de, 2

LABEL_F3276C:
	call DrawDesignFrame
	jrl AccIll_ReturnZero2

LABEL_F32773:
	ld xwa, (xsp + 74)
	ld xbc, (xsp + 70)
	ld xde, (xsp + 66)
	call InheritedProc
	ld xwa, (xsp + 74)
	call GetViewInstance
	ld (xsp + 8), xhl
	call GetTitleNow
	ld (xsp + 6), l
	ld xwa, (xsp + 8)
	lda xbc, (xwa + 26)
	ld xwa, (xsp + 66)
	cp xwa, 0x1
	jrl nz, LABEL_F32931
	sti8_24 0x03e2e0, 0x00
	ld xwa, (xbc)
	ld xbc, 0x1E8003A
	lds32 xde, 0
	call ApFuncCall
	ldfr_berp L, 0xFB
	cpi_berp 0xFB, 0
	jr z, LABEL_F327FD
	lds32 xde, 0
	ldto_berp E, 0xFB
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000E
	call SendEvent
	dec1_berp 0xFB
	lds32 xde, 0
	ldto_berp E, 0xFB
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 26)
	ld xbc, 0x1E8003B
	call ApFuncCall
	lds32 xde, 0
	ldto_berp E, 0xFB
	add xde, 0x100
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000E
	call SendEvent

LABEL_F327FD:
	cp (xsp + 6), 0xA2
	jr nz, LABEL_F32868
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0xF
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x10
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x11
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x12
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x13
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x14
	jrl LABEL_F32912

LABEL_F32868:
	cp (xsp + 6), 0xA4
	jr nz, LABEL_F328D2
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x15
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x16
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x17
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x18
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x19
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x1A
	jr LABEL_F32912

LABEL_F328D2:
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x1B
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x1C
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x1D
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x1E

LABEL_F32912:
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C00017
	lds32 xde, 2
	call SetDialUp
	ld xwa, (xsp + 74)
	ld xbc, 0x1C00018
	lds32 xde, 2
	jrl AccIll_CallSetDialDown

LABEL_F32931:
	ld xwa, (xsp + 66)
	cp xwa, 0x3
	jrl nz, LABEL_F32AD1
	sti8_24 0x03e2e0, 0x01
	ld xwa, (xbc)
	ld xbc, 0x1E8003C
	lds32 xde, 0
	call ApFuncCall
	ldfr_berp L, 0xFB
	cpi_berp 0xFB, 0
	jr z, LABEL_F3299D
	lds32 xde, 0
	ldto_berp E, 0xFB
	add xde, 0x10000
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000E
	call SendEvent
	dec1_berp 0xFB
	lds32 xde, 0
	ldto_berp E, 0xFB
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 26)
	ld xbc, 0x1E8003D
	call ApFuncCall
	lds32 xde, 0
	ldto_berp E, 0xFB
	add xde, 0x10100
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000E
	call SendEvent

LABEL_F3299D:
	cp (xsp + 6), 0xA2
	jr nz, LABEL_F32A08
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0xF
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x10
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x11
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x12
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x13
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x14
	jrl LABEL_F32AB2

LABEL_F32A08:
	cp (xsp + 6), 0xA4
	jr nz, LABEL_F32A72
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x15
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x16
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x17
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x18
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x19
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x1A
	jr LABEL_F32AB2

LABEL_F32A72:
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x1B
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x1C
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x1D
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x1E

LABEL_F32AB2:
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C00017
	lds32 xde, 4
	call SetDialUp
	ld xwa, (xsp + 74)
	ld xbc, 0x1C00018
	lds32 xde, 4
	jrl AccIll_CallSetDialDown

LABEL_F32AD1:
	ld xwa, (xsp + 66)
	cp xwa, 0x2
	jrl nz, LABEL_F32B6D
	sti8_24 0x03e2e0, 0x00
	ld xwa, (xbc)
	ld xbc, 0x1E8003A
	lds32 xde, 0
	call ApFuncCall
	ldfr_berp L, 0xFB
	cp (xsp + 6), 0xA2
	jr nz, LABEL_F32B0F
	ldto_berp E, 0xFB
	add e, 0xF
	ldb d, 0x0
	extz xde
	ld xwa, 0x1480000
	ld xbc, 0x1E80014
	jr LABEL_F32B3F

LABEL_F32B0F:
	cp (xsp + 6), 0xA4
	jr nz, LABEL_F32B2B
	ldto_berp E, 0xFB
	add e, 0x15
	ldb d, 0x0
	extz xde
	ld xwa, 0x1480000
	ld xbc, 0x1E80014
	jr LABEL_F32B3F

LABEL_F32B2B:
	ldto_berp E, 0xFB
	add e, 0x1B
	ldb d, 0x0
	extz xde
	ld xwa, 0x1480000
	ld xbc, 0x1E80014

LABEL_F32B3F:
	call MainPostEvent
	ld xwa, (xsp + 74)
	ld xbc, (xsp + 70)
	ld xde, (xsp + 66)
	call SetAutoInc
	ld xwa, (xsp + 74)
	ld xbc, 0x1C00017
	ld xde, (xsp + 66)
	call SetDialUp
	ld xwa, (xsp + 74)
	ld xbc, 0x1C00018
	ld xde, (xsp + 66)
	jrl AccIll_CallSetDialDown

LABEL_F32B6D:
	ld xwa, (xsp + 66)
	cp xwa, 0x4
	jrl nz, AccIll_ReturnZero2
	sti8_24 0x03e2e0, 0x01
	ld xwa, (xbc)
	ld xbc, 0x1E8003C
	lds32 xde, 0
	call ApFuncCall
	ldfr_berp L, 0xFB
	cp (xsp + 6), 0xA2
	jr nz, LABEL_F32BAB
	ldto_berp E, 0xFB
	add e, 0x12
	ldb d, 0x0
	extz xde
	ld xwa, 0x1480000
	ld xbc, 0x1E80014
	jr LABEL_F32BDB

LABEL_F32BAB:
	cp (xsp + 6), 0xA4
	jr nz, LABEL_F32BC7
	ldto_berp E, 0xFB
	add e, 0x18
	ldb d, 0x0
	extz xde
	ld xwa, 0x1480000
	ld xbc, 0x1E80014
	jr LABEL_F32BDB

LABEL_F32BC7:
	ldto_berp E, 0xFB
	add e, 0x1D
	ldb d, 0x0
	extz xde
	ld xwa, 0x1480000
	ld xbc, 0x1E80014

LABEL_F32BDB:
	call MainPostEvent
	ld xwa, (xsp + 74)
	ld xbc, (xsp + 70)
	ld xde, (xsp + 66)
	call SetAutoInc
	ld xwa, (xsp + 74)
	ld xbc, 0x1C00017
	ld xde, (xsp + 66)
	call SetDialUp
	ld xwa, (xsp + 74)
	ld xbc, 0x1C00018
	ld xde, (xsp + 66)
	jrl AccIll_CallSetDialDown

LABEL_F32C09:
	ld xwa, (xsp + 74)
	ld xbc, (xsp + 70)
	ld xde, (xsp + 66)
	call InheritedProc
	ld xwa, (xsp + 74)
	call GetViewInstance
	ld (xsp + 8), xhl
	call GetTitleNow
	ld (xsp + 6), l
	ld xwa, (xsp + 66)
	cp xwa, 0x1
	jrl nz, LABEL_F32E0B
	sti8_24 0x03e2e0, 0x00
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 26)
	ld xbc, 0x1E8003A
	lds32 xde, 0
	call ApFuncCall
	ldfr_berp L, 0xFB
	lds32 xde, 0
	ldto_berp E, 0xFB
	cp (xsp + 6), 0x91
	jr z, LABEL_F32C5F
	cp (xsp + 6), 0xA8
	jrl nz, LABEL_F32CE1

LABEL_F32C5F:
	cpi_berp 0xFB, 1
	jr nc, LABEL_F32C87
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000E
	call SendEvent
	inc1_berp 0xFB
	lds32 xde, 0
	ldto_berp E, 0xFB
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 26)
	ld xbc, 0x1E8003B
	call ApFuncCall

LABEL_F32C87:
	lds32 xde, 0
	ldto_berp E, 0xFB
	add xde, 0x100
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000E
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x1B
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x1C
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x1D
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x1E
	jrl LABEL_F32DEC

LABEL_F32CE1:
	cpi_berp 0xFB, 2
	jr nc, LABEL_F32D20
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000E
	call SendEvent
	inc1_berp 0xFB
	lds32 xde, 0
	ldto_berp E, 0xFB
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 26)
	ld xbc, 0x1E8003B
	call ApFuncCall
	lds32 xde, 0
	ldto_berp E, 0xFB
	add xde, 0x100
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000E
	call SendEvent

LABEL_F32D20:
	cp (xsp + 6), 0xA2
	jr nz, LABEL_F32D8A
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0xF
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x10
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x11
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x12
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x13
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x14
	jr LABEL_F32DEC

LABEL_F32D8A:
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x15
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x16
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x17
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x18
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x19
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x1A

LABEL_F32DEC:
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C00017
	lds32 xde, 2
	call SetDialUp
	ld xwa, (xsp + 74)
	ld xbc, 0x1C00018
	lds32 xde, 2
	jrl AccIll_CallSetDialDown

LABEL_F32E0B:
	ld xwa, (xsp + 8)
	lda xbc, (xwa + 26)
	ld xwa, (xsp + 66)
	cp xwa, 0x3
	jrl nz, LABEL_F32FF7
	sti8_24 0x03e2e0, 0x01
	ld xwa, (xbc)
	ld xbc, 0x1E8003C
	lds32 xde, 0
	call ApFuncCall
	ldfr_berp L, 0xFB
	lds32 xde, 0
	ldto_berp E, 0xFB
	add xde, 0x10000
	cp (xsp + 6), 0x91
	jr z, LABEL_F32E4B
	cp (xsp + 6), 0xA8
	jrl nz, LABEL_F32ECD

LABEL_F32E4B:
	cpi_berp 0xFB, 1
	jr nc, LABEL_F32E8A
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000E
	call SendEvent
	inc1_berp 0xFB
	lds32 xde, 0
	ldto_berp E, 0xFB
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 26)
	ld xbc, 0x1E8003D
	call ApFuncCall
	lds32 xde, 0
	ldto_berp E, 0xFB
	add xde, 0x10100
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000E
	call SendEvent

LABEL_F32E8A:
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x1B
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x1C
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x1D
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x1E
	jrl LABEL_F32FD8

LABEL_F32ECD:
	cpi_berp 0xFB, 2
	jr nc, LABEL_F32F0C
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000E
	call SendEvent
	inc1_berp 0xFB
	lds32 xde, 0
	ldto_berp E, 0xFB
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 26)
	ld xbc, 0x1E8003D
	call ApFuncCall
	lds32 xde, 0
	ldto_berp E, 0xFB
	add xde, 0x10100
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000E
	call SendEvent

LABEL_F32F0C:
	cp (xsp + 6), 0xA2
	jr nz, LABEL_F32F76
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0xF
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x10
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x11
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x12
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x13
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x14
	jr LABEL_F32FD8

LABEL_F32F76:
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x15
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x16
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x17
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x18
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x19
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C0000F
	ld xde, 0x1A

LABEL_F32FD8:
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, 0x1C00017
	lds32 xde, 4
	call SetDialUp
	ld xwa, (xsp + 74)
	ld xbc, 0x1C00018
	lds32 xde, 4
	jrl AccIll_CallSetDialDown

LABEL_F32FF7:
	ld xwa, (xsp + 66)
	cp xwa, 0x2
	jrl nz, LABEL_F33093
	sti8_24 0x03e2e0, 0x00
	ld xwa, (xbc)
	ld xbc, 0x1E8003A
	lds32 xde, 0
	call ApFuncCall
	ldfr_berp L, 0xFB
	cp (xsp + 6), 0xA2
	jr nz, LABEL_F33035
	ldto_berp E, 0xFB
	add e, 0xF
	ldb d, 0x0
	extz xde
	ld xwa, 0x1480000
	ld xbc, 0x1E80015
	jr LABEL_F33065

LABEL_F33035:
	cp (xsp + 6), 0xA4
	jr nz, LABEL_F33051
	ldto_berp E, 0xFB
	add e, 0x15
	ldb d, 0x0
	extz xde
	ld xwa, 0x1480000
	ld xbc, 0x1E80015
	jr LABEL_F33065

LABEL_F33051:
	ldto_berp E, 0xFB
	add e, 0x1B
	ldb d, 0x0
	extz xde
	ld xwa, 0x1480000
	ld xbc, 0x1E80015

LABEL_F33065:
	call MainPostEvent
	ld xwa, (xsp + 74)
	ld xbc, (xsp + 70)
	ld xde, (xsp + 66)
	call SetAutoInc
	ld xwa, (xsp + 74)
	ld xbc, 0x1C00017
	ld xde, (xsp + 66)
	call SetDialUp
	ld xwa, (xsp + 74)
	ld xbc, 0x1C00018
	ld xde, (xsp + 66)
	jrl AccIll_CallSetDialDown

LABEL_F33093:
	ld xwa, (xsp + 66)
	cp xwa, 0x4
	jrl nz, AccIll_ReturnZero2
	sti8_24 0x03e2e0, 0x01
	ld xwa, (xbc)
	ld xbc, 0x1E8003C
	lds32 xde, 0
	call ApFuncCall
	ldfr_berp L, 0xFB
	cp (xsp + 6), 0xA2
	jr nz, LABEL_F330D1
	ldto_berp E, 0xFB
	add e, 0x12
	ldb d, 0x0
	extz xde
	ld xwa, 0x1480000
	ld xbc, 0x1E80015
	jr LABEL_F33101

LABEL_F330D1:
	cp (xsp + 6), 0xA4
	jr nz, LABEL_F330ED
	ldto_berp E, 0xFB
	add e, 0x18
	ldb d, 0x0
	extz xde
	ld xwa, 0x1480000
	ld xbc, 0x1E80015
	jr LABEL_F33101

LABEL_F330ED:
	ldto_berp E, 0xFB
	add e, 0x1D
	ldb d, 0x0
	extz xde
	ld xwa, 0x1480000
	ld xbc, 0x1E80015

LABEL_F33101:
	call MainPostEvent
	ld xwa, (xsp + 74)
	ld xbc, (xsp + 70)
	ld xde, (xsp + 66)
	call SetAutoInc
	ld xwa, (xsp + 74)
	ld xbc, 0x1C00017
	ld xde, (xsp + 66)
	call SetDialUp
	ld xwa, (xsp + 74)
	ld xbc, 0x1C00018
	ld xde, (xsp + 66)

AccIll_CallSetDialDown:
	call SetDialDown

AccIll_ReturnZero2:
	lds32 xhl, 0

LABEL_F33132:
	pop xiz
	lda xsp, (xsp + 74)
	ret

AccIllProc:
	lda xsp, (xsp - 66)
	push xiz
	ld (xsp + 62), xde
	ld xiz, xbc
	ld (xsp + 66), xwa
	cp xiz, 0x1C00018
	jrl z, AccIll_HandleDownScroll
	cp xiz, 0x1C00017
	jrl z, AccIll_HandleUpScroll
	cp xiz, 0x1C80001
	jrl z, AccIll_HandleVertSlider
	cp xiz, 0x1C80000
	jr z, AccIll_HandleHorizSlider
	cp xiz, 0x1E8000F
	jr z, AccIll_HandleUpperPanelEvent
	cp xiz, 0x1E8000E
	jr z, AccIll_HandleLowerPanelEvent
	cp xiz, 0x1C0000B
	jrl nz, AccIll_PassThrough
	ld xwa, (xsp + 66)
	ld xbc, xiz
	ld xde, (xsp + 62)
	call InheritedProc
	ld xde, (xsp + 66)
	ld xwa, 0x1480002
	ld xbc, xiz
	call MainPostEvent
	ld xwa, (xsp + 66)
	ld xbc, 0x1C00017
	lds32 xde, 1
	call SetDialUp
	ld xwa, (xsp + 66)
	ld xbc, 0x1C00018
	lds32 xde, 1
	call SetDialDown
	lds wa, 1
	jrl AccIll_CallSortedUpdate

AccIll_HandleLowerPanelEvent:
	ld xwa, (xsp + 66)
	ld xbc, 0x1C80000
	lds32 xde, 0
	jr AccIll_PanelDispatch

AccIll_HandleUpperPanelEvent:
	ld xwa, (xsp + 62)
	or xwa, xwa
	jrl nz, AccIll_ReturnZero
	ld xwa, (xsp + 66)
	ld xbc, 0x1C80001
	lds32 xde, 0

AccIll_PanelDispatch:
	call SendEvent
	jrl AccIll_ReturnZero

AccIll_HandleHorizSlider:
	ld xwa, (xsp + 66)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 26)
	ld xbc, 0x1E80069
	lds32 xde, 0
	call ApFuncCall
	ld xwa, (xsp + 4)
	cp l, (xwa + 30)
	jrl nz, AccIll_ReturnZero
	lda xix, (xsp + 54)
	ldw (xix), 0x64
	lda xbc, (xix + 2)
	ldw (xbc), 0x5E
	lda xde, (xix + 4)
	ld wa, (xix)
	add wa, 0xB4
	ld (xde), wa
	lda xhl, (xix + 6)
	ld wa, (xbc)
	add wa, 0x13
	ld (xhl), wa
	ld wa, (xde)
	sub wa, (xix)
	exts xwa
	divs wa, 0x2
	ld ix, (xix)
	add ix, wa
	lda xde, (xsp + 50)
	ld (xde), ix
	ld bc, (xbc)
	ld wa, (xhl)
	sub wa, bc
	exts xwa
	divs wa, 0x2
	add bc, wa
	ld (xde + 2), bc
	lda xbc, (xsp + 30)
	ld xwa, xbc
	lda xbc, (xbc + 20)

AccIll_ClearDrawBuffer1:
	stib_dpi 0xE0, 0x00
	cp xwa, xbc
	jr c, AccIll_ClearDrawBuffer1
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 26)
	ld xbc, 0x1E00045
	lds32 xde, 0
	call ApFuncCall
	lda xde, (xsp + 8)
	ld (xde), xhl
	lda xwa, (xsp + 30)
	ld (xde + 18), xwa
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 26)
	ld xbc, 0x1E00047
	call ApFuncCall
	lda xwa, (xsp + 54)
	lda xbc, (xsp + 50)
	lda xde, (xsp + 30)
	lds32 xhl, 4
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	jrl AccIll_CallDrawRoutine

AccIll_HandleVertSlider:
	ld xwa, (xsp + 66)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 26)
	ld xbc, 0x1E80069
	lds32 xde, 0
	call ApFuncCall
	ld xwa, (xsp + 4)
	cp l, (xwa + 30)
	jrl nz, AccIll_ReturnZero
	lda xix, (xsp + 54)
	ldw (xix), 0xB2
	lda xbc, (xix + 2)
	ldw (xbc), 0x91
	lda xde, (xix + 4)
	ld wa, (xix)
	add wa, 0x2D
	ld (xde), wa
	lda xhl, (xix + 6)
	ld wa, (xbc)
	add wa, 0xC
	ld (xhl), wa
	ld wa, (xde)
	sub wa, (xix)
	exts xwa
	divs wa, 0x2
	ld ix, (xix)
	add ix, wa
	lda xde, (xsp + 50)
	ld (xde), ix
	ld bc, (xbc)
	ld wa, (xhl)
	sub wa, bc
	exts xwa
	divs wa, 0x2
	add bc, wa
	ld (xde + 2), bc
	lda xbc, (xsp + 30)
	ld xwa, xbc
	lda xbc, (xbc + 20)

AccIll_ClearDrawBuffer2:
	stib_dpi 0xE0, 0x00
	cp xwa, xbc
	jr c, AccIll_ClearDrawBuffer2
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 26)
	ld xbc, 0x1E00045
	lds32 xde, 1
	call ApFuncCall
	lda xde, (xsp + 8)
	ld (xde), xhl
	lda xwa, (xsp + 30)
	ld (xde + 18), xwa
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 26)
	ld xbc, 0x1E8004C
	call ApFuncCall
	lda xwa, (xsp + 54)
	lda xbc, (xsp + 50)
	lda xde, (xsp + 30)
	lds32 xhl, 1
	push xhl
	pushw 0x0
	pushw 0xFF

AccIll_CallDrawRoutine:
	call DrawStringLeftJustify
	jrl AccIll_ReturnZero

AccIll_HandleUpScroll:
	ld xwa, (xsp + 66)
	ld xbc, xiz
	ld xde, (xsp + 62)
	call InheritedProc
	ld xwa, (xsp + 62)
	or xwa, xwa
	jr nz, AccIll_UpScroll_Mode1
	ld xwa, 0x1480002
	ld xbc, 0x1E80011
	lds32 xde, 1
	jr AccIll_UpScroll_Dispatch

AccIll_UpScroll_Mode1:
	ld xwa, (xsp + 62)
	cp xwa, 0x1
	jr nz, AccIll_UpScroll_Refresh
	ld xwa, 0x1480002
	ld xbc, 0x1E80012
	ld xde, 0x100

AccIll_UpScroll_Dispatch:
	call MainPostEvent

AccIll_UpScroll_Refresh:
	ld xwa, (xsp + 66)
	ld xbc, xiz
	ld xde, (xsp + 62)
	call SetAutoInc
	ld xwa, (xsp + 66)
	ld xbc, 0x1C00017
	lds32 xde, 1
	call SetDialUp
	ld xwa, (xsp + 66)
	ld xbc, 0x1C00018
	lds32 xde, 1
	call SetDialDown
	lds wa, 1
	jr AccIll_CallSortedUpdate

AccIll_HandleDownScroll:
	ld xwa, (xsp + 66)
	ld xbc, xiz
	ld xde, (xsp + 62)
	call InheritedProc
	ld xwa, (xsp + 62)
	or xwa, xwa
	jr nz, AccIll_DownScroll_Mode1
	ld xwa, 0x1480002
	ld xbc, 0x1E80011
	ld xde, 0xFFFFFFFF
	jr AccIll_DownScroll_Dispatch

AccIll_DownScroll_Mode1:
	ld xwa, (xsp + 62)
	cp xwa, 0x1
	jr nz, AccIll_DownScroll_Refresh
	ld xwa, 0x1480002
	ld xbc, 0x1E80012
	ld xde, 0xFFFFFF00

AccIll_DownScroll_Dispatch:
	call MainPostEvent

AccIll_DownScroll_Refresh:
	ld xwa, (xsp + 66)
	ld xbc, xiz
	ld xde, (xsp + 62)
	call SetAutoInc
	ld xwa, (xsp + 66)
	ld xbc, 0x1C00017
	lds32 xde, 1
	call SetDialUp
	ld xwa, (xsp + 66)
	ld xbc, 0x1C00018
	lds32 xde, 1
	call SetDialDown
	lds wa, 1

AccIll_CallSortedUpdate:
	call SetDialEnable

AccIll_ReturnZero:
	lds32 xhl, 0
	jr AccIll_Epilogue

AccIll_PassThrough:
	ld xwa, (xsp + 66)
	ld xbc, xiz
	ld xde, (xsp + 62)
	call InheritedProc

AccIll_Epilogue:
	pop xiz
	lda xsp, (xsp + 66)
	ret

EffectBoxProc:
	st_dri3b L, 0xFD, 0xAA, 0xFE
	push xiz
	st_dri3l XDE, 0xFD, 0x4E, 0x01
	st_dri3l XBC, 0xFD, 0x52, 0x01
	st_dri3l XWA, 0xFD, 0x56, 0x01
	ld xiy, 0xE34900
	lda xix, (xsp + 12)
	ldiw
	ldiw
	ld xiy, 0xE34904
	lda xix, (xsp + 8)
	ldiw
	ldiw
	ld_sril XWA, (xsp + 0x0152)
	cp xwa, 0x1C00018
	jrl z, LABEL_F33D60
	cp xwa, 0x1C00017
	jrl z, LABEL_F33B77
	cp xwa, 0x1C80001
	jrl z, LABEL_F339BF
	cp xwa, 0x1C80000
	jrl z, LABEL_F33627
	cp xwa, 0x1E8000F
	jrl z, LABEL_F335E7
	cp xwa, 0x1E8000E
	jrl z, LABEL_F335D9
	cp xwa, 0x1C0000E
	jrl z, LABEL_F3354A
	cp xwa, 0x1C0000B
	jrl nz, LABEL_F33F96
	ld_sril XWA, (xsp + 0x0156)
	ld_sril XBC, (xsp + 0x0152)
	ld_sril XDE, (xsp + 0x014e)
	call InheritedProc
	ld_sril XWA, (xsp + 0x0156)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 28)
	ld xbc, 0x1E8000C
	lds32 xde, 0
	call ApFuncCall
	ld xwa, (xiz + 28)
	ld xbc, 0x1E8000A
	lds32 xde, 0
	call ApFuncCall
	ld_sril XWA, (xsp + 0x0156)
	ld xbc, 0x1C0000E
	lds32 xde, 1
	call SendEvent
	ld_sril XDE, (xsp + 0x0156)
	ld xwa, 0x1480002
	ld_sril XBC, (xsp + 0x0152)
	call MainPostEvent
	ld_sril XWA, (xsp + 0x0156)
	ld xbc, 0x1C00017
	lds32 xde, 2
	call SetDialUp
	ld_sril XWA, (xsp + 0x0156)
	ld xbc, 0x1C00018
	lds32 xde, 2
	call SetDialDown
	lds wa, 1
	jrl LABEL_F33B70

LABEL_F3354A:
	ld_sril XWA, (xsp + 0x0156)
	ld_sril XBC, (xsp + 0x0152)
	ld_sril XDE, (xsp + 0x014e)
	call InheritedProc
	ld_sril XWA, (xsp + 0x0156)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 28)
	ld xbc, 0x1E80069
	lds32 xde, 0
	call ApFuncCall
	cp l, (xiz + 36)
	jrl nz, EffectBoxProc_ReturnZero
	ld xwa, (xiz + 28)
	ld xbc, 0x1E8000B
	lds32 xde, 0
	call ApFuncCall
	ld xbc, 0xE3357A
	add xbc, xhl
	st_dri3b W, 0xFD, 0x46, 0x01
	lda xde, (xwa + 2)
	ld c, (xbc)
	extz bc
	ld (xde), bc
	ldw (xwa), 0x3A
	ld bc, (xde)
	add bc, 0x10
	ld (xwa + 6), bc
	ld bc, (xwa)
	add bc, 0xDF
	ld (xwa + 4), bc
	ld_sril XBC, (xsp + 0x014e)
	cp xbc, 0x1
	jr nz, LABEL_F335CB
	pushw 0xF2
	lds bc, 1
	lds de, 2
	jr LABEL_F335D2

LABEL_F335CB:
	pushm (xiz + 22)
	lds bc, 1
	lds de, 2

LABEL_F335D2:
	call DrawDesignFrame
	jrl EffectBoxProc_ReturnZero

LABEL_F335D9:
	ld_sril XWA, (xsp + 0x0156)
	ld xbc, 0x1C80000
	lds32 xde, 0
	jr LABEL_F33620

LABEL_F335E7:
	ld_sril XWA, (xsp + 0x0156)
	call GetViewInstance
	ld xwa, (xhl + 28)
	ld xbc, 0x1E8000D
	lds32 xde, 0
	call ApFuncCall
	sub_sril_mr XHL, 0xFD, 0x4E, 0x01
	ld_sril XWA, (xsp + 0x014e)
	cp xwa, 0x8
	jrl nc, EffectBoxProc_ReturnZero
	ld_sril XWA, (xsp + 0x0156)
	ld xbc, 0x1C80001
	ld_sril XDE, (xsp + 0x014e)

LABEL_F33620:
	call SendEvent
	jrl EffectBoxProc_ReturnZero

LABEL_F33627:
	ld_sril XWA, (xsp + 0x0156)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld xbc, 0x1E80069
	lds32 xde, 0
	call ApFuncCall
	ld xwa, (xsp + 4)
	cp l, (xwa + 36)
	jrl nz, EffectBoxProc_ReturnZero
	st_dri3b D, 0xFD, 0x3E, 0x01
	ldw (xix), 0x64
	lda xbc, (xix + 2)
	ldw (xbc), 0x26
	lda xde, (xix + 4)
	ld wa, (xix)
	add wa, 0xB9
	ld (xde), wa
	lda xhl, (xix + 6)
	ld wa, (xbc)
	add wa, 0x14
	ld (xhl), wa
	ld wa, (xde)
	sub wa, (xix)
	exts xwa
	divs wa, 0x2
	ld ix, (xix)
	add ix, wa
	st_dri3b B, 0xFD, 0x3A, 0x01
	ld (xde), ix
	ld bc, (xbc)
	ld wa, (xhl)
	sub wa, bc
	exts xwa
	divs wa, 0x2
	add bc, wa
	ld (xde + 2), bc
	lda xbc, (xsp + 38)
	ld xwa, xbc
	lda xbc, (xbc + 20)

LABEL_F336A1:
	stib_dpi 0xE0, 0x00
	cp xwa, xbc
	jr c, LABEL_F336A1
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld xbc, 0x1E00045
	lds32 xde, 0
	call ApFuncCall
	lda xde, (xsp + 16)
	ld (xde), xhl
	lda xwa, (xsp + 38)
	ld (xde + 18), xwa
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld xbc, 0x1E00047
	call ApFuncCall
	st_dri3b W, 0xFD, 0x3E, 0x01
	st_dri3b A, 0xFD, 0x3A, 0x01
	lda xde, (xsp + 38)
	lds32 xhl, 4
	push xhl
	pushw 0xFF
	ld xhl, (xsp + 10)
	pushm (xhl + 22)
	call DrawStringLeftJustify
	st_dri3b A, 0xFD, 0x3E, 0x01
	ldw (xbc), 0x3A
	ldw wa, 0x3A
	add wa, 0x8C
	ld (xbc + 4), wa
	sub wa, (xbc)
	exts xwa
	divs wa, 0x2
	ld bc, (xbc)
	add bc, wa
	st_dri3w BC, 0xFD, 0x3A, 0x01
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld xbc, 0x1E00045
	lds32 xde, 0
	call ApFuncCall
	lda xde, (xsp + 16)
	ld (xde), xhl
	lda xwa, (xsp + 58)
	ld (xde + 18), xwa
	lda xbc, (xsp + 38)
	ld xwa, xbc
	lda xbc, (xbc + 20)

LABEL_F33739:
	stib_dpi 0xE0, 0x00
	cp xwa, xbc
	jr c, LABEL_F33739
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld xbc, 0x1E80000
	call ApFuncCall
	lds iz, 0

LABEL_F33752:
	st_dri3b B, 0xFD, 0x3E, 0x01
	lda xbc, (xde + 2)
	ld wa, iz
	extz xwa
	ld xhl, 0xE33582
	add xhl, xwa
	ld a, (xhl)
	extz wa
	ld (xbc), wa
	add wa, 0xC
	ld (xde + 6), wa
	ld bc, (xbc)
	sub wa, bc
	exts xwa
	divs wa, 0x2
	add bc, wa
	st_dri3w BC, 0xFD, 0x3C, 0x01
	pushw 0x11
	ld wa, iz
	mul wa, 0x11
	lda xbc, (xsp + 60)
	add xbc, xwa
	push xbc
	lda xwa, (xsp + 44)
	push xwa
	call Strncpy
	lda xsp, (xsp + 10)
	st_dri3b W, 0xFD, 0x3E, 0x01
	st_dri3b A, 0xFD, 0x3A, 0x01
	lda xde, (xsp + 38)
	lds32 xhl, 0
	push xhl
	pushw 0xFF
	ld xhl, (xsp + 10)
	pushm (xhl + 22)
	call DrawStringLeftJustify
	inc 1, iz
	cp iz, 0x8
	jr c, LABEL_F33752
	st_dri3b A, 0xFD, 0x3E, 0x01
	ldw (xbc), 0x100
	ldw wa, 0x100
	add wa, 0x14
	ld (xbc + 4), wa
	sub wa, (xbc)
	exts xwa
	divs wa, 0x2
	ld bc, (xbc)
	add bc, wa
	st_dri3w BC, 0xFD, 0x3A, 0x01
	lda xbc, (xsp + 38)
	ld xwa, xbc
	lda xbc, (xbc + 20)

LABEL_F337EE:
	stib_dpi 0xE0, 0x00
	cp xwa, xbc
	jr c, LABEL_F337EE
	lds iz, 0

LABEL_F337F8:
	st_dri3b B, 0xFD, 0x3E, 0x01
	lda xbc, (xde + 2)
	ld wa, iz
	extz xwa
	ld xhl, 0xE33582
	add xhl, xwa
	ld a, (xhl)
	extz wa
	ld (xbc), wa
	add wa, 0xC
	ld (xde + 6), wa
	ld bc, (xbc)
	sub wa, bc
	exts xwa
	divs wa, 0x2
	add bc, wa
	st_dri3w BC, 0xFD, 0x3C, 0x01
	pushw 0x2
	ld wa, iz
	add wa, wa
	extz xwa
	st_dri3b W, 0xE1, 0x88, 0x00
	lda xbc, (xsp + 60)
	add xbc, xwa
	push xbc
	lda xwa, (xsp + 44)
	push xwa
	call Strncpy
	lda xsp, (xsp + 10)
	st_dri3b W, 0xFD, 0x3E, 0x01
	st_dri3b A, 0xFD, 0x3A, 0x01
	lda xde, (xsp + 38)
	lds32 xhl, 0
	push xhl
	pushw 0xFF
	ld xhl, (xsp + 10)
	pushm (xhl + 22)
	call DrawStringLeftJustify
	inc 1, iz
	cp iz, 0x8
	jr c, LABEL_F337F8
	st_dri3b D, 0xFD, 0x3E, 0x01
	ldw (xix), 0x2B
	lda xde, (xix + 4)
	ld wa, (xix)
	add wa, 0xE
	ld (xde), wa
	lda xbc, (xix + 2)
	ldw (xbc), 0x46
	lda xhl, (xix + 6)
	ldw (xhl), 0x54
	ld wa, (xde)
	sub wa, (xix)
	exts xwa
	divs wa, 0x2
	ld ix, (xix)
	add ix, wa
	st_dri3b B, 0xFD, 0x3A, 0x01
	ld (xde), ix
	ld bc, (xbc)
	ld wa, (xhl)
	sub wa, bc
	exts xwa
	divs wa, 0x2
	add bc, wa
	ld (xde + 2), bc
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld xbc, 0x1E8000D
	lds32 xde, 0
	call ApFuncCall
	or xhl, xhl
	jr z, LABEL_F338E2
	pushw 0x4
	lda xwa, (xsp + 14)
	push xwa
	lda xwa, (xsp + 44)
	push xwa
	call Strncpy
	lda xsp, (xsp + 10)
	ld (xsp + 42), 0x0
	jr LABEL_F338EC

LABEL_F338E2:
	lda xwa, (xsp + 38)
	ld (xwa), 0x20
	ld (xwa + 1), 0x0

LABEL_F338EC:
	st_dri3b W, 0xFD, 0x3E, 0x01
	st_dri3b A, 0xFD, 0x3A, 0x01
	lda xde, (xsp + 38)
	lds32 xhl, 0
	push xhl
	pushw 0xFF
	ld xhl, (xsp + 10)
	pushm (xhl + 22)
	call DrawStringLeftJustify
	st_dri3b A, 0xFD, 0x3E, 0x01
	lda xwa, (xbc + 2)
	ldw (xwa), 0xB6
	ldw (xbc + 6), 0xC4
	ld bc, (xwa)
	ldw wa, 0xC4
	sub wa, bc
	exts xwa
	divs wa, 0x2
	add bc, wa
	st_dri3w BC, 0xFD, 0x3C, 0x01
	ldi_berp 0xFB, 7
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld xbc, 0x1E8000D
	lds32 xde, 0
	call ApFuncCall
	ldto_berp A, 0xFB
	add a, l
	ldfr_berp A, 0xFB
	lds32 xde, 0
	ldto_berp E, 0xFB
	inc 1, xde
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld xbc, 0x1E80009
	call ApFuncCall
	lda xwa, (xsp + 38)
	or xhl, xhl
	jr z, LABEL_F3397C
	pushw 0x4
	lda xbc, (xsp + 10)
	push xbc
	push xwa
	call Strncpy
	lda xsp, (xsp + 10)
	ld (xsp + 42), 0x0
	jr LABEL_F33983

LABEL_F3397C:
	ld (xwa), 0x20
	ld (xwa + 1), 0x0

LABEL_F33983:
	st_dri3b W, 0xFD, 0x3E, 0x01
	st_dri3b A, 0xFD, 0x3A, 0x01
	lda xde, (xsp + 38)
	lds32 xhl, 0
	push xhl
	pushw 0xFF
	ld xhl, (xsp + 10)
	pushm (xhl + 22)
	call DrawStringLeftJustify
	lds iz, 0

LABEL_F339A2:
	ld de, iz
	extz xde
	ld_sril XWA, (xsp + 0x0156)
	ld xbc, 0x1C80001
	call SendEvent
	inc 1, iz
	cp iz, 0x8
	jr c, LABEL_F339A2
	jrl EffectBoxProc_ReturnZero

LABEL_F339BF:
	ld_sril XWA, (xsp + 0x014e)
	cp xwa, 0x7
	jrl ugt, EffectBoxProc_ReturnZero
	ld_sril XWA, (xsp + 0x0156)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld xbc, 0x1E80069
	lds32 xde, 0
	call ApFuncCall
	ld xwa, (xsp + 4)
	cp l, (xwa + 36)
	jrl nz, EffectBoxProc_ReturnZero
	st_dri3b D, 0xFD, 0x3E, 0x01
	ldw (xix), 0xC3
	lda xde, (xix + 4)
	ld wa, (xix)
	add wa, 0x3D
	ld (xde), wa
	lda xbc, (xix + 2)
	ld xwa, 0xE33582
	add_sril_rm XWA, 0xFD, 0x4E, 0x01
	ld a, (xwa)
	extz wa
	ld (xbc), wa
	lda xhl, (xix + 6)
	add wa, 0xC
	ld (xhl), wa
	ld wa, (xde)
	sub wa, (xix)
	exts xwa
	divs wa, 0x2
	ld ix, (xix)
	add ix, wa
	st_dri3b B, 0xFD, 0x3A, 0x01
	ld (xde), ix
	ld bc, (xbc)
	ld wa, (xhl)
	sub wa, bc
	exts xwa
	divs wa, 0x2
	add bc, wa
	ld (xde + 2), bc
	lda xbc, (xsp + 38)
	ld xwa, xbc
	lda xbc, (xbc + 20)

; EffectBox name setup dispatch
EffectBox_NameSetup:
	stib_dpi 0xE0, 0x00
	cp xwa, xbc
	jr c, EffectBox_NameSetup
	ld_sril XDE, (xsp + 0x014e)
	inc 1, xde
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld xbc, 0x1E00045
	call ApFuncCall
	lda xde, (xsp + 16)
	ld (xde), xhl
	lda xwa, (xsp + 58)
	ld (xde + 18), xwa
	ld_sril XHL, (xsp + 0x014e)
	ld xwa, (xsp + 4)
	lda xbc, (xwa + 28)
	dec 1, xhl
	cp xhl, 0x0
	jr c, EffectBoxProc_CopyNameAndSetup
	cp xhl, 0x6
	jr ugt, EffectBoxProc_CopyNameAndSetup
	add xhl, xhl
	add xhl, 0xE34908
	ld hl, (xhl)
	lda_24 xix, 0xf33aab
	jp_dri 8, 0x07, 0xF0, 0xEC
; EffectBoxProc dispatch
EffectBox_Dispatch:
	ld	xwa, (xbc)
	ld	xbc, 31981570
	jr	65
	ld	xwa, (xbc)
	ld	xbc, 31981571
	jr	56
	ld	xwa, (xbc)
	ld	xbc, 31981572
	jr	47
	ld	xwa, (xbc)
	ld	xbc, 31981573
	jr	38
	ld	xwa, (xbc)
	ld	xbc, 31981574
	jr	29
	ld	xwa, (xbc)
	ld	xbc, 31981575
	jr	20
	ld	xwa, (xbc)
	ld	xbc, 31981576
	jr	11

EffectBoxProc_CopyNameAndSetup:
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld xbc, 0x1E80001
	call ApFuncCall
	pushw 0x7
	lda xwa, (xsp + 60)
	push xwa
	lda xwa, (xsp + 44)
	push xwa
	call Strncpy
	lda xsp, (xsp + 10)
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld xbc, 0x1E8000B
	lds32 xde, 0
	call ApFuncCall
	st_dri3b W, 0xFD, 0x3E, 0x01
	st_dri3b A, 0xFD, 0x3A, 0x01
	cp_sril_rm XHL, 0xFD, 0x4E, 0x01
	jr nz, LABEL_F33B3B
	lda xde, (xsp + 38)
	lds32 xhl, 0
	push xhl
	pushw 0x0
	pushw 0xFF
	jr LABEL_F33B4A

LABEL_F33B3B:
	lda xde, (xsp + 38)
	lds32 xhl, 0
	push xhl
	pushw 0xFF
	ld xhl, (xsp + 10)
	pushm (xhl + 22)

LABEL_F33B4A:
	call DrawStringLeftJustify
	ld_sril XWA, (xsp + 0x0156)
	ld xbc, 0x1C00017
	lds32 xde, 2
	call SetDialUp
	ld_sril XWA, (xsp + 0x0156)
	ld xbc, 0x1C00018
	lds32 xde, 2
	call SetDialDown
	lds wa, 1

LABEL_F33B70:
	call SetDialEnable
	jrl EffectBoxProc_ReturnZero

LABEL_F33B77:
	ld_sril XWA, (xsp + 0x0156)
	ld_sril XBC, (xsp + 0x0152)
	ld_sril XDE, (xsp + 0x014e)
	call InheritedProc
	ld_sril XWA, (xsp + 0x0156)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	lda xbc, (xwa + 28)
	ld_sril XWA, (xsp + 0x014e)
	cp xwa, 0x1
	jrl nz, LABEL_F33C91
	ld xwa, (xbc)
	ld xbc, 0x1E8000B
	lds32 xde, 0
	call ApFuncCall
	ldfr_berp L, 0xFA
	cpi_berp 0xFA, 0
	jr z, LABEL_F33C23
	ld_sril XWA, (xsp + 0x0156)
	ld xbc, 0x1C0000E
	lds32 xde, 0
	call SendEvent
	ldto_berp A, 0xFA
	dec 1, a
	ldfr_berp A, 0xFB
	lds32 xde, 0
	ldto_berp E, 0xFB
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld xbc, 0x1E8000A
	call ApFuncCall
	ld_sril XWA, (xsp + 0x0156)
	ld xbc, 0x1C0000E
	lds32 xde, 1
	call SendEvent
	lds32 xde, 0
	ldto_berp E, 0xFA
	ld_sril XWA, (xsp + 0x0156)
	ld xbc, 0x1C80001
	call SendEvent
	lds32 xde, 0
	ldto_berp E, 0xFB
	ld_sril XWA, (xsp + 0x0156)
	ld xbc, 0x1C80001
	call SendEvent
	jr EffectBoxProc_RestoreAndJumpToDispatch

LABEL_F33C23:
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld xbc, 0x1E8000D
	lds32 xde, 0
	call ApFuncCall
	ldfr_berp L, 0xFB
	cpi_berp 0xFB, 0
	jr z, EffectBoxProc_RestoreAndJumpToDispatch
	dec1_berp 0xFB
	lds32 xde, 0
	ldto_berp E, 0xFB
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld xbc, 0x1E8000C
	call ApFuncCall
	ld_sril XWA, (xsp + 0x0156)
	ld xbc, 0x1C80000
	lds32 xde, 0
	call SendEvent
	lds iz, 0

LABEL_F33C65:
	ld de, iz
	extz xde
	ld_sril XWA, (xsp + 0x0156)
	ld xbc, 0x1C80001
	call SendEvent
	inc 1, iz
	cp iz, 0x8
	jr c, LABEL_F33C65

EffectBoxProc_RestoreAndJumpToDispatch:
	ld_sril XWA, (xsp + 0x0156)
	ld_sril XBC, (xsp + 0x0152)
	ld_sril XDE, (xsp + 0x014e)
	jrl EffectBox_SetAutoInc

LABEL_F33C91:
	ld_sril XWA, (xsp + 0x014e)
	cp xwa, 0x2
	jr nz, LABEL_F33CF2
	ld xwa, (xbc)
	ld xbc, 0x1E8000D
	lds32 xde, 0
	call ApFuncCall
	ldfr_berp L, 0xFB
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld xbc, 0x1E8000B
	lds32 xde, 0
	call ApFuncCall
	ldto_berp A, 0xFB
	add a, l
	ldfr_berp A, 0xFB
	lds32 xde, 0
	ldto_berp E, 0xFB
	add xde, 0x100
	ld xwa, 0x1480002
	ld xbc, 0x1E80012
	call MainPostEvent
	ld_sril XWA, (xsp + 0x0156)
	ld_sril XBC, (xsp + 0x0152)
	ld_sril XDE, (xsp + 0x014e)
	jrl EffectBox_SetAutoInc

LABEL_F33CF2:
	ld_sril XWA, (xsp + 0x014e)
	or xwa, xwa
	jrl nz, EffectBoxProc_ReturnZero
	ld xwa, 0x1480002
	ld xbc, 0x1E80011
	lds32 xde, 1
	call MainPostEvent
	ld_sril XWA, (xsp + 0x0156)
	ld xbc, 0x1C0000E
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld xbc, 0x1E8000C
	lds32 xde, 0
	call ApFuncCall
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld xbc, 0x1E8000A
	lds32 xde, 0
	call ApFuncCall
	ld_sril XWA, (xsp + 0x0156)
	ld xbc, 0x1C0000E
	lds32 xde, 1
	call SendEvent
	ld_sril XWA, (xsp + 0x0156)
	ld_sril XBC, (xsp + 0x0152)
	ld_sril XDE, (xsp + 0x014e)
	jrl EffectBox_SetAutoInc

LABEL_F33D60:
	ld_sril XWA, (xsp + 0x0156)
	ld_sril XBC, (xsp + 0x0152)
	ld_sril XDE, (xsp + 0x014e)
	call InheritedProc
	ld_sril XWA, (xsp + 0x0156)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld_sril XBC, (xsp + 0x014e)
	cp xbc, 0x1
	jrl nz, LABEL_F33EC3
	ld xbc, 0x1E8000B
	lds32 xde, 0
	call ApFuncCall
	ldfr_berp L, 0xFA
	ld xwa, (xsp + 4)
	lda xbc, (xwa + 28)
	cpi_berp 0xFA, 7
	jr nc, LABEL_F33E2A
	ldto_berp E, 0xFA
	inc 1, e
	ldb d, 0x0
	extz xde
	ld xwa, (xbc)
	ld xbc, 0x1E80009
	call ApFuncCall
	or xhl, xhl
	jrl z, LABEL_F33EB1
	ld_sril XWA, (xsp + 0x0156)
	ld xbc, 0x1C0000E
	lds32 xde, 0
	call SendEvent
	ldto_berp A, 0xFA
	inc 1, a
	ldfr_berp A, 0xFB
	lds32 xde, 0
	ldto_berp E, 0xFB
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld xbc, 0x1E8000A
	call ApFuncCall
	ld_sril XWA, (xsp + 0x0156)
	ld xbc, 0x1C0000E
	lds32 xde, 1
	call SendEvent
	lds32 xde, 0
	ldto_berp E, 0xFA
	ld_sril XWA, (xsp + 0x0156)
	ld xbc, 0x1C80001
	call SendEvent
	lds32 xde, 0
	ldto_berp E, 0xFB
	ld_sril XWA, (xsp + 0x0156)
	ld xbc, 0x1C80001
	call SendEvent
	jrl LABEL_F33EB1

LABEL_F33E2A:
	ld xwa, (xbc)
	ld xbc, 0x1E8000D
	lds32 xde, 0
	call ApFuncCall
	ldto_berp A, 0xFA
	add a, l
	ldfr_berp A, 0xFA
	ldto_berp E, 0xFA
	inc 1, e
	ldb d, 0x0
	extz xde
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld xbc, 0x1E80009
	call ApFuncCall
	or xhl, xhl
	jr z, LABEL_F33EB1
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld xbc, 0x1E8000D
	lds32 xde, 0
	call ApFuncCall
	inc 1, l
	ldfr_berp L, 0xFB
	lds32 xde, 0
	ldto_berp E, 0xFB
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld xbc, 0x1E8000C
	call ApFuncCall
	ld_sril XWA, (xsp + 0x0156)
	ld xbc, 0x1C80000
	lds32 xde, 0
	call SendEvent
	lds iz, 0

LABEL_F33E97:
	ld de, iz
	extz xde
	ld_sril XWA, (xsp + 0x0156)
	ld xbc, 0x1C80001
	call SendEvent
	inc 1, iz
	cp iz, 0x8
	jr c, LABEL_F33E97

LABEL_F33EB1:
	ld_sril XWA, (xsp + 0x0156)
	ld_sril XBC, (xsp + 0x0152)
	ld_sril XDE, (xsp + 0x014e)
	jrl EffectBox_SetAutoInc

LABEL_F33EC3:
	ld_sril XBC, (xsp + 0x014e)
	cp xbc, 0x2
	jr nz, LABEL_F33F21
	ld xbc, 0x1E8000D
	lds32 xde, 0
	call ApFuncCall
	ldfr_berp L, 0xFB
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld xbc, 0x1E8000B
	lds32 xde, 0
	call ApFuncCall
	ldto_berp A, 0xFB
	add a, l
	ldfr_berp A, 0xFB
	lds32 xde, 0
	ldto_berp E, 0xFB
	add xde, 0xFFFFFF00
	ld xwa, 0x1480002
	ld xbc, 0x1E80012
	call MainPostEvent
	ld_sril XWA, (xsp + 0x0156)
	ld_sril XBC, (xsp + 0x0152)
	ld_sril XDE, (xsp + 0x014e)
	jr EffectBox_SetAutoInc

LABEL_F33F21:
	ld_sril XWA, (xsp + 0x014e)
	or xwa, xwa
	jr nz, EffectBoxProc_ReturnZero
	ld xwa, 0x1480002
	ld xbc, 0x1E80011
	ld xde, 0xFFFFFFFF
	call MainPostEvent
	ld_sril XWA, (xsp + 0x0156)
	ld xbc, 0x1C0000E
	lds32 xde, 0
	call SendEvent
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld xbc, 0x1E8000C
	lds32 xde, 0
	call ApFuncCall
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld xbc, 0x1E8000A
	lds32 xde, 0
	call ApFuncCall
	ld_sril XWA, (xsp + 0x0156)
	ld xbc, 0x1C0000E
	lds32 xde, 1
	call SendEvent
	ld_sril XWA, (xsp + 0x0156)
	ld_sril XBC, (xsp + 0x0152)
	ld_sril XDE, (xsp + 0x014e)

EffectBox_SetAutoInc:
	call SetAutoInc

EffectBoxProc_ReturnZero:
	lds32 xhl, 0
	jr LABEL_F33FA9

LABEL_F33F96:
	ld_sril XWA, (xsp + 0x0156)
	ld_sril XBC, (xsp + 0x0152)
	ld_sril XDE, (xsp + 0x014e)
	call InheritedProc

LABEL_F33FA9:
	pop xiz
	st_dri3b L, 0xFD, 0x56, 0x01
	ret

EqualizerBoxProc:
	lda xsp, (xsp - 92)
	push xiz
	ld (xsp + 88), xde
	ld xiz, xbc
	ld (xsp + 92), xwa
	cp xiz, 0x1C80002
	jrl z, LABEL_F3425D
	cp xiz, 0x1C00018
	jrl z, LABEL_F341FC
	cp xiz, 0x1C00017
	jrl z, LABEL_F341A0
	cp xiz, 0x1C80003
	jrl z, LABEL_F34061
	cp xiz, 0x1E8000F
	jr z, LABEL_F34041
	cp xiz, 0x1E8000E
	jr z, LABEL_F34016
	cp xiz, 0x1C0000B
	jrl nz, LABEL_F345D3
	ld xwa, (xsp + 92)
	ld xbc, xiz
	ld xde, (xsp + 88)
	call InheritedProc
	ld xde, (xsp + 92)
	ld xwa, 0x1480002
	ld xbc, xiz
	call MainPostEvent
	jrl SeqAccomp_ReturnZeroJmp

LABEL_F34016:
	ld xwa, (xsp + 92)
	ld xbc, 0x1C80002
	lds32 xde, 1
	call SendEvent
	lds iz, 0

LABEL_F34026:
	ld de, iz
	extz xde
	ld xwa, (xsp + 92)
	ld xbc, 0x1C80003
	call SendEvent
	inc 1, iz
	cp iz, 0x8
	jr c, LABEL_F34026
	jrl SeqAccomp_ReturnZeroJmp

LABEL_F34041:
	ld xwa, (xsp + 92)
	ld xbc, 0x1C80002
	lds32 xde, 1
	call SendEvent
	ld xwa, (xsp + 92)
	ld xbc, 0x1C80003
	ld xde, (xsp + 88)
	call SendEvent
	jrl SeqAccomp_ReturnZeroJmp

LABEL_F34061:
	ld xwa, (xsp + 88)
	cp xwa, 0x7
	jrl ugt, SeqAccomp_ReturnZeroJmp
	ld xwa, (xsp + 92)
	call GetViewInstance
	ld (xsp + 22), xhl
	ld xwa, (xsp + 22)
	ld xwa, (xwa + 28)
	ld xbc, 0x1E80069
	lds32 xde, 0
	call ApFuncCall
	ld xwa, (xsp + 22)
	cp l, (xwa + 32)
	jrl nz, SeqAccomp_ReturnZeroJmp
	lda xix, (xsp + 80)
	ld xhl, (xsp + 88)
	add xhl, xhl
	ld xwa, 0xE34926
	add xwa, xhl
	ld wa, (xwa)
	ld (xix), wa
	lda xde, (xix + 4)
	ld wa, (xix)
	add wa, 0x3C
	ld (xde), wa
	lda xbc, (xix + 2)
	ld xwa, 0xE34916
	add xwa, xhl
	ld wa, (xwa)
	ld (xbc), wa
	lda xhl, (xix + 6)
	add wa, 0x10
	ld (xhl), wa
	ld wa, (xde)
	sub wa, (xix)
	exts xwa
	divs wa, 0x2
	ld ix, (xix)
	add ix, wa
	lda xde, (xsp + 76)
	ld (xde), ix
	ld bc, (xbc)
	ld wa, (xhl)
	sub wa, bc
	exts xwa
	divs wa, 0x2
	add bc, wa
	ld (xde + 2), bc
	lda xbc, (xsp + 26)
	ld xwa, xbc
	lda xbc, (xbc + 20)

; EffectBox state dispatch
EffectBox_StateDispatch:
	stib_dpi 0xE0, 0x00
	cp xwa, xbc
	jr c, EffectBox_StateDispatch
	ld xwa, (xsp + 22)
	ld xwa, (xwa + 28)
	ld xbc, 0x1E00045
	ld xde, (xsp + 88)
	call ApFuncCall
	lda xde, (xsp + 46)
	ld (xde), xhl
	lda xwa, (xsp + 26)
	ld (xde + 18), xwa
	ld xbc, (xsp + 88)
	ld xwa, (xsp + 22)
	lda xhl, (xwa + 28)
	ld xwa, (xhl)
	dec 1, xbc
	cp xbc, 0x0
	jr c, EffectBox_State1
	cp xbc, 0x6
	jr ugt, EffectBox_State1
	add xbc, xbc
	add xbc, 0xE34936
	ld bc, (xbc)
	lda_24 xix, 0xf34148
	jp_dri 8, 0x07, 0xF0, 0xE4
; SeqAccomp editor load dispatch
SeqAccomp_Dispatch:
	.byte 0x41, 0x62, 0x00, 0xe8, 0x01, 0x68, 0x31, 0x41
	.byte 0x63, 0x00, 0xe8, 0x01
	.asciz "h*Ad"
	.byte 0xe8, 0x01
	.asciz "h#Ae"
	.byte 0xe8, 0x01, 0x68, 0x1c, 0x41, 0x66, 0x00, 0xe8
	.byte 0x01, 0x68, 0x15, 0x41, 0x67, 0x00, 0xe8, 0x01
	.byte 0x68, 0x0e, 0x41, 0x68, 0x00, 0xe8, 0x01, 0x68
	.byte 0x07

; EffectBox state 1
EffectBox_State1:
	ld xwa, (xhl)
	ld xbc, 0x1E80061
	call ApFuncCall
	lda xwa, (xsp + 80)
	lda xbc, (xsp + 76)
	lda xde, (xsp + 26)
	lds32 xhl, 0
	push xhl
	pushw 0xFF
	ld xhl, (xsp + 28)
	pushm (xhl + 22)
	call DrawStringLeftJustify
	jrl SeqAccomp_ReturnZeroJmp

LABEL_F341A0:
	ld xwa, (xsp + 92)
	ld xbc, xiz
	ld xde, (xsp + 88)
	call InheritedProc
	ld xwa, (xsp + 88)
	cp xwa, 0x8
	jrl nc, SeqAccomp_ReturnZeroJmp
	ld xde, 0x100
	add xde, (xsp + 88)
	ld xwa, 0x1480002
	ld xbc, 0x1E80012
	call MainPostEvent
	ld xwa, (xsp + 92)
	ld xbc, 0x1C00017
	ld xde, (xsp + 88)
	call SetDialUp
	ld xwa, (xsp + 92)
	ld xbc, 0x1C00018
	ld xde, (xsp + 88)
	call SetDialDown
	lds wa, 1
	call SetDialEnable
	ld xwa, (xsp + 92)
	ld xbc, xiz
	ld xde, (xsp + 88)
	jr LABEL_F34256

LABEL_F341FC:
	ld xwa, (xsp + 92)
	ld xbc, xiz
	ld xde, (xsp + 88)
	call InheritedProc
	ld xwa, (xsp + 88)
	cp xwa, 0x8
	jrl nc, SeqAccomp_ReturnZeroJmp
	ld xde, 0xFFFFFF00
	add xde, (xsp + 88)
	ld xwa, 0x1480002
	ld xbc, 0x1E80012
	call MainPostEvent
	ld xwa, (xsp + 92)
	ld xbc, 0x1C00017
	ld xde, (xsp + 88)
	call SetDialUp
	ld xwa, (xsp + 92)
	ld xbc, 0x1C00018
	ld xde, (xsp + 88)
	call SetDialDown
	lds wa, 1
	call SetDialEnable
	ld xwa, (xsp + 92)
	ld xbc, xiz
	ld xde, (xsp + 88)

LABEL_F34256:
	call SetAutoInc
	jrl SeqAccomp_ReturnZeroJmp

LABEL_F3425D:
	ld xwa, (xsp + 92)
	call GetViewInstance
	ld (xsp + 22), xhl
	ld xwa, (xsp + 22)
	ld (xsp + 4), xwa
	ld xwa, (xwa + 28)
	ld xbc, 0x1E80069
	lds32 xde, 0
	call ApFuncCall
	ld xwa, (xsp + 22)
	cp l, (xwa + 32)
	jrl nz, SeqAccomp_ReturnZeroJmp
	lda xwa, (xsp + 80)
	ldw (xwa), 0x20
	ldw (xwa + 2), 0x24
	ldw (xwa + 4), 0xF8
	ldw (xwa + 6), 0x78
	lds bc, 0
	ldw de, 0xF5
	call DrawDesignBox
	ld xwa, (xsp + 22)
	ld xwa, (xwa + 28)
	ld xbc, 0x1E80013
	lds32 xde, 1
	call ApFuncCall
	extz hl
	ld (xsp + 8), hl
	ld xwa, (xsp + 22)
	ld xwa, (xwa + 28)
	ld xbc, 0x1E80013
	lds32 xde, 2
	call ApFuncCall
	extz hl
	ld (xsp + 10), hl
	ld xwa, (xsp + 22)
	ld xwa, (xwa + 28)
	ld xbc, 0x1E80013
	lds32 xde, 3
	call ApFuncCall
	extz hl
	ld (xsp + 12), hl
	ld xwa, (xsp + 22)
	ld xwa, (xwa + 28)
	ld xbc, 0x1E80013
	lds32 xde, 4
	call ApFuncCall
	extz hl
	ld (xsp + 14), hl
	ld xwa, (xsp + 22)
	ld xwa, (xwa + 28)
	ld xbc, 0x1E80013
	lds32 xde, 5
	call ApFuncCall
	extz hl
	ld (xsp + 16), hl
	ld xwa, (xsp + 22)
	ld xwa, (xwa + 28)
	ld xbc, 0x1E80013
	lds32 xde, 6
	call ApFuncCall
	extz hl
	ld (xsp + 18), hl
	ld xwa, (xsp + 22)
	ld xwa, (xwa + 28)
	ld xbc, 0x1E80013
	lds32 xde, 7
	call ApFuncCall
	extz hl
	ld (xsp + 20), hl
	ld xwa, (xsp + 22)
	ld xwa, (xwa + 28)
	ld xbc, 0x1E80013
	ld xde, 0x8
	call ApFuncCall
	extz hl
	ld (xsp + 22), hl
	ld xwa, (xsp + 88)
	cp xwa, 0x1
	jr nz, LABEL_F34368
	ldw (xsp + 24), 0xFB
	jr LABEL_F34371

LABEL_F34368:
	ld xwa, (xsp + 4)
	ld wa, (xwa + 22)
	ld (xsp + 24), wa

LABEL_F34371:
	lda xwa, (xsp + 72)
	ldw (xwa), 0x20
	ld hl, (xsp + 10)
	ld (xwa + 2), hl
	lda xbc, (xsp + 68)
	ld de, (xsp + 8)
	ld (xbc), de
	ld (xbc + 2), hl
	ld de, (xsp + 24)
	call DrawLine
	ld wa, (xsp + 12)
	sub wa, (xsp + 8)
	cp wa, 0x14
	jr ule, LABEL_F343A1
	ldw iz, 0xA
	jr LABEL_F343A6

LABEL_F343A1:
	ld iz, wa
	srl iz, 1

LABEL_F343A6:
	lda xwa, (xsp + 72)
	ld bc, (xsp + 8)
	ld (xwa), bc
	ld bc, (xsp + 10)
	ld (xwa + 2), bc
	lda xbc, (xsp + 68)
	ld de, (xsp + 8)
	add de, iz
	ld (xbc), de
	ldw (xbc + 2), 0x4D
	ld de, (xsp + 24)
	call DrawLine
	lda xwa, (xsp + 72)
	ld bc, (xsp + 8)
	add bc, iz
	ld (xwa), bc
	ldw (xwa + 2), 0x4D
	lda xbc, (xsp + 68)
	ld de, (xsp + 12)
	sub de, iz
	ld (xbc), de
	ldw (xbc + 2), 0x4D
	ld de, (xsp + 24)
	call DrawLine
	lda xwa, (xsp + 72)
	ld bc, (xsp + 12)
	sub bc, iz
	ld (xwa), bc
	ldw (xwa + 2), 0x4D
	lda xbc, (xsp + 68)
	ld de, (xsp + 12)
	ld (xbc), de
	ld de, (xsp + 14)
	ld (xbc + 2), de
	ld de, (xsp + 24)
	call DrawLine
	ld wa, (xsp + 16)
	sub wa, (xsp + 12)
	cp wa, 0x14
	jr ule, LABEL_F34424
	ldw iz, 0xA
	jr LABEL_F34429

LABEL_F34424:
	ld iz, wa
	srl iz, 1

LABEL_F34429:
	lda xwa, (xsp + 72)
	ld bc, (xsp + 12)
	ld (xwa), bc
	ld bc, (xsp + 14)
	ld (xwa + 2), bc
	lda xbc, (xsp + 68)
	ld de, (xsp + 12)
	add de, iz
	ld (xbc), de
	ldw (xbc + 2), 0x4D
	ld de, (xsp + 24)
	call DrawLine
	lda xwa, (xsp + 72)
	ld bc, (xsp + 12)
	add bc, iz
	ld (xwa), bc
	ldw (xwa + 2), 0x4D
	lda xbc, (xsp + 68)
	ld de, (xsp + 16)
	sub de, iz
	ld (xbc), de
	ldw (xbc + 2), 0x4D
	ld de, (xsp + 24)
	call DrawLine
	lda xwa, (xsp + 72)
	ld bc, (xsp + 16)
	sub bc, iz
	ld (xwa), bc
	ldw (xwa + 2), 0x4D
	lda xbc, (xsp + 68)
	ld de, (xsp + 16)
	ld (xbc), de
	ld de, (xsp + 18)
	ld (xbc + 2), de
	ld de, (xsp + 24)
	call DrawLine
	ld wa, (xsp + 20)
	sub wa, (xsp + 16)
	cp wa, 0x14
	jr ule, LABEL_F344A7
	ldw iz, 0xA
	jr LABEL_F344AC

LABEL_F344A7:
	ld iz, wa
	srl iz, 1

LABEL_F344AC:
	lda xwa, (xsp + 72)
	ld bc, (xsp + 16)
	ld (xwa), bc
	ld bc, (xsp + 18)
	ld (xwa + 2), bc
	lda xbc, (xsp + 68)
	ld de, (xsp + 16)
	add de, iz
	ld (xbc), de
	ldw (xbc + 2), 0x4D
	ld de, (xsp + 24)
	call DrawLine
	lda xwa, (xsp + 72)
	ld bc, (xsp + 16)
	add bc, iz
	ld (xwa), bc
	ldw (xwa + 2), 0x4D
	lda xbc, (xsp + 68)
	ld de, (xsp + 20)
	sub de, iz
	ld (xbc), de
	ldw (xbc + 2), 0x4D
	ld de, (xsp + 24)
	call DrawLine
	lda xwa, (xsp + 72)
	ld bc, (xsp + 20)
	sub bc, iz
	ld (xwa), bc
	ldw (xwa + 2), 0x4D
	lda xbc, (xsp + 68)
	ld de, (xsp + 20)
	ld (xbc), de
	ld de, (xsp + 22)
	ld (xbc + 2), de
	ld de, (xsp + 24)
	call DrawLine
	lda xwa, (xsp + 72)
	ld bc, (xsp + 20)
	ld (xwa), bc
	ld de, (xsp + 22)
	ld (xwa + 2), de
	lda xbc, (xsp + 68)
	ldw (xbc), 0xF8
	ld (xbc + 2), de
	ld de, (xsp + 24)
	call DrawLine
	ld xwa, (xsp + 88)
	cp xwa, 0x1
	jr nz, LABEL_F3454A
	ldw (xsp + 24), 0xFF
	jr LABEL_F34553

LABEL_F3454A:
	ld xwa, (xsp + 4)
	ld wa, (xwa + 22)
	ld (xsp + 24), wa

LABEL_F34553:
	lda xwa, (xsp + 72)
	ld de, (xsp + 8)
	ld (xwa), de
	ld bc, (xsp + 10)
	ld (xwa + 2), bc
	lda xbc, (xsp + 68)
	ld (xbc), de
	ldw (xbc + 2), 0x78
	ld de, (xsp + 24)
	call DrawLine
	lda xwa, (xsp + 72)
	ld de, (xsp + 12)
	ld (xwa), de
	ld bc, (xsp + 14)
	ld (xwa + 2), bc
	lda xbc, (xsp + 68)
	ld (xbc), de
	ldw (xbc + 2), 0x78
	ld de, (xsp + 24)
	call DrawLine
	lda xwa, (xsp + 72)
	ld de, (xsp + 16)
	ld (xwa), de
	ld bc, (xsp + 18)
	ld (xwa + 2), bc
	lda xbc, (xsp + 68)
	ld (xbc), de
	ldw (xbc + 2), 0x78
	ld de, (xsp + 24)
	call DrawLine
	lda xwa, (xsp + 72)
	ld de, (xsp + 20)
	ld (xwa), de
	ld bc, (xsp + 22)
	ld (xwa + 2), bc
	lda xbc, (xsp + 68)
	ld (xbc), de
	ldw (xbc + 2), 0x78
	ld de, (xsp + 24)
	call DrawLine

SeqAccomp_ReturnZeroJmp:
	lds32 xhl, 0
	jr LABEL_F345DF

LABEL_F345D3:
	ld xwa, (xsp + 92)
	ld xbc, xiz
	ld xde, (xsp + 88)
	call InheritedProc

LABEL_F345DF:
	pop xiz
	lda xsp, (xsp + 92)
	ret

EqOnOffFuncToggleProc:
	push xiz
	ld xiz, xwa
	cp xbc, 0x1C0001C
	jr z, LABEL_F34628
	cp xbc, 0x1C00001
	jr z, LABEL_F345FF
	ld xwa, xiz
	call InheritedProc
	jr SqplyFunc_FormatEntry

LABEL_F345FF:
	ld xwa, xiz
	call InheritedProc
	ld xwa, 0x4006
	call SndParam_LookupReadOnly
	cps hl, 1
	jr nz, LABEL_F3461D
	ld xwa, xiz
	ld xbc, 0x1E0003B
	lds32 xde, 1
	jr SqEdit_SendEventEpilog

LABEL_F3461D:
	ld xwa, xiz
	ld xbc, 0x1E0003B
	lds32 xde, 0
	jr SqEdit_SendEventEpilog

LABEL_F34628:
	ld xwa, (xde)
	cp xwa, 0x4006
	jr nz, SqplyFunc_FormatDispatch
	cpw (xde + 4), 0x1
	jr nz, LABEL_F34644
	ld xwa, xiz
	ld xbc, 0x1E0003B
	lds32 xde, 1
	jr SqEdit_SendEventEpilog

LABEL_F34644:
	ld xwa, xiz
	ld xbc, 0x1E0003B
	lds32 xde, 0

SqEdit_SendEventEpilog:
	call SendEvent

; SqplyFunc format dispatch
SqplyFunc_FormatDispatch:
	lds32 xhl, 0

; SqplyFunc format entry
SqplyFunc_FormatEntry:
	pop xiz
	ret

SqplyFunc:
	lda xsp, (xsp - 12)
	ld (xsp + 4), xde
	ld (xsp + 8), xwa
	ld xhl, xbc
	cp xbc, 0x1E80069
	jrl z, SqplyFunc_GetScreenId
	ld xwa, (xsp + 4)
	cp xbc, 0x1E80038
	jrl z, SqplyFunc_HandlePartQuery
	cp xbc, 0x1E80037
	jrl z, SqplyFunc_HandleTrackLookup
	cp xbc, 0x1E80035
	jrl z, SqplyFunc_StoreTrackPart
	cp xbc, 0x1E80036
	jrl z, SqplyFunc_GetValueDispatch
	cp xbc, 0x1E00045
	jrl z, SqplyFunc_HandleGetValue
	cp xbc, 0x1E80050
	jrl z, SqplyFunc_FormatFillIn
	cp xbc, 0x1E8004F
	jrl z, SqplyFunc_FormatEnding
	cp xbc, 0x1E8004E
	jrl z, SqplyFunc_FormatIntro
	ldda16 xde, 9832
	cp xbc, 0x1E8004D
	jrl z, SqplyFunc_FormatRhythmPattern
	sub xhl, 0x1E8003E
	cp xhl, 0x0
	jrl lt, SqplyFunc_ReturnZero
	cp xhl, 0x9
	jrl gt, SqplyFunc_ReturnZero
	add xhl, xhl
	add xhl, 0xE34B38
	ld hl, (xhl)
	lda_24 xix, 0xf346ed
	jp_dri 8, 0x07, 0xF0, 0xEC
SqplyFunc_ParamFormatData:
	.byte 0xaf, 0x04, 0x20, 0xb7, 0x60, 0xda, 0x88, 0xda
	.byte 0xcf, 0x02, 0x80, 0x6e, 0x07, 0x40, 0x9c, 0x4a
	.byte 0xe3, 0x00, 0x68, 0x0b, 0xd8, 0xcf, 0x01, 0x80
	.byte 0x6e, 0x16, 0x40, 0xa0, 0x4a, 0xe3, 0x00, 0x38
	.byte 0xaf, 0x04, 0x20, 0xa8, 0x12, 0x20, 0x38, 0x1d
	.byte 0x4d, 0x0f, 0xff, 0xef, 0x60, 0x78, 0x64, 0x01
	.byte 0x28, 0x40, 0xa4, 0x4a, 0xe3, 0x00, 0x78, 0x4c
	.byte 0x01, 0xaf, 0x04, 0x20, 0xb7, 0x60, 0xc1, 0x32
	.byte 0x23, 0x21, 0xd8, 0x12, 0x28, 0x40, 0xa8, 0x4a
	.byte 0xe3, 0x00, 0x78, 0x38, 0x01, 0xaf, 0x04, 0x20
	.byte 0xb7, 0x60, 0xc1, 0x68, 0x1d, 0x21, 0xd8, 0x12
	.byte 0x28, 0x40, 0xae, 0x4a, 0xe3, 0x00, 0x78, 0x24
	.byte 0x01, 0xaf, 0x04, 0x20, 0xb7, 0x60, 0x1d, 0x67
	.byte 0x58, 0xfa, 0xa7, 0x20, 0xb8, 0x12, 0x31, 0xcf
	.byte 0xcf, 0x82, 0x6e, 0x18, 0xf1, 0xb1, 0x28, 0xc8
	.byte 0x66, 0x07, 0x40, 0xb2, 0x4a, 0xe3, 0x00, 0x68
	.byte 0x05, 0x40, 0xb8, 0x4a, 0xe3, 0x00, 0x38, 0xa1
	.ascii " 8h6¡!ñ±"
	.byte 0x28, 0xc9, 0x66, 0x07, 0x40, 0xbe, 0x4a, 0xe3
	.byte 0x00, 0x68, 0x05, 0x40, 0xc4, 0x4a, 0xe3, 0x00
	.byte 0x38, 0x39, 0x68, 0x1e, 0xaf, 0x04, 0x20, 0xb7
	.byte 0x60, 0x40, 0xd0, 0x4a, 0xe3, 0x00, 0xc1, 0x3a
	.byte 0x28, 0x3f, 0x00, 0x66, 0x05, 0x40, 0xca, 0x4a
	.byte 0xe3, 0x00, 0x38, 0xaf, 0x04, 0x20, 0xa8, 0x12
	.byte 0x20, 0x38, 0x1d, 0x4d, 0x0f, 0xff, 0xef, 0x60
	.byte 0x78, 0xc9, 0x00, 0xaf, 0x04, 0x20, 0xb7, 0x60
	.byte 0x1d, 0x67, 0x58, 0xfa, 0xcf, 0xcf, 0x86, 0x6e
	.byte 0x0b, 0xd1, 0x20, 0x25, 0x04, 0x40, 0xd6, 0x4a
	.byte 0xe3, 0x00, 0x68, 0x09, 0xd1, 0x1c, 0x25, 0x04
	.byte 0x40, 0xdc, 0x4a, 0xe3, 0x00, 0x78, 0x95, 0x00
	.byte 0xaf, 0x04, 0x20, 0xb7, 0x60, 0x1d, 0x67, 0x58
	.byte 0xfa, 0xcf, 0xcf, 0x86, 0x6e, 0x0b, 0xd1, 0x22
	.byte 0x25, 0x04, 0x40, 0xe2, 0x4a, 0xe3, 0x00, 0x68
	.byte 0x09, 0xd1, 0x1e, 0x25, 0x04, 0x40, 0xe8, 0x4a
	.byte 0xe3, 0x00, 0x68, 0x71

SqplyFunc_FormatRhythmPattern:
	ld xwa, (xsp + 4)
	ld (xsp), xwa
	ld hl, de
	ld xwa, (xsp)
	lda xbc, (xwa + 18)
	cp de, 0x8002
	jr nz, SqplyFunc_CheckPattern8001
	ld xwa, 0xE34AEE
	jr SqplyFunc_CopyPatternString

SqplyFunc_CheckPattern8001:
	cp hl, 0x8001
	jr nz, SqplyFunc_FormatPatternNumeric
	ld xwa, 0xE34AF4

SqplyFunc_CopyPatternString:
	push xwa
	ld xwa, (xbc)
	push xwa
	call Strcpy
	inc 8, xsp
	jr SqplyFunc_RestoreAndReturn

SqplyFunc_FormatPatternNumeric:
	pushw hl
	pushw 0xE3
	pushw 0x4AFA
	jr SqplyFunc_PushAndFormat

SqplyFunc_FormatIntro:
	ld xwa, (xsp + 4)
	ld (xsp), xwa
	push_sd16w 0x38, 0xF2
	ld xwa, 0xE34B00
	jr SqplyFunc_PushFormatAddr

SqplyFunc_FormatEnding:
	ld xwa, (xsp + 4)
	ld (xsp), xwa
	push_sd16w 0x3A, 0xF2
	ld xwa, 0xE34B06
	push xwa
	ld xwa, (xsp + 6)
	lda xbc, (xwa + 18)

SqplyFunc_PushAndFormat:
	ld xwa, (xbc)
	push xwa
	jr SqplyFunc_CallAudioSendCmd

SqplyFunc_FormatFillIn:
	ld xwa, (xsp + 4)
	ld (xsp), xwa
	push_sd16w 0x3F, 0xF2
	ld xwa, 0xE34B0C

SqplyFunc_PushFormatAddr:
	push xwa
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 18)
	push xwa

SqplyFunc_CallAudioSendCmd:
	call Audio_SendCommand
	lda xsp, (xsp + 10)

SqplyFunc_RestoreAndReturn:
	ld xhl, (xsp + 8)
	jrl SqplyFunc_Epilogue

SqplyFunc_HandleGetValue:
	ld xwa, (xsp + 4)
	dec 1, xwa
	cp xwa, 0x0
	jr c, SqplyFunc_GetValueDefault
	cp xwa, 0xA
	jr ugt, SqplyFunc_GetValueDefault
	add xwa, xwa
	add xwa, 0xE34B22
	ld wa, (xwa)
	lda_24 xix, 0xf348b0
	jp_dri 8, 0x07, 0xF0, 0xE0

SqplyFunc_GetValueDispatch:
	lds32 xhl, 0
	ld8_24 l, 0x02109c
	jrl SqplyFunc_Epilogue
	ldada xhl, 9832
	jr SqplyFunc_GetValueReturn
	ldada xhl, 10417
	jr SqplyFunc_GetValueDone
	call GetTitleNow
	cp l, 0x82
	jr nz, SqplyFunc_GetValNonPlay
	ldada xhl, 9500
	jr SqplyFunc_GetValueReturn

SqplyFunc_GetValNonPlay:
	ldada xhl, 9504
	jr SqplyFunc_GetValueReturn
	call GetTitleNow
	cp l, 0x82
	jr nz, SqplyFunc_GetValNonPlay2
	ldada xhl, 9502
	jr SqplyFunc_GetValueReturn

SqplyFunc_GetValNonPlay2:
	ldada xhl, 9506
	jr SqplyFunc_GetValueReturn
	ldada xhl, 9964
	jr SqplyFunc_GetValueReturn
	ldada xhl, 62008
	jr SqplyFunc_GetValueReturn
	ldada xhl, 62010
	jr SqplyFunc_GetValueReturn
	ldada xhl, 62015
	jr SqplyFunc_GetValueReturn
	ldada xhl, 10298

SqplyFunc_GetValueDone:
	jrl SqplyFunc_Epilogue

SqplyFunc_GetValueDefault:
	ldada xhl, 9832

SqplyFunc_GetValueReturn:
	jrl SqplyFunc_Epilogue

SqplyFunc_StoreTrackPart:
	st8_24 0x02109c, a

SqplyFunc_ReturnZero:
	lds32 xhl, 0
	jrl SqplyFunc_Epilogue

SqplyFunc_HandleTrackLookup:
	call GetTitleNow
	ld xwa, (xsp + 4)
	cp l, 0x82
	jr z, SqplyFunc_TrackMode82_86
	cp l, 0x86
	jr nz, SqplyFunc_TrackMode88

SqplyFunc_TrackMode82_86:
	ld c, a
	cps a, 3
	jr z, SqplyFunc_TrackPart3
	cps c, 2
	jr z, SqplyFunc_TrackPart2
	cps c, 1
	jr nz, SqplyFunc_TrackTypeUnknown
	ldb l, 0x4
	jr SqplyFunc_TrackTypeReturn

SqplyFunc_TrackPart2:
	ldb l, 0x5
	jr SqplyFunc_TrackTypeReturn

SqplyFunc_TrackPart3:
	ldb l, 0x6
	jr SqplyFunc_TrackTypeReturn

SqplyFunc_TrackMode88:
	cp l, 0x88
	jr nz, SqplyFunc_TrackMode96_99
	ld c, a
	cps a, 3
	jr z, SqplyFunc_TrackMode88_Part3
	cps c, 2
	jr z, SqplyFunc_TrackMode88_Part2
	cps c, 1
	jr nz, SqplyFunc_TrackTypeUnknown
	ldb l, 0x8
	jr SqplyFunc_TrackTypeReturn

SqplyFunc_TrackMode88_Part2:
	ldb l, 0x9
	jr SqplyFunc_TrackTypeReturn

SqplyFunc_TrackMode88_Part3:
	ldb l, 0xA
	jr SqplyFunc_TrackTypeReturn

SqplyFunc_TrackMode96_99:
	cp l, 0x96
	jr z, SqplyFunc_TrackModePerc
	cp l, 0x99
	jr nz, SqplyFunc_TrackTypeUnknown

SqplyFunc_TrackModePerc:
	ld c, a
	cps a, 3
	jr z, SqplyFunc_TrackPart3
	cps c, 2
	jr z, SqplyFunc_TrackPart2
	cps c, 1
	jr nz, SqplyFunc_TrackTypeUnknown
	ldb l, 0xB
	jr SqplyFunc_TrackTypeReturn

SqplyFunc_TrackTypeUnknown:
	ldb l, 0xFF

SqplyFunc_TrackTypeReturn:
	exts hl
	exts xhl
	jr SqplyFunc_Epilogue

SqplyFunc_HandlePartQuery:
	extz wa
	dec 4, wa
	cps wa, 0
	jr lt, SqplyFunc_ReturnZero
	cps wa, 7
	jr gt, SqplyFunc_ReturnZero
	add wa, wa
	lda_24 xix, 0xe34b12
	ld_sriw3 WA, 0x07, 0xF0, 0xE0
	lda_24 xix, 0xf349b0
	jp_dri 8, 0x07, 0xF0, 0xE0

SqplyFunc_PartQueryDispatch:
	ldb	l, 1
	ld8_24	a, 135324
	cp	a, l
	scc16	z, hl
	extz	xhl
	jr	16
	ldb	l, 2
	jr	-17
	ldb	l, 3
	jr	-21

SqplyFunc_GetScreenId:
	call GetTitleNow
	ldb h, 0x0
	extz xhl

SqplyFunc_Epilogue:
	lda xsp, (xsp + 12)
	ret

SqedtFunc:
	lda xsp, (xsp - 12)
	push xiz
	ld (xsp + 8), xde
	ld xiz, xbc
	ld (xsp + 12), xwa
	call GetTitleNow
	ld xde, xiz
	cp xiz, 0x1E80069
	jrl z, SqedtFunc_StateChainA
	cp xiz, 0x1E00045
	jrl z, SqedtFunc_ModeD
	cp xiz, 0x1E80073
	jrl z, SqedtFunc_ModeB
	cp xiz, 0x1E80072
	jrl z, SqedtFunc_ModeA
	cp xiz, 0x1E8004B
	jrl z, SqedtFunc_CheckMode
	cp xiz, 0x1E8004A
	jrl z, SqedtFunc_Case2
	cp xiz, 0x1E80049
	jrl z, SqedtFunc_Case1
	cp xiz, 0x1E80048
	jrl z, SqedtFunc_Case0
	ld xwa, (xsp + 8)
	sub xde, 0x1E80016
	cp xde, 0x0
	jrl lt, SeqFunc_ReturnZeroJmp
	cp xde, 0x27
	jrl gt, SeqFunc_ReturnZeroJmp
	add xde, xde
	add xde, 0xE34D20
	ld de, (xde)
	lda_24 xix, 0xf34a5c
	jp_dri 8, 0x07, 0xF0, 0xE8
; SqedtFunc parameter dispatch
Sqedt_ParamDispatch:
	.byte 0xaf, 0x08, 0x20, 0xbf, 0x04, 0x60, 0x0b, 0x05
	.byte 0x00, 0xdb, 0x12, 0xdb, 0xca, 0x9c, 0x00, 0xdb
	.byte 0xd8, 0x61, 0x3e, 0xdb, 0xdf, 0x6a, 0x3a, 0xdb
	.byte 0x83, 0xf2, 0x10, 0x4d, 0xe3, 0x34, 0xd3, 0x07
	.byte 0xf0, 0xec, 0x23, 0xf2, 0x89, 0x4a, 0xf3, 0x34
	.byte 0xf3, 0x07, 0xf0, 0xec, 0xd8, 0xc1, 0x0e, 0x26
	.byte 0x21, 0x68, 0x22, 0xc1, 0x1c, 0x26, 0x21, 0x68
	.byte 0x1c, 0xc1, 0xd6, 0xf1, 0x21, 0x68, 0x16, 0xc1
	.byte 0xdb, 0xf1, 0x21, 0x68, 0x10, 0xc1, 0xf1, 0xf1
	.byte 0x21, 0x68, 0x0a, 0xc1, 0x28, 0xf2, 0x21, 0x68
	.byte 0x04, 0xc1, 0x04, 0x26, 0x21, 0x78, 0xc1, 0x03
	.byte 0xaf, 0x08, 0x20, 0xbf, 0x04, 0x60, 0xdb, 0x12
	.byte 0xdb, 0xca, 0x9c, 0x00, 0xdb, 0xd8, 0x61, 0x5c
	.byte 0xdb, 0xdf, 0x6a, 0x58, 0xdb, 0x83, 0xf2, 0x00
	.byte 0x4d, 0xe3, 0x34, 0xd3, 0x07, 0xf0, 0xec, 0x23
	.byte 0xf2, 0xde, 0x4a, 0xf3, 0x34, 0xf3, 0x07, 0xf0
	.byte 0xec, 0xd8, 0xd1, 0x10, 0x26, 0x04, 0x40, 0x4c
	.byte 0x4b, 0xe3, 0x00, 0x68, 0x40, 0xd1, 0x1e, 0x26
	.byte 0x04, 0x40, 0x52, 0x4b, 0xe3, 0x00, 0x68, 0x35
	.byte 0xd1, 0xd7, 0xf1, 0x04, 0x40, 0x58, 0x4b, 0xe3
	.byte 0x00, 0x68, 0x2a, 0xd1, 0xdc, 0xf1, 0x04, 0x40
	.long LABEL_E34B5E
	.byte 0x68, 0x1f, 0xd1, 0xf2
	.byte 0xf1, 0x04, 0x40, 0x64, 0x4b, 0xe3, 0x00, 0x68
	.byte 0x14, 0xd1, 0x29, 0xf2, 0x04, 0x40, 0x6a, 0x4b
	.byte 0xe3, 0x00, 0x68, 0x09, 0xd1, 0x06, 0x26, 0x04
	.byte 0x40, 0x70, 0x4b, 0xe3, 0x00, 0x78, 0x7f, 0x04
	.byte 0xaf, 0x08, 0x20, 0xbf, 0x04, 0x60, 0xdb, 0x12
	.byte 0xdb, 0xca, 0x9c, 0x00, 0xdb, 0xd8, 0x61, 0x5c
	.byte 0xdb, 0xdf, 0x6a, 0x58, 0xdb, 0x83, 0xf2, 0xf0
	.byte 0x4c, 0xe3, 0x34, 0xd3, 0x07, 0xf0, 0xec, 0x23
	.byte 0xf2, 0x56, 0x4b, 0xf3, 0x34, 0xf3, 0x07, 0xf0
	.byte 0xec, 0xd8, 0xd1, 0x12, 0x26, 0x04, 0x40, 0x76
	.byte 0x4b, 0xe3, 0x00, 0x68, 0x40, 0xd1, 0x20, 0x26
	.byte 0x04, 0x40, 0x7c, 0x4b, 0xe3, 0x00, 0x68, 0x35
	.byte 0xd1, 0x2c, 0x26, 0x04, 0x40, 0x82, 0x4b, 0xe3
	.byte 0x00, 0x68, 0x2a, 0xd1, 0x26, 0x26, 0x04, 0x40
	.long NakaInst_3d
	.byte 0x68, 0x1f, 0xd1, 0xfc
	.byte 0x25, 0x04, 0x40, 0x8e, 0x4b, 0xe3, 0x00, 0x68
	.byte 0x14, 0xd1, 0xfa, 0x25, 0x04, 0x40, 0x94, 0x4b
	.byte 0xe3, 0x00, 0x68, 0x09, 0xd1, 0x08, 0x26, 0x04
	.byte 0x40, 0x9a, 0x4b, 0xe3, 0x00, 0x78, 0x07, 0x04
	.byte 0xaf, 0x08, 0x20, 0xbf, 0x04, 0x60, 0xc1, 0x0c
	.byte 0x26, 0x25, 0xcd, 0xd8, 0x62, 0x11, 0xda, 0x13
	.long LABEL_E30B2A
	.byte 0x0b, 0xa0, 0x4b, 0xaf
	.byte 0x0a, 0x20, 0xb8, 0x12, 0x31, 0x68, 0x15, 0xaf
	.byte 0x04, 0x20, 0xb8, 0x12, 0x31, 0xcd, 0xd8, 0x69
	.byte 0x11, 0xcd, 0x07, 0xda, 0x13, 0x2a, 0x0b, 0xe3
	.byte 0x00, 0x0b, 0xa8, 0x4b, 0xa1, 0x20, 0x38, 0x78
	.byte 0xd5, 0x03, 0xda, 0x13, 0x2a, 0x0b, 0xe3, 0x00
	.byte 0x0b, 0xb0, 0x4b, 0x78, 0x8e, 0x03, 0xaf, 0x08
	.byte 0x20, 0xbf, 0x04, 0x60, 0xc1, 0x22, 0x26, 0x25
	.byte 0xcd, 0xd8, 0x62, 0x0a, 0xda, 0x13, 0x2a, 0x40
	.long LABEL_E34BB6
	.byte 0x68, 0x18, 0xcd, 0xd8
	.byte 0x69, 0x0c, 0xcd, 0x07, 0xda, 0x13, 0x2a, 0x40
	.long LABEL_E34BBE
	.byte 0x68, 0x08, 0xda, 0x13
	.byte 0x2a, 0x40, 0xc6, 0x4b, 0xe3, 0x00, 0x78, 0x8e
	.byte 0x03, 0xaf, 0x08, 0x20, 0xbf, 0x04, 0x60, 0xc1
	.byte 0x2e, 0xf2, 0x25, 0xcd, 0xd8, 0x62, 0x0a, 0xda
	.byte 0x13, 0x2a, 0x40, 0xcc, 0x4b, 0xe3, 0x00, 0x68
	.byte 0x18, 0xcd, 0xd8, 0x69, 0x0c, 0xcd, 0x07, 0xda
	.byte 0x13, 0x2a, 0x40, 0xd4, 0x4b, 0xe3, 0x00, 0x68
	.byte 0x08, 0xda, 0x13, 0x2a, 0x40, 0xdc, 0x4b, 0xe3
	.byte 0x00, 0x38, 0xaf, 0x0a, 0x20, 0xb8, 0x12, 0x31
	.byte 0x78, 0x21, 0x03, 0xaf, 0x08, 0x20, 0xbf, 0x04
	.byte 0x60, 0x0b, 0x09, 0x00, 0xc1, 0xe0, 0xf1, 0x21
	.byte 0xd8, 0x12, 0xd8, 0x09, 0x09, 0x00, 0x41, 0x16
	.byte 0x4a, 0xe3, 0x00, 0xe8, 0x13, 0xe9, 0x80, 0x38
	.byte 0x78, 0x62, 0x03, 0xaf, 0x08, 0x20, 0xbf, 0x04
	.byte 0x60, 0x0b, 0x0f, 0x00, 0xc1, 0xf6, 0xf1, 0x21
	.byte 0xd8, 0x12, 0xd8, 0x09, 0x0f, 0x00, 0x41, 0x32
	.byte 0x4a, 0xe3, 0x00, 0xe8, 0x13, 0xe9, 0x80, 0x38
	.byte 0x78, 0x42, 0x03, 0xaf, 0x08, 0x20, 0xbf, 0x04
	.byte 0x60, 0xc1, 0x00, 0x26, 0x21, 0xd8, 0x12, 0x28
	.byte 0x40, 0xe2, 0x4b, 0xe3, 0x00, 0x78, 0xff, 0x02
	.byte 0xaf, 0x08, 0x20, 0xbf, 0x04, 0x60, 0xc1, 0x02
	.byte 0x26, 0x25, 0xcd, 0x89, 0xd8, 0x13, 0xcd, 0xd8
	.byte 0x62, 0x08, 0x28, 0x40, 0xe8, 0x4b, 0xe3, 0x00
	.byte 0x68, 0x16, 0xcd, 0xd8, 0x69, 0x0c, 0xcd, 0x07
	.byte 0xda, 0x13, 0x2a, 0x40, 0xf0, 0x4b, 0xe3, 0x00
	.byte 0x68, 0x06, 0x28, 0x40, 0xf8, 0x4b, 0xe3, 0x00
	.byte 0x38, 0xaf, 0x0a, 0x20, 0xb8, 0x12, 0x31, 0x78
	.byte 0x92, 0x02, 0xaf, 0x08, 0x20, 0xbf, 0x04, 0x60
	.byte 0xb8, 0x12, 0x31, 0xa1, 0x20, 0xb0, 0x00, 0x20
	.byte 0x0b, 0x09, 0x00, 0xc1, 0x16, 0x26, 0x21, 0xd8
	.byte 0x12, 0xd8, 0x09, 0x09, 0x00, 0xf2, 0x46, 0x09
	.byte 0xe3, 0x32, 0xe8, 0x13, 0xea, 0x80, 0x38, 0xa1
	.byte 0x20, 0xe8, 0x61, 0x38, 0x1d, 0xf3, 0x0c, 0xff
	.byte 0xbf, 0x0a, 0x37, 0xc1, 0x16, 0x26, 0x21, 0xd8
	.byte 0x12, 0x28, 0x40, 0xfe, 0x4b, 0xe3, 0x00, 0x68
	.byte 0x3d, 0xaf, 0x08, 0x20, 0xbf, 0x04, 0x60, 0xb8
	.byte 0x12, 0x31, 0xa1, 0x20, 0xb0, 0x00, 0x20, 0x0b
	.byte 0x09, 0x00, 0xc1, 0x58, 0x26, 0x21, 0xd8, 0x12
	.byte 0xd8, 0x09, 0x09, 0x00, 0xf2, 0x46, 0x09, 0xe3
	.byte 0x32, 0xe8, 0x13, 0xea, 0x80, 0x38, 0xa1, 0x20
	.byte 0xe8, 0x61, 0x38, 0x1d, 0xf3, 0x0c, 0xff, 0xbf
	.byte 0x0a, 0x37, 0xc1, 0x58, 0x26, 0x21, 0xd8, 0x12
	.byte 0x28, 0x40, 0x06, 0x4c, 0xe3, 0x00, 0x38, 0xaf
	.byte 0x0a, 0x20, 0xa8, 0x12, 0x20, 0xb8, 0x0a, 0x30
	.byte 0x38, 0x78, 0x43, 0x02, 0xaf, 0x08, 0x20, 0xbf
	.byte 0x04, 0x60, 0xc1, 0xd3, 0xf1, 0x21, 0xd8, 0x12
	.byte 0x28, 0x40, 0x0e, 0x4c, 0xe3, 0x00, 0x78, 0x26
	.byte 0x02, 0xaf, 0x08, 0x20, 0xbf, 0x04, 0x60, 0xc1
	.byte 0xd4, 0xf1, 0x21, 0xd8, 0x12, 0x28, 0x40, 0x14
	.byte 0x4c, 0xe3, 0x00, 0x38, 0xaf, 0x0a, 0x20, 0xb8
	.byte 0x12, 0x31, 0x78, 0xd7, 0x01, 0xaf, 0x08, 0x20
	.byte 0xbf, 0x04, 0x60, 0xc1, 0xd5, 0xf1, 0x21, 0xd8
	.byte 0x12, 0x28, 0x40, 0x1a, 0x4c, 0xe3, 0x00, 0x78
	.byte 0xf5, 0x01, 0xaf, 0x08, 0x20, 0xbf, 0x04, 0x60
	.byte 0x0b, 0x05, 0x00, 0xc1, 0xe9, 0xf1, 0x21, 0x78
	.byte 0xaf, 0x00, 0xaf, 0x08, 0x20, 0xbf, 0x04, 0x60
	.byte 0xd1, 0xea, 0xf1, 0x04, 0x40, 0x20, 0x4c, 0xe3
	.byte 0x00, 0x38, 0xaf, 0x0a, 0x20, 0xb8, 0x12, 0x31
	.byte 0x78, 0x99, 0x01, 0xaf, 0x08, 0x20, 0xbf, 0x04
	.byte 0x60, 0xd1, 0x28, 0x26, 0x04, 0x40, 0x26, 0x4c
	.byte 0xe3, 0x00, 0x78, 0xba, 0x01, 0xaf, 0x08, 0x20
	.byte 0xbf, 0x04, 0x60, 0x0b, 0x05, 0x00, 0xc1, 0xee
	.byte 0xf1, 0x21, 0x68, 0x75, 0xaf, 0x08, 0x20, 0xbf
	.byte 0x04, 0x60, 0xd1, 0xef, 0xf1, 0x04, 0x40, 0x2c
	.byte 0x4c, 0xe3, 0x00, 0x38, 0xaf, 0x0a, 0x20, 0xb8
	.byte 0x12, 0x31, 0x78, 0x5f, 0x01, 0xaf, 0x08, 0x20
	.byte 0xbf, 0x04, 0x60, 0xc1, 0x2a, 0x26, 0x21, 0xd8
	.byte 0x12
	.byte 0x28, 0x40, 0x32, 0x4c
	.byte 0xe3, 0x00, 0x78
	.byte 0x7d, 0x01, 0xaf, 0x08, 0x20, 0xbf, 0x04, 0x60
	.byte 0x0b, 0x05, 0x00, 0xc1, 0xe1, 0xf1, 0x21, 0x68
	.byte 0x38, 0xaf, 0x08, 0x20, 0xbf, 0x04, 0x60, 0xd1
	.byte 0xe2, 0xf1, 0x04, 0x40, 0x38, 0x4c, 0xe3, 0x00
	.byte 0x38, 0xaf, 0x0a, 0x20, 0xb8, 0x12, 0x31, 0x78
	.byte 0x22, 0x01, 0xaf, 0x08, 0x20, 0xbf, 0x04, 0x60
	.byte 0xd1, 0x2e, 0x26, 0x04, 0x40, 0x3e, 0x4c, 0xe3
	.byte 0x00, 0x78, 0x43, 0x01, 0xaf, 0x08, 0x20, 0xbf
	.byte 0x04, 0x60, 0x0b, 0x05, 0x00, 0xc1, 0xe6, 0xf1
	.byte 0x21, 0xd8, 0x12, 0xd8, 0x09, 0x05, 0x00, 0x41
	.long LABEL_E34944
	.byte 0xe8, 0x13, 0xe9, 0x80
	.byte 0x38, 0x78, 0x51, 0x01, 0xaf, 0x08, 0x20, 0xbf
	.byte 0x04, 0x60, 0xd1, 0xe7, 0xf1, 0x04, 0x40, 0x44
	.byte 0x4c, 0xe3, 0x00, 0x38, 0xaf, 0x0a, 0x20, 0xb8
	.byte 0x12, 0x31, 0x78, 0xd7, 0x00, 0xaf, 0x08, 0x20
	.byte 0xbf, 0x04, 0x60, 0xc1, 0x30, 0x26, 0x21, 0xd8
	.byte 0x12
	.byte 0x28, 0x40, 0x4a, 0x4c
	.byte 0xe3, 0x00, 0x78
	.byte 0xf5, 0x00, 0xaf, 0x08, 0x20, 0xbf, 0x04, 0x60
	.byte 0xc1, 0x08, 0x27, 0x21, 0xd8, 0x12, 0x28, 0x40
	.long NakaInst_2d
	.byte 0x38, 0xaf, 0x0a, 0x20
	.byte 0xb8, 0x12, 0x31, 0x78, 0xa6, 0x00, 0xaf, 0x08
	.byte 0x20, 0xbf, 0x04, 0x60, 0x0b, 0x03, 0x00, 0xc1
	.byte 0x0c
	.ascii "'!h\""
	ld	xwa, (xsp+8)
	.byte 0xbf, 0x04, 0x60, 0xc1, 0x0a, 0x27, 0x21, 0xd8
	.byte 0x12
	.byte 0x28, 0x40, 0x56, 0x4c
	.byte 0xe3, 0x00, 0x78
	.byte 0xb5, 0x00, 0xaf, 0x08, 0x20, 0xbf, 0x04, 0x60
	.byte 0x0b, 0x03, 0x00, 0xc1, 0x0e, 0x27, 0x21, 0xd8
	.byte 0x12, 0xd8, 0x09, 0x03, 0x00, 0x41, 0x9e, 0x49
	.byte 0xe3, 0x00, 0xe8, 0x13, 0xe9, 0x80, 0x38, 0x78
	.byte 0xc3, 0x00

; SqedtFunc dispatch case 0
SqedtFunc_Case0:
	ld xwa, (xsp + 8)
	ld (xsp + 4), xwa
	pushw 0x6
	ldda8 a, 10360
	extz wa
	muls wa, 0x6
	ld xbc, 0xE349D4
	exts xwa
	add xwa, xbc
	push xwa
	jrl SqedtFunc_ModeC_Entry

; SqedtFunc dispatch case 1
SqedtFunc_Case1:
	ld xwa, (xsp + 8)
	ld (xsp + 4), xwa
	pushw 0x10
	ldada xwa, 9706
	jrl SqedtFunc_ModeC

; SqedtFunc dispatch case 2
SqedtFunc_Case2:
	ld xwa, (xsp + 8)
	ld (xsp + 4), xwa
	cpdi8 10360, 10
	jr nz, LABEL_F34F68
	pushw 0xE3
	pushw 0x4C5C
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 18)
	push xwa
	call Strcpy
	inc 8, xsp
	jr StringCopyEpilog

LABEL_F34F68:
	push_sd16w 0x28, 0x27
	ld xwa, 0xE34C62
	push xwa
	ld xwa, (xsp + 10)
	lda xbc, (xwa + 18)
	ld xwa, (xbc)
	push xwa
	jr LABEL_F34FB3

; SqedtFunc check mode
SqedtFunc_CheckMode:
	ld xwa, (xsp + 8)
	ld (xsp + 4), xwa
	cpdi8 10360, 10
	jr nz, LABEL_F34F9F
	pushw 0xE3
	pushw 0x4C68
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 18)
	push xwa
	call Strcpy
	inc 8, xsp
	jr StringCopyEpilog

LABEL_F34F9F:
	ldda8 a, 10348
	extz wa
	pushw wa
	ld xwa, 0xE34C6C
	push xwa
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 18)
	push xwa

LABEL_F34FB3:
	call Audio_SendCommand
	lda xsp, (xsp + 10)
	jr StringCopyEpilog

; SqedtFunc mode A
SqedtFunc_ModeA:
	ld xwa, (xsp + 8)
	ld (xsp + 4), xwa
	pushw 0x10
	ldada xwa, 10306
	jr SqedtFunc_ModeC

; SqedtFunc mode B
SqedtFunc_ModeB:
	ld xwa, (xsp + 8)
	ld (xsp + 4), xwa
	pushw 0x10
	ldada xwa, 10322

; SqedtFunc mode C
SqedtFunc_ModeC:
	push xwa

; SqedtFunc mode C entry
SqedtFunc_ModeC_Entry:
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 18)
	push xwa
	call Strncpy
	lda xsp, (xsp + 10)

StringCopyEpilog:
	ld xhl, (xsp + 12)
	jrl SqedtFunc_Epilogue12

; SqedtFunc mode D
SqedtFunc_ModeD:
	ld xwa, (xsp + 8)
	calr SqedtFunc_StateChainB
	jrl SqedtFunc_Epilogue12
	lds32 xhl, 0
	ld8_24 l, 0x02109c
	jrl SqedtFunc_Epilogue12
	st8_24 0x02109c, a

SeqFunc_ReturnZeroJmp:
	lds32 xhl, 0
	jrl SqedtFunc_Epilogue12
	extz wa
	cps wa, 0
	jrl mi, SqedtFunc_ReturnNegOne
	cps wa, 6
	jrl gt, SqedtFunc_ReturnNegOne
	add wa, wa
	lda_24 xix, 0xe34ce2
	ld_sriw3 WA, 0x07, 0xF0, 0xE0
	lda_24 xix, 0xf3502c
	jp_dri 8, 0x07, 0xF0, 0xE0

; SqedtFunc value dispatch
Sqedt_ValueDispatch:
	.byte 0xdb, 0x12, 0xdb, 0xca, 0x9b, 0x00, 0xdb, 0xd8
	.byte 0x71, 0xbe, 0x00, 0xdb, 0xcf, 0x08, 0x00, 0x7a
	.byte 0xb7, 0x00, 0xdb, 0x83, 0xf2, 0xd0, 0x4c, 0xe3
	.byte 0x34, 0xd3, 0x07, 0xf0, 0xec, 0x23, 0xf2, 0x54
	.byte 0x50, 0xf3, 0x34, 0xf3, 0x07, 0xf0, 0xec, 0xd8
	.byte 0x27, 0x00, 0x78, 0x9e, 0x00, 0x27, 0x0c, 0x78
	.byte 0x99, 0x00, 0xdb, 0x12, 0xdb, 0xca, 0x9c, 0x00
	.byte 0xdb, 0xd8, 0x71, 0x8c, 0x00, 0xdb, 0xdf, 0x7a
	.byte 0x87, 0x00, 0xdb, 0x83, 0xf2, 0xc0, 0x4c, 0xe3
	.byte 0x34, 0xd3, 0x07, 0xf0, 0xec, 0x23, 0xf2, 0x84
	.byte 0x50, 0xf3, 0x34, 0xf3, 0x07, 0xf0, 0xec, 0xd8
	.byte 0x27, 0x01, 0x68, 0x6f, 0xdb, 0x12, 0xdb, 0xca
	.byte 0x9b, 0x00, 0xdb, 0xd8, 0x61, 0x63, 0xdb, 0xcf
	.byte 0x08, 0x00, 0x6a, 0x5d, 0xdb, 0x83, 0xf2, 0xae
	.byte 0x4c, 0xe3, 0x34, 0xd3, 0x07, 0xf0, 0xec, 0x23
	.byte 0xf2, 0xae, 0x50, 0xf3, 0x34, 0xf3, 0x07, 0xf0
	.byte 0xec, 0xd8, 0x27, 0x02, 0x68, 0x45, 0x27, 0x0d
	.byte 0x68, 0x41, 0xcf, 0xcf, 0x9c, 0x66, 0x24, 0xcf
	.byte 0xcf, 0xa1, 0x66, 0x1b, 0xcf, 0xcf, 0x9e, 0x66
	.byte 0x12, 0xcf, 0xcf, 0x9d, 0x66, 0x09, 0xcf, 0xcf
	.byte 0xa0, 0x6e, 0x26, 0x27, 0x03, 0x68, 0x24, 0x27
	.byte 0x04, 0x68, 0x20, 0x27, 0x05, 0x68, 0x1c, 0x27
	.byte 0x06, 0x68, 0x18, 0x27, 0x07, 0x68, 0x14, 0xcf
	.byte 0xcf, 0x9f, 0x66, 0x09, 0xcf, 0xcf, 0x9c, 0x6e
	.byte 0x08, 0x27, 0x08, 0x68, 0x06, 0x27, 0x0a, 0x68
	.byte 0x02

SqedtFunc_ReturnNegOne:
	ldb l, 0xFF

SqedtFunc_SignExtendAndReturn:
	exts hl
	exts xhl
	jrl SqedtFunc_Epilogue12
	cp l, 0x9B
	jr z, SqedtFunc_SignExtend
	cp l, 0x9F
	jr z, SqedtFunc_ReturnNeg1
	cp l, 0x9C
	jr nz, SqedtFunc_ReturnNegOne
	ldb l, 0x9
	jr SqedtFunc_SignExtendAndReturn

; SqedtFunc return -1
SqedtFunc_ReturnNeg1:
	ldb l, 0xB
	jr SqedtFunc_SignExtendAndReturn

; SqedtFunc sign extend and return
SqedtFunc_SignExtend:
	ldb l, 0xE
	jr SqedtFunc_SignExtendAndReturn
	extz wa
	cps wa, 0
	jrl mi, SeqFunc_ReturnZeroJmp
	cp wa, 0xE
	jrl gt, SeqFunc_ReturnZeroJmp
	add wa, wa
	lda_24 xix, 0xe34c90
	ld_sriw3 WA, 0x07, 0xF0, 0xE0
	lda_24 xix, 0xf3513d
	jp_dri 8, 0x07, 0xF0, 0xE0

; Sequencer format dispatch A
SeqFormat_DispatchA:
	.byte 0x27, 0x00, 0xc2, 0x9c, 0x10, 0x02, 0x21, 0xcf
	.byte 0xf1, 0xdb, 0x76, 0xeb, 0x12, 0x78, 0xec, 0x00
	.byte 0x27, 0x01, 0x68, 0xee, 0x27, 0x02, 0x68, 0xea
	.byte 0x27, 0x03, 0x68, 0xe6, 0x27, 0x05, 0x68, 0xe2
	.byte 0x27, 0x06, 0x68, 0xde, 0xeb, 0xa8, 0xc2, 0xdc
	.byte 0xe2, 0x03, 0x27, 0x78, 0xce, 0x00, 0xf2, 0xdc
	.byte 0xe2, 0x03, 0x41, 0x78, 0x92, 0xfe, 0xeb, 0xa8
	.byte 0xc2, 0xde, 0xe2, 0x03, 0x27, 0x78, 0xbc, 0x00
	.byte 0xf2, 0xde, 0xe2, 0x03, 0x41, 0x78, 0x80, 0xfe
	.byte 0xd8, 0x12, 0xd8, 0xca, 0x0f, 0x00, 0xd8, 0xd8
	.byte 0x71, 0x75, 0xfe, 0xd8, 0xcf, 0x0f, 0x00, 0x7a
	.byte 0x6e, 0xfe, 0xd8, 0x80, 0xf2, 0x70, 0x4c, 0xe3
	.byte 0x34, 0xd3, 0x07, 0xf0, 0xe0, 0x20, 0xf2, 0xad
	.byte 0x51, 0xf3, 0x34, 0xf3, 0x07, 0xf0, 0xe0, 0xd8
	.byte 0xc2, 0xe0, 0xe2, 0x03, 0x3f, 0x00, 0x7e, 0x4f
	.byte 0xfe, 0x40, 0x0f, 0x00, 0x00, 0x00, 0x68, 0x3e
	.byte 0xc2, 0xe0, 0xe2, 0x03, 0x3f, 0x01, 0x7e, 0x3f
	.byte 0xfe, 0x40, 0x12, 0x00, 0x00, 0x00, 0x68, 0x50
	.byte 0xc2, 0xe0, 0xe2, 0x03, 0x3f, 0x00, 0x7e, 0x2f
	.byte 0xfe, 0x40, 0x15, 0x00, 0x00, 0x00, 0x68, 0x1e
	.byte 0xc2, 0xe0, 0xe2, 0x03, 0x3f, 0x01, 0x7e, 0x1f
	.byte 0xfe, 0x40, 0x18, 0x00, 0x00, 0x00, 0x68, 0x30
	.byte 0xc2, 0xe0, 0xe2, 0x03, 0x3f, 0x00, 0x7e, 0x0f
	.byte 0xfe, 0x40, 0x1b, 0x00, 0x00, 0x00, 0xaf, 0x08
	.byte 0x21, 0xe8, 0xa1, 0xe8, 0xa8, 0xc2, 0xdc, 0xe2
	.byte 0x03, 0x21, 0xe9, 0xf0, 0xdb, 0x76, 0xeb, 0x12
	.byte 0x68, 0x2a, 0xc2, 0xe0, 0xe2, 0x03, 0x3f, 0x01
	.byte 0x7e, 0xed, 0xfd, 0x40, 0x1d, 0x00, 0x00, 0x00
	.byte 0xaf, 0x08, 0x21, 0xe8, 0xa1, 0xe8, 0xa8, 0xc2
	.byte 0xde, 0xe2, 0x03, 0x21, 0xe9, 0xf0, 0xdb, 0x76
	.byte 0xeb, 0x12, 0x68, 0x08

; SqedtFunc state chain A
SqedtFunc_StateChainA:
	call GetTitleNow
	ldb h, 0x0
	extz xhl

SqedtFunc_Epilogue12:
	pop xiz
	lda xsp, (xsp + 12)
	ret

; SqedtFunc state chain B
SqedtFunc_StateChainB:
	push xiz
	ld xiz, xwa
	call GetTitleNow
	ld a, l
	cp l, 0x91
	jrl z, DspItem0_CngFunc
	cp l, 0x90
	jr z, SeqFormat_DispatchB
	extz wa
	sub wa, 0x9B
	cps wa, 0
	jrl lt, SqedtFunc_GetFieldAddr_BySelector
	cp wa, 0xD
	jrl gt, SqedtFunc_GetFieldAddr_BySelector
	add wa, wa
	lda_24 xix, 0xe34d70
	ld_sriw3 WA, 0x07, 0xF0, 0xE0
	lda_24 xix, 0xf3527a
	jp_dri 8, 0x07, 0xF0, 0xE0

; Sequencer format dispatch B
SeqFormat_DispatchB:
	cp xiz, 0x22
	jr z, LABEL_F352A0
	cp xiz, 0x21
	jr z, LABEL_F35299
	cp xiz, 0x20
	jr nz, LABEL_F352A7
	ldada xhl, 9706
	jrl SqedtFunc_Epilogue

LABEL_F35299:
	ldada xhl, 10024
	jrl SqedtFunc_EpilogueJump

LABEL_F352A0:
	ldada xhl, 10348
	jrl SqedtFunc_Epilogue

LABEL_F352A7:
	ldada xhl, 10360
	jrl SqedtFunc_Epilogue
	cp xiz, 0xB
	jr z, LABEL_F352E3
	cp xiz, 0xA
	jr z, LABEL_F352DC
	cp xiz, 0x2
	jr z, LABEL_F352D5
	cp xiz, 0x1
	jr nz, LABEL_F352EA
	ldada xhl, 9744
	jrl SqedtFunc_EpilogueJump

LABEL_F352D5:
	ldada xhl, 9746
	jrl SqedtFunc_EpilogueJump

LABEL_F352DC:
	ldada xhl, 9750
	jrl SqedtFunc_Epilogue

LABEL_F352E3:
	ldada xhl, 9816
	jrl SqedtFunc_Epilogue

LABEL_F352EA:
	ldada xhl, 9742
	jrl SqedtFunc_Epilogue
	cp xiz, 0x4
	jr z, LABEL_F35317
	cp xiz, 0x2
	jr z, LABEL_F35310
	cp xiz, 0x1
	jr nz, LABEL_F3531E
	ldada xhl, 9758
	jrl SqedtFunc_EpilogueJump

LABEL_F35310:
	ldada xhl, 9760
	jrl SqedtFunc_EpilogueJump

LABEL_F35317:
	ldada xhl, 9762
	jrl SqedtFunc_ReturnPath

LABEL_F3531E:
	ldada xhl, 9756
	jrl SqedtFunc_Epilogue
	cp xiz, 0x2
	jr z, LABEL_F3533C
	cp xiz, 0x1
	jr nz, LABEL_F35343
	ldada xhl, 61911
	jrl SqedtFunc_EpilogueJump

LABEL_F3533C:
	ldada xhl, 9772
	jrl SqedtFunc_EpilogueJump

LABEL_F35343:
	ldada xhl, 61910
	jrl SqedtFunc_Epilogue
	cp xiz, 0x6
	jr z, LABEL_F35370
	cp xiz, 0x2
	jr z, LABEL_F35369
	cp xiz, 0x1
	jr nz, LABEL_F35377
	ldada xhl, 61916
	jrl SqedtFunc_EpilogueJump

LABEL_F35369:
	ldada xhl, 9766
	jrl SqedtFunc_EpilogueJump

LABEL_F35370:
	ldada xhl, 61920
	jrl SqedtFunc_Epilogue

LABEL_F35377:
	ldada xhl, 61915
	jrl SqedtFunc_Epilogue
	cp xiz, 0x9
	jr z, LABEL_F353C2
	cp xiz, 0x8
	jr z, LABEL_F353BB
	cp xiz, 0x7
	jr z, LABEL_F353B4
	cp xiz, 0x2
	jr z, LABEL_F353AD
	cp xiz, 0x1
	jr nz, LABEL_F353C9
	ldada xhl, 61938
	jrl SqedtFunc_EpilogueJump

LABEL_F353AD:
	ldada xhl, 9724
	jrl SqedtFunc_EpilogueJump

LABEL_F353B4:
	ldada xhl, 61942
	jrl SqedtFunc_Epilogue

LABEL_F353BB:
	ldada xhl, 9728
	jrl SqedtFunc_Epilogue

LABEL_F353C2:
	ldada xhl, 9730
	jrl SqedtFunc_ReturnPath

LABEL_F353C9:
	ldada xhl, 61937
	jrl SqedtFunc_Epilogue
	cp xiz, 0x5
	jr z, LABEL_F353F6
	cp xiz, 0x2
	jr z, LABEL_F353EF
	cp xiz, 0x1
	jr nz, LABEL_F353FD
	ldada xhl, 61993
	jrl SqedtFunc_EpilogueJump

LABEL_F353EF:
	ldada xhl, 9722
	jrl SqedtFunc_EpilogueJump

LABEL_F353F6:
	ldada xhl, 61998
	jrl SqedtFunc_ReturnPath

LABEL_F353FD:
	ldada xhl, 61992
	jrl SqedtFunc_Epilogue
	cp xiz, 0xE
	jr z, LABEL_F3541B
	cp xiz, 0xD
	jr nz, LABEL_F35422
	ldada xhl, 61908
	jrl SqedtFunc_Epilogue

LABEL_F3541B:
	ldada xhl, 61909
	jrl SqedtFunc_Epilogue

LABEL_F35422:
	ldada xhl, 61907
	jrl SqedtFunc_Epilogue
	cp xiz, 0x14
	jr z, LABEL_F3546D
	cp xiz, 0x13
	jr z, LABEL_F35466
	cp xiz, 0x12
	jr z, LABEL_F3545F
	cp xiz, 0x11
	jr z, LABEL_F35458
	cp xiz, 0x10
	jr nz, LABEL_F35474
	ldada xhl, 61930
	jrl SqedtFunc_EpilogueJump

LABEL_F35458:
	ldada xhl, 9768
	jrl SqedtFunc_EpilogueJump

LABEL_F3545F:
	ldada xhl, 61934
	jrl SqedtFunc_Epilogue

LABEL_F35466:
	ldada xhl, 61935
	jrl SqedtFunc_EpilogueJump

LABEL_F3546D:
	ldada xhl, 9770
	jrl SqedtFunc_Epilogue

LABEL_F35474:
	ldada xhl, 61929
	jrl SqedtFunc_Epilogue
	cp xiz, 0x1A
	jr z, LABEL_F354BB
	cp xiz, 0x19
	jr z, LABEL_F354B5
	cp xiz, 0x18
	jr z, LABEL_F354AF
	cp xiz, 0x17
	jr z, LABEL_F354A9
	cp xiz, 0x16
	jr nz, LABEL_F354C1
	ldada xhl, 61922
	jr SqedtFunc_EpilogueJump

LABEL_F354A9:
	ldada xhl, 9774
	jr SqedtFunc_EpilogueJump

LABEL_F354AF:
	ldada xhl, 61926
	jr SqedtFunc_Epilogue

LABEL_F354B5:
	ldada xhl, 61927
	jr SqedtFunc_EpilogueJump

LABEL_F354BB:
	ldada xhl, 9776
	jr SqedtFunc_Epilogue

LABEL_F354C1:
	ldada xhl, 61921
	jr SqedtFunc_Epilogue

; DspItem0CngFunc dispatch
DspItem0_CngFunc:
	cp xiz, 0x1E
	jr z, LABEL_F354EB
	cp xiz, 0x1D
	jr z, LABEL_F354E5
	cp xiz, 0x1C
	jr nz, LABEL_F354F1
	ldada xhl, 9996
	jr SqedtFunc_Epilogue

LABEL_F354E5:
	ldada xhl, 9994
	jr SqedtFunc_Epilogue

LABEL_F354EB:
	ldada xhl, 9998
	jr SqedtFunc_Epilogue

LABEL_F354F1:
	ldada xhl, 9992
	jr SqedtFunc_Epilogue

SqedtFunc_GetFieldAddr_BySelector:
	cp xiz, 0x3
	jr z, LABEL_F3551B
	cp xiz, 0x2
	jr z, LABEL_F35515
	cp xiz, 0x1
	jr nz, LABEL_F35521
	ldada xhl, 9734
	jr SqedtFunc_EpilogueJump

LABEL_F35515:
	ldada xhl, 9736

SqedtFunc_EpilogueJump:
	jr SqedtFunc_Epilogue

LABEL_F3551B:
	ldada xhl, 9740

SqedtFunc_ReturnPath:
	jr SqedtFunc_Epilogue

LABEL_F35521:
	ldada xhl, 9732

SqedtFunc_Epilogue:
	pop xiz
	ret

; =============================================================================
; DspItem0CngFunc -- DSP Effect Item Change Function (UI handler)
; =============================================================================
; Handles DSP effect editor events. Displays effect names (0xE32A7A ptr table),
; parameter names (0xE324C4 via per-algo config at 0xE446DC), and values.
; Sends parameter changes to Sub CPU via Audio_SendCommand.
; Stack frame: 28 bytes.
DspItem0CngFunc:
	lda xsp, (xsp - 28)
	ld (xsp + 20), xbc
	ld (xsp + 24), xwa
	ld xix, (xsp + 20)
	ld (xsp), xix
	cp xix, 0x1E80069
	jrl z, DspItem0_DispatchTarget
	cp xix, 0x1E00046
	jrl z, LABEL_F357C8
	ld8_24 l, 0x021098
	ldada xwa, 10616
	ld (xsp + 4), xwa
	ld c, l
	inc 1, c
	ld b, l
	inc 2, b
	ld h, l
	inc 3, h
	ld a, l
	inc 4, a
	ldfr_berp A, 0xE2
	ld a, l
	inc 5, a
	ldfr_berp A, 0xE6
	ld a, l
	inc 6, a
	ldfr_berp A, 0xEE
	ld a, l
	inc 7, a
	extz wa
	ld (xsp + 18), wa
	ldto_berp A, 0xEE
	extz wa
	ld (xsp + 16), wa
	ldto_berp A, 0xE6
	extz wa
	ld (xsp + 14), wa
	ldto_berp A, 0xE2
	extz wa
	ld (xsp + 12), wa
	ld a, h
	extz wa
	ld (xsp + 10), wa
	ld a, b
	extz wa
	ld (xsp + 8), wa
	ld a, c
	extz wa
	ld c, l
	extz bc
	cp xix, 0x1E00045
	jrl z, DspItem0_TypeChangeHandler
	cp xix, 0x1E8004C
	jrl z, DspItem0_SendEffectParam
	cp xix, 0x1E00047
	jr z, DspItem0_DisplayEffectName
	ld xiy, (xsp)
	sub xiy, 0x1E80000
	cp xiy, 0x0
	jrl lt, EffectEdit_ReturnZero
	cp xiy, 0x10
	jrl gt, EffectEdit_ReturnZero
	add xiy, xiy
	add xiy, 0xE34DA4
	ld iy, (xiy)
	lda_24 xix, 0xf355f3
	jp_dri 8, 0x07, 0xF0, 0xF4

DspItem0_DisplayEffectName:
	ld (xsp), xde
	ldda16 xwa, 10614
	extz xwa
	sll xwa, 2
	ld xbc, 0xE32A7A
	add xbc, xwa
	ld xwa, (xbc)
	push xwa
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 18)
	push xwa
	call Strcpy
	inc 8, xsp
	jrl DspItem0_ExitWithHL
	ld (xsp), xde
	ldw (xsp + 18), 0x0

DspItem0_DisplayParamNames:
	pushw 0x11
	ld8_24 a, 0x021098
	extz wa
	add wa, (xsp + 20)
	ldada xbc, 10668
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	extz wa
	muls wa, 0x11
	lda_24 xbc, 0xe324c4
	exts xwa
	add xwa, xbc
	push xwa
	ld bc, (xsp + 24)
	mul bc, 0x11
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 18)
	add xwa, xbc
	push xwa
	call Strncpy
	lda xsp, (xsp + 10)
	incm 1, (xsp + 18)
	cpw (xsp + 18), 0x8
	jr c, DspItem0_DisplayParamNames
	ldw (xsp + 18), 0x0

DspItem0_DisplayParamValues:
	pushw 0x2
	ld8_24 a, 0x021098
	extz wa
	add wa, (xsp + 20)
	ldada xbc, 10668
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	extz wa
	add wa, wa
	lda_24 xbc, 0xe32418
	exts xwa
	add xwa, xbc
	push xwa
	ld wa, (xsp + 24)
	add wa, wa
	extz xwa
	st_dri3b A, 0xE1, 0x88, 0x00
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 18)
	add xwa, xbc
	push xwa
	call Strncpy
	lda xsp, (xsp + 10)
	incm 1, (xsp + 18)
	cpw (xsp + 18), 0x8
	jr c, DspItem0_DisplayParamValues
	jr DspItem0_ExitWithHL
	ld (xsp), xde
	ld xde, (xde + 18)
	ld wa, bc
	ld xbc, xde
	jr DspItem0_FormatParamValue
	ld (xsp), xde
	ld xbc, (xde + 18)
	jr DspItem0_FormatParamValue
	ld (xsp), xde
	ld xbc, (xde + 18)
	ld wa, (xsp + 8)
	jr DspItem0_FormatParamValue
	ld (xsp), xde
	ld xbc, (xde + 18)
	ld wa, (xsp + 10)
	jr DspItem0_FormatParamValue
	ld (xsp), xde
	ld xbc, (xde + 18)
	ld wa, (xsp + 12)
	jr DspItem0_FormatParamValue
	ld (xsp), xde
	ld xbc, (xde + 18)
	ld wa, (xsp + 14)
	jr DspItem0_FormatParamValue
	ld (xsp), xde
	ld xbc, (xde + 18)
	ld wa, (xsp + 16)
	jr DspItem0_FormatParamValue
	ld (xsp), xde
	ld xbc, (xde + 18)
	ld wa, (xsp + 18)

DspItem0_FormatParamValue:
	calr FormatParamValueStr
	jr DspItem0_ExitWithHL

DspItem0_SendEffectParam:
	ld (xsp), xde
	ld xwa, (xsp + 4)
	pushm (xwa)
	pushw 0xE3
	pushw 0x4D8C
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 18)
	push xwa
	call Audio_SendCommand
	lda xsp, (xsp + 10)

DspItem0_ExitWithHL:
	ld xhl, (xsp + 24)
	jrl DspItem0_Epilogue

DspItem0_TypeChangeHandler:
	cp xde, 0x8
	jr ugt, DspItem0_TypeDispatch
	add xde, xde
	add xde, 0xE34D92
	ld de, (xde)
	lda_24 xix, 0xf35747
	jp_dri 8, 0x07, 0xF0, 0xE8

; DspItem0 type change dispatch
DspItem0_TypeDispatch:
	ldada xhl, 10614
	jrl DspItem0_Epilogue
	sla bc, 1
	ld xwa, (xsp + 4)
	st_dri3b C, 0x07, 0xE0, 0xE4
	jrl DspItem0_Epilogue
	sla wa, 1
	ld bc, wa
	ld xwa, (xsp + 4)
	st_dri3b C, 0x07, 0xE0, 0xE4
	jrl DspItem0_Epilogue
	ld bc, (xsp + 8)
	sla bc, 1
	ld xwa, (xsp + 4)
	st_dri3b C, 0x07, 0xE0, 0xE4
	jrl DspItem0_Epilogue
	ld bc, (xsp + 10)
	add bc, bc
	ld xwa, (xsp + 4)
	st_dri3b C, 0x07, 0xE0, 0xE4
	jr DspItem0_Epilogue
	ld bc, (xsp + 12)
	add bc, bc
	ld xwa, (xsp + 4)
	st_dri3b C, 0x07, 0xE0, 0xE4
	jr DspItem0_Epilogue
	ld bc, (xsp + 14)
	add bc, bc
	ld xwa, (xsp + 4)
	st_dri3b C, 0x07, 0xE0, 0xE4
	jr DspItem0_Epilogue
	ld bc, (xsp + 16)
	add bc, bc
	ld xwa, (xsp + 4)
	st_dri3b C, 0x07, 0xE0, 0xE4
	jr DspItem0_Epilogue
	ld bc, (xsp + 18)
	add bc, bc
	ld xwa, (xsp + 4)
	st_dri3b C, 0x07, 0xE0, 0xE4
	jr DspItem0_Epilogue

LABEL_F357C8:
	lds32 xhl, 2
	jr DspItem0_Epilogue
	lds32 xwa, 0
	ldda8 a, 10666
	cp xde, xwa
	scc16 c, hl
	extz xhl
	jr DspItem0_Epilogue
	st8_24 0x02109a, e

EffectEdit_ReturnZero:
	lds32 xhl, 0
	jr DspItem0_Epilogue
	lds32 xhl, 0
	ld8_24 l, 0x02109a
	jr DspItem0_Epilogue
	st8_24 0x021098, e
	jr EffectEdit_ReturnZero
	ldb h, 0x0
	extz xhl
	jr DspItem0_Epilogue
	lds32 xhl, 0
	ldda8 l, 10666
	jr DspItem0_Epilogue

; DspItem0 dispatch target (calls GetTitleNow then falls through to epilogue)
DspItem0_DispatchTarget:
	call GetTitleNow
	ldb h, 0x0
	extz xhl

DspItem0_Epilogue:
	lda xsp, (xsp + 28)
	ret

EqualizerCngFunc:
	push xiz
	ld xiz, xwa
	ld xwa, xbc
	cp xbc, 0x1E00045
	jrl z, Equalizer_ParamByIndex
	cp xbc, 0x1E80013
	jr z, Equalizer_DispatchA
	lda_24 xbc, 0xe321fa
	ldada xhl, 10616
	sub xwa, 0x1E80061
	cp xwa, 0x0
	jrl lt, Equalizer_ParamString
	cp xwa, 0x8
	jrl gt, Equalizer_ParamString
	add xwa, xwa
	add xwa, 0xE34DDC
	ld wa, (xwa)
	lda_24 xix, 0xf35858
	jp_dri 8, 0x07, 0xF0, 0xE0

; EqualizerCngFunc dispatch A
Equalizer_DispatchA:
	ld xwa, xde
	lda_24 xbc, 0xe30dfe
	lda_24 xde, 0xe30dc6
	dec 2, xwa
	cp xwa, 0x0
	jrl c, Equalizer_LookupParamByIndex
	cp xwa, 0x6
	jrl ugt, Equalizer_LookupParamByIndex
	add xwa, xwa
	add xwa, 0xE34DCE
	ld wa, (xwa)
	lda_24 xix, 0xf3588c
	jp_dri 8, 0x07, 0xF0, 0xE0

; --- EQ_7Band_ParamLookup: Look up equalizer parameters for 7 frequency bands ---
; Seven entry points, one per EQ band. Each reads a 16-bit index from
; consecutive RAM addresses (0x297A-0x2986), doubles it as a table offset,
; adds to the base pointer in XBC/XDE, loads a 16-bit value, and jumps
; to a common handler. Alternates between XBC and XDE base registers.
; EqualizerCngFunc dispatch B
Equalizer_DispatchB:
	ldda16	wa, 10618
	extz	xwa
	add	xwa, xwa
	add	xbc, xwa
	ld	hl, (xbc)
	extz	xhl
	jrl	300
	ldda16	wa, 10620
	extz	xwa
	add	xwa, xwa
	add	xde, xwa
	ld	hl, (xde)
	extz	xhl
	jrl	283
	ldda16	wa, 10622
	extz	xwa
	add	xwa, xwa
	add	xbc, xwa
	ld	hl, (xbc)
	extz	xhl
	jrl	266
	ldda16	wa, 10624
	extz	xwa
	add	xwa, xwa
	add	xde, xwa
	ld	hl, (xde)
	extz	xhl
	jrl	249
	ldda16	wa, 10626
	extz	xwa
	add	xwa, xwa
	add	xbc, xwa
	ld	hl, (xbc)
	extz	xhl
	jrl	232
	ldda16	wa, 10628
	extz	xwa
	add	xwa, xwa
	add	xde, xwa
	ld	hl, (xde)
	extz	xhl
	jrl	215
	ldda16	wa, 10630
	extz	xwa
	add	xwa, xwa
	add	xbc, xwa
	ld	hl, (xbc)
	extz	xhl
	jrl	198

Equalizer_LookupParamByIndex:
	ldda16 xwa, 10616
	extz xwa
	add xwa, xwa
	add xde, xwa
	ld hl, (xde)
	extz xhl
	jrl Equalizer_PopIzRet

; Equalizer param by index lookup
Equalizer_ParamByIndex:
	ldada xbc, 10616
	dec 1, xde
	cp xde, 0x0
	jr c, Equalizer_ReturnParamAddr
	cp xde, 0x6
	jr ugt, Equalizer_ReturnParamAddr
	add xde, 0xE34DC6
	ld a, (xde)
	exts wa
	st_dri3b C, 0x07, 0xE4, 0xE0
	jrl Equalizer_PopIzRet

Equalizer_ReturnParamAddr:
	ldada xhl, 10616
	jrl Equalizer_PopIzRet
	ld xix, xde
	pushw 0x5
	jr Equalizer_LookupParamString
	ld xix, xde
	pushw 0x5
	lds wa, 2
	jr FormatEqParamValue
	ld xix, xde
	pushw 0x5
	inc 4, xhl
	jr Equalizer_LookupParamString
	ld xix, xde
	pushw 0x5
	lds wa, 6
	jr FormatEqParamValue
	ld xix, xde
	pushw 0x5
	inc 8, xhl
	jr Equalizer_LookupParamString
	ld xix, xde
	pushw 0x5
	ldw wa, 0xA
	jr FormatEqParamValue
	ld xix, xde
	pushw 0x5
	lda xhl, (xhl + 12)

Equalizer_LookupParamString:
	ld wa, (xhl)
	extz xwa
	ld xbc, xwa
	sll xbc, 2
	add xbc, xwa
	ld xwa, 0xE32390
	add xwa, xbc
	push xwa
	jr LABEL_F359AE
	ld xix, xde
	pushw 0x5
	ldw wa, 0xE

FormatEqParamValue:
	ld_sriw3 WA, 0x07, 0xEC, 0xE0
	extz xwa
	ld xde, xwa
	sll xde, 2
	add xde, xwa
	add xbc, xde
	push xbc

LABEL_F359AE:
	ld xwa, (xix + 18)
	push xwa
	call Strncpy
	lda xsp, (xsp + 10)
	ld xhl, xiz
	jr Equalizer_PopIzRet
	call GetTitleNow
	ldb h, 0x0
	extz xhl
	jr Equalizer_PopIzRet

; Equalizer param string lookup
Equalizer_ParamString:
	lds32 xhl, 0

Equalizer_PopIzRet:
	pop xiz
	ret

MainExeFunc:
	cp xbc, 0x1C00007
	jr nz, Equalizer_FormatValue
	ld xwa, 0x1480001
	call MainPostEvent

; Equalizer format param value
Equalizer_FormatValue:
	lds32 xhl, 0
	ret

SureJudgeFunc:
	cp xbc, 0x1C00007
	jrl nz, ParamCmd_ReturnZero
	cpi8_24 0x0340ea, 0x00
	jr nz, Equalizer_CmdDispatch
	ld xwa, 0x1480001
	call MainPostEvent
	jrl ParamCmd_ReturnZero

; Equalizer command dispatch
Equalizer_CmdDispatch:
	lds wa, 0
	call SetDialEnable
	call GetTitleNow
	ld xwa, xhl
	cp xhl, 0x1A00091
	jr z, Equalizer_CmdCase1
	cp xhl, 0x1A00090
	jr z, Equalizer_CmdCase0
	sub xwa, 0x1A0009A
	cp xwa, 0x0
	jrl lt, ParamCmd_ReturnZero
	cp xwa, 0xE
	jrl gt, ParamCmd_ReturnZero
	add xwa, xwa
	add xwa, 0xE34DEE
	ld wa, (xwa)
	lda_24 xix, 0xf35a44
	jp_dri 8, 0x07, 0xF0, 0xE0

; Equalizer command case 0
Equalizer_CmdCase0:
	ld xwa, 0x900009
	ld xbc, 0x1C00001
	lds32 xde, 5
	jrl ParamCmd_SendAndReturnZero

; Equalizer command case 1
Equalizer_CmdCase1:
	ld xwa, 0x91000B
	ld xbc, 0x1C00001
	lds32 xde, 5
	jrl ParamCmd_SendAndReturnZero
	ld xwa, 0x9A0006
	ld xbc, 0x1C00001
	lds32 xde, 5
	jrl ParamCmd_SendAndReturnZero
	ld xwa, 0x9B000F
	ld xbc, 0x1C00001
	lds32 xde, 5
	jr ParamCmd_SendAndReturnZero
	ld xwa, 0x9C000E
	ld xbc, 0x1C00001
	lds32 xde, 5
	jr ParamCmd_SendAndReturnZero
	ld xwa, 0x9D000A
	ld xbc, 0x1C00001
	lds32 xde, 5
	jr ParamCmd_SendAndReturnZero
	ld xwa, 0x9E000A
	ld xbc, 0x1C00001
	lds32 xde, 5
	jr ParamCmd_SendAndReturnZero
	ld xwa, 0x9F0012
	ld xbc, 0x1C00001
	lds32 xde, 5
	jr ParamCmd_SendAndReturnZero
	ld xwa, 0xA0000A
	ld xbc, 0x1C00001
	lds32 xde, 5
	jr ParamCmd_SendAndReturnZero
	ld xwa, 0xA20009
	ld xbc, 0x1C00001
	lds32 xde, 5
	jr ParamCmd_SendAndReturnZero
	ld xwa, 0xA30009
	ld xbc, 0x1C00001
	lds32 xde, 5
	jr ParamCmd_SendAndReturnZero
	ld xwa, 0xA40009
	ld xbc, 0x1C00001
	lds32 xde, 5
	jr ParamCmd_SendAndReturnZero
	ld xwa, 0xA1000A
	ld xbc, 0x1C00001
	lds32 xde, 5

ParamCmd_SendAndReturnZero:
	call SendEvent

ParamCmd_ReturnZero:
	lds32 xhl, 0
	ret

FormatParamValueStr:
	push xiz
	ld xiz, xbc
	ld (xiz), 0x20
	ld c, a
	extz bc
	ldada xde, 10668
	extz xbc
	add xbc, xde
	ld w, (xbc)
	lda xhl, (xiz + 1)
	cp w, 0x55
	jrl z, Equalizer_CopyFixedString
	cps w, 0
	jrl z, Equalizer_CopyFixedString
	ld c, a
	extz bc
	ldada xde, 10616
	cp w, 0x49
	jrl z, Equalizer_FormatDefault
	cp w, 0x47
	jr z, FormatParamString
	cp w, 0x41
	jr z, FormatParamString
	cp w, 0x40
	jr z, FormatParamString
	ld a, w
	extz wa
	dec 8, wa
	cps wa, 0
	jrl lt, PrepareAudioParam
	cp wa, 0x11
	jr le, Equalizer_FormatDispatch
	dec 6, wa
	cp wa, 0x12
	jrl lt, PrepareAudioParam
	cp wa, 0x2B
	jrl gt, PrepareAudioParam

; Equalizer format dispatch
Equalizer_FormatDispatch:
	lda_24 xix, 0xe34e28
	ld_sriw3 WA, 0x07, 0xF0, 0xE0
	extz wa
	sll wa, 1
	ld xix, 0xE34E54
	ld_sriw3 WA, 0x07, 0xF0, 0xE0
	lda_24 xix, 0xf35b85
	jp_dri 8, 0x07, 0xF0, 0xE0

LABEL_F35B85:
	.byte 0x0b, 0x05, 0x00, 0x40, 0x90, 0x23, 0xe3, 0x00
	.byte 0x78, 0xc2, 0x00, 0x0b, 0x05, 0x00, 0x40, 0xf0
	.byte 0x22, 0xe3, 0x00, 0x78, 0xb7, 0x00, 0x0b, 0x05
	.byte 0x00, 0x40, 0xfa, 0x21, 0xe3, 0x00, 0x78, 0xac
	.byte 0x00

FormatParamString:
	pushw 0x5
	ld xwa, 0xE32006
	jrl FormatParamStr_CopyEnumName
	pushw 0x5
	ld xwa, 0xE31FF6
	jrl FormatParamStr_CopyEnumName
	pushw 0x5
	ld xwa, 0xE31E02
	jrl FormatParamStr_CopyEnumName

; Equalizer format default
Equalizer_FormatDefault:
	pushw 0x5
	ld xwa, 0xE31C0E
	jrl FormatParamStr_CopyEnumName
	pushw 0x5
	ld xwa, 0xE31A1A
	jr FormatParamStr_CopyEnumName
	pushw 0x5
	ld xwa, 0xE31A10
	jr FormatParamStr_CopyEnumName
	pushw 0x5
	ld xwa, 0xE318A2
	jr FormatParamStr_CopyEnumName
	pushw 0x5
	ld xwa, 0xE316AE
	jr FormatParamStr_CopyEnumName
	pushw 0x5
	ld xwa, 0xE314BA
	jr FormatParamStr_CopyEnumName
	pushw 0x5
	ld xwa, 0xE312C6
	jr FormatParamStr_CopyEnumName
	pushw 0x5
	ld xwa, 0xE310D2
	jr FormatParamStr_CopyEnumName
	add bc, bc
	ld_sriw3 WA, 0x07, 0xE8, 0xE4
	cps wa, 0
	jr ge, LABEL_F35C2D
	neg wa
	pushw wa
	ld xwa, 0xE34E0C
	jr SendAudioCommand

LABEL_F35C2D:
	pushw wa
	cps wa, 0
	jr le, LABEL_F35C39
	ld xwa, 0xE34E12
	jr SendAudioCommand

LABEL_F35C39:
	ld xwa, 0xE34E18
	jr SendAudioCommand
	pushw 0x5
	ld xwa, 0xE31054
	jr FormatParamStr_CopyEnumName
	pushw 0x5
	ld xwa, 0xE30E60

FormatParamStr_CopyEnumName:
	add bc, bc
	ld_sriw3 BC, 0x07, 0xE8, 0xE4
	extz xbc
	ld xde, xbc
	sll xde, 2
	add xde, xbc
	add xwa, xde
	push xwa
	push xhl
	call Strncpy
	lda xsp, (xsp + 10)
	jr Equalizer_PadSpaceAndReturn

Equalizer_CopyFixedString:
	pushw 0xE3
	pushw 0x4E1E
	push xhl
	call Strcpy
	inc 8, xsp
	jr Equalizer_PadSpaceAndReturn

PrepareAudioParam:
	add bc, bc
	push_sriw 0x07, 0xE8, 0xE4
	ld xwa, 0xE34E24

SendAudioCommand:
	push xwa
	push xhl
	call Audio_SendCommand
	lda xsp, (xsp + 10)

Equalizer_PadSpaceAndReturn:
	ld (xiz + 6), 0x20
	pop xiz
	ret

CycleOnOffFunc:
	cp xbc, 0x1E0003B
	jr nz, LABEL_F35CAF
	ld xwa, 0x1480003
	ld xbc, 0x1E80044
	call MainPostEvent

LABEL_F35CAF:
	lds32 xhl, 0
	ret

MetroOnOffFunc:
	cp xbc, 0x1E0003B
	jr nz, LABEL_F35CDC
	or xde, xde
	jr nz, LABEL_F35CCC
	ld xwa, 0x1480003
	ld xbc, 0x1E80045
	lds32 xde, 0
	jr LABEL_F35CD8

LABEL_F35CCC:
	ld xwa, 0x1480003
	ld xbc, 0x1E80045
	lds32 xde, 1

LABEL_F35CD8:
	call MainPostEvent

LABEL_F35CDC:
	lds32 xhl, 0
	ret

PunchInOutFunc:
	cp xbc, 0x1E0003B
	jr nz, LABEL_F35D09
	or xde, xde
	jr nz, LABEL_F35CF9
	ld xwa, 0x1480003
	ld xbc, 0x1E80046
	lds32 xde, 0
	jr LABEL_F35D05

LABEL_F35CF9:
	ld xwa, 0x1480003
	ld xbc, 0x1E80046
	lds32 xde, 1

LABEL_F35D05:
	call MainPostEvent

LABEL_F35D09:
	lds32 xhl, 0
	ret

EqInOutFunc:
	cp xbc, 0x1E0003B
	jr nz, LABEL_F35D30
	or xde, xde
	jr nz, LABEL_F35D23
	ld xwa, 0x4006
	lds bc, 0
	lds de, 1
	jr LABEL_F35D2C

LABEL_F35D23:
	ld xwa, 0x4006
	lds bc, 1
	lds de, 1

LABEL_F35D2C:
	call MainLswPut

LABEL_F35D30:
	lds32 xhl, 0
	ret

MimeOnOffFunc:
	cp xbc, 0x1E0003B
	jr nz, LABEL_F35D49
	ld xwa, 0x1480023
	ld xbc, 0x1E0003B
	call MainPostEvent

LABEL_F35D49:
	lds32 xhl, 0
	ret

TrkMixerIntTtlFunc:
	ld xwa, 0xFFFFFFFF
	ld xbc, 0x1C00016
	ld xde, 0x1A000A5
	call PostEvent
	lds32 xhl, 0
	ret


BitmapNtedt0k:
	cp xbc, 0x1E000A3
	jr z, LABEL_F35D89
	cp xbc, 0x1E000A2
	jr z, LABEL_F35D83
	cp xbc, 0x1E000A1
	jr z, LABEL_F35D7D
	lds32 xhl, 0
	ret

LABEL_F35D7D:
	lda_24 xhl, 0xe34e78
	ret

LABEL_F35D83:
	ld xhl, 0x10
	ret

LABEL_F35D89:
	ld xhl, 0x7F
	ret


BitmapNtedt0d:
	cp xbc, 0x1E000A3
	jr z, LABEL_F35DB6
	cp xbc, 0x1E000A2
	jr z, LABEL_F35DB0
	cp xbc, 0x1E000A1
	jr z, LABEL_F35DAA
	lds32 xhl, 0
	ret

LABEL_F35DAA:
	lda_24 xhl, 0xe35668
	ret

LABEL_F35DB0:
	ld xhl, 0xF0
	ret

LABEL_F35DB6:
	ld xhl, 0x7F
	ret


BitmapDredt0k:
	cp xbc, 0x1E000A3
	jr z, LABEL_F35DE3
	cp xbc, 0x1E000A2
	jr z, LABEL_F35DDD
	cp xbc, 0x1E000A1
	jr z, LABEL_F35DD7
	lds32 xhl, 0
	ret

LABEL_F35DD7:
	lda_24 xhl, 0xe3cd78
	ret

LABEL_F35DDD:
	ld xhl, 0x58
	ret

LABEL_F35DE3:
	ld xhl, 0x77
	ret

BitmapDredt0d:
	cp xbc, 0x1E000A3
	jr z, BitmapDredt0d_ReturnSize77
	cp xbc, 0x1E000A2
	jr z, BitmapDredt0d_ReturnSizeA8
	cp xbc, 0x1E000A1
	jr z, BitmapDredt0d_ReturnDataPtr
	lds32 xhl, 0
	ret

BitmapDredt0d_ReturnDataPtr:
	lda_24 xhl, 0xe3f660
	ret

BitmapDredt0d_ReturnSizeA8:
	ld xhl, 0xA8
	ret

BitmapDredt0d_ReturnSize77:
	ld xhl, 0x77
	ret

	.include "sequencer/bmdredit_routines.s"
