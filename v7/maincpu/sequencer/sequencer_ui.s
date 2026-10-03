; =============================================================================
; Sequencer UI (14K lines)
; =============================================================================
;
; Sequencer editing user interface: track display, step/event
; editing, and the bitmap drum editor integration.
; =============================================================================

InitializeYoko:
	lda xsp, (xsp - 0x0e)
	RegObjTable NAKA_CLASS_Class, ClassProc, Yoko_ClassCount_167, Yoko_ClassTable_167, 0x167
	RegObjTable NAKA_CLASS_ResEvent, ResEventProc, Yoko_ResEventCount_1C7, EvtName_PtrTable, 0x1c7
	RegObjTable NAKA_CLASS_ResMethod, ResMethodProc, Yoko_ResMethodCount_1E7, MtName_PtrTable, 0x1e7
	RegObjTabl NAKA_CLASS_ApFunction, ApFunctionProc, 0x2e, Yoko_ApFunctionTable_127, 0x127
	RegObjTabl NAKA_CLASS_ApFunction, ApFunctionProc, 0x2e, Yoko_ApFunctionTable_427, 0x427
	RegObjTabl NAKA_CLASS_Function, FunctionProc, 0x1, Yoko_FunctionTable_107, 0x107
	RegObjTabl NAKA_CLASS_Function, FunctionProc, 0x1, Yoko_FunctionTable_407, 0x407
	RegObjTabl NAKA_CLASS_MainFunction, MainFunctionProc, 0x1f, Yoko_MainFuncTable_147, 0x147
	RegObjTabl NAKA_CLASS_MainFunction, MainFunctionProc, 0x1f, Yoko_MainFuncNameTable_447, 0x447
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x2b, Yoko_ViewTable_06F, 0x6f
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x2b, Yoko_ResNameTable_36F, 0x36f
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0xc, Yoko_ViewTable_070, 0x70
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0xc, Yoko_ResNameTable_370, 0x370
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0xb, Yoko_ViewTable_071, 0x71
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0xb, Yoko_ResNameTable_371, 0x371
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x7, Yoko_ViewTable_072, 0x72
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x7, Yoko_ResNameTable_372, 0x372
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x10, Yoko_ViewTable_073, 0x73
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x10, Yoko_ResNameTable_373, 0x373
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0xf, Yoko_ViewTable_074, 0x74
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0xf, Yoko_ResNameTable_374, 0x374
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0xd, Yoko_ViewTable_075, 0x75
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0xd, Yoko_ResNameTable_375, 0x375
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x8, Yoko_ViewTable_076, 0x76
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x8, Yoko_ResNameTable_376, 0x376
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x1e, Yoko_ViewTable_078, 0x78
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x1e, Yoko_ResNameTable_378, 0x378
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0xc, Yoko_ViewTable_07A, 0x7a
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0xc, Yoko_ResNameTable_37A, 0x37a
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x5, Yoko_ViewTable_089, 0x89
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x5, Yoko_ResNameTable_389, 0x389
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x1, Yoko_ViewTable_08A, 0x8a
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x1, Yoko_ResNameTable_38A, 0x38a
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x16, Yoko_ViewTable_08B, 0x8b
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x16, Yoko_ResNameTable_38B, 0x38b
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x1c, Yoko_ViewTable_08C, 0x8c
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x1c, Yoko_ResNameTable_38C, 0x38c
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x5, Yoko_ViewTable_08E, 0x8e
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x5, Yoko_ResNameTable_38E, 0x38e
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x6, Yoko_ViewTable_08F, 0x8f
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x6, Yoko_ResNameTable_38F, 0x38f
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x4, Yoko_ViewTable_092, 0x92
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x4, Yoko_ResNameTable_392, 0x392
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x0, Yoko_ViewTable_0A7, 0xa7
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x0, Yoko_ResNameTable_3A7, 0x3a7
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x6, Yoko_ViewTable_0A9, 0xa9
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x6, Yoko_ResNameTable_3A9, 0x3a9
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x4, Yoko_ViewTable_0E0, 0xe0
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x4, Yoko_ResNameTable_3E0, 0x3e0
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0xc, Yoko_ViewTable_0E1, 0xe1
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0xc, Yoko_ResNameTable_3E1, 0x3e1
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0xc, Yoko_ViewTable_0E2, 0xe2
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0xc, Yoko_ResNameTable_3E2, 0x3e2
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0xc, Yoko_ViewTable_0E3, 0xe3
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0xc, Yoko_ResNameTable_3E3, 0x3e3
	pushw 0x0007
	pushw Yoko_ResNames_3E3_Strings@hi16
	pushw Yoko_ResNames_3E3_Strings@lo16
	ld XWA,0x0000000d
	ld XBC,NAKA_MAINFUNC_SeqStepModeFunc
	ld XDE,TITLE_SQTRSEL
	call RegisterMode
	pushw 0x0007
	pushw InitializeYoko_Str_MD_DEMO@hi16
	pushw InitializeYoko_Str_MD_DEMO@lo16
	ld XWA,0x00000013
	ld XBC,NAKA_MAINFUNC_DemoModeFunc
	ld XDE,TITLE_DEMOMENU
	call RegisterMode
	pushw 0x0007
	pushw InitializeYoko_Str_TT_DPSMF@hi16
	pushw InitializeYoko_Str_TT_DPSMF@lo16
	ld XWA,0x0000006f
	ld XBC,NAKA_MAINFUNC_DpSmfTtlFunc
	ld XDE,0x006f0000
	call RegisterTitle
	pushw 0x0007
	pushw InitializeYoko_Str_TT_DPDOC@hi16
	pushw InitializeYoko_Str_TT_DPDOC@lo16
	ld XWA,0x00000070
	ld XBC,NAKA_MAINFUNC_DpDocTtlFunc
	ld XDE,0x00700000
	call RegisterTitle
	pushw 0x0007
	pushw InitializeYoko_Str_TT_DPPD@hi16
	pushw InitializeYoko_Str_TT_DPPD@lo16
	ld XWA,0x00000071
	ld XBC,NAKA_MAINFUNC_DpPdTtlFunc
	ld XDE,0x00710000
	call RegisterTitle
	pushw 0x0007
	pushw InitializeYoko_Str_TT_DPSMFLYR@hi16
	pushw InitializeYoko_Str_TT_DPSMFLYR@lo16
	ld XWA,0x00000072
	ld XBC,NAKA_MAINFUNC_DpSmfLyrTtlFunc
	ld XDE,0x00720000
	call RegisterTitle
	pushw 0x0007
	pushw InitializeYoko_Str_TT_DPMDLYSMF@hi16
	pushw InitializeYoko_Str_TT_DPMDLYSMF@lo16
	ld XWA,0x00000073
	ld XBC,NAKA_MAINFUNC_DpMdlySmfTtlFunc
	ld XDE,0x00730000
	call RegisterTitle
	pushw 0x0007
	pushw InitializeYoko_Str_TT_DPMDLYDOC@hi16
	pushw InitializeYoko_Str_TT_DPMDLYDOC@lo16
	ld XWA,0x00000074
	ld XBC,NAKA_MAINFUNC_DpMdlyDocTtlFunc
	ld XDE,0x00740001
	call RegisterTitle
	pushw 0x0007
	pushw InitializeYoko_Str_TT_DPMDLYPD@hi16
	pushw InitializeYoko_Str_TT_DPMDLYPD@lo16
	ld XWA,0x00000075
	ld XBC,NAKA_MAINFUNC_DpMdlyPdTtlFunc
	ld XDE,0x00750000
	call RegisterTitle
	pushw 0x0007
	pushw InitializeYoko_Str_TT_DPMDLYSMFLYR@hi16
	pushw InitializeYoko_Str_TT_DPMDLYSMFLYR@lo16
	ld XWA,0x00000076
	ld XBC,NAKA_MAINFUNC_DpMdlySmfLyrTtlFunc
	ld XDE,0x00760000
	call RegisterTitle
	pushw 0x0007
	pushw InitializeYoko_Str_TT_DKMDLYPLY@hi16
	pushw InitializeYoko_Str_TT_DKMDLYPLY@lo16
	ld XWA,0x00000078
	ld XBC,NAKA_MAINFUNC_DkMdlyPlyTtlFunc
	ld XDE,0x00780000
	call RegisterTitle
	pushw 0x0007
	pushw InitializeYoko_Str_TT_SQMDLYPLY@hi16
	pushw InitializeYoko_Str_TT_SQMDLYPLY@lo16
	ld XWA,0x0000007a
	ld XBC,NAKA_MAINFUNC_SqMdlyPlyTtlFunc
	ld XDE,0x007a0000
	call RegisterTitle
	pushw 0x0007
	pushw InitializeYoko_Str_TT_SQTRSEL@hi16
	pushw InitializeYoko_Str_TT_SQTRSEL@lo16
	ld XWA,0x00000089
	ld XBC,NAKA_MAINFUNC_SqTrSelTtlFunc
	ld XDE,0x00890000
	call RegisterTitle
	pushw 0x0007
	pushw InitializeYoko_Str_TT_SQSTEP@hi16
	pushw InitializeYoko_Str_TT_SQSTEP@lo16
	ld XWA,0x0000008a
	ld XBC,NAKA_MAINFUNC_SqStepTtlFunc
	ld XDE,0x008a0000
	call RegisterTitle
	pushw 0x0007
	pushw InitializeYoko_Str_TT_SQTRAS@hi16
	pushw InitializeYoko_Str_TT_SQTRAS@lo16
	ld XWA,0x0000008b
	ld XBC,NAKA_MAINFUNC_SqTrAsTtlFunc
	ld XDE,0x008b0000
	call RegisterTitle
	pushw 0x0007
	pushw InitializeYoko_Str_TT_SQTRASPS@hi16
	pushw InitializeYoko_Str_TT_SQTRASPS@lo16
	ld XWA,0x0000008c
	ld XBC,NAKA_MAINFUNC_SqTrAsPsTtlFunc
	ld XDE,0x008c0000
	call RegisterTitle
	pushw 0x0007
	pushw InitializeYoko_Str_TT_SQSNGSEL@hi16
	pushw InitializeYoko_Str_TT_SQSNGSEL@lo16
	ld XWA,0x0000008e
	ld XBC,NAKA_MAINFUNC_SqSngSelTtlFunc
	ld XDE,0x008e0000
	call RegisterTitle
	pushw 0x0007
	pushw InitializeYoko_Str_TT_SQSNGNAME@hi16
	pushw InitializeYoko_Str_TT_SQSNGNAME@lo16
	ld XWA,0x0000008f
	ld XBC,NAKA_MAINFUNC_SqSngNameTtlFunc
	ld XDE,0x008f0000
	call RegisterTitle
	pushw 0x0007
	pushw InitializeYoko_Str_TT_SQAFTSET@hi16
	pushw InitializeYoko_Str_TT_SQAFTSET@lo16
	ld XWA,0x00000092
	ld XBC,NAKA_MAINFUNC_SqAftSetTtlFunc
	ld XDE,0x00920000
	call RegisterTitle
	pushw 0x0007
	pushw InitializeYoko_Str_TT_SQEASYNAME@hi16
	pushw InitializeYoko_Str_TT_SQEASYNAME@lo16
	ld XWA,0x000000a7
	ld XBC,NAKA_MAINFUNC_SqSngNameTtlFunc
	ld XDE,0x008f0000
	call RegisterTitle
	pushw 0x0007
	pushw InitializeYoko_Str_TT_SQSTEPBAL@hi16
	pushw InitializeYoko_Str_TT_SQSTEPBAL@lo16
	ld XWA,0x000000a9
	ld XBC,NAKA_APFUNC_DefaultFunction
	ld XDE,0x00a90000
	call RegisterTitle
	pushw 0x0007
	pushw InitializeYoko_Str_TT_DEMOMENU@hi16
	pushw InitializeYoko_Str_TT_DEMOMENU@lo16
	ld XWA,0x000000e0
	ld XBC,NAKA_MAINFUNC_DemoMenuTtlFunc
	ld XDE,LED_patterns_indicating_firmware_version
	call RegisterTitle
	pushw 0x0007
	pushw InitializeYoko_Str_TT_DEMOSTYLE@hi16
	pushw InitializeYoko_Str_TT_DEMOSTYLE@lo16
	ld XWA,0x000000e1
	ld XBC,NAKA_MAINFUNC_DemoStyleTtlFunc
	ld XDE,InitializeYoko_Data
	call RegisterTitle
	pushw 0x0007
	pushw InitializeYoko_Str_TT_DEMOSOUND@hi16
	pushw InitializeYoko_Str_TT_DEMOSOUND@lo16
	ld XWA,0x000000e2
	ld XBC,NAKA_MAINFUNC_DemoSoundTtlFunc
	ld XDE,0x00e20000
	call RegisterTitle
	pushw 0x0007
	pushw InitializeYoko_Str_TT_DEMORHY@hi16
	pushw InitializeYoko_Str_TT_DEMORHY@lo16
	ld XWA,0x000000e3
	ld XBC,NAKA_MAINFUNC_DemoRhyTtlFunc
	ld XDE,InitializeYoko_PtrTable
	call RegisterTitle
	lda xsp, (xsp + 0x0e)
	ret
PartSelLangCheck:
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr nz, PartSelLang_ReturnZero
	lda xhl, (PartSelLangCheck_PtrTable:24)
	ret

PartSelLang_ReturnZero:
	ld xhl, 0:i3
	ret

AfterLangCheck:
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr nz, AfterLang_ReturnZero
	lda xhl, (AfterLangCheck_PtrTable:24)
	ret

AfterLang_ReturnZero:
	ld xhl, 0:i3
	ret

TrAsPreLangCheck:
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr nz, TrAsPreLang_ReturnZero
	lda xhl, (TrAsPreLangCheck_PtrTable:24)
	ret

TrAsPreLang_ReturnZero:
	ld xhl, 0:i3
	ret

AtentionLangCheck:
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr nz, AtentionLang_ReturnZero
	lda xhl, (AtentionLangCheck_PtrTable:24)
	ret

AtentionLang_ReturnZero:
	ld xhl, 0:i3
	ret

AreYouSureLangCheck:
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr nz, AreYouSureLang_ReturnZero
	lda xhl, (AreYouSureLangCheck_PtrTable:24)
	ret

AreYouSureLang_ReturnZero:
	ld xhl, 0:i3
	ret

GmOnSureLangCheck:
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr nz, GmOnSureLang_ReturnZero
	lda xhl, (GmOnSureLangCheck_PtrTable:24)
	ret

GmOnSureLang_ReturnZero:
	ld xhl, 0:i3
	ret

GmOffSureLangCheck:
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr nz, GmOffSureLang_ReturnZero
	lda xhl, (GmOffSureLangCheck_PtrTable:24)
	ret

GmOffSureLang_ReturnZero:
	ld xhl, 0:i3
	ret

TrAsSureLangCheck:
	cp	xbc, EVT_GET_LANGUAGE_PTR
	jr	nz, TrAsSureLang_ReturnZero	; -> 0xF2A9D5
	ld	a, (10355:16)
	extz	wa
	sla	wa, 2
	lda	xbc, (TrAsSureLangCheck_PtrTable_2:24)
	ld	xwa, (xbc+wa)
	push	xwa
	ld	a, (4438:16)
	extz	wa
	sla	wa, 2
	ld	xwa, (xbc+wa)
	push	xwa
	ld	a, (3295:16)
	inc	1, a
	extz	wa
	pushw	wa
	ld	a, (213220:24)
	extz	wa
	sla	wa, 2
	lda	xbc, (TrAsSureLangCheck_PtrTable:24)
	ld	xwa, (xbc+wa)
	push	xwa
	pushw	2
	pushw	3252
	call	Sprintf_Locked
	lda	xsp, (xsp+18)
	lda	xhl, (253688:24)
	ret
TrAsSureLang_ReturnZero:
	ld xhl, 0:i3
	ret

Audio_SendEventPostCmd:
	ld xwa, 0x720006
	ld xbc, EVT_LYRICS_PLAY_REQUEST
	ld xde, 0:i3
	jp ApPostEvent

Audio_ExternalCallback:
	ld xwa, 0x720006
	ld xbc, EVT_LYRICS_PLAY_REQUEST
	ld xde, 0:i3
	call ApPostEvent
	ld xwa, 0x720006
	ld xbc, EVT_LYRICS_CHANGE_COLOR
	ld xde, 0:i3
	jp ApPostEvent
Audio_ExternalCallback_End:

LyricsBoxProc:
	lda xsp, (xsp - 48)
	push xiz
	ld xiz, xde
	ld (xsp + 48), xwa
	cp xbc, EVT_LYRICS_SCROLL_UP
	jrl z, LyricsBox_HandleEventD
	cp xbc, EVT_LYRICS_REVERSE
	jrl z, LyricsBox_HandleEventC
	cp xbc, EVT_LYRICS_RENEW
	jrl z, LyricsBox_HandleEventB
	cp xbc, EVT_LYRICS_ALL_DRAW
	jr z, LyricsBox_HandleEventA
	cp xbc, EVT_LYRICS_ALL_CLEAR
	jr z, LyricsBox_HandleEvent9
	ld xwa, (xsp + 48)
	ld xde, xiz
	call InheritedProc
	jrl LyricsBox_Epilogue

LyricsBox_HandleEvent9:
	call GetTitleNow
	cp xhl, TITLE_DPSMFLYR
	jr z, LyricsBox_MatchedTitle
	call GetTitleNow
	cp xhl, TITLE_DPMDLYSMFLYR
	jr nz, LyricsBox_ClearBuffers

LyricsBox_MatchedTitle:
	ld xwa, (xsp + 48)
	ld xbc, EVT_DRAW
	ld xde, xiz
	call SendEvent

LyricsBox_ClearBuffers:
	lda xbc, (0x020cbe:24)
	ld xwa, xbc
	lda xbc, (xbc+320)

LyricsBox_ClearOuterLoop:
	ld xde, xwa
	lda xhl, (xwa + 64)

LyricsBox_ClearInnerLoop:
	ld (xde+), 0x00
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
	cp xhl, TITLE_DPSMFLYR
	jr z, LyricsBox_DrawClientArea
	call GetTitleNow
	cp xhl, TITLE_DPMDLYSMFLYR
	jrl nz, SongEdit_ReturnZero

LyricsBox_DrawClientArea:
	lda xbc, (xsp + 40)
	ld xwa, (xsp + 48)
	call GetClientBox
	lda xwa, (xsp + 40)
	incw 2, (xwa)
	incw 4, (xwa + 2)
	decm 1, (xwa + 4)
	decm 2, (xwa + 6)
	ldw (xsp + 8), 0x0
	ld xwa, (xsp + 12)
	cpw (xwa + 38), 0x0
	jrl ule, SongEdit_ReturnZero

LyricsBox_DrawLineLoop:
	lda xix, (0x020e3e:24)
	ld DE,(XIX+0x02)
	ld BC,(XSP+0x08)
	extz XBC
	sll XBC, 0x06
	ld XHL,0x00020cbe
	add XHL,XBC
	cp (XSP+0x08),DE
	jr nc, .Lc_f2ab42
	push XHL
	pushw 0x0002
	pushw 0x0dfe
	call Free_Compare2
	inc 8,XSP
	lda xbc, (xsp + 0x14)
	lda xwa, (xsp + 0x28)
	ld DE,(XWA)
	ld (XBC),DE
	ld DE,(XSP+0x08)
	mul DE,0x0012
	ld HL,(XWA+0x02)
	add HL,DE
	ld (XBC+0x02),HL
	ld XHL,(XSP+0x0c)
	ld XDE,(XHL+0x1c)
	push XDE
	pushm (xhl + 0x22)
	pushw 0x0007
	ld XDE,0x00020dfe
	jrl t, LyricsBox_DrawAndAdvance
LyricsBox_CheckCurrentLine:
.Lc_f2ab42:
	lda xbc, (0x020dfe:24)
	cp DE,(XSP+0x08)
	jrl nz, LyricsBox_CopyAndDraw
	ld WA,(XIX)
	inc 1,WA
	ld (XSP+0x0a),WA
	pushm (xsp + 0x0a)
	push XHL
	push XBC
	call CmpNamingCheck_Helper
	lda xsp, (xsp + 0x0a)
	ld WA,(XSP+0x0a)
	extz XWA
	lda xde, (0x020dfe:24)
	ld XBC,XDE
	add XBC,XWA
	ld (XBC),0x00
	lda xbc, (xsp + 0x14)
	lda xwa, (xsp + 0x28)
	ld HL,(XWA)
	ld (XBC),HL
	ld HL,(XSP+0x08)
	mul HL,0x0012
	ld IX,(XWA+0x02)
	add IX,HL
	ld (XBC+0x02),IX
	ld XHL,(XSP+0x0c)
	ld XHL,(XHL+0x1c)
	push XHL
	ld XHL,(XSP+0x08)
	pushm (xhl + 0x22)
	pushw 0x0007
	call DrawString
	ld BC,(XSP+0x0a)
	extz XBC
	ld WA,(XSP+0x08)
	extz XWA
	sll XWA, 0x06
	add XWA,XBC
	ld XBC,0x00020cbe
	add XBC,XWA
	push XBC
	pushw 0x0002
	pushw 0x0dfe
	call Free_Compare2
	inc 8,XSP
	ld BC,(XSP+0x0a)
	sll BC, 0x03
	lda xwa, (xsp + 0x28)
	ld DE,(XWA)
	add DE,BC
	lda xbc, (xsp + 0x14)
	ld (XBC),DE
	ld DE,(XSP+0x08)
	mul DE,0x0012
	ld HL,(XWA+0x02)
	add HL,DE
	ld (XBC+0x02),HL
	ld XDE,(XSP+0x0c)
	ld XDE,(XDE+0x1c)
	push XDE
	ld XDE,(XSP+0x08)
	pushm (xde + 0x20)
	pushw 0x0007
	ld XDE,0x00020dfe
	jr t, LyricsBox_DrawAndAdvance
LyricsBox_CopyAndDraw:
	push xhl

	push xbc

	call	Free_Compare2

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

	ld xde, 0x20dfe



LyricsBox_DrawAndAdvance:
	call DrawString
	incw 1, (xsp + 8)
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
	cp xhl, TITLE_DPSMFLYR
	jr z, LyricsBox_DrawCurrentLine
	call GetTitleNow
	cp xhl, TITLE_DPMDLYSMFLYR
	jrl nz, LyricsBox_UpdateCursors46

LyricsBox_DrawCurrentLine:
	lda xbc, (xsp + 40)

	ld xwa, (xsp + 48)

	call	GetClientBox

	lda xwa, (xsp + 40)

	incw 2, (xwa)

	incw 4, (xwa + 2)

	decm 1, (xwa + 4)

	decm 2, (xwa + 6)

	lda xwa, (0x020e46:24)

	ld bc, (0x020e4a:24)

	sub bc, (xwa)

	inc 1, bc

	ld (xsp + 10), bc

	pushm (xsp + 10)

	ld bc, (xwa + 2)

	sla bc, 6

	add bc, (xwa)

	lda xwa, (0x020cbe:24)

	lda	xwa, (xwa+bc)

	push xwa

	pushw 0x2

	pushw 0xdfe

	call	CmpNamingCheck_Helper

	lda xsp, (xsp + 10)

	ld wa, (xsp + 10)

	extz xwa

	lda xde, (0x020dfe:24)

	ld xbc, xde

	add xbc, xwa

	ld (xbc), 0x0

	lda xwa, (xsp + 40)

	lda xhl, (0x020e46:24)

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

	call	DrawString



LyricsBox_UpdateCursors46:
	ld xbc, 0x20e46
	ld xwa, 0x20e4a
	jrl LyricsBox_StoreCursorPos

LyricsBox_HandleEventC:
	ld xwa, (xsp + 48)
	ld xde, xiz
	call InheritedProc
	ld xwa, (xsp + 48)
	call GetViewInstance
	ld (xsp + 12), xhl
	call GetTitleNow
	cp xhl, TITLE_DPSMFLYR
	jr z, LyricsBox_DrawSelLine
	call GetTitleNow
	cp xhl, TITLE_DPMDLYSMFLYR
	jrl nz, LyricsBox_UpdateCursors3E

LyricsBox_DrawSelLine:
	lda xbc, (xsp + 40)

	ld xwa, (xsp + 48)

	call	GetClientBox

	lda xwa, (xsp + 40)

	incw 2, (xwa)

	incw 4, (xwa + 2)

	decm 1, (xwa + 4)

	decm 2, (xwa + 6)

	lda xwa, (0x020e3e:24)

	ld bc, (0x020e42:24)

	sub bc, (xwa)

	ld (xsp + 10), bc

	pushm (xsp + 10)

	ld bc, (xwa + 2)

	sla bc, 6

	add bc, (xwa)

	lda xwa, (0x020cbe:24)

	lda	xwa, (xwa+bc)

	push xwa

	pushw 0x2

	pushw 0xdfe

	call	CmpNamingCheck_Helper

	lda xsp, (xsp + 10)

	ld wa, (xsp + 10)

	extz xwa

	lda xde, (0x020dfe:24)

	ld xbc, xde

	add xbc, xwa

	ld (xbc), 0x0

	lda xwa, (xsp + 40)

	lda xhl, (0x020e3e:24)

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

	call	DrawString



LyricsBox_UpdateCursors3E:
	ld xbc, 0x20e3e
	ld xwa, 0x20e42

LyricsBox_StoreCursorPos:
	ld wa, (xwa)
	ld (xbc), wa
	jr SongEdit_ReturnZero

LyricsBox_HandleEventD:
	ld xwa, (xsp + 48)
	ld xde, xiz
	call InheritedProc
	call GetTitleNow
	cp xhl, TITLE_DPSMFLYR
	jr z, LyricsBox_ScrollAndDraw
	call GetTitleNow
	cp xhl, TITLE_DPMDLYSMFLYR
	jr nz, SongEdit_ReturnZero

LyricsBox_ScrollAndDraw:
	lda xbc, (xsp + 40)
	ld xwa, (xsp + 48)
	call GetClientBox
	lda xiz, (xsp + 40)
	incw 2, (xiz)
	lda xhl, (xiz + 2)
	incw 4, (xhl)
	decm 1, (xiz + 4)
	decm 2, (xiz + 6)
	lda xiy, (xsp + 40)
	lda xix, (xsp + 32)
	ld bc, 4:i3
	ldirw
	lda xwa, (xsp + 32)
	addiw_da (xwa + 2), 0x12
	lda xde, (xsp + 16)
	ld bc, (xiz)
	ld (xde), bc
	ld bc, (xhl)
	ld (xde + 2), bc
	lda xiy, (xsp + 40)
	lda xix, (xsp + 24)
	ld bc, 4:i3
	ldirw
	lda xhl, (xsp + 24)
	ld bc, (xhl + 6)
	sub bc, 0x12
	ld (xhl + 2), bc
	ld xbc, xde
	call MovePixels
	lda xwa, (xsp + 24)
	ld bc, 7:i3
	call DrawBox

SongEdit_ReturnZero:
	ld xhl, 0:i3

LyricsBox_Epilogue:
	pop xiz
	lda xsp, (xsp + 48)
	ret

SongEdit_CheckBounds:
	dec 2,XSP
	ld (XSP),A
	lda xix, (0x020e4a:24)
	ld A,(XSP)
	extz WA
	add WA,(XIX)
	lda xbc, (0x020cbe:24)
	lda xde, (xix + 0x02)
	cp WA,0x0022
	jr ge, SongEdit_OverflowCheck
	ld A,(XSP)
	inc 1,A
	extz WA
	pushw wa
	pushw 0x0002
	pushw 0x0e4e
	ld WA,(XDE)
	sla WA, 0x06
	add WA,(XIX)
	exts XWA
	add XWA,XBC
	push XWA
	call CmpNamingCheck_Helper
	lda xsp, (xsp + 0x0a)
	lda xbc, (0x020e4a:24)
	ld A,(XSP)
	extz WA
	add WA,(XBC)
	ld (XBC),WA
	ld (0x020e4e:24), 0x00
	ld XWA,0x006f0027
	ld XBC,EVT_LYRICS_RENEW
	ld xde, 0:i3
	jrl t, SongEdit_SendAndReturnOK
SongEdit_OverflowCheck:
	ld xhl, xde

	ld wa, (xde)

	cp wa, 4:i3

	jrl ge, SongEdit_ReturnOverflow

	sla wa, 6

	add wa, (xix)

	ld	(xbc+wa), 0x0d

	ld wa, (xix)

	inc 1, wa

	ld (xix), wa

	ld wa, (xhl)

	sla wa, 6

	add wa, (xix)

	ld	(xbc+wa), 0x00

	ld wa, (xix)

	inc 1, wa

	ld (xix), wa

	ld xwa, 0x6f0027

	ld xbc, EVT_LYRICS_RENEW

	ld xde, 0:i3

	call	SendEvent

	lda xde, (0x020e46:24)

	lda xbc, (xde + 2)

	ld wa, (xbc)

	inc 1, wa

	ld (xbc), wa

	ldw (xde), 0x0

	lda xde, (0x020e4a:24)

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

	pushw 0xe4e

	ld bc, (xbc)

	sla bc, 6

	add bc, (xde)

	lda xwa, (0x020cbe:24)

	lda	xwa, (xwa+bc)

	push xwa

	call	CmpNamingCheck_Helper

	lda xsp, (xsp + 10)

	lda xbc, (0x020e4a:24)

	ld a, (xsp)

	extz wa

	add wa, (xbc)

	ld (xbc), wa

	ld (0x020e4e:24), 0x00

	ld xwa, 0x6f0027

	ld xbc, EVT_LYRICS_RENEW

	ld xde, 0:i3



SongEdit_SendAndReturnOK:
	call SendEvent
	ld l, 0x0:opc
	jr SongEdit_CheckBounds_Epilogue

SongEdit_ReturnOverflow:
	ld l, 0xff:opc

SongEdit_CheckBounds_Epilogue:
	inc 2, xsp
	ret

LyricsTrack_ReadAndParse:
	lda	xwa, (134734:24)
	call	SeqFile_ReadTrackData
	pushw	2
	pushw	3662
	call	Strlen
	inc	4, xsp
	cp	hl, 34
	jr	c, LyricsTrack_CheckEmpty
	ld	(134767:24), 0
LyricsTrack_CheckEmpty:
	lda xwa, (0x20e4e:24)
	cp (xwa), 0
	ret z
	push xwa
	call Strlen
	inc 4, xsp
	dec 1, hl
	extz xhl
	lda xwa, (0x20e4e:24)
	ld xde, xwa
	add xde, xhl
	ld c, (xde)
	push xwa
	cp c, 10
	jr z, LyricsTrack_HandleNewline
	cp c, 13
	jrl nz, LyricsTrack_HandleNormalChar
LyricsTrack_HandleNewline:
	call	Strlen
	inc	4, xsp
	cp	l, 1:i3
	jr	z, LyricsTrack_HandleSingleChar
	pushw	2
	pushw	3662
	call	Strlen
	inc	4, xsp
	extz	hl
	ld	wa, hl
	jr	LyricsTrack_JmpCheckBounds
LyricsTrack_HandleSingleChar:
	lda xde, (0x020e4a:24)
	lda xbc, (xde + 2)
	ld wa, (xbc)
	cp wa, 4:i3
	ret ge
	sla wa, 6
	add wa, (xde)
	lda xhl, (0x020cbe:24)
	ld	(xhl+wa), 0x0d
	ld wa, (xde)
	inc 1, wa
	ld (xde), wa
	ld wa, (xbc)
	sla wa, 6
	add wa, (xde)
	ld	(xhl+wa), 0x00
	ld wa, (xde)
	inc 1, wa
	ld (xde), wa
	ld xwa, 0x6f0027
	ld xbc, EVT_LYRICS_RENEW
	ld xde, 0:i3
	call SendEvent
	lda xde, (0x020e46:24)
	lda xbc, (xde + 2)
	ld wa, (xbc)
	inc 1, wa
	ld (xbc), wa
	ldw (xde), 0x0
	lda xde, (0x020e4a:24)
	lda xbc, (xde + 2)
	ld wa, (xbc)
	inc 1, wa
	ld (xbc), wa
	ldw (xde), 0x0
	ld (0x020e4e:24), 0x00
	ret

LyricsTrack_HandleNormalChar:
	call	Strlen
	inc	4, xsp
	extz	hl
	ld	wa, hl
LyricsTrack_JmpCheckBounds:
	jrl SongEdit_CheckBounds

LyricsTrack_ResetAllBuffers:
	pushw iz
	ld iz, 0:i3

LyricsTrack_ResetBufferLoop:
	pushw 0x40

	ld bc, iz

	sla bc, 6

	ld de, bc

	add de, 0x40

	lda xwa, (0x020cbe:24)

	exts xde

	add xde, xwa

	push xde

	lda	xwa, (xwa+bc)

	push xwa

	call	Mem_Copy

	lda xsp, (xsp + 10)

	ld bc, iz

	sla bc, 6

	lda xwa, (0x020cfe:24)

	exts xbc

	add xbc, xwa

	ld xwa, xbc

	lda xbc, (xbc + 64)



LyricsTrack_ZeroFillLoop:
	ld (xwa+), 0x00
	cp xwa, xbc
	jr c, LyricsTrack_ZeroFillLoop
	inc 1, iz
	ld wa, iz
	inc 1, wa
	cp wa, 4:i3
	jr le, LyricsTrack_ResetBufferLoop
	lda xwa, (0x020e3e:24)
	ldw (xwa + 2), 0x2
	ldw (xwa), 0x0
	lda xwa, (0x020e42:24)
	ldw (xwa + 2), 0x2
	ldw (xwa), 0x0
	lda xbc, (0x020e48:24)
	ld wa, (xbc)
	dec 1, wa
	ld (xbc), wa
	lda xbc, (0x020e4c:24)
	ld wa, (xbc)
	dec 1, wa
	ld (xbc), wa
	ld xwa, 0x6f0027
	ld xbc, EVT_LYRICS_SCROLL_UP
	ld xde, 0:i3
	call SendEvent
	ld xwa, NAKA_MAINFUNC_MiddleFuncCall
	ld xbc, EVT_LYRICS_CHARA_REQ
	ld xde, 0:i3
	call MainFuncCall
	popw iz
	ret

LyricsFile_ValidateAndInsert:
	pushw	iz
	ld	xwa, 134990
	call	SeqFile_ValidateAndStore
	pushw	2
	pushw	3918
	call	Strlen
	inc	4, xsp
	cp	hl, 34
	jr	c, LyricsFile_CheckFirstByte
	ld	(135023:24), 0
LyricsFile_CheckFirstByte:
	ld e, (0x020f4e:24)
	cp e, 0:i3
	jrl z, LyricsBox_PopIzRet
	lda xhl, (0x020cbe:24)
	cp e, 0xd
	jr nz, LyricsFile_CheckLinefeed
	lda xbc, (0x020e42:24)
	ld de, (xbc + 2)
	sla de, 6
	add de, (xbc)
	cp	(xhl+de), 0x0d
	jrl z, LyricsFile_ResetBuffers
	jrl LyricsBox_PopIzRet

LyricsFile_CheckLinefeed:
	lda xbc, (0x020e42:24)
	ld wa, (xbc + 2)
	sla wa, 6
	cp e, 0xa
	jr nz, LyricsFile_InsertNormalChar
	add wa, (xbc)
	cp	(xhl+wa), 0x0d
	jr z, LyricsFile_ResetBuffers
	jr LyricsBox_PopIzRet

LyricsFile_InsertNormalChar:
	add wa, (xbc)
	cp	(xhl+wa), 0x0d
	call z, (LyricsTrack_ResetAllBuffers:24)
	pushw 0x0002
	pushw 0x0f4e
	call Strlen
	ld iz, hl
	pushw iz
	pushw 0x0002
	pushw 0x0f4e
	lda xwa, (0x20e42:24)
	ld bc, (xwa+2)
	sla bc, 6
	add bc, (xwa)
	lda xwa, (0x20cbe:24)
	lda	xwa, (xwa+bc)
	push xwa
	call CmpNamingCheck_Helper
	lda xsp, (xsp+14)
	lda xwa, (0x20e42:24)
	ld bc, iz
	add bc, (xwa)
	ld (xwa), bc
	ld xwa, 0x006f0027
	ld xbc, EVT_LYRICS_REVERSE
	ld xde, 0:i3
	call SendEvent
	call UpdateScreen
	lda xwa, (0x20e42:24)
	ld bc, (xwa+2)
	sla bc, 6
	add bc, (xwa)
	lda xwa, (0x20cbe:24)
	cp	(xwa+bc), 0x0d
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
	cp xbc, EVT_LYRICS_CHANGE_COLOR
	jrl z, LyricsBoxFunc_ValidateFile
	lda xwa, (0x020e4e:24)
	cp xbc, EVT_LYRICS_GET_EVENT
	jrl z, LyricsBoxFunc_HandleInput
	cp xbc, EVT_LYRICS_PLAY_REQUEST
	jr z, LyricsBoxFunc_SendEvent12
	cp xbc, EVT_LYRICS_PLAY_START_INI
	jr z, LyricsBoxFunc_ResetCursors
	cp xbc, EVT_GET_STRING
	jr z, LyricsBoxFunc_CopyString
	cp xbc, EVT_DRAW
	jrl nz, LyricsBoxFunc_InheritedProc
	ld xwa, xiz
	call InheritedProc
	ld xwa, xiz
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	jr LyricsBoxFunc_SendAndReturn

LyricsBoxFunc_CopyString:
	pushw	NakaT1_Str021A4@hi16
	pushw	NakaT1_Str021A4@lo16
	push	xde
	call	Free_Compare2
	inc	8, xsp
	jrl	SongName_ReturnZeroJmp
LyricsBoxFunc_ResetCursors:
	lda xbc, (0x020e3e:24)
	ldw (xbc), 0x0
	ldw (xbc + 2), 0x2
	lda xbc, (0x020e42:24)
	ldw (xbc), 0x0
	ldw (xbc + 2), 0x2
	lda xbc, (0x020e46:24)
	ldw (xbc), 0x0
	ldw (xbc + 2), 0x2
	lda xbc, (0x020e4a:24)
	ldw (xbc), 0x0
	ldw (xbc + 2), 0x2
	ld (xwa), 0x0
	ld (0x020f4e:24), 0x00
	jrl SongName_ReturnZeroJmp

LyricsBoxFunc_SendEvent12:
	ld xwa, 0x720006
	ld xbc, EVT_LYRICS_GET_EVENT
	ld xde, 0:i3

LyricsBoxFunc_SendAndReturn:
	call SendEvent
	jrl SongName_ReturnZeroJmp

LyricsBoxFunc_HandleInput:
	ld XBC,XWA
	cp (XWA),0x00
	jrl z, LyricsBoxFunc_ReadTrack
	push XBC
	call Strlen
	inc 4,XSP
	dec 1,HL
	extz XHL
	lda xwa, (0x020e4e:24)
	ld XDE,XWA
	add XDE,XHL
	ld C,(XDE)
	push XWA
	cp C,0x0a
	jr z, LyricsBoxFunc_HandleNewline
	cp C,0x0d
	jrl nz, LyricsBoxFunc_HandleNormalChar
LyricsBoxFunc_HandleNewline:
	call	Strlen
	inc	4, xsp
	cp	l, 1:i3
	jr	z, LyricsBoxFunc_HandleSingleChar
	pushw	2
	pushw	3662
	call	Strlen
	inc	4, xsp
	extz	hl
	ld	wa, hl
	calr	SongEdit_CheckBounds
	cp	l, 255
	jrl	z, SongName_ReturnZeroJmp
	ld	xwa, 7274535
	ld	xbc, EVT_LYRICS_RENEW
	ld	xde, 0:i3
	jrl	LyricsBoxFunc_SendEventB
LyricsBoxFunc_HandleSingleChar:
	lda xde, (0x020e4a:24)
	lda xbc, (xde + 2)
	ld wa, (xbc)
	cp wa, 4:i3
	jrl ge, SongName_ReturnZeroJmp
	sla wa, 6
	add wa, (xde)
	lda xhl, (0x020cbe:24)
	ld	(xhl+wa), 0x0d
	ld wa, (xde)
	inc 1, wa
	ld (xde), wa
	ld wa, (xbc)
	sla wa, 6
	add wa, (xde)
	ld	(xhl+wa), 0x00
	ld wa, (xde)
	inc 1, wa
	ld (xde), wa
	ld xwa, 0x6f0027
	ld xbc, EVT_LYRICS_RENEW
	ld xde, 0:i3
	call SendEvent
	lda xde, (0x020e46:24)
	lda xbc, (xde + 2)
	ld wa, (xbc)
	inc 1, wa
	ld (xbc), wa
	ldw (xde), 0x0
	lda xde, (0x020e4a:24)
	lda xbc, (xde + 2)
	ld wa, (xbc)
	inc 1, wa
	ld (xbc), wa
	ldw (xde), 0x0
	ld (0x020e4e:24), 0x00
	jr LyricsBoxFunc_ReadTrack

LyricsBoxFunc_HandleNormalChar:
	call	Strlen
	inc	4, xsp
	extz	hl
	ld	wa, hl
	calr	SongEdit_CheckBounds
	cp	l, 255
	jr	z, SongName_ReturnZeroJmp
	ld	xwa, 7274535
	ld	xbc, EVT_LYRICS_RENEW
	ld	xde, 0:i3
LyricsBoxFunc_SendEventB:
	call SendEvent

LyricsBoxFunc_ReadTrack:
	ld wa, 0:i3
	calr LyricsTrack_ReadAndParse
	jr SongName_ReturnZeroJmp

LyricsBoxFunc_ValidateFile:
	calr LyricsFile_ValidateAndInsert

SongName_ReturnZeroJmp:
	ld xhl, 0:i3
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
	cp xiz, EVT_SONG_WRITE
	jr z, SongNameBox_HandleEventF
	cp xiz, EVT_LYRICS_ALL_CLEAR
	jr z, SongNameBox_HandleEvent9
	cp xiz, EVT_REPAINT
	jr z, SongNameBox_HandleFocusGained
	cp xiz, EVT_PAINT
	jr z, SongNameBox_HandleFocusGained
	cp xiz, EVT_HIDE
	jr z, SongNameBox_HandleSize
	cp xiz, EVT_SHOW
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
	ld xwa, NAKA_MAINFUNC_NameGetFuncCall
	ld xbc, EVT_GET_LYRICS_SONG_NAME
	ld xde, 0:i3
	call MainFuncCall
	jr DrawStringCenter_RetZero2

SongNameBox_HandleEvent9:
	ld xwa, (xsp + 24)
	ld xbc, EVT_DRAW
	ld xde, (xsp + 20)
	call SendEvent
	jr DrawStringCenter_RetZero2

SongNameBox_HandleEventF:
	ld xwa, (xsp + 24)
	ld xbc, EVT_DRAW
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
	pushw 0xf7
	ld xde, 0x2104e
	call DrawStringCentered

DrawStringCenter_RetZero2:
	ld xhl, 0:i3
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
	cp xiz, EVT_COMPOSER_WRITE
	jr z, ComposerBox_HandleEventE
	cp xiz, EVT_LYRICS_ALL_CLEAR
	jr z, ComposerBox_HandleEvent9
	cp xiz, EVT_REPAINT
	jr z, SongNameBox2_HandleFocusGained
	cp xiz, EVT_PAINT
	jr z, SongNameBox2_HandleFocusGained
	cp xiz, EVT_HIDE
	jr z, ComposerBox_HandleSize
	cp xiz, EVT_SHOW
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
	ld xwa, NAKA_MAINFUNC_NameGetFuncCall
	ld xbc, EVT_GET_COMPOSER_NAME
	ld xde, 0:i3
	call MainFuncCall
	jr DrawStringCentered_RetZero

ComposerBox_HandleEvent9:
	ld xwa, (xsp + 24)
	ld xbc, EVT_DRAW
	ld xde, (xsp + 20)
	call SendEvent
	jr DrawStringCentered_RetZero

ComposerBox_HandleEventE:
	ld xwa, (xsp + 24)
	ld xbc, EVT_DRAW
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
	pushw 0xf7
	ld xde, 0x21064
	call DrawStringCentered

DrawStringCentered_RetZero:
	ld xhl, 0:i3
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
	cp xiz, EVT_PARA_DRAW
	jr z, MeasureBox_HandleEventF
	cp xiz, EVT_PAINT
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
	ld xwa, NAKA_MAINFUNC_ApPlaySyori_Yoko
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
	ldw (xhl), 0x6c
	lda xbc, (xhl + 2)
	ldw (xbc), 0x56
	lda xwa, (xhl + 4)
	ldw (xwa), 0xd8
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
	ld xbc, EVT_GET_RAM_ADDRESS
	ld xde, (xsp + 58)
	call ApFuncCall
	lda xde, (xsp + 8)
	ld (xde), xhl
	lda xhl, (xsp + 30)
	ld xwa, xhl
	lda xbc, (xhl + 16)

MeasureBox_ZeroFillLoop:
	ld (xwa+), 0x00
	cp xwa, xbc
	jr c, MeasureBox_ZeroFillLoop
	ld (xde + 18), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 26)
	ld xbc, EVT_GET_MEAS_STRING
	call ApFuncCall
	lda xwa, (xsp + 50)
	lda xbc, (xsp + 46)
	lda xde, (xsp + 30)
	ld xhl, 0:i3
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify

MeasureBox_ReturnZero:
	ld xhl, 0:i3

MeasureBox_Epilogue:
	pop xiz
	lda xsp, (xsp + 62)
	ret

MeasureBoxFunc:
	push xiz
	ld xiz, xwa
	cp xbc, EVT_GET_RAM_ADDRESS
	jr z, MeasureBoxFunc_LoadAddr
	cp xbc, EVT_GET_MEAS_STRING
	jr z, MeasureBoxFunc_DrawMeasure
	ld xhl, 0:i3
	jr MeasureBoxFunc_Epilogue

MeasureBoxFunc_DrawMeasure:
	pushm (0x2668:16)
	pushw MeasureBoxFunc_DrawMeasure_Str_MEASURE_Fmt3d@hi16
	pushw MeasureBoxFunc_DrawMeasure_Str_MEASURE_Fmt3d@lo16
	ld xwa, (xde+18)
	push xwa
	call Sprintf_Locked
	lda xsp, (xsp+10)
	ld xhl, xiz
	jr MeasureBoxFunc_Epilogue
MeasureBoxFunc_LoadAddr:
	lda xhl, (9832:16)

MeasureBoxFunc_Epilogue:
	pop xiz
	ret
MeasureBoxFunc_End:

AcDiskFileNameBoxProc:
	lda xsp, (xsp-256)
	push xiz
	ld xiz, xwa
	cp xbc, EVT_DISK_FILE_NAME
	jr z, AcDiskFileName_HandleEventF
	cp xbc, EVT_REPAINT
	jr z, AcDiskFileName_HandleFocusGained
	cp xbc, EVT_PAINT
	jr z, AcDiskFileName_HandleFocusGained
	cp xbc, EVT_HIDE
	jr z, AcDiskFileName_HandleEvent1
	cp xbc, EVT_SHOW
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
	ld xwa, NAKA_MAINFUNC_NameGetFuncCall
	ld xbc, EVT_GET_DISK_FILE_NAME
	ld xde, 0:i3
	call MainFuncCall
	jr AcDiskFileName_ReturnZero

AcDiskFileName_HandleEventF:
	ld	xwa, xiz
	call	InheritedProc
	pushw	AcDiskFileName_HandleEventF_Str_Blank25@hi16
	pushw	AcDiskFileName_HandleEventF_Str_Blank25@lo16
	lda	xwa, (xsp+8)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	lda	xde, (xsp+4)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	SendEvent
	pushw	0
	pushw	7270
	lda	xwa, (xsp+8)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	lda	xde, (xsp+4)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	SendEvent
AcDiskFileName_ReturnZero:
	ld xhl, 0:i3

AcDiskFileName_Epilogue:
	pop xiz
	lda xsp, (xsp+256)
	ret
AcDiskFileName_End:

AcSmfFileNameBoxProc:
	lda xsp, (xsp-256)
	push xiz
	ld xiz, xwa
	cp xbc, EVT_SMF_FILE_NAME
	jr z, AcSmfFileName_HandleEventF
	cp xbc, EVT_REPAINT
	jr z, AcSmfFileName_HandleFocusGained
	cp xbc, EVT_PAINT
	jr z, AcSmfFileName_HandleFocusGained
	cp xbc, EVT_HIDE
	jr z, AcSmfFileName_HandleEvent1
	cp xbc, EVT_SHOW
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
	ld xwa, NAKA_MAINFUNC_NameGetFuncCall
	ld xbc, EVT_GET_SMF_FILE_NAME
	ld xde, 0:i3
	call MainFuncCall
	jr AcSmfFileName_ReturnZero

AcSmfFileName_HandleEventF:
	ld	xwa, xiz
	call	InheritedProc
	pushw	AcSmfFileName_HandleEventF_Str_Blank25@hi16
	pushw	AcSmfFileName_HandleEventF_Str_Blank25@lo16
	lda	xwa, (xsp+8)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	lda	xde, (xsp+4)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	SendEvent
	pushw	0
	pushw	7284
	lda	xwa, (xsp+8)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	lda	xde, (xsp+4)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	SendEvent
AcSmfFileName_ReturnZero:
	ld xhl, 0:i3

AcSmfFileName_Epilogue:
	pop xiz
	lda xsp, (xsp+256)
	ret
AcSmfFileName_End:

AcSmfSongNameBoxProc:
	lda xsp, (xsp-256)
	push xiz
	ld xiz, xwa
	cp xbc, EVT_SMF_SONG_NAME
	jr z, AcSmfSongName_HandleEventF
	cp xbc, EVT_REPAINT
	jr z, AcSmfSongName_HandleFocusGained
	cp xbc, EVT_PAINT
	jr z, AcSmfSongName_HandleFocusGained
	cp xbc, EVT_HIDE
	jr z, AcSmfSongName_HandleEvent1
	cp xbc, EVT_SHOW
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
	ld xwa, NAKA_MAINFUNC_NameGetFuncCall
	ld xbc, EVT_GET_SMF_SONG_NAME
	ld xde, 0:i3
	call MainFuncCall
	jr AcSmfSongName_ReturnZero

AcSmfSongName_HandleEventF:
	ld	xwa, xiz
	call	InheritedProc
	pushw	AcSmfSongName_HandleEventF_Str_Blank25@hi16
	pushw	AcSmfSongName_HandleEventF_Str_Blank25@lo16
	lda	xwa, (xsp+8)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	lda	xde, (xsp+4)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	SendEvent
	pushw	0
	pushw	7304
	lda	xwa, (xsp+8)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	lda	xde, (xsp+4)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	SendEvent
AcSmfSongName_ReturnZero:
	ld xhl, 0:i3

AcSmfSongName_Epilogue:
	pop xiz
	lda xsp, (xsp+256)
	ret
AcSmfSongName_End:

AcDocSongNameBoxProc:
	lda xsp, (xsp-256)
	push xiz
	ld xiz, xwa
	cp xbc, EVT_DOC_SONG_NAME
	jr z, AcDocSongName_HandleEventF
	cp xbc, EVT_REPAINT
	jr z, AcDocSongName_HandleFocusGained
	cp xbc, EVT_PAINT
	jr z, AcDocSongName_HandleFocusGained
	cp xbc, EVT_HIDE
	jr z, AcDocSongName_HandleEvent1
	cp xbc, EVT_SHOW
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
	ld xwa, NAKA_MAINFUNC_NameGetFuncCall
	ld xbc, EVT_GET_DOC_SONG_NAME
	ld xde, 0:i3
	call MainFuncCall
	jr AcDocSongName_ReturnZero

AcDocSongName_HandleEventF:
	ld	xwa, xiz
	call	InheritedProc
	pushw	AcDocSongName_HandleEventF_Str_Blank25@hi16
	pushw	AcDocSongName_HandleEventF_Str_Blank25@lo16
	lda	xwa, (xsp+8)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	lda	xde, (xsp+4)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	SendEvent
	pushw	0
	pushw	7326
	lda	xwa, (xsp+8)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	lda	xde, (xsp+4)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	SendEvent
AcDocSongName_ReturnZero:
	ld xhl, 0:i3

AcDocSongName_Epilogue:
	pop xiz
	lda xsp, (xsp+256)
	ret
AcDocSongName_End:

AcDocFileNoBoxProc:
	lda xsp, (xsp-256)
	push xiz
	ld xiz, xwa
	cp xbc, EVT_DOC_FILE_NO
	jr z, AcDocFileNo_HandleEventF
	cp xbc, EVT_REPAINT
	jr z, AcDocFileNo_HandleFocusGained
	cp xbc, EVT_PAINT
	jr z, AcDocFileNo_HandleFocusGained
	cp xbc, EVT_HIDE
	jr z, AcDocFileNo_HandleEvent1
	cp xbc, EVT_SHOW
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
	ld xwa, NAKA_MAINFUNC_NameGetFuncCall
	ld xbc, EVT_GET_DOC_FILE_NO
	ld xde, 0:i3
	call MainFuncCall
	jr AcDocFileNo_ReturnZero

AcDocFileNo_HandleEventF:
	ld	xwa, xiz
	call	InheritedProc
	pushw	AcDocFileNo_HandleEventF_Str_Blank25@hi16
	pushw	AcDocFileNo_HandleEventF_Str_Blank25@lo16
	lda	xwa, (xsp+8)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	lda	xde, (xsp+4)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	SendEvent
	pushw	0
	pushw	7362
	lda	xwa, (xsp+8)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	lda	xde, (xsp+4)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	SendEvent
AcDocFileNo_ReturnZero:
	ld xhl, 0:i3

AcDocFileNo_Epilogue:
	pop xiz
	lda xsp, (xsp+256)
	ret
AcDocFileNo_End:

AcPDSongNameBoxProc:
	lda xsp, (xsp-256)
	push xiz
	ld xiz, xwa
	cp xbc, EVT_PD_SONG_NAME
	jr z, AcPDSongName_HandleEventF
	cp xbc, EVT_REPAINT
	jr z, AcPDSongName_HandleFocusGained
	cp xbc, EVT_PAINT
	jr z, AcPDSongName_HandleFocusGained
	cp xbc, EVT_HIDE
	jr z, AcPDSongName_HandleEvent1
	cp xbc, EVT_SHOW
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
	ld xwa, NAKA_MAINFUNC_NameGetFuncCall
	ld xbc, EVT_GET_PD_SONG_NAME
	ld xde, 0:i3
	call MainFuncCall
	jr AcPDSongName_ReturnZero

AcPDSongName_HandleEventF:
	ld	xwa, xiz
	call	InheritedProc
	pushw	AcPDSongName_HandleEventF_Str_Blank25@hi16
	pushw	AcPDSongName_HandleEventF_Str_Blank25@lo16
	lda	xwa, (xsp+8)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	lda	xde, (xsp+4)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	SendEvent
	pushw	0
	pushw	7340
	lda	xwa, (xsp+8)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	lda	xde, (xsp+4)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	SendEvent
AcPDSongName_ReturnZero:
	ld xhl, 0:i3

AcPDSongName_Epilogue:
	pop xiz
	lda xsp, (xsp+256)
	ret
AcPDSongName_End:

AcPDFileNoBoxProc:
	lda xsp, (xsp-256)
	push xiz
	ld xiz, xwa
	cp xbc, EVT_PD_FILE_NO
	jr z, AcPDFileNo_HandleEventF
	cp xbc, EVT_REPAINT
	jr z, AcPDFileNo_HandleFocusGained
	cp xbc, EVT_PAINT
	jr z, AcPDFileNo_HandleFocusGained
	cp xbc, EVT_HIDE
	jr z, AcPDFileNo_HandleEvent1
	cp xbc, EVT_SHOW
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
	ld xwa, NAKA_MAINFUNC_NameGetFuncCall
	ld xbc, EVT_GET_PD_FILE_NO
	ld xde, 0:i3
	call MainFuncCall
	jr AcPDFileNo_ReturnZero

AcPDFileNo_HandleEventF:
	ld	xwa, xiz
	call	InheritedProc
	pushw	AcPDFileNo_HandleEventF_Str_Blank25@hi16
	pushw	AcPDFileNo_HandleEventF_Str_Blank25@lo16
	lda	xwa, (xsp+8)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	lda	xde, (xsp+4)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	SendEvent
	pushw	0
	pushw	7366
	lda	xwa, (xsp+8)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	lda	xde, (xsp+4)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	SendEvent
AcPDFileNo_ReturnZero:
	ld xhl, 0:i3

AcPDFileNo_Epilogue:
	pop xiz
	lda xsp, (xsp+256)
	ret

IvNamingExitProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, EVT_SW_IN
	jr z, IvNamingExit_ReturnZero
	cp xiz, EVT_GET_STRING
	jr z, IvNamingExit_CopyString
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	jr IvNamingExit_CallInherited

IvNamingExit_CopyString:
	pushw	IvNamingExit_CopyString_Str_ExMD@hi16
	pushw	IvNamingExit_CopyString_Str_ExMD@lo16
	ld	xwa, (xsp+8)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	ld	xhl, 0:i3
	jr	IvNamingExit_Epilogue
IvNamingExit_ReturnZero:
	ld xwa, (xsp + 8)
	ld xbc, EVT_CHECK_EDIT_SW
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jr z, IvNamingExit_ForwardEvent
	call GetTitleNow
	cp xhl, TITLE_SQSNGNAME
	jr nz, IvNamingExit_CheckTitleA7
	ld xwa, 0xffffffff
	ld xbc, EVT_CHANGE_TITLE
	ld xde, TITLE_SQSNGSEL
	jr IvNamingExit_PostTitleEvent

IvNamingExit_CheckTitleA7:
	call GetTitleNow
	cp xhl, TITLE_SQEASYNAME
	jr nz, IvNamingExit_ForwardEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_CHANGE_TITLE
	ld xde, TITLE_SQEASYREC

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
	lda	xsp, (xsp-178)
	push	xiz
	ld	(xsp+170), xde
	ld	(xsp+174), xbc
	ld	(xsp+178), xwa
	ld	xwa, (xsp+174)
	cp	xwa, EVT_INDEXSW_DOWN
	jrl	z, IvNamingExit_ScreenData_Skip5
	cp	xwa, EVT_INDEXSW_UP
	jrl	z, IvNamingExit_ScreenData_Skip5
	cp	xwa, EVT_SET_SELECTED_FILE_NUM
	jrl	z, IvNamingExit_ScreenData_Skip4
	cp	xwa, EVT_PARA_DRAW
	jrl	z, IvNamingExit_ScreenData_Skip2
	cp	xwa, EVT_PAINT
	jr	z, IvNamingExit_ScreenData_Skip
	cp	xwa, EVT_SHOW
	jrl	nz, IvNamingExit_ScreenData_Skip6
	ld	xwa, (xsp+178)
	ld	xbc, (xsp+174)
	ld	xde, (xsp+170)
	call	InheritedProc
	ld	xwa, (xsp+178)
	call	GetViewInstance
	ld	xiz, xhl
	ld	xde, (xsp+178)
	ld	xwa, (xiz+34)
	ld	xbc, EVT_PS_SONG_SEL_BOX_ID
	call	MainFuncCall
	cpw (xiz+46), 0
	jrl	z, IvNamingExit_ScreenData_Join3
	ld	xwa, (xsp+178)
	ld	xbc, EVT_INDEXSW_DOWN
	ld	xde, 0:i3
	call	SetDialUp
	ld	xwa, (xsp+178)
	ld	xbc, EVT_INDEXSW_UP
	ld	xde, 0:i3
	call	SetDialDown
	ld	wa, 1:i3
	call	SetDialEnable
	jrl	IvNamingExit_ScreenData_Join3
IvNamingExit_ScreenData_Skip:
	ld	xwa, (xsp+178)
	ld	xbc, (xsp+174)
	ld	xde, (xsp+170)
	call	InheritedProc
	ld	xwa, (xsp+178)
	call	GetViewInstance
	ld	(xsp+22), xhl
	ld	xwa, (xsp+22)
	ld	xwa, (xwa+34)
	ld	xbc, (xsp+174)
	ld	xde, (xsp+170)
	call	MainFuncCall
	ld	xwa, (xsp+22)
	cpw (xwa+38), 2
	jrl	lt, IvNamingExit_ScreenData_Join3
	lda	xbc, (xsp+154)
	ld	xwa, (xsp+178)
	call	GetClientBox
	lda	xde, (xsp+154)
	ld	bc, (xde+4)
	sub bc, (xde)
	exts	xbc
	ld	xwa, (xsp+22)
	divs xbc, (xwa+38)
	ld	(xsp+8), bc
	ld	wa, (xde+2)
	inc	1, wa
	ld	(xsp+168), wa
	ld	wa, (xde+6)
	dec	1, wa
	ld	(xsp+164), wa
	ldw	(xsp+20), 1
	jr	IvNamingExit_ScreenData_Join
IvNamingExit_ScreenData_Loop:
	ld	wa, (xsp+8)
	mul xwa, (xsp+20)
	ld	bc, (xsp+154)
	add	bc, wa
	dec	1, bc
	lda	xwa, (xsp+166)
	ld	(xwa), bc
	lda	xbc, (xsp+162)
	ld	de, (xwa)
	ld	(xbc), de
	ld	de, 7:i3
	call	DrawLine
	incw	1, (xsp+20)
IvNamingExit_ScreenData_Join:
	ld	xwa, (xsp+22)
	ld	wa, (xwa+38)
	cp	(xsp+20), wa
	jr	c, IvNamingExit_ScreenData_Loop
	jrl	IvNamingExit_ScreenData_Join3
IvNamingExit_ScreenData_Skip2:
	ld	xwa, (xsp+178)
	ld	xbc, (xsp+174)
	ld	xde, (xsp+170)
	call	InheritedProc
	ld	xwa, (xsp+178)
	call	GetViewInstance
	ld	(xsp+10), xhl
	ld	xwa, (xsp+10)
	ld	(xsp+4), xwa
	ld	xde, (xsp+170)
	or	xde, xde
	jrl	z, IvNamingExit_ScreenData_Skip4
	ld	bc, (xwa+38)
	muls xbc, (xwa+40)
	ld	a, (xde)
	exts	wa
	cp	wa, bc
	jrl	ge, IvNamingExit_ScreenData_Skip4
	lda	xbc, (xsp+154)
	ld	xwa, (xsp+178)
	call	GetClientBox
	lda	xbc, (xsp+154)
	lda	xwa, (xbc+4)
	ld	(xsp+18), xwa
	ld	de, (xwa)
	sub de, (xbc)
	exts	xde
	ld	xhl, (xsp+10)
	divs xde, (xhl+38)
	ld	(xsp+8), de
	lda	xwa, (xbc+6)
	ld	(xsp+14), xwa
	lda	xwa, (xbc+2)
	ld	(xsp+22), xwa
	ld	de, (xwa)
	ld	xwa, (xsp+14)
	ld	ix, (xwa)
	sub	ix, de
	ld	hl, (xhl+40)
	exts	xix
	divs	xix, hl
	ld	xwa, (xsp+170)
	ld	a, (xwa)
	exts	wa
	exts	xwa
	divs	xwa, hl
	ld	iy, qwa
	ld	xwa, (xsp+170)
	ld	a, (xwa)
	exts	wa
	exts	xwa
	divs	xwa, hl
	ld	hl, wa
	ld	wa, ix
	mul	xwa, iy
	inc	2, wa
	add	de, wa
	ld	xiy, (xsp+22)
	ld	(xiy), de
	add	de, ix
	ld	xwa, (xsp+14)
	ld	(xwa), de
	ld	wa, (xsp+8)
	mul	xwa, hl
	inc	2, wa
	add	(xbc), wa
	ld	de, (xbc)
	add de, (xsp+8)
	ld	xwa, (xsp+18)
	ld	(xwa), de
	lda	xde, (xsp+166)
	ld	wa, (xbc)
	ld	(xde), wa
	ld	wa, (xiy)
	ld	(xde+2), wa
	ld	xwa, (xsp+170)
	inc	1, xwa
	push	xwa
	lda	xwa, (xsp+30)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	ld	xbc, (xsp+10)
	ld	xix, (xbc+42)
	ld	xwa, (xsp+170)
	ld	a, (xwa)
	ldfr_berp	a, 244
	exts	iy
	lda	xde, (xsp+26)
	lda	xhl, (xbc+28)
	lda	xbc, (xsp+166)
	lda	xwa, (xsp+154)
	cp iy, (xix)
	jr	nz, IvNamingExit_ScreenData_Skip3
	ld	xhl, (xhl)
	push	xhl
	pushw 0
	pushw 255
	jr	IvNamingExit_ScreenData_Join2
IvNamingExit_ScreenData_Skip3:
	ld	xhl, (xhl)
	push	xhl
	ld	xhl, (xsp+14)
	pushm (xhl+32)
	ld	xhl, (xsp+10)
	pushm (xhl+22)
IvNamingExit_ScreenData_Join2:
	call	DrawString
IvNamingExit_ScreenData_Skip4:
	ld	xwa, (xsp+178)
	call	GetViewInstance
	ld	wa, (xhl+38)
	muls xwa, (xhl+40)
	exts	xwa
	cp	(xsp+170), xwa
	jr	nc, IvNamingExit_ScreenData_Join3
	ld	xbc, (xhl+42)
	ld	xwa, (xsp+170)
	ld	(xbc), wa
	jr	IvNamingExit_ScreenData_Join3
IvNamingExit_ScreenData_Skip5:
	ld	xwa, (xsp+178)
	ld	xbc, (xsp+174)
	ld	xde, (xsp+170)
	call	InheritedProc
	ld	xwa, (xsp+178)
	call	GetViewInstance
	ld	xiz, xhl
	ld	xwa, (xiz+34)
	ld	xbc, (xsp+174)
	ld	xde, (xsp+170)
	call	MainFuncCall
	cpw (xiz+48), 0
	jr	z, IvNamingExit_ScreenData_Join3
	ld	xwa, (xsp+178)
	ld	xbc, (xsp+174)
	ld	xde, (xsp+170)
	call	SetAutoInc
IvNamingExit_ScreenData_Join3:
	ld	xhl, 0:i3
	jr	IvNamingExit_ScreenData_Epilogue
IvNamingExit_ScreenData_Skip6:
	ld	xwa, (xsp+178)
	ld	xbc, (xsp+174)
	ld	xde, (xsp+170)
	call	InheritedProc
IvNamingExit_ScreenData_Epilogue:
	pop	xiz
	lda	xsp, (xsp+178)
	ret
TrAsGrid_LookupByteTable:
	extz wa
	lda xbc, (0xf1a0:16)
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
	cp xbc, EVT_REQUEST_GRID_DRAW
	jrl z, TrAsGrid_HandleResizeEvent
	ld xwa, (xsp + 12)
	cp xwa, EVT_SW_IN
	jrl z, TrAsGrid_HandleSelectEvent
	cp xwa, EVT_GET_FIXED_ROW_STR
	jrl z, TrAsGrid_GetDirectionLabel
	cp xwa, EVT_GET_FIXED_COL_STR
	jrl z, TrAsGrid_GetWidgetLabel
	cp xwa, EVT_SHOW
	jr z, TrAsGrid_HandleInit
	sub xbc, EVT_INDEXSW_UP
	cp xbc, 0x0
	jrl lt, TrAsGrid_PassThrough
	cp xbc, 0x6
	jrl gt, TrAsGrid_PassThrough
	add xbc, xbc
	add xbc, AcTrAsGridBoxProc_CaseTable
	ld bc, (xbc)
	lda xix, (TrAsGrid_HandleInit:24)
	jp	t, (xix+bc)

TrAsGrid_HandleInit:
	ld	xwa, 192
	call	AcApcToggleProc_Helper
	cp	hl, 0:i3
	jr	z, TrAsGrid_InitStateZero
	ld	xwa, 9109513
	ld	bc, 0:i3
	jr	TrAsGrid_InitDispatch
TrAsGrid_InitStateZero:
	ld xwa, 0x8b0009
	ld bc, 1:i3

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
	ld xbc, EVT_GET_SELECTED_CEL
	ld xde, 0:i3
	call SendEvent
	ld xiz, xhl
	ld xwa, (xsp + 4)
	ld bc, (xwa + 26)
	ld xwa, xiz
	srl xwa, 16
	ldiw_erp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, (xsp + 16)
	ld xbc, EVT_INDEXSW_UP
	call SetDialUp
	ld xwa, (xsp + 4)
	ld bc, (xwa + 26)
	ld xwa, xiz
	srl xwa, 16
	ldiw_erp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, (xsp + 16)
	ld xbc, EVT_INDEXSW_DOWN
	call SetDialDown
	ld wa, 1:i3
	jrl TrAsGrid_CallUpdateSorted
	ld xwa, (xsp + 16)
	ld xbc, EVT_CHECK_INDEX
	ld xde, (xsp + 8)
	call SendEvent
	or xhl, xhl
	jrl z, TrAsGrid_HandleOtherEvent
	bit 0, (3296:16)
	jr nz, TrAsGrid_ScrollDown
	call GetFocusObject
	ld xwa, xhl
	ld xbc, EVT_GET_SELECTED_CEL
	ld xde, 0:i3
	call SendEvent
	dec 3, l
	extz hl
	ld wa, hl
	jr TrAsGrid_ApplyScrollOffset

TrAsGrid_ScrollDown:
	call GetFocusObject
	ld xwa, xhl
	ld xbc, EVT_GET_SELECTED_CEL
	ld xde, 0:i3
	call SendEvent
	inc 5, l
	extz hl
	ld wa, hl

TrAsGrid_ApplyScrollOffset:
	calr TrAsGrid_LookupByteTable
	ld (0x021082:24), l
	ld xwa, (xsp + 16)
	ld xbc, EVT_GET_SELECTED_CEL
	ld xde, 0:i3
	call SendEvent
	ld (xsp + 6), hl
	ld c, (3296:16)
	ld e, c
	and e, 0x1
	cp e, 0:i3
	scc16 nz, ix
	ld wa, (xsp + 6)
	sub wa, 0x2
	cp wa, 0:i3
	scc16 z, hl
	and hl, ix
	jr z, TrAsGrid_CheckScrollBoundary
	res 0, c
	ld (3296:16), c
	ld xwa, (xsp + 16)
	ld xbc, EVT_SET_SELECTED_CEL
	ld xde, 0xffff0009
	call SendEvent
	ld xwa, (xsp + 16)
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	jr TrAsGrid_DispatchNavigate

TrAsGrid_CheckScrollBoundary:
	cp e, 0:i3
	scc16 z, bc
	cp wa, 0:i3
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
	add xde, 0xffff0000
	ld xwa, (xsp + 16)
	ld xbc, EVT_SELE_DRAW

TrAsGrid_DispatchNavigate:
	call SendEvent
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call SetAutoInc
	call SleepMainTask
	ld xwa, NAKA_MAINFUNC_MiddleFuncCall
	ld xbc, EVT_TR_AS_TRACK_DEC
	ld xde, (xsp + 8)
	call FuncCall
	call WakeUpMainTask
	jrl TrAsGrid_ReturnZero

TrAsGrid_HandleOtherEvent:
	ld xwa, (xsp + 16)
	ld xbc, EVT_CHECK_GRID_INDEX
	ld xde, (xsp + 8)
	call SendEvent
	or xhl, xhl
	jrl z, TrAsGrid_ReturnZero
	bit 2, (1057:16)
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
	ld xbc, EVT_INDEXSW_UP
	ld xde, (xsp + 8)
	call SetDialUp
	ld xwa, (xsp + 16)
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, (xsp + 8)
	call SetDialDown
	ld wa, 1:i3
	jrl TrAsGrid_CallUpdateSorted
	ld xwa, (xsp + 16)
	ld xbc, EVT_CHECK_INDEX
	ld xde, (xsp + 8)
	call SendEvent
	or xhl, xhl
	jrl z, TrAsGrid_HandleOtherEvent2
	bit 0, (3296:16)
	jr nz, TrAsGrid_ScrollDown2
	call GetFocusObject
	ld xwa, xhl
	ld xbc, EVT_GET_SELECTED_CEL
	ld xde, 0:i3
	call SendEvent
	dec 1, l
	extz hl
	ld wa, hl
	jr TrAsGrid_ApplyScrollOffset2

TrAsGrid_ScrollDown2:
	call GetFocusObject
	ld xwa, xhl
	ld xbc, EVT_GET_SELECTED_CEL
	ld xde, 0:i3
	call SendEvent
	inc 7, l
	extz hl
	ld wa, hl

TrAsGrid_ApplyScrollOffset2:
	calr TrAsGrid_LookupByteTable
	ld (0x021082:24), l
	ld xwa, (xsp + 16)
	ld xbc, EVT_GET_SELECTED_CEL
	ld xde, 0:i3
	call SendEvent
	ld (xsp + 6), hl
	ld c, (3296:16)
	ld e, c
	and e, 0x1
	cp e, 0:i3
	scc16 z, ix
	ld wa, (xsp + 6)
	dec 2, wa
	cp wa, 7:i3
	scc16 z, hl
	and hl, ix
	jr z, TrAsGrid_CheckScrollBoundary2
	set 0, c
	ld (3296:16), c
	ld xwa, (xsp + 16)
	ld xbc, EVT_SET_SELECTED_CEL
	ld xde, 0xffff0002
	call SendEvent
	ld xwa, (xsp + 16)
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	jr TrAsGrid_DispatchNavigate2

TrAsGrid_CheckScrollBoundary2:
	cp e, 0:i3
	scc16 nz, bc
	cp wa, 7:i3
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
	add xde, 0xffff0000
	ld xwa, (xsp + 16)
	ld xbc, EVT_SELE_DRAW

TrAsGrid_DispatchNavigate2:
	call SendEvent
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call SetAutoInc
	call SleepMainTask
	ld xwa, NAKA_MAINFUNC_MiddleFuncCall
	ld xbc, EVT_TR_AS_TRACK_INC
	ld xde, (xsp + 8)
	call FuncCall
	call WakeUpMainTask
	jrl TrAsGrid_ReturnZero

TrAsGrid_HandleOtherEvent2:
	ld xwa, (xsp + 16)
	ld xbc, EVT_CHECK_GRID_INDEX
	ld xde, (xsp + 8)
	call SendEvent
	or xhl, xhl
	jrl z, TrAsGrid_ReturnZero
	bit 2, (1057:16)
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
	ld xbc, EVT_INDEXSW_UP
	ld xde, (xsp + 8)
	call SetDialUp
	ld xwa, (xsp + 16)
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, (xsp + 8)
	call SetDialDown
	ld wa, 1:i3

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
	bit 0, (3296:16)
	jr nz, TrAsGrid_DirectionLabel2
	ld xwa, TrAsGrid_GetDirectionLabel_Str
	jr TrAsGrid_PushLabelAddr

TrAsGrid_DirectionLabel2:
	ld xwa, TrAsGrid_DirectionLabel2_Str

TrAsGrid_PushLabelAddr:
	push xwa

TrAsGrid_CopyLabel:
	ld	xwa, (xsp+12)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	jrl	TrAsGrid_ReturnZero
TrAsGrid_HandleSelectEvent:
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, (xsp + 8)
	cp xwa, 0x8f
	jrl nz, TrAsGrid_ReturnZero
	bit 0, (3296:16)
	jr nz, TrAsGrid_DeselectCell
	ldw wa, 0x8
	calr TrAsGrid_LookupByteTable
	ld (0x021082:24), l
	set 0, (3296:16)
	ld xwa, (xsp + 16)
	ld xbc, EVT_SET_SELECTED_CEL
	ld xde, 0xffff0002
	call SendEvent
	ld xwa, (xsp + 16)
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	call SendEvent
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call SetAutoInc
	call SleepMainTask
	ld xwa, NAKA_MAINFUNC_MiddleFuncCall
	ld xbc, EVT_TR_AS_PAGE_INC
	ld xde, (xsp + 8)
	jr TrAsGrid_FinishCellUpdate

TrAsGrid_DeselectCell:
	ld wa, 0:i3
	calr TrAsGrid_LookupByteTable
	ld (0x021082:24), l
	res 0, (3296:16)
	ld xwa, (xsp + 16)
	ld xbc, EVT_SET_SELECTED_CEL
	ld xde, 0xffff0002
	call SendEvent
	ld xwa, (xsp + 16)
	ld xbc, EVT_PAINT
	ld xde, 0:i3
	call SendEvent
	ld xwa, (xsp + 16)
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	call SetAutoInc
	call SleepMainTask
	ld xwa, NAKA_MAINFUNC_MiddleFuncCall
	ld xbc, EVT_TR_AS_PAGE_DEC
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
	ld xhl, 0:i3
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
	lda xbc, (TrAsGrid_LookupTable_Table:24)
	ld	hl, (xbc+wa)
	ret

; TrAsGrid_StepListValue (formerly TrAsGrid_ByteData1: it is code) -- A :=
; position of value A in the 20-entry list TrAsGrid_ByteData1_Table; step
; it up (C == 0, stopping at 19) or down (stopping at 0); return in L the
; list value at the new position from TrAsGrid_ByteData1_Table_2.  Called
; by the TrAsGridCheck cases.
TrAsGrid_StepListValue:
	extz	wa
	lda	xde, (TrAsGrid_ByteData1_Table:24)
	ld	a, (xde+wa)
	cp c, 0:i3
	jr nz, TrAsGrid_StepListValue_Skip
	cp a, 19
	jr	nc, TrAsGrid_StepListValue_Join
	inc	1, a
	jr	TrAsGrid_StepListValue_Join
TrAsGrid_StepListValue_Skip:
	cp	a, 0:i3
	jr	z, TrAsGrid_StepListValue_Join
	dec	1, a
TrAsGrid_StepListValue_Join:
	extz	wa
	ld	xbc, TrAsGrid_ByteData1_Table_2
	ld	l, (xbc+wa)
	ret

TrAsGrid_CheckTrackType:
	cp a, 0:i3
	jr nz, TrAsGrid_CheckCurrentCell
	ld a, c
	extz wa
	lda xbc, (0xf1a0:16)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	cp a, 0xe
	jr z, TrAsGrid_IsDrumType
	cp a, 0xd
	jr z, TrAsGrid_IsDrumType

TrAsGrid_NotDrumType:
	ld l, 0x0:opc
	ret

TrAsGrid_CheckCurrentCell:
	ld a, (0x021082:24)
	cp a, 0xe
	jr z, TrAsGrid_IsDrumType
	cp a, 0xd
	jr nz, TrAsGrid_NotDrumType

TrAsGrid_IsDrumType:
	ld l, 0x1:opc
	ret

TrAsGridCheck:
	lda xsp, (xsp - 18)
	push xiz
	ld xiz, xde
	ld xwa, xbc
	cp xbc, EVT_REQUEST_GRID_DRAW
	jrl z, TrAsGridChk_HandleResizeEvent
	sub xwa, EVT_INDEXSW_UP
	cp xwa, 0x0
	jrl lt, TrAsGridChk_ReturnZero
	cp xwa, 0x6
	jrl gt, TrAsGridChk_ReturnZero
	add xwa, xwa
	add xwa, TrAsGridCheck_CaseTable
	ld wa, (xwa)
	lda xix, (TrAsGridCheck_Cases:24)
	jp	t, (xix+wa)

; Case bodies of the `jp t, (xrr+rr)` switch in TrAsGridCheck (events 0x1C00017-0x1C0001D; word offsets at TrAsGridCheck_CaseTable): jp (xix + r) with xix = this
; label, so this label is the offset-0 case.  Formerly named as data; it is
; code.
TrAsGridCheck_Cases:
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, EVT_GET_SELECTED_CEL
	ld	xde, 0:i3
	call	SendEvent
	ld	xiz, xhl
	lda	xwa, (xsp+14)
	ld	xbc, xiz
	srl	xbc, 16
	ld	qbc, 0
	ld	(xwa), bc
	ld	de, iz
	ld	(xwa+2), de
	ld	bc, (xwa)
	cp	bc, 3:i3
	jrl	z, TrAsGrid_CheckTrackType_Skip3
	cp	bc, 2:i3
	jr	z, TrAsGrid_CheckTrackType_Skip
	cp	bc, 1:i3
	jrl	nz, TrAsGridChk_ReturnZero
	ld	a, (0x2873:16)
	extz	wa
	ld	bc, 0:i3
	calr	TrAsGrid_StepListValue
	ld	(0x2873:16), l
	ld (0x021082:24), (0x2873:16)
	ld xwa, NAKA_MAINFUNC_MiddleFuncCall
	ld	xbc, EVT_TR_AS_PART_INC
	ld	xde, xiz
	call	MainFuncCall
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, EVT_REQUEST_GRID_DRAW
	ld	xde, xiz
	call	SendEvent
	call	GetFocusObject
	ld	xwa, xhl
	ld	de, (xsp+16)
	extz	xde
	add	xde, 0x020000
	ld	xbc, EVT_REQUEST_GRID_DRAW
	call	SendEvent
	call	GetFocusObject
	ld	xwa, xhl
	ld	de, (xsp+16)
	extz	xde
	add	xde, 0x030000
	ld	xbc, EVT_REQUEST_GRID_DRAW
	call	SendEvent
	jrl	TrAsGridChk_ReturnZero
TrAsGrid_CheckTrackType_Skip:
	bit	0, (3296:16)
	jr	nz, TrAsGrid_CheckTrackType_Skip2
	dec	2, e
	extz	de
	ld	wa, de
	jr	TrAsGrid_CheckTrackType_Join
TrAsGrid_CheckTrackType_Skip2:
	inc	6, e
	extz	de
	ld	wa, de
TrAsGrid_CheckTrackType_Join:
	calr	TrAsGrid_LookupTable
	or (61904:16), hl
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, EVT_REQUEST_GRID_DRAW
	ld	xde, xiz
	call	SendEvent
	ld	xwa, NAKA_MAINFUNC_MiddleFuncCall
	ld	xbc, EVT_AMD_CALL
	ld	xde, xiz
	jrl	TrAsGrid_CheckTrackType_Join5
TrAsGrid_CheckTrackType_Skip3:
	bit	0, (3296:16)
	jr	nz, TrAsGrid_CheckTrackType_Skip4
	dec	2, e
	extz	de
	ld	wa, de
	calr	TrAsGrid_LookupTable
	or (62096:16), hl
	ld	xwa, NAKA_MAINFUNC_MiddleFuncCall
	ld	xbc, EVT_TRACK_MIDI_CALL
	ld	xde, xiz
	jr	TrAsGrid_CheckTrackType_Join2
TrAsGrid_CheckTrackType_Skip4:
	inc	6, e
	extz	de
	ld	wa, de
	calr	TrAsGrid_LookupTable
	or (62096:16), hl
	ld	xwa, NAKA_MAINFUNC_MiddleFuncCall
	ld	xbc, EVT_TRACK_MIDI_CALL
	ld	xde, xiz
TrAsGrid_CheckTrackType_Join2:
	call	MainFuncCall
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, EVT_REQUEST_GRID_DRAW
	ld	xde, xiz
	call	SendEvent
	ld	xwa, NAKA_MAINFUNC_MiddleFuncCall
	ld	xbc, EVT_AMD_CALL
	ld	xde, xiz
	jrl	TrAsGrid_CheckTrackType_Join5
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, EVT_GET_SELECTED_CEL
	ld	xde, 0:i3
	call	SendEvent
	ld	xiz, xhl
	lda	xwa, (xsp+14)
	ld	xbc, xiz
	srl	xbc, 16
	ld	qbc, 0
	ld	(xwa), bc
	ld	de, iz
	ld	(xwa+2), de
	ld	bc, (xwa)
	cp	bc, 3:i3
	jrl	z, TrAsGrid_CheckTrackType_Skip7
	cp	bc, 2:i3
	jr	z, TrAsGrid_CheckTrackType_Skip5
	cp	bc, 1:i3
	jrl	nz, TrAsGridChk_ReturnZero
	ld	a, (0x2873:16)
	extz	wa
	ld	bc, 1:i3
	calr	TrAsGrid_StepListValue
	ld	(0x2873:16), l
	ld (0x021082:24), (0x2873:16)
	ld xwa, NAKA_MAINFUNC_MiddleFuncCall
	ld	xbc, EVT_TR_AS_PART_DEC
	ld	xde, xiz
	call	MainFuncCall
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, EVT_REQUEST_GRID_DRAW
	ld	xde, xiz
	call	SendEvent
	call	GetFocusObject
	ld	xwa, xhl
	ld	de, (xsp+16)
	extz	xde
	add	xde, 0x020000
	ld	xbc, EVT_REQUEST_GRID_DRAW
	call	SendEvent
	call	GetFocusObject
	ld	xwa, xhl
	ld	de, (xsp+16)
	extz	xde
	add	xde, 0x030000
	ld	xbc, EVT_REQUEST_GRID_DRAW
	call	SendEvent
	jrl	TrAsGridChk_ReturnZero
TrAsGrid_CheckTrackType_Skip5:
	bit	0, (3296:16)
	jr	nz, TrAsGrid_CheckTrackType_Skip6
	dec	2, e
	extz	de
	ld	wa, de
	jr	TrAsGrid_CheckTrackType_Join3
TrAsGrid_CheckTrackType_Skip6:
	inc	6, e
	extz	de
	ld	wa, de
TrAsGrid_CheckTrackType_Join3:
	calr	TrAsGrid_LookupTable
	cpl	hl
	and (61904:16), hl
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, EVT_REQUEST_GRID_DRAW
	ld	xde, xiz
	call	SendEvent
	ld	xwa, NAKA_MAINFUNC_MiddleFuncCall
	ld	xbc, EVT_AMD_CALL
	ld	xde, xiz
	jr	TrAsGrid_CheckTrackType_Join5
TrAsGrid_CheckTrackType_Skip7:
	bit	0, (3296:16)
	jr	nz, TrAsGrid_CheckTrackType_Skip8
	dec	2, e
	extz	de
	ld	wa, de
	calr	TrAsGrid_LookupTable
	cpl	hl
	and (62096:16), hl
	ld	xwa, NAKA_MAINFUNC_MiddleFuncCall
	ld	xbc, EVT_TRACK_MIDI_CALL
	ld	xde, xiz
	jr	TrAsGrid_CheckTrackType_Join4
TrAsGrid_CheckTrackType_Skip8:
	inc	6, e
	extz	de
	ld	wa, de
	calr	TrAsGrid_LookupTable
	cpl	hl
	and (62096:16), hl
	ld	xwa, NAKA_MAINFUNC_MiddleFuncCall
	ld	xbc, EVT_TRACK_MIDI_CALL
	ld	xde, xiz
TrAsGrid_CheckTrackType_Join4:
	call	MainFuncCall
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, EVT_REQUEST_GRID_DRAW
	ld	xde, xiz
	call	SendEvent
	ld	xwa, NAKA_MAINFUNC_MiddleFuncCall
	ld	xbc, EVT_AMD_CALL
	ld	xde, xiz
TrAsGrid_CheckTrackType_Join5:
	call	MainFuncCall
	jrl	TrAsGridChk_ReturnZero

TrAsGridChk_HandleResizeEvent:
	lda xbc, (xsp + 14)
	ld xwa, xiz
	srl xwa, 16
	ldiw_erp 0xe2, 0
	ld (xbc), wa
	lda xwa, (xbc + 2)
	ld de, iz
	ld (xwa), de
	lda xde, (xsp + 4)
	ld (xbc + 4), xde
	ld bc, (xbc)
	ld wa, (xwa)
	cp bc, 3:i3
	jrl z, TrAsGridChk_Part3_Start
	cp bc, 2:i3
	jr z, TrAsGridChk_Part2_Start
	cp bc, 1:i3
	jrl nz, TrAsGridChk_ReturnZero
	call GetFocusObject
	ld xwa, xhl
	ld xbc, EVT_GET_SELECTED_CEL
	ld xde, 0:i3
	call SendEvent
	ld wa, (xsp + 16)
	ld bc, wa
	cp bc, hl
	jr nz, TrAsGridChk_Part1_AdjustDown
	ld l, (0x021082:24)
	jr TrAsGridChk_Part1_SendAudio

TrAsGridChk_Part1_AdjustDown:
	bit 0, (3296:16)
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
	extz	hl
	sla	hl, 2
	ld	xbc, TrAsGridChk_Part1_SendAudio_PtrTable
	ld	xwa, (xbc+hl)
	push	xwa
	lda	xwa, (xsp+8)
	push	xwa
	call	Sprintf_Locked
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+14)
	ld	xbc, EVT_GRID_DRAW
	jrl	TrAsGridChk_DispatchAndReturn
TrAsGridChk_Part2_Start:
	bit 0, (3296:16)
	jr nz, TrAsGridChk_Part2_UpDir
	dec 2, a
	extz wa
	calr TrAsGrid_LookupTable
	and hl, (0xf1d0:16)
	lda xbc, (xsp + 4)
	ld xwa, TrAsGridChk_Part2_Start_Str_2
	cp hl, 0:i3
	jr z, TrAsGridChk_Part2_PushCmd
	ld xwa, TrAsGridChk_Part2_Start_Str

TrAsGridChk_Part2_PushCmd:
	push	xwa
	push	xbc
	call	Sprintf_Locked
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, EVT_GET_SELECTED_CEL
	ld	xde, 0:i3
	call	SendEvent
	ld	wa, (xsp+16)
	ld	de, wa
	dec	2, a
	ld	c, a
	extz	bc
	cp	de, hl
	jr	nz, TrAsGridChk_Part2_CheckType0
	ld	wa, 1:i3
	calr	TrAsGrid_CheckTrackType
	cp	l, 1:i3
	jrl	nz, TrAsGridChk_Part2_Finish
	ld	xwa, TrAsGridChk_Part2_PushCmd_Str
	jr	TrAsGridChk_SendExtraAudioCmd
TrAsGridChk_Part2_CheckType0:
	ld wa, 0:i3
	calr TrAsGrid_CheckTrackType
	cp l, 1:i3
	jr nz, TrAsGridChk_Part2_Finish
	ld xwa, TrAsGridChk_Part2_PushCmd_Str_2
	jr TrAsGridChk_SendExtraAudioCmd

TrAsGridChk_Part2_UpDir:
	inc 6, a
	extz wa
	calr TrAsGrid_LookupTable
	and hl, (0xf1d0:16)
	lda xbc, (xsp + 4)
	ld xwa, TrAsGridChk_Part2_UpDir_Str_2
	cp hl, 0:i3
	jr z, TrAsGridChk_Part2_UpPushCmd
	ld xwa, TrAsGridChk_Part2_UpDir_Str

TrAsGridChk_Part2_UpPushCmd:
	push	xwa
	push	xbc
	call	Sprintf_Locked
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, EVT_GET_SELECTED_CEL
	ld	xde, 0:i3
	call	SendEvent
	ld	wa, (xsp+16)
	ld	de, wa
	inc	6, a
	ld	c, a
	extz	bc
	cp	de, hl
	jr	nz, TrAsGridChk_Part2_UpCheckType0
	ld	wa, 1:i3
	calr	TrAsGrid_CheckTrackType
	cp	l, 1:i3
	jr	nz, TrAsGridChk_Part2_Finish
	ld	xwa, TrAsGridChk_Part2_UpPushCmd_Str
	jr	TrAsGridChk_SendExtraAudioCmd
TrAsGridChk_Part2_UpCheckType0:
	ld wa, 0:i3
	calr TrAsGrid_CheckTrackType
	cp l, 1:i3
	jr nz, TrAsGridChk_Part2_Finish
	ld xwa, TrAsGridChk_Part2_UpCheckType0_Str

TrAsGridChk_SendExtraAudioCmd:
	push	xwa
	lda	xwa, (xsp+8)
	push	xwa
	call	Sprintf_Locked
	inc	8, xsp
TrAsGridChk_Part2_Finish:
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 14)
	ld xbc, EVT_GRID_DRAW
	jrl TrAsGridChk_DispatchAndReturn

TrAsGridChk_Part3_Start:
	bit 0, (3296:16)
	jr nz, TrAsGridChk_Part3_UpDir
	dec 2, a
	extz wa
	calr TrAsGrid_LookupTable
	and hl, (0xf290:16)
	ld xwa, TrAsGridChk_Part3_Start_Str_2
	cp hl, 0:i3
	jr z, TrAsGridChk_Part3_PushCmd
	ld xwa, TrAsGridChk_Part3_Start_Str

TrAsGridChk_Part3_PushCmd:
	push	xwa
	lda	xwa, (xsp+8)
	push	xwa
	call	Sprintf_Locked
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, EVT_GET_SELECTED_CEL
	ld	xde, 0:i3
	call	SendEvent
	ld	wa, (xsp+16)
	ld	de, wa
	dec	2, a
	ld	c, a
	extz	bc
	cp	de, hl
	jr	nz, TrAsGridChk_Part3_CheckType0
	ld	wa, 1:i3
	calr	TrAsGrid_CheckTrackType
	cp	l, 1:i3
	jrl	nz, TrAsGridChk_Part3_Finish
	ld	xwa, TrAsGridChk_Part3_PushCmd_Str
	jr	TrAsGridChk_SendExtraAudioCmd2
TrAsGridChk_Part3_CheckType0:
	ld wa, 0:i3
	calr TrAsGrid_CheckTrackType
	cp l, 1:i3
	jr nz, TrAsGridChk_Part3_Finish
	ld xwa, TrAsGridChk_Part3_PushCmd_Str_2
	jr TrAsGridChk_SendExtraAudioCmd2

TrAsGridChk_Part3_UpDir:
	inc 6, a
	extz wa
	calr TrAsGrid_LookupTable
	and hl, (0xf290:16)
	ld xwa, TrAsGridChk_Part3_UpDir_Str_2
	cp hl, 0:i3
	jr z, TrAsGridChk_Part3_UpPushCmd
	ld xwa, TrAsGridChk_Part3_UpDir_Str

TrAsGridChk_Part3_UpPushCmd:
	push	xwa
	lda	xwa, (xsp+8)
	push	xwa
	call	Sprintf_Locked
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, EVT_GET_SELECTED_CEL
	ld	xde, 0:i3
	call	SendEvent
	ld	wa, (xsp+16)
	ld	de, wa
	inc	6, a
	ld	c, a
	extz	bc
	cp	de, hl
	jr	nz, TrAsGridChk_Part3_UpCheckType0
	ld	wa, 1:i3
	calr	TrAsGrid_CheckTrackType
	cp	l, 1:i3
	jr	nz, TrAsGridChk_Part3_Finish
	ld	xwa, TrAsGridChk_Part3_UpPushCmd_Str
	jr	TrAsGridChk_SendExtraAudioCmd2
TrAsGridChk_Part3_UpCheckType0:
	ld wa, 0:i3
	calr TrAsGrid_CheckTrackType
	cp l, 1:i3
	jr nz, TrAsGridChk_Part3_Finish
	ld xwa, TrAsGridChk_Part3_UpCheckType0_Str

TrAsGridChk_SendExtraAudioCmd2:
	push	xwa
	lda	xwa, (xsp+8)
	push	xwa
	call	Sprintf_Locked
	inc	8, xsp
TrAsGridChk_Part3_Finish:
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 14)
	ld xbc, EVT_GRID_DRAW

TrAsGridChk_DispatchAndReturn:
	call SendEvent

TrAsGridChk_ReturnZero:
	ld xhl, 0:i3
	pop xiz
	lda xsp, (xsp + 18)
	ret
TrAsGridChk_End:

AcModeSelBoxProc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xwa
	cp xbc, EVT_SET_SELECTED
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
	mrdb5 0x8b, 0x32, 0x19, 0x3e, 0x0d

VoiceConfig_ReturnZero:
	ld xhl, 0:i3

VoiceConfig_Epilogue:
	pop xiz
	inc 4, xsp
	ret

VoiceConfig_ScreenTypeDispatch:
	push xiz
	ld xiz, xwa
	cp xiz, 0xb
	jr z, VoiceConfig_SetType5
	cp xiz, 0xa
	jr z, VoiceConfig_SetType4
	cp xiz, 0x9
	jr z, VoiceConfig_SetType3
	cp xiz, 0x8b
	jr z, VoiceConfig_SetType2
	cp xiz, 0x8a
	jr z, VoiceConfig_SetType1
	cp xiz, 0x89
	jr nz, VoiceConfig_ReturnZeroShort
	ld xiz, 0:i3

VoiceConfig_LookupByScreenType:
	call GetTitleNow
	ldiw_erp 0xee, 0
	cp hl, 0xe3
	jr z, VoiceConfig_LoadTableB
	cp hl, 0xe2
	jr z, VoiceConfig_LoadTableA
	cp hl, 0xe1
	jr nz, VoiceConfig_ReturnZeroShort
	ld xwa, VoiceConfig_LookupByScreenType_Table

VoiceConfig_ReadFromTable:
	add xwa, xiz
	ld l, (xwa)
	jr VoiceConfig_PopIzRet

VoiceConfig_SetType1:
	ld xiz, 1:i3
	jr VoiceConfig_LookupByScreenType

VoiceConfig_SetType2:
	ld xiz, 2:i3
	jr VoiceConfig_LookupByScreenType

VoiceConfig_SetType3:
	ld xiz, 3:i3
	jr VoiceConfig_LookupByScreenType

VoiceConfig_SetType4:
	ld xiz, 4:i3
	jr VoiceConfig_LookupByScreenType

VoiceConfig_SetType5:
	ld xiz, 5:i3
	jr VoiceConfig_LookupByScreenType

VoiceConfig_LoadTableA:
	ld xwa, VoiceConfig_LoadTableA_Table
	jr VoiceConfig_ReadFromTable

VoiceConfig_LoadTableB:
	ld xwa, VoiceConfig_LoadTableB_Table
	jr VoiceConfig_ReadFromTable

VoiceConfig_ReturnZeroShort:
	ld l, 0x0:opc

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
	cp xwa, EVT_SW_IN
	jr z, AcDemoSong_HandleResize
	cp xwa, EVT_HIDE
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
	cp (3375:16), 0
	jr nz, AcCurrentSongBox_RetZero
	bit 3, (0x28ad:16)
	jr z, AcDemoSong_SetupDisplay
	cp (4439:16), l
	jr nz, AcCurrentSongBox_RetZero

AcDemoSong_SetupDisplay:
	ld h, 0x0:opc
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
	ld xhl, 0:i3

AcDemoSong_Epilogue:
	pop xiz
	lda xsp, (xsp + 12)
	ret
AcDemoSong_End:

AcCurrentSongBoxProc:
	lda xsp, (xsp-256)
	push xiz
	ld xiz, xwa
	cp xbc, EVT_REPAINT
	jr z, AcCurSongName_HandleFocusGained
	cp xbc, EVT_PAINT
	jr z, AcCurSongName_HandleFocusGained
	cp xbc, EVT_HIDE
	jr z, AcCurSong_HandleEvent1
	cp xbc, EVT_SHOW
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
	ld	xwa, xiz
	call	InheritedProc
	ld	a, (65507:24)
	inc	1, a
	extz	wa
	pushw	wa
	pushw	AcCurSongName_HandleFocusGained_Data@hi16
	pushw	AcCurSongName_HandleFocusGained_Data@lo16
	lda	xwa, (xsp+10)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	lda	xde, (xsp+4)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	SendEvent
AcCurSong_ReturnZero:
	ld xhl, 0:i3

AcCurSong_Epilogue:
	pop xiz
	lda xsp, (xsp+256)
	ret
AcCurSong_End:

AcCurSongNameBoxProc:
	lda xsp, (xsp-256)
	push xiz
	ld xiz, xwa
	cp xbc, EVT_CUR_SONG_NAME
	jr z, AcCurSongName_HandleEventF
	cp xbc, EVT_REPAINT
	jr z, AcCurSongName_HandleFocusAndInit
	cp xbc, EVT_PAINT
	jr z, AcCurSongName_HandleFocusAndInit
	cp xbc, EVT_HIDE
	jr z, AcCurSongName_HandleEvent1
	cp xbc, EVT_SHOW
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

AcCurSongName_HandleFocusAndInit:
	ld xwa, xiz
	call InheritedProc
	ld xwa, NAKA_MAINFUNC_NameGetFuncCall
	ld xbc, EVT_GET_CUR_SONG_NAME
	ld xde, 0:i3
	call MainFuncCall
	jr MuteChSel_TtlSetup

AcCurSongName_HandleEventF:
	ld	xwa, xiz
	call	InheritedProc
	pushw	AcCurSongName_HandleEventF_Str_Blank22@hi16
	pushw	AcCurSongName_HandleEventF_Str_Blank22@lo16
	lda	xwa, (xsp+8)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	lda	xde, (xsp+4)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	SendEvent
	pushw	0
	pushw	7248
	lda	xwa, (xsp+8)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	lda	xde, (xsp+4)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	SendEvent
MuteChSel_TtlSetup:
	ld xhl, 0:i3

; SmfMuteChSelFunc title default
MuteChSel_TtlDefault:
	pop xiz
	lda xsp, (xsp+256)
	ret

DemoSongSelFunc:
	ld xwa, NAKA_MAINFUNC_MiddleFuncCall
	ld xbc, EVT_DEMO_SONG_SEL
	call MainFuncCall
	ld xhl, 0:i3
	ret

SmfMuteChSelFunc:
	push xiz
	ld xiz, xwa
	sub xbc, EVT_GET_LARGE_STEP
	cp xbc, 0x0
	jr lt, MuteChSel_ReturnZero
	cp xbc, 0x9
	jr gt, MuteChSel_ReturnZero
	add xbc, xbc
	add xbc, SmfMuteChSelFunc_CaseTable
	ld bc, (xbc)
	lda xix, (MuteChSel_Dispatch:24)
	jp	t, (xix+bc)
; SmfMuteChSelFunc dispatch
MuteChSel_Dispatch:
	ld	xwa, (xde+14)
	sll	xwa, 2
	ld	xbc, MuteChSel_Dispatch_PtrTable
	add	xbc, xwa
	ld	xwa, (xbc)
	push	xwa
	ld	xwa, (xde+18)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	ld	xhl, xiz
	jr	MuteChSel_Epilogue
	ld	xhl, 1:i3
	jr	MuteChSel_Epilogue
	ld	xhl, 15
	jr	MuteChSel_Epilogue
MuteChSel_ReturnZero:
	ld xhl, 0:i3
	jr MuteChSel_Epilogue
	lda xhl, (0x021084:24)

; SmfMuteChSelFunc epilogue
MuteChSel_Epilogue:
	pop xiz
	ret

SqTrAsPsSongFunc:
	push xiz
	ld xiz, xwa
	sub xbc, EVT_GET_LARGE_STEP
	cp xbc, 0x0
	jr lt, SqTrAsPsSong_ReturnZero
	cp xbc, 0x9
	jr gt, SqTrAsPsSong_ReturnZero
	add xbc, xbc
	add xbc, SqTrAsPsSongFunc_CaseTable
	ld bc, (xbc)
	lda xix, (SqTrAsPsSong_Dispatch:24)
	jp	t, (xix+bc)
; SqTrAsPsSongFunc dispatch
SqTrAsPsSong_Dispatch:
	ld	xwa, (xde+14)
	sll	xwa, 2
	ld	xbc, SqTrAsPsSong_Dispatch_PtrTable
	add	xbc, xwa
	ld	xwa, (xbc)
	push	xwa
	ld	xwa, (xde+18)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	ld	xhl, xiz
	jr	SqTrAsPsSong_Epilogue
	ld	xhl, 1:i3
	jr	SqTrAsPsSong_Epilogue
	ld	xhl, 10
	jr	SqTrAsPsSong_Epilogue
SqTrAsPsSong_ReturnZero:
	ld xhl, 0:i3
	jr SqTrAsPsSong_Epilogue
	lda xhl, (3391:16)

SqTrAsPsSong_Epilogue:
	pop xiz
	ret

SqAftSetFunc:
	push	xiz
	ld	xiz, xwa
	cp	xbc, EVT_GET_DIRECTION
	jr	z, SqAftSet_Case2	; -> 0xF2CD0B
	cp	xbc, EVT_GET_BIT
	jr	z, SqAftSet_Case1	; -> 0xF2CD07
	cp	xbc, EVT_GET_BIT_ADDRESS
	jr	z, SqAftSet_Case0	; -> 0xF2CD00
	cp	xbc, EVT_GET_BIT_STRING
	jr	nz, SqAftSet_Case2	; -> 0xF2CD0B
	ld	wa, (xde+8)
	sla	wa, 2
	lda	xbc, (SqAftSetFunc_PtrTable:24)
	ld	xwa, (xbc+wa)
	push	xwa
	ld	xwa, (xde+10)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	ld	xhl, xiz
	jr	SqAftSet_LookupExit	; -> 0xF2CD0D
SqAftSet_Case0:
	lda xhl, (0x00ffc2:24)
	jr SqAftSet_LookupExit

; SqAftSetFunc case 1
SqAftSet_Case1:
	ld xhl, 1:i3
	jr SqAftSet_LookupExit

; SqAftSetFunc case 2
SqAftSet_Case2:
	ld xhl, 0:i3

SqAftSet_LookupExit:
	pop xiz
	ret

SqAftSet_LookupTableEntry:
	extz wa
	add wa, wa
	lda xbc, (SqAftSet_LookupTableEntry_Table:24)
	ld	wa, (xbc+wa)
	ld (0x021086:24), wa
	ret

MuteChSetFunc:
	push xiz
	ld xiz, xwa
	ld xwa, xbc
	cp xbc, EVT_RAM_DATA_REQ
	jr z, MuteChSet_ParamCheck
	sub xwa, EVT_GET_LARGE_STEP
	cp xwa, 0x0
	jr lt, MuteChSetFunc_Exit
	cp xwa, 0x9
	jr gt, MuteChSetFunc_Exit
	add xwa, xwa
	add xwa, MuteChSetFunc_CaseTable
	ld wa, (xwa)
	lda xix, (MuteChSet_Dispatch:24)
	jp	t, (xix+wa)

; MuteChSetFunc dispatch
MuteChSet_Dispatch:
	ld	xwa, (xde+14)
	sll	xwa, 2
	ld	xbc, MuteChSet_Dispatch_PtrTable
	add	xbc, xwa
	ld	xwa, (xbc)
	push	xwa
	ld	xwa, (xde+18)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	ld	xhl, xiz
	jr	SqAftSet_LookupTableEntry_Epilogue
	ld	xhl, 1:i3
	jr	SqAftSet_LookupTableEntry_Epilogue
	ld	xhl, 15
	jr	SqAftSet_LookupTableEntry_Epilogue
	lda	xhl, (135306:24)
	jr	SqAftSet_LookupTableEntry_Epilogue
MuteChSet_ParamCheck:
	cp (0x021088:24), 0x01
	jr nz, MuteChSetFunc_Exit
	ld a, (0x02108a:24)
	extz wa
	calr SqAftSet_LookupTableEntry
	ld xwa, NAKA_MAINFUNC_MiddleFuncCall
	ld xbc, EVT_DIRECT_PLAY_MUTE
	ld xde, 0:i3
	call MainFuncCall

MuteChSetFunc_Exit:
	ld xhl, 0:i3
SqAftSet_LookupTableEntry_Epilogue:
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
	cp xwa, EVT_SHOW
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
	ld xbc, EVT_GET_TOGGLE_SW
	ld xde, 0:i3
	call ApFuncCall
	ld xde, xhl
	ld (0x02108c:24), xde
	ld xwa, xiz
	ld xbc, EVT_SET_PARAM
	call SendEvent
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	call InheritedProc
	ld xhl, 0:i3

AcMuteToggle_Epilogue:
	pop xiz
	inc 8, xsp
	ret

SMFMuteOnOffFunc:
	cp xbc, EVT_GET_TOGGLE_SW
	jr nz, SMFMuteOnOff_Enable
	ld xhl, 0:i3
	ld l, (0x021088:24)
	ret

SMFMuteOnOff_Enable:
	cp xde, 0x1
	jr nz, SMFMuteOnOff_Disable
	ld (0x021088:24), 0x01
	ld a, (0x02108a:24)
	extz wa
	calr SqAftSet_LookupTableEntry
	ld xwa, NAKA_MAINFUNC_MiddleFuncCall
	ld xbc, EVT_DIRECT_PLAY_MUTE
	ld xde, 0:i3
	jr SMFMuteOnOff_PostCall

SMFMuteOnOff_Disable:
	ld (0x021088:24), 0x00
	ldw (0x021086:24), 0x0000
	ld xwa, NAKA_MAINFUNC_MiddleFuncCall
	ld xbc, EVT_DIRECT_PLAY_MUTE
	ld xde, 0:i3

SMFMuteOnOff_PostCall:
	call MainFuncCall
	ld xhl, 0:i3
	ret

SMFMute_GetBit0Status:
	ld hl, (0x021086:24)
	and hl, 0x1
	extz xhl
	ret

SMFMute_GetBit1Status:
	ld hl, (0x021086:24)
	and hl, 0x2
	extz xhl
	ret

SMFMute_GetUpperBits:
	ld hl, (0x021086:24)
	and hl, 0xfffc
	extz xhl
	ret

SMFMute_ClearBit0:
	ld hl, (0x021086:24)
	res 0, hl
	extz xhl
	ret

Rt1MuteFunc:
	cp xbc, EVT_GET_TOGGLE_SW
	jr z, SMFMute_GetBit0Status
	cp xde, 0x1
	jr nz, Rt1Mute_ClearAndPost
	orw (0x021086:24), 1
	ld xwa, NAKA_MAINFUNC_MiddleFuncCall
	ld xbc, EVT_DIRECT_PLAY_MUTE
	ld xde, 0:i3
	jr Rt1Mute_PostCall

Rt1Mute_ClearAndPost:
	andw (0x021086:24), 0xfffe
	ld xwa, NAKA_MAINFUNC_MiddleFuncCall
	ld xbc, EVT_DIRECT_PLAY_MUTE
	ld xde, 0:i3

Rt1Mute_PostCall:
	call MainFuncCall
	ld xhl, 0:i3
	ret

Rt2MuteFunc:
	cp xbc, EVT_GET_TOGGLE_SW
	jr z, SMFMute_GetBit1Status
	cp xde, 0x1
	jr nz, Rt2Mute_ClearAndPost
	orw (0x021086:24), 2
	ld xwa, NAKA_MAINFUNC_MiddleFuncCall
	ld xbc, EVT_DIRECT_PLAY_MUTE
	ld xde, 0:i3
	jr Rt2Mute_PostCall

Rt2Mute_ClearAndPost:
	andw (0x021086:24), 0xfffd
	ld xwa, NAKA_MAINFUNC_MiddleFuncCall
	ld xbc, EVT_DIRECT_PLAY_MUTE
	ld xde, 0:i3

Rt2Mute_PostCall:
	call MainFuncCall
	ld xhl, 0:i3
	ret

DocOrchMuteFunc:
	cp xbc, EVT_GET_TOGGLE_SW
	jrl z, SMFMute_GetUpperBits
	cp xde, 0x1
	jr nz, DocOrchMute_ClearAndPost
	orw (0x021086:24), 0xfffc
	ld xwa, NAKA_MAINFUNC_MiddleFuncCall
	ld xbc, EVT_DIRECT_PLAY_MUTE
	ld xde, 0:i3
	jr DocOrchMute_PostCall

DocOrchMute_ClearAndPost:
	andw (0x021086:24), 3
	ld xwa, NAKA_MAINFUNC_MiddleFuncCall
	ld xbc, EVT_DIRECT_PLAY_MUTE
	ld xde, 0:i3

DocOrchMute_PostCall:
	call MainFuncCall
	ld xhl, 0:i3
	ret

PdOrchMuteFunc:
	cp xbc, EVT_GET_TOGGLE_SW
	jrl z, SMFMute_ClearBit0
	cp xde, 0x1
	jr nz, PdOrchMute_ClearAndPost
	orw (0x021086:24), 0xfffe
	ld xwa, NAKA_MAINFUNC_MiddleFuncCall
	ld xbc, EVT_DIRECT_PLAY_MUTE
	ld xde, 0:i3
	jr PdOrchMute_PostCall

PdOrchMute_ClearAndPost:
	andw (0x021086:24), 1
	ld xwa, NAKA_MAINFUNC_MiddleFuncCall
	ld xbc, EVT_DIRECT_PLAY_MUTE
	ld xde, 0:i3

PdOrchMute_PostCall:
	call MainFuncCall
	ld xhl, 0:i3
	ret

SeqNameOKFunc:
	call GetNamingWindowID
	ld xwa, xhl
	ld xbc, EVT_GET_STRING
	ld xde, 0x20c92
	call SendEvent
	ld xwa, NAKA_MAINFUNC_MiddleFuncCall
	ld xbc, EVT_SONG_NAME_SET
	ld xde, 0x20c92
	call MainFuncCall
	ld xhl, 0:i3
	ret

SeqNamingCheck:
	dec	4, xsp
	push	xiz
	ld	(xsp+4), xde
	ld	xiz, xwa
	cp	xbc, EVT_GET_STRING_LENGTH
	jr	z, SeqNameOK_Return10
	cp	xbc, EVT_GET_NAMING_MODE
	jr	z, SeqNameOK_ReturnZero
	cp	xbc, EVT_GET_STRING
	jr	nz, SeqNameOK_ReturnZero
	pushw	16
	pushw	0
	pushw	62080
	pushw	2
	pushw	3234
	call	CmpNamingCheck_Helper
	lda	xwa, (134306:24)
	ld	(xwa+16), 0
	push	xwa
	ld	xwa, (xsp+18)
	push	xwa
	call	Free_Compare2
	lda	xsp, (xsp+18)
	ld	xhl, xiz
	jr	SeqNameOK_Epilogue
SeqNameOK_ReturnZero:
	ld xhl, 0:i3
	jr SeqNameOK_Epilogue

SeqNameOK_Return10:
	ld xhl, 0x10

SeqNameOK_Epilogue:
	pop xiz
	inc 4, xsp
	ret
SeqNameOK_End:

AcDemoMedleyDispBoxProc:
	lda xsp, (xsp-256)
	push xiz
	ld xiz, xwa
	cp xbc, EVT_REPAINT
	jr z, AcDemoMedley_HandleScrollEvent
	cp xbc, EVT_PAINT
	jr z, AcDemoMedley_HandleScrollEvent
	cp xbc, EVT_HIDE
	jr z, DemoMedDsp_LoadEntry
	cp xbc, EVT_SHOW
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
	ld xwa, AcDemoMedley_HandleScrollEvent_Str_2
	cp (0x021090:24), 0x01
	jr nz, DPPlayDsp_CheckEntry
	ld xwa, AcDemoMedley_HandleScrollEvent_Str

; DPPlayDspCheck entry
DPPlayDsp_CheckEntry:
	push	xwa
	push	xbc
	call	Sprintf_Locked
	inc	8, xsp
	lda	xde, (xsp+4)
	ld	xwa, xiz
	ld	xbc, EVT_PARA_DRAW
	call	SendEvent
DPPlayDsp_ReturnPath:
	ld xhl, 0:i3

; DPPauseDspCheck entry
DPPauseDsp_CheckEntry:
	pop xiz
	lda xsp, (xsp+256)
	ret

DemoMedDspCheck:
	push xiz
	ld xiz, xwa
	ld xwa, xbc
	cp xbc, EVT_RAM_DATA_REQ
	jr z, DPLoad_DspReturn
	sub xwa, EVT_GET_LARGE_STEP
	cp xwa, 0x0
	jr lt, DPLoad_DspReturn
	cp xwa, 0x9
	jr gt, DPLoad_DspReturn
	add xwa, xwa
	add xwa, DemoMedDspCheck_CaseTable
	ld wa, (xwa)
	lda xix, (DemoMedDsp_Dispatch:24)
	jp	t, (xix+wa)

; DemoMedDspCheck dispatch
DemoMedDsp_Dispatch:
	ld	xhl, (xde+14)
	ld	xbc, (xde+18)
	ld	xwa, DemoMedDsp_Dispatch_Str
	or	xhl, xhl
	jr	nz, AcDemoMedleyDispBoxProc_Skip
	ld	xwa, MedleyDisp_Blank
AcDemoMedleyDispBoxProc_Skip:
	push	xwa
	push	xbc
	call	Sprintf_Locked
	inc	8, xsp
	ld	xhl, xiz
	jr	AcDemoMedleyDispBoxProc_Epilogue
	ld	xhl, 4:i3
	jr	AcDemoMedleyDispBoxProc_Epilogue
	ld	xhl, 1:i3
	jr	AcDemoMedleyDispBoxProc_Epilogue
	ld	xhl, 16
	jr	AcDemoMedleyDispBoxProc_Epilogue
	ld	xhl, 4294967267
	jr	AcDemoMedleyDispBoxProc_Epilogue
	lda	xhl, (135312:24)
	jr	AcDemoMedleyDispBoxProc_Epilogue
DPLoad_DspReturn:
	ld xhl, 0:i3
AcDemoMedleyDispBoxProc_Epilogue:
	pop xiz
	ret

DPPlayDspCheck:
	push xiz
	ld xiz, xwa
	ld xwa, xbc
	cp xbc, EVT_RAM_DATA_REQ
	jr z, DPPlay_DspReturn
	sub xwa, EVT_GET_LARGE_STEP
	cp xwa, 0x0
	jr lt, DPPlay_DspReturn
	cp xwa, 0x9
	jr gt, DPPlay_DspReturn
	add xwa, xwa
	add xwa, DPPlayDspCheck_CaseTable
	ld wa, (xwa)
	lda xix, (DPPlayDsp_Dispatch:24)
	jp	t, (xix+wa)

; DPPlayDspCheck dispatch
DPPlayDsp_Dispatch:
	ld	xhl, (xde+14)
	ld	xbc, (xde+18)
	ld	xwa, DPPlayDsp_Dispatch_Str
	or	xhl, xhl
	jr	nz, AcDemoMedleyDispBoxProc_Skip2
	ld	xwa, PlayModeStr_Play
AcDemoMedleyDispBoxProc_Skip2:
	push	xwa
	push	xbc
	call	Sprintf_Locked
	inc	8, xsp
	ld	xhl, xiz
	jr	AcDemoMedleyDispBoxProc_Epilogue2
	ld	xhl, 4:i3
	jr	AcDemoMedleyDispBoxProc_Epilogue2
	ld	xhl, 1:i3
	jr	AcDemoMedleyDispBoxProc_Epilogue2
	ld	xhl, 16
	jr	AcDemoMedleyDispBoxProc_Epilogue2
	ld	xhl, 4294967267
	jr	AcDemoMedleyDispBoxProc_Epilogue2
	lda	xhl, (135314:24)
	jr	AcDemoMedleyDispBoxProc_Epilogue2
DPPlay_DspReturn:
	ld xhl, 0:i3
AcDemoMedleyDispBoxProc_Epilogue2:
	pop xiz
	ret

DPPauseDspCheck:
	push xiz
	ld xiz, xwa
	ld xwa, xbc
	cp xbc, EVT_RAM_DATA_REQ
	jr z, DPPause_DspReturn
	sub xwa, EVT_GET_LARGE_STEP
	cp xwa, 0x0
	jr lt, DPPause_DspReturn
	cp xwa, 0x9
	jr gt, DPPause_DspReturn
	add xwa, xwa
	add xwa, DPPauseDspCheck_CaseTable
	ld wa, (xwa)
	lda xix, (DPPauseDsp_Dispatch:24)
	jp	t, (xix+wa)

; DPPauseDspCheck dispatch
DPPauseDsp_Dispatch:
	ld	xhl, (xde+14)
	ld	xbc, (xde+18)
	ld	xwa, DPPauseDsp_Dispatch_Str
	or	xhl, xhl
	jr	nz, AcDemoMedleyDispBoxProc_Skip3
	ld	xwa, PlayModeStr_Pause
AcDemoMedleyDispBoxProc_Skip3:
	push	xwa
	push	xbc
	call	Sprintf_Locked
	inc	8, xsp
	ld	xhl, xiz
	jr	AcDemoMedleyDispBoxProc_Epilogue3
	ld	xhl, 4:i3
	jr	AcDemoMedleyDispBoxProc_Epilogue3
	ld	xhl, 1:i3
	jr	AcDemoMedleyDispBoxProc_Epilogue3
	ld	xhl, 16
	jr	AcDemoMedleyDispBoxProc_Epilogue3
	ld	xhl, 4294967267
	jr	AcDemoMedleyDispBoxProc_Epilogue3
	lda	xhl, (135316:24)
	jr	AcDemoMedleyDispBoxProc_Epilogue3
DPPause_DspReturn:
	ld xhl, 0:i3
AcDemoMedleyDispBoxProc_Epilogue3:
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
	cp xwa, EVT_SW_IN
	jr z, IvExitTrSel_CheckSendEvent
	cp xwa, EVT_GET_STRING
	jr z, IvExitTrSel_CopyString
	ld xwa, xiz
	ld xbc, (xsp + 8)
	ld xde, (xsp + 4)
	jr IvExitTrSel_CallInherited

IvExitTrSel_CopyString:
	pushw	DPPauseDspCheck_CaseTable_Strings@hi16
	pushw	DPPauseDspCheck_CaseTable_Strings@lo16
	ld	xwa, (xsp+8)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	ld	xhl, 0:i3
	jr	IvExitTrSel_Epilogue
IvExitTrSel_CheckSendEvent:
	ld xwa, xiz
	call GetViewInstance
	ld xwa, xiz
	ld xbc, EVT_CHECK_EDIT_SW
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jr z, IvExitTrSel_PrepareInherited
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 1:i3
	call SendEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_CHANGE_MODE
	ld xde, NAKA_MODE_MD_SEQ
	call PostEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 0:i3
	call PostEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_CHANGE_TITLE
	ld xde, TITLE_SQCMENU
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

	RegObjTable NAKA_CLASS_Class, ClassProc, Kubo_ClassCount_168, Kubo_ClassTable_168, 0x168
	RegObjTable NAKA_CLASS_ResEvent, ResEventProc, Kubo_ResEventCount_1C8, EvtEffDraw_PtrTable, 0x1c8
	RegObjTable NAKA_CLASS_ResMethod, ResMethodProc, EffectsEditor_GapByte, MT_FuncName_PtrTable, 0x1e8
	RegObjTabl NAKA_CLASS_ApFunction, ApFunctionProc, 0x49, Kubo_ApFuncTable_128, 0x128
	RegObjTabl NAKA_CLASS_ApFunction, ApFunctionProc, 0x49, Kubo_ApFuncNameTable_428, 0x428
	RegObjTabl NAKA_CLASS_Function, FunctionProc, 0x0, 0x3df10, 0x108
	RegObjTabl NAKA_CLASS_Function, FunctionProc, 0x0, 0x3df14, 0x408
	RegObjTabl NAKA_CLASS_MainFunction, MainFunctionProc, 0x2c, Kubo_MainFunctionTable_148, 0x148
	RegObjTabl NAKA_CLASS_MainFunction, MainFunctionProc, 0x2c, InitializeKubo_PtrTable_72, 0x448
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0xc, Kubo_ViewableTable_00A, 0xa
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0xc, InitializeKubo_PtrTable_35, 0x30a
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0xc, Kubo_ViewableTable_00B, 0xb
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0xc, InitializeKubo_PtrTable_36, 0x30b
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x25, Kubo_ViewableTable_00C, 0xc
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x25, InitializeKubo_PtrTable_37, 0x30c
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0xc, InitializeKubo_PtrTable, 0xe
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0xc, InitializeKubo_PtrTable_38, 0x30e
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0xc, InitializeKubo_PtrTable_2, 0x80
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0xc, InitializeKubo_PtrTable_39, 0x380
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x1c, InitializeKubo_PtrTable_3, 0x81
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x1c, InitializeKubo_PtrTable_40, 0x381
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x8, InitializeKubo_PtrTable_4, 0x82
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x8, InitializeKubo_PtrTable_41, 0x382
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x10, InitializeKubo_PtrTable_5, 0x83
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x10, InitializeKubo_PtrTable_42, 0x383
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0xa, InitializeKubo_PtrTable_6, 0x84
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0xa, InitializeKubo_PtrTable_43, 0x384
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x19, InitializeKubo_PtrTable_7, 0x85
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x19, InitializeKubo_PtrTable_44, 0x385
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0xb, InitializeKubo_PtrTable_8, 0x86
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0xb, InitializeKubo_PtrTable_45, 0x386
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x18, InitializeKubo_PtrTable_9, 0x87
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x18, InitializeKubo_PtrTable_46, 0x387
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0xc, InitializeKubo_PtrTable_10, 0x88
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0xc, InitializeKubo_PtrTable_47, 0x388
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x4, InitializeKubo_PtrTable_11, 0x8d
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x4, InitializeKubo_PtrTable_48, 0x38d
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x11, InitializeKubo_PtrTable_12, 0x90
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x11, InitializeKubo_PtrTable_49, 0x390
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x13, InitializeKubo_PtrTable_13, 0x91
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x13, InitializeKubo_PtrTable_50, 0x391
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x1a, InitializeKubo_PtrTable_14, 0x93
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x1a, InitializeKubo_PtrTable_51, 0x393
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x4, InitializeKubo_PtrTable_15, 0x94
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x4, InitializeKubo_PtrTable_52, 0x394
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x1b, InitializeKubo_PtrTable_16, 0x95
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x1b, InitializeKubo_PtrTable_53, 0x395
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x8, InitializeKubo_PtrTable_17, 0x96
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x8, InitializeKubo_PtrTable_54, 0x396
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x4, InitializeKubo_PtrTable_18, 0x97
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x4, InitializeKubo_PtrTable_55, 0x397
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x1a, InitializeKubo_PtrTable_19, 0x98
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x1a, InitializeKubo_PtrTable_56, 0x398
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x8, InitializeKubo_PtrTable_20, 0x99
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x8, InitializeKubo_PtrTable_57, 0x399
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0xe, InitializeKubo_PtrTable_21, 0x9a
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0xe, InitializeKubo_PtrTable_58, 0x39a
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x16, InitializeKubo_PtrTable_22, 0x9b
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x16, InitializeKubo_PtrTable_59, 0x39b
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x15, InitializeKubo_PtrTable_23, 0x9c
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x15, InitializeKubo_PtrTable_60, 0x39c
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x10, InitializeKubo_PtrTable_24, 0x9d
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x10, InitializeKubo_PtrTable_61, 0x39d
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x10, InitializeKubo_PtrTable_25, 0x9e
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x10, InitializeKubo_PtrTable_62, 0x39e
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x19, InitializeKubo_PtrTable_26, 0x9f
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x19, InitializeKubo_PtrTable_63, 0x39f
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x10, InitializeKubo_PtrTable_27, 0xa0
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x10, InitializeKubo_PtrTable_64, 0x3a0
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x10, InitializeKubo_PtrTable_28, 0xa1
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x10, InitializeKubo_PtrTable_65, 0x3a1
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x11, InitializeKubo_PtrTable_29, 0xa2
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x11, InitializeKubo_PtrTable_66, 0x3a2
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0xf, InitializeKubo_PtrTable_30, 0xa3
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0xf, InitializeKubo_PtrTable_67, 0x3a3
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x11, InitializeKubo_PtrTable_31, 0xa4
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x11, InitializeKubo_PtrTable_68, 0x3a4
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x0, Kubo_ViewableTable_0A8, 0xa8
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x0, Kubo_ResNameTable_3A8, 0x3a8
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x0, Kubo_ViewableTable_0AA, 0xaa
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x0, Kubo_ResNameTable_3AA, 0x3aa
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x2, InitializeKubo_PtrTable_32, 0xab
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x2, InitializeKubo_PtrTable_69, 0x3ab
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0xf, InitializeKubo_PtrTable_33, 0xd6
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0xf, InitializeKubo_PtrTable_70, 0x3d6
	RegObjTabl NAKA_CLASS_Viewable, ViewableProc, 0x3d, InitializeKubo_PtrTable_34, 0xe7
	RegObjTabl NAKA_CLASS_ResName, ResNameProc, 0x3d, InitializeKubo_PtrTable_71, 0x3e7

	RegMode 0x8, InitializeKubo_Str_MD_ENTERTAINER, 0x7, NAKA_APFUNC_DefaultFunction, TITLE_ETMENU
	RegMode 0x8, InitializeKubo_Str_MD_SEQ, 0x8, NAKA_MAINFUNC_SeqModeFunc, TITLE_SQMENU
	RegMode 0x8, InitializeKubo_Str_MD_SEQ_EREC, 0x9, NAKA_MAINFUNC_SeqErecModeFunc, TITLE_SQEASYREC
	RegMode 0x8, InitializeKubo_Str_MD_SEQ_PLAY, 0xa, NAKA_MAINFUNC_SeqPlayModeFunc, TITLE_SQPLAY
	RegMode 0x8, InitializeKubo_Str_MD_SEQ_REAL, 0xb, NAKA_MAINFUNC_SeqRealModeFunc, TITLE_SQREALREC
	RegMode 0x8, InitializeKubo_Str_MD_SEQ_EDIT, 0xc, NAKA_MAINFUNC_SeqEditModeFunc, TITLE_SQEMENU
	RegMode 0x8, InitializeKubo_Str_MD_HELP, 0x14, NAKA_MAINFUNC_HelpModeFunc, TITLE_SWHELP

	RegTitle 0x8, InitializeKubo_Str_TT_SDREVSET, 0xa, NAKA_MAINFUNC_SdRevsetTitleFunc, 0xa0000
	RegTitle 0x8, InitializeKubo_Str_TT_SDDSPEFF, 0xb, NAKA_MAINFUNC_SdDspeffTitleFunc, 0xb0000
	RegTitle 0x8, InitializeKubo_Str_TT_SDEQUALIZER, 0xc, NAKA_APFUNC_DefaultFunction, 0xc0000
	RegTitle 0x8, InitializeKubo_Str_TT_SDACCILL, 0xe, NAKA_MAINFUNC_SdAccillTitleFunc, 0xe0000
	RegTitle 0x8, InitializeKubo_Str_TT_SQMENU, 0x80, NAKA_APFUNC_DefaultFunction, 0x800000
	RegTitle 0x8, InitializeKubo_Str_TT_SQPLAY, 0x81, NAKA_MAINFUNC_SqPlayTitleFunc, 0x810000
	RegTitle 0x8, InitializeKubo_Str_TT_SQCYCPLY, 0x82, NAKA_APFUNC_DefaultFunction, 0x820000
	RegTitle 0x8, InitializeKubo_Str_TT_SQEASYREC, 0x83, NAKA_APFUNC_DefaultFunction, 0x830000
	RegTitle 0x8, InitializeKubo_Str_TT_SQCMENU, 0x84, NAKA_APFUNC_DefaultFunction, 0x840000
	RegTitle 0x8, InitializeKubo_Str_TT_SQREALREC, 0x85, NAKA_MAINFUNC_SqRealRecTitleFunc, 0x850000
	RegTitle 0x8, InitializeKubo_Str_TT_SQCYCREC, 0x86, NAKA_APFUNC_DefaultFunction, 0x860000
	RegTitle 0x8, InitializeKubo_Str_TT_SQPUNCH, 0x87, NAKA_MAINFUNC_SqPunchTitleFunc, 0x870000
	RegTitle 0x8, InitializeKubo_Str_TT_SQPUNCHM, 0x88, NAKA_MAINFUNC_SqPunchmTitleFunc, 0x880000
	RegTitle 0x8, InitializeKubo_Str_TT_SQPNLWR, 0x8d, NAKA_APFUNC_DefaultFunction, 0x8d0000
	RegTitle 0x8, InitializeKubo_Str_TT_SQSNGCLR, 0x90, NAKA_MAINFUNC_SqSoclTitleFunc, 0x900000
	RegTitle 0x8, InitializeKubo_Str_TT_SQSNGCP, 0x91, NAKA_MAINFUNC_SqSngcpTitleFunc, 0x910000
	RegTitle 0x8, InitializeKubo_Str_TT_SQEMENU, 0x93, NAKA_APFUNC_DefaultFunction, 0x930000
	RegTitle 0x8, InitializeKubo_Str_TT_SQNOTESEL, 0x94, NAKA_MAINFUNC_SqNoteSelTitleFunc, 0x940000
	RegTitle 0x8, InitializeKubo_Str_TT_SQNOTEEDT, 0x95, NAKA_MAINFUNC_SqNoteEdtTitleFunc, 0x950000
	RegTitle 0x8, InitializeKubo_Str_TT_SQNOTECYCP, 0x96, NAKA_MAINFUNC_SqNoteCycpTitleFunc, 0x960000
	RegTitle 0x8, InitializeKubo_Str_TT_SQDRMSEL, 0x97, NAKA_MAINFUNC_SqDrmSelTitleFunc, 0x970000
	RegTitle 0x8, InitializeKubo_Str_TT_SQDRMEDT, 0x98, NAKA_MAINFUNC_SqDrmEdtTitleFunc, 0x980000
	RegTitle 0x8, InitializeKubo_Str_TT_SQDRMCYCP, 0x99, NAKA_MAINFUNC_SqDrmCycpTitleFunc, 0x990000
	RegTitle 0x8, InitializeKubo_Str_TT_SQTRKCLR, 0x9a, NAKA_MAINFUNC_SqTrclTitleFunc, 0x9a0000
	RegTitle 0x8, InitializeKubo_Str_TT_SQTRKMRG, 0x9b, NAKA_MAINFUNC_SqTrmgTitleFunc, 0x9b0000
	RegTitle 0x8, InitializeKubo_Str_TT_SQQTZ, 0x9c, NAKA_MAINFUNC_SqQtzTitleFunc, 0x9c0000
	RegTitle 0x8, InitializeKubo_Str_TT_SQTRNS, 0x9d, NAKA_MAINFUNC_SqTrnsTitleFunc, 0x9d0000
	RegTitle 0x8, InitializeKubo_Str_TT_SQVELOCNG, 0x9e, NAKA_MAINFUNC_SqVcngTitleFunc, 0x9e0000
	RegTitle 0x8, InitializeKubo_Str_TT_SQNOTECNG, 0x9f, NAKA_MAINFUNC_SqNcngTitleFunc, 0x9f0000
	RegTitle 0x8, InitializeKubo_Str_TT_SQADVDLY, 0xa0, NAKA_MAINFUNC_SqAdlyTitleFunc, 0xa00000
	RegTitle 0x8, InitializeKubo_Str_TT_SQMERS, 0xa1, NAKA_MAINFUNC_SqMersTitleFunc, 0xa10000
	RegTitle 0x8, InitializeKubo_Str_TT_SQMCP, 0xa2, NAKA_MAINFUNC_SqMcpyTitleFunc, 0xa20000
	RegTitle 0x8, InitializeKubo_Str_TT_SQMDEL, 0xa3, NAKA_MAINFUNC_SqMdelTitleFunc, 0xa30000
	RegTitle 0x8, InitializeKubo_Str_TT_SQMINS, 0xa4, NAKA_MAINFUNC_SqMinsTitleFunc, 0xa40000
	RegTitle 0x8, InitializeKubo_Str_TT_SQSNGCPC, 0xa8, NAKA_MAINFUNC_SqSngcpTitleFunc, 0x910000
	RegTitle 0x8, InitializeKubo_Str_TT_SQPNLWRM, 0xaa, NAKA_APFUNC_DefaultFunction, 0x8d0000
	RegTitle 0x8, InitializeKubo_Str_TT_SQMETBAL, 0xab, NAKA_APFUNC_DefaultFunction, 0xab0000
	RegTitle 0x8, InitializeKubo_Str_TT_ETMENU, 0xd6, NAKA_MAINFUNC_EtmenuTitleFunc, 0xd60000
	RegTitle 0x8, InitializeKubo_Str_TT_SWHELP, 0xe7, NAKA_MAINFUNC_HelpTitleFunc, 0xe70000

	lda xsp, (xsp + 14)
	ret

AutoPunchTtlRqFunc:
	cp xbc, EVT_SW_IN
	jr nz, IvRealRecCheck_ReturnZero
	bit 2, (1057:16)
	jr nz, IvRealRecCheck_ReturnZero
	ld xwa, 0xffffffff
	ld xbc, EVT_CHANGE_TITLE
	ld xde, TITLE_SQPUNCHM
	call PostEvent

IvRealRecCheck_ReturnZero:
	ld xhl, 0:i3
	ret

IvRealRecExitProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, EVT_SW_IN
	jr z, IvRealRecExit_CheckSendEvent
	cp xiz, EVT_GET_STRING
	jr z, IvRealRecExit_CopyString
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	jr IvRealRecExit_CallInherited

IvRealRecExit_CopyString:
	pushw	NakaDesc_Str0330A@hi16
	pushw	NakaDesc_Str0330A@lo16
	ld	xwa, (xsp+8)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	ld	xhl, 0:i3
	jr	IvRealRecExit_Epilogue
IvRealRecExit_CheckSendEvent:
	ld xwa, (xsp + 8)
	ld xbc, EVT_CHECK_EDIT_SW
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jr z, IvRealRecExit_PrepareInherited
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 1:i3
	call SendEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_CHANGE_MODE
	ld xde, NAKA_MODE_MD_SEQ
	call PostEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 0:i3
	call PostEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_CHANGE_TITLE
	ld xde, TITLE_SQCMENU
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
	cp xwa, EVT_SW_OFF
	jrl z, AcPanicEditSw_HandleLostInherited
	cp xwa, EVT_SW_ON
	jr z, AcPanicEditSw_HandleFocus
	cp xwa, EVT_DRAW
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
	ld xde, 0:i3
	ld e, (xhl + 40)
	ld xwa, (xsp + 8)
	ld xbc, EVT_PARA_DRAW
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
	set 0, (0x02109e:24)
	jr UI_CheckDisplayModeAndDispatch

AcPanicEditSw_SetMode1:
	set 1, (0x02109e:24)
	jr UI_CheckDisplayModeAndDispatch

AcPanicEditSw_SetMode2:
	set 2, (0x02109e:24)
	jr UI_CheckDisplayModeAndDispatch

AcPanicEditSw_SetMode3:
	set 3, (0x02109e:24)

UI_CheckDisplayModeAndDispatch:
	ld c, (0x02109e:24)
	ld a, c
	and a, 0x3
	jr z, AcPanicEditSw_HandleFocusLost
	and c, 0xc
	jr z, AcPanicEditSw_HandleFocusLost
	ld xwa, (xhl + 42)
	ld xbc, (xsp + 4)
	ld xde, xiz
	call ApFuncCall

AcPanicEditSw_ReturnZero:
	ld xhl, 0:i3
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
	res 0, (0x02109e:24)
	jr EventHandler_FinalizeAndReturn

AcPanicEditSw_ClearMode1:
	res 1, (0x02109e:24)
	jr EventHandler_FinalizeAndReturn

AcPanicEditSw_ClearMode2:
	res 2, (0x02109e:24)
	jr EventHandler_FinalizeAndReturn

AcPanicEditSw_ClearMode3:
	res 3, (0x02109e:24)

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
	cp xbc, EVT_SW_ON
	jr nz, PanicFunc_ReturnZero
	ld xwa, NAKA_MAINFUNC_MainPanic
	ld xbc, EVT_PANIC
	call MainFuncCall

PanicFunc_ReturnZero:
	ld xhl, 0:i3
	ret

HelpStsCheck:
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr nz, HelpStsCheck_ReturnZero
	ld xbc, 0:i3
	ld c, (0x0340e4:24)
	sll xbc, 2
	ld xwa, 0:i3
	ld a, (0x296e:16)
	sll xwa, 2
	ld xhl, 0x69800
	add xhl, xwa
	sub xhl, xbc
	ret

HelpStsCheck_ReturnZero:
	ld xhl, 0:i3
	ret

HelpStsP2Check:
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr nz, HelpStsP2Check_ReturnZero
	ld xbc, 0:i3
	ld c, (0x0340e4:24)
	sll xbc, 2
	ld xwa, 0:i3
	ld a, (0x296e:16)
	sll xwa, 2
	lda xwa, (xwa+200:16)
	ld xhl, 0x69800
	add xhl, xwa
	sub xhl, xbc
	ret

HelpStsP2Check_ReturnZero:
	ld xhl, 0:i3
	ret

HelpStsP3Check:
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr nz, HelpStsP3Check_ReturnZero
	ld xbc, 0:i3
	ld c, (0x0340e4:24)
	sll xbc, 2
	ld xwa, 0:i3
	ld a, (0x296e:16)
	sll xwa, 2
	lda xwa, (xwa+400)
	ld xhl, 0x69800
	add xhl, xwa
	sub xhl, xbc
	ret

HelpStsP3Check_ReturnZero:
	ld xhl, 0:i3
	ret

HelpStsP4Check:
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr nz, HelpStsP4Check_ReturnZero
	ld xbc, 0:i3
	ld c, (0x0340e4:24)
	sll xbc, 2
	ld xwa, 0:i3
	ld a, (0x296e:16)
	sll xwa, 2
	lda xwa, (xwa+600)
	ld xhl, 0x69800
	add xhl, xwa
	sub xhl, xbc
	ret

HelpStsP4Check_ReturnZero:
	ld xhl, 0:i3
	ret

HelpMenuCheck:
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr nz, HelpMenuCheck_ReturnZero
	ld xhl, 0x988000
	ret

HelpMenuCheck_ReturnZero:
	ld xhl, 0:i3
	ret

HelpLangChkFunc:
	push xiz
	ld xiz, xde
	cp xbc, EVT_HIDE
	jr z, HelpLangChk_CheckIzZero
	cp xbc, EVT_SHOW
	jr nz, HelpLang_ReturnZero
	ld xwa, NAKA_MAINFUNC_HelpLangChkMain
	ld xde, xiz
	call MainPostEvent
	jr HelpLang_ReturnZero

HelpLangChk_CheckIzZero:
	or	xiz, xiz
	jr	nz, HelpLang_ReturnZero
	call	GetTitleNow
	cp	xhl, TITLE_SWHELP
	jr	z, HelpLang_ReturnZero
	ld	wa, 4:i3
	call	PanelDisplay_DispatchByMode
	cp	hl, 0:i3
	jr	z, HelpLang_ReturnZero
	ld	xwa, 4294967295
	ld	xbc, EVT_SET_NOT_DRAW_FLAG
	ld	xde, 1:i3
	call	SendEvent
	ld	xwa, 4294967295
	ld	xbc, EVT_SET_NOT_DRAW_FLAG
	ld	xde, 0:i3
	call	PostEvent
	ld	(32422:16), 72
	ld	xwa, 4294967295
	ld	xbc, EVT_INTERRUPT_TITLE
	ld	xde, TITLE_MESAGE
	call	PostEvent
	ld	xwa, NAKA_MAINFUNC_HelpFlashFunc
	ld	xbc, EVT_KUBO_FLASH_LOAD
	ld	xde, xiz
	call	MainFuncCall
HelpLang_ReturnZero:
	ld xhl, 0:i3
	pop xiz
	ret

EdMenuPageFunc:
	cp xbc, EVT_SHOW
	jr nz, HelpFuncCheck_Return
	or xde, xde
	jr nz, HelpFuncCheck_Return
	call GetTitleOld
	cp xhl, TITLE_SQMENU
	jr nz, HelpFuncCheck_Return
	ld xwa, 0x930002
	ld xbc, EVT_SET_PAGE
	ld xde, 1:i3
	call SendEvent

HelpFuncCheck_Return:
	ld xhl, 0:i3
	ret

HelpFuncChkFunc:
	push xiz
	ld xiz, xde
	cp xbc, EVT_HIDE
	jr z, HelpFunc_CheckIzZero
	cp xbc, EVT_SHOW
	jrl nz, HelpFunc_ReturnZero
	or xiz, xiz
	jrl nz, HelpFunc_ReturnZero
	ld xwa, HelpFuncChkFunc_Data
	ld xbc, EVT_SET_PAGE
	ld xde, 1:i3
	call SendEvent
	ld xwa, HelpFuncChkFunc_Data_2
	ld xbc, EVT_SET_PAGE
	ld xde, 1:i3
	call SendEvent
	ld xwa, HelpFuncChkFunc_Data_3
	ld xbc, EVT_SET_PAGE
	ld xde, 1:i3
	call SendEvent
	jr HelpFunc_ReturnZero

HelpFunc_CheckIzZero:
	or	xiz, xiz
	jr	nz, HelpFunc_ReturnZero
	call	GetTitleNow
	cp	xhl, TITLE_SWHELP
	jr	z, HelpFunc_ReturnZero
	ld	wa, 4:i3
	call	PanelDisplay_DispatchByMode
	cp	hl, 0:i3
	jr	z, HelpFunc_ReturnZero
	ld	xwa, 4294967295
	ld	xbc, EVT_SET_NOT_DRAW_FLAG
	ld	xde, 1:i3
	call	SendEvent
	ld	xwa, 4294967295
	ld	xbc, EVT_SET_NOT_DRAW_FLAG
	ld	xde, 0:i3
	call	PostEvent
	ld	(32422:16), 72
	ld	xwa, 4294967295
	ld	xbc, EVT_INTERRUPT_TITLE
	ld	xde, TITLE_MESAGE
	call	PostEvent
	ld	xwa, NAKA_MAINFUNC_HelpFlashFunc
	ld	xbc, EVT_KUBO_FLASH_LOAD
	ld	xde, xiz
	call	MainFuncCall
HelpFunc_ReturnZero:
	ld xhl, 0:i3
	pop xiz
	ret

HelpOkSwFunc:
	cp xbc, EVT_SW_IN
	jr nz, HelpFunc_ReturnZero2
	ld xwa, NAKA_MAINFUNC_HelpFlashFunc
	ld xbc, EVT_KUBO_FLASH_WRITE
	call MainFuncCall

HelpFunc_ReturnZero2:
	ld xhl, 0:i3
	ret

HelpTtlProc:
	lda xsp, (xsp - 74)
	push xiz
	ld xiz, xwa
	cp xbc, EVT_DRAW
	jr z, HelpTtlProc_HandleActivation
	cp xbc, EVT_SHOW
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
	ld xbc, EVT_GET_RAM_ADDRESS
	ld xde, 0:i3
	call ApFuncCall
	lda xde, (xsp + 56)
	ld (xde), xhl
	lda xwa, (xsp + 8)
	ld (xde + 18), xwa
	ld xwa, (xiz + 32)
	ld xbc, EVT_GET_RAM_STRING
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
	ld xbc, 0x5b
	ld de, 0:i3
	call DrawTitleBar
	ld xhl, 0:i3

HelpTtl_Epilogue:
	pop xiz
	lda xsp, (xsp + 74)
	ret

HelpTtlFunc:
	push xiz
	ld xiz, xwa
	cp xbc, EVT_GET_RAM_STRING
	jr z, HelpTtlFunc_DecrementPage
	cp xbc, EVT_GET_RAM_ADDRESS
	jr z, HelpTtlFunc_LoadPageCount
	ld xhl, 0:i3
	jr HelpTtlFunc_Epilogue

HelpTtlFunc_LoadPageCount:
	ld xhl, 0:i3
	ld l, (0x296e:16)
	jr HelpTtlFunc_Epilogue

HelpTtlFunc_DecrementPage:
	ld a, (0x296e:16)
	extz wa
	dec 1, wa
	cp wa, 0:i3
	jr lt, HelpTtlFunc_ClampMin
	cp wa, 0x30
	jr le, HelpTtlFunc_LookupSlide

HelpTtlFunc_ClampMin:
	ldw wa, 0x31

HelpTtlFunc_LookupSlide:
	sll	wa, 2
	lda	xix, (HelpTtlFunc_LookupSlide_PtrTable:24)
	ld	xwa, (xix+wa)
	push	xwa
	ld	xwa, (xde+18)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	ld	xhl, xiz
HelpTtlFunc_Epilogue:
	pop xiz
	ret

IvSdrevProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, EVT_GET_STRING
	jr z, IvSdrev_CopyString
	cp xiz, EVT_DRAW
	jr z, IvSdrev_HandleFocus
	cp xiz, EVT_SHOW
	jr z, IvSdrev_CheckParam
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	jr IvSdrev_Epilogue

IvSdrev_CheckParam:
	ld	xwa, (xsp+4)
	cp	xwa, 4
	jr	z, MasterParam_Return
	cp	xwa, 3
	jr	nz, MasterParam_Return
	ld	xwa, 16386
	call	AcApcToggleProc_Helper
	cp	hl, 0:i3
	jr	nz, MasterParam_Return
	ld	xwa, 16386
	ldw	bc, 127
	ld	de, 3:i3
	call	MainLswPut
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
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	call SendEvent
	jr IvSdrev_ReturnZero

IvSdrev_CopyString:
	pushw	HelpTtlFunc_LookupSlide_PtrTable_Strings@hi16
	pushw	HelpTtlFunc_LookupSlide_PtrTable_Strings@lo16
	ld	xwa, (xsp+8)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
IvSdrev_ReturnZero:
	ld xhl, 0:i3

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
	cp xwa, EVT_GET_STRING
	jrl z, IvSddsp_CopyString
	cp xwa, EVT_DRAW
	jr z, IvSddsp_HandleFocus
	cp xwa, EVT_SHOW
	jr z, IvSddsp_CheckParam
	ld xwa, (xsp + 10)
	ld xbc, (xsp + 6)
	ld xde, (xsp + 2)
	call InheritedProc
	jr IvSddsp_Epilogue

IvSddsp_CheckParam:
	ld	xwa, (xsp+2)
	cp	xwa, 4
	jr	z, FilterParam_Return
	cp	xwa, 3
	jr	nz, FilterParam_Return
	call	GetPartSelect
	ld	iz, hl
	ld	wa, iz
	ldw	bc, 93
	call	DkMdlyPly_CheckState_Helper
	cp	hl, 0:i3
	jr	nz, FilterParam_Return
	lda	xwa, (37105:16)
	ld	bc, iz
	extz	xbc
	add	xbc, xwa
	ld	e, (xbc)
	extz	de
	pushw	4
	ld	wa, iz
	ldw	bc, 93
	call	MainLswPartPut
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
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	call SendEvent
	jr IvSddsp_ReturnZero

IvSddsp_CopyString:
	pushw	IvSddsp_CopyString_Str_Dsp@hi16
	pushw	IvSddsp_CopyString_Str_Dsp@lo16
	ld	xwa, (xsp+6)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
IvSddsp_ReturnZero:
	ld xhl, 0:i3

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
	cp xiz, EVT_GET_STRING
	jr z, IvSdacc_CopyString
	cp xiz, EVT_DRAW
	jr z, IvSdacc_HandleFocus
	cp xiz, EVT_SHOW
	jr z, IvSdacc_CheckParam
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	jr IvSdacc_Epilogue

IvSdacc_CheckParam:
	ld	xwa, (xsp+4)
	cp	xwa, 4
	jr	z, OscillatorParam_Return
	cp	xwa, 3
	jr	nz, OscillatorParam_Return
	ld	xwa, 16388
	call	AcApcToggleProc_Helper
	cp	hl, 0:i3
	jr	nz, OscillatorParam_Return
	ld	xwa, 16388
	ld	bc, 1:i3
	ld	de, 3:i3
	call	MainLswPut
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
	ld xbc, EVT_PARA_DRAW
	ld xde, 0:i3
	call SendEvent
	jr IvSdacc_ReturnZero

IvSdacc_CopyString:
	pushw	IvSdacc_CopyString_Str_Acc@hi16
	pushw	IvSdacc_CopyString_Str_Acc@lo16
	ld	xwa, (xsp+8)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
IvSdacc_ReturnZero:
	ld xhl, 0:i3

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
	cp xwa, EVT_SW_IN
	jr z, IvPlayExit_CheckSendEvent
	cp xwa, EVT_GET_STRING
	jr z, IvPlayExit_CopyString
	ld xwa, xiz
	ld xbc, (xsp + 12)
	ld xde, (xsp + 8)
	jr IvPlayExit_CallInherited

IvPlayExit_CopyString:
	pushw	IvPlayExit_CopyString_Str_ExMD@hi16
	pushw	IvPlayExit_CopyString_Str_ExMD@lo16
	ld	xwa, (xsp+12)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	ld	xhl, 0:i3
	jr	IvPlayExit_Epilogue
IvPlayExit_CheckSendEvent:
	ld	xwa, xiz
	call	GetViewInstance
	ld	(xsp+4), xhl
	ld	xwa, xiz
	ld	xbc, EVT_CHECK_EDIT_SW
	ld	xde, (xsp+8)
	call	SendEvent
	or	xhl, xhl
	jr	z, IvPlayExit_PrepareInherited
	cp	(58098:16), 0
	jr	nz, IvPlayExit_ClearFlag
	ld	xwa, (xsp+4)
	ld	xde, (xwa+22)
	ld	xwa, 4294967295
	ld	xbc, EVT_CHANGE_MODE
	call	PostEvent
IvPlayExit_ClearFlag:
	ld	(58098:16), 0
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
	cp xiz, EVT_SW_IN
	jr z, IvPunchExit_CheckSendEvent
	cp xiz, EVT_GET_STRING
	jr z, IvPunchExit_CopyString
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	jr IvPunchExit_CallInherited

IvPunchExit_CopyString:
	pushw	IvPunchExit_CopyString_Str_ExPR@hi16
	pushw	IvPunchExit_CopyString_Str_ExPR@lo16
	ld	xwa, (xsp+8)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	ld	xhl, 0:i3
	jr	IvPunchExit_Epilogue
IvPunchExit_CheckSendEvent:
	ld xwa, (xsp + 8)
	ld xbc, EVT_CHECK_EDIT_SW
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jr z, IvPunchExit_PrepareInherited
	bit 2, (1057:16)
	jr nz, IvPunchExit_PrepareInherited
	ld xwa, 0xffffffff
	ld xbc, EVT_CHANGE_TITLE
	ld xde, TITLE_SQCMENU
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
	cp xiz, EVT_SW_IN
	jr z, IvAutoPunchExit_CheckSendEvent
	cp xiz, EVT_GET_STRING
	jr z, IvAutoPunchExit_CopyString
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	jr IvAutoPunchExit_CallInherited

IvAutoPunchExit_CopyString:
	pushw	IvAutoPunchExit_CopyString_Str_ExAP@hi16
	pushw	IvAutoPunchExit_CopyString_Str_ExAP@lo16
	ld	xwa, (xsp+8)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	ld	xhl, 0:i3
	jr	IvAutoPunchExit_Epilogue
IvAutoPunchExit_CheckSendEvent:
	ld xwa, (xsp + 8)
	ld xbc, EVT_CHECK_EDIT_SW
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jr z, IvAutoPunchExit_PrepareInherited
	cpw (0x28a8:16), 0
	jr z, IvAutoPunchExit_PostSceneEvent
	bit 2, (1057:16)
	jr nz, IvAutoPunchExit_PrepareInherited

IvAutoPunchExit_PostSceneEvent:
	ld xwa, 0xffffffff
	ld xbc, EVT_CHANGE_TITLE
	ld xde, TITLE_SQPUNCH
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
	cp xiz, EVT_YOU_ARE_SELECTED
	jrl z, AcIndexToggle_HandleDefault
	cp xiz, EVT_CHK_TOGGLE_EDIT_SW
	jrl z, AcIndexToggle_CheckNoteRange
	cp xiz, EVT_INDEX_SELECT
	jrl z, AcIndexToggle_HandleFocusLost
	cp xiz, EVT_SW_IN
	jr z, AcIndexToggle_HandleSelectEvent
	cp xiz, EVT_SHOW
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
	ld xbc, EVT_GET_LANG
	ld xde, 0:i3
	call ApFuncCall
	extz xhl
	ld wa, (xiz + 42)
	extz xwa
	sll xwa, 16
	ld xde, xwa
	add xde, xhl
	ld xwa, 0xffffffff
	ld xbc, EVT_YOU_ARE_SELECTED
	jrl SendNoteDeleteEvent

AcIndexToggle_HandleSelectEvent:
	ld xwa, (xsp + 12)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 12)
	call GetVisible
	cp hl, 0:i3
	jr z, AcIndexToggle_PrepareInherited
	ld xwa, (xsp + 12)
	ld xbc, EVT_CHK_TOGGLE_EDIT_SW
	ld xde, (xsp + 8)
	call SendEvent
	cp hl, 0:i3
	jr z, AcIndexToggle_PrepareInherited
	ld xwa, (xsp + 4)
	ld de, (xwa + 44)
	exts xde
	ld xwa, (xwa + 46)
	ld xbc, EVT_CHK_LANG
	call ApFuncCall
	or xhl, xhl
	jrl nz, SqedtNote_ReturnZero
	ld xwa, (xsp + 4)
	ld de, (xwa + 42)
	cp de, 0xffff
	jr z, AcIndexToggle_SendVisibility
	exts xde
	ld xwa, 0xffffffff
	ld xbc, EVT_INDEX_SELECT
	call SendEvent

AcIndexToggle_SendVisibility:
	ld xwa, (xsp + 12)
	ld xbc, EVT_SET_PARAM
	ld xde, 1:i3
	call SendEvent
	ld xwa, (xsp + 4)
	ld de, (xwa + 44)
	exts xde
	ld xwa, (xwa + 46)
	ld xbc, EVT_SET_LANG
	call ApFuncCall
	ld xwa, AcIndexToggle_SendVisibility_Data
	ld xbc, EVT_DRAW
	ld xde, 0:i3
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
	ld xbc, EVT_SET_PARAM
	ld xde, 0:i3
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
	ldfr_werp BC, 0xfa
	jr AcIndexToggle_SendNoteEvent

AcIndexToggle_SetFromDE:
	ld iz, bc
	ldfr_werp DE, 0xfa

AcIndexToggle_SendNoteEvent:
	ld xwa, 0x2600024
	ld xbc, EVT_MAKE_EDIT_SW_ID
	ld xde, (xsp + 8)
	call SendEvent
	cp hl, iz
	jr c, SqedtNote_ReturnZero
	cpw_erp HL, 0xfa
	jr ugt, SqedtNote_ReturnZero
	ld xhl, 1:i3
	jr AcIndexToggle_Epilogue

AcIndexToggle_HandleDefault:
	ld xwa, (xsp + 12)
	ld xbc, xiz
	ld xde, (xsp + 8)
	call InheritedProc
	ld xwa, (xsp + 12)
	call GetViewInstance
	lda xwa, (xhl + 42)
	cpw (xwa), 0xffff
	jr z, SqedtNote_ReturnZero
	ld xbc, (xsp + 8)
	srl xbc, 16
	ldiw_erp 0xe6, 0
	ld de, (xwa)
	ld wa, de
	cp wa, bc
	jr nz, SqedtNote_ReturnZero
	ld xwa, (xsp + 8)
	ld bc, (xhl + 44)
	cp bc, wa
	jr nz, SqedtNote_ReturnZero
	exts xde
	ld xwa, 0xffffffff
	ld xbc, EVT_INDEX_SELECT
	call SendEvent
	ld xwa, (xsp + 12)
	ld xbc, EVT_SET_PARAM
	ld xde, 1:i3

SendNoteDeleteEvent:
	call SendEvent

SqedtNote_ReturnZero:
	ld xhl, 0:i3

AcIndexToggle_Epilogue:
	pop xiz
	lda xsp, (xsp + 12)
	ret

AcIndexWideToggleFunc:
	ld a, e
	cp xbc, EVT_CHK_LANG
	jr z, AcIndexToggleFunc_CheckMatch
	cp xbc, EVT_SET_LANG
	jr z, AcIndexToggleFunc_StoreAndPost
	cp xbc, EVT_GET_LANG
	jr nz, AcIndexToggleFunc_ReturnZero
	ld xhl, 0:i3
	ld l, (0x0340e4:24)
	ret

AcIndexToggleFunc_StoreAndPost:
	ld (0x0340e4:24), a
	ld xwa, NAKA_MAINFUNC_HelpLangChkMain
	call MainPostEvent

AcIndexToggleFunc_ReturnZero:
	ld xhl, 0:i3
	ret

AcIndexToggleFunc_CheckMatch:
	cp a, (0x0340e4:24)
	scc16 z, hl
	extz xhl
	ret

AttAreYouSureCheck:
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr nz, AttModePreCheck_ReturnZero
	lda xhl, (AttAreYouSureCheck_PtrTable:24)
	ret

AttModePreCheck_ReturnZero:
	ld xhl, 0:i3
	ret

AttAttentionCheck:
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr nz, AttAttentionCheck_ReturnZero
	lda xhl, (AttAttentionCheck_PtrTable:24)
	ret

AttAttentionCheck_ReturnZero:
	ld xhl, 0:i3
	ret

StsSeqMenu1Check:
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr nz, StsSeqMenu1Check_ReturnZero
	lda xhl, (StsSeqMenu1Check_PtrTable:24)
	ret

StsSeqMenu1Check_ReturnZero:
	ld xhl, 0:i3
	ret

StsSeqMenu2Check:
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr nz, StsSeqMenu2Check_ReturnZero
	lda xhl, (StsSeqMenu2Check_PtrTable:24)
	ret

StsSeqMenu2Check_ReturnZero:
	ld xhl, 0:i3
	ret

StsEasyRec1Check:
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr nz, StsEasyRec1Check_ReturnZero
	lda xhl, (StsEasyRec1Check_PtrTable:24)
	ret

StsEasyRec1Check_ReturnZero:
	ld xhl, 0:i3
	ret

StsEasyRec2Check:
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr nz, StsEasyRec2Check_ReturnZero
	lda xhl, (StsEasyRec2Check_PtrTable:24)
	ret

StsEasyRec2Check_ReturnZero:
	ld xhl, 0:i3
	ret

StsPnlWrtCheck:
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr nz, StsPnlWrtCheck_ReturnZero
	lda xhl, (StsPnlWrtCheck_PtrTable:24)
	ret

StsPnlWrtCheck_ReturnZero:
	ld xhl, 0:i3
	ret

StsTrkClr1Check:
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr nz, StsTrkClr1Check_ReturnZero
	lda xhl, (StsTrkClr1Check_PtrTable:24)
	ret

StsTrkClr1Check_ReturnZero:
	ld xhl, 0:i3
	ret

StsTrkClr2Check:
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr nz, StsTrkClr2Check_ReturnZero
	lda xhl, (StsTrkClr2Check_PtrTable:24)
	ret

StsTrkClr2Check_ReturnZero:
	ld xhl, 0:i3
	ret

StsNtDrEditCheck:
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr nz, StsNtDrEditCheck_ReturnZero
	lda xhl, (StsNtDrEditCheck_PtrTable:24)
	ret

StsNtDrEditCheck_ReturnZero:
	ld xhl, 0:i3
	ret

AttTrkClrCheck:
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr nz, AttTrkClrCheck_ReturnZero
	lda xhl, (AttTrkClrCheck_PtrTable:24)
	ret

AttTrkClrCheck_ReturnZero:
	ld xhl, 0:i3
	ret

AttSongClrCheck:
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr nz, AttSongClrCheck_ReturnZero
	lda xhl, (AttSongClrCheck_PtrTable:24)
	ret

AttSongClrCheck_ReturnZero:
	ld xhl, 0:i3
	ret

StsAtPunchCheck:
	cp xbc, EVT_GET_LANGUAGE_PTR
	jr nz, StsAtPunchCheck_ReturnZero
	lda xhl, (StsAtPunchCheck_PtrTable:24)
	ret

StsAtPunchCheck_ReturnZero:
	ld xhl, 0:i3
	ret

MsgToTtlProc:
	cp xbc, EVT_SHOW
	jp nz, (InheritedProc:24)
	call InheritedProc
	call GetTitleOld
	cp xhl, TITLE_MESAGE
	jr nz, MsgToTtl_ReturnZero
	call CheckNotDrawFlag
	cp hl, 0:i3
	jr z, MsgToTtl_ReturnZero
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 1:i3
	call SendEvent
	ld xwa, 0xffffffff
	ld xbc, EVT_SET_NOT_DRAW_FLAG
	ld xde, 0:i3
	call PostEvent
	call GetTitleNow
	cp l, 0x90
	jr nz, MsgToTtl_CheckTitleAndPost
	ld xwa, 0xffffffff
	ld xbc, EVT_CHANGE_TITLE
	ld xde, TITLE_SQCMENU
	jr MsgToTtl_PostEvent

MsgToTtl_CheckTitleAndPost:
	call GetTitleNow
	add xhl, TITLE_PS
	ld xwa, 0xffffffff
	ld xbc, EVT_CHANGE_TITLE
	ld xde, xhl

MsgToTtl_PostEvent:
	call PostEvent

MsgToTtl_ReturnZero:
	ld xhl, 0:i3
	ret

NoteEditBoxProc:
	lda xsp, (xsp - 94)
	push xiz
	ld (xsp + 90), xde
	ld xiz, xbc
	ld (xsp + 94), xwa
	cp xiz, EVT_INDEXSW_DOWN
	jrl z, NoteEdit_FormatDispatch
	cp xiz, EVT_INDEXSW_UP
	jrl z, NoteEdit_FormatDispatch
	cp xiz, EVT_GRAPH_DRAW
	jrl z, NoteEditBox_GridDispatch2
	cp xiz, EVT_PARA_DRAW
	jr z, NoteEditBox_HandleFocusLost
	cp xiz, EVT_PAINT
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
	ld xwa, NAKA_MAINFUNC_NoteEditSyori
	ld xbc, xiz
	call MainPostEvent
	ld xwa, (xsp + 94)
	ld xbc, EVT_INDEXSW_UP
	ld xde, 0:i3
	call SetDialUp
	ld xwa, (xsp + 94)
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, 0:i3
	call SetDialDown
	ld wa, 1:i3
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
	ld xbc, EVT_GET_TTL_NOW
	ld xde, 0:i3
	call ApFuncCall
	ld xiy, (xsp + 12)
	cp l, (xiy + 30)
	jrl nz, NoteEdit_ReturnZero
	lda xix, (xsp + 28)
	ld xwa, NoteEditBox_HandleFocusLost_Table
	add xwa, (xsp + 90)
	ld a, (xwa)
	extz wa
	ld (xix), wa
	lda xbc, (xix + 2)
	ldw (xbc), 0xb9
	ld xwa, NoteEditBox_HandleFocusLost_Table_2
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
	ld xbc, EVT_GET_RAM_ADDRESS
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
	ld (xwa+), 0x00
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
	add xhl, NoteEditBox_SetupGrid_CaseTable
	ld hl, (xhl)
	lda xix, (NoteEditBox_EventDispatch1:24)
	jp	t, (xix+hl)
; NoteEditBoxProc event dispatch 1
NoteEditBox_EventDispatch1:
	ld	xwa, (xbc)
	ld	xbc, EVT_GET_HAKU_STRING
	jr	NoteEditBoxProc_SetupGridDisplay_Join
	ld	xwa, (xbc)
	ld	xbc, EVT_GET_POS_STRING
	jr	NoteEditBoxProc_SetupGridDisplay_Join
	ld	xwa, (xbc)
	ld	xbc, EVT_GET_NOTE_STRING
	jr	NoteEditBoxProc_SetupGridDisplay_Join
	ld	xwa, (xbc)
	ld	xbc, EVT_GET_VEL_STRING
	jr	NoteEditBoxProc_SetupGridDisplay_Join
	ld	xwa, (xbc)
	ld	xbc, EVT_GET_LEN_STRING
	jr	NoteEditBoxProc_SetupGridDisplay_Join
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+26)
	ld	xbc, EVT_GET_INC_STRING
	jr	NoteEditBoxProc_SetupGridDisplay_Join
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+26)
	ld	xbc, EVT_GET_INPUT_LEN_STRING
	jr	NoteEditBoxProc_SetupGridDisplay_Join
	ld	xwa, (xbc)
	ld	xbc, EVT_GET_INPUT_VEL_STRING
	jr	NoteEditBoxProc_SetupGridDisplay_Join

NoteEditBoxProc_SetupGridDisplay:
	ld xwa, (xsp + 12)
	ld xwa, (xwa + 26)
	ld xbc, EVT_KUBO_GET_MEAS_STRING
NoteEditBoxProc_SetupGridDisplay_Join:
	call ApFuncCall
	lda xwa, (xsp + 28)
	lda xbc, (xsp + 24)
	lda xde, (xsp + 36)
	ld xhl, 0:i3
	push xhl
	pushw 0xff
	pushw 0xf5
	call DrawStringLeftJustify
	jrl NoteEdit_ReturnZero

; NoteEditBox grid dispatch 2
NoteEditBox_GridDispatch2:
	ld xwa, (xsp + 94)
	call GetViewInstance
	ld (xsp + 12), xhl
	ld xwa, (xsp + 12)
	ld xwa, (xwa + 26)
	ld xbc, EVT_GET_TTL_NOW
	ld xde, 0:i3
	call ApFuncCall
	ld xwa, (xsp + 12)
	cp l, (xwa + 30)
	jrl nz, NoteEdit_ReturnZero
	ld xwa, (xsp + 90)
	dec 3, xwa
	cp xwa, 0x0
	jrl c, NoteEditBoxProc_ClassifyGridPosition
	cp xwa, 0xb
	jrl ugt, NoteEditBoxProc_ClassifyGridPosition
	add xwa, xwa
	add xwa, NoteEditBox_GridDispatch2_CaseTable
	ld wa, (xwa)
	lda xix, (NoteEditBox_EventDispatch2:24)
	jp	t, (xix+wa)
NoteEditBox_EventDispatch2:
	call	GetTitleNow
	ld	(xsp+10), 3
	cp	xhl, TITLE_SQNOTEEDT
	jr	nz, NoteEditBox_EventDispatch2_Skip
	ld	(xsp+10), 2
NoteEditBox_EventDispatch2_Skip:
	lda	xwa, (xsp+28)
	ld	c, (xsp+10)
	extz	bc
	sla	bc, 3
	lda	xde, (NoteEditBox_EventDispatch2_Table:24)
	lda	xde, (xde+bc)
	ld	bc, (xde)
	ld	(xwa), bc
	lda	xhl, (xwa+2)
	ld	bc, (xde+2)
	ld	(xhl), bc
	ld	bc, (xwa)
	add bc, (xde+4)
	ld	(xwa+4), bc
	ld	bc, (xhl)
	add bc, (xde+6)
	ld	(xwa+6), bc
	ld	bc, 0:i3
	ldw	de, 245
	call	DrawDesignBox
	call	GetTitleNow
	ld	(xsp+10), 7
	cp	xhl, TITLE_SQNOTEEDT
	jr	nz, NoteEditBox_EventDispatch2_Skip2
	ld	(xsp+10), 6
NoteEditBox_EventDispatch2_Skip2:
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+26)
	ld	xbc, EVT_GET_END_POS
	ld	xde, (xsp+90)
	call	ApFuncCall
	lda	xix, (xsp+28)
	ld	(xix), hl
	cpw (xix), 0
	jr	z, NoteEditBox_EventDispatch2_Skip3
	lda	xde, (xix+2)
	ld	a, (xsp+10)
	extz	wa
	sla	wa, 3
	lda	xbc, (NoteEditBox_EventDispatch2_Table:24)
	lda	xbc, (xbc+wa)
	ld	wa, (xbc+2)
	ld	(xde), wa
	ld	hl, (xix)
	add hl, (xbc+4)
	lda	xwa, (xix+4)
	ld	(xwa), hl
	ld	iy, (xde)
	add iy, (xbc+6)
	lda	xhl, (xix+6)
	ld	(xhl), iy
	ld	wa, (xwa)
	sub wa, (xix)
	exts	xwa
	divs	wa, 2
	ld	bc, (xix)
	add	bc, wa
	lda	xix, (xsp+24)
	ld	(xix), bc
	ld	bc, (xde)
	ld	wa, (xhl)
	sub	wa, bc
	exts	xwa
	divs	wa, 2
	add	bc, wa
	ld	(xix+2), bc
	pushw StsAtPunchCheck_PtrTable_Strings@hi16
	pushw StsAtPunchCheck_PtrTable_Strings@lo16
	lda	xwa, (xsp+40)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	lda	xwa, (xsp+28)
	lda	xbc, (xsp+24)
	lda	xde, (xsp+36)
	ld	xhl, 0:i3
	push	xhl
	pushw 251
	pushw 245
	call	DrawStringLeftJustify
NoteEditBox_EventDispatch2_Skip3:
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+26)
	ld	xbc, EVT_GET_TRI_POS
	ld	xde, (xsp+90)
	call	ApFuncCall
	lda	xix, (xsp+28)
	ld	(xix), hl
	lda	xde, (xix+2)
	ld	a, (xsp+10)
	extz	wa
	sla	wa, 3
	lda	xbc, (NoteEditBox_EventDispatch2_Table:24)
	lda	xbc, (xbc+wa)
	ld	wa, (xbc+2)
	ld	(xde), wa
	ld	hl, (xix)
	add hl, (xbc+4)
	lda	xwa, (xix+4)
	ld	(xwa), hl
	ld	iy, (xde)
	add iy, (xbc+6)
	lda	xhl, (xix+6)
	ld	(xhl), iy
	ld	wa, (xwa)
	sub wa, (xix)
	exts	xwa
	divs	wa, 2
	ld	bc, (xix)
	add	bc, wa
	lda	xix, (xsp+24)
	ld	(xix), bc
	ld	bc, (xde)
	ld	wa, (xhl)
	sub	wa, bc
	exts	xwa
	divs	wa, 2
	add	bc, wa
	ld	(xix+2), bc
	pushw NoteEditBox_EventDispatch2_Str_N81@hi16
	pushw NoteEditBox_EventDispatch2_Str_N81@lo16
	lda	xwa, (xsp+40)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	lda	xwa, (xsp+28)
	lda	xbc, (xsp+24)
	lda	xde, (xsp+36)
	ld	xhl, 0:i3
	push	xhl
	pushw 251
	pushw 245
	jrl	NoteEditBox_EventDispatch2_Join7
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+26)
	ld	xbc, EVT_GET_LINE_POS
	ld	xde, (xsp+90)
	call	ApFuncCall
	lda	xwa, (xsp+20)
	ld	(xwa), hl
	lda	xhl, (xwa+2)
	lda	xix, (NoteEditBox_EventDispatch2_Table:24)
	ld	bc, (xix+66)
	ld	(xhl), bc
	lda	xbc, (xsp+16)
	ld	de, (xwa)
	ld	(xbc), de
	ld	de, (xhl)
	add de, (xix+70)
	ld	(xbc+2), de
	ldw	de, 242
	call	DrawLine
	jrl	NoteEdit_ReturnZero
	ld	xwa, 9764884
	ld	xbc, EVT_DRAW
	ld	xde, (xsp+90)
	jr	NoteEditBox_EventDispatch2_Join
	ld	xwa, 9961489
	ld	xbc, EVT_DRAW
	ld	xde, (xsp+90)
NoteEditBox_EventDispatch2_Join:
	call	SendEvent
	jrl	NoteEdit_ReturnZero
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+26)
	ld	xbc, EVT_GET_MEAS_TOP_NUM_SV
	ld	xde, 0:i3
	call	ApFuncCall
	ld	(xsp+8), hl
	ldw	(xsp+10), 1
	ldib_erp	251, 0
NoteEditBox_EventDispatch2_Loop:
	ldto_berp	a, 251
	extz	wa
	add	wa, wa
	lda	xbc, (NoteEditBox_EventDispatch2_Table_2:24)
	ld	wa, (xbc+wa)
	ld	(xsp+28), wa
	ld	xde, 0:i3
	ldto_berp	e, 251
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+26)
	ld	xbc, EVT_GET_MEAS_CNG_SV
	call	ApFuncCall
	or	xhl, xhl
	jr	z, NoteEditBox_EventDispatch2_Skip5
	ld	xwa, 0:i3
	ld	(xsp+4), xwa
	lda	xwa, (xsp+28)
	ldw	(xwa+2), 32
	ldw	(xwa+6), 43
	cpib_erp	251, 0
	jr	nz, NoteEditBox_EventDispatch2_Skip4
	pushm (xsp+8)
	ld	xwa, FmtStr_pct3d
	jr	NoteEditBox_EventDispatch2_Join2
NoteEditBox_EventDispatch2_Skip4:
	ld	wa, (xsp+8)
	extz	xwa
	div	wa, 100
	ld	wa, qwa
	pushw	wa
	ld	(xsp+10), wa
	ld	xwa, NoteEditBox_EventDispatch2_Str
NoteEditBox_EventDispatch2_Join2:
	push	xwa
	lda	xwa, (xsp+42)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	incw	1, (xsp+8)
	ldw	(xsp+10), 2
	jr	NoteEditBox_EventDispatch2_Join3
NoteEditBox_EventDispatch2_Skip5:
	ld	xwa, 3:i3
	ld	(xsp+4), xwa
	lda	xwa, (xsp+28)
	ldw	(xwa+2), 33
	ldw	(xwa+6), 42
	pushm (xsp+10)
	pushw NoteEditBox_EventDispatch2_Str_Fmt2d@hi16
	pushw NoteEditBox_EventDispatch2_Str_Fmt2d@lo16
	lda	xwa, (xsp+42)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	incw	1, (xsp+10)
NoteEditBox_EventDispatch2_Join3:
	lda	xwa, (xsp+28)
	ld	bc, (xwa)
	add	bc, 32
	ld	(xwa+4), bc
	sub bc, (xwa)
	exts	xbc
	divs	bc, 2
	ld	de, (xwa)
	add	de, bc
	lda	xbc, (xsp+24)
	ld	(xbc), de
	ld	hl, (xwa+2)
	ld	de, (xwa+6)
	sub	de, hl
	exts	xde
	divs	de, 2
	add	hl, de
	ld	(xbc+2), hl
	lda	xde, (xsp+36)
	ld	xhl, (xsp+4)
	push	xhl
	pushw 255
	pushw 245
	call	DrawStringLeftJustify
	inc1b_erp	251
	cp_erpb	251, 11
	jrl	c, NoteEditBox_EventDispatch2_Loop
	jrl	NoteEdit_ReturnZero
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+26)
	ld	xbc, EVT_GET_MEAS_TOP_NUM_SV
	ld	xde, 0:i3
	call	ApFuncCall
	ld	(xsp+8), hl
	ldw	(xsp+10), 1
	ldib_erp	251, 0
NoteEditBox_EventDispatch2_Loop2:
	ldto_berp	a, 251
	extz	wa
	add	wa, wa
	lda	xbc, (NoteEditBox_EventDispatch2_Table_3:24)
	ld	wa, (xbc+wa)
	ld	(xsp+28), wa
	ld	xde, 0:i3
	ldto_berp	e, 251
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+26)
	ld	xbc, EVT_GET_MEAS_CNG_SV
	call	ApFuncCall
	lda	xde, (xsp+36)
	lda	xwa, (xsp+28)
	lda	xbc, (xwa+2)
	lda	xix, (xwa+6)
	or	xhl, xhl
	jr	z, NoteEditBox_EventDispatch2_Skip7
	ld	xwa, 0:i3
	ld	(xsp+4), xwa
	ldw	(xbc), 38
	ldw	(xix), 49
	cpib_erp	251, 0
	jr	nz, NoteEditBox_EventDispatch2_Skip6
	pushm (xsp+8)
	ld	xwa, NoteEditBox_EventDispatch2_Str_2
	jr	NoteEditBox_EventDispatch2_Join4
NoteEditBox_EventDispatch2_Skip6:
	ld	wa, (xsp+8)
	extz	xwa
	div	wa, 100
	ld	wa, qwa
	pushw	wa
	ld	(xsp+10), wa
	ld	xwa, NoteEditBox_EventDispatch2_Str_3
NoteEditBox_EventDispatch2_Join4:
	push	xwa
	push	xde
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	incw	1, (xsp+8)
	ldw	(xsp+10), 2
	jr	NoteEditBox_EventDispatch2_Join5
NoteEditBox_EventDispatch2_Skip7:
	ld	xwa, 3:i3
	ld	(xsp+4), xwa
	ldw	(xbc), 40
	ldw	(xix), 49
	pushm (xsp+10)
	pushw NoteEditBox_EventDispatch2_Str_Fmt2d_2@hi16
	pushw NoteEditBox_EventDispatch2_Str_Fmt2d_2@lo16
	push	xde
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	incw	1, (xsp+10)
NoteEditBox_EventDispatch2_Join5:
	lda	xwa, (xsp+28)
	ld	bc, (xwa)
	add	bc, 32
	ld	(xwa+4), bc
	sub bc, (xwa)
	exts	xbc
	divs	bc, 2
	ld	de, (xwa)
	add	de, bc
	lda	xbc, (xsp+24)
	ld	(xbc), de
	ld	hl, (xwa+2)
	ld	de, (xwa+6)
	sub	de, hl
	exts	xde
	divs	de, 2
	add	hl, de
	ld	(xbc+2), hl
	lda	xde, (xsp+36)
	ld	xhl, (xsp+4)
	push	xhl
	pushw 255
	pushw 245
	call	DrawStringLeftJustify
	inc1b_erp	251
	cp_erpb	251, 8
	jrl	c, NoteEditBox_EventDispatch2_Loop2
	jrl	NoteEdit_ReturnZero
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+26)
	ld	xbc, EVT_NOTE_BAR_DISP
	ld	xde, 0:i3
	jr	NoteEditBox_EventDispatch2_Join6
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+26)
	ld	xbc, EVT_NOTE_BAR_DISP2
	ld	xde, 0:i3
	jr	NoteEditBox_EventDispatch2_Join6
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+26)
	ld	xbc, EVT_NOTE_HILIGHT_DISP
	ld	xde, 0:i3
NoteEditBox_EventDispatch2_Join6:
	call	ApFuncCall
	jrl	NoteEdit_ReturnZero
	lda	xix, (xsp+28)
	ldw	(xix), 5
	lda	xbc, (xix+2)
	ldw	(xbc), 99
	lda	xde, (xix+4)
	ld	wa, (xix)
	add	wa, 16
	ld	(xde), wa
	lda	xhl, (xix+6)
	ld	wa, (xbc)
	inc	6, wa
	ld	(xhl), wa
	ld	wa, (xde)
	sub wa, (xix)
	exts	xwa
	divs	wa, 2
	ld	ix, (xix)
	add	ix, wa
	lda	xde, (xsp+24)
	ld	(xde), ix
	ld	bc, (xbc)
	ld	wa, (xhl)
	sub	wa, bc
	exts	xwa
	divs	wa, 2
	add	bc, wa
	ld	(xde+2), bc
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+26)
	ld	xbc, EVT_GET_RAM_ADDRESS
	ld	xde, (xsp+90)
	call	ApFuncCall
	lda	xde, (xsp+68)
	ld	(xde), xhl
	lda	xbc, (xsp+36)
	ld	(xde+18), xbc
	ld	xwa, xbc
	lda	xbc, (xbc+32)
NoteEditBox_EventDispatch2_Loop3:
	ld	(xwa+), 0
	cp	xwa, xbc
	jr	c, NoteEditBox_EventDispatch2_Loop3
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+26)
	ld	xbc, EVT_GET_KB1_STR
	call	ApFuncCall
	lda	xwa, (xsp+28)
	lda	xbc, (xsp+24)
	lda	xde, (xsp+36)
	ld	xhl, 3:i3
	push	xhl
	pushw 0
	pushw 255
	call	DrawStringLeftJustify
	lda	xhl, (xsp+28)
	lda	xbc, (xhl+2)
	ldw	(xbc), 155
	lda	xde, (xhl+6)
	ldw	(xde), 161
	ld	wa, (xhl+4)
	sub wa, (xhl)
	exts	xwa
	divs	wa, 2
	ld	ix, (xhl)
	add	ix, wa
	lda	xhl, (xsp+24)
	ld	(xhl), ix
	ld	bc, (xbc)
	ld	wa, (xde)
	sub	wa, bc
	exts	xwa
	divs	wa, 2
	add	bc, wa
	ld	(xhl+2), bc
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+26)
	ld	xbc, EVT_GET_RAM_ADDRESS
	ld	xde, (xsp+90)
	call	ApFuncCall
	lda	xde, (xsp+68)
	ld	(xde), xhl
	lda	xwa, (xsp+36)
	ld	(xde+18), xwa
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+26)
	ld	xbc, EVT_GET_KB2_STR
	call	ApFuncCall
	lda	xwa, (xsp+28)
	lda	xbc, (xsp+24)
	lda	xde, (xsp+36)
	ld	xhl, 3:i3
	push	xhl
	pushw 0
	pushw 255
NoteEditBox_EventDispatch2_Join7:
	call	DrawStringLeftJustify
	jrl	NoteEdit_ReturnZero
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+26)
	ld	xbc, EVT_GET_RAM_ADDRESS
	ld	xde, (xsp+90)
	call	ApFuncCall
	lda	xwa, (xsp+68)
	ld	(xwa), xhl
	lda	xbc, (xsp+36)
	ld	(xwa+18), xbc
	ld	xwa, xbc
	lda	xbc, (xbc+32)
NoteEditBox_EventDispatch2_Loop4:
	ld	(xwa+), 0
	cp	xwa, xbc
	jr	c, NoteEditBox_EventDispatch2_Loop4
	ld	(135318:24), 0
NoteEditBox_EventDispatch2_Loop5:
	lda	xix, (xsp+28)
	ldw	(xix), 2
	lda	xde, (xix+4)
	ld	wa, (xix)
	add	wa, 24
	ld	(xde), wa
	lda	xbc, (xix+2)
	ld	a, (135318:24)
	mul	a, 10
	add	a, 57
	extz	wa
	ld	(xbc), wa
	lda	xhl, (xix+6)
	inc	8, wa
	ld	(xhl), wa
	ld	wa, (xde)
	sub wa, (xix)
	exts	xwa
	divs	wa, 2
	ld	ix, (xix)
	add	ix, wa
	lda	xde, (xsp+24)
	ld	(xde), ix
	ld	bc, (xbc)
	ld	wa, (xhl)
	sub	wa, bc
	exts	xwa
	divs	wa, 2
	add	bc, wa
	ld	(xde+2), bc
	lda	xde, (xsp+68)
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+26)
	ld	xbc, EVT_GET_DR_NUM_STRING
	call	ApFuncCall
	lda	xbc, (xsp+24)
	ld	a, (135318:24)
	cp	a, (10144:16)
	jr	nz, NoteEditBox_EventDispatch2_Skip8
	lda	xwa, (xsp+28)
	lda	xde, (xsp+36)
	ld	xhl, 3:i3
	push	xhl
	pushw 255
	pushw 242
	jr	NoteEditBox_EventDispatch2_Join8
NoteEditBox_EventDispatch2_Skip8:
	lda	xwa, (xsp+28)
	lda	xde, (xsp+36)
	ld	xhl, 3:i3
	push	xhl
	pushw 0xf2	; colour pair for DrawStringLeftJustify, not a pointer
	pushw 0xff
NoteEditBox_EventDispatch2_Join8:
	call	DrawStringLeftJustify
	lda	xix, (xsp+28)
	ldw	(xix), 23
	lda	xde, (xix+4)
	ld	wa, (xix)
	add	wa, 70
	ld	(xde), wa
	lda	xbc, (xix+2)
	ld	a, (135318:24)
	mul	a, 10
	add	a, 57
	extz	wa
	ld	(xbc), wa
	lda	xhl, (xix+6)
	inc	8, wa
	ld	(xhl), wa
	ld	wa, (xde)
	sub wa, (xix)
	exts	xwa
	divs	wa, 2
	ld	ix, (xix)
	add	ix, wa
	lda	xde, (xsp+24)
	ld	(xde), ix
	ld	bc, (xbc)
	ld	wa, (xhl)
	sub	wa, bc
	exts	xwa
	divs	wa, 2
	add	bc, wa
	ld	(xde+2), bc
	lda	xde, (xsp+68)
	ld	xwa, (xsp+12)
	ld	xwa, (xwa+26)
	ld	xbc, EVT_GET_DR_NAME_STRING
	call	ApFuncCall
	lda	xwa, (xsp+28)
	lda	xbc, (xsp+24)
	lda	xde, (xsp+36)
	ld	xhl, 3:i3
	push	xhl
	pushw 0xf2	; colour pair for DrawStringLeftJustify, not a pointer
	pushw 0xff
	call	DrawStringLeftJustify
	ld	a, (135318:24)
	inc	1, a
	ld	(135318:24), a
	cp	a, 11
	jrl	ule, NoteEditBox_EventDispatch2_Loop5
	jrl	NoteEdit_ReturnZero
NoteEditBoxProc_ClassifyGridPosition:
	ld xwa, (xsp + 90)
	cp xwa, 0x2
	jr z, NoteEditGrid_CheckTitle95
	cp xwa, 0x1
	jr nz, NoteEditGrid_CheckTitle95Alt
	call GetTitleNow
	cp xhl, TITLE_SQNOTEEDT
	jr nz, NoteEditGrid_SetCoord3
	ld (xsp + 10), 0x2
	jr NoteEditGrid_LoadCoordinates

NoteEditGrid_SetCoord3:
	ld (xsp + 10), 0x3
	jr NoteEditGrid_LoadCoordinates

NoteEditGrid_CheckTitle95:
	call GetTitleNow
	cp xhl, TITLE_SQNOTEEDT
	jr nz, NoteEditGrid_SetCoord5
	ld (xsp + 10), 0x4
	jr NoteEditGrid_LoadCoordinates

NoteEditGrid_SetCoord5:
	ld (xsp + 10), 0x5
	jr NoteEditGrid_LoadCoordinates

NoteEditGrid_CheckTitle95Alt:
	call GetTitleNow
	ld (xsp + 10), 0x1
	cp xhl, TITLE_SQNOTEEDT
	jr nz, NoteEditGrid_LoadCoordinates
	ld (xsp + 10), 0x0

NoteEditGrid_LoadCoordinates:
	lda xwa, (xsp + 28)
	ld c, (xsp + 10)
	extz bc
	sla bc, 3
	lda xde, (NoteEditBox_EventDispatch2_Table:24)
	lda	xde, (xde+bc)
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
	ld bc, 0:i3
	ldw de, 0xf5
	call DrawDesignBox
	jrl NoteEdit_ReturnZero

; NoteEdit format dispatch
NoteEdit_FormatDispatch:
	ld xwa, (xsp + 94)
	ld xbc, xiz
	ld xde, (xsp + 90)
	call InheritedProc
	ld xwa, (xsp + 90)
	cp xwa, 0xe
	jr ugt, NoteEdit_FormatEntry
	ld xwa, NAKA_MAINFUNC_NoteEditSyori
	ld xbc, EVT_INDEXSW_UP
	call MainDeleteEvent
	ld xwa, NAKA_MAINFUNC_NoteEditSyori
	ld xbc, EVT_INDEXSW_DOWN
	call MainDeleteEvent
	ld xwa, NAKA_MAINFUNC_NoteEditSyori
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
	cp xwa, 0xb
	jr ugt, NoteEdit_ReturnZero
	add xwa, NoteEdit_FormatEntry_Table
	ld wa, (xwa)
	extz wa
	sll wa, 1
	ld xix, NoteEdit_FormatEntry_CaseTable
	ld	wa, (xix+wa)
	lda xix, (NoteEditBox_GridDispatch:24)
	jp	t, (xix+wa)

; NoteEditBoxProc grid check dispatch
NoteEditBox_GridDispatch:
	ld	xwa, (xsp+94)
	ld	xbc, EVT_INDEXSW_UP
	ld	xde, (xsp+90)
	call	SetDialUp
	ld	xwa, (xsp+94)
	ld	xbc, EVT_INDEXSW_DOWN
	ld	xde, (xsp+90)
	call	SetDialDown

NoteEdit_ReturnZero:
	ld xhl, 0:i3

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
	cp xbc, EVT_GET_TTL_NOW
	jrl z, NoteEdit_GetScreenId
	lda xhl, (NoteEditFunc_Table:24)
	cp xbc, EVT_GET_KB2_STR
	jrl z, NoteEdit_FormatNoteNameLow
	cp xbc, EVT_GET_KB1_STR
	jrl z, NoteEdit_FormatNoteNameHigh
	cp xbc, EVT_GET_RAM_ADDRESS
	jrl z, NoteEdit_GetParamValue
	cp xbc, EVT_GET_DR_NAME_STRING
	jrl z, NoteEdit_FormatChordNotes
	cp xbc, EVT_GET_DR_NUM_STRING
	jrl z, NoteEdit_FormatChordType
	cp xbc, EVT_KUBO_GET_MEAS_STRING
	jr z, NoteEdit_FormatTempo
	sub xwa, EVT_GET_END_POS
	cp xwa, 0x0
	jrl lt, NoteEdit_DefaultReturn
	cp xwa, 0xf
	jrl gt, NoteEdit_DefaultReturn
	add xwa, xwa
	add xwa, NoteEditFunc_CaseTable
	ld wa, (xwa)
	lda xix, (NoteEdit_FormatTempo:24)
	jp	t, (xix+wa)

NoteEdit_FormatTempo:
	ld	xiz, xde
	ld	wa, (10052:16)
	cp	wa, 999
	jr	ugt, NoteEdit_FormatTempoString
	pushw	wa
	pushw	NoteEditBox_SetupGrid_CaseTable_Strings@hi16
	pushw	NoteEditBox_SetupGrid_CaseTable_Strings@lo16
	ld	xwa, (xiz+18)
	push	xwa
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	jrl	NoteEdit_RestoreAndReturn
NoteEdit_FormatTempoString:
	pushw NoteEdit_FormatTempoString_Str_Star_Star_Star_Dot@hi16
	pushw NoteEdit_FormatTempoString_Str_Star_Star_Star_Dot@lo16
	ld	xwa, (xiz+18)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	jrl	NoteEdit_RestoreAndReturn
	ld	xiz, xde
	ld	wa, (10114:16)
	inc	1, wa
	pushw	wa
	ld	xwa, NoteEdit_FormatTempoString_Str
	jrl	NoteEdit_PushFormatAndCopy
	ld	xiz, xde
	pushm (0x2784:16)
	ld	xwa, NoteEdit_FormatTempoString_Str_2
	jrl	NoteEdit_PushFormatAndCopy
	ld	xiz, xde
	call	GetTitleNow
	ld	a, (10118:16)
	extz	wa
	cp	l, 149
	jr	nz, NoteEdit_FormatNoteOther
	pushw 9
	muls	wa, 9
	lda	xbc, (NoteEdit_FormatTempoString_Data:24)
	exts	xwa
	add	xwa, xbc
	push	xwa
	ld	xwa, (xiz+18)
	push	xwa
	call	CmpNamingCheck_Helper
	lda	xsp, (xsp+10)
	jrl	NoteEdit_RestoreAndReturn
NoteEdit_FormatNoteOther:
	pushw wa
	ld xwa, NoteEdit_FormatNoteOther_Str
	jrl NoteEdit_PushFormatAndCopy
	ld xiz, xde
	ld a, (0x2788:16)
	extz wa
	pushw wa
	ld xwa, NoteEdit_FormatNoteOther_Str_2
	jrl NoteEdit_PushFormatAndCopy
	ld xiz, xde
	ld a, (0x278a:16)
	extz wa
	pushw wa
	ld xwa, NoteEdit_FormatNoteOther_Str_3
	jrl NoteEdit_PushFormatAndCopy
	ld xiz, xde
	push_sd16w 0x8c, 0x27
	ld xwa, NoteEdit_FormatNoteOther_Str_4
	jrl NoteEdit_PushFormatAndCopy
	ld xiz, xde
	push_sd16w 0x8e, 0x27
	ld xwa, NoteEdit_FormatNoteOther_Str_5
	jrl NoteEdit_PushFormatAndCopy
	ld xiz, xde
	ld de, (0x2792:16)
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
	cp de, 0xc
	jr z, NoteEdit_GateTime0C
	ld xwa, (xbc)
	cp de, 0x8
	jr nz, NoteEdit_GateTimeNumeric
	pushw NoteEdit_FormatNoteOther_Str_ad_b8@hi16
	pushw NoteEdit_FormatNoteOther_Str_ad_b8@lo16
	push xwa
	jr NoteEdit_GateTimeStrcpy

NoteEdit_GateTime0C:
	ld xwa, NoteEdit_GateTime0C_Str
	jr NoteEdit_GateTimePushFormat

NoteEdit_GateTime10:
	ld xwa, NoteEdit_GateTime10_Str

NoteEdit_GateTimePushFormat:
	push xwa
	ld xwa, (xbc)
	push xwa
	jr NoteEdit_GateTimeStrcpy

NoteEdit_GateTime18:
	ld xwa, NoteEdit_GateTime18_Str
	jr NoteEdit_GateTimePushAndCopy

NoteEdit_GateTime20:
	ld xwa, NoteEdit_GateTime20_Str
	jr NoteEdit_GateTimePushAndCopy

NoteEdit_GateTime30:
	ld xwa, NoteEdit_GateTime30_Str
	jr NoteEdit_GateTimePushAndCopy

NoteEdit_GateTime60:
	ld xwa, NoteEdit_GateTime60_Str

NoteEdit_GateTimePushAndCopy:
	push xwa
	ld xwa, (xiz + 18)
	push xwa

NoteEdit_GateTimeStrcpy:
	call	Free_Compare2
	inc	8, xsp
	jrl	NoteEdit_RestoreAndReturn
NoteEdit_GateTimeNumeric:
	pushw de
	pushw NoteEdit_GateTimeNumeric_Str_Fmt2d@hi16
	pushw NoteEdit_GateTimeNumeric_Str_Fmt2d@lo16
	push xwa
	jr NoteEdit_CallAudioSendCmd

NoteEdit_FormatChordType:
	ld xiz, xde
	ld a, (0x279e:16)
	add a, (0x021096:24)
	extz wa
	pushw wa
	ld xwa, NoteEdit_FormatChordType_Str

NoteEdit_PushFormatAndCopy:
	push xwa
	ld xwa, (xiz + 18)
	push xwa

NoteEdit_CallAudioSendCmd:
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	jrl	NoteEdit_RestoreAndReturn
NoteEdit_FormatChordNotes:
	ld	xiz, xde
	pushw	10
	ld	xbc, 0:i3
	ld	c, (135318:24)
	ld	xwa, 0:i3
	ld	a, (10142:16)
	add	xwa, xbc
	ld	xbc, 13
	call	Math_MultiplyAccumulate
	add	xhl, (7508:16)
	push	xhl
	jrl	NoteEdit_DoStrncpy
NoteEdit_GetParamValue:
	dec 1, xde
	cp xde, 0x0
	jr c, NoteEdit_GetTempoValue
	cp xde, 0xd
	jr ugt, NoteEdit_GetTempoValue
	add xde, xde
	add xde, NoteEdit_GetParamValue_CaseTable
	ld de, (xde)
	lda xix, (NoteEdit_GetParamValue_Cases:24)
	jp	t, (xix+de)
; Case bodies of the `jp t, (xrr+rr)` switch in NoteEdit_GetParamValue (xde-1 = 0..13; word offsets at NoteEdit_GetParamValue_CaseTable): jp (xix + r) with xix = this
; label, so this label is the offset-0 case.  Formerly named as data; it is
; code.
NoteEdit_GetParamValue_Cases:
	ld	hl, (0x2782:16)
	extz	xhl
	jrl	NoteEdit_Epilogue
	ld	hl, (0x2784:16)
	extz	xhl
	jrl	NoteEdit_Epilogue
	ld	xhl, 0:i3
	ld	l, (0x2786:16)
	jrl	NoteEdit_Epilogue
	ld	hl, (0x2792:16)
	extz	xhl
	jrl	NoteEdit_Epilogue
	ld	xhl, 0:i3
	ld	l, (0x2798:16)
	jrl	NoteEdit_Epilogue
	ld	xhl, 0:i3
	ld	l, (0x279e:16)
	jrl	NoteEdit_Epilogue

NoteEdit_GetTempoValue:
	ld hl, (0x2744:16)
	extz xhl
	jr NoteEdit_Epilogue
	ld hl, (0x27b4:16)
	extz xhl
	jr NoteEdit_Epilogue
	ld hl, (0x27b6:16)
	extz xhl
	jr NoteEdit_Epilogue
	ld hl, (0x27b8:16)
	extz xhl
	jr NoteEdit_Epilogue
	ld hl, (0x27b2:16)
	extz xhl
	jr NoteEdit_Epilogue
	extz de
	lda xbc, (0x27a4:16)
	extz xde
	add xde, xbc
	ld xhl, 0:i3
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
	ld a, (0x2798:16)
	inc 1, a
	jr NoteEdit_CopyNoteName

NoteEdit_FormatNoteNameLow:
	ld xiz, xde
	pushw 0x6
	ld a, (0x2798:16)

NoteEdit_CopyNoteName:
	extz wa
	muls wa, 0x6
	exts xwa
	add xwa, xhl
	push xwa

NoteEdit_DoStrncpy:
	ld	xwa, (xiz+18)
	push	xwa
	call	CmpNamingCheck_Helper
	lda	xsp, (xsp+10)
NoteEdit_RestoreAndReturn:
	ld xhl, (xsp + 4)
	jr NoteEdit_Epilogue

NoteEdit_GetScreenId:
	call GetTitleNow
	ld h, 0x0:opc
	extz xhl
	jr NoteEdit_Epilogue

NoteEdit_DefaultReturn:
	ld xhl, 0:i3

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
	cp xiz, EVT_INDEXSW_DOWN
	jr z, SngSel2_HandleTimerResetEvent
	cp xiz, EVT_INDEXSW_UP
	jr z, SngSel2_HandleTimerResetEvent
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	jr SngSel2_Epilogue

SngSel2_HandleTimerResetEvent:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	call InheritedProc
	ld xwa, EVT_HIDE
	push xwa
	ld xwa, 0:i3
	push xwa
	ld xwa, 0xc8
	ld xbc, (xsp + 16)
	ld xde, 0x810016
	call ResetApTimer
	ld xwa, 0x810011
	ld xbc, xiz
	ld xde, (xsp + 4)
	call SendEvent
	ld xhl, 0:i3

SngSel2_Epilogue:
	pop xiz
	inc 8, xsp
	ret

SngSelProc:
	lda xsp, (xsp - 78)
	push xiz
	ld (xsp + 74), xde
	ld xiz, xbc
	ld (xsp + 78), xwa
	cp xiz, EVT_INDEXSW_DOWN
	jrl z, SngSel_HandleScrollEvent
	cp xiz, EVT_INDEXSW_UP
	jrl z, SngSel_HandleScrollEvent
	cp xiz, EVT_PARA_DRAW
	jr z, SngSel_HandleEventF
	cp xiz, EVT_PAINT
	jr z, SngSel_HandleEventB
	ld xwa, (xsp + 78)
	ld xbc, xiz
	ld xde, (xsp + 74)
	call InheritedProc
	jrl SngSel_Epilogue

SngSel_HandleEventB:
	ld xwa, (xsp + 78)
	ld xbc, xiz
	ld xde, (xsp + 74)
	call InheritedProc
	ld xde, (xsp + 78)
	ld xwa, NAKA_MAINFUNC_SngSelSyori
	ld xbc, xiz
	call MainPostEvent
	jrl StringDraw_CleanupAndReturn

SngSel_HandleEventF:
	ld xwa, (xsp + 78)
	ld xbc, xiz
	ld xde, (xsp + 74)
	call InheritedProc
	ld xwa, (xsp + 78)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 30)
	ld xbc, EVT_GET_TTL_NOW
	ld xde, 0:i3
	call ApFuncCall
	ld xwa, (xsp + 4)
	cp l, (xwa + 34)
	jrl nz, StringDraw_CleanupAndReturn
	ld xwa, (xwa + 30)
	ld xbc, EVT_GET_RAM_ADDRESS
	ld xde, 0:i3
	call ApFuncCall
	lda xde, (xsp + 52)
	ld (xde), xhl
	lda xwa, (xsp + 20)
	ld (xde + 18), xwa
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 30)
	ld xbc, EVT_GET_RAM_STRING
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

SngSel_HandleScrollEvent:
	ld xwa, (xsp + 78)
	ld xbc, xiz
	ld xde, (xsp + 74)
	call InheritedProc
	ld xwa, (xsp + 74)
	cp xwa, 0x3
	jr nz, StringDraw_CleanupAndReturn
	ld xwa, NAKA_MAINFUNC_SngSelSyori
	ld xbc, xiz
	ld xde, 0:i3
	call MainPostEvent
	ld xwa, (xsp + 78)
	ld xbc, xiz
	ld xde, (xsp + 74)
	call SetAutoInc

StringDraw_CleanupAndReturn:
	ld xhl, 0:i3

SngSel_Epilogue:
	pop xiz
	lda xsp, (xsp + 78)
	ret

SngSelFunc:
	dec 4, xsp
	push xiz
	ld (xsp + 4), xwa
	cp xbc, EVT_GET_TTL_NOW
	jr z, SngSelFunc_GetTitleIndex
	cp xbc, EVT_GET_RAM_ADDRESS
	jr z, SngSelFunc_LoadTitleCount
	cp xbc, EVT_GET_RAM_STRING
	jr z, SngSelFunc_HandleEvent47
	ld xhl, 0:i3
	jr ReturnTitleOrZero

SngSelFunc_HandleEvent47:
	ld	xiz, xde
	pushw	NoteEditFunc_CaseTable_Strings@hi16
	pushw	NoteEditFunc_CaseTable_Strings@lo16
	ld	xwa, (xiz+18)
	push	xwa
	call	Free_Compare2
	ld	a, (65507:24)
	inc	1, a
	extz	wa
	pushw	wa
	pushw	SngSelFunc_HandleEvent47_Data@hi16
	pushw	SngSelFunc_HandleEvent47_Data@lo16
	ld	xwa, (xiz+18)
	inc	4, xwa
	push	xwa
	call	Sprintf_Locked
	lda	xbc, (xiz+18)
	ld	xwa, (xbc)
	ld	(xwa+6), 58
	pushw	16
	pushw	0
	pushw	62080
	ld	xwa, (xbc)
	inc	7, xwa
	push	xwa
	call	CmpNamingCheck_Helper
	lda	xsp, (xsp+28)
	ld	xwa, (xiz+18)
	ld	(xwa+23), 0
	ld	xhl, (xsp+4)
	jr	ReturnTitleOrZero
SngSelFunc_LoadTitleCount:
	ld xhl, 0:i3
	ld l, (0x00ffe3:24)
	jr ReturnTitleOrZero

SngSelFunc_GetTitleIndex:
	call GetTitleNow
	ld h, 0x0:opc
	extz xhl

ReturnTitleOrZero:
	pop xiz
	inc 4, xsp
	ret

PlySngSelFunc:
	ld	xhl, xwa
	cp	xbc, EVT_SW_IN
	jr	z, PlySngSel_HandleSelectEvent
	cp	xbc, EVT_HIDE
	jr	z, PlySngSel_HandleTimerEvent
	cp	xbc, EVT_SHOW
	jr	nz, PlaySong_ReturnZero
	ld	xwa, EVT_HIDE
	push	xwa
	ld	xwa, 0:i3
	push	xwa
	ld	xwa, 200
	ld	xbc, xhl
	ld	xde, 8454166
	call	SetApTimer
	ld	(58098:16), 1
	jr	PlaySong_ReturnZero
PlySngSel_HandleTimerEvent:
	call GetTitleNow
	cp xhl, TITLE_SQPLAY
	jr nz, PlySngSel_ClearFlagAndReturn
	ld xwa, 0x810012
	ld xbc, EVT_SHOW
	ld xde, 5:i3
	call SendEvent

PlySngSel_ClearFlagAndReturn:
	ld	(58098:16), 0
	jr	PlaySong_ReturnZero
PlySngSel_HandleSelectEvent:
	ld xwa, 0xc8
	cp xde, 0xf
	jr nz, PlySngSel_ResetTimerCommon
	ld xwa, 0:i3

PlySngSel_ResetTimerCommon:
	ld xbc, EVT_HIDE
	push xbc
	ld xbc, 0:i3
	push xbc
	ld xbc, xhl
	ld xde, 0x810016
	call ResetApTimer

PlaySong_ReturnZero:
	ld xhl, 0:i3
	ret

PlySngSel2Func:
	cp xbc, EVT_SW_IN
	jr nz, EntGrid_InitDispatch
	bit 2, (1057:16)
	jr nz, EntGrid_InitDispatch
	ld xwa, 0x810012
	ld xbc, EVT_HIDE
	ld xde, 5:i3
	call SendEvent
	ld xwa, 0x810016
	ld xbc, EVT_SHOW
	ld xde, 5:i3
	call SendEvent

; AcEntertainerGridBoxProc init dispatch
EntGrid_InitDispatch:
	ld xhl, 0:i3
	ret

AcEntertainerGridBoxProc:
	lda xsp, (xsp - 16)
	push xiz
	ld (xsp + 12), xde
	ld (xsp + 16), xbc
	ld xiz, xwa
	ld xbc, (xsp + 16)
	cp xbc, EVT_RET_EFF_PARA
	jrl z, EntGrid_CellAction2
	ld xwa, (xsp + 16)
	cp xwa, EVT_RET_EFF_FIX
	jrl z, EntGrid_CellAction1
	cp xwa, EVT_REQUEST_GRID_DRAW
	jrl z, EntGrid_CellSelect
	cp xwa, EVT_GET_FIXED_ROW_STR
	jrl z, EntGrid_PostReturn
	cp xwa, EVT_GET_FIXED_COL_STR
	jrl z, EntGrid_PostEvent
	cp xwa, EVT_SHOW
	jr z, AcEntertainer_EventDispatch
	sub xbc, EVT_INDEXSW_UP
	cp xbc, 0x0
	jrl lt, EntGrid_CellAction3
	cp xbc, 0x6
	jrl gt, EntGrid_CellAction3
	add xbc, xbc
	add xbc, AcEntertainerGridBoxProc_CaseTable
	ld bc, (xbc)
	lda xix, (AcEntertainer_EventDispatch:24)
	jp	t, (xix+bc)

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
	ld xbc, EVT_GET_SELECTED_CEL
	ld xde, 0:i3
	call SendEvent
	ld (xsp + 4), xhl
	ld xde, xiz
	ld xwa, NAKA_MAINFUNC_EffEditMain
	ld xbc, EVT_PAINT
EntGrid_PostMainEvent:
	call MainPostEvent
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 16
	ldiw_erp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, xiz
	ld xbc, EVT_INDEXSW_UP
	call SetDialUp
	ld xwa, (xsp + 8)
	ld bc, (xwa + 26)
	ld xwa, (xsp + 4)
	srl xwa, 16
	ldiw_erp 0xe2, 0
	add wa, bc
	ld de, wa
	extz xde
	ld xwa, xiz
	ld xbc, EVT_INDEXSW_DOWN
	call SetDialDown
	ld wa, 1:i3
	call SetDialEnable
	ld (0x02109e:24), 0x00
	jrl Entertainer_ReturnZeroJmp
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	ld xbc, EVT_CHECK_INDEX
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, EntGrid_CheckOverflow1
	ld xwa, xiz
	ld xbc, EVT_GET_SELECTED_CEL
	ld xde, 0:i3
	call SendEvent
	ld wa, hl
	add wa, wa
	lda xbc, (EntGrid_PostMainEvent_Table:24)
	ld	wa, (xbc+wa)
	sub hl, wa
	extz xhl
	add xhl, 0xffff0000
	ld xwa, xiz
	ld xbc, EVT_SELE_DRAW
	ld xde, xhl
	call SendEvent
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	jrl Entertainer_ReturnZeroJmp

EntGrid_CheckOverflow1:
	ld xwa, xiz
	ld xbc, EVT_CHECK_GRID_INDEX
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
	ld xbc, EVT_INDEXSW_UP
	ld xde, (xsp + 12)
	call SetDialUp
	ld xwa, xiz
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, (xsp + 12)
	call SetDialDown
	ld wa, 1:i3
	jrl EntGrid_SetDialEnable
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc
	ld xwa, xiz
	ld xbc, EVT_CHECK_INDEX
	ld xde, (xsp + 12)
	call SendEvent
	or xhl, xhl
	jr z, EntGrid_CheckOverflow2
	ld xwa, xiz
	ld xbc, EVT_GET_SELECTED_CEL
	ld xde, 0:i3
	call SendEvent
	ld wa, hl
	add wa, wa
	lda xbc, (EntGrid_PostMainEvent_Table_2:24)
	ld	wa, (xbc+wa)
	add wa, hl
	ld de, wa
	extz xde
	add xde, 0xffff0000
	ld xwa, xiz
	ld xbc, EVT_SELE_DRAW
	call SendEvent
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call SetAutoInc
	jrl Entertainer_ReturnZeroJmp

EntGrid_CheckOverflow2:
	ld xwa, xiz
	ld xbc, EVT_CHECK_GRID_INDEX
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
	ld xbc, EVT_INDEXSW_UP
	ld xde, (xsp + 12)
	call SetDialUp
	ld xwa, xiz
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, (xsp + 12)
	call SetDialDown
	ld wa, 1:i3

EntGrid_SetDialEnable:
	call SetDialEnable
	jr Entertainer_ReturnZeroJmp

; Entertainer grid post event
EntGrid_PostEvent:
	ld xwa, xiz
	ld xiz, 0x3e
	jr EntGrid_GetViewAndCopy

; Entertainer grid post return
EntGrid_PostReturn:
	ld xwa, xiz
	ld xiz, 0x42

EntGrid_GetViewAndCopy:
	call	GetViewInstance
	add	xhl, xiz
	ld	xwa, (xhl)
	push	xwa
	ld	xwa, (xsp+16)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	jr	Entertainer_ReturnZeroJmp
	ld	xwa, xiz
	call	GetViewInstance
	ld	xwa, (xhl+70)
	ld	xbc, (xsp+16)
	ld	xde, (xsp+12)
	jr	CallApFuncPath
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
	ld xhl, 0:i3
	jr EntGrid_Epilogue

; Entertainer grid cell action 3
EntGrid_CellAction3:
	ld xwa, xiz
	ld xbc, (xsp + 16)
	ld xde, (xsp + 12)
	call InheritedProc

EntGrid_Epilogue:
	pop xiz
	lda xsp, (xsp + 16)
	ret

EntertainerGridCheck:
	lda xsp, (xsp - 62)
	push xiz
	ld (xsp + 58), xde
	ld (xsp + 62), xbc
	ld xiy, EntertainerGridCheck_LocalInit
	lda xix, (xsp + 48)
	ld bc, 5:i3
	ldirw
	ld xiy, EntertainerGridCheck_Data
	lda xix, (xsp + 40)
	ld bc, 4:i3
	ldirw
	ld xde, (xsp + 62)
	ld (xsp + 20), xde
	lda xwa, (EntertainerGridCheck_Data_3:24)
	ld (xsp + 12), xwa
	lda xwa, (EntertainerGridCheck_Data_2:24)
	ld (xsp + 8), xwa
	lda xwa, (NakaData_WidgetDescriptors:24)
	ld (xsp + 4), xwa
	lda xwa, (xsp + 48)
	ld (xsp + 28), xwa
	lda xbc, (xsp + 40)
	lda xwa, (0x2978:16)
	ld (xsp + 24), xwa
	lda xwa, (xbc + 2)
	ld (xsp + 36), xwa
	lda xwa, (xbc + 4)
	ld (xsp + 32), xwa
	cp xde, EVT_RET_EFF_PARA
	jrl z, EntGridCheck_Default
	lda xwa, (DspEffectName_PtrTable:24)
	ld (xsp + 16), xwa
	cp xde, EVT_RET_EFF_FIX
	jrl z, EntGridCheck_Return
	ld xwa, xde
	cp xwa, EVT_REQUEST_GRID_DRAW
	jrl z, EntGridCheck_Handler
	ld xwa, (xsp + 20)
	sub xwa, EVT_INDEXSW_UP
	cp xwa, 0x0
	jrl lt, SndParam_ReturnZero
	cp xwa, 0x6
	jrl gt, SndParam_ReturnZero
	add xwa, xwa
	add xwa, EntertainerGridCheck_CaseTable
	ld wa, (xwa)
	lda xix, (SndParam_Dispatch:24)
	jp	t, (xix+wa)
SndParam_Dispatch:
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, EVT_GET_SELECTED_CEL
	ld	xde, 0:i3
	call	SendEvent
	ld	(xsp+58), xhl
	lda	xbc, (xsp+40)
	ld	xwa, (xsp+58)
	srl	xwa, 16
	ld	qwa, 0
	ld	(xbc), wa
	ld	xde, (xsp+58)
	ld	(xbc+2), de
	cpw (xbc), 1
	jrl	nz, SndParam_ReturnZero
	ld	wa, de
	cp	wa, 0:i3
	jrl	mi, SndParam_ReturnZero
	cp	wa, 8
	jrl	gt, SndParam_ReturnZero
	add	wa, wa
	lda	xix, (SndParam_Dispatch_PtrTable_2:24)
	ld	wa, (xix+wa)
	lda	xix, (SndParam_Dispatch_Code:24)
	jp	t, (xix+wa)
SndParam_Dispatch_Code:
	ld	xbc, (xsp+62)
	sla	de, 2
	cp	xbc, EVT_INDEXSW_UP_AIC
	jr	nz, SndParam_Dispatch_Skip
	lda	xbc, (SndParam_Dispatch_Table:24)
	ld	xwa, (xbc+de)
	ld	bc, 4:i3
	ld	de, 4:i3
	jr	SndParam_Dispatch_Join
SndParam_Dispatch_Skip:
	lda	xbc, (SndParam_Dispatch_Table:24)
	ld	xwa, (xbc+de)
	ld	bc, 1:i3
	ld	de, 4:i3
SndParam_Dispatch_Join:
	call	MainLswAdd
	jrl	SndParam_ReturnZero
	ld	xwa, NAKA_MAINFUNC_EffEditMain
	ld	xbc, EVT_CNG_EFF_TYPE
	ld	xde, 1:i3
	jrl	SndParam_Dispatch_Join3
	dec	5, de
	exts	xde
	add	xde, 256
	ld	xwa, NAKA_MAINFUNC_EffEditMain
	ld	xbc, EVT_CNG_EFF_PARA
	jrl	SndParam_Dispatch_Join3
	call	GetFocusObject
	ld	xwa, xhl
	ld	xbc, EVT_GET_SELECTED_CEL
	ld	xde, 0:i3
	call	SendEvent
	ld	(xsp+58), xhl
	lda	xbc, (xsp+40)
	ld	xwa, (xsp+58)
	srl	xwa, 16
	ld	qwa, 0
	ld	(xbc), wa
	ld	xhl, (xsp+58)
	ld	(xbc+2), hl
	cpw (xbc), 1
	jrl	nz, SndParam_ReturnZero
	ld	wa, hl
	cp	wa, 0:i3
	jrl	mi, SndParam_ReturnZero
	cp	wa, 8
	jrl	gt, SndParam_ReturnZero
	add	wa, wa
	lda	xix, (SndParam_Dispatch_PtrTable:24)
	ld	wa, (xix+wa)
	lda	xix, (SndParam_Dispatch_Code_2:24)
	jp	t, (xix+wa)
SndParam_Dispatch_Code_2:
	ld	xde, (xsp+62)
	sla	hl, 2
	lda	xwa, (SndParam_Dispatch_Table:24)
	ld	xwa, (xwa+hl)
	cp	xde, EVT_INDEXSW_DOWN_AIC
	jr	nz, SndParam_Dispatch_Skip2
	ldw	bc, 65532
	ld	de, 4:i3
	jr	SndParam_Dispatch_Join2
SndParam_Dispatch_Skip2:
	ldw	bc, 65535
	ld	de, 4:i3
SndParam_Dispatch_Join2:
	call	MainLswAdd
	jrl	SndParam_ReturnZero
	ld	xwa, NAKA_MAINFUNC_EffEditMain
	ld	xbc, EVT_CNG_EFF_TYPE
	ld	xde, 4294967295
	jr	SndParam_Dispatch_Join3
	dec	5, hl
	exts	xhl
	add	xhl, 4294967040
	ld	xwa, NAKA_MAINFUNC_EffEditMain
	ld	xbc, EVT_CNG_EFF_PARA
	ld	xde, xhl
SndParam_Dispatch_Join3:
	call	MainPostEvent
	jrl	SndParam_ReturnZero
	lda	xhl, (xsp+40)
	ldw	(xhl), 1
	lda	xde, (xhl+2)
	ldw	(xde), 0
	lda	xix, (SndParam_Dispatch_Table:24)
	ld	xiz, (xsp+58)
	jr	SndParam_Dispatch_Join4
SndParam_Dispatch_Loop:
	ld	iy, bc
	sla	iy, 2
	ld	xwa, (xiz)
	cp	xwa, (xix+iy)
	jr	z, SndParam_Dispatch_Skip3
	inc	1, bc
	ld	(xde), bc
SndParam_Dispatch_Join4:
	ld	bc, (xde)
	cp	bc, 9
	jr	lt, SndParam_Dispatch_Loop
SndParam_Dispatch_Skip3:
	lda	xbc, (xsp+48)
	ld	(xhl+4), xbc
	ld	xwa, (xsp+58)
	ld	xhl, (xwa)
	lda	xde, (xwa+4)
	cp	xhl, 16704
	jr	z, SndParam_Dispatch_Skip4
	cp	xhl, 16705
	jrl	nz, SndParam_ReturnZero
	pushm (xde)
	pushw EntertainerGridCheck_LocalInit_Strings@hi16
	pushw EntertainerGridCheck_LocalInit_Strings@lo16
	push	xbc
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+40)
	ld	xbc, EVT_GRID_DRAW
	jrl	SndParam_SendEventReturnZero
SndParam_Dispatch_Skip4:
	ld	xwa, SndParam_Dispatch_Str_2
	cpw (xde), 0
	jr	z, SndParam_Dispatch_Skip5
	ld	xwa, SndParam_Dispatch_Str
SndParam_Dispatch_Skip5:
	push	xwa
	push	xbc
	call	Free_Compare2
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+40)
	ld	xbc, EVT_GRID_DRAW
	jrl	SndParam_SendEventReturnZero
EntGridCheck_Handler:
	ld XWA,(XSP+0x3a)
	srl XWA, 16
	ld QWA,0
	ld (XBC),WA
	ld XHL,(XSP+0x24)
	ld XDE,(XSP+0x3a)
	ld XWA,(XSP+0x24)
	ld (XWA),DE
	ld XDE,(XSP+0x1c)
	ld (XSP+0x14),XDE
	ld XWA,(XSP+0x20)
	ld (XWA),XDE
	cpw (XBC), 0x0001
	jrl nz, SndParam_ReturnZero
	ld WA,(XHL)
	sla WA, 0x02
	lda xbc, (SndParam_Dispatch_Table:24)
	ld	xde, (xbc+wa)
	ld XBC,(XSP+0x18)
	cp XDE,0x00004e13
	jrl z, EntGridCheck_Handle4E13
	ld XHL,(XSP+0x14)
	lda xwa, (xhl + 0x01)
	ld (XSP+0x24),XWA
	lda xwa, (xhl + 0x02)
	ld (XSP+0x20),XWA
	ld XWA,XDE
	cp XDE,0x00004e12
	jrl z, EntGridCheck_Handle4E12
	cp XDE,0x00004e11
	jrl z, EntGridCheck_Handle4E11
	cp XDE,0x00004e10
	jrl z, EntGridCheck_Handle4E10
	cp XDE,0x00004e00
	jr z, EntGridCheck_Handle4E00
	cp XDE,0x00004140
	jr z, EntGridCheck_Handle4140
	cp XDE,0x00004141
	jrl nz, SndParam_ReturnZero
	call AcApcToggleProc_Helper
	pushw hl
	pushw EntGridCheck_Handler_Str_Fmt3d@hi16
	pushw EntGridCheck_Handler_Str_Fmt3d@lo16
	lda xwa, (xsp + 0x36)
	push XWA
	call Sprintf_Locked
	lda xsp, (xsp + 0x0a)
	call GetFocusObject
	ld XWA,XHL
	lda xde, (xsp + 0x28)
	ld XBC,EVT_GRID_DRAW
	jrl t, SndParam_SendEventReturnZero
EntGridCheck_Handle4140:
	call	AcApcToggleProc_Helper
	ld	xwa, EntGridCheck_Handle4140_Str_2
	cp	hl, 0:i3
	jr	z, EntGridCheck_CopyStringResult
	ld	xwa, EntGridCheck_Handle4140_Str
EntGridCheck_CopyStringResult:
	push	xwa
	lda	xwa, (xsp+52)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+40)
	ld	xbc, EVT_GRID_DRAW
	jrl	SndParam_SendEventReturnZero
EntGridCheck_Handle4E00:
	pushw	9
	ld	wa, (10614:16)
	extz	xwa
	sll	xwa, 2
	ld	xbc, (xsp+18)
	add	xbc, xwa
	ld	xwa, (xbc)
	push	xwa
	ld	xwa, (xsp+26)
	push	xwa
	call	CmpNamingCheck_Helper
	lda	xsp, (xsp+10)
	ld	(xsp+57), 0
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+40)
	ld	xbc, EVT_GRID_DRAW
	jrl	SndParam_SendEventReturnZero
EntGridCheck_Handle4E10:
	ld	xwa, (xsp+20)
	ld	(xwa), 32
	ld	xwa, (xsp+36)
	ld	(xwa), 32
	pushw	5
	ld	wa, (xbc)
	extz	xwa
	ld	xbc, xwa
	sll	xbc, 2
	add	xbc, xwa
	ld	xwa, (xsp+6)
	add	xwa, xbc
	push	xwa
	ld	xwa, (xsp+38)
	push	xwa
	call	CmpNamingCheck_Helper
	lda	xsp, (xsp+10)
	lda	xwa, (xsp+48)
	ld	(xwa+7), 115
	ld	(xwa+8), 32
	ld	(xwa+9), 0
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+40)
	ld	xbc, EVT_GRID_DRAW
	jrl	SndParam_SendEventReturnZero
EntGridCheck_Handle4E11:
	ld	xwa, (xsp+20)
	ld	(xwa), 32
	pushw	5
	ld	wa, (xbc+2)
	extz	xwa
	ld	xbc, xwa
	sll	xbc, 2
	add	xbc, xwa
	ld	xwa, (xsp+14)
	add	xwa, xbc
	push	xwa
	ld	xwa, (xsp+42)
	push	xwa
	call	CmpNamingCheck_Helper
	lda	xsp, (xsp+10)
	lda	xwa, (xsp+48)
	ld	(xwa+6), 72
	ld	(xwa+7), 122
	ld	(xwa+8), 32
	ld	(xwa+9), 0
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+40)
	ld	xbc, EVT_GRID_DRAW
	jrl	SndParam_SendEventReturnZero
EntGridCheck_Handle4E12:
	ld	xde, (xsp+20)
	ld	(xde), 32
	ld	xwa, (xsp+36)
	ld	(xwa), 32
	ld	xwa, (xsp+32)
	ld	(xwa), 32
	pushw	5
	ld	wa, (xbc+4)
	extz	xwa
	ld	xbc, xwa
	sll	xbc, 2
	add	xbc, xwa
	ld	xwa, (xsp+10)
	add	xwa, xbc
	push	xwa
	lda	xwa, (xde+3)
	push	xwa
	call	CmpNamingCheck_Helper
	lda	xsp, (xsp+10)
	lda	xwa, (xsp+48)
	ld	(xwa+8), 32
	ld	(xwa+9), 0
	call	GetFocusObject
	ld	xwa, xhl
	lda	xde, (xsp+40)
	ld	xbc, EVT_GRID_DRAW
	jrl	SndParam_SendEventReturnZero
EntGridCheck_Handle4E13:
	pushm (xbc + 6)

	pushw 0xe3

	pushw 0x47ba

	ld xwa, (xsp + 26)

	push xwa

	call	Sprintf_Locked

	lda xsp, (xsp + 10)

	call	GetFocusObject

	ld xwa, xhl

	lda xde, (xsp + 40)

	ld xbc, EVT_GRID_DRAW
	jrl SndParam_SendEventReturnZero	; jrl SndParam_SendEventReturnZero (v7 displacement)




; EntertainerGridCheck return

EntGridCheck_Return:
	ldw (xbc), 0x1

	ld xwa, (xsp + 36)

	ldw (xwa), 0x4

	ld xwa, (xsp + 32)

	ld xde, (xsp + 28)

	ld (xwa), xde

	pushw 0x9

	ld wa, (0x2976:16)

	extz xwa

	sll xwa, 2

	ld xbc, (xsp + 18)

	add xbc, xwa

	ld xwa, (xbc)

	push xwa

	push xde

	call	CmpNamingCheck_Helper

	lda xsp, (xsp + 10)

	ld (xsp + 57), 0x0

	call	GetFocusObject

	ld xwa, xhl

	lda xde, (xsp + 40)

	ld xbc, EVT_GRID_DRAW
	jrl SndParam_SendEventReturnZero	; jrl SndParam_SendEventReturnZero (v7 displacement)




; EntertainerGridCheck default

EntGridCheck_Default:
	ldw (XBC), 0x0001
	ld XDE,(XSP+0x3a)
	ld BC,DE
	inc 5,BC
	ld XWA,(XSP+0x24)
	ld (XWA),BC
	ld XBC,(XSP+0x1c)
	ld (XSP+0x14),XBC
	ld XWA,(XSP+0x20)
	ld (XWA),XBC
	ld (XBC),0x20
	ld XWA,XBC
	inc 2,XWA
	ld (XSP+0x24),XWA
	cp XDE,0x00000003
	jrl z, EntGridCheck_SendAudioCommand
	ld XWA,(XSP+0x14)
	lda xbc, (xwa + 0x01)
	cp XDE,0x00000002
	jr z, EntGridCheck_DefaultCase2
	ld XWA,XDE
	cp XWA,0x00000001
	jr z, EntGridCheck_DefaultCase1
	or XWA,XWA
	jrl nz, SndParam_BuildDisplayEvent
	ld (XBC),0x20
	pushw 0x0005
	ld XWA,(XSP+0x1a)
	ld WA,(XWA)
	extz XWA
	ld XBC,XWA
	sll XBC, 0x02
	add XBC,XWA
	ld XWA,(XSP+0x06)
	add XWA,XBC
	push XWA
	ld XWA,(XSP+0x2a)
	push XWA
	call CmpNamingCheck_Helper
	lda xsp, (xsp + 0x0a)
	lda xwa, (xsp + 0x30)
	ld (XWA+0x07),0x73
	ld (XWA+0x08),0x20
	jr t, EntGridCheck_NullTerminate
EntGridCheck_DefaultCase1:
	pushw	5
	ld	xwa, (xsp+26)
	ld	wa, (xwa+2)
	extz	xwa
	ld	xde, xwa
	sll	xde, 2
	add	xde, xwa
	ld	xwa, (xsp+14)
	add	xwa, xde
	push	xwa
	push	xbc
	call	CmpNamingCheck_Helper
	lda	xsp, (xsp+10)
	lda	xwa, (xsp+48)
	ld	(xwa+6), 72
	ld	(xwa+7), 122
	ld	(xwa+8), 32
	jr	EntGridCheck_NullTerminate
EntGridCheck_DefaultCase2:
	ld	(xbc), 32
	ld	xwa, (xsp+36)
	ld	(xwa), 32
	pushw	5
	ld	xwa, (xsp+26)
	ld	wa, (xwa+4)
	extz	xwa
	ld	xbc, xwa
	sll	xbc, 2
	add	xbc, xwa
	ld	xwa, (xsp+10)
	add	xwa, xbc
	push	xwa
	ld	xwa, (xsp+26)
	inc	3, xwa
	push	xwa
	call	CmpNamingCheck_Helper
	lda	xsp, (xsp+10)
	lda	xwa, (xsp+48)
	ld	(xwa+8), 32
EntGridCheck_NullTerminate:
	ld (xwa + 9), 0x0
	jr SndParam_BuildDisplayEvent

EntGridCheck_SendAudioCommand:
	ld xwa, (xsp + 24)

	pushm (xwa + 6)

	pushw 0xe3

	pushw 0x47c4

	ld xwa, (xsp + 26)

	push xwa

	call Sprintf_Locked

	lda xsp, (xsp + 10)



SndParam_BuildDisplayEvent:
	call GetFocusObject
	ld xwa, xhl
	lda xde, (xsp + 40)
	ld xbc, EVT_GRID_DRAW

SndParam_SendEventReturnZero:
	call SendEvent

SndParam_ReturnZero:
	ld xhl, 0:i3
	pop xiz
	lda xsp, (xsp + 62)
	ret

IvSongCopyExitProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, EVT_SW_IN
	jr z, IvSongCopyExit_HandleSelectEvent
	cp xiz, EVT_GET_STRING
	jr z, IvSongCopyExit_CopyString
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	jr IvSongCopyExit_CallInherited

IvSongCopyExit_CopyString:
	pushw	EntertainerGridCheck_CaseTable_Strings@hi16
	pushw	EntertainerGridCheck_CaseTable_Strings@lo16
	ld	xwa, (xsp+8)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	ld	xhl, 0:i3
	jr	IvSongCopyExit_Epilogue
IvSongCopyExit_HandleSelectEvent:
	ld xwa, (xsp + 8)
	ld xbc, EVT_CHECK_EDIT_SW
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jr z, IvSongCopyExit_PrepareInherited
	call GetTitleNow
	cp xhl, TITLE_SQSNGCP
	jr nz, IvSongCopyExit_CheckTitleA8
	ld xwa, 0xffffffff
	ld xbc, EVT_CHANGE_TITLE
	ld xde, TITLE_SQEMENU
	jr IvSongCopyExit_PostEvent

IvSongCopyExit_CheckTitleA8:
	call GetTitleNow
	cp xhl, TITLE_SQSNGCPC
	jr nz, IvSongCopyExit_PrepareInherited
	ld xwa, 0xffffffff
	ld xbc, EVT_CHANGE_TITLE
	ld xde, TITLE_SQCMENU

IvSongCopyExit_PostEvent:
	call PostEvent

IvSongCopyExit_PrepareInherited:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)

IvSongCopyExit_CallInherited:
	call InheritedProc

IvSongCopyExit_Epilogue:
	pop xiz
	inc 8, xsp
	ret

IvPnlWrExitProc:
	dec 8, xsp
	push xiz
	ld (xsp + 4), xde
	ld xiz, xbc
	ld (xsp + 8), xwa
	cp xiz, EVT_SW_IN
	jr z, IvPnlWrExit_HandleSelectEvent
	cp xiz, EVT_GET_STRING
	jr z, IvPnlWrExit_CopyString
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)
	jr IvPnlWrExit_CallInherited

IvPnlWrExit_CopyString:
	pushw	IvPnlWrExit_CopyString_Str_ExMD@hi16
	pushw	IvPnlWrExit_CopyString_Str_ExMD@lo16
	ld	xwa, (xsp+8)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	ld	xhl, 0:i3
	jr	IvPnlWrExit_Epilogue
IvPnlWrExit_HandleSelectEvent:
	ld xwa, (xsp + 8)
	ld xbc, EVT_CHECK_EDIT_SW
	ld xde, (xsp + 4)
	call SendEvent
	or xhl, xhl
	jr z, IvPnlWrExit_PrepareInherited
	call GetTitleNow
	cp xhl, TITLE_SQPNLWR
	jr nz, IvPnlWrExit_CheckTitleAA
	ld xwa, 0xffffffff
	ld xbc, EVT_CHANGE_TITLE
	ld xde, TITLE_SQCMENU
	jr IvPnlWrExit_PostEvent

IvPnlWrExit_CheckTitleAA:
	call GetTitleNow
	cp xhl, TITLE_SQPNLWRM
	jr nz, IvPnlWrExit_PrepareInherited
	ld xwa, 0xffffffff
	ld xbc, EVT_CHANGE_TITLE
	ld xde, TITLE_SQMENU

IvPnlWrExit_PostEvent:
	call PostEvent

IvPnlWrExit_PrepareInherited:
	ld xwa, (xsp + 8)
	ld xbc, xiz
	ld xde, (xsp + 4)

IvPnlWrExit_CallInherited:
	call InheritedProc

IvPnlWrExit_Epilogue:
	pop xiz
	inc 8, xsp
	ret

SqplyValProc:
	lda xsp, (xsp - 70)
	pushw_erp 0xfa
	ld (xsp + 60), xde
	ld (xsp + 64), xbc
	ld (xsp + 68), xwa
	ld xwa, (xsp + 64)
	cp xwa, EVT_SW_IN
	jrl z, SqplyVal_HandleSelectEvent
	cp xwa, EVT_INDEXSW_DOWN
	jrl z, SqplyVal_HandleDownScrollEvent
	cp xwa, EVT_INDEXSW_UP
	jrl z, SqplyVal_HandleUpScrollEvent
	cp xwa, EVT_PARA_DRAW
	jrl z, SqplyVal_HandleScrollEvent
	cp xwa, EVT_PAINT
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
	ld xbc, EVT_SET_CUR_POS
	ld xde, 1:i3
	call ApFuncCall
	ld xwa, 0xffffffff
	ld xbc, EVT_SW_IN
	ld xde, 0x89
	call SendEvent
	ld xwa, (xsp + 68)
	ld xbc, EVT_INDEXSW_UP
	ld xde, 1:i3
	call SetDialUp
	ld xwa, (xsp + 68)
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, 1:i3
	call SetDialDown
	ld wa, 1:i3
	call SetDialEnable
	jr SqplyVal_DispatchUpdate

SqplyVal_CheckMode81:
	cp	l, 129
	jr	nz, SqplyVal_DispatchUpdate
	ld	xwa, 8454166
	ld	xbc, EVT_HIDE
	ld	xde, 5:i3
	call	SendEvent
	ld	xwa, 8454162
	ld	xbc, EVT_SHOW
	ld	xde, 5:i3
	call	SendEvent
	ld	(58098:16), 0
SqplyVal_DispatchUpdate:
	ld xde, (xsp + 68)
	ld xwa, NAKA_MAINFUNC_ApPlaySyori_Kubo
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
	ld xbc, EVT_GET_TTL_NOW
	ld xde, 0:i3
	call ApFuncCall
	ld xiy, (xsp + 6)
	cp l, (xiy + 30)
	jrl nz, SqplyVal_ReturnZero
	lda xhl, (xsp + 52)
	ld xwa, (xsp + 60)
	sll xwa, 3
	ld xde, SqplyVal_HandleScrollEvent_Table
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
	ld xbc, EVT_GET_RAM_ADDRESS
	ld xde, (xsp + 60)
	call ApFuncCall
	lda xde, (xsp + 10)
	ld (xde), xhl
	lda xhl, (xsp + 32)
	ld xwa, xhl
	lda xbc, (xhl + 16)

SqplyVal_ClearDrawBuffer:
	ld (xwa+), 0x00
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
	ld xbc, EVT_KUBO_GET_MEAS_STRING
	call ApFuncCall
	lda xwa, (xsp + 52)
	lda xbc, (xsp + 48)
	lda xde, (xsp + 32)
	ld xhl, 0:i3
	push xhl
	ld xhl, (xsp + 10)
	pushm (xhl + 22)
	pushm (xhl + 24)
	jr SqplyVal_CallDrawGrid

SqplyVal_RenderNoteGrid1:
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 26)
	ld xbc, EVT_GET_BEAT_STRING
	call ApFuncCall
	lda xwa, (xsp + 52)
	lda xbc, (xsp + 48)
	lda xde, (xsp + 32)
	ld xhl, 0:i3
	push xhl
	ld xhl, (xsp + 10)
	pushm (xhl + 22)
	pushm (xhl + 24)
	jr SqplyVal_CallDrawGrid

SqplyVal_RenderNoteGrid2:
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 26)
	ld xbc, EVT_GET_MEM_STRING
	call ApFuncCall
	lda xwa, (xsp + 52)
	lda xbc, (xsp + 48)
	lda xde, (xsp + 32)
	ld xhl, 0:i3
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
	add xhl, SqplyVal_HandleExtraParams_CaseTable
	ld hl, (xhl)
	lda xix, (SqplyVal_ParamCases:24)
	jp	t, (xix+hl)
; Case bodies of the `jp t, (xrr+rr)` switch in the SqplyVal handler above (index 0..7; word offsets at SqplyVal_HandleExtraParams_CaseTable): jp (xix + r) with xix = this
; label, so this label is the offset-0 case.  Formerly named as data; it is
; code.
SqplyVal_ParamCases:
	ld	xwa, (xbc)
	ld	xbc, EVT_GET_CYC_EN_STRING
SqplyVal_ParamCases_Join:
	call	ApFuncCall
	ld	xwa, (xsp+6)
	ld	xwa, (xwa+26)
	ld	xbc, EVT_CHK_CUR
	ld	xde, (xsp+60)
	call	ApFuncCall
	lda	xwa, (xsp+52)
	lda	xbc, (xsp+48)
	lda	xde, (xsp+32)
	or	xhl, xhl
	jr	z, SqplyVal_ParamCases_Skip
	ld	xhl, 0:i3
	push	xhl
	pushw	0
	pushw	255
	jr	SqplyVal_ParamCases_Join2
	ld	xwa, (xbc)
	ld	xbc, EVT_GET_CYC_SRT_M_STRING
	jr	SqplyVal_ParamCases_Join
	ld	xwa, (xbc)
	ld	xbc, EVT_GET_CYC_END_M_STRING
	jr	SqplyVal_ParamCases_Join
	ld	xwa, (xbc)
	ld	xbc, EVT_GET_P_IN_MEAS_STRING
	jr	SqplyVal_ParamCases_Join
	ld	xwa, (xbc)
	ld	xbc, EVT_GET_P_OUT_MEAS_STRING
	jr	SqplyVal_ParamCases_Join
	ld	xwa, (xbc)
	ld	xbc, EVT_GET_P_CNT_IN_STRING
	jr	SqplyVal_ParamCases_Join
	ld	xwa, (xbc)
	ld	xbc, EVT_GET_SOLO_EN_STRING
	jr	SqplyVal_ParamCases_Join
SqplyVal_ParamCases_Skip:
	ld	xhl, 0:i3
	push	xhl
	ld	xhl, (xsp+10)
	pushm (xhl+22)
	pushm (xhl+24)
SqplyVal_ParamCases_Join2:
	call	DrawStringLeftJustify
	ld	xwa, (xsp+68)
	ld	xbc, EVT_INDEXSW_UP
	ld	xde, 1:i3
	call	SetDialUp
	ld	xwa, (xsp+68)
	ld	xbc, EVT_INDEXSW_DOWN
	ld	xde, 1:i3
	call	SetDialDown
	ld	wa, 1:i3
	jrl	SqplyVal_CallSortedUpdate

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
	ld xbc, EVT_GET_CUR_POS
	ld xde, 0:i3
	call ApFuncCall
	ldfr_berp L, 0xfb
	ldto_berp E, 0xfb
	exts de
	exts xde
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 26)
	ld xbc, EVT_CUR_TO_PARAM
	call ApFuncCall
	ldfr_berp L, 0xfb
	ldto_berp E, 0xfb
	exts de
	exts xde
	ld xwa, NAKA_MAINFUNC_ApPlaySyori_Kubo
	ld xbc, EVT_INC_VAL
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
	bit 2, (1057:16)
	jrl nz, SqplyVal_ReturnZero
	ld xwa, NAKA_MAINFUNC_ApPlaySyori_Kubo
	ld xbc, EVT_INC_VAL
	ld xde, 0:i3
	call MainPostEvent
	ld xwa, (xsp + 68)
	ld xbc, (xsp + 64)
	ld xde, (xsp + 60)
	call SetAutoInc
	ld xwa, (xsp + 68)
	ld xbc, EVT_INDEXSW_UP
	ld xde, 2:i3
	call SetDialUp
	ld xwa, (xsp + 68)
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, 2:i3
	call SetDialDown
	ld wa, 1:i3
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
	ld xbc, EVT_GET_CUR_POS
	ld xde, 0:i3
	call ApFuncCall
	ldfr_berp L, 0xfb
	ldto_berp E, 0xfb
	exts de
	exts xde
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 26)
	ld xbc, EVT_CUR_TO_PARAM
	call ApFuncCall
	ldfr_berp L, 0xfb
	ldto_berp E, 0xfb
	exts de
	exts xde
	ld xwa, NAKA_MAINFUNC_ApPlaySyori_Kubo
	ld xbc, EVT_DEC_VAL
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
	bit 2, (1057:16)
	jrl nz, SqplyVal_ReturnZero
	ld xwa, NAKA_MAINFUNC_ApPlaySyori_Kubo
	ld xbc, EVT_DEC_VAL
	ld xde, 0:i3
	call MainPostEvent
	ld xwa, (xsp + 68)
	ld xbc, (xsp + 64)
	ld xde, (xsp + 60)
	call SetAutoInc
	ld xwa, (xsp + 68)
	ld xbc, EVT_INDEXSW_UP
	ld xde, 2:i3
	call SetDialUp
	ld xwa, (xsp + 68)
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, 2:i3
	call SetDialDown
	ld wa, 1:i3

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
	ld xbc, EVT_GET_CUR_POS
	ld xde, 0:i3
	call ApFuncCall
	ld (xsp + 2), l
	ld xwa, (xsp + 60)
	cp xwa, 0xc
	jr z, SqplyVal_SelectTrack
	cp xwa, 0xb
	jr z, SqplyVal_SelectTrack
	cp xwa, 0xa
	jr z, SqplyVal_SelectTrack
	cp xwa, 0x9
	jr z, SqplyVal_SelectTrack
	cp xwa, 0x8
	jr z, SqplyVal_SelectTrack
	cp xwa, 0x8c
	jr z, SqplyVal_SelectTrack
	cp xwa, 0x8b
	jrl z, SqplyVal_SelectTrack_SetPart3
	cp xwa, 0x8a
	jrl z, SqplyVal_SelectTrack_SetPart2
	cp xwa, 0x89
	jrl z, SqplyVal_SelectTrack_SetPart1
	cp xwa, 0x88
	jrl nz, SqplyVal_ReturnZero

SqplyVal_SelectTrack:
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 26)
	ld xbc, EVT_GET_CUR_POS
	ld xde, 0:i3
	call ApFuncCall
	ld (xsp + 4), l
	ld xde, 0:i3
	ld e, (xsp + 2)
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 26)
	ld xbc, EVT_CUR_TO_PARAM
	call ApFuncCall
	ldfr_berp L, 0xfb
	ld xwa, (xsp + 6)
	lda xbc, (xwa + 26)
	cpib_erp 0xfb, 0
	jr lt, SqplyVal_SelectTrack_NegRange
	ld xde, 0:i3
	ld e, (xsp + 2)
	ld xwa, (xbc)
	ld xbc, EVT_SET_CUR_POS
	call ApFuncCall
	ldto_berp E, 0xfb
	exts de
	exts xde
	ld xwa, (xsp + 68)
	ld xbc, EVT_PARA_DRAW
	call SendEvent
	ld a, (xsp + 2)
	cp a, (xsp + 4)
	jr z, SqplyVal_ReturnZero
	ld xde, 0:i3
	ld e, (xsp + 4)
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 26)
	ld xbc, EVT_CUR_TO_PARAM
	call ApFuncCall
	ldfr_berp L, 0xfb
	cpib_erp 0xfb, 0
	jr lt, SqplyVal_ReturnZero
	ldto_berp E, 0xfb
	exts de
	exts xde
	ld xwa, (xsp + 68)
	ld xbc, EVT_PARA_DRAW
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
	ld xde, 0:i3
	ld e, (xsp + 4)
	ld xwa, (xbc)
	ld xbc, EVT_CUR_TO_PARAM
	call ApFuncCall
	ldfr_berp L, 0xfb
	cpib_erp 0xfb, 0
	jr lt, SqplyVal_ReturnZero
	ldto_berp E, 0xfb
	exts de
	exts xde
	ld xwa, (xsp + 68)
	ld xbc, EVT_PARA_DRAW

SqplyVal_DispatchScrollCmd:
	call SendEvent

SqplyVal_ReturnZero:
	ld xhl, 0:i3

SqplyVal_Epilogue:
	popw_erp 0xfa
	lda xsp, (xsp + 70)
	ret

SqedtValProc:
	lda xsp, (xsp - 76)
	pushw_erp 0xfa
	ld (xsp + 66), xde
	ld (xsp + 70), xbc
	ld (xsp + 74), xwa
	ld xwa, (xsp + 70)
	cp xwa, EVT_SW_IN
	jrl z, SqedtVal_HandleSelectEvent
	cp xwa, EVT_INDEXSW_DOWN
	jrl z, SqedtVal_HandleDownScrollEvent
	cp xwa, EVT_INDEXSW_UP
	jrl z, SqedtVal_HandleUpScrollEvent
	cp xwa, EVT_PARA_DRAW
	jr z, SqedtVal_HandleScrollEvent
	cp xwa, EVT_PAINT
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
	ld xbc, EVT_SET_CUR_POS
	ld xde, 0:i3
	call ApFuncCall
	ld xwa, 0xffffffff
	ld xbc, EVT_SW_IN
	ld xde, 0x88
	call SendEvent
	ld xde, (xsp + 74)
	ld xwa, NAKA_MAINFUNC_ApEditSyori
	ld xbc, (xsp + 70)
	call MainPostEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_INDEXSW_UP
	ld xde, 1:i3
	call SetDialUp
	ld xwa, (xsp + 74)
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, 1:i3
	call SetDialDown
	ld wa, 1:i3
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
	ld xbc, EVT_GET_TTL_NOW
	ld xde, 0:i3
	call ApFuncCall
	ld xiy, (xsp + 4)
	cp l, (xiy + 30)
	jrl nz, SqedtVal_ReturnZero
	lda xhl, (xsp + 58)
	ld xwa, (xsp + 66)
	sll xwa, 3
	ld xde, SqedtVal_HandleScrollEvent_Table
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
	ld xbc, EVT_GET_RAM_ADDRESS
	ld xde, (xsp + 66)
	call ApFuncCall
	lda xde, (xsp + 8)
	ld (xde), xhl
	lda xhl, (xsp + 30)
	ld xwa, xhl
	lda xbc, (xhl + 24)

SqedtVal_ClearDrawBuffer:
	ld (xwa+), 0x00
	cp xwa, xbc
	jr c, SqedtVal_ClearDrawBuffer
	ld (xde + 18), xhl
	ld xwa, (xsp + 66)
	cp xwa, 0xe
	jrl ugt, SqedtVal_ReturnZero
	add xwa, xwa
	add xwa, SqedtVal_ClearDrawBuffer_CaseTable
	ld wa, (xwa)
	lda xix, (SqedtVal_ParamCases:24)
	jp	t, (xix+wa)

; Case bodies of the `jp t, (xrr+rr)` switch in the SqedtVal handler above (index 0..14; word offsets at SqedtVal_ClearDrawBuffer_CaseTable): jp (xix + r) with xix = this
; label, so this label is the offset-0 case.  Formerly named as data; it is
; code.
SqedtVal_ParamCases:
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+26)
	ld	xbc, EVT_GET_TRK_STRING
SqedtVal_ParamCases_Join:
	call	ApFuncCall
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+26)
	ld	xbc, EVT_CHK_CUR
	ld	xde, (xsp+66)
	call	ApFuncCall
	lda	xwa, (xsp+58)
	lda	xbc, (xsp+54)
	lda	xde, (xsp+30)
	or	xhl, xhl
	jrl	z, SqedtVal_ParamCases_Skip
	ld	xhl, 0:i3
	push	xhl
	pushw	0
	pushw	255
	jrl	SqedtVal_ParamCases_Join2
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+26)
	ld	xbc, EVT_GET_FM_STRING
	jr	SqedtVal_ParamCases_Join
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+26)
	ld	xbc, EVT_GET_LM_STRING
	jr	SqedtVal_ParamCases_Join
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+26)
	ld	xbc, EVT_GET_ADLY_STRING
	jr	SqedtVal_ParamCases_Join
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+26)
	ld	xbc, EVT_GET_TRNS_STRING
	jr	SqedtVal_ParamCases_Join
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+26)
	ld	xbc, EVT_GET_VELO_STRING
	jr	SqedtVal_ParamCases_Join
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+26)
	ld	xbc, EVT_GET_MERS_STRING
	jr	SqedtVal_ParamCases_Join
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+26)
	ld	xbc, EVT_GET_QTZ_VAL_STRING
	jrl	SqedtVal_ParamCases_Join
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+26)
	ld	xbc, EVT_GET_QTZ_STR_STRING
	jrl	SqedtVal_ParamCases_Join
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+26)
	ld	xbc, EVT_GET_QTZ_WIN_STRING
	jrl	SqedtVal_ParamCases_Join
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+26)
	ld	xbc, EVT_GET_TN_STRING
	jrl	SqedtVal_ParamCases_Join
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+26)
	ld	xbc, EVT_GET_CN_STRING
	jrl	SqedtVal_ParamCases_Join
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+26)
	ld	xbc, EVT_GET_MRG_TR_A_STRING
	jrl	SqedtVal_ParamCases_Join
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+26)
	ld	xbc, EVT_GET_MRG_TR_B_STRING
	jrl	SqedtVal_ParamCases_Join
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+26)
	ld	xbc, EVT_GET_MRG_TR_C_STRING
	jrl	SqedtVal_ParamCases_Join
SqedtVal_ParamCases_Skip:
	ld	xhl, 0:i3
	push	xhl
	ld	xhl, (xsp+8)
	pushm (xhl+22)
	pushm (xhl+24)
SqedtVal_ParamCases_Join2:
	call	DrawStringLeftJustify
	ld	xwa, (xsp+74)
	ld	xbc, EVT_INDEXSW_UP
	ld	xde, 1:i3
	call	SetDialUp
	ld	xwa, (xsp+74)
	ld	xbc, EVT_INDEXSW_DOWN
	ld	xde, 1:i3
	call	SetDialDown
	ld	wa, 1:i3
	jrl	SqedtVal_DoSortedUpdate

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
	ld xbc, EVT_GET_CUR_POS
	ld xde, 0:i3
	call ApFuncCall
	ldfr_berp L, 0xfa
	ldto_berp E, 0xfa
	exts de
	exts xde
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 26)
	ld xbc, EVT_CUR_TO_PARAM
	call ApFuncCall
	ldfr_berp L, 0xfa
	ldto_berp E, 0xfa
	exts de
	exts xde
	ld xwa, NAKA_MAINFUNC_ApEditSyori
	ld xbc, EVT_INC_VAL
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
	ld xbc, EVT_GET_CUR_POS
	ld xde, 0:i3
	call ApFuncCall
	ldfr_berp L, 0xfa
	ldto_berp E, 0xfa
	exts de
	exts xde
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 26)
	ld xbc, EVT_CUR_TO_PARAM
	call ApFuncCall
	ldfr_berp L, 0xfa
	ldto_berp E, 0xfa
	exts de
	exts xde
	ld xwa, NAKA_MAINFUNC_ApEditSyori
	ld xbc, EVT_DEC_VAL
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
	cp xwa, 0xb
	jr z, SqedtVal_CallSortedUpdate
	cp xwa, 0x9
	jr z, SqedtVal_SetBerp6
	cp xwa, 0x8
	jr z, SqedtVal_SetBerp5
	cp xwa, 0x8b
	jr z, SqedtVal_SetBerp3
	cp xwa, 0x8a
	jr z, SqedtVal_SetBerp2
	cp xwa, 0x89
	jr z, SqedtVal_SetBerp1
	cp xwa, 0x88
	jr nz, SqedtVal_SelectDefault
	ldib_erp 0xfb, 0
	jr SqedtVal_SelectDispatch

SqedtVal_SetBerp1:
	ldib_erp 0xfb, 1
	jr SqedtVal_SelectDispatch

SqedtVal_SetBerp2:
	ldib_erp 0xfb, 2
	jr SqedtVal_SelectDispatch

SqedtVal_SetBerp3:
	ldib_erp 0xfb, 3
	jr SqedtVal_SelectDispatch

SqedtVal_SetBerp5:
	ldib_erp 0xfb, 5
	jr SqedtVal_SelectDispatch

SqedtVal_SetBerp6:
	ldib_erp 0xfb, 6
	jr SqedtVal_SelectDispatch

SqedtVal_CallSortedUpdate:
	ld wa, 0:i3

SqedtVal_DoSortedUpdate:
	call SetDialEnable
	jrl SqedtVal_ReturnZero

SqedtVal_SelectDefault:
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 26)
	ld xbc, EVT_GET_CUR_POS
	ld xde, 0:i3
	call ApFuncCall
	ldfr_berp L, 0xfb

SqedtVal_SelectDispatch:
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 26)
	ld xbc, EVT_GET_CUR_POS
	ld xde, 0:i3
	call ApFuncCall
	ld (xsp + 2), l
	ld xde, 0:i3
	ldto_berp E, 0xfb
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 26)
	ld xbc, EVT_CUR_TO_PARAM
	call ApFuncCall
	ldfr_berp L, 0xfa
	ld xwa, (xsp + 4)
	lda xbc, (xwa + 26)
	cpib_erp 0xfa, 0
	jr lt, SqedtVal_Select_NegRange
	ld xde, 0:i3
	ldto_berp E, 0xfb
	ld xwa, (xbc)
	ld xbc, EVT_SET_CUR_POS
	call ApFuncCall
	ldto_berp E, 0xfa
	exts de
	exts xde
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	call SendEvent
	ldto_berp A, 0xfb
	cp a, (xsp + 2)
	jr z, SqedtVal_ReturnZero
	ld xde, 0:i3
	ld e, (xsp + 2)
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 26)
	ld xbc, EVT_CUR_TO_PARAM
	call ApFuncCall
	ldfr_berp L, 0xfa
	cpib_erp 0xfa, 0
	jr lt, SqedtVal_ReturnZero
	ldto_berp E, 0xfa
	exts de
	exts xde
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	jr SqedtVal_DispatchScrollCmd

SqedtVal_Select_NegRange:
	ld xde, 0:i3
	ld e, (xsp + 2)
	ld xwa, (xbc)
	ld xbc, EVT_CUR_TO_PARAM
	call ApFuncCall
	ldfr_berp L, 0xfa
	cpib_erp 0xfa, 0
	jr lt, SqedtVal_ReturnZero
	ldto_berp E, 0xfa
	exts de
	exts xde
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW

SqedtVal_DispatchScrollCmd:
	call SendEvent

SqedtVal_ReturnZero:
	ld xhl, 0:i3

SqedtVal_Epilogue:
	popw_erp 0xfa
	lda xsp, (xsp + 76)
	ret

SqedtFixProc:
	lda xsp, (xsp-130)
	push xiz
	ld xhl, xbc
	ld xiz, xwa
	ld xiy, SqedtFixProc_LocalInit
	lda xix, (xsp + 100)
	ld bc, 2:i3
	ldirw
	ldi85
	ld xiy, SqedtFixProc_LocalInit_2
	lda xix, (xsp + 96)
	ldi85
	ldiw
	ld xiy, SqedtFixProc_LocalInit_3
	lda xix, (xsp + 90)
	ld bc, 2:i3
	ldirw
	ldi85
	ld xiy, SqedtFixProc_LocalInit_4
	lda xix, (xsp + 84)
	ld bc, 3:i3
	ldirw
	ld xiy, SqedtFixProc_LocalInit_5
	lda xix, (xsp + 78)
	ld bc, 3:i3
	ldirw
	ld xiy, SqedtFixProc_LocalInit_6
	lda xix, (xsp + 76)
	ldiw
	ld xiy, SqedtFixProc_LocalInit_7
	lda xix, (xsp + 62)
	ld bc, 7:i3
	ldirw
	ld xiy, SqedtFixProc_LocalInit_8
	lda xix, (xsp + 48)
	ld bc, 6:i3
	ldirw
	ldi85
	ld xiy, SqedtFixProc_LocalInit_9
	lda xix, (xsp + 34)
	ld bc, 7:i3
	ldirw
	ld xiy, SqedtFixProc_LocalInit_10
	lda xix, (xsp + 26)
	ld bc, 3:i3
	ldirw
	ldi85
	ld xiy, SqedtFixProc_LocalInit_11
	lda xix, (xsp + 20)
	ld bc, 2:i3
	ldirw
	ldi85
	cp xhl, EVT_PAINT
	jr z, SqedtFix_HandleInitEvent
	ld xwa, xiz
	ld xbc, xhl
	call InheritedProc
	jrl SqedtFix_Epilogue

SqedtFix_HandleInitEvent:
	ld xwa, xiz
	ld xbc, xhl
	call InheritedProc
	ld xwa, xiz
	call GetViewInstance
	ld (xsp + 4), xhl
	lda xwa, (xsp + 118)
	ldw (xwa), 0x2c
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
	ld xhl, 2:i3
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	lda xwa, (xsp + 118)
	ldw (xwa), 0xda
	ldw bc, 0xda
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
	ld xhl, 2:i3
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	lda xwa, (xsp + 118)
	ldw (xwa), 0x3d
	lda xde, (xwa + 2)
	ldw (xde), 0xb7
	lda xhl, (xwa + 4)
	ld bc, (xwa)
	add bc, 0x28
	ld (xhl), bc
	lda xix, (xwa + 6)
	ld bc, (xde)
	add bc, 0xf
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
	ld xhl, 0:i3
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	lda xwa, (xsp + 118)
	ldw (xwa), 0xe4
	ldw bc, 0xe4
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
	ld xhl, 0:i3
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	lda xwa, (xsp + 118)
	ldw (xwa), 0x14
	lda xde, (xwa + 2)
	ldw (xde), 0xc8
	lda xhl, (xwa + 4)
	ld bc, (xwa)
	add bc, 0x2d
	ld (xhl), bc
	lda xix, (xwa + 6)
	ld bc, (xde)
	add bc, 0xf
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
	ld xhl, 0:i3
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	lda xwa, (xsp + 118)
	ldw (xwa), 0x61
	ldw bc, 0x61
	add bc, 0x2d
	ld (xwa + 4), bc
	sub bc, (xwa)
	exts xbc
	divs bc, 0x2
	ld de, (xwa)
	add de, bc
	lda xbc, (xsp + 106)
	ld (xbc), de
	lda xde, (xsp + 84)
	ld xhl, 0:i3
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	lda xwa, (xsp + 118)
	ldw (xwa), 0xb4
	ldw bc, 0xb4
	add bc, 0x2d
	ld (xwa + 4), bc
	sub bc, (xwa)
	exts xbc
	divs bc, 0x2
	ld de, (xwa)
	add de, bc
	lda xbc, (xsp + 106)
	ld (xbc), de
	lda xde, (xsp + 90)
	ld xhl, 0:i3
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	lda xwa, (xsp + 118)
	ldw (xwa), 0x101
	ldw bc, 0x101
	add bc, 0x2d
	ld (xwa + 4), bc
	sub bc, (xwa)
	exts xbc
	divs bc, 0x2
	ld de, (xwa)
	add de, bc
	lda xbc, (xsp + 106)
	ld (xbc), de
	lda xde, (xsp + 84)
	ld xhl, 0:i3
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
	add bc, 0x6a
	ld (xwa + 6), bc
	ld xde, (xsp + 4)
	ld bc, (xde + 26)
	ld de, (xde + 24)
	call DrawDesignBox
	lda xwa, (xsp + 126)
	ldw (xwa), 0xa4
	ldw bc, 0xa4
	add bc, 0x95
	ld (xwa + 4), bc
	ld bc, (xwa + 2)
	add bc, 0x6a
	ld (xwa + 6), bc
	ld xde, (xsp + 4)
	ld bc, (xde + 26)
	ld de, (xde + 24)
	call DrawDesignBox
	lda xwa, (xsp + 114)
	ldw (xwa), 0x4
	ldw (xwa + 2), 0xc8
	lda xbc, (xsp + 110)
	ld de, (xwa)
	ld (xbc), de
	ldw (xbc + 2), 0xd6
	ld xde, (xsp + 4)
	ld de, (xde + 22)
	call DrawLine
	lda xwa, (xsp + 114)
	ldw (xwa), 0x9b
	lda xbc, (xsp + 110)
	ld de, (xwa)
	ld (xbc), de
	ld xde, (xsp + 4)
	ld de, (xde + 22)
	call DrawLine
	lda xwa, (xsp + 114)
	ldw (xwa), 0xa4
	lda xbc, (xsp + 110)
	ld de, (xwa)
	ld (xbc), de
	ld xde, (xsp + 4)
	ld de, (xde + 22)
	call DrawLine
	lda xwa, (xsp + 114)
	ldw (xwa), 0x13b
	lda xbc, (xsp + 110)
	ld de, (xwa)
	ld (xbc), de
	ld xde, (xsp + 4)
	ld de, (xde + 22)
	call DrawLine
	lda xwa, (xsp + 114)
	ldw (xwa), 0x4
	lda xde, (xwa + 2)
	ldw (xde), 0xc8
	lda xbc, (xsp + 110)
	ldw (xbc), 0x9a
	ld de, (xde)
	ld (xbc + 2), de
	ld xde, (xsp + 4)
	ld de, (xde + 22)
	call DrawLine
	lda xwa, (xsp + 114)
	ldw (xwa), 0xa4
	lda xbc, (xsp + 110)
	ldw (xbc), 0x13a
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
	cp l, 0xa8
	jrl z, SqedtFix_SetupLayoutB
	cp l, 0x91
	jrl z, SqedtFix_SetupLayoutB
	cp l, 0xa4
	jr z, SqedtFix_SetupLayoutA
	cp l, 0xa2
	jrl nz, SqedtFix_ReturnZero

SqedtFix_SetupLayoutA:
	ldw (xwa), 0xa
	ldw (xix), 0x3a
	ld de, (xwa)
	add de, 0x82
	ld (xiz), de
	ld de, (xix)
	add de, 0xf
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
	ld xhl, 0:i3
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
	ld xhl, 0:i3
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	lda xwa, (xsp + 118)
	lda xbc, (xwa + 2)
	ldw (xbc), 0x5c
	ldw (xwa + 6), 0x6b
	ld de, (xbc)
	ldw bc, 0x6b
	sub bc, de
	exts xbc
	divs bc, 0x2
	add de, bc
	lda xbc, (xsp + 106)
	ld (xbc + 2), de
	lda xde, (xsp + 62)
	ld xhl, 0:i3
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	lda xwa, (xsp + 118)
	lda xbc, (xwa + 2)
	ldw (xbc), 0x6a
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
	ld xhl, 0:i3
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	lda xwa, (xsp + 118)
	lda xbc, (xwa + 2)
	ldw (xbc), 0x7e
	ldw (xwa + 6), 0x8d
	ld de, (xbc)
	ldw bc, 0x8d
	sub bc, de
	exts xbc
	divs bc, 0x2
	add de, bc
	lda xbc, (xsp + 106)
	ld (xbc + 2), de
	lda xde, (xsp + 48)
	ld xhl, 0:i3
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	lda xwa, (xsp + 118)
	lda xbc, (xwa + 2)
	ldw (xbc), 0x8c
	ldw (xwa + 6), 0x9b
	ld de, (xbc)
	ldw bc, 0x9b
	sub bc, de
	exts xbc
	divs bc, 0x2
	add de, bc
	lda xbc, (xsp + 106)
	ld (xbc + 2), de
	lda xde, (xsp + 76)
	ld xhl, 0:i3
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	lda xwa, (xsp + 118)
	ldw (xwa), 0xaa
	lda xde, (xwa + 2)
	ldw (xde), 0x3a
	lda xhl, (xwa + 4)
	ld bc, (xwa)
	add bc, 0x82
	ld (xhl), bc
	lda xix, (xwa + 6)
	ld bc, (xde)
	add bc, 0xf
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
	ld xhl, 0:i3
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
	ld xhl, 0:i3
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	lda xwa, (xsp + 118)
	lda xbc, (xwa + 2)
	ldw (xbc), 0x5c
	ldw (xwa + 6), 0x6b
	ld de, (xbc)
	ldw bc, 0x6b
	sub bc, de
	exts xbc
	divs bc, 0x2
	add de, bc
	lda xbc, (xsp + 106)
	ld (xbc + 2), de
	lda xde, (xsp + 34)
	ld xhl, 0:i3
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	lda xwa, (xsp + 118)
	lda xbc, (xwa + 2)
	ldw (xbc), 0x6a
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
	ld xhl, 0:i3
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	lda xwa, (xsp + 118)
	lda xbc, (xwa + 2)
	ldw (xbc), 0x7e
	ldw (xwa + 6), 0x8d
	ld de, (xbc)
	ldw bc, 0x8d
	sub bc, de
	exts xbc
	divs bc, 0x2
	add de, bc
	lda xbc, (xsp + 106)
	ld (xbc + 2), de
	lda xde, (xsp + 26)
	ld xhl, 0:i3
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	lda xwa, (xsp + 118)
	lda xbc, (xwa + 2)
	ldw (xbc), 0x8c
	ldw (xwa + 6), 0x9b
	ld de, (xbc)
	ldw bc, 0x9b
	sub bc, de
	exts xbc
	divs bc, 0x2
	add de, bc
	lda xbc, (xsp + 106)
	ld (xbc + 2), de
	lda xde, (xsp + 76)
	ld xhl, 0:i3
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	jrl SqedtFix_DrawString

SqedtFix_SetupLayoutB:
	ldw (xwa), 0x6
	ldw (xix), 0x3e
	ld de, (xwa)
	add de, 0x82
	ld (xiz), de
	ld de, (xix)
	add de, 0xf
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
	ld xhl, 0:i3
	push xhl
	ld xhl, (xsp + 16)
	pushm (xhl)
	ld xhl, (xsp + 14)
	pushm (xhl)
	call DrawStringLeftJustify
	lda xwa, (xsp + 118)
	lda xbc, (xwa + 2)
	ldw (xbc), 0x4e
	ldw (xwa + 6), 0x5d
	ld de, (xbc)
	ldw bc, 0x5d
	sub bc, de
	exts xbc
	divs bc, 0x2
	add de, bc
	lda xbc, (xsp + 106)
	ld (xbc + 2), de
	lda xde, (xsp + 76)
	ld xhl, 0:i3
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	lda xwa, (xsp + 118)
	lda xbc, (xwa + 2)
	ldw (xbc), 0x5f
	ldw (xwa + 6), 0x6e
	ld de, (xbc)
	ldw bc, 0x6e
	sub bc, de
	exts xbc
	divs bc, 0x2
	add de, bc
	lda xbc, (xsp + 106)
	ld (xbc + 2), de
	lda xde, (xsp + 76)
	ld xhl, 0:i3
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
	ld xhl, 0:i3
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
	ld xhl, 0:i3
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	lda xwa, (xsp + 118)
	ldw (xwa), 0xa6
	lda xde, (xwa + 2)
	ldw (xde), 0x3e
	lda xhl, (xwa + 4)
	ld bc, (xwa)
	add bc, 0x82
	ld (xhl), bc
	lda xix, (xwa + 6)
	ld bc, (xde)
	add bc, 0xf
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
	ld xhl, 0:i3
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	lda xwa, (xsp + 118)
	lda xbc, (xwa + 2)
	ldw (xbc), 0x4e
	ldw (xwa + 6), 0x5d
	ld de, (xbc)
	ldw bc, 0x5d
	sub bc, de
	exts xbc
	divs bc, 0x2
	add de, bc
	lda xbc, (xsp + 106)
	ld (xbc + 2), de
	lda xde, (xsp + 76)
	ld xhl, 0:i3
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	lda xwa, (xsp + 118)
	lda xbc, (xwa + 2)
	ldw (xbc), 0x5f
	ldw (xwa + 6), 0x6e
	ld de, (xbc)
	ldw bc, 0x6e
	sub bc, de
	exts xbc
	divs bc, 0x2
	add de, bc
	lda xbc, (xsp + 106)
	ld (xbc + 2), de
	lda xde, (xsp + 76)
	ld xhl, 0:i3
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
	ld xhl, 0:i3
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
	ld xhl, 0:i3
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)

SqedtFix_DrawString:
	call DrawStringLeftJustify

SqedtFix_ReturnZero:
	ld xhl, 0:i3

SqedtFix_Epilogue:
	pop xiz
	lda xsp, (xsp+130:16)
	ret

SqedtVal3Proc:
	lda xsp, (xsp - 66)
	push xiz
	ld (xsp + 62), xde
	ld xiz, xbc
	ld (xsp + 66), xwa
	cp xiz, EVT_INDEXSW_DOWN
	jrl z, SqedtVal3_HandleSelectEvent2
	cp xiz, EVT_INDEXSW_UP
	jrl z, SqedtVal3_HandleSelectEvent1
	cp xiz, EVT_PARA_DRAW
	jr z, SqedtVal3_HandleScrollEvent
	cp xiz, EVT_PAINT
	jr z, SqedtVal3_HandleInitEvent
	ld xwa, (xsp + 66)
	ld xbc, xiz
	ld xde, (xsp + 62)
	call InheritedProc
	jrl SqedtVal3_Epilogue

SqedtVal3_HandleInitEvent:
	ld xwa, (xsp + 66)
	ld xbc, xiz
	ld xde, (xsp + 62)
	call InheritedProc
	ld xde, (xsp + 66)
	ld xwa, NAKA_MAINFUNC_ApEditSyori
	ld xbc, xiz
	call MainPostEvent
	ld xwa, (xsp + 66)
	ld xbc, EVT_INDEXSW_UP
	ld xde, 1:i3
	call SetDialUp
	ld xwa, (xsp + 66)
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, 1:i3
	call SetDialDown
	ld wa, 1:i3
	call SetDialEnable
	jrl SqedtVal_ReturnZero2

SqedtVal3_HandleScrollEvent:
	ld xwa, (xsp + 66)
	ld xbc, xiz
	ld xde, (xsp + 62)
	call InheritedProc
	ld xwa, (xsp + 62)
	cp xwa, 0x1f
	jrl c, SqedtVal_ReturnZero2
	cp xwa, 0x22
	jrl ugt, SqedtVal_ReturnZero2
	ld xwa, (xsp + 66)
	call GetViewInstance
	ld (xsp + 4), xhl
	lda xhl, (xsp + 54)
	lda xde, (SqedtVal_HandleScrollEvent_Table:24)
	ld	wa, (xde+248)
	ld (xhl), wa
	lda xbc, (xhl + 2)
	ld	wa, (xde+250)
	ld (xbc), wa
	ld ix, (xhl)
	add	ix, (xde+252)
	lda xwa, (xhl + 4)
	ld (xwa), ix
	ld ix, (xbc)
	add	ix, (xde+254)
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
	ld xbc, EVT_GET_RAM_ADDRESS
	ld xde, 0x1f
	call ApFuncCall
	lda xde, (xsp + 8)
	ld (xde), xhl
	lda xhl, (xsp + 30)
	ld xwa, xhl
	lda xbc, (xhl + 20)

SqedtVal3_FillBufferLoop1:
	ld (xwa+), 0x00
	cp xwa, xbc
	jr c, SqedtVal3_FillBufferLoop1
	ld (xde + 18), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 26)
	ld xbc, EVT_GET_SCLR_NO_STRING
	call ApFuncCall
	lda xwa, (xsp + 54)
	lda xbc, (xsp + 50)
	lda xde, (xsp + 30)
	ld xhl, 4:i3
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	lda xhl, (xsp + 54)
	lda xde, (SqedtVal_HandleScrollEvent_Table:24)
	ld	wa, (xde+256)
	ld (xhl), wa
	lda xbc, (xhl + 2)
	ld	wa, (xde+258)
	ld (xbc), wa
	ld ix, (xhl)
	add	ix, (xde+260)
	lda xwa, (xhl + 4)
	ld (xwa), ix
	ld ix, (xbc)
	add	ix, (xde+262)
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
	ld xbc, EVT_GET_RAM_ADDRESS
	ld xde, 0x20
	call ApFuncCall
	lda xde, (xsp + 8)
	ld (xde), xhl
	lda xhl, (xsp + 30)
	ld xwa, xhl
	lda xbc, (xhl + 20)

SqedtVal3_FillBufferLoop2:
	ld (xwa+), 0x00
	cp xwa, xbc
	jr c, SqedtVal3_FillBufferLoop2
	ld (xde + 18), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 26)
	ld xbc, EVT_GET_SCLR_NAME_STRING
	call ApFuncCall
	lda xwa, (xsp + 54)
	lda xbc, (xsp + 50)
	lda xde, (xsp + 30)
	ld xhl, 4:i3
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	lda xhl, (xsp + 54)
	lda xde, (SqedtVal_HandleScrollEvent_Table:24)
	ld	wa, (xde+264)
	ld (xhl), wa
	lda xbc, (xhl + 2)
	ld	wa, (xde+266)
	ld (xbc), wa
	ld ix, (xhl)
	add	ix, (xde+268)
	lda xwa, (xhl + 4)
	ld (xwa), ix
	ld ix, (xbc)
	add	ix, (xde+270)
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
	ld xbc, EVT_GET_RAM_ADDRESS
	ld xde, 0x21
	call ApFuncCall
	lda xde, (xsp + 8)
	ld (xde), xhl
	lda xhl, (xsp + 30)
	ld xwa, xhl
	lda xbc, (xhl + 20)

SqedtVal3_FillBufferLoop3:
	ld (xwa+), 0x00
	cp xwa, xbc
	jr c, SqedtVal3_FillBufferLoop3
	ld (xde + 18), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 26)
	ld xbc, EVT_GET_SCLR_KB_STRING
	call ApFuncCall
	lda xwa, (xsp + 54)
	lda xbc, (xsp + 50)
	lda xde, (xsp + 30)
	ld xhl, 3:i3
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	lda xhl, (xsp + 54)
	lda xde, (SqedtVal_HandleScrollEvent_Table:24)
	ld	wa, (xde+272)
	ld (xhl), wa
	lda xbc, (xhl + 2)
	ld	wa, (xde+274)
	ld (xbc), wa
	ld ix, (xhl)
	add	ix, (xde+276)
	lda xwa, (xhl + 4)
	ld (xwa), ix
	ld ix, (xbc)
	add	ix, (xde+278)
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
	ld xbc, EVT_GET_RAM_ADDRESS
	ld xde, 0x22
	call ApFuncCall
	lda xde, (xsp + 8)
	ld (xde), xhl
	lda xhl, (xsp + 30)
	ld xwa, xhl
	lda xbc, (xhl + 20)

SqedtVal3_FillBufferLoop4:
	ld (xwa+), 0x00
	cp xwa, xbc
	jr c, SqedtVal3_FillBufferLoop4
	ld (xde + 18), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 26)
	ld xbc, EVT_GET_SCLR_PER_STRING
	call ApFuncCall
	lda xwa, (xsp + 54)
	lda xbc, (xsp + 50)
	lda xde, (xsp + 30)
	ld xhl, 4:i3
	push xhl
	ld xhl, (xsp + 8)
	pushm (xhl + 22)
	pushm (xhl + 24)
	call DrawStringLeftJustify
	jr SqedtVal_ReturnZero2

SqedtVal3_HandleSelectEvent1:
	ld xwa, (xsp + 66)
	ld xbc, xiz
	ld xde, (xsp + 62)
	call InheritedProc
	ld xwa, (xsp + 62)
	cp xwa, 0x1
	jr nz, SqedtVal_ReturnZero2
	ld xwa, NAKA_MAINFUNC_ApEditSyori
	ld xbc, EVT_INC_VAL
	ld xde, 0x1f
	call MainPostEvent
	ld xwa, (xsp + 66)
	ld xbc, xiz
	ld xde, (xsp + 62)
	jr SqedtVal3_CallSetAutoInc

SqedtVal3_HandleSelectEvent2:
	ld xwa, (xsp + 66)
	ld xbc, xiz
	ld xde, (xsp + 62)
	call InheritedProc
	ld xwa, (xsp + 62)
	cp xwa, 0x1
	jr nz, SqedtVal_ReturnZero2
	ld xwa, NAKA_MAINFUNC_ApEditSyori
	ld xbc, EVT_DEC_VAL
	ld xde, 0x1f
	call MainPostEvent
	ld xwa, (xsp + 66)
	ld xbc, xiz
	ld xde, (xsp + 62)

SqedtVal3_CallSetAutoInc:
	call SetAutoInc

SqedtVal_ReturnZero2:
	ld xhl, 0:i3

SqedtVal3_Epilogue:
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
	cp xwa, EVT_INDEXSW_DOWN
	jrl z, SqedtVal2_HandleUpScrollInner
	cp xwa, EVT_INDEXSW_UP
	jrl z, SqedtVal2_HandleSelectEvent
	cp xwa, EVT_SELE_DRAW
	jrl z, SqedtVal2_HandleUpScrollEvent
	cp xwa, EVT_PARA_DRAW
	jrl z, SqedtVal2_HandleScrollEvent
	cp xwa, EVT_PAINT
	jr z, SqedtVal2_HandleInitEvent
	ld xwa, (xsp + 74)
	ld xbc, (xsp + 70)
	ld xde, (xsp + 66)
	call InheritedProc
	jrl SqedtVal2_Epilogue

SqedtVal2_HandleInitEvent:
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
	ld xwa, NAKA_MAINFUNC_ApEditSyori
	ld xbc, (xsp + 70)
	call MainPostEvent
	ld xwa, (xiz + 26)
	ld xbc, EVT_SET_FROM_CUR
	ld xde, 0:i3
	call ApFuncCall
	ld xwa, (xiz + 26)
	ld xbc, EVT_SET_TO_CUR
	ld xde, 0:i3
	call ApFuncCall
	ld xwa, (xsp + 74)
	ld xbc, EVT_SELE_DRAW
	ld xde, 1:i3
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_SELE_DRAW
	ld xde, 0x10001
	call SendEvent
	cp (xsp + 6), 0xa2
	jr z, SqedtVal2_SendA2A4Events
	cp (xsp + 6), 0xa4
	jr nz, SqedtVal2_SendCommonEvents

SqedtVal2_SendA2A4Events:
	ld xwa, (xsp + 74)
	ld xbc, EVT_SELE_DRAW
	ld xde, 2:i3
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_SELE_DRAW
	ld xde, 0x10002
	call SendEvent

SqedtVal2_SendCommonEvents:
	ld xwa, (xsp + 74)
	ld xbc, EVT_SELE_DRAW
	ld xde, 0x100
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_SELE_DRAW
	ld xde, 0x10100
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_INDEXSW_UP
	ld xde, 2:i3
	call SetDialUp
	ld xwa, (xsp + 74)
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, 2:i3
	call SetDialDown
	ld wa, 1:i3
	call SetDialEnable
	ld (0x03e2e0:24), 0x00
	jrl AccIll_ReturnZero2

SqedtVal2_HandleScrollEvent:
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
	ld xde, SqedtVal_HandleScrollEvent_Table
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
	ld xbc, EVT_GET_RAM_ADDRESS
	ld xde, (xsp + 66)
	call ApFuncCall
	lda xde, (xsp + 12)
	ld (xde), xhl
	lda xhl, (xsp + 34)
	ld xwa, xhl
	lda xbc, (xhl + 20)

; SqplyVal extra params dispatch
SqplyVal_ExtraParams:
	ld (xwa+), 0x00
	cp xwa, xbc
	jr c, SqplyVal_ExtraParams
	ld (xde + 18), xhl
	ld xhl, (xsp + 66)
	ld xwa, (xsp + 4)
	lda xbc, (xwa + 26)
	sub xhl, 0xf
	cp xhl, 0x0
	jrl c, AccIll_ReturnZero2
	cp xhl, 0xf
	jrl ugt, AccIll_ReturnZero2
	add xhl, xhl
	add xhl, SqplyVal_ExtraParams_CaseTable
	ld hl, (xhl)
	lda xix, (AccIll_Dispatch:24)
	jp	t, (xix+hl)
; AccIll_HandleEditorLoad dispatch
AccIll_Dispatch:
	ld	xwa, (xbc)
	ld	xbc, EVT_GET_MCP_TR_A_STRING
AccIll_Dispatch_Join:
	call	ApFuncCall
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+26)
	ld	xbc, EVT_CHK_CUR2
	ld	xde, (xsp+66)
	call	ApFuncCall
	or	xhl, xhl
	jrl	z, AccIll_Dispatch_Skip
	lda	xwa, (xsp+58)
	lda	xbc, (xsp+54)
	lda	xde, (xsp+34)
	ld	xhl, 0:i3
	push	xhl
	pushw	0
	pushw	255
	jrl	AccIll_Dispatch_Join2
	ld	xwa, (xbc)
	ld	xbc, EVT_GET_MCP_FM_STRING
	jr	AccIll_Dispatch_Join
	ld	xwa, (xbc)
	ld	xbc, EVT_GET_MCP_LM_STRING
	jr	AccIll_Dispatch_Join
	ld	xwa, (xbc)
	ld	xbc, EVT_GET_MCP_TR_B_STRING
	jr	AccIll_Dispatch_Join
	ld	xwa, (xbc)
	ld	xbc, EVT_GET_MCP_SM_STRING
	jr	AccIll_Dispatch_Join
	ld	xwa, (xbc)
	ld	xbc, EVT_GET_MCP_REP_STRING
	jr	AccIll_Dispatch_Join
	ld	xwa, (xbc)
	ld	xbc, EVT_GET_MINS_TR_A_STRING
	jr	AccIll_Dispatch_Join
	ld	xwa, (xbc)
	ld	xbc, EVT_GET_MINS_FM_STRING
	jr	AccIll_Dispatch_Join
	ld	xwa, (xbc)
	ld	xbc, EVT_GET_MINS_LM_STRING
	jr	AccIll_Dispatch_Join
	ld	xwa, (xbc)
	ld	xbc, EVT_GET_MINS_TR_B_STRING
	jrl	AccIll_Dispatch_Join
	ld	xwa, (xbc)
	ld	xbc, EVT_GET_MINS_SM_STRING
	jrl	AccIll_Dispatch_Join
	ld	xwa, (xbc)
	ld	xbc, EVT_GET_MINS_REP_STRING
	jrl	AccIll_Dispatch_Join
	ld	xwa, (xbc)
	ld	xbc, EVT_GET_SCP_FSNG_STRING
	jrl	AccIll_Dispatch_Join
	ld	xwa, (xbc)
	ld	xbc, EVT_GET_SCP_FTR_STRING
	jrl	AccIll_Dispatch_Join
	ld	xwa, (xbc)
	ld	xbc, EVT_GET_SCP_TSNG_STRING
	jrl	AccIll_Dispatch_Join
	ld	xwa, (xbc)
	ld	xbc, EVT_GET_SCP_TTR_STRING
	jrl	AccIll_Dispatch_Join
AccIll_Dispatch_Skip:
	lda	xwa, (xsp+58)
	lda	xbc, (xsp+54)
	lda	xde, (xsp+34)
	ld	xhl, 0:i3
	push	xhl
	ld	xhl, (xsp+8)
	pushm (xhl+22)
	pushm (xhl+24)
AccIll_Dispatch_Join2:
	call	DrawStringLeftJustify
	ld	xwa, (xsp+4)
	lda	xbc, (xwa+26)
	lda	xwa, (xsp+12)
	ld	(xsp+8), xwa
	ld	xwa, (xsp+66)
	cp	xwa, 29
	jrl	z, AccIll_Dispatch_Skip2
	cp	xwa, 27
	jrl	nz, AccIll_ReturnZero2
	lda	xiy, (xsp+58)
	ldw (xiy), 14
	lda	xde, (xiy+2)
	ldw (xde), 95
	lda	xhl, (xiy+4)
	ld	wa, (xiy)
	add	wa, 160
	ld	(xhl), wa
	lda	xix, (xiy+6)
	ld	wa, (xde)
	add	wa, 14
	ld	(xix), wa
	ld	wa, (xhl)
	sub wa, (xiy)
	exts xwa
	divs	wa, 2
	ld	iy, (xiy)
	add	iy, wa
	lda	xhl, (xsp+54)
	ld	(xhl), iy
	ld	de, (xde)
	ld	wa, (xix)
	sub	wa, de
	exts	xwa
	divs	wa, 2
	add	de, wa
	ld	(xhl+2), de
	ld	xwa, (xbc)
	ld	xbc, EVT_GET_F_SNG_NAME_STRING
	ld	xde, (xsp+8)
AccIll_Dispatch_Join3:
	call	ApFuncCall
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+26)
	ld	xbc, EVT_CHK_CUR2
	ld	xde, (xsp+66)
	call	ApFuncCall
	lda	xbc, (xsp+54)
	lda	xde, (xsp+34)
	or	xhl, xhl
	jr	z, AccIll_Dispatch_Skip3
	lda	xwa, (xsp+58)
	ld	xhl, 0:i3
	push	xhl
	pushw	0
	pushw	255
	jr	AccIll_Dispatch_Join4
AccIll_Dispatch_Skip2:
	lda	xiy, (xsp+58)
	ldw (xiy), 174
	lda	xde, (xiy+2)
	ldw (xde), 95
	lda	xhl, (xiy+4)
	ld	wa, (xiy)
	add	wa, 160
	ld	(xhl), wa
	lda	xix, (xiy+6)
	ld	wa, (xde)
	add	wa, 14
	ld	(xix), wa
	ld	wa, (xhl)
	sub wa, (xiy)
	exts xwa
	divs	wa, 2
	ld	iy, (xiy)
	add	iy, wa
	lda	xhl, (xsp+54)
	ld	(xhl), iy
	ld	de, (xde)
	ld	wa, (xix)
	sub	wa, de
	exts	xwa
	divs	wa, 2
	add	de, wa
	ld	(xhl+2), de
	ld	xwa, (xbc)
	ld	xbc, EVT_GET_T_SNG_NAME_STRING
	ld	xde, (xsp+8)
	jrl	AccIll_Dispatch_Join3
AccIll_Dispatch_Skip3:
	lda	xwa, (xsp+58)
	ld	xhl, 0:i3
	push	xhl
	ld	xhl, (xsp+8)
	pushm (xhl+22)
	pushm (xhl+24)
AccIll_Dispatch_Join4:
	call	DrawStringLeftJustify
	jrl	AccIll_ReturnZero2

SqedtVal2_HandleUpScrollEvent:
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
	srl xwa, 16
	and xwa, 0xff
	ld c, a
	ld xwa, (xsp + 66)
	and xwa, 0xff
	ldfr_berp A, 0xfb
	cp c, 0:i3
	jr nz, SqedtVal2_HandleDownScrollEvent
	lda xix, (xsp + 58)
	lda xbc, (xix + 2)
	lda xde, (xix + 4)
	lda xhl, (xix + 6)
	cp (xsp + 6), 0x91
	jr z, SqedtVal2_UpScrollModeA2
	cp (xsp + 6), 0xa8
	jr nz, SqedtVal2_UpScrollDefault

SqedtVal2_UpScrollModeA2:
	ldto_berp A, 0xfb
	extz wa
	sla wa, 3
	lda xiy, (SqedtVal2_UpScrollModeA2_Table:24)
	lda	xiy, (xiy+wa)
	ld wa, (xiy + 2)
	ld (xbc), wa
	ld wa, (xiy)
	ld (xix), wa
	ld wa, (xbc)
	add wa, (xiy + 6)
	ld (xhl), wa
	ld xwa, xiy
	jr SqedtVal2_UpScrollCalcOffset

SqedtVal2_UpScrollDefault:
	ldto_berp A, 0xfb
	extz wa
	sla wa, 3
	lda xiy, (SqedtVal2_UpScrollDefault_Table:24)
	lda	xiy, (xiy+wa)
	ld wa, (xiy + 2)
	ld (xbc), wa
	ld wa, (xiy)
	ld (xix), wa
	ld wa, (xbc)
	add wa, (xiy + 6)
	ld (xhl), wa
	ld xwa, xiy

SqedtVal2_UpScrollCalcOffset:
	ld bc, (xix)
	add bc, (xwa + 4)
	ld (xde), bc
	jr SqedtVal2_DrawScrollFrame

SqedtVal2_HandleDownScrollEvent:
	ldto_berp A, 0xfb
	extz wa
	sla wa, 3
	cp (xsp + 6), 0x91
	jr z, SqedtVal2_DownScrollModeA2
	cp (xsp + 6), 0xa8
	jr nz, SqedtVal2_DownScrollDefault

SqedtVal2_DownScrollModeA2:
	lda xhl, (xsp + 58)
	lda xde, (xhl + 2)
	lda xbc, (SqedtVal2_DownScrollModeA2_Table:24)
	lda	xbc, (xbc+wa)
	ld wa, (xbc + 2)
	ld (xde), wa
	ld wa, (xbc)
	ld (xhl), wa
	ld wa, (xde)
	add wa, (xbc + 6)
	ld (xhl + 6), wa
	ld xwa, xbc
	ld xbc, xhl
	jr SqedtVal2_DownScrollCalcOffset

SqedtVal2_DownScrollDefault:
	lda xhl, (xsp + 58)
	lda xde, (xhl + 2)
	lda xbc, (SqedtVal2_DownScrollDefault_Table:24)
	lda	xbc, (xbc+wa)
	ld wa, (xbc + 2)
	ld (xde), wa
	ld wa, (xbc)
	ld (xhl), wa
	ld wa, (xde)
	add wa, (xbc + 6)
	ld (xhl + 6), wa
	ld xwa, xbc
	ld xbc, xhl

SqedtVal2_DownScrollCalcOffset:
	ld bc, (xbc)
	add bc, (xwa + 4)
	ld (xhl + 4), bc

SqedtVal2_DrawScrollFrame:
	ld xwa, (xsp + 66)
	srl xwa, 8
	and xwa, 0xff
	cp a, 1:i3
	jr nz, SqedtVal2_DrawWithViewColors
	lda xwa, (xsp + 58)
	pushw 0xf2
	ld bc, 1:i3
	ld de, 2:i3
	jr SqedtVal2_CallDrawDesignFrame

SqedtVal2_DrawWithViewColors:
	lda xwa, (xsp + 58)
	ld xbc, (xsp + 8)
	pushm (xbc + 24)
	ld bc, 1:i3
	ld de, 2:i3

SqedtVal2_CallDrawDesignFrame:
	call DrawDesignFrame
	jrl AccIll_ReturnZero2

SqedtVal2_HandleSelectEvent:
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
	jrl nz, SqedtVal2_HandleSelectCase3
	ld (0x03e2e0:24), 0x00
	ld xwa, (xbc)
	ld xbc, EVT_GET_FROM_CUR
	ld xde, 0:i3
	call ApFuncCall
	ldfr_berp L, 0xfb
	cpib_erp 0xfb, 0
	jr z, SqedtVal2_CheckModeA2
	ld xde, 0:i3
	ldto_berp E, 0xfb
	ld xwa, (xsp + 74)
	ld xbc, EVT_SELE_DRAW
	call SendEvent
	dec1b_erp 0xfb
	ld xde, 0:i3
	ldto_berp E, 0xfb
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 26)
	ld xbc, EVT_SET_FROM_CUR
	call ApFuncCall
	ld xde, 0:i3
	ldto_berp E, 0xfb
	add xde, 0x100
	ld xwa, (xsp + 74)
	ld xbc, EVT_SELE_DRAW
	call SendEvent

SqedtVal2_CheckModeA2:
	cp (xsp + 6), 0xa2
	jr nz, SqedtVal2_CheckModeA4
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0xf
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x10
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x11
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x12
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x13
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x14
	jrl SqedtVal2_SendScrollAndDial

SqedtVal2_CheckModeA4:
	cp (xsp + 6), 0xa4
	jr nz, SqedtVal2_DefaultScrollSend
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x15
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x16
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x17
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x18
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x19
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x1a
	jr SqedtVal2_SendScrollAndDial

SqedtVal2_DefaultScrollSend:
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x1b
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x1c
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x1d
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x1e

SqedtVal2_SendScrollAndDial:
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_INDEXSW_UP
	ld xde, 2:i3
	call SetDialUp
	ld xwa, (xsp + 74)
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, 2:i3
	jrl AccIll_CallSetDialDown

SqedtVal2_HandleSelectCase3:
	ld xwa, (xsp + 66)
	cp xwa, 0x3
	jrl nz, SqedtVal2_HandleSelectCase2
	ld (0x03e2e0:24), 0x01
	ld xwa, (xbc)
	ld xbc, EVT_GET_TO_CUR
	ld xde, 0:i3
	call ApFuncCall
	ldfr_berp L, 0xfb
	cpib_erp 0xfb, 0
	jr z, SqedtVal2_SelectCase3_ModeA2
	ld xde, 0:i3
	ldto_berp E, 0xfb
	add xde, 0x10000
	ld xwa, (xsp + 74)
	ld xbc, EVT_SELE_DRAW
	call SendEvent
	dec1b_erp 0xfb
	ld xde, 0:i3
	ldto_berp E, 0xfb
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 26)
	ld xbc, EVT_SET_TO_CUR
	call ApFuncCall
	ld xde, 0:i3
	ldto_berp E, 0xfb
	add xde, 0x10100
	ld xwa, (xsp + 74)
	ld xbc, EVT_SELE_DRAW
	call SendEvent

SqedtVal2_SelectCase3_ModeA2:
	cp (xsp + 6), 0xa2
	jr nz, SqedtVal2_SelectCase3_ModeA4
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0xf
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x10
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x11
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x12
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x13
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x14
	jrl SqedtVal2_SelectCase3_SendDial

SqedtVal2_SelectCase3_ModeA4:
	cp (xsp + 6), 0xa4
	jr nz, SqedtVal2_SelectCase3_Default
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x15
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x16
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x17
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x18
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x19
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x1a
	jr SqedtVal2_SelectCase3_SendDial

SqedtVal2_SelectCase3_Default:
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x1b
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x1c
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x1d
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x1e

SqedtVal2_SelectCase3_SendDial:
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_INDEXSW_UP
	ld xde, 4:i3
	call SetDialUp
	ld xwa, (xsp + 74)
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, 4:i3
	jrl AccIll_CallSetDialDown

SqedtVal2_HandleSelectCase2:
	ld xwa, (xsp + 66)
	cp xwa, 0x2
	jrl nz, SqedtVal2_HandleSelectCase4
	ld (0x03e2e0:24), 0x00
	ld xwa, (xbc)
	ld xbc, EVT_GET_FROM_CUR
	ld xde, 0:i3
	call ApFuncCall
	ldfr_berp L, 0xfb
	cp (xsp + 6), 0xa2
	jr nz, SqedtVal2_SelectCase2_ModeA4
	ldto_berp E, 0xfb
	add e, 0xf
	ld d, 0x0:opc
	extz xde
	ld xwa, NAKA_MAINFUNC_ApEditSyori
	ld xbc, EVT_INC_VAL
	jr SqedtVal2_SelectCase2_PostEvent

SqedtVal2_SelectCase2_ModeA4:
	cp (xsp + 6), 0xa4
	jr nz, SqedtVal2_SelectCase2_Default
	ldto_berp E, 0xfb
	add e, 0x15
	ld d, 0x0:opc
	extz xde
	ld xwa, NAKA_MAINFUNC_ApEditSyori
	ld xbc, EVT_INC_VAL
	jr SqedtVal2_SelectCase2_PostEvent

SqedtVal2_SelectCase2_Default:
	ldto_berp E, 0xfb
	add e, 0x1b
	ld d, 0x0:opc
	extz xde
	ld xwa, NAKA_MAINFUNC_ApEditSyori
	ld xbc, EVT_INC_VAL

SqedtVal2_SelectCase2_PostEvent:
	call MainPostEvent
	ld xwa, (xsp + 74)
	ld xbc, (xsp + 70)
	ld xde, (xsp + 66)
	call SetAutoInc
	ld xwa, (xsp + 74)
	ld xbc, EVT_INDEXSW_UP
	ld xde, (xsp + 66)
	call SetDialUp
	ld xwa, (xsp + 74)
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, (xsp + 66)
	jrl AccIll_CallSetDialDown

SqedtVal2_HandleSelectCase4:
	ld xwa, (xsp + 66)
	cp xwa, 0x4
	jrl nz, AccIll_ReturnZero2
	ld (0x03e2e0:24), 0x01
	ld xwa, (xbc)
	ld xbc, EVT_GET_TO_CUR
	ld xde, 0:i3
	call ApFuncCall
	ldfr_berp L, 0xfb
	cp (xsp + 6), 0xa2
	jr nz, SqedtVal2_SelectCase4_ModeA4
	ldto_berp E, 0xfb
	add e, 0x12
	ld d, 0x0:opc
	extz xde
	ld xwa, NAKA_MAINFUNC_ApEditSyori
	ld xbc, EVT_INC_VAL
	jr SqedtVal2_SelectCase4_PostEvent

SqedtVal2_SelectCase4_ModeA4:
	cp (xsp + 6), 0xa4
	jr nz, SqedtVal2_SelectCase4_Default
	ldto_berp E, 0xfb
	add e, 0x18
	ld d, 0x0:opc
	extz xde
	ld xwa, NAKA_MAINFUNC_ApEditSyori
	ld xbc, EVT_INC_VAL
	jr SqedtVal2_SelectCase4_PostEvent

SqedtVal2_SelectCase4_Default:
	ldto_berp E, 0xfb
	add e, 0x1d
	ld d, 0x0:opc
	extz xde
	ld xwa, NAKA_MAINFUNC_ApEditSyori
	ld xbc, EVT_INC_VAL

SqedtVal2_SelectCase4_PostEvent:
	call MainPostEvent
	ld xwa, (xsp + 74)
	ld xbc, (xsp + 70)
	ld xde, (xsp + 66)
	call SetAutoInc
	ld xwa, (xsp + 74)
	ld xbc, EVT_INDEXSW_UP
	ld xde, (xsp + 66)
	call SetDialUp
	ld xwa, (xsp + 74)
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, (xsp + 66)
	jrl AccIll_CallSetDialDown

SqedtVal2_HandleUpScrollInner:
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
	jrl nz, SqedtVal2_HandleDownScrollInner
	ld (0x03e2e0:24), 0x00
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 26)
	ld xbc, EVT_GET_FROM_CUR
	ld xde, 0:i3
	call ApFuncCall
	ldfr_berp L, 0xfb
	ld xde, 0:i3
	ldto_berp E, 0xfb
	cp (xsp + 6), 0x91
	jr z, SqedtVal2_UpInner_CheckA8
	cp (xsp + 6), 0xa8
	jrl nz, SqedtVal2_UpInner_CheckA4

SqedtVal2_UpInner_CheckA8:
	cpib_erp 0xfb, 1
	jr nc, SqedtVal2_UpInner_SendExtra
	ld xwa, (xsp + 74)
	ld xbc, EVT_SELE_DRAW
	call SendEvent
	inc1b_erp 0xfb
	ld xde, 0:i3
	ldto_berp E, 0xfb
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 26)
	ld xbc, EVT_SET_FROM_CUR
	call ApFuncCall

SqedtVal2_UpInner_SendExtra:
	ld xde, 0:i3
	ldto_berp E, 0xfb
	add xde, 0x100
	ld xwa, (xsp + 74)
	ld xbc, EVT_SELE_DRAW
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x1b
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x1c
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x1d
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x1e
	jrl SqedtVal2_UpInner_SendDial

SqedtVal2_UpInner_CheckA4:
	cpib_erp 0xfb, 2
	jr nc, SqedtVal2_UpInner_SendFields
	ld xwa, (xsp + 74)
	ld xbc, EVT_SELE_DRAW
	call SendEvent
	inc1b_erp 0xfb
	ld xde, 0:i3
	ldto_berp E, 0xfb
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 26)
	ld xbc, EVT_SET_FROM_CUR
	call ApFuncCall
	ld xde, 0:i3
	ldto_berp E, 0xfb
	add xde, 0x100
	ld xwa, (xsp + 74)
	ld xbc, EVT_SELE_DRAW
	call SendEvent

SqedtVal2_UpInner_SendFields:
	cp (xsp + 6), 0xa2
	jr nz, SqedtVal2_UpInner_ModeA4Scroll
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0xf
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x10
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x11
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x12
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x13
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x14
	jr SqedtVal2_UpInner_SendDial

SqedtVal2_UpInner_ModeA4Scroll:
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x15
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x16
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x17
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x18
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x19
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x1a

SqedtVal2_UpInner_SendDial:
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_INDEXSW_UP
	ld xde, 2:i3
	call SetDialUp
	ld xwa, (xsp + 74)
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, 2:i3
	jrl AccIll_CallSetDialDown

SqedtVal2_HandleDownScrollInner:
	ld xwa, (xsp + 8)
	lda xbc, (xwa + 26)
	ld xwa, (xsp + 66)
	cp xwa, 0x3
	jrl nz, SqedtVal2_HandleDownCase2
	ld (0x03e2e0:24), 0x01
	ld xwa, (xbc)
	ld xbc, EVT_GET_TO_CUR
	ld xde, 0:i3
	call ApFuncCall
	ldfr_berp L, 0xfb
	ld xde, 0:i3
	ldto_berp E, 0xfb
	add xde, 0x10000
	cp (xsp + 6), 0x91
	jr z, SqedtVal2_DownInner_CheckA8
	cp (xsp + 6), 0xa8
	jrl nz, SqedtVal2_DownInner_CheckA4

SqedtVal2_DownInner_CheckA8:
	cpib_erp 0xfb, 1
	jr nc, SqedtVal2_DownInner_SendFields
	ld xwa, (xsp + 74)
	ld xbc, EVT_SELE_DRAW
	call SendEvent
	inc1b_erp 0xfb
	ld xde, 0:i3
	ldto_berp E, 0xfb
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 26)
	ld xbc, EVT_SET_TO_CUR
	call ApFuncCall
	ld xde, 0:i3
	ldto_berp E, 0xfb
	add xde, 0x10100
	ld xwa, (xsp + 74)
	ld xbc, EVT_SELE_DRAW
	call SendEvent

SqedtVal2_DownInner_SendFields:
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x1b
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x1c
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x1d
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x1e
	jrl SqedtVal2_DownInner_SendDial

SqedtVal2_DownInner_CheckA4:
	cpib_erp 0xfb, 2
	jr nc, SqedtVal2_DownInner_SendExtra
	ld xwa, (xsp + 74)
	ld xbc, EVT_SELE_DRAW
	call SendEvent
	inc1b_erp 0xfb
	ld xde, 0:i3
	ldto_berp E, 0xfb
	ld xwa, (xsp + 8)
	ld xwa, (xwa + 26)
	ld xbc, EVT_SET_TO_CUR
	call ApFuncCall
	ld xde, 0:i3
	ldto_berp E, 0xfb
	add xde, 0x10100
	ld xwa, (xsp + 74)
	ld xbc, EVT_SELE_DRAW
	call SendEvent

SqedtVal2_DownInner_SendExtra:
	cp (xsp + 6), 0xa2
	jr nz, SqedtVal2_DownInner_ModeA4Scroll
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0xf
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x10
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x11
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x12
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x13
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x14
	jr SqedtVal2_DownInner_SendDial

SqedtVal2_DownInner_ModeA4Scroll:
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x15
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x16
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x17
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x18
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x19
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_PARA_DRAW
	ld xde, 0x1a

SqedtVal2_DownInner_SendDial:
	call SendEvent
	ld xwa, (xsp + 74)
	ld xbc, EVT_INDEXSW_UP
	ld xde, 4:i3
	call SetDialUp
	ld xwa, (xsp + 74)
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, 4:i3
	jrl AccIll_CallSetDialDown

SqedtVal2_HandleDownCase2:
	ld xwa, (xsp + 66)
	cp xwa, 0x2
	jrl nz, SqedtVal2_HandleDownCase4
	ld (0x03e2e0:24), 0x00
	ld xwa, (xbc)
	ld xbc, EVT_GET_FROM_CUR
	ld xde, 0:i3
	call ApFuncCall
	ldfr_berp L, 0xfb
	cp (xsp + 6), 0xa2
	jr nz, SqedtVal2_DownCase2_ModeA4
	ldto_berp E, 0xfb
	add e, 0xf
	ld d, 0x0:opc
	extz xde
	ld xwa, NAKA_MAINFUNC_ApEditSyori
	ld xbc, EVT_DEC_VAL
	jr SqedtVal2_DownCase2_PostEvent

SqedtVal2_DownCase2_ModeA4:
	cp (xsp + 6), 0xa4
	jr nz, SqedtVal2_DownCase2_Default
	ldto_berp E, 0xfb
	add e, 0x15
	ld d, 0x0:opc
	extz xde
	ld xwa, NAKA_MAINFUNC_ApEditSyori
	ld xbc, EVT_DEC_VAL
	jr SqedtVal2_DownCase2_PostEvent

SqedtVal2_DownCase2_Default:
	ldto_berp E, 0xfb
	add e, 0x1b
	ld d, 0x0:opc
	extz xde
	ld xwa, NAKA_MAINFUNC_ApEditSyori
	ld xbc, EVT_DEC_VAL

SqedtVal2_DownCase2_PostEvent:
	call MainPostEvent
	ld xwa, (xsp + 74)
	ld xbc, (xsp + 70)
	ld xde, (xsp + 66)
	call SetAutoInc
	ld xwa, (xsp + 74)
	ld xbc, EVT_INDEXSW_UP
	ld xde, (xsp + 66)
	call SetDialUp
	ld xwa, (xsp + 74)
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, (xsp + 66)
	jrl AccIll_CallSetDialDown

SqedtVal2_HandleDownCase4:
	ld xwa, (xsp + 66)
	cp xwa, 0x4
	jrl nz, AccIll_ReturnZero2
	ld (0x03e2e0:24), 0x01
	ld xwa, (xbc)
	ld xbc, EVT_GET_TO_CUR
	ld xde, 0:i3
	call ApFuncCall
	ldfr_berp L, 0xfb
	cp (xsp + 6), 0xa2
	jr nz, SqedtVal2_DownCase4_ModeA4
	ldto_berp E, 0xfb
	add e, 0x12
	ld d, 0x0:opc
	extz xde
	ld xwa, NAKA_MAINFUNC_ApEditSyori
	ld xbc, EVT_DEC_VAL
	jr SqedtVal2_DownCase4_PostEvent

SqedtVal2_DownCase4_ModeA4:
	cp (xsp + 6), 0xa4
	jr nz, SqedtVal2_DownCase4_Default
	ldto_berp E, 0xfb
	add e, 0x18
	ld d, 0x0:opc
	extz xde
	ld xwa, NAKA_MAINFUNC_ApEditSyori
	ld xbc, EVT_DEC_VAL
	jr SqedtVal2_DownCase4_PostEvent

SqedtVal2_DownCase4_Default:
	ldto_berp E, 0xfb
	add e, 0x1d
	ld d, 0x0:opc
	extz xde
	ld xwa, NAKA_MAINFUNC_ApEditSyori
	ld xbc, EVT_DEC_VAL

SqedtVal2_DownCase4_PostEvent:
	call MainPostEvent
	ld xwa, (xsp + 74)
	ld xbc, (xsp + 70)
	ld xde, (xsp + 66)
	call SetAutoInc
	ld xwa, (xsp + 74)
	ld xbc, EVT_INDEXSW_UP
	ld xde, (xsp + 66)
	call SetDialUp
	ld xwa, (xsp + 74)
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, (xsp + 66)

AccIll_CallSetDialDown:
	call SetDialDown

AccIll_ReturnZero2:
	ld xhl, 0:i3

SqedtVal2_Epilogue:
	pop xiz
	lda xsp, (xsp + 74)
	ret

AccIllProc:
	lda xsp, (xsp - 66)
	push xiz
	ld (xsp + 62), xde
	ld xiz, xbc
	ld (xsp + 66), xwa
	cp xiz, EVT_INDEXSW_DOWN
	jrl z, AccIll_HandleDownScroll
	cp xiz, EVT_INDEXSW_UP
	jrl z, AccIll_HandleUpScroll
	cp xiz, EVT_EFF_PARA_DRAW
	jrl z, AccIll_HandleVertSlider
	cp xiz, EVT_EFF_FIX_DRAW
	jr z, AccIll_HandleHorizSlider
	cp xiz, EVT_RET_EFF_PARA
	jr z, AccIll_HandleUpperPanelEvent
	cp xiz, EVT_RET_EFF_FIX
	jr z, AccIll_HandleLowerPanelEvent
	cp xiz, EVT_PAINT
	jrl nz, AccIll_PassThrough
	ld xwa, (xsp + 66)
	ld xbc, xiz
	ld xde, (xsp + 62)
	call InheritedProc
	ld xde, (xsp + 66)
	ld xwa, NAKA_MAINFUNC_EffEditMain
	ld xbc, xiz
	call MainPostEvent
	ld xwa, (xsp + 66)
	ld xbc, EVT_INDEXSW_UP
	ld xde, 1:i3
	call SetDialUp
	ld xwa, (xsp + 66)
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, 1:i3
	call SetDialDown
	ld wa, 1:i3
	jrl AccIll_CallSortedUpdate

AccIll_HandleLowerPanelEvent:
	ld xwa, (xsp + 66)
	ld xbc, EVT_EFF_FIX_DRAW
	ld xde, 0:i3
	jr AccIll_PanelDispatch

AccIll_HandleUpperPanelEvent:
	ld xwa, (xsp + 62)
	or xwa, xwa
	jrl nz, AccIll_ReturnZero
	ld xwa, (xsp + 66)
	ld xbc, EVT_EFF_PARA_DRAW
	ld xde, 0:i3

AccIll_PanelDispatch:
	call SendEvent
	jrl AccIll_ReturnZero

AccIll_HandleHorizSlider:
	ld xwa, (xsp + 66)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 26)
	ld xbc, EVT_GET_TTL_NOW
	ld xde, 0:i3
	call ApFuncCall
	ld xwa, (xsp + 4)
	cp l, (xwa + 30)
	jrl nz, AccIll_ReturnZero
	lda xix, (xsp + 54)
	ldw (xix), 0x64
	lda xbc, (xix + 2)
	ldw (xbc), 0x5e
	lda xde, (xix + 4)
	ld wa, (xix)
	add wa, 0xb4
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
	ld (xwa+), 0x00
	cp xwa, xbc
	jr c, AccIll_ClearDrawBuffer1
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 26)
	ld xbc, EVT_GET_RAM_ADDRESS
	ld xde, 0:i3
	call ApFuncCall
	lda xde, (xsp + 8)
	ld (xde), xhl
	lda xwa, (xsp + 30)
	ld (xde + 18), xwa
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 26)
	ld xbc, EVT_GET_RAM_STRING
	call ApFuncCall
	lda xwa, (xsp + 54)
	lda xbc, (xsp + 50)
	lda xde, (xsp + 30)
	ld xhl, 4:i3
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
	ld xbc, EVT_GET_TTL_NOW
	ld xde, 0:i3
	call ApFuncCall
	ld xwa, (xsp + 4)
	cp l, (xwa + 30)
	jrl nz, AccIll_ReturnZero
	lda xix, (xsp + 54)
	ldw (xix), 0xb2
	lda xbc, (xix + 2)
	ldw (xbc), 0x91
	lda xde, (xix + 4)
	ld wa, (xix)
	add wa, 0x2d
	ld (xde), wa
	lda xhl, (xix + 6)
	ld wa, (xbc)
	add wa, 0xc
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
	ld (xwa+), 0x00
	cp xwa, xbc
	jr c, AccIll_ClearDrawBuffer2
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 26)
	ld xbc, EVT_GET_RAM_ADDRESS
	ld xde, 1:i3
	call ApFuncCall
	lda xde, (xsp + 8)
	ld (xde), xhl
	lda xwa, (xsp + 30)
	ld (xde + 18), xwa
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 26)
	ld xbc, EVT_GET_ACC_LVL_STR
	call ApFuncCall
	lda xwa, (xsp + 54)
	lda xbc, (xsp + 50)
	lda xde, (xsp + 30)
	ld xhl, 1:i3
	push xhl
	pushw 0x0
	pushw 0xff

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
	ld xwa, NAKA_MAINFUNC_EffEditMain
	ld xbc, EVT_CNG_EFF_TYPE
	ld xde, 1:i3
	jr AccIll_UpScroll_Dispatch

AccIll_UpScroll_Mode1:
	ld xwa, (xsp + 62)
	cp xwa, 0x1
	jr nz, AccIll_UpScroll_Refresh
	ld xwa, NAKA_MAINFUNC_EffEditMain
	ld xbc, EVT_CNG_EFF_PARA
	ld xde, 0x100

AccIll_UpScroll_Dispatch:
	call MainPostEvent

AccIll_UpScroll_Refresh:
	ld xwa, (xsp + 66)
	ld xbc, xiz
	ld xde, (xsp + 62)
	call SetAutoInc
	ld xwa, (xsp + 66)
	ld xbc, EVT_INDEXSW_UP
	ld xde, 1:i3
	call SetDialUp
	ld xwa, (xsp + 66)
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, 1:i3
	call SetDialDown
	ld wa, 1:i3
	jr AccIll_CallSortedUpdate

AccIll_HandleDownScroll:
	ld xwa, (xsp + 66)
	ld xbc, xiz
	ld xde, (xsp + 62)
	call InheritedProc
	ld xwa, (xsp + 62)
	or xwa, xwa
	jr nz, AccIll_DownScroll_Mode1
	ld xwa, NAKA_MAINFUNC_EffEditMain
	ld xbc, EVT_CNG_EFF_TYPE
	ld xde, 0xffffffff
	jr AccIll_DownScroll_Dispatch

AccIll_DownScroll_Mode1:
	ld xwa, (xsp + 62)
	cp xwa, 0x1
	jr nz, AccIll_DownScroll_Refresh
	ld xwa, NAKA_MAINFUNC_EffEditMain
	ld xbc, EVT_CNG_EFF_PARA
	ld xde, 0xffffff00

AccIll_DownScroll_Dispatch:
	call MainPostEvent

AccIll_DownScroll_Refresh:
	ld xwa, (xsp + 66)
	ld xbc, xiz
	ld xde, (xsp + 62)
	call SetAutoInc
	ld xwa, (xsp + 66)
	ld xbc, EVT_INDEXSW_UP
	ld xde, 1:i3
	call SetDialUp
	ld xwa, (xsp + 66)
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, 1:i3
	call SetDialDown
	ld wa, 1:i3

AccIll_CallSortedUpdate:
	call SetDialEnable

AccIll_ReturnZero:
	ld xhl, 0:i3
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
	lda xsp, (xsp-342)
	push xiz
	ld	(xsp+334), xde
	ld	(xsp+338), xbc
	ld	(xsp+342), xwa
	ld xiy, EffectBoxProc_LocalInit
	lda xix, (xsp + 12)
	ldiw
	ldiw
	ld xiy, EffectBoxProc_LocalInit_2
	lda xix, (xsp + 8)
	ldiw
	ldiw
	ld XWA, (xsp + 0x0152)
	cp xwa, EVT_INDEXSW_DOWN
	jrl z, EffectBox_HandleCase0_Post
	cp xwa, EVT_INDEXSW_UP
	jrl z, EffectBox_HandleDefaultEvent
	cp xwa, EVT_EFF_PARA_DRAW
	jrl z, EffectBox_HandleSelectEvent
	cp xwa, EVT_EFF_FIX_DRAW
	jrl z, EffectBox_HandleScrollEvent
	cp xwa, EVT_RET_EFF_PARA
	jrl z, EffectBox_HandleEvent1
	cp xwa, EVT_RET_EFF_FIX
	jrl z, EffectBox_HandleEvent0
	cp xwa, EVT_SELE_DRAW
	jrl z, EffectBox_HandleInitEvent
	cp xwa, EVT_PAINT
	jrl nz, EffectBox_HandleInherited
	ld XWA, (xsp + 0x0156)
	ld XBC, (xsp + 0x0152)
	ld XDE, (xsp + 0x014e)
	call InheritedProc
	ld XWA, (xsp + 0x0156)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 28)
	ld xbc, EVT_SET_ITEM_TOP
	ld xde, 0:i3
	call ApFuncCall
	ld xwa, (xiz + 28)
	ld xbc, EVT_SET_ITEM_OFF
	ld xde, 0:i3
	call ApFuncCall
	ld XWA, (xsp + 0x0156)
	ld xbc, EVT_SELE_DRAW
	ld xde, 1:i3
	call SendEvent
	ld XDE, (xsp + 0x0156)
	ld xwa, NAKA_MAINFUNC_EffEditMain
	ld XBC, (xsp + 0x0152)
	call MainPostEvent
	ld XWA, (xsp + 0x0156)
	ld xbc, EVT_INDEXSW_UP
	ld xde, 2:i3
	call SetDialUp
	ld XWA, (xsp + 0x0156)
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, 2:i3
	call SetDialDown
	ld wa, 1:i3
	jrl EffectBox_SetDialDownAndEnable

EffectBox_HandleInitEvent:
	ld XWA, (xsp + 0x0156)
	ld XBC, (xsp + 0x0152)
	ld XDE, (xsp + 0x014e)
	call InheritedProc
	ld XWA, (xsp + 0x0156)
	call GetViewInstance
	ld xiz, xhl
	ld xwa, (xiz + 28)
	ld xbc, EVT_GET_TTL_NOW
	ld xde, 0:i3
	call ApFuncCall
	cp l, (xiz + 36)
	jrl nz, EffectBoxProc_ReturnZero
	ld xwa, (xiz + 28)
	ld xbc, EVT_GET_ITEM_OFF
	ld xde, 0:i3
	call ApFuncCall
	ld xbc, EffectBox_HandleInitEvent_Table
	add xbc, xhl
	lda xwa, (xsp+326)
	lda xde, (xwa + 2)
	ld c, (xbc)
	extz bc
	ld (xde), bc
	ldw (xwa), 0x3a
	ld bc, (xde)
	add bc, 0x10
	ld (xwa + 6), bc
	ld bc, (xwa)
	add bc, 0xdf
	ld (xwa + 4), bc
	ld XBC, (xsp + 0x014e)
	cp xbc, 0x1
	jr nz, EffectBox_DrawWithViewFrame
	pushw 0xf2
	ld bc, 1:i3
	ld de, 2:i3
	jr EffectBox_CallDrawDesignFrame

EffectBox_DrawWithViewFrame:
	pushm (xiz + 22)
	ld bc, 1:i3
	ld de, 2:i3

EffectBox_CallDrawDesignFrame:
	call DrawDesignFrame
	jrl EffectBoxProc_ReturnZero

EffectBox_HandleEvent0:
	ld XWA, (xsp + 0x0156)
	ld xbc, EVT_EFF_FIX_DRAW
	ld xde, 0:i3
	jr EffectBox_SendEventCommon

EffectBox_HandleEvent1:
	ld XWA, (xsp + 0x0156)
	call GetViewInstance
	ld xwa, (xhl + 28)
	ld xbc, EVT_GET_ITEM_TOP
	ld xde, 0:i3
	call ApFuncCall
	sub	(xsp+334), xhl
	ld XWA, (xsp + 0x014e)
	cp xwa, 0x8
	jrl nc, EffectBoxProc_ReturnZero
	ld XWA, (xsp + 0x0156)
	ld xbc, EVT_EFF_PARA_DRAW
	ld XDE, (xsp + 0x014e)

EffectBox_SendEventCommon:
	call SendEvent
	jrl EffectBoxProc_ReturnZero

EffectBox_HandleScrollEvent:
	ld XWA, (xsp + 0x0156)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld xbc, EVT_GET_TTL_NOW
	ld xde, 0:i3
	call ApFuncCall
	ld xwa, (xsp + 4)
	cp l, (xwa + 36)
	jrl nz, EffectBoxProc_ReturnZero
	lda xix, (xsp+318)
	ldw (xix), 0x64
	lda xbc, (xix + 2)
	ldw (xbc), 0x26
	lda xde, (xix + 4)
	ld wa, (xix)
	add wa, 0xb9
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
	lda xde, (xsp+314)
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

EffectBox_FillBufferLoop1:
	ld (xwa+), 0x00
	cp xwa, xbc
	jr c, EffectBox_FillBufferLoop1
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld xbc, EVT_GET_RAM_ADDRESS
	ld xde, 0:i3
	call ApFuncCall
	lda xde, (xsp + 16)
	ld (xde), xhl
	lda xwa, (xsp + 38)
	ld (xde + 18), xwa
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld xbc, EVT_GET_RAM_STRING
	call ApFuncCall
	lda xwa, (xsp+318)
	lda xbc, (xsp+314)
	lda xde, (xsp + 38)
	ld xhl, 4:i3
	push xhl
	pushw 0xff
	ld xhl, (xsp + 10)
	pushm (xhl + 22)
	call DrawStringLeftJustify
	lda xbc, (xsp+318)
	ldw (xbc), 0x3a
	ldw wa, 0x3a
	add wa, 0x8c
	ld (xbc + 4), wa
	sub wa, (xbc)
	exts xwa
	divs wa, 0x2
	ld bc, (xbc)
	add bc, wa
	ld	(xsp+314), bc
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld xbc, EVT_GET_RAM_ADDRESS
	ld xde, 0:i3
	call ApFuncCall
	lda xde, (xsp + 16)
	ld (xde), xhl
	lda xwa, (xsp + 58)
	ld (xde + 18), xwa
	lda xbc, (xsp + 38)
	ld xwa, xbc
	lda xbc, (xbc + 20)

EffectBox_FillBufferLoop2:
	ld (xwa+), 0x00
	cp xwa, xbc
	jr c, EffectBox_FillBufferLoop2
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld xbc, EVT_GET_EFF_FIX_STRING
	call ApFuncCall
	ld iz, 0:i3

EffectBox_PostFillSetup:
	lda xde, (xsp+318)
	lda xbc, (xde+2)
	ld wa, iz
	extz xwa
	ld xhl, EffectBox_PostFillSetup_Table
	add xhl, xwa
	ld a, (xhl)
	extz wa
	ld (xbc), wa
	add wa, 12
	ld (xde+6), wa
	ld bc, (xbc)
	sub wa, bc
	exts xwa
	divs wa, 2
	add bc, wa
	ld (xsp+316), bc
	pushw 0x0011
	ld wa, iz
	mul wa, 17
	lda xbc, (xsp+60)
	add xbc, xwa
	push xbc
	lda xwa, (xsp+44)
	push xwa
	call CmpNamingCheck_Helper
	lda xsp, (xsp+10)
	lda xwa, (xsp+318)
	lda xbc, (xsp+314)
	lda xde, (xsp+38)
	ld xhl, 0:i3
	push xhl
	pushw 0x00ff
	ld xhl, (xsp+10)
	pushm (xhl+22)
	call DrawStringLeftJustify
	inc 1, iz
	cp iz, 8
	jr c, EffectBox_PostFillSetup
	lda xbc, (xsp+318)
	ldw (xbc), 256
	ldw wa, 256
	add wa, 20
	ld (xbc+4), wa
	sub wa, (xbc)
	exts xwa
	divs wa, 2
	ld bc, (xbc)
	add bc, wa
	ld (xsp+314), bc
	lda xbc, (xsp+38)
	ld xwa, xbc
	lda xbc, (xbc+20)
EffectBox_FillBufferLoop3:
	ld (xwa+), 0x00
	cp xwa, xbc
	jr c, EffectBox_FillBufferLoop3
	ld iz, 0:i3
EffectBox_PostFill3Setup:
	lda	xde, (xsp+318)
	lda	xbc, (xde+2)
	ld	wa, iz
	extz	xwa
	ld	xhl, EffectBox_PostFillSetup_Table
	add	xhl, xwa
	ld	a, (xhl)
	extz	wa
	ld	(xbc), wa
	add	wa, 12
	ld	(xde+6), wa
	ld	bc, (xbc)
	sub	wa, bc
	exts	xwa
	divs	wa, 2
	add	bc, wa
	ld	(xsp+316), bc
	pushw 2
	ld	wa, iz
	add	wa, wa
	extz	xwa
	lda	xwa, (xwa+136)
	lda	xbc, (xsp+60)
	add	xbc, xwa
	push	xbc
	lda	xwa, (xsp+44)
	push	xwa
	call	CmpNamingCheck_Helper
	lda	xsp, (xsp+10)
	lda	xwa, (xsp+318)
	lda	xbc, (xsp+314)
	lda	xde, (xsp+38)
	ld	xhl, 0:i3
	push	xhl
	pushw 255
	ld	xhl, (xsp+10)
	pushm (xhl+22)
	call	DrawStringLeftJustify
	inc	1, iz
	cp	iz, 8
	jr	c, EffectBox_PostFill3Setup
	lda	xix, (xsp+318)
	ldw	(xix), 43
	lda	xde, (xix+4)
	ld	wa, (xix)
	add	wa, 14
	ld	(xde), wa
	lda	xbc, (xix+2)
	ldw	(xbc), 70
	lda	xhl, (xix+6)
	ldw	(xhl), 84
	ld	wa, (xde)
	sub wa, (xix)
	exts	xwa
	divs	wa, 2
	ld	ix, (xix)
	add	ix, wa
	lda	xde, (xsp+314)
	ld	(xde), ix
	ld	bc, (xbc)
	ld	wa, (xhl)
	sub	wa, bc
	exts	xwa
	divs	wa, 2
	add	bc, wa
	ld	(xde+2), bc
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+28)
	ld	xbc, EVT_GET_ITEM_TOP
	ld	xde, 0:i3
	call	ApFuncCall
	or	xhl, xhl
	jr	z, EffectBox_SetEmptyString1
	pushw 0x0004
	lda	xwa, (xsp+14)
	push	xwa
	lda	xwa, (xsp+44)
	push	xwa
	call	CmpNamingCheck_Helper
	lda	xsp, (xsp+10)
	ld	(xsp+42), 0
	jr	EffectBox_DrawField1
EffectBox_SetEmptyString1:
	lda xwa, (xsp + 38)
	ld (xwa), 0x20
	ld (xwa + 1), 0x0
EffectBox_DrawField1:
	lda	xwa, (xsp+318)
	lda	xbc, (xsp+314)
	lda	xde, (xsp+38)
	ld	xhl, 0:i3
	push	xhl
	pushw 255
	ld	xhl, (xsp+10)
	pushm (xhl+22)
	call	DrawStringLeftJustify
	lda	xbc, (xsp+318)
	lda	xwa, (xbc+2)
	ldw	(xwa), 182
	ldw	(xbc+6), 196
	ld	bc, (xwa)
	ldw	wa, 196
	sub	wa, bc
	exts	xwa
	divs	wa, 2
	add	bc, wa
	ld	(xsp+316), bc
	ldib_erp	251, 7
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+28)
	ld	xbc, EVT_GET_ITEM_TOP
	ld	xde, 0:i3
	call	ApFuncCall
	ldto_berp	a, 251
	add	a, l
	ldfr_berp	a, 251
	ld	xde, 0:i3
	ldto_berp	e, 251
	inc	1, xde
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+28)
	ld	xbc, EVT_GET_ITEM_EXIST
	call	ApFuncCall
	lda	xwa, (xsp+38)
	or	xhl, xhl
	jr	z, EffectBox_SetEmptyString2
	pushw 0x0004
	lda	xbc, (xsp+10)
	push	xbc
	push	xwa
	call	CmpNamingCheck_Helper
	lda	xsp, (xsp+10)
	ld	(xsp+42), 0
	jr	EffectBox_DrawField2
EffectBox_SetEmptyString2:
	ld (xwa), 0x20
	ld (xwa + 1), 0x0

EffectBox_DrawField2:
	lda xwa, (xsp+318)
	lda xbc, (xsp+314)
	lda xde, (xsp + 38)
	ld xhl, 0:i3
	push xhl
	pushw 0xff
	ld xhl, (xsp + 10)
	pushm (xhl + 22)
	call DrawStringLeftJustify
	ld iz, 0:i3

EffectBox_DrawAndSendLoop:
	ld de, iz
	extz xde
	ld XWA, (xsp + 0x0156)
	ld xbc, EVT_EFF_PARA_DRAW
	call SendEvent
	inc 1, iz
	cp iz, 0x8
	jr c, EffectBox_DrawAndSendLoop
	jrl EffectBoxProc_ReturnZero

EffectBox_HandleSelectEvent:
	ld XWA, (xsp + 0x014e)
	cp xwa, 0x7
	jrl ugt, EffectBoxProc_ReturnZero
	ld XWA, (xsp + 0x0156)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld xbc, EVT_GET_TTL_NOW
	ld xde, 0:i3
	call ApFuncCall
	ld xwa, (xsp + 4)
	cp l, (xwa + 36)
	jrl nz, EffectBoxProc_ReturnZero
	lda xix, (xsp+318)
	ldw (xix), 0xc3
	lda xde, (xix + 4)
	ld wa, (xix)
	add wa, 0x3d
	ld (xde), wa
	lda xbc, (xix + 2)
	ld xwa, EffectBox_PostFillSetup_Table
	add	xwa, (xsp+334)
	ld a, (xwa)
	extz wa
	ld (xbc), wa
	lda xhl, (xix + 6)
	add wa, 0xc
	ld (xhl), wa
	ld wa, (xde)
	sub wa, (xix)
	exts xwa
	divs wa, 0x2
	ld ix, (xix)
	add ix, wa
	lda xde, (xsp+314)
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
	ld (xwa+), 0x00
	cp xwa, xbc
	jr c, EffectBox_NameSetup
	ld XDE, (xsp + 0x014e)
	inc 1, xde
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld xbc, EVT_GET_RAM_ADDRESS
	call ApFuncCall
	lda xde, (xsp + 16)
	ld (xde), xhl
	lda xwa, (xsp + 58)
	ld (xde + 18), xwa
	ld XHL, (xsp + 0x014e)
	ld xwa, (xsp + 4)
	lda xbc, (xwa + 28)
	dec 1, xhl
	cp xhl, 0x0
	jr c, EffectBoxProc_CopyNameAndSetup
	cp xhl, 0x6
	jr ugt, EffectBoxProc_CopyNameAndSetup
	add xhl, xhl
	add xhl, EffectBox_NameSetup_CaseTable
	ld hl, (xhl)
	lda xix, (EffectBox_Dispatch:24)
	jp	t, (xix+hl)
; EffectBoxProc dispatch
EffectBox_Dispatch:
	ld	xwa, (xbc)
	ld	xbc, EVT_GET_EFF_DLT1_STR
	jr	EffectBox_Dispatch_Join
	ld	xwa, (xbc)
	ld	xbc, EVT_GET_EFF_DLT2_STR
	jr	EffectBox_Dispatch_Join
	ld	xwa, (xbc)
	ld	xbc, EVT_GET_EFF_DLT3_STR
	jr	EffectBox_Dispatch_Join
	ld	xwa, (xbc)
	ld	xbc, EVT_GET_EFF_DLT4_STR
	jr	EffectBox_Dispatch_Join
	ld	xwa, (xbc)
	ld	xbc, EVT_GET_EFF_DLT5_STR
	jr	EffectBox_Dispatch_Join
	ld	xwa, (xbc)
	ld	xbc, EVT_GET_EFF_DLT6_STR
	jr	EffectBox_Dispatch_Join
	ld	xwa, (xbc)
	ld	xbc, EVT_GET_EFF_DLT7_STR
	jr	EffectBox_Dispatch_Join

EffectBoxProc_CopyNameAndSetup:
	ld xwa, (xsp+4)
	ld xwa, (xwa+28)
	ld xbc, EVT_GET_EFF_DLT0_STR
EffectBox_Dispatch_Join:
	call ApFuncCall
	pushw 0x0007
	lda xwa, (xsp+60)
	push xwa
	lda xwa, (xsp+44)
	push xwa
	call CmpNamingCheck_Helper
	lda xsp, (xsp+10)
	ld xwa, (xsp+4)
	ld xwa, (xwa+28)
	ld xbc, EVT_GET_ITEM_OFF
	ld xde, 0:i3
	call ApFuncCall
	lda xwa, (xsp+318)
	lda xbc, (xsp+314)
	cp xhl, (xsp+334)
	jr nz, EffectBox_DrawWithFBColor
	lda xde, (xsp+38)
	ld xhl, 0:i3
	push xhl
	pushw 0x0000
	pushw 0x00ff
	jr EffectBox_DrawStringAndSetDial
EffectBox_DrawWithFBColor:
	lda xde, (xsp + 38)
	ld xhl, 0:i3
	push xhl
	pushw 0xff
	ld xhl, (xsp + 10)
	pushm (xhl + 22)

EffectBox_DrawStringAndSetDial:
	call DrawStringLeftJustify
	ld XWA, (xsp + 0x0156)
	ld xbc, EVT_INDEXSW_UP
	ld xde, 2:i3
	call SetDialUp
	ld XWA, (xsp + 0x0156)
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, 2:i3
	call SetDialDown
	ld wa, 1:i3

EffectBox_SetDialDownAndEnable:
	call SetDialEnable
	jrl EffectBoxProc_ReturnZero

EffectBox_HandleDefaultEvent:
	ld XWA, (xsp + 0x0156)
	ld XBC, (xsp + 0x0152)
	ld XDE, (xsp + 0x014e)
	call InheritedProc
	ld XWA, (xsp + 0x0156)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	lda xbc, (xwa + 28)
	ld XWA, (xsp + 0x014e)
	cp xwa, 0x1
	jrl nz, EffectBox_HandleCase2
	ld xwa, (xbc)
	ld xbc, EVT_GET_ITEM_OFF
	ld xde, 0:i3
	call ApFuncCall
	ldfr_berp L, 0xfa
	cpib_erp 0xfa, 0
	jr z, EffectBox_RedrawAfterChange
	ld XWA, (xsp + 0x0156)
	ld xbc, EVT_SELE_DRAW
	ld xde, 0:i3
	call SendEvent
	ldto_berp A, 0xfa
	dec 1, a
	ldfr_berp A, 0xfb
	ld xde, 0:i3
	ldto_berp E, 0xfb
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld xbc, EVT_SET_ITEM_OFF
	call ApFuncCall
	ld XWA, (xsp + 0x0156)
	ld xbc, EVT_SELE_DRAW
	ld xde, 1:i3
	call SendEvent
	ld xde, 0:i3
	ldto_berp E, 0xfa
	ld XWA, (xsp + 0x0156)
	ld xbc, EVT_EFF_PARA_DRAW
	call SendEvent
	ld xde, 0:i3
	ldto_berp E, 0xfb
	ld XWA, (xsp + 0x0156)
	ld xbc, EVT_EFF_PARA_DRAW
	call SendEvent
	jr EffectBoxProc_RestoreAndJumpToDispatch

EffectBox_RedrawAfterChange:
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld xbc, EVT_GET_ITEM_TOP
	ld xde, 0:i3
	call ApFuncCall
	ldfr_berp L, 0xfb
	cpib_erp 0xfb, 0
	jr z, EffectBoxProc_RestoreAndJumpToDispatch
	dec1b_erp 0xfb
	ld xde, 0:i3
	ldto_berp E, 0xfb
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld xbc, EVT_SET_ITEM_TOP
	call ApFuncCall
	ld XWA, (xsp + 0x0156)
	ld xbc, EVT_EFF_FIX_DRAW
	ld xde, 0:i3
	call SendEvent
	ld iz, 0:i3

EffectBox_SendLoopValue:
	ld de, iz
	extz xde
	ld XWA, (xsp + 0x0156)
	ld xbc, EVT_EFF_PARA_DRAW
	call SendEvent
	inc 1, iz
	cp iz, 0x8
	jr c, EffectBox_SendLoopValue

EffectBoxProc_RestoreAndJumpToDispatch:
	ld XWA, (xsp + 0x0156)
	ld XBC, (xsp + 0x0152)
	ld XDE, (xsp + 0x014e)
	jrl EffectBox_SetAutoInc

EffectBox_HandleCase2:
	ld XWA, (xsp + 0x014e)
	cp xwa, 0x2
	jr nz, EffectBox_HandleCaseOther
	ld xwa, (xbc)
	ld xbc, EVT_GET_ITEM_TOP
	ld xde, 0:i3
	call ApFuncCall
	ldfr_berp L, 0xfb
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld xbc, EVT_GET_ITEM_OFF
	ld xde, 0:i3
	call ApFuncCall
	ldto_berp A, 0xfb
	add a, l
	ldfr_berp A, 0xfb
	ld xde, 0:i3
	ldto_berp E, 0xfb
	add xde, 0x100
	ld xwa, NAKA_MAINFUNC_EffEditMain
	ld xbc, EVT_CNG_EFF_PARA
	call MainPostEvent
	ld XWA, (xsp + 0x0156)
	ld XBC, (xsp + 0x0152)
	ld XDE, (xsp + 0x014e)
	jrl EffectBox_SetAutoInc

EffectBox_HandleCaseOther:
	ld XWA, (xsp + 0x014e)
	or xwa, xwa
	jrl nz, EffectBoxProc_ReturnZero
	ld xwa, NAKA_MAINFUNC_EffEditMain
	ld xbc, EVT_CNG_EFF_TYPE
	ld xde, 1:i3
	call MainPostEvent
	ld XWA, (xsp + 0x0156)
	ld xbc, EVT_SELE_DRAW
	ld xde, 0:i3
	call SendEvent
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld xbc, EVT_SET_ITEM_TOP
	ld xde, 0:i3
	call ApFuncCall
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld xbc, EVT_SET_ITEM_OFF
	ld xde, 0:i3
	call ApFuncCall
	ld XWA, (xsp + 0x0156)
	ld xbc, EVT_SELE_DRAW
	ld xde, 1:i3
	call SendEvent
	ld XWA, (xsp + 0x0156)
	ld XBC, (xsp + 0x0152)
	ld XDE, (xsp + 0x014e)
	jrl EffectBox_SetAutoInc

EffectBox_HandleCase0_Post:
	ld XWA, (xsp + 0x0156)
	ld XBC, (xsp + 0x0152)
	ld XDE, (xsp + 0x014e)
	call InheritedProc
	ld XWA, (xsp + 0x0156)
	call GetViewInstance
	ld (xsp + 4), xhl
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld XBC, (xsp + 0x014e)
	cp xbc, 0x1
	jrl nz, EffectBox_HandleAppFunc
	ld xbc, EVT_GET_ITEM_OFF
	ld xde, 0:i3
	call ApFuncCall
	ldfr_berp L, 0xfa
	ld xwa, (xsp + 4)
	lda xbc, (xwa + 28)
	cpib_erp 0xfa, 7
	jr nc, EffectBox_RedrawFullLoop
	ldto_berp E, 0xfa
	inc 1, e
	ld d, 0x0:opc
	extz xde
	ld xwa, (xbc)
	ld xbc, EVT_GET_ITEM_EXIST
	call ApFuncCall
	or xhl, xhl
	jrl z, EffectBox_SetAutoIncAfterLoop
	ld XWA, (xsp + 0x0156)
	ld xbc, EVT_SELE_DRAW
	ld xde, 0:i3
	call SendEvent
	ldto_berp A, 0xfa
	inc 1, a
	ldfr_berp A, 0xfb
	ld xde, 0:i3
	ldto_berp E, 0xfb
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld xbc, EVT_SET_ITEM_OFF
	call ApFuncCall
	ld XWA, (xsp + 0x0156)
	ld xbc, EVT_SELE_DRAW
	ld xde, 1:i3
	call SendEvent
	ld xde, 0:i3
	ldto_berp E, 0xfa
	ld XWA, (xsp + 0x0156)
	ld xbc, EVT_EFF_PARA_DRAW
	call SendEvent
	ld xde, 0:i3
	ldto_berp E, 0xfb
	ld XWA, (xsp + 0x0156)
	ld xbc, EVT_EFF_PARA_DRAW
	call SendEvent
	jrl EffectBox_SetAutoIncAfterLoop

EffectBox_RedrawFullLoop:
	ld xwa, (xbc)
	ld xbc, EVT_GET_ITEM_TOP
	ld xde, 0:i3
	call ApFuncCall
	ldto_berp A, 0xfa
	add a, l
	ldfr_berp A, 0xfa
	ldto_berp E, 0xfa
	inc 1, e
	ld d, 0x0:opc
	extz xde
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld xbc, EVT_GET_ITEM_EXIST
	call ApFuncCall
	or xhl, xhl
	jr z, EffectBox_SetAutoIncAfterLoop
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld xbc, EVT_GET_ITEM_TOP
	ld xde, 0:i3
	call ApFuncCall
	inc 1, l
	ldfr_berp L, 0xfb
	ld xde, 0:i3
	ldto_berp E, 0xfb
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld xbc, EVT_SET_ITEM_TOP
	call ApFuncCall
	ld XWA, (xsp + 0x0156)
	ld xbc, EVT_EFF_FIX_DRAW
	ld xde, 0:i3
	call SendEvent
	ld iz, 0:i3

EffectBox_SendMultipleValues:
	ld de, iz
	extz xde
	ld XWA, (xsp + 0x0156)
	ld xbc, EVT_EFF_PARA_DRAW
	call SendEvent
	inc 1, iz
	cp iz, 0x8
	jr c, EffectBox_SendMultipleValues

EffectBox_SetAutoIncAfterLoop:
	ld XWA, (xsp + 0x0156)
	ld XBC, (xsp + 0x0152)
	ld XDE, (xsp + 0x014e)
	jrl EffectBox_SetAutoInc

EffectBox_HandleAppFunc:
	ld XBC, (xsp + 0x014e)
	cp xbc, 0x2
	jr nz, EffectBox_HandleCase0_Direct
	ld xbc, EVT_GET_ITEM_TOP
	ld xde, 0:i3
	call ApFuncCall
	ldfr_berp L, 0xfb
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld xbc, EVT_GET_ITEM_OFF
	ld xde, 0:i3
	call ApFuncCall
	ldto_berp A, 0xfb
	add a, l
	ldfr_berp A, 0xfb
	ld xde, 0:i3
	ldto_berp E, 0xfb
	add xde, 0xffffff00
	ld xwa, NAKA_MAINFUNC_EffEditMain
	ld xbc, EVT_CNG_EFF_PARA
	call MainPostEvent
	ld XWA, (xsp + 0x0156)
	ld XBC, (xsp + 0x0152)
	ld XDE, (xsp + 0x014e)
	jr EffectBox_SetAutoInc

EffectBox_HandleCase0_Direct:
	ld XWA, (xsp + 0x014e)
	or xwa, xwa
	jr nz, EffectBoxProc_ReturnZero
	ld xwa, NAKA_MAINFUNC_EffEditMain
	ld xbc, EVT_CNG_EFF_TYPE
	ld xde, 0xffffffff
	call MainPostEvent
	ld XWA, (xsp + 0x0156)
	ld xbc, EVT_SELE_DRAW
	ld xde, 0:i3
	call SendEvent
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld xbc, EVT_SET_ITEM_TOP
	ld xde, 0:i3
	call ApFuncCall
	ld xwa, (xsp + 4)
	ld xwa, (xwa + 28)
	ld xbc, EVT_SET_ITEM_OFF
	ld xde, 0:i3
	call ApFuncCall
	ld XWA, (xsp + 0x0156)
	ld xbc, EVT_SELE_DRAW
	ld xde, 1:i3
	call SendEvent
	ld XWA, (xsp + 0x0156)
	ld XBC, (xsp + 0x0152)
	ld XDE, (xsp + 0x014e)

EffectBox_SetAutoInc:
	call SetAutoInc

EffectBoxProc_ReturnZero:
	ld xhl, 0:i3
	jr EffectBox_Epilogue

EffectBox_HandleInherited:
	ld XWA, (xsp + 0x0156)
	ld XBC, (xsp + 0x0152)
	ld XDE, (xsp + 0x014e)
	call InheritedProc

EffectBox_Epilogue:
	pop xiz
	lda xsp, (xsp+342)
	ret

EqualizerBoxProc:
	lda xsp, (xsp - 92)
	push xiz
	ld (xsp + 88), xde
	ld xiz, xbc
	ld (xsp + 92), xwa
	cp xiz, EVT_EQ_LINE_DRAW
	jrl z, Equalizer_HandleScrollUpEvent
	cp xiz, EVT_INDEXSW_DOWN
	jrl z, Equalizer_HandleEvent1
	cp xiz, EVT_INDEXSW_UP
	jrl z, Equalizer_DrawStringDone
	cp xiz, EVT_EQ_STR_DRAW
	jrl z, Equalizer_HandleSelectEvent
	cp xiz, EVT_RET_EFF_PARA
	jr z, Equalizer_SendAndLoopDone
	cp xiz, EVT_RET_EFF_FIX
	jr z, Equalizer_SendPanelEvent
	cp xiz, EVT_PAINT
	jrl nz, Equalizer_HandleInherited
	ld xwa, (xsp + 92)
	ld xbc, xiz
	ld xde, (xsp + 88)
	call InheritedProc
	ld xde, (xsp + 92)
	ld xwa, NAKA_MAINFUNC_EffEditMain
	ld xbc, xiz
	call MainPostEvent
	jrl SeqAccomp_ReturnZeroJmp

Equalizer_SendPanelEvent:
	ld xwa, (xsp + 92)
	ld xbc, EVT_EQ_LINE_DRAW
	ld xde, 1:i3
	call SendEvent
	ld iz, 0:i3

Equalizer_SendChannelLoop:
	ld de, iz
	extz xde
	ld xwa, (xsp + 92)
	ld xbc, EVT_EQ_STR_DRAW
	call SendEvent
	inc 1, iz
	cp iz, 0x8
	jr c, Equalizer_SendChannelLoop
	jrl SeqAccomp_ReturnZeroJmp

Equalizer_SendAndLoopDone:
	ld xwa, (xsp + 92)
	ld xbc, EVT_EQ_LINE_DRAW
	ld xde, 1:i3
	call SendEvent
	ld xwa, (xsp + 92)
	ld xbc, EVT_EQ_STR_DRAW
	ld xde, (xsp + 88)
	call SendEvent
	jrl SeqAccomp_ReturnZeroJmp

Equalizer_HandleSelectEvent:
	ld xwa, (xsp + 88)
	cp xwa, 0x7
	jrl ugt, SeqAccomp_ReturnZeroJmp
	ld xwa, (xsp + 92)
	call GetViewInstance
	ld (xsp + 22), xhl
	ld xwa, (xsp + 22)
	ld xwa, (xwa + 28)
	ld xbc, EVT_GET_TTL_NOW
	ld xde, 0:i3
	call ApFuncCall
	ld xwa, (xsp + 22)
	cp l, (xwa + 32)
	jrl nz, SeqAccomp_ReturnZeroJmp
	lda xix, (xsp + 80)
	ld xhl, (xsp + 88)
	add xhl, xhl
	ld xwa, Equalizer_HandleSelectEvent_Table_2
	add xwa, xhl
	ld wa, (xwa)
	ld (xix), wa
	lda xde, (xix + 4)
	ld wa, (xix)
	add wa, 0x3c
	ld (xde), wa
	lda xbc, (xix + 2)
	ld xwa, Equalizer_HandleSelectEvent_Table
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
	ld (xwa+), 0x00
	cp xwa, xbc
	jr c, EffectBox_StateDispatch
	ld xwa, (xsp + 22)
	ld xwa, (xwa + 28)
	ld xbc, EVT_GET_RAM_ADDRESS
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
	add xbc, EffectBox_StateDispatch_CaseTable
	ld bc, (xbc)
	lda xix, (SeqAccomp_Dispatch:24)
	jp	t, (xix+bc)
; SeqAccomp editor load dispatch
SeqAccomp_Dispatch:
	ld	xbc, EVT_GET_EQ1_STR
	jr	EffectBoxProc_CopyNameAndSetup_Code_Join
	ld	xbc, EVT_GET_EQ2_STR
	jr EffectBoxProc_CopyNameAndSetup_Code_Join
	ld xbc, EVT_GET_EQ3_STR
	jr EffectBoxProc_CopyNameAndSetup_Code_Join
	ld xbc, EVT_GET_EQ4_STR
	jr	EffectBoxProc_CopyNameAndSetup_Code_Join
	ld	xbc, EVT_GET_EQ5_STR
	jr	EffectBoxProc_CopyNameAndSetup_Code_Join
	ld	xbc, EVT_GET_EQ6_STR
	jr	EffectBoxProc_CopyNameAndSetup_Code_Join
	ld	xbc, EVT_GET_EQ7_STR
	jr	EffectBoxProc_CopyNameAndSetup_Code_Join

; EffectBox state 1
EffectBox_State1:
	ld xwa, (xhl)
	ld xbc, EVT_GET_EQ0_STR
EffectBoxProc_CopyNameAndSetup_Code_Join:
	call ApFuncCall
	lda xwa, (xsp + 80)
	lda xbc, (xsp + 76)
	lda xde, (xsp + 26)
	ld xhl, 0:i3
	push xhl
	pushw 0xff
	ld xhl, (xsp + 28)
	pushm (xhl + 22)
	call DrawStringLeftJustify
	jrl SeqAccomp_ReturnZeroJmp

Equalizer_DrawStringDone:
	ld xwa, (xsp + 92)
	ld xbc, xiz
	ld xde, (xsp + 88)
	call InheritedProc
	ld xwa, (xsp + 88)
	cp xwa, 0x8
	jrl nc, SeqAccomp_ReturnZeroJmp
	ld xde, 0x100
	add xde, (xsp + 88)
	ld xwa, NAKA_MAINFUNC_EffEditMain
	ld xbc, EVT_CNG_EFF_PARA
	call MainPostEvent
	ld xwa, (xsp + 92)
	ld xbc, EVT_INDEXSW_UP
	ld xde, (xsp + 88)
	call SetDialUp
	ld xwa, (xsp + 92)
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, (xsp + 88)
	call SetDialDown
	ld wa, 1:i3
	call SetDialEnable
	ld xwa, (xsp + 92)
	ld xbc, xiz
	ld xde, (xsp + 88)
	jr Equalizer_CallSetAutoInc

Equalizer_HandleEvent1:
	ld xwa, (xsp + 92)
	ld xbc, xiz
	ld xde, (xsp + 88)
	call InheritedProc
	ld xwa, (xsp + 88)
	cp xwa, 0x8
	jrl nc, SeqAccomp_ReturnZeroJmp
	ld xde, 0xffffff00
	add xde, (xsp + 88)
	ld xwa, NAKA_MAINFUNC_EffEditMain
	ld xbc, EVT_CNG_EFF_PARA
	call MainPostEvent
	ld xwa, (xsp + 92)
	ld xbc, EVT_INDEXSW_UP
	ld xde, (xsp + 88)
	call SetDialUp
	ld xwa, (xsp + 92)
	ld xbc, EVT_INDEXSW_DOWN
	ld xde, (xsp + 88)
	call SetDialDown
	ld wa, 1:i3
	call SetDialEnable
	ld xwa, (xsp + 92)
	ld xbc, xiz
	ld xde, (xsp + 88)

Equalizer_CallSetAutoInc:
	call SetAutoInc
	jrl SeqAccomp_ReturnZeroJmp

Equalizer_HandleScrollUpEvent:
	ld xwa, (xsp + 92)
	call GetViewInstance
	ld (xsp + 22), xhl
	ld xwa, (xsp + 22)
	ld (xsp + 4), xwa
	ld xwa, (xwa + 28)
	ld xbc, EVT_GET_TTL_NOW
	ld xde, 0:i3
	call ApFuncCall
	ld xwa, (xsp + 22)
	cp l, (xwa + 32)
	jrl nz, SeqAccomp_ReturnZeroJmp
	lda xwa, (xsp + 80)
	ldw (xwa), 0x20
	ldw (xwa + 2), 0x24
	ldw (xwa + 4), 0xf8
	ldw (xwa + 6), 0x78
	ld bc, 0:i3
	ldw de, 0xf5
	call DrawDesignBox
	ld xwa, (xsp + 22)
	ld xwa, (xwa + 28)
	ld xbc, EVT_GET_DISP_POS
	ld xde, 1:i3
	call ApFuncCall
	extz hl
	ld (xsp + 8), hl
	ld xwa, (xsp + 22)
	ld xwa, (xwa + 28)
	ld xbc, EVT_GET_DISP_POS
	ld xde, 2:i3
	call ApFuncCall
	extz hl
	ld (xsp + 10), hl
	ld xwa, (xsp + 22)
	ld xwa, (xwa + 28)
	ld xbc, EVT_GET_DISP_POS
	ld xde, 3:i3
	call ApFuncCall
	extz hl
	ld (xsp + 12), hl
	ld xwa, (xsp + 22)
	ld xwa, (xwa + 28)
	ld xbc, EVT_GET_DISP_POS
	ld xde, 4:i3
	call ApFuncCall
	extz hl
	ld (xsp + 14), hl
	ld xwa, (xsp + 22)
	ld xwa, (xwa + 28)
	ld xbc, EVT_GET_DISP_POS
	ld xde, 5:i3
	call ApFuncCall
	extz hl
	ld (xsp + 16), hl
	ld xwa, (xsp + 22)
	ld xwa, (xwa + 28)
	ld xbc, EVT_GET_DISP_POS
	ld xde, 6:i3
	call ApFuncCall
	extz hl
	ld (xsp + 18), hl
	ld xwa, (xsp + 22)
	ld xwa, (xwa + 28)
	ld xbc, EVT_GET_DISP_POS
	ld xde, 7:i3
	call ApFuncCall
	extz hl
	ld (xsp + 20), hl
	ld xwa, (xsp + 22)
	ld xwa, (xwa + 28)
	ld xbc, EVT_GET_DISP_POS
	ld xde, 0x8
	call ApFuncCall
	extz hl
	ld (xsp + 22), hl
	ld xwa, (xsp + 88)
	cp xwa, 0x1
	jr nz, Equalizer_SetFixedWidth1
	ldw (xsp + 24), 0xfb
	jr Equalizer_StoreWidthAndDraw1

Equalizer_SetFixedWidth1:
	ld xwa, (xsp + 4)
	ld wa, (xwa + 22)
	ld (xsp + 24), wa

Equalizer_StoreWidthAndDraw1:
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
	jr ule, Equalizer_SetFixedWidth2
	ldw iz, 0xa
	jr Equalizer_StoreWidthAndDraw2

Equalizer_SetFixedWidth2:
	ld iz, wa
	srl iz, 1

Equalizer_StoreWidthAndDraw2:
	lda xwa, (xsp + 72)
	ld bc, (xsp + 8)
	ld (xwa), bc
	ld bc, (xsp + 10)
	ld (xwa + 2), bc
	lda xbc, (xsp + 68)
	ld de, (xsp + 8)
	add de, iz
	ld (xbc), de
	ldw (xbc + 2), 0x4d
	ld de, (xsp + 24)
	call DrawLine
	lda xwa, (xsp + 72)
	ld bc, (xsp + 8)
	add bc, iz
	ld (xwa), bc
	ldw (xwa + 2), 0x4d
	lda xbc, (xsp + 68)
	ld de, (xsp + 12)
	sub de, iz
	ld (xbc), de
	ldw (xbc + 2), 0x4d
	ld de, (xsp + 24)
	call DrawLine
	lda xwa, (xsp + 72)
	ld bc, (xsp + 12)
	sub bc, iz
	ld (xwa), bc
	ldw (xwa + 2), 0x4d
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
	jr ule, Equalizer_SetFixedWidth3
	ldw iz, 0xa
	jr Equalizer_StoreWidthAndDraw3

Equalizer_SetFixedWidth3:
	ld iz, wa
	srl iz, 1

Equalizer_StoreWidthAndDraw3:
	lda xwa, (xsp + 72)
	ld bc, (xsp + 12)
	ld (xwa), bc
	ld bc, (xsp + 14)
	ld (xwa + 2), bc
	lda xbc, (xsp + 68)
	ld de, (xsp + 12)
	add de, iz
	ld (xbc), de
	ldw (xbc + 2), 0x4d
	ld de, (xsp + 24)
	call DrawLine
	lda xwa, (xsp + 72)
	ld bc, (xsp + 12)
	add bc, iz
	ld (xwa), bc
	ldw (xwa + 2), 0x4d
	lda xbc, (xsp + 68)
	ld de, (xsp + 16)
	sub de, iz
	ld (xbc), de
	ldw (xbc + 2), 0x4d
	ld de, (xsp + 24)
	call DrawLine
	lda xwa, (xsp + 72)
	ld bc, (xsp + 16)
	sub bc, iz
	ld (xwa), bc
	ldw (xwa + 2), 0x4d
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
	jr ule, Equalizer_SetFixedWidth4
	ldw iz, 0xa
	jr Equalizer_StoreWidthAndDraw4

Equalizer_SetFixedWidth4:
	ld iz, wa
	srl iz, 1

Equalizer_StoreWidthAndDraw4:
	lda xwa, (xsp + 72)
	ld bc, (xsp + 16)
	ld (xwa), bc
	ld bc, (xsp + 18)
	ld (xwa + 2), bc
	lda xbc, (xsp + 68)
	ld de, (xsp + 16)
	add de, iz
	ld (xbc), de
	ldw (xbc + 2), 0x4d
	ld de, (xsp + 24)
	call DrawLine
	lda xwa, (xsp + 72)
	ld bc, (xsp + 16)
	add bc, iz
	ld (xwa), bc
	ldw (xwa + 2), 0x4d
	lda xbc, (xsp + 68)
	ld de, (xsp + 20)
	sub de, iz
	ld (xbc), de
	ldw (xbc + 2), 0x4d
	ld de, (xsp + 24)
	call DrawLine
	lda xwa, (xsp + 72)
	ld bc, (xsp + 20)
	sub bc, iz
	ld (xwa), bc
	ldw (xwa + 2), 0x4d
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
	ldw (xbc), 0xf8
	ld (xbc + 2), de
	ld de, (xsp + 24)
	call DrawLine
	ld xwa, (xsp + 88)
	cp xwa, 0x1
	jr nz, Equalizer_SetFixedWidthFF
	ldw (xsp + 24), 0xff
	jr Equalizer_StoreWidthAndDrawFF

Equalizer_SetFixedWidthFF:
	ld xwa, (xsp + 4)
	ld wa, (xwa + 22)
	ld (xsp + 24), wa

Equalizer_StoreWidthAndDrawFF:
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
	ld xhl, 0:i3
	jr Equalizer_Epilogue

Equalizer_HandleInherited:
	ld xwa, (xsp + 92)
	ld xbc, xiz
	ld xde, (xsp + 88)
	call InheritedProc

Equalizer_Epilogue:
	pop xiz
	lda xsp, (xsp + 92)
	ret

EqOnOffFuncToggleProc:
	push xiz
	ld xiz, xwa
	cp xbc, EVT_LSW_DATA
	jr z, EqOnOff_CheckValue
	cp xbc, EVT_SHOW
	jr z, EqOnOff_HandleToggleOn
	ld xwa, xiz
	call InheritedProc
	jr SqplyFunc_FormatEntry

EqOnOff_HandleToggleOn:
	ld	xwa, xiz
	call	InheritedProc
	ld	xwa, 16390
	call	AcApcToggleProc_Helper
	cp	hl, 1:i3
	jr	nz, EqOnOff_HandleToggleOff
	ld	xwa, xiz
	ld	xbc, EVT_SET_PARAM
	ld	xde, 1:i3
	jr	SqEdit_SendEventEpilog
EqOnOff_HandleToggleOff:
	ld xwa, xiz
	ld xbc, EVT_SET_PARAM
	ld xde, 0:i3
	jr SqEdit_SendEventEpilog

EqOnOff_CheckValue:
	ld xwa, (xde)
	cp xwa, 0x4006
	jr nz, SqplyFunc_FormatDispatch
	cpw (xde + 4), 0x1
	jr nz, EqOnOff_ToggleResult
	ld xwa, xiz
	ld xbc, EVT_SET_PARAM
	ld xde, 1:i3
	jr SqEdit_SendEventEpilog

EqOnOff_ToggleResult:
	ld xwa, xiz
	ld xbc, EVT_SET_PARAM
	ld xde, 0:i3

SqEdit_SendEventEpilog:
	call SendEvent

; SqplyFunc format dispatch
SqplyFunc_FormatDispatch:
	ld xhl, 0:i3

; SqplyFunc format entry
SqplyFunc_FormatEntry:
	pop xiz
	ret

SqplyFunc:
	lda xsp, (xsp - 12)
	ld (xsp + 4), xde
	ld (xsp + 8), xwa
	ld xhl, xbc
	cp xbc, EVT_GET_TTL_NOW
	jrl z, SqplyFunc_GetScreenId
	ld xwa, (xsp + 4)
	cp xbc, EVT_CHK_CUR
	jrl z, SqplyFunc_HandlePartQuery
	cp xbc, EVT_CUR_TO_PARAM
	jrl z, SqplyFunc_HandleTrackLookup
	cp xbc, EVT_SET_CUR_POS
	jrl z, SqplyFunc_StoreTrackPart
	cp xbc, EVT_GET_CUR_POS
	jrl z, SqplyFunc_GetValueDispatch
	cp xbc, EVT_GET_RAM_ADDRESS
	jrl z, SqplyFunc_HandleGetValue
	cp xbc, EVT_GET_P_CNT_IN_STRING
	jrl z, SqplyFunc_FormatFillIn
	cp xbc, EVT_GET_P_OUT_MEAS_STRING
	jrl z, SqplyFunc_FormatEnding
	cp xbc, EVT_GET_P_IN_MEAS_STRING
	jrl z, SqplyFunc_FormatIntro
	ld de, (9832:16)
	cp xbc, EVT_GET_P_MEAS_STRING
	jrl z, SqplyFunc_FormatRhythmPattern
	sub xhl, EVT_KUBO_GET_MEAS_STRING
	cp xhl, 0x0
	jrl lt, SqplyFunc_ReturnZero
	cp xhl, 0x9
	jrl gt, SqplyFunc_ReturnZero
	add xhl, xhl
	add xhl, SqplyFunc_CaseTable
	ld hl, (xhl)
	lda xix, (SqplyFunc_FormatCases:24)
	jp	t, (xix+hl)
; Case bodies of the `jp t, (xrr+rr)` switch in the SqplyFunc handler above (events 0x1E8003E-0x1E80047; word offsets at SqplyFunc_CaseTable): jp (xix + r) with xix = this
; label, so this label is the offset-0 case.  Formerly named as data; it is
; code.
SqplyFunc_FormatCases:
	ld	xwa, (xsp+4)
	ld	(xsp), xwa
	ld	wa, de
	cp	de, 32770
	jr	nz, SqplyFunc_FormatCases_Skip
	ld	xwa, SqplyFunc_ParamFormatData_Str
	jr	SqplyFunc_FormatCases_Join
SqplyFunc_FormatCases_Skip:
	cp	wa, 32769
	jr	nz, SqplyFunc_FormatCases_Skip2
	ld	xwa, SqplyFunc_ParamFormatData_Str_2
SqplyFunc_FormatCases_Join:
	push	xwa
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+18)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	jrl	SqplyFunc_RestoreAndReturn
SqplyFunc_FormatCases_Skip2:
	pushw	wa
	ld	xwa, SqplyFunc_ParamFormatData_Str_3
	jrl	SqplyFunc_PushFormatAddr
	ld	xwa, (xsp+4)
	ld	(xsp), xwa
	ld	a, (9010:16)
	extz	wa
	pushw	wa
	ld	xwa, SqplyFunc_ParamFormatData_Str_4
	jrl	SqplyFunc_PushFormatAddr
	ld	xwa, (xsp+4)
	ld	(xsp), xwa
	ld	a, (7528:16)
	extz	wa
	pushw	wa
	ld	xwa, SqplyFunc_ParamFormatData_Str_5
	jrl	SqplyFunc_PushFormatAddr
	ld	xwa, (xsp+4)
	ld	(xsp), xwa
	call	GetTitleNow
	ld	xwa, (xsp)
	lda	xbc, (xwa+18)
	cp	l, 130
	jr	nz, SqplyFunc_FormatCases_Skip5
	bit 0, (0x28b1:16)
	jr	z, SqplyFunc_FormatCases_Skip4
	ld	xwa, SqplyFunc_ParamFormatData_Str_6
	jr	SqplyFunc_FormatCases_Join2
SqplyFunc_FormatCases_Skip4:
	ld	xwa, SqplyFunc_ParamFormatData_Str_7
SqplyFunc_FormatCases_Join2:
	push	xwa
	ld	xwa, (xbc)
	push	xwa
	jr	SqplyFunc_FormatCases_Join4
SqplyFunc_FormatCases_Skip5:
	ld	xbc, (xbc)
	bit 1, (0x28b1:16)
	jr	z, SqplyFunc_FormatCases_Skip6
	ld	xwa, SqplyFunc_ParamFormatData_Str_8
	jr	SqplyFunc_FormatCases_Join3
SqplyFunc_FormatCases_Skip6:
	ld	xwa, SqplyFunc_ParamFormatData_Str_9
SqplyFunc_FormatCases_Join3:
	push	xwa
	push	xbc
	jr	SqplyFunc_FormatCases_Join4
	ld	xwa, (xsp+4)
	ld	(xsp), xwa
	ld	xwa, SqplyFunc_ParamFormatData_Str_11
	cp	(10298:16), 0
	jr	z, SqplyFunc_FormatCases_Skip3
	ld	xwa, SqplyFunc_ParamFormatData_Str_10
SqplyFunc_FormatCases_Skip3:
	push	xwa
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+18)
	push	xwa
SqplyFunc_FormatCases_Join4:
	call	Free_Compare2
	inc	8, xsp
	jrl	SqplyFunc_RestoreAndReturn
	ld	xwa, (xsp+4)
	ld	(xsp), xwa
	call	GetTitleNow
	cp	l, 134
	jr	nz, SqplyFunc_FormatCases_Skip7
	pushm (0x2520:16)
	ld	xwa, SqplyFunc_ParamFormatData_Str_12
	jr	SqplyFunc_FormatCases_Join5
SqplyFunc_FormatCases_Skip7:
	pushm (0x251c:16)
	ld	xwa, SqplyFunc_ParamFormatData_Str_13
SqplyFunc_FormatCases_Join5:
	jrl	SqplyFunc_PushFormatAddr
	ld	xwa, (xsp+4)
	ld	(xsp), xwa
	call	GetTitleNow
	cp	l, 134
	jr	nz, SqplyFunc_FormatCases_Skip8
	pushm (0x2522:16)
	ld	xwa, SqplyFunc_ParamFormatData_Str_14
	jr	SqplyFunc_FormatCases_Join6
SqplyFunc_FormatCases_Skip8:
	pushm (0x251e:16)
	ld	xwa, SqplyFunc_ParamFormatData_Str_15
SqplyFunc_FormatCases_Join6:
	jr	SqplyFunc_PushFormatAddr
SqplyFunc_FormatRhythmPattern:
	ld xwa, (xsp + 4)
	ld (xsp), xwa
	ld hl, de
	ld xwa, (xsp)
	lda xbc, (xwa + 18)
	cp de, 0x8002
	jr nz, SqplyFunc_CheckPattern8001
	ld xwa, SqplyFunc_FormatRhythmPattern_Str
	jr SqplyFunc_CopyPatternString

SqplyFunc_CheckPattern8001:
	cp hl, 0x8001
	jr nz, SqplyFunc_FormatPatternNumeric
	ld xwa, SqplyFunc_FormatRhythmPattern_Str_2

SqplyFunc_CopyPatternString:
	push	xwa
	ld	xwa, (xbc)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	jr	SqplyFunc_RestoreAndReturn
SqplyFunc_FormatPatternNumeric:
	pushw hl
	pushw SqplyFunc_FormatPatternNumeric_Str_Fmt3d@hi16
	pushw SqplyFunc_FormatPatternNumeric_Str_Fmt3d@lo16
	jr SqplyFunc_PushAndFormat

SqplyFunc_FormatIntro:
	ld xwa, (xsp + 4)
	ld (xsp), xwa
	push_sd16w 0x38, 0xf2
	ld xwa, SqplyFunc_FormatIntro_Str
	jr SqplyFunc_PushFormatAddr

SqplyFunc_FormatEnding:
	ld xwa, (xsp + 4)
	ld (xsp), xwa
	push_sd16w 0x3a, 0xf2
	ld xwa, SqplyFunc_FormatEnding_Str
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
	push_sd16w 0x3f, 0xf2
	ld xwa, SqplyFunc_FormatFillIn_Str

SqplyFunc_PushFormatAddr:
	push xwa
	ld xwa, (xsp + 6)
	ld xwa, (xwa + 18)
	push xwa

SqplyFunc_CallAudioSendCmd:
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
SqplyFunc_RestoreAndReturn:
	ld xhl, (xsp + 8)
	jrl SqplyFunc_Epilogue

SqplyFunc_HandleGetValue:
	ld xwa, (xsp + 4)
	dec 1, xwa
	cp xwa, 0x0
	jr c, SqplyFunc_GetValueDefault
	cp xwa, 0xa
	jr ugt, SqplyFunc_GetValueDefault
	add xwa, xwa
	add xwa, SqplyFunc_HandleGetValue_CaseTable
	ld wa, (xwa)
	lda xix, (SqplyFunc_GetValueDispatch:24)
	jp	t, (xix+wa)

SqplyFunc_GetValueDispatch:
	ld xhl, 0:i3
	ld l, (0x02109c:24)
	jrl SqplyFunc_Epilogue
	lda xhl, (9832:16)
	jr SqplyFunc_GetValueReturn
	lda xhl, (0x28b1:16)
	jr SqplyFunc_GetValueDone
	call GetTitleNow
	cp l, 0x82
	jr nz, SqplyFunc_GetValNonPlay
	lda xhl, (9500:16)
	jr SqplyFunc_GetValueReturn

SqplyFunc_GetValNonPlay:
	lda xhl, (9504:16)
	jr SqplyFunc_GetValueReturn
	call GetTitleNow
	cp l, 0x82
	jr nz, SqplyFunc_GetValNonPlay2
	lda xhl, (9502:16)
	jr SqplyFunc_GetValueReturn

SqplyFunc_GetValNonPlay2:
	lda xhl, (9506:16)
	jr SqplyFunc_GetValueReturn
	lda xhl, (9964:16)
	jr SqplyFunc_GetValueReturn
	lda xhl, (0xf238:16)
	jr SqplyFunc_GetValueReturn
	lda xhl, (0xf23a:16)
	jr SqplyFunc_GetValueReturn
	lda xhl, (0xf23f:16)
	jr SqplyFunc_GetValueReturn
	lda xhl, (0x283a:16)

SqplyFunc_GetValueDone:
	jrl SqplyFunc_Epilogue

SqplyFunc_GetValueDefault:
	lda xhl, (9832:16)

SqplyFunc_GetValueReturn:
	jrl SqplyFunc_Epilogue

SqplyFunc_StoreTrackPart:
	ld (0x02109c:24), a

SqplyFunc_ReturnZero:
	ld xhl, 0:i3
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
	cp a, 3:i3
	jr z, SqplyFunc_TrackPart3
	cp c, 2:i3
	jr z, SqplyFunc_TrackPart2
	cp c, 1:i3
	jr nz, SqplyFunc_TrackTypeUnknown
	ld l, 0x4:opc
	jr SqplyFunc_TrackTypeReturn

SqplyFunc_TrackPart2:
	ld l, 0x5:opc
	jr SqplyFunc_TrackTypeReturn

SqplyFunc_TrackPart3:
	ld l, 0x6:opc
	jr SqplyFunc_TrackTypeReturn

SqplyFunc_TrackMode88:
	cp l, 0x88
	jr nz, SqplyFunc_TrackMode96_99
	ld c, a
	cp a, 3:i3
	jr z, SqplyFunc_TrackMode88_Part3
	cp c, 2:i3
	jr z, SqplyFunc_TrackMode88_Part2
	cp c, 1:i3
	jr nz, SqplyFunc_TrackTypeUnknown
	ld l, 0x8:opc
	jr SqplyFunc_TrackTypeReturn

SqplyFunc_TrackMode88_Part2:
	ld l, 0x9:opc
	jr SqplyFunc_TrackTypeReturn

SqplyFunc_TrackMode88_Part3:
	ld l, 0xa:opc
	jr SqplyFunc_TrackTypeReturn

SqplyFunc_TrackMode96_99:
	cp l, 0x96
	jr z, SqplyFunc_TrackModePerc
	cp l, 0x99
	jr nz, SqplyFunc_TrackTypeUnknown

SqplyFunc_TrackModePerc:
	ld c, a
	cp a, 3:i3
	jr z, SqplyFunc_TrackPart3
	cp c, 2:i3
	jr z, SqplyFunc_TrackPart2
	cp c, 1:i3
	jr nz, SqplyFunc_TrackTypeUnknown
	ld l, 0xb:opc
	jr SqplyFunc_TrackTypeReturn

SqplyFunc_TrackTypeUnknown:
	ld l, 0xff:opc

SqplyFunc_TrackTypeReturn:
	exts hl
	exts xhl
	jr SqplyFunc_Epilogue

SqplyFunc_HandlePartQuery:
	extz wa
	dec 4, wa
	cp wa, 0:i3
	jr lt, SqplyFunc_ReturnZero
	cp wa, 7:i3
	jr gt, SqplyFunc_ReturnZero
	add wa, wa
	lda xix, (SqplyFunc_HandlePartQuery_CaseTable:24)
	ld	wa, (xix+wa)
	lda xix, (SqplyFunc_PartQueryDispatch:24)
	jp	t, (xix+wa)

SqplyFunc_PartQueryDispatch:
	ld	l, 1:opc
SqplyFunc_PartQueryDispatch_Join:
	ld	a, (0x02109c:24)
	cp	a, l
	scc16	z, hl
	extz	xhl
	jr	SqplyFunc_Epilogue
	ld	l, 2:opc
	jr	SqplyFunc_PartQueryDispatch_Join
	ld	l, 3:opc
	jr	SqplyFunc_PartQueryDispatch_Join

SqplyFunc_GetScreenId:
	call GetTitleNow
	ld h, 0x0:opc
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
	cp xiz, EVT_GET_TTL_NOW
	jrl z, SqedtFunc_StateChainA
	cp xiz, EVT_GET_RAM_ADDRESS
	jrl z, SqedtFunc_ModeD
	cp xiz, EVT_GET_T_SNG_NAME_STRING
	jrl z, SqedtFunc_ModeB
	cp xiz, EVT_GET_F_SNG_NAME_STRING
	jrl z, SqedtFunc_ModeA
	cp xiz, EVT_GET_SCLR_PER_STRING
	jrl z, SqedtFunc_CheckMode
	cp xiz, EVT_GET_SCLR_KB_STRING
	jrl z, SqedtFunc_Case2
	cp xiz, EVT_GET_SCLR_NAME_STRING
	jrl z, SqedtFunc_Case1
	cp xiz, EVT_GET_SCLR_NO_STRING
	jrl z, SqedtFunc_Case0
	ld xwa, (xsp + 8)
	sub xde, EVT_GET_TRK_STRING
	cp xde, 0x0
	jrl lt, SeqFunc_ReturnZeroJmp
	cp xde, 0x27
	jrl gt, SeqFunc_ReturnZeroJmp
	add xde, xde
	add xde, SqedtFunc_CaseTable
	ld de, (xde)
	lda xix, (Sqedt_ParamDispatch:24)
	jp	t, (xix+de)
; SqedtFunc parameter dispatch
Sqedt_ParamDispatch:
	; framing ported from v10's source for the same label (same span length, statement for statement); 406 of 484 slots byte-identical
	ld	xwa, (xsp+8)
	ld	(xsp+4), xwa
	pushw	5
	extz	hl
	sub	hl, 156
	cp	hl, 0:i3
	jr	lt, Sqedt_ParamDispatch_Skip
	cp	hl, 7:i3
	jr	gt, Sqedt_ParamDispatch_Skip
	add	hl, hl
	lda	xix, (Sqedt_ParamDispatch_CaseTable_3:24)
	ld	hl, (xix+hl)
	lda	xix, (Sqedt_ParamDispatch_Code:24)
	jp	t, (xix+hl)
Sqedt_ParamDispatch_Code:
	ld	a, (9742:16)
	jr	Sqedt_ParamDispatch_Join
	ld	a, (9756:16)
	jr	Sqedt_ParamDispatch_Join
	ld	a, (61910:16)
	jr	Sqedt_ParamDispatch_Join
	ld	a, (61915:16)
	jr	Sqedt_ParamDispatch_Join
	ld	a, (61937:16)
	jr	Sqedt_ParamDispatch_Join
	ld	a, (61992:16)
	jr	Sqedt_ParamDispatch_Join
Sqedt_ParamDispatch_Skip:
	ld	a, (9732:16)
Sqedt_ParamDispatch_Join:
	jrl	Sqedt_ParamDispatch_Join8
	ld	xwa, (xsp+8)
	ld	(xsp+4), xwa
	extz	hl
	sub	hl, 156
	cp	hl, 0:i3
	jr	lt, Sqedt_ParamDispatch_Entry
	cp	hl, 7:i3
	jr	gt, Sqedt_ParamDispatch_Entry
	add	hl, hl
	lda	xix, (Sqedt_ParamDispatch_CaseTable_2:24)
	ld	hl, (xix+hl)
	lda	xix, (Sqedt_ParamDispatch_Code_2:24)
	jp	t, (xix+hl)
Sqedt_ParamDispatch_Code_2:
	pushm (0x2610:16)
	ld	xwa, Sqedt_ParamDispatch_Str
	jr	Sqedt_ParamDispatch_Join2
	pushm (0x261e:16)
	ld	xwa, Sqedt_ParamDispatch_Str_2
	jr	Sqedt_ParamDispatch_Join2
	pushm (0xf1d7:16)
	ld	xwa, Sqedt_ParamDispatch_Str_3
	jr	Sqedt_ParamDispatch_Join2
	pushm (0xf1dc:16)
	ld xwa, FmtStr_pct3d_4B5E
	jr	Sqedt_ParamDispatch_Join2
	pushm (0xf1f2:16)
	ld xwa, Sqedt_ParamDispatch_Str_Fmt3d
	jr	Sqedt_ParamDispatch_Join2
	pushm (0xf229:16)
	ld	xwa, Sqedt_ParamDispatch_Str_4
	jr	Sqedt_ParamDispatch_Join2
Sqedt_ParamDispatch_Entry:
	pushm (0x2606:16)
	ld	xwa, Sqedt_ParamDispatch_Str_5
Sqedt_ParamDispatch_Join2:
	jrl	EffectBoxProc_CopyNameAndSetup_Code_Join18
	ld	xwa, (xsp+8)
	ld	(xsp+4), xwa
	extz	hl
	sub	hl, 156
	cp	hl, 0:i3
	jr	lt, Sqedt_ParamDispatch_Entry2
	cp	hl, 7:i3
	jr	gt, Sqedt_ParamDispatch_Entry2
	add	hl, hl
	lda	xix, (Sqedt_ParamDispatch_CaseTable:24)
	ld	hl, (xix+hl)
	lda	xix, (Sqedt_ParamDispatch_Code_3:24)
	jp	t, (xix+hl)
Sqedt_ParamDispatch_Code_3:
	pushm (0x2612:16)
	ld	xwa, Sqedt_ParamDispatch_Str_6
	jr	Sqedt_ParamDispatch_Entry2_Join
	pushm (0x2620:16)
	ld	xwa, Sqedt_ParamDispatch_Str_7
	jr	Sqedt_ParamDispatch_Entry2_Join
	pushm (0x262c:16)
	ld	xwa, Sqedt_ParamDispatch_Str_8
	jr	Sqedt_ParamDispatch_Entry2_Join
	pushm (0x2626:16)
	ld xwa, NakaInst_3d
	jr	Sqedt_ParamDispatch_Entry2_Join
	pushm (0x25fc:16)
	ld	xwa, Sqedt_ParamDispatch_Str_9
	jr	Sqedt_ParamDispatch_Entry2_Join
	pushm (0x25fa:16)
	ld	xwa, Sqedt_ParamDispatch_Str_10
	jr	Sqedt_ParamDispatch_Entry2_Join
Sqedt_ParamDispatch_Entry2:
	pushm (0x2608:16)
	ld	xwa, Sqedt_ParamDispatch_Str_11
Sqedt_ParamDispatch_Entry2_Join:
	jrl	EffectBoxProc_CopyNameAndSetup_Code_Join18
	ld	xwa, (xsp+8)
	ld	(xsp+4), xwa
	ld	e, (9740:16)
	cp	e, 0:i3
	jr	le, Sqedt_ParamDispatch_Entry2_Skip
	exts	de
	pushw de
	pushw Sqedt_ParamDispatch_Entry2_Str_Fmt2d@hi16
	pushw	Sqedt_ParamDispatch_Entry2_Str_Fmt2d@lo16
	ld	xwa, (xsp+10)
	lda	xbc, (xwa+18)
	jr	Sqedt_ParamDispatch_Join3
Sqedt_ParamDispatch_Entry2_Skip:
	ld	xwa, (xsp+4)
	lda	xbc, (xwa+18)
	cp	e, 0:i3
	jr	ge, Sqedt_ParamDispatch_Skip2
	neg	e
	exts	de
	pushw	de
	pushw	Sqedt_ParamDispatch_Entry2_Str_Fmt2d_2@hi16
	pushw	Sqedt_ParamDispatch_Entry2_Str_Fmt2d_2@lo16
Sqedt_ParamDispatch_Join3:
	ld	xwa, (xbc)
	push	xwa
	jrl	SqedtFunc_CheckMode_SendAudio
Sqedt_ParamDispatch_Skip2:
	exts	de
	pushw	de
	pushw	Sqedt_ParamDispatch_Entry2_Str_Fmt3d@hi16
	pushw	Sqedt_ParamDispatch_Entry2_Str_Fmt3d@lo16
	jrl	EffectBoxProc_CopyNameAndSetup_Code_Join17
	ld	xwa, (xsp+8)
	ld	(xsp+4), xwa
	ld	e, (9762:16)
	cp	e, 0:i3
	jr	le, Sqedt_ParamDispatch_Skip3
	exts	de
	pushw	de
	ld xwa, FmtStr_pluspct3d
	jr	Sqedt_ParamDispatch_Join4
Sqedt_ParamDispatch_Skip3:
	cp	e, 0:i3
	jr	ge, Sqedt_ParamDispatch_Skip4
	neg	e
	exts	de
	pushw	de
	ld xwa, FmtStr_minuspct3d
	jr	Sqedt_ParamDispatch_Join4
Sqedt_ParamDispatch_Skip4:
	exts	de
	pushw	de
	ld	xwa, Sqedt_ParamDispatch_Str_12
Sqedt_ParamDispatch_Join4:
	jrl	EffectBoxProc_CopyNameAndSetup_Code_Join18
	ld	xwa, (xsp+8)
	ld	(xsp+4), xwa
	ld	e, (61998:16)
	cp	e, 0:i3
	jr	le, Sqedt_ParamDispatch_Skip5
	exts	de
	pushw	de
	ld	xwa, Sqedt_ParamDispatch_Str_13
	jr	Sqedt_ParamDispatch_Join5
Sqedt_ParamDispatch_Skip5:
	cp	e, 0:i3
	jr	ge, Sqedt_ParamDispatch_Skip6
	neg	e
	exts	de
	pushw	de
	ld	xwa, Sqedt_ParamDispatch_Str_14
	jr	Sqedt_ParamDispatch_Join5
Sqedt_ParamDispatch_Skip6:
	exts	de
	pushw	de
	ld	xwa, Sqedt_ParamDispatch_Str_15
Sqedt_ParamDispatch_Join5:
	push	xwa
	ld	xwa, (xsp+10)
	lda	xbc, (xwa+18)
	jrl	EffectBoxProc_CopyNameAndSetup_Code_Join17
	ld	xwa, (xsp+8)
	ld	(xsp+4), xwa
	pushw	9
	ld	a, (61920:16)
	extz	wa
	muls	wa, 9
	ld	xbc, Sqedt_ParamDispatch_Table_3
	exts	xwa
	add	xwa, xbc
	push	xwa
	jrl	SqedtFunc_ModeC_Entry
	ld	xwa, (xsp+8)
	ld	(xsp+4), xwa
	pushw	15
	ld	a, (61942:16)
	extz	wa
	muls	wa, 15
	ld	xbc, Sqedt_ParamDispatch_Table_4
	exts	xwa
	add	xwa, xbc
	push	xwa
	jrl	SqedtFunc_ModeC_Entry
	ld	xwa, (xsp+8)
	ld	(xsp+4), xwa
	ld	a, (9728:16)
	extz	wa
	pushw	wa
	ld	xwa, Sqedt_ParamDispatch_Str_16
	jrl	EffectBoxProc_CopyNameAndSetup_Code_Join18
	ld	xwa, (xsp+8)
	ld	(xsp+4), xwa
	ld	e, (9730:16)
	ld	a, e
	exts	wa
	cp	e, 0:i3
	jr	le, Sqedt_ParamDispatch_Skip7
	pushw	wa
	ld	xwa, Sqedt_ParamDispatch_Str_17
	jr	Sqedt_ParamDispatch_Join6
Sqedt_ParamDispatch_Skip7:
	cp	e, 0:i3
	jr	ge, Sqedt_ParamDispatch_Skip8
	neg	e
	exts	de
	pushw	de
	ld	xwa, Sqedt_ParamDispatch_Str_18
	jr	Sqedt_ParamDispatch_Join6
Sqedt_ParamDispatch_Skip8:
	pushw	wa
	ld	xwa, Sqedt_ParamDispatch_Str_19
Sqedt_ParamDispatch_Join6:
	push	xwa
	ld	xwa, (xsp+10)
	lda	xbc, (xwa+18)
	jrl	EffectBoxProc_CopyNameAndSetup_Code_Join17
	ld	xwa, (xsp+8)
	ld	(xsp+4), xwa
	lda	xbc, (xwa+18)
	ld	xwa, (xbc)
	ld	(xwa), 32
	pushw	9
	ld	a, (9750:16)
	extz	wa
	muls	wa, 9
	lda	xde, (NoteEdit_FormatTempoString_Data:24)
	exts	xwa
	add	xwa, xde
	push	xwa
	ld	xwa, (xbc)
	inc	1, xwa
	push	xwa
	call	CmpNamingCheck_Helper
	lda	xsp, (xsp+10)
	ld	a, (9750:16)
	extz	wa
	pushw	wa
	ld	xwa, Sqedt_ParamDispatch_Str_20
	jr	Sqedt_ParamDispatch_Join7
	ld	xwa, (xsp+8)
	ld	(xsp+4), xwa
	lda	xbc, (xwa+18)
	ld	xwa, (xbc)
	ld	(xwa), 32
	pushw	9
	ld	a, (9816:16)
	extz	wa
	muls	wa, 9
	lda	xde, (NoteEdit_FormatTempoString_Data:24)
	exts	xwa
	add	xwa, xde
	push	xwa
	ld	xwa, (xbc)
	inc	1, xwa
	push	xwa
	call	CmpNamingCheck_Helper
	lda	xsp, (xsp+10)
	ld	a, (9816:16)
	extz	wa
	pushw	wa
	ld	xwa, Sqedt_ParamDispatch_Str_21
Sqedt_ParamDispatch_Join7:
	push	xwa
	ld	xwa, (xsp+10)
	ld	xwa, (xwa+18)
	lda	xwa, (xwa+10)
	push	xwa
	jrl	SqedtFunc_CheckMode_SendAudio
	ld	xwa, (xsp+8)
	ld	(xsp+4), xwa
	ld	a, (61907:16)
	extz	wa
	pushw	wa
	ld	xwa, Sqedt_ParamDispatch_Str_22
	jrl	EffectBoxProc_CopyNameAndSetup_Code_Join18
	ld	xwa, (xsp+8)
	ld	(xsp+4), xwa
	ld	a, (61908:16)
	extz	wa
	pushw	wa
	ld	xwa, Sqedt_ParamDispatch_Str_23
	push	xwa
	ld	xwa, (xsp+10)
	lda	xbc, (xwa+18)
	jrl	EffectBoxProc_CopyNameAndSetup_Code_Join17
	ld	xwa, (xsp+8)
	ld	(xsp+4), xwa
	ld	a, (61909:16)
	extz	wa
	pushw	wa
	ld	xwa, Sqedt_ParamDispatch_Str_24
	jrl	EffectBoxProc_CopyNameAndSetup_Code_Join18
	ld	xwa, (xsp+8)
	ld	(xsp+4), xwa
	pushw	5
	ld	a, (61929:16)
	jrl	Sqedt_ParamDispatch_Join8
	ld	xwa, (xsp+8)
	ld	(xsp+4), xwa
	pushm (0xf1ea:16)
	ld	xwa, Sqedt_ParamDispatch_Str_25
	push	xwa
	ld	xwa, (xsp+10)
	lda	xbc, (xwa+18)
	jrl	EffectBoxProc_CopyNameAndSetup_Code_Join17
	ld	xwa, (xsp+8)
	ld	(xsp+4), xwa
	pushm (0x2628:16)
	ld	xwa, Sqedt_ParamDispatch_Str_26
	jrl	EffectBoxProc_CopyNameAndSetup_Code_Join18
	ld	xwa, (xsp+8)
	ld	(xsp+4), xwa
	pushw	5
	ld	a, (61934:16)
	jr	Sqedt_ParamDispatch_Join8
	ld	xwa, (xsp+8)
	ld	(xsp+4), xwa
	pushm (0xf1ef:16)
	ld	xwa, Sqedt_ParamDispatch_Str_27
	push	xwa
	ld	xwa, (xsp+10)
	lda	xbc, (xwa+18)
	jrl	EffectBoxProc_CopyNameAndSetup_Code_Join17
	ld	xwa, (xsp+8)
	ld	(xsp+4), xwa
	ld	a, (9770:16)
	extz	wa
	pushw	wa
	ld	xwa, Sqedt_ParamDispatch_Str_28
	jrl	EffectBoxProc_CopyNameAndSetup_Code_Join18
	ld	xwa, (xsp+8)
	ld	(xsp+4), xwa
	pushw	5
	ld	a, (61921:16)
	jr	Sqedt_ParamDispatch_Join8
	ld	xwa, (xsp+8)
	ld	(xsp+4), xwa
	pushm (0xf1e2:16)
	ld	xwa, Sqedt_ParamDispatch_Str_29
	push	xwa
	ld	xwa, (xsp+10)
	lda	xbc, (xwa+18)
	jrl	EffectBoxProc_CopyNameAndSetup_Code_Join17
	ld	xwa, (xsp+8)
	ld	(xsp+4), xwa
	pushm (0x262e:16)
	ld	xwa, Sqedt_ParamDispatch_Str_30
	jrl	EffectBoxProc_CopyNameAndSetup_Code_Join18
	ld	xwa, (xsp+8)
	ld	(xsp+4), xwa
	pushw	5
	ld	a, (61926:16)
Sqedt_ParamDispatch_Join8:
	extz	wa
	muls	wa, 5
	ld xbc, LongStr_1_2_3
	exts	xwa
	add	xwa, xbc
	push	xwa
	jrl	SqedtFunc_ModeC_Entry
	ld	xwa, (xsp+8)
	ld	(xsp+4), xwa
	pushm (0xf1e7:16)
	ld xwa, Sqedt_ParamDispatch_Entry2_Str_Fmt3d_2
	push	xwa
	ld	xwa, (xsp+10)
	lda	xbc, (xwa+18)
	jrl	EffectBoxProc_CopyNameAndSetup_Code_Join17
	ld	xwa, (xsp+8)
	ld	(xsp+4), xwa
	ld	a, (9776:16)
	extz	wa
	pushw	wa
	ld	xwa, Sqedt_ParamDispatch_Str_31
	jrl	EffectBoxProc_CopyNameAndSetup_Code_Join18
	ld	xwa, (xsp+8)
	ld	(xsp+4), xwa
	ld	a, (9992:16)
	extz	wa
	pushw	wa
	ld xwa, NakaInst_2d
	push	xwa
	ld	xwa, (xsp+10)
	lda	xbc, (xwa+18)
	jrl	EffectBoxProc_CopyNameAndSetup_Code_Join17
	ld	xwa, (xsp+8)
	ld	(xsp+4), xwa
	pushw	3
	ld a, (0x270c:16)
	jr Sqedt_ParamDispatch_Entry2_Join2
	ld	xwa, (xsp+8)
	ld	(xsp+4), xwa
	ld	a, (9994:16)
	extz	wa
	pushw	wa
	ld	xwa, Sqedt_ParamDispatch_Str_32
	jrl	EffectBoxProc_CopyNameAndSetup_Code_Join18
	ld	xwa, (xsp+8)
	ld	(xsp+4), xwa
	pushw	3
	ld	a, (9998:16)
Sqedt_ParamDispatch_Entry2_Join2:
	extz	wa
	muls	wa, 3
	ld	xbc, Sqedt_ParamDispatch_Table
	exts	xwa
	add	xwa, xbc
	push	xwa
	jrl	SqedtFunc_ModeC_Entry
SqedtFunc_Case0:
	ld xwa, (xsp + 8)
	ld (xsp + 4), xwa
	pushw 0x6
	ld a, (0x2878:16)
	extz wa
	muls wa, 0x6
	ld xbc, Sqedt_ParamDispatch_Table_2
	exts xwa
	add xwa, xbc
	push xwa
	jrl SqedtFunc_ModeC_Entry

; SqedtFunc dispatch case 1
SqedtFunc_Case1:
	ld xwa, (xsp + 8)
	ld (xsp + 4), xwa
	pushw 0x10
	lda xwa, (9706:16)
	jrl SqedtFunc_ModeC

; SqedtFunc dispatch case 2
SqedtFunc_Case2:
	ld XWA,(XSP+0x08)
	ld (XSP+0x04),XWA
	cp (0x2878:16), 0x0a
	jr nz, SqedtFunc_Case2_CopyParam
	pushw Sqedt_ParamDispatch_Entry2_Str_Blank5@hi16
	pushw Sqedt_ParamDispatch_Entry2_Str_Blank5@lo16
	ld XWA,(XSP+0x08)
	ld XWA,(XWA+0x12)
	push XWA
	call Free_Compare2
	inc 8,XSP
	jr t, StringCopyEpilog
SqedtFunc_Case2_CopyParam:
	push_sd16w 0x28, 0x27
	ld xwa, Sqedt_ParamDispatch_Str_33
	push xwa
	ld xwa, (xsp + 10)
	lda xbc, (xwa + 18)
EffectBoxProc_CopyNameAndSetup_Code_Join17:
	ld xwa, (xbc)
	push xwa
	jr SqedtFunc_CheckMode_SendAudio

; SqedtFunc check mode
SqedtFunc_CheckMode:
	ld XWA,(XSP+0x08)
	ld (XSP+0x04),XWA
	cp (0x2878:16), 0x0a
	jr nz, SqedtFunc_CheckMode_CopyParam
	pushw SqedtFunc_CheckMode_Str_N100@hi16
	pushw SqedtFunc_CheckMode_Str_N100@lo16
	ld XWA,(XSP+0x08)
	ld XWA,(XWA+0x12)
	push XWA
	call Free_Compare2
	inc 8,XSP
	jr t, StringCopyEpilog
SqedtFunc_CheckMode_CopyParam:
	ld a, (0x286c:16)
	extz wa
	pushw wa
	ld xwa, Sqedt_ParamDispatch_Str_34
EffectBoxProc_CopyNameAndSetup_Code_Join18:
	push xwa
	ld xwa, (xsp + 10)
	ld xwa, (xwa + 18)
	push xwa

SqedtFunc_CheckMode_SendAudio:
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
	jr	StringCopyEpilog
SqedtFunc_ModeA:
	ld xwa, (xsp + 8)
	ld (xsp + 4), xwa
	pushw 0x10
	lda xwa, (0x2842:16)
	jr SqedtFunc_ModeC

; SqedtFunc mode B
SqedtFunc_ModeB:
	ld xwa, (xsp + 8)
	ld (xsp + 4), xwa
	pushw 0x10
	lda xwa, (0x2852:16)

; SqedtFunc mode C
SqedtFunc_ModeC:
	push xwa

; SqedtFunc mode C entry
SqedtFunc_ModeC_Entry:
	ld	xwa, (xsp+10)
	ld	xwa, (xwa+18)
	push	xwa
	call	CmpNamingCheck_Helper
	lda	xsp, (xsp+10)
StringCopyEpilog:
	ld xhl, (xsp + 12)
	jrl SqedtFunc_Epilogue12

; SqedtFunc mode D
SqedtFunc_ModeD:
	ld xwa, (xsp + 8)
	calr SqedtFunc_StateChainB
	jrl SqedtFunc_Epilogue12
	ld xhl, 0:i3
	ld l, (0x02109c:24)
	jrl SqedtFunc_Epilogue12
	ld (0x02109c:24), a

SeqFunc_ReturnZeroJmp:
	ld xhl, 0:i3
	jrl SqedtFunc_Epilogue12
	extz wa
	cp wa, 0:i3
	jrl mi, SqedtFunc_ReturnNegOne
	cp wa, 6:i3
	jrl gt, SqedtFunc_ReturnNegOne
	add wa, wa
	lda xix, (SeqFunc_ReturnZeroJmp_CaseTable:24)
	ld	wa, (xix+wa)
	lda xix, (Sqedt_ValueDispatch:24)
	jp	t, (xix+wa)

; SqedtFunc value dispatch
Sqedt_ValueDispatch:
	extz	hl
	sub	hl, 155
	cp	hl, 0:i3
	jrl	lt, SqedtFunc_ReturnNegOne
	cp	hl, 8
	jrl	gt, SqedtFunc_ReturnNegOne
	add	hl, hl
	lda	xix, (Sqedt_ValueDispatch_CaseTable_3:24)
	ld	hl, (xix+hl)
	lda	xix, (Sqedt_ValueDispatch_Code:24)
	jp	t, (xix+hl)
Sqedt_ValueDispatch_Code:
	ld	l, 0:opc
	jrl	SqedtFunc_SignExtendAndReturn
	ld	l, 12:opc
	jrl	SqedtFunc_SignExtendAndReturn
	extz	hl
	sub	hl, 156
	cp	hl, 0:i3
	jrl	lt, SqedtFunc_ReturnNegOne
	cp	hl, 7:i3
	jrl	gt, SqedtFunc_ReturnNegOne
	add	hl, hl
	lda	xix, (Sqedt_ValueDispatch_CaseTable_2:24)
	ld	hl, (xix+hl)
	lda	xix, (Sqedt_ValueDispatch_Code2:24)
	jp	t, (xix+hl)
Sqedt_ValueDispatch_Code2:
	ld	l, 1:opc
	jr	SqedtFunc_SignExtendAndReturn
	extz	hl
	sub	hl, 155
	cp	hl, 0:i3
	jr	lt, SqedtFunc_ReturnNegOne
	cp	hl, 8
	jr	gt, SqedtFunc_ReturnNegOne
	add	hl, hl
	lda	xix, (Sqedt_ValueDispatch_CaseTable:24)
	ld	hl, (xix+hl)
	lda	xix, (Sqedt_ValueDispatch_Code3:24)
	jp	t, (xix+hl)
Sqedt_ValueDispatch_Code3:
	ld	l, 2:opc
	jr	SqedtFunc_SignExtendAndReturn
	ld	l, 13:opc
	jr	SqedtFunc_SignExtendAndReturn
	cp	l, 156
	jr	z, Sqedt_ValueDispatch_Skip4
	cp	l, 161
	jr	z, Sqedt_ValueDispatch_Skip3
	cp	l, 158
	jr	z, Sqedt_ValueDispatch_Skip2
	cp	l, 157
	jr	z, Sqedt_ValueDispatch_Skip
	cp	l, 160
	jr	nz, SqedtFunc_ReturnNegOne
	ld	l, 3:opc
	jr	SqedtFunc_SignExtendAndReturn
Sqedt_ValueDispatch_Skip:
	ld	l, 4:opc
	jr	SqedtFunc_SignExtendAndReturn
Sqedt_ValueDispatch_Skip2:
	ld	l, 5:opc
	jr	SqedtFunc_SignExtendAndReturn
Sqedt_ValueDispatch_Skip3:
	ld	l, 6:opc
	jr	SqedtFunc_SignExtendAndReturn
Sqedt_ValueDispatch_Skip4:
	ld	l, 7:opc
	jr	SqedtFunc_SignExtendAndReturn
	cp	l, 159
	jr	z, Sqedt_ValueDispatch_Skip5
	cp	l, 156
	jr	nz, SqedtFunc_ReturnNegOne
	ld	l, 8:opc
	jr	SqedtFunc_SignExtendAndReturn
Sqedt_ValueDispatch_Skip5:
	ld	l, 10:opc
	jr	SqedtFunc_SignExtendAndReturn

SqedtFunc_ReturnNegOne:
	ld l, 0xff:opc

SqedtFunc_SignExtendAndReturn:
	exts hl
	exts xhl
	jrl SqedtFunc_Epilogue12
	cp l, 0x9b
	jr z, SqedtFunc_SignExtend
	cp l, 0x9f
	jr z, SqedtFunc_ReturnNeg1
	cp l, 0x9c
	jr nz, SqedtFunc_ReturnNegOne
	ld l, 0x9:opc
	jr SqedtFunc_SignExtendAndReturn

; SqedtFunc return -1
SqedtFunc_ReturnNeg1:
	ld l, 0xb:opc
	jr SqedtFunc_SignExtendAndReturn

; SqedtFunc sign extend and return
SqedtFunc_SignExtend:
	ld l, 0xe:opc
	jr SqedtFunc_SignExtendAndReturn
	extz wa
	cp wa, 0:i3
	jrl mi, SeqFunc_ReturnZeroJmp
	cp wa, 0xe
	jrl gt, SeqFunc_ReturnZeroJmp
	add wa, wa
	lda xix, (SqedtFunc_SignExtend_CaseTable:24)
	ld	wa, (xix+wa)
	lda xix, (SeqFormat_DispatchA:24)
	jp	t, (xix+wa)

; Sequencer format dispatch A
SeqFormat_DispatchA:
	ld	l, 0:opc
SeqFormat_DispatchA_Join:
	ld	a, (0x02109c:24)
	cp	a, l
	scc16	z, hl
	extz	xhl
	jrl	SqedtFunc_Epilogue12
	ld	l, 1:opc
	jr	SeqFormat_DispatchA_Join
	ld	l, 2:opc
	jr	SeqFormat_DispatchA_Join
	ld	l, 3:opc
	jr	SeqFormat_DispatchA_Join
	ld	l, 5:opc
	jr	SeqFormat_DispatchA_Join
	ld	l, 6:opc
	jr	SeqFormat_DispatchA_Join
	ld	xhl, 0:i3
	ld	l, (0x03e2dc:24)
	jrl	SqedtFunc_Epilogue12
	ld	(0x03e2dc:24), a
	jrl	SeqFunc_ReturnZeroJmp
	ld	xhl, 0:i3
	ld	l, (0x03e2de:24)
	jrl	SqedtFunc_Epilogue12
	ld	(0x03e2de:24), a
	jrl	SeqFunc_ReturnZeroJmp
	extz	wa
	sub	wa, 15
	cp	wa, 0:i3
	jrl	lt, SeqFunc_ReturnZeroJmp
	cp	wa, 15
	jrl	gt, SeqFunc_ReturnZeroJmp
	add	wa, wa
	lda	xix, (SeqFormat_DispatchA_CaseTable:24)
	ld	wa, (xix+wa)
	lda	xix, (SeqFormat_DispatchA_Code:24)
	jp	t, (xix+wa)
SeqFormat_DispatchA_Code:
	cp	(0x03e2e0:24), 0
	jrl	nz, SeqFunc_ReturnZeroJmp
	ld	xwa, 15
	jr	SeqFormat_DispatchA_Join2
	cp	(0x03e2e0:24), 1
	jrl	nz, SeqFunc_ReturnZeroJmp
	ld	xwa, 18
	jr	SeqFormat_DispatchA_Join3
	cp	(0x03e2e0:24), 0
	jrl	nz, SeqFunc_ReturnZeroJmp
	ld	xwa, 21
	jr	SeqFormat_DispatchA_Join2
	cp	(0x03e2e0:24), 1
	jrl	nz, SeqFunc_ReturnZeroJmp
	ld	xwa, 24
	jr	SeqFormat_DispatchA_Join3
	cp	(0x03e2e0:24), 0
	jrl	nz, SeqFunc_ReturnZeroJmp
	ld	xwa, 27
SeqFormat_DispatchA_Join2:
	ld	xbc, (xsp+8)
	sub	xbc, xwa
	ld	xwa, 0:i3
	ld	a, (0x03e2dc:24)
	cp	xwa, xbc
	scc16	z, hl
	extz	xhl
	jr	SqedtFunc_Epilogue12
	cp	(0x03e2e0:24), 1
	jrl	nz, SeqFunc_ReturnZeroJmp
	ld	xwa, 29
SeqFormat_DispatchA_Join3:
	ld	xbc, (xsp+8)
	sub	xbc, xwa
	ld	xwa, 0:i3
	ld	a, (0x03e2de:24)
	cp	xwa, xbc
	scc16	z, hl
	extz	xhl
	jr	SqedtFunc_Epilogue12

; SqedtFunc state chain A
SqedtFunc_StateChainA:
	call GetTitleNow
	ld h, 0x0:opc
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
	sub wa, 0x9b
	cp wa, 0:i3
	jrl lt, SqedtFunc_GetFieldAddr_BySelector
	cp wa, 0xd
	jrl gt, SqedtFunc_GetFieldAddr_BySelector
	add wa, wa
	lda xix, (SqedtFunc_StateChainB_CaseTable:24)
	ld	wa, (xix+wa)
	lda xix, (SeqFormat_DispatchB:24)
	jp	t, (xix+wa)

; Sequencer format dispatch B
SeqFormat_DispatchB:
	cp xiz, 0x22
	jr z, SeqFmt_Field_LoadB
	cp xiz, 0x21
	jr z, SeqFmt_Field_LoadA
	cp xiz, 0x20
	jr nz, SeqFmt_Field_LoadC
	lda xhl, (9706:16)
	jrl SqedtFunc_Epilogue

SeqFmt_Field_LoadA:
	lda xhl, (0x2728:16)
	jrl SqedtFunc_EpilogueJump

SeqFmt_Field_LoadB:
	lda xhl, (0x286c:16)
	jrl SqedtFunc_Epilogue

SeqFmt_Field_LoadC:
	lda xhl, (0x2878:16)
	jrl SqedtFunc_Epilogue
	cp xiz, 0xb
	jr z, SeqFmt_Field_LoadF
	cp xiz, 0xa
	jr z, SeqFmt_Field_LoadE
	cp xiz, 0x2
	jr z, SeqFmt_Field_LoadD
	cp xiz, 0x1
	jr nz, SeqFmt_Field_LoadG
	lda xhl, (9744:16)
	jrl SqedtFunc_EpilogueJump

SeqFmt_Field_LoadD:
	lda xhl, (9746:16)
	jrl SqedtFunc_EpilogueJump

SeqFmt_Field_LoadE:
	lda xhl, (9750:16)
	jrl SqedtFunc_Epilogue

SeqFmt_Field_LoadF:
	lda xhl, (9816:16)
	jrl SqedtFunc_Epilogue

SeqFmt_Field_LoadG:
	lda xhl, (9742:16)
	jrl SqedtFunc_Epilogue
	cp xiz, 0x4
	jr z, SeqFmt_Field_LoadI
	cp xiz, 0x2
	jr z, SeqFmt_Field_LoadH
	cp xiz, 0x1
	jr nz, SeqFmt_Field_LoadJ
	lda xhl, (9758:16)
	jrl SqedtFunc_EpilogueJump

SeqFmt_Field_LoadH:
	lda xhl, (9760:16)
	jrl SqedtFunc_EpilogueJump

SeqFmt_Field_LoadI:
	lda xhl, (9762:16)
	jrl SqedtFunc_ReturnPath

SeqFmt_Field_LoadJ:
	lda xhl, (9756:16)
	jrl SqedtFunc_Epilogue
	cp xiz, 0x2
	jr z, SeqFmt_Field_LoadK
	cp xiz, 0x1
	jr nz, SeqFmt_Field_LoadL
	lda xhl, (0xf1d7:16)
	jrl SqedtFunc_EpilogueJump

SeqFmt_Field_LoadK:
	lda xhl, (9772:16)
	jrl SqedtFunc_EpilogueJump

SeqFmt_Field_LoadL:
	lda xhl, (0xf1d6:16)
	jrl SqedtFunc_Epilogue
	cp xiz, 0x6
	jr z, SeqFmt_Field_LoadN
	cp xiz, 0x2
	jr z, SeqFmt_Field_LoadM
	cp xiz, 0x1
	jr nz, SeqFmt_Field_LoadO
	lda xhl, (0xf1dc:16)
	jrl SqedtFunc_EpilogueJump

SeqFmt_Field_LoadM:
	lda xhl, (9766:16)
	jrl SqedtFunc_EpilogueJump

SeqFmt_Field_LoadN:
	lda xhl, (0xf1e0:16)
	jrl SqedtFunc_Epilogue

SeqFmt_Field_LoadO:
	lda xhl, (0xf1db:16)
	jrl SqedtFunc_Epilogue
	cp xiz, 0x9
	jr z, SeqFmt_Field_LoadS
	cp xiz, 0x8
	jr z, SeqFmt_Field_LoadR
	cp xiz, 0x7
	jr z, SeqFmt_Field_LoadQ
	cp xiz, 0x2
	jr z, SeqFmt_Field_LoadP
	cp xiz, 0x1
	jr nz, SeqFmt_Field_LoadT
	lda xhl, (0xf1f2:16)
	jrl SqedtFunc_EpilogueJump

SeqFmt_Field_LoadP:
	lda xhl, (9724:16)
	jrl SqedtFunc_EpilogueJump

SeqFmt_Field_LoadQ:
	lda xhl, (0xf1f6:16)
	jrl SqedtFunc_Epilogue

SeqFmt_Field_LoadR:
	lda xhl, (9728:16)
	jrl SqedtFunc_Epilogue

SeqFmt_Field_LoadS:
	lda xhl, (9730:16)
	jrl SqedtFunc_ReturnPath

SeqFmt_Field_LoadT:
	lda xhl, (0xf1f1:16)
	jrl SqedtFunc_Epilogue
	cp xiz, 0x5
	jr z, SeqFmt_Field_LoadV
	cp xiz, 0x2
	jr z, SeqFmt_Field_LoadU
	cp xiz, 0x1
	jr nz, SeqFmt_Field_LoadW
	lda xhl, (0xf229:16)
	jrl SqedtFunc_EpilogueJump

SeqFmt_Field_LoadU:
	lda xhl, (9722:16)
	jrl SqedtFunc_EpilogueJump

SeqFmt_Field_LoadV:
	lda xhl, (0xf22e:16)
	jrl SqedtFunc_ReturnPath

SeqFmt_Field_LoadW:
	lda xhl, (0xf228:16)
	jrl SqedtFunc_Epilogue
	cp xiz, 0xe
	jr z, SeqFmt_Field_LoadX
	cp xiz, 0xd
	jr nz, SeqFmt_Field_LoadY
	lda xhl, (0xf1d4:16)
	jrl SqedtFunc_Epilogue

SeqFmt_Field_LoadX:
	lda xhl, (0xf1d5:16)
	jrl SqedtFunc_Epilogue

SeqFmt_Field_LoadY:
	lda xhl, (0xf1d3:16)
	jrl SqedtFunc_Epilogue
	cp xiz, 0x14
	jr z, SeqFmt_Field_LoadAC
	cp xiz, 0x13
	jr z, SeqFmt_Field_LoadAB
	cp xiz, 0x12
	jr z, SeqFmt_Field_LoadAA
	cp xiz, 0x11
	jr z, SeqFmt_Field_LoadZ
	cp xiz, 0x10
	jr nz, SeqFmt_Field_LoadAD
	lda xhl, (0xf1ea:16)
	jrl SqedtFunc_EpilogueJump

SeqFmt_Field_LoadZ:
	lda xhl, (9768:16)
	jrl SqedtFunc_EpilogueJump

SeqFmt_Field_LoadAA:
	lda xhl, (0xf1ee:16)
	jrl SqedtFunc_Epilogue

SeqFmt_Field_LoadAB:
	lda xhl, (0xf1ef:16)
	jrl SqedtFunc_EpilogueJump

SeqFmt_Field_LoadAC:
	lda xhl, (9770:16)
	jrl SqedtFunc_Epilogue

SeqFmt_Field_LoadAD:
	lda xhl, (0xf1e9:16)
	jrl SqedtFunc_Epilogue
	cp xiz, 0x1a
	jr z, SeqFmt_Field_LoadAH
	cp xiz, 0x19
	jr z, SeqFmt_Field_LoadAG
	cp xiz, 0x18
	jr z, SeqFmt_Field_LoadAF
	cp xiz, 0x17
	jr z, SeqFmt_Field_LoadAE
	cp xiz, 0x16
	jr nz, SeqFmt_Field_LoadAI
	lda xhl, (0xf1e2:16)
	jr SqedtFunc_EpilogueJump

SeqFmt_Field_LoadAE:
	lda xhl, (9774:16)
	jr SqedtFunc_EpilogueJump

SeqFmt_Field_LoadAF:
	lda xhl, (0xf1e6:16)
	jr SqedtFunc_Epilogue

SeqFmt_Field_LoadAG:
	lda xhl, (0xf1e7:16)
	jr SqedtFunc_EpilogueJump

SeqFmt_Field_LoadAH:
	lda xhl, (9776:16)
	jr SqedtFunc_Epilogue

SeqFmt_Field_LoadAI:
	lda xhl, (0xf1e1:16)
	jr SqedtFunc_Epilogue

; DspItem0CngFunc dispatch
DspItem0_CngFunc:
	cp xiz, 0x1e
	jr z, DspItem0Cng_LoadFieldB
	cp xiz, 0x1d
	jr z, DspItem0Cng_LoadFieldA
	cp xiz, 0x1c
	jr nz, DspItem0Cng_LoadFieldC
	lda xhl, (9996:16)
	jr SqedtFunc_Epilogue

DspItem0Cng_LoadFieldA:
	lda xhl, (9994:16)
	jr SqedtFunc_Epilogue

DspItem0Cng_LoadFieldB:
	lda xhl, (9998:16)
	jr SqedtFunc_Epilogue

DspItem0Cng_LoadFieldC:
	lda xhl, (9992:16)
	jr SqedtFunc_Epilogue

SqedtFunc_GetFieldAddr_BySelector:
	cp xiz, 0x3
	jr z, SqedtFunc_FieldSel_LoadB
	cp xiz, 0x2
	jr z, SqedtFunc_FieldSel_LoadA
	cp xiz, 0x1
	jr nz, SqedtFunc_FieldSel_LoadC
	lda xhl, (9734:16)
	jr SqedtFunc_EpilogueJump

SqedtFunc_FieldSel_LoadA:
	lda xhl, (9736:16)

SqedtFunc_EpilogueJump:
	jr SqedtFunc_Epilogue

SqedtFunc_FieldSel_LoadB:
	lda xhl, (9740:16)

SqedtFunc_ReturnPath:
	jr SqedtFunc_Epilogue

SqedtFunc_FieldSel_LoadC:
	lda xhl, (9732:16)

SqedtFunc_Epilogue:
	pop xiz
	ret

; =============================================================================
; DspItem0CngFunc -- DSP Effect Item Change Function (UI handler)
; =============================================================================
; Handles DSP effect editor events. Displays effect names (0xe32a7a ptr table),
; parameter names (0xe324c4 via per-algo config at 0xe446dc), and values.
; Sends parameter changes to Sub CPU via Sprintf_Locked.
; Stack frame: 28 bytes.
DspItem0CngFunc:
	lda xsp, (xsp - 28)
	ld (xsp + 20), xbc
	ld (xsp + 24), xwa
	ld xix, (xsp + 20)
	ld (xsp), xix
	cp xix, EVT_GET_TTL_NOW
	jrl z, DspItem0_DispatchTarget
	cp xix, EVT_GET_RAM_SIZE
	jrl z, DspItem0_HandleType2
	ld l, (0x021098:24)
	lda xwa, (0x2978:16)
	ld (xsp + 4), xwa
	ld c, l
	inc 1, c
	ld b, l
	inc 2, b
	ld h, l
	inc 3, h
	ld a, l
	inc 4, a
	ldfr_berp A, 0xe2
	ld a, l
	inc 5, a
	ldfr_berp A, 0xe6
	ld a, l
	inc 6, a
	ldfr_berp A, 0xee
	ld a, l
	inc 7, a
	extz wa
	ld (xsp + 18), wa
	ldto_berp A, 0xee
	extz wa
	ld (xsp + 16), wa
	ldto_berp A, 0xe6
	extz wa
	ld (xsp + 14), wa
	ldto_berp A, 0xe2
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
	cp xix, EVT_GET_RAM_ADDRESS
	jrl z, DspItem0_TypeChangeHandler
	cp xix, EVT_GET_ACC_LVL_STR
	jrl z, DspItem0_SendEffectParam
	cp xix, EVT_GET_RAM_STRING
	jr z, DspItem0_DisplayEffectName
	ld xiy, (xsp)
	sub xiy, EVT_GET_EFF_FIX_STRING
	cp xiy, 0x0
	jrl lt, EffectEdit_ReturnZero
	cp xiy, 0x10
	jrl gt, EffectEdit_ReturnZero
	add xiy, xiy
	add xiy, DspItem0CngFunc_CaseTable
	ld iy, (xiy)
	lda xix, (DspItem0_DisplayEffectName:24)
	jp	t, (xix+iy)

DspItem0_DisplayEffectName:
	ld	(xsp), xde
	ld	wa, (10614:16)
	extz	xwa
	sll	xwa, 2
	ld	xbc, DspEffectName_PtrTable
	add	xbc, xwa
	ld	xwa, (xbc)
	push	xwa
	ld	xwa, (xsp+4)
	ld	xwa, (xwa+18)
	push	xwa
	call	Free_Compare2
	inc	8, xsp
	jrl	DspItem0_ExitWithHL	; -> 0xF356FB
	ld	(xsp), xde
	ldw	(xsp+18), 0
DspItem0_DisplayParamNames:
	pushw 0x0011
	ld a, (0x21098:24)
	extz wa
	add wa, (xsp+20)
	lda_d16 xbc, (0x29ac)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	extz wa
	muls wa, 17
	lda xbc, (DspParamName_Table:24)
	exts xwa
	add xwa, xbc
	push xwa
	ld bc, (xsp+24)
	mul bc, 17
	ld xwa, (xsp+6)
	ld xwa, (xwa+18)
	add xwa, xbc
	push xwa
	call CmpNamingCheck_Helper
	lda xsp, (xsp+10)
	incm 1, (xsp+18)
	cpw (xsp+18), 8
	jr c, DspItem0_DisplayParamNames
	ldw (xsp+18), 0
DspItem0_DisplayParamValues:
	pushw 0x0002
	ld a, (0x21098:24)
	extz wa
	add wa, (xsp+20)
	lda_d16 xbc, (0x29ac)
	extz xwa
	add xwa, xbc
	ld a, (xwa)
	extz wa
	add wa, wa
	lda xbc, (DspParamUnit_Table:24)
	exts xwa
	add xwa, xbc
	push xwa
	ld wa, (xsp+24)
	add wa, wa
	extz xwa
	lda xbc, (xwa+136)
	ld xwa, (xsp+6)
	ld xwa, (xwa+18)
	add xwa, xbc
	push xwa
	call CmpNamingCheck_Helper
	lda xsp, (xsp+10)
	incm 1, (xsp+18)
	cpw (xsp+18), 8
	jr c, DspItem0_DisplayParamValues
	jr DspItem0_ExitWithHL
	ld (xsp), xde
	ld xde, (xde+18)
	ld wa, bc
	ld xbc, xde
	jr DspItem0_FormatParamValue
	ld (xsp), xde
	ld xbc, (xde+18)
	jr DspItem0_FormatParamValue
	ld (xsp), xde
	ld xbc, (xde+18)
	ld wa, (xsp+8)
	jr DspItem0_FormatParamValue
	ld (xsp), xde
	ld xbc, (xde+18)
	ld wa, (xsp+10)
	jr DspItem0_FormatParamValue
	ld (xsp), xde
	ld xbc, (xde+18)
	ld wa, (xsp+12)
	jr DspItem0_FormatParamValue
	ld (xsp), xde
	ld xbc, (xde+18)
	ld wa, (xsp+14)
	jr DspItem0_FormatParamValue
	ld (xsp), xde
	ld xbc, (xde+18)
	ld wa, (xsp+16)
	jr DspItem0_FormatParamValue
	ld (xsp), xde
	ld xbc, (xde+18)
	ld wa, (xsp+18)
DspItem0_FormatParamValue:
	calr FormatParamValueStr
	jr DspItem0_ExitWithHL

DspItem0_SendEffectParam:
	ld (xsp), xde

	ld xwa, (xsp + 4)

	pushm (xwa)

	pushw 0xe3

	pushw 0x4d8c

	ld xwa, (xsp + 6)

	ld xwa, (xwa + 18)

	push xwa

	call Sprintf_Locked

	lda xsp, (xsp + 10)



DspItem0_ExitWithHL:
	ld xhl, (xsp + 24)
	jrl DspItem0_Epilogue

DspItem0_TypeChangeHandler:
	cp xde, 0x8
	jr ugt, DspItem0_TypeDispatch
	add xde, xde
	add xde, DspItem0_TypeChangeHandler_CaseTable
	ld de, (xde)
	lda xix, (DspItem0_TypeDispatch:24)
	jp	t, (xix+de)

; DspItem0 type change dispatch
DspItem0_TypeDispatch:
	lda xhl, (0x2976:16)
	jrl DspItem0_Epilogue
	sla bc, 1
	ld xwa, (xsp + 4)
	lda	xhl, (xwa+bc)
	jrl DspItem0_Epilogue
	sla wa, 1
	ld bc, wa
	ld xwa, (xsp + 4)
	lda	xhl, (xwa+bc)
	jrl DspItem0_Epilogue
	ld bc, (xsp + 8)
	sla bc, 1
	ld xwa, (xsp + 4)
	lda	xhl, (xwa+bc)
	jrl DspItem0_Epilogue
	ld bc, (xsp + 10)
	add bc, bc
	ld xwa, (xsp + 4)
	lda	xhl, (xwa+bc)
	jr DspItem0_Epilogue
	ld bc, (xsp + 12)
	add bc, bc
	ld xwa, (xsp + 4)
	lda	xhl, (xwa+bc)
	jr DspItem0_Epilogue
	ld bc, (xsp + 14)
	add bc, bc
	ld xwa, (xsp + 4)
	lda	xhl, (xwa+bc)
	jr DspItem0_Epilogue
	ld bc, (xsp + 16)
	add bc, bc
	ld xwa, (xsp + 4)
	lda	xhl, (xwa+bc)
	jr DspItem0_Epilogue
	ld bc, (xsp + 18)
	add bc, bc
	ld xwa, (xsp + 4)
	lda	xhl, (xwa+bc)
	jr DspItem0_Epilogue

DspItem0_HandleType2:
	ld xhl, 2:i3
	jr DspItem0_Epilogue
	ld xwa, 0:i3
	ld a, (0x29aa:16)
	cp xde, xwa
	scc16 c, hl
	extz xhl
	jr DspItem0_Epilogue
	ld (0x02109a:24), e

EffectEdit_ReturnZero:
	ld xhl, 0:i3
	jr DspItem0_Epilogue
	ld xhl, 0:i3
	ld l, (0x02109a:24)
	jr DspItem0_Epilogue
	ld (0x021098:24), e
	jr EffectEdit_ReturnZero
	ld h, 0x0:opc
	extz xhl
	jr DspItem0_Epilogue
	ld xhl, 0:i3
	ld l, (0x29aa:16)
	jr DspItem0_Epilogue

; DspItem0 dispatch target (calls GetTitleNow then falls through to epilogue)
DspItem0_DispatchTarget:
	call GetTitleNow
	ld h, 0x0:opc
	extz xhl

DspItem0_Epilogue:
	lda xsp, (xsp + 28)
	ret

EqualizerCngFunc:
	push xiz
	ld xiz, xwa
	ld xwa, xbc
	cp xbc, EVT_GET_RAM_ADDRESS
	jrl z, Equalizer_ParamByIndex
	cp xbc, EVT_GET_DISP_POS
	jr z, Equalizer_DispatchA
	lda xbc, (EntertainerGridCheck_Data_2:24)
	lda xhl, (0x2978:16)
	sub xwa, EVT_GET_EQ0_STR
	cp xwa, 0x0
	jrl lt, Equalizer_ParamString
	cp xwa, 0x8
	jrl gt, Equalizer_ParamString
	add xwa, xwa
	add xwa, EqualizerCngFunc_CaseTable
	ld wa, (xwa)
	lda xix, (Equalizer_DispatchA:24)
	jp	t, (xix+wa)

; EqualizerCngFunc dispatch A
Equalizer_DispatchA:
	ld xwa, xde
	lda xbc, (Equalizer_DispatchA_Data_2:24)
	lda xde, (Equalizer_DispatchA_Data:24)
	dec 2, xwa
	cp xwa, 0x0
	jrl c, Equalizer_LookupParamByIndex
	cp xwa, 0x6
	jrl ugt, Equalizer_LookupParamByIndex
	add xwa, xwa
	add xwa, Equalizer_DispatchA_CaseTable
	ld wa, (xwa)
	lda xix, (Equalizer_DispatchB:24)
	jp	t, (xix+wa)

; --- EQ_7Band_ParamLookup: Look up equalizer parameters for 7 frequency bands ---
; Seven entry points, one per EQ band. Each reads a 16-bit index from
; consecutive RAM addresses (0x297a-0x2986), doubles it as a table offset,
; adds to the base pointer in XBC/XDE, loads a 16-bit value, and jumps
; to a common handler. Alternates between XBC and XDE base registers.
; EqualizerCngFunc dispatch B
Equalizer_DispatchB:
	ld	wa, (0x297a:16)
	extz	xwa
	add	xwa, xwa
	add	xbc, xwa
	ld	hl, (xbc)
	extz	xhl
	jrl	Equalizer_PopIzRet
	ld	wa, (0x297c:16)
	extz	xwa
	add	xwa, xwa
	add	xde, xwa
	ld	hl, (xde)
	extz	xhl
	jrl	Equalizer_PopIzRet
	ld	wa, (0x297e:16)
	extz	xwa
	add	xwa, xwa
	add	xbc, xwa
	ld	hl, (xbc)
	extz	xhl
	jrl	Equalizer_PopIzRet
	ld	wa, (0x2980:16)
	extz	xwa
	add	xwa, xwa
	add	xde, xwa
	ld	hl, (xde)
	extz	xhl
	jrl	Equalizer_PopIzRet
	ld	wa, (0x2982:16)
	extz	xwa
	add	xwa, xwa
	add	xbc, xwa
	ld	hl, (xbc)
	extz	xhl
	jrl	Equalizer_PopIzRet
	ld	wa, (0x2984:16)
	extz	xwa
	add	xwa, xwa
	add	xde, xwa
	ld	hl, (xde)
	extz	xhl
	jrl	Equalizer_PopIzRet
	ld	wa, (0x2986:16)
	extz	xwa
	add	xwa, xwa
	add	xbc, xwa
	ld	hl, (xbc)
	extz	xhl
	jrl	Equalizer_PopIzRet

Equalizer_LookupParamByIndex:
	ld wa, (0x2978:16)
	extz xwa
	add xwa, xwa
	add xde, xwa
	ld hl, (xde)
	extz xhl
	jrl Equalizer_PopIzRet

; Equalizer param by index lookup
Equalizer_ParamByIndex:
	lda xbc, (0x2978:16)
	dec 1, xde
	cp xde, 0x0
	jr c, Equalizer_ReturnParamAddr
	cp xde, 0x6
	jr ugt, Equalizer_ReturnParamAddr
	add xde, Equalizer_ParamByIndex_Table
	ld a, (xde)
	exts wa
	lda	xhl, (xbc+wa)
	jrl Equalizer_PopIzRet

Equalizer_ReturnParamAddr:
	lda xhl, (0x2978:16)
	jrl Equalizer_PopIzRet
	ld xix, xde
	pushw 0x5
	jr Equalizer_LookupParamString
	ld xix, xde
	pushw 0x5
	ld wa, 2:i3
	jr FormatEqParamValue
	ld xix, xde
	pushw 0x5
	inc 4, xhl
	jr Equalizer_LookupParamString
	ld xix, xde
	pushw 0x5
	ld wa, 6:i3
	jr FormatEqParamValue
	ld xix, xde
	pushw 0x5
	inc 8, xhl
	jr Equalizer_LookupParamString
	ld xix, xde
	pushw 0x5
	ldw wa, 0xa
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
	ld xwa, EntertainerGridCheck_Data_3
	add xwa, xbc
	push xwa
	jr FormatEqParam_CopyAndReturn
	ld xix, xde
	pushw 0x5
	ldw wa, 0xe

FormatEqParamValue:
	ld	wa, (xhl+wa)
	extz xwa
	ld xde, xwa
	sll xde, 2
	add xde, xwa
	add xbc, xde
	push xbc

FormatEqParam_CopyAndReturn:
	ld	xwa, (xix+18)
	push	xwa
	call	CmpNamingCheck_Helper
	lda	xsp, (xsp+10)
	ld	xhl, xiz
	jr	Equalizer_PopIzRet
	call	GetTitleNow
	ld	h, 0:opc
	extz	xhl
	jr	Equalizer_PopIzRet
Equalizer_ParamString:
	ld xhl, 0:i3

Equalizer_PopIzRet:
	pop xiz
	ret

MainExeFunc:
	cp xbc, EVT_SW_IN
	jr nz, Equalizer_FormatValue
	ld xwa, NAKA_MAINFUNC_MainExeCall
	call MainPostEvent

; Equalizer format param value
Equalizer_FormatValue:
	ld xhl, 0:i3
	ret

SureJudgeFunc:
	cp xbc, EVT_SW_IN
	jrl nz, ParamCmd_ReturnZero
	cp (0x0340ea:24), 0x00
	jr nz, Equalizer_CmdDispatch
	ld xwa, NAKA_MAINFUNC_MainExeCall
	call MainPostEvent
	jrl ParamCmd_ReturnZero

; Equalizer command dispatch
Equalizer_CmdDispatch:
	ld wa, 0:i3
	call SetDialEnable
	call GetTitleNow
	ld xwa, xhl
	cp xhl, TITLE_SQSNGCP
	jr z, Equalizer_CmdCase1
	cp xhl, TITLE_SQSNGCLR
	jr z, Equalizer_CmdCase0
	sub xwa, TITLE_SQTRKCLR
	cp xwa, 0x0
	jrl lt, ParamCmd_ReturnZero
	cp xwa, 0xe
	jrl gt, ParamCmd_ReturnZero
	add xwa, xwa
	add xwa, Equalizer_CmdDispatch_CaseTable
	ld wa, (xwa)
	lda xix, (Equalizer_CmdCase0:24)
	jp	t, (xix+wa)

; Equalizer command case 0
Equalizer_CmdCase0:
	ld xwa, 0x900009
	ld xbc, EVT_SHOW
	ld xde, 5:i3
	jrl ParamCmd_SendAndReturnZero

; Equalizer command case 1
Equalizer_CmdCase1:
	ld xwa, 0x91000b
	ld xbc, EVT_SHOW
	ld xde, 5:i3
	jrl ParamCmd_SendAndReturnZero
	ld xwa, 0x9a0006
	ld xbc, EVT_SHOW
	ld xde, 5:i3
	jrl ParamCmd_SendAndReturnZero
	ld xwa, 0x9b000f
	ld xbc, EVT_SHOW
	ld xde, 5:i3
	jr ParamCmd_SendAndReturnZero
	ld xwa, 0x9c000e
	ld xbc, EVT_SHOW
	ld xde, 5:i3
	jr ParamCmd_SendAndReturnZero
	ld xwa, 0x9d000a
	ld xbc, EVT_SHOW
	ld xde, 5:i3
	jr ParamCmd_SendAndReturnZero
	ld xwa, 0x9e000a
	ld xbc, EVT_SHOW
	ld xde, 5:i3
	jr ParamCmd_SendAndReturnZero
	ld xwa, 0x9f0012
	ld xbc, EVT_SHOW
	ld xde, 5:i3
	jr ParamCmd_SendAndReturnZero
	ld xwa, 0xa0000a
	ld xbc, EVT_SHOW
	ld xde, 5:i3
	jr ParamCmd_SendAndReturnZero
	ld xwa, 0xa20009
	ld xbc, EVT_SHOW
	ld xde, 5:i3
	jr ParamCmd_SendAndReturnZero
	ld xwa, 0xa30009
	ld xbc, EVT_SHOW
	ld xde, 5:i3
	jr ParamCmd_SendAndReturnZero
	ld xwa, 0xa40009
	ld xbc, EVT_SHOW
	ld xde, 5:i3
	jr ParamCmd_SendAndReturnZero
	ld xwa, 0xa1000a
	ld xbc, EVT_SHOW
	ld xde, 5:i3

ParamCmd_SendAndReturnZero:
	call SendEvent

ParamCmd_ReturnZero:
	ld xhl, 0:i3
	ret

FormatParamValueStr:
	push xiz
	ld xiz, xbc
	ld (xiz), 0x20
	ld c, a
	extz bc
	lda xde, (0x29ac:16)
	extz xbc
	add xbc, xde
	ld w, (xbc)
	lda xhl, (xiz + 1)
	cp w, 0x55
	jrl z, Equalizer_CopyFixedString
	cp w, 0:i3
	jrl z, Equalizer_CopyFixedString
	ld c, a
	extz bc
	lda xde, (0x2978:16)
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
	cp wa, 0:i3
	jrl lt, PrepareAudioParam
	cp wa, 0x11
	jr le, Equalizer_FormatDispatch
	dec 6, wa
	cp wa, 0x12
	jrl lt, PrepareAudioParam
	cp wa, 0x2b
	jrl gt, PrepareAudioParam

; Equalizer format dispatch
Equalizer_FormatDispatch:
	lda xix, (Equalizer_FormatDispatch_Table:24)
	ld	wa, (xix+wa)
	extz wa
	sll wa, 1
	ld xix, Equalizer_FormatDispatch_CaseTable
	ld	wa, (xix+wa)
	lda xix, (Equalizer_FormatCases:24)
	jp	t, (xix+wa)

; Case bodies of the `jp t, (xrr+rr)` switch in Equalizer_FormatDispatch (word offsets at Equalizer_FormatDispatch_CaseTable): jp (xix + r) with xix = this
; label, so this label is the offset-0 case.  Formerly named as data; it is
; code.
Equalizer_FormatCases:
	pushw 0x0005
	ld xwa, EntertainerGridCheck_Data_3
	jrl FormatParamStr_CopyEnumName
	pushw 0x0005
	ld xwa, Equalizer_FormatCases_Data
	jrl FormatParamStr_CopyEnumName
	pushw 0x0005
	ld xwa, EntertainerGridCheck_Data_2
	jrl FormatParamStr_CopyEnumName

FormatParamString:
	pushw 0x5
	ld xwa, FormatParamString_Data_3
	jrl FormatParamStr_CopyEnumName
	pushw 0x5
	ld xwa, FormatParamString_Data_2
	jrl FormatParamStr_CopyEnumName
	pushw 0x5
	ld xwa, FormatParamString_Data
	jrl FormatParamStr_CopyEnumName

; Equalizer format default
Equalizer_FormatDefault:
	pushw 0x5
	ld xwa, Equalizer_FormatDefault_Data_8
	jrl FormatParamStr_CopyEnumName
	pushw 0x5
	ld xwa, Equalizer_FormatDefault_Data_7
	jr FormatParamStr_CopyEnumName
	pushw 0x5
	ld xwa, Equalizer_FormatDefault_Data_6
	jr FormatParamStr_CopyEnumName
	pushw 0x5
	ld xwa, Equalizer_FormatDefault_Data_5
	jr FormatParamStr_CopyEnumName
	pushw 0x5
	ld xwa, Equalizer_FormatDefault_Data_4
	jr FormatParamStr_CopyEnumName
	pushw 0x5
	ld xwa, Equalizer_FormatDefault_Data_3
	jr FormatParamStr_CopyEnumName
	pushw 0x5
	ld xwa, Equalizer_FormatDefault_Data_2
	jr FormatParamStr_CopyEnumName
	pushw 0x5
	ld xwa, Equalizer_FormatDefault_Data
	jr FormatParamStr_CopyEnumName
	add bc, bc
	ld	wa, (xde+bc)
	cp wa, 0:i3
	jr ge, EqFormat_NegativeValue
	neg wa
	pushw wa
	ld xwa, Equalizer_FormatDefault_Str
	jr SendAudioCommand

EqFormat_NegativeValue:
	pushw wa
	cp wa, 0:i3
	jr le, EqFormat_PositiveValue
	ld xwa, EqFormat_NegativeValue_Str
	jr SendAudioCommand

EqFormat_PositiveValue:
	ld xwa, EqFormat_PositiveValue_Str
	jr SendAudioCommand
	pushw 0x5
	ld xwa, EqFormat_PositiveValue_Data
	jr FormatParamStr_CopyEnumName
	pushw 0x5
	ld xwa, NakaData_WidgetDescriptors

FormatParamStr_CopyEnumName:
	add BC,BC
	ld	bc, (xde+bc)
	extz XBC
	ld XDE,XBC
	sll XDE, 0x02
	add XDE,XBC
	add XWA,XDE
	push XWA
	push XHL
	call CmpNamingCheck_Helper
	lda xsp, (xsp + 0x0a)
	jr t, Equalizer_PadSpaceAndReturn
Equalizer_CopyFixedString:
	pushw	Equalizer_CopyFixedString_Str_Blank5@hi16
	pushw	Equalizer_CopyFixedString_Str_Blank5@lo16
	push	xhl
	call	Free_Compare2
	inc	8, xsp
	jr	Equalizer_PadSpaceAndReturn
PrepareAudioParam:
	add bc, bc
	pushw	(xde+bc)
	ld xwa, PrepareAudioParam_Str

SendAudioCommand:
	push	xwa
	push	xhl
	call	Sprintf_Locked
	lda	xsp, (xsp+10)
Equalizer_PadSpaceAndReturn:
	ld (xiz + 6), 0x20
	pop xiz
	ret

CycleOnOffFunc:
	cp xbc, EVT_SET_PARAM
	jr nz, CycleOnOff_PostAndReturn
	ld xwa, NAKA_MAINFUNC_ApPlaySyori_Kubo
	ld xbc, EVT_SET_CYCLE
	call MainPostEvent

CycleOnOff_PostAndReturn:
	ld xhl, 0:i3
	ret

MetroOnOffFunc:
	cp xbc, EVT_SET_PARAM
	jr nz, MetroOnOff_ReturnZero
	or xde, xde
	jr nz, MetroOnOff_SendDisable
	ld xwa, NAKA_MAINFUNC_ApPlaySyori_Kubo
	ld xbc, EVT_SET_METRO
	ld xde, 0:i3
	jr MetroOnOff_PostEvent

MetroOnOff_SendDisable:
	ld xwa, NAKA_MAINFUNC_ApPlaySyori_Kubo
	ld xbc, EVT_SET_METRO
	ld xde, 1:i3

MetroOnOff_PostEvent:
	call MainPostEvent

MetroOnOff_ReturnZero:
	ld xhl, 0:i3
	ret

PunchInOutFunc:
	cp xbc, EVT_SET_PARAM
	jr nz, PunchInOut_ReturnZero
	or xde, xde
	jr nz, PunchInOut_SendDisable
	ld xwa, NAKA_MAINFUNC_ApPlaySyori_Kubo
	ld xbc, EVT_SET_PUNCH
	ld xde, 0:i3
	jr PunchInOut_PostEvent

PunchInOut_SendDisable:
	ld xwa, NAKA_MAINFUNC_ApPlaySyori_Kubo
	ld xbc, EVT_SET_PUNCH
	ld xde, 1:i3

PunchInOut_PostEvent:
	call MainPostEvent

PunchInOut_ReturnZero:
	ld xhl, 0:i3
	ret

EqInOutFunc:
	cp xbc, EVT_SET_PARAM
	jr nz, EqInOut_ReturnZero
	or xde, xde
	jr nz, EqInOut_SendEnable
	ld xwa, 0x4006
	ld bc, 0:i3
	ld de, 1:i3
	jr EqInOut_CallLswPut

EqInOut_SendEnable:
	ld xwa, 0x4006
	ld bc, 1:i3
	ld de, 1:i3

EqInOut_CallLswPut:
	call MainLswPut

EqInOut_ReturnZero:
	ld xhl, 0:i3
	ret

MimeOnOffFunc:
	cp xbc, EVT_SET_PARAM
	jr nz, MimeOnOff_PostAndReturn
	ld xwa, NAKA_MAINFUNC_MimeSyori
	ld xbc, EVT_SET_PARAM
	call MainPostEvent

MimeOnOff_PostAndReturn:
	ld xhl, 0:i3
	ret

TrkMixerIntTtlFunc:
	ld xwa, 0xffffffff
	ld xbc, EVT_INTERRUPT_TITLE
	ld xde, TITLE_SQMIXER
	call PostEvent
	ld xhl, 0:i3
	ret


BitmapNtedt0k:
	cp xbc, EVT_GET_BITMAP_HEIGHT
	jr z, BitmapNtedt0k_GetHeight
	cp xbc, EVT_GET_BITMAP_WIDTH
	jr z, BitmapNtedt0k_GetWidth
	cp xbc, EVT_GET_BITMAP_DATA
	jr z, BitmapNtedt0k_GetAddress
	ld xhl, 0:i3
	ret

BitmapNtedt0k_GetAddress:
	lda xhl, (Bitmap_Ntedt0k:24)
	ret

BitmapNtedt0k_GetWidth:
	ld xhl, 0x10
	ret

BitmapNtedt0k_GetHeight:
	ld xhl, 0x7f
	ret


BitmapNtedt0d:
	cp xbc, EVT_GET_BITMAP_HEIGHT
	jr z, BitmapNtedt0d_GetHeight
	cp xbc, EVT_GET_BITMAP_WIDTH
	jr z, BitmapNtedt0d_GetWidth
	cp xbc, EVT_GET_BITMAP_DATA
	jr z, BitmapNtedt0d_GetAddress
	ld xhl, 0:i3
	ret

BitmapNtedt0d_GetAddress:
	lda xhl, (Bitmap_Ntedt0d:24)
	ret

BitmapNtedt0d_GetWidth:
	ld xhl, 0xf0
	ret

BitmapNtedt0d_GetHeight:
	ld xhl, 0x7f
	ret


BitmapDredt0k:
	cp xbc, EVT_GET_BITMAP_HEIGHT
	jr z, BitmapDredt0k_GetHeight
	cp xbc, EVT_GET_BITMAP_WIDTH
	jr z, BitmapDredt0k_GetWidth
	cp xbc, EVT_GET_BITMAP_DATA
	jr z, BitmapDredt0k_GetAddress
	ld xhl, 0:i3
	ret

BitmapDredt0k_GetAddress:
	lda xhl, (Bitmap_Dredt0k:24)
	ret

BitmapDredt0k_GetWidth:
	ld xhl, 0x58
	ret

BitmapDredt0k_GetHeight:
	ld xhl, 0x77
	ret

BitmapDredt0d:
	cp xbc, EVT_GET_BITMAP_HEIGHT
	jr z, BitmapDredt0d_ReturnSize77
	cp xbc, EVT_GET_BITMAP_WIDTH
	jr z, BitmapDredt0d_ReturnSizeA8
	cp xbc, EVT_GET_BITMAP_DATA
	jr z, BitmapDredt0d_ReturnDataPtr
	ld xhl, 0:i3
	ret

BitmapDredt0d_ReturnDataPtr:
	lda xhl, (Bitmap_Dredt0d:24)
	ret

BitmapDredt0d_ReturnSizeA8:
	ld xhl, 0xa8
	ret

BitmapDredt0d_ReturnSize77:
	ld xhl, 0x77
	ret

	.include "sequencer/bmdredit_routines.s"
